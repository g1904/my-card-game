# adventure-event / research（AdventureEvent-Research）

> 闭关：玩家**调整 / 升阶自己的卡组**。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **闭关（Research）= 玩家调整 / 升阶自己的卡组。** 一种非战斗 AdventureEvent 子类型，走事件式结算；语义上是角色静修钻研，机制上是**轮回内构筑的落点**——升阶 / 弃置 / 学新功法都发生在这里。见 `systems/character-profile/deck/_index.md`。
- **开局那个强制的构筑事件归 Research。** 起始批次中**必有一个强制事件**，让玩家选**一门功法**与**一件法宝**（各三选一）——形态取 Slay the Spire 第一章的味道。它是 Research 的一个条目，**不需要第六类**；承载机制是既有的 `eventPriority = 1`（本批有效可选集收窄为该档），**不新增机制**。**推论：Research 既定起手形状（开局），也承担整个轮回的多轮构筑（途中）**——两者是同一类事件的两种编排。
- **Research 不可被 Explore 遮罩。** 卡组编辑是玩家主动规划的动作，把它藏在未知后面只制造挫败，不制造张力。见 `../explore/_index.md`。
- **不单列「休养 / Rest」。** 休养语义并入 战斗 或 闭关——闭关承担其中的静养 / 修整语义。见 `systems/adventure-event/_index.md`、`terminology.md`。
- **闭关比常规事件耗时更长。** 这是寿元定价上的一条既定差异：定价表里 Research 的 `lifeSpanCost` 高于常规事件。表的形态与取值归 `systems/balance.md`。

Source: `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md` · `handoffs/2026-08-12f-cultivation-technique-deck-building.md` · `handoffs/2026-08-15c-event-type-collapse-and-batch-shape.md`

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- **Research 为五类分类法之一，语义 = 调整 / 升阶卡组；休养并入闭关（或战斗）；开局强制构筑事件归 Research** → `decisions/ADR-0002-adventure-event-taxonomy.md`。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **卡组操作的具体清单与代价：** 升阶 / 弃置 / 学新功法各自的规则（一次事件能做几次操作？可选范围如何生成？是否有额外的资源代价？）未定。→ `systems/character-profile/deck/`。
- **除卡组外是否另有产出：** 回复 `lifeTotal`？推拉隐藏属性？领悟法则？未定——若有，需与「Research = 调整卡组」的收窄语义划清边界。
- **开局构筑事件的候选生成：** 功法 / 法宝各三选一的候选池从哪来、是否受 seeded RNG 与 PlayerPower 影响未定。→ `systems/services/future-event-service.md`、`systems/character-profile/deck/_index.md`。

## 对应
提炼至：`.claude/knowledge/systems/adventure-event/research.md`（待建）
