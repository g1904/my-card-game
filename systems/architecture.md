# architecture（代码库如何运作的高层指南）

> 类模型化（Java class 式）结构总览：systems ≈ 一组类；character-profile / player-profile 为核心「类」，services/ 下的服务（内含 manager）对其提供 API；adventure-event 子类型层级；数据流。
> **本文件是结构与边界的权威**；「代码跑起来是什么样」的端到端运行链路见根级 `program-overview.md`；「工程里长什么样」（进程边界、文件夹布局、autoload 注册、代码形态）见根级 `system-overview.md`。深入代码侧知识见 `.claude/knowledge/architecture.md`（引用层）。
>
> **「服务」= 进程内模块单例**（同一 Godot 二进制、同一进程、直接 C# 方法调用），**不是**分布式微服务。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

### 类模型化结构总览
- **systems ≈ 一组 Java 类。** 每个系统是一个「类」，其内容（数据定义）是该类的「字段 / 内嵌类型」——内容并入系统，不单列内容层。Source: `handoffs/2026-07-24-docs-restructure-class-model.md`。
- **复杂类型下沉为文件夹。** 简单主题保持单 `.md`；复杂主题（各 adventure-event 子类型、deck、item、player-power……）各占一个文件夹，含 `_index.md` 与 `common-properties.md`，为「每个具体设计一个 Markdown」预留结构。
- **共有属性显式化。** 每一层的共有字段抽到 `common-properties.md`：adventure-event 各子类型各自一份、adventure-event 顶层一份、systems 顶层一份（`systems/common-properties.md`）。

### 核心「类」：character-profile / player-profile
- **PlayerProfile / 玩家信息（账号级主档，元进程层）：** 跨轮回持久，持有 `List<CharacterProfile>`、`GameSetting`、`List<PlayerPower>`、`List<PlayerItem>`、`List<Achievements>`、`AccountInfo` 等。结构权威见 `systems/player-profile/`。
- **CharacterProfile / 角色信息（单次轮回）：** 一次轮回 / 一个角色的状态与历史（对齐 CycleState 概念）：`status`（ongoing | defeated | completed）、`chapter`、`Status`（lifeTotal / mana + 隐藏属性 道心 / 煞气 / 寿元）、`List<AdventureEvent>`、`List<CharacterItems>`、AdventurePlot key points 等。结构权威见 `systems/character-profile/`。
- 这两者是被服务操作的**数据核心**；它们不自己驱动轮回生命周期、事件生成或剧本下发，而是被服务读写。

### 服务层：五级层次 service ⊃ manager ⊃ module ⊃ processor ⊃ handler（**已定案**）

