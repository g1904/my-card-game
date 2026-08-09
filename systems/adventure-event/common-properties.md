# adventure-event / common-properties（AdventureEvent 顶层共有属性）

> 所有 AdventureEvent 子类型共有的属性 / 字段与通用流程。各子类型专有属性见其各自的 `common-properties.md`。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

### 共有属性 / 字段

- **AdventureEvent 之间不存在前后连边。** 单个 AdventureEvent 只是一份自足的内容条目，**不持有指向后续事件的引用**——事件之间的走向不由内容作者预先连线，而由 **future-event-service 在运行时依角色状态产出的一批 `List<EventOption> eventOptions`** 决定：受角色当前 location（地域）框定，并被隐藏剧本层 AdventurePlot 持续调制（见 `systems/services/future-event-service.md`、`systems/services/plot-manager.md`）。Source: `terminology.md` + `handoffs/2026-07-24-docs-restructure-class-model.md` + `handoffs/2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md`。
- **`pastEvent`（历程轨迹 · CharacterProfile 侧）。** 与向前的走向相对，向后的**已经历轨迹**仍需持久化：`pastEvent` 是一条**扁平的时序列表**（不是图的反向边），记录角色走过哪些事件。它归属 CharacterProfile 的轮回状态，不挂在 AdventureEvent 上。**只有一种痕迹：进入并结算**——跳过通道已整体移除（见下方「一批只有一次操作」）。条目类型 `PastEventEntry` 与字段表见下方「`pastEvent` 的痕迹 schema」。
- **`eventType`（类型标签 · 子类型枚举）。** 每个 AdventureEvent 带一个 `eventType` 字段，归属九类之一（Combat / Finale / Mystery / Practice / Exchange / Research / Explore / Social / Travel）。Mystery 为元类型，遮罩一个固定的其余某类事件——被遮罩事件的真实 `eventType` 在揭示前对玩家不可见。Source: `terminology.md` + `handoffs/2026-07-25b-event-cost-fields-capability-flags-and-service-hierarchy.md`。
- **`selectCost`（选择成本 · 共有字段）= 一个定制的复合成本类型（已定案）。** 选中该 AdventureEvent 以推进轮回所需付出的代价。`selectCost` **不是单一数值，而是一个定制类**——它由**若干成本 element 组成**，**`lifeSpanCost` 是其中一个 element**。因此一个事件的选择代价可以同时涉及多种资源（寿元 + 其他），由该成本类型统一承载，而非在 AdventureEvent 上平铺一堆并列的成本字段。它把「从 eventOptions 中推进」建模为一次**付费的取舍**，而非单纯的菜单点选——契合月圆之夜式事件菜单的策划取向。Source: `handoffs/2026-07-25b-event-cost-fields-capability-flags-and-service-hierarchy.md`。
  - **`lifeSpanCost`（成本 element）：** 完成该事件对角色**寿元 / lifeSpan** 的扣减，由内容作者以**正数量值**标注；见下方独立条目。
  - **支付 `selectCost` 是无条件的可推进行为（已定案 · 08-06c · 承重 · 推翻「付不起则拒绝」）。** 选中一个事件时，`selectCost` **照常施加，不因「付不起」被拒绝**；**支付之后做状态判定，判负则进入既有的失败流程**（寿元归 0 → 「大限将至」→ `defeated`）。
    - **推翻的明文：** `AdvanceEventAsync` 流程里的「`TryApply(SelectCost)` ← 付不起则拒绝，不产生任何写入」以及 `program-overview.md` 阶段 4 的「付不起 → 拒绝，回到呈现步」——**这条回路整体删除**。
    - **推论 ①（承重）：「付不起唯一可选项 ⇒ 轮回无法推进」这个死锁在规则层不成立**，且**不是靠产出侧保证闭合的**——future-event-service 不欠 `selectCost` 侧任何可负担性保证（与「不给可战胜保证」同一种收口：不给保护，给出口）。
    - **推论 ②：终态由支付后的状态判定给出，而不是由「付不起」这个事实给出。** 支付后未必死——付寿元才可能触发终态，付非终结性资源只是变穷。
    - **推论 ③：「付不起」在事件选择面整体消失。** UI **不需要不可选 / 置灰态**，但**必须如实展示 `selectCost`**：让玩家能自己算出「这一步可能是最后一步」。**明知是死路仍然走**是有意义的玩家决策，与「打不过也得打」同构。
    - **事务性不变、可负担性校验去掉。** `ProfileManager.TryApply` 仍是全有或全无的单点提交；变的只是它不再为事件推进做「先校验付得起、否则整体拒绝」。**负值施加时各资源的钳制规则待定**，见待决问题。
    Source: `handoffs/2026-08-06c-skip-channel-removal-priority-two-tier-and-location-codex-edges.md`。
  - **代码形态 = `ProfileChangeSpec`（已定案）。** 该复合成本类型即 `ProfileChangeSpec`（`IReadOnlyList<ChangeElement>`，`ChangeElement.BaseValue` **带符号**：负 = 消耗，正 = 产出）——**成本与产出共用一个类型**，因为「全有或全无、单点提交」本就要求二者落在同一事务内。`selectCost` 在**物化时组装**（modifier pipeline 尚未施加，它在 `ProfileManager.TryApply` 那一刻才生效）。Source: `handoffs/2026-07-27b-service-api-contracts.md`。
  - **内容侧写正数量值，spec 里仍是负数（已定案 · 两条约定各自成立）。** 带符号约定**不变**；但**内容作者标注的成本一律是正数量值（magnitude）**——「这个事件耗 3 点寿元」写 `3`，不写 `-3`。**取负发生在 future-event-service 物化组装 `selectCost` 的那一刻**（见 `systems/services/future-event-service.md`）。二者互不推翻：作者面对的是「花多少」，`TryApply` 面对的是带符号 element。Source: `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。

    | 层 | 形态 |
    |----|------|
    | `AdventureEventData.tres` / 平衡分档表 | **正数量值** |
    | `EventOption.SelectCost` 内的 `ChangeElement.BaseValue` | **取负**（`-magnitude`） |
    | `ProfileManager.TryApply` | 照常按带符号 element 施加 |
- **一批只有一次操作：择一进入。跳过通道整体不存在（已定案 · 08-06c · 承重 · 推翻既有的跳过建制）。** 面对一批 eventOptions，玩家**唯一能做的事就是选中其中一个进入**——**没有跳过（skip）这条通道**，`skipCost` 与 `ifMandatory` 两个字段随之**整体删除**。
  - **理由 = 跳过本就是冗余机制。** **每完成一次选择，eventOptions 无论如何都会整批重算**；因此**选中某一个事件本身就等价于跳过了同批其余全部事件**。跳过通道只是把「不做这件事」额外做成了一个要付费、要留痕、要补位的独立机制，而玩家早已通过「选别的」得到同样的结果。
  - **它承载的设计意图不但没丢，反而更强：** 「每批必有不可跳过项、打不过也得打」**升级为结构性事实**——**本批的每一项都是必做项**，回避通道在规则层根本不存在，**不需要字段来表达它**。
  - **单项补位（`TryRefill`）随之删除。** 补位只为「被跳过的那个位置空了」而存在；没有跳过就没有空位。**批次刷新只剩一种形态：一次选择 → 整批重算。**
  - **推论（一次删掉五处结构）：** `EventOption` 九字段 → **七字段**（删 `IsMandatory` / `SkipCost`）· `EventOptionBatch` 删 `AnySkippable` 与「每批至少一个 `IsMandatory`」的恒真不变式 · `AdvanceMode { Select, Skip }` **整个枚举删除**（`AdvanceEventAsync` 少一个参数、`EventResolved` 负载少一个字段）· future-event-service 的 API 面五方法 → **四方法** · `CapabilityFlag` 删 `ShowSkipCost`、modifier key 清单删 `skipCost`。
  - **推论：`pastEvent` 只剩一种痕迹**（进入并结算）——「区分两种痕迹」这个 schema 难题直接消解。**未被选中的选项随批次归档轻摘要**（已定案 · 08-09c），见下方「`pastEvent` 的痕迹 schema」。
  - **推论：跳过侧的两条产出侧保证作废**（不生成付不起 `skipCost` 的事件 / 不生成整批全跳的批次）——前提消失。
  - **推论：「跳过什么类型的事件反向影响剧本」这条内容侧方向改变形态、并未作废（08-09c 收窄）。** 「回避了什么」不再是一个**独立的玩家操作**，而是选择的**补集**——由 `PastEventEntry.Unchosen`（同批未选项轻摘要）承载，剧本照常读得出「同批还摆着什么而没选」。见下方「`pastEvent` 的痕迹 schema」。
  Source: `handoffs/2026-08-06c-skip-channel-removal-priority-two-tier-and-location-codex-edges.md`。
- **`eventPriority`（事件优先级 · 共有字段 · 已定案 · 08-06c 定形）。** **唯一**约束玩家选择权的字段，约束面是**同批 eventOptions 内的可选范围**：
  - **取值域只有两档：`0`**（常态——玩家可从本批中任选）与 **`1`**（本批一旦出现，**有效可选集收窄为该档**，`0` 档本轮被封锁）。
  - **有效可选集 = 本批中最高优先级档的全部事件**，同档内玩家自由择一。
  - **置位方唯一 = future-event-service，在物化时置位；PlotManager 不得改变它。** **推论（边界澄清 · 承重）：PlotManager 只调内容不调约束**——它能影响哪些事件进池、以什么权重出现，但**不能通过抬优先级强制玩家做某件事**；剧本要表达强制性，只能靠**把候选池收窄**（整批只出这一类）。这是更诚实的表达：玩家看到的仍是一批可选项，而非一个被系统钉死的选项。
  - **推论：两档 ⇒ 不存在「优先级 2 压过优先级 1」的层叠语义。** Travel 闸门用的「最高优先级」就是 `1`，与剧情线的强制事件**共用同一档**——两者同批出现时玩家在它们之间自由择一。
  Source: `handoffs/2026-07-26-event-priority-skip-semantics-and-hotfix-scope.md` + `handoffs/2026-08-06c-skip-channel-removal-priority-two-tier-and-location-codex-edges.md`。
- **寿元消耗 `lifeSpanCost`（`selectCost` 成本类型的一个 element）。** 表示完成该事件对角色**寿元 / lifeSpan** 的扣减；它不是 AdventureEvent 上的独立平铺字段，而是**成本类型 `selectCost` 的组成 element 之一**（见上）。**内容侧以正数量值书写**（`1` = 消耗 1 点寿元），物化时取负。寿元由 life-cycle-service 在事件结算时按 `lifeSpanCost` 扣减，归 0 → `defeated`（大限将至）。
  - **定价是时长旋钮，不是固定基准（已定案）。** 先前记载的「基准 1」**只是占位值，不是设计意图**。真正的设计判据是**目标游玩时长**：第一 / 第二篇章各 **15–30 分钟**、第三篇章 **20–40 分钟**——**寿元预算不变，靠调 `lifeSpanCost` 把时长压回区间**（第三篇章预算 +300 远多于前两章，故定价相应**大幅上调**）。事件之间定价有差异（如**闭关 Research 比常规事件耗时更长**）。**具体分档表待定**，见 `systems/balance.md`。Source: `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。
  - 个别事件可设更小或**产出向**（回寿）的数值以体现代价差异——产出向的写法遵循同一约定（内容侧写量值，语义由字段方向承载）。
