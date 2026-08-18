---
type: solution-draft
date: 2026-08-16
question: `ProfileChangeSpec.Elements` 是否一律走 modifier pipeline？通则未收口，每新增一个 element 都要单独裁一遍「一条法则能不能改写它」。
source: open-questions/07-codex-monetization.md → 「`Elements` 是否一律走 modifier pipeline 的通则（08-15b 新增 · 承重）」
targets: systems/services/profile-service.md · systems/architecture.md（共享核心类型）· systems/monetization.md（`BundleGrantOrdinal` 豁免改为引用通则）· systems/player-profile/player-power/common-properties.md（modifier 通道的作用面）
status: distilled
distilled-to: handoffs/2026-08-16f-elements-modifier-pipeline-opt-in.md
reviewed: 2026-08-16 — 两项取向均按推荐裁定（`PowerFragmentAccumulated.GainModifier` 留空 · `ClampSpec` / `ResourceClamps` 更名为 `ElementSpec` / `ResourceElements`）
---

# 方案草稿 — `Elements` 与 modifier pipeline 的通则

## 问题

`systems/services/profile-service.md` 现文写着：

> **modifier pipeline 在此生效。** ProfileManager 读取每个 element 数值的那一刻走 `Apply(key, baseValue)`。

这是一条**全称句**：`Elements` 里的每一个都经 pipeline。但已经有两处明确豁免、且都是逐案裁的：

- **统计层**（`Stats`）——「统计 element 绝不经过 modifier pipeline（否则一条法则能改写统计数字）」；
- **`BundleGrantOrdinal`**（08-15b）——「经 pipeline = 一条法则能改写付费凭证」。

两条豁免都成立，但**通则没收口**：`Elements` 里其余的（残卷的 `PowerFragmentAccumulated` / `PowerFragmentWinOrdinal` / `PowerFragmentFirstWin`、以及「cost element 清单」日后新增的每一条）都还悬着。悬着的代价不是「有一条没定」，而是**每加一个 element 都要重新裁一次同一个问题**，而漏裁的默认值是「经 pipeline」——即**默认把新 element 暴露给法则改写**。这个洞会随每条新 element 复现。

08-15b 的原措辞建议的通则是：**「序号 / 幂等键 / 权益类 element 一律不经 pipeline」**。本草稿认为方向对、形态不对，理由见下。

## 约束（来自既有设计）

- **`ProfileChangeSpec` = 三个平级只读列表**，`Elements`（资源）· `AbilityElements`（能力）· `Stats`（统计）。已定：**能力「绝不走 modifier pipeline」**、**统计不走**。→ `systems/architecture.md`「共享核心类型」、`systems/services/profile-service.md`。
- **钳制已定为「逐 element 的一张封闭表，不是一条全局通则」**（承重）：`ResourceClamps: CostKey → ClampSpec(Min, Max, DepletionDefeat)`，落**代码常量**而非 `.tres`，「新增一行 = 新增一个资源 element 的完整语义，须与 `CostKey` 同批评审」。→ `systems/architecture.md` 同处。
- **付费凭证的承重判据：** 「capability / modifier 都是由内容条目聚合出的**派生态**，付费凭证是账号上的**原始事实**——派生态不能承载原始事实。付费凭证必须是硬状态：不参与 pipeline、后端可复算。」→ `systems/monetization.md`。
- **施加顺序已定：** `effective = ApplyModifier(key, baseValue)` → `raw = 当前值 + effective` → `落值 = Clamp(raw, Min, Max)`。→ `systems/services/profile-service.md`。
- **`CanAfford` 与 `TryApply` 必须走同一条 pipeline**（共用内部 `Evaluate(spec)`），否则 UI 显示「买得起」而实际拒绝。→ 同上。
- **`selectCost` 在物化时组装，「modifier pipeline 尚未施加，它在 `ProfileManager.TryApply` 那一刻才生效」。** → `systems/adventure-event/common-properties.md`。
- **modifier 通道的定位：** 「非布尔的全局修正（`lifeSpanCost`、商店价格、掉落权重……）由 PlayerPower 注册**具名 modifier**（key + 运算 + 数值）」，经 `CapabilityManager` 聚合，**受轮回级禁用截断**。→ `systems/player-profile/player-power/common-properties.md`。
- **`ModifierKey` 目前只出现在 API 签名 `int ApplyModifier(ModifierKey key, int baseValue)` 里**，未在 `systems/architecture.md` 的共享核心类型清单中登记，成员亦未定。

