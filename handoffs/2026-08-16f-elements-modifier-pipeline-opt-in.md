# `Elements` 与 modifier pipeline：缺省豁免 + 逐行 opt-in

- id: 2026-08-16f-elements-modifier-pipeline-opt-in
- date: 2026-08-16
- topic: systems/services/profile-service.md · systems/architecture.md · systems/monetization.md · systems/player-profile/player-power/common-properties.md
- status: distilled
- distilled-to: `systems/architecture.md` · `systems/services/profile-service.md` · `systems/monetization.md` · `systems/player-profile/player-power/common-properties.md` · `systems/services/life-cycle-service.md` · `systems/adventure-event/common-properties.md` · `systems/character-profile/currency.md` · `systems/character-profile/life-total.md` · `systems/character-profile/mana.md` · `systems/services/plot-manager.md`

## Intent（distilled）

**一句话：** `ProfileChangeSpec.Elements` **缺省不经 modifier pipeline**；只有在 `ResourceElements` 表中显式登记了 `ModifierKey` 的那一行才经。`AbilityElements` / `Stats` 永不经。

### 问题：一条被两处例外证伪的全称句

`profile-service.md` 原写着一条全称句——「ProfileManager 读取每个 element 数值的那一刻走 `Apply(key, baseValue)`」。但已有两处明确豁免，且都是逐案裁的：统计层（一条法则能改写统计数字）、`BundleGrantOrdinal`（一条法则能改写付费凭证）。

通则未收口的代价不是「有一条没定」，而是**每新增一个 element 都要重新裁一遍同一个问题**，而漏裁的默认值是「经 pipeline」——即默认把新 element 暴露给法则改写。这个洞随每条新 element 复现。

### 收口形态：逐 element 的一列，不是语义分类的通则

不采用「序号 / 幂等键 / 权益类一律不经 pipeline」这种**语义分类**通则，改为在既有的钳制表上**加两列**，形成 **opt-in 白名单**。三条依据：

1. **与钳制同构，零新机制。** 钳制已定为「逐 element 的一张封闭表，不是一条全局通则」，理由是「没有任何通则能给出这些区间」。**「这个 element 能不能被法则改写」与「它的取值域是多少」是同一类逐条属性**——由该 element 自己的语义决定（`LifeSpan` 是可被法则修正的成本量，`BundleGrantOrdinal` 是付费凭证的序号），不由任何分类推出。表已存在，加一列成本为零；「新增一行须与 `CostKey` 同批评审」这条纪律自动覆盖新列。
2. **分类通则解决不了它自己要解决的问题。** 它要求给每个新 element **判类**——那正是「每次单独裁一遍」本身，只是把裁决从「经不经 pipeline」换成「算不算权益类」。而边界确实模糊：`PowerFragmentAccumulated` 是进度量还是权益量？分类给不出答案，表给得出（表里就那一格）。
3. **缺省方向必须 fail-safe。** 漏填这一列时：缺省**豁免** → 最坏是某条法则本该修正它却没修正，数值不对、可见可复现、改一行修好；缺省**经 pipeline** → 最坏是某条法则**静默地**改写了幂等键 / 付费凭证 / 元进程计数，无人察觉，且在「云端权威 + 后端复算」下表现为客户端与后端算不一致。两侧代价不对称，缺省取豁免侧。

### 承载：加两列并按符号分向，表随之更名

只加一列 `ModifierKey?` 不够——**同一个资源 element 的「消耗向」与「产出向」共用一个 `CostKey`**（`ChangeElement.BaseValue` 带符号）。一条「寿元消耗 −20%」的法则若不分向，会把**寿元回复也削 20%**。既有术语本就是分向的（`lifeSpanCost` 是成本向的名字，不是 `LifeSpan` 字段的名字）。

```csharp
internal readonly record struct ElementSpec(
    int  Min,
    int? Max,
    DefeatReason? DepletionDefeat,
    ModifierKey?  CostModifier,     // 作用于 BaseValue < 0；null = 不经 pipeline
    ModifierKey?  GainModifier);    // 作用于 BaseValue > 0；null = 不经 pipeline

internal static readonly IReadOnlyDictionary<CostKey, ElementSpec> ResourceElements = ...
```

