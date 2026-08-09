# system-overview —— 项目结构与落地形态

> **这份文档回答「这些服务在 Godot 工程里长什么样」。** 进程边界、文件夹布局、autoload 注册、service / manager 的代码形态。
>
> 「代码怎么跑起来」的端到端运行链路见 `program-overview.md`；结构与边界的**权威**在 `systems/architecture.md`。
> Source: `handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md` + `handoffs/2026-07-27b-service-api-contracts.md`（Bootstrap 启动契约、`internal sealed` manager、后端接口化）。

---

## 一、术语澄清：service ≠ 微服务

**七个 service 全部在同一个 Godot 项目、同一个二进制、同一个进程里**，彼此之间是**直接的 C# 方法调用**——没有网络、没有序列化、没有独立部署单元。

「服务」这个词在本项目中的准确含义是：**一个有明确边界的进程内模块单例**。借用这个词的价值**不在于分布式部署**，而在于那套**边界纪律**（服务之间不互相读写字段、唯一入口、经编排顶点或 EventBus 通信）——这套纪律靠约定与代码审查执行，不靠网络强制。

> 因此本库**不使用「微服务」一词**。相关文档统一称「服务（进程内模块单例）」。

### 真正的进程边界只有一条

```
┌──────────────────────────────────────────────────────────┐
│  客户端 = 一个 Godot 二进制 = 一个进程                     │
│                                                           │
│   7 个 service（autoload 单例）+ 它们的 manager            │
│   ↕ 全部是普通 C# 方法调用                                 │
└───────────────────────┬──────────────────────────────────┘
                        │  HTTP / WebSocket  ← 唯一真实的进程边界
                        ↓
┌──────────────────────────────────────────────────────────┐
│  后端（独立分支线 backend-*，见 backend-design-documents/） │
│  账号鉴权 · 档案存储 · 剧本下发 · 内容分发(CDN)             │
└──────────────────────────────────────────────────────────┘
```

七个服务中**只有 4 个碰这条边界**：`account-service`、`content-service`、`sync-service`，以及 `future-event-service` 内部的 `PlotManager`。其余三个（`profile-service` / `life-cycle-service` / `combat-service`）**纯本地**，永远不发网络请求。

---

## 二、项目结构

