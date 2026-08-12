# future-event-service（服务）

> 依据当前 CharacterProfile **产出 eventOptions**（一组可选的 AdventureEvent）的服务层。玩家从 eventOptions 中择一以推进游戏；每完成一个事件后重算下一批。**对 `character-profile` / `game-progression` 提供「下一批可选事件」API。**

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **future-event-service = eventOptions 生成服务。** 依据**当前 characterProfile** 产出一批 **`List<EventOption> eventOptions`** —— 即当前可用、玩家可从中择一以推进轮回的选项集合。每个 `EventOption` 是一份**由 `AdventureEventData` 模板物化而来的定稿实例**（按 `EventId` 溯源到模板，按 `InstanceId` 被引用），携带物化时置位的全部属性（含 `eventPriority`，见下）。Source: `handoffs/2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md`。
- **「下一步能去哪」是运行时算出来的，不是内容里连好的。** 事件之间**不存在预先编好的前后连边**，AdventureEvent 只是自足的内容条目（见 `systems/adventure-event/common-properties.md`）。走向完全由本服务的产出面决定——这使内容可加性成立（新增一个事件 = 新增一个 `.tres`，无需改任何既有事件的出边），也使 PlotManager 得以在运行时调制走向。
- **eventOptions 循环。** 玩家从 eventOptions 中选择一个 AdventureEvent → life-cycle-service 结算该事件、更新 characterProfile → **future-event-service 依更新后的 characterProfile 重算一批新的 eventOptions** 供玩家再次选择。这是一个 chapter 内驱动进程的核心循环（见 `systems/game-progression.md`）。Source: `handoffs/2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md`。
- **多层框定。** eventOptions 的生成受多层框定叠加：**location（地域）** 框定本地域的产出面（见下条与 `systems/game-progression.md`），**PlotManager** 依隐藏属性 / 剧本进度**调制** eventOptions（见 `plot-manager.md`）。future-event-service 是这些框定汇聚、产出最终 eventOptions 的服务。
- **location 的框定面 = 三组字段（已定案 · 08-05b · 承重）。** 一个 location 携带 **① 事件类型出现概率修正**（软框定：改类型权重，不改可及性）、**② 一组特定的 `EnemyData`**（硬框定：限定战斗类事件的取池）、**③ `eventCountLimit`**（该地域的事件容量上限）。字段语义与推论归 `systems/game-progression.md`；对本服务的三条直接影响：
  - **物化的类型配比有了第一层确定的输入**：候选池按 location 的类型修正加权，而**不是**按地点切换到另一个封闭的事件池。
  - **敌人取池由 location 给出** ⇒ **敌人物化的两条轴至此正交**：**location 决定「派谁来」**，**相对角色等级的赋级带决定「有多强」**（三章统一 `±2`，见下）。这答结了「物化时充实 / 改写规则」中**取池**的那一半；带内各档的分布权重与卡组改写规则**亦已定案**，见下。
  - **`eventCountLimit` 是本服务的产出闸门**：配额用尽即改产 Travel（见下）。判定在**每一次整批重算**时做出（08-06c：补位机制已删除，故不再有第二个判定时点）。
  Source: `handoffs/2026-08-05b-location-fields-event-count-limit-and-skip-refill-closure.md`。
- **配额用尽 → 本批收窄为仅剩 Travel（已定案 · 08-05b）。** 玩家在当前 location 达到 `eventCountLimit` 后，本服务产出的**只剩「前往另一个 location」**。**承载机制无需新增，且 08-06c 后只需一个字段**——Travel 选项以**最高 `Priority`（= 1）**出场即可（`EffectivePriority` 随之抬到该档，封锁同批其余选项）。由此 Travel 从可选路由升格为**结构性闸门**：篇章 = 若干 location 的串联，location 之间由 Travel 缝合。
  - **闸门给多个目的地：** 收窄后是**若干个并列的 Travel 选项**，各指向 `locationMap` 上当前 location 的一个邻接地域——「去哪」是一次真实的玩家决策。**候选数量与抽取规则（全部邻接 vs seeded 抽取）未定。**
  - **计数口径：** `eventCountLimit` 只计**选择进入并结算**的事件；**Travel 不计入**。08-06c 后「一批 = 一次操作 = 一次配额消耗」，地域节奏是一条干净的计数。
  Source: 同上。
