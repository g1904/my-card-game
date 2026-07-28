# adventure-event / common-properties（AdventureEvent 顶层共有属性）

> 所有 AdventureEvent 子类型共有的属性 / 字段与通用流程。各子类型专有属性见其各自的 `common-properties.md`。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

### 共有属性 / 字段

- **AdventureEvent 之间不存在前后连边。** 单个 AdventureEvent 只是一份自足的内容条目，**不持有指向后续事件的引用**——事件之间的走向不由内容作者预先连线，而由 **future-event-service 在运行时依角色状态产出的一批 `List<EventOption> eventOptions`** 决定：受角色当前 location（地域）框定，并被隐藏剧本层 AdventurePlot 持续调制（见 `20-systems/services/future-event-service.md`、`20-systems/services/plot-manager.md`）。Source: `terminology.md` + `10-handoffs/2026-07-24-docs-restructure-class-model.md` + `10-handoffs/2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md`。
- **`pastEvent`（历程轨迹 · CharacterProfile 侧）。** 与向前的走向相对，向后的**已经历轨迹**仍需持久化：`pastEvent` 是一条**扁平的时序列表**（不是图的反向边），记录角色走过 / 跳过了哪些事件。它归属 CharacterProfile 的轮回状态，不挂在 AdventureEvent 上。痕迹语义见下方「跳过通道的玩法语义」。
- **`eventType`（类型标签 · 子类型枚举）。** 每个 AdventureEvent 带一个 `eventType` 字段，归属九类之一（Combat / Finale / Mystery / Practice / Exchange / Research / Explore / Social / Travel）。Mystery 为元类型，遮罩一个固定的其余某类事件——被遮罩事件的真实 `eventType` 在揭示前对玩家不可见。Source: `terminology.md` + `10-handoffs/2026-07-25b-event-cost-fields-capability-flags-and-service-hierarchy.md`。
- **`selectCost`（选择成本 · 共有字段）= 一个定制的复合成本类型（已定案）。** 选中该 AdventureEvent 以推进轮回所需付出的代价。`selectCost` **不是单一数值，而是一个定制类**——它由**若干成本 element 组成**，**`lifeSpanCost` 是其中一个 element**。因此一个事件的选择代价可以同时涉及多种资源（寿元 + 其他），由该成本类型统一承载，而非在 AdventureEvent 上平铺一堆并列的成本字段。与 `skipCost` 一起，把「从 eventOptions 中推进」建模为一次**双向付费的取舍**，而非单纯的菜单点选——契合月圆之夜式事件菜单的策划取向。Source: `10-handoffs/2026-07-25b-event-cost-fields-capability-flags-and-service-hierarchy.md`。
  - **`lifeSpanCost`（成本 element）：** 完成该事件对角色**寿元 / lifeSpan** 的扣减，**基准 -1**；见下方独立条目。
  - **`skipCost` 同为该成本类型（已确认）。** 跳过与选择付的是**同一套资源体系**，只是数值取向不同——因此 `selectCost` / `skipCost` 是同一成本类型的两个实例，`lifeSpanCost` 等 element 对二者同样适用。其余 element 的清单待定，见待决问题。
  - **代码形态 = `ProfileChangeSpec`（已定案）。** 该复合成本类型即 `ProfileChangeSpec`（`IReadOnlyList<ChangeElement>`，`ChangeElement.BaseValue` **带符号**：负 = 消耗，正 = 产出）——**成本与产出共用一个类型**，因为「全有或全无、单点提交」本就要求二者落在同一事务内。`selectCost` / `skipCost` 在**物化时组装**（modifier pipeline 尚未施加，它在 `ProfileManager.TryApply` 那一刻才生效）。Source: `10-handoffs/2026-07-27b-service-api-contracts.md`。
- **`skipCost`（跳过成本 · 共有字段）+ `ifMandatory`（是否强制 · 共有字段）。** 二者共同定义一条**「跳过事件」通道**：面对一批 eventOptions，玩家除择一进入外，还可**付出 `skipCost` 跳过**某个事件；`ifMandatory = true` 的事件封死该通道（必须面对，不可跳过）。**`ifMandatory` 由 future-event-service 在产出 eventOptions 时动态置位**（而非内容作者在 `.tres` 写死），且**一批 eventOptions 可以全部为 mandatory**（等同本轮取消跳过权）。跳过后的完整玩法语义见下方「跳过通道的玩法语义」条目。Source: 同上 + `10-handoffs/2026-07-26-event-priority-skip-semantics-and-hotfix-scope.md`。
- **`eventPriority`（事件优先级 · 共有字段 · 已定案）。** AdventureEvent 的又一条重要共有属性，约束的是**同批 eventOptions 内的可选范围**：
  - **通常优先级为 0**——玩家可从本批中**任选所有优先级为 0 的事件**。
  - 本批一旦出现**优先级为 1（或更高）的一个或多个事件**，玩家就**必须优先从高优先级的事件中择一进入**，低优先级的事件本轮被封锁。
  - **有效可选集 = 本批中最高优先级档的全部事件**，同档内玩家仍自由择一（推演解读，待确认）。
  - 与 `ifMandatory` 是**两条不同的约束轴**：`ifMandatory` 封锁**跳过通道**（必须面对这一个），`eventPriority` 封锁**同批的其他选项**（必须先做这一类）。二者的叠加规则见待决问题。Source: `10-handoffs/2026-07-26-event-priority-skip-semantics-and-hotfix-scope.md`。
