# game-progression

> 每个 ante 的进程推进、location（地域）、Travel 路由、节点类型路径导航、月圆之夜式菜单、横向滑动选择、篇章 / 境界推进、blind / ante 缩放。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

### 轮回结构与篇章 / 境界推进
- 一次轮回的结构为 **realm → chapter → AdventureEvent**。修炼阶梯（炼气 / Qi Refining → 筑基 / Foundation Establishment → 金丹 / Golden Core → 元婴 / Nascent Soul）共四个 realm；一次轮回为**三个 chapter**，每个 chapter 是相邻两个 realm 之间的攀登。Source: `10-handoffs/2026-07-13.md`。
- 在一个 chapter 内，进程由 **eventOptions 循环**驱动：future-event-service 依当前 characterProfile 产出一批可选的 AdventureEvent（eventOptions），玩家**从中选择一个**来推进；每个 AdventureEvent 触发事件、改变玩家状态，随后 future-event-service **重算下一批 eventOptions**。见 `20-systems/services/future-event-service.md`。Source: `10-handoffs/2026-07-13.md` + `10-handoffs/2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md`。
- **各 chapter 相互衔接。** 第 N+1 个 chapter 从第 N 个 chapter 的某个*可用结束点*开始——因此完成状态会分支，并为下一个 chapter 的起点埋下种子。Source: `10-handoffs/2026-07-13.md`。
- 每个 chapter 边界都是角色档案上的一个**存档 / 记录点**（共三个）；抵达元婴即为最终奖杯展示。Source: `10-handoffs/2026-07-13.md`。
- **篇章总数 = 四境三篇章（已确认）。** 重试上限：第一章（炼气→筑基）无限、第二章（筑基→金丹）3、第三章（金丹→元婴）1。（重试 / 存档 / 篇章继承的完整生命周期语义归 `20-systems/services/life-cycle-service.md`。）Source: `10-handoffs/2026-07-22-online-cloud-combat-and-meta-clarifications.md`。
- **篇章继承 = 全部继承（已定案）。** 读档续入下一 chapter 时，角色带入**上一篇章的全部信息**（deck、法宝、属性、叙事标记等），无逐项筛选。Source: `10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。
- **每个篇章 = 一个移动端时段，时长由 `lifeSpanCost` 定价控制（已定案）。** 目标时长（**熟练玩家口径**，新手更长）：第一篇章 **30–40 分钟**、第二篇章 **35–45 分钟**、第三篇章 **45–55 分钟**。**寿元预算增量是叙事阶梯的形式量，事件定价才是时长旋钮**；第三篇章预算 +300 远多于前两章，靠**上调 `lifeSpanCost`** 把时长压回区间。**剩余寿元跨篇章结转**（下一篇章预算 = 该章增量 + 上一章剩余），故「省着花」有跨篇章回报，寿元是贯穿整个轮回的一条资源线。分档表归 `20-systems/balance.md`。**推论：时段被拉长到接近一小时**，故中途存档续玩比先前更承重（已由决策点存档覆盖）。Source: `10-handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md` + `10-handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。

### 修行等级体系（realm + level）

- **等级 = 境界内的层级（已定案）。** 角色的修行位置由**境界（realm）+ 境界内等级（level）**合成：

  | 境界 | 层级 | 数量 | 篇章跨度 |
  |------|------|------|----------|
  | 炼气 Qi Refining | 1 层 ~ 13 层 | 13 | 第一篇章 1→13 |
  | 筑基 Foundation Establishment | 初期 / 中期 / 后期 / 巅峰 | 4 | 第二篇章 1→4 |
  | 金丹 Golden Core | 初期 / 中期 / 后期 / 巅峰 | 4 | 第三篇章 1→4 |
  | 元婴 Nascent Soul | 初期 | 1 | 终点 |

  Source: `10-handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md`。
