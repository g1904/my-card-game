# 术语表（Terminology）

> 开发中使用的专有术语事实来源：中文领域词 ↔ 英文 / 代码标识符。随开发滚动更新。
> 代码标识符沿用此处的英文 / 代码列（`csharp-godot-rules.md` 的 PascalCase 命名）。
> 提炼至：`.claude/knowledge/dictionary.md`。
>
> **借词纪律（08-02 定）：** card / deck / combat 体系将**大量借用 MTG 术语**来简化表达。**每个借入的词都要在本表登记为已定含义**——写清它在本作中指什么、与 MTG 原义有何出入，避免同一个词在两套语境间漂移；借词也不得覆盖既有的仙侠定名（mana = 法力、momentum = 道念、PlayerPower = 法则、PlayerItem = 古宝、CharacterPower = 神通、CharacterItem = 法宝）。**第一批借词已于 08-04b 全部定名**（见「战斗 · 卡牌类型与异能」小节）；后续新借的词照此登记。Source: `handoffs/2026-08-02-momentum-conversion-reward-structure-and-mtg-stack.md` + `handoffs/2026-08-04b-mtg-loanwords-card-types-and-intent-snapshot.md`。
>
> **中文名不承担层级表达（08-03 定）：** `PlayerPower` / `PlayerItem` / `CharacterPower` / `CharacterItem` 的中文定名为**法则 / 古宝 / 神通 / 法宝**——四个彼此独立的仙侠词，**不共用词根**。账号级 ↔ 轮回级的对称此后**只在英文标识符上成立**（`Player*` / `Character*`）；**UI 文案不能靠中文名传达「这是账号级的」**，层级须由界面归属（元进程界面 vs 轮回内界面）承担。Source: `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md`。

## 核心结构

