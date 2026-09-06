# 两种货币的产出曲线与定价初值：灵石 = 战利品、仙玉 = 稀有事件，货币跨篇章结转

- id: 2026-09-05-currency-acquisition-and-pricing
- date: 2026-09-05
- topic: systems/balance.md · systems/character-profile/currency.md · systems/adventure-event/exchange/_index.md · systems/adventure-event/common-properties.md · systems/adventure-event/travel/_index.md · systems/adventure-event/combat/_index.md · systems/services/life-cycle-service.md · terminology.md · decisions/ADR-0089
- status: distilled
- distilled-to: systems/balance.md, systems/character-profile/currency.md, systems/adventure-event/exchange/_index.md, systems/adventure-event/common-properties.md, systems/adventure-event/travel/_index.md, systems/adventure-event/combat/_index.md, systems/services/life-cycle-service.md, terminology.md, decisions/ADR-0089-two-tier-currency.md

## Intent（distilled）

**一句话：** 灵石是战利品（战斗是主产出口，非战斗事件默认不给），仙玉是稀有事件的标志性产出（每章 1–2 次、单次 1 / 2 / 4 枚）；两种货币**跨篇章结转、与寿元同形**；25 格定价表按「族系数 × 稀有度基价」给出初值，仙玉只落在四族的高档位、**一格都不落可售出的 `CharacterItem` 族**。

### 1. 货币贯穿轮回，不每章重置

两种货币与寿元自此**同形**：随轮回清理，但**跨篇章结转**，篇章边界不做任何清零动作。

- **它不需要任何新机制。** 篇章边界原先没有货币清零职责、存档点清单里没有这个落点、`CharacterProfile` 上也没有篇章维的货币字段——「每章重置」这条措辞在全库零机制承载，改为结转即让措辞与机制对齐，`ChapterManager` 一行代码都不用加。
- **它使「省着花有跨篇章回报」对货币逐字成立**，与寿元结转同一条激励结构。
- **它给定价表「不设篇章维」换了一条更强的理由**：跨章结转要求价格跨章稳定——若同一件东西在 ch3 更贵，攒下来的余额会被通胀稀释，激励当场失效。

### 2. 标定分母：`I(c)` / `I_cum(c)` / `J(c)` / `J_cum(c)` 是书写口径，不是运行期字段

照回寿量「占本章预算百分比」的先例：作者按它标定定价表，运行期不读取。

```
I(c)     = Σ 本章战斗 BaseReward 灵石量 + Σ 道念差 × rewardPerMomentum[SpiritStone][c] + Σ 事件 outcome 灵石产出
I_cum(c) = Σ_{k ≤ c} I(k) − 已花销          ← 结转口径下，购买力的真实分母
```

`I(c)` 校准「本章掉多少」，`I_cum(c)` 校准「玩家此刻买得起什么」。仙玉侧同构（`J(c)` / `J_cum(c)`）。

### 3. 灵石的渠道口径：战斗是主产出口

| 事件类型 | 灵石产出 |
|---|---|
| `Combat`（三档） | **主产出口**：`BaseReward` + 道念差 × `rewardPerMomentum` 线性加成 |
| `Research` | 不给（既有定案） |
| `Exchange` | 不给——它是消费点，在消费点发钱等于给定价表打一个不可见的折，两条曲线都失去可反推性 |
| `Travel` | 不给，并补一条结构性禁令（见 5） |
| `Explore` | 不单独给——它解析为真身，产出随真身走，本身再给一份即双记 |

⇒ **灵石 ≈ 战利品。** 好处是它把灵石收入钉在「战斗场数」这个已知且近似恒定的量上（7 / 8 / 8），而定价表无篇章维恰恰要求收入形状可控。

`OutcomeRule.FixedResource(SpiritStone)` 白名单**不改**（改它会连带动仙玉的唯一通道），改以编排口径 + 一条加载期软校验约束：非 Combat 类型默认不填货币产出，例外须在条目注释中给理由。

### 4. 篇章缩放落在「给多少」，不落定价表

