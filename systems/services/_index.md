# services —— 服务层索引

> 服务层：对 `character-profile` / `player-profile` 两个核心「类」提供操作面。**服务不持有独立数据**；跨系统解耦事件走 EventBus。
> 运行时端到端调用链见根级 `program-overview.md`；工程落地形态见根级 `system-overview.md`；结构与边界权威见 `systems/architecture.md`。

## 术语：service = 进程内模块单例，**不是**微服务

**七个 service 全部在同一个 Godot 项目、同一个二进制、同一个进程里**，彼此之间是**直接的 C# 方法调用**——没有网络、没有序列化、没有独立部署单元。服务以 **autoload** 形式存在，manager 是服务持有的普通 C# 对象（非 `Node`）。

借用「服务」一词的价值**不在于分布式部署**，而在于那套**边界纪律**（不读写对方字段、不伸手进对方 manager、唯一入口、既成事实经 EventBus 广播）——靠约定与代码审查执行，不靠网络强制。

**唯一真实的进程边界**是客户端 ↔ 后端：七个服务中只有 `account-service`、`content-service`、`sync-service` 会跨越它；其余四个纯本地。**跨边界成分全部是服务本身——`manager` 不跨边界是无例外的**：剧本内容属本地内容层，故连 `PlotManager` 也不跨边界。工程结构、autoload 注册与代码形态见 `system-overview.md`。

Source: `handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md` · `handoffs/2026-08-11-plot-content-localization.md`

## 层级：service ⊃ manager ⊃ module ⊃ processor ⊃ handler

**抽象层次不封顶在两级**，但每一级都有固定的层级词——**名字的后缀即宣告它在第几层**：service（第一级）→ manager（第二级）→ module（第三级）→ processor（第四级）→ handler（第五级）。第四 / 第五级目前无实例，定名以免各处自造词。层级表与纪律见 `systems/architecture.md`。

- **service（服务）= 边界单元。** 一个职能值得成为服务，当且仅当命中**三条判据之一**：
  1. 拥有**自己的状态机或跨多帧的长流程**；
  2. 需要**事务性地跨多个字段一致写入**（全有或全无）；
  3. 坐在一个**外部 I/O 边界**上（网络、存档、平台 SDK）。
  服务以 Godot **autoload** 形式存在。**边界纪律（已定案的准确措辞）：服务之间不读写对方字段、不伸手进对方 manager；跨服务的方法调用（经对方门面 `Xxx.Instance.Method(...)`）允许。**
- **manager（管理器）= 服务内部的职能组件。** 多个 manager 生活在同一服务里，**共享宿主服务的事务边界与生命周期**；**不被跨服务直接调用**——外部只看得见宿主服务的 API 面。manager 是服务持有的普通 C# 对象（非 `Node`，除非确需 `_Process`）。
- **module（模块）= manager 内部的组件。** 同样共享宿主服务的事务边界；**不跨层直呼**——它是宿主 manager 的内部实现，服务门面上看不见它。现有唯一实例：`DeckModule`。

Source: `handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md` · `handoffs/2026-07-27b-service-api-contracts.md` · `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`

## 拆分轴：生命周期层 + 行为边界，**不是数据类型**

**不**按 `power` / `item` / `card` / `resource` 各开一个服务。三条理由：

1. **撕碎事务。** 本作几乎没有「只改一种资源」的操作——一次 Exchange 结算典型是 `-灵石 -寿元 +卡牌 +道具 + 推拉隐藏属性`。按类型拆开后调用方要手动编排 N 次写，还得自己保证「付不起第三项时前两项回滚」与「N 次写只提交一次存档」。已定的 `selectCost` **复合成本类型（element 列表）**的天然消费者是**一个**统一施加点。
2. **横切生命周期层。** `PlayerItem`（账号级、跨轮回、失败不清）与 `CharacterItem`（轮回级、`defeated` 即清）的持久化语义与清理规则完全不同；一个 `item-collection-service` 会同时管两者，边界比拆分前更糟。
3. **贫血 CRUD。** 只有 `Add / Remove / Get / Count` 而无规则的服务，规则仍留在调用方——服务层没有承担任何东西。

