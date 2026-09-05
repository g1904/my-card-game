# purchase —— 付费验票 · 后端权威写入 · 收据幂等

> 覆盖 `/v1/purchase/…` 三个端点的报文本体。**边界层不在此重复**：序列化与命名约定、`/v1/` 主版本、传输信封、错误体形状、错误码台账、版本协商——全部见 `envelope.md`，本文件只写 purchase 域**相对它的差异与细化**。
> 客户端侧的购买流程、兑现段演算与入口前置条件见 `game-design-documents/systems/monetization.md` 与 `game-design-documents/systems/services/sync-service.md`（那里描述**客户端怎么用**；此处描述**报文长什么样**）。
> 技术栈未定 ⇒ 本文件停在**协议与语义层**，不指定语言 / 框架 / 存储实现。字段形态最终由 spec 单点承载（`envelope.md` §1）。

## 1. 端点集：三个

```
POST /v1/purchase/verify              提交平台收据 → 验票 → 权威写入   —— 需鉴权
GET  /v1/purchase/receipt/{receiptId} 收据状态的幂等读                 —— 需鉴权
POST /v1/purchase/order               为需商户侧下单的渠道创建订单     —— 需鉴权
```

**第三个端点只对「需商户侧下单」的渠道存在**（当前仅微信支付），不做成三渠道统一下单：商店渠道的订单由平台自己创建，其 `receiptId` 只在购买**之后**才存在，预分配不成立，硬造一个空转步骤只会给两条渠道多一次可失败的往返。它是一条需鉴权的写路径（写幂等记录），**滥用阈值的形态归 `operations/purchase-ops.md`**。三个端点全部需鉴权：`envelope.md` §4a 的免鉴权判据是「调用它的玩家此刻**不可能**持有 access token」，而下单发生在已登录的商店屏，不够格豁免。

**本域与 `profile-sync` 的承重纪律恰好相反，这是它单独成文的第一理由。** `profile-sync` 的三条纪律是「后端对透明段只读 · 后端不裁决 · 复算不一致不拒绝」；购买则是**后端权威写入 · 必须裁决 · 必须能拒绝**。两套相反的纪律同居一份契约，读者无法判断哪一条管哪个端点。另两条理由：`_index.md` 的分域惯例本就按域切（边界层 / 内容分发 / 登录会话 / 存档同步 / 购买）；本域牵动平台 SDK 与渠道回调，与 `02-account-compliance.md` 的「自建 vs 接第三方」耦合，独立成文才使那条耦合显式可见。

## 2. 验票的权威分配：写入只由 verify 承担

- **验票必须由后端向平台服务器校验，不信客户端自述。** 客户端已明写「付费凭证不能只信客户端」，`bundleGrantOrdinal` 的推进权因此只能在后端——否则整套防篡改归零。
- **渠道回调只作对账 / 补偿通道，不作写入路径。** 渠道回调的时序不可控：可能早于、晚于、或永不到达客户端的 verify。把它作为写入路径会让「玩家已付款但序号未涨」无处排查，且要额外处理「回调与 verify 竞态」——而那条竞态的收益仅在「客户端崩溃且从不回来」这一场景。**回调记账与补偿任务归 `operations/`**，作为「已付款但从未 verify」的兜底发现手段。
- **兑现段仍由客户端掷骰、后端复算**（`profile-sync.md` §6 §7），本域不参与兑现。

## 3. `POST /v1/purchase/verify`

| 方向 | 字段 | 语义 |
|---|---|---|
| ↑ | `platform` | 枚举字符串，取值与客户端 C# 成员名逐字相同（`envelope.md` §2）。**取值域封闭为三条渠道**：Google Play Billing · App Store（StoreKit）· 微信支付（范围权威在 `game-design-documents/vision/scope.md`；成员名两侧同批冻结） |
| ↑ | `receiptId` | 收据唯一 id —— **幂等键**（取值见 §3a，窗口见 §7） |
| ↑ | `receipt` | 平台原始收据负载，形态**逐渠道不同**（§3a）。**请求体整体是一个以 `platform` 为判别式的三分支联合**，见下 |
| ↓ | `bundleGrantOrdinal` | `+1` 后的新序号（**兑现段掷骰的 `ordinal`**） |
| ↓ | `revision` | `+1` 后的新 `cloudRevision` |
| ↓ | `deduplicated` | boolean；同一 `receiptId` 重复提交时为 `true`，序号与 `revision` 回上次结果 |

