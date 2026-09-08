# 风控三张台账的存储形态（四张表）

- id: 2026-09-08-risk-ledger-storage-shapes
- date: 2026-09-08
- topic: operations/moderation · systems/account · operations/environments · operations/compliance-ops · operations/observability
- status: distilled
- distilled-to: operations/moderation.md, systems/account.md, operations/environments.md, operations/compliance-ops.md

## Intent（distilled）

`operations/moderation.md` 已把风控事件流、复核队列、昵称扫描台账三样东西的**字段与语义**写全，欠的只是**落到哪张表、怎么滚动**。本 handoff 补齐这一层：分区、索引、到期执行方式、复核队列的领取语义、探针与旋钮。

**一句话总纲：四张表同处单库、同一 schema，但形态各不相同——判据是「体量随什么增长」与「访问模式是不是点查」，不是「它们都叫台账」。**

三样东西落**四张表**：注销审计的两个 `kind`（`DeletionRequested` / `DeletionCancelled`）与风控判定不在同一条时间轴上，单独成表。

| 表 | 体量随什么长 | 主访问模式 | 分区 | 过期 |
|---|---|---|---|---|
| `risk_event` | 时间（只追加） | 按账号 + `kind` 的窗口计数；按版本分组的聚合 | 按 `occurred_at_utc` 月 RANGE 分区 | 整分区 `DROP`（180 天水位） |
| `deletion_audit` | 账号数（一生零到少数几行） | 按 `account_id` 点查（客诉举证） | 不分区 | 按批 `DELETE`（3 年水位）；注销执行不删 |
| `nickname_review` | 待办积压（人工处置速度） | 按状态取待办；按 `account_id` 点查 | 不分区 | 终态行按批 `DELETE`（180 天） |
| `nickname_scan` | 账号数（一行一账号） | 按 `account_id` 点查；按落后的词表版本取批 | 不分区 | 无到期过期；随注销硬删 |

### 1. 四张表落同一库、同一 schema，不新增存储系统

「不引入独立存储系统」已是明确不引入项（`systems/_index.md` · `decisions/ADR-0021`）；而「注销审计事件与 `account_deletion` 行同事务」与「注销执行是一次全有或全无的删除事务」**各自单独**就要求这些表与 `account` 域同库同实例——跨存储写入会让「行已删、事件未落」成为可达状态，那正是要留证的那一刻。

Redis 不是候选：它只承担限流计数器、不持有权威状态，而复核判定结果会回灌词表、扫描台账决定 `nicknameChangeRequired` 是否为真，两者都是权威状态。

**文档落点沿用既有分工**：承重列写 `systems/account.md`（写入方都在 account 域的判定链与合规域端点上），分区 / 索引 / 裁剪 / 领取语义 / 探针写 `operations/moderation.md`——与 `receipt_idem` 的分工逐字同构。

### 2. `risk_event`：月 RANGE 分区，整分区 `DROP`

「到期整体过期」这句话本身就是分区裁剪的规格说明；`push_idem` 已是同库同形的现成实现。粒度取月不取日：180 天 ⇒ 稳态 7 个活分区；日分区的 180+ 个分区只换来过期精度。**实际保留期因此是 [180, 210] 天**——180 天的推导是「覆盖两倍于最长累计窗口 90 天」，是下界性质，多留 30 天不违反任何约束。

主键 `(occurred_at_utc, event_id)`（分区表唯一索引必须含分区键）。分区的预建与裁剪挂既有的定时任务通道，预建未来 2 个月余量——缺分区的 `INSERT` 在 PostgreSQL 上直接报错，一次任务连续失败一整月不应让写入当场失败。

### 3. 两条索引，各对一条既有读路径

- `(account_id, kind, occurred_at_utc)` —— 累计阈值表的窗口计数（等值 · 等值 · 范围的标准前缀形态），同时是注销按账号硬删的走索引前缀。
- `(kind, occurred_at_utc)` —— 全局熔断的窗口切片，取到后按 `app_version` / `content_version` 分组聚合。

