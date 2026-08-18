---
type: solution-draft
date: 2026-08-17
question: 是否存在非境界突破的寿元增长途径？若存在，它的载体、施加路径、展示纪律与平衡护栏各是什么？
source: open-questions/04-hidden-attributes-plot.md → 「非境界突破的寿元增长途径」
targets: systems/adventure-event/common-properties.md · systems/character-profile/item/_index.md · systems/services/profile-service.md · systems/services/plot-manager.md · systems/balance.md · systems/monetization.md
status: distilled
decided-on: 2026-08-17
reviewed: 2026-08-17 — 四项取向一律取推荐项（回寿只走 outcome 侧 · 数字与 selectCost 同 Band 2 门控 · 中档 10% · 不设每篇章回寿总量硬上限）
distilled-to: handoffs/2026-08-17f-lifespan-restoration-paths.md
---

> **本草稿已裁决（2026-08-17）：全部取向项一律按推荐方案定案。** 逐项见文末「## 仍需用户决定 → 已全部裁决」。

# 方案草稿 — 非境界突破的寿元增长途径

## 问题

`open-questions/04-hidden-attributes-plot.md` 第 12 行：**「非境界突破的寿元增长途径。是否存在（回寿类事件产出）未定。」**

**用户已给出方向（本次运行的输入）：`存在`，形态「类似补天丹的效果」** —— 即一件可使用的、能补回寿元的丹药类道具。故本草稿**不再讨论「存不存在」**，只推演**它落成什么**：载体有几条、走哪条施加路径、怎么展示、拿什么拦住它的平衡漏洞。

它悬着卡住的东西比看上去多：寿元是**唯一有精确显示通道**的隐藏属性（Band 2 红字倒数），也是**篇章时长的主旋钮**。一条回寿通道同时碰到「给方向不给数字」的呈现纪律、`lifeSpanCost` 的定价反推链、以及 monetization 明写排除的「付费续命」。

## 约束（来自既有设计）

- **寿元走资源 element 路径，不走 `HiddenStatGrade`。** `ResourceElements` 表已有 `LifeSpan` 行 `(Min = 0, Max = 无, DepletionDefeat = LifeSpanExhausted, CostModifier = LifeSpanCost, GainModifier = null)`。→ `systems/services/profile-service.md`
- **`ChangeElement.BaseValue` 带符号，成本与产出共用一个类型**；内容侧写正数量值，物化时按方向取负。→ `systems/adventure-event/common-properties.md`
- **成本侧展示挂寿元档位：Band 0 / Band 1 完全不显示 `selectCost`，Band 2 如实展示精确扣减量。** 与红字倒数同一个开关。→ 同上 · `systems/services/plot-manager.md`
- **`selectCost` 无条件施加，支付后立即做终态判定 ①**（判负则短路，事件不进 resolver）。→ `systems/services/life-cycle-service.md`
- **档号 = 离常态的距离；`|newBand| > |oldBand|` 才播叙事，回落一律静默。** 寿元回滞 δ = 3 个百分点。→ `systems/services/plot-manager.md`
- **寿元百分比的分母 = `Status.ChapterLifeSpanBudget`，由 ChapterManager 在篇章边界冻结**，章内不变。→ `systems/services/life-cycle-service.md`
- **付费面五项排除的第一条 = 付费续命 / 复活**（ADR-0004 的失败压力线不得被按次取消）。付费礼包从 `(Item, Player)` 池抽 2 件古宝。→ `systems/monetization.md`
- **`lifeSpanCost` 定价表已明写允许「产出向（回寿）的覆盖值」**（`systems/balance.md` 与 `systems/adventure-event/common-properties.md` 各一处）——本草稿要动的正是这半句，见「与既有决策的张力」。
- **道具战斗内形态、储物袋 9 格、`ItemData` 字段形态、消耗即时经 `TryApply` 写档**均已定案。→ `systems/character-profile/item/_index.md`

## 建议方案

### 1. 三条获取通道，一条施加路径

`[既有推演]`

建议**通道分三条、路径只留一条**：

