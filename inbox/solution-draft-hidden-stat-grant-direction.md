---
type: solution-draft
date: 2026-08-22
question: `HiddenStatGrant` 的推拉方向（涨 / 跌）落在哪一格，取什么形态？
source: open-questions/02-event-options.md → 「`HiddenStatGrant` 的推拉方向如何表达（08-22 新增 · 轻）」
targets:
  - systems/architecture.md（「共享核心类型」：新增枚举 + `HiddenStatGrant` 由两格改三格）
  - systems/adventure-event/common-properties.md（模板侧五格的字段注释 + 加载期校验 8 / 9）
  - systems/services/future-event-service.md（物化展开伪码 + 组装后断言 11 / 12）
  - systems/balance.md（`HiddenStatGrade` 一节注明「映射值恒为正量、方向不在本表」）
status: distilled
distilled-to: handoffs/2026-08-22-hidden-stat-grant-direction.md
reviewed: 2026-08-22 —— 采纳候选一：`HiddenStatGrant` 加第三格 `HiddenStatDirection { Raise, Lower }`；不加 `Unset` 哨兵；采纳校验 9（`Stat == LifeSpan` 拒绝）；`Stat` 类型不收窄，照 `OutcomeRule.PoolKind` 先例以校验收窄。
---

# 方案草稿 — `HiddenStatGrant` 的推拉方向如何表达

## 问题

模板侧的产出格里有一格 `HiddenStatGrant[] HiddenStatGrants`，当前形状是两元组 `(HiddenStat Stat, HiddenStatGrade Grade)`（见 `systems/architecture.md`「共享核心类型」与 `systems/adventure-event/common-properties.md`「模板侧的产出格」）。

它写不出方向：

- **道心是双臂属性**（档号 `−2 … +2`，轮回起始 50，「心境澄明 ↔ 心魔渐生」），一个「静室枯坐」的条目要推高、一个「屠戮山门」的条目要压低，**同一属性同一档、方向相反**。
- **煞气虽以上行为主，但明写「可被净化类事件下拉」**（`systems/services/plot-manager.md`「取值域与档位表」）。
- 而 `HiddenStatGrade { None, Minor, Standard, Major }` 的平衡表映射值是**正量**（`Minor 2 / Standard 5 / Major 10`，见 `systems/balance.md`「隐藏属性推拉的量纲」）。

于是「方向位落在哪里」悬着：`HiddenStatGrant` 自带一格？档位表分正负两套？复用既有的 `OutcomeDirection { Gain, Loss }`？在它定下来之前，`HiddenStatGrants` 这一格是**写不出一半正常内容编排**的半成品。

**边界澄清（它不是什么）：** 这**不是**「隐藏属性能不能为负」的问题——`Faith` / `Bloodlust` 在 `ResourceElements` 表里的取值域都是 `[0, 100]`，永不为负；也**不是**「element 层如何表达增减」的问题——那一层早已定案（`ChangeElement.BaseValue` 带符号，负 = 消耗、正 = 产出）。悬着的**只是模板层的书写位**：内容作者在 `.tres` 里写什么，物化组装才能算出那个符号。

## 约束（来自既有设计）