```
game-feature-branch/
├── project.godot
├── game-feature-branch.csproj
│
├── src/                              ← C# 代码，不含场景
│   ├── Autoload/
│   │   └── EventBus.cs
│   ├── Core/                         ← 核心「类」与共享契约类型（纯数据对象，非 Node）
│   │   ├── PlayerProfile.cs          ← ⊃ List<CharacterProfile>
│   │   ├── CharacterProfile.cs
│   │   ├── OpResult.cs  ApplyResult.cs      ← 统一结果类型（readonly record struct）
│   │   ├── ProfileChangeSpec.cs  ChangeElement.cs   ← 成本与产出合一，element 带符号
│   │   ├── EventOption.cs  EventOptionBatch.cs      ← 物化后的定稿实例
│   │   ├── IBootstrappable.cs        ← 启动契约（四个边界服务实现）
│   │   └── Enums.cs                  ← CostKey / CapabilityFlag / RngStream / EventType ...
│   ├── Data/                         ← XxxData : Resource 定义
│   │   ├── AdventureEventData.cs
│   │   ├── CardData.cs  EnemyData.cs  ItemData.cs  PlayerPowerData.cs
│   ├── Services/                     ← 一个文件夹 = 一个服务及其全部 manager
│   │   ├── Account/
│   │   │   ├── AccountService.cs         ← Node（autoload）
│   │   │   ├── AuthManager.cs            ← internal sealed，普通 C# 类
│   │   │   ├── ComplianceManager.cs
│   │   │   └── IAccountBackend.cs  HttpAccountBackend.cs  OfflineAccountBackend.cs
│   │   ├── Content/
│   │   │   ├── ContentService.cs
│   │   │   ├── ContentRegistry.cs
│   │   │   ├── ContentUpdateManager.cs
│   │   │   ├── IContentRepository.cs
│   │   │   └── IContentBackend.cs  HttpContentBackend.cs  OfflineContentBackend.cs
│   │   ├── Sync/
│   │   │   ├── SyncService.cs
│   │   │   ├── ProfileSyncManager.cs  LocalCacheManager.cs  MigrationManager.cs
│   │   │   └── IProfileBackend.cs  HttpProfileBackend.cs  OfflineProfileBackend.cs
│   │   ├── Profile/
│   │   │   ├── ProfileService.cs
│   │   │   ├── ProfileManager.cs  CapabilityManager.cs  AchievementManager.cs
│   │   ├── LifeCycle/
│   │   │   ├── LifeCycleService.cs
│   │   │   ├── CycleStateManager.cs  ChapterManager.cs  SeedManager.cs
│   │   │   └── IEventResolver.cs  CombatEventResolver.cs  GenericEventResolver.cs
│   │   ├── FutureEvent/
│   │   │   ├── FutureEventService.cs
│   │   │   ├── EventOptionManager.cs  PlotManager.cs
│   │   │   └── IPlotBackend.cs  HttpPlotBackend.cs  OfflinePlotBackend.cs
│   │   └── Combat/
│   │       ├── CombatService.cs
│   │       ├── TurnManager.cs  CharacterManager.cs  EnemyManager.cs
│   │       └── CombatantDeck.cs      ← 参战方内部组件，每 character / enemy 一份
│   ├── Progression/
│   │   └── GameProgression.cs        ← 编排顶点
│   └── UI/
│       └── ViewModels/
│
├── scenes/                           ← .tscn
│   ├── screens/     BootstrapScreen  LoginScreen  MainMenu  EventMenu  CombatScreen
│   ├── combat/      Card  Enemy
│   └── components/
│
├── content/                          ← res:// 基线内容（.tres）
│   ├── manifest.json                 ← contentVersion + 逐条目 hash
│   ├── events/  cards/  enemies/  items/  powers/  balance/
│
└── assets/                           ← 美术 / 音频
```

**一个文件夹 = 一个服务及其全部 manager。** 文件夹边界即服务边界——视觉上一眼看出「这个 manager 属于谁」。

---

## 三、注册：service 是 autoload，manager 不是

`project.godot` 中声明（**顺序即启动依赖顺序**，Godot 按声明顺序执行 `_Ready`）：

```ini
[autoload]

EventBus="*res://src/Autoload/EventBus.cs"
ContentService="*res://src/Services/Content/ContentService.cs"
AccountService="*res://src/Services/Account/AccountService.cs"
SyncService="*res://src/Services/Sync/SyncService.cs"
ProfileService="*res://src/Services/Profile/ProfileService.cs"
LifeCycleService="*res://src/Services/LifeCycle/LifeCycleService.cs"
FutureEventService="*res://src/Services/FutureEvent/FutureEventService.cs"
CombatService="*res://src/Services/Combat/CombatService.cs"
```

Godot 4 允许 autoload 直接指向 `.cs` 脚本（类继承 `Node` 即可），无需为每个服务建空 `.tscn`。

> **这是一条无例外的约定（已定案）：七个服务的 autoload 形态统一，不为承载配置而建空场景。** 直接推论：**autoload 指向 `.cs` 时不存在场景实例，`[Export]` 没有存储处、检视器里也无从编辑**——运行时永远拿到字段默认值。因此**服务级配置项一律走 ProjectSettings，不走 `[Export]`**；`[Export]` 保留给真正的场景组件（卡牌、敌人、UI 控件），那才是「设计师在检视器里调数值」的正确落点。Source: `handoffs/2026-08-09e-discipline-enforceability.md`。

**七个服务 = 场景树中七个常驻节点；manager 一个节点都不占**——它们是服务持有的普通 C# 对象：