## 建议方案

### 1. 收口形态：不定语义分类的通则，改为**逐 element 的一列**（与钳制同表、同批评审）

`[既有推演]`

**建议答结的通则一句话：**

> **`Elements` 缺省不经 modifier pipeline；只有在 `ResourceElements` 表中显式登记了 `ModifierKey` 的那一行才经。`AbilityElements` / `Stats` 永不经。**

即 **opt-in 白名单**，而非「全称句 + 逐条例外」。三条依据：

1. **与已答结的钳制同构，零新机制。** 本库刚在 08-16d 答结「钳制是逐 element 的一张封闭表，不是一条全局通则」，理由是「没有任何通则能给出这些区间」。**「这个 element 能不能被法则改写」与「这个 element 的取值域是多少」是同一类逐条属性**——它由该 element 自己的语义决定（`LifeSpan` 是可被法则修正的成本量，`BundleGrantOrdinal` 是付费凭证的序号），不由任何分类推出。既然表已经存在，加一列的成本是零；「新增一行须与 `CostKey` 同批评审」这条纪律自动覆盖新列。
2. **语义分类的通则解决不了它自己要解决的问题。** 「序号 / 幂等键 / 权益类不经 pipeline」要求**给每个新 element 判类**——那正是「每次都要单独裁一遍」本身，只是把裁决从「经不经 pipeline」换成了「算不算权益类」。而边界确实模糊：`PowerFragmentAccumulated` 是进度量还是权益量？分类通则给不出答案，表给得出（表里就那一格）。
3. **缺省方向是 fail-safe 的。** 一个新 element 若漏填这一列：
   - 缺省**豁免**时，最坏后果 = 某条法则本该修正它却没修正 → 数值不对，测试与体验中可见、可复现、可改一行修好；
   - 缺省**经 pipeline** 时，最坏后果 = 某条法则**静默地**改写了幂等键 / 付费凭证 / 元进程计数 → 无人察觉，且在「云端权威 + 后端复算」下会表现为客户端与后端算不一致。
   两侧代价不对称，缺省必须取豁免侧。

### 2. 具体承载：`ClampSpec` 加两列（按符号分向），表随之更名

`[既有推演]`

只加一列 `ModifierKey?` 是不够的——**同一个资源 element 的「消耗向」与「产出向」共用一个 `CostKey`**（`ChangeElement.BaseValue` 带符号：负 = 消耗，正 = 产出）。一条「寿元消耗 −20%」的法则若不分向，会把**寿元回复也削 20%**。既有术语本就是分向的（`lifeSpanCost` 是成本向的名字，不是 `LifeSpan` 字段的名字）。

故建议两格：

```csharp
internal readonly record struct ElementSpec(       // 原 ClampSpec，加后两列
    int  Min,                                      // 施加后的下界
    int? Max,                                      // null = 无上界
    DefeatReason? DepletionDefeat,                 // null = 触底不构成终态
    ModifierKey?  CostModifier,                    // 作用于 BaseValue < 0；null = 不经 pipeline
    ModifierKey?  GainModifier);                   // 作用于 BaseValue > 0；null = 不经 pipeline

internal static readonly IReadOnlyDictionary<CostKey, ElementSpec> ResourceElements = ...
```

施加顺序改写为（其余不变）：

```
key = BaseValue < 0 ? spec.CostModifier : spec.GainModifier
effective = key == null ? BaseValue : ApplyModifier(key.Value, BaseValue)
raw       = 当前值 + effective
落值      = Clamp(raw, Min, Max)
```

- `BaseValue == 0` 不经 pipeline（无向可分，且是空操作）。
- **`CanAfford` 与 `TryApply` 共用的 `Evaluate(spec)` 读同一张表** ⇒ 「两者必须走同一条 pipeline」自动保持。
- **改名理由与代价（已裁定采纳）：** 表现在承载「取值域 + 终态 + 修正」三件事，`ResourceClamps` / `ClampSpec` 这两个名字变窄到会误导（读者会以为修正是别处配的）。代价是一次纯机械改名，当前无代码落地 ⇒ 零迁移。