- **幂等键不由客户端生成。** 两家商店渠道取平台发放的 id，微信渠道取后端在下单时分配的商户订单号（§3a · §3b）。承重的是「不由客户端生成」——防篡改；「由渠道方发放」只是商店渠道的事实描述，不是这条纪律本身。这与 `profile-sync` 为同一场景引入 `pushId` 是同一条理由，只是这里的键不需要客户端造。
- **判别式发生在请求根，不在 `receipt` 内部。** `VerifyRequest` 定义为 `oneOf` 三个分支（`GooglePlay` / `AppStore` / `WeChatPay`），每个分支内 `platform` 为 const、`receipt` 为该渠道的具体对象；spec 层即 JSON Schema `oneOf` + `discriminator: { propertyName: "platform" }`。`platform` 是 `receipt` 的兄弟字段，而 `discriminator` 要求判别属性出现在每个子 schema 内——把 `platform` 复制进 `receipt` 会造出同一事实的两个落点，两者不等时报文层无从裁决哪个为准。判别提到根则一处判别、一处校验，`receipt` 保持纯净。
- **必填性因此可被 schema 层校验**：缺字段 / 类型不符 → `purchase.payload_invalid`。`envelope.md` §2 的「忽略未知字段」管的是**多余**字段，与必填校验不同轴，两者不冲突。
- **新增第四条渠道 = 新增一个 `oneOf` 分支 + 一个枚举值**，对既有客户端是纯追加（老客户端从不发送新值）⇒ `openapi.yaml` 的 `info.version` bump minor，`/v1/` 不动。**明确否决把 `receipt` 定义为不透明字符串**（base64 / 原样 JSON 串）：三渠道的必填性会全部退化为运行时判断，「字段形态由 spec 单点承载」（`envelope.md` §1）对本域就等于没写。
- **同一 `receiptId` 重复提交绝不重复 `+1`**，直接回上次结果（与 `pushId` 的 `deduplicated = true` 同构）。缺这一条，移动网络下的重试会让玩家的序号跳号、掷骰序列错位。
- **`bundleGrantOrdinal += 1` 与 `cloudRevision += 1` 必须在同一次事务内**——与 `profile-sync.md` §8 的「禁止先写 profile 再改 revision 的两步非原子形态」同一条。
- **verify 不接受 `baseRevision`、不做 CAS 判定。** 它是后端权威写入，不是客户端提交的 diff；且客户端此刻的 `baseRevision` 必然落后，走 CAS 只会失败。客户端拿新 `revision` 的路径是**购后强制一次 pull**（客户端已定）。
- **应答只回序号 + revision，不内联新 profile。** 客户端本就会另发一次 pull，两侧形态因此一致；且让 verify 保持**窄接口**，不与 profile 的下行形态耦合。否决内联：省一个 RTT，却把 profile 的完整下行形态复制进购买域，两处形态从此要同步演进。

**失败面**（`code` 的 `class` / `OpError` / 客户端处置 / `detail` 形状归 `envelope.md` §6 台账，本节只列本域用到哪几条）：

| 情形 | `code` |
|---|---|
| 收据无效（签名 / 环境 / SKU / 金额 / 归属任一项不符，或渠道已关单 / 已退款） | `purchase.receipt_invalid` |
| 该收据已被**其他账号**核销 | `purchase.receipt_claimed` |
| 渠道明确回「交易尚未终态」（钱未确认扣） | `purchase.receipt_pending` |
| 请求体不满足所选 `platform` 分支的必填集合 | `purchase.payload_invalid` |
| 渠道未开通（`POST /v1/purchase/order`，见 §3b） | `purchase.channel_disabled` |
| 平台服务不可达 / 超时 / 限频 / 我方凭据失效 | `server.unavailable`（**可重试**） |