| # | 约束 | 来源 |
|---|---|---|
| 1 | `ChangeElement.BaseValue` **带符号**（负 = 消耗，正 = 产出），`Op == Add` 时有向 | `systems/architecture.md`「共享核心类型」 |
| 2 | `Faith` / `Bloodlust` 两行：`Min 0` · `Max 100` · `DepletionDefeat` 无 · **两个修正列恒 `null`** · `AllowedOps = Add` | `systems/services/profile-service.md`「`ResourceElements` 表」 |
| 3 | **钳制发生在 `Evaluate(spec)` 施加到 Profile 字段那一刻**：`raw = 当前值 + eff; 落值 = Clamp(raw, Min, Max)`；spec 与快照记**未截断值** | 同上「施加顺序」 |
| 4 | **内容侧不落裸数字**：走「枚举档 + 平衡表映射」；`Faith` / `Bloodlust` 不在 `FixedResource` 的可写 key 内 | `systems/adventure-event/common-properties.md`「模板侧的产出格」 |
| 5 | **取负发生在物化组装，与 `SelectCost` 同处** | `OutcomeRule.Direction` 的既有注释（同上） |
| 6 | 隐藏属性推拉**在 `OnResolved` / `OnFailure` 两侧各展开一份相同 element**，胜负同施、**不套 `FailureRatio`** | `systems/services/future-event-service.md` |
| 7 | 模板加载期校验 7：`HiddenStatGrants` 内**同一 `HiddenStat` 出现两条 → 拒绝** | `systems/adventure-event/common-properties.md` |
| 8 | **修正与否是 element 类型的属性，不是单次变更的属性**（故它配在表里，不让 `ChangeElement` 逐次带） | `systems/services/profile-service.md` |
| 9 | 三级判据：新语义**落配表**的条件是「同一个 key 的**每一次**变更都取同一个值」 | `systems/architecture.md`「一个新的施加语义该落在哪里」 |
| 10 | `HiddenStatGrade` 的映射值**不得**套到寿元上（寿元走资源 element 路径、跨章 100 / 200 / 300+ 的绝对预算） | `systems/balance.md`「回寿量」的 ⚠ 一条 |
| 11 | 档位判定（band 更新 / 回滞 / 跨档文案）读的是**钳制后的 Profile 字段**，触发规则是 `\|newBand\| > \|oldBand\|`，**不需要方向字段** | `systems/services/plot-manager.md` |

**约束 8 + 9 合起来先把一半答案定死：方向是「单次变更的属性」**——同一个 `Faith` key，这个条目推高、那个条目压低。按三级判据，它**落不进配表**（配表只装「每一次变更都取同一个值」的性质），只能落在**内容作者可逐条书写的那一格**上，即 `HiddenStatGrant` 本身。

## 建议方案

### 一、方向落 `HiddenStatGrant` 的第三格，取一个新的二值枚举 `HiddenStatDirection { Raise, Lower }`

`[既有推演]`

```csharp
// systems/architecture.md「共享核心类型」
public enum HiddenStatDirection { Raise, Lower }      // 沿数值轴：推高 / 压低。不含价值判断
public readonly record struct HiddenStatGrant(
    HiddenStat          Stat,
    HiddenStatGrade     Grade,
    HiddenStatDirection Direction);                   // 取负发生在物化组装，与 SelectCost 同处
                                                      // 胜负同施一份，不套用 FailureRatio
```

四条依据：

- **与 `ChangeElement` 既有的有符号形态一致 = 零新概念（承重）。** 模板侧写「哪个属性 · 多大 · 哪个方向」，物化组装读平衡表取正量再按方向取负，展开成一条 `ChangeElement(key, ±v, Add)`。**「取负发生在物化组装」是逐字复用的既有纪律**（`SelectCost` 的 `lifeSpanCost` 取负、`OutcomeRule.Direction` 取负都在同一处），不是新增一条规则。element 层、`AppliedChange` 层、存档层**一格都不用动**。
- **档位表条目数不变。** 平衡表仍是 3 行（`Minor 2 / Standard 5 / Major 10`），`HiddenStatGrade` 仍是 4 成员，`ExperienceGrade` ↔ `HiddenStatGrade`「形态同构而非同一张表」的既定关系不受扰动。
- **命名沿数值轴而非价值轴。** `Raise` / `Lower` 对三个属性一律无歧义：道心 `Raise` = 数值升，煞气 `Raise` = 数值升。**不引入「对玩家是好是坏」这一维**——那正是候选三翻车的地方（见下方「备选方案」）。
- **枚举二值且封闭、不会再长。** 数值只有升降两向，没有第三种；这是三个候选里唯一**只增加一个不会再增长的结构**的方案。

**代价明写（被接受）：** `systems/architecture.md`「共享核心类型」多一行枚举；内容作者每条 grant 多填一格。内容侧的迁移面为**零**——`content/` 下当前尚无任何 AdventureEvent 条目（只有两份模板与 `_index.md`）。

