# architecture（代码库如何运作的高层指南）

> 类模型化（Java class 式）结构总览：systems ≈ 一组类；character-profile / player-profile 为核心「类」，services/ 下的服务（内含 manager）对其提供 API；adventure-event 子类型层级；数据流。
> **本文件是结构与边界的权威**；「代码跑起来是什么样」的端到端运行链路见根级 `program-overview.md`；「工程里长什么样」（进程边界、文件夹布局、autoload 注册、代码形态）见根级 `system-overview.md`。深入代码侧知识见 `.claude/knowledge/architecture.md`（引用层）。
>
> **「服务」= 进程内模块单例**（同一 Godot 二进制、同一进程、直接 C# 方法调用），**不是**分布式微服务。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

### 类模型化结构总览
- **systems ≈ 一组 Java 类。** 每个系统是一个「类」，其**内容定义**（有哪些字段、字段是什么语义）并入该系统，不另设一层。
- **条目实例归平级的 `../content/`。** 类模型回答「这类内容怎么运作」，`content/<类型>/<id>.md` 回答「有哪些条目」——**类 ↔ 实例，故平级而非嵌套**：条目会增长到成百上千，把实例塞进按概念结构组织的树会让 `_index.md` 的索引职责失效。条目文档只写「填了什么值 + 回链本区」，**不复述字段定义**（否则制造第二权威，两份表会各自漂移而本库无机制发现）。
- **复杂类型下沉为文件夹。** 简单主题保持单 `.md`；复杂主题（各 adventure-event 子类型、deck、item、player-power……）各占一个文件夹，含 `_index.md` 与 `common-properties.md`，为「每个具体设计一个 Markdown」预留结构。
- **共有属性显式化。** 每一层的共有字段抽到 `common-properties.md`：adventure-event 各子类型各自一份、adventure-event 顶层一份、systems 顶层一份（`systems/common-properties.md`）。

### 核心「类」：character-profile / player-profile
- **PlayerProfile / 玩家信息（账号级主档，元进程层）：** 跨轮回持久，持有 `List<CharacterProfile>`、`GameSetting`、`List<PlayerPower>`、`List<PlayerItem>`、`achievement: List<Achievement>`、`AccountInfo` 等。结构权威见 `systems/player-profile/`。
- **CharacterProfile / 角色信息（单次轮回）：** 一次轮回 / 一个角色的状态与历史（对齐 CycleState 概念）：`status`（ongoing | defeated | completed）、`chapter`、`Status`（lifeTotal / mana + 隐藏属性 道心 / 煞气 / 寿元）、`pastEvent: IReadOnlyList<PastEventEntry>`、`magicPack: List<CharacterItem>`、AdventurePlot key points 等。结构权威见 `systems/character-profile/`。
- 这两者是被服务操作的**数据核心**；它们不自己驱动轮回生命周期、事件生成或剧本解析，而是被服务读写。

### 服务层：五级层次 service ⊃ manager ⊃ module ⊃ processor ⊃ handler

**抽象层次不封顶在两级**，但每一级都有**固定的层级词**——名字的后缀即宣告它在第几层。完整清单见 `services/_index.md`；运行时端到端链路见根级 `program-overview.md`。

| 层级 | 名称 | 说明 | 现有实例 |
|------|------|------|---------|
| 第一级 | **service** | 边界单元，autoload；三判据（见下） | 七个服务 |
| 第二级 | **manager** | 服务内部的职能组件 | TurnManager、ProfileManager…… |
| 第三级 | **module** | manager 内部的组件 | **`DeckModule`**（CharacterManager / EnemyManager 各持一份） |
| 第四级 | **processor** | 预留 | — |
| 第五级 | **handler** | 预留 | — |

> **纪律不随层数放宽：** 边界仍是「服务之间不读写对方字段、不伸手进对方 manager」；同理**不得跨层直呼**——外部只看得见宿主服务的 API 面，module 及以下一律是宿主 manager 的内部实现。**第四 / 第五级目前没有实例，且暂不落实例——保持空是健康的。**

**module 以下的下沉判据：判据的轴从「职责」换成「形态」。** 前三级各有其轴——service = **边界**（三判据）、manager = **职能**（服务内的一块职责）、module = **可复用的部件**（`DeckModule` 每个参战方各持一份，其成立依据正是「同一形状被实例化多次」）。顺着这条轴：

> **processor = 无状态的处理阶段；handler = 按 kind 分派的叶子。**

- **拆出 processor 需三条判据全中（与门）：**
  1. **它是一个可独立命名的处理阶段**，输入 / 输出明确，**不持有跨调用的状态**（或只持一次调用内的临时状态）。——**这是与 module 的分界**：module 持有状态（`DeckModule` 拥有三个区），processor 不持有。它也是「拆分轴 = 生命周期层 + 行为边界」这条既定轴在第四级的延续（无状态 = 无独立生命周期）。
  2. **它有 ≥ 2 个同形态的实现，或有明确的可替换性**（规则变体、按数据选实现）。单一实现且永不变体的一段代码，拆出去只是换个文件名。**本库已经在实践这条判据**——五类事件只有 2 个 `IEventResolver`，正是同构的先例。
  3. **拆出后调用入口仍只有宿主 module 一个**——不产生第二个调用方、不越层被 manager 直呼。
- **下沉到 handler（第五级）的判据：存在一个开放的 `kind` 枚举，且每个 kind 的处理互不共享状态** → 一个 kind 一个 handler，由 processor 按 kind 分派。**「开放」是关键词**：kind 集合封闭且稳定时（如 `TurnStep` 三值），一个 `switch` 比五个 handler 类清晰得多。**handler 的价值在可加性**——新增一个 kind = 新增一个 handler 文件，与「新增一张卡 = 新增一个 `.tres`」是同一条可加性纪律在代码侧的投影。
- **三条反判据（明确不拆）：** ① 只是「这个文件太长了」；② 只被调用一次且无变体；③ 为了让层级看起来更完整。**层数不是成熟度指标**——「抽象层次不封顶在两级」这句话同时也意味着**不封底**。
- **校准样本（列出但不构成排期）：** 目标合法性筛选（`StackManager` 内）**最强候选**（无状态 ✅ / 按目标类别与次类型筛选有天然变体 ✅ / 只被结算流程调用 ✅）· 效果施加（`StackManager` 内）**强候选**，其下**可能**是 handler 的第一处用武之地（一个效果 kind 一个 handler）· seeded 洗牌（`DeckModule` 内）**不拆**（只有一种洗法）。
- **「先有判据、后有实例」为定案**，比先造实例再补判据安全。**已知代价**：判据偏严可能出现「该拆没拆」的巨型 module——**接受**，巨型 module 是**局部**问题（宿主 manager 之外看不见它），而层级滥用是**全局**问题（词表失去意义、每个人自造层），两害相权取局部。
- **连带：`BattlefieldManager` 不提级。** 提级的三条否决理由见下方「战场与两个参战方 manager 的划线判据」。

- **service（服务）= 边界单元。** 值得成为服务当且仅当命中**三条判据之一**：① 拥有**自己的状态机或跨多帧的长流程**；② 需要**事务性地跨多个字段一致写入**（全有或全无）；③ 坐在**外部 I/O 边界**上（网络、存档、平台 SDK）。服务以 autoload 形式存在，**不持有独立数据**，只操作核心「类」。**边界纪律（已定案的准确措辞）：服务之间不读写对方字段、不伸手进对方 manager；跨服务的方法调用（经对方的服务门面 `Xxx.Instance.Method(...)`）允许。** 编排顶点 game-progression 负责「谁在什么时机调谁」的屏幕流程串联，但**不是**一切跨服务调用的必经中转；既成事实经 EventBus 广播。
- **manager（管理器）= 服务内部的职能组件。** 多个 manager 生活在同一服务里，**共享宿主服务的事务边界与生命周期**；**不被跨服务直接调用**——外部只看得见宿主服务的 API 面。

| 服务 | 判据 | 内含 manager |
|------|------|-------------|
| **account-service** | ③ | AuthManager、ComplianceManager |
| **content-service** | ③ | ContentRegistry、ContentUpdateManager |
| **sync-service** | ②③ | ProfileSyncManager、LocalCacheManager、MigrationManager |
| **profile-service** | ② | ProfileManager、CapabilityManager、AchievementManager |
| **life-cycle-service** | ① | CycleStateManager、ChapterManager、SeedManager |
| **future-event-service** | ① | EventOptionManager、PlotManager |
| **combat-service** | ① | TurnManager、CharacterManager、EnemyManager、BattlefieldManager、StackManager |

> **combat-service 的战场与栈各自一个 manager。** **BattlefieldManager** 持有 **battlefield（战场）**——场上正在生效的卡牌 / 持续状态 / **触发器注册面**；**StackManager** 持有栈（压栈、LIFO 结算、连锁触发顺序）。**栈 = 等待结算的队列，战场 = 已结算并正在生效的东西**，是两个区；TurnManager 是纯粹的回合状态机。

> **战场与两个参战方 manager 的划线判据 = 「是否在场上生效」。** 一件东西**在场上生效、可被效果针对 / 查询、需在结束阶段被清理、需进决策点存档** → **战场条目，归 BattlefieldManager**，条目自带 `OwnerSide` 表示归属方；**参战方的私有资源与牌堆**（mana、道念、手牌、卡组、本场可用道具）→ 归 CharacterManager / EnemyManager。**「属于谁」只是条目的一个字段，不是它的住处**——附着在某一方身上的持续状态（「我方本回合所有牌 +1 道念」）因此是战场条目。**单一战场记录，不分双场区容器。** **读侧统一、写侧分权**：需要整场信息的场合读 combat-service 组装的 `CombatSnapshot`（第一级已是「拥有整场信息的顶点」），写入仍各归其主。**层级不动**——BattlefieldManager 不提级、两个参战方 manager 不降级：提级会让它变成 god object，并把 `DeckModule` 压到第四级、强迫回答尚无判据的「module 以下的下沉判据」；且层级词表的拆分轴是**生命周期层 + 行为边界**，而战场与两个参战方的生命周期完全同长（一场战斗），不存在包含关系。

> **combat-service 的卡组 = `DeckModule`（第三级）。** 抽 / 弃 / 洗与 seeded 洗牌由 CharacterManager 与 EnemyManager 各自持有的 `DeckModule` 承担，**每个 character / enemy 一份**（敌人也出牌）。它不是平级 manager，而是 manager 内部的 module。

#### 拆分轴：生命周期层 + 行为边界，**不是数据类型**

**不**按 `power` / `item` / `card` / `resource` 各开一个服务：那会**撕碎事务**（一次结算典型要同时改多种资源，已定的 `selectCost` 复合成本类型的天然消费者是**一个**统一施加点）、**横切生命周期层**（`PlayerItem` 账号级跨轮回与 `CharacterItem` 轮回级即清，持久化与清理规则完全不同）、并退化为**无规则的贫血 CRUD**。同理**不为五类 AdventureEvent 各开服务**——只有 Combat 真有状态机，其余差异在**数据**而非**代码**（`combatTier` 三档共用 combat-service，Explore 揭示后落到真实 `eventType`）。

「同类内容的统一入口与标准操作接口」由 **content-service 的 ContentRegistry + 泛型仓储接口**满足，而非按类型开服务。

#### 两条唯一入口 + 一个编排顶点

- **内容读取唯一入口 = `content-service.ContentRegistry`**（代码中不散落 `ResourceLoader.Load`）。
- **档案写入唯一入口 = `profile-service.ProfileManager`**。`PlayerProfile ⊃ List<CharacterProfile>`，故由**单一 profile-service** 作为两层的写入面：`TryApply(spec)` 全量校验 → 全有或全无 → 单点提交；modifier pipeline 在此生效。life-cycle-service / combat-service / future-event-service 都只经它写档。
- **编排顶点 = game-progression**（不是服务，是屏幕流程编排层）。核心循环 `ComputeEventOptions → 呈现 → 玩家选择 → AdvanceEvent → 重算` 由它串联。

