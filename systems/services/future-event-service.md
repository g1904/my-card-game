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
  - **敌人取池的地域维度由敌人条目自己的 `PoolScope` 给出**（location 条目不持敌人清单）⇒ **敌人物化的两条轴仍然正交**：**当前 location 影响「派谁来」**（通用条目恒进池，该地域的专属条目在其上叠加），**相对角色等级的赋级带决定「有多强」**（三章统一 `±2`，见下）。带内各档的分布权重与卡组改写规则见下。
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
  - **`locationMap` 在轮回内对玩家不可见**；玩家可见的那一面是账号级的 `LocationCodex`（图鉴族第六本，「去过即记」**且记连边**，故整张图可在多次轮回中被重建——这是设计目标，见 `systems/player-profile/codex/_index.md`）。**推论：图的稳定性是对玩家的隐性承诺**——改连边等于清空一份账号级资产。

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
  - **物化后断言两条**（`PushError` + `EventId`）：`Priority ∈ { 0, 1 }`；`OutcomeSpec != null`——**无产出的事件用空 spec 表达，不用 `null`**，避免下游到处判空。`Priority` 不设加载期检查：它从不是 `AdventureEventData` 上的字段，一个不存在的 `[Export]` 面没有「检出它出现了」的机制，纪律靠文字与置位方唯一保证。
  - **物化日志：** `[FutureEvent-Materialize] instance=<InstanceId> event=<EventId> type=<EventType> prio=<n> cost=<lifeSpan> outcomeRolls=<n>`。
- **选择约束只有一条轴，且由本服务独占置位。** `eventPriority` 是**唯一**约束玩家选择权的字段——**不设第二个约束字段**；它是上述物化模型的一个特例——**不由内容作者在 `.tres` 写死**，而由本服务在物化这一批时**动态置位**：
  - **取值域两档：`0`**（常态，玩家可从本批任选）与 **`1`**（本批一旦出现，有效可选集收窄为该档）。语义详见 `systems/adventure-event/common-properties.md`。
  - **置位方唯一 = 本服务；PlotManager 不得改变它。** **推论（边界澄清 · 承重）：PlotManager 只调内容不调约束**——它影响哪些事件进池、以什么权重出现，但**不能通过抬优先级强制玩家做某件事**；剧本的强制性只能靠**把候选池收窄**表达。
- **批次规模 = 常态 3、区间 1–5。** 本服务每次产出的 `EventOptionBatch` **通常含 3 项**，允许 1 到 5。**批次不是固定宽度**——产出侧要按批给出数量，不能套一个常数；**1 项的批次合法**（与 `Priority = 1` 收窄到单项、Travel 20% 随机档同形，不需要额外规则允许它）。区间两端由什么驱动未定，见待决问题。
- **重算依据 = 角色的整体历程，不是上一批（承重）。** 新一批**不在上一批基础上增删**，而是依角色的整体状态与历程重新产出——**`pastEvent` 是本服务的一等输入**（与 location 框定、PlotManager 调制、map 子流并列）。**「更新后」这三个字是硬要求**：收口那一次事务里本次事件的账与新 `pastEvent` 条目必须已经算进去，故 life-cycle-service 先取一份**只读投影**（`profile-service.Project(spec)`）再调本方法，把新一批放回同一次提交——**收口仍是一次事务、一个存档点**。**推论：本服务不持有跨批次的状态**；批与批之间唯一的信息通道是 CharacterProfile 本身，这与「模板不可写回」「产出即定稿」共同保证了本服务是无记忆的纯产出侧。
- **批次刷新只有一种形态：整批重算（承重）。** 玩家面对一批 eventOptions 唯一能做的是**择一进入**；**每完成一次选择，本服务整批重算**——**选中一个即等价于跳过了其余全部**，故**不设跳过通道**。
  - **不设单项补位。** 本服务的 API 面是**四个**方法，没有 `TryRefill` 一类的单项补位方法——一旦有它，就要跟着回答「补位落空怎么办」「不生成付不起的事件」「不生成整批不可选的批次」一整串问题，而整批重算让这些问题不存在。
  - **`EventOptionBatch` 不设「至少一个必做项」的不变式**：**本批的每一项都是必做项**，不需要字段去保证它。
  - **「打不过也得打」这条设计意图升级为结构性事实。** 仍**不需要**产出侧的「至少一个可负担 / 可战胜选项」保证：**必须面对的遭遇打不过 → 输掉这一局，是正常且合意的结果**。这与失败侧的既有建制自洽（EnemyCodex 遭遇即记、失败也可能给经验，加上篇章重试模型；**道统残卷的累积已收窄为 Finale 失败专属**，不参与常规遭遇的论证）——**「输」是这个游戏的一个正常出口**；同时它**约束产出侧不要过度保护**，难度的界由赋级带给出已经足够。
  - **`selectCost` 侧同样不欠可负担性保证。** 支付 `selectCost` 是**无条件的可推进行为**，付不起也照付、支付后判定状态、判负进失败流程（见 `systems/adventure-event/common-properties.md`）。**推论：「付不起唯一可选项 ⇒ 无法推进」这条死锁在规则层不成立**，本服务不需要为此做任何产出侧兜底。
