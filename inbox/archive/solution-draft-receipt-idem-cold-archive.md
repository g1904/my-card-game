---
type: solution-draft
date: 2026-09-06
question: `receipt_idem` 幂等记录体量增长后的冷存归档形态，以及对账信号「`bundleGrantOrdinal > bundleRedeemedOrdinal` 持续 N 天」的阈值 N 如何定值与校准
source: open-questions/06-platform-stack.md → 「`receiptId` 幂等记录的冷存归档与对账阈值（部分答结）」
targets: operations/purchase-ops.md（§3b 索引一行 · §3d 全节改写 · §4 阈值一行）· operations/environments.md（旋钮清单补行）· systems/profile-store.md（`receipt_idem` 承重列与「永久保留」一段各补一句）
status: distilled
reviewed: 2026-09-06 · 批量评审 —— receiptArchiveAgeMonths = 24
distilled-to: handoffs/2026-09-06-receipt-idem-cold-archive.md
---

# 方案草稿 — `receipt_idem` 的冷存归档形态与对账阈值 N

## 问题

`06-platform-stack.md` 该条已**部分答结**：存储选型（关系库 `receipt_idem`、`receipt_id` 全局唯一主键）· 与 `bundleGrantOrdinal` / `cloudRevision` 的写入同一次事务 · 下单时预落未决态记录 · 永久保留不设 TTL —— 全部已定，本草稿**不重新设计这一半**。

仍悬着两项：

1. **冷存归档形态**。`operations/purchase-ops.md` §3d 已定「首版不做 + 三条触发阈值 + 两条承重约束（唯一性索引永不归档 · 冷数据仍需点查）」，但**没有形态**：热 / 温 / 冷各是什么、读路径怎么走、归档任务的顺序与可重入、归档后 TTL 禁用断言与备份口径如何仍然成立。缺形态的后果是：触发条件真的命中那天，归档会被临场设计，而它是一条**正确性关键路径**——一次查不到就等于「当作新票」重复发放，且线上不可发现。
2. **对账信号阈值 N**。`operations/purchase-ops.md` §4 已写 N = 3 天并给了推导，但 06 分片的条目仍记作「阈值待定」。真正欠的不是初值，而是**旋钮位置与校准方法**：N 目前既不在 `operations/environments.md` 的旋钮清单里（改它就要发版），也没有「上线后拿什么数据、按什么公式收敛到定值」的口径。

## 约束（来自既有设计）

硬前提，方案不得与之冲突：

- **`receiptId` 全局唯一、永不过期、不设 TTL**；过期后果是重复发放，线上不可发现 → `contracts/purchase.md` §7 · `decisions/ADR-0013-receipt-idempotency-and-read-your-writes.md`。
- **幂等记录写入与 `bundleGrantOrdinal += 1`、`cloudRevision += 1` 同一次事务**；唯一性由存储层的唯一约束保证，不由应用层先读后写 → `operations/purchase-ops.md` §3a（S1 / S2）。
- **读己所写覆盖 `GET /v1/purchase/receipt/{receiptId}`**，包含下单预落的 `status = Unknown` 记录 → `contracts/purchase.md` §6 保证 3 · S3。玩家读路径全部走写入区 → `systems/profile-store.md`、`operations/environments.md`「拓扑与副本」。
- **唯一性索引永不归档，可归档的只有记录体；冷数据仍需点查**，明确否决只能顺序扫描的介质 → `operations/purchase-ops.md` §3d。
- **在线分区按 `receipt_id` 哈希**，时间维度只用于归档，不用于在线分区 → 同上 §3b。
- **对账不驱动任何自动写入**；退款不回收权益、不回退序号；信号只作人工 / 工单入口，且**不做逐账号告警** → `contracts/purchase.md` §7 · `operations/purchase-ops.md` §2 §4 · `ADR-0007`。
- **不引入独立存储系统 / 消息队列 / 分片 / 多主 / 读写分离** → `systems/_index.md`「明确不引入」。
- **收据表须显式关闭任何 TTL / 过期清理机制，并在配置层留一条部署时断言** → `operations/purchase-ops.md` §3c。
- **迁移走 expand → deploy → contract 三步、只前滚不回滚** → `operations/deployment.md`。
- **运行期可调旋钮落 `config_knob` 表、改值不发版**；契约里凡标注「初值 / 待实测校准」的数值都应在旋钮清单里 → `operations/environments.md`。

## 建议方案

