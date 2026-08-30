# future-event-service（服务）

> 依据当前 CharacterProfile **产出 eventOptions**（一组可选的 AdventureEvent）的服务层。玩家从 eventOptions 中择一以推进游戏；每完成一个事件后重算下一批。**对 `character-profile` / `game-progression` 提供「下一批可选事件」API。**

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **future-event-service = eventOptions 生成服务。** 依据**当前 characterProfile** 产出一批 **`List<EventOption> eventOptions`** —— 即当前可用、玩家可从中择一以推进轮回的选项集合。每个 `EventOption` 是一份**由 `AdventureEventData` 模板物化而来的定稿实例**（按 `EventId` 溯源到模板，按 `InstanceId` 被引用），携带物化时置位的全部属性（含 `eventPriority`，见下）。
- **「下一步能去哪」是运行时算出来的，不是内容里连好的。** 事件之间**不存在预先编好的前后连边**，AdventureEvent 只是自足的内容条目（见 `systems/adventure-event/common-properties.md`）。走向完全由本服务的产出面决定——这使内容可加性成立（新增一个事件 = 新增一个 `.tres`，无需改任何既有事件的出边），也使 PlotManager 得以在运行时调制走向。
- **eventOptions 循环。** 玩家从 eventOptions 中选择一个 AdventureEvent → life-cycle-service 结算该事件、更新 characterProfile → **future-event-service 依更新后的 characterProfile 重算一批新的 eventOptions** 供玩家再次选择。这是一个 chapter 内驱动进程的核心循环（见 `systems/game-progression.md`）。
- **多层框定。** eventOptions 的生成受多层框定叠加：**location（地域）** 框定本地域的产出面（见下条与 `systems/game-progression.md`），**PlotManager** 依隐藏属性 / 剧本进度**调制** eventOptions（见 `plot-manager.md`）。future-event-service 是这些框定汇聚、产出最终 eventOptions 的服务。
- **location 的框定面 = 两组字段（承重）。** 一个 location 携带 **① 事件类型出现概率修正**（软框定：改类型权重，不改可及性）与 **② `eventCountLimit`**（该地域的事件容量上限）。字段语义与推论归 `systems/game-progression.md`；对本服务的三条直接影响：
  - **物化的类型配比有了第一层确定的输入**：候选池按 location 的类型修正加权，而**不是**按地点切换到另一个封闭的事件池。
  - **敌人取池的地域维度由敌人条目自己的 `PoolScope` 给出**（location 条目不持敌人清单）⇒ **敌人物化的两条轴仍然正交**：**当前 location 影响「派谁来」**（通用条目恒进池，该地域的专属条目在其上叠加），**相对角色等级的赋级带决定「有多强」**（三章统一 `±2`，见下）。带内各档的分布权重见下；**卡组不随赋级变化**，按模板的功法引用列表展开。
  - **`eventCountLimit` 是本服务的产出闸门**：配额用尽即改产 Travel（见下）。判定在**每一次整批重算**时做出，**没有第二个判定时点**（本服务不设单项补位，见下）。
- **配额用尽 → 本批收窄为仅剩 Travel。** 玩家在当前 location 达到 `eventCountLimit` 后，本服务产出的**只剩「前往另一个 location」**。**承载它只需一个既有字段**——Travel 选项以**最高 `Priority`（= 1）**出场即可（`EffectivePriority` 随之抬到该档，封锁同批其余选项）。由此 Travel 从可选路由升格为**结构性闸门**：篇章 = 若干 location 的串联，location 之间由 Travel 缝合。
  - **Travel 候选按 80 / 20 掷定：** **80%** 列出 `locationMap` 上当前 location 的**全部邻接地域**（各为一个并列选项，「去哪」是一次真实的玩家决策）；**20%** 由 map 子流 seeded 随机取一个。**常规出场与闸门场景一律适用**；**Explore 揭示出的 Travel 必为随机那一档**。**掷定发生在本服务的物化阶段**——它是「候选数量与抽取规则」这一问的答案。见 `systems/adventure-event/travel/_index.md`。
  - **Travel 段的物化落在既有 `ComputeEventOptions` 内，不新增方法：**

    ```
    若 LocationEventCount >= 当前 location.EventCountLimit：
        掷 map 子流：< TravelFullFanoutChance ? 全部邻接 : seeded 取一个
        该批 = 这些邻接各物化一个 Travel EventOption，Priority = 1
    否则：
        Travel 与其余四类一同按 location 的类型修正加权抽取，得槽位数 k（k 可为 0）
        若 k > 0：掷 map 子流 → 80% 从邻接集合抽 min(k, 邻接数) 个 / 20% 抽 1 个
        Priority = 0
    每个抽出的邻接 Id 填入该实例的 DestinationLocationId
    邻接集合取自全量图（location 与地域图恒启用，不经 AllEnabled() 过滤）
    ```

    - **`DestinationLocationId` 在物化时掷定并落在定稿实例上**，Explore 壳亦然：当 `RevealedEventId` 指向一个 Travel 条目时，该 Explore `EventOption` 的 `DestinationLocationId` **一并填好**（必为随机那一档）。**理由是既有的防重掷纪律**——候选须预先算定并落决策点存档，目的地若等到揭示那一刻才掷，玩家退出重进即可刷一个更合意的地域。呈现侧的配套约束见 `systems/adventure-event/explore/_index.md`。

    - **常规场景的 80% 档受本批槽位数 `k` 截断**：不截断则高出度地域会溢出批次规模区间 1–5，或把常规批挤成事实上的闸门批。掷定规则本身不分叉。
    - **`TravelFullFanoutChance = 0.80` 是平衡资源里的全局单值**，**PlotManager 不得推拉它**——它改的是玩家选择空间的宽窄，落在约束面，而本服务独占约束面的置位权。
    - **邻接集合不经 `AllEnabled()`，这是本服务取池纪律的唯一例外**：`AllEnabled()` 管的是**内容集合的抽取**，而邻接集合来自**图这一结构**，其顶点恒启用（见 `content-service.md`）。这条例外也是「Travel 兜底恒可产出」的前提。
  - **计数口径：** `eventCountLimit` 只计**选择进入并结算**的事件；**Travel 不计入**。「一批 = 一次操作 = 一次配额消耗」，地域节奏是一条干净的计数。
- **`locationMap` = 本服务高频读取的只读静态数据。** 地域之间的连边由一份独立的 **`locationMap`** 承载（不挂在 Travel 内容条目上、不在运行时算）；Travel 的目的地取自当前 location 的**邻接集合**。它是**一份不变的数据、三个篇章共用同一张图**，本服务**经常调用**它。
  - **工程形态由此定：** 进 `ContentRegistry`、**启动加载一次并常驻内存**、本服务**只读不写**（与「模板是共享只读单例、服务不得写回」同一条纪律）；**存档不存图，只存当前所在 location 的 `Id`**。受 overlay 热更管辖，但**一次轮回内视为不变**；**flags 对它与 `LocationData` 均不生效**（结构性查表类恒启用，见 `content-service.md`）。载体形态 `LocationMapData` / `LocationData`、`Id` 约定与八条加载期校验归 `systems/game-progression.md`。
  - **推论：location 不随篇章 / 境界变化。** 篇章间的难度差异由**敌人赋级带**（相对角色当前等级）承载，不由换图承载——同一张图在三个篇章重走，敌人强度自动跟着角色走。
  - **`locationMap` 在轮回内对玩家不可见**；玩家可见的那一面是账号级的 `LocationCodex`（图鉴族的地域本，「去过即记」**且记连边**，故整张图可在多次轮回中被重建——这是设计目标，见 `systems/player-profile/codex/_index.md`）。**推论：图的稳定性是对玩家的隐性承诺**——改连边等于清空一份账号级资产。

- **PlotManager 是本服务内部的管理器。** 隐藏剧本层**不是与本服务并列的服务**，而是生活在本服务内部的 manager，共享其事务边界与生命周期。它**不直接写 eventOptions**，也不直接对 game-progression / UI 暴露 eventOptions——它是一个**被调用的调制源**；对外呈现 eventOptions 的**唯一出口是 future-event-service**。

  ```
  future-event-service.ComputeEventOptions(characterProfile)
        ├─▶ PlotManager        (隐藏属性阈值 / key points → 调制；本地剧本节点解析)
        ├─▶ location 框定       (由 Travel 事件刷新)
        └─▶ SeedManager 的 map 子流
        ──▶ eventOptions ──▶ characterProfile（经 profile-service.ProfileManager 写入）
  ```