**抽象层次不封顶在两级**，但每一级都有**固定的层级词**——名字的后缀即宣告它在第几层。完整清单见 `services/_index.md`；运行时端到端链路见根级 `program-overview.md`。Source: `handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md` + `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。

| 层级 | 名称 | 说明 | 现有实例 |
|------|------|------|---------|
| 第一级 | **service** | 边界单元，autoload；三判据（见下） | 七个服务 |
| 第二级 | **manager** | 服务内部的职能组件 | TurnManager、ProfileManager…… |
| 第三级 | **module** | manager 内部的组件 | **`DeckModule`**（CharacterManager / EnemyManager 各持一份） |
| 第四级 | **processor** | 预留 | — |
| 第五级 | **handler** | 预留 | — |

> **纪律不随层数放宽：** 边界仍是「服务之间不读写对方字段、不伸手进对方 manager」；同理**不得跨层直呼**——外部只看得见宿主服务的 API 面，module 及以下一律是宿主 manager 的内部实现。**第四 / 第五级目前没有实例，且暂不落实例——保持空是健康的。**

**module 以下的下沉判据（已定案）：判据的轴从「职责」换成「形态」。** 前三级各有其轴——service = **边界**（三判据）、manager = **职能**（服务内的一块职责）、module = **可复用的部件**（`DeckModule` 每个参战方各持一份，其成立依据正是「同一形状被实例化多次」）。顺着这条轴：

> **processor = 无状态的处理阶段；handler = 按 kind 分派的叶子。**

- **拆出 processor 需三条判据全中（与门）：**
  1. **它是一个可独立命名的处理阶段**，输入 / 输出明确，**不持有跨调用的状态**（或只持一次调用内的临时状态）。——**这是与 module 的分界**：module 持有状态（`DeckModule` 拥有三个区），processor 不持有。它也是「拆分轴 = 生命周期层 + 行为边界」这条既定轴在第四级的延续（无状态 = 无独立生命周期）。
  2. **它有 ≥ 2 个同形态的实现，或有明确的可替换性**（规则变体、按数据选实现）。单一实现且永不变体的一段代码，拆出去只是换个文件名。**本库已经在实践这条判据**——九类事件只有 2 个 `IEventResolver`，正是同构的先例。
  3. **拆出后调用入口仍只有宿主 module 一个**——不产生第二个调用方、不越层被 manager 直呼。
- **下沉到 handler（第五级）的判据：存在一个开放的 `kind` 枚举，且每个 kind 的处理互不共享状态** → 一个 kind 一个 handler，由 processor 按 kind 分派。**「开放」是关键词**：kind 集合封闭且稳定时（如 `TurnStep` 三值），一个 `switch` 比五个 handler 类清晰得多。**handler 的价值在可加性**——新增一个 kind = 新增一个 handler 文件，与「新增一张卡 = 新增一个 `.tres`」是同一条可加性纪律在代码侧的投影。
- **三条反判据（明确不拆）：** ① 只是「这个文件太长了」；② 只被调用一次且无变体；③ 为了让层级看起来更完整。**层数不是成熟度指标**——「抽象层次不封顶在两级」这句话同时也意味着**不封底**。
- **校准样本（列出但不构成排期）：** 目标合法性筛选（`StackManager` 内）**最强候选**（无状态 ✅ / 按目标类别与次类型筛选有天然变体 ✅ / 只被结算流程调用 ✅）· 效果施加（`StackManager` 内）**强候选**，其下**可能**是 handler 的第一处用武之地（一个效果 kind 一个 handler）· seeded 洗牌（`DeckModule` 内）**不拆**（只有一种洗法）· 意图生成（`EnemyManager` 内）**暂不拆、观察**。
- **「先有判据、后有实例」为定案**，比先造实例再补判据安全。**已知代价**：判据偏严可能出现「该拆没拆」的巨型 module——**接受**，巨型 module 是**局部**问题（宿主 manager 之外看不见它），而层级滥用是**全局**问题（词表失去意义、每个人自造层），两害相权取局部。
- **连带：`BattlefieldManager` 提级仍不推荐。** 本判据只消解了它此前四条理由中的第二条（「级联降级会强迫回答一个尚无判据的问题」），其余三条依然成立。

Source: `handoffs/2026-08-06d-combat-open-questions-mass-closure.md`。

- **service（服务）= 边界单元。** 值得成为服务当且仅当命中**三条判据之一**：① 拥有**自己的状态机或跨多帧的长流程**；② 需要**事务性地跨多个字段一致写入**（全有或全无）；③ 坐在**外部 I/O 边界**上（网络、存档、平台 SDK）。服务以 autoload 形式存在，**不持有独立数据**，只操作核心「类」。**边界纪律（已定案的准确措辞）：服务之间不读写对方字段、不伸手进对方 manager；跨服务的方法调用（经对方的服务门面 `Xxx.Instance.Method(...)`）允许。** 编排顶点 game-progression 负责「谁在什么时机调谁」的屏幕流程串联，但**不是**一切跨服务调用的必经中转；既成事实经 EventBus 广播。Source: `handoffs/2026-07-27b-service-api-contracts.md`。
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

> **combat-service 的战场与栈各自一个 manager（08-03）。** **BattlefieldManager** 持有 **battlefield（战场）**——场上正在生效的卡牌 / 持续状态 / **触发器注册面**；**StackManager** 持有栈（压栈、LIFO 结算、连锁触发顺序）。**栈 = 等待结算的队列，战场 = 已结算并正在生效的东西**，是两个区；TurnManager 因此回落为纯粹的回合状态机。Source: `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md`。

> **战场与两个参战方 manager 的划线判据 = 「是否在场上生效」（08-04b）。** 一件东西**在场上生效、可被效果针对 / 查询、需在结束阶段被清理、需进决策点存档** → **战场条目，归 BattlefieldManager**，条目自带 `OwnerSide` 表示归属方；**参战方的私有资源与牌堆**（mana、道念、手牌、卡组、本场可用道具）→ 归 CharacterManager / EnemyManager。**「属于谁」只是条目的一个字段，不是它的住处**——附着在某一方身上的持续状态（「我方本回合所有牌 +1 道念」）因此是战场条目。**单一战场记录，不分双场区容器。** **读侧统一、写侧分权**：需要整场信息的场合读 combat-service 组装的 `CombatSnapshot`（第一级已是「拥有整场信息的顶点」），写入仍各归其主。**层级不动**——BattlefieldManager 不提级、两个参战方 manager 不降级：提级会让它变成 god object，并把 `DeckModule` 压到第四级、强迫回答尚无判据的「module 以下的下沉判据」；且层级词表的拆分轴是**生命周期层 + 行为边界**，而战场与两个参战方的生命周期完全同长（一场战斗），不存在包含关系。Source: `handoffs/2026-08-04b-mtg-loanwords-card-types-and-intent-snapshot.md`。

> **combat-service 的卡组 = `DeckModule`（第三级）。** 抽 / 弃 / 洗与 seeded 洗牌由 CharacterManager 与 EnemyManager 各自持有的 `DeckModule` 承担，**每个 character / enemy 一份**（敌人也出牌）。它不是平级 manager，而是 manager 内部的 module。Source: `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md` + `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。

