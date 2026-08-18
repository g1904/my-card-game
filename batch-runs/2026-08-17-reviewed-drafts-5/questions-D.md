# Phase A 报告 — 分片 D：solution-draft-element-carrier-gaps（element 层的三个载体缺口）

> 目标库：`game-design-documents/`（客户端）。草稿 `targets` 全部落在客户端主题文档区；无后端库承接项（唯一擦边处见 §6）。
> 本阶段严格只读，未写入任何设计库 / 台账文件。

## 1. 意图要点（我的理解）

1. 三条待答项形状同构：**某一类施加语义在 element 层没有载体**，散文已写定的语义在类型层落不了地。
2. 草稿先给一条**统一判据（三级问法 ① 分列 / ② 加 `Op` / ③ 配表加列 + 反判据）**，再用它推出三个各不相同的形状——这是草稿自称的承重部分。
3. 缺口①：`ChangeElement` 增第三字段 `ApplyOp Op { Add, Set }`；`ElementSpec` 增第六列 `ApplyOps AllowedOps`（`[Flags]`）。三条连带规则：`Set` 恒不经 modifier pipeline · 含 `Set` 的行两个修正列恒为 `null`（启动期断言）· `Op ∉ AllowedOps` → `PushError` + 整批拒绝。并明写 `Set` 不参与 `CanAfford`。
4. 缺口②：`DeckChangeOp` 增第五值 `AddLooseCard`（`Id` = 卡牌 `Id`、`Tier = -1`、零字段增量）；同名多张 = 多条 element、不设 count；「目标已在卡组 → 正常追加一张、不是空操作」必须明写；新增 `Pool == Enemy → PushError + 整批拒绝` 一道闸；填掉 `exchange/common-properties.md` 商品族表 `Card` 那一格。
5. 缺口③：`ProfileChangeSpec` 增列 `PlotElements`，条目类型 `PlotKeyPointAssignment`（`PlotKeyPoint` 的镜像，按 `ArcId` upsert、零 `Op`、恒不经 pipeline、`SelectCost` 内恒空），并新增五行写严的施加侧失败语义。
6. 用户已在评审中把 5 项**全部裁决为推荐项 A**（其中 2 / 4 / 5 标 `[采纳推荐 — 待复核]`），并追加三条跨分片连带（见 §2 的 ✅ 区）。
7. 草稿明确**不改任何 Profile 字段**，三条改动全在变更规格（spec）一侧；连带 bump 一次存档 schema 版本（本批五份草稿合并为同一次）。

## 2. 校验发现

### 🔴 冲突（必须 interview）

**（无）** —— 三条形态与既有承重纪律逐条核对后一致：`element 只承载已定稿的值 / AppliedChange 可直接重放`（`architecture.md` 395 行、`profile-service.md` 76 行）· `修正与否是 element 类型的属性`（`profile-service.md` 98 行）· `逐行配表优于全局通则`（`profile-service.md` 81–101 行）· `一个事件的收口是一次事务、一个存档点`（`profile-service.md` 29 行、`character-profile/_index.md` 101 行）· `保留惰性条目而非删除 / 不记已走分支路径`（`plot-manager.md` 345、361 行）· `散牌是多重集、不设 count`（`profile-service.md` 77 行）· `玩家侧抽取源只含 Pool != Enemy`（`deck/_index.md` 87 行）均未被推翻。张力 1–4 草稿已逐条化解，且用户已确认张力 1 的区分成立。

### 🟠 含糊（必须 interview）