- **跳过通道的玩法语义（已定案）。**
  - **单项补位，不是整批刷新。** 一个事件被跳过后，由 **future-event-service 生成一个新事件顶替它的位置**；本批其余选项不动。
  - **补位可能落空。** 也可能没有新事件产出——此时本批 eventOptions 就**少了一个选项**（不回填、不阻塞）。
  - **通常不扣 `lifeSpanCost`（时间通常不流逝）。** 少部分事件可以带 `skipCost`，此时按其 element 扣减，寿元也可以是其中之一。
  - **跳过计入 `pastEvent`。** 被跳过的事件仍记入修行历程，作为一条**行为轨迹（类似 action-trace）**——记录「玩家做过什么决定」，而不仅是「玩家经历过什么事件」。因此 `pastEvent` 需能区分「已进入并结算」与「已跳过」两种痕迹。Source: `10-handoffs/2026-07-26-event-priority-skip-semantics-and-hotfix-scope.md`。
- **寿元消耗 `lifeSpanCost`（`selectCost` 成本类型的一个 element）。** 表示完成该事件对角色**寿元 / lifeSpan** 的扣减；它不是 AdventureEvent 上的独立平铺字段，而是**成本类型 `selectCost` 的组成 element 之一**（见上）。**默认（基准）为 -1**——即推进一个修行事件通常消耗 1 点寿元。个别事件可设更大 / 更小 / 正值（回寿）以体现代价差异。寿元由 life-cycle-service 在事件结算时按 `lifeSpanCost` 扣减，归 0 → `defeated`（大限将至）。`lifeSpanCost` 的基准值为可调平衡数值（见 `20-systems/balance.md`）。Source: `10-handoffs/2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md`。
- **稳定 Id。** 作为数据资源，每个 AdventureEvent 内容条目有稳定唯一的字符串 `Id`（供 eventOptions 引用、`pastEvent` 轨迹、存档 key points、注册表查找）。Source: `data-resource-rules.md`。

### 物化（materialize）：模板 `AdventureEventData` → 定稿实例 `EventOption`（已定案）

**`AdventureEventData : Resource` 是模板 / 素材，不是成品。** 它承载稳定 `Id`、`eventType`、静态展示文案、基准数值与**可变体的参数空间**、数据驱动的 outcome / effect 定义。**多数**具体属性由 **future-event-service 依情境物化产出**——目的是「按不同情境制造更多变化与风味」。`ifMandatory` / `eventPriority` 的动态置位只是这条规则的两个特例。Source: `10-handoffs/2026-07-27b-service-api-contracts.md`。

```
AdventureEventData(.tres)  ──▶  ContentRegistry 只读模板  ──▶  future-event-service 物化  ──▶  EventOption（定稿，immutable）
= 静态素材 / 参数空间              共享单例、可热更                情境代入                       只读消费，落存档
```

- **唯一物化点 = future-event-service。** 物化输入 = 模板（经 `AllEnabled()` 取池）+ CharacterProfile（含隐藏属性、修行历程）+ location 框定 + PlotManager 调制 + SeedManager 的 map 子流。
- **模板不可在运行时写。** `AdventureEventData` 是注册表里的**共享只读单例**且可被 overlay 热更覆写；写回它会污染同一轮回的后续批次与其他角色。
- **产出即定稿（finalized）。** `EventOption` 一经输出即冻结：life-cycle-service / combat-service / ViewModel 一律只读消费，**不得回查模板重算、不得改写其字段**。这保证「同一个事件在呈现、结算、记入历程三处看到的是同一份数据」。
- **定稿实例落存档，不重算。** 物化用了 seeded RNG、当时的角色状态、以及可热更的模板，确定性只在同一 `contentVersion` 内成立。因此**当前批 eventOptions 与 `pastEvent` 痕迹都存物化后的快照**。
- **`InstanceId` 与 `EventId` 并存：** 同一模板可在一次轮回里被物化多次，`pastEvent` / 事件负载 / 补位定位一律按 `InstanceId`。
- 字段骨架与完整论证见 `20-systems/services/future-event-service.md` 与 `20-systems/architecture.md`「总则 6」。

### 结算阶段：`eventStart` / `eventEnd` 是流程阶段名，不是资源上的方法（已定案）

**`eventStart` / `eventEnd` 是 `life-cycle-service.AdvanceEventAsync(...)` 内部结算流程的两个阶段名**，**不是 `AdventureEventData` 上的一对生命周期钩子**。Source: `10-handoffs/2026-07-27b-service-api-contracts.md`。

