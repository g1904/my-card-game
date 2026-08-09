# combat-service（服务）

> 战斗驱动服务：回合循环、出牌结算、抽 / 弃 / 洗、敌人 AI 与意图（意图按**等级差三档揭示**）。**判据 ① —— 拥有自己的状态机与跨多帧的长流程。**
> Source: `handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md`。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **为何 Combat 需要独立服务，而其余八类不需要。** 九类 AdventureEvent 中**只有 Combat 真正拥有自己的状态机**——回合循环跨多帧推进、有独立的中间态（手牌、场上效果、敌人意图）。Practice / Research / Social / Explore / Exchange / Travel / Mystery 共享同一形状（呈现 → 择一进入 → 扣成本 → 应用产出 → 推拉隐藏属性 → 收口），差异在**数据**而非**代码**，由通用结算器 + 数据驱动的 outcome / effect 定义承担。见 `_index.md` 的拆分轴。
- **Finale 复用本服务的状态机。** 境界突破是 Combat 的一个变体（独立的结算规则与胜负条件，但同一套回合循环），不另建服务。
- **战斗模型 = mana（出牌）+ 道念（计分与胜负）（已定案）。** 本服务维护**双方各自的道念（momentum）**作为胜负标尺：**道念高者胜**；`currentMana / manaLimit` 为出牌资源，mana **无曲线**、**每回合开始自动恢复至 `manaLimit`**。**`lifeTotal`（单值，无上限字段）在战斗过程中不被读写**——失败时才在收口时刻按「角色道念 − 敌人道念」的差值扣减 lifeTotal。炼气基线 lifeTotal 10、mana 5/5。见 `systems/scoring.md`、`systems/character-profile/life-total.md`、`mana.md`、`systems/adventure-event/combat/`。Source: `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。
- **战斗是定长的：固定 10 个回合（已定案 · 答结道念模型的首要缺口）。** 一场战斗**打满 10 个回合**，**双方各 5 个**（「回合」= 单方的一次行动轮，交替进行），随后比道念、高者胜。**不设提前终止**（无道念阈值胜利、不以卡组耗尽终止）。**推论：TurnManager 是一个固定长度的循环**（`for turn in 1..10`）而非动态终止判定——状态机形状因此确定，且每场战斗的时间开销可预测。Source: `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。
- **平局 = 只发基础奖励（已定案）。** 10 回合打满后道念相等时：**不判负、不扣 lifeTotal**，玩家**只获得该事件的基础奖励**（道念差为 0，故无任何厚度加成）。因此 `CombatOutcome` 需要第三个胜负态 `Draw`，且它在收口上落在「胜利侧的最薄一档」——与「道念差是双向刻度」自洽：差值为 0 就是两侧都不加码的那个原点。Source: 同上。
- **道念的运行态骨架（已定案）。** 战斗开始时本服务为双方各置一个**起始道念 = `baseMomentum`（按各自全局等级，表见 `systems/balance.md`）**；此后道念**由打出的卡牌产出**，且卡牌**可削减对方道念**，**削减在 0 处截断**（无负道念）。**推论：等级差在开局即转化为道念差**，越级挑战的压力有了确切量纲。Source: 同上。
- **奖励由本服务计算，且「获取奖励」是战斗流程的一部分（已定案 · 答结归属）。** 结算量不由 life-cycle-service 拿着 `CombatResult` 的双方道念在 `eventEnd` 再算——**combat-service 按战斗结果算完**，包括按道念差决定的奖励厚度与 lifeTotal 扣减。**推论 ①：`RunCombatAsync` 的流程尾部含奖励环节**——10 回合打完后还要走「胜负判定 → 计算奖励 →（若有可选奖励）等玩家选择 → 收口」，随后才返回 `CombatResult`；它因此仍是形态 C，只是尾部多了一个等待玩家输入的阶段。**推论 ②：不违反「一个事件 = 一次事务 = 一个存档点」**——本服务只**计算并确定**奖励，产出的仍是一份 `ProfileChangeSpec`（`Spoils`），真正的写入照旧由 life-cycle-service 在 `eventEnd` 合并为一次 `TryApply`。**分工 = 计算归战斗、施加归生命周期。** Source: `handoffs/2026-08-02-momentum-conversion-reward-structure-and-mtg-stack.md`。
- **奖励分两类：强制自动计入 / 可选由玩家择一（已定案）。** **强制奖励**无需玩家操作、自动计数（例：经验）；**可选奖励**由玩家从若干候选中选择，形态**参照 Slay the Spire** 的战后奖励面板。**推论 ①：战斗后需要一个奖励选择步骤与对应界面**，且因奖励发放归 combat 流程，这一屏在战斗流程内、返回 `CombatResult` 之前（见 `ux/combat-ux.md`）。**推论 ②：`Spoils` 需能表达两类条目**——强制部分计算时即固定，可选部分先呈现候选、再由玩家选择收敛为最终 spec。Source: 同上。
- **奖励**预先算好**，故奖励选择**不是**决策点（已定案）。** 候选项在收口时一次算定，**退出重进得到的是同一组选项**——不存在「不满意就退出重开换一批」的窗口，因此**无需为它单独落一个决策点**。**推论：候选生成必须在战斗的确定性边界之内**（走 `Reward` 子流并随战斗 RNG `State` 一同持久化），否则「重进得到同样选项」这条保证不成立。Source: 同上。
- **失败侧仍发 `baseReward`，额外惩罚以负向条目包在 reward 内（已定案）。** 输了通常只有基础奖励；少数事件附带额外惩罚，它不另立结构，就是 `Spoils` 中的负向 `ChangeElement`——与带符号约定天然自洽。见 `systems/scoring.md` 的三档结算产物表。Source: 同上。
- **卡牌结算 = stack，但**不含交互与优先权**（已定案 · 08-02b · 承重）。** 借入 MTG 的 **stack**：打出的牌先入栈、按 **LIFO** 结算，「打出」与「结算」是两个时刻。**但交互（instant / 栈非空时出牌）与优先权传递（priority passing）整体移除**——理由是它们**把对局时长拉得太长、决策点过多、复杂度高而玩法深度收益小**。**推论 ①：「一方行动完再交给另一方」的简单交替成立**——TurnManager **不需要**「优先权在谁手上」的内循环，只需要「轮到谁」。**推论 ②：EnemyManager 的代理面回落**——AI 只在自己的回合选行动，不必在对手的窗口中决策。**推论 ③：「定长 10 回合 → 时长可预测」恢复成立**——回合数固定、每回合步骤固定，无须再为交互次数另加时长护栏。**推论 ④：决策点粒度不必覆盖响应窗口**（粒度问题本身仍在，见待决问题）。Source: `handoffs/2026-08-02b-stack-without-interaction-and-three-step-turn.md`。
- **回合结构 = 三步：开始阶段 / 行动阶段 / 结束阶段（已定案 · 08-02b）。** **去掉战斗步骤，也不设双主阶段**：

  | 步骤 | 英文 / 代码 | 内容 |
  |------|------------|------|
  | **开始阶段** | `start step` / `TurnStep.Start` | 回合归属方 mana 恢复至 `manaLimit` → 触发「回合开始时」→ 抽牌 |
  | **行动阶段** | `action step` / `TurnStep.Action` | **唯一**的出牌阶段。**只有回合归属方能主动出牌** |
  | **结束阶段** | `end step` / `TurnStep.End` | 触发「回合结束时」→ 清理回合内的非永久条目 |

  **中文侧统一以「阶段」收尾、英文侧统一以 `step` 收尾（08-04b 定名）**；`main phase` 弃用——MTG 的 `main` 有 precombat / postcombat 两个 main 与同级 phase 作对照系，本作无战斗步骤、无双主阶段，对照系不存在，`action` 直接陈述这一步做什么。**与 `eventStart` / `eventEnd` 的同词不作重构**（事件级 vs 回合级，语境不同且从不同屏出现）。

  **三步是回合归属方的流程，双方不同时走**：每一方在自己的回合内各走一套完整的三步，「回合开始 / 回合结束」是**有归属方的时点**，不是双方同步发生的公共时刻。**步内顺序是规则的一部分**：mana 恢复在「回合开始时」触发**之前**、抽牌在触发**之后**，故「回合开始时」类效果能影响本回合的抽牌。**推论 ①：mana 恢复的是本回合归属方的 mana**——非归属方无法出牌，其 mana 在对手回合无用途，语义实为「每次轮到我时刷满」；「响应用谁的 mana」这一问题随交互移除而消解。**推论 ②：出牌时机是唯一的，且是全局规则（08-04b 定名收口）**——**一张牌只能在自己回合的行动阶段、且栈为空时打出**；`instant` 不存在，出牌时机不再是卡牌的一个属性。**`sorcery speed` 一词随之整条弃用**（与之相对的 `instant speed` 不存在，单一取值的维度不是维度）；**启动式异能与道具的使用窗口与出牌完全相同**。**推论 ③：「回合内状态」成为一个正式的状态生命周期档位**，与跨回合持续状态相对。**推论 ④：没有独立的战斗步骤**——道念的产出 / 削减全部经由行动阶段打出的卡牌，不存在第二条结算通道。Source: 同上。