| 通道 | 形态 | 依据 |
|---|---|---|
| **A · 回寿事件产出** | AdventureEvent 的 outcome 侧产出 `ChangeElement(LifeSpan, +n)` | 待答项自己点名的形态（「回寿类事件产出」）；`ResolveOutcome` → `eventEnd` 合并 `TryApply` 现成 |
| **B · 补天丹（法宝）** | `ItemData`，`Scope = Character`、`UsableScene = OutOfCombat`、`Charges` 有限，其 ability 产出 `ChangeElement(LifeSpan, +n)` | 用户点名的形态；`magicPack` 与「消耗即时经 `TryApply` 写档」现成 |
| **C · 商店购入 B** | Exchange 库存中出现补天丹 ⇒ jade ↔ lifeSpan 的兑换接口 | 纯内容编排，零新增结构。**阻于 Exchange 专场未开**，见「前置依赖」 |

**三条通道共用同一条施加路径**：`ChangeElement(Key = CostKey.LifeSpan, BaseValue = +n)` 落进那一次 `TryApply`。

**推论（承重）：本方案不新增任何字段、不新增任何 element、不 bump 存档 schema。** `LifeSpan` 已在 `ResourceElements` 表里、`BaseValue` 已带符号、`PastEventEntry.AppliedChange` 已记最终 spec、`LifeSpanAfter` 已记结算后余量、寿元曲线因此自动画得出回升段。**这是本方案最强的一条论据——「存在回寿途径」在结构上是零成本的，代价全在呈现与平衡两侧。**

### 2. 回寿只走 outcome 侧，`lifeSpanCost` 的取值域收紧为非负（承重 · 与既有文本冲突）

`[既有推演]`

建议**明确写死：`selectCost` 内的 `LifeSpan` element 恒为消耗向（内容侧量值 ≥ 0，物化后 `BaseValue ≤ 0`）**，回寿一律落 outcome / reward 侧。三条理由，第一条是硬的：

1. **成本侧回寿会改写终态判定 ① 的语义。** 既定流程是「`TryApply(SelectCost)` → 立刻判负 → 判负则短路」。若某个事件在成本侧写产出向，玩家在寿元剩 1 点时选它**反而先被加寿元**，「支付后判定」这一步从压力点变成救命点——「明知是死路仍然走」这条承重取向被一个内容条目的符号翻转悄悄取消。
2. **成本侧回寿会让 Band 2 的展示自相矛盾。** Band 2 的既定语义是「如实展示精确扣减量」；一条 `+8` 的「扣减量」要么显示成负扣减（读者当场读成 bug），要么要为它单开一套呈现分支——为一个可以不存在的形态加一层 UI 状态。
3. **入场费与后果是两个概念。** 这与既定的「能力 element 恒不出现在 `selectCost`」是同一条判据的第二个实例：**成本侧只放「进这扇门要付什么」，产出一律是事件的后果。** 一条能倒贴的入场费不是入场费。

**可机械检查的形态**（与 `SelectCost.AbilityElements` 恒空同款，两处 `PushError`）：

- 内容模板加载期：`lifeSpanCost` 的表值 / 覆盖值为负 → `PushError` + 条目 `Id`；
- future-event-service 物化组装后断言：`SelectCost.Elements` 中 `Key == LifeSpan` 者 `BaseValue <= 0` → 否则 `PushError`。

> 这一条直接改写 `systems/balance.md` 与 `systems/adventure-event/common-properties.md` 各一处现有文本，见「与既有决策的张力」。

### 3. 回寿量的展示与成本侧同一个开关（承重）

`[既有推演]`

**建议：回寿的精确数值同样只在寿元 Band 2 出现；Band 0 / Band 1 一律定性文案，不给数字。** 适用于三处：eventOption 卡片上的收益标注、补天丹的道具描述、结算面板的 `AppliedChange` 陈列中的寿元行。

依据是一条反证：**若一个 eventOption 明写「+10 寿元」，寿元的绝对量纲当场泄露。** 玩家由此可反推自己每一步花了多少、还剩多少步——而「Band 0 / Band 1 不显示 `selectCost`」这条纪律付出的全部代价（省着花的策略在常态档不可被精细执行）就是为了封住这件事。**只封成本侧不封产出侧，等于留了一扇后门，而后门比正门更宽**（成本是逐事件的小数，回寿是一次性的大数，更容易被当作标尺）。

具体形态：

| 位置 | Band 0 / Band 1 | Band 2 |
|---|---|---|
| eventOption 卡片 | 定性标签（如「延年」），无数字 | 如实展示 `+n`，与 `selectCost` 的 `−m` 并列 |
| 补天丹道具描述 | 定性正文（「服之可补益寿元」），无数字 | 同上，补一行精确值 |
| 结算面板寿元行 | 定性一行 | 精确值 |

