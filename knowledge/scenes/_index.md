# 场景索引

> 屏幕/流程/手感的权威设计意图：`game-design-documents/40-ux/`（screen-flow、combat-ux、onboarding）；端到端运行链路见根级 `program-overview.md`。

手工维护的 Godot 场景目录。添加/重命名场景时更新本文件。**目前项目没有任何游戏场景**——只有脚手架（`icon.svg`；`project.godot` 中尚未设置主场景）。

## 屏幕流程（已定案）

**登录屏（应用首屏）→ 主菜单 →（切换篇章）→ run。**

- **强制账号登录，已移除游客（Guest）入口**——不支持不登录直接进入。登录渠道优先级：手机 / 邮箱 → 微信 / QQ → 海外 / 跨平台。
- 登录屏含**服务条款（T&S）**；背景是 **live2d 风格循环动画视频**，用 **`VideoStreamPlayer`** 实现（美术 TBA，先留占位）。
- **主菜单**核心操作是**切换篇章以开始一次 run**——在**已解锁**篇章中择一。首玩者**只能从炼气（第一篇章）开始**，其余篇章选项**隐藏**（门禁细节见 `40-ux/onboarding.md`）。
- **美术挂点占位。** 循环视频、图标、卡面等 TBA；组合场景时保留可轻松替换的挂点。

## ViewModel 是屏幕与服务之间的契约层（已定案）

屏幕**不直接读服务内部字段**。呈现期由 UI 层组装 `Data（静态文案，来自 ContentRegistry）+ 运行时状态 + capability 可见性 → ViewModel`。ViewModel **不落存档、不进云端负载**，单向依赖、不被服务反向依赖。

**呈现决策归呈现层：** capability flag 由 `profile-service.CapabilityManager` 聚合并经 EventBus 广播 `CapabilitiesChanged`；**各 UI 组件自行订阅并自查** `Has(RevealHiddenStats)` 等 flag 决定自身可见性——业务层完全不知道这些 PlayerPower 存在。

## 预期场景

### 屏幕（全视口）
| 场景（规划中） | 用途 |
|-----------------|---------|
| `LoginScreen.tscn` | 应用首屏：T&S、`VideoStreamPlayer` 循环视频背景、渠道登录入口。**无游客入口。** |
| `MainMenu.tscn` | 篇章选择（已解锁者可见）+ 四个入口按钮：PlayerProfile（`AccountInfo`）、PlayerPower（可开关能力）、Achievements（查看进度 / 领奖）、Settings（`GameSetting`）。 |
| `Run.tscn` | run 外壳，承载当前事件的屏幕 + 常驻 HUD（金币、寿元、life / mana、deck）。 |
| `EventOptions.tscn` | **月圆之夜式菜单，横向滑动选择**；每项显示 `selectCost` / `skipCost` / 是否 `ifMandatory`（强制项封死跳过通道）。这是 run 内的主导航面。 |
| `Combat.tscn` | 战斗视图：敌人与意图、手牌、mana、出牌区。Finale 复用。 |
| `Settings.tscn` | 音频、显示、辅助功能。 |

> 交易（Exchange）等其余七类事件**不各占一个屏幕**——它们共享同一形状（呈现 → 选择或跳过 → 校验扣成本 → 应用产出 → 收口），差异在**数据**而非代码。

### 实例化控件（可复用，`PackedScene`）
| 场景（规划中） | 用途 |
|-----------------|---------|
| `Card.tscn` | 绑定到某个 `CardData` 的单张卡牌视图；可拖拽。 |
| `Enemy.tscn` | 绑定到 `EnemyData` 的敌人视图；显示 intent。 |
| `PlayerPowerIcon.tscn` | HUD / 主菜单中的一个玩家能力（relic-joker），带开关。 |
| `EventOptionCard.tscn` | 事件选项条目：静态文案 + 成本 + 可选性状态。 |

## 如何添加一条场景说明

对于非平凡的场景，添加一小节（或一个文件）逐场景注明：node 树形状、脚本类、导出引用、消费哪个 ViewModel、由哪个服务 / 编排层驱动、以及它发射的信号。一旦 `LoginScreen.tscn`（应用首屏）存在，在 `project.godot` 中将其设置为主场景。