- **进阶即归位初期（已定案）。** 每个篇章结束、突破进入下一境界后，等级一律重置为**新境界的初期（level 1）——元婴亦然**（元婴只有初期，且是游戏终点）。Source: 同上。
- **一切等级比较建立在全局等级序上（已定案）。** 「谁比谁高几级」的判据（首先是 `combat-service` 的敌人意图三档揭示）一律在**跨境界连续的全局序**上做，**不拿两个境界内的层号直接相减**——否则「筑基中期(2) vs 金丹初期(1)」会得出敌人更低的荒谬结论。全局序 = 境界基数 + 境界内层级：

  ```
  炼气 1层..13层  →  全局 1..13
  筑基 初期..巅峰 →  全局 14..17
  金丹 初期..巅峰 →  全局 18..21
  元婴 初期       →  全局 22
  ```

  **境界之间不留跳变（已定案）：** 全局序就是连续的 1–22，枚举值自带描述（`level=1` → 炼气一层，`level=14` → 筑基初期，…）。**境界鸿沟改由 `baseMomentum` 承载**——每个等级对应一个战斗起始道念，筑基以上每级跨度持续放大（表见 `20-systems/balance.md`）。这条分工让等级序保持为一把简单的直尺，而把「跨境界有多难」放进战斗数值里。Source: 同上 + `10-handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。
- **等级成长 = 事件产出（已定案）。** 境界内等级由 **AdventureEvent 的 reward 给予**：
  - **不只绑定 Combat / Practice** —— 任何类型的修行事件都可能给等级产出（闭关、探索、社交皆可）。
  - **不只有胜利才给** —— **失败同样可能有等级产出**（挫折亦是修行）。这与「失败侧应有产出」的取向一致（见 `20-systems/player-profile/codex/`、`player-power/`）。
  - 它与 `manaLimit` 同属一套「由事件 cost / reward 推拉」的成长体系，走同一条 `ProfileChangeSpec` → `TryApply` 链路（见 `20-systems/services/life-cycle-service.md`）。
  - **产出的频次与分布未定**，见待决问题——它与寿元预算的花法互相约束。
  Source: `10-handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。

