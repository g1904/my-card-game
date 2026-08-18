# Phase B 报告 — 分片 D：solution-draft-element-carrier-gaps（波次 1/6）

目标库：`game-design-documents/`（客户端）。无后端库改动。`answers.md` 的 D-O1 / D-O2 / D-O3 与草稿评审阶段已裁的 5 项全部照裁决落笔；Phase A 报告 §3 的 29 条逐条执行完毕。

## 1. 改动文件逐条清单

| 文件 | 改了什么 |
|---|---|
| `systems/architecture.md` | ① `ProfileChangeSpec` 落成**最终 7 列**；② `ChangeElement` 增第三字段 `ApplyOp Op`；③ `ElementSpec` 增第六列 `ApplyOps AllowedOps`，`ResourceElements` 注释行补第六格并新增三行；④ `DeckChangeElement.Id` 注释补 `AddLooseCard`；⑤ 新增 `PlotKeyPointAssignment` record；⑥ 枚举清单：`CostKey` 增三成员、新增 `ApplyOp` / `ApplyOps` / `PlotArcState`、`DeckChangeOp` 改 5 值；⑦ **新增「三级判据」承重段 + 六面核对判据卡 + 反判据**（D-O1）；⑧ 分列段补剧本一句；⑨ modifier pipeline 段补「`Set` 恒不经 pipeline」；⑩ `Source:` 追加 |
| `systems/services/profile-service.md` | ① 各列语义列举补 `PlotElements` + `EventStateChanges` 并回链三级判据；② 失败语义表**新增 8 行**；③ 卡组小节「四个 `Op`」→ 五个、增减两向对称、新增「已在卡组 → 正常追加一张」；④ **新增「剧本推进经 `PlotElements` 写入」小节**；⑤ **`ResourceElements` 整张表增第六列 + 三新行**，表下新增三条 bullet；⑥ 施加顺序伪码增 op 准入闸与 `Set` 分支；⑦ `CanAfford` 补「`Set` 不参与可负担性」；⑧ 待决区**删 2 条**；⑨ `Source:` 追加 |
| `systems/character-profile/deck/_index.md` | 「四个 `Op`」→ 五个；「游离散牌入组无载体（缺口）」整段**改写**为 `AddLooseCard` 形态 + 三条通道 + 五条子规则；待决区**删 1 条** |
| `systems/adventure-event/exchange/common-properties.md` | 商品族表 `Card` 行 `⟨待定⟩` → `DeckChangeElement(AddLooseCard, cardId, Tier = -1)`；待决区**删 1 条** |
| `systems/adventure-event/exchange/_index.md` | 交易 spec 形状补 `Card` 族一支、`ChangeElement(Jade, -ListPrice)` 补第三参 `Add`；待决区**删 1 条** |
| `systems/services/plot-manager.md` | 推进时点段补出载体 = `PlotElements` 的 `PlotKeyPointAssignment` + 拓扑校验落 `#if DEBUG`；`PlotArcState` 注释改**回链** |
| `systems/character-profile/_index.md` | `eventEnd` 那次 `TryApply` 补出载体与条目类型；`PlotArcState` 注释改回链 |
| `terminology.md` | `ProfileChangeSpec` 词条由 4 列**补齐为 7 列**（既有漂移：原本连 `DeckElements` 都缺），补 `ChangeElement` 第三字段语义 |
| `handoffs/2026-08-17-element-carrier-gaps.md` | **新建**（`status: distilled`，`distilled-to` 列 8 份活文档）；Clarifications 三条 + 3 个 `[采纳推荐 — 待复核]` |
| `answer-logs/log-element-carrier-gaps.md` | **新建**，4 条 |

**未触碰**：`systems/monetization.md`（守 D-O3）· 所有共享台账 · `open-questions*` · `inbox/` · schema bump 统一措辞（归 A）。
溯源三条自查已跑。

## 2. 给 orchestrator 代笔的台账素材

### 2a. `handoffs/_index.md` 新增行（置顶）
```
| [element-carrier-gaps](2026-08-17-element-carrier-gaps.md) | 2026-08-17 | element 层三缺口一次答定：先立「分列 / 加 `Op` / 配表加列」三级判据（六面核对 + 反判据），再据之落 `ChangeElement.ApplyOp` + `ElementSpec.AllowedOps` · `DeckChangeOp.AddLooseCard` · `ProfileChangeSpec.PlotElements`；连带登记 `Experience` / `Faith` / `MaleficQi` 三个 `CostKey` 成员与 `PlotArcState` | distilled | `systems/architecture.md` (+7) |
```

