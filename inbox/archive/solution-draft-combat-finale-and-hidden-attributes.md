---
type: solution-draft
date: 2026-08-17
question: 非战斗形态的 Finale 是否存在；Combat 三档与隐藏属性（道心 / 煞气 / 寿元）如何交互
source: open-questions/03-adventure-event-types.md → 「非战斗形态的 Finale」+「各档与隐藏属性的交互」
targets: systems/adventure-event/combat/_index.md · systems/services/plot-manager.md · systems/adventure-event/common-properties.md · systems/services/combat-service.md
status: distilled
decided-on: 2026-08-17
reviewed: 2026-08-17 — 四项取向 + 一条口径确认全部裁决；定案 1、2 推翻原推荐的非战斗 Finale / 试炼整套方案，定案 3 把隐藏属性扩为输入与输出两侧全开，定案 4 改为胜负都推道心
distilled-to: handoffs/2026-08-17e-finale-combat-only-and-hidden-stat-io.md
---

# 方案草稿 — 非战斗 Finale（否决）· Combat 三档 × 隐藏属性

> **本草稿已裁决（2026-08-17）。** 用户定案见「## 定案」一节。原草稿推荐的**非战斗 Finale / 试炼**整套方案（`EncounterSpec.Trial`、抉择链形态、等效道念差映射）**已被整体否决**，正文相应改写；其论证保留在「备选方案（已考虑并否决）」中作溯源。

## 定案

| # | 定案 | 相对原草稿 |
|---|---|---|
| 1 | **不存在非战斗形态的 Finale。** 全部 Finale 均为天劫战。 | **推翻**原第一~五节的整套方案 |
| 2 | **不存在非战斗试炼。** 不引入 `TrialSpec` / 试炼求值 / 抉择链形态。 | **推翻**原第四条与 `TrialSpec` 字段面 |
| 3 | **隐藏属性作为所有类型事件的输入与输出，两侧都可能改动。** | **扩大**原第八条（原建议 Finale 不检定；现输入侧对五类一律开放） |
| 4 | **Finale 的 `HiddenStatGrade` 口径 = 胜利与失败都推道心。** | **改**原建议（原为「胜利推 `Major`、失败不推」） |

原第 1、2、5 项取向（试炼形态 / 三章分布 / `eventType == Combat` 的命名张力）**随定案 1、2 一并作废**——非战斗形态不存在，这三项没有承载对象。

## 问题

两条紧密耦合的待答项，都坐在「`combatTier` 三档」与「隐藏属性 / 剧本层」的交界上：

1. **非战斗形态的 Finale。** `combat/_index.md` 原写「少部分 Finale 不是战斗」，形态留白。→ **定案 1：不存在。该句须改写。**
2. **各档与隐藏属性的交互。** ① `Practice` 是否推拉道心 / 煞气 / 寿元；② 「大限将至」等隐藏属性剧情线触发后是否**转入 `Finale`**；③ `Finale` 是否**消耗 / 检定**隐藏属性。

**明确不在本草稿范围内：** `Practice` / `Finale` 档的奖励厚薄（`BaseReward` / `RewardPoolId`）与全部具体数值——清单已把它归 **ch1 数值标杆专场**，本草稿只标出挂钩点，不替它拍数值。

## 约束（来自既有设计）

- **推拉面已全开：** 「**所有事件都有可能推拉这三个隐藏属性，不限事件类型**（五类无一例外）」；`HiddenStatGrade` 是**可选**字段、对全部事件类型开放、**不填 = 不推**（`plot-manager.md`）。定案 3 把这条从「产出侧全开」扩为**输入与产出两侧全开**。
- **「大限将至」= 寿元归 0 = `defeated` 终态，对应终态而非任何一档，不经 `PlotTriggerId` 通道**（`plot-manager.md` 明写）。真正经 `PlotTriggerId` 的只有两条：煞气 Band 3「煞气反噬」、道心 Band −2「心魔滋生」。
- **PlotManager 只调内容不调约束。** `PlotModulation` 六字段是权力面的逐条投影；「抬 `eventPriority`」「改模板任何字段」**写不出来**。
- **每个篇章只有一个 Finale，败后不可重战**；由此推出「残卷因此不需要任何额外的冷却 / 次数上限规则」——**可刷性由结构封死**（`combat/_index.md`、`player-power/_index.md`）。
- **`combatTier` 是必需的机械判据**，三个承重消费者：篇章边界闸门 · ADR-0004 篇章重试锚点 · 道统残卷的唯一累积源与兑现点（`decisions/ADR-0002`）。
- **`selectCost` 的 element 清单只有 `lifeSpanCost` 一项**；成本侧只放**可如实计价的量**（展示纪律：让玩家能自己算出「这一步可能是最后一步」）。
- **调制才是隐藏属性的主要显影通道**，旁白只是极值时刻的一次强调（`plot-manager.md` 承重）。
- 道心 / 煞气**触底不构成终态**，截断到 `[0, 100]`。
- **不加没有消费者的死结构**；`VictoryRule` 明写「参数化为一个数，不做可替换的判定对象」。