### A. 三层的分工：热 = 同一张表，温 = 同库归档表，冷 = 只作备份

`[既有推演]`

- **热层 = 现有 `receipt_idem` 表本身。** 每一张收据**永远**在这里保留一行（下称**哨兵行**），承载唯一约束与「他账号核销」判定所需的最小列集。归档**不删行**。
- **温层 = 同库同实例的独立表 `receipt_idem_archive`**，只装被搬走的**记录体列**，按 `record_at_utc` 做**年度 RANGE 分区**，每个分区上有 `receipt_id` 的唯一索引 ⇒ **仍是点查**，只是多一跳。
- **冷层 = 对象存储的年度导出**，**不在任何在线读路径上**，只作长期备份与离线分析。它是可选的第三步，且必须与温层**同时存在**（导出不等于删除温层分区）。

三层同处一个库 / 一个实例，是「不引入独立存储系统」与「玩家读路径全部走写入区」两条既有结论的直接推论：温层若移到另一实例或只读副本，S3（读己所写）与 S1（同事务）当场破防。

### B. 哨兵行常驻：唯一性与他账号判定永不离线

`[既有推演]`

哨兵行保留五列，**永不归档、永不置空**：

| 列 | 为什么必须常驻 |
|---|---|
| `receipt_id`（主键） | 唯一性约束本体。少一行 = 一次重复发放 |
| `account_id` | 「已被其他账号核销」是一次索引冲突后的当场判定（`systems/_index.md` 已把它定为数据库不变式），二跳判定会把它变回应用层查重 |
| `status` | `GET /receipt/{receiptId}` 的三值应答主体；`Unknown` / `Rejected` 两态**不需要**记录体即可作答 |
| `tier`（`hot` \| `archived`） | 读路径判断要不要走第二跳 |
| `record_at_utc` = `COALESCE(verified_at_utc, ordered_at_utc)` | **二跳的分区剪枝键**。缺它，按 `receipt_id` 查温层会广播到全部年度分区——正是 §3b 拒绝在线时间分区的那条退化 |

其余列（`channel` · `bundle_grant_ordinal` · `revision` · `ordered_at_utc` · `verified_at_utc` · 退款 / 关单等运维侧字段）为**记录体**，归档时写入温层并在热层置 `NULL`。

**这样归档不触碰任何事务路径**：verify 与下单仍只写 `receipt_idem` 一张表、仍是一次本地事务，S1 / S2 逐字不变。

### C. 读路径与延迟预算：一跳命中，二跳只对老票且只在需要记录体时发生

`[既有推演]` + `[通行做法]`

```
查重 / 补查 → 热层按 receipt_id 主键点查
  未命中                    ⇒ 新票（verify 正常流程 / GET 回 404 语义）
  命中且 account_id 不同     ⇒ purchase.receipt_claimed          （零二跳）
  命中且 status ≠ Verified   ⇒ 直接作答 Unknown / Rejected        （零二跳）
  命中且 tier = hot          ⇒ 直接作答（含 ordinal / revision）   （零二跳）
  命中且 tier = archived     ⇒ 按 (record_at_utc → 年度分区, receipt_id) 点查温层，取记录体作答
```

**verify 热路径实际上永不二跳**：新票在第一跳未命中即结束；只有「几个月后重装回来的老票重复提交」与「客服补查老订单」会走第二跳，而这两条路径的延迟预算本就宽松（玩家侧处在阻塞重试态，轮询间隔以秒计）。

| 路径 | 预算（初值，待实测校准） |
|---|---|
| 热层点查 p99 | ≤ **20 ms**（沿用 §3d 触发阈值 ③，不新设一个数） |
| 温层二跳点查 p99 | ≤ **100 ms** |
| `GET /receipt/{receiptId}` 端到端 p99（含二跳） | ≤ **300 ms** |
| 冷层（对象存储导出） | **不在在线读路径上**，无预算 |

### D. 归档任务：单向、幂等、可重入，顺序保证任何中断都不会丢记录体

`[通行做法]`

按批（`receiptArchiveBatchRows` 行）循环，每批一个事务，顺序固定：

1. `SELECT … FROM receipt_idem WHERE tier = 'hot' AND record_at_utc < now() - :ageMonths AND status <> 'Unknown' … FOR UPDATE SKIP LOCKED`；
2. `INSERT INTO receipt_idem_archive … ON CONFLICT (receipt_id) DO NOTHING`（重入安全）；
3. **确认温层该行已存在**后，同一事务内 `UPDATE receipt_idem SET tier='archived', archived_at_utc=now(), <记录体列>=NULL`。