### 内容与档案的存储分界

```
res://content/**.tres     基线内容，随包发布，只读（保证首启可用 / 离线可读）
user://overlay/**.tres    云端下发的增量，可热更，按 Id 覆盖基线
      ↓ 合并（overlay 优先，res:// 兜底）→ 合并后统一校验（重复 / 悬空 Id → PushError 早失败）
ContentRegistry（内存）    按 Id 索引，唯一内容读取入口
```

- **本地内容层**（`res://` + overlay）承载**有稳定 `Id`、被存档引用、需启动期校验**的一切：`AdventureEventData`、`CardData`、`EnemyData`、`ItemData`、`PlayerPowerData`、平衡表，**含静态展示文案**。因此 **AdventureEvent 的定义本身属本地** —— 启动期强校验模型成立。
- **没有云端内容通道。** AdventurePlot 的剧本节点 / 分支 / 文本**同属本地内容层**，经 ContentRegistry 读取；PlotManager 按 key points 在本地定位剧本节点，**运行时内容零网络请求**。剧本正文**不落存档**（`CharacterProfile` 只存 key points），这一点只决定一件事：**overlay 对剧本内容可新增 `Id`**（「只改不增」的唯一例外，见 `services/content-service.md`）。悬空 key point → `PushWarning` + 叙事降级、不阻塞轮回。
- **档案**：云端权威 `PlayerProfile ⊃ List<CharacterProfile>`；启动时全量 pull，自动存档点 push，冲突以云端为准；本地 `user://cache/` 仅缓存。存档本身归属 sync-service。
  - **`user://cache/` 下一律原子写**（临时文件 → rename），实现走共享静态工具 `AtomicJsonFile`（见下方「共享核心类型」）。
  - **断线时的逐场景处置不在本文件。** 权威分散在各边界服务：push / pull 两条通道、缓冲闸门、退避形态与 `Upgrade` 类错误见 `services/sync-service.md`「断线降级」/「`Immediate` flush 的失败语义」/「`Upgrade` 类错误在非闸门点」；身份侧的刷新失败分流见 `services/account-service.md`；内容与 flags 侧的降级见 `services/content-service.md`；退避的可调数值见 `balance.md`「同步 / 内容管线旋钮」。**本文件不复述任何处置**——抄一份即制造第二权威，而降级行为分散在三个服务里各自演进。
  - **schema 版本 + 迁移路径按判据决定谁需要，不是全称要求。** **多字段的结构体（存档聚合、信封）必须带 `schemaVersion` 并有一条迁移路径**——它们的字段面会增长，读到一份不认识的结构而无版本可判即坏档。**单字段的设备维度小文件不带版本**：迁移面为空，那一格纯属仪式，而配套的「版本不认识就整份丢弃」还可能有害（对一个设备标识而言，丢弃 = 一次假换设备）。判据是**这份文件的结构会不会增长到需要逐版迁移**。逐份落点与各自的处置见 `systems/services/sync-service.md`、`systems/services/content-service.md`、`systems/services/account-service.md`、`systems/player-profile/game-setting.md`。

### 展示层契约：数据 / 运行时 / ViewModel 三层

> **不为「充血模型」另建并行展示类，按生命周期切分三层。** 核心「类」只携带编码（`Id` / 数值），前端要用的描述字段按下面三层各归其位。

1. **静态展示文本留在数据资源上。** `XxxData : Resource`（`.tres`）除 `Id` 与玩法数值外**直接携带**显示名 / 描述 / 图标——这本就是 `data-resource-rules.md` 的既有约定（显示字符串与 `Id` 分离、可本地化）。另建并行展示类只会制造两份需同步的真值。
2. **运行时 / 存档态只带 `Id` + 可变状态。** CharacterProfile 及其持有的运行态对象**不复制展示文本**——存档与上行云端负载保持轻量可版本化，文案变更不触发存档迁移。
3. **组合展示走 UI 层轻量 ViewModel。** 动态描述（数值代入、条件文案、随 capability flag 变化的可见性）由展示层按需组装 `Data + 运行时状态 → ViewModel`，只存在于呈现期，**不落存档、不进云端负载**。

**ViewModel 层因此是架构中的一个显式层**：位于 services / 核心「类」与屏幕场景之间，是「服务 → 屏幕」的数据形态契约。它的完整契约（依赖方向、组装源、重组装触发面、只读消费与缓存归属、永不渲染清单）见 `systems/viewmodel.md`。

### API 契约总则（贯穿七个服务）

> 以下八条总则是全局规则，各服务文档的「API 面（契约）」小节在其约束下书写。

#### 总则 1 —— 三种方法形态，按「它跨什么边界」决定

不允许混用。**形态 B / C 一律带 `Async` 后缀并返回 `Task`，形态 A 一律不带**——看签名即知它是否跨边界。

| 形态 | 适用 | 签名形状 | 理由 |
|------|------|----------|------|
| **A · 同步直返** | 纯内存查询与纯本地事务（查内容、施加变更、能力查询、RNG 派生、物化） | `T Get(...)` / `ApplyResult TryApply(...)` / `bool Has(...)` | 无 I/O、单帧内完成；引入 `Task` 只会给每次查询加一次状态机分配 |
| **B · `Task<OpResult<T>>`** | 跨客户端 ↔ 后端边界的一切（account / content update + flags / sync push-pull） | `Task<OpResult<PlayerProfile>> PullProfileAsync(string accountId, CancellationToken ct)` | 网络失败是**常态而非异常**；`Task` 让离线 stub 变成一行 `Task.FromResult`，也让超时 / 取消 / 重试有统一挂点 |
| **C · `Task<T>` 由信号推进** | 跨多帧的玩法长流程（`RunCombatAsync`、`AdvanceEventAsync`） | `Task<CombatResult> RunCombatAsync(...)`，内部 `await ToSignal(...)` 等玩家输入 | 调用方要的是「战斗打完给我结果」这一件事；帧级推进封在服务内部，不外泄成状态机 |

#### 总则 2 —— 失败语义三分，与 null-check 规则一一对应

| 失败性质 | 形状 | 例 |
|----------|------|-----|
| **必需缺失 = 程序缺陷 / 坏数据** | `GD.PushError($"[Svc-Method] ..., id={id}")` + `throw` | `ContentRegistry.Get(id)`、启动期校验 |
| **可选缺失 = 调用方可降级** | `bool TryXxx(..., out T value)`，返回 `false` 前 `GD.PushWarning` | `ContentRegistry.TryGet`、`TryGetActiveCharacter` |
| **业务失败 = 预期内的拒绝** | 返回 `OpResult` / `OpResult<T>` / `ApplyResult`，**绝不抛** | 网络不通、token 失效、重试耗尽（**事件推进不校验「付得起」**，见总则 8） |

```csharp
public enum OpError { None, Network, Auth, Compliance, Validation, NotFound, Conflict, Cancelled, Migration }

public readonly record struct OpResult(bool Success, OpError Error, string Detail)
{
    public static OpResult Ok()                           => new(true,  OpError.None, string.Empty);
    public static OpResult Fail(OpError e, string detail) => new(false, e, detail);
}
public readonly record struct OpResult<T>(bool Success, T Value, OpError Error, string Detail);

// ApplyResult 保留为独立类型：它多带「哪个 element 不足」，UI 用它做灰显与提示
public readonly record struct ApplyResult(bool Success, CostKey MissingElement);
```

`readonly record struct` 而非 class：结果对象在核心循环里每步都产生，**零堆分配**，且天然带值相等与解构。

#### 总则 3 —— 服务门面的固定骨架

每个服务都长一样：`static Instance` + `private` manager 字段 + 只暴露方法的 API 面（代码形态见 `system-overview.md` 第四节）。三条配套约定：

1. **manager 类型声明为 `internal sealed`**——同程序集内可测，跨服务代码里根本写不出对方 manager 的类型名。
2. **服务间只经 `Xxx.Instance.Method(...)` 调用**；`Instance` 为 null 即启动顺序配错，属「必需缺失」→ `PushError` + 抛，不做静默降级。
3. **服务不返回内部可变集合**——一律 `IReadOnlyList<T>` / `IReadOnlyDictionary<,>`。

#### 总则 4 —— 启动契约：`_Ready` 只装配，`InitializeAsync` 才做 I/O

Godot autoload 的 `_Ready` 不能 `await`，而 content-service 启动就要比对云端版本、sync-service 要 pull。「autoload 声明顺序 = 启动依赖顺序」只解决**装配**顺序，未解决**初始化**顺序。引入 **Bootstrap 屏幕场景**（`scenes/screens/BootstrapScreen.tscn`，非服务、非 autoload）作为 `main` 场景驱动异步初始化：

```csharp
public interface IBootstrappable          // 由三个边界服务实现
{
    Task<OpResult> InitializeAsync(CancellationToken ct);
}
```

顺序：`ContentService.InitializeAsync`（版本比对 + overlay 合并 + 校验，断网降级到基线）→ `LoginScreen` → `AccountService.SignInAsync` → **`ContentService.RefreshFlagsAsync`**（首次 flags 拉取）→ `SyncService.InitializeAsync`（pull + 迁移）→ `ProfileService.Hydrate` → `MainMenu`。三个纯本地服务（profile / life-cycle / combat）**不实现该接口**。这给了「首启不依赖网络下载内容，但进入游戏仍需登录」一个明确落点。

- **flags 刷新为什么另立一步、不并进 `ContentService.InitializeAsync`：** flags 端点**需鉴权**，而 content-service 是启动链第一步、跑在登录之前——两者对不上。排在 `SignInAsync` 之后、`SyncService.InitializeAsync` 之前：抽取池必须在轮回开始前正确，而它**失败不阻塞**，放在硬阻塞的 pull 之前不增加任何阻塞风险。语义见 `systems/services/content-service.md`「flags：`ContentEnabled` 的第三层」。

#### 总则 5 —— EventBus：C# 泛型事件 + `readonly record struct` 负载

Godot `[Signal]` 传自定义负载要求负载继承 `GodotObject`，于是**每次广播都分配一个引用对象并经 `Variant` 装箱**——撞上「层与层之间不做隐式装箱 / 转换」与「热路径不分配」。核心循环每步广播 `EventResolved`、战斗内每张牌广播 `CardResolved`，这条路径不该分配。EventBus 仍是 autoload `Node`（留在场景树里、可在 `_ExitTree` 做泄漏检查），但对外暴露**强类型 C# 事件**：

```csharp
public event Action<CycleStarted>  CycleStarted;
public void Emit(in CycleStarted e)
{
    GD.Print($"[EventBus-Emit] CycleStarted character={e.CharacterId} chapter={e.Chapter}");
    CycleStarted?.Invoke(e);
}
```

配套纪律：**订阅方在 `_Ready` 订阅、在 `_ExitTree` 退订**。代价：GDScript 与编辑器信号面板订阅不了——本项目纯 C#，不构成损失。负载 schema 与三条负载纪律见下方「EventBus 负载契约」。

**退订纪律的强制形态 = `#if DEBUG` 订阅审计（阶梯第 3 级）。** 漏退订不改变玩法结果（幽灵订阅者收到的是既成事实广播，不可否决），只吃内存并可能对已 `QueueFree` 的节点调方法，**开发期即可显形**——按「纪律的可执行化」的选级判据，第 3 级足够，不必付第 1 / 2 级的成本。形态四条：