- **稳定 Id。** 作为数据资源，每个 AdventureEvent 内容条目有稳定唯一的字符串 `Id`（供 eventOptions 引用、`pastEvent` 轨迹、存档 key points、注册表查找）。Source: `data-resource-rules.md`。

### 物化（materialize）：模板 `AdventureEventData` → 定稿实例 `EventOption`（已定案）

**`AdventureEventData : Resource` 是模板 / 素材，不是成品。** 它承载稳定 `Id`、`eventType`、静态展示文案、基准数值与**可变体的参数空间**、数据驱动的 outcome / effect 定义。**多数**具体属性由 **future-event-service 依情境物化产出**——目的是「按不同情境制造更多变化与风味」。`eventPriority` 的动态置位只是这条规则的一个特例。Source: `handoffs/2026-07-27b-service-api-contracts.md`。

```
AdventureEventData(.tres)  ──▶  ContentRegistry 只读模板  ──▶  future-event-service 物化  ──▶  EventOption（定稿，immutable）
= 静态素材 / 参数空间              共享单例、可热更                情境代入                       只读消费，落存档
```

- **唯一物化点 = future-event-service。** 物化输入 = 模板（经 `AllEnabled()` 取池）+ CharacterProfile（含隐藏属性、修行历程）+ location 框定 + PlotManager 调制 + SeedManager 的 map 子流。
- **模板不可在运行时写。** `AdventureEventData` 是注册表里的**共享只读单例**且可被 overlay 热更覆写；写回它会污染同一轮回的后续批次与其他角色。
- **产出即定稿（finalized）。** `EventOption` 一经输出即冻结：life-cycle-service / combat-service / ViewModel 一律只读消费，**不得回查模板重算、不得改写其字段**。这保证「同一个事件在呈现、结算、记入历程三处看到的是同一份数据」。
- **定稿实例落存档，不重算。** 物化用了 seeded RNG、当时的角色状态、以及可热更的模板，确定性只在同一 `contentVersion` 内成立。因此**当前批 eventOptions 与 `pastEvent` 痕迹都存物化后的快照**。
- **`InstanceId` 与 `EventId` 并存：** 同一模板可在一次轮回里被物化多次，`pastEvent` / 事件负载一律按 `InstanceId` 定位。
- 字段骨架与完整论证见 `systems/services/future-event-service.md` 与 `systems/architecture.md`「总则 6」。

