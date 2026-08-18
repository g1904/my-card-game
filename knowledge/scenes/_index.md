# 场景索引（引用层）

> **权威：`game-design-documents/ux/`**（screen-flow、combat-ux、onboarding）；端到端运行链路见根级 `program-overview.md`。此处只留代码现状、场景目录与接线纪律。

## 代码现状

**项目没有任何场景。** `game-feature-branch/` 只有 `icon.svg`；`project.godot` **未设主场景**、无 `[autoload]`。下列全是**规划**。添加 / 重命名场景时更新本文件。

## 屏幕流程

**Bootstrap（`main` 场景）→ 登录屏 → 主菜单 →（切换篇章）→ 轮回。**

- **`main` 场景是 `BootstrapScreen.tscn`，不是 `LoginScreen.tscn`。** autoload 的 `_Ready` 不能 `await`，故由它按序驱动**三个**边界服务的 `InitializeAsync`（并在登录之后插入一次 `RefreshFlagsAsync`）并把进度喂给启动画面。→ `autoloads/_index.md`。
- **强制账号登录，无游客（Guest）入口。** 渠道优先级：手机 / 邮箱 → 微信 / QQ → 海外 / 跨平台。
- **主菜单**核心操作是**切换篇章以开始一次轮回**（仅已解锁者可见；首玩者只能从炼气开始）。门禁细节 → `ux/onboarding.md`。
- **轮回内主导航是月圆之夜式的 eventOptions 横向滑动菜单**，不是传统地图屏。**一批只有一次操作：择一进入**——跳过通道已整体移除（08-06c），不存在「跳过」按钮、不显示 `skipCost`、不标注「可跳过 / 必做」。
- **`locationMap` 在轮回内对玩家不可见**——没有俯瞰地图屏。它的显影通道是账号级的 `LocationCodex`。
- **美术挂点占位。** 循环视频、图标、卡面等 TBA；组合场景时保留可轻松替换的挂点。

## 预期场景

### 屏幕（全视口）
| 场景（规划中） | 用途 |
|-----------------|---------|
| `BootstrapScreen.tscn` | **`main` 场景**（`scenes/screens/`）：启动画面 + 按序驱动三个边界服务的初始化与登录后的 flags 拉取。非服务、非 autoload。 |
| `LoginScreen.tscn` | 第一个交互屏：T&S、`VideoStreamPlayer` 循环视频背景、渠道登录入口。**无游客入口。** |
| `MainMenu.tscn` | 篇章选择 + 四个入口：PlayerProfile（`AccountInfo`）、PlayerPower（可开关能力）、Achievements、Settings（`GameSetting`）。 |
| `Cycle.tscn` | 轮回外壳：承载当前事件的屏幕 + **角色状态条**（境界、lifeTotal / mana、灵玉、经验条、储物袋入口；**寿元告警的静态标注只落在 EventOption 选择界面这一条上，不做全局 HUD、不进战斗内**）。→ `ux/screen-flow.md` |
| `EventOptions.tscn` | **横向滑动选择**；每项显示 `SelectCost` 与 `Priority`。消费物化出的定稿 `EventOption`，**只读**（字段清单 → `systems/adventure-event/common-properties.md`）。轮回内主导航面。**付不起 `SelectCost` 不设灰态**——须如实展示并允许选择（照付 → 判定 → 可能判负）。 |
| `Combat.tscn` | 战斗视图：敌人区、**结算 ticker**（固定预留高度，只在敌人回合有内容）、**战场区**、**栈区**（栈进入呈现层）、手牌、mana、出牌区、**「随身」抽屉**、埋伏计数。**无意图区**（08-15d 整条移除）。三个 `combatTier` 档复用。 |
| `CombatReward.tscn` | 战后奖励屏（参照 StS）：强制自动计入项 + **固定 3 项可选奖励择一**。奖励预先算定并落存档、不重抽，**因此不是决策点**。 |
| `Settings.tscn` | 音频、显示、辅助功能。 |

> 交易（Exchange）等其余四类非战斗事件**不各占一个屏幕**——它们共享同一形状，差异在**数据**而非代码。

### 实例化控件（可复用，`PackedScene`）
| 场景（规划中） | 用途 |
|-----------------|---------|
| `Card.tscn` | 绑定到某个 `CardData` / `CardInstance` 的卡牌视图；可拖拽。 |
| `Enemy.tscn` | 绑定到 `EnemyInstance`（**非 `EnemyData`**——等级是物化产物）的敌人视图；显示境界名 + 层级（**全局序不上 UI、不做方向标记**），**不显示任何行动预告**。点按立绘开敌人图鉴。 |
| `PlayerPowerIcon.tscn` | HUD / 主菜单中的一个玩家能力，带开关。 |
| `EventOptionCard.tscn` | 事件选项条目：静态文案 + 成本 + `Priority`。**无「可跳过 / 必做」状态**——本批每一项都是必做项。 |

## 承重纪律

- **屏幕不直接读服务内部字段**：呈现期由 UI 层组装 ViewModel（静态文案 + 运行时状态 + capability 可见性），**不落存档、不进云端负载**、不被服务反向依赖。→ `systems/architecture.md`
- **呈现决策归呈现层**：`CapabilitiesChanged` 是空负载，各 UI 组件自行订阅并自查 `Has(flag)`——业务层完全不知道这些 PlayerPower 存在。→ `standards/signal-eventbus.md`
- **EventBus 订阅在 `_Ready`、退订在 `_ExitTree`**：C# 泛型事件漏退订即泄漏且**不会报错**。→ `standards/signal-eventbus.md`
- **UI 文案一律走 `res://text/` 翻译键，全库不写任何文案字面量**（`ERR_*` 由 `code` 机械变换而来，不得手写）；**内容文案不走翻译键**，它走条目内嵌的 `LocalizedText`。→ `ux/error-and-blocking-ux.md`、`ux/_index.md`（归属四问）
- **切语言后 ViewModel 不会自己变**：`LocalizedText` 不经 `TranslationServer`，ViewModel 层须订阅翻译变更并重新组装一次，否则界面已是英文而卡面仍是中文。→ `ux/_index.md`
- **场景是视图，不放数值**：玩法数值在 `.tres`，由注册表加载。→ `standards/godot-scene-conventions.md`
- **敌人的行动不作任何事前预告**，可读性由敌人回合的逐步执行呈现独占承担——别加「蓄力 / 破绽」式状态标记，那是换名字把预告装回来。→ `ux/combat-ux.md`
- **呈现层只认档位、不认档位的来源**：碾压 / 越阶两道硬门不自我声明，UI 不加标注也不给替代线索。→ `ux/combat-ux.md`
- **选目标态必须自解释**：唯一合法目标时不进入该态，单点即确认，挂起后恢复回到该选择点、不允许反悔。→ `ux/combat-ux.md`

## 如何添加一条场景说明

对于非平凡的场景，添加一小节（或一个文件）注明：node 树形状、脚本类、导出引用、消费哪个 ViewModel、由哪个服务 / 编排层驱动、发射哪些信号。一旦 `BootstrapScreen.tscn` 存在，在 `project.godot` 中将**它**设为主场景。
