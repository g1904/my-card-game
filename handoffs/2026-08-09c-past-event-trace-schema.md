# `pastEvent` 痕迹 schema —— 判据先于字段表，未选项归档轻摘要

- id: 2026-08-09c-past-event-trace-schema
- date: 2026-08-09
- topic: systems/adventure-event/common-properties, systems/services/future-event-service, systems/services/sync-service, systems/services/plot-manager, systems/character-profile, systems/architecture, terminology
- status: distilled
- distilled-to: systems/adventure-event/common-properties.md, systems/services/（future-event-service.md, sync-service.md, plot-manager.md）, systems/character-profile/_index.md, systems/architecture.md, terminology.md, open-questions/（02-event-options.md, update-log.md）, open-questions.md, answer-logs/log-past-event-trace-schema.md

## Intent（distilled）

**一句话：** `pastEvent` 的痕迹条目定形为 **`PastEventEntry`**——**「重算不出来的存、重算得出来的不存」是判据，字段表只是它当下的投影**；未被选中的选项**归档轻摘要**（只求可回溯，不求可重建）；与 AdventurePlot key points **零结构耦合、单向只读**；单事件增量 ~770 B，**落在既有 ~2 KB 预算内 ⇒ push 粒度不变**。连带答结「风味文案不物化，跟随模板数据」——`EventOption` 完整物化字段清单的**文本那一半**就此收口。

### 0 · 这四个子问题必须一起答

- **快照存哪些字段** 决定单条体积；
- **未选项是否归档** 决定条数乘数；
- **与 key points 的耦合方式** 决定有没有第五个字段族；
- **体积对增量 push 粒度的影响** 是前三者的预算校验。

它卡住的下游是三条：`CharacterProfile` 的存档 schema 定不下来 → sync-service 的 `CharacterProfile` 粒度 diff 无法核算预算 → PlotManager「读选择偏好」这条既定意图没有确定的数据面。本次一并解开。

### 1 · 判据 —— 「重算不出来的存，重算得出来的不存」

> **凡「模板 + `EventId` 在任意 `contentVersion` 下都能稳定重建」的，不进快照；凡「由本次物化的情境 / seeded RNG / 当时角色状态决定，重建不出同一结果」的，必进快照。**

**这条判据本身要写进设计文档，而不只是写一张字段表**——字段表会随「`EventOption` 完整物化字段清单」继续增长，判据不会。由它自动落定四条：

- **静态展示文案（显示名 / 描述 / 图标）不进快照。** 按 `EventId` 经 `ContentRegistry.Get()` 随时取得（读取侧不过滤 `ContentEnabled`，故被关闭的条目照常解析）。**文案改版不触发存档迁移**这条既有收益因此保住。
- **风味文案同样不进快照。** 它跟随模板数据，与显示名 / 描述属同一层。**这使判据两侧再无灰色地带：所有文本类字段一律留在模板侧，快照里一个字符串正文都不存。**
- **模板上的基准数值、参数空间、outcome / effect 定义不进快照。** 本次掷定的结果已经在 `AppliedChange` 里；存权重表等于存一份用不上的中间态。
- **物化产出的数值必进快照。** `SelectCost`（取负后的定稿 spec）、`Priority`、Mystery 真身、敌人赋级——正是「重算不保证同结果」的那一半。

**顺带解掉一处被误认的张力。** 「定稿实例必须落存档」与「存档态只带 `Id` + 可变状态、不复制展示文本」看似互斥，实则**管的不是同一类字段**：后者管**展示文本**，前者管**物化数值**，快照存后者不存前者，两条同时成立。唯一可能让它们正面相撞的条件是「风味文案也物化」——而文案不物化，该条件不成立。**这句解释要写出来**，否则日后会有人以为二者冲突而去松动其中一条。

### 2 · 痕迹条目 = 定稿实例快照 + 本次结算的最终账

**痕迹条目不等于 `EventOption`。** 一个事件的权威事实是 `eventEnd` 那**一次**合并 `TryApply` 的 spec，而不是分散在 `ResolveOutcome` / `lifeSpanCost` / 隐藏属性推拉里的若干片段。**存最终 spec 一份，胜过存若干片段再让读取方自己合。**