**同理不为五类 AdventureEvent 各开服务。** 只有 **Combat** 真有自己的状态机；Exchange / Research / Explore / Travel 共享同一形状（呈现 → 择一进入 → 扣成本 → 应用产出 → 推拉隐藏属性 → 收口），差异在**数据**而非**代码**。为其各建服务违反可加性原则（新增内容 = 新增 `.tres`，而非新增代码 / 服务）。**`combatTier` 三档（Practice / Standard / Finale）共用 combat-service 的回合循环与参战方结构（CharacterManager + EnemyManager）与同一个 `CombatEventResolver`**；**Explore** 揭示后落到真实 `eventType`。

「同类内容的统一入口与标准操作接口」这一诉求由 **content-service 的 ContentRegistry + 泛型仓储接口**满足（见 `content-service.md`），而非按类型开服务。

## 服务清单

| 服务 | 判据 | 内含 manager | 文档 |
|------|------|-------------|------|
| **account-service** | ③ | AuthManager、ComplianceManager | [account-service](account-service.md) |
| **content-service** | ③ | ContentRegistry、ContentUpdateManager | [content-service](content-service.md) |
| **sync-service** | ②③ | ProfileSyncManager、LocalCacheManager、MigrationManager | [sync-service](sync-service.md) |
| **profile-service** | ② | ProfileManager、CapabilityManager、AchievementManager | [profile-service](profile-service.md) |
| **life-cycle-service** | ① | CycleStateManager、ChapterManager、SeedManager | [life-cycle-service](life-cycle-service.md) |
| **future-event-service** | ① | EventOptionManager、PlotManager | [future-event-service](future-event-service.md) ⊃ [plot-manager](plot-manager.md) |
| **combat-service** | ① | TurnManager、CharacterManager、EnemyManager、BattlefieldManager、StackManager | [combat-service](combat-service.md) |

> **combat-service 的卡组 = `DeckModule`（第三级）。** 抽 / 弃 / 洗与 seeded 洗牌归**参战方内部的 module**，由 CharacterManager 与 EnemyManager 各自持有，**每个 character / enemy 一份**（敌人也出牌，可带定制卡组）。CharacterManager 与 EnemyManager 共享大量参战方接口，差异只在驱动方式——前者监听玩家操作，后者代理 AI 行为选择。
>
> **战场与栈各自一个 manager。** **BattlefieldManager** 持有 **battlefield（战场）**——场上正在生效的卡牌 / 持续状态 / 触发器注册面；**StackManager** 持有**栈**——压栈、LIFO 结算、连锁触发的解决顺序。**二者是两个区**：栈 = 等待结算的队列，战场 = 已结算并正在生效的东西。**属于某一方的 mana / 道念 / 手牌 / 卡组仍归两个参战方 manager。**

**编排顶点 = game-progression**（不是服务，是屏幕流程编排层）。核心循环 `ComputeEventOptions → 呈现 → 玩家选择 → AdvanceEventAsync → 重算` 由它串联。见 `systems/game-progression.md`。

Source: `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md` · `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md` · `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md`

## 两条唯一入口 + 一个唯一物化点

- **内容读取的唯一入口 = content-service.ContentRegistry。** 代码中不散落 `ResourceLoader.Load`；**抽取一律走 `AllEnabled()`**，读取侧 `Get(id)` 不过滤。
- **档案写入的唯一入口 = profile-service.ProfileManager。** 两个 Profile 的一切变更经 `TryApply(spec)`：全量校验 → 全有或全无 → 单点提交。life-cycle-service / combat-service / future-event-service 都只经它写档。
- **AdventureEvent 物化的唯一点 = future-event-service。** `AdventureEventData` 是模板；`EventOption` 由本服务依情境**物化**产出，**产出即定稿**，其余服务只读消费、不回查模板重算、不改写其字段。见 `systems/architecture.md`「总则 6」。

Source: `handoffs/2026-07-27b-service-api-contracts.md`

## API 契约

七个服务的 API 面是**契约**：八条总则（三种方法形态 / 三分失败语义 + `OpResult` / 服务门面骨架 / Bootstrap 启动契约 / EventBus 强类型事件 / 物化模型 / 后端接口化 / 结算阶段名）与共享核心类型的**权威在 `systems/architecture.md`**；逐服务的方法表在各服务文档的「API 面（契约）」小节，统一为四列 **方法 | 形态(A/B/C) | 完整签名 | 失败语义**。

Source: `handoffs/2026-07-27b-service-api-contracts.md`

## 待决问题

> 各服务的残留待决项见其各自文档；API 契约本身已定案（见上节）。
