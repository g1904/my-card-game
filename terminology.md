# 术语表（Terminology）

> 开发中使用的专有术语事实来源：中文领域词 ↔ 英文 / 代码标识符。随开发滚动更新。
> 代码标识符沿用此处的英文 / 代码列（`csharp-godot-rules.md` 的 PascalCase 命名）。
> 提炼至：`.claude/knowledge/dictionary.md`。
>
> **借词纪律：** card / deck / combat 体系将**大量借用 MTG 术语**来简化表达。**每个借入的词都要在本表登记为已定含义**——写清它在本作中指什么、与 MTG 原义有何出入，避免同一个词在两套语境间漂移；借词也不得覆盖既有的仙侠定名（mana = 法力、momentum = 道念、PlayerPower = 法则、PlayerItem = 古宝、CharacterPower = 神通、CharacterItem = 法宝）。**第一批借词已全部定名**（见「战斗 · 卡牌类型与异能」小节）；后续新借的词照此登记。
>
> **中文名不承担层级表达：** `PlayerPower` / `PlayerItem` / `CharacterPower` / `CharacterItem` 的中文定名为**法则 / 古宝 / 神通 / 法宝**——四个彼此独立的仙侠词，**不共用词根**。账号级 ↔ 轮回级的对称此后**只在英文标识符上成立**（`Player*` / `Character*`）；**UI 文案不能靠中文名传达「这是账号级的」**，层级须由界面归属（元进程界面 vs 轮回内界面）承担。

## 核心结构

