# scoring（道念 / momentum）

> **计分模型 = 道念（momentum）**，且道念**就是战斗的胜负判据**——不是独立于战斗之外的另一层。战斗内资源 = **mana（出牌）+ 道念（计分与胜负）**；寿元退到战斗外承接失败惩罚。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

### 道念 = 胜利点数 = 胜负判据

- **道念（momentum）是计分用的胜利点数（victory point）。** 它是本作对「计分」这一空缺的回答：**计分不是战斗之外的一层结算，而就是战斗本身的胜负标尺**。
- **胜负 = 道念高者胜。** 战斗结束时比较双方道念，**高者胜**。战斗**不以任一方的任何资源池归零为终止 / 判定条件**。
- **战斗过程中寿元不被读写（资源纪律 · 承重）。** 回合内的一切焦点都在**积累道念 / 压制对方道念**上；寿元在战斗过程中既不被消耗也不被读取，**只在收口时刻被扣**。理由：战斗内一旦能读写这条命，以生命值为终止条件的消耗战就从后门回来，而本作的战斗终止条件是道念比拼。故战斗内可用的道具与法则不得产出 `LifeSpan`（见 `systems/character-profile/life-span.md`）。
- **失败惩罚 = 按道念差扣寿元。** 战斗 / 修炼失败时，角色在**战斗结束的**收口**时刻**损失寿元，损失量由「**角色道念 − 敌人道念**」的差值决定（差得越多，伤得越重）。**它与事件成本 `lifeSpanCost` 落在同一个值上**——一次战斗失败因此同时压缩「还能失败几次」与「本章还能做几个事件」。
- **换算 = 道念差 × `lossPerMomentum`（负侧）。** `lifeSpan -= (敌人道念 − 角色道念) × lossPerMomentum(篇章)`——**第一篇章的系数锁定为 10**，战斗屏上的「我落后 8 点」同时就是「输了要掉 80 点寿元」——一次乘 10，账当场折得出来，不需要额外教学；后两章由系数吸收 `baseMomentum` 的量纲膨胀（`baseMomentum` 约百倍膨胀而预算只有三倍），玩家在一个篇章之内看到的始终是同一个系数。**代价如实写下：可算性是 ×10 而不是逐点对应**，比 1:1 多一步心算，这一步是为寿元定价表的分辨率付出的对价。**系数按篇章分档、不按 `combatTier` 分档**：三档共用同一系数，故同一时刻不存在两套账本。**不设上限截断：** 换算就是全部规则，不加封顶。表、ch1 = 10 的锚与 ch2 / ch3 的形状锚见 `systems/balance.md`。
- **道念差因此仍是一把通用刻度，且现在跨事件类型可比价。** 被扣的是角色唯一的那条命，故「打一场输了」与「多走三到五个事件」第一次落在同一把尺子上。
- **胜利侧同样读道念差 → 奖励厚度。** 赢多少也算数：**道念差越大，奖励越厚**（碾压 > 险胜）。**道念差因此是一个双向的结算刻度**——同一个量在胜负两侧分别驱动奖励厚度与惩罚深度，不需要第二套结算量。**负侧 = 道念差 × 篇章系数；胜侧 = 两条支路**——**强制奖励（可数量）走线性 `1:1 × 可调单价`**（「1 点道念差 = 1 个 `rewardPerMomentum` 单位」，单价逐篇章下调以吸收 `baseMomentum` 的百倍量纲膨胀），**可选奖励（品质）走归一化 `advantage` 三档**（险胜 / 优胜 / 碾压，只改候选池的稀有度权重、不改数量）。**道念差因此有两个消费点，调平衡时须同时看。** 公式、单价表与门槛见 `systems/balance.md`。
- **`momentum` 的字段形态 = 非负整数。** `>= 0` 的 Integer——下限 0 在类型层面即已表达，不引入小数、不引入负值。**推论：削减是饱和减法**，削到 0 即止、多余量不结转，故若要如实呈现「本次削了多少」，需区分**意图削减量**与**实际削减量**。

