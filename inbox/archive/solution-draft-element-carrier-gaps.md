---
type: solution-draft
date: 2026-08-17
question: element 层的三个载体缺口 —— `Elements` 无 Add/Set 之分、游离散牌入组无增向 `Op`、`plotKeyPoint` 无所属列表
source: open-questions/05-service-contracts.md → `ResourceElements` 是否增一列 `ApplyOp` · 游离散牌入组的 element 载体 · `plotKeyPoint` 的 element 形态
targets: systems/architecture.md（共享核心类型）· systems/services/profile-service.md（ProfileManager · 失败语义表 · `ResourceElements` 表）· systems/character-profile/deck/_index.md · systems/adventure-event/exchange/common-properties.md（商品族产出 element 一列）· systems/services/plot-manager.md · systems/character-profile/_index.md（`plotKeyPoint` 写入路径一句）
status: distilled
reviewed: 2026-08-17 —— 5 项取向全部取推荐项 A（2 / 4 / 5 标 [采纳推荐 — 待复核]）；合并 interview 另裁定：三级判据落 architecture.md、PlotArcState 登记进共享核心类型、BundleGrantOrdinal 行保留 Set 且本批不动 monetization.md
distilled-to: handoffs/2026-08-17g-element-carrier-gaps.md
---

# 方案草稿 — element 层的三个载体缺口

## 问题

三条待答项形状完全相同：**某一类施加语义在 element 层没有载体**，于是散文里已经写定的语义在类型层落不了地。

1. **`Elements` 没有 op。** `ChangeElement` 只有 `(CostKey Key, int BaseValue)`，施加算法固定为「当前值 + eff 后钳制」。但 `BundleGrantOrdinal` 已明写为**置值**（`BundleGrantOrdinal := ordinal`，`ordinal` 是先算好的绝对值）、`PowerFragmentAccumulated` 为**累加 / 置值**（每次 Finale 累加 `x`；发放法则后**重置为 `Base(x + 1)`**）。「这一行是加还是赋」目前只存在于散文中，**没有任何类型或表格承载**。
2. **`DeckChangeOp` 没有增向。** 四值里只有 `RemoveLooseCard` 一个散牌向，是减向。而三条既有通道都要求增向：① 业障由事件负向奖励塞进卡组（`deck/_index.md` 的既定通道）；② 战斗奖励的单卡入组；③ 商店 `Card` 族商品购买（`exchange/common-properties.md` 的商品族表里这一格至今是「⟨待定⟩」）。三条在 element 层一律落不了地。
3. **`plotKeyPoint` 没有所属列表。** 它已声明「写入并入 `eventEnd` 那一次 `TryApply`」（`character-profile/_index.md`、`plot-manager.md` 两处），但它是**每 arc 一条、带四个伴随字段的集合型**记录，`StatusAssignment(StatusKey, int, string)` 装不下；`ProfileChangeSpec` 现有五列没有一列能收它。

**这三条宜一次答定**：它们要么加一列、要么加一个 `Op`、要么加一列表格，而「什么时候该分列 / 该加 `Op` / 该配表」本库至今只有分散的先例（`ProfileChangeSpec` 五列、`AbilityChangeOp` 三值、`DeckChangeOp` 四值、`ResourceElements` 五列、`StatusFields` 三列），**没有写下统一判据**。逐条各答一次，很可能给出三个互不一致的形状。

## 约束（来自既有设计）

- **`ProfileManager.TryApply` 是两层 Profile 的唯一写入面；一次提交全有或全无、单点提交。**（`systems/services/profile-service.md`）
- **一个事件的收口是一次事务、一个存档点**；`plotKeyPoint`、三个 band、两个 location 字段、卡组变更全部并入 `eventEnd` 那一次 `TryApply`，**不新增存档点、不新增结算阶段**。
- **`ProfileChangeSpec` = 平级只读列表，逐条按施加语义分列；列表数不进承重表述**（它随字段族增长）。（`systems/architecture.md`）
- **element 只承载已定稿的值，`AppliedChange` 必须可直接重放。** 由此已导出两条同源结论：`DeckChangeElement.Tier` 写**目标层数**不写增量；`StatusAssignment` 写**已算好的绝对值**、`ProfileManager` 不做任何加减。
- **modifier pipeline 对 `Elements` 是 opt-in 白名单、缺省豁免；「修正与否是 element 类型的属性，不是单次变更的属性」**，故它配在 `ResourceElements` 表里而非让 `ChangeElement` 自带一个 `ModifierKey?`。`AbilityElements` / `Stats` / `StatusChanges` / `DeckElements` **恒不走** pipeline。
- **逐行配表优于全局通则**：`ResourceElements` 五列合成一张表（分表必然「加了行 A 忘了行 B」）；**启动期断言表覆盖枚举的全部成员**，漏行即 `PushError`。
- **`AbilityElements` / `DeckElements` 在 `SelectCost` 内恒为空**（成本侧只放可如实计价的量）。
- **写严读宽的既有不对称**：`(Kind, Scope, Source)` 合法子集表在**施加侧**不合法即 `PushError` + 整批拒绝，在**读档侧**遇不合法条目 `PushWarning` + 保留原值。`PlotKeyPoint` 的读档校验（悬空 → `PushWarning` + 该条惰性、保留条目）已定，属读宽那一侧。
- **`PlotKeyPoint` 的 schema 已定稿**（`ArcId` / `NodeId` / `State` / `EnteredAtChapter` / `EnteredAtSeq`，无任何 `InstanceId`），**保留惰性条目而非删除**，**不记已走分支路径**。
- **散牌是多重集**（同一张业障可在卡组里出现多张）；`RemoveLooseCard` **一条 element 移一张、不设 count 字段**。卡组规模两侧**不设硬限**。
- **卡组条目没有 `SourceCode` 挂载面**，`AbilityChangeElement` 强制携带的 `Source` 对它无落点。
- `CardData.Pool` 必填三值；**玩家侧奖励池 / 商店库存的抽取源必须只含 `Pool != Enemy`**。
- **`ElementSpec` / `StatusFields` 落代码常量而非 `.tres`**（改任一列改变的是规则而非难度）。

