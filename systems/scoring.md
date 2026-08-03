# scoring（道念 / momentum）

> **计分模型 = 道念（momentum）**，且道念**就是战斗的胜负判据**——不是独立于战斗之外的另一层。战斗内资源 = **mana（出牌）+ 道念（计分与胜负）**；lifeTotal 退到战斗外承接失败惩罚。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

### 道念 = 胜利点数 = 胜负判据（已定案）

- **道念（momentum）是计分用的胜利点数（victory point）。** 它是本作对「计分」这一空缺的回答：**计分不是战斗之外的一层结算，而就是战斗本身的胜负标尺**。Source: `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。
- **胜负 = 道念高者胜（已定案）。** 战斗结束时比较双方道念，**高者胜**。战斗**不以任一方 lifeTotal 归零为终止 / 判定条件**。Source: 同上。
- **战斗过程中 lifeTotal 不直接参与。** 回合内的一切焦点都在**积累道念 / 压制对方道念**上；lifeTotal 在战斗过程中既不被消耗也不被读取。Source: 同上。
- **失败惩罚 = 按道念差扣 lifeTotal（已定案）。** 战斗 / 修炼失败时，角色在**战斗结束的结算时刻**损失 lifeTotal，损失量由「**角色道念 − 敌人道念**」的差值决定（差得越多，伤得越重）。Source: 同上。
- **换算 = 1:1（已定案 · 负侧）。** 道念差**就是** lifeTotal 的损失量：`lifeTotal -= (敌人道念 − 角色道念)`——不是线性系数、不是分档表，中间**不隔一层映射**。**推论：道念差成为一把真正的通用刻度**——战斗屏上的「我落后 8 点」同时就是「输了要掉 8 点 lifeTotal」，账当场可算，无需额外教学。**不设上限截断（已定案）：** 1:1 就是全部规则，不加封顶、不加分档。**「一次惨败打穿耐久」由内容设计侧规避**——遭遇编排不会给出会导致该结果的等级差，故规则层无需为此加护栏。**推论：内容侧因此背上一条硬约束**——`EnemyTemplate` 的物化赋级必须把「最坏情况下的道念差」控制在当前 `lifeTotal` 可承受的范围内，这条约束落在 future-event-service 的赋级规则上。Source: `handoffs/2026-08-02-momentum-conversion-reward-structure-and-mtg-stack.md`。
- **胜利侧同样读道念差 → 奖励厚度（已定案）。** 赢多少也算数：**道念差越大，奖励越厚**（碾压 > 险胜）。**道念差因此是一个双向的结算刻度**——同一个量在胜负两侧分别驱动奖励厚度与惩罚深度，不需要第二套结算量。**负侧已定为 1:1；胜侧是否同为 1:1 未定**，曲线归 `systems/balance.md`。Source: `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md` + `handoffs/2026-08-02-momentum-conversion-reward-structure-and-mtg-stack.md`。
- **`momentum` 的字段形态 = 非负整数（已定案）。** `>= 0` 的 Integer——下限 0 在类型层面即已表达，不引入小数、不引入负值。**推论：削减是饱和减法**，削到 0 即止、多余量不结转，故若要如实呈现「本次削了多少」，需区分**意图削减量**与**实际削减量**。Source: `handoffs/2026-08-02-momentum-conversion-reward-structure-and-mtg-stack.md`。

```
战斗内：  mana（出牌资源，每回合恢复至 manaLimit）  +  道念（双方各一，计分与胜负）
          起始道念 = baseMomentum(自身等级)；由卡牌产出 / 削减对方；下限 0
              ↓ 固定 10 个回合（双方各 5）打满
结算：    道念高者胜 →  胜：baseReward + 按道念差加厚（曲线待定）
                       平：只发 baseReward（差值 0 = 不加码的原点，不扣 lifeTotal）
                       负：baseReward（少数事件夹带负向条目）
                           且 lifeTotal -= (敌人道念 − 角色道念)  ← 1:1，唯一动 lifeTotal 的时刻