`S(c)` = 篇章标准战斗灵石给予量（书写口径）：ch1 **15** · ch2 **35** · ch3 **60**；三档偏置 `Practice ≈ 0.5 × S`、`Finale ≈ 2.0 × S`。

**货币量不引入档位枚举，就写绝对整数，且这不是疏漏。** 既有三处枚举先例（`ExperienceGrade` / `HiddenStatGrade` / `SelectionWeightGrades`）之所以要枚举，是因为同一个数在不同篇章意义不同、必须先归一化再映射；**货币恰恰相反：定价表不设篇章维 ⇒ 「40 灵石」在三章买到的是同一格商品 ⇒ 绝对值本身就跨章可比**，再套一层档位只是把一个已经可比的数拆成两个书写位。这与回寿量三档「是量值口径不是新枚举」同向——两者同为走资源 element 路径的绝对量值。

### 5. Travel 补一条货币产出禁令

既有禁令「Travel 条目不得产出 `LifeSpan`」的理由是**换图的代价不得被同一事件抵消**。同一条理由对货币逐字成立，而当前禁令只覆盖寿元——Travel 结构上可以给灵石，全库无一句禁止也无一句允许。

⇒ 校验 6 的谓词由 `ResourceKey == LifeSpan` 扩为 `ResourceKey ∈ { LifeSpan, SpiritStone, ImmortalJade }`，**`Direction == Gain` 那一半原样保留**——Travel 条目的货币**扣减**向（「路上被劫走灵石」）是合法编排，不在禁止之列。纯加法，零字段增量。

### 6. 定价表 25 格初值：族系数 × 稀有度基价

表结构不变（仍是 25 个独立整数），只是初值来源可解释：稀有度基价逐档 ×2（20 / 40 / 80 / 160 / 320），族系数 `Card 0.75 · CharacterItem 1.0 · CharacterPower 1.5 · CultivationTechnique 2.0 · PlayerItem 2.5`。

### 7. 仙玉：每章 1–2 次、单次 1 / 2 / 4 枚，且不落可售出族

- **频次载体是既有的 `SelectionWeightGrades.Rare` 档**，不加字段、不加校验。
- **币种分布把净产出敞口结构性关掉**：可售出 ⟺ `ExchangeGoodsKind == CharacterItem` 是代码级常量判据 ⇒ **只要仙玉一枚都不落在 `CharacterItem` 行，「售出产仙玉」就不可能发生**，无需统计盯防。在仙玉预期收入只有个位数、而回收价有 `Clamp >= 1` 下限的量级上这尤其要紧：3 枚定价 × 40% = 1.2 → 1，任何一件免费掉落的仙玉法宝都稳产 1 枚，占一章收入的 20–50%。
- **代价如实写下：从此编排不出「以仙玉计价的法宝」**，包括补天丹类顶级消耗品——它们只能以灵石计价。这是在「币种与族 × 档绑死」这条既有代价之上再收一格。

### 8. 两档回收率初值

`SellRatePercent` 默认 **40%**（可编排区间 30–50）· `PackSellRatePercent` **15%**。15% 使「清仓不构成经济来源」成立：一件 Tier2 法宝（40）随售得 6，不足半次购入；商店收购（16）恒显著更优，由既有硬校验保证。

### 9. 载体：新开一份 `ExchangePriceTableData`

按平衡资源的三问判据（消费者 / 覆写纪律 / 跨字段不变式）：25 格 `(Currency, BasePrice)` 与 `PackSellRatePercent` 的消费者是 Exchange 物化与随售折算，**两者共用同一张基准价表 ⇒ 跨字段不变式 ⇒ 必须同住一份**。形状照 `LifeSpanCostTableData`：具名字段 + 内嵌 `Resource` 行类型 + 加载期校验表，经 `Content.Single<T>()` 取。灵石产出侧**不新开资源**——`S(c)` 是书写口径不是字段，`rewardPerMomentum` 已有归属。

## Clarifications（interview 产物）

