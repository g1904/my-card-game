---
type: solution-draft
date: 2026-08-07
question: `pastEvent` 的痕迹 schema —— 快照存哪些字段、未被选中的选项是否随批次一并归档、与 AdventurePlot key points 的耦合方式、快照体积对增量 push 粒度的影响
source: open-questions/02-event-options.md → 第 15 条（`pastEvent` 的痕迹 schema）；亦见 systems/adventure-event/common-properties.md#待决问题、systems/services/future-event-service.md#待决问题
targets: systems/adventure-event/common-properties.md、systems/services/future-event-service.md、systems/services/sync-service.md、systems/services/plot-manager.md、systems/character-profile/_index.md、terminology.md、systems/architecture.md（总则 6 的 schema 面）
status: distilled
---

# 方案草稿 — `pastEvent` 的痕迹 schema

> **本草稿的全部取向项已由用户裁决（2026-08-07），无遗留待选项。** 裁决见下方「裁决记录」；正文已按裁决改写为单一方案，备选项只作为否决理由保留。

## 裁决记录（用户 · 2026-08-07）

| # | 项 | 裁决 |
|---|-----|------|
| 1 | 未被选中的选项是否归档 | **归档轻摘要**（③ 方案 B） |
| 2 | `EventOutcome` 粒度 | **四值即可**（`Resolved` / `CombatWon` / `CombatLost` / `Aborted`） |
| 3 | `LifeSpanAfter` 冗余快照字段 | **收**，并在文档中**写明它是判据的明示例外** |
| 4 | 风味文案是否物化 | **不物化 —— 风味文案跟随模板数据** |
| 5 | 其余各项 | 按草稿推荐方案 |

**第 4 项的影响超出本问题，值得单独点出：** 它使 C1 ↔ C2 的那处张力**整体消解**（不再存在「既是展示文本、又重算不出」的字段类），`variantKey` 这个化解方案随之不再需要；同时它**顺带答结了「`EventOption` 完整物化字段清单」里"风味文案是否也物化"那一半**——该结论应在提炼时一并落进 `future-event-service.md` 与 `adventure-event/common-properties.md`。

## 问题

`pastEvent` 是 CharacterProfile 上的一条**扁平时序列表**，记录角色走过哪些事件。持久化**方式**已定案（存**物化后的定稿实例快照**、按 `InstanceId` 索引、不事后重算），08-06c 移除跳过通道后**痕迹只剩一种**（进入并结算），「区分两种痕迹」的 schema 难题已消解。

悬着的是四个子问题，它们必须一起答——第一个决定单条体积，第二个决定条数乘数，第四个是前两个的预算校验，第三个决定有没有第五个字段族：

1. **快照存哪些字段？**「定稿实例快照」是个方向，不是字段表。
2. **未被选中的选项是否随批次快照一并归档？** 归档则剧本能读出「回避了什么」（08-06c 移除跳过后丢失的那条信号），代价是体积成倍增长。
3. **与 AdventurePlot key points 怎么耦合？**
4. **快照体积对增量 push 粒度的影响？**

它卡住的下游：`CharacterProfile` 的存档 schema 定不下来 → sync-service 的 `CharacterProfile` 粒度 diff 无法核算预算 → PlotManager 「读选择偏好」这条既定意图没有确定的数据面。

## 约束（来自既有设计）

