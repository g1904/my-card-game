# item —— 共有属性

> 角色级道具（`CharacterItem` 持有条目）的共有字段与共有机制。占位结构，细节待定。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **角色道具是 CharacterProfile 的 `magicPack: List<CharacterItem>`（储物袋）。** 集合的每个元素是**一份持有实例**（不是「一条 Id 一行」）：带 `ItemId`（指向 `ItemData.Id` 的引用字段）与该份各自的 `Charges` / `status`。**内容定义 `ItemData` ↔ 持有条目 `CharacterItem` ↔ 集合字段 `magicPack` 的三层分工**见 `_index.md` 顶部。Source: `handoffs/2026-08-12c-identifier-singular-collapse.md` + `handoffs/2026-07-24-docs-restructure-class-model.md`。

- **`SourceCode`（共有字段：授予来源，类型 `Source` 枚举 · 已定案 · 08-12b）。** 法宝条目记录**它是被哪条渠道给到玩家的**，写入时刻 = 授予时刻、此后不变；**落在持有条目上而非 `ItemData` 上**（同一件法宝可由不同渠道获得）。
  - **本层合法取值（08-12b 分域清单的法宝列）= `EventOutcome` / `CombatReward` / `ExchangePurchase` / `InitialGrant`**（+ 读档兜底 `Unknown`），与神通列相同。**这四条正是法宝的常规来路**——08-10b 的封闭三值全是账号级途径、在本层无一合法，该冲突由 08-12b 扩清单解决（**推翻「清单是封闭的」**，而非收窄字段覆盖面）。`FinaleWin` / `PremiumBundle` / `AchievementReward` 在本层不合法（账号级发放的东西不该随轮回清理）。
  - **本层没有规则消费点**——`SourceCode` 的**规则**消费点唯一，是残卷的 `x`，而 `x` 只数法则。本层它承载的是**非规则用途**（`TryApply` 可追溯性日志 + 客服 / 数据侧溯源）。
  - 枚举清单、分域校验表（入口严 / 读档宽）与授予通道的强制携带规则见 `systems/common-properties.md`。Source: `handoffs/2026-08-12b-grant-source-per-kind-scope.md`。

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **共有字段未定案。** 若道具走「数据即资源」，预期会有稳定唯一 `Id`、显示名 / 描述、效果定义等（对齐 `data-resource-rules.md`）——但目前**未有任何设计**，全部为占位待定。Source: `handoffs/2026-07-24-docs-restructure-class-model.md`。

## 对应
提炼至：`.claude/knowledge/systems/character-profile/item/`（待建）。
