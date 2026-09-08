# ADR-0181 — 非商店平台的 Store 入口不渲染，不引入「永久灰」语义

- **状态：** Accepted
- **日期：** 2026-09-06
- **来源：** handoffs/2026-09-06-iap-channel-integration.md · answer-logs/log-iap-channel-integration.md

## 背景

桌面与网页上不存在可用的商店渠道实现（`ADR-0179` 的 `UnavailableStoreChannel` 是那两端的常态）。主菜单的 Store 入口因此需要一个表态：置灰，还是不渲染。此前主菜单的前置条件表里没有这一行。

## 决策

**非商店平台（桌面 / 网页）的 Store 入口不渲染，而非置灰。**

**前置条件表加一行**「当前平台存在可用渠道（运行时探测到可用的商店渠道实现）→ 入口不渲染」。**不引入「永久灰」语义。**

各处对该表的引用改为**不带计数的措辞**。

前置条件表全表 → `systems/monetization.md`；主菜单呈现 → `ux/screen-flow.md`。

## 理由

- **灰态语义是「暂不可用、会恢复」**（`ADR-0142`：灰态是视觉降级而非引擎级禁用，灰格必须继续接收触控并给出说明）。桌面上的 Store 永远不会恢复——把它做成灰格就要给一条「本平台不支持」的说明文案，而那是在为一个不存在的功能占一行主菜单。
- **不渲染是既有前置条件表的标准处置**，本条只是补上遗漏的一行，不新增机制。
- **改为不带计数的措辞**：表的权威在 `systems/monetization.md`，别处写「五条前置条件」会在加行时静默失准——这次正好加了一行。

## 备选方案

- **置灰（永久灰）** — 否决：灰态语义是「会恢复」，引入「永久灰」会让整套灰态判据出现第二种含义。

## 后果

- **`ADR-0142` 的灰态判据不被稀释**——本条明确把「不会恢复」这一类排除在灰态之外。
- **运行时探测是唯一判据**（与 `ADR-0179` 同一次探测），不按平台写死。
- 受约束的文档：`systems/monetization.md` · `ux/screen-flow.md` · `ux/error-and-blocking-ux.md` · `decisions/ADR-0023-premium-entitlement-and-redemption.md`（计数措辞）· `decisions/ADR-0142-grayed-state-is-visual-only.md`。