- **① 三级判据（§0 的「三问 + 反判据」）是否作为常设判据段落写进 `systems/architecture.md`，还是只作为本次三条结论的推导理由、不落成通则？**
  - 想法侧：草稿 §0 明写「**建议把它写进 `systems/architecture.md`「共享核心类型」，作为日后所有 element 形态问题的答法**」，并自称这是本草稿的承重部分。
  - 既有权威：`architecture.md` 391 行只写了「**施加语义根本不同就分列**」一句判据 + 各列语义列举，**没有**「六个可机械核对的面」「② 加 `Op` 的条件」「③ 配表加列的条件」「反判据：逐次可变的必须逐条带，唯『谁有权改写它』永远配表」。写进去 = 新增一条约束**所有未来 element 形态问题**的常设闸门。
  - **它没有进用户的裁决清单**：五项裁决只覆盖 `## 仍需用户决定` 的 1–5，§0 标的是 `[既有推演]`。判定为 🟠 而非 🔵，理由是它的影响面（约束未来所有同类问题）远大于一次推演，且落笔位置 / 形态（正文段落 vs 判据卡 vs 两者都要）会写出不同的文档。
  - 选项与后果：
    (a) **写进 `architecture.md`「共享核心类型」，形态 = 一段承重正文 + 一张「六面核对」判据卡** ⇒ 本批同时新增两列（`PlotElements` / `EventStateChanges`）、一个 `Op`、一个表列，判据一次写下即被四处引用；代价是日后每次列形态之争都要先过这道闸。不触后端库、不改任何 ADR。
    (b) **只写六面核对表、不写「② / ③ / 反判据」的通则表述** ⇒ 分列这一问有判据，加 `Op` / 加表列仍靠先例类推。
    (c) **不写通则**，三条结论各自在落点文档就地给理由 ⇒ `architecture.md` 零新增承重表述；代价是下一次遇到同类问题（几乎必然发生，`CostKey` 资源族清单与 `StatKey` 清单都在待答）又要重新推一遍，且很可能推出不一致的形状。
  - **推荐：(a)** —— 依据既有设计而非偏好：本库已经把「纪律的可执行化四级阶梯」（`architecture.md` 436–473 行）、「共有属性提炼粒度判据」（`systems/common-properties.md`）等**判据本身**当作一等文档内容沉淀，先例明确；且 §0 的反判据正是「`ModifierKey` 不逐条带」这条已定纪律的一般化，写下它使该纪律不再是孤例。

- **② `PlotArcState` 的声明落点未指定。**
  - 想法侧：`PlotKeyPointAssignment` 落 `src/Core/` 的共享核心类型，其第三个字段类型是 `PlotArcState`。
  - 既有权威：`architecture.md` 367–386 行的枚举清单**不含 `PlotArcState`**；该枚举目前只出现在 `plot-manager.md` 319–325 行与 `character-profile/_index.md` 88–92 行的 `PlotKeyPoint` record 内联注释里，**从未指定它声明在哪。** 而 `ProfileChangeSpec` 各列引用的每一个枚举（`CostKey` / `StatusKey` / `DeckChangeOp` / `AbilityChangeOp` / `AbilityKind` / `AbilityScope` / `DisableDuration` / `StatKey`）**无一例外**都登记在该清单里。
  - 选项与后果：
    (a) **把 `public enum PlotArcState { Queued, Active, Completed, Abandoned }` 登记进 `architecture.md` 共享核心类型的枚举清单** ⇒ 与既有八个先例同形；`plot-manager.md` / `character-profile/_index.md` 两处改为回链，不复述。
    (b) **留在剧本侧类型文件，Core 反向引用它** ⇒ `src/Core/` 开始依赖剧本域类型，与「共享核心类型是被各方引用的底层」相反。
  - **推荐：(a)** —— 八处同款先例；且 `PlotKeyPoint` 本身是存档类型，其枚举本就该与 `CycleStatus` / `DefeatReason` 同处。

