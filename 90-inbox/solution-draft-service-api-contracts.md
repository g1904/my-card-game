---
type: solution-draft
date: 2026-07-26
decided: 2026-07-27
question: 七个服务与其 manager 的职责边界已定，但具体 API 面（方法签名、参数 / 返回类型、事件负载 schema）未定义。
source: open-questions.md → ⚠ 服务 API 契约（07-25c · 结构已定，契约待写 · 优先）
targets:
  - 20-systems/architecture.md（新增「API 契约总则」小节；「服务 API 契约」待决项收口）
  - 20-systems/common-properties.md（服务协作约定 → 追加 API 书写规范、物化模型、跨服务调用纪律的措辞收紧）
  - 20-systems/services/_index.md（待决项收口）
  - 20-systems/services/account-service.md · content-service.md · sync-service.md · profile-service.md · life-cycle-service.md · future-event-service.md · combat-service.md · plot-manager.md（各自「API 面」小节由草图升为契约）
  - 20-systems/adventure-event/common-properties.md（「共有方法面」重写为结算阶段名；新增「物化」条目）
  - system-overview.md（代码形态：Bootstrap 启动契约、manager 可见性、后端接口与离线 stub）
  - terminology.md（新增 OpResult / ProfileChangeSpec / EventOption / 物化 materialize / CardInstance / SavePointReason / RngStream）
status: distilled
distilled-to: 10-handoffs/2026-07-27b-service-api-contracts.md
---

# 方案草稿 — 七服务的 API 契约（已裁决）

> **本文件已由用户于 2026-07-27 全数裁决**：五个取向选择项全部取推荐项 A，两处与既有决策的张力均按建议松动，并补充了一条关于 AdventureEvent **物化（materialize）** 的意图澄清。全文语气已由「提案」改为「定案」，可直接作为 `/analyze-new-ideas` 的原始意图输入。

## 用户裁决与意图澄清（2026-07-27）

### 新增意图澄清 —— AdventureEvent 的属性由 future-event-service **物化**，产出即定稿

> 用户原话：*"many AdventureEvent properties are decided via future-event-service (after process on existing static resources or assets) (in order to add more variations and favors based on different scenarios). Once the AdventureEvent details are outputed from future-event-service, their data are finalized."*

这条澄清把原草稿里「`ifMandatory` / `eventPriority` 是动态置位的」从一个**局部例外**升级为**贯穿全局的产出模型**，并直接改写了总则 6（见下）。要点有三：

1. **`AdventureEventData : Resource` 是模板 / 素材，不是成品。** 它承载静态定义与可变体的参数空间；**多数**具体属性（不止那两个 flag）由 future-event-service 依情境加工得出——目的正是「按不同情境制造更多变化与风味」。
2. **future-event-service 是唯一的物化点。** 物化输入 = 模板（经 ContentRegistry）+ CharacterProfile + location + 隐藏属性 / 剧本进度（PlotManager 调制）+ SeedManager 的 map 子流。这与既定的「eventOptions 唯一出口」完全同构——**产出 eventOptions ≡ 物化 AdventureEvent**。
3. **产出即定稿（finalized · immutable）。** 一旦 `EventOption` 从 future-event-service 输出，其数据即冻结：life-cycle-service、combat-service、UI 一律只读消费，**不得回查模板重算、不得改写其字段**。

### 五个取向选择项 —— 全数取推荐项 A

| # | 议题 | 裁决 |
|---|------|------|
| 1 | EventBus 的负载机制 | **A —— C# 泛型 `event` + `readonly record struct` 负载**（不用 Godot `[Signal]`） |
| 2 | 跨进程边界方法的异步形态 | **A —— `Task<OpResult<T>>` + `CancellationToken`** |
| 3 | `eventStart` / `eventEnd` 的宿主 | **A —— 结算流程的阶段名 + 两个 `IEventResolver` 实现**（不是 `Resource` 上的方法） |
| 4 | capability flag 的载体 | **A —— C# `enum CapabilityFlag`**（不是字符串 key） |
| 5 | `CostSpec` / `RewardSpec` 是两个类型还是一个 | **A —— 合并为单一 `ProfileChangeSpec`**（element 带符号） |

### 两处张力 —— 均按建议松动

- **张力 1 已裁决：** `eventStart` / `eventEnd` 理解为**结算流程的两个阶段名**，而非 `Resource` 上的方法。→ `adventure-event/common-properties.md` 的「共有方法面」需按此重写。
- **张力 2 已裁决：** 「服务之间不互相读写字段」的措辞收紧为——**服务之间不读写对方字段、不伸手进对方 manager；跨服务的方法调用允许。** → `architecture.md`、`20-systems/common-properties.md`、`services/_index.md` 中的对应措辞需一并更新。

---

## 问题

`10-handoffs/2026-07-25c` 定案了两级层次 `service ⊃ manager`、三条服务判据、两条唯一入口与一个编排顶点，**边界因此已经清楚**。但每份服务文档的「API 面」小节至今都自标为「意图草图 · 签名待定」——只有方法名与一句话意图，没有：

- **参数与返回类型**（`AdvanceEvent(character, chosenAdventureEvent, mode)` 里三个参数分别是什么类型？返回什么？）
- **失败语义**（`TryApply` 返回 `ApplyResult` 已示范，但 `SignIn` / `PullProfile` / `CheckAndUpdate` 失败时返回什么？抛还是回 Result？）
- **同步 / 异步形态**（跨网络的 `PullProfile`、跨多帧的 `RunCombat` 在 C# 里长什么样？）
- **事件负载 schema**（EventBus 广播的 `CapabilitiesChanged` / `CycleStarted` / `EventResolved` 携带什么、用什么类型承载？）

**它卡住了什么：** `/derive-requirements` 无法从「意图草图」产出带验收标准的 FR；`/blueprint` 无接口可对；`game-feature-branch/` 至今只有 `project.godot` 与一个 icon，第一行服务代码没法开写——因为一旦按各自理解写下去，七个服务的失败语义与异步形态就会各不相同，事后统一的代价远高于现在定。

本文件的目标**不是把七个服务的全部方法写完**（很多方法的形状取决于仍待答的内容问题，见 `## 前置依赖`），而是定下**贯穿七个服务的契约总则 + 每个服务的首版签名骨架**，使各服务文档的「API 面」小节可以从「草图」升级为「契约」。

## 约束（来自既有设计）

