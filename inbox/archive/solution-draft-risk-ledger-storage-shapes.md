---
type: solution-draft
date: 2026-09-08
question: 风控事件流 / 复核队列 / 昵称扫描台账三张表各自的存储形态——落哪张表、分区键与粒度、索引、到期「整体过期」的执行方式、复核队列的领取语义。
source: operations/moderation.md:128（末行「仍待定的一项」，其指向的 open-questions/06-platform-stack.md 已不再持有该问题——见下方「一处悬空指路」）
targets: operations/moderation.md（新增「三张台账的存储形态」一节，替换末行的待定声明）· systems/account.md（「存储形态：承重列」块补三张表）· operations/environments.md（旋钮清单 + 定时任务出口各补数行）· operations/compliance-ops.md（注销执行的删除清单补两张表）· open-questions/06-platform-stack.md（删除悬空指路的承接）
status: distilled
reviewed: 2026-09-08（批量评审）—— 「仍需用户决定」的唯一取向裁决为 B：两个删除类 `kind` 另落 `deletion_audit` 表，保留 3 年，注销执行时不删。正文按被否决的 A 写就，落笔以裁决行的三点口径为准。
distilled-to: handoffs/2026-09-08-risk-ledger-storage-shapes.md
---

# 方案草稿 — 风控三张台账的存储形态

## 问题

`operations/moderation.md` 已把三样东西的**字段与语义**写全：

1. **风控事件流** —— 字段表（`eventId` / `occurredAtUtc` / `accountId` / `kind` / `severity` / `subject` / `expected` / `actual` / `requestId` / `deviceId` / `appVersion` / `contentVersion` / `context`）、`kind` 十值、四条落地纪律（只追加 · 旁路不在热路径裁决 · 不进 profile · 保留期初值 180 天）、累计阈值表与全局熔断；
2. **复核队列** —— 入队条件（词表复核级命中 · T1 检出绕过 · 适配器判待复核 / 不可达 · 存量扫描判定）与条目内容（`accountId` · 提交串 · 词表版本 · `requestId`，见 `systems/account.md` N8）；
3. **昵称扫描台账** —— 六个字段（`accountId` · `lastAcceptedNickname` · `acceptedAtUtc` · `reviewedWordlistVersion` · `reviewState` · `lastScannedAtUtc`）与三条触发源 T1 / T2 / T3。

**欠的只是落到哪张表、怎么滚动。** 它卡住两件事：`operations/moderation.md` 转 derive-ready 的最后一项；以及后端 FR 模板的 `Data & state touchpoints` 目前写不到表级（其余域都能写到表 / 列级，见 `systems/account.md` 与 `systems/profile-store.md` 的承重列块）。

**一处悬空指路（顺带订正）。** 末行把该问题「归 `open-questions/06-platform-stack.md`」，但 `06` 的抬头已改为「栈与运维形态已落定 · 余一条待实测的成本模型」，其唯一待办条目是成本模型，两点「条件化核对项」只涉第三方审核两阈值与服务商选型；全片 grep `存储形态` / `风控` / `复核` / `扫描台账` **零命中**。即 `06` 已不承接它——这个问题目前**只挂在 `moderation.md` 的末行上**，没有任何台账在跟踪。三张表在别处同样零承载：`systems/account.md` 的承重列块只有七张表、`systems/profile-store.md` 只有 `push_idem` / `receipt_idem`，而 `systems/account.md:166` 又把扫描台账推回 `operations/moderation.md`——两侧互相指路。建议本方案被采纳时一并把 `06` 的承接指路删掉（纯机械）。

## 约束（来自既有设计）

| # | 约束 | 来源 |
|---|---|---|
| K1 | **单库 PostgreSQL（单主）承载全部权威状态**；明确不引入独立文档库 / 消息队列 / 分布式事务协调器 / 分片与读写分离 | `systems/_index.md`「共用的存储与并发形态」·「明确不引入」· `decisions/ADR-0021` · `operations/environments.md` |
| K2 | `DeletionRequested` / `DeletionCancelled` 两事件**必须与 `account_deletion` 行的插入 / 删除同一次事务**——撤销即删行，事件流是库内唯一留痕 | `operations/moderation.md`「与合规域运维面的交叉点」 |
| K3 | 注销执行时**该账号的全部风控事件硬删除**，且执行是**一次事务、全有或全无** | `operations/compliance-ops.md`「执行时删什么」· `systems/account.md` D7 |
| K4 | 风控事件**只追加**：条目永不改写、永不单条删除，**到期整体过期**；保留期初值 **180 天** | `operations/moderation.md`「四条落地纪律」 |
| K5 | 事件产出是**旁路**，`push` 的应答**不等待它落盘**，绝不在同步热路径上裁决 | 同上 |
| K6 | `kind` 清单**可增量**，未知取值不驱动判定；零判定权字段一律原样记账、不拒收 | `operations/moderation.md` · `decisions/ADR-0017-*` · `systems/profile-store.md` 纪律 4 |
| K7 | 周期任务**零调度中间件、零消息队列、零分布式锁**，领取一律 `SELECT … FOR UPDATE SKIP LOCKED`，出口只有一条 | `operations/environments.md`「定时任务出口」· `operations/compliance-ops.md`「调度形态」 |
| K8 | 字段名 `snake_case`，报文 lowerCamelCase，序列化边界一次映射 | `systems/_index.md` |
| K9 | 标注「初值 / 待实测校准」的数值一律落 `config_knob` 表，不写代码常量 | `operations/environments.md`「旋钮清单」 |
| K10 | 扫描台账**落后端内部存储、不进 profile**；后端**绝不改写云端昵称** | `operations/moderation.md`「未过审昵称的存量扫描」 |

