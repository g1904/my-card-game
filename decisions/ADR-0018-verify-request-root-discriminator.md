# ADR-0018 — 验票请求的判别式发生在请求根，`receipt` 逐渠道成形

- **状态：** Accepted
- **日期：** 2026-09-03
- **来源：** `handoffs/2026-09-03-purchase-channel-integration.md` · `answer-logs/log-purchase-channel-integration.md`

## 背景

`POST /v1/purchase/verify` 要同时承接三条渠道（Google Play Billing · App Store StoreKit · 微信支付），而三家的收据**结构不同**：一家给 token + SKU，一家给 JWS 串，一家根本没有「平台发给客户端的收据」、只有我方分配的商户订单号。一个端点、三种请求体，必须先定「读者与校验器凭什么知道这份报文属于哪一支」。

## 决策

**`VerifyRequest` 定义为以 `platform` 为判别式的三分支联合，判别式发生在请求根、不在 `receipt` 内部；`receipt` 是该渠道的具体对象，逐渠道成形。**

- spec 层即 JSON Schema `oneOf` + `discriminator: { propertyName: "platform" }`；每个分支内 `platform` 为 const，`receipt` 为该分支的具体对象。
- **`receipt` 绝不定义为不透明字符串**（base64 / 原样 JSON 串）。
- 必填性因此可被 schema 层校验，缺字段 / 类型不符 → `purchase.payload_invalid`。
- 新增第四条渠道 = 新增一个 `oneOf` 分支 + 一个枚举值，对既有客户端是纯追加 ⇒ `openapi.yaml` 的 `info.version` bump minor，`/v1/` 不动。
- 三张逐渠道字段表、贯穿它们的「客户端提交的一切只作索引、不作判据」纪律，以及 `receiptId` 的取值形态 → `contracts/purchase.md` §3 §3a。

## 理由

`platform` 是 `receipt` 的兄弟字段，而 `discriminator` 要求判别属性出现在每个子 schema 内——**把 `platform` 复制进 `receipt` 会造出同一事实的两个落点，两者不等时报文层无从裁决哪个为准**。判别提到根则一处判别、一处校验，`receipt` 保持纯净（`contracts/purchase.md` §3）。

不透明字符串则是另一个方向的失败：三渠道的必填性会全部退化为运行时判断，**`envelope.md` §1「字段形态由 spec 单点承载」对本域就等于没写**。

## 备选方案

- **把 `platform` 复制进 `receipt` 内部以便就地判别** — 同一事实两个落点，两者不等时报文层无从裁决。
- **把 `receipt` 定义为不透明字符串**（base64 / 原样 JSON 串） — 三渠道的必填性全部退化为运行时判断，「形态由 spec 单点承载」名存实亡。
- **三个渠道各开一个 verify 端点** — 写入路径、事务语义与七条服务端保证三倍复制，而它们对渠道无差别。

## 后果

- `contracts/purchase.md` §3 的请求体、§3a 的三张逐渠道字段表与三张渠道情形 → `code` 映射表必须按分支组织；三家的收据字段各自封闭，不合并成一张通表。
- 接入第四条渠道是**纯追加**：加分支 + 加枚举值，不动 `/v1/`，不改既有分支。`platform` 取值域仍封闭为三条渠道——**不实现 ≠ 从契约删除**。
- `purchase.payload_invalid` 因此是一条 schema 层可判定的码，而非运行时语义码 → `contracts/envelope.md` §6 台账。
- 本 ADR 只定**请求体形状**；写入权威分配属 `ADR-0007`，下单端点属 `ADR-0019`，两者均不因本条改变。
- 客户端侧的收据取值与提交形态权威在 `game-design-documents/systems/monetization.md`，本库不复述。
