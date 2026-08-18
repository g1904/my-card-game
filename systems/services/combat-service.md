# combat-service（服务）

> 战斗驱动服务：回合循环、出牌结算、抽 / 弃 / 洗、敌人 AI。**敌人的行动不作事前预告。** **判据 ① —— 拥有自己的状态机与跨多帧的长流程。**

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **为何 Combat 需要独立服务，而其余四类不需要。** 五类 AdventureEvent 中**只有 Combat 真正拥有自己的状态机**——回合循环跨多帧推进、有独立的中间态（手牌、场上效果、栈）。Exchange / Research / Explore / Travel 共享同一形状（呈现 → 择一进入 → 扣成本 → 应用产出 → 推拉隐藏属性 → 收口），差异在**数据**而非**代码**，由通用结算器 + 数据驱动的 outcome / effect 定义承担。见 `_index.md` 的拆分轴。
- **Finale 复用本服务的状态机。** 境界突破是 Combat 的一个变体（独立的结算规则与胜负条件，但同一套回合循环），不另建服务。
- **战斗模型 = mana（出牌）+ 道念（计分与胜负）。** 本服务维护**双方各自的道念（momentum）**作为胜负标尺：**道念高者胜**；`currentMana / manaLimit` 为出牌资源，mana **无曲线**、**每回合开始自动恢复至 `manaLimit`**。**`lifeTotal`（单值，无上限字段）在战斗过程中不被读写**——失败时才在收口时刻按「角色道念 − 敌人道念」的差值扣减 lifeTotal。炼气基线 lifeTotal 10、mana 5/5。见 `systems/scoring.md`、`systems/character-profile/life-total.md`、`mana.md`、`systems/adventure-event/combat/`。
- **战斗是定长的：固定 10 个回合。** 一场战斗**打满 10 个回合**，**双方各 5 个**（「回合」= 单方的一次行动轮，交替进行），随后比道念、高者胜。**不设提前终止**（无道念阈值胜利、不以卡组耗尽终止）。**推论：TurnManager 是一个固定长度的循环**（`for turn in 1..10`）而非动态终止判定——状态机形状因此确定，且每场战斗的时间开销可预测。
- **平局 = 只发基础奖励。** 10 回合打满后道念相等时：**不判负、不扣 lifeTotal**，玩家**只获得该事件的基础奖励**（道念差为 0，故无任何厚度加成）。因此 `CombatOutcome` 需要第三个胜负态 `Draw`，且它在收口上落在「胜利侧的最薄一档」——与「道念差是双向刻度」自洽：差值为 0 就是两侧都不加码的那个原点。
- **道念的运行态骨架。** 战斗开始时本服务为双方各置一个**起始道念 = `baseMomentum`（按各自全局等级，表见 `systems/balance.md`）**；此后道念**由打出的卡牌产出**，且卡牌**可削减对方道念**，**削减在 0 处截断**（无负道念）。**推论：等级差在开局即转化为道念差**，越级挑战的压力有了确切量纲。
- **奖励由本服务计算，且「获取奖励」是战斗流程的一部分。** 结算量不由 life-cycle-service 拿着 `CombatResult` 的双方道念在 `eventEnd` 再算——**combat-service 按战斗结果算完**，包括按道念差决定的奖励厚度与 lifeTotal 扣减。**推论 ①：`RunCombatAsync` 的流程尾部含奖励环节**——10 回合打完后还要走「胜负判定 → 计算奖励 →（若有可选奖励）等玩家选择 → 收口」，随后才返回 `CombatResult`；它因此仍是形态 C，只是尾部多了一个等待玩家输入的阶段。**推论 ②：不违反「一个事件的收口是一次事务、一个存档点」**——本服务只**计算并确定**奖励，产出的仍是一份 `ProfileChangeSpec`（`Spoils`），真正的写入照旧由 life-cycle-service 在 `eventEnd` 合并为一次 `TryApply`。**分工 = 计算归战斗、施加归生命周期。** **推论 ③：本服务交出的 `Spoils` 内的授予一律记 `Source.CombatReward`**——授予来源的分野判据是「谁组装出这条 element」而非「属于哪类事件」，故一个揭示出战斗真身的 Explore 选项，其战利品同样记 `CombatReward`；唯一例外是 `Finale` 胜利时由道统残卷发放的那一路，走 `Source.FinaleWin`。见 `systems/common-properties.md`。
- **奖励分两类：强制自动计入 / 可选由玩家择一。** **强制奖励**无需玩家操作、自动计数（例：经验）；**可选奖励**由玩家从若干候选中选择，形态**参照 Slay the Spire** 的战后奖励面板。**推论 ①：战斗后需要一个奖励选择步骤与对应界面**，且因奖励发放归 combat 流程，这一屏在战斗流程内、返回 `CombatResult` 之前（见 `ux/combat-ux.md`）。**推论 ②：`Spoils` 需能表达两类条目**——强制部分计算时即固定，可选部分先呈现候选、再由玩家选择收敛为最终 spec。
- **奖励预先算好，故奖励选择不是决策点。** 候选项在收口时一次算定，**退出重进得到的是同一组选项**——不存在「不满意就退出重开换一批」的窗口，因此**无需为它单独落一个决策点**。**推论：候选生成必须在战斗的确定性边界之内**（走 `Reward` 子流并随战斗 RNG `State` 一同持久化），否则「重进得到同样选项」这条保证不成立。
- **失败侧仍发 `baseReward`，额外惩罚以负向条目包在 reward 内。** 输了通常只有基础奖励；少数事件附带额外惩罚，它不另立结构，就是 `Spoils` 中的负向 `ChangeElement`——与带符号约定天然自洽。见 `systems/scoring.md` 的三档结算产物表。
- **卡牌结算 = stack，但**不含交互与优先权**（承重）。** 借入 MTG 的 **stack**：打出的牌先入栈、按 **LIFO** 结算，「打出」与「结算」是两个时刻。**但交互（instant / 栈非空时出牌）与优先权传递（priority passing）整体移除**——理由是它们**把对局时长拉得太长、决策点过多、复杂度高而玩法深度收益小**。**推论 ①：「一方行动完再交给另一方」的简单交替成立**——TurnManager **不需要**「优先权在谁手上」的内循环，只需要「轮到谁」。**推论 ②：EnemyManager 的代理面回落**——AI 只在自己的回合选行动，不必在对手的窗口中决策。**推论 ③：「定长 10 回合 → 时长可预测」成立**——回合数固定、每回合步骤固定，无须再为交互次数另加时长护栏。**推论 ④：决策点粒度不必覆盖响应窗口**（粒度问题本身仍在，见待决问题）。
- **回合结构 = 三步：开始阶段 / 行动阶段 / 结束阶段。** **不设战斗步骤，也不设双主阶段**：

  | 步骤 | 英文 / 代码 | 内容 |
  |------|------------|------|
  | **开始阶段** | `start step` / `TurnStep.Start` | 回合归属方 mana 恢复至 `manaLimit` → 触发「回合开始时」→ 抽牌 |
  | **行动阶段** | `action step` / `TurnStep.Action` | **唯一**的出牌阶段。**只有回合归属方能主动出牌** |
  | **结束阶段** | `end step` / `TurnStep.End` | 触发「回合结束时」→ 清理回合内的非永久条目 |

  **中文侧统一以「阶段」收尾、英文侧统一以 `step` 收尾**；**不借 `main phase` 一词**——MTG 的 `main` 有 precombat / postcombat 两个 main 与同级 phase 作对照系，本作无战斗步骤、无双主阶段，对照系不存在，`action` 直接陈述这一步做什么。**与 `eventStart` / `eventEnd` 同词不冲突**（事件级 vs 回合级，语境不同且从不同屏出现）。

  **三步是回合归属方的流程，双方不同时走**：每一方在自己的回合内各走一套完整的三步，「回合开始 / 回合结束」是**有归属方的时点**，不是双方同步发生的公共时刻。**步内顺序是规则的一部分**：mana 恢复在「回合开始时」触发**之前**、抽牌在触发**之后**，故「回合开始时」类效果能影响本回合的抽牌。**推论 ①：mana 恢复的是本回合归属方的 mana**——非归属方无法出牌，其 mana 在对手回合无用途，语义实为「每次轮到我时刷满」；**没有交互，故不存在「响应用谁的 mana」**。**推论 ②：出牌时机是唯一的，且是全局规则**——**一张牌只能在自己回合的行动阶段、且栈为空时打出**；`instant` 不存在，出牌时机不再是卡牌的一个属性。**不借 `sorcery speed` 一词**（与之相对的 `instant speed` 不存在，单一取值的维度不是维度）；**启动式异能与道具的使用窗口与出牌完全相同**。**推论 ③：「回合内状态」成为一个正式的状态生命周期档位**，与跨回合持续状态相对。**推论 ④：没有独立的战斗步骤**——道念的产出 / 削减全部经由行动阶段打出的卡牌，不存在第二条结算通道。
