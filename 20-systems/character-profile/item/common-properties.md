# item —— 共有属性

> 角色级道具（CharacterItems）的共有字段与共有机制。占位结构，细节待定。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **角色道具是 CharacterProfile 的 `List<CharacterItems>`。** 唯一已确认的共有属性是它作为角色级、随轮回存在的集合被 CharacterProfile 持有。Source: `20-systems/services/life-cycle-service.md`（`CharacterProfile` 字段）+ `10-handoffs/2026-07-24-docs-restructure-class-model.md`。

## 决策(-> ADR)
> _已定案的决定链接到 50-decisions/ADR-####。_

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **共有字段未定案。** 若道具走「数据即资源」，预期会有稳定唯一 `Id`、显示名 / 描述、效果定义等（对齐 `data-resource-rules.md`）——但目前**未有任何设计**，全部为占位待定。Source: `10-handoffs/2026-07-24-docs-restructure-class-model.md`。

## 对应
提炼至：`.claude/knowledge/systems/character-profile/item/`（待建）。
