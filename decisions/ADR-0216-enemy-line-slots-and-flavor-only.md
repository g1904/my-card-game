# ADR-0216 — 敌人台词进战斗屏、`LineSlot` 首批五成员；台词永不承载规则信息

- **状态：** Accepted
- **日期：** 2026-09-08
- **来源：** handoffs/2026-09-08-combat-ui-elements.md · handoffs/2026-09-08-combat-portrait-layout.md · answer-logs/log-combat-ui-elements.md

## 背景

`LineSlot` 是空枚举 ⇒ `Lines` 对任何条目都只能是空数组，整条内容通道被阻塞。`decisions/ADR-0120-content-artwork-and-enemy-lines.md` 定了字段落 `Lines`，但一个成员都没有。

## 决策

**敌人台词进战斗屏**，落点 = 敌人立绘**上方**的非常驻浮层气泡：**不进任何 `Container`**、约 1.5 s 淡出、不可点不可关闭、触控穿透、**与既有节拍并行、不新增等待节拍**。

**`LineSlot` 首批五成员**，全部落在既有可观测时刻上：`OnCombatStart` · `OnFirstEnemyTurn` · `OnEnemyMomentumLead`（一场至多一次）· `OnEnemyDefeat` · `OnCharacterDefeat`。新增成员一律追加末尾，**声明顺序不表达时间轴**。

**绝不给 `EnemyLine` 加权重 / 条件 / 概率。硬纪律：台词永不承载规则信息。**

## 理由

`systems/enemies/_index.md`：台词一旦能说「我要用大招了」，它就成了「敌人的行动不作任何事前预告」（`decisions/ADR-0059-no-enemy-intent-telegraph.md`）这条承重纪律的旁路。

`ux/combat-ux.md`：台词与既有节拍并行播放，不新增任何等待节拍，**敌人回合演出 ≤ 4 s 的硬上界原样成立**——若台词要求额外停留，那条上界就被一条风味元素绕过了。

## 备选方案

- **台词不进战斗屏** — 否决：裁为进战斗屏。
- **给 `EnemyLine` 加权重 / 条件 / 概率** — 否决：那会变成第二套触发系统，而触发式异能已经是那个系统。

## 后果

- 解除 `Lines` 的整条阻塞：`LineSlot` 五成员就位，空数组仍合法（= 该敌人无台词）。
- 约束新成员只能追加末尾；放弃了台词的条件化 / 概率化编排能力。
- 台词进 `LocalizedText` 写作口径：`[Practice, Standard]` 条目须同时说得通两种语境。
