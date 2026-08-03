# 术语表（Terminology）

> 开发中使用的专有术语事实来源：中文领域词 ↔ 英文 / 代码标识符。随开发滚动更新。
> 代码标识符沿用此处的英文 / 代码列（`csharp-godot-rules.md` 的 PascalCase 命名）。
> 提炼至：`.claude/knowledge/dictionary.md`。
>
> **借词纪律（08-02 定）：** card / deck / combat 体系将**大量借用 MTG 术语**来简化表达。**每个借入的词都要在本表登记为已定含义**——写清它在本作中指什么、与 MTG 原义有何出入，避免同一个词在两套语境间漂移；借词也不得覆盖既有的仙侠定名（mana = 法力、momentum = 道念）。清单与中文定名待逐步补全。Source: `handoffs/2026-08-02-momentum-conversion-reward-structure-and-mtg-stack.md`。
>
> **中文名不承担层级表达（08-03 定）：** `PlayerPower` / `PlayerItem` / `CharacterPower` / `CharacterItem` 的中文定名为**法则 / 古宝 / 神通 / 法宝**——四个彼此独立的仙侠词，**不共用词根**。账号级 ↔ 轮回级的对称此后**只在英文标识符上成立**（`Player*` / `Character*`）；**UI 文案不能靠中文名传达「这是账号级的」**，层级须由界面归属（元进程界面 vs 轮回内界面）承担。Source: `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md`。

## 核心结构

