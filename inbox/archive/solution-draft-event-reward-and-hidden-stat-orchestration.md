---
type: solution-draft
date: 2026-09-09
question: Combat 三档的奖励厚薄（`RewardPoolId` / `BaseReward` 其余 element）与隐藏属性的逐条目推拉编排（三档默认 `HiddenStatGrade` + 五类事件的推拉映射 + 两条剧情线的形态）
source: open-questions/03-adventure-event-types.md:12 · :13 · open-questions/04-hidden-attributes-plot.md:9
targets: systems/balance.md · systems/adventure-event/combat/_index.md · systems/services/plot-manager.md · systems/scoring.md · systems/adventure-event/common-properties.md · systems/services/combat-service.md
status: distilled
reviewed: 2026-09-09 批量评审 + 合并 interview —— 待决 1 的问法作废（每池五档全非空，§B 池成分表整表重做）· 待决 2 维持内容池字面对称 5:5，但**所述两条后果经核算不成立**，改记为默认上漂「修行本身即精进」· **净比 η 不存在**（行程 = Σ|Δ|，直读裁定）· 携带面缩到 18–20（非草稿的「扩」）· 煞气反向 ≈9 条 / 篇章
distilled-to: handoffs/2026-09-09f-event-reward-and-hidden-stat-orchestration.md
---

# 方案草稿 — 战后奖励厚薄轴与隐藏属性推拉编排

> 本草稿是**提案**，不是定案。三个子问题同源（同一批 Combat 三档口径 + 同一套内容编排面），故合在一起提出。

## 问题

三条待答项，全部已收窄到「只欠编排口径 / 只欠取值」，但**它们悬着的不是同一类东西**：

1. **`Practice` / `Finale` 档的奖励厚薄**（`open-questions/03:12`）。`BaseReward` 的灵石量已由 `S(c)` 给出（`Practice ≈ 0.5 × S` / `Standard = S` / `Finale ≈ 2.0 × S`，`systems/balance.md:397`）。悬着的是两格：
   - **`RewardPoolId` 随档位如何调厚薄**——这是一个**机制形态选择**（换池 / 换权重 / 换抽数），不是一个数字；
   - **`BaseReward` 中其余 element 的量**。
2. **Combat 三档各推哪一档 `HiddenStatGrade`**（`open-questions/03:13`）。三档的**方向与是否推**已定（`combat/_index.md:71–75`），**档位值**未给。
3. **隐藏属性的推拉触发**（`open-questions/04:9`）。清单 / 取值域 / 档位表 / 阈值 / 回滞 / 允许面全部已定案，条目自陈「转为纯内容编排工作量」。剩下的是**逐条目的 `(Stat, Direction, Grade)` 映射**与**两条剧情线（煞气反噬 / 心魔滋生）的具体内容**。

②③ 是同一件事的两半：② 是 ③ 在 Combat 三档上的子集（`plot-manager.md:578` 明写这一点）。① 与它们共处同一个事件收口面（`eventEnd` 那一次 `TryApply` 同时装 `Spoils`、`lifeSpanCost` 与隐藏属性推拉）。

## 约束（来自既有设计）

**奖励侧：**

- 战后可选奖励**固定 3 项、逐项领取**（不是择一，`ADR-0082`），池 = 事件模板的 `RewardPoolId` 经 `AllEnabled()` 取，**四族混合**（`CardData` / `ItemData` / `CultivationTechniqueData` / `PowerData`，`ADR-0169`），本次已抽中的 `Id` 不再出。→ `systems/services/combat-service.md:591` · `:14`
- **池深度已有三道闸**（加载期断言「池 ≥ `CandidateCount` + 余量」· 取池期拦截 · 物化期降级「给几条算几条」且不给玩家提示）。→ `decisions/ADR-0073-pickmany-shortfall-three-gates.md`
- **`combatTier` 三档共用同一条生成路径，差异只在 `RewardPoolId`、`Tier`，以及 `Practice` 档对 `PowerData` 的整族排除。** → `systems/services/combat-service.md:602`
- **稀有度权重表按 `RarityTier` 五档索引、由优势档 `Tier { Narrow, Solid, Crushing }` 三档选表**；`RarityTier` 与 `Tier` **不得复用同一枚举、也不得互相换算**。→ `systems/balance.md:645`
- **优势档只影响候选池的稀有度权重，不影响候选数量（数量恒 3）。** → `systems/balance.md:644`
- **权重表的分表维度 = 按用途（授予 / 战后奖励），不按渠道、不按 `(CarrierKind, Scope)`。** → `systems/balance.md:893`
- `RewardPoolId` **挂 `AdventureEventData` 不挂 `EnemyData`**；`EncounterSpec` 的 `Tier` / `TurnLimit` / `VictoryRule` / `RewardPoolId` / `BaseReward` 全部**物化时定稿**。→ `systems/services/combat-service.md:580` · `combat/_index.md:26`
- **灵石 ≈ 战利品：`Combat` 是灵石的唯一主产出口**；`Research` / `Exchange` 不给，`Travel` 是结构性禁令，`Explore` 不单独给（产出随真身）。→ `systems/balance.md:385`–`:389`
- 已有一条加载期软校验 **C-1**：单个 `EncounterSpec.BaseReward` 的灵石量 > `2.5 × S(该篇章)` → `PushWarning`。→ `systems/balance.md:441`
- **失败侧仍发 `baseReward`**；少数条目的额外惩罚是 `Spoils` 中的负向 `ChangeElement`，不另立结构。→ `systems/services/combat-service.md:19`
- **平衡数值不硬编码、经 `Content.Single<T>()` 取；不设 `GlobalBalanceData` 兜底大表**，按三问判据逐份切。→ `systems/balance.md:947`

**隐藏属性侧：**