- **它不是新机制，是既有档位表的第六个消费方**，判据仍是「寿元 Band == 2」，与红字倒数、`selectCost` 精确展示**同一个开关、同时开启**。不新增字段、不新增流程。
- **道具描述的门控是唯一略麻烦的一处**：`ItemData` 的描述是 `LocalizedText` 静态文案，做不到按 Band 变体。建议解法：**正文恒为定性文案，精确值由 UI 在 Band 2 时追加一行**（数值来自 ability 定义，不写进文案）——这与「快照里一个字符串正文都不存」「文案跟随模板」的既有分层一致，也让翻译侧不必为两种 Band 各写一版。
- **代价明写：** 玩家在常态档无法比较「这颗丹值不值这个价」。这**正是取向本身**，与「eventOption 不标注经验产出数字」是同一条纪律的又一个实例。

### 4. 补天丹限定 `Scope = Character`；`(Item, Player)` 池排除一切寿元产出（承重）

`[既有推演]`

**建议：能产出 `LifeSpan` 的 `ItemData` 必须 `Scope == AbilityScope.Character`（法宝），账号级古宝一概不得含寿元产出。**

依据是 monetization 明写的第一条排除：**付费续命 / 复活**。付费礼包从 `(Item, Player)` 池**抽 2 件古宝**，池中一旦有回寿古宝，「花钱 → 抽到 → 续寿」就是付费续命的软形态——它甚至绕过了那条排除的字面表述（没有「撤销一次 `defeated`」，只是让 `defeated` 更晚到来），而 ADR-0004 那条压力线是按次被稀释的，效果相同。

**可机械检查的形态**（加载期，`PushError` + 条目 `Id`）：

```
ItemData.Scope == Player 且其 Abilities 含 LifeSpan 产出  → PushError
ItemData 含 LifeSpan 产出 且 UsableScene 含 InCombat      → PushError
```

第二条的依据是既定的「lifeTotal 是战斗内血量的替代、寿元战斗内不参与」——战斗内根本没有寿元结算通道，一件能在战斗内回寿的道具指向一条不存在的路径。

**连带（提醒而非新规则）：** 付费的战斗价值由古宝承载这条既定分工不受影响——它讲的是战斗内价值，而回寿是战斗外资源线。

### 5. 平衡护栏：不加硬上限，靠「回寿事件自己也要付费 + 稀有度」两道软闸

`[通行做法]` + `[既有推演]`

回寿通道的真实风险是**时长旋钮被架空**：`lifeSpanCost` 定价表是按目标时长（30–40 / 35–45 / 45–55 分钟）反推的，一条不受控的回寿通道能把一轮回无限拉长。

建议**不设「每篇章回寿总量上限」一类的硬结构**，理由是既有的两道闸已经把正反馈掐死：

1. **回寿事件本身照常付 `selectCost`**（它是一个普通 AdventureEvent，占一个事件位）⇒ 净收益 = 回寿量 − 该事件定价，**恒小于回寿量**；
2. **回寿事件占 `eventCountLimit` 配额** ⇒ 它挤掉的是别的事件，不能凭空多做事情；
3. 补天丹占**储物袋 9 格中的一格**（按 `ItemId` 堆叠，同 `ItemId` 多份仍占 1 格——故它对种类数这条取舍位施压，而这正是 9 格上限的设计意图）。

**可调旋钮因此落在纯内容侧**：回寿事件 / 补天丹的 `RarityTier` 档与抽取权重、回寿量的表值。**改数值不改结构。**

> **与 Travel 定价那条结构性约束的区别（写明以免被误推广）：** Travel 必须 > 0 是因为它**不占** `eventCountLimit` 配额、能开出零成本 reroll；回寿事件占配额，不存在同款漏洞，故不需要一条「必须如何」的结构性约束。

### 6. 回寿量的标定口径 = 本章预算的百分比（不是绝对点数）

`[通行做法]`

**建议：回寿量在 `systems/balance.md` 中以「占本章 `ChapterLifeSpanBudget` 的百分比」推导，落表时写成各篇章的绝对点数**（内容侧仍写正数量值，链路不变）。