#### 拆分轴：生命周期层 + 行为边界，**不是数据类型**（已定案）

**不**按 `power` / `item` / `card` / `resource` 各开一个服务：那会**撕碎事务**（一次结算典型要同时改多种资源，已定的 `selectCost` 复合成本类型的天然消费者是**一个**统一施加点）、**横切生命周期层**（`PlayerItem` 账号级跨轮回与 `CharacterItems` 轮回级即清，持久化与清理规则完全不同）、并退化为**无规则的贫血 CRUD**。同理**不为九类 AdventureEvent 各开服务**——只有 Combat 真有状态机，其余差异在**数据**而非**代码**（Finale 复用 combat-service，Mystery 揭示后落到真实 `eventType`）。

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

> 原问题：核心「类」目前只携带编码（`Id` / 数值），前端要用的描述字段应包含进去，还是为「充血模型」单建一套展示类？**已定案：不为充血另建并行类，按生命周期切分三层。** Source: `handoffs/2026-07-25b-event-cost-fields-capability-flags-and-service-hierarchy.md`。

1. **静态展示文本留在数据资源上。** `XxxData : Resource`（`.tres`）除 `Id` 与玩法数值外**直接携带**显示名 / 描述 / 图标——这本就是 `data-resource-rules.md` 的既有约定（显示字符串与 `Id` 分离、可本地化）。另建并行展示类只会制造两份需同步的真值。
2. **运行时 / 存档态只带 `Id` + 可变状态。** CharacterProfile 及其持有的运行态对象**不复制展示文本**——存档与上行云端负载保持轻量可版本化，文案变更不触发存档迁移。
3. **组合展示走 UI 层轻量 ViewModel。** 动态描述（数值代入、条件文案、随 capability flag 变化的可见性）由展示层按需组装 `Data + 运行时状态 → ViewModel`，只存在于呈现期，**不落存档、不进云端负载**。

**ViewModel 层因此是架构中的一个显式层**：位于 services / 核心「类」与屏幕场景之间，是「服务 → 屏幕」的数据形态契约。它单向依赖（读 Data + 运行时状态），不被服务反向依赖，也不参与存档 / 同步。

### API 契约总则（**已定案** · 贯穿七个服务）

> 七个服务的 API 面由「意图草图」升为**契约**。以下八条总则是全局规则，各服务文档的「API 面（契约）」小节在其约束下书写。Source: `handoffs/2026-07-27b-service-api-contracts.md`。

#### 总则 1 —— 三种方法形态，按「它跨什么边界」决定

不允许混用。**形态 B / C 一律带 `Async` 后缀并返回 `Task`，形态 A 一律不带**——看签名即知它是否跨边界。

| 形态 | 适用 | 签名形状 | 理由 |
|------|------|----------|------|
| **A · 同步直返** | 纯内存查询与纯本地事务（查内容、施加变更、能力查询、RNG 派生、物化） | `T Get(...)` / `ApplyResult TryApply(...)` / `bool Has(...)` | 无 I/O、单帧内完成；引入 `Task` 只会给每次查询加一次状态机分配 |
| **B · `Task<OpResult<T>>`** | 跨客户端 ↔ 后端边界的一切（account / content update / sync push-pull / PlotManager 请求剧本） | `Task<OpResult<PlayerProfile>> PullProfileAsync(string accountId, CancellationToken ct)` | 网络失败是**常态而非异常**；`Task` 让离线 stub 变成一行 `Task.FromResult`，也让超时 / 取消 / 重试有统一挂点 |
| **C · `Task<T>` 由信号推进** | 跨多帧的玩法长流程（`RunCombatAsync`、`AdvanceEventAsync`） | `Task<CombatResult> RunCombatAsync(...)`，内部 `await ToSignal(...)` 等玩家输入 | 调用方要的是「战斗打完给我结果」这一件事；帧级推进封在服务内部，不外泄成状态机 |