```
战斗内：  mana（出牌资源，每回合恢复至 manaLimit）  +  道念（双方各一，计分与胜负）
          起始道念 = baseMomentum(自身等级)；由卡牌产出 / 削减对方；下限 0
          第二条削减通道 = 疲劳：抽牌堆已空时每抽一张 −1（不重洗）
              ↓ 固定 10 个回合（双方各 5）打满
结算：    道念高者胜 →  胜：baseReward + 按道念差加厚（曲线待定）
                       平：只发 baseReward（差值 0 = 不加码的原点，不扣寿元）
                       负：baseReward（少数事件夹带负向条目）
                           且 lifeSpan -= (敌人道念 − 角色道念) × lossPerMomentum(篇章)
                                          ← ch1 系数 = 10；唯一动寿元的战斗内时刻是收口
战斗外：  lifeSpan = 角色唯一的资源命线（见 systems/character-profile/life-span.md）
```

### 道念的规则骨架

- **终止条件 = 固定 10 个回合。** 一场战斗**打满 10 个回合**，**双方各 5 个**（「回合」= 单方的一次行动轮，双方交替），结束时比道念、高者胜。**不设「先到某值即胜」的提前终止，也不以卡组耗尽终止。** 推论：战斗是**定长**的——TurnManager 是一个固定长度的循环而非动态终止判定，每场战斗的时间开销可预测，直接服务于篇章时长控制。
- **平局 = 只发基础奖励。** `Standard` 档打满 10 回合后道念相等时**不判负、不扣寿元**，只发该事件的**基础奖励**（无任何厚度加成）。这与「道念差是双向刻度」自洽：**差值 0 就是两侧都不加码的那个原点**——负侧的惩罚与胜侧的加厚都从这里向两边展开。落到类型上，`CombatOutcome` 需要 `Draw` 这一态。**它只在 `Standard` 一档可达**：另两档「相等即判胜」，那里没有平局这个中间态。
- **产出途径 = 卡牌。** 道念由打出的卡牌产生。
- **削减有两条通道：卡牌与疲劳。** 除卡牌之外，**抽牌堆为空时每尝试抽一张牌，抽牌方失去 1 点道念**（一次抽 N 张即失去 N 点）——**抽牌堆不重洗、弃牌堆不回流**，故卡组是一场战斗内会被真正耗尽的资源。**疲劳以一条栈条目结算**，与触发式异能同形——可被监听、可被响应、可被削减至 0；它**不产生 `ActionResult`**（它不是玩家动作），与卡牌削减共用同一条「下限 0 逐次截断」规则。**推论 ①：卡组规模成为一条真实的构筑取舍**——牌少而精的代价是后期稳定失血，这也是「两侧卡组规模都不设硬限」得以成立的前提（见 `systems/balance.md`）。**推论 ②：不以卡组耗尽终止仍然成立**——耗尽不终止战斗，只是从此每回合失血；定长 10 回合的结构不变。**推论 ③：满手与疲劳互不触发**——抽牌堆非空但满手时牌留在抽牌堆、无事发生、不扣道念；疲劳的触发条件是「牌堆空」，不是「没拿到牌」。
- **可互相削减。** 卡牌既能给自己加道念，也能削减对方道念——道念是**可攻可守的双向标尺**，不是单向累加的计分器。
- **下限 = 0，且截断发生在每一次结算时。** 削减在 0 处截断，不存在负道念；多个效果同时在栈上时，饱和减法**逐次截断**，**不是**全栈结算完后再统一截断。**推论 ①：更保护落后方，且差异是可算的**——对方道念 5、栈上有「削 8」与「+3」：逐次截断 → `5-8 → 0`，再 `+3 → 3`；全栈后截断 → `5-8+3 = 0`。**溢出的削减量不结转**，故落后方不会被一次连锁按死在 0 上。**推论 ②：LIFO 顺序对最终结果有实际影响**——削减与产出交错时结算顺序改变结果，这把「栈序是卡牌设计可利用的资源」从原则变成了具体的算术。**推论 ③：每一次结算都必须携带本次的实际削减量**——截断在每次结算发生，故每次结算都是可观测事件，「意图削减量 vs 实际削减量」的差在连锁中必然出现。逐次结算的这一对值由 `CombatFeedEntry` 承载，玩家动作整条链路的汇总值由 `ActionResult` 承载（见 `systems/services/combat-service.md`）。
- **起始道念 = `baseMomentum`（按自身全局等级）。** 战斗开始时双方各持一个由等级决定的起始道念（表见 `systems/balance.md`）。**推论（承重）：等级差直接变成起跑线差**——炼气十层（10）挑战筑基初期（20）= 开局落后 10 点，须在 10 个回合内追回。这与「敌人等级在 eventOptions 上精确标注」形成闭环：**看到等级，就等于看到起跑线**，越级挑战的风险由此可计算。
- **节奏的落点。** mana 每回合刷满、道念不下 0、回合数固定——三者合起来把战斗定义为一场**限时积分对抗**：张力不在「谁先撑不住」，而在「10 个回合内谁攒得多、什么时候该转去压对方」。