- **手牌上限是一条恒定不变式，不设弃牌机制。** **手牌在任何时刻都不得超过上限**——**没有时间限制，也没有「结束阶段弃到上限」这类必须弃牌的机制**（结束阶段因此只做「触发『回合结束时』→ 清理回合内状态」）。**上限值 = 7**（见 `systems/balance.md`）。 **推论：约束点落在会让手牌增加的时刻**（抽牌、以及任何「加入手牌」类效果）。
- **满手时抽牌 = 抽不进。** 满手时抽牌**抽不进——牌留在抽牌堆，这次抽牌无事发生**；「加入手牌」类效果同理落空。**「抽出即弃」与「直接销毁」两条路线均不采用。** **推论 ①：手牌上限是一条纯上界**——不产生任何弃牌堆流量、不消耗抽牌堆。**推论 ②：弃牌不是被规则强制的动作原语**（回合末不弃、满手不弃），弃牌堆只由「打出后进弃牌堆」与「卡牌效果显式弃牌」填充。**推论 ③：抽牌堆顺序不被满手情形扰动**，seeded 洗牌的确定性不因此分叉；「本回合抽 N 张」在满手时等价于抽 0 张。**推论 ④：满手的代价是 tempo 而非资源**——牌没丢，只是这一拍没拿到，手牌上限因此是节奏约束而非惩罚。呈现见 `ux/combat-ux.md`。
- **battlefield（战场）与栈各是一个 manager（承重）。** **battlefield = 战斗的公共区**，记录**场上的全部准确数据**——哪些卡牌正在生效、有哪些持续状态、有哪些触发器在等待。新增 **BattlefieldManager**（战场）与 **StackManager**（栈）两个 manager。**推论 ①：栈与战场是两个不同的区**——**栈 = 等待结算的队列，战场 = 已结算并正在生效的东西**；完整结算路径 = **打出 → 入栈 →（LIFO）弹出结算 → 效果施加 →（若是持续效果）落到战场**。**推论 ②：「回合内 / 跨回合状态」有了确切落点**——它们是**战场上带生命周期标记的条目**，结束阶段「清理回合内状态」= 清掉战场上标记为回合内的条目（取值边界仍待定）。**推论 ③：TurnManager 是纯粹的回合状态机**，只管「轮到谁、走到三步的哪一步」；栈的持有与结算不归它。**推论 ④：战斗内状态出现第三类持有者**——属于**某一方**的东西（mana、道念、手牌、卡组）仍归 CharacterManager / EnemyManager，**已离开手牌、正在场上生效**的东西归 BattlefieldManager；确切划线见待决问题。**推论 ⑤：决策点存档必须能恢复战场**（战场条目须可序列化）；**栈则可能不必落存档**——「栈非空时双方都不能出牌」意味着任何可退出的时刻栈应为空，待确认。**推论 ⑥：EnemyManager 决策时要读战场**——场上的持续状态会改写出牌的结果，故 AI 以战场当前状态为输入。**推论 ⑦：战场必须进入呈现层**（栈之外再加一个区，见 `ux/combat-ux.md`）。
- **触发式效果的载体是开放的，不专属卡牌。** 牌上的触发器、**场上的持续状态**、**CharacterPower（神通）** 都可能承载触发式效果，**清单开放**、日后可再增载体。**推论 ①：需要一个统一的触发注册 / 匹配面**——否则每类载体各写一套「谁在监听哪个时点」的匹配逻辑。**推论 ②：该注册面坐在 battlefield 上**（「场上有哪些触发器在等待、挂在谁身上」正是场上准确数据的一部分）。**推论 ③：轮回级能力必须能被战斗内读到**——参战方组装时要把角色持有的神通**注册进战场**，故本服务要读 CharacterProfile 上的这份列表。**推论 ④：压栈者与载体解耦**——触发命中后把被触发的能力压入栈的一律是 **StackManager**。仍待定：跨归属方的触发时点、以及 PlayerPower（法则）能否也承载战斗内触发，见待决问题。
- **栈深由触发式能力入栈撑起（承重）。** **在栈上的牌可以触发能力，被触发的能力也进栈**，因此**即便只打出一张牌，栈深也可以大于 1**——这就是移除交互之后 stack 的承重点：**它管的是触发的解决顺序，不是双方互插牌**。**推论 ①：「栈非空时不能出牌」对双方都成立**，不为归属方开口子（「允许行动阶段连续压入多张牌再统一结算」这条候选路线**不采用**）。**推论 ②：LIFO 有了实际意义**——一次结算可能连锁产生多个触发，后触发的先解决，结算顺序成为卡牌设计可利用的资源。**推论 ③：「多张削减效果同时在栈上」会真实发生**——**截断在每一次结算时发生**（见下条）。**推论 ④：栈必须进入呈现层**（见 `ux/combat-ux.md`）。
- **道念的下限 0 在每一次结算时截断。** 饱和减法**逐次截断**，不是全栈结算完后再截断。**推论 ①：更保护落后方，且差异可算**——对方道念 5、栈上有「削 8」与「+3」：逐次截断 → `5-8 → 0`，再 `+3 → 3`；全栈后截断 → `5-8+3 = 0`。**溢出的削减量不结转。** **推论 ②：LIFO 顺序对最终结果有实际影响**——削减与产出交错时结算顺序改变结果，「栈序是卡牌设计可利用的资源」由此从原则变成具体算术。**推论 ③：`PlayResult` 必须携带本次的实际削减量**——截断发生在每一次结算，故每次结算都是可观测事件，「意图削减量 vs 实际削减量」的差在连锁中必然出现。见 `systems/scoring.md`。
- **回合数与胜负判据是遭遇参数，不是常量。** **`Standard` 档 = 10 回合、道念高者胜**；**`Practice` / `Finale` 档可改写回合数与胜负条件**（前者更简单、后者更难，对位 Balatro 的 small / big / boss blind）。**推论：TurnManager 仍是定长循环，但长度来自本场遭遇的配置**，且胜负判据是一个可替换的判定而非写死的比较——承载位置未定，见待决问题。
- **卡牌类型 = 五类，按「所在区 + 结算后去处」切分（承重）。** `CardType` 是五值枚举：**法术 `Sorcery`**（一次性，进弃牌堆）· **阵法 `Enchantment`**（永久物落战场，埋伏是其次类型）· **法宝 / 古宝 `Item`**（不洗进卡组，存于储物袋）· **神通 / 法则 `Power`**（开局直接入场的受保护永久物）· **业障 `Affliction`**（可打出但无正面效果，唯一作用是把自己送进弃牌堆）。**从卡组打出的永久物只有阵法一类**，故永久物不区分实体 / 非实体。**三个来源区各自绕开的东西不同**，这是五类之间最本质的结构差别：**卡组**（法术 / 阵法 / 业障，受抽牌运制约）· **持有的道具**（玩家侧来自储物袋、敌人侧来自 `EnemyData`，不受抽牌运制约）· **开局入场**（`Power`，无需玩家动作）。**推论 ①：本服务要处理三条来源路径而非一条**——`DeckModule` 之外，参战方还各持一份「本场可用道具」，且组装阶段要把 `Power` 注册进战场。**推论 ②：类型间的具体差异化留待日后**，本条只定下不定就无法写 schema 的结构性差别。
- **异能三分：静止式 / 启动式 / 触发式。** **静止式 `static ability`** 不入栈，载体在战场上即持续生效；**启动式 `activated ability`** 启动后压栈，可用窗口 = **自己回合的行动阶段、栈为空时**（与出牌完全同窗口）；**触发式 `triggered ability`** 命中后由 StackManager 压栈。它与「载体开放」正交：**载体说的是「挂在谁身上」，异能类型说的是「怎么生效」**。**关键自洽点：启动式异能不引入交互**——它的窗口就是出牌那一个窗口，不构成「在对手回合插手」的通道。**推论 ①：异能抽为独立的可复用资源 `AbilityData`**，由 `CardData` / `PowerData` / `ItemData` / 战场条目共同引用（触发匹配逻辑不能写死在卡牌类型里）。**推论 ②：静止式异能是 BattlefieldManager 的一条与栈无关的写入路径**——载体一进场即时生效、一离场即时失效。**推论 ③：启动式异能给 mana 第二个花费去向**——此前 mana 只用于出牌，手牌不足时纯浪费；现在场上永久物也能吃 mana，沉没成本被缓解，战场从纯被动区变成有操作面的区。
- **永久物（permanent）把战场条目切成两类。** **永久物 = 落在战场上、无限期存在直到被移除或战斗结束的条目**（阵法 / `Power`）；**非永久条目 = 带生命周期标记的持续状态**（回合内 / 跨回合 / 持续 N 回合）。**与 MTG 的出入：** MTG 的 permanent 是区的成员资格（在战场上的一律是永久物），**本作的永久物只是战场条目的一个子集**。**推论 ①：结束阶段的清理边界是明确的**——结束阶段**只清理非永久条目中标记为回合内的那些，永远不碰永久物**，故不存在「永久物会不会被误清」的歧义。**推论 ②：「可被移除」只对永久物有意义**，针对 / 移除类效果的目标合法性因此有了类型级判据。**推论 ③：永久物与非永久条目的存档字段形态不同**——前者带来源卡牌 `Id` + 运行态，后者带生命周期标记 + 剩余回合数。
- **触发条件可跨归属方，埋伏牌由此成立。** 时点本身有归属方（「回合开始时」是某一方的），但**监听方不必是该归属方**——一个条目可以监听「**对手的**回合开始时」「**对手**打出牌时」（`TriggerOwnerScope { Self / Opponent / Either }`）。**这是「规则体系须支持奥秘式埋伏牌」这条要求的逻辑前提**：埋伏的本质就是「在对手回合的某个时点触发」。埋伏 = **阵法的次类型**，面朝下布置、是永久物、触发后进弃牌堆、**同名不可重复布置**、**对手只知「有一张埋伏」不知是哪张**。**推论 ①：埋伏是本作唯一一条「在对手回合发生作用」的通道**——玩家不能在对手回合主动响应，但可以预先布置自动响应的东西；结算入口不变（StackManager 压栈），**这是移除交互后 stack 仍然承重的又一个证明**。**推论 ②：EnemyManager 从战场读到的是埋伏计数而非条目内容**——AI 与玩家的信息完全对称，**这是一条双向对称的信息规则**；AI 可据此变得谨慎但无法针对性规避，故**埋伏的威慑力与实际效果是两件事**。
- **道具（`Item`）是战斗内唯一会即时写 Profile 的卡牌行为（承重）。** 法宝 / 古宝**不洗进卡组**，存于角色的**储物袋**（跨战斗内外存在，上限 9 个按 `Id` 堆叠的条目）；战斗只从中筛出 `UsableScene` 含 `InCombat` 的那些，形成参战方各持一份的**「本场可用道具」**（敌人侧来自 `EnemyData`——**敌人没有储物袋但同样持有道具**，故容器与视图必须分开）。**使用窗口 = 自己回合的行动阶段、栈为空时**，与出牌完全同窗口：**「随时可用」= 不受抽牌运制约，不是不受回合限制**，交互不回归，`RunCombatAsync` 状态机形状不变。**古宝的使用次数即时经 `ProfileManager.TryApply` 写 PlayerProfile，不攒到收口**——堵死「用完退出重进恢复次数」的窗口，与既有的「战斗过程中的变更即时经 ProfileManager，`Spoils` 只承载收口产出」一致。**推论 ①：敌人的道具是它的一条独立行动来源**——AI 的决策输入除卡组与战场外还有本场可用道具，且道具的使用照常在敌人回合逐步呈现。**推论 ②：道具绕开手牌上限这条节奏约束**，是有意的松弛阀——卡组受抽牌运摆布，道具是玩家可规划的确定性资源；代价是**道具强度必须低于同费法术**（归 `systems/balance.md`）。
- **`Power` 在参战方组装阶段入场，故本服务要读两个 Profile。** **法则（PlayerPower）能承载战斗内触发**，与神通（CharacterPower）走同一条路径：**入场条件是两条与门——`status == 开启` 且 `UsableScene` 含 `InCombat`**（`status` 关闭 = **不入场**，而非「入场但不生效」；两个字段正交不可合并——`UsableScene` 是内容侧静态属性，`status` 是玩家侧运行时开关）。入场发生在**第一个开始阶段之前**，故「回合开始时」类触发从第 1 回合起就已挂载。**推论 ①：这是 combat-service 第一次需要读 PlayerProfile**——参战方组装流程要同时读 CharacterProfile 的神通列表与 PlayerProfile 的法则列表。**推论 ②：`Power` 一律受保护**（战场条目上的 `IsProtected` 在 `CardType.Power` 落场时统一置 true，**不由 `PowerData` 逐条目声明**），**唯一后门 = 效果侧声明 `IgnoresProtection`**；其稀缺性与卡面明示**归内容侧纪律，代码不加硬规则保护**（只留 `PushWarning` 软检查）。**推论 ③：`Power` 无 mana 费用**（它不被「打出」，启动式异能的启动费另算），且**是唯一不产生弃牌堆流量、也不产生栈上「打出」事件的类型**——它的触发式异能照常压栈，但它自身永远不入栈。**推论 ④：不引入 MTG 的指挥区（command zone）**——战斗内已有卡组 / 手牌 / 弃牌堆 / 栈 / 战场 / 本场可用道具六处位置，为一类不可交互的条目再开第七处，收益不抵竖屏 UI 与存档形态的成本。
- **战场与两个参战方 manager 的划线判据 = 「是否在场上生效」，不是「属于谁」。** **层级不动**：五个 manager 保持平级，`DeckModule` 仍是第三级；BattlefieldManager 不提级，两个参战方 manager 不降级。

  > **判据：** 一件东西**在场上生效、可被效果针对 / 查询、需在结束阶段被清理、需进决策点存档** → **战场条目，归 BattlefieldManager**，条目自带 `OwnerSide`。**参战方的私有资源与牌堆**（mana、道念、手牌、卡组、本场可用道具）→ **归 CharacterManager / EnemyManager**。

  按此判据，「我方本回合所有牌 +1 道念」是**战场条目**（`OwnerSide = Character` 的非永久条目），不是参战方状态——它要被针对、要被清理、要进存档，三件事全是战场的活。**「属于谁」只是它的一个字段，不是它的住处**：这正是该问题此前卡住的地方——只用「属于谁」划不开。**推论 ①：双方场区不分开记录**——单一战场记录 + `OwnerSide` 字段，不建两个并列容器；跨归属方的触发（埋伏监听「对手打出牌时」）与全场查询（「场上所有阵法」）在单一记录下是一次遍历，分成两个容器则每次查询都要合并，呈现层按 `OwnerSide` 分区渲染即可。**推论 ②：读侧统一、写侧分权**——需要「整场全部信息」的场合（EnemyManager 规划意图、决策点存档、UI 组装）读本服务组装的 `CombatSnapshot`；写入仍各归其主。**推论 ③：不把 BattlefieldManager 提为参战方之上一层**——四条理由：① 它会变成 god object（TurnManager 恢复 mana / 抽牌、StackManager 写双方道念都要经它转发）；② 级联降级会把 `DeckModule` 压到第四级，强迫回答「module 以下的下沉判据」这个尚无判据的问题；③ 层级词表的拆分轴是「生命周期层 + 行为边界」而非「谁的信息全」，而战场与两个参战方的生命周期完全同长；④ 「拥有整场信息的顶点」已由 combat-service 本身 + `CombatSnapshot` 承担。
