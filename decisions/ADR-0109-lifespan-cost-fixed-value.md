# ADR-0109 — `lifeSpanCost` 恒为非负整数定值：不带区间、不带公式，变异位共三个且无一新增

- **状态：** Accepted
- **日期：** 2026-08-17
- **来源：** handoffs/2026-08-17i-event-option-materialized-fields.md · answer-logs/log-event-option-materialized-fields.md · answer-logs/log-0823.md

## 背景

`lifeSpanCost` 是事件的选择成本，也是篇章目标时长的主旋钮。它的数据形态未定：可以是一个定值，也可以是一个区间（每次掷一个），或者一条依局面求值的公式。

## 决策

**形态 = 一个非负整数定值，不带区间、不带公式。** 模板侧不填则取定价表「事件类型 × 篇章」那一格；可填偏移或更小的覆盖值（Explore 禁填）；物化时取负填入 `ChangeElement.BaseValue`，`SelectCost` 内因此是一个**已定稿的单一负值**。

**变异位共三个且无一新增**：定价表按类型 × 篇章分格 · 条目级偏移 / 覆盖 · `ModifierKey.LifeSpanCost`。

逐条语义、定价表形态与三条理由 → `systems/adventure-event/common-properties.md`、`systems/balance.md`。

## 理由

两条既有设计各自独立地否掉区间与公式：

- **它是时长旋钮，而区间损害反推精度。** 目标时长（30–40 / 35–45 / 45–55 分钟）反推定价是一个算术问题，区间会把它变成期望值加方差，而旋钮精度正是定价表存在的唯一理由。
- **公式撞上「内容侧不落裸数字」范式**，且运行期变异已有 `ModifierKey.LifeSpanCost` 一条通道，不需要第二条。

## 备选方案

- **区间旋钮（每次掷一个）** — 否决：损害反推精度。**`selectCost` 恒精确展示后这条反而更强**——区间会让同一个事件类型在不同批次报出不同价码，玩家看得见却读不出规律，而定价表存在的唯一理由正是旋钮精度。
- **依局面求值的公式** — 否决：与内容侧不落裸数字的范式冲突，且运行期变异通道已存在。

## 后果

- `systems/adventure-event/common-properties.md` 是形态的权威；`systems/balance.md` 承载定价表本体，**继续不设区间列**。
- 三个变异位是封闭的：新增第四个变异位需要重开本条。
- 定价表逐格取值仍待定，且被「目标时长反推」阻塞——这是取值面的欠账，不影响本条的形态结论。
- 寿元回复只走产出侧、`selectCost` 内 `LifeSpan` 收紧为非负 → `ADR-0066`。
