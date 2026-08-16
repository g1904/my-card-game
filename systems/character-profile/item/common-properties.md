# item —— 共有属性

> 角色级道具（`CharacterItem` 持有条目）的共有字段与共有机制。占位结构，细节待定。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **角色道具是 CharacterProfile 的 `magicPack: List<CharacterItem>`（储物袋）。** 集合的每个元素是**一份持有实例**（不是「一条 Id 一行」）：带 `ItemId`（指向 `ItemData.Id` 的引用字段）与该份各自的 `Charges` / `status`。**内容定义 `ItemData` ↔ 持有条目 `CharacterItem` ↔ 集合字段 `magicPack` 的三层分工**见 `_index.md` 顶部。

- **`SourceCode`（共有字段 · 类型 `Source` 枚举）。** 落在 **CharacterItem 持有条目**上（`magicPack` 的每份实例各自一份），不落在 `ItemData` 上。
  - **本层合法取值 =** `EventOutcome` / `CombatReward` / `ExchangePurchase` / `InitialGrant`（+ 读档兜底 `Unknown`），与神通列相同。
  - **本层无规则消费点**——`x` 只数法则。本层它只承载非规则用途，**字段有信息但暂无规则消费者**，这是有意接受的代价。
  - 枚举清单、分域校验表（入口严 / 读档宽）与授予通道的强制携带规则见 `systems/common-properties.md`。

Source: `handoffs/2026-07-24-docs-restructure-class-model.md` · `handoffs/2026-08-12b-grant-source-per-kind-scope.md` · `handoffs/2026-08-12c-identifier-singular-collapse.md`

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **共有字段未定案。** 若道具走「数据即资源」，预期会有稳定唯一 `Id`、显示名 / 描述、效果定义等（对齐 `data-resource-rules.md`）——但目前**未有任何设计**，全部为占位待定。

## 对应
提炼至：`.claude/knowledge/systems/character-profile/item/`（待建）。
