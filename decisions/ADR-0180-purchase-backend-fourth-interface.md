# ADR-0180 — 购买域的后端调用独立为第四个窄接口 `IPurchaseBackend`，条件编译清单扩至 6 处

- **状态：** Accepted
- **日期：** 2026-09-06
- **来源：** handoffs/2026-09-06-iap-channel-integration.md · answer-logs/log-iap-channel-integration.md

## 背景

购买段有三个 HTTP 调用（verify / order / receipt）。草稿提议把它们挂进既有的 `IProfileBackend`——但 `systems/architecture.md` 早已预告过 `IPurchaseBackend` 并**点名否决**了扩展 `IProfileBackend` 这条路；草稿的「张力：无」属漏检。

## 决策

**verify / order / receipt 三个 HTTP 调用走 sync-service 持有的第四个窄接口 `IPurchaseBackend`**，不挂进 `IProfileBackend`。

**`OfflinePurchaseBackend` 整类 `#if DEBUG`，成为条件编译清单的第 6 处**（清单 5 → 6）；`DebugStoreChannel` 同文件同区，**不另增位点**。

接口签名与三个方法的失败语义 → `systems/architecture.md`、`systems/services/sync-service.md`。

## 理由

- **「档案同步」与「支付」是两个语义无关的边界**——`IProfileBackend` 的每个方法都读写玩家档案，而验票不碰档案；把它们并进一个接口，离线实现就要同时伪造两类语义无关的行为。
- **这是兑现既有预告，不是新决定**：`systems/architecture.md` 的总则 7 早已写明会有第四个窄接口并否决了扩展路径，本条只是把预告改写为当前事实。
- **条件编译清单显式加一处而非悄悄增加**：清单本身是纪律（每一处 `#if DEBUG` 都要能被数出来），加一处必须同批改数。

## 备选方案

- **扩展 `IProfileBackend`**（草稿原案） — 否决：与 `systems/architecture.md` 总则 7 的显式否决相抵；本条明写推翻草稿该句。
- **`DebugStoreChannel` 单列为第 7 处** — 否决：同文件同区，不构成独立位点。

## 后果

- **条件编译清单从 5 处变为 6 处**，`decisions/ADR-0011` / `ADR-0023` / `ADR-0024` 三处预告行同批改为当前事实。
- **离线 stub 完整**：`OfflinePurchaseBackend` + `DebugStoreChannel` 使购买链在后端就绪前可端到端跑通。
- 受约束的文档：`systems/services/sync-service.md` · `systems/architecture.md` · `system-overview.md` · `decisions/ADR-0011-api-contract-principles.md` · `decisions/ADR-0023-premium-entitlement-and-redemption.md` · `decisions/ADR-0024-in-app-purchase-channels-in-mvp.md`。
