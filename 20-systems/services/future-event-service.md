# future-event-service（服务）

> 依据当前 CharacterProfile **产出 eventOptions**（一组可选的 AdventureEvent）的服务层。玩家从 eventOptions 中择一以推进游戏；每完成一个事件后重算下一批。**对 `character-profile` / `game-progression` 提供「下一批可选事件」API。**

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **future-event-service = eventOptions 生成服务。** 依据**当前 characterProfile** 产出一批 **`List<EventOption> eventOptions`** —— 即当前可用、玩家可从中择一以推进轮回的选项集合。每个 `EventOption` 是一份**由 `AdventureEventData` 模板物化而来的定稿实例**（按 `EventId` 溯源到模板，按 `InstanceId` 被引用），携带物化时置位的全部属性（含 `ifMandatory` / `eventPriority`，见下）。Source: `10-handoffs/2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md`。
- **「下一步能去哪」是运行时算出来的，不是内容里连好的。** 事件之间**不存在预先编好的前后连边**，AdventureEvent 只是自足的内容条目（见 `20-systems/adventure-event/common-properties.md`）。走向完全由本服务的产出面决定——这使内容可加性成立（新增一个事件 = 新增一个 `.tres`，无需改任何既有事件的出边），也使 PlotManager 得以在运行时调制走向。
- **eventOptions 循环。** 玩家从 eventOptions 中选择一个 AdventureEvent → life-cycle-service 结算该事件、更新 characterProfile → **future-event-service 依更新后的 characterProfile 重算一批新的 eventOptions** 供玩家再次选择。这是一个 chapter 内驱动进程的核心循环（见 `20-systems/game-progression.md`）。Source: `10-handoffs/2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md`。
- **多层框定。** eventOptions 的生成受多层框定叠加：**location（地域）** 框定「当前地点开放哪批事件池」（见 `20-systems/game-progression.md`），**PlotManager** 依隐藏属性 / 剧本进度**调制** eventOptions（见 `plot-manager.md`）。future-event-service 是这些框定汇聚、产出最终 eventOptions 的服务。
- **PlotManager 是本服务内部的管理器（已定案）。** 隐藏剧本层**不是与本服务并列的服务**，而是生活在本服务内部的 manager，共享其事务边界与生命周期。它**不直接写 eventOptions**，也不直接对 game-progression / UI 暴露 eventOptions——它是一个**被调用的调制源**；对外呈现 eventOptions 的**唯一出口是 future-event-service**。Source: `10-handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md`。

  ```
  future-event-service.ComputeEventOptions(characterProfile)
        ├─▶ PlotManager        (隐藏属性阈值 / key points → 调制；云端剧本服务客户端)
        ├─▶ location 框定       (由 Travel 事件刷新)
        └─▶ SeedManager 的 map 子流
        ──▶ eventOptions ──▶ characterProfile（经 profile-service.ProfileManager 写入）
  ```

- **本服务是 AdventureEvent 的唯一物化点，产出即定稿（已定案 · 影响面最大的一条）。** `AdventureEventData : Resource` 是**模板 / 素材，不是成品**：它承载稳定 `Id`、`eventType`、静态展示文案、基准数值与**可变体的参数空间**、数据驱动的 outcome / effect 定义。**多数**具体属性由本服务依情境**物化（materialize）**得出——目的正是「按不同情境制造更多变化与风味」。Source: `10-handoffs/2026-07-27b-service-api-contracts.md`。

  ```
  res:// + user://overlay/          ContentRegistry              future-event-service          life-cycle / combat / UI
    AdventureEventData(.tres)  ──▶  按 Id 索引的只读模板  ──▶  物化(materialize)        ──▶   只读消费
    = 静态素材 / 参数空间             共享单例、可热更           情境代入 → 定稿实例            不回查模板、不改字段
                                                               （EventOption，immutable）
  ```

  - **物化输入** = 模板（经 `ContentRegistry.AllEnabled()` 取池）+ CharacterProfile（含隐藏属性、修行历程）+ location 框定 + PlotManager 调制 + SeedManager 的 map 子流。**产出 eventOptions ≡ 物化 AdventureEvent**——与既定的「eventOptions 唯一出口」完全同构。
  - **模板是共享只读单例，本服务不得写回它**——写回会污染注册表，被同一轮回的后续批次与其他角色看到。
  - **产出即定稿（finalized · immutable）。** `EventOption` 一经输出即冻结：life-cycle-service / combat-service / ViewModel 一律只读消费，**不得回查模板重算、不得改写其字段**。这是「同一个事件在呈现、结算、记入历程三处看到的是同一份数据」的保证。
  - **定稿实例必须落存档。** 物化用了 seeded RNG、当时的角色状态、以及可被 overlay 热更的模板；确定性只在同一 `contentVersion` 内成立，重算不保证同结果。因此**当前批 eventOptions 与 `pastEvent` 痕迹都存物化后的快照**，而非只存 `EventId` 事后重算。
  - **`InstanceId` 与 `EventId` 并存且不可互相替代。** 同一模板可在一次轮回里被物化多次（不同情境 → 不同实例）；`pastEvent`、`EventResolved` 负载、`TryRefill` 的「被跳过的那一个」都按 `InstanceId` 定位。