战斗外：  lifeTotal = 角色生命值 / 失败惩罚承受量（见 systems/character-profile/life-total.md）
```

### 道念的规则骨架（已定案）

- **终止条件 = 固定 10 个回合。** 一场战斗**打满 10 个回合**，**双方各 5 个**（「回合」= 单方的一次行动轮，双方交替），结束时比道念、高者胜。**不设「先到某值即胜」的提前终止，也不以卡组耗尽终止。** 推论：战斗是**定长**的——TurnManager 是一个固定长度的循环而非动态终止判定，每场战斗的时间开销可预测，直接服务于篇章时长控制。Source: `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。
- **平局 = 只发基础奖励。** 10 回合打满后道念相等时**不判负、不扣 lifeTotal**，只发该事件的**基础奖励**（无任何厚度加成）。这与「道念差是双向刻度」自洽：**差值 0 就是两侧都不加码的那个原点**——负侧的惩罚与胜侧的加厚都从这里向两边展开。落到类型上，`CombatOutcome` 需要 `Draw` 这一态。Source: 同上。
- **产出途径 = 卡牌。** 道念由打出的卡牌产生。Source: 同上。
- **可互相削减。** 卡牌既能给自己加道念，也能削减对方道念——道念是**可攻可守的双向标尺**，不是单向累加的计分器。Source: 同上。
- **下限 = 0，且截断发生在每一次结算时（已定案 · 08-03）。** 削减在 0 处截断，不存在负道念；多个效果同时在栈上时，饱和减法**逐次截断**，**不是**全栈结算完后再统一截断。**推论 ①：更保护落后方，且差异是可算的**——对方道念 5、栈上有「削 8」与「+3」：逐次截断 → `5-8 → 0`，再 `+3 → 3`；全栈后截断 → `5-8+3 = 0`。**溢出的削减量不结转**，故落后方不会被一次连锁按死在 0 上。**推论 ②：LIFO 顺序对最终结果有实际影响**——削减与产出交错时结算顺序改变结果，这把「栈序是卡牌设计可利用的资源」从原则变成了具体的算术。**推论 ③：`PlayResult` 必须携带本次的实际削减量**——截断在每次结算发生，故每次结算都是可观测事件，「意图削减量 vs 实际削减量」的差在连锁中必然出现。Source: 同上 + `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md`。
- **起始道念 = `baseMomentum`（按自身全局等级）。** 战斗开始时双方各持一个由等级决定的起始道念（表见 `systems/balance.md`）。**推论（承重）：等级差直接变成起跑线差**——炼气十层（10）挑战筑基初期（20）= 开局落后 10 点，须在 10 个回合内追回。这与「敌人等级在 eventOptions 上精确标注」形成闭环：**看到等级，就等于看到起跑线**，越级挑战的风险由此可计算。Source: 同上。
- **节奏的落点。** mana 每回合刷满、道念不下 0、回合数固定——三者合起来把战斗定义为一场**限时积分对抗**：张力不在「谁先撑不住」，而在「10 个回合内谁攒得多、什么时候该转去压对方」。

### 三档结算产物（已定案）

| 结果 | lifeTotal | 奖励 |
|------|-----------|------|
| **胜** | 不变 | `baseReward` + 按道念差加厚（碾压 > 险胜） |
| **平**（道念相等） | 不变 | 只发 `baseReward`，无任何厚度加成 |
| **负** | `-= (敌人道念 − 角色道念)`（1:1） | `baseReward`；**少数事件另夹带负向条目** |

- **输了通常只有 `baseReward`。** 失败不是零产出——与「失败侧首次有产出」（EnemyCodex 遭遇即记、道统残卷累积、等级产出也可能来自失败）一脉相承。Source: `handoffs/2026-08-02-momentum-conversion-reward-structure-and-mtg-stack.md`。
- **额外惩罚**包在 reward 里**，不另立结构。** 少数事件的失败会附带额外惩罚，它就是**奖励结构中的负向条目**。**推论：与 `ProfileChangeSpec` 的带符号约定天然自洽**（`ChangeElement.BaseValue` 负 = 消耗、正 = 产出），故「奖励里夹一条惩罚」不需要任何新类型，仍是同一份 `CombatResult.Spoils`、同一次 `TryApply`。Source: 同上。
- **奖励的计算归 combat-service，施加仍归 life-cycle-service。** 见 `systems/services/combat-service.md`。

