# PlotManager（管理器 · 隶属 future-event-service）

> 隐藏剧本管理器：剧本层级（Story / Chapter / SideChapter / SideStory 四级）、隐藏属性驱动（道心 / 煞气 / 寿元）、CharacterProfile 上的 key points、云端剧本服务客户端、eventOptions 调制。
> **它是 manager 而非 service**：生活在 `future-event-service` 内部，共享其事务边界与生命周期，**不被跨服务直接调用**。Source: `handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md`。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **AdventurePlot = 隐藏剧本层。** 一棵由**分支可能性**构成的树，在背景中运行、**调制 future-event-service 产出的 eventOptions**（见 `future-event-service.md`、`systems/game-progression.md`）。玩家通常看不到它，但它持续塑造后续会变为可用的 AdventureEvent；部分节点可像 **DnD** 那样让玩家**显式选择分支**。Source: `handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。

- **剧本层级（四级）。**

  | 层级 | 英文 / 代码 | 范围 |
  |------|------------|------|
  | 主线剧本 | AdventurePlot-Story | 贯穿**三大篇章**相连的大剧本（一条完整主线） |
  | 篇章剧本 | AdventurePlot-Chapter | **单个篇章**对应的剧本单元（一个 Story 含三个 Chapter） |
  | 支线（篇章内） | AdventurePlot-SideChapter | 在**单个 Chapter 内**穿插的小型支线 |
  | 支线（跨篇章） | AdventurePlot-SideStory | **跨篇章**穿插的支线 |

  即：三个 **Chapter** 相连组成一个 **Story**；Chapter 内可穿插 **SideChapter**，跨 Chapter 可穿插 **SideStory**。

- **隐藏属性驱动。** 属性模型借鉴 **Reigns** 但**反其道：属性隐藏、不作可见仪表**。隐藏属性（**道心 / faith**、**煞气 / malefic qi**、**寿元 / lifeSpan**）达**阈值**时触发对应剧情线。隐藏属性落在 `CharacterProfile.Status`（见 `life-cycle-service.md` 与 `systems/character-profile/`）；由 AdventureEvent 推拉，一切写入经 `profile-service.ProfileManager`。Source: `handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。