- **③ `BundleGrantOrdinal` 的 `AllowedOps = Set` 行是否仍有客户端施加路径？（既有权威内部不一致，本草稿的逐行取值依赖它）**
  - 想法侧：`BundleGrantOrdinal → AllowedOps = Set`，依据「已明写被赋为预先算好的 `ordinal`」。
  - 既有权威——**同一份文档两处相抵**：`systems/monetization.md` 62–69 行的伪码由**客户端**组装 `spec = { Elements: [ BundleGrantOrdinal := ordinal ], … }` 并 `ProfileManager.TryApply(spec)`；而同文件 79–85 行（08-15b 购买段定案）写「**后端**把云端 `bundleGrantOrdinal` +1」「谁有权把 `BundleGrantOrdinal` 从 n 推到 n+1 **只能是后端**，否决客户端自行置位」，客户端只是 **pull 到新序号**后掷骰兑现。
  - 选项与后果：
    (a) **保留该行 `Set`，不在本次动 `monetization.md`** ⇒ 本草稿零改动；代价是表里留着一行可能永不被客户端施加的准入，且 `monetization.md` 的伪码继续与它自己的定案相抵（缺陷仍在，只是不由本批修）。
    (b) **保留该行，并顺手把 `monetization.md` 62–69 的伪码改为「`Elements` 不含 `BundleGrantOrdinal`，序号由 pull 带回」** ⇒ 消掉既有不一致；但这触及 monetization / sync 专场的承重表述，且**跨库**（后端 `contracts/purchase.md` 是验票写入的权威），超出本草稿范围。
    (c) **从 `ResourceElements` 撤下 `BundleGrantOrdinal` 行** ⇒ 与 `profile-service.md` 68 行、92 行的既定表行直接冲突，且该值仍需在客户端被读取与校验。**不推荐。**
  - **推荐：(a) + 把不一致登记为一条新的 open question**（落 `open-questions/05-service-contracts.md` 或 monetization 所属分片），交 monetization / sync 专场处理。理由：本批五份草稿的范围是 element 载体形态，不是购买段权威划分；而 (c) 会把一处文档不一致升级为一处类型层缺口。

### 🔵 可推演（不进 interview）

- `ApplyOp.Add` 必须是零值、`ApplyOps.Add = 1`（`[Flags]`）⇒ `default(ChangeElement).Op == Add`（与「缺省 Add」自洽）、`default(ElementSpec).AllowedOps == 0`（空集，恰好被草稿的第 1 条启动期断言捕获）。依据：草稿给出的枚举写法 + `architecture.md` 「`readonly record struct` 零分配」纪律。
- `Op == AddLooseCard 且 Tier != -1` **无需新增失败语义行** —— `profile-service.md` 56 行既有行「`Op ∈ { LearnTechnique, UpgradeTechnique }` 且 `Tier < 1`，或**其余 `Op`** 且 `Tier != -1`」自动覆盖新成员。
- `AddLooseCard` 的 `Id` 悬空同样**复用** `profile-service.md` 55 行既有行，不新增。
- `Set` 落到 `Min` 的终态判定不需改写 —— `profile-service.md` 117 行的判据「该字段 == 对应 `ElementSpec.Min` 且 `DepletionDefeat != null`」只读 `Snapshot.Status`，与施加方式无关；且两个终态 key（`LifeSpan` / `LifeTotal`）的 `AllowedOps` 均为 `Add`，`Set` 在它们上不可达。
- `AddLooseCard` **不进 Research 的槽内操作清单** —— `systems/adventure-event/research/_index.md` 38 行已定「加一张游离散牌不作为 Research 的正向操作」。本次只加 `Op`，不动 Research 的四类槽。
- `DeckElements` / `PlotElements` 在 `SelectCost` 内恒空是**两条独立不变式、两行独立断言**，不合并成通则（`profile-service.md` 50 / 57 行已是逐列独立成行的先例，且用户本轮明确「成本侧恒空断言逐列独立写」）。
- 写严读宽不冲突：施加侧 `ArcId` 悬空 `PushError` + 整批拒绝，与 `plot-manager.md` 339–345 行读档侧「`PushWarning` + 该条惰性 + 保留条目」并存；先例是 `(Kind, Scope, Source)` 合法子集表的同款不对称（`profile-service.md` 49 行）。
- `PastEventEntry.AppliedChange` 不新增字段 —— 它随 `ProfileChangeSpec` 自动获得剧本推进与散牌入组的账（`profile-service.md` 80 行同款处置）。

### ✅ 用户已在评审中定下（照定案处理，不进 interview）

- **1 取 A** → `ChangeElement(CostKey, int, ApplyOp)` + `ElementSpec` 增第六列 `ApplyOps AllowedOps`；三条连带规则全采纳；明写 `Set` 不参与 `CanAfford`；张力 1 的区分成立（`AllowedOps` 把纪律留在表里 ⇒ 单一施加点纪律未松动）。
  - 连带代价（如实记，不进 interview）：第 2 条断言把「允许 `Set`」与「两个修正列必须为 `null`」**焊在同一个 key 上** ⇒ 结构上排除「同一 key 既走修正的 `Add`、又有不走修正的 `Set`」这一形态。首批与待登记 key 全部零摩擦。