| # | 约束 | 来源 |
|---|------|------|
| C1 | **定稿实例必须落存档，不能只存 `EventId` 事后重算。** 物化用了 seeded RNG、当时的角色状态、可被 overlay 热更的模板；确定性只在同一 `contentVersion` 内成立。 | `systems/architecture.md` 总则 6 推论 1；`future-event-service.md`；`common-properties.md` |
| C2 | **运行时 / 存档态只带 `Id` + 可变状态，不复制展示文本**（三层切分第二层）；静态展示文案留在 `XxxData : Resource` 上，组合展示由 UI 层 ViewModel 现场组装、不落存档、不进云端负载。 | `systems/common-properties.md`「展示字段的归属」 |
| C3 | **`InstanceId` 与 `EventId` 并存且不可互相替代**；`pastEvent` 与 `EventResolved` 负载一律按 `InstanceId` 定位。 | 同上 + `terminology.md` |
| C4 | **一个事件 = 一次事务 = 一个存档点。** `eventEnd` 把 `ResolveOutcome` + `lifeSpanCost` + lifeTotal 扣减 + 等级产出 + 隐藏属性推拉合并为**一次** `TryApply`。 | `life-cycle-service.md`、`architecture.md` 总则 8 |
| C5 | **增量 push 粒度 = 按 `CharacterProfile` 做 diff（已定案）**；粗算一次轮回约 **200 事件 × ~2 KB diff ≈ 400 KB**，移动网络可接受。 | `sync-service.md` |
| C6 | **读取侧 `Get(id)` 不过滤 `ContentEnabled`**，故存档引用到被关闭的条目仍能正确解析。 | `systems/common-properties.md` |
| C7 | **绝不用数组索引作为内容的键**；稳定 `Id` 是一切引用的键。 | `.claude/rules/data-resource-rules.md` |
| C8 | **剧本内容不落存档**（存云端剧本服务）；`CharacterProfile` 只存 key points 这类轻量锚点。 | `plot-manager.md` |
| C9 | **存档 schema 带版本 + 迁移路径**；当前无线上存档 → 空迁移，但迁移骨架已立。 | `sync-service.md`、`character-profile/_index.md` |
| C10 | **本批的每一项都是必做项，唯一推进方式是择一进入**；一次选择 → 整批重算。未选项在下一刻即被整批丢弃。 | `handoffs/2026-08-06c-*`、`common-properties.md` |
| C11 | **风味文案不物化，跟随模板数据**（用户裁决 · 08-07）。 | 本草稿裁决记录第 4 项 |

## 方案

### ① 快照字段的判据 —— 「重算不出来的存，重算得出来的不存」

`[既有推演]`

C1 与 C2 表面上互相拉扯（一个说「实例要落档」，一个说「存档态只带 `Id` + 可变状态」），但它们管的不是同一类字段，合起来正好给出一条**可执行的判据**，而不是逐字段拍脑袋：

> **凡「模板 + `EventId` 在任意 `contentVersion` 下都能稳定重建」的，不存；凡「由本次物化的情境 / seeded RNG / 当时角色状态决定，重建不出同一结果」的，必存。**

由此四条自动落定：

- **静态展示文案（显示名 / 描述 / 图标）不进快照。** 它们是模板侧字段，按 `EventId` 经 `ContentRegistry.Get()` 随时取得（C6 保证 disabled 条目也解析得到）。**文案改版不触发存档迁移**这条既有收益因此保住。
- **风味文案同样不进快照（C11）。** 它跟随模板数据，与显示名 / 描述属同一层——**这使判据的两侧再无灰色地带**：所有文本类字段一律留在模板侧，快照里一个字符串正文都不存。
- **模板上的基准数值、参数空间、outcome / effect 定义不进快照。** 本次掷定的结果已经在 `AppliedChange` 里（见下），存权重表等于存了一份用不上的中间态。
- **物化产出的数值必进快照。** `SelectCost`（正量值取负后的定稿 spec）、`Priority`、Mystery 真身、敌人赋级——这些正是「重算不保证同结果」的那一半。

**建议把这条判据本身写进 `common-properties.md` 的意图层**，而不只是写一张字段表：字段表会随「`EventOption` 完整物化字段清单」（另一待答项）继续增长，判据不会。

### ② 痕迹条目形态 —— `PastEventEntry`

`[既有推演]` + `[通行做法]`

痕迹条目**不等于 `EventOption`**：它是「定稿实例快照 + 本次结算的最终账」。理由是 C4——一个事件的权威事实是那**一次**合并 `TryApply` 的 spec，而不是分散在 `ResolveOutcome` / `lifeSpanCost` / 隐藏属性推拉里的若干片段。存最终 spec 一份，胜过存若干片段再让读取方自己合。

字段表见「具体形态」小节。三点承重说明：

