---
type: solution-draft
date: 2026-09-06
question: 平台内购 SDK 的选型方向与客户端封装层形态（购买段的「唤起内购」一步——systems/monetization.md 唯一整段排除的部分）
source: open-questions/07-codex-monetization.md → 「平台内购 SDK 的选型与封装层」；systems/monetization.md#待决问题
targets: systems/monetization.md（购买段唤起小节）· systems/services/sync-service.md（StoreChannelManager 与 IProfileBackend 扩展）· ux/screen-flow.md（非商店平台的入口行为）· vision/scope.md（iOS 部署下限，若采纳）
status: distilled
reviewed: 2026-09-06 批量评审——子项 4 裁 A（非商店平台入口不渲染）；interview 追加裁决：后端三 HTTP 调用落新增窄接口 IPurchaseBackend、条件编译清单 5→6（推翻子项 2 的「扩展 IProfileBackend」提议，兑现 architecture.md 既有预告）
distilled-to: handoffs/2026-09-06-iap-channel-integration.md
counterpart: backend-design-documents/inbox/solution-draft-iap-channel-integration.md
---

# 方案草稿 — 平台内购 SDK 选型与封装层（唤起段）

## 问题

三渠道（Google Play Billing · App Store · 微信支付）已纳入 MVP（`vision/scope.md` · `ADR-0024`），是客户端**唯一必须引入第三方 SDK 的地方**，牵动 Godot 导出配置与各平台构建。`systems/monetization.md` 把「唤起内购」整段排除、只写了兑现段与失败处置；`open-questions/07-codex-monetization.md` 明写「**购买段在 SDK 落定前无法落地**」。本草稿只补唤起段的设计形态，停在设计层（不写代码），供后续「一次专门的客户端工程蓝图」消费。

> **硬前提（已定，绝不重开）：** 购买段后端权威 · 兑现段客户端演算（`ADR-0023`）；验票报文、逐渠道 `receipt` 形态与 `receiptId` 取值的权威在 `backend-design-documents/contracts/purchase.md`（本库不复述）；`OpError.Purchase` 只由 `purchase.*` 域映入、不建逐 `code` 表（`ADR-0140`）；四种失败情形的呈现与待兑现态联动、Apple `finish()` 是流程内显式步骤、微信先下单（`systems/monetization.md`）；唤起失败一律回主菜单、无 Profile 变更、无痕迹；首版 Google Play + App Store、微信随资质开（后端 09-03 handoff 中用户已裁决）。

## 约束（来自既有设计）

- **总则 7 —— 后端接口化**：跨进程边界收敛到窄接口 + 双实现；**条件编译清单共 5 处、不得扩张**（`systems/architecture.md`）。任何新增 `#if` 位点的方案在结构上出局。
- **服务清单七个、层级词表 service ⊃ manager ⊃ …**（`systems/services/_index.md` · `ADR-0008`）；两条唯一入口与编排顶点（`ADR-0009`）。
- 购买段的后端腿（购后强制 pull、待兑现态持久化、阻塞重试）已落 `systems/services/sync-service.md`。
- 移动优先 / 触控 / 竖屏；桌面、网页是次要目标（`vision/scope.md`）。
- 灰态判据（置灰 + 说明、不隐藏）与入口前置条件表四条（`systems/monetization.md` · `ux/error-and-blocking-ux.md`）。

## 建议方案

### 子项 1 —— SDK / 插件选型方向（逐渠道）

`[通行做法]`（版本假设如注，**接入时一律以官方文档核实**）

| 渠道 | 选型方向 | 版本假设 | 要点 |
|---|---|---|---|
| Google Play | **Google Play Billing Library**，经 Godot 4 Android 插件（v2 插件系统）接入 | Billing Library **7.x**（Google 对更新提审有最低版本时限，逐年上抬） | 官方 `godot-google-play-billing` 插件历史上滞后于 Billing 大版本 → **以其为骨架自维护 fork 升级**，不把上线押在上游节奏上。产出恰为契约所需的 `purchaseToken` + `productId`。商品配 consumable；**客户端不调用 consume / acknowledge**（后端在 `+1` 事务后发起，对侧已定） |
| App Store | **StoreKit 2**，自写 Swift iOS 插件（静态库 + `.gdip`） | **iOS 15+**（StoreKit 2 的硬下限） | 官方 `godot-ios-plugins` 的 in-app-store 插件是 StoreKit 1（`SKPaymentQueue`），**拿不到 JWS**——契约的 `signedTransaction` 只能由 StoreKit 2 的 `jwsRepresentation` 给出，故不可用、必须自写。插件暴露：购买（回 JWS + `transactionId`）与 `finish()` 两个动作 |
| 微信支付 | **WeChat OpenSDK**（Android / iOS）自写插件包一层 `WXApi` 唤起 APP 支付 | OpenSDK 随接入时取最新 | 产出只有「支付流程已返回」信号——`errCode` 不作判据（对侧已定）；真正的凭据是下单端点预取的 `outTradeNo`。**首版不开通 → 插件可整体后置**，接口分支先占位。注意：微信原生插件将来**同时服务登录（authCode）与支付**——原生层按平台一个 WeChat 插件，封装接口按职责切分（支付走本方案的接口，登录走 account-service 既有渠道形态），不因共用 SDK 而把两条职责塞进一个封装 |