- **2 取 A** `[采纳推荐 — 待复核]` → `ApplyOp` 现在就落结构，逐行取值随 `CostKey` 成员登记补齐。
- **3 取 A** → 定名 `AddLooseCard`；多张 = 多条 element、不设 count；明写「目标已在卡组 → 正常追加一张」；新增 `Pool == Enemy` 一道闸。
- **4 取 A** `[采纳推荐 — 待复核]` → 列名 `PlotElements`、类型 `PlotKeyPointAssignment`。
- **5 取 A** `[采纳推荐 — 待复核]` → `ProfileManager` 只校验 `Id` 可解析 / 不串线 / 同批不重复；拓扑「单步推进」走 PlotManager 的 `#if DEBUG` 断言。
- **跨分片连带（用户本轮同批裁定）：** `ProfileChangeSpec` 本轮共增**两列**（`PlotElements` + S3 的 `EventStateChanges`），与 `ChangeElement` 增第三字段、`ElementSpec` 增第六列**一次落笔**；`Experience` / `Faith` / `MaleficQi` 本批登记为 `CostKey` 成员，三者 `AllowedOps` 取 `Add`（本草稿「届时建议 `Add`」此刻生效）；五份草稿的 schema bump 合并为同一次。

## 3. 拟改动文档清单（供跨草稿核对）

> **落笔后的最终形状（供交叉核对，逐条为准）：**
>
> ```csharp
> // ProfileChangeSpec 最终 7 列（本批增 2 列；顺序 = 既有 5 列 + PlotElements + EventStateChanges）
> IReadOnlyList<ChangeElement>          Elements
> IReadOnlyList<AbilityChangeElement>   AbilityElements
> IReadOnlyList<StatDelta>              Stats
> IReadOnlyList<StatusAssignment>       StatusChanges
> IReadOnlyList<DeckChangeElement>      DeckElements
> IReadOnlyList<PlotKeyPointAssignment> PlotElements          // ← 本分片 D
> ⟨S3 定形⟩                              EventStateChanges     // ← 分片 S3，非本分片写
>
> public readonly record struct ChangeElement(CostKey Key, int BaseValue, ApplyOp Op);   // Op 缺省 Add
> public enum ApplyOp  { Add, Set }                       // Add 必须为 0
> [Flags] public enum ApplyOps { Add = 1, Set = 2 }
>
> internal readonly record struct ElementSpec(            // 6 列（原 5 + AllowedOps）
>     int Min, int? Max, DefeatReason? DepletionDefeat,
>     ModifierKey? CostModifier, ModifierKey? GainModifier, ApplyOps AllowedOps);
>
> public enum DeckChangeOp { LearnTechnique, UpgradeTechnique, ForgetTechnique,
>                            AddLooseCard, RemoveLooseCard };   // 5 值，AddLooseCard 插在 Remove 前
>
> public readonly record struct PlotKeyPointAssignment(
>     string ArcId, string NodeId, PlotArcState State,
>     int EnteredAtChapter, int EnteredAtSeq);
>
> public enum PlotArcState { Queued, Active, Completed, Abandoned }   // 🟠②：待裁定是否登记于此
> ```
>
> **`ResourceElements` 第六列 `AllowedOps` 的逐行取值（本批后的完整口径）：**
> `LifeSpan → Add` · `Jade → Add` · `LifeTotal → Add` · `ManaLimit → Add`（硬要求，`Set` 恒不开）·
> `PowerFragmentAccumulated → Add | Set` · `PowerFragmentWinOrdinal → Add` · `PowerFragmentFirstWin(chapter) → Set`（形态未定）· `BundleGrantOrdinal → Set`（见 🟠③）·
> **本批新登记：`Experience → Add` · `Faith → Add` · `MaleficQi → Add`**（三行的其余五列归 S1，见 §6）。