- **`locationMap` = 本服务高频读取的只读静态数据（已定案 · 08-05b）。** 地域之间的连边由一份独立的 **`locationMap`** 承载（不挂在 Travel 内容条目上、不在运行时算）；Travel 的目的地取自当前 location 的**邻接集合**。它是**一份不变的数据、三个篇章共用同一张图**，本服务**经常调用**它。
  - **工程形态由此定：** 进 `ContentRegistry`、**启动加载一次并常驻内存**、本服务**只读不写**（与「模板是共享只读单例、服务不得写回」同一条纪律）；**存档不存图，只存当前所在 location 的 `Id`**。受 overlay 热更管辖，但**一次轮回内视为不变**。
  - **推论：location 不随篇章 / 境界变化。** 篇章间的难度差异由**敌人赋级带**（相对角色当前等级）承载，不由换图承载——同一张图在三个篇章重走，敌人强度自动跟着角色走。
  - **`locationMap` 在轮回内对玩家不可见**；玩家可见的那一面是账号级的 `LocationCodex`（图鉴族第六本，「去过即记」**且记连边**，故整张图可在多次轮回中被重建——这是设计目标，见 `systems/player-profile/codex/_index.md`）。**推论：图的稳定性是对玩家的隐性承诺**——改连边等于清空一份账号级资产。
  Source: 同上。
- **PlotManager 是本服务内部的管理器（已定案）。** 隐藏剧本层**不是与本服务并列的服务**，而是生活在本服务内部的 manager，共享其事务边界与生命周期。它**不直接写 eventOptions**，也不直接对 game-progression / UI 暴露 eventOptions——它是一个**被调用的调制源**；对外呈现 eventOptions 的**唯一出口是 future-event-service**。Source: `handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md`。

  ```
  future-event-service.ComputeEventOptions(characterProfile)
        ├─▶ PlotManager        (隐藏属性阈值 / key points → 调制；本地剧本节点解析)
        ├─▶ location 框定       (由 Travel 事件刷新)
        └─▶ SeedManager 的 map 子流
        ──▶ eventOptions ──▶ characterProfile（经 profile-service.ProfileManager 写入）
  ```

- **本服务是 AdventureEvent 的唯一物化点，产出即定稿（已定案 · 影响面最大的一条）。** `AdventureEventData : Resource` 是**模板 / 素材，不是成品**：它承载稳定 `Id`、`eventType`、静态展示文案、基准数值与**可变体的参数空间**、数据驱动的 outcome / effect 定义。**多数**具体属性由本服务依情境**物化（materialize）**得出——目的正是「按不同情境制造更多变化与风味」。Source: `handoffs/2026-07-27b-service-api-contracts.md`。

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
  - **文本类字段一律不物化（已定案 · 08-09c）。** 显示名 / 描述 / 图标之外，**风味文案同样跟随模板数据**——它不进定稿实例、不进快照、不落存档，由 UI 层按 `EventId` 现场取模板组装。**收益：文案改版永不触发存档迁移**，且使「重算不出来的存」这条快照判据两侧再无灰色地带（见 `systems/adventure-event/common-properties.md` 的「`pastEvent` 的痕迹 schema」）。**推论：「完整物化字段清单」的剩余分叉只在数值与结构字段上。** Source: `handoffs/2026-08-09c-past-event-trace-schema.md`。
  - **快照存哪些字段由一条判据给出，不逐字段拍板：** 「重算不出来的存，重算得出来的不存」。字段表与 `PastEventEntry` 的完整形态归 `systems/adventure-event/common-properties.md`；本服务侧的承重点是**物化产出的数值必进快照**（`SelectCost` / `Priority` / Mystery 真身 / 敌人赋级）。Source: 同上。