| 中文 | 英文 / 代码 | 含义 |
|------|------------|------|
| 轮回 | cycle | 从开局到胜 / 负的一次完整游玩历程（roguelike 体裁通称 *run*，本作定名为**轮回**）。由 seed 驱动，含三个篇章，状态与历史落在一个 CharacterProfile 上；生命周期归 life-cycle-service。 |
| 修行事件 | AdventureEvent | 逐时逐刻的游玩单元；玩家从当前可用项中择一以推进轮回。 |
| 修行历程 | `pastEvent`（集合，`IReadOnlyList<PastEventEntry>`） | 一个角色**已走过**的整段修行旅程——一条扁平的、**只追加**的时序轨迹。**只有一种痕迹：进入并结算**（跳过通道已移除）。**向前的走向不在此结构中**，由 future-event-service 每步现算的 eventOptions 决定。 |
| 痕迹条目 | `PastEventEntry` | `pastEvent` 的条目类型（`sealed record`，immutable，落存档）= **定稿实例快照 + 本次结算的最终账**（`AppliedChange`）。字段取舍由判据给出：**重算不出来的存，重算得出来的不存**（文本类字段一律留在模板侧）。含同批未选项轻摘要 `UnchosenOptionRef`。 |
| 结算走向 | `EventOutcome` | 痕迹上的四值枚举：`Resolved`（非战斗类正常结算）/ `CombatWon` / `CombatLost` / `Aborted`（支付 `SelectCost` 后终态判定 ① 即短路，事件未进入 resolver）。 |
| 可选事件 | `EventOption`（集合，`List<EventOption> eventOptions`） | future-event-service 由 `AdventureEventData` 模板**物化**出的**定稿实例**（`sealed record`，immutable，落存档）：按 `EventId` 溯源模板、按 `InstanceId` 被引用，携带物化时置位的全部属性（含 `eventPriority`）。**产出即定稿**，下游只读消费。 |
| 物化 | materialize | future-event-service 把 `AdventureEventData`（模板 / 参数空间）**依情境代入**（CharacterProfile + location + PlotManager 调制 + map 子流）产出定稿 `EventOption` 的过程。**唯一物化点 = future-event-service；产出 eventOptions ≡ 物化 AdventureEvent；产出即定稿、不可改写、不回查模板重算。** |
| 实例标识 | `InstanceId` | 一次物化实例的稳定标识。同一模板（`EventId`）可在一次轮回里被物化多次，故 `pastEvent`、事件负载一律按 `InstanceId` 定位，**不可用 `EventId` 替代**。 |
| 卡牌实例 | `CardInstance` | `CardData` 模板的运行时实例（手牌中的临时增益等）。与 `EventOption` 同属「内容定义 + 轮回内状态」的第二类型，区别在于它**运行态可变**；共享纪律「服务签名里传实例，不传 `Resource`」。 |
| 操作结果 | `OpResult` / `OpResult<T>` | 统一的**业务失败**返回类型（`readonly record struct`，零堆分配）：`Success` + `OpError`（`Network` / `Auth` / `Compliance` / `Validation` / `NotFound` / `Conflict` / `Cancelled` / `Migration`）+ `Detail`。**业务失败绝不抛异常**；必需缺失才 `PushError` + `throw`。 |
| 档案变更规格 | `ProfileChangeSpec` | 施加给 `ProfileManager.TryApply` 的声明式变更规格，**平级只读列表，逐条按施加语义分列**（列表数不写进承重表述，随字段族增长）：`Elements`（资源，`ChangeElement.BaseValue` **带符号**：负 = 消耗，正 = 产出；第三字段 `ApplyOp Op { Add, Set }` 缺省 `Add`，`Set` 时 `BaseValue` 是已算好的绝对值、恒不经 modifier pipeline，准入逐行配在 `ElementSpec.AllowedOps`）· `AbilityElements`（能力，按 `Id` 的集合成员操作）· `Stats`（统计计数，纯自增）· `StatusChanges`（`Status` 规则字段，绝对置值）· `DeckElements`（卡组，带层数的构筑变更与多重集增删）· `PlotElements`（剧本，按 `ArcId` 的带载荷 upsert）· `EventStateChanges`（事件态，绝对置值）· `RngElements`（RNG 子流，按子流键的双标量 upsert）· `TraceElements`（履历，序列尾部只追加）· `CodexElements`（图鉴解锁，零 `Op` 的按 `(Kind, Id)` 幂等收录）· `SettingChanges`（账号级设置，绝对置值）· `ItemElements`（道具次数，按 `(Scope, ItemId)` 选定实例后的带符号增量）· `ItemUseElements`（战斗外道具使用痕迹，序列尾部只追加，落 `CharacterProfile.pastItemUse`）。**不拆成 `CostSpec` / `RewardSpec` 两个类型**——成本与产出必须落在同一事务内。`selectCost` / `CombatResult.Spoils` 均为它；**`selectCost` 内除 `Elements` 外各列恒为空**。 |
| 状态置值 element | `StatusAssignment` | `ProfileChangeSpec.StatusChanges` 的条目：`StatusKey` + `IntValue` + `StringValue`（按 key 的声明类型取其一，另一格填缺省）。**语义是绝对置值**——赋一个已由组装方算好的值，`ProfileManager` 不做加减。承载 `CharacterProfile.Status` 上的规则字段（`CurrentLocationId` · `LocationEventCount` · 三个隐藏属性 band · `ChapterLifeSpanBudget`）。值类型与取值域逐行查封闭表 `StatusFields`；`Id` 型解析不到 → `PushError` + 整批拒绝。**恒不走 modifier pipeline。** |
| 本轮回禁用 | `DisabledAbilityEntry`（集合字段 `CharacterProfile.disabledAbility`） | 事件对能力条目施加的**轮回级抑制**：**不删除持有、不扣 `Charges`**，只让它在**进入生效面那一步被截断**（`Power` 不入场 / `Item` 不进本场可用道具 / 不进 capability 聚合与 modifier 表 / 触发器不注册）。时长三档 `DisableDuration { NextEvent, ThisChapter, ThisCycle }`（第一档管的是**下一次进入的那个事件**，因为施加只发生在 `eventEnd`）。去重键 `(CarrierKind, Scope, AbilityId)`，重复不叠加、取更长者。四类通用（法则 · 神通 · 法宝 · 古宝）。归 `systems/character-profile/_index.md`。 |
| 置换（型剥夺） | `AbilityChangeElement` 的 `Remove` + `Grant`（同一 `PairKey`） | **唯一能真正从账号 / 角色移除一条能力的通道，且必须玩家点头**：以一换一，**排除已有 · 同稀有度 · 同 `(CarrierKind, Scope)` · 先看后决 · 拒绝无代价**。候选在 `eventEnd` 之前走 `reward` 子流掷定并落决策点存档，形状与战后奖励面板同构。**只出现在 outcome / reward 侧，恒不出现在 `selectCost`。** 置换所得**继承被换出条目的 `SourceCode`**，故对残卷的 `x` 中性。 |
| 能力变更 element | `AbilityChangeElement` | `ProfileChangeSpec.AbilityElements` 的条目：`Op { Grant, Remove, Disable }` · `Kind { Power, Item }` · `Scope: AbilityScope { Character, Player }` · `AbilityId` · `Duration` · `Source` · `PairKey`。**只承载已定稿的 `Id`**（选取规则在 spec 组装前就已掷完，保证 `AppliedChange` 可重放）。 |
| 能力层级 | `AbilityScope` | `{ Character, Player }`，决定一条能力条目落在哪个持久层。**不按 Power / Item 拆成两个 scope 枚举**（值域与语义完全相同，拆开两个会逼 element 侧写一层无意义的转换）。 |
| 稀有度档 | `RarityTier` | 内容品质档 `{ Tier1..Tier5 }`，档号越高越稀有；挂 `PowerData` / `ItemData` / `CardData` / `CultivationTechniqueData`（功法整体标一个稀有度，组内各卡不各自表达），缺失 → `PushError`。**消费点清单见 `systems/common-properties.md`**。**⚠ 与战后奖励的优势档 `Tier { Narrow, Solid, Crushing }` 是两个东西**——不得复用同一枚举，也不得互相换算。 |
| 账号级统计计数 | `PlayerStatistics` | `PlayerProfile` 上的**纯读数层**具名类，首批两项 `TotalCyclesCompleted` / `TotalCyclesDefeated`。**绝不被任何规则 / 闸门 / 幂等键读取**——一个类型就是一道可见的边界（`Statistics.` 前缀让越界在 review 时一眼可见）。字段只读，唯一写入路径是 `StatDelta` 经 `TryApply`；走宽松同步口径。 |
| 存档点原因 | `SavePointReason` | `sync-service.PushAsync` 的枚举参数（`CycleStarted` / `EventResolved` / `ChapterBoundary` / `CycleEnded` / `MetaChanged` / `InventoryChanged`）：驱动日志、重试策略与合并窗口。与 `PushPolicy { Debounced \| Immediate }` 配合。**以成员名逐字序列化上行**，取值清单是两侧共同约定的契约面。 |
| RNG 子流 | `RngStream` | 具名 RNG 子流的枚举（`Map` / `Combat` / `Shop` / `Reward`）。`life-cycle-service.Stream(RngStream)` 返回 Godot 的 `RandomNumberGenerator`（自带可序列化的 `Seed` / `State`），而非 `int Next()`。 |
| 玩家信息 | PlayerProfile | 账号级主档，跨轮回持久，持有一组 CharacterProfile 及账号级元数据。 |
| 角色信息 | CharacterProfile | 单次轮回 / 单个角色的状态与历史（对齐 CycleState 概念）。 |
| 法则 | PlayerPower | 账号级 always-available 能力，带开关（默认开启）；QoL 或影响公平性的全局加强，不与角色绑定，可获取 / 失去。**中文定名 = 法则**（`power` 没有统一的中文通译，两层各自定名）。**战斗内以 `CardType.Power` 呈现**：`status == 开启` 且 `UsableScene` 含 `InCombat` 者在**开局入场**、受保护不可被针对——故除 capability flag 与 modifier pipeline 外，另有**战斗内异能**这第三条生效通道（**允许但极其稀缺**，`InCombat` 法则应 ≤ 1/5）。 |
| 古宝 | PlayerItem | 账号级、有使用次数限制的道具。**中文定名 = 古宝**。**战斗内以 `CardType.Item` 呈现**：存于**储物袋**、**不洗进卡组**、不受抽牌运制约，使用窗口与出牌同（自己回合的行动阶段、栈为空时）；**使用次数即时经 `ProfileManager.TryApply` 写 PlayerProfile**，不攒到收口。 |
| 神通 | CharacterPower | **轮回级**的角色能力，**对标账号级的 PlayerPower（法则）**（同一概念的两层，分界是生命周期）：由 CharacterProfile 持有，随轮回清理；沿用 `status` 开关、事件触发器被动修正、capability flag + modifier pipeline 两条生效通道。**可承载战斗内的触发式效果**（见「触发器」）。**中文定名 = 神通**（不共用词根，见借词纪律；旧称「角色能力」）。**战斗内以 `CardType.Power` 呈现**：`status == 开启` 且 `UsableScene` 含 `InCombat` 者在**开局入场**、作为受保护的永久物不可被针对 / 移除。归 `systems/character-profile/power/`。 |
| 法宝 | CharacterItem | **轮回级**的角色道具，由 CharacterProfile 持有（字段 `magicPack: List<CharacterItem>`，即储物袋的轮回级那一半）、随轮回清理；对标账号级的 PlayerItem（古宝）。**中文定名 = 法宝**。**战斗内以 `CardType.Item` 呈现**：存于**储物袋**、**不洗进卡组**、不受抽牌运制约，使用窗口与出牌同；消耗即时经 `ProfileManager.TryApply` 写 CharacterProfile。归 `systems/character-profile/item/`。 |
| 成就 | Achievement | 账号级、分组的成就条目，由 PlayerProfile 持有（字段 `achievement: List<Achievement>`）、跨轮回持久。玩家**只能查看进度 / 领取奖励**；奖励按**组内加权进度**分 60% / 90% 两档一次性发放，目录 80% 可见、20% 隐藏。**标识符恒单数**——与 PlayerPower / PlayerItem / CharacterPower / CharacterItem 同为单数元素类型；通则「类型名恒为单数，复数只属于集合字段名」。归 `systems/player-profile/achievement/`。 |
| 道念 | momentum | **计分（scoring）用的胜利点数**，**`>= 0` 的 Integer**，双方各持一份：**战斗胜负 = 道念高者胜**。**由卡牌产出、可互相削减、下限为 0**（削减是饱和减法，**在每一次结算时就截断**，溢出的削减量不结转）；**战斗开始时双方各有一个由自身等级决定的起始道念 `baseMomentum`**。**标准 Combat = 10 个回合**（双方各 5 个）后比大小；**相等 = 平局，只发 `baseReward`、不扣 lifeTotal**。道念差在胜负两侧各驱动一件事：**胜 → 奖励厚度**（换算未定），**负 → 按差值 1:1 扣 lifeTotal**。道念是战斗内运行态，战斗结束即消失，不落 CharacterProfile。归 `systems/scoring.md`。 |
| 基础奖励 | baseReward | 一个战斗事件**不论胜负都会发放**的奖励底盘。胜 = `baseReward` + 按道念差加厚；平 = 只发 `baseReward`；负 = `baseReward`，**少数事件另夹带负向条目**（额外惩罚**包在 reward 里**，不另立惩罚结构——与 `ProfileChangeSpec` 的带符号约定自洽）。奖励**由 combat-service 计算**，写入仍由 life-cycle-service 在 `eventEnd` 一次施加。 |
| 堆栈 | stack | 卡牌结算模型，**借自 MTG**：打出的牌**不立即生效**，先入栈，按**后进先出（LIFO）**依次结算——「打出」与「结算」是两个时刻。**只借结算模型，不借交互与优先权**：无 instant、栈非空时不可出牌（**对双方都成立**）、无优先权传递，故**回合是「我打完换你打」的简单交替**。**栈深由触发式能力撑起**：在栈上的牌可以触发能力，**被触发的能力也进栈**，故即便只打出一张牌栈深也可大于 1；连锁触发按 LIFO 解决，**后触发的先生效**。归 `systems/character-profile/deck/`。 |
| 回合结构 | turn structure | 一个回合固定走**三步**：**开始阶段 start step**（回合归属方 mana 恢复至 `manaLimit` → 触发「回合开始时」→ 抽牌）→ **行动阶段 action step**（**唯一**出牌阶段，只有回合归属方能出牌）→ **结束阶段 end step**（触发「回合结束时」→ 清理回合内的非永久条目）。**无战斗步骤、无双主阶段。** 步内顺序是规则的一部分；**三步是回合归属方的流程，双方不同时走**（回合开始 / 结束是有归属方的时点）。中文侧统一以「阶段」收尾、英文侧统一以 `step` 收尾（**不借 `main phase` 一词**）。归 `systems/services/combat-service.md`。 |
| 手牌上限 | hand size limit | **手牌在任何时刻都不得超过的张数上限**——是一条**恒定不变式**，不是回合末的清算：**没有时间限制，也没有必须弃牌的机制**。约束点落在会让手牌增加的时刻：**满手时抽牌抽不进（牌留在抽牌堆，本次抽牌无事发生），「加入手牌」类效果同理落空**——不抽出即弃、不销毁，故手牌上限是**纯上界**，不产生弃牌堆流量。**上限数值 = 7**（起手 4 + 每回合抽 2 ⇒ 第 2 回合即撞上限，是一条会真实咬合的紧约束；取值与推导见 `systems/balance.md`）。归 `systems/character-profile/deck/`。 |
| 战场 | battlefield | **战斗的公共区**：记录**场上的全部准确数据**——哪些卡牌正在生效、有哪些持续状态、有哪些触发器在等待，以及各条目的生命周期标记（回合内 / 跨回合）。**与栈是两个区**：栈 = 等待结算的队列，战场 = 已结算并正在生效的东西；结算路径 = 打出 → 入栈 → LIFO 弹出结算 → 效果施加 →（若持续）落到战场。由 **BattlefieldManager**（combat-service 的 manager）持有。**单一战场记录，不分双场区容器**——条目自带 `OwnerSide` 表示归属方，呈现层按它分区渲染。**划线判据：** 在场上生效、可被针对 / 查询、需在结束阶段清理、需进决策点存档 → **战场条目**；参战方的私有资源与牌堆（mana / 道念 / 手牌 / 卡组 / 本场可用道具）→ 归参战方 manager。**「属于谁」只是它的一个字段，不是它的住处。** |
| 战报 | combatLog | **战斗内的结算记录**：记的是**已从栈上弹出、已经发生**的事情——与 stack（等待结算的队列）、battlefield（已结算并正在生效的东西）并列为三个互不重叠的对象。**一份数据、两个视图**：**收起态**（双方回合都常驻，固定预留高度的单行）显示最新一条；**展开态**是本场全部条目按回合分组的**因果树**，条目沿 `CauseEntryId` 指向引发它的那一条，故「谁引发了谁」可读（它与栈条目的 `sourceEntryId`「载体所在的战场条目」是两件事）。**条目粒度 = 结算事件**——卡牌结算 / 触发式异能 / 疲劳扣减各占一条，**目标落空是条目上的类别值 + `FizzledSlots` 位掩码、不另立一类条目**；各类共走 combat-service 的统一广播 `CombatFeedEntry`（**它不是一个日志实体类**；条目存结构化数据与**本次结算的增量值**，翻译键在渲染期才套）。**纯呈现层、不落存档**，退出重进即从空开始；**只属 Combat，不外延到其余四类事件**——事件间的账目归 `PastEventEntry`（落存档）。归 `ux/combat-ux.md`。 |
| 触发器 | trigger | 触发式效果的挂载点。**载体开放、不专属卡牌**：牌上的触发器、**场上的持续状态**、**CharacterPower（神通）** 都可能承载，清单可再增。**触发命中后被触发的能力由 StackManager 压入栈**（与载体解耦）；「谁在监听哪个时点」的注册面坐在 **battlefield** 上。已定的触发时点：「回合开始时」/「回合结束时」（有归属方的时点）。**触发条件可跨归属方**：时点有归属方，但**监听方不必是该归属方**——可写「对手的回合开始时」「对手打出牌时」，埋伏牌靠此成立。 |
| 异能 | `AbilityData` | 挂在内容条目（卡牌 / 神通 / 法宝 / 法则 / 古宝）上的能力定义体，落为**两格 + 一条 XOR 校验**：`Effects : EffectData[]`（结算时执行的原子操作）与 `StaticModifiers : StaticModifierData[]`（不入栈的持续修正），**恰有一格非空**。**`Sorcery` 不得带任何异能**（三档异能都以「在场」为前提，而它结算后即进弃牌堆）。`ADR-0115`。归 `systems/character-profile/deck/common-properties.md`。 |
| 效果原语 | `EffectData` | 效果的第一层定义：**抽象基类 + 一个原语一个 `[GlobalClass]` 子类**，运行期按 `Type` 经 `Dictionary<Type, IEffectHandler>` 分派，**不引判别枚举**（判据：检视器可写性 · 链路类型一致性 · 加载期校验归属 · 可加性）。**首批八个原语**；**疲劳不是原语**（它是栈条目结算时的一条内建 `ModifyMomentum`）。**恒不落存档**——它是内容侧 `Resource`，与落存档的 `ChangeElement` 否决多态判据不同，故两者不矛盾。`ADR-0115`。 |
| 静止式修正定义体 | `StaticModifierData` | 与 `EffectData` **并列的第二种定义体**（`Scope` / `What : ModifierTarget` / `Layer` / `Amount`），不入栈、只在求值瞬间被读取，故不混装进原语子类树。`ModifierTarget` 首批五项、**成员序视同冻结、只能追加**；量纲取**万分比整数**，合并「同层求和 → 只乘一次 → 只取整一次」。与 Profile 侧的 `ModifierKey` 是两套 key 空间，不合并。`ADR-0115`。 |
| 触发时点 | `TimingId` / `TimingIds` | 触发器的时点标识：**点分字符串 id + 代码侧封闭常量表 `TimingIds`**（首批十个），不改 C# 枚举——点分惯例已由次类型 id 规范立为先例，加载期封闭集校验拿到的安全性与枚举等同。承载者 `TriggerConditionData`。`ADR-0115`。 |
| 效果条件 | `EffectCondition` | 挂在 `EffectData.Conditions` 上的**三个封闭谓词**，**AND 语义**、单一落点；**条件不满足 ≠ fizzle**（后者是目标落空）。**逐 element 就地求值**——「element 顺序是规则、前一条改了道念后一条读到改后的值」因此保留；代价是 AI 试算须按进入本动作前的局面求条件（已明写为例外规则）。`ADR-0115`。 |
| 卡组操作 | `DeckOperation`（`OutcomeRule.DeckOperation`） | 事件产出侧对卡组的五个 `Op`。**走池抽只对 `AddLooseCard` 开放**（`TargetId` 留空即从池抽），其余四个 `Op` 的 `TargetId` **必填非空**。取池链逐字沿用商店 `Card` 族：`AllEnabled()` → `Pool != Enemy` → 排除功法成员卡 → `CardTypeFilter` → `RarityFilter` → 按 `RarityTier` 权重表 `PickMany` 无放回；**复用 `RngStream.Reward`、物化时掷定并落存档、绝不重抽**。`ADR-0118`。归 `systems/adventure-event/common-properties.md`。 |
| 抽牌堆插入位 | `InsertPosition { Top, Bottom }` | `MoveCardEffect` 的独立一格：目的地为抽牌堆时，牌插在**顶**还是**底**。顶 / 底是同一个区的两个插入位、不是两个区，存档仍只记抽牌堆的一条 `Id` 序列。**首批只开确定性两位、不开随机位**——随机位才会使抽牌堆重新成为战斗中途的随机消耗点；「整堆 / 全部」形态**硬禁**（那是被否决的规则性重洗换个写法）。`From == To` 的禁令放宽为「且 `To != DrawPile`」⇒ **抽牌堆内重排可写**。`ADR-0119`。 |
| 敌人 AI 策略 | `EnemyAiProfileData` | 敌人的**定制**出牌策略：一条独立可复用 `Resource`（`Id` 形如 `enemy_ai.<snake_case_slug>`），`EnemyData.AiProfile` 是对它的**直接类型引用**，**可空 = 走通用兜底**。profile **只列要覆写的 `AiWeight{Term, Value}`**，未列项取兜底默认值；不挂 `Rarity`、**profile 内无第二类结构位**。**只给权重不给代码**——它是兜底在同一搜索空间内的一次重新加权。`ADR-0113`。归 `systems/enemies/`。 |
| AI 评分项 | `AiTerm` / `AiWeightVector` | 兜底 AI 的加权效用评分项（**十项**）与其定长权重向量。兜底算法 = **单层（1-ply）加权效用评分 + 确定性 argmax**，`score(EndTurn) ≡ 0` 为绝对零点、决策粒度逐张、**全流程零随机零记忆**（平手取确定性字典序，`ChooseAction` 是 `static` 纯函数，`ActiveCombat` 一格不加）。`AiWeightVector` 是**加载期的展开产物、不是内容形态**（内容侧写稀疏的 `CombatRulesData.AiFallbackWeights`）。`Value` 钳在 `[AiWeightMin, AiWeightMax]`，越界 `PushError` + 抛。`ADR-0113`。 |
| 重试上限载体 | `ChapterRetryLimitsData` | 篇章重试上限的两档表（`Chapter1/2/3` 具名字段，`-1` = 无限），`Resource, ISingletonContent`，经 `Content.Single<T>()` 取、调用方不写 `Id` 字面量。**上限判定读既有的 `PlayerEntitlement`**——`profile-service.HasPremiumBundle`（`=> Entitlement.BundleGrantOrdinal > 0`）**选行**，**不新增任何存档结构**（不做 `CapabilityFlag`、不做 modifier、不在 `PlayerEntitlement` 上开派生字段）。`ADR-0117`。归 `systems/balance.md`。 |
| 道具使用痕迹 | `ItemUseEntry`（集合字段 `CharacterProfile.pastItemUse`） | **战斗外**道具使用的痕迹条目，与 `pastEvent` 平级的第二条**只追加**序列。它承接发生在事件之外的那些使用——那一刻没有 `PastEventEntry` 可挂，而这一笔重算不出来、又有消费方（角色履历的寿元曲线、「这段回升是哪来的」这类诊断）。唯一写入路径是 `ProfileChangeSpec.ItemUseElements` 经 `TryApply`，与它记录的那次变更**同批同事务** ⇒ 不存在「扣了次数但痕迹没落下」的中间态；`activeEvent != null` 时不写（那一次账已由事件的 `AppliedChange` 承载）。`ADR-0122`。归 `systems/character-profile/_index.md`。 |
| 回合归属方 | turn owner | 当前回合轮到的一方。**只有归属方能主动出牌**，且起始步恢复的是**归属方的** mana。 |
| 疲劳 | fatigue | **抽牌堆已空时仍尝试抽牌的代价：每张 −1 道念**（一次抽 N 张即 −N，下限 0 照常截断）。前提是**本作的抽牌堆不重洗**——弃牌堆不回流，一场战斗内只在参战方组装时初洗一次。**它是道念的第二条削减通道**（另一条是卡牌）。**它入栈**——以一条栈条目结算，与触发式异能同形，**可被监听、可被响应，其扣减量可被削减至 0**（扣减量与其余数值同经求值管线，故「疲劳时发动」的埋伏、「免疫下一次疲劳」的法宝都成立）；疲劳被削减或推后不会让对局不终止，因为 `EncounterSpec.TurnLimit` 已为双方合计回合数封顶。**不产生 `ActionResult`**（它不是玩家动作），但照常广播一条战报条目。**与满手抽不进互不触发**：牌堆空 → 疲劳；牌堆非空但满手 → 无事发生、不扣道念。归 `systems/scoring.md`、`systems/character-profile/deck/`。 |
| 先手方 | `FirstSide` | 战斗中先走回合的一方，**由 `EncounterSpec.FirstSide`（可空）承载**：剧情需要时由 future-event-service 物化写入，**`null` 则由 combat 子流掷**。与「**不设先后手抽牌差**」并行不悖——后者说不做补偿（打满回合比总量，先手 tempo 优势不存在），前者说谁先动。归 `systems/services/combat-service.md`。 |
| 出牌时机（唯一） | —（无借词） | 一张牌只能在**自己回合的行动阶段、且栈为空时**打出。这是**全局规则，不是卡牌属性**——本作不存在第二种出牌时机；**启动式异能与道具的使用窗口与之完全相同**。`instant`（瞬间）**明确不借**；**`sorcery speed` 亦不借**（与之相对的 `instant speed` 不存在，单一取值的维度不是维度，借它会制造「本作有出牌时机之分」的错觉）。 |
| 经验值 | `experiencePoint` | **等级成长的累积量**，`CharacterProfile.Status` 上的字段：**每个等级各有一个升级所需的经验阈值**，AdventureEvent 的 reward **发放经验值**（而非直接给等级），累积达阈值才升一级。**任何类型的事件都可能给，失败也给**（失败给得少）。它是战斗奖励中「强制自动计入」的那一类。阈值曲线待定，归 `systems/balance.md`；等级模型见 `systems/game-progression.md`。 |
| 起始道念 | baseMomentum | 每个**全局等级**对应的战斗起始道念（炼气 1–13 → 1..12, 15；筑基 20 / 24 / 28 / 32；金丹 45 / 55 / 65 / 75；元婴 100）。**境界鸿沟由它承载**（全局等级序基数本身连续无跳变），故等级差直接变成开局的起跑线差。可调数值，归 `systems/balance.md`。 |
| 生命总量 | lifeTotal | **角色的生命值** —— 战斗外的耐久 / 失败惩罚承受量（**不是战斗内血量**）：战斗过程中既不消耗也不读取，只在战斗 / 修炼失败的**结算时刻**按道念差**1:1**被扣减，**通过 AdventureEvent 恢复**。**归 0 → 角色 `defeated`**（与寿元归 0 并列的第二条终结路径）。对齐 `Status.lifeTotal` —— **只有这一个字段：`lifeTotalLimit` 概念整体删除，没有上限字段、没有上限截断**（也不写成 `currentHealth / healthLimit`）。炼气基线 **10**（进入更高境界时一次性跃升到 25 / 40），此后完全由事件 reward / cost 与战斗失败推拉。区别于寿元 lifeSpan（按事件流逝的寿命预算）。 |
| 法力 | mana | **战斗内的出牌资源**（战斗内另一半是道念）。**无 mana 曲线**：战斗中**每回合开始恢复至 `manaLimit`**，而 `manaLimit` 由事件的 cost / reward 推拉（可升可降），不随境界自动成长，**不设下界护栏**。炼气基线 5/5。对齐 `Status.currentMana / manaLimit`。 |
| 道统残卷 | PlayerPowerFragment | 元进程的**失败侧产出**：累积的**不是账号级货币**，而是获得新 PlayerPower 的**递增掉落概率**。**三个时刻全部落在 Finale（天劫）上**——**Finale 失败累积、Finale 通过掷骰、在该 Finale 的 eventReward 界面即时发放**；掷中并授予后概率重置为新档地板。上限 / 基础概率 / 适格篇章按 **`x` = 账号已拥有且 `SourceCode == Source.FinaleWin` 的法则数**分档（**只数「靠渡劫拿到的」**，礼包 / 成就奖励得来的不计 ⇒ **礼包与残卷完全解耦**）。落 `PlayerProfile` 上的同名具名小类（5 个字段），**不并入账号级统计计数**。避免引入第二套账号级经济。归 `systems/player-profile/player-power/`。 |
| 授予来源 | `SourceCode` / `Source` | **四类持有条目（法则 / 古宝 / 神通 / 法宝）的共有字段**：记录该条目**是被哪条渠道给到玩家的**。字段名 `SourceCode`，类型是枚举 **`Source`**——成员带**稳定整数 code**（存档 / 上行只序列化 code，重命名成员不破坏存档，已删 code 永不复用）与**展示 value**（可本地化、不落存档）。**落在持有条目上，不落在 `PowerData` / `ItemData` 上**（同一条内容可由不同渠道获得）；写入时刻 = 授予时刻、此后不变。**成员封闭三值**：`FinaleWin` · `PremiumBundle` · `AchievementReward`（+ 兜底 `Unknown = 0`，不是一条途径）。**置换所得继承被换出条目的来源**（关死「用置换刷回高掉率」的通道）。**唯一消费点是道统残卷的 `x`**——不对玩家可见、不进图鉴、不参与其他判定，是一个纯规则字段；授予 element 强制携带来源。归 `systems/common-properties.md`。 |
| 渡劫成功序号 | `FinaleWinOrdinal` | 账号级 **Finale 通过序号**，`PlayerPowerFragment` 上的 `int`：只在 **Finale 通过**（道念差 `>= 0`）时 +1，失败不自增，单调递增、不清零，**同时是道统残卷掷骰的幂等键**。**它不是通关数统计**——统计侧的「通关」= 完成整个轮回（`TotalCyclesCompleted`），两个数在任何账号上都不相等；「渡劫成功了几次」的展示**直读本字段**，统计层不另设 Finale 通过数。它属**规则字段层**（严格同步 · 后端可复算），命名硬约定：后缀 `Ordinal` 保留给规则序号 / 幂等键，统计计数层禁用。归 `systems/player-profile/`。 |
| 账号级统计计数 | `Total...` / `...Count` | `PlayerProfile` 上的一族**纯读数**（首批含篇章重试的跨角色累计、`TotalCyclesCompleted`），与 `Achievement` 相邻但不同——**成就是有奖励的里程碑，统计计数只被 UI 读来看**。**绝不被任何规则读取**，故走宽松同步口径（被篡改无玩法后果）。与规则字段层的分层判据、合并判据与命名约定见 `systems/player-profile/_index.md`。 |
| 角色（模板） | CharacterData | **有身份的角色模板**（内容条目），区别于 `CharacterProfile`（某一次轮回的角色状态）。**开局随机分配一个角色**；每个角色**自带一个神通与两门绑定功法**，且**每一局都相同**——角色因此是可辨认的身份，跨轮回的熟悉感由此产生。归 `systems/character-profile/`。 |
| 功法 | CultivationTechnique | **卡组的构筑单位**：一组**必须整组入组**的卡牌（一张或多张），卡组由若干功法构成、数量不限。带**层数 `TechniqueTier`**；**层数提升 = 该组牌被整组替换为更强的一版**（每层一整套卡牌定义），不是数值变大、也不是追加新卡。**内容形态 = 轻量 header 条目持每层的卡牌 `Id` 列表**——每张卡各自是独立的内容条目，卡牌侧不带功法标记；一张卡可被多门功法引用。**功法不是卡组的完全划分**——业障与单卡奖励作为**游离散牌**照常进入卡组。**战斗内不感知功法**（组装时已展开为卡牌集合）；**存档存「功法 `Id` + 层数」而非展开后的牌**。每个角色**绑定两门功法**，其余靠 adventureEvent 升阶 / 弃置 / 学新，**弃置不设限（绑定的也能弃）**。**敌我共用同一 `CultivationTechniqueData` 类型与同一注册表**——敌方样本卡组同样由功法 + 层数展开（外加游离散牌）。带必填的 `Pool`（无默认，缺失 `PushError`；定义与两侧过滤语义见 `systems/character-profile/deck/_index.md` 的卡池划分一节）。归 `systems/character-profile/deck/`。 |
| 层数 | `TechniqueTier` | **功法的钻研程度**，与角色的 `level` 是两个量、**刻意不共用「等级」一词**——后者是境界内层级（承重字段，见下行）。UI 与文档中两者必须一眼可分。**敌人侧的层数在 `EnemyData` 上逐条编排为固定值，不随赋级浮动**；`EnemyLevelRange` 与层数不建立机械对应关系。上限字段 `MaxTier` 挂 `CultivationTechniqueData`。归 `systems/character-profile/deck/`。 |
| 等级 | level | **境界内的层级**：炼气 1 层~13 层；筑基 / 金丹 各为 初期 / 中期 / 后期 / 巅峰；元婴仅初期。篇章结束突破后**一律归位为新境界的初期**（元婴亦然）。**与功法的「层数 `TechniqueTier`」是两个量，不得混用。** 归 `systems/game-progression.md`。 |
| 赋级带 | `EnemyLevelRange`（容器 `EnemyLevelingData`） | 敌人物化赋级的合法区间：相对角色当前等级的对称闭区间 `[L−2, L+2]`（三章统一，在全局序 1–22 上截断）**加上带内逐档的分布权重**——边界与权重同住一行，权重的支撑集就是带宽。三章各一行具名字段，住在平衡资源里、随内容 overlay 可调；服务侧只读「当前篇章的带」这一个概念。**代码标识符刻意不写成 `LevelBand`**——`Band` 在本库已被隐藏属性档 / 寿元档占用（`HiddenStatBandData` · `BandIndex` · `PlotTrigger.HiddenStatBand`），两个档位概念同页两义。归 `systems/balance.md`。 |
| 全局等级序 | global level | 跨境界连续的等级序 **1–22**（炼气 1–13 / 筑基 14–17 / 金丹 18–21 / 元婴 22），由「境界基数 + 境界内 level」合成，**境界之间不留跳变**（鸿沟由 `baseMomentum` 承载）。枚举值自带描述（`level=1` → 炼气一层，`level=14` → 筑基初期，…）。等级差比较在此序上做，不拿两个境界内的层号直接相减。 |
| 图鉴（族） | Codex | **账号级的知识收集面**，共**七个**：`EnemyCodex` / `CharacterPowerCodex` / `PlayerPowerCodex` / `CharacterItemCodex` / `PlayerItemCodex` / `LocationCodex` / `TechniqueCodex`。跨轮回持久、归 PlayerProfile、条目按内容 `Id` 索引、内容为**静态文案**（挂在对应 `Resource` 上），存档只记解锁状态。归 `systems/player-profile/codex/`。 |
| 敌人图鉴 | EnemyCodex | 图鉴族之一（类 Pokédex）。只记录**静态知识**（这个敌人会做哪些事），**不记录动态情报**（它这回合做什么）——分工是「事前知识 vs 事中情报」。**敌人的行动不作事前预告，故本图鉴是事前知识的主通道。****遭遇即记录，不必击败**；**一次遭遇即全文案解锁**，词条含 人物背景 · 功法简介 · 运作方式 · 特点与弱点 · `EnemyData` 样本卡组的关键卡牌。**词条②「功法简介」指向该敌人实际使用的功法条目**（`CultivationTechnique`）：挂一个单数、必填的「主功法」引用字段（只带 `Id`，须 ∈ 该敌人的功法列表）；**手写正文只写路数、不写功法名**，名字由引用字段在呈现层渲染。 |
| 功法图鉴 | TechniqueCodex | 图鉴族之一：已接触过的功法（`CultivationTechnique`），条目按功法 `Id` 索引。**解锁有两条通道**：玩家自己习得（进入持有列表），以及**收录一个敌人时连带收录该敌人功法引用列表里的全部功法**。**词条 = 功法名 / 描述 / `Rarity` / 路数概括 + 可选 `CodexFlavor`，不列卡牌清单**——列出卡表会让玩家由敌人词条的主功法引用反查出敌人完整卡组，那是事中情报；卡牌列表只在玩家自己持有该功法时由构筑界面提供。`Pool == Enemy` 的**敌方专用功法照常收录**，「敌方专属」是呈现层按 `Pool` 现算的标注、**不落存档**。标识符：`CodexKind.Technique` · 存档字段 `techniqueCodex`。归 `systems/player-profile/codex/`。 |
| 敌人模板 | EnemyData | 敌人的**静态内容数据**集合（稳定 `Id` + 图鉴文案 + 基准数值 + **功法引用列表 `TechniqueRef` + 游离散牌 `Id` 列表** + `KeyCardIds` + 图鉴词条②的主功法引用 + 可空的定制出牌策略 + `EncounterScopes` + `ChapterScope` + `PoolScope`；字段面见 `systems/enemies/`）。**样本卡组不再是直接的卡牌列表**，而是功法展开产物 ∪ 散牌，与玩家侧同构。**敌人等级不在模板上定死**：future-event-service 取一份模板 → 充实 / 改写 → 指派给该事件，等级是**物化产物**。与 `AdventureEventData ↔ EventOption`、`CardData ↔ CardInstance` 同属「模板 ↔ 实例」通则。**标识符统一为 `EnemyData`**（`XxxData` 是全库内容层的命名族），中文领域词保留「敌人模板」。归 `systems/enemies/`。 |
| 敌人实例 | EnemyInstance | 物化后的**定稿敌人**（`InstanceId` / `EnemyId` / `Level` / `DeckCardIds` / `ItemIds` / `PowerIds`）。性质**对齐 `EventOption` 而非 `CardInstance`**：产出即冻结、不可变、**嵌在 `EventOption` 上随批次落存档**、下游只读消费。**战斗内的敌人运行态**（道念 / 手牌 / 卡组状态 / 已用道具 / `Power` 计数器）由 **EnemyManager 持有**，不进 `EnemyInstance`、也不另立类型。**本作不存在多敌人场景**，故承载字段一律写单数。 |
| 灵石 | spiritStone | **轮回级基础货币**（软通货，官方货币名）：随轮回存在、随轮回清理，归 CharacterProfile；主要花销在 Exchange（交易 / 商店）。区别于每回合出牌资源 mana。与仙玉**不可兑换**。 |
| 仙玉 | immortalJade | **轮回级高阶货币**：同样随轮回存在、随轮回清理，归 CharacterProfile。获取 = **稀有 AdventureEvent 产出**；花销 = **高阶 Exchange 商品**。「高阶」由稀有度与价格量级表达，不由新机制表达；与灵石**不可兑换**。 |
| 道心 | faith | **隐藏数值属性**（原 `faith` / 信仰即时属性，现归为隐藏）；与 煞气 / 寿元 同属驱动 AdventurePlot 的隐藏属性。 |
| 煞气（点数） | Bloodlust | **隐藏属性**：积累到阈值触发「煞气反噬」剧情线。 |
| 寿元 | lifeSpan | **隐藏属性**：角色寿命预算（**非 life**）——炼气起始 100、抵达筑基 +100、抵达金丹 +300、抵达元婴 +500（元婴为终点，该增量无玩法影响）；**剩余寿元跨篇章结转**。初始隐藏，**30% 起给定性叙事提示、10% 起给红字数值倒数**；每完成一个 AdventureEvent 按其 `lifeSpanCost` 扣减，**递减到 0 → 「大限将至」→ 角色 defeated**。 |
| 寿元消耗 | lifeSpanCost | **成本类型 `selectCost` 的一个 element**：完成该事件对角色寿元的扣减。**内容侧以正数量值书写**（「耗 3 点」写 `3`），由 future-event-service 在**物化组装 spec 时取负**填入带符号的 `ChangeElement.BaseValue`。它是**控制篇章时长的主旋钮**（目标：**30–40 / 35–45 / 45–55 分钟**，熟练玩家口径），分档表待定。 |
| 事件类型 | eventType | AdventureEvent 的共有字段（**五值**）：该事件归属 Combat / Exchange / Research / Explore / Travel 中的哪一类。 |
| 选择成本 | selectCost | AdventureEvent 的共有字段，且是一个**定制的复合成本类型**：由若干成本 element 组成（`lifeSpanCost` 为其中之一），表示选中该事件以推进轮回所需付出的代价。**代码形态 = `ProfileChangeSpec`，在物化时组装。** **支付它是无条件的可推进行为**——不因「付不起」被拒绝，支付后做状态判定，判负则进失败流程。 |
| 事件优先级 | eventPriority | AdventureEvent 的共有字段，**取值域两档：`0`**（常态，本批自由择一）与 **`1`**（有效可选集收窄为该档，其余本轮被封锁）。**只由 future-event-service 在物化时置位，PlotManager 不得改变。** 它是**唯一**约束玩家选择权的字段（跳过通道与 `ifMandatory` 已移除）。 |
| 能力标记 | `CapabilityFlag` | 能力条目授予的具名布尔标记（如「显示隐藏属性」）。载体 = **单一扁平枚举**，不分区、不加前缀、落地 `HashSet<CapabilityFlag>` 不加 `[Flags]`。**注册面两层共用**——`profile-service.CapabilityManager` 同时遍历 `PlayerProfile.playerPower` 与当前角色的 `CharacterProfile.characterPower`，经同三条与门聚合成同一份**生效能力集**，消费侧单点查询 `Has(flag)` + 订阅 `CapabilitiesChanged`（`ItemData` 两类不参与聚合；无当前角色时只聚合账号级、不告警）。**叠加 = 集合并且幂等**，**冲突在结构上关死**：全部 flag 恒为增益向 ⇒ 不设优先级 / 声明序 / 裁决表。命名 = 动词 + 宾语、动词取自封闭三词表 `Reveal` / `Show` / `Unlock`，**禁否定式**（`Hide*` · `No*` · `Disable*` · `Suppress*` · `Prevent*`），配 `#if DEBUG` 反射断言。`ADR-0116`。 |
| 修正管线 | modifier pipeline | 能力条目注册的**具名数值修正**（`lifeSpanCost`、商店价格等）的统一施加入口 `ApplyModifier(key, baseValue)`；**各消费层不散落条件判断**，一个 `ModifierKey` 只一个施加点。条目形态 `ModifierEntry(Key, Op, int Value)`，`ModifierOp { Add, Scale }`、`Scale` 取**万分比整数**（禁 `float`）；**合并算法 = 同层求和 → 只乘一次 → 只取整一次**，外加两条钳制（`scale` 钳 `[0, ∞)`；结果与 `baseValue` 同号或为 0）⇒ **结果与顺序无关、不设优先级**。注册面与 flag 同为两层共用。与战斗内的 `ModifierTarget` 是两套 key 空间、**不合并**（量纲与合并算法逐字相同）。`ADR-0116`。 |
| 展示模型 | ViewModel | 呈现期由 `Data + 运行时状态` 组装的展示对象；**不落存档、不进云端负载**，是「服务 → 屏幕」的数据形态契约。 |
| 可选事件集 | eventOptions | 一组当前可选的 `AdventureEvent`，玩家从中择一以推进轮回；由 future-event-service 依当前 CharacterProfile 产出、每个事件后重算。 |
| 境界突破 · 高潮 | Combat（`combatTier = Finale`） | 篇章边界的境界突破事件；**不是独立的 `eventType`，而是 Combat 的最重一档遭遇**（ADR-0002）。 |
| 修行剧情（体系） | AdventurePlot | 隐藏剧本层的总称：由分支可能性构成、在背景中运行、**调制 future-event-service 产出的 eventOptions**；可像 DnD 那样让玩家选分支。下含 Story / Chapter / SideChapter / SideStory 四级。由 PlotManager 提供 API。 |
| 主线剧本 | AdventurePlot-Story | 贯穿**三大篇章**相连的**大剧本**（一条角色的完整主线故事）。 |
| 篇章剧本 | AdventurePlot-Chapter | **单个篇章**对应的剧本单元（一个 Story 含三个 Chapter）。 |
| 支线（篇章内） | AdventurePlot-SideChapter | 在**单个 Chapter 内**穿插的小型支线剧本。 |
| 支线（跨篇章） | AdventurePlot-SideStory | **跨篇章**穿插的支线剧本。 |
| 剧情节点 | AdventurePlot key points | Character 上记录的 AdventurePlot **关键节点 / 进度锚点**。剧本正文与分支**不落存档**，而是作为**本地内容条目**经 ContentRegistry 按 `Id` 读取；key point **必须可独立解析、其剧本节点缺失时可安全跳过**（悬空 → `PushWarning` + 叙事降级、不阻塞轮回）。 |
| 服务 | service | **进程内模块单例**（**不是**微服务：同一二进制、同一进程、直接方法调用）。**边界单元**，判据三选一：① 自有状态机 / 长流程 ② 事务性跨字段一致写 ③ 外部 I/O 边界。以 autoload 存在，彼此不互相读写字段。 |
| 管理器 | manager | **第二级抽象**：服务内部的职能组件（普通 C# 对象，非 `Node`）；共享宿主服务的事务边界与生命周期，**不被跨服务直接调用**。 |
| 模块 | module | **第三级抽象**：manager 内部的组件。命名后缀即层级声明（例：`DeckModule` —— 卡组由 `CharacterManager` / `EnemyManager` 各自持有、每参战方一份）。 |
| 处理器 | processor | **第四级抽象**（名字先定，目前无实例）。 |
| 处理器件 | handler | **第五级抽象**（名字先定，目前无实例）。 |
| 后端 | backend | 客户端之外的**唯一真实进程边界**：账号鉴权 · 档案存储 · 剧本下发 · 内容分发。另一套代码库，不在本项目内。 |
| 编排顶点 | game-progression | 屏幕流程编排层（**不是服务**）：串联核心循环 `ComputeEventOptions → 呈现 → 选择 → AdvanceEvent → 重算`。 |
| 账号服务 | account-service | 服务：登录渠道、token / 会话、合规（AuthManager、ComplianceManager）。 |
| 内容服务 | content-service | 服务：`res://` 基线 + `user://overlay/` 热更的合并与按 `Id` 索引；**唯一内容读取入口**（ContentRegistry、ContentUpdateManager）。 |
| 同步服务 | sync-service | 服务：档案 Pull / Push、本地原子写、schema 迁移（ProfileSyncManager、LocalCacheManager、MigrationManager）。 |
| 档案服务 | profile-service | 服务：`PlayerProfile` 与 `CharacterProfile` 的**唯一写入面**；capability 聚合；成就（ProfileManager、CapabilityManager、AchievementManager）。 |
| 生命周期服务 | life-cycle-service | 服务：轮回生命周期（开始 seed、推进、胜/负、清理、篇章继承、状态机、重试）。（CycleStateManager、ChapterManager、SeedManager） |
| 未来事件服务 | future-event-service | 服务：依当前 CharacterProfile 产出 eventOptions，每个事件后重算；**eventOptions 唯一出口**。（EventOptionManager、PlotManager） |
| 隐藏剧本管理器 | PlotManager | **管理器，隶属 future-event-service**：隐藏属性驱动、按 key points 从 ContentRegistry 解析本地剧本节点、eventOptions 调制、DnD 式选分支。**纯本地，永不跨进程边界**。 |
| 战斗服务 | combat-service | 服务：**定长回合循环**（回合数与胜负判据是 `EncounterSpec` 的遭遇参数，10 回合 / 「道念高者胜」是 `Standard` 档取值）、抽/弃（**不重洗**，抽空即疲劳）、**双方道念与胜负判定**、敌人 AI（**不作任何事前预告**——意图机制已整条移除）；**`combatTier` 三档共用同一套代码**。（TurnManager、CharacterManager、EnemyManager、**BattlefieldManager**、**StackManager**；`DeckModule` 为第三级组件，每个 character / enemy 一份） |
| 付费礼包 | premium bundle | 唯一已陈述的付费点：购买后给予**随机 1 个 PlayerPower + 随机 2 个 PlayerItem**，并把**第二篇章重试上限 3 → 9、第三篇章 1 → 3**（第一篇章本就无限）。使 ADR-0004 的重试上限从常量变为**基线值**。归 `systems/monetization.md`。 |
| 内容注册表 | ContentRegistry | content-service 的管理器：合并后按 `Id` 索引，暴露泛型仓储接口 `Get` / `TryGet` / `AllEnabled` / `AllIncludingDisabled`。**没有中性名 `All()`**（已删除，写下即编译失败）——抽取一律走 `AllEnabled()`。 |
| 档案管理器 | ProfileManager | profile-service 的管理器：`TryApply(spec)` 原子施加成本 / 产出（**全有或全无**）；modifier pipeline 的生效点。 |
| 内容覆盖层 | content overlay | `user://overlay/` 下由云端下发、按 `Id` 覆盖 `res://` 基线的热更内容增量。 |
| 内容版本 | contentVersion | `manifest.json` 携带的内容版本号；启动时与云端比对以决定是否下载增量。存档记两个：`StartContentVersion`（轮回开始，不变）/ `LastContentVersion`（每个存档点更新）。 |
| 内容启用开关 | ContentEnabled | 内容共有字段（`bool`，默认 `true`）：线上放量开关。**只在产出侧过滤**（抽取走 `AllEnabled()`），读取侧 `Get(id)` 不过滤。 |
| 待发队列 | pending queue | `user://cache/pending/`：断线期间未上行的变更，原子写、跨启动保留，恢复后 `FlushPending()` 补提交（先 pull，云端 `revision` 领先则丢弃）。 |
| 修订号 | revision | push 信封携带的档案修订标识；本地基线 vs 云端的比较依据，决定离线缓冲是否被云端覆盖。 |
| 轮回种子 | CycleSeed | `CharacterProfile.Rng` 上的 u64 根种子；具名子流按 `Hash64(CycleSeed, streamName)` 派生。 |
| 地域 | location · `LocationData` | 角色当前所在地点，**框定 eventOptions**。**携带两组字段**：事件类型出现概率修正（软框定）· `eventCountLimit`（计数闸门）。**不持敌人清单**——某地域会出哪些敌人由 `EnemyData.PoolScope` 一侧表达。由 Travel 事件刷新。载体为 `[GlobalClass] LocationData : Resource`，`Id` 形如 `location.bamboo_sea`；**平坦集合，无层级分组**；**恒启用**（结构性查表类）。归属 `systems/game-progression.md`。 |
| 地域图 | locationMap · `LocationMapData` | location 之间连通关系的承载者：**单份全局唯一的无向邻接表资源**（边为 `LocationEdgeData`，`A-B` 只写一条），**恒启用**；**一份全局不变的数据，三个篇章共用同一张图**，future-event-service 高频只读（启动加载一次、常驻、不写回、不进存档——存档只记当前 location 的 `Id`）。Travel 的目的地取自当前 location 的邻接集合。**对玩家不可见。** |
| 地域图鉴 | LocationCodex | 图鉴族之一：已去过的地域，「去过即记」，**词条记该地域通向哪些地域（连边）**。**它是不可见的 `locationMap` 向玩家显影的唯一通道**——世界地图靠多次轮回一格一格拼出来，而非一开始就发下来；**跨轮回重建整张图是设计目标**。账号级、跨轮回持久，归 PlayerProfile。 |
| 事件类型出现概率修正 | event type possibility modifier | location 字段：对候选池中各 `eventType` 的出现权重施加修正。**软框定**——改权重不改可及性，故不是「按地点分池」。具体取值归内容制作阶段。 |
| 地域事件容量上限 | eventCountLimit | location 字段：玩家在该地域最多经历几个事件（**只计选择进入并结算的，Travel 不计**）。**用尽 → 本批 eventOptions 收窄为仅剩 Travel**。与 `lifeSpanCost` 并列为篇章节奏的两个旋钮。 |

