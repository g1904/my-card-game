# adventure-event / exchange / common-properties（Exchange 子类型共有属性）

> Exchange 类 AdventureEvent 共有的属性 / 字段。顶层共有属性见 `../common-properties.md`。仅交易机制字段；道具定义见 `player-profile/player-item/`。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **库存引用。** Exchange 事件承载一份可购 / 可售条目列表，以 `Id` 引用别处定义的道具（`player-profile/player-item/`）而非内联定义。Source: `10-handoffs/2026-07-24-docs-restructure-class-model.md`。
- **交易货币引用。** 购买 / 出售读写角色货币（见 `20-systems/character-profile/currency.md`）。Source: `10-handoffs/2026-07-24-docs-restructure-class-model.md`（结构映射）。

## 决策(-> ADR)
> _已定案的决定链接到 50-decisions/ADR-####。_

- 见 `_index.md`。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **库存 / 定价 schema：** 见 `_index.md`（交易机制细则未定）。

## 对应
提炼至：`.claude/knowledge/systems/adventure-event/exchange.md`（待建）