| # | 硬约束 | 来源 |
|---|--------|------|
| C1 | service = **进程内模块单例**（autoload `Node`），彼此直接 C# 方法调用；manager 是服务持有的**普通 C# 对象**（非 `Node`） | `system-overview.md` 一 / 三；`20-systems/common-properties.md` |
| C2 | **服务之间不读写对方字段、不伸手进对方 manager**；跨服务的方法调用允许（经服务门面），编排归**编排顶点 game-progression**，既成事实经 **EventBus** 广播 | `architecture.md`；`system-overview.md` 四；**措辞按张力 2 裁决收紧** |
| C3 | **两条唯一入口**：内容读取 = `content-service.ContentRegistry`；档案写入 = `profile-service.ProfileManager.TryApply(spec)`（全量校验 → 全有或全无 → 单点提交，modifier pipeline 在此生效） | `architecture.md`；`services/_index.md` |
| C4 | **null / 结果校验强制**：必需但缺失 → `GD.PushError` + 定位上下文并退出；可选但缺失 → `GD.PushWarning` + 安全默认值。绝不把未检查的 null 向下游传 | `.claude/rules/null-check-rules.md` |
| C5 | **贯穿整条链路的类型一致性**：UI → 服务 → 数据资源 → 存档模型，**层与层之间不做隐式装箱 / 转换** | `.claude/rules/Context.md`；`20-systems/common-properties.md` |
| C6 | **数据即资源**：`XxxData : Resource` 只承载 `Id` + 数值 + 静态展示文案；**新增内容 = 新增 `.tres`，不编辑 switch** | `.claude/rules/data-resource-rules.md` |
| C7 | **展示层三层切分**：Data（静态文案）/ 运行时·存档态（只带 `Id` + 可变状态）/ ViewModel（呈现期组装，不落存档、不进云端负载）。**服务不返回 ViewModel** | `architecture.md`；`20-systems/common-properties.md` |
| C8 | 唯一真实进程边界 = 客户端 ↔ 后端；**只有 4 处跨越它**：account-service、content-service、sync-service、future-event-service 内的 PlotManager。其余三个纯本地 | `system-overview.md` 一 |
| C9 | 边界服务**可被替换为离线 stub**，使后端未开工时整个游戏能端到端跑起来 | `system-overview.md` 五；`.claude/rules/Context.md` |
| C10 | 避免 `async void`；`_Process` 热路径不分配、不用 LINQ；有意识断开信号 | `.claude/rules/csharp-godot-rules.md` |
| C11 | **AdventureEvent 的多数属性（含 `ifMandatory` / `eventPriority`）由 future-event-service 依情境物化产出，产出即定稿** | 用户裁决 2026-07-27；`adventure-event/common-properties.md`；`future-event-service.md` |
| C12 | 确定性边界 = 同一 `contentVersion` 内；一切玩法随机性经 SeedManager 的**具名子流** | `20-systems/common-properties.md` |

---

## 决策

### 总则 1 —— 三种方法形态，按「它跨什么边界」决定

`[既有推演]` C1 + C8 + C10。七个服务里方法只有三类边界，各配一种固定形态，**不允许混用**：

| 形态 | 适用 | 签名形状 | 理由 |
|------|------|----------|------|
| **A · 同步直返** | 纯内存查询与纯本地事务（ContentRegistry 查内容、ProfileManager 施加变更、CapabilityManager 查询、SeedManager 派生、future-event 物化） | `T Get(...)` / `ApplyResult TryApply(...)` / `bool Has(...)` | 无 I/O、单帧内完成；引入 `Task` 只会给每次查询加一次状态机分配（违 C10） |
| **B · `Task<OpResult<T>>`** | 跨 C8 那条进程边界的一切（account / content update / sync push-pull / PlotManager 请求剧本） | `Task<OpResult<PlayerProfile>> PullProfileAsync(string accountId, CancellationToken ct)` | 网络失败是**常态而非异常**；`Task` 让「离线 stub 直接 `Task.FromResult`」变成一行（C9），也让超时 / 取消 / 重试有统一挂点 |
| **C · `Task<T>` 由信号推进** | 跨多帧的玩法长流程（`RunCombatAsync`、`AdvanceEventAsync`） | `Task<CombatResult> RunCombatAsync(...)`，内部 `await ToSignal(...)` 等玩家输入 | 调用方要的是「战斗打完给我结果」这一件事；把回合内的帧级推进封在服务内部，不外泄成状态机 |

**命名：** 形态 B / C 的方法一律带 `Async` 后缀并返回 `Task`；形态 A 一律不带。看签名即知它是否跨边界。

### 总则 2 —— 失败语义三分，与 null-check 规则一一对应

`[既有推演]` C4。既有的 `ContentRegistry.Get`（缺失 → PushError + 抛）/ `TryGet`（缺失 → 调用方降级）/ `ProfileManager.TryApply`（返回 `ApplyResult`）已经示范了三种，固化为全局规则：

| 失败性质 | 形状 | 例 |
|----------|------|-----|
| **必需缺失 = 程序缺陷 / 坏数据** | `GD.PushError($"[Svc-Method] ..., id={id}")` + `throw` | `ContentRegistry.Get(id)`、启动期校验 |
| **可选缺失 = 调用方可降级** | `bool TryXxx(..., out T value)`，返回 `false` 前 `GD.PushWarning` | `ContentRegistry.TryGet`、`TryRefill` |
| **业务失败 = 预期内的拒绝** | 返回 `OpResult` / `OpResult<T>` / `ApplyResult`，**绝不抛** | 付不起成本、网络不通、token 失效、重试次数耗尽 |

**统一结果类型**（`src/Core/`）：

```csharp
public enum OpError { None, Network, Auth, Compliance, Validation, NotFound, Conflict, Cancelled, Migration }

public readonly record struct OpResult(bool Success, OpError Error, string Detail)
{
    public static OpResult Ok()                           => new(true,  OpError.None, string.Empty);
    public static OpResult Fail(OpError e, string detail) => new(false, e, detail);
}

public readonly record struct OpResult<T>(bool Success, T Value, OpError Error, string Detail);
```

`readonly record struct` 而非 class：结果对象在核心循环里每步都产生，**零堆分配**（C10），且天然带值相等与解构。

**`ApplyResult` 保留为独立类型**（它多带一个「哪个 element 不足」，UI 要用它做灰显与提示）：

