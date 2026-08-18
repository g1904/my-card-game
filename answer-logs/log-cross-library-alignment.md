# Answer log cross-library-alignment

- 日期：2026-08-16
- 来源：`inbox/solution-draft-cross-library-alignment.md` → `handoffs/2026-08-16-purchase-contract-and-cross-boundary-ledger.md`
- 移出条数：2

**购买段的新边界尚无契约承载（承重 · 08-16b 采集于 `01-contracts.md`）** → **购买域单开第五份契约 `contracts/purchase.md`**：两个端点（`POST /v1/purchase/verify` + `GET /v1/purchase/receipt/{receiptId}`）· 验票由后端向平台校验 · **写入只由 verify 承担，渠道回调降为对账 / 补偿通道** · 平台收据 id 作幂等键（重复提交绝不重复 `+1`）· `bundleGrantOrdinal` 与 `revision` 同事务自增 · verify 不走 CAS 且应答不内联 profile · 复算回链 §6 不新开随机源 · 四条栈中立的服务端保证。**不塞进 `profile-sync.md`** 的判据：一个域的承重纪律若与既有契约相反（权威写入 vs 只读、必须裁决 vs 不裁决、必须能拒绝 vs 不拒绝），就必须独立成文。
（归档去向：`contracts/purchase.md`、`contracts/_index.md`、`README.md`。）

**`bundleGrantOrdinal` 的透明路径未定** → **`/entitlement/bundleGrantOrdinal`**（客户端落点 `PlayerEntitlement.BundleGrantOrdinal` 于 08-15b 定案），按同形态补入 `profile-sync.md` §5 白名单原先预留的那一行，并同批与客户端确认。
（归档去向：`contracts/profile-sync.md` §5。）

> **连带的一次纪律松动（用户已裁决，非本次新问题）：** §2 §5 的「后端对透明段只读，唯一写入是 `accountSeed`」改写为**封闭两行表** + 「本表封闭，新增后端写入字段是破坏性契约变更、须两侧同批评审」的护栏。被接受的代价如实记在 `profile-sync.md` §5 的引述块内：那句话原本的价值在于「后端只读」无例外，开口后每一条「能不能让后端也写这个」都会引用它作先例。