理由：绝对点数会在三章之间失真（ch1 预算 100、ch3 预算 300 + 结转，同一个「+10」在两章的意义差 3 倍以上）；百分比口径与寿元 Band 的阈值（30% / 10%）**同量纲**，让「一颗丹能把玩家拉回几档」成为可直接读出的设计量。

**推荐初值三档（待 ch1 数值标杆专场校准）：**

| 档 | 占本章预算 | 手感目标 |
|---|---|---|
| 小 | **5%** | 缓一口气，不改变所处档 |
| 中 | **10%** | **Band 2 中位（≈5%）→ 15% = Band 1** —— 恰好拉回一档 |
| 大 | **20%** | Band 1 → Band 0，一次显著的战略续航 |

- **中档的取值是被 Band 阈值反推出来的，不是拍的**：10% 使「濒死时一颗补天丹换回一档」成立，而这正是「补天丹」这个题材词承诺给玩家的手感。
- **三档是量值口径，不是新枚举**——它与隐藏属性推拉的 `HiddenStatGrade { Minor, Standard, Major }` **不是同一个东西，也不得复用**：寿元走资源 element 路径（绝对量值），`HiddenStatGrade` 是道心 / 煞气推拉的档位映射。（这与 `Tier` / `RarityTier` 那条硬约定同性质。）
- 落表位置建议与 `lifeSpanCost` 定价表并列，同为「事件类型 × 篇章」形态的一张小表。

### 7. `LifeSpan.GainModifier` 保持 `null`

`[既有推演]`

`ResourceElements` 表中 `LifeSpan` 的 `GainModifier` 现为 `null`，理由写的是「产出向无既定修正意图」。**回寿通道确立后，这一格建议仍留 `null`**：

- `Elements` 的 modifier 准入是 **opt-in 白名单、缺省豁免**——没有具体法则条目时不该先占位；
- 一条「延寿 +X%」的法则会**直接乘上时长旋钮**，且它是账号级永久持有的，须按「老账号全开」校准难度曲线；先不开这个口子，日后确需时**加一行即可，零结构改动**。

### 8. 剧本侧零改动

`[既有推演]`

- **PlotModulation 已能调节回寿事件的出现**（`EventWeights` / `TypeWeights` 抬权重），**不需要任何新字段**——「大限将至」的剧情线因此可以在压力最大时把回寿机会摆到玩家面前，而这仍是「只调内容不调约束」。
- **寿元回落的叙事按既定规则静默**：回寿使 `|BandIndex|` 减小 = 靠近常态 ⇒ 不播文案，只更新 band 字段。回滞 δ = 3 个百分点自动挡住「在阈值上反复上下」的抖动。**答任一侧都不改结构**这条既有判断因此保持成立。

### 9. 明确不做的两件事

`[既有推演]`

- **不抬高 `ChapterLifeSpanBudget`。** 回寿后剩余寿元可能超过冻结的分母（百分比 > 100%）——**这被接受**：分母是篇章边界的口径量，章内抬高会让 30% / 10% 阈值在章内漂移，而回滞机制假定阈值不动。>100% 仍落在 Band 0，无任何呈现问题。
- **不为回寿设 `Max` 上界。** `LifeSpan` 行的 `Max = 无` 是既定的（与 `LifeTotal` 同款「只跟踪单值、无上限截断」）；加上界会引出「补满时用丹浪费」这一整类挫败感，而 `lifeTotal` 那边正是**专门删掉上限字段**来消掉它的。

## 具体形态（可 derive 的落地面）

**施加路径（三通道共用，零新增类型）：**

```csharp
// 回寿事件 outcome 侧 / 补天丹使用，均组装出：
new ChangeElement(CostKey.LifeSpan, +restoreAmount)
// → 并入 eventEnd 那一次 TryApply（事件侧），或即时 TryApply（道具侧）
// → Evaluate 内：GainModifier == null ⇒ 不经 pipeline；Clamp(raw, 0, null) 无上界截断
```

**加载期校验（新增四条，全部 `PushError` + 条目 `Id`）：**

| 违规 | 处置 | 依据 |
|---|---|---|
| `lifeSpanCost` 的表值 / 条目覆盖值为负（成本侧产出向） | `PushError` | 建议 2 |
| 物化后 `SelectCost.Elements` 中 `Key == LifeSpan` 且 `BaseValue > 0` | `PushError`（断言） | 建议 2 |
| `ItemData.Scope == Player` 且 abilities 含 `LifeSpan` 产出 | `PushError` | 建议 4 |
| `ItemData` 含 `LifeSpan` 产出 且 `UsableScene` 含 `InCombat` | `PushError` | 建议 4 |

