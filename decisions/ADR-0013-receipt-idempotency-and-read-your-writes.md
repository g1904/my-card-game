# ADR-0013 — `receiptId` 全局唯一 · 永久保留，且写入后的读路径必须读己所写

- **状态：** Accepted
- **日期：** 2026-08-22
- **来源：** `handoffs/2026-08-22-entitlement-echo-and-receipt-idempotency.md`

## 背景

`pushId` 的幂等窗口（条数 + 天数）由客户端待发队列的存活上界推出。`receiptId` 的存活上界**完全不同轴**：待兑现态跨启动持久化、**无硬超时、永不放弃**，玩家可卸载数月后重装再登录，而平台退款 / 客诉窗口以月计。沿用同一组旋钮会让两件不同的事共用一个数字。

另一侧的缺口是读路径：verify 已经写入，客户端随即 pull，若读到的是滞后副本，它无法区分「副本滞后」与「verify 未成功」——而这两种情况的正确处置相反。

## 决策

**以 `receiptId` 作全局唯一幂等键，永久保留；并把「读己所写」升格为服务端的读路径一致性要求。**

- 幂等键**不带 `accountId` 前缀**——跨账号可查重，因为「已被其他账号核销」是 `contracts/purchase.md` §3 的既定失败面。
- 幂等记录**永久保留、不设 TTL**；形态为 `receiptId → { accountId, bundleGrantOrdinal, revision, verifiedAtUtc, status }`，`status ∈ { unknown, verified, rejected }`。
- 该记录与 `bundleGrantOrdinal += 1`、`cloudRevision += 1` **写在同一次事务内**。
- 同一 `receiptId` 在**任意时间跨度**（含远超 `pushId` 窗口）重复提交，仍回 `deduplicated = true`，序号与 `revision` **逐位相同**。
- **读己所写：** verify 应答返回后，同账号后续的 `GET /v1/profile/pull` 与 `GET /v1/purchase/receipt/{receiptId}` 必须**不早于**该次写入的结果。

旋钮表、服务端保证与只读副本约束 → `contracts/purchase.md` §4 §6 §7、`contracts/profile-sync.md` §8 §9。

## 理由

过期代价**不对称**（`contracts/purchase.md` §7 推导列）：`pushId` 过期只降级为一次进度丢失（既定语义已接受）；`receiptId` 过期是**重复 `+1`**——第二次提交查不到记录即当作新票，玩家白得一份，且这是发放侧漏洞、线上不可发现。而记录体量与购买次数同阶（每账号个位数 / 年），永久保留的成本可忽略。

「超过该期限的重复提交不可能发生」这一论证在待兑现态无自动放弃的前提下**做不实**。

读己所写必须是**服务端保证**而非客户端轮询纪律：客户端拿不到区分滞后与失败的信息，把它换成客户端纪律等于把一个可验收的断言换成一句无法验证的约定。

## 备选方案

- **`receiptId` 沿用 `pushId` 的幂等窗口旋钮** — 两者存活上界不同轴，过期后果不是同一量级。
- **论证「超过期限的重复提交不可能发生」以保留 TTL** — 在待兑现态永不放弃的前提下不成立。
- **把读己所写留作客户端轮询纪律** — 客户端无法区分副本滞后与 verify 未成功。
- **后端主动推送新序号** — 新增通道与平台推送依赖；强制一次 pull 已解决同一问题。
- **后端在 `grant > redeemed` 超时后自动补发** — 等于后端具备发放权，与「兑现段客户端演算、后端只复算」正面相悖。

## 后果

- 放弃**存储成本的可回收性**（幂等表只增不减）；存储选型、分区与冷存归档归 `open-questions/06-platform-stack.md` 与 `operations/`，**不回头改契约**。
- 读己所写**排除了纯只读副本的读路径**，需会话粘滞或 `revision` 下界等待——这是本库唯一一条对部署拓扑的读路径约束，必须带进栈选型（`open-questions/06-platform-stack.md`）。
- `contracts/profile-sync.md` §9 必须保留「`receiptId` 的幂等窗口与本节不同轴、不沿用旋钮」那一句，§8 必须写下「滞后只读副本不能无条件承接 pull」。
- 兑现水位 `/entitlement/bundleRedeemedOrdinal` 的不变式（`0 ≤ redeemed ≤ grant` 且单调不减）与「后端不据此做任何发放 / 补偿判断」作为本条的连带条款留在 `contracts/profile-sync.md` §5 与 `contracts/purchase.md` §6；它受回声校验约束那一面属 `ADR-0008`。
- 「购买写入只由 verify 端点承担、幂等键取 `receiptId` 且不由客户端生成」的**权威分配**属 `ADR-0007`，本 ADR 只定键作用域、保留期与读一致性。
- 对账信号「`grant > redeemed` 持续 N 天」归 `operations/`。
- 客户端侧对位（待兑现态跨启动持久化 `receiptId`、购后强制一次 pull、阻塞在主菜单重试）权威在 `game-design-documents/systems/monetization.md` 与 `game-design-documents/decisions/ADR-0023-premium-entitlement-and-redemption.md`。
