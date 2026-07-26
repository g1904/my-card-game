# 术语表（Terminology）

> 开发中使用的专有术语事实来源：中文领域词 ↔ 英文 / 代码标识符。随开发滚动更新。
> 代码标识符沿用此处的英文 / 代码列（`csharp-godot-rules.md` 的 PascalCase 命名）。
> 提炼至：`.claude/knowledge/dictionary.md`。

## 核心结构

| 中文 | 英文 / 代码 | 含义 | 来源 |
|------|------------|------|------|
| 修行事件 | AdventureEvent | 逐时逐刻的游玩单元；玩家从当前可用项中择一以推进 run。 | `10-handoffs/2026-07-15b-taxonomy-and-checkpoint-clarifications.md` |
| 修行历程 | （集合，`List<AdventureEvent>`） | 一个角色走过 / 可走的整段修行旅程（修行事件的序列 / 图）。 | 同上 |
| 玩家信息 | PlayerProfile | 账号级主档，跨 run 持久，持有一组 CharacterProfile 及账号级元数据。 | `10-handoffs/2026-07-15-adventure-event-profiles.md` |
| 角色信息 | CharacterProfile | 单次 run / 单个角色的状态与历史（对齐 RunState 概念）。 | 同上 |
| 玩家能力 | PlayerPower | 账号级 always-available 能力，带开关（默认开启）；QoL 或影响公平性的全局加强，不与角色绑定，可获取 / 失去。 | `10-handoffs/2026-07-22-online-cloud-combat-and-meta-clarifications.md` |
| 玩家道具 | PlayerItem | 账号级、有使用次数限制的道具。 | 同上 |
| 生命 · 法力 | life + mana | 战斗双资源模型（参考 MTG / Hearthstone）：生命为血量，mana 为每回合出牌资源。**无 mana 曲线**，采用「上限 + 逐步恢复」；炼气基线 life=10/10、mana=5/5。对齐 `Status.currentHealth / currentMana`。 | 同上 + `10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md` |
| 道心 | faith | **隐藏数值属性**（原 `faith` / 信仰即时属性，现归为隐藏）；与 煞气 / 寿元 同属驱动 AdventurePlot 的隐藏属性。 | `10-handoffs/2026-07-15-adventure-event-profiles.md` + 归隐藏 `10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md` |
| 煞气（点数） | malefic qi | **隐藏属性**：积累到阈值触发「煞气反噬」剧情线。 | `10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md` |
| 寿元 | lifeSpan | **隐藏属性**：角色寿命预算（**非血量 life**）——炼气起始 100、抵达筑基 +100、抵达金丹 +300、抵达元婴 +500（累计 1000；元婴为终点，该增量无玩法影响）；初始隐藏、低于 10% 时显示；每完成一个 AdventureEvent 按其 `lifeSpanCost`（默认 -1）扣减，**递减到 0 → 「大限将至」→ 角色 defeated**。 | 同上 + `10-handoffs/2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md` + `10-handoffs/2026-07-25b-event-cost-fields-capability-flags-and-service-hierarchy.md` |
| 寿元消耗 | lifeSpanCost | **成本类型 `selectCost` 的一个 element**：完成该事件对角色寿元的扣减，**基准 -1**；可按事件覆写。 | `10-handoffs/2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md` + `10-handoffs/2026-07-25b-event-cost-fields-capability-flags-and-service-hierarchy.md` |
| 事件类型 | eventType | AdventureEvent 的共有字段：该事件归属九类子类型中的哪一类。 | `10-handoffs/2026-07-25b-event-cost-fields-capability-flags-and-service-hierarchy.md` |
| 选择成本 | selectCost | AdventureEvent 的共有字段，且是一个**定制的复合成本类型**：由若干成本 element 组成（`lifeSpanCost` 为其中之一），表示选中该事件以推进 run 所需付出的代价。 | 同上 |
| 跳过成本 | skipCost | AdventureEvent 的共有字段：**跳过**该事件所需付出的代价；**与 `selectCost` 同为上述复合成本类型**（同一套 element 体系，数值取向不同）。 | 同上 |
| 是否强制 | ifMandatory | AdventureEvent 的共有字段：为真则该事件**不可跳过**（必须面对）。 | 同上 |
| 能力标记 | capability flag | PlayerPower 授予的具名布尔标记（如「显示隐藏属性」），由中心聚合面按 `status` 汇总为**生效能力集**，消费侧单点查询。 | 同上 |
| 修正管线 | modifier pipeline | PlayerPower 注册的**具名数值修正**（`lifeSpanCost`、商店价格等）的统一施加入口 `Apply(key, baseValue)`，取代各消费层的散落条件。 | 同上 |
| 展示模型 | ViewModel | 呈现期由 `Data + 运行时状态` 组装的展示对象；**不落存档、不进云端负载**，是「服务 → 屏幕」的数据形态契约。 | 同上 |
| 可选事件集 | eventOptions | 一组当前可选的 `AdventureEvent`，玩家从中择一以推进 run；由 future-event-service 依当前 CharacterProfile 产出、每个事件后重算。 | `10-handoffs/2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md` |
| 境界突破 · 高潮 | AdventureEvent-Finale | 篇章边界的境界突破事件；分类法**第七类，独立于 Combat**（ADR-0002 07-23 修订）。 | 同上 |
| 修行剧情（体系） | AdventurePlot | 隐藏剧本层的总称：由分支可能性构成、在背景中运行、**调制 future-event-service 产出的 eventOptions**；可像 DnD 那样让玩家选分支。下含 Story / Chapter / SideChapter / SideStory 四级。由 PlotManager 提供 API。 | 同上 |
| 主线剧本 | AdventurePlot-Story | 贯穿**三大篇章**相连的**大剧本**（一条角色的完整主线故事）。 | 同上 |
| 篇章剧本 | AdventurePlot-Chapter | **单个篇章**对应的剧本单元（一个 Story 含三个 Chapter）。 | 同上 |
| 支线（篇章内） | AdventurePlot-SideChapter | 在**单个 Chapter 内**穿插的小型支线剧本。 | 同上 |
| 支线（跨篇章） | AdventurePlot-SideStory | **跨篇章**穿插的支线剧本。 | 同上 |
| 剧情节点 | AdventurePlot key points | Character 上记录的 AdventurePlot **关键节点 / 进度锚点**（完整剧本与分支内容不落在存档，见「剧本服务」）。 | 同上 |
| 剧本服务 | script service | 存储**全部 AdventurePlot 剧本与分支内容**的（云端）服务；客户端按 key points 向其请求完整剧本 / 分支。 | 同上 |
| 服务 | service | **进程内模块单例**（**不是**微服务：同一二进制、同一进程、直接方法调用）。**边界单元**，判据三选一：① 自有状态机 / 长流程 ② 事务性跨字段一致写 ③ 外部 I/O 边界。以 autoload 存在，彼此不互相读写字段。 | `10-handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md` |
| 管理器 | manager | **服务内部的职能组件**（普通 C# 对象，非 `Node`）；共享宿主服务的事务边界与生命周期，**不被跨服务直接调用**。 | 同上 |
| 后端 | backend | 客户端之外的**唯一真实进程边界**：账号鉴权 · 档案存储 · 剧本下发 · 内容分发。另一套代码库，不在本项目内。 | 同上 |
| 编排顶点 | game-progression | 屏幕流程编排层（**不是服务**）：串联核心循环 `ComputeEventOptions → 呈现 → 选择 → AdvanceEvent → 重算`。 | 同上 |
| 账号服务 | account-service | 服务：登录渠道、token / 会话、合规（AuthManager、ComplianceManager）。 | 同上 |
| 内容服务 | content-service | 服务：`res://` 基线 + `user://overlay/` 热更的合并与按 `Id` 索引；**唯一内容读取入口**（ContentRegistry、ContentUpdateManager）。 | 同上 |
| 同步服务 | sync-service | 服务：档案 Pull / Push、本地原子写、schema 迁移（ProfileSyncManager、LocalCacheManager、MigrationManager）。 | 同上 |
| 档案服务 | profile-service | 服务：`PlayerProfile` 与 `CharacterProfile` 的**唯一写入面**；capability 聚合；成就（ProfileManager、CapabilityManager、AchievementManager）。 | 同上 |
| 生命周期服务 | life-cycle-service | 服务：run 生命周期（开始 seed、推进、胜/负、清理、篇章继承、状态机、重试）。（RunStateManager、ChapterManager、SeedManager） | `10-handoffs/2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md` |
| 未来事件服务 | future-event-service | 服务：依当前 CharacterProfile 产出 eventOptions，每个事件后重算；**eventOptions 唯一出口**。（EventOptionManager、PlotManager） | 同上 |
| 隐藏剧本管理器 | PlotManager | **管理器，隶属 future-event-service**：隐藏属性驱动、key points ↔ 云端剧本服务、eventOptions 调制、DnD 式选分支。 | `10-handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md` |
| 战斗服务 | combat-service | 服务：回合循环、抽/弃/洗、敌人意图；**Finale 复用其状态机**。（TurnManager、DeckManager、IntentManager） | 同上 |
| 内容注册表 | ContentRegistry | content-service 的管理器：合并后按 `Id` 索引，暴露泛型仓储接口 `Get` / `TryGet` / `All` / `Where`。 | 同上 |
| 档案管理器 | ProfileManager | profile-service 的管理器：`TryApply(spec)` 原子施加成本 / 产出（**全有或全无**）；modifier pipeline 的生效点。 | 同上 |
| 内容覆盖层 | content overlay | `user://overlay/` 下由云端下发、按 `Id` 覆盖 `res://` 基线的热更内容增量。 | 同上 |
| 内容版本 | contentVersion | `manifest.json` 携带的内容版本号；启动时与云端比对以决定是否下载增量。 | 同上 |
| 地域 | location | **抽象概念**：角色当前所在地点，**框定 eventOptions**（决定下一批可能出现的修行事件池）；由 Travel 事件刷新。归属 `20-systems/game-progression.md`。 | `10-handoffs/2026-07-24-docs-restructure-class-model.md` |