**同库既有的三条先例，本方案逐条对齐而非另立一套：**

- **月分区滚动裁剪** —— `push_idem` 按 `accepted_at_utc` 月分区、整分区滚动（`systems/profile-store.md`「`push_idem`：两个旋钮取先到者」）；
- **哈希分区 + 部分索引 + TTL 禁用断言** —— `receipt_idem`（`operations/purchase-ops.md` §3b · §3c）。它是本方案的**反向先例**：那张表必须**显式关闭**任何 TTL，风控事件反之必须过期。两条方向相反不是矛盾，判据见下方「过期代价的不对称性」；
- **不分区、存量极小即不上机制** —— `compliance_ticket`（`operations/compliance-ops.md`「签发与清理」：过期后留 24 小时、按批删除、**不分区、不设 TTL 扩展机制**）与 `signin_replay`（`systems/account.md`:46「不必分区」）。

## 建议方案

一句话总纲：**三张表同处单库、同一 schema，但形态各不相同——判据是「体量随什么增长」与「访问模式是不是点查」，不是「它们都叫台账」。**

| 表 | 体量随什么长 | 主访问模式 | 分区 | 过期 |
|---|---|---|---|---|
| `risk_event` | **时间**（只追加） | 按账号 + `kind` 的窗口计数；按版本分组的聚合 | **按 `occurred_at_utc` 月 RANGE 分区** | **整分区 `DROP`** |
| `nickname_review` | 待办积压（人工处置速度） | 按状态取待办；按 `accountId` 点查 | **不分区** | 终态行按批 `DELETE` |
| `nickname_scan` | **账号数**（一行一账号，不随时间长） | 按 `accountId` 点查；按落后的词表版本取批 | **不分区** | **无过期**（随注销硬删） |

### 1. 三张表落同一库、同一 schema，不新增存储系统

`[既有推演]` K1 已把「不引入独立存储系统」写成明确不引入项，而 K2（与 `account_deletion` 同事务）与 K3（与其余七表同一次全有或全无的删除事务）**各自单独**就要求风控事件与 `account` 域同库同实例：跨存储写入会让「行已删、事件未落」成为可达状态，那正是 K2 要留证的那一刻。复核队列与扫描台账同理——它们由昵称判定链（`systems/account.md`）与 `push` 路径（`systems/profile-store.md`）写入，都在同一进程、同一库。

**Redis 不是候选**：`systems/_index.md` 已定「Redis 只承担限流计数器，不持有任何权威状态」。复核队列的判定结果会回灌词表、扫描台账决定 `nicknameChangeRequired` 是否为真——两者都是权威状态。

**表归属的文档落点**（沿用既有分工，不新立规矩）：**承重列写 `systems/account.md` 的「存储形态：承重列」块**（三张表的写入方都在 account 域的判定链与合规域端点上），**分区 / 索引 / 裁剪 / 领取语义 / 探针写 `operations/moderation.md`**——与 `receipt_idem`（承重列在 `systems/profile-store.md`、运维形态在 `operations/purchase-ops.md`）逐字同构。

### 2. `risk_event`：按 `occurred_at_utc` 月 RANGE 分区，整分区 `DROP`

`[既有推演]` K4 的措辞是「**到期整体过期**」，不是「按行过期」——这句话本身就是分区裁剪的规格说明；`push_idem` 已经是同库同形的现成实现（按时间列月分区、整分区滚动）。反面形态（每晚 `DELETE FROM risk_event WHERE occurred_at_utc < now() - 180d`）在 PostgreSQL 上要付 dead tuple 与 autovacuum 的代价、且是一条长事务，而 `DROP TABLE <分区>` 是一次元数据操作。

`[通行做法]` **粒度取月，不取日**：180 天 ⇒ 稳态 **7 个活分区**（6 个整月 + 当月）。日分区会有 180+ 个分区，给规划器与 `DDL` 维护平白增负担，而它换来的只是过期精度。

**实际保留期因此是 [180, 210] 天，不是精确 180 天**（只有整月边界越过水位线才 `DROP`）。这一口径必须写进文档而不是留给读者推断：K4 的 180 天推导是「覆盖两倍于最长累计窗口 90 天」——它是**下界性质**，多留 30 天不违反任何既有约束（合规侧的要求是「不宜永久」，同样是上界性质）。

**分区键与主键：** PostgreSQL 的分区表唯一索引**必须含分区键**，故主键写 `(occurred_at_utc, event_id)`——与 `receipt_idem_archive` 的 `PRIMARY KEY (record_at_utc, receipt_id)` 同一形态与同一理由。`eventId` 作为「去重与工单关联的键」的语义不受影响：去重发生在写入侧（事件由服务端生成 `eventId`，不接受客户端提供），工单关联恒带时间戳。**若日后确需跨分区的全局 `event_id` 唯一性**，代价是一张单独的键表——本方案不引入，理由是当前没有任何以裸 `eventId` 为唯一入参的读路径。

