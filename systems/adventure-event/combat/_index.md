# adventure-event / combat（AdventureEvent-Combat）

> 正式回合制战斗遭遇：回合结构、敌人意图 / AI、**mana + 道念战斗模型**、胜 / 负结算。含敌人内容定义。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

### 战斗定位

- **Combat = AdventureEvent 的一个子类型。** 与 ADR-0002 分类法一致。
- **战斗是回合制且易读，而非实时 / 拼 APM。** 敌人以「意图（intent）」表达下一步行动；**意图是否呈现给玩家由等级差决定**（见下）。Source: `handoffs/2026-07-13.md`。

### 战斗模型 = mana（出牌）+ 道念（计分与胜负）（已定案）

- **胜负 = 道念高者胜（已定案）。** 战斗内的胜负标尺是**道念（momentum）**——计分用的胜利点数，双方各持一份，**高者胜**。**战斗过程中 lifeTotal 不参与**（既不消耗也不读取）；失败时角色在**结算时刻**按「角色道念 − 敌人道念」的差值损失 lifeTotal。完整模型见 `systems/scoring.md`；lifeTotal 的战斗外语义见 `systems/character-profile/life-total.md`。Source: `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。
- **一场标准 Combat = 固定 10 个回合（已定案）。** 双方各 5 个回合、交替，**打满即止**再比道念；不设提前终止（无「先到某值即胜」，也不以卡组耗尽终止）。**回合数固定，且每个回合的步骤固定（三步，见下）**，故**「每场时长可预测」成立**——它直接服务篇章时长控制，无须为交互次数另加护栏。Source: `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md` + `handoffs/2026-08-02b-stack-without-interaction-and-three-step-turn.md`。
- **道念的规则骨架（已定案）：** 由**卡牌**产出、**可互相削减**、**下限为 0**；**起始道念 = `baseMomentum`（按自身全局等级）**，故**等级差直接变成开局的起跑线差**——这与「敌人等级精确标注」形成闭环：看到等级即看到起跑线。表与系数归 `systems/balance.md`，完整模型见 `systems/scoring.md`。Source: 同上。
- **胜利侧也读道念差（已定案）。** 赢多少也算数：**道念差越大，奖励越厚**（碾压 > 险胜）。道念差因此是一个双向刻度——胜侧给奖励厚度，负侧扣 lifeTotal。Source: 同上。
- **负侧换算 = 1:1（已定案）。** 失败时 `lifeTotal -= (敌人道念 − 角色道念)`——道念差就是损失量，中间不隔系数。`momentum` 为 **`>= 0` 的 Integer**。Source: `handoffs/2026-08-02-momentum-conversion-reward-structure-and-mtg-stack.md`。
- **Combat = 三档难度中的「大盲」（已定案）。** Practice / Combat / Finale 对位 Balatro 的 **small / big / boss blind**：**Combat 是标准档**——10 回合、道念高者胜；Practice 更简单、Finale 更难，二者的**回合数与胜负条件均可被改写**。**推论：10 回合与「道念高者胜」是 Combat 这一档的默认值，不是全局常量**。借的是 blind 的难度分档结构，不是它的计分结构。Source: 同上。
- **卡牌结算 = stack，但交互与优先权移除（已定案 · 承重 · 08-02b 收窄）。** 借入 MTG 的 **stack**（先入栈、后进先出、「打出」与「结算」分两个时刻）；**但 instant / 栈非空时出牌与优先权传递整体不借**——理由是它们**拉长时长、决策点过多、复杂度高而深度收益小**。**推论：「双方各 5 个回合、我打完换你打」的简单交替成立**，且**「定长 = 每场时长可预测」恢复成立**。规则细则见 `systems/character-profile/deck/`。Source: `handoffs/2026-08-02b-stack-without-interaction-and-three-step-turn.md`。
- **回合结构 = 三步（已定案 · 08-02b）。** **起始步**（回合归属方 mana 恢复至 `manaLimit` → 触发「回合开始时」→ 抽牌）→ **主阶段**（唯一出牌阶段，只有归属方出牌，sorcery speed）→ **结束步**（触发「回合结束时」→ 清理回合内状态）。**三步是回合归属方的流程，双方不同时走**：每一方在自己的回合内各走一套完整的三步，「回合开始 / 回合结束」是有归属方的时点，不是双方同步的公共时刻。**去掉战斗步骤、不设双主阶段**——**推论：没有 MTG 式的攻击阶段**，道念的产出 / 削减全部经由主阶段打出的卡牌，不存在第二条结算通道。完整结构与步内顺序的意义见 `systems/services/combat-service.md`。Source: 同上。

- **战场（battlefield）= 战斗的公共区（已定案 · 08-03 · 承重）。** 场上的**全部准确数据**（正在生效的卡牌、持续状态、等待中的触发器）落在 battlefield 上，由 combat-service 的 **BattlefieldManager** 持有；**栈**另由 **StackManager** 持有。**二者是两个区**：栈 = 等待结算的队列，战场 = 已结算并正在生效的东西——结算路径 = **打出 → 入栈 → LIFO 弹出结算 → 效果施加 →（若持续）落到战场**。**推论 ①：至今空白的「回合内效果 / 状态系统」有了承载结构**——状态即**战场上带生命周期标记的条目**，结束步清理标记为回合内的那些。**推论 ②：意图的合并结果须以战场为输入**（场上的持续状态会改写本回合出牌的最终结果）。**推论 ③：战场必须进入呈现层**（栈之外的第二个区）。Source: `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md`。
- **触发式效果的载体开放，不专属卡牌（已定案 · 08-03）。** 牌上的触发器、**场上的持续状态**、**CharacterPower（神通）** 都可能承载，**清单可再增**；「谁在监听哪个时点」的注册面坐在战场上，命中后由 StackManager 压栈。**推论：轮回级能力必须能被战斗内读到**——参战方组装时要把角色持有的神通注册进战场。Source: 同上。
- **道念下限 0 在每一次结算时截断（已定案 · 08-03）。** 溢出的削减量不结转，故 **LIFO 顺序对最终结果有实际影响**（削减与产出交错时）。见 `systems/scoring.md`。Source: 同上。
- **满手时抽牌抽不进（已定案 · 08-03）。** 牌留在抽牌堆、本次抽牌无事发生；「加入手牌」类效果同理落空。**手牌上限因此是纯上界与节奏约束**，不产生弃牌堆流量。见 `systems/character-profile/deck/`。Source: 同上。

### 结算产物（已定案）

- **胜：** `baseReward` + 按道念差加厚；**平：** 只发 `baseReward`；**负：** `baseReward`，**少数事件另夹带负向条目**（额外惩罚**包在 reward 里**，不另立结构——与 `ProfileChangeSpec` 的带符号约定自洽）。Source: `handoffs/2026-08-02-momentum-conversion-reward-structure-and-mtg-stack.md`。
- **奖励分两类：强制自动计入（例：经验）/ 可选由玩家择一（参照 Slay the Spire 的战后奖励面板）。** **推论：战斗后需要一个奖励选择步骤**，且它在战斗流程内——**奖励计算与发放归 combat-service**，写入仍由 life-cycle-service 在 `eventEnd` 一次施加。Source: 同上。
- **不是 StS 纯 HP，也不是 Balatro 的 chips × mult。** 道念是**双方对抗的相对量**（比谁高），不是对抗静态阈值的绝对量——与「敌人也出牌、双方对称」的参战方模型一致。
- **mana = 无曲线 · 每回合恢复至 `manaLimit`（已定案）。** 不采用 mana 曲线（既非 Hearthstone 式每回合 +1 上限，也非 MTG 式打地递增）：战斗内**每回合的起始步、回合归属方的 mana 自动恢复到 `manaLimit`**（08-02b 精确化：恢复的是本回合归属方的 mana——非归属方无法出牌，其 mana 在对手回合无用途）；`manaLimit` 本身**由 AdventureEvent 的 cost / reward 推拉**（可升可降），不随境界自动成长；**不设下界护栏**（下降极罕见）。**炼气期标准基线（起始满值）：** life = **10/10**、mana = **5/5**——战斗模型改写**未改动这两个数值**，只改了 life 的语义。Source: `handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md` + `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md` + `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。