- **本服务是 AdventureEvent 的唯一物化点，产出即定稿（影响面最大的一条）。** `AdventureEventData : Resource` 是**模板 / 素材，不是成品**：它承载稳定 `Id`、`eventType`、静态展示文案、基准数值与**可变体的参数空间**、数据驱动的 outcome / effect 定义。**多数**具体属性由本服务依情境**物化（materialize）**得出——目的正是「按不同情境制造更多变化与风味」。

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
  - **`InstanceId` 与 `EventId` 并存且不可互相替代。** 同一模板可在一次轮回里被物化多次（不同情境 → 不同实例）；`pastEvent` 与 `EventResolved` 负载都按 `InstanceId` 定位。
  - **批的权威在 `CharacterProfile.eventOption`，`Current { get; }` 是内存视图。** 本服务**零改动、不新增写入面**，仍是无记忆的纯产出侧：批的落盘由 life-cycle-service 组装成 `ProfileChangeSpec.EventStateChanges` 经 `ProfileManager` 写入。结算进行中的那一项住在 `CharacterProfile.activeEvent`（派生后的整份快照），形态与读档校验见 `systems/character-profile/_index.md`。
  - **「唯一出口」管的是「物化」这一动作，不管已定稿实例的 `with` 派生（承重）。** Explore 揭示与 Exchange 刷新由 life-cycle-service 与 Exchange 的结算路径派生：它们**不取池、不掷物化随机、不改 `InstanceId` / `EventId`**（刷新掷的是库存，不是重新物化一个事件），当前批里那份原实例一字不动。**不写下这一句，日后必有人据「唯一出口」把派生逻辑推回本服务**——而那会给这个明写「无记忆、不持有跨批次状态」的服务装上一个事件内的状态机。
  - **文本类字段一律不物化。** 显示名 / 描述 / 图标之外，**风味文案同样跟随模板数据**——它不进定稿实例、不进快照、不落存档，由 UI 层按 `EventId` 现场取模板组装。**收益：文案改版永不触发存档迁移**，且使「重算不出来的存」这条快照判据两侧再无灰色地带（见 `systems/adventure-event/common-properties.md` 的「`pastEvent` 的痕迹 schema」）。**推论：「完整物化字段清单」的剩余分叉只在数值与结构字段上。**
  - **快照存哪些字段由一条判据给出，不逐字段拍板：** 「重算不出来的存，重算得出来的不存」。字段表与 `PastEventEntry` 的完整形态归 `systems/adventure-event/common-properties.md`；本服务侧的承重点是**物化产出的数值必进快照**（`SelectCost` / `Priority` / Explore 真身 / 敌人赋级）。
  - **物化面同样由一条判据收口，不逐字段拍板（承重）。** 凡满足下列任一条的落 `EventOption`，三条皆不满足的留在模板侧：
    - **① 由 seeded RNG 掷定**（重算不保证同结果）；
    - **② 由情境代入而定**（角色状态 / 篇章 / location / `PlotModulation` 参与，模板上只有参数空间）；
    - **③ 物化时组装 / 变换而成**（`SelectCost` 的取负与 element 组装即此类）。

    **反向的硬边界：** 文本类字段一律留模板（显示名 / 描述 / 图标 / 风味文案）；随 flags 变且无消费方的（Explore 真身的启用态）不落实例。
    **收益：新增一类专有物化字段时走判据即可，不必每次重开「清单闭合了吗」。**
  - **两条判据的分工：物化判据答「这一格在不在定稿实例上」，快照判据答「这一格要不要再抄进 `PastEventEntry`」。** 二者取值不同的例子现成：`ExchangeStock` 在定稿实例上（物化产出），痕迹侧却靠 `AppliedChange` 记账、不再存一份库存表。
  - **outcome 的固化时点：抽取在物化时掷定，条件在结算时求值（承重）。** 「从哪个池抽哪一条」「掷出几个」「哪一档」在物化时掷定并落定稿实例；依结算走向的分支（胜 / 负、成 / 败，经验的失败折算，读隐藏属性当前值作为输入项）在结算时求值。**条件两侧的取值均已定稿，结算时只选一侧、不掷骰。**
    - **三条理由全是既有纪律的直接推演：** ① 产出侧同受防重掷约束——抽取若留到结算那一刻现掷，退出重进即可重掷产出，这正是 Research 候选与 Exchange 库存被前移到物化的同一条理由；② 产出侧同受「不得回查模板重算」约束——overlay 热更可在轮回进行中覆写模板，结算时回查等于同一事件在呈现与结算两处看到不同数据；③ `AppliedChange` 只记**施加之后**的最终账，而决策点（置换面板的「失去 A · 得到 B」候选）需要一份**施加之前就已定稿**的候选。
    - **与「模板上的 outcome / effect 定义不进快照」不冲突**：那条管 `PastEventEntry`（本次掷定的结果已在 `AppliedChange` 里，再存一份权重表是无用中间态）；固化的结果落在**当前批 eventOptions 的存档**里，痕迹侧照旧不存。
  - **未选项的 outcome 白掷是既有代价，不是新代价。** 一批 3–5 个选项的产出全部预掷 ⇒ 未选项的产出永不施加。这与 `SelectCost` / `ResearchSlots` / `ExchangeStock` 在未选项上白算完全同构；RNG 消耗照常由 `DrawCount` 持久化，确定性不受影响。
  - **outcome 的抽取链是复用，本服务不新增抽取代码。** 能力族产出调 `profile-service.TryPickGrantableMany(kind, scope, rng, n)`，内容族走对应仓储的 `AllEnabled()` / `DrawPool<T>` 加权无放回抽取——与 Research 候选、Exchange 库存逐字同款。**随机源 = `RngStream.Reward` 子流，不新开子流。**
  - **批内抽取顺序必须固定，且是一条确定性要求（承重）。** 一次 `ComputeEventOptions` 会为同批 3–5 个选项**连续**在 `Reward` 子流上抽取（Research 候选 + outcome 产出），「三个用途从不并发」这条既有论证是**结算期**的论证，在批物化期不再自明。**顺序定为：按 option 在批内的索引升序；单个 option 内按「Research 槽 → `OnResolvedRules` 数组序 → `OnFailureRules` 数组序」。** 不定死顺序则两种实现能从同一种子产出不同批次，属能上线、线上不可见的一类缺陷。落一条 `#if DEBUG` 顺序断言（记录抽取调用序列并与上述顺序比对，不符即 `PushWarning` + 序列）。
  - **outcome 型取池短缺按分界判据降级，不新增闸 ①。** 事件产出没付过钱 ⇒ **降级到更少 + `PushWarning`（want / got）**，不拒绝、不拦事件。闸 ① 存在的理由是「不能留空面板」，而事件产出不是面板——少发一件不产生死屏、不卡玩家。
  - **`OutcomeRule` 不支持「多选一 / 加权掷一条」：一条规则一条产出。** 「随机三选一」由 `GrantFromPool` + `RarityFilter` 表达；具名的互斥产出拆成多个内容条目。本库对这类口子的收口方式是不给——真需要时补一个字段是纯加法，而先做再退回要改存档结构。
  - **outcome 物化日志：** `[FutureEvent-Outcome] instance=<InstanceId> event=<EventId> side=<Resolved|Failure> rule=<Kind> want=<n> got=<m>`。
  - **物化后断言三条**（`PushError` + `EventId`）：`Priority ∈ { 0, 1 }`；`1 <= EventOptionBatch.Options.Count <= 5`（带 `BatchId`；下界由收缩保底显式兑现，上界由 `BatchSizeWeights` 的支撑集与 `locationMap` 出度 ≤ 5 两侧共同保证）；`OutcomeSpec != null`——**无产出的事件用空 spec 表达，不用 `null`**，避免下游到处判空。`Priority` 不设加载期检查：它从不是 `AdventureEventData` 上的字段，一个不存在的 `[Export]` 面没有「检出它出现了」的机制，纪律靠文字与置位方唯一保证。
  - **物化日志：** `[FutureEvent-Materialize] instance=<InstanceId> event=<EventId> type=<EventType> prio=<n> prioReason=<QuotaGate|InitialBuild|Finale|None> cost=<lifeSpan> outcomeRolls=<n>`。抬升原因**并进这一行、不另开日志点**——它与 `prio` 同源同粒度（逐实例的物化产出），且根约定的日志标签形态是 `[System-Method]`，而 `Priority` 不是方法名。
- **选择约束只有一条轴，且由本服务独占置位。** `eventPriority` 是**唯一**约束玩家选择权的字段——**不设第二个约束字段**；它是上述物化模型的一个特例——**不由内容作者在 `.tres` 写死**，而由本服务在物化这一批时**动态置位**：
  - **取值域两档：`0`**（常态，玩家可从本批任选）与 **`1`**（本批一旦出现，有效可选集收窄为该档）。语义详见 `systems/adventure-event/common-properties.md`。
  - **置位方唯一 = 本服务；PlotManager 不得改变它。** **推论（边界澄清 · 承重）：PlotManager 只调内容不调约束**——它影响哪些事件进池、以什么权重出现，但**不能通过抬优先级强制玩家做某件事**；剧本的强制性只能靠**把候选池收窄**表达。
- **抬升判据：写一条判据，不列一张清单（承重 · 与物化判据 / 快照判据并列的第三条）。**

  > **抬升当且仅当：不抬升会使一条结构性规则失效。**

  三条子判据逐条可机械核对，**取与门**（三条皆成立才准入）：

  | # | 子判据 | 它挡住什么 |
  |---|---|---|
  | **(a)** | 该选项是某条**结构性规则的唯一出口**——不选它，那条规则无法兑现 | 挡住「这个事件很重要 / 很稀有 / 很贵」这类**风味性**抬升 |
  | **(b)** | 收窄条件**由产出侧可确定判定**（配额计数 · 篇章 · `pastEvent` · 角色等级），**不读隐藏属性、不读剧本状态** | 挡住 PlotManager 借道本服务抬升——它要读的正是剧本状态 |
  | **(c)** | 抬升表达的是**结构**，不是**难度**或**叙事** | 挡住「本批全是打不过的战斗，抬一个安全选项」这类过度保护 |

  - **(b) 是这条判据最值钱的一半**：它把「PlotManager 只调内容不调约束」从一句纪律变成一条可机械核对的准入条件。剧情线关键节点之所以不能抬升，不是因为不想，而是它的触发条件必然读剧本状态、直接被 (b) 拒。
  - **判据比清单值钱的理由**：清单会随内容增长被不断追加，每次追加都要重开「这一条该不该进」的辩论；判据把辩论一次性收敛为三次机械核对。**代价明写**：它给本服务再加一条必须被后来者遵守的纪律，密度是有成本的。
- **依判据得出的抬升清单，当前闭合为三条。**

  | 条件 | 判定式 | (a) | (b) | (c) |
  |---|---|---|---|---|
  | **配额闸门 Travel** | `Status.LocationEventCount >= location.EventCountLimit` | ✅ 离开当前 location 的唯一出口 | ✅ 读计数器 | ✅ |
  | **开局构筑事件** | `chapter == 1` 且 `pastEvent` 为空 | ✅ 开局底盘的唯一来源 | ✅ 读篇章 + 一等输入 `pastEvent` | ✅ |
  | **Finale** | `level == 该境界末级`（13 / 17 / 21） | ✅ 篇章边界的唯一出口，且不可重战 | ✅ 读等级 | ✅ |

  - **开局构筑事件的判定式读的全是既有可读状态。** `chapter == 1` ⟺ 炼气新角色（ch2 / ch3 只能由续章进入，角色已有完整卡组与法宝）；`pastEvent` 为空 ⟺ 这是 `StartCycle` 写的那一批。**不引入 `CharacterProfile` 的新格、也不给本服务开跨批次入参**——前者是一次为可推出量付的存档 schema 迁移，后者与「本服务不持有跨批次状态」正面冲突。
  - **ch1 的篇章重试算作「新角色首批」，照常抬升。** ch1 的篇章起始存档就是一个尚未做过任何构筑的空白炼气角色，「开局底盘的唯一来源」这条结构性规则在它身上成立。排除它会让 ch1 重试（上限无限，是最常走的一条路）永远拿不到那门功法与那件法宝。**收窄排除的是 ch2 / ch3 的续章与重试**：篇章继承 = 全部继承 ⇒ 底盘已完整，(a) 不成立；不收窄则续章首批会被一个不必要的强制构筑事件占满一整批。
  - **Finale 不写「本篇章尚未结算过 Finale」的守卫。** 通过（`d >= 0`）即离开本篇章、失败（`d < 0`）即角色终结——两支都离开本篇章，故「本篇章已结算过 Finale 而角色仍留在本篇章」这一状态不存在，守卫恒不可达。为一个不可达的分支写扫描是纯负债。见 `systems/adventure-event/combat/_index.md`。
  - **满级那一批的 Finale 恒进候选池、不参与类型加权**（闸门式旁路，见上方十步管线）——抬升需要有对象，加权只能提高概率。两条规则成对成立，缺一条另一条即落空。
  - **满级恰逢配额用尽 ⇒ 先 Travel 一次再渡劫，且不会丢失 Finale。** 闸门分支整批替换 ⇒ 本批只有 Travel；Travel 不计入配额、Finale 不绑定 location ⇒ 换图后新 location 的 `LocationEventCount == 0`，走常规分支，等级条件仍成立、照常抬升。代价只是多花一格 Travel 的低价寿元。
- **明确被否决的抬升候选（写下来，防止日后被逐个加回）。**

  | 候选 | 被哪条子判据拒 | 说明 |
  |---|---|---|
  | **剧情线关键节点** | **(b)** | 触发条件必然读剧本 / 隐藏属性状态。剧本的强制性**只能靠收窄候选池**表达，这是承重边界 |
  | **寿元见底时强制某类事件**（如强制一个回寿事件） | **(b)** + 承重取向 | 推进规则层从不读资源余量；且「明知是死路仍然走」是明写的承重取向，抬升等于用规则把它取消 |
  | **稀有 / 高价值 / 高 `RarityTier` 事件** | **(c)** | 纯风味。稀有度已有自己的表达位（抽取权重） |
  | **「本批全是打不过的战斗」时抬一个安全选项** | **(c)** + 承重定案 | 产出侧明写不做过度保护、不欠可战胜保证；难度的界由 `±2` 赋级带给出已经足够 |
  | **ch2 / ch3 的篇章重试后首批** | **(a)** | 篇章继承使底盘完整，无结构性规则需要兑现 |
  | **付费礼包 / 账号级持有状态触发的抬升** | **(b)** + 分层 | 账号级持有改写轮回级的选择约束，与「一条法则不得改写轮回级定稿实例」同源同重 |

