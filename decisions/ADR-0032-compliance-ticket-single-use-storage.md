# ADR-0032 — `complianceTicket` 落主库，一次性消费做成条件更新，回放窗口做成寿命的延长

- **状态：** Accepted
- **日期：** 2026-09-06
- **来源：** handoffs/2026-09-06-compliance-domain-storage.md · answer-logs/log-compliance-domain-storage.md

## 背景

`contracts/compliance.md` §3 定死了 ticket 的契约语义（一次性 · 10 分钟 · 单端点 · 不进 `Authorization` 头），`ADR-0020` 又给它加了 60 秒回放窗口（回放不消费、无副作用），但两者都把**存储形态与保留期**留给了 `operations/` 与 `systems/`。「一次性」与「回放窗口」在实现上会撞出一个边角：同时已过期且在窗口内，该算什么。

## 决策

`complianceTicket` 的消费态落**主库一张表**（`compliance_ticket`），不落 Redis；存哈希不存明文，`response_snapshot` 只装应答体。一次性 + 60 秒回放落成**一次条件更新 + 受影响行数分支**，五步求值顺序写死。

**关键一笔：消费时把 `expires_at_utc` 拉到 `max(原值, consumed_at_utc + 60 秒)`**，使回放窗口成为**寿命的延长**，而不是与寿命竞争的第二把尺。

**外部 HTTP 调用是「消费标记与它守护的写入同事务」的唯一例外**：取「条件更新占位消费并提交 → 调核验 → 第二次事务写结果与快照」两段；中间态回 `server.unavailable`（`Retryable`），终局出路是重走 `signin` 拿新 ticket。

形态与 SQL 见 `operations/compliance-ops.md`；表定义与事务边界见 `systems/account.md`。

## 理由

Redis 不持有任何权威状态（`systems/_index.md`），跨存储会造出「ticket 已消费但结果未落」或其反面。消费标记必须与它守护的状态写入同事务——这是 `signin_replay` 已经确立的判据，**ticket 是它的第二个实例**。

做成寿命的延长后**边角消失**：`Expired` 与 `Consumed` 在任何时刻都互斥且确定，不需要在契约里再定一个口径。

两段事务的终局出路必须写下，否则这条路径没有尽头；而它的代价上界只是「一次重新登录」，因此不需要任何补偿任务或人工介入。

## 备选方案

- ticket 放 Redis — 跨存储无法与状态写入同事务。
- 先 `SELECT` 再 `UPDATE` — 照 CAS 的既有手法用受影响行数分支即可（`systems/profile-store.md`）。
- 把 60 秒窗口做成独立于寿命的第二把尺 — 留下「同时已过期且在窗口内」这个契约未定口径的边角。
- 外部核验放进持锁事务 — 把外部延迟变成锁持有时长。
- 为两段事务的中间态设补偿任务或新增 `code` — 代价上界只是一次重新登录，且与契约既有的「核验服务不可达 → `server.unavailable`」逐字一致。

## 后果

- 合规域因此不需要独立的 KV 存储；`ADR-0021`「全部权威状态落单主关系库」在本域得到兑现。
- `ADR-0020` 的契约语义与本条的存储形态互为两半，各自可被单独推翻：改存储不改报文，改窗口才动契约。
- 到期判定的时刻基准由 `ADR-0028` 提供。
