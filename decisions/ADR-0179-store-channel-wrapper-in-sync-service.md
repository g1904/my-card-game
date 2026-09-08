# ADR-0179 — 购买段渠道封装落 sync-service：`StoreChannelManager` 持 `IStoreChannel`，运行时探测选实现

- **状态：** Accepted
- **日期：** 2026-09-06
- **来源：** handoffs/2026-09-06-iap-channel-integration.md · answer-logs/log-iap-channel-integration.md

## 背景

三渠道 SDK 选型落定后，随之而来的是归属问题：平台商店 SDK 的调用（拉起支付、完成交易）由哪个服务持有。微信 OpenSDK 同时被登录与支付使用，这个事实很容易被读成「支付该归 account-service」。

## 决策

**购买段的渠道封装落 sync-service，形态 = `StoreChannelManager` 持一个窄接口 `IStoreChannel`**（`Platform` / `PurchaseAsync` / `FinishAsync`，返回**非泛型** `OpResult`）。

**实现选择 = 运行时探测，不走 `#if`**：插件缺席 → `UnavailableStoreChannel` 兜底。

**`ChannelReceipt` / `ChannelOrderParams` / `StorePlatform` 登记进共享核心类型**，取值**一律回链对侧契约、不另立取值表**。

接口定义、失败路径与逐渠道的实现挂载 → `systems/services/sync-service.md`。

## 理由

- **共用微信 SDK 是原生打包层的事实，不构成职责归属**——账号与支付是两个语义无关的边界，共用一个第三方 SDK 不能让它们变成同一件事。
- **归 sync-service** 是因为购买的另一半（后端验票与凭证下行）本就在这条同步链上；把渠道调用放在别处会让一次购买跨两个服务编排。
- **运行时探测而非 `#if`**：与 `ADR-0160` 的凭据存储、与 `BackendSelector` 是同一条纪律——**唯一选择点 + 换实现而非插 `if`**；`UnavailableStoreChannel` 让「这台设备没有可用渠道」成为一条正常路径而不是编译期缺失。
- **不另立取值表**：`ChannelReceipt` 的字段取值权威在对侧 `contracts/purchase.md`，本库复制一份即制造第二权威。

## 备选方案

- **新开一个 purchase 服务** — 否决：七服务边界按生命周期层 + 行为边界拆分（`ADR-0008`），购买不构成第八条。
- **放 account-service** — 否决：共用微信 SDK 是打包层事实，不构成职责归属。
- **用 `#if` 按平台选实现** — 否决：把平台差异抬到编译期，且与两处既有的运行时探测纪律相抵。

## 后果

- **`StoreChannelManager` 进 sync-service 的 manager 清单**，`StorePlatform` 进 `systems/architecture.md` 的共享核心类型。
- **桌面 / 网页上 `UnavailableStoreChannel` 是常态实现**，不是错误态——它与 `ADR-0181` 的「入口不渲染」是同一件事的两端。
- 受约束的文档：`systems/services/sync-service.md` · `systems/services/_index.md` · `systems/architecture.md` · `system-overview.md` · `backend-design-documents/contracts/purchase.md`（取值权威）。