### 进程形态与节点呈现
- **eventOptions 的服务化生成。** 「从当前可用的 AdventureEvent 中选择」由 **future-event-service** 依当前 characterProfile 产出一批 `List<EventOption> eventOptions`（见 `20-systems/services/future-event-service.md`）。**进程是逐批择一的线性推进，不是可俯瞰的分支地图**：事件之间没有预先连好的边，每一步的可选集都是当场算出来的；CharacterProfile 向后以 `pastEvent` 持有已走过的历程轨迹。Source: `10-handoffs/2026-07-15-adventure-event-profiles.md` + `10-handoffs/2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md`。
- **节点形态 = 月圆之夜风格（已定案）。** 节点 / 修行事件的呈现**参考《月圆之夜》**——精心策划的事件菜单，而非 StS 式完全分支地图。Source: `10-handoffs/2026-07-22-online-cloud-combat-and-meta-clarifications.md` + `10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。
- **选择界面 = 横向滑动选择区（已定案）。** eventOptions 通过一个**可横向滑动的选择区**（horizontal scrolling area）呈现，玩家滑动以选中要继续的目标 AdventureEvent。契合月圆之夜风格的「事件菜单」形态，且贴合竖屏触控。Source: `10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。
- **AdventurePlot 调制 eventOptions（方向）。** 隐藏抽象 **AdventurePlot（隐藏剧情线）** 是一棵分支可能性树，在背景中**调制 future-event-service 产出的 eventOptions**。隐藏属性（道心 / 煞气 / 寿元）达阈值时驱动对应剧情线，改写后续可选事件；某些节点可像 DnD 那样让玩家选择分支。详见 `20-systems/services/plot-manager.md`。Source: `10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。

### 地域 / location 与 Travel 路由
- **地域 / location = 抽象概念。** 角色当前所在地点。location **框定 eventOptions**——角色当前地点决定**下一批可能出现的修行事件池**。它是介于「原始生成」与「AdventurePlot 调制」之间的另一层框定：不同地点开放不同的修行事件池。Source: `10-handoffs/2026-07-24-docs-restructure-class-model.md`。
- **Travel / 前往某处地点 = 地图路由（AdventureEvent-Travel，第九类）。** Travel 是 adventure-event 的一个子类型，**功能上是一次地图路由选择**——选择 Travel 事件即**刷新角色所在的 location**，从而换掉下一批 eventOptions。即：Travel 是玩家在月圆之夜式菜单中「换图 / 换地点」的入口。子类型定义见 `20-systems/adventure-event/travel/`；本文档持有 location 抽象与路由语义。Source: `10-handoffs/2026-07-24-docs-restructure-class-model.md`。
- **归属划分。** location 抽象与路径导航语义归本文档（game-progression）；Travel 作为**事件类型**的呈现 / 数据归 `adventure-event/travel/`；二者通过「Travel 刷新 location → location 框定 eventOptions」协作。

### blind / ante 缩放
- blind / ante 的**要求、奖励与 scaling** 归本文档（进程侧）；缩放曲线为可调数值，存入 `.tres` 并归 `20-systems/balance.md`（ante 曲线）。**具体 blind 要求 / 奖励 / 缩放曲线尚未陈述**，见待决问题。Source: `10-handoffs/2026-07-24-docs-restructure-class-model.md`。

## 决策(-> ADR)
> _已定案的决定链接到 50-decisions/ADR-####。_

- **境界存档 · 篇章重试模型（四境三篇章、篇章衔接、重试无限/3/1）** → `50-decisions/ADR-0004-realm-checkpoint-retry-model.md`（Accepted）。
- **修行事件分类（含 Explore / Travel）** → `50-decisions/ADR-0002-adventure-event-taxonomy.md`（Accepted；ADR-0002 待补订 Explore / Travel）。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **等级产出的频次与分布（途径已定，分布未定）。** 「等级成长 = event reward、不只战斗类、失败也可能给」已定案；仍待定：一章内需要多少个「升级型产出」才能从 1 爬到 13（炼气）/ 1 到 4（筑基 · 金丹）、它们在事件池中如何分布、失败给的产出是否弱于胜利。**这会反向约束该章的事件总数与寿元预算的花法。** → `20-systems/balance.md`。Source: `10-handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。
- **中长期规划感的来源（08-01 提出，未裁决）。** 进程是**逐批择一的线性推进**，既无俯瞰地图也无前方预告——玩家看不到「还有几步到 Finale」、也无法为几步之后布局。中长期规划感由什么承担（可见的篇章进度条？eventOptions 的前瞻提示？还是有意不给），本次评审提出但**未讨论**。→ 亦见 `40-ux/`。Source: 同上。
- **「可用结束点」已明确**：到达下一境界所落的**存档点**即结束点，可读档开始下一 chapter。**chapter 途中死亡 → 从该 chapter 起始存档重试**；炼气（第 1 chapter）近乎无限重试，后续 chapter 有限重试（数值见 `20-systems/services/life-cycle-service.md`）。Source: `10-handoffs/2026-07-15b-taxonomy-and-checkpoint-clarifications.md`。
- **选择区的呈现与导航手感**：月圆之夜式菜单 + 横向滑动选择已定案，但**每批 eventOptions 的选项数量 / 排布 / 滑动手感**尚未落定。注意进程形态是**逐批择一的线性推进**（每次从当前 eventOptions 中选一个，选完重算下一批），**不是可俯瞰、可回溯的分支地图**。Source: `10-handoffs/2026-07-13.md`。
- **eventOptions 生成 / 加权**：future-event-service 服务化已定，但**从 characterProfile 如何生成 / 加权抽取**下一批 eventOptions（策划 vs 随机权重、带种子 RNG 派生）、以及 location 框定 / AdventurePlot 调制 / seeded RNG 的**叠加顺序**未定。→ `20-systems/services/future-event-service.md`。Source: `10-handoffs/2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md`。
- **location 机制细节（待定）：** 地域的枚举 / 层级、Travel 如何映射到具体 location、一个 location 开放哪些修行事件池、location 与 AdventurePlot 调制的叠加顺序、location 是否随篇章 / 境界变化——均**尚未陈述**。Source: `10-handoffs/2026-07-24-docs-restructure-class-model.md`。
- **blind / ante 缩放（未陈述）：** 具体 blind 要求 / 奖励 / ante 缩放曲线**尚未陈述**；缩放数值最终归 `20-systems/balance.md`。Source: `10-handoffs/2026-07-24-docs-restructure-class-model.md`。

## 对应
提炼至：`.claude/knowledge/systems/game-progression.md`（引用层，待建）。
