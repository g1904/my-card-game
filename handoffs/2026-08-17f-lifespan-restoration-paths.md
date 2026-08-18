# 非境界突破的寿元回复通道：只走 outcome 侧，展示与 `selectCost` 同门控

- id: 2026-08-17f-lifespan-restoration-paths
- date: 2026-08-17
- topic: systems/adventure-event/common-properties · systems/balance · systems/character-profile/item · systems/character-profile/power · systems/services/profile-service · systems/services/plot-manager · systems/services/life-cycle-service · systems/monetization · systems/adventure-event/travel · systems/adventure-event/exchange · ux/screen-flow
- status: distilled
- distilled-to: systems/adventure-event/common-properties.md, systems/balance.md, systems/character-profile/item/_index.md, systems/character-profile/power/_index.md, systems/services/profile-service.md, systems/services/plot-manager.md, systems/services/life-cycle-service.md, systems/monetization.md, systems/adventure-event/travel/_index.md, systems/adventure-event/exchange/_index.md, ux/screen-flow.md

## Intent（distilled）

**一句话：** 非境界突破的寿元回复通道**存在**，形态是「补天丹」一类的可使用法宝与回寿事件产出；但它落地的代价不在结构（**零新增字段、零新增 element、不 bump 存档 schema**），而全部在**呈现纪律**与**平衡护栏**两侧——回寿因此被收紧为**只走 outcome 侧**（`selectCost` 内的 `LifeSpan` 取值域收紧为非负），回寿数字**与 `selectCost` 共用寿元 Band 2 那一个开关**，并由一组加载期校验把「无次数上限的回寿源」与「不占配额的回寿事件」两条正反馈通道钉死在编译 / 启动期。

### ① 三条获取通道，一条施加路径

| 通道 | 形态 |
|---|---|
| **A · 回寿事件产出** | AdventureEvent 的 outcome 侧产出 `ChangeElement(LifeSpan, +n)`，随 `ResolveOutcome` 并入 `eventEnd` 那一次合并 `TryApply` |
| **B · 补天丹（法宝）** | `ItemData`，`Scope = AbilityScope.Character` · `UsableScene = OutOfCombat` · `Charges` 为有限正整数；其 ability 产出 `ChangeElement(LifeSpan, +n)`，使用时即时经 `ProfileManager.TryApply` 写档 |
| **C · 商店购入 B** | 补天丹是 `ExchangeGoodsKind.CharacterItem` 一族的一个普通内容条目，走既有购买路径：`ChangeElement(Jade, -ListPrice)` + `AbilityChangeElement(Grant, Item, Character, id, Source.ExchangePurchase)`，定价取「商品族 × 稀有度」表的 `CharacterItem` 行。**纯内容编排，零新增结构** |

**三条共用同一条施加路径**：`ChangeElement(CostKey.LifeSpan, +n)` 落进一次 `TryApply`。

**承重推论：本方案不新增任何字段、不新增任何 element、不 bump 存档 schema。** `LifeSpan` 已在 `ResourceElements` 表里、`ChangeElement.BaseValue` 已带符号、`PastEventEntry.AppliedChange` 已记本次事件的最终账、`LifeSpanAfter` 已记结算后余量 ⇒ 元进程的寿元曲线自动画得出回升段。**「存在回寿途径」在结构上是零成本的。**

**与 Research 的 `Recuperate` 是两个量，不得混淆：** `Recuperate` 回复的是 `lifeTotal`（战斗耐久），本条回复的是 `lifeSpan`（寿命预算）。两者在 `ResourceElements` 表里各占一行、终态原因各异（`LifeTotalExhausted` / `LifeSpanExhausted`）。

### ② 回寿只走 outcome 侧，`selectCost` 内的 `LifeSpan` 取值域收紧为非负（承重 · 改写三处现有文本）

**`selectCost` 内的 `LifeSpan` element 恒为消耗向**（内容侧量值 ≥ 0，物化取负后 `BaseValue ≤ 0`），回寿一律落 outcome / reward 侧。三条理由，第一条是硬的：

