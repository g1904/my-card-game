# Answer log completed-data-retention

- 日期：2026-09-06
- 来源：`inbox/solution-draft-completed-data-retention.md` → `handoffs/2026-09-06-completed-data-retention.md`
- 移出条数：**1**

## 移出的待答项

**`completed` 是否清理角色数据（`open-questions/06-meta-progression.md`）** → **不清理角色实体状态。** 「清理」拆成三层：L1 运行时拆解（`TeardownCycle`）/ L2 轮回运行态字段清空 / L3 角色实体状态处置。L1 + L2 对两条出口一视同仁，**L3 只在 `defeated` 上做**。原措辞「`defeated` 与 `completed` 数据都会在轮回结束时被清理」有一个窄读法仍然为真（清的是运行态），据此改写；反侧的四项机制（`SourceCharacterId` 的按 id 引用 · 可挑战角色判定 · 篇章继承 = 全部继承 · 从起始存档重试）以「通关档仍然存在」为唯一数据源，库内无替代载体。
（归档去向：`systems/services/life-cycle-service.md`「轮回出口的三层处置」、`systems/character-profile/_index.md`、`program-overview.md` 阶段 5、`decisions/ADR-0004-realm-checkpoint-retry-model.md`、`systems/services/profile-schema-versions.md` #34）

## 逐条裁决

1. **`completed` 档回到 `ongoing` 的存档表达** → **选 A · 单记录 + `chapterStartSnapshot`**。一个角色恒为 `characterProfile` 列表里的一条记录，原地跨三篇章推进；`character-profile/_index.md` 的「终态收敛的状态机」随之改写（`completed → ongoing` 是一条合法转移，只有 `defeated` 是吸收态）。未取「每篇章一条记录 + 血统引用」——它省下一句措辞，换来一条必须新写、且随时间失效即静默膨胀的回收规则。
2. **ch3 `completed`（元婴通关档）是否回收实体状态** → **选 A · 永久保留完整档**。未采纳草稿推荐的 B；用户在明知「当前零消费方（无 ch4、不做独立回看、`TotalCyclesCompleted` 已承载通关计数）、每通关一次即在云端权威主档永久多留一份完整角色状态」的代价下，选择留住奖杯感。
3. **收口范围** → **两条出口一并收口**。`defeated` 侧按墓碑形态落笔：保留 `id` · `characterDataId` · `chapter` · `status` · `defeatReason` · `chapterRetry` · `chapterStartSnapshot` · `pastEvent` / `pastItemUse`，清空运行态与可回滚实体状态列。**两条出口的处置自此不再对称**（ch3 `completed` 留完整档 vs `defeated` 只留墓碑），不得再复用「两条出口同档处置」的表述。
4. **`pastEvent` / `pastItemUse` 的篇章边界与重试处置** → **不清空、不回滚，改摘要取法**。推翻草稿原案的「篇章边界清空」：原案援引的 `future-event-service` 开局构筑判定式经直读不构成清空的论据（`chapter == 1` 单独已排除 ch2 / ch3），而清空要同时松动四条已成文的承重纪律（Exchange 的「本轮回买了几件」推导口径 · PlotManager 读整体历程 · `PlotKeyPoint.EnteredAtSeq` 坐标 · 「只追加 + `Seq` 单调递增不复用」入口校验）。改的是一个呈现层计数：`ChapterEndSummary` / `CycleEndSummary` 的 `PastEventCount` 由**篇章起始 `Seq` 锚点**求差得出，锚点落 `chapterStartSnapshot` 内一格。**明写代价**：重试后上一次失败尝试的痕迹留在历程里，这是有意的——它是「你在这一章折过几次」的唯一逐笔来源。
5. **`chapterStartSnapshot` 的保留与回收** → **必须进 `defeated` 墓碑保留清单**（草稿的墓碑字段清单漏列，不补则「金丹存档必须活过 ch3 途中那次死亡」整条失效）；回收口径 = **只回收 ch1 墓碑**（ch1 重试是新建角色档，该 snapshot 结构上永不可读，判据不读任何上限）。**重试次数已耗尽的墓碑与 ch3 通关档一律保留**——按上限判定回收会撞上「礼包在耗尽后购买、上限 3 → 9，而 snapshot 已被回收」这个真实边角。

## 采纳的标准默认（未出题）

- **snapshot 的字段面写成三分而非二分**：运行态 / 可回滚实体状态 / 身份与元进程格。排除集逐条推出，其中 `chapterRetry` 是承重的——它若进 snapshot，重试成了「回滚到 0 再 +1」，计数永远停在 1，**重试上限静默失效**。
- **snapshot 只在 `StartCycle` 写一次**，不在 `CompleteChapter` 重复写（续章必经 `StartCycle`，后者恒覆盖前者、前一次写入无消费方）。
- **重试 / 续章时 `characterPower` / `magicPack` 上的 `Status` 开关随持有列表整体回滚 / 继承**；账号级 `playerPower` / `playerItem` 的 `Status` 不受影响。
- **`TeardownCycle()` 语义收窄为纯运行时拆解、零存档语义。**
- **不新增存档点、不 bump schema、后端零配合**（v1 补条目明写不产生 bump ⇒ 不触发跨边界承接）。