**分区的创建与裁剪挂既有的一条定时任务通道**（K7），不引入分区管理插件：每轮预建**未来 2 个月**的空分区、`DROP` 早于水位线的整分区。预建余量取 2 个月而不是 1 个：一次任务连续失败一整月的情形下，写入不应当场失败（缺分区的 `INSERT` 在 PostgreSQL 上直接报错）。

### 3. `risk_event` 的索引：两条，各对一条既有查询路径

`[既有推演]` 索引不按「可能会查什么」铺，按 `moderation.md` 已经写死的两条判定路径铺——它们是这张表**全部**的读路径：

| # | 索引（逐分区） | 服务的路径 |
|---|---|---|
| I1 | `(account_id, kind, occurred_at_utc)` | **累计阈值表**：按 `kind` 在窗口内计某账号的次数（`RollMismatch` ≥1 / ≥3 次 / 90 天、`EchoRejected` ≥3 / ≥10 次 / 7 天、`NicknameViolation` ≥3 次 / 180 天）。列序是「等值 · 等值 · 范围」，标准前缀形态 |
| I2 | `(kind, occurred_at_utc)` | **全局熔断**：同一 `app_version` / `content_version` 分组内的触发率（`RollMismatch` > 1% 账号、`EchoRejected` > 0.5% 账号）。窗口内按 `kind` 取全量再按版本分组去重计数 |

- **`(app_version, content_version)` 不进索引键**：熔断是**周期性聚合**而非点查，窗口内某 `kind` 的行数本身就少（正常账号的期望值是 0，见阈值表推导），I2 取到窗口切片后在应用层 / `GROUP BY` 分组即可。把两个版本列塞进索引键只会让写放大跟着涨，而它们的基数在任一时刻都只有个位数。
- **不建 rollup / 物化聚合表。** 体量估算：这张表的写入是**异常驱动**的（正常账号的 `RollMismatch` / `EchoRejected` 期望值为 0），加上 `NicknameBypassed` / `NicknameViolation`（确定性检出，稀疏）与 `DeletionRequested` / `DeletionCancelled`（每账号一生零到一次）⇒ 稳态量级远低于 `receipt_idem`（后者 0.5 GB / 年已判为「归档不是扩容手段」）。为一个尚不存在的聚合压力先建一条派生数据路径，与 `purchase-ops.md` §3d 的「为一个尚不存在的问题增加一条正确性关键路径是不划算的」同一判据。**若熔断聚合日后真的成为负担，先按那一节的四项排除法诊断**（表 / 索引膨胀与 autovacuum · 索引膨胀 · 连接池与最长事务 · 实例规格），rollup 是最后手段。
- **`device_id` 不建索引**：它「只作观测维度，永不参与判定」（字段表已写死），没有以它为条件的判定路径。
- **`request_id` 不建索引**：两侧日志的接起来发生在日志系统侧，不是这张表的读路径。

### 4. `risk_event` 的两条删除路径，以及「只追加」到底禁的是什么

`[既有推演]` K4 说「永不单条删除」，K3 又要求注销时**逐账号硬删**——两句话必须一起读，否则实现者会二选一。**建议在文档里把语义写成这一句：**

> 业务路径上只追加：条目永不改写、永不因业务原因单条删除。**恰有两条删除路径，都不是业务路径**：① 到期的**整分区 `DROP`**（K4）；② **注销执行时按 `account_id` 的硬删**（K3，合规删除权，与其余七表同处一次全有或全无的事务）。除此之外没有任何删除 SQL。

- ② 是**跨全部活分区**的 `DELETE … WHERE account_id = ?`。7 个分区 × 单账号的稀疏行数 ⇒ 代价可忽略；I1 的前缀即 `account_id`，每个分区都能走索引。**这也是 `account_id` 必须是 I1 首列的第二个理由**（第一个是累计阈值的等值前缀）。
- **注销事务因此会与分区裁剪任务在同一批分区上并发**：`DROP` 整分区与 `DELETE` 同一分区内的行会互相等锁（`DROP` 需 `ACCESS EXCLUSIVE`）。处置沿用既有形态：裁剪任务**跑在低峰**、失败即下一轮重试（K7 的「进程中途崩溃即回滚、下一轮重新领取」）；**注销执行永不为裁剪让路**——它是本库唯一不可逆的周期动作，语义优先级最高（`operations/environments.md`）。

### 5. `risk_event` 的写入路径：默认旁路批量，三类例外同事务

`[既有推演]` K5 要求 `push` 的应答不等待事件落盘，K1 又排除了消息队列 ⇒ **进程内有界缓冲 + 后台批量 `INSERT`** 是唯一剩下的形态。三条纪律：

