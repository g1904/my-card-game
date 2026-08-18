# `EventOption` 的物化字段清单：一条物化判据 + 产出侧定稿载体 `OutcomeSpec`

- id: 2026-08-17i-event-option-materialized-fields
- date: 2026-08-17
- topic: systems/services/future-event-service.md · systems/adventure-event/common-properties.md · systems/architecture.md · systems/services/life-cycle-service.md · systems/services/plot-manager.md · systems/services/profile-service.md · systems/adventure-event/combat/_index.md · systems/balance.md · decisions/ADR-0002-adventure-event-taxonomy.md
- status: distilled
- distilled-to: systems/services/future-event-service.md, systems/adventure-event/common-properties.md, systems/architecture.md, systems/services/life-cycle-service.md, systems/services/plot-manager.md, systems/services/profile-service.md, systems/adventure-event/combat/_index.md, systems/balance.md, decisions/ADR-0002-adventure-event-taxonomy.md

## Intent（distilled）

`AdventureEventData` 是模板，「多数具体属性由 future-event-service 依情境物化产出」——但「多数」这个词一直没有闭合的清单。本次不逐字段拍板，而是**给清单一条判据，再把判据指出的缺口补上**。

### 1. 收口方式 = 一条物化判据

快照面早已用一条判据收口（「重算不出来的存」）；物化面照抄这个形状：

> 凡满足下列任一条的落 `EventOption`，三条皆不满足的留在模板侧：
> ① 由 seeded RNG 掷定；② 由情境代入而定（角色状态 / 篇章 / location / `PlotModulation` 参与，模板上只有参数空间）；③ 物化时组装 / 变换而成。
>
> 反向的硬边界：文本类字段一律留模板；随 flags 变且无消费方的不落实例。

两条判据是孪生的，分工不同——**物化判据答「这一格在不在定稿实例上」，快照判据答「这一格要不要再抄进 `PastEventEntry`」**。二者取值可以不同：`ExchangeStock` 在定稿实例上，痕迹侧却只靠 `AppliedChange` 记账。

**收益：日后新增一类专有物化字段走判据即可，不再重开「清单闭合了吗」。**

### 2. 缺口 A：产出侧的定稿载体 `EventOption.OutcomeSpec`

按判据逐格核过，产出侧（outcome / effect）**没有任何一格承载**，而 `Source.EventOutcome` 的定义写的是「从物化后的 `EventOption` 的 outcome 定义算出的授予」——今天的通用结算器无处可读。故 `EventOption` 增一格 `EventOutcomeSpec OutcomeSpec`。

**固化时点分两档（承重结论）：**

| | 什么 | 何时定 |
|---|---|---|
| 抽取 / 权重 | 从哪个池抽哪一条、掷出几个、哪一档 | **物化时掷定，落定稿实例** |
| 条件 / 分支 | 依结算走向的分支、经验的失败折算、读隐藏属性当前值作输入 | **结算时求值** |

「不固化」不等于「留一张权重表到结算时再掷」——**条件分支两侧的取值都已定稿，结算时只选一侧、不掷骰**。

三条理由全是既有纪律的直接推演：产出侧同受防重掷约束（现掷则退出重进可重掷）；同受「不得回查模板重算」约束（overlay 热更下呈现与结算会读到不同数据）；`AppliedChange` 只记施加后的最终账，而决策点需要一份施加前就已定稿的候选。

**顶层按结算走向分侧（`OnResolved` / `OnFailure`），不按事件类型分侧**——与「授予来源的分野判据 = 谁组装出这条 element」同一条判据。**内部分解不在本次范围**，归「效果关键字体系与目标规则」那次专门 handoff。

**结算走向映射**：`Resolved` / `CombatWon` → `OnResolved`；`Draw` → `OnResolved`（对齐「平：只发 `baseReward`、不扣 `lifeTotal`」）；`CombatLost` → `OnFailure`；`Aborted` → 两侧皆不施加。

**Combat 类的产出边界**：`OutcomeSpec` 只承载隐藏属性推拉 + 经验档 + 事件级产出；**战斗战利品恒不进 `OutcomeSpec`**，走 `EncounterSpec.BaseReward` / `RewardPoolId` → `Spoils`。

**代价明写（被接受）：** 一批 3–5 个选项的产出全部预掷 ⇒ 未选项白掷。这与 `SelectCost` / `ResearchSlots` / `ExchangeStock` 在未选项上白算完全同构，不是新代价。

### 3. `lifeSpanCost` = 定值，不带区间、不带公式

三条既有设计各自独立地否掉区间与公式：它是时长旋钮而区间损害反推精度；Band 0 / Band 1 不显示成本 ⇒ 方差不可感知；公式撞上「内容侧不落裸数字」范式，且运行期变异已有 `ModifierKey.LifeSpanCost` 一条通道。

