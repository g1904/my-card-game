---
type: solution-draft
date: 2026-08-16
question: AdventurePlot 树用什么数据表达（调制还是并行结构）、key points 的粒度与 schema、剧本内容类型是不是 `XxxData : Resource`，以及「新增剧本条目不得引用本次 overlay 之外的新 `Id`」如何可机械检查。
source: open-questions/04-hidden-attributes-plot.md → 「AdventurePlot 数据编码与 key points 粒度」+「剧本内容类型的数据形态」两条（同题条目另见 systems/services/plot-manager.md#待决问题 与 systems/services/content-service.md#待决问题「剧本例外的可执行化」）
targets: systems/services/plot-manager.md · systems/services/content-service.md · systems/character-profile/_index.md · systems/services/future-event-service.md · systems/architecture.md · systems/balance.md · systems/common-properties.md
status: distilled
reviewed: 2026-08-16 —— 用户在评审阶段裁定三项取向（并发上限 2 · 排队不丢弃 · 不持久化分支路径 · 扩写可执行化阶梯）；提炼时另经 interview 裁定两项：arc 参与 flags 放量（改写后端契约）· 排队 arc 落存档（`PlotArcState` 加 `Queued`）。
distilled-to: handoffs/2026-08-16i-plot-data-encoding.md
decided: 2026-08-16 —— 三项取向**全部按推荐裁定**（side arc 并发上限 2 · 排队不丢弃 · 不持久化已走分支路径 · 扩写可执行化阶梯以容纳内容侧纪律）。全文已按裁定改写为单一方案，不再保留并列选项。
---

# 方案草稿 — 剧本数据编码、key points schema 与剧本内容类型形态

## 问题

AdventurePlot 的**语义面已大量定案**（四级层级 · 隐藏属性驱动 · 档位表与 `PlotTriggerId` · 纯本地内容层 · overlay 可为剧本新增 `Id` · 悬空 key point 走 `PushWarning` + 叙事降级 · key point 与 `InstanceId` 零结构耦合），但**它的数据面整条是空的**，三处相连的空缺互为前置：

1. **树怎么表达。** AdventurePlot 是**调制** eventOptions，还是一套与 future-event-service 并行的产出结构？树的节点 / 边 / 推进条件用什么承载？
2. **key points 是什么粒度、什么 schema。** 存档里那几条锚点长什么样，才能同时满足两条硬约束（不引用 `InstanceId` · 剧本节点缺失时可安全跳过）。
3. **剧本条目是不是 `XxxData : Resource`。** 若是，则合并后强校验对它生效，「新增剧本条目不得引用本次 overlay 之外的新 `Id`」这条约束**需要一个可机械检查的形态**（按「纪律的可执行化」选级判据，它属**能上线且线上不可见**）。

三者卡住的下游：`PlotSegment` 的字段（`plot-manager.md` 明写 ⟨待定⟩ 依赖第 3 条）· `CharacterProfile` 的 key points 字段 schema · content-service 的「剧本例外的可执行化」待答项 · PlotManager 四个方法中的三个的实现形态。

## 约束（来自既有设计）