| 中文 | 英文 / 代码 | 含义 | 来源 |
|------|------------|------|------|
| 轮回 | cycle | 从开局到胜 / 负的一次完整游玩历程（roguelike 体裁通称 *run*，本作定名为**轮回**）。由 seed 驱动，含三个篇章，状态与历史落在一个 CharacterProfile 上；生命周期归 life-cycle-service。 | 全库术语重构 2026-07-27（`run` → `cycle`，与 life-cycle-service 同词根） |
| 修行事件 | AdventureEvent | 逐时逐刻的游玩单元；玩家从当前可用项中择一以推进轮回。 | `handoffs/2026-07-15b-taxonomy-and-checkpoint-clarifications.md` |
| 修行历程 | `pastEvent`（集合，`List<AdventureEvent>`） | 一个角色**已走过**的整段修行旅程——一条扁平的时序轨迹（含已结算与已跳过的事件）。**向前的走向不在此结构中**，由 future-event-service 每步现算的 eventOptions 决定。 | 同上 |
| 可选事件 | `EventOption`（集合，`List<EventOption> eventOptions`） | future-event-service 由 `AdventureEventData` 模板**物化**出的**定稿实例**（`sealed record`，immutable，落存档）：按 `EventId` 溯源模板、按 `InstanceId` 被引用，携带物化时置位的全部属性（含 `ifMandatory` / `eventPriority`）。**产出即定稿**，下游只读消费。 | `handoffs/2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md` + `handoffs/2026-07-27b-service-api-contracts.md` |
| 物化 | materialize | future-event-service 把 `AdventureEventData`（模板 / 参数空间）**依情境代入**（CharacterProfile + location + PlotManager 调制 + map 子流）产出定稿 `EventOption` 的过程。**唯一物化点 = future-event-service；产出 eventOptions ≡ 物化 AdventureEvent；产出即定稿、不可改写、不回查模板重算。** | `handoffs/2026-07-27b-service-api-contracts.md` |
| 实例标识 | `InstanceId` | 一次物化实例的稳定标识。同一模板（`EventId`）可在一次轮回里被物化多次，故 `pastEvent`、事件负载、跳过补位一律按 `InstanceId` 定位，**不可用 `EventId` 替代**。 | 同上 |
| 卡牌实例 | `CardInstance` | `CardData` 模板的运行时实例（手牌中的临时增益等）。与 `EventOption` 同属「内容定义 + 轮回内状态」的第二类型，区别在于它**运行态可变**；共享纪律「服务签名里传实例，不传 `Resource`」。 | 同上 |
| 操作结果 | `OpResult` / `OpResult<T>` | 统一的**业务失败**返回类型（`readonly record struct`，零堆分配）：`Success` + `OpError`（`Network` / `Auth` / `Compliance` / `Validation` / `NotFound` / `Conflict` / `Cancelled` / `Migration`）+ `Detail`。**业务失败绝不抛异常**；必需缺失才 `PushError` + `throw`。 | 同上 |
| 档案变更规格 | `ProfileChangeSpec` | 施加给 `ProfileManager.TryApply` 的声明式变更规格：`IReadOnlyList<ChangeElement>`，`ChangeElement.BaseValue` **带符号**（负 = 消耗，正 = 产出）。**取代先前的 `CostSpec` / `RewardSpec` 两个类型**——成本与产出必须落在同一事务内。`selectCost` / `skipCost` / `CombatResult.Spoils` 均为它。 | 同上 |
| 存档点原因 | `SavePointReason` | `sync-service.PushAsync` 的枚举参数（`CycleStarted` / `EventResolved` / `ChapterBoundary` / `CycleEnded` / `MetaChanged`）：驱动日志、重试策略与合并窗口。与 `PushPolicy { Debounced \| Immediate }` 配合。 | 同上 |
| RNG 子流 | `RngStream` | 具名 RNG 子流的枚举（`Map` / `Combat` / `Shop` / `Reward`）。`life-cycle-service.Stream(RngStream)` 返回 Godot 的 `RandomNumberGenerator`（自带可序列化的 `Seed` / `State`），而非 `int Next()`。 | 同上 |
| 玩家信息 | PlayerProfile | 账号级主档，跨轮回持久，持有一组 CharacterProfile 及账号级元数据。 | `handoffs/2026-07-15-adventure-event-profiles.md` |
| 角色信息 | CharacterProfile | 单次轮回 / 单个角色的状态与历史（对齐 CycleState 概念）。 | 同上 |
| 法则 | PlayerPower | 账号级 always-available 能力，带开关（默认开启）；QoL 或影响公平性的全局加强，不与角色绑定，可获取 / 失去。**中文定名 = 法则**（08-03 定，取代「玩家能力」；`power` 不再有统一中文通译，两层各自定名）。 | `handoffs/2026-07-22-online-cloud-combat-and-meta-clarifications.md` + `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md` |
| 古宝 | PlayerItem | 账号级、有使用次数限制的道具。**中文定名 = 古宝**（08-03 定，取代「玩家道具」）。 | 同上 |
| 神通 | CharacterPower | **轮回级**的角色能力，**对标账号级的 PlayerPower（法则）**（同一概念的两层，分界是生命周期）：由 CharacterProfile 持有，随轮回清理；沿用 `status` 开关、事件触发器被动修正、capability flag + modifier pipeline 两条生效通道。**可承载战斗内的触发式效果**（见「触发器」）。**中文定名 = 神通**（08-03 定，取代「角色能力」）。归 `systems/character-profile/power/`。 | `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md` + `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md` |
| 法宝 | CharacterItem | **轮回级**的角色道具，由 CharacterProfile 持有（现有写法 `List<CharacterItems>`，单复数待统一）、随轮回清理；对标账号级的 PlayerItem（古宝）。**中文定名 = 法宝**（08-03 定，取代「角色道具」）。归 `systems/character-profile/item/`。 | `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md` |
| 道念 | momentum | **计分（scoring）用的胜利点数**，**`>= 0` 的 Integer**，双方各持一份：**战斗胜负 = 道念高者胜**。**由卡牌产出、可互相削减、下限为 0**（削减是饱和减法，**在每一次结算时就截断**，溢出的削减量不结转）；**战斗开始时双方各有一个由自身等级决定的起始道念 `baseMomentum`**。**标准 Combat = 10 个回合**（双方各 5 个）后比大小；**相等 = 平局，只发 `baseReward`、不扣 lifeTotal**。道念差在胜负两侧各驱动一件事：**胜 → 奖励厚度**（换算未定），**负 → 按差值 1:1 扣 lifeTotal**。道念是战斗内运行态，战斗结束即消失，不落 CharacterProfile。归 `systems/scoring.md`。 | `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md` + `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md` + `handoffs/2026-08-02-momentum-conversion-reward-structure-and-mtg-stack.md` |
| 基础奖励 | baseReward | 一个战斗事件**不论胜负都会发放**的奖励底盘。胜 = `baseReward` + 按道念差加厚；平 = 只发 `baseReward`；负 = `baseReward`，**少数事件另夹带负向条目**（额外惩罚**包在 reward 里**，不另立惩罚结构——与 `ProfileChangeSpec` 的带符号约定自洽）。奖励**由 combat-service 计算**，写入仍由 life-cycle-service 在 `eventEnd` 一次施加。 | `handoffs/2026-08-02-momentum-conversion-reward-structure-and-mtg-stack.md` |
| 堆栈 | stack | 卡牌结算模型，**借自 MTG**：打出的牌**不立即生效**，先入栈，按**后进先出（LIFO）**依次结算——「打出」与「结算」是两个时刻。**只借结算模型，不借交互与优先权**：无 instant、栈非空时不可出牌（**对双方都成立**）、无优先权传递，故**回合是「我打完换你打」的简单交替**。**栈深由触发式能力撑起**：在栈上的牌可以触发能力，**被触发的能力也进栈**，故即便只打出一张牌栈深也可大于 1；连锁触发按 LIFO 解决，**后触发的先生效**。归 `systems/character-profile/deck/`。 | 同上 + `handoffs/2026-08-02b-stack-without-interaction-and-three-step-turn.md` |
| 回合结构 | turn structure | 一个回合固定走**三步**：**起始步 start**（回合归属方 mana 恢复至 `manaLimit` → 触发「回合开始时」→ 抽牌）→ **主阶段 main**（**唯一**出牌阶段，只有回合归属方能出牌）→ **结束步 end**（触发「回合结束时」→ 清理回合内状态）。**无战斗步骤、无双主阶段。** 步内顺序是规则的一部分；**三步是回合归属方的流程，双方不同时走**（回合开始 / 结束是有归属方的时点）。归 `systems/services/combat-service.md`。 | `handoffs/2026-08-02b-stack-without-interaction-and-three-step-turn.md` |
| 手牌上限 | hand size limit | **手牌在任何时刻都不得超过的张数上限**——是一条**恒定不变式**，不是回合末的清算：**没有时间限制，也没有必须弃牌的机制**。约束点落在会让手牌增加的时刻：**满手时抽牌抽不进（牌留在抽牌堆，本次抽牌无事发生），「加入手牌」类效果同理落空**——不抽出即弃、不销毁，故手牌上限是**纯上界**，不产生弃牌堆流量。**上限数值待定。** 归 `systems/character-profile/deck/`。 | 同上 + `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md` |
| 战场 | battlefield | **战斗的公共区**：记录**场上的全部准确数据**——哪些卡牌正在生效、有哪些持续状态、有哪些触发器在等待，以及各条目的生命周期标记（回合内 / 跨回合）。**与栈是两个区**：栈 = 等待结算的队列，战场 = 已结算并正在生效的东西；结算路径 = 打出 → 入栈 → LIFO 弹出结算 → 效果施加 →（若持续）落到战场。由 **BattlefieldManager**（combat-service 的 manager）持有。 | `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md` |
| 触发器 | trigger | 触发式效果的挂载点。**载体开放、不专属卡牌**：牌上的触发器、**场上的持续状态**、**CharacterPower（神通）** 都可能承载，清单可再增。**触发命中后被触发的能力由 StackManager 压入栈**（与载体解耦）；「谁在监听哪个时点」的注册面坐在 **battlefield** 上。已定的触发时点：「回合开始时」/「回合结束时」（有归属方的时点）。 | 同上 |
| 回合归属方 | turn owner | 当前回合轮到的一方。**只有归属方能主动出牌**，且起始步恢复的是**归属方的** mana。 | 同上 |
| —（中文定名待定） | sorcery speed | **出牌时机**，借自 MTG：只能在**自己回合的主阶段、栈为空时**打出。**本作所有牌都是 sorcery speed**——它是全局规则而非卡牌属性；`instant`（瞬间）**明确不借**。中文定名未给，见 `systems/character-profile/deck/` 的待决问题。 | 同上 |
| 经验值 | `experiencePoint` | **等级成长的累积量**，`CharacterProfile.Status` 上的字段：**每个等级各有一个升级所需的经验阈值**，AdventureEvent 的 reward **发放经验值**（而非直接给等级），累积达阈值才升一级。**任何类型的事件都可能给，失败也给**（失败给得少）。它是战斗奖励中「强制自动计入」的那一类。阈值曲线待定，归 `systems/balance.md`；等级模型见 `systems/game-progression.md`。 | 同上 |
| 起始道念 | baseMomentum | 每个**全局等级**对应的战斗起始道念（炼气 1–13 → 1..12, 15；筑基 20 / 24 / 28 / 32；金丹 45 / 55 / 65 / 75；元婴 100）。**境界鸿沟由它承载**（全局等级序基数本身连续无跳变），故等级差直接变成开局的起跑线差。可调数值，归 `systems/balance.md`。 | `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md` |
| 生命总量 | lifeTotal | **角色的生命值** —— 战斗外的耐久 / 失败惩罚承受量（**不是战斗内血量**）：战斗过程中既不消耗也不读取，只在战斗 / 修炼失败的**结算时刻**按道念差**1:1**被扣减，**通过 AdventureEvent 恢复**。**归 0 → 角色 `defeated`**（与寿元归 0 并列的第二条终结路径）。对齐 `Status.lifeTotal / lifeTotalLimit`（代码字段一并改名，`currentHealth / healthLimit` 作废）。炼气基线 10/10，无曲线。区别于寿元 lifeSpan（按事件流逝的寿命预算）。 | 同上 + `handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md` |
| 法力 | mana | **战斗内的出牌资源**（战斗内另一半是道念）。**无 mana 曲线**：战斗中**每回合开始恢复至 `manaLimit`**，而 `manaLimit` 由事件的 cost / reward 推拉（可升可降），不随境界自动成长，**不设下界护栏**。炼气基线 5/5。对齐 `Status.currentMana / manaLimit`。 | `handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md` + `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md` + `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md` |
| 道统残卷 | —（标识符待定） | 元进程的**失败侧产出**：失败累积的**不是账号级货币**，而是「下一次轮回获得新 PlayerPower」的**递增掉落概率**；**一旦获得新 PlayerPower 即重置**该概率。避免引入第二套账号级经济。归 `systems/player-profile/player-power/`。 | `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md` |
| 等级 | level | **境界内的层级**：炼气 1 层~13 层；筑基 / 金丹 各为 初期 / 中期 / 后期 / 巅峰；元婴仅初期。篇章结束突破后**一律归位为新境界的初期**（元婴亦然）。归 `systems/game-progression.md`。 | `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md` |
| 全局等级序 | global level | 跨境界连续的等级序 **1–22**（炼气 1–13 / 筑基 14–17 / 金丹 18–21 / 元婴 22），由「境界基数 + 境界内 level」合成，**境界之间不留跳变**（鸿沟由 `baseMomentum` 承载）。枚举值自带描述（`level=1` → 炼气一层，`level=14` → 筑基初期，…）。等级差比较在此序上做，不拿两个境界内的层号直接相减。 | 同上 + `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md` |
| 意图 | intent | 敌人**下一个回合全部出牌的综合描述**（**数值 = 计算后合并的最终结果**、**类别 = 主类别并行陈列**，非逐张预告；EnemyManager 内部生成，**只在玩家回合呈现、敌人回合收起**；**公布即承诺，不因玩家行动重算**）。**呈现三档**，判据 = **同阶等级差 + 越阶硬门**：**越阶（敌人境界更高）一律完全无信息**；同阶时按篇章 —— **第一篇章** `diff ≤ -3` 完整意图 / `-2 ~ 2` 仅类别 / `≥ 3` 完全无信息；**第二 · 第三篇章** `diff ≤ -2` / `-1 ~ 1` / `≥ 2`。第三档不给任何替代线索。**完整意图因此是碾压专属，「仅类别」才是常态（同级只给类别为有意为之）。** | 同上 + `handoffs/2026-08-02c-intent-threshold-inversion-and-aggregate-intent.md` |
| 探查 | `probe`（标识符暂定） | 玩家**主动付出代价换取当回合敌人意图**的效果——与被动的意图档位相对，是第二条信息通道。「能力 / 道具授予窥视意图」即其授予形式。**具体形态归卡牌 / 技能内容的横向扩展阶段，现阶段搁置。** | 同上 |
| 图鉴（族） | Codex | **账号级的知识收集面**，共**五个**：`EnemyCodex` / `CharacterPowerCodex` / `PlayerPowerCodex` / `CharacterItemCodex` / `PlayerItemCodex`。跨轮回持久、归 PlayerProfile、条目按内容 `Id` 索引、内容为**静态文案**（挂在对应 `Resource` 上），存档只记解锁状态。归 `systems/player-profile/codex/`。 | `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md` |
| 敌人图鉴 | EnemyCodex | 图鉴族之一（类 Pokédex）。只记录**静态知识**（这个敌人会做哪些事），**不记录动态意图**（它这回合做什么），故不架空越级黑箱。**遭遇即记录，不必击败**；**一次遭遇即全文案解锁**，词条含 人物背景 · 功法简介 · 运作方式 · 特点与弱点 · `EnemyTemplate` 样本卡组的关键卡牌。 | 同上 + `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md` |
| 敌人模板 | EnemyTemplate | 敌人的**静态内容数据**集合（稳定 `Id` + 图鉴文案 + 基准数值 + **样本卡组**）。**敌人等级不在模板上定死**：future-event-service 取一份模板 → 充实 / 改写 → 指派给该事件，等级是**物化产物**。与 `AdventureEventData ↔ EventOption`、`CardData ↔ CardInstance` 同属「模板 ↔ 实例」通则。 | `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md` |
| 灵玉 | jade | **轮回级软通货**（官方货币名）：随轮回存在、随轮回清理，归 CharacterProfile；主要花销在 Exchange（交易 / 商店）。区别于每回合出牌资源 mana。 | `systems/character-profile/currency.md` |
| 道心 | faith | **隐藏数值属性**（原 `faith` / 信仰即时属性，现归为隐藏）；与 煞气 / 寿元 同属驱动 AdventurePlot 的隐藏属性。 | `handoffs/2026-07-15-adventure-event-profiles.md` + 归隐藏 `handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md` |
| 煞气（点数） | malefic qi | **隐藏属性**：积累到阈值触发「煞气反噬」剧情线。 | `handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md` |
| 寿元 | lifeSpan | **隐藏属性**：角色寿命预算（**非 life**）——炼气起始 100、抵达筑基 +100、抵达金丹 +300、抵达元婴 +500（元婴为终点，该增量无玩法影响）；**剩余寿元跨篇章结转**。初始隐藏，**30% 起给定性叙事提示、10% 起给红字数值倒数**；每完成一个 AdventureEvent 按其 `lifeSpanCost` 扣减，**递减到 0 → 「大限将至」→ 角色 defeated**。 | 同上 + `handoffs/2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md` + `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md` |
| 寿元消耗 | lifeSpanCost | **成本类型 `selectCost` 的一个 element**：完成该事件对角色寿元的扣减。**内容侧以正数量值书写**（「耗 3 点」写 `3`），由 future-event-service 在**物化组装 spec 时取负**填入带符号的 `ChangeElement.BaseValue`。它是**控制篇章时长的主旋钮**（目标：**30–40 / 35–45 / 45–55 分钟**，熟练玩家口径），分档表待定。 | `handoffs/2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md` + `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md` |
| 事件类型 | eventType | AdventureEvent 的共有字段：该事件归属九类子类型中的哪一类。 | `handoffs/2026-07-25b-event-cost-fields-capability-flags-and-service-hierarchy.md` |
| 选择成本 | selectCost | AdventureEvent 的共有字段，且是一个**定制的复合成本类型**：由若干成本 element 组成（`lifeSpanCost` 为其中之一），表示选中该事件以推进轮回所需付出的代价。**代码形态 = `ProfileChangeSpec`，在物化时组装。** | 同上 + `handoffs/2026-07-27b-service-api-contracts.md` |
| 跳过成本 | skipCost | AdventureEvent 的共有字段：**跳过**该事件所需付出的代价；**与 `selectCost` 同为上述复合成本类型**（同一套 element 体系，数值取向不同）。 | 同上 |
| 是否强制 | ifMandatory | AdventureEvent 的共有字段：为真则该事件**不可跳过**（必须面对）。由 future-event-service 在产出 eventOptions 时**动态置位**；一批可以全部为真。 | 同上 + `handoffs/2026-07-26-event-priority-skip-semantics-and-hotfix-scope.md` |
| 事件优先级 | eventPriority | AdventureEvent 的共有字段：**通常为 0**（本批中可自由择一）；本批一旦出现更高优先级的事件，玩家**必须从最高优先级档中择一**，其余档次本轮被封锁。与 `ifMandatory` 分属两条约束轴（前者封锁其他选项，后者封锁跳过通道）。 | `handoffs/2026-07-26-event-priority-skip-semantics-and-hotfix-scope.md` |
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
| 地域 | location | **抽象概念**：角色当前所在地点，**框定 eventOptions**（决定下一批可能出现的修行事件池）；由 Travel 事件刷新。归属 `systems/game-progression.md`。 | `handoffs/2026-07-24-docs-restructure-class-model.md` |

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
