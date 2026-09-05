# 场景索引（引用层）

> **权威：`game-design-documents/ux/`**（`screen-flow.md` · `combat-ux.md` · `onboarding.md` · `error-and-blocking-ux.md`（横切所有屏）· `_index.md`）；端到端运行链路见根级 `program-overview.md`。此处只留代码现状、场景目录与接线纪律。

## 代码现状

**项目没有任何场景。** `game-feature-branch/` 只有 Godot 脚手架（`project.godot`、`icon.svg`、`.godot` 缓存、git 属性文件），无 `.tscn` / `.cs`；`project.godot` **未设主场景**、无 `[autoload]`。下列全是**规划**。添加 / 重命名场景时更新本文件。

## 屏幕流程

**Bootstrap（`main` 场景）→ 登录屏（条件步）→ 主菜单 →（切换篇章）→ 角色选择屏 → 轮回。**

- **`main` 场景是 `BootstrapScreen.tscn`，不是 `LoginScreen.tscn`。** autoload 的 `_Ready` 不能 `await`，故由它按序驱动边界服务的初始化并把进度喂给启动画面；**完整启动顺序见权威，别在此复述**。→ `autoloads/_index.md`、`systems/architecture.md`「总则 4」
- **登录屏是条件步**：启动期静默续期成功即跳过它直接进主菜单——**别把它接成必经的一屏**。→ `ux/screen-flow.md`
- **强制账号登录，无游客（Guest）入口。** **渠道入口按「本版本实现了哪些」呈现，不遍历 `LoginChannel` 枚举**（首版只实现两个入口，照枚举渲染会画出点不了的按钮）。→ `ux/onboarding.md`
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
| `MainMenu.tscn` | 篇章选择 + **五个**入口：PlayerProfile、PlayerPower、Achievement、Settings、**Store（礼包）**。 |
| `CharacterSelect.tscn` | **角色选择屏**：切换篇章后、`StartCycle` 之前的一屏，横滑选择可玩角色模板。 |
| `Cycle.tscn` | 轮回外壳：承载当前事件的屏幕 + **角色状态条**（境界、寿元、mana、灵石、经验条 + 储物袋与**卡组**两个入口）。**状态条只常驻灵石；仙玉的非战斗查看落点唯一落在储物袋面板。** **寿元告警的静态标注只落在 EventOption 选择界面这一条上，不做全局 HUD、不进战斗内。** → `ux/screen-flow.md` |
| `StoragePack.tscn` | **储物袋：全屏面板**（不是抽屉），纵向滚动网格，跨轮回级 / 账号级两持久层。→ `decisions/ADR-0097-storage-pack-two-layer-view.md` |
| `PreCombatConfirm.tscn` | **战前确认页**：事件流程内的一屏全屏，事前知识（含已解锁敌人图鉴词条）在此兑现——**战斗屏内没有任何图鉴入口**。→ `decisions/ADR-0094-pre-combat-confirmation-page.md` |
| `Exchange.tscn` | 交易屏：纵向滚动网格、买不起灰显、就地二段确认、售罄留占位。**形状与其余非战斗事件不同构。** |
| `Store.tscn` | 礼包详情与购买入口；另有购买处理中与兑现结果两个**结果态**（不是两屏）。 |
| `BlockingNoticeScreen.tscn` | 三种终局 / 硬阻塞态共用一屏（变体表见权威）。→ `ux/screen-flow.md` |
| `EventOptions.tscn` | **横向滑动选择**；每项显示 `SelectCost` 与 `Priority`。消费物化出的定稿 `EventOption`，**只读**（字段清单 → `systems/adventure-event/common-properties.md`）。轮回内主导航面。**付不起 `SelectCost` 不设灰态**——须如实展示并允许选择（照付 → 判定 → 可能判负）。 |
| `Combat.tscn` | 战斗视图。**主视觉 = 双方道念位**（对比条横贯屏幕、双方头像与数值分居两端）+ **剩余回合数**；另有敌人区、**战报 `combatLog`**（收起态固定预留高度的单行，**双方回合都常驻有内容**；展开态 = 半屏因果树）、**战场区**、**栈区**、手牌、mana、出牌区、持有物两层（**只读的神通 / 法则条** + **可操作的「随身」抽屉**）、埋伏计数。**无意图区**（08-15d 整条移除）。三个 `combatTier` 档复用。 |
| `CombatReward.tscn` | 战后奖励屏（参照 StS）：强制自动计入项 + 候选项**逐项领取 / 跳过**（**不是三选一**，到手数由玩家定）。奖励预先算定落存档、退出重进同一组、不重抽；但**每一次领取 / 跳过都是决策点 `D6`**，中途进度落 `activeCombat.reward`。→ `decisions/ADR-0082-itemized-combat-rewards.md` |
| `Settings.tscn` | 音频、显示、辅助功能。 |

> **非战斗四类不共享同一个屏幕形状。** 「差异只在数据」这条只对**代码分层**成立（两个 `IEventResolver`），**不对呈现成立**：Exchange 是滚动网格屏、Research 是复数决策槽的构筑面板、Explore 另有一层全屏揭示转场、Travel 无自有面板。别照着「一个通用事件屏」去搭。