施加顺序：

```
key = BaseValue < 0 ? spec.CostModifier : (BaseValue > 0 ? spec.GainModifier : null)
eff = key == null ? BaseValue : ApplyModifier(key.Value, BaseValue)
raw = 当前值 + eff
落值 = Clamp(raw, Min, Max)
```

- `BaseValue == 0` 不经 pipeline——无向可分，且它是空操作（组装侧不应产出 0 值 element）。
- `CanAfford` 与 `TryApply` 共用的 `Evaluate(spec)` 读同一张表 ⇒ 「两者必须走同一条 pipeline」自动保持。
- **更名 `ClampSpec` → `ElementSpec`、`ResourceClamps` → `ResourceElements`：** 表现在承载「取值域 + 终态 + 修正」三件事，旧名窄到会误导（读者会以为修正配在别处）。当前无代码落地 ⇒ 零迁移。

### 首批表内容

| `CostKey` | Min | Max | 归 Min 时 | `CostModifier` | `GainModifier` |
|---|---|---|---|---|---|
| `LifeSpan` | 0 | 无 | 终态 `LifeSpanExhausted` | `LifeSpanCost` | `null` |
| `Jade` | 0 | 无 | 无 | `null` | `null` |
| `LifeTotal` | 0 | 无 | 终态 `LifeTotalExhausted` | `null` | `null` |
| `PowerFragmentAccumulated` | 0 | 10000 | 无 | `null` | `null` |
| `PowerFragmentWinOrdinal` | 0 | 无 | 无 | `null` | `null` |
| `PowerFragmentFirstWin(chapter)` | 形态未定 | — | 无 | `null` | `null` |
| `BundleGrantOrdinal` | 0 | 无 | 无 | `null` | `null` |

逐行理由：`LifeSpan` 的成本向是既有文档点名的第一个 modifier 用例，产出向（寿元回复）无既定修正意图 ⇒ 按缺省豁免。`Jade` 两格留空的依据是下面「一个 `ModifierKey` 只施加一次」。`PowerFragmentAccumulated` 直接决定「这次 Finale 是否授予一条法则」，让法则修正它 = **法则加速获得法则**的自举回路。`PowerFragmentWinOrdinal` 与 `BundleGrantOrdinal` 是序号，被修正即掷骰序列漂移、幂等键失效。`PowerFragmentFirstWin` 是置位、无量纲，修正无意义。

后四行随各自的 `CostKey` 成员登记时同步生效——本次只裁它们那一格，不裁清单本身。

### `ModifierKey` 登记与「只施加一次」

`ModifierKey` 至今只活在方法签名 `int ApplyModifier(ModifierKey key, int baseValue)` 里、成员未定，本次给它一个落地起点：`public enum ModifierKey { LifeSpanCost, … }`，并登记进共享核心类型清单。

- **表里出现的 key 必须是 `ModifierKey` 的成员，反向不要求。** `ApplyModifier` 仍是通用查询——非 element 路径的数值（商店价格、掉落权重、战斗内数值）照常各自调用它。本次**只约束 element 施加路径**，不收窄 `ApplyModifier` 的用途。
- **一个 `ModifierKey` 只能有一个施加点（承重）。** 判据：**该修正后的值是否需要在施加之前呈现给玩家**。需要 → 施加点在物化 / 展示侧（商店价格必须先算才能标价），此时它**不得**再进本表，否则打两次折；不需要 → 施加点在 `TryApply`（`lifeSpanCost` 属此类：既定「`selectCost` 物化时 pipeline 尚未施加，在 `TryApply` 那一刻才生效」）。

### 校验与失败语义

- **启动期断言 `ResourceElements` 覆盖 `CostKey` 的全部成员**——漏行即缺省行为不明，必须在启动期 `PushError`，而不是在轮回中途撞上。
- `ChangeElement.Key` 在表中无对应行 → 必需缺失（代码缺陷）→ `PushError` + 整批拒绝。
- 表内登记的 `ModifierKey` 无任何法则注册修正 → 正常，`ApplyModifier` 原值返回。

