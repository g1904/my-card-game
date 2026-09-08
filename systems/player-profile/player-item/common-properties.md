# player-item —— 共有属性

> PlayerItem 的共有字段与共有机制：账号级、使用次数限制、可购语义。为未来「每个道具一个 Markdown」预留结构。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **使用次数限制（共有机制）。** PlayerItem 的定义性共有属性是**有使用次数限制**——一种会被消耗的账号级资源。
- **`SourceCode`（共有字段 · 类型 `Source` 枚举）。** 落在 **PlayerItem 持有条目**上，不落在 `ItemData` 上。
  - **本层合法取值 =** `PremiumBundle` / `AchievementReward` / `ExchangePurchase`（+ 读档兜底 `Unknown`）。
  - **本层无规则消费点**——`x` 只数法则。本层它只承载非规则用途，**字段有信息但暂无规则消费者**，这是有意接受的代价。
  - 枚举清单、分域校验表（入口严 / 读档宽）、授予通道的强制携带与置换继承规则见 `systems/common-properties.md`。
- **可购字段。** 作为可购道具，预期共有字段含价格 / 成本、库存（Shop 库存 seeded）、稀有度 / 权重等；购买发生在 Exchange 事件中。

Source: `handoffs/2026-07-22-online-cloud-combat-and-meta-clarifications.md` · `handoffs/2026-07-24-docs-restructure-class-model.md` · `handoffs/2026-08-12b-grant-source-per-kind-scope.md`

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **共有字段部分未定案。** **已定案的部分不在本条范围内**：`SourceCode` 的合法取值与分域校验（见上方「意图」）· `Charges > 0` 是 `Scope == Player` 的硬约束（违反 → 加载期 `PushError`）· 两格使用效果面 `CombatUseEffects` / `OutOfCombatUseOutcome` 与本场配额 `MaxUsesPerCombat` · 必填 `Rarity: RarityTier`（缺失 → `PushError`）· **`ItemData` 上不加 `Price` / `Purchasable`**——权威见 `_index.md` 与 `../../character-profile/item/_index.md`。
  **仍未设计**：次数上限的具体取值模型与次数如何补充、可购价格 / 库存权重、道具种类目录（对齐 `data-resource-rules.md` 的「数据即资源」形态）。

## 对应
提炼至：`.claude/knowledge/systems/player-profile/player-item/`（待建）。