- **顺序不可颠倒**：先写温层、后改哨兵。任何中断的最坏结果是「温层多一行、热层还是 hot」——一次可重跑的空转，而不是「热层已置空、温层未写」这一**不可恢复的记录体丢失**。
- **`status = 'Unknown'` 的记录不归档**：微信渠道的未决 / 关单记录是对账任务的日常工作面（§2），搬走只会让日频对账天天二跳。
- 任务频次周级、跑在低峰；它与既有两个轻量周期任务（分区滚动、体积扫描）同处一个出口（`operations/environments.md`「定时任务出口」），**不新增调度设施**。
- 归档任务是**唯一**被允许把记录体列置 `NULL` 的路径；除它之外 `receipt_idem` 无任何删除 / 清空路径。

### E. TTL 禁用断言与备份口径必须一并扩写

`[既有推演]`

- **断言扩展**：现有断言是「读取该表的过期策略，非『永不过期』即拒绝启动」（§3c）。引入温层后，断言须**逐张覆盖 `receipt_idem` 与 `receipt_idem_archive` 两张表及其全部分区**。少写一张表 = 归档表被一次误配置清掉 = 老票二跳查不到 = 重复发放，且**线上不可发现**（与原漏洞逐字同形）。
- **备份与恢复口径必须一致**：两张表须在**同一 PITR 一致点**上恢复。分开备份会恢复出「哨兵 `tier = archived`、温层无此行」的悬空指针——读路径查不到记录体，表现与「记录被清掉」相同。这条须写进恢复演练的必检项（`ADR-0009` O3 的可演练恢复）。
- **冷层导出不改变以上两条**：导出是备份的补充，不是温层的替代，导出完成**不得**触发温层分区删除。

### F. 触发条件的一处重分类：行数阈值不是归档信号

`[既有推演]`

§3d 的三条触发阈值中，**① 在线表行数 > 5,000 万在本形态下不可能由归档解决**——哨兵行必须常驻，键的条数只增不减。归档能降的只有**行宽、堆体积与二级索引条目数**。因此建议：

| 原阈值 | 重分类 | 处置 |
|---|---|---|
| ① 行数 > 5,000 万 | **容量 / 扩容信号**，不是归档信号 | 纵向扩容 + 哈希分区数扩容（`systems/_index.md` 已给的扩展方向） |
| ② 表 + 索引 > 50 GB | 归档信号 | 启动归档 |
| ③ 点查 p99 > 20 ms 持续 7 天 | 归档信号，但**须先排除**下列项 | 见下 |

**③ 命中时，归档是最后手段而不是第一反应。** 按序排除：表 / 索引膨胀与 autovacuum 是否跟得上 · 二级索引是否已膨胀 · 连接池饱和与最长事务时长（`observability.md`「数据面」已有这两条指标）· 实例规格与共享缓冲区。在 0.5 GB / 年的估算体量下，p99 劣化几乎必然出自这四项之一而非行数——先归档等于为一个错误诊断增加一条正确性关键路径。

**收益要如实记下**：`receipt_id` 本身（Google 的 `purchaseToken` 常见即数百字符）往往就是行的主体，记录体列合计约 60–90 字节 / 行、二级索引项约 40 字节 / 行 ⇒ 归档对 ② 的收益上界大致在 **30–50%**，**不是一个数量级**。这正是「归档不是扩容手段」的定量说明。

### G. 二级索引改为部分索引：③ 的真实收益点

`[既有推演]`

§3b 的 `(account_id, verified_at_utc)` 二级索引改为 `WHERE tier = 'hot'` 的**部分索引**，归档行自动移出；对账 / 客服的历史查询走温层上的同名索引。这比搬记录体更直接地压住点查 p99——索引高度与缓存命中率是 ③ 真正的因变量。

### H. 对账阈值 N：初值不动，提为旋钮，给出校准公式与静默期

`[通行做法]`

