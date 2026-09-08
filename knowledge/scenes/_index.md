# 场景索引（引用层）

> **权威：`game-design-documents/ux/`**（`screen-flow.md` · `combat-ux.md` · `onboarding.md` · `error-and-blocking-ux.md`（横切所有屏）· `_index.md`）；端到端运行链路见根级 `program-overview.md`。此处只留代码现状、场景目录与接线纪律。

## 代码现状

**项目没有任何场景。** `game-feature-branch/` 只有 Godot 脚手架（`project.godot`、`icon.svg(.import)`、编辑器 / git 配置文件），无 `.tscn` / `.cs` / `.csproj`；`project.godot` **未设主场景**、无 `[autoload]`。下列全是**规划**。添加 / 重命名场景时更新本文件。

## 屏幕流程

**启动链与轮回内导航的完整流程步骤在权威文档，此处不复述。** → `ux/screen-flow.md`、`ux/onboarding.md`

- **`main` 场景是 `BootstrapScreen.tscn`，不是 `LoginScreen.tscn`**（autoload 的 `_Ready` 不能 `await`，故由它按序驱动边界服务初始化）；**登录屏是条件步，别接成必经的一屏**。→ `autoloads/_index.md`、`systems/architecture.md`「总则 4」
- **强制账号登录，无游客入口**；**渠道入口按「本版本实现了哪些」渲染，不遍历 `LoginChannel` 枚举**（照枚举渲染会画出点不了的按钮）。→ `ux/onboarding.md`
- **轮回内主导航是 eventOptions 横滑选择区，不是地图屏**；跳过通道整体不存在（不画「跳过」键、不显示 `skipCost`、不标注「可跳过 / 必做」），`locationMap` 对玩家不可见（其显影通道是账号级 `LocationCodex`）。→ `decisions/ADR-0046-skip-channel-removal.md`
- **美术挂点占位。** 循环视频、图标、卡面等 TBA；组合场景时保留可轻松替换的挂点。

## 预期场景

### 屏幕（全视口，均为规划中，尚无任何 `.tscn`）