- **同批多个 `1` 档：不新增任何收窄规则（三条独立依据）。**
  1. **在当前伪码下它是结构上不可达的分支**：闸门分支**整批替换**（该批里没有别的类型，第二类抬升项进不来）；开局构筑事件只出现在 `pastEvent` 为空的那一批，此时 `LocationEventCount == 0` ⇒ 必走非闸门分支，与闸门互斥；Finale 只出现在非闸门批，与闸门同样互斥，而它与开局构筑事件在时间上互斥（首批时 `level == 1`）。**为一条不可达的分支写规则是纯负债。**
  2. **两档语义已明写「同档内自由择一」**，它零成本、且在日后新增抬升条件时自动生效，**保留它作为兜底**而不是删掉。
  3. **任何「`1` 档内再排序」的规则事实上等于引入第三档**，而「两档 ⇒ 不存在层叠语义」是明写形态；它还会立刻长出「谁有权用这个排序」这个口子，本库对这类口子的收口方式是不给。
- **抬升的落地面无结构增量。** 三条条件读的全是既有可读状态（`Status.LocationEventCount` · `chapter` · `pastEvent` · `realm` + `level`）；**不新增字段 / 枚举 / 加载期校验，不 bump 存档 schema**。抬升原因**不入快照**——它可由 `Priority` 加当时的 `LocationId` / `Seq` / 等级重算得出，按快照判据不存；回溯「这一步是不是被闸门收窄的」由已落存档的 `PastEventEntry.Priority` 加物化日志的 `prioReason` 回答。

  ```
  ComputeEventOptions 的置位段（落在既有物化流程内，不新增方法）：

    若 Status.LocationEventCount >= location.EventCountLimit：
        闸门分支（既有）：整批 Travel，Priority = 1，prioReason = QuotaGate
        返回

    常规分支：全部选项 Priority = 0
    若 chapter == 1 且 pastEvent 为空：
        开局构筑事件（若已进批）Priority = 1，prioReason = InitialBuild
    若 level == 该境界末级（13 / 17 / 21）：
        Finale 选项 Priority = 1，prioReason = Finale

    EffectivePriority = Max(o.Priority)         ← 既有
    物化后断言 Priority ∈ { 0, 1 }               ← 既有
  ```

- **批次规模 = 常态 3、区间 1–5。** 本服务每次产出的 `EventOptionBatch` **通常含 3 项**，允许 1 到 5。**批次不是固定宽度**——产出侧要按批给出数量，不能套一个常数；**1 项的批次合法**（与 `Priority = 1` 收窄到单项、Travel 20% 随机档同形，不需要额外规则允许它）。**常规批的规模由 `BatchSizeWeights` 掷定**（按篇章分格的五格权重表，走 map 子流；取值与加载期校验见 `systems/balance.md`）；**三种结构性场景不走这张表**——配额闸门批（= 邻接数或 1）、`Priority = 1` 收窄批（= 该档条目数）、闸 ②③ 降级后（少一项）。
- **eventOptions 的生成 / 加权 = 一条十步管线（适用范围 = 常规批）。** 下述十步描述**常规批**；**闸门批在 ① 之前短路**——`LocationEventCount >= EventCountLimit` 成立即走上方的 Travel 段伪码，整批归 Travel，不进本管线（它的取池链是邻接集合、不经 `AllEnabled()`，硬塞进同一条管线会模糊那条明写的例外）；`Priority = 1` 收窄批同理由 `systems/adventure-event/_index.md` 的既有规则给出。

  ```
  ① 取池        AllEnabled<AdventureEventData>() → 按 ChapterScope 命中当前篇章过滤
  ② 白名单收窄   全部 Active arc 的非空 EventWhitelist 取并 → 收窄支撑集；全部为空 = 不收窄
  ③ 条目级闸     闸 ②（Research 槽 / Exchange 库存的可产出性）+ Explore 壳的真身过滤
                → 不合格条目本次不进候选池（PushWarning）
  ④ 类型分布     w_type(t) = BaseTypeWeights(t) × LocationMod(t) × Π_arc PlotTypeMod(arc, t)
                → 在 ①②③ 之后仍有条目的类型上归一化
  ⑤ 批次规模 N   按当前篇章的 BatchSizeWeights 掷定（map 子流），N ∈ [1, 5]
  ⑥ 类型指派     逐槽按 ④ 的分布有放回抽 N 次，且按各类型收窄后的可用条目数封顶
                （抽满一类即把它移出分布并重新归一）；Travel 抽中几次即槽位数 k
  ⑦ 条目抽取     槽内按 w_event = SelectionWeightGrades[SelectionWeight] × Π_arc EventWeights 系数，
                无放回抽取（同批不重复 EventId）
  ⑧ Travel 段    照上方伪码：掷 map 子流 → 80% 从邻接抽 min(k, 邻接数) 个 / 20% 抽 1 个
  ⑨ 逐项物化     赋级 / Research 候选 / Exchange 库存 / OutcomeSpec / SelectCost 取负 / Priority 置位
  ⑩ 收缩保底 + 断言
  ```

  - **类型修正是乘性系数，支撑集不变（承重）。** location 的类型修正一行被定义为「**软**（改权重，不改可及性）」，而只有正的乘性系数天然满足这条定义：加性偏移做不到（一个大负偏移把权重按到 0 或负，可及性就没了，还要额外裁「负权重怎么办」），「白名单 + 权重」本身就是**硬**框定且与 `PlotModulation.EventWhitelist` 撞权威。它也与赋级带已定的「调制修正（乘性，只改权重不改支撑集）+ 截断重分配」逐字同构——同一段物化管线、同一个 map 子流、同一批调制源不能有两套权重语义。取值域与校验归 `systems/game-progression.md`（location 侧）与 `plot-manager.md`（剧本侧）。
  - **乘法可交换 ⇒「location 与 arc 谁先」不是一个需要裁决的量。** 需要真正定序的只剩 ②（支撑集）与 ⑤（规模），而它们各自只有一个来源。
  - **seeded RNG 是消费者，不是并列的第三层框定（承重）。** location 与 `PlotModulation` **改支撑集与权重**，map 子流**在已定形的分布上掷**。写成第三层会让人以为存在「RNG 先于框定」的可能形态，而那形态不存在。本管线不新开子流，RNG 消耗计入 map 子流的 `DrawCount` 并照既有纪律持久化。
  - **收窄支撑集（②③）必须先于算权重（④）。** 否则会算出一个包含空类型的分布，抽中即落空——而本服务不设单项补位，落空只能整格丢掉，等于让批次规模被静默腐蚀。先收窄再归一，空类型自动退出分母。闸 ②③ 排在 ② 之后而非之前，是因为白名单可能把一整类条目筛没，先跑池计数是白算；且闸 ② 的口径明写「与实际抽取链同口径」，而抽取链是收窄后的那一条。
  - **⑥ 有放回、⑦ 无放回。** 一批里出现两个 Combat 是正常的（`combatTier` 三档共用一个类型）；出现同一个 `EventId` 两次不是——与 Exchange `PickMany` 无放回「同批不出现重复商品」同款理由。⑥ 的封顶是同一条纪律在类型层的前置落地：不封顶则某类型抽中 m 次而收窄后只剩 `< m` 条条目时槽位落空，批次宽度会被内容池丰度间接影响，而「玩家可从批次宽度反推内容池状态」正是被否决的形态。
  - **⑧ 单列在 ⑦ 之外**：Travel 的目的地取自邻接集合，那是唯一不经 `AllEnabled()` 的取池，不能混进 ⑦ 的内容池抽取。
  - **⑩ 收缩保底：`Options.Count` 收缩到 0 时补一个 Travel。** 触发面是 Travel 20% 档缩水与闸 ③ 降级叠加到把整批清空（`N = 1` 本就有基础概率，故这不是理论不可达的分支）。**它不是单项补位**——不重新取池、不挑条目，只走既有的 Travel 死局兜底通道（邻接集合恒非空、`selectCost` 无条件可支付）。「不设单项补位」管的是「批次少一项时不另取一条填补」，本条管的是「批次空掉时仍有一个可推进的出口」，两者不是同一件事。
  - **满级后的 Finale 条目是本管线之前的一条闸门式旁路，不是一个高权重条目（承重）。** 角色已达本境界巅峰时，该篇章的 Finale 条目**恒进候选池并直接占一个槽位**，判定发生在 ④ 类型分布与 ⑥ 类型指派**之前**，**不参与类型加权**。
    - **加权只能提高概率，而篇章推进需要的是必现。** 写成高权重条目就存在一批又一批抽不到它的可能，角色卡在巅峰等级上无法推进。
    - **旁路形态同时封死一条越权面：** 若 Finale 靠类型加权出场，一条把 Combat 排除在 `EventWhitelist` 之外的剧本 arc 即可间接封死篇章推进——而 PlotManager **只调内容不调约束**，它不该有这条能力。旁路发生在白名单收窄与类型加权之前，剧本够不着它。
  - **「策划 vs 随机」不设旋钮。** 策划度已由三条既有通道逐级承载（`Priority = 1` 完全策划 / `EventWhitelist` + `EventWeights` 半策划 / 类型分布 × 条目权重的加权随机），是可算的**涌现量**而非要拍板的数字。为它开一个「策划度」参数会落在约束面，且没有任何消费方能说出 0.3 与 0.4 有什么区别。
  - **物化日志：** `[FutureEvent-Weight] location=<Id> arcs=<n> N=<n> dist=<Combat:.42,Exchange:.18,...> k=<n>`。一批只在屏幕切换点产出一次，不落任何热路径（与「逐候选条目算一次池计数」同款代价论证）。
- **重算依据 = 角色的整体历程，不是上一批（承重）。** 新一批**不在上一批基础上增删**，而是依角色的整体状态与历程重新产出——**`pastEvent` 是本服务的一等输入**（与 location 框定、PlotManager 调制、map 子流并列）。**「更新后」这三个字是硬要求**：收口那一次事务里本次事件的账与新 `pastEvent` 条目必须已经算进去，故 life-cycle-service 先取一份**只读投影**（`profile-service.Project(spec)`）再调本方法，把新一批放回同一次提交——**收口仍是一次事务、一个存档点**。**推论：本服务不持有跨批次的状态**；批与批之间唯一的信息通道是 CharacterProfile 本身，这与「模板不可写回」「产出即定稿」共同保证了本服务是无记忆的纯产出侧。
- **批次刷新只有一种形态：整批重算（承重）。** 玩家面对一批 eventOptions 唯一能做的是**择一进入**；**每完成一次选择，本服务整批重算**——**选中一个即等价于跳过了其余全部**，故**不设跳过通道**。
  - **不设单项补位。** 本服务的 API 面是**四个**方法，没有 `TryRefill` 一类的单项补位方法——一旦有它，就要跟着回答「补位落空怎么办」「不生成付不起的事件」「不生成整批不可选的批次」一整串问题，而整批重算让这些问题不存在。
  - **`EventOptionBatch` 不设「至少一个必做项」的不变式**：**本批的每一项都是必做项**，不需要字段去保证它。
  - **「打不过也得打」这条设计意图升级为结构性事实。** 仍**不需要**产出侧的「至少一个可负担 / 可战胜选项」保证：**必须面对的遭遇打不过 → 输掉这一局，是正常且合意的结果**。这与失败侧的既有建制自洽（EnemyCodex 遭遇即记、失败也可能给经验，加上篇章重试模型；**道统残卷的累积已收窄为 Finale 失败专属**，不参与常规遭遇的论证）——**「输」是这个游戏的一个正常出口**；同时它**约束产出侧不要过度保护**，难度的界由赋级带给出已经足够。
  - **`selectCost` 侧同样不欠可负担性保证。** 支付 `selectCost` 是**无条件的可推进行为**，付不起也照付、支付后判定状态、判负进失败流程（见 `systems/adventure-event/common-properties.md`）。**推论：「付不起唯一可选项 ⇒ 无法推进」这条死锁在规则层不成立**，本服务不需要为此做任何产出侧兜底。