- **选择约束只剩一条轴，且由本服务独占置位（已定案 · 08-06c）。** `eventPriority` 是**唯一**约束玩家选择权的字段（`ifMandatory` 已随跳过通道一并删除），它是上述物化模型的一个特例——**不由内容作者在 `.tres` 写死**，而由本服务在物化这一批时**动态置位**：
  - **取值域两档：`0`**（常态，玩家可从本批任选）与 **`1`**（本批一旦出现，有效可选集收窄为该档）。语义详见 `systems/adventure-event/common-properties.md`。
  - **置位方唯一 = 本服务；PlotManager 不得改变它。** **推论（边界澄清 · 承重）：PlotManager 只调内容不调约束**——它影响哪些事件进池、以什么权重出现，但**不能通过抬优先级强制玩家做某件事**；剧本的强制性只能靠**把候选池收窄**表达。
  Source: `handoffs/2026-07-26-event-priority-skip-semantics-and-hotfix-scope.md` + `handoffs/2026-08-06c-skip-channel-removal-priority-two-tier-and-location-codex-edges.md`。
- **跳过通道整体移除，批次刷新只剩一种形态（已定案 · 08-06c · 承重）。** 玩家面对一批 eventOptions 唯一能做的是**择一进入**；**每完成一次选择，本服务整批重算**——**选中一个即等价于跳过了其余全部**，故跳过是冗余机制。
  - **`TryRefill`（单项补位）整个方法删除**，本服务的 API 面由五个方法收为**四个**。「补位可能落空」「落空判据 = 配额用尽」「不生成付不起 `skipCost` 的事件」「不生成整批全跳的批次」**全部作废**——前提消失。
  - **`EventOptionBatch` 的恒真不变式与 `AnySkippable` 删除**：不再需要用字段保证「至少一个必做项」，因为**本批的每一项都是必做项**。
  - **「打不过也得打」这条设计意图升级为结构性事实。** 仍**不需要**产出侧的「至少一个可负担 / 可战胜选项」保证：**必须面对的遭遇打不过 → 输掉这一局，是正常且合意的结果**。这与失败侧的既有建制自洽（EnemyCodex 遭遇即记、失败也可能给经验，加上篇章重试模型；**道统残卷的累积已收窄为 Finale 失败专属**，不参与常规遭遇的论证）——**「输」是这个游戏的一个正常出口**；同时它**约束产出侧不要过度保护**，难度的界由赋级带给出已经足够。
  - **`selectCost` 侧同样不欠可负担性保证（08-06c 答结）。** 支付 `selectCost` 是**无条件的可推进行为**，付不起也照付、支付后判定状态、判负进失败流程（见 `systems/adventure-event/common-properties.md`）。**推论：「付不起唯一可选项 ⇒ 无法推进」这条死锁在规则层不成立**，本服务不需要为此做任何产出侧兜底。
  Source: `handoffs/2026-08-05b-location-fields-event-count-limit-and-skip-refill-closure.md` + `handoffs/2026-08-06c-skip-channel-removal-priority-two-tier-and-location-codex-edges.md`。
- **敌人物化 = 一条五旋钮管线，输入固定、顺序固定、产物落存档（已定案）。**

  ```
  输入：EnemyData（经 ContentRegistry.AllEnabled() 取池，按 PoolScope / location / 剧情线 / 篇章 / eventType 框定）
      + CharacterProfile（全局等级、所在篇章、隐藏属性）
      + location 框定
      + PlotManager 框定（选池 + 赋级权重偏移，不触及模板字段）
      + SeedManager 的 map 子流

  ① 选池 + 选模板  ← PoolScope（通用 / 地点专属 / 剧情线专属）+ location + 篇章 + eventType 框定 → 加权抽取
  ② 赋级          ← 角色全局等级 ±2 带 + 权重表
  ③ 卡组结构对齐   ← 以 ② 的等级为输入（仅费用曲线对齐与风味替换，不加第二条强度曲线）
  ④ item / power 持有列表  ← 直接取自模板（不由剧本调制改写）
  ⑤ 遭遇参数      ← eventType（Combat 10 回合 / WinMargin 1；Practice 8 / 0；Finale 12 / N）

  产出：EnemyInstance（定稿 · immutable · 嵌在 EventOption 上随批次落存档）
  ```

  - **关键规则：等级先定，其余四项以等级为输入，且不叠加第二条强度曲线。** 敌人的战斗强度以 `baseMomentum` 为主刻度——若卡组也随等级放大（更强的牌 + 更高的起始道念），强度就被**平方**，`±2` 带的数值安全性推导立刻失效。**卡组承担风味，等级承担强度。**

    | 旋钮 | 允许做的 | 不允许做的 |
    |------|---------|-----------|
    | **卡组改写** | 结构对齐（费用曲线与该等级的 `manaLimit` 相称）、风味替换（同族异名）、埋伏张数增减 | 用「等级越高牌越强」再加一条强度曲线；**由剧情线临场改写** |
    | **item / power 列表** | **直接取自模板**（boss 与天劫的「不可被移除的场上特性」写在其专属条目上） | **由剧本调制增删**；突破 `IgnoresProtection` 的配额 |
    | **遭遇参数** | 按 eventType 改写 `TurnLimit` 与 `VictoryRule` | 用它抵消等级带的约束 |

  - **卡组改写的表达形式**：常规敌人走**算子式**，boss / 天劫走**多套预制**（含天劫的定制卡组），二者并存。
  - **一条可在物化时机械检查的改写上界：必须保留模板标注的 `KeyCardIds`。** 否则图鉴会与玩家实际遭遇的敌人对不上——而图鉴在意图黑箱档位下是唯一的信息来源。违反 → `PushWarning` + **该次改写回退**；**`OverridesDeck == true` 的定制卡组条目显式豁免**（图鉴条目自带说明）。
  - **确定性与存档**：全部改写走 map 子流；产物 `EnemyInstance` **随 `EventOption` 落存档、不重算**（overlay 热更 + seeded RNG 使重算不保证同结果）。
  - **⚠ 前置依赖（诚实标注）**：「结构对齐」与「风味替换」目前**没有量纲**（费用曲线、道念产出量纲未定），故旋钮 ③ 在 ch1 数值标杆专场之前**只是一个框架，不能落地为具体改写算子**。
  Source: `handoffs/2026-08-06d-combat-open-questions-mass-closure.md`。