## 修行事件分类（九类 · 07-24 加入 Explore / Travel；原七类见 ADR-0002）

| 中文 | 英文 / 代码 | 直观含义 |
|------|------------|----------|
| 修炼 | Practice | 比试 / 切磋——低风险战斗式历练 |
| 战斗 | Combat | 正式回合制战斗遭遇 |
| 闭关 | Research | 钻研 / 潜修 |
| 交易 | Exchange | 交易 / 商店 |
| 社交 | Social | 与 NPC / 势力的社交互动 |
| 未知 | Mystery | **元类型**：进入后才揭示为其余某一类；揭示的是一个**固定的** AdventureEvent，而非点击时临时生成 |
| 境界突破 | Finale | **篇章边界高潮**：渡劫 / 突破，独立于 Combat 的结算（07-23 加入的第七类） |
| 探索秘境 | Explore | **探索一处秘境**（07-24 加入的第八类） |
| 前往某处地点 | Travel | **地图路由选择**：刷新角色所在的 location（地域）（07-24 加入的第九类） |

> 休养 / Rest 不单列，并入 战斗 或 闭关。原七类定案见 `50-decisions/ADR-0002-adventure-event-taxonomy.md`；**07-24 加入 Explore / Travel 为第八、九类**（`10-handoffs/2026-07-24-docs-restructure-class-model.md`；ADR-0002 待补订）。
> **Mystery = 遮罩一个固定 AdventureEvent**（非点击时生成）。Source: `10-handoffs/2026-07-24-docs-restructure-class-model.md`。
> **境界突破 = `AdventureEvent-Finale`**（篇章边界高潮），已作为**第七类并入 ADR-0002 枚举**，独立于 Combat。Source: `10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。

## 修行阶梯（境界 · realm）

| 中文 | 英文 / 代码 | 说明 |
|------|------------|------|
| 炼气 | Qi Refining | 第一境 |
| 筑基 | Foundation Establishment | 第二境 |
| 金丹 | Golden Core | 第三境 |
| 元婴 | Nascent Soul | 第四境（终点 / 奖杯） |
| 篇章 | Chapter | 相邻两境之间的一段攀登；一次 run 含三个篇章。 |

> 来源：`10-handoffs/2026-07-13.md`。