- **敌人物化 = 一条五旋钮管线，输入固定、顺序固定、产物落存档。**

  ```
  输入：EnemyData（经 ContentRegistry.AllEnabled() 取池，按 PoolScope / location / 全部 Active arc
        / ChapterScope / EncounterScopes 框定）
      + CharacterProfile（全局等级、所在篇章、隐藏属性）
      + location 框定
      + PlotManager 框定（框定敌人池 + 赋级权重偏移，不触及模板字段）
      + SeedManager 的 map 子流

  ① 框定 + 选模板  ← EncounterScopes.Contains(spec.Tier) + PoolScope（通用条目恒进池，地点 / arc 专属条目叠加）
                    + location + ChapterScope 命中 currentChapter（单值 int，取自 CharacterProfile.chapter）→ 加权抽取
  ② 赋级          ← 角色全局等级 ±2 带 + 权重表（BandFor(chapter)，见 systems/balance.md）
  ③ 卡组展开      ← 模板的功法引用列表（TechniqueRef）逐门按其 Tier 取该层卡牌，并入游离散牌
                    （层数是模板上的固定值，不以 ② 的等级为输入 ⇒ 展开产物在加载期即唯一确定）
  ④ item / power 持有列表  ← 直接取自模板（不由剧本调制改写）
  ⑤ 遭遇参数      ← combatTier 代入五格：TurnLimit / WinMargin（Standard 10 / 1；Practice 8 / 0；Finale 12 / 0）
                    + 三格牌流量 InitialDraw / DrawPerTurn / HandLimit（模板未覆写则取 CombatRulesData 默认值）
  ⑤b 剧本收紧     ← 全部 Active arc 的 PlotModulation.Tighten 五格合并 → 施加 → 钳制 → 断言
                    （Tier == Finale 整档跳过；只施加一次；与 LevelBias 互不影响）

  产出：EnemyInstance（定稿 · immutable · 随 EncounterSpec 嵌在 EventOption.Encounter 上落存档，
        不在战斗开始时二次展开）
  ```

  - **关键规则：等级先定，其余四项以等级为输入，且不叠加第二条强度曲线。** 敌人的战斗强度以 `baseMomentum` 为主刻度——若卡组也随等级放大（更强的牌 + 更高的起始道念），强度就被**平方**，`±2` 带的数值安全性推导立刻失效。**卡组承担风味，等级承担强度。**

    | 旋钮 | 允许做的 | 不允许做的 |
    |------|---------|-----------|
    | **卡组** | **不是旋钮**——按模板的功法引用列表逐门展开、并入游离散牌，物化期不做任何二次改写 | 用「等级越高牌越强」再加一条强度曲线；随赋级改动功法层数；**由剧情线临场改写** |
    | **item / power 列表** | **直接取自模板**（boss 与天劫的「不可被移除的场上特性」写在其专属条目上） | **由剧本调制增删**；突破 `IgnoresProtection` 的配额 |
    | **遭遇参数** | 按 `combatTier` 代入五格（`TurnLimit` · `VictoryRule` · 三格牌流量），再由剧本的 `Tighten` **单向收紧** | 用它抵消等级带的约束；用剧本**放宽**任一格 |

  - **卡组的定制性归内容层**：一个敌人「用什么牌」完全由它模板上的功法引用列表与散牌决定；天劫这类需要专属牌的条目走 `Pool == Enemy` 的敌方专用功法，物化路径上没有第二条通道。
  - **`KeyCardIds` 的校验因此上移到加载期**：关键卡必须落在「功法展开产物 ∪ 散牌」这个并集内，违反 → `PushError`。图鉴写的就是玩家实际会遭遇的牌——而图鉴是事前知识的主通道。口径与逐条报错形态见 `systems/enemies/common-properties.md`。
  - **确定性与存档**：展开不引入随机；产物 `EnemyInstance` **随 `EventOption` 落存档、不重算**（overlay 热更使重算不保证同结果）。
- **剧情线不可调制敌人模板；剧情线与地点各自可拥有专属敌人模板池（承重）。** 差异化的表达位从「改写模板内容」整体移到「**换一个池子抽**」：
  - 每个 `EnemyData` 带 **`PoolScope`**（通用池 / 某地点专属 / 某 arc 专属）；抽取时按 `EncounterScopes`（遭遇档位作用域，`CombatTier[]`）+ `PoolScope`（地点 / arc，逐维度与门、空维度恒真，arc 一侧传**全部 `Active` arc 的集合**）+ `ChapterScope`（篇章框定，空 = 三章通用，入参是单值 `currentChapter`）叠加，全部在 `AllEnabled()` 之后。**通用条目恒进池，专属条目是叠加而非替代**——池归属的唯一权威在敌人条目一侧，location 条目不持敌人清单（见 `systems/enemies/_index.md`）。
  - 「大限将至」线上的绝境敌人 = **该线专属池里的一条完整 `EnemyData`**（自带更凶的样本卡组与 power），**不是**把通用条目临场改凶。
  - **PlotManager 的权力因此收敛为三项：框定用哪个池 · 偏移带内赋级权重 · 拧紧遭遇参数。它碰不到模板的任何字段。**
    这份权力面在内容侧有一个**逐条投影的承载类型 `PlotModulation`**（六个 `[Export]` 字段，一一对应上述三项加事件层的两项权重）：越权的写法在内容层**根本没有字段可填**——`eventPriority`、模板字段、敌人卡组、item / power 列表都不在其中。类型定义见 `plot-manager.md`。
  - **好处**：改写幅度天然有界 · 图鉴词条与玩家实际遭遇恒对得上（专属条目有自己的词条）· 可确定性复算。**代价**：内容量上升（每条专属敌人都是一个完整条目，含图鉴五项词条），归内容排期。
  - **三个框定字段的缺失语义各不相同**：`EncounterScopes` 空数组 → 加载期 `PushError`（`Contains` 恒假 ⇒ 漏填即写了永不进池的死条目）；`PoolScope` **允许为空**（= 通用池），不报错；`ChapterScope` **空数组合法**（过滤写成 `Length == 0 ||`，空即恒真 ⇒ 漏填只是范围偏宽，不是死条目）。逐字段的校验口径见 `systems/enemies/common-properties.md`。
  条目定义见 `systems/enemies/`。
- **遭遇参数由本服务在物化时从 `AdventureEventData` 代入 `EncounterSpec`。** `TurnLimit` / `VictoryRule` / `RewardPoolId` / `BaseReward` 全部在物化时定稿，**`EnemyData` 完全不携带**——否则同一个敌人条目无法同时用于 Practice 与 Combat。**依据 = 唯一物化点 + 产出即定稿**：消费侧不得回查模板重算，故 `EncounterSpec` 必须自带取值，不能只带一个 `EncounterId` 让 combat-service 回查。**物化时代入也是剧本调制的天然挂点**（PlotManager 可拧紧遭遇参数）。类型形态见 `systems/services/combat-service.md`。

- **剧本收紧的施加侧全在本服务（旋钮 ⑤b）。** 输入 = 全部 `Active` arc 的 `PlotModulation.Tighten` 按逐格算子合并出的一份五格增量（类型形态、方向约束与合并算子见 `systems/services/plot-manager.md`；十个界常量的取值见 `systems/balance.md`——**两处均只回链，本节不复述定义与数字**）。落位固定在**旋钮 ⑤ 之后、`EncounterSpec` 定稿之前**，**整批只施加一次**。
  - **`Tier == Finale` 整档跳过**（不是错误、不告警），闸的理由见 `plot-manager.md`。
  - **与 `LevelBias` 互不影响** ⇒ 两者的先后不是需要裁决的量。
  - **施加式：每格的 `Clamp` 一侧写硬界常量，另一侧写该格的施加前值本身。**

    | 格 | 施加式 |
    |---|---|
    | `TurnLimit` | `Clamp(v + TurnLimitDelta, MinTurnLimit, v)` |
    | `WinMargin` | `Clamp(v + WinMarginDelta, v, MaxWinMargin)`（反向格；`v` 恒 `>= 0`） |
    | `InitialDraw` | `Clamp(v + InitialDrawDelta, MinInitialDraw, v)` |
    | `DrawPerTurn` | `Clamp(v + DrawPerTurnDelta, MinDrawPerTurn, v)` |
    | `HandLimit` | `Clamp(v + HandLimitDelta, MinHandLimit, v)` |

    （`v` = 该格的施加前值，即旋钮 ⑤ 代入的档位默认值或模板覆写值。）

  - **把施加前值写成 `Clamp` 的一侧，是为了让「永不放宽」不依赖方向校验。** 方向由加载期校验保证（delta 符号越界 → `PushError`），但**加载期校验够不着 overlay 推上来的坏数据**；施加式自带这条边界后，即便一条 `TurnLimitDelta = +3` 绕过校验落到这里，`Clamp` 的上界仍是 `v` ⇒ 结果不高于施加前值。**收紧管线因此在数据层面单调**，与「越权的写法在内容层根本没有字段可填」是同一条纪律在物化侧的延伸。
  - **三格牌流量在此必须代入定值。** `EncounterSpec` 的三格是可空覆写组（`null` = 取 `CombatRulesData` 默认值），但**一旦本步产生非零收紧，该格不得再留 `null`**——产出即定稿、消费侧不回查模板重算，留 `null` 会让 combat-service 读回未收紧的默认值。
  - **物化期钳制 5 条，一律削平而非拒绝**（一条 overlay 推上去的坏 `Tighten` 应当被削平，而不是让这一批 eventOptions 产不出来——与「合法池不足 3 条目时显式降级、不静默」同一条纪律：降级但留痕）。任一格被硬界削平 → `PushWarning`，带**全部 `Active` arc 的 `Id`** + 字段名 + want / got。
  - **`EncounterTighten` 本身不进 `EncounterSpec`、不落存档**：它是本步的一个输入，施加完即消失；落存档的是**施加后的五格定值**。⇒ 本机制对存档 schema 零改动、零迁移。
  - **物化日志并进 `[FutureEvent-Materialize]`：**

    ```
    [FutureEvent-Materialize] tighten=<turnΔ>/<marginΔ>/<initΔ>/<drawΔ>/<handΔ>
    ```

    记的是**实际生效的增量**（钳制之后的差值），不是合并出的原始 delta——否则被削平的那一批日志会与存档里的定值对不上。