### 二、物化展开的形态（写进 `future-event-service.md`，与经验的失败折算并列）

`[既有推演]`

```
物化时（对 HiddenStatGrants 逐条）：
  v    = HiddenStatGradeTable[g.Grade]                       // 正量；见 systems/balance.md
  sign = g.Direction == Raise ? +1 : -1
  key  = g.Stat == Faith ? CostKey.Faith : CostKey.Bloodlust
  OnResolved.Elements += ChangeElement(key, sign * v, Add)
  OnFailure .Elements += ChangeElement(key, sign * v, Add)   // 胜负同施，不套 FailureRatio
```

- **两侧那两条恒相同**，由**同一段组装代码**从**同一个** `HiddenStatGrants` 展开——既定「不加顶层第三格 `Always`」的理由原样成立，方向位不改变它。
- **`Grade == None` 的条目不产出 element，而是直接被加载期拒绝**（见校验 8）：与 `ExperienceGrade == None` 不同——那是一个**字段默认值**（缺省即不产出），而这是**数组里的一条**，写了一条什么都不做的行是编排错误，不是缺省。

### 三、`[0, 100]` 钳制在哪一步发生：不新增任何钳制点

`[既有推演]`

**方向位不引入新的钳制语义。** 逐步落位（全部是既有形态）：

| 步骤 | 发生什么 | 是否受方向位影响 |
|---|---|---|
| 内容模板 | 作者写 `(Faith, Standard, Lower)` | — |
| 物化组装 | 展开为 `ChangeElement(Faith, −5, Add)`，落进两侧 `OutcomeSpec.Elements` | **符号在此产生** |
| 落存档（定稿实例 / `PastEventEntry.AppliedChange`） | 记 `−5`，**未截断值** | 否 |
| `eventEnd` 的 `TryApply` → `Evaluate(spec)` | `Op == Add` 分支：`eff = BaseValue`（`Faith` 行两个修正列恒 `null` ⇒ pipeline 不介入）→ `raw = 当前值 + eff` → `落值 = Clamp(raw, 0, 100)` | 否 |
| band 更新 / 回滞 / 跨档文案 | 读**钳制后**的 Profile 字段，按 `\|newBand\| > \|oldBand\|` 判是否播 | 否 |

三条推论值得写进文档，否则实现时会各自发明一遍：

- **截断不构成 `ApplyResult.Fail`**（既定）：道心 98 + `Raise Major(10)` 落 100、煞气 3 + `Lower Standard(5)` 落 0，都是正常结算，不是失败。
- **`BaseValue` 的符号与 modifier 分向在这两个 key 上是空操作**——`Faith` / `Bloodlust` 两行的 `CostModifier` / `GainModifier` 均为 `null`（依据明写：「一条法则能伪造隐藏属性，即等于伪造整条剧本线的触发条件」）。故**方向位与 modifier 语义零耦合**，不必回答「压低道心算不算一次 `CostModifier`」这个问题。
- **方向位不能落 `HiddenStatBandData`。** 档位判定读的是钳制后的当前值、且触发规则已由「`BandIndex` = 离常态的距离」消掉了方向维（既定：「不需要方向字段，也不需要为寿元开特例」）。往档位表里塞方向会与那条承重定义正面冲突。

### 四、两条加载期校验 + 两条物化后断言

`[既有推演]`（第 9 条另见「仍需用户决定」第 3 项）

**内容模板加载期校验**（接在 `common-properties.md` 现有 7 条之后，一律 `PushError` + 条目 `Id`）：

| # | 校验 | 理由 |
|---|---|---|
| 8 | `HiddenStatGrants` 内 `Grade == None` → 拒绝 | 一条什么都不做的 grant 是编排错误；「不产生无消费方的空条目」 |
| 9 | `HiddenStatGrants` 内 `Stat == HiddenStat.LifeSpan` → 拒绝 | 见下 |