## 建议方案

### 0. 先给统一判据：三级问法（这是本草稿的承重部分）

`[既有推演]` —— 把本库既有的五处先例（`ProfileChangeSpec` 分列 · `AbilityChangeOp` / `DeckChangeOp` 的 `Op` · `ResourceElements` / `StatusFields` 的配表 · 「修正与否是类型属性」· 「element 只承载已定稿的值」）归纳为一条自上而下的判据。**建议把它写进 `systems/architecture.md`「共享核心类型」，作为日后所有 element 形态问题的答法**：

> **一个新的施加语义该落在哪里，自上而下问三问：**
>
> **① 新增一个列表（分列）** ⟺ 施加语义与既有各列**根本不同**。可机械核对的六个面：**要不要钳制** · **是否走 modifier pipeline** · **失败是否阻断整批** · **是否幂等** · **有无量纲** · **键与载荷的形状**（标量 / 集合成员 / 多重集成员 / 带载荷的键值 upsert）。任一列在这六面上与新语义全部对齐 ⇒ 不分列。
>
> **② 同列内新增一个 `Op`** ⟺ 语义同族——共用同一张配表、同一条校验链、同一套钳制与失败语义——但**动作的方向或形式不同**（增 vs 减、加 vs 赋、学 vs 忘 vs 升）。既有先例：`AbilityChangeOp` 三值、`DeckChangeOp` 四值。
>
> **③ 在配表里新增一列**（`ResourceElements` / `StatusFields`）⟺ 该性质是 **element 类型的属性**：同一个 key 的**每一次**变更都取同一个值（取值域、触底是否终态、修正准入、**允许的 `Op` 集合**）。
>
> **反判据（决定「配表」还是「逐条带」）：** 同一个 key 的**不同次**变更可能取不同值 ⇒ 必须**逐条带**在 element 上（`BaseValue`、`Tier`、`StatusAssignment` 的值、下文的 `Op`）。**唯一的例外恒成立：「谁有权改写它」永远是类型属性，永远配表、绝不逐条带**——逐条带会把一条纪律降级为调用方选项（这正是 `ModifierKey?` 被否决的理由）。

三条缺口按此判据分别落在 ②+③、②、① 上——**得出的是三个不同的形状，但出自同一条判据**，这正是一次答定的价值。

### 1. `Elements` 增 `ApplyOp`：逐条带 `Op`，表里加一列 `AllowedOps`

`[既有推演]`

**判据落点：② + ③。** `Add` 与 `Set` 在六个面上完全同族（同样钳制、同一张 `ResourceElements` 行、同一条终态判定、失败语义相同、同为标量、同有量纲）⇒ 不分列，落 `Op`。而「这个 key 允许哪些 op」是类型属性 ⇒ 配表。

**为什么 `Op` 必须逐条带、不能只在表里逐行配一个单值**（这是原待答项的建议形态，须推翻）：`PowerFragmentAccumulated` 在**同一个 key 上真的需要两种** —— 每次 Finale 累加 `x`（`Add`），发放法则后**重置为 `Base(x + 1)`**（`Set`，见 `answer-logs/log-legacy-fragment-chance.md`）。逐行配单值表达不了它。

**为什么重置不能写成 `Add` 的负值：** 那要求组装方读当前值算差，而 `AppliedChange` 要可**直接重放** —— 写增量会让重放结果依赖当时的值。这与 `Tier` 取目标层数、`StatusAssignment` 取绝对值是**同一条**纪律的第三次应用。

具体形态：

```csharp
public readonly record struct ChangeElement(   // 负 = 消耗，正 = 产出（仅 Add 时有向）
    CostKey  Key,
    int      BaseValue,
    ApplyOp  Op);                              // 缺省 Add；Set 时 BaseValue = 已算好的绝对值

public enum ApplyOp { Add, Set }
```

`ElementSpec` 增第六列：

```csharp
internal readonly record struct ElementSpec(
    int  Min, int? Max,
    DefeatReason? DepletionDefeat,
    ModifierKey?  CostModifier,
    ModifierKey?  GainModifier,
    ApplyOps      AllowedOps);                 // [Flags] Add / Set / Add|Set

[Flags] public enum ApplyOps { Add = 1, Set = 2 }
```