- 清单 = **道心 `Faith`** `[0,100]` 起始 50 双臂 5 档（阈值 20/40/60/80）· **煞气 `Bloodlust`** `[0,100]` 起始 0 单臂 4 档（阈值 25/50/75）；回滞 δ = 4；档号方向 = 离常态的距离，触发规则 `|newBand| > |oldBand|`。→ `systems/services/plot-manager.md:78` · `:93`–`:118`
- **推拉的允许面全开**（五类事件无一例外），且是「**允许携带**」而非「强制携带」——**不填 = 不推**。→ `systems/services/plot-manager.md:44`–`:45`
- 载体 = `AdventureEventData` 上的 `HiddenStatGrants : HiddenStatGrant[]`，元素三格 `(Stat, Grade, Direction)`；**同一 `HiddenStat` 出现两条 → 拒绝**（校验 7）、**`Grade == None` → 拒绝**（校验 8）；作者从不落负数，符号在物化组装由 `Direction` 取负。→ `systems/adventure-event/common-properties.md:125` · `:170`–`:174` · `systems/architecture.md:500`
- **胜负同施一份，不套用 `FailureRatio`**（语义是「做了什么」，不是「学到多少」）。→ `systems/adventure-event/common-properties.md:293`
- `HiddenStatGrade { None 0 | Minor 2 | Standard 5 | Major 10 }`，**映射值恒为正量、方向不进本表**。→ `systems/balance.md:773`
- 反推验收口径已成文：**每属性每篇章跨档（含往返）2–4 次**；道心档宽 20 ⇒ 一章净行程 40–80 点；煞气档宽 25 ⇒ 50–100 点；**一章 ≈ 35 个事件，设其中约一半推拉道心（约 17–18 次）**；「`Standard = 5` 略高于上沿——接受，**不动映射值**」。→ `systems/balance.md:781`–`:786`
- 三档已定的口径：`Practice` 推道心 `Raise`、**对位低一档**、默认不推煞气；`Standard` 逐条目编排（杀伐类推煞气 `Raise`）；`Finale` 胜负同推道心 `Raise`。→ `systems/adventure-event/combat/_index.md:71`–`:81`
- 两条剧情线经 `PlotTriggerId` 挂在两个极值档上（煞气 Band 3 → 煞气反噬；道心 Band −2 → 心魔滋生）；**档位表侧配了 `PlotTriggerId` 却无 arc 承接 → `PushError`（双向校验）**。→ `systems/services/plot-manager.md:506`–`:508` · `:485`
- 剧情线**不转入 `Finale`**；替代形态 = 一场被 `PlotModulation` 六字段拧过的 `Standard` 档 Combat，**不给残卷、不是篇章闸门、失败不影响境界突破**。→ `systems/services/plot-manager.md:383`–`:390`
- 跨档叙事**只挂极值档**、密度 ≈ 2–4 条 / **轮回**（不是每篇章）；退让位顺序已定，**档数永远不是该动的旋钮**。→ `systems/services/plot-manager.md:125`–`:134`
- **ch1 参考构成（35 批次）**：`Finale` 1 · `Practice` 5 · `Standard` 5 · `Research` 4 · `Explore` 4 · `Exchange` 10 · `Travel` 6。→ `systems/balance.md:242`–`:252`

---

## 建议方案

### A. `RewardPoolId` 随档位调厚薄 = **换池**，不换权重表、不换抽数

`[既有推演]`

三条候选路径逐条按既有结构检验：

| 路径 | 结构后果 | 判定 |
|---|---|---|
| **换池**（三档各带自己的 `RewardPoolId`） | **零结构增量** —— `combat-service.md:602` 明写「三档共用同一条生成路径，差异只在 `RewardPoolId`、`Tier`」，换池正是既有结构**唯一已经预留**的档位差异旋钮 | ✅ **建议采纳** |
| **换权重**（按 `combatTier` 选不同稀有度权重表） | 权重表当前是**一维**（按 `RarityTier` 索引、由优势档 `Tier` 三档选表）。加 `combatTier` 维 ⇒ 3 张表变 9 张，且与 `balance.md:893`「分表维度 = 按用途，不按渠道」这条**已成文的结构结论**同形相抵（`combatTier` 也是「由哪条路径给出」而非「什么用途」） | ❌ 否决 |
| **换抽数**（`Practice` 抽 2 项 / `Finale` 抽 4 项） | 与 `balance.md:644`「档位只影响候选池的稀有度权重，**不影响候选数量**（数量恒 3）」直接冲突，且牵动战后奖励屏的三项逐项领取布局 | ❌ 否决 |

**推论：厚薄轴落在「池里有什么」，不落在「怎么抽」。** 这与 `Practice` 档 `PowerData` 的整族排除是同一条轴上的两个刻度（族排除 = 池成分的极端形态），故不引入第二条机制。

### B. 池的编排维度 = **篇章 × `combatTier` 九个池**；厚薄由池的 `RarityTier` 组成表达

`[既有推演]` + `[通行做法]`

- **篇章维是必需的。** `balance.md:428` 明写：「购买力校验的前提（ch1 主要遇到低档）**尚未被机械保证**，它依赖战后奖励池 / 商店库存的 `RarityTier` 分布权重」。权重表不设篇章维（`balance.md:893` 的分表判据），故这条前提**只能由池成分兑现**。给池加篇章维即当场把它机械化。
- **池 id 形态（照既有两段式内容 id 惯例）：** `reward.ch1.practice` · `reward.ch1.standard` · `reward.ch1.finale` · … 共 9 个。`AdventureEventData` 模板上填哪一个是内容编排决策；池本身是既有的具名池，不新增内容类型。
- **`Practice` 档不必在池成分上再表达神通排除**——生成侧的族级排除已机械兜底（`combat-service.md:602`），池里写不写都不影响结果。避免两处真值。

**ch1 池成分初值（待实测校准）：**

