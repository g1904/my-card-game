# currency

> run 货币 gold —— 单次 run 内的软通货，获取 / 消耗。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **run 货币 = gold（run 级软通货）。** gold 是单次 run 内的货币，随 run 存在、随 run 清理，归 CharacterProfile。它区别于每回合出牌资源 mana（见 `mana.md`）。Source: `10-handoffs/2026-07-24-docs-restructure-class-model.md`。

## 决策(-> ADR)
> _已定案的决定链接到 50-decisions/ADR-####。_

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **gold 的获取 / 消耗尚未设计。** 来源与花销与 `Exchange`（交易 / 商店，见 `20-systems/adventure-event/exchange/`）关联，但具体获取渠道、掉落权重、消耗点均未设计。→ 数值归 `20-systems/balance.md`。Source: `10-handoffs/2026-07-24-docs-restructure-class-model.md`。

## 对应
提炼至：`.claude/knowledge/systems/character-profile/currency.md`（待建）。