| 场景 | 一句话 | 权威 |
|------|--------|------|
| `BootstrapScreen.tscn` | **`main` 场景**：启动画面 + 按序驱动边界服务初始化与登录后的 flags 拉取；非服务、非 autoload | `ux/screen-flow.md`、`autoloads/_index.md` |
| `LoginScreen.tscn` | 第一个交互屏（T&S、循环视频背景、渠道入口）；**无游客入口** | `ux/onboarding.md` |
| `RealNameScreen.tscn` | 实名屏，**未登录态可达**；客户端只做长度 / 字符集约束，判定权在后端 | `decisions/ADR-0155-compliance-client-split-criterion.md` |
| `MainMenu.tscn` | 篇章选择 + 入口按钮列；**入口个数不写死**，判据是「Store 恒排末位、安静呈现」；`ongoing` 行的「放弃」是玩家主动终结角色的**唯一入口** | `ux/screen-flow.md`「主菜单入口按钮」、`decisions/ADR-0162-active-character-discard.md` |
| `PlayerProfileScreen.tscn` | **账号级低频操作的唯一落点**——这些一律不新增主菜单入口、不落设置屏 | `ux/screen-flow.md`「玩家档案屏」 |
| `CharacterSelect.tscn` | 角色选择屏；横滑区**与 eventOptions 共用同一卡宽基准**，5 张角色卡照常横滑、不追求一屏看全 | `decisions/ADR-0221-shared-card-width-baseline.md` |
| `Cycle.tscn` | 轮回外壳：当前事件屏 + 常驻角色状态条（字段面与排版见权威；状态条只常驻灵石，寿元告警只落 EventOption 选择界面） | `ux/screen-flow.md`「角色状态条」 |
| `EventOptions.tscn` | 轮回内主导航面：**横滑等宽 carousel + 焦点制进入**；消费定稿 `EventOption`（只读），`SelectCost` 恒精确显示、`Priority` 不作数字呈现、付不起也不设灰态 | `decisions/ADR-0219-event-option-focus-tap-entry.md`、`ADR-0220`、`systems/adventure-event/common-properties.md` |
| `StoragePack.tscn` | 储物袋：**全屏面板**（不是抽屉），跨轮回级 / 账号级两持久层 | `decisions/ADR-0097-storage-pack-two-layer-view.md` |
| `PreCombatConfirm.tscn` | 战前确认页：事前知识（含敌人图鉴词条）在此兑现——**战斗屏内没有任何图鉴入口** | `decisions/ADR-0094-pre-combat-confirmation-page.md` |
| `Exchange.tscn` | 交易屏：纵向滚动网格，**与其余非战斗事件不同构** | `ux/screen-flow.md`「Exchange（交易）屏」 |
| `Research.tscn` | **闭关构筑面板**：全部槽同屏一个纵向滚动容器，不做分步向导 | `decisions/ADR-0222-research-build-panel-portrait-form.md`、`ADR-0223`、`systems/adventure-event/research/_index.md` |
| `Combat.tscn` | 战斗视图，三档 `combatTier` 复用；**无意图区**（意图机制整条移除）；**六区屏高预算表见权威，不抄进代码以外的任何地方** | `ux/combat-ux.md`「竖屏分区」、`decisions/ADR-0202-combat-portrait-zone-height-budget.md`、`ADR-0059` |
| `CombatReward.tscn` | **战斗流程内的一屏，不进屏幕栈、无返回键**；强制自动计入项 + 候选项逐项领取 / 跳过（**不是三选一**），预先算定落存档、退出重进不重抽 | `decisions/ADR-0215-post-combat-reward-panel-form.md`、`ADR-0082` |
| `CycleEndScreen.tscn` | 轮回结束屏 = 一屏三变体（`DefeatReason`），不进屏幕栈、无返回、非弹层 | `decisions/ADR-0148-cycle-end-screen.md` |
| `ChapterEndScreen.tscn` | 篇章结束屏 = 一屏三变体（按 `chapter`），ch3 变体即通关证书、不另立一屏 | `decisions/ADR-0143-chapter-end-screen.md` |
| `CodexIndexScreen.tscn` / `CodexBookScreen.tscn` / `CodexEntryScreen.tscn` | 图鉴族三层浏览；**词条页只有敌人本是全屏，其余六本走 bottom sheet**；单本页逐字复用储物袋网格语汇 | `decisions/ADR-0147-codex-single-entry-three-layer-browse.md` |
| `BlockingNoticeScreen.tscn` | 三终局态共用一屏 + 数据驱动变体表；**准入判据在权威，别自行扩表**（三个变体 ≠ 三处硬阻塞） | `ux/error-and-blocking-ux.md` |
| `Store.tscn` | 礼包详情与购买入口；购买处理中 / 兑现结果是**结果态、不是两屏** | `ux/screen-flow.md`、`systems/monetization.md` |
| `Settings.tscn` | 音频、显示、辅助功能 | `ux/screen-flow.md` |

> **非战斗四类不共享同一个屏幕形状。** 「差异只在数据」这条只对**代码分层**成立（两个 `IEventResolver`），**不对呈现成立**：Exchange 是滚动网格屏、Research 是复数决策槽的构筑面板、Explore 另有一层全屏揭示转场、Travel 无自有面板。别照着「一个通用事件屏」去搭。