- **缓冲有界，溢出即丢弃并计数**，绝不反压请求路径——反压等于把旁路做回热路径，正面违反 K5。丢弃计数出一条指标（应恒为 0；非零即缓冲偏小或数据面已劣化）。
- **概率信号容得下极少量丢失**：`RollMismatch` / `ChanceInconsistent` / `InvariantViolated` / `EchoRejected` / `RevisionAhead` / `RateLimitTripped` 都带累计阈值与窗口，丢一条只让一次判定晚到。
- **三类例外必须与状态变更同一次事务，不走缓冲**：
  - `DeletionRequested` / `DeletionCancelled` —— K2 已明写，且撤销即删行 ⇒ 丢一条 = 一次客诉在服务端零证据；
  - `NicknameBypassed` —— 它「是确定性检出而非概率信号，累计计数对它无意义」（阈值表原文：≥1 次即进复核）。**没有累计冗余的信号不能走可丢弃的通道**；且它同时驱动复核入队，两者理应同事务（见下条）。

  同事务写一行 `INSERT` **不违反**「绝不在同步热路径上裁决」——被禁的是**裁决**（阈值判定、处置升级）在热路径上，不是记一行账。这层区分建议在文档里写明，否则实现者会把 K5 读成「一律异步」而把 K2 也异步掉。

### 6. `nickname_review`：不分区，状态机 + 租约，`SKIP LOCKED` 只在选行的那一瞬

`[既有推演]` + `[通行做法]`

- **不分区。** 体量随**待办积压**增长而不是随时间增长，稳态存量取决于人工处置速度（复核级命中 + T1 绕过检出，稀疏）；先例是 `compliance_ticket` 的「不分区、不设 TTL 扩展机制——稳态存量极小」与 `signin_replay` 的「不必分区」。给一张几千行的表上分区只增加维护面。
- **领取语义不能照抄合规域。** `operations/compliance-ops.md` 的四条周期任务是 `FOR UPDATE SKIP LOCKED` **持锁到事务结束**——那成立的前提是「处置在毫秒到秒级内完成」。复核是**人工**动作，持有时长以分钟计，把数据库事务开着等人点按钮会长期占住连接、把最长事务时长指标（`observability.md`「数据面」）打成常态告警，并阻塞 autovacuum。
- **建议形态：条件 `UPDATE` 取租约。** `SKIP LOCKED` 仍用，但只用在**选行的那一条语句**里，事务在语句返回即提交：

  ```
  领取（一次短事务）：
    WITH picked AS (
      SELECT review_id FROM nickname_review
       WHERE state = 'Pending'
       ORDER BY enqueued_at_utc
       FOR UPDATE SKIP LOCKED
       LIMIT :batch)
    UPDATE nickname_review r
       SET state = 'Claimed', claimed_by = :reviewer,
           claim_expires_at_utc = now() + :leaseMinutes
      FROM picked WHERE r.review_id = picked.review_id
    RETURNING …
  判定：state = 'Claimed' AND claimed_by = :reviewer 的条件 UPDATE 写入判定结果（受影响行数分支）
  租约回收：state = 'Claimed' AND claim_expires_at_utc <= now() ⇒ 置回 'Pending'，claim_attempts += 1
  ```

  - 多副本 / 多复核员安全由 `SKIP LOCKED` + 条件 `UPDATE` 的受影响行数分支共同兑现，**仍是零分布式锁、零调度中间件**（K7 一字不破）。
  - 判定写的是**条件** `UPDATE`（`WHERE claimed_by = :reviewer`），因此租约过期后原复核员的迟到提交会命中 0 行而被拒——不会覆盖已被他人处置的条目。
  - **租约超时初值 30 分钟**（旋钮，待实测校准）：一次昵称复核是秒级判断，30 分钟覆盖一次中途被打断的班次；上界的代价只是条目滞留，下界的代价是复核员正在看的条目被他人抢走。
  - `claim_attempts` 反复升高 = 某条目每次被领走都无人判定（多为疑难条目），出一条指标即可，不自动升级。
- **入队去重**：`UNIQUE (account_id) WHERE state IN ('Pending','Claimed')` ——**同一账号在办至多一条待复核**。同一玩家反复改名撞复核级会连开多条条目，让人工对同一账号重复判定；落成数据库不变式而不是应用层「先查再插」，与 `export_task` 的部分唯一索引、`session` 的活跃会话上限 1 是同一手法（`systems/_index.md`「契约条款直接落为数据库不变式」）。命中冲突 ⇒ **更新既有在办条目的提交串 / 词表版本 / `requestId` 为最新一次**，不新插行（判定要针对当前值，历史提交串的留痕在 `risk_event` 侧已有）。
- **`NicknameBypassed` 事件与入队同事务**（承接第 5 节）：两者是同一次检出的两个落点，拆开会让「事件已落、未入队」成为可达状态——那正是一次绕过检出被静默吞掉的形态。
- **终态条目按批 `DELETE`**，挂既有周期通道（同 `compliance_ticket` 的「按批删除」），保留期与风控事件同为 180 天初值（条目含玩家提交的昵称串，同属可关联到个人的行为数据，不宜永久）。注销执行时按 `account_id` 硬删（见「后果」一节的清单补项）。

### 7. `nickname_scan`：一行一账号，不分区、无过期

`[既有推演]`