```
/root
 ├── EventBus
 ├── ContentService          ← 内部持有 ContentRegistry / ContentUpdateManager
 ├── AccountService
 ├── SyncService
 ├── ProfileService          ← 内部持有 ProfileManager / CapabilityManager / AchievementManager
 ├── LifeCycleService
 ├── FutureEventService      ← 内部持有 EventOptionManager / PlotManager
 ├── CombatService
 └── CurrentScreen           ← 当前屏幕场景，随流程切换
```

---

## 四、代码形态

### 服务（`Node`，autoload）

```csharp
// src/Services/Profile/ProfileService.cs
using Godot;

public partial class ProfileService : Node
{
    public static ProfileService Instance { get; private set; }

    // manager 是内部实现，对外只暴露服务自己的 API 面
    private ProfileManager _profile;
    private CapabilityManager _capability;
    private AchievementManager _achievement;

    public override void _Ready()
    {
        Instance = this;
        _profile     = new ProfileManager(this);
        _capability  = new CapabilityManager(this);
        _achievement = new AchievementManager(this);
        GD.Print("[ProfileService-Ready] managers initialized");
    }

    // ── 对外 API 面（其他服务只看得见这些；绝不暴露 manager 引用）──
    public ApplyResult TryApply(ProfileChangeSpec spec)      => _profile.TryApply(spec);
    public bool CanAfford(ProfileChangeSpec spec)            => _profile.CanAfford(spec);
    public bool Has(CapabilityFlag flag)                     => _capability.Has(flag);
    public int  ApplyModifier(ModifierKey k, int baseValue)  => _capability.ApplyModifier(k, baseValue);
}
```

**服务门面的骨架是固定的**（`systems/architecture.md` 总则 3）：`static Instance` + `private` manager 字段 + 只暴露方法的 API 面 + **不返回内部可变集合**（一律 `IReadOnlyList<T>` / `IReadOnlyDictionary<,>`）。`Instance` 为 null 即启动顺序配错，属「必需缺失」→ `GD.PushError` + 抛，不做静默降级。

### 管理器（普通 C# 类，**不是** `Node`；一律 `internal sealed`）

```csharp
// src/Services/Profile/ProfileManager.cs
using Godot;

internal sealed class ProfileManager        // internal：跨服务代码里根本写不出这个类型名
{
    private readonly ProfileService _host;   // 同服务内可互相访问
    private PlayerProfile _profile;          // ⊃ List<CharacterProfile>

    public ProfileManager(ProfileService host) => _host = host;

    public ApplyResult TryApply(ProfileChangeSpec spec)
    {
        // 1) 全量校验：modifier pipeline 在读数值时生效
        foreach (var e in spec.Elements)
        {
            int cost = _host.ApplyModifier(e.Key, e.BaseValue);
            if (!CanPay(e, cost))
            {
                GD.PushWarning($"[ProfileManager-TryApply] insufficient, element={e.Key}");
                return ApplyResult.Fail(e.Key);   // 全有或全无，未写任何字段
            }
        }
        // 2) 一次性提交
        foreach (var e in spec.Elements) Pay(e, _host.ApplyModifier(e.Key, e.BaseValue));
        return ApplyResult.Ok();
    }
}
```

### 跨服务调用：允许，但只经对方的服务门面

**边界纪律的准确措辞：服务之间不读写对方字段、不伸手进对方 manager；跨服务的方法调用允许。**

```csharp
// src/Services/LifeCycle/LifeCycleService.cs
public async Task<AdvanceResult> AdvanceEventAsync(EventOption chosen, CancellationToken ct)
{
    // 收定稿实例而非 AdventureEventData：Priority / SelectCost 都是物化时置位的
    var spec = chosen.SelectCost;   // 08-06c：无跳过通道，推进只有一种形态

    ProfileService.Instance.TryApply(spec);                 // ✅ 服务门面；无条件施加，不做「付得起」校验
    // var result = ProfileService.Instance._profile...      // ❌ 伸手进 manager

    var statusAfterCost = _cycleState.EvaluateStatus();      // 终态判定 ①：支付本身可能耗尽寿元
    if (statusAfterCost == CycleStatus.Defeated)
        return new AdvanceResult(false, AdvanceStage.None, default, CycleStatus.Defeated);

    GD.Print($"[LifeCycle-AdvanceEvent] start instance={chosen.InstanceId} event={chosen.EventId}");
    // ...
}
```