### 实例化控件（可复用，`PackedScene`）
| 场景（规划中） | 用途 |
|-----------------|---------|
| `Card.tscn` | 绑定到某个 `CardData` / `CardInstance` 的卡牌视图。**全幅插画**，卡面唯一文字是 `manaCost`；**点按 = 升起详情页，拖出手牌区 = 打出**。 |
| `TechniqueCard.tscn` | 功法卡片：**闭关 / 开局构筑 / 商店 / 战后奖励四处共用同一套**，带属性图标与「单灵根专属」角标。 |
| `CharacterCard.tscn` | 角色选择屏横滑区的条目。 |
| `Enemy.tscn` | 绑定到 `EnemyInstance`（**非 `EnemyData`**——等级是物化产物）的敌人视图；显示境界名 + 层级（**全局序不上 UI、不做方向标记**），**不显示任何行动预告**。**不挂图鉴入口**——战斗内一律不可查。 |
| `PlayerPowerIcon.tscn` | HUD / 主菜单中的一个玩家能力，带开关。 |
| `EventOptionCard.tscn` | 事件选项条目：静态文案 + 成本 + `Priority`。**无「可跳过 / 必做」状态**——跳过通道整体不存在。 |
| `BottomSheet.tscn` | **半屏弹层是全局统一的控件语言**（先例：随身抽屉、战前确认页的功法词条、`Power` 详情）——需要「升起一层」时复用它，不另造控件。 |

## 承重纪律

- **屏幕不直接读服务内部字段**：呈现期由 UI 层组装 ViewModel（静态文案 + 运行时状态 + capability 可见性），**不落存档、不进云端负载**、不被服务反向依赖。→ `systems/viewmodel.md`
- **呈现决策归呈现层**：`CapabilitiesChanged` 是空负载，各 UI 组件自行订阅并自查 `Has(flag)`——业务层完全不知道这些 PlayerPower 存在。→ `standards/signal-eventbus.md`
- **EventBus 订阅在 `_Ready`、退订在 `_ExitTree`**：C# 泛型事件漏退订即泄漏且**不会报错**。→ `standards/signal-eventbus.md`
- **UI 文案一律走 `res://text/` 翻译键，全库不写任何文案字面量**（`ERR_*` 由 `code` 机械变换而来，不得手写）；**内容文案不走翻译键**，它走条目内嵌的 `LocalizedText`。→ `ux/error-and-blocking-ux.md`、`ux/_index.md`（归属四问）
- **切语言后 ViewModel 不会自己变**：`LocalizedText` 不经 `TranslationServer`，ViewModel 层须订阅翻译变更并重新组装一次，否则界面已是英文而卡面仍是中文。→ `systems/viewmodel.md`
- **场景是视图，不放数值**：玩法数值在 `.tres`，由注册表加载。→ `standards/godot-scene-conventions.md`
- **敌人的行动不作任何事前预告**，可读性由敌人回合的逐步执行呈现独占承担——别加「蓄力 / 破绽」式状态标记，那是换名字把预告装回来。→ `ux/combat-ux.md`
- **卡面 = 全幅插画**：唯一文字是 `manaCost`，规则文字 / 卡名 / 关键字一律后置到详情页；**插画内不得烧入任何承载可翻译语义的文字**（那会绕过唯一的语言开关）。→ `decisions/ADR-0083-full-art-card-face.md`
- **手势分工**：**点按手牌 = 升起详情页，拖出手牌区 = 打出**；详情入口按「对象是否可拖拽」分化——**可拖拽用点按、不可拖拽用长按**（长按与拖拽起手争同一段时间窗）。**两种手势并存是判据，不是漂移。** → `decisions/ADR-0085-gesture-split-tap-versus-longpress.md`
- **全库禁 hover-only 可供性**，触控等价物一律是长按。→ `.claude/rules/ui-input-rules.md`
- **战斗内一律没有图鉴入口**（含点按敌人立绘）：事前知识集中在战前确认页兑现，事中可读性由飘字 + 战报独占承担。→ `decisions/ADR-0094-pre-combat-confirmation-page.md`
- **战斗持有物按「可操作 / 只读」分两层，不按数据归属分**；**禁用判据一句话：看它是否与决策面争抢屏幕或语义**——**纯只读不是豁免理由**。→ `decisions/ADR-0099-combat-holdings-two-tiers.md`
- **固定预留高度的容器本身不参与布局变化**（变的是子节点淡入淡出）⇒ 动画不触发 `Container` 重排。这条防的是手牌区跳位干扰拖拽出牌的肌肉记忆，是「拖出手牌区 = 打出」的前提。→ `ux/combat-ux.md`
- **付费入口只有主菜单那一个**：轮回内 / 战斗内 / 结算流程内**不存在第二条通往付费的路径**；永不带红点 / 角标 / 倒计时，已购不隐藏。→ `ux/screen-flow.md`
- **设置滑条：拖动实时预览、释放才提交，离屏时强制提交一次**——一次提交 ⇒ 一次本地原子写。→ `ux/screen-flow.md`
- **「离线 · 待同步 N」指示在战斗屏内必须可见**：它是「进入战斗前同步失败不额外提示」那条静默纪律成立的前提，藏起来静默就变成失联。→ `ux/screen-flow.md`
- **不在最高频操作上加模态弹层**——这是裁决「要不要再加一次确认」的通用判据。→ `ux/combat-ux.md`
- **选目标态必须自解释**：唯一合法目标时不进入该态，单点即确认，挂起后恢复回到该选择点、不允许反悔。→ `ux/combat-ux.md`

## 如何添加一条场景说明

对于非平凡的场景，添加一小节（或一个文件）注明：node 树形状、脚本类、导出引用、消费哪个 ViewModel、由哪个服务 / 编排层驱动、发射哪些信号。一旦 `BootstrapScreen.tscn` 存在，在 `project.godot` 中将**它**设为主场景。