1. **成本侧回寿会改写终态判定 ① 的语义。** 既定流程是「`TryApply(SelectCost)` → 立刻判负 → 判负则短路」。若某条目在成本侧写产出向，玩家在寿元剩 1 点时选它**反而先被加寿元**，「支付后判定」这一步从压力点变成救命点——「明知是死路仍然走」这条承重取向被一个内容条目的符号翻转悄悄取消。
2. **成本侧回寿会让 Band 2 的展示自相矛盾。** Band 2 的既定语义是「如实展示精确扣减量」；一条 `+8` 的「扣减量」要么显示成负扣减（读者当场读成 bug），要么要为它单开一套呈现分支——为一个可以不存在的形态加一层 UI 状态。
3. **入场费与后果是两个概念。** 与「能力 element 恒不出现在 `selectCost`」「卡组 element 恒不出现在 `selectCost`」是同一条判据的第三个实例：**成本侧只放「进这扇门要付什么」，产出一律是事件的后果。** 一条能倒贴的入场费不是入场费。

**它与前两条不变式形状不同，不合并。** 前两条是「某个列表恒为空」，本条是「`Elements` 内某个 key 的**取值域**收紧」——`Elements` 在成本侧本就非空。三条各自落一处断言 + 一处加载期校验。

**被松动的代价（如实记）：** 内容作者少一个书写位——想做「一个便宜又回寿的事件」要写成「表值定价 + outcome 侧产出」两处，而不是在定价格里写个负数。**代价很小**：定价表本就默认不填、取类型基准值，作者的默认动作不变。

**不松动时的替代方案（已否决）：** ① 终态判定 ① 之前先算净额（等于在流程里插一步「先加后判」，与「无条件施加、支付后判定」正面打架）；② Band 2 改为「显示净额」（读者要理解一个可正可负的「扣减量」）。两条都是为一个可以不存在的形态加复杂度。

### ③ 回寿的数字与 `selectCost` 同一个开关（承重）

**回寿的精确数值同样只在寿元 Band 2 出现；Band 0 / Band 1 一律定性文案，不给数字。**

| 位置 | Band 0 / Band 1 | Band 2 |
|---|---|---|
| eventOption 卡片上的收益标注 | 定性标签（「延年」），无数字 | 如实展示 `+n`，与 `selectCost` 的 `−m` 并列 |
| 补天丹的道具描述 | 定性正文（「服之可补益寿元」），无数字 | 正文之外由 UI 追加一行精确值 |
| 结算面板的寿元行 | 定性一行 | 精确值 |

- **依据是一条反证：** 若一个 eventOption 明写「+10 寿元」，寿元的绝对量纲当场泄露，玩家由此可反推自己每一步花了多少、还剩多少步——而「Band 0 / Band 1 不显示 `selectCost`」这条纪律付出的全部代价（省着花的策略在常态档不可被精细执行）正是为了封住这件事。**只封成本侧不封产出侧等于留了一扇后门，而后门比正门更宽**（成本是逐事件的小数，回寿是一次性的大数，更容易被当作标尺）。
- **它是既有档位表的第六个消费方**，判据仍是「寿元 Band == 2」，与红字倒数、`selectCost` 精确展示**同一个开关、同时开启**。不新增字段、不新增流程。
- **道具描述的门控形态：** `ItemData` 的描述是 `LocalizedText` 静态文案，做不到按 Band 变体。故**正文恒为定性文案，精确值由 UI 在 Band 2 时追加一行**（数值取自 ability 定义，不写进文案）——与「快照里一个字符串正文都不存」「文案跟随模板」的既有分层一致，翻译侧也不必为两种 Band 各写一版。
- **代价明写：** 玩家在常态档无法比较「这颗丹值不值这个价」。**这正是取向本身**，与「eventOption 不标注经验产出数字」是同一条纪律的又一个实例。

### ④ 回寿源的准入：三条硬边界

**边界一 · 能力条目一概不得产出寿元。** `PowerData`（法则与神通，两个 `Scope` 皆然）不得含 `LifeSpan` 产出。**判据是次数**：`PowerData` 没有 `Charges` 字段——它一经持有即永久可用，一条能产寿元的能力条目就是一个**无次数上限的回寿水龙头**，把「`lifeSpanCost` 是控制篇章时长的主旋钮」直接架空。回寿只挂在**有明确次数上限的一次性消费**（法宝的 `Charges`）与**占事件位的事件产出**上。

