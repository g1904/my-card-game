# 七服务的 API 契约 · AdventureEvent 物化模型

- id: 2026-07-27b-service-api-contracts
- date: 2026-07-27
- topic: systems/architecture、systems/common-properties、systems/services/**（七份服务文档 + plot-manager）、systems/adventure-event/common-properties、system-overview、terminology
- status: distilled
- distilled-to: systems/architecture.md, systems/common-properties.md, systems/services/_index.md, systems/services/account-service.md, systems/services/content-service.md, systems/services/sync-service.md, systems/services/profile-service.md, systems/services/life-cycle-service.md, systems/services/future-event-service.md, systems/services/plot-manager.md, systems/services/combat-service.md, systems/adventure-event/common-properties.md, system-overview.md, terminology.md, open-questions.md, answer-logs/log-service-api-contracts.md

> **一句话：** 七个服务的 API 面由「意图草图」升为**契约**——三种方法形态按边界划分、三种失败语义与 null-check 规则一一对应、EventBus 走强类型 C# 事件；同时确立 **AdventureEvent 的物化（materialize）模型**：`AdventureEventData` 是模板，future-event-service 是唯一物化点，产出的 `EventOption` 即定稿、不可改写。

来源：`inbox/solution-draft-service-api-contracts.md`（用户 2026-07-27 全数裁决）。

---

## Intent（distilled）

### 一、物化模型 —— AdventureEvent 的属性由 future-event-service 产出，产出即定稿

> 用户原话：*"many AdventureEvent properties are decided via future-event-service (after process on existing static resources or assets) (in order to add more variations and favors based on different scenarios). Once the AdventureEvent details are outputed from future-event-service, their data are finalized."*

这条把先前「`ifMandatory` / `eventPriority` 由 future-event-service 动态置位」从一个**局部例外**升级为**贯穿全局的产出模型**：

```
res:// + user://overlay/          ContentRegistry              future-event-service          life-cycle / combat / UI
  AdventureEventData(.tres)  ──▶  按 Id 索引的只读模板  ──▶  物化(materialize)        ──▶   只读消费
  = 静态素材 / 参数空间             共享单例、可热更           情境代入 → 定稿实例            不回查模板、不改字段
                                                             （EventOption，immutable）
```

1. **模板侧：`AdventureEventData : Resource` 是素材，不是成品。** 它承载稳定 `Id`、`eventType`、静态展示文案、基准数值与**可变体的参数空间**、数据驱动的 outcome / effect 定义。它是 ContentRegistry 里的**共享只读单例**，可被 overlay 热更覆写——**任何服务都不得在运行时写它**（写回会污染注册表，被同一轮回的后续批次与其他角色看到）。
2. **物化侧：future-event-service 是唯一物化点。** 输入 = 模板（经 `AllEnabled()` 取池）+ CharacterProfile（含隐藏属性、修行历程）+ location 框定 + PlotManager 调制 + SeedManager 的 map 子流；输出 = 一批 `EventOption`。这与既定的「eventOptions 唯一出口」完全同构——**产出 eventOptions ≡ 物化 AdventureEvent**。物化的目的是**按不同情境制造更多变化与风味**，故被物化的**不止那两个 flag**，而是多数具体属性。
3. **消费侧：产出即定稿（finalized · immutable）。** `EventOption` 一经输出即冻结：life-cycle-service / combat-service / ViewModel 一律只读消费，**不得回查模板重算、不得改写其字段**。这条纪律是「同一个事件在呈现、结算、记入历程三处看到的是同一份数据」的保证。

**三条推论：**

- **定稿实例必须落存档，不能只存 `EventId` 事后重算。** 物化用了 seeded RNG、当时的角色状态、以及可被 overlay 热更的模板；确定性只在同一 `contentVersion` 内成立，重算不保证同结果。因此**当前批 eventOptions 与 `pastEvent` 痕迹都要存物化后的快照**。
- **`InstanceId` 与 `EventId` 并存且不可互相替代。** 同一模板可在一次轮回里被物化多次（不同情境 → 不同实例）；`pastEvent`、`EventResolved` 负载、`TryRefill` 的「被跳过的那一个」都必须按 `InstanceId` 定位。
- **通则：** 凡「内容定义 + 情境 / 轮回内状态」的组合都是两个类型——`AdventureEventData` ↔ `EventOption`（**定稿不可变**）；`CardData` ↔ `CardInstance`（运行态**可变**，手牌中的临时增益）。二者共享同一纪律：**服务签名里传实例，不传 `Resource`**；差别只在实例本身是否可变。这与展示层三层切分同构，把第二层的类型形态明确了。

### 二、五个取向 —— 全数取推荐项

| # | 议题 | 裁决 |
|---|------|------|
| 1 | EventBus 的负载机制 | **C# 泛型 `event` + `readonly record struct` 负载**（不用 Godot `[Signal]`） |
| 2 | 跨进程边界方法的异步形态 | **`Task<OpResult<T>>` + `CancellationToken`** |
| 3 | `eventStart` / `eventEnd` 的宿主 | **结算流程的阶段名 + 两个 `IEventResolver` 实现**（不是 `Resource` 上的方法） |
| 4 | capability flag 的载体 | **C# `enum CapabilityFlag`**（不是字符串 key） |
| 5 | `CostSpec` / `RewardSpec` 是两个类型还是一个 | **合并为单一 `ProfileChangeSpec`**（element 带符号） |

### 三、两处与既有决策的张力 —— 均按建议松动

- **张力 1（`eventStart` / `eventEnd` vs 数据即资源）：** 若钩子是 `Resource` 上的虚方法，新增一个事件就要新建一个 C# 子类，可加性直接失效；且 `Resource` 是共享单例，在其方法里持有本次结算的中间态会跨事件泄漏。**裁决：`eventStart` / `eventEnd` 是结算流程的两个阶段名，不是 `Resource` 上的方法。**
- **张力 2（「服务之间不互相读写字段」vs 服务互相调用门面）：** 既有示例本就是 `LifeCycleService.AdvanceEvent` 内直呼 `ProfileService.Instance.TryApply(...)`。**裁决：措辞收紧为——服务之间不读写对方字段、不伸手进对方 manager；跨服务的方法调用允许。** 编排顶点 game-progression 的定位不变（负责「谁在什么时机调谁」的屏幕流程串联），但它不再被读作「一切跨服务调用的必经中转」。这只是措辞澄清，不改变任何既定行为。

### 四、八条契约总则

**总则 1 —— 三种方法形态，按「它跨什么边界」决定。** 不允许混用；形态 B / C 一律带 `Async` 后缀并返回 `Task`，形态 A 一律不带——看签名即知它是否跨边界。

| 形态 | 适用 | 签名形状 | 理由 |
|------|------|----------|------|
| **A · 同步直返** | 纯内存查询与纯本地事务（查内容、施加变更、能力查询、RNG 派生、物化） | `T Get(...)` / `ApplyResult TryApply(...)` / `bool Has(...)` | 无 I/O、单帧内完成；引入 `Task` 只会给每次查询加一次状态机分配 |
| **B · `Task<OpResult<T>>`** | 跨客户端 ↔ 后端边界的一切（account / content update / sync push-pull / PlotManager 请求剧本） | `Task<OpResult<PlayerProfile>> PullProfileAsync(string accountId, CancellationToken ct)` | 网络失败是**常态而非异常**；`Task` 让离线 stub 变成一行 `Task.FromResult`，也让超时 / 取消 / 重试有统一挂点 |
| **C · `Task<T>` 由信号推进** | 跨多帧的玩法长流程（`RunCombatAsync`、`AdvanceEventAsync`） | `Task<CombatResult> RunCombatAsync(...)`，内部 `await ToSignal(...)` 等玩家输入 | 调用方要的是「战斗打完给我结果」这一件事；帧级推进封在服务内部，不外泄成状态机 |

**总则 2 —— 失败语义三分，与 null-check 规则一一对应。**

| 失败性质 | 形状 | 例 |
|----------|------|-----|
| **必需缺失 = 程序缺陷 / 坏数据** | `GD.PushError($"[Svc-Method] ..., id={id}")` + `throw` | `ContentRegistry.Get(id)`、启动期校验 |
| **可选缺失 = 调用方可降级** | `bool TryXxx(..., out T value)`，返回 `false` 前 `GD.PushWarning` | `ContentRegistry.TryGet`、`TryRefill` |
| **业务失败 = 预期内的拒绝** | 返回 `OpResult` / `OpResult<T>` / `ApplyResult`，**绝不抛** | 付不起成本、网络不通、token 失效、重试耗尽 |

```csharp
public enum OpError { None, Network, Auth, Compliance, Validation, NotFound, Conflict, Cancelled, Migration }

public readonly record struct OpResult(bool Success, OpError Error, string Detail)
{
    public static OpResult Ok()                           => new(true,  OpError.None, string.Empty);
    public static OpResult Fail(OpError e, string detail) => new(false, e, detail);
}
public readonly record struct OpResult<T>(bool Success, T Value, OpError Error, string Detail);

// ApplyResult 保留为独立类型：它多带「哪个 element 不足」，UI 要用它做灰显与提示
public readonly record struct ApplyResult(bool Success, CostKey MissingElement);
```

`readonly record struct` 而非 class：结果对象在核心循环里每步都产生，**零堆分配**，且天然带值相等与解构。

**总则 3 —— 服务门面的固定骨架。** 每个服务都长一样：`static Instance` + `private` manager 字段 + 只暴露方法的 API 面。三条配套约定：① **manager 类型声明为 `internal sealed`**——同程序集内可测，跨服务代码里根本写不出对方 manager 的类型名；② 服务间只经 `Xxx.Instance.Method(...)` 调用，`Instance` 为 null 即启动顺序配错，属「必需缺失」→ `PushError` + 抛，不做静默降级；③ **服务不返回内部可变集合**，一律 `IReadOnlyList<T>` / `IReadOnlyDictionary<,>`。

**总则 4 —— 启动契约：`_Ready` 只装配，`InitializeAsync` 才做 I/O。** Godot autoload 的 `_Ready` 不能 `await`，而 content-service 启动就要比对云端版本、sync-service 要 pull。既有的「autoload 声明顺序 = 启动依赖顺序」只解决了**装配**顺序，没解决**初始化**顺序。引入一个 **Bootstrap 屏幕场景**（`scenes/screens/BootstrapScreen.tscn`，非服务、非 autoload），作为 `main` 场景按固定顺序驱动异步初始化并把进度喂给启动画面：

```csharp
public interface IBootstrappable          // 由四个边界服务实现
{
    Task<OpResult> InitializeAsync(CancellationToken ct);
}
```

顺序：`ContentService.InitializeAsync`（版本比对 + overlay 合并 + 校验，断网降级到基线）→ 进 `LoginScreen` → `AccountService.SignInAsync` → `SyncService.InitializeAsync`（pull + 迁移）→ `ProfileService.Hydrate` → 进 `MainMenu`。三个纯本地服务（profile / life-cycle / combat）**不实现该接口**——它们在 `_Ready` 里装配完就绪。这同时给了「首启不依赖网络下载内容，但进入游戏仍需登录」一个明确的落点。

**总则 5 —— EventBus：C# 泛型事件 + `readonly record struct` 负载。** Godot `[Signal]` 传自定义负载要求负载继承 `GodotObject`，于是**每次广播都分配一个引用对象并经 `Variant` 装箱**——直接撞上「层与层之间不做隐式装箱 / 转换」与「热路径不分配」。核心循环每步要广播 `EventResolved`、战斗内每张牌要广播 `CardResolved`，这条路径不该分配。EventBus 仍是 autoload `Node`（保持它在场景树里、可在 `_ExitTree` 做泄漏检查），但对外暴露**强类型 C# 事件**：

```csharp
public event Action<CycleStarted>  CycleStarted;
public void Emit(in CycleStarted e)
{
    GD.Print($"[EventBus-Emit] CycleStarted character={e.CharacterId} chapter={e.Chapter}");
    CycleStarted?.Invoke(e);
}
```

配套纪律：**订阅方在 `_Ready` 订阅、在 `_ExitTree` 退订**。代价：GDScript 与编辑器信号面板订阅不了——本项目纯 C#，不构成损失。

**总则 6 —— 物化模型。** 见上文第一节。类型形态：

```csharp
public sealed record EventOption(                 // 定稿实例：immutable 引用类型，落存档
    string             InstanceId,                // 本次物化实例的稳定标识；pastEvent / 存档引用它
    string             EventId,                   // 溯源到模板
    EventType          EventType,                 // Mystery 时 = 遮罩类型；真身见 RevealedEventId
    int                Priority,                  // 物化时置位
    bool               IsMandatory,               // 物化时置位
    ProfileChangeSpec  SelectCost,                // 物化时组装（modifier pipeline 尚未施加）
    ProfileChangeSpec  SkipCost,
    bool               IsRevealed,                // Mystery：是否已揭示
    string             RevealedEventId            // Mystery 遮罩的固定事件（物化时即已确定）
    /* ⟨待定：其余物化字段清单⟩ */);