- **成本量值取负发生在本服务的物化组装阶段。** 内容作者在 `AdventureEventData` 上以**正数量值**标注 `lifeSpanCost` 等成本（「耗 3 点寿元」写 `3`）；**本服务在组装 `SelectCost` 时取负**填入 `ChangeElement.BaseValue`，从而满足既定的带符号约定（负 = 消耗，正 = 产出）。这条转换**只在此处发生一次**——下游（life-cycle-service / ProfileManager）拿到的一律是带符号 spec，不做任何符号推断。
- **战斗类事件在物化时精确标注敌人等级。** `combatTier` 三档的 `EventOption` 需向玩家**精确展示敌人的等级**（否决模糊的危险度档位）——玩家据此与自身等级比对，把「越级挑战」当作可主动选择的风险 / 回报。
- **敌人也由本服务物化：`EnemyData` → 充实 / 改写 → 指派给事件。** 敌人的**静态数据**集中在 **`EnemyData`** 集合（稳定 `Id` + 图鉴文案 + 基准数值 + **样本卡组**；玩家侧的那一面即 EnemyCodex）。本服务在物化一个战斗类事件时：**取出一份模板 → 依情境充实 / 改写（enrich / modify）→ 把结果指派给该事件**。**`EnemyData` 另需两个持有列表字段：item 持有列表与 power 持有列表**——**敌人没有储物袋**（那是角色的道具容器），道具与 `Power` 直接挂在模板上；战斗组装时 item 列表成为敌人侧的「本场可用道具」，power 列表按 `UsableScene` 过滤后入场为受保护永久物。**这给「物化时充实 / 改写」多了两个可调旋钮**（除等级与样本卡组外，还可调这一场敌人带哪些道具 / 特性）。

  - **敌人等级由此答定：它不是模板上的死值，而是物化产物。** 同一个敌人模板可在不同篇章、不同情境下以不同等级出场——这正是「多数属性由物化决定」在敌人上的应用。
  - **连带答定「等级标注的承载字段」的一半：** 既然等级在物化时确定，它就**随物化产物一同定稿并落存档**，而不是由 ViewModel 现查模板算出来。
  - **它是「模板 ↔ 实例」通则的第三个实例**（前两个是 `AdventureEventData ↔ EventOption`、`CardData ↔ CardInstance`，见 `systems/architecture.md` 总则 6）：模板是 ContentRegistry 里的共享只读单例，**本服务不得写回它**；改写只发生在物化产出上。
  - **样本卡组同理**：模板给基线卡组，物化时可改写（Finale 的天劫即极端情形——定制卡组的 Enemy）。

- **赋级的合法区间 = 角色当前等级 `±2` 的对称带（三章统一 · 承重）。** 物化赋级落在 `[角色等级 − 2, 角色等级 + 2]` 内，在全局序 **1–22** 上截断。
  - **它是一条相对 `diff` 的带，不是按境界给的绝对天花板**，且**同时给出上界与下界**（此前只有上界）。
  - **本服务只读「当前篇章的带」这一个概念，不为分章写分支**（读取面 = `BandFor(chapter)` 一次取值）。带边界与带内权重同住一份平衡资源，**资源形态与加载期校验见 `systems/balance.md`**。
  - **PlotManager 不得改带边界，只能对带内权重施加乘性调制**（只改权重不改支撑集）——与本服务权力面三项中的「偏移带内赋级权重」是同一条。
  - **赋级规则挂在 Enemy 上，不挂在事件类型上** ⇒ **`combatTier` 三档一视同仁**。天劫只是 Enemy 的一种，不享有等级规则上的例外（见 `systems/adventure-event/combat/`）；Practice 的「低风险」由回合数与胜负门槛承担，**不由「派个更弱的对手」承担**。
  - **推论 ①（承重 · 三章全部成立）：一次惨败的量级由规则层框住。** 上界统一为 `+2`，最坏落差为 9（炼气十三层 `baseMomentum` 15 遇筑基中期 24）；对炼气段 100 点的寿元预算约为 9%，与回寿三档的中档同量级——赋级带因此仍是「一次失败最多有多重」的规则层闸，而不是唯一防线。
  - **推论 ②：越阶遭遇只出现在每个境界的末两级**——12 · 13 → 筑基；16 · 17 → 金丹；20 · 21 → 元婴。**三章统一**，越阶压迫感自动向篇章尾部集中，与 Finale 落在篇章边界同向。
  - **推论 ③：`±2` 是无例外的硬规则。** 任何调制源（PlotManager、location 框定、事件模板、Finale）都不得产出带外 `diff`；**赋级函数不接受任何区间覆盖参数**——不给这个口子，就不存在「谁有权用它」的问题。调制源只能改**带内权重**。
  - **推论 ④：上界档不必然越阶。** `diff = +2` 只在境界末两级才是越阶；境界中段的 `+2` 是同阶。
  - **推论 ⑤：本服务不需要境界表。** 赋级 = 全局序上一次加减 + 截断；境界边界的特殊性由 `baseMomentum` 的跨度放大自然承载。
  - **推论 ⑥：元婴（全局 22）**——角色 21 时带为 `[19, 22]`；抵达 22 即轮回终点，实际不产生遭遇。
  - **推论 ⑦：带内分布权重表**（五档权重 × 调制修正 × 截断重分配 × 批内去重），见 `systems/balance.md`。**截断重分配必须显式实现**：全局序 1–22 截断后落空的档位权重按比例并入带内剩余档，否则 L1 · L2 的抽取会出现权重和不为 1 的实现分歧。
- **Research 的构筑面板候选在物化阶段掷定，随 `EventOption` 落存档。** 模板上的 `ResearchSlotSpec[]` 在本服务物化时展开为 `ResearchSlot[]`：逐槽按 `AllowedOperations` 取候选池、抽 `CandidateCount` 条、并为每条掷定它附带的 `ManaDelta`（风险档为 `±1`，其余为 `0`）。
  - **随机源 = `RngStream.Reward` 子流，不新开子流**：`Reward` 已承载完全同构的用途（候选预先掷定 + 落存档 + 绝不重抽），而奖励候选与构筑候选从不并发。
  - **两条取池链均为复用，本服务不新增抽取代码**：法宝候选直接调 `profile-service` 的 `TryPickGrantableMany(Item, Character, rng, 3)`；功法候选走 `CultivationTechniqueData` 仓储的 `AllEnabled()` / `DrawPool<T>` 加权无放回抽取，**它是 `DrawPool<T>` 的第五个调用方**，并在交给抽取之前自叠两层调用方过滤：`Pool != Enemy` 与**灵根修习准入**（后者需读 `Profile` 取角色灵根，按分界判据不进 `DrawPool<T>`；见 `systems/character-profile/deck/_index.md`「灵根修习准入」）。**开局构筑三选一与闭关学新共用这一条链**，准入只写在这一处、不各写一遍。
  - **候选必须在此刻算定，不能等到面板打开。** 依据是既有的防重掷纪律——候选若在结算那一刻才掷，玩家退出重进即可重掷；`ManaDelta` 同理，**风险档正是靠「结果已定、只是尚未展示」才能成立**。槽与候选的字段面见 `systems/adventure-event/research/common-properties.md`。
- **Exchange 的库存在物化阶段掷定，随 `EventOption` 落存档。** 模板上的 `ExchangeSpec.StockRules` 在本服务物化时展开为 `ExchangeOffer[]`：逐条规则按 `Kind` 映射到对应仓储取池、按 `RarityFilter` 过滤、按 `RarityTier` 权重无放回抽 `SlotCount` 条，再逐条从「族 × 稀有度」定价表该格抄下 `Currency`、算出 `BasePrice` 与 `ListPrice`。
  - **随机源 = `RngStream.Shop` 子流**，它已在子流清单里，不新开。
  - **取池链沿用授予池那一条，不另写一段**：`AllEnabled()` → 按 `Kind` 映射仓储 → 排除 `ExclusiveSource != null` → `Card` / `CultivationTechnique` 两族排除 `Pool == Enemy`、功法族另叠灵根修习准入 → 排除已持有（能力族）→ `RarityFilter` → 加权 `PickMany`（无放回 ⇒ 同批不出现重复商品，免费成立）。**不新建任何抽取池**——五个商品族一一映射到既有仓储。
    - **能力族商品经第二级 `TryPickGrantableMany` 取池，其余三族直用第一级 `DrawPool<T>`**（`[采纳推荐 — 待复核]`）。理由：「排除已持有」是需要读 `Profile` 的那道过滤，它必须只写在一个地方；走既有门面方法即可，**不给 `GrantPoolPicker` 新开入口**——它已是全库唯一的能力抽取处，入口越多越容易漏用。代价：本条取池链因此分裂为两种写法。
  - **`ListPrice` 在此定稿，`ModifierKey.ShopPrice` 也在此施加。** 依据是「一个 `ModifierKey` 只能有一个施加点」：商店价格必须先算才能标价 ⇒ 施加点在物化 / 展示侧，**两个货币行**的两个修正列因此恒为 `null`（见 `systems/services/profile-service.md`）。**代价明写：** 轮回中途新获得的降价修正不影响已定稿的库存，下一个 Exchange 事件才生效。
  - **以物易物的 `BarterStock` 由 `ExchangeSpec.BarterRules` 逐条平移得出，不经取池链、不掷 `RngStream.Shop`。** 一条 `ExchangeBarterRule` 恰好平移为一个 `BarterOffer`（`OfferId` 与 `ExchangeOffer` 同一命名空间、`SoldOut` 初值 `false`、产出为功法时抄下层数），**不读定价表、不施加任何 modifier 与折扣、不参与三道短缺闸**——它是内容作者点名的定值编排，没有分母可算。`BarterRules` 为空即 `BarterStock` 为空数组。字段面与六条加载期校验见 `systems/adventure-event/exchange/common-properties.md`。
  - **`RerolledCount` 初值为 0。** 刷新是结算侧的动作（花灵石重掷整批库存，走同一条取池链与同一个 `Shop` 子流），本服务只负责给出初始库存。规则见 `systems/adventure-event/exchange/_index.md`，字段面与校验见其 `common-properties.md`。
- **Explore 的取池附加一条过滤：真身被 `ContentEnabled == false` 关闭，或真身是 Exchange 且其闸 ② 不通过 ⇒ 该 Explore 壳本次不进候选池。** 判定与 `AllEnabled()` 同一档，在取池阶段做一次；两个分支同形同档——否则玩家付掉壳的 `lifeSpanCost`、揭示之后撞上一个空商店，而这正是「失败点必须前移到付费之前」所防的形态。
  - **不加这条即有一个能上线、线上不可见的洞**：线上用 flags 关掉一个坏掉的 Combat 条目后，指向它的 Explore 壳仍在池里（壳自己是 enabled 的），玩家照常选中、照常付费，揭示后落到那个被关闭的条目上——放量开关对这条路径静默失效。
  - **它是抽取侧过滤，不违反「读取侧不过滤」**：`pastEvent` 回溯与图鉴解析照常解析 disabled 条目。
  - **真身的启用态不进 `EventOption` 快照**（随 flags 变、重算不保证同结果且无消费方），只在取池那一刻查一次。代价与被否决的替代见 `systems/adventure-event/explore/_index.md`。
