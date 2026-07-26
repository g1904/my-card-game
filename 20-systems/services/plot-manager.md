# PlotManager（管理器 · 隶属 future-event-service）

> 隐藏剧本管理器：剧本层级（Story / Chapter / SideChapter / SideStory 四级）、隐藏属性驱动（道心 / 煞气 / 寿元）、CharacterProfile 上的 key points、云端剧本服务客户端、eventOptions 调制。
> **它是 manager 而非 service**：生活在 `future-event-service` 内部，共享其事务边界与生命周期，**不被跨服务直接调用**。Source: `10-handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md`。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **AdventurePlot = 隐藏剧本层。** 一棵由**分支可能性**构成的树，在背景中运行、**调制 future-event-service 产出的 eventOptions**（见 `future-event-service.md`、`20-systems/game-progression.md`）。玩家通常看不到它，但它持续塑造后续会变为可用的 AdventureEvent；部分节点可像 **DnD** 那样让玩家**显式选择分支**。Source: `10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。

- **剧本层级（四级）。**

  | 层级 | 英文 / 代码 | 范围 |
  |------|------------|------|
  | 主线剧本 | AdventurePlot-Story | 贯穿**三大篇章**相连的大剧本（一条完整主线） |
  | 篇章剧本 | AdventurePlot-Chapter | **单个篇章**对应的剧本单元（一个 Story 含三个 Chapter） |
  | 支线（篇章内） | AdventurePlot-SideChapter | 在**单个 Chapter 内**穿插的小型支线 |
  | 支线（跨篇章） | AdventurePlot-SideStory | **跨篇章**穿插的支线 |

  即：三个 **Chapter** 相连组成一个 **Story**；Chapter 内可穿插 **SideChapter**，跨 Chapter 可穿插 **SideStory**。

- **隐藏属性驱动。** 属性模型借鉴 **Reigns** 但**反其道：属性隐藏、不作可见仪表**。隐藏属性（**道心 / faith**、**煞气 / malefic qi**、**寿元 / lifeSpan**）达**阈值**时触发对应剧情线。隐藏属性落在 `CharacterProfile.Status`（见 `life-cycle-service.md` 与 `20-systems/character-profile/`）；由 AdventureEvent 推拉，一切写入经 `profile-service.ProfileManager`。Source: `10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。

- **寿元 / lifeSpan = 递减的寿命预算。** 炼气起始 **100**、抵达筑基 **+100**、抵达金丹 **+300**、抵达元婴 **+500**（累计 1000；但元婴即游戏终点，该增量**不产生可消耗预算**，只是最后一次数值更新并存档——见 `20-systems/balance.md`）；**初始隐藏**，**低于 10% 时在屏上显示**。**每完成一个 AdventureEvent 按其 `lifeSpanCost`（默认 -1）扣减寿元**（`lifeSpanCost` 是 `selectCost` 复合成本类型的一个 element，见 `20-systems/adventure-event/common-properties.md`）；**递减到 0 → 触发「大限将至」→ 角色 defeated**。寿元是**独立于血量 `life`** 的寿命数值。Source: `10-handoffs/2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md`。

- **CharacterProfile 只存 key points；内容在云端剧本服务。** `CharacterProfile` 上记录 AdventurePlot 的 **key points（关键节点 / 进度锚点）**；**完整的剧本与分支内容不落存档**，而是存于（云端）**剧本服务（script service）**——本 manager 按 key points 向其请求完整剧本 / 分支。

  这也是**本地 / 云端内容分界**的云端一侧：剧本文本**按进度动态请求、一次性呈现、不被存档引用**，因此**不进 ContentRegistry、不落存档**；而 `AdventureEventData` 等有稳定 `Id` 且被存档引用的定义属**本地内容层**。判据见 `content-service.md`。

### event / EventData（剧本内容侧）
- **event = 剧本内容单元。** 承载**提示文本以及分支式的选择 / 结果**；AdventurePlot 负责结构模型，event 内容侧负责具体剧本文本与分支。event 内容存于云端剧本服务，按 key points 请求。
- **隐藏属性驱动剧情线（示例）：**
  - **煞气 / malefic qi** —— 累积到阈值 → 触发 **「煞气反噬」** 剧情线。
  - **寿元 / lifeSpan** —— 递减到 0 → 触发 **「大限将至」**（角色 defeated）。

## 管理器角色 / API 面
> _意图层草图；具体协议待细化。_

- **定位。** PlotManager 是**云端剧本服务的客户端接口** + **eventOptions 的调制源**。它**不直接写 eventOptions**、也不向 game-progression / UI 暴露 eventOptions——对外呈现 eventOptions 的**唯一出口是宿主服务 future-event-service**。
- **方法面（意图草图 · 签名待定）：**
  - `ResolvePlot(character.keyPoints)` → 向云端剧本服务请求当前应生效的剧本 / 分支内容。
  - `ModulateEventOptions(character, eventOptions)` → 依隐藏属性 / 剧本进度调制宿主服务产出的 eventOptions。
  - `OnHiddenStatThreshold(character, stat)` → 隐藏属性达阈值时驱动对应剧情线（煞气反噬 / 大限将至 等）。
  - `ChooseBranch(character, branchChoice)` → DnD 式显式选分支时提交玩家选择，推进 key points（经 ProfileManager 写入）。
- **事件面：** 剧情线触发、分支揭示 / 选择、key point 推进等，由**宿主服务**经 EventBus 广播给 game-progression / UI。
- **数据契约：** CharacterProfile 存 key points（轻量锚点）；剧本内容由云端下发（不落存档）；隐藏属性阈值触发映射待定。

## 决策(-> ADR)

- 内容云端下发依赖 **强制在线 · 云端权威** → `50-decisions/ADR-0003-online-cloud-authority.md`（Accepted）。
- **降为 future-event-service 内部的 manager** → 已定案（两级层次 service ⊃ manager），**ADR 候选**。Source: `10-handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md`。

## 待决问题

- **数据编码与耦合：** AdventurePlot 树如何用数据表达？它是**调制** eventOptions，还是并行结构？key points 的粒度与 schema？Source: `10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。
- **剧本服务契约：** 请求 / 下发协议、缓存策略、**离线缓冲（断线时剧情如何降级）**、版本化未定。→ 与 `sync-service.md` 的断线降级策略耦合。
- **DnD 式选分支：** 触发点、UI、以及玩家可见 / 不可见分支的边界未定。
- **隐藏属性清单与阈值：** 已定 **道心 / 煞气 / 寿元** 三项且均隐藏；仍待定：是否还有其他隐藏属性、各自阈值、增减触发（哪些 AdventureEvent 推拉）、剧情线目录。（寿元消耗已定；仅剩「是否有非境界突破的寿元增长途径」待定。）→ 亦见 `life-cycle-service.md`。

## 对应
提炼至：`.claude/knowledge/systems/plot-manager.md`（引用层，待建）。
