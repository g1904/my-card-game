---
type: solution-draft
date: 2026-09-02
question: 三条支付渠道（Google Play Billing · App Store · 微信支付）各自的 `receipt` 内部形态与平台错误码映射，以及 `receiptId` 幂等记录的存储 / 分区 / 冷存归档与对账信号落点
source: open-questions/06-platform-stack.md → 「平台内购三渠道的接入形态」+「`receiptId` 幂等记录的存储与冷存归档」
targets: contracts/purchase.md（§1 端点集 · §3 字段表与失败面 · §7 存储注解）· contracts/envelope.md §6（新增 4 行台账）· operations/（新建 `purchase-ops.md`）· open-questions/06-platform-stack.md（两条可部分移出）
status: distilled
reviewed: 2026-09-02（用户批量评审：草稿内取向与张力逐条裁决）；2026-09-03（/batch-analyze-new-ideas 合并 interview 十项裁决，见 handoff 的 Clarifications）
distilled-to: handoffs/2026-09-03-purchase-channel-integration.md
---

# 方案草稿 — 三渠道验票接入面 · 收据幂等记录的实现形态

## 问题

`contracts/purchase.md` 的报文骨架、权威分配、幂等语义与七条服务端保证都已封定，但两处仍是空的：

1. **`receipt` 字段的内部形态**（§3 只写「形态逐渠道不同，随各渠道接入落笔」）与 **verify 失败面的具体 `code`**（§3 失败面只写了三类情形，`code` 标注「待落笔」）。这两样缺席使 `purchase.md` 连续四次未能兑现「本次落笔」的预告，也使后端 FR 强制要求的 `## Failure & retry semantics` 无从写起——它不可切、不可留空。
2. **`receiptId` 幂等记录的实现**：语义已定且不回头改契约（全局唯一键 · 永久保留不设 TTL · 与序号 / `cloudRevision` 同一次事务，§7 + `ADR-0013`），但存储选型、分区策略、体量增长、冷存归档形态，以及它与 `(accountId, pushId)` 记录能否同处，全部悬着。另有对账信号「`bundleGrantOrdinal > bundleRedeemedOrdinal` 持续 N 天」的落点与阈值。

本草稿只推演这两项。渠道**本身**已定（三家，`platform` 取值域封闭），不重开选型。

## 约束（来自既有设计）

- **验票必须由后端向平台服务器校验，不信客户端自述；写入只由 verify 承担，渠道回调只作对账** —— `purchase.md` §2 · `ADR-0007`。
- **`bundleGrantOrdinal` 严格单调递增、不清零；与 `cloudRevision` 同一次事务；同一 `receiptId` 任意时间跨度重复提交回 `deduplicated = true`** —— `purchase.md` §6 保证 1 / 2 / 4 / 6 · `ADR-0013`。
- **读己所写是对读路径的一致性要求**，排除滞后只读副本无条件承接读 —— `purchase.md` §6 保证 3 · `profile-sync.md` §8。
- **`receiptId` 全局唯一、不带 `accountId` 前缀、永久保留** —— `purchase.md` §7 · `ADR-0013`。
- **平台不可达须与「收据无效」在报文层面可区分** —— `purchase.md` §3 失败面。
- **渠道原始错误码只随日志上报、客户端不解析；渠道错误分「明确拒绝」与「服务不可达」两类映射** —— `auth.md` §3a（登录渠道的同形先例，理由同源）。
- **客户端永不接触渠道 secret** —— `auth.md` §3a 义务 1；本域逐字同构。
- **错误体形状、`class` 四值、`code` 永不复用、新增 `code` 一律登记 §6 台账** —— `envelope.md` §5 §6；台账变更流程「先文档 → 后 spec → 后实现」见 `operations/_index.md`。
- **契约停在语义层，不指定语言 / 框架 / 存储实现**（技术栈未定）—— `purchase.md` 卷首 · `profile-sync.md` §8。
- **`verify` 不返回 `compliance.*`** —— `purchase.md` §3；本草稿的失败面不重开这一条。
- 客户端侧硬前提（**不复述，回链**）：购后强制一次 pull、待兑现态跨启动持久化 `receiptId`、阻塞在主菜单重试、**无硬超时永不放弃**、可重复购买 —— `game-design-documents/systems/monetization.md` · `game-design-documents/decisions/ADR-0023-premium-entitlement-and-redemption.md`。

---

## 建议方案

### A. `receipt` 的共存形态：判别式发生在**请求根**，不在 `receipt` 内部

`[既有推演]` + `[通行做法]`

三张字段表要在同一个 `receipt` 字段名下共存，建议把 `POST /v1/purchase/verify` 的**请求体整体**定义为一个三分支的判别式联合（JSON Schema `oneOf` + `discriminator: { propertyName: "platform" }`），每个分支内 `platform` 为 const、`receipt` 为该渠道的具体对象：

```
VerifyRequest = oneOf[
  { platform: "GooglePlay", receiptId, receipt: GooglePlayReceipt },
  { platform: "AppStore",   receiptId, receipt: AppStoreReceipt   },
  { platform: "WeChatPay",  receiptId, receipt: WeChatPayReceipt  }
]
```