- **独立表，不给 `account` 加列。** 两条理由：① `account` 行是全库唯一的并发单元（`systems/_index.md`），扫描任务批量更新 `last_scanned_at_utc` 会与 `signin` / `push` / `bind` 争同一把行锁——把一条纯离线批处理（T3「纯离线批处理、可错峰」）塞进玩家热路径的锁竞争里；② 六个字段里有五个只有扫描链路读写，与 `account` 的读频次差若干数量级。
- **不分区、无到期过期。** 体量 = 账号数、**不随时间增长**（每账号恒一行、原地更新），与「随时间只追加」的 `risk_event` 不同轴。生命周期跟账号：**注销执行时硬删**（它含 `last_accepted_nickname`，属可关联到个人的数据）。
- **`account_id` 主键**（同时是 T1 的点查键：`push` 解 `playerDiff` 顶层键后比对本次 `nickname` 与 `last_accepted_nickname`，一次主键点查 + 一次字符串比较）。
- **两条索引对应 T2 / T3：**
  - `(reviewed_wordlist_version)` —— T2 取「落后于最新词表版本」的批。词表版本基数极低（每次发布 +1），但选择率在一次发布后接近 100% ⇒ 该索引主要服务**发布后期**（多数账号已重扫完、只剩少数落后者）的收尾扫描；发布初期规划器自行选顺序扫描是正确的选择，不必干预。
  - `(last_scanned_at_utc)` —— T3 的 30 天兜底全量按此列取批并推进水位，天然分页、可错峰、可中断续跑。
- **`review_state` 存 `text`，不用数据库 enum**（K6 与 K8：`kind` 清单可增量、`status` / `tier` 等既有列均为 `text NOT NULL`）。加一个档位不应当是一次 DDL 迁移。
- **行的创建时点**：建号骨架不建这张表的行（新账号无昵称）；**首次经改名端点接受时插入**（`INSERT … ON CONFLICT (account_id) DO UPDATE`），T1 在无行时视为「从未经端点接受过昵称」⇒ 若 `push` 带来非空 `nickname` 即判绕过（这与 T1 的既有语义一致：`lastAcceptedNickname` 无值而云端有值，正是绕过端点的定义）。

### 8. 过期与 TTL 断言：与 `receipt_idem` 方向相反，判据是代价的不对称性

`[既有推演]` `operations/purchase-ops.md` §3c 要求 `receipt_idem` **显式关闭**任何 TTL 并在部署时断言（读取过期策略，非「永不过期」即拒绝启动）。本方案的三张表**两张必须过期、一张永不过期**，因此**不能把那条断言当作全库通则照抄**。建议把判据写明：

| 表 | 过期方向 | 少留的代价 | 多留的代价 |
|---|---|---|---|
| `receipt_idem` | **永不过期**（断言拒绝启动） | 一次**不可发现的重复发放**（第二次提交查不到即当作新票） | ≈ 0（0.5 GB / 年） |
| `risk_event` · `nickname_review` | **必须过期** | 最多一条晚到的判定 / 一次审计线索（保留期已是最长累计窗口的两倍） | **个人信息超期留存**——合规风险，且体量随时间线性增长 |
| `nickname_scan` | **无过期**（一行一账号，不随时间长） | — | ≈ 0；随注销硬删 |

- **`risk_event` 的机制发现面：一条「分区裁剪滞后量」探针**（当前最老活分区的年龄 − 保留期上界；阈值应恒接近 0）。它与 `operations/compliance-ops.md` 的「到期扫描滞后量」是同一手法、同一理由——**那是「个人信息超期留存」唯一的机制发现面**。裁剪任务默默失败三个月不会有任何人发现，除非有这条数。
- **`nickname_review` 的对偶指标：待办积压量与最老 `Pending` 条目年龄**。前者是人工处置容量是否够的信号，后者防「某条目永远排不到」。

## 具体形态（可 derive 的落地面）

### 表形态（承重列，非完整 DDL；`snake_case` 照 K8）