- **敌人物化 = 一条五旋钮管线，输入固定、顺序固定、产物落存档。**

  ```
  输入：EnemyData（经 ContentRegistry.AllEnabled() 取池，按 PoolScope / location / 全部 Active arc / 篇章 / eventType 框定）
      + CharacterProfile（全局等级、所在篇章、隐藏属性）
      + location 框定
      + PlotManager 框定（框定敌人池 + 赋级权重偏移，不触及模板字段）
      + SeedManager 的 map 子流

  ① 框定 + 选模板  ← PoolScope（通用条目恒进池，地点 / arc 专属条目叠加）+ location + 篇章 + eventType 框定 → 加权抽取
  ② 赋级          ← 角色全局等级 ±2 带 + 权重表
  ③ 卡组结构对齐   ← 以 ② 的等级为输入（仅费用曲线对齐与风味替换，不加第二条强度曲线）
  ④ item / power 持有列表  ← 直接取自模板（不由剧本调制改写）
  ⑤ 遭遇参数      ← eventType（Combat 10 回合 / WinMargin 1；Practice 8 / 0；Finale 12 / N）

  产出：EnemyInstance（定稿 · immutable · 随 EncounterSpec 嵌在 EventOption.Encounter 上落存档，
        不在战斗开始时二次展开）
  ```

  - **关键规则：等级先定，其余四项以等级为输入，且不叠加第二条强度曲线。** 敌人的战斗强度以 `baseMomentum` 为主刻度——若卡组也随等级放大（更强的牌 + 更高的起始道念），强度就被**平方**，`±2` 带的数值安全性推导立刻失效。**卡组承担风味，等级承担强度。**

    | 旋钮 | 允许做的 | 不允许做的 |
    |------|---------|-----------|
    | **卡组改写** | 结构对齐（费用曲线与该等级的 `manaLimit` 相称）、风味替换（同族异名）、埋伏张数增减 | 用「等级越高牌越强」再加一条强度曲线；**由剧情线临场改写** |
    | **item / power 列表** | **直接取自模板**（boss 与天劫的「不可被移除的场上特性」写在其专属条目上） | **由剧本调制增删**；突破 `IgnoresProtection` 的配额 |
    | **遭遇参数** | 按 eventType 改写 `TurnLimit` 与 `VictoryRule` | 用它抵消等级带的约束 |

  - **卡组改写的表达形式**：常规敌人走**算子式**，boss / 天劫走**多套预制**（含天劫的定制卡组），二者并存。
  - **一条可在物化时机械检查的改写上界：必须保留模板标注的 `KeyCardIds`。** 否则图鉴会与玩家实际遭遇的敌人对不上——而图鉴是事前知识的主通道。违反 → `PushWarning` + **该次改写回退**；**`OverridesDeck == true` 的定制卡组条目显式豁免**（图鉴条目自带说明）。
  - **确定性与存档**：全部改写走 map 子流；产物 `EnemyInstance` **随 `EventOption` 落存档、不重算**（overlay 热更 + seeded RNG 使重算不保证同结果）。
  - **⚠ 前置依赖（诚实标注）**：「结构对齐」与「风味替换」目前**没有量纲**（费用曲线、道念产出量纲未定），故旋钮 ③ 在 ch1 数值标杆专场之前**只是一个框架，不能落地为具体改写算子**。
