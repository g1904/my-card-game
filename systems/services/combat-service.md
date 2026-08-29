# combat-service（服务）

> 战斗驱动服务：回合循环、出牌结算、抽 / 弃 / 洗、敌人 AI。**敌人的行动不作事前预告。** **判据 ① —— 拥有自己的状态机与跨多帧的长流程。**

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **为何 Combat 需要独立服务，而其余四类不需要。** 五类 AdventureEvent 中**只有 Combat 真正拥有自己的状态机**——回合循环跨多帧推进、有独立的中间态（手牌、场上效果、栈）。Exchange / Research / Explore / Travel 共享同一形状（呈现 → 择一进入 → 扣成本 → 应用产出 → 推拉隐藏属性 → 收口），差异在**数据**而非**代码**，由通用结算器 + 数据驱动的 outcome / effect 定义承担。见 `_index.md` 的拆分轴。
- **Finale 复用本服务的状态机。** 境界突破是 Combat 的一个变体（独立的结算规则与胜负条件，但同一套回合循环），不另建服务。**本服务不负责角色终结**：Finale 失败照常返回一份 `CombatResult`（`Outcome == Defeat`），是否因此终结角色由 life-cycle-service 的终态判定裁定——**判定归生命周期、计算归战斗**这条既有分工在这里无例外。
- **战斗模型 = mana（出牌）+ 道念（计分与胜负）。** 本服务维护**双方各自的道念（momentum）**作为胜负标尺：**道念高者胜**；`currentMana / manaLimit` 为出牌资源，mana **无曲线**、**每回合开始自动恢复至 `manaLimit`**。**`lifeTotal`（单值，无上限字段）在战斗过程中不被读写**——失败时才在收口时刻按「角色道念 − 敌人道念」的差值扣减 lifeTotal。炼气基线 lifeTotal 10、mana 5/5。见 `systems/scoring.md`、`systems/character-profile/life-total.md`、`mana.md`、`systems/adventure-event/combat/`。
- **战斗是定长的：固定 10 个回合。** 一场战斗**打满 10 个回合**，**双方各 5 个**（「回合」= 单方的一次行动轮，交替进行），随后比道念、高者胜。**不设提前终止**（无道念阈值胜利、不以卡组耗尽终止）。**推论：TurnManager 是一个固定长度的循环**（`for turn in 1..10`）而非动态终止判定——状态机形状因此确定，且每场战斗的时间开销可预测。
- **平局 = 只发基础奖励（`Standard` 档）。** `Standard` 档打满 10 回合后道念相等时：**不判负、不扣 lifeTotal**，玩家**只获得该事件的基础奖励**（道念差为 0，故无任何厚度加成）。因此 `CombatOutcome` 需要第三个胜负态 `Draw`，且它在收口上落在「胜利侧的最薄一档」——与「道念差是双向刻度」自洽：差值为 0 就是两侧都不加码的那个原点。**`Draw` 只在 `Standard` 一档可达**：另两档 `WinMargin` 为 0，相等即判胜（`Practice` 点到为止 / `Finale` 不落后即通过），`Draw` 分支在那里恒不成立。
- **道念的运行态骨架。** 战斗开始时本服务为双方各置一个**起始道念 = `baseMomentum`（按各自全局等级，表见 `systems/balance.md`）**；此后道念**由打出的卡牌产出**，且卡牌**可削减对方道念**，**削减在 0 处截断**（无负道念）。**推论：等级差在开局即转化为道念差**，越级挑战的压力有了确切量纲。
- **奖励由本服务计算，且「获取奖励」是战斗流程的一部分。** 结算量不由 life-cycle-service 拿着 `CombatResult` 的双方道念在 `eventEnd` 再算——**combat-service 按战斗结果算完**，包括按道念差决定的奖励厚度与 lifeTotal 扣减。**推论 ①：`RunCombatAsync` 的流程尾部含奖励环节**——10 回合打完后还要走「胜负判定 → 计算奖励 →（若有可选奖励）等玩家选择 → 收口」，随后才返回 `CombatResult`；它因此仍是形态 C，只是尾部多了一个等待玩家输入的阶段。**推论 ②：不违反「一个事件的收口是一次事务、一个存档点」**——本服务只**计算并确定**奖励，产出的仍是一份 `ProfileChangeSpec`（`Spoils`），真正的写入照旧由 life-cycle-service 在 `eventEnd` 合并为一次 `TryApply`。**分工 = 计算归战斗、施加归生命周期。** **推论 ③：本服务交出的 `Spoils` 内的授予一律记 `Source.CombatReward`**——授予来源的分野判据是「谁组装出这条 element」而非「属于哪类事件」，故一个揭示出战斗真身的 Explore 选项，其战利品同样记 `CombatReward`；唯一例外是 `Finale` 胜利时由道统残卷发放的那一路，走 `Source.FinaleWin`。见 `systems/common-properties.md`。
- **奖励分两类：强制自动计入 / 可选逐项领取。** **强制奖励**无需玩家操作、自动计数（例：经验）；**可选奖励逐项列出、由玩家逐项领取或跳过**，形态**参照 Slay the Spire** 的战后奖励面板——**不是从候选中择一**，三项各自独立，可以全领、也可以一项不领。**推论 ①：战斗后需要一个奖励领取步骤与对应界面**，且因奖励发放归 combat 流程，这一屏在战斗流程内、返回 `CombatResult` 之前（见 `ux/combat-ux.md`）。**推论 ②：`Spoils` 需能表达两类条目**——强制部分计算时即固定，可选部分先呈现候选、再由玩家的逐项领取收敛为最终 spec（跳过的项零 element、零代价，与置换 / 禁用面板的「拒绝」同款）。
- **候选预先算定使 reroll 封死；领取进度是新状态，故领取是决策点。** 这两句并行不悖，各管一半：
  - **封死 reroll 的是「预先算定」**——`picks` 在胜负判定后一次抽定并落存档，**退出重进得到的是同一组候选**，不存在「不满意就退出重开换一批」的窗口。**推论：候选生成必须在战斗的确定性边界之内**（走 `Reward` 子流并随战斗 RNG `State` 一同持久化），否则这条保证不成立。
  - **「已领哪几项 / 还剩哪几项」是逐项领取新引入的中途状态**：它由玩家输入产生、局面重算不出来，且流程会在每一次领取 / 跳过之后停下来继续等玩家输入 ⇒ 按「状态机停下来等玩家输入且此刻之前消耗的随机已全部反映在持久化 `State` 里」这条判据，**它是决策点**（`D6`，见下方决策点清单），落点承载于 `activeCombat.reward`。
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
- **道念的下限 0 在每一次结算时截断。** 饱和减法**逐次截断**，不是全栈结算完后再截断。**推论 ①：更保护落后方，且差异可算**——对方道念 5、栈上有「削 8」与「+3」：逐次截断 → `5-8 → 0`，再 `+3 → 3`；全栈后截断 → `5-8+3 = 0`。**溢出的削减量不结转。** **推论 ②：LIFO 顺序对最终结果有实际影响**——削减与产出交错时结算顺序改变结果，「栈序是卡牌设计可利用的资源」由此从原则变成具体算术。**推论 ③：`ActionResult` 必须携带本次的实际削减量**——截断发生在每一次结算，故每次结算都是可观测事件，「意图削减量 vs 实际削减量」的差在连锁中必然出现。见 `systems/scoring.md`。
- **回合数与胜负判据是遭遇参数，不是常量。** **`Standard` 档 = 10 回合、道念高者胜**；**`Practice` / `Finale` 档可改写回合数与胜负条件**（前者更简单、后者更难，对位 Balatro 的 small / big / boss blind）。**推论：TurnManager 仍是定长循环，但长度来自本场遭遇的配置**，且胜负判据是一个可替换的判定而非写死的比较——承载位置未定，见待决问题。
- **卡牌类型 = 五类，按「所在区 + 结算后去处」切分（承重）。** `CardType` 是五值枚举：**法术 `Sorcery`**（一次性，进弃牌堆）· **阵法 `Enchantment`**（永久物落战场，埋伏是其次类型）· **法宝 / 古宝 `Item`**（不洗进卡组，存于储物袋）· **神通 / 法则 `Power`**（开局直接入场的受保护永久物）· **业障 `Affliction`**（可打出但无正面效果，唯一作用是把自己送进弃牌堆）。**从卡组打出的永久物只有阵法一类**，故永久物不区分实体 / 非实体。**三个来源区各自绕开的东西不同**，这是五类之间最本质的结构差别：**卡组**（法术 / 阵法 / 业障，受抽牌运制约）· **持有的道具**（玩家侧来自储物袋、敌人侧来自 `EnemyData`，不受抽牌运制约）· **开局入场**（`Power`，无需玩家动作）。**推论 ①：本服务要处理三条来源路径而非一条**——`DeckModule` 之外，参战方还各持一份「本场可用道具」，且组装阶段要把 `Power` 注册进战场。**推论 ②：类型间的具体差异化留待日后**，本条只定下不定就无法写 schema 的结构性差别。
- **异能三分：静止式 / 启动式 / 触发式。** **静止式 `static ability`** 不入栈，载体在战场上即持续生效；**启动式 `activated ability`** 启动后压栈，可用窗口 = **自己回合的行动阶段、栈为空时**（与出牌完全同窗口）；**触发式 `triggered ability`** 命中后由 StackManager 压栈。它与「载体开放」正交：**载体说的是「挂在谁身上」，异能类型说的是「怎么生效」**。**关键自洽点：启动式异能不引入交互**——它的窗口就是出牌那一个窗口，不构成「在对手回合插手」的通道。**推论 ①：异能抽为独立的可复用资源 `AbilityData`**，由 `CardData` / `PowerData` / `ItemData` / 战场条目共同引用（触发匹配逻辑不能写死在卡牌类型里）。**推论 ②：静止式异能是 BattlefieldManager 的一条与栈无关的写入路径**——载体一进场即时生效、一离场即时失效。**推论 ③：启动式异能给 mana 第二个花费去向**——此前 mana 只用于出牌，手牌不足时纯浪费；现在场上永久物也能吃 mana，沉没成本被缓解，战场从纯被动区变成有操作面的区。
- **永久物（permanent）把战场条目切成两类。** **永久物 = 落在战场上、无限期存在直到被移除或战斗结束的条目**（阵法 / `Power`）；**非永久条目 = 带生命周期标记的持续状态**（回合内 / 跨回合 / 持续 N 回合）。**与 MTG 的出入：** MTG 的 permanent 是区的成员资格（在战场上的一律是永久物），**本作的永久物只是战场条目的一个子集**。**推论 ①：结束阶段的清理边界是明确的**——结束阶段**只清理非永久条目中标记为回合内的那些，永远不碰永久物**，故不存在「永久物会不会被误清」的歧义。**推论 ②：「可被移除」只对永久物有意义**，针对 / 移除类效果的目标合法性因此有了类型级判据。**推论 ③：永久物与非永久条目的存档字段形态不同**——前者带来源卡牌 `Id` + 运行态，后者带生命周期标记 + 剩余回合数。
- **触发条件可跨归属方，埋伏牌由此成立。** 时点本身有归属方（「回合开始时」是某一方的），但**监听方不必是该归属方**——一个条目可以监听「**对手的**回合开始时」「**对手**打出牌时」（`TriggerOwnerScope { Self / Opponent / Either }`）。**这是「规则体系须支持奥秘式埋伏牌」这条要求的逻辑前提**：埋伏的本质就是「在对手回合的某个时点触发」。埋伏 = **阵法的次类型**，面朝下布置、是永久物、触发后进弃牌堆、**同名不可重复布置**、**对手只知「有一张埋伏」不知是哪张**。**推论 ①：埋伏是本作唯一一条「在对手回合发生作用」的通道**——玩家不能在对手回合主动响应，但可以预先布置自动响应的东西；结算入口不变（StackManager 压栈），**这是移除交互后 stack 仍然承重的又一个证明**。**推论 ②：EnemyManager 从战场读到的是埋伏计数而非条目内容**——AI 与玩家的信息完全对称，**这是一条双向对称的信息规则**；AI 可据此变得谨慎但无法针对性规避，故**埋伏的威慑力与实际效果是两件事**。
- **道具（`Item`）是战斗内唯一会即时写 Profile 的卡牌行为（承重）。** 法宝 / 古宝**不洗进卡组**，存于角色的**储物袋**（跨两个持久层的呈现视图，跨战斗内外存在，容量不设硬上限）；战斗只从中筛出 `UsableScene` 含 `InCombat` 的那些，形成参战方各持一份的**「本场可用道具」**（敌人侧来自 `EnemyData`——**敌人没有储物袋但同样持有道具**，故容器与视图必须分开）。**使用窗口 = 自己回合的行动阶段、栈为空时**，与出牌完全同窗口：**「随时可用」= 不受抽牌运制约，不是不受回合限制**，交互不回归，`RunCombatAsync` 状态机形状不变。**古宝的使用次数即时经 `ProfileManager.TryApply` 写 PlayerProfile，不攒到收口**——堵死「用完退出重进恢复次数」的窗口，与既有的「战斗过程中的变更即时经 ProfileManager，`Spoils` 只承载收口产出」一致。**推论 ①：敌人的道具是它的一条独立行动来源**——AI 的决策输入除卡组与战场外还有本场可用道具，且道具的使用照常在敌人回合逐步呈现。**推论 ②：道具绕开手牌上限这条节奏约束**，是有意的松弛阀——卡组受抽牌运摆布，道具是玩家可规划的确定性资源；代价是**道具强度必须低于同费法术**（归 `systems/balance.md`）。
- **`Power` 在参战方组装阶段入场，故本服务要读两个 Profile。** **法则（PlayerPower）能承载战斗内触发**，与神通（CharacterPower）走同一条路径：**入场条件是两条与门——`status == 开启` 且 `UsableScene` 含 `InCombat`**（`status` 关闭 = **不入场**，而非「入场但不生效」；两个字段正交不可合并——`UsableScene` 是内容侧静态属性，`status` 是玩家侧运行时开关）。入场发生在**第一个开始阶段之前**，故「回合开始时」类触发从第 1 回合起就已挂载。**推论 ①：这是 combat-service 第一次需要读 PlayerProfile**——参战方组装流程要同时读 CharacterProfile 的神通列表与 PlayerProfile 的法则列表。**推论 ②：`Power` 一律受保护**（战场条目上的 `IsProtected` 在 `CardType.Power` 落场时统一置 true，**不由 `PowerData` 逐条目声明**），**唯一后门 = 效果侧声明 `IgnoresProtection`**；其稀缺性与详情页明示**归内容侧纪律，代码不加硬规则保护**（只留 `PushWarning` 软检查）。**推论 ③：`Power` 无 mana 费用**（它不被「打出」，启动式异能的启动费另算），且**是唯一不产生弃牌堆流量、也不产生栈上「打出」事件的类型**——它的触发式异能照常压栈，但它自身永远不入栈。**推论 ④：不引入 MTG 的指挥区（command zone）**——战斗内已有卡组 / 手牌 / 弃牌堆 / 栈 / 战场 / 本场可用道具六处位置，为一类不可交互的条目再开第七处，收益不抵竖屏 UI 与存档形态的成本。
- **战场与两个参战方 manager 的划线判据 = 「是否在场上生效」，不是「属于谁」。** **层级不动**：五个 manager 保持平级，`DeckModule` 仍是第三级；BattlefieldManager 不提级，两个参战方 manager 不降级。

  > **判据：** 一件东西**在场上生效、可被效果针对 / 查询、需在结束阶段被清理、需进决策点存档** → **战场条目，归 BattlefieldManager**，条目自带 `OwnerSide`。**参战方的私有资源与牌堆**（mana、道念、手牌、卡组、本场可用道具）→ **归 CharacterManager / EnemyManager**。

  按此判据，「我方本回合所有牌 +1 道念」是**战场条目**（`OwnerSide = Character` 的非永久条目），不是参战方状态——它要被针对、要被清理、要进存档，三件事全是战场的活。**「属于谁」只是它的一个字段，不是它的住处**：这正是该问题此前卡住的地方——只用「属于谁」划不开。**推论 ①：双方场区不分开记录**——单一战场记录 + `OwnerSide` 字段，不建两个并列容器；跨归属方的触发（埋伏监听「对手打出牌时」）与全场查询（「场上所有阵法」）在单一记录下是一次遍历，分成两个容器则每次查询都要合并，呈现层按 `OwnerSide` 分区渲染即可。**推论 ②：读侧统一、写侧分权**——需要「整场全部信息」的场合（EnemyManager 规划意图、决策点存档、UI 组装）读本服务组装的 `CombatSnapshot`；写入仍各归其主。**推论 ③：不把 BattlefieldManager 提为参战方之上一层**——四条理由：① 它会变成 god object（TurnManager 恢复 mana / 抽牌、StackManager 写双方道念都要经它转发）；② 级联降级会把 `DeckModule` 压到第四级，强迫回答「module 以下的下沉判据」这个尚无判据的问题；③ 层级词表的拆分轴是「生命周期层 + 行为边界」而非「谁的信息全」，而战场与两个参战方的生命周期完全同长；④ 「拥有整场信息的顶点」已由 combat-service 本身 + `CombatSnapshot` 承担。