- **`AppliedChange` 是这条 schema 的核心，也是唯一真正新增的东西。** 有了它，「这个角色一路上到底发生了什么」是一条可直接重放的账；没有它，履历 / 剧本 / 诊断三个消费方各自去猜。它复用既有的 `ProfileChangeSpec` 类型，**不引入新类型**。
- **`Seq` 显式序号，不依赖数组下标。** C7 禁止用数组索引作**内容的键**；`Seq` 不是内容键，是**时序坐标**——但显式写出来才能在日志、履历展示、诊断中安全提及。序号在角色内单调递增、不复用、不因迁移重排。
- **`LifeSpanAfter` 是判据的明示例外（裁决 3）。** 它可由 `AppliedChange` 全序列重放得出，按 ① 的判据本不该存——但它已经在 `EventResolved` 事件负载里（`LifeSpanRemaining`），且元进程的角色履历要画寿元曲线。**收下它，成本 4 字节 × 200 条 = 800 字节，换掉一次全序列重放。** 提炼时**必须在文档里写明"这是 ① 判据的明示例外"**——例外写明了就不会被当成疏漏，也不会被当成先例滥用。

### ③ 未被选中的选项 —— 归档「轻摘要」（裁决 1）

`[取向选择 · 已裁决]`

先把一条常被忽略的推演摆出来，它是本裁决的论证基础：

> **C1「定稿实例必须落存档」对未选项不成立。** C1 的理由是「重算不保证同结果，而这份实例还要被消费」；而由 C10，**未选项在下一次重算时即被整批丢弃，永远不会被任何流程消费**。它们不需要可重建——只需要**可回溯**。

「可消费」要完整快照，「可回溯」只要够剧本读出偏好。剧本要的信号是「玩家回避了什么**类型 / 什么内容**」，`EventType` + `EventId` 就足够；未选项的 `SelectCost` 永不会被施加，敌人实例永不会入场。

三个曾考虑的方案：

| | 方案 | 单事件增量 | 剧本可读出 | 结论 |
|---|------|-----------|-----------|------|
| A | 不归档（只存被选中的那一条） | 0 | 只有「选了什么」 | 否决：08-06c 丢掉的那条信号**永久丢掉**，日后想补要改 schema + 迁移 |
| **B** | **归档轻摘要**（未选项只存 `InstanceId` / `EventId` / `EventType` / `Priority`） | **~4 × 60 B ≈ 240 B** | 「选了什么」+「同批还摆着什么而没选」 | **采纳** |
| C | 归档完整快照（未选项与被选项同构） | ~4 × 500 B ≈ 2 KB | 同 B（多出的字段无消费方） | 否决：体积翻数倍换零新增信息 |

**采纳 B。** 它拿到了 08-06c 明确点名的那条信号，成本是 A 的一个小常数倍，而 C 多出来的字节**没有任何已知消费方**——多存的部分正好是上面推演中「永不被消费」的那些。

**B 的副产品：批次的完整性得以保留。** 有了未选项摘要，`pastEvent` 不再是一串孤立事件，而是一串**批次**——「这一步你面前摆着这四个，你选了第二个」。这对元进程的角色履历展示、以及日后做「回放 / 复盘」都是免费的地基。

### ④ 与 AdventurePlot key points —— 单向读取，零结构耦合

`[既有推演]`

**`pastEvent` 不持有任何 key point 引用；key points 也不引用 `PastEventEntry`。PlotManager 只把 `pastEvent` 当作只读输入。**

三条依据：

- **C8 划定了边界。** key points 是剧本服务的进度锚点，剧本内容在云端、不落存档。把 `InstanceId` / `Seq` 塞进 key point，等于让**云端剧本服务隐式依赖客户端存档的 `InstanceId` 空间**——那是客户端物化时随手生成的标识，一旦形态变动就变成一处跨进程的破坏性改动。协议契约要窄，这条不该穿过去。
- **不需要新链路。** `PlotManager.ModulateEventOptions(CharacterProfile c, EventOptionBatch batch)` 已经拿到整个 `CharacterProfile`，`pastEvent` 就在其中。读偏好是一次**服务内 manager 对宿主数据的只读访问**，不跨任何边界，也不需要新方法。
- **派生索引不落存档。** 「每类事件走过几次」这类聚合为**读时计算**（n ≈ 200，一次线性扫描，非每帧热路径）或 PlotManager 内的内存缓存，**不作为存档字段**。存了就有两份真相，迁移与重放时必然对不齐——这是通行的派生数据纪律，也与既有的「服务不返回内部可变集合」同向。