### 战斗变体：10 回合与「道念高者胜」是 Combat 档的标准值（已定案）

- **Practice / Combat / Finale = Balatro 的 small / big / boss blind 三档对位。** 借的是它的**难度分档结构**，不是计分结构（chips × mult 仍被否决）。Source: `handoffs/2026-08-02-momentum-conversion-reward-structure-and-mtg-stack.md`。
- **标准 Combat = 10 个回合、以道念差判胜负**；**Practice 与 Finale 的回合数与胜负条件均可被改写**（Practice 更简单、Finale 更难）。**推论 ①：回合数不是常量而是遭遇参数**——TurnManager 仍是定长循环，长度来自这一场遭遇的配置。**推论 ②：胜负条件是可替换的判据**，Combat 档的判据即「道念高者胜、相等为平局」。Source: 同上。

### 为何是道念而非 chips × mult

- **不采用 Balatro 式 chips × mult 的「打分达标」结构。** 道念是**双方对抗的相对量**（比谁高），不是对抗一条静态阈值的绝对量——这保住了「敌人也出牌、双方对称」的既定参战方模型（见 `systems/services/combat-service.md`）。
- **也不是 StS 式纯 HP 消耗战。** 战斗内不存在被削减的血量池：mana 每回合刷满使资源曲线不承担节奏，道念的**累积与反超**成为回合间张力的主轴。

### 归属与协作

| 关注点 | 归属文档 |
|--------|---------|
| 道念的定义、胜负判据、与 lifeTotal 的关系（本文件） | `systems/scoring.md` |
| 战斗内道念的驱动（10 回合循环、双方道念状态、胜负判定实现） | `systems/services/combat-service.md` |
| 道念在战斗事件中的呈现（主视觉：双方道念对比） | `ux/combat-ux.md` |
| lifeTotal 作为战斗外耐久的语义 | `systems/character-profile/life-total.md` |
| `baseMomentum` 表、卡牌道念产出分档、道念差 → lifeTotal 损失 / 奖励厚度的系数 | `systems/balance.md` |
| 哪些卡牌产 / 削道念 | `systems/character-profile/deck/` |

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- **计分模型 = 道念（momentum）；道念即战斗胜负判据；失败按道念差扣 lifeTotal** —— 已定案。**ADR 候选**。Source: `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。
- **终止条件 = 固定 10 回合（双方各 5）；产出途径 = 卡牌、可互削、下限 0；起始道念 = `baseMomentum`；胜利侧按道念差给奖励厚度；平局只发基础奖励** —— 已定案。Source: `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。
- **道念差 → lifeTotal 损失 = 1:1；`momentum` = 非负整数；失败仍发 `baseReward`、额外惩罚以负向条目包在 reward 内；Practice / Combat / Finale 的回合数与胜负条件按 blind 三档可变** —— 已定案。Source: `handoffs/2026-08-02-momentum-conversion-reward-structure-and-mtg-stack.md`。
- **下限 0 的截断时机 = 每一次结算时截断**（溢出量不结转，LIFO 顺序因此影响最终结果） —— 已定案。Source: `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md`。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **胜利侧的「道念差 → 奖励厚度」是否也 1:1。** 负侧已定；胜侧仍是定性表述。若也 1:1，「1 点道念差」在奖励侧等于什么单位（灵玉？候选项数量？某个权重）未定。→ `systems/balance.md`。Source: 同上。
- **Practice / Finale 的具体改写值。** 「回合数与胜负条件可变、一简一难」已定方向；Practice 是更少回合（更快）还是更多回合（更宽容）、Finale 的额外门槛取什么形式，均未给。→ `systems/adventure-event/practice/`、`finale/`。Source: 同上。
- **卡牌产 / 削道念的量纲基准（已归属专场）。** 「一张牌该产多少」「10 个回合内总产出应达起始值的几倍」——**明确推迟到内容横向扩展阶段的「ch1 数值模型」session**，切入点是起始角色 starter deck 的设计。→ `systems/character-profile/deck/`、`systems/balance.md`。Source: 同上。

## 对应
提炼至：`.claude/knowledge/systems/scoring.md`
