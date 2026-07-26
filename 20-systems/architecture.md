# architecture（代码库如何运作的高层指南）

> 类模型化（Java class 式）结构总览：20-systems ≈ 一组类；character-profile / player-profile 为核心「类」，services/ 下的服务（内含 manager）对其提供 API；adventure-event 子类型层级；数据流。
> **本文件是结构与边界的权威**；「代码跑起来是什么样」的端到端运行链路见根级 `program-overview.md`；「工程里长什么样」（进程边界、文件夹布局、autoload 注册、代码形态）见根级 `system-overview.md`。深入代码侧知识见 `.claude/knowledge/architecture.md`（引用层）。
>
> **「服务」= 进程内模块单例**（同一 Godot 二进制、同一进程、直接 C# 方法调用），**不是**分布式微服务。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

### 类模型化结构总览
- **20-systems ≈ 一组 Java 类。** 每个系统是一个「类」，其内容（数据定义）是该类的「字段 / 内嵌类型」——内容并入系统，不单列内容层。Source: `10-handoffs/2026-07-24-docs-restructure-class-model.md`。
- **复杂类型下沉为文件夹。** 简单主题保持单 `.md`；复杂主题（各 adventure-event 子类型、deck、item、player-power……）各占一个文件夹，含 `_index.md` 与 `common-properties.md`，为「每个具体设计一个 Markdown」预留结构。
- **共有属性显式化。** 每一层的共有字段抽到 `common-properties.md`：adventure-event 各子类型各自一份、adventure-event 顶层一份、20-systems 顶层一份（`20-systems/common-properties.md`）。

### 核心「类」：character-profile / player-profile
- **PlayerProfile / 玩家信息（账号级主档，元进程层）：** 跨 run 持久，持有 `List<CharacterProfile>`、`GameSetting`、`List<PlayerPower>`、`List<PlayerItem>`、`List<Achievements>`、`AccountInfo` 等。结构权威见 `20-systems/player-profile/`。
- **CharacterProfile / 角色信息（单次 run）：** 一次 run / 一个角色的状态与历史（对齐 RunState 概念）：`status`（ongoing | defeated | completed）、`chapter`、`Status`（life / mana + 隐藏属性 道心 / 煞气 / 寿元）、`List<AdventureEvent>`、`List<CharacterItems>`、AdventurePlot key points 等。结构权威见 `20-systems/character-profile/`。
- 这两者是被服务操作的**数据核心**；它们不自己驱动 run 生命周期、事件生成或剧本下发，而是被服务读写。

### 服务层：两级层次 service ⊃ manager（**已定案**）

代码里只有两级职能层次，判据明确、不设第三级。完整清单见 `services/_index.md`；运行时端到端链路见根级 `program-overview.md`。Source: `10-handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md`。

- **service（服务）= 边界单元。** 值得成为服务当且仅当命中**三条判据之一**：① 拥有**自己的状态机或跨多帧的长流程**；② 需要**事务性地跨多个字段一致写入**（全有或全无）；③ 坐在**外部 I/O 边界**上（网络、存档、平台 SDK）。服务以 autoload 形式存在，**不持有独立数据**，只操作核心「类」；**服务之间不互相读写字段**——只经编排顶点调用或经 EventBus 广播既成事实。
- **manager（管理器）= 服务内部的职能组件。** 多个 manager 生活在同一服务里，**共享宿主服务的事务边界与生命周期**；**不被跨服务直接调用**——外部只看得见宿主服务的 API 面。

| 服务 | 判据 | 内含 manager |
|------|------|-------------|
| **account-service** | ③ | AuthManager、ComplianceManager |
| **content-service** | ③ | ContentRegistry、ContentUpdateManager |
| **sync-service** | ②③ | ProfileSyncManager、LocalCacheManager、MigrationManager |
| **profile-service** | ② | ProfileManager、CapabilityManager、AchievementManager |
| **life-cycle-service** | ① | RunStateManager、ChapterManager、SeedManager |
| **future-event-service** | ① | EventOptionManager、PlotManager |
| **combat-service** | ① | TurnManager、DeckManager、IntentManager |

#### 拆分轴：生命周期层 + 行为边界，**不是数据类型**（已定案）