#### 总则 2 —— 失败语义三分，与 null-check 规则一一对应

| 失败性质 | 形状 | 例 |
|----------|------|-----|
| **必需缺失 = 程序缺陷 / 坏数据** | `GD.PushError($"[Svc-Method] ..., id={id}")` + `throw` | `ContentRegistry.Get(id)`、启动期校验 |
| **可选缺失 = 调用方可降级** | `bool TryXxx(..., out T value)`，返回 `false` 前 `GD.PushWarning` | `ContentRegistry.TryGet`、`TryGetActiveCharacter` |
| **业务失败 = 预期内的拒绝** | 返回 `OpResult` / `OpResult<T>` / `ApplyResult`，**绝不抛** | 网络不通、token 失效、重试耗尽（**事件推进不再因「付不起」被拒绝**，见总则 8） |

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
public interface IBootstrappable          // 由四个边界服务实现
{
    Task<OpResult> InitializeAsync(CancellationToken ct);
}
```

顺序：`ContentService.InitializeAsync`（版本比对 + overlay 合并 + 校验，断网降级到基线）→ `LoginScreen` → `AccountService.SignInAsync` → `SyncService.InitializeAsync`（pull + 迁移）→ `ProfileService.Hydrate` → `MainMenu`。三个纯本地服务（profile / life-cycle / combat）**不实现该接口**。这给了「首启不依赖网络下载内容，但进入游戏仍需登录」一个明确落点。

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

**退订纪律的强制形态 = `#if DEBUG` 订阅审计（阶梯第 3 级，已定案）。** 漏退订不改变玩法结果（幽灵订阅者收到的是既成事实广播，不可否决），只吃内存并可能对已 `QueueFree` 的节点调方法，**开发期即可显形**——按「纪律的可执行化」的选级判据，第 3 级足够，不必付第 1 / 2 级的成本。形态四条：

1. **判据：** 遍历 `event` 的 `GetInvocationList()`，`d.Target is GodotObject go && !GodotObject.IsInstanceValid(go)` 即泄漏。
2. **定位信息取自 `d.Method`，不取自 `d.Target`。** 泄漏发生时目标实例已释放，`Target.ToString()` 无用；`Method.DeclaringType.Name + "." + Method.Name` 是反射元数据，**不依赖实例存活**，直接给出 `CombatScreen.OnCardResolved` 这样可定位的名字。**因此订阅时不需额外登记来源，`+=` 的惯用形态原样保留。**
3. **触发时机 = 每次屏幕切换完成后**，由编排顶点 game-progression 调一次 `AuditSubscribers()`。屏幕场景是订阅者的绝大多数，切屏正是它们被释放的边界；频率 = 每次切屏一次，**零热路径成本**。**否决「每次 `Emit` 顺带检查」**——`GetInvocationList()` 每次分配数组，`CardResolved` 在战斗热路径上，直接撞「热路径不分配」。**EventBus 自己的 `_ExitTree` 只打一条订阅计数摘要，不做泄漏判定**：此时七个 autoload 服务可能正在同步销毁，`IsInstanceValid` 会对它们误报。
4. **泄漏检查豁免 autoload 服务的订阅**——服务与游戏同生命周期，它们的订阅按定义不是泄漏。用 `IsInstanceValid` 在切屏时机作判据天然满足这一点，这也是必须避开 `_ExitTree` 判定的原因。

Source: `handoffs/2026-08-09e-discipline-enforceability.md`。

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

```csharp
public sealed record EventOption(                 // 定稿实例：immutable 引用类型，落存档
    string             InstanceId,                // 本次物化实例的稳定标识；pastEvent / 存档引用它
    string             EventId,                   // 溯源到模板
    EventType          EventType,                 // Mystery 时 = 遮罩类型；真身见 RevealedEventId
    int                Priority,                  // 物化时置位；取值域 { 0, 1 }
    ProfileChangeSpec  SelectCost,                // 物化时组装（modifier pipeline 尚未施加）
    bool               IsRevealed,                // Mystery：是否已揭示
    string             RevealedEventId            // Mystery 遮罩的固定事件（物化时即已确定）
    /* ⟨待定：其余物化字段清单⟩ */);
```

**为何是 `sealed record`（引用类型）而非 `readonly record struct`：** 字段多、要落存档、一批只有个位数个、不在每帧热路径——按值拷贝的代价高于一次分配。`record` 的 `with` 表达式同时给出「定稿后若确需派生（如 Mystery 揭示）就产生一个新实例而非改旧的」这一惯用法。

