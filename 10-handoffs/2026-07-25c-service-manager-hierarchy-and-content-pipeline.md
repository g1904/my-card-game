# 服务 / 管理器两级层次 · 拆分轴定案 · 内容资产管线与本地云端分界 · 程序运行总览

- id: 2026-07-25c-service-manager-hierarchy-and-content-pipeline
- date: 2026-07-25
- topic: services 全树（两级层次 service ⊃ manager；新增 account-service / content-service / sync-service / profile-service / combat-service；adventure-plot-service 降级为 PlotManager）, 拆分轴原则（生命周期层 + 行为边界，非数据类型）, 内容资产管线（res:// 基线 + user:// overlay + 云端版本校验）, 本地 / 云端内容分界（闭环缺口 4）, **术语修正：废弃「微服务」措辞**, program-overview.md + system-overview.md（新增两份根级总览）
- status: distilled
- distilled-to: program-overview.md, system-overview.md, terminology.md, 20-systems/services/_index.md, 20-systems/services/account-service.md, 20-systems/services/content-service.md, 20-systems/services/sync-service.md, 20-systems/services/profile-service.md, 20-systems/services/combat-service.md, 20-systems/services/plot-manager.md, 20-systems/services/life-cycle-service.md, 20-systems/services/future-event-service.md, 20-systems/architecture.md, 20-systems/common-properties.md, 20-systems/_index.md, 20-systems/player-profile/_index.md, open-questions.md, README.md, 10-handoffs/_index.md

## Intent（distilled）

一次**架构层次定案**：确立 service / manager 两级结构，据此重构服务清单并闭合 `2026-07-25b` 体检中的多数缺口；确定内容资产的存储形态与本地 / 云端分界；产出一份根级的程序运行总览供随时对照。

### 1. 两级层次：service ⊃ manager（已定案）

先前所有职能一律称「服务」，导致粒度失控——既想为 `PlayerPower` / `PlayerItem` / 卡牌 / 资源各开一个服务，又发现它们只是 CRUD 包装。**根因是缺少一个比服务更小的层级。** 现补上：

- **service（服务）= 边界单元。** 一个职能值得成为服务，当且仅当命中以下**三条判据之一**：
  1. 它拥有**自己的状态机或跨多帧的长流程**；
  2. 它需要**事务性地跨多个字段一致写入**（全有或全无）；
  3. 它坐在一个**外部 I/O 边界**上（网络、存档、平台 SDK）。
- **manager（管理器）= 服务内部的职能组件。** 多个 manager 生活在同一个服务里，**共享宿主服务的事务边界与生命周期**。manager **不被跨服务直接调用**——外部只看得见宿主服务的 API 面。
- **落地形态：** 服务以 Godot autoload 形式存在；manager 是服务持有的普通 C# 对象（不是 Node，除非确需 `_Process`）。

据此，先前三个「服务」中有一个降级：**adventure-plot-service → PlotManager**，隶属 future-event-service（它本就被判定为「不直接写 eventOptions、不对外暴露」的内部调制源——那正是 manager 的定义）。

### 2. 拆分轴定案：生命周期层 + 行为边界，**不是数据类型**（已定案）

曾考虑的 `power-collection-service` / `item-collection-service` / `card-collection-service` / `resource-collection-service` **被否决**。三条理由：

1. **撕碎事务。** 本作几乎没有「只改一种资源」的操作——一次 Exchange 结算典型是 `-灵玉 -寿元 +卡牌 +道具 + 推拉隐藏属性`。按类型拆开后调用方要手动编排 N 次写，还得自己保证「付不起第三项时前两项回滚」与「N 次写只提交一次存档」。而已定的 `selectCost`**复合成本类型（element 列表）**的天然消费者是**一个**统一施加点，不是 N 个服务。
2. **横切生命周期层。** `PlayerItem`（账号级、跨轮回、失败不清）与 `CharacterItems`（轮回级、`defeated` 即清）持久化语义与清理规则完全不同；一个 `item-collection-service` 会同时管两者，边界比拆分前更糟。
3. **贫血 CRUD。** 只有 `Add / Remove / Get / Count` 而无规则的服务，规则仍留在调用方——服务层没有承担任何东西。

