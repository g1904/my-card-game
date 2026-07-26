# system-overview —— 项目结构与落地形态

> **这份文档回答「这些服务在 Godot 工程里长什么样」。** 进程边界、文件夹布局、autoload 注册、service / manager 的代码形态。
>
> 「代码怎么跑起来」的端到端运行链路见 `program-overview.md`；结构与边界的**权威**在 `20-systems/architecture.md`。
> Source: `10-handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md`。

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
│   ├── Core/                         ← 核心「类」（纯数据对象，非 Node）
│   │   ├── PlayerProfile.cs          ← ⊃ List<CharacterProfile>
│   │   ├── CharacterProfile.cs
│   │   ├── CostSpec.cs  RewardSpec.cs  CostElement.cs
│   │   └── CapabilityFlag.cs
│   ├── Data/                         ← XxxData : Resource 定义
│   │   ├── AdventureEventData.cs
│   │   ├── CardData.cs  EnemyData.cs  ItemData.cs  PlayerPowerData.cs
│   ├── Services/                     ← 一个文件夹 = 一个服务及其全部 manager
│   │   ├── Account/
│   │   │   ├── AccountService.cs         ← Node（autoload）
│   │   │   ├── AuthManager.cs            ← 普通 C# 类
│   │   │   └── ComplianceManager.cs
│   │   ├── Content/
│   │   │   ├── ContentService.cs
│   │   │   ├── ContentRegistry.cs
│   │   │   ├── ContentUpdateManager.cs
│   │   │   └── IContentRepository.cs
│   │   ├── Sync/
│   │   │   ├── SyncService.cs
│   │   │   ├── ProfileSyncManager.cs  LocalCacheManager.cs  MigrationManager.cs
│   │   ├── Profile/
│   │   │   ├── ProfileService.cs
│   │   │   ├── ProfileManager.cs  CapabilityManager.cs  AchievementManager.cs
│   │   ├── LifeCycle/
│   │   │   ├── LifeCycleService.cs
│   │   │   ├── RunStateManager.cs  ChapterManager.cs  SeedManager.cs
│   │   ├── FutureEvent/
│   │   │   ├── FutureEventService.cs
│   │   │   ├── EventOptionManager.cs  PlotManager.cs
│   │   └── Combat/
│   │       ├── CombatService.cs
│   │       ├── TurnManager.cs  DeckManager.cs  IntentManager.cs
│   ├── Progression/
│   │   └── GameProgression.cs        ← 编排顶点
│   └── UI/
│       └── ViewModels/
│
├── scenes/                           ← .tscn
│   ├── screens/     LoginScreen  MainMenu  EventMenu  CombatScreen
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

    // ── 对外 API 面（其他服务只看得见这些）──
    public ApplyResult TryApply(CostSpec spec)   => _profile.TryApply(spec);
    public bool CanAfford(CostSpec spec)         => _profile.CanAfford(spec);
    public bool Has(CapabilityFlag flag)         => _capability.Has(flag);
    public int  Apply(string key, int baseValue) => _capability.ApplyModifier(key, baseValue);
}
```

### 管理器（普通 C# 类，**不是** `Node`）

```csharp
// src/Services/Profile/ProfileManager.cs
using Godot;

public sealed class ProfileManager
{
    private readonly ProfileService _host;   // 同服务内可互相访问
    private PlayerProfile _profile;          // ⊃ List<CharacterProfile>

    public ProfileManager(ProfileService host) => _host = host;

    public ApplyResult TryApply(CostSpec spec)
    {
        // 1) 全量校验：modifier pipeline 在读数值时生效
        foreach (var e in spec.Elements)
        {
            int cost = _host.Apply(e.Key, e.BaseValue);
            if (!CanPay(e, cost))
            {
                GD.PushWarning($"[ProfileManager-TryApply] insufficient, element={e.Key}");
                return ApplyResult.Fail(e.Key);   // 全有或全无，未写任何字段
            }
        }
        // 2) 一次性提交
        foreach (var e in spec.Elements) Pay(e, _host.Apply(e.Key, e.BaseValue));
        return ApplyResult.Ok();
    }
}
```

### 跨服务调用：只经对方的服务门面

```csharp
// src/Services/LifeCycle/LifeCycleService.cs
public void AdvanceEvent(CharacterProfile character, AdventureEventData evt, AdvanceMode mode)
{
    var spec = mode == AdvanceMode.Skip ? evt.SkipCost : evt.SelectCost;

    var result = ProfileService.Instance.TryApply(spec);    // ✅ 服务门面
    // var result = ProfileService.Instance._profile...      // ❌ 伸手进 manager
    if (!result.Success) return;

    GD.Print($"[LifeCycle-AdvanceEvent] start id={evt.Id} mode={mode}");
    // ...
}
```

---

## 五、实践后果

- **启动顺序 = autoload 声明顺序。** `ContentService` 必须排在一切依赖内容的服务之前；`AccountService` 排在 `SyncService` 之前（后者需要 token）。这是唯一需要人工维护的依赖声明。
- **服务是常驻的，run 结束时清的不是服务本身。** `TeardownRun` 清的是 `CharacterProfile`、实例化的卡牌 / 敌人节点、服务内部的集合与静态字段——「防跨 run 残留」指的是这些，不是销毁服务。
- **边界靠纪律，不靠编译器。** C# 无法阻止调用方绕过服务门面。可做的加固：manager 类型不设为 `public`（用 `internal`）、服务只暴露方法而不暴露 manager 引用（如上例 `_profile` 为 `private`）。
- **边界服务可被替换为离线 stub。** `account-service` / `content-service` / `sync-service` 是纯边界门面，可提供「离线假实现」让整个游戏在**后端尚未存在**时先端到端跑起来。这对当前阶段（后端未开工）是关键的开发策略。

## 对应

- 运行时链路：`program-overview.md`
- 结构与边界权威：`20-systems/architecture.md`
- 服务清单与拆分轴：`20-systems/services/_index.md`
