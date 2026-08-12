# player-item —— 共有属性

> PlayerItem 的共有字段与共有机制：账号级、使用次数限制、可购语义。为未来「每个道具一个 Markdown」预留结构。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **使用次数限制（共有机制）。** PlayerItem 的定义性共有属性是**有使用次数限制**——一种会被消耗的账号级资源。Source: `handoffs/2026-07-22-online-cloud-combat-and-meta-clarifications.md`。
- **`SourceCode`（共有字段：授予来源，类型 `Source` 枚举 · 已定案 · 08-12b）。** 每个持有条目记录**它是被哪条渠道给到玩家的**。写入时刻 = 授予时刻、此后不变；**落在持有条目上而非 `ItemData` 上**（同一件古宝可由不同渠道获得）；置换所得继承被换出条目的来源。
  - **本层合法取值（分域清单的古宝列）= `PremiumBundle` / `AchievementReward` / `ExchangePurchase`**（+ 读档兜底 `Unknown`）。**`ExchangePurchase` 是 08-12b 扩清单为古宝补上的那一条**——可购道具的购买发生在 Exchange 事件中，此前无合法取值。`FinaleWin` 只发法则；`CombatReward` / `InitialGrant` 属轮回级来路，在账号级不合法；**`EventOutcome` 暂不开放**（同法则一侧，取决于「第三条获取渠道」那条待决项）。
  - **古宝侧没有规则消费点**——`SourceCode` 的**规则**消费点唯一，是残卷的 `x`，而 `x` 只数法则。本层它承载的是**非规则用途**（`TryApply` 可追溯性日志 + 客服 / 数据侧账号溯源），尤其是**付费给予 vs 玩法购买的区分**——那是退款与申诉的第一手依据。
  - 枚举清单、分域校验表（入口严 / 读档宽）与授予通道的强制携带规则见 `systems/common-properties.md`。Source: `handoffs/2026-08-12b-grant-source-per-kind-scope.md`。
- **可购字段。** 作为可购道具，预期共有字段含价格 / 成本、库存（Shop 库存 seeded）、稀有度 / 权重等；购买发生在 Exchange 事件中。Source: `handoffs/2026-07-24-docs-restructure-class-model.md`。

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **共有字段未定案。** 若走「数据即资源」，预期有稳定唯一 `Id`、显示名 / 描述、使用次数上限、效果定义、价格 / 库存权重（对齐 `data-resource-rules.md`）——但目前均为占位，无实质设计。

## 对应
提炼至：`.claude/knowledge/systems/player-profile/player-item/`（待建）。