### 实例化控件（可复用，`PackedScene`）
| 场景（规划中） | 用途 |
|-----------------|---------|
| `Card.tscn` | 绑定到某个 `CardData` / `CardInstance` 的卡牌视图。**全幅插画**，卡面唯一文字是 `manaCost`；**点按 = 升起详情页，拖出手牌区 = 打出**。 |
| `TechniqueCard.tscn` | 功法卡片：**闭关 / 开局构筑 / 商店 / 战后奖励四处共用同一套**，带属性图标与「单灵根专属」角标。 |
| `CharacterCard.tscn` | 角色选择屏横滑区的条目。 |
| `Enemy.tscn` | 绑定到 `EnemyInstance`（**非 `EnemyData`**——等级是物化产物）的敌人视图；显示境界名 + 层级（**全局序不上 UI、不做方向标记**），**不显示任何行动预告**。**不挂图鉴入口**——战斗内一律不可查。 |
| `PlayerPowerIcon.tscn` | HUD / 主菜单中的一个玩家能力，带开关。 |
| `EventOptionCard.tscn` | 事件选项条目 = 全库统一「候选条目」构件的一个落位；**标注带恒为空是结论、不是遗漏**，`Priority` 不作数字呈现，无「可跳过 / 必做」状态。→ `decisions/ADR-0218-candidate-item-widget-and-annotation-layers.md`、`ux/screen-flow.md`「候选项列表语言」 |
| `BottomSheet.tscn` | **半屏弹层是全局统一的控件语言**——需要「升起一层」时复用它，不另造控件；先例清单见权威。→ `ux/screen-flow.md`、`decisions/ADR-0212-card-detail-sheet-and-disable-tier.md` |
| `CodexCell.tscn` | 图鉴网格格（已收录 / 未收录两态，形态见权威）。→ `decisions/ADR-0147-codex-single-entry-three-layer-browse.md` |
| `PlotBranchButton.tscn` | 剧本分支按钮：**纵向堆叠全宽**、每条一行、承载 `BranchLabel` 全文不截断；**不复用横滑区语汇**（横滑是 eventOptions 与角色选择的语言）。→ `decisions/ADR-0150-plot-segment-in-outcome-panel.md` |

## 承重纪律

### 候选项与排布（横切六个以上面，新增决策面必读）

- **新增任何决策面前，先按排布轴判据落位：推进进程的择一 → 横滑等宽 carousel；面板内 / 事件内的择一与列举 → 纵向堆叠或网格。** 用错轴等于在视觉上否定该面的语义（战后奖励三项独立可领，横滑会把它读成三选一）。条目构件六个位、三类标注层与三条禁则见权威。→ `decisions/ADR-0217-option-list-layout-axis-criterion.md`、`ADR-0218`、`ux/screen-flow.md`「候选项列表语言」
- **说明通道全库只有一条：恒常可见 → 长按升半屏 bottom sheet → 再叠一层；绝不用悬停、绝不用「ⓘ」小图标**（前者无触控等价物，后者与整条目的点按热区争抢）。→ `decisions/ADR-0218-candidate-item-widget-and-annotation-layers.md`
- **事件选项 = 焦点制两段进入**：点非焦点卡只把它移到中心、不支付不进入；点焦点卡才支付 `selectCost` 并进入。支付不可逆且可能当场终结角色，这是零新增控件下的两段确认。→ `decisions/ADR-0219-event-option-focus-tap-entry.md`、`ADR-0220`
- **战后奖励面板的已处置项：行保留、状态标记就位，两个按钮同时移除而非置灰**——已成事实没有说明可给，留灰键只会诱导点击；面板逐格映射 `picks`，不渲染空槽。→ `decisions/ADR-0215-post-combat-reward-panel-form.md`

### 呈现层接线