**不**按 `power` / `item` / `card` / `resource` 各开一个服务：那会**撕碎事务**（一次结算典型要同时改多种资源，已定的 `selectCost` 复合成本类型的天然消费者是**一个**统一施加点）、**横切生命周期层**（`PlayerItem` 账号级跨 run 与 `CharacterItems` run 级即清，持久化与清理规则完全不同）、并退化为**无规则的贫血 CRUD**。同理**不为九类 AdventureEvent 各开服务**——只有 Combat 真有状态机，其余差异在**数据**而非**代码**（Finale 复用 combat-service，Mystery 揭示后落到真实 `eventType`）。

「同类内容的统一入口与标准操作接口」由 **content-service 的 ContentRegistry + 泛型仓储接口**满足，而非按类型开服务。

#### 两条唯一入口 + 一个编排顶点

- **内容读取唯一入口 = `content-service.ContentRegistry`**（代码中不散落 `ResourceLoader.Load`）。
- **档案写入唯一入口 = `profile-service.ProfileManager`**。`PlayerProfile ⊃ List<CharacterProfile>`，故由**单一 profile-service** 作为两层的写入面：`TryApply(spec)` 全量校验 → 全有或全无 → 单点提交；modifier pipeline 在此生效。life-cycle-service / combat-service / future-event-service 都只经它写档。
- **编排顶点 = game-progression**（不是服务，是屏幕流程编排层）。核心循环 `ComputeEventOptions → 呈现 → 玩家选择 → AdvanceEvent → 重算` 由它串联。

### 内容与档案的存储分界（**已定案**）

```
res://content/**.tres     基线内容，随包发布，只读（保证首启可用 / 离线可读）
user://overlay/**.tres    云端下发的增量，可热更，按 Id 覆盖基线
      ↓ 合并（overlay 优先，res:// 兜底）→ 合并后统一校验（重复 / 悬空 Id → PushError 早失败）
ContentRegistry（内存）    按 Id 索引，唯一内容读取入口
```

- **本地内容层**（`res://` + overlay）承载**有稳定 `Id`、被存档引用、需启动期校验**的一切：`AdventureEventData`、`CardData`、`EnemyData`、`ItemData`、`PlayerPowerData`、平衡表，**含静态展示文案**。因此 **AdventureEvent 的定义本身属本地** —— 启动期强校验模型成立。
- **云端剧本服务**只下发**按进度动态请求、一次性呈现、不被存档引用**的内容（AdventurePlot 分支文本），由 PlotManager 按 key points 请求，**不进 ContentRegistry、不落存档**。
- **档案**：云端权威 `PlayerProfile ⊃ List<CharacterProfile>`；启动时全量 pull，自动存档点 push，冲突以云端为准；本地 `user://cache/` 仅缓存，原子写 + schema 版本 + 迁移路径。归属 sync-service。

### 展示层契约：数据 / 运行时 / ViewModel 三层（**已定案**）

> 原问题：核心「类」目前只携带编码（`Id` / 数值），前端要用的描述字段应包含进去，还是为「充血模型」单建一套展示类？**已定案：不为充血另建并行类，按生命周期切分三层。** Source: `10-handoffs/2026-07-25b-event-cost-fields-capability-flags-and-service-hierarchy.md`。

1. **静态展示文本留在数据资源上。** `XxxData : Resource`（`.tres`）除 `Id` 与玩法数值外**直接携带**显示名 / 描述 / 图标——这本就是 `data-resource-rules.md` 的既有约定（显示字符串与 `Id` 分离、可本地化）。另建并行展示类只会制造两份需同步的真值。
2. **运行时 / 存档态只带 `Id` + 可变状态。** CharacterProfile 及其持有的运行态对象**不复制展示文本**——存档与上行云端负载保持轻量可版本化，文案变更不触发存档迁移。
3. **组合展示走 UI 层轻量 ViewModel。** 动态描述（数值代入、条件文案、随 capability flag 变化的可见性）由展示层按需组装 `Data + 运行时状态 → ViewModel`，只存在于呈现期，**不落存档、不进云端负载**。

