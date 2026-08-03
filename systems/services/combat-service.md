# combat-service（服务）

> 战斗驱动服务：回合循环、出牌结算、抽 / 弃 / 洗、敌人 AI 与意图（意图按**等级差三档揭示**）。**判据 ① —— 拥有自己的状态机与跨多帧的长流程。**
> Source: `handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md`。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **为何 Combat 需要独立服务，而其余八类不需要。** 九类 AdventureEvent 中**只有 Combat 真正拥有自己的状态机**——回合循环跨多帧推进、有独立的中间态（手牌、场上效果、敌人意图）。Practice / Research / Social / Explore / Exchange / Travel / Mystery 共享同一形状（呈现 → 选择或跳过 → 校验扣成本 → 应用产出 → 推拉隐藏属性 → 收口），差异在**数据**而非**代码**，由通用结算器 + 数据驱动的 outcome / effect 定义承担。见 `_index.md` 的拆分轴。
- **Finale 复用本服务的状态机。** 境界突破是 Combat 的一个变体（独立的结算规则与胜负条件，但同一套回合循环），不另建服务。
- **战斗模型 = mana（出牌）+ 道念（计分与胜负）（已定案）。** 本服务维护**双方各自的道念（momentum）**作为胜负标尺：**道念高者胜**；`currentMana / manaLimit` 为出牌资源，mana **无曲线**、**每回合开始自动恢复至 `manaLimit`**。**`lifeTotal / lifeTotalLimit` 在战斗过程中不被读写**——失败时才在结算时刻按「角色道念 − 敌人道念」的差值扣减 lifeTotal。炼气基线 lifeTotal 10/10、mana 5/5。见 `systems/scoring.md`、`systems/character-profile/life-total.md`、`mana.md`、`systems/adventure-event/combat/`。Source: `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。
- **战斗是定长的：固定 10 个回合（已定案 · 答结道念模型的首要缺口）。** 一场战斗**打满 10 个回合**，**双方各 5 个**（「回合」= 单方的一次行动轮，交替进行），随后比道念、高者胜。**不设提前终止**（无道念阈值胜利、不以卡组耗尽终止）。**推论：TurnManager 是一个固定长度的循环**（`for turn in 1..10`）而非动态终止判定——状态机形状因此确定，且每场战斗的时间开销可预测。Source: `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。
- **平局 = 只发基础奖励（已定案）。** 10 回合打满后道念相等时：**不判负、不扣 lifeTotal**，玩家**只获得该事件的基础奖励**（道念差为 0，故无任何厚度加成）。因此 `CombatOutcome` 需要第三个胜负态 `Draw`，且它在结算上落在「胜利侧的最薄一档」——与「道念差是双向刻度」自洽：差值为 0 就是两侧都不加码的那个原点。Source: 同上。
- **道念的运行态骨架（已定案）。** 战斗开始时本服务为双方各置一个**起始道念 = `baseMomentum`（按各自全局等级，表见 `systems/balance.md`）**；此后道念**由打出的卡牌产出**，且卡牌**可削减对方道念**，**削减在 0 处截断**（无负道念）。**推论：等级差在开局即转化为道念差**，越级挑战的压力有了确切量纲。Source: 同上。
- **奖励由本服务计算，且「获取奖励」是战斗流程的一部分（已定案 · 答结归属）。** 结算量不由 life-cycle-service 拿着 `CombatResult` 的双方道念在 `eventEnd` 再算——**combat-service 按战斗结果算完**，包括按道念差决定的奖励厚度与 lifeTotal 扣减。**推论 ①：`RunCombatAsync` 的流程尾部含奖励环节**——10 回合打完后还要走「结算 → 计算奖励 →（若有可选奖励）等玩家选择 → 收口」，随后才返回 `CombatResult`；它因此仍是形态 C，只是尾部多了一个等待玩家输入的阶段。**推论 ②：不违反「一个事件 = 一次事务 = 一个存档点」**——本服务只**计算并确定**奖励，产出的仍是一份 `ProfileChangeSpec`（`Spoils`），真正的写入照旧由 life-cycle-service 在 `eventEnd` 合并为一次 `TryApply`。**分工 = 计算归战斗、施加归生命周期。** Source: `handoffs/2026-08-02-momentum-conversion-reward-structure-and-mtg-stack.md`。
- **奖励分两类：强制自动计入 / 可选由玩家择一（已定案）。** **强制奖励**无需玩家操作、自动计数（例：经验）；**可选奖励**由玩家从若干候选中选择，形态**参照 Slay the Spire** 的战后奖励面板。**推论 ①：战斗后需要一个奖励选择步骤与对应界面**，且因奖励发放归 combat 流程，这一屏在战斗流程内、返回 `CombatResult` 之前（见 `ux/combat-ux.md`）。**推论 ②：`Spoils` 需能表达两类条目**——强制部分计算时即固定，可选部分先呈现候选、再由玩家选择收敛为最终 spec。Source: 同上。
- **奖励**预先算好**，故奖励选择**不是**决策点（已定案）。** 候选项在结算时一次算定，**退出重进得到的是同一组选项**——不存在「不满意就退出重开换一批」的窗口，因此**无需为它单独落一个决策点**。**推论：候选生成必须在战斗的确定性边界之内**（走 `Reward` 子流并随战斗 RNG `State` 一同持久化），否则「重进得到同样选项」这条保证不成立。Source: 同上。
- **失败侧仍发 `baseReward`，额外惩罚以负向条目包在 reward 内（已定案）。** 输了通常只有基础奖励；少数事件附带额外惩罚，它不另立结构，就是 `Spoils` 中的负向 `ChangeElement`——与带符号约定天然自洽。见 `systems/scoring.md` 的三档结算产物表。Source: 同上。
- **卡牌结算 = stack，但**不含交互与优先权**（已定案 · 08-02b · 承重）。** 借入 MTG 的 **stack**：打出的牌先入栈、按 **LIFO** 结算，「打出」与「结算」是两个时刻。**但交互（instant / 栈非空时出牌）与优先权传递（priority passing）整体移除**——理由是它们**把对局时长拉得太长、决策点过多、复杂度高而玩法深度收益小**。**推论 ①：「一方行动完再交给另一方」的简单交替成立**——TurnManager **不需要**「优先权在谁手上」的内循环，只需要「轮到谁」。**推论 ②：EnemyManager 的代理面回落**——AI 只在自己的回合选行动，不必在对手的窗口中决策。**推论 ③：「定长 10 回合 → 时长可预测」恢复成立**——回合数固定、每回合步骤固定，无须再为交互次数另加时长护栏。**推论 ④：决策点粒度不必覆盖响应窗口**（粒度问题本身仍在，见待决问题）。Source: `handoffs/2026-08-02b-stack-without-interaction-and-three-step-turn.md`。
- **回合结构 = 三步：起始步 / 主阶段 / 结束步（已定案 · 08-02b）。** **去掉战斗步骤，也不设双主阶段**：

  | 步骤 | 内容 |
  |------|------|
  | **起始步（start）** | 回合归属方 mana 恢复至 `manaLimit` → 触发「回合开始时」→ 抽牌 |
  | **主阶段（main）** | **唯一**的出牌阶段。**只有回合归属方能主动出牌**（sorcery speed） |
  | **结束步（end）** | 触发「回合结束时」→ 清理回合内状态 |

  **三步是回合归属方的流程，双方不同时走**：每一方在自己的回合内各走一套完整的三步，「回合开始 / 回合结束」是**有归属方的时点**，不是双方同步发生的公共时刻。**步内顺序是规则的一部分**：mana 恢复在「回合开始时」触发**之前**、抽牌在触发**之后**，故「回合开始时」类效果能影响本回合的抽牌。**推论 ①：mana 恢复的是本回合归属方的 mana**——非归属方无法出牌，其 mana 在对手回合无用途，语义实为「每次轮到我时刷满」；「响应用谁的 mana」这一问题随交互移除而消解。**推论 ②：所有牌都是 sorcery speed**——instant 不存在，出牌时机不再是卡牌的一个属性而是全局规则。**推论 ③：「回合内状态」成为一个正式的状态生命周期档位**，与跨回合持续状态相对。**推论 ④：没有独立的战斗步骤**——道念的产出 / 削减全部经由主阶段打出的卡牌，不存在第二条结算通道。Source: 同上。
