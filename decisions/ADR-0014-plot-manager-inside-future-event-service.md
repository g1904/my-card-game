# ADR-0014 — PlotManager 隶属 future-event-service；eventOptions 唯一出口

- **状态：** Accepted
- **日期：** 2026-07-25
- **来源：** handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md

## 背景

AdventurePlot 在背景中运行并塑造玩家将要看到的事件。它是不是一个自己的服务？如果是，它就有能力把事件直接摆到玩家面前——那样一来「玩家看到的这一批 eventOptions 是谁产出的」就有了两个答案。

## 决策

**PlotManager 是 manager，不是 service**：生活在 `future-event-service` 内部，共享其事务边界与生命周期，**不被跨服务直接调用**。

**future-event-service 是 eventOptions 的唯一出口**，也是唯一物化点（见 `decisions/ADR-0012-materialization-model.md`）。PlotManager 在 `ComputeEventOptions` 物化链条内部只作为一个**加权 / 框定输入**，与 location 框定、map 子流并列。

**本 manager 纯本地，永不跨进程边界**——剧本内容属本地内容层（见 `decisions/ADR-0007-local-content-layer-and-overlay.md`），读取是一次纯内存的 ContentRegistry 查找。

职责面、`PlotModulation` 的权力面与 key points 形态见 `systems/services/plot-manager.md`。

## 理由

- **它不命中 service 的任何一条判据**（见 `decisions/ADR-0008-service-hierarchy-vocabulary.md`）：没有自己的状态机、不需要事务性跨字段写入（一切写入经 ProfileManager）、不坐在外部 I/O 边界上。
- **第二个出口即第二份真值**：剧本若能自己把事件摆到玩家面前，「唯一物化点 + 唯一出口」立刻失效，而那两条是定稿纪律与确定性的地基。
- **剧本留在本地后，跨进程边界成分全部是服务本身** ⇒「manager 不跨边界」成为**无例外的结构性事实**，不需要为它开特例。

## 备选方案

- **PlotManager 提为独立服务** — 否决：不命中三判据；且它一旦是服务就有能力成为第二个 eventOptions 出口。
- **剧本内容走云端、PlotManager 持有一个后端接口** — 否决：见 `decisions/ADR-0007`；这会使它成为唯一跨边界的 manager。

## 后果

- **剧本树不产出任何事件、不持有任何事件序列**——它只调制。这条由本 ADR 与唯一出口共同封死，是 `decisions/ADR-0015-plot-tree-data-shape.md`「纯调制、无并行结构」的前提。
- 剧本读取**没有网络失败路径**，故不设剧本的事务前置、不设 `user://cache/plot/` 与 LRU 预取、`sync-service` 的降级表里没有「剧本请求」一行。
- `PlotThresholdReached` 由 future-event-service **代 PlotManager** 广播（manager 不直接对外）。
- 影响文档：`systems/services/plot-manager.md`（权威）· `systems/services/future-event-service.md` · `systems/architecture.md`。