- **跨档给定性叙事反馈（已定案 · 数值仍隐藏）。** 数值继续隐藏，但**当某个隐藏属性跨过一个隐藏档位时，给一条定性的叙事描述**——**给方向与因果，不给数字**：

  ```
  道心 ↑ 跨档：  「你于静室枯坐三日，心念澄明。」
  煞气 ↑ 跨档：  「你的指节泛起一层洗不去的暗红。」
  寿元 进入 30%：「鬓角新添的白发，你已数不清是第几根。」
  ```

  - **只在跨档时触发**（每个隐藏属性分若干**隐藏档位**），**不是每次结算都播**——稀缺才有分量。
  - **落点 = 已有的 `ResolveOutcome` → `eventEnd` 阶段，无新结构**（见 `systems/adventure-event/common-properties.md`）。
  - **设计意图：** 玩家学到**方向与因果**（做这类事会推高煞气），学不到**精确数值**，因此**无法做电子表格式优化**。这正是本作对 Reigns 张力的替代路径——Reigns 靠**可见**仪表制造权衡，本作靠**可感知但不可测量**。
  - **档位划分（分几档、阈值在哪）未定**，见待决问题——它是本条能否落地的前置。
  Source: `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。

- **寿元 / lifeSpan = 递减的寿命预算。** 炼气起始 **100**、抵达筑基 **+100**、抵达金丹 **+300**、抵达元婴 **+500**（累计 1000；但元婴即游戏终点，该增量**不产生可消耗预算**，只是最后一次数值更新并存档——见 `systems/balance.md`）；**剩余寿元跨篇章结转**（下一篇章预算 = 该章增量 + 上一章剩余，见 `life-cycle-service.md`）。**每完成一个 AdventureEvent 按其 `lifeSpanCost` 扣减寿元**（内容侧为正数量值、物化时取负；`lifeSpanCost` 是 `selectCost` 复合成本类型的一个 element，见 `systems/adventure-event/common-properties.md`）；**递减到 0 → 触发「大限将至」→ 角色 defeated**。寿元是**独立于 `life`** 的寿命数值。Source: `handoffs/2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md` + `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。
- **寿元告警两段式（已定案 · 取代「只有 10% 红字」）。** **初始隐藏 → 进入 30% 给一条定性叙事提示 → 进入 10% 转为红字数值倒数。** 原因：对 100 点的第一篇章预算而言，10% 才告警**太晚，来不及做战略调整**；30% 的定性提示给出一个可行动的提前量，同时不破坏「数值隐藏」。呈现位置仍是 **EventOption 选择界面的静态标注**，见 `ux/screen-flow.md`。Source: `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。

- **CharacterProfile 只存 key points；内容在云端剧本服务。** `CharacterProfile` 上记录 AdventurePlot 的 **key points（关键节点 / 进度锚点）**；**完整的剧本与分支内容不落存档**，而是存于（云端）**剧本服务（script service）**——本 manager 按 key points 向其请求完整剧本 / 分支。

  这也是**本地 / 云端内容分界**的云端一侧：剧本文本**按进度动态请求、一次性呈现、不被存档引用**，因此**不进 ContentRegistry、不落存档**；而 `AdventureEventData` 等有稳定 `Id` 且被存档引用的定义属**本地内容层**。判据见 `content-service.md`。

- **剧本的离线降级：事务前置 + 预取缓存（已定案）。**
  - **事务前置：** 剧本内容**取得之前**不施加任何成本、不推进 key point。取不到 → 该事件呈现「内容加载失败 · 重试」，**CharacterProfile 零变更**。这把网络失败挡在事务边界之外，避免「扣了成本却没剧情」这类不可回滚的半状态。
  - **预取缓存：** PlotManager 按 key points **预取下一批**剧本文本（深度 = 下一批 eventOptions 对应的 key points），**LRU 缓存于 `user://cache/plot/`**。该缓存是**纯缓存**：可随时丢弃、**不落存档**、不参与冲突裁决。有缓存直接用，无缓存才走上面的失败路径。
  - 与 push / pull 通道的完整降级表见 `sync-service.md`。Source: `handoffs/2026-07-27-content-gating-offline-resilience-and-rng-persistence.md`。

### event / EventData（剧本内容侧）
- **event = 剧本内容单元。** 承载**提示文本以及分支式的选择 / 结果**；AdventurePlot 负责结构模型，event 内容侧负责具体剧本文本与分支。event 内容存于云端剧本服务，按 key points 请求。
- **隐藏属性驱动剧情线（示例）：**
  - **煞气 / malefic qi** —— 累积到阈值 → 触发 **「煞气反噬」** 剧情线。
  - **寿元 / lifeSpan** —— 递减到 0 → 触发 **「大限将至」**（角色 defeated）。

## 管理器角色 / API 面（契约）
> _总则与共享类型见 `systems/architecture.md`「API 契约总则」。PlotManager 是本项目中**唯一跨进程边界的 manager**（其余三处跨边界者都是服务本身）。Source: `handoffs/2026-07-27b-service-api-contracts.md`。_

- **定位。** PlotManager 是**云端剧本服务的客户端接口** + **eventOptions 的调制源**。它**不直接写 eventOptions**、也不向 game-progression / UI 暴露 eventOptions——对外呈现 eventOptions 的**唯一出口是宿主服务 future-event-service**。
- **类型声明为 `internal sealed`**（总则 3）：跨服务代码里根本写不出本 manager 的类型名。