1. **判据：** 遍历 `event` 的 `GetInvocationList()`，`d.Target is GodotObject go && !GodotObject.IsInstanceValid(go)` 即泄漏。
2. **定位信息取自 `d.Method`，不取自 `d.Target`。** 泄漏发生时目标实例已释放，`Target.ToString()` 无用；`Method.DeclaringType.Name + "." + Method.Name` 是反射元数据，**不依赖实例存活**，直接给出 `CombatScreen.OnCardResolved` 这样可定位的名字。**因此订阅时不需额外登记来源，`+=` 的惯用形态原样保留。**
3. **触发时机 = 每次屏幕切换完成后**，由编排顶点 game-progression 调一次 `AuditSubscribers()`。屏幕场景是订阅者的绝大多数，切屏正是它们被释放的边界；频率 = 每次切屏一次，**零热路径成本**。**否决「每次 `Emit` 顺带检查」**——`GetInvocationList()` 每次分配数组，`CardResolved` 在战斗热路径上，直接撞「热路径不分配」。**EventBus 自己的 `_ExitTree` 只打一条订阅计数摘要，不做泄漏判定**：此时七个 autoload 服务可能正在同步销毁，`IsInstanceValid` 会对它们误报。
4. **泄漏检查豁免 autoload 服务的订阅**——服务与游戏同生命周期，它们的订阅按定义不是泄漏。用 `IsInstanceValid` 在切屏时机作判据天然满足这一点，这也是必须避开 `_ExitTree` 判定的原因。

#### 总则 6 —— 物化模型：模板 `Data` → future-event-service 物化 → 定稿实例

**AdventureEvent 的多数属性由 future-event-service 依情境物化产出，产出即定稿。** 这是影响面最大的一条，它同时改写 `adventure-event/common-properties.md` 与 `future-event-service.md` 的意图层表述。

```
res:// + user://overlay/          ContentRegistry              future-event-service          life-cycle / combat / UI
  AdventureEventData(.tres)  ──▶  按 Id 索引的只读模板  ──▶  物化(materialize)        ──▶   只读消费
  = 静态素材 / 参数空间             共享单例、可热更           情境代入 → 定稿实例            不回查模板、不改字段
                                                             （EventOption，immutable）
```

- **模板侧（`AdventureEventData : Resource`）** 承载稳定 `Id`、`eventType`、静态展示文案、基准数值与**可变体的参数空间**、数据驱动的 outcome / effect 定义。它是 ContentRegistry 里的**共享只读单例**，可被 overlay 热更覆写——**任何服务都不得在运行时写它**（写回会污染注册表，被同一轮回的后续批次与其他角色看到）。
- **物化侧（future-event-service）** 是**唯一物化点**。输入 = 模板（经 `AllEnabled()` 取池）+ CharacterProfile + location 框定 + PlotManager 调制 + SeedManager 的 map 子流；输出 = 一批 `EventOption`。**产出 eventOptions ≡ 物化 AdventureEvent**；`eventPriority` 的动态置位只是这条规则的一个特例，**按情境制造变化与风味**才是物化的目的。
- **消费侧定稿（finalized）。** `EventOption` 一经输出即冻结：life-cycle-service / combat-service / ViewModel 一律只读，**不得回查模板重算、不得改写其字段**。这条纪律保证「同一个事件在呈现、结算、记入历程三处看到的是同一份数据」。
- **哪些字段落定稿实例由一条物化判据给出：** 由 seeded RNG 掷定 · 由情境代入而定 · 物化时组装或变换而成——命中任一条即落 `EventOption`，三条皆不命中的留模板侧；文本类字段是反向的硬边界。**它与快照判据是孪生的两条**（前者答「在不在定稿实例上」，后者答「要不要再抄进 `PastEventEntry`」）。判据全文、outcome 的固化时点与结算走向映射见 `systems/services/future-event-service.md`。

```csharp
public sealed record EventOption(                 // 定稿实例：immutable 引用类型，落存档
    string             InstanceId,                // 本次物化实例的稳定标识；pastEvent / 存档引用它
    string             EventId,                   // 溯源到模板
    EventType          EventType,                 // Explore 时 = Explore 本身；真身见 RevealedEventId
    int                Priority,                  // 物化时置位；取值域 { 0, 1 }
    ProfileChangeSpec  SelectCost,                // 物化时组装（modifier pipeline 尚未施加）
    bool               IsRevealed,                // Explore：是否已揭示
    string             RevealedEventId,           // Explore 遮罩的固定事件（内容侧即已确定）
    string             DestinationLocationId,     // Travel 的目的地 LocationData.Id；非 Travel 为空串
    IReadOnlyList<ResearchSlot> ResearchSlots,    // Research 的构筑面板决策槽（候选已掷定）；其余类型为空
    IReadOnlyList<ExchangeOffer> ExchangeStock,   // Exchange 的定稿库存（商品与标价已掷定）；其余类型为空
    int                RerolledCount,             // Exchange 已刷新次数；供刷新价递增与存档恢复
    EventOutcomeSpec   OutcomeSpec,               // 产出侧定稿载体：抽取 / 权重已掷定，结算时只选一侧
    EncounterSpec      Encounter                  // 战斗真身非空、其余为 null；EnemyInstance 嵌在其内
    );
```

**为何是 `sealed record`（引用类型）而非 `readonly record struct`：** 字段多、要落存档、一批只有个位数个、不在每帧热路径——按值拷贝的代价高于一次分配。`record` 的 `with` 表达式同时给出「定稿后若确需派生（如 Explore 揭示）就产生一个新实例而非改旧的」这一惯用法。

**`with` 派生不违反「产出即定稿」，且派生实例另有承载。** 派生**不取池、不掷物化随机、不改 `InstanceId` / `EventId`**，当前批里那份原实例一字未动 ⇒ 定稿纪律原样成立。派生后的那一份住在 `CharacterProfile.activeEvent`（结算期间的权威副本），当前批住在 `CharacterProfile.eventOption`；两者的形态、写入通道与读档校验见 `systems/character-profile/_index.md`。

**`DestinationLocationId` 与 `RevealedEventId` 同款：只对某一类型有意义、其余类型填空串的结构性 id 字段。** 它必须落在定稿实例上、不能事后算——目的地由 map 子流从邻接集合抽出，是物化产物，重算不保证同结果，而「产出即定稿、不得回查模板重算」禁止消费侧再抽一次。它同时使呈现与结算共用同一份事实：选项上显示「前往 X」、life-cycle-service 据它写 `Status.CurrentLocationId`，两处看到的必须是同一个 `Id`。

**`ResearchSlots` 同属这一族「只对某一类型有意义」的结构性字段，理由同款且更硬。** 槽内候选（学哪门功法 / 得哪件法宝 / 附带的 `manaLimit` 变动）在物化时用 `RngStream.Reward` 掷定并随实例落存档——候选若等到面板打开那一刻才掷，玩家退出重进即可重掷，而**风险档正是靠「结果已定、只是尚未展示」才能成立**。槽的字段面与候选取池链见 `systems/adventure-event/research/common-properties.md`。

**`ExchangeStock` 与 `RerolledCount` 是同一族的第三、第四个实例。** 库存由 `RngStream.Shop` 子流在物化时掷定——抽哪几件、每件标价多少都取决于当时的角色状态与 seeded RNG，重算不保证同结果，而「产出即定稿、不得回查模板重算」禁止消费侧再抽一次；`ListPrice` 尤其如此，它在物化时就已施加 `ModifierKey.ShopPrice`，等到展示时现算会让同一个 offer 在两次进入之间变价。`RerolledCount` 是刷新价递增的自变量，同样必须在玩家可退出之前落盘，否则退出重进即可把刷新价按回起点。商品族、字段面与定价链见 `systems/adventure-event/exchange/common-properties.md`。

**三条推论：**

1. **定稿实例必须落存档，不能只存 `EventId` 事后重算。** 物化用了 seeded RNG、当时的角色状态、以及可被 overlay 热更的模板；确定性只在同一 `contentVersion` 内成立。因此**当前批 eventOptions 与 `pastEvent` 痕迹都要存物化后的快照**。
   **快照存哪些字段由一条判据给出：「重算不出来的存，重算得出来的不存」**——文本类字段一律留在模板侧（**风味文案也不物化**），物化产出的数值必进快照。它与「运行时 / 存档态只带 `Id` + 可变状态、不复制展示文本」**不冲突**：后者管展示文本，本条管物化数值。痕迹条目 `PastEventEntry` 的完整形态见 `systems/adventure-event/common-properties.md`。
2. **`InstanceId` 与 `EventId` 并存且不可互相替代。** 同一模板可在一次轮回里被物化多次；`pastEvent` 与 `EventResolved` 负载都按 `InstanceId` 定位。
3. **通则：** 凡「内容定义 + 情境 / 轮回内状态」的组合都是两个类型——`AdventureEventData` ↔ `EventOption`（**定稿不可变**）；`CardData` ↔ `CardInstance`（运行态**可变**）；**`EnemyData` ↔ `EnemyInstance`**（**定稿不可变**；future-event-service 取模板 → 充实 / 改写 → 指派给事件，**敌人等级即物化产物**；条目定义归 `systems/enemies/`）。共享纪律：**服务签名里传实例，不传 `Resource`**；差别只在实例是否可变。这与展示层三层切分同构，把第二层的类型形态明确了。

#### 总则 7 —— 后端接口化：三个边界服务各持一个可替换后端

把跨进程边界的调用收敛到三个窄接口，让离线 stub 是「换一个实现」而非「在服务里插 `if (offline)`」：

```csharp
internal interface IAccountBackend  { Task<OpResult<Session>>          SignInAsync(LoginChannel c, CancellationToken ct); }
internal interface IContentBackend  { Task<OpResult<ContentManifest>>  GetManifestAsync(CancellationToken ct); }
internal interface IProfileBackend  { Task<OpResult<ProfileSnapshot>>  PullAsync(string accountId, CancellationToken ct);
                                      Task<OpResult<PushAck>>          PushAsync(ProfilePayload p, CancellationToken ct); }
```

> **三个后端接口全部落在服务身上，`manager` 没有跨边界的例外。** 不设剧本后端接口：剧本内容属本地内容层（见上方「内容与档案的存储分界」），客户端不存在剧本的网络通道。条件编译清单共 **5 处**，不得扩张（清单见下方「纪律的可执行化」）。

每个接口两份实现：`HttpXxxBackend`（后端就绪后）与 `OfflineXxxBackend`（当前阶段，读 `res://` 假数据 / 内存回显）。

**选择形态：唯一选择点 `BackendSelector` + Release 构建里离线实现根本不存在。** 三个服务**不各自持开关**——由 `src/Core/BackendSelector.cs` 的 `CreateAccount()` / `CreateContent()` / `CreateProfile()` 产出实现，三个 `OfflineXxxBackend` **整类包在 `#if DEBUG` 内**（阶梯第 1 级：Release 下写不出对离线实现的引用，配错连编译都不通过）；开发期的开关载体是 ProjectSettings 自定义项 `mycardgame/backend/use_offline_backend`（第 3 级兜底），**不是 `[Export]`**。落地形态、启动期审计与「条件编译共 5 处、不得扩张」的清单见 `system-overview.md` 第四节，选级理由见下方「纪律的可执行化」。

> **理由（承重）：** 每个服务各持一个开关字段 = 若干个可能各自出错的点，最糟的失败态是「开了一部分没开另一部分」的**半在线状态**——它比全离线更难诊断（登录成功、内容加载正常，只有存档静默写进内存回显）。收敛成一个选择点后，这个失败态在结构上不存在。这与两条唯一入口 + 唯一物化点是同一条纪律。**接口有几个不削弱这条理由**——只要多于一个，半在线态就有可能。