**推论：`pastEvent` 的 schema 因此不受「key points 粒度」这个待答项阻塞。** 两者可以各自定稿。这是本方案的一个实际收益——它把一条依赖边直接砍掉了。

### ⑤ 快照体积 vs 增量 push —— 不改 push 粒度，只加一条护栏

`[既有推演]` + `[通行做法]`

按 ② + ③B 估算单事件的 `pastEvent` 增量：

| 组成 | 估算 |
|------|------|
| 标识与坐标（`Seq` / `InstanceId` / `EventId` / `BatchId` / `LocationId`） | ~150 B |
| `SelectCost`（1–3 个 `ChangeElement`） | ~80 B |
| `AppliedChange`（3–8 个 `ChangeElement`，含 lifeSpan / 隐藏属性 / spoils） | ~200 B |
| 结算结果与冗余（`Outcome` / `LifeSpanAfter` / 敌人摘要） | ~100 B |
| 未选项轻摘要 × 4 | ~240 B |
| **合计** | **~770 B（JSON 明文）** |

**结论：落在 C5 既有粗算的 ~2 KB/事件预算之内，`pastEvent` 约占其中三分之一。** 整轮回 200 事件 ≈ 150 KB 的 `pastEvent`。**既有的「按 `CharacterProfile` 做 diff」粒度成立，无需为快照体积新增任何机制。** 这个子问题的答案是「不影响」——但它需要被算一遍才能这么说。

`pastEvent` 是**只追加**结构，一次事件只新增一条尾部条目，因此它对 diff 尤其友好：只要 diff 实现能表达「列表尾部追加」，增量就是这一条本身，与列表已有长度无关。**把「`pastEvent` 只追加、不修改既有条目」写成一条明文不变式**——它是上述估算成立的前提，也让 diff 实现有一条可依赖的性质。

**护栏（通行做法）：** 给单个 `CharacterProfile` 的 `pastEvent` 一个**软上限告警**——条数 > 500 或序列化 > 512 KB 时 `GD.PushWarning` 带 `characterId` 与实际值。理由：`PlayerProfile` 是整聚合 pull 的单位（启动时全量一次），一个失控增长的 `pastEvent` 首先伤的是**启动 pull**，而那条路径是硬阻塞的。告警不改变行为，只让异常在被玩家感知之前先被看到。

**明确否决：** 现阶段**不做** `pastEvent` 的分页 / 冷热分离 / 归档到独立存档段。没有证据表明需要，且它会把「云端权威、整聚合 pull」这条重新打开。

## 具体形态（可 derive 的落地面）

### `PastEventEntry`

```csharp
public sealed record PastEventEntry(          // 痕迹条目：immutable，只追加，落存档
    int                Seq,                   // 角色内单调递增的时序坐标；不复用、不因迁移重排
    string             InstanceId,            // 定位键（C3）；与被结算的那个 EventOption 同值
    string             EventId,               // 溯源模板（C6：disabled 条目照常解析）
    EventType          EventType,             // 当时呈现给玩家的类型；Mystery 时 = 遮罩类型
    string             RevealedEventId,       // Mystery 真身；非 Mystery 为空串
    int                Priority,              // 当时的物化置位 { 0, 1 }；用于回溯「这一步是不是被闸门收窄的」
    string             BatchId,               // 归属批次；与下面的未选项摘要同批
    string             LocationId,            // 当时所在地域（location 是物化输入，且 Travel 缝合要它）
    ProfileChangeSpec  SelectCost,            // 物化组装的定稿 spec（带符号，已取负）
    ProfileChangeSpec  AppliedChange,         // eventEnd 那一次合并 TryApply 的最终 spec（C4）
    EventOutcome       Outcome,               // 结算走向，见下
    int                LifeSpanAfter,         // 结算后剩余寿元 —— ① 判据的明示例外（裁决 3）
    IReadOnlyList<UnchosenOptionRef> Unchosen // 同批未被选中的选项轻摘要（③ 方案 B）
    /* ⟨随「EventOption 完整物化字段清单」与「敌人实例类型形态」两项答定后扩充；
        文本类字段不在扩充范围内 —— 风味文案跟随模板（C11）⟩ */);

public sealed record UnchosenOptionRef(       // 未选项：只求可回溯，不求可重建（③）
    string    InstanceId,
    string    EventId,
    EventType EventType,
    int       Priority);

public enum EventOutcome { Resolved, CombatWon, CombatLost, Aborted }   // 四值定（裁决 2）
// Resolved   = 非战斗类事件正常结算
// CombatWon / CombatLost = 战斗类事件的胜负（剧本与履历都要读，且不可由 AppliedChange 反推得可靠）
// Aborted    = 支付 SelectCost 后终态判定 ① 即短路，事件未进入 resolver（08-06c 的新分支）
```