**同理否决「每类 AdventureEvent 一个服务」。** 九类中只有 **Combat** 真有自己的状态机；Practice / Research / Social / Explore / Exchange / Travel / Mystery 共享同一形状（呈现 → 选择或跳过 → 校验扣成本 → 应用产出 → 推拉隐藏属性 → 收口），差异在**数据**而非**代码**。为其各建服务违反 `data-resource-rules.md` 的可加性原则（新增内容 = 新增 `.tres`，而非新增代码 / 服务）。Finale 复用 combat-service 的状态机；Mystery 揭示后落到真实 `eventType`。

**用户的原始诉求仍然成立且已被满足**——「内容数据有统一入口、同类内容有标准操作接口」的正确形态是 **content-service 的 ContentRegistry + 泛型仓储接口**（见第 4 节），而非按类型开服务。

### 3. 服务清单（七个）与 manager 归属（已定案）

| 服务 | 命中判据 | 内含 manager |
|------|---------|-------------|
| **account-service** | ③ I/O 边界 | AuthManager、ComplianceManager |
| **content-service** | ③ I/O 边界 + 启动流程 | ContentRegistry、ContentUpdateManager |
| **sync-service** | ②③ | ProfileSyncManager、LocalCacheManager、MigrationManager |
| **profile-service** | ② 事务性跨字段一致写 | **ProfileManager**、**CapabilityManager**、AchievementManager |
| **life-cycle-service** | ① 状态机 | CycleStateManager、ChapterManager、SeedManager |
| **future-event-service** | ① 长流程 | EventOptionManager、**PlotManager** |
| **combat-service** | ① 状态机 | TurnManager、DeckManager、IntentManager |

- **profile-service 同时拥有两层 profile（用户确认）。** 因 `PlayerProfile ⊃ List<CharacterProfile>`，由**单一 profile-service** 作为两个 profile 的**唯一写入面**；life-cycle-service / combat-service / future-event-service 都只经它写档。好处：「扣账号级 PlayerItem 次数 + 扣轮回级灵玉」天然落在同一事务内，存档提交点唯一。
- **ProfileManager**（原议名 ProfileMutator）是那个统一施加点：`TryApply(spec)` 先全量校验所有 cost element 是否付得起，再一次性提交——**全有或全无**，不产生半成品状态。modifier pipeline 在它读取每个 element 数值的那一刻生效，因此 PlayerPower 的全局数值修正不需要任何消费层写 `if (hasPowerX)`。
- **CapabilityManager** 是 `2026-07-25b` 第 6 节 capability flag 聚合面的宿主（此前无归属）。
- **编排顶点 = game-progression（已定案，闭合缺口 7）。** 它不是服务，是屏幕流程编排层：核心循环 `ComputeEventOptions → 呈现 → 玩家选择 → AdvanceEvent → 重算` 由它串联。**服务之间不互相直呼**，只经编排顶点调用或经 EventBus 广播既成事实。

### 4. 内容资产管线：三层 + 统一仓储接口（已定案）

**存储形态（用户选定：随包内置 + user:// 覆盖层）：**

```
res://content/**.tres        基线内容，随版本发布，只读，保证首启可用 / 离线可读
user://overlay/**.tres       云端下发的增量，可热更，按 Id 覆盖基线
      ↓ 合并（overlay 优先，res:// 兜底）
内存 ContentRegistry         按 Id 索引，全游戏唯一读取入口
```

- `res://content/manifest.json` 携带 `contentVersion` 与逐条目 hash；启动时 ContentUpdateManager 比对云端版本，有更新则下载增量到 `user://overlay/`。
- **合并后统一校验**（重复 Id、悬空交叉引用）→ `GD.PushError` 启动期早失败。热更并未削弱这条纪律，只是把校验点从「加载 res://」后移到「合并完成后」。
- **统一操作接口（回应「同类内容的标准操作接口」诉求）：** ContentRegistry 为每种 `XxxData : Resource` 持有一个仓储，对外是同一形状——`Get(id)` / `TryGet(id, out)` / `All()` / `Where(pred)`。所有服务经此取内容，**代码中不散落 `ResourceLoader.Load`**。
- 收益：平衡数值、事件定义、卡牌数值可**热更而不发版**（规避微信 / App Store 审核周期）；同时保留启动期强校验与离线首启能力。