### 危险度 = 精确标注敌人等级（已定案）

- **不做模糊的危险度档位。** 「同阶 / 略高 / 越阶 / 无从揣度」一类模糊标签**否决**；Combat / Practice / Finale 在 **eventOptions 上精确标注敌人的等级**。Source: `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。
- **推论 ①：等级差对玩家可见。** 玩家可自行把标注的敌人等级与自身等级比对，从而**理解意图为何被遮蔽**——信息遮蔽有了可解释的因，而不是无来由的惩罚。见 `ux/combat-ux.md`。
- **推论 ②：越级挑战成为可主动选择的风险 / 回报维度。** 信息可见，抉择才成立：玩家可以明知山有虎地去打高几级的敌人。Source: 同上。

### 意图的三档揭示（已定案）

- **三档结构：完整意图**（综合类型 + 综合数值）→ **仅类别**（攻击 / 防御 / 增益 / 特殊，无数值）→ **完全无信息**（不给任何替代线索）。Source: `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md`。
- **分界值 = 同阶差值 + 越阶硬门（已定案 · 08-02c 阈值下移）。** **越阶（敌人境界高于角色）一律完全无信息**——不论全局等级差多小；同阶时按 `diff`（= 敌人全局等级 − 角色全局等级）取门槛，**篇章分档保留**：**第一篇章** `diff ≤ -3` 完整 / `-2 ~ 2` 仅类别 / `≥ 3` 无信息；**第二 · 第三篇章** `diff ≤ -2` 完整 / `-1 ~ 1` 仅类别 / `≥ 2` 无信息（**两端各收紧一级 → 后期境界内每一级差在信息面上更值钱**，与 `baseMomentum` 跨度随境界放大同向）。**这把「境界鸿沟」从数值差提升为一条结构性规则**。完整规则与呈现见 `systems/services/combat-service.md`、`ux/combat-ux.md`。Source: `handoffs/2026-08-02c-intent-threshold-inversion-and-aggregate-intent.md`。
- **完整意图 = 碾压专属，第二档是常态（已定案 · 08-02c）。** 阈值下移后**同级对局（`diff = 0`）只给类别，不给数值——这是有意为之，不做补偿**；完整意图只在明显压制时出现（ch1 低 3 级、ch2 · ch3 低 2 级及以上），是**碾压弱敌的即时反馈**而非每场都有的基础信息；「略强 / 略弱」在信息上不作区分。**推论 ①：「仅类别」的视觉语言与类别枚举升为承重项**（它现在是玩家看得最多的一档）。**推论 ②：探查（probe）的价值显著上升**。**推论 ③：意图揭示不再承担教学职能**，同级对局的可读性须由图鉴 / 卡牌文本 / 道念主视觉承担。Source: 同上。
- **意图是回合级的综合描述（已定案 · 08-02c · 承重）。** **一个回合对手可以打出多张牌**，故意图是**对本回合全部出牌的汇总**——**综合数值 = 计算后合并的最终结果**（一个结果值，例：削减 12），**综合类别 = 主类别并行陈列**（跨类别时并列各主类别，不压缩、不归「特殊」）；**不暴露张数与逐张分解**。**推论 ①：敌人 AI 是回合级一次性规划**——呈现意图时本回合整套出牌已定并已算出合并结果。**推论 ②：意图数值是声明的量，与实际结算量可以不等**（下限 0 的饱和减法 + 触发入栈）。Source: 同上。
- **意图只在玩家回合呈现，内容是敌人的下一个回合（已定案 · 08-02c）。** 敌人回合内不呈现意图（那时它正在执行出牌）。**推论：意图的用途是为玩家本回合的出牌决策提供依据**，故合并成一条结果值即够用；敌人 AI 的规划时点因此前移到玩家回合开始之前。Source: 同上。
- **意图即承诺，公布后不因玩家行动重算（已定案 · 08-02c）。** 玩家在主阶段做什么都不改写敌人已公布的计划，也不刷新显示——玩家因此能据它布局（「它要打 12，我这回合防住 12」）。**推论 ①：AI 不走响应式路径**，决策发生在一个明确时点，难度旋钮落在规划算法与卡组而非临场调整。**推论 ②：承诺与执行可能不一致**（玩家行动使计划中的牌无法照原样执行），处理方式未定，见待决问题。Source: 同上。
- **探查（probe）是第二条信息通道** —— 玩家主动付代价换取当回合意图；形态归卡牌 / 技能内容的横向扩展阶段，本阶段搁置。Source: `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md`。
- **敌人图鉴给静态知识**（这个敌人会做哪些事），**不给动态情报**（它这回合做什么），故不架空越级黑箱。**一次遭遇即解锁全部词条文案**（人物背景 / 功法简介 / 运作方式 / 特点与弱点 / 样本卡组的关键卡牌）。见 `systems/player-profile/codex/enemy-codex.md`。Source: 同上 + `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。

