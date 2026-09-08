# ADR-0188 — 道念两格首批只编排加法层；乘法层留给费用 / 抽牌 / 疲劳三格

- **状态：** Accepted
- **日期：** 2026-09-07
- **来源：** handoffs/2026-09-07-combat-scale-baseline.md · answer-logs/log-combat-scale-baseline.md

## 背景

`ModifierTarget` 的机制层已由 `decisions/ADR-0115-ability-effect-primitive-grammar.md` 与 `decisions/ADR-0116-capability-flag-and-modifier-shape.md` 完整定案，但内容侧能不能用乘区去改道念从未表态。它直接决定追分锚点能否对账。

## 决策

**首批内容侧只编排加法层的道念修正**：`StaticModifierData{ Layer = Additive, What = MomentumProduced | MomentumReduced }` 启用；**乘法层首批不作用于 `MomentumProduced` / `MomentumReduced`**，保留给 `CardManaCost` / `DrawCount` / `FatigueAmount` 三格。

**这是编排口径，不是字段约束**——字段已在，只是内容侧不填；核对落 `/audit-content` 汇总，只报告不阻断。

## 理由

`systems/character-profile/deck/_index.md`：乘区会让同一副卡组在不同手牌序列下摆幅相差数档，**锚点从此无法对账**，法则 10% / 神通 25% 两道以 `baseMomentum` 计的闸门也失去可事前估算性。

## 备选方案

- **焊进加载期校验** — 否决：焊进加载期只会让日后放开时撞一次 `PushError`；日后要开是纯加法。

## 后果

- 约束了首批卡牌的表达面：写不出「道念翻倍」一类效果。
- 放弃了乘区的设计空间，换取锚点的可对账性。
- 三格保留的乘法层不受本条约束。