- **战斗内的一切写入经 ProfileManager。** 耗 mana、消耗道具、获得战利品、以及**收口时按道念差扣 lifeTotal** 都走 `profile-service.ProfileManager.TryApply(...)`——本服务不直接改 CharacterProfile 字段。**道念本身是战斗内的运行态**（活在 `CombatSnapshot` 里），战斗结束即消失，不落 CharacterProfile。
- **敌人的行动不作任何事前预告（承重）。** 本服务**不提供任何形式的意图预告**——不设揭示档位、不设行动类别标注、不生成回合级行动描述、不设「花代价换情报」的探查通道。**这条不要靠加一层预告去「改善可读性」**：玩家的可读通道另有其人，清单见 `systems/adventure-event/combat/_index.md`「敌人回合的可读性」（该处为权威）。
- **敌人回合的逐步执行反馈是呈现层的硬要求（承重）。** **敌人回合是玩家获取动态情报的唯一时刻**。**本服务侧的要求：敌人回合内的每一次结算都必须是可观测事件**（逐次广播 / 逐次可读的 `PlayResult`），呈现层据此逐步演出。这与既有的「道念下限 0 在每一次结算时截断，故每次结算都是可观测事件」完全合流——**同一条要求，两个来源**。形态与节奏参数见 `ux/combat-ux.md`。
- **`MomentumDelta` 的 `Declared` / `Actual` 一对完整保留。** `Declared` 是**本次结算的效果标称量**（这张牌 / 这个异能声称削多少）。它与 `Actual` 之差正是**被下限 0 截断吞掉的量**，是「削减 8（对方仅剩 5，溢出 3 未结转）」这类反馈的唯一数据来源；逐步反馈是硬要求，故这一对字段承重。
- **EnemyManager 不受「回合级一次性规划」约束。**
  - **推论 ①：AI 可在自己的回合内逐张决策**，不必在玩家回合开始之前把整套行动（连同道具）一次定好。
  - **推论 ②：这不引入交互**——敌人回合在玩家回合之后，玩家在其中没有输入窗口；「逐张」指的是 AI 在自己回合内的内部推进顺序，不是对玩家的响应。
  - **推论 ③：难度旋钮不变**（规划算法与卡组，不在反应速度）。
  - **推论 ④：AI 仍可读对手的埋伏计数**——但那是 AI 算法的自由，不再是机制层的规划输入要求。
  - **具体 AI 形态归待决问题**，本条不指定 AI 形态。
- **敌人 AI 不单列 manager。** AI 行为选择隶属 **EnemyManager**，与敌人实例状态同属一个组件——二者共享同一份敌人运行态，拆开只会让它们互相伸手。**EnemyManager 内部不再细分职能。**
- **CharacterManager 与 EnemyManager 平级、共享接口、驱动方式相反。** 两者管理战斗的两侧参战方，**共有大量接口定义**（生命 / mana、卡组、状态、出牌）；差异只在**谁驱动决策**——EnemyManager 含**代理操作**（AI 行为选择），CharacterManager **监听玩家操作**。
- **每个参战方各有一个 `DeckModule`。** 卡组不是全局单件：**每个 character、每个 enemy 各持有一个**，由 CharacterManager / EnemyManager 各自持有。**敌人也出牌**，且可带定制卡组（例如 Finale 的天劫，以及 `EnemyData` 的样本卡组经物化改写而来）。`DeckModule` 是**第三级抽象（module）**，不列入本服务的 manager 清单——层级词表见 `systems/architecture.md`。
- **`combatTier` 三档共用本服务的参战方结构。** `Practice` / `Standard` / `Finale` 都用 EnemyManager + CharacterManager 与同一套回合循环，差异只在遭遇参数（回合数 / 胜负门槛 / 奖惩）。见 `systems/adventure-event/combat/`。
- **事件过程按决策点落存档。** 战斗**不是**存档盲区：事件过程中（含战斗内）在**决策点**落存档，使「退出重进」得到的是同一个局面与同一份 RNG 状态。**`selectCost` 不回滚**——选中事件时施加的成本（含 `lifeSpanCost`）一经施加即成事实。**决策点的具体粒度未定**，见待决问题。
- **栈必须落存档：决策点并不总落在栈为空的时刻（承重）。** **触发式异能在栈上若需要选择目标，那次目标选择本身就是一个决策点**，故「任何可退出的时刻栈都是空的」这条假设**不成立**——**不要**从「栈非空时双方都不能出牌」推出「栈总能不落存档」：**「出牌时机唯一」不等于「唯一的玩家输入时刻」**。
  - **推论 ①：栈条目须可序列化**，与战场条目同级：来源 `Id`、已选定的目标（`TargetRef` 列表）、「正等待选择目标」这一挂起态、栈内位置。
  - **推论 ②（承重 · 代码面）：结算不是一个原子的同步过程。** LIFO 弹栈结算的中途可以停下来等玩家输入，**`RunCombatAsync` 的结算循环因此必须是可挂起、可从中途恢复的状态机**，而不是一个跑到底的循环。这是本条对本服务的实际要求。
  - **推论 ③：决策点粒度的清单多一类。** 除回合 / 出牌边界外，**结算过程中的目标选择**也是决策点，粒度不止于回合 / 出牌这一级。粒度问题本身仍未答定，但已知它至少要覆盖这一类。
  - **推论 ④：这不重新引入交互。** 目标选择是**结算自身的一部分**（这张牌 / 这个触发指向谁），不是「在对手窗口插手」的响应机会；交互与优先权仍然不存在。
  - **推论 ⑤：决策点只在需要玩家输入时产生。** 敌人的触发式异能同样可能需要选目标，那由 EnemyManager 在执行时自行决定，**不产生决策点**。
