# deck

> 角色卡组 deck —— 抽牌堆 / hand / 弃牌堆、seeded 洗牌、deck 变更，以及卡牌 / **CardData** 定义与起始卡组内容设计。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **deck 是 CharacterProfile 的一部分。** 卡组、hand、以及打出一张卡的结算，都是单次轮回 / 单角色的状态；deck 随轮回推进被增 / 删 / 升级。Source: `10-handoffs/2026-07-24-docs-restructure-class-model.md`。
- **卡牌是道念的唯一产出途径（已定案 · 承重）。** 战斗的胜负标尺是道念（见 `20-systems/scoring.md`），而**道念由打出的卡牌产生**；卡牌**既能给自己加道念，也能削减对方道念**（削减在 0 处截断，无负道念）。**推论：卡牌设计的第一维度是「产多少 / 削多少」**——它取代了 HP 消耗战里的「打多少伤害 / 挡多少」，也是与 `manaLimit`（每回合刷满）配合出节奏的那一维。战斗**定长 10 个回合**、**起始道念按等级给**，共同框定了「一张牌该值多少道念」的量纲（基准未定，见待决问题）。Source: `10-handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。
- **战斗中每个参战方各有一个 `DeckModule`（已定案）。** 卡组不是战斗内的全局单件：**每个 character、每个 enemy 各持有一个**，由 combat-service 的 CharacterManager / EnemyManager 各自持有（`DeckModule` = 第三级抽象，见 `20-systems/architecture.md`）。**敌人也出牌**，且可带定制卡组（如 Finale 的天劫）。本文档持有**角色侧**卡组的设计；敌方卡组的内容形态见 `20-systems/adventure-event/combat/`。Source: `10-handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md`。
- **抽牌堆 / hand / 弃牌堆 · seeded 洗牌 · deck 变更。** 抽牌、手牌、弃牌的循环，以及洗牌必须由轮回种子（seed）驱动以保证确定性可复现。deck 变更（增卡 / 删卡 / 升级）来自遭遇（如 Exchange / 奖励）。
- **卡牌 / CardData 定义。** 卡牌是**数据**（`[GlobalClass] partial class CardData : Resource`，以 `.tres` 编写，带稳定唯一 `Id`）；打出一张卡涉及**费用（mana）、目标选择、效果流水线、触发器**。卡牌数值不硬编码，读自数据资源（见 `data-resource-rules.md`）。

> 具体的抽 / 弃 / 洗规则、CardData 字段（费用、目标、效果、触发器）、效果流水线阶段、起始卡组内容等见 `common-properties.md`。

## 决策(-> ADR)
> _已定案的决定链接到 50-decisions/ADR-####。_

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **卡牌设计意图为占位。** 卡牌的具体机制（手牌上限、每回合抽牌数、效果关键字、目标规则、CardData 字段清单、起始卡组）均尚未设计，需一次 handoff。
- **道念产 / 削的量纲基准未定（承重）。** 「卡牌产道念、可互削、下限 0」已定；但**一张牌该产多少**、**10 个回合内一方的总产出应达到起始 `baseMomentum` 的几倍**未给——它直接决定**越级追分是否可能**（起始就落后 10 点时，5 个回合能否翻盘）。是否存在道念相关的状态与倍率亦未定。→ `20-systems/balance.md`、`20-systems/scoring.md`。Source: `10-handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。
- **出牌费用 = mana（已定案）。** 每回合出牌资源为 mana，**每回合开始恢复至 `manaLimit`**（炼气基线 5/5）；`manaLimit` 由事件 cost / reward 推拉。→ 见 `../mana.md`。
- **敌方卡组是否共用同一套 `CardData` 体系未定。** 敌人也持有卡组已定；其卡牌是与玩家共用卡池 / 共用 `CardData` 定义，还是另立敌方卡池，以及敌方卡组规模与抽牌规则均未定。→ `20-systems/adventure-event/combat/`。Source: `10-handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md`。
- **探查（probe）的卡牌 / 技能形态待设计。** 「付出代价换取当回合敌人意图」的效果已定名并归入本阶段之后的内容横向扩展；花费形式（mana / 弃牌 / 每场次数）与承载形态（卡牌 / 能力 / 道具）待设计。→ `20-systems/services/combat-service.md`。Source: 同上。

## 对应
提炼至：`.claude/knowledge/systems/character-profile/deck/_index.md`（待建）。
