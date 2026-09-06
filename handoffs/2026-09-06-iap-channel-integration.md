# 平台内购 SDK 选型与封装层（唤起段收口）

- id: 2026-09-06-iap-channel-integration
- date: 2026-09-06
- topic: systems/monetization · systems/services/sync-service · systems/architecture（总则 7）· ux/screen-flow · vision/scope
- status: distilled
- distilled-to: `systems/monetization.md`（SDK 选型方向表 + 前置条件表第 5 行）、`systems/services/sync-service.md`（「购买段的两条腿」：`StoreChannelManager` / `IStoreChannel` / `IPurchaseBackend`）、`systems/architecture.md`（总则 7 四接口 · 条件编译清单 6 处 · `StorePlatform` 等共享类型登记）、`system-overview.md`（第四节与目录树）、`decisions/ADR-0011`、`decisions/ADR-0023`、`decisions/ADR-0024`、`ux/screen-flow.md`、`ux/error-and-blocking-ux.md`、`vision/scope.md`（iOS 部署下限 15）、`systems/services/_index.md`、`answer-logs/log-iap-channel-integration.md`
- counterpart: `backend-design-documents/handoffs/2026-09-06-iap-channel-integration.md`（后端半：凭据托管形态 + 补查 `Rejected` 原因取值，同批落笔、互相回链）

## Intent（distilled）

三渠道（Google Play Billing · App Store · 微信支付）是客户端唯一必须引入第三方 SDK 的地方；`systems/monetization.md` 此前把「唤起内购」整段排除。本次补齐唤起段的设计形态（停在设计层，导出配置与各平台构建归实现蓝图），购买段的其余硬前提（后端权威 · 兑现段客户端演算 · 报文权威在对侧 · 四种失败情形与待兑现态联动 · Apple `finish()` 显式步骤 · 微信先下单 · 唤起失败回主菜单无痕迹 · 首版 GP + AS、微信随资质开）全部不重开。

### 一、SDK 选型方向（版本假设注记，接入时以官方文档核实）

- **Google Play**：Billing Library 7.x，经 Godot 4 Android 插件接入；官方插件滞后于 Billing 大版本 → 以其为骨架**自维护 fork 升级**。客户端不调用 consume / acknowledge（后端在 `+1` 事务后发起）。
- **App Store**：**StoreKit 2 自写 Swift 插件**——官方 godot-ios-plugins 是 StoreKit 1、拿不到契约要求的 JWS，必须自写；**iOS 部署下限因此为 15**（本方案带出的唯一新平台约束，进 `vision/scope.md`）。
- **微信支付**：WeChat OpenSDK 自写插件包一层 `WXApi`；`errCode` 不作判据，凭据是下单端点预取的 `outTradeNo`；插件随资质开通整体后置。原生层按平台一个 WeChat 插件、封装接口按职责切分（支付 / 登录两条职责不合并）。

### 二、封装层：sync-service 增 `StoreChannelManager`，持窄接口 `IStoreChannel`；实现选择走运行时探测

- 不新开服务、否决放 account-service（共用微信 SDK 是原生打包层事实，不构成职责归属）。
- `IStoreChannel { Platform, PurchaseAsync(productId, order?, ct), FinishAsync(transactionToken, ct) }`；`FinishAsync` 返回非泛型 `OpResult`（共享类型无 `Unit`），把「Apple `finish()` 是流程内显式步骤」落成接口方法。
- **运行时探测 + `UnavailableStoreChannel` 兜底，不走 `#if`**——渠道可用性是运行时事实（无 Play 服务的设备也会缺插件），失败路径闭合到既定「唤起失败回主菜单、无痕迹」。
- `ChannelReceipt` / `ChannelOrderParams` / `StorePlatform`（成员名与契约 `platform` 三值逐字相同，两侧同批冻结）登记进共享核心类型；**凭据字段一律回链对侧 `purchase.md` §3a，本库不另立取值表**。

### 三、后端三个 HTTP 调用 = 第四个窄接口 `IPurchaseBackend`（清单 5 → 6 的兑现）

