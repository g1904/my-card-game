# adventure-event / travel / common-properties（Travel 子类型共有属性）

> Travel 类 AdventureEvent 共有的属性 / 字段。顶层共有属性见 `../common-properties.md`。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **目的地 location 引用，取自 `locationMap` 的邻接集合（已定案 · 08-05b）。** 一个 Travel 事件承载可前往的目的地 location（地域）；选定后刷新角色所在的 location，进而重算 eventOptions（见 `systems/services/future-event-service.md`）。**目的地不是内容作者在事件条目上连好的边**——连通关系由全局不变的 **`locationMap`** 承载，Travel 的目的地在物化时从当前 location 的邻接集合中取。location 与 `locationMap` 的主文档在 `systems/game-progression.md`。Source: `handoffs/2026-07-24-docs-restructure-class-model.md`、`terminology.md` + `handoffs/2026-08-05b-location-fields-event-count-limit-and-skip-refill-closure.md`。
- **路由语义。** Travel 功能上是地图路由选择，而非战斗 / 事件式玩法本身。Source: `handoffs/2026-07-24-docs-restructure-class-model.md`。
- **闸门形态下的物化置位（已定案 · 08-05b）。** 当 `eventCountLimit` 达成、Travel 作为出口出场时，它由 future-event-service 物化为**最高 `Priority`（= 1）**的 `EventOption`——该字段是**物化时动态置位**的，**不由内容作者在 `.tres` 写死**（08-06c：`IsMandatory` 已随跳过通道一并移除，闸门只靠优先级成立）。同一个 Travel 内容条目在配额未满时仍可作为普通可选项出场。Source: `handoffs/2026-08-05b-location-fields-event-count-limit-and-skip-refill-closure.md`。

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- 见 `_index.md`。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **目的地字段与 location schema：** location 的数据表达、可选目的地的约束未定。→ `systems/game-progression.md`、`_index.md`。

## 对应
提炼至：`.claude/knowledge/systems/adventure-event/travel.md`（待建）