- **手牌上限是一条恒定不变式，不设弃牌机制（已定案 · 08-02b）。** **手牌在任何时刻都不得超过上限**——**没有时间限制，也没有「结束步弃到上限」这类必须弃牌的机制**（结束步因此只做「触发『回合结束时』→ 清理回合内状态」）。**上限值待定。** **推论：约束点前移到会让手牌增加的时刻**（抽牌、以及任何「加入手牌」类效果）。Source: 同上。
- **满手时抽牌 = 抽不进（已定案 · 08-03 · 答结抽牌流程的前置条件）。** 满手时抽牌**抽不进——牌留在抽牌堆，这次抽牌无事发生**；「加入手牌」类效果同理落空。**「抽出即弃」与「直接销毁」两条路线均不采用。** **推论 ①：手牌上限是一条纯上界**——不产生任何弃牌堆流量、不消耗抽牌堆。**推论 ②：弃牌不是被规则强制的动作原语**（回合末不弃、满手不弃），弃牌堆只由「打出后进弃牌堆」与「卡牌效果显式弃牌」填充。**推论 ③：抽牌堆顺序不被满手情形扰动**，seeded 洗牌的确定性不因此分叉；「本回合抽 N 张」在满手时等价于抽 0 张。**推论 ④：满手的代价是 tempo 而非资源**——牌没丢，只是这一拍没拿到，手牌上限因此是节奏约束而非惩罚。呈现见 `ux/combat-ux.md`。Source: `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md`。
- **引入 battlefield（战场），栈与战场各升为一个 manager（已定案 · 08-03 · 承重）。** **battlefield = 战斗的公共区**，记录**场上的全部准确数据**——哪些卡牌正在生效、有哪些持续状态、有哪些触发器在等待。新增 **BattlefieldManager**（战场）与 **StackManager**（栈）两个 manager。**推论 ①：栈与战场是两个不同的区**——**栈 = 等待结算的队列，战场 = 已结算并正在生效的东西**；完整结算路径 = **打出 → 入栈 →（LIFO）弹出结算 → 效果施加 →（若是持续效果）落到战场**。**推论 ②：「回合内 / 跨回合状态」有了确切落点**——它们是**战场上带生命周期标记的条目**，结束步「清理回合内状态」= 清掉战场上标记为回合内的条目（取值边界仍待定）。**推论 ③：TurnManager 回落为纯粹的回合状态机**，只管「轮到谁、走到三步的哪一步」；栈的持有与结算从它身上拆走。**推论 ④：战斗内状态出现第三类持有者**——属于**某一方**的东西（mana、道念、手牌、卡组）仍归 CharacterManager / EnemyManager，**已离开手牌、正在场上生效**的东西归 BattlefieldManager；确切划线见待决问题。**推论 ⑤：决策点存档必须能恢复战场**（战场条目须可序列化）；**栈则可能不必落存档**——「栈非空时双方都不能出牌」意味着任何可退出的时刻栈应为空，待确认。**推论 ⑥：EnemyManager 规划意图时要读战场**——本回合出牌的合并结果会被场上的持续状态改写，故回合级一次性规划以战场当前状态为输入。**推论 ⑦：战场必须进入呈现层**（栈之外再加一个区，见 `ux/combat-ux.md`）。Source: 同上。
- **触发式效果的载体是开放的，不专属卡牌（已定案 · 08-03）。** 牌上的触发器、**场上的持续状态**、**CharacterPower（神通）** 都可能承载触发式效果，**清单开放**、日后可再增载体。**推论 ①：需要一个统一的触发注册 / 匹配面**——否则每类载体各写一套「谁在监听哪个时点」的匹配逻辑。**推论 ②：该注册面坐在 battlefield 上**（「场上有哪些触发器在等待、挂在谁身上」正是场上准确数据的一部分）。**推论 ③：轮回级能力必须能被战斗内读到**——参战方组装时要把角色持有的神通**注册进战场**，故本服务要读 CharacterProfile 上的这份列表。**推论 ④：压栈者与载体解耦**——触发命中后把被触发的能力压入栈的一律是 **StackManager**。仍待定：跨归属方的触发时点、以及 PlayerPower（法则）能否也承载战斗内触发，见待决问题。Source: 同上。
- **栈深由触发式能力入栈撑起（已定案 · 08-02b · 承重）。** **在栈上的牌可以触发能力，被触发的能力也进栈**，因此**即便只打出一张牌，栈深也可以大于 1**——这就是移除交互之后 stack 的承重点：**它管的是触发的解决顺序，不是双方互插牌**。**推论 ①：「栈非空时不能出牌」对双方都成立**，不为归属方开口子（「允许主阶段连续压入多张牌再统一结算」这条候选路线**不采用**）。**推论 ②：LIFO 有了实际意义**——一次结算可能连锁产生多个触发，后触发的先解决，结算顺序成为卡牌设计可利用的资源。**推论 ③：「多张削减效果同时在栈上」会真实发生**——**截断时机已于 08-03 答定：在每一次结算时截断**（见下条）。**推论 ④：栈必须进入呈现层**（见 `ux/combat-ux.md`）。Source: 同上。
- **道念的下限 0 在每一次结算时截断（已定案 · 08-03）。** 饱和减法**逐次截断**，不是全栈结算完后再截断。**推论 ①：更保护落后方，且差异可算**——对方道念 5、栈上有「削 8」与「+3」：逐次截断 → `5-8 → 0`，再 `+3 → 3`；全栈后截断 → `5-8+3 = 0`。**溢出的削减量不结转。** **推论 ②：LIFO 顺序对最终结果有实际影响**——削减与产出交错时结算顺序改变结果，「栈序是卡牌设计可利用的资源」由此从原则变成具体算术。**推论 ③：`PlayResult` 必须携带本次的实际削减量**——截断发生在每一次结算，故每次结算都是可观测事件，「意图削减量 vs 实际削减量」的差在连锁中必然出现。见 `systems/scoring.md`。Source: `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md`。
- **回合数与胜负判据是遭遇参数，不是常量（已定案）。** **标准 Combat = 10 回合、道念高者胜**；**Practice / Finale 可改写回合数与胜负条件**（Practice 更简单、Finale 更难，对位 Balatro 的 small / big / boss blind）。**推论：TurnManager 仍是定长循环，但长度来自本场遭遇的配置**，且胜负判据是一个可替换的判定而非写死的比较——承载位置未定，见待决问题。Source: 同上。
- **战斗内的一切写入经 ProfileManager。** 耗 mana、消耗道具、获得战利品、以及**结算时按道念差扣 lifeTotal** 都走 `profile-service.ProfileManager.TryApply(...)`——本服务不直接改 CharacterProfile 字段。**道念本身是战斗内的运行态**（活在 `CombatSnapshot` 里），战斗结束即消失，不落 CharacterProfile。
- **敌人意图三档揭示，分界值已给全（已定案）。** **默认揭示，越级才降级**——不是 Slay the Spire 式的常驻免费预告，也不是全盘隐藏。判据分两层：**先看是否越阶，再看同阶差值**（`diff` = 敌人全局等级 − 角色全局等级）：

  | 情形 | 玩家看到 |
  |---|---|
  | **越阶**（敌人境界高于角色） | **完全无信息** —— 不论 `diff` 多小 |
  | 同阶 · 第一篇章、`diff ≤ -3` | **完整意图**：综合类型 + 综合数值 |
  | 同阶 · 第一篇章、`-2 ≤ diff ≤ 2` | **仅类别**：攻击 / 防御 / 增益 / 特殊——有符号无数值 |
  | 同阶 · 第一篇章、`diff ≥ 3` | **完全无信息**，且**不提供任何替代线索** |
  | 同阶 · 第二 / 第三篇章、`diff ≤ -2` | **完整意图** |
  | 同阶 · 第二 / 第三篇章、`-1 ≤ diff ≤ 1` | **仅类别** |
  | 同阶 · 第二 / 第三篇章、`diff ≥ 2` | **完全无信息** |

  **「越阶 = 黑箱」是一道硬门**：它把「境界鸿沟」从数值差提升为结构性规则——炼气十三层对上筑基初期（全局仅差 1）同样是彻底黑箱。**同阶阈值整体下移，篇章分档保留**（ch2 · ch3 两端各收紧一级 → **后期境界内每一级差在信息面上更值钱**）：**完整意图只在明显压制时出现**，同级附近的一大段一律只给类别。**推论 ①：第二档是常态档**——标准 Combat 的默认呈现是「仅类别」（**同级只给类别是有意为之，不做补偿**），其视觉语言与类别枚举因此成为承重项。**推论 ②：探查（probe）的价值上升**——常态既然只有类别，主动买完整意图有了稳定需求。**推论 ③：意图揭示不再承担教学职能**，可读性须由图鉴 / 卡牌文本 / 道念主视觉承担。**不做「敌人状态可读」的补偿**。呈现侧见 `ux/combat-ux.md`。Source: `handoffs/2026-08-02c-intent-threshold-inversion-and-aggregate-intent.md`。