```
risk_event                                   -- PARTITION BY RANGE (occurred_at_utc)，月分区
  occurred_at_utc     timestamptz NOT NULL   -- 分区键
  event_id            text        NOT NULL   -- 去重与工单关联；服务端生成
  account_id          uuid        NOT NULL
  kind                text        NOT NULL   -- 十值，可增量；不用 DB enum
  severity            text        NOT NULL   -- Info | Warn | Critical
  subject             text                   -- JSON path 或字段名
  expected            text                   -- 一律字符串序列化（字段表已定）
  actual              text
  request_id          text
  device_id           text                   -- 只作观测维度，永不参与判定 ⇒ 不建索引
  app_version         text
  content_version     text
  context             jsonb                  -- 按 kind 取固定形状
  PRIMARY KEY (occurred_at_utc, event_id)    -- 分区表唯一索引须含分区键
  每分区： INDEX (account_id, kind, occurred_at_utc)   -- I1 累计阈值 + 注销按账号硬删
           INDEX (kind, occurred_at_utc)               -- I2 全局熔断的窗口切片

nickname_review                              -- 不分区
  review_id           uuid        PK
  account_id          uuid        NOT NULL
  submitted_nickname  text        NOT NULL   -- 提交串（原串，非归一化串）
  wordlist_version    bigint      NOT NULL   -- 判定所依据的词表版本
  request_id          text
  enqueue_reason      text        NOT NULL   -- ReviewWord | Bypassed | AdapterReview | ScanHit
  state               text        NOT NULL   -- Pending | Claimed | Decided
  decision            text                   -- Violation | Clean（终态才有值）
  claimed_by          text                   -- 复核员标识
  claim_expires_at_utc timestamptz           -- 租约
  claim_attempts      int         NOT NULL DEFAULT 0
  enqueued_at_utc     timestamptz NOT NULL
  decided_at_utc      timestamptz
  UNIQUE (account_id) WHERE state IN ('Pending','Claimed')   -- 同一账号在办至多一条
  INDEX (state, enqueued_at_utc)                             -- 领取：取最老的待办批
  INDEX (state, claim_expires_at_utc)                        -- 租约回收扫描
  INDEX (decided_at_utc) WHERE state = 'Decided'             -- 终态按批删除

nickname_scan                                -- 不分区、无过期，一行一账号
  account_id                uuid        PK
  last_accepted_nickname    text                   -- 最近一次经改名端点接受的值
  accepted_at_utc           timestamptz
  reviewed_wordlist_version bigint                 -- 上次按哪一版词表通过（T2 的增量面）
  review_state              text        NOT NULL   -- 处置档位，text 不用 enum
  last_scanned_at_utc       timestamptz
  INDEX (reviewed_wordlist_version)                -- T2
  INDEX (last_scanned_at_utc)                      -- T3 兜底全量取批与水位推进
```

### 定时任务（并入 `operations/environments.md`「定时任务出口」表，共用同一条通道）

| 任务 | 频次（初值） | 领取 / 动作 |
|---|---|---|
| `risk_event` 分区维护 | 日频、低峰 | 预建未来 2 个月空分区；`DROP` 早于保留期上界的整分区 |
| `nickname_review` 租约回收 | 5 分钟 | `state='Claimed' AND claim_expires_at_utc <= now()` ⇒ 置回 `Pending`，`claim_attempts += 1` |
| `nickname_review` 终态清理 | 日频 | `state='Decided' AND decided_at_utc < now() - :retention` 按批 `DELETE` |
| 存量扫描 T2（词表版本驱动） | 每次词表发布后一轮 | 取 `reviewed_wordlist_version` 落后的批 |
| 存量扫描 T3（定期兜底全量） | 30 天 / 轮（既有初值） | 按 `last_scanned_at_utc` 取批、推进水位；纯离线、可错峰、可中断续跑 |

四条任务全部 `FOR UPDATE SKIP LOCKED` 的条件转移，零新增组件（K7）。

### 旋钮（并入 `operations/environments.md`「旋钮清单」，权威列指向 `operations/moderation.md`）

| 旋钮 key | 初值 | 说明 |
|---|---|---|
| `riskEventRetentionDays` | **180**（既有初值，本方案不改） | 保留期水位线；月分区 ⇒ 实际保留 [180, 210] 天 |
| `riskEventPartitionAheadMonths` | 2 | 预建空分区的余量；缺分区的 `INSERT` 会直接失败 |
| `riskEventBufferRows` | 待定（随实测） | 进程内旁路缓冲上界；溢出即丢弃并计数 |
| `nicknameReviewClaimLeaseMinutes` | 30 | 复核租约；超时置回 `Pending` |
| `nicknameReviewRetentionDays` | 180 | 终态条目清理水位，与风控事件同期 |
| `nicknameScanSweepDays` | 30（既有初值，T3） | 定期兜底全量周期 |

### 探针（口径落 `operations/observability.md`，与既有三条同步探针并列）

| 探针 | 期望 | 它是什么的唯一发现面 |
|---|---|---|
| `risk_event` 分区裁剪滞后量 | 恒接近 0 | **个人信息超期留存**（同 `compliance-ops.md` 的到期扫描滞后量） |
| 旁路缓冲丢弃计数 | 恒 0 | 缓冲偏小 / 数据面劣化 |
| `nickname_review` 待办积压量 · 最老 `Pending` 年龄 | 有界 | 人工处置容量不足 / 某条目永远排不到 |
| `claim_attempts` 高位条目数 | 接近 0 | 疑难条目反复被领走却无人判定 |

### 可验证的服务端保证（后端库体例：请求 → 应答 / 存储状态；与 `systems/account.md` 的 N* / S* 同体例）

