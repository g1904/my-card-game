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

- **「可用结束点」已明确**：到达下一境界所落的**存档点**即结束点，可读档开始下一 chapter。**chapter 途中死亡 → 从该 chapter 起始存档重试**；炼气（第 1 chapter）近乎无限重试，后续 chapter 有限重试（数值见 `20-systems/services/life-cycle-service.md`）。Source: `10-handoffs/2026-07-15b-taxonomy-and-checkpoint-clarifications.md`。
- **选择区的呈现与导航手感**：月圆之夜式菜单 + 横向滑动选择已定案，但**每批 eventOptions 的选项数量 / 排布 / 滑动手感**尚未落定。注意进程形态是**逐批择一的线性推进**（每次从当前 eventOptions 中选一个，选完重算下一批），**不是可俯瞰、可回溯的分支地图**。Source: `10-handoffs/2026-07-13.md`。
- **eventOptions 生成 / 加权**：future-event-service 服务化已定，但**从 characterProfile 如何生成 / 加权抽取**下一批 eventOptions（策划 vs 随机权重、带种子 RNG 派生）、以及 location 框定 / AdventurePlot 调制 / seeded RNG 的**叠加顺序**未定。→ `20-systems/services/future-event-service.md`。Source: `10-handoffs/2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md`。
- **location 机制细节（待定）：** 地域的枚举 / 层级、Travel 如何映射到具体 location、一个 location 开放哪些修行事件池、location 与 AdventurePlot 调制的叠加顺序、location 是否随篇章 / 境界变化——均**尚未陈述**。Source: `10-handoffs/2026-07-24-docs-restructure-class-model.md`。
- **blind / ante 缩放（未陈述）：** 具体 blind 要求 / 奖励 / ante 缩放曲线**尚未陈述**；缩放数值最终归 `20-systems/balance.md`。Source: `10-handoffs/2026-07-24-docs-restructure-class-model.md`。

## 对应
提炼至：`.claude/knowledge/systems/game-progression.md`（引用层，待建）。