```csharp
public readonly record struct ApplyResult(bool Success, CostKey MissingElement)
{
    public static ApplyResult Ok()                  => new(true, default);
    public static ApplyResult Fail(CostKey missing) => new(false, missing);
}
```

### 总则 3 —— 服务门面的固定骨架

`[既有推演]` C1 + C2，把 `system-overview.md` 四已示范的形态固化为**每个服务都长一样**的骨架：

```csharp
public partial class ProfileService : Node
{
    public static ProfileService Instance { get; private set; }

    private ProfileManager    _profile;      // manager 一律 private 字段
    private CapabilityManager _capability;

    public override void _Ready()
    {
        Instance    = this;
        _profile    = new ProfileManager(this);
        _capability = new CapabilityManager(this);
        GD.Print("[ProfileService-Ready] managers initialized");
    }

    // ── 对外 API 面：只暴露方法，绝不暴露 manager 引用 ──
    public ApplyResult TryApply(ProfileChangeSpec spec) => _profile.TryApply(spec);
}
```

三条配套约定：

1. **manager 类型声明为 `internal sealed`**（`system-overview.md` 五已提出的加固）——同程序集内可测，跨服务代码里根本写不出对方 manager 的类型名。
2. **服务间只经 `Xxx.Instance.Method(...)` 调用**（C2 裁决后的措辞：调用允许，读写字段与伸手进 manager 不允许）；`Instance` 为 null 即启动顺序配错，属 C4 的「必需缺失」→ `PushError` + 抛，不做静默降级。
3. **服务不返回内部可变集合**：一律 `IReadOnlyList<T>` / `IReadOnlyDictionary<,>`。

### 总则 4 —— 启动契约：`_Ready` 只装配，`InitializeAsync` 才做 I/O

`[既有推演]` C1 + 形态 B。Godot autoload 的 `_Ready` 不能 `await`，而 content-service 启动就要比对云端版本、sync-service 要 pull——**这些 I/O 放不进 `_Ready`**。既有的「autoload 声明顺序 = 启动依赖顺序」只解决了**装配**顺序，没解决**初始化**顺序。

引入一个 **Bootstrap 屏幕场景**（`scenes/screens/BootstrapScreen.tscn`，非服务、非 autoload），作为 `main` 场景按固定顺序驱动异步初始化，并把进度喂给启动画面：

```csharp
public interface IBootstrappable          // 由四个边界服务实现
{
    Task<OpResult> InitializeAsync(CancellationToken ct);
}
```

顺序：`ContentService.InitializeAsync`（版本比对 + overlay 合并 + 校验，断网降级到基线）→ 进 `LoginScreen` → `AccountService.SignInAsync` → `SyncService.InitializeAsync`（pull + 迁移）→ `ProfileService.Hydrate` → 进 `MainMenu`。三个纯本地服务（profile / life-cycle / combat）**不实现该接口**——它们在 `_Ready` 里装配完就绪。

这同时给了「首启不依赖网络下载内容，但进入游戏仍需登录」（`content-service.md`）一个明确的落点。

### 总则 5 —— EventBus：C# 泛型事件 + `readonly record struct` 负载

`[既有推演]` C5 + C10 · **裁决 1 = A**。

Godot `[Signal]` 传自定义负载要求负载继承 `GodotObject`，于是**每次广播都分配一个引用对象并经 `Variant` 装箱**——直接撞上 C5「层与层之间不做隐式装箱 / 转换」与 C10「热路径不分配」。核心循环每步要广播 `EventResolved`、战斗内每张牌要广播 `CardResolved`，这条路径不该分配。

EventBus 仍是 autoload `Node`（保持它在场景树里、可在 `_ExitTree` 做泄漏检查），但对外暴露的是**强类型 C# 事件**而非 `[Signal]`：

```csharp
public partial class EventBus : Node
{
    public static EventBus Instance { get; private set; }
    public override void _Ready() { Instance = this; }

    public event Action<CycleStarted>        CycleStarted;
    public event Action<EventResolved>       EventResolved;
    public event Action<CapabilitiesChanged> CapabilitiesChanged;
    // ...

    public void Emit(in CycleStarted e)
    {
        GD.Print($"[EventBus-Emit] CycleStarted character={e.CharacterId} chapter={e.Chapter}");
        CycleStarted?.Invoke(e);
    }
}
```

配套纪律：**订阅方在 `_Ready` 订阅、在 `_ExitTree` 退订**（C10「有意识地断开信号」的等价物）。代价：GDScript 与编辑器信号面板订阅不了——本项目纯 C#（`project.godot` 已启用 .NET），不构成损失。

### 总则 6 —— 物化模型：模板 `Data` → future-event-service 物化 → 定稿实例

`[用户意图 · 2026-07-27]` + `[既有推演]` C6 + C7 + C11。**这是本文件里影响面最大的一条**，它同时改写 `adventure-event/common-properties.md` 与 `future-event-service.md` 的意图层表述。

#### 三阶段

```
res:// + user://overlay/          ContentRegistry              future-event-service            life-cycle / combat / UI
  AdventureEventData(.tres)  ──▶  按 Id 索引的只读模板  ──▶  物化(materialize)          ──▶   只读消费
  = 静态素材 / 参数空间             共享单例、可热更           情境代入 → 定稿实例              不回查模板、不改字段
                                                             （EventOption，immutable）
```

- **模板侧（`AdventureEventData : Resource`）** 承载：稳定 `Id`、`eventType`、静态展示文案、基准数值与**可变体的参数空间**、数据驱动的 outcome / effect 定义。它是 ContentRegistry 里的**共享只读单例**，且可被 overlay 热更覆写——**任何服务都不得在运行时写它**（写回会污染注册表、被同一轮回的后续批次与其他角色看到）。
- **物化侧（future-event-service）** 是**唯一物化点**。输入 = 模板 + CharacterProfile（含隐藏属性、修行历程）+ location 框定 + PlotManager 调制 + SeedManager 的 map 子流；输出 = 一批 `EventOption`。原先「`ifMandatory` / `eventPriority` 动态置位」只是这条规则的一个特例——**按情境制造变化与风味**才是物化的目的。
- **消费侧定稿（finalized）。** `EventOption` 一经输出即冻结：`life-cycle-service` / `combat-service` / ViewModel 一律只读，**不得回查模板重算、不得改写其字段**。这条纪律是「同一个事件在呈现、结算、记入历程三处看到的是同一份数据」的保证。

#### 类型形态

