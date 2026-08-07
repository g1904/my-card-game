# adventure-event / combat（AdventureEvent-Combat）

> 正式回合制战斗遭遇：回合结构、敌人意图 / AI、**mana + 道念战斗模型**、胜 / 负结算。含敌人内容定义。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

### 战斗定位

- **Combat = AdventureEvent 的一个子类型。** 与 ADR-0002 分类法一致。
- **战斗是回合制且易读，而非实时 / 拼 APM。** 敌人以「意图（intent）」表达下一步行动；**意图是否呈现给玩家由等级差决定**（见下）。Source: `handoffs/2026-07-13.md`。

### 战斗模型 = mana（出牌）+ 道念（计分与胜负）（已定案）

- **胜负 = 道念高者胜（已定案）。** 战斗内的胜负标尺是**道念（momentum）**——计分用的胜利点数，双方各持一份，**高者胜**。**战斗过程中 lifeTotal 不参与**（既不消耗也不读取）；失败时角色在**收口时刻**按「角色道念 − 敌人道念」的差值损失 lifeTotal。完整模型见 `systems/scoring.md`；lifeTotal 的战斗外语义见 `systems/character-profile/life-total.md`。Source: `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。
- **一场标准 Combat = 固定 10 个回合（已定案）。** 双方各 5 个回合、交替，**打满即止**再比道念；不设提前终止（无「先到某值即胜」，也不以卡组耗尽终止）。**回合数固定，且每个回合的步骤固定（三步，见下）**，故**「每场时长可预测」成立**——它直接服务篇章时长控制，无须为交互次数另加护栏。Source: `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md` + `handoffs/2026-08-02b-stack-without-interaction-and-three-step-turn.md`。
- **道念的规则骨架（已定案）：** 由**卡牌**产出、**可互相削减**、**下限为 0**；**起始道念 = `baseMomentum`（按自身全局等级）**，故**等级差直接变成开局的起跑线差**——这与「敌人等级精确标注」形成闭环：看到等级即看到起跑线。表与系数归 `systems/balance.md`，完整模型见 `systems/scoring.md`。Source: 同上。
- **胜利侧也读道念差（已定案 · 换算 = 两条支路）。** 赢多少也算数：**道念差越大，奖励越厚**（碾压 > 险胜）。道念差因此是一个双向刻度——胜侧给奖励厚度，负侧扣 lifeTotal。**换算分两条支路**：**强制奖励（可数量）走线性 `1:1 × 可调单价`**（「1 点道念差 = 1 个 `rewardPerMomentum` 单位」，单价逐篇章下调）；**可选奖励（品质）走归一化 `advantage` 三档**（险胜 / 优胜 / 碾压，只改候选池的稀有度权重、不改数量）。公式、单价表与门槛见 `systems/balance.md`。Source: 同上 + `handoffs/2026-08-06d-combat-open-questions-mass-closure.md`。
- **负侧换算 = 1:1（已定案）。** 失败时 `lifeTotal -= (敌人道念 − 角色道念)`——道念差就是损失量，中间不隔系数。`momentum` 为 **`>= 0` 的 Integer**。Source: `handoffs/2026-08-02-momentum-conversion-reward-structure-and-mtg-stack.md`。
- **Combat = 三档难度中的「大盲」（已定案 · 改写值已给）。** Practice / Combat / Finale 对位 Balatro 的 **small / big / boss blind**。**回合数与胜负判据是遭遇参数，落在 `EncounterSpec` 上**（不落 `EnemyData`）：**Practice 8 回合 `(WinMargin 0, DrawCountsAsLoss false)` / Combat 10 回合 `(1, false)` / Finale 12 回合 `(N, false)`**。**难度旋钮 = `WinMargin`，回合数 = 节奏旋钮。** **推论：10 回合与「道念高者胜」是 Combat 这一档的默认值，不是全局常量**。借的是 blind 的难度分档结构，不是它的计分结构。取值与理由见 `systems/balance.md`。Source: 同上 + `handoffs/2026-08-06d-combat-open-questions-mass-closure.md`。
- **胜负判据参数化为两个数，不做「可替换的判定对象」（已定案）。** `VictoryRule(int WinMargin, bool DrawCountsAsLoss)`：`d = 角色道念 − 敌人道念`；`d >= WinMargin` → Victory；否则 `DrawCountsAsLoss ? Defeat : Draw`。代入已陈述的全部需求（标准 Combat `(1, false)`、Practice「打平即通过」`(0, false)`、Finale「必须领先 N 点」`(N, false)`）已完全覆盖——**无需策略枚举、无需分发**。Source: `handoffs/2026-08-06d-combat-open-questions-mass-closure.md`。
- **卡牌结算 = stack，但交互与优先权移除（已定案 · 承重 · 08-02b 收窄）。** 借入 MTG 的 **stack**（先入栈、后进先出、「打出」与「结算」分两个时刻）；**但 instant / 栈非空时出牌与优先权传递整体不借**——理由是它们**拉长时长、决策点过多、复杂度高而深度收益小**。**推论：「双方各 5 个回合、我打完换你打」的简单交替成立**，且**「定长 = 每场时长可预测」恢复成立**。规则细则见 `systems/character-profile/deck/`。Source: `handoffs/2026-08-02b-stack-without-interaction-and-three-step-turn.md`。
- **回合结构 = 三步（已定案 · 08-02b）。** **开始阶段**（回合归属方 mana 恢复至 `manaLimit` → 触发「回合开始时」→ 抽牌）→ **行动阶段**（唯一出牌阶段，只有归属方出牌）→ **结束阶段**（触发「回合结束时」→ 清理回合内的非永久条目）。**中文侧统一以「阶段」收尾、英文侧统一以 `step` 收尾**（`start step` / `action step` / `end step`，08-04b 定名；`main phase` 弃用）。**出牌时机是唯一的、且是全局规则**：自己回合的行动阶段、栈为空时——`sorcery speed` 一词亦不借（08-04b 整条弃用）。**三步是回合归属方的流程，双方不同时走**：每一方在自己的回合内各走一套完整的三步，「回合开始 / 回合结束」是有归属方的时点，不是双方同步的公共时刻。**去掉战斗步骤、不设双主阶段**——**推论：没有 MTG 式的攻击阶段**，道念的产出 / 削减全部经由行动阶段打出的卡牌，不存在第二条结算通道。完整结构与步内顺序的意义见 `systems/services/combat-service.md`。Source: 同上。

- **战场（battlefield）= 战斗的公共区（已定案 · 08-03 · 承重）。** 场上的**全部准确数据**（正在生效的卡牌、持续状态、等待中的触发器）落在 battlefield 上，由 combat-service 的 **BattlefieldManager** 持有；**栈**另由 **StackManager** 持有。**二者是两个区**：栈 = 等待结算的队列，战场 = 已结算并正在生效的东西——结算路径 = **打出 → 入栈 → LIFO 弹出结算 → 效果施加 →（若持续）落到战场**。**推论 ①：至今空白的「回合内效果 / 状态系统」有了承载结构**——状态即**战场上带生命周期标记的条目**，结束阶段清理标记为回合内的那些。**推论 ②：意图的合并结果须以战场为输入**（场上的持续状态会改写本回合出牌的最终结果）。**推论 ③：战场必须进入呈现层**（栈之外的第二个区）。Source: `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md`。
- **触发式效果的载体开放，不专属卡牌（已定案 · 08-03）。** 牌上的触发器、**场上的持续状态**、**CharacterPower（神通）** 都可能承载，**清单可再增**；「谁在监听哪个时点」的注册面坐在战场上，命中后由 StackManager 压栈。**推论：轮回级能力必须能被战斗内读到**——参战方组装时要把角色持有的神通注册进战场。Source: 同上。
- **道念下限 0 在每一次结算时截断（已定案 · 08-03）。** 溢出的削减量不结转，故 **LIFO 顺序对最终结果有实际影响**（削减与产出交错时）。见 `systems/scoring.md`。Source: 同上。
- **卡牌类型六分 + 异能三分 + 永久物（已定案 · 08-04b · 承重）。** 六类 = **法术 `Sorcery`** / **灵宠 `Creature`** / **阵法 `Enchantment`** / **法宝·古宝 `Item`** / **神通·法则 `Power`** / **业障 `Affliction`**；异能三分 = **静止式 / 启动式 / 触发式**（与 08-03 的「载体开放」正交：载体说「挂在谁身上」，类型说「怎么生效」）；**永久物 = 战场条目的子集**（灵宠 / 阵法 / `Power`），**永不被结束阶段清理**。**推论 ①：战斗内的来源区从一个变成三个**——卡组（受抽牌运）· 本场可用道具（不受抽牌运，需玩家动作）· 开局入场的 `Power`（不受抽牌运，无需动作）。**推论 ②：卡牌类型与意图类别正交**——前者是结算生命周期的分类，后者是敌人行为的展示分类，**不共用一套枚举**（否则「既产道念又削对方道念的牌属于哪类」无解，且意图类别一改就波及卡牌数据）。**推论 ③：灵宠是「延迟回报」型的道念产出通道**——法术即时产出、灵宠分期产出，**越接近第 10 回合灵宠越不划算**；定长战斗天然给了它一条内建的时间价值曲线，不需要额外机制支撑。规则细则见 `systems/character-profile/deck/`。Source: `handoffs/2026-08-04b-mtg-loanwords-card-types-and-intent-snapshot.md`。
- **满手时抽牌抽不进（已定案 · 08-03）。** 牌留在抽牌堆、本次抽牌无事发生；「加入手牌」类效果同理落空。**手牌上限因此是纯上界与节奏约束**，不产生弃牌堆流量。见 `systems/character-profile/deck/`。Source: 同上。

### 结算产物（已定案）

- **胜：** `baseReward` + 按道念差加厚；**平：** 只发 `baseReward`；**负：** `baseReward`，**少数事件另夹带负向条目**（额外惩罚**包在 reward 里**，不另立结构——与 `ProfileChangeSpec` 的带符号约定自洽）。Source: `handoffs/2026-08-02-momentum-conversion-reward-structure-and-mtg-stack.md`。
- **奖励分两类：强制自动计入（例：经验）/ 可选由玩家择一（参照 Slay the Spire 的战后奖励面板）。** **推论：战斗后需要一个奖励选择步骤**，且它在战斗流程内——**奖励计算与发放归 combat-service**，写入仍由 life-cycle-service 在 `eventEnd` 一次施加。Source: 同上。
- **不是 StS 纯 HP，也不是 Balatro 的 chips × mult。** 道念是**双方对抗的相对量**（比谁高），不是对抗静态阈值的绝对量——与「敌人也出牌、双方对称」的参战方模型一致。
- **mana = 无曲线 · 每回合恢复至 `manaLimit`（已定案）。** 不采用 mana 曲线（既非 Hearthstone 式每回合 +1 上限，也非 MTG 式打地递增）：战斗内**每回合的开始阶段、回合归属方的 mana 自动恢复到 `manaLimit`**（08-02b 精确化：恢复的是本回合归属方的 mana——非归属方无法出牌，其 mana 在对手回合无用途）；`manaLimit` 本身**由 AdventureEvent 的 cost / reward 推拉**（可升可降），不随境界自动成长；**不设下界护栏**（下降极罕见）。**炼气期标准基线（起始满值）：** life = **10/10**、mana = **5/5**——战斗模型改写**未改动这两个数值**，只改了 life 的语义。Source: `handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md` + `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md` + `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。