- **产出侧的两条选择约束由本服务置位（已定案）。** 它们是上述物化模型的两个特例——**不是内容作者在 `.tres` 写死的**，而是本服务在物化这一批时**动态置位**：
  - **`ifMandatory`（封锁跳过通道）：** 由本服务 / PlotManager 依剧情线关键节点等条件置位；**一批 eventOptions 可以全部为 mandatory**（等同本轮取消跳过权）。
  - **`eventPriority`（封锁同批其他选项）：** 通常为 0，玩家可任选；本批一旦出现更高优先级的事件，**有效可选集收窄为最高优先级档**。语义详见 `20-systems/adventure-event/common-properties.md`。Source: `10-handoffs/2026-07-26-event-priority-skip-semantics-and-hotfix-scope.md`。
- **跳过 = 单项补位（已定案）。** 玩家跳过一个事件后，本服务**生成一个新事件顶替它的位置**——**不是整批刷新**，本批其余选项保持不动。**补位可能落空**：若产不出新事件，本批就少一个选项（不回填、不阻塞）。Source: 同上。

## 管理器

| manager | 职责 |
|---------|------|
| **EventOptionManager** | 依 CharacterProfile 产出 / 重算 eventOptions；location 框定与 seeded 抽取 |
| **PlotManager** | 隐藏剧本：key points ↔ 云端剧本服务、隐藏属性阈值 → 调制。详见 [plot-manager](plot-manager.md) |

## 服务角色 / API 面（契约）
> _总则与共享类型见 `20-systems/architecture.md`「API 契约总则」。物化本身是纯内存计算（形态 A）；只有 PlotManager 请求云端剧本跨进程边界（形态 B）。Source: `10-handoffs/2026-07-27b-service-api-contracts.md`。_

| 方法 | 形态 | 完整签名 | 失败语义 |
|------|------|----------|----------|
| 物化一批 | A | `EventOptionBatch ComputeEventOptions(CharacterProfile character)` | 内容池为空 = 坏数据 → `PushError` + 抛 |
| 结算后重算 | A | `EventOptionBatch RefreshAfterEvent(CharacterProfile character, string resolvedInstanceId)` | 同上 |
| 跳过补位 | A | `bool TryRefill(ref EventOptionBatch batch, string skippedInstanceId, out EventOption replacement)` | **可选缺失**——补位落空是**已定案的正常语义**，`false` 前 `PushWarning` 留痕即可 |
| 当前批 | A | `EventOptionBatch Current { get; }` | — |
| 剧本分支 | **B** | `Task<OpResult> ChooseBranchAsync(string branchId, CancellationToken ct)` | 业务失败 → `OpResult`；PlotManager 的**唯一对外投影** |

```csharp
public sealed record EventOption(                 // 定稿实例：immutable 引用类型，落存档
    string             InstanceId,                // 本次物化实例的稳定标识；pastEvent / 存档引用它
    string             EventId,                   // 溯源到模板：ContentRegistry.Get<AdventureEventData>(EventId)
    EventType          EventType,                 // Mystery 时 = 遮罩类型；真身见 RevealedEventId
    int                Priority,                  // 物化时置位
    bool               IsMandatory,               // 物化时置位
    ProfileChangeSpec  SelectCost,                // 物化时组装（modifier pipeline 尚未施加）
    ProfileChangeSpec  SkipCost,
    bool               IsRevealed,                // Mystery：是否已揭示
    string             RevealedEventId            // Mystery 遮罩的固定事件（物化时即已确定）
    /* ⟨待定：其余物化字段清单，见待决问题⟩ */);

public sealed record EventOptionBatch(
    string                     BatchId,
    IReadOnlyList<EventOption> Options,
    int                        EffectivePriority,   // 本批最高优先级档；有效可选集 = Priority == EffectivePriority 的全部
    bool                       AnySkippable);       // = 任一 Option 的 IsMandatory == false
```

**为何 `EventOption` 是 `sealed record`（引用类型）而非 `readonly record struct`：** 字段多、要落存档、一批只有个位数个、不在每帧热路径——按值拷贝的代价高于一次分配。`record` 的 `with` 表达式同时给出「定稿后若确需派生（如 Mystery 揭示）就产生一个新实例而非改旧的」这一惯用法。

四点推演：

