# profile-store —— 权威 profile 存储 · CAS · 幂等记录（服务内部设计）

对位客户端的 `sync-service`。**边界报文与判定语义的权威在 `contracts/profile-sync.md` 与 `contracts/purchase.md`，本文件不复述**，只写后端内部如何兑现：表怎么摆、事务边界在哪、幂等记录怎么存。

公共的存储与并发前提（单库 PostgreSQL · `jsonb` 的浅合并语义 · 并发单元 = `account` 行）见 `_index.md`。

## 存储形态：承重列

```
profile       (account_id PK/FK, revision BIGINT, schema_version INT,
               doc JSONB, updated_at_utc)          -- doc 含透明段与不透明段

push_idem     (account_id, push_id, new_revision, accepted_at_utc,
               PRIMARY KEY (account_id, push_id))  -- 按 accepted_at_utc 月分区

receipt_idem  (receipt_id PK, account_id, channel, status,
               bundle_grant_ordinal, revision, ordered_at_utc, verified_at_utc)
```

- **`doc` 整段存一列。** 透明段与不透明段同处一个 `jsonb`，后端对不透明段一字不动；分列存储会让「顶层键整键替换」这条合并语义分裂成两套实现。
- **`revision` 与 `doc` 同表同行**，使 CAS 是一条语句而不是一次跨表协调。

## 事务边界

| 操作 | 同一事务内的写入 | 并发获取 |
|---|---|---|
| `push` | `doc` 浅合并 · `revision += 1` · `push_idem` 插入 | 条件 `UPDATE … WHERE account_id = ? AND revision = :baseRevision` |
| `verify` | `doc` 的 `/entitlement/bundleGrantOrdinal += 1` · `revision += 1` · `receipt_idem` 更新为已核销 | `SELECT … FOR UPDATE` on `account` |
| 下单（预落幂等记录） | `receipt_idem` 插入，`status` 记为未决态 | `receipt_id` 唯一索引 |
| `bind` / `unbind` | `doc` 的 `/accountInfo/identities` 更新 · `revision += 1` | `SELECT … FOR UPDATE` on `account`（详见 `account.md`） |

**建号骨架写入**（`account` + `identity` + profile 且 `revision = 1`）落在 `signin` 的同一次事务内，见 `account.md`。

## 四条实现纪律

写错任一条都会在正常账号上产生故障，而不是在边角情形上。

1. **CAS 用受影响行数分支，不要先 `SELECT` 再 `UPDATE`。** `UPDATE … WHERE account_id = ? AND revision = ?` 返回 0 行时，再读一次当前 `revision` 来区分「客户端落后」与「客户端领先」。这条自然满足契约「禁止先写 profile 再改 revision 的两步非原子形态」。
2. **判定顺序照契约写死**：`schemaVersion` 闸门 → 信封形状 → CAS → 回声校验 → 写入（`contracts/profile-sync.md` §4）。**回声校验读的是本事务内已加锁的当前值**，不是事务外的一次预读——否则校验通过与写入之间会开一道竞态缝。
3. **回声比较必须是类型感知的语义相等**，不是原始字节比较：整数按值、hex 逐字、时间戳按时刻、对象数组有序逐元素递归（口径见 `contracts/profile-sync.md` §5c）。因此存储层必须能把白名单路径还原成**类型化值**再比较；`jsonb` 按路径提取后由应用层按该口径判定。
4. **零判定权字段必须在校验中间件里显式关闭 enum 严格校验。** `reason` 与 `sourceCode` 的未知取值一律原样记账、不改写、不拒收（`decisions/ADR-0017-*`）。多数 Web 框架的 schema 校验默认对 enum 严拒，照默认走会让客户端一次枚举增员变成一次线上故障，并把后端做成客户端的发版阻塞点。
   **驱动判定的枚举反之仍是封闭校验面**（`platform` · `channel` · `code`）——校验策略在字段级分成两类，**不能一刀切**。

## 幂等记录：两类，不同轴

两类记录的轴不同，因此形态也不同，不要合并成一张表。

| | `push_idem` | `receipt_idem` |
|---|---|---|
| 键 | `(account_id, push_id)` | `receipt_id` **全局唯一，不带账号前缀** |
| 保留 | 有窗口（初值 30 天 / 200 条） | **永久保留，不设 TTL** |
| 分区 | 按 `accepted_at_utc` 月分区，整分区滚动裁剪 | 不按账号分区（全局唯一键与按账号分区互斥）；按 `ordered_at_utc` 的时间分区仍可行 |
| 命中的含义 | 同一次上行的重复到达 | 同一张收据的重复核销，或**已被其他账号核销** |

### `push_idem`：两个旋钮取先到者，实现只执行时间那一半

契约给了两个旋钮（最近 200 条 · 30 天）。稳态下 30 天内的 push 数远超 200 条，故活跃账号恒由条数先到、闲置账号由时间先到——两者都是上界，互不冲突。

**实现只做按 `accepted_at_utc` 的月分区滚动（时间那一半），把条数降级为观测阈值而非实时裁剪。** 按账号排序删除代价高，而放宽记忆量只会让幂等窗口更长、即更安全（契约已写明「窗口过期不会造成错误接受，只会把一次重试变成一次进度丢失」）。体量参考：活跃账号 30 天约 1 200 行、每行百余字节。

**命中处置**：主键冲突 ⇒ 读出 `new_revision` 回幂等应答，**不再推进 `revision`、不重写 profile、不做请求体深比对**。

### `receipt_idem`：全局唯一键，与序号推进同事务

- **插入点有两处**：下单时预落一条未决态记录（幂等键由后端在下单时分配或取平台发放的 id，客户端不生成），验票通过时把同一行更新为已核销并写入序号与 `revision`。**核销与 `bundleGrantOrdinal += 1` 必须同一次事务**，否则会出现「序号已推进但幂据未落」这一契约点名的失败态。
- **`receipt_id` 是主键**，因此「这张收据已被其他账号核销」是一次索引冲突，不是一次应用层查重。
- **永久保留**：一批收据行的体量极小，永久保留成本近似为零，与内容 flags 历史规则集永久保留是同形取舍。冷存归档、渠道逐个的 `receipt` 内部形态与对账信号阈值归购买域运维文档，本文件只定存储位置与事务边界。
- **它受读己所写约束**：下单与验票之后的 `receipt/{receiptId}` 读必须读到该次写入（见下）。

## 读己所写：玩家读路径全部走写入区

契约把「验票写入后立即读到」定为**对读路径的一致性要求**，这是本库唯一一条对部署拓扑的读路径约束。本形态的兑现方式是最简的那一种：**玩家读路径全部落在写入区**（会话粘滞的极端形态）。因此不需要 `revision` 下界等待、不需要副本复制位点暴露、不需要失败时退化回主。

拓扑与只读副本的职责见 `operations/environments.md`。

## 体积软告警

每次 push 写入后取 `doc` 的存储体积，出一个分布指标与「超阈值账号数」的 gauge（初值 512 KB，可热调，见 `operations/environments.md`）。**软告警绝不拒绝上行**——契约没有拒绝语义，把观测阈值实现成拒绝阈值等于给正常账号造一条「push 永远失败」的路径。

Source: `handoffs/2026-09-03-backend-stack-and-hosting.md`。