---

## 建议方案

### 一、不存在非战斗形态的 Finale —— 全部 Finale 均为天劫战

`[已定案]`

`combat/_index.md` 现存的「少部分 Finale 不是战斗」一句**须改写为**：**全部 Finale 均为天劫战；本作不设非战斗形态的境界突破路径。**

**连带收益（本定案顺手关掉的东西）：**

- `EncounterSpec` **不加** `Trial` 字段，`Enemy` **不必**放宽为可空 ⇒ 「Finale 场次可能无敌人」这一分支从结构中消失，`TurnLimit` / `FirstSide` 恒有意义。
- `CombatEventResolver` **无内部分派**，恒走 `combat-service.RunCombatAsync`。
- **`eventType == Combat` 的命名张力不再存在**——Combat 类的每一条都真的动手。原草稿为它准备的「口径澄清」一句**不必写**。
- **「非战斗 Finale 没有敌人等级可标」这条前置依赖消失**：`combatTier` 三档全部有敌人，危险度 = 精确标注敌人等级这条唯一难度刻度**无例外**。
- 残卷的累积源与兑现点无形态分叉，`player-power/_index.md` 不必加澄清句。

**存档 / 契约影响：无。** 本定案是**取消一个尚未存在的分支**，不新增也不删除任何已落地结构。

### 二、`Practice` 与隐藏属性：结构层面此问已被 08-16 的定案答结，剩下的是内容编排口径

`[既有推演]`

`plot-manager.md` 已明写推拉面对五类全开、`HiddenStatGrade` 可选、不填 = 不推 ⇒ **`Practice` 当然可以推拉道心 / 煞气，无需任何新字段、新规则。** 寿元同理：`selectCost` 三档一律无条件施加，定价表里 `combatTier` 各档可各有取值（`common-properties.md` 明写）。

**故这一问不需要机制决策，只需要一条内容编排的默认口径。** 建议口径（可逐条目覆盖，「不填 = 不推」照常成立）：

| 档位 | 道心 faith | 煞气 Bloodlust | 依据 |
|---|---|---|---|
| **`Practice`** | 推（正向为主），**对位低一档** | **默认不推** | `WinMargin 0`「道念相等即判胜」正是**点到为止**的机制表达——切磋是磨砺心性（推道心），不是杀伐（不积煞气） |
| `Standard` | 逐条目编排 | 推（杀伐类条目） | 常规遭遇是煞气的主要来源 |
| **`Finale`** | **胜利与失败都推道心**（定案 4） | 逐条目编排 | 见第四条 |

**「对位低一档」沿用既定范式：** `ExperienceGrade` 的档位偏置已明写「Combat `Standard` 档胜利 `Major` · `Practice` 档胜利 `Standard`（**低风险 ⇒ 产出对位低一档**）」。隐藏属性推拉照抄这条口径即可，不是新规则。具体映射值归 ch1 数值标杆专场。

**连带建议：隐藏属性推拉不套用 `FailureRatio`，胜负同施一份 `HiddenStatGrade`。**

`[既有推演]` — 经验有 `FailureRatio`（默认 0.5）是因为经验的语义是「**学到多少**」，失败也学到、按比例折算说得通。隐藏属性的语义是「**做了什么**」——屠戮就是屠戮，胜负不改变行为的性质；而且道心是**双向**属性，「失败时道心下降取 50%」在语义上无从解释（半个心魔？）。

> **定案 4 与这条正相印证。** 「胜利与失败都推道心」正是「一份 `HiddenStatGrade`、胜负同施」的直接兑现——**无需 `FailureHiddenStatGrade`、无需比率**。若日后确需让胜负推不同的量，正确形态仍是内容侧第二个**可空档位字段**（可正可负、语义自洽），而不是一个比率；可空字段不牵动存档迁移。

### 三、隐藏属性剧情线**不转入 `Finale`**——剧情线的高潮用 `PlotModulation` 表达