- **候选池短缺由三道闸处置，两处都不留空面板（承重）。** Research 候选与 Exchange 库存各自的取池链都可能抽不足所需条数（`PickMany` 返回 `false`）；处置分三个时机，两个调用点共用同一层次、逐格取值不同。

  | 闸 | 时机 | Research | Exchange | 失败处置 |
  |---|---|---|---|---|
  | **①** | 内容加载期（合并后强校验，走 `AllIncludingDisabled()` 的同一遍） | 每个 `ResearchSlotSpec` 的每类内容池型操作（`LearnTechnique` / `GrantItem`）：通用池条目数 ≥ `CandidateCount` + `ResearchPoolMargin` | 逐 `Kind` 逐 `RarityTier` 档位核算：覆盖该档位的全部规则 Σ`SlotCount` + `ExchangePoolMargin` ≤ 该档位的池条目数 | **`PushError`** —— 编排错误在启动期就大声失败。断言全文见两个子类型的 `common-properties.md` |
  | **②** | 取池期（本服务挑候选事件条目、物化之前） | 该条目**至少一个槽**能产出 ≥ 1 条候选；`AllowDecline == false` 的槽**逐槽** ≥ 1 | 该条目全部 `StockRule` 的可产出 offer 数之和 ≥ 1 | **该条目本次不进候选池** + `PushWarning` + 定位上下文；判定结果**不落快照** |
  | **③** | 物化期（实际抽取） | 该槽候选数降级为实际抽到的条数；某槽降到 0 → 该槽不进 `ResearchSlot[]` | 该规则少产出几个 offer；某规则降到 0 → 少一批槽位 | `PushWarning` + want / got |

  - **闸 ② 与既有的 Explore 壳过滤同形同档**：同样是取池阶段的一次判定、不落快照，防的同样是加载期够不着的**运行期收缩**（flags 秒关、玩家已持有导致的池收缩）。**它是「不能留空面板」的真正防线。**
  - **闸 ② 的阈值取 `≥ 1` 而不是 `≥ 所需`**：取后者会让一次轻微的运行期收缩把整类事件从池里删掉（Research 尤其致命，它是构筑的唯一落点），其余交给闸 ③ 降级。硬约束原文是「不留空面板」，不是「面板必须是满的」。
  - **闸 ② 的计数必须与实际抽取链同口径**：能力族走 `profile-service.GrantableCount(kind, scope, rarityFilter)`（`rarityFilter` 可选，`null` / 空 = 不限），内容族走 `DrawPool<T>` 同款过滤后的条目数。用不含 `RarityFilter` 的宽松计数会出现「总池非空、过滤后为空」⇒ 闸 ② 判过、闸 ③ 抽空，而闸 ② 之所以能声称「闸 ③ 的空面板分支理论不可达」，全部依据就在这个同口径上。
  - **代价明写：** 每批产 3–5 项、只发生在屏幕切换点，逐候选条目算一次池计数不落在任何热路径上。
  - **闸 ③ 的空面板分支是理论不可达的缺陷分支：** 全部槽 / 全部 offer 皆空到达此处 ⇒ `PushError` + 上报，**该条目本次不进批次、本批少一项**。**不另取一条填补批次**——本服务不设单项补位，而 1 项的批次本就合法，少一项不需要额外规则允许它。
  - **闸 ② 移出条目后的退化情形不新增任何分支：** 批次规模照常由既有产出逻辑给出（可缩到 1 项）；过滤后候选池为空则落既有的「内容池为空 = 坏数据 → `PushError` + 抛」；而**邻接集合不经 `AllEnabled()` ⇒ Travel 兜底恒可产出**，轮回死锁在规则层不成立。
  - **闸 ② 对 `AllowDecline == false` 的槽逐槽收紧**，是因为那类槽卡住玩家：开局构筑事件靠 `eventPriority = 1` 强制进入，任一槽降到 0 候选即是一个无法提交的强制面板。被拦下时该条目不进批次，**首批退化为常规批**（见 `systems/adventure-event/research/_index.md`）。
  - **分界判据 = 玩家有没有为这一次产出付过钱。** 付过钱的产出（premium bundle 的空池三道闸，见 `systems/monetization.md`）→ **少给即事故**，把失败点前移到掏钱之前，宁可拒绝进入流程，绝不降级替代。没付钱的玩法内容（Research 候选 / Exchange 库存）→ **降级到更少是可接受的方差**，硬拒绝反而制造更严重的后果：Research 是构筑的唯一落点，把它整类拦掉等于剥夺轮回内构筑；把一批 eventOptions 拦成空批则直接触及轮回死锁。**两套看似相反的处置由这一条判据分开**，不写下它，后来者会把两处读成矛盾。
  - **日志形态：**

    ```
    [FutureEvent-PoolGate]   skip event=<EventId> type=<Research|Exchange> reason=insufficient-pool detail=<kind/slot> pool=<n>
    [FutureEvent-Materialize] empty panel: instance=<InstanceId> event=<EventId> type=<Research|Exchange>
    ```

    闸 ② 用 `PushWarning`——flags 秒关是正常运营手段，一个条目因此暂时退出候选池不是缺陷；闸 ③ 的空面板分支用 `PushError`——它意味着闸 ② 判定与实际抽取不一致，是真缺陷。

- **Explore 的真身类型分布不是本服务的一个旋钮，而是取池加权的涌现结果。** 遮罩的是模板上写死的固定条目 ⇒ 物化与揭示两处都不掷这个权重；`AdventureEventData` / `LocationData` / `PlotModulation` 三处均**不为它新增字段**。location 的类型修正只及「有多少 Explore」这一行，及不到「秘境里多半是什么」。权威与占比的编排口径见 `systems/adventure-event/explore/_index.md`。
- **Explore 的揭示落在既有 `eventStart` 阶段内，不新增服务方法。** 揭示是 `revealed = option with { IsRevealed = true }` 一次派生（当前批里那份原实例不动，符合「产出即定稿」）；**resolver 按真身的 `eventType` 选取，不按 `EventOption.EventType`**——后者恒为 `Explore`，照它选会把一个战斗真身送进 `GenericEventResolver`。这与下条的组装判据是同一条纪律的两处应用。
- **通用结算器从 outcome / effect 定义算出的授予一律记 `Source.EventOutcome`。** 授予来源的分野判据是**谁组装出这条 element**，不是事件类型：Research / Explore / Travel 的 outcome 授予、以及 Exchange 中**不走购买流程**的 outcome（对话结果、赠礼）同归此值；走购买流程的那一条走 `Source.ExchangePurchase`，由 combat-service 交出的 `Spoils` 走 `Source.CombatReward`。**推论：Explore 选项按其揭示后的真身归类**——`EventType` 恒为 `Explore` 而真身在 `RevealedEventId`，一个揭示出战斗真身的选项，其战利品出自 combat-service，故不记 `EventOutcome`。见 `systems/common-properties.md`。

Source: `handoffs/2026-08-30-exchange-barter-support.md` · `handoffs/2026-08-30-affinity-and-technique-attributes.md` · `handoffs/2026-08-30-life-lifespan-merge.md` · `handoffs/2026-08-25-currency-split-spirit-stone-and-immortal-jade.md` · `handoffs/2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md` · `handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md` · `handoffs/2026-07-26-event-priority-skip-semantics-and-hotfix-scope.md` · `handoffs/2026-07-27b-service-api-contracts.md` · `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md` · `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md` · `handoffs/2026-08-04b-mtg-loanwords-card-types-and-intent-snapshot.md` · `handoffs/2026-08-05-level-band-stack-save-and-token-free-deck.md` · `handoffs/2026-08-05b-location-fields-event-count-limit-and-skip-refill-closure.md` · `handoffs/2026-08-06b-asymmetric-ch1-band-consented-power-loss-and-chapter-retry-shape.md` · `handoffs/2026-08-06c-skip-channel-removal-priority-two-tier-and-location-codex-edges.md` · `handoffs/2026-08-06d-combat-open-questions-mass-closure.md` · `handoffs/2026-08-09c-past-event-trace-schema.md` · `handoffs/2026-08-11-plot-content-localization.md` · `handoffs/2026-08-15c-event-type-collapse-and-batch-shape.md` · `handoffs/2026-08-16g-travel-mechanics-and-location-carrier.md` · `handoffs/2026-08-16h-grant-source-assembler-criterion.md` · `handoffs/2026-08-16i-plot-data-encoding.md` · `handoffs/2026-08-17-travel-destination-and-status-change-elements.md` · `handoffs/2026-08-17b-research-build-panel-and-deck-elements.md` · `handoffs/2026-08-17c-explore-reveal-mechanics.md` · `handoffs/2026-08-17d-exchange-mechanics-and-transaction-discipline.md` · `handoffs/2026-08-17j-event-option-derived-persistence.md` · `handoffs/2026-08-19-pickmany-shortfall-handling.md` · `handoffs/2026-08-22-event-generation-weighting-pipeline.md` · `handoffs/2026-08-22-event-outcome-spec-fields.md` · `handoffs/2026-08-22-priority-elevation-criterion.md` · `handoffs/2026-08-22-enemy-pool-chapter-scoping.md` · `handoffs/2026-08-22-band-boundary-config-placement.md` · `handoffs/2026-08-22-encounter-tighten-fields.md` · `handoffs/2026-08-22-hidden-stat-grant-direction.md` · `handoffs/2026-08-25-enemy-deck-from-techniques-and-ai.md`

## 管理器

| manager | 职责 |
|---------|------|
| **EventOptionManager** | 依 CharacterProfile 产出 / 重算 eventOptions；location 框定与 seeded 抽取 |
| **PlotManager** | 隐藏剧本：按 key points 解析本地剧本节点、隐藏属性阈值 → 调制。**纯本地**。详见 [plot-manager](plot-manager.md) |

## 服务角色 / API 面（契约）
> _总则与共享类型见 `systems/architecture.md`「API 契约总则」。**本服务纯本地，永不跨进程边界，故全部方法为形态 A**——物化是纯内存计算，PlotManager 亦不跨边界（剧本内容属本地内容层）。_

| 方法 | 形态 | 完整签名 | 失败语义 |
|------|------|----------|----------|
| 物化一批 | A | `EventOptionBatch ComputeEventOptions(CharacterProfile character)` | 内容池为空 = 坏数据 → `PushError` + 抛 |
| 结算后重算 | A | `EventOptionBatch RefreshAfterEvent(CharacterProfile character, string resolvedInstanceId)` | 同上。**`character` 可以是一份投影 profile**（含本次收口尚未提交的账与新 `pastEvent` 条目），本服务不区分投影与已提交视图 |
| 当前批 | A | `EventOptionBatch Current { get; }` | — |
| 剧本分支 | A | `OpResult ChooseBranch(string branchId)` | 业务失败 → `OpResult`；PlotManager 的**唯一对外投影**；剧本内容属本地内容层，无远端请求 |

```csharp
public sealed record EventOption(                 // 定稿实例：immutable 引用类型，落存档
    string             InstanceId,                // 本次物化实例的稳定标识；pastEvent / 存档引用它
    string             EventId,                   // 溯源到模板：ContentRegistry.Get<AdventureEventData>(EventId)
    EventType          EventType,                 // Explore 时 = Explore 本身；真身见 RevealedEventId
    int                Priority,                  // 物化时置位；取值域 { 0, 1 }
    ProfileChangeSpec  SelectCost,                // 物化时组装：内容侧正数量值 → 取负填入 BaseValue（modifier pipeline 尚未施加）
    bool               IsRevealed,                // Explore：是否已揭示
    string             RevealedEventId,           // Explore 遮罩的固定事件（内容侧即已确定）
    string             DestinationLocationId,     // Travel 的目的地 LocationData.Id；非 Travel 为空串
    IReadOnlyList<ResearchSlot> ResearchSlots,    // Research 的构筑面板决策槽（候选已掷定）；其余类型为空
    IReadOnlyList<ExchangeOffer> ExchangeStock,   // Exchange 的定稿库存（商品与标价已掷定）；其余类型为空
    IReadOnlyList<BarterOffer> BarterStock,       // Exchange 的以物易物定稿 offer（BarterRules 逐条平移，不掷随机）；其余类型为空
    int                RerolledCount,             // Exchange 已刷新次数；供刷新价递增与存档恢复
    IReadOnlyList<AbilityChangeSlot> AbilityChangeSlots,  // 置换 / 禁用的决策点候选（物化时掷定）；无此类产出时为空
    EventOutcomeSpec   OutcomeSpec,               // 产出侧定稿载体：抽取 / 权重已掷定，结算时只选一侧
    EncounterSpec      Encounter                  // 战斗真身非空、其余为 null；EnemyInstance 嵌在其内
    );

public sealed record EventOptionBatch(
    string                     BatchId,
    IReadOnlyList<EventOption> Options,
    int                        EffectivePriority);  // 本批最高优先级档（0 或 1）；有效可选集 = Priority == EffectivePriority 的全部
// 无 AnySkippable，也无「每批至少一个 IsMandatory」的不变式——
// 本批的每一项都是必做项，唯一的推进方式是择一进入。
```