- **平台不可达复用 `server.unavailable`，不新造渠道码。** `auth.md` §3a 对登录渠道已这么处理，且台账为该码规定的 `message` 必含项正是「下游组件与失败阶段」——渠道名与查询阶段落在那里正合适。新造一个 `purchase.channel_unavailable` 只会让客户端的两条路径走同一条处置，却多一行映射表。
- **`purchase.receipt_pending` 必须与 `server.unavailable` 分列。** 二者 `class` 相同、退避形态相同，含义却相反：一个是「我方查不到平台」，一个是「平台明确说这笔钱还没到位」。合并会让线上探针无法区分「我方故障」与「玩家用了慢速支付方式」，而这两条曲线一个叫人、一个不叫人。
- **`purchase.receipt_invalid` 不按成因细分。** 十几种成因对**客户端处置逐字相同**，细分只会让处置表多十行走同一条路径——与 §6 台账「`restricted` 与 `banned` 共用一个 `code`、靠 `reasonKey` 分辨」同一判据。成因进 `message` 与风控事件，不进 `code`。
- **渠道原始错误码只随日志上报，客户端不解析**（`auth.md` §3a 同形）：`receipt_invalid` 的 `detail.channelCode`、`receipt_pending` 的 `detail.channelState` 均为原样透传的渠道串。
- **`purchase.receipt_claimed` 的 `detail` 与 `message` 绝不含另一账号的任何标识**——只给当前账号前缀与 `receiptId` 前缀截断。

**verify 不返回 `compliance.*`。** 它是业务端点，而合规拦截只在 `signin` 落地（`auth.md` §5a）：在这里硬拒，玩家会在已付款之后拿不到发放，而钱已经花了——这是「仅两处硬阻塞」那条纪律代价最高的一处违反。被合规拦住的账号根本走不到 verify，因为它拿不到 access token。

## 3a. 逐渠道的 `receipt` 形态与渠道状态映射

**贯穿三张表的一条纪律：客户端提交的一切只作「去哪里查」的索引，不作判据。** 权威状态一律由后端向渠道服务器查询取得——这是 §2「不信客户端自述」在字段层的兑现，也解释了三张表为什么都这么窄。**三套服务端验票凭据只在服务端、绝不进客户端二进制**（`auth.md` §3a 义务 1 逐字同构）；凭据形态与轮换窗口见 `operations/purchase-ops.md`。

### `GooglePlay` —— `GooglePlayReceipt`

| 字段 | 必填 | 来源与用途 |
|---|---|---|
| `purchaseToken` | ✅ | 客户端 `Purchase.getPurchaseToken()`；后端据此向 Play Developer API 取权威状态 |
| `productId` | ✅ | 后端**与自己的 SKU 表比对**，不匹配即无效 |
| `orderId` | ➖ | 测试 / 促销购买可能缺省。**仅进日志与工单**，不参与任何判定 |

- **不接收 `originalJson` / `signature`**（客户端本地签名校验的那一对）。收下它等于把客户端提交的 JSON 变成事实来源；服务端 API 校验本就更强，两条并存只会让「以哪条为准」再成一题。**`packageName` 不由客户端提交**，后端取自身配置——客户端提交的包名对防伪毫无贡献。
- **商品须配置为 consumable**（可重复购买是既定语义）。**acknowledge / consume 只能在 `+1` 事务提交之后由后端发起**，失败进补偿队列重试，客户端不承担该动作：提前 consume 而事务失败 ⇒ 玩家付了钱、票被消掉、序号没涨，且再也查不回来。

| 渠道侧情形 | `code` | 附加动作 |
|---|---|---|
| token 不存在 / 与 `productId` 或 `packageName` 不匹配 | `purchase.receipt_invalid` | — |
| `productId` 不在本作 SKU 表内 | `purchase.receipt_invalid` | 风控事件 |
| `purchaseState = Cancelled`，或命中 voided 列表 | `purchase.receipt_invalid` | — |
| `purchaseState = Pending`（慢速支付） | `purchase.receipt_pending` | — |
| `purchaseType = Test` 且部署环境为生产 | `purchase.receipt_invalid` | 风控事件（**高优**） |
| `consumptionState = 已消费` 且本库无该 `receiptId` 记录 | `purchase.receipt_invalid` | 风控事件（票被别处消掉了） |
| 该 `receiptId` 已存在、`accountId` 不同 | `purchase.receipt_claimed` | 风控事件 |
| 该 `receiptId` 已存在、`accountId` 相同 | **不是失败**：回 `deduplicated = true` | — |
| API 401 / 403（服务账号凭据失效 / 权限被撤） | `server.unavailable` | **P1 告警**——我方配置事故，不是玩家问题 |
| API 5xx / 超时 / 配额 429 | `server.unavailable` | 带 `Retry-After` |