**三条推论：**

1. **定稿实例必须落存档，不能只存 `EventId` 事后重算。** 物化用了 seeded RNG、当时的角色状态、以及可被 overlay 热更的模板；确定性只在同一 `contentVersion` 内成立。因此**当前批 eventOptions 与 `pastEvent` 痕迹都要存物化后的快照**。
   **快照存哪些字段由一条判据给出（08-09c）：「重算不出来的存，重算得出来的不存」**——文本类字段一律留在模板侧（**风味文案也不物化**），物化产出的数值必进快照。它与「运行时 / 存档态只带 `Id` + 可变状态、不复制展示文本」**不冲突**：后者管展示文本，本条管物化数值。痕迹条目 `PastEventEntry` 的完整形态见 `systems/adventure-event/common-properties.md`。
2. **`InstanceId` 与 `EventId` 并存且不可互相替代。** 同一模板可在一次轮回里被物化多次；`pastEvent` 与 `EventResolved` 负载都按 `InstanceId` 定位。
3. **通则：** 凡「内容定义 + 情境 / 轮回内状态」的组合都是两个类型——`AdventureEventData` ↔ `EventOption`（**定稿不可变**）；`CardData` ↔ `CardInstance`（运行态**可变**）；**`EnemyData` ↔ `EnemyInstance`**（**定稿不可变**；future-event-service 取模板 → 充实 / 改写 → 指派给事件，**敌人等级即物化产物**；条目定义归 `systems/enemies/`）。共享纪律：**服务签名里传实例，不传 `Resource`**；差别只在实例是否可变。这与展示层三层切分同构，把第二层的类型形态明确了。

#### 总则 7 —— 后端接口化：四个边界服务各持一个可替换后端

把跨进程边界的调用收敛到四个窄接口，让离线 stub 是「换一个实现」而非「在服务里插 `if (offline)`」：

```csharp
internal interface IAccountBackend  { Task<OpResult<Session>>          SignInAsync(LoginChannel c, CancellationToken ct); }
internal interface IContentBackend  { Task<OpResult<ContentManifest>>  GetManifestAsync(CancellationToken ct); }
internal interface IProfileBackend  { Task<OpResult<ProfileSnapshot>>  PullAsync(string accountId, CancellationToken ct);
                                      Task<OpResult<PushAck>>          PushAsync(ProfilePayload p, CancellationToken ct); }
internal interface IPlotBackend     { Task<OpResult<PlotSegment>>      ResolveAsync(PlotRequest req, CancellationToken ct); }
```

每个接口两份实现：`HttpXxxBackend`（后端就绪后）与 `OfflineXxxBackend`（当前阶段，读 `res://` 假数据 / 内存回显）。

**选择形态（已定案）：唯一选择点 `BackendSelector` + Release 构建里离线实现根本不存在。** 四个服务**不各自持开关**——由 `src/Core/BackendSelector.cs` 的 `CreateAccount()` / `CreateContent()` / `CreateProfile()` / `CreatePlot()` 产出实现，四个 `OfflineXxxBackend` **整类包在 `#if DEBUG` 内**（阶梯第 1 级：Release 下写不出对离线实现的引用，配错连编译都不通过）；开发期的开关载体是 ProjectSettings 自定义项 `mycardgame/backend/use_offline_backend`（第 3 级兜底），**不是 `[Export]`**。落地形态、启动期审计与「条件编译共 6 处、不得扩张」的清单见 `system-overview.md` 第四节，选级理由见下方「纪律的可执行化」。Source: `handoffs/2026-08-09e-discipline-enforceability.md`。

> **理由（承重）：** 四个字段 = 四个可能各自出错的点，最糟的失败态是「三个开了一个没开」的**半在线状态**——它比全离线更难诊断（登录成功、内容加载正常，只有存档静默写进内存回显）。收敛成一个选择点后，这个失败态在结构上不存在。这与两条唯一入口 + 唯一物化点是同一条纪律。

> **不插 `if`，也不插 `#if`：** 服务与 manager 内部一律只见 `IXxxBackend` 接口。

> 这四个接口是客户端 ↔ 后端**协议契约的客户端一侧投影**；其权威在 `backend-design-documents/`。本库只定客户端的**调用形状**（方法名、参数、`OpResult` 语义），不定 HTTP 路径 / 报文字段。

