# adventure-event / exchange（AdventureEvent-Exchange）

> 交易 / 商店的**交易机制**。可购道具的定义归属 `player-profile`（见「对应 / 边界」），此处只承载交易行为本身。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **交易（Exchange）= 交易 / 商店。** 一种非战斗 AdventureEvent 子类型，走事件式结算。Source: `20-systems/adventure-event/_index.md`、`terminology.md`。
- **职责切分：交易机制 vs 道具定义（重构裁定）。** shop 有双重语义——既是**获取机制**（归 `adventure-event/exchange/`），又产出**可购道具**（道具定义归 `player-profile/player-item/`）。本子类型**只承载交易机制**（进入商店、浏览库存、以货币购买 / 出售），**不重复定义道具**。Source: `10-handoffs/2026-07-24-docs-restructure-class-model.md`。

## 决策(-> ADR)
> _已定案的决定链接到 50-decisions/ADR-####。_

- **Exchange 为分类法第四类** → `50-decisions/ADR-0002-adventure-event-taxonomy.md`。
- **道具定义归 player-profile、交易机制归 adventure-event/exchange**（当前裁定，见待决问题）。Source: `10-handoffs/2026-07-24-docs-restructure-class-model.md`。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **shop-rewards 双重语义的更清晰切分（draft Open question 原样）：** 当前把道具定义归 player-profile、交易机制归 exchange；是否需要更清晰的切分待确认。Source: `10-handoffs/2026-07-24-docs-restructure-class-model.md`。
- **交易机制细则：** 库存生成规则、定价 / 折扣、货币来源、刷新 / 重roll、售出机制均未定。→ 货币见 `20-systems/character-profile/currency.md`。

## 对应
提炼至：`.claude/knowledge/systems/adventure-event/exchange.md`（待建）
可购道具定义见：`20-systems/player-profile/player-item/`（不在此重复）。
