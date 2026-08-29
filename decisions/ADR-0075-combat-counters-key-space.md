# ADR-0075 — 战斗内 `counters` 的键空间只有 `<abilityId>[#<子名>]` 一种形态，子名须登记

- **状态：** Accepted
- **日期：** 2026-08-22
- **来源：** handoffs/2026-08-22-combat-runtime-counter-persistence.md, handoffs/2026-08-22-card-counters-api-and-key-space.md

## 背景

战斗内的运行态计数（这张牌被触发过几次、这个异能积累了多少层）需要一个存放处。`counters` 是一个字符串键字典——而字符串键的问题是任何拼写都合法，拼错的键会静默开出一个新计数器，原计数器永远读到 0。

## 决策

**合法的键形态只有一种：`<abilityId>[#<子名>]`，`counters` 不承载非异能计数。**

子名**须登记在 `AbilityData.CounterNames` 内**，**读写两侧都校验**。

**`KeywordRef.Amount` 落战场条目独立的 `amount` 一格，不进 `counters`。**

API 面与校验 → `systems/services/combat-service.md`；关键字侧 → `systems/character-profile/deck/common-properties.md`。

## 理由

登记 + 两侧校验把「拼错」从**静默的错误行为**变成**开机可失败的检查**：拼错的子名不在 `CounterNames` 里，读写当场报错。只靠正则不做登记是不够的——**拼错的名字通常仍然合法**（`burn` vs `burns` 都匹配正则）。

`Amount` 不进 `counters` 的判据是语义：**`counters` 的语义是计数**（随对局递增递减），**`Amount` 是参数**（出牌时定稿，不变）。混装后无从分辨哪些键该在回合结束清零。

## 备选方案

- **给关键字状态层数开第二类键** — 否决：层数是**可重算的派生量**，不该有独立落点。
- **只靠正则校验，不做登记** — 否决：拼错的名字通常仍然合法，静默开出的新计数器让配额闸门永远读到 0。

## 后果

- 键空间闭合使 `counters` 可以整体落存档而无需担心未知键。
- 战斗内运行态计数器随 `activeCombat` 持久化，退出重进得到同一份（→ `ADR-0036`）。
- 新增一类计数必须先在 `AbilityData.CounterNames` 登记，这是一次内容改动而非代码改动。
