# player-item —— 共有属性

> PlayerItem 的共有字段与共有机制：账号级、使用次数限制、可购语义。为未来「每个道具一个 Markdown」预留结构。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **使用次数限制（共有机制）。** PlayerItem 的定义性共有属性是**有使用次数限制**——一种会被消耗的账号级资源。Source: `handoffs/2026-07-22-online-cloud-combat-and-meta-clarifications.md`。
- **可购字段。** 作为可购道具，预期共有字段含价格 / 成本、库存（Shop 库存 seeded）、稀有度 / 权重等；购买发生在 Exchange 事件中。Source: `handoffs/2026-07-24-docs-restructure-class-model.md`。

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **共有字段未定案。** 若走「数据即资源」，预期有稳定唯一 `Id`、显示名 / 描述、使用次数上限、效果定义、价格 / 库存权重（对齐 `data-resource-rules.md`）——但目前均为占位，无实质设计。

## 对应
提炼至：`.claude/knowledge/systems/player-profile/player-item/`（待建）。