- **PlotManager 纯本地、永不跨进程边界；全部方法为形态 A。** 剧本内容随 `res://` 基线 + overlay 落地，**不存在「取不到剧本」这一失败态**；不设事务前置、不设 `user://cache/plot/`、不设 `IPlotBackend`。→ `systems/services/plot-manager.md`
- **PlotManager 只调内容不调约束（承重）。** `eventPriority` 的置位方唯一 = future-event-service，PlotManager **不得**抬优先级；**剧本的强制性只能靠把候选池收窄表达**。→ `systems/services/future-event-service.md`
- **PlotManager 对敌人的权力收敛为三项：框定用哪个池 · 偏移带内赋级权重 · 拧紧遭遇参数。它碰不到模板的任何字段。** 赋级 `±2` 带是无例外硬规则，赋级函数不接受区间覆盖参数。→ 同上
- **事件之间不存在预先编好的前后连边；「下一步能去哪」是运行时算出来的。** 唯一物化点 = future-event-service，唯一出口亦然。→ 同上
- **key point 不得引用 `InstanceId`**（内容条目不得隐式依赖存档的运行时标识空间）；**必须能在其引用的剧本节点缺失时被安全跳过**，不得设计成「解析失败即无法确定当前剧本位置」的形态。→ `systems/services/plot-manager.md`
- **overlay「只改不增」的唯一例外是剧本类型**，边界两条：只覆盖剧本内容类型本身 · **新增剧本条目不得引用本次 overlay 之外的新 `Id`**。**状态转换触发的定性文案（跨档叙事、Finale 补白）明确不在例外内、照旧只改不增。** → `systems/services/content-service.md`
- **内容条目通则：** `[GlobalClass] XxxData : Resource` + 稳定 `Id` + `ContentEnabled` + 静态展示文本用 `LocalizedText`（`zh` 缺失 → `PushError`）；产出侧经 `AllEnabled()` 取池、读取侧 `Get(id)` 不过滤；坏数据启动期 `PushError`。→ `systems/common-properties.md`、`systems/services/content-service.md`
- **`HiddenStatBandData` 的先例：** 「查表读取」类内容走 `AllIncludingDisabled()`、`ContentEnabled == false` → `PushError`；「能被抽取的才配有开关」。→ `systems/services/content-service.md`
- **存档判据「重算不出来的存，重算得出来的不存」**；`pastEvent` 只追加不修改；band 写入并入 `eventEnd` 那一次 `TryApply`，**不新增存档点、不新增结算阶段**。→ `systems/character-profile/_index.md`
- **`DisabledAbilityEntry` 的先例：** 存「施加时坐标 + 时长」而非「到期坐标」，坐标用 `pastEvent` 的 `Seq`（`int`）而非 `InstanceId`。→ 同上
- **纪律的可执行化四级阶梯 + 两条选级判据**（能上线且线上不可见 → 必须第 1 / 2 级）。**条件编译清单穷举 5 处，不得扩张。** → `systems/architecture.md`

## 建议方案

### 1. 树 = 纯调制，没有并行结构

`[既有推演]`

**AdventurePlot 不产出任何事件，也不持有任何事件序列。** 它是 `ComputeEventOptions` 物化链条内部的一个**加权 / 框定输入**，与 location 框定、map 子流并列。

这不是取舍，是既有决策的直接推论——三条各自独立地封死了并行结构：

- **「唯一物化点 + 唯一出口」**：并行结构意味着剧本自己能把事件摆到玩家面前，那就是第二个出口。
- **「事件之间不存在预先编好的前后连边」**：剧本树若持有事件序列，它就是一张被编好的连边图，只是换了个地方存。
- **「PlotManager 只调内容不调约束」**：剧本要表达「这一步你必须去某处」，既定的唯一手段就是**把候选池收窄到只剩它**——这本身就是调制语言的一条算子，而不是另一套结构。

**推论（承重）：剧本树的「节点」不是事件，是一组调制参数 + 一段可选叙事 + 一组出边。** 玩家永远不会「进入一个剧本节点」，他只会**察觉摆在面前的事件变了**（与档位表「调制才是隐藏属性的主要显影通道」完全同构）。

### 2. 剧本内容 = 两个 `Resource` 类型：`PlotArcData` + `PlotNodeData`

`[既有推演]`

进 ContentRegistry、各有自己的仓储，形态与 `HiddenStatBandData` / `LocationData` 同族。

- **`PlotArcData` = 一条剧本线的头**（Story / Chapter / SideChapter / SideStory 之一）：持有层级、入口节点、激活条件、篇章范围。
- **`PlotNodeData` = 树上的一个节点**：持有叙事正文、调制算子、出边。

**为什么是两个而不是一个：** arc 与 node 的**激活面完全不同**——arc 由 `PlotTriggerId` / 篇章边界激活（一次），node 在 arc 存活期间被反复推进（多次）；且 key points 的粒度落在 arc 上（见第 4 条），一个类型无法同时当锚点和当步骤。**也不是三个**：不再单列「剧本文本」类型，理由见下条。

**为什么不是四个（每级一个类型）：** 四级的差别只在**激活范围与并发规则**，字段集合完全相同。四个类型会让「解析一个 arc」需要四条分支，而层级本身是一个枚举就能表达的东西。

### 3. 剧本正文**内嵌**在 `PlotNodeData` 上，不复用定性文案条目、不单列文本类型

`[既有推演]`

`plot-manager.md` 当前写着跨档叙事「文案正文单独成条目（复用 Finale 补白要用的那个定性文案类型）」。**剧本正文不能走同一条路**，两条理由：

1. **热更权限相反、且已明写。** 定性文案条目属「被存档引用」类，**照旧只改不增**；而剧本例外的**全部收益就是「新剧情可热更不发版」**。若剧本正文寄生在只改不增的类型上，overlay 新增一条 arc 时**写不出它的正文**——例外当场失效。
2. **拆条目的动机在剧本侧不存在。** 档位文案拆出去是因为「每档 2–3 条候选、等概率取一、可单独被 flags 关掉一条」；剧本节点的正文是**一对一、不可替换、与节点同生同灭**的。拆开只买到一层 `Id` 间接与一处新的悬空可能。