**三条连带规则（缺一即出漏洞）：**

- **`Set` 恒不经 modifier pipeline。** `BaseValue` 在 `Set` 下是一个已算好的绝对值，**符号不表达方向**，「按符号分向」无从判断该取 `CostModifier` 还是 `GainModifier`；更重的理由与 `StatusChanges` 同源——让一条法则改写一个已算定的权威值（付费凭证序号、万分比累计），等于让内容改写权威值。
- **`AllowedOps` 含 `Set` 的行，两个修正列必须恒为 `null`** —— 落为**启动期断言**（与「表覆盖 `CostKey` 全部成员」同档）。这条使上一条不靠人记。首批四个待登记 key 的两列本来就全是 `null`，零摩擦。
- **`Op` 不在 `AllowedOps` 内 → 必需缺失 → `PushError` + 整批拒绝**（代码组装缺陷，与「`Key` 在 `ResourceElements` 中无对应行」同档）。这把纪律留在表里，`Op` 只承载「这一次发生了什么」。

**施加算法更新**（`Evaluate(spec)` 内，逐 `ChangeElement`）：

```
spec = ResourceElements[e.Key]                              // 缺行 → PushError + 整批拒绝
if (e.Op & spec.AllowedOps) == 0 → PushError + 整批拒绝     // 新增
if e.Op == Set:
    落值 = Clamp(e.BaseValue, spec.Min, spec.Max)            // 不读当前值、不经 pipeline
else:
    key  = e.BaseValue < 0 ? spec.CostModifier
         : e.BaseValue > 0 ? spec.GainModifier : null
    eff  = key == null ? e.BaseValue : ApplyModifier(key.Value, e.BaseValue)
    落值 = Clamp(当前值 + eff, spec.Min, spec.Max)
```

**不受影响的既有结论：** 钳制照旧在「施加到 Profile 字段」那一刻发生、spec 与快照记未截断原值；**截断不构成 `ApplyResult.Fail`**；终态判定仍读 `Snapshot.Status`（判据「== `Min` 且 `DepletionDefeat != null`」对 `Set` 落到 `Min` 同样成立，无需改写）；`CanAfford` / `TryApply` 仍共用 `Evaluate(spec)`。**`Set` 与 `CanAfford` 的关系须明写一句：`Set` 不参与可负担性**——它不是消耗，`CanAfford` 只看 `Add` 且 `BaseValue < 0` 的那些。

**逐行取值（首批四行 + 四个待登记 key）：**

| `CostKey` | `AllowedOps` | 依据 |
|---|---|---|
| `LifeSpan` | `Add` | 寿元只有消耗与回复两向，从无「赋一个绝对寿元」的通道；开 `Set` 即给内容一条绕过 `LifeSpanCost` 修正的路 |
| `Jade` | `Add` | 同上；灵玉的每一笔都是交易的增减 |
| `LifeTotal` | `Add` | 同上 |
| `ManaLimit` | `Add` | **硬要求**：`Set` 会让「单次变动幅度恒为 1」这条承重规则失去载体（一条 `Set` 即可跳档） |
| `PowerFragmentAccumulated` | `Add \| Set` | 累加（每次 Finale）+ 置值（发放后重置为 `Base(x+1)`）；本 key 是 `Op` 必须逐条带的唯一现存例证 |
| `PowerFragmentWinOrdinal` | `Add` | 自增 = `Add(+1)`，不需要 `Set` |
| `PowerFragmentFirstWin(chapter)` | `Set` | 置位；`Add` 对布尔无意义。**该 key 自身的形态仍未定**（见前置依赖） |
| `BundleGrantOrdinal` | `Set` | 已明写「被赋为**预先算好的** `ordinal`，不是加法」 |

后四行随各自 `CostKey` 成员登记时同步生效。

### 2. 游离散牌入组 = `DeckChangeOp` 增第五值 `AddLooseCard`

`[既有推演]`

**判据落点：②。** 与 `RemoveLooseCard` 在六个面上全部同族（不钳制、恒不走 pipeline、`Id` 悬空即阻断整批、**同为非幂等的多重集成员操作**、无量纲、同为「卡牌 `Id` + `Tier = -1`」的形状），只有方向相反 ⇒ **新增一个 `Op`，不新增列、不新增字段**。

```csharp
public enum DeckChangeOp { LearnTechnique, UpgradeTechnique, ForgetTechnique,
                           AddLooseCard, RemoveLooseCard }
```