- **初值 N = 3 天不改**，`operations/purchase-ops.md` §4 的推导（客户端兑现触发点在「主菜单、一次 pull 之后」⇒ 正常玩家下次登录即追平；3 天覆盖一个周末缺席，且远短于以月计的退款 / 客诉窗口）已经成立，本草稿不重推。
- **把它提为运行期旋钮** `grantRedeemedLagAlertDays`，落 `config_knob` 表并登记进 `operations/environments.md`「旋钮清单」。现状是它只写在运维文档正文里 —— 改一次阈值要发一次版，与「契约里全部标注初值 / 待实测校准的数值落旋钮表」这条判据不符。
- **上线后先静默观测**：新增布尔旋钮 `grantRedeemedLagTicketEnabled`，初值 `false` —— 信号只上看板、不产出工单，**连续 4 周**（覆盖至少两个完整周末与一个月度活跃周期）之后再置 `true`。理由：N 的正确性完全取决于「正常玩家的追平时长分布」，而这条分布在有真实玩家之前不存在；先出工单只会让首批工单全是正常在途。
- **校准公式**（数据源即 §4 已定的「按持续时长分桶的分布」）：

  ```
  N := clamp( ceil( P99(追平时长_天) ) + 1, 3, 14 )
  ```

  - 分桶建议 **1 / 2 / 3 / 5 / 7 / 14 / 30+ 天**（低基数、覆盖 P99 可读区）。
  - `+1` 是余量位：分桶是离散的，P99 落在桶内何处不可知。
  - **下界 3 天**：既有推导（一个周末的正常缺席），不下调。
  - **上界 14 天**：平台退款 / 客诉窗口以月计，工单须留出至少两周处置期 ⇒ N 不得超过窗口的一半。
  - **复核节奏**：定值后每季度复核一次；**客户端兑现触发点形态一变更即立刻复核**（N 的整条推导挂在「兑现发生在主菜单、一次 pull 之后」这个前提上）。
- **「差值 ≥ 2 立即告警」这条不参与校准、不受 N 影响。** 它是故障信号（连续两次购买都未兑现，或兑现路径本身坏了），与「玩家缺席」不同轴；把它并进 N 的分布里会让一条故障曲线被玩家作息淹没。
- **纪律重申（不放松）**：N 命中只产出**看板计数与工单**。方案中不存在、也不得引入任何自动补发 / 自动核销 / 自动改写 `bundleRedeemedOrdinal` 的路径——那等于后端具备发放权，与「兑现段客户端演算、后端只复算」正面相悖（`ADR-0007` · `contracts/purchase.md` §7）。指标仍是「一条 gauge + 一条按持续时长分桶的分布」，**不做逐账号告警**。

## 具体形态（可 derive 的落地面）

### 表形态（`snake_case` 列名，沿用 `systems/_index.md` 的映射约定）

```
receipt_idem                                   -- 热层，PARTITION BY HASH (receipt_id)，形态不变
  receipt_id            text        PK         -- 哨兵：永不归档
  account_id            uuid        NOT NULL   -- 哨兵
  status                text        NOT NULL   -- 哨兵：Unknown | Verified | Rejected
  tier                  text        NOT NULL DEFAULT 'hot'   -- 新增：hot | archived
  record_at_utc         timestamptz NOT NULL   -- 新增：COALESCE(verified_at_utc, ordered_at_utc)，二跳剪枝键
  archived_at_utc       timestamptz            -- 新增：可空
  channel               text                   -- ↓ 以下为记录体，归档后置 NULL
  bundle_grant_ordinal  bigint
  revision              bigint
  ordered_at_utc        timestamptz
  verified_at_utc       timestamptz
  <退款 / 关单等运维侧字段>

  INDEX (account_id, verified_at_utc) WHERE tier = 'hot'      -- 由普通索引改为部分索引

receipt_idem_archive                           -- 温层，PARTITION BY RANGE (record_at_utc)，年度分区
  receipt_id            text        NOT NULL
  record_at_utc         timestamptz NOT NULL
  <与热层记录体列逐一同构>
  PRIMARY KEY (record_at_utc, receipt_id)
  每分区： UNIQUE INDEX (receipt_id) · INDEX (account_id, verified_at_utc)
```

**迁移按 expand → deploy → contract 三步**：expand = 加 `tier` / `record_at_utc` / `archived_at_utc` 三列（带默认值，旧代码兼容）+ 建温层空表 + 建部分索引；deploy = 发带二跳读路径的新代码；contract = 删旧的全量二级索引。**归档任务本身在 contract 之后、且只在触发条件命中时才开启**（`receiptArchiveEnabled` 初值 `false`）。

### 旋钮（登记进 `operations/environments.md`「旋钮清单」，权威列指向 `operations/purchase-ops.md`）