| 池 | 族 | `RarityTier` 组成 | 期望价值 V（见下） | 对 `Standard` 之比 |
|---|---|---|---|---|
| `reward.ch1.practice` | 卡牌 / 道具 / 功法（神通由生成侧排除） | Tier1–Tier2 | 28.1 | **0.72**（族排除后实测更低） |
| `reward.ch1.standard` | 四族 | Tier1–Tier3 | 39.1 | **1.00** |
| `reward.ch1.finale` | 四族 | Tier2–Tier4 | 74.9 | **1.92** |

ch2 各档整体上移一档、ch3 再上移一档（`Tier5` 只出现在 `reward.ch3.standard` / `reward.ch3.finale`），从而「ch1 主要遇到低档」成为池成分的直接后果。

**V 的算法（可复算，不进 `.tres`，是书写口径）：**

```
V(池) = Σ_i w_i × BasePrice_i / Σ_i w_i
  w_i        = 战后奖励池权重表在该 RarityTier 的权重    ← 尚待定，见「前置依赖」
  BasePrice_i = 定价表的稀有度基价向量 20/40/80/160/320  ← systems/balance.md:424
```

上表用 `GrantPoolWeights`（40/27/18/10/5，`balance.md:883`）作**占位权重**代入。取它是因为它是本库当前唯一已定的 `RarityTier` 权重表；战后奖励池的自有权重表定稿后须用真值重算。

**为什么用「期望价值比」而不是别的锚：** `BaseReward` 的灵石量已由 `S(c)` 给出 `0.5 : 1 : 2.0` 的三档偏置。可选奖励是同一场战斗的另一半产出，两半的厚度轴**若严重错位**，玩家会看到「Finale 灵石翻倍但候选质量不变」的割裂。上表的 `0.72 : 1 : 1.92` 与 `0.5 : 1 : 2.0` 同向、`Finale` 一格几乎重合；`Practice` 一格偏高 0.22，其中一部分由**神通整族排除**吃掉（`CharacterPower` 是定价表族系数 1.5 的高价族），故不必再收窄池成分。

**可调旋钮位置：** 池成员是 `.tres` 编排面（改条目的池归属，改数据不改代码）；权重表在 `systems/balance.md`、经 `Content.Single<T>()` 取。**两处都随 overlay 可调、不发版。**

### C. `BaseReward` 中「其余 element 的量」= 三档默认下**恒空**

`[既有推演]`

这一格的答案不是「一个待填的数字」，而是「结构上没有第二格」：

| 候选 element | 判定 | 依据 |
|---|---|---|
| `SpiritStone` | ✅ 唯一一格，量 = `S(c)` 三档偏置 | `balance.md:397` |
| `ImmortalJade` | ❌ 恒不出现 | 仙玉走 `SelectionWeightGrades.Rare` 的稀有事件通道，每章 1–2 次；单价表只列灵石（`balance.md:405` · `:619`） |
| `ExperiencePoint` | ❌ 恒不出现 | 经验走模板侧独立的 `ExperienceGrade` + `FailureRatio` 格。`BaseReward` 再装一份即制造第二个书写位，与「**物化后可出现的 key ≠ 模板可声明的 key**」这条承重纪律相抵（`common-properties.md:180`） |
| `LifeSpan` | ❌ 恒不出现 | 回寿只有三条通道、只走 outcome 侧（`ADR-0066`），战斗战利品不在其列 |
| `ManaLimit` | ❌ 恒不出现 | 量值恒为 1、由 outcome 侧展开（`log-event-outcome-spec-fields`） |
| 卡牌 / 道具 / 功法 / 神通 | ❌ 走 `RewardPoolId` 的可选奖励通道 | `combat-service.md:591` |

**唯一的例外（逐条目编排，不进三档默认表）：** 少数条目附带的**额外惩罚**是 `Spoils` 内的负向 `ChangeElement`（`combat-service.md:19`）。它是内容作者逐条目写的，不是档位默认值。

**建议落笔形态：** 在 `systems/balance.md` 的 `S(c)` 表下补一句「**`BaseReward` 的默认 element 面 = 灵石一格**；其余 element 恒空，负向条目属逐条目编排」，并把 `open-questions/03:12` 的「其余 element 的量」一格**关闭**（它不是待校准的数字，是一条结构结论）。

### D. Combat 三档的默认 `HiddenStatGrade` 阶梯

`[既有推演]`

| 档位 | 道心 `Faith` | 煞气 `Bloodlust` |
|---|---|---|
| `Practice` | `Raise` · **`Minor`(2)** | 不填（已定） |
| `Standard` | 逐条目（方向随语义）· 基准 **`Standard`(5)** | 杀伐类 `Raise` · **`Major`(10)** |
| `Finale` | 胜负同施 `Raise` · **`Major`(10)** | **首批一律不填**（口径仍是「逐条目编排」，本条只是内容侧的首批建议） |

逐格依据：

- **`Standard` 档道心取 `Standard`(5)：** `balance.md:784` 的反推口径本身就是拿 `Standard = 5` 去对「平均单次净幅度 2.5–4.4」的，并明写「略高于上沿——接受，**不动映射值**」。基准档取中位档 `Standard` 是这条已成文口径的直接读出。
- **`Practice` 档道心取 `Minor`(2)：** 「对位低一档」是已定口径（`combat/_index.md:79`），基准既定为 `Standard`(5)，低一档即 `Minor`(2)。机械得出，无自由度。
- **`Finale` 取 `Major`(10)：** 三条。① 一章仅一次，而 `S(c)` 与 `lifeSpanCost` 两张既有表都给它最高档偏置（2.0 × / 45 vs 38），推拉档位与它们同向才自洽；② 若取 `Standard`(5)，渡劫与一场普通遭遇等量，与「Finale 是篇章高潮 + 胜负同施一份」的语义不匹配；③ `Major` = 10 = 道心档宽 20 的一半 ⇒ 「渡劫必留下印记，但单次不足以跨档」，与「跨档是里程碑不是计时器」相容。
- **煞气的默认档比道心高一档（`Major` vs `Standard`）：** 由两张档位表的几何直接推出——煞气**从 0 起、须走满 75 点**才到极值档 Band 3；道心**从 50 起、只须走 30 点**到 `+2`。两属性的验收带（净行程 40–80 vs 50–100）也印证这条不对称。若两者取同档，煞气在既有事件密度下**结构上到不了极值档**，「煞气反噬」剧情线与它那条唯一的跨档文案将双双零触发。
- **`Finale` 煞气首批不填：** 天劫是天道 / 自然，不是可屠戮的生灵，杀伐语义不成立。这不推翻「逐条目编排」的口径，只是首批内容的编排建议。