- **战斗内的一切写入经 ProfileManager。** 耗 mana、消耗道具、获得战利品、以及**收口时按道念差扣 lifeTotal** 都走 `profile-service.ProfileManager.TryApply(...)`——本服务不直接改 CharacterProfile 字段。**道念本身是战斗内的运行态**（活在 `CombatSnapshot` 里），战斗结束即消失，不落 CharacterProfile。
- **敌人的行动不作任何事前预告（承重）。** 本服务**不提供任何形式的意图预告**——不设揭示档位、不设行动类别标注、不生成回合级行动描述、不设「花代价换情报」的探查通道。**这条不要靠加一层预告去「改善可读性」**：玩家的可读通道另有其人，清单见 `systems/adventure-event/combat/_index.md`「敌人回合的可读性」（该处为权威）。
- **逐步执行反馈是呈现层的硬要求，双方回合都适用（承重）。** **本服务侧的要求：战斗内的每一次结算都必须是可观测事件**（逐次广播 `CombatFeedEntry` / 逐次可读的 `ActionResult`），呈现层据此逐步演出。**同一条要求，两个来源、两侧适用面：**
  - **敌人回合**这一半的理由是**敌人回合是玩家获取动态情报的唯一时刻**——敌人不作事前预告，执行过程是唯一的情报通道；
  - **玩家回合**这一半的理由是**LIFO 连锁的因果必须可读、被下限 0 截断的量必须被说明**——一次出牌可连锁出多个触发，只报一个终值，玩家读不出「谁引发了谁」，也读不出溢出未结转的那部分。

  这与既有的「道念下限 0 在每一次结算时截断，故每次结算都是可观测事件」完全合流。形态与节奏参数见 `ux/combat-ux.md`。
- **`MomentumDelta` 的 `Declared` / `Actual` 一对完整保留。** `Declared` 是**本次结算的效果标称量**（这张牌 / 这个异能声称削多少）。它与 `Actual` 之差正是**被下限 0 截断吞掉的量**，是「削减 8（对方仅剩 5，溢出 3 未结转）」这类反馈的唯一数据来源；逐步反馈是硬要求，故这一对字段承重。
- **EnemyManager 不受「回合级一次性规划」约束。**
  - **推论 ①：AI 可在自己的回合内逐张决策**，不必在玩家回合开始之前把整套行动（连同道具）一次定好。
  - **推论 ②：这不引入交互**——敌人回合在玩家回合之后，玩家在其中没有输入窗口；「逐张」指的是 AI 在自己回合内的内部推进顺序，不是对玩家的响应。
  - **推论 ③：反应速度不是难度旋钮。** 难度由 `baseMomentum` 与内容编排承担；规划算法与卡组是**打法风格的表达面**，不叠第二条强度曲线。
  - **推论 ④：AI 仍可读对手的埋伏计数**——但那是 AI 算法的自由，不再是机制层的规划输入要求。
  - **具体 AI 形态归待决问题**，本条不指定 AI 形态。
- **敌人 AI 不单列 manager。** AI 行为选择隶属 **EnemyManager**，与敌人实例状态同属一个组件——二者共享同一份敌人运行态，拆开只会让它们互相伸手。**EnemyManager 内部不再细分职能。**
- **敌人 AI 分两层：通用兜底 + 敌人模板级定制（承重）。** **通用兜底策略** = 任何套牌都能跑的保底出牌逻辑，**实现在 EnemyManager 内**——它是算法而非可调数值，故不另立内容条目、不建「默认策略」资源（日后若需数值旋钮，走 `CombatRulesData` 一类平衡资源）。**敌人模板级定制策略挂在 `EnemyData` 上**（「这个敌人该怎么打」），**字段可空、空即回落兜底**；漏填只是回落到一条可用路径，不产生静默污染，故不取「必填无默认」那一档。字段面与形态归 `systems/enemies/`。
  - **推论 ①：`EnemyInstance` 不加字段。** 策略经 `EnemyInstance.EnemyId` → `ContentRegistry.Get<EnemyData>()` 解析——**模板常量不是物化产物**，消费方本来就要查模板，在同一次 `Get()` 里免费拿到。这与「结算期间敌人**实例**的读取权威只有 `activeEvent.Option.Encounter.Enemy` 一处」不冲突：那条约束的是实例，按 `Id` 解析模板的静态字段是 `CardData` / `ItemData` / `PowerData` 同款的全库通例。
  - **推论 ②：战斗内仍然完全不感知功法。** 策略是敌人模板的属性，与卡组的来源无关；参战方组装时卡组已展开为卡牌集合，`EnemyInstance` 只持 `DeckCardIds`。「功法是战斗外的构筑层，战斗内完全不感知它」这条纪律因此原样成立，见 `systems/character-profile/deck/_index.md`。
  - **推论 ③：策略的运行态归 EnemyManager**，不新增持有者、**不进 `ActiveCombat`**——战斗内的敌人运行态本就归 EnemyManager，且本作不存在多敌人场景。**连带：不可由局面重算的策略状态不能有**——多回合行为倾向取**零记忆**这一端：一切倾向都写成当前局面的函数（剩余回合数 · 双方道念差 · 抽牌堆余量 · 己方战场条目 · 手牌张数，全部已在 `ActiveCombat` 内），**`ActiveCombat` 一格不加、零迁移**，AI 不得持有任何跨动作 / 跨回合的私有字段。
  - **推论 ④：定制策略只表达打法风格，不作强度 / 难度旋钮。** 强度主刻度仍是 `baseMomentum` 与内容编排，**卡组与策略都不叠第二条强度曲线**；「策略不得强于兜底多少」是**编排口径、不设校验**（与「`Practice` 默认不挂负向 `OnFailureRules`」同款软口径）。
  - **推论 ⑤：定制层只提供权重向量，不提供代码。** 定制策略的形态 = 一条独立可复用的 `EnemyAiProfileData`（`[Export]` 直接类型引用、可空），内容只有一组 `AiTerm → float` 的权重覆写；它与兜底跑**同一条 argmax 循环、同一套 term、同一个候选集**。字段面与逐条校验归 `systems/enemies/`。
- **AI 兜底算法 = 单层（1-ply）加权效用评分 + 确定性 argmax（承重）。** 一次决一个动作，执行到栈清空后重新组装候选集再决下一个——**栈结算会改变局面**（连锁触发、下限 0 截断、条目落场 / 离场），一次性规划出的后续动作在执行到时的合法性与价值都可能已变。候选集：

  ```
  candidates ← { PlayCard(c)           | c ∈ 己方手牌, c.ManaCost <= currentMana, 每个槽位 LegalTargets 非空 }
             ∪ { UseItem(i)            | i ∈ 本场可用道具, Profile 侧充能未耗尽 且 本场配额未用尽 }
             ∪ { ActivateAbility(e, a) | a ∈ 己方战场条目 e 的启动式异能,
                                         a.ManaCost <= currentMana
                                         且（a.MaxActivationsPerCombat == -1 或 counters[a.Id] < a.MaxActivationsPerCombat）}
             ∪ { EndTurn }
  score(a) = Σ_k  w_k · term_k(a, view)      // score(EndTurn) ≡ 0，作绝对零点
  ```

  ```csharp
  // EnemyManager 内部。static ⇒ 私有记忆在语言层无处存放（ADR-0013 第 1 级）；返回 EndTurn ⇒ 本回合结束
  internal static EnemyAction ChooseAction(
      in CombatSnapshot           view,      // viewerSide = 该敌人的 OwnerSide；唯一输入面
      IReadOnlyList<CardInstance> selfHand,  // view 己方手牌 id 的实例解析结果，由 EnemyManager 提供
      EnemyAiProfileData?         profile,   // null = 纯兜底权重
      in AiWeightVector           fallback); // 来自 Content.Single<CombatRulesData>()，已展开为定长向量

  public enum AiTerm                         // 初值，开放可加（同 EffectData 原子操作清单）
  { MomentumGain, MomentumDenial, ManaEfficiency, BoardPresence, Removal,
    AmbushCaution, HandRetention, KeyCardAffinity, ClosingUrgency, ItemEagerness }

  public enum EnemyActionKind { PlayCard, UseItem, ActivateAbility, EndTurn }

  public readonly record struct EnemyAction(
      EnemyActionKind          Kind,
      string                   SubjectId,   // CardInstanceId / ItemId / BattlefieldEntryId；EndTurn 时 string.Empty
      string                   AbilityId,   // 仅 ActivateAbility；否则 string.Empty
      IReadOnlyList<TargetRef> Targets);    // 按 slotIndex 顺序，已由 AI 自行解析完毕（不产生决策点）

  // 定长权重向量。索引 = (int)AiTerm；长度恒 == AiTerm 成员数。
  public readonly struct AiWeightVector
  {
      private readonly float[] _values;                  // 加载期一次分配，此后只读
      public float this[AiTerm term] => _values[(int)term];
  }
  ```

  - **`AiWeightVector` 是加载期的展开产物，不是内容形态。** 内容侧写的是稀疏的 `CombatRulesData.AiFallbackWeights : AiWeight[]`；**ContentRegistry 在 `LoadAll()` 内把它一次性展开为定长向量，落 ContentRegistry 侧的派生索引**，不写回条目（`CombatRulesData` 是共享只读单例）。它**不落 `.tres`、不落存档、不进上行负载，不 bump 任何 schema**。数组一次分配、按枚举索引零分配，落在热路径纪律内。
    - **`AiFallbackWeights` 缺项 → `PushError` + 抛**（见 `systems/balance.md`）**正是这次展开的前置条件**：缺项即向量带一个静默的 `0f`，而 `score` 是这批 term 的线性组合，静默零权重不会以任何方式显形。
  - **有效权重的合并语义只写在这一处：**

    ```
    w_k = profile 的 Weights 中列了 term_k ? 该条的 Value : fallback[term_k]
    ```

    `systems/enemies/` 一侧只写「profile 只列要覆写的项，未列项取兜底默认值」，**不复述这条算式**——两处同时写出完整算式即第二权威，两份会各自漂移而本库无机制发现。
  - **`score(EndTurn) ≡ 0` 是承重的**：它把「还该不该继续行动」变成 argmax 的自然产物，不需要第二套「何时收手」的规则；同时它给权重向量一个绝对零点，取值域因此可被钳制（钳制区间与兜底向量住 `CombatRulesData`，见 `systems/balance.md`）。
  - **试算不展开连锁触发，这是规则不是实现细节。** 每个候选的收益按该动作自身 `EffectData` 在求值管线上跑一遍得出（走「效果流水线」的阶段 1 → 3 拿到 `Declared`，不进施加与收口）。展开连锁等于把 StackManager 的结算在评分里重跑一遍（性能与正确性双重风险），且**搜索深度恒为 1-ply 正是「定制不强于兜底」的结构性上界之一**——不写成规则，日后有人顺手加一层，上界当场失效。
    - **试算侧的条件求值是一条例外，须一并写明：** 真实结算逐 element 就地求条件、读得到同序列前序 element 的产物；**试算则按「进入本动作前的局面」一次求全部条件**，因为它不进施加阶段、没有产物可读。**故试算与真实结算可能走不同分支**（例：同一张牌先产道念、后一个 element 写「若我道念 ≥ 10 则抽 1」，试算按产之前的道念判、真实结算按产之后的判）。这是 1-ply 无副作用试算的**已知代价**，不是缺陷：让试算读到自己的产物就要真的施加一遍，那正是本条要禁的事。内容侧纪律：**依赖同序列内前序产物的条件应当稀少**，它们对 AI 是不可见的收益。
  - **目标选择复用同一个评分函数**：在既定的 `LegalTargets` 结果内取使该动作试算分数最高者，平手取序列首项；`LegalTargets` 为空的槽位使该候选整个不进候选集。不为目标另写第二套启发式——两套会各自漂移而无机制发现。
  - **`ActivateAbility` 的两个准入闸一个都不能漏**（mana 可付 **且** 本场配额未用尽；`MaxActivationsPerCombat == -1` 即不限、该闸恒过）：契约权威在下方「API 面」，AI 侧只是引用方。
  - 打法风格的十项 term 语义、强弱差的三条结构性上界见 `systems/enemies/_index.md`。
- **AI 决策是「当前局面 + `combat` 子流」的纯函数（承重）。** 不得依赖真实时间、帧序或未持久化的隐藏记忆；**随机只取 `combat` 子流，不再派生新流**——而**兜底与定制策略均零随机消耗**（平手按确定性字典序打破：`−score` → 动作种类序 → 主体 id 的组装序），故这条约束当前为空，保留它是为日后可能引入的随机化权重项。理由：敌人回合内部不落决策点，**D5 一个点即覆盖整个敌人回合，它是一段可确定性重放的区间**——玩家在敌人回合中途退出时整段被重放，任何不在存档里的私有记忆都会让重放分叉。**输入面限对称可见信息**：战场全部条目（含 `OwnerSide`）· 双方道念与回合数 · 对手埋伏**计数** · 对手手牌**张数** · 自己的手牌 / 卡组 / 本场可用道具；**不读玩家手牌内容与抽牌堆顺序**——这一条做到 `ADR-0013` 第 1 级：AI 读的是 `viewerSide` 为敌方的 `CombatSnapshot`，而 `SideSnapshot.HandCardInstanceIds` 恒只有 viewer 己方非空、抽牌堆只给张数，玩家手牌内容与牌序**在类型层根本没有承载它们的字段**。**AI 的目标选择照旧不产生决策点**，定制策略不改变这一条。
- **CharacterManager 与 EnemyManager 平级、共享接口、驱动方式相反。** 两者管理战斗的两侧参战方，**共有大量接口定义**（生命 / mana、卡组、状态、出牌）；差异只在**谁驱动决策**——EnemyManager 含**代理操作**（AI 行为选择），CharacterManager **监听玩家操作**。
- **每个参战方各有一个 `DeckModule`。** 卡组不是全局单件：**每个 character、每个 enemy 各持有一个**，由 CharacterManager / EnemyManager 各自持有。**敌人也出牌**，且可带定制卡组：`EnemyData` 的样本卡组由**功法列表展开而来（外加游离散牌）**，天劫等条目的定制性由**敌方专用功法**承担。`DeckModule` 是**第三级抽象（module）**，不列入本服务的 manager 清单——层级词表见 `systems/architecture.md`。
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
  - **连带：fizzle 必须在战报（`combatLog`）上可见**——它承接「逐步反馈是硬要求」这条既定纪律，否则玩家只看到一张牌什么也没发生。见 `ux/combat-ux.md`。