- **屏幕不直接读服务内部字段**：呈现期由 UI 层组装 ViewModel（静态文案 + 运行时状态 + capability 可见性），**不落存档、不进云端负载**、不被服务反向依赖。→ `systems/viewmodel.md`
- **呈现决策归呈现层**：`CapabilitiesChanged` 是空负载，各 UI 组件自行订阅并自查 `Has(flag)`——业务层完全不知道这些 PlayerPower 存在。→ `standards/signal-eventbus.md`
- **EventBus 订阅在 `_Ready`、退订在 `_ExitTree`**：C# 泛型事件漏退订即泄漏且**不会报错**。→ `standards/signal-eventbus.md`
- **UI 文案一律走 `res://text/` 翻译键，全库不写任何文案字面量**（`ERR_*` 由 `code` 机械变换而来，不得手写）；**内容文案不走翻译键**，它走条目内嵌的 `LocalizedText`。→ `ux/error-and-blocking-ux.md`、`ux/_index.md`（归属四问）
- **战报翻译键随 `CombatFeedKind` 成员机械对应，不建第二张手写对照表**；来源名（卡名 / 异能名 / 道具名）不进翻译键，走内容层 `LocalizedText` 作格式参数插入。→ `decisions/ADR-0213-combat-log-copy-system.md`、`ux/error-and-blocking-ux.md` 分区表
- **切语言后 ViewModel 不会自己变**：`LocalizedText` 不经 `TranslationServer`，ViewModel 层须订阅翻译变更并重新组装一次，否则界面已是英文而卡面仍是中文。→ `systems/viewmodel.md`
- **场景是视图，不放数值**：玩法数值在 `.tres`，由注册表加载。→ `standards/godot-scene-conventions.md`

### 输入与手势

- **手势分工**：**点按手牌 = 升起详情页，拖出手牌区 = 打出**；详情入口按「对象是否可拖拽」分化——**可拖拽用点按、不可拖拽用长按**（长按与拖拽起手争同一段时间窗）。**两种手势并存是判据，不是漂移。** → `decisions/ADR-0085-gesture-split-tap-versus-longpress.md`
- **全库禁 hover-only 可供性**，触控等价物一律是长按。→ `.claude/rules/ui-input-rules.md`
- **灰态是视觉降级，不是引擎级禁用——灰格必须继续接收触控**（`Button.Disabled = true` 会静默吞掉按下信号，症状是「点了没反应」且测不出来）。**边界：暂时不可用 → 置灰保留触控；已成事实、永不恢复 → 移除控件；0 值的入口置灰、0 值的指示淡出。** → `decisions/ADR-0142-grayed-state-is-visual-only.md`、`ADR-0209-zero-value-affordance-versus-indicator.md`、`ux/error-and-blocking-ux.md`「灰态判据」
- **不在最高频操作上加模态弹层**——这是裁决「要不要再加一次确认」的通用判据。→ `ux/combat-ux.md`
- **选目标态必须自解释**：唯一合法目标时不进入该态，单点即确认，挂起后恢复回到该选择点、不允许反悔。→ `ux/combat-ux.md`

### 战斗屏

- **敌人的行动不作任何事前预告**，可读性由敌人回合的逐步执行呈现独占承担——别加「蓄力 / 破绽」式状态标记，那是换名字把预告装回来。→ `ux/combat-ux.md`
- **卡面 = 全幅插画**：唯一文字是 `manaCost`，规则文字 / 卡名 / 关键字一律后置到详情页；**插画内不得烧入任何承载可翻译语义的文字**（那会绕过唯一的语言开关）。→ `decisions/ADR-0083-full-art-card-face.md`
- **栈不占常驻布局预算**：它是结算期的临时浮层，出现 / 消失不得挤动任何常驻区（尤其手牌区不得跳位）。→ `decisions/ADR-0202-combat-portrait-zone-height-budget.md`、`ADR-0201`
- **固定预留高度的容器本身不参与布局变化**（变的是子节点淡入淡出）⇒ 动画不触发 `Container` 重排。这条防的是手牌区跳位干扰拖拽出牌的肌肉记忆，是「拖出手牌区 = 打出」的前提。→ `ux/combat-ux.md`
- **敌方区不做己方的镜像，且布局不得预留「翻开对手信息」的位置**——对侧手牌 / 道具 / 可启动异能在类型层恒空。→ `decisions/ADR-0203-enemy-zone-readouts-only.md`
- **敌人台词气泡以 anchor 挂在敌方区、不进任何 `Container`**（出现 / 消失不得触发重排），触控一律穿透，且**台词永不承载规则信息**（否则成为「不做事前预告」的旁路）。→ `decisions/ADR-0216-enemy-line-slots-and-flavor-only.md`
- **`TurnLimit` 与 `HandLimit` 由 `EncounterSpec` 驱动，绝不把标准档数值写死进 UI。** → `ux/combat-ux.md`、`systems/services/combat-service.md`
- **战斗持有物按「可操作 / 只读」分两层，不按数据归属分**；只读层是单行图标条 + `+N` 溢出，**不折叠不滚动**；**禁用判据一句话：看它是否与决策面争抢屏幕或语义**——**纯只读不是豁免理由**。→ `decisions/ADR-0099-combat-holdings-two-tiers.md`、`ADR-0208`
- **战斗内一律没有图鉴入口**（含点按敌人立绘）：事前知识集中在战前确认页兑现，事中可读性由飘字 + 战报独占承担。→ `decisions/ADR-0094-pre-combat-confirmation-page.md`
- **对手侧的面朝下条目不进入战斗态视图**（契约面已整条剔除，不是「在列表里但不渲染」）⇒ 视图内 `FaceDown == true` 恒指己方埋伏，`Battlefield.Count` 不再等于场上条目总数。→ `decisions/ADR-0154-snapshot-facedown-viewer-filter.md`

