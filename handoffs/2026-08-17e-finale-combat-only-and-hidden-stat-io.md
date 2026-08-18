# 全部 Finale 均为天劫战 · 隐藏属性对五类事件输入与输出两侧全开

- id: 2026-08-17e-finale-combat-only-and-hidden-stat-io
- date: 2026-08-17
- topic: systems/adventure-event/combat · systems/services/plot-manager · systems/adventure-event/common-properties · systems/services/combat-service · systems/balance
- status: distilled
- distilled-to: systems/adventure-event/combat/_index.md, systems/services/plot-manager.md, systems/adventure-event/common-properties.md, systems/services/combat-service.md, systems/balance.md

## Intent（distilled）

**一句话：** 两条坐在「`combatTier` 三档 × 隐藏属性」交界上的待答项一并收口，方向是**关掉一个尚未存在的分支、打开一个已经存在的通道**——非战斗形态的 Finale **不存在**（全部 Finale 均为天劫战，`EncounterSpec` / `CombatEventResolver` 因此免于分叉），隐藏属性则**对五类事件的输入与输出两侧全开**（由调制与结算输入两条既有通道承载，不新增机制）。**本次零结构增量：不加字段、不加枚举成员、不 bump 存档 schema。**

### ① 全部 Finale 均为天劫战，不设非战斗形态的境界突破路径（承重）

- **境界突破只有一条路径：打赢天劫。** Combat 类的每一条都真的动手，`eventType == Combat` 名副其实。
- **连带关掉的四样东西（都是尚未存在的分支，取消它们不删除任何已落地结构）：**
  - `EncounterSpec` **不加** `Trial` 一类字段，`Enemy` **不必**放宽为可空 ⇒ 「Finale 场次可能无敌人」这一分支从结构中消失，`TurnLimit` / `FirstSide` 恒有意义。
  - `CombatEventResolver` **无内部分派**，恒走 `combat-service.RunCombatAsync`。
  - **不引入试炼求值 / 抉择链 / 等效道念差映射**，不新建 `TrialOutcome` / `TrialResult` 一类类型——那会连带出第二套奖惩换算、第二套残卷判定、第二条失败通道。
  - **危险度刻度无例外**：三档全部有敌人 ⇒ 「精确标注敌人等级」这条唯一难度刻度不需要为任何一档开口子。
- **残卷的累积源与兑现点无形态分叉**，`player-power/_index.md` 不必加澄清句。
- **存档 / 契约影响：无。**

### ② 隐藏属性对五类事件**输入与输出两侧全开**（承重）

产出侧本就全开（`HiddenStatGrade` 对五类开放、可选、不填 = 不推）；本次把**输入侧**一并打开，由两条**既有**通道承载：

| 通道 | 形态 | 适用面 |
|---|---|---|
| **调制通道（主）** | Band 触发 arc → `PlotModulation` 六字段（`TypeWeights` / `EventWhitelist` / `EventWeights` / `EnemyPoolScope` / `LevelBias` / `Tighten`） | 五类一律 |
| **结算输入通道** | 事件的数据驱动 outcome 求值读取隐藏属性当前值作为输入项之一 | 五类一律（Combat 侧经 `EncounterSpec` 的既有可调字段体现） |

**承重边界：输入侧全开**不**等于把隐藏属性接进胜负判定。** `VictoryRule` 仍是单字段 `(int WinMargin)`，不做可替换的判定对象、无需策略枚举、无需分发。隐藏属性影响 Finale 的路径是**拧参数**（更凶的天劫模板、更高的 `WinMargin`、更差的起手），不是**加一条并列的判定条件**。

| 想要的效果 | 既有通道 |
|---|---|
| 煞气高 ⇒ 天劫更凶 | 煞气 Band 3 触发的 arc 用 `Tighten` 拧 `WinMargin` / 用 `EnemyPoolScope` 换更凶的天劫模板 |
| 道心低 ⇒ 渡劫时心魔作梗 | 道心 Band −2 的 arc 同上 |
| 渡劫成败 ⇒ 道心变动 | Finale 条目自己的 `HiddenStatGrade`（见 ③） |