### 三档结算产物

| 结果 | lifeSpan | 奖励 |
|------|----------|------|
| **胜** | 不变 | `baseReward` + 按道念差加厚（碾压 > 险胜） |
| **平**（道念相等） | 不变 | 只发 `baseReward`，无任何厚度加成 |
| **负** | `-= (敌人道念 − 角色道念) × lossPerMomentum(篇章)` | `baseReward`；**少数事件另夹带负向条目** |

- **战斗结算只会向下推这个值，永不向上。** 胜利不回升寿元；向上只由事件产出与道具承担（回复三通道见 `systems/character-profile/life-span.md`）。

- **本表只列结算侧的两列，失败代价不止于此。** 寿元扣减是失败的**一条**代价；完整代价面（含未获奖励的机会成本、寿元与时间成本、图鉴与经验的正向产出）逐条列在 `systems/adventure-event/combat/_index.md`，本处不复述。
- **输了通常只有 `baseReward`。** 失败不是零产出——与「失败侧首次有产出」一脉相承。**常规失败的产出面是两条：EnemyCodex 遭遇即记 + 失败仍给的经验**；**道统残卷的累积已收窄为 Finale 失败专属**，不再是普遍适用的失败侧产出。
- **额外惩罚**包在 reward 里**，不另立结构。** 少数事件的失败会附带额外惩罚，它就是**奖励结构中的负向条目**。**推论：与 `ProfileChangeSpec` 的带符号约定天然自洽**（`ChangeElement.BaseValue` 负 = 消耗、正 = 产出），故「奖励里夹一条惩罚」不需要任何新类型，仍是同一份 `CombatResult.Spoils`、同一次 `TryApply`。
- **奖励的计算归 combat-service，施加仍归 life-cycle-service。** 见 `systems/services/combat-service.md`。

### 遭遇档位：10 回合与「道念高者胜」是 `Standard` 档的取值

- **`combatTier { Practice, Standard, Finale }` = Balatro 的 small / big / boss blind 三档对位。** 借的是它的**难度分档结构**，不是计分结构（chips × mult 仍被否决）。
- **`Standard` 档 = 10 个回合、以道念差判胜负**；**`Practice` 与 `Finale` 档的回合数与胜负条件均可被改写**（前者放宽到「相等即胜」并缩短窗口，后者放宽到「不落后即通过」但把失败的后果推到顶——失败即角色终结）。**推论 ①：回合数不是常量而是遭遇参数**——TurnManager 仍是定长循环，长度来自这一场遭遇的配置。**推论 ②：胜负条件是可替换的判据**，`Standard` 档的判据即「道念高者胜、相等为平局」。

### 为何是道念而非 chips × mult

- **不采用 Balatro 式 chips × mult 的「打分达标」结构。** 道念是**双方对抗的相对量**（比谁高），不是对抗一条静态阈值的绝对量——这保住了「敌人也出牌、双方对称」的既定参战方模型（见 `systems/services/combat-service.md`）。
- **也不是 StS 式纯 HP 消耗战。** 战斗内不存在被削减的血量池：mana 每回合刷满使资源曲线不承担节奏，道念的**累积与反超**成为回合间张力的主轴。

