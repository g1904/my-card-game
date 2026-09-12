# ADR-0065 — 验票应答按 `kind` 分形，请求侧一格不加

- **状态：** Accepted
- **日期：** 2026-09-11
- **来源：** handoffs/2026-09-12-premium-character-series-unlock.md

## 背景

第二类 SKU（角色系列解锁）进入 verify 之后，报文层要回答两件事：**客户端要不要在请求里说明自己买的是哪个系列**，以及 **`bundleGrantOrdinal` 这个只对礼包有意义的字段在系列购买时回什么**。前者关系到「客户端自述能否成为判据」，后者关系到同一个字段会不会在两类 SKU 下语义不同。两者都发生在已有三渠道判别式（`ADR-0018`）的请求根上，形态必须与之同构，否则同一份报文里出现两种判别风格。

## 决策

**请求侧一格不加。** `seriesId` 不进 `VerifyRequest` —— 类别与 `seriesId` 一律由后端从 `productId` 机械解析（`ADR-0064`），而 `productId` 本就在 `receipt` 分支内。

**应答按 `kind` 分形**：新增判别式字段 `kind ∈ { PremiumBundle, CharacterSeries }`（后端权威回显该 `productId` 的类别），`bundleGrantOrdinal` 降为**仅 `kind == PremiumBundle` 时存在**；`revision` / `deduplicated` 两类同有。spec 层取 `oneOf` + `discriminator: { propertyName: "kind" }`，与请求根判别式同构（`ADR-0018`）。`GET /v1/purchase/receipt/{receiptId}` 的 `Verified` 应答**同款分形、同一条判别式**；`Rejected` 的取值域一字不变。

**系列解锁的应答不回 `seriesId`**；解锁的正确性由购后 pull 读到的 `/entitlement/characterSeries` 承载。

**新增一类 SKU = 新增一个应答分支 + 一个枚举值**，对既有客户端是纯追加 ⇒ `openapi.yaml` 的 `info.version` bump minor，`/v1/` 不动 —— 与新增渠道的处置逐字同构。

→ `contracts/purchase.md` §3 · §4

## 理由

- **`seriesId` 是客户端自述**，收下它正面违反本域「客户端提交的一切只作索引、不作判据」（`purchase.md` §3a），而那条纪律正是 §2「不信客户端自述」在字段层的兑现。
- **`bundleGrantOrdinal` 的存在意义是「兑现段掷骰的 `ordinal`」，而系列解锁没有兑现段** —— 无条件回一个对本类别无意义的序号，会让同一字段在两类 SKU 下语义不同（「`+1` 后的新序号」vs「当前值」），正是本契约反复分列所要避免的歧义。
- **分形而非分端点**：验票逻辑（渠道校验、幂等、事务、读己所写）逐字相同，分端点即写两遍，且端点全集表、两条机检断言与 `receiptId` 幂等窗口全要分叉。
- **`Verified` 应答的条件化不是破坏性变更，但依赖一个必须写明的前提**：老客户端不可能持有系列 SKU 的 `receiptId`（它买不到这类 SKU）⇒ 它查到的收据恒为 `PremiumBundle`，该分支字段集一字不变。前提已如实写进 `purchase.md` §4 正文，作为分形成立的条件。

## 备选方案

- **请求里带 `seriesId`** — 客户端自述，违反「只作索引、不作判据」。
- **应答复用 `bundleGrantOrdinal`，系列购买时回「云端当前值」** — 同一字段两类语义。
- **新开端点 `POST /v1/purchase/verify-series`** — 验票逻辑逐字相同，分端点即写两遍；端点全集表、机检断言与幂等窗口全要分叉。
- **应答内联 `seriesId`** — 客户端知道自己点的是哪个 SKU；与「应答只回序号 + revision，不内联新 profile」同一条取向。

## 后果

- `contracts/purchase.md` §3 的应答字段表须逐字标注 `bundleGrantOrdinal` 的条件存在性，§4 须写明分形成立的前提（老客户端不可能持有系列 SKU 收据）。
- `openapi.yaml` 落笔时 verify 与 `GET receipt` 两处应答均取 `oneOf` + `discriminator`，`info.version` bump minor、URL 主版本不动。
- `contracts/envelope.md` §3 端点全集表**零加行**（不新开端点）、§6 台账**零加行**（不新增 `code`）。
- 跨边界后果：客户端的 verify / `GET receipt` 应答 record 须随本次分形同批调整 → `game-design-documents/handoffs/2026-09-12-premium-character-series-unlock.md`。
- 若日后出现任何能让不认识 `kind` 的客户端拿到系列 SKU 收据的路径，条件化对它表现为字段缺失，届时须重新评估而非沿用本结论。