- **合法目标集 = 在需要它的那一刻对当前局面跑一遍筛选，永不预存、永不缓存。** 这是「`LegalTargets` 不落存档、恢复时按当前局面重算」的正面表述。求解按槽位进行：

  ```
  LegalTargets(slot, controllerSide, battlefield, hands) =
      候选集 ← 按 slot.Kind 取全集
                None             → { }                       // 无需求解
                Side             → { Character, Enemy }
                BattlefieldEntry → battlefield 全部条目
                HandCard         → controllerSide 的手牌实例   // 强制 Self，见 deck/common-properties.md
      过滤 ① 方位：slot.Side 相对 controllerSide 解析（Any / Self / Opponent）
      过滤 ② 类别：slot.Filter.AllowedEntryKinds 命中
      过滤 ③ 保护：entry.IsProtected == false || slot.IgnoresProtection
      过滤 ④ 筛选：slot.Filter（次类型 ∩ 关键字 ∩ faceDown 可见性）
      → 结果集
  ```

  **四条过滤的顺序不是规则**——结果与顺序无关（交集可交换），写成这个顺序只为可读与短路。**这一点须明写**：本服务已有一条顺序敏感性（LIFO），求值管线另有一条（加法先于乘法），不宜让人误以为这里是第三条。槽位与筛选结构的声明侧形态见 `systems/character-profile/deck/common-properties.md`。
- **结算时逐槽位重检 + 部分 fizzle（承重）。** LIFO 连锁下，栈上更靠上的条目可能移除掉下面那条已选定的目标，**fizzle 在本作真实发生**。规则：**部分槽位非法 → 该槽位不产生效果、其余槽位照常结算**；**全部有目标的槽位都非法 → 整条不结算**（`MomentumDelta.Declared` 记 0）。
  - **否决「全有全无」**：一张两槽位的牌因为对手拆掉其中一个目标就整条落空，在 5 回合定长对局里惩罚过重，且玩家没有响应窗口去补救。
  - **连带：fizzle 必须在 ticker 上可见**——它承接「逐步反馈是硬要求」这条既定纪律，否则玩家只看到一张牌什么也没发生。见 `ux/combat-ux.md`。
- **槽位产生挂起，当且仅当三条同时成立：** ① `Kind ∈ { BattlefieldEntry, HandCard }`（`None` / `Side` 恒可自动解析）；② `controllerSide == Character`（敌人侧由 EnemyManager 自行决定）；③ `LegalTargets.Count > 1`。
  - **`Count == 1` → 自动选定，不挂起。** 省一次无意义点击、一个决策点与一次存档写；在 5 回合定长 + 移动端竖屏下这是实打实的节奏收益。
  - **`Count == 0` → 该槽位判非法**，走上条的 fizzle 分支，**不挂起**——不能让玩家面对一个空的高亮集。
  - **推论 ①：`Kind == Side` 且 `Side != Any` 的槽位永不挂起。** 「削对方 3 点道念」自动解析、零点击，**绝大多数产 / 削道念的牌因此不产生任何目标交互**，与低交互定位一致。
  - **推论 ②：这三条只管结算侧的槽位**（触发式 / 启动式异能在栈上回头问的那些）。**玩家主动出牌的全部槽位在打出前由 UI 按 `slotIndex` 顺序一次收齐，入栈即 `targetState = Resolved`**——`PlayCard` 因此收一个 `TargetRef` 列表，见「API 面」。
  - **推论 ③：一场战斗的决策点总数不再固定。** 自动选定只会**减少**决策点，故 ≈31 个决策点与 ≈93 KB 的量级是**上界而非典型值**，体积护栏不受威胁；D4 的定义（`pending` 写入那一刻）原样成立，只是写入条件更严。
- **确定性。** 洗牌、敌人行为掷骰等一律用 `life-cycle-service.SeedManager` 派生的 **combat 子流**，与地图 / 商店 / 奖励子流隔离，避免 desync。同一 seed 必须复现同一场战斗。**派生形态 = `Hash64(combatStreamSeed, eventId)`，就这一层，不加 `attemptIndex`**——篇章重试生成的是全新的 `CycleSeed`（见 `life-cycle-service.md`），再叠一层重试计数没有职责。`eventId` 这一层让不同事件的战斗随机互相隔离，成本为零。**敌人抽牌走与玩家抽牌不同的子流**，使玩家侧的一次额外抽牌不打乱敌人牌序。
- **先后手由 `EncounterSpec.FirstSide` 决定，未指定则随机。** `EncounterSpec` 带一个可空字段 **`FirstSide: Side?`**（`null` = 未指定），由 **future-event-service 在物化 eventOption 时写入**，剧情意图经其下的 **plot-manager** 调制；**未指定时由本服务用 combat 子流掷**，故同一 seed 复现同一个先后手。**推论 ①：本服务只读该字段、不问来源**——与既有「遭遇参数收进 `EncounterSpec`」（`TurnLimit` / `VictoryRule` / 抽牌与手牌上限覆写）完全同形，**不新增对 future-event-service 的运行时依赖**。**推论 ②：与「不设先后手抽牌差」不冲突**——那条说的是不做补偿（先手 tempo 优势在打满回合比总量的结构下不存在），本条说的是谁先动。**推论 ③：掷点消耗的随机落在 D0 之前**，随参战方组装一并反映进持久化的 RNG `State`，退出重进不会改变先后手。
- **不设 mulligan。** **玩家抽到什么就是什么**——起始手牌一次发到位，没有换牌 / 调度窗口。**推论：开局不多出一个决策点**（连带不多一个存档点），也不多一次 RNG 消耗；开局方差由「定长 10 回合、不设提前终止」吸收，不需要第二条抹平通道。
- **抽牌堆不重洗，抽空即疲劳（承重）。** **抽牌堆抽空即为空，弃牌堆不回流**——没有「抽牌堆空时由弃牌堆重洗补充」这条规则。**抽牌堆为空时每尝试抽一张牌，抽牌方失去 1 点道念**（一次抽 N 张即失去 N 点）。
  - **推论 ①（承重）：道念的结算通道有两条**——**卡牌**（行动阶段打出、经栈结算）与**疲劳**（开始阶段抽牌）。疲劳**不入栈、不产生 `PlayResult`**，是抽牌流程内的一次直接扣减。
  - **推论 ②：下限 0 逐次截断照常适用**——道念为 0 时继续疲劳不产生负值、溢出量不结转（`systems/scoring.md` 的既有规则原样成立，`momentum` 仍是 `>= 0` 的 Integer）。
  - **推论 ③：不以卡组耗尽终止仍然成立**——卡组耗尽不终止战斗，只是从此每回合稳定失血；定长循环的形状不变。
  - **推论 ④：`DeckModule` 没有重洗代码路径**，seeded 洗牌只发生在参战方组装时的一次初洗。
  - **推论 ⑤：满手抽不进与疲劳的叠加已定**——两条判定按流程顺序：抽牌堆为空 → 先扣道念（无牌可抽）；抽牌堆非空但满手 → 牌留在抽牌堆、无事发生、**不触发疲劳**（疲劳的触发条件是「牌堆空」，不是「没拿到牌」）。
- **卡牌侧数值。** **起始手牌 4**（双方同值）· **每回合抽 2** · **手牌上限 7** · **卡组规模：两侧皆不设硬限** · **储物袋上限 9**（计数单位 = **按 `Id` 堆叠后的条目数**）。**推论：卡组规模成为可编排维度**（敌人侧由 `EnemyData` 逐条编排、玩家侧由构筑决定），**其代价由疲劳承接**——小卡组在后期真实失血。敌我对称仍是硬纪律（起手 / 抽牌 / 手牌上限三项完全同值）。取值与推导见 `systems/balance.md`。

Source: `handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md` · `handoffs/2026-07-30-claude-engineering-scope-enemy-manager-and-requirement-breakdown.md` · `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md` · `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md` · `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md` · `handoffs/2026-08-02-momentum-conversion-reward-structure-and-mtg-stack.md` · `handoffs/2026-08-02b-stack-without-interaction-and-three-step-turn.md` · `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md` · `handoffs/2026-08-04b-mtg-loanwords-card-types-and-intent-snapshot.md` · `handoffs/2026-08-05-level-band-stack-save-and-token-free-deck.md` · `handoffs/2026-08-06d-combat-open-questions-mass-closure.md` · `handoffs/2026-08-11c-combat-turn-flow-fatigue-and-card-type-reduction.md` · `handoffs/2026-08-15d-intent-removal-lifespan-cost-visibility-and-design-audit.md` · `handoffs/2026-08-16c-effect-keywords-and-targeting.md` · `handoffs/2026-08-16h-grant-source-assembler-criterion.md` · `handoffs/2026-08-17d-exchange-mechanics-and-transaction-discipline.md`

## 战斗存档：`ActiveCombat`

> **共用公理：决策点 = 战斗状态机唯一可以停下来的地方。** 存档 schema、取消语义、决策点清单三者全部由它导出。

**`ActiveCombat` 是 `CharacterProfile` 上一个可空块**：战斗开始时创建、`eventEnd` 收口时置空。它**不进 `pastEvent`**（历史事件只留定稿快照），也不与 `Rng.Streams[]` 混住——它是**事件内的中间态**，寿命短于一次事件。挂 `CharacterProfile` 使 diff 天然落在 sync-service 既定的 diff 单位上，**无需新增同步单元**，且与「每篇章至多一个 ongoing 事件」自洽。

