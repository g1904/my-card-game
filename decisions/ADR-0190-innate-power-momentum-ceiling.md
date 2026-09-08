# ADR-0190 — 神通的战斗内强度闸门 = 单条道念净贡献 ≤ 25% × `baseMomentum`，不设合计总闸

- **状态：** Accepted
- **日期：** 2026-09-07
- **来源：** handoffs/2026-09-07-combat-scale-baseline.md · answer-logs/log-combat-scale-baseline.md

## 背景

神通「显著强于法则」此前只有定性表述，缺一把可讨论的量纲；而它同时被指派为 ch3 越阶追分的承担面（`decisions/ADR-0187-chapter-three-overlevel-catchup-carrier.md`），必须先有上沿。

## 决策

**单条神通的战斗内道念净贡献 ≤ 本方 `baseMomentum` 的 25%（初值）**，显著高于法则的 10%。

**读法：单条神通的上沿 ≈ 老账号全部法则合计的上沿。**折成摆幅 = ch1 2.5 点（摆幅 9%）· ch3 16 点（摆幅 28%）。

**不设合计总闸。**该闸是评审参考上沿、不可机械校验，落纪律阶梯第 4 级。

## 理由

`systems/balance.md`：法则那道 25% 的第二闸是为「跨轮回单调累积 + 不可被针对」设的，**神通三条前提都不成立**——再压一道合计闸只是把一个不存在的失控路径写进文档。

## 备选方案

- 为神通补一道合计总闸 — 否决：理由如上。

## 后果

- 约束内容评审：单条神通的效果量按此上沿核对。
- **明写与另两格的咬合仍未解开**（相对同 `ManaCost` 法术的效果量系数、各 `RarityTier` 的条目数），留待 starter deck 铺开后一并标定。
- 与 `decisions/ADR-0153-character-power-strength-ceiling.md` 同层：本条给出 25% 这个刻度值，那条给出「取 `baseMomentum` 比例刻度、不设合计总闸」的形态。
