# ADR-0026 — eventOptions 的生成 / 加权 = 一条十步管线；类型修正为乘性系数

- **状态：** Accepted
- **日期：** 2026-08-22
- **来源：** handoffs/2026-08-22-event-generation-weighting-pipeline.md

## 背景

`future-event-service.ComputeEventOptions` 那段算术从未被写下来。全库有五份文档各自登记着「生成 / 加权规则未定」「三层框定的叠加顺序未定」，而它是四个非战斗事件子类型、`game-progression` 与 `plot-manager` 合并算法共六份文档的**共同上游**——不定它，玩法侧任何一份文档都写不出可验证的验收标准。悬着的具体量有四个：类型修正用什么算子、三层框定谁先谁后、多条 `Active` arc 的调制如何合并、批次规模 N 由谁决定。

## 决策

**把 `ComputeEventOptions` 定死为一条十步管线（仅描述常规批），类型修正取乘性系数。**

- **类型修正 = 乘性系数，作用于归一化前的权重，支撑集不变：**
  `w_type(t) = BaseTypeWeights(t) × LocationMod(t) × Π_arc PlotTypeMod(arc, t)`，`P(t) = w_type(t) / Σ w_type(t')`。
  取值域：location 的 Combat / Exchange / Research / Explore 四行 `> 0`、Travel 行 `>= 0`；剧本侧 `EventTypeWeight.Multiplier` 与 `EventWeight.Multiplier` 恒 `> 0`，不设 Travel 例外。**乘法可交换 ⇒「location 与 arc 谁先」不是需要裁决的量。**
- **三层框定收为两层 + 一个消费者：** location 与 `PlotModulation` 是框定（改支撑集与权重），map 子流是消费者（在已定形的分布上掷），**seeded RNG 不与前两层并列**。
- **十步：** ① 取池（`AllEnabled()` → `ChapterScope` 命中当前篇章）· ② 白名单取并收窄 · ③ 条目级闸 · ④ 类型分布归一 · ⑤ N 掷定 · ⑥ 类型指派（有放回，按各类型可用条目数封顶）· ⑦ 条目无放回抽取 · ⑧ Travel 段 · ⑨ 逐项物化 · ⑩ 收缩保底 + 断言。**闸门批在 ① 之前短路**；满级后的 Finale 条目是管线之前的**闸门式旁路**（恒进候选池、直接占一个槽位、不参与类型加权）。
- **多条 `Active` arc 的合并算子：** `TypeWeights` / `EventWeights` **相乘**（恒等元 1.0）· `EventWhitelist` **非空者取并** · `EnemyPoolScope` 取并 · `LevelBias` 相加 · `Tighten` 逐字段取更紧。
- **批次规模 N 由按篇章分格的 `BatchSizeWeights` 掷定**（五格 N=1…5，走 map 子流）。**N 是目标槽位数不是产出数量**，实际输出允许少于 N，只保底 `Count >= 1`；收缩到 0 时补一个 Travel、走既有死局兜底通道（**不是单项补位**）。**`k`（Travel 槽位数）是 N 与类型分布的副产品，不是独立旋钮。**
- **条目基础权重落 `AdventureEventData.SelectionWeight : SelectionWeightGrade`**（`Rare / Uncommon / Common`，默认 `Common`）+ 平衡表 `SelectionWeightGrades` 映射。
- **「策划 vs 随机」不设旋钮**：策划度由 `eventPriority = 1` / `EventWhitelist` + `EventWeights` / 加权随机三条既有通道逐级承载，是涌现量而非要拍板的数字。

逐步伪码、取值域、加载期校验与物化后断言 → `systems/services/future-event-service.md`；合并算子表 → `systems/services/plot-manager.md`；`SelectionWeight` 字段面 → `systems/adventure-event/common-properties.md`。

## 理由