**校验 9 的理由（本草稿顺带补上的一格）。** `HiddenStat` 是三成员枚举 `{ Faith, Bloodlust, LifeSpan }`，故当前形状下作者写得出 `(LifeSpan, Major, Raise)`。它会当场撞三条既定纪律：① `systems/balance.md` 明写 `HiddenStatGrade` 的 `[0,100]` 标定**套不到**跨章 100 / 200 / 300+ 的寿元预算上；② 它给寿元开出**第二个书写位**，绕过 `lifeSpanCost` 定价表与回寿量表这两张时长旋钮；③ 它绕过 `eventType == Travel` 不得回寿这条结构性禁令的模板侧落点（校验 6 只看 `OutcomeRule`，看不见 `HiddenStatGrants`）。

**顺带的好消息：既有校验 7 已经把「方向互相抵消」这个坏形态封死了。** 加上方向位后，`(Faith, Minor, Raise)` + `(Faith, Minor, Lower)` 会净成 0；而校验 7 本就拒绝同一 `HiddenStat` 出现两条 ⇒ **不需要为方向位新增任何去重校验**。

**物化组装后断言**（接在 `future-event-service.md` 现有 10 条之后，`PushError` + `EventId` + `InstanceId`）：

| # | 断言 | 理由 |
|---|---|---|
| 11 | 两侧 `Elements` 中 `Key ∈ { Faith, Bloodlust }` 时 `BaseValue != 0` | 校验 8 的物化侧对偶；`Op == Add` 已由既有断言 8 覆盖 |
| 12 | 两侧 `Elements` 中 `Key ∈ { Faith, Bloodlust }` 各至多一条 | 校验 7 的物化侧对偶，与断言 4 / 5 「成本侧那条的镜像」同款分工 |

## 具体形态（可 derive 的落地面）

**字段表** —— `HiddenStatGrant`（`readonly record struct`，落 `AdventureEventData.HiddenStatGrants` 数组）：

| 字段 | 类型 | 取值域 | 默认 | 校验 |
|---|---|---|---|---|
| `Stat` | `HiddenStat` | **`{ Faith, Bloodlust }`**（`LifeSpan` 拒绝） | 无 | 模板校验 9 · 断言 12 |
| `Grade` | `HiddenStatGrade` | **`{ Minor, Standard, Major }`**（`None` 拒绝） | 无 | 模板校验 8 · 断言 11 |
| `Direction` | `HiddenStatDirection` | `{ Raise, Lower }` | `Raise`（枚举 0 值；沿用 `OutcomeRule.Direction` 的既有形态） | 无（**已裁决不设 `Unset` 哨兵**，2026-08-22） |

**新增枚举**（`systems/architecture.md`「共享核心类型」）：

```csharp
public enum HiddenStatDirection { Raise, Lower }   // 数值轴；与 OutcomeDirection 分立，理由见下
```

**改动的既有类型**（同处，两格 → 三格）：

```csharp
public readonly record struct HiddenStatGrant(
    HiddenStat Stat, HiddenStatGrade Grade, HiddenStatDirection Direction);
```

**平衡表侧的一句话**（`systems/balance.md`「隐藏属性推拉的量纲 `HiddenStatGrade`」）：

> 三个映射值**恒为正量**；**推拉方向不在本表**，由 `HiddenStatGrant.Direction` 逐条承载。理由：方向是**单次变更的属性**（同一属性这个条目推高、那个条目压低），按三级判据落不进配表；且分正负两套映射值会造出一张注定冗余、却可被填成不一致的表。

## 后果