`IPurchaseBackend { VerifyPurchaseAsync / CreateOrderAsync / GetReceiptAsync }`，宿主 sync-service；`BackendSelector` 增 `CreatePurchase()`；`OfflinePurchaseBackend` 整类 `#if DEBUG`（条件编译清单第 6 处）；`DebugStoreChannel` 与它同文件同 `#if` 区、不另增位点，且挂 `BackendSelector` 同一选择点——编辑器可离线跑通「唤起 → 验票 → pull → 兑现」全链，「离线后端不得发到线上」的第 1 级防线顺带覆盖。

### 四、边界与非商店平台

- 封装层的终点 = 交出 `ChannelReceipt`，兑现段完全不经封装层；待兑现态进入时刻（商店渠道 = 拿到凭据那一刻、微信 = 下单应答返回 `receiptId` 那一刻）与补查键本地推导（前缀规则单一来源在对侧 §3a）。
- **非商店平台（桌面 / 网页）Store 入口不渲染**：前置条件表加「当前平台存在可用渠道」一行（与「不在主菜单」行同形），不引入「永久灰」语义；各处对该表的计数措辞（「四条」）一并改为不带计数的指代。

## Clarifications

- **后端三个 HTTP 调用挂哪个接口？**（原始草稿子项 2 第三点写「扩展 `IProfileBackend`、不新开第四个接口」，与 `systems/architecture.md` 总则 7 对该形态的显式否决相抵，草稿自检漏报）→ **用户裁决：新增第四个窄接口 `IPurchaseBackend`，条件编译清单 5 → 6**——兑现既有预告、零 ADR 推翻；草稿的「清单不得扩张」论据被清单自身的预告条款消解。**本 handoff 推翻原始草稿的该句**（答复优先级高于原始输入），草稿其余子项零影响。
- **非商店平台的 Store 入口形态**（草稿子项 4 两选项）→ **选 A：入口不渲染**；前置条件表加一行、不引入「永久灰」语义（2026-09-06 批量评审裁决）。
- **对侧 `status` 三值改 PascalCase**（连带知会）→ 客户端枚举 `ReceiptStatus { Unknown, Verified, Rejected }` 成员名与契约取值逐字对位；对侧 §4 补查应答的 `Rejected` 附 `code` 对客户端**处置零新增**（既有映射覆盖），仅知会。
- **标准默认（自动采纳）**：iOS 部署下限 15（契约只收 JWS + StoreKit 1 `verifyReceipt` 已废弃 ⇒ 由既有定案必然推出）· 封装层落 sync-service 的 manager 级（七服务清单既定 + 购买段后端腿归属）· 运行时探测而非 `#if`（渠道可用性是运行时事实）· `FinishAsync` 返回非泛型 `OpResult`（共享类型无 `Unit`）· 计数措辞去计数（「不带计数指代会扩员的清单」既有先例）· 微信取消支付的残留本地态不需要新机制（正确性由 `/entitlement` 两字段之差承载）· `StorePlatform` 成员名与契约三值逐字相同（`envelope.md` §2 纪律的兑现时点）。

## Open questions

（无——唤起段范围内无用户当下答不出的远期未知。微信开放平台资质仍在对侧 `06-platform-stack.md`，是渠道实现排期的外部依赖，不属本 handoff 新增。）

## Notes / triage

- 路由：SDK 选型方向与前置条件表 → `systems/monetization.md`；封装层与后端接口形态 → `systems/services/sync-service.md`；清单 6 处与共享类型 → `systems/architecture.md` + `system-overview.md` + 三份 ADR 的对应行；入口呈现 → `ux/screen-flow.md` + `ux/error-and-blocking-ux.md`；平台约束 → `vision/scope.md`。
- 答结移出：`open-questions/07-codex-monetization.md` 的「平台内购 SDK 的选型与封装层」条 → `answer-logs/log-iap-channel-integration.md`；`systems/monetization.md` 待决问题区的同名条目同批删除。
- 跨库成对：后端半（凭据托管形态 + `Rejected` 原因取值）见 counterpart handoff，两侧同批采纳、互相回链，每侧只写归属判据判给它的那一半。