### 结算阶段：`eventStart` / `eventEnd` 是流程阶段名，不是资源上的方法（已定案）

**`eventStart` / `eventEnd` 是 `life-cycle-service.AdvanceEventAsync(...)` 内部结算流程的两个阶段名**，**不是 `AdventureEventData` 上的一对生命周期钩子**。Source: `handoffs/2026-07-27b-service-api-contracts.md`。

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

固定流程（权威见 `systems/services/life-cycle-service.md`）：

```
校验选项合法性（Priority < EffectivePriority → 拒绝）
  → TryApply(SelectCost)                     ← 无条件施加；不做「付得起」校验
  → 终态判定 ①（支付后立即）                 ← 判负 → 短路进失败流程，不再进入 resolver
  → 【eventStart 阶段】选 resolver、Mystery 揭示
  → resolver.ResolveAsync(option, ct)
  → 【eventEnd 阶段】合并 ResolveOutcome + lifeSpanCost + 隐藏属性推拉为**一次** TryApply
  → 记入 pastEvent（按 InstanceId，携带定稿实例快照）
  → 终态判定 ②（结算后）→ EventBus 广播 → 自动存档点
```

**终态判定有两处（08-06c）：** ① 紧接 `TryApply(SelectCost)` 之后——支付本身可能耗尽寿元，此时**短路进失败流程**，事件不再结算；② 事件结算后照常判定。这是「支付 `selectCost` 是可推进行为、支付后判定状态」的直接落地。