### 敌人

- **敌人持有道念、intent（意图）、行为，并持有自己的卡组（已定案）。** 敌人也出牌：每个 enemy 各有一个卡组，可为定制卡组（如 Finale 的天劫）。参战方结构见 `systems/services/combat-service.md` 的 EnemyManager / CharacterManager。**敌人侧的战斗内量与玩家侧对称，也是道念**——敌人同样以道念高低论胜负，不设独立的血量池。Source: `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md` + `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。
- **敌人带等级，等级是物化产物（已定案）。** 敌人的静态数据集中在 **`EnemyTemplate`**（稳定 `Id` + 图鉴文案 + 基准数值 + **样本卡组**）；**future-event-service 取一份模板 → 充实 / 改写 → 指派给该事件**，等级在这一步确定。因此**同一个敌人可在不同篇章 / 情境下以不同等级出场**，等级既是意图揭示的判据，也**随物化产物落进 `EventOption` 精确标注给玩家**。见 `systems/services/future-event-service.md`。Source: `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。
- **敌人是数据资源。** 每个敌人模板为一个 `.tres` 内容条目，带稳定 `Id`；战斗 AdventureEvent 引用敌人组合。Source: `data-resource-rules.md`。
- **敌人的战斗强度以 `baseMomentum` 为主刻度。** 敌人等级 → 起始道念 → 开局领先量，这是越级压迫感的直接来源；「敌人各等级的道念产出缩放」仍待设计。→ `systems/balance.md`。Source: `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- **战斗模型 = mana（出牌）+ 道念（计分与胜负）；胜负 = 道念高者胜；失败按道念差扣 lifeTotal** —— 已定案。Source: `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。
- **战斗固定 10 回合（双方各 5）；道念由卡牌产出、可互削、下限 0、起始 = `baseMomentum`；胜利侧按道念差给奖励厚度** —— 已定案。Source: `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。
- **敌人静态数据 = `EnemyTemplate`；敌人等级为 future-event-service 的物化产物** —— 已定案。Source: 同上。
- **意图分档 = 同阶差值 + 越阶硬门**（ch1：`≤ -3` 完整 / `-2 ~ 2` 仅类别 / `≥ 3` 无信息；ch2 · ch3：`≤ -2` / `-1 ~ 1` / `≥ 2`）；**意图为回合级综合描述，只在玩家回合呈现敌人下一回合** —— 已定案。Source: `handoffs/2026-08-02c-intent-threshold-inversion-and-aggregate-intent.md`。
- **mana 无曲线 · 每回合恢复至 `manaLimit`、炼气基线 10/10 · 5/5** —— 已定案。Source: `handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md` + `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md`。
- **敌人意图三档揭示（按全局等级差）；探查为第二条信息通道** —— 已定案。Source: `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md`。
- **危险度 = eventOptions 上精确标注敌人等级（否决模糊档位）；等级差因此可见** —— 已定案。Source: `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。
- **引入 battlefield（战场）及 BattlefieldManager / StackManager；触发载体开放；道念下限 0 逐次结算截断；满手抽不进** —— 已定案。Source: `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md`。
- **Combat 为分类法第二类** → `decisions/ADR-0002-adventure-event-taxonomy.md`。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **意图类别的枚举（08-02c 加压 · 第二档已成常态档）：** 展示粒度定为「攻击 / 防御 / 增益 / 特殊」，其正式枚举与敌人行为的映射未定（**跨类别呈现已答定 = 主类别并行陈列**）。→ `systems/services/combat-service.md`、`ux/combat-ux.md`。Source: `handoffs/2026-08-02c-intent-threshold-inversion-and-aggregate-intent.md`。
- **承诺与执行不一致时如何处理（08-02c 追加）：** 意图公布后不重算已定案；但玩家行动可能让计划中的某张牌在敌人回合无法照原样执行（资源变化 / 目标状态改变 / 牌被移出手牌）——跳过该张照打其余？降级执行？还是允许临场替换（等于开了重算的口子）？→ `systems/character-profile/deck/`、`systems/services/combat-service.md`。Source: 同上。
- **`EnemyTemplate` 与既有 `EnemyData` 的关系：** 是同一个东西的两个名字（则统一定名），还是两层？**物化后的敌人实例**亦未定名，且「随 `EventOption` 落存档 vs 战斗开始时再展开」未定。→ `systems/services/future-event-service.md`。Source: 同上。
- **敌人卡组的设计形态：** 模板带**样本卡组**已定（物化时可改写）；其卡牌是与玩家共用 `CardData` 体系还是另立敌方卡池、卡组规模与抽牌规则均未定。→ `systems/character-profile/deck/`。Source: `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md` + 同上。
- **平局已定案：** 10 回合打满道念相等 → **只发基础奖励**、不扣 lifeTotal（`CombatOutcome.Draw`）。
- **卡牌产 / 削道念的量纲基准：** 一张牌该产多少、10 回合内一方总产出相对起始值的倍数——**它决定越级追分是否可能**；是否存在道念相关的状态与倍率亦未定。→ `systems/character-profile/deck/`、`systems/balance.md`。Source: 同上。
- **胜利侧的「道念差 → 奖励厚度」换算：** **负侧已定为 1:1**；胜侧仍是定性表述，若也 1:1，「1 点道念差」在奖励侧等于什么单位未定。→ `systems/balance.md`。Source: `handoffs/2026-08-02-momentum-conversion-reward-structure-and-mtg-stack.md`。
- **可选奖励的候选生成：** 候选数量 / 抽自哪个池 / 是否受道念差影响未定（**奖励预先算定、选择不是决策点**已定案）。→ `systems/services/combat-service.md`。Source: 同上。
- **触发条件能否跨归属方（08-02b 新增 · 08-03 收窄）：** **载体形态已答定**（牌上触发器 / 场上持续状态 / CharacterPower，清单开放）；仍待定触发条件能否写「对手的回合开始时」这类跨归属方的时点。→ `systems/character-profile/deck/`、`systems/services/combat-service.md`。Source: `handoffs/2026-08-02b-stack-without-interaction-and-three-step-turn.md` + `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md`。
- **手牌上限的数值（08-02b 新增）：** 语义已全定（恒定不变式、无弃牌机制、**满手抽不进**）；**上限数值**未给，敌人侧是否同值亦未给。→ `systems/character-profile/deck/`。Source: 同上。
- **「回合内状态」的判定边界（08-02b 新增 · 08-03 有了落点）：** **承载结构已定**（战场上带生命周期标记的条目）；仍待定**取值**——结束步清理哪些东西、「持续到下回合结束」这类跨回合时长如何表达。Source: 同上。
- **`manaLimit` 推拉的分档：** 哪些事件推高 / 压低、单次幅度（下界护栏已明确不做）。→ `systems/character-profile/mana.md`、`systems/balance.md`。
- **属性模型与战斗资源共存：** 隐藏属性（道心 / 煞气 / 寿元）与 mana / 道念 / lifeTotal 如何共存与推拉未定。→ `systems/services/plot-manager.md`、`systems/services/life-cycle-service.md`。
- **敌人 AI / intent 系统：** 意图选择逻辑、多回合行为脚本、敌人组合与出现规则均未定义。
- **敌人平衡：** 敌人各等级的道念**产出**能力（起始值已由 `baseMomentum` 给定）、随境界 / 篇章缩放未定。→ `systems/balance.md`。Source: 同上。
- **失败后果的其余部分：** 胜利奖励随道念差变厚已定；失败除扣 lifeTotal 外是否另有后果、与寿元 / Finale 的交互未定。
- **enemies 归属（Open question）：** 当前归 combat/；**Practice 与 Finale 均已确认使用敌人**（天劫即一个带定制卡组的 Enemy），是否应升为共享内容层待确认。Source: `handoffs/2026-07-24-docs-restructure-class-model.md` + `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md`。

## 对应
提炼至：`.claude/knowledge/systems/adventure-event/combat.md`（待建）