```csharp
public sealed record EventOption(                 // 定稿实例：immutable 引用类型，落存档
    string             InstanceId,                // 本次物化实例的稳定标识；pastEvent / 存档引用它
    string             EventId,                   // 溯源到模板：ContentRegistry.Get<AdventureEventData>(EventId)
    EventType          EventType,                 // Mystery 时 = 遮罩类型；真身见 RevealedEventType
    int                Priority,                  // 物化时置位（取值域见前置依赖）
    bool               IsMandatory,               // 物化时置位
    ProfileChangeSpec  SelectCost,                // 物化时组装（modifier pipeline 尚未施加）
    ProfileChangeSpec  SkipCost,
    bool               IsRevealed,                // Mystery：是否已揭示
    string             RevealedEventId            // Mystery 遮罩的固定事件（物化时即已确定）
    /* ⟨待定：其余物化字段清单，见前置依赖⟩ */);
```

**为何是 `sealed record`（引用类型）而非 `readonly record struct`：** 字段多、要落存档、一批只有个位数个、不在每帧热路径——按值拷贝的代价高于一次分配。`record` 的 `with` 表达式同时给出了「定稿后若确需派生（如 Mystery 揭示）就产生一个新实例而非改旧的」这一惯用法。

#### 三条推论

1. **定稿实例必须落存档，而不能只存 `EventId` 事后重算。** 物化用了 seeded RNG、当时的角色状态、以及**可被 overlay 热更的模板**；既定的确定性边界只在同一 `contentVersion` 内（C12），重算不保证同结果。因此**当前批 eventOptions 与 `pastEvent` 痕迹都要存物化后的快照**。（这修正了原草稿「不影响存档 schema」的说法——见 `## 后果`。）
2. **`InstanceId` 与 `EventId` 并存且不可互相替代。** 同一模板可在一次轮回里被物化多次（不同情境 → 不同实例）；`pastEvent`、`EventResolved` 负载、`TryRefill` 的「被跳过的那一个」都必须按 `InstanceId` 定位。
3. **通则（推广到其他内容类型）：** 凡「内容定义 + 情境 / 轮回内状态」的组合都是两个类型：
   - `AdventureEventData` ↔ **`EventOption`** —— 物化后**定稿不可变**；
   - `CardData` ↔ **`CardInstance`** —— 运行态**可变**（手牌中的临时增益），`combat-service.md` 的 `PlayCard(cardInstance, target)` 已在用这个词。

   两者共享同一条纪律：**服务签名里传实例，不传 `Resource`**；差别只在实例本身是否可变。这与 C7 三层切分同构，把第二层的类型形态明确了。

### 总则 7 —— 后端接口化：四个边界服务各持一个可替换后端

`[既有推演]` C8 + C9。把跨进程边界的调用收敛到四个窄接口，让离线 stub 是「换一个实现」而不是「在服务里插 `if (offline)`」：

```csharp
internal interface IAccountBackend  { Task<OpResult<Session>>          SignInAsync(LoginChannel c, CancellationToken ct); /* ... */ }
internal interface IContentBackend  { Task<OpResult<ContentManifest>>  GetManifestAsync(CancellationToken ct); /* ... */ }
internal interface IProfileBackend  { Task<OpResult<PlayerProfile>>    PullAsync(string accountId, CancellationToken ct);
                                      Task<OpResult>                   PushAsync(ProfilePayload p, CancellationToken ct); }
internal interface IPlotBackend     { Task<OpResult<PlotSegment>>      ResolveAsync(PlotRequest req, CancellationToken ct); }
```

每个接口两份实现：`HttpXxxBackend`（后端就绪后）与 `OfflineXxxBackend`（当前阶段，读 `res://` 假数据 / 内存回显）。选择哪份由服务上的 `[Export] bool UseOfflineBackend`（默认 `true`，直到后端上线）决定——**开发期切换不需要重编译**。

> 这四个接口是客户端 ↔ 后端**协议契约的客户端一侧投影**；其权威在 `backend-design-documents/`。本文件只定客户端的**调用形状**（方法名、参数、`OpResult` 语义），不定 HTTP 路径 / 报文字段——那属后端库。

### 总则 8 —— 结算阶段名取代「事件自带钩子」

**裁决 3 = A**（原张力 1）。`eventStart` / `eventEnd` 是 **`AdvanceEventAsync` 内部结算流程的两个阶段名**，不是 `AdventureEventData` 上的方法。落地为一个数据驱动的结算器：

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
校验 mode 合法性（IsMandatory + Skip → 拒绝；Priority < EffectivePriority → 拒绝）
  → TryApply(SelectCost | SkipCost)                       ← 付不起则回 AdvanceResult 拒绝，不产生任何写入
  → 【eventStart 阶段】选 resolver、Mystery 揭示
  → resolver.ResolveAsync(option, ct)                     ← Combat/Finale 转 combat-service，其余走通用结算器
  → 【eventEnd 阶段】合并 ResolveOutcome + lifeSpanCost + 隐藏属性推拉为**一次** TryApply
  → 记入 pastEvent（按 InstanceId，携带定稿实例快照）
  → RunStateManager 终态判定 → EventBus 广播 → sync 自动存档点
```

九类事件仍只有**两个** resolver——与既定拆分轴「只有 Combat 真有状态机、其余差异在数据而非代码」完全一致，且保住了「新增一个事件 = 新增一个 `.tres`」的可加性（C6）。

---

## 具体形态（可 derive 的落地面）

> 以下为**首版签名骨架**。凡形状取决于仍待答内容问题的，用 `⟨待定⟩` 标出并列入 `## 前置依赖`——**不臆造**。

### 共享核心类型（`src/Core/`）

```csharp
// 裁决 5 = A：单一 ProfileChangeSpec，element 带符号（负 = 消耗，正 = 产出）
public sealed class ProfileChangeSpec
{
    public IReadOnlyList<ChangeElement> Elements { get; }
}
public readonly record struct ChangeElement(CostKey Key, int BaseValue);
public enum CostKey { LifeSpan, Jade, /* ⟨待定：其余 element 清单⟩ */ }

public enum AdvanceMode    { Select, Skip }
public enum CycleStatus    { Ongoing, Defeated, Completed }
public enum DefeatReason   { Discarded, LifeSpanExhausted, CombatLost }
public enum CapabilityFlag { RevealHiddenStats, ShowMysteryType, ShowSkipCost /* 可加 */ }   // 裁决 4 = A
public enum HiddenStat     { Faith, MaleficQi, LifeSpan }
public enum RngStream      { Map, Combat, Shop, Reward }
public enum EventType      { Practice, Combat, Research, Exchange, Social, Mystery, Finale, Explore, Travel }
```