- **手牌上限是一条恒定不变式，不设弃牌机制（已定案 · 08-02b）。** **手牌在任何时刻都不得超过上限**——**没有时间限制，也没有「结束阶段弃到上限」这类必须弃牌的机制**（结束阶段因此只做「触发『回合结束时』→ 清理回合内状态」）。**上限值待定。** **推论：约束点前移到会让手牌增加的时刻**（抽牌、以及任何「加入手牌」类效果）。Source: 同上。
- **满手时抽牌 = 抽不进（已定案 · 08-03 · 答结抽牌流程的前置条件）。** 满手时抽牌**抽不进——牌留在抽牌堆，这次抽牌无事发生**；「加入手牌」类效果同理落空。**「抽出即弃」与「直接销毁」两条路线均不采用。** **推论 ①：手牌上限是一条纯上界**——不产生任何弃牌堆流量、不消耗抽牌堆。**推论 ②：弃牌不是被规则强制的动作原语**（回合末不弃、满手不弃），弃牌堆只由「打出后进弃牌堆」与「卡牌效果显式弃牌」填充。**推论 ③：抽牌堆顺序不被满手情形扰动**，seeded 洗牌的确定性不因此分叉；「本回合抽 N 张」在满手时等价于抽 0 张。**推论 ④：满手的代价是 tempo 而非资源**——牌没丢，只是这一拍没拿到，手牌上限因此是节奏约束而非惩罚。呈现见 `ux/combat-ux.md`。Source: `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md`。
- **引入 battlefield（战场），栈与战场各升为一个 manager（已定案 · 08-03 · 承重）。** **battlefield = 战斗的公共区**，记录**场上的全部准确数据**——哪些卡牌正在生效、有哪些持续状态、有哪些触发器在等待。新增 **BattlefieldManager**（战场）与 **StackManager**（栈）两个 manager。**推论 ①：栈与战场是两个不同的区**——**栈 = 等待结算的队列，战场 = 已结算并正在生效的东西**；完整结算路径 = **打出 → 入栈 →（LIFO）弹出结算 → 效果施加 →（若是持续效果）落到战场**。**推论 ②：「回合内 / 跨回合状态」有了确切落点**——它们是**战场上带生命周期标记的条目**，结束阶段「清理回合内状态」= 清掉战场上标记为回合内的条目（取值边界仍待定）。**推论 ③：TurnManager 回落为纯粹的回合状态机**，只管「轮到谁、走到三步的哪一步」；栈的持有与结算从它身上拆走。**推论 ④：战斗内状态出现第三类持有者**——属于**某一方**的东西（mana、道念、手牌、卡组）仍归 CharacterManager / EnemyManager，**已离开手牌、正在场上生效**的东西归 BattlefieldManager；确切划线见待决问题。**推论 ⑤：决策点存档必须能恢复战场**（战场条目须可序列化）；**栈则可能不必落存档**——「栈非空时双方都不能出牌」意味着任何可退出的时刻栈应为空，待确认。**推论 ⑥：EnemyManager 规划意图时要读战场**——本回合出牌的合并结果会被场上的持续状态改写，故回合级一次性规划以战场当前状态为输入。**推论 ⑦：战场必须进入呈现层**（栈之外再加一个区，见 `ux/combat-ux.md`）。Source: 同上。
- **触发式效果的载体是开放的，不专属卡牌（已定案 · 08-03）。** 牌上的触发器、**场上的持续状态**、**CharacterPower（神通）** 都可能承载触发式效果，**清单开放**、日后可再增载体。**推论 ①：需要一个统一的触发注册 / 匹配面**——否则每类载体各写一套「谁在监听哪个时点」的匹配逻辑。**推论 ②：该注册面坐在 battlefield 上**（「场上有哪些触发器在等待、挂在谁身上」正是场上准确数据的一部分）。**推论 ③：轮回级能力必须能被战斗内读到**——参战方组装时要把角色持有的神通**注册进战场**，故本服务要读 CharacterProfile 上的这份列表。**推论 ④：压栈者与载体解耦**——触发命中后把被触发的能力压入栈的一律是 **StackManager**。仍待定：跨归属方的触发时点、以及 PlayerPower（法则）能否也承载战斗内触发，见待决问题。Source: 同上。
- **栈深由触发式能力入栈撑起（已定案 · 08-02b · 承重）。** **在栈上的牌可以触发能力，被触发的能力也进栈**，因此**即便只打出一张牌，栈深也可以大于 1**——这就是移除交互之后 stack 的承重点：**它管的是触发的解决顺序，不是双方互插牌**。**推论 ①：「栈非空时不能出牌」对双方都成立**，不为归属方开口子（「允许行动阶段连续压入多张牌再统一结算」这条候选路线**不采用**）。**推论 ②：LIFO 有了实际意义**——一次结算可能连锁产生多个触发，后触发的先解决，结算顺序成为卡牌设计可利用的资源。**推论 ③：「多张削减效果同时在栈上」会真实发生**——**截断时机已于 08-03 答定：在每一次结算时截断**（见下条）。**推论 ④：栈必须进入呈现层**（见 `ux/combat-ux.md`）。Source: 同上。
- **道念的下限 0 在每一次结算时截断（已定案 · 08-03）。** 饱和减法**逐次截断**，不是全栈结算完后再截断。**推论 ①：更保护落后方，且差异可算**——对方道念 5、栈上有「削 8」与「+3」：逐次截断 → `5-8 → 0`，再 `+3 → 3`；全栈后截断 → `5-8+3 = 0`。**溢出的削减量不结转。** **推论 ②：LIFO 顺序对最终结果有实际影响**——削减与产出交错时结算顺序改变结果，「栈序是卡牌设计可利用的资源」由此从原则变成具体算术。**推论 ③：`PlayResult` 必须携带本次的实际削减量**——截断发生在每一次结算，故每次结算都是可观测事件，「意图削减量 vs 实际削减量」的差在连锁中必然出现。见 `systems/scoring.md`。Source: `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md`。
- **回合数与胜负判据是遭遇参数，不是常量（已定案）。** **标准 Combat = 10 回合、道念高者胜**；**Practice / Finale 可改写回合数与胜负条件**（Practice 更简单、Finale 更难，对位 Balatro 的 small / big / boss blind）。**推论：TurnManager 仍是定长循环，但长度来自本场遭遇的配置**，且胜负判据是一个可替换的判定而非写死的比较——承载位置未定，见待决问题。Source: 同上。
- **卡牌类型 = 六类，按「所在区 + 结算后去处」切分（已定案 · 08-04b · 承重）。** `CardType` 是六值枚举：**法术 `Sorcery`**（一次性，进弃牌堆）· **灵宠 `Creature`**（结算后作为实体永久物落战场）· **阵法 `Enchantment`**（非实体永久物落战场，埋伏是其次类型）· **法宝 / 古宝 `Item`**（不洗进卡组，存于储物袋）· **神通 / 法则 `Power`**（开局直接入场的受保护永久物）· **业障 `Affliction`**（可打出但无正面效果，唯一作用是把自己送进弃牌堆）。**三个来源区各自绕开的东西不同**，这是六类之间最本质的结构差别：**卡组**（法术 / 灵宠 / 阵法 / 业障，受抽牌运制约）· **持有的道具**（玩家侧来自储物袋、敌人侧来自 `EnemyData`，不受抽牌运制约）· **开局入场**（`Power`，无需玩家动作）。**推论 ①：本服务要处理三条来源路径而非一条**——`DeckModule` 之外，参战方还各持一份「本场可用道具」，且组装阶段要把 `Power` 注册进战场。**推论 ②：类型间的具体差异化留待日后**，本条只定下不定就无法写 schema 的结构性差别。Source: `handoffs/2026-08-04b-mtg-loanwords-card-types-and-intent-snapshot.md`。
- **异能三分：静止式 / 启动式 / 触发式（已定案 · 08-04b）。** **静止式 `static ability`** 不入栈，载体在战场上即持续生效；**启动式 `activated ability`** 启动后压栈，可用窗口 = **自己回合的行动阶段、栈为空时**（与出牌完全同窗口）；**触发式 `triggered ability`** 命中后由 StackManager 压栈。这补完了 08-03「载体开放」的另一半：**载体说的是「挂在谁身上」，异能类型说的是「怎么生效」，两者正交**。**关键自洽点：启动式异能不重新引入交互**——它的窗口就是出牌那一个窗口，不构成「在对手回合插手」的通道，08-02b 的定案不被松动。**推论 ①：异能抽为独立的可复用资源 `AbilityData`**，由 `CardData` / `PowerData` / `ItemData` / 战场条目共同引用（触发匹配逻辑不能写死在卡牌类型里）。**推论 ②：静止式异能是 BattlefieldManager 的一条与栈无关的写入路径**——载体一进场即时生效、一离场即时失效。**推论 ③：启动式异能给 mana 第二个花费去向**——此前 mana 只用于出牌，手牌不足时纯浪费；现在场上永久物也能吃 mana，沉没成本被缓解，战场从纯被动区变成有操作面的区。Source: 同上。
- **永久物（permanent）把战场条目切成两类（已定案 · 08-04b）。** **永久物 = 落在战场上、无限期存在直到被移除或战斗结束的条目**（灵宠 / 阵法 / `Power`）；**非永久条目 = 带生命周期标记的持续状态**（回合内 / 跨回合 / 持续 N 回合）。**与 MTG 的出入：** MTG 的 permanent 是区的成员资格（在战场上的一律是永久物），**本作的永久物只是战场条目的一个子集**。**推论 ①：结束阶段的清理边界被收窄了一半**——结束阶段**只清理非永久条目中标记为回合内的那些，永远不碰永久物**，「永久物会不会被误清」这个歧义直接消失。**推论 ②：「可被移除」只对永久物有意义**，针对 / 移除类效果的目标合法性因此有了类型级判据。**推论 ③：永久物与非永久条目的存档字段形态不同**——前者带来源卡牌 `Id` + 运行态，后者带生命周期标记 + 剩余回合数。Source: 同上。
- **触发条件可跨归属方，埋伏牌由此成立（已定案 · 08-04b · 答结 08-02b 的待决问题）。** 时点本身有归属方（「回合开始时」是某一方的），但**监听方不必是该归属方**——一个条目可以监听「**对手的**回合开始时」「**对手**打出牌时」（`TriggerOwnerScope { Self / Opponent / Either }`）。**这是「规则体系须支持奥秘式埋伏牌」这条要求的逻辑前提**：埋伏的本质就是「在对手回合的某个时点触发」。埋伏 = **阵法的次类型**，面朝下布置、是永久物、触发后进弃牌堆、**同名不可重复布置**、**对手只知「有一张埋伏」不知是哪张**。**推论 ①：埋伏是本作唯一一条「在对手回合发生作用」的通道**——玩家不能在对手回合主动响应，但可以预先布置自动响应的东西；结算入口不变（StackManager 压栈），**这是移除交互后 stack 仍然承重的又一个证明**。**推论 ②：EnemyManager 从战场读到的是埋伏计数而非条目内容**——AI 与玩家的信息完全对称，**这是本作第一处双向对称的信息规则**（意图揭示是单向的）；AI 可据此变得谨慎但无法针对性规避，故**埋伏的威慑力与实际效果是两件事**。Source: 同上。
- **道具（`Item`）是战斗内唯一会即时写 Profile 的卡牌行为（已定案 · 08-04b · 承重）。** 法宝 / 古宝**不洗进卡组**，存于角色的**储物袋**（跨战斗内外存在，上限 99）；战斗只从中筛出 `UsableScene` 含 `InCombat` 的那些，形成参战方各持一份的**「本场可用道具」**（敌人侧来自 `EnemyData`——**敌人没有储物袋但同样持有道具**，故容器与视图必须分开）。**使用窗口 = 自己回合的行动阶段、栈为空时**，与出牌完全同窗口：**「随时可用」= 不受抽牌运制约，不是不受回合限制**，交互不回归，`RunCombatAsync` 状态机形状不变。**古宝的使用次数即时经 `ProfileManager.TryApply` 写 PlayerProfile，不攒到收口**——堵死「用完退出重进恢复次数」的窗口，与既有的「战斗过程中的变更即时经 ProfileManager，`Spoils` 只承载收口产出」一致。**推论 ①：敌人的道具效果计入意图数值**——意图是本回合全部行动的推算结果，道具是行动的一种；排除它会让意图失去参考价值，故 EnemyManager 的回合级规划输入多一个来源（**不新增机制**：回合级一次性规划本就排除逐张即时决策）。**推论 ②：道具绕开手牌上限这条节奏约束**，是有意的松弛阀——卡组受抽牌运摆布，道具是玩家可规划的确定性资源；代价是**道具强度必须低于同费法术**（归 `systems/balance.md`）。Source: 同上。
- **`Power` 在参战方组装阶段入场，故本服务要读两个 Profile（已定案 · 08-04b · 答结 08-03 的待决问题）。** **法则（PlayerPower）能承载战斗内触发**，与神通（CharacterPower）走同一条路径：**入场条件是两条与门——`status == 开启` 且 `UsableScene` 含 `InCombat`**（`status` 关闭 = **不入场**，而非「入场但不生效」；两个字段正交不可合并——`UsableScene` 是内容侧静态属性，`status` 是玩家侧运行时开关）。入场发生在**第一个开始阶段之前**，故「回合开始时」类触发从第 1 回合起就已挂载。**推论 ①：这是 combat-service 第一次需要读 PlayerProfile**——参战方组装流程要同时读 CharacterProfile 的神通列表与 PlayerProfile 的法则列表。**推论 ②：`Power` 一律受保护**（战场条目上的 `IsProtected` 在 `CardType.Power` 落场时统一置 true，**不由 `PowerData` 逐条目声明**），**唯一后门 = 效果侧声明 `IgnoresProtection`**；其稀缺性与卡面明示**归内容侧纪律，代码不加硬规则保护**（只留 `PushWarning` 软检查）。**推论 ③：`Power` 无 mana 费用**（它不被「打出」，启动式异能的启动费另算），且**是唯一不产生弃牌堆流量、也不产生栈上「打出」事件的类型**——它的触发式异能照常压栈，但它自身永远不入栈。**推论 ④：不引入 MTG 的指挥区（command zone）**——战斗内已有卡组 / 手牌 / 弃牌堆 / 栈 / 战场 / 本场可用道具六处位置，为一类不可交互的条目再开第七处，收益不抵竖屏 UI 与存档形态的成本。Source: 同上。
- **战场与两个参战方 manager 的划线判据 = 「是否在场上生效」，不是「属于谁」（已定案 · 08-04b · 答结 08-03 的待决问题）。** **层级不动**：五个 manager 保持平级，`DeckModule` 仍是第三级；BattlefieldManager 不提级，两个参战方 manager 不降级。

  > **判据：** 一件东西**在场上生效、可被效果针对 / 查询、需在结束阶段被清理、需进决策点存档** → **战场条目，归 BattlefieldManager**，条目自带 `OwnerSide`。**参战方的私有资源与牌堆**（mana、道念、手牌、卡组、本场可用道具）→ **归 CharacterManager / EnemyManager**。

  按此判据，「我方本回合所有牌 +1 道念」是**战场条目**（`OwnerSide = Character` 的非永久条目），不是参战方状态——它要被针对、要被清理、要进存档，三件事全是战场的活。**「属于谁」只是它的一个字段，不是它的住处**：这正是该问题此前卡住的地方——只用「属于谁」划不开。**推论 ①：双方场区不分开记录**——单一战场记录 + `OwnerSide` 字段，不建两个并列容器；跨归属方的触发（埋伏监听「对手打出牌时」）与全场查询（「场上所有灵宠」）在单一记录下是一次遍历，分成两个容器则每次查询都要合并，呈现层按 `OwnerSide` 分区渲染即可。**推论 ②：读侧统一、写侧分权**——需要「整场全部信息」的场合（EnemyManager 规划意图、决策点存档、UI 组装）读本服务组装的 `CombatSnapshot`；写入仍各归其主。**推论 ③：不把 BattlefieldManager 提为参战方之上一层**——四条理由：① 它会变成 god object（TurnManager 恢复 mana / 抽牌、StackManager 写双方道念都要经它转发）；② 级联降级会把 `DeckModule` 压到第四级，强迫回答「module 以下的下沉判据」这个尚无判据的问题；③ 层级词表的拆分轴是「生命周期层 + 行为边界」而非「谁的信息全」，而战场与两个参战方的生命周期完全同长；④ 「拥有整场信息的顶点」已由 combat-service 本身 + `CombatSnapshot` 承担。Source: 同上。