- **为什么判别在根而不在 `receipt` 内：** `platform` 是 `receipt` 的**兄弟字段**（§3 字段表已定），而 OpenAPI 的 `discriminator` 要求判别属性出现在被判别的每个子 schema 内。把 `platform` 复制进 `receipt` 会造出同一事实的两个落点（两份可能不等的 `platform`，且报文层无从裁决哪个为准）；把判别提到请求根则一处判别、一处校验，`receipt` 保持纯净。
- **必填性因此可被 schema 层校验**：缺字段 / 类型不符 → `purchase.payload_invalid`（下方 C）。`envelope.md` §2 的「忽略未知字段」仍适用于 `receipt` 内部——它管的是**多余**字段，与必填校验不同轴，两者不冲突。
- **新增第四条渠道 = 新增一个 `oneOf` 分支 + 一个枚举值**，对既有客户端是纯追加（老客户端从不发送新值）⇒ `openapi.yaml` 的 `info.version` bump **minor**，不动 `/v1/`。
- **明确否决把 `receipt` 定义为不透明字符串**（base64 / 原样 JSON 串）：省一次 schema 编写，代价是三渠道的必填性全部退化为运行时判断，且 spec 单点（`envelope.md` §1）在本域名存实亡——「字段形态由 spec 单点承载」这条对购买域就等于没写。

### B. 逐渠道的 `receipt` 字段表

`[通行做法]`（三家的收据 / 凭证结构与校验协议是渠道方公开协议）+ `[既有推演]`（取舍依据来自本库既定纪律）

> 贯穿三张表的一条纪律：**客户端提交的一切只作「去哪里查」的索引，不作判据。** 权威状态一律由后端向渠道服务器查询取得。这是 §2「不信客户端自述」在字段层的兑现，也解释了三张表为什么都这么窄。

**B1. `GooglePlay` —— `GooglePlayReceipt`**

| 字段 | 类型 | 必填 | 来源 |
|---|---|---|---|
| `purchaseToken` | string | ✅ | 客户端 `Purchase.getPurchaseToken()`；后端据此调 Play Developer API 取权威状态 |
| `productId` | string | ✅ | `Purchase.getProducts()[0]`；后端**与自己的 SKU 表比对**，不匹配即无效 |
| `orderId` | string | ➖ | `Purchase.getOrderId()`；测试 / 促销购买可能缺省。**仅进日志与工单**，不参与任何判定 |

- **不接收 `originalJson` / `signature`**（客户端本地签名校验的那一对）。收下它等于把客户端提交的 JSON 变成事实来源；服务端 API 校验本就更强，两条并存只会让「以哪条为准」再成一题。
- **`packageName` 不由客户端提交**，后端取自身配置——客户端提交的包名对防伪毫无贡献。
- **商品须配置为 consumable**（可重复购买是既定语义），且 **acknowledge / consume 只能发生在 `+1` 事务提交之后**：提前 consume 而事务失败 ⇒ 玩家付了钱、票被消掉、序号没涨，且再也查不回来。建议由**后端**在事务提交后调 consume（服务端有该 API），失败进补偿队列重试；客户端不承担该动作。

**B2. `AppStore` —— `AppStoreReceipt`**

| 字段 | 类型 | 必填 | 来源 |
|---|---|---|---|
| `signedTransaction` | string（JWS compact） | ✅ | StoreKit 2 `VerificationResult.jwsRepresentation` |
| `transactionId` | string | ➖ | 便于早期路由与日志。**后端只信 JWS 内解出的值**，两者不等即按无效处理并记风控 |

- 后端义务：验证 JWS 证书链至 Apple 根证书 → 校验 `bundleId` / `productId` / **`environment`** → 必要时以 App Store Server API 复核该 `transactionId` 的当前状态（是否已退款 / 撤销）。
- **`environment` 校验是承重项，不是可选加固**：Sandbox 交易在生产环境被接受 = 任何人可无限白嫖礼包。同理 B1 的测试购买（`purchaseType = Test`）在生产环境一律拒绝并记风控。
- **`finish()` 只能在 verify 成功（或 `deduplicated = true`）之后由客户端调用**——Apple 侧没有服务端 finish 接口，这一条只能落在客户端。本库不代为决定其形态，见「前置依赖」。

**B3. `WeChatPay` —— `WeChatPayReceipt`**

| 字段 | 类型 | 必填 | 来源 |
|---|---|---|---|
| `outTradeNo` | string | ✅ | **本库下单端点**（下方 D）下发的商户订单号 |

- 只有一个字段，是因为微信支付的形态与另两家**结构不同**：不存在「平台发给客户端的收据」，权威状态只能由商户后台以 `outTradeNo` 查单取得（`trade_state` / `transaction_id` / `amount`）。
- **客户端 SDK 返回的 `errCode` 不作任何判据**：它既可被伪造，也可能在支付成功后丢失（用户切走 App）。它至多作为 `channelCode` 随日志上报。
- **本渠道特有的必查项**：`appid` / `mchid` / `amount.total` 与 `outTradeNo` 的**账号归属**四项须逐一比对。另两家的收据自带应用绑定，微信的订单号由我方分配，绑定关系只能由我方自查——漏掉「归属」这一项即等于任何登录用户都能提交别人的订单号换一次发放。

**`receiptId` 的取值（三渠道统一形态）**

| 渠道 | `receiptId` | 说明 |
|---|---|---|
| `GooglePlay` | `gp_` + `purchaseToken` | 消耗型商品每次购买产生新 token，天然唯一 |
| `AppStore` | `as_` + JWS 内的 `transactionId` | **不取客户端提交的那个** |
| `WeChatPay` | `wx_` + `outTradeNo` | 由后端在下单时分配 |