```jsonc
"activeCombat": {                    // null = 当前没有进行中的战斗
  "eventInstanceId": "evt-0042",     // 归属的 EventOption.InstanceId，读档时校验一致
  "encounterId": "enc_wolf_pack",
  "turnLimit": 10,                   // 遭遇参数（Practice 档 8 / Finale 档 12）
  "turnIndex": 3,
  "activeSide": "Character",
  "step": "Action",                  // Start | Action | End
  "rng": { "seed": 0, "state": 0, "drawCount": 0 },
  "sides": [ /* 恰两条 */ ],
  "battlefield": [ /* 单表 + kind */ ],
  "stack": [ /* 数组序即栈序，0 = 栈底 */ ],
  "pending": null                    // 全局至多一个
}
```

**参战方（`sides`，恰两条）**：`side` · `momentum` · `manaLimit`（战斗内不变，落它只为读档自洽）· `currentMana`（**回合内消耗量，决策点存档必须恢复它**——它每回合刷满、回合内不结转，战斗外无意义，故它的落点是本字段而非 `CharacterProfile.Status`）· `drawPile` / `hand` / `discardPile`（`CardInstanceId` **有序**序列）· `instances` · `items` · `enemyRef`（仅敌方）。

- **`enemyRef` = `EnemyInstance.InstanceId`，不是模板 `EnemyId`、也不是整份实例拷贝。** 敌人实例的唯一定稿副本嵌在 `EventOption.Encounter.Enemy` 上；本字段只是一枚指针，**存模板 id 会丢掉物化赋级的 `Level`（重算不出来），拷贝整份则是第二个落点、无机制保证两份相等**。读档时经 `activeEvent.Option.Encounter.Enemy.InstanceId` 比对，不一致 → `PushError` + 抛（与既有 `eventInstanceId` 一致性校验同款）。
- **战斗读到的敌人实例来自 `activeEvent.Option.Encounter.Enemy`**：结算期间的读取权威只有这一处（规则见 `systems/adventure-event/common-properties.md`），本服务不另辟一条读取路径。

```csharp
public sealed record CardInstanceSave(
    string InstanceId,                        // 战斗内唯一，确定性发号
    string CardId,                            // ContentRegistry 的稳定 Id
    IReadOnlyDictionary<string,int> Counters);// 运行态可变部分；空则整字段省略
```

- **`InstanceId` 确定性生成，不记「怎么造出来的」**：一场战斗内卡牌集合是**闭集**，组装阶段按固定顺序发号即可（`c#0`、`e#0`…），读档时按同一顺序重建实例表、再按三区的 `Id` 序列归位。**不需要为运行时新造的匿名卡分配 id，也不需要 token 类型。**
- **`CardType` / `Subtypes` 不落存档**（静态字段，由 `CardId` 解析）。

**战场条目（单表 + `kind`，不分三张表也不分双场区容器）**：

| 字段 | 类型 | 语义 |
|------|------|------|
| `entryId` | `string` | 战场条目唯一 id，**目标引用的锚点** |
| `kind` | `BattlefieldEntryKind { PermanentCard, PermanentPower, Transient }` | 三档 |
| `sourceId` | `string` | `CardId`（阵法）或 `PowerId`（神通 / 法则） |
| `sourceInstanceId` | `string?` | 仅 `PermanentCard`：它原本是卡组里的哪张牌（**闭集的另一半**——牌离开手牌落到战场，实例仍在） |
| `keywordId` | `string?` | **条目的关键字筛选键**：仅由 `KeywordKind.State` 展开产出的 `Transient` 条目非空。**不可由 `sourceId` 推导**——同一张牌可施加两条不同的关键字状态，两条条目的 `sourceId` 相同；没有这一格，「移除对方所有带某状态的条目」这类 payoff 写不出来。语义见 `systems/character-profile/deck/common-properties.md` |
| `ownerSide` | `OwnerSide` | 「属于谁」只是字段，不是住处 |
| `lifetime` | `EntryLifetime { UntilEndOfTurn, ForTurns, Indefinite }` | 永久物恒为 `Indefinite` 语义（永不被清理） |
| `countdownSide` | `CountdownSide { Owner, Opponent, Either }` | 以谁的结束阶段为节拍；默认 `Owner` |
| `remainingTurns` | `int` | 仅 `ForTurns` 有意义；其余档写 `-1` 并在校验中要求如此 |
| `faceDown` | `bool` | 埋伏（对手只见计数） |
| `counters` | `Dictionary<string,int>` | **运行态计数器**——`Power` 的「本场已触发 N 次」就落在这里 |

> **`Power` 的战斗内运行态不需要独立结构——它就是战场条目的 `counters`。** 这是「`Power` 是战场条目的一档」这条定案的直接后果，**不新增结构**。生命周期三件套的语义与清理判据见 `systems/character-profile/deck/_index.md`。

**栈条目**：`stackEntryId` · `kind { PlayedCard, TriggeredAbility, ActivatedAbility }` · `controllerSide`（**决定这次目标选择是否产生决策点**）· `sourceInstanceId` · `sourceEntryId` · `abilityId` · `chosenTargets`（`TargetRef[]`，按槽位顺序）· `targetState { Resolved, AwaitingChoice }`。**栈内位置由数组顺序承载，不落 `position` 字段**——索引即位置，另存一个序号是可以不一致的冗余。

**挂起态 `pending`（全局至多一个）**：`{ stackEntryId, slotIndex }`。结算是 LIFO 单线程推进的，不可能同时有两处等玩家输入；用一个顶层可空字段比在每个栈条目上找更明确，读档时「要不要进选目标态」是一次判空。**合法目标集不落存档**——恢复时按当前局面重算。

**战斗内道具运行态**：`readonly record struct CombatItemSave(string ItemId, int UsesThisCombat)`。**只落「本场已用几次」**：本场可用道具列表本身是**派生的**（玩家侧按 `UsableScene` 筛储物袋，敌人侧取 `EnemyData` 持有列表），而古宝的总剩余次数**权威在 PlayerProfile**（使用次数即时写，战斗内再存一份就是双写）。`UsesThisCombat` 仍必须存——**本作确实存在「每场限用一次」这类本场配额效果**，它是唯一的载体。

**不落存档的可重建项**（沿「可重算的东西不进存档」判据）：`isProtected`（`kind == PermanentPower` 即 `true`）· **触发器注册面**（由 `sourceId` 解析出的 `AbilityData` 重建，「谁在监听哪个时点」是纯派生数据）· **`Power` 的入场本身**（由两个 Profile 的持有列表 + `status` + `UsableScene` + **`CharacterProfile.disabledAbility`** 重放；禁用表就在 `CharacterProfile` 上、随存档走，故重建仍是确定性的，**不需要给 `ActiveCombat` 新增任何字段**）· **「本场可用道具」列表**（玩家侧按 `UsableScene` 筛储物袋，**并过滤掉在 `disabledAbility` 内的 `Id`**；敌人侧取 `EnemyData` 持有列表）· 合法目标集。

**读档校验（强制，四个检查点全部命中）**：① `eventInstanceId` 与当前进行中的 `EventOption` 不一致 → `PushError` + **拒绝恢复该战斗**；② `cardId` / `sourceId` / `abilityId` 解析不到 → `PushError` 并报出 id（**注意 `Get(id)` 不过滤 `ContentEnabled`**，故战斗中途某条目被线上关闭仍能恢复——这正是「读取侧不过滤」的用武之地）；③ `pending.stackEntryId` 在 `stack` 中找不到 → `PushError`（内部一致性破损）；④ **三区 `Id` 序列的并集 ≠ `instances` 全集 → `PushError`**（闭集不变式的自校验，是「无凭空生成的牌」买来的一条免费断言）。

**版本化**：本块是新增字段 → 随下一次 schema bump 一起走（当前无线上存档 = 空迁移）。

**已知代价**：单次决策点 diff 量级 **2–4 KB**，一场约 31 个决策点 ≈ 93 KB 本地写（毫秒级原子写，移动端可承受）；`instances` 与三区序列有冗余（**接受**，换来的是「实例表即闭集全集」这条可断言的不变式）；若实测序列化成本超预算，可退化为「战斗内只写本地、`Immediate` push 仅在进入战斗前 / 收口 / 应用失焦」——**这是纯工程优化，不改 schema**。

### 决策点清单

> **判据：决策点 = 「战斗状态机即将停下来等玩家输入」的时刻，且该时刻之前消耗的随机已全部反映在持久化的 RNG `State` 里。** 这条判据一次性解释了三件事：为什么敌人回合内部不落点（不等玩家输入）、为什么奖励选择不是决策点（等的不是会改变局面的输入）、为什么挂起态是决策点（正是在等玩家输入）。

| # | 决策点 | 精确时刻 | push policy |
|---|--------|---------|-------------|
| **D0** | 战斗开始 | 参战方组装完成（含 `Power` 入场）、第一个开始阶段之前 | `Immediate`（复用既定的「进入战斗前」flush 点）；**flush 失败不阻塞进入战斗** |
| **D1** | 行动阶段开始 | 玩家回合的开始阶段全部走完（mana 恢复 → 触发结算完 → 抽牌完），栈为空 | `Debounced` |
| **D2** | 一次出牌 / 启动 / 用道具结算完毕 | 栈**再次清空**、控制权回到行动阶段 | `Debounced` |
| **D3** | 玩家回合结束 | 结束阶段清理完，移交对手之前 | `Debounced` |
| **D4** | 进入挂起态 | 栈上某条目 `targetState = AwaitingChoice`、`pending` 写入那一刻 | `Debounced`（应用失焦时另由既定 `Immediate` 规则兜底） |
| **D5** | 敌人回合结束 | 敌人整个回合执行完（含其栈全部结算完）、交回玩家之前 | `Debounced` |
| **D6** | 战斗收口 | 胜负判定 + 奖励算定完成 | 并入 `eventEnd` 的**单一事务存档点**，不单独落点 |

**明确不是决策点**（同样重要）：弹栈结算的**每一次**弹出（除非因此进入 D4）· **敌人回合内部**的任何一步（玩家在其中没有输入，D5 一个点即覆盖整个敌人回合，它是一段可确定性重放的区间）· 战后奖励选择。