`[既有推演]` — 建议**明确否决**「转入 Finale」，四条理由中第一条是致命的：

1. **它会当场炸掉残卷的结构封印。** 「每角色每篇章至多累积一次或掷骰一次，且二者互斥」这条不变式的**唯一支撑就是「每篇章一个 Finale」**；剧情线若能造出第二个 Finale，玩家可以靠推煞气 / 掉道心在一个篇章内刷出额外的残卷累积。`player-power/_index.md` 正是据此明写「残卷不需要任何额外的冷却 / 次数上限规则」——那条豁免会立刻失效。
2. **Finale 的出现条件是一条等级条件**（已达本境界巅峰），而剧情线可能在篇章中段触发，此时天劫 `diff = +1` 的自洽性验证不成立，「渡劫 = 突破到下一境界」的叙事随之破裂。
3. **PlotManager 结构上够不着 Finale。** `PlotModulation` 六字段里**写不出 `eventPriority`**、写不出 `combatTier`、写不出模板的任何字段。**这条不需要新规则来禁止，它已经被数据形态禁止了。**
4. ADR-0004 以 Finale 为篇章重试的锚点；第二个 Finale 会让「篇章边界」这个概念本身歧义。

**「大限将至」这一半的前提需要更正。** 待答项把「大限将至」列为「隐藏属性剧情线」的例子，但 `plot-manager.md` 已明写：**它对应寿元归 0（终态），不是任何一档，不经 `PlotTriggerId` 通道。** 寿元归 0 时角色已 `defeated`，**没有任何东西可以转入**。故这一半不是「要不要转入 Finale」，而是「问题的前提已被 08-12d 的档位模型改写」。真正经 `PlotTriggerId` 的只有**煞气反噬**（Band 3）与**心魔滋生**（道心 Band −2）。

**推荐替代形态（零新结构）：剧情线的高潮 = 一场被 `PlotModulation` 拧过的 `Standard` 档 Combat。** 现有六个字段刚好凑齐一个「剧情线 boss」：

| 想要的效果 | 承载字段 |
|---|---|
| 本批只出这条剧情线的事件 | `EventWhitelist` |
| 派心魔 / 煞气化身来，而不是常规敌人 | `EnemyPoolScope` |
| 比常规遭遇更凶 | `Tighten`（`TurnLimit` / `VictoryRule`）+ `LevelBias` |
| 这条线的事件更容易出现 | `TypeWeights` · `EventWeights` |

**代价明写（也正是想要的）：** 剧情线 boss **不给残卷、不是篇章闸门、失败不影响境界突破**。它是一段风味与压力，不是第二个篇章收口。

### 四、隐藏属性对五类事件**输入与输出两侧全开**；`Finale` 仍不消耗、不做胜负检定

`[已定案]` + `[既有推演]`

**（a）产出侧（输出）——已定案全开，无新机制。** `HiddenStatGrade` 本就对五类开放、可空、不填 = 不推。`Finale` 依定案 4 填「胜利与失败都推道心」。

**（b）输入侧——定案 3 扩为全开，由两条既有通道承载，不新增机制：**

| 通道 | 形态 | 适用面 |
|---|---|---|
| **调制通道**（主）| Band 触发 arc → `PlotModulation` 六字段（`Tighten` / `EnemyPoolScope` / `LevelBias` / `EventWhitelist` / `TypeWeights` / `EventWeights`） | 五类一律 |
| **结算输入通道** | 事件的数据驱动 outcome 求值读取隐藏属性当前值作为**输入项之一** | 五类一律（Combat 侧经 `EncounterSpec` 的既有可调字段体现） |

**承重：输入侧全开**不**等于把隐藏属性接进胜负判定。** `VictoryRule` 仍是**单字段**（`WinMargin` 一个数），不做可替换的判定对象、无需策略枚举、无需分发——这条定案不受定案 3 触动。隐藏属性影响 Finale 的路径是「**拧参数**」（更凶的天劫模板、更高的 `WinMargin`、更差的起手），不是「**加一条并列的判定条件**」。

| 想要的效果 | 既有通道 |
|---|---|
| 煞气高 ⇒ 天劫更凶 | 煞气 Band 3 触发的 arc 用 `Tighten` 拧 `WinMargin` / `EnemyPoolScope` 换更凶的天劫模板 |
| 道心低 ⇒ 渡劫时心魔作梗 | 道心 Band −2 的 arc 同上 |
| 渡劫成败 ⇒ 道心变动 | Finale 条目自己的 `HiddenStatGrade`（定案 4：胜负都推） |