**`IProfileBackend` 的两个返回类型都带 `revision`**（`ProfileSnapshot(Profile, Revision, SchemaVersion)` / `PushAck(NewRevision, Deduplicated)`）——`revision` 是**后端分配的账号级单调递增 `long`**，客户端持有的基线值 `baseRevision` 是**传输层元数据**（落 `user://cache/sync-envelope.json`，不进 Profile、不进存档 schema）；上行走 **CAS**，并携带幂等键 `pushId` 防「请求已达、响应丢失」时丢进度。语义、三分支表与校验点见 `systems/services/sync-service.md`。Source: `handoffs/2026-08-09-sync-revision-cas-and-immediate-flush-nonblocking.md`。

#### 总则 8 —— 结算阶段名取代「事件自带钩子」

`eventStart` / `eventEnd` 是 `AdvanceEventAsync` 内部结算流程的**两个阶段名**，不是 `AdventureEventData` 上的方法。落地为数据驱动的结算器：

```csharp
internal interface IEventResolver          // 按 eventType 注册，共 2 个实现
{
    Task<ResolveOutcome> ResolveAsync(EventOption option, CancellationToken ct);
}
// CombatEventResolver  → Combat / Finale，转 combat-service
// GenericEventResolver → 其余七类，读模板上的数据驱动 outcome / effect 定义
```

`AdvanceEventAsync` 的固定流程：

```
校验选项合法性（Priority < EffectivePriority → 拒绝）
  → TryApply(SelectCost)                     ← 无条件施加；不做「付得起」校验（08-06c）
  → 终态判定 ①（支付后立即）                 ← 判负 → 短路进失败流程，不再进入 resolver
  → 【eventStart 阶段】选 resolver、Mystery 揭示
  → resolver.ResolveAsync(option, ct)
  → 【eventEnd 阶段】合并 ResolveOutcome + lifeSpanCost + 隐藏属性推拉为**一次** TryApply
  → 记入 pastEvent（按 InstanceId，携带定稿实例快照）
  → 终态判定 ②（结算后）→ EventBus 广播 → sync 自动存档点
```

九类事件仍只有**两个** resolver——与拆分轴「只有 Combat 真有状态机、其余差异在数据而非代码」一致，且保住「新增一个事件 = 新增一个 `.tres`」的可加性。

#### 共享核心类型（`src/Core/`）

```csharp
public sealed class ProfileChangeSpec { public IReadOnlyList<ChangeElement> Elements { get; } }
public readonly record struct ChangeElement(CostKey Key, int BaseValue);   // 负 = 消耗，正 = 产出
public enum CostKey        { LifeSpan, Jade, /* ⟨待定：其余 element 清单⟩ */ }
public enum CycleStatus    { Ongoing, Defeated, Completed }
public enum DefeatReason   { Discarded, LifeSpanExhausted, LifeTotalExhausted }   // 战斗失败本身不终结角色，只扣 lifeTotal
public enum CapabilityFlag { RevealHiddenStats, ShowMysteryType }
public enum HiddenStat     { Faith, MaleficQi, LifeSpan }
public enum RngStream      { Map, Combat, Shop, Reward }
public enum EventType      { Practice, Combat, Research, Exchange, Social, Mystery, Finale, Explore, Travel }
```

**`CostSpec` / `RewardSpec` 合并为单一 `ProfileChangeSpec`**（element 带符号：负 = 消耗，正 = 产出）。理由：「全有或全无、单点提交」本就要求成本与产出在同一事务内；两个类型会诱导出「先 `TryApply(cost)` 再 `TryApply(reward)`」这种半套写入。

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

### 纪律的可执行化（**已定案** · 八条总则的共同上位判据）

> 一条约定该做到哪一级，取决于**违反它的代价**——不取决于它写得多醒目。本判据是把本库已有的三处实践（`internal sealed` manager、`Async` 后缀、两条唯一入口）归纳成的显式阶梯，供日后遇到「这条约定怎么强制」时直接套用，不必逐条重新讨论。Source: `handoffs/2026-08-09e-discipline-enforceability.md`。

| 级 | 手段 | 违反时 | 成本 |
|----|------|--------|------|
| **1 · 写不出来** | 类型 / 可见性 / 命名——错误的写法在语言层不存在或不合法 | 不可能发生 | 设计期一次性 |
| **2 · 编译不过** | `[Obsolete(error: true)]`、`#if` 条件编译、分析器 | 编译期报错 | 低～中 |
| **3 · 大声失败** | 启动期断言、切屏 / 退出期审计（一律 `#if DEBUG`） | 开发期 `PushError` | 低，但只在开发期生效 |
| **4 · 评审清单** | 文档条款 + 人工评审 | 靠人 | 零成本、零保证 |