- **加渠道前缀**，使「三家的 id 空间不相撞」成为可证的，而不是被假定的。前缀不是 `accountId` 前缀，与 §7「不带 `accountId` 前缀」不抵触。
- **字符集限制在 `[A-Za-z0-9._~-]`**，长度上界 **256**：它要作为 `GET /v1/purchase/receipt/{receiptId}` 的**路径段**，不可要求客户端做转义（客户端此刻正处在阻塞重试态，任何编码分歧都会表现为「补查永远 404」）。
- **`wx_` 的 id 由后端在下单时分配**，是对 §7「幂等键由平台发放、不由客户端生成」的一处**措辞细化**：承重的是「不由客户端生成」，而不是「必须由渠道方发放」。见「与既有决策的张力」。

### C. 平台错误码映射：归一到本库 `code`，新增四条

`[既有推演]`（映射分类与「不可达可重试」的判据完全沿用 `auth.md` §3a）+ `[通行做法]`（渠道侧情形取自各渠道公开协议）

**C1. 拟新增的四条 `code`（进 `envelope.md` §6 台账的那几行；本草稿不改该文件）**

| `code` | `class` | `OpError` | 客户端处置 | `detail` 形状 | `message` 必含 |
|---|---|---|---|---|---|
| `purchase.receipt_invalid` | `Fatal` | `Purchase`（待客户端确认，见前置依赖；退化映射 `Validation`） | Store 屏终态失败 + 客服入口；**解除待兑现态**（这张票永远不会通过） | `{ platform, channelCode? }`（`channelCode` 渠道原始码原样透传，**客户端不解析**） | 平台名 · 渠道原始码 · `receiptId` 前缀截断 · 判定失败的那一项（签名 / 环境 / SKU / 金额） |
| `purchase.receipt_claimed` | `Fatal` | 同上 | 呈现「该收据已在另一账号上核销」+ 客服入口；解除待兑现态 | `{ platform }` | `receiptId` 前缀截断 + 当前账号前缀。**绝不含另一账号的任何标识** |
| `purchase.receipt_pending` | `Retryable` | `Network` | **保持待兑现态**、退避重试（交易尚未终态，钱未确认扣） | `{ platform, channelState }`（`channelState` 渠道原始状态串，只作日志） | 渠道返回的状态值与查询时刻 |
| `purchase.payload_invalid` | `Fatal` | `Validation` | **bug 面，不是玩家面**——上报 | `{ field }` | 违规字段路径与期望形态 |

- **平台不可达一律复用 `server.unavailable`（`Retryable`），不新增码。** `auth.md` §3a 对登录渠道已经这么处理，且 §6 台账为它规定的 `message` 必含项就是「下游组件与失败阶段」——渠道名与查询阶段落在那里正合适。新造一个 `purchase.channel_unavailable` 只会让客户端的两条路径合并成同一条处置，却多一行映射表。
- **`purchase.receipt_pending` 必须与 `server.unavailable` 分列。** 二者 `class` 相同、客户端退避形态相同，但**含义相反**：一个是「我方查不到平台」，一个是「平台明确说这笔钱还没到位」。合并会让线上探针无法区分「我方故障」与「玩家用了慢速支付方式」，而这两条曲线的处置完全不同（一个叫人，一个不叫人）。
- **`purchase.receipt_invalid` 不细分原因。** 无效的十几种成因（签名坏 / 环境不符 / SKU 不认 / 金额不符 / 已关单 / 已退款）对**客户端处置逐字相同**，细分只会让处置表多十行走同一条路径——与 `envelope.md` §6「`restricted` 与 `banned` 共用一个 `code`、靠 `reasonKey` 分辨」同一条判据。成因进 `message` 与风控事件，不进 `code`。
- 四条 `code` 均须按 `operations/_index.md` 的流程落地：**先改 `envelope.md` §6 台账 → 同一次变更补进 `openapi.yaml` 错误码枚举 → 再改实现**。

**C2. 逐渠道原始失败情形 → 本库 `code`**

**Google Play**（`purchases.products.get` / `voidedpurchases.list`）

| 渠道侧情形 | `code` | 附加动作 |
|---|---|---|
| token 不存在 / 与 `productId` 不匹配 / `packageName` 不匹配 | `purchase.receipt_invalid` | — |
| `productId` 不在本作 SKU 表内 | `purchase.receipt_invalid` | 风控事件 |
| `purchaseState = Cancelled`，或命中 voided 列表 | `purchase.receipt_invalid` | — |
| `purchaseState = Pending`（慢速支付） | `purchase.receipt_pending` | — |
| `purchaseType = Test` 且部署环境为生产 | `purchase.receipt_invalid` | 风控事件（**高优**） |
| `consumptionState = 已消费` 且本库无该 `receiptId` 记录 | `purchase.receipt_invalid` | 风控事件（异常态：票被别处消掉了） |
| 该 `receiptId` 已存在、`accountId` 不同 | `purchase.receipt_claimed` | 风控事件 |
| 该 `receiptId` 已存在、`accountId` 相同 | **不是失败**：回 `deduplicated = true` | — |
| API 401 / 403（服务账号凭据失效 / 权限被撤） | `server.unavailable` | **P1 告警**——我方配置事故，不是玩家问题 |
| API 5xx / 超时 / 配额 429 | `server.unavailable` | 带 `Retry-After` |

**App Store**（JWS 校验 + App Store Server API）

