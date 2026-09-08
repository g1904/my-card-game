# 轮回出口的三层处置 —— `completed` 保留、`defeated` 留墓碑

- id: 2026-09-06-completed-data-retention
- date: 2026-09-06
- topic: systems/services/life-cycle-service.md · systems/character-profile/_index.md · program-overview.md · decisions/ADR-0004-realm-checkpoint-retry-model.md · systems/services/profile-schema-versions.md
- status: distilled
- distilled-to: systems/services/life-cycle-service.md、systems/character-profile/_index.md、program-overview.md、decisions/ADR-0004-realm-checkpoint-retry-model.md、systems/services/profile-schema-versions.md、answer-logs/log-completed-data-retention.md

## Intent（distilled）

### 1 · 收口方向：`completed` 不清理角色实体状态

库内曾有两种互斥写法：一侧写「`defeated` 与 `completed` 数据都会在轮回结束时被清理」，另一侧的四项机制（`CycleStartSpec.SourceCharacterId` 的按 id 引用、篇章解锁的「可挑战角色」判定、篇章继承 = 全部继承、从篇章起始存档重试）**全部以「通关档仍然存在」为唯一数据源**，库内没有任何一处给过替代载体。

**判定：后者成立。** 前一句仍有一个为真的窄读法——被清理的是**轮回运行态**，不是角色实体状态。收口后的统一措辞：

> 轮回运行态在两条出口上都被清理；角色实体状态只在 `defeated` 上被处置，`completed` 保留下来即「境界存档」。

### 2 · 「清理」是三层，不是一件事

矛盾的根源是「清理」一词同时用在三个层上。三层都落在既有时点，**不新增任何存档点**：

| 层 | 内容 | `completed` | `defeated` | 时点 |
|---|---|---|---|---|
| **L1 运行时拆解** | 断开信号、`QueueFree` 实例化节点、清空内存集合与静态字段 | 做 | 做 | `TeardownCycle()` |
| **L2 轮回运行态字段清空** | 见字段三分表的「运行态」 | 做 | 做 | 并入 `CompleteChapter` / `DefeatCharacter` 那一次 `TryApply` |
| **L3 角色实体状态处置** | 见字段三分表的「可回滚实体状态」 | **不做**（保留 = 境界存档） | 做（墓碑形态见 §4） | 同 L2 那一次 `TryApply` |

L1 与 L2 对两条出口一视同仁。

### 3 · 字段三分（不是二分）

分区判据：**「这一格描述的是这一遍怎么走的」→ 运行态；「这一格描述的是这个角色是谁 / 走到哪了」→ 实体状态**；实体状态再按**「它必须活过一次重试吗」**分成可回滚与不可回滚两半。

- **运行态（L2 清空）**：`rng`（`cycleSeed` + 四条子流）· `activeEvent` · `activeCombat` · `eventOption`（当前批）。
- **可回滚实体状态（进 `chapterStartSnapshot`）**：`deck` / `technique` / `looseCard` · `magicPack` · `characterPower` · `disabledAbility` · `Status` 全部数值格（含两个 band、两个 location 格、`ChapterLifeSpanBudget`）· `spiritStone` / `immortalJade` · `plotKeyPoint` · `realm` / `level`。
- **身份与元进程格（既不清空也不回滚）**：`id` · `characterDataId` · `chapter` · `status` · `defeatReason` · `chapterRetry` · `startContentVersion` / `lastContentVersion` · `chapterStartSnapshot` 自身 · **`pastEvent` / `pastItemUse`**。

`chapterRetry` 落第三类是承重的：它若进 snapshot，重试就成了「回滚到 0 再 +1」，计数永远停在 1，重试上限**静默失效**。

### 4 · `pastEvent` / `pastItemUse`：跨篇章一路追加，重试也不回滚

两条痕迹序列**既不在篇章边界清空，也不随重试回滚**。理由是它们是四处既有设计的唯一数据源或唯一坐标系：

- 「数 `pastEvent` 里 `Op == Grant` 且 `Source == ExchangePurchase` 的 element 即得**本轮回**买了几件」这条推导口径要求跨篇章连续；
- PlotManager 读的是**角色的整体历程**（选择偏好 / 整批重算依据），截断即丢掉前几章的信号；
- `PlotKeyPoint.EnteredAtSeq` 是「进入当前节点时的 `pastEvent` 时序坐标」，而 `plotKeyPoint` 跨篇章保留 —— `Seq` 一旦复用，该坐标语义悬空；
- `TraceElements` / `ItemUseElements` 的入口校验（`Seq != 末条 Seq + 1` 即整批拒绝）立在「只追加 + 单调递增不复用」这条不变式上。

**代价是有意的：**重试后上一次失败尝试的痕迹留在历程里 —— 它是「你在这一章折过几次」的唯一逐笔来源。

**连带：篇章计数改取法。** `ChapterEndSummary.PastEventCount` 与 `CycleEndSummary` 的同名字段不再取 `pastEvent.Count`，改由**篇章起始 `Seq` 锚点**求差得出；锚点落 `chapterStartSnapshot` 内的一格。

### 5 · `defeated` 那一半：清理 ≠ 立刻整条删除

三条既有设计要求 `defeated` 的档不能在终结那一刻整条消失：`RetryChapter(string characterId)` 的入参必须可解析 · `chapterRetry`「通关后保留计数、不清零，故计数同时是一份历史」需要持久载体 · 「从该篇章起始存档重试」要求金丹存档活过 ch3 途中的那次死亡。