- **剧情线不可调制敌人模板；剧情线与地点各自可拥有专属敌人模板池（已定案 · 承重）。** 差异化的表达位从「改写模板内容」整体移到「**换一个池子抽**」：
  - 每个 `EnemyData` 带 **`PoolScope`**（通用池 / 某地点专属 / 某剧情线专属）；抽取时按 `EncounterScopes`（事件类型作用域）+ `PoolScope`（地点 / 剧情线）+ 篇章框定叠加，全部在 `AllEnabled()` 之后。
  - 「大限将至」线上的绝境敌人 = **该线专属池里的一条完整 `EnemyData`**（自带更凶的样本卡组与 power），**不是**把通用条目临场改凶。
  - **PlotManager 的权力因此收敛为三项：框定用哪个池 · 偏移带内赋级权重 · 拧紧遭遇参数。它碰不到模板的任何字段。**
  - **好处**：改写幅度天然有界 · 图鉴词条与玩家实际遭遇恒对得上（专属条目有自己的词条）· 可确定性复算。**代价**：内容量上升（每条专属敌人都是一个完整条目，含图鉴五项词条），归内容排期。
  - **两个字段的缺失语义不同**：`EncounterScopes` 空数组 → 加载期 `PushError`（漏填会静默缩小抽取池）；`PoolScope` **允许为空**（= 通用池），不报错。
  条目定义见 `systems/enemies/`。Source: 同上。
