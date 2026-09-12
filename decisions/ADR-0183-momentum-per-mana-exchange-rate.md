# ADR-0183 — 战斗量纲基准取 `momentumPerMana = 1`：产与削共用同一把刻度

- **状态：** Accepted
- **日期：** 2026-09-07
- **来源：** handoffs/2026-09-07-combat-scale-baseline.md · answer-logs/log-combat-scale-baseline.md

## 背景

卡牌产 / 削道念此前只有定性描述，没有任何可复算的量纲。缺这把刻度，`EncounterTighten` 两格牌流量的四个界常量、`EnemyManaLimit` 的校验、`RarityTier` 的分布权重、AI 兜底权重与 starter deck 全部无法落笔——它们是同一个未知的五个面。

## 决策

**取 `momentumPerMana = 1`：在该篇章的基准层数上，1 点 mana ≈ 1 点道念，产出侧与削减侧共用同一把刻度**（削减侧受下限 0 截断）。

摆幅口径取 `P(篇章) ≈ 0.9 × 5 × manaLimit`，据此篇章末摆幅 29 / 40 / 52，`P / baseMomentum` = 1.9 / 1.3 / 0.7。

**这组值与 `E[道念差]` 同级：是可复算的初值，不是设计结论。**逐格取值与三张台账的权威在 `systems/balance.md`。

## 理由

`k = 2` 时典型道念差应为 10 而非既定的 5 ⇒ **`k = 1` 是唯一让 `E[道念差]` 台账成立的取值**（`systems/balance.md`）。它同时是可心算的：3 费牌 ≈ 3 点道念，玩家不必记第二张换算表。

## 备选方案

- `momentumPerMana = 2` — 否决：与既定的 `E[道念差]` = 5 台账不自洽。
- 除此之外未权衡其他方案。

## 后果

- 全部卡牌效果量的编排从此有共同基准；放弃了「凭手感给数字」。
- **它自标为标定假设、不得被引为承重依据**——实测改写 `E[道念差]` 时，本组值按同一式子整体重算。
- 约束 `systems/character-profile/deck/_index.md` · `systems/scoring.md` · `systems/character-profile/power/_index.md`（闸门折算）· `systems/enemies/_index.md`（敌方摆幅）逐处按同一刻度表述。