## 战斗 · 卡牌类型与异能（MTG 借词第一批）

> 「与 MTG 原义的出入」是借词纪律要求写清的部分。
>

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
| 卡牌类型 | `CardType` | 五值枚举：`Sorcery` / `Enchantment` / `Item` / `Power` / `Affliction` |
| 次类型 | `card subtype` | 对位 MTG 的 subtype；本作以**稳定字符串 id + 注册表（`.tres`）**表达，内容侧可加，**不是 C# 枚举**；须能被效果的目标筛选引用。**当前清单已归零，机制原样保留**——唯一存活条目是埋伏 `enchantment.ambush`（见下）；重建按准入判据（≥3 条目共享 + ≥1 处筛选引用）。**「功法」一词已被 `CultivationTechnique` 占用，不得再命名任何次类型**，`power.technique` 亦不得复用 |
| 法术 | `Sorcery` | 一次性牌的通名，结算后进弃牌堆。**因无 Instant，本作的「法术」不含速度含义** |
| 阵法 | `Enchantment` | 合并了 MTG 的 Enchantment 与 Artifact（本作无「针对面」之分）。场上永久物的唯一卡组来源，是 build 的骨架 |
| 埋伏 | 次类型 id `enchantment.ambush` | **阵法的次类型 = 炉石的「奥秘」**：面朝下布置，在**对手回合**的时点触发，触发后进弃牌堆。对手只知「有一张埋伏」不知是哪张；**同名埋伏不可重复布置**。**它不是枚举值**（次类型体系明确不用 C# 枚举），故不再有 PascalCase 形态 |
| 道具（卡牌类型） | `Item` | **非 MTG 概念。** 法宝 / 古宝在战斗内的卡牌形态；不洗进卡组、存于储物袋、不受抽牌运制约 |
| 储物袋 | `magic pack` / `CharacterProfile.magicPack` | **非 MTG 概念，且不是战斗概念。** **跨两个持久层的呈现视图**，同时呈现持有的全部法宝（轮回级）与古宝（账号级），条目带 `AbilityScope` 标识来源；跨战斗内外存在，**容量不设硬上限**。**`CharacterProfile.magicPack`（`List<CharacterItem>`）是它的轮回级那一半**——字段名直接命名它承载的那一半，不做「概念 → 字段」的翻译；账号级古宝的持久层是 `PlayerProfile`。战斗从中筛出 `UsableScene` 含 `InCombat` 的部分呈现为「本场可用道具」；**敌人无储物袋但同样持有道具**。**同一 `ItemId` 的道具可以持有多份**（面板内堆叠显示 `×N`） |
| 随售 | `Source.PackSell` / 平衡数值格 `PackSellRatePercent` | 玩家在**储物袋内**直接售出法宝的那条弃置通道，发生在事件之外、与 Exchange 商店内售出并列的第二条售出通道。**只对法宝开放**（准入复用「可售出 ⟺ `ExchangeGoodsKind == CharacterItem`」那条代码级常量），回收率是全局单值、**显著低于商店档**，折算基准取「族 × 稀有度」定价表的基准价。它与战斗外道具使用同属批次层的储物袋操作，push 走 `SavePointReason.InventoryChanged`。规则权威见 `systems/character-profile/item/_index.md` |
| 随身 | —（呈现名，无代码标识符） | **储物袋在战斗内那一份筛选视图的呈现名**。战斗语境里**不称「储物袋」**——储物袋是角色的容器，战斗里出现的只是它按 `UsableScene` 筛出的一个子集，且敌人没有储物袋却同样有道具。形态 = 己方战场区边缘的**角标**（与法则条分居两侧）+ 点按升起的**底部抽屉**。它**不是一个新的层级词**，只是一个界面标签 |
| 神通 / 法则（卡牌类型） | `Power` | 对位 MTG 的**徽记（emblem）**：几乎不可被交互、一旦存在就一直存在。**出入**：MTG 的徽记在指挥区且不是永久物；**本作的 `Power` 就落在战场上、是永久物**，只是带 `IsProtected` 标记不可被针对。且它不由效果产生，而是**开局按持有列表入场**；无 mana 费用（它不被「打出」） |
| 无视保护 | `IgnoresProtection` | **非 MTG 概念**（MTG 以 hexproof / indestructible 等在**被保护侧**表达；本作反向，把例外放在**攻击侧的效果**上）。效果级布尔标记：置 true 的移除 / 针对类效果可作用于受保护的战场条目（即所有 `Power`）。**是 `Power` 的唯一后门**；稀缺性与卡面明示归内容侧纪律，代码只留 `PushWarning` 软检查 |
| 关键字 | `keyword` / `KeywordData` | 对位 MTG 的 keyword，但本作**以稳定字符串 id + 注册表（`.tres`）**表达而非 C# 枚举（同次类型）。两种 `KeywordKind`：`Action` 展开为一段原子操作、`State` 展开为一份战场条目模板；**它是命名与复用的一层，不新增第三种效果载体**。单个 `Amount` 参数，无通用表达式。**当前清单为空，机制原样保留**；准入判据同次类型（≥3 条目共享 + ≥1 处筛选或 payoff 引用） |
| 目标 | `target` / `TargetSlot` | 同义。结算那一刻由 `TargetRef` 锚定到具体条目；一槽位 = 恰好一个目标，多目标靠多槽位。**须与作用域区分** |
| 作用域 | `scope` / `EffectScope` | **非 MTG 词**（MTG 以 "all …" 的文本直接表达）。静止式修正在求值瞬间按筛选条件**动态匹配**的集合：永不需要玩家输入、永不 fizzle、不落存档。与目标共用同一个筛选结构 `EntryFilter` |
| 目标落空 | `fizzle` | 对位 MTG 的 fizzle，且**同采部分落空**：结算时逐槽位重检，部分槽位非法则该槽位不生效、其余照常；全部有目标的槽位非法则整条不结算。**出入**：MTG 由「目标全部非法才不结算」的规则给出，本作把它写为逐槽位判定 |
| 疲劳 | `fatigue` / `FatiguePerDraw` | 对位 MTG「从空牌库抽牌即输」与炉石的 fatigue，**本作两处都不同**：抽牌堆**不重洗**，空堆每抽一张扣 **1 点道念**（不递增、不致死，道念下限 0 逐次截断）；**它是规则不是关键字**，无载体、无卡面；但**照常入栈**——以一条栈条目结算，与触发式异能同形，可被监听 / 响应 / 取消（MTG 与炉石的 fatigue 均无此面）。**双方一视同仁**；扣减量是 `CombatRulesData` 上的全局常量，**不进 `EncounterSpec` 覆写组**（见 `systems/balance.md`） |
| 业障 | `Affliction` | 对位 StS 的 Curse，但**可被打出**——打出无任何正面效果、唯一作用是把自己送进弃牌堆，故**不产生永久堵塞**。代价是 tempo；少数条目另带额外代价（mana / 削己方道念） |