> **不插 `if`，也不插 `#if`：** 服务与 manager 内部一律只见 `IXxxBackend` 接口。

> 这三个接口是客户端 ↔ 后端**协议契约的客户端一侧投影**；其权威在 `backend-design-documents/`。本库只定客户端的**调用形状**（方法名、参数、`OpResult` 语义），不定 HTTP 路径 / 报文字段。

**`IProfileBackend` 的两个返回类型都带 `revision`**（`ProfileSnapshot(Profile, Revision, SchemaVersion)` / `PushAck(NewRevision, Deduplicated)`）——`revision` 是**后端分配的账号级单调递增 `long`**，客户端持有的基线值 `baseRevision` 是**传输层元数据**（落 `user://cache/sync-envelope.json`，不进 Profile、不进存档 schema）；上行走 **CAS**，并携带幂等键 `pushId` 防「请求已达、响应丢失」时丢进度。语义、三分支表与校验点见 `systems/services/sync-service.md`。

##### 后端错误码 → `OpError`：一张数据表

> 后端错误体统一为 `code` / `class` / `message` / `detail` / `requestId` 五字段（权威：`backend-design-documents/contracts/envelope.md` §5–6）。客户端侧的承接落在**共享的一处**：三个 `HttpXxxBackend` 共用 `src/Core/` 的映射表与头处理点，不各写一遍。

**形态是数据表**（`code → (OpError, 处置)`），**不是 switch 语句**——与「新增内容 = 新增数据，不编辑 switch」的可加性纪律一致：新增一个后端 `code` = 表里加一行。

**三条承重纪律：**

1. **不得靠 HTTP 状态码分支**，业务分支一律以 `code` 为键；状态码只承担传输层语义。否则「401 到底是 token 过期还是被挤下线」永远做不干净，而这两者的客户端处置**完全不同**（静默刷新 vs 硬阻塞重登）。
2. **不得解析 `message` 做任何分支**——措辞可随时改写，依赖它的分支会在某次后端改文案时静默失效。需要被代码消费的值一律取 `detail`。
3. **`message` 不进玩家可见弹窗**：与 `requestId` 一起拼进 `OpResult.Detail`，随 `GD.PushError` / `GD.PushWarning` 输出。`requestId` 是**跨越进程边界的那个定位标识符**，正是日志纪律要求的东西；玩家可见文案由 UI 层决定。

**处置表不含玩家文案；文案归 UI 层，键同为 `code`。** 这张表跑在后端适配层，**那里没有界面上下文，也不该有**——往里塞文案会让一个网络适配器依赖 UI 层。文案表是另一张表，与本表**共用同一个键 `code`**：本表回答「怎么办」，文案表回答「怎么说」。`code` → 翻译键是**机械变换**（`ERR_` + 全大写 + `.` 换 `_`），故新增一个 `code` 只需在本表加一行、在翻译资源加一条，**不存在第二张需要同步的对照表**。形态、兜底路径与启动期审计见 `ux/error-and-blocking-ux.md`。

**`OpResult.Detail` 是诊断串，UI 永不直接渲染它。** `Detail` = `code` + `requestId` + 后端 `message`（本地失败则为定位上下文）；玩家可见文案一律经 UI 层的 `ErrorText.For(code, reasonKey, error)`。**它不兼「可展示」身份**——一旦可能被渲染，英文调试串就随时可能漏到屏上，且上面三条承重纪律**一条也无法机械检查**。**检查形态**：UI 层不出现把 `OpResult.Detail` 赋给任何 `Label.Text` 的写法。

**默认路径**（未知 `code` → 按 `class` 降级；**未知 `class` → 当作 `Fatal` + 上报一次**）：

| `class` | 默认 `OpError` | 默认处置 |
|---|---|---|
| `Retryable` | `Network` | 既定断线降级（进待发队列 + 退避 + 不阻塞） |
| `Fatal` | `Validation` | 拒绝本次操作 + **上报一次** |
| `Reauth` | `Auth` | **静默刷新一次**；刷新的失败按判据分流——**网络失败视同断线**走同一缓冲通道，**收到 `auth.session_revoked` 则硬阻塞重登**（见 `services/account-service.md`） |
| `Upgrade` | `Validation` | 非闸门点的非阻塞处置（见 `sync-service.md`） |

- **硬阻塞仍然只有两处，且只由已知 `code` 触发**——`auth.session_revoked`（被挤下线）与登录 / 启动 pull 点的 `client.version_unsupported`。（**阻塞屏有三个变体，但阻塞点仍是这两处**：本地迁移失败落在「启动 pull」那一处之内，不新增第三处。见 `ux/error-and-blocking-ux.md`。）**一个未知 `code` 永远不得新增第三处硬阻塞**：未知 `Reauth` 走保守的静默刷新，代价是一个真失效的会话可能多跑一小会儿（下一次操作仍会被拒），收益是后端新加一条错误码不可能打断玩家进行中的轮回。
- **`OpError.Cancelled` 与 `OpError.Migration` 不得出现在映射表的取值域里。** 前者是 `CancellationToken` 的本地语义，后者是 `MigrationManager` 的本地存档迁移失败；后端拒绝一个它不认识的 `schemaVersion` 是**上行校验失败**（`Validation`），映到 `Migration` 会让客户端去跑一条本地迁移路径，而问题根本不在本地。**这条可机械检查**（表的 `OpError` 列排除两值）。
- **应答体无法解析为契约错误体**（网关 502、非 JSON 错误页）→ 按 HTTP 状态码降级为 `server.unavailable`（`Retryable`）；不要求网关也产出契约错误体。
- **映射表不含 `plot` 域**——剧本内容属本地内容层，客户端不存在剧本的网络失败态。

#### 总则 8 —— 结算阶段名

`eventStart` / `eventEnd` 是 `AdvanceEventAsync` 内部结算流程的**两个阶段名**，**不是 `AdventureEventData` 上的方法**——事件不自带钩子，结算流程的编排权归 `AdvanceEventAsync`。落地为数据驱动的结算器：

```csharp
internal interface IEventResolver          // 按 eventType 注册，共 2 个实现
{
    Task<ResolveOutcome> ResolveAsync(EventOption option, CancellationToken ct);
}
// CombatEventResolver  → Combat（三个 combatTier 档共用），转 combat-service
// GenericEventResolver → 其余四类，读物化后 EventOption 上的定稿 OutcomeSpec
```

`AdvanceEventAsync` 的固定流程：

```
校验选项合法性（Priority < EffectivePriority → 拒绝）
  → TryApply(SelectCost + EventStateChanges[ActiveEvent = 该项原样拷贝])  ← 同一次事务；不做「付得起」校验
  → 终态判定 ①（支付后立即）                 ← 判负 → 短路进失败流程，activeEvent 随失败流程一并清理
  → 【eventStart 阶段】选 resolver、Explore 揭示
  → resolver.ResolveAsync(activeEvent.option, ct)      ← 传派生后的那一份
  → 【eventEnd 阶段】合并 ResolveOutcome + lifeSpanCost + 隐藏属性推拉
                     + TraceElements[本次 PastEventEntry]（快照取自 activeEvent.option）
                     + EventStateChanges[ActiveEvent = null, ActiveCombat = null, EventOption = 新一批]
                     + RngElements[本次事件内消耗过的子流终态] 为**一次** TryApply
  → 终态判定 ②（结算后）→ EventBus 广播 → sync 自动存档点
```

**「记入 `pastEvent`」在事务之内，不是事务之后。** 它经 `TraceElements` 与收口的其余各列同批提交，故「收口是一次事务、一个存档点」不依赖任何人记得把两步写在一起。收口内部的组装顺序（先投影、后补两列）见 `systems/services/life-cycle-service.md`。

五类事件仍只有**两个** resolver——与拆分轴「只有 Combat 真有状态机、其余差异在数据而非代码」一致，且保住「新增一个事件 = 新增一个 `.tres`」的可加性。

#### 共享核心类型（`src/Core/`）

