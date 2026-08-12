# deck —— 共有属性

> deck 子系统的共有字段与共有机制：抽 / 弃 / 洗循环、CardData 定义（费用、目标、效果流水线、触发器）。为未来「每张卡一个 Markdown」预留结构。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **抽牌 / hand / 弃牌循环（共有机制）。** 卡从抽牌堆抽入 hand，打出后进弃牌堆；**弃牌堆不回流**——抽牌堆抽空即为空，此后每尝试抽一张牌抽牌方 −1 道念（疲劳，见 `systems/scoring.md`）。洗牌只在参战方组装时发生一次，由 cycle seed 驱动（确定性可复现，见 `state-save-rules.md`）。
- **CardData 共有字段（数据即资源）。** 每张卡是一个 `CardData : Resource`（`.tres`），共有字段预期含：稳定唯一 `Id`、显示名 / 描述（与 `Id` 分离、可本地化）、**费用（mana cost）**、**目标（target）**、**效果流水线（effect pipeline）**、**触发器（trigger）**。数值读自资源，不硬编码。Source: `data-resource-rules.md`。
- **三个新增共有字段（已定案 · 08-04b）：**

  | 字段 | 类型 | 说明 |
  |---|---|---|
  | `CardType` | `CardType` | **必填，无默认值**（逼内容侧显式声明；缺失 → 加载时 `PushError`）。五值：`Sorcery` / `Enchantment` / `Item` / `Power` / `Affliction` |
  | `Subtypes` | `string[]` | 次类型 id 列表，可空。**须在次类型注册表中存在**，否则加载时 `PushError`；且须与主类型匹配（「埋伏」只能挂 `Enchantment`） |
  | `Abilities` | `AbilityData[]` | 该牌携带的异能列表，可空 |

  **`CardType` 与 `Subtypes` 是静态字段，不进存档**（存档只记 `Id`），故**无迁移**。Source: `handoffs/2026-08-04b-mtg-loanwords-card-types-and-intent-snapshot.md`。
- **`AbilityData`（跨载体可复用的异能资源 · 08-04b）。** 异能不是 `CardData` 的私有字段结构——神通、持续状态、道具都能带异能，故抽为独立资源，由 `CardData` / `PowerData` / `ItemData` / 战场条目共同引用。

  ```csharp
  public enum AbilityKind { Static = 0, Activated = 1, Triggered = 2 }
  public enum TriggerOwnerScope { Self = 0, Opponent = 1, Either = 2 } // Opponent ← 埋伏靠这个成立

  // AbilityData : Resource
  //   Id / Kind / ActivationCost(ProfileChangeSpec?，仅 Activated) / TriggerWhen(仅 Triggered) / Effect
  // TriggerConditionData : Resource
  //   TimingId("turn.start" / "turn.end" / "card.played"…) / OwnerScope / Filter(次类型、费用区间等)
  ```

  Source: 同上。
- **加载时校验规则（坏数据启动即失败 · 08-04b）。**

  | 规则 | 违反时 |
  |---|---|
  | `CardType` 必填 | `PushError`，带 `Id` 与 `.tres` 路径 |
  | `Sorcery` 不得带 `Static` / `Activated` 异能 | `PushError`——不留场，无生效载体 |
  | `Affliction` 不得带任何异能 | `PushError` |
  | `Affliction` 允许有 mana 费用与负向效果，但不得有正面效果 | `PushWarning`（软检查，例：业障带产道念的效果 → 警告）——正负难以机械判定，主要靠内容侧纪律 |
  | `Enchantment` 至少带一个异能 | `PushWarning`——不带异能的永久物是空条目，多半漏填 |
  | `AbilityKind == Activated` 时 `ActivationCost` 非空 | `PushError`——零费启动式异能会造成无限循环 |
  | `AbilityKind == Triggered` 时 `TriggerWhen` 非空 | `PushError` |
  | `Subtypes` 中每个 id 须在次类型注册表中存在 | `PushError`，报出悬空 id |
  | 次类型须与主类型匹配 | `PushError` |

  Source: 同上。
- **打出一张卡的结算（共有流程）。** 费用支付（mana）→ 目标选择 → 效果流水线依序执行 → 触发器响应事件。（具体阶段待设计。）**生命周期链路按 `CardType` 分叉**：`Sorcery` / `Affliction` 结算后进弃牌堆；`Enchantment` 结算后作为**永久物**落战场；`Item` 不经卡组、结算后进弃牌堆或按次数消耗；`Power` 开局入场且**永不入栈、永不离场**。

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **CardData 字段清单未定案（08-04b 部分落定）。** **已定：`CardType` / `Subtypes` / `Abilities` 三个共有字段与 `AbilityData` / `TriggerConditionData` 的形态**（见上）；**仍为结构占位**：费用 / 目标 / 效果流水线的具体类型与枚举、效果关键字体系、目标规则，需一次 handoff。
- **抽 / 弃 / 洗数值。** 手牌上限、每回合抽牌数、初始牌堆规模等属平衡数值 → `systems/balance.md`。

## 对应
提炼至：`.claude/knowledge/data/_index.md`（CardData）；`.claude/knowledge/systems/character-profile/deck/`（待建）。
