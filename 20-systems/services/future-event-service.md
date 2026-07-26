# future-event-service（服务）

> 依据当前 CharacterProfile **产出 eventOptions**（一组可选的 AdventureEvent）的服务层。玩家从 eventOptions 中择一以推进游戏；每完成一个事件后重算下一批。**对 `character-profile` / `game-progression` 提供「下一批可选事件」API。**

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **future-event-service = eventOptions 生成服务。** 依据**当前 characterProfile** 产出一批 **eventOptions** —— 即当前可用、玩家可从中择一以推进 run 的 `AdventureEvent` 集合。这把原先作为 `AdventureEvent` 图字段的 `possibleFutureEvent` 概念**提升为一个服务化的生成面**。Source: `10-handoffs/2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md`。
- **eventOptions 循环。** 玩家从 eventOptions 中选择一个 AdventureEvent → life-cycle-service 结算该事件、更新 characterProfile → **future-event-service 依更新后的 characterProfile 重算一批新的 eventOptions** 供玩家再次选择。这是一个 chapter 内驱动进程的核心循环（见 `20-systems/game-progression.md`）。Source: `10-handoffs/2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md`。
- **多层框定。** eventOptions 的生成受多层框定叠加：**location（地域）** 框定「当前地点开放哪批事件池」（见 `20-systems/game-progression.md`），**PlotManager** 依隐藏属性 / 剧本进度**调制** eventOptions（见 `plot-manager.md`）。future-event-service 是这些框定汇聚、产出最终 eventOptions 的服务。
- **PlotManager 是本服务内部的管理器（已定案）。** 隐藏剧本层**不是与本服务并列的服务**，而是生活在本服务内部的 manager，共享其事务边界与生命周期。它**不直接写 eventOptions**，也不直接对 game-progression / UI 暴露 eventOptions——它是一个**被调用的调制源**；对外呈现 eventOptions 的**唯一出口是 future-event-service**。Source: `10-handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md`。

  ```
  future-event-service.ComputeEventOptions(characterProfile)
        ├─▶ PlotManager        (隐藏属性阈值 / key points → 调制；云端剧本服务客户端)
        ├─▶ location 框定       (由 Travel 事件刷新)
        └─▶ SeedManager 的 map 子流
        ──▶ eventOptions ──▶ characterProfile（经 profile-service.ProfileManager 写入）
  ```

## 管理器

| manager | 职责 |
|---------|------|
| **EventOptionManager** | 依 CharacterProfile 产出 / 重算 eventOptions；location 框定与 seeded 抽取 |
| **PlotManager** | 隐藏剧本：key points ↔ 云端剧本服务、隐藏属性阈值 → 调制。详见 [plot-manager](plot-manager.md) |

## 服务角色 / API 面
> _意图层的方法 / 事件 / 数据契约草图；具体签名待细化（见待决问题与 `20-systems/architecture.md`）。_

- **方法面（意图草图 · 签名待定）：**
  - `ComputeEventOptions(characterProfile)` → 依当前角色状态（location、隐藏属性、修行历程等）产出一批 `eventOptions`。
  - `RefreshAfterEvent(characterProfile, resolvedEvent)` → 事件结算后重算 eventOptions。
- **协作面：** 生成的 eventOptions 交由 **game-progression（编排顶点）** 以**月圆之夜式菜单 / 横向滑动选择区**呈现；PlotManager 在产出前后**调制**该集合；随机性从 `life-cycle-service.SeedManager` 派生的 map 子流取得（确定性可复现，见 `20-systems/common-properties.md`）；内容按 `Id` 经 `content-service.ContentRegistry` 解析。

## 决策(-> ADR)
> _已定案的决定链接到 50-decisions/ADR-####。_

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **生成 / 加权规则未定。** 服务化架构已定，但从 characterProfile **生成 / 加权抽取** eventOptions 的具体规则（月圆之夜式策划 vs 随机权重、每批数量、node 类型配比）未定。→ `20-systems/game-progression.md`。Source: `10-handoffs/2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md`。
- **eventOptions 与 possibleFutureEvent 图的关系。** 服务产出 `eventOptions` 后，`AdventureEvent` 上原 `List<possibleFutureEvent>` / `List<pastEvent>` 图字段是保留（服务读写它）还是被服务态取代？两者关系待厘清。→ `20-systems/game-progression.md`。Source: `10-handoffs/2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md`。
- **框定叠加顺序。** location 框定、PlotManager 调制、seeded RNG 三者的叠加顺序与优先级未定。→ `20-systems/game-progression.md`、`20-systems/services/plot-manager.md`。
- **跳过通道的玩法语义未定。** 归属已定（复用 `life-cycle-service.AdvanceEvent` 的 `mode = Skip` 分支，`skipCost` 经 `profile-service.ProfileManager` 施加）；仍待定：跳过后本批 eventOptions 是移除该项还是整批重算（大概率重算）？是否计入修行历程？→ `20-systems/adventure-event/common-properties.md`。Source: `10-handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md`。
- **`ifMandatory` 由谁置位。** 内容作者在 `.tres` 写死，还是本服务 / PlotManager 在产出 eventOptions 时动态置位（剧情线关键节点强制）？一批 eventOptions 能否全部 mandatory？Source: `10-handoffs/2026-07-25b-event-cost-fields-capability-flags-and-service-hierarchy.md`。

## 对应
提炼至：`.claude/knowledge/systems/future-event-service.md`（引用层，待建）。