**边界二 · 账号级道具不得产出寿元。** `ItemData.Scope == AbilityScope.Player`（古宝）不得含 `LifeSpan` 产出。依据是付费面五项排除的第一条**付费续命 / 复活**：付费礼包从 `(Item, Player)` 池抽 2 件古宝，池中一旦有回寿古宝，「花钱 → 抽到 → 续寿」就是付费续命的软形态——它甚至绕过了那条排除的字面表述（没有「撤销一次 `defeated`」，只是让 `defeated` 更晚到来），而 ADR-0004 那条压力线被按次稀释，效果相同。**边界一同时关掉了礼包 ① 那一半**（随机 1 条 PlayerPower）。

**边界三 · 战斗内不得产出寿元。** 含 `LifeSpan` 产出的 `ItemData` 其 `UsableScene` 不得含 `InCombat`。依据是既定的「`lifeTotal` 是战斗内耐久、寿元在战斗内不参与结算」——战斗内根本没有寿元结算通道，一件能在战斗内回寿的道具指向一条不存在的路径。

**连带（提醒而非新规则）：** 「付费的战斗价值由古宝承载」这条既定分工不受影响——它讲的是战斗内价值，而回寿是战斗外资源线。

### ⑤ 平衡护栏：不设硬上限，靠三道软闸 + 一条结构性禁令

回寿通道的真实风险是**时长旋钮被架空**：`lifeSpanCost` 定价表是按目标时长（30–40 / 35–45 / 45–55 分钟）反推的，一条不受控的回寿通道能把一轮回无限拉长。

**不设「每篇章回寿总量上限」一类的硬结构**——它需要一个新的存档字段（本章已回寿累计）与一处新校验，而下列软闸已把正反馈掐死：

1. **回寿事件照常付 `selectCost`**（它是一个普通 AdventureEvent）⇒ 净收益 = 回寿量 − 该事件定价，**恒小于回寿量**；
2. **回寿事件占 `eventCountLimit` 配额** ⇒ 它挤掉的是别的事件，不能凭空多做事情；
3. 补天丹占**储物袋 9 格中的一格**（按 `ItemId` 堆叠，多份仍占 1 格 ⇒ 它施压的是种类数这条取舍位，而这正是 9 格上限的设计意图）。

**结构性禁令（软闸 2 的必要边界）：`eventType == Travel` 的条目其 outcome 侧不得含 `LifeSpan` 产出。** Travel **不计入 `eventCountLimit`**——软闸 2 对它整条失效，只剩软闸 1，而 Travel 的定价是全表最低一档（常规基准的 1/3 ~ 1/2）。一条带回寿的 Travel 条目就是「来回横跳换寿元」，与「Travel 那一格必须 > 0」要堵的零成本 reroll 是同一个漏洞的两半。**Explore 遮罩的情形自动被覆盖**——被遮罩的真身本身就是一个 Travel 条目，模板侧校验照常命中。

**可调旋钮因此落在纯内容侧**：回寿事件 / 补天丹的 `RarityTier` 档与抽取权重、回寿量的表值。**改数值不改结构。**

### ⑥ 回寿量的标定口径 = 本章预算的百分比

**回寿量在 `systems/balance.md` 中以「占本章 `ChapterLifeSpanBudget` 的百分比」推导，落表时写成各篇章的绝对点数**（内容侧仍写正数量值，链路不变）。

绝对点数会在三章之间失真（ch1 预算 100、ch3 预算 300 + 结转，同一个「+10」在两章的意义差 3 倍以上）；百分比口径与寿元 Band 的阈值（30% / 10%）**同量纲**，让「一颗丹能把玩家拉回几档」成为可直接读出的设计量。

| 档 | 占本章预算 | 手感目标 |
|---|---|---|
| 小 | **5%** | 缓一口气，不改变所处档 |
| 中 | **10%** | Band 2 中位（≈5%）→ 15%，**越过 Band 1 的退出阈值 13%（10% + δ 3 个百分点）⇒ 恰好拉回一档** |
| 大 | **20%** | Band 1 → Band 0，一次显著的战略续航 |

- **中档由 Band 阈值反推而来，且经回滞校验成立**：10% 使「濒死时一颗补天丹换回一档」为真，而这正是「补天丹」这个题材词承诺给玩家的手感。
- **三档是量值口径，不是新枚举**——它与 `HiddenStatGrade { Minor, Standard, Major }` **不是同一个东西，也不得复用**：寿元走资源 element 路径（绝对量值），`HiddenStatGrade` 是道心 / 煞气推拉的档位映射，其映射值是为 `[0,100]` 取值域标定的，套不到跨章 100 / 200 / 300+ 的寿元预算上。（与 `Tier` / `RarityTier` 那条硬约定同性质。）
- 落表位置与 `lifeSpanCost` 定价表并列，同为「事件类型 × 篇章」形态的一张小表；绝对点数归 ch1 数值标杆专场。