### E. 五类事件的推拉编排判据表（语义 → `(Stat, Direction, Grade)`）

`[既有推演]` + `[通行做法]`

本表是**内容编排口径**（照 `Explore` 真身 5:3:2、`combatTier` 配比 1:1 的既有范式），**不新增字段、不新增加载期校验**。

| 条目语义 | `Stat` | `Direction` | 默认 `Grade` |
|---|---|---|---|
| 屠戮 / 灭门 / 掠夺生灵 | `Bloodlust` | `Raise` | `Major` |
| 常规杀伐性质的遭遇取胜 | `Bloodlust` | `Raise` | `Major` |
| 沾边的暴力（黑市火并、劫掠） | `Bloodlust` | `Raise` | `Minor` |
| 净化 / 忏悔 / 疗愈 / 放生 | `Bloodlust` | `Lower` | `Standard` |
| 切磋 / 点到为止 | `Faith` | `Raise` | `Minor` |
| 闭关顿悟 · 坚守承诺 · 舍己 · 拒绝捷径 | `Faith` | `Raise` | `Standard` |
| 背信 · 夺舍 · 服用禁药 · 走捷径 | `Faith` | `Lower` | `Standard` |
| 渡劫（成败同施） | `Faith` | `Raise` | `Major` |
| 走火入魔（`Research` 风险档命中） | 两条：`Faith` `Lower` `Standard` + `Bloodlust` `Raise` `Standard` | | |
| 换图 / 纯移动（`Travel`） | — | — | **不填** |
| `Explore` 壳条目 | — | — | **不填**（产出随真身，照 `balance.md:389` 的既有口径） |

三条编排纪律：

1. **一个条目至多两条 grant**（校验 7 已保证同属性不重复）；**默认动作是不填**（`plot-manager.md:45`）。
2. **`Travel` 一律不填。** 换图本身没有道德内容；且 `Travel` 已因不占 `eventCountLimit` 而失去一道软闸，再给它一条隐藏属性通道会开出「来回横跳刷道心」的口子——与「`Travel` 定价那一格必须 > 0」要堵的零成本 reroll 同源。**建议以 `/audit-content` 的一条汇总项看住（只报告不阻断），不立加载期校验。**
3. **`Explore` 壳不填、真身填。** 遮罩纪律照旧：壳的 `EventId` 指向 Explore 模板，推拉随 `RevealedEventId` 的真身模板走。

### F. 一张「推拉供给 ÷ 跨档需求」对账表（照 `ExperienceGrade` 供需比的既有范式）

`[既有推演]`

`balance.md:767` 已有一张经验的「供给 92 / 需求 79 = 1.16」对账表，并明写「把供给 / 需求比做成**一份可算的校验表**，每次调时长旋钮时重算，而不是死记这组数字」。隐藏属性侧缺的正是同款一张表。建议照抄这个形状。

**ch1 对账（用 35 批次参考构成 · 初值）：**

*道心 `Faith`*

| 类型 | 次数 | 携带 | 档 | Σ&#124;Δ&#124; |
|---|---|---|---|---|
| `Practice` | 5 | 5 | `Minor` 2 | 10 |
| `Standard` | 5 | 5 | `Standard` 5 | 25 |
| `Finale` | 1 | 1 | `Major` 10 | 10 |
| `Research` | 4 | 3 | `Standard` 5 | 15 |
| `Exchange` | 10 | 6 | `Standard` 5 | 30 |
| `Explore`（壳）/ `Travel` | 10 | 0 | — | 0 |
| **合计** | **35** | **20** | | **毛 90** |

- 携带 20 / 35 = 57%，与 `balance.md:783` 的假设「约一半推拉道心（约 17–18 次）」同一量级 ✓。
- 净行程 = 毛 × 净比 η。目标 40–80 ⇒ **η ≥ 0.44**。一个倾向一致的玩家实际接触到的携带条目约 3:1 同向 ⇒ η ≈ 0.5 ⇒ **净 ≈ 45** ✓ 落在带内下半区。
- **收口方向是扩携带面（20 → 22–24），不是提映射值**——`balance.md:784` 已明写映射值不动。

*煞气 `Bloodlust`*

| 类型 | 次数 | 携带 | 档 | Σ&#124;Δ&#124; |
|---|---|---|---|---|
| `Standard`（杀伐类，占 `Standard` 池 ≈ 80%） | 5 | 4 | `Major` 10 | +40 |
| `Explore` 真身中的 Combat（4 × 5/10） | — | 2 | `Major` 10 | +20 |
| `Research`（走火入魔风险档命中） | 4 | 2 | `Standard` 5 | +10 |
| `Exchange`（黑市 / 劫掠类） | 10 | 3 | `Minor` 2 | +6 |
| 净化 / 忏悔 / 疗愈类（跨类型） | — | 3 | `Standard` 5 | −15 |
| **合计** | | **14** | | **毛 91 · 净 +61** |

净 61 ✓ 落在 50–100 带内。

**F 的承重结论（比数字更重要）：反向（`Lower`）供给面是达成验收带的必要条件，不是可选点缀。**