- **只有正的乘性系数能兑现 location 那一行既定的「软框定」语义**（改权重、不改可及性）。加性偏移做不到——一个大负偏移把权重按到 0 或负，可及性就没了；「白名单 + 权重」本身是**硬**框定且与 `PlotModulation.EventWhitelist` 撞权威。
- **与赋级带已定的「调制修正（乘性，只改权重不改支撑集）+ 截断重分配」逐字同构**：同一段物化管线、同一个 map 子流、同一批调制源不能有两套权重语义。
- **相乘的恒等元是 1 ⇒ 缺省不需特判**；相加会让两条 arc 的调制全有全无地互相湮灭，与「排队不丢弃、触发恒定成立」相抵。
- **白名单取交在两条不相交白名单下必然为空**，落进既定的「内容池为空 = 坏数据 → `PushError` + 抛」——一次合法编排就能把游戏打崩；取交还会让一条 arc 静默取消另一条的强制性。要表达独占用 `ExclusiveGroup`，不要把独占性塞进合并算子。
- **归一化分母恒 > 0** 是取值域的直接推论：「加权抽取抽不出东西」在类型层不存在，类型层的空只可能来自收窄后该类型没有条目。
- **`SelectionWeightGrade` 是「内容侧不落裸数字、走枚举档 + 平衡表映射」的第三个实例**（前两个是 `ExperienceGrade` / `HiddenStatGrade`），并补上了 `Rarity` 被排除时所承诺的那个「权重」。

## 备选方案

- **类型修正取加性偏移** — 破坏支撑集不变，见理由第一条。
- **把 seeded RNG 写成第三个框定层** — 会让人以为存在「RNG 先于框定」的形态，而那形态不存在。
- **多 arc 的 `TypeWeights` 相加** — 两条 arc 的调制会互相湮灭。
- **`EventWhitelist` 取交** — 不相交白名单下必然打崩游戏。
- **N 由 location / `PlotModulation` / 隐藏属性决定** — 三者被结构性排除：location 的框定面是两组既定字段 · 规模落在约束面而 PlotManager 不调约束 · 隐藏属性输入侧只有两条既有通道。
- **允许 ⑥ 步槽位落空** — 会从后门重新引入「玩家可从批次宽度反推内容池状态」这条已被否决的泄露。
- **把闸门批塞进同一条管线** — 等于无必要地重写既有的 Travel 段伪码，且会模糊「邻接集合不经 `AllEnabled()`」这条明写的例外。
- **满级 Finale 走高权重而非闸门旁路** — 加权只能提高概率，而抬升需要的是必现；旁路同时封堵「剧本把 Combat 排除出白名单即间接封死篇章推进」这条 PlotManager 越权面。
- **为「策划 vs 随机」设一个旋钮** — 「预排序列」已被「剧本树不产出任何事件、不持有任何事件序列」封死。

## 后果

- **五份重复登记的「生成 / 加权规则未定」一次性关闭**（`future-event-service.md` 两条 · `game-progression.md` 三处 · `adventure-event/common-properties.md` · `travel/_index.md` 两条 · `plot-manager.md` 的合并算子）。
- **`AdventureEventData` 新增两格**：`SelectionWeight`（住 `adventure-event/common-properties.md`）与 `ChapterScope`。后者的事件侧启动期断言粒度取 `(chapter, EventType)`——`ChapterScope` 一旦落地，「第二章没有任何 Explore 条目」就成了一种可静默编排出来的坏数据。
- **`eventType == Travel` 的条目 `ChapterScope` 必须为空，加载期 `PushError`。** Travel 是结构性通道而非内容；不豁免则某章无命中的 Travel 条目时闸门批产不出选项，「Travel 兜底恒可产出 ⇒ 无轮回死锁」这条承重结论当场失效。
- **`PlotModulation.EventWeights` 的措辞由「权重加成」松动为乘性系数**（字段类型 / 数量 / 位置全不变）。
- **`content/adventure-event/` 类型档案开张时**（`/scaffold-content-type adventure-event`）须把 `SelectionWeight` 与 `ChapterScope` 纳入字段核对清单——当前该档案尚未开张，两格在内容层无回填面。
- **仍然开放**：`BaseTypeWeights` 与 `combatTier` 三档的配比取值、`BatchSizeWeights` 与 `SelectionWeightGrades` 的初值校准，全部归 ch1 数值标杆专场。本 ADR 只定算子与结构，不定任何数字。
- `systems/common-properties.md` 不受影响：`Rarity` 对 `AdventureEventData` 的排除原样成立（本条落的是 `SelectionWeight`，不同名不同表）。