- **剧情线不可调制敌人模板；剧情线与地点各自可拥有专属敌人模板池（承重）。** 差异化的表达位从「改写模板内容」整体移到「**换一个池子抽**」：
  - 每个 `EnemyData` 带 **`PoolScope`**（通用池 / 某地点专属 / 某 arc 专属）；抽取时按 `EncounterScopes`（事件类型作用域）+ `PoolScope`（地点 / arc，逐维度与门、空维度恒真，arc 一侧传**全部 `Active` arc 的集合**）+ 篇章框定叠加，全部在 `AllEnabled()` 之后。**通用条目恒进池，专属条目是叠加而非替代**——池归属的唯一权威在敌人条目一侧，location 条目不持敌人清单（见 `systems/enemies/_index.md`）。
  - 「大限将至」线上的绝境敌人 = **该线专属池里的一条完整 `EnemyData`**（自带更凶的样本卡组与 power），**不是**把通用条目临场改凶。
  - **PlotManager 的权力因此收敛为三项：框定用哪个池 · 偏移带内赋级权重 · 拧紧遭遇参数。它碰不到模板的任何字段。**
    这份权力面在内容侧有一个**逐条投影的承载类型 `PlotModulation`**（六个 `[Export]` 字段，一一对应上述三项加事件层的两项权重）：越权的写法在内容层**根本没有字段可填**——`eventPriority`、模板字段、敌人卡组、item / power 列表都不在其中。类型定义见 `plot-manager.md`。
  - **好处**：改写幅度天然有界 · 图鉴词条与玩家实际遭遇恒对得上（专属条目有自己的词条）· 可确定性复算。**代价**：内容量上升（每条专属敌人都是一个完整条目，含图鉴五项词条），归内容排期。
  - **两个字段的缺失语义不同**：`EncounterScopes` 空数组 → 加载期 `PushError`（漏填会静默缩小抽取池）；`PoolScope` **允许为空**（= 通用池），不报错。
  条目定义见 `systems/enemies/`。
- **遭遇参数由本服务在物化时从 `AdventureEventData` 代入 `EncounterSpec`。** `TurnLimit` / `VictoryRule` / `RewardPoolId` / `BaseReward` 全部在物化时定稿，**`EnemyData` 完全不携带**——否则同一个敌人条目无法同时用于 Practice 与 Combat。**依据 = 唯一物化点 + 产出即定稿**：消费侧不得回查模板重算，故 `EncounterSpec` 必须自带取值，不能只带一个 `EncounterId` 让 combat-service 回查。**物化时代入也是剧本调制的天然挂点**（PlotManager 可拧紧遭遇参数）。类型形态见 `systems/services/combat-service.md`。
- **成本量值取负发生在本服务的物化组装阶段。** 内容作者在 `AdventureEventData` 上以**正数量值**标注 `lifeSpanCost` 等成本（「耗 3 点寿元」写 `3`）；**本服务在组装 `SelectCost` 时取负**填入 `ChangeElement.BaseValue`，从而满足既定的带符号约定（负 = 消耗，正 = 产出）。这条转换**只在此处发生一次**——下游（life-cycle-service / ProfileManager）拿到的一律是带符号 spec，不做任何符号推断。
- **战斗类事件在物化时精确标注敌人等级。** `combatTier` 三档的 `EventOption` 需向玩家**精确展示敌人的等级**（否决模糊的危险度档位）——玩家据此与自身等级比对，理解意图为何被遮蔽，并把「越级挑战」当作可主动选择的风险 / 回报。
- **敌人也由本服务物化：`EnemyData` → 充实 / 改写 → 指派给事件。** 敌人的**静态数据**集中在 **`EnemyData`** 集合（稳定 `Id` + 图鉴文案 + 基准数值 + **样本卡组**；玩家侧的那一面即 EnemyCodex）。本服务在物化一个战斗类事件时：**取出一份模板 → 依情境充实 / 改写（enrich / modify）→ 把结果指派给该事件**。**`EnemyData` 另需两个持有列表字段：item 持有列表与 power 持有列表**——**敌人没有储物袋**（那是角色的道具容器），道具与 `Power` 直接挂在模板上；战斗组装时 item 列表成为敌人侧的「本场可用道具」，power 列表按 `UsableScene` 过滤后入场为受保护永久物。**这给「物化时充实 / 改写」多了两个可调旋钮**（除等级与样本卡组外，还可调这一场敌人带哪些道具 / 特性）。

  - **敌人等级由此答定：它不是模板上的死值，而是物化产物。** 同一个敌人模板可在不同篇章、不同情境下以不同等级出场——这正是「多数属性由物化决定」在敌人上的应用。
  - **连带答定「等级标注的承载字段」的一半：** 既然等级在物化时确定，它就**随物化产物一同定稿并落存档**，而不是由 ViewModel 现查模板算出来。
  - **它是「模板 ↔ 实例」通则的第三个实例**（前两个是 `AdventureEventData ↔ EventOption`、`CardData ↔ CardInstance`，见 `systems/architecture.md` 总则 6）：模板是 ContentRegistry 里的共享只读单例，**本服务不得写回它**；改写只发生在物化产出上。
  - **样本卡组同理**：模板给基线卡组，物化时可改写（Finale 的天劫即极端情形——定制卡组的 Enemy）。