- **文档面：** 四份文档各改一处（见 front matter 的 `targets`）。
- **存档 schema：零增量、不 bump、无迁移。** 方向位**只活在模板侧**——物化后它已化为 `BaseValue` 的符号，而 `ChangeElement` / `EventOutcomeSpec` / `PastEventEntry.AppliedChange` 一格未动。（诚实记：这一点三个候选**等价**，不构成候选一的优势。）
- **内容面：迁移面为零。** `content/` 下当前无任何 AdventureEvent 条目。
- **代码面：** 一个新枚举、`HiddenStatGrant` 多一格、物化组装多一次符号取反、两条加载期校验 + 两条断言。无新服务、无新调用方、不改任何方法签名。
- **不受影响的既有结论（逐条核过，均无扰动）：** 档位表 12 档与回滞 δ · 跨档叙事「只挂极值档」与 `\|BandIndex\|` 触发规则 · `PlotModulation` 六字段与合并算子 · `Faith` / `Bloodlust` 两行的 `ResourceElements` 配置 · 「隐藏属性不进成本侧」· 「两侧各展开一份、不加 `Always`」。

## 备选方案（已考虑并否决）

### 备选一 · 档位表分正负两套（`HiddenStatGrade` 扩为 `{ None, MinorUp, MinorDown, StandardUp, StandardDown, MajorUp, MajorDown }`，平衡表 3 行 → 6 行）

否决。四条理由：

1. **它把「单次变更的属性」焊进了 element 类型的量纲轴**——正面违反三级判据的落点条件（配表只装「每一次变更都取同一个值」的性质）。
2. **两套值必然长期相等，却可以被填成不一致。** 没有任何设计理由让「涨 5」与「跌 5」取不同数字；于是这张表**注定冗余**，同时留出一个**能上线且线上不可见**的漂移口（作者把 `MajorDown` 填成 12 而 `MajorUp` 是 10，无人发现）。要堵它就得再加一条「两套映射值必须相等」的校验——一条既尴尬又自证冗余的检查。
3. **组合爆炸的形状本库已经点名否决过。** 跨档文案那条论证里，「事件数 × 属性数 × 档数 × **方向**」被逐字列为不可维护的乘积形态，其中方向明确是**独立的一轴**。把它乘进档位轴与该判断直接相抵；且日后若加一个 `Trivial` 档，成员数是 `档数 × 2` 地长。
4. **断裂 `ExperienceGrade` ↔ `HiddenStatGrade` 的形态同构关系**（既定：「两者是形态同构而非同一张表」）。

### 备选二 · 复用既有 `OutcomeDirection { Gain, Loss }` 作为第三格

否决。**这是三个候选里最省字面、也最危险的一个。**

- **`Gain` / `Loss` 是价值判断词（得到 / 失去），不是数值轴词（升 / 降）。** 它在既有唯一用法（`OutcomeRule.Direction`，`Kind == FixedResource`）里绑在 `LifeSpan` / `LifeTotal` / `ManaLimit` / `Jade` 四个 key 上——那里资源恒是「玩家想要的东西」，**得到 = 数值升，两轴重合**，无歧义。
- **移到隐藏属性上两轴当场分离。** 煞气是**累积物 / 负面**：`(Bloodlust, Major, Gain)` 有两个自洽读法——「煞气 +10」（数值升、玩家变糟）还是「玩家获益 ⇒ 煞气 −10」？**`.tres` 里读不出作者想的是哪一种**，这与本库对「加性 vs 乘性两个相邻字段语义相反是纯粹的漂移源」的判定**是同一形状的错误**。道心作为双臂属性本身没有「有利方向」，同样只能靠一条口头约定消歧——而一旦要写「本处 `Gain` 一律读作数值升」这条约定，**枚举名就已经在骗人了**；正确的做法是改名，改名即回到候选一。
- **过载的第二笔代价：枚举的含义不再是常量。** 目前「见到 `OutcomeDirection` ⇒ 它作用在一个 `FixedResource` 资源量上」是一条恒真句；让它兼职后，「这个枚举出现在哪里 ⇒ 它意味着什么」要靠读上下文。且日后 `OutcomeRule` 侧若需第三个成员，隐藏属性侧当场被迫回答「它对档位映射是什么意思」——一个本不该存在的分叉。
- **省下的只有一行枚举声明。** 与上面三笔代价不成比例。

### 备选三 · 逐属性固定方向的约定（「道心默认涨、煞气默认涨，要反向就……」）

