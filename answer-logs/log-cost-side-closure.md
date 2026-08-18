# Answer log cost-side-closure

- 日期：2026-08-16
- 来源：`inbox/archive/solution-draft-cost-side-closure.md` → `handoffs/2026-08-16d-cost-side-closure.md`
- 移出条数：3（全部来自 `open-questions/02-event-options.md`）

三条同属 `selectCost` 成本侧的**同一条语义链**，一起答——分开答会各自定出互不自洽的规则。

---

**寿元打穿后怎么办（负值施加的钳制规则 · 承重）** → 钳制建模为一张**封闭表** `ResourceClamps: CostKey → ClampSpec(Min, Max, DepletionDefeat)`，而非「资源一律截断到 0」这样一条通则——已有的三个区间（残卷 `[0, 10000]`、道心 / 煞气 `[0, 100]`、寿元 `[0, ∞)`）互不相同且都不由任何通则给出，而「触底是否构成终态」也逐 element 不同，故与取值域并成同一张表的两列。首批三行：`LifeSpan (0, null, LifeSpanExhausted)` · `Jade (0, null, null)` · `LifeTotal (0, null, LifeTotalExhausted)`。**寿元截断到 0、不允许为负**（Band 2 的精确余量是寿元唯一的精确显示通道，不能显示负数；截断后 `<= 0` 与 `== 0` 两种判据同解；跨篇章结转要求它是非负预算）。**表落代码常量、不落 `.tres`**（三列没有一列是平衡旋钮，落 `.tres` 会让一次 overlay 热更改写终态判据）。**spec 与快照记未截断的原值**，截断只发生在施加到 Profile 字段那一刻，从而保住 `AppliedChange`「可直接重放的账」并免费保留「超支了多少」。`ApplyResult` **不**新增触底 element 字段。
（归档去向：`systems/architecture.md`「共享核心类型」· `systems/services/profile-service.md` ProfileManager 小节 · `systems/services/life-cycle-service.md` 终态判定 · `systems/character-profile/currency.md` · `life-total.md`；`mana.md` 补一句「`Min = 0` 是取值域、不是被否决的下界护栏」）

**「余额不足即拒」还剩哪些消费点** → 三样东西按「有无消费点」分开处置，不打包。**删除** `AdvanceStage.CostRejected` 与 `AdvanceResult.MissingElement`——事件推进路径已定「无条件施加、不做付得起校验」，两者不可达，留着会诱导后来者把校验加回来。**保留** `ProfileService.CanAfford` 与 `ApplyResult.MissingElement`——Exchange 的商店购买是已定存在的消费点。**商店可灰显、事件面不可灰显出自同一条判据**：「明知做不到仍然去做」有没有意义（走死路有意义，点买不起的商品没有）。呈现形态待 Exchange 专场。
（归档去向：`systems/services/life-cycle-service.md` API 面 · `systems/services/profile-service.md` API 面 · `systems/adventure-event/exchange/_index.md`）

**遮罩下的 `selectCost` 呈现** → **问题的前提不成立**：支付先于揭示（`TryApply(SelectCost)` 排在 `eventStart` 的 Explore 揭示之前），被施加的必然是 Explore 模板物化出的那一份，真身模板的成本字段从头到尾不在链路上，`PastEventEntry` 也只有一份 `SelectCost`。故不是「二选一」而是「只有一份」，展示侧没有泄漏面。泄漏面转到**定价侧**，由两条纪律封死：Explore 在 `lifeSpanCost` 定价表上**自成一行且不得由真身推导**；Explore 条目**禁用条目级成本覆盖值**（加载期校验 `PushError` + `Id`）。物化组装后另加一条断言「不读真身成本字段」。
（归档去向：`systems/adventure-event/explore/_index.md` · `systems/adventure-event/common-properties.md`）

---

## 一并记下的两处（不计入移出条数）

- **interview 裁决：** `AdvanceResult.MissingElement` 一并删除（草稿只表态了 `ApplyResult` 上的同名字段），`AdvanceResult` 收窄为 `(Success, FailedAt, StatusAfter)`。
- **草稿误读的一条论据已按既有权威改写：** 草稿称道心 / 煞气是「双向量」，而 `life-cycle-service.md` 早已明写两者截断到 `[0, 100]`。结论不变——`[0, 100]` 反而是「必须配表」的又一例证。