**「输入」不含「作为 `selectCost` 消耗」（口径确认）。** Finale 照旧**不消耗**道心 / 煞气，`selectCost` 的 element 清单仍只有 `lifeSpanCost` 一项。两条理由：**成本侧只放可如实计价的量**（Band 2 精确展示纪律的全部目的是让玩家自己算出「这一步可能是最后一步」，而道心 / 煞气是隐藏量，玩家永远算不出那一格——这与「能力 element 恒不出现在 `selectCost`」是同一条判据的第二个实例）；**它没有消费者**（道心 / 煞气触底不构成终态，截断到 `[0, 100]`，扣了不产生任何可判定的后果）。**连带：「道心 / 煞气是否列入 `CostKey`」那条待答项不受本次施压，原样保留。**

### ③ 隐藏属性推拉：一份 `HiddenStatGrade`、胜负同施，不套 `FailureRatio`

- **`Finale` 档：胜利与失败都推道心。** 渡劫这件事本身塑造道心，成败只改变塑造的内容，不改变「它发生了」。
- **`Practice` 档默认口径：推道心（对位低一档）· 默认不推煞气。** `WinMargin 0`「道念相等即判胜」正是**点到为止**的机制表达——切磋是磨砺心性，不是杀伐。「对位低一档」沿用 `ExperienceGrade` 已有的档位偏置范式（低风险 ⇒ 产出对位低一档），不是新规则。
- **`Standard` 档**逐条目编排；常规遭遇是煞气的主要来源。
- **三条都是内容编排的默认口径，逐条目可覆盖，「不填 = 不推」照常成立。**
- **不套用 `FailureRatio`（承重）。** 经验有 `FailureRatio` 是因为经验的语义是「**学到多少**」，失败也学到、按比例折算说得通；隐藏属性的语义是「**做了什么**」——屠戮就是屠戮，胜负不改变行为的性质。且道心是**双向**属性，「失败时道心下降取 50%」在语义上无从解释。**日后若确需让胜负推不同的量，正确形态是内容侧第二个可空的档位字段（可正可负、语义自洽），不是一个比率**——可空字段不牵动存档迁移。
- 映射值归 ch1 数值标杆专场。

### ④ 隐藏属性剧情线**不转入 `Finale`**；高潮形态 = 被 `PlotModulation` 拧过的 `Standard` 档 Combat

四条理由，第一条是致命的：

1. **它会当场炸掉残卷的结构封印。** 「每角色每篇章至多累积一次或掷骰一次，且二者互斥」这条不变式的**唯一支撑就是「每篇章一个 Finale」**；剧情线若能造出第二个 Finale，玩家可以靠推煞气 / 掉道心在一个篇章内刷出额外的残卷累积，而「残卷不需要任何额外的冷却 / 次数上限规则」这条豁免会立刻失效。
2. **Finale 的出现条件是一条等级条件**（已达本境界巅峰），而剧情线可能在篇章中段触发——此时天劫 `diff = +1` 的自洽性验证不成立，「渡劫 = 突破到下一境界」的叙事随之破裂。
3. **PlotManager 在数据形态上够不着 Finale。** `PlotModulation` 六字段里写不出 `eventPriority`、写不出 `combatTier`、写不出模板的任何字段。**这条不需要新规则来禁止，它已经被数据形态禁止了。**
4. ADR-0004 以 Finale 为篇章重试的锚点；第二个 Finale 会让「篇章边界」这个概念本身歧义。

**替代形态（零新结构）：** 现有六个字段刚好凑齐一个「剧情线 boss」——`EventWhitelist`（本批只出这条线的事件）· `EnemyPoolScope`（派心魔 / 煞气化身而非常规敌人）· `Tighten` + `LevelBias`（比常规遭遇更凶）· `TypeWeights` / `EventWeights`（这条线的事件更容易出现）。**代价明写，也正是想要的：剧情线 boss 不给残卷、不是篇章闸门、失败不影响境界突破。** 它是一段风味与压力，不是第二个篇章收口。

### ⑤ 一处前提更正：「大限将至」不是剧情线

待答清单把「大限将至」列作隐藏属性剧情线的例子，但它对应**寿元归 0（终态）**，不是任何一档，**不经 `PlotTriggerId` 通道**——寿元归 0 时角色已 `defeated`，**没有任何东西可以转入**。真正经 `PlotTriggerId` 的只有两条：煞气 Band 3「煞气反噬」、道心 Band −2「心魔滋生」。故这一半不是「要不要转入 Finale」，而是问题的前提本身已被档位模型改写；本次一并修正清单措辞。

### 落地面

