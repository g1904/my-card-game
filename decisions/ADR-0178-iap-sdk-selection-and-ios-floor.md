# ADR-0178 — 三渠道内购 SDK 选型：一律自维护插件，iOS 走 StoreKit 2 且部署下限 15

- **状态：** Accepted
- **日期：** 2026-09-06
- **来源：** handoffs/2026-09-06-iap-channel-integration.md · answer-logs/log-iap-channel-integration.md

## 背景

平台内购三渠道纳入 MVP（`ADR-0024`），但「用什么接」一直悬着——它是当时唯一未定的跨边界依赖，卡着 `monetization.md` 的唤起内购整段。Godot 侧的现成选项都不干净：官方 iOS 插件的 in-app-store 部分仍是 StoreKit 1，而验票契约收的是 JWS。

## 决策

**三渠道选型方向：**

- **Google Play** — Play Billing 7.x，以官方插件为骨架**自维护 fork**。
- **App Store** — **StoreKit 2，自写 Swift iOS 插件**。
- **微信** — OpenSDK 自写插件；`errCode` **不作判据**，随资质后置。

**连带定案：iOS 部署下限 15**（StoreKit 2 的硬下限）。

选型方向表与逐渠道的具体理由 → `systems/monetization.md`；平台下限 → `vision/scope.md`。

## 理由

- **官方 `godot-ios-plugins` 的 in-app-store 插件是 StoreKit 1，拿不到 JWS**——而验票契约只收 JWS。用它就要改契约去迁就一条已被 Apple 废弃的路径（`verifyReceipt` 已废弃）。
- **自维护而非原样接入**：上游插件滞后于渠道 SDK 的版本节奏，而支付是不能等上游的一条链。
- **`errCode` 不作判据**：微信侧的错误码语义不稳定且与资质状态耦合，把它写进判据等于把客户端逻辑挂在一个会变的外部约定上。

## 备选方案

- **依赖官方 / 上游插件原样接入** — 否决：上游滞后，且 StoreKit 1 拿不到 JWS。
- **iOS 走 StoreKit 1 + 收据文件以兼容 iOS 15 以下** — 否决：`verifyReceipt` 已废弃，等于改契约迁就废弃路径。

## 后果

- **iOS 15 以下不在支持范围**——`vision/scope.md` 的平台矩阵因此收窄，是为选型付的价。
- **三个插件工程都要自己维护**，包括跟随渠道 SDK 的版本升级；这条成本如实写下。
- **T3 触发条件当场命中**：本条一旦落地实现，就是「首次为移动端引入自有原生插件」——`ADR-0160` 的平台密钥库评估须在同批给出结论。
- 受约束的文档：`systems/monetization.md` · `vision/scope.md` · `decisions/ADR-0024-in-app-purchase-channels-in-mvp.md` · `backend-design-documents/contracts/purchase.md`（验票契约收 JWS，权威在对侧）。