- 煞气单臂、跨篇章不重置 ⇒ **一条轮回内至多 3 次单向 outward 跨档**，而验收带要求 6–12 次（2–4 × 3 章）。差额**只能靠往返补**（`balance.md:781` 自己写的「含往返」）。
- 回滞 δ = 4（档宽的 20%）⇒ 一次往返再跨的边际成本仅 ≈ 2δ = 8 点，远低于首次跨档的 25 点。**往返因此是廉价且被设计允许的路径**，但它要求存在能把煞气拉下来的条目。
- ⇒ **建议给每篇章至少 3 条净化 / 忏悔类的 `Bloodlust` `Lower` 条目**，并把它写成内容编排的一条硬性配额（`/audit-content` 汇总项）。缺了这条，「煞气反噬」那条剧情线与它唯一的极值档文案将在多数轮回中零触发。
- 道心同理：**两向都要有供给面**，否则 `−2` 心魔滋生（无文案、只靠剧情线显影）等于白写。

### G. 两条剧情线的结构形态与内容大纲

`[通行做法]`（结构部分为 `[既有推演]`）

**结构（可直接落 `.tres`）：**

| 格 | 煞气反噬 | 心魔滋生 |
|---|---|---|
| `Id` | `plot.arc.sidestory.bloodlust_backlash` | `plot.arc.sidestory.inner_demon` |
| `Tier` | `SideStory` | `SideStory` |
| `ChapterScope` | 空（不限） | 空（不限） |
| `PlotTriggerId` | 与 `HiddenStatBandData` 煞气 Band 3 对接 | 与道心 Band −2 对接 |
| `ExclusiveGroup` | 建议同组 `hidden_stat_backlash` | 同左 |
| 节点数 | 3–4 | 3–4 |

- **取 `SideStory` 而非 `SideChapter`：** 两个属性的值**跨篇章不重置**，触发时点不可预知；`SideStory` 的定义就是「跨篇章穿插」，且 `ChapterScope` 空 = 不限（`plot-manager.md:19` · `:252`）。
- **同 `ExclusiveGroup` 是建议不是必然：** 两条线可以同时触发（一个既杀伐又失道心的角色），但同时跑两条 boss 线会在一个篇章里堆两次高潮。同组即「一次轮回至多激活一条」。**这一格若用户不同意可直接留空，不影响其余结构。**
- **节点形态：** 入口节点（纯叙事，`Modulation` 空）→ 1–2 个调制节点（`EventWhitelist` + `EventWeights` 把本线事件推到玩家面前）→ **一个「剧情线 boss」节点**（`EnemyPoolScope` 换成煞气化身 / 心魔模板 + `LevelBias` + `Tighten`，即 `plot-manager.md:390` 已给的零新结构形态）→ 终止节点（`Edges` 空 ⇒ arc → `Completed`）。
- **至少一处 `ChooseBranch`（两出边）**，让玩家能选择迎合或抗拒——这是 `PlotEdge` 已有的能力，不新增结构。
- 既定边界照旧：**不给残卷、不是篇章闸门、失败不影响境界突破**。

**内容大纲（提案 · 正文归内容编排阶段）：**

- **煞气反噬** —— 杀业积到反噬自身：先是战斗后久不散的血气（叙事节点），继而旧日杀过的对象在秘境中以煞气化身出现（调制节点，`EnemyPoolScope` 收窄），高潮是与自身煞气所化之物一战（boss 节点）。分支 = 「以杀止杀」（胜后煞气再涨、但得一件与杀伐相性的奖励）vs 「散去煞气」（`Bloodlust` `Lower` `Major`，代价为一次事件位与寿元）。
- **心魔滋生** —— 道心崩坏后被外物趁虚而入：先是决断开始出错（调制节点，`Tighten` 让遭遇更紧），继而出现一个「可以走捷径」的诱惑事件（`EventWhitelist`），高潮是心魔具象（boss 节点）。分支 = 「与心魔共处」（保留一项带代价的强力收益）vs 「斩心魔」（`Faith` `Raise` `Major`）。
- 基调按 `vision/pillars.md` 第 6 条 grimdark：两条线**都不给干净的好结局**，代价一律如实展示。

### H. 审计落点：`/audit-content` 增两项汇总

`[既有推演]`

照 `Explore` 真身 5:3:2 与 `combatTier` 配比 1:1 的既有落点范式（**只报告、不阻断**）：

1. **逐篇章 × 逐属性的 Σ|Δ| 与 `Raise` / `Lower` 构成**，对上表的目标带比对；并单列「`Travel` 条目携带 `HiddenStatGrants`」与「`Explore` 壳条目携带 `HiddenStatGrants`」两项异常。
2. **逐 `RewardPoolId` 池的 `RarityTier` 组成与 V 值比**（池**深度**已由 `ADR-0073` 的三道闸看住，本项不重复造闸，只汇总组成分布供编排对照）。

---

## 具体形态（可 derive 的落地面）

**新增 / 改动的字段：零。** 本方案不新增任何字段、内容类型、枚举成员、加载期校验或存档字段；不 bump `schemaVersion`；后端零参与。全部落点是**书写口径表 + 内容编排口径 + 审计汇总项**。

| 落点 | 写什么 |
|---|---|
| `systems/balance.md` | ① `S(c)` 表下补「`BaseReward` 默认 element 面 = 灵石一格」；② 新增「战后奖励池的三档池成分表 + V 值算式」小节；③ `HiddenStatGrade` 反推口径下补「Combat 三档默认阶梯」与「ch1 推拉供给对账表」；④ 补一句区分「每属性每篇章跨档 2–4 次」（全档）与「跨档叙事 ≈ 2–4 条 / 轮回」（仅极值档）两个不同的量 |
| `systems/adventure-event/combat/_index.md` | 「三档与隐藏属性」表补入 `Grade` 列；`:205` 与 `:207` 两条待决问题收口 |
| `systems/services/plot-manager.md` | 「隐藏属性驱动剧情线」补两条 arc 的结构形态；`:578` 待决问题收口 |
| `systems/adventure-event/common-properties.md` | 补「语义 → `(Stat, Direction, Grade)`」编排判据表（口径，不是校验） |
| `systems/services/combat-service.md` | 明确 `RewardPoolId` 的编排维度 = 篇章 × `combatTier` |
| `systems/scoring.md:94` | 待决条收口（其余 element 恒空 + 厚薄轴 = 换池） |

