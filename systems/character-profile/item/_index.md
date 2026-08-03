# item

> **法宝 / CharacterItem** —— CharacterProfile 持有的、随单次轮回存在的道具（现有写法 `List<CharacterItems>`），含道具设计内容。占位结构，细节待定。
> **中文定名 = 法宝**（08-03 定，取代「角色道具 / 角色物品」）；账号级的对应物是 **古宝 / PlayerItem**。**中文名不表达层级**。**标识符的单复数待统一**（`CharacterItem` vs `CharacterItems`），见待决问题。Source: `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md`。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **角色级道具随轮回存在。** CharacterProfile 持有 `List<CharacterItems>`（角色物品），与账号级的 **PlayerItem**（`player-profile/player-item/`）区分开：CharacterItems 属单次轮回 / 单角色，随轮回清理；PlayerItem 跨轮回持久、有使用次数限制。Source: `handoffs/2026-07-24-docs-restructure-class-model.md`。

- **见过的角色道具会进 CharacterItemCodex。** 图鉴族（见 `../../player-profile/codex/`）为角色道具单列一本——**图鉴是账号级、跨轮回持久的**，而 `List<CharacterItems>` 随轮回清理：轮回结束后道具没了，但「见过它」这条知识留下。解锁触发（获得即记？见到即记？）未定，见图鉴族的待决问题。Source: `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。

> 本文件夹为「每类角色道具 / 每份道具设计一个 Markdown」预留结构；具体语义见 `common-properties.md` 与待决问题。

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **`CharacterItem` 的标识符单复数不一致（08-03 新增）。** 中文定名「法宝」对应 `CharacterItem`（单数），但全库既有写法是 `List<CharacterItems>`（复数）。是否统一为 `CharacterItem` 未定。→ `terminology.md`。Source: `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md`。
- **角色级道具语义未设计。** 除「CharacterProfile 持有 `List<CharacterItems>`」这一持有关系外，道具的种类、获取 / 消耗 / 效果、与卡牌 / PlayerPower / PlayerItem 的边界均未设计，需一次 handoff。

## 对应
提炼至：`.claude/knowledge/systems/character-profile/item/`（待建）。
