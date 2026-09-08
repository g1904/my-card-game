# Answer log risk-ledger-storage-shapes

- 日期：2026-09-08
- 来源：`inbox/solution-draft-risk-ledger-storage-shapes.md`（提炼为 `handoffs/2026-09-08-risk-ledger-storage-shapes.md`）
- 移出条数：1

**风控事件流 / 复核队列 / 昵称扫描台账自身的存储形态（分区、索引、到期整体过期的执行方式、复核队列的领取语义）** → 三样东西落**四张表**，同处单库同一 schema、形态各不相同（判据是「体量随什么增长」与「访问模式是不是点查」）：`risk_event` 按 `occurred_at_utc` 月 RANGE 分区、整分区 `DROP`（180 天水位 ⇒ 实际 [180, 210] 天）、两条索引各对一条既有判定路径、写入走进程内有界缓冲 + 后台批量 `INSERT`；`deletion_audit` 单独承载 `DeletionRequested` / `DeletionCancelled`，不分区、保留 3 年、注销执行时不删；`nickname_review` 不分区、状态机 + 条件 `UPDATE` 取租约（`SKIP LOCKED` 只在选行的那一瞬）、部分唯一索引兑现「同一账号在办至多一条」；`nickname_scan` 一行一账号、不分区、无到期过期、随注销硬删。（归档去向：`operations/moderation.md`「四张台账的存储形态」· `systems/account.md`「存储形态：承重列」与事务边界 · `operations/environments.md` 旋钮清单与定时任务出口 · `operations/compliance-ops.md`「执行时删什么」）

**部分答定的两点，剩余部分仍留待答：**

- `riskEventBufferRows`（旁路缓冲上界）的**取值**待上线后按事件速率标定；形态与旋钮落点已定（改值不发版）。
- `DeletionRequested` / `DeletionCancelled` 的保留期取向由用户在本次批量评审中裁决为「另落 `deletion_audit`、保留 3 年、注销不删」；判据是过期代价的不对称性（多留 ≈ 一张几乎为空的表，少留 = 一条不可举证的删号客诉），且条目不含个人信息故不构成超期留存。

**顺带订正的一处悬空指路：** `operations/moderation.md` 末行原把本问题「归 `open-questions/06-platform-stack.md`」，而该分片已不承接它（全片对「存储形态 / 风控 / 复核 / 扫描台账」零命中）；该指路随本次落笔一并删除。
