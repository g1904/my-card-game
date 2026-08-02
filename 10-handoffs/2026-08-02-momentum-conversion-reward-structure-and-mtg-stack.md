# 道念换算 · 奖励结构 · 战斗变体 · MTG stack

- id: 2026-08-02-momentum-conversion-reward-structure-and-mtg-stack
- date: 2026-08-02
- topic: 20-systems/scoring · services/（combat / life-cycle / future-event）· balance · game-progression · character-profile/（life-total / deck）· adventure-event/（combat / practice / finale）· 40-ux/combat-ux · 00-vision/（references / scope）· terminology
- status: distilled
- distilled-to: terminology.md, 20-systems/scoring.md, 20-systems/balance.md, 20-systems/game-progression.md, 20-systems/services/（combat-service, life-cycle-service, future-event-service）, 20-systems/character-profile/（life-total.md, deck/_index.md）, 20-systems/adventure-event/（combat/_index.md, practice/_index.md, finale/_index.md）, 40-ux/combat-ux.md, 00-vision/（references.md, scope.md）, open-questions.md, answer-logs/log-0802.md

## Intent（distilled）

**一句话：** 把道念（momentum）从「规则骨架」推到「可结算」——**道念差 1:1 换算为 lifeTotal 损失（不设截断，越界风险由内容侧的赋级上界规避）**、**奖励由 combat-service 在战斗流程内预先算定并分强制 / 可选两类（选择不是决策点）**、**Practice / Combat / Finale 是 Balatro 三档 blind 的对位（回合数与胜负条件皆可被变体改写）**；并落下两项结构性改写：**卡牌结算借入 MTG 的 stack 且连响应窗口一并借入 —— 回合变成交互式的**，以及**等级成长改由新字段 `experiencePoint` 承载**（事件发经验、达阈值才升级，推翻「事件直接给等级」）。此外：今后大量借用 MTG 术语来简化 card / deck / combat 体系；数值标杆（卡牌产 / 削道念的量纲、lifeTotal 回复幅度）**明确推迟到内容横向扩展阶段的一场专门「ch1 数值模型」session**，并**优先打磨 ch1 内容**。

### ① 道念差 → lifeTotal 损失 = 1:1

- **换算公式定案（负侧）：道念差**就是** lifeTotal 的损失量。** 战斗判负时 `lifeTotal -= (敌人道念 − 角色道念)`——不是线性系数、不是分档表，而是**同一个数直接搬过去**。
- **推论 ①：道念差成为一个真正的通用刻度。** 它既是胜负判据的差值，又直接是惩罚的量值，中间不隔一层映射——玩家在战斗屏上看到的「我落后 8 点」就是「输了要掉 8 点 lifeTotal」，账当场可算，不需要额外的教学。
- **不设上限截断（同轮追加拍板）。** 1:1 就是全部规则——不封顶、不分档。**「一次惨败打穿耐久」由内容设计侧规避**：遭遇编排不会给出会导致该结果的等级差，故规则层无需加护栏，`lifeTotalLimit` 也不必被迫涨到与 `baseMomentum` 同量级。
- **推论：约束从规则层转移到内容层。** future-event-service 的敌人赋级规则由此背上一条硬约束——**最坏情况下的道念差必须落在当前 `lifeTotal` 可承受的范围内**。它是一条上界，取值待定，与 `lifeTotalLimit` 的境界基线互为约束。
- **胜利侧的换算尚未给定同样的形式。** 用户只明确了负侧 1:1；胜侧「道念差 → 奖励厚度」仍是既定的定性表述（碾压 > 险胜），是否也 1:1（差值直接作为某种奖励量的乘数 / 加数）未陈述，见 Open questions。

### ② 失败侧的奖励结构：通常只有 baseReward

- **输了通常只发 `baseReward`（基础奖励）。** 失败不是零产出——这与 08-01 定下的「失败侧首次有产出」（EnemyCodex 遭遇即记、道统残卷累积、等级产出也可能来自失败）一脉相承。
- **少部分情况有额外惩罚，且惩罚**包在 reward 里面**。** 不新增「惩罚结构」——额外惩罚就是奖励结构中的**负向条目**。
- **推论：这与 `ProfileChangeSpec` 的带符号约定天然自洽。** `ChangeElement.BaseValue` 本就带符号（负 = 消耗，正 = 产出），故「奖励里夹一条惩罚」不需要任何新类型，仍是同一个 `CombatResult.Spoils` spec、同一次 `TryApply`。
- **推论：三档结算量已经齐全** —— 胜（baseReward + 按道念差加厚）／平（只发 baseReward）／负（baseReward，少数带负向条目，另按道念差扣 lifeTotal）。

### ③ 奖励由 combat-service 计算，且发放属于战斗流程的一部分