- **`Id` = 卡牌 `Id`（`CardData`）· `Tier = -1`** —— 与 `RemoveLooseCard` 完全同款，`DeckChangeElement` **零字段增量**。
- **「同名多张如何表达」直接由既有纪律回答：提交多条 element。** `RemoveLooseCard` 已定「一条 element 移一张、**不设 count 字段**（一条 element ↔ 一次可重放的操作）」；增向照抄，**不设 count**。三张业障 = 三条 `AddLooseCard`。
- **`AddLooseCard` 的目标已在卡组 → 不是失败、不是空操作，正常追加一张。** 这一条**必须明写**：`LearnTechnique` 的对应行是「已在卡组 → `PushWarning` + 空操作」，而散牌是多重集，套用那条会**静默吞掉第二张**——这正是原待答项点出的风险。
- **无上界校验** —— 卡组规模两侧不设硬限（既定），故不新增「卡组已满」这一失败情形。
- **不带 `Source`** —— 沿用 `DeckElements` 整列的既定形态（卡组条目无 `SourceCode` 挂载面）。**代价明写：** 「这张业障是哪个事件塞的 / 这张卡是买来的还是打来的」在卡组侧查不出来，只能从 `PastEventEntry.AppliedChange` 逆查。这与既定的「卡组无 `Source`」一致，不为本条开例外。
- **`DeckElements` 在 `SelectCost` 内恒为空这条不变式原样成立** —— 业障入组是 outcome 侧的**负向奖励**，不是成本；三条通道全在 outcome / 购买侧。
- **失败语义表新增 / 复用：**

  | 情形 | 语义 | 处置 |
  |---|---|---|
  | `AddLooseCard` 的 `Id` 解析不到卡牌注册表 | 必需缺失 | `PushError` + 整批拒绝（**复用**既有的 `DeckChangeElement.Id` 悬空那一行，不新增） |
  | `AddLooseCard` 的目标卡 `Pool == Enemy` | 必需缺失（代码 / 内容组装缺陷） | `PushError` + 整批拒绝（**新增**，见下） |
  | `Op == AddLooseCard` 且 `Tier != -1` | 必需缺失 | `PushError` + 整批拒绝（**复用**既有的 `Tier` 那一行，`AddLooseCard` 自动落入「其余 `Op`」） |

  **`Pool == Enemy` 那一闸是 `[既有推演]`：** 既定校验「玩家侧奖励池 / 商店库存的抽取源必须只含 `Pool != Enemy`」只管**取池侧**；element 层是敌方专用牌进入玩家卡组前的**最后一道闸**，而漏进去的后果（玩家卡组里出现一张为敌人设计的牌）在轮回中途才可见、且已落存档。加载期校验挡不住它——`AddLooseCard` 的 `Id` 也可能来自事件负向奖励的内容定义。

- **`exchange/common-properties.md` 商品族表的「⟨待定⟩」一格填为：** `Card` → `DeckElements` 的 `AddLooseCard`。一笔 `Card` 族交易的 spec = `ChangeElement(Jade, -ListPrice, Add)` + `DeckChangeElement(AddLooseCard, cardId, -1)`。

### 3. `plotKeyPoint` = `ProfileChangeSpec` 的第六列 `PlotElements`

`[既有推演]`

**判据落点：①（真的要分列）。** 逐面核对既有五列：

| 面 | `plotKeyPoint` 的写入语义 | 与既有列 |
|---|---|---|
| 键与载荷 | 键 = `ArcId`，载荷 = 四个伴随字段的整条记录 ⇒ **带载荷的键值 upsert** | `Elements` 标量 · `StatusChanges` 标量 · `AbilityElements` 集合成员（无载荷）· `DeckElements` 多重集成员（`Id` + 一个 `Tier`）——**没有一列是这个形状** |
| 幂等 | 按 `ArcId` **整条替换**（同 arc 反复推进即反复覆盖） | 与 `AbilityElements` 的「已持有 → 空操作」不同；与 `DeckElements` 的「可同名多张」相反 |
| 钳制 | 无（两个整型坐标是事实坐标，不是取值域受限的量） | — |
| pipeline | 恒不走 | 与非资源四列同 |
| 失败 | 悬空 `Id` 阻断整批 | 与 `AbilityElements` / `DeckElements` 同 |
| 量纲 | 无 | — |

前两面与五列全部不同 ⇒ **分列**。这与「列表数不进承重表述」正相合——它随字段族增长，第六列是这条纪律的预期而非例外。

```csharp
public sealed class ProfileChangeSpec
{
    public IReadOnlyList<ChangeElement>            Elements        { get; }
    public IReadOnlyList<AbilityChangeElement>     AbilityElements { get; }
    public IReadOnlyList<StatDelta>                Stats           { get; }
    public IReadOnlyList<StatusAssignment>         StatusChanges   { get; }
    public IReadOnlyList<DeckChangeElement>        DeckElements    { get; }
    public IReadOnlyList<PlotKeyPointAssignment>   PlotElements    { get; }   // 新增
}

public readonly record struct PlotKeyPointAssignment(   // 按 ArcId upsert 一条 PlotKeyPoint
    string       ArcId,
    string       NodeId,
    PlotArcState State,
    int          EnteredAtChapter,
    int          EnteredAtSeq);
```

