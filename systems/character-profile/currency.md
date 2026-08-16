# currency

> 轮回货币 灵玉 / jade —— 单次轮回内的软通货，获取 / 消耗。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **轮回货币 = 灵玉 / `jade`（轮回级软通货）。** 灵玉是官方货币名（代码标识符 `jade`），是单次轮回内的货币，随轮回存在、随轮回清理，归 CharacterProfile。它区别于每回合出牌资源 mana（见 `mana.md`）。

Source: `handoffs/2026-07-24-docs-restructure-class-model.md`

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **jade 的获取 / 消耗尚未设计。** 来源与花销与 `Exchange`（交易 / 商店，见 `systems/adventure-event/exchange/`）关联，但具体获取渠道、掉落权重、消耗点均未设计。→ 数值归 `systems/balance.md`。

## 对应
提炼至：`.claude/knowledge/systems/character-profile/currency.md`（待建）。