### account-service

| 方法 | 形态 | 签名 |
|------|------|------|
| 登录 | B | `Task<OpResult<Session>> SignInAsync(LoginChannel channel, CancellationToken ct)` |
| 登出 | B | `Task<OpResult> SignOutAsync(CancellationToken ct)` |
| 刷新 | B | `Task<OpResult<Session>> RefreshTokenAsync(CancellationToken ct)` |
| 取会话 | A | `bool TryGetSession(out Session session)` — 未登录是**可选缺失**（登录屏正常态），不是错误 |

```csharp
public readonly record struct Session(string AccountId, string Token, DateTime ExpiresAtUtc);
public enum LoginChannel { Phone, Email, WeChat, QQ }   // 优先级序见 ADR-0003；无 Guest
```

失败映射：网络不通 → `OpError.Network`；渠道拒绝 / token 失效 → `OpError.Auth`；实名 / 防沉迷拦截 → `OpError.Compliance`（`Detail` 携带面向玩家的原因串，由 UI 层决定文案）。

### content-service

| 方法 | 形态 | 签名 |
|------|------|------|
| 版本比对 + 下载 | B | `Task<OpResult<ContentUpdateInfo>> CheckAndUpdateAsync(CancellationToken ct)` |
| 合并加载 + 校验 | A | `void LoadAll()` — 校验失败 = 坏数据 → `PushError` + 抛（启动期早失败） |
| 取仓储 | A | `IContentRepository<T> Repo<T>() where T : Resource` |
| 当前版本 | A | `int ContentVersion { get; }` |

```csharp
public readonly record struct ContentUpdateInfo(int FromVersion, int ToVersion, int FilesApplied, bool FellBackToBaseline);

public interface IContentRepository<T> where T : Resource
{
    T                Get(string id);               // 必需：缺失 → PushError + throw
    bool             TryGet(string id, out T v);   // 可选：缺失 → 调用方降级
    IReadOnlyList<T> All();
    IReadOnlyList<T> AllEnabled();                 // 抽取池：ContentEnabled == true；产出侧唯一取池入口
    IEnumerable<T>   Where(Func<T, bool> predicate);
}
```

- `Repo<T>()` 而非七个具名属性：新增内容类型 = 注册一个仓储，**调用方与服务签名都不动**（C6 可加性）。
- **`AllEnabled()` 是物化取池的唯一入口**（`data-resource-rules.md` 明文纪律）：future-event-service 物化时必须从 `AllEnabled()` 取候选，而 `Get(id)` 不过滤——使存档中引用到已关闭条目的实例仍能正确解析。

### sync-service

| 方法 | 形态 | 签名 |
|------|------|------|
| 拉取 | B | `Task<OpResult<PlayerProfile>> PullProfileAsync(string accountId, CancellationToken ct)` |
| 上行 | B | `Task<OpResult> PushAsync(SavePointReason reason, CancellationToken ct)` |
| 补提交 | B | `Task<OpResult> FlushPendingAsync(CancellationToken ct)` |
| 同步态 | A | `SyncState State { get; }` |

```csharp
public enum SavePointReason { CycleStarted, EventResolved, ChapterBoundary, CycleEnded, MetaChanged }
public enum SyncState       { Idle, Syncing, Buffered, Offline, Failed }
```

三点推演：
- **`PushAsync` 不接收 profile 参数。** profile 的内存权威在 profile-service，sync-service 只负责持久化与传输（`sync-service.md` 明文）；让调用方递一份 profile 进来等于把「谁是权威」这件事再打开一次。sync-service 内部经 `ProfileService.Instance.Snapshot` 取快照。
- **`reason` 保留**（既有草图已有），它同时驱动日志、重试策略与合并窗口——是「自动存档点是否过频」这条待答项的调节旋钮所在。
- 迁移失败 → `OpError.Migration`，`Detail` 带 `fromVersion → toVersion`；UX 表现待定（前置依赖）。

### profile-service

| 方法 | 形态 | 签名 |
|------|------|------|
| 载入 | A | `void Hydrate(PlayerProfile profile)` — 触发首次 capability 聚合 |
| 施加变更 | A | `ApplyResult TryApply(ProfileChangeSpec spec)` |
| 预校验 | A | `bool CanAfford(ProfileChangeSpec spec)` — 供 UI 灰显 / 预览，**不提交** |
| 能力查询 | A | `bool Has(CapabilityFlag flag)` |
| 数值修正 | A | `int ApplyModifier(ModifierKey key, int baseValue)` |
| 开关 | A | `ApplyResult SetPowerStatus(string powerId, bool enabled)` |
| 授予 / 撤销 | A | `ApplyResult GrantPower(string powerId)` / `RevokePower(string powerId)` |
| 消耗账号道具 | A | `ApplyResult ConsumePlayerItem(string itemId, int count = 1)` |
| 成就采集 | A | `void ReportProgress(AchievementSignal signal)` |
| 只读快照 | A | `PlayerProfile Snapshot { get; }`（只读视图，供 sync / ViewModel 组装） |

- `CanAfford` 与 `TryApply` **必须走同一条 modifier pipeline**，否则 UI 显示「买得起」而实际拒绝。二者共用一个内部 `Evaluate(spec)`，`TryApply` = `Evaluate` + 提交。
- `Snapshot` 返回**只读视图**而非可变引用（总则 3）。运行态写入一律经 `TryApply`。

### life-cycle-service

| 方法 | 形态 | 签名 |
|------|------|------|
| 开始轮回 | A | `OpResult<CharacterProfile> StartCycle(CycleStartSpec spec)` |
| 推进 | C | `Task<AdvanceResult> AdvanceEventAsync(EventOption chosen, AdvanceMode mode, CancellationToken ct)` |
| 篇章通关 | A | `OpResult CompleteChapter()` |
| 角色终结 | A | `OpResult DefeatCharacter(DefeatReason reason)` |
| 重试 | A | `OpResult<CharacterProfile> RetryChapter(string characterId)` |
| 清理 | A | `void TeardownCycle()` |
| 当前角色 | A | `bool TryGetActiveCharacter(out CharacterProfile c)` |
| RNG 子流 | A | `RandomNumberGenerator Stream(RngStream stream)` |