### 启动契约：`_Ready` 只装配，`InitializeAsync` 才做 I/O

autoload 的 `_Ready` 不能 `await`，而 content-service 启动就要比对云端版本、sync-service 要 pull。「autoload 声明顺序」只解决**装配**顺序，未解决**初始化**顺序。因此由一个 **Bootstrap 屏幕场景**（`scenes/screens/BootstrapScreen.tscn`，**非服务、非 autoload**，作为 `main` 场景）驱动异步初始化并把进度喂给启动画面：

```csharp
public interface IBootstrappable          // 由四个边界服务实现
{
    Task<OpResult> InitializeAsync(CancellationToken ct);
}
```

```
ContentService.InitializeAsync   （版本比对 + overlay 合并 + 校验；断网降级到 res:// 基线）
  → LoginScreen → AccountService.SignInAsync
  → SyncService.InitializeAsync  （pull + 迁移）
  → ProfileService.Hydrate
  → MainMenu
```

三个纯本地服务（profile / life-cycle / combat）**不实现该接口**——它们在 `_Ready` 里装配完就绪。

### 后端接口化：四个边界服务各持一个可替换后端

```csharp
internal interface IAccountBackend  { Task<OpResult<Session>>          SignInAsync(LoginChannel c, CancellationToken ct); }
internal interface IContentBackend  { Task<OpResult<ContentManifest>>  GetManifestAsync(CancellationToken ct); }
internal interface IProfileBackend  { Task<OpResult<ProfileSnapshot>>  PullAsync(string accountId, CancellationToken ct);
                                      Task<OpResult<PushAck>>          PushAsync(ProfilePayload p, CancellationToken ct); }
internal interface IPlotBackend     { Task<OpResult<PlotSegment>>      ResolveAsync(PlotRequest req, CancellationToken ct); }
```

每个接口两份实现：`HttpXxxBackend`（后端就绪后）与 `OfflineXxxBackend`（当前阶段，读 `res://` 假数据 / 内存回显）。离线 stub 是「换一个实现」，而不是「在服务里插 `if (offline)`」。

#### 选择形态：唯一选择点 + Release 构建里离线实现根本不存在（已定案）

**四个服务不各自持开关。** 选级理由见 `systems/architecture.md`「纪律的可执行化」——离线后端属「能上线且线上不可见」，必须做到阶梯第 1 级。Source: `handoffs/2026-08-09e-discipline-enforceability.md`。

```csharp
// src/Core/BackendSelector.cs —— 后端实现的唯一选择点
internal static class BackendSelector
{
    internal static IAccountBackend CreateAccount() =>
#if DEBUG
        UseOffline ? new OfflineAccountBackend() : new HttpAccountBackend();
#else
        new HttpAccountBackend();
#endif
    // CreateContent() / CreateProfile() / CreatePlot() 同形

    private static bool UseOffline =>
        (bool)ProjectSettings.GetSetting("mycardgame/backend/use_offline_backend", true);
}
```

```csharp
// src/Services/Account/OfflineAccountBackend.cs —— 四个离线实现整类包在 #if DEBUG 内
#if DEBUG
internal sealed class OfflineAccountBackend : IAccountBackend { /* ... */ }
#endif
```