- **槽位产生挂起，当且仅当三条同时成立：** ① `Kind ∈ { BattlefieldEntry, HandCard }`（`None` / `Side` 恒可自动解析）；② `controllerSide == Character`（敌人侧由 EnemyManager 自行决定）；③ `LegalTargets.Count > 1`。
  - **`Count == 1` → 自动选定，不挂起。** 省一次无意义点击、一个决策点与一次存档写；在 5 回合定长 + 移动端竖屏下这是实打实的节奏收益。
  - **`Count == 0` → 该槽位判非法**，走上条的 fizzle 分支，**不挂起**——不能让玩家面对一个空的高亮集。
  - **推论 ①：`Kind == Side` 且 `Side != Any` 的槽位永不挂起。** 「削对方 3 点道念」自动解析、零点击，**绝大多数产 / 削道念的牌因此不产生任何目标交互**，与低交互定位一致。
  - **推论 ②：这三条只管结算侧的槽位**（触发式 / 启动式异能在栈上回头问的那些）。**玩家主动出牌的全部槽位在打出前由 UI 按 `slotIndex` 顺序一次收齐，入栈即 `targetState = Resolved`**——`PlayCard` 因此收一个 `TargetRef` 列表，见「API 面」。
  - **推论 ③：一场战斗的决策点总数不再固定。** 自动选定只会**减少**决策点，故 ≈31 个决策点与 ≈93 KB 的量级是**上界而非典型值**，体积护栏不受威胁；D4 的定义（`pending` 写入那一刻）原样成立，只是写入条件更严。
- **确定性。** 洗牌、先后手掷点、AI 决策掷骰、卡牌与异能效果内的随机，一律直接取 `life-cycle-service.SeedManager` 的 **`combat` 子流本身**，与地图 / 商店 / 奖励子流隔离，避免 desync。**其上不派生任何层**——既不按 `eventId` 分流、也不按 `attemptIndex` 分流、也不按参战方分流。同一 `CycleSeed` + 同一 `contentVersion` 复现同一场战斗。不叠派生层的理由见 `systems/common-properties.md` 与 `systems/services/life-cycle-service.md`。
  - **两侧牌序互不打乱，这个性质由结构提供、与子流数量无关。** 两侧牌序在参战方组装时各洗一次即定，此后抽牌只是从定序列表头部取值、**零随机消耗**（见下方「抽牌堆不重洗」推论 ④）⇒ 「玩家的一次额外抽牌打乱敌人牌序」这条通道在结构上不存在，不需要为它分出第二条流。
  - **初洗与掷点的先后是规则，不是实现细节。** 单流之下谁先取随机就决定了两侧牌序，顺序不写下来即为未定义行为。规则：**参战方组装时按 `ActiveCombat.sides[]` 的存档序依次初洗**（`sides[0]` = 玩家侧、`sides[1]` = 敌方侧），**`FirstSide == null` 时的先后手掷点排在两次初洗之后**。掷点排在后面，使 `FirstSide` 是否被内容侧显式指定**不改变两侧牌序**——内容编排改一个字段不会连锁抖动整场牌序，编排者的心智负担更低。
  - **确定性的可验证形态（三条断言，可在 Godot 编辑器内运行观察）：** ① **复现**——同一 `CycleSeed` + 同一 `contentVersion` + 同一玩家动作序列 ⇒ 同一场战斗（两侧初始牌序、先后手、AI 每一步选择、效果内随机结果逐项一致）。**`contentVersion` 相同这一前提必须显式钉住**，否则任何一次 overlay 热更都会让这条断言误报失败（边界见 `decisions/ADR-0033-determinism-within-content-version.md`）。② **存档面**——一场战斗全程 `CharacterProfile.rng.stream[]` 恰四条，只推进 `name == "combat"` 那一条的 `State` / `DrawCount`，其余三条零变化。③ **退出重进**——任一决策点 D0–D6 退出重进，恢复后的局面与 `rng.stream[combat].state` 与退出前逐字相等，后续推进与不退出时一致。
- **先后手由 `EncounterSpec.FirstSide` 决定，未指定则随机。** `EncounterSpec` 带一个可空字段 **`FirstSide: Side?`**（`null` = 未指定），由 **future-event-service 在物化 eventOption 时写入**——「剧情指定先手」= **内容侧在事件模板（`AdventureEventData`）上直接编排**；**未指定时由本服务用 combat 子流掷**，故同一 seed 复现同一个先后手。**推论 ①：本服务只读该字段、不问来源**——与既有「遭遇参数收进 `EncounterSpec`」（`TurnLimit` / `VictoryRule` / 抽牌与手牌上限覆写）完全同形，**不新增对 future-event-service 的运行时依赖**。**推论 ②：与「不设先后手抽牌差」不冲突**——那条说的是不做补偿（先手 tempo 优势在打满回合比总量的结构下不存在），本条说的是谁先动。**推论 ③：掷点消耗的随机落在 D0 之前**，随参战方组装一并反映进持久化的 RNG `State`，退出重进不会改变先后手。
- **不设 mulligan。** **玩家抽到什么就是什么**——起始手牌一次发到位，没有换牌 / 调度窗口。**推论：开局不多出一个决策点**（连带不多一个存档点），也不多一次 RNG 消耗；开局方差由「定长 10 回合、不设提前终止」吸收，不需要第二条抹平通道。
- **抽牌堆不重洗，抽空即疲劳（承重）。** **抽牌堆抽空即为空，弃牌堆不回流**——没有「抽牌堆空时由弃牌堆重洗补充」这条规则。**抽牌堆为空时每尝试抽一张牌，抽牌方失去 1 点道念**（一次抽 N 张即失去 N 点）。
  - **推论 ①（承重）：道念的结算通道有两条**——**卡牌**（行动阶段打出、经栈结算）与**疲劳**（开始阶段抽牌）。**疲劳入栈**，是一条与触发式异能同款的栈条目（`StackEntryKind.Fatigue`），由 StackManager 压栈、照常 LIFO 结算。
    - **它是完全一等的栈条目：可被监听、可被响应、可被削减至 0。** 「疲劳时」是一个可被触发式异能监听的时点；**扣减量与其余数值同经求值管线聚合得出**（`ModifierTarget.FatigueAmount`），故「免疫下一次疲劳」写成一条 `ForTurns(1)` 的战场条目 + 一条把扣减量削到 0 的静止式修正即可，不需要在抽牌流程里开第二个后门，**也不需要给栈开第二个可寻址面**（`TargetKind` 不含 `StackEntry`，见「API 面」）。
    - **削减至 0 不会让对局不终止：回合上限是双方合计的硬护栏。** `EncounterSpec.TurnLimit`（`Practice` 8 / `Standard` 10 / `Finale` 12）封顶了整场的回合数，胜负在打满后按道念比出；疲劳被削减或被推后只改变失血曲线，改变不了「对局必然在固定回合数内结束」。**疲劳因此不需要「不可削减」这条特权**。
    - **疲劳不产生 `ActionResult`**——它不是玩家动作，没有调用方，没有返回值可给；但它**照常广播一条 `CombatFeedEntry`**，故「我的道念为什么少了 3」在战报里有账可查。
    - **疲劳栈条目的 `sourceInstanceId` / `sourceEntryId` / `abilityId` 三格恒空**（它没有卡牌实例、没有载体条目、没有异能主体），`chosenTargets` 为空、`targetState` 恒为 `Resolved`（疲劳的承受方 = 抽牌方，无需求解）。读档校验 ② 只校验非空值，故三格恒空不触发它。**存档 schema 一格不加**：`stack` 数组本就在 `ActiveCombat` 内，多的只是 `kind` 枚举的一个取值。
  - **推论 ②：下限 0 逐次截断照常适用**——道念为 0 时继续疲劳不产生负值、溢出量不结转（`systems/scoring.md` 的既有规则原样成立，`momentum` 仍是 `>= 0` 的 Integer）。
  - **推论 ③：不以卡组耗尽终止仍然成立**——卡组耗尽不终止战斗，只是从此每回合稳定失血；定长循环的形状不变。
  - **推论 ④：`DeckModule` 没有「弃牌堆整堆回流重洗」这条代码路径**，seeded 洗牌只发生在参战方组装时的一次初洗。**卡牌效果可经 `MoveCard` 把有限张牌置于抽牌堆顶 / 底，插入位置不掷随机**（随机位入堆未开放）；`Selection = Random` 的**源牌**选择照常走 `combat` 子流，那是选哪张的随机、不是插进哪里的随机，两者互不干涉。**抽牌本身因此仍零随机消耗**，「两侧牌序互不打乱」原样成立（见上方「确定性」）。
    - **随机位入堆未开放，界线写在这里：** 「把一张牌随机洗回抽牌堆 / 随机置入抽牌堆第 N 张」才使抽牌堆重新成为战斗中途的随机消耗点。若日后开放，**仍不拆分子流**（消耗照常记在 `combat` 上、`State` 照常随决策点同批持久化）。确定性的顶 / 底入堆不触及这条界线。
  - **推论 ⑤：满手抽不进与疲劳的叠加已定**——两条判定按流程顺序：抽牌堆为空 → 先扣道念（无牌可抽）；抽牌堆非空但满手 → 牌留在抽牌堆、无事发生、**不触发疲劳**（疲劳的触发条件是「牌堆空」，不是「没拿到牌」）。
- **卡牌侧数值。** **起始手牌 4**（双方同值）· **每回合抽 2** · **手牌上限 7** · **卡组规模：两侧皆不设硬限**（储物袋同样不设硬上限）。**推论：卡组规模成为可编排维度**（敌人侧由 `EnemyData` 逐条编排、玩家侧由构筑决定），**其代价由疲劳承接**——小卡组在后期真实失血。敌我对称仍是硬纪律（起手 / 抽牌 / 手牌上限三项完全同值）。取值与推导见 `systems/balance.md`。

Source: `handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md` · `handoffs/2026-07-30-claude-engineering-scope-enemy-manager-and-requirement-breakdown.md` · `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md` · `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md` · `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md` · `handoffs/2026-08-02-momentum-conversion-reward-structure-and-mtg-stack.md` · `handoffs/2026-08-02b-stack-without-interaction-and-three-step-turn.md` · `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md` · `handoffs/2026-08-04b-mtg-loanwords-card-types-and-intent-snapshot.md` · `handoffs/2026-08-05-level-band-stack-save-and-token-free-deck.md` · `handoffs/2026-08-06d-combat-open-questions-mass-closure.md` · `handoffs/2026-08-11c-combat-turn-flow-fatigue-and-card-type-reduction.md` · `handoffs/2026-08-15d-intent-removal-lifespan-cost-visibility-and-design-audit.md` · `handoffs/2026-08-16c-effect-keywords-and-targeting.md` · `handoffs/2026-08-16h-grant-source-assembler-criterion.md` · `handoffs/2026-08-17d-exchange-mechanics-and-transaction-discipline.md` · `handoffs/2026-08-22-finale-failure-is-death.md` · `handoffs/2026-08-22-card-counters-api-and-key-space.md` · `handoffs/2026-08-25-enemy-deck-from-techniques-and-ai.md` · `handoffs/2026-08-25-combat-presentation-and-action-result.md` · `handoffs/2026-08-23g-hidden-stat-combat-boundary-event-backdrop-and-itemized-rewards.md` · `handoffs/2026-08-26b-combat-substream-arbitration.md` · `handoffs/2026-08-26c-enemy-ai-strategy-shape.md` · `handoffs/2026-08-26d-activate-ability-contract.md` · `handoffs/2026-08-27-card-pool-and-reshuffle.md` · `handoffs/2026-08-28-content-artwork-enemy-lines-and-ai-weight-vector.md`

## 战斗存档：`ActiveCombat`

> **共用公理：决策点 = 战斗状态机唯一可以停下来的地方。** 存档 schema、取消语义、决策点清单三者全部由它导出。

**`ActiveCombat` 是 `CharacterProfile` 上一个可空块**：战斗开始时创建、`eventEnd` 收口时置空。它**不进 `pastEvent`**（历史事件只留定稿快照），也不自带随机流状态——它是**事件内的中间态**，寿命短于一次事件。挂 `CharacterProfile` 使 diff 天然落在 sync-service 既定的 diff 单位上，**无需新增同步单元**，且与「每篇章至多一个 ongoing 事件」自洽。

**写入通道 = `ProfileChangeSpec.EventStateChanges`（`Key == ActiveCombat`），与 `activeEvent` 同一列。** 本服务在每个决策点组装一次 `TryApply`，整块绝对置值；`eventEnd` 收口时置空（并入那一次事务）。「战斗内的一切写入经 `ProfileManager`」由此有了确实的通道，不再有例外。分列判据与失败语义见 `systems/architecture.md`「共享核心类型」与 `systems/services/profile-service.md`。

```jsonc
"activeCombat": {                    // null = 当前没有进行中的战斗
  "eventInstanceId": "evt-0042",     // 归属的 EventOption.InstanceId，读档时校验一致
  "encounterId": "enc_wolf_pack",
  "turnLimit": 10,                   // 遭遇参数（Practice 档 8 / Finale 档 12）
  "turnIndex": 3,
  "activeSide": "Character",
  "step": "Action",                  // Start | Action | End
  "sides": [ /* 恰两条 */ ],
  "battlefield": [ /* 单表 + kind */ ],
  "stack": [ /* 数组序即栈序，0 = 栈底 */ ],
  "pending": null,                   // 全局至多一个
  "reward": null                     // null = 尚未进入奖励领取步骤（胜负判定之前）
}
```

**奖励块（`reward`）—— 逐项领取的中途状态**：胜负判定后由本服务写入一次（候选算定），此后每一次领取 / 跳过更新一次，`eventEnd` 收口时随整块 `activeCombat` 一并置空。

```jsonc
"reward": {
  "picks": [                         // 已抽定的可选候选，顺序即面板呈现顺序，不可重排
    { "kind": "Card",      "id": "card_xxx",      "state": "Claimed" },
    { "kind": "Item",      "id": "item_yyy",      "state": "Skipped" },
    { "kind": "Technique", "id": "tech_zzz",      "state": "Pending" }
  ]
}
```

- **`state` 三值枚举 `RewardPickState { Pending, Claimed, Skipped }`。** 三项**各自独立**——不是择一，故不能用「选中的下标」这一个字段表达；也不能只存「已处理几项」，因为玩家可以按任意顺序处置。
- **`picks` 一经写入即不可增删、不可重排**：它就是「退出重进得到同一组选项」这条保证的载体。恢复时按 `state` 重建面板：`Pending` 的项仍可操作，`Claimed` / `Skipped` 的项已成事实、**不允许反悔**（与挂起态恢复同一条纪律——已经发生的事就是发生了）。
- **强制奖励不进本块**：它无需玩家操作、计算时即固定，随 `Spoils` 一次带走。
- **`Claimed` 项到 `Spoils` 的收敛发生在 `D7` 收口**，不是每领一项就提交一次 element ——「计算归战斗、施加归生命周期」原样成立，本块只是记录玩家已作出的处置。

**战斗内随机的状态不落本块，由 `CharacterProfile.rng.stream[Combat]` 承载。** 战斗内随机**直接用 `combat` 子流、不在其上再派生一层**，故不存在第二个随机源，本块里再放一份 `(seed, state, drawCount)` 就是无机制保证相等的第二份真值。它经 `ProfileChangeSpec.RngElements` 在每个决策点那一次 `TryApply` 内与局面同批更新——「凡消耗了子流随机的提交，该子流 `State` / `DrawCount` 必须在同一次原子写内更新」这条不变式对战斗内因此同样是结构保证。

**参战方（`sides`，恰两条，索引序固定为 `sides[0]` = 玩家侧、`sides[1]` = 敌方侧）**：`side` · `momentum` · `manaLimit`（战斗内不变，落它只为读档自洽）· `currentMana`（**回合内消耗量，决策点存档必须恢复它**——它每回合刷满、回合内不结转，战斗外无意义，故它的落点是本字段而非 `CharacterProfile.Status`）· `drawPile` / `hand` / `discardPile`（`CardInstanceId` **有序**序列）· `instances` · `items` · `enemyRef`（仅敌方）。

