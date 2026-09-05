# 三渠道验票接入面与收据幂等的实现要求

- id: 2026-09-03-purchase-channel-integration
- date: 2026-09-03
- topic: contracts/purchase · operations/purchase-ops · decisions/ADR-0007
- status: distilled
- distilled-to: `contracts/purchase.md`、`operations/purchase-ops.md`（新建）、`decisions/ADR-0007-purchase-write-authority.md`（连带条款一行）

## Intent（distilled）

`contracts/purchase.md` 的报文骨架、权威分配、幂等语义与七条服务端保证早已封定，两处却一直是空的：`receipt` 字段的内部形态（原文只写「随各渠道接入落笔」）与 verify 失败面的具体 `code`。这两样缺席使后端 FR 强制要求的 `## Failure & retry semantics` 无从写起——它不可切、不可留空。第二处是 `receiptId` 幂等记录的实现：语义已定（全局唯一 · 永久保留 · 与序号同事务），但存储判据、分区、归档与对账信号全部悬着。

本次把这两处填上，渠道本身不重开选型（三家，`platform` 取值域封闭）。

### 一、验票请求成为以 `platform` 为判别式的三分支联合

`VerifyRequest` 定义为 `oneOf` 三分支，判别式**在请求根**而非 `receipt` 内部：`platform` 已是 `receipt` 的兄弟字段，而 `discriminator` 要求判别属性出现在每个子 schema 内——复制进去就是同一事实的两个落点，两者不等时报文层无从裁决。判别提到根则一处判别、一处校验，必填性可被 schema 层校验，缺字段直接落 `purchase.payload_invalid`。新增第四条渠道 = 新增一个分支 + 一个枚举值，对老客户端是纯追加，`info.version` bump minor。

### 二、三张逐渠道字段表，都很窄

贯穿三表的一条纪律：**客户端提交的一切只作「去哪里查」的索引，不作判据**，权威状态一律由后端向渠道服务器查询取得。

- `GooglePlay`：`purchaseToken` + `productId` 必填，`orderId` 仅进日志。不收 `originalJson` / `signature`，`packageName` 取自身配置。商品配置为 consumable，**acknowledge / consume 只在 `+1` 事务提交后由后端发起**，失败进补偿队列。
- `AppStore`：`signedTransaction`（JWS）必填，`transactionId` 只作路由与日志，后端只信 JWS 内解出的值。`environment` 校验是承重项而非可选加固。`finish()` 的时机只能落在客户端。
- `WeChatPay`：只有 `outTradeNo`，因为微信侧不存在「平台发给客户端的收据」，权威状态只能由商户后台查单取得。客户端 SDK 的 `errCode` 不作任何判据。本渠道特有的必查四项含**订单归属**——另两家的收据自带应用绑定，微信的订单号由我方分配，绑定关系只能自查。

`receiptId` 取值统一为渠道前缀 + 渠道 id（`gp_` / `as_` / `wx_`），使三家 id 空间不相撞成为可证的；字符集限制在路径段免转义的范围内。

### 三、四条 `code` + 第五条渠道未开通

`purchase.receipt_invalid` / `receipt_claimed` / `receipt_pending` / `payload_invalid`，另加 `purchase.channel_disabled`。平台不可达复用 `server.unavailable`、不新造渠道码；`receipt_pending` 与 `server.unavailable` 必须分列（一个是我方故障、一个是玩家用了慢速支付，两条曲线一个叫人一个不叫人）；无效成因不细分（客户端处置逐字相同）。逐渠道的原始情形 → `code` 映射三张表落进契约 §3a。

### 四、微信渠道需要一个下单端点

微信支付 APP 支付的下单必须由商户后台发起（需商户私钥签名），客户端无从自行取得支付参数 ⇒ 端点集由两个变三个，新增 `POST /v1/purchase/order`。它**只对需商户侧下单的渠道存在**，不做成三渠道统一下单（商店渠道的 `receiptId` 只在购买之后才存在，预分配不成立）。它**不写入 `bundleGrantOrdinal`**，只创建订单并预落一条 `status = unknown` 的幂等记录——这也把 `unknown` 从理论值变成微信渠道的常规态，并使读己所写这条保证多了一个受约束的写入点。未支付订单只标关单、**记录不删**。

### 五、幂等记录：给判据与断言，不给选型

三条选型判据（同事务写入 · 唯一性由存储层保证 · 读路径受同一条读己所写约束）+ 哈希分区与一条 `(accountId, verifiedAtUtc)` 二级索引 + 「与 `(accountId, pushId)` 记录可同系统、不可合表」+ **显式关闭 TTL 并在配置层留断言** + 冷存归档的三项触发条件与「唯一性索引永不归档」。存储产品与事务实现随后端栈落定，本次只写要求。

对账信号两条（`grant > redeemed` 持续 3 天 · 差值 ≥ 2 立即）+ 渠道对账日频，全部只作人工 / 工单入口。退款一律不回收权益、不回退序号，退款态记在运维侧字段、不进 `status` 枚举。

## Clarifications

