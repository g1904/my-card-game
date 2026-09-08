# item —— 共有属性

> 角色级道具（`CharacterItem` 持有条目）的共有字段与共有机制。**内容定义侧（`ItemData`）的字段清单、两格使用效果面与加载期校验的权威在 `_index.md`**，本文件只写持有条目侧。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **角色道具是 CharacterProfile 的 `magicPack: List<CharacterItem>`（储物袋）。** 集合的每个元素是**一份持有实例**（不是「一条 Id 一行」）：带 `ItemId`（指向 `ItemData.Id` 的引用字段）与该份各自的 `Charges` / `status`。**内容定义 `ItemData` ↔ 持有条目 `CharacterItem` ↔ 集合字段 `magicPack` 的三层分工**见 `_index.md` 顶部。**内容定义侧的完整字段清单、两格使用效果面与加载期校验的权威在 `_index.md`**，本文件不复述。

- **`SourceCode`（共有字段 · 类型 `Source` 枚举）。** 落在 **CharacterItem 持有条目**上（`magicPack` 的每份实例各自一份），不落在 `ItemData` 上。
  - **本层合法取值 =** `EventOutcome` / `CombatReward` / `ExchangePurchase` / `InitialGrant`（+ 读档兜底 `Unknown`），与神通列相同。
  - **本层无规则消费点**——`x` 只数法则。本层它只承载非规则用途，**字段有信息但暂无规则消费者**，这是有意接受的代价。
  - 枚举清单、分域校验表（入口严 / 读档宽）与授予通道的强制携带规则见 `systems/common-properties.md`。

- **`Status`（共有字段 · `bool`，true = 启用，默认 true）与「拥有 / 失去」是正交两维。** 法宝**对玩家开放这个开关**：储物袋里可以关掉一件不想自动触发 / 不想误点的法宝。
  - **拥有 = `magicPack` 的成员资格**；失去 = 移出该列表，不是置 `Status = false`。
  - **本轮回禁用是第三维**，落 `CharacterProfile.disabledAbility`，不挤进这一格。
  - **生效 = 三条与门**：拥有 ∧ `Status == true` ∧ 不在 `disabledAbility` 内。
  - **关掉的法宝仍占储物袋位、`Charges` 不变**——与「禁用不影响持有、也不影响 `Charges`」逐字同构。
  - **写入经 `ProfileChangeSpec.AbilityStatusChanges`**，门面 `SetAbilityStatus(kind, scope, abilityId, enabled)`，见 `systems/services/profile-service.md`。record 形态（四类持有条目共有 `Status`）的权威在 `systems/player-profile/_index.md`，本文件不复述。

Source: `handoffs/2026-07-24-docs-restructure-class-model.md` · `handoffs/2026-08-12b-grant-source-per-kind-scope.md` · `handoffs/2026-08-12c-identifier-singular-collapse.md` · `handoffs/2026-09-06-status-vs-ownership-encoding.md`

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- 无。

## 对应
提炼至：`.claude/knowledge/systems/character-profile/item/`（待建）。