```csharp
public readonly record struct CycleStartSpec(ulong Seed, int Chapter, string SourceCharacterId /* 空 = 炼气新角色 */);

public readonly record struct AdvanceResult(
    bool         Success,
    AdvanceStage FailedAt,      // None | ModeRejected | CostRejected | InnerFlow | OutcomeRejected
    CostKey      MissingElement,
    CycleStatus  StatusAfter);
```

四点推演：
- **`AdvanceEventAsync` 收 `EventOption`（定稿实例）而非 `AdventureEventData`**（总则 6）——它需要物化时置位的 `Priority` / `IsMandatory` / `SelectCost` / `SkipCost` 来校验「这一步合法吗」并施加成本。传 `Resource` 就拿不到这些字段，且会诱使调用方回查模板重算，违 C11 的「产出即定稿」。
- **不收 `character` 参数。** 每篇章至多一个 `ongoing`（ADR-0004），当前角色是服务自己的状态机持有物；把它当参数传等于允许调用方指定「对哪个角色推进」，是一处不必要的越权面。（`StartCycle` / `RetryChapter` 例外，它们要选角色。）
- **返回 `AdvanceResult` 而非 `void`。** 「付不起 → 拒绝，回到呈现步」是 `program-overview.md` 阶段 4 ④ 的明文流程，编排顶点需要一个可判定的返回值，且 `MissingElement` 直接喂给 UI 提示。
- **`Stream(RngStream)` 暴露 `RandomNumberGenerator` 而非 `int Next()`。** Godot 的 `RandomNumberGenerator` 自带可序列化的 `Seed` / `State`，正好是「持久化 RNG 状态」这条待答项的载体；且各子流独立实例天然满足「互不干扰」。

### future-event-service

| 方法 | 形态 | 签名 |
|------|------|------|
| 物化一批 | A | `EventOptionBatch ComputeEventOptions(CharacterProfile character)` |
| 结算后重算 | A | `EventOptionBatch RefreshAfterEvent(CharacterProfile character, string resolvedInstanceId)` |
| 跳过补位 | A | `bool TryRefill(ref EventOptionBatch batch, string skippedInstanceId, out EventOption replacement)` |
| 当前批 | A | `EventOptionBatch Current { get; }` |
| 剧本分支 | B | `Task<OpResult> ChooseBranchAsync(string branchId, CancellationToken ct)` — PlotManager 的**唯一对外投影** |

```csharp
public sealed record EventOptionBatch(
    string                     BatchId,
    IReadOnlyList<EventOption> Options,
    int                        EffectivePriority,   // 本批最高优先级档；有效可选集 = Priority == EffectivePriority 的全部
    bool                       AnySkippable);       // = 任一 Option 的 IsMandatory == false
```

- **本服务是唯一物化点**（总则 6）。`ComputeEventOptions` 的语义就是「物化」：取 `AllEnabled()` 候选 → location 框定 → PlotManager 调制 → map 子流抽取 → 组装定稿实例。**物化完成后本服务不再改这批实例**，`TryRefill` 是**新增一个实例**（顶替被跳过的那一个），不是改旧的。
- **`TryRefill` 用 `bool` + `out`**（「可选缺失」形态），因为「补位可能落空」是**已定案的正常语义**（`future-event-service.md`），不是错误——`false` 前 `PushWarning` 留痕即可。
- **`EffectivePriority` 由服务算好放进 batch**，而不是让 UI 自己去 `Max(o.Priority)`。呈现层只做呈现（C7），「哪些可选」是产出侧的语义。
- **PlotManager 的四个方法（`ResolvePlot` / `ModulateEventOptions` / `OnHiddenStatThreshold` / `ChooseBranch`）不出现在服务门面上**（C2：manager 不被跨服务调用）。前三个是 `ComputeEventOptions` 物化链条内部的一环；只有 `ChooseBranch` 需要玩家输入，故投影为服务门面上的 `ChooseBranchAsync`。

### combat-service

| 方法 | 形态 | 签名 |
|------|------|------|
| 打一场 | C | `Task<CombatResult> RunCombatAsync(EncounterSpec encounter, CancellationToken ct)` |
| 出牌 | A | `PlayResult PlayCard(CardInstance card, TargetRef target)` |
| 结束回合 | A | `void EndTurn()` |
| 战斗态 | A | `CombatSnapshot Snapshot { get; }`（供 ViewModel 组装） |

```csharp
public readonly record struct EncounterSpec(string EncounterId, bool IsFinale);
public readonly record struct CombatResult(
    CombatOutcome     Outcome,        // Victory | Defeat | Fled
    int               RemainingHealth,
    ProfileChangeSpec Spoils);        // 战利品以 spec 形式回吐，由 life-cycle 经 ProfileManager 施加
```

**`CombatResult.Spoils` 是 `ProfileChangeSpec` 而非「已写好的变更」**——这一条同时回答了 `combat-service.md` 的待决项「谁持有 `CombatResult` 并把它翻译成 Profile 变更」：combat-service 只**描述**结果，life-cycle-service 在 `eventEnd` 阶段把它连同 `lifeSpanCost` 与隐藏属性推拉**合并为一次 `TryApply`**，从而「一个事件 = 一次事务 = 一个存档点」。（战斗**过程中**的血 / mana 变更仍即时经 ProfileManager，见 `combat-service.md`；`Spoils` 只承载收口产出。）

### 事件负载 schema（EventBus）

| 事件 | 负载 | 广播者 |
|------|------|--------|
| `CycleStarted` | `(string CharacterId, int Chapter, ulong Seed)` | life-cycle |
| `EventResolved` | `(string CharacterId, string InstanceId, string EventId, AdvanceMode Mode, int LifeSpanRemaining)` | life-cycle |
| `ChapterCompleted` | `(string CharacterId, int Chapter, Realm ReachedRealm)` | life-cycle |
| `CharacterDefeated` | `(string CharacterId, DefeatReason Reason, int RetriesLeft)` | life-cycle |
| `EventOptionsChanged` | `(string BatchId, int Revision)` | future-event |
| `PlotThresholdReached` | `(string CharacterId, HiddenStat Stat, int Threshold)` | future-event（代 PlotManager） |
| `CapabilitiesChanged` | **空负载** | profile |
| `AchievementTierReached` | `(string GroupId, int TierPercent)` | profile |
| `CombatTurnStarted` / `CombatTurnEnded` | `(int TurnIndex)` | combat |
| `CardResolved` | `(string CardInstanceId, string CardId)` | combat |
| `CombatFinished` | `(CombatOutcome Outcome, int RemainingHealth)` | combat |
| `SyncStateChanged` | `(SyncState State, OpError LastError)` | sync |
| `ContentUpdateFinished` | `(ContentUpdateInfo Info, bool Success)` | content |
| `SessionChanged` | `(bool SignedIn, OpError Reason)` | account |