- **战斗内的一切写入经 ProfileManager。** 耗 mana、消耗道具、获得战利品、以及**收口时按道念差扣 lifeTotal** 都走 `profile-service.ProfileManager.TryApply(...)`——本服务不直接改 CharacterProfile 字段。**道念本身是战斗内的运行态**（活在 `CombatSnapshot` 里），战斗结束即消失，不落 CharacterProfile。
- **敌人意图三档揭示，分界值已给全（已定案）。** **默认揭示，越级才降级**——不是 Slay the Spire 式的常驻免费预告，也不是全盘隐藏。判据分两层：**先看是否越阶，再看同阶差值**（`diff` = 敌人全局等级 − 角色全局等级）：

  | 情形 | 玩家看到 |
  |---|---|
  | **越阶**（敌人境界高于角色） | **完全无信息** —— 不论 `diff` 多小 |
  | 同阶 · 第一篇章、`diff ≤ −2` | **完整意图**：综合类型 + 综合数值 |
  | 同阶 · 第一篇章、`−1 ≤ diff ≤ +1` | **仅类别**：攻击 / 防御 / 增益 / 特殊——有符号无数值 |
  | 同阶 · 第一篇章、`diff ≥ +2` | **完全无信息**，且**不提供任何替代线索** |
  | 同阶 · 第二 / 第三篇章、`diff ≤ −1` | **完整意图** |
  | 同阶 · 第二 / 第三篇章、`diff = 0` | **仅类别** |
  | 同阶 · 第二 / 第三篇章、`diff ≥ +1` | **完全无信息** |

  **「越阶 = 黑箱」是一道硬门**：它把「境界鸿沟」从数值差提升为结构性规则——炼气十三层对上筑基初期（全局仅差 1）同样是彻底黑箱。**同阶阈值整体收紧一级，使三档在 `±2` 带内全部可达**，篇章分档保留。**完整意图 = 「压到带内下界」**（ch1 `−2` / ch2 · ch3 `−1`），仍是碾压专属，只是尺子短了。**推论 ①：第二档在 ch1 是常态档**（`−1 ~ +1` 三格），但**在 ch2 · ch3 收窄为 `diff = 0` 单一取值**——「仅类别是常态呈现」这条判断只在 ch1 成立，第二档视觉语言的承重级别须按此重估。**推论 ②：ch2 · ch3 黑箱面积显著变大**（约五分之二的同阶遭遇 + 境界末两级的越阶），**不做可读性补偿**，压力转嫁给图鉴 / 卡面文本 / 道念主视觉。**推论 ③：探查（probe）的价值上升**。**推论 ④：意图揭示不再承担教学职能**。呈现侧见 `ux/combat-ux.md`；三档需要一个正式枚举 `IntentRevealTier { Full, CategoryOnly, Hidden }`。Source: `handoffs/2026-08-02c-intent-threshold-inversion-and-aggregate-intent.md` + `handoffs/2026-08-06d-combat-open-questions-mass-closure.md`。
