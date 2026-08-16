# adventure-event / exchange（AdventureEvent-Exchange）

> 交易：**以资源换取 item / cultivationTechnique / 等**，含与 NPC / 势力打交道的社交语境。可购道具的定义归属 `player-profile`（见「对应 / 边界」），此处只承载交易行为本身。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **交易（Exchange）= 玩家以资源换取 item / cultivationTechnique / 等。** 一种非战斗 AdventureEvent 子类型，走事件式结算。
- **Exchange 吸收社交语境。** 与 NPC / 势力的社交互动**不单列为一类**：「与 NPC 谈条件」与「在商店买东西」共有同一套事件式结算形状与呈现形状，分成两类只是在内容风味上切一刀，而**风味不需要枚举值来承载**。因此坊市商贾、同门师长、宗门势力一律是 Exchange 条目的不同风味。
- **职责切分：交易机制 vs 道具定义。** shop 有双重语义——既是**获取机制**（归 `adventure-event/exchange/`），又产出**可购道具**（道具定义归 `player-profile/player-item/`）。本子类型**只承载交易机制**（进入商店、浏览库存、以货币购买 / 出售），**不重复定义道具**。

Source: `handoffs/2026-07-24-docs-restructure-class-model.md` · `handoffs/2026-08-15c-event-type-collapse-and-batch-shape.md`

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- **Exchange 为五类分类法之一，社交语境并入其中** → `decisions/ADR-0002-adventure-event-taxonomy.md`。
- **道具定义归 player-profile、交易机制归 adventure-event/exchange**（见待决问题）。

Source: `handoffs/2026-07-24-docs-restructure-class-model.md` · `handoffs/2026-08-15c-event-type-collapse-and-batch-shape.md`

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **shop-rewards 双重语义的更清晰切分：** 当前把道具定义归 player-profile、交易机制归 exchange；是否需要更清晰的切分待确认。
- **交易机制细则：** 库存生成规则、定价 / 折扣、货币来源、刷新 / 重roll、售出机制均未定。→ 货币见 `systems/character-profile/currency.md`。
- **NPC / 势力模型是否仍需要：** 社交语境归 Exchange 后，NPC / 势力是**降级为交易条目的风味层**（只是文案与插图），还是仍需一套数据模型（NPC 如何定义、好感 / 关系度是否有持久数值、跨轮回是否留存）？归 Exchange 专场。→ `systems/services/plot-manager.md`。
- **社交型产出的形态：** 除道具 / 卡牌外，是否产出剧情分支、是否触发 AdventurePlot 分支未定。→ `systems/services/plot-manager.md`。
- **「余额不足即拒」是否仍需保留在此。** 事件推进路径不需要它（`selectCost` 无条件施加）；**Exchange 内的商店购买是它最后一个可能的消费点**——若此处也不需要，`CanAfford` / `AdvanceResult.CostRejected` / `MissingElement` 可整体删除。→ `systems/services/profile-service.md`。

Source: `handoffs/2026-07-24-docs-restructure-class-model.md` · `handoffs/2026-08-15c-event-type-collapse-and-batch-shape.md`

## 对应
提炼至：`.claude/knowledge/systems/adventure-event/exchange.md`（待建）
可购道具定义见：`systems/player-profile/player-item/`（不在此重复）。
