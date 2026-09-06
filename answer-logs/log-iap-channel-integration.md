# Answer log iap-channel-integration

- 日期：2026-09-06
- 来源：`inbox/solution-draft-iap-channel-integration.md` → `handoffs/2026-09-06-iap-channel-integration.md`
- 移出条数：1

## 逐条

**平台内购 SDK 的选型与封装层（07 分片）** → **答定**：Google Play = Billing Library 7.x 经 Godot 4 Android 插件、以官方插件为骨架自维护 fork；App Store = StoreKit 2 自写 Swift 插件（官方插件是 StoreKit 1 拿不到 JWS，**iOS 部署下限因此为 15**，进 `vision/scope.md`）；微信 = OpenSDK 自写插件包一层 `WXApi`、随资质开通整体后置（原生层一个 WeChat 插件、封装接口按支付 / 登录职责切分）。封装层 = sync-service 增 `StoreChannelManager`（manager 级）持窄接口 `IStoreChannel`（`PurchaseAsync` + 非泛型 `OpResult` 的 `FinishAsync`），实现选择走**运行时探测 + `UnavailableStoreChannel` 兜底**、不走 `#if`；`ChannelReceipt` / `ChannelOrderParams` / `StorePlatform` 登记共享核心类型，凭据字段回链对侧 `purchase.md` §3a 不另立表；待兑现态进入时刻与补查键本地推导收口；`DebugStoreChannel` 挂 `BackendSelector` 同一选择点、与 `OfflinePurchaseBackend` 同文件同 `#if DEBUG` 区。（归档去向：`systems/monetization.md`「唤起内购」表 + 前置条件表、`systems/services/sync-service.md`「购买段的两条腿」、`systems/architecture.md` 总则 7、`system-overview.md` 第四节、`vision/scope.md`）

## 同批裁决（合并 interview / 批量评审）

- **🔴 后端三个 HTTP 调用的落形**（草稿「扩展 `IProfileBackend`」与 `architecture.md` 总则 7 的显式否决相抵）→ **选项 B：新增第四个窄接口 `IPurchaseBackend`（`VerifyPurchaseAsync` / `CreateOrderAsync` / `GetReceiptAsync`），条件编译清单 5 → 6**——兑现既有预告、零 ADR 推翻；同批把 `architecture.md` :636/:638、`system-overview.md` 第四节、`ADR-0011` / `ADR-0023` / `ADR-0024` 的对应行改写为当前事实。草稿该句不采纳，handoff Clarifications 已记。
- **非商店平台（桌面 / 网页）的 Store 入口** → **不渲染**（前置条件表加「当前平台存在可用渠道」一行，与「不在主菜单」行同形；不引入「永久灰」语义）；各处「四条」计数措辞同批去计数（`monetization.md` · `ADR-0023` ③ · `ux/screen-flow.md` · `ux/error-and-blocking-ux.md`）。

## 跨边界

后端半（凭据托管形态 = 云 SSM Secrets、补查应答 `Rejected` 附 `code`、`status` 三值 PascalCase）同批落笔于 `backend-design-documents/`，见对侧 `handoffs/2026-09-06-iap-channel-integration.md` 与 `answer-logs/log-iap-channel-integration.md`；本 log 不复述其形态。客户端对 `Rejected` 附 `code` 的处置零新增（既有映射覆盖）。