三条负载纪律：

1. **负载只带 `Id` + 值类型，绝不带 `CharacterProfile` / `Resource` / `EventOption` 引用。** 传引用等于给每个订阅者开一条绕过唯一写入入口的旁路（C3），也让定稿实例有被下游改写的可能（C11）。需要完整实例的订阅者按 `InstanceId` 向 future-event-service 取。
2. **`CapabilitiesChanged` 空负载。** 订阅者收到后自行 `ProfileService.Instance.Has(flag)` 重查——这正是既定的「一个 flag ↔ 一处消费点 · 单点查询」（`player-power/common-properties.md`）；把生效集塞进负载反而制造第二份真值。
3. **广播 = 既成事实，不可否决。** EventBus 不承载「请求 / 询问」；需要返回值的一律是直接方法调用。

### API 书写规范（供各服务文档的「API 面」小节统一格式）

每个方法一行，四列：**方法 | 形态(A/B/C) | 完整签名 | 失败语义**。凡形状依赖未答问题的，写 `⟨待定：链接到待决项⟩`，不留空白也不臆造。

---

## 后果

- **可 derive。** 七份服务文档的「API 面」从「意图草图 · 签名待定」升为契约后，`/derive-requirements` 能对每个方法产出带验收标准的 FR（输入 / 输出 / 失败分支各是一条可验收的行为）。
- **代码可开写。** `src/Core/` 的共享类型（`OpResult`、`ApplyResult`、`ProfileChangeSpec`、`EventOption`、各枚举）与七个服务门面骨架 + 四个后端接口的 offline stub，是第一个可落地的实现批次，且不依赖任何未答的内容问题。
- **改动既有文档：**
  - `architecture.md` —— 新增「API 契约总则」小节（总则 1–8）；收口「服务 API 契约」待决项；C2 措辞按张力 2 收紧。
  - `20-systems/common-properties.md` —— 「服务协作约定」追加总则 1 / 2 / 5 / 6 / 8 与 API 书写规范；跨服务调用纪律措辞收紧。
  - `system-overview.md` —— 第三 / 四节补 Bootstrap 启动契约、`internal sealed` manager、后端接口与离线 stub 切换。
  - **`adventure-event/common-properties.md` —— 「共有方法面」按裁决 3 重写为结算阶段名；新增「物化」条目（模板 vs 定稿实例）；对应的两条待决问题（`eventStart`/`eventEnd` 职责边界）收口。**
  - **`future-event-service.md` —— 「意图」层补「本服务是唯一物化点、产出即定稿」；API 面按上表重写。**
  - 其余七份服务文档各自重写「API 面」小节。
  - `terminology.md` —— 新增 `OpResult`、`ProfileChangeSpec`、`EventOption`、**物化 / materialize**、`CardInstance`、`SavePointReason`、`RngStream`、`InstanceId`。
- **影响存档 schema（修正原判断）。** 物化模型的推论 1 要求：**当前批 eventOptions 与 `pastEvent` 痕迹都要持久化定稿实例的快照**，而非只存 `EventId` 事后重算。这给 `pastEvent` 痕迹 schema 与增量 push 粒度两条待答项加了一个硬约束（快照体积 → 影响流量），需在那两条问题定案时一并考虑。
- **顺带收窄了两条既有待答项**（未裁决，仅提供了新的判断依据）：
  - 「eventOptions 的持久化形态」—— 物化模型意味着一批 eventOptions 若要落地，落的是**定稿实例**（`InstanceId`）而非模板 `Id`。
  - 「产出侧的可负担性保证」—— 既然 `selectCost` 是**物化时组装**的，「至少一个可负担选项」这条保证天然有落点：物化阶段即可对照 `CanAfford` 调整。

## 备选方案（已考虑并否决）

- **全异步（七个服务的方法一律 `Task`）** — 否决：三个纯本地服务永不跨边界（C8），给 `Has(flag)`、`Get(id)` 套 `Task` 是每次查询一次状态机分配，违 C10，且让「哪些调用会真的等」这个信息从签名里消失。
- **全同步 + 回调（`SignIn(channel, Action<OpResult> onDone)`）** — 否决：回调地狱在启动链（版本比对 → 登录 → pull → hydrate）上尤其明显，且无统一的取消 / 超时挂点。
- **失败一律抛异常** — 否决：网络失败与「付不起成本」是**预期内**的常态，用异常表达会让核心循环里到处是 `try/catch`，并与既定的 `TryApply → ApplyResult` 形态不一致。
- **Godot `[Signal]` 承载 EventBus**（裁决 1 的 B 项） — 否决：负载须继承 `GodotObject` → 每次广播分配 + `Variant` 装箱，撞 C5 / C10；其唯一优势（编辑器连接 / GDScript 订阅）在纯 C# 项目里用不上。（若日后确需编辑器可视化连接，可为少数低频事件额外挂 `[Signal]`，但不作为主通道。）
- **Godot 信号回调承载跨边界调用**（裁决 2 的 B 项） — 否决：调用点与结果处理点分离，启动链尤其难读，且无统一取消 / 超时挂点。
- **把物化结果写回 `AdventureEventData`** — 否决：`Resource` 是注册表里的共享只读单例且可被 overlay 覆写，运行时改它会污染同一轮回的后续批次与其他角色（总则 6）。
- **只存 `EventId`、消费时按需重算物化结果** — 否决：物化用了 seeded RNG + 当时的角色状态 + 可热更的模板，重算不保证同结果（C12 的确定性只在同一 `contentVersion` 内），会导致「呈现时看到的事件」与「结算时执行的事件」不一致。
- **`AdventureEventData` 上的虚方法 / `[Export] Script EventScript`**（裁决 3 的 B 项） — 否决：回到「每个事件一段代码」、失去数据驱动的可加性（C6），且脚本里改共享 `Resource` 状态的风险仍在。
- **capability flag 用字符串 key**（裁决 4 的 B 项） — 否决：flag 的消费点**必然**是一段 UI 代码（「隐藏属性显示组件自查并重绘」），新增 flag 本来就要写消费代码——字符串只是把「拼错了」从编译期推迟到运行时，换不来真正的可加性。（可加的是 `.tres` 里**谁授予哪个已定义的 flag**，这与 `data-resource-rules.md` 不冲突。）
- **保留 `CostSpec` / `RewardSpec` 两个类型**（裁决 5 的 B 项） — 否决：既定的「全有或全无、单点提交」本就要求成本与产出在同一事务内；两个类型会诱导出「先 `TryApply(cost)` 再 `TryApply(reward)`」这种半套写入。
- **服务门面暴露 manager（`ProfileService.Profile.TryApply(...)`）** — 否决：直接违 C2，且让「manager 不被跨服务调用」这条纪律在代码里无从执行。
- **每个服务各自在 `_Ready` 里 `async void` 做初始化 I/O** — 否决：`async void` 被 `csharp-godot-rules.md` 明确劝阻，且 autoload 的 `_Ready` 之间没有 await 关系，无法保证「content 就绪后才 pull」。