```csharp
public sealed record ProfileChangeSpec                                    // 平级只读列表，逐条按施加语义分列
{
    public IReadOnlyList<ChangeElement>        Elements        { get; }   // 资源：带符号的量
    public IReadOnlyList<AbilityChangeElement> AbilityElements { get; }   // 能力：按 Id 的集合成员操作
    public IReadOnlyList<StatDelta>            Stats           { get; }   // 统计计数：纯自增
    public IReadOnlyList<StatusAssignment>     StatusChanges   { get; }   // Status 规则字段：绝对置值
    public IReadOnlyList<DeckChangeElement>    DeckElements    { get; }   // 卡组：带层数的构筑变更 / 多重集增删
    public IReadOnlyList<PlotKeyPointAssignment> PlotElements  { get; }   // 剧本：按 ArcId 的带载荷 upsert
    public IReadOnlyList<EventStateAssignment> EventStateChanges { get; } // 事件态：绝对置值（含 activeCombat）
    public IReadOnlyList<RngStateAssignment>   RngElements     { get; }   // RNG 子流：按子流键的双标量 upsert
    public IReadOnlyList<PastEventEntry>       TraceElements   { get; }   // 履历：序列尾部只追加
    public IReadOnlyList<SettingAssignment>    SettingChanges  { get; }   // 账号级设置：绝对置值
}
public readonly record struct ChangeElement(   // 负 = 消耗，正 = 产出（仅 Add 时有向）
    CostKey Key,
    int     BaseValue,
    ApplyOp Op);                               // 缺省 Add；Set 时 BaseValue = 已算好的绝对值
public readonly record struct AbilityChangeElement(
    AbilityChangeOp Op, AbilityKind Kind, AbilityScope Scope,
    string AbilityId, DisableDuration Duration, Source Source, string PairKey);
public readonly record struct StatDelta(StatKey Key, int Delta);
public readonly record struct StatusAssignment(   // 置值：赋为一个已算好的绝对值，不做加减
    StatusKey Key,
    int       IntValue,                           // Key 声明为整型时使用
    string    StringValue);                       // Key 声明为 id 型时使用；另一格填缺省
public readonly record struct DeckChangeElement(  // 卡组变更：带层数的构筑操作 / 游离散牌的多重集增删
    DeckChangeOp Op,
    string       Id,                              // 功法 Id（前三个 Op）/ 卡牌 Id（AddLooseCard / RemoveLooseCard）
    int          Tier);                           // LearnTechnique = 1 / UpgradeTechnique = 目标层数；其余写 -1
public readonly record struct PlotKeyPointAssignment(   // 按 ArcId upsert 一条 PlotKeyPoint（已算好的绝对状态）
    string       ArcId,
    string       NodeId,
    PlotArcState State,
    int          EnteredAtChapter,
    int          EnteredAtSeq);
public readonly record struct EventStateAssignment(     // 事件态：赋一份已算好的块，或置空
    EventStateKey     Key,
    ActiveEventState? ActiveEvent,                      // Key == ActiveEvent 时使用
    EventOptionSave?  EventOption,                      // Key == EventOption 时使用
    ActiveCombat?     ActiveCombat);                    // Key == ActiveCombat 时使用；其余格填 null
                                                        // 三格恒为 null = 置空，仅 ActiveEvent / ActiveCombat 合法
public readonly record struct RngStateAssignment(       // RNG 子流：按子流键的绝对置值 upsert
    RngStream Stream,                                   // 键：SeedManager 内的子流常量清单
    ulong     State,                                    // 恢复权威字段
    int       DrawCount);                               // 诊断与迁移保险；本次提交之后的累计值
public readonly record struct SettingAssignment(        // 账号级设置：赋一个已算好的绝对值
    SettingKey Key,
    int?       IntValue,                                // Kind == Int 时使用；否则 null
    bool?      BoolValue);                              // Kind == Bool 时使用；否则 null
                                                        // 两格皆可空：0 / false 既是缺省也是合法值，
                                                        // 非可空下「哪一格有效」判不出来

internal readonly record struct ElementSpec(      // 资源 element 的取值域 + 终态语义 + 修正接入 + op 准入
    int  Min,                                     // 施加后的下界
    int? Max,                                     // null = 无上界
    DefeatReason? DepletionDefeat,                // null = 触底不构成终态
    ModifierKey?  CostModifier,                   // 作用于 BaseValue < 0；null = 不经 modifier pipeline
    ModifierKey?  GainModifier,                   // 作用于 BaseValue > 0；null = 不经 modifier pipeline
    ApplyOps      AllowedOps);                    // 该 key 允许的施加方式；空集 = 启动期 PushError

// 封闭表；新增一行 = 新增一个资源 element 的完整语义，须与 CostKey 同批评审
internal static readonly IReadOnlyDictionary<CostKey, ElementSpec> ResourceElements = ...
// 轮回层 · CharacterProfile
// LifeSpan        → (0, null,  DefeatReason.LifeSpanExhausted,  ModifierKey.LifeSpanCost, null, Add)
// Jade            → (0, null,  null,                            null, null,               Add)
// LifeTotal       → (0, null,  DefeatReason.LifeTotalExhausted, null, null,               Add)
// ManaLimit       → (0, null,  null,                            null, null,               Add)   两个修正列留空是硬要求，Set 恒不开，见下
// ExperiencePoint → (0, null,  null,                            null, null,               Add)
// Faith           → (0, 100,   null,                            null, null,               Add)
// Bloodlust       → (0, 100,   null,                            null, null,               Add)
// 账号层 · PlayerProfile.playerPowerFragment（7 字段 ↔ 7 成员）
// PowerFragmentAccumulated         → (0, 10000, null, null, null, Add | Set)
// PowerFragmentFinaleWinOrdinal    → (0, null,  null, null, null, Add)
// PowerFragmentCh1FirstWinDone     → (0, 1,     null, null, null, Set)
// PowerFragmentCh2FirstWinDone     → (0, 1,     null, null, null, Set)
// PowerFragmentCh3FirstWinDone     → (0, 1,     null, null, null, Set)
// PowerFragmentLastRoll            → (0, 9999,  null, null, null, Set)
// PowerFragmentLastEffectiveChance → (0, 10000, null, null, null, Set)
// 账号层 · PlayerProfile.entitlement
// BundleRedeemedOrdinal            → (0, null,  null, null, null, Set)

internal readonly record struct StatusFieldSpec(StatusValueKind Kind, int Min, int? Max);

// 封闭表；逐行给出该 key 的值类型与取值域，与 ResourceElements 同款判据
internal static readonly IReadOnlyDictionary<StatusKey, StatusFieldSpec> StatusFields = ...
// CurrentLocationId  → (Id,  -, -)      值须能经 ContentRegistry 解析为 LocationData
// LocationEventCount → (Int,  0, null)
// FaithBand          → (Int, -2, 2)
// BloodlustBand      → (Int,  0, 3)
// LifeSpanBand       → (Int,  0, 2)
// ChapterLifeSpanBudget → (Int,  0, null)   Min = 0 与寿元同源（结转要求它是可加的非负预算）；无上界
// ⟨其余 Status 规则字段随各自专场逐条补⟩

internal readonly record struct SettingFieldSpec(       // 值类型 + 取值域 + 默认值（默认值的唯一一处）
    SettingValueKind Kind, int Min, int Max, int IntDefault, bool BoolDefault);

// 封闭表；与 StatusFields 同款判据。默认值列不是平衡数值，是 UI 初值 / 缺省
internal static readonly IReadOnlyDictionary<SettingKey, SettingFieldSpec> SettingFields = ...
// MasterVolume        → (Int,  0, 100, 100, -)
// MusicVolume         → (Int,  0, 100,  80, -)
// SfxVolume           → (Int,  0, 100, 100, -)
// FastCombatAnimation → (Bool, -,   -,   -, false)

public enum CostKey         {                                             // 资源族 element 键；15 值，逐一在 ResourceElements 表中占一行
                              // 轮回层 · CharacterProfile
                              LifeSpan, Jade, LifeTotal, ManaLimit,
                              ExperiencePoint, Faith, Bloodlust,
                              // 账号层 · PlayerProfile.playerPowerFragment
                              PowerFragmentAccumulated, PowerFragmentFinaleWinOrdinal,
                              PowerFragmentCh1FirstWinDone, PowerFragmentCh2FirstWinDone,
                              PowerFragmentCh3FirstWinDone,
                              PowerFragmentLastRoll, PowerFragmentLastEffectiveChance,
                              // 账号层 · PlayerProfile.entitlement
                              BundleRedeemedOrdinal }
public enum ApplyOp         { Add, Set }                                  // Add 必须为 0（缺省即累加）
[Flags] public enum ApplyOps { Add = 1, Set = 2 }                         // ElementSpec 的 op 准入集
public enum DeckChangeOp    { LearnTechnique, UpgradeTechnique, ForgetTechnique,
                              AddLooseCard, RemoveLooseCard }
public enum PlotArcState    { Queued, Active, Completed, Abandoned }      // 一条剧本线在存档里的态
public enum EventStateKey   { ActiveEvent, EventOption, ActiveCombat }    // 事件态字段；载荷格名与成员名一一对应
public enum StatusKey       { CurrentLocationId, LocationEventCount,
                              FaithBand, BloodlustBand, LifeSpanBand,
                              ChapterLifeSpanBudget, /* ⟨随各专场逐条补⟩ */ }
public enum StatusValueKind { Int, Id }
public enum SettingKey      { MasterVolume, MusicVolume, SfxVolume, FastCombatAnimation }
                                                              // 账号级设置键；逐一在 SettingFields 表中占一行
public enum SettingValueKind { Int, Bool }
public enum ModifierKey     { LifeSpanCost, ShopPrice, /* ⟨待定：其余具名修正，随各自专场补⟩ */ }
public enum StatKey         { TotalCyclesCompleted, TotalCyclesDefeated }   // 统计族；无配表，成员名 = PlayerStatistics 字段名
public enum AbilityChangeOp { Grant, Remove, Disable }
public enum AbilityKind     { Power, Item }
public enum AbilityScope    { Character, Player }                         // 能力的生命周期层
public enum DisableDuration { NextEvent, ThisChapter, ThisCycle }
public enum RarityTier      { Tier1, Tier2, Tier3, Tier4, Tier5 }         // 内容稀有度，档号越高越稀有
public enum CycleStatus     { Ongoing, Defeated, Completed }
public enum Realm           { QiRefining, FoundationEstablishment, GoldenCore, NascentSoul }
                                                              // 四境；全局等级序 = (Realm, Level) 的纯函数，不落存档
public enum DefeatReason    { Discarded, LifeSpanExhausted, LifeTotalExhausted }   // 战斗失败本身不终结角色，只扣 lifeTotal
public enum CapabilityFlag  { RevealHiddenStats, ShowExploreType }
public enum HiddenStat      { Faith, Bloodlust, LifeSpan }
public enum RngStream       { Map, Combat, Shop, Reward }
public enum EventType       { Combat, Exchange, Research, Explore, Travel }
public enum CombatTier      { Practice, Standard, Finale }   // 仅 EventType.Combat 携带
```

**`CostKey` / `StatKey` 的成员**序**不构成契约，成员**名**构成契约，只可追加（承重）。** 两个枚举都随 `ProfileChangeSpec` 落进 `PastEventEntry.SelectCost` / `AppliedChange`，而枚举以成员名逐字序列化（见 `systems/services/sync-service.md`）⇒ **重命名或复用一个成员即破坏性契约变更**，须 bump `schemaVersion` 并与后端同批改；重排成员则毫无影响。**也不给两者分配显式整数 code**：`Source` 走名 / code 双轨是因为它在存档里以整数序列化，两个 element 键无此包袱，加一套 code 等于加一份必须一同冻结的第二真值而收益为零。

**`CostKey` 的成员集合由两层 Profile 的字段表穷举而来，不是一个开放的设计选择（承重）。** `Elements` 的唯一职责是写 Profile 上的资源型字段，故成员数 **=** 两张字段表中写入通道标为 `Elements` 的格子数，闭合判据是这个映射**双向满射**（每个成员有一个标的字段，每个标为 `Elements` 的字段有一个成员）。**日后新增一个资源 element 恰好五步**：① Profile 加字段（只读、无 setter）并更新该库字段表的写入通道列 → ② `CostKey` 加一个成员（名 ⟸ 字段路径）→ ③ `ResourceElements` 加一行六列 → ④ bump 存档 schema 版本（老档补默认值）→ ⑤ 若该行含 `Set`，两个修正列必须留空（启动期断言兜底）。不新增服务、不改任何调用方。字段表见 `systems/character-profile/_index.md` 与 `systems/player-profile/_index.md`，逐行取值与两族的书写分野见 `systems/services/profile-service.md` 与 `systems/player-profile/_index.md`。

**三个首胜标记以 `int 0/1` 进 `Elements`，不另开一列 `FlagChanges`。** 它们在存档上是 `bool`，在 `ChangeElement.BaseValue`（`int`）上以 `0 / 1` 承载，`Min = 0` / `Max = 1` 由钳制兜住。按三级判据的六个面核对，它与 `Elements` 在**五个面上全对齐**（要钳制 · `Set` 下不走 pipeline · 失败阻断整批 · `Set` 幂等 · 键与载荷是标量），只在「有无量纲」一面不同——而判据要求的是**六面全对齐才不分列**的反面：**只差一面不足以分列**，否则每个 `Set` 型标量都要一列。

**`CostSpec` / `RewardSpec` 合并为单一 `ProfileChangeSpec`**（element 带符号：负 = 消耗，正 = 产出）。理由：「全有或全无、单点提交」本就要求成本与产出在同一事务内；两个类型会诱导出「先 `TryApply(cost)` 再 `TryApply(reward)`」这种半套写入。

**`ProfileChangeSpec` 是 `sealed record`，组装期的追加以 `with` 产生新实例，各列仍是 `IReadOnlyList<T>`（承重）。** 收口组装存在一个「先投影、再把算出的结果补进 spec」的既定顺序（见下方总则 8 与 `systems/services/life-cycle-service.md`），它要求一份已构造的 spec 能派生出带追加列的新实例。**取 `record` + `with`，不让任何一列可变**——可变列与「服务不返回内部可变集合」这条同源纪律直接相抵，也会让 `AppliedChange` 记的账在提交之后仍可被改写。`with` 是纯函数派生：原实例一字未动，与 `EventOption` 处理「定稿后确需派生」的既有惯用法（总则 6）同形。否决 `ProfileChangeSpecBuilder`：它要求全部 spec 组装点改写，换来的只是把同一条边界从类型层挪到一个 `Build()` 调用上。

**一个新的施加语义该落在哪里：自上而下的三问（承重判据）。** 每次遇到「这条新语义要不要新开一列 / 要不要加一个 `Op` / 要不要在配表里加一列」，按下表逐级下降，取第一个成立的落点。判据本身是可机械核对的，不靠先例类推——散落的类推会给形状相同的三个问题推出三个互不一致的答案。

