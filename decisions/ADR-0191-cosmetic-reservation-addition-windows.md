# ADR-0191 — 外观「架构预留」的兑现物 = 三个加法窗口保持开启，明确否决占位字段

- **状态：** Accepted
- **日期：** 2026-09-07
- **来源：** handoffs/2026-09-07b-cosmetic-monetization-shape.md · answer-logs/log-cosmetic-monetization-shape.md

## 背景

`vision/scope.md` 长期写着外观装饰「架构预留、首批不做」。这是一句无法证伪的承诺，最容易被误读成「那就先加个占位字段把位置占住」。

## 决策

**「预留」的兑现物 = 下列三个加法窗口保持开启，首批不为外观增加任何字段、屏、内容类型或资产类目：**

1. `PlayerEntitlement` 可加具名字段；2. `GameSetting` 可加账号级具名字段；3. Store 屏可容纳新结果态。

**明确否决占位字段。**三个窗口的逐行说明见 `systems/monetization.md`。

## 理由

`systems/monetization.md` 三条：① 占位字段会进 `profile-shape-v1.json` 的 golden 快照与 v1 清单，于是一个**永远为空**的结构成为契约的一部分；② `/entitlement/*` 是透明路径且后端写入面受回声约束，占位即要求后端此刻就在封闭表里为它开一行——**跨边界地固化一个尚未设计的形状**；③ 预留的成立只依赖那三个窗口开着，而它们都开着，占位不换来任何东西。

## 备选方案

- **先加一个空的占位字段把位置占住** — 否决：三条理由如上。

## 后果

- 首批零改动、当前不产生任何后端承接项，两库 `cross-boundary.md` 保持原样。
- **代价：那三个加法窗口本身此后成为受保护的不变式**——关闭其中任何一个即等于撤销这条预留。
- 约束 `systems/player-profile/_index.md` · `systems/player-profile/game-setting.md` · `systems/services/profile-schema-versions.md` 不得预先为外观开格。