## 与既有决策的张力（均已裁决）

**张力 1 —— `eventStart` / `eventEnd` 是「AdventureEvent 自身的生命周期钩子」，与「数据即资源」相抵。 → 已裁决：松动。**

- 冲突的是：`adventure-event/common-properties.md`「共有方法面」把 `eventStart(...)` / `eventEnd(...)` 描述为**每个 AdventureEvent 自带的一对钩子**，「事件自身负责其内部流程」；而 `data-resource-rules.md` + C6 要求 `AdventureEventData : Resource` 只承载数据，且「新增一个事件 = 新增一个 `.tres`，而非编辑 switch 语句 / 写代码」。若钩子是 `Resource` 上的虚方法，则**新增一个事件就要新建一个 C# 子类**——可加性直接失效；且 `Resource` 是注册表里的共享单例，在其方法里持有本次结算的中间态会跨事件泄漏。
- **裁决（用户 2026-07-27）：** 采纳松动 —— **`eventStart` / `eventEnd` 是结算流程的两个阶段名，不是 `Resource` 上的方法**。落地形态见总则 8。
- **后续动作：** `adventure-event/common-properties.md` 的「共有方法面」小节按此重写；该文档与 `life-cycle-service.md` / `combat-service.md` 中「`eventStart` / `eventEnd` 与 `AdvanceEvent` 的职责边界未定」这条同名待决问题随之收口。

**张力 2 —— 「服务之间不互相读写字段」与服务互相调用门面。 → 已裁决：措辞收紧。**

- 严格读「服务之间只经编排顶点调用」会得出「life-cycle 不该直呼 `ProfileService.Instance`」。但 `system-overview.md` 第四节的示例正是 `LifeCycleService.AdvanceEvent` 内直呼 `ProfileService.Instance.TryApply(...)`，`program-overview.md` 阶段 4 也如此。
- **裁决（用户 2026-07-27）：** 这条纪律的措辞收紧为——**服务之间不读写对方字段、不伸手进对方 manager；跨服务的方法调用允许。** 编排顶点 game-progression 的定位不变（它负责「谁在什么时机调谁」的屏幕流程串联），但它不再被读作「一切跨服务调用的必经中转」。
- **后续动作：** `architecture.md`、`20-systems/common-properties.md`「服务协作约定」、`services/_index.md` 中的对应句子一并更新。这只是措辞澄清，不改变任何既定行为。

## 前置依赖

以下部分在对应问题答定前**无法定稿**，本文件以 `⟨待定⟩` 占位而非填充臆造值：

| 待稿部分 | 依赖的待答问题 |
|----------|----------------|
| `CostKey` 枚举成员、`ChangeElement.BaseValue` 是否够用（区间 / 公式？）、是否允许部分抵扣 | **cost element 清单**（`adventure-event/common-properties.md`、`profile-service.md`） |
| **`EventOption` 的完整物化字段清单**（除已列出的之外，还有哪些属性由物化决定） | **物化字段清单**（新增，归 `adventure-event/common-properties.md` + `future-event-service.md`，需一次内容侧 handoff） |
| `EventOption.Priority` 的取值域（`bool` 够用还是需 `int` 档位）、`AdvanceEventAsync` 对 `mode = Skip` + `IsMandatory` 的拒绝规则 | **`eventPriority` 取值域与置位方**、**与 `ifMandatory` 的叠加规则** |
| `pastEvent` 存储定稿实例快照的字段形态、区分「进入并结算」与「跳过」 | **`pastEvent` 的痕迹 schema**（现叠加物化推论 1 的硬约束） |
| `TryRefill` 落空后是否需兜底、`EventOptionBatch` 是否允许 `Options.Count == 0` | **补位落空的判定规则**、**全 mandatory + 付不起 `selectCost` 的死锁** |
| `Stream(RngStream)` 返回的 `RandomNumberGenerator` 其 `State` 如何进存档 schema | **RNG 状态的持久化形态**（`sync-service.md`） |
| 定稿实例快照的体积对增量 push 的影响 | **增量 push 的粒度**（`sync-service.md`） |
| `PushAsync` 失败后的行为（阻塞 / 缓冲 / 回退）、`SyncState.Buffered` 的上限与超时、`OpError.Migration` 的 UX | **断线降级的具体行为**、**迁移失败的玩家侧表现** |
| `CapabilityFlag` 的完整枚举成员与叠加规则、`ModifierKey` 的运算顺序 | **capability flag 的枚举与命名空间；叠加 / 冲突规则** |
| `IPlotBackend.PlotRequest` / `PlotSegment` 的字段 | **剧本服务契约**（请求 / 下发协议、缓存、离线降级） |
| `EncounterSpec` / `CombatSnapshot` / `TargetRef` / `PlayResult` 的字段 | **战斗内容全部未设计**（卡牌、敌人、遭遇战编排、效果系统） |
| 四个后端接口的报文字段与端点 | `backend-design-documents/open-questions.md`（协议契约） |

**本文件的可落地部分不被上述依赖阻塞**：总则 1–8、`OpResult` / `ApplyResult` / `ProfileChangeSpec`、服务门面骨架、Bootstrap 启动契约、物化模型的三阶段与三条推论、事件负载纪律、四个后端接口的**形状**，均已定案并可开写。