**ViewModel 层因此是架构中的一个显式层**：位于 services / 核心「类」与屏幕场景之间，是「服务 → 屏幕」的数据形态契约。它单向依赖（读 Data + 运行时状态），不被服务反向依赖，也不参与存档 / 同步。

### adventure-event 子类型层级
- **AdventureEvent = 逐时逐刻的游玩单元。** 展开为按子类型分文件夹的深层结构（`20-systems/adventure-event/<子类型>/`），每个子类型含 `_index.md` + `common-properties.md`。
- **九类子类型：** Combat（战斗）、Finale（境界突破，篇章边界高潮）、Mystery（未知，遮罩一个固定事件）、Practice（修炼）、Exchange（交易 / 商店）、Research（闭关）、Social（社交）、**Explore（探索秘境，第八类）**、**Travel（前往某处地点，第九类 = 地图路由）**。分类权威见 `terminology.md` 与 `50-decisions/ADR-0002`。
- **Travel 特例：** 功能上是地图路由——刷新角色 location，从而框定 eventOptions（location 抽象归 `20-systems/game-progression.md`）。

### 数据流（目标）
```
启动 ──▶ content-service (manifest 版本比对 → overlay 增量 → 合并 → 校验)
登录 ──▶ account-service ──▶ sync-service.Pull ──▶ profile-service.Hydrate
                                                      └─▶ CapabilityManager 聚合
                                                            ──▶ EventBus: CapabilitiesChanged

Input (touch, 横向滑动选择)
   ──▶ Screen scene (月圆之夜式菜单)  ◀── ViewModel (呈现期组装 Data + 运行时状态; 不落存档)
        ──▶ game-progression (编排顶点: 呈现 eventOptions 供选择)
             ──▶ future-event-service (依 CharacterProfile 产出 eventOptions; 唯一出口)
             │      ├─▶ PlotManager (隐藏属性阈值 → 调制; key points ↔ 云端剧本服务)
             │      └─▶ location (由 Travel 刷新) + SeedManager 的 map 子流
             ──▶ life-cycle-service.AdvanceEvent (mode = Select | Skip; 状态机与编排)
                   ├─▶ profile-service.ProfileManager (唯一写入面; 原子施加成本 / 产出)
                   ├─▶ AdventureEvent.eventStart / eventEnd (事件自身内部流程)
                   │      └─▶ combat-service (Combat / Finale: 回合循环状态机)
                   ├─▶ content-service.ContentRegistry (按 Id 读内容: card / item / enemy / event ...)
                   └─▶ EventBus (广播 run / 篇章 / 剧情 事件) ──▶ 其他系统 / UI
   sync-service ◀── 自动存档点 ── PlayerProfile ⊃ CharacterProfile ──▶ 云端 (权威; user:// 仅缓存)
                                   (SeedManager 的具名子流驱动全部随机性)
```

## 决策(-> ADR)
> _已定案的决定链接到 50-decisions/ADR-####。_

- **修行事件分类（含 Explore / Travel）** → `50-decisions/ADR-0002-adventure-event-taxonomy.md`（Accepted；待补订 Explore / Travel）。
- **境界存档 · 篇章重试模型** → `50-decisions/ADR-0004-realm-checkpoint-retry-model.md`（Accepted）。
- **强制在线 · 云端权威** → `50-decisions/ADR-0003-online-cloud-authority.md`（Accepted）。
- **`.claude/knowledge` 降为引用层（本库成为内容 + 技术结构双重事实来源）** → ADR 候选（待固化）。
- **展示层三层切分（Data / 运行时·存档 / ViewModel）** → 已定案，**ADR 候选**（待固化）。Source: `10-handoffs/2026-07-25b-event-cost-fields-capability-flags-and-service-hierarchy.md`。
- **两级层次 service ⊃ manager；拆分轴 = 生命周期层 + 行为边界（非数据类型）** → 已定案，**ADR 候选**（待固化）。Source: `10-handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md`。
- **单一 profile-service 拥有两层 profile（ProfileManager 唯一写入面）；ContentRegistry 唯一内容读取入口；game-progression 为编排顶点** → 已定案，**ADR 候选**（待固化）。Source: 同上。
- **内容载体形态（随包基线 + `user://overlay/` 热更 + 云端版本校验）与本地 / 云端内容分界** → 已定案，**ADR 候选**（待固化）。Source: 同上。
- **PlotManager 隶属 future-event-service，eventOptions 唯一出口** → 已定案，**ADR 候选**（待固化）。

