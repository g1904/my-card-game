# adventure-event / social（AdventureEvent-Social）

> 社交：与 NPC / 势力的社交互动。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **社交（Social）= 与 NPC / 势力的社交互动。** 一种非战斗 AdventureEvent 子类型，走事件式结算。Source: `20-systems/adventure-event/_index.md`、`terminology.md`。
- **抉择驱动、影响未来状态。** 与整体 AdventureEvent 意图一致：呈现事件 / 选择（月圆之夜式），后果影响玩家及未来状态，底层可推拉隐藏属性。Source: `20-systems/adventure-event/_index.md`。

## 决策(-> ADR)
> _已定案的决定链接到 50-decisions/ADR-####。_

- **Social 为分类法第五类** → `50-decisions/ADR-0002-adventure-event-taxonomy.md`。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **NPC / 势力模型：** NPC / 势力如何定义（数据资源？）、好感 / 关系度是否有持久数值、跨 run 是否留存未定。
- **社交结果：** 产出（道具 / 卡牌 / 剧情分支 / 隐藏属性推拉）、是否触发 AdventurePlot 分支未定。→ `20-systems/services/plot-manager.md`。

## 对应
提炼至：`.claude/knowledge/systems/adventure-event/social.md`（待建）