- **意图是回合级的综合描述（已定案 · 承重）。** **一个回合对手可以打出多张牌**，故意图**不是「下一张牌是什么」**，而是对**本回合全部出牌的汇总**：**综合数值 = 计算后合并的最终结果**（一个结果值，例：削减 12；不是 4+5+3 的明细，也不是未合并的多条），**综合类别 = 主类别并行陈列**（一回合跨类别时并列各主类别，不压缩成单一类别、不归入「特殊」）。**推论 ①：不暴露张数与逐张分解**——即便第一档，玩家拿到的也是最终结果而非牌序。**推论 ②：EnemyManager 的 AI 是回合级一次性规划**——必须在呈现意图之时就已定好本回合整套出牌**并算出合并结果**，这排除了逐张即时决策的 AI 形态。**推论 ③：意图数值 ≠ 实际结算量**——道念削减是下限 0 的饱和减法且触发也入栈，故综合数值是**声明的量**，与「`PlayResult` 需区分意图削减量 vs 实际削减量」合流。Source: 同上。
- **意图只在玩家回合呈现，内容是敌人的下一个回合（已定案）。** 敌人回合内**不呈现意图**（那时它正在执行出牌）。**推论 ①：意图的用途是为玩家本回合的出牌决策提供依据**——这也解释了为何合并成一条结果值就够用（玩家要的是「该防多少 / 追多少」，不是牌序）。**推论 ②：敌人 AI 的规划时点前移到玩家回合开始之前**（结合回合级一次性规划：玩家回合开始时，敌人下一回合的整套出牌已定案）。**推论 ③：意图是玩家回合内的常驻信息**，随回合归属切换出现 / 消失。Source: 同上。
- **意图即承诺：公布后不因玩家行动重算（已定案）。** 敌人的下一回合计划在玩家回合开始时定案，**玩家在主阶段做什么都不会改写它**，也不刷新显示——意图是一个可依赖的承诺，玩家因此能据它布局（「它要打 12，我这回合防住 12」）。**推论 ①：EnemyManager 的代理面进一步收窄**——AI 决策发生在一个明确时点（玩家回合开始之前），不必挂钩玩家的出牌事件做重算，也不需要「响应式 AI」这条路径。**推论 ②：AI 的规划质量取决于它对玩家回合的预判**，而非临场调整；难度调节的旋钮因此落在规划算法与卡组，不在反应速度。**推论 ③：承诺与执行可能不一致**——玩家行动可能让计划中的某张牌在敌人回合无法照原样执行（资源变化、目标状态改变），此时如何处理未定，见待决问题。Source: 同上。
- **探查（probe）是意图之外的第二条信息通道。** 意图揭示档位由等级差**被动**决定；**探查**则是玩家**主动付出代价换取当回合敌人意图**的效果。方向已定、定名已成，**具体形态（花费形式 / 授予途径 / 可探查档位）归卡牌与技能内容的横向扩展阶段，本阶段搁置**。「某些能力或道具授予窥视意图」即探查能力的授予形式。Source: 同上。
- **意图不单列 manager。** 意图生成隶属 **EnemyManager**，与敌人实例状态、AI 行为选择同属一个组件——三者共享同一份敌人运行态，拆开只会让它们互相伸手。**EnemyManager 内部不再细分职能（已定案）。** Source: `handoffs/2026-07-30-claude-engineering-scope-enemy-manager-and-requirement-breakdown.md` + `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md`。
- **CharacterManager 与 EnemyManager 平级、共享接口、驱动方式相反（已定案）。** 两者管理战斗的两侧参战方，**共有大量接口定义**（生命 / mana、卡组、状态、出牌）；差异只在**谁驱动决策**——EnemyManager 含**代理操作**（AI 行为选择、意图生成），CharacterManager **监听玩家操作**。Source: `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md`。
- **每个参战方各有一个 `DeckModule`（已定案）。** 卡组不是全局单件：**每个 character、每个 enemy 各持有一个**，由 CharacterManager / EnemyManager 各自持有。**敌人也出牌**，且可带定制卡组（例如 Finale 的天劫，以及 `EnemyTemplate` 的样本卡组经物化改写而来）。`DeckModule` 是**第三级抽象（module）**，不列入本服务的 manager 清单——层级词表见 `systems/architecture.md`。Source: 同上 + `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。
- **Practice / Finale 复用本服务的参战方结构。** 两者都用 EnemyManager + CharacterManager，是 Combat 的**变体**（同一套回合循环与参战方模型，独立的胜负条件与奖励结构）。见 `systems/adventure-event/practice/`、`finale/`。Source: 同上。
- **事件过程按决策点落存档（已定案）。** 战斗**不是**存档盲区：事件过程中（含战斗内）在**决策点**落存档，使「退出重进」得到的是同一个局面与同一份 RNG 状态。**`selectCost` 不回滚**——选中事件时施加的成本（含 `lifeSpanCost`）一经施加即成事实。**决策点的具体粒度未定**，见待决问题。Source: 同上。
- **确定性。** 洗牌、敌人行为掷骰等一律用 `life-cycle-service.SeedManager` 派生的 **combat 子流**，与地图 / 商店 / 奖励子流隔离，避免 desync。同一 seed 必须复现同一场战斗。

## 管理器

| manager | 职责 |
|---------|------|
| **TurnManager** | **定长回合**的状态机（标准 Combat = 10 回合、双方各 5，交替；Practice / Finale 可改写长度）。每个回合走**三步**：**起始步**（归属方 mana 恢复至 `manaLimit` → 触发「回合开始时」→ 抽牌）→ **主阶段**（唯一出牌阶段，只有归属方出牌；**无优先权内循环**）→ **结束步**（触发「回合结束时」→ 清理回合内状态）→ 交给另一方。**三步是归属方的流程，双方不同时走。** 打满后做胜负判定（Combat 档 = **道念高者胜**，相等 = `Draw`，只发 `baseReward`），随后走**奖励计算与可选奖励选择**再收口。**它只管「轮到谁、走到哪一步」——栈的持有与结算归 StackManager** |
| **CharacterManager** | 玩家侧参战方：角色的对战状态、其卡组、出牌通道；**监听玩家操作** |
| **EnemyManager** | 敌人侧参战方：敌人实例与状态、其卡组、**AI 行为选择与意图（intent）生成**；**代理操作**。内部不再细分职能。规划本回合整套出牌时**读战场当前状态** |
| **BattlefieldManager** | **战场（battlefield）**：场上正在生效的卡牌、持续状态、**触发器注册面**（谁在监听哪个时点），及各条目的生命周期标记（回合内 / 跨回合）与清理。**已离开手牌、正在场上生效的东西归它**；属于某一方的 mana / 道念 / 手牌 / 卡组仍归两个参战方 manager |
| **StackManager** | **栈（stack）**：压栈、**LIFO 结算**、连锁触发的解决顺序。**被触发的能力由它压栈**（与触发挂在哪个载体上无关）；结算产生的持续效果落到 BattlefieldManager |

**`DeckModule`（第三级）不是平级 manager。** 抽牌堆 / 手牌 / 弃牌堆的流转与 seeded 洗牌由 CharacterManager 与 EnemyManager 各自持有的 `DeckModule` 承担，**每个 character / enemy 一份**。它与那套共享的参战方接口是同一件事的两面。

**栈与战场是两个区，不是一个。** 栈 = **等待结算**的队列；战场 = **已结算并正在生效**的东西。结算的完整路径：**打出 → 入栈 →（LIFO）弹出结算 → 效果施加 →（若是持续效果）落到战场**。Source: `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md`。

## API 面（契约）

> 总则与共享类型见 `systems/architecture.md`「API 契约总则」。本服务**纯本地**，永不跨进程边界；`RunCombatAsync` 是形态 C（跨多帧、由信号推进），其余为形态 A。Source: `handoffs/2026-07-27b-service-api-contracts.md`。

| 方法 | 形态 | 完整签名 | 失败语义 |
|------|------|----------|----------|
| 打一场 | **C** | `Task<CombatResult> RunCombatAsync(EncounterSpec encounter, CancellationToken ct)` | 未知 `EncounterId` = 坏数据 → `PushError` + 抛；胜负是**结果**不是失败 |
| 出牌 | A | `PlayResult PlayCard(CardInstance card, TargetRef target)` | 业务失败（mana 不足、目标非法）→ `PlayResult`，绝不抛 |
| 结束回合 | A | `void EndTurn()` | — |
| 战斗态 | A | `CombatSnapshot Snapshot { get; }` | 只读视图，供 ViewModel 组装；**必含双方道念** |

```csharp
public readonly record struct EncounterSpec(string EncounterId, bool IsFinale);
public readonly record struct CombatResult(
    CombatOutcome     Outcome,            // Victory | Draw | Defeat | Fled（Draw = 道念相等，只发基础奖励）
    int               CharacterMomentum,  // 结算时角色道念（10 回合打满后）
    int               EnemyMomentum,      // 结算时敌方道念；二者之差：胜 → 奖励厚度，负 → lifeTotal 扣减
    int               RemainingLifeTotal, // 结算扣完之后剩余的 lifeTotal（非「战斗中掉剩的血」）
    ProfileChangeSpec Spoils);            // 本服务算好的最终奖励（含可选奖励的玩家选择结果、失败侧的负向条目）
                                          // 以 spec 形式回吐，由 life-cycle 经 ProfileManager 施加
