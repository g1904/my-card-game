# `bundleGrantOrdinal` 施加权的后端承接：回声校验 · 水位路径登记 · 读己所写 · 收据幂等窗口

- id: 2026-08-22-entitlement-echo-and-receipt-idempotency
- date: 2026-08-22
- topic: contracts/profile-sync（§4 拒绝面 · §5 白名单 + 回声校验通则 · §7a 判据边界 · §8 读路径约束 · §9 旁注）· contracts/purchase（§3 渠道取值域 · §4 · §5 判据 · §6 服务端保证 · 新增 §7 收据幂等窗口）· open-questions/01 · 06 · cross-boundary
- status: distilled
- distilled-to: `contracts/profile-sync.md`、`contracts/purchase.md`、`open-questions/01-contracts.md`、`open-questions/06-platform-stack.md`、`open-questions/cross-boundary.md`、`open-questions.md`、`open-questions/update-log.md`

## Intent（distilled）

客户端定案「`bundleGrantOrdinal` 只能由后端 `+1`」并撤下客户端的施加路径（`game-design-documents/handoffs/2026-08-19-bundle-grant-ordinal-authority.md` · `decisions/ADR-0023`）。本库既有表述与该裁决**完全同向**，因此本次没有一句既有口径被改写——全部内容是**新增的护栏与登记**，兑现这条裁决在后端侧的四件承接。

### 1. 回声校验：后端写入字段表由此获得执行点（承重）

「后端唯一 `+1`」此前只挡住了「客户端主动 `+1`」，没有挡住**覆写**：`playerDiff` 是顶层键粒度的浅合并，`entitlement` 一旦出现即整键替换，键内由后端唯一写入的 `bundleGrantOrdinal` 随客户端提交的值一起落地。客户端提交旧值 ⇒ 云端序号**回退** ⇒ 同一 `ordinal` 被兑现两次、下一次验票再推一次，序列彻底错位。

客户端新增的兑现水位 `bundleRedeemedOrdinal` 与它同处 `entitlement` 键，使这个窗口从「理论可能」变成**每次兑现都会走一遍**的常规路径。

`revision` CAS 挡不住它：CAS 问「你的基线对不对」，不问「你有没有权改这个字段」——客户端一个 bug（把序号写成常量 0）在基线正确时会被原样接受。

**规则：** 凡 `playerDiff` 含某个受约束顶层键，键内属后端写入字段表的路径，客户端提交的值**只能是回声**（与当前云端值相等）；不等即**整批拒绝**，复用 `sync.conflict`，`detail.field` 给该 JSON path，并打一条风控事件。**后端永不采纳客户端对这些路径的写入，也不静默丢弃**（静默丢弃会让客户端 bug 永远看不见）。

- **拒绝整批而非字段级挑拣**：挑拣要求后端在顶层键内部做字段级合并，会打开「不递归、不逐元素合并」这条分段。拒绝是唯一不动摇既有分段的处置。
- **复用 `sync.conflict` 而非新增码**：客户端处置与 Conflict 逐字相同（以云端为准、丢弃缓冲、重新 pull），新码只逼客户端多写一条走向同一处的分支。可观测性由风控事件承担。
- **与「复算不一致仅记账不拒绝」不冲突**：判据是**所有权**不是严格程度。复算管的是客户端有权写、值可能有争议的路径（误报 = 一次错误的进度丢失）；回声管的是客户端根本无权写的路径（正常客户端永远只提交回声，零误报）。

### 2. 兑现水位路径 `/entitlement/bundleRedeemedOrdinal` 的登记