| 中文 | 英文 / 代码 | 含义 | 来源 |
|------|------------|------|------|
| 轮回 | cycle | 从开局到胜 / 负的一次完整游玩历程（roguelike 体裁通称 *run*，本作定名为**轮回**）。由 seed 驱动，含三个篇章，状态与历史落在一个 CharacterProfile 上；生命周期归 life-cycle-service。 | 全库术语重构 2026-07-27（`run` → `cycle`，与 life-cycle-service 同词根） |
| 修行事件 | AdventureEvent | 逐时逐刻的游玩单元；玩家从当前可用项中择一以推进轮回。 | `handoffs/2026-07-15b-taxonomy-and-checkpoint-clarifications.md` |
| 修行历程 | `pastEvent`（集合，`IReadOnlyList<PastEventEntry>`） | 一个角色**已走过**的整段修行旅程——一条扁平的、**只追加**的时序轨迹。**只有一种痕迹：进入并结算**（跳过通道已移除）。**向前的走向不在此结构中**，由 future-event-service 每步现算的 eventOptions 决定。 | 同上 + `handoffs/2026-08-09c-past-event-trace-schema.md` |
| 痕迹条目 | `PastEventEntry` | `pastEvent` 的条目类型（`sealed record`，immutable，落存档）= **定稿实例快照 + 本次结算的最终账**（`AppliedChange`）。字段取舍由判据给出：**重算不出来的存，重算得出来的不存**（文本类字段一律留在模板侧）。含同批未选项轻摘要 `UnchosenOptionRef`。 | `handoffs/2026-08-09c-past-event-trace-schema.md` |
| 结算走向 | `EventOutcome` | 痕迹上的四值枚举：`Resolved`（非战斗类正常结算）/ `CombatWon` / `CombatLost` / `Aborted`（支付 `SelectCost` 后终态判定 ① 即短路，事件未进入 resolver）。 | 同上 |
| 可选事件 | `EventOption`（集合，`List<EventOption> eventOptions`） | future-event-service 由 `AdventureEventData` 模板**物化**出的**定稿实例**（`sealed record`，immutable，落存档）：按 `EventId` 溯源模板、按 `InstanceId` 被引用，携带物化时置位的全部属性（含 `eventPriority`）。**产出即定稿**，下游只读消费。 | `handoffs/2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md` + `handoffs/2026-07-27b-service-api-contracts.md` |
| 物化 | materialize | future-event-service 把 `AdventureEventData`（模板 / 参数空间）**依情境代入**（CharacterProfile + location + PlotManager 调制 + map 子流）产出定稿 `EventOption` 的过程。**唯一物化点 = future-event-service；产出 eventOptions ≡ 物化 AdventureEvent；产出即定稿、不可改写、不回查模板重算。** | `handoffs/2026-07-27b-service-api-contracts.md` |
| 实例标识 | `InstanceId` | 一次物化实例的稳定标识。同一模板（`EventId`）可在一次轮回里被物化多次，故 `pastEvent`、事件负载一律按 `InstanceId` 定位，**不可用 `EventId` 替代**。 | 同上 |
| 卡牌实例 | `CardInstance` | `CardData` 模板的运行时实例（手牌中的临时增益等）。与 `EventOption` 同属「内容定义 + 轮回内状态」的第二类型，区别在于它**运行态可变**；共享纪律「服务签名里传实例，不传 `Resource`」。 | 同上 |
| 操作结果 | `OpResult` / `OpResult<T>` | 统一的**业务失败**返回类型（`readonly record struct`，零堆分配）：`Success` + `OpError`（`Network` / `Auth` / `Compliance` / `Validation` / `NotFound` / `Conflict` / `Cancelled` / `Migration`）+ `Detail`。**业务失败绝不抛异常**；必需缺失才 `PushError` + `throw`。 | 同上 |
| 档案变更规格 | `ProfileChangeSpec` | 施加给 `ProfileManager.TryApply` 的声明式变更规格：`IReadOnlyList<ChangeElement>`，`ChangeElement.BaseValue` **带符号**（负 = 消耗，正 = 产出）。**取代先前的 `CostSpec` / `RewardSpec` 两个类型**——成本与产出必须落在同一事务内。`selectCost` / `CombatResult.Spoils` 均为它。 | 同上 |
| 存档点原因 | `SavePointReason` | `sync-service.PushAsync` 的枚举参数（`CycleStarted` / `EventResolved` / `ChapterBoundary` / `CycleEnded` / `MetaChanged`）：驱动日志、重试策略与合并窗口。与 `PushPolicy { Debounced \| Immediate }` 配合。 | 同上 |
| RNG 子流 | `RngStream` | 具名 RNG 子流的枚举（`Map` / `Combat` / `Shop` / `Reward`）。`life-cycle-service.Stream(RngStream)` 返回 Godot 的 `RandomNumberGenerator`（自带可序列化的 `Seed` / `State`），而非 `int Next()`。 | 同上 |
| 玩家信息 | PlayerProfile | 账号级主档，跨轮回持久，持有一组 CharacterProfile 及账号级元数据。 | `handoffs/2026-07-15-adventure-event-profiles.md` |
| 角色信息 | CharacterProfile | 单次轮回 / 单个角色的状态与历史（对齐 CycleState 概念）。 | 同上 |
| 法则 | PlayerPower | 账号级 always-available 能力，带开关（默认开启）；QoL 或影响公平性的全局加强，不与角色绑定，可获取 / 失去。**中文定名 = 法则**（08-03 定，取代「玩家能力」；`power` 不再有统一中文通译，两层各自定名）。**战斗内以 `CardType.Power` 呈现**：`status == 开启` 且 `UsableScene` 含 `InCombat` 者在**开局入场**、受保护不可被针对——故除 capability flag 与 modifier pipeline 外，另有**战斗内异能**这第三条生效通道（**允许但极其稀缺**，`InCombat` 法则应 ≤ 1/5，08-04b 定）。 | `handoffs/2026-07-22-online-cloud-combat-and-meta-clarifications.md` + `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md` |
| 古宝 | PlayerItem | 账号级、有使用次数限制的道具。**中文定名 = 古宝**（08-03 定，取代「玩家道具」）。**战斗内以 `CardType.Item` 呈现**：存于**储物袋**、**不洗进卡组**、不受抽牌运制约，使用窗口与出牌同（自己回合的行动阶段、栈为空时）；**使用次数即时经 `ProfileManager.TryApply` 写 PlayerProfile**，不攒到收口（08-04b 定）。 | 同上 + `handoffs/2026-08-04b-mtg-loanwords-card-types-and-intent-snapshot.md` |
| 神通 | CharacterPower | **轮回级**的角色能力，**对标账号级的 PlayerPower（法则）**（同一概念的两层，分界是生命周期）：由 CharacterProfile 持有，随轮回清理；沿用 `status` 开关、事件触发器被动修正、capability flag + modifier pipeline 两条生效通道。**可承载战斗内的触发式效果**（见「触发器」）。**中文定名 = 神通**（08-03 定，取代「角色能力」）。**战斗内以 `CardType.Power` 呈现**：`status == 开启` 且 `UsableScene` 含 `InCombat` 者在**开局入场**、作为受保护的永久物不可被针对 / 移除（08-04b 定）。归 `systems/character-profile/power/`。 | `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md` + `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md` |
| 法宝 | CharacterItem | **轮回级**的角色道具，由 CharacterProfile 持有（现有写法 `List<CharacterItems>`，单复数待统一）、随轮回清理；对标账号级的 PlayerItem（古宝）。**中文定名 = 法宝**（08-03 定，取代「角色道具」）。**战斗内以 `CardType.Item` 呈现**：存于**储物袋**、**不洗进卡组**、不受抽牌运制约，使用窗口与出牌同；消耗即时经 `ProfileManager.TryApply` 写 CharacterProfile（08-04b 定）。归 `systems/character-profile/item/`。 | `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md` + `handoffs/2026-08-04b-mtg-loanwords-card-types-and-intent-snapshot.md` |
| 道念 | momentum | **计分（scoring）用的胜利点数**，**`>= 0` 的 Integer**，双方各持一份：**战斗胜负 = 道念高者胜**。**由卡牌产出、可互相削减、下限为 0**（削减是饱和减法，**在每一次结算时就截断**，溢出的削减量不结转）；**战斗开始时双方各有一个由自身等级决定的起始道念 `baseMomentum`**。**标准 Combat = 10 个回合**（双方各 5 个）后比大小；**相等 = 平局，只发 `baseReward`、不扣 lifeTotal**。道念差在胜负两侧各驱动一件事：**胜 → 奖励厚度**（换算未定），**负 → 按差值 1:1 扣 lifeTotal**。道念是战斗内运行态，战斗结束即消失，不落 CharacterProfile。归 `systems/scoring.md`。 | `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md` + `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md` + `handoffs/2026-08-02-momentum-conversion-reward-structure-and-mtg-stack.md` |
| 基础奖励 | baseReward | 一个战斗事件**不论胜负都会发放**的奖励底盘。胜 = `baseReward` + 按道念差加厚；平 = 只发 `baseReward`；负 = `baseReward`，**少数事件另夹带负向条目**（额外惩罚**包在 reward 里**，不另立惩罚结构——与 `ProfileChangeSpec` 的带符号约定自洽）。奖励**由 combat-service 计算**，写入仍由 life-cycle-service 在 `eventEnd` 一次施加。 | `handoffs/2026-08-02-momentum-conversion-reward-structure-and-mtg-stack.md` |
| 堆栈 | stack | 卡牌结算模型，**借自 MTG**：打出的牌**不立即生效**，先入栈，按**后进先出（LIFO）**依次结算——「打出」与「结算」是两个时刻。**只借结算模型，不借交互与优先权**：无 instant、栈非空时不可出牌（**对双方都成立**）、无优先权传递，故**回合是「我打完换你打」的简单交替**。**栈深由触发式能力撑起**：在栈上的牌可以触发能力，**被触发的能力也进栈**，故即便只打出一张牌栈深也可大于 1；连锁触发按 LIFO 解决，**后触发的先生效**。归 `systems/character-profile/deck/`。 | 同上 + `handoffs/2026-08-02b-stack-without-interaction-and-three-step-turn.md` |
| 回合结构 | turn structure | 一个回合固定走**三步**：**开始阶段 start step**（回合归属方 mana 恢复至 `manaLimit` → 触发「回合开始时」→ 抽牌）→ **行动阶段 action step**（**唯一**出牌阶段，只有回合归属方能出牌）→ **结束阶段 end step**（触发「回合结束时」→ 清理回合内的非永久条目）。**无战斗步骤、无双主阶段。** 步内顺序是规则的一部分；**三步是回合归属方的流程，双方不同时走**（回合开始 / 结束是有归属方的时点）。中文侧统一以「阶段」收尾、英文侧统一以 `step` 收尾（08-04b 定名；`main phase` 弃用）。归 `systems/services/combat-service.md`。 | `handoffs/2026-08-02b-stack-without-interaction-and-three-step-turn.md` + `handoffs/2026-08-04b-mtg-loanwords-card-types-and-intent-snapshot.md` |
| 手牌上限 | hand size limit | **手牌在任何时刻都不得超过的张数上限**——是一条**恒定不变式**，不是回合末的清算：**没有时间限制，也没有必须弃牌的机制**。约束点落在会让手牌增加的时刻：**满手时抽牌抽不进（牌留在抽牌堆，本次抽牌无事发生），「加入手牌」类效果同理落空**——不抽出即弃、不销毁，故手牌上限是**纯上界**，不产生弃牌堆流量。**上限数值待定。** 归 `systems/character-profile/deck/`。 | 同上 + `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md` |
| 战场 | battlefield | **战斗的公共区**：记录**场上的全部准确数据**——哪些卡牌正在生效、有哪些持续状态、有哪些触发器在等待，以及各条目的生命周期标记（回合内 / 跨回合）。**与栈是两个区**：栈 = 等待结算的队列，战场 = 已结算并正在生效的东西；结算路径 = 打出 → 入栈 → LIFO 弹出结算 → 效果施加 →（若持续）落到战场。由 **BattlefieldManager**（combat-service 的 manager）持有。**单一战场记录，不分双场区容器**——条目自带 `OwnerSide` 表示归属方，呈现层按它分区渲染。**划线判据（08-04b 定）：** 在场上生效、可被针对 / 查询、需在结束阶段清理、需进决策点存档 → **战场条目**；参战方的私有资源与牌堆（mana / 道念 / 手牌 / 卡组 / 本场可用道具）→ 归参战方 manager。**「属于谁」只是它的一个字段，不是它的住处。** | `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md` + `handoffs/2026-08-04b-mtg-loanwords-card-types-and-intent-snapshot.md` |
| 触发器 | trigger | 触发式效果的挂载点。**载体开放、不专属卡牌**：牌上的触发器、**场上的持续状态**、**CharacterPower（神通）** 都可能承载，清单可再增。**触发命中后被触发的能力由 StackManager 压入栈**（与载体解耦）；「谁在监听哪个时点」的注册面坐在 **battlefield** 上。已定的触发时点：「回合开始时」/「回合结束时」（有归属方的时点）。**触发条件可跨归属方**（08-04b 定）：时点有归属方，但**监听方不必是该归属方**——可写「对手的回合开始时」「对手打出牌时」，埋伏牌靠此成立。 | 同上 + `handoffs/2026-08-04b-mtg-loanwords-card-types-and-intent-snapshot.md` |
| 回合归属方 | turn owner | 当前回合轮到的一方。**只有归属方能主动出牌**，且起始步恢复的是**归属方的** mana。 | 同上 |
| 出牌时机（唯一） | —（无借词） | 一张牌只能在**自己回合的行动阶段、且栈为空时**打出。这是**全局规则，不是卡牌属性**——本作不存在第二种出牌时机；**启动式异能与道具的使用窗口与之完全相同**。`instant`（瞬间）**明确不借**；**`sorcery speed` 亦不借**（08-04b 整条删除：与之相对的 `instant speed` 不存在，单一取值的维度不是维度，保留它会制造「本作有出牌时机之分」的错觉）。 | 同上 + `handoffs/2026-08-04b-mtg-loanwords-card-types-and-intent-snapshot.md` |
| 经验值 | `experiencePoint` | **等级成长的累积量**，`CharacterProfile.Status` 上的字段：**每个等级各有一个升级所需的经验阈值**，AdventureEvent 的 reward **发放经验值**（而非直接给等级），累积达阈值才升一级。**任何类型的事件都可能给，失败也给**（失败给得少）。它是战斗奖励中「强制自动计入」的那一类。阈值曲线待定，归 `systems/balance.md`；等级模型见 `systems/game-progression.md`。 | 同上 |
| 起始道念 | baseMomentum | 每个**全局等级**对应的战斗起始道念（炼气 1–13 → 1..12, 15；筑基 20 / 24 / 28 / 32；金丹 45 / 55 / 65 / 75；元婴 100）。**境界鸿沟由它承载**（全局等级序基数本身连续无跳变），故等级差直接变成开局的起跑线差。可调数值，归 `systems/balance.md`。 | `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md` |
| 生命总量 | lifeTotal | **角色的生命值** —— 战斗外的耐久 / 失败惩罚承受量（**不是战斗内血量**）：战斗过程中既不消耗也不读取，只在战斗 / 修炼失败的**结算时刻**按道念差**1:1**被扣减，**通过 AdventureEvent 恢复**。**归 0 → 角色 `defeated`**（与寿元归 0 并列的第二条终结路径）。对齐 `Status.lifeTotal` —— **只有这一个字段：`lifeTotalLimit` 概念整体删除，没有上限字段、没有上限截断**（`currentHealth / healthLimit` 亦作废）。炼气基线 **10**（进入更高境界时一次性跃升到 25 / 40），此后完全由事件 reward / cost 与战斗失败推拉。区别于寿元 lifeSpan（按事件流逝的寿命预算）。 | 同上 + `handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md` |
| 法力 | mana | **战斗内的出牌资源**（战斗内另一半是道念）。**无 mana 曲线**：战斗中**每回合开始恢复至 `manaLimit`**，而 `manaLimit` 由事件的 cost / reward 推拉（可升可降），不随境界自动成长，**不设下界护栏**。炼气基线 5/5。对齐 `Status.currentMana / manaLimit`。 | `handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md` + `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md` + `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md` |
| 道统残卷 | PlayerPowerFragment | 元进程的**失败侧产出**：累积的**不是账号级货币**，而是获得新 PlayerPower 的**递增掉落概率**。**三个时刻全部落在 Finale（天劫）上**——**Finale 失败累积、Finale 胜利掷骰、在该 Finale 的 eventReward 界面即时发放**；掷中并授予后概率重置为新档地板。上限 / 基础概率 / 适格篇章按账号**已拥有法则数 `x`** 分档。落 `PlayerProfile` 上的同名具名小类（5 个字段），**不并入账号级统计计数**。避免引入第二套账号级经济。归 `systems/player-profile/player-power/`。 | `handoffs/2026-08-09b-player-power-fragment-finale-bound-drop-chance.md` |
| 渡劫成功序号 | `FinaleWinOrdinal` | 账号级 **Finale 胜利序号**，`PlayerPowerFragment` 上的 `int`：只在 **Finale 胜利**时 +1（失败、以及 1% 的「失败但存活」都不自增），单调递增、不清零，**同时是道统残卷掷骰的幂等键**。**它不是通关数统计**——统计侧的「通关」= 完成整个轮回（`TotalCyclesCompleted`），两个数在任何账号上都不相等；「渡劫成功了几次」的展示**直读本字段**，统计层不另设 Finale 胜利数。它属**规则字段层**（严格同步 · 后端可复算），命名硬约定：后缀 `Ordinal` 保留给规则序号 / 幂等键，统计计数层禁用。归 `systems/player-profile/`。 | `handoffs/2026-08-09b-player-power-fragment-finale-bound-drop-chance.md` + `handoffs/2026-08-09d-field-layering-merge-criterion-and-ordinal-naming.md` |
| 账号级统计计数 | `Total...` / `...Count` | `PlayerProfile` 上的一族**纯读数**（首批含篇章重试的跨角色累计、`TotalCyclesCompleted`），与 `Achievements` 相邻但不同——**成就是有奖励的里程碑，统计计数只被 UI 读来看**。**绝不被任何规则读取**，故走宽松同步口径（被篡改无玩法后果）。与规则字段层的分层判据、合并判据与命名约定见 `systems/player-profile/_index.md`。 | `handoffs/2026-08-06b-asymmetric-ch1-band-consented-power-loss-and-chapter-retry-shape.md` + `handoffs/2026-08-09d-field-layering-merge-criterion-and-ordinal-naming.md` |
| 等级 | level | **境界内的层级**：炼气 1 层~13 层；筑基 / 金丹 各为 初期 / 中期 / 后期 / 巅峰；元婴仅初期。篇章结束突破后**一律归位为新境界的初期**（元婴亦然）。归 `systems/game-progression.md`。 | `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md` |
| 全局等级序 | global level | 跨境界连续的等级序 **1–22**（炼气 1–13 / 筑基 14–17 / 金丹 18–21 / 元婴 22），由「境界基数 + 境界内 level」合成，**境界之间不留跳变**（鸿沟由 `baseMomentum` 承载）。枚举值自带描述（`level=1` → 炼气一层，`level=14` → 筑基初期，…）。等级差比较在此序上做，不拿两个境界内的层号直接相减。 | 同上 + `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md` |
| 意图 | intent | 敌人**下一个回合全部出牌的综合描述**（**数值 = 计算后合并的最终结果**、**类别 = 主类别并行陈列**，非逐张预告；EnemyManager 内部生成，**只在玩家回合呈现、敌人回合收起**）。**意图 = 预期决策链路的快照**：在玩家回合开始前按当时局面用公式推算定案，**公布后不重算，但不保证与执行一致**——敌人回合按执行时的真实局面求值，偏差是常态而非异常（08-04b 修正「即承诺」的措辞）。**呈现三档**，判据 = **同阶等级差 + 越阶硬门**：**越阶（敌人境界更高）一律完全无信息**；同阶时按篇章 —— **第一篇章** `diff ≤ -3` 完整意图 / `-2 ~ 2` 仅类别 / `≥ 3` 完全无信息；**第二 · 第三篇章** `diff ≤ -2` / `-1 ~ 1` / `≥ 2`。第三档不给任何替代线索。**完整意图因此是碾压专属，「仅类别」才是常态（同级只给类别为有意为之）。** | 同上 + `handoffs/2026-08-02c-intent-threshold-inversion-and-aggregate-intent.md` |
| 探查 | `probe`（标识符暂定） | 玩家**主动付出代价换取当回合敌人意图**的效果——与被动的意图档位相对，是第二条信息通道。「能力 / 道具授予窥视意图」即其授予形式。**具体形态归卡牌 / 技能内容的横向扩展阶段，现阶段搁置。** | 同上 |
| 图鉴（族） | Codex | **账号级的知识收集面**，共**五个**：`EnemyCodex` / `CharacterPowerCodex` / `PlayerPowerCodex` / `CharacterItemCodex` / `PlayerItemCodex`。跨轮回持久、归 PlayerProfile、条目按内容 `Id` 索引、内容为**静态文案**（挂在对应 `Resource` 上），存档只记解锁状态。归 `systems/player-profile/codex/`。 | `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md` |
| 敌人图鉴 | EnemyCodex | 图鉴族之一（类 Pokédex）。只记录**静态知识**（这个敌人会做哪些事），**不记录动态意图**（它这回合做什么），故不架空越级黑箱。**遭遇即记录，不必击败**；**一次遭遇即全文案解锁**，词条含 人物背景 · 功法简介 · 运作方式 · 特点与弱点 · `EnemyData` 样本卡组的关键卡牌。 | 同上 + `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md` |
| 敌人模板 | EnemyData | 敌人的**静态内容数据**集合（稳定 `Id` + 图鉴文案 + 基准数值 + **样本卡组** + `KeyCardIds` + `EncounterScopes` + `PoolScope`）。**敌人等级不在模板上定死**：future-event-service 取一份模板 → 充实 / 改写 → 指派给该事件，等级是**物化产物**。与 `AdventureEventData ↔ EventOption`、`CardData ↔ CardInstance` 同属「模板 ↔ 实例」通则。**标识符统一为 `EnemyData`**（`XxxData` 是全库内容层的命名族），中文领域词保留「敌人模板」。归 `systems/enemies/`。 | `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md` + `handoffs/2026-08-06d-combat-open-questions-mass-closure.md` |
| 敌人实例 | EnemyInstance | 物化后的**定稿敌人**（`InstanceId` / `EnemyId` / `Level` / `DeckCardIds` / `ItemIds` / `PowerIds`）。性质**对齐 `EventOption` 而非 `CardInstance`**：产出即冻结、不可变、**嵌在 `EventOption` 上随批次落存档**、下游只读消费。**战斗内的敌人运行态**（道念 / 手牌 / 卡组状态 / 已用道具 / `Power` 计数器）由 **EnemyManager 持有**，不进 `EnemyInstance`、也不另立类型。**本作不存在多敌人场景**，故承载字段一律写单数。 | `handoffs/2026-08-06d-combat-open-questions-mass-closure.md` |
| 灵玉 | jade | **轮回级软通货**（官方货币名）：随轮回存在、随轮回清理，归 CharacterProfile；主要花销在 Exchange（交易 / 商店）。区别于每回合出牌资源 mana。 | `systems/character-profile/currency.md` |
| 道心 | faith | **隐藏数值属性**（原 `faith` / 信仰即时属性，现归为隐藏）；与 煞气 / 寿元 同属驱动 AdventurePlot 的隐藏属性。 | `handoffs/2026-07-15-adventure-event-profiles.md` + 归隐藏 `handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md` |
| 煞气（点数） | malefic qi | **隐藏属性**：积累到阈值触发「煞气反噬」剧情线。 | `handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md` |
| 寿元 | lifeSpan | **隐藏属性**：角色寿命预算（**非 life**）——炼气起始 100、抵达筑基 +100、抵达金丹 +300、抵达元婴 +500（元婴为终点，该增量无玩法影响）；**剩余寿元跨篇章结转**。初始隐藏，**30% 起给定性叙事提示、10% 起给红字数值倒数**；每完成一个 AdventureEvent 按其 `lifeSpanCost` 扣减，**递减到 0 → 「大限将至」→ 角色 defeated**。 | 同上 + `handoffs/2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md` + `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md` |
| 寿元消耗 | lifeSpanCost | **成本类型 `selectCost` 的一个 element**：完成该事件对角色寿元的扣减。**内容侧以正数量值书写**（「耗 3 点」写 `3`），由 future-event-service 在**物化组装 spec 时取负**填入带符号的 `ChangeElement.BaseValue`。它是**控制篇章时长的主旋钮**（目标：**30–40 / 35–45 / 45–55 分钟**，熟练玩家口径），分档表待定。 | `handoffs/2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md` + `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md` |
| 事件类型 | eventType | AdventureEvent 的共有字段：该事件归属九类子类型中的哪一类。 | `handoffs/2026-07-25b-event-cost-fields-capability-flags-and-service-hierarchy.md` |
| 选择成本 | selectCost | AdventureEvent 的共有字段，且是一个**定制的复合成本类型**：由若干成本 element 组成（`lifeSpanCost` 为其中之一），表示选中该事件以推进轮回所需付出的代价。**代码形态 = `ProfileChangeSpec`，在物化时组装。** **支付它是无条件的可推进行为**——不因「付不起」被拒绝，支付后做状态判定，判负则进失败流程。 | 同上 + `handoffs/2026-07-27b-service-api-contracts.md` + `handoffs/2026-08-06c-skip-channel-removal-priority-two-tier-and-location-codex-edges.md` |
| 事件优先级 | eventPriority | AdventureEvent 的共有字段，**取值域两档：`0`**（常态，本批自由择一）与 **`1`**（有效可选集收窄为该档，其余本轮被封锁）。**只由 future-event-service 在物化时置位，PlotManager 不得改变。** 它是**唯一**约束玩家选择权的字段（跳过通道与 `ifMandatory` 已移除）。 | `handoffs/2026-07-26-event-priority-skip-semantics-and-hotfix-scope.md` + `handoffs/2026-08-06c-skip-channel-removal-priority-two-tier-and-location-codex-edges.md` |
| 能力标记 | capability flag | PlayerPower 授予的具名布尔标记（如「显示隐藏属性」），由中心聚合面按 `status` 汇总为**生效能力集**，消费侧单点查询。 | 同上 |
| 修正管线 | modifier pipeline | PlayerPower 注册的**具名数值修正**（`lifeSpanCost`、商店价格等）的统一施加入口 `Apply(key, baseValue)`，取代各消费层的散落条件。 | 同上 |
| 展示模型 | ViewModel | 呈现期由 `Data + 运行时状态` 组装的展示对象；**不落存档、不进云端负载**，是「服务 → 屏幕」的数据形态契约。 | 同上 |
| 可选事件集 | eventOptions | 一组当前可选的 `AdventureEvent`，玩家从中择一以推进轮回；由 future-event-service 依当前 CharacterProfile 产出、每个事件后重算。 | `handoffs/2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md` |
| 境界突破 · 高潮 | AdventureEvent-Finale | 篇章边界的境界突破事件；分类法**第七类，独立于 Combat**（ADR-0002 07-23 修订）。 | 同上 |
| 修行剧情（体系） | AdventurePlot | 隐藏剧本层的总称：由分支可能性构成、在背景中运行、**调制 future-event-service 产出的 eventOptions**；可像 DnD 那样让玩家选分支。下含 Story / Chapter / SideChapter / SideStory 四级。由 PlotManager 提供 API。 | 同上 |
| 主线剧本 | AdventurePlot-Story | 贯穿**三大篇章**相连的**大剧本**（一条角色的完整主线故事）。 | 同上 |
| 篇章剧本 | AdventurePlot-Chapter | **单个篇章**对应的剧本单元（一个 Story 含三个 Chapter）。 | 同上 |
| 支线（篇章内） | AdventurePlot-SideChapter | 在**单个 Chapter 内**穿插的小型支线剧本。 | 同上 |
| 支线（跨篇章） | AdventurePlot-SideStory | **跨篇章**穿插的支线剧本。 | 同上 |
| 剧情节点 | AdventurePlot key points | Character 上记录的 AdventurePlot **关键节点 / 进度锚点**（完整剧本与分支内容不落在存档，见「剧本服务」）。 | 同上 |
| 剧本服务 | script service | 存储**全部 AdventurePlot 剧本与分支内容**的（云端）服务；客户端按 key points 向其请求完整剧本 / 分支。 | 同上 |
| 服务 | service | **进程内模块单例**（**不是**微服务：同一二进制、同一进程、直接方法调用）。**边界单元**，判据三选一：① 自有状态机 / 长流程 ② 事务性跨字段一致写 ③ 外部 I/O 边界。以 autoload 存在，彼此不互相读写字段。 | `handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md` |
| 管理器 | manager | **第二级抽象**：服务内部的职能组件（普通 C# 对象，非 `Node`）；共享宿主服务的事务边界与生命周期，**不被跨服务直接调用**。 | 同上 |
| 模块 | module | **第三级抽象**：manager 内部的组件。命名后缀即层级声明（例：`DeckModule` —— 卡组由 `CharacterManager` / `EnemyManager` 各自持有、每参战方一份）。 | `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md` |
| 处理器 | processor | **第四级抽象**（名字先定，目前无实例）。 | 同上 |
| 处理器件 | handler | **第五级抽象**（名字先定，目前无实例）。 | 同上 |
| 后端 | backend | 客户端之外的**唯一真实进程边界**：账号鉴权 · 档案存储 · 剧本下发 · 内容分发。另一套代码库，不在本项目内。 | 同上 |
| 编排顶点 | game-progression | 屏幕流程编排层（**不是服务**）：串联核心循环 `ComputeEventOptions → 呈现 → 选择 → AdvanceEvent → 重算`。 | 同上 |
| 账号服务 | account-service | 服务：登录渠道、token / 会话、合规（AuthManager、ComplianceManager）。 | 同上 |
| 内容服务 | content-service | 服务：`res://` 基线 + `user://overlay/` 热更的合并与按 `Id` 索引；**唯一内容读取入口**（ContentRegistry、ContentUpdateManager）。 | 同上 |
| 同步服务 | sync-service | 服务：档案 Pull / Push、本地原子写、schema 迁移（ProfileSyncManager、LocalCacheManager、MigrationManager）。 | 同上 |
| 档案服务 | profile-service | 服务：`PlayerProfile` 与 `CharacterProfile` 的**唯一写入面**；capability 聚合；成就（ProfileManager、CapabilityManager、AchievementManager）。 | 同上 |
| 生命周期服务 | life-cycle-service | 服务：轮回生命周期（开始 seed、推进、胜/负、清理、篇章继承、状态机、重试）。（CycleStateManager、ChapterManager、SeedManager） | `handoffs/2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md` |
| 未来事件服务 | future-event-service | 服务：依当前 CharacterProfile 产出 eventOptions，每个事件后重算；**eventOptions 唯一出口**。（EventOptionManager、PlotManager） | 同上 |
| 隐藏剧本管理器 | PlotManager | **管理器，隶属 future-event-service**：隐藏属性驱动、key points ↔ 云端剧本服务、eventOptions 调制、DnD 式选分支。 | `handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md` |
| 战斗服务 | combat-service | 服务：**固定 10 回合**的回合循环、抽/弃/洗、**双方道念与「道念高者胜」的判定**、敌人 AI 与意图（**意图按三档揭示**）；**Practice / Finale 为其变体**。（TurnManager、CharacterManager、EnemyManager、**BattlefieldManager**、**StackManager**；`DeckModule` 为第三级组件，每个 character / enemy 一份） | 同上 + `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md` + `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md` + `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md` |
| 付费礼包 | premium bundle | 唯一已陈述的付费点：购买后给予**随机 1 个 PlayerPower + 随机 2 个 PlayerItem**，并把**第二篇章重试上限 3 → 9、第三篇章 1 → 3**（第一篇章本就无限）。使 ADR-0004 的重试上限从常量变为**基线值**。归 `systems/monetization.md`。 | `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md` |
| 内容注册表 | ContentRegistry | content-service 的管理器：合并后按 `Id` 索引，暴露泛型仓储接口 `Get` / `TryGet` / `All` / `Where`。 | 同上 |
| 档案管理器 | ProfileManager | profile-service 的管理器：`TryApply(spec)` 原子施加成本 / 产出（**全有或全无**）；modifier pipeline 的生效点。 | 同上 |
| 内容覆盖层 | content overlay | `user://overlay/` 下由云端下发、按 `Id` 覆盖 `res://` 基线的热更内容增量。 | 同上 |
| 内容版本 | contentVersion | `manifest.json` 携带的内容版本号；启动时与云端比对以决定是否下载增量。存档记两个：`StartContentVersion`（轮回开始，不变）/ `LastContentVersion`（每个存档点更新）。 | 同上 |
| 内容启用开关 | ContentEnabled | 内容共有字段（`bool`，默认 `true`）：线上放量开关。**只在产出侧过滤**（抽取走 `AllEnabled()`），读取侧 `Get(id)` 不过滤。 | `handoffs/2026-07-27-content-gating-offline-resilience-and-rng-persistence.md` |
| 待发队列 | pending queue | `user://cache/pending/`：断线期间未上行的变更，原子写、跨启动保留，恢复后 `FlushPending()` 补提交（先 pull，云端 `revision` 领先则丢弃）。 | 同上 |
| 修订号 | revision | push 信封携带的档案修订标识；本地基线 vs 云端的比较依据，决定离线缓冲是否被云端覆盖。 | 同上 |
| 轮回种子 | CycleSeed | `CharacterProfile.Rng` 上的 u64 根种子；具名子流按 `Hash64(CycleSeed, streamName)` 派生。 | 同上 |
| 地域 | location | 角色当前所在地点，**框定 eventOptions**。**携带三组字段**：事件类型出现概率修正（软框定）· 一组特定的 `EnemyData`（硬框定取池）· `eventCountLimit`。由 Travel 事件刷新。归属 `systems/game-progression.md`。 | `handoffs/2026-07-24-docs-restructure-class-model.md` + `handoffs/2026-08-05b-location-fields-event-count-limit-and-skip-refill-closure.md` |
| 地域图 | locationMap | location 之间连通关系的承载者：**一份全局不变的数据，三个篇章共用同一张图**，future-event-service 高频只读（启动加载一次、常驻、不写回、不进存档——存档只记当前 location 的 `Id`）。Travel 的目的地取自当前 location 的邻接集合。**对玩家不可见。** | `handoffs/2026-08-05b-location-fields-event-count-limit-and-skip-refill-closure.md` |
| 地域图鉴 | LocationCodex | 图鉴族**第六本**：已去过的地域，「去过即记」，**词条记该地域通向哪些地域（连边）**。**它是不可见的 `locationMap` 向玩家显影的唯一通道**——世界地图靠多次轮回一格一格拼出来，而非一开始就发下来；**跨轮回重建整张图是设计目标**。账号级、跨轮回持久，归 PlayerProfile。 | 同上 + `handoffs/2026-08-06c-skip-channel-removal-priority-two-tier-and-location-codex-edges.md` |
| 事件类型出现概率修正 | event type possibility modifier | location 字段：对候选池中各 `eventType` 的出现权重施加修正。**软框定**——改权重不改可及性，故不是「按地点分池」。具体取值归内容制作阶段。 | `handoffs/2026-08-05b-location-fields-event-count-limit-and-skip-refill-closure.md` |
| 地域事件容量上限 | eventCountLimit | location 字段：玩家在该地域最多经历几个事件（**只计选择进入并结算的，Travel 不计**）。**用尽 → 本批 eventOptions 收窄为仅剩 Travel**。与 `lifeSpanCost` 并列为篇章节奏的两个旋钮。 | 同上 |