### 子项 2 —— 封装层形态：sync-service 增 `StoreChannelManager`，持窄接口 `IStoreChannel`；实现选择走运行时探测，不走 `#if`

`[既有推演]`（由总则 7 骨架 + 条件编译清单不得扩张 + 拆分轴推出）

- **不新开服务。** 七服务清单是既定结构；唤起段的生命周期归账号级、消费方是 Store 流程，与购买段后端腿（购后 pull、待兑现态）同居 **sync-service** 内聚最高 → 增一个 `internal sealed` manager：`StoreChannelManager`。**否决放 account-service**：它管的是身份与合规，「共用微信 SDK」是原生层事实，不构成职责归属理由。
- **窄接口（调用形状，示意）：**

  ```csharp
  internal interface IStoreChannel
  {
      StorePlatform Platform { get; }
      // order：仅需商户侧下单的渠道非空（微信，来自下单端点应答的 channelOrderParams）
      Task<OpResult<ChannelReceipt>> PurchaseAsync(string productId, ChannelOrderParams? order, CancellationToken ct);
      // 仅 AppStore 有实义（StoreKit finish()）；其余渠道 no-op 成功
      Task<OpResult<Unit>> FinishAsync(string transactionToken, CancellationToken ct);
  }
  ```

  `ChannelReceipt` 是逐渠道凭据的客户端投影（GooglePlay：`purchaseToken` + `productId`；AppStore：`signedTransaction` + `transactionId`；WeChatPay：`outTradeNo` 回带）——**字段与对侧 `purchase.md` §3a 三表逐字对位，取形态一律回链、本库不另立语义**。`FinishAsync` 把「finish() 是流程内显式步骤、不挂 UI 回调」（既定）落成接口上的显式方法。
- **实现选择 = 运行时探测，不是条件编译。** 每渠道一个实现（内部经 `Engine.HasSingleton` / 平台特性探测取原生插件单例）；插件缺席 → `UnavailableStoreChannel`（一律返回失败 → 既定的「唤起失败回主菜单、无痕迹」路径）。**这正是不选 `#if` 的理由：条件编译清单 5 处不得扩张**，而渠道可用性本就是运行时事实（同一份 Android 包在无 Play 服务的设备上也会缺插件）。
- **verify / order / receipt 三个 HTTP 调用：扩展既有 `IProfileBackend` 三个方法**（`VerifyPurchaseAsync` / `CreateOrderAsync` / `GetReceiptAsync`），**不新开第四个后端接口**——新接口意味着新的 `Offline*Backend` 文件，即条件编译清单第 6 处，清单不得扩张；且购买段的后端腿本就归 sync-service。错误映射沿用 `src/Core/` 共享数据表（总则 7 既定），`purchase.*` 域按 `ADR-0140` 映入。
- **开发期端到端：`DebugStoreChannel` 挂在 `BackendSelector` 同一选择点**——选中 Offline 后端时才启用，返回确定性假凭据；`OfflineProfileBackend` 的 verify 分支对任意假凭据 `+1` 序号并回幂等语义。于是编辑器里可以离线跑通「唤起 → 验票 → pull → 兑现」全链，且「离线后端不得发到线上」的既有第 1 级防线**顺带覆盖它**，零新增 `#if` 位点、零新增防线。

### 子项 3 —— 与兑现段 / 待兑现态的边界

`[既有推演]`（`systems/monetization.md` 与 `sync-service.md` 既有语义的收口，不新增机制）

- 封装层的终点 = 交出 `ChannelReceipt`。此后验票、购后强制 pull、兑现循环、`Immediate` push 全部走既有形态，**兑现段完全不经封装层**。
- **待兑现态的进入时刻**：商店渠道 = `PurchaseAsync` 成功返回凭据的那一刻；微信 = 下单应答返回 `receiptId` 的那一刻（既定：`receiptId` 随待兑现态持久化）。此前任何失败（取消 / SDK 错误 / 下单失败）都不进待兑现态——与「唤起失败回主菜单、无痕迹」逐字一致。
- **补查键的本地推导**：商店渠道的 `receiptId` 按对侧 §3a 的前缀规则由本地凭据机械推导（`gp_` + purchaseToken / `as_` + transactionId）随待兑现态持久化，微信取下单应答下发值——**取值规则单一来源在对侧 §3a，客户端不另立取值表**；且既有兜底不变（正确性由 `/entitlement` 两字段之差承载，本地态只是加速补查）。
- `FinishAsync` 的调用点：verify 成功或 `deduplicated = true` 之后、由购买流程显式调用（既定纪律的接口化，无新决策）。

### 子项 4 —— 非商店平台（桌面 / 网页）的 Store 入口

