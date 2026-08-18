# 剧本数据编码：树 = 纯调制 · 两个内容类型 · key points 每 arc 一条

- id: 2026-08-16i-plot-data-encoding
- date: 2026-08-16
- topic: systems/services/plot-manager.md · systems/services/content-service.md · systems/architecture.md · systems/character-profile/_index.md · systems/services/future-event-service.md · systems/balance.md · content/_index.md（+ 对侧库 `backend-design-documents/contracts/content-manifest.md`）
- status: distilled
- distilled-to: `systems/services/plot-manager.md`、`systems/services/content-service.md`、`systems/architecture.md`、`systems/character-profile/_index.md`、`systems/services/future-event-service.md`、`systems/balance.md`、`content/_index.md`、`backend-design-documents/contracts/content-manifest.md`、`backend-design-documents/open-questions/04-content-delivery.md`

## Intent（distilled）

**一句话：** AdventurePlot 的语义面早已定案，本次补齐它整条空缺的**数据面**——树是纯调制而非并行结构，剧本内容落成 `PlotArcData` + `PlotNodeData` 两个 `Resource` 类型，key points 的粒度定为**每条已激活 arc 一条**，overlay 的剧本例外获得两条可机械检查的合并期闸。

### 1. 树 = 纯调制，没有并行结构

AdventurePlot **不产出任何事件，也不持有任何事件序列**。它是 `ComputeEventOptions` 物化链条内部的一个加权 / 框定输入，与 location 框定、map 子流并列。三条既定纪律各自独立地封死并行结构：唯一物化点 + 唯一出口（并行结构 = 第二个出口）· 事件之间不存在预先编好的前后连边（剧本树若持有事件序列，它就是一张被编好的连边图）· PlotManager 只调内容不调约束（「这一步你必须去某处」的唯一手段是把候选池收窄，那是调制语言的一条算子）。

**推论（承重）：剧本树的「节点」不是事件，是一组调制参数 + 一段可选叙事 + 一组出边。** 玩家永远不会「进入一个剧本节点」，他只会察觉摆在面前的事件变了。

### 2. 两个内容类型：`PlotArcData` + `PlotNodeData`

- **`PlotArcData`** = 一条剧本线的头（四级层级之一）：层级、入口节点、激活条件、篇章范围、角色限定、互斥组。
- **`PlotNodeData`** = 树上的一个节点：叙事正文、调制算子、出边。

**不是一个类型**：arc 与 node 的激活面完全不同（arc 一次性激活、node 反复推进），且 key points 的锚点粒度落在 arc 上，一个类型无法同时当锚点和当步骤。**不是四个**：四级的差别只在激活范围与并发规则，字段集合完全相同，层级用一个枚举表达即可。

### 3. 剧本正文内嵌在 `PlotNodeData` 上

`PlotNodeData.Body : LocalizedText`（可空 = 纯调制节点）。**不复用状态转换触发的定性文案类型**：那类条目照旧只改不增，寄生其上会让 overlay 新增一条 arc 时写不出它的正文，剧本例外的全部收益归零。且拆条目的动机在剧本侧不存在——档位文案拆出去是因为每档 2–3 条候选可等概率取一、可单独关掉，而剧本节点的正文是一对一、不可替换、与节点同生同灭的。

**连带收益（第 6 条依赖它）：** 一条新 arc = 若干 `PlotNodeData` + 一个 `PlotArcData`，全部是剧本类型，不需要新增任何非剧本 `Id` 就能自足。

### 4. key points 粒度 = 每条已激活 arc 一条

粒度判据由悬空降级规则反推，不是体积判据：全局单指针一处悬空即整个剧本层不可解析（直接违反硬约束）· 每节点一条痕迹满足可跳过但随轮回长度线性膨胀且无消费方 · **每 arc 一条**使一条悬空只让那一条剧本线惰性化，降级从「不阻塞轮回」加强为「不阻塞其余剧本线」。

记录里只有内容侧 `Id` 与两个整型坐标，**没有任何 `InstanceId`**；时序坐标沿用 `pastEvent` 的 `Seq`（`DisabledAbilityEntry.AppliedAtSeq` 的既有先例）。

### 5. 推进时点 = 已有的 `eventEnd`，单步推进

判定并入 band 写入的**同一次 `TryApply`**，不新增存档点、不新增结算阶段。**一次 `eventEnd`，每条 arc 至多前进一个节点**——允许链式推进会让一次结算跑完半条剧本线，玩家在一个事件后发现候选池换了三轮；单步推进使「剧本推进速度 ≤ 事件推进速度」成为结构性事实。

### 6. overlay 剧本例外的两条合并期闸

合并阶段 ContentRegistry 本就知道每个 `Id` 来自基线还是 overlay，`newIds` 是免费拿到的。两条规则跑在合并后强校验里，全量、非 `#if DEBUG`：**闸 A** `newIds` 的宿主类型必须 ∈ { `PlotArcData`, `PlotNodeData` }；**闸 B** 新增剧本条目引用的非剧本 `Id` 必须存在于基线，引用剧本 `Id` 则允许来自 `newIds`。闸 A 顺带把「overlay 只改不增」连同它的例外一起从约定变成启动期硬校验。