## 战斗 · 卡牌类型与异能（MTG 借词第一批 · 08-04b 定名）

> 本小节的词一律来自 08-04b 的定名批次；「与 MTG 原义的出入」是借词纪律要求写清的部分。
> Source: `handoffs/2026-08-04b-mtg-loanwords-card-types-and-intent-snapshot.md`。

| 中文 | 英文 / 代码 | 与 MTG 原义的出入 |
|------|------------|-------------------|
| 开始阶段 | `start step` / `TurnStep.Start` | MTG 拆为 untap / upkeep / draw 三个 step；本作合并为一步，内含「mana 恢复 → 触发『回合开始时』→ 抽牌」，步内顺序是规则的一部分 |
| 行动阶段 | `action step` / `TurnStep.Action` | 对位 MTG 的 main phase；本作**唯一**出牌阶段，无双主阶段、无战斗步骤，故不叫 main |
| 结束阶段 | `end step` / `TurnStep.End` | MTG 的 end step 之后还有 cleanup step（弃到手牌上限）；**本作无 cleanup、无弃牌机制**，结束阶段只做「触发『回合结束时』→ 清理回合内的非永久条目」 |
| 结算 | `resolve` | 同义，**专指栈上对象的结算**；战斗收口那处已改称「收口」，一词两义就此消除 |
| 收口 | `settle` | **非 MTG 词。** 战斗打满后的胜负判定 → 奖励计算 → lifeTotal 扣减这一段 |
| 触发 | `trigger` | 本作的触发时点**全部有归属方**，**但监听方可跨归属方**；命中后压栈者一律是 StackManager |
| 静止式异能 | `static ability` | 同义。**不入栈**、载体在战场上即持续生效 |
| 启动式异能 | `activated ability` | MTG 可在任意优先权窗口启动；**本作限定为自己回合的行动阶段、栈为空时**——与出牌同窗口，**不构成交互** |
| 触发式异能 | `triggered ability` | 同义。命中后由 StackManager 压栈 |
| 永久物 | `permanent` | MTG 的 permanent = 战场上的对象（**区的成员资格**）；**本作的永久物是战场条目的子集**——战场上同时住着非永久的持续状态。永久物**永不被结束阶段清理** |
| 卡牌类型 | `CardType` | 六值枚举：`Sorcery` / `Creature` / `Enchantment` / `Item` / `Power` / `Affliction` |
| 次类型 | `card subtype` | 对位 MTG 的 subtype；本作以**稳定字符串 id + 注册表（`.tres`）**表达，内容侧可加，**不是 C# 枚举**；须能被效果的目标筛选引用 |
| 法术 | `Sorcery` | 一次性牌的通名，结算后进弃牌堆。**因无 Instant，本作的「法术」不含速度含义** |
| 灵宠 | `Creature` | **不互相攻击**（无战斗步骤、无伤害模型）；靠异能产出 / 修正道念，是「延迟回报」型的产出通道 |
| 阵法 | `Enchantment` | 合并了 MTG 的 Enchantment 与 Artifact（本作无「针对面」之分）。场上的非实体永久物，是 build 的骨架 |
| 埋伏 | 次类型 id `enchantment.ambush` | **阵法的次类型 = 炉石的「奥秘」**：面朝下布置，在**对手回合**的时点触发，触发后进弃牌堆。对手只知「有一张埋伏」不知是哪张；**同名埋伏不可重复布置**。**它不是枚举值**（次类型体系明确不用 C# 枚举），故不再有 PascalCase 形态 |
| 道具（卡牌类型） | `Item` | **非 MTG 概念。** 法宝 / 古宝在战斗内的卡牌形态；不洗进卡组、存于储物袋、不受抽牌运制约 |
| 储物袋 | `magic pack` | **非 MTG 概念，且不是战斗概念。** 角色的道具容器，存放持有的全部法宝 / 古宝，跨战斗内外存在，容量上限 **99**（≈ 不设限，仅防溢出）。战斗从中筛出 `UsableScene` 含 `InCombat` 的部分呈现为「本场可用道具」；**敌人无储物袋但同样持有道具**。**同一 `Id` 的道具可以持有多份**（面板内堆叠显示 `×N`） |
| 随身 | —（呈现名，无代码标识符） | **储物袋在战斗内那一份筛选视图的呈现名**。战斗语境里**不称「储物袋」**——储物袋是角色的容器，战斗里出现的只是它按 `UsableScene` 筛出的一个子集，且敌人没有储物袋却同样有道具。形态 = 己方战场区边缘的**角标**（与法则条分居两侧）+ 点按升起的**底部抽屉**。它**不是一个新的层级词**，只是一个界面标签 |
| 神通 / 法则（卡牌类型） | `Power` | 对位 MTG 的**徽记（emblem）**：几乎不可被交互、一旦存在就一直存在。**出入**：MTG 的徽记在指挥区且不是永久物；**本作的 `Power` 就落在战场上、是永久物**，只是带 `IsProtected` 标记不可被针对。且它不由效果产生，而是**开局按持有列表入场**；无 mana 费用（它不被「打出」） |
| 无视保护 | `IgnoresProtection` | **非 MTG 概念**（MTG 以 hexproof / indestructible 等在**被保护侧**表达；本作反向，把例外放在**攻击侧的效果**上）。效果级布尔标记：置 true 的移除 / 针对类效果可作用于受保护的战场条目（即所有 `Power`）。**是 `Power` 的唯一后门**；稀缺性与卡面明示归内容侧纪律，代码只留 `PushWarning` 软检查 |
| 业障 | `Affliction` | 对位 StS 的 Curse，但**可被打出**——打出无任何正面效果、唯一作用是把自己送进弃牌堆，故**不产生永久堵塞**。代价是 tempo；少数条目另带额外代价（mana / 削己方道念） |

