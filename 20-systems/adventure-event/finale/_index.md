# adventure-event / finale（AdventureEvent-Finale）

> 篇章边界高潮：渡劫 / 境界突破，独立于 Combat 的结算。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **境界突破 = AdventureEvent-Finale（已定案）。** 篇章边界的境界突破定义为 **AdventureEvent-Finale**，**独立类型、区别于 Combat**，并作为**第七类正式并入 ADR-0002 枚举**。Source: `20-systems/adventure-event/_index.md`、`10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。
- **篇章边界高潮。** Finale 出现在篇章（Chapter）边界，对应修行阶梯上境界的跃迁（炼气 → 筑基 → 金丹 → 元婴）；一次轮回含三个篇章。Source: `terminology.md`（修行阶梯）、`20-systems/adventure-event/_index.md`。
- **独立结算（区别于 Combat 规则）。** Finale 走独立的境界突破结算，而非 Combat 的战斗结算——呼应「并非每个事件都是战斗」这一支柱。Source: `20-systems/adventure-event/_index.md`。

## 决策(-> ADR)
> _已定案的决定链接到 50-decisions/ADR-####。_

- **境界突破 = AdventureEvent-Finale，第七类，独立于 Combat** → `50-decisions/ADR-0002-adventure-event-taxonomy.md`（Accepted，07-23 修订）。Source: `10-handoffs/2026-07-23-...`。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **Finale 独立结算的具体机制：** 区别于 Combat 的结算规则（渡劫 / 突破的玩法形态、成功 / 失败判定、奖励与后果）属内容 / 平衡设计，未定。Source: `20-systems/adventure-event/_index.md`。
- **与隐藏属性的交互：** 「大限将至」等隐藏属性剧情线触发后是否转入 Finale、Finale 是否消耗 / 检定隐藏属性未定。→ `20-systems/services/plot-manager.md`。

## 对应
提炼至：`.claude/knowledge/systems/adventure-event/finale.md`（待建）