## 修行事件分类（五类 · 定案见 ADR-0002）

| 中文 | 英文 / 代码 | 直观含义 |
|------|------------|----------|
| 战斗 | Combat | 与敌人战斗并获取资源；**最高频的一类**，唯一走战斗结算 |
| 交易 | Exchange | 以资源换取 item / cultivationTechnique / 等；含与 NPC / 势力打交道的社交语境 |
| 闭关 | Research | 玩家**调整 / 升阶自己的卡组** |
| 探索秘境 | Explore | **元类型**：遮罩一个**固定的** Combat / Travel / Exchange 事件，进入后才揭示（非点击时临时生成） |
| 前往某处地点 | Travel | **地图路由选择**：刷新角色所在的 location（地域）；**非常驻可选项** |

### 遭遇档位（`combatTier` · 仅 Combat 携带）

| 中文 | 英文 / 代码 | 直观含义 |
|------|------------|----------|
| 修炼 | Practice | 比试 / 切磋——低风险战斗式历练（对位 Balatro small blind） |
| 常规 | Standard | 常规战斗遭遇（big blind） |
| 境界突破 | Finale | **篇章边界高潮**：渡劫 / 突破至下一境界（boss blind）；**通过即推进，失败即角色终结** |

> 休养 / Rest 不单列，并入 战斗 或 闭关。
> **走火入魔**不是一类事件，而是**闭关构筑面板里玩家自选的风险档候选**：成功 `manaLimit +1`、失败 `−1`，结果在物化时掷定并落存档。它是全作 `manaLimit` 下降的唯一通道，见 `systems/adventure-event/research/_index.md`。
> **`combatTier` 不是 `eventType`**：三档共用同一套回合循环、参战方结构与结算代码，差异只在遭遇参数（回合数 / 胜负门槛 / 奖惩）。定案见 `decisions/ADR-0002-adventure-event-taxonomy.md`。