- **索引序是承重的，不是排版顺序。** 组装时的两次初洗按 `sides[]` 序取 `combat` 子流（见「确定性」），故 `sides[0]` = 玩家侧、`sides[1]` = 敌方侧这一条一旦变动，同一 `CycleSeed` 下的两侧牌序就整体互换。它与 `CardInstanceId` 的确定性发号序（`c#0` 先、`e#0` 后）同向。
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
| `amount` | `int` | **关键字展开参数**：`KeywordRef.Amount` 的落点，默认 `-1` = 无参数（与 `KeywordRef` 的既定约定同值）。**不可由 `keywordId` 推导**——同一关键字可用不同 `Amount` 施加两次，与 `keywordId` 不可由 `sourceId` 推导逐字同构。`BattlefieldEntryTemplate` 侧不带这一格：`Amount` 来自引用侧的 `KeywordRef`，不是模板的属性 |
| `ownerSide` | `OwnerSide` | 「属于谁」只是字段，不是住处 |
| `lifetime` | `EntryLifetime { UntilEndOfTurn, ForTurns, Indefinite }` | 永久物恒为 `Indefinite` 语义（永不被清理） |
| `countdownSide` | `CountdownSide { Owner, Opponent, Either }` | 以谁的结束阶段为节拍；默认 `Owner` |
| `remainingTurns` | `int` | 仅 `ForTurns` 有意义；其余档写 `-1` 并在校验中要求如此 |
| `faceDown` | `bool` | 埋伏（对手只见计数） |
| `counters` | `Dictionary<string,int>` | **运行态计数器**——`Power` 的「本场已触发 N 次」就落在这里。键约定见下 |

> **`Power` 的战斗内运行态不需要独立结构——它就是战场条目的 `counters`。** 这是「`Power` 是战场条目的一档」这条定案的直接后果，**不新增结构**。生命周期三件套的语义与清理判据见 `systems/character-profile/deck/_index.md`。
>
> **未入场的 `Power` 没有计数器落点，这是自洽而非缺口** —— 入场三条与门任一不成立即不入场，它本场也不可能触发。**`PlayerPower`（账号级）的本场计数落在轮回级的 `ActiveCombat` 里不是层级错配** —— 计数的寿命等于这一场战斗，与 `PlayerProfile` 上的持有 / `status` / 残卷语义不同，不构成双写。**敌人的 `Power` 同表承载**（`ownerSide = Enemy`），不另立第二结构。

**`counters` 的键约定（战场条目与 `CardInstanceSave.Counters` 共用同一套，不写成两套）**：

```
键   ::= <abilityId>                 // 该异能的默认计数器（触发 / 启动次数）
       | <abilityId> "#" <子名>       // 须登记在该异能的 AbilityData.CounterNames 内
<子名> ::= ^[a-z][a-z0-9_]*(\.[a-z0-9_]+)*$      // 长度 ≤ 32
// 不变式：键的第一段恒为 AbilityData.Id
// ':' 前缀保留为未来非异能键的命名空间，当前不使用
```

- **`#` 前那一段必须能经 `ContentRegistry` 解析出一条 `AbilityData`。** 键的主体是 `AbilityData.Id` 而非 `PowerId` / `CardId`：`PowerData.Abilities` 可含多个异能，「每场限 N 次」的配额天然挂在**某一个异能**上，以条目为单位记数就写不出「A 每场一次、B 不限」。取具名 id 而非自造裸字符串，是为了让键具备与全库其他跨类型引用同款的**悬空校验能力**。
- **该 `abilityId` 段与其余 `abilityId` 同档，受下方读档校验 ② 约束**（解析不到 → `PushError` + 报出 id），**不开例外**。计数器丢失只影响一次配额，但真悬空意味着内容被删或键被写错，静默丢弃会让一次内容运维动作静默吃掉玩家的配额状态；`Get(id)` 不过滤 `ContentEnabled`，故「战斗中途某条目被线上关闭仍能恢复」这条承诺不依赖于放宽本条。
- **内容条目 `Id` 的字符集不含 `#` 与 `:`**（含加载期校验），故 `#` 分隔在语法上恒成立、`:` 前缀与异能键天然不相交。该约束是内容 id 的通则，权威在 `systems/common-properties.md`「稳定 Id 键」，此处不复述。
- **子名须登记在 `AbilityData.CounterNames` 内**，读写两侧都校验（未登记 → `PushError` + 抛）。**正则拦不住拼错**——拼错的名字通常仍然合法，而一个静默开出来的新计数器会让配额闸门永远读到 0，「每场限 N 次」就此静默失效、且只在线上被玩家发现。读侧同样拦，否则「读到 0」与「键根本不存在」在闸门处无法区分。字段与加载期校验见 `systems/character-profile/deck/common-properties.md`。
- **允许下划线**是刻意的：全库其他 id 段一律 `snake_case`，禁止 `_` 会造出第二套书写习惯，收益仅是名字略短。
- **值域 `>= 0`；为 0 的键不写入**（等价于「没记过」），与 `CardInstanceSave.Counters`「空则整字段省略」同向——省下的是每个决策点 diff 里的一堆零。
- **合法的键形态只有这一种，`counters` 不承载非异能计数。** 「关键字状态叠了几层」是**可重算的派生量**——每次 `ApplyState` 产出一条独立的 `Transient` 条目，层数 = 战场上同 `keywordId` + 同 `ownerSide` 的条目计数，一次遍历即得，依「可重算的东西不进存档」判据不该有独立落点。合并成「单条 + 层数」则是语义损失：生命周期三件套逐条独立倒数，合并等于强制多次施加共享同一个过期时刻。故 `Transient` 条目没有 `AbilityData` 主体不构成缺口——它压根不需要计数器；而第一类键覆盖的**配额**天然挂在某一条异能上，关键字侧同样如此（`BattlefieldEntryTemplate` 里就是 `AbilityData[]`）。
- **启动式异能的「每场限 N 次」配额读写的就是第一类键（无 `#` 段），`ActiveCombat` 因此一格不加、空迁移。** 配额语义是**每载体条目、每场**：同一条 `AbilityData` 挂在两个条目上 ⇒ 两份独立计数（`Power` 只有一个条目故无差别，阵法多份同名时每份各有配额）。**清理动作也为零**——条目离场 `counters` 随之消失、`activeCombat` 在 `eventEnd` 整块置空，本场配额随战斗自然清零，与「有过期时刻的计数落战场条目」这条归属判据自洽。跨场的「本轮回限 N 次」没有过期时刻，按同一判据不落此处，当前无此需求、不预铺。配额字段与加载期校验见 `systems/character-profile/deck/common-properties.md`，闸门与扣费见下方「API 面」。
- **`KeywordRef.Amount` 落条目的 `amount` 一格，不进 `counters`。** `counters` 的语义是**计数**（值域 `>= 0`、为 0 不写入、单调 bump），`Amount` 是**参数**——「为 0 的键不写入」对它是错误语义，且键空间一旦承担两族语义，此后每次读键都要先分辨它属于哪一族。

**栈条目**：`stackEntryId` · `kind { PlayedCard, TriggeredAbility, ActivatedAbility, Fatigue }` · `controllerSide`（**决定这次目标选择是否产生决策点**）· `sourceInstanceId` · `sourceEntryId` · `abilityId` · `chosenTargets`（`TargetRef[]`，按槽位顺序）· `targetState { Resolved, AwaitingChoice }`。**栈内位置由数组顺序承载，不落 `position` 字段**——索引即位置，另存一个序号是可以不一致的冗余。

**挂起态 `pending`（全局至多一个）**：`{ stackEntryId, slotIndex }`。结算是 LIFO 单线程推进的，不可能同时有两处等玩家输入；用一个顶层可空字段比在每个栈条目上找更明确，读档时「要不要进选目标态」是一次判空。**合法目标集不落存档**——恢复时按当前局面重算。

**战斗内道具运行态**：`readonly record struct CombatItemSave(string ItemId, int UsesThisCombat)`。**只落「本场已用几次」**：本场可用道具列表本身是**派生的**（玩家侧按 `UsableScene` 筛储物袋，敌人侧取 `EnemyData` 持有列表），而古宝的总剩余次数**权威在 PlayerProfile**（使用次数即时写，战斗内再存一份就是双写）。`UsesThisCombat` 仍必须存——**本作确实存在「每场限用一次」这类本场配额效果**，它是唯一的运行态载体，**它比对的上限是内容侧的 `ItemData.MaxUsesPerCombat`**（`-1` = 不限），不是 Profile 侧的总剩余次数。

- **两级道具在存档面上完全对称，`CombatItemSave` 一个结构覆盖两级。** 法宝一侧的 `CharacterItem.Charges` 同样即时写 `CharacterProfile`、不攒到收口（两级共用 `ProfileChangeSpec.ItemElements` 这一条写入通道；权威在 `systems/character-profile/item/_index.md` 与 `systems/services/profile-service.md`，此处不复述）；古宝一侧见 `systems/player-profile/player-item/_index.md`。`ItemData.Scope` 是内容侧静态字段，`ItemId` 已唯一决定它是哪一级，故 `CombatItemSave` **不带 `Scope` 字段**（与「`CardType` / `Subtypes` 不落存档」「栈内位置不落 `position`」同款判据）。
- **敌人侧同样用 `CombatItemSave`，且这是 `UsesThisCombat` 的第二个不可替代用途。** 敌人没有储物袋、道具来自 `EnemyData` 持有列表，没有 Profile 侧的 `Charges` 可写，故**敌人道具的总量上限只能靠 `UsesThisCombat` 对着 `ItemData.Charges`（上限 / 初值）比**；`MaxUsesPerCombat` 那道本场配额闸对敌人同样成立，两道闸取更严者。

**不落存档的可重建项**（沿「可重算的东西不进存档」判据）：`isProtected`（`kind == PermanentPower` 即 `true`）· **触发器注册面**（由 `sourceId` 解析出的 `AbilityData` 重建，「谁在监听哪个时点」是纯派生数据）· **`Power` 的入场本身**（由两个 Profile 的持有列表 + `status` + `UsableScene` + **`CharacterProfile.disabledAbility`** 重放；禁用表就在 `CharacterProfile` 上、随存档走，故重建仍是确定性的，**不需要给 `ActiveCombat` 新增任何字段**）· **「本场可用道具」列表**（玩家侧按 `UsableScene` 筛储物袋，**并过滤掉在 `disabledAbility` 内的 `Id`**；敌人侧取 `EnemyData` 持有列表）· 合法目标集。

**读档校验（强制，六个检查点全部命中）**：① `eventInstanceId` 与当前进行中的 `EventOption` 不一致 → `PushError` + **拒绝恢复该战斗**；② `cardId` / `sourceId` / `abilityId` 解析不到 → `PushError` 并报出 id（**注意 `Get(id)` 不过滤 `ContentEnabled`**，故战斗中途某条目被线上关闭仍能恢复——这正是「读取侧不过滤」的用武之地）；③ `pending.stackEntryId` 在 `stack` 中找不到 → `PushError`（内部一致性破损）；④ **三区 `Id` 序列的并集 ≠ `instances` 全集 → `PushError`**（闭集不变式的自校验，是「无凭空生成的牌」买来的一条免费断言）；⑤ `counters` 某键的值为负、或 `UsesThisCombat < 0` → `PushError` + 抛，带 `entryId` / `cardInstanceId` / `itemId`（`counters` 两处落点都覆盖；不可能态，与 ③ ④ 同属内部一致性破损）；⑥ `CombatItemSave.ItemId` 不在该侧「本场可用道具」的重建结果内 → `PushWarning` + **丢弃该条**、不阻断恢复（多半是 `disabledAbility` 或 `UsableScene` 中途变化；「本场可用道具」本就是按当前状态重建的派生项，丢弃一条已不可用道具的计数无副作用）。

> **`counters` 键的 `abilityId` 段走 ② 而非 ⑥。** 两者形态相似但语义不同：⑥ 丢弃的是一条**内容仍在、只是本场不再可用**的记录；键解析不到则是真悬空（内容被删或键被写错），与 `sourceId` 悬空同档致命。

**版本化**：本块是新增字段 → 随下一次 schema bump 一起走（当前无线上存档 = 空迁移）。

**本块新增的字段只有战场条目的 `amount` 一格** —— 计数器与道具运行态全部落在既有的 `counters` / `Counters` / `items` 上。`amount` 的量级为 **≤ 4 字节 / `Transient` 条目**，相对单次决策点 2–4 KB 的既有量级可忽略；当前无线上存档 ⇒ **空迁移**，故下述量级与迁移面不受影响。**这一格是在关键字清单为空时先行铺下的**，取舍明确：加它的成本此刻恒为零，不加的成本在第一条带 `Amount` 的 `State` 关键字落地时可能已不为零（届时 schema 或已上线，加格不再是空迁移）。

**已知代价**：单次决策点 diff 量级 **2–4 KB**，一场约 31 个决策点 ≈ 93 KB 本地写（毫秒级原子写，移动端可承受）；`instances` 与三区序列有冗余（**接受**，换来的是「实例表即闭集全集」这条可断言的不变式）；若实测序列化成本超预算，可退化为「战斗内只写本地、`Immediate` push 仅在进入战斗前 / 收口 / 应用失焦」——**这是纯工程优化，不改 schema**。

### 决策点清单

> **判据：决策点 = 「战斗状态机即将停下来等玩家输入」的时刻，且该时刻之前消耗的随机已全部反映在持久化的 RNG `State` 里。** 这条判据一次性解释了三件事：为什么敌人回合内部不落点（不等玩家输入）、为什么挂起态是决策点（正是在等玩家输入）、为什么奖励的每一次领取 / 跳过是决策点（它产生了重算不出来的新状态，且流程在此停下等下一次输入）。

| # | 决策点 | 精确时刻 | push policy |
|---|--------|---------|-------------|
| **D0** | 战斗开始 | 参战方组装完成（含 `Power` 入场）、第一个开始阶段之前 | `Immediate`（复用既定的「进入战斗前」flush 点）；**flush 失败不阻塞进入战斗** |
| **D1** | 行动阶段开始 | 玩家回合的开始阶段全部走完（mana 恢复 → 触发结算完 → 抽牌完），栈为空 | `Debounced` |
| **D2** | 一次出牌 / 启动 / 用道具结算完毕 | 栈**再次清空**、控制权回到行动阶段 | `Debounced` |
| **D3** | 玩家回合结束 | 结束阶段清理完，移交对手之前 | `Debounced` |
| **D4** | 进入挂起态 | 栈上某条目 `targetState = AwaitingChoice`、`pending` 写入那一刻 | `Debounced`（应用失焦时另由既定 `Immediate` 规则兜底） |
| **D5** | 敌人回合结束 | 敌人整个回合执行完（含其栈全部结算完）、交回玩家之前 | `Debounced` |
| **D6** | **一次奖励领取 / 跳过** | 玩家对某一项候选按下领取或跳过、`reward.picks[i].state` 由 `Pending` 转定那一刻 | `Debounced` |
| **D7** | 战斗收口 | 全部候选处置完毕（无 `Pending` 项）+ `Spoils` 收敛完成 | 并入 `eventEnd` 的**单一事务存档点**，不单独落点 |

**明确不是决策点**（同样重要）：弹栈结算的**每一次**弹出（除非因此进入 D4）· **敌人回合内部**的任何一步（玩家在其中没有输入，D5 一个点即覆盖整个敌人回合，它是一段可确定性重放的区间）· **奖励面板的打开本身**（打开时 `picks` 已由胜负判定那一步算定并写入，这一刻没有新状态产生——与「Exchange 面板打开」同形）。