| # | 输入 | 期望 |
|---|---|---|
| R1 | 注销申请端点成功返回 | `account_deletion` 行与一条 `DeletionRequested` 事件**在同一事务内**落库；杀死进程于两者之间 ⇒ 两者都不存在 |
| R2 | 撤销端点成功返回 | `account_deletion` 行已删 · `status` 已恢复 `previous_status` · 一条 `DeletionCancelled` 事件已落，三者同事务 |
| R3 | 注销执行完成后 | 该 `account_id` 在 `risk_event` · `nickname_review` · `nickname_scan` 中**零行**；`receipt_idem` 该账号行仍在（既有 D7） |
| R4 | 分区裁剪任务跑过一轮 | 最老活分区的上界不早于 `now() - riskEventRetentionDays - 31 天`；无任何单条 `DELETE` 语句执行 |
| R5 | 写入落在尚无分区的月份 | 分区维护任务已预建 ⇒ `INSERT` 成功；人为删除预建分区后 `INSERT` 失败并告警（不静默丢） |
| R6 | 两个容器同时领取复核队列 | 每条待办**恰好被一个复核员领到**（同既有 D6 的体例） |
| R7 | 复核员租约超时后提交判定 | 命中 0 行、判定被拒；条目已回 `Pending` 或已被他人判定，**不被覆盖** |
| R8 | 同一账号连续两次撞复核级词表 | `nickname_review` 中该账号在办条目恒为 **1** 条，提交串 / 词表版本更新为最新一次 |
| R9 | `push` 上行触发一条 `EchoRejected` | 应答**不等待**事件落盘（应答延迟与不产事件时同量级） |
| R10 | `push` 检出 `NicknameBypassed` | 事件与复核队列条目**同事务**落库；不存在「事件已落、未入队」的可达状态 |
| R11 | 新词表版本发布后 | `reviewed_wordlist_version` 落后的账号被重扫；已是最新版本的账号不重扫（既有 S3，此处给出索引支撑） |

## 后果

- **`operations/moderation.md`**：末行的「仍待定的一项」被一节「三张台账的存储形态」替换（分区 / 索引 / 裁剪 / 领取语义 / 探针 / 两条删除路径的语义澄清）。该文件因此**不再有待定项**——转 derive-ready 的最后一个卡点闭合（就绪度评估仍归 `/assess-derive-readiness`，本草稿不评估）。
- **`systems/account.md`**：「存储形态：承重列」块由七张表增至十张；「昵称判定链与存量扫描的服务内部形态」一节的 `:166` 那句「扫描台账见 `operations/moderation.md`」可保留（形态在运维侧，承重列在此处，与 `receipt_idem` 同构），互相指路的死循环随之解开。
- **`operations/compliance-ops.md`「执行时删什么」表需补两行**（`nickname_review` · `nickname_scan` 硬删，理由：含玩家提交的昵称串，属可关联到个人的行为数据；风控事件那一行已在表内）。**这是必须的补项，不是可选装饰**——漏掉即注销后仍留着该玩家的昵称串与复核记录，而 K3 的删除清单是逐类别穷举的。对应 `systems/account.md` 的注销执行事务行同改。
- **`operations/environments.md`**：「旋钮清单」+6 行、「定时任务出口」+2 行（分区维护 · 复核租约回收与终态清理；两条扫描任务可并入既有行或另列）。
- **`operations/observability.md`**：+4 条探针口径。
- **`open-questions/06-platform-stack.md`**：删掉对本问题的承接指路（当前已悬空，见「问题」一节）。
- **不触碰任何契约**：三张表全是后端内部状态，`contracts/*` 的报文一字不改；`profile` 的 `doc` 也不新增字段（K10）。
- **无迁移负担**：三张表都是新建，不涉及 `expand → deploy → contract`（`operations/deployment.md`）——首版即建。

## 备选方案（已考虑并否决）

- **`risk_event` 用日 `DELETE` 而非分区** —— dead tuple 与 autovacuum 代价、长事务，且 K4 的「整体过期」字面就否决了它。
- **`risk_event` 日分区** —— 180+ 活分区换来的只是过期精度，而保留期是下界性质。
- **`risk_event` 只落日志 / 指标出口**（`systems/_index.md`「明确不引入」一节的措辞倾向） —— K2 要求与 `account_deletion` 同事务、K3 要求按账号硬删、累计阈值要求按窗口计数：三条各自单独就排除了纯日志形态。见「与既有决策的张力」。
- **`event_id` 单列全局唯一** —— PostgreSQL 分区表唯一索引必须含分区键；要全局唯一得另立一张键表，而当前没有以裸 `eventId` 为唯一入参的读路径。
- **风控三表挂 Redis（`event_id` 去重 / 队列）** —— `systems/_index.md` 已定 Redis 不持有权威状态；且 K2 的同事务要求直接排除。
- **复核队列用 `FOR UPDATE SKIP LOCKED` 持锁到人工判定结束**（照抄合规域四条任务） —— 人工持有时长以分钟计，会长期占住连接、打爆最长事务时长指标、阻塞 autovacuum。
- **复核队列按时间分区** —— 体量随积压而非时间增长，稳态存量极小（同 `compliance_ticket` 判据）。
- **扫描台账并进 `account` 表加六列** —— `account` 行是全库唯一并发单元，离线批处理会与玩家热路径争行锁。
- **给 `risk_event` 建按 `(kind, app_version, content_version, 小时)` 的 rollup 表** —— 为尚不存在的聚合压力先建一条派生数据路径；先按 `purchase-ops.md` §3d 的四项排除法诊断。
- **`kind` / `severity` / `review_state` 用数据库 enum** —— 与 K6「清单可增量」相抵，加一档变成一次 DDL 迁移。

## 与既有决策的张力

**一条，措辞级而非实质级：`systems/_index.md`「明确不引入 · 消息队列」那条的收尾句写「风控事件与告警走日志 / 指标出口即可」。**