**呈现门控（第六个「寿元 Band == 2」消费方）：** eventOption 收益标注 · 道具描述附加行 · 结算面板寿元行，三处同开关。

**平衡表新增（归 ch1 数值标杆专场填值）：** 回寿量三档 `5% / 10% / 20% × ch1 / ch2 / ch3` 的绝对点数。

## 后果

- **存档 schema：零改动、不 bump、无迁移。** 全部复用 `ChangeElement` / `AppliedChange` / `LifeSpanAfter`。
- **受影响文档：**
  - `systems/adventure-event/common-properties.md` —— 改写「产出向（回寿）覆盖值」那半句（建议 2）；新增回寿收益的展示门控（建议 3）。
  - `systems/balance.md` —— 同上一处改写；新增回寿量三档表（建议 6）。
  - `systems/character-profile/item/_index.md` —— 补天丹形态与两条 `ItemData` 校验（建议 4）；**它同时给该文档「道具的战斗外获取途径与效果未设计」这条待决项添上第一个具体条目**。
  - `systems/services/profile-service.md` —— `LifeSpan` 行 `GainModifier` 保持 `null` 的理由改写为「已有回寿通道，仍不开修正口」（建议 7）。
  - `systems/services/plot-manager.md` · `life-cycle-service.md` —— 待决项「是否有非境界突破的寿元增长途径」移出，档位表消费方由五增至六。
  - `systems/monetization.md` —— 五项排除的第一条补一句连带（回寿古宝被结构性关死，建议 4）。
- **`ux/` 侧**：eventOption 卡片与结算面板各多一处 Band 门控的呈现分支；储物袋新增「战斗外使用」入口——**但后者的形态未设计**，见前置依赖。

## 备选方案（已考虑并否决）

- **回寿作为 `selectCost` 的负成本（即保留现有文本）** —— 否决：改写终态判定 ① 的语义、与 Band 2 展示纪律冲突。见建议 2。
- **回寿走 `HiddenStatGrade` 三档映射**（与道心 / 煞气同款） —— 否决：寿元已在 `CostKey` / `ResourceElements` 中走资源 element 路径，两条路径并存会让同一个字段有两个写入语义，且三档映射值（`Minor 2 / Standard 5 / Major 10`）是为 `[0,100]` 取值域的属性标定的，套不到跨章 100 / 200 / 300+ 的寿元预算上。
- **给寿元设上界（如 `Max = ChapterLifeSpanBudget`）** —— 否决：引回「补满时用丹浪费」的挫败感，而 `lifeTotal` 那条线正是专门删掉上限来消掉它的；且与既定的 `Max = 无` 冲突。
- **每篇章回寿总量硬上限** —— 否决：需要一个新的存档字段（本章已回寿累计）与一处新校验，而两道软闸（占事件位 + 占配额）已把正反馈掐死。见建议 5。
- **回寿量写绝对点数、不设百分比推导口径** —— 否决：三章预算差 3 倍以上，同一个绝对值在 ch1 是救命、在 ch3 是零头，且失去与 Band 阈值同量纲这一便利。

## 与既有决策的张力

**一处，明确的正面冲突：**

`systems/adventure-event/common-properties.md` 第 79 / 83 行与 `systems/balance.md` 第 75 行现明写：

> 「内容条目只在需要体现代价差异时标一个偏移 / **覆盖值**（**含产出向的回寿事件**）」
> 「个别事件可在表值之外设更小或**产出向（回寿）的覆盖值**」

**这三处把回寿放在了 `selectCost` 成本侧**，而建议 2 主张回寿只走 outcome 侧、成本侧取值域收紧为非负。

