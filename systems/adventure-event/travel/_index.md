# adventure-event / travel（AdventureEvent-Travel）

> **新类型「前往某处地点」**（07-24 加入的第九类）。功能上是一次地图路由选择，刷新角色所在的 location（地域）。具体机制待定，见 ## 待决问题。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **前往某处地点（Travel）= AdventureEvent 的新子类型（第九类）。** **功能上是一次地图路由选择**——刷新角色所在的 **location（地域）**。07-24 随本次重构从 handoff 播种。Source: `handoffs/2026-07-24-docs-restructure-class-model.md`、`terminology.md`。
- **通过 location 换图，框定下一批可用事件。** location（地域）**框定 eventOptions** —— 它携带事件类型出现概率修正、一组特定的 `EnemyData`、以及 `eventCountLimit`（字段语义见 `systems/game-progression.md`）；Travel 事件是刷新 location 的手段。Source: `handoffs/2026-07-24-docs-restructure-class-model.md`、`terminology.md`。
- **Travel = 结构性闸门，不只是可选路由（已定案 · 08-05b · 承重）。** 玩家在当前 location 达到 `eventCountLimit` 后，**本批 eventOptions 收窄为仅剩 Travel**。承载机制**无需新增，且 08-06c 后只需一个字段**：Travel 选项以**最高 `eventPriority`（= 1）**出场即可封锁同批其余选项（跳过通道与 `ifMandatory` 已整体移除，本批的每一项本就都是必做项）。
  - **推论：地域迁移是被规则驱动的必经节点**，每个 location 都有一个确定的出口时刻。**进程的形状由此清晰：一次篇章 = 若干 location 的串联，location 之间由 Travel 缝合。**
  - **闸门给多个目的地（已定案 · 08-05b）：** 收窄后剩下的是**若干个并列的 Travel 选项**，各指向 **`locationMap`** 上当前 location 的一个邻接地域——**「去哪」本身是一次真实的玩家决策**。**推论：这是逐批择一的线性进程里唯一一个带地理含义的分岔点**；因 `locationMap` 对玩家不可见，第一次走是盲选，随 `LocationCodex` 积累而变成有信息的选择——**跨轮回的知识增长在此变现**。候选数量与抽取规则未定。
  - **Travel 不占用所在 location 的 `eventCountLimit` 配额（已定案 · 08-05b）：** 配额只计「选择进入并结算」的事件，**离开的动作本身不算做事**。
  - **推论：Travel 同时是死局兜底。** 配额用尽后 Travel 顶上，保证**任何时刻至少有一个可推进的选项**——且它必然可被选中（`selectCost` 无条件可支付，见 `../common-properties.md`）。
  Source: `handoffs/2026-08-05b-location-fields-event-count-limit-and-skip-refill-closure.md`。

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- **Travel 作为第九类加入分类法**（ADR-0002 待补订）。Source: `handoffs/2026-07-24-docs-restructure-class-model.md`。
- **location 框定 eventOptions、由 Travel 刷新**（方向已定）。Source: `handoffs/2026-07-24-docs-restructure-class-model.md`、`terminology.md`。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **Travel 与 game-progression 的具体交互（08-05b 收窄）？** **触发时机与可达来源均已定案**（`eventCountLimit` 达成即收窄为仅剩 Travel；目的地取自 `locationMap` 的邻接集合）；仍待定：`locationMap` 与 location 的**载体形态与定名**（单份邻接表资源？各 location 持边？）。→ `systems/game-progression.md`。
- **闸门给几个候选、怎么选（08-05b 收窄）？** **多个并列已定案**；仍待定：是否列出**全部邻接**、还是 seeded 抽取其中几个，候选是否受剧本调制。
- **一次 Travel 刷新多少 / 何种事件？** location 换图后 eventOptions 的生成规则（数量、类型配比的运算形态）未定。→ `systems/services/future-event-service.md`、`../common-properties.md`。
- **Travel 的代价 / 风险？** 前往是否消耗资源、是否可能触发途中遭遇未定。**死锁那一半已消解（08-06c）**：`selectCost` 无条件可支付，付不起也能走——只是走完可能判负。
- **与篇章 / 境界推进的关系？** Travel 是否与篇章边界 / Finale 触发耦合未定。
- **ADR-0002 补订：** 正式并入枚举待补。

## 对应
提炼至：`.claude/knowledge/systems/adventure-event/travel.md`（待建）
location（地域）主文档见：`systems/game-progression.md`。