**为何不是资源上的方法：** 若钩子是 `Resource` 上的虚方法，**新增一个事件就要新建一个 C# 子类**——「新增内容 = 新增一个 `.tres`」的可加性直接失效；且 `Resource` 是注册表里的共享单例，在其方法里持有本次结算的中间态会跨事件泄漏。

落地为一个数据驱动的结算器，九类事件共**两个**实现：

```csharp
internal interface IEventResolver          // 按 eventType 注册
{
    Task<ResolveOutcome> ResolveAsync(EventOption option, CancellationToken ct);
}
// CombatEventResolver  → Combat / Finale，转 combat-service
// GenericEventResolver → 其余七类，读模板上的数据驱动 outcome / effect 定义
```

固定流程（权威见 `20-systems/services/life-cycle-service.md`）：

```
校验 mode 合法性（IsMandatory + Skip → 拒绝；Priority < EffectivePriority → 拒绝）
  → TryApply(SelectCost | SkipCost)          ← 付不起则拒绝，不产生任何写入
  → 【eventStart 阶段】选 resolver、Mystery 揭示
  → resolver.ResolveAsync(option, ct)
  → 【eventEnd 阶段】合并 ResolveOutcome + lifeSpanCost + 隐藏属性推拉为**一次** TryApply
  → 记入 pastEvent（按 InstanceId，携带定稿实例快照）
  → 终态判定 → EventBus 广播 → 自动存档点
```

由此职责边界完全明确：**扣成本、推拉隐藏属性、写 CharacterProfile 全部由 life-cycle-service 经 `profile-service.ProfileManager` 完成**（一个事件 = 一次事务 = 一个存档点）；resolver 只**描述**结果（`ResolveOutcome`），不自行写档。

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

- **`EventOption` 的完整物化字段清单未定（07-27b 新增）：** 骨架九字段已定（见 `future-event-service.md`）；但「**多数**属性由物化决定」意味着还有一批未列出的字段——哪些数值可被情境改写？风味文案是否也物化？outcome 权重是否在物化时固化？需要一次**内容侧** handoff。Source: `10-handoffs/2026-07-27b-service-api-contracts.md`。
- **`pastEvent` 的痕迹 schema 与 key points 粒度：** 持久化**方式**已定案（落物化后的定稿实例快照，按 `InstanceId` 索引，不重算）；仍待定：如何**区分「进入并结算」与「跳过」两种痕迹**及各自付出的成本、快照存哪些字段、与 AdventurePlot key points 的耦合方式、以及**快照体积对增量 push 粒度的影响**。→ 亦见 `20-systems/services/future-event-service.md`、`plot-manager.md`、`sync-service.md`。Source: 同上。
- **可用事件的生成规则：** future-event-service 如何具体产出「下一批 eventOptions」（数量、类型配比、刷新时机、location + AdventurePlot 叠加顺序）未定。→ 亦见 `20-systems/game-progression.md`。
- **成本类型的 element 清单未定。** `selectCost` 为定制复合成本类型、`lifeSpanCost` 为其一个 element 已定案；**其余有哪些 element**（jade？mana？道具？隐藏属性推拉？）、每个 element 的数据形态（固定值 / 区间 / 公式）、以及**付不起某个 element 时的判定规则**（整体不可选？部分抵扣？）均未定。→ `20-systems/character-profile/currency.md`、`20-systems/balance.md`。Source: `10-handoffs/2026-07-25b-event-cost-fields-capability-flags-and-service-hierarchy.md`。
- **`eventPriority` 与 `ifMandatory` 的叠加规则未定：** 一个高优先级事件**能否被跳过**？若可跳过且被跳过，本轮是否解除对低优先级事件的封锁？二者都限制玩家选择权，是否存在语义重叠（高优先级是否应蕴含 mandatory）？→ `20-systems/services/future-event-service.md`。Source: `10-handoffs/2026-07-26-event-priority-skip-semantics-and-hotfix-scope.md`。
- **`eventPriority` 的取值域与置位方未定：** 优先级是两档（0 / 1）还是任意整数档位？是否与 `ifMandatory` 一样由 future-event-service / PlotManager 在产出时动态置位（用户仅明确了 `ifMandatory`）？Source: 同上。
- **跳过语义的残留细节：** 主干已定（单项补位 / 通常不扣寿元 / 计入 `pastEvent`）；仍待定：**能否整批全跳**、**付不起 `skipCost` 时如何表现**。→ `20-systems/services/future-event-service.md`。Source: 同上。
- **全部 mandatory + 付不起 `selectCost` 的死锁：** 一批可以全部 mandatory，且高优先级会封锁其余选项；若玩家付不起唯一可选事件的 `selectCost`，轮回将无法推进。是否需要产出侧「至少一个可负担选项」的保证，或一条兜底降级？→ `20-systems/services/future-event-service.md`。Source: 同上。

## 对应
提炼至：`.claude/knowledge/systems/adventure-event/common-properties.md`（待建）