### 3. 首批表内容（三行既有 + 三行残卷 + 一行权益）

`[既有推演]`（其中 `PowerFragmentAccumulated` 一行原为 `[取向选择]`，**08-16 已按推荐裁定为留空**，见「已裁决的取向项」）

| `CostKey` | Min | Max | 归 Min 时 | `CostModifier` | `GainModifier` | 依据 |
|---|---|---|---|---|---|---|
| `LifeSpan` | 0 | 无 | 终态 `LifeSpanExhausted` | **`LifeSpanCost`** | `null` | `lifeSpanCost` 是既有文档点名的第一个 modifier 用例；产出向（寿元回复）无既定修正意图，按缺省豁免 |
| `Jade` | 0 | 无 | 无 | `null` | `null` | 见下「一个 `ModifierKey` 只施加一次」——商店价格修正须在**展示价格时**就已生效，故不能再在 element 路径重复施加 |
| `LifeTotal` | 0 | 无 | 终态 `LifeTotalExhausted` | `null` | `null` | 无既定修正意图；有具体法则条目时再填，缺省豁免 |
| `PowerFragmentAccumulated` | 0 | 10000 | 无 | `null` | `null` | 万分比累计，决定「授予不授予法则」——经 pipeline = 法则加速获得法则（自举回路）。**已裁定留空** |
| `PowerFragmentWinOrdinal` | 0 | 无 | 无 | `null` | `null` | **序号**：自增值被修正即掷骰序列漂移，与 `BundleGrantOrdinal` 同理 |
| `PowerFragmentFirstWin(chapter)` | — | — | 无 | `null` | `null` | **置位**：无量纲，修正无意义 |
| `BundleGrantOrdinal` | 0 | 无 | 无 | `null` | `null` | 已定豁免（`systems/monetization.md`）——本表把它从个案改为**表里的一行**，不再是文字里的例外 |

> `PowerFragmentFirstWin(chapter)` 是置位语义、并非可加的量，它是否该待在 `Elements` 里、以什么 `CostKey` 形态表达（带参数的 key？位集合？），归「cost element 清单未定」那一问，**本方案不裁**——只裁它不经 pipeline。

### 4. 连带收口：`ModifierKey` 登记进共享核心类型，首批一个成员

`[既有推演]`

`ModifierKey` 至今只活在一处方法签名里，成员未定。本方案给它一个可落地的起点：

```csharp
public enum ModifierKey { LifeSpanCost, /* ⟨待定：其余具名修正，随各自专场补⟩ */ }
```

- **表里出现的 key 必须是 `ModifierKey` 的成员**，反向不要求——`ApplyModifier` 仍是通用查询，**非 element 路径**的数值（商店价格、掉落权重、战斗内数值）照常各自调用它。本方案**只约束 element 施加路径**，不收窄 `ApplyModifier` 的用途。
- **一个 `ModifierKey` 只能有一个施加点（承重）。** 判据：**该修正后的值是否需要在施加之前呈现给玩家**。
  - 需要 → 施加点在**物化 / 展示侧**（商店价格必须先算才能标价），此时它**不得**再出现在本表里，否则打两次折；
  - 不需要 → 施加点在 `TryApply`（`lifeSpanCost` 属此类：既定「`selectCost` 物化时 pipeline 尚未施加，在 `TryApply` 那一刻才生效」）。
  这条判据是把 `Jade` 两格填 `null` 的理由，也是防止日后新增 modifier 时双重施加的通则。

### 5. 文档改写点

`[既有推演]`

- `systems/services/profile-service.md` 的全称句 **「ProfileManager 读取每个 element 数值的那一刻走 `Apply(key, baseValue)`」须改写**为「按 `ResourceElements` 表逐行 opt-in」。这不是新增一条纪律，是把一条已经被两处例外证伪的全称句改对。
- `systems/monetization.md` 的 `BundleGrantOrdinal` 豁免段改为**引用通则 + 指向表**（保留「经 pipeline = 一条法则能改写付费凭证」这句判据，它是通则缺省方向的最强论据之一）。
- `systems/player-profile/player-power/common-properties.md` 的 modifier 通道段补一句作用面：**modifier 只作用于「非 element 数值」与「表内已登记的资源 element」**，不作用于能力、统计、序号与权益。