| 落点 | 成立条件 | 既有形态 |
|---|---|---|
| **① 新增一个列表（分列）** | 施加语义与既有各列**根本不同**。可机械核对的**六个面**：**要不要钳制** · **是否走 modifier pipeline** · **失败是否阻断整批** · **是否幂等** · **有无量纲** · **键与载荷的形状**（见下方展开）。**任一既有列在这六面上与新语义全部对齐 ⇒ 不分列。** | `ProfileChangeSpec` 的各列 |
| **② 同列内新增一个 `Op`** | 语义**同族**——共用同一张配表、同一条校验链、同一套钳制与失败语义——但**动作的方向或形式不同**（增 vs 减、加 vs 赋、学 vs 忘 vs 升）。 | `ApplyOp` · `AbilityChangeOp` · `DeckChangeOp` |
| **③ 在配表里新增一列** | 该性质是 **element 类型的属性**：同一个 key 的**每一次**变更都取同一个值（取值域、触底是否终态、修正准入、允许的 `Op` 集合）。 | `ResourceElements` · `StatusFields` |

**第六面「键与载荷的形状」的完整口径（承重）：它由三样东西共同给出——**

1. **访问形态**：标量 / 集合成员 / 多重集成员 / 带载荷的键值 upsert / 序列尾部追加；
2. **键的取值空间**：内容 `Id`（须经 `ContentRegistry` 解析）/ 固定枚举 / 无键（位置由序列尾部给出）；
3. **载荷的字段集合**：几个标量、还是一整个结构块，以及是哪些字段。

**三样全部相同才算这一面对齐。** 只比第 1 样会让「按内容 `Id` upsert 一条剧本锚点」与「按子流枚举键 upsert 一对 RNG 标量」被判为同形，从而推出「把 RNG 状态塞进 `PlotElements`」这类结论——两者的键要不要过内容注册表、载荷字段有没有一格重合，全都不同。**这不是给判据开口子，而是把它本就要比的东西写全**：形状是「怎么定位 + 定位到什么」，不只是「标量还是 upsert」。

**反判据（决定「配表」还是「逐条带」）：** 同一个 key 的**不同次**变更可能取不同值 ⇒ 必须**逐条带**在 element 上（`BaseValue`、`Tier`、`StatusAssignment` 的值、`ApplyOp`）。**唯一恒成立的例外是「谁有权改写它」永远是类型属性、永远配表、绝不逐条带**——逐条带会把一条纪律降级为调用方选项，且 `AppliedChange` 重放时同一 key 可能带不同配置。`ChangeElement` 不自带 `ModifierKey?` 正是这条的应用；而 `Op` 描述的是**这一次发生了什么**（事实，逐次不同），准入仍留在 `ElementSpec.AllowedOps` 里，故两者并存不冲突。

**为什么逐条按施加语义分列，而不是给 `ChangeElement` 加可空字段（承重判据）。** **施加语义根本不同就分列**——列表数不是这条判据的一部分，它随字段族增长，故此处不把数字写进承重表述。当前各列的语义：资源是**标量值**（可钳制、`Add` 时可加且带符号分向、`Set` 时是已算好的绝对值、**按 `ResourceElements` 表逐行决定是否走 modifier pipeline**），能力是集合成员操作（幂等增删、无量纲、**绝不走 modifier pipeline**），统计是纯计数（不钳制、失败不阻断、**绝不走 modifier pipeline**），Status 规则字段是**绝对置值**（赋一个已算好的值、不累加、按 key 的声明类型可为 id、**绝不走 modifier pipeline**），卡组是**带层数的构筑变更与多重集增删**（层数不可加、散牌可同名多张、无 `Source`、**绝不走 modifier pipeline**），剧本是**按 `ArcId` 的带载荷键值 upsert**（整条替换、无量纲、不钳制、**恒不走 modifier pipeline**），事件态是**整块绝对置值**（赋一份已算好的结构块或置空、无量纲、不钳制、**恒不走 modifier pipeline**），RNG 子流是**按子流枚举键的双标量 upsert**（幂等置值、无量纲、不钳制、**恒不走 modifier pipeline**），履历是**序列尾部追加一个大结构块**（**不幂等**、无量纲、不钳制、**恒不走 modifier pipeline**），账号级设置是**按固定枚举键的绝对置值**（要钳制、无量纲、双可空标量载荷格、**恒不走 modifier pipeline**）。把它们压进一个带符号 `int` 是**让类型说谎**；分开还使 `ApplyResult.MissingElement: CostKey` 的语义保持完好（它只对资源列表有意义）。**事务性不受影响**——各列表在同一次 `TryApply` 内提交，「全有或全无、单点提交」不变。否决的两个替代：`ChangeElement` 加可空 `TargetId` / 把 `Duration` 塞进 `BaseValue`（破坏带符号约定）；多态 element（`abstract record` + 子类，破坏 `readonly record struct` 的零分配与 diff / 序列化的简单形态）。

**`StatusChanges` 的取值域同样是逐行一张封闭表（`StatusFields`），与 `ResourceElements` 同款判据。** 每行给出该 key 的**值类型**（`Int` / `Id`）与取值域：band 的 `[-2, 2]` / `[0, 3]` / `[0, 2]` 来自档位表，`LocationEventCount` 的 `[0, ∞)` 来自计数语义——没有通则能给出这些区间，也没有通则能判断某个 key 该填哪一格。**`Id` 型的值须能经 `ContentRegistry` 解析**，解析不到即坏档。`StatusChanges` 恒不走 modifier pipeline，理由与统计层同源且更重：`CurrentLocationId` 若可被一条法则改写，等于让内容改写玩家的地图位置；band 若可被改写，等于让法则伪造隐藏属性档位。逐行取值与施加 / 失败语义见 `systems/services/profile-service.md`。

**`DeckElements` 承载卡组变更，`Tier` 写目标层数而非增量。** 卡组的施加语义与其余各列都不同：功法带**层数**，`UpgradeTechnique` 既不是集合意义上的 `Grant` 也不是 `Remove`；游离散牌是**多重集**（同一张业障可在卡组里出现多张），而集合成员操作的「已持有 → 空操作」会静默吞掉第二张；卡组条目也没有 `SourceCode` 挂载面，`AbilityChangeElement` 强制携带的 `Source` 对它无落点。**`Tier` 取目标层数**的理由与「element 只承载已定稿的 `Id`」同源：`AppliedChange` 要可直接重放，写增量会让重放结果依赖当时的层数。**恒不走 modifier pipeline**——一条法则若能把「层数 +1」放大成 +2，「进化 = 整组替换、每层一整套卡牌定义」直接失去意义（不存在「1.5 层」的定义）。逐条校验与失败语义见 `systems/services/profile-service.md`，卡组侧语义见 `systems/character-profile/deck/_index.md`。

**`EventStateChanges` 承载三个事件态字段（`activeEvent` / `eventOption` / `activeCombat`），语义是整块绝对置值。** 它按三级判据的 ① 分列：键与载荷的形状是**固定枚举键 → 整个结构块**（而非标量、集合成员或按内容 `Id` 的 upsert），既不钳制也无量纲，其余各列没有一列在这六面上与之对齐。**`activeCombat` 收在本列内、不另开一列**：它在六面上与 `activeEvent` 全部对齐（都是不钳制、恒不走 pipeline、必需缺失即整批拒绝、绝对置值故幂等、无量纲、固定枚举键 → 结构块），而判据明文要求六面全对齐即不分列。**列名不是分列判据**——`activeCombat` 本就被定性为事件内的中间态，寿命短于一次事件。**载荷落成具名可空字段而非裸 `object`**，与 `StatusAssignment` 的「双字段单列表、另一格填缺省」同构——贯穿链路的类型一致性不做隐式装箱，且「`Key` 与哪一格有效」因此可机械校验。**`ActiveEvent` 与 `ActiveCombat` 允许置空，`EventOption` 不允许**（收口必须清空前两者；轮回进行中把当前批置空即让玩家无路可走）。**恒不走 modifier pipeline**：一条法则若能改写 `RerolledCount`、商店库存或战场局面，等于账号级内容改写轮回级的定稿实例。字段语义与读档校验见 `systems/character-profile/_index.md`，施加与失败语义见 `systems/services/profile-service.md`。

**`RngElements` 承载四条具名 RNG 子流的状态，语义是按子流键的绝对置值 upsert。** 它按三级判据的 ① 分列，卡在**第六面**：一次提交常需更新多条子流（`EventStateChanges` 的「同批两条同 `Key` 即组装缺陷」正是相反的形状），而键是固定枚举、载荷是两个标量且无一格须过内容注册表（`PlotElements` 的键是内容 `Id`、载荷是五格剧本状态）。**不为它配一张逐 key 的表**——四条子流在取值域、终态、修正准入上完全相同，配一张四行全同的表只会长出一处必须与 `RngStream` 同步增删的枚举镜像，而三级判据的 ③ 要求的是「该性质逐 key 各不相同」。**`Seed` 不进 spec**：`streamSeed` 由 `CycleSeed` 与子流名重算得出，把可重算的值放进 spec 等于让重放依赖一份冗余真值。**恒不走 modifier pipeline**——一条法则若能改写随机流状态，它能改写的是整条确定性链。施加与失败语义见 `systems/services/profile-service.md`。

**`TraceElements` 承载 `pastEvent` 的追加，语义是序列尾部只追加。** 它按三级判据的 ① 分列，**第四、第六两面均不对齐**：追加**不幂等**（同一条提交两次得两条，而 `EventStateChanges` / `PlotElements` 都是幂等置值），且它无键——位置由序列尾部给出，载荷是一整个 `PastEventEntry`（`DeckElements.AddLooseCard` 的多重集追加形状同类，但载荷是三个标量且须解析内容注册表）。**直接复用 `PastEventEntry`、不建镜像类型**：`PlotKeyPointAssignment` 用镜像的成本近零（五个标量），而 `PastEventEntry` 字段众多且随快照判据继续增长，镜像一份等于制造两张必须同步增删的字段表。**分列的直接收益是「记入 `pastEvent`」并入收口那一次 `TryApply`**——「一个事件的收口是一次事务、一个存档点」由结构兑现，而不再由约定兑现。施加与失败语义见 `systems/services/profile-service.md`，条目形态见 `systems/adventure-event/common-properties.md`。

**资源 element 的语义是逐行一张封闭表，不是若干条全局通则（承重）。** `ResourceElements` 把「取值域」「触底是否构成终态」「两向修正接入」并成同一张表的五列，因为它们逐 element 各不相同：寿元与耐久归 0 构成终态，灵玉归 0 只是变穷；`PowerFragmentAccumulated` 的上界 `10000` 来自它自己的万分比语义，道心 / 煞气的 `[0, 100]` 来自档位表——**没有任何通则能给出这些区间**。修正列同理：「这个 element 能不能被法则改写」由它自己的语义决定（`LifeSpan` 是可被法则修正的成本量，`BundleRedeemedOrdinal` 是付费礼包的兑现水位），同样推不出通则。查表还使终态判定不必硬编码检查若干字段：「新增一个终态资源 = 表里加一行 + `DefeatReason` 加一个成员」，与「新增一张卡 = 新增一个 `.tres`」的可加性同向。**五列合成一张表而非拆成几张按同一个键索引的表**：分表必然出现「加了行 A 忘了行 B」，合表时漏填只是同一行里的空格。