**结构上写不出来，直接否决。** 既定「道心可正可负、双向推拉」使任何逐属性固定方向都表达不了「静室枯坐推高道心 / 屠戮山门压低道心」这对**最基本**的编排；煞气侧同样明写「可被净化类事件下拉」。它连问题的最小需求都不满足。

### 备选四 · 让 `HiddenStatGrant` 直接带一个有符号 `int`

否决。正面违反「**内容侧不落裸数字**、走枚举档 + 平衡表映射」这条既定范式——那条范式的全部目的正是让平衡值集中在一张表里可全局重调；表达式 / 裸数字「比裸数字更远」的论证已在 `lifeSpanCost` 处写过一遍。

### 备选五 · 为 `HiddenStatGrant.Stat` 新开一个二值枚举 `PushableHiddenStat { Faith, Bloodlust }`

否决，但**它是一个真实的张力**，见下节。

## 与既有决策的张力

**一处轻张力（建议接受，不改既有决策）：`HiddenStatGrant.Stat` 用了一个比它实际允许的取值域更宽的类型。**

→ 已裁决（2026-08-22 · 批量评审）：**不松动** —— `Stat` 保持宽类型 `HiddenStat`，由加载期校验 9 收窄为 `{ Faith, Bloodlust }`，照 `OutcomeRule.PoolKind` + 校验 4 的既有先例处置；不新开 `PushableHiddenStat`。 [采纳推荐 — 待复核]

`HiddenStat` 是三成员枚举 `{ Faith, Bloodlust, LifeSpan }`，而本方案的校验 9 把 grant 侧收窄为两成员。这是本库明确不喜欢的形态（「准入留在表里」「正向白名单」那类纪律偏好类型层面的收窄）。

- **松动它的代价：** 新开 `PushableHiddenStat { Faith, Bloodlust }` = 一个与 `HiddenStat` 近同义的第二枚举，两者要在物化组装处互相映射；且 `HiddenStat` 正被 `HiddenStatBandData.Stat`、`PlotCondition.Kind == HiddenStatBand`、EventBus 的 `PlotThresholdReached` 负载三处使用，多一个近同义枚举会让「该用哪个」成为每次新增字段都要回答一遍的问题。
- **不松动的代价：** 一条加载期校验（校验 9）。
- **建议：不松动**——一条 `PushError` 比一个近同义枚举便宜得多，且本库已有同款先例（`OutcomeRule.PoolKind` 用宽的 `ExchangeGoodsKind` + 校验 4 收窄为能力族两值）。**这条先例几乎逐字对应**，故本方案取同款处置。

其余：与 `decisions/ADR-*` 无冲突（ADR 面不涉隐藏属性推拉的书写形态）。

## 前置依赖

**无阻塞项。** 两条相邻的待答项经核对**均不阻塞**本方案，如实记于此以免日后被误挂：

- **`HiddenStatGrade` 的三个映射值**（`Minor 2 / Standard 5 / Major 10`，归 ch1 数值标杆专场）——本方案定的是**结构与符号来源**，不定量值；映射值怎么调都不改变「方向由 `Direction` 取负」这条形态。`systems/balance.md` 已明写「档位结构、阈值形态、文案形态均不被它阻塞：它约束的是标定，不是结构」。
- **「隐藏属性的增减触发」逐条目映射**（哪条内容推哪个属性、推哪一档）——那是**内容编排口径**；本方案恰恰是它的前置（在方向位定下来之前，一半的编排根本写不出来）。

## 仍需用户决定 → **已全部裁决（2026-08-22 · 批量评审）**

> - **①** 三候选 → **A · `HiddenStatGrant` 加第三格 `HiddenStatDirection { Raise, Lower }`**（数值轴命名；符号在物化组装取负，与 `SelectCost` / `OutcomeRule.Direction` 同处）。正式拍板。
> - **②** `Unset = 0` 哨兵 → **不加**（按推荐；已知代价：忘填静默变 `Raise`，对煞气恰是常见方向）。 [采纳推荐 — 待复核]
> - **③** 校验 9（`Stat == HiddenStat.LifeSpan` → `PushError`）→ **采纳**（按推荐）。 [采纳推荐 — 待复核]
> - **张力**（`Stat` 类型比取值域宽）→ **不松动**，用校验收窄，照 `OutcomeRule.PoolKind` 先例。 [采纳推荐 — 待复核]