**`OutcomeSpec`（类型 `EventOutcomeSpec`）= 产出侧的定稿载体，顶层按结算走向分侧。** 它顶层分 `OnResolved` / `OnFailure` 两侧，**不按事件类型分侧**——与「授予来源的分野判据 = 谁组装出这条 element」同一条判据。

```csharp
public sealed record EventOutcomeSpec(
    ProfileChangeSpec OnResolved,     // 恒非 null；无产出时为空 spec
    ProfileChangeSpec OnFailure);     // 同上
```

- **两侧的载体类型复用 `ProfileChangeSpec`，不新建窄类型。** 三条依据全部来自既有形状：**成本与产出共用一个类型**是明写形态（产出侧另造窄类型等于把已合并的东西重新分叉）；`eventEnd` 的五步组装第 ① 步本就是拼各列，选中一侧后直接并入、零 element 翻译；`SelectCost` 已示范「复用宽类型 + 恒空列断言」这套纪律，读者不需要学第二套。**代价明写**：outcome 侧多数列恒空，需逐列断言（见下）。
- **术语纪律：这里的产出原语叫「产出 element」，不叫「效果」（承重）。** 本库「效果」一词有**两个所指**——战斗侧的效果原语（`EffectData` 的原子操作 + `KeywordData` + `TargetSlot` / `EffectScope` / `EntryFilter`，作用于战场条目与手牌、寿命一场战斗）与本处的产出 element（`ProfileChangeSpec` 各列，作用于 `CharacterProfile` / `PlayerProfile` 的字段、经 `ProfileManager.TryApply` 施加、跨事件持久）。**两套作用面不相交**：战斗效果原语没有一个写 Profile，而一个事件产出里根本没有战场。混用同一个词会让人以为产出面依赖战斗侧的关键字体系，而它不依赖。与「字段名取 `OutcomeSpec` 而非 `Outcome`」同源的防混淆纪律。

**两侧各自开放的列 = `Elements` / `AbilityElements` / `DeckElements` 三列，其余各列恒空。** 判据一句（写判据而非清单）：**内容作者能如实声明的量才进 `OutcomeSpec`；由服务算出绝对值、或由代码采集的，一律不进。**

| `ProfileChangeSpec` 列 | outcome 侧 | 依据 |
|---|---|---|
| `Elements`（资源） | ✅ | 经验 / 寿元回复 / `manaLimit` / 隐藏属性 / 货币走它；key 取值域另收紧，见下 |
| `AbilityElements`（能力） | ✅ | **只承载物化时定稿的授予**（`Op == Grant`）；置换 / 禁用走 `EventOption.AbilityChangeSlots` 的决策点，见下 |
| `DeckElements`（卡组） | ✅ | 功法的学 / 升 / 弃、散牌的增删；与能力侧同为「`SelectCost` 恒空、只能在 outcome 侧」 |
| `Stats`（统计计数） | ❌ | 统计由各消费点代码采集，内容侧声明它等于让一个 `.tres` 伪造统计数字 |
| `StatusChanges`（Status 规则字段） | ❌ | band 与 location 字段由 life-cycle-service **算出绝对值**后置入（band 要读前值 + 回滞），内容侧写不出绝对值 |
| `PlotElements`（剧本） | ❌ | 推进逻辑归 PlotManager 独占；内容条目直接推进剧本 = 绕过「剧本表达强制性只能靠收窄候选池」这条边界 |
| `EventStateChanges`（事件态） | ❌ | 整块中间态，由 life-cycle-service / combat-service 组装；`AppliedChange` 累加时本就要剔除它 |
| `RngElements`（RNG 子流） | ❌ | 唯一组装路径是 `SeedManager.AttachRngState(spec)` |
| `TraceElements`（履历） | ❌ | 一次事件恰一条痕迹，由 life-cycle-service 组装；内容侧写它即自指 |
| `SettingChanges`（账号级设置） | ❌ | 设置只在设置屏发起，永不发生在事件结算里 |
| `CodexElements`（图鉴解锁） | ❌ | 触发采集与去重归 `CodexManager`；内容侧声明会与它的组装打架，`AppliedChange` 记的账与提交的 spec 不一致 |

**恒空列的表述逐列穷举，不写列数。** 与「`ProfileChangeSpec` 的列表数不进承重表述」同一条纪律：列随字段族增长，写死数字等于每加一列就要回改一次承重句。

**`Elements` 内的 key 取值域收紧（outcome 侧的第四条不变式）。** `Elements` 开放不等于全部 `CostKey` 开放：

| `CostKey` | 物化后可出现 | 说明 |
|---|---|---|
| `ExperiencePoint` · `Faith` · `Bloodlust` | ✅（**只由服务展开**） | 由物化组装从 `ExperienceGrade` / `HiddenStatGrade` 的平衡表映射展开；**`OutcomeRule` 写不出它们**，见下方两层分野 |
| `ManaLimit` · `SpiritStone` · `ImmortalJade` | ✅ | 事件产出的常规面；`ManaLimit` 另受幅度约束，见下 |
| `LifeSpan` | ✅（**仅正向**） | 回寿通道 A；成本侧恒 ≤ 0、产出侧恒 ≥ 0。**`eventType == Travel` 的条目该 key 恒不得出现**（既有结构性禁令） |
| `PowerFragment*` 七 key | ❌ | 道统残卷由 life-cycle-service 在 Finale 收口时组装（含账号级掷骰与幂等键），内容条目声明它 = 一个 `.tres` 能伪造发放记录 |
| `BundleRedeemedOrdinal` | ❌ | 付费兑现水位；`BundleGrantOrdinal` 更是后端独占、根本不是 `CostKey` 成员 |

- **「物化后可出现的 key」与「模板可声明的 key」是两张表，不是一张（承重）。** 把它们写成同一张表会让内容作者能直接写 `FixedResource(ExperiencePoint, 7)` / `FixedResource(Faith, 12)`——**同一个产出当场有两个书写位**（枚举档 + 裸数字），而「内容侧不落裸数字、走枚举档 + 平衡表映射」正是经验与隐藏属性的既定范式，平衡表的反推口径会因此失效。故 `OutcomeRule.FixedResource` 的可写 key 收窄为 **`LifeSpan` / `ManaLimit` / `SpiritStone` / `ImmortalJade`** 四个，加载期拒绝其余；`ExperiencePoint` / `Faith` / `Bloodlust` **只能由物化组装从档位表展开**。
- **`ManaLimit` 的单次变动幅度恒为 1，产出侧必须显式闭合。** `manaLimit` 的两个修正列被封死正是为了守住这条承重规则；若内容侧能写任意 `Magnitude`，一个 `.tres` 即可把 ±1 放大为 ±3，且**能上线、线上不可见**（要到玩家吃到 +3 才发现）。故加一条加载期校验 + 一条物化断言：`ResourceKey == ManaLimit ⇒ Magnitude == 1`。它是 `ResearchCandidate.ManaDelta ∈ { -1, 0, +1 }` 的对偶。

**`AbilityElements` 只承载 `Op == Grant`，且作用域恒为 `Character`（正向白名单）。** 合法子集表对 `Source.EventOutcome` 一行只开 `(Power, Character)` / `(Item, Character)` 两格——法则 `(Power, Player)` 与**古宝 `(Item, Player)` 双双为 ❌**。故断言写成一条**正向**判定：`Op == Grant` ∧ `Scope == Character` ∧ `Source == EventOutcome`。

- **正向白名单替掉两条负向排除。** 负向写法每新增一个 ❌ 格就要回来补一条，与「合法子集表是静态查表」的既有形态不同构；正向写法与该表逐格对齐，表翻一格即校验跟着变。
- **事件产出不能给账号级古宝（承重）。** 古宝是账号级持久资产；由轮回内事件产出会改变账号级经济，也会绕开「账号级授予只走残卷 / 付费 / 成就」三条既定渠道。`GrantFromPool` 的 `PoolKind` 相应拒绝 `PlayerItem`。

**置换 / 禁用不由 `OutcomeSpec` 承载，走 `EventOption.AbilityChangeSlots` 的决策点（承重）。** 置换型剥夺与三档禁用需要**一份施加之前就已定稿的候选**给玩家做决策，而 `ProfileChangeSpec` 的 element 只承载已定稿的最终账——两者不是同一层东西。

```csharp
public sealed record AbilityChangeSlot(       // 定稿 · immutable；物化时掷定，退出重进不重掷
    int             SlotIndex,
    AbilityChangeOp Op,                       // Remove（置换的失去侧）/ Disable；恒不为 Grant
    AbilityCarrierKind Kind,
    AbilityScope    Scope,                    // 恒为 Character
    string          LoseAbilityId,            // 被剥夺 / 被禁用的目标，已掷定
    string          GainAbilityId,            // 置换的得到侧，已掷定；纯禁用为空串
    DisableDuration Duration,                 // Op == Disable 时有效；否则缺省
    bool            AllowDecline);            // 置换 = true（拒绝零代价）；禁用型 = false（只告知）
```

- **形状与 `EventOption.ResearchSlots` 同构，随机源同为 `RngStream.Reward` 子流。** 两者都是「物化时掷定的决策点候选 + 落存档 + 绝不重抽」，不发明第二套形态。
- **掷定时点前移到物化时，与「抽取在物化时掷定」一条纪律收口。** 三个决策点面板（Research 槽 · Exchange 库存 · 置换 / 禁用候选）由此掷定时点一致，既有的不对称消失；防重掷也更严——留到结算那一刻现掷，玩家退出重进即可刷一个更合意的置换对象。
- **`OutcomeSpec` 侧因此可写死 `Op == Grant`。** resolver 在结算时把玩家的选择翻译为 `Remove` + `Grant`（同 `PairKey`）或 `Disable` 三类 element，并入 `eventEnd` 那一次 `TryApply`；`ResolveOutcome` 不新增结构。
- **存档 schema 有一格增量（如实记）：** `EventOption` 新增 `AbilityChangeSlots` 一格 ⇒ 随同批 bump（当前无线上存档 = 空迁移）。`PastEventEntry` **不受影响**——本次掷定的结果已在 `AppliedChange` 里，候选本身按既有判据（重算不出来**且有消费方**）在事件收口后无消费方。

**模板侧的参数空间与加载期校验见 `systems/adventure-event/common-properties.md`；本服务只负责把它物化成上述定稿实例。**

**物化组装后的断言清单**（`PushError` + `EventId` + `InstanceId`）：

| # | 断言 |
|---|---|
| 1 | `OutcomeSpec != null`（既有，保留） |
| 2 | 两侧的 `Stats` · `StatusChanges` · `PlotElements` · `EventStateChanges` · `RngElements` · `TraceElements` · `SettingChanges` · `CodexElements` **逐列恒空**（穷举，不按数量核对） |
| 3 | 两侧 `Elements` 中不得出现 `PowerFragment*` 七 key 与 `BundleRedeemedOrdinal` |
| 4 | 两侧 `Elements` 中 `Key == LifeSpan` 时 `BaseValue >= 0`（成本侧那条的镜像） |
| 5 | 真身口径的 `eventType == Travel` 时两侧不得出现 `Key == LifeSpan`（既有结构性禁令的物化侧对偶） |
| 6 | 两侧 `Elements` 中 `Key == ManaLimit` 时 `\|BaseValue\| == 1` |
| 7 | 两侧 `AbilityElements` 每条：`Op == Grant` ∧ `Scope == Character` ∧ `Source == EventOutcome` |
| 8 | 每条 `ChangeElement.Op ∈ ResourceElements[Key].AllowedOps` |
| 9 | `AbilityChangeSlots` 每条：`Op ∈ { Remove, Disable }` ∧ `Scope == Character`；`Op == Remove` 时 `GainAbilityId` 非空 |
| 10 | Explore 壳：`OutcomeSpec` 由 `RevealedEventId` 指向的模板物化（见 `systems/adventure-event/explore/_index.md`） |
| 11 | 两侧 `Elements` 中 `Key ∈ { Faith, Bloodlust }` 时 `BaseValue != 0`（模板校验 8 的物化侧对偶；`Op == Add` 已由断言 8 覆盖） |
| 12 | 两侧 `Elements` 中 `Key ∈ { Faith, Bloodlust }` 各至多一条（模板校验 7 的物化侧对偶，与断言 4 / 5「成本侧那条的镜像」同款分工） |
| 13 | `EncounterSpec.Tier == Finale` ⇒ 五格遭遇参数全等于该档默认值（`Tighten` 整档豁免的物化侧对偶） |

