# adventure-event / finale（AdventureEvent-Finale）

> 篇章边界高潮：渡劫 / 境界突破。**大部分是战斗的变体**（渡劫的对手 = 天劫，天劫是一个带定制卡组的 Enemy）；少部分非战斗形态待日后定制。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **境界突破 = AdventureEvent-Finale（已定案）。** 篇章边界的境界突破定义为 **AdventureEvent-Finale**，**独立类型、区别于 Combat**，并作为**第七类正式并入 ADR-0002 枚举**。Source: `20-systems/adventure-event/_index.md`、`10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。
- **篇章边界高潮。** Finale 出现在篇章（Chapter）边界，对应修行阶梯上境界的跃迁（炼气 → 筑基 → 金丹 → 元婴）；一次轮回含三个篇章。通过后角色进入新境界，**等级归位为新境界的初期**（见 `20-systems/game-progression.md`）。Source: `terminology.md`（修行阶梯）。
- **大部分 Finale 是战斗的变体（已定案）。** Finale 使用 combat-service 的 **CharacterManager + EnemyManager**，与 Combat 同一套回合循环与参战方模型；区别在于**独立的胜负条件与奖励结构**，而非另起一套结算代码。Source: `10-handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md`。
- **渡劫的对手 = 天劫，天劫是一个 Enemy（已定案）。** 天劫作为敌人条目存在，**带定制卡组**——这是「每个 enemy 各持有一个卡组」的直接应用。Source: 同上。
- **少部分 Finale 不是战斗。** 存在非战斗形态的境界突破，其形态**留待日后定制**，届时才需要战斗框架之外的结算路径。Source: 同上。

## 决策(-> ADR)
> _已定案的决定链接到 50-decisions/ADR-####。_

- **境界突破 = AdventureEvent-Finale，第七类，独立于 Combat** → `50-decisions/ADR-0002-adventure-event-taxonomy.md`（Accepted，07-23 修订）。
- **Finale 为战斗变体（复用参战方结构与回合循环）；天劫 = 带定制卡组的 Enemy** —— 已定案。Source: `10-handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md`。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **独立的胜负条件与奖励结构：** 复用战斗框架已定；区别于 Combat 的渡劫胜负判定（是否有额外的成功 / 失败判定层？失败是否直接 defeated？）与奖励结构未定。
- **非战斗形态的 Finale：** 哪些境界突破走非战斗路径、其结算形态如何，留待日后定制。
- **天劫的等级与意图档位：** 天劫作为 Enemy 带等级；篇章边界的天劫是否天然属于「大幅越级」（即完全无意图信息）未定——这会直接决定 Finale 的信息压迫感。→ `20-systems/services/combat-service.md`。
- **与隐藏属性的交互：** 「大限将至」等隐藏属性剧情线触发后是否转入 Finale、Finale 是否消耗 / 检定隐藏属性未定。→ `20-systems/services/plot-manager.md`。

## 对应
提炼至：`.claude/knowledge/systems/adventure-event/finale.md`（待建）