- **密度 ≈ 31 个决策点 / 场**（10 回合、玩家 5 个回合、每回合出 2~3 张牌）。**保留 D2**——它是「退出重进得到同一局面」这条承诺在最自然位置的兑现，**不作为超预算时的第一削减对象**——该承诺在强制在线 · 云端权威下是玩家对存档的基本信任。若实测超预算，先动 push 频率而非存档点本身（存档点与 push 已解耦）。
- **软阻塞闸门不受影响**：`sync-service` 的缓冲上限口径为「未同步的**事件级**存档点 ≥ 3」，**战斗内 D0–D5 照常写本地、照常防抖 push，但不参与软阻塞判定**——否则每场战斗的第三个决策点就会触发模态。**连带：D0 的 `Immediate` flush 失败也不触发阻塞**——同一个点不能一边被排除在闸门计数外、一边又能独立挡住玩家；且此时 `SelectCost` 已施加，挡住 = 付了成本却拿不到事件。「flush 是尝试、闸门是状态」见 `sync-service.md`「`Immediate` flush 的失败语义」。
- **需要选目标的触发式异能按稀缺配额编排**：占全部触发式异能 **≤ 10%**（加载时统计 + `PushWarning`）、一场 `Standard` 档战斗期望进入挂起态 **1~2 次**（编排口径，不可机械化）。频度天然低——玩家**主动出牌**的目标在打出时就由 UI 按 `slotIndex` 顺序一次收齐（`PlayCard(card, targets)`，入栈时 `targetState = Resolved`），挂起态**只**来自「压进去的东西在结算时回头问一句『指谁』」；敌人侧的目标选择由 EnemyManager 自行决定、不产生决策点。**稀少改变的是性能预算，不是正确性要求**：D4 必须在清单里。连带成立——**挂起态存档不做任何专门优化**，`ActiveCombat` 全量序列化足够，**栈的增量写入不做**。

### 挂起态的恢复与取消

- **恢复回到该选择点，栈原样挂起，不允许反悔。** 回退到更粗的边界意味着重放已弹栈结算的条目，而 RNG `State` 已随之前进——要么局面分叉，要么就得回滚 `State`，那等于给玩家开了「不满意就退出重掷」的窗口。与「`SelectCost` 不回滚」同一条纪律：**已经发生的事就是发生了**。且若恢复只能回到更粗的边界，「存挂起态」本身就没有存在意义。
- 恢复流程与正常推进路径**共用同一段代码**：读 `ActiveCombat` → 重建实例表 / 战场 / 栈 → 重放派生项 → `pending != null` ? 按当前局面重算合法目标集并直接进入选目标态 : 按 `step` 进入对应阶段。
- **`ct` 只在决策点被观察**（`AdvanceToNextDecisionPoint()` → `PersistDecisionPoint()` → `ThrowIfCancellationRequested()` → `WaitForPlayerInput()`）。三条推论：**取消点与存档点永远重合**（对齐问题因此**不存在**，而不是「靠约定去对齐」）· **中间态永不需要持久化**（结算走到一半被取消是不可能的）· 等待输入期间收到取消则落在 D1/D2/D4 之一，恢复时回到同一处等待。这与「结算循环必须可挂起可恢复」不冲突——**可挂起的位置就是决策点，两者是同一个集合**。
- **UX 硬要求：选目标态必须自解释**（交代是哪张牌 / 哪个异能在要求选目标、它要做什么），不能依赖玩家的短期记忆——玩家可能隔几小时才回来。见 `ux/combat-ux.md`。
- 取消的触发方清单与 `AdvanceStage.Cancelled` 见 `life-cycle-service.md`。

## 管理器

| manager | 职责 |
|---------|------|
| **TurnManager** | **定长回合**的状态机（`Standard` 档 = 10 回合、双方各 5，交替；`Practice` / `Finale` 档可改写长度）。每个回合走**三步**：**开始阶段**（归属方 mana 恢复至 `manaLimit` → 触发「回合开始时」→ 抽牌）→ **行动阶段**（唯一出牌阶段，只有归属方出牌；**无优先权内循环**）→ **结束阶段**（触发「回合结束时」→ 清理回合内状态）→ 交给另一方。**三步是归属方的流程，双方不同时走。** 打满后做胜负判定（`Standard` 档 = **道念高者胜**，相等 = `Draw`，只发 `baseReward`），随后走**奖励计算与可选奖励选择**再收口。**它只管「轮到谁、走到哪一步」——栈的持有与结算归 StackManager** |
| **CharacterManager** | 玩家侧参战方：角色的对战状态、其卡组、**本场可用道具**、出牌通道；**监听玩家操作** |
| **EnemyManager** | 敌人侧参战方：敌人实例与状态、其卡组、**本场可用道具**（来自 `EnemyData`）、**AI 行为选择**；**代理操作**。内部不再细分职能。决策时**读战场当前状态 + 本场可用道具**（亦可读对手的埋伏计数，但那是算法的自由，不是机制要求）。**不受「回合级一次性规划」约束** |
| **BattlefieldManager** | **战场（battlefield）**：场上正在生效的条目、**触发器注册面**（谁在监听哪个时点）与清理。条目分**三档**：**永久物 · 常规**（阵法结算后落场，可被针对，永不被结束阶段清理）· **永久物 · 受保护**（`Power`，开局入场，`IsProtected = true`，唯一后门是效果侧的 `IgnoresProtection`）· **非永久条目**（持续状态，带生命周期标记，结束阶段清理标记为「回合内」的那些）。**静止式异能是一条与栈无关的写入路径**（载体一进场即生效、一离场即失效）。**单一战场记录，不分双场区容器**——条目自带 `OwnerSide` / `IsProtected` / `SourceId`，呈现层按 `OwnerSide` 分区渲染 |
| **StackManager** | **栈（stack）**：压栈、**LIFO 结算**、连锁触发的解决顺序。**被触发的能力由它压栈**（与触发挂在哪个载体上无关）；结算产生的持续效果落到 BattlefieldManager |

**`DeckModule`（第三级）不是平级 manager。** 抽牌堆 / 手牌 / 弃牌堆的流转与 seeded 洗牌由 CharacterManager 与 EnemyManager 各自持有的 `DeckModule` 承担，**每个 character / enemy 一份**。它与那套共享的参战方接口是同一件事的两面。

**「本场可用道具」是与 `DeckModule` 平级的第三级持有物，且不称储物袋。** 参战方各持一份：**玩家侧 = 储物袋中 `UsableScene` 含 `InCombat` 的筛选结果**，**敌人侧 = `EnemyData` 的道具持有列表**。**储物袋是角色的道具容器（跨战斗内外存在、上限 9 个按 `Id` 堆叠的条目），不是战斗概念**——敌人没有储物袋却同样持有道具，正说明容器与本场视图必须分开。

**参战方组装阶段读两个 Profile。** 组装时除卡组与道具外，还要把 **CharacterProfile 的神通列表**与 **PlayerProfile 的法则列表**按**三条与门**——「`status == 开启` 且 `UsableScene` 含 `InCombat` 且**不在 `CharacterProfile.disabledAbility` 内**」——过滤后**作为 `CardType.Power` 注册进战场**，入场早于第一个开始阶段。**这是本服务第一次需要读 PlayerProfile。** 三个字段**正交不可合并**：`UsableScene` 是内容侧静态属性、`status` 是账号级玩家开关、`disabledAbility` 是**轮回级外部抑制**（见 `systems/character-profile/power/_index.md`）。**同一条禁用过滤也作用于「本场可用道具」的派生**（被禁用的法宝 / 古宝不进该列表，储物袋里仍在）。

**栈与战场是两个区，不是一个。** 栈 = **等待结算**的队列；战场 = **已结算并正在生效**的东西。结算的完整路径：**打出 → 入栈 →（LIFO）弹出结算 → 效果施加 →（若是持续效果）落到战场**。

Source: `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md` · `handoffs/2026-08-04b-mtg-loanwords-card-types-and-intent-snapshot.md` · `handoffs/2026-08-10c-ability-disable-replacement-and-player-statistics.md` · `handoffs/2026-08-17h-profile-field-schema.md`

## API 面（契约）

> 总则与共享类型见 `systems/architecture.md`「API 契约总则」。本服务**纯本地**，永不跨进程边界；`RunCombatAsync` 是形态 C（跨多帧、由信号推进），其余为形态 A。

| 方法 | 形态 | 完整签名 | 失败语义 |
|------|------|----------|----------|
| 打一场 | **C** | `Task<CombatResult> RunCombatAsync(EncounterSpec encounter, CancellationToken ct)` | 未知 `EncounterId` = 坏数据 → `PushError` + 抛；胜负是**结果**不是失败 |
| 出牌 | A | `PlayResult PlayCard(CardInstance card, IReadOnlyList<TargetRef> targets)` | 业务失败（mana 不足、目标非法、槽位数不匹配）→ `PlayResult`，绝不抛 |
| **提供目标** | A | `PlayResult ProvideTarget(TargetRef target)` | 非法目标 → `PlayResult { Accepted = false, Rejection = IllegalTarget }`，绝不抛；服务端仍以 `LegalTargets` 为准校验 |
| 结束回合 | A | `void EndTurn()` | — |
| 战斗态 | A | `CombatSnapshot Snapshot { get; }` | 只读视图，供 ViewModel 组装；**必含双方道念**；**按变更广播 + 缓存**，不是每次访问现组装 |