**可调旋钮一览（全部随 overlay 可调、不发版）：**

| 旋钮 | 在哪 | 动它会连带影响 |
|---|---|---|
| 池成员（条目的 `RewardPoolId` 归属） | `.tres` 内容面 | 三档 V 比、`I(c)` 灵石收入的加成项 |
| 战后奖励池稀有度权重表 | `systems/balance.md`（**归分片 A**） | 三档 V 值（本方案的 V 表须随之重算） |
| 逐条目 `HiddenStatGrants` 的携带与档位 | `.tres` 内容面 | 两属性的净行程、剧情线触发率、跨档文案密度 |
| `HiddenStatGrade` 映射值 2/5/10 | `systems/balance.md` | **本方案建议不动**（`balance.md:784` 已明写不动） |

---

## 后果

- **三条待答项可一次收口**，且 `open-questions/03:12` 的「其余 element 的量」一格由「待校准数字」降级为「结构结论」，不再进统计校准清单。
- `balance.md:428` 那条「尚未被机械保证」的购买力校验前提（ch1 主要遇到低档），由池的篇章维直接兑现。
- `/audit-content` 多两项汇总；`systems/balance.md` 多两张可复算的口径表（不进 `.tres`，与 λ 反推式、`t(type)` 耗时台账同档）。
- **存档 / 契约零影响**：不动 schema、不 bump、无迁移、后端不参与。
- **对 derive 就绪度的影响：** `systems/scoring.md` 的两条卡点减为一条（只剩「卡牌产 / 削道念的量纲基准」）；`combat/_index.md:202`–`:205` 四条卡点减为两条。**本草稿不评估就绪度**，此处只作提示。

## 备选方案（已考虑并否决）

- **战后奖励权重表加 `combatTier` 维（3 张 → 9 张）。** 否决：与 `balance.md:893`「分表维度 = 按用途，不按渠道」同形相抵；且 `combat-service.md:602` 已把档位差异钉在 `RewardPoolId` / `Tier` 两格上，加一维等于开第三条轴。
- **`Practice` 抽 2 项 / `Finale` 抽 4 项。** 否决：与「候选数量恒 3」直接冲突（`balance.md:644`），且牵动战后奖励屏布局。
- **给 `BaseReward` 加一格 `ExperiencePoint`。** 否决：经验已有 `ExperienceGrade` + `FailureRatio` 的独立书写位，加进来即制造第二真值，与「模板可声明的 key ≠ 物化后可出现的 key」两张表纪律相抵。
- **为 `Finale` 的隐藏属性推拉另立一条「胜 / 负各一档」的字段。** 否决：`common-properties.md:297` 已明写日后确需时的正确形态是**第二个可空档位字段**，且当前没有需求推动它；本方案不预留。
- **给两条剧情线做成 `SideChapter`（篇章内）。** 否决：两个属性的值跨篇章不重置，触发时点不可预知；`SideChapter` 的 `ChapterScope` 会让「ch1 末触发的煞气反噬」在 ch2 开头当场被判出范围。
- **为「`Travel` 不得携带 `HiddenStatGrants`」加一条加载期 `PushError`。** 否决：`plot-manager.md:44` 明写允许面对五类**无一例外**开放，加硬校验即在结构上推翻它；编排纪律的正确载体是 `/audit-content` 汇总项（纪律阶梯第 3 级，与 `Explore` 真身占比同款）。

## 与既有决策的张力

**① `systems/balance.md` 内部对战后奖励池族维度的两处不一致（🟠 · 需裁决，本方案已选边）。**
`:892` 写「族维度含卡牌 / 道具 / **功法三类**」，`:990` 写「卡牌 / 道具 / 功法 / **神通四类**」，而 `combat-service.md:591`、`handoffs/2026-09-06-mechanism-contradiction-roundup.md` 与 **`decisions/ADR-0169-combat-reward-four-family-pool.md`（Accepted）** 均为**四族**。有 ADR 在，`:892` 那半句是漏改的残留，**不是需要裁决的分歧**。本方案按四族推演。**它落在分片 A 的写入面上**，由 orchestrator 统一处置，不由本草稿改。

**② `:990` 的措辞「神通列只在 `Standard` / `Finale` **两张表**上非空」与同句「按优势档 `Tier` **三档各一张表**」相抵。**
两者不可能同时成立——前者按 `combatTier` 分表、后者按 `Tier` 分表。而 `combat-service.md:591` · `:602` 与 `ADR-0169` 的权威口径是：**权重表不带 `combatTier` 维**，`Practice` 的神通排除走**生成侧的族级排除**（机械兜底，不依赖编排纪律）。本方案按权威口径推演，并建议把 `:990` 那半句改写为「`Practice` 档的神通排除走生成侧族级排除，不经权重表」。**同样落在分片 A 的写入面上。**
**这条与 A 节的判定直接咬合：** 若分片 A 采信 `:990` 的字面而给权重表加 `combatTier` 维，本方案的 A 节（「换池、不换权重表」）当场失效。两者必须同批裁决。

**③ 两个「2–4」密度口径易被混读。**
`balance.md:781` 的「每属性每篇章跨档 2–4 次」是**全档**计数；`plot-manager.md:132` / `balance.md:791` 的「跨档叙事 ≈ 2–4 条 / **轮回**」是**仅极值档**计数。两者相差约一个数量级的分母。本方案建议在 `balance.md` 明写它们不是同一个量——否则下一次校准会拿其中一个去证伪另一个。