### `AppStore` —— `AppStoreReceipt`

| 字段 | 必填 | 来源与用途 |
|---|---|---|
| `signedTransaction` | ✅ | StoreKit 2 的 JWS compact 串（`VerificationResult.jwsRepresentation`） |
| `transactionId` | ➖ | 便于早期路由与日志。**后端只信 JWS 内解出的值**，两者不等即按无效处理并记风控 |

- 后端义务：验证 JWS 证书链至 Apple 根证书 → 校验 `bundleId` / `productId` / **`environment`** → 必要时以 App Store Server API 复核该 `transactionId` 的当前状态（是否已退款 / 撤销）。
- **`environment` 校验是承重项，不是可选加固**：Sandbox 交易在生产环境被接受 = 任何人可无限白嫖礼包。Google 侧的 `purchaseType = Test` 同理。
- **`finish()` 只能在 verify 成功或 `deduplicated = true` 之后调用**——Apple 侧没有服务端 finish 接口，这一条只能落在客户端。本契约只声明「verify 应答是它的前置」，动作形态归 `game-design-documents/systems/monetization.md`。

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

> 消耗型交易在 StoreKit 2 下**没有 pending 态**（家庭共享的延迟批准表现为交易根本不产生），故本渠道不产出 `purchase.receipt_pending`。这不影响该 `code` 的定义——`code` 按语义定义，不按「每个渠道都得用上」定义。

### `WeChatPay` —— `WeChatPayReceipt`

| 字段 | 必填 | 来源与用途 |
|---|---|---|
| `outTradeNo` | ✅ | **本域下单端点（§3b）下发的商户订单号**；后端据此向商户后台查单取 `trade_state` / `transaction_id` / `amount` |

- 只有一个字段，是因为微信支付的形态与另两家**结构不同**：不存在「平台发给客户端的收据」，权威状态只能由商户后台以 `outTradeNo` 查单取得。
- **客户端 SDK 返回的 `errCode` 不作任何判据**：它既可被伪造，也可能在支付成功后丢失（用户切走 App）。它至多作为 `channelCode` 随日志上报。
- **本渠道特有的必查四项**：`appid` / `mchid` / `amount.total` / `outTradeNo` 的**账号归属**须逐一比对。另两家的收据自带应用绑定，微信的订单号由我方分配，绑定关系只能由我方自查——漏掉「归属」这一项即等于任何登录用户都能提交别人的订单号换一次发放。

| 渠道侧情形 | `code` | 附加动作 |
|---|---|---|
| `trade_state = SUCCESS` **且**必查四项全对 | **通过** | — |
| `SUCCESS` 但四项中任一不符 | `purchase.receipt_invalid` | 风控事件（**高优**） |
| `NOTPAY` / `USERPAYING` | `purchase.receipt_pending` | — |
| `CLOSED` / `REVOKED` / `PAYERROR` | `purchase.receipt_invalid` | — |
| `REFUND`（首次验票时已退款） | `purchase.receipt_invalid` | — |
| `outTradeNo` 属于另一账号 | `purchase.receipt_claimed` | 风控事件 |
| 网关 5xx / 超时 / 限频 | `server.unavailable` | 带 `Retry-After` |
| 商户证书 / APIv3 密钥失效、平台证书轮换未跟上 | `server.unavailable` | **P1 告警** |

### `receiptId` 的取值（三渠道统一形态）

| 渠道 | `receiptId` | 说明 |
|---|---|---|
| `GooglePlay` | `gp_` + `purchaseToken` | 消耗型商品每次购买产生新 token，天然唯一 |
| `AppStore` | `as_` + JWS 内解出的 `transactionId` | **不取客户端提交的那个** |
| `WeChatPay` | `wx_` + `outTradeNo` | 由后端在下单时分配（§3b） |