// 道念为 >= 0 的 Integer；负侧扣减 = 道念差 1:1
// ⟨待定：EncounterSpec 的回合数 / 胜负判据字段、CombatSnapshot / TargetRef / PlayResult 的完整字段⟩
```

- **`CombatSnapshot` / `PlayResult` 必须承载道念（已定案）。** 胜负标尺是道念，故战斗态视图与出牌结果**都要能表达道念的当前值与本次变化量**——否则 `ux/combat-ux.md` 的「双方道念对比」主视觉无数据可读。具体字段依赖战斗内容设计。Source: `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。

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
   │           ├─▶ content-service.ContentRegistry  按 Id 取 CardData / EnemyData
   │           ├─▶ profile-service.ProfileManager   战斗过程中的即时写入
   │           └─▶ CombatResult（Outcome + 双方道念 + RemainingLifeTotal + Spoils:ProfileChangeSpec）
   └─ 【eventEnd 阶段】Spoils + lifeSpanCost + 隐藏属性推拉 → **一次** TryApply → 一个存档点
```

## 决策(-> ADR)

- **战斗模型 = mana + 道念；胜负 = 道念高者胜；失败按道念差扣 lifeTotal** → 见 `systems/scoring.md`、`systems/adventure-event/combat/`、`systems/character-profile/life-total.md`、`mana.md`。**ADR 候选。**
- **战斗定长 = 10 个回合（双方各 5）；起始道念 = `baseMomentum`；道念可互削、下限 0** —— 已定案。Source: `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。
- **意图分档 = 越阶硬门 + 同阶差值门槛**（ch1：`≤ -3` 完整 / `-2 ~ 2` 仅类别 / `≥ 3` 无信息；ch2 · ch3：`≤ -2` / `-1 ~ 1` / `≥ 2`）；**意图为回合级综合描述，只在玩家回合呈现敌人下一回合** —— 已定案。Source: `handoffs/2026-08-02c-intent-threshold-inversion-and-aggregate-intent.md`。
- **奖励计算归 combat-service、发放属于战斗流程；奖励分强制 / 可选两类且预先算定（奖励选择不是决策点）；回合数与胜负判据为遭遇参数** —— 已定案。Source: `handoffs/2026-08-02-momentum-conversion-reward-structure-and-mtg-stack.md`。
- **卡牌结算 = stack（LIFO），但交互与优先权传递移除；栈深由触发式能力入栈撑起；回合结构 = 起始步 / 主阶段 / 结束步三步（归属方各走一套，无战斗步骤、无双主阶段）；所有牌为 sorcery speed；手牌上限是恒定不变式、不设弃牌机制** —— 已定案。Source: `handoffs/2026-08-02b-stack-without-interaction-and-three-step-turn.md`。
- **引入 battlefield（战场）并新增 BattlefieldManager 与 StackManager 两个 manager；满手时抽牌抽不进（纯上界、无弃牌流量）；触发式效果的载体开放（牌上触发器 / 场上持续状态 / CharacterPower，可再增）；道念下限 0 在每一次结算时截断** —— 已定案。Source: `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md`。
- **Finale 为独立事件类型（第七类）但复用战斗状态机** → `decisions/ADR-0002-adventure-event-taxonomy.md`。

