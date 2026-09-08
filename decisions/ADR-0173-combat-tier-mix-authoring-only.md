# ADR-0173 — `combatTier` 配比是内容编排口径：`Practice : Standard = 1 : 1` 三章统一，管线不掷 tier

- **状态：** Accepted
- **日期：** 2026-09-06
- **来源：** handoffs/2026-09-06-event-type-mix-ratios.md · answer-logs/log-event-type-mix-ratios.md

## 背景

`Combat` 那一格的权重定了之后，随之而来的是「这些战斗里轻档与常规档各占多少」。最自然的想法是再开一张 `CombatTierWeights` 表、在生成管线里加一步掷 tier——但那与「一个 `AdventureEventData` 条目只有一个档」的既定形态直接冲突。

## 决策

**`Practice : Standard` 的目标比例 = `1 : 1`，三章统一。**

**它是内容编排口径，不是运行期旋钮（承重）：** 管线**不掷 tier**，实际比例是**条目池组成 × `SelectionWeight` 的涌现结果**。**不新增字段 / 不设 `CombatTierWeights` 表 / 不在管线里加一步。**

编排口径与它在灵石给予量 `S(c)` 反推中的用法 → `systems/adventure-event/combat/_index.md`、`systems/balance.md`。

## 理由

- **一个条目只有一个档**：`combatTier` 写在 `AdventureEventData` 条目上。要在运行期掷档，就得让同一个条目能变成两个档——那是在推翻条目的物化模型（`ADR-0012`）。
- **涌现比运行期旋钮更诚实**：编排者往池子里放多少个 `Practice` 条目、给它们多大 `SelectionWeight`，本来就完全决定了这个比例；再加一层运行期权重等于让同一件事有两个控制点。
- **这个 `1 : 1` 是全库口径而非局部假设**——`S(c)` 的档偏置反推、战后奖励厚薄的标定都建立在它之上，故必须写成口径而非某一处的临时取值。

## 备选方案

- **`CombatTierWeights` 表 + 管线加一步掷 tier** — 否决：撞「一个条目只有一个档」。
- **`Practice : Standard` 逐章右移**（越往后常规档越多） — 否决：要按章重算 Explore 定价行，代价与收益失配。

## 后果

- **`/audit-content` 需要能报出当前池子的实际 tier 构成**，否则这条编排口径无从核对（它不进任何加载期校验）。
- **改这个比例 = 改内容池**，不是改一个数字——这是本条要的性质。
- 受约束的文档：`systems/adventure-event/combat/_index.md` · `systems/balance.md` · `systems/services/future-event-service.md` · `decisions/ADR-0012-materialization-model.md`。