## 修行事件分类（九类 · 07-24 加入 Explore / Travel；原七类见 ADR-0002）

| 中文 | 英文 / 代码 | 直观含义 |
|------|------------|----------|
| 修炼 | Practice | 比试 / 切磋——低风险战斗式历练 |
| 战斗 | Combat | 正式回合制战斗遭遇 |
| 闭关 | Research | 钻研 / 潜修 |
| 交易 | Exchange | 交易 / 商店 |
| 社交 | Social | 与 NPC / 势力的社交互动 |
| 未知 | Mystery | **元类型**：进入后才揭示为其余某一类；揭示的是一个**固定的** AdventureEvent，而非点击时临时生成 |
| 境界突破 | Finale | **篇章边界高潮**：渡劫 / 突破，独立于 Combat 的结算（07-23 加入的第七类） |
| 探索秘境 | Explore | **探索一处秘境**（07-24 加入的第八类） |
| 前往某处地点 | Travel | **地图路由选择**：刷新角色所在的 location（地域）（07-24 加入的第九类） |

> 休养 / Rest 不单列，并入 战斗 或 闭关。原七类定案见 `decisions/ADR-0002-adventure-event-taxonomy.md`；**07-24 加入 Explore / Travel 为第八、九类**（`handoffs/2026-07-24-docs-restructure-class-model.md`；ADR-0002 待补订）。
> **Mystery = 遮罩一个固定 AdventureEvent**（非点击时生成）。Source: `handoffs/2026-07-24-docs-restructure-class-model.md`。
> **境界突破 = `AdventureEvent-Finale`**（篇章边界高潮），已作为**第七类并入 ADR-0002 枚举**，独立于 Combat。Source: `handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。

## 修行阶梯（境界 · realm）

| 中文 | 英文 / 代码 | 说明 |
|------|------------|------|
| 炼气 | Qi Refining | 第一境；境内 **1 层 ~ 13 层**（全局 1–13） |
| 筑基 | Foundation Establishment | 第二境；境内 **初期 / 中期 / 后期 / 巅峰**（全局 14–17） |
| 金丹 | Golden Core | 第三境；境内 **初期 / 中期 / 后期 / 巅峰**（全局 18–21） |
| 元婴 | Nascent Soul | 第四境（终点 / 奖杯）；**仅初期**（全局 22） |
| 篇章 | Chapter | 相邻两境之间的一段攀登；一次轮回含三个篇章。篇章跨度 = 该境界的等级跨度（1→13 / 1→4 / 1→4）；**突破后等级归位为新境界的初期**。 |

> 来源：`handoffs/2026-07-13.md` + `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md`（境界内等级与全局等级序）。

## 美术与音频（art · 工作流词汇）

| 中文 | 英文 / 代码 | 含义 | 来源 |
|------|------------|------|------|
| 总美术方向 | art direction | `art/visuals/art-direction.md`：**所有 art guide 的公共约束**（基调 / 色彩 / 光照 / 构图 / 技术）。是每份 guide 的**上游**，跨资产的风格一致性由它承担。 | `handoffs/2026-08-04-art-audio-library-scaffold.md` |
| 生成指导 | art guide / audio guide | 单份资产的**结构化生成 prompt**：由 AI 依 vision + 参考素材写出，连同参考素材一并投喂生成工具（视觉为 Midjourney，音频工具待定）。可迭代，带「产出与迭代」记录。 | 同上 |
| 参考素材 | reference material | 投喂给生成工具的既有作品 / 图像 / 音频，须逐条登记**借什么 / 不借什么**。 | 同上 |
| 资产类目 | asset category | guide 的归属维度（卡面插画 / 敌人立绘 / 事件插图 / 屏幕背景 / UI 元件 / BGM / 音效…），用于与 `systems/` 的内容条目对齐。 | 同上 |

> **不是游戏内术语**，是资产生产流水线的工作词汇；不会出现在玩家可见文案或代码标识符中。