```csharp
public sealed record EncounterSpec(               // sealed record 而非 struct：字段多、含引用类型、落存档、非热路径
    string            EncounterId,                // 溯源；战斗类事件下 = EventOption.InstanceId
    CombatTier        Tier,                        // Practice | Standard | Finale —— 篇章边界 / 残卷 / 重试模型的判据；战斗规则本身不由它派生
    EnemyInstance     Enemy,                      // 单数：本作不存在多敌人场景；恒非空（三档一律有敌人）
    int               TurnLimit,                  // 双方合计回合数；Practice 8 / Standard 10 / Finale 12
    VictoryRule       VictoryRule,
    Side?             FirstSide,                   // 先手方；null = 未指定 → 由 combat 子流掷。剧情指定时由 future-event-service 物化写入
    string            RewardPoolId,               // 可选奖励抽取池
    ProfileChangeSpec BaseReward);                // 本场 baseReward，物化时定稿

public readonly record struct VictoryRule(
    int  WinMargin,          // 角色须领先的点数。Standard = 1（严格高于）、Practice = 0、Finale = N
    );                       // 差额未达 WinMargin → Draw

public readonly record struct CombatResult(
    CombatOutcome     Outcome,            // Victory | Draw | Defeat（Draw = 未达 WinMargin，只发基础奖励）
    int               CharacterMomentum,  // 收口时角色道念
    int               EnemyMomentum,      // 收口时敌方道念；二者之差：胜 → 奖励厚度，负 → lifeTotal 扣减
    int               RemainingLifeTotal, // 收口扣完之后剩余的 lifeTotal（非「战斗中掉剩的血」）
    ProfileChangeSpec Spoils);            // 本服务算好的最终奖励（含可选奖励的玩家选择结果、失败侧的负向条目）

public enum Side       { Character, Enemy }       // 与战场条目的 OwnerSide 同一枚举，复用不另立
public enum TargetKind { None, Side, BattlefieldEntry, HandCard }

public readonly record struct TargetRef(
    TargetKind Kind,
    Side       Side,      // Kind == Side 时即目标；否则为该条目的归属方（冗余但便于校验与呈现）
    string     EntryId);  // 战场条目 / 手牌实例的运行时 id；Kind == None | Side 时为 string.Empty

public sealed record CombatSnapshot(              // 只读视图，供 ViewModel 组装；不落存档
    int          TurnIndex,
    int          TurnLimit,                       // 来自 EncounterSpec，UI 需显示「第 3 / 10 回合」
    Side         ActiveSide,
    TurnStep     Step,                            // Start | Action | End
    SideSnapshot Character,
    SideSnapshot Enemy,
    IReadOnlyList<BattlefieldEntryView> Battlefield,  // 单一记录，条目自带 OwnerSide，呈现层分区渲染
    IReadOnlyList<StackEntryView>       Stack,        // 栈顶在前
    PendingTargetRequest? PendingTarget);         // 结算挂起中的「请选目标」；无挂起时 null

public sealed record SideSnapshot(
    string ActorId,                               // CharacterId / 敌人实例 Id
    int    GlobalLevel,                           // 1..22，用于呈现等级差
    int    Momentum,                              // 当前道念（>= 0）—— 主视觉「双方道念对比」的数据源
    int    MomentumDeltaThisTurn,                 // 本回合累计变化（带符号），用于涨落反馈
    int    CurrentMana, int ManaLimit,
    int    HandCount,                             // 双方都给计数
    IReadOnlyList<string> HandCardInstanceIds,    // 仅己方非空；敌方恒为空
    int    DrawPileCount, int DiscardPileCount,
    int    AmbushCount,                           // 双向对称：只给计数不给内容
    IReadOnlyList<string> UsableItemIds);         // 本场可用道具；仅己方非空

public readonly record struct PendingTargetRequest(
    string     StackEntryId,                      // 谁在要目标
    int        SlotIndex,                         // 问的是第几个槽位；与 pending.slotIndex 同值
    string     SourceCardId,                      // 呈现用（「埋伏·XX 需要一个目标」）
    TargetKind AllowedKinds,
    IReadOnlyList<TargetRef> LegalTargets);       // 按当前局面算出的合法目标集，UI 直接据此高亮

public readonly record struct PlayResult(
    bool          Accepted,           // 业务失败 = false，绝不抛
    PlayRejection Rejection,
    string        CardInstanceId,
    int           ManaSpent,
    MomentumDelta CharacterMomentum,  // 本次出牌链路（含连锁触发）结算完毕后，角色侧的道念变化
    MomentumDelta EnemyMomentum,
    bool          AwaitingTarget,     // true = 结算在中途挂起，等玩家选目标
    int           StackDepth);        // 挂起时的栈深；0 = 已结算干净

public enum PlayRejection
{ None, NotYourTurn, NotActionStep, StackNotEmpty, InsufficientMana, IllegalTarget, CardNotInHand }

public readonly record struct MomentumDelta(
    int Before, int After,            // 本次结算前 / 后（After >= 0）
    int Declared,                     // 声明量合计：产出为正、削减为负
    int Actual);                      // 实际量 = After − Before；与 Declared 之差 = 被下限 0 截断吞掉的量
```

- **`CombatSnapshot` / `PlayResult` 必须承载道念。** 胜负标尺是道念，故战斗态视图与出牌结果**都要能表达道念的当前值与本次变化量**——否则 `ux/combat-ux.md` 的「双方道念对比」主视觉无数据可读。
- **道念字段结构 = 当前值 + 本回合增量，且明确不分来源（承重）。** `CombatSnapshot` 是**状态视图**（现在是多少），按来源拆分道念是**事件视图**的活；分来源的诉求由 `PlayResult` 承载，两者不重复。
- **`MomentumDelta` 的 `Declared` / `Actual` 放在 `PlayResult` 而非 `CombatSnapshot`（承重）。** 判据：**snapshot 是状态视图**（现在是多少），**`PlayResult` 是事件视图**（这一次发生了什么）——而截断是每次结算发生的**事件**。这条划分同时解释了为何 snapshot 只需「当前值 + 本回合增量」。
  - **`Declared` 是效果的标称量。** `Declared − Actual` = 被下限 0 吞掉的溢出量，UI 据此打出「削减 8（对方仅剩 5，溢出 3 未结转）」。**它正是「敌人回合的执行过程须逐步可见」这条硬要求所需的数据**——该要求的理由是「敌人回合是玩家获取动态情报的唯一时刻」。
- **`PlayCard` 收一个 `TargetRef` 列表，长度必须等于该效果的 `TargetSlots` 长度**（顺序即 `slotIndex`；无目标的槽位写 `TargetRef(None, _, string.Empty)`）。**一个效果可以有多个目标槽位，而主动出牌的槽位一律在打出前收齐**——把它们改走挂起态逐个问，会让决策点密度按每张多目标牌 +N 暴涨，与 D4 的稀缺配额正面冲突。**运行时不变式（可断言）**：`chosenTargets.Length == TargetSlots.Length` · `pending` 非空 ⇒ 该槽位满足挂起三条件 · 静止式修正的求值路径上**恒不出现 `TargetRef`**。
- **`ProvideTarget` 补上的是一个真实的 API 缺口**：结算循环已定为可挂起的状态机，但此前没有让玩家把目标交回去的方法。返回同一个 `PlayResult` 类型——它是**同一次出牌的续报**，续报里的 `MomentumDelta` 覆盖「从上次挂起点到本次挂起点 / 结算完毕」这一段；`AwaitingTarget` 可连续为 true（连锁触发中多次要目标）。**不走 EventBus 回传**——广播是既成事实、不承载请求。
- **`SideSnapshot` 单类型，不拆己方 / 对方**：拆两个类型会让「双方对称的参战方模型」在视图层裂开、ViewModel 要写两套。代价是必须写死一条填充纪律——**敌方侧的 `HandCardInstanceIds` 与 `UsableItemIds` 恒为空，不是 bug**。
- **`TargetKind` 必须有 `None`**：`PlayCard` 每次都要传一个 `TargetRef` 而大量牌无目标，`None` 使「无目标」成为**已表达的取值**而非 null 约定。**`StackEntry` 不保留**——本作不做「反制栈上条目」这一形态的效果，枚举里不留永无消费者的取值；栈条目只被 `pending` 与结算流程用 `stackEntryId` 引用，**从不作为效果的目标**。
- **`CombatTier` 是三值枚举而非 bool**：回合数与胜负判据已显式化，**战斗规则不从它派生**；但它是**战斗之外**三处的判据（篇章边界闸门 · ADR-0004 篇章重试 · 道统残卷的累积与兑现），故用三值枚举而非 bool——枚举同时让 `Practice` 有了位置。见 `decisions/ADR-0002-adventure-event-taxonomy.md`。
- **胜负判据参数化为两个数就够，不做「可替换的判定对象」**：`(1, false)` / `(0, false)` / `(N, false)` 已覆盖全部已陈述需求，无需策略枚举与分发。
- **`BaseReward` 随物化定稿**（热更不影响进行中的遭遇），与「`EventOption` 产出即定稿」一致；代价是与「overlay 热更即生效」略有张力，**取定稿纪律**。
- **`EncounterSpec` 整份嵌在 `EventOption.Encounter` 上，`EncounterId` 与 `EventOption.InstanceId` 同值的冗余是写明的例外、不是先例。** 本服务只见 `EncounterSpec`、不见 `EventOption`；删掉这一格会让战斗侧日志与 `ActiveCombat` 存档失去溯源键。它与 `LifeSpanAfter` 同款处置——**不得据此放宽「重算得出来的不存」这条判据**。
- **`CombatSnapshot` 按变更广播 + 缓存**，不是每次访问现组装（含两个列表，UI 每帧读会在热路径分配）；调用纪律 = **每回合 / 每次结算后组装一次**。归 `.claude/rules/csharp-godot-rules.md` 热路径不分配。
- **运行时视图字段 ≠ 存档 schema**：二者大量重合但不应混为一谈（例如 `PendingTargetRequest.LegalTargets` 明确不必存档，恢复时按当前局面重算）。存档 schema 见上方「战斗存档：`ActiveCombat`」。

### 可选奖励的候选生成

