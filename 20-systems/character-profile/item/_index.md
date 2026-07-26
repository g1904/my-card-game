# item

> 角色级道具 —— CharacterProfile 持有的、随单次 run 存在的道具（`List<CharacterItems>`），含道具设计内容。占位结构，细节待定。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **角色级道具随 run 存在。** CharacterProfile 持有 `List<CharacterItems>`（角色物品），与账号级的 **PlayerItem**（`player-profile/player-item/`）区分开：CharacterItems 属单次 run / 单角色，随 run 清理；PlayerItem 跨 run 持久、有使用次数限制。Source: `10-handoffs/2026-07-24-docs-restructure-class-model.md`。

> 本文件夹为「每类角色道具 / 每份道具设计一个 Markdown」预留结构；具体语义见 `common-properties.md` 与待决问题。

## 决策(-> ADR)
> _已定案的决定链接到 50-decisions/ADR-####。_

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **角色级道具语义未设计。** 除「CharacterProfile 持有 `List<CharacterItems>`」这一持有关系外，道具的种类、获取 / 消耗 / 效果、与卡牌 / PlayerPower / PlayerItem 的边界均未设计，需一次 handoff。

## 对应
提炼至：`.claude/knowledge/systems/character-profile/item/`（待建）。