## 具体形态（可 derive 的落地面）

**类型（`src/Core/`）：**

| 项 | 形态 | 变化 |
|---|---|---|
| `ClampSpec` | → `ElementSpec(int Min, int? Max, DefeatReason? DepletionDefeat, ModifierKey? CostModifier, ModifierKey? GainModifier)` | 加两列 + 更名 |
| `ResourceClamps` | → `ResourceElements: IReadOnlyDictionary<CostKey, ElementSpec>` | 更名；仍为 `internal static readonly` **代码常量**，不落 `.tres`（理由同既有：它改的是规则不是难度，overlay 热更不得改写） |
| `ModifierKey` | `public enum ModifierKey { LifeSpanCost, … }` | 新登记进共享核心类型清单 |
| `ProfileChangeSpec` / `ChangeElement` / `StatDelta` / `AbilityChangeElement` | 不变 | — |
| `ApplyResult` / `TryApply` / `CanAfford` 签名 | 不变 | — |

**施加算法（`ProfileManager.Evaluate` 内，逐 `ChangeElement`）：**

```
spec = ResourceElements[e.Key]                       // 缺行 = 必需缺失 → PushError + 整批拒绝
mk   = e.BaseValue < 0 ? spec.CostModifier : (e.BaseValue > 0 ? spec.GainModifier : null)
eff  = mk == null ? e.BaseValue : ApplyModifier(mk.Value, e.BaseValue)
raw  = current[e.Key] + eff
new  = Clamp(raw, spec.Min, spec.Max)
```

**校验（启动期，与既有「坏数据大声失败」同档）：** 断言 `ResourceElements` 覆盖 `CostKey` 的**全部**成员——漏行即缺省行为不明，必须在启动期 `PushError`，而不是在轮回中途撞上。

**失败语义（并入 `profile-service.md` 已有的施加失败语义表）：**

| 情形 | 语义 | 处置 |
|---|---|---|
| `ChangeElement.Key` 在 `ResourceElements` 中无对应行 | 必需缺失（代码缺陷） | `PushError` + 整批拒绝 |
| 表内登记的 `ModifierKey` 无任何法则注册修正 | 正常 | `ApplyModifier` 原值返回（既有语义，非错误） |

## 后果

- **改动面：** `systems/architecture.md`（共享核心类型两处 + 钳制段落）· `systems/services/profile-service.md`（全称句改写 + 施加顺序 + 失败语义表加两行 + 移出该待答项）· `systems/monetization.md`（个案改引用）· `systems/player-profile/player-power/common-properties.md`（作用面一句）。
- **存档 schema：无影响。** 表是代码常量，不落存档、不落 `.tres`，无迁移。
- **对后端：无影响、也不需要对侧承接。** pipeline 是客户端内部的施加语义，报文里传的是施加**结果**；`BundleGrantOrdinal` 的后端复算本就要求它是硬状态，本方案只是把这条要求一般化。
- **正向副作用：** 「新增一个资源 element」的评审清单从 3 项（key / 区间 / 终态）变成 5 项（+ 两向修正），且全部落在同一行 —— 漏项在 code review 里是一个空格，不是一段散落文字。

## 备选方案（已考虑并否决）

- **采纳 08-15b 原措辞的语义分类通则（「序号 / 幂等键 / 权益类不经 pipeline」）。** 否决：它把「每次单独裁」从裁 pipeline 改成裁分类，没消掉裁决本身；且分类边界模糊（`PowerFragmentAccumulated` 属哪类无法从定义推出）；且它是**黑名单**形态，缺省仍是「经 pipeline」——缺省方向错在不安全的一侧。
- **维持全称句「一律经 pipeline」，例外写在各自文档里。** 否决：这就是现状，已被两处例外证伪；例外散落在 `monetization.md` 与 `profile-service.md` 两处，第三条新 element 的作者不会读到它们。
- **另起一张独立白名单表 `ElementModifiers: CostKey → (ModifierKey?, ModifierKey?)`，不动 `ResourceClamps`。** 否决（08-16 裁定采纳合表 + 更名）：两张按同一个键索引的表必然出现「加了行 A 忘了行 B」，而合成一张时漏填是同一行里的空格；`ResourceClamps` 把「取值域」与「终态」合表的理由（同批评审）在这里同样成立。
- **让 element 自己携带 `ModifierKey`（`ChangeElement(CostKey Key, int BaseValue, ModifierKey? Modifier)`）。** 否决：修正与否是 element **类型**的属性，不是**单次变更**的属性；放进 spec 等于允许组装方逐次决定「这次让不让法则改」，是把一条纪律降级为调用方选项，且 `AppliedChange` 重放时同一 key 可能带不同修正配置。
- **给 `ModifierKey` 分向（`LifeSpanCost` / `LifeSpanGain` 各一个 key）而非表里两格。** 否决：向性是 `BaseValue` 符号已经表达过的信息，再在 key 名里编码一次等于两处真值；且法则条目侧要为「消耗与产出都改」写两条 modifier。