- **形态 = `PlotKeyPoint` 本体的镜像，语义是「已算好的绝对状态」。** PlotManager 先按剧本图算出「这条 arc 该在哪个节点、什么态」，`ProfileManager` 只按 `ArcId` upsert，**不做任何推进逻辑**。与 `StatusChanges`「提交已算好的绝对值、本 manager 不做加减」是同一条纪律；也使 `AppliedChange` 可直接重放（重放结果不依赖当时在哪个节点）。
- **`ProfileManager` 不认识剧本图。** 分层不变：推进规则、单步节制、出边求值、`ExclusiveGroup`、队列出队全部留在 PlotManager；`PlotElements` 只是它把结论交给唯一写入面的通道。**`ChooseBranch` 亦经 ProfileManager 写入**（既定）——它组装出的同样是一条 `PlotKeyPointAssignment`。
- **零 `Op`，因为永不删除。** 既定「保留惰性条目而非删除」+ 四态 `Queued | Active | Completed | Abandoned` 全部由 `State` 表达（`Abandoned` 是一个态，不是删除）⇒ 不需要 `Remove` 向，`Op` 字段是纯冗余。`Queued → Active` 的出队也只是一次 upsert。
- **恒不经 modifier pipeline。** 理由与 `StatusChanges` 同源且同重：一条法则若能改写剧本进度，等于让内容改写玩家在剧情里的位置。
- **`PlotElements` 在 `SelectCost` 内恒为空** —— 与 `AbilityElements` / `DeckElements` 同款不变式（成本侧只放可如实计价的量，「推进半条剧本线值多少寿元」无法回答），同样落为物化组装后的断言 + 内容模板加载期校验。
- **失败语义（新增五行，写严；读档侧读宽的既定处置不动）：**

  | 情形 | 语义 | 处置 |
  |---|---|---|
  | `ArcId` 经 `ContentRegistry` 解析不到 `PlotArcData` | 必需缺失 | `PushError` + 整批拒绝（悬空 `Id` 写进 Profile 会污染存档；与 `AbilityId` / `DeckChangeElement.Id` 同档） |
  | `NodeId` 解析不到，或其 `ArcId` 与本条的 `ArcId` 不一致（串线） | 必需缺失 | `PushError` + 整批拒绝 |
  | `State` 越界 | 必需缺失 | `PushError` + 整批拒绝 |
  | 同一批 `PlotElements` 内出现两条同 `ArcId` | 必需缺失（组装缺陷） | `PushError` + 整批拒绝（「一次 `eventEnd` 每条 arc 至多前进一个节点」⇒ 同批同 arc 两条即缺陷；这与读档侧「同 `ArcId` 多条 → `PushWarning` + 保留 `EnteredAtSeq` 最大」不冲突，后者处理的是坏档） |
  | `EnteredAtChapter < 1` 或 `EnteredAtSeq < 0` | 必需缺失 | `PushError` + 整批拒绝 |

  **写严读宽的不对称是有意的，须明写理由：** 施加侧的悬空来自**代码 / 内容组装缺陷**，此刻拒绝还救得回来；读档侧的悬空来自 **overlay 热更 / 版本回退**，此时拒绝等于让一次内容更新废掉玩家的轮回，故降级为该条惰性。先例是 `(Kind, Scope, Source)` 合法子集表的同款读写不对称。
- **可追溯性日志（非告警）：** upsert 时打一行 `[ProfileManager-TryApply] plot arc=plot.arc.story.ashen_lineage node=plot.node.ashen_lineage.03 state=Active`。与能力得失同理——剧本推进是玩家会来问「我这条线怎么突然变了」的一类变更。
- **`PastEventEntry.AppliedChange` 随 `ProfileChangeSpec` 自动获得剧本推进的账，不新增字段。**
- **增列 ⇒ bump 存档 schema 版本**（`AppliedChange` 的形状随之变；当前无线上存档 ⇒ 空迁移，走既有 MigrationManager 骨架）。与 `DeckElements` 增列时同款处置。

## 具体形态（可 derive 的落地面）

`systems/architecture.md`「共享核心类型」改动汇总：

```csharp
// —— 改：ChangeElement 增 Op ——
public readonly record struct ChangeElement(CostKey Key, int BaseValue, ApplyOp Op);
public enum ApplyOp { Add, Set }

// —— 改：ElementSpec 增第六列 ——
internal readonly record struct ElementSpec(
    int Min, int? Max, DefeatReason? DepletionDefeat,
    ModifierKey? CostModifier, ModifierKey? GainModifier,
    ApplyOps AllowedOps);
[Flags] public enum ApplyOps { Add = 1, Set = 2 }
// LifeSpan  → (0, null, LifeSpanExhausted,  LifeSpanCost, null, Add)
// Jade      → (0, null, null,               null, null,         Add)
// LifeTotal → (0, null, LifeTotalExhausted, null, null,         Add)
// ManaLimit → (0, null, null,               null, null,         Add)   Set 恒不开，见 §1

// —— 改：DeckChangeOp 增第五值 ——
public enum DeckChangeOp { LearnTechnique, UpgradeTechnique, ForgetTechnique,
                           AddLooseCard, RemoveLooseCard };

// —— 新增：第六列 ——
public readonly record struct PlotKeyPointAssignment(
    string ArcId, string NodeId, PlotArcState State,
    int EnteredAtChapter, int EnteredAtSeq);
// ProfileChangeSpec 增 IReadOnlyList<PlotKeyPointAssignment> PlotElements
```

三条新增的**启动期断言**（与「表覆盖枚举全部成员」同档，漏则 `PushError`）：

1. `ResourceElements` 每一行的 `AllowedOps != 0`（空集 = 该 element 无任何合法写法）。
2. `AllowedOps` 含 `Set` 的行，`CostModifier == null && GainModifier == null`。
3. `DeckChangeOp` / `ApplyOp` / `ApplyOps` 的成员在各自校验分支中全覆盖（无落空的 `Op`）。