## 修行阶梯（境界 · realm）

| 中文 | 英文 / 代码 | 说明 |
|------|------------|------|
| 炼气 | Qi Refining | 第一境；境内 **1 层 ~ 13 层**（全局 1–13） |
| 筑基 | Foundation Establishment | 第二境；境内 **初期 / 中期 / 后期 / 巅峰**（全局 14–17） |
| 金丹 | Golden Core | 第三境；境内 **初期 / 中期 / 后期 / 巅峰**（全局 18–21） |
| 元婴 | Nascent Soul | 第四境（终点 / 奖杯）；**仅初期**（全局 22） |
| 篇章 | Chapter | 相邻两境之间的一段攀登；一次轮回含三个篇章。篇章跨度 = 该境界的等级跨度（1→13 / 1→4 / 1→4）；**突破后等级归位为新境界的初期**。 |



## 美术与音频（art · 工作流词汇）

| 中文 | 英文 / 代码 | 含义 |
|------|------------|------|
| 总美术方向 | art direction | `art/visuals/art-direction.md`：**所有 art guide 的公共约束**（基调 / 色彩 / 光照 / 构图 / 技术）。是每份 guide 的**上游**，跨资产的风格一致性由它承担。 |
| 生成指导 | art guide / audio guide | 单份资产的**结构化生成 prompt**：由 AI 依 vision + 参考素材写出，连同参考素材一并投喂生成工具（视觉为 Midjourney，音频工具待定）。可迭代，带「产出与迭代」记录。 |
| 参考素材 | reference material | 投喂给生成工具的既有作品 / 图像 / 音频，须逐条登记**借什么 / 不借什么**。 |
| 资产类目 | asset category | guide 的归属维度（卡面插画 / 敌人立绘 / 事件插图 / 屏幕背景 / UI 元件 / BGM / 音效…），用于与 `systems/` 的内容条目对齐。 |

