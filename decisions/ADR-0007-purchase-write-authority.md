# ADR-0007 — 购买写入只由 verify 端点承担，渠道回调降为对账通道

- **状态：** Accepted
- **日期：** 2026-08-16
- **来源：** `handoffs/2026-08-16-purchase-contract-and-cross-boundary-ledger.md` · `answer-logs/log-cross-library-alignment.md`

## 背景

付费权益的推进（`bundleGrantOrdinal += 1`）必须在后端，否则防篡改归零。但「后端」有两条可能的入口：客户端触发的验票端点，与平台 / 渠道的服务器回调。两条都写库看起来更保险，实则要处理它们之间的竞态。

## 决策

**权益推进只由 `POST /v1/purchase/verify` 写入；平台 / 渠道回调只作对账与补偿发现，不作写入路径。**

同批固化的连带条款：

- **幂等键不由客户端生成**；两家商店渠道取平台发放的 id，微信渠道取后端在下单时分配的商户订单号。同一 `receiptId` 重复提交**绝不重复 `+1`**，直接回上次结果（`deduplicated = true`）。
- `bundleGrantOrdinal += 1` 与 `cloudRevision += 1` **必须同一次事务**。
- **verify 不接受 `baseRevision`、不做 CAS 判定**；应答只回序号 + `revision`，**不内联新 profile**（客户端另走一次 pull）。
- `GET /v1/purchase/receipt/{receiptId}` 是**承重的补查通道**，不是可选便利。
- 报文、四条服务端保证与失败面 → `contracts/purchase.md` §2–§6。

## 理由

回调时序**不可控**：它可能早于、晚于、或永不到达客户端的 verify。把它作为写入路径会让「玩家已付款但序号未涨」无处排查，且要额外处理回调与 verify 的竞态——而那条竞态的收益仅在「客户端崩溃且从不回来」这一个场景，那个场景由回调侧的**对账与补偿任务**兜住即可，不需要它具备写入权。→ `contracts/purchase.md` §2。

本域的承重纪律与 `profile-sync` 恰好相反（后端权威写入 · 必须裁决 · 必须能拒绝），这也是它单独成文的第一理由。

## 备选方案

- **平台回调直接写库、不设 verify 端点** — 回调时序不可控，「已付款未涨序号」无处排查。
- **回调与 verify 双写入路径** — 引入一条只在罕见场景有收益的竞态，而它的错误形态直接是玩家的钱与权益不一致。
- **让客户端携带 `baseRevision` 走 CAS 提交购买** — 等于承认客户端有权参与决定序号；且客户端此刻的 `baseRevision` 必然落后，只会失败。
- **验票由客户端做、后端事后复算** — 客户端置位 = 客户端有权发货；事后发现不一致时玩家已拿到东西，回收比不发更糟。
- **verify 应答内联新 profile** — 省一个 RTT，却把 profile 的下行形态复制进购买域，两处形态从此要同步演进。

## 后果

- `/entitlement/bundleGrantOrdinal` 因此进入 `contracts/profile-sync.md` §5 的**后端写入字段表（封闭）**，写入时机写死为「每次验票通过时 `+1`」；该表新增行是破坏性契约变更，须两侧同批评审。
- **verify 不返回 `compliance.*`**：被合规拦住的账号拿不到 access token，根本走不到 verify；在此硬拒会让玩家已付款却拿不到发放。
- 回调记账与补偿任务（「已付款但从未 verify」的兜底发现）落 `operations/`，待 `06-platform-stack.md`。
- `receipt` 字段的逐渠道内部形态与平台错误码归一见 `contracts/purchase.md` §3a §3b（支付渠道与 `auth.md` 的登录渠道**不同轴**）；它不影响本 ADR 的四条服务端保证。
- 客户端侧对位（购后强制一次 pull、待兑现态持久化 `receiptId`、阻塞在主菜单重试）权威在 `game-design-documents/systems/monetization.md`。