- **渠道前缀使「三家的 id 空间不相撞」成为可证的，而不是被假定的。** 它不是 `accountId` 前缀，与 §7「不带 `accountId` 前缀」不抵触——那一句禁的是**账号维度**前缀（它会破坏跨账号查重）。
- **字符集限制在 `[A-Za-z0-9._~-]`**：`receiptId` 要作为 `GET /v1/purchase/receipt/{receiptId}` 的**路径段**，不可要求客户端做转义——客户端此刻正处在阻塞重试态，任何编码分歧都会表现为「补查永远 404」。
- **长度上界 1024，且不做截断、不做哈希。** Google 的 `purchaseToken` 常见即数百字符且无稳定上界，上界定得太紧会让 schema 拒收一张**已付款的真票**，玩家永远卡在阻塞重试态。截断会破坏唯一性；哈希会使 `receiptId` 不再可由渠道值直接反查，抬高客服排障成本。上界的最终形态由 spec 单点承载（`envelope.md` §1）。

## 3b. `POST /v1/purchase/order`

| 方向 | 字段 | 语义 |
|---|---|---|
| ↑ | `platform` | 枚举取值**受限于「需商户侧下单」的渠道子集**（当前仅 `WeChatPay`）；其余取值走 schema 拒绝 → `purchase.payload_invalid` |
| ↑ | `productId` | SKU 标识 |
| ↓ | `receiptId` | 本次订单的幂等键（= `wx_` + `outTradeNo`）。**客户端须随待兑现态一并持久化**——它是补查的唯一入口 |
| ↓ | `channelOrderParams` | 交给渠道 SDK 唤起支付的参数对象，形态**逐渠道不同**，同样按 `platform` 判别 |

- **本端点不写入 `bundleGrantOrdinal`**，§2 的权威分配逐字不变：它只创建订单并**预落一条 `status = unknown` 的幂等记录**。这也把 `GET /receipt/{receiptId}` 的 `unknown` 态从理论值变成微信渠道的常规态。
- **未支付订单的清理：记录本身不删。** 预落的 `unknown` 记录若在订单有效期后仍未转 `verified`，由对账任务标记为关单（运维侧字段，`operations/purchase-ops.md`）。删除会让同一 `outTradeNo` 的迟到查询查不到记录，正是 §7 拒绝设 TTL 所要堵的那条路径。
- **渠道未开通时回 `purchase.channel_disabled`（`Fatal`），不复用 `receipt_invalid`。** 未开通发生在下单、玩家**尚未付款**：对他呈现「收据无效 + 客服入口」是错的话，且会让线上「无效收据」曲线被未开通渠道的调用污染。渠道开通时只需删掉实现分支，**契约面零变更**。`platform` 取值域仍封闭为三条渠道——**不实现 ≠ 从契约删除**（`auth.md` §3 的登录渠道先例逐字适用；删掉再加回是破坏性契约变更，追加实现不是）。

## 4. `GET /v1/purchase/receipt/{receiptId}`

回 `status ∈ {unknown, verified, rejected}`；`verified` 时附 `bundleGrantOrdinal` 与 `revision`，`rejected` 时附原因。**纯读、幂等、不产生任何写入。**

**本端点同样受 §6 的读己所写要求约束**：它是「响应丢失」时的补查路径，读到滞后结果的后果与 pull 读到旧序号逐字相同——客户端据此判定「无待兑现」而不再重试。

**这个端点是承重的，不是可选便利。** 客户端在「已付款、后端已 `+1`、但响应丢失」这一移动网络常态下**必须**有一条查得回来的路径；客户端据此把玩家阻塞在主菜单重试直到拿到序号（形态归客户端，见 `game-design-documents/systems/monetization.md`）。没有这条通道，那里的阻塞就变成死等。`receiptId` 由客户端随待兑现态持久化，**跨启动也能补查**。

## 5. 复算：与残卷共用同一条链，不新开

客户端兑现段用 `(accountSeed, stream = PremiumBundle, ordinal = bundleGrantOrdinal)` 掷骰抽 3 条，后端以同一三元组复算——**这正是 `profile-sync.md` §6 已定义的 SplitMix64**（`PremiumBundle = 1` 已在那里冻结）。**本契约不定义任何新的随机源**，只回链。

复算不一致的处置**沿用 §7a**（接受写入 + 打风控事件，不拒绝、不改写），不为购买单开更严的处置：兑现段的条目是客户端从池里抽的，与残卷同构；真正需要严格把关的是**验票**那一步，而它由平台校验兜住。