- 这句话的**论证对象是「不需要消息队列」**，本方案与该结论完全一致（旁路批量写库，零 MQ）。但它的字面表述「走日志 / 指标出口」会被读成「风控事件不落库」——而 `operations/moderation.md` 后续定的 K2（与 `account_deletion` 同事务）、`operations/compliance-ops.md` 定的 K3（注销时按账号硬删）与累计阈值的窗口计数，**三条各自单独**都要求它是一张关系表。写入日志的一行既无法参与事务，也无法被按账号删除。
- **松动代价 ≈ 0，因为两者不在同一命题上**：建议把那句改写为「风控事件落同库的 `risk_event` 表（旁路批量写入，见 `operations/moderation.md`），告警走指标出口——**两者都不需要消息队列**」。结论（不引入 MQ）与它的论证一字不动。
- **不松动时的替代方案**：不存在可行的——放弃落库就要放弃 K2 的留证义务（一次「我明明撤销过」的客诉在服务端零证据）与 K3 的合规删除义务。故建议按上述改写，而非在两条之间取舍。**改写权在用户 / `/analyze-new-ideas`，本草稿不动主题文档。**

## 前置依赖

- **无阻塞项。** 本方案不依赖任何仍待答的问题：栈已落定（`decisions/ADR-0021`），三张表的字段与语义已由 `operations/moderation.md` 写全。
- **`open-questions/06` 的「成本模型」不构成前置**：它欠的是实例规格 / 备份保留期一类需真实体量的数值，而本方案给出的是形态；三张表的体量本身是异常驱动与账号数驱动的低量级，不参与成本模型的关键路径。
- **仅一处取值待实测**：`riskEventBufferRows`（旁路缓冲上界）随上线后的事件速率标定——它已按 K9 落旋钮表，改值不发版。

## 仍需用户决定

**一条（真取向 · 涉合规与客诉风险偏好，无客观最优）：`DeletionRequested` / `DeletionCancelled` 两值是否沿用 180 天保留期。**

`operations/moderation.md` 现已写明这两值「保留期沿用下方的 180 天」。但 180 天的推导是「覆盖两倍于最长累计窗口 90 天」——那是**风控判定**的时间尺度。这两值的用途是**另一条轴**：撤销即删行 ⇒ 事件流是「谁在什么时候申请过 / 撤销过」在库内的**唯一**留痕，而它直接决定账号是否被删除。一次「我明明撤销过、账号却被删了」的客诉可能在半年、一年后才到（玩家往往在想回来玩时才发现），届时事件已随分区 `DROP` 消失，服务端零证据。

| 选项 | 后果 |
|---|---|
| **A. 沿用 180 天**（既有文本，零改动） | 形态最简：一条保留期、一条裁剪路径。代价是 180–210 天之后的注销类客诉在服务端不可举证；账号已删、`identity` 已删，连「这个人是否存在过」都只剩 `account` 墓碑的 `deleted_at_utc` |
| **B. 两值单独更长保留期**（推荐，例如 3 年，与交易记录法定保存期同量级） | 需要一条例外规则。**建议的最简形态：这两值不写 `risk_event`，另落一张极小的 `deletion_audit` 表**（每账号一生零到一次，永不裁剪或按 3 年裁剪，且**注销执行时不删**——它不含个人信息，`context` 已明写「不含任何个人信息」，与 `account` 墓碑同一性质）。代价是多一张表 + K2 的同事务要求要落到这张表上（形态不变，仍是同库同事务） |
| C. 全表保留期统一提到 3 年 | 否决建议：其余八个 `kind` 是可关联到个人的行为数据，`moderation.md` 已判「不宜永久」；为两个值把全部事件多留 2.5 年，与该判断正面相悖 |

**推荐 B。** 判据是「过期代价的不对称性」——与 `receipt_idem` 永不设 TTL 是同一条判据的第二次应用：这两值多留的代价是一张几乎为空的表（每账号一生零到一次），少留的代价是一条**不可举证**的删号客诉。而 B 的实现代价被 `context` 的既有约束压到极低：它已明写「不含任何个人信息」，因此长留不构成个人信息超期留存，也就不需要为它设计任何删除路径。

**A 与 B 只影响一条例外规则，不影响本方案其余任何一节**：本草稿的表形态、索引、裁剪、领取语义均按 A（180 天、两值同处 `risk_event`）写就；选 B 则追加一张 `deletion_audit` 表并把这两个 `kind` 的写入点改指向它，其余一字不改。

→ **已裁决（2026-09-08 · 批量评审）：选 B —— 另落 `deletion_audit` 表，保留 3 年。**
> **⚠ 本草稿正文按 A 写就，凡与本裁决相抵之处一律以本裁决为准**，提炼时按以下三点落笔：
> ① `DeletionRequested` / `DeletionCancelled` 两个 `kind` **不写 `risk_event`**，改写入新增的 `deletion_audit` 表（每账号一生零到一次）；
> ② 该表保留 **3 年**，**注销执行时不删**——依据是 `context` 既有的「不含任何个人信息」约束，与 `account` 墓碑同一性质，因此不构成个人信息超期留存、无需删除路径；
> ③ K2 的「与 `account_deletion` 状态变更同事务」要求原样落到这张表上（同库同事务，形态不变）。
> 其余八个 `kind` 的 180 天保留期与整分区 `DROP` 裁剪**一字不改**。