### 5. 本地 / 云端内容分界（已定案，闭合缺口 4）

一条判据划清：

- **有稳定 `Id`、被存档引用、需启动期校验** → **本地内容层**（`res://` 基线 + `user://overlay/` 热更）。含 `AdventureEventData`、`CardData`、`EnemyData`、`ItemData`、`PlayerPowerData`、平衡表，**以及它们的静态展示文案**。
- **按进度动态请求、一次性呈现、不被存档引用** → **云端剧本服务下发**。即 AdventurePlot 的剧本分支文本与揭示内容，由 PlotManager 按 `CharacterProfile` 的 key points 请求，只在呈现期存在，**不进 ContentRegistry、不落存档**。

因此 **AdventureEvent 的定义本身属本地内容层**——DataRegistry / ContentRegistry「启动期缺失或悬空 Id 立即失败」的模型得以保留；云端只下发剧本文本。

### 6. Profile 的存储与同步（已定案）

- **`PlayerProfile ⊃ List<CharacterProfile>`**（结构确认）。云端是权威主档。
- **启动时全量 pull** 一次；轮回内每个自动存档点 **push**。冲突一律**以云端为准**（ADR-0003）。
- 本地 `user://cache/` 仅作缓存与断线临时态：**原子写**（临时文件 → rename 覆盖）、带 **schema 版本**、读取时校验版本与内容 Id，不匹配则迁移或清晰拒绝。
- 归属：sync-service 的 ProfileSyncManager（上下行与冲突）、LocalCacheManager（原子写）、MigrationManager（版本迁移）。这闭合了缺口 3。

### 7. 术语修正：废弃「微服务」措辞（已定案）

**「微服务」是误导性用词，全库废弃。** 七个 service **全部在同一个 Godot 项目、同一个二进制、同一个进程内**，彼此是**直接的 C# 方法调用**——没有网络、没有序列化、没有独立部署单元。

- **准确定义：** service = **一个有明确边界的进程内模块单例**（autoload）；manager = 服务持有的普通 C# 对象（非 `Node`）。
- **借用「服务」一词的价值不在分布式部署，而在边界纪律**（不互相读写字段、唯一入口、经编排顶点或 EventBus）——靠约定与代码审查执行，不靠网络强制。
- **唯一真实的进程边界是客户端 ↔ 后端。** 七个服务中只有 `account-service`、`content-service`、`sync-service` 与 `future-event-service` 内部的 `PlotManager` 跨越它；`profile-service` / `life-cycle-service` / `combat-service` **纯本地，永不发网络请求**。
- 全库活文档已统一改为「服务（进程内模块单例）」；`terminology.md` 补入 `service` / `manager` / `backend` 三条词条。

### 8. 两份根级总览（新增文档）

- **`program-overview.md`（运行时视角）：** 从启动、登录、内容校验、主界面、开轮回、核心循环、战斗、结算到轮回结束的**端到端调用链**，以及服务 / 管理器职责矩阵。回答「代码怎么跑起来」。
- **`system-overview.md`（工程视角）：** 进程边界图、Godot 工程文件夹布局（`src/Services/<服务>/` 一个文件夹一个服务及其全部 manager）、`project.godot` 的 autoload 注册（**声明顺序即启动依赖顺序**）、service / manager 的代码形态与跨服务调用示例。回答「这些服务在工程里长什么样」。
- `20-systems/architecture.md` 保持为**结构与边界的权威**，两份总览是它的两个视角对照面。

**由 `system-overview.md` 顺带确立的一条开发策略：** `account-service` / `content-service` / `sync-service` 是纯边界门面，可提供**离线 stub 实现**，让整个游戏在**后端尚未存在**时先端到端跑起来。这对当前阶段（后端未开工）是关键。

### 9. 缺口状态更新（对照 `2026-07-25b` 第 7 节）