- **① 三候选的最终裁决 —— 推荐候选一（`HiddenStatGrant` 第三格 + 新枚举 `HiddenStatDirection { Raise, Lower }`）。**
  - 候选二（档位表分正负两套）：档位表 3 行 → 6 行、枚举 4 → 7 成员，两套值注定冗余且可被填成不一致，且违反三级判据的落点条件。
  - 候选三（复用 `OutcomeDirection`）：省一行声明，代价是把价值判断词按到一个语义上双读的位置（煞气 `Gain` 歧义），并让该枚举的含义不再是常量。
  - **理由集中在一句：** 方向是**单次变更的属性**，只能落在条目可逐条书写的那一格；落上去之后，符号的产生位置（物化组装取负）与 `SelectCost` / `OutcomeRule.Direction` **逐字相同**，是三者中唯一零新概念的形态。

  → 已裁决（2026-08-22 · 批量评审）：**A · 采纳候选一** —— `HiddenStatGrant` 加第三格 `HiddenStatDirection { Raise, Lower }`（数值轴命名），符号在物化组装取负。

- **② 是否给 `HiddenStatDirection` 加一个 `Unset = 0` 哨兵成员 —— 推荐不加。**
  - **背景：** C# / Godot `[Export]` 枚举的默认值是 0 号成员，故作者忘填 `Direction` 时会静默落成 `Raise`。加 `Unset = 0` + 一条加载期 `PushError` 可以把「忘填」变成大声失败。
  - **推荐不加，两条理由：** ① **既有先例已经接受这个形态**——`OutcomeRule.Direction`（同为二值方向枚举）全库没有为它设哨兵；② 本库对「为一个常态设一个必须显式置位的成员」明确判为**反向的负担**（跨档文案「静默是默认，不用字段声明」那条）。
  - **不加的代价明写：** 一个忘填的条目会静默变成「推高」，而它对煞气（累积物、以上行为主）恰好是常见方向、更难被察觉。**若用户认为隐藏属性的方向错误比一般字段更难在测试中显形**（它不可见、只经调制显影），加哨兵是合理的——这正是本项需要点头的地方。

  → 已裁决（2026-08-22 · 批量评审）：**不加 `Unset` 哨兵**，`HiddenStatDirection` 保持二值 `{ Raise, Lower }`，默认落 `Raise`（枚举 0 值），依据 `OutcomeRule.Direction` 全库无哨兵的先例；「忘填静默变 `Raise`」这一代价用户已知会并接受。 [采纳推荐 — 待复核]

- **③ 校验 9（`HiddenStatGrants` 内 `Stat == LifeSpan` → `PushError`）—— 推荐采纳，但它收窄了一个既有字段的取值域，请复核。**
  - 它是本草稿**顺带补上**的一格：现行两元组形状下作者已经写得出 `(LifeSpan, …)`，而三条既定纪律都不允许它（`HiddenStatGrade` 的标定套不到寿元预算上 · 会给寿元开第二个书写位、绕过定价表与回寿量表 · 会绕开 Travel 回寿禁令的模板侧落点）。
  - **若用户认为这已是逻辑必然、不必单独点头**，它就直接随本方案落笔；**若用户另有打算**（例如日后确实想让事件用档位口径推寿元），则本条须先答，且会牵动 `systems/balance.md` 的 ⚠ 一条。

  → 已裁决（2026-08-22 · 批量评审）：**采纳校验 9** —— `HiddenStatGrants` 内 `Stat == HiddenStat.LifeSpan` → `PushError`（带条目 `Id`），堵住绕过寿元定价表与 Travel 回寿禁令的书写出口。 [采纳推荐 — 待复核]
