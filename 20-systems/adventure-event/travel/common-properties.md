# adventure-event / travel / common-properties（Travel 子类型共有属性）

> Travel 类 AdventureEvent 共有的属性 / 字段。顶层共有属性见 `../common-properties.md`。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **目的地 location 引用。** 一个 Travel 事件承载可前往的目的地 location（地域）；选定后刷新角色所在的 location，进而重算 eventOptions（见 `20-systems/services/future-event-service.md`）。location 模型主文档在 `20-systems/game-progression.md`。Source: `10-handoffs/2026-07-24-docs-restructure-class-model.md`、`terminology.md`。
- **路由语义。** Travel 功能上是地图路由选择，而非战斗 / 事件式玩法本身。Source: `10-handoffs/2026-07-24-docs-restructure-class-model.md`。

## 决策(-> ADR)
> _已定案的决定链接到 50-decisions/ADR-####。_

- 见 `_index.md`。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **目的地字段与 location schema：** location 的数据表达、可选目的地的约束未定。→ `20-systems/game-progression.md`、`_index.md`。

## 对应
提炼至：`.claude/knowledge/systems/adventure-event/travel.md`（待建）
