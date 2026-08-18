# element 层的三个载体缺口：`ApplyOp` · `AddLooseCard` · `PlotElements`

- id: 2026-08-17g-element-carrier-gaps
- date: 2026-08-17
- topic: systems/architecture.md · systems/services/profile-service.md · systems/character-profile/deck/_index.md · systems/adventure-event/exchange/ · systems/services/plot-manager.md · systems/character-profile/_index.md · terminology.md
- status: distilled
- distilled-to: systems/architecture.md, systems/services/profile-service.md, systems/character-profile/deck/_index.md, systems/character-profile/_index.md, systems/adventure-event/exchange/_index.md, systems/adventure-event/exchange/common-properties.md, systems/services/plot-manager.md, terminology.md

## Intent（distilled）

三条待答项形状完全相同：**某一类施加语义在 element 层没有载体**，于是散文里已经写定的语义在类型层落不了地。本次一次答定，并先给出统一判据，使三个答案出自同一条推理。

### 0. 统一判据：三级问法（本次的承重产出）

一个新的施加语义该落在哪里，自上而下问三问，取第一个成立的落点：

- **① 新增一个列表（分列）** ⟺ 施加语义与既有各列**根本不同**。可机械核对的六个面：**要不要钳制** · **是否走 modifier pipeline** · **失败是否阻断整批** · **是否幂等** · **有无量纲** · **键与载荷的形状**（标量 / 集合成员 / 多重集成员 / 带载荷的键值 upsert）。任一既有列在这六面上与新语义全部对齐 ⇒ 不分列。
- **② 同列内新增一个 `Op`** ⟺ 语义同族（共用同一张配表、同一条校验链、同一套钳制与失败语义），但动作的方向或形式不同。
- **③ 在配表里新增一列** ⟺ 该性质是 **element 类型的属性**：同一个 key 的每一次变更都取同一个值。
- **反判据：** 同一个 key 的不同次变更可能取不同值 ⇒ 必须逐条带在 element 上；**唯一恒成立的例外是「谁有权改写它」永远是类型属性、永远配表**——逐条带会把一条纪律降级为调用方选项。

三条缺口按此判据分别落在 ②+③、②、① 上——形状各不相同，但出自同一条判据。

### 1. `Elements` 增 `ApplyOp`：逐条带 `Op` + 表里加一列 `AllowedOps`

`Add` 与 `Set` 在六个面上完全同族 ⇒ 不分列，落 `Op`；「这个 key 允许哪些 op」是类型属性 ⇒ 配表。

```csharp
public readonly record struct ChangeElement(CostKey Key, int BaseValue, ApplyOp Op);  // 缺省 Add
public enum ApplyOp { Add, Set }                    // Add 必须为 0
[Flags] public enum ApplyOps { Add = 1, Set = 2 }
internal readonly record struct ElementSpec(
    int Min, int? Max, DefeatReason? DepletionDefeat,
    ModifierKey? CostModifier, ModifierKey? GainModifier, ApplyOps AllowedOps);
```

- **`Op` 必须逐条带、不能只在表里逐行配单值**：`PowerFragmentAccumulated` 在同一个 key 上真的需要两种（每次 Finale 累加 `x`；发放法则后重置为 `Base(x + 1)`）。
- **重置不能写成 `Add` 的负值**：那要求组装方读当前值算差，而 `AppliedChange` 要可直接重放。与 `Tier` 取目标层数、`StatusAssignment` 取绝对值是同一条纪律的第三次应用。
- **三条连带规则：** `Set` 恒不经 modifier pipeline · 含 `Set` 的行两个修正列恒为 `null`（启动期断言）· `Op ∉ AllowedOps` → `PushError` + 整批拒绝。另明写 **`Set` 不参与 `CanAfford`**。
- **代价明写：** 第二条断言把「允许 `Set`」与「两个修正列为 `null`」焊在同一个 key 上，结构上排除「同一 key 既走修正的 `Add`、又有不走修正的 `Set`」这一形态；首批与待登记 key 全部零摩擦。

### 2. 游离散牌入组 = `DeckChangeOp` 增第五值 `AddLooseCard`

与 `RemoveLooseCard` 六面同族、只有方向相反 ⇒ 加一个 `Op`，不新增列、不新增字段。`Id` = 卡牌 `Id`、`Tier = -1`、`DeckChangeElement` 零字段增量；同名多张 = 多条 element，**不设 count**；**目标已在卡组 → 正常追加一张，不是空操作**（套用集合幂等语义会静默吞掉第二张）；不带 `Source`（代价：来源只能从 `PastEventEntry.AppliedChange` 逆查）；新增 **`Pool == Enemy` → `PushError` + 整批拒绝** 一道闸——取池侧的过滤只管抽取，element 层是敌方专用牌进入玩家卡组前的最后一道闸。三条通道（事件负向奖励塞业障 / 战斗奖励单卡入组 / 商店 `Card` 族购买）就此全部落地。