### ⑦ `LifeSpan.GainModifier` 保持 `null`

- `Elements` 的 modifier 准入是 **opt-in 白名单、缺省豁免**——没有具体法则条目时不该先占位；
- 一条「延寿 +X%」的法则会**直接乘上时长旋钮**，且它是账号级永久持有的，须按「老账号全开」校准难度曲线。先不开这个口子，日后确需时**加一行即可，零结构改动**。它与边界一互补：边界一关掉「法则直接产寿元」，本条关掉「法则放大回寿」。

### ⑧ 剧本侧与呈现侧零改动

- **PlotModulation 已能调节回寿事件的出现**（`EventWeights` / `TypeWeights` 抬权重），零新增字段——剧情线因此可以在压力最大时把回寿机会摆到玩家面前，而这仍是「只调内容不调约束」。
- **寿元回升的叙事按既定规则静默**：回寿使 `|BandIndex|` 减小 = 靠近常态 ⇒ 不播文案，只更新 band 字段；回滞 δ = 3 个百分点自动挡住阈值上的抖动。

### ⑨ 明确不做的两件事

- **不抬高 `ChapterLifeSpanBudget`。** 回寿后剩余寿元可能超过冻结的分母（百分比 > 100%）——**这被接受**：分母是篇章边界的口径量，章内抬高会让 30% / 10% 阈值在章内漂移，而回滞机制假定阈值不动。>100% 仍落在 Band 0，无任何呈现问题。
- **不为寿元设 `Max` 上界。** `LifeSpan` 行的 `Max = 无` 与 `LifeTotal` 同款「只跟踪单值、无上限截断」；加上界会引出「补满时用丹浪费」这一整类挫败感，而 `lifeTotal` 那边正是专门删掉上限字段来消掉它的。

### 加载期与物化期校验（六条，全部 `PushError` + 条目 `Id`）

| # | 违规 | 时机 | 依据 |
|---|---|---|---|
| 1 | `lifeSpanCost` 的表值 / 条目覆盖值为负 | 内容模板加载期 | ② |
| 2 | 物化后 `SelectCost.Elements` 中 `Key == LifeSpan` 且 `BaseValue > 0` | 物化组装后断言 | ② |
| 3 | `PowerData`（任一 `Scope`）的 abilities 含 `LifeSpan` 产出 | 加载期 | ④ 边界一 |
| 4 | `ItemData.Scope == Player` 且 abilities 含 `LifeSpan` 产出 | 加载期 | ④ 边界二 |
| 5 | `ItemData` 含 `LifeSpan` 产出 且 `UsableScene` 含 `InCombat` | 加载期 | ④ 边界三 |
| 6 | `eventType == Travel` 的条目 outcome 侧含 `LifeSpan` 产出 | 加载期 | ⑤ |

### 落地面

| # | 落点 | 改动 |
|---|---|---|
| 1 | `adventure-event/common-properties.md` | 成本侧 `LifeSpan` 取值域收紧（改写「产出向覆盖值」半句）；回寿 outcome 侧条目与展示门控；两条校验 |
| 2 | `balance.md` | 同一处半句改写；回寿量三档表与标定口径；新增待定数值格 |
| 3 | `character-profile/item/_index.md` | 补天丹形态；两条 `ItemData` 校验；「战斗外获取途径与效果」待决项添上第一个具体条目 |
| 4 | `character-profile/power/_index.md` | `PowerData` 不得含寿元产出（次数判据） |
| 5 | `services/profile-service.md` | `LifeSpan` 行 `GainModifier` 理由改写；成本侧非负不变式进失败语义表 |
| 6 | `services/plot-manager.md` | 档位表消费方五 → 六；待答项去掉「是否有非境界突破的寿元增长途径」 |
| 7 | `services/life-cycle-service.md` | 同上一句的重复登记同改 |
| 8 | `monetization.md` | 付费续命那条排除补一句连带（回寿被结构性关死） |
| 9 | `adventure-event/travel/_index.md` | Travel 条目不得带回寿产出（结构性禁令） |
| 10 | `adventure-event/exchange/_index.md` | 补天丹 = `CharacterItem` 族的普通条目，走既有购买路径与定价表 |
| 11 | `ux/screen-flow.md` | 两段告警表补一列语义：Band 2 同时开启回寿数字 |