`(app_version, content_version)` 不进索引键（周期性聚合而非点查，基数个位数）；`device_id` 不建索引（永不参与判定）；`request_id` 不建索引（两侧日志的接起来发生在日志系统侧）。不建 rollup 表：写入是异常驱动的，稳态量级远低于 `receipt_idem`。

### 4. 「只追加」到底禁的是什么

业务路径上只追加：条目永不改写、永不因业务原因单条删除。恰有两条删除路径，都不是业务路径：① 到期的整分区 `DROP`；② 注销执行时按 `account_id` 的硬删。除此之外没有任何删除 SQL。

注销事务会与裁剪任务在同一批分区上并发（`DROP` 需 `ACCESS EXCLUSIVE`）：裁剪跑低峰、失败即下一轮重试；注销执行永不为裁剪让路。

### 5. 写入路径：默认旁路批量，两类例外同事务

`push` 的应答不等待事件落盘 + 无消息队列 ⇒ 进程内有界缓冲 + 后台批量 `INSERT` 是唯一剩下的形态。缓冲有界、溢出即丢弃并计数，绝不反压请求路径——反压等于把旁路做回热路径。带累计阈值与窗口的概率信号容得下极少量丢失。

两类例外不走缓冲、必须与状态变更同一次事务：
- `DeletionRequested` / `DeletionCancelled` 写 `deletion_audit`，与 `account_deletion` 行的插入 / 删除同事务；
- `NicknameBypassed` 是确定性检出、没有累计冗余，且与复核入队是同一次检出的两个落点。

同事务写一行 `INSERT` 不违反「绝不在同步热路径上裁决」：被禁的是**裁决**（阈值判定、处置升级）在热路径上，不是记一行账。

### 6. `deletion_audit`：注销审计单独成表，保留 3 年，注销执行不删

`DeletionRequested` / `DeletionCancelled` 的用途与风控判定不在同一条轴上：撤销即删行 ⇒ 它是「谁在什么时候申请过 / 撤销过」在库内的唯一留痕，而这条路径直接决定账号是否被删除。一次「我明明撤销过、账号却被删了」的客诉往往在半年、一年后才到（玩家在想回来玩时才发现）。

保留期取 3 年（与交易记录法定保存期同量级）。它不含个人信息（`context` 已明写「不含任何个人信息」），与 `account` 墓碑同一性质，因此**注销执行时不删**，长留也不构成个人信息超期留存。

判据是过期代价的不对称性：多留的代价是一张几乎为空的表（每账号一生零到少数几行），少留的代价是一条不可举证的删号客诉。

不给整张 `risk_event` 统一提到 3 年：其余八个 `kind` 是可关联到个人的行为数据，「不宜永久」的判断对它们仍然成立。

### 7. `nickname_review`：不分区，状态机 + 租约

体量随待办积压而非时间增长，稳态存量极小（同 `compliance_ticket` 与 `signin_replay` 的判据）。

**领取语义不能照抄合规域的四条周期任务**：那四条 `FOR UPDATE SKIP LOCKED` 持锁到事务结束，成立前提是「处置在毫秒到秒级内完成」。复核是人工动作、持有时长以分钟计，把数据库事务开着等人点按钮会长期占住连接、把最长事务时长指标打成常态告警、阻塞 autovacuum。

形态是**条件 `UPDATE` 取租约**：`SKIP LOCKED` 只用在选行的那一条语句里，事务在语句返回即提交；判定写条件 `UPDATE`（`WHERE claimed_by = :reviewer`），租约过期后原复核员的迟到提交命中 0 行而被拒；租约超时由周期任务置回 `Pending` 并 `claim_attempts += 1`。仍是零分布式锁、零调度中间件。