**这条纪律的客户端天花板是阶梯第 3 级**：第 1 级靠类型 / 可见性、第 2 级靠编译期，而被检查的对象是 `.tres` 的引用图，C# 编译器与类型系统都触不到它。**选级判据的诉求由另一条路满足——把同一份校验前移到 overlay 打包工具**：喂「基线 + 待发 overlay」跑同一个 `LoadAll()` 路径，不通过就不产出包。客户端侧的 `PushError` 保留为兜底，处理手工塞进 `user://overlay/` 的非发布路径。

### 7. side arc 并发上限 2，超出排队不丢弃

`MaxConcurrentSideArcs` 是平衡数值，初值 `2`，只统计 `SideChapter` / `SideStory` 且 `Active` 的 arc（Story 与 Chapter 是结构不是穿插，不占配额）。依据：调制是叠加的，三条 side arc 同时改权重会让候选池变成谁也说不清的混合物，而调制正是隐藏属性与剧本的主要显影通道。

**超出 → 排队不丢弃**：丢弃会让 `PlotTriggerId` 触发变成「有时不生效」，一个跨入煞气 Band 3 却什么都没发生的轮回无法与「机制坏了」区分。

### 8. key points 不持久化已走分支路径

只记「这条线现在在哪个节点」，不记怎么走过来的。判据「重算不出来的存」有两半——重算不出来**且有消费方**；路径当前没有任何消费方（调制、叙事、推进都只读当前节点）。日后确需（履历展示「你在这条线上选了什么」）的落点是 `PastEventEntry` 而非 key point：选分支本就发生在某个事件里，记进那条事件痕迹比在 key point 上另开一个随轮回长度线性增长的数组更贴近既有分层。代价明写：在补上那个字段之前，已结束的轮回无法回顾分支选择，补记补不回来。

## Clarifications（interview 产物）

1. **arc 的放量开关语义 ↔ 后端契约的「flags 对剧本条目无作用点」** → **以本次为准，改写后端契约**。
   `backend-design-documents/contracts/content-manifest.md` 原写「剧本条目不进任何抽取池，把剧本 `Id` 放进 `disabledIds` 不产生任何效果」，那是在「剧本条目只由 key point 定位读取」这一未细分的前提下写的。本次把剧本内容切成 arc（被激活抽取 ⇒ 产出侧）与 node（被 key point 查表定位 ⇒ 结构性读取）两层后，该前提对 arc 不再成立。
   裁定：**`PlotArcData` 照常参与 `AllEnabled()` 与 flags**（关一条只让它不再被**新激活**，已在 key points 里的照常经 `Get(id)` 解析）；**`PlotNodeData` 恒启用**（`false` → 加载期 `PushError`）。收益是一条 overlay 热更推上去的坏 arc 可秒关，否则唯一手段是发布更大的 `contentVersion`。
   **这一项使本次成为跨库运行**，对侧库须同改（见下方落点）。

2. **排队 arc 的持久化** → **`PlotArcState` 增加 `Queued` 值，排队即写一条 key point**。
   原草稿定「队列不落存档、由『全部 arc 的激活条件 + 当前 key points』读时重建」，与「排队使触发恒定成立」自相矛盾：道心是双向属性、煞气可被净化下拉，band 回落后重建的队列会静默丢掉那条排队 arc——等价于丢弃，而丢弃是被明确否决的。
   裁定形态：触发时立刻写一条 `PlotKeyPoint`（`State = Queued`，`NodeId = EntryNodeId`），出队时改为 `Active`。判据「重算不出来的存」成立（跨档是一次性历史事件，band 回落后重算不出），且**零新增字段**——复用已有的每 arc 一条结构；并发上限只约束 `State == Active` 的条数，统计口径原样成立。

## Open questions

- **多条 Active arc 的 `Modulation` 如何合并**（白名单取交还是取并、权重相乘还是相加）——阻于 `future-event-service.md` 的「框定叠加顺序」待答项。字段形态不受影响。
- **`EventOption` 完整物化字段清单** —— `PlotModulation` 的六个字段是**下界不是上界**，字段面可能还需扩。
- **DnD 式选分支的触发点与 UI** —— `BranchLabel` / `PlotBranchOption` 只是数据挂点，何时把分支摆给玩家、摆在哪一屏不在本次范围内。
- **剧本内容的体积与分发粒度 / 按篇章分包** —— 本次不涉及；`PlotArcData.ChapterScope` 恰是日后分包边界的天然切分键，但分包与否仍待答。

## Notes / triage

- 来源：`inbox/solution-draft-plot-data-encoding.md`（`status: decided`，三项取向已由用户在评审阶段裁定），已归档进 `inbox/archive/`。
- 移出待答项 2 条，记于 `answer-logs/log-plot-data-encoding.md`。
- **不构成阻塞的前置：** 角色模板池形态——`PlotArcData.CharacterIds` 设计成两种取向都能承载（空 = 全局主线，填值 = 角色专属），日后定哪一侧都只改内容不改 schema。