**每个决策点的提交形态：** `TryApply(EventStateChanges[ActiveCombat = 当前局面] + RngElements[combat 子流终态])` —— D0–D6 各一次，**不新增存档点类型**（这七个点本就是既定存档点），且照常**不计**软阻塞闸门。**D7 并入 `eventEnd` 的那一次**（`ActiveCombat = null`），既定的「收口不单独落点」原样成立。**D6 一场至多 3 次**（候选恒 3 项、每项至多处置一次、不允许反悔），对下方密度口径的增量可忽略。提交前由组装方比对 SeedManager 的未清账子流与 `spec.RngElements`（`#if DEBUG`），见 `systems/services/life-cycle-service.md`。

- **密度 ≈ 31 个决策点 / 场**（10 回合、玩家 5 个回合、每回合出 2~3 张牌）。**保留 D2**——它是「退出重进得到同一局面」这条承诺在最自然位置的兑现，**不作为超预算时的第一削减对象**——该承诺在强制在线 · 云端权威下是玩家对存档的基本信任。若实测超预算，先动 push 频率而非存档点本身（存档点与 push 已解耦）。
- **软阻塞闸门不受影响**：`sync-service` 的缓冲上限口径为「未同步的**事件级**存档点 ≥ 3」，**战斗内 D0–D5 照常写本地、照常防抖 push，但不参与软阻塞判定**——否则每场战斗的第三个决策点就会触发模态。**连带：D0 的 `Immediate` flush 失败也不触发阻塞**——同一个点不能一边被排除在闸门计数外、一边又能独立挡住玩家；且此时 `SelectCost` 已施加，挡住 = 付了成本却拿不到事件。「flush 是尝试、闸门是状态」见 `sync-service.md`「`Immediate` flush 的失败语义」。
- **战斗前确认页的「进入战斗」按钮不是决策点。** 判据是「这一刻有没有新状态产生」——按下它不产生任何新状态，局面早已由「择一进入」那一次提交定死；它与「Exchange 面板打开 / Research 面板打开」同形，都是呈现层的一次动作而非分叉。故清单不为它加行，`D0` 的 `Immediate` flush 点仍恰好就是「进入战斗前」那一次。确认页的规格见 `ux/screen-flow.md`。
- **需要选目标的触发式异能按稀缺配额编排**：占全部触发式异能 **≤ 10%**（加载时统计 + `PushWarning`）、一场 `Standard` 档战斗期望进入挂起态 **1~2 次**（编排口径，不可机械化）。频度天然低——玩家**主动出牌**的目标在打出时就由 UI 按 `slotIndex` 顺序一次收齐（`PlayCard(card, targets)`，入栈时 `targetState = Resolved`），挂起态**只**来自「压进去的东西在结算时回头问一句『指谁』」；敌人侧的目标选择由 EnemyManager 自行决定、不产生决策点。**稀少改变的是性能预算，不是正确性要求**：D4 必须在清单里。连带成立——**挂起态存档不做任何专门优化**，`ActiveCombat` 全量序列化足够，**栈的增量写入不做**。

### 挂起态的恢复与取消

- **恢复回到该选择点，栈原样挂起，不允许反悔。** 回退到更粗的边界意味着重放已弹栈结算的条目，而 RNG `State` 已随之前进——要么局面分叉，要么就得回滚 `State`，那等于给玩家开了「不满意就退出重掷」的窗口。与「`SelectCost` 不回滚」同一条纪律：**已经发生的事就是发生了**。且若恢复只能回到更粗的边界，「存挂起态」本身就没有存在意义。
- 恢复流程与正常推进路径**共用同一段代码**：读 `ActiveCombat` → 重建实例表 / 战场 / 栈 → 重放派生项 → `pending != null` ? 按当前局面重算合法目标集并直接进入选目标态 : 按 `step` 进入对应阶段。
- **`ct` 只在决策点被观察**（`AdvanceToNextDecisionPoint()` → `PersistDecisionPoint()` → `ThrowIfCancellationRequested()` → `WaitForPlayerInput()`）。三条推论：**取消点与存档点永远重合**（对齐问题因此**不存在**，而不是「靠约定去对齐」）· **中间态永不需要持久化**（结算走到一半被取消是不可能的）· 等待输入期间收到取消则落在 D1/D2/D4 之一，恢复时回到同一处等待。这与「结算循环必须可挂起可恢复」不冲突——**可挂起的位置就是决策点，两者是同一个集合**。
- **UX 硬要求：选目标态必须自解释**（交代是哪张牌 / 哪个异能在要求选目标、它要做什么），不能依赖玩家的短期记忆——玩家可能隔几小时才回来。见 `ux/combat-ux.md`。
- 取消的触发方清单与 `AdvanceStage.Cancelled` 见 `life-cycle-service.md`。

Source: `handoffs/2026-08-22-card-counters-api-and-key-space.md` · `handoffs/2026-08-26b-combat-substream-arbitration.md` · `handoffs/2026-08-26d-activate-ability-contract.md` · `handoffs/2026-08-28-item-use-effect-face-and-carrier-kind.md`

## 效果流水线（一条栈条目被弹出后的结算）

> **主持者 = `EffectProcessor`**（`combat-service > StackManager > EffectProcessor > handler` 四级，层级词表见 `systems/architecture.md`）。定义体的形态（`EffectData` 子类树 · `EffectCondition` · `KeywordData` 展开 · `StaticModifierData`）见 `systems/character-profile/deck/common-properties.md`，此处只定**结算时序**。

| 阶段 | 做什么 |
|---|---|
| **1 重检目标 / 挂起** | 逐槽位按「合法目标集」的四条过滤重检 → 非法槽位置 `FizzledSlots` 对应位。挂起三条与门成立 ⇒ 写 `pending`、落决策点 `D4`、等 `ProvideTarget`（恢复后从本阶段同一槽位继续）。全部有目标的槽位非法 ⇒ 整条不结算，直接跳到阶段 5（`Declared` 记 0） |
| **2 关键字展开** | `Keyword != null` 的 element 按 `KeywordData` 就地展开（`Action` 内联进 element 序列 / `State` 供 `ApplyState` 消费），`Amount` 哨兵在此刻代入。展开产物不再展开（**恰好一层**） |
| **3 数值求值** | 每个数值参数经求值管线聚合（遍历战场上匹配的静止式修正 → 加法层 → 乘法层）得出 `Declared`。**整条一次求完** |
| **4 逐 element：条件 → 施加** | 按 element 顺序，逐条先求它的 `Conditions`（AND；不满足则整条跳过、`Declared` 记 0、**不置 `FizzledSlots`**），满足则立即施加该原语。`ModifyMomentum` 在此按下限 0 截断得 `Actual` |
| **5 收口** | ① 默认 counters +1（仅当阶段 4 实际生效）② 收集本次引发的触发式异能、按 element 顺序压栈 ③ 广播一条 `CombatFeedEntry`（`FizzledSlots` / `MomentumDelta` / `CauseEntryId`）④ 交回 StackManager 判断是否进 `D2` |

**六条须写成规则、不是实现细节的：**

1. **挂起点唯一 = 阶段 1。** 阶段 2–5 恒不挂起。这正是「结算走到一半被取消是不可能的 ⇒ 中间态永不需要持久化」得以成立的结构依据（见「挂起态的恢复与取消」）。
2. **element 顺序是规则**（与 LIFO、「加法先于乘法」同款处理）：同一条 element 序列内先后可观测——**前一条改了道念，后一条的条件读到的是改后的值**。
3. **数值一次求完、条件逐条就地求，这两个时机刻意不同。** 数值在阶段 3 整条冻结，否则一条修正在序列中途被移除时，同一张牌的前后两个 element 会吃到不同的修正，语义不可预期、也无法在卡面上表达；条件则读**当前**局面，因为「打完这一下之后还成不成立」正是条件想表达的东西。**卡面措辞须让玩家读得出这条差别**（条件句写在它所修饰的那一句里，不写成整张牌的前置）。
4. **展开先于求值与条件**（阶段 2 排在 3、4 之前）：关键字模板内的 element 同样带基类的 `Conditions` 与数值参数，展开排在后面它们就永远不会被求值。
5. **`Evaluate` 与条件求值无副作用；`Apply` 是唯一允许写状态的地方。** `IEffectHandler` 因此分成两段：`int Evaluate(ctx)`（阶段 3，纯函数）与 `void Apply(ctx, evaluated)`（阶段 4 的施加半边）。**任何把写入塞进 `Evaluate` 或塞进条件求值的实现都会让 AI 试算污染真实局面**，且因 AI 每回合试算多个候选，污染是静默且累积的。**原语内的随机同理**：一律取 `combat` 子流，但**只能在 `Apply` 内取**；`Evaluate` 遇到随机取标称值。否则 AI 每试算一次就推进一次 `State`，「同一 `CycleSeed` 复现同一场战斗」当场失效。
6. **单次动作链的栈条目总数上限 N：超限即中止链路并 `PushError`。** 一次玩家动作引发的连锁（含触发的触发）压栈总数计入同一个计数，达到 N 即停止继续压栈、本次动作按已结算的部分收口。**它是进程护栏不是玩法闸**——它只阻止结算不返回，不限制任何设计面：玩家主动发起的每次启动都是一条新链，各自重新计数。**N 落 `CombatRulesData`**（数值不硬编码），取值归内容扩充后的统计校准（`systems/balance.md`）。

**槽位在栈条目层扁平化编号。** 一个栈条目的槽位序列 = 它**全部 element 的 `TargetSlots` 按 element 顺序拼接**后的扁平序列，`slotIndex` 是这条扁平序列的下标；`pending.slotIndex` / `PendingTargetRequest.SlotIndex` / `CombatFeedEntry.FizzledSlots` 的位序全部同此。运行时不变式：`chosenTargets.Length == Σ(element.TargetSlots.Length)`。

- **`FizzledSlots` 是 `int` 位掩码 ⇒ 单个栈条目的槽位总数硬上限 32**（加载期 `PushError`），另配 `> 4` 的 `PushWarning`（清单式软检查，与 `IgnoresProtection` 清单同构）。多目标牌在定长对局 + 竖屏下本就该稀少。

**求值管线不只在阶段 3 被调用。** 它是一个可复用函数——「所有数值在**使用时**按战场上的静止式修正聚合得出」——阶段 3 只是它在效果参数上的那一次调用。另两处消费点：**出牌 / 启动的费用预判**（`CardManaCost`，`BattlefieldEntryView.ActivatableAbilities` 的灰态即读它，不读未修正的原值）与**抽牌流程的疲劳扣减量**（`FatigueAmount`）。可修正量的清单见 `systems/character-profile/deck/common-properties.md`。

**阶段 5 的「默认 counters +1」只对 `abilityId` 非空的栈条目成立。** `counters` 的键空间闭合于 `<abilityId>[#<子名>]`，而 `PlayedCard` / `Fatigue` 与**用道具**产生的栈条目都没有异能主体（疲劳的三格恒空；道具的使用效果不挂宿主 `AbilityData`）⇒ 它们没有默认计数器可 bump。不写明这一条，实现会撞穿闭合键空间。

Source: `handoffs/2026-08-27-ability-primitive-grammar.md` · `handoffs/2026-08-28-item-use-effect-face-and-carrier-kind.md`

## 管理器

| manager | 职责 |
|---------|------|
| **TurnManager** | **定长回合**的状态机（`Standard` 档 = 10 回合、双方各 5，交替；`Practice` / `Finale` 档可改写长度）。每个回合走**三步**：**开始阶段**（归属方 mana 恢复至 `manaLimit` → 触发「回合开始时」→ 抽牌）→ **行动阶段**（唯一出牌阶段，只有归属方出牌；**无优先权内循环**）→ **结束阶段**（触发「回合结束时」→ 清理回合内状态）→ 交给另一方。**三步是归属方的流程，双方不同时走。** 打满后做胜负判定（`Standard` 档 = **道念高者胜**，相等 = `Draw`，只发 `baseReward`），随后走**奖励计算与可选奖励选择**再收口。**它只管「轮到谁、走到哪一步」——栈的持有与结算归 StackManager** |
| **CharacterManager** | 玩家侧参战方：角色的对战状态、其卡组、**本场可用道具**、出牌通道；**监听玩家操作** |
| **EnemyManager** | 敌人侧参战方：敌人实例与状态、其卡组、**本场可用道具**（来自 `EnemyData`）、**AI 行为选择**；**代理操作**。内部不再细分职能。决策时读 `ViewerSide` 为本侧的 **`CombatSnapshot`**（亦可读对手的埋伏计数，但那是算法的自由，不是机制要求），并按 `EnemyId` 取模板上的 **`AiProfile`**，无则用**通用兜底权重**（兜底算法 `ChooseAction` 实现在本 manager 内，见「意图」）。**不受「回合级一次性规划」约束** |
| **BattlefieldManager** | **战场（battlefield）**：场上正在生效的条目、**触发器注册面**（谁在监听哪个时点）与清理。条目分**三档**：**永久物 · 常规**（阵法结算后落场，可被针对，永不被结束阶段清理）· **永久物 · 受保护**（`Power`，开局入场，`IsProtected = true`，唯一后门是效果侧的 `IgnoresProtection`）· **非永久条目**（持续状态，带生命周期标记，结束阶段清理标记为「回合内」的那些）。**静止式异能是一条与栈无关的写入路径**（载体一进场即生效、一离场即失效）。**单一战场记录，不分双场区容器**——条目自带 `OwnerSide` / `IsProtected` / `SourceId`，呈现层按 `OwnerSide` 分区渲染 |
| **StackManager** | **栈（stack）**：压栈、**LIFO 结算**、连锁触发的解决顺序。**被触发的能力由它压栈**（与触发挂在哪个载体上无关）；**疲劳同样由它压栈**（`StackEntryKind.Fatigue`，故「疲劳时」可被监听、可被响应，其扣减量可被削减至 0）；结算产生的持续效果落到 BattlefieldManager |

**运行态计数器的消费面按「谁持有谁读写」分落两处，共四个方法、不新增 manager 也不新增事件。** 「每场限 N 次」的闸门若没人读，配额就只是存了而没人管。落点判据是**读写落在持有它的那个 manager 的既有职责内**：战场持有场上的全部准确数据 ⇒ 条目计数落 BattlefieldManager；实例表 `instances` 是 `sides[]` 的字段、战场并不持有不在场的牌（手牌 / 抽牌堆 / 弃牌堆里的牌照样能带本体计数器）⇒ 实例计数落**参战方**。

```csharp
// BattlefieldManager —— 战场条目一侧
int  GetCounter(string entryId, string counterKey);          // 缺键 → 0
void BumpCounter(string entryId, string counterKey, int by); // 仅在异能实际生效时调用

// 参战方接口（CharacterManager / EnemyManager 共享）—— CardInstanceSave.Counters 一侧
int  GetCardCounter(string cardInstanceId, string counterKey);          // 缺键 → 0
void BumpCardCounter(string cardInstanceId, string counterKey, int by);
```

- **两个计数器空间的归属判据直接复用既有那条，不新造：有过期时刻的 → 战场条目；无过期时刻且属于这张牌本体的 → `CardInstance`**（权威见 `systems/character-profile/deck/_index.md`）。即**随条目消亡的计数落 `entry.counters`，随牌本体、整场存活的计数落 `CardInstanceSave.Counters`**。一张 `Enchantment` 同时拥有两个计数器空间不是重复：条目离场即消失（「这个永久物在场期间触发了几次」），实例计数整场存活（「这张牌本场被打出过几次」，即便它已回到弃牌堆）。
- **卡牌一侧不做同名重载，取不同方法名。** 两族签名同为 `(string, string)` / `(string, string, int)`，重载在编译期完全无法区分，把 `entryId` 传进卡牌一侧会编译照过、运行期静默开一个新计数器。不同方法名是唯一能让编译器帮上忙的形态。
- **实例计数落两侧共享的参战方接口，敌人侧同样覆盖**（`e#…` 系列实例同样可带本体计数器），与「`DeckModule` 每个 character / enemy 一份」同构。
- **寻址不需要任何新状态。** 调用点在 StackManager 的结算收口回调，栈条目自带 `controllerSide` 与 `sourceInstanceId` ⇒「找哪一侧的实例表」是现成信息。**不按 `c#` / `e#` 前缀解析实例 id**（那会把发号格式变成隐式契约），**也不建跨侧的全局实例索引**（那是第二份持有关系）。
- **失败语义（形态 A，见 `systems/architecture.md`「API 契约总则」）：** `cardInstanceId` / `entryId` 不在对应表中 → `PushError` + 抛（闭集不变式已保证它必然存在，找不到 = 内部一致性破损）；`counterKey` 缺失（读）→ 返回 `0`；`by` 使计数降到负数 → `PushError` + 抛（读档校验 ⑤ 在写入侧的提前拦截）；`counterKey` 的 `abilityId` 段解析不到、或 `#` 段未登记 → `PushError` + 抛。