由此职责边界完全明确：**扣成本、推拉隐藏属性、写 CharacterProfile 全部由 life-cycle-service 经 `profile-service.ProfileManager` 完成**（一个事件 = 一次事务 = 一个存档点）；resolver 只**描述**结果（`ResolveOutcome`），不自行写档。

**隐藏属性的跨档定性反馈挂在 `eventEnd`（已定案 · 无新结构）。** 隐藏属性推拉在 `eventEnd` 阶段合并施加；**当某个隐藏属性因本次推拉而跨过一个隐藏档位时，附带一条定性的叙事描述**（不给数字）。它**复用已有的 `ResolveOutcome` → `eventEnd` 链路**，不引入新的结构或阶段。触发规则与档位归 `systems/services/plot-manager.md`，呈现归 `ux/screen-flow.md`。Source: `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。

### `pastEvent` 的痕迹 schema（已定案 · 08-09c）

**判据先于字段表：「重算不出来的存，重算得出来的不存」。**

> 凡「模板 + `EventId` 在任意 `contentVersion` 下都能稳定重建」的，**不进快照**；凡「由本次物化的情境 / seeded RNG / 当时角色状态决定，重建不出同一结果」的，**必进快照**。

**判据本身是这条设计的权威，字段表只是它当下的投影**——字段表会随「`EventOption` 完整物化字段清单」继续增长，判据不会。由它自动落定四条：

- **静态展示文案（显示名 / 描述 / 图标）不进快照**，按 `EventId` 经 `ContentRegistry.Get()` 随时取得（读取侧不过滤 `ContentEnabled`，被关闭的条目照常解析）。**文案改版不触发存档迁移**这条既有收益因此保住。
- **风味文案同样不进快照** —— 它跟随模板数据，与显示名 / 描述属同一层。**由此判据两侧再无灰色地带：所有文本类字段一律留在模板侧，快照里一个字符串正文都不存。**（这同时收窄了「`EventOption` 完整物化字段清单」那条待决问题的文本那一半，见下。）
- **模板上的基准数值、参数空间、outcome / effect 定义不进快照** —— 本次掷定的结果已经在 `AppliedChange` 里，存权重表等于存一份用不上的中间态。
- **物化产出的数值必进快照** —— `SelectCost`、`Priority`、Mystery 真身、敌人赋级正是「重算不保证同结果」的那一半。

**「定稿实例必须落存档」与「存档态只带 `Id` + 可变状态、不复制展示文本」不冲突**（写明以免日后被误当成矛盾去松动其中一条）：后者管**展示文本**，前者管**物化数值**，快照存后者不存前者，两条同时成立。唯一可能让它们正面相撞的条件是「风味文案也物化」，而文案不物化，该条件不成立。

**痕迹条目 ≠ `EventOption`，而是「定稿实例快照 + 本次结算的最终账」。** 一个事件的权威事实是 `eventEnd` 那**一次**合并 `TryApply` 的 spec，而非分散在 `ResolveOutcome` / `lifeSpanCost` / 隐藏属性推拉里的若干片段——**存最终 spec 一份，胜过存若干片段再让读取方自己合**。

```csharp
public sealed record PastEventEntry(          // 痕迹条目：immutable，只追加，落存档
    int                Seq,                   // 角色内单调递增的时序坐标；不复用、不因迁移重排
    string             InstanceId,            // 定位键；与被结算的那个 EventOption 同值
    string             EventId,               // 溯源模板（disabled 条目照常解析）
    EventType          EventType,             // 当时呈现给玩家的类型；Mystery 时 = 遮罩类型
    string             RevealedEventId,       // Mystery 真身；非 Mystery 为空串
    int                Priority,              // 当时的物化置位 { 0, 1 }；回溯「这一步是不是被闸门收窄的」
    string             BatchId,               // 归属批次；与未选项摘要同批
    string             LocationId,            // 当时所在地域
    ProfileChangeSpec  SelectCost,            // 物化组装的定稿 spec（带符号，已取负）
    ProfileChangeSpec  AppliedChange,         // eventEnd 那一次合并 TryApply 的最终 spec
    EventOutcome       Outcome,               // 结算走向
    int                LifeSpanAfter,         // 结算后剩余寿元 —— 判据的明示例外，见下
    IReadOnlyList<UnchosenOptionRef> Unchosen // 同批未被选中的选项轻摘要
    /* ⟨随「EventOption 完整物化字段清单」与「敌人实例类型形态」两项答定后扩充；
        文本类字段不在扩充范围内 —— 风味文案跟随模板⟩ */);