| 旋钮 key | 初值 | 说明 |
|---|---|---|
| `receiptArchiveEnabled` | `false` | 归档任务总开关。首版不做（§3d 既有结论），触发条件命中后置 `true` |
| `receiptArchiveAgeMonths` | **24**（取向项，见下） | 归档水位线：`record_at_utc` 早于此即可归档 |
| `receiptArchiveBatchRows` | 5 000 | 单批搬运行数；批越小锁窗越短 |
| `receiptArchiveIntervalHours` | 168（周频） | 低峰执行 |
| `receiptArchiveHotP99Ms` | 20 | 热层点查预算 = §3d 触发阈值 ③，同一个数只有一个落点 |
| `receiptArchiveWarmP99Ms` | 100 | 温层二跳预算 |
| `grantRedeemedLagAlertDays`（N） | **3** | 既有初值不改，只是从正文提为旋钮 |
| `grantRedeemedLagTicketEnabled` | `false` | 上线后 4 周静默观测期结束再置 `true` |

> 顺带发现：`operations/purchase-ops.md` §3a 的**悬挂 `claiming` 清理阈值 10 分钟**同样标注「初值待实测校准」，却也不在旋钮清单里。它与上表同批登记即可（纯机械，答案已定）。

### 归档触发条件（改写后的 §3d 三条）

| 信号 | 阈值初值 | 判为 |
|---|---|---|
| 在线表行数 > 5,000 万 | 5,000 万 | **容量 / 扩容信号**（归档不降行数） |
| 表 + 索引 > 50 GB | 50 GB | 归档信号 |
| 点查 p99 > 20 ms 持续 7 天 | 20 ms / 7 天 | 归档信号，**须先排除 bloat / 索引膨胀 / 连接池 / 规格四项** |

## 后果

- **改动文档**：`operations/purchase-ops.md`（§3b 索引一行改部分索引 · §3d 整节由「只留触发条件」扩为「触发条件 + 形态」· §4 阈值行加旋钮 key 与校准口径）· `operations/environments.md`（旋钮清单补 8 行 + `claiming` 阈值 1 行）· `systems/profile-store.md`（`receipt_idem` 承重列补三列、「永久保留」一段补一句指向温层）。
- **不改契约**：`contracts/purchase.md` §7 的语义（永不过期）与 §6 的七条保证逐字不变，符合该节「不回头改契约」的处置。**七条服务端保证在归档后仍全部成立**——保证 1 / 6（任意时间跨度重复提交仍 `deduplicated = true`）恰恰是靠「哨兵行永不删 + 二跳可点查」兑现的。
- **无存档 / 报文迁移**：客户端零感知，无 `schemaVersion` 变化。
- **新增一条正确性关键路径**（归档任务）——这是本方案的主要代价，因此它由 `receiptArchiveEnabled` 默认关闭、并要求触发条件命中且四项排除完成后才开启。
- **恢复演练必检项 +1**：两表须同 PITR 一致点恢复。

## 备选方案（已考虑并否决）

- **把哨兵拆成独立的 `receipt_key` 表 + 记录体表** — 这就是 §3a 那条「退化形态」的自发重演：一次事务变两步，正确性靠清理任务维持。而本方案不需要它——哨兵与热记录体同表即可，归档只是置空列。
- **归档 = 从热表删除行、只留在温层** — 直接违反「唯一性索引永不归档」：删掉的行不再参与唯一约束，同一张票二次提交查不到即当作新票 ⇒ 重复发放，且线上无任何报错。
- **归档到对象存储 / 日志式冷存并直接作为读路径** — §3d 已明确否决只能顺序扫描的介质；本方案把对象存储降级为**备份与离线分析**，不在任何在线读路径上。
- **把温层放到只读副本或另一实例** — 与 S3（读己所写）和「玩家读路径全部走写入区」正面冲突；且引入第二个存储系统，与 `systems/_index.md`「明确不引入」相抵。
- **在线表改为按 `verified_at_utc` 时间分区以便整分区 detach** — §3b 已给理由：点查时不知道这张票是哪年的，会退化为跨全部分区广播。本方案改用「哨兵常驻 + `record_at_utc` 携带年份」拿到同样的剪枝能力而不动在线分区键。
- **两级分区（RANGE(年) → HASH(receipt_id)）** — 顶层 RANGE 无法由 `receipt_id` 剪枝，点查仍要遍历所有年份；等价于上一条的翻版。
- **靠 TTL / 定期清理压体量** — §3c 的 TTL 禁用断言是本域最承重的一条，任何形式的过期清理都是同一个漏洞。
- **N 命中后自动补发 / 自动核销** — §7 与 `ADR-0007` 已明确否决：等于后端具备发放权。
- **N 做成逐账号告警** — §4 已否决：任何一次客户端发版事故都会把它变成告警风暴。
- **把「差值 ≥ 2」并入 N 的持续时长判定** — 两者不同轴（故障 vs 缺席），合并会让故障曲线被玩家作息淹没。
- **上线即按 N = 3 出工单** — 追平时长分布在有真实玩家之前不存在，首批工单会全是正常在途；故先静默 4 周。

