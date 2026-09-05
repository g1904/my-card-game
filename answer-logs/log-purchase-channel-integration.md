# Answer log purchase-channel-integration

- 日期：2026-09-03
- 来源：`inbox/archive/solution-draft-purchase-channel-integration.md` → `handoffs/2026-09-03-purchase-channel-integration.md`
- 移出条数：2（**均为部分移出**，两条各留一半在 `open-questions/06-platform-stack.md`）

## 逐条

**平台内购三渠道的接入形态（三家的 `receipt` 内部形态与平台错误码映射、服务端验票凭据、退款与撤单的对账通道）** → **答定**：验票请求定义为以 `platform` 为判别式的三分支联合（判别式在请求根，不在 `receipt` 内部）；三张逐渠道字段表（`GooglePlay` 三字段 / `AppStore` 两字段 / `WeChatPay` 一字段）与「客户端提交的一切只作索引、不作判据」这条贯穿纪律；`receiptId` 取值统一为渠道前缀 + 渠道 id，字符集限路径段免转义、长度上界 1024 且不截断不哈希；平台错误码归一为**五条新 `code`**（`purchase.receipt_invalid` / `receipt_claimed` / `receipt_pending` / `payload_invalid` / `channel_disabled`）+ 平台不可达复用 `server.unavailable`，逐渠道原始情形 → `code` 的三张映射表；三渠道验票凭据的形态与轮换特征、「三把钥匙三套轮换窗口不共用托管配置」、环境隔离以部署配置为准；三条退款 / 撤单对账通道与「推送只作更快知道、周期性拉取才是正确性来源」。（归档去向：`contracts/purchase.md` §3 · **新增 §3a** · **新增 §3b** · 失败面表 · 备选方案十四条；`operations/purchase-ops.md` §1 §2）

**`receiptId` 幂等记录的存储与冷存归档（含对账信号落点与阈值）** → **部分答定**：三条选型判据 S1 / S2 / S3 及 S1 不可满足时的 `receiptClaim` + `receiptRecord` 退化形态（悬挂 claim 回收阈值初值 10 分钟）；按 `receiptId` 哈希分区、否决在线时间分区、一条 `(accountId, verifiedAtUtc)` 二级索引；与 `(accountId, pushId)` 记录**可同系统、不可合表**，且收据表须**显式关闭 TTL 并在配置层留一条断言**（误配置 = 线上不可发现的重复发放漏洞）；冷存归档首版不做、三项触发条件（5,000 万行 / 50 GB / 点查 p99 20 ms 持续 7 天，均待实测校准）与「唯一性索引永不归档、否决只能顺序扫描的冷介质」；对账信号两条（`grant > redeemed` 持续 3 天 · 差值 ≥ 2 立即）+ 渠道对账日频 + 指标形态（gauge + 持续时长分桶，不做逐账号告警）。（归档去向：`operations/purchase-ops.md` §3 §4；`contracts/purchase.md` §7 的存储形态行回链）

## 同批裁决（interview）

- **`ADR-0007` 连带条款与微信 `receiptId` 由后端分配相抵** → 同批改写该 ADR 的那一行为「幂等键不由客户端生成；两家商店渠道取平台发放的 id，微信渠道取后端在下单时分配的商户订单号」。写入权威分配 / 回调只作对账 / 同事务自增 / 不走 CAS / 补查通道五条逐字不变。
- **四条新 `code` 的 `OpError` 列** → 新增 `OpError.Purchase`；`purchase.payload_invalid` 仍映 `Validation`，另三条映 `Purchase`。客户端侧承接同批在对侧库登记。
- **微信首版未开通的报文表达** → 新增第五条 `purchase.channel_disabled`（`Fatal`），与 `receipt_invalid` 分列。
- **幂等记录的存储写到哪一层** → 本次只写判据与断言并回链，存储选型归后端栈那一侧落笔。

## 仍留在清单上的

- **渠道验票凭据的具体托管形态**（KMS / 密钥托管服务）—— 随后端栈与密钥托管选型落定，与 `06-platform-stack.md` 已有的两把钥匙同处。
- **幂等记录的存储产品选型与事务域实现** —— 三条判据已作为选型输入落笔，选型结论本身随栈落定。

## 跨边界

客户端侧的四项承接（`OpError.Purchase` 成员与映射 · `receipt_pending` 的长等待 UX · Apple `finish()` 时机 · 微信购买流程多一步下单）登记在 `handoffs/2026-09-03-purchase-channel-integration.md` 的「客户端侧影响」，对侧落笔与裁决在 `game-design-documents/` 侧，**本 log 不复述其形态**。
