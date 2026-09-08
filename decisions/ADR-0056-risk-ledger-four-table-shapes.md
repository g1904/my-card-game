# ADR-0056 — 风控台账落四张表，逐表形态按「体量随什么增长 + 是不是点查」判定

- **状态：** Accepted
- **日期：** 2026-09-08
- **来源：** handoffs/2026-09-08-risk-ledger-storage-shapes.md · answer-logs/log-risk-ledger-storage-shapes.md

## 背景

`operations/moderation.md` 已把风控事件流、复核队列、昵称扫描台账三样东西的**字段与语义**写全，欠的只是落到哪张表、怎么滚动——分区、索引、到期执行方式。这一层不定，`Data & state touchpoints` 写不到表级。

## 决策

三样东西落**四张表**，同处单库、同一 schema，**不新增任何存储系统**；形态各不相同，判据是「**体量随什么增长**」与「**访问模式是不是点查**」，不是「它们都叫台账」：

| 表 | 体量随什么长 | 分区 | 过期 |
|---|---|---|---|
| `risk_event` | 时间（只追加） | 按 `occurred_at_utc` **月 RANGE 分区** | **整分区 `DROP`**（180 天水位） |
| `deletion_audit` | 账号数 | 不分区 | 按批 `DELETE`（3 年水位）；注销执行不删（`ADR-0057`） |
| `nickname_review` | 待办积压 | 不分区 | 终态行按批 `DELETE`（180 天） |
| `nickname_scan` | 账号数（一行一账号） | 不分区 | **无到期过期**；随注销硬删 |

`risk_event` 主键 `(occurred_at_utc, event_id)`，预建未来 2 个月空分区余量；索引**只铺两条**，各对一条既有读路径——`(account_id, kind, occurred_at_utc)`（累计阈值窗口计数，同时是注销按账号硬删的索引前缀）与 `(kind, occurred_at_utc)`（全局熔断的窗口切片）。**不建 rollup 表。** `nickname_review` 的入队去重落成数据库不变式 `UNIQUE (account_id) WHERE state IN ('Pending','Claimed')`；`nickname_scan` **不给 `account` 加列**。

承重列写 `systems/account.md`，分区 / 索引 / 裁剪 / 领取语义 / 探针写 `operations/moderation.md`（与 `receipt_idem` 的分工逐字同构）。

## 理由

- **同库同实例是被两条既有要求各自单独逼出来的**：「注销审计事件与 `account_deletion` 行同事务」与「注销执行是一次全有或全无的删除事务」——跨存储写入会让「行已删、事件未落」成为可达状态，而那正是要留证的那一刻。Redis 不是候选：它只承担限流计数器、不持有权威状态，而复核判定会回灌词表、扫描台账决定 `nicknameChangeRequired` 是否为真，两者都是权威状态。
- **`risk_event` 取月不取日**：「到期整体过期」这句话本身就是分区裁剪的规格说明，`push_idem` 已是同库同形的现成实现；180 天 ⇒ 稳态 7 个活分区，日分区的 180+ 个分区只换来过期精度，而 180 天是**下界性质**（覆盖两倍于最长累计窗口 90 天）⇒ **实际保留 [180, 210] 天**不违反任何约束。
- **预建余量**：缺分区的 `INSERT` 在 PostgreSQL 上直接报错，一次定时任务连续失败一整月不应让写入当场失败。
- **索引只对已写死的读路径铺**：`(app_version, content_version)` 是周期性聚合而非点查、基数个位数；`device_id` 永不参与判定；`request_id` 的两侧日志接起来发生在日志系统侧。不建 rollup 是因为写入是异常驱动的，稳态量级远低于 `receipt_idem`——为尚不存在的聚合压力先建派生数据路径不划算。
- **`nickname_scan` 不加列到 `account`**：`account` 行是全库唯一的并发单元，扫描任务批量更新会与 `signin` / `push` / `bind` 争同一把行锁，把一条纯离线批处理塞进玩家热路径的锁竞争里；且六个字段里有五个只有扫描链路读写。
- **过期方向不是全库通则**：`receipt_idem` 必须显式关闭 TTL，本批四张表却有三张必须过期——判据是代价的不对称性（少留 vs 多留），不写明这条，那条 TTL 断言会被当作全库通则照抄。

## 备选方案

- **三张表**（注销审计并入 `risk_event`）— 见 `ADR-0057`：两者不在同一条时间轴上，保留期与删除语义都相反。
- **`risk_event` 日分区** — 只换来过期精度，代价是 180+ 个分区的维护面。
- **建 rollup 表 / 给聚合列建索引** — 为尚不存在的聚合压力先建派生数据路径；先走 `operations/purchase-ops.md` §3d 的四项排除法。
- **`nickname_scan` 的六个字段直接加到 `account`** — 把离线批处理塞进全库唯一并发单元的锁竞争。

## 后果

- `systems/account.md` 承重列块补四张表，注销执行事务行同改；`operations/moderation.md` 新增「四张台账的存储形态」一节并替换末行的待定声明。
- `operations/environments.md` 的旋钮清单与定时任务出口各补行（分区预建 / 裁剪 / 租约回收 / 终态清理）。
- **`risk_event` 的分区裁剪滞后量是「个人信息超期留存」唯一的机制发现面**——裁剪任务默默失败三个月不会有任何人发现，除非有这条数。探针口径见 `operations/observability.md`。
- 注销事务会与裁剪任务在同一批分区上并发（`DROP` 需 `ACCESS EXCLUSIVE`）：裁剪跑低峰、失败即下一轮重试，**注销执行永不为裁剪让路**。
- 客户端侧零影响：四张表全是后端内部状态，`contracts/*` 报文一字不改。