| # | 手段 | 阶梯级 | 作用 |
|---|------|--------|------|
| 1 | **`BackendSelector` 唯一选择点** | 1 | **四个字段 = 四个可能各自出错的点**，最糟的失败态是「三个开了一个没开」的半在线状态（登录成功、内容加载正常，只有存档静默写进内存回显）——比全离线更难诊断。收敛成一个点后这个失败态在结构上不存在 |
| 2 | **`OfflineXxxBackend` 整类 `#if DEBUG`** | 1 | **主闸**：Release 构建里离线实现不存在，问题从「开关会不会配错」降级为「类型存不存在」——配错连编译都不通过 |
| 3 | **ProjectSettings `mycardgame/backend/use_offline_backend`**（bool，默认 `true`） | 3 | 开发期开关载体，**取代 `[Export]`**。值落在 `project.godot`：进版本控制、可 diff、可在评审中看见；Godot 原生支持 feature tag override（`....release`） |
| 4 | **BootstrapScreen 横幅 + release×offline 断言** | 3 | 在驱动 `InitializeAsync` 前打一行必然位于日志顶部的 `[Bootstrap-Backends] offline=… build=…`；`!OS.IsDebugBuild() && IsOffline` → `PushError` + `throw`。若第 2 项生效此 `throw` 恒不可达，**保留它是为了防「条件编译常量哪天被改错」**，成本一行 |

**条件编译使用清单（穷举，不得扩张）：** `src/Core/BackendSelector.cs`、四个 `src/Services/*/Offline*Backend.cs`、`src/Autoload/EventBus.cs` 的审计块，**共 6 处**。**服务与 manager 内部一律不得出现 `#if`**——「换实现而非插 `if`」在条件编译上同样成立。

> **待实测确认一次：** 前提是「Godot 的 .NET 集成在 Release 导出配置下不定义 `DEBUG`，编辑器内运行与 Debug 导出定义」。`game-feature-branch/` 当前尚无 `.csproj`，无从验证；若不成立，改用显式 `<DefineConstants>MYCARDGAME_OFFLINE_OK</DefineConstants>`，**方案形态不变**。

---

## 五、实践后果

- **装配顺序 = autoload 声明顺序；初始化顺序 = Bootstrap 屏幕。** `ContentService` 必须排在一切依赖内容的服务之前；`AccountService` 排在 `SyncService` 之前（后者需要 token）。**但涉及 I/O 的初始化不在 `_Ready` 里**——它由 Bootstrap 屏幕按 `IBootstrappable` 顺序驱动（见上节）。
- **服务是常驻的，轮回结束时清的不是服务本身。** `TeardownCycle` 清的是 `CharacterProfile`、实例化的卡牌 / 敌人节点、服务内部的集合与静态字段——「防跨轮回残留」指的是这些，不是销毁服务。
- **边界靠纪律，不靠编译器——但已尽可能加固。** C# 无法阻止调用方绕过服务门面。已采取的加固：**manager 类型一律 `internal sealed`**（跨服务代码里写不出对方 manager 的类型名）、服务只暴露方法而不暴露 manager 引用（上例 `_profile` 为 `private`）、服务不返回内部可变集合。
- **边界服务可被替换为离线 stub。** `account-service` / `content-service` / `sync-service` 与 `future-event-service` 内的 `PlotManager` 各持一个窄后端接口（见上节），离线实现让整个游戏在**后端尚未存在**时先端到端跑起来。这对当前阶段（后端未开工）是关键的开发策略。
- **离线开关不可能悄无声息发到线上（已定案）。** 主闸是「Release 构建里离线实现根本不存在」而非任何一处配置——见上节。**否决过的路径：** 导出预设作主闸（配置会被漏配、被覆盖、被新建预设时忘记同步）、启动期断言作主闸（断言只在**跑到那一步**时生效，而离线包的症状恰恰是「一切正常」，正式包若没人在 release 模式下真跑一遍，断言等于不存在）。二者只作第 3 级兜底。
- **纪律该做到哪一级，有统一判据。** 「靠约定执行」的工程纪律按**违反它的代价**选级（写不出来 / 编译不过 / 大声失败 / 评审清单），判据与三处应用见 `systems/architecture.md`「纪律的可执行化」。

## 对应

- 运行时链路：`program-overview.md`
- 结构与边界权威：`systems/architecture.md`
- 服务清单与拆分轴：`systems/services/_index.md`