**这一条与 `profile-sync.md` §5c 的回声校验不抵触，判据是所有权而不是严格程度。** 本节说的是**客户端有权写、后端只作复算比对**的路径（掷骰结果与兑现水位）——值可能有争议，一次误报即一次错误的进度丢失，故只记账；§5c 管的是**客户端根本无权写**的路径（`bundleGrantOrdinal`）——值无争议地不属于它，正常客户端永远只提交回声，故零误报。**两条判据不同轴；不写下判据，两句话会被读成互相抵触。**

## 6. 服务端保证（栈中立的验收断言）

1. 同一 `receiptId` 提交 N 次，`bundleGrantOrdinal` 恰好 `+1`；第 2..N 次回 `deduplicated = true` 且序号与第 1 次逐位相同。
2. `bundleGrantOrdinal` 与 `revision` 的自增**要么都发生、要么都不发生**。
3. **读己所写（对读路径的一致性要求，不只是一条测试断言）**：verify 应答返回之后，同一账号的任何后续 `GET /v1/profile/pull` 与 `GET /v1/purchase/receipt/{receiptId}` 都必须读到该次写入的结果（`bundleGrantOrdinal` 与 `revision` 均不早于 verify 应答中的值）。**同一条约束覆盖 `POST /v1/purchase/order` 预落的 `status = unknown` 记录**：下单应答返回之后，`GET /receipt/{receiptId}` 必须立即读到它——否则客户端在阻塞态下读到「不存在」，与「下单失败」不可区分。
4. `bundleGrantOrdinal` 账号级**严格单调递增、不清零**（与 `finaleWinOrdinal` 同一条纪律）。
5. 上行 `playerDiff.entitlement.bundleGrantOrdinal` 与云端当前值不等 ⇒ 上行被拒（`sync.conflict`，`profile-sync.md` §5c），且 `bundleGrantOrdinal` / `bundleRedeemedOrdinal` / `cloudRevision` 三者皆不变。
6. 同一 `receiptId` 在首次 verify 之后**任意时间跨度**（含 > 30 天）重复提交，仍回 `deduplicated = true`，序号与 `revision` 与第一次逐位相同。
7. 上行使 `bundleRedeemedOrdinal > bundleGrantOrdinal` ⇒ **接受写入**，记一条告警级台账 + 风控事件（不拒绝，`profile-sync.md` §7a）。

**保证 3 是一条要求，不是一种实现。** 客户端拿到新序号的唯一路径是 verify 应答后强制一次 pull（§3 已定 verify 不内联 profile）。若这次读落在滞后的只读副本上，客户端读到旧序号 ⇒ 判定「无待兑现」⇒ **玩家付了钱、客户端认为没有货可发，且不会再重试**（它已经不觉得自己欠什么）——这是整条链上唯一一个无人重试的失败点，客户端也无从区分「副本滞后」与「verify 其实没成功」。因此它排除「读走可能滞后的只读副本」这一部署形态，或要求该形态附带会话粘滞 / `revision` 下界等待；**具体实现不指定**，跨区域侧的对应约束见 `profile-sync.md` §8。**代价如实记下**：这是本库唯一一条对读路径提出的实现约束，须在栈选型时带上。**明确否决**「后端主动推送新序号给客户端」——新增一条通道与平台推送依赖，而它解决的问题已被强制 pull 解决。

## 7. `receiptId` 幂等窗口：全局唯一键 + 永久保留

**与 `profile-sync.md` §9 的 `pushId` 窗口不同轴，不沿用它的旋钮。** `pushId` 的 200 条 / 30 天由**客户端待发队列的存活上界**（refresh token TTL）推出；`receiptId` 的存活上界完全不同——客户端的待兑现态跨启动持久化、**无硬超时、永不放弃**，玩家可以卸载、几个月后重装再登录；而平台侧的退款 / 客诉窗口以月计，对账需要按 `receiptId` 回查一次购买的全部历史。