public sealed record UnchosenOptionRef(       // 未选项：只求可回溯，不求可重建
    string    InstanceId,
    string    EventId,
    EventType EventType,
    int       Priority);

public enum EventOutcome { Resolved, CombatWon, CombatLost, Aborted }
// Resolved               = 非战斗类事件正常结算
// CombatWon / CombatLost = 战斗类事件的胜负（剧本与履历都要读，且不可由 AppliedChange 可靠反推）
// Aborted                = 支付 SelectCost 后终态判定 ① 即短路，事件未进入 resolver
```

- **`AppliedChange` 是核心，也是唯一真正新增的东西。** 有了它，「这个角色一路上到底发生了什么」是一条可直接重放的账；没有它，履历 / 剧本 / 诊断三个消费方各自去猜。它**复用既有的 `ProfileChangeSpec`，不引入新类型**。
- **`Seq` 是时序坐标，不是内容键。** 「绝不用数组索引作内容的键」约束的是内容键；`Seq` 显式写出来才能在日志、履历展示与诊断中安全提及。角色内单调递增、不复用、不因迁移重排。
- **`LifeSpanAfter` 是上述判据的明示例外。** 它可由 `AppliedChange` 全序列重放得出，按判据本不该存；但它**已在 `EventResolved` 负载里**（`LifeSpanRemaining`），且元进程的角色履历要画寿元曲线。**成本 4 字节 × 200 条 = 800 字节，换掉一次全序列重放。** 它是**写明的例外，不是先例**——不得据此放宽判据。
- **`Aborted` 是跳过通道移除后的直接产物。** 支付 `selectCost` 后立即判负会短路、事件不再结算，但**这一步仍然发生过**（成本已施加、`selectCost` 不回滚），必须留痕且必须与正常结算可区分——否则履历上会出现一条「结算了但什么也没产出」的诡异记录。它通常是角色的**最后一条**痕迹。
- **枚举保持四值，不为 DnD 式选分支预留成员。** 分支形态未定时预留即臆造；日后若需要，是**新增一个可空字段**（`ChosenBranchId`），不是改枚举——**枚举成员的增删牵动存档迁移，可空字段不牵动**。

**未被选中的选项 = 归档轻摘要（已定案）。** 论证基础是一条推演：**「定稿实例必须落存档」对未选项不成立**——该条的理由是「重算不保证同结果，而这份实例还要被消费」，而未选项在下一次整批重算时即被丢弃，**永远不会被任何流程消费**；它们不需要**可重建**，只需要**可回溯**。剧本要的信号是「玩家回避了什么类型 / 什么内容」，`EventType` + `EventId` 就足够；未选项的 `SelectCost` 永不会被施加，敌人实例永不会入场。

| | 方案 | 单事件增量 | 剧本可读出 | 结论 |
|---|------|-----------|-----------|------|
| A | 不归档 | 0 | 只有「选了什么」 | 否决：回避信号**永久丢掉**，日后想补要改 schema + 迁移 |
| **B** | **归档轻摘要**（四字段） | **~4 × 60 B ≈ 240 B** | 「选了什么」+「同批还摆着什么而没选」 | **采纳** |
| C | 归档完整快照 | ~4 × 500 B ≈ 2 KB | 同 B（多出字段无消费方） | 否决：体积翻数倍换零新增信息 |

**副产品：批次的完整性得以保留。** `pastEvent` 不再是一串孤立事件，而是一串**批次**——「这一步你面前摆着这四个，你选了第二个」。这对元进程的角色履历展示与日后的「回放 / 复盘」都是免费的地基。

**与 AdventurePlot key points：单向读取、零结构耦合。** `pastEvent` 不持有任何 key point 引用，key points 也不引用 `PastEventEntry`；PlotManager 只把 `pastEvent` 当只读输入。**推论：`pastEvent` 的 schema 不受「key points 粒度」这个待答项阻塞，两者各自定稿。** 详见 `systems/services/plot-manager.md`。

**存档与校验：**

- **本次落定 `pastEvent` 结构 → bump 存档 schema 版本**；当前无线上存档 → **空迁移**，走既有 MigrationManager 骨架。只追加不变式与体积护栏见 `systems/services/sync-service.md`。
- **加载时校验：** `EventId` 经 `ContentRegistry` 解析不到 → **可选缺失** → `GD.PushWarning` + 该条降级为「仅标识可读」（履历显示为未知条目），**不阻断读档**——历程是历史记录，一条读不出的旧条目不该让整个角色无法进入。`InstanceId` 缺失 / `Seq` 不连续 / `Seq` 重复 → **必需缺失** → `GD.PushError` 带 `characterId` + `seq`。
- **写入点不新增。** 上方结算流程里「记入 `pastEvent`」这一步的语义具体化为：**由 life-cycle-service 组装 `PastEventEntry`（含从被替换的当前批取未选项摘要），经 `profile-service.ProfileManager` 写入**——与「档案写入的唯一入口」一致，不绕过。

Source: `handoffs/2026-08-09c-past-event-trace-schema.md`。

### 通用流程

- **呈现 = 月圆之夜风格（已定案）。** 修行事件以精心策划的**事件菜单**形态呈现，参考《月圆之夜》。Source: `handoffs/2026-07-22-online-cloud-combat-and-meta-clarifications.md`。
- **选择 = 横向滑动选择区（已定案）。** 「从可用修行事件（eventOptions）中选择」用一个**可横向滑动的选择区**（horizontal scrolling area），滑动选中目标 AdventureEvent。详见 `systems/game-progression.md`。Source: `handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。
- **进入。** 玩家在选择区选中一个可用 AdventureEvent 后进入该事件；Mystery 在进入时揭示其被遮罩的固定事件。Source: `terminology.md`。
- **结算与后果。** 事件结束后其后果影响玩家及未来状态（隐藏属性推拉、eventOptions 重算、location 刷新等）；结算规则因子类型而异——**Combat / Practice / Finale 走战斗结算**（同一回合循环与参战方结构，独立的胜负条件与奖惩），其余六类为事件式结算。
- **自动存档边界。** 事件为合理的自动存档点之一（每场遭遇战 / 地图节点之后）。Source: `state-save-rules.md`。

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- **呈现形态、选择交互** 已定案，见「意图」及 `decisions/ADR-0002-adventure-event-taxonomy.md` 上下文。
- **`pastEvent` 痕迹 schema（`PastEventEntry` + 判据 + 未选项轻摘要）** 已定案，见「意图」的同名小节。**ADR 候选**（它同时约束存档 schema、同步粒度与剧本读取面）。Source: `handoffs/2026-08-09c-past-event-trace-schema.md`。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **`EventOption` 的完整物化字段清单未定（07-27b 新增 · 08-06c 收窄为七字段 · 08-09c 再收窄）：** 骨架**七字段**已定（见 `future-event-service.md`）；但「**多数**属性由物化决定」意味着还有一批未列出的字段——哪些数值可被情境改写？outcome 权重是否在物化时固化？需要一次**内容侧** handoff。**「风味文案是否也物化」这一半已答结：不物化，跟随模板数据** ⇒ **剩余分叉只在数值与结构字段上，不含任何文本类字段**。Source: `handoffs/2026-07-27b-service-api-contracts.md` + `handoffs/2026-08-09c-past-event-trace-schema.md`。
- **可用事件的生成规则：** future-event-service 如何具体产出「下一批 eventOptions」（数量、类型配比、刷新时机、location + AdventurePlot 叠加顺序）未定。→ 亦见 `systems/game-progression.md`。
- **成本类型的 element 清单未定（08-06c 收窄）。** `selectCost` 为定制复合成本类型、`lifeSpanCost` 为其一个 element 已定案；**其余有哪些 element**（jade？mana？道具？隐藏属性推拉？）、每个 element 的数据形态（固定值 / 区间 / 公式）未定。**「付不起某个 element 时整体不可选」这一问已作废**——支付无条件发生；取而代之的新问是**打穿之后怎么办**，见下条。→ `systems/character-profile/currency.md`、`systems/balance.md`。Source: `handoffs/2026-07-25b-event-cost-fields-capability-flags-and-service-hierarchy.md` + `handoffs/2026-08-06c-skip-channel-removal-priority-two-tier-and-location-codex-edges.md`。
- **哪些资源允许被打穿、各自的截断与终态判据（08-06c 新增 · 承重）：** `selectCost` 无条件施加后必须回答——寿元归 0 = `defeated` 已定；**灵玉 / mana / 其余 element 打到负数怎么办**（截断到 0？允许为负？）、哪些资源的耗尽构成终态、哪些只是变穷。这直接决定 `ProfileManager.TryApply` 施加负值时的钳制规则。→ `systems/services/profile-service.md`、`systems/character-profile/currency.md`。Source: 同上。
- **「余额不足即拒」还剩哪些消费点（08-06c 新增）：** 事件推进路径已不需要它；Exchange 内的商店购买等主动消费点是否仍需？若全都不需要，`AdvanceResult.CostRejected` / `MissingElement` / `CanAfford` 可整体删除。→ `systems/services/profile-service.md`、`life-cycle-service.md`。Source: 同上。
- **`Priority` 字段是否从 `int` 退化为 `bool`（08-06c 新增 · 轻）：** 语义已定为两档；保留 `int` 是留扩展余地，改 `bool` 是让类型说实话。Source: 同上。
- **各篇章 `lifeSpanCost` 的具体分档表：** 定价方向已定（目标时长驱动、逐篇章上调、闭关更耗）；仍待定**哪些事件类型多耗、单次幅度各是多少**——需以 15–30 / 15–30 / 20–40 分钟反推。→ `systems/balance.md`。Source: `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。

## 对应
提炼至：`.claude/knowledge/systems/adventure-event/common-properties.md`（待建）