| 文档 | 拟新增 / 修改的要点 |
|---|---|
| `systems/architecture.md`「共享核心类型」 | ① `ChangeElement` 增第三字段 `ApplyOp Op`（注释：`缺省 Add；Set 时 BaseValue = 已算好的绝对值`）；新增 `public enum ApplyOp { Add, Set }` |
| 同上 | ② `ElementSpec` 增第六列 `ApplyOps AllowedOps`；新增 `[Flags] public enum ApplyOps { Add = 1, Set = 2 }`；四行注释补第六格（`LifeSpan/Jade/LifeTotal/ManaLimit → Add`，`ManaLimit` 后加「`Set` 恒不开」） |
| 同上 | ③ `DeckChangeOp` 枚举由 4 值改 5 值，新增成员名 **`AddLooseCard`**（插在 `RemoveLooseCard` 之前）；`DeckChangeElement.Id` 注释由「卡牌 `Id`（`RemoveLooseCard`）」改为「卡牌 `Id`（`AddLooseCard` / `RemoveLooseCard`）」 |
| 同上 | ④ `ProfileChangeSpec` 增列 `public IReadOnlyList<PlotKeyPointAssignment> PlotElements { get; }`（注释：`剧本：按 ArcId 的带载荷 upsert`）；新增 `public readonly record struct PlotKeyPointAssignment(string ArcId, string NodeId, PlotArcState State, int EnteredAtChapter, int EnteredAtSeq)` |
| 同上 | ⑤ 391 行「为什么逐条按施加语义分列」段的**各列语义列举**补一句：`剧本是按 ArcId 的带载荷键值 upsert（整条替换、无量纲、恒不走 modifier pipeline）` |
| 同上 | ⑥ 新增一段承重正文 +「六面核对」判据卡（🟠① 待裁定）：**判据原话** ——「**一个新的施加语义该落在哪里，自上而下问三问：① 新增一个列表（分列）⟺ 施加语义与既有各列根本不同，可机械核对的六个面：要不要钳制 · 是否走 modifier pipeline · 失败是否阻断整批 · 是否幂等 · 有无量纲 · 键与载荷的形状（标量 / 集合成员 / 多重集成员 / 带载荷的键值 upsert）；任一列在这六面上与新语义全部对齐 ⇒ 不分列。② 同列内新增一个 `Op` ⟺ 语义同族（共用同一张配表、同一条校验链、同一套钳制与失败语义）但动作的方向或形式不同。③ 在配表里新增一列 ⟺ 该性质是 element 类型的属性：同一个 key 的每一次变更都取同一个值。反判据：同一个 key 的不同次变更可能取不同值 ⇒ 必须逐条带在 element 上；唯一恒成立的例外是「谁有权改写它」永远是类型属性、永远配表——逐条带会把一条纪律降级为调用方选项。**」 |
| 同上 | ⑦ 枚举清单新增 `public enum PlotArcState { Queued, Active, Completed, Abandoned }`（🟠② 待裁定） |
| 同上 | ⑧ 待决问题区不新增；`Source:` 行按小节唯一性追加本次 handoff（不逐条挂） |
| `systems/services/profile-service.md` | ⑨ `ResourceElements` 表**增第六列 `AllowedOps`**（列名原话：`AllowedOps`），八行各填值（见上方口径）；表下新增三条 bullet：`Set 恒不经 modifier pipeline`（理由：`BaseValue` 在 `Set` 下是绝对值、符号不表达方向，「按符号分向」无从判断取哪个修正列；且让一条法则改写已算定的权威值 = 内容改写权威值）· `含 Set 的行两个修正列恒为 null → 启动期断言`（与「表覆盖 `CostKey` 全部成员」同档）· `AllowedOps != 0 → 启动期断言` |
| 同上 | ⑩ 104–113 行**施加顺序伪码改写**：在 `spec = ResourceElements[e.Key]` 之后插 `if (e.Op & spec.AllowedOps) == 0 → PushError + 整批拒绝`；再按 `e.Op == Set` 分支（`落值 = Clamp(e.BaseValue, spec.Min, spec.Max)`，不读当前值、不经 pipeline）/ `else` 走既有分向 + `当前值 + eff` 路径 |
| 同上 | ⑪ 「`CanAfford` 与 `TryApply` 共用 `Evaluate(spec)`」处新增一句：**`Set` 不参与可负担性——它不是消耗，`CanAfford` 只看 `Op == Add` 且 `BaseValue < 0` 的那些** |
| 同上 | ⑫ 施加失败语义表**新增行**（逐行原话）：`Op 不在该 Key 的 AllowedOps 内 → 必需缺失（代码组装缺陷）→ PushError + 整批拒绝` · `AddLooseCard 的目标卡 Pool == Enemy → 必需缺失 → PushError + 整批拒绝` · `PlotElements 出现在 SelectCost 内 → 必需缺失 → PushError + 整批拒绝（不变式，与 AbilityElements / DeckElements 同款、独立成行）` · `PlotKeyPointAssignment.ArcId 解析不到 PlotArcData → 必需缺失 → PushError + 整批拒绝` · `NodeId 解析不到，或其 ArcId 与本条不一致（串线）→ 必需缺失 → PushError + 整批拒绝` · `State 越界 → 必需缺失 → PushError + 整批拒绝` · `同一批 PlotElements 内出现两条同 ArcId → 必需缺失（组装缺陷）→ PushError + 整批拒绝` · `EnteredAtChapter < 1 或 EnteredAtSeq < 0 → 必需缺失 → PushError + 整批拒绝`（**共 8 行**） |
| 同上 | ⑬ 「`AddLooseCard` 的目标已在卡组」**不进失败表**，改为写在卡组小节的正文一句：**正常追加一张，不是失败也不是空操作**（散牌是多重集；套用 `LearnTechnique` 那一行会静默吞掉第二张） |
| 同上 | ⑭ 75 行「四个 `Op`」改「**五个 `Op`**」并补 `AddLooseCard`；77 行 `RemoveLooseCard 只移除一张` 扩写为增减两向对称（`AddLooseCard` 一条 element 加一张、不设 count） |
| 同上 | ⑮ 新增一小节「剧本推进经 `PlotElements` 写入，语义是按 `ArcId` 的整条 upsert」：`ProfileManager` 不认识剧本图、不做推进逻辑；恒不经 pipeline（理由与 `StatusChanges` 同源：法则若能改写剧本进度 = 内容改写玩家在剧情里的位置）；`SelectCost` 内恒空 |
| 同上 | ⑯ 可追溯性日志新增一行（原话）：`[ProfileManager-TryApply] plot arc=<ArcId> node=<NodeId> state=<State>` |
| 同上 | ⑰ 37 行 `ProfileChangeSpec` 各列语义列举补 `PlotElements`（**与 S3 的 `EventStateChanges` 同处，须一次写全**） |
| 同上 | ⑱ 待决问题区**删除**「游离散牌入组的 element 载体未定」一条；「道心 `Faith` / 煞气 `MaleficQi` 是否列入 `CostKey`」一条随本批裁定删除（**归属见 §6**） |
| `systems/character-profile/deck/_index.md` | ⑲ 22 行「四个 `Op`」→「**五个 `Op`**」，补 `AddLooseCard`（游离散牌入组，**一条 element 加一张**）；25 行「游离散牌入组当前没有 element 载体（缺口）」**整段改写**为 `AddLooseCard` 的形态与三条通道（事件负向奖励塞业障 / 战斗奖励单卡入组 / 商店 `Card` 族购买），并写下代价：**卡组条目无 `Source`，「这张业障是哪个事件塞的」只能从 `PastEventEntry.AppliedChange` 逆查** |
| 同上 | ⑳ 待决问题区**删除**「游离散牌入组的 element 载体未定（承重）」一条 |
| `systems/adventure-event/exchange/common-properties.md` | ㉑ 商品族表 `Card` 行「购买产出的 element」格由 `⟨待定…⟩` 填为：**`DeckChangeElement(AddLooseCard, cardId, Tier = -1)`**；并注一句一笔 `Card` 族交易的 spec = `ChangeElement(Jade, -ListPrice, Add)` + 该条 |
| 同上 | ㉒ 待决问题区**删除**「`Card` 族购买的入组 element 载体未定」一条 |
| `systems/adventure-event/exchange/_index.md` | ㉓ 19 行「一笔交易的 spec 形状」补 `Card` 族一支（走 `DeckElements` 的 `AddLooseCard`）；`ChangeElement(Jade, -ListPrice)` 补第三参 `Add`；待决问题区**删除**「`Card` 族商品的入组载体」一条 |
| `systems/services/plot-manager.md` | ㉔ 347–350 行「推进时点 = 已有的 `eventEnd`，单步推进」补出载体：**`ProfileChangeSpec.PlotElements` 的 `PlotKeyPointAssignment`，语义是按 `ArcId` 的整条 upsert（已算好的绝对状态）**；`ChooseBranch` 组装出的同样是一条 `PlotKeyPointAssignment` |
| 同上 | ㉕ 新增一句：「单步推进」的拓扑校验（新 `NodeId` 必须是当前节点的一条出边或等于当前节点）由 **PlotManager 在推进时 `#if DEBUG` 断言**，`ProfileManager` 不持有剧本图拓扑知识（纪律阶梯第 3 级） |
| `systems/character-profile/_index.md` | ㉖ 101 行「写入并入 `eventEnd` 那一次 `TryApply`」补出载体：**`ProfileChangeSpec.PlotElements`，条目类型 `PlotKeyPointAssignment`（`PlotKeyPoint` 的镜像）**；88–92 行 `PlotKeyPoint` record 处按 🟠② 的裁定改为回链 `PlotArcState` 的声明处 |
| `terminology.md`（根级） | ㉗ **25 行「档案变更规格 `ProfileChangeSpec`」条目的列举已经过期**（只列到 `StatusChanges`，缺 `DeckElements`）。本批须补齐为**七列**并补 `ChangeElement` 的第三字段 —— ⚠ **本文件同批可能被 S1 / S3 触碰，须由 orchestrator 指定单写者** |
| 存档 | ㉘ bump schema 版本一次（`AppliedChange` 形状随 `ProfileChangeSpec` 变）；当前无线上存档 ⇒ 空迁移，走既有 MigrationManager 骨架。**本批五份草稿合并为同一次 bump**（用户已裁定） |
| handoff | ㉙ 新建 `handoffs/2026-08-17-element-carrier-gaps.md`（`status: distilled`，`distilled-to` 指向上列文档）；**`handoffs/_index.md` 台账行由 orchestrator 代笔** |