- **计数只在异能实际产生效果的那一刻 +1 —— 弹栈结算成功之后，两族计数器同一时机。** `BumpCounter` 与 `BumpCardCounter` 的**调用点唯一且相同**，落在 StackManager 的结算收口回调里，而不是压栈处或付费处。判据：**一条没结算的异能不该吃掉配额**，而 fizzle（全部有目标的槽位都非法 → 整条不结算）发生在弹栈结算那一刻，晚于压栈与付费。**本体计数不另开「压栈成功即 +1」的第二时机**——那会把「什么时候算数」变成逐计数器记忆的事。
- **启动代价（`ManaCost`）已付但 fizzle 的启动式不吃配额，成本仍不退。** 与「`SelectCost` 不回滚」同一条纪律：已经付出的就是付出了，但没有发生的效果不记账。
- **配额闸门查两次：宣告 / 触发注册时查一次，结算时再查一次。** 因为计数在结算后才 +1，宣告时读到的是旧值；**连锁触发**（多条同源触发同时压栈）能在同一次结算链内全部通过第一道闸门，结算时的第二次查询让链内第二条到达时读到已 +1 的值、自然被拦。一次额外查询、无新状态——不为配额引入「已预留」这类第二份运行态。
- **内容侧纪律：「每场限 N 次」类异能必须在效果定义里引用自己 `AbilityData` 的稳定 `Id` 作键，不得自造裸字符串。**

**`DeckModule`（第三级）不是平级 manager。** 抽牌堆 / 手牌 / 弃牌堆的流转与 seeded 洗牌由 CharacterManager 与 EnemyManager 各自持有的 `DeckModule` 承担，**每个 character / enemy 一份**。它与那套共享的参战方接口是同一件事的两面。

**「本场可用道具」是与 `DeckModule` 平级的第三级持有物，且不称储物袋。** 参战方各持一份：**玩家侧 = 储物袋中 `UsableScene` 含 `InCombat` 的筛选结果**（储物袋跨两层 ⇒ 这条筛选天然同时覆盖法宝与古宝，与「战斗道具区同时呈现两级」一致，不需要第二条取数路径），**敌人侧 = `EnemyData` 的道具持有列表**。**储物袋是跨两个持久层的呈现视图（同时呈现轮回级法宝与账号级古宝、跨战斗内外存在、容量不设硬上限），不是战斗概念**——敌人没有储物袋却同样持有道具，正说明容器与本场视图必须分开。

**参战方组装阶段读两个 Profile。** 组装时除卡组与道具外，还要把 **CharacterProfile 的神通列表**与 **PlayerProfile 的法则列表**按**三条与门**——「`status == 开启` 且 `UsableScene` 含 `InCombat` 且**不在 `CharacterProfile.disabledAbility` 内**」——过滤后**作为 `CardType.Power` 注册进战场**，入场早于第一个开始阶段。**这是本服务第一次需要读 PlayerProfile。** 三个字段**正交不可合并**：`UsableScene` 是内容侧静态属性、`status` 是账号级玩家开关、`disabledAbility` 是**轮回级外部抑制**（见 `systems/character-profile/power/_index.md`）。**同一条禁用过滤也作用于「本场可用道具」的派生**（被禁用的法宝 / 古宝不进该列表，储物袋里仍在）。

**栈与战场是两个区，不是一个。** 栈 = **等待结算**的队列；战场 = **已结算并正在生效**的东西。结算的完整路径：**打出 → 入栈 →（LIFO）弹出结算 → 效果施加 →（若是持续效果）落到战场**。

Source: `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md` · `handoffs/2026-08-04b-mtg-loanwords-card-types-and-intent-snapshot.md` · `handoffs/2026-08-10c-ability-disable-replacement-and-player-statistics.md` · `handoffs/2026-08-17h-profile-field-schema.md` · `handoffs/2026-08-19-profile-change-spec-gaps.md` · `handoffs/2026-08-22-combat-runtime-counter-persistence.md` · `handoffs/2026-08-22-card-counters-api-and-key-space.md` · `handoffs/2026-08-25-combat-presentation-and-action-result.md` · `handoffs/2026-08-26-storage-pack-two-layer-view-and-combat-holdings.md` · `handoffs/2026-08-26c-enemy-ai-strategy-shape.md` · `handoffs/2026-08-26d-activate-ability-contract.md`

## API 面（契约）

> 总则与共享类型见 `systems/architecture.md`「API 契约总则」。本服务**纯本地**，永不跨进程边界；`RunCombatAsync` 是形态 C（跨多帧、由信号推进），其余为形态 A。

| 方法 | 形态 | 完整签名 | 失败语义 |
|------|------|----------|----------|
| 打一场 | **C** | `Task<CombatResult> RunCombatAsync(EncounterSpec encounter, CancellationToken ct)` | 未知 `EncounterId` = 坏数据 → `PushError` + 抛；胜负是**结果**不是失败 |
| 出牌 | A | `ActionResult PlayCard(CardInstance card, IReadOnlyList<TargetRef> targets)` | 业务失败（mana 不足、目标非法、槽位数不匹配）→ `ActionResult`，绝不抛 |
| **用道具** | A | `ActionResult UseItem(string itemId, IReadOnlyList<TargetRef> targets)` | 业务失败（不在本场可用道具内、本场配额用尽、充能耗尽、目标非法）→ `ActionResult`，绝不抛 |
| **启动异能** | A | `ActionResult ActivateAbility(string entryId, string abilityId, IReadOnlyList<TargetRef> targets)` | 业务失败（不是自己回合 / 不在行动阶段 / 栈非空 / mana 不足 / 条目或异能不可启动 / 本场配额用尽 / 目标非法或槽位数不匹配）→ `ActionResult`，绝不抛；`abilityId` 经 `ContentRegistry` 解析不到 → `PushError` + 抛 |
| **提供目标** | A | `ActionResult ProvideTarget(TargetRef target)` | 非法目标 → `ActionResult { Accepted = false, Rejection = IllegalTarget }`，绝不抛；服务端仍以 `LegalTargets` 为准校验 |
| 结束回合 | A | `ActionResult EndTurn()` | 业务失败（不是自己回合、栈非空）→ `ActionResult`，绝不抛 |
| 战斗态 | A | `CombatSnapshot Snapshot { get; }` | 只读视图，供 ViewModel 组装；**必含双方道念**；**按变更广播 + 缓存**，不是每次访问现组装 |

```csharp
public sealed record EncounterSpec(               // sealed record 而非 struct：字段多、含引用类型、落存档、非热路径
    string            EncounterId,                // 溯源；战斗类事件下 = EventOption.InstanceId
    CombatTier        Tier,                        // Practice | Standard | Finale —— 篇章边界 / 残卷 / 重试模型的判据；战斗规则本身不由它派生
    EnemyInstance     Enemy,                      // 单数：本作不存在多敌人场景；恒非空（三档一律有敌人）
    int               TurnLimit,                  // 双方合计回合数；Practice 8 / Standard 10 / Finale 12
    VictoryRule       VictoryRule,
    Side?             FirstSide,                   // 先手方；null = 未指定 → 由 combat 子流掷。内容侧在事件模板上编排先手时，由 future-event-service 物化写入
    int?              InitialDraw,                 // ↓ 覆写组：null = 取 CombatRulesData 默认值
    int?              DrawPerTurn,                 //   双方同用一组值（起手 / 每回合抽牌 / 手牌上限）
    int?              HandLimit,
    int?              EnemyManaLimit,              //   仅敌方；null = 取 CombatRulesData 的 EnemyManaLimit
    string            RewardPoolId,               // 可选奖励抽取池
    ProfileChangeSpec BaseReward);                // 本场 baseReward，物化时定稿

public readonly record struct VictoryRule(
    int  WinMargin,          // 角色须领先的点数。Standard = 1（严格高于）、Practice = 0、Finale = 0
    );                       // d >= WinMargin → Victory；d == WinMargin - 1 且 WinMargin >= 1 → Draw；否则 → Defeat
                             // ⇒ WinMargin == 0 的两档二值化，Draw 只在 Standard 可达

public readonly record struct CombatResult(
    CombatOutcome     Outcome,            // Victory | Draw | Defeat（Draw = 道念相等，只发基础奖励；仅 Standard 可达）
                                          // Tier == Finale 且 Outcome == Defeat ⇒ 角色终结（见 life-cycle-service 的终态判定旁路）
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

public sealed record CombatSnapshot(              // 只读视图，供 ViewModel 组装与 AI 决策；不落存档
    Side         ViewerSide,                      // 「己方」按谁解释：UI / 决策点存档 = Character，AI = 该敌人的 OwnerSide
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
    IReadOnlyList<string> HandCardInstanceIds,    // 仅 viewer 己方非空；对侧恒为空
    int    DrawPileCount, int DiscardPileCount,
    int    AmbushCount,                           // 双向对称：只给计数不给内容
    IReadOnlyList<string> UsableItemIds);         // 本场可用道具；仅 viewer 己方非空

public readonly record struct AbilityAvailability(   // BattlefieldEntryView 上一格：IReadOnlyList<AbilityAvailability> ActivatableAbilities
    string          AbilityId,
    int             ManaCost,
    int             RemainingUses,                   // -1 = 不限
    bool            CanActivate,
    ActionRejection Reason);                         // CanActivate == true 时为 None

public readonly record struct PendingTargetRequest(
    string     StackEntryId,                      // 谁在要目标
    int        SlotIndex,                         // 问的是第几个槽位；与 pending.slotIndex 同值
    string     SourceCardId,                      // 呈现用（「埋伏·XX 需要一个目标」）
    TargetKind AllowedKinds,
    IReadOnlyList<TargetRef> LegalTargets);       // 按当前局面算出的合法目标集，UI 直接据此高亮

public readonly record struct ActionResult(
    bool             Accepted,        // 业务失败 = false，绝不抛
    ActionRejection  Rejection,
    CombatActionKind Kind,            // 本次是哪种玩家动作；决定 SubjectId 怎么读
    string           SubjectId,       // 动作主体：CardInstanceId（PlayCard）/ ItemId（UseItem）/ 战场条目 entryId（ActivateAbility）/ string.Empty（EndTurn）
    int              ManaSpent,
    MomentumDelta    CharacterMomentum,  // 本次动作链路（含连锁触发）结算完毕后，角色侧的道念变化
    MomentumDelta    EnemyMomentum,
    bool             AwaitingTarget,  // true = 结算在中途挂起，等玩家选目标
    int              StackDepth);     // 挂起时的栈深；0 = 已结算干净

public enum CombatActionKind { PlayCard, UseItem, ActivateAbility, EndTurn }

public enum ActionRejection
{ None, NotYourTurn, NotActionStep, StackNotEmpty, InsufficientMana, IllegalTarget, CardNotInHand,
  ItemNotAvailable, ItemChargesExhausted, ItemUsesThisCombatExceeded,
  AbilityNotAvailable, AbilityQuotaExceeded }

public readonly record struct MomentumDelta(
    int Before, int After,            // 本次结算前 / 后（After >= 0）
    int Declared,                     // 声明量合计：产出为正、削减为负
    int Actual);                      // 实际量 = After − Before；与 Declared 之差 = 被下限 0 截断吞掉的量
```

- **`ActionResult` 是玩家动作的统一返回类型，不专属出牌。** 出牌 / 用道具 / 结束回合三个方法各返回一份，`ProvideTarget` 返回它所续报的那次动作的同一类型。它承载的是「**我发起的这次动作，服务受理了没有、结果是什么**」；`Kind` 决定 `SubjectId` 怎么读。
  - **`EndTurn` 有返回值。** 结束阶段会触发「回合结束时」并清理到期的战场条目，这些结算同样会改动道念，也同样可能因触发式异能需要选目标而挂起（`AwaitingTarget` 可为 true）；无返回值就等于把这一段结果藏起来。
  - **`UseItem` 的次数消耗即时经 `ProfileManager.TryApply` 写入，本方法不直接改 Profile 字段**——法宝一侧写 `CharacterProfile` 的 `CharacterItem.Charges`，古宝一侧写 `PlayerProfile`（两者的载体都是 `ProfileChangeSpec.ItemElements`，见 `systems/services/profile-service.md`），本场配额落 `CombatItemSave.UsesThisCombat`。**战斗内使用不写 `pastItemUse`**：它发生在事件之内（`activeEvent != null`），账已由该事件的 `AppliedChange` 承载。三条拒绝理由因此各有落点：不在本场可用道具列表内 → `ItemNotAvailable`（含被 `disabledAbility` 过滤掉的）· Profile 侧充能归零 → `ItemChargesExhausted` · 本场配额撞上 `ItemData.MaxUsesPerCombat` → `ItemUsesThisCombatExceeded`。**用道具与出牌完全同窗口**（自己回合的行动阶段、栈为空），故前三条通用拒绝理由照常适用。
    - **两道闸各自成立、取更严者**：本场配额（`UsesThisCombat < MaxUsesPerCombat`，`-1` = 不限）与 Profile 侧总剩余次数（`Charges > 0`）是两个字段、两条拒绝理由，不可互相代替——拿 `Charges` 兼作本场上限会让一件无限法宝的「每场限用一次」在结构上写不出来。字段形态与加载期校验见 `systems/character-profile/item/_index.md`。**敌人侧没有 Profile**，故它改以 `UsesThisCombat < ItemData.Charges`（上限 / 初值）为闸。
    - **`targets` 与 `PlayCard` 逐字同构**：长度 = `Σ CombatUseEffects[i].TargetSlots.Length`，顺序即扁平化的 `slotIndex`；「玩家主动发起的动作，槽位一律在发起前一次收齐」的判据是**主动发起**，故适用，**入栈即 `targetState = Resolved`**。
    - **用道具产生的栈条目 `abilityId` 恒空**（道具没有宿主 `AbilityData`）⇒ 收口阶段的「默认 counters +1」对它不成立，与 `PlayedCard` / `Fatigue` 同款；同理 `BumpCounterEffect` / `CounterAtLeastCondition` 在 `CombatUseEffects` 内是加载期错误。
  - **`ActivateAbility` 的 `SubjectId` 取 `entryId` 而非 `abilityId`。** `entryId` 是**唯一寻址**（同一条 `AbilityData` 可同时挂在多个条目上，`abilityId` 定位不到是哪一个），且与 `CauseEntryId` / `TargetRef.EntryId` 同一命名空间；调用方本就知道自己启动的是哪条异能，`ActionResult` 是**同一次动作的回执**，不必把请求参数原样回传。`ManaSpent` 填 `ManaCost`。
  - **「抓牌」不是玩家动作，没有 `ActionResult`。** 抽牌发生在开始阶段、以及作为卡牌效果的结算产物，没有调用方也就没有返回值可给；它的可观测性由 `CombatFeedEntry` 承担（疲劳同理）。