入队去重落成数据库不变式：`UNIQUE (account_id) WHERE state IN ('Pending','Claimed')`——同一账号在办至多一条。命中冲突即更新既有在办条目的提交串 / 词表版本 / `requestId` 为最新一次。

终态条目按批 `DELETE`，保留期 180 天（条目含玩家提交的昵称串）。注销执行时按 `account_id` 硬删。

### 8. `nickname_scan`：一行一账号，不分区、无到期过期

不给 `account` 加列：`account` 行是全库唯一的并发单元，扫描任务批量更新 `last_scanned_at_utc` 会与 `signin` / `push` / `bind` 争同一把行锁，把一条纯离线批处理塞进玩家热路径的锁竞争里；且六个字段里有五个只有扫描链路读写。

体量 = 账号数，不随时间增长 ⇒ 不分区、无到期过期；生命周期跟账号，注销执行时硬删（含 `last_accepted_nickname`）。`account_id` 主键即 T1 的点查键。两条索引对应 T2（`reviewed_wordlist_version`）与 T3（`last_scanned_at_utc`，天然分页、可错峰、可中断续跑）。

行的创建时点：建号骨架不建行（新账号无昵称）；首次经改名端点接受时插入。T1 在无行时视为「从未经端点接受过昵称」。

### 9. 过期方向不是全库通则

`receipt_idem` 必须显式关闭 TTL 并在部署时断言，本批四张表却有三张必须过期——两者方向相反不是矛盾，判据是代价的不对称性（少留的代价 vs 多留的代价）。这条判据要写明，否则那条 TTL 断言会被当作全库通则照抄。

`risk_event` 的分区裁剪滞后量是「个人信息超期留存」唯一的机制发现面：裁剪任务默默失败三个月不会有任何人发现，除非有这条数。

## Clarifications

- **`DeletionRequested` / `DeletionCancelled` 是否沿用 180 天保留期？** → 不沿用：两值不写 `risk_event`，另落 `deletion_audit` 表，保留 3 年，注销执行时不删；「与 `account_deletion` 状态变更同事务」的要求原样落到这张表上。其余八个 `kind` 的 180 天保留期与整分区 `DROP` 裁剪不变。（用户裁决；原始草稿正文按「沿用 180 天、两值同处 `risk_event`」写就，本 handoff 已按裁决重写受影响的每一节。）
- **`systems/_index.md`「明确不引入 · 消息队列」的收尾句「风控事件与告警走日志 / 指标出口即可」措辞会被读成「风控事件不落库」。** → 该句的论证对象是「不需要消息队列」，本方案与该结论一致（旁路批量写库，零 MQ）；但字面表述与「同事务留证 / 按账号硬删 / 窗口计数」三条各自单独的要求相抵。建议改写为「风控事件落同库的 `risk_event` 表（旁路批量写入），告警走指标出口——两者都不需要消息队列」。**本 handoff 不改 `systems/_index.md`**，该措辞订正列为待办。

## Open questions

- `riskEventBufferRows`（旁路缓冲上界）随上线后的事件速率标定；已按旋钮落表，改值不发版。
- `systems/_index.md`「明确不引入 · 消息队列」的收尾措辞是否按上述建议改写（结论不变，仅措辞）。

## Notes / triage

路由：`operations/moderation.md`（新增「四张台账的存储形态」一节，替换末行的待定声明 + 数值初值表补 5 行）· `systems/account.md`（承重列块补四张表 · 注销执行事务行同改）· `operations/environments.md`（旋钮清单 + 定时任务出口各补行）· `operations/compliance-ops.md`（「执行时删什么」表补 `nickname_review` · `nickname_scan` 两行，并写明 `deletion_audit` 不在删除清单内的理由）· `operations/observability.md`（+4 条探针口径）。

## 客户端侧影响

**无。** 四张表全是后端内部状态，`contracts/*` 的报文一字不改，`profile` 的 `doc` 不新增字段。客户端的 `account-service` / `sync-service` 无需任何改动。