## 后果

- **改动文档：** `systems/architecture.md`（共享核心类型 + 三条判据段落 + 判据卡）· `systems/services/profile-service.md`（`ResourceElements` 表增一列 + 施加顺序伪码 + 失败语义表增 8 行 + 两条可追溯性日志）· `systems/character-profile/deck/_index.md`（「游离散牌入组当前没有 element 载体」这段缺口声明改写为 `AddLooseCard` 的形态，四个 `Op` 改五个）· `systems/adventure-event/exchange/_index.md` + `common-properties.md`（商品族表填格、待决问题移出）· `systems/services/plot-manager.md`（推进时点那一段点明载体 = `PlotElements`）· `systems/character-profile/_index.md`（`plotKeyPoint` 的「写入并入 `eventEnd`」一句补出载体）。
- **移出待答：** `open-questions/05-service-contracts.md` 三条 · `deck/_index.md` 与 `exchange/*` 各自的同题条目 · `profile-service.md` 待决问题里的散牌那条。（本技能不写这些，归 `/analyze-new-ideas`。）
- **存档：** bump schema 版本一次（`AppliedChange` 形状变）；当前无线上存档 ⇒ 空迁移。`CharacterProfile` / `PlayerProfile` 的**字段**不因本方案增减——三条改动全在**变更规格（spec）**一侧。
- **不受影响：** 「全有或全无、单点提交」· 存档点数量 · 结算阶段数 · `ApplyResult` 的形状（`MissingElement: CostKey` 仍只对资源列表有意义）· `CanAfford` 与 `TryApply` 共用 `Evaluate` · `RngStream` 子流 · EventBus 负载。

## 备选方案（已考虑并否决）

**缺口 ① ：**
- **逐行配单一 `ApplyOp`（原待答项的建议形态）** — 否决：`PowerFragmentAccumulated` 同一个 key 上真的两种（累加 + 发放后重置），单值表达不了。
- **用 `Add` 的负值表达重置 / 置值** — 否决：组装方要读当前值算差，`AppliedChange` 的直接重放当场失效。
- **把置值类 element 移进 `StatusChanges`** — 否决：`StatusChanges` 是 `CharacterProfile.Status` 的规则字段通道，而 `BundleGrantOrdinal` 在 `PlayerEntitlement`、`PowerFragment*` 在 `PlayerProfile`；且 `StatusFieldSpec` 只有 `(Kind, Min, Max)` 三列，装不下终态与修正准入。原待答项已自行否决过这条路（「即便加了它，`CurrentLocationId` 仍是 `string`，`Elements` 仍装不下」）。
- **为置值类新开一列 `ResourceAssignments`** — 否决（但这是最有分量的备选，见「仍需用户决定」第 1 项）：`Add` / `Set` 共用同一张 `ResourceElements` 行、同一套钳制与终态判定，分列会让**同一个 `CostKey` 的语义散在两列**、两列共用一张表——正是「分表必然漏行」要避免的形状。

**缺口 ②：**
- **新开一列 `LooseCardElements`** — 否决：与 `RemoveLooseCard` 六面同族，分列即把多重集的增与减拆到两处维护。
- **复用 `AbilityElements` 的 `Grant`** — 否决（既定）：集合成员操作的幂等语义会静默吞掉第二张；`Source` 对卡组无落点。
- **给 `DeckChangeElement` 加 `Count`** — 否决（既定）：一条 element ↔ 一次可重放的操作。

**缺口 ③：**
- **塞进 `StatusChanges`，加一个 `Id` 型 `StatusKey`** — 否决：集合型、每 arc 一条、带四个伴随字段，`StatusAssignment(Key, int, string)` 装不下（原待答项已判明）。
- **PlotManager 直接写 `CharacterProfile`** — 否决：`ProfileManager` 是唯一写入面。
- **为剧本推进另开一次 `TryApply` / 一条通道** — 否决：一个事件的收口是一次事务、一个存档点。
- **`PlotElements` 带 `Op { Upsert, Remove }`** — 否决：既定「保留惰性条目而非删除」+ 四态由 `State` 表达 ⇒ `Remove` 向不存在，`Op` 是纯冗余。
- **在 `PlotElements` 上记已走分支路径** — 否决（既定）：路径无消费方，落点是 `PastEventEntry`。

## 与既有决策的张力

1. **「修正与否是 element 类型的属性，不是单次变更的属性」vs 逐条带 `Op`。** 表面同类，实质两回事：`Op` 描述**这一次发生了什么**（事实，逐次不同，属反判据管辖），`ModifierKey` 描述**谁有权改写它**（纪律，恒定）。方案用 `AllowedOps` 表列把纪律仍留在表里，`Op` 只承载事实 ⇒ 「不把纪律降级为调用方选项」这条**没有松动**。**若用户不接受这条区分**，唯一自洽的替代是分列（`ResourceAssignments`），见「仍需用户决定」第 1 项。
2. **「按符号分向」在 `Set` 下无定义。** 这不是松动既有规则，而是**补一条互补规则**（`Set` 恒不经 pipeline + 启动期断言把两个修正列锁为 `null`），使「分向」的适用域被明确限定在 `Add`。
3. **`ProfileChangeSpec` 涨到六列。** 与「列表数不进承重表述」相容（该纪律正是为此写的），但**代价明写**：每加一列，`TryApply` 的校验链、`AppliedChange` 的序列化、diff 面各加一段；这一次的收益是 `plotKeyPoint` 从「散文里说要写」变成「类型上写得出来」。
4. **`AddLooseCard` 不带 `Source`。** 与「凡授予 power / item 的 element 一律强制带来源」不同轨（那条只管能力族），但确实留下「这张业障哪来的」在卡组侧不可查。方案选择**不为本条破例**（否则 `DeckElements` 整列的形态要改），代价已在 §2 明写。