> **不是游戏内术语**，是资产生产流水线的工作词汇；不会出现在玩家可见文案或代码标识符中。

Source: `handoffs/2026-07-15-adventure-event-profiles.md` · `handoffs/2026-07-15b-taxonomy-and-checkpoint-clarifications.md` · `handoffs/2026-07-22-online-cloud-combat-and-meta-clarifications.md` · `handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md` · `handoffs/2026-07-24-docs-restructure-class-model.md` · `handoffs/2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md` · `handoffs/2026-07-25b-event-cost-fields-capability-flags-and-service-hierarchy.md` · `handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md` · `handoffs/2026-07-26-event-priority-skip-semantics-and-hotfix-scope.md` · `handoffs/2026-07-27-content-gating-offline-resilience-and-rng-persistence.md` · `handoffs/2026-07-27b-service-api-contracts.md` · `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md` · `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md` · `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md` · `handoffs/2026-08-02-momentum-conversion-reward-structure-and-mtg-stack.md` · `handoffs/2026-08-02b-stack-without-interaction-and-three-step-turn.md` · `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md` · `handoffs/2026-08-04-art-audio-library-scaffold.md` · `handoffs/2026-08-04b-mtg-loanwords-card-types-and-intent-snapshot.md` · `handoffs/2026-08-05b-location-fields-event-count-limit-and-skip-refill-closure.md` · `handoffs/2026-08-06b-asymmetric-ch1-band-consented-power-loss-and-chapter-retry-shape.md` · `handoffs/2026-08-06c-skip-channel-removal-priority-two-tier-and-location-codex-edges.md` · `handoffs/2026-08-06d-combat-open-questions-mass-closure.md` · `handoffs/2026-08-09b-player-power-fragment-finale-bound-drop-chance.md` · `handoffs/2026-08-09c-past-event-trace-schema.md` · `handoffs/2026-08-09d-field-layering-merge-criterion-and-ordinal-naming.md` · `handoffs/2026-08-10b-grant-source-and-fragment-source-scoping.md` · `handoffs/2026-08-10c-ability-disable-replacement-and-player-statistics.md` · `handoffs/2026-08-11-plot-content-localization.md` · `handoffs/2026-08-11c-combat-turn-flow-fatigue-and-card-type-reduction.md` · `handoffs/2026-08-12c-identifier-singular-collapse.md` · `handoffs/2026-08-12f-cultivation-technique-deck-building.md` · `handoffs/2026-08-16c-effect-keywords-and-targeting.md` · `handoffs/2026-08-16g-travel-mechanics-and-location-carrier.md` · `handoffs/2026-08-17-travel-destination-and-status-change-elements.md` · `handoffs/2026-08-17g-element-carrier-gaps.md` · `handoffs/2026-08-22-finale-failure-is-death.md` · `handoffs/2026-08-22-enemy-deck-size-and-fatigue-knob.md` · `handoffs/2026-08-25-numeric-philosophy-and-balance-anchors.md` · `handoffs/2026-08-25-enemy-deck-from-techniques-and-ai.md` · `handoffs/2026-08-25-info-economy-and-codex-expansion.md` · `handoffs/2026-08-25-combat-presentation-and-action-result.md` · `handoffs/2026-08-26-storage-pack-two-layer-view-and-combat-holdings.md` · `handoffs/2026-08-26c-enemy-ai-strategy-shape.md` · `handoffs/2026-08-27-ability-primitive-grammar.md` · `handoffs/2026-08-27-capability-flag-and-entitlement.md` · `handoffs/2026-08-27-card-pool-and-reshuffle.md` · `handoffs/2026-08-28-content-artwork-enemy-lines-and-ai-weight-vector.md` · `handoffs/2026-08-28-item-use-effect-face-and-carrier-kind.md` · `handoffs/2026-08-28-out-of-combat-item-use-savepoint-and-trace.md`