- **归属定案：combat-service 按战斗结果计算奖励。** 这答结了「道念差的结算量由谁算」——不是 life-cycle-service 拿着 `CombatResult` 的双方道念在 `eventEnd` 再算，而是**战斗服务自己算完**。
- **「获取奖励」是 combat 流程的一部分**，不是战斗之后另起的一步。
- **推论 ①：`RunCombatAsync` 的流程尾部包含奖励环节。** 战斗状态机在 10 回合打完之后还要走「结算 → 计算奖励 → （若有可选奖励）等玩家选择 → 收口」，随后才返回 `CombatResult`。它因此仍是形态 C（跨多帧、由信号推进）——尾部多了一个等待玩家输入的阶段。
- **推论 ②：不违反「一个事件 = 一次事务 = 一个存档点」。** combat-service 只**计算并确定**奖励内容，产出的仍是一份 `ProfileChangeSpec`（`CombatResult.Spoils`）；真正的写入照旧由 life-cycle-service 在 `eventEnd` 与 `lifeSpanCost`、隐藏属性推拉合并为**一次** `TryApply`。「计算归战斗、施加归生命周期」的分工不变。

### ④ 奖励分两类：强制自动计入 / 可选由玩家择一

- **强制奖励：自动计数，无需玩家操作**——例：**`experiencePoint`（经验值）**，见 ⑪。
- **可选奖励：由玩家从若干项中选择**——形态**参照 Slay the Spire** 的战后奖励面板。
- **推论 ①：战斗后需要一个奖励选择步骤与对应界面。** 这是战斗 UX 至今未有的一屏；且因奖励发放归 combat 流程，这一屏在战斗流程内、返回 `CombatResult` 之前。
- **奖励**预先算好**，故奖励选择**不是**决策点（同轮追加拍板）。** 候选项在结算时一次算定，**退出重进得到的是同一组选项**——不存在「不满意就退出重开换一批」的窗口，因此无需为它单独落一个决策点。**推论：候选生成必须落在战斗的确定性边界内**（走 `Reward` 子流、随战斗 RNG `State` 一同持久化），否则「重进得到同样选项」这条保证不成立。
- **推论 ②：`Spoils` 需能表达两类条目。** 强制部分在计算时即固定，可选部分要先呈现候选、再由玩家的选择收敛为最终 spec。

### ⑤ Practice / Combat / Finale = Balatro 的三档 blind

- **对位关系（用户原话）：** `practice = small blind`；`combat = big blind`；`finale = boss blind`。
- **标准 Combat = 10 个回合，以道念差判胜负**（既定规则在此被确认为**标准档**，而非全局常量）。
- **Practice：胜负条件与回合数**可能变化**，整体比 Combat **更简单**。** 这给了「低风险历练」一个具体的实现面：不必靠「失败不扣惩罚」这类特例，直接把难度旋钮拧松即可。
- **Finale：胜负条件与回合数**可能变化**，整体比 Combat **更难**。**
- **推论 ①：回合数不是常量，是遭遇参数。** TurnManager 仍是定长循环，但长度来自这一场遭遇的配置（`EncounterSpec` 一侧），而不是硬编码的 10。10 是 Combat 这一档的默认值。
- **推论 ②：胜负条件是可替换的判据，而非写死的「道念高者胜」。** Finale 可以要求「必须领先 N 点」或别的门槛；Combat 档的判据就是「道念高者胜、相等为平局」。
- **推论 ③：三档难度阶梯由此获得统一语言。** 借的是 Balatro 的**难度分档结构**（小盲 → 大盲 → Boss 盲的递进），不是它的计分结构（chips × mult 仍被否决）。

### ⑥ 数值标杆整体推迟到「ch1 数值模型」专场

- **卡牌产 / 削道念的量纲基准**：在**内容横向扩展**阶段具体定义；切入点是**设计起始角色（starter deck）的过程**，届时聚焦并定义**第一篇章（ch1）的数值标杆**。
- **`lifeTotal` 的恢复幅度**：同样在内容横向扩展阶段定义。
- **内容横向扩展需要一场专门的「ch1 数值模型」session。**
- **优先打磨 ch1 的内容。**
- **推论：这把两条先前列为「承重待答」的条目降级为有明确归宿的搁置项。** 它们不再是当前焦点区的阻塞项，而是排进了一场已被点名的专场；与既定的「机制先行、内容随后」路线一致。

### ⑦ 越级追分：可能，但很难，尤其跨大境界

- **确认越级追分是可能的**——不是结构性禁止，而是难度问题。
- **境界差越大越难，因此 `baseMomentum` 的差距（跨度）随之变大。** 这确认了 `baseMomentum` 表「每级跨度持续放大、境界之间跨度更大」的形状**正是为此而设**——起跑线差就是越级难度的调节旋钮。
- **推论：越级挑战是一条连续的风险曲线，不是开关。** 与「敌人等级在 eventOptions 上精确标注」合起来，玩家看到的是一个可估的赔率，而不是一道禁止线。