- **`ADR-0007` 的连带条款与微信 `receiptId` 由后端分配相抵，以哪一侧为准？** → **同批改写该 ADR 的那一行**：「幂等键不由客户端生成；两家商店渠道取平台发放的 id，微信渠道取后端在下单时分配的商户订单号」。承重意图是「不由客户端生成」（防篡改），「由平台发放」只是另两家的事实描述被写进了理由句。写入权威分配 / 回调只作对账 / 同事务自增 / 不走 CAS / 补查通道五条逐字不变，决策本体与全部备选方案一字不动。（推翻 `ADR-0007` 中「幂等键取平台收据 id」这半句。）
- **四条新 `code` 的 `OpError` 列填什么？** → **新增 `OpError.Purchase`**；`purchase.payload_invalid` 仍映 `Validation`（它确实是 bug 面），另三条映 `Purchase`。客户端现有八个成员没有一个承载购买失败面，而把玩家面的终态失败映进 `Validation` 会让客户端走上报路径、不出客服入口，映进 `Conflict` 更会把一次验票失败变成一次进度丢失。客户端侧的承接（新增成员 + 三条映射）在 `game-design-documents/` 侧同批登记，本库不代为决定。（细化原始草稿「待客户端确认，退化映射 `Validation`」那一句。）
- **微信「首版不实现」在报文层面用哪个 `code`？** → **新增第五条 `purchase.channel_disabled`（`Fatal`）**，与 `receipt_invalid` 分列。未开通发生在下单、玩家尚未付款，不应出「收据无效 + 客服入口」，探针曲线也不该被未开通渠道的调用污染。微信开通时只删实现分支，契约面零变更。（细化原始草稿「调用即返回 `purchase.receipt_invalid`」那一句。）
- **收据幂等记录的存储要写到哪一层？** → **只写判据与断言并回链**，具体存储产品 / 实例形态 / 事务实现归后端栈那一侧落笔。判据本就是选型的输入，写在购买域是它的正确归属。
- **标准默认（自动采纳）：** `receiptId` 长度上界由 256 放宽到 **1024**，且**不截断、不哈希**——Google 的 `purchaseToken` 常见即数百字符且无稳定上界，上界过紧会让 schema 拒收一张已付款的真票，玩家永远卡在阻塞重试态；截断破坏唯一性，哈希抬高客服排障成本。 · 新端点**需鉴权**（`envelope.md` §4a 的免鉴权判据不成立，下单发生在已登录的商店屏）。 · 判别式放在请求根（`auth.md` §3 的 `credential` 分形同构）。 · 平台不可达复用 `server.unavailable`（`auth.md` §3a 先例）。 · 无效成因不细分（§6 台账 `restricted` / `banned` 同判据）。 · 退款不回收权益、「已退款」不进 `status` 枚举（保证 4 + `ADR-0013` 相加即得）。 · acknowledge / consume 只在 `+1` 事务后由后端发起。 · 首版不做冷存归档、只留三项触发条件。 · 幂等记录永久保留、显式关闭 TTL。

## 用户已裁决的取向（原草稿评审）

- **首版 Google Play + App Store，微信随资质开。** `platform` 取值域**不变**（仍封闭为三值），微信分支先不实现——`auth.md` §3「不实现 ≠ 从契约删除」逐字适用，删掉再加回是破坏性契约变更。这只决定实现排期。
- **退款仅记账 + 工单，不做自动处置。** 不为退款开一条后端自动写入路径——那会让「后端不具备发放权」这条纪律出现第一个例外。

## Open questions

- **幂等记录的存储产品选型与事务实现** —— 判据、分区、索引与 TTL 断言已落 `operations/purchase-ops.md`；用哪个存储、事务域怎么划随后端栈落定，归 `open-questions/06-platform-stack.md`。
- **渠道验票凭据的具体托管形态**（KMS / 密钥托管服务）—— 同上，随栈落定。轮换特征与「三把钥匙不共用托管配置」已落笔。

## 客户端侧影响

本 handoff 改动客户端 ↔ 后端边界的报文面，客户端侧有四项承接（**本库不代为决定，只登记；对侧落笔与裁决在 `game-design-documents/` 侧**）：

1. **`OpError` 新增 `Purchase` 成员 + 三条 `code → (OpError, 处置)` 映射**（第四条 `purchase.payload_invalid` 映既有的 `Validation`，第五条 `purchase.channel_disabled` 映 `Purchase`）。受影响成分：`sync-service` / `account-service` 的错误映射表。
2. **`purchase.receipt_pending` 的长等待 UX**：Google 的慢速支付可 pending 数小时至数日，而客户端购后是全屏模态阻塞、无硬超时永不放弃。「钱还没扣、请稍后回来」与「已付款正在发放」是两句不同的话。本库只保证二者在报文层可区分（`code` 不同），呈现形态归客户端。
3. **Apple `finish()` 的调用时机**：只能在 verify 成功或 `deduplicated = true` 之后。Apple 侧无服务端 finish 接口，动作只能落在客户端。
4. **微信渠道的购买流程多一步下单**：客户端须在唤起支付前先调 `POST /v1/purchase/order`，并把应答里的 `receiptId` 随待兑现态持久化。因首版微信不开通，这一条不阻塞上线。