```

**为何是 `sealed record`（引用类型）而非 `readonly record struct`：** 字段多、要落存档、一批只有个位数个、不在每帧热路径——按值拷贝的代价高于一次分配。`record` 的 `with` 表达式同时给出了「定稿后若确需派生（如 Mystery 揭示）就产生一个新实例而非改旧的」这一惯用法。

**总则 7 —— 后端接口化：四个边界服务各持一个可替换后端。** 把跨进程边界的调用收敛到四个窄接口，让离线 stub 是「换一个实现」而不是「在服务里插 `if (offline)`」：

```csharp
internal interface IAccountBackend  { Task<OpResult<Session>>          SignInAsync(LoginChannel c, CancellationToken ct); }
internal interface IContentBackend  { Task<OpResult<ContentManifest>>  GetManifestAsync(CancellationToken ct); }
internal interface IProfileBackend  { Task<OpResult<PlayerProfile>>    PullAsync(string accountId, CancellationToken ct);
                                      Task<OpResult>                   PushAsync(ProfilePayload p, CancellationToken ct); }
internal interface IPlotBackend     { Task<OpResult<PlotSegment>>      ResolveAsync(PlotRequest req, CancellationToken ct); }
```

每个接口两份实现：`HttpXxxBackend`（后端就绪后）与 `OfflineXxxBackend`（当前阶段，读 `res://` 假数据 / 内存回显）。选择哪份由服务上的 `[Export] bool UseOfflineBackend`（默认 `true`，直到后端上线）决定——开发期切换不需要重编译。

