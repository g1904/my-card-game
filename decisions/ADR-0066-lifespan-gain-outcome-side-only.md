# ADR-0066 — 寿元回复只走产出侧：`selectCost` 内 `LifeSpan` 取值域收紧为非负；护栏用三道软闸，不设硬上限

- **状态：** Accepted
- **日期：** 2026-08-17
- **来源：** handoffs/2026-08-17f-lifespan-restoration-paths.md

## 背景

`selectCost` 与 outcome 侧共用 `ProfileChangeSpec`，因此技术上「成本为负 = 回复」是可表达的。若允许，一个事件就能写成「选择这一项，倒赚 20 寿元」。

而寿元回复一旦存在，就需要总量护栏——否则正反馈成立：回寿事件 ⇒ 更多事件 ⇒ 更多回寿事件。

## 决策

**`selectCost` 内的 `LifeSpan` 恒为消耗向：取值域收紧为非负（承重）。寿元回复只能落在 outcome / reward 侧。**

回寿数字与 `selectCost` **共用寿元 Band 2 那一个开关**（Band 0 / Band 1 均不显示）。

**平衡护栏 = 三道软闸 + 一条结构性禁令，不设硬上限。**

三道软闸与禁令 → `systems/adventure-event/common-properties.md`；数值 → `systems/balance.md`；回寿法宝 → `systems/character-profile/item/_index.md`。

## 理由

成本侧回寿会把「支付后判定」从**压力点**变成**救命点**——玩家看到高成本反而想选。这悄悄取消了「明知是死路仍然走」这条承重取向（→ `ADR-0031`）。

硬上限（每篇章回寿总量不超过 N）被否是因为它需要**新存档字段 + 新校验**，而三道软闸已经掐死正反馈：回寿事件本身要付出别的代价，且它们的出现频率受编排约束。

## 备选方案

- **成本侧允许回寿** — 否决：把压力点变成救命点。
- **每篇章回寿总量硬上限** — 否决：需新存档字段与新校验，软闸已足。

## 后果

- 加载期校验 9 拒绝 `selectCost` 内出现 `Stat == LifeSpan` 的负值。
- 回寿法宝的总量护栏后来因储物袋取消容量上限而少了一道软闸，护栏落到内容编排面（→ `ADR-0097`）。
- 两道加载期校验保留：`Scope == Player` 且产出 `LifeSpan` → 拒；`LifeSpan` 产出 + `UsableScene` 含 `InCombat` → 拒。