- **`ComputeEventOptions` 的语义就是「物化」：** 取 `AllEnabled()` 候选 → location 框定 → PlotManager 调制 → map 子流抽取 → 组装定稿实例。**物化完成后本服务不再改这批实例**；`TryRefill` 是**新增一个实例**顶替被跳过的那一个，不是改旧的。
- **`TryRefill` 用 `bool` + `out`**（「可选缺失」形态），因为「补位可能落空」是已定案的正常语义，不是错误。
- **`EffectivePriority` 由本服务算好放进 batch**，而不是让 UI 自己去 `Max(o.Priority)`。呈现层只做呈现，「哪些可选」是产出侧的语义。
- **PlotManager 的四个方法不出现在服务门面上**（manager 不被跨服务调用）：`ResolvePlot` / `ModulateEventOptions` / `OnHiddenStatThreshold` 是 `ComputeEventOptions` 物化链条内部的一环；只有 `ChooseBranch` 需要玩家输入，故投影为服务门面上的 `ChooseBranchAsync`。

**事件面：**

| 事件 | 负载 |
|------|------|
| `EventOptionsChanged` | `(string BatchId, int Revision)` |
| `PlotThresholdReached` | `(string CharacterId, HiddenStat Stat, int Threshold)`（本服务代 PlotManager 广播） |

**协作面：** 物化出的 eventOptions 交由 **game-progression（编排顶点）** 以**月圆之夜式菜单 / 横向滑动选择区**呈现；随机性从 `life-cycle-service.Stream(RngStream.Map)` 取得；模板按 `Id` 经 `content-service.ContentRegistry` 解析。

## 决策(-> ADR)
> _已定案的决定链接到 50-decisions/ADR-####。_

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **生成 / 加权规则未定。** 服务化架构已定，但从 characterProfile **生成 / 加权抽取** eventOptions 的具体规则（月圆之夜式策划 vs 随机权重、每批数量、node 类型配比）未定。→ `20-systems/game-progression.md`。Source: `10-handoffs/2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md`。
- **`EventOption` 的完整物化字段清单未定（07-27b 收窄）。** 骨架九字段已定（`InstanceId` / `EventId` / `EventType` / `Priority` / `IsMandatory` / `SelectCost` / `SkipCost` / `IsRevealed` / `RevealedEventId`）；但「**多数**属性由物化决定」意味着还有一批未列出的字段：哪些数值可被情境改写？风味文案是否也物化？outcome 权重是否在物化时固化？这需要一次**内容侧** handoff 才能定稿。→ `20-systems/adventure-event/common-properties.md`。Source: `10-handoffs/2026-07-27b-service-api-contracts.md`。
- **定稿实例快照的存档字段形态未定（07-27b 收窄）。** 持久化**方式**已定案（落物化后的定稿实例快照，不重算——见「意图」）；仍待定的是快照的**字段形态 / schema**：`pastEvent` 如何区分「进入并结算」与「跳过」两种痕迹、快照存哪些字段、以及**快照体积对增量 push 粒度的影响**。→ `20-systems/adventure-event/common-properties.md`、`sync-service.md`。Source: 同上。
- **框定叠加顺序。** location 框定、PlotManager 调制、seeded RNG 三者的叠加顺序与优先级未定。→ `20-systems/game-progression.md`、`20-systems/services/plot-manager.md`。
- **补位落空的判定规则未定。** 「也可能没有新的」——在什么条件下本服务补不出事件（事件池耗尽？优先级 / 剧本约束不允许？）？eventOptions 是否允许被跳到只剩 0 个？若剩 0 个，玩家如何推进（死局兜底）？Source: `10-handoffs/2026-07-26-event-priority-skip-semantics-and-hotfix-scope.md`。
- **`eventPriority` 的置位规则与 `ifMandatory` 的叠加未定。** 优先级档位如何取值、依什么条件抬升；高优先级事件能否被跳过、跳过后是否解除对低优先级的封锁；二者是否语义重叠。→ `20-systems/adventure-event/common-properties.md`。Source: 同上。
- **产出侧的可负担性保证未定。** 一批可以全部 mandatory 且高优先级会封锁其余选项——若玩家付不起唯一可选事件的 `selectCost` 则轮回无法推进；是否需要「至少一个可负担选项」的产出侧保证或兜底降级。**07-27b 收窄：** 既然 `selectCost` 是**物化时组装**的，这条保证天然有落点——物化阶段即可对照 `ProfileService.Instance.CanAfford(spec)` 调整；剩下的只是「要不要给这条保证」以及兜底形态。Source: 同上 + `10-handoffs/2026-07-27b-service-api-contracts.md`。
- **跳过语义的残留细节。** 主干已定（单项补位 / 通常不扣寿元 / 计入 `pastEvent`）；仍待定：能否整批全跳、付不起 `skipCost` 时如何表现。→ `20-systems/adventure-event/common-properties.md`。Source: 同上。

## 对应
提炼至：`.claude/knowledge/systems/future-event-service.md`（引用层，待建）。