> 这四个接口是客户端 ↔ 后端**协议契约的客户端一侧投影**；其权威在 `backend-design-documents/`。本库只定客户端的**调用形状**（方法名、参数、`OpResult` 语义），不定 HTTP 路径 / 报文字段。

**总则 8 —— 结算阶段名取代「事件自带钩子」。** `eventStart` / `eventEnd` 是 `AdvanceEventAsync` 内部结算流程的两个阶段名。落地为一个数据驱动的结算器：

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
  → TryApply(SelectCost | SkipCost)          ← 付不起则回 AdvanceResult 拒绝，不产生任何写入
  → 【eventStart 阶段】选 resolver、Mystery 揭示
  → resolver.ResolveAsync(option, ct)
  → 【eventEnd 阶段】合并 ResolveOutcome + lifeSpanCost + 隐藏属性推拉为**一次** TryApply
  → 记入 pastEvent（按 InstanceId，携带定稿实例快照）
  → RunStateManager 终态判定 → EventBus 广播 → sync 自动存档点
```

九类事件仍只有**两个** resolver——与既定拆分轴「只有 Combat 真有状态机、其余差异在数据而非代码」完全一致，且保住了「新增一个事件 = 新增一个 `.tres`」的可加性。

### 五、共享核心类型与各服务首版签名

共享核心类型（`src/Core/`）：

```csharp
public sealed class ProfileChangeSpec { public IReadOnlyList<ChangeElement> Elements { get; } }
public readonly record struct ChangeElement(CostKey Key, int BaseValue);   // 负 = 消耗，正 = 产出
public enum CostKey        { LifeSpan, Jade, /* ⟨待定：其余 element 清单⟩ */ }
public enum AdvanceMode    { Select, Skip }
public enum CycleStatus    { Ongoing, Defeated, Completed }
public enum DefeatReason   { Discarded, LifeSpanExhausted, CombatLost }
public enum CapabilityFlag { RevealHiddenStats, ShowMysteryType, ShowSkipCost }
public enum HiddenStat     { Faith, MaleficQi, LifeSpan }
public enum RngStream      { Map, Combat, Shop, Reward }
public enum EventType      { Practice, Combat, Research, Exchange, Social, Mystery, Finale, Explore, Travel }
```

逐服务的方法表已折进各服务文档的「API 面（契约）」小节，不在此重复。四条值得单列的推演：

- **`sync-service.PushAsync` 不接收 profile 参数。** profile 的内存权威在 profile-service；让调用方递一份 profile 进来等于把「谁是权威」这件事再打开一次。
- **`life-cycle-service.AdvanceEventAsync` 收 `EventOption`（定稿实例）而非 `AdventureEventData`**，且**不收 `character` 参数**（每篇章至多一个 `ongoing`，当前角色是服务自己的状态机持有物）。
- **`life-cycle-service.Stream(RngStream)` 暴露 `RandomNumberGenerator` 而非 `int Next()`。** Godot 的 `RandomNumberGenerator` 自带可序列化的 `Seed` / `State`，正好是既定 RNG 持久化形态的载体。
- **`CombatResult.Spoils` 是 `ProfileChangeSpec` 而非「已写好的变更」。** combat-service 只**描述**结果，life-cycle-service 在 `eventEnd` 阶段把它连同 `lifeSpanCost` 与隐藏属性推拉**合并为一次 `TryApply`**，从而「一个事件 = 一次事务 = 一个存档点」。（战斗**过程中**的血 / mana 变更仍即时经 ProfileManager；`Spoils` 只承载收口产出。）

### 六、EventBus 负载 schema 与三条负载纪律

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

1. **负载只带 `Id` + 值类型，绝不带 `CharacterProfile` / `Resource` / `EventOption` 引用。** 传引用等于给每个订阅者开一条绕过唯一写入入口的旁路，也让定稿实例有被下游改写的可能。需要完整实例的订阅者按 `InstanceId` 向 future-event-service 取。
2. **`CapabilitiesChanged` 空负载。** 订阅者收到后自行 `ProfileService.Instance.Has(flag)` 重查——这正是既定的「一个 flag ↔ 一处消费点 · 单点查询」；把生效集塞进负载反而制造第二份真值。
3. **广播 = 既成事实，不可否决。** EventBus 不承载「请求 / 询问」；需要返回值的一律是直接方法调用。

### 七、API 书写规范

各服务文档的「API 面」小节统一为四列表：**方法 | 形态(A/B/C) | 完整签名 | 失败语义**。凡形状依赖未答问题的，写 `⟨待定：链接到待决项⟩`，不留空白也不臆造。

---

## 已否决的备选（保留理由，避免重开）

- **全异步（七个服务的方法一律 `Task`）** — 三个纯本地服务永不跨边界，给 `Has(flag)` / `Get(id)` 套 `Task` 是每次查询一次状态机分配，且让「哪些调用会真的等」这个信息从签名里消失。
- **全同步 + 回调** — 回调地狱在启动链（版本比对 → 登录 → pull → hydrate）上尤其明显，且无统一的取消 / 超时挂点。
- **失败一律抛异常** — 网络失败与「付不起成本」是**预期内**的常态，用异常表达会让核心循环里到处是 `try/catch`，并与既定的 `TryApply → ApplyResult` 形态不一致。
- **Godot `[Signal]` 承载 EventBus** — 负载须继承 `GodotObject` → 每次广播分配 + `Variant` 装箱；其唯一优势（编辑器连接 / GDScript 订阅）在纯 C# 项目里用不上。（若日后确需编辑器可视化连接，可为少数低频事件额外挂 `[Signal]`，但不作为主通道。）
- **把物化结果写回 `AdventureEventData`** — `Resource` 是注册表里的共享只读单例且可被 overlay 覆写，运行时改它会污染同一轮回的后续批次与其他角色。
- **只存 `EventId`、消费时按需重算物化结果** — 重算不保证同结果，会导致「呈现时看到的事件」与「结算时执行的事件」不一致。
- **`AdventureEventData` 上的虚方法 / `[Export] Script EventScript`** — 回到「每个事件一段代码」、失去数据驱动的可加性。
- **capability flag 用字符串 key** — flag 的消费点**必然**是一段 UI 代码，新增 flag 本来就要写消费代码；字符串只是把「拼错了」从编译期推迟到运行时。（可加的是 `.tres` 里**谁授予哪个已定义的 flag**。）
- **保留 `CostSpec` / `RewardSpec` 两个类型** — 「全有或全无、单点提交」本就要求成本与产出在同一事务内；两个类型会诱导出「先 `TryApply(cost)` 再 `TryApply(reward)`」这种半套写入。
- **服务门面暴露 manager** — 让「manager 不被跨服务调用」这条纪律在代码里无从执行。
- **每个服务各自在 `_Ready` 里 `async void` 做初始化 I/O** — `async void` 被明确劝阻，且 autoload 的 `_Ready` 之间没有 await 关系，无法保证「content 就绪后才 pull」。

## Open questions

- **`EventOption` 的完整物化字段清单。** 已定骨架九字段；「多数属性由物化决定」意味着还有一批未列出的字段（哪些数值可被情境改写？风味文案是否也物化？outcome 权重是否在物化时固化？）。这需要一次**内容侧** handoff。→ `systems/adventure-event/common-properties.md`、`systems/services/future-event-service.md`。
- **`AdvanceEventAsync` 的取消语义。** 形态 C 带 `CancellationToken`，但「谁会取消一场进行中的事件 / 战斗」以及取消后已施加的 `SelectCost` 如何处置（回滚？视同结算？）未定——它与「战斗中途断线 / 退出」是同一个问题的两面。→ `systems/services/life-cycle-service.md`、`combat-service.md`、`sync-service.md`。
- **`[Export] bool UseOfflineBackend` 的发布期防护。** 默认 `true` 直到后端上线；正式包如何保证它不为 `true`（导出预设 / 编译期 `#if` / 启动期断言）未定——这是一个能悄无声息发到线上的开关。→ `system-overview.md`。
- **`OpError` → 玩家文案的映射归属。** `OpResult.Detail` 约定携带「面向玩家的原因串，由 UI 层决定文案」；这份映射表由谁持有（UI 层常量？本地化表？服务返回已本地化串？）未定。→ `ux/`。
- **EventBus 退订纪律的可执行性。** 「`_Ready` 订阅 / `_ExitTree` 退订」是约定；漏退订即泄漏且在 C# 事件上不会报错。是否需要 EventBus 侧的调试期订阅计数 / 泄漏检查未定。→ `systems/architecture.md`。

## Notes / triage

**一处内部矛盾，已按下述解读收口（需用户确认）：** 草稿的「总则 6 推论 1」断言*「当前批 eventOptions 与 `pastEvent` 痕迹都要存物化后的快照」*（并在备选方案中明确否决「只存 `EventId` 事后重算」），而同一文件的「后果」小节又把「eventOptions 的持久化形态」列为**未裁决、仅提供判断依据**。

- **解读：以推论 1 为准——持久化形态本身已定案**（落定稿实例快照，不重算）。理由：它是用户「产出即定稿」裁决的直接逻辑后果，且对应的备选方案已被明确否决；「后果」小节的措辞是草稿撰写时的残留。
- **仍待定的是下一层：** 快照的**字段形态 / schema**（`pastEvent` 如何区分「进入并结算」与「跳过」、快照存哪些字段）、以及**快照体积对增量 push 的影响**。这两条留在待答清单。