- **探查只能把档位升一档，不能打穿越阶黑箱（已定案 · 规则层）。** 完全无信息 → 仅类别；仅类别 → 完整意图；**已是完整意图 → 无效果，且 UI 应禁用该操作**。**理由是硬的**：「越阶 ⇒ 一律完全无信息」是一条结构性规则，若探查能把越阶敌人一次打到完整意图，**这条规则就被一件内容道具整个绕过**，境界压迫感失效。升一档下，越阶敌人被探查后仍只到「仅类别」——玩家拿到了实质帮助，但黑箱的结构不被打穿。**探查只揭示当回合已公布的那份快照，不重算、不延续到下回合** ⇒ 它是一个**纯呈现层开关，`RunCombatAsync` 的形状完全不变**。Source: `handoffs/2026-08-06d-combat-open-questions-mass-closure.md`。
- **意图是回合级的综合描述（已定案 · 承重）。** **一个回合对手可以打出多张牌**，故意图**不是「下一张牌是什么」**，而是对**本回合全部出牌的汇总**：**综合数值 = 计算后合并的最终结果**（一个结果值，例：削减 12；不是 4+5+3 的明细，也不是未合并的多条），**综合类别 = 主类别并行陈列**（一回合跨类别时并列各主类别，不压缩成单一类别、不归入「特殊」）。**推论 ①：不暴露张数与逐张分解**——即便第一档，玩家拿到的也是最终结果而非牌序。**推论 ②：EnemyManager 的 AI 是回合级一次性规划**——必须在呈现意图之时就已定好本回合整套出牌**并算出合并结果**，这排除了逐张即时决策的 AI 形态。**推论 ③：意图数值 ≠ 实际结算量**——道念削减是下限 0 的饱和减法且触发也入栈，故综合数值是**声明的量**，与「`PlayResult` 需区分意图削减量 vs 实际削减量」合流。Source: 同上。
- **意图只在玩家回合呈现，内容是敌人的下一个回合（已定案）。** 敌人回合内**不呈现意图**（那时它正在执行出牌）。**推论 ①：意图的用途是为玩家本回合的出牌决策提供依据**——这也解释了为何合并成一条结果值就够用（玩家要的是「该防多少 / 追多少」，不是牌序）。**推论 ②：敌人 AI 的规划时点前移到玩家回合开始之前**（结合回合级一次性规划：玩家回合开始时，敌人下一回合的整套出牌已定案）。**推论 ③：意图是玩家回合内的常驻信息**，随回合归属切换出现 / 消失。Source: 同上。
- **意图即快照：公布后不重算，但不保证与执行一致（已定案 · 08-04b 修正措辞 · 承重）。** **意图 = 敌人在玩家回合开始前，按当时局面用公式推算出的本回合预期决策链路的快照。** 计划在玩家回合开始时定案，**玩家在行动阶段做什么都不会改写它**，也不刷新显示——玩家因此能据它布局（「它要打 12，我这回合防住 12」）；但**敌人回合的实际执行按执行时的真实局面求值**，与已公布的快照可能有偏差。**「承诺」的准确含义是「公布后不重算」，而非「结果必然如此」。**
  - **推论 ①（承重 · 代码面净减）：EnemyManager 不需要一致性校验与回退逻辑。** 执行阶段逐步走规划链路，每一步按**执行时的实际状态**求值；不可执行的步骤自然落空。**没有「检测到不一致 → 选择处理策略」这条分支**，`RunCombatAsync` 的敌人回合形状不变——三个候选解（跳过该张照打其余 / 降级执行 / 允许临场替换）**全部不采用**，它们都在为「让快照与执行对齐」造机制，而快照本就不承担对齐义务（「临场替换」还等于开了重算的口子）。
  - **推论 ②：EnemyManager 的代理面进一步收窄**——AI 决策发生在一个明确时点（玩家回合开始之前），不必挂钩玩家的出牌事件做重算，也不需要「响应式 AI」这条路径。
  - **推论 ③：埋伏牌与敌人道具是偏差的正常来源，不是需要专门裁决的高频落空场景**——与「资源变化」同属一类：执行时局面不同了，结果就不同。
  - **推论 ④：「意图数值 ≠ 实际结算量」从异常升为常态**，与「道念下限 0 在每一次结算时截断」「`PlayResult` 须携带本次实际削减量」完全合流：**意图是声明的量，`PlayResult` 是发生的量。**
  - **推论 ⑤：意图快照不必单独进存档**——它由「局面 + 已持久化的 RNG `State`」确定性重算得到（规划走 combat 子流）；若重算成本高可作为缓存写入，但那是优化不是正确性要求。
  - **推论 ⑥：难度调节的旋钮不变**（规划算法与卡组，不在反应速度）——快照语义没有给 AI 增加临场调整能力。
  - **代价：呈现层承担解释责任**——意图的语气须是「预估」而非「契约」，且敌人回合的执行过程须逐步可见，见 `ux/combat-ux.md`。
  Source: `handoffs/2026-08-02c-intent-threshold-inversion-and-aggregate-intent.md` + `handoffs/2026-08-04b-mtg-loanwords-card-types-and-intent-snapshot.md`。