```csharp
public sealed record PastEventEntry(          // 痕迹条目：immutable，只追加，落存档
    int                Seq,                   // 角色内单调递增的时序坐标；不复用、不因迁移重排
    string             InstanceId,            // 定位键；与被结算的那个 EventOption 同值
    string             EventId,               // 溯源模板（读取侧不过滤 ContentEnabled，disabled 条目照常解析）
    EventType          EventType,             // 当时呈现给玩家的类型；Mystery 时 = 遮罩类型
    string             RevealedEventId,       // Mystery 真身；非 Mystery 为空串
    int                Priority,              // 当时的物化置位 { 0, 1 }；用于回溯「这一步是不是被闸门收窄的」
    string             BatchId,               // 归属批次；与下面的未选项摘要同批
    string             LocationId,            // 当时所在地域（location 是物化输入，且 Travel 缝合要它）
    ProfileChangeSpec  SelectCost,            // 物化组装的定稿 spec（带符号，已取负）
    ProfileChangeSpec  AppliedChange,         // eventEnd 那一次合并 TryApply 的最终 spec
    EventOutcome       Outcome,               // 结算走向，见下
    int                LifeSpanAfter,         // 结算后剩余寿元 —— 判据的明示例外
    IReadOnlyList<UnchosenOptionRef> Unchosen // 同批未被选中的选项轻摘要
    /* ⟨随「EventOption 完整物化字段清单」与「敌人实例类型形态」两项答定后扩充；
        文本类字段不在扩充范围内 —— 风味文案跟随模板⟩ */);

public sealed record UnchosenOptionRef(       // 未选项：只求可回溯，不求可重建
    string    InstanceId,
    string    EventId,
    EventType EventType,
    int       Priority);

public enum EventOutcome { Resolved, CombatWon, CombatLost, Aborted }
// Resolved               = 非战斗类事件正常结算
// CombatWon / CombatLost = 战斗类事件的胜负（剧本与履历都要读，且不可由 AppliedChange 可靠反推）
// Aborted                = 支付 SelectCost 后终态判定 ① 即短路，事件未进入 resolver
```

三点承重说明：

- **`AppliedChange` 是这条 schema 的核心，也是唯一真正新增的东西。** 有了它，「这个角色一路上到底发生了什么」是一条可直接重放的账；没有它，履历 / 剧本 / 诊断三个消费方各自去猜。它**复用既有的 `ProfileChangeSpec`，不引入新类型**。
- **`Seq` 显式序号，不依赖数组下标。** 「绝不用数组索引作内容的键」约束的是**内容键**；`Seq` 不是内容键，是**时序坐标**——但显式写出来才能在日志、履历展示、诊断中安全提及。角色内单调递增、不复用、不因迁移重排。
- **`LifeSpanAfter` 是判据的明示例外。** 它可由 `AppliedChange` 全序列重放得出，按判据本不该存；但它**已经在 `EventResolved` 负载里**（`LifeSpanRemaining`），且元进程的角色履历要画寿元曲线。**收下它，成本 4 字节 × 200 条 = 800 字节，换掉一次全序列重放。** 文档中**必须写明它是明示例外**——例外写明了就不会被当成疏漏，也不会被当成先例滥用。

**`Aborted` 是跳过通道移除后的直接产物。** 支付 `selectCost` 后立即判负会短路、事件不再结算，但**这一步仍然发生过**（成本已施加、`selectCost` 不回滚）。它必须留痕，且必须与正常结算可区分——否则履历上会出现一条「结算了但什么也没产出」的诡异记录。这条痕迹通常是角色的**最后一条**。

**枚举保持四值，不为 DnD 式选分支预留成员。** 分支选择的触发点与形态本身仍未定；若日后需要，它是**新增一个可空字段**（`ChosenBranchId`），不是改枚举——**枚举成员的增删牵动存档迁移，可空字段不牵动**。

### 3 · 未被选中的选项 —— 归档轻摘要

先摆出论证基础：**「定稿实例必须落存档」这条对未选项不成立。** 该条的理由是「重算不保证同结果，而这份实例还要被消费」；而未选项在下一次整批重算时即被丢弃，**永远不会被任何流程消费**。它们不需要**可重建**——只需要**可回溯**。

「可消费」要完整快照，「可回溯」只要够剧本读出偏好。剧本要的信号是「玩家回避了什么类型 / 什么内容」，`EventType` + `EventId` 就足够；未选项的 `SelectCost` 永不会被施加，敌人实例永不会入场。