- **`ActivateAbility` 按战场条目寻址，不按 `Power` 寻址。** 启动式异能不是 `Power` 专属——`PowerData.Abilities` 与 `CardData.Abilities` 取值域相同，而**阵法（`Enchantment`）是留场永久物**，「留场 + 每回合花 mana 启动」正是启动式异能的样板形态；按 `powerId` 寻址会把阵法侧排除在外，日后必然再开第二个方法。`abilityId` 必须显式给：一个条目可挂多个异能，只给 `entryId` 表达不出「启动的是哪一条」。**动词取 `Activate` 不取 `Use`**——`Use` 已被道具占用，两个动词分给两条不同的来源路径，读签名即知走的是哪一条。
  - **`targets` 与 `PlayCard` 逐字同构**：长度 = 该异能全部 element 的 `TargetSlots` 长度之和，顺序即扁平化的 `slotIndex`（见「效果流水线」的槽位编号），入栈即 `targetState = Resolved`。「玩家主动发起的动作，槽位一律在发起前一次收齐」的判据是**主动发起**而非「打的是不是牌」，故适用；挂起态仍只来自结算中途回头问的那些。
  - **扣费 = 压栈那一刻扣 `sides[controllerSide].currentMana`，`fizzle` 不退，且不经 `ProfileManager`**——`currentMana` 是 `activeCombat.sides[]` 上的回合内运行态、不是 Profile 字段（`CostKey` 与两层 Profile 字段双向满射且无 `CurrentMana`）。**按 `controllerSide` 解析而非写死玩家侧**：敌人同样启动，与「`SideConstraint` 一律相对施放者解析」同构。
  - **入栈**：`kind = ActivatedAbility`（枚举成员已存在）· `controllerSide = 启动方` · `sourceEntryId = entryId`（载体条目）· `abilityId = abilityId` · `sourceInstanceId` = 载体条目的 `sourceInstanceId`（阵法有值、`Power` 为空）· `chosenTargets` = 传入列表 · `targetState = Resolved`。
  - **拒绝理由的落点**：三条通用（`NotYourTurn` / `NotActionStep` / `StackNotEmpty`）照常适用 · `currentMana < ManaCost` → `InsufficientMana`（复用，不另立）· 配额撞上 `MaxActivationsPerCombat` → `AbilityQuotaExceeded`（对位 `ItemUsesThisCombatExceeded`）· 目标非法 / 槽位数不匹配 → `IllegalTarget` · **`entryId` 不在战场 / `ownerSide` 非本方 / `abilityId` 不挂该条目 / `Kind != Activated` 四种情形合并为 `AbilityNotAvailable`**（与 `ItemNotAvailable` 同款粒度：四者对玩家是同一句话，拆成四条只增加调用方分支而不增加任何可呈现的差别）。
  - **`abilityId` 经 `ContentRegistry` 解析不到 → `PushError` + 抛，不是业务拒绝**（真悬空 = 内容被删或键被写错，与读档校验 ② 同档）；**解析得到但不挂在该条目 / 不是启动式 → 业务拒绝**（UI 可能持有一份刚被移除条目的陈旧 id，属预期内）。这条分界必须写明，否则两侧会各写一半。
  - **敌人侧不经本方法**：EnemyManager 在自己回合内自行决定启动、走内部路径，**不产生 `ActionResult`**（没有调用方），照常广播 `CombatFeedEntry`。不为敌人另开 API。
  - **决策点清单不加行**：启动的结算与出牌完全同形，`D2` 本就点名了它，结算中途要目标落既有的 `D4`；密度口径也不变——启动**替代**一次出牌占用行动阶段的一个动作位，不是额外叠加。
- **灰态预判所需的数据由服务算好交给 UI，不让 UI 重演规则。** `BattlefieldEntryView` 上的 `ActivatableAbilities` 一格即为此：配额计数活在 `entry.counters` 里 UI 拿不到，而让 UI 自行按 `ContentRegistry` + snapshot 重算窗口 / mana / 配额三条规则，等于把规则实现成两份。`CombatSnapshot` 本就按变更广播 + 缓存，多这一格不落在热路径的分配面上。
  - **只对 `ViewerSide` 己方条目填充，对侧条目恒为空列表**——与 `HandCardInstanceIds` / `UsableItemIds` 同一条填充纪律。灰态预判服务的是观察方可发起的动作；给对手条目算 `CanActivate` 既无消费者，又是一条信息泄漏面。无启动式异能的条目同样是空列表。
  - **被 `disabledAbility` 抑制的载体本就不入场**（参战方组装的三条与门），其上的启动式异能天然不可见、由 `AbilityNotAvailable` 兜底，**不需要第二条禁用过滤**。
  - **UI 预判不减免服务侧的全量重校验**：服务是规则权威、绝不信任 UI（与 `ProvideTarget`「服务端仍以 `LegalTargets` 为准校验」同款）。两者不是重复——UI 不预判就只能让玩家点了才被拒，撞上「使用窗口是全局规则，UI 应把它表达为可供性的有无」这条既定要求。`Accepted == false` 时 UI 只回到原态、不弹 toast，解释由灰态 + 长按承担。
- **`CombatSnapshot` / `ActionResult` 必须承载道念。** 胜负标尺是道念，故战斗态视图与动作结果**都要能表达道念的当前值与本次变化量**——否则 `ux/combat-ux.md` 的「双方道念对比」主视觉无数据可读。
- **道念字段结构 = 当前值 + 本回合增量，且明确不分来源（承重）。** `CombatSnapshot` 是**状态视图**（现在是多少），按来源拆分道念是**事件视图**的活；分来源的诉求由 `ActionResult` 与 `CombatFeedEntry` 承载，三者不重复。
- **`MomentumDelta` 的 `Declared` / `Actual` 放在事件视图而非 `CombatSnapshot`（承重）。** 判据：**snapshot 是状态视图**（现在是多少），**`ActionResult` / `CombatFeedEntry` 是事件视图**（这一次发生了什么）——而截断是每次结算发生的**事件**。这条划分同时解释了为何 snapshot 只需「当前值 + 本回合增量」。
  - **`Declared` 是效果的标称量。** `Declared − Actual` = 被下限 0 吞掉的溢出量，UI 据此打出「削减 8（对方仅剩 5，溢出 3 未结转）」。**它正是「执行过程须逐步可见」这条硬要求所需的数据**。
  - **两个事件视图的粒度不同，不是重复。** `ActionResult` 给的是**一次玩家动作链路（含连锁触发）的汇总值**，服务的是发起动作的调用方；`CombatFeedEntry` 每条自带**本次结算的增量值**，服务的是呈现层。敌人结算 / 触发式异能 / 疲劳三类没有调用方、拿不到 `ActionResult`，逐条却都要有值可显——只有 feed 能覆盖。
  - **`Declared` 无法由状态视图重建，这是它必须落在事件视图上的硬理由。** 对方剩 5 时打 8 与打 5，snapshot 序列完全相同（都是 `5 → 0`），被下限 0 吞掉的量在状态里不留任何痕迹。
- **`PlayCard` 收一个 `TargetRef` 列表，长度必须等于该牌全部 element 的 `TargetSlots` 长度之和**（顺序即扁平化的 `slotIndex`；无目标的槽位写 `TargetRef(None, _, string.Empty)`）。**一张牌可以有多个目标槽位，而主动出牌的槽位一律在打出前收齐**——把它们改走挂起态逐个问，会让决策点密度按每张多目标牌 +N 暴涨，与 D4 的稀缺配额正面冲突。**运行时不变式（可断言）**：`chosenTargets.Length == Σ(element.TargetSlots.Length)` · `pending` 非空 ⇒ 该槽位满足挂起三条件 · 静止式修正的求值路径上**恒不出现 `TargetRef`**。
- **`ProvideTarget` 补上的是一个真实的 API 缺口**：结算循环已定为可挂起的状态机，但此前没有让玩家把目标交回去的方法。返回同一个 `ActionResult` 类型（`Kind` / `SubjectId` 沿用被续报的那次动作）——它是**同一次动作的续报**，续报里的 `MomentumDelta` 覆盖「从上次挂起点到本次挂起点 / 结算完毕」这一段；`AwaitingTarget` 可连续为 true（连锁触发中多次要目标）。**不走 EventBus 回传**——广播是既成事实、不承载请求。
- **`SideSnapshot` 单类型，不拆己方 / 对方**：拆两个类型会让「双方对称的参战方模型」在视图层裂开、ViewModel 要写两套。代价是必须写死一条填充纪律——**`ViewerSide` 对侧的 `HandCardInstanceIds` 与 `UsableItemIds` 恒为空，不是 bug**。
- **`CombatSnapshot` 是双视角的单一投影，AI 与呈现共用一个类型（承重）。** 「读侧统一、写侧分权」这条划线推论覆盖 AI：EnemyManager 规划意图时读的就是本类型，只是 `ViewerSide` 取该敌人的 `OwnerSide`；UI 组装与决策点存档取 `Character`。**不为 AI 另立第二个投影类型**——两个投影会各自漂移，而本库没有机制发现它们不一致。
  - **双视角不改动任何字段语义**：「仅 viewer 己方非空」这条填充纪律原样成立，只是「己方」随 `ViewerSide` 解释。这正是「不读玩家手牌内容」能停在第 1 级的原因——敌方视角下那份内容结构上不存在，而不是靠约定不去读它。
  - **缓存与按变更广播按 `ViewerSide` 分别持有**（两份缓存、同一次组装），**不跨视角复用一份**：一份缓存被两个视角轮流覆写，等于把「我这次读到的是谁的视角」变成时序问题。
- **`TargetKind` 必须有 `None`**：`PlayCard` 每次都要传一个 `TargetRef` 而大量牌无目标，`None` 使「无目标」成为**已表达的取值**而非 null 约定。**`StackEntry` 不保留**——本作不做「反制栈上条目」这一形态的效果，枚举里不留永无消费者的取值；栈条目只被 `pending` 与结算流程用 `stackEntryId` 引用，**从不作为效果的目标**。
- **`CombatTier` 是三值枚举而非 bool**：回合数与胜负判据已显式化，**战斗规则不从它派生**；但它是**战斗之外**三处的判据（篇章边界闸门 · ADR-0004 篇章重试 · 道统残卷的累积与兑现），故用三值枚举而非 bool——枚举同时让 `Practice` 有了位置。见 `decisions/ADR-0002-adventure-event-taxonomy.md`。
- **胜负判据参数化为两个数就够，不做「可替换的判定对象」**：`(1, false)` / `(0, false)` / `(N, false)` 已覆盖全部已陈述需求，无需策略枚举与分发。
- **`BaseReward` 随物化定稿**（热更不影响进行中的遭遇），与「`EventOption` 产出即定稿」一致；代价是与「overlay 热更即生效」略有张力，**取定稿纪律**。
- **`EncounterSpec` 的可空覆写组 = `InitialDraw` / `DrawPerTurn` / `HandLimit` / `EnemyManaLimit` 四格，`null` = 取 `CombatRulesData` 的默认值。** 它们与 `TurnLimit` / `VictoryRule` 属同一档遭遇参数旋钮——「更宽容的 `Practice`」最自然的形态之一就是多抽一张。取值与逐格理由见 `systems/balance.md`；**疲劳量刻意不在覆写组内**（同处给出理由）。
  - **本服务只见定值，不知道剧本存在。** 前三格连同 `TurnLimit` / `WinMargin` 可能已在物化期被剧本的 `PlotModulation.Tighten` 收紧（形态与合并算子见 `systems/services/plot-manager.md`）；`EncounterSpec` 产出即定稿并落存档，**消费侧不回查模板重算**。
  - **⚠ 已知例外：参战方对称在 mana 这一项被打破。** 「敌人侧规则数值与玩家侧完全同值」这条对称纪律（它支撑着「敌人回合的可读性依赖对称」）对起手 / 抽牌 / 手牌上限三项成立，**对 `manaLimit` 不成立**：敌方取全局常量 `EnemyManaLimit`（初值 `5`，可被本格覆写），而玩家侧 `manaLimit` 随大境界提升而增长，第三章可达 9~12。玩家因此**无法从自己的 mana 节奏推断敌人的行动空间**，图鉴「关键卡牌」一栏的费用参照系也随之偏移。这是已知并接受的代价——敌人的强度差由 `baseMomentum` 与逐条编排的卡组承载，不由 mana 承载。玩家侧的成长语义见 `systems/character-profile/mana.md`，敌方取值见 `systems/balance.md`。
- **`EncounterSpec` 整份嵌在 `EventOption.Encounter` 上，`EncounterId` 与 `EventOption.InstanceId` 同值的冗余是写明的例外、不是先例。** 本服务只见 `EncounterSpec`、不见 `EventOption`；删掉这一格会让战斗侧日志与 `ActiveCombat` 存档失去溯源键。它与 `LifeSpanAfter` 同款处置——**不得据此放宽「重算得出来的不存」这条判据**。
- **`CombatSnapshot` 按变更广播 + 缓存**，不是每次访问现组装（含两个列表，UI 每帧读会在热路径分配）；调用纪律 = **每回合 / 每次结算后组装一次**。归 `.claude/rules/csharp-godot-rules.md` 热路径不分配。
- **运行时视图字段 ≠ 存档 schema**：二者大量重合但不应混为一谈（例如 `PendingTargetRequest.LegalTargets` 明确不必存档，恢复时按当前局面重算）。存档 schema 见上方「战斗存档：`ActiveCombat`」。

### 可选奖励的候选生成

- **固定 3 项候选，不受道念差影响；三项各自独立可领可跳，不是择一。** **道念差的价值全部落在候选质量上**（`Tier` 三档，见 `systems/balance.md`），不落在数量上——这是数量恒定的现行理由。逐项领取使实际到手项数在 0–3 之间由玩家决定，**面板长度恒为 3、到手数不恒定**。
- **池 = 事件模板携带的 `RewardPoolId`，经 `AllEnabled()` 取池**，**三类混合（`CardData` / `ItemData` / `CultivationTechniqueData`）**，去重（本次已抽中的 `Id` 不再出）。**必须走 `AllEnabled()`**，不得自写 `All().Where(x => x.ContentEnabled)`。**这是一条玩家侧候选池，故另叠一层 `Pool != Enemy`**——卡牌与功法两侧同款过滤（`Pool` 的枚举成员、必填语义与两侧对称的校验口径见 `systems/character-profile/deck/_index.md`，此处不复述）。**`RewardPoolId` 挂 `AdventureEventData` 不挂 `EnemyData`**——「打赢什么敌人」与「这场给什么奖」是两件事，同一个敌人在 Practice 与 Combat 中的奖励池应当能不同。**稀有度权重表按 `RarityTier` 五档索引、由优势档 `Tier` 三档选表**——`RarityTier { Tier1..Tier5 }` 是内容品质档（挂 `CardData` / `ItemData` / `PowerData` / `CultivationTechniqueData`，缺失 → `PushError`），`Tier { Narrow, Solid, Crushing }` 是道念差归一化的优势档，**两者不得复用同一枚举、也不得互相换算**。见 `systems/balance.md`。
- **功法候选的两条口径。**
  - **候选中出现已持有的功法 → 直接排除，不折算为升阶。** 与闭关三选一的处置一致（见 `systems/character-profile/deck/_index.md` 与 `systems/adventure-event/research/common-properties.md`）：升阶是另一条独立通道，混进奖励抽取会让「抽到什么」与「升什么」两件事互相污染。
  - **玩家选中一门功法 = `Spoils` 内的一条 `DeckChangeElement(LearnTechnique, id, Tier = 1)`，与商店购买逐字同构，不新增任何结构。** `CombatResult.Spoils` 本就是一份完整的 `ProfileChangeSpec`，其 `DeckElements` 已能承载它。选中即**整组入组**——一个功法是一组必须整组入组的卡牌。
- **奖励池的 `Card` 部分同样排除「被任一功法引用的成员卡」**，通则与加载期反建索引的权威在 `systems/adventure-event/exchange/common-properties.md`。注意这与上一条不冲突：功法是作为**独立族**进池的，被排除的是散牌产出侧的成员卡。
- **时点 = 胜负判定之后、奖励领取步骤之前，一次性抽定**，走 `RngStream.Reward` 子流；**`picks` 落 `activeCombat.reward`、与 `rng.State` 一同存档，恢复时直接读已抽定的 `picks`，绝不用同一 `State` 重抽**——后者依赖抽取算法永不变更，是脆弱保证；直接存结果才真正兑现「退出重进得到同一组选项」。
- `combatTier` 三档**共用同一条生成路径**，差异只在 `RewardPoolId` 与 `Tier`。
- **「一项都不领」是合法结局**，它不是一条单独的「放弃全部」通道，而是逐项跳过的自然叠加——面板上没有「放弃全部」按钮，玩家只是把三项都跳过了。**合法池不足 3 条目时显式降级**：`PushWarning` + 给出实际能给的项数，**不静默给 2 项**。
- 「碾压才有高稀有度」会诱导玩家专挑弱敌刷奖励——但 `±2` 带已从规则层封住碾压深度，该激励天然受限。**这是 `±2` 带的一个正向副作用。**