| # | 落点 | 改动 |
|---|---|---|
| 1 | `adventure-event/combat/_index.md` | 「少部分 Finale 不是战斗」→「全部 Finale 均为天劫战」；新增 Finale / Practice 的隐藏属性口径；两条待决问题移除、一条收窄 |
| 2 | `services/plot-manager.md` | 两条明写：剧情线不转入 Finale（四条理由 + 替代形态）· 隐藏属性输入 / 输出两侧对五类全开且 `VictoryRule` 不受触动 |
| 3 | `adventure-event/common-properties.md` | 隐藏属性推拉一份 `HiddenStatGrade`、胜负同施、不套 `FailureRatio`；日后分化的落点是可空档位字段 |
| 4 | `services/combat-service.md` | 「少部分非战斗形态的 Finale 亦待日后定制」的尾巴收掉 |
| 5 | `systems/balance.md` | `HiddenStatGrade` 段挂 Finale / Practice 两档的映射挂钩点（归 ch1 数值标杆专场） |

**存档 / 契约影响：无。** `EncounterSpec` 不动 · `CombatEventResolver` 不动 · `EventOutcome` 四值不动 · `CombatOutcome` 三值不动 · `PastEventEntry` 不动 · `PlotKeyPoint` 不动 · `PlotModulation` 六字段不动 · `ProfileChangeSpec` 不增列 · `selectCost` element 清单不动 ⇒ **无 schema bump、无迁移**。**对后端库零影响**——本次全部落在客户端本地的内容编排与结算参数上，不触及任何协议契约（`characterProfile` 内的隐藏属性字段在 `contracts/profile-sync.md` 中属不透明段）。

## Clarifications（评审裁决）

草稿以 `status: decided` 进入本次提炼；**定案推翻了原草稿的主体方案**，正文已按裁决改写：

1. **是否存在非战斗形态的 Finale** → **不存在**（**推翻原推荐**「非战斗 Finale 作为 Combat 类特例、载体为 `EncounterSpec.Trial` 可空字段」）。
2. **是否引入非战斗试炼** → **不引入**（**推翻原推荐**的 `TrialSpec` / 试炼求值 / 抉择链形态与等效道念差映射）。
3. **隐藏属性与五类事件的关系** → **输入与输出两侧全开**（**扩大**原建议——原建议 Finale 不检定、只谈产出侧）。承重限定：不等于接进胜负判定，`VictoryRule` 仍是单字段。
4. **Finale 的 `HiddenStatGrade` 口径** → **胜利与失败都推道心**（**改**原建议「胜利推 `Major`、失败不推」）。
5. **口径确认：定案 3 的「输入」= 可被读取、可影响结算与调制，不含「作为 `selectCost` 消耗」** ⇒ 第 ② 条末段「Finale 不消耗隐藏属性」保持成立。

原草稿的试炼形态三选一、非战斗 Finale 的三章分布、以及 `eventType == Combat` 的命名张力口径澄清，**随定案 1、2 一并作废**——没有承载对象。被否决方案的完整论证保留在 `inbox/archive/solution-draft-combat-finale-and-hidden-attributes.md` 的「备选方案」一节作溯源。

## Open questions

- **隐藏属性的增减触发（逐条目编排）仍未定。** 本次给的是 `Practice` / `Finale` 两档的**默认口径**，它是那条待答项的一个子集；「哪些 AdventureEvent 推哪个属性、各推哪一档」仍需与它一并定。→ `systems/services/plot-manager.md`。
- **`HiddenStatGrade` 的映射值与 Finale / Practice 的奖励厚薄**归 ch1 数值标杆专场（本次按范围要求不替它拍任何数值）。→ `systems/balance.md`。
- **「道心 / 煞气是否列入 `CostKey`」照旧独立待答**——本次明确不给它施加压力（Finale 不消耗隐藏属性），两者各自定稿。→ `systems/services/profile-service.md`。

## Notes / triage

- 输入：`inbox/solution-draft-combat-finale-and-hidden-attributes.md`（`status: decided`），已归档进 `inbox/archive/`。
- 本次答结并移出 2 条待答项，见 `answer-logs/log-combat-finale-and-hidden-attributes.md`。
- 本次是同日第五场专场。前四场（Travel / Research / Explore / Exchange）已把 `EventOption` 骨架推到十一字段、并改写了事务纪律与 `AppliedChange` 语义；**本次不新增任何字段、不触碰那两条纪律**。