### 危险度 = 精确标注敌人等级（已定案）

- **不做模糊的危险度档位。** 「同阶 / 略高 / 越阶 / 无从揣度」一类模糊标签**否决**；Combat / Practice / Finale 在 **eventOptions 上精确标注敌人的等级**。Source: `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。
- **推论 ①：等级差对玩家可见。** 玩家可自行把标注的敌人等级与自身等级比对，从而**理解意图为何被遮蔽**——信息遮蔽有了可解释的因，而不是无来由的惩罚。见 `ux/combat-ux.md`。
- **推论 ②：越级挑战成为可主动选择的风险 / 回报维度。** 信息可见，抉择才成立：玩家可以明知山有虎地去打高几级的敌人。Source: 同上。

### 意图的三档揭示（已定案）

- **三档结构：完整意图**（综合类型 + 综合数值）→ **仅类别**（攻击 / 防御 / 增益 / 特殊，无数值）→ **完全无信息**（不给任何替代线索）。Source: `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md`。
- **分界值 = 同阶差值 + 一道越阶硬门（已定案 · 三档整体收紧一级）。** **越阶（敌人境界高于角色）一律完全无信息**——不论全局等级差多小；同阶时按 `diff`（= 敌人全局等级 − 角色全局等级）取门槛，**篇章分档保留**：

  | 篇章 | 完整意图 | 仅类别 | 完全无信息 |
  |------|---------|--------|-----------|
  | **第一篇章 炼气** | `diff ≤ −2` | `−1 ~ +1` | `diff ≥ +2` |
  | **第二 · 第三篇章** | `diff ≤ −1` | `diff = 0` | `diff ≥ +1` |

  三处门槛整体压进 `±2` 带的五个格子内，使**三档在带内全部可达**（此前取值下 ch1 的完整档与无信息档皆不可达、ch2 · ch3 完整档只剩一个取值）。**三档结构、越阶硬门、篇章分档三条框架不动**；**这把「境界鸿沟」从数值差提升为一条结构性规则**。完整规则与呈现见 `systems/services/combat-service.md`、`ux/combat-ux.md`；数值与代价见 `systems/balance.md`。Source: `handoffs/2026-08-02c-intent-threshold-inversion-and-aggregate-intent.md` + `handoffs/2026-08-06d-combat-open-questions-mass-closure.md`。
- **完整意图 = 碾压专属，且「碾压」重定义为「压到带内下界」（已定案）。** 本作能出现的最大压制就是 `diff = −2`（ch1）/ `−1`（ch2 · ch3），故完整意图仍是奖励，只是尺子短了——不再是「低 3 级」。**同级对局（`diff = 0`）三章恒为「仅类别」，这是有意为之、不做补偿**；「略强 / 略弱」在信息上不作区分。**推论 ①：「仅类别」是玩家看得最多的一档，但这条判断只在 ch1 成立**——ch2 · ch3 的第二档收窄为 `diff = 0` 单一取值，而黑箱门下移到 `+1` 后约五分之二的同阶遭遇完全无信息，**后期战斗可读性显著下降是有意接受的代价**，不做意图侧补偿。**推论 ②：探查（probe）的价值显著上升**。**推论 ③：意图揭示不再承担教学职能**，可读性须由图鉴 / 卡牌文本 / 道念主视觉承担。**推论 ④：轮回最初两级（角色全局等级 1 · 2）因带被截断而恒为「仅类别」**，这是开局的自然状态，不是死档。Source: 同上。
- **意图类别的枚举 = `IntentCategory { Offense, Defense, Buff, Special }`（已定案）。** 判据**以道念语义定义，不以卡牌类型定义**（既定：卡牌类型与意图类别正交，正交的两套分类只能各自标注、不能互相推导）：

  | 中文 | 标识符 | 判据 |
  |------|--------|------|
  | 攻击 | `Offense` | 净效果是**削减对手道念** |
  | 防御 | `Defense` | 净效果是**保护自身道念**（抵消 / 减免 / 免疫 / 清除对手场上条目） |
  | 增益 | `Buff` | 净效果是**提升自身道念或自身后续产出**（产道念、加成、灵宠 / 阵法落场） |
  | 特殊 | `Special` | 不落入上述三类者：抽牌 / 过牌、mana 操作、弃牌、探查、规则改写 |

  - **映射 = 内容侧静态标注**：每个 `AbilityData` / 效果原语带一个 `IntentCategory` 字段（`.tres` 上的静态字段），**不从合并结果反推**（「既产道念又削对方道念的牌属于哪类」无解）。填错不崩溃，只会误导玩家 → 加载期 `PushWarning` 软检查（例：削减类效果标成 `Buff`）。
  - **主类别可机械计算**：按类别归桶 → 每桶累计**道念当量**（`Special` 桶无当量，按「存在即计 1」）→ 取贡献占比 **≥ 20%** 的全部桶 → 至少 1 个、至多 4 个 → 按贡献降序陈列。**20% 是把符号数从 4 压到通常 1~2 的可调旋钮**（竖屏窄边容不下四个符号）。
  - **不进意图但仍参与合并计算的两类**：埋伏、静止式异能（判据 = 「凡不在敌人自己回合发生的东西一律不进意图」）。**它们改写数值，只是不作为类别陈列**——这条须写明，否则实现上会把「不进意图」误读为「不参与计算」。
  - 三档需要一个正式枚举 `IntentRevealTier { Full, CategoryOnly, Hidden }`；`EnemyIntent` **不落存档**（可由局面 + RNG `State` 重算）。
  - **已知风险**：每个效果原语多一个必填字段，内容作者要为它做判断；**`Special` 是兜底桶、有膨胀风险**（玩家读到「特殊」等于读到「不知道」）——若内容铺开后占比偏高再拆，属**内容量起来后的编排复盘，不作为设计待答项保留**。
  Source: `handoffs/2026-08-06d-combat-open-questions-mass-closure.md`。
- **意图是回合级的综合描述（已定案 · 08-02c · 承重）。** **一个回合对手可以打出多张牌**，故意图是**对本回合全部出牌的汇总**——**综合数值 = 计算后合并的最终结果**（一个结果值），**综合类别 = 主类别并行陈列**（跨类别时并列各主类别，不压缩、不归「特殊」）；**不暴露张数与逐张分解**。**完整档那「一个结果值」的语义**：主类别含 `Offense` → 数值 = 对玩家道念的**预估净削减量**，负号呈现（`−12`）；不含 `Offense`（纯增益 / 防御回合）→ 数值 = 敌人道念的**预估净增量**，正号呈现（`+9`）。**两者共用一个数字位，靠符号区分，不并列两个数。****推论 ①：敌人 AI 是回合级一次性规划**——呈现意图时本回合整套出牌已定并已算出合并结果。**推论 ②：意图数值是声明的量，与实际结算量可以不等**（下限 0 的饱和减法 + 触发入栈）。Source: 同上。
- **意图只在玩家回合呈现，内容是敌人的下一个回合（已定案 · 08-02c）。** 敌人回合内不呈现意图（那时它正在执行出牌）。**推论：意图的用途是为玩家本回合的出牌决策提供依据**，故合并成一条结果值即够用；敌人 AI 的规划时点因此前移到玩家回合开始之前。Source: 同上。
- **意图即快照：公布后不重算，但不保证与执行一致（已定案 · 08-02c 立、08-04b 修正措辞 · 承重）。** **意图 = 敌人在玩家回合开始前，按当时局面用公式推算出的本回合预期决策链路的快照。** 玩家在行动阶段做什么都不改写它、也不刷新显示——玩家因此能据它布局；但**敌人回合的实际执行按执行时的真实局面求值**，与快照可能有偏差。**「承诺」的准确含义是「公布后不重算」，而非「结果必然如此」。** **推论 ①：偏差不做任何处理**——三个候选解（跳过该张照打其余 / 降级执行 / 允许临场替换）全部不采用；执行阶段逐步走规划链路，不可执行的步骤自然落空，**EnemyManager 因此不需要一致性校验与回退逻辑**（代码面净减）。**推论 ②：AI 不走响应式路径**，难度旋钮仍落在规划算法与卡组。**推论 ③：埋伏牌与敌人道具是偏差的正常来源**，不需要特殊处理。**推论 ④：「意图数值 ≠ 实际结算量」从异常升为常态**——意图是声明的量，`PlayResult` 是发生的量。**代价：呈现层承担解释责任**（语气改为「预估」+ 敌人回合执行过程逐步可见），见 `ux/combat-ux.md`。Source: 同上 + `handoffs/2026-08-04b-mtg-loanwords-card-types-and-intent-snapshot.md`。
- **敌人的道具效果计入意图数值（已定案 · 08-04b）。** 敌人同样持有 item 与 power（来自 `EnemyData` 的两个持有列表），**道具是行动的一种**，排除它会让意图失去参考价值。**推论：EnemyManager 的规划输入从「卡组 + 战场」扩到「卡组 + 战场 + 本场可用道具 + 对手的埋伏计数」**——AI 在玩家回合开始之前就要连道具一起定好整套行动。**这不新增机制**：「回合级一次性规划」本就排除了逐张即时决策，道具只是规划输入里多了一个来源。**埋伏的信息是对称的**——AI 读到的是计数而非条目内容，可以据此变得谨慎（例：留一张牌不打）但无法针对性规避，故**埋伏的威慑力与实际效果是两件事**。Source: `handoffs/2026-08-04b-mtg-loanwords-card-types-and-intent-snapshot.md`。
- **探查（probe）是第二条信息通道** —— 玩家主动付代价换取当回合意图；形态归卡牌 / 技能内容的横向扩展阶段，本阶段搁置。Source: `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md`。
- **敌人图鉴给静态知识**（这个敌人会做哪些事），**不给动态情报**（它这回合做什么），故不架空越级黑箱。**一次遭遇即解锁全部词条文案**（人物背景 / 功法简介 / 运作方式 / 特点与弱点 / 样本卡组的关键卡牌）。见 `systems/player-profile/codex/enemy-codex.md`。Source: 同上 + `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。