| 方法 | 形态 | 完整签名 | 失败语义 |
|------|------|----------|----------|
| 请求剧本 | B | `Task<OpResult<PlotSegment>> ResolvePlotAsync(PlotRequest req, CancellationToken ct)` | 业务失败 → `OpResult`；**事务前置**：取不到则不施加任何成本、不推进 key point |
| 调制 | A | `EventOptionBatch ModulateEventOptions(CharacterProfile c, EventOptionBatch batch)` | 无调制 = 原批返回 |
| 阈值驱动 | A | `void OnHiddenStatThreshold(CharacterProfile c, HiddenStat stat)` | — |
| 选分支 | B | `Task<OpResult> ChooseBranchAsync(string branchId, CancellationToken ct)` | 业务失败 → `OpResult`；经 ProfileManager 推进 key points |

**只有 `ChooseBranch` 投影到服务门面上。** 前三个方法是宿主服务 `ComputeEventOptions` 物化链条**内部**的一环，不被跨服务调用（manager 纪律）；`ChooseBranchAsync` 因需要玩家输入，故由 future-event-service 以同名方法转发。

**后端接口（总则 7）：** 本 manager 持有 `IPlotBackend { Task<OpResult<PlotSegment>> ResolveAsync(PlotRequest req, CancellationToken ct); }`，两份实现 `HttpPlotBackend` / `OfflinePlotBackend`（读 `res://` 假剧本）。`PlotRequest` / `PlotSegment` 的**字段** ⟨待定⟩——依赖「剧本服务契约」，见待决问题。

**事件面：** 剧情线触发经宿主服务广播 `PlotThresholdReached(string CharacterId, HiddenStat Stat, int Threshold)`；分支揭示 / 选择、key point 推进同样由**宿主服务**代为广播（manager 不直接持有 EventBus 通道）。
- **数据契约：** CharacterProfile 存 key points（轻量锚点）；剧本内容由云端下发（不落存档）；隐藏属性阈值触发映射待定。

## 决策(-> ADR)

- 内容云端下发依赖 **强制在线 · 云端权威** → `decisions/ADR-0003-online-cloud-authority.md`（Accepted）。
- **降为 future-event-service 内部的 manager** → 已定案（层级词表见 `systems/architecture.md`），**ADR 候选**。Source: `handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md`。

## 待决问题

- **数据编码与耦合：** AdventurePlot 树如何用数据表达？它是**调制** eventOptions，还是并行结构？key points 的粒度与 schema？Source: `handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。
- **剧本服务契约：** 离线降级已定（事务前置 + `user://cache/plot/` LRU 预取，见「意图」）；仍待定：**请求 / 下发协议**与**版本化**。→ 协议契约的另一侧归 `backend-design-documents/`。
- **预取与事务前置的边界。** 预取降低失败率但不消除它；**LRU 容量上限**、以及**预取失败是否静默**（不打扰玩家、留待实际请求时再报）未定。Source: `handoffs/2026-07-27-content-gating-offline-resilience-and-rng-persistence.md`。
- **DnD 式选分支：** 触发点、UI、以及玩家可见 / 不可见分支的边界未定。
- **隐藏属性的档位划分（08-01 新增 · 承重）。** 「跨档给定性叙事」已定案，但**每个隐藏属性分几档、阈值在哪**未定——**定性反馈的触发完全依赖它**，不定则本条无法落地。寿元已给两档（30% / 10%）；道心 / 煞气的档位未给。Source: `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。
- **跨档叙事文案的归属与形态。** 文案是挂在隐藏属性的档位定义上（每档一条固定文案），还是随触发它的事件而变（同一跨档在不同事件下措辞不同）？是否也走内容层（可热更）？未定。→ `systems/adventure-event/`、`ux/`。Source: 同上。
- **隐藏属性清单与阈值：** 已定 **道心 / 煞气 / 寿元** 三项且均隐藏；仍待定：是否还有其他隐藏属性、各自阈值、增减触发（哪些 AdventureEvent 推拉）、剧情线目录。（寿元消耗已定；仅剩「是否有非境界突破的寿元增长途径」待定。）→ 亦见 `life-cycle-service.md`。

## 对应
提炼至：`.claude/knowledge/systems/plot-manager.md`（引用层，待建）。