| 旋钮 | 定值 | 推导 |
|---|---|---|
| 唯一键 | **`receiptId` 全局唯一**，不带 `accountId` 前缀 | 「已被其他账号核销」是既定失败面（§3），它要求跨账号可查重；`pushId` 取 `(accountId, pushId)` 是因为那个键由客户端生成、只在账号内有意义 |
| 保留时长 | **永久（不设 TTL）** | 过期代价不对称：`pushId` 过期只降级为一次进度丢失（既定语义已接受），`receiptId` 过期是**重复 `+1`**——第二次提交查不到记录即当作新票，玩家白得一份，且这是发放侧漏洞、线上不可发现。记录体量与购买次数同阶（每账号个位数 / 年），存储成本可忽略 |
| 存储形态 | `receiptId → { accountId, bundleGrantOrdinal, revision, verifiedAtUtc, status }` | 与 `bundleGrantOrdinal` / `cloudRevision` 的写入**同一次事务**——分开写会出现「revision 已 `+1` 但幂等记录未落」，正是重放会重复发放的那一刻。**选型判据、分区与索引、不合表与 TTL 禁用断言见 `operations/purchase-ops.md`** |

**幂等记录的存储选型、分区与冷存归档归 `operations/purchase-ops.md`**，**不回头改契约**。本节只定语义：**永不过期**。那里以三条**选型判据**（同事务写入 · 唯一性由存储层保证 · 读路径受同一条读己所写约束）约束选型，而不是替选型下结论；具体存储产品与事务实现随栈落定。

**对账信号不进本契约。**「`bundleGrantOrdinal > bundleRedeemedOrdinal` 持续超过 N 天」（玩家付了钱但客户端一直没兑现）是有价值的运营信号，落点是 `operations/purchase-ops.md` 的对账任务，**不驱动任何自动写入**——自动补发等于后端具备发放权，与「兑现段客户端演算、后端只复算」正面相悖，只作人工 / 工单入口。**退款同理不回收权益、不回退序号**（保证 4 严格单调不清零；且兑现段产出的条目已写进玩家存档，回收比不发更糟）；退款态记在幂等记录的运维侧字段上，**不进 §4 的 `status` 枚举**——客户端对「已退款」没有任何动作可做，下发只会诱导它实现一条不存在的处置。三条渠道的退款 / 撤单对账通道见 `operations/purchase-ops.md`。

## 决策(-> ADR)

- **购买写入只由 verify 端点承担，渠道回调降为对账通道** → ADR 候选，登记于 `decisions/_index.md`。值得固化其依据（回调时序不可控 ⇒ 「已付款但序号未涨」无处排查），否则「用回调直接写库省一次往返」会反复被重新提出。
- **验票请求的判别式发生在请求根，`receipt` 逐渠道成形** → ADR 候选。值得固化其依据（判别属性不得在同一报文里有两个落点），否则「把 `platform` 也塞进 `receipt` 便于就地判别」会被重新提出。
- **微信渠道引入下单端点，但不改变 §2 的写入权威分配** → ADR 候选。值得固化，否则「既然有了下单端点，不如让它也参与写入」会被反复提出。

## 备选方案（已考虑并否决）