- **遭遇参数由本服务在物化时从 `AdventureEventData` 代入 `EncounterSpec`（已定案）。** `TurnLimit` / `VictoryRule` / `RewardPoolId` / `BaseReward` 全部在物化时定稿，**`EnemyData` 完全不携带**——否则同一个敌人条目无法同时用于 Practice 与 Combat。**依据 = 唯一物化点 + 产出即定稿**：消费侧不得回查模板重算，故 `EncounterSpec` 必须自带取值，不能只带一个 `EncounterId` 让 combat-service 回查。**物化时代入也是剧本调制的天然挂点**（PlotManager 可拧紧遭遇参数）。类型形态见 `systems/services/combat-service.md`。Source: 同上。
- **成本量值取负发生在本服务的物化组装阶段（已定案）。** 内容作者在 `AdventureEventData` 上以**正数量值**标注 `lifeSpanCost` 等成本（「耗 3 点寿元」写 `3`）；**本服务在组装 `SelectCost` 时取负**填入 `ChangeElement.BaseValue`，从而满足既定的带符号约定（负 = 消耗，正 = 产出）。这条转换**只在此处发生一次**——下游（life-cycle-service / ProfileManager）拿到的一律是带符号 spec，不再做任何符号推断。Source: `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。
- **战斗类事件在物化时精确标注敌人等级（已定案）。** Combat / Practice / Finale 的 `EventOption` 需向玩家**精确展示敌人的等级**（否决模糊的危险度档位）——玩家据此与自身等级比对，理解意图为何被遮蔽，并把「越级挑战」当作可主动选择的风险 / 回报。Source: 同上。
- **敌人也由本服务物化：`EnemyData` → 充实 / 改写 → 指派给事件（已定案）。** 敌人的**静态数据**集中在 **`EnemyData`** 集合（稳定 `Id` + 图鉴文案 + 基准数值 + **样本卡组**；玩家侧的那一面即 EnemyCodex）。本服务在物化一个战斗类事件时：**取出一份模板 → 依情境充实 / 改写（enrich / modify）→ 把结果指派给该事件**。**`EnemyData` 另需两个持有列表字段（08-04b）：item 持有列表与 power 持有列表**——**敌人没有储物袋**（那是角色的道具容器），道具与 `Power` 直接挂在模板上；战斗组装时 item 列表成为敌人侧的「本场可用道具」，power 列表按 `UsableScene` 过滤后入场为受保护永久物。**这给「物化时充实 / 改写」多了两个可调旋钮**（除等级与样本卡组外，还可调这一场敌人带哪些道具 / 特性）。Source: `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md` + `handoffs/2026-08-04b-mtg-loanwords-card-types-and-intent-snapshot.md`。

  - **敌人等级由此答定：它不是模板上的死值，而是物化产物。** 同一个敌人模板可在不同篇章、不同情境下以不同等级出场——这正是「多数属性由物化决定」在敌人上的应用。
  - **连带答定「等级标注的承载字段」的一半：** 既然等级在物化时确定，它就**随物化产物一同定稿并落存档**，而不是由 ViewModel 现查模板算出来。
  - **它是「模板 ↔ 实例」通则的第三个实例**（前两个是 `AdventureEventData ↔ EventOption`、`CardData ↔ CardInstance`，见 `systems/architecture.md` 总则 6）：模板是 ContentRegistry 里的共享只读单例，**本服务不得写回它**；改写只发生在物化产出上。
  - **样本卡组同理**：模板给基线卡组，物化时可改写（Finale 的天劫即极端情形——定制卡组的 Enemy）。

- **赋级的合法区间 = 角色当前等级 `±2` 的对称带（已定案 · 三章统一 · 承重）。** 物化赋级落在 `[角色等级 − 2, 角色等级 + 2]` 内，在全局序 **1–22** 上截断。
  - **它是一条相对 `diff` 的带，不是按境界给的绝对天花板**，且**同时给出上界与下界**（此前只有上界）。
  - **三章的带边界全部是内容侧可调数值（08-06b）**，与意图阈值的三处门槛同级。**本服务只读「当前篇章的带」这一个概念，不为分章写分支**；落点与加载时校验见 `systems/balance.md` 的待决问题。
  - **赋级规则挂在 Enemy 上，不挂在事件类型上** ⇒ **Combat / Practice / Finale 一视同仁**。天劫只是 Enemy 的一种，不享有等级规则上的例外（见 `systems/adventure-event/finale/`）；Practice 的「低风险」由回合数与胜负门槛承担，**不由「派个更弱的对手」承担**。
  - **推论 ①（承重 · 三章全部成立）：「一次惨败打穿耐久」由规则层封住。** 上界统一为 `+2`，最坏落差为 9（炼气十三层 `baseMomentum` 15 遇筑基中期 24），在 `lifeTotal` 10/10 之内。
  - **推论 ②：越阶遭遇只出现在每个境界的末两级**——12 · 13 → 筑基；16 · 17 → 金丹；20 · 21 → 元婴。**三章统一**，越阶压迫感自动向篇章尾部集中，与 Finale 落在篇章边界同向。
  - **推论 ③：`±2` 是无例外的硬规则。** 任何调制源（PlotManager、location 框定、事件模板、Finale）都不得产出带外 `diff`；**赋级函数不接受任何区间覆盖参数**——不给这个口子，就不存在「谁有权用它」的问题。调制源只能改**带内权重**。
  - **推论 ④：「上界档必然越阶 ⇒ 最难即最不可读」作废。** `diff = +2` 只在境界末两级才是越阶；境界中段的 `+2` 是同阶，照常按 `diff` 门槛给信息。
  - **推论 ⑤：本服务不再需要境界表。** 赋级 = 全局序上一次加减 + 截断；境界边界的特殊性由 `baseMomentum` 的跨度放大自然承载。
  - **推论 ⑦：带内分布权重表已定案**（三段权重 × 调制修正 × 截断重分配 × 批内去重），见 `systems/balance.md`。**截断重分配必须显式实现**：全局序 1–22 截断后落空的档位权重按比例并入带内剩余档，否则 L1 · L2 的抽取会出现权重和不为 1 的实现分歧。
  - **推论 ⑥：元婴（全局 22）**——角色 21 时带为 `[19, 22]`；抵达 22 即轮回终点，实际不产生遭遇。
  - **推论 ⑦：带只约束「能出到几级」，不约束分布。** 带内各档（ch1 七格 / ch2 · ch3 五格）以什么权重出现，仍归本服务的加权规则（待定）。
  Source: `handoffs/2026-08-05-level-band-stack-save-and-token-free-deck.md` + `handoffs/2026-08-06b-asymmetric-ch1-band-consented-power-loss-and-chapter-retry-shape.md`。

## 管理器

| manager | 职责 |
|---------|------|
| **EventOptionManager** | 依 CharacterProfile 产出 / 重算 eventOptions；location 框定与 seeded 抽取 |
| **PlotManager** | 隐藏剧本：按 key points 解析本地剧本节点、隐藏属性阈值 → 调制。**纯本地**。详见 [plot-manager](plot-manager.md) |

## 服务角色 / API 面（契约）
> _总则与共享类型见 `systems/architecture.md`「API 契约总则」。**本服务纯本地，永不跨进程边界，故全部方法为形态 A**——物化是纯内存计算，PlotManager 自 08-11 剧本本地化后亦不再跨边界（此前它是全项目唯一跨边界的 manager）。Source: `handoffs/2026-07-27b-service-api-contracts.md` + `handoffs/2026-08-11-plot-content-localization.md`。_

| 方法 | 形态 | 完整签名 | 失败语义 |
|------|------|----------|----------|
| 物化一批 | A | `EventOptionBatch ComputeEventOptions(CharacterProfile character)` | 内容池为空 = 坏数据 → `PushError` + 抛 |
| 结算后重算 | A | `EventOptionBatch RefreshAfterEvent(CharacterProfile character, string resolvedInstanceId)` | 同上 |
| 当前批 | A | `EventOptionBatch Current { get; }` | — |
| 剧本分支 | A | `OpResult ChooseBranch(string branchId)` | 业务失败 → `OpResult`；PlotManager 的**唯一对外投影**。**08-11 由形态 B 降为 A**（剧本本地化，无远端请求） |

```csharp
public sealed record EventOption(                 // 定稿实例：immutable 引用类型，落存档
    string             InstanceId,                // 本次物化实例的稳定标识；pastEvent / 存档引用它
    string             EventId,                   // 溯源到模板：ContentRegistry.Get<AdventureEventData>(EventId)
    EventType          EventType,                 // Mystery 时 = 遮罩类型；真身见 RevealedEventId
    int                Priority,                  // 物化时置位；取值域 { 0, 1 }
    ProfileChangeSpec  SelectCost,                // 物化时组装：内容侧正数量值 → 取负填入 BaseValue（modifier pipeline 尚未施加）
    bool               IsRevealed,                // Mystery：是否已揭示
    string             RevealedEventId            // Mystery 遮罩的固定事件（物化时即已确定）
    /* ⟨待定：其余物化字段清单，见待决问题⟩ */);

