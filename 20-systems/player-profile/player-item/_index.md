# player-item

> **古宝 / PlayerItem** —— 账号级、有使用次数限制的道具，含可购道具定义。
> **中文定名 = 古宝**（08-03 定，取代「玩家道具」）；轮回级的对应物是 **法宝 / CharacterItem**（`../../character-profile/item/`）。**中文名不表达层级**。Source: `10-handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md`。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **PlayerItem = 账号级、有使用次数限制的道具。** 独立于任何单次轮回，由 PlayerProfile 持有（`List<PlayerItem>`）；跨轮回持久。与角色级的 CharacterItems（`../../character-profile/item/`）区分开。Source: `10-handoffs/2026-07-22-online-cloud-combat-and-meta-clarifications.md`。
- **可购道具定义。** 道具的**定义 / 可购语义**归入本处；**交易机制**本身（作为一种 AdventureEvent）归 `20-systems/adventure-event/exchange/`（Exchange / 交易）。即：道具**是什么**在这里，**如何买到**在 exchange。Source: `10-handoffs/2026-07-24-docs-restructure-class-model.md`。

- **一条已定的获取渠道 = premium bundle（已定案）。** 付费礼包一次性给予**随机 2 个 PlayerItem**（外加随机 1 个 PlayerPower）。这是目前唯一明确写下的 PlayerItem 获取途径——其余（Exchange 购买、事件产出）仍是方向而非定案。礼包全貌见 `20-systems/monetization.md`。Source: `10-handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。
- **已获得的 PlayerItem 会进 PlayerItemCodex。** 图鉴族（见 `../codex/`）为 PlayerItem 单列一本，记录静态文案；与当前**持有**的 `List<PlayerItem>`（含剩余使用次数）是两回事。Source: 同上。

> 具体的使用次数模型、可购字段等共有属性见 `common-properties.md`。

## 决策(-> ADR)
> _已定案的决定链接到 50-decisions/ADR-####。_

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **道具定义 vs 交易机制切分（handoff Open question）：** shop（Exchange）既是**获取机制**（→ `adventure-event/exchange/`），又产出**可购道具**（→ 本处）。当前把**道具定义**归 player-item、**交易机制**归 adventure-event/exchange；是否需要更清晰的切分待确认。Source: `10-handoffs/2026-07-24-docs-restructure-class-model.md`。
- **PlayerItem 机制未设计。** 除「账号级 + 有使用次数限制」外，道具种类、使用次数模型、获取 / 补充 / 消耗、效果、可购价格 / 库存均未设计。

## 对应
提炼至：`.claude/knowledge/systems/player-profile/player-item/`（待建）。