| 渠道侧情形 | `code` | 附加动作 |
|---|---|---|
| JWS 签名 / 证书链校验失败 | `purchase.receipt_invalid` | 风控事件 |
| `bundleId` 不匹配 / `productId` 不在 SKU 表 | `purchase.receipt_invalid` | 风控事件 |
| `environment` 与部署环境不符（Sandbox ↔ Production） | `purchase.receipt_invalid` | 风控事件（**高优**） |
| Server API 报 `transactionId` 不存在 | `purchase.receipt_invalid` | — |
| 交易带 `revocationDate` / 已退款 | `purchase.receipt_invalid` | — |
| 同 `transactionId` 已被他账号核销 | `purchase.receipt_claimed` | 风控事件 |
| Server API 401（IAP key 失效 / JWT 过期） | `server.unavailable` | **P1 告警** |
| Server API 5xx / 超时 / 429 | `server.unavailable` | 带 `Retry-After` |

> 消耗型交易在 StoreKit 2 下**没有 pending 态**（家庭共享的延迟批准表现为交易根本不产生），故本渠道不产出 `purchase.receipt_pending`。这不影响 `code` 的定义——`code` 按语义定义，不按「每个渠道都得用上」定义。

**微信支付**（查单 `trade_state`）

| 渠道侧情形 | `code` | 附加动作 |
|---|---|---|
| `SUCCESS` **且** `appid` / `mchid` / `amount.total` / 订单归属四项全对 | **通过** | — |
| `SUCCESS` 但四项中任一不符 | `purchase.receipt_invalid` | 风控事件（**高优**） |
| `NOTPAY` / `USERPAYING` | `purchase.receipt_pending` | — |
| `CLOSED` / `REVOKED` / `PAYERROR` | `purchase.receipt_invalid` | — |
| `REFUND`（首次验票时已退款） | `purchase.receipt_invalid` | — |
| `outTradeNo` 属于另一账号 | `purchase.receipt_claimed` | 风控事件（本渠道下这必然是提交了他人订单号） |
| 网关 5xx / 超时 / 限频 | `server.unavailable` | 带 `Retry-After` |
| 商户证书 / APIv3 密钥失效、平台证书轮换未跟上 | `server.unavailable` | **P1 告警** |

**C3. 退款 / 撤单的对账通道（逐渠道）**

`[既有推演]`：`ADR-0007` 已定回调只作对账、不作写入路径；§6 保证 4 已定 `bundleGrantOrdinal` **严格单调不清零**。两条相加 ⇒ **退款一律不回收权益、不回退序号**，只在收据记录上打标并进工单。回收在结构上已被排除（兑现段产出的条目已写进玩家存档，回收比不发更糟——`ADR-0007` 已就同一判据裁过一次）。

| 渠道 | 对账通道 | 补漏手段 |
|---|---|---|
| Google Play | Real-time Developer Notifications（推送）+ voided purchases 列表 | 定期拉 voided 列表兜底，不依赖推送必达 |
| App Store | App Store Server Notifications V2（`REFUND` / `REVOKE` 等） | 通知历史接口回补漏收的通知 |
| 微信支付 | 退款结果通知 + 退款查询 | 定期按时间窗查单兜底 |

- **三条通道的共同形态：推送只作「更快知道」，周期性拉取才是正确性来源。** 回调不可达是常态，而对账的正确性不能押在推送必达上。
- 退款态记在幂等记录的**运维侧字段**上，**不进 `GET /v1/purchase/receipt/{receiptId}` 的 `status` 枚举**（`ADR-0013` 已把它冻结为 `{ unknown, verified, rejected }`）。理由：客户端对「已退款」**没有任何动作可做**（货已发、序号不退），把它下发只会诱导客户端去实现一条不存在的处置。

### D. 微信支付需要一个下单端点（承重，改动 §1 的「端点集：两个」）

`[既有推演]`（由 B3 的渠道形态与「客户端永不接触渠道 secret」共同推出）

微信支付 APP 支付的下单调用必须由**商户后台**发起（需商户私钥签名），客户端无法自行取得支付所需的参数。因此 `purchase.md` §1 的两端点集**不足以支撑微信渠道**，建议补第三个：

```
POST /v1/purchase/order   为需要商户侧下单的渠道创建订单   —— 需鉴权
```

| 方向 | 字段 | 语义 |
|---|---|---|
| ↑ | `platform` | **枚举取值受限于「需商户侧下单」的渠道子集**（当前仅 `WeChatPay`）；其余取值走 schema 拒绝 → `purchase.payload_invalid` |
| ↑ | `productId` | SKU 标识 |
| ↓ | `receiptId` | 本次订单的幂等键（= `wx_` + `outTradeNo`），**客户端须随待兑现态一并持久化**——它是补查的唯一入口 |
| ↓ | `channelOrderParams` | 交给渠道 SDK 唤起支付的参数对象，形态**逐渠道不同**，同样按 `platform` 判别 |

- **端点只对需要它的渠道存在，不做成「三渠道统一下单」。** Google / Apple 的订单由平台商店自己创建，硬造一个空转的下单步骤会让两条渠道多一次可失败的往返，且它们的 `receiptId` 只能在购买**之后**才存在，预分配根本不成立。
- **本端点不写入 `bundleGrantOrdinal`**，`ADR-0007` 的权威分配逐字不变：它只创建订单并**预落一条 `status = unknown` 的幂等记录**。这也恰好把 `GET /receipt/{receiptId}` 的 `unknown` 态从「理论值」变成微信渠道的常规态。
- **未支付订单的清理**：预落的 `unknown` 记录若在订单有效期后仍未转 `verified`，由对账任务标记为**关单**（运维侧字段），**记录本身不删**——删除会让同一 `outTradeNo` 的迟到查询查不到记录，正是 §7 拒绝设 TTL 所要堵的那条路径。

