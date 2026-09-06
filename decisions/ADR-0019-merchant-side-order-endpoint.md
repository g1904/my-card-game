# ADR-0019 — 微信渠道引入下单端点，但写入权威分配逐字不变

- **状态：** Accepted
- **日期：** 2026-09-03
- **来源：** `handoffs/2026-09-03-purchase-channel-integration.md` · `answer-logs/log-purchase-channel-integration.md`

## 背景

微信支付的形态与两家商店**结构不同**：不存在「平台发给客户端的收据」，权威状态只能由商户后台以商户订单号 `outTradeNo` 查单取得，而那个订单号必须由我方在支付发起前分配。购买域原本只有两个端点（verify + 收据补查），微信渠道因此逼出第三个。而端点集一旦扩张，「既然有了下单端点，不如让它也参与写入」就会被反复提出——那正是 `ADR-0007` 用一条竞态论证关掉的门。

## 决策

**新增 `POST /v1/purchase/order`，只对「需商户侧下单」的渠道存在（当前仅 `WeChatPay`）；它创建订单、下发 `receiptId` 与 `channelOrderParams`、预落一条 `status = Unknown` 的幂等记录，但绝不写入 `bundleGrantOrdinal`——`ADR-0007` 的权威分配逐字不变。**

- **不做成三渠道统一下单端点。**
- 该端点**需鉴权**（下单发生在已登录的商店屏，不够格走 `envelope.md` §4a 的免鉴权判据）。
- 渠道未开通回 `purchase.channel_disabled`（`Fatal`），**不复用 `receipt_invalid`**。
- **预落的 `Unknown` 记录不删**；订单有效期后仍未转 `Verified` 的，由对账任务标记关单（运维侧字段）。
- 报文、`channelOrderParams` 形态与滥用阈值 → `contracts/purchase.md` §3b、`operations/purchase-ops.md`。

## 理由

**统一下单不成立：商店渠道的订单由平台自己创建，其 `receiptId` 只在购买之后才存在，预分配不成立**——硬造一个空转步骤只会给两条渠道各多一次可失败的往返（`contracts/purchase.md` §3b）。

**写入权威不放松，理由与 `ADR-0007` 同源：写入面一旦有两个入口，「已付款但序号未涨」就重新变得无处排查。** 下单端点持有的是订单，不是权益。

`channel_disabled` 不复用 `receipt_invalid`，因为未开通发生在下单、玩家**尚未付款**：对他呈现「收据无效 + 客服入口」是错的话，且会让线上「无效收据」曲线被未开通渠道的调用污染。

`Unknown` 记录不删，理由与 `ADR-0013` 拒绝给 `receiptId` 设 TTL 同一条：**删除会让同一 `outTradeNo` 的迟到查询查不到记录**。

## 备选方案

- **做成三渠道统一的下单端点** — 商店渠道的 `receiptId` 只在购买之后存在，预分配不成立；空转步骤只增加可失败的往返。
- **让下单端点也参与权益写入** — 与 `ADR-0007` 的写入权威分配正面相悖：写入面有两个入口，「已付款但序号未涨」重新无处排查。
- **渠道未开通复用 `purchase.receipt_invalid`** — 会对一个从未付款的玩家呈现「收据无效 + 客服入口」，并污染线上「无效收据」曲线。
- **删除未支付的预落记录** — 同一 `outTradeNo` 的迟到查询查不到记录，正是 `ADR-0013` 拒绝设 TTL 所要堵的那条路径。

## 后果

- 购买域端点集为**三个**，其中第三个是**渠道条件性的**——`contracts/purchase.md` §1 必须写清它的存在条件，而不是把它当作通用步骤。
- `GET /v1/purchase/receipt/{receiptId}` 的 `Unknown` 态由理论值变成微信渠道的**常规态**；`ADR-0013` 的读己所写因此**同时覆盖预落记录**：下单应答返回之后 `GET /receipt/{receiptId}` 必须立即读到它，否则客户端在阻塞态下读到「不存在」，与「下单失败」不可区分（`contracts/purchase.md` §6 保证 3）。
- 客户端须把下单应答里的 `receiptId` **随待兑现态一并持久化**——它是补查的唯一入口；客户端侧形态权威在 `game-design-documents/systems/monetization.md`。
- 渠道开通时只需删掉实现分支，**契约面零变更**。
- 渠道凭据托管与滥用阈值落 `operations/purchase-ops.md`，不回头改契约。
