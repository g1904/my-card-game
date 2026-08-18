# Answer log combat-finale-and-hidden-attributes

- 日期：2026-08-17
- 来源：`inbox/solution-draft-combat-finale-and-hidden-attributes.md` → `handoffs/2026-08-17e-finale-combat-only-and-hidden-stat-io.md`
- 移出条数：2

---

**非战斗形态的 Finale。**（哪些境界突破走非战斗路径、其结算形态如何、仍是 Combat 类特例还是另起路径）
→ **不存在该形态。全部 Finale 均为天劫战，本作不设非战斗形态的境界突破路径。** 连带关掉四样尚未存在的分支：`EncounterSpec` 不加 `Trial` 一类字段且 `Enemy` 恒非空 · `CombatEventResolver` 无内部分派 · 不引入试炼求值 / 抉择链 / 等效道念差映射、不新建 `TrialOutcome` 一类类型 · 危险度刻度（精确标注敌人等级）三档无例外。取消一个尚未存在的分支 ⇒ 存档与契约零影响。
（归档去向：`systems/adventure-event/combat/_index.md` 的「意图」与「决策」；`systems/services/combat-service.md` 待决问题的尾巴一并收掉）

**各档与隐藏属性的交互。**（`Practice` 是否推拉道心 / 煞气 / 寿元；隐藏属性剧情线触发后是否转入 `Finale`；`Finale` 是否消耗 / 检定隐藏属性）
→ 三半各自答定：
- **推拉面**：隐藏属性对五类事件的**输入与输出两侧全开**，输入经**调制通道**（Band 触发 arc → `PlotModulation` 六字段）与**结算输入通道**承载，不新增机制。承重限定：**输入侧全开不等于接进胜负判定**——`VictoryRule` 仍是单字段，隐藏属性影响遭遇的路径是拧参数而非加一条并列判定条件。三档默认口径：`Practice` 推道心（对位低一档）· 不推煞气；`Standard` 逐条目编排；`Finale` 胜利与失败都推道心。推拉**不套用 `FailureRatio`**，胜负同施一份 `HiddenStatGrade`。
- **是否转入 `Finale`**：**不转入。** 四条理由（炸掉残卷的结构封印 · Finale 的出现条件是等级条件 · PlotManager 在数据形态上够不着 · ADR-0004 以 Finale 为篇章重试锚点）；替代形态 = 被 `PlotModulation` 拧过的 `Standard` 档 Combat，**不给残卷、不是篇章闸门、失败不影响境界突破**。附前提更正：「大限将至」对应寿元归 0 的终态、不经 `PlotTriggerId`，寿元归 0 时角色已 `defeated`，无物可转入。
- **是否消耗**：**不消耗。** `selectCost` 的 element 清单仍只有 `lifeSpanCost` 一项——成本侧只放可如实计价的量，且道心 / 煞气触底不构成终态，扣了没有消费者。「道心 / 煞气是否列入 `CostKey`」那条待答项不受本次施压，原样保留。

（归档去向：`systems/services/plot-manager.md`「意图」两条明写 · `systems/adventure-event/combat/_index.md`「三档与隐藏属性」· `systems/adventure-event/common-properties.md` 推拉口径 · `systems/balance.md` 挂钩点）

**部分留下：** 「隐藏属性的增减触发（哪些 AdventureEvent 推拉、各推哪一档）」与 `HiddenStatGrade` 映射值仍待答——本次给的三档默认口径是它的一个子集，条目已收窄措辞后留在 `open-questions/03-adventure-event-types.md`。