| | 方案 | 单事件增量 | 剧本可读出 | 结论 |
|---|------|-----------|-----------|------|
| A | 不归档 | 0 | 只有「选了什么」 | 否决：跳过通道移除时丢掉的那条信号**永久丢掉**，日后想补要改 schema + 迁移 |
| **B** | **归档轻摘要**（`InstanceId` / `EventId` / `EventType` / `Priority`） | **~4 × 60 B ≈ 240 B** | 「选了什么」+「同批还摆着什么而没选」 | **采纳** |
| C | 归档完整快照 | ~4 × 500 B ≈ 2 KB | 同 B（多出的字段无消费方） | 否决：体积翻数倍换零新增信息 |

**采纳 B。** 它拿回了跳过通道移除时被明确点名放弃的那条信号，成本是 A 的一个小常数倍；C 多出来的字节**没有任何已知消费方**——多存的正是上面推演中「永不被消费」的那些。

**B 的副产品：批次的完整性得以保留。** `pastEvent` 不再是一串孤立事件，而是一串**批次**——「这一步你面前摆着这四个，你选了第二个」。这对元进程的角色履历展示、以及日后做「回放 / 复盘」都是免费的地基。

**连带修订：** 「跳过什么类型的事件反向影响剧本这条内容侧方向作废」需要收窄——**回避信号以「同批未选」的形式回来了**，只是它不再是一个独立的玩家操作，而是选择的补集。

### 4 · 与 AdventurePlot key points —— 单向读取，零结构耦合

**`pastEvent` 不持有任何 key point 引用；key points 也不引用 `PastEventEntry`。PlotManager 只把 `pastEvent` 当作只读输入。**

- **边界依据。** key points 是剧本服务的进度锚点，剧本内容在云端、不落存档。把 `InstanceId` / `Seq` 塞进 key point，等于让**云端剧本服务隐式依赖客户端存档的 `InstanceId` 空间**——那是客户端物化时随手生成的标识，一旦形态变动就成为一处跨进程的破坏性改动。协议契约要窄，这条不该穿过去。
- **不需要新链路。** `ModulateEventOptions(CharacterProfile c, EventOptionBatch batch)` 已经拿到整个 `CharacterProfile`，`pastEvent` 就在其中。读偏好是一次**服务内 manager 对宿主数据的只读访问**，不跨任何边界，也不需要新方法。
- **派生索引不落存档。** 「每类事件走过几次」这类聚合为**读时计算**（n ≈ 200，一次线性扫描，非每帧热路径）或 PlotManager 内的内存缓存，**不作为存档字段**。存了就有两份真相，迁移与重放时必然对不齐。

**推论：`pastEvent` 的 schema 不受「key points 粒度」这个待答项阻塞，两者可以各自定稿。** 这是本次的一个实际收益——它砍掉了一条依赖边。

### 5 · 体积 vs 增量 push —— 不改粒度，只加一条护栏

| 组成 | 估算 |
|------|------|
| 标识与坐标（`Seq` / `InstanceId` / `EventId` / `BatchId` / `LocationId`） | ~150 B |
| `SelectCost`（1–3 个 `ChangeElement`） | ~80 B |
| `AppliedChange`（3–8 个 `ChangeElement`，含 lifeSpan / 隐藏属性 / spoils） | ~200 B |
| 结算结果与冗余（`Outcome` / `LifeSpanAfter` / 敌人摘要） | ~100 B |
| 未选项轻摘要 × 4 | ~240 B |
| **合计** | **~770 B（JSON 明文）** |

**落在既有粗算的 ~2 KB / 事件预算之内，`pastEvent` 约占其中三分之一**；整轮回 200 事件 ≈ 150 KB。**既有的「按 `CharacterProfile` 做 diff」粒度成立，无需为快照体积新增任何机制。** 这个子问题的答案是「不影响」——但它需要被算一遍才能这么说。

- **不变式：`pastEvent` 只追加，不修改既有条目。** 一次事件只新增一条尾部条目，因此它对 diff 尤其友好：只要 diff 能表达「列表尾部追加」，增量就是这一条本身，与列表已有长度无关。**这条要写成明文**——它是上述估算成立的前提，也让 diff 实现有一条可依赖的性质。
- **护栏：软上限告警。** 单个 `CharacterProfile` 的 `pastEvent` 条数 > 500 或序列化 > 512 KB 时 `GD.PushWarning` 带 `characterId` 与实际值。理由：`PlayerProfile` 是整聚合 pull 的单位（启动时全量一次），失控增长首先伤的是**启动 pull**，而那条路径是硬阻塞的。**告警不改变行为，只让异常在被玩家感知之前先被看到。**
- **明确否决：现阶段不做** `pastEvent` 的分页 / 冷热分离 / 归档到独立存档段。没有证据表明需要，且它会把「云端权威、整聚合 pull」这条重新打开。