public sealed record EventOptionBatch(
    string                     BatchId,
    IReadOnlyList<EventOption> Options,
    int                        EffectivePriority);  // 本批最高优先级档（0 或 1）；有效可选集 = Priority == EffectivePriority 的全部
// 08-06c：跳过通道移除 ⇒ 删 AnySkippable 与「每批至少一个 IsMandatory」的恒真不变式——
// 本批的每一项都是必做项，唯一的推进方式是择一进入。
```

**为何 `EventOption` 是 `sealed record`（引用类型）而非 `readonly record struct`：** 字段多、要落存档、一批只有个位数个、不在每帧热路径——按值拷贝的代价高于一次分配。`record` 的 `with` 表达式同时给出「定稿后若确需派生（如 Mystery 揭示）就产生一个新实例而非改旧的」这一惯用法。

三点推演：

- **`ComputeEventOptions` 的语义就是「物化」：** 取 `AllEnabled()` 候选 → location 框定 → PlotManager 调制 → map 子流抽取 → 组装定稿实例（**成本量值在此取负**）。**物化完成后本服务不再改这批实例**；一批的更新只有一种形态——`RefreshAfterEvent` 产出**一批全新的实例**。
- **未选项摘要从「被替换的那一批」取，取用方是 life-cycle-service（已定案 · 08-09c）。** `RefreshAfterEvent` 会把当前批整批换掉；被换掉的那一批里除 `resolvedInstanceId` 之外的选项，正是要写进 `PastEventEntry.Unchosen` 的轻摘要来源。**本服务不因此新增方法、也不负责写档**——`Current` 在重算之前仍指向旧批，life-cycle-service 在组装 `PastEventEntry` 时读它即可，写入照常经 `profile-service.ProfileManager`。字段形态见 `systems/adventure-event/common-properties.md`。Source: `handoffs/2026-08-09c-past-event-trace-schema.md`。
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

- **生成 / 加权规则未定（08-05b 收窄）。** **location 层的形态已定案**（事件类型概率修正 + 敌人模板池 + `eventCountLimit`），**具体数值归内容制作阶段**；仍待定：**每批数量**、类型修正的**运算形态**（乘性 / 加性 / 白名单 + 权重，能否修正到 0）、月圆之夜式策划与随机权重的配比、以及 location 框定 / PlotManager 调制 / seeded RNG 的**叠加顺序**。→ `systems/game-progression.md`。Source: `handoffs/2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md` + `handoffs/2026-08-05b-location-fields-event-count-limit-and-skip-refill-closure.md`。
- **`EventOption` 的完整物化字段清单未定（07-27b 收窄 · 08-06c 减为七字段 · 08-09c 再收窄）。** 骨架七字段已定（`InstanceId` / `EventId` / `EventType` / `Priority` / `SelectCost` / `IsRevealed` / `RevealedEventId`）；但「**多数**属性由物化决定」意味着还有一批未列出的字段：哪些数值可被情境改写？outcome 权重是否在物化时固化？这需要一次**内容侧** handoff 才能定稿。**「风味文案是否也物化」已答结：不物化**（见「意图」），故剩余分叉**不含任何文本类字段**。→ `systems/adventure-event/common-properties.md`。Source: `handoffs/2026-07-27b-service-api-contracts.md` + `handoffs/2026-08-09c-past-event-trace-schema.md`。
- **物化后敌人实例的类型形态未定（08-09c 显式化）。** `EnemyInstance` 是**嵌在 `EventOption` 上**还是只记引用？战斗类痕迹需要它才能定稿。**不阻塞 `pastEvent` 的最小面已定：至少存 `EnemyTemplateId` + 物化赋级 `Level`**（等级是物化产物、重算不出，EnemyCodex 与角色履历都要读它）。→ `systems/enemies/`、`systems/adventure-event/common-properties.md`。Source: `handoffs/2026-08-09c-past-event-trace-schema.md`。
- **框定叠加顺序。** location 框定、PlotManager 调制、seeded RNG 三者的叠加顺序与优先级未定。→ `systems/game-progression.md`、`systems/services/plot-manager.md`。
- **`Priority = 1` 依什么条件抬升（08-06c 收窄）。** **取值域（两档）与置位方（本服务独占，PlotManager 不得改）已定案**；仍待定：本服务依什么条件把某个选项抬到 `1`（剧情线关键节点？配额闸门之外还有哪些？），以及**同批出现多个 `1` 档时是否需要额外收窄规则**（当前语义：同档内自由择一）。→ `systems/adventure-event/common-properties.md`。Source: `handoffs/2026-08-06c-skip-channel-removal-priority-two-tier-and-location-codex-edges.md`。

## 对应
提炼至：`.claude/knowledge/systems/future-event-service.md`（引用层，待建）。