### 其余屏与横切

- **付费入口只有主菜单那一个**：轮回内 / 战斗内 / 结算流程内不存在第二条通往付费的路径；永不带红点 / 角标 / 倒计时，已购不隐藏。**非商店平台（桌面 / 网页）入口不渲染、不置灰**。→ `ux/screen-flow.md`、`decisions/ADR-0181-hide-store-entry-off-channel-platforms.md`
- **设置滑条：拖动实时预览、释放才提交，离屏时强制提交一次**——一次提交 ⇒ 一次本地原子写。→ `ux/screen-flow.md`
- **「离线 · 待同步 N」指示在战斗屏内必须可见**：它是「进入战斗前同步失败不额外提示」那条静默纪律成立的前提。**该指示有三取值，`UpgradeRequired == true` 时必须换掉「离线」二字**。→ `ux/screen-flow.md`
- **Exchange 的 barter 格不按持有面过滤呈现**：不持有支付物则灰显、支付要求保持可见——过滤会让同一个 `EventOption` 在两次进入之间呈现不同内容。→ `ux/error-and-blocking-ux.md`「灰态判据」、`decisions/ADR-0126-exchange-barter-payment.md`
- **轮回收尾族两屏只有一个出路「返回主菜单」**，不放「再试一次」/「继续下一篇章」——三道闸全挂在主菜单「开始新轮回」上。→ `decisions/ADR-0148-cycle-end-screen.md`、`ADR-0143`
- **剧本层在 UX 上只有一个落点：事件结算面板底部追加一段。** 不新增屏、不新增弹层；有分支时分支按钮取代「继续」。→ `decisions/ADR-0150-plot-segment-in-outcome-panel.md`
- **合规呈现落发起该操作的那一屏，一屏也不进阻塞屏**；**「可再来的时刻」只做绝对时刻格式化、不做倒计时**（本地时钟不可信）。→ `decisions/ADR-0155-compliance-client-split-criterion.md`
- **图鉴只在主菜单可达**：战斗内与轮回内的 EventOption 选择界面都不设入口。→ `decisions/ADR-0147-codex-single-entry-three-layer-browse.md`
- **三样明确不是屏**：须改名模态 · Explore 揭示转场 · Store 结果态——都不进屏幕栈。→ `ux/screen-flow.md`

## 如何添加一条场景说明

对于非平凡的场景，添加一小节（或一个文件）注明：node 树形状、脚本类、导出引用、消费哪个 ViewModel、由哪个服务 / 编排层驱动、发射哪些信号。一旦 `BootstrapScreen.tscn` 存在，在 `project.godot` 中将**它**设为主场景。