## 4. 拟移出的 open-questions 条目

- `open-questions/05-service-contracts.md`：**`ResourceElements` 是否增一列 `ApplyOp { Add, Set }`（08-17 新增 · 轻）** → 答定为：**不是「表里逐行配一个单值」，而是 `Op` 逐条带在 `ChangeElement` 上 + 表里增一列 `AllowedOps`（`[Flags]`）** —— 原建议形态被推翻，理由是 `PowerFragmentAccumulated` 同一 key 上真的需要两种。归档去向 `systems/architecture.md` + `systems/services/profile-service.md`。
- `open-questions/05-service-contracts.md`：**游离散牌入组的 element 载体（08-17d 新增 · 承重）** → 答定为：**`DeckChangeOp` 增第五值 `AddLooseCard`**（`Id` = 卡牌 `Id`、`Tier = -1`、零字段增量、不设 count、目标已在卡组则正常追加、新增 `Pool == Enemy` 闸）。归档去向 `deck/_index.md` + `profile-service.md` + `exchange/*`。
- `open-questions/05-service-contracts.md`：**`plotKeyPoint` 的 element 形态（08-17 新增）** → 答定为：**`ProfileChangeSpec` 第六列 `PlotElements`，条目类型 `PlotKeyPointAssignment`**（`PlotKeyPoint` 镜像、按 `ArcId` upsert、零 `Op`、恒不经 pipeline、`SelectCost` 内恒空、五行写严的施加侧失败语义）。归档去向 `architecture.md` + `profile-service.md` + `plot-manager.md` + `character-profile/_index.md`。
- `open-questions/05-service-contracts.md`：**道心 `Faith` / 煞气 `MaleficQi` 是否列入 `CostKey`（08-16e 新增 · 轻）** → 由本批跨分片连带答定：**列入，两行 `AllowedOps = Add`**。⚠ **归属存疑** —— 触发方是 S1 的发现，本草稿只给了「届时建议 `Add`」。**建议由 orchestrator 判给 S1 或本分片其一，勿两处都移。**
- 主题文档内的同题待决条目（随上述一并删除）：`profile-service.md` 待决区 1 条 · `deck/_index.md` 待决区 1 条 · `exchange/common-properties.md` 待决区 1 条 · `exchange/_index.md` 待决区 1 条。

