# adventure-event / travel（AdventureEvent-Travel）

> **新类型「前往某处地点」**（07-24 加入的第九类）。功能上是一次地图路由选择，刷新角色所在的 location（地域）。具体机制待定，见 ## 待决问题。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **前往某处地点（Travel）= AdventureEvent 的新子类型（第九类）。** **功能上是一次地图路由选择**——刷新角色所在的 **location（地域）**。07-24 随本次重构从 handoff 播种。Source: `handoffs/2026-07-24-docs-restructure-class-model.md`、`terminology.md`。
- **通过 location 换图，框定下一批可用事件。** location（地域）是抽象概念，**框定 eventOptions**（角色当前地点决定下一批可能出现的修行事件池）；Travel 事件是刷新 location 的手段。location 归属 `systems/game-progression.md`，Travel 通过它换图。Source: `handoffs/2026-07-24-docs-restructure-class-model.md`、`terminology.md`。

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- **Travel 作为第九类加入分类法**（ADR-0002 待补订）。Source: `handoffs/2026-07-24-docs-restructure-class-model.md`。
- **location 框定 eventOptions、由 Travel 刷新**（方向已定）。Source: `handoffs/2026-07-24-docs-restructure-class-model.md`、`terminology.md`。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **Travel 与 game-progression 的具体交互？** location 的模型（枚举 / 图 / 数据资源）、可达 location 的约束、Travel 事件如何呈现可去目的地未定。→ `systems/game-progression.md`。
- **一次 Travel 刷新多少 / 何种事件？** location 换图后 eventOptions 的生成规则（数量、类型配比）未定。→ `systems/services/future-event-service.md`、`../common-properties.md`。
- **Travel 的代价 / 风险？** 前往是否消耗资源、是否可能触发途中遭遇未定。
- **与篇章 / 境界推进的关系？** Travel 是否与篇章边界 / Finale 触发耦合未定。
- **ADR-0002 补订：** 正式并入枚举待补。

## 对应
提炼至：`.claude/knowledge/systems/adventure-event/travel.md`（待建）
location（地域）主文档见：`systems/game-progression.md`。
