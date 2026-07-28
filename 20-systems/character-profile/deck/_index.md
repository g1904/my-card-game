# deck

> 角色卡组 deck —— 抽牌堆 / hand / 弃牌堆、seeded 洗牌、deck 变更，以及卡牌 / **CardData** 定义与起始卡组内容设计。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **deck 是 CharacterProfile 的一部分。** 卡组、hand、以及打出一张卡的结算，都是单次轮回 / 单角色的状态；deck 随轮回推进被增 / 删 / 升级。Source: `10-handoffs/2026-07-24-docs-restructure-class-model.md`。
- **抽牌堆 / hand / 弃牌堆 · seeded 洗牌 · deck 变更。** 抽牌、手牌、弃牌的循环，以及洗牌必须由轮回种子（seed）驱动以保证确定性可复现。deck 变更（增卡 / 删卡 / 升级）来自遭遇（如 Exchange / 奖励）。
- **卡牌 / CardData 定义。** 卡牌是**数据**（`[GlobalClass] partial class CardData : Resource`，以 `.tres` 编写，带稳定唯一 `Id`）；打出一张卡涉及**费用（mana）、目标选择、效果流水线、触发器**。卡牌数值不硬编码，读自数据资源（见 `data-resource-rules.md`）。

> 具体的抽 / 弃 / 洗规则、CardData 字段（费用、目标、效果、触发器）、效果流水线阶段、起始卡组内容等见 `common-properties.md`。

## 决策(-> ADR)
> _已定案的决定链接到 50-decisions/ADR-####。_

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **卡牌设计意图为占位。** 卡牌的具体机制（手牌上限、每回合抽牌数、效果关键字、目标规则、CardData 字段清单、起始卡组）均尚未设计，需一次 handoff。
- **出牌费用 = mana（方向已定，速率待定）。** 每回合出牌资源为 mana（上限 + 逐步恢复，炼气基线 5/5）；恢复速率仍待定。→ 见 `../mana.md`。

## 对应
提炼至：`.claude/knowledge/systems/character-profile/deck/_index.md`（待建）。
