# ADR-0187 — ch3 的越阶追分不由卡组承担，改由神通 / 战斗内法则 / 道具三者承担

- **状态：** Accepted
- **日期：** 2026-09-07
- **来源：** handoffs/2026-09-07-combat-scale-baseline.md · answer-logs/log-combat-scale-baseline.md

## 背景

`MaxTier` 上界 5 与每层 +20% 的算术后果是：第三篇章追平一次越阶需要约 3.4 档层数，而余量只剩 1 档。谁来补那最坏 35 点的落差，必须当场表态。

## 决策

**接受「在第三篇章，光靠卡组追不平一次越阶」**，把 ch3 的越阶追分改由三者承担：**神通**（单条上沿 25% × `baseMomentum` ≈ 16 点）· **战斗内法则**（老账号合计 25% ≈ 16 点）· **道具**。

**`baseMomentum` 表、`±2` 赋级带、`MaxTier` 上界 5 三者均不为此改动。**

## 理由

`systems/balance.md`：依据是**难度曲线按老账号全开校准，而非新账号裸奔**；上调产出面或放宽带宽都要动一条已完整定案的曲线，且会连带重算 `lossPerMomentum` 的 ch3 系数、`advantage` 三档分布与 λ 反推式。

## 备选方案

- 上调每层替换幅度 — 否决：动一条已完整定案的曲线。
- 放宽 `±2` 赋级带（`decisions/ADR-0044-enemy-leveling-band.md`）— 否决：同上。
- 抬高 `MaxTier` 上界 — 否决：同上。

## 后果

- 改写了「越阶追分能力应随篇章保持可达」这一未言明的期待：越阶在 ch1 是「卡组打得好就能赢」，在 ch3 是「你这一轮回攒了什么」。
- **代价明写并被接受：老账号与新账号在 ch3 的越阶能力显著分化。**
- 约束 `systems/character-profile/power/_index.md` · `systems/player-profile/player-power/_index.md` · `systems/character-profile/item/_index.md` 三份把「ch3 越阶追分的承担面」写进各自的定位段。
