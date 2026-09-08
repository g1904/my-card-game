# ADR-0184 — 卡牌费用曲线随境界整体上移；牌流三值 4 / 2 / 7 三章同形

- **状态：** Accepted
- **日期：** 2026-09-07
- **来源：** handoffs/2026-09-07-combat-scale-baseline.md · answer-logs/log-combat-scale-baseline.md

## 背景

`manaLimit` 自第二篇章中段起溢出牌流上界：手上没有那么多牌可打，两条成长通道在轮回的后三分之二同时失效。要么上调费用曲线，要么逐章收紧牌流——两个旋钮只能动一个。

## 决策

**令平均费用随境界整体上移：`avgManaCost(c) = round(5 × manaLimit(c) / 14)` = 2 / 3 / 4**（费用带众数 ch1 1–2 · ch2 2–4 · ch3 3–5）。

据此**牌流三值维持起手 4 / 每回合抽 2 / 手牌上限 7、三章同形**，`RealmBreakthroughManaBonus` 维持 1。逐格复算见 `systems/character-profile/mana.md` 与 `systems/balance.md`。

## 理由

费用曲线同步上移使每一档 `manaLimit` 的实际购买力逐章递减（ch1 +0.5 张 / 回合、ch2 +0.33、ch3 +0.25），**「一章净增 +1~+2」这条预算因此不变**（`systems/character-profile/mana.md`）。

牌流侧的复算：平均费用 2 下稳态手牌 = 4（抽 2 出 2），**连续两个回合出牌不足才撞 7** ⇒ 紧但不是每场都咬（`systems/balance.md`）。

## 备选方案

- **费用曲线不上移、改为逐章收紧牌流**（ch3 每回合抽 1 或手牌上限 5）— 否决：与「牌流上界三章同形」冲突，且 4 / 2 / 7 的三条依据全部失效，等于用未论证的三元组换掉已论证的三元组。
- `RealmBreakthroughManaBonus` 上调至 2 — 否决：会让境界跃升变成 `manaLimit` 的主通道，与既定分工冲突。

## 后果

- 费用曲线与 4 / 2 / 7 从此**内耦合**：否掉其一必须重算其二。
- 三章末的 mana 预算全部落在「恰好饱和」；放弃了「后两章 mana 溢出是已知代价」这段旧表述。
- `decisions/ADR-0035-mana-no-curve-model.md` 后果段把费用曲线列为待决的那句已不成立，本决策即其答案。