## 闭环缺口（架构体检 · 2026-07-25c 更新）

> 两级层次（service ⊃ manager）与拆分轴定案后，`2026-07-25b` 体检列出的 8 处缺口中 **6 处已闭合**、1 处部分闭合。Source: `10-handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md`。

| # | 缺口 | 状态 |
|---|------|------|
| 1 | PlayerProfile 侧无服务 | **已闭合** → profile-service（ProfileManager / CapabilityManager / AchievementManager） |
| 2 | 战斗内部无归属 | **已闭合** → combat-service（唯一自带状态机的事件类型；Finale 复用） |
| 3 | 存档 / 云同步无归属 | **已闭合** → sync-service（ProfileSyncManager / LocalCacheManager / MigrationManager） |
| 4 | 本地 / 云端内容分界未定 | **已闭合** → 有稳定 `Id` 且被存档引用 → 本地内容层；按进度动态请求、不被存档引用 → 云端剧本服务 |
| 5 | skip 通道无结算归属 | **部分闭合** → 归属已定（`AdvanceEvent` 的 `mode = Skip` 分支，经 ProfileManager 施加）；**玩法语义仍未定**（是否计入修行历程、是否照扣寿元、能否整批全跳） |
| 6 | `selectCost` / `lifeSpanCost` 重叠 | **已闭合**（07-25b：包含关系）；ProfileManager 是其唯一消费点 |
| 7 | 编排顶点缺失 | **已闭合** → game-progression |
| 8 | UI 与服务间无契约层 | **已闭合**（07-25b：ViewModel 层） |

**剩余的结构性未决项**已下沉为各服务文档的待决问题（API 签名、cost element 清单、热更范围边界、断线降级策略），见下节与 `services/*`。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **服务 API 契约（本文件核心待细化项）：** 七个服务与其 manager 的**职责边界已定**，但**具体 API 面（方法签名、参数 / 返回类型、事件负载 schema）尚未定义**。各服务文档已给意图层草图，权威契约待在此细化。Source: `10-handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md`。
- **cost element 清单（ProfileManager 的形状取决于它）：** 有哪些 element（gold / mana / 道具 / 隐藏属性推拉？）、各自数据形态（固定值 / 区间 / 公式）、是否允许**部分抵扣**。→ `20-systems/adventure-event/common-properties.md`、`services/profile-service.md`。
- **热更内容的范围边界与确定性张力：** overlay 是否允许**新增 `Id`**（会让旧客户端存档引用未知内容）？run 进行中 overlay 更新时，是否需**冻结该 run 的 `contentVersion`** 以保证 seed 可复现？→ `services/content-service.md`。
- **断线降级的具体行为：** push / pull / 剧本请求失败时阻塞玩家、本地缓冲重试、还是回退存档点？→ `services/sync-service.md`、`services/account-service.md`。
- **ViewModel 层是否需要单独一份文档：** 三层切分已定案并在本文件显式化；是否为 ViewModel 层单列文档（或归 `40-ux/`）待定。Source: `10-handoffs/2026-07-25b-event-cost-fields-capability-flags-and-service-hierarchy.md`。
- **player-profile「etc.」范围：** 除 player-item / player-power 外是否还有 achievements / account-info / game-setting 等子类型待确认。Source: 同上。
- **scoring.md 去向：** 是否并入某系统或在 life+mana 模型下废弃待确认。Source: 同上。
- **enemies 归属：** 当前归 `adventure-event/combat/`；若 Practice 等也用敌人，是否升为共享内容层待确认。Source: 同上。
- **`.claude/knowledge` 引用层改造形态：** 薄引用 vs 提炼摘要 + 回链，影响 sync-knowledge 语义，建议以 ADR 固化。Source: 同上。

## 对应
提炼至：`.claude/knowledge/architecture.md`（引用层；本库为技术结构事实来源，知识库引用之，待改造）。