**形态：** `PlotNodeData.Body : LocalizedText`（可空——纯调制节点没有正文）。`LocalizedText` 的既有语义原样适用（`zh` 缺失 → `PushError`；`en` 缺失 → 静默回落 + 覆盖率审计；overlay 改文案 / 补语言键不算新增 `Id`）。

**连带收益（承重，第 6 条依赖它）：** 一条新 arc = 若干 `PlotNodeData` + 一个 `PlotArcData`，**全部是剧本类型**。它不需要新增任何非剧本 `Id` 就能自足——这正是「新增剧本条目不得引用本次 overlay 之外的新 `Id`」这条约束**能被机械检查且不误伤正常内容编排**的前提。

### 4. key points 粒度 = **每条已激活 arc 一条**，不是每节点一条、也不是全局一个指针

`[既有推演]` `[通行做法]`

```csharp
// CharacterProfile 上：IReadOnlyList<PlotKeyPoint> plotKeyPoint;   （单数命名，沿用 pastEvent 风格）
public sealed record PlotKeyPoint(
    string       ArcId,             // PlotArcData 的稳定 Id
    string       NodeId,            // 该 arc 当前所处节点（PlotNodeData 的 Id）
    PlotArcState State,             // Active | Completed | Abandoned
    int          EnteredAtChapter,  // 进入当前节点时的篇章
    int          EnteredAtSeq       // 进入当前节点时的 pastEvent 时序坐标
);
```

**粒度判据 = 悬空降级规则反推出来的，不是体积判据。** 既定纪律要求「key point 必须能被独立解析、缺失时安全跳过」：

- **全局单指针**（只存「当前剧本位置」）→ 一处悬空即**整个剧本层不可解析**，降级规则在结构上不成立。**直接违反硬约束，出局。**
- **每节点一条痕迹**（记走过的全部节点）→ 满足可跳过，但存档随轮回长度线性膨胀，且违反「重算不出来的存」的节制口径（走过的路径当前**没有消费方**，见第 8 条）。
- **每 arc 一条** → 每条记录自成一个可独立解析的单元；一条悬空只让**那一条剧本线**惰性化，其余 arc 照常调制、照常叙事。**降级从「不阻塞轮回」加强为「不阻塞其余剧本线」。**

**两条硬约束的满足是显式的：** 记录里**只有内容侧 `Id` 与两个整型坐标，没有任何 `InstanceId`**；`EnteredAtSeq` 用 `pastEvent` 的 `Seq`，直接沿用 `DisabledAbilityEntry.AppliedAtSeq` 的既有先例。

**读档 / 解析校验：**

| 情形 | 语义 | 处置 |
|---|---|---|
| `ArcId` 解析不到 | 可选缺失（overlay / 版本回退） | `PushWarning` + **该条整体惰性**（不调制、不叙事）+ 保留条目，轮回继续 |
| `ArcId` 在、`NodeId` 解析不到 | 同上 | `PushWarning` + 该条惰性；**不尝试回退到入口节点**——那会让玩家重走一遍已走过的剧情 |
| `State` 缺失 / 越界 | 必需缺失 | `PushError` 带 `characterId` + `ArcId` |
| 同 `ArcId` 出现多条 | 不可能态 | `PushWarning` + 保留 `EnteredAtSeq` 最大的一条 |
| `EnteredAtChapter` > 当前 `chapter` | 不可能态 | `PushWarning` + 按 `Completed` 处理 |

**保留惰性条目而非删除**：与 `disabledAbility`「空指向条目是无害的幂等残留」同款处置——overlay 回滚后再滚上来，那条线应当能自己复活。

### 5. 推进时点 = 已有的 `eventEnd`，单步推进，不新增结算阶段

`[既有推演]`

- **判定落在 `eventEnd`**，与隐藏属性 band 的写入**同一次 `TryApply`**——「一个事件 = 一次事务 = 一个存档点」原样成立。这与 band 字段的既定落点是同一条论证，不是新结构。
- **一次 `eventEnd`，每条 arc 至多前进一个节点。** `[通行做法]` 允许链式推进会让一次结算跑完半条剧本线（若干节点的出边条件恰好同时满足），玩家在一个事件后突然发现候选池换了三轮。单步推进使「剧本推进速度 ≤ 事件推进速度」成为结构性事实。
- **推进是 key point 的唯一变更方式**；`ChooseBranch` 亦经 `ProfileManager` 写入（既定），不另开写入口。