## 待决问题

- **意图类别的枚举（08-02c 加压 · 第二档已成常态档）。** 展示粒度是「攻击 / 防御 / 增益 / 特殊」，其正式枚举与敌人行为的映射未定；**跨类别呈现规则已答定**（主类别并行陈列），剩下的是四类各自的边界与映射。→ `systems/adventure-event/combat/`。Source: `handoffs/2026-08-02c-intent-threshold-inversion-and-aggregate-intent.md`。
- **承诺与执行不一致时如何处理（08-02c 追加 · 由「意图即承诺」推出）。** 意图公布后不重算，但玩家的行动可能让计划中的某张牌在敌人回合无法照原样执行（mana / 资源变化、目标状态改变、牌被移出手牌）：是**跳过该张照打其余**、**降级执行**（打出但效果打折）、还是**允许临场替换**（等于开了重算的口子）？未定。→ `systems/character-profile/deck/`、`ux/combat-ux.md`。Source: 同上。
- **决策点的粒度。** 「事件过程按决策点落存档」已定，但战斗内的决策点具体指哪些位置（每回合开始？每次出牌后？每次目标选择后？）未定；粒度直接决定本地写入频率与 push 防抖压力。→ `sync-service.md`。Source: 同上。
- **`attemptIndex` 是否还需要。** 既定的战斗内 RNG 派生式 `Hash64(combatStreamSeed, eventId, attemptIndex)` 是为防「退出重进重掷」；**决策点存档 + RNG `State` 持久化已从根上关闭该窗口**。剩下的问题收窄为：篇章重试（ADR-0004）重开同一篇章时，同名事件是否应换一套战斗随机——若应则 `attemptIndex` 取「篇章重试的第几次」，若不应则该派生层可整个去掉。→ `systems/common-properties.md`、`life-cycle-service.md`。Source: 同上。
- **Finale 的独立胜负条件与奖励结构。** 「Finale 是战斗变体、天劫为带定制卡组的 Enemy」已定；区别于 Combat 的胜负判定与奖励结构未定，少部分非战斗形态的 Finale 亦待日后定制。→ `systems/adventure-event/finale/`。
- **`CombatSnapshot` / `PlayResult` 的道念字段形态。** 产出途径已定（卡牌，可互削，下限 0），但这两个类型该带什么（当前值 + 本次增量？分来源？对方的削减量？）仍依赖卡牌内容设计。→ `systems/character-profile/deck/`。Source: 同上。
- **可选奖励的候选如何生成。** 候选项数量、抽自哪个池、是否受道念差影响（赢得越多候选越好，还是道念差只影响强制部分的厚度）均未定。**约束已给**：候选必须**预先算定**（走 `Reward` 子流并随战斗 RNG `State` 持久化），使退出重进得到同一组选项。→ `systems/balance.md`。Source: `handoffs/2026-08-02-momentum-conversion-reward-structure-and-mtg-stack.md`。
- **BattlefieldManager 与两个参战方 manager 的边界划线（08-03 新增 · 承重）。** 「属于某一方的归参战方、场上生效的归战场」是推演出的划法，未经陈述：**附着在某一方身上的持续状态**（例：「我方本回合所有牌 +1 道念」）算战场条目还是参战方状态？双方各自的场区是否分开记录？Source: `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md`。
- **战场与栈的存档形态（08-03 新增）。** 决策点存档要求局面可恢复 ⇒ **战场条目须可序列化**；**栈是否需要落存档**取决于「决策点是否总落在栈为空的时刻」（栈非空时双方都不能出牌，故很可能是），未确认。→ `sync-service.md`。Source: 同上。
- **触发条件能否跨归属方（08-02b 新增 · 08-03 收窄）。** **载体形态已答定**（牌上触发器 / 场上持续状态 / CharacterPower，清单开放）；仍待定：触发条件能否写「对手的回合开始时」这类跨归属方的时点（时点本身有归属方，但监听方未必是归属方）。→ `systems/character-profile/deck/`。Source: 同上。
- **PlayerPower（法则）能否承载战斗内触发（08-03 新增）。** CharacterPower（神通）已确认可承载；账号级的法则未陈述。若可，则本服务还要读 PlayerProfile 一侧的持有列表。→ `systems/player-profile/player-power/`。Source: 同上。
- **回合数与胜负判据落在哪个类型上。** 二者可被变体改写，故 `EncounterSpec` 需携带它们（回合数 + 胜负判据标识），或由 `EnemyTemplate` / 事件模板带入——当前 `EncounterSpec` 只有 `(EncounterId, IsFinale)`。Source: 同上。
- **手牌上限的取值（08-02b 新增）。** 上限的存在与语义已定（恒定不变式、无弃牌机制）；**数值未给**，敌人侧是否同值亦未给。→ `systems/character-profile/deck/`。Source: 同上。
- **每回合抽牌数与首回合 / 起始手牌（08-02b 新增）。** 抽牌**时机**已定（起始步、「回合开始时」触发之后）；**数量**、先后手是否有抽牌差未给。→ 同上。
- **「回合内状态」的判定边界（08-02b 新增 · 08-03 有了落点）。** **承载结构已定**：状态是**战场上带生命周期标记的条目**，结束步清理标记为回合内的那些；仍待定的是**取值**——哪些东西该标为回合内（本回合获得的临时增益？本回合出的牌留下的持续效果？），以及「持续到下回合结束」这类跨回合时长如何表达。→ `systems/adventure-event/combat/`。Source: 同上 + `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md`。
- **`EncounterSpec` 如何承载物化后的敌人。** 敌人等级 / 卡组由 future-event-service 在物化时确定，故 `EncounterSpec` 需要携带**物化后的敌人实例**（或其引用），而非只带一个 `EncounterId` 让本服务回查模板——具体形态未定。→ `future-event-service.md`。Source: 同上。
- **战斗内容全部未设计。** 卡牌定义与起始卡组、敌人与意图目录、遭遇战（encounter）编排、回合内的效果 / 状态系统 —— 均为空白。→ `systems/adventure-event/combat/`、`systems/character-profile/deck/`。
- **`manaLimit` 的推拉分档。** 「每回合恢复至上限、`manaLimit` 由事件 cost / reward 推拉」已定；哪些事件推高 / 压低、幅度分档未定。→ `systems/balance.md`、`systems/character-profile/mana.md`。
- **enemies 归属。** 当前归 `adventure-event/combat/`；Practice 与 Finale 均已确认使用敌人（天劫即 Enemy），是否升为共享内容层待确认。

## 对应
提炼至：`.claude/knowledge/systems/combat-service.md`（引用层，待建）。