### 归属与协作

| 关注点 | 归属文档 |
|--------|---------|
| 道念的定义、胜负判据、与寿元的关系（本文件） | `systems/scoring.md` |
| 战斗内道念的驱动（10 回合循环、双方道念状态、胜负判定实现） | `systems/services/combat-service.md` |
| 道念在战斗事件中的呈现（主视觉：双方道念对比） | `ux/combat-ux.md` |
| 寿元作为角色唯一资源命线的语义 | `systems/character-profile/life-span.md` |
| `baseMomentum` 表、卡牌道念产出分档、`lossPerMomentum` 与奖励厚度的系数 | `systems/balance.md` |
| 哪些卡牌产 / 削道念 | `systems/character-profile/deck/` |
| 隐藏属性（道心 / 煞气）与战斗层的边界 —— **战斗层不读写隐藏属性，交互全在事件层** | `systems/services/plot-manager.md` |

Source: `handoffs/2026-09-03-lifespan-cost-table-and-budget-scale.md` · `handoffs/2026-08-30-life-lifespan-merge.md` · `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md` · `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md` · `handoffs/2026-08-02-momentum-conversion-reward-structure-and-mtg-stack.md` · `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md` · `handoffs/2026-08-05-level-band-stack-save-and-token-free-deck.md` · `handoffs/2026-08-09b-player-power-fragment-finale-bound-drop-chance.md` · `handoffs/2026-08-11c-combat-turn-flow-fatigue-and-card-type-reduction.md` · `handoffs/2026-08-22-finale-failure-is-death.md` · `handoffs/2026-08-23g-hidden-stat-combat-boundary-event-backdrop-and-itemized-rewards.md`

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- **计分模型 = 道念（momentum）；道念即战斗胜负判据；失败按道念差扣寿元** → `decisions/ADR-0018-momentum-scoring-model.md`（Accepted）。
- **终止条件 = `EncounterSpec.TurnLimit`**（遭遇参数，**不是常量**——`Standard` 档取值为双方合计 10 回合）**；产出途径 = 卡牌、可互削、下限 0；起始道念 = `baseMomentum`；胜利侧按道念差给奖励厚度；平局只发基础奖励** → 同上 ADR-0018。
- **道念差 → 寿元损失 = 道念差 × `lossPerMomentum`（ch1 = 10）；`momentum` = 非负整数；失败仍发 `baseReward`、额外惩罚以负向条目包在 reward 内；`combatTier` 三档的回合数与胜负条件随档可变** → 同上 ADR-0018；`WinMargin` 在 `Finale` 退场亦见该 ADR。
- **下限 0 的截断时机 = 每一次结算时截断**（溢出量不结转，LIFO 顺序因此影响最终结果）→ `decisions/ADR-0086-lifo-resolution-and-combat-log.md`（Accepted）。
- **道念削减的第二条通道 = 疲劳**（抽牌堆不重洗；空堆时每抽一张 −1 道念，同受下限 0 截断）→ `decisions/ADR-0052-no-reshuffle-fatigue.md` · `decisions/ADR-0088-fatigue-as-stack-entry.md`（均 Accepted）。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **三档奖励厚薄的具体取值。** 遭遇参数（`Practice` 8 / `WinMargin 0`、`Standard` 10 / `WinMargin 1`、`Finale` 12 / `WinMargin 0`）；**`BaseReward` 与 `RewardPoolId` 随档位如何调厚薄**未给，留待内容扩充后的统计校准。→ `systems/adventure-event/combat/`、`systems/balance.md`。
- **卡牌产 / 削道念的量纲基准。** 「一张牌该产多少」「10 个回合内总产出应达起始值的几倍」——**明确推迟到内容横向扩展阶段**，留待内容扩充后的统计校准，切入点是起始角色 starter deck 的设计。→ `systems/character-profile/deck/`、`systems/balance.md`。

## 对应
提炼至：`.claude/knowledge/systems/scoring.md`