### 6. overlay 剧本例外的可执行化：合并后新增 `Id` 集合的两条闸

`[既有推演]`

合并阶段 ContentRegistry 本就知道每个 `Id` 来自基线还是 overlay，故 `newIds = overlay 中不存在于基线的 Id 集合` 是**免费拿到的**。两条规则跑在合并后强校验里，全量、非 `#if DEBUG`：

| 闸 | 规则 | 违反 |
|---|---|---|
| **A · 只改不增的机械形态** | `newIds` 中的每个 `Id` 的宿主类型必须 ∈ { `PlotArcData`, `PlotNodeData` } | `PushError` 带 `Id` + 类型名 + `throw` |
| **B · 剧本例外的边界二** | 新增剧本条目的每一个**外部引用 `Id`**：若被引用者是**非剧本类型** → 必须存在于**基线**；若是剧本类型 → 允许来自 `newIds` | `PushError` 带引用方 `Id` + 悬空 / 越界的被引用 `Id` |

**闸 A 是顺带的净收益：** 「overlay 只改不增」此前只是一条约定（第 4 级），这两条闸让它连同它的例外一起变成启动期硬校验。

**诚实标注：这条纪律的天花板是第 3 级，不是第 1 / 2 级。** `content-service.md` 写着它「应做到阶梯第 1 / 2 级」——**做不到**：第 1 级靠类型 / 可见性，第 2 级靠编译期，而这里被检查的对象是 `.tres` 的**引用图**，C# 编译器与类型系统都触不到它。硬凑第 2 级的唯一路径是代码生成器 + 分析器，成本远超收益，且已有「否决 Roslyn 分析器」的先例。

**但选级判据的诉求可以另一条路满足——把同一份校验前移到 overlay 发布管线：**

- 构建 overlay 包时，用**同一份校验代码**（同一个 `LoadAll()` 路径，喂「基线 + 待发 overlay」）跑一遍，不通过就**不产出包**。
- 于是「线上收到一份带悬空引用的 overlay」这一事件在**发布侧**就不可能发生，而不是等玩家启动时才 `PushError`。**效果等价于第 2 级**（发布前显形），实现是零新增机制（复用 `LoadAll()`）。
- 客户端侧的 `PushError` 仍保留为兜底——它处理的是「手工塞进 `user://overlay/` 的包」这类非发布路径。

**这条推论回写 `content-service.md` 与 `systems/architecture.md`（已裁定）：** 选级阶梯的第 1 / 2 级只对**代码侧**纪律成立；**内容侧纪律的等价物是「同一份校验跑在发布管线上」**，判据「能上线且线上不可见」由此照样满足。**它写成阶梯的一条通用补注，不是只写给剧本的特例**——`.tres` 的引用图不止剧本一处（`EncounterScopes`、`NarrativeIds`、`RewardPoolId`、`locationMap` 连边全在此列），逐条写例外只会把同一条论证重复五遍。

### 7. 同时激活的 side arc 上限 = **2**，超出**排队**不丢弃

`[通行做法]`（已裁定）

- **`MaxConcurrentSideArcs` 是平衡数值，落 `systems/balance.md`，初值 `2`。** 只统计 `Tier ∈ { SideChapter, SideStory }` 且 `State == Active` 的 arc；Story 与 Chapter 各恒有一条，**不占配额**（它们是结构不是穿插）。
- **依据：调制是叠加的。** 三条 side arc 同时改类型权重 / 事件权重，候选池会变成谁也说不清的混合物——而**调制正是隐藏属性与剧本的主要显影通道**（既定：玩家感知「这条线在动」主要来自摆在面前的事件变了）。上限保住的是这条通道的可读性。
- **超出上限 → 排队，不丢弃（承重）。** 丢弃会让 `PlotTriggerId` 触发变成「有时不生效」——一个跨入煞气 Band 3 却什么都没发生的轮回，无法与「机制坏了」区分。排队使触发恒定成立，只是延后。
  - **队列不落存档**：它可由「全部 arc 的激活条件 + 当前 key points」读时重建，按判据「重算得出来的不存」⇒ **`CharacterProfile` 不加字段**。
  - **出队时点 = `eventEnd`**，与 arc 推进同一次判定；一次 `eventEnd` 至多出队一条（与单步推进同款节制）。
  - **`ExclusiveGroup` 先于队列生效**：同组已有 Active arc 时，新 arc 直接判为不激活，不进队列。
- **上限是纯内容侧数值，不改任何结构**——日后实测觉得闷，改 `2` 为 `3` 即可，schema / 字段 / 校验全不动。