### E. 幂等记录的存储：语义与判据（不点名产品）

`[既有推演]`

**E1. 三条选型判据（不满足即出局）**

| # | 判据 | 不满足的后果 |
|---|---|---|
| S1 | **幂等记录的写入与 `bundleGrantOrdinal += 1`、`cloudRevision += 1` 能落在同一次事务内**（`purchase.md` §7 存储形态列） | 出现「revision 已 `+1` 但幂等记录未落」的中间态——正是重放会重复发放的那一刻 |
| S2 | **`receiptId` 的唯一性由存储层的唯一约束保证，不由应用层「先读后写」保证** | 并发双提交在读-写窗口内双双通过，同一张票 `+1` 两次；这类窗口在压测下不出现、在线上偶发 |
| S3 | **收据记录的读路径与 profile 读路径受同一条读己所写约束**（`purchase.md` §6 保证 3 · `ADR-0013`） | `GET /receipt/{receiptId}` 读到滞后副本 ⇒ 客户端在阻塞重试态下反复读到 `unknown`，与「verify 从未成功」不可区分 |

**S1 与「全局唯一键」的张力，以及化解形态。** 全局唯一要求一条跨账号的唯一索引；账号级事务通常按账号分区。若选型无法让两者同处一次事务，**退化形态**（仅在 S1 不可满足时启用）：拆成两条记录 ——

- `receiptClaim`：全局唯一索引 `receiptId → { accountId, claimedAtUtc, state }`，在事务**之前**以 `state = claiming` 写入；
- `receiptRecord`：与账号聚合同处，随 `+1` 事务一并写入。

判定规则：claim 命中且 `accountId` 相同 ⇒ 同一账号的重试，接管并继续；`accountId` 不同 ⇒ `purchase.receipt_claimed`（正确，一张票只属于一个购买者）。悬挂的 `claiming`（超过阈值仍无对应 `receiptRecord`）由清理任务回收，**阈值初值 10 分钟**（推导：一次验票的端到端上界是渠道查询超时 + 事务耗时，秒级；10 分钟给异常态两个数量级余量，且远短于玩家重试的耐心周期）。**这是退化形态而非首选**——它把一个事务变成两步，正确性靠一条清理任务维持。

**E2. 分区与索引**

- **按 `receiptId` 做哈希分区**：本表的在线负载**只有点查**（验票时查重、补查端点），没有任何按 `receiptId` 的范围扫描，哈希分区给出最均匀的分布。
- **按时间分区是错的**：会让点查退化为跨全部分区的广播（查询时不知道这张票是哪年的）。时间维度只用于**归档**（E4），不用于在线分区。
- **一条二级索引 `(accountId, verifiedAtUtc)`**：对账、客服排障、退款处置的唯一查询路径都是「这个账号买过什么」。缺它则这三件事只能全表扫。

**E3. 与 `(accountId, pushId)` 幂等记录的同处：可同系统，不可合表**

| 维度 | `receiptId` | `(accountId, pushId)` |
|---|---|---|
| 键作用域 | 全局 | 账号内 |
| 保留期 | **永久，不设 TTL** | 30 天 TTL |
| 写入频次 | 每账号个位数 / 年 | 稳态约每分钟 1 次 / 账号 |

- 结论：**同一存储系统可以，同一张表不行。** 差三个数量级的写入频次与两套相反的保留策略共表，唯一的好处是少建一张表。
- **承重的一条：收据表须显式关闭任何 TTL / 过期清理机制，并在配置层留一条断言。** 合表（或共享 TTL 配置）时一次误配置就等于收据记录被清掉 = 重复发放漏洞，而这个漏洞**线上不可发现**（§7 已写明这条不对称性）。

**E4. 体量与冷存归档：给触发条件，首版不做**

体量推导（数量级估算，非承诺）：单条记录以 `receiptId`（≤256 字符）为主，含索引约 **0.5 KB / 条**。购买次数与付费用户数同阶、每账号个位数 / 年 ⇒ 即便按 **每年 100 万次购买**估，也只有约 **0.5 GB / 年**。

- **建议首版不做冷存归档**，只留触发条件。**触发任一即启动**：① 在线表行数 > **5,000 万**；② 表 + 索引 > **50 GB**；③ 点查 p99 > **20 ms** 持续 7 天。推导：①② 按上述体量相当于数十年量级，实际上必然先经历一次栈演进；③ 是唯一可能提前到来的信号，且它直接对应玩家侧的阻塞等待时长。**三个阈值均为初值，待实测校准。**
- **归档形态的承重约束：`receiptId` 的全量唯一性索引永不归档，可归档的只有记录体。** 幂等查询必须命中冷数据——一次查不到就等于「当作新票」重复发放。因此**明确否决**「归档到只能顺序扫描的介质」（日志式冷存）这一常见形态：它对本表不适用，因为本表的冷数据仍需**点查**。可接受的形态是：冷分区仍可点查、只是延迟更高（补查端点的延迟预算宽松，玩家侧本就是阻塞重试态）。
- 归档切分维度用 `verifiedAtUtc`（年度分区），与 E2 的在线哈希分区不冲突——归档是把整个「年」的记录体搬走，不改变在线点查路径。

### F. 对账信号：两条，只作人工 / 工单入口

`[既有推演]`（`purchase.md` §7 已定「不驱动任何自动写入」）

