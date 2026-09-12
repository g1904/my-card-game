# ADR-0134 — 灵石 ≈ 战利品：战斗是主产出口，Travel 禁令扩至三个 key

- **状态：** Accepted
- **日期：** 2026-09-05
- **来源：** handoffs/2026-09-05-currency-acquisition-and-pricing.md · handoffs/2026-09-12-spirit-stone-budget-and-combat-count.md

## 背景

灵石的产出通道此前只有一处给出过取值（战斗 `BaseReward` + 道念差 × `rewardPerMomentum`），其余四类 AdventureEvent 既无一句禁止也无一句允许。要反推 25 格定价表的初值，必须先把「一章能拿到多少灵石」钉成一个形状可控的量——而这要求产出渠道是**已枚举的**，不是「哪个条目想给就给」。

Travel 侧另有一处结构性缺口：既有禁令「Travel 条目不得产出 `LifeSpan`」的理由是**换图的代价不得被同一事件抵消**，而同一条理由对货币逐字成立，禁令却只覆盖寿元。

## 决策

**灵石的渠道口径：`Combat`（三档）是主产出口，非战斗事件默认不给。**

| 事件类型 | 灵石产出 |
|---|---|
| `Combat` | **主产出口**：`BaseReward` + 道念差 × `rewardPerMomentum` |
| `Research` · `Exchange` · `Travel` · `Explore` | 不给 |

- **`OutcomeRule.FixedResource` 的可写 key 白名单不改**；口径由编排纪律 + 一条加载期**软**检查约束（非 `Combat` 类型默认不填货币产出，例外须在条目注释中给理由）。
- **Travel 的禁令谓词由 `ResourceKey == LifeSpan` 扩为 `ResourceKey ∈ { LifeSpan, SpiritStone, ImmortalJade }`，`Direction == Gain` 那一半原样保留**——Travel 条目的货币**扣减**向（「路上被劫走灵石」）是合法编排。
- **篇章缩放落在「给多少」而非定价表**：`S(c)` = 篇章标准战斗灵石给予量（书写口径），三档偏置 `Practice ≈ 0.5 × S`、`Finale ≈ 2.0 × S`。**货币量写绝对整数，不引入档位枚举。**

逐格取值、`S(c)` 三章数值与校验表 → `systems/balance.md`「货币产出与定价」；校验 6 的谓词 → `systems/adventure-event/common-properties.md`。

## 理由

- **它把灵石收入钉在「战斗场数」这个已知且近似恒定的量上**（11 / 11.9 / 14，含 Finale），而定价表不设篇章维（`decisions/ADR-0133-currency-carries-across-chapters.md`）恰恰要求收入的形状可控。
- **逐类型的否决理由各自独立成立：** `Exchange` 是消费点，在消费点发钱等于给定价表打一个不可见的折，两条曲线都失去可反推性；`Explore` 解析为真身、产出随真身走，本身再给一份即双记；`Research` 不给是既有定案。
- **不改白名单**：改它会连带动仙玉的唯一通道（稀有 AdventureEvent 产出），代价远大于收益。
- **不引入档位枚举是有依据的例外，不是疏漏。** 既有三处枚举先例（`ExperienceGrade` / `HiddenStatGrade` / `SelectionWeightGrades`）要枚举，是因为同一个数在不同篇章意义不同、必须先归一化；货币恰恰相反——定价表不设篇章维 ⇒「40 灵石」在三章买到的是同一格商品 ⇒ 绝对值本身跨章可比。
- **Travel 扩禁令是纯加法、零字段增量**，且理由是既有禁令那一条的逐字延伸。

## 备选方案

- **收紧 `OutcomeRule.FixedResource` 白名单以机械禁止非战斗产出** — 否决：白名单同时是仙玉的唯一通道，收紧它会把仙玉一并禁掉。
- **Travel 禁令连 `Direction` 谓词一起改写** — 否决：会连带禁掉合法的货币扣减向 outcome（「路上被劫」），而那正是 Travel 该有的风味。
- **由 `Finale` 另发一笔篇章收口奖励** — 否决：`Finale` 的 `BaseReward` 本就是战斗货币通道的一部分（拿 `2.0 × S`），另设一条等于对同一场战斗重复记账；且 ch3 的 `Finale` 是轮回终点，那一笔确实无处可花。

## 后果

- 非 `Combat` 类型的条目**默认不填货币产出**；例外由加载期软检查看住并要求条目注释给理由 → `systems/balance.md` 校验表。
- 篇章经济差异**只能**通过 `S(c)` 表达，不得通过定价表达 → 承 `decisions/ADR-0133-currency-carries-across-chapters.md`。
- `Travel` 条目永久不可产出寿元与两种货币 → `systems/adventure-event/common-properties.md` 校验 6、`systems/adventure-event/travel/_index.md`。
- 放弃了「用事件产出微调经济节奏」这一手段：所有经济旋钮收敛到 `S(c)`、`rewardPerMomentum` 与定价表三处。
