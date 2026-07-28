# Autoload（服务）索引（引用层）

> **权威：`game-design-documents/20-systems/services/`**（`_index.md` 两级层次 + 七服务；各服务文档带「API 面（契约）」四列表：方法 | 形态(A/B/C) | 完整签名 | 失败语义）与根级 `program-overview.md`（启动顺序 / 职责矩阵）、`system-overview.md`（代码形态）。**签名、接口、代码块一律去那边看**——此处只留导航与代码现状。

## 代码现状

**尚未注册任何 autoload。** `game-feature-branch/project.godot` 无 `[autoload]` 段。下表是**规划**。

## 七个服务（规划中）

| 服务（autoload） | 判据 | 内含 manager | 一句话职责 |
|------------------|------|-------------|------|
| **account-service** | ③ | AuthManager、ComplianceManager | 登录渠道、token / 会话、实名合规。**无游客入口。** |
| **content-service** | ③ | ContentRegistry、ContentUpdateManager | 基线 + overlay 合并、按 `Id` 索引。**唯一内容读取入口。** |
| **sync-service** | ②③ | ProfileSyncManager、LocalCacheManager、MigrationManager | 启动 Pull、存档点 Push、原子写、schema 迁移。 |
| **profile-service** | ② | ProfileManager、CapabilityManager、AchievementManager | **两个 Profile 的唯一写入面**；capability 聚合；成就。 |
| **life-cycle-service** | ① | CycleStateManager、ChapterManager、SeedManager | 轮回生命周期、篇章边界与重试、具名 RNG 子流。 |
| **future-event-service** | ① | EventOptionManager、PlotManager | 物化 AdventureEvent → eventOptions（**唯一物化点 / 唯一出口**）。 |
| **combat-service** | ① | TurnManager、DeckManager、IntentManager | 回合循环、抽/弃/洗、敌人意图。**Finale 复用。** |

判据（三选一才够格成为服务）：① 自有状态机 / 跨多帧长流程；② 事务性跨多字段一致写；③ 外部 I/O 边界。

**非服务的横切件：** **EventBus**（autoload `Node`，广播既成事实 → `standards/signal-eventbus.md`）、**game-progression**（屏幕流程编排顶点）、**ViewModel**（呈现期对象）、**BootstrapScreen**（`main` 场景，驱动启动 → `scenes/_index.md`）。

## 承重纪律

- **服务不持有独立数据** ——只操作 `PlayerProfile` / `CharacterProfile`。manager 是服务持有的普通 C# 对象（非 `Node`，除非确需 `_Process`），类型声明 **`internal sealed`**。
- **边界措辞（精确版）：服务之间不读写对方字段、不伸手进对方 manager；跨服务的方法调用经 `Xxx.Instance.Method(...)` 是允许的。** 编排顶点 game-progression 负责「谁在什么时机调谁」，但**不是**一切跨服务调用的必经中转。
- **`Instance` 为 null = 启动顺序配错** → 属「必需缺失」→ `GD.PushError` + 抛，**不做静默降级**。
- **服务不返回内部可变集合** —— 一律 `IReadOnlyList<T>` / `IReadOnlyDictionary<,>`。
- **`_Ready` 只装配，`InitializeAsync` 才做 I/O。** autoload 的 `_Ready` 不能 `await`；异步初始化经 `IBootstrappable`，由 `BootstrapScreen` 按序驱动（content → 登录 → account → sync → profile hydrate → 主菜单）。三个纯本地服务（profile / life-cycle / combat）**不实现**该接口。**不要在 `_Ready` 里写 `async void` 做初始化**（已明确否决）。
- **两条唯一入口：** 内容读取经 `ContentRegistry`（不散落 `ResourceLoader.Load`；**抽取走 `AllEnabled()`**）；档案写入经 `ProfileManager.TryApply(spec)`。
- **离线 stub 是「换一个实现」，不是在服务里插 `if (offline)`。** 四个边界服务各持一个窄后端接口，两份实现由 `[Export] bool UseOfflineBackend`（默认 `true`）选择。接口定义见 `20-systems/architecture.md`「总则 7」。

## 装配顺序（规划）

**EventBus → content → account → sync → profile → life-cycle → future-event → combat。** 注意这只解决**装配**顺序；**初始化**顺序由 `BootstrapScreen` 驱动（见上）。实际顺序确定后在此记录。

## 如何添加一条 autoload 说明

服务落地后，在此记录：它的 autoload 注册名与路径、内含 manager、是否实现 `IBootstrappable`、启动顺序依赖。**API 契约表写在设计库的服务文档里，不在这里复制。**