- **把购买端点并进 `profile-sync.md`** — 两套相反的承重纪律不能同居一份契约（§1）。
- **平台回调直接写库、不设 verify 端点** — 回调时序不可控，且「已付款未涨序号」无处排查（§2）。**回调保留为对账通道。**
- **让客户端携带 `baseRevision` 走 CAS 提交购买** — 走 CAS 等于承认客户端有权参与决定序号；且客户端此刻的 `baseRevision` 必然落后，只会失败。
- **为购买在 CAS 三分支表加第四分支** — 客户端的时机纪律已在结构上关闭该窗口，加分支等于为一个不可达的情形增加同步模型的复杂度。
- **验票由客户端做、后端事后复算** — 客户端置位 = 客户端有权发货；事后发现不一致时玩家已拿到东西，回收比不发更糟。
- **verify 应答内联新 profile** — 省一个 RTT，却把 profile 的下行形态复制进购买域，两处形态从此要同步演进。
- **在本库复述客户端的时机纪律与兑现流程** — 回链即可；复述会制造第二权威，而客户端那侧才是它的归属。
- **`receiptId` 沿用 `pushId` 的 30 天 TTL**（§7） — 两者的存活上界不同轴；过期后果是重复发放（玩家白得一份），与 `pushId` 过期只降级为一次进度丢失不是同一量级。
- **后端在 `grant > redeemed` 超时后自动补发**（§7） — 等于后端具备发放权，与「兑现段客户端演算、后端只复算」正面相悖；对账信号归 `operations/`，只作人工入口。
- **把「读己所写」留作客户端的轮询纪律**（读到旧序号时重试 N 次）（§6） — 把一条可验收的服务端保证换成一条客户端纪律，且客户端无法区分「副本滞后」与「verify 未成功」。
- **后端主动推送新序号给客户端**（§6） — 新增一条通道与平台推送依赖，而强制 pull 已解决同一问题。
- **把 `receipt` 定义为不透明字符串**（base64 / 原样 JSON 串）（§3） — 三渠道的必填性全部退化为运行时判断，「形态由 spec 单点承载」对本域名存实亡。
- **把 `platform` 复制进 `receipt` 内部以便就地判别**（§3） — 同一事实两个落点，两者不等时报文层无从裁决。
- **三个渠道各开一个 verify 端点**（§3） — 写入路径、事务语义与七条服务端保证三倍复制，而它们对渠道无差别。
- **接收并信任 Google 的 `originalJson` + `signature` 本地校验**（§3a） — 把客户端提交的 JSON 变成事实来源，与 §2「不信客户端自述」正面相悖。
- **信任客户端提交的 `transactionId` / 微信 `errCode`**（§3a） — 二者皆可伪造，且微信侧还会在支付成功后丢失。
- **为「平台不可达」新造 `purchase.channel_unavailable`**（§3） — 与 `server.unavailable` 的客户端处置逐字相同，多一行映射表换零收益。
- **把 `purchase.receipt_pending` 并入 `server.unavailable`**（§3） — 探针无法区分「我方故障」与「玩家用了慢速支付」，而这两条曲线一个叫人、一个不叫人。
- **按无效成因细分出多个 `code`**（§3） — 客户端处置逐字相同，处置表多十行走同一条路径。
- **渠道未开通复用 `purchase.receipt_invalid`**（§3b） — 会对一个从未付款的玩家呈现「收据无效 + 客服入口」，并让线上「无效收据」曲线被未开通渠道的调用污染。
- **`receiptId` 超长时截断或改存哈希**（§3a） — 截断破坏唯一性；哈希使 `receiptId` 不再可由渠道值直接反查，抬高客服排障成本。
- **做成三渠道统一的下单端点**（§3b） — 商店渠道的 `receiptId` 只在购买之后存在，预分配不成立；空转步骤只增加可失败的往返。
- **让下单端点也参与权益写入**（§3b） — 与 §2 的写入权威分配正面相悖：写入面一旦有两个入口，「已付款但序号未涨」就重新变得无处排查。
- **退款回收权益 / 回退 `bundleGrantOrdinal`**（§7） — 与保证 4「严格单调不清零」直接冲突，且条目已写进玩家存档，回收比不发更糟。
- **把「已退款」加进 §4 的 `status` 枚举**（§7） — 三值已封定，且客户端对它没有任何动作可做，下发只会诱导实现一条不存在的处置。

## Open questions

- **幂等记录的存储产品选型与事务实现** —— 判据、分区与索引、不合表与 TTL 禁用断言已落 `operations/purchase-ops.md`；余下的「用哪个存储、事务域怎么划」随后端栈落定，归 `06-platform-stack.md`，**不回头改契约**（与 `profile-sync.md` §12 同一条处置）。§7 的语义（永不过期）本身不依赖选型。

Source: `handoffs/2026-08-16-purchase-contract-and-cross-boundary-ledger.md` · `handoffs/2026-08-16c-compliance-contract-and-session-arbitration.md`（§3 的失败面：verify 不返回 `compliance.*`）· `handoffs/2026-08-22-entitlement-echo-and-receipt-idempotency.md`（§3 渠道取值域 · §4 与 §6 读己所写 · §5 判据 · §7 收据幂等窗口）· `handoffs/2026-09-03-purchase-channel-integration.md`（§1 三端点 · §3 判别式与失败面 · §3a 逐渠道形态与 `receiptId` 取值 · §3b 下单端点 · §6 保证 3 覆盖面 · §7 回链）。