形态：模板侧一个非负整数（不填 = 取定价表那一格；可填偏移 / 更小的覆盖值，Explore 禁填），物化取负填 `ChangeElement.BaseValue`。**变异位共三个且无一新增。**

配套的呈现纪律：Band 2 的精确扣减量取 `ApplyModifier(LifeSpanCost, …)` 的**只读查询**结果，不写回定稿实例——只读查询不构成第二个施加点，写回则打两次折。

### 4. `combatTier` 两处都不加，走 `EventId` 溯源

tier 是模板常量而非物化产物（`EnemyData` 不带、`PlotModulation` 写不出、赋级带对三档一视同仁），物化判据一条都不命中。呈现与履历两个消费方本就要按 `EventId` 查模板取显示名，tier 在同一次查表里免费拿到；剧本条件填 `PlotCondition.EventResolved` 的 `EventId` 即可。额外收益：Explore 遮罩纪律少一个守点。

**与 `PastEventEntry.EventType` 的口径不对称须明写理由**：`EventType` 存的是**当时呈现给玩家的口径**（Explore 时与真身不同，是一条独立事实）；tier 无此分叉。

唯一退化情形：条目在新 `contentVersion` 被删 ⇒ 痕迹降级为「仅标识可读」，tier 与显示名一同丢失，不构成额外损失。

### 5. `Priority` 保留 `int`

塌缩为 `bool` 要连改三处（含存档字段 `PastEventEntry.Priority`），日后需要第三档时是一次真实迁移；保留的成本是零。「让类型说实话」由**物化组装后断言 `Priority ∈ { 0, 1 }`** 兑现。

**不设加载期校验。** 「`Priority` 是非模板字段，内容作者不得填」这条纪律**没有可实现的检查形态**——它从不是 `AdventureEventData` 上的 `[Export]` 字段，一个不存在的字段没有「检出它出现了」的机制。纪律靠文字与「置位方唯一」保证。

### 6. `PlotModulation` 复核：不为新增物化格扩字段

逐格核过：产出侧载体属模板 outcome 定义的物化产物，给剧本字段去改它等于开「改模板字段」的口子（正确形态是 `EventWeights` 换池）；`SelectCost` / `Priority` / Travel 参数 / Research 候选池 / Exchange 库存均落在约束面或「换池才是唯一合法表达位」那一侧。

**并把复核的判据写进 `plot-manager.md`**，使字段面不必随清单每次增长再复核一遍：**落内容面 → 已有字段够用；落约束面或模板字段面 → 不加字段。**

## Clarifications（interview 产物）

- **`EventOutcomeSpec` 的内部字段面写不写进活文档？** → **不写。** 原始草稿给了一段含 `int FailureRatio`（百分比、默认 50）与 `HiddenStatPush` / `ReplacementOffer` 两个类型名的示意代码；活文档只落「载体存在 + 固化时点 + 顶层按结算走向分侧」，内部分解留待定。这推翻了草稿「具体形态」小节的可定稿意味——那段代码是示意，逐字抄进活文档等于在一份声明「不定内部形态」的方案里把内部形态定了，且会顺手改掉经验失败折算既有的 `0.5` 比率口径，并引入两个全库零定义的类型名。**既有 `0.5` 比率口径一字不动。**
- **字段名取 `Outcome` 还是 `OutcomeSpec`？** → **`OutcomeSpec`**（类型仍 `EventOutcomeSpec`）。草稿写的是 `Outcome`，与 `PastEventEntry.Outcome`（`EventOutcome` 枚举）、`Source.EventOutcome` 三重撞名，而三者在同一条链路上被同时提及。
- **两侧分法与四值 `EventOutcome` / 三值 `CombatOutcome` 的映射？** → **明写映射表**（`Draw → OnResolved`、`Aborted → 两侧皆不施加`）。草稿未写，留着会让一个可机械判定的分支变成实现分歧。
- **Combat 类的 `OutcomeSpec` 与 `Spoils` / `EncounterSpec` 的分工？** → **明写边界**：`OutcomeSpec` 装隐藏属性推拉 + 经验档 + 事件级产出，战利品恒走 `EncounterSpec` → `Spoils`。草稿一字未写。
- **「加载期校验 `Priority` 非模板字段」保不保留？** → **删掉**，只留物化后断言 + 文字纪律。草稿把它列进校验表，但它没有可实现形态。
- **`PlotModulation` 的字段数？** → **维持六字段**（`TypeWeights` / `EventWhitelist` / `EventWeights` / `EnemyPoolScope` / `LevelBias` / `Tighten`）。本次只补判据，不动字段面。

## Open questions

- **`lifeSpanCost` 一律定值 `[采纳推荐 — 待复核]`。** 否决区间旋钮的理由（Band 0 / Band 1 不显示成本 ⇒ 方差不可感知；时长旋钮反推精度）成立与否待实测复核。
- **`EventOutcomeSpec` 的内部字段面。** 顶层载体与固化时点已定；内部分解阻于「效果关键字体系与目标规则」那条待答项。