| 信号 | 阈值初值 | 推导 |
|---|---|---|
| `bundleGrantOrdinal > bundleRedeemedOrdinal` **持续 N 天** | **N = 3 天** | 客户端的兑现触发点是「主菜单、一次 pull 完成之后」⇒ 正常玩家在下一次登录即追平。3 天覆盖一个周末的正常缺席，同时**远短于平台退款 / 客诉窗口（以月计）**，使工单仍落在可处置期内 |
| **差值 ≥ 2** | 立即（不设持续时长） | 正常路径下差值只会短暂为 1；≥2 意味着连续两次购买都未兑现，或兑现路径本身坏了——这是故障信号，不是玩家缺席信号 |
| 「已付款但从未 verify」（渠道对账发现） | 按渠道对账周期，建议 **每日一次** | `ADR-0007` 已把它定为回调 / 对账的兜底职责；日频足以落在退款窗口内 |

- **指标形态：一条 gauge「当前处于 `grant > redeemed` 的账号数」+ 一条按持续时长分桶的分布**，不做逐账号告警——逐账号会在任何一次客户端发版事故中变成告警风暴。
- **落点 `operations/`**：建议新建 `purchase-ops.md`（渠道凭据与轮换 · 对账任务 · 退款处置 · 归档触发条件），与 `observability.md` 的三条同步探针并列。

### G. 渠道验票凭据与密钥保管

`[既有推演]`（与 `06` 已有的两条同形项并列，形成第三条）

| 渠道 | 服务端凭据 | 轮换特征 |
|---|---|---|
| Google Play | Play Developer API 的服务账号凭据（或等价的工作负载身份） | 可无停机轮换；权限范围只给「查询 + 消费购买」 |
| App Store | In-App Purchase key（`.p8` + keyId + issuerId）用于 Server API；Apple 根证书用于离线 JWS 校验 | key 可并存新旧；**根证书随 Apple 更新，须有更新通道** |
| 微信支付 | 商户 API 私钥 + 证书序列号、APIv3 密钥（回调解密）、平台证书 / 公钥（回调验签） | **平台证书会轮换**，须支持新旧并存期，否则轮换当天全渠道验票中断 |

- **三套凭据一律只在服务端，绝不进客户端二进制**——与 `auth.md` §3a 义务 1 逐字同构。
- **与 `06` 已有两条钥匙区分清楚**：内容签名 ES256 私钥（`04`）、会话 token 签名密钥（`06`）、**渠道验票凭据（本条）**——**三把钥匙、三套轮换窗口**，不共用托管配置。具体托管形态（KMS / 密钥托管服务）待栈落定。
- **环境隔离是凭据层的事**：测试环境用沙箱凭据、生产用生产凭据，且 B1 / B2 的环境校验以**部署环境配置**为准，不以收据自述为准。

---

## 具体形态（可 derive 的落地面）

汇总为可被 `/derive-requirements` 消费的清单：

1. **报文**：`VerifyRequest` 的三分支判别式联合（A）+ 三张 `receipt` 字段表（B1–B3）+ `receiptId` 取值与字符集 / 长度上界。
2. **端点**：新增 `POST /v1/purchase/order`（D），请求 / 应答字段表如上；`platform` 枚举受限子集。
3. **错误码**：四条新 `code` 的台账行（C1，形状完整：`class` · `OpError` · 处置 · `detail` · `message` 必含）+ 三张逐渠道映射表（C2）。
4. **服务端断言**（栈中立，可直接进 FR 的 `## Failure & retry semantics`）：
   - A1 同一 `receiptId` 由**不同**账号提交 ⇒ 回 `purchase.receipt_claimed`，且 `bundleGrantOrdinal` / `cloudRevision` 两侧账号均不变。
   - A2 渠道查询超时 / 5xx ⇒ 回 `server.unavailable`（`Retryable`），**不写入任何状态**，重试可再次抵达同一判定。
   - A3 渠道返回未终态（Google `Pending` / 微信 `USERPAYING`·`NOTPAY`）⇒ 回 `purchase.receipt_pending`，**不写入**，客户端保持待兑现态。
   - A4 收据校验的任一项不符（签名 / 环境 / `bundleId`·`packageName` / SKU / 金额 / 归属）⇒ 回 `purchase.receipt_invalid` + 一条风控事件（账号 · 平台 · 失败项 · `requestId`）。
   - A5 请求体不满足所选 `platform` 分支的必填集合 ⇒ 回 `purchase.payload_invalid`，`detail.field` 给第一条违规路径。
   - A6 Google 渠道：consume 只在 `+1` 事务提交后发起；consume 失败不影响已提交的 `+1`，进补偿队列。
   - A7 微信渠道：`POST /v1/purchase/order` 成功 ⇒ 幂等记录以 `status = unknown` 存在，`GET /receipt/{receiptId}` 立即可读到它（受 S3 约束）。
5. **存储判据**：S1 / S2 / S3 三条（E1）+ 分区与索引（E2）+ 不合表与 TTL 禁用断言（E3）。
6. **数值初值**（全部待实测校准）：悬挂 claim 回收 10 分钟 · 归档触发 5,000 万行 / 50 GB / p99 20 ms 持续 7 天 · 对账 N = 3 天 · 差值 ≥ 2 立即 · 渠道对账日频。

## 后果