**墓碑形态**：`defeated` 时保留 `id` · `characterDataId` · `chapter` · `status` · `defeatReason` · `chapterRetry` · **`chapterStartSnapshot`** · `pastEvent` / `pastItemUse`，清空 L2 全部运行态 + L3 的可回滚实体状态列。墓碑不是任何篇章的「可挑战角色」（该判定只认 `completed`），故它不会让本该锁定的篇章保持解锁。

### 6 · 存档表达 = 单记录 + `chapterStartSnapshot`

一个角色恒为 `characterProfile` 列表里的**一条**记录，原地跨三篇章推进。

| 项 | 形态 |
|---|---|
| 新增字段 | `CharacterProfile.chapterStartSnapshot` —— 本篇章起始那一刻**可回滚实体状态列**的冻结拷贝 + 一格篇章起始 `Seq` 锚点 |
| 写入时点 | **只在 `StartCycle` 写一次** |
| 续章 | `StartCycle(SourceCharacterId = 自身 id)` → `status: completed → ongoing`、`chapter += 1`、新 `cycleSeed` 与四条子流、写新的 snapshot |
| 重试 | `RetryChapter(id)` → 用 snapshot 整份回滚可回滚实体状态列、`chapterRetry.ChN += 1`、`status: defeated → ongoing`、换一套随机流 |
| 状态机 | `completed → ongoing` 是一条合法转移（由 `StartCycle` 触发）；只有 `defeated` 是吸收态 |

`chapterStartSnapshot` 使 `CurrentLocationId` 与 `ChapterLifeSpanBudget` 两处「随该篇章起始存档一并回滚 / 带回」的现成措辞获得逐字对应的载体 —— 它们此前指向的对象在库内是无名的。

### 7 · 回收口径：只回收 ch1 墓碑

ch1 重试 = 重新走角色选择、新建一个 `CharacterProfile` ⇒ ch1 墓碑的 snapshot 从落地那一刻起就永不可读，回收无歧义、不读任何上限。

**重试次数已耗尽的墓碑与 ch3 通关档一律保留** —— 不引入「读取上限」一类判定（那会撞上「礼包在耗尽后购买、上限从 3 抬到 9，而 snapshot 已被回收」这个边角），也不引入礼包边角规则。

### 8 · ch3 `completed` 永久保留完整档

不回收元婴通关档的实体状态列。明知代价（当前零消费方 —— 没有 ch4、不做独立回看、`TotalCyclesCompleted` 已承载「通关过几次」；每通关一次即在云端权威主档上永久多留一份完整角色状态），取的是**奖杯感**，与「元婴为奖杯」的措辞一致。

### 9 · 不新增存档点、不 bump schema、后端零配合

- L2 / L3 的写入并入 `CompleteChapter` / `DefeatCharacter` 那一次既有的 `TryApply`，落在既定的篇章边界 / 轮回结束存档点上。
- `TeardownCycle()` 的语义收窄为**纯运行时拆解、零存档语义** —— 塞进存档语义就要在方法内分支 `status`，而两屏摘要的组装时点已钉在它之前。
- `chapterStartSnapshot` 是首发前的 v1 补条目，**不产生任何 bump**；`profile-schema-versions.md` 的「本表新增一行 = 一次 bump 定案」这条跨边界触发源因此不触发 ⇒ 后端零配合，本次单库落笔。

## Clarifications（interview 产物）

- **`completed` 档回到 `ongoing` 的存档表达** → **单记录 + `chapterStartSnapshot`**（未取「每篇章一条记录 + 血统引用」）。理由：后者省下的是一句措辞，换来的是一条必须新写、且随时间失效即静默膨胀的回收规则。连带：`character-profile/_index.md` 的「终态收敛的状态机」一句改写。
- **ch3 `completed` 是否回收实体状态** → **永久保留完整档**（未采纳草稿推荐的「与 `defeated` 同档处置」）。用户在明知零消费方与体积代价的前提下选择奖杯感。
- **收口范围** → **两条出口一并收口**，`defeated` 侧按墓碑形态落笔。理由：两条出口写在同一句话里，分开收会留下第二次矛盾。连带后果：ch3 `completed` 保留完整档而 `defeated` 只留墓碑 ⇒ **两条出口的处置自此不再对称**，不得再复用「两条出口同档处置」的表述。
- **`pastEvent` / `pastItemUse` 的篇章边界与重试处置** → **不清空、不回滚，改摘要取法**（推翻草稿原案的「篇章边界清空」）。原案援引的 `future-event-service` 开局构筑判定式经直读**不构成清空的论据**（`chapter == 1` 单独已排除 ch2 / ch3）；而清空要同时松动四条已成文的承重纪律。改的是一个呈现层计数的取法。
- **`chapterStartSnapshot` 的保留与回收** → **必须进墓碑保留清单**（草稿的墓碑字段清单漏列，不补则「金丹存档活过 ch3 死亡」整条失效）；回收口径**只回收 ch1 墓碑**。
- **标准默认（自动采纳）：** snapshot 排除必须活过一次重试的格（`chapterRetry` 首当其冲）⇒ 字段面写成三分而非二分 · snapshot 只在 `StartCycle` 写一次（续章必经 `StartCycle`，`CompleteChapter` 那一次恒被覆盖、无消费方）· 重试 / 续章时 `characterPower` / `magicPack` 上的 `Status` 开关随持有列表整体回滚 / 继承，账号级 `playerPower` / `playerItem` 的 `Status` 不受影响 · 不新增存档点、不 bump、后端零配合。

## Open questions

- 无。本次答定的两条（`completed` 数据处置、snapshot 回收口径）均已落笔，不留待决项。
