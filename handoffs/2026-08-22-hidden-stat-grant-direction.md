# 隐藏属性推拉的方向位：`HiddenStatGrant` 加第三格

- id: 2026-08-22-hidden-stat-grant-direction
- date: 2026-08-22
- topic: systems/architecture.md · systems/adventure-event/common-properties.md · systems/services/future-event-service.md · systems/balance.md
- status: distilled
- distilled-to: `systems/architecture.md`、`systems/adventure-event/common-properties.md`、`systems/services/future-event-service.md`、`systems/balance.md`

## Intent（distilled）

**一句话：** 隐藏属性推拉的方向（涨 / 跌）落在 `HiddenStatGrant` 的第三格，取一个新的二值枚举 `HiddenStatDirection { Raise, Lower }`；符号在物化组装时取负，与 `SelectCost` / `OutcomeRule.Direction` 同处。

### 问题

模板侧的产出格 `HiddenStatGrant[] HiddenStatGrants` 原为两元组 `(HiddenStat Stat, HiddenStatGrade Grade)`，写不出方向：

- **道心是双臂属性**（档号 `−2 … +2`，轮回起始 50）——「静室枯坐」推高、「屠戮山门」压低，**同一属性同一档、方向相反**。
- **煞气虽以上行为主，但可被净化类事件下拉。**
- 而 `HiddenStatGrade` 的平衡表映射值是**正量**（`Minor 2 / Standard 5 / Major 10`）。

方向位未定之前，`HiddenStatGrants` 这一格写不出一半正常的内容编排。

**它不是什么：** 不是「隐藏属性能不能为负」（`Faith` / `Bloodlust` 的取值域恒为 `[0, 100]`），也不是「element 层如何表达增减」（`ChangeElement.BaseValue` 带符号早已定案）。悬着的只是**模板层的书写位**。

### 落点判据

方向是**单次变更的属性**——同一个 `Faith` key，这个条目推高、那个条目压低。按 `systems/architecture.md`「一个新的施加语义该落在哪里」的三级判据，配表只装「同一个 key 的**每一次**变更都取同一个值」的性质，故方向**落不进配表**，只能落在内容作者可逐条书写的那一格，即 `HiddenStatGrant` 本身。

### 形态

```csharp
public enum HiddenStatDirection { Raise, Lower }      // 沿数值轴：推高 / 压低。不含价值判断
public readonly record struct HiddenStatGrant(
    HiddenStat Stat, HiddenStatGrade Grade, HiddenStatDirection Direction);
```

四条依据：

- **与 `ChangeElement` 既有的有符号形态一致 = 零新概念。** 模板侧写「哪个属性 · 多大 · 哪个方向」，物化组装读平衡表取正量再按方向取负，展开成一条 `ChangeElement(key, ±v, Add)`。「取负发生在物化组装」是逐字复用的既有纪律（`SelectCost` 的 `lifeSpanCost` 取负、`OutcomeRule.Direction` 取负都在同一处）。element 层、`AppliedChange` 层、存档层**一格都不用动**。
- **档位表条目数不变。** 平衡表仍是 3 行，`HiddenStatGrade` 仍是 4 成员，`ExperienceGrade` ↔ `HiddenStatGrade`「形态同构而非同一张表」的关系不受扰动。
- **命名沿数值轴而非价值轴。** `Raise` / `Lower` 对三个属性一律无歧义：道心 `Raise` = 数值升，煞气 `Raise` = 数值升。**不引入「对玩家是好是坏」这一维**——煞气是累积物 / 负面，价值判断词（`Gain` / `Loss`）在它身上有两个自洽读法，`.tres` 里读不出作者想的是哪一种。
- **枚举二值且封闭。** 数值只有升降两向，没有第三种。

**代价明写（被接受）：** 内容作者每条 grant 多填一格。内容侧迁移面为**零**——`content/` 下当前尚无任何 AdventureEvent 条目。

### 物化展开

```
物化时（对 HiddenStatGrants 逐条）：
  v    = HiddenStatGradeTable[g.Grade]                       // 正量
  sign = g.Direction == Raise ? +1 : -1
  key  = g.Stat == Faith ? CostKey.Faith : CostKey.Bloodlust
  OnResolved.Elements += ChangeElement(key, sign * v, Add)
  OnFailure .Elements += ChangeElement(key, sign * v, Add)   // 胜负同施，不套 FailureRatio
```

两侧那两条恒相同，由**同一段组装代码**从**同一个** `HiddenStatGrants` 展开——「不加顶层第三格 `Always`」的理由原样成立，方向位不改变它。

### 钳制不新增

方向位不引入任何新的钳制点。逐步落位全部是既有形态：内容模板写 `(Faith, Standard, Lower)` → 物化组装展开为 `ChangeElement(Faith, −5, Add)`（**符号在此产生**）→ 落存档记 `−5` 未截断值 → `eventEnd` 的 `Evaluate(spec)` 走 `Op == Add` 分支，`Faith` / `Bloodlust` 两行的两个修正列恒 `null` ⇒ pipeline 不介入 → `Clamp(raw, 0, 100)` → band 更新读钳制后的字段。