**两条选级判据：**

- **能上线且线上不可见 → 必须做到第 1 或第 2 级。** 判据是「这条纪律被违反后，测试期能不能被发现」。违反后游戏照常运行、错误只在真实玩家身上显形的，**第 3 级不够**。
- **只在开发期显形、且违反后会累积 → 第 3 级足够**，不必付第 1 / 2 级的成本。

**三处已定案的应用：**

| 纪律 | 判据落点 | 落到第几级 | 形态 |
|------|----------|-----------|------|
| 离线后端不得发到线上 | 上线且不可见 | **1** | `BackendSelector` 唯一选择点 + `OfflineXxxBackend` 整类 `#if DEBUG`（总则 7）；ProjectSettings 开关与启动期断言为第 3 级兜底 |
| 抽取必走 `AllEnabled()` | 上线且不可见 | **1 / 2** | **删除中性名 `All()`**，只留 `AllEnabled()` + `AllIncludingDisabled()`；过渡期 `[Obsolete(error: true)] All()` 占位（第 2 级）。第二阶段前把 `AllEnabled()` 返回类型升为 `DrawPool<T>`、seeded 抽取只定义在其上（第 1 级）。见 `services/content-service.md` |
| EventBus 订阅必退订 | 只在开发期显形 | **3** | `#if DEBUG` 订阅审计，切屏后触发（总则 5） |

**「不插 `if`，也不插 `#if`」——条件编译的使用清单是穷举的，不得扩张：** `src/Core/BackendSelector.cs`、四个 `src/Services/*/Offline*Backend.cs`、`src/Autoload/EventBus.cs` 的审计块，**共 6 处**。服务与 manager 内部一律不得出现 `#if`。

**否决记录：** Roslyn 分析器（单独项目要维护、随 Godot 生成的 `.csproj` 走易被覆盖、无 CI 前提下只在本机构建生效；`[Obsolete(error: true)]` 拿到同一份编译期保证）· 把「上线且不可见」类纪律只做到第 3 级（断言只在跑到那一步时生效，而这类违规的症状恰恰是「一切正常」）。

### adventure-event 子类型层级
- **AdventureEvent = 逐时逐刻的游玩单元。** 展开为按子类型分文件夹的深层结构（`systems/adventure-event/<子类型>/`），每个子类型含 `_index.md` + `common-properties.md`。
- **九类子类型：** Combat（战斗）、Finale（境界突破，篇章边界高潮）、Mystery（未知，遮罩一个固定事件）、Practice（修炼）、Exchange（交易 / 商店）、Research（闭关）、Social（社交）、**Explore（探索秘境，第八类）**、**Travel（前往某处地点，第九类 = 地图路由）**。分类权威见 `terminology.md` 与 `decisions/ADR-0002`。
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
             │      ├─▶ PlotManager (隐藏属性阈值 → 调制; key points ↔ 云端剧本服务)
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

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- **修行事件分类（含 Explore / Travel）** → `decisions/ADR-0002-adventure-event-taxonomy.md`（Accepted；待补订 Explore / Travel）。
- **境界存档 · 篇章重试模型** → `decisions/ADR-0004-realm-checkpoint-retry-model.md`（Accepted）。
- **强制在线 · 云端权威** → `decisions/ADR-0003-online-cloud-authority.md`（Accepted）。
- **`.claude/knowledge` 降为引用层（本库成为内容 + 技术结构双重事实来源）；引用层形态 = 薄引用（副本判据：设计库里已是代码形态的东西只留链接）** → `decisions/ADR-0005-knowledge-thin-reference-layer.md`（Accepted）。
- **展示层三层切分（Data / 运行时·存档 / ViewModel）** → 已定案，**ADR 候选**（待固化）。Source: `handoffs/2026-07-25b-event-cost-fields-capability-flags-and-service-hierarchy.md`。
- **五级层次 service ⊃ manager ⊃ module ⊃ processor ⊃ handler；拆分轴 = 生命周期层 + 行为边界（非数据类型）** → 已定案，**ADR 候选**（待固化）。Source: `handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md` + `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。
- **单一 profile-service 拥有两层 profile（ProfileManager 唯一写入面）；ContentRegistry 唯一内容读取入口；game-progression 为编排顶点** → 已定案，**ADR 候选**（待固化）。Source: 同上。
- **内容载体形态（随包基线 + `user://overlay/` 热更 + 云端版本校验）与本地 / 云端内容分界** → 已定案，**ADR 候选**（待固化）。Source: 同上。
- **PlotManager 隶属 future-event-service，eventOptions 唯一出口** → 已定案，**ADR 候选**（待固化）。
- **API 契约总则（三种方法形态 / 三分失败语义 + `OpResult` / 服务门面骨架 / Bootstrap 启动契约 / EventBus 用 C# 泛型事件 / 后端接口化 / 结算阶段名）** → 已定案，**ADR 候选**（待固化）。Source: `handoffs/2026-07-27b-service-api-contracts.md`。
- **物化模型：`AdventureEventData` 为模板、future-event-service 为唯一物化点、`EventOption` 产出即定稿且落存档** → 已定案，**ADR 候选**（待固化）。Source: 同上。
- **`CostSpec` / `RewardSpec` 合并为单一 `ProfileChangeSpec`（element 带符号）** → 已定案。Source: 同上。
- **纪律的可执行化四级阶梯 + 两条选级判据（离线后端删类 / 删中性名 `All()` / EventBus 订阅审计三处应用）** → 已定案，**ADR 候选**（待固化，与「API 契约总则」并列）。Source: `handoffs/2026-08-09e-discipline-enforceability.md`。