- **`contracts/purchase.md`**：§1 端点集由两个变三个（D）；§3 字段表补 `receipt` 的判别式形态与逐渠道表、失败面补具体 `code`；§7 的「存储形态」行补一条指向 `operations/` 的判据回链。**§2 的权威分配、§5 的复算、§6 的七条保证逐字不变**——它们对渠道无差别，本草稿不触碰。
- **`contracts/envelope.md` §6**：新增四行台账；同一次变更须补进 `openapi.yaml` 的错误码枚举（`operations/_index.md` 的流程）。
- **`contracts/_index.md`**：`purchase.md` 的状态由 blocked 转 partial 的前置条件由此满足（余下待落笔的是 spec 本身）。
- **`operations/`**：新增 `purchase-ops.md` 的计划条目（渠道凭据与轮换 · 三条对账通道 · 退款处置 · 归档触发条件 · 两条对账信号）。
- **`open-questions/06-platform-stack.md`**：两条待答项可**部分**移出——余下的是与栈强耦合的部分（存储产品、事务域、密钥托管形态）。
- **ADR 候选（两条）**：① 「验票请求的判别式发生在请求根，`receipt` 逐渠道成形」；② 「微信渠道引入下单端点，但不改变 `ADR-0007` 的写入权威分配」。第二条值得固化，否则「既然有了下单端点，不如让它也参与写入」会被反复提出。
- **无存档 schema 迁移**：本草稿不触碰 Profile 的任何 JSON path，`schemaVersion` 不 bump。

## 备选方案（已考虑并否决）

- **`receipt` 定义为不透明字符串（base64 / 原样 JSON 串）** — 三渠道的必填性全部退化为运行时判断，spec 单点在购买域名存实亡（A）。
- **把 `platform` 复制进 `receipt` 内部以便就地判别** — 同一事实两个落点，两者不等时报文层无从裁决（A）。
- **三个渠道各开一个 verify 端点** — 写入路径、事务语义、七条服务端保证三倍复制，而它们对渠道无差别（A）。
- **接收并信任 Google 的 `originalJson` + `signature` 本地校验** — 把客户端提交的 JSON 变成事实来源，与 §2「不信客户端自述」正面相悖（B1）。
- **信任客户端提交的 `transactionId` / 微信 `errCode`** — 二者皆可伪造，且微信侧还会在支付成功后丢失（B2 / B3）。
- **为「平台不可达」新造 `purchase.channel_unavailable`** — 与 `server.unavailable` 的客户端处置逐字相同，多一行映射表换零收益；`auth.md` §3a 已有同形先例（C1）。
- **把 `purchase.receipt_pending` 并入 `server.unavailable`** — 探针无法区分「我方故障」与「玩家用了慢速支付」，而这两条曲线一个叫人、一个不叫人（C1）。
- **按无效成因细分出多个 `code`** — 客户端处置逐字相同，处置表多十行走同一条路径（C1）。
- **退款回收权益 / 回退 `bundleGrantOrdinal`** — 与 §6 保证 4「严格单调不清零」直接冲突，且条目已写进玩家存档，回收比不发更糟（C3）。
- **把「已退款」加进 `GET /receipt` 的 `status` 枚举** — `ADR-0013` 已冻结三值，且客户端对它没有任何动作可做，下发只会诱导实现一条不存在的处置（C3）。
- **做成三渠道统一的下单端点** — Google / Apple 的 `receiptId` 只在购买之后存在，预分配不成立；硬造的空转步骤只增加可失败的往返（D）。
- **让下单端点也参与权益写入** — 直接推翻 `ADR-0007` 的写入权威分配（D）。
- **收据幂等记录与 `(accountId, pushId)` 记录合表** — 两套相反的保留策略共表，一次 TTL 误配置 = 线上不可发现的重复发放漏洞（E3）。
- **按时间对收据表做在线分区** — 点查退化为跨全部分区广播（E2）。
- **归档到只能顺序扫描的冷介质** — 冷数据仍须点查，查不到即当作新票重复发放（E4）。
- **首版即上冷存归档** — 按体量推导，触发条件在数十年量级才到达；先做等于为一个不存在的问题增加一条正确性关键路径（E4）。
- **对账信号自动补发 / 自动退款处置** — `purchase.md` §7 与 `ADR-0013` 已明确否决，等于后端具备发放权（F）。

## 与既有决策的张力

1. **`purchase.md` §1「端点集：两个」与微信渠道的结构需求冲突（🔴，需裁决）。**
   冲突的是「两个端点」这句话本身，而非任何承重纪律。微信支付 APP 支付要求商户后台先下单（需商户私钥签名），客户端无从自行取得支付参数。
   **需要它松动的理由**：不松动就无法接入微信渠道，而三渠道纳入 MVP 是既定范围（`game-design-documents/vision/scope.md`）。
   **松动的代价**：`purchase.md` 的端点集不再是一句可背诵的「两个」；且新端点是一条新的、需鉴权的写路径（写幂等记录），扩大了本域的攻击面（须有滥用阈值，形态归 `06`）。
   **不松动的替代方案**：把下单做成微信渠道专有的**非 `/v1/purchase/` 端点**（例如归入运营侧）——否决，它把同一域的两步拆到两个契约文档，读者无从发现 `receiptId` 是在别处分配的。
   **本草稿的建议**：松动，并同批把「新增端点不改变 `ADR-0007` 的写入权威」写成 ADR。

2. **`purchase.md` §3「幂等键由平台发放」在微信渠道下不成立（🟠，措辞细化）。**
   微信的 `outTradeNo` 由**我方后端**在下单时分配。§3 的承重意图是「**不由客户端生成**」（防篡改），而不是「必须由渠道方发放」——后者只是另两家的事实描述被写进了理由句。
   **建议**：把该句改写为「幂等键不由客户端生成；两家商店渠道取平台发放的 id，微信渠道取后端在下单时分配的商户订单号」。§7 的三条旋钮（全局唯一 / 永久保留 / 同一事务）逐字不变，`ADR-0013` 无需改动。