- 进 §5 **透明字段白名单**：`number int`，**后端只读**，不变式 `0 ≤ bundleRedeemedOrdinal ≤ bundleGrantOrdinal` 且单调不减。
- **后端写入封闭表不动**：该字段的真值产生在客户端（兑现事务的一部分），「够格进表」第 ① 条判据即不满足，与 `/accountInfo/nickname` 同型。护栏未被动用。
- **不变式违反 → 告警台账 + 风控事件，不拒绝上行**（走既有的「记账不拒绝」侧）：这个字段客户端有权写，越界只说明它算错了水位；拒绝会把一次客户端 bug 升级成一次进度丢失，而同一批里还带着玩家刚拿到的法则 / 古宝。**同一顶层键内两条路径走两种处置，判据是各自的所有权**——这一点必须明写，否则实现者会按键统一处置。
- **后端不据此做任何发放 / 补偿判断。**「`grant > redeemed` 持续超过 N 天」是有价值的运营信号，但落点是 `operations/` 的对账任务：自动补发等于后端具备发放权，与「兑现段客户端演算、后端只复算」正面相悖。

### 3. verify 之后的可读语义：读己所写（read-your-writes）

客户端拿新序号的**唯一**路径是 verify 应答后强制一次 pull。若该 pull 落到滞后的只读副本上，客户端读到旧序号 ⇒ 判定「无待兑现」⇒ **玩家付了钱、客户端认为没有货可发，且不会重试**（它已经不觉得自己欠什么）。这是整条链上唯一一个无人重试的失败点。

因此把既有的验收断言「verify 通过后立即 pull 读到一致」**升格为对读路径的一致性要求**：verify 应答返回之后，同一账号的任何后续 pull 与 `receipt/{receiptId}` 读，必须不早于该次写入的结果。它排除「读走可能滞后的只读副本」这一部署形态，或要求该形态附带会话粘滞 / 版本等待。

- 不指定实现（主库读 / 会话粘滞 / 携带 `revision` 下界等待），只写要求本身。
- **代价如实记下**：这是本库首次对读路径提实现约束，须在栈选型时带上。
- **不引入后端主动推送。** 强制 pull 已解决同一问题，推送要新增一条通道与平台推送依赖。

### 4. `receiptId` 幂等窗口：与 `pushId` 的 30 天 TTL 不同轴，永久保留

`pushId` 的 30 天由**客户端待发队列的存活上界**（refresh token TTL）推出；`receiptId` 的存活上界完全不同——客户端的待兑现态跨启动持久化、无硬超时、永不放弃，玩家可以卸载数月后重装再登录。且平台侧的退款 / 客诉窗口以月计，对账需按 `receiptId` 回查一次购买的全部历史。

| 旋钮 | 定值 | 推导 |
|---|---|---|
| 唯一键 | `receiptId` **全局唯一**，不带 `accountId` 前缀 | 「已被其他账号核销」是既定失败面，要求跨账号可查重；`pushId` 用 `(accountId, pushId)` 是因为它由客户端生成、只在账号内有意义 |
| 保留时长 | **永久**（不设 TTL） | 过期代价不对称：`pushId` 过期只降级为一次进度丢失（已被既定语义接受），`receiptId` 过期是**重复 `+1`**（玩家白得一份，且发放侧不可发现）。记录体量与购买次数同阶（每账号个位数 / 年） |
| 存储形态 | `receiptId → { accountId, bundleGrantOrdinal, revision, verifiedAtUtc, status }` | 与序号 / `cloudRevision` 的写入**同一次事务**——分开写会出现「revision 已 `+1` 但幂等记录未落」 |

存储选型、分区与冷存归档归 `operations/`，**不回头改契约**；本条只定语义。

### 5. 相邻定案的连带：平台内购三渠道纳入 MVP

支付渠道选型已定为 **Google Play Billing · App Store（StoreKit）· 微信支付**三条，纳入 MVP（客户端权威：`game-design-documents/vision/scope.md` · `systems/monetization.md`）。连带：

- `purchase.md` 的 `receipt.platform` 取值域由开放收敛为**三条具名渠道**（枚举成员名与客户端 C# 成员名逐字相同，两侧同批冻结）。
- `06-platform-stack.md` 的支付渠道选型由「不阻塞、可推后」变为**MVP 范围内必须答结**：三家的收据 / 凭证结构与校验协议互不相同，后端须逐渠道定验票端点形态。
- **对验票权威、原子性、幂等窗口与回声校验的实质影响为零**——它们对渠道无差别。

