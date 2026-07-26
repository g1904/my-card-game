# services —— 服务层索引

> 服务层：对 `character-profile` / `player-profile` 两个核心「类」提供操作面。**服务不持有独立数据**；跨系统解耦事件走 EventBus。
> 运行时端到端调用链见根级 `program-overview.md`；工程落地形态见根级 `system-overview.md`；结构与边界权威见 `20-systems/architecture.md`。

## 术语：service = 进程内模块单例，**不是**微服务

**七个 service 全部在同一个 Godot 项目、同一个二进制、同一个进程里**，彼此之间是**直接的 C# 方法调用**——没有网络、没有序列化、没有独立部署单元。服务以 **autoload** 形式存在，manager 是服务持有的普通 C# 对象（非 `Node`）。

借用「服务」一词的价值**不在于分布式部署**，而在于那套**边界纪律**（服务之间不互相读写字段、唯一入口、经编排顶点或 EventBus 通信）——靠约定与代码审查执行，不靠网络强制。

**唯一真实的进程边界**是客户端 ↔ 后端：七个服务中只有 `account-service`、`content-service`、`sync-service` 与 `future-event-service` 内部的 `PlotManager` 会跨越它；其余三个纯本地。工程结构、autoload 注册与代码形态见 `system-overview.md`。Source: `10-handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md`。

## 两级层次：service ⊃ manager（已定案）

代码里只有两级职能层次，判据明确、不设第三级。Source: `10-handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md`。

- **service（服务）= 边界单元。** 一个职能值得成为服务，当且仅当命中**三条判据之一**：
  1. 拥有**自己的状态机或跨多帧的长流程**；
  2. 需要**事务性地跨多个字段一致写入**（全有或全无）；
  3. 坐在一个**外部 I/O 边界**上（网络、存档、平台 SDK）。
  服务以 Godot **autoload** 形式存在。**服务之间不互相读写字段**——只经编排顶点调用，或经 EventBus 广播既成事实。
- **manager（管理器）= 服务内部的职能组件。** 多个 manager 生活在同一服务里，**共享宿主服务的事务边界与生命周期**；**不被跨服务直接调用**——外部只看得见宿主服务的 API 面。manager 是服务持有的普通 C# 对象（非 `Node`，除非确需 `_Process`）。

## 拆分轴：生命周期层 + 行为边界，**不是数据类型**（已定案）

**不**按 `power` / `item` / `card` / `resource` 各开一个服务。三条理由：

1. **撕碎事务。** 本作几乎没有「只改一种资源」的操作——一次 Exchange 结算典型是 `-金币 -寿元 +卡牌 +道具 + 推拉隐藏属性`。按类型拆开后调用方要手动编排 N 次写，还得自己保证「付不起第三项时前两项回滚」与「N 次写只提交一次存档」。已定的 `selectCost` **复合成本类型（element 列表）**的天然消费者是**一个**统一施加点。
2. **横切生命周期层。** `PlayerItem`（账号级、跨 run、失败不清）与 `CharacterItems`（run 级、`defeated` 即清）的持久化语义与清理规则完全不同；一个 `item-collection-service` 会同时管两者，边界比拆分前更糟。
3. **贫血 CRUD。** 只有 `Add / Remove / Get / Count` 而无规则的服务，规则仍留在调用方——服务层没有承担任何东西。

**同理不为九类 AdventureEvent 各开服务。** 只有 **Combat** 真有自己的状态机；Practice / Research / Social / Explore / Exchange / Travel / Mystery 共享同一形状（呈现 → 选择或跳过 → 校验扣成本 → 应用产出 → 推拉隐藏属性 → 收口），差异在**数据**而非**代码**。为其各建服务违反可加性原则（新增内容 = 新增 `.tres`，而非新增代码 / 服务）。**Finale 复用 combat-service 的状态机**；**Mystery** 揭示后落到真实 `eventType`。

「同类内容的统一入口与标准操作接口」这一诉求由 **content-service 的 ContentRegistry + 泛型仓储接口**满足（见 `content-service.md`），而非按类型开服务。

## 服务清单

| 服务 | 判据 | 内含 manager | 文档 |
|------|------|-------------|------|
| **account-service** | ③ | AuthManager、ComplianceManager | [account-service](account-service.md) |
| **content-service** | ③ | ContentRegistry、ContentUpdateManager | [content-service](content-service.md) |
| **sync-service** | ②③ | ProfileSyncManager、LocalCacheManager、MigrationManager | [sync-service](sync-service.md) |
| **profile-service** | ② | ProfileManager、CapabilityManager、AchievementManager | [profile-service](profile-service.md) |
| **life-cycle-service** | ① | RunStateManager、ChapterManager、SeedManager | [life-cycle-service](life-cycle-service.md) |
| **future-event-service** | ① | EventOptionManager、PlotManager | [future-event-service](future-event-service.md) ⊃ [plot-manager](plot-manager.md) |
| **combat-service** | ① | TurnManager、DeckManager、IntentManager | [combat-service](combat-service.md) |

**编排顶点 = game-progression**（不是服务，是屏幕流程编排层）。核心循环 `ComputeEventOptions → 呈现 → 玩家选择 → AdvanceEvent → 重算` 由它串联；服务之间不互相直呼。见 `20-systems/game-progression.md`。

## 两条唯一入口

- **内容读取的唯一入口 = content-service.ContentRegistry。** 代码中不散落 `ResourceLoader.Load`。
- **档案写入的唯一入口 = profile-service.ProfileManager。** 两个 Profile 的一切变更经 `TryApply(spec)`：全量校验 → 全有或全无 → 单点提交。life-cycle-service / combat-service / future-event-service 都只经它写档。

## 待决问题

- **各服务的具体 API 签名未定。** 职责边界已定，但方法签名、返回类型、事件负载 schema 仍是意图草图。→ `20-systems/architecture.md`。Source: `10-handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md`。