### 8. key points **不**持久化已走分支路径

`[既有推演]`（已裁定）

`PlotKeyPoint` 只记「这条线现在在哪个节点」，**不记它是怎么走过来的**。

- **判据是「重算不出来的存」的完整口径**——它有两半，既有文档一直连用：**重算不出来**（分支选择确实是玩家输入，重算不出）**且有消费方**。路径当前**没有任何消费方**：调制只读当前节点、叙事只读当前节点、推进只读当前节点。
- **日后确需（角色履历展示「你在这条线上选了什么」）的落点是 `PastEventEntry`，不是 key point。** DnD 选分支本就发生在某个事件里，把它记进那条事件痕迹，比在 key point 上另开一个随轮回长度线性增长的数组更贴近既有分层（`pastEvent` 只追加、已有 `Unchosen` 轻摘要这一先例）。
- **明写的代价：** 在补上那个字段之前，**已结束的轮回无法回顾分支选择**——补记是补不回来的。这被接受：履历展示不在中期路线图内，而每条 key point 上挂一个无人读的数组会先付出存档体积与 diff 噪音的代价（`CharacterProfile` 是 sync-service 的既定 diff 单位）。

## 具体形态（可 derive 的落地面）

### `PlotArcData`

```csharp
[GlobalClass]
public partial class PlotArcData : Resource
{
    [Export] public string        Id             { get; set; }  // "plot.arc.story.ashen_lineage"
    [Export] public PlotTier      Tier           { get; set; }  // Story | Chapter | SideChapter | SideStory
    [Export] public string        ParentArcId    { get; set; }  // Chapter → 所属 Story；其余可空
    [Export] public string        EntryNodeId    { get; set; }  // 入口 PlotNodeData
    [Export] public string        PlotTriggerId  { get; set; }  // 可空：与 HiddenStatBandData.PlotTriggerId 对接
    [Export] public int[]         ChapterScope   { get; set; }  // 允许存活的篇章；空 = 不限（SideStory）
    [Export] public string[]      CharacterIds   { get; set; }  // 可空：限定角色模板；空 = 任意角色
    [Export] public string        ExclusiveGroup { get; set; }  // 可空：同组 arc 一次轮回内至多激活一条
    [Export] public bool          ContentEnabled { get; set; } = true;
}
```

- **`CharacterIds` 让「主线是否与角色绑定」两种取向都能承载**，故本方案**不被「角色模板池形态」那条待答项阻塞**：空数组 = 全局主线，填值 = 角色专属主线，日后定哪一侧都只改内容不改 schema。
- **`ContentEnabled` 有语义**（不同于 `HiddenStatBandData`）：arc 是**被激活抽取**的，不是查表结构 ⇒ 「能被抽取的才配有开关」判据判它**照常参与 `AllEnabled()`**，关一条 arc 只让它不再被新激活。**已在 key points 里的 arc 照常经 `Get(id)` 解析**（读取侧不过滤），不会因线上关闭而悬空。

### `PlotNodeData`

```csharp
[GlobalClass]
public partial class PlotNodeData : Resource
{
    [Export] public string          Id       { get; set; }  // "plot.node.ashen_lineage.03"
    [Export] public string          ArcId    { get; set; }  // 所属 arc（冗余存一份，供加载期反查校验）
    [Export] public LocalizedText   Body     { get; set; }  // 可空 = 纯调制节点，无叙事
    [Export] public PlotModulation  Modulation { get; set; }// 可空 = 纯叙事节点，无调制
    [Export] public PlotEdge[]      Edges    { get; set; }  // 空 = 终止节点（arc → Completed）
    [Export] public bool            ContentEnabled { get; set; } = true;  // 恒 true，见下
}
```

- **`PlotNodeData.ContentEnabled == false` → 加载期 `PushError`**，与 `HiddenStatBandData` 同款判据：节点是**被 key point 查表定位**的结构，不是抽取池成员；关掉一个中间节点只会在树上造出空洞、让一条正在进行的 arc 卡死。**放量的正确粒度是 arc，不是 node。**
- **`Body` 与 `Modulation` 不得同时为空** → 加载期 `PushWarning`（一个既不叙事也不调制的节点是编排失误，但不阻塞）。

### `PlotEdge` / `PlotModulation`