**（c）不消耗（`selectCost` 侧保持不变）。** `Finale` 的 `selectCost` 与其余事件同形（照定价表取 `Combat × Finale` 那一格），**不额外扣道心 / 煞气**：

- **成本侧只放可如实计价的量。** `selectCost` 的展示纪律（Band 2 精确展示）的全部目的是让玩家**能自己算出「这一步可能是最后一步」**；道心 / 煞气是**隐藏**属性，把隐藏量放进成本侧，玩家永远算不出那一格，与整条展示纪律正面冲突。这与「能力 element 恒不出现在 `selectCost`」是**同一条判据的第二个实例**。
- **它是没有消费者的结构。** 道心 / 煞气触底不构成终态（截断到 `[0, 100]`），扣了不产生任何可判定的后果。
- **连带：本方案不依赖「道心 / 煞气是否列入 `CostKey`」那条待答项**（`profile-service.md` 的轻量待答）。不消耗 ⇒ Finale 侧不给它施加任何新压力。

> **一处需在提炼时确认的口径（轻）：** 定案 3 的「输入」按本草稿理解为「**可被读取、可影响结算与调制**」，**不含**「作为 `selectCost` 消耗」——消耗是成本侧、受 Band 2 精确展示纪律约束，与「输入」不是同一个轴。若用户本意包含消耗侧，则第四条 (c) 须整条推翻，并须先答「道心 / 煞气是否列入 `CostKey`」。

---

## 具体形态（可 derive 的落地面）

**1. `combat/_index.md` 的改写（定案 1）**

- 「少部分 Finale 不是战斗」→ **「全部 Finale 均为天劫战；不设非战斗形态的境界突破路径。」**
- 「非战斗形态的 Finale」这条待决问题**移除**（已答结为「不存在」）。

**2. `EncounterSpec`：不动。**

```csharp
public sealed record EncounterSpec(
    string            EncounterId,
    CombatTier        Tier,
    EnemyInstance     Enemy,          // 恒非空 —— 定案 1 后无「无敌人的 Finale」
    int               TurnLimit,
    VictoryRule       VictoryRule,
    Side?             FirstSide,
    string            RewardPoolId,
    ProfileChangeSpec BaseReward);
```

**3. `CombatEventResolver`：不动**，恒走 `combat-service.RunCombatAsync(encounter, ct)`，无内部分派。

**4. 内容侧口径（`common-properties.md` / 内容层字段核对清单）**

- `HiddenStatGrade` **一份，胜负同施**，不套用 `FailureRatio`。日后分化的落点是可空的第二个**档位**字段（不是比率）。
- `Practice` 档默认口径：**推道心（对位低一档）· 不推煞气**；逐条目可覆盖。
- `Finale` 档：**胜利与失败都推道心**（档位与方向归 ch1 数值标杆专场与内容编排）。

**5. `plot-manager.md` 新增两条明写**

- 剧情线**不转入 Finale**（四条理由 + `PlotModulation` 替代形态；剧情线 boss 不给残卷、不是篇章闸门）。
- 隐藏属性**输入与输出两侧对五类全开**（定案 3），输入经调制通道与结算输入通道承载；**`VictoryRule` 仍是单字段，隐藏属性不作为并列的胜负判定条件**。

**6. 存档 / 契约影响：无。**

`EventOutcome` 四值不动 · `CombatOutcome` 三值不动 · `PastEventEntry` 不动 · `PlotKeyPoint` 不动 · `ProfileChangeSpec` 不动 · `selectCost` element 清单不动 · **无存档 schema bump、无迁移。**

---

## 后果

- **`systems/adventure-event/combat/_index.md`** — 「少部分 Finale 不是战斗」改写为「全部 Finale 均为天劫战」；「非战斗形态的 Finale」待决问题移除。
- **`systems/services/combat-service.md`** — `EncounterSpec` 与 `CombatEventResolver` **不改**；「Finale 的奖励结构加厚幅度」那条待决问题里「非战斗形态待定制」的尾巴**收掉**（改为「不存在该形态」）。
- **`systems/services/plot-manager.md`** — 新增两条明写：① 剧情线**不转入 Finale**；② 隐藏属性输入 / 输出两侧对五类全开，输入经调制与结算输入通道，`VictoryRule` 不受触动。
- **`systems/adventure-event/common-properties.md`** — 隐藏属性推拉不套 `FailureRatio`、胜负同施一份 `HiddenStatGrade` 的口径一条。
- **`systems/balance.md`** — 只加挂钩点：Finale / Practice 的 `HiddenStatGrade` 映射，**归 ch1 数值标杆专场**。
- **存档 schema：不变，无迁移。**