**`Aborted` 是 08-06c 的直接产物，值得单独说一句：** 支付 `selectCost` 后立即判负会短路、事件不再结算，但**这一步仍然发生过**（成本已施加、`selectCost` 不回滚）。它必须在 `pastEvent` 里留痕，且必须与正常结算可区分——否则履历上会出现一条「结算了但什么也没产出」的诡异记录。这条痕迹通常是角色的**最后一条**。

**枚举保持四值，不为 DnD 式选分支预留成员（裁决 2）。** 分支选择的触发点与形态本身仍未定（见 `plot-manager.md` 待决问题）；若日后需要，它是**新增一个可空字段**（`ChosenBranchId`），不是改枚举——枚举成员的增删牵动存档迁移，可空字段不牵动。

### `CharacterProfile` 侧

```jsonc
"pastEvent": [           // 扁平时序列表，只追加；数组顺序 == Seq 升序
  { "seq": 1, "instanceId": "...", "eventId": "...", /* ... */ }
]
```

- **schema 版本：** 本次落定 `pastEvent` 结构 → **bump schema 版本**；当前无线上存档 → 空迁移，走既有的 MigrationManager 骨架（C9）。
- **加载时校验（`.claude/rules/null-check-rules.md`）：** `EventId` 经 `ContentRegistry` 解析不到 → **可选缺失** → `GD.PushWarning` + 该条降级为「仅标识可读」（履历显示为未知条目），**不阻断读档**——历程是历史记录，一条读不出的旧条目不该让整个角色无法进入。`InstanceId` 缺失 / `Seq` 不连续 / `Seq` 重复 → **必需缺失** → `GD.PushError` 带 `characterId` + `seq`。

### 写入点

不新增写入点。既有流程里 `→ 记入 pastEvent（按 InstanceId，携带定稿实例快照）` 这一步的语义具体化为：**由 life-cycle-service 组装 `PastEventEntry`（含从被替换的当前批取未选项摘要），经 `profile-service.ProfileManager` 写入**——与「档案写入的唯一入口」一致，不绕过。

## 后果

| 影响面 | 内容 |
|--------|------|
| `systems/adventure-event/common-properties.md` | `pastEvent` 条目从一句话描述变为字段表；新增「重算不出来的存」判据条目（含 `LifeSpanAfter` 的明示例外）；待决问题中的该条移出 |
| `systems/services/future-event-service.md` | 「定稿实例快照的存档字段形态未定」一条移出；`ComputeEventOptions` 需明确「被替换的批次交给谁去取未选项摘要」；**并落「风味文案不物化、跟随模板」这条裁决**（收窄「完整物化字段清单」那一项） |
| `systems/services/sync-service.md` | 增「`pastEvent` 只追加」不变式 + 体积护栏 + 单事件增量估算；push 粒度**不变** |
| `systems/services/plot-manager.md` | 明确「PlotManager 只读 `pastEvent`，不与 key points 结构耦合；偏好聚合读时计算」 |
| `systems/character-profile/_index.md` | `List<AdventureEvent>`（修行历程）的类型改为 `IReadOnlyList<PastEventEntry>`——**当前文档写的是 `List<AdventureEvent>`，这个类型与既定的物化模型不符**（存的是定稿实例快照，不是 `Resource`），应一并修正 |
| `terminology.md` | 修行历程 / `pastEvent` 词条的类型标注同上修正 |
| 存档迁移 | **bump schema 版本，空迁移**（无线上存档） |