## 与既有决策的张力

1. **`operations/purchase-ops.md` §3b + §3d 的两个分区维度，在同一张表上不可同时成立。** §3b 定在线哈希分区（键 `receipt_id`），§3d 说「归档切分维度用 `verifiedAtUtc`（年度分区）…… 与 3b 的在线哈希分区不冲突」。PostgreSQL 单表只有一个分区键，这句话**只有在「归档表是另一张表」时才成立**——而 §3d 没有把这一点写出来。本方案把它显式化（热层不动、温层是另一张按年 RANGE 分区的表），因此是**补全而非推翻**；建议提炼时顺手把 §3d 那句改写清楚。
2. **06 分片的条目措辞滞后于 `operations/purchase-ops.md`。** 条目说 N「仍待落定」，而 §4 已写 N = 3 天并给了完整推导。本方案按「初值已在、待旋钮化与校准」处理，**不重新推导 3 天**。提炼时应把条目改写为其真实残余（旋钮位置 + 校准口径 + 上线后校准），否则下一次运行会再一次去推一个已经存在的数。
3. **§3d「触发任一即启动归档」与本方案 F 节的重分类。** 行数阈值在「唯一性索引永不归档」这条硬约束下不可能被归档解决——这不是与决策冲突，而是既有三条阈值中有一条**被放错了类**。若用户不接受重分类，替代做法是保留三条同列，但在 ① 后加一句「归档不降行数，该阈值的处置是扩容」——效果相同，只是不改表结构。

## 前置依赖

- **真实体量与流量**（同分片的「成本模型」条目）：归档三条触发阈值与 N 都标注「待实测校准」，本方案给的是**校准方法与旋钮位置**，定值仍须上线后的数据。
- **备份保留期**（`operations/environments.md`：副本数与备份保留期是成本模型的输出，DAU 预期落定前不写死）：冷层导出的保留期与它同源，本方案不越位定值。
- **客服 / 对账的「可查询期」产品承诺**：`receiptArchiveAgeMonths` 的取值等价于它，见下方取向项。

## 仍需用户决定

> **本节已于 2026-09-06 的批量评审中裁决完毕**（`/batch-provide-solution-draft backend`）。
>
> **→ 已裁决（2026-09-06 · 批量评审）：`receiptArchiveAgeMonths` 初值取 24 个月**（选项 B）。
> 依据：它是三个候选里唯一不依赖尚未存在的输入（DAU / 成本模型），又同时覆盖两个完整年度对账周期与任何以月计的退款 / 客诉窗口；且它是运行期旋钮，实测后可随时调。
>
> **→ 同批确认的承重前提（来自同一场评审的另一条裁决）：注销执行时 `receipt_idem` 全行保留 + 最小 `account` 墓碑**（见 `solution-draft-compliance-domain-storage.md` 的「注销执行的删除深度」）。本草稿「哨兵行永不删」的承重前提因此成立，方案无需重做。

- **`receiptArchiveAgeMonths` 的初值 —— 即「多久以前的订单允许退出热层」。** `[取向选择]`
  归档后订单**仍然查得到**（二跳、延迟 ≤ 100 ms），因此这不是「查不查得到」的选择，而是「客服与对账的日常工作面有多宽」的选择。
  - **A. 12 个月** —— 热层最小、归档收益最大；但跨年度的退款争议与年度对账会频繁走二跳。
  - **B. 24 个月（推荐）** —— 覆盖两个完整的年度对账周期与任何以月计的退款 / 客诉窗口，热层仍能压掉大部分历史；在 0.5 GB / 年的估算下，热层稳定在 1 GB 量级。
  - **C. 与备份保留期对齐** —— 概念上最整齐，但备份保留期本身是成本模型的输出、当前未定 ⇒ 采纳 C 等于把本旋钮也推迟到成本模型之后。
  **推荐 B**：它是唯一一个不依赖尚未存在的输入、又能同时覆盖对账与退款两条工作面的取值；且它是旋钮，实测后可随时调。