## 前置依赖

- **`CostKey` 资源族的完整清单（承重待决，另案）。** `AllowedOps` 的**逐行取值**对后四个 key（`PowerFragment*` 三项 + `BundleGrantOrdinal`）随它们各自登记时才生效；**表结构与三条连带规则不依赖它**，可先落。
- **`PowerFragmentFirstWin(chapter)` 的 key 形态未定**（参数化 key 如何进 `CostKey`）。它那一行的 `AllowedOps = Set` 是形态定后才能落的一格。
- **`Faith` / `Bloodlust` 是否列入 `CostKey`**（不在本批）。若列入，两行的 `AllowedOps` 需一并裁定——**建议届时取 `Add`**（既定「经隐藏属性推拉施加」是增减语义），但本草稿不预设。
- **`plotKeyPoint` 的内容侧逐条映射**（哪个 arc 在哪个节点触发什么）归 ch1 / plot 专场，与本方案的载体形态无关。
- **⚠ 与 S1 分片（`CharacterProfile` / `PlayerProfile` 字段 schema）的对齐：** 本方案**只改变更规格（spec）一侧，不定任何 Profile 字段**。但两处形状必须一致 ——
  - `PlotKeyPointAssignment` 是 `PlotKeyPoint` record 的镜像。**若 S1 改动 `PlotKeyPoint` 的字段集**（增删字段 / 改名 / 改 `PlotArcState` 值域），`PlotElements` 的载荷须同步，否则 upsert 装不下。
  - `AddLooseCard` 假定卡组的游离散牌部分是「卡牌 `Id` 的多重集」（`deck/_index.md` 推论 ③ 的既定形态）。**若 S1 把散牌改为带附加运行态的结构**，`AddLooseCard` 需要第二个载荷字段。
  - `ApplyOp = Set` 假定 `PowerFragmentAccumulated` / `BundleGrantOrdinal` 是可被整体赋值的标量字段（`PlayerPowerFragment.Accumulated` / `PlayerEntitlement.BundleGrantOrdinal`）。
  **这三点须与 S1 的 schema 对齐后才能定稿。**

## 仍需用户决定 → **已全部裁决（2026-08-17 · 批量评审）**

> **定案（五项一律取推荐项 A）：**
> **1 取 A** —— `Set` 落「同列带 `Op`」：`ChangeElement(CostKey, int, ApplyOp)` + `ElementSpec` 增第六列 `ApplyOps AllowedOps`。三条连带规则全部采纳（`Set` 恒不经 pipeline · 含 `Set` 的行两个修正列恒为 `null` 并加启动期断言 · `Op` 不在 `AllowedOps` 内则 `PushError` + 整批拒绝），并明写 `Set` 不参与 `CanAfford`。张力 1（`Op` 逐条带 vs `ModifierKey` 恒配表）按草稿的区分成立：`AllowedOps` 把纪律仍留在表里 ⇒ 单一施加点纪律**未松动**。
> **2 取 A `[采纳推荐 — 待复核]`** —— `ApplyOp` 现在就落结构，逐行取值随 `CostKey` 成员登记补齐。
> **3 取 A** —— 散牌增向定名 **`AddLooseCard`**（与 `RemoveLooseCard` 严格对称）；同名多张 = 提交多条 element、不设 count；明写「目标已在卡组 → 正常追加一张，不是空操作」；新增 `Pool == Enemy → PushError + 整批拒绝` 一道闸。
> **4 取 A `[采纳推荐 — 待复核]`** —— 第六列定名 `PlotElements`，类型 `PlotKeyPointAssignment`。
> **5 取 A `[采纳推荐 — 待复核]`** —— `ProfileManager` 只校验 `Id` 可解析 / 不串线 / 同批不重复；「单步推进」的拓扑校验走 PlotManager 的 `#if DEBUG` 断言。
>
> **本轮同批裁定的连带（跨分片，orchestrator 合并）：**
> - **本草稿的三处类型改动与同批 S3 的 `EventStateChanges` 列在同一段代码块内，必须一次落笔**：`ProfileChangeSpec` 本轮共增**两列**（`PlotElements` + `EventStateChanges`），`ChangeElement` 增第三字段，`ElementSpec` 增第六列。成本侧恒空断言**逐列独立写**、不合并成通则。
> - **同批 S1 从 Profile 字段侧独立撞到同一条裂缝**（`looseCard` 缺增向 `Op`），与本草稿的 `AddLooseCard` 互为印证；S1 同时发现 `experiencePoint` / `faith` / `bloodlust` 缺 `CostKey` 成员 ⇒ 用户裁定**同批把 `Experience` / `Faith` / `Bloodlust` 登记为 `CostKey` 成员**。本草稿对 `Faith` / `Bloodlust` 只给了「届时建议 `Add`」而未预设——该建议此刻生效，三个新成员的 `AllowedOps` 取 `Add`。
> - 五份草稿的 schema bump **合并为同一次**。
>
> 下列原文保留为选项与理由的溯源。