### ⑧ 道念的字段形态

- **`momentum` = 非负整数（`>= 0` 的 Integer）。** 下限 0 在类型层面即已表达；不引入小数、不引入负值。
- **推论：削减是饱和减法。** 削到 0 即止，多余的削减量不结转、不产生负数——`CombatSnapshot` / `PlayResult` 上「本次削减量」若要如实呈现，需要区分「意图削减量」与「实际削减量」。

### ⑨ 卡牌结算参考 MTG 的 stack（堆栈）

> **本节的「响应窗口一并借入」已被同日 `2026-08-02b-stack-without-interaction-and-three-step-turn.md` 收窄：stack 保留，交互与优先权传递移除。** 以那份 handoff 与各主题文档为准。

- **卡牌结算方式参考 Magic: the Gathering 的 stack 概念。** 打出的卡牌不立即生效，而是先入栈，按**后进先出**的顺序依次结算。
- **响应窗口一并借入，回合是交互式的（同轮追加拍板 · 承重）。** 不是只借结算顺序——**对方可在你的牌结算之前插入自己的牌**。
- **推论 ①：结算顺序成为一条明确的规则，而不是实现细节。** 「打出」与「结算」是两个时刻，中间的窗口正是 MTG stack 的价值所在，也是回合内效果 / 状态系统（至今空白）的一个天然骨架。
- **推论 ②：「一方行动完再交给另一方」的简单交替被推翻。** 回合数仍固定，但每个回合内双方来回交互——TurnManager 因此多一层「优先权（priority）在谁手上」的内循环，而不只是「轮到谁」。
- **推论 ③：战斗张力的来源扩展了。** 从「10 个回合内攒够道念」扩展到「什么时候出手、留不留牌应对」——这是 mana 每回合刷满之后，回合间张力的第二个来源。
- **推论 ④：卡牌设计多出一个维度。** 一张牌除了产 / 削多少道念，还要定它**能否在响应窗口中打出**——这是 MTG 术语体系（瞬间 / instant 一类关键字）最直接的落点。
- **推论 ⑤：EnemyManager 的代理操作面变大。** AI 不仅要在自己的回合选行动，还要在玩家的响应窗口中决定是否响应、响应什么。
- **推论 ⑥：「定长 10 回合 → 时长可预测」被削弱。** 回合数固定，但每回合的交互次数不固定，篇章时长控制需重新审视；决策点粒度也必须覆盖响应窗口。

### ⑩ 术语方向：向 MTG 借词

- **今后将大量使用 MTG 术语来简化 card / deck / combat 体系的表达。**
- **推论：`terminology.md` 需要一条借词约定。** 借来的词（stack、resolve、trigger、instant、permanent…）应在术语表登记为**已定含义**，避免同一个词在设计文档与 MTG 原义之间漂移；仙侠语境下的中文定名与之配对。
- **这与既有的「规避 MTG」条目不冲突：** 规避的是它的**胜负模型**（血量归零）与 **mana 曲线**；借的是它的**结算模型与术语体系**。

### ⑪ 经验值 `experiencePoint` 是一个新字段（推翻「事件直接给等级」）

- **`experiencePoint`（经验值）是 CharacterProfile 上的新字段。** **每个等级各有一个升级所需的经验阈值**；**事件奖励发放的是经验值，而不是等级本身**，累积达到阈值才升一级。**阈值曲线待定。**
- **这推翻了 08-01 定下的「等级成长 = 事件 reward 直接给等级」**——模型多了一层累积量。
- **推论 ①：等级产出可以做得细碎而连续。** 一次事件给几点经验，不必每次都是一次跳级——产出的分布因此好调得多。
- **推论 ②：「失败给的比胜利少」有了自然的表达。** 同一个量的不同数值，取代「给不给等级」这种全有全无的判断。
- **推论 ③：它落在 `CharacterProfile.Status` 上**，与 `lifeTotal` / `mana` / 隐藏属性并列；升级判定是 ProfileManager 施加经验之后的一次派生检查。
- **推论 ④：它就是战斗奖励中「强制自动计入」的那一类**（见 ④），两条约定在此接上。

## Open questions

> 本 handoff 首轮提出的四项待确认（`lifeTotalLimit` 量纲对齐、「经验」是否新字段、奖励选择是否决策点、stack 借入深度）**已在同一轮全部拍板**，已折进正文，不再列于此。以下是仍未决的。