- **探查（probe）是意图之外的第二条信息通道。** 意图揭示档位由等级差**被动**决定；**探查**则是玩家**主动付出代价换取当回合敌人意图**的效果。方向已定、定名已成，**具体形态（花费形式 / 授予途径 / 可探查档位）归卡牌与技能内容的横向扩展阶段，本阶段搁置**。「某些能力或道具授予窥视意图」即探查能力的授予形式。Source: 同上。
- **意图不单列 manager。** 意图生成隶属 **EnemyManager**，与敌人实例状态、AI 行为选择同属一个组件——三者共享同一份敌人运行态，拆开只会让它们互相伸手。**EnemyManager 内部不再细分职能（已定案）。** Source: `handoffs/2026-07-30-claude-engineering-scope-enemy-manager-and-requirement-breakdown.md` + `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md`。
- **CharacterManager 与 EnemyManager 平级、共享接口、驱动方式相反（已定案）。** 两者管理战斗的两侧参战方，**共有大量接口定义**（生命 / mana、卡组、状态、出牌）；差异只在**谁驱动决策**——EnemyManager 含**代理操作**（AI 行为选择、意图生成），CharacterManager **监听玩家操作**。Source: `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md`。
- **每个参战方各有一个 `DeckModule`（已定案）。** 卡组不是全局单件：**每个 character、每个 enemy 各持有一个**，由 CharacterManager / EnemyManager 各自持有。**敌人也出牌**，且可带定制卡组（例如 Finale 的天劫，以及 `EnemyData` 的样本卡组经物化改写而来）。`DeckModule` 是**第三级抽象（module）**，不列入本服务的 manager 清单——层级词表见 `systems/architecture.md`。Source: 同上 + `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。
- **Practice / Finale 复用本服务的参战方结构。** 两者都用 EnemyManager + CharacterManager，是 Combat 的**变体**（同一套回合循环与参战方模型，独立的胜负条件与奖励结构）。见 `systems/adventure-event/practice/`、`finale/`。Source: 同上。
- **事件过程按决策点落存档（已定案）。** 战斗**不是**存档盲区：事件过程中（含战斗内）在**决策点**落存档，使「退出重进」得到的是同一个局面与同一份 RNG 状态。**`selectCost` 不回滚**——选中事件时施加的成本（含 `lifeSpanCost`）一经施加即成事实。**决策点的具体粒度未定**，见待决问题。Source: 同上。
- **栈必须落存档：决策点并不总落在栈为空的时刻（已定案 · 08-05 · 承重 · 推翻 08-03 推论 ⑤）。** **触发式异能在栈上若需要选择目标，那次目标选择本身就是一个决策点**，故「任何可退出的时刻栈都是空的」这条假设不成立。08-03 推论 ⑤ 的依据是「栈非空时双方都不能出牌」——**「出牌时机唯一」这条规则本身没错，错的是把它等同于「唯一的玩家输入时刻」**。
  - **推论 ①：栈条目须可序列化**，与战场条目同级：来源 `Id`、已选定的目标（`TargetRef` 列表）、「正等待选择目标」这一挂起态、栈内位置。
  - **推论 ②（承重 · 代码面）：结算不是一个原子的同步过程。** LIFO 弹栈结算的中途可以停下来等玩家输入，**`RunCombatAsync` 的结算循环因此必须是可挂起、可从中途恢复的状态机**，而不是一个跑到底的循环。这是本条对本服务的实际要求。
  - **推论 ③：决策点粒度的清单多一类。** 除回合 / 出牌边界外，**结算过程中的目标选择**也是决策点——08-02b「回落到回合 / 出牌这一级」被推回一层。粒度问题本身仍未答定，但已知它至少要覆盖这一类。
  - **推论 ④：这不重新引入交互。** 目标选择是**结算自身的一部分**（这张牌 / 这个触发指向谁），不是「在对手窗口插手」的响应机会；08-02b 移除交互与优先权的定案不被松动。
  - **推论 ⑤：决策点只在需要玩家输入时产生。** 敌人的触发式异能同样可能需要选目标，那由 EnemyManager 在执行时自行决定，**不产生决策点**。
  Source: `handoffs/2026-08-05-level-band-stack-save-and-token-free-deck.md`。
- **确定性。** 洗牌、敌人行为掷骰等一律用 `life-cycle-service.SeedManager` 派生的 **combat 子流**，与地图 / 商店 / 奖励子流隔离，避免 desync。同一 seed 必须复现同一场战斗。**派生形态 = `Hash64(combatStreamSeed, eventId)`**——`attemptIndex` 那一层已整层删除（篇章重试生成新的 `CycleSeed`，见 `life-cycle-service.md`）；`eventId` 这一层保留，它让不同事件的战斗随机互相隔离，成本为零。**敌人抽牌走与玩家抽牌不同的子流**，使玩家侧的一次额外抽牌不打乱敌人牌序。Source: `handoffs/2026-08-06d-combat-open-questions-mass-closure.md`。

## 战斗存档：`ActiveCombat`

> **共用公理：决策点 = 战斗状态机唯一可以停下来的地方。** 存档 schema、取消语义、决策点清单三者全部由它导出。Source: `handoffs/2026-08-06d-combat-open-questions-mass-closure.md`。

**`ActiveCombat` 是 `CharacterProfile` 上一个可空块**：战斗开始时创建、`eventEnd` 收口时置空。它**不进 `pastEvent`**（历史事件只留定稿快照），也不与 `Rng.Streams[]` 混住——它是**事件内的中间态**，寿命短于一次事件。挂 `CharacterProfile` 使 diff 天然落在 sync-service 既定的 diff 单位上，**无需新增同步单元**，且与「每篇章至多一个 ongoing 事件」自洽。

```jsonc
"activeCombat": {                    // null = 当前没有进行中的战斗
  "eventInstanceId": "evt-0042",     // 归属的 EventOption.InstanceId，读档时校验一致
  "encounterId": "enc_wolf_pack",
  "turnLimit": 10,                   // 遭遇参数（Practice 8 / Finale 12）
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

**参战方（`sides`，恰两条）**：`side` · `momentum` · `currentMana` / `manaLimit`（战斗内不变，落它只为读档自洽）· `drawPile` / `hand` / `discardPile`（`CardInstanceId` **有序**序列）· `instances` · `items` · `enemyRef`（仅敌方）。

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
| `sourceId` | `string` | `CardId`（灵宠 / 阵法）或 `PowerId`（神通 / 法则） |
| `sourceInstanceId` | `string?` | 仅 `PermanentCard`：它原本是卡组里的哪张牌（**闭集的另一半**——牌离开手牌落到战场，实例仍在） |
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

**不落存档的可重建项**（沿「可重算的东西不进存档」判据）：`isProtected`（`kind == PermanentPower` 即 `true`）· **触发器注册面**（由 `sourceId` 解析出的 `AbilityData` 重建，「谁在监听哪个时点」是纯派生数据）· **`Power` 的入场本身**（由两个 Profile 的持有列表 + `status` + `UsableScene` 重放）· 合法目标集 · 意图快照。

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

**明确不是决策点**（同样重要）：弹栈结算的**每一次**弹出（除非因此进入 D4）· **敌人回合内部**的任何一步（玩家在其中没有输入，D5 一个点即覆盖整个敌人回合，它是一段可确定性重放的区间）· 意图呈现 · 战后奖励选择。

- **密度 ≈ 31 个决策点 / 场**（10 回合、玩家 5 个回合、每回合出 2~3 张牌）。**保留 D2**——它是「退出重进得到同一局面」这条承诺在最自然位置的兑现；**若实测超预算，第一刀砍 D2 的 push 而非 D2 本身**（存档点与 push 已解耦，正是为此准备的）。
- **软阻塞闸门不受影响**：`sync-service` 的缓冲上限口径为「未同步的**事件级**存档点 ≥ 3」，**战斗内 D0–D5 照常写本地、照常防抖 push，但不参与软阻塞判定**——否则每场战斗的第三个决策点就会触发模态。**连带（08-09 定案）：D0 的 `Immediate` flush 失败也不触发阻塞**——同一个点不能一边被排除在闸门计数外、一边又能独立挡住玩家；且此时 `SelectCost` 已施加，挡住 = 付了成本却拿不到事件。「flush 是尝试、闸门是状态」见 `sync-service.md`「`Immediate` flush 的失败语义」。
- **需要选目标的触发式异能按稀缺配额编排**：占全部触发式异能 **≤ 10%**（加载时统计 + `PushWarning`）、一场标准 Combat 期望进入挂起态 **1~2 次**（编排口径，不可机械化）。频度天然低——玩家**主动出牌**的目标在打出时就选定（`PlayCard(card, target)` 的签名已定，入栈时 `targetState = Resolved`），挂起态**只**来自「压进去的东西在结算时回头问一句『指谁』」；敌人侧的目标选择由 EnemyManager 自行决定、不产生决策点。**稀少改变的是性能预算，不是正确性要求**：D4 必须在清单里。连带成立——**挂起态存档不做任何专门优化**，`ActiveCombat` 全量序列化足够，**栈的增量写入不做**。

### 挂起态的恢复与取消

- **恢复回到该选择点，栈原样挂起，不允许反悔。** 回退到更粗的边界意味着重放已弹栈结算的条目，而 RNG `State` 已随之前进——要么局面分叉，要么就得回滚 `State`，那等于给玩家开了「不满意就退出重掷」的窗口。与「`SelectCost` 不回滚」同一条纪律：**已经发生的事就是发生了**。且若恢复只能回到更粗的边界，「存挂起态」本身就没有存在意义。
- 恢复流程与正常推进路径**共用同一段代码**：读 `ActiveCombat` → 重建实例表 / 战场 / 栈 → 重放派生项 → `pending != null` ? 按当前局面重算合法目标集并直接进入选目标态 : 按 `step` 进入对应阶段。
- **`ct` 只在决策点被观察**（`AdvanceToNextDecisionPoint()` → `PersistDecisionPoint()` → `ThrowIfCancellationRequested()` → `WaitForPlayerInput()`）。三条推论：**取消点与存档点永远重合**（对齐问题因此**不存在**，而不是「靠约定去对齐」）· **中间态永不需要持久化**（结算走到一半被取消是不可能的）· 等待输入期间收到取消则落在 D1/D2/D4 之一，恢复时回到同一处等待。这与「结算循环必须可挂起可恢复」不冲突——**可挂起的位置就是决策点，两者是同一个集合**。
- **UX 硬要求：选目标态必须自解释**（交代是哪张牌 / 哪个异能在要求选目标、它要做什么），不能依赖玩家的短期记忆——玩家可能隔几小时才回来。见 `ux/combat-ux.md`。
- 取消的触发方清单与 `AdvanceStage.Cancelled` 见 `life-cycle-service.md`。

## 管理器

| manager | 职责 |
|---------|------|
| **TurnManager** | **定长回合**的状态机（标准 Combat = 10 回合、双方各 5，交替；Practice / Finale 可改写长度）。每个回合走**三步**：**开始阶段**（归属方 mana 恢复至 `manaLimit` → 触发「回合开始时」→ 抽牌）→ **行动阶段**（唯一出牌阶段，只有归属方出牌；**无优先权内循环**）→ **结束阶段**（触发「回合结束时」→ 清理回合内状态）→ 交给另一方。**三步是归属方的流程，双方不同时走。** 打满后做胜负判定（Combat 档 = **道念高者胜**，相等 = `Draw`，只发 `baseReward`），随后走**奖励计算与可选奖励选择**再收口。**它只管「轮到谁、走到哪一步」——栈的持有与结算归 StackManager** |
| **CharacterManager** | 玩家侧参战方：角色的对战状态、其卡组、**本场可用道具**、出牌通道；**监听玩家操作** |
| **EnemyManager** | 敌人侧参战方：敌人实例与状态、其卡组、**本场可用道具**（来自 `EnemyData`）、**AI 行为选择与意图（intent）生成**；**代理操作**。内部不再细分职能。规划本回合整套行动时**读战场当前状态 + 本场可用道具 + 对手的埋伏计数** |
| **BattlefieldManager** | **战场（battlefield）**：场上正在生效的条目、**触发器注册面**（谁在监听哪个时点）与清理。条目分**三档**：**永久物 · 常规**（灵宠 / 阵法结算后落场，可被针对，永不被结束阶段清理）· **永久物 · 受保护**（`Power`，开局入场，`IsProtected = true`，唯一后门是效果侧的 `IgnoresProtection`）· **非永久条目**（持续状态，带生命周期标记，结束阶段清理标记为「回合内」的那些）。**静止式异能是一条与栈无关的写入路径**（载体一进场即生效、一离场即失效）。**单一战场记录，不分双场区容器**——条目自带 `OwnerSide` / `IsProtected` / `SourceId`，呈现层按 `OwnerSide` 分区渲染 |
| **StackManager** | **栈（stack）**：压栈、**LIFO 结算**、连锁触发的解决顺序。**被触发的能力由它压栈**（与触发挂在哪个载体上无关）；结算产生的持续效果落到 BattlefieldManager |

**`DeckModule`（第三级）不是平级 manager。** 抽牌堆 / 手牌 / 弃牌堆的流转与 seeded 洗牌由 CharacterManager 与 EnemyManager 各自持有的 `DeckModule` 承担，**每个 character / enemy 一份**。它与那套共享的参战方接口是同一件事的两面。

**「本场可用道具」是与 `DeckModule` 平级的第三级持有物，且不称储物袋。** 参战方各持一份：**玩家侧 = 储物袋中 `UsableScene` 含 `InCombat` 的筛选结果**，**敌人侧 = `EnemyData` 的道具持有列表**。**储物袋是角色的道具容器（跨战斗内外存在、上限 99），不是战斗概念**——敌人没有储物袋却同样持有道具，正说明容器与本场视图必须分开。Source: `handoffs/2026-08-04b-mtg-loanwords-card-types-and-intent-snapshot.md`。

**参战方组装阶段读两个 Profile。** 组装时除卡组与道具外，还要把 **CharacterProfile 的神通列表**与 **PlayerProfile 的法则列表**按「`status == 开启` 且 `UsableScene` 含 `InCombat`」过滤后**作为 `CardType.Power` 注册进战场**——入场早于第一个开始阶段。**这是本服务第一次需要读 PlayerProfile。** Source: 同上。

**栈与战场是两个区，不是一个。** 栈 = **等待结算**的队列；战场 = **已结算并正在生效**的东西。结算的完整路径：**打出 → 入栈 →（LIFO）弹出结算 → 效果施加 →（若是持续效果）落到战场**。Source: `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md`。

## API 面（契约）

> 总则与共享类型见 `systems/architecture.md`「API 契约总则」。本服务**纯本地**，永不跨进程边界；`RunCombatAsync` 是形态 C（跨多帧、由信号推进），其余为形态 A。Source: `handoffs/2026-07-27b-service-api-contracts.md`。

| 方法 | 形态 | 完整签名 | 失败语义 |
|------|------|----------|----------|
| 打一场 | **C** | `Task<CombatResult> RunCombatAsync(EncounterSpec encounter, CancellationToken ct)` | 未知 `EncounterId` = 坏数据 → `PushError` + 抛；胜负是**结果**不是失败 |
| 出牌 | A | `PlayResult PlayCard(CardInstance card, TargetRef target)` | 业务失败（mana 不足、目标非法）→ `PlayResult`，绝不抛 |
| **提供目标** | A | `PlayResult ProvideTarget(TargetRef target)` | 非法目标 → `PlayResult { Accepted = false, Rejection = IllegalTarget }`，绝不抛；服务端仍以 `LegalTargets` 为准校验 |
| 结束回合 | A | `void EndTurn()` | — |
| 战斗态 | A | `CombatSnapshot Snapshot { get; }` | 只读视图，供 ViewModel 组装；**必含双方道念**；**按变更广播 + 缓存**，不是每次访问现组装 |

```csharp
public sealed record EncounterSpec(               // sealed record 而非 struct：字段多、含引用类型、落存档、非热路径
    string            EncounterId,                // 溯源；战斗类事件下 = EventOption.InstanceId
    EventType         EventType,                  // Practice | Combat | Finale —— 仅供呈现 / 埋点，规则不由它派生
    EnemyInstance     Enemy,                      // 单数：本作不存在多敌人场景
    int               TurnLimit,                  // 双方合计回合数；Practice 8 / Combat 10 / Finale 12
    VictoryRule       VictoryRule,
    string            RewardPoolId,               // 可选奖励抽取池
    ProfileChangeSpec BaseReward);                // 本场 baseReward，物化时定稿

public readonly record struct VictoryRule(
    int  WinMargin,          // 角色须领先的点数。Combat = 1（严格高于）、Practice = 0、Finale = N
    bool DrawCountsAsLoss);  // 差额未达 WinMargin 时：false = Draw，true = Defeat

public readonly record struct CombatResult(
    CombatOutcome     Outcome,            // Victory | Draw | Defeat | Fled（Draw = 道念相等，只发基础奖励）
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
    IntentView?           Intent,                 // 仅玩家回合有值；不达档时为 null
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
    string     SourceCardId,                      // 呈现用（「埋伏·XX 需要一个目标」）
    TargetKind AllowedKinds,
    IReadOnlyList<TargetRef> LegalTargets);       // 预先算定的合法目标集，UI 直接据此高亮

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

- **`CombatSnapshot` / `PlayResult` 必须承载道念（已定案）。** 胜负标尺是道念，故战斗态视图与出牌结果**都要能表达道念的当前值与本次变化量**——否则 `ux/combat-ux.md` 的「双方道念对比」主视觉无数据可读。Source: `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。
- **道念字段结构 = 当前值 + 本回合增量，且明确不分来源（承重）。** 意图已定为「合并的最终结果，不暴露张数与逐张分解」；**若 `CombatSnapshot` 按来源拆分道念，UI 就能反推出敌人的逐张分解，直接架空那条定案**。分来源的诉求由 `PlayResult` 承载。
- **「意图削减量 vs 实际削减量」由 `MomentumDelta` 的 `Declared` / `Actual` 一对承载（承重）。** 放在 `PlayResult` 而非 `CombatSnapshot` 的判据：**snapshot 是状态视图**（现在是多少），**`PlayResult` 是事件视图**（这一次发生了什么）——而截断是每次结算发生的**事件**。这条划分同时解释了为何 snapshot 只需「当前值 + 本回合增量」。呈现价值：UI 可以打出「削减 8（对方仅剩 5，溢出 3 未结转）」这类反馈，正是「敌人回合执行过程须逐步可见」所需的数据。
- **`ProvideTarget` 补上的是一个真实的 API 缺口**：结算循环已定为可挂起的状态机，但此前没有让玩家把目标交回去的方法。返回同一个 `PlayResult` 类型——它是**同一次出牌的续报**，续报里的 `MomentumDelta` 覆盖「从上次挂起点到本次挂起点 / 结算完毕」这一段；`AwaitingTarget` 可连续为 true（连锁触发中多次要目标）。**不走 EventBus 回传**——广播是既成事实、不承载请求。
- **`SideSnapshot` 单类型，不拆己方 / 对方**：拆两个类型会让「双方对称的参战方模型」在视图层裂开、ViewModel 要写两套。代价是必须写死一条填充纪律——**敌方侧的 `HandCardInstanceIds` 与 `UsableItemIds` 恒为空，不是 bug**。
- **`TargetKind` 必须有 `None`**：`PlayCard` 每次都要传一个 `TargetRef` 而大量牌无目标，`None` 使「无目标」成为**已表达的取值**而非 null 约定。**`StackEntry` 不保留**——本作不做「反制栈上条目」这一形态的效果，枚举里不留永无消费者的取值；栈条目只被 `pending` 与结算流程用 `stackEntryId` 引用，**从不作为效果的目标**。
- **`IsFinale` 收编为 `EventType`**：一旦回合数与胜负判据显式化，规则不再从它派生，它退化为呈现 / 埋点标记，用完整枚举比 bool 更贴切且让 Practice 有了位置。
- **胜负判据参数化为两个数就够，不做「可替换的判定对象」**：`(1, false)` / `(0, false)` / `(N, false)` 已覆盖全部已陈述需求，无需策略枚举与分发。
- **`BaseReward` 随物化定稿**（热更不影响进行中的遭遇），与「`EventOption` 产出即定稿」一致；代价是与「overlay 热更即生效」略有张力，**取定稿纪律**。
- **`CombatSnapshot` 按变更广播 + 缓存**，不是每次访问现组装（含两个列表，UI 每帧读会在热路径分配）；调用纪律 = **每回合 / 每次结算后组装一次**。归 `.claude/rules/csharp-godot-rules.md` 热路径不分配。
- **运行时视图字段 ≠ 存档 schema**：二者大量重合但不应混为一谈（例如 `IntentView` 明确不必存档）。存档 schema 见上方「战斗存档：`ActiveCombat`」。

Source（上述字段与判据）：`handoffs/2026-08-06d-combat-open-questions-mass-closure.md`。

### 可选奖励的候选生成（已定案）

- **固定 3 项候选，不受道念差影响**：数量恒定使 UI 布局稳定，也避免「多给一项」这种价值跳变让玩家更想 reroll（而 reroll 通道已被「奖励选择不是决策点」封死）。**道念差的价值全部落在候选质量上**（`Tier` 三档，见 `systems/balance.md`），不落在数量上。
- **池 = 事件模板携带的 `RewardPoolId`，经 `AllEnabled()` 取池**，混合 `CardData` 与 `ItemData`，去重（本次已抽中的 `Id` 不再出）。**必须走 `AllEnabled()`**，不得自写 `All().Where(x => x.ContentEnabled)`。**`RewardPoolId` 挂 `AdventureEventData` 不挂 `EnemyData`**——「打赢什么敌人」与「这场给什么奖」是两件事，同一个敌人在 Practice 与 Combat 中的奖励池应当能不同。稀有度权重按 `Tier` 调整。
- **时点 = 胜负判定之后、奖励选择步骤之前，一次性抽定**，走 `RngStream.Reward` 子流；**`picks` 与 `rng.State` 一同落存档，恢复时直接读已抽定的 `picks`，绝不用同一 `State` 重抽**——后者依赖抽取算法永不变更，是脆弱保证；直接存结果才真正兑现「退出重进得到同一组选项」。
- 三类战斗事件**共用同一条生成路径**，差异只在 `RewardPoolId` 与 `Tier`。
- **不设「放弃全部候选」通道**（放弃会重新制造一个玩家心理上的决策点，与低压定位相悖）。**合法池不足 3 条目时显式降级**：`PushWarning` + 给出实际能给的项数，**不静默给 2 项**。
- 「碾压才有高稀有度」会诱导玩家专挑弱敌刷奖励——但 `±2` 带已从规则层封住碾压深度，该激励天然受限。**这是 `±2` 带的一个正向副作用。**

Source: `handoffs/2026-08-06d-combat-open-questions-mass-closure.md`。

- **`RunCombatAsync` 收 `EncounterSpec` 而非 `CharacterProfile`**：当前角色是 life-cycle-service 状态机的持有物，本服务经 `ProfileService.Instance` 读写，不接收角色参数。
- **`CardData` ↔ `CardInstance` 是「模板 ↔ 运行时实例」的另一半**（另一半是 `AdventureEventData` ↔ `EventOption`）：签名里**传实例，不传 `Resource`**；区别在于 `CardInstance` 运行态**可变**（手牌中的临时增益），而 `EventOption` 产出即定稿不可变。见 `systems/architecture.md` 总则 6。
- **`CombatResult.Spoils` 是 `ProfileChangeSpec` 而非「已写好的变更」（已定案）。** 本服务只**描述**结果；life-cycle-service 在 `eventEnd` 阶段把它连同 `lifeSpanCost` 与隐藏属性推拉**合并为一次 `TryApply`**，从而「一个事件 = 一次事务 = 一个存档点」。战斗**过程中**的血 / mana 变更仍即时经 ProfileManager；`Spoils` 只承载收口产出。

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
- **战斗定长 = 10 个回合（双方各 5）；起始道念 = `baseMomentum`；道念可互削、下限 0** —— 已定案。Source: `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。
- **意图分档 = 越阶硬门 + 同阶差值门槛**（ch1：`≤ −2` 完整 / `−1 ~ +1` 仅类别 / `≥ +2` 无信息；ch2 · ch3：`≤ −1` / `= 0` / `≥ +1`）；**意图为回合级综合描述，只在玩家回合呈现敌人下一回合** —— 已定案。Source: `handoffs/2026-08-02c-intent-threshold-inversion-and-aggregate-intent.md` + `handoffs/2026-08-06d-combat-open-questions-mass-closure.md`。
- **`ActiveCombat` 战斗存档 schema（挂 `CharacterProfile`、可空、收口即清）；D0–D6 决策点清单（保留 D2）；挂起态恢复回到该选择点、不允许反悔；`ct` 只在决策点被观察；`attemptIndex` 整层删除** —— 已定案。Source: `handoffs/2026-08-06d-combat-open-questions-mass-closure.md`。
- **`EncounterSpec` 携带 `TurnLimit` / `VictoryRule` / `RewardPoolId` / `BaseReward` 且改为 `sealed record`；`IsFinale` 收编为 `EventType`；新增 `ProvideTarget` API；`MomentumDelta` 四字段承载声明量 vs 实际量；可选奖励固定 3 项且预先算定落存档** —— 已定案。Source: 同上。
- **奖励计算归 combat-service、发放属于战斗流程；奖励分强制 / 可选两类且预先算定（奖励选择不是决策点）；回合数与胜负判据为遭遇参数** —— 已定案。Source: `handoffs/2026-08-02-momentum-conversion-reward-structure-and-mtg-stack.md`。
- **卡牌结算 = stack（LIFO），但交互与优先权传递移除；栈深由触发式能力入栈撑起；回合结构 = 开始阶段 / 行动阶段 / 结束阶段三步（归属方各走一套，无战斗步骤、无双主阶段）；出牌时机唯一且为全局规则；手牌上限是恒定不变式、不设弃牌机制** —— 已定案。Source: `handoffs/2026-08-02b-stack-without-interaction-and-three-step-turn.md` + `handoffs/2026-08-04b-mtg-loanwords-card-types-and-intent-snapshot.md`（定名收口）。
- **借词第一批全部定名；卡牌类型六分 + 异能三分 + 永久物；意图 = 快照非承诺；战场与参战方的划线判据 = 「是否在场上生效」** —— 已定案。Source: `handoffs/2026-08-04b-mtg-loanwords-card-types-and-intent-snapshot.md`。**ADR 候选**（`CardType` 六值枚举是内容体系的根，值得固化）。
- **引入 battlefield（战场）并新增 BattlefieldManager 与 StackManager 两个 manager；满手时抽牌抽不进（纯上界、无弃牌流量）；触发式效果的载体开放（牌上触发器 / 场上持续状态 / CharacterPower，可再增）；道念下限 0 在每一次结算时截断** —— 已定案。Source: `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md`。
- **Finale 为独立事件类型（第七类）但复用战斗状态机** → `decisions/ADR-0002-adventure-event-taxonomy.md`。

## 待决问题

- **Finale 的奖励结构加厚幅度。** 「Finale 是战斗变体、天劫为带定制卡组的 Enemy」与遭遇参数（12 回合 / `WinMargin N`）均已定案；**奖励加厚的具体取值**归 ch1 数值标杆专场，少部分非战斗形态的 Finale 亦待日后定制。→ `systems/adventure-event/finale/`。
- **先后手由谁决定。** 「不设先后手抽牌差」已定案（本作不存在先手 tempo 优势）；但**谁先手**依什么决定（固定角色先手？按等级？随战斗子流掷？）未定。
- **战斗内容全部未设计。** 卡牌定义与起始卡组、敌人与意图目录、遭遇战编排——均为空白（**回合内的效果 / 状态系统骨架已定案**，见 `systems/character-profile/deck/_index.md`）。→ `systems/adventure-event/combat/`、`systems/character-profile/deck/`。
- **效果关键字体系与目标规则（需一次专门 handoff）。** 效果的原子操作清单、求值管线、目标引用形态（`TargetRef`）均已定案；**可复用的效果关键字词汇表**与**目标规则的完整判据**仍是结构占位。→ `systems/character-profile/deck/common-properties.md`。
- **`EnemyIntent` 的呈现层缓存策略。** 意图快照不必落存档（可由局面 + RNG `State` 重算）；**是否为省重算成本而缓存**是优化取舍，不是正确性要求，实测后再定。

## 对应
提炼至：`.claude/knowledge/systems/combat-service.md`（引用层，待建）。