1. **`Set` 语义落「同列带 `Op`」还是「新开一列 `ResourceAssignments`」（承重 · 本草稿最需点头的一项）。**
   - **选项 A（推荐）：** `ChangeElement` 增 `ApplyOp Op` + `ElementSpec` 增 `AllowedOps` 列。
     后果：`Elements` 一列即覆盖加与赋；同一个 `CostKey` 的全部语义留在 `ResourceElements` 的同一行；代价是「逐条带一个决定施加方式的字段」这件事第一次出现在资源列上，需靠 `AllowedOps` + 启动期断言把纪律锁住。
   - **选项 B：** 新开第六/七列 `ResourceAssignments`（`(CostKey Key, int Value)`），`Elements` 保持纯加法。
     后果：`ChangeElement` 一字不改，「逐条不带施加方式」的纯净性完整保留；代价是同一个 `CostKey`（`PowerFragmentAccumulated`）要在两列各出现一次，两列共用同一张 `ResourceElements` 表却各走一条校验链——本库已明写「分表必然出现『加了这张忘了那张』」，而这是同一风险的另一种形态。
   - **推荐 A 的理由：** 判据 ①（分列 ⟺ 六面根本不同）在此不成立——`Add` / `Set` 共用钳制、共用取值域、共用终态判定、共用失败语义。既有两列（`AbilityElements` / `DeckElements`）都已用 `Op` 表达同族内的不同动作，A 与它们同形；B 会让 `ProfileChangeSpec` 的分列判据从「按施加语义」滑向「按施加动作」。

2. **`ApplyOp` 是否现在就落，还是与「`CostKey` 资源族清单」同批。**
   - **选项 A（推荐）：** 现在落**结构**（`Op` 字段 + `AllowedOps` 列 + 三条连带规则 + 首批四行取值），逐行取值随 `CostKey` 成员登记补齐。
   - **选项 B：** 整条推迟到资源族清单答定时一次做完。
   - **推荐 A 的理由：** 原待答项标「轻 · 不阻塞」，但 `BundleGrantOrdinal` 的置值语义**今天已在 `monetization.md` 写定并被三道闸依赖**，而类型层表达不出来 —— 这已经是一处「散文与类型不一致」的活漏洞；先落结构可让它闭合，且结构本身不依赖清单。

3. **散牌增向 `Op` 的定名。**
   - **选项 A（推荐）`AddLooseCard`** —— 与 `RemoveLooseCard` 严格对称，读表时一眼成对。
   - **选项 B `GainLooseCard`** —— 与奖励语域贴合，但三条通道之一是**塞业障**（负向），"Gain" 措辞与之相左。
   - **选项 C `AcquireLooseCard`** —— 更中性，但与既有四个 `Op` 的短动词风格（Learn / Upgrade / Forget / Remove）不齐。
   - **推荐 A** ：对称性在这张五值枚举里是最强的可读性来源。

4. **第六列的列名与类型名。**
   - **选项 A（推荐）：** 列名 `PlotElements` + 类型 `PlotKeyPointAssignment`。列名与 `DeckElements` 同款；类型名沿用 `StatusAssignment` 的「置值」词根（本条同样是「赋一个已算好的绝对状态」）。
   - **选项 B：** 列名 `PlotKeyPoints` + 类型 `PlotKeyPointChange`。更直白，但列名与其余五列的 `*Elements` / `Stats` / `*Changes` 风格都不齐，且 `Change` 一词在本库已被 `ChangeElement` / `DeckChangeElement` 用于「带 `Op` 的变更」，而本条没有 `Op`。
   - **推荐 A。**

5. **「单步推进」的拓扑校验落在哪一侧。**
   - **选项 A（推荐）：** `ProfileManager` **不校验拓扑**（只校验 `Id` 可解析 / 不串线 / 同批不重复）；「新 `NodeId` 必须是当前节点的一条出边或等于当前节点」由 **PlotManager 在推进时 `#if DEBUG` 断言**。
     后果：`ProfileManager` 不必认识剧本图，分层干净；代价是 Release 构建里一条越级推进不会被拦住（但它只能由 PlotManager 自己的缺陷产生，而 PlotManager 是唯一组装方）。
   - **选项 B：** `ProfileManager` 读 `PlotArcData` 的出边做强校验，违反即 `PushError` + 整批拒绝。
     后果：越级推进在任何构建下都拦得住；代价是唯一写入面开始持有剧本图的拓扑知识，与「PlotManager 是剧本内容的解析器、ProfileManager 只施加」这条分层相左，且每次 upsert 多一次图查询。
   - **推荐 A** ：按纪律可执行化的阶梯，这一条属「唯一组装方的内部不变式」，第 3 级（`#if DEBUG` 大声失败）足够；升到入口强校验换来的是分层污染。