- **敌人赋级的等级差上界取什么值？（承重 · 由「不设截断、内容侧规避」逼出）** 1:1 不封顶，「一次惨败打穿耐久」交由内容设计侧规避，故 future-event-service 的赋级规则须持有一条上界——**最坏情况下的道念差不超过当前 `lifeTotal` 可承受范围**。上界值未定，且与 `lifeTotalLimit` 的境界基线互为约束。→ `20-systems/services/future-event-service.md`、`20-systems/balance.md`、`20-systems/character-profile/life-total.md`。
- **`experiencePoint` 的升级阈值曲线。** 炼气 13 级 / 筑基 · 金丹各 4 级各需多少经验、是线性还是递增、每境界是否重置量纲；它与单次事件的经验给予量互为倒数，须一同确定。→ `20-systems/balance.md`、`20-systems/game-progression.md`。
- **响应窗口的规则细则（承重）。** 优先权如何轮转与让渡（双方连续 pass 才结算栈顶？）、**哪些牌可在响应窗口打出**（是否需要「瞬间」类关键字，还是所有牌都可响应）、**响应是否消耗 mana**（mana 每回合刷满，在对方回合响应用的是谁的 mana？）、栈深是否设上限、敌人 AI 如何在窗口中决策。→ `20-systems/character-profile/deck/`、`20-systems/services/combat-service.md`。
- **交互式回合的移动端形态与时长约束。** 「轮到你响应」如何提示与如何 pass（自动 pass？超时？）——设计得重则每回合的来回会把节奏拖垮；且回合数固定但交互次数不固定，是否需要额外的时长约束（响应次数上限 / 计时）未定。→ `40-ux/combat-ux.md`、`20-systems/balance.md`。
- **决策点粒度须覆盖响应窗口。** 一个回合内有多个可退出的时刻，决策点落在哪些位置（每次入栈后？每次优先权移交时？只在栈清空后？）直接决定本地写入频率与 push 防抖压力。→ `20-systems/services/life-cycle-service.md`、`combat-service.md`、`sync-service.md`。
- **胜利侧的「道念差 → 奖励厚度」是否也 1:1？** 负侧已定为 1:1；胜侧仍只有定性表述。若也 1:1，那「1 点道念差」在奖励侧等于什么单位（灵玉？候选项数量？某个权重）未定。→ `20-systems/balance.md`。
- **可选奖励的候选如何生成？** 候选项数量、从哪个池抽、是否受道念差影响（赢得越多候选越好？还是只影响强制部分的厚度）均未定。**约束已给：** 候选须**预先算定**（走 `Reward` 子流、随战斗 RNG `State` 持久化），使退出重进得到同一组选项。→ `20-systems/balance.md`、`20-systems/services/combat-service.md`。
- **Practice / Finale 的回合数与胜负条件具体改写成什么？** 「可能变化、一简一难」已定方向，但**具体数值与判据**未给：Practice 是更少回合（更快）还是更多回合（更宽容）？Finale 的额外门槛是什么形式？→ `20-systems/adventure-event/practice/`、`finale/`。
- **回合数与胜负判据落在哪个类型上？** 若二者可被变体改写，`EncounterSpec` 就需要携带它们（回合数 + 胜负判据标识），或由 `EnemyTemplate` / 事件模板带入。当前 `EncounterSpec` 只有 `(EncounterId, IsFinale)`。→ `20-systems/services/combat-service.md`。
- **stack 与「道念下限 0」的交互。** 若多张削减牌同时在栈上，饱和减法在**每次结算**时截断还是在**全栈结算完**后截断？两者结果不同（前者更保护落后方）。→ `20-systems/scoring.md`。
- **借入的 MTG 术语清单与中文定名。** 哪些词借、哪些词不借（避免与既有仙侠定名冲突，如 mana 已定名「法力」、momentum 已定名「道念」）？借词是否需要一条统一的登记纪律？→ `terminology.md`。
- **「小盲 / 大盲 / Boss 盲」的对位是否也意味着**出现频率与顺序**的对位？** Balatro 里三档 blind 是固定循环出现的；本作的事件是逐批择一、无固定序列。这条对位只讲难度，还是也暗示 Practice / Combat / Finale 在一个篇章内应有某种节律？**倾向解读：只讲难度分档**——Finale 已明确只在篇章边界出现，与 Balatro 每 ante 一次 boss blind 形似但不同源。待确认。→ `20-systems/game-progression.md`。

## Notes / triage

- 本 handoff 是 08-01 / 08-01b 道念改写的第三篇，主要贡献是**把结算量从「待定公式」变成「可算的数」**（负侧 1:1、奖励归属 combat-service、奖励分两类）。
- 两条**流程性**约定（ch1 数值模型专场、优先打磨 ch1 内容）不属于任何单一主题文档，落进 `00-vision/scope.md` 的开发路线与 `20-systems/balance.md` 的待决问题归宿说明。
- MTG stack 与借词是**方向性**约定，本次只登记方向与其推论，不展开机制——展开归战斗内容专场。