> 对应的 answer log 文件名按技能第 8b 步取 `answer-logs/log-element-carrier-gaps.md`（输入是 `inbox/solution-draft-element-carrier-gaps.md` ⇒ slug 照抄）。**由 orchestrator 建，本 worker 不写。**

## 5. 拟新增的 open-questions 条目

- `open-questions/05-service-contracts.md`：**`monetization.md` 内部相抵——`BundleGrantOrdinal` 究竟由谁施加。** 62–69 行的伪码由客户端组装 `Elements: [BundleGrantOrdinal := ordinal]` 并 `TryApply`，而 79–85 行（购买段定案）写「只能由后端 +1、客户端 pull 到新序号后只做兑现」。它决定 `ResourceElements` 里 `BundleGrantOrdinal` 那一行的 `AllowedOps = Set` 是否存在客户端施加路径。**归 monetization / sync 专场；可能跨库**（后端 `contracts/purchase.md` 是验票写入的权威）。→ `systems/monetization.md`、`systems/services/sync-service.md`。（**仅当 🟠③ 裁为 (a) 时新增**）
- `open-questions/05-service-contracts.md`：**`PowerFragmentFirstWin(chapter)` 的参数化 `CostKey` 形态**（既有前置依赖，草稿未答；它那一行的 `AllowedOps = Set` 是形态定后才能落的一格）—— **若该条已在别处登记则不重复新增**，请 orchestrator 与 S1 的 `CostKey` 成员清单一并核对。