- **赋级的合法区间 = 角色当前等级 `±2` 的对称带（三章统一 · 承重）。** 物化赋级落在 `[角色等级 − 2, 角色等级 + 2]` 内，在全局序 **1–22** 上截断。
  - **它是一条相对 `diff` 的带，不是按境界给的绝对天花板**，且**同时给出上界与下界**（此前只有上界）。
  - **三章的带边界全部是内容侧可调数值。** **本服务只读「当前篇章的带」这一个概念，不为分章写分支**；落点与加载时校验见 `systems/balance.md` 的待决问题。
  - **赋级规则挂在 Enemy 上，不挂在事件类型上** ⇒ **`combatTier` 三档一视同仁**。天劫只是 Enemy 的一种，不享有等级规则上的例外（见 `systems/adventure-event/combat/`）；Practice 的「低风险」由回合数与胜负门槛承担，**不由「派个更弱的对手」承担**。
  - **推论 ①（承重 · 三章全部成立）：「一次惨败打穿耐久」由规则层封住。** 上界统一为 `+2`，最坏落差为 9（炼气十三层 `baseMomentum` 15 遇筑基中期 24），在 `lifeTotal` 10/10 之内。
  - **推论 ②：越阶遭遇只出现在每个境界的末两级**——12 · 13 → 筑基；16 · 17 → 金丹；20 · 21 → 元婴。**三章统一**，越阶压迫感自动向篇章尾部集中，与 Finale 落在篇章边界同向。
  - **推论 ③：`±2` 是无例外的硬规则。** 任何调制源（PlotManager、location 框定、事件模板、Finale）都不得产出带外 `diff`；**赋级函数不接受任何区间覆盖参数**——不给这个口子，就不存在「谁有权用它」的问题。调制源只能改**带内权重**。
  - **推论 ④：上界档不必然越阶。** `diff = +2` 只在境界末两级才是越阶；境界中段的 `+2` 是同阶，照常按 `diff` 门槛给信息。
  - **推论 ⑤：本服务不需要境界表。** 赋级 = 全局序上一次加减 + 截断；境界边界的特殊性由 `baseMomentum` 的跨度放大自然承载。
  - **推论 ⑦：带内分布权重表**（三段权重 × 调制修正 × 截断重分配 × 批内去重），见 `systems/balance.md`。**截断重分配必须显式实现**：全局序 1–22 截断后落空的档位权重按比例并入带内剩余档，否则 L1 · L2 的抽取会出现权重和不为 1 的实现分歧。
  - **推论 ⑥：元婴（全局 22）**——角色 21 时带为 `[19, 22]`；抵达 22 即轮回终点，实际不产生遭遇。
  - **推论 ⑦：带只约束「能出到几级」，不约束分布。** 带内各档（ch1 七格 / ch2 · ch3 五格）以什么权重出现，仍归本服务的加权规则（待定）。
- **Research 的构筑面板候选在物化阶段掷定，随 `EventOption` 落存档。** 模板上的 `ResearchSlotSpec[]` 在本服务物化时展开为 `ResearchSlot[]`：逐槽按 `AllowedOperations` 取候选池、抽 `CandidateCount` 条、并为每条掷定它附带的 `ManaDelta`（风险档为 `±1`，其余为 `0`）。
  - **随机源 = `RngStream.Reward` 子流，不新开子流**：`Reward` 已承载完全同构的用途（候选预先掷定 + 落存档 + 绝不重抽），而奖励候选与构筑候选从不并发。
  - **两条取池链均为复用，本服务不新增抽取代码**：法宝候选直接调 `profile-service` 的 `TryPickGrantableMany(Item, Character, rng, 3)`；功法候选走 `CultivationTechniqueData` 仓储的 `AllEnabled()` / `DrawPool<T>` 加权无放回抽取，**它是 `DrawPool<T>` 的第五个调用方**。
  - **候选必须在此刻算定，不能等到面板打开。** 依据是既有的防重掷纪律——候选若在结算那一刻才掷，玩家退出重进即可重掷；`ManaDelta` 同理，**风险档正是靠「结果已定、只是尚未展示」才能成立**。槽与候选的字段面见 `systems/adventure-event/research/common-properties.md`。