### 2b. `open-questions/05-service-contracts.md`
**移出（删除）4 条**（原第 24–27 行）：道心 `Faith` / 煞气 `MaleficQi` 是否列入 `CostKey` · `ResourceElements` 是否增一列 `ApplyOp` · 游离散牌入组的 element 载体 · `plotKeyPoint` 的 element 形态。
> ⚠ `Faith` / `MaleficQi` 那条由 A 与 D 共同触发，**只移一次**，结论已记在 D 的 answer-log。

**新增 1 条（原文照写）：**
```
- **`monetization.md` 内部相抵——`BundleGrantOrdinal` 究竟由谁施加（08-17 新增 · 承重）。** 该文档的购买伪码由**客户端**组装 `Elements: [BundleGrantOrdinal := ordinal]` 并 `TryApply`，而同文档的购买段定案写「只能由**后端** +1，客户端 pull 到新序号后只做兑现」。它决定 `ResourceElements` 里 `BundleGrantOrdinal` 那一行的 `AllowedOps = Set` 是否存在客户端施加路径。**归 monetization / sync 专场；可能跨库**（后端 `contracts/purchase.md` 是验票写入的权威）。→ `systems/monetization.md`、`systems/services/sync-service.md`。
```
**待核（不重复新增）**：`PowerFragmentFirstWin(chapter)` 的参数化 `CostKey` 形态——若 A 已登记同题条目则不另开。

### 2c. `update-log.md` 摘要素材（本分片那一半）
- 答结 4 条：`ApplyOp` 形态（原建议「表里逐行配单值」被推翻 → 逐条带 `Op` + 表增 `AllowedOps` 列）· 散牌增向 `AddLooseCard` · `plotKeyPoint` 落新列 `PlotElements` · 道心/煞气列入 `CostKey`。
- 新增 1 条：`BundleGrantOrdinal` 由谁施加。
- 新落点：`architecture.md` 新增「三级判据」承重段 + 六面核对判据卡。

### 2d. `answer-logs/_index.md` 新增行
```
| `log-element-carrier-gaps.md` | 2026-08-17 | `inbox/archive/solution-draft-element-carrier-gaps.md` → `handoffs/2026-08-17-element-carrier-gaps.md` | 4 |
```

### 2e. `inbox/_index.md`
- 待处理表：删 `solution-draft-element-carrier-gaps.md` 行。
- 已归档表新增：
```
| `solution-draft-element-carrier-gaps.md` | solution-draft | 2026-08-17 | `handoffs/2026-08-17-element-carrier-gaps.md` | `answer-logs/log-element-carrier-gaps.md` |
```

### 2f. 草稿 frontmatter
```yaml
status: distilled
reviewed: 2026-08-17 —— 5 项取向全部取推荐项 A（2 / 4 / 5 标 [采纳推荐 — 待复核]）；合并 interview 另裁定：三级判据落 architecture.md、PlotArcState 登记进共享核心类型、BundleGrantOrdinal 行保留 Set 且本批不动 monetization.md
distilled-to: handoffs/2026-08-17-element-carrier-gaps.md
```

## 3. 越界发现（未处理）

1. `monetization.md` 的内部不一致仍在（守 D-O3），已作为新待答交回；跨库尾巴：若日后裁为「客户端不写该 key」，后端 `contracts/purchase.md` 需对称承接项。
2. `terminology.md` 的 `ProfileChangeSpec` 词条此前连 `DeckElements` 都漏了（既有漂移），本次一并补齐；同类漂移未逐条扫其它词条。
3. `profile-service.md` 待决区首条「cost element 清单未定」的括注仍写「隐藏属性推拉？」，已被本批部分回答，措辞未改。
4. `research/common-properties.md` 的槽内操作注释含 `RemoveLooseCard`；`AddLooseCard` **不应**加进 Research 槽，本分片未动。
5. 战斗奖励的单卡入组在 `combat/` 与 `scoring.md` 侧无 `⟨待定⟩` 占位，本次只填已登记的两处。

## 4. 交给后续波次的最终形态（勿重写）