### 敌人 → `systems/enemies/`

**敌人已升为与 `adventure-event` 平级的系统**（三类战斗事件共享同一批条目）。`EnemyData` 的字段与语义、模板 ↔ 实例二元、样本卡组、item / power 持有列表、`EncounterScopes` 与 `PoolScope`、赋级带的接受面、埋伏规则**全部归 `systems/enemies/`**。本文件只保留与战斗规则直接接壤的三条：

- **敌人是对称的参战方。** 敌人也持道念、也出牌、各持一个 `DeckModule`，**敌人侧的战斗内量与玩家侧对称**——同样以道念高低论胜负，不设独立的血量池。参战方结构见 `systems/services/combat-service.md` 的 EnemyManager / CharacterManager。
- **敌人的战斗强度以 `baseMomentum` 为主刻度。** 等级 → 起始道念 → 开局领先量，这是越级压迫感的直接来源；**卡组保持强度中立、不叠第二条强度曲线**。
- **敌人等级是物化产物**，落在角色等级 `±2` 带内（三章统一），既是意图揭示的判据，也随物化产物落进 `EventOption` 精确标注给玩家。见 `systems/services/future-event-service.md`、`systems/balance.md`。

Source: `handoffs/2026-08-06d-combat-open-questions-mass-closure.md`。

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- **战斗模型 = mana（出牌）+ 道念（计分与胜负）；胜负 = 道念高者胜；失败按道念差扣 lifeTotal** —— 已定案。Source: `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。
- **战斗固定 10 回合（双方各 5）；道念由卡牌产出、可互削、下限 0、起始 = `baseMomentum`；胜利侧按道念差给奖励厚度** —— 已定案。Source: `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。
- **敌人静态数据 = `EnemyData`；敌人等级为 future-event-service 的物化产物** —— 已定案。Source: 同上。
- **意图分档 = 同阶差值 + 越阶硬门**（ch1：`≤ −2` 完整 / `−1 ~ +1` 仅类别 / `≥ +2` 无信息；ch2 · ch3：`≤ −1` / `= 0` / `≥ +1`）；**意图为回合级综合描述，只在玩家回合呈现敌人下一回合** —— 已定案。Source: `handoffs/2026-08-02c-intent-threshold-inversion-and-aggregate-intent.md` + `handoffs/2026-08-06d-combat-open-questions-mass-closure.md`。
- **mana 无曲线 · 每回合恢复至 `manaLimit`、炼气基线 10/10 · 5/5** —— 已定案。Source: `handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md` + `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md`。
- **敌人意图三档揭示（按全局等级差）；探查为第二条信息通道** —— 已定案。Source: `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md`。
- **危险度 = eventOptions 上精确标注敌人等级（否决模糊档位）；等级差因此可见** —— 已定案。Source: `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。
- **引入 battlefield（战场）及 BattlefieldManager / StackManager；触发载体开放；道念下限 0 逐次结算截断；满手抽不进** —— 已定案。Source: `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md`。
- **卡牌类型六分 + 异能三分 + 永久物 + 次类型体系；触发条件可跨归属方（埋伏成立）；意图 = 快照而非承诺；敌人同样持有 item 与 power 且道具计入意图** —— 已定案。Source: `handoffs/2026-08-04b-mtg-loanwords-card-types-and-intent-snapshot.md`。
- **敌人赋级的合法区间 = 相对角色等级的 `±2` 带（取代按境界给的绝对上界，三章统一，三类战斗事件一视同仁，`±2` 为无例外的硬规则）；埋伏进入敌人卡池但不计入意图** —— 已定案。Source: `handoffs/2026-08-05-level-band-stack-save-and-token-free-deck.md` + `handoffs/2026-08-06d-combat-open-questions-mass-closure.md`。
- **意图三档阈值整体收紧一级、三档在带内全部可达；意图类别枚举 = `Offense / Defense / Buff / Special`（内容侧静态标注 + 20% 贡献阈值选主类别）；遭遇参数（回合数 / `VictoryRule`）落 `EncounterSpec`；enemies 升格为 `systems/enemies/`** —— 已定案。Source: `handoffs/2026-08-06d-combat-open-questions-mass-closure.md`。
- **Combat 为分类法第二类** → `decisions/ADR-0002-adventure-event-taxonomy.md`。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **平局已定案：** 10 回合打满道念相等 → **只发基础奖励**、不扣 lifeTotal（`CombatOutcome.Draw`）。**Practice 档 `WinMargin = 0` 使 `Draw` 在该档永不可达**——干净的退化，呈现层需知晓。
- **卡牌产 / 削道念的量纲基准：** 一张牌该产多少、10 回合内一方总产出相对起始值的倍数——**它决定越级追分是否可能**；是否存在道念相关的状态与倍率亦未定。**已归 ch1 数值标杆专场。** → `systems/character-profile/deck/`、`systems/balance.md`。
- **效果关键字体系与目标规则（承重 · 需一次专门 handoff）：** 效果的原子操作清单与求值管线已定（见 `systems/character-profile/deck/`），但**关键字体系**（可复用的效果词汇表）与**目标规则**（谁可以指定谁、合法性的完整判据）仍是结构占位。→ `systems/adventure-event/common-properties.md`、`systems/character-profile/deck/common-properties.md`。
- **先后手由谁决定：** 「不设先后手抽牌差」已定案（本作不存在先手 tempo 优势，故无需补偿）；但**谁先手**本身依什么决定（固定角色先手？按等级？随机？）未定。→ `systems/services/combat-service.md`。
- **属性模型与战斗资源共存：** 隐藏属性（道心 / 煞气 / 寿元）与 mana / 道念 / lifeTotal 如何共存与推拉未定。→ `systems/services/plot-manager.md`、`systems/services/life-cycle-service.md`。
- **敌人 AI 的规划算法：** 「回合级一次性规划」与规划输入（卡组 + 战场 + 本场可用道具 + 对手埋伏计数）已定；具体算法、多回合行为倾向、难度旋钮落点未定义。→ `systems/enemies/`。
- **敌人平衡：** 敌人各等级的道念**产出**能力（起始值已由 `baseMomentum` 给定）、随境界 / 篇章缩放未定。→ `systems/balance.md`。
- **失败后果的其余部分：** 胜利奖励随道念差变厚已定；失败除扣 lifeTotal 外是否另有后果未定（**Finale 失败已定案 = 不另开终结通道**，见 `finale/_index.md`）。

## 对应
提炼至：`.claude/knowledge/systems/adventure-event/combat.md`（待建）