**④ 「每属性每篇章跨档 2–4 次」在单向路径上算术不可达（已在 F 节给出化解）。**
煞气单臂、跨篇章不重置 ⇒ 单向至多 3 次 / 轮回，而验收带要求 6–12 次。`balance.md:781` 的「含往返」是化解，但它**隐含了一条从未被写下来的内容义务**：必须存在足量的反向（`Lower`）供给面。本方案把它显式化为一条编排配额。**若用户不接受这条义务，正确的收口是放宽验收带，而不是当作已满足。**

## 前置依赖

- **战后奖励池各档稀有度权重表**（`balance.md:990` 待决 · **归本批分片 A**）。B 节的 V 值表用 `GrantPoolWeights` 作占位权重，权重表定稿后须重算；**三档池成分的相对形状不依赖它，绝对 V 值依赖它。**
- **「三项皆可领之后候选厚度与 `RewardPoolId` 取值需重估」**（`handoffs/2026-08-23g` · **归本批分片 A**）。它与 A/B 节切的是**同一个旋钮**（池成分与权重）。若 A 分片的重估结论是「整体调薄」，本方案的三档**相对**比例仍成立，**绝对**池成分须同批下调。
- **卡牌产 / 削道念的量纲基准**（`balance.md:988`）。它定 `E[道念差]` → 定 `advantage` 三档的实际分布 → 与池成分共同决定玩家实际拿到的稀有度。B 节的 V 表是「池侧」的一半，另一半在它。
- **回寿法宝的总量护栏**（`common-properties.md:110` 软闸 ③ · **归本批分片 C**）。战后奖励池是「出现频率」的一个面：`reward.ch*.finale` 池若含补天丹类 `CharacterItem` 条目，即绕过商店库存深度与定价两道闸。**本方案的池成分表未对回寿法宝表态**，留给分片 C 定案后填。
- **ch2 / ch3 的逐类型事件构成表尚未补齐**（`balance.md:418`）。F 节的对账表因此**只有 ch1 可复算**；ch2 / ch3 两列须待构成表补齐后按同一条式子算出，不在本草稿臆造。

## 仍需用户决定

### 1. `reward.ch1.practice` 池的 `RarityTier` 上界：Tier2 还是 Tier1？

**背景（自包含）：** 战后可选奖励固定 3 项，从事件模板指定的「奖励池」里抽。本方案建议三个战斗档位（切磋 `Practice` / 常规 `Standard` / 渡劫 `Finale`）各用一个自己的池，厚薄由池里允许出现的**稀有度档**（`RarityTier` 五档，档号越高越稀有）表达。切磋档这一格取哪个上界，决定「打一场低风险切磋能不能偶尔掉到好东西」。

| 选项 | 池成分 | 期望价值比（对 `Standard`） | 后果 |
|---|---|---|---|
| **(a) Tier1–Tier2**（推荐） | 两档 | 0.72（神通整族排除后实测更低，≈ 0.6） | 切磋偶有 Tier2 惊喜；与 `S(c)` 的 0.5 偏置略高但同向；池深度充裕，三项去重不吃力 |
| (b) 仅 Tier1 | 一档 | 0.51 | 与 `S(c)` 的 0.5 精确对齐；但三个候选恒同档、切磋的奖励环节几乎没有变化度，且 Tier1 池须足够深才能去重抽 3 项 |

**推荐 (a)，理由：** ① `Practice` 的厚度落差已有**两个**承担者——池成分与神通整族排除；只用池成分一个去精确命中 0.5 会把落差压得过狠。② `combat/_index.md:39` 已把 `Practice` 定位为「低风险历练」而非「无价值遭遇」，一个恒定同档的奖励面会让这档退化成纯粹的时间开销。③ roguelike 通行做法（Slay the Spire 的 small elite / normal 对照）是「低档遭遇上限低但不封顶」，而非「低档只掉最低档」。

→ **已裁决（2026-09-09 · 批量评审）：选项 (a) —— `Tier1`–`Tier2`。** 期望价值比 0.72（神通整族排除后实测 ≈0.6）。B 节三档 V 值表与三个 `practice` 池成分按本裁决取值定稿。

### 2. 道心内容池的默认方向倾向：`Raise` 与 `Lower` 条目在池中的配比？

**背景（自包含）：** 「道心」是两个隐藏属性之一（另一个是「煞气」），玩家看不到数值，取值 0–100、每次轮回从 50 起。事件条目可以选择推高（`Raise`）或压低（`Lower`）它，也可以不填。掉到 0–19 会触发「心魔滋生」剧情线——而该档**没有任何文案**，剧情线是它唯一的显影通道。本题问的是：**内容池里推高与压低的条目按什么比例编排**，即「一个不刻意选择的玩家」的道心会往哪边漂。

| 选项 | 池中 `Raise` : `Lower` | 后果 |
|---|---|---|
| (a) 对称 | 5 : 5 | 净方向完全由玩家选择决定；代价是**随大流的玩家可能整章不跨一次档**，道心这条轴对他等于不存在，「心魔滋生」剧情线在多数轮回零触发 |
| **(b) 偏 `Lower`**（推荐） | 4 : 6 | 「世界残酷、道心自然消磨」——玩家须**主动维护**才守得住；心魔滋生是一种被动风险，两条剧情线因此各有一条自然通路（煞气靠杀伐主动累积、道心靠默认消磨被动下滑） |
| (c) 偏 `Raise` | 6 : 4 | 「修行本身即精进」——堕落需要主动作恶；道心通明（Band +2，**唯一有文案的道心档**）更常被看到，但心魔滋生几乎只有刻意求之的玩家能碰到 |