本次**未触发 interview**：草稿以 `status: decided` 进入，两项真取向已在 2026-09-05 的评审中由用户裁决，其余各节草稿自带 `[既有推演]` / `[通行做法]` 标注，经复核确属可推演项。

- **货币是每章重置还是贯穿轮回？** → **贯穿轮回、不每章重置**（用户裁决，取草稿的选项 B 而非其推荐项 A）。它推翻了三处「每章重置」措辞与一处否决理由，见下。
- **仙玉是否允许落在 `CharacterItem`（法宝）行？** → **不允许**（用户裁决，取推荐项）。净产出敞口结构性归零，代价是永远编排不出以仙玉计价的法宝。

**自行推演并直接落笔的项（标准默认）：**

- **「不由 Finale 发放」的结论保留，理由重立。** 原理由（「篇章收口处发放、随后即被清理，玩家拿到手也几乎无处可花」）在结转口径下整条失效。新理由：**Finale 的 `BaseReward` 本就是战斗货币通道的一部分**（它拿 `2.0 × S`），另设一条「篇章收口发放」等于对同一场战斗重复记账；且 ch3 的 Finale 是轮回终点，那一笔确实无处可花。
- **校验 6 扩写保留 `Direction == Gain`。** 只扩 `ResourceKey` 集合、不动方向谓词，否则会连带禁掉合法的货币扣减向 outcome。
- **`ADR-0089:44` 订正**：「仙玉的唯一主动获取通道是**商店**」是一处误写——商店是**花销**通道，获取通道是稀有 AdventureEvent 产出（`currency.md` 与本 ADR 的来源 handoff 均为此口径）。ADR 内部并不自相冲突，冲突方在 ADR 与系统文档之间。
- **`ADR-0089:42` 订正**：「`CostKey` 由 15 值增至 16 值」写于 08-25 时正确，是 08-30 `LifeTotal` 退役把 16 改回 15 时漏改了这一处。订正措辞保留这段算术而非简单改数字。
- **`terminology.md` 仙玉词条补「主动」二字**：08-26 那次「唯一获取通道 → 唯一**主动**获取通道」的订正在术语表这一处没落到。

## Open questions

- **`I(c)` 的道念差加成项仍是量级估算，不是定稿。** 它的两个输入（败率 20%、`E[道念差]` 5 / 12 / 18）是明令不得引为承重依据的待实测格；`I(ch1) ≈ 127` 中约 28 来自该项。道念量纲基准定案后须复核。
- **`I(ch2)` / `I(ch3)` 比 `I(ch1)` 粗一档**：ch2 / ch3 只有事件总数（26 / 32），没有逐类型构成表，两章构成表补齐后须复核。
- **「玩家在 ch1 主要遇到 Tier1–Tier2」这一购买力校验前提尚未被机械保证**——它依赖战后奖励池 / 商店库存的 `RarityTier` 分布权重，那一条仍未定，是本次标定的前置而非产物。

## Notes / triage

- 来源草稿：`inbox/archive/solution-draft-currency-acquisition.md`（`/provide-solution-draft` 产出，经用户评审裁决两项取向）。
- 本次校验推翻草稿三处主张：`ADR-0089:38` 的「自相冲突」系草稿记错（:38 是五条否决通道的列举，不含「稀有 AdventureEvent 产出」）· `balance.md` 待决第 10 条与货币无关（其「定价表」指寿元 `lifeSpanCost` 表）、第 4 条方向相反（是本方案的前置依赖）· 校验 6 的谓词是合取，草稿的扩写写法会丢掉方向位。
- 草稿漏登记、本次一并处理的四处：`exchange/_index.md` 的第三处「每章重置」镜像句 · `exchange/_index.md` 的待决条 · `open-questions/03-adventure-event-types.md` 的镜像登记 · `terminology.md` 仙玉词条。
- ADR 候选（归 `/write-adr`）：① 两种货币跨篇章结转，与寿元同形 ② 灵石的渠道口径（战斗为主产出口 · Travel 禁令扩三 key）③ 仙玉不落可售出族，净产出敞口结构性关闭。