## 6. 越界发现（不处理，仅记录）

1. **`terminology.md` 25 行的 `ProfileChangeSpec` 列举已过期**（缺 `DeckElements`，是 08-17b 落 `DeckElements` 时漏改的既有漂移）。本批要把它补到七列，但**该文件同批极可能被 S1（Profile 字段 schema）与 S3 一并触碰** ⇒ 请 orchestrator 指定单写者，或整体收在收尾统一写。
2. **`ResourceElements` 新增三行（`Experience` / `Faith` / `MaleficQi`）的归属分裂：** 本分片只对这三行的**第六列 `AllowedOps` = `Add`** 有结论；其余五列（`Min` / `Max` / `DepletionDefeat` / 两个修正列）来自 S1 的字段 schema 发现。**两个 worker 不得各写一半同一张表**——建议整张表（含新增行与新增列）由**一个** worker 一次写完，另一方在报告里交出待填格。
3. **`profile-service.md` 与 `architecture.md` 是本分片与 S1 / S3 的共同写入面**（`ProfileChangeSpec` 两列同批、`ChangeElement` 第三字段、`ElementSpec` 第六列在同一段代码块内）。用户已裁定「必须一次落笔」⇒ 这两份文件**必须由单一 worker 串行写**，不可并行分派。
4. **`monetization.md` 的内部不一致**（见 🟠③）属 monetization / sync 专场，本分片不动；它另有一条跨库尾巴——后端 `contracts/purchase.md` 承载验票写入的权威，若日后裁为「客户端不写该 key」，后端库需一条对称的承接项。**本次不写后端库。**
5. **`systems/adventure-event/research/common-properties.md` 41 行**的槽内操作枚举注释里含 `RemoveLooseCard`。本次新增 `AddLooseCard` **不应**加进 Research 槽（`research/_index.md` 38 行已明确排除），但若 orchestrator 有分片正在改 Research，请确认它不会顺手把新成员加进那份清单。
6. **战斗奖励的单卡入组**这条通道在 `systems/adventure-event/combat/` 与 `systems/scoring.md` 侧**没有留下 `⟨待定⟩` 占位**（只在 `deck/_index.md` / `exchange/*` 两处登记为缺口）。本次填格只覆盖已登记的两处；若有分片正在写战后奖励，可顺带把 `AddLooseCard` 作为其载体点名。