三条推论：

- **截断不构成 `ApplyResult.Fail`**：道心 98 + `Raise Major(10)` 落 100、煞气 3 + `Lower Standard(5)` 落 0，都是正常结算。
- **方向位与 modifier 语义零耦合**——两个 key 的 `CostModifier` / `GainModifier` 均为 `null`（一条法则能伪造隐藏属性，即等于伪造整条剧本线的触发条件）。
- **方向位不能落 `HiddenStatBandData`**：档位判定读钳制后的当前值，触发规则已由「`BandIndex` = 离常态的距离」消掉方向维。

### 校验与断言

模板加载期（`PushError` + 条目 `Id`）：

| # | 校验 |
|---|---|
| 8 | `HiddenStatGrants` 内 `Grade == None` → 拒绝（一条什么都不做的 grant 是编排错误） |
| 9 | `HiddenStatGrants` 内 `Stat == HiddenStat.LifeSpan` → 拒绝 |

物化组装后（`PushError` + `EventId` + `InstanceId`）：

| # | 断言 |
|---|---|
| 11 | 两侧 `Elements` 中 `Key ∈ { Faith, Bloodlust }` 时 `BaseValue != 0`（校验 8 的物化侧对偶） |
| 12 | 两侧 `Elements` 中 `Key ∈ { Faith, Bloodlust }` 各至多一条（校验 7 的物化侧对偶） |

**既有校验 7 已把「方向互相抵消」封死**：`(Faith, Minor, Raise)` + `(Faith, Minor, Lower)` 会净成 0，而校验 7 本就拒绝同一 `HiddenStat` 出现两条 ⇒ 不需要为方向位新增任何去重校验。

`Stat` 保持宽类型 `HiddenStat`，由校验 9 收窄为 `{ Faith, Bloodlust }`，照 `OutcomeRule.PoolKind` 用宽的 `ExchangeGoodsKind` + 校验 4 收窄的既有先例处置——一条 `PushError` 比一个近同义枚举便宜；`HiddenStat` 正被 `HiddenStatBandData.Stat`、`PlotCondition.Kind == HiddenStatBand`、EventBus 的 `PlotThresholdReached` 三处使用，多一个近同义枚举会让「该用哪个」成为每次新增字段都要回答一遍的问题。

## Clarifications（interview 产物）

- **方向位落在哪一格？** → **`HiddenStatGrant` 加第三格 `HiddenStatDirection { Raise, Lower }`，数值轴命名，符号在物化组装取负。** 正式拍板。否决的三条：档位表分正负两套（把单次变更的属性焊进 element 类型的量纲轴，两套值注定冗余却可被填成不一致）· 复用 `OutcomeDirection { Gain, Loss }`（价值判断词按到语义双读的位置）· 逐属性固定方向（结构上表达不出双向推拉）。
- **是否给 `HiddenStatDirection` 加 `Unset = 0` 哨兵？** → **不加**（`[采纳推荐 — 待复核]`）。依据：`OutcomeRule.Direction` 同为二值方向枚举，全库无哨兵；本库对「为一个常态设一个必须显式置位的成员」判为反向的负担。**代价明写：** 忘填 `Direction` 会静默落成 `Raise`，而 `Raise` 对煞气（累积物、以上行为主）恰是常见方向，比一般字段更难在测试中显形。
- **是否采纳校验 9（`Stat == LifeSpan` → `PushError`）？** → **采纳**（`[采纳推荐 — 待复核]`）。它堵住的是一个真实可写出的口子：现行形状下作者写得出 `(LifeSpan, Major, Raise)`，而它撞三条既定纪律——`HiddenStatGrade` 的 `[0,100]` 标定套不到跨章 100 / 200 / 300+ 的寿元预算上；它给寿元开第二个书写位、绕过 `lifeSpanCost` 定价表与回寿量表；现行校验 6 只覆盖 `OutcomeRule` 两侧，看不见 `HiddenStatGrants`，故 Travel 不得回寿的结构性禁令在 grant 侧无落点。
- **`Stat` 的类型是否收窄为 `PushableHiddenStat { Faith, Bloodlust }`？** → **不收窄**（`[采纳推荐 — 待复核]`），用校验收窄，照 `OutcomeRule.PoolKind` 先例。

## Open questions

- **`HiddenStatDirection` 不加 `Unset = 0` 哨兵** —— `[采纳推荐 — 待复核]`。
- **校验 9（`HiddenStatGrants` 内 `Stat == LifeSpan` → `PushError`）** —— `[采纳推荐 — 待复核]`。
- **`HiddenStatGrant.Stat` 保持宽类型 `HiddenStat`，以校验收窄** —— `[采纳推荐 — 待复核]`。

（`HiddenStatGrade` 的三个映射值与「隐藏属性的增减触发」逐条目映射均**不阻塞**本决策：本次定的是结构与符号来源，不定量值。）