**推荐 (b)，理由：** ① `vision/pillars.md` 第 6 条 grimdark「后果沉重、常常残酷的结局」与基调段「Reigns 般的求生张力」都指向「默认在恶化」。② 结构上更要紧：道心 `−2` 档**明确不配文案**（`plot-manager.md:105`），设计已把它的存在感**全部押在剧情线与调制上**；若默认方向中性或偏 `Raise`，那条剧情线的触发率会低到「白写」。这是 08-12d 那次裁决（「若既无文案又无剧情线，玩家对掉道心这条因果链完全无感」）的直接延伸。③ **代价须一并接受：** 玩家会感到「什么都没做也在掉道心」，这必须由事件文案本身承担解释（修行界的凶险、旁人的算计），不能只靠数值默默滑落——否则会被读成 bug。

> 用户若选 (a) 或 (c)，F 节的道心对账表须重算净比 η，且「心魔滋生」剧情线的触发率预期须同批下修。

→ **已裁决（2026-09-09 · 批量评审）：选项 (a) —— 对称 5 : 5。**（**非本草稿的推荐项** —— 草稿推荐 (b) 偏 `Lower` 4:6，用户裁定取对称。）
> **已接受的代价（草稿已明示，用户裁决后照单接受）：** 净方向完全由玩家选择决定；随大流的玩家可能整章一次档都不跨，道心这条轴对他等于不存在，「心魔滋生」剧情线在多数轮回零触发。
>
> **⚠ 本裁决触发三项强制连带动作（提炼时必须一并执行，不得当作无影响）：**
> 1. **F 节道心对账表须重算净比 η** —— 对称配比下 η 趋近 0，道心的净行程可能**跌出 40–80 验收带**；重算后若确实跌出，须**扩携带面**（提高携带 `DaoHeart` 推拉的条目次数）把净行程拉回带内。当前表中「道心携带 20 次 / 毛 90 / 净 ≈45」这组数字建立在 4:6 的 η 上，**已失效，须重算**。
> 2. **「心魔滋生」剧情线的触发率预期须同批下修**，并据此复核 G 节两条剧情线的编排投入是否仍成比例。
> 3. **煞气侧不受本裁决影响**（煞气是单臂属性，无 `Raise:Lower` 配比问题），F 节煞气那一半的对账数字维持原值。
>
> 本草稿 §F 的承重结论（**反向 `Lower` 供给面是达成「每属性每篇章跨档 2–4 次」的必要条件，不是可选点缀**；建议每篇章 ≥3 条净化/忏悔类 `Bloodlust` `Lower` 条目）**不因本裁决动摇**——对称配比只改道心那一臂的方向倾向，不改「往返才够次数」这条算术。

---

## 批量评审的连带裁决（2026-09-09 · 与另两份草稿的交叉核对结果）

本草稿是 `/batch-provide-solution-draft` 三分片之一，另两份为 `solution-draft-combat-rarity-and-reward-scale.md`（稀有度与奖励量纲）与 `solution-draft-lifespan-item-supply-guardrail.md`（回寿法宝护栏）。合并 interview 的交叉核对结论：

### ✅ 与 A 草稿「最硬的交叉点」经直读裁定为**不冲突**

本草稿张力表第 ② 条担心「若 A 采信 `balance.md:990` 字面而给权重表加 `combatTier` 维，本草稿 A 节当场失效」。orchestrator 直读 `balance.md:990` 原句：「战后奖励池各档权重（按**优势档 `Tier`** 三档各一张表……）」。

⇒ **A 的三张表按「优势档」分，本草稿的九个池按「`combatTier` × 篇章」分 —— 两者是正交的两个维度，并行不悖。** A 草稿实际给出的也正是三张按优势档的表（`Narrow` / `Solid` / `Crushing`），未给权重表加 `combatTier` 维。**本草稿 A 节整节成立，无须改动。**

`:990` 真正的缺陷在后半句（把 `Practice` 的族级排除误写成表维度），处置见下。

### ✅ X-1 · 稀有度分布按篇章分池 —— **本草稿 §B 的做法被采纳为全批口径**

→ **已裁决（2026-09-09 · 批量评审）：按篇章分池。** 本草稿 §B「池的编排维度 = 篇章 × `combatTier` 九个池」被采纳，**并扩展到商店库存**（商店同样按篇章分池）。
这同时解除了 C 草稿最硬的前置依赖（其收支回代建立在「ch1 主要遇 Tier1–2、ch3 遇 Tier3–4」上），并把 `balance.md:428` 那条「尚未被机械保证」的购买力校验前提当场机械化 —— 正是本草稿 §B 预期的顺带收益。**已接受的代价：需要维护的具名池数量上升。**

### ✅ 与 C 草稿「留口待填」的那一格已定案

本草稿 §B 池成分表对回寿法宝**刻意未表态**、留口待 C 定案。C 的 L-0 已裁决通过：

→ **战后奖励池排除含 `LifeSpan` 产出的道具**（取池侧过滤，加载期反建索引）。⇒ **本草稿的九个池成分表中，`CharacterItem` 族一律不含回寿法宝子集**，该留口就此填上。本草稿独立报出的「软闸 ③ 未封的口子」由此闭合。

### R-2 / R-3 · 两处陈旧副本的机械修正（直读裁定，无需用户裁决）

本草稿张力表第 ① ② 条所指的两处，orchestrator 直读后裁定如下（**落在 A 草稿的写入面上，提炼时由 A 那一份一并改掉，本草稿不重复落笔**）：

- **`balance.md:892`** 的族维度「三类」是陈旧副本 ⇒ 按 `ADR-0169` 的**四族**改写。
- **`balance.md:990` 后半句**「神通列只在 `Standard` / `Finale` 两张表上非空」误把 `combatTier` 的排除写成表维度 ⇒ 改写为「`Practice` 不产神通走**生成侧族级排除**，不经权重表」。

本草稿张力表第 ③ ④ 条（两个「2–4」口径易混读 · 反向供给面的隐含内容义务）**未被本次 interview 取消**，按草稿原议处置。