- **Exchange 的库存在物化阶段掷定，随 `EventOption` 落存档。** 模板上的 `ExchangeSpec.StockRules` 在本服务物化时展开为 `ExchangeOffer[]`：逐条规则按 `Kind` 映射到对应仓储取池、按 `RarityFilter` 过滤、按 `RarityTier` 权重无放回抽 `SlotCount` 条，再逐条算出 `BasePrice` 与 `ListPrice`。
  - **随机源 = `RngStream.Shop` 子流**，它已在子流清单里，不新开。
  - **取池链沿用授予池那一条，不另写一段**：`AllEnabled()` → 按 `Kind` 映射仓储 → 排除 `ExclusiveSource != null` → 排除已持有（能力族）→ `RarityFilter` → 加权 `PickMany`（无放回 ⇒ 同批不出现重复商品，免费成立）。**不新建任何抽取池**——五个商品族一一映射到既有仓储。
    - **能力族商品经第二级 `TryPickGrantableMany` 取池，其余三族直用第一级 `DrawPool<T>`**（`[采纳推荐 — 待复核]`）。理由：「排除已持有」是需要读 `Profile` 的那道过滤，它必须只写在一个地方；走既有门面方法即可，**不给 `GrantPoolPicker` 新开入口**——它已是全库唯一的能力抽取处，入口越多越容易漏用。代价：本条取池链因此分裂为两种写法。
  - **`ListPrice` 在此定稿，`ModifierKey.ShopPrice` 也在此施加。** 依据是「一个 `ModifierKey` 只能有一个施加点」：商店价格必须先算才能标价 ⇒ 施加点在物化 / 展示侧，`Jade` 那一行的两个修正列因此恒为 `null`（见 `systems/services/profile-service.md`）。**代价明写：** 轮回中途新获得的降价修正不影响已定稿的库存，下一个 Exchange 事件才生效。
  - **`RerolledCount` 初值为 0。** 刷新是结算侧的动作（花 jade 重掷整批库存，走同一条取池链与同一个 `Shop` 子流），本服务只负责给出初始库存。规则见 `systems/adventure-event/exchange/_index.md`，字段面与校验见其 `common-properties.md`。
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

Source: `handoffs/2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md` · `handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md` · `handoffs/2026-07-26-event-priority-skip-semantics-and-hotfix-scope.md` · `handoffs/2026-07-27b-service-api-contracts.md` · `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md` · `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md` · `handoffs/2026-08-04b-mtg-loanwords-card-types-and-intent-snapshot.md` · `handoffs/2026-08-05-level-band-stack-save-and-token-free-deck.md` · `handoffs/2026-08-05b-location-fields-event-count-limit-and-skip-refill-closure.md` · `handoffs/2026-08-06b-asymmetric-ch1-band-consented-power-loss-and-chapter-retry-shape.md` · `handoffs/2026-08-06c-skip-channel-removal-priority-two-tier-and-location-codex-edges.md` · `handoffs/2026-08-06d-combat-open-questions-mass-closure.md` · `handoffs/2026-08-09c-past-event-trace-schema.md` · `handoffs/2026-08-11-plot-content-localization.md` · `handoffs/2026-08-15c-event-type-collapse-and-batch-shape.md` · `handoffs/2026-08-16g-travel-mechanics-and-location-carrier.md` · `handoffs/2026-08-16h-grant-source-assembler-criterion.md` · `handoffs/2026-08-16i-plot-data-encoding.md` · `handoffs/2026-08-17-travel-destination-and-status-change-elements.md` · `handoffs/2026-08-17b-research-build-panel-and-deck-elements.md` · `handoffs/2026-08-17c-explore-reveal-mechanics.md` · `handoffs/2026-08-17d-exchange-mechanics-and-transaction-discipline.md` · `handoffs/2026-08-17j-event-option-derived-persistence.md` · `handoffs/2026-08-19-pickmany-shortfall-handling.md`

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
    int                RerolledCount,             // Exchange 已刷新次数；供刷新价递增与存档恢复
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

