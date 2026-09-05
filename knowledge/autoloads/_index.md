# Autoload（服务）索引（引用层）

> **权威：`game-design-documents/systems/services/`**（`_index.md` 层级词表 + 七服务；各服务文档带「API 面（契约）」四列表：方法 | 形态(A/B/C) | 完整签名 | 失败语义）与根级 `program-overview.md`（启动顺序 / 职责矩阵）、`system-overview.md`（代码形态）。**签名、接口、代码块一律去那边看**——此处只留导航与代码现状。

## 代码现状

**尚未注册任何 autoload。** `game-feature-branch/project.godot` 无 `[autoload]` 段。下表是**规划**。

## 七个服务（规划中）

| 服务（autoload） | 一句话职责 | 权威文档 |
|------------------|------|------|
| **account-service** | 登录渠道、token / 会话、实名合规。**无游客入口。** | `services/account-service.md` |
| **content-service** | 基线 + overlay 合并、按 `Id` 索引、flags 通道。**唯一内容读取入口。** | `services/content-service.md` |
| **sync-service** | 启动 Pull、存档点 Push、原子写、schema 迁移。 | `services/sync-service.md` |
| **profile-service** | **两个 Profile 的唯一写入面**；capability 聚合；成就；图鉴收录；能力抽取。 | `services/profile-service.md` |
| **life-cycle-service** | 轮回生命周期、篇章边界与重试、具名 RNG 子流。 | `services/life-cycle-service.md` |
| **future-event-service** | 物化 AdventureEvent → eventOptions（**唯一物化点 / 唯一出口**）。 | `services/future-event-service.md` ⊃ `services/plot-manager.md` |
| **combat-service** | 回合循环、抽 / 弃、双方道念、敌人 AI。**`combatTier` 三档复用同一套代码。** | `services/combat-service.md` |

> **各服务的判据字母与内含 manager 清单去权威文档看**——此处曾复制过一份，结果它比设计库少了两个 manager。判据本身（三选一才够格成为服务）：① 自有状态机 / 跨多帧长流程；② 事务性跨多字段一致写；③ 外部 I/O 边界。

**跨进程边界只有三个服务**（account / content / sync），且**跨边界成分全部是服务本身——`manager` 不跨边界是无例外的结构性事实**（连 `PlotManager` 也不跨）。

**combat-service 的 manager 分区判据：栈与战场是两个区，划线看「是否在场上生效」而非「属于谁」**，TurnManager 因此是纯粹的回合状态机。→ `systems/services/combat-service.md`

**非服务的横切件：** **EventBus**（autoload `Node`，广播既成事实 → `standards/signal-eventbus.md`）、**game-progression**（屏幕流程编排顶点）、**ViewModel**（呈现期对象 → `systems/viewmodel.md`）、**BootstrapScreen**（`main` 场景，驱动启动 → `scenes/_index.md`）。

## 承重纪律

- **服务不持有独立数据** ——只操作 `PlayerProfile` / `CharacterProfile`。manager 是服务持有的普通 C# 对象（非 `Node`，除非确需 `_Process`），类型声明 **`internal sealed`**。
- **边界措辞（精确版）：服务之间不读写对方字段、不伸手进对方 manager；跨服务的方法调用经 `Xxx.Instance.Method(...)` 是允许的。** 编排顶点 game-progression 负责「谁在什么时机调谁」，但**不是**一切跨服务调用的必经中转。
- **`Instance` 为 null = 启动顺序配错** → 属「必需缺失」→ `GD.PushError` + 抛，**不做静默降级**。
- **服务不返回内部可变集合** —— 一律 `IReadOnlyList<T>` / `IReadOnlyDictionary<,>`。
- **后端错误一律以 `code` 为键查表映射成 `OpError`**，不写 switch、不按 HTTP 状态码分支、不解析 `message`；请求头组装 / 应答头解析 / 映射表**收敛在一处**，三个 `HttpXxxBackend` 不各写一遍。→ `systems/architecture.md`「总则 7」
- **`_Ready` 只装配，`InitializeAsync` 才做 I/O**（autoload 的 `_Ready` 不能 `await`，也别写 `async void`）：异步初始化经 `IBootstrappable`，由 `BootstrapScreen` 按序驱动。**装配顺序与初始化顺序的权威都在 `system-overview.md`「三、注册」与「Bootstrap 屏幕」两节，不在此复制。**
- **两条唯一入口：** 内容读取经 `ContentRegistry`（不散落 `ResourceLoader.Load`；**抽取走 `AllEnabled()`**）；档案写入经 `ProfileManager.TryApply(spec)`，**收口前的重算走只读投影 `Project(spec)`，不开第二个写入面**。
- **autoload 一律直接指向 `.cs`，无例外**（不为服务包一层 `.tscn`）⇒ **服务级配置走 ProjectSettings，`[Export]` 只留给场景组件**——没有场景实例，`[Export]` 既无存储处也无检视器落点。这是技术互斥，不是风格偏好。
- **离线 stub 是「换一个实现」，不是在服务里插 `if (offline)`**：三个边界服务各持一个窄后端接口，两份实现经唯一选择点 `BackendSelector` 取得，`OfflineXxxBackend` 整类包在 `#if DEBUG` 内（Release 里不存在），开关走 ProjectSettings 而非 `[Export]`。→ `systems/architecture.md`「总则 7」、`system-overview.md` 第四节

## 装配顺序（规划）

**EventBus → content → account → sync → profile → life-cycle → future-event → combat**（已定案，与 `system-overview.md` 的 `[autoload]` 块逐行一致）。注意这只解决**装配**顺序；**初始化**顺序另由 `BootstrapScreen` 按 `IBootstrappable` 驱动。→ `system-overview.md`

## 如何添加一条 autoload 说明

服务落地后，在此记录：它的 autoload 注册名与路径、内含 manager、是否实现 `IBootstrappable`、启动顺序依赖。**API 契约表写在设计库的服务文档里，不在这里复制。**