```csharp
[GlobalClass]
public partial class PlotEdge : Resource
{
    [Export] public string        ToNodeId    { get; set; }
    [Export] public PlotCondition Condition   { get; set; }  // 见下表
    [Export] public LocalizedText BranchLabel { get; set; }  // 非空 = 对玩家可见的 DnD 分支；空 = 后台自动推进
}

[GlobalClass]
public partial class PlotModulation : Resource
{
    [Export] public EventTypeWeight[] TypeWeights   { get; set; }  // 事件类型权重修正（软框定）
    [Export] public string[]          EventWhitelist{ get; set; }  // 非空 = 候选池收窄到这些 EventId（剧本强制性的唯一表达）
    [Export] public EventWeight[]     EventWeights  { get; set; }  // 单条 AdventureEventData 的权重加成
    [Export] public string            EnemyPoolScope{ get; set; }  // 框定剧情线专属 EnemyData 池（对上 PoolScope）
    [Export] public int               LevelBias     { get; set; }  // 带内赋级权重偏移；不改 ±2 带边界
    [Export] public EncounterTighten  Tighten       { get; set; }  // 可空：拧紧遭遇参数（TurnLimit / VictoryRule）
}
```

**`PlotModulation` 的字段集合是「PlotManager 权力面」的逐条投影，不多一个字段：**

| 既定权力 | 承载字段 |
|---|---|
| 影响哪些事件进池、以什么权重出现 | `TypeWeights` · `EventWeights` |
| 剧本强制性 = 把候选池收窄 | `EventWhitelist` |
| 框定用哪个敌人池 | `EnemyPoolScope` |
| 偏移带内赋级权重 | `LevelBias` |
| 拧紧遭遇参数 | `Tighten` |
| ~~抬 `eventPriority`~~ | **无字段**——写不出来（阶梯第 1 级） |
| ~~改模板字段 / 改敌人卡组 / 改 item·power 列表~~ | **无字段**——同上 |

**这是本方案里唯一做到阶梯第 1 级的地方，值得点名：** 「PlotManager 只调内容不调约束」「碰不到模板任何字段」这两条承重纪律，在这个类型上退化为**内容作者根本写不出那个字段**。

### `PlotCondition`（出边推进条件）

| `Kind` | 参数 | 语义 |
|---|---|---|
| `EventResolved` | `EventId` / `EventType` / `EventOutcome` | 完成了符合条件的事件 |
| `HiddenStatBand` | `HiddenStat` + `BandIndex` + 比较向 | 某隐藏属性到达 / 跨入某档 |
| `BranchChosen` | —— | 由 `ChooseBranch` 显式选定（`BranchLabel` 非空的边专用） |
| `ChapterAdvanced` | `Chapter` | 篇章推进到某章 |
| `EventCount` | `n` | 该 arc 在当前节点已停留 n 个事件（`currentSeq − EnteredAtSeq >= n`） |

**出边求值顺序 = 数组顺序，取第一条满足的。** 显式顺序优于「按优先级字段排序」——后者会立刻引出「同优先级怎么办」。**`BranchChosen` 边与自动边不得混在同一节点**（要么这个节点让玩家选，要么它自己走）→ 加载期 `PushError`。

### `PlotSegment`（`TryResolvePlot` 的产出，填上 `plot-manager.md` 的 ⟨待定⟩）

```csharp
public sealed record PlotSegment(
    string                          ArcId,
    string                          NodeId,
    LocalizedText                   Body,        // 可空
    IReadOnlyList<PlotBranchOption> Branches,    // 空 = 无玩家选择；非空 = DnD 选分支
    PlotModulation                  Modulation); // 可空

public readonly record struct PlotBranchOption(string BranchId, LocalizedText Label);
```

- **`TryResolvePlot` 的既定 `bool` 语义原样成立**：任一 key point 惰性 → 该条不产 segment；**全部 arc 都惰性 / 无激活 arc → 返回 `false`**，调用方跳过叙事与调制、轮回继续。
- **`ModulateEventOptions` 的输入 = 全部 Active arc 的 `Modulation` 之并**。多条 arc 同时调制时的合并规则（白名单取交还是取并、权重相乘还是相加）**归「框定叠加顺序」那条待答项**，本方案只定字段形态，见「前置依赖」。

### 加载期校验（合并后强校验，走 `AllIncludingDisabled()`）