`[取向选择]`（待用户选定）

三渠道全是移动渠道；桌面 / 网页构建上不存在任何可用 `IStoreChannel`。两个选项：

- **选项 A（推荐）：入口不渲染。** 与前置条件 1「不在主菜单 → 入口不渲染」同形；且灰态的既有语义是「暂不可用、会恢复」（等同步完成 / 等发放完成），而桌面上它**永不恢复**，置灰是对灰态判据的语义污染。云端权威使手机购得的权益在桌面照常经 pull 生效，玩家无损失。
- **选项 B：置灰 + 「请在移动端购买」。** 优点是付费点在全平台可见（转化提示）；代价如上——引入一类「永久灰」的新灰态语义，且需要一条新文案与新判据。

推荐 A：既有判据零扩张。若用户在意桌面端的付费可发现性，可在礼包详情不可达的前提下于其他呈现处（穷举三处之内）解决，不必为它松动灰态语义。

## 具体形态（可 derive 的落地面）

- `sync-service` 新增：`StoreChannelManager`（manager 级）· `IStoreChannel` + 三渠道实现 + `UnavailableStoreChannel` + `DebugStoreChannel`；`IProfileBackend` 增三方法。
- 数据类型：`StorePlatform` 枚举（成员名与契约 `platform` 取值逐字相同，`envelope.md` §2 既定）· `ChannelReceipt`（判别式联合的客户端投影）· `ChannelOrderParams`。
- 工程面：Android 自维护 Billing 插件 fork；iOS Swift StoreKit 2 插件（**部署下限 iOS 15**）；微信插件后置。导出配置与各平台构建细节归实现蓝图。
- 前置条件表若采纳选项 A：加一行「当前平台存在可用渠道 → 否则入口不渲染」（往既有表加行，不新增拦截点——闸 ② 并入时的同一先例）。

## 后果

- `systems/monetization.md` 的「唤起内购」排除段可以收口；`open-questions/07-codex-monetization.md` 的 SDK 条目可移出（由 `/analyze-new-ideas` 执行）。
- **iOS 部署下限成为 15**（StoreKit 2 硬要求）——`vision/scope.md` 的平台约束宜补一句；这是本方案带出的唯一新平台约束，如实点出。
- 不改任何存档结构、不 bump `schemaVersion`、不动 `BlockingNoticeKind`；报文面零变更（凭据形态全部回链对侧）。

## 备选方案（已考虑并否决）

- **依赖官方 / 上游插件原样接入**（godot-google-play-billing · godot-ios-plugins in-app-store）— 前者滞后于 Billing 大版本时限，后者是 StoreKit 1、拿不到契约要求的 JWS；把上线押在上游维护节奏上不可接受。
- **iOS 走 StoreKit 1 + 收据文件以兼容 iOS 15 以下** — `verifyReceipt` 已废弃，且契约只收 JWS ⇒ 要改契约来迁就一条被废弃的路径；覆盖率收益可忽略。
- **新开第八个 service（store-service）** — 七服务清单是既定结构；唤起段只有一个 manager 的体量，且它的上下游（下单 / 验票 / 待兑现态）全在 sync-service。
- **封装层放 account-service（因共用微信 SDK）** — 原生插件共用是打包层事实，不构成职责归属；登录与支付两条职责会被塞进一个封装。
- **`IStoreChannel` 做成第四个后端接口（Offline 双实现 + `#if`）** — 条件编译清单 5 处不得扩张；且平台商店不是「客户端 ↔ 后端」边界，运行时探测才是它的正确形态。
- **桌面端接 Steam 等第四渠道** — `platform` 取值域已封闭为三条（对侧 §3），新增渠道是显式的契约追加事件，不在本草稿范围。

## 与既有决策的张力

无。（唯一接近张力的是 iOS 15 下限——`vision/scope.md` 未写过 iOS 版本下限，属新增约束而非冲突，已在「后果」如实列出。）

## 前置依赖

- **微信开放平台资质**（`backend-design-documents/open-questions/06-platform-stack.md`，首个玩家建号前必须完成）——微信渠道实现的排期挂它；不阻塞 GP / AS 两渠道与封装层本体。
- **counterpart 互依**：本草稿的 `ChannelReceipt` 逐渠道字段与 `FinishAsync` 时机，须与 `backend-design-documents/inbox/solution-draft-iap-channel-integration.md` 及对侧 `purchase.md` §3a 既有三表**同批对位采纳**——单侧采纳即两侧不一致。对侧草稿的托管形态半（Secrets / 轮换）对客户端零义务。

## 仍需用户决定

- **非商店平台（桌面 / 网页）的 Store 入口形态**（子项 4）：**A 不渲染（推荐——既有判据零扩张、灰态语义不被污染）** vs B 置灰 + 「请在移动端购买」（付费点全平台可见，但引入「永久灰」新语义）。
  → 已裁决（2026-09-06 · 批量评审）：选 A——非商店平台入口不渲染；前置条件表加「当前平台存在可用渠道」一行，不引入「永久灰」语义。