## 备选方案（已考虑并否决）

- **只存 `EventId` + 时间戳，展示时回查模板重算** —— 直接违反 C1（重算不保证同结果），且违反「不得回查模板重算」的定稿纪律。**否决**。
- **`pastEvent` 存整个 `EventOption` 实例（含未来可能物化的全部字段）** —— 把「实例」与「痕迹」混为一谈。痕迹要的是「发生了什么」（`AppliedChange`），实例只是「摆出来时长什么样」。且实例字段清单仍在增长，绑死会让每次扩字段都牵动存档迁移。**否决**。
- **在 `pastEvent` 上维护派生索引（每类计数、每 location 计数）** —— 两份真相，迁移与重放必然对不齐；n ≈ 200 的读时扫描完全够用。**否决**（见 ④）。
- **`pastEvent` 分页 / 冷热分离** —— 见 ⑤，无证据需要且会重新打开整聚合 pull 的语义。**否决（现阶段）**。
- **未选项归档完整快照（③ 方案 C）** —— 多出的字段无消费方。**否决**。
- **未选项完全不归档（③ 方案 A）** —— 08-06c 丢失的剧本信号将永久放弃，补回需改 schema + 迁移。**否决**。
- **物化文案存 `variantKey`** —— 这是「风味文案也物化」情形下化解 C1 ↔ C2 冲突的方案；裁决 4 判定文案不物化，**该冲突不存在，方案随之作废**。
- **`EventOutcome` 预留分支选择成员** —— 枚举成员增删牵动存档迁移；分支形态未定时预留即臆造。改用日后新增可空字段。**否决**。

## 与既有决策的张力

**无。**

草稿初版曾记一处：C1（定稿实例必须落存档）↔ C2（存档态只带 `Id` + 可变状态，不复制展示文本）。二者本就管的不是同一类字段——C2 管**展示文本**，C1 管**物化数值**，快照存后者不存前者，两条同时成立。唯一可能让它们正面相撞的条件是「风味文案也物化」，而**裁决 4 判定文案不物化、跟随模板（C11），该条件不成立**。

**建议仍把「C1 与 C2 管的不是同一类字段」这句解释写进文档**——它现在只是隐含的，写出来能防止日后有人以为二者冲突而去松动其中一条。

## 前置依赖

以下待答项会**扩充**本 schema，但**不阻塞它定稿**（`PastEventEntry` 上已留显式扩充点）：

- **`EventOption` 的完整物化字段清单**（→ `future-event-service.md`）。新增的物化字段按 ① 的判据自动分流：重算不出的进快照。**该项中"风味文案是否物化"那一半已由裁决 4 答结（不物化）**，故扩充范围**不含任何文本类字段**——剩余的分叉只在数值与结构字段上，风险显著降低。
- **物化后敌人实例的类型形态**（`EnemyInstance`？嵌在 `EventOption` 上还是只记引用？）。战斗类痕迹需要它。**不阻塞的最小面：至少存 `EnemyTemplateId` + 物化赋级 `Level`**——等级是物化产物、重算不出，且 EnemyCodex 与履历都要读它。本草稿的体积估算已按这个最小面计入（~100 B）。
- **`CostKey` 的其余 element 与各 element 的数据形态**。只影响 `SelectCost` / `AppliedChange` 内 element 的**条数**，不影响 schema 形状（`ProfileChangeSpec` 是既定容器）。估算按 1–3 / 3–8 条取值，若 element 族显著变大需重算 ⑤。
- **每批 eventOptions 的数量**（→ 生成 / 加权规则）。③ 的体积乘数直接取决于它；本草稿按**每批 5 项（未选 4 项）**估算。若每批显著更大（如 8–10 项），轻摘要的增量随之线性上升，但仍远低于完整快照。
- **`revision` 的产生方与语义**（→ `sync-service.md` + 后端）。影响 diff 基线怎么比，不影响本 schema。

## 仍需用户决定

**无 —— 本草稿的四个取向项已于 2026-08-07 全部裁决**（见「裁决记录」）。可直接交由 `/analyze-new-ideas` 提炼。
