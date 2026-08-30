# ADR-0063 — 资源的钳制 / 终态 / modifier 准入统一查一张逐 element 的封闭表 `ResourceElements`

- **状态：** Accepted
- **日期：** 2026-08-16
- **来源：** handoffs/2026-08-16d-cost-side-closure.md

## 背景

每种资源（`LifeSpan` / `Mana` / `SpiritStone` / 隐藏属性…）都要回答四个问题：能降到多少、能升到多少、归 0 是不是终态、哪些 modifier 能作用于它。若这四问散落在各资源的字段判断里，新增一种资源就要在四处各补一段。

## 决策

**钳制、终态与修正接入统一查 `ResourceElements` 表，不散落字段判断（承重）。**

每个资源 element 在表中占一行：**`(Min, Max, DepletionDefeat, CostModifier, GainModifier, AllowedOps)` 六列**。

落点是**代码常量静态表，不进 `.tres`**。

全表与逐列语义 → `systems/services/profile-service.md`；共享核心类型 → `systems/architecture.md`。

## 理由

「一条全局通则」在本作行不通：`PowerFragmentAccumulated` 的区间是 `[0, 10000]`、`Faith` / `Bloodlust` 是 `[0, 100]`、`LifeSpan` 无上界——**已经有三个不同的区间**，通则会立刻退化为「通则 + 三个例外」。一张表则天然容纳差异，且新增资源 = 加一行。

不进 `.tres` 的理由：这张表是**类型级契约**（谁能被谁修改），不是可调数值。放进内容层意味着 overlay 能改「归 0 算不算死」，那是规则不是平衡。

## 备选方案

- **资源一律截断到 0 的通则** — 否决：两个已存在的非零下界区间即是反例。
- **终态性与钳制分两处** — 否决：两者都是「这个资源到边界时怎么办」，分开会让新增资源漏配其中之一。

## 后果

- 新增一种资源必须同时加一行，否则 `TryApply` 查表失败即报错——漏配在结构上不可能静默。
- `TryApply` 的整批原子性建立在这张表之上：任一 element 违反其行即整批拒绝。
- 表已由首批 5 行长到 15 行，增长是预期形态而非漂移。
- **收缩同样是预期形态，且有对称的程序。** 删一个资源 element = 删字段 + 删 `CostKey` 成员 + 删表行 + （若该行带 `DepletionDefeat`）同步删 `DefeatReason` 成员并复核终态判定旁路 + bump schema。**只登记增长会让删除变成一次没有清单的手工作业**，而漏掉 `DefeatReason` 那一步会留下一个永远不可达的成员；逐步清单见 `systems/architecture.md`。