**存档 schema：零改动、不 bump、无迁移。** 全部复用 `ChangeElement` / `AppliedChange` / `LifeSpanAfter`。
**对后端库零影响：** 寿元与 `magicPack` 均落在 `characterProfile` 内，而 `backend-design-documents/contracts/profile-sync.md` 把 `characterDiffs` 整体划为不透明段；本次不新增任何 `Source` 成员、不触及唯一的透明路径 `/playerPowers[*]/sourceCode`。故不写对侧库、不产生跨边界承接项。

## Clarifications（评审裁决）

草稿以 `status: decided` 进入本次提炼，四项取向一律取推荐项：

1. **回寿是否收紧为「只走 outcome 侧」** → **收紧**（成本侧 `LifeSpan` 取值域非负 + 两条 `PushError`），三处现有文本据此改写。**这是草稿自陈的唯一硬冲突，代价如实落笔**：内容作者少一个书写位。
2. **回寿收益的数字是否与 `selectCost` 同门控** → **同门控**（Band 2 才给数字）。
3. **回寿量中档取值** → **10%**（濒死时一颗丹恰好拉回一档；本次补做了回滞校验，δ = 3 个百分点下该手感仍成立）。
4. **是否接受「不设每篇章回寿总量硬上限」** → **接受**（软闸已足，硬上限要新增一个存档字段）。

**本次自行推演并落笔的三项（依据既有承重纪律，非草稿原文）：**

- **`PowerData` 不得含寿元产出。** 草稿只关了 `(Item, Player)` 一半；但礼包同时给 1 条 PlayerPower，且 `PowerData` **没有 `Charges` 字段** ⇒ 一条能产寿元的能力条目是无次数上限的回寿源，比古宝更彻底地架空时长旋钮。
- **Travel 条目不得带回寿产出。** 用户裁决 ④「不设硬上限」的依据是两道软闸，而 Travel **不占 `eventCountLimit` 配额** ⇒ 软闸 2 对它整条失效。这是被接受的护栏的边界条件，不是新加的限制。
- **回寿量中档 10% 的回滞校验。** Band 1 的退出阈值 = 10% + δ 3 = 13% < 15%，故「Band 2 中位一颗丹拉回一档」在回滞下仍成立。

## Open questions

- **战斗外道具的使用入口未设计（承重 · 阻塞通道 B 定稿）。** `UsableScene = OutOfCombat` 的道具**在哪一屏、哪一步被使用**尚无设计（`item/_index.md` 只定义了战斗内的使用窗口）。**连带两问**：使用是否单独构成一个存档点（归「决策点粒度」）；以及**在事件之外使用时没有 `PastEventEntry` 可挂**，元进程的寿元曲线会出现一段无痕迹的回升——痕迹落点未定。→ `systems/character-profile/item/_index.md`、`systems/services/life-cycle-service.md`。
- **回寿量三档的绝对点数**（`5% / 10% / 20% × ch1 / ch2 / ch3`）与它同 `lifeSpanCost` 定价表的联合反推（回寿量折合「几个事件的时间」）**归 ch1 数值标杆专场**。形态与标定口径已定，不阻塞结构。→ `systems/balance.md`。
- **道具种类目录与「什么该做成卡 / 道具 / 神通」的判据未给。** 补天丹是该目录的第一个具体条目，但目录本身的组织方式未定。→ `systems/character-profile/item/_index.md`。

## Notes / triage

- 输入：`inbox/solution-draft-lifespan-gain-paths.md`（`status: decided`），已归档进 `inbox/archive/`。
- 本次答结并移出 1 条待答项，见 `answer-logs/log-lifespan-gain-paths.md`。
- 本次是同日第六场专场。前五场（Travel / Research / Explore / Exchange / Finale）已把 `EventOption` 骨架推到十一字段、`ProfileChangeSpec` 推到逐条按施加语义分列、并改写了事务纪律与 `AppliedChange` 语义；**本次不新增任何字段、不增 spec 列、不触碰那两条纪律**。草稿写作时登记的「Exchange 专场未开」这条前置依赖已随同日第四场消解，通道 C 因此有完整落点。