- **为什么需要它松动：** 见建议 2 的三条理由，其中第一条（成本侧回寿把「支付后判负」从压力点变成救命点）是规则层的语义改写，不是风格问题。
- **松动的代价：** 内容作者少一个书写位——想做「一个便宜又回寿的事件」时，要写成「表值定价 + outcome 侧产出」两处，而不是在一格里写个负数。**这个代价很小**：定价表本就默认不填、取类型基准值，作者的默认动作不变。
- **不松动时的替代方案：** 保留成本侧产出向，但补两条规则——① 终态判定 ① 之前先算净额（等于在流程里插一步「先加后判」，与「无条件施加、支付后判定」的既定表述打架）；② Band 2 展示改为「显示净额」（读者要理解一个可正可负的「扣减量」）。**两条都是为一个可以不存在的形态加复杂度**，故推荐松动。
- **裁决权在用户。** 若用户选择保留现有文本，本草稿的其余八条建议全部不受影响（它们不依赖建议 2）。

## 前置依赖

- **战斗外道具的使用入口未设计（承重）。** `systems/character-profile/item/_index.md` 只定义了**战斗内**的使用窗口（自己回合行动阶段、栈为空时）；`UsableScene = OutOfCombat` 的道具**在哪一屏、哪一步被使用**尚无设计。补天丹（通道 B）在这一条答定前无法定稿。
  **建议形态（供该专场参考，本草稿不替它拍板）：** 在 eventOptions 选择屏可打开储物袋面板使用 `OutOfCombat` 道具；使用**不占事件位、不扣 `lifeSpanCost`**，即时经 `ProfileManager.TryApply` 写档（沿用既定的「消耗即时写、不攒到收口」），是否单独构成一个存档点归「决策点粒度」那一问。
- **ch1 数值标杆专场未开** —— 回寿量三档的绝对点数、以及它与 `lifeSpanCost` 定价表的联合反推（回寿量占「几个事件的时间」）无法定稿。**不阻塞结构**：建议 6 给的是标定口径与百分比初值，绝对值是待校准项。
- **Exchange 专场未开** —— 通道 C（商店售卖补天丹）的库存生成 / 定价 / 刷新形态未定。**不阻塞通道 A / B**。
- **道具种类目录与「什么该做成卡 / 道具 / 神通」的判据未给** —— 补天丹是该目录的第一个具体条目，但目录本身的组织方式未定。

## 仍需用户决定 → **已全部裁决（2026-08-17）**

> **定案：四项一律取推荐项。** 即：① 回寿**收紧为只走 outcome 侧**（成本侧 `LifeSpan` 取值域非负 + 两条 `PushError`），三处现有文本据此改写 · ② 回寿收益数字**与 `selectCost` 同门控**（Band 2 才给数字）· ③ 回寿量中档取 **10%**（濒死时一颗丹恰好拉回一档）· ④ **接受**「不设每篇章回寿总量硬上限」。
>
> 下列原文保留为选项与理由的溯源。

1. **【建议 2 的裁决 · 唯一的硬冲突】回寿是否收紧为「只走 outcome 侧」，从而改写三处现有文本？**
   - **推荐：收紧**（成本侧 `LifeSpan` 取值域非负 + 两条 `PushError`）。理由：成本侧回寿改写终态判定 ① 的语义，把「明知是死路仍然走」这条承重取向交给一个内容条目的符号去决定。
   - 备选：保留现有文本，另补「先加后判」与「净额展示」两条规则。
2. **【建议 3】回寿收益的数字是否与 `selectCost` 同门控（Band 2 才给数字）？**
   - **推荐：同门控。** 只封成本侧不封产出侧等于给寿元量纲留后门，且产出是大数、更适合当标尺。
   - 代价：玩家在常态档无法比较「这颗丹值不值这个价」——这是既定「给方向不给数字」纪律的延伸，不是新代价。
   - 备选：产出侧恒给精确数字（呈现更友好，但寿元的绝对量纲当场泄露，`selectCost` 的门控随之失去意义）。
3. **【建议 6】回寿量的中档取 10%（濒死时一颗丹恰好拉回一档）这个手感目标是否是你要的？**
   - **推荐：是。** 它由 Band 阈值反推而来，也是「补天丹」这个题材词对玩家的隐含承诺。
   - 备选：中档取 5%（更保守，丹药只是缓一口气、不改变所处档；寿元压力线更硬）。
4. **【建议 5】是否接受「不设每篇章回寿总量硬上限」？**
   - **推荐：接受。** 占事件位 + 占配额两道软闸已掐死正反馈，硬上限要新增一个存档字段。
   - 备选：设硬上限（结构更稳，代价是一个新存档字段 + 一处新校验 + 一条要向玩家解释的隐形规则）。
