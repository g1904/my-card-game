# scoring（道念 / momentum）

> **计分模型 = 道念（momentum）**，且道念**就是战斗的胜负判据**——不是独立于战斗之外的另一层。战斗内资源 = **mana（出牌）+ 道念（计分与胜负）**；lifeTotal 退到战斗外承接失败惩罚。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

### 道念 = 胜利点数 = 胜负判据（已定案）

- **道念（momentum）是计分用的胜利点数（victory point）。** 它是本作对「计分」这一空缺的回答：**计分不是战斗之外的一层结算，而就是战斗本身的胜负标尺**。Source: `10-handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。
- **胜负 = 道念高者胜（已定案）。** 战斗结束时比较双方道念，**高者胜**。战斗**不以任一方 lifeTotal 归零为终止 / 判定条件**。Source: 同上。
- **战斗过程中 lifeTotal 不直接参与。** 回合内的一切焦点都在**积累道念 / 压制对方道念**上；lifeTotal 在战斗过程中既不被消耗也不被读取。Source: 同上。
- **失败惩罚 = 按道念差扣 lifeTotal（已定案）。** 战斗 / 修炼失败时，角色在**战斗结束的结算时刻**损失 lifeTotal，损失量由「**角色道念 − 敌人道念**」的差值决定（差得越多，伤得越重）。换算公式未定，见待决问题。Source: 同上。
- **胜利侧同样读道念差 → 奖励厚度（已定案）。** 赢多少也算数：**道念差越大，奖励越厚**（碾压 > 险胜）。**道念差因此是一个双向的结算刻度**——同一个量在胜负两侧分别驱动奖励厚度与惩罚深度，不需要第二套结算量。曲线归 `20-systems/balance.md`。Source: `10-handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。

```
战斗内：  mana（出牌资源，每回合恢复至 manaLimit）  +  道念（双方各一，计分与胜负）
          起始道念 = baseMomentum(自身等级)；由卡牌产出 / 削减对方；下限 0
              ↓ 固定 10 个回合（双方各 5）打满
结算：    道念高者胜 →  胜：奖励厚度 = g(角色道念 − 敌人道念)
                       平：只发基础奖励（差值 0 = 不加码的原点，不扣 lifeTotal）
                       负：lifeTotal -= f(敌人道念 − 角色道念)   ← 唯一动 lifeTotal 的时刻
战斗外：  lifeTotal = 角色生命值 / 失败惩罚承受量（见 20-systems/character-profile/life-total.md）
```

### 道念的规则骨架（已定案）

- **终止条件 = 固定 10 个回合。** 一场战斗**打满 10 个回合**，**双方各 5 个**（「回合」= 单方的一次行动轮，双方交替），结束时比道念、高者胜。**不设「先到某值即胜」的提前终止，也不以卡组耗尽终止。** 推论：战斗是**定长**的——TurnManager 是一个固定长度的循环而非动态终止判定，每场战斗的时间开销可预测，直接服务于篇章时长控制。Source: `10-handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。
- **平局 = 只发基础奖励。** 10 回合打满后道念相等时**不判负、不扣 lifeTotal**，只发该事件的**基础奖励**（无任何厚度加成）。这与「道念差是双向刻度」自洽：**差值 0 就是两侧都不加码的那个原点**——负侧的惩罚与胜侧的加厚都从这里向两边展开。落到类型上，`CombatOutcome` 需要 `Draw` 这一态。Source: 同上。
- **产出途径 = 卡牌。** 道念由打出的卡牌产生。Source: 同上。
- **可互相削减。** 卡牌既能给自己加道念，也能削减对方道念——道念是**可攻可守的双向标尺**，不是单向累加的计分器。Source: 同上。
- **下限 = 0。** 削减在 0 处截断，不存在负道念。Source: 同上。
- **起始道念 = `baseMomentum`（按自身全局等级）。** 战斗开始时双方各持一个由等级决定的起始道念（表见 `20-systems/balance.md`）。**推论（承重）：等级差直接变成起跑线差**——炼气十层（10）挑战筑基初期（20）= 开局落后 10 点，须在 10 个回合内追回。这与「敌人等级在 eventOptions 上精确标注」形成闭环：**看到等级，就等于看到起跑线**，越级挑战的风险由此可计算。Source: 同上。
- **节奏的落点。** mana 每回合刷满、道念不下 0、回合数固定——三者合起来把战斗定义为一场**限时积分对抗**：张力不在「谁先撑不住」，而在「10 个回合内谁攒得多、什么时候该转去压对方」。

### 为何是道念而非 chips × mult

- **不采用 Balatro 式 chips × mult 的「打分达标」结构。** 道念是**双方对抗的相对量**（比谁高），不是对抗一条静态阈值的绝对量——这保住了「敌人也出牌、双方对称」的既定参战方模型（见 `20-systems/services/combat-service.md`）。
- **也不是 StS 式纯 HP 消耗战。** 战斗内不存在被削减的血量池：mana 每回合刷满使资源曲线不承担节奏，道念的**累积与反超**成为回合间张力的主轴。

### 归属与协作

| 关注点 | 归属文档 |
|--------|---------|
| 道念的定义、胜负判据、与 lifeTotal 的关系（本文件） | `20-systems/scoring.md` |
| 战斗内道念的驱动（10 回合循环、双方道念状态、胜负判定实现） | `20-systems/services/combat-service.md` |
| 道念在战斗事件中的呈现（主视觉：双方道念对比） | `40-ux/combat-ux.md` |
| lifeTotal 作为战斗外耐久的语义 | `20-systems/character-profile/life-total.md` |
| `baseMomentum` 表、卡牌道念产出分档、道念差 → lifeTotal 损失 / 奖励厚度的系数 | `20-systems/balance.md` |
| 哪些卡牌产 / 削道念 | `20-systems/character-profile/deck/` |

## 决策(-> ADR)
> _已定案的决定链接到 50-decisions/ADR-####。_

- **计分模型 = 道念（momentum）；道念即战斗胜负判据；失败按道念差扣 lifeTotal** —— 已定案。**ADR 候选**。Source: `10-handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。
- **终止条件 = 固定 10 回合（双方各 5）；产出途径 = 卡牌、可互削、下限 0；起始道念 = `baseMomentum`；胜利侧按道念差给奖励厚度；平局只发基础奖励** —— 已定案。Source: `10-handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **卡牌产 / 削道念的量纲基准。** `baseMomentum` 给了起点，但「一张牌该产多少道念」「10 个回合内一方的总产出应达到起始值的几倍」这条基准未给——**它决定越级追分是否可能**。是否存在道念相关的状态与倍率亦未定。→ `20-systems/character-profile/deck/`、`20-systems/balance.md`。Source: 同上。
- **道念差 → lifeTotal 损失 / 奖励厚度的换算公式。** 线性？分档？带上下限？胜负两侧是同一条曲线的两端还是两套独立分档？→ `20-systems/balance.md`。Source: 同上。
- **Finale / Practice 的道念规则差异。** 二者是战斗变体、有独立胜负条件（见 `20-systems/adventure-event/finale/`、`practice/`）；**是否同为 10 回合**、如何改写道念判据（更高门槛？失败惩罚更轻？）未定。

## 对应
提炼至：`.claude/knowledge/systems/scoring.md`
