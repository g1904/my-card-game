# adventure-event / travel / common-properties（Travel 子类型共有属性）

> Travel 类 AdventureEvent 共有的属性 / 字段。顶层共有属性见 `../common-properties.md`。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **目的地 location 引用，取自 `locationMap` 的邻接集合。** 一个 Travel 事件承载可前往的目的地 location（地域）；选定后刷新角色所在的 location，进而重算 eventOptions（见 `systems/services/future-event-service.md`）。**目的地不是内容作者在事件条目上连好的边**——连通关系由全局不变的 **`locationMap`** 承载，Travel 的目的地在物化时从当前 location 的邻接集合中取。location 与 `locationMap` 的主文档在 `systems/game-progression.md`。
- **路由语义。** Travel 功能上是地图路由选择，而非战斗 / 事件式玩法本身。
- **闸门形态下的物化置位。** 当 `eventCountLimit` 达成、Travel 作为出口出场时，它由 future-event-service 物化为**最高 `Priority`（= 1）**的 `EventOption`——该字段是**物化时动态置位**的，**不由内容作者在 `.tres` 写死**；**没有 `IsMandatory` 一类的强制标记字段**，闸门只靠优先级成立。同一个 Travel 内容条目在配额未满时仍可作为普通可选项出场。
- **目的地引用的是 `LocationData.Id`。** 邻接集合取自单份 `LocationMapData` 的无向边集，**取全量图、不经 `AllEnabled()` 过滤**——location 与地域图是结构性查表类内容，恒启用（见 `systems/services/content-service.md`）。载体形态、`Id` 约定与加载期校验归 `systems/game-progression.md`。
- **目的地的承载字段 = `EventOption.DestinationLocationId`（非 Travel 为空串）。** 它在**物化时**由 map 子流从邻接集合抽出并落在定稿实例上——**不能事后算**：抽取是物化产物，重算不保证同结果，而「产出即定稿、不得回查模板重算」禁止消费侧再抽一次。呈现（「前往 X」）与结算（写 `Status.CurrentLocationId`）读的必须是同一个 `Id`。字段定义见 `systems/services/future-event-service.md`。
  - **Explore 遮罩 Travel 时，目的地同样在物化时掷定并落在壳实例上**（必为随机那一档），并与 `RevealedEventId` 同属揭示前不得进入呈现层的字段。见 `../explore/_index.md`。
  - **痕迹侧不加目的地字段**：目的地由下一条痕迹的 `LocationId` 给出，三种边界情形（结算成功但轮回随即终结 / `Aborted` 时换图从未发生 / 读档后继续）下这一还原都成立，按「重算得出来的不存」加字段是净负收益。
- **痕迹侧：Travel 的 `PastEventEntry.LocationId` 记出发地。** 它是唯一一类会在自己结算过程中改写该字段的事件；目的地由下一条痕迹的 `LocationId` 给出。字段表见 `../common-properties.md`。
- **结算的写入面。** Travel 结算在 `eventEnd` 那**一次** `TryApply` 内同时更新 `CharacterProfile.Status` 的 `CurrentLocationId`（改为目的地）与 `LocationEventCount`（归 0）；不新增结算阶段、不新增存档点。字段语义见 `systems/character-profile/_index.md`。
  - **载体 = `ProfileChangeSpec.StatusChanges` 的两条 `StatusAssignment`（绝对置值）**，由 life-cycle-service 在组装 `eventEnd` 的 spec 时从 `option.DestinationLocationId` 读出并置入；**`GenericEventResolver` 对 Travel 不产出任何写入描述**，保住「resolver 只描述结果、不自行写档」的边界。
  - **判据是 `DestinationLocationId != ""`，不是 `EventType == Travel`**——后者会漏掉「Explore 揭示出的 Travel 也归 0」这一情形（那时 `EventType` 恒为 `Explore`）。组装形态见 `systems/services/life-cycle-service.md`。

Source: `handoffs/2026-07-24-docs-restructure-class-model.md` · `handoffs/2026-08-05b-location-fields-event-count-limit-and-skip-refill-closure.md` · `handoffs/2026-08-16g-travel-mechanics-and-location-carrier.md` · `handoffs/2026-08-17-travel-destination-and-status-change-elements.md`

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- 见 `_index.md`。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- 见 `_index.md`。

## 对应
提炼至：`.claude/knowledge/systems/adventure-event/travel.md`（待建）