**断言 5 是既有禁令的物化侧对偶，在「Explore 产出取真身」的处置下继续成立**——若产出取壳，一个遮罩着回寿 Travel 的秘境就能绕过该禁令。

**经验的失败折算在物化组装时完成，`FailureRatio` 不进定稿实例。**

```
物化时：
  base   = ExperienceGradeTable[chapter][ExperienceGrade]      // 平衡表映射，已含篇章放大
  OnResolved.Elements += ChangeElement(ExperiencePoint, +base, Add)
  fail   = max(1, floor(base × FailureRatio / 100))            // 百分比整数；向下取整、下限 1
  OnFailure.Elements  += ChangeElement(ExperiencePoint, +fail, Add)
```

- 它兑现三条既有纪律：**结算时只选一侧、不掷骰也不算数** · **element 只承载已定稿的量** · **`AppliedChange` 可直接重放**。
- **`ExperienceGrade == None` 时两侧都不产出该 element**（而不是产出一条 `+0`），与「无产出用空 spec 不用 `null`」同向：不产生无消费方的空条目。
**隐藏属性推拉的展开：符号由 `HiddenStatGrant.Direction` 在此产生。**

```
物化时（对 HiddenStatGrants 逐条）：
  v    = HiddenStatGradeTable[g.Grade]                        // 正量；见 systems/balance.md
  sign = g.Direction == Raise ? +1 : -1
  key  = g.Stat == Faith ? CostKey.Faith : CostKey.Bloodlust
  OnResolved.Elements += ChangeElement(key, sign * v, Add)
  OnFailure .Elements += ChangeElement(key, sign * v, Add)    // 胜负同施，不套 FailureRatio
```

- **取负只在此处发生一次**，与 `SelectCost` 的 `lifeSpanCost` 取负、`OutcomeRule.Direction` 取负同处；下游拿到的一律是带符号 spec，不做符号推断。三格的类型定义与方向位的落点论证见 `systems/architecture.md`「共享核心类型」，模板侧的加载期校验见 `systems/adventure-event/common-properties.md`。
- **本服务不新增任何钳制点。** `[0, 100]` 的截断发生在 `Evaluate(spec)` 施加到 Profile 字段那一刻（`Faith` / `Bloodlust` 两行的两个修正列恒 `null` ⇒ pipeline 不介入），spec 与快照记**未截断值**；截断不构成 `ApplyResult.Fail`。
- **`Grade == None` 的条目不在此产出一条 `+0`**——它已在模板加载期被拒绝，与 `ExperienceGrade == None`（字段默认值，缺省即不产出）不同构。
- **隐藏属性推拉在两侧各展开一份相同 element，不加顶层第三格 `Always`。** 两份由物化时的**同一段组装代码**从模板上**同一个** `HiddenStatGrants` 字段展开，不存在两处真值；加一格会把顶层从两侧变成三格、走向映射表要重写，且立刻要回答「`Aborted` 时 `Always` 施不施加」——那正是最不该新开的分叉。冗余的实际体积 = 每侧至多 2 条 element。方向位不改变这条。

**Explore 壳的 `OutcomeSpec` 由真身模板物化：「成本取壳、产出取真身」是一条有意的不对称（承重）。** 成本侧取壳的理由是：`selectCost` 恒精确展示，若壳按真身报价，成本数值就成了真身类型的指纹（Combat / Travel / Exchange 三行定价不同）——**故 Explore 在定价表上自成一行、壳恒按该行的唯一定值报价**；**产出在揭示前从不展示**（遮罩态卡面只取 Explore 模板自己的文案与图标），该理由整条不成立。而防重掷的理由在产出侧成立且已由 `Encounter` / `DestinationLocationId` 立过先例：抽取型产出若等到揭示后再掷，退出重进即可重刷。**不写明这条不对称，后来者读到两条相反的处置会去「统一」其中一条——统一到哪一侧都造成实际损坏**（统一取壳 ⇒ 真身条目的产出格在被遮罩时整条失效，同一份数据两种行为；统一取真身 ⇒ 成本数值成为指纹）。落地断言见 `systems/adventure-event/explore/_index.md`。

- **字段名取 `OutcomeSpec` 而非 `Outcome`**：`PastEventEntry.Outcome`（`EventOutcome` 枚举）与 `Source.EventOutcome`（授予来源枚举成员）都在同一条链路上被同时提及，三者同名不同物会让层间类型一致性无从机械核对。
- **结算走向 → 施加哪一侧的映射（明写，不留实现分歧）：**

  | 结算走向 | 施加 |
  |---|---|
  | `EventOutcome.Resolved`（非战斗类正常结算） | `OnResolved` |
  | `EventOutcome.CombatWon` | `OnResolved` |
  | `CombatOutcome.Draw`（`Standard` 档打满道念相等；另两档不可达） | `OnResolved` —— 与「平：只发 `baseReward`、不扣寿元」对齐 |
  | `EventOutcome.CombatLost` | `OnFailure` |
  | `EventOutcome.Aborted`（支付后短路，未进 resolver） | **两侧皆不施加** |

- **Combat 类的产出边界（承重）：`OutcomeSpec` 只承载隐藏属性推拉 + 经验档 + 事件级产出；战斗战利品恒不进 `OutcomeSpec`。** 战利品出自 `CombatResult.Spoils`（记 `Source.CombatReward`），其取值来自 `EncounterSpec.BaseReward` / `RewardPoolId`。故 Combat 事件的 `OutcomeSpec` **既不恒为空**（它还要装隐藏属性推拉与经验档），**也不装战利品**——两格的分工按「谁组装出这条 element」逐条落定。

**`Encounter`（类型 `EncounterSpec`，可空）= 战斗类事件的遭遇载体，`EnemyInstance` 嵌在其内。** 它与 `ResearchSlots` / `ExchangeStock` 同属「只对某一类型有意义的物化载荷」一族，差别只在那两个是列表、这个是单个可空引用——**本作不存在多敌人场景，承载字段一律单数、不留伸缩位**。

- **取一格嵌套而非平铺八格（承重）。** `EncounterSpec` 的七个物化产物（`Tier` / `Enemy` / `TurnLimit` / `VictoryRule` / `FirstSide` / `RewardPoolId` / `BaseReward`）无论如何都得落在定稿实例上——消费侧不得回查模板重算。嵌一个可空引用 = **加 1 格**；平铺 = **加 7 格**且其中六格对四类非战斗事件恒为默认值。
- **`RunCombatAsync(EncounterSpec, ct)` 的签名不动**：life-cycle-service 进入战斗时直接把 `option.Encounter` 递进去，**不组装、不派生、不重算** ⇒ 不产生第二个物化点。
- **物化后校验两条，按 `EventType` 的真身判，不按 `EventType` 字段判**（`PushError` + `InstanceId` + 抛）：真身 ∈ `{ Practice, Combat, Finale }` 且 `Encounter == null`；真身 ∉ 三档且 `Encounter != null`。**按真身判是「resolver 按真身的 `eventType` 选取」同一条纪律的又一处应用。**
- **真身为战斗类的 Explore 壳，其 `Encounter` 在物化时即填好**——与 `DestinationLocationId` 对 Travel 真身的处置完全同构，依据同为防重掷：敌人若等到揭示那一刻才掷，玩家退出重进即可刷一个更弱的对手。
- **结算期间读到的敌人实例来自 `activeEvent.Option.Encounter.Enemy`**（读取权威见 `systems/adventure-event/common-properties.md`）；当前批里的那一份不因结算而改变。

**为何 `EventOption` 是 `sealed record`（引用类型）而非 `readonly record struct`：** 字段多、要落存档、一批只有个位数个、不在每帧热路径——按值拷贝的代价高于一次分配。`record` 的 `with` 表达式同时给出「定稿后若确需派生（如 Explore 揭示）就产生一个新实例而非改旧的」这一惯用法。

三点推演：

- **`ComputeEventOptions` 的语义就是「物化」：** 取 `AllEnabled()` 候选 → location 框定 → PlotManager 调制 → map 子流抽取 → 组装定稿实例（**成本量值在此取负**）。**物化完成后本服务不改这批实例**；一批的更新只有一种形态——`RefreshAfterEvent` 产出**一批全新的实例**。
- **未选项摘要从「被替换的那一批」取，取用方是 life-cycle-service。** `RefreshAfterEvent` 会把当前批整批换掉；被换掉的那一批里除 `resolvedInstanceId` 之外的选项，正是要写进 `PastEventEntry.Unchosen` 的轻摘要来源。**本服务不因此新增方法、也不负责写档**——`Current` 在重算之前仍指向旧批，life-cycle-service 在组装 `PastEventEntry` 时读它即可，写入照常经 `profile-service.ProfileManager`。字段形态见 `systems/adventure-event/common-properties.md`。
- **`EffectivePriority` 由本服务算好放进 batch**，而不是让 UI 自己去 `Max(o.Priority)`。呈现层只做呈现，「哪些可选」是产出侧的语义。
- **PlotManager 的四个方法不出现在服务门面上**（manager 不被跨服务调用）：`TryResolvePlot` / `ModulateEventOptions` / `OnHiddenStatThreshold` 是 `ComputeEventOptions` 物化链条内部的一环；只有 `ChooseBranch` 需要玩家输入，故投影为服务门面上的同名方法。

**事件面：**

| 事件 | 负载 |
|------|------|
| `EventOptionsChanged` | `(string BatchId, int Revision)` |
| `PlotThresholdReached` | `(string CharacterId, HiddenStat Stat, int Threshold)`（本服务代 PlotManager 广播） |

**协作面：** 物化出的 eventOptions 交由 **game-progression（编排顶点）** 以**月圆之夜式菜单 / 横向滑动选择区**呈现；随机性从 `life-cycle-service.Stream(RngStream.Map)` 取得；模板按 `Id` 经 `content-service.ContentRegistry` 解析。

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **五类之间的配比未定（`BaseTypeWeights` 的取值）。** 它以**乘性**方式参与类型分布、归一化在类型分布层发生**已定**（见「意图」的十步管线）；仍待定的是表里每格填多少，以及 Combat 内 `combatTier` 三档的配比。→ `systems/balance.md`、`systems/adventure-event/common-properties.md`。

Source: `handoffs/2026-08-25-currency-split-spirit-stone-and-immortal-jade.md` · `handoffs/2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md` · `handoffs/2026-07-27b-service-api-contracts.md` · `handoffs/2026-08-05b-location-fields-event-count-limit-and-skip-refill-closure.md` · `handoffs/2026-08-06c-skip-channel-removal-priority-two-tier-and-location-codex-edges.md` · `handoffs/2026-08-09c-past-event-trace-schema.md`

## 对应
提炼至：`.claude/knowledge/systems/future-event-service.md`（引用层，待建）。