**modifier pipeline 对 `Elements` 是 opt-in 白名单，缺省豁免（承重）。** 只有在表中显式登记了 `ModifierKey` 的那一行才经 pipeline，`AbilityElements` / `Stats` 永不经。**缺省方向必须取豁免侧**：漏填时若缺省豁免，最坏是某条法则本该修正它却没修正——数值不对、可见可复现、改一行修好；若缺省经 pipeline，最坏是某条法则**静默地**改写了幂等键 / 付费凭证 / 元进程计数，无人察觉，且在云端权威 + 后端复算下表现为两侧算不一致。两侧代价不对称。**按符号分向是必需的**：同一个资源 element 的消耗向与产出向共用一个 `CostKey`，一条「寿元消耗 −20%」的法则若不分向，会把寿元回复也削 20%。**`Op == Set` 恒不经 pipeline，与该行的两个修正列是否为空无关**：`BaseValue` 在 `Set` 下是一个已算好的绝对值，符号不表达方向，「按符号分向」无从判断该取哪一格；且让一条法则改写一个已算定的权威值（付费凭证序号、万分比累计）等于让内容改写权威值。配套的启动期断言把「允许 `Set` 的行两个修正列必须为 `null`」固定下来，使这条不靠人记。逐行取值、`ModifierKey` 的「只施加一次」判据与施加算法见 `systems/services/profile-service.md`。

**`ModifierKey` 的成员集合大于本表出现的 key 集合，这是有意的。** 「只施加一次」的判据是**该修正后的值是否需要在施加之前呈现给玩家**：需要 → 施加点在物化 / 展示侧，此时它**不得**再进本表。`ShopPrice` 正是这一档——商店价格必须先算才能标价，`ListPrice` 在物化时就已定稿，`Elements` 路径拿到的 `BaseValue` 已是修正后的数，再登记一次即打两次折。故它在 `ModifierKey` 里、`Jade` 那一行的两个修正列却恒为 `null`。**`ApplyModifier` 仍是通用查询**——非 element 路径的数值（商店价格、掉落权重、战斗内数值）照常各自调用它，本表只约束 element 施加路径。

**它落代码常量，不落 `.tres`。** 五列没有一列是平衡旋钮——`Min` 是取值域、`DepletionDefeat` 是终态语义、两个修正列是「谁有权改写它」的准入，改任一列改变的是规则而非难度；与 `(Kind, Scope, Source)` 合法子集表、`RngStream` 子流清单同类。落 `.tres` 会让一次 overlay 热更即可改写终态判据（把 `LifeSpan` 的 `Min` 调成 -50 等于取消寿元死亡）或给付费凭证挂上一个修正 key，而这类改动须走版本发布。

**截断只发生在「施加到 Profile 字段」那一刻；spec 与快照保留未截断的原值。** `ChangeElement.BaseValue` 与落进 `PastEventEntry.SelectCost` / `AppliedChange` 的快照一律记未截断值——截断进 spec 等于让账本记的不是实际发生的事，而 `AppliedChange` 的定位正是「可直接重放的账」。副产品：「超支了多少」这一信息不丢（由 `LifeSpanAfter == 0` 与 `AppliedChange` 中的原值相减得出）。这与「内容侧写正数量值、物化时取负、`TryApply` 按带符号施加」是同一条分层纪律：**每一层只做自己那一次变换，不把下游的语义提前**。**截断不构成 `ApplyResult.Fail`**——「全有或全无」约束的是「各列表是否一起落」，不是「每个 element 是否落满」。

**`SettingChanges` 承载账号级设置，语义是按 key 的绝对置值。** 它按三级判据的 ① 分列，卡在**要不要钳制**这一面与作用对象上：`StatusChanges` 在其余五面与它对齐，但那一列明写绑定 `CharacterProfile.Status` 上的**规则字段**，两者混住会让 `StatusFields` 的 key 同时指向两个对象——「这个 key 写哪个对象」从此要读上下文，正是配表判据要消掉的东西。**两个载荷格皆可空**（`int?` / `bool?`），与 `StatusAssignment` 的「另一格填缺省」刻意不同：`bool` 的 `false` 与 `int` 的 `0` 既是缺省也是合法值（音量 0 = 静音），非可空下「哪一格有效」在运行时判不出来，而 `StatusAssignment` 的另一格是 `string`（`null` 即缺省）——同库先例是 `EventStateAssignment` 的可空载荷格。**恒不走 modifier pipeline**：否则一条法则能改写玩家的音量与演出速度。逐行取值与失败语义见 `systems/services/profile-service.md`，字段语义与两侧切分见 `systems/player-profile/game-setting.md`。

**`RarityTier` 与 `Tier` 是两个东西，不得复用同一枚举、也不得互相换算。** `Tier { Narrow, Solid, Crushing }` 是战后奖励的**优势档**（道念差归一化后的碾压程度）；`RarityTier` 是**内容品质档**。类型名不写成裸 `Tier` 正是为了避免它们在 `systems/balance.md` 的同一页里造出两个含义。

#### 共享静态工具 `AtomicJsonFile`（`src/Core/`）

**`user://` 下小 JSON 文件的原子读写收敛为一个不属任何服务的共享静态工具。**

```csharp
public static class AtomicJsonFile          // 无状态；不持有任何服务引用，可在启动链最早期调用
{
    public static bool TryRead<T> (string path, out T value);   // 缺失 / 解析失败 → false，由调用方定失败语义
    public static bool TryWrite<T>(string path, T value);       // 临时文件 → rename；失败 → false
}
```

- **为什么它不归任何服务。** 现有写入方分散在四处以上：sync-service 的同步信封与待发队列 · content-service 的 flags 缓存 · UI 层的已关闭推荐版本号 · account-service 的设备标识 · 设置层的设备本地偏好。五份实现受同一条纪律却各写各的，**必然漂移，且漂移的形态正是「某一处漏了 rename，崩溃时留下半个文件」**——原子写这条纪律唯一要防的事。
- **它不违反「服务之间不伸手进对方 manager」。** 调用它不是跨服务调用，而是调用一个无状态工具；反过来把它挂在 `sync-service` 的 API 面上会长出「替我原子写一个任意文件」这种方法，且**启动顺序对不上**——设备标识在登录时就要读，那一刻 sync-service 尚未初始化。
- **它只管原子性与序列化，不管语义。** 版本判定、`accountId` 归属校验、缺失时的降级（`PushError` 还是 `PushWarning` + 默认值）一律留在各自的调用方——它们逐份文件各不相同，收进工具里等于让工具认识每一份文件。
- **`LocalCacheManager` 因此是它的调用方之一，不是原子写的实现方。**

#### EventBus 负载契约

| 事件 | 负载 | 广播者 |
|------|------|--------|
| `CycleStarted` | `(string CharacterId, int Chapter, ulong Seed)` | life-cycle |
| `EventResolved` | `(string CharacterId, string InstanceId, string EventId, int LifeSpanRemaining)` | life-cycle |
| `ChapterCompleted` | `(string CharacterId, int Chapter, Realm ReachedRealm)` | life-cycle |
| `CharacterDefeated` | `(string CharacterId, DefeatReason Reason, int RetriesLeft)` | life-cycle |
| `EventOptionsChanged` | `(string BatchId, int Revision)` | future-event |
| `PlotThresholdReached` | `(string CharacterId, HiddenStat Stat, int Threshold)` | future-event（代 PlotManager） |
| `CapabilitiesChanged` | **空负载** | profile |
| `AchievementTierReached` | `(string GroupId, int TierPercent)` | profile |
| `CombatTurnStarted` / `CombatTurnEnded` | `(int TurnIndex)` | combat |
| `CardResolved` | `(string CardInstanceId, string CardId)` | combat |
| `CombatFinished` | `(CombatOutcome Outcome, int CharacterMomentum, int EnemyMomentum, int RemainingLifeTotal)` | combat |
| `SyncStateChanged` | `(SyncState State, OpError LastError)` | sync |
| `ContentUpdateFinished` | `(ContentUpdateInfo Info, bool Success)` | content |
| `SessionChanged` | `(bool SignedIn, OpError Reason)` | account |

1. **负载只带 `Id` + 值类型，绝不带 `CharacterProfile` / `Resource` / `EventOption` 引用。** 传引用等于给每个订阅者开一条绕过唯一写入入口的旁路，也让定稿实例有被下游改写的可能。需要完整实例的订阅者按 `InstanceId` 向 future-event-service 取。
2. **`CapabilitiesChanged` 空负载。** 订阅者收到后自行 `ProfileService.Instance.Has(flag)` 重查——这正是既定的「一个 flag ↔ 一处消费点 · 单点查询」；把生效集塞进负载反而制造第二份真值。
3. **广播 = 既成事实，不可否决。** EventBus 不承载「请求 / 询问」；需要返回值的一律是直接方法调用。

#### API 书写规范

各服务文档的「API 面（契约）」小节统一为四列表：**方法 | 形态(A/B/C) | 完整签名 | 失败语义**。凡形状依赖未答问题的，写 `⟨待定：链接到待决项⟩`，不留空白也不臆造。

### 纪律的可执行化（八条总则的共同上位判据）

> 一条约定该做到哪一级，取决于**违反它的代价**——不取决于它写得多醒目。本判据是把本库已有的三处实践（`internal sealed` manager、`Async` 后缀、两条唯一入口）归纳成的显式阶梯，供日后遇到「这条约定怎么强制」时直接套用，不必逐条重新讨论。

| 级 | 手段 | 违反时 | 成本 |
|----|------|--------|------|
| **1 · 写不出来** | 类型 / 可见性 / 命名——错误的写法在语言层不存在或不合法 | 不可能发生 | 设计期一次性 |
| **2 · 编译不过** | `[Obsolete(error: true)]`、`#if` 条件编译、分析器 | 编译期报错 | 低～中 |
| **3 · 大声失败** | 启动期断言、切屏 / 退出期审计（一律 `#if DEBUG`） | 开发期 `PushError` | 低，但只在开发期生效 |
| **4 · 评审清单** | 文档条款 + 人工评审 | 靠人 | 零成本、零保证 |

**两条选级判据：**

- **能上线且线上不可见 → 必须做到第 1 或第 2 级。** 判据是「这条纪律被违反后，测试期能不能被发现」。违反后游戏照常运行、错误只在真实玩家身上显形的，**第 3 级不够**。
- **只在开发期显形、且违反后会累积 → 第 3 级足够**，不必付第 1 / 2 级的成本。

**通用补注 —— 内容侧纪律的等价第 2 级 = 发布管线跑同一份校验。** 阶梯的第 1 / 2 级手段（类型 / 可见性 / `[Obsolete(error: true)]` / 条件编译）全部作用于 **C# 代码**。有一类纪律的检查对象是 **`.tres` 的引用图**（剧本条目的引用约束、`EncounterScopes`、`NarrativeIds`、`RewardPoolId`、`locationMap` 连边），它不在这些手段的作用域内——C# 编译器与类型系统都触不到它，客户端侧的天花板是第 3 级。

**这类纪律的第 1 / 2 级等价物是：把同一份校验放进内容的打包 / 发布管线，不通过即不产包。** 喂「基线 + 待发 overlay」跑同一个 `LoadAll()` 路径，于是「线上收到一份带悬空引用的内容包」这一事件在**发布侧**就不可能发生，而不是等玩家启动时才 `PushError`——判据「能上线且线上不可见」的诉求（线上永不显形一次）照样满足，实现是零新增机制。

- **成立的前提是校验内嵌在打包工具本身**（产包的唯一路径），而非一个「记得跑一下」的独立步骤——后者退化为第 4 级。
- **客户端启动期的 `PushError` 保留为兜底**，它处理的是手工塞进 `user://overlay/` 这类非发布路径。
- **写成通用补注而非逐条例外**：`.tres` 的引用图不止剧本一处，逐条写例外只会把同一条论证重复五遍。

**四处应用：**