| 违规 | 处置 |
|---|---|
| `PlotArcData.EntryNodeId` / `ParentArcId` / `PlotNodeData.ArcId` / `PlotEdge.ToNodeId` 悬空 | `PushError` + 双方 `Id` + `throw` |
| `PlotNodeData.ArcId` 与「从该 arc 入口可达」不一致（孤儿节点 / 串线节点） | `PushError` + `Id` |
| 从 `EntryNodeId` 出发的可达图**含环** | `PushError` + 环上 `Id` 序列（剧本树是树，环会让单步推进永不终止） |
| 存在**不可达节点** | `PushWarning` + 逐条列出（多半是编排遗漏，但不阻塞） |
| `PlotArcData.Tier == Chapter` 而 `ParentArcId` 为空 / 指向非 `Story` | `PushError` |
| `PlotArcData.PlotTriggerId` 与任一 `HiddenStatBandData.PlotTriggerId` 对不上 | `PushError` + 悬空 `PlotTriggerId`（**双向校验**：档位表侧配了触发 id 却无 arc 承接同样报错） |
| 同一节点混有 `BranchChosen` 边与自动边 | `PushError` |
| `PlotNodeData.ContentEnabled == false` | `PushError` |
| `Body` 与 `Modulation` 同时为空 | `PushWarning` |
| `PlotModulation.EventWhitelist` / `EventWeights` 指向不存在的 `EventId` | `PushError`（第 6 条闸 B 在此之上另加「必须来自基线」） |
| `LevelBias` 绝对值超出内容侧配置的上界 | `PushWarning`（带不越界由赋级函数保证，这里只挡明显的编排失误） |

### `Id` 约定

与 `plot.band.faith.2` / `location.wilds.bamboo_sea` 的点分小写同构：

- arc：`plot.arc.<tier>.<name>` —— `plot.arc.story.ashen_lineage` · `plot.arc.sidechapter.frostmarket_debt`
- node：`plot.node.<arc-name>.<两位序号>` —— `plot.node.ashen_lineage.03`

**node 的 `Id` 带 arc 名是有意的**：合并后校验能在**不解引用**的前提下先做一次廉价的命名一致性检查，且 overlay 新增一条 arc 时，它的全部新 `Id` 共享同一前缀，人工评审一眼可辨。

## 后果

- **`plot-manager.md`**：填上 `PlotSegment` 的 ⟨待定⟩；「文案正文单独成条目（复用 Finale 补白类型）」一句**只对档位叙事成立**，须补明剧本正文内嵌（否则两处相互矛盾）；「数据编码与 key points 粒度」「剧本内容类型的数据形态」两条待答项可移出。
- **`content-service.md`**：「剧本例外的可执行化」待答项可移出。
- **`systems/architecture.md`**：「纪律的可执行化」阶梯补一条通用附注——**内容侧纪律的等价第 2 级 = 发布管线跑同一份校验**；`content-service.md` 的同名小节回链它，不复述。
- **`systems/balance.md`**：新增一个平衡旋钮 `MaxConcurrentSideArcs`（初值 2）。
- **`character-profile/_index.md`**：`plotKeyPoint` 字段 schema 落定 → **bump 存档 schema 版本**（当前无线上存档 ⇒ 空迁移）。「AdventurePlot key points 粒度仍待定」一句可移出。
- **`future-event-service.md`**：`ModulateEventOptions` 的输入类型确定为 `PlotModulation`；**「框定叠加顺序」那条待答项的形状因此收窄**——它现在只需回答「多个 `PlotModulation` 与 location 修正怎么合并」，而不必再回答「剧本用什么调制」。
- **内容层**：新增两个内容类型 ⇒ 需要两轮 `/scaffold-content-type`（`plot-arc` · `plot-node`），条目本身归内容阶段。
- **无后端影响**：纯本地，不触及任何契约。
- **迁移**：仅 `CharacterProfile` 一次 schema bump，无线上存档 ⇒ 空迁移。

## 备选方案（已考虑并否决）

- **单一 `PlotData` 类型，一条 arc 一个条目、树内嵌为嵌套数组。** 否决：`.tres` 的嵌套编辑体验差，且 overlay 改一个节点要整条 arc 重发（文件级事务的粒度随之变粗）；更要命的是 key point 指向的 `NodeId` 不再是一个可被 `ContentRegistry.Get` 独立解析的 `Id`，**悬空降级的「独立解析」前提当场失效**。
- **剧本正文复用定性文案条目类型。** 否决：该类型明写只改不增，会让 overlay 新增 arc 时写不出正文，剧本例外的全部收益归零（见第 3 条）。
- **key points 记走过的全部节点路径。** 否决（见第 8 条）：当前无消费方；日后确需时落 `PastEventEntry` 是更贴近既有分层的纯加法退让位。
- **side arc 不设并发上限，靠 `ExclusiveGroup` 与内容编排自律。** 否决（见第 7 条）：「候选池被搅浑」这类问题在内容阶段才显形且难以归因，而上限的成本只是一个内容侧数值。
- **超出并发上限时丢弃新 arc。** 否决：会让 `PlotTriggerId` 触发变成「有时不生效」，与「机制坏了」无法区分。
- **key points 用单一「当前剧本位置」指针。** 否决：直接违反「缺失时可安全跳过」硬约束。
- **给 `PlotModulation` 加一个 `PriorityBoost` 字段表达剧本强制性。** 否决：违反「置位方唯一 = future-event-service」与「PlotManager 只调内容不调约束」两条承重纪律；强制性已有 `EventWhitelist` 这一既定表达。
- **靠 Roslyn 分析器把剧本引用约束抬到第 2 级。** 否决：与既有否决记录同理由（单独项目要维护、`.csproj` 易被 Godot 覆盖、无 CI 前提下只在本机生效），且它检查的是 `.tres` 数据而非 C# 语法树，分析器根本不是对的工具。

