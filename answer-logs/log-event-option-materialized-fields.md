# Answer log event-option-materialized-fields

- 日期：2026-08-17
- 来源：`inbox/solution-draft-event-option-materialized-fields.md` → `handoffs/2026-08-17i-event-option-materialized-fields.md`
- 移出条数：4

**`EventOption` 的完整物化字段清单如何收口** → 不逐字段拍板，改由一条**物化判据**收口（① seeded RNG 掷定 / ② 情境代入而定 / ③ 物化时组装或变换；三条皆不中留模板侧；文本类字段是反向硬边界）。它与快照判据是孪生的两条，分工是「在不在定稿实例上」vs「要不要再抄进 `PastEventEntry`」。按判据核过只缺两格：产出侧载体（本次答定，见下）与 `EncounterSpec` 的承载（归「物化后敌人实例的类型形态」那条待答项）。（`systems/services/future-event-service.md`、`systems/adventure-event/common-properties.md`、`systems/architecture.md`）

**outcome 权重是否在物化时固化** → **是，全部固化。** `EventOption` 增一格 `EventOutcomeSpec OutcomeSpec`：抽取 / 权重（从哪个池抽哪一条、掷出几个、哪一档）在物化时掷定并落定稿实例；条件 / 分支在结算时求值，但**两侧取值均已定稿，结算时只选一侧、不掷骰**。顶层按结算走向分侧（`OnResolved` / `OnFailure`），映射为 `Resolved` / `CombatWon` / `Draw → OnResolved`、`CombatLost → OnFailure`、`Aborted → 两侧皆不施加`；Combat 类的 `OutcomeSpec` 只装隐藏属性推拉 + 经验档 + 事件级产出，战利品恒走 `EncounterSpec.BaseReward` / `RewardPoolId` → `Spoils`。连带：三处 resolver 注释由「读模板上的 outcome / effect 定义」改为「读物化后 `EventOption` 上的定稿 `OutcomeSpec`」，`Source.EventOutcome` 的定义不动。**内部字段面未答定**，作为新条目留在待答清单。（`systems/services/future-event-service.md`、`systems/architecture.md`、`systems/services/life-cycle-service.md`、`systems/adventure-event/common-properties.md`）

**`lifeSpanCost` 的数据形态** → **一个非负整数定值**，不带区间、不带公式（不填 = 取定价表那一格，可填偏移 / 更小的覆盖值，Explore 禁填；物化取负）。变异位共三个且无一新增。定价表因此不设区间列。**标 `[采纳推荐 — 待复核]`**：否决区间旋钮的理由待实测复核，该项同时留在待答清单。连带答定：Band 2 的精确扣减量取 `ApplyModifier` 的**只读查询**结果，只读查询不构成第二个施加点。（`systems/adventure-event/common-properties.md`、`systems/balance.md`、`systems/services/profile-service.md`）

**`PlotModulation` 的字段面是否还需扩** → **不扩，维持六字段**，并把复核的判据写进 `plot-manager.md`：新增一格物化字段时，落**内容面**（哪些条目进池、以什么权重出现、用哪个敌人池、带内赋级权重、遭遇参数）→ 已有字段够用；落**约束面或模板字段面** → 不加字段。有了判据，字段面不必随物化清单每次增长再逐格复核。（`systems/services/plot-manager.md`）

**部分答定的说明：**

- **`Priority = 1` 依什么条件抬升**只答定了其中一半——**字段保留 `int`、不塌缩为 `bool`**，由物化组装后断言 `Priority ∈ { 0, 1 }` 兑现「让类型说实话」，并删掉「加载期校验 `Priority` 非模板字段」这条不可实现的检查。**其余（依什么条件抬升、同批多个 `1` 档是否需额外收窄规则）仍留在待答清单。**
- **`combatTier` 的落点**由本次答定为「`EventOption` / `PastEventEntry` 两处都不加，走 `EventId` → 模板溯源」，`decisions/ADR-0002` 尾部同名待办随之改写为正面陈述。