## 闭环缺口（架构体检 · 2026-07-25c 更新）

> `2026-07-25b` 体检列出的 8 处缺口**已全部闭合**（缺口 5 的玩法语义于 07-26 补齐）。Source: `handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md` + `handoffs/2026-07-26-event-priority-skip-semantics-and-hotfix-scope.md`。

| # | 缺口 | 状态 |
|---|------|------|
| 1 | PlayerProfile 侧无服务 | **已闭合** → profile-service（ProfileManager / CapabilityManager / AchievementManager） |
| 2 | 战斗内部无归属 | **已闭合** → combat-service（唯一自带状态机的事件类型；Finale 复用） |
| 3 | 存档 / 云同步无归属 | **已闭合** → sync-service（ProfileSyncManager / LocalCacheManager / MigrationManager） |
| 4 | 本地 / 云端内容分界未定 | **已闭合** → 有稳定 `Id` 且被存档引用 → 本地内容层；按进度动态请求、不被存档引用 → 云端剧本服务 |
| 5 | skip 通道无结算归属 | **已闭合（08-06c：以移除该通道的方式）** → 跳过、`skipCost`、`ifMandatory`、单项补位整体删除；一批只有一次操作（择一进入），选中一个即等价于跳过其余 |
| 6 | `selectCost` / `lifeSpanCost` 重叠 | **已闭合**（07-25b：包含关系）；ProfileManager 是其唯一消费点 |
| 7 | 编排顶点缺失 | **已闭合** → game-progression |
| 8 | UI 与服务间无契约层 | **已闭合**（07-25b：ViewModel 层） |

**API 契约**已于 07-27b 定案（见上方「API 契约总则」）。**剩余的结构性未决项**已下沉为各服务文档的待决问题（cost element 清单、`EventOption` 完整物化字段清单、内容分桶粒度、协议报文字段），见下节与 `services/*`。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **cost element 清单（ProfileManager 的形状取决于它）：** 有哪些 element（jade / mana / 道具 / 隐藏属性推拉？）、各自数据形态（固定值 / 区间 / 公式）、是否允许**部分抵扣**。→ `systems/adventure-event/common-properties.md`、`services/profile-service.md`。
- **热更「只改不增」的连带项：** 范围边界已定（overlay 只改既有条目的数值 / 文案，不得新增 `Id`）、确定性张力已裁决（以 overlay 更新为准，不冻结 `contentVersion`，放弃跨版本 seed 可复现）；残留：是否需「预埋占位 `Id`」策略绕开审核周期、是否在存档中记录 `contentVersion` 以便诊断。→ `services/content-service.md`。Source: `handoffs/2026-07-26-event-priority-skip-semantics-and-hotfix-scope.md`。
- **断线降级的具体行为：** push / pull / 剧本请求失败时阻塞玩家、本地缓冲重试、还是回退存档点？→ `services/sync-service.md`、`services/account-service.md`。
- **ViewModel 层是否需要单独一份文档：** 三层切分已定案并在本文件显式化；是否为 ViewModel 层单列文档（或归 `ux/`）待定。Source: `handoffs/2026-07-25b-event-cost-fields-capability-flags-and-service-hierarchy.md`。


## 对应
提炼至：`.claude/knowledge/architecture.md`（**薄引用层**，ADR-0005：导航 + 代码现状 + 承重一句话，代码形态内容只回链本文件，不留副本）。