## 与既有决策的张力

- **与 `profile-service.md` 现文的全称句直接冲突** —— 但这句话已被它自己文件内的两处豁免证伪（统计层、`BundleGrantOrdinal`），本方案是**改对**而非**松动**，不需要用户在两条设计之间取舍。
- **与「钳制是逐 element 一张封闭表，不是一条全局通则」不冲突，是同向扩展** —— 本方案正是把同一条论证扩到第二个属性上。
- **与 ADR-0002 / 0003 / 0004 / 0005 均无接触面。**
- **一处轻微张力：** 本方案给 `ModifierKey` 定了首批成员 `LifeSpanCost`，而「多个 modifier 作用于同一 key 时的运算顺序（加法先于乘法？声明序？优先级字段？）」仍是待答项（`player-power/common-properties.md`）。本方案**不裁运算顺序**，只裁「哪些 element 进 pipeline」——两问正交：运算顺序答定后填进 `ApplyModifier` 内部，不改本表任何一格。

## 前置依赖

- **「cost element 清单未定（资源族）」** —— 决定表的**行数**，不决定表的**形态**。本方案可独立于它定稿；清单答定时逐行补两格即可。
- **Exchange（交易机制）专场** —— `Jade` 两格填 `null` 的理由依赖「商店价格修正在物化/展示侧施加」这一判断。该专场未开，若最终定为「价格在 `TryApply` 时才修正」（即商店不预先显示修正后价格），则 `Jade` 的 `CostModifier` 需改填。**不阻塞本方案定稿**——判据（「一个 `ModifierKey` 只施加一次，看是否需要施加前呈现」）本身不依赖专场结论。
- **「`PowerFragmentFirstWin(chapter)` 以什么形态进 `Elements`」** —— 归 cost element 清单那一问；本方案只裁它不经 pipeline。

## 已裁决的取向项（2026-08-16 · 均按推荐定案）

> 本节原为「仍需用户决定」。两项取向已由用户裁定，**全部取推荐项**；方案正文与表格已按裁定改写，本节只留裁定与理由。

1. **`PowerFragmentAccumulated` 的 `GainModifier` = `null`（豁免）。** 法则不能加速残卷累积。理由：`Accumulated` 直接决定「这次 Finale 是否授予一条法则」，让法则修正它 = **法则加速获得法则**的自举回路；且它与 `BundleGrantOrdinal` 同属「决定授予什么」的量，付费凭证那条承重判据（「派生态不能承载原始事实」）在这里同样适用。
   **随之否决：** 填一个 `PowerFragmentGain` key 以开启「残卷积累加速」类法则的设计空间——代价是残卷进度这条元进程核心曲线会因账号而异，「玩了多久 → 拿到多少」不再是一条曲线。日后若确要这类法则，正确的加法是在残卷的档位 / `Gain` / `Cap` 三表侧开旋钮，而不是让 pipeline 介入授予判定。

2. **`ClampSpec` → `ElementSpec`、`ResourceClamps` → `ResourceElements`（更名）。** 表已承载「取值域 + 终态 + 修正」三件事，旧名会让读者以为修正配在别处。当前无代码落地 ⇒ 零迁移成本。
   **随之否决：** 不更名 / 另起一张独立白名单表（见「备选方案」末项）。

## 仍需用户决定

无 —— 两项取向均已裁定，本草稿可直接喂给 `/analyze-new-ideas`。