| 纪律 | 判据落点 | 落到第几级 | 形态 |
|------|----------|-----------|------|
| 离线后端不得发到线上 | 上线且不可见 | **1** | `BackendSelector` 唯一选择点 + `OfflineXxxBackend` 整类 `#if DEBUG`（总则 7）；ProjectSettings 开关与启动期断言为第 3 级兜底 |
| 抽取必走 `AllEnabled()` | 上线且不可见 | **1 / 2** | **删除中性名 `All()`**，只留 `AllEnabled()` + `AllIncludingDisabled()`；过渡期 `[Obsolete(error: true)] All()` 占位（第 2 级）。第二阶段前把 `AllEnabled()` 返回类型升为 `DrawPool<T>`、seeded 抽取只定义在其上（第 1 级）。见 `services/content-service.md` |
| EventBus 订阅必退订 | 只在开发期显形 | **3** | `#if DEBUG` 订阅审计，切屏后触发（总则 5） |
| overlay 新增剧本条目不得引用新的非剧本 `Id` | 上线且不可见 | **3 + 发布侧等价 2** | 合并期 `newIds` 双闸（全量 `PushError`，非 `#if DEBUG`）+ 打包工具跑同一份 `LoadAll()`、不通过不产包。见 `services/content-service.md` |

**「不插 `if`，也不插 `#if`」——条件编译的使用清单是穷举的，不得扩张：** `src/Core/BackendSelector.cs`、三个 `src/Services/*/Offline*Backend.cs`、`src/Autoload/EventBus.cs` 的审计块，**共 5 处**。服务与 manager 内部一律不得出现 `#if`。

> **一次已预告的、有边界的扩张：** 商业化落地时将新增**第四个窄接口 `IPurchaseBackend`**（平台内购 SDK + 后端验票是一条全新的跨进程边界，其失败语义——用户取消 / 订单待处理 / 票据重复 / 跨设备重复到账——与 `IProfileBackend` 完全不同），条件编译清单相应由 **5 → 6**。这遵守总则 7 的**本意**（防「服务内插 `if (offline)`」造成半在线态，而非禁止新增边界服务），**不构成对该纪律的普遍松动**：清单仍是穷举的，新增仍需逐次裁决。**本次不新增接口**——商业化落地在 `vision/scope.md` 的「范围之外（暂时）」内，裁决点留到真正需要它的时候。**否决**把 `CreateOrderAsync` / `RedeemReceiptAsync` 挂进 `IProfileBackend`（清单虽不变，却把「档案同步」与「支付」两个语义无关的边界混住，且 `OfflineProfileBackend` 要同时假装是内存回显和假支付网关）。见 `systems/monetization.md`。

**否决记录：** Roslyn 分析器（单独项目要维护、随 Godot 生成的 `.csproj` 走易被覆盖、无 CI 前提下只在本机构建生效；`[Obsolete(error: true)]` 拿到同一份编译期保证）· 把「上线且不可见」类纪律只做到第 3 级（断言只在跑到那一步时生效，而这类违规的症状恰恰是「一切正常」）。

### adventure-event 子类型层级
- **AdventureEvent = 逐时逐刻的游玩单元。** 展开为按子类型分文件夹的深层结构（`systems/adventure-event/<子类型>/`），每个子类型含 `_index.md` + `common-properties.md`。
- **五类子类型：** Combat（战斗，唯一走战斗结算，内含 `combatTier { Practice, Standard, Finale }` 三档）、Exchange（交易，含社交语境）、Research（闭关，调整 / 升阶卡组）、Explore（探索秘境，唯一的元类型）、Travel（前往某处地点 = 地图路由）。分类权威见 `terminology.md` 与 `decisions/ADR-0002`。
- **Travel 特例：** 功能上是地图路由——刷新角色 location，从而框定 eventOptions（location 抽象归 `systems/game-progression.md`）。

### 数据流（目标）
```
启动 ──▶ content-service (manifest 版本比对 → overlay 增量 → 合并 → 校验)
登录 ──▶ account-service ──▶ sync-service.Pull ──▶ profile-service.Hydrate
                                                      └─▶ CapabilityManager 聚合
                                                            ──▶ EventBus: CapabilitiesChanged

Input (touch, 横向滑动选择)
   ──▶ Screen scene (月圆之夜式菜单)  ◀── ViewModel (呈现期组装 Data + 运行时状态; 不落存档)
        ──▶ game-progression (编排顶点: 呈现 eventOptions 供选择)
             ──▶ future-event-service (物化 AdventureEvent → eventOptions; 唯一物化点 / 唯一出口)
             │      ├─▶ PlotManager (隐藏属性阈值 → 调制; key points → 本地剧本节点; 纯本地)
             │      └─▶ location (由 Travel 刷新) + SeedManager 的 map 子流
             ──▶ life-cycle-service.AdvanceEventAsync (EventOption 定稿实例; mode = Select | Skip)
                   ├─▶ profile-service.ProfileManager (唯一写入面; 原子施加成本 / 产出)
                   ├─▶ 【eventStart 阶段】 → IEventResolver → 【eventEnd 阶段】(结算流程的阶段名)
                   │      └─▶ combat-service (Combat / Finale: 回合循环状态机)
                   ├─▶ content-service.ContentRegistry (按 Id 读内容: card / item / enemy / event ...)
                   └─▶ EventBus (广播轮回 / 篇章 / 剧情 事件) ──▶ 其他系统 / UI
   sync-service ◀── 自动存档点 ── PlayerProfile ⊃ CharacterProfile ──▶ 云端 (权威; user:// 仅缓存)
                                   (SeedManager 的具名子流驱动全部随机性)
```

Source: `handoffs/2026-07-24-docs-restructure-class-model.md` · `handoffs/2026-07-25b-event-cost-fields-capability-flags-and-service-hierarchy.md` · `handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md` · `handoffs/2026-07-27b-service-api-contracts.md` · `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md` · `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md` · `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md` · `handoffs/2026-08-04b-mtg-loanwords-card-types-and-intent-snapshot.md` · `handoffs/2026-08-06d-combat-open-questions-mass-closure.md` · `handoffs/2026-08-09-sync-revision-cas-and-immediate-flush-nonblocking.md` · `handoffs/2026-08-09e-discipline-enforceability.md` · `handoffs/2026-08-10c-ability-disable-replacement-and-player-statistics.md` · `handoffs/2026-08-11-plot-content-localization.md` · `handoffs/2026-08-11b-contract-boundary-and-flags-client-side.md` · `handoffs/2026-08-12-error-copy-and-update-prompts.md` · `handoffs/2026-08-14c-content-authoring-layer.md` · `handoffs/2026-08-15b-monetization-entitlement-purchase-shape-and-scope.md` · `handoffs/2026-08-16d-cost-side-closure.md` · `handoffs/2026-08-16f-elements-modifier-pipeline-opt-in.md` · `handoffs/2026-08-16i-plot-data-encoding.md` · `handoffs/2026-08-17-travel-destination-and-status-change-elements.md` · `handoffs/2026-08-17d-exchange-mechanics-and-transaction-discipline.md` · `handoffs/2026-08-17g-element-carrier-gaps.md` · `handoffs/2026-08-17h-profile-field-schema.md` · `handoffs/2026-08-17j-event-option-derived-persistence.md` · `handoffs/2026-08-19-profile-change-spec-gaps.md` · `handoffs/2026-08-19-costkey-statkey-registry.md` · `handoffs/2026-08-19-game-setting-schema.md` · `handoffs/2026-08-19-device-id-provisioning.md` · `handoffs/2026-08-19-architecture-structural-residuals.md`

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- **修行事件分类（含 Explore / Travel）** → `decisions/ADR-0002-adventure-event-taxonomy.md`（Accepted；待补订 Explore / Travel）。
- **境界存档 · 篇章重试模型** → `decisions/ADR-0004-realm-checkpoint-retry-model.md`（Accepted）。
- **强制在线 · 云端权威** → `decisions/ADR-0003-online-cloud-authority.md`（Accepted）。
- **`.claude/knowledge` 降为引用层（本库成为内容 + 技术结构双重事实来源）；引用层形态 = 薄引用（副本判据：设计库里已是代码形态的东西只留链接）** → `decisions/ADR-0005-knowledge-thin-reference-layer.md`（Accepted）。
- **展示层三层切分（Data / 运行时·存档 / ViewModel）** → **ADR 候选**（待固化；**固化时的主落点是 `systems/viewmodel.md`**，本文件保留三层定义段）。
- **五级层次 service ⊃ manager ⊃ module ⊃ processor ⊃ handler；拆分轴 = 生命周期层 + 行为边界（非数据类型）** → **ADR 候选**（待固化）。
- **单一 profile-service 拥有两层 profile（ProfileManager 唯一写入面）；ContentRegistry 唯一内容读取入口；game-progression 为编排顶点** → **ADR 候选**（待固化）。
- **内容载体形态（随包基线 + `user://overlay/` 热更 + 云端版本校验）与本地 / 云端内容分界** → **ADR 候选**（待固化）。
- **PlotManager 隶属 future-event-service，eventOptions 唯一出口** → **ADR 候选**（待固化）。
- **API 契约总则（三种方法形态 / 三分失败语义 + `OpResult` / 服务门面骨架 / Bootstrap 启动契约 / EventBus 用 C# 泛型事件 / 后端接口化 / 结算阶段名）** → **ADR 候选**（待固化）。
- **物化模型：`AdventureEventData` 为模板、future-event-service 为唯一物化点、`EventOption` 产出即定稿且落存档** → **ADR 候选**（待固化）。
- **`CostSpec` / `RewardSpec` 合并为单一 `ProfileChangeSpec`（element 带符号）**。
- **纪律的可执行化四级阶梯 + 两条选级判据 + 内容侧等价第 2 级（发布管线跑同一份校验）** → **ADR 候选**（待固化，与「API 契约总则」并列）。

Source: `handoffs/2026-07-25b-event-cost-fields-capability-flags-and-service-hierarchy.md` · `handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md` · `handoffs/2026-07-27b-service-api-contracts.md` · `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md` · `handoffs/2026-08-09e-discipline-enforceability.md`

## 闭环缺口（架构体检）

> 架构体检列出的 8 处缺口**已全部闭合**。

| # | 缺口 | 状态 |
|---|------|------|
| 1 | PlayerProfile 侧无服务 | **已闭合** → profile-service（ProfileManager / CapabilityManager / AchievementManager） |
| 2 | 战斗内部无归属 | **已闭合** → combat-service（唯一自带状态机的事件类型；Finale 复用） |
| 3 | 存档 / 云同步无归属 | **已闭合** → sync-service（ProfileSyncManager / LocalCacheManager / MigrationManager） |
| 4 | 本地 / 云端内容分界未定 | **已闭合** → **没有云端内容通道，一切内容属本地内容层**；「是否被存档引用」只决定 overlay 能否为它新增 `Id`（剧本内容可新增，是唯一例外） |
| 5 | skip 通道无结算归属 | **已闭合**（以移除该通道的方式）→ 跳过、`skipCost`、`ifMandatory`、单项补位整体删除；一批只有一次操作（择一进入），选中一个即等价于跳过其余 |
| 6 | `selectCost` / `lifeSpanCost` 重叠 | **已闭合**（包含关系）；ProfileManager 是其唯一消费点 |
| 7 | 编排顶点缺失 | **已闭合** → game-progression |
| 8 | UI 与服务间无契约层 | **已闭合** → ViewModel 层 |

**API 契约**见上方「API 契约总则」。**剩余的结构性未决项**已下沉为各服务文档的待决问题（`EventOption` 完整物化字段清单、内容分桶粒度、协议报文字段），见下节与 `services/*`。

Source: `handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md` · `handoffs/2026-07-26-event-priority-skip-semantics-and-hotfix-scope.md`

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

> _（当前无未决项。）_


## 对应
提炼至：`.claude/knowledge/architecture.md`（**薄引用层**，ADR-0005：导航 + 代码现状 + 承重一句话，代码形态内容只回链本文件，不留副本）。
