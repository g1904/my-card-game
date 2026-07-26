# adventure-event / common-properties（AdventureEvent 顶层共有属性）

> 所有 AdventureEvent 子类型共有的属性 / 字段与通用流程。各子类型专有属性见其各自的 `common-properties.md`。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

### 共有属性 / 字段

- **图编码 possibleFutureEvent / pastEvent。** AdventureEvent 组成一张图（「修行历程」，`List<AdventureEvent>` 概念）：每个事件持有指向**可能的后续事件**（`possibleFutureEvent`）与**已经历事件**（`pastEvent`）的引用，据此编码修行历程的前后关系。当前可选的一批事件（eventOptions）由 future-event-service 依角色状态产出：受角色当前 location（地域）框定，并被隐藏剧本层 AdventurePlot 持续调制（见 `20-systems/services/future-event-service.md`、`20-systems/services/plot-manager.md`）。Source: `terminology.md` + `10-handoffs/2026-07-24-docs-restructure-class-model.md` + `10-handoffs/2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md`。
- **`eventType`（类型标签 · 子类型枚举）。** 每个 AdventureEvent 带一个 `eventType` 字段，归属九类之一（Combat / Finale / Mystery / Practice / Exchange / Research / Explore / Social / Travel）。Mystery 为元类型，遮罩一个固定的其余某类事件——被遮罩事件的真实 `eventType` 在揭示前对玩家不可见。Source: `terminology.md` + `10-handoffs/2026-07-25b-event-cost-fields-capability-flags-and-service-hierarchy.md`。
- **`selectCost`（选择成本 · 共有字段）= 一个定制的复合成本类型（已定案）。** 选中该 AdventureEvent 以推进 run 所需付出的代价。`selectCost` **不是单一数值，而是一个定制类**——它由**若干成本 element 组成**，**`lifeSpanCost` 是其中一个 element**。因此一个事件的选择代价可以同时涉及多种资源（寿元 + 其他），由该成本类型统一承载，而非在 AdventureEvent 上平铺一堆并列的成本字段。与 `skipCost` 一起，把「从 eventOptions 中推进」建模为一次**双向付费的取舍**，而非单纯的菜单点选——契合月圆之夜式事件菜单的策划取向。Source: `10-handoffs/2026-07-25b-event-cost-fields-capability-flags-and-service-hierarchy.md`。
  - **`lifeSpanCost`（成本 element）：** 完成该事件对角色**寿元 / lifeSpan** 的扣减，**基准 -1**；见下方独立条目。
  - **`skipCost` 同为该成本类型（已确认）。** 跳过与选择付的是**同一套资源体系**，只是数值取向不同——因此 `selectCost` / `skipCost` 是同一成本类型的两个实例，`lifeSpanCost` 等 element 对二者同样适用。其余 element 的清单待定，见待决问题。
- **`skipCost`（跳过成本 · 共有字段）+ `ifMandatory`（是否强制 · 共有字段）。** 二者共同定义一条**「跳过事件」通道**：面对一批 eventOptions，玩家除择一进入外，还可**付出 `skipCost` 跳过**某个事件；`ifMandatory = true` 的事件封死该通道（必须面对，不可跳过）。跳过后的完整语义（是否刷新整批、是否计入修行历程、是否照扣寿元）待定，见待决问题。Source: 同上。
- **寿元消耗 `lifeSpanCost`（`selectCost` 成本类型的一个 element）。** 表示完成该事件对角色**寿元 / lifeSpan** 的扣减；它不是 AdventureEvent 上的独立平铺字段，而是**成本类型 `selectCost` 的组成 element 之一**（见上）。**默认（基准）为 -1**——即推进一个修行事件通常消耗 1 点寿元。个别事件可设更大 / 更小 / 正值（回寿）以体现代价差异。寿元由 life-cycle-service 在事件结算时按 `lifeSpanCost` 扣减，归 0 → `defeated`（大限将至）。`lifeSpanCost` 的基准值为可调平衡数值（见 `20-systems/balance.md`）。Source: `10-handoffs/2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md`。
- **稳定 Id。** 作为数据资源，每个 AdventureEvent 内容条目有稳定唯一的字符串 `Id`（供图引用、存档 key points、注册表查找）。Source: `data-resource-rules.md`。

### 共有方法面（生命周期钩子）