**`OutcomeSpec`（类型 `EventOutcomeSpec`）= 产出侧的定稿载体，顶层按结算走向分侧。** 它顶层分 `OnResolved` / `OnFailure` 两侧，**不按事件类型分侧**——与「授予来源的分野判据 = 谁组装出这条 element」同一条判据。**内部分解 ⟨待定：归「效果关键字体系与目标规则」那次专门 handoff⟩**：产出的效果原语表达、两侧各自的列、经验失败折算的数据形态都在那次落定，本处只定「载体存在于 `EventOption` 上」「固化时点如上」「顶层按结算走向分侧」三件事。

- **字段名取 `OutcomeSpec` 而非 `Outcome`**：`PastEventEntry.Outcome`（`EventOutcome` 枚举）与 `Source.EventOutcome`（授予来源枚举成员）都在同一条链路上被同时提及，三者同名不同物会让层间类型一致性无从机械核对。
- **结算走向 → 施加哪一侧的映射（明写，不留实现分歧）：**

  | 结算走向 | 施加 |
  |---|---|
  | `EventOutcome.Resolved`（非战斗类正常结算） | `OnResolved` |
  | `EventOutcome.CombatWon` | `OnResolved` |
  | `CombatOutcome.Draw`（打满道念相等） | `OnResolved` —— 与「平：只发 `baseReward`、不扣 `lifeTotal`」对齐 |
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

- **生成 / 加权规则未定。** **location 层的形态**（事件类型概率修正 + `eventCountLimit`）、**每批数量**（常态 3、区间 1–5）、**重算依据**（角色整体历程，重度依赖 `pastEvent`，不承接上一批）、**Travel 段的物化伪码**均已给出；仍待定：类型修正的**运算形态**（乘性 / 加性 / 白名单 + 权重，其余四类能否修正到 0）、月圆之夜式策划与随机权重的配比、location 框定 / PlotManager 调制 / seeded RNG 的**叠加顺序**、以及**批次规模区间两端由什么驱动**（它同时决定常规批里 Travel 的槽位数 `k` 从何而来）。→ `systems/game-progression.md`、`systems/adventure-event/common-properties.md`。
- **`EventOutcomeSpec` 的内部字段面未定。** 顶层载体、固化时点与「按结算走向分侧」已定（见「意图」）；**内部分解**——产出效果原语的表达、`OnResolved` / `OnFailure` 两侧各自的列、经验失败折算的数据形态——此前登记为「阻于效果关键字体系与目标规则」，**该前置已于 08-16c 收口**（`KeywordData` 内容层条目 + target / scope 分开建模并共用 `EntryFilter`，见 `systems/character-profile/deck/common-properties.md`）。**故本条的阻塞来源需重新确认**：若确已解除，它就只欠自身落笔，可单独排一次专场。→ `systems/character-profile/deck/common-properties.md`。
- **框定叠加顺序。** location 框定、PlotManager 调制、seeded RNG 三者的叠加顺序与优先级未定。**问题形状已收窄为「多个 `PlotModulation` 与 location 修正如何合并」**（白名单取交还是取并、权重相乘还是相加）——「剧本用什么调制」已有答案，调制的承载类型与字段面见 `plot-manager.md`，本条只欠合并算法。→ `systems/game-progression.md`、`systems/services/plot-manager.md`。
- **`Priority = 1` 依什么条件抬升。** **取值域（两档）与置位方（本服务独占，PlotManager 不得改）**；**两个确定的抬升条件已知**——配额用尽后的 Travel 闸门，以及起始批次里的开局构筑事件（Research）。仍待定：本服务还依什么条件把某个选项抬到 `1`（剧情线关键节点？），以及**同批出现多个 `1` 档时是否需要额外收窄规则**（当前语义：同档内自由择一）。→ `systems/adventure-event/common-properties.md`。

Source: `handoffs/2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md` · `handoffs/2026-07-27b-service-api-contracts.md` · `handoffs/2026-08-05b-location-fields-event-count-limit-and-skip-refill-closure.md` · `handoffs/2026-08-06c-skip-channel-removal-priority-two-tier-and-location-codex-edges.md` · `handoffs/2026-08-09c-past-event-trace-schema.md`

## 对应
提炼至：`.claude/knowledge/systems/future-event-service.md`（引用层，待建）。