### 6 · 存档、校验与写入点

- **schema 版本：** 本次落定 `pastEvent` 结构 → **bump schema 版本**；当前无线上存档 → **空迁移**，走既有的 MigrationManager 骨架。
- **加载时校验：**
  - `EventId` 经 `ContentRegistry` 解析不到 → **可选缺失** → `GD.PushWarning` + 该条降级为「仅标识可读」（履历显示为未知条目），**不阻断读档**——历程是历史记录，一条读不出的旧条目不该让整个角色无法进入。
  - `InstanceId` 缺失 / `Seq` 不连续 / `Seq` 重复 → **必需缺失** → `GD.PushError` 带 `characterId` + `seq`。
- **写入点不新增。** 既有流程里「记入 `pastEvent`（按 `InstanceId`，携带定稿实例快照）」这一步的语义具体化为：**由 life-cycle-service 组装 `PastEventEntry`（含从被替换的当前批取未选项摘要），经 `profile-service.ProfileManager` 写入**——与「档案写入的唯一入口」一致，不绕过。
- **类型修正。** `CharacterProfile` 的修行历程字段当前记为 `List<AdventureEvent>`，**与既定的物化模型不符**（存的是定稿实例快照，不是 `Resource`）→ 改为 `IReadOnlyList<PastEventEntry>`，`terminology.md` 同步。

## 已否决的备选

- **只存 `EventId` + 时间戳，展示时回查模板重算** —— 违反「定稿实例必须落存档」与「不得回查模板重算」两条定稿纪律。
- **`pastEvent` 存整个 `EventOption` 实例** —— 把「实例」与「痕迹」混为一谈。痕迹要的是「发生了什么」（`AppliedChange`），实例只是「摆出来时长什么样」；且实例字段清单仍在增长，绑死会让每次扩字段都牵动存档迁移。
- **在 `pastEvent` 上维护派生索引**（每类计数 / 每 location 计数）—— 两份真相，迁移与重放必然对不齐；n ≈ 200 的读时扫描完全够用。
- **`pastEvent` 分页 / 冷热分离** —— 无证据需要，且会重新打开整聚合 pull 的语义。
- **未选项归档完整快照 / 完全不归档** —— 前者多出的字段无消费方；后者永久放弃回避信号。
- **物化文案存 `variantKey`** —— 它是「风味文案也物化」情形下化解冲突的方案；文案不物化，该冲突不存在，方案随之作废。
- **`EventOutcome` 预留分支选择成员** —— 枚举成员增删牵动存档迁移；分支形态未定时预留即臆造。改用日后新增可空字段。

## Open questions

以下三项**扩充**本 schema，但**不阻塞它定稿**（`PastEventEntry` 上已留显式扩充点）：

- **`EventOption` 的完整物化字段清单**（→ `future-event-service.md`）。新增的物化字段按判据自动分流。**「风味文案是否物化」那一半已答结（不物化）**，故扩充范围**不含任何文本类字段**——剩余分叉只在数值与结构字段上。
- **物化后敌人实例的类型形态**（`EnemyInstance` 嵌在 `EventOption` 上还是只记引用？）。战斗类痕迹需要它。**不阻塞的最小面：至少存 `EnemyTemplateId` + 物化赋级 `Level`**——等级是物化产物、重算不出，且 EnemyCodex 与履历都要读它；体积估算已按这个最小面计入。
- **`CostKey` 的其余 element 与各 element 的数据形态。** 只影响 `SelectCost` / `AppliedChange` 内 element 的**条数**，不影响 schema 形状（`ProfileChangeSpec` 是既定容器）。估算按 1–3 / 3–8 条取值；若 element 族显著变大需重算体积。
- **每批 eventOptions 的数量**（→ 生成 / 加权规则）。未选项摘要的体积乘数直接取决于它；本次按**每批 5 项（未选 4 项）**估算。若每批显著更大（如 8–10 项），轻摘要增量线性上升，但仍远低于完整快照。

## Notes / triage

来源：`inbox/solution-draft-past-event-trace-schema.md`（`/provide-solution-draft` 产出，用户于 2026-08-07 逐项裁决：未选项归档轻摘要 · `EventOutcome` 四值 · 收下 `LifeSpanAfter` 并写明为例外 · 风味文案不物化）。草稿已移入 `inbox/archive/`。
