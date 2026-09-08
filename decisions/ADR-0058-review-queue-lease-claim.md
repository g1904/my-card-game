# ADR-0058 — 复核队列取条件 `UPDATE` 租约，不照抄合规域的持锁 `SKIP LOCKED`

- **状态：** Accepted
- **日期：** 2026-09-08
- **来源：** handoffs/2026-09-08-risk-ledger-storage-shapes.md · answer-logs/log-risk-ledger-storage-shapes.md

## 背景

合规域四条周期任务已定 `SELECT … FOR UPDATE SKIP LOCKED` 持锁到事务结束的领取语义（`ADR-0034`）。昵称人工复核队列 `nickname_review` 表面上是同一类「取一批待办来处置」，直觉上应照抄。但两者的持有时长差三个数量级。

## 决策

复核条目的领取**不持锁到事务结束**，改为**条件 `UPDATE` 取租约**：

- `SKIP LOCKED` **只用在选行的那一条语句**里，事务在语句返回即提交；
- 领取写一次条件 `UPDATE` 置 `state = 'Claimed'` · `claimed_by` · `claim_expires_at_utc`，**租约超时初值 30 分钟**；
- 判定提交同样是条件 `UPDATE`（`WHERE claimed_by = :reviewer`），租约过期后原复核员的迟到提交**命中 0 行而被拒**；
- 租约超时由周期任务置回 `Pending` 并 `claim_attempts += 1`；`claim_attempts` 反复升高只出一条指标，**不自动升级**。

仍是零分布式锁、零调度中间件。形态与伪码见 `operations/moderation.md`「`nickname_review`：不分区，状态机 + 租约」。

## 理由

- 合规域那四条的成立前提是「处置在**毫秒到秒级**完成」。复核是**人工**动作、持有时长以分钟计：把数据库事务开着等人点按钮会长期占住连接、把最长事务时长指标打成常态告警、并阻塞 autovacuum。
- 条件 `UPDATE` 把「谁有权提交」落成一次行级判定而非一把锁，因此**租约到期后的迟到提交不会覆盖已被他人处置的条目**——这是持锁形态靠事务隔离拿到的同一条保证，用受影响行数分支兑现（与 `contracts/profile-sync.md` 的 CAS、`ADR-0032` 的 ticket 一次性消费同一手法）。
- **30 分钟**的取值判据：一次昵称复核是秒级判断，30 分钟覆盖一次中途被打断的班次；上界的代价只是条目滞留，下界的代价是复核员正在看的条目被他人抢走。

## 备选方案

- **照抄合规域的 `FOR UPDATE SKIP LOCKED` 持锁到事务结束** — 人工持有时长以分钟计，会占住连接、打成常态告警、阻塞 autovacuum。
- **引入分布式锁 / 调度中间件承载领取** — 与「明确不引入」四条相抵，且本形态零新增组件即可满足。

## 后果

- `operations/moderation.md` 落领取伪码、租约回收周期任务与两条对偶指标（待办积压量 · 最老 `Pending` 条目年龄）；`operations/environments.md` 的旋钮清单与定时任务出口各补行。
- 服务端保证 M7（租约超时后提交命中 0 行、判定被拒、条目不被覆盖）与 M8（同一账号在办条目恒为 1 条）成为可断言的验收行——后者由入队去重不变式 `UNIQUE (account_id) WHERE state IN ('Pending','Claimed')` 兑现（`ADR-0056`）。
- `claimed_by` 的取值域仍未定——本库尚无「内部人员身份」的概念，该问题登记在 `open-questions/07-internal-tools.md`。本决策**不依赖**它成立：租约机制对取值域是中立的。
- 客户端零影响。