## 备选方案（已考虑并否决）

**因定案 1、2 否决（原草稿的推荐方案，保留作溯源）：**

- **非战斗 Finale 仍是 Combat 类特例、载体为 `EncounterSpec.Trial` 可空字段** — 原推荐方案。论证是三个承重消费者以 `combatTier == Finale` 为机械判据、类内差异用参数表达、07-30b 已否决过「独立结算」。**用户定案「不存在非战斗 Finale」，整套作废。**
- **试炼产出 `(得分, 门槛)` 塞进 `CombatResult` 的两个道念槽** — 结构收益最大的一条（全部奖惩换算、残卷、失败通道原样复用，存档零迁移）。**随定案 2 作废。**
- **试炼形态 A 单次检定 / B 抉择链 / C 单人演法** — 原推荐 B。**随定案 2 作废。**
- **非战斗 Finale 的三章分布（ch1 不出现、ch2/ch3 各少数条目）** — **随定案 1 作废。**

**原草稿即已否决（结论不变）：**

- **非战斗 Finale 另起一个 `eventType`（第六类）** — 三处承重消费者的判据全部分裂为二元判断，正是 ADR-0002 要消灭的反模式。（现更无必要。）
- **给 `combatTier` 加第四档 `FinaleTrial`** — `combatTier` 落存档、被三处消费，增删成员牵动存档迁移。
- **为非战斗 Finale 新建 `TrialOutcome` / `TrialResult` 类型** — 会连带出第二套奖惩换算、第二套残卷判定、第二条失败通道。
- **剧情线转入 Finale** — 炸掉残卷的结构封印（详见第三条），且 PlotManager 在数据形态上根本写不出来。
- **`Finale` 检定隐藏属性作为并列的胜负条件** — 直接推翻「`VictoryRule` 是单字段、不做可替换的判定对象」。定案 3 的「输入侧全开」由**拧参数**兑现，不需要这条。
- **隐藏属性推拉套用 `FailureRatio`** — 语义错配，且比率对双向的道心无从解释。定案 4「胜负都推」正是「一份档位、胜负同施」的兑现。

## 与既有决策的张力

**无。** 定案 1、2 是**取消一个尚未存在的分支**，不与任何既有决策冲突；反而消解了原草稿唯一那处张力（`eventType == Combat` 在非战斗 Finale 上名不副实）——非战斗形态不存在，该张力自动消失。

定案 3、4 落在 `plot-manager.md` 已明写的「推拉面五类全开、`HiddenStatGrade` 可空」之内，是**扩写与口径落定**，不推翻任何承重措辞。`VictoryRule` 单字段、`selectCost` 只放可计价量两条定案均**保持不变**。

## 前置依赖

- **「隐藏属性的增减触发」**（哪些 AdventureEvent 推拉、各推哪一档）— 第二条给出的是 `Practice` / `Finale` 两档的**默认口径**，它是那条待答项的一个子集，须与它一并定。
- **ch1 数值标杆专场** — `HiddenStatGrade` 映射值、Finale / Practice 的 `lifeSpanCost` 与奖励厚薄。（**本草稿按范围要求不替它拍任何数值。**）
- **不构成依赖（写明以免误判）：** 「道心 / 煞气是否列入 `CostKey`」——本草稿建议 Finale **不消耗**隐藏属性，故不给那条施加新压力，两者各自定稿。**除非**第四条 (c) 末尾那条口径确认的结果是「输入含消耗」，届时它转为硬前置。
- **已消失的依赖：** 原草稿列的「`EventOption` 完整物化字段清单 / `combatTier` 落点（非战斗 Finale 没有敌人等级可标）」**随定案 1 消失**——三档全部有敌人。

## 仍需用户决定

**无。** 四项取向 + 一条口径确认均已裁决：

- **定案 3 的「输入」= 读取 / 影响结算与调制，不包含「作为 `selectCost` 消耗」**（2026-08-17 确认）。消耗属成本侧、受 Band 2 精确展示纪律约束，与「输入」不同轴 ⇒ **第四条 (c)「Finale 不消耗隐藏属性」保持成立**，`selectCost` 的 element 清单仍只有 `lifeSpanCost` 一项，「道心 / 煞气是否列入 `CostKey`」照旧不受本草稿施压。
