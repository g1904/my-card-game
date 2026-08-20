# ADR-0015 — 剧本树的数据形态：纯调制、两个内容类型、key points 每 arc 一条

- **状态：** Accepted
- **日期：** 2026-08-16
- **来源：** handoffs/2026-08-16i-plot-data-encoding.md

## 背景

剧本层此前只有语义描述（四级层级、隐藏属性驱动、key points），没有可写 `.tres` 的类型。落地时必须同时回答三件事：树的节点是什么、剧本内容落成几个内容类型、存档上的进度锚点记到什么粒度。

## 决策

**① 树 = 纯调制，没有并行结构。** AdventurePlot **不产出任何事件，也不持有任何事件序列**。**剧本树的「节点」不是事件，是一组调制参数 + 一段可选叙事 + 一组出边**；玩家永远不会「进入一个剧本节点」，他只会察觉摆在面前的事件变了。

**② 剧本内容 = 两个内容类型 `PlotArcData` + `PlotNodeData`**（各进 ContentRegistry、各有仓储）。**剧本正文内嵌在 `PlotNodeData.Body`**（`LocalizedText`），不复用定性文案条目、不单列文本类型。**调制权力面 = `PlotModulation` 六字段**（`TypeWeights` / `EventWhitelist` / `EventWeights` / `EnemyPoolScope` / `LevelBias` / `Tighten`），**不多一个字段**——抬 `eventPriority`、改模板字段、改敌人卡组在内容层**写不出来**。

**③ key points 粒度 = 每条已激活 arc 一条**（`PlotKeyPoint(ArcId, NodeId, State, EnteredAtChapter, EnteredAtSeq)`），不是每节点一条、也不是全局一个指针。记录里**只有内容侧 `Id` 与两个整型坐标，没有任何 `InstanceId`**。

配套：推进时点 = 已有的 `eventEnd`，**单步推进**（一次 `eventEnd` 每条 arc 至多前进一个节点）；载体 = `ProfileChangeSpec.PlotElements`；同时激活的 side arc 上限 `MaxConcurrentSideArcs`（初值 2），**超出排队不丢弃**且排队即写 key point。字段清单、加载期校验表与读档校验表见 `systems/services/plot-manager.md`。

## 理由

- **纯调制由三条既定纪律各自独立封死**：唯一物化点 + 唯一出口（并行结构 = 第二个出口）· 事件之间不存在预先编好的前后连边（剧本树若持有事件序列，它就是一张被编好的连边图，只是换了个地方存）· 只调内容不调约束。
- **两个类型而非一个**：arc 与 node 的**激活面完全不同**——arc 由 `PlotTriggerId` / 篇章边界激活（一次），node 在 arc 存活期间被反复推进（多次）；且 key points 的粒度落在 arc 上，一个类型无法同时当锚点和当步骤。**也不是四个**（每级一个）：四级的差别只在激活范围与并发规则，字段集合完全相同，而层级是一个枚举就能表达的东西。
- **正文内嵌而非拆条目**：定性文案条目属「被存档引用」类、照旧只改不增，而剧本例外的全部收益就是「新剧情可热更不发版」；正文若寄生其上，overlay 新增一条 arc 时**写不出它的正文**，例外当场失效。连带收益：一条新 arc 的全部构件都是剧本类型，不需要引用任何新的非剧本 `Id` 就能自足——这正是 overlay 双闸能被机械检查且不误伤正常编排的前提。
- **粒度由悬空降级规则反推，不是体积判据**：全局单指针 ⇒ 一处悬空即整个剧本层不可解析，降级规则在结构上不成立；每节点一条 ⇒ 存档随轮回长度线性膨胀且当前无消费方；**每 arc 一条** ⇒ 一条悬空只让那一条剧本线惰性化，降级从「不阻塞轮回」加强为「不阻塞其余剧本线」。
- **排队不丢弃**：丢弃会让 `PlotTriggerId` 触发变成「有时不生效」——一个跨入煞气 Band 3 却什么都没发生的轮回，无法与「机制坏了」区分。
- **`PlotModulation` 是剧本数据面唯一做到可执行化阶梯第 1 级的地方**：「只调内容不调约束」「碰不到模板任何字段」两条承重纪律在这个类型上退化为**内容作者根本写不出那个字段**（见 `decisions/ADR-0013-discipline-enforceability-ladder.md`）。

## 备选方案

- **剧本树持有事件序列 / 并行结构** — 否决：等于第二个 eventOptions 出口。
- **四级各一个内容类型** — 否决：字段集合完全相同，解析一个 arc 要走四条分支。
- **剧本正文复用定性文案条目** — 否决：热更权限相反，剧本例外当场失效。
- **key points 用全局单指针** — 否决：违反「必须能被独立解析、缺失时安全跳过」这条硬约束。
- **key points 记走过的全部节点** — 否决：线性膨胀且当前无消费方。
- **超出并发上限即丢弃触发** — 否决：触发变成「有时不生效」，与故障不可区分。

## 后果

- **剧情线不转入 `Finale`**：本 manager 在数据形态上够不着 Finale（写不出 `eventPriority` / `combatTier` / 任何模板字段），这条不需要新规则来禁止。替代形态是一场被 `PlotModulation` 拧过的 `Standard` 档 Combat——代价明写且正是想要的：剧情线 boss 不给残卷、不是篇章闸门、失败不影响境界突破。
- **key points 不持久化已走分支路径**：重算不出来但当前无消费方；代价是补上那个字段之前，已结束的轮回无法回顾分支选择。
- `PlotNodeData` **恒启用**（关一个中间节点会在树上造出空洞）、`PlotArcData` **照常参与放量**——放量的正确粒度是 arc，不是 node。
- 影响文档：`systems/services/plot-manager.md`（权威）· `systems/architecture.md`（`PlotArcState` / `PlotKeyPointAssignment` 的枚举与共享类型）· `systems/services/content-service.md`（剧本例外的双闸）· `systems/enemies/_index.md`（`PoolScope.PlotArcId` 对位）。跨库：`backend-design-documents/contracts/content-manifest.md`「剧本文本」。