- **`eventStart(...)` / `eventEnd(...)`。** 每个 AdventureEvent 带一对生命周期钩子：`eventStart` 为进入该事件时的入口回调，`eventEnd` 为事件结束 / 结算时的出口回调。与 life-cycle-service 的 `AdvanceEvent(...)` 构成**两段式**：**服务**负责状态机与 CharacterProfile 写入，**事件自身**负责其内部流程。二者的具体职责边界（谁扣成本、谁推拉隐藏属性、谁触发 eventOptions 重算）与签名待定，见待决问题。Source: `10-handoffs/2026-07-25b-event-cost-fields-capability-flags-and-service-hierarchy.md`。

### 通用流程

- **呈现 = 月圆之夜风格（已定案）。** 修行事件以精心策划的**事件菜单**形态呈现，参考《月圆之夜》。Source: `10-handoffs/2026-07-22-online-cloud-combat-and-meta-clarifications.md`。
- **选择 = 横向滑动选择区（已定案）。** 「从可用修行事件（eventOptions）中选择」用一个**可横向滑动的选择区**（horizontal scrolling area），滑动选中目标 AdventureEvent。详见 `20-systems/game-progression.md`。Source: `10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。
- **进入。** 玩家在选择区选中一个可用 AdventureEvent 后进入该事件；Mystery 在进入时揭示其被遮罩的固定事件。Source: `terminology.md`。
- **结算与后果。** 事件结束后其后果影响玩家及未来状态（隐藏属性推拉、eventOptions 重算、location 刷新等）；结算规则因子类型而异——Combat/Practice 走战斗结算、Finale 走独立结算、其余为事件式结算。
- **自动存档边界。** 事件为合理的自动存档点之一（每场遭遇战 / 地图节点之后）。Source: `state-save-rules.md`。

## 决策(-> ADR)
> _已定案的决定链接到 50-decisions/ADR-####。_

- **呈现形态、选择交互** 已定案，见「意图」及 `50-decisions/ADR-0002-adventure-event-taxonomy.md` 上下文。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **图 schema 与 key points 粒度：** possibleFutureEvent / pastEvent 的数据编码、与 eventOptions 服务态的关系、与 AdventurePlot key points 的耦合方式、存档落地的字段清单未定。→ 亦见 `20-systems/services/future-event-service.md`、`20-systems/services/plot-manager.md`。
- **可用事件的生成规则：** future-event-service 如何具体产出「下一批 eventOptions」（数量、类型配比、刷新时机、location + AdventurePlot 叠加顺序）未定。→ 亦见 `20-systems/game-progression.md`。
- **成本类型的 element 清单未定。** `selectCost` 为定制复合成本类型、`lifeSpanCost` 为其一个 element 已定案；**其余有哪些 element**（gold？mana？道具？隐藏属性推拉？）、每个 element 的数据形态（固定值 / 区间 / 公式）、以及**付不起某个 element 时的判定规则**（整体不可选？部分抵扣？）均未定。→ `20-systems/character-profile/currency.md`、`20-systems/balance.md`。Source: `10-handoffs/2026-07-25b-event-cost-fields-capability-flags-and-service-hierarchy.md`。
- **跳过是否也扣 `lifeSpanCost` element？** `skipCost` 与 `selectCost` 同类型已定，故寿元在结构上**可以**成为跳过的代价之一；但「跳过一个事件时时间是否照样流逝」是玩法取向问题，未定。→ 亦见下方跳过机制条目。Source: `10-handoffs/2026-07-25b-event-cost-fields-capability-flags-and-service-hierarchy.md`。
- **跳过机制的完整语义未定：** 付出 `skipCost` 后，被跳过的事件是从本批 eventOptions 移除还是整批刷新？是否计入 `List<AdventureEvent>` / `pastEvent`？能否整批全跳？跳过是否也扣 `lifeSpanCost`（时间照样流逝？）？付不起 `skipCost` 时如何表现？跳过走哪个服务 API？→ `20-systems/services/future-event-service.md`、`20-systems/services/life-cycle-service.md`。Source: 同上。
- **`ifMandatory` 的产出侧规则未定：** 强制事件由内容作者在 `.tres` 写死，还是由 future-event-service / PlotManager 在产出 eventOptions 时动态置位（如剧情线关键节点强制）？一批 eventOptions 能否全部为 mandatory（等同取消选择权）？→ `20-systems/services/future-event-service.md`。Source: 同上。
- **`eventStart` / `eventEnd` 与 `AdvanceEvent` 的职责边界未定：** 谁写 CharacterProfile、谁扣成本、谁推拉隐藏属性、谁触发 eventOptions 重算；签名与返回形态（结算结果对象？）未定。→ `20-systems/services/life-cycle-service.md`。Source: 同上。

## 对应
提炼至：`.claude/knowledge/systems/adventure-event/common-properties.md`（待建）