- **`RunCombatAsync` 收 `EncounterSpec` 而非 `CharacterProfile`**：当前角色是 life-cycle-service 状态机的持有物，本服务经 `ProfileService.Instance` 读写，不接收角色参数。
- **`CardData` ↔ `CardInstance` 是「模板 ↔ 运行时实例」的另一半**（另一半是 `AdventureEventData` ↔ `EventOption`）：签名里**传实例，不传 `Resource`**；区别在于 `CardInstance` 运行态**可变**（手牌中的临时增益），而 `EventOption` 产出即定稿不可变。见 `systems/architecture.md` 总则 6。
- **`CombatResult.Spoils` 是 `ProfileChangeSpec` 而非「已写好的变更」。** 本服务只**描述**结果；life-cycle-service 在 `eventEnd` 阶段把它连同 `lifeSpanCost` 与隐藏属性推拉**合并为一次 `TryApply`**，从而「一个事件的收口是一次事务、一个存档点」。战斗**过程中**的血 / mana 变更仍即时经 ProfileManager——**事件内部的主动消费即时提交**，这是同一条纪律的另一半，不是例外；`Spoils` 只承载收口产出。

**事件面：**

| 事件 | 负载 |
|------|------|
| `CombatTurnStarted` / `CombatTurnEnded` | `(int TurnIndex)` |
| `CombatFeedEntry` | 见下方字段面 |
| `CombatFinished` | `(CombatOutcome Outcome, int CharacterMomentum, int EnemyMomentum, int RemainingLifeTotal)` |

**`CombatFeedEntry` 是喂给呈现层的统一结算事件流，五类情形共用一条广播：卡牌结算 · 启动式异能 · 触发式异能 · 疲劳扣减 · fizzle。** 一个事实只留一条广播——飘字 / 战报收起态单行 / 战报展开态因果树三个消费者读的是同一条流，不各自去别处捞。

```csharp
public readonly record struct CombatFeedEntry(
    CombatFeedKind Kind,             // CardPlay | AbilityActivation | AbilityTrigger | Fatigue
    Side           Side,             // 本次结算的归属方；与战场条目的 OwnerSide 同一枚举，复用不另立
    string         EntryId,          // 本条自身 id = 该次结算所属栈条目的 stackEntryId（各类无例外）
    string         CauseEntryId,     // 因果父的 EntryId；无父 = string.Empty
    string         SourceId,         // CardId（CardPlay）/ AbilityId（AbilityActivation | AbilityTrigger）/ string.Empty（Fatigue）
    string         SourceInstanceId, // CardInstanceId；无实例来源 = string.Empty
    int            FizzledSlots,     // 落空槽位的位掩码，0 = 未落空
    MomentumDelta  CharacterMomentum,// 本次结算的增量（逐次结算粒度）
    MomentumDelta  EnemyMomentum);

public enum CombatFeedKind { CardPlay, AbilityActivation, AbilityTrigger, Fatigue }
```

- **启动式异能自成一类 `AbilityActivation`，不并入 `AbilityTrigger`。** 后者的语义是**触发式**；合用会让战报的因果树分不清「**我启动了** X」与「X **被触发了**」，而战报的全部价值就是「谁引发了谁」可读。条目取值：`EntryId = stackEntryId` · `CauseEntryId = string.Empty`（玩家主动动作是因果树的根，与 `CardPlay` 同）· `SourceId = abilityId` · `SourceInstanceId` = 载体条目的 `sourceInstanceId`（`Power` 载体时为空）· `FizzledSlots` 照常。

- **`EntryId` 恒有值，因果树的两端都不缺。** 各类结算全部经栈（启动式压栈、疲劳同样入栈），故 `EntryId` 直接取 `stackEntryId`，不为任何一类特设发号路径。`CauseEntryId` 指向**引发本条的那条 feed 条目**——一次出牌与它连锁引发的全部触发因此归为一棵树，「谁引发了谁」读得出来。**它与栈条目的 `sourceEntryId` 不是同一件事**：后者是**载体所在的战场条目**（这个异能挂在谁身上），前者是**因果父**（这次结算是被谁引发的），两格并存不构成重复。无父时 `CauseEntryId = string.Empty`，沿 `TargetRef.EntryId` 在 `Kind == None` 时写 `string.Empty` 的既定约定。
- **fizzle 是条目上的一格，不是第四个类别。** 「部分槽位非法 → 该槽位不产生效果、其余槽位照常结算」这条规则要求呈现层写明**是哪一半没生效**；把 fizzle 拆成与卡牌结算平行的独立条目，一次「打出 X 且其中一个槽位落空」就得拆成两条，那句话就写不出来。`FizzledSlots` 是位掩码（槽位数极小，位掩码避免热路径上分配集合）；全条落空 = 全部有目标的槽位置位且 `Declared == 0`。
- **负载只带 `Id` 与值类型，不带 `CardInstance` / `Resource` 引用。** 本流在战斗内逐次结算都广播，是热路径——Godot `[Signal]` 传自定义负载会**每次广播都分配一个引用对象并经 `Variant` 装箱**（EventBus 走 C# 泛型事件而非 `[Signal]` 的直接动因，见总则 5），且**传引用等于给每个订阅者开一条绕过唯一写入入口的旁路**。需要完整实例的订阅者按 `Id` 向 `ContentRegistry` / `CombatSnapshot` 取。
- **条目存结构化数据，不存已格式化的字符串。** 热路径不做 `string` 拼接（`.claude/rules/csharp-godot-rules.md`），且**渲染期才套 `res://text/` 翻译键**（`.claude/rules/ui-input-rules.md`「UI 文案一律走翻译键」）——在服务侧拼好句子，战报会成为全库最大的一处文案字面量泄漏源，切语言时静默留在中文。
- **本流不落存档，退出重进战报从空开始。** 这**不是**「可重算所以不存」——feed 是历史，局面重算不出来；它的理由是**明写接受丢失**：`ActiveCombat` 因此一格不加，而「选目标态必须自解释」这条硬要求的承担者是指令条、本就不依赖战报。
- **本流是 Combat 专属，不外延为跨事件类型的日志。** 见 `systems/adventure-event/common-properties.md`。

Source: `handoffs/2026-07-27b-service-api-contracts.md` · `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md` · `handoffs/2026-08-06d-combat-open-questions-mass-closure.md` · `handoffs/2026-08-22-finale-failure-is-death.md` · `handoffs/2026-08-22-encounter-tighten-fields.md` · `handoffs/2026-08-25-numeric-philosophy-and-balance-anchors.md` · `handoffs/2026-08-25-combat-presentation-and-action-result.md` · `handoffs/2026-08-26c-enemy-ai-strategy-shape.md` · `handoffs/2026-08-26d-activate-ability-contract.md` · `handoffs/2026-08-28-item-use-effect-face-and-carrier-kind.md`

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

- **战斗模型 = mana + 道念；胜负 = 道念高者胜；失败按道念差扣 lifeTotal** → `decisions/ADR-0018-momentum-scoring-model.md`（Accepted）；规则骨架见 `systems/scoring.md`、`systems/adventure-event/combat/`、`systems/character-profile/life-total.md`、`mana.md`。
- **战斗定长 = 10 个回合（双方各 5）；起始道念 = `baseMomentum`；道念可互削、下限 0**。
- **敌人的行动不作任何事前预告**（不设揭示档位 / 行动类别标注 / 回合级行动描述 / 探查通道）；**EnemyManager 不受「回合级一次性规划」约束**；**双方回合的每一次结算都必须是可观测事件**（逐步演出是硬要求），由统一广播 `CombatFeedEntry` 承载。
- **`ActiveCombat` 战斗存档 schema（挂 `CharacterProfile`、可空、收口即清）；D0–D7 决策点清单（保留 D2；D6 = 奖励逐项领取）；挂起态恢复回到该选择点、不允许反悔；`ct` 只在决策点被观察；战斗随机不设 `attemptIndex` 派生层**。
- **`EncounterSpec` 携带 `TurnLimit` / `VictoryRule` / `RewardPoolId` / `BaseReward` 且改为 `sealed record`；`IsFinale` 收编为三值 `CombatTier`；玩家动作的统一返回类型 `ActionResult`（覆盖出牌 / 用道具 / 启动异能 / 结束回合 / 提供目标五个方法）；`MomentumDelta` 四字段（`Declared` = 效果标称量）；可选奖励固定 3 项且预先算定落存档**。
- **奖励计算归 combat-service、发放属于战斗流程；奖励分强制 / 可选两类，候选预先算定、可选部分逐项领取 / 跳过（每一次处置是决策点 D6）；回合数与胜负判据为遭遇参数**。
- **卡牌结算 = stack（LIFO），但交互与优先权传递移除；栈深由触发式能力入栈撑起；回合结构 = 开始阶段 / 行动阶段 / 结束阶段三步（归属方各走一套，无战斗步骤、无双主阶段）；出牌时机唯一且为全局规则；手牌上限是恒定不变式、不设弃牌机制**。
- **借词第一批全部定名；卡牌类型五分 + 异能三分 + 永久物；战场与参战方的划线判据 = 「是否在场上生效」** → `decisions/ADR-0019-card-type-taxonomy-and-battlefield.md`（Accepted）。
- **先后手由 `EncounterSpec.FirstSide` 决定（null → combat 子流掷）；不设 mulligan；抽牌堆不重洗、抽空即每张扣 1 道念；疲劳入栈，是完全一等的栈条目（可被监听 / 响应，扣减量可被削减至 0），无限对局风险由 `TurnLimit` 封顶；起手 4 / 手牌上限 7 / 卡组规模不设硬限**。
- **呈现事件流统一为一条广播 `CombatFeedEntry`**（卡牌结算 / 触发式异能 / 疲劳 / fizzle 四类共用，fizzle 是条目上的 `FizzledSlots` 一格而非独立类别）；**条目自带 `EntryId` / `CauseEntryId` 构成因果树**、存结构化数据不存格式化字符串；**不落存档，明写接受退出重进丢失**。
- **D0–D7 决策点清单完整，D2 不得砍。** **D2 兑现的是「退出重进得到同一局面」**，在强制在线 · 云端权威下这是玩家对存档的基本信任，不是可牺牲的性能余量；超预算时先动 push 频率。约 31 个决策点 / 场、≈93 KB 本地写的量级接受。
- **引入 battlefield（战场）并新增 BattlefieldManager 与 StackManager 两个 manager；满手时抽牌抽不进（纯上界、无弃牌流量）；触发式效果的载体开放（牌上触发器 / 场上持续状态 / CharacterPower，可再增）；道念下限 0 在每一次结算时截断**。
- **Finale 不是独立事件类型，而是 Combat 的最重一档 `combatTier`；三档共用战斗状态机** → `decisions/ADR-0002-adventure-event-taxonomy.md`。
- **合法目标集 = 即时求解的四条可交换过滤（顺序非规则）；结算时逐槽位重检并采部分 fizzle；挂起态三条与门；`PlayCard` 收 `TargetRef` 列表；`PendingTargetRequest` 带 `SlotIndex`；战场条目新增 `keywordId`**。
- **敌人 AI 两层结构 = 通用兜底（实现在 EnemyManager 内）+ 敌人模板级定制策略（挂 `EnemyData`、可空、空即回落兜底），经 `EnemyId` 读模板、`EnemyInstance` 不加字段；定制策略只表达打法风格，不作强度 / 难度旋钮；AI 决策是「局面 + `combat` 子流」的纯函数，输入面限对称可见信息**。
- **定制策略 = `EnemyAiProfileData` 的权重覆写（定制层不提供代码）；兜底算法 = 1-ply 加权效用评分 + 确定性 argmax、`score(EndTurn) ≡ 0`、决策粒度逐张；AI 全流程零随机、零记忆，`ActiveCombat` 一格不加；`CombatSnapshot` 双视角化（`ViewerSide`），AI 与呈现共用同一投影**。
- **`ActivateAbility(entryId, abilityId, targets)` 补齐第五个玩家动作方法**（按战场条目寻址、敌人侧不经本方法、决策点清单不加行）；**启动代价拆为 `ManaCost` 一格 + `MaxActivationsPerCombat` 配额闸，首版不开 Profile 侧代价列**；配额落既有 `entry.counters`、`ActiveCombat` 零新增字段；`ActionRejection` 增 `AbilityNotAvailable` / `AbilityQuotaExceeded`、`CombatFeedKind` 增 `AbilityActivation`；灰态预判由 `BattlefieldEntryView.ActivatableAbilities` 承载、只填 `ViewerSide` 己方条目。
- **效果流水线 = 五个阶段（重检 / 挂起 → 关键字展开 → 数值求值 → 逐 element 条件与施加 → 收口），挂起点唯一 = 阶段 1；数值整条一次求完而条件逐 element 就地求；`IEffectHandler` 拆 `Evaluate` / `Apply` 且随机只在 `Apply` 内取；槽位在栈条目层扁平化编号（上限 32）；单次动作链的栈条目总数上限 N 落 `CombatRulesData`**。
- **卡牌效果可经 `MoveCard` 把有限张牌置于抽牌堆顶 / 底**（插入位置不掷随机，随机位入堆未开放）；护栏落在载体消耗性与 `TurnLimit` 上，规则性的弃牌堆回流重洗依然不存在 → `decisions/ADR-0052-no-reshuffle-fatigue.md`。
- **`counters` 键空间只有 `<abilityId>[#<子名>]` 一种形态（非异能计数不进 `counters`）；子名有正则且须登记在 `AbilityData.CounterNames`；实例侧计数由参战方的 `GetCardCounter` / `BumpCardCounter` 承担、与配额计数同时机；战场条目新增 `amount` 承载 `KeywordRef.Amount`**。

Source: `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md` · `handoffs/2026-08-02-momentum-conversion-reward-structure-and-mtg-stack.md` · `handoffs/2026-08-02b-stack-without-interaction-and-three-step-turn.md` · `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md` · `handoffs/2026-08-04b-mtg-loanwords-card-types-and-intent-snapshot.md` · `handoffs/2026-08-06d-combat-open-questions-mass-closure.md` · `handoffs/2026-08-11c-combat-turn-flow-fatigue-and-card-type-reduction.md` · `handoffs/2026-08-15d-intent-removal-lifespan-cost-visibility-and-design-audit.md` · `handoffs/2026-08-16-design-audit-adjudication-and-hand-limit.md` · `handoffs/2026-08-22-card-counters-api-and-key-space.md` · `handoffs/2026-08-25-combat-presentation-and-action-result.md` · `handoffs/2026-08-26c-enemy-ai-strategy-shape.md` · `handoffs/2026-08-26d-activate-ability-contract.md`

## 待决问题

- **Finale 的奖励结构加厚幅度。** Finale 是战斗变体、天劫为带定制卡组的 Enemy，遭遇参数为 12 回合 / `WinMargin 0`；**奖励加厚的具体取值**留待内容扩充后的统计校准。→ `systems/adventure-event/combat/`。
- **战斗内容全部未设计。** 卡牌定义与起始卡组、敌人目录、遭遇战编排——均为空白（**回合内的效果 / 状态系统骨架**，见 `systems/character-profile/deck/_index.md`）。→ `systems/adventure-event/combat/`、`systems/character-profile/deck/`。

## 对应
提炼至：`.claude/knowledge/systems/combat-service.md`（引用层，待建）。