## Clarifications（用户裁决 · 2026-08-19 三项全部定案，2026-08-22 提炼时无新增追问）

- **是否新增回声校验这条拒绝条件** → **新增**，整批拒绝 + 风控事件。判据：所有权类越界与复算不一致不同轴；「只靠 CAS」的失败模式无声且不可逆，「只记账不拒绝」观测到时损害已成。后端写入字段封闭表由此首次获得执行点。
- **是否把读己所写升格为服务端一致性要求** → **升格**，并接受「排除滞后只读副本」这一栈约束。一条一致性要求比一条客户端轮询纪律便宜且可验收，且客户端无法区分「副本滞后」与「verify 未成功」。
- **`receiptId` 幂等记录的保留期** → **永久，不设 TTL**。过期代价不对称（错误发放 vs 一次进度丢失），且「超过该期限的重复提交不可能发生」这一论证在待兑现态无自动放弃的前提下做不实。
- **提炼时的两处落笔判断（无设计自由度，未回头追问）**：① 收据幂等窗口的本体写进 `purchase.md`（购买域）而非 `profile-sync.md` §9 旁，后者只留一句「不同轴」的指路——两处都是草稿给出的备选落点，选购买域使 `pushId` 与 `receiptId` 各在自己的域内定义；② §4 拒绝面登记**不写「由两类变三类」这个计数**——现有拒绝面实为版本闸门 / 信封形状 / CAS 三类，加上所有权类为四类，故按类逐行列出而不作计数断言。

## Open questions

- **回声校验的适用面与比较口径**：`/accountInfo` 是「客户端整键替换覆写后端写入字段」的第二处同形（键内含后端写的 `accountSeed` / `createdAtUtc` / `identities` 与客户端写的 `nickname`），需逐条登记哪些路径受约束，并定下非整数路径的比较口径（时间串按时刻还是按字面、数组按序还是按集合）。选错会让**正常客户端**被整批拒绝 = 丢玩家进度。→ 已登记进 `open-questions/01-contracts.md`；`inbox/solution-draft-echo-validation-scope.md`（已裁决，待提炼）承接它。
- **风控事件的落地形态**（字段、累计频次的处置阈值）—— 沿用既有归属：`02` / `06`，落 `operations/`。
- **幂等记录的存储与归档、对账信号「`grant > redeemed` 持续 N 天」的落点** —— 归 `06`，落 `operations/`，不回头改契约。
- **三渠道各自的 `receipt` 内部形态与平台错误码映射** —— 随支付渠道逐家接入落笔，归 `06`。

## Notes / triage

来源：`inbox/solution-draft-bundle-grant-ordinal-authority.md`（`status: decided`，2026-08-19 三项裁决），已归档进 `inbox/archive/`。
对侧那一半（客户端）已于 2026-08-19 单独落笔，见「客户端侧影响」——**成对采纳的硬要求由此满足**。
本次移出待答条目 0 条（本库分片与 `cross-boundary.md` 此前均无对应条目），故不建 answer log。

## 客户端侧影响

本 handoff **不新增**对客户端的义务：它承接的是客户端已定案的一半，客户端侧（`PlayerEntitlement` 第二字段 · 撤下 `BundleGrantOrdinal` 的施加路径 · 逐一循环追平的兑现 · 购买入口第四条前置条件）已由 `game-design-documents/handoffs/2026-08-19-bundle-grant-ordinal-authority.md` 落笔，权威在 `game-design-documents/systems/monetization.md` 与 `decisions/ADR-0023-premium-entitlement-and-redemption.md`。受影响的客户端成分是 `sync-service`（上行 diff 的组装）与购买段的 `account-service` 无关面。

**唯一一条新的两侧刚性**在回声校验上：客户端提交受约束顶层键时必须原样回声后端写入路径的值。其客户端侧形态（回声值取自哪里、push 前自检、老档补默认值的例外）待 `inbox/solution-draft-echo-validation-scope.md` 与其对侧同批落笔。