### 不受影响的面

- **存档 schema 无影响**——表是代码常量，不落存档、不落 `.tres`。
- **后端无影响、无需对侧承接**——pipeline 是客户端内部的施加语义，报文里传的是施加**结果**；`BundleGrantOrdinal` 的后端复算本就要求它是硬状态，本次只是把这条要求一般化。故本次**不跨库**。
- **正向副作用**：「新增一个资源 element」的评审清单从 3 项（key / 区间 / 终态）变成 5 项（+ 两向修正），且全落在同一行——漏项在 code review 里是一个空格，不是一段散落文字。

## Clarifications（interview 产物）

草稿以 `status: decided` 进入本次运行，两项取向已由用户在评审阶段裁定，**均取推荐项**；本次校验未发现新的冲突或含糊，故未触发 interview。

- **`PowerFragmentAccumulated.GainModifier = null`（用户裁定）** —— 随之否决「填一个 `PowerFragmentGain` key 以开启残卷积累加速类法则」：残卷进度这条元进程核心曲线会因账号而异，「玩了多久 → 拿到多少」不再是一条曲线。日后确要这类法则，正确的加法是在残卷的档位 / `Gain` / `Cap` 三表侧开旋钮，而不是让 pipeline 介入授予判定。
- **`ClampSpec` / `ResourceClamps` 更名为 `ElementSpec` / `ResourceElements`（用户裁定）** —— 随之否决「不更名」与「另起一张独立白名单表 `ElementModifiers`」：两张按同一个键索引的表必然出现「加了行 A 忘了行 B」，合成一张时漏填只是同一行里的空格。

**本次自行推演的一项（依据既有约定，非新决策）：** 更名是全库机械同步，改动面因此大于草稿列出的四份文档——`life-cycle-service.md`（终态判定伪码）· `adventure-event/common-properties.md`（两处推论）· `character-profile/currency.md` · `life-total.md` · `mana.md` · `services/plot-manager.md` 均引用旧名，一并改到；否则活文档留下悬空的类型名。

## 被否决的替代（理由承重，防止日后重提）

- **维持全称句「一律经 pipeline」、例外写在各自文档里。** 这就是原状：例外散落在 `monetization.md` 与 `profile-service.md` 两处，第三条新 element 的作者不会读到它们。
- **让 element 自己携带 `ModifierKey`（`ChangeElement(Key, BaseValue, Modifier)`）。** 修正与否是 element **类型**的属性，不是**单次变更**的属性；放进 spec 等于允许组装方逐次决定「这次让不让法则改」，把一条纪律降级为调用方选项，且 `AppliedChange` 重放时同一 key 可能带不同修正配置。
- **给 `ModifierKey` 分向（`LifeSpanCost` / `LifeSpanGain` 两个 key）而非表里两格。** 向性是 `BaseValue` 符号已经表达过的信息，在 key 名里再编码一次等于两处真值；且法则条目侧要为「消耗与产出都改」写两条 modifier。

## Open questions

- **`Jade` 的 `CostModifier` 取值依赖 Exchange 专场。** 现填 `null` 的理由是「商店价格修正在物化 / 展示侧施加」；若该专场最终定为「价格在 `TryApply` 时才修正」（商店不预先显示修正后价格），则需改填。**不阻塞本次定稿**——判据（「一个 `ModifierKey` 只施加一次，看是否需要施加前呈现」）本身不依赖专场结论。
- **多个 modifier 作用于同一 key 时的运算顺序**（加法先于乘法？声明序？优先级字段？）仍未定 → `systems/player-profile/player-power/common-properties.md`。与本次正交：答定后填进 `ApplyModifier` 内部，不改本表任何一格。
- **cost element 清单（资源族）未定** —— 决定表的**行数**，不决定表的**形态**。清单答定时逐行补两格即可。
- **`PowerFragmentFirstWin(chapter)` 以什么形态进 `Elements`**（带参数的 key？位集合？）归 cost element 清单那一问；本次只裁它不经 pipeline。