3. **`ADR-0013` 的「读己所写」现在多了一个受约束对象（🔵，只是范围确认）。**
   原文约束的是 `pull` 与 `GET /receipt/{receiptId}`；D 引入的下单端点使 `unknown` 态成为微信渠道的常规态 ⇒ 下单应答返回后，`GET /receipt/{receiptId}` 必须立即读到那条 `unknown` 记录（否则客户端在阻塞态下读到 404 / 不存在，与「下单失败」不可区分）。**这不是新约束，是同一条约束覆盖到新写入点**，建议在 `purchase.md` §6 保证 3 的措辞里显式含进去。

## 前置依赖

- **`06-platform-stack.md` 的栈与托管选型**：E1 的 S1 / S2 / S3 是**判据**而非选型结论；分区能力、跨记录事务域、单写入区拓扑、密钥托管形态全部待栈落定。本草稿的存储部分在栈落定前无法定稿到实现层，但**判据本身即可先行采纳**（它是选型的输入）。
- **`operations/` 尚未落笔**：F 与 G 的落点 `purchase-ops.md` 是计划中的文档，本草稿只作登记。
- **客户端侧两项承接（本库不代为决定，只回链）**：
  - **`OpError` 是否新增 `Purchase` 成员**。现有成员（`Auth` / `Compliance` / `Conflict` / `Validation` / `Network` / `NotFound` / `Cancelled` / `Migration`）中没有能承载购买失败面的一档；C1 的映射列因此暂标「待确认」，并给了退化映射。权威在 `game-design-documents/systems/services/account-service.md` 与 `sync-service.md`。
  - **`purchase.receipt_pending` 的长等待 UX**。Google 的慢速支付可 pending 数小时至数日，而客户端购后是**全屏模态阻塞、无硬超时永不放弃**（`game-design-documents/systems/monetization.md`）。「钱还没扣、请稍后回来」与「已付款正在发放」是两句不同的话，本库只保证二者在报文层可区分（`code` 不同），呈现形态归客户端。
  - **Apple 的 `finish()` 时机**（B2）：只能在 verify 成功或 `deduplicated = true` 之后由客户端调用。本库只能声明「verify 应答是它的前置」，动作本身在客户端。
- **`openapi.yaml` 的落笔时机**：A 与 D 的形态最终由 spec 单点承载（`envelope.md` §1）；在 spec 落笔前，本草稿的字段表按该节纪律**视为草案**。

## 仍需用户决定

1. **三渠道是否同批上线，还是首版只上两家、微信随资质到位再开？**
   - **选项 A（三渠道同批）**：MVP 即覆盖国内外全部支付面。代价：微信支付商户资质 + 微信开放平台资质（后者已因登录渠道而**必须在首个玩家建号前完成**）成为上线的硬前置，任一卡住即整体延期。
   - **选项 B（首版 Google Play + App Store，微信随资质开）**：契约面**照旧封闭为三个 `platform` 取值**，微信分支先不实现，调用即返回 `purchase.receipt_invalid`；下单端点同批落笔但只对已开通渠道放行。
   - **推荐 B。** 理由是 `auth.md` §3「首版上线两个渠道 / **不实现 ≠ 从契约删除**」的先例逐字适用：删掉再加回是破坏性契约变更，追加实现不是。它把资质风险从「上线闸门」降为「渠道开通开关」，且不改变本草稿的任何形态。
   - **注意**：这条只决定**实现排期**，不改 `platform` 取值域（那已由 `game-design-documents/vision/scope.md` 封定）。
   - → **已裁决（2026-09-02 · 批量评审）：选项 B** —— 首版 Google Play + App Store，微信随资质开；`platform` 取值域不变。

2. **对惯性退款者是否做自动处置？**
   - **选项 A（仅记账 + 工单）**：退款只在收据记录上打标、进对账报表，处置由人工按个案决定。
   - **选项 B（累计 N 次退款后自动限制购买 / 封禁）**：需要一条自动写入路径与一套申诉出口。
   - **推荐 A（MVP 内）。** 理由：`ADR-0007` 与 §7 已把「后端自动写入」在本域关死了两次（自动补发、对账驱动写入），为退款单开一条自动写入路径会让那条纪律出现第一个例外；且 MVP 的付费面是单一 SKU、单一价格档，滥用的收益上限本就很低。B 可在有实际滥用数据后再议。
   - → **已按标准默认采纳（2026-09-02 · 批量评审）：选项 A**（仅记账 + 工单）。判据明确、无客观争点，未占用 interview 名额。

---

## 批量评审同批裁决（本草稿的两条张力）

- **张力 1（🔴 端点集 2 → 3）→ 已裁决：新增 `POST /v1/purchase/order`。** 同批写一条 ADR 固定「新增端点不改变 `ADR-0007` 的写入权威」。
- **张力 2（🟠 §3「幂等键由平台发放」措辞）→ 已按标准默认采纳**：改写为「不由客户端生成；两家商店渠道取平台发放的 id，微信渠道取后端下单时分配的商户订单号」。承重意图不变，§7 三条旋钮与 `ADR-0013` 逐字不变。
- 张力 3（🔵 读己所写覆盖到下单端点）是同一约束的适用面说明，无需裁决，落笔时在 §6 保证 3 措辞里显式含进。