| 缺口 | 状态 |
|------|------|
| 1. PlayerProfile 侧无服务 | **闭合** → profile-service（ProfileManager / CapabilityManager / AchievementManager） |
| 2. 战斗无归属 | **闭合** → combat-service（唯一自带状态机的事件类型；Finale 复用） |
| 3. 存档 / 云同步无归属 | **闭合** → sync-service |
| 4. 本地 / 云端内容分界 | **闭合** → 见第 5 节判据 |
| 5. skip 无结算归属 | **闭合** → 复用 `AdvanceEvent` 的分支，经同一个 ProfileManager 施加 `skipCost`；skip 的**玩法语义**（是否计入修行历程 / 是否照扣寿元）仍未定 |
| 6. `selectCost` / `lifeSpanCost` 重叠 | 已于 07-25b 闭合（包含关系）；ProfileManager 是其唯一消费点 |
| 7. 编排顶点缺失 | **闭合** → game-progression |
| 8. UI 契约层 | 已于 07-25b 闭合（ViewModel） |

## Open questions

- **各服务的具体 API 签名仍未定。** 七个服务与其 manager 的职责边界已定，但方法签名、返回类型、事件负载 schema 仍是意图草图。→ `20-systems/architecture.md`、`20-systems/services/*`。
- **cost element 清单未定（沿袭自 07-25b）。** ProfileManager 的 `TryApply` 形状取决于它——有哪些 element（jade / mana / 道具 / 隐藏属性推拉？）、数据形态（固定值 / 区间 / 公式）。「付不起时整体不可选」已由**全有或全无**的事务语义确定，但「是否允许部分抵扣」仍未定。→ `20-systems/adventure-event/common-properties.md`。
- **热更内容的范围边界。** overlay 可覆盖哪些字段？允许热更**新增** Id（新卡 / 新事件）还是仅允许改既有条目的数值 / 文案？新增 Id 会让旧版本客户端的存档引用到未知内容，需要一条兼容规则。→ `20-systems/services/content-service.md`。
- **overlay 与存档的版本耦合。** 若某个轮回进行中 overlay 被更新（数值变了），进行中的 CharacterProfile 是否需要冻结其 `contentVersion` 以保证 seed 可复现？确定性要求（同一 seed 复现同一轮回）与热更存在张力。→ `20-systems/services/content-service.md`、`20-systems/common-properties.md`。
- **断线降级的具体行为。** 强制在线下，push 失败 / 剧本请求失败时：阻塞玩家、本地缓冲后重试、还是回退到上一个存档点？→ `20-systems/services/sync-service.md`。
- **combat-service 与 `eventStart` / `eventEnd` 的职责边界。** Combat 事件的 `eventStart` 是直接把控制权交给 combat-service，还是 combat-service 由 life-cycle-service 直接驱动？→ `20-systems/services/combat-service.md`。
- **account-service 的合规面范围。** ComplianceManager 覆盖实名 / 防沉迷 / 注销 / 数据导出到什么程度，属实现级选型。→ `50-decisions/ADR-0003`。
- **AchievementManager 的触发采集面。** 成就进度靠订阅 EventBus 被动采集，还是由各服务主动上报？前者解耦但易漏，后者反向依赖。→ `20-systems/services/profile-service.md`。

## Notes / triage

- 第 1 / 2 / 3 节是应用户「service 与 manager 有层级之分」的判断补全的层次定案；第 3 节 profile-service 拥有两层 profile、第 4 节内容载体形态均由用户在选项中明确选定；第 7 节的术语修正与第 8 节的 `system-overview.md` 由用户明确要求。
- 第 2 节记录了**被否决的方案**（按数据类型拆服务、按事件类型拆服务）及其理由——保留否决理由是为了防止同一诱惑复发，不属于「考古」。
- 本次闭合了 `2026-07-25b` 体检 8 处缺口中的 5 处（1/2/3/4/7），缺口 5 部分闭合（归属已定，玩法语义待定）。
- 新增根级 `program-overview.md`，与 `terminology.md` / `open-questions.md` 同级，作为运行时视角的对照面。