### 4a. `ProfileChangeSpec` 7 列（已落笔原文）
```csharp
public sealed class ProfileChangeSpec                                     // 平级只读列表，逐条按施加语义分列
{
    public IReadOnlyList<ChangeElement>        Elements        { get; }   // 资源：带符号的量
    public IReadOnlyList<AbilityChangeElement> AbilityElements { get; }   // 能力：按 Id 的集合成员操作
    public IReadOnlyList<StatDelta>            Stats           { get; }   // 统计计数：纯自增
    public IReadOnlyList<StatusAssignment>     StatusChanges   { get; }   // Status 规则字段：绝对置值
    public IReadOnlyList<DeckChangeElement>    DeckElements    { get; }   // 卡组：带层数的构筑变更 / 多重集增删
    public IReadOnlyList<PlotKeyPointAssignment> PlotElements  { get; }   // 剧本：按 ArcId 的带载荷 upsert
    public IReadOnlyList<EventStateAssignment> EventStateChanges { get; } // 事件态：绝对置值
}
public readonly record struct ChangeElement(   // 负 = 消耗，正 = 产出（仅 Add 时有向）
    CostKey Key,
    int     BaseValue,
    ApplyOp Op);                               // 缺省 Add；Set 时 BaseValue = 已算好的绝对值
```
> **分片 C：`EventStateAssignment` 类型本身尚未定义**——D 只落了列。补它的 record 定义、语义与失败语义行，**不要重写上面的代码块**。

### 4b. `ElementSpec` 6 列 + 新枚举（已落笔原文）
```csharp
internal readonly record struct ElementSpec(      // 取值域 + 终态语义 + 修正接入 + op 准入
    int  Min, int? Max, DefeatReason? DepletionDefeat,
    ModifierKey? CostModifier, ModifierKey? GainModifier,
    ApplyOps AllowedOps);                         // 空集 = 启动期 PushError

public enum CostKey          { LifeSpan, Jade, LifeTotal, ManaLimit,
                               Experience, Faith, MaleficQi, /* ⟨待定：其余 element 清单⟩ */ }
public enum ApplyOp          { Add, Set }                                 // Add 必须为 0
[Flags] public enum ApplyOps { Add = 1, Set = 2 }
public enum DeckChangeOp     { LearnTechnique, UpgradeTechnique, ForgetTechnique,
                               AddLooseCard, RemoveLooseCard }
public enum PlotArcState     { Queued, Active, Completed, Abandoned }
public readonly record struct PlotKeyPointAssignment(
    string ArcId, string NodeId, PlotArcState State, int EnteredAtChapter, int EnteredAtSeq);
```

### 4c. `ResourceElements` 表最终形态（11 行 · 分片 A 勿动）

| `CostKey` | Min | Max | 归 Min 时 | `CostModifier` | `GainModifier` | `AllowedOps` |
|---|---|---|---|---|---|---|
| `LifeSpan` | 0 | 无 | 终态 `LifeSpanExhausted` | `LifeSpanCost` | `null` | `Add` |
| `Jade` | 0 | 无 | 无 | `null` | `null` | `Add` |
| `LifeTotal` | 0 | 无 | 终态 `LifeTotalExhausted` | `null` | `null` | `Add` |
| `ManaLimit` | 0 | 无 | 无 | `null` | `null` | `Add` |
| `Experience` | 0 | 无 | 无 | `null` | `null` | `Add` |
| `Faith` | 0 | 100 | 无 | `null` | `null` | `Add` |
| `MaleficQi` | 0 | 100 | 无 | `null` | `null` | `Add` |
| `PowerFragmentAccumulated` | 0 | 10000 | 无 | `null` | `null` | `Add \| Set` |
| `PowerFragmentWinOrdinal` | 0 | 无 | 无 | `null` | `null` | `Add` |
| `PowerFragmentFirstWin(chapter)` | 形态未定 | — | 无 | `null` | `null` | `Set` |
| `BundleGrantOrdinal` | 0 | 无 | 无 | `null` | `null` | `Set` |

### 4d. 其它跨波次约定的执行状态
- `terminology.md` 的 `ProfileChangeSpec` 词条已由 D 改完；**E 只改 location 词条**，不同段落。
- `EventOption` record 11 → 13 格：D 未触碰，留给 B / E。
- `PastEventEntry`：D 未触碰（剧本推进与散牌入组的账随 spec 自动获得，不新增字段）。
- schema bump：D 只沿用既有「bump 一次、空迁移」措辞，统一段落归 A 在 `sync-service.md`。