## 与既有决策的张力

**一处，已裁定为「扩写阶梯」（不是降低要求）。** `content-service.md` 写着剧本引用约束「应做到阶梯第 1 / 2 级」，而本方案给出的客户端侧形态是**第 3 级**。

- **冲突的具体点：** 阶梯的第 1 / 2 级手段（类型 / 可见性 / `[Obsolete(error: true)]` / 条件编译）全部作用于 **C# 代码**；本条纪律的检查对象是 **`.tres` 的引用图**，不在这些手段的作用域内。
- **不松动的代价：** 硬凑第 2 级只剩代码生成 + 分析器一条路，成本远超收益且已有否决先例。
- **裁定的松动形态：** **补齐阶梯对内容侧纪律的定义**——「能上线且线上不可见」的内容侧等价物是**把同一份校验放进发布管线**（不通过即不产包）。判据的诉求（线上永不显形一次）照样满足，实现是零新增机制（复用 `LoadAll()`）。
- **落笔位置 = `systems/architecture.md` 的阶梯表附注（通用），`content-service.md` 回链。** 写成通用补注而非剧本特例，理由见第 6 条末段。
- **被否决的替代：** 把该纪律明写降级为「第 3 级 + 接受残余风险」——代价是发布侧完全无闸，一份带悬空引用的 overlay 能一路发到线上、只靠玩家启动时的 `PushError` 兜底，而那时它已经在线上了。

## 已裁定的取向（2026-08-16）

| # | 取向 | 裁定 | 落点 |
|---|------|------|------|
| ① | side arc 并发上限 | **设上限，初值 2；超出排队不丢弃；队列不落存档** | 第 7 条 · `systems/balance.md` |
| ② | 是否持久化已走分支路径 | **不存**；日后落 `PastEventEntry` 而非 key point | 第 8 条 |
| ③ | 可执行化阶梯的张力 | **扩写阶梯**（内容侧等价第 2 级 = 发布管线校验），写成通用附注 | 第 6 条 · `systems/architecture.md` |

全文已按上述裁定改写为单一方案，**不再保留并列选项**。

## 前置依赖

- **框定叠加顺序**（location 框定 / PlotManager 调制 / seeded RNG 三者的顺序与优先级，`future-event-service.md` 待答项）→ **本方案的「多条 Active arc 的 `Modulation` 如何合并」无法定稿**（白名单取交还是取并、权重相乘还是相加）。字段形态不受影响，合并算法须等它。
- **`EventOption` 完整物化字段清单** → `PlotModulation` 能作用到的字段面可能还需扩，本方案给的六个字段是**下界不是上界**。
- **DnD 式选分支的触发点与 UI**（同分片另一条待答项）→ `BranchLabel` / `PlotBranchOption` 只是数据挂点，**何时把分支摆给玩家、摆在哪一屏**不在本方案内。
- **每条剧情线的具体内容 + 逐条目推拉映射**（内容层，已随内容充实搁置）→ 本方案只定形态，条目为零。
- **剧本内容的体积与分发粒度 / 按篇章分包**（同分片第三条）→ 本方案不涉及；`PlotArcData.ChapterScope` 恰好是日后分包边界的天然切分键，但**分包与否仍待答**。
- **角色模板池形态** → **不构成阻塞**：`CharacterIds` 已设计成两种取向都能承载（见「具体形态」的 `PlotArcData`）。

## 仍需用户决定

**无。** 三项取向已于 2026-08-16 全部裁定（见上一节的裁定表）。**余下的不是取向，是前置依赖**——「多条 Active arc 的 `Modulation` 如何合并」须等「框定叠加顺序」答定。本草稿可直接喂给 `/analyze-new-ideas`。
