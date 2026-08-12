# Answer log combat-system

- 日期：2026-08-11
- 来源：`inbox/draft-combat-system.md` → `handoffs/2026-08-11c-combat-turn-flow-fatigue-and-card-type-reduction.md`
- 移出条数：2

**先后手由谁决定。** → **由 `EncounterSpec.FirstSide`（`Side?`，可空）承载**：剧情需要时由 **future-event-service 物化 eventOption 时写入**（意图经 plot-manager 调制），**`null` 则由 combat 子流掷**，同一 seed 复现同一个先后手。combat-service 只读该字段、不问来源，**不新增服务间运行时依赖**。与既有「不设先后手抽牌差」并行不悖（那条说不做补偿，本条说谁先动）。（归档：`systems/services/combat-service.md`、`systems/adventure-event/combat/_index.md`、`terminology.md`、`systems/balance.md`）

**阵法与灵宠的区分轴。** → **问题随灵宠删除而消失**：`CardType` 由六类降为五类，**灵宠 `Creature` 整条删除**，永久物统一由阵法承载，「实体 / 非实体永久物」二分取消。原灵宠的三个次类型（灵兽 / 傀儡 / 器灵）迁为阵法的次类型。（归档：`systems/character-profile/deck/_index.md`、`deck/common-properties.md`、`systems/services/combat-service.md`、`systems/adventure-event/combat/_index.md`、`terminology.md`、`ux/combat-ux.md`）

**同批推翻的既有定案（非待答清单条目，记此备查）：**

- 「抽牌堆空时由弃牌堆重洗补充」→ **不重洗，抽空即疲劳**（每张 −1 道念）。
- 「道念的产出 / 削减不存在第二条结算通道」→ **有两条**：卡牌与疲劳。
- 起始手牌 5 → **4**；手牌上限 10 → **9**；敌人卡组固定 15（不作为物化旋钮）→ **两侧皆不设硬限**；储物袋 99 → **9**（按 `Id` 堆叠后的条目数）。
- 新增：**不设 mulligan**。