### 3. `plotKeyPoint` = `ProfileChangeSpec` 增列 `PlotElements`

键 = `ArcId`、载荷 = 整条记录的**带载荷键值 upsert**，且按 `ArcId` 整条替换 —— 这两面与既有五列全部不同 ⇒ 真的要分列。

```csharp
public readonly record struct PlotKeyPointAssignment(
    string ArcId, string NodeId, PlotArcState State, int EnteredAtChapter, int EnteredAtSeq);
```

- 形态 = `PlotKeyPoint` 的镜像，语义是「已算好的绝对状态」；`ProfileManager` 不认识剧本图，`ChooseBranch` 组装出的同样是一条 `PlotKeyPointAssignment`。
- **零 `Op`**（保留惰性条目而非删除 + 四态由 `State` 表达 ⇒ 无 `Remove` 向）· **恒不经 pipeline** · **`SelectCost` 内恒空**（独立成行的断言）。
- **施加侧写严：** `ArcId` / `NodeId` 悬空或串线、`State` 越界、同批同 `ArcId` 两条、两个整型坐标越界，一律 `PushError` + 整批拒绝；读档侧读宽的既定处置（`PushWarning` + 该条惰性 + 保留条目）不动。
- **拓扑校验落 PlotManager 的 `#if DEBUG` 断言**，`ProfileManager` 不持有剧本图知识。
- `PastEventEntry.AppliedChange` 随 `ProfileChangeSpec` 自动获得剧本推进的账，不新增字段。

### 连带

- **`ProfileChangeSpec` 本轮共增两列**（`PlotElements` + 事件态的 `EventStateChanges`），与 `ChangeElement` 增第三字段、`ElementSpec` 增第六列**一次落笔**。成本侧恒空断言逐列独立写，不合并成通则。
- **`Experience` / `Faith` / `MaleficQi` 本批登记为 `CostKey` 成员**，三者 `AllowedOps` 取 `Add`；`Faith` / `MaleficQi` 的两个修正列留空——一条法则能伪造隐藏属性，即等于伪造整条剧本线的触发条件。
- **`PlotArcState` 登记进 `systems/architecture.md` 的共享核心类型枚举清单**，`plot-manager.md` 与 `character-profile/_index.md` 两处改为回链。
- **bump 存档 schema 版本一次**（`AppliedChange` 形状随 `ProfileChangeSpec` 变；当前无线上存档 ⇒ 空迁移），与同批其余草稿合并为同一次。
- Profile 的**字段**不因本次增减——三条改动全在变更规格（spec）一侧。

## Clarifications（interview 产物）

- **三级判据是否落成常设通则？** → 落，写进 `systems/architecture.md`「共享核心类型」，形态 = 一段承重正文 + 一张「六面核对」判据卡，含 ② 加 `Op` 与 ③ 配表加列的条件以及反判据。原草稿只把它标为推演理由，此裁决把它升为约束未来所有同类问题的常设闸门。
- **`PlotArcState` 声明在哪？** → 登记进 `architecture.md` 的共享核心类型枚举清单（与 `CostKey` / `DeckChangeOp` / `CycleStatus` 等八个先例同形），两处引用改回链、不复述。
- **`BundleGrantOrdinal` 那一行的 `AllowedOps = Set` 是否仍有客户端施加路径？** → 该行保留 `Set`，本次不动 `systems/monetization.md`；「该 key 究竟由谁施加」的文档内部不一致登记为一条独立待答，归 monetization / sync 专场（可能跨库）。

## Open questions

- **`[采纳推荐 — 待复核]` `ApplyOp` 现在就落结构**，逐行取值随 `CostKey` 成员登记补齐。
- **`[采纳推荐 — 待复核]` 第六列定名 `PlotElements`、条目类型 `PlotKeyPointAssignment`。**
- **`[采纳推荐 — 待复核]` `ProfileManager` 只校验 `Id` 可解析 / 不串线 / 同批不重复**，「单步推进」的拓扑校验走 PlotManager 的 `#if DEBUG` 断言。
- **`monetization.md` 内部相抵：`BundleGrantOrdinal` 究竟由谁施加。** 它决定 `ResourceElements` 里那一行的 `Set` 是否存在客户端施加路径。
- **`PowerFragmentFirstWin(chapter)` 的参数化 `CostKey` 形态未定** —— 它那一行的 `AllowedOps = Set` 是形态定后才能落的一格。

## Notes / triage

来源草稿：`inbox/solution-draft-element-carrier-gaps.md`（`/provide-solution-draft` 产物，用户已评审，五项裁决全部取推荐项 A）。