- **固定 3 项候选，不受道念差影响**：数量恒定使 UI 布局稳定，也避免「多给一项」这种价值跳变让玩家更想 reroll（而 reroll 通道已被「奖励选择不是决策点」封死）。**道念差的价值全部落在候选质量上**（`Tier` 三档，见 `systems/balance.md`），不落在数量上。
- **池 = 事件模板携带的 `RewardPoolId`，经 `AllEnabled()` 取池**，混合 `CardData` 与 `ItemData`，去重（本次已抽中的 `Id` 不再出）。**必须走 `AllEnabled()`**，不得自写 `All().Where(x => x.ContentEnabled)`。**`RewardPoolId` 挂 `AdventureEventData` 不挂 `EnemyData`**——「打赢什么敌人」与「这场给什么奖」是两件事，同一个敌人在 Practice 与 Combat 中的奖励池应当能不同。**稀有度权重表按 `RarityTier` 五档索引、由优势档 `Tier` 三档选表**——`RarityTier { Tier1..Tier5 }` 是内容品质档（挂 `CardData` / `ItemData` / `PowerData`，缺失 → `PushError`），`Tier { Narrow, Solid, Crushing }` 是道念差归一化的优势档，**两者不得复用同一枚举、也不得互相换算**。见 `systems/balance.md`。
- **时点 = 胜负判定之后、奖励选择步骤之前，一次性抽定**，走 `RngStream.Reward` 子流；**`picks` 与 `rng.State` 一同落存档，恢复时直接读已抽定的 `picks`，绝不用同一 `State` 重抽**——后者依赖抽取算法永不变更，是脆弱保证；直接存结果才真正兑现「退出重进得到同一组选项」。
- `combatTier` 三档**共用同一条生成路径**，差异只在 `RewardPoolId` 与 `Tier`。
- **不设「放弃全部候选」通道**（放弃会重新制造一个玩家心理上的决策点，与低压定位相悖）。**合法池不足 3 条目时显式降级**：`PushWarning` + 给出实际能给的项数，**不静默给 2 项**。
- 「碾压才有高稀有度」会诱导玩家专挑弱敌刷奖励——但 `±2` 带已从规则层封住碾压深度，该激励天然受限。**这是 `±2` 带的一个正向副作用。**

- **`RunCombatAsync` 收 `EncounterSpec` 而非 `CharacterProfile`**：当前角色是 life-cycle-service 状态机的持有物，本服务经 `ProfileService.Instance` 读写，不接收角色参数。
- **`CardData` ↔ `CardInstance` 是「模板 ↔ 运行时实例」的另一半**（另一半是 `AdventureEventData` ↔ `EventOption`）：签名里**传实例，不传 `Resource`**；区别在于 `CardInstance` 运行态**可变**（手牌中的临时增益），而 `EventOption` 产出即定稿不可变。见 `systems/architecture.md` 总则 6。
- **`CombatResult.Spoils` 是 `ProfileChangeSpec` 而非「已写好的变更」。** 本服务只**描述**结果；life-cycle-service 在 `eventEnd` 阶段把它连同 `lifeSpanCost` 与隐藏属性推拉**合并为一次 `TryApply`**，从而「一个事件的收口是一次事务、一个存档点」。战斗**过程中**的血 / mana 变更仍即时经 ProfileManager——**事件内部的主动消费即时提交**，这是同一条纪律的另一半，不是例外；`Spoils` 只承载收口产出。

Source: `handoffs/2026-07-27b-service-api-contracts.md` · `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md` · `handoffs/2026-08-06d-combat-open-questions-mass-closure.md`

**事件面：**

| 事件 | 负载 |
|------|------|
| `CombatTurnStarted` / `CombatTurnEnded` | `(int TurnIndex)` |
| `CardResolved` | `(string CardInstanceId, string CardId)` |
| `CombatFinished` | `(CombatOutcome Outcome, int CharacterMomentum, int EnemyMomentum, int RemainingLifeTotal)` |

`CardResolved` 在战斗内每张牌都广播，是热路径——故负载为 `readonly record struct` 且**只带 `Id`**，不带 `CardInstance` 引用（EventBus 走 C# 泛型事件而非 Godot `[Signal]` 的直接动因，见总则 5）。

## 与其他服务的关系

```
life-cycle-service.AdvanceEventAsync(eventOption, mode, ct)
   ├─ 【eventStart 阶段】选 resolver
   ├─ CombatEventResolver.ResolveAsync(option, ct)          [eventType == Combat | Finale]
   │     └─▶ combat-service.RunCombatAsync(encounter, ct)
   │           ├─▶ content-service.ContentRegistry  按 Id 取 CardData / EnemyData / ItemData / PowerData / AbilityData
   │           ├─▶ profile-service               参战方组装：读 CharacterProfile（神通 · 法宝 · 储物袋）
   │           │                                 **与 PlayerProfile（法则 · 古宝）** —— 首次读 PlayerProfile
   │           ├─▶ profile-service.ProfileManager   战斗过程中的即时写入（含古宝次数的即时消耗）
   │           └─▶ CombatResult（Outcome + 双方道念 + RemainingLifeTotal + Spoils:ProfileChangeSpec）
   └─ 【eventEnd 阶段】Spoils + lifeSpanCost + 隐藏属性推拉 → **一次** TryApply → 一个存档点
```

## 决策(-> ADR)

- **战斗模型 = mana + 道念；胜负 = 道念高者胜；失败按道念差扣 lifeTotal** → 见 `systems/scoring.md`、`systems/adventure-event/combat/`、`systems/character-profile/life-total.md`、`mana.md`。**ADR 候选。**
- **战斗定长 = 10 个回合（双方各 5）；起始道念 = `baseMomentum`；道念可互削、下限 0**。
- **敌人的行动不作任何事前预告**（不设揭示档位 / 行动类别标注 / 回合级行动描述 / 探查通道）；**EnemyManager 不受「回合级一次性规划」约束**；**敌人回合的每一次结算必须是可观测事件**（逐步演出是硬要求）。
- **`ActiveCombat` 战斗存档 schema（挂 `CharacterProfile`、可空、收口即清）；D0–D6 决策点清单（保留 D2）；挂起态恢复回到该选择点、不允许反悔；`ct` 只在决策点被观察；战斗随机不设 `attemptIndex` 派生层**。
- **`EncounterSpec` 携带 `TurnLimit` / `VictoryRule` / `RewardPoolId` / `BaseReward` 且改为 `sealed record`；`IsFinale` 收编为三值 `CombatTier`；新增 `ProvideTarget` API；`MomentumDelta` 四字段（`Declared` = 效果标称量）；可选奖励固定 3 项且预先算定落存档**。
- **奖励计算归 combat-service、发放属于战斗流程；奖励分强制 / 可选两类且预先算定（奖励选择不是决策点）；回合数与胜负判据为遭遇参数**。
- **卡牌结算 = stack（LIFO），但交互与优先权传递移除；栈深由触发式能力入栈撑起；回合结构 = 开始阶段 / 行动阶段 / 结束阶段三步（归属方各走一套，无战斗步骤、无双主阶段）；出牌时机唯一且为全局规则；手牌上限是恒定不变式、不设弃牌机制**。
- **借词第一批全部定名；卡牌类型五分 + 异能三分 + 永久物；战场与参战方的划线判据 = 「是否在场上生效」**。**ADR 候选**（`CardType` 五值枚举是内容体系的根，值得固化）。
- **先后手由 `EncounterSpec.FirstSide` 决定（null → combat 子流掷）；不设 mulligan；抽牌堆不重洗、抽空即每张扣 1 道念；起手 4 / 手牌上限 7 / 卡组规模不设硬限 / 储物袋 9**。
- **D0–D6 决策点清单完整，D2 不得砍。** **D2 兑现的是「退出重进得到同一局面」**，在强制在线 · 云端权威下这是玩家对存档的基本信任，不是可牺牲的性能余量；超预算时先动 push 频率。约 31 个决策点 / 场、≈93 KB 本地写的量级接受。
- **引入 battlefield（战场）并新增 BattlefieldManager 与 StackManager 两个 manager；满手时抽牌抽不进（纯上界、无弃牌流量）；触发式效果的载体开放（牌上触发器 / 场上持续状态 / CharacterPower，可再增）；道念下限 0 在每一次结算时截断**。
- **Finale 不是独立事件类型，而是 Combat 的最重一档 `combatTier`；三档共用战斗状态机** → `decisions/ADR-0002-adventure-event-taxonomy.md`。
- **合法目标集 = 即时求解的四条可交换过滤（顺序非规则）；结算时逐槽位重检并采部分 fizzle；挂起态三条与门；`PlayCard` 收 `TargetRef` 列表；`PendingTargetRequest` 带 `SlotIndex`；战场条目新增 `keywordId`**。

Source: `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md` · `handoffs/2026-08-02-momentum-conversion-reward-structure-and-mtg-stack.md` · `handoffs/2026-08-02b-stack-without-interaction-and-three-step-turn.md` · `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md` · `handoffs/2026-08-04b-mtg-loanwords-card-types-and-intent-snapshot.md` · `handoffs/2026-08-06d-combat-open-questions-mass-closure.md` · `handoffs/2026-08-11c-combat-turn-flow-fatigue-and-card-type-reduction.md` · `handoffs/2026-08-15d-intent-removal-lifespan-cost-visibility-and-design-audit.md` · `handoffs/2026-08-16-design-audit-adjudication-and-hand-limit.md`

## 待决问题

- **Finale 的奖励结构加厚幅度。** 「Finale 是战斗变体、天劫为带定制卡组的 Enemy」与遭遇参数（12 回合 / `WinMargin N`）均已定案；**奖励加厚的具体取值**归 ch1 数值标杆专场。→ `systems/adventure-event/combat/`。
- **战斗内容全部未设计。** 卡牌定义与起始卡组、敌人目录、遭遇战编排——均为空白（**回合内的效果 / 状态系统骨架**，见 `systems/character-profile/deck/_index.md`）。→ `systems/adventure-event/combat/`、`systems/character-profile/deck/`。
- **敌人 AI 的决策形态。** AI 可在自己回合内逐张决策；具体算法、决策粒度、多回合行为倾向、难度旋钮落点均未定义。→ `systems/enemies/`。

## 对应
提炼至：`.claude/knowledge/systems/combat-service.md`（引用层，待建）。
