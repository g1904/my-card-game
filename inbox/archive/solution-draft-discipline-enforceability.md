---
type: solution-draft
date: 2026-08-09
question: 三条「靠约定执行」的工程纪律（离线后端开关不上线、抽取必走 AllEnabled()、EventBus 订阅必退订）如何在代码评审之外被机器强制？
source: open-questions/05-service-contracts.md → 第 1 / 3 / 4 条
targets:
  - system-overview.md（第四节「后端接口化」、第五节 ⚠ 条）
  - systems/architecture.md（总则 5 EventBus、总则 7 后端接口化；新增「纪律的可执行化」小节）
  - systems/services/content-service.md（统一操作接口签名、待决问题「AllEnabled() 纪律的可执行性」）
  - systems/common-properties.md（「内容共有字段 ContentEnabled」条的纪律措辞）
  - .claude/rules/data-resource-rules.md（`All()` 一句话纪律的措辞跟改）
status: distilled
reviewed-date: 2026-08-09
---

# 方案草稿 — 纪律的可执行化（三条约定 → 机器强制）

> **评审状态：已由用户裁决（2026-08-09），可供 `/analyze-new-ideas` 提炼。** 原「仍需用户决定」的四项与「与既有决策的张力」一项均已选定，选定结果就地写入各小节并汇总在文末「裁决记录」。**仍待答的只剩两条前置依赖**（`ContentEnabled` 分桶粒度、`#if DEBUG` 实测确认），二者都不阻塞本方案定稿——见「前置依赖」。

## 问题

`open-questions/05-service-contracts.md` 中有三条独立列出的待决项，它们其实是**同一个问题的三个实例**：

1. **`[Export] bool UseOfflineBackend` 的发布期防护。** 四个边界服务的离线 stub 开关默认 `true` 直到后端上线；正式包如何保证它不为 `true` 未定——**这是一个能悄无声息发到线上的开关**。
2. **`AllEnabled()` 纪律的可执行性。** 约定已立（抽取必走 `AllEnabled()`，漏写即线上事故），但代码评审之外如何强制未定。
3. **EventBus 退订纪律的可执行性。** 「`_Ready` 订阅 / `_ExitTree` 退订」是约定；漏退订即泄漏，且在 C# `event` 上**不会报任何错**。

三者的共同结构是：**正确的写法需要作者主动记得，错误的写法既不报错也不显眼**。三条都通不过「新人第一次写这段代码会不会写错」这一关。

因此本草稿先提出一条**统一的判据阶梯**，再用它分别给出三条的落地形态。

## 约束（来自既有设计）

- **七个服务在同一进程内，边界靠纪律不靠编译器。** 已采取的加固是 `internal sealed` manager + 不暴露 manager 引用 + 不返回可变集合。Source: `system-overview.md` 第五节、`systems/architecture.md` 总则 3。
- **「唯一入口」是本库反复出现的形态：** 内容读取唯一入口 `ContentRegistry`、档案写入唯一入口 `ProfileManager`、唯一物化点 `future-event-service`。Source: `systems/architecture.md`「两条唯一入口 + 一个编排顶点」。
- **「看签名即知语义」已是既定纪律：** 形态 B / C 带 `Async` 后缀、形态 A 不带。Source: `systems/architecture.md` 总则 1。
- **EventBus 是 autoload `Node`，「可在 `_ExitTree` 做泄漏检查」已被写进总则 5** —— 方向已埋，只差形态。Source: `systems/architecture.md` 总则 5。
- **热路径不分配、不做隐式装箱。** `CardResolved` 每张牌广播一次，`EventResolved` 核心循环每步一次。Source: `systems/common-properties.md`、`.claude/rules/csharp-godot-rules.md`。
- **无 CI 前提。** 维护者机器上 `node` / `docker` / `gh` 均不假定在 PATH；验证通过 Godot 编辑器构建完成，不做 CLI 编译检查。Source: `.claude/rules/environment-rules.md`。
- **客户端代码目前为空脚手架**（`game-feature-branch/` 只有 `project.godot` 与 `icon.svg`，尚无 `.csproj`、无一行 C#）。**三条纪律的落地成本此刻处于历史最低点**——没有存量调用方需要迁移。

---

## 建议方案

### 子项 0 — 先立一条判据：纪律可执行化阶梯

`[既有推演]`（把 `internal sealed` / `Async` 后缀 / 唯一入口这三处已有实践归纳成显式判据）

> **一条纪律该做到哪一级，取决于「违反它的代价」。**

| 级 | 手段 | 违反时 | 成本 |
|----|------|--------|------|
| **1 · 写不出来** | 类型 / 可见性 / 命名——错误的写法在语言层不存在或不合法 | 不可能发生 | 设计期一次性 |
| **2 · 编译不过** | `[Obsolete(error: true)]`、`#if` 条件编译、分析器 | 编译期报错 | 低～中 |
| **3 · 大声失败** | 启动期断言、切屏 / 退出期审计（一律 `#if DEBUG`） | 开发期 `PushError` | 低，但只在开发期生效 |
| **4 · 评审清单** | 文档条款 + 人工评审 | 靠人 | 零成本、零保证 |

**建议的选级判据（两条与门）：**

- **能上线且线上不可见 → 必须做到第 1 或第 2 级。** 判据是「这条纪律被违反后，测试期能不能被发现」。`UseOfflineBackend` 与 `AllEnabled()` 都属于「违反后游戏照常运行、错误只在真实玩家身上显形」，因此**第 3 级不够**。
- **只在开发期显形、且违反后会累积 → 第 3 级足够。** EventBus 泄漏属此类：它不改变玩法结果，只吃内存并制造幽灵订阅者；开发期能抓到即可。

**提炼位置已选定：`systems/architecture.md` 的新小节「纪律的可执行化」**，与八条 API 契约总则同层，作为总则 3 / 5 / 7 的共同上位判据。**不放 `.claude/rules/`**——它约束的是设计库里写下的契约形态（接口签名、开关形态），权威应在设计侧。它的价值在于：日后再出现「这条约定怎么强制」的问题时，不必逐条重新讨论。

---

### 子项 1 — `UseOfflineBackend`：单一选择点 + 条件编译删类

#### 1a. 先指出一处既有表述的技术互斥

`[既有推演]`

`system-overview.md` 第三节写「Godot 4 允许 autoload 直接指向 `.cs` 脚本，**无需为每个服务建空 `.tscn`**」；第四节又写开关是服务上的 `[Export] bool UseOfflineBackend`，「开发期切换不需要重编译」。

**这两条互斥。** autoload 指向 `.cs` 时，Godot 直接实例化该脚本，**不存在场景实例，因而没有 `[Export]` 值的存储处，检视器里也无从编辑**——运行时拿到的永远是字段的默认值 `true`。「不重编译就能切换」在当前形态下**已经不成立**。

也就是说：这个开关不但发布期无防护，**开发期也不好用**。建议一并修掉。

#### 1b. 建议形态：一个 `BackendSelector`，四个服务不各自持开关

`[既有推演]`（「唯一入口」纪律的直接延续）

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
}
```

**理由：四个字段 = 四个可能各自出错的点，而最糟的失败态是「三个开了一个没开」的半在线状态**——它比全离线更难诊断（登录成功、内容加载正常，只有存档静默写进内存回显）。收敛成一个选择点后，这个失败态在结构上不存在。

这与 ContentRegistry / ProfileManager / future-event-service 三处「唯一入口」是同一条纪律。

#### 1c. 主闸（第 1 级）：Release 构建里离线实现根本不存在

`[通行做法]` + `[既有推演]`

四个 `OfflineXxxBackend` 类整体包在 `#if DEBUG` 内：

```csharp
// src/Services/Account/OfflineAccountBackend.cs
#if DEBUG
internal sealed class OfflineAccountBackend : IAccountBackend { /* ... */ }
#endif
```

**这把问题从「开关会不会配错」降级为「类型存不存在」**——Release 构建下写不出对离线实现的引用，配错开关连编译都不通过。这是阶梯第 1 级，也是唯一能真正兑现「不可能悄无声息发到线上」的做法。

配套代价（如实）：`BackendSelector` 与四个 backend 文件需要 `#if DEBUG`，共 5 处条件编译。**建议把条件编译严格限制在这 5 个位置**——服务内部一律只见 `IXxxBackend` 接口，绝不出现第二处 `#if`。这正是总则 7「离线 stub 是换一个实现，不是插 `if (offline)`」的延伸：不插 `if`，也不插 `#if`。

> **判据说明：** Godot 的 .NET 集成在 Release 导出配置下不定义 `DEBUG`；编辑器内运行与 Debug 导出定义。`#if DEBUG` 因此天然对齐「导出预设的 Release / Debug 维度」，不需要自定义常量。**这条需在项目首次生成 `.csproj` 后实测确认一次**（当前尚无 `.csproj`），若不成立则改用显式的 `<DefineConstants>MYCARDGAME_OFFLINE_OK</DefineConstants>` 自定义常量，形态不变。

#### 1d. 开发期开关载体（第 3 级兜底）：ProjectSettings 自定义项 —— **已选定**

`[通行做法]` · **用户已选定 A：采用 ProjectSettings，`[Export] bool UseOfflineBackend` 这一表述作废。**

```
mycardgame/backend/use_offline_backend = true        # project.godot，进版本控制、可 diff
```

```csharp
private static bool UseOffline =>
    (bool)ProjectSettings.GetSetting("mycardgame/backend/use_offline_backend", true);
```

替代 `[Export]`，理由三条：① autoload 指向 `.cs` 时 `[Export]` 无落点（见 1a）；② 值落在 `project.godot` 里，**进版本控制、可 diff、可在评审中看见**，而 `.tscn` 里的 `[Export]` 值同样可 diff 但要为此建四个空场景；③ Godot 的 ProjectSettings 原生支持 **feature tag override**（`mycardgame/backend/use_offline_backend.release`），这就是「导出预设维度覆盖」这一候选答案的原生实现，但**只作为第 3 级兜底**——主闸仍是 1c。

#### 1e. 启动期审计（第 3 级）

Bootstrap 屏幕在驱动 `InitializeAsync` 之前打一行**必然出现在日志顶部**的横幅：

```csharp
GD.Print($"[Bootstrap-Backends] offline={BackendSelector.IsOffline} build={(OS.IsDebugBuild() ? "debug" : "release")}");
if (!OS.IsDebugBuild() && BackendSelector.IsOffline)
{
    GD.PushError("[Bootstrap-Backends] offline backend in release build");
    throw new InvalidOperationException("Offline backend must not ship");
}
```

若 1c 生效，这个 `throw` 是恒不可达的——**保留它是为了防「1c 的条件编译常量哪天被改错」**，成本一行。「必需缺失 → `PushError` + `throw`」符合总则 2。

---

### 子项 2 — `AllEnabled()`：删掉中性诱饵名 `All()`

#### 2a. 两个显式名，**没有中性名** —— **已选定**

`[既有推演]`（「看签名即知语义、不留中性名」，与 `Async` 后缀同构）· **用户已选定 A：删除 `All()`，只留 `AllEnabled()` + `AllIncludingDisabled()`。**

```csharp
public interface IContentRepository<T> where T : Resource
{
    T                Get(string id);                    // 读取侧：不过滤（存档引用可解析）
    bool             TryGet(string id, out T v);
    IReadOnlyList<T> AllEnabled();                      // 抽取池：ContentEnabled == true
    IReadOnlyList<T> AllIncludingDisabled();            // 全量：仅校验 / 调试 / 图鉴统计
    IEnumerable<T>   Where(Func<T, bool> predicate);    // ⚠ 见 2c
}
```

**关键在于删除 `All()` 本身，而不只是给它改名。** 漏写过滤这个错误的发生机制是「随手写了那个最短、最中性、看起来最无害的名字」。只要 `All()` 还在，它就是诱饵；两个名字都带修饰语时，作者**必须在两种语义之间做一次显式选择**，写下 `AllIncludingDisabled()` 的人不可能声称自己没意识到有 disabled 条目这回事。

对比另一条路（`All()` 保留但语义改为 enabled-only + `AllIncludingDisabled()`）：最短路径确实安全了，但 `All` 会撒谎——一个叫 `All` 却不返回全部的方法，是下一个 bug 的温床。**建议否决，理由是命名诚实性**（见「备选方案」）。

#### 2b. 过渡期硬闸（第 2 级）：把 `All()` 留成编译期错误

`[通行做法]`

```csharp
[Obsolete("抽取走 AllEnabled()；确需含已关闭条目走 AllIncludingDisabled()。", error: true)]
public IReadOnlyList<T> All() => throw new NotSupportedException();
```

成本是一个方法 + 一个特性，收益是**任何出于惯性写下 `All()` 的代码（包括 AI 生成的）当场编译失败并被指路**。建议保留至少到内容阶段结束。

**这条同时是「Roslyn 分析器」这一候选的替代答案**：分析器要单独建项目、随 Godot 生成的 `.csproj` 走容易被覆盖、在无 CI 的前提下只能靠本机构建生效——而 `[Obsolete(error: true)]` 拿到的是同一份编译期保证，成本低几个数量级。建议**否决分析器**。

#### 2c. 抽取池独立为一个类型（第 1 级）—— **已采纳，排入第二阶段**

`[既有推演]` · **用户已裁决：采纳，但排到第二阶段（内容）开工前落地**，本阶段不改 `AllEnabled()` 的返回类型。

2a + 2b 让「漏写过滤」变得极难，但仍未做到不可能：`Where(...)` 或 `AllIncludingDisabled()` 的结果照样能被拿去抽取。若要做到第 1 级：

```csharp
public readonly struct DrawPool<T> where T : Resource   // 薄包装，零堆分配
{
    private readonly IReadOnlyList<T> _items;
    public T       PickOne(RandomNumberGenerator rng);
    public IReadOnlyList<T> PickMany(RandomNumberGenerator rng, int count);
    public DrawPool<T> Filter(Func<T, bool> predicate);  // 过滤后仍是 DrawPool
}
```

`AllEnabled()` 的返回类型改为 `DrawPool<T>`，而**带 seeded RNG 的抽取方法只定义在 `DrawPool<T>` 上**。于是「从内容集合抽取」这个动作在语言层只能从抽取池发起——`AllIncludingDisabled()` 返回的 `IReadOnlyList<T>` 上根本没有 `PickOne`。

- **收益：** 把本库自评为「漏写即线上事故」的动作提到阶梯第 1 级；顺带给 seeded 抽取一个统一落点（当前抽取逻辑散在 future-event-service 物化、商店库存、奖励掷骰三处）。
- **代价：** 多一个共享核心类型；`AllEnabled()` 的返回类型不再是 `IReadOnlyList<T>`，需要看全集的调用方多写一次 `.Filter(...)` 或换用 `AllIncludingDisabled()`。
- **延后风险低**：`DrawPool<T>` 是纯加法改造，`AllEnabled()` 换返回类型时受影响的只有抽取侧三处。

**排期依据（已裁决）：** 排在第二阶段（内容）开工前——彼时三个抽取侧（future-event-service 物化、商店库存、奖励掷骰）都已有真实调用方，能验证 `PickOne` / `PickMany` 的形状是否够用；此刻定死形状是纸上设计。**这同时避开了唯一的前置依赖**（`ContentEnabled` 分桶粒度未定，见「前置依赖」）——届时分桶若已答定，`DrawPool<T>` 可一次性带上正确的构造签名。

**排期的具体落点建议：** 在第二阶段开工的**第一份 FR** 之前完成 2c 改造，而非与内容 FR 并行——一旦三个抽取侧写完再改返回类型，就从「纯加法」退化为「改调用方」。

---

### 子项 3 — EventBus 退订：调试期订阅审计

#### 3a. 定级：第 3 级足够

`[既有推演]`

漏退订**不改变玩法结果**（幽灵订阅者收到的是既成事实广播，不可否决——总则 5 第 3 条），只吃内存并可能对已 `QueueFree` 的节点调方法。它在**开发期即可显形**，不属于「上线且线上不可见」那一类，因此按子项 0 的判据**第 3 级足够，不必付第 1 / 2 级的成本**。

这也与总则 5 已埋的伏笔一致：「EventBus 仍是 autoload `Node`（留在场景树里、**可在 `_ExitTree` 做泄漏检查**）」——方向早已选定，本节只补形态。

#### 3b. 建议形态：`#if DEBUG` 的订阅审计

`[通行做法]`

C# `event` 的 `GetInvocationList()` 可枚举全部订阅者。审计逻辑：

```csharp
#if DEBUG
private void AuditOne(string eventName, Delegate handler)
{
    foreach (var d in handler.GetInvocationList())
    {
        if (d.Target is GodotObject go && !GodotObject.IsInstanceValid(go))
            GD.PushError($"[EventBus-Audit] leaked subscriber event={eventName} " +
                         $"handler={d.Method.DeclaringType?.Name}.{d.Method.Name}");
    }
}
#endif
```

**关键细节：定位信息取自 `d.Method`，不取自 `d.Target`。** 泄漏发生时目标实例已被释放，`Target.ToString()` 拿不到有用信息；而 `Method.DeclaringType.Name + "." + Method.Name` 是反射元数据，**不依赖实例存活**，直接给出 `CombatScreen.OnCardResolved` 这样可定位的名字。因此**不需要**在订阅时额外登记来源，`+=` 的惯用订阅形态原样保留。

#### 3c. 触发时机：切屏后，而非 `_ExitTree`

`[既有推演]`

| 时机 | 建议 | 理由 |
|------|------|------|
| **每次屏幕切换完成后**（由编排顶点 game-progression 调一次） | ✅ **主时机** | 屏幕场景是订阅者的绝大多数，切屏正是它们被释放的边界；频率 = 每次切屏一次，**零热路径成本** |
| 每次 `Emit` 时顺带检查 | ❌ 否决 | `CardResolved` 在战斗热路径，`GetInvocationList()` 每次分配一个数组——直接撞「热路径不分配」 |
| EventBus 自己的 `_ExitTree` | ⚠ 降级 | 此时七个 autoload 服务可能正在同步销毁，`IsInstanceValid` 会对它们误报。**建议 `_ExitTree` 只打印一条订阅计数摘要，不做泄漏判定** |

> **推论（值得写进纪律）：** 泄漏检查**豁免 autoload 服务的订阅**——服务与游戏同生命周期，它们的订阅按定义不是泄漏。用 `IsInstanceValid` 作判据在切屏时机天然满足这一点（服务此刻当然有效）；这也是必须避开 `_ExitTree` 判定的原因。

#### 3d. 配套：`_ExitTree` 摘要

```csharp
public override void _ExitTree()
{
    GD.Print($"[EventBus-Exit] subscribers total={_debugSubscriberCount}");
}
```

一行摘要，提供「退出时还挂着几个」的粗粒度体感，不做判定、不报错。

---

## 具体形态（可 derive 的落地面）

### 改动清单

| # | 位置 | 改动 | 阶梯级 |
|---|------|------|--------|
| 1 | `src/Core/BackendSelector.cs`（新增） | 四个 `CreateXxx()`，后端实现的唯一选择点 | 1 |
| 2 | 四个 `OfflineXxxBackend.cs` | 整类包 `#if DEBUG` | 1 |
| 3 | 四个边界服务 | **移除** `[Export] bool UseOfflineBackend`，改调 `BackendSelector` | — |
| 4 | `project.godot` | 新增 `mycardgame/backend/use_offline_backend`（bool，默认 `true`） | 3 |
| 5 | `BootstrapScreen` | 后端选择横幅日志 + release×offline 断言 | 3 |
| 6 | `IContentRepository<T>` | **删除** `All()`；新增 `AllIncludingDisabled()`；保留 `AllEnabled()` | 1 |
| 7 | `IContentRepository<T>` | 过渡期 `[Obsolete(error: true)] All()` 占位 | 2 |
| 9 | `EventBus` | `#if DEBUG` 订阅审计 `AuditSubscribers()` | 3 |
| 10 | `game-progression` | 切屏完成后调一次 `AuditSubscribers()` | 3 |

**第二阶段（内容）开工前的一项：**

| # | 位置 | 改动 | 阶梯级 |
|---|------|------|--------|
| 8 | `IContentRepository<T>` + `src/Core/DrawPool.cs` | `AllEnabled()` 返回类型改为 `DrawPool<T>`；seeded 抽取方法只定义在其上 | 1 |

### `IContentRepository<T>` 本阶段定稿签名（第 8 项落地前）

```csharp
public interface IContentRepository<T> where T : Resource
{
    T                Get(string id);                 // 必需：缺失 → PushError + throw；不过滤 ContentEnabled
    bool             TryGet(string id, out T v);     // 可选：缺失 → PushWarning，调用方降级
    IReadOnlyList<T> AllEnabled();                   // 抽取池：ContentEnabled == true。产出侧唯一取池入口
    IReadOnlyList<T> AllIncludingDisabled();         // 全量：启动期校验 / 图鉴统计 / 调试
    IEnumerable<T>   Where(Func<T, bool> predicate); // 不过滤；调用方自负

    [Obsolete("抽取走 AllEnabled()；确需含已关闭条目走 AllIncludingDisabled()。", error: true)]
    IReadOnlyList<T> All();                          // 过渡期编译闸，恒抛
}
```

> **合并后强校验走 `AllIncludingDisabled()`**——disabled 条目照常参与 `Id` 唯一性与交叉引用校验（既有决策，见 `content-service.md`）。这条正是 `AllIncludingDisabled()` 的第一个正当调用方，它的存在使「两个显式名」不是多余的对称。

### 条件编译使用清单（穷举，不得扩张）

| 文件 | 符号 |
|------|------|
| `src/Core/BackendSelector.cs` | `DEBUG` |
| `src/Services/{Account,Content,Sync,FutureEvent}/Offline*Backend.cs` | `DEBUG` |
| `src/Autoload/EventBus.cs`（审计块） | `DEBUG` |

**共 6 处，是全部。** 服务与 manager 内部一律不得出现 `#if`——总则 7「换实现而非插 `if`」在条件编译上同样成立。

---

## 后果

- **`system-overview.md` 第四节与第五节须改写：** `[Export] bool UseOfflineBackend` 的描述作废（技术上不成立，见 1a），换成 `BackendSelector` + ProjectSettings + `#if DEBUG`；第五节的 ⚠ 条从「未定」改为「已定案」。
- **`systems/architecture.md` 总则 7 须改写**开关形态；总则 5 补上审计形态；新增「纪律的可执行化」小节（子项 0）。
- **`content-service.md` 的「统一操作接口」代码块与 API 面表须改写**（`All()` → `AllIncludingDisabled()`），并把「`AllEnabled()` 纪律的可执行性」从待决问题移出。
- **`systems/common-properties.md`** 的 `ContentEnabled` 条与 API 契约总则摘要须跟改一句措辞。
- **`.claude/rules/data-resource-rules.md`** 现有一句「不要自己写 `All().Where(x => x.ContentEnabled)`，用 `AllEnabled()`」需跟改——`All()` 届时已不存在。（属工程规则层，由 `/analyze-new-ideas` 判断是否同步落笔。）
- **不影响存档 schema、不影响后端协议、不影响任何玩法语义。** 三条改动全在客户端工程形态层，无迁移成本。
- **落地成本此刻近乎为零**：无一行存量 C# 代码需要迁移。同样的改动在内容阶段做，代价是改所有抽取侧调用方。

## 备选方案（已考虑并否决）

- **`All()` 保留但语义改为 enabled-only + `AllIncludingDisabled()`。** 最短路径确实安全，但一个叫 `All` 却不返回全部的方法会撒谎——**用错误的名字换安全，只是把 bug 挪到未来**（谁读到 `All()` 都会以为拿到了全集，比如写图鉴统计时）。
- **Roslyn 分析器强制 `AllEnabled()`。** 否决：单独项目要维护、随 Godot 生成的 `.csproj` 走易被覆盖、无 CI 前提下只在本机构建生效；而 `[Obsolete(error: true)]` 拿到同一份编译期保证，成本低几个数量级。
- **导出预设作为 `UseOfflineBackend` 的唯一防护。** 否决作为**主**闸：导出预设是配置，配置会被漏配、被覆盖、被新建预设时忘记同步；它只能是第 3 级。作为 ProjectSettings feature override 的兜底保留。
- **启动期断言作为 `UseOfflineBackend` 的唯一防护。** 否决：断言只在**跑到那一步**时生效——而离线包的症状恰恰是「一切正常」，正式包若没人在 release 模式下真跑一遍，断言等于不存在。
- **EventBus 改为 `Subscribe(...)` 返回 `IDisposable` + `SubscriptionBag`。** 否决：会把 C# `event` 换成方法对，失去 `+=` / `-=` 的惯用性与编译器生成的线程安全访问器，而收益仅是「少写一行 `-=`」。
- **为订阅方提供一个 `EventBusSubscriber` 基类自动退订。** 否决：C# 单继承，屏幕脚本已需继承 `Control` / `Node2D` 等 Godot 基类，塞一个纪律基类会污染整条继承链。
- **每次 `Emit` 顺带做泄漏检查。** 否决：`GetInvocationList()` 每次分配数组，`CardResolved` 在战斗热路径上——直接撞既定的「热路径不分配」。

## 与既有决策的张力

**一处，已裁决（2026-08-09）。**

`system-overview.md` 同时写着两条互斥的表述（详见子项 1a）：

- **(甲)** 「Godot 4 允许 autoload 直接指向 `.cs` 脚本，无需为每个服务建空 `.tscn`」；
- **(乙)** 「由服务上的 `[Export] bool UseOfflineBackend`（默认 `true`）选择——开发期切换不需要重编译」。

autoload 指向 `.cs` 时没有场景实例，`[Export]` 无存储处也无检视器落点，(乙) 不成立。必须松动其一：

| 松动 | 代价 |
|------|------|
| **松动 (乙)，开关改 ProjectSettings** ← **已选定** | `[Export]` 这一表述作废；换来开关值落在 `project.godot`（可 diff、可评审）且原生支持 feature override |
| 松动 (甲)，为四个边界服务各建一个空 `.tscn` | 四个空场景纯为承载一个 bool；autoload 表变成 `.cs` / `.tscn` 混合形态，与「服务形态统一」相悖 |

**裁决：松动 (乙)，(甲) 保持不动。** 理由：`[Export]` 的价值本是「设计师在检视器里调数值」（见 `.claude/rules/csharp-godot-rules.md`），而这个开关的读者是工程师而非设计师，检视器并非它的正确落点。

**因此 (甲)「autoload 直接指向 `.cs`，无需为每个服务建空 `.tscn`」升为一条无例外的约定**——七个服务的 autoload 形态统一，不再有「为承载配置而建空场景」这条后门。**推论：日后任何服务级配置项都走 ProjectSettings，不走 `[Export]`；`[Export]` 保留给真正的场景组件（卡牌、敌人、UI 控件）。**

## 前置依赖

- **`ContentEnabled` 的粒度是否够用**（`content-service.md` 待决问题：灰度 / 分批放量需按玩家分桶，布尔字段不携带分桶信息）。**影响面限于已排期到第二阶段的子项 2c**：若届时抽取池要按分桶裁剪，`DrawPool<T>` 的构造签名会变成 `AllEnabled(bucketContext)` 一类形态。**子项 2a / 2b（命名改造 + `Obsolete` 闸）不受此依赖影响，本阶段即可定稿**——这也是 2c 排期到第二阶段的第二个理由：那时分桶问题大概率已答定，`DrawPool<T>` 可一次成型。
- 子项 1c 的 `#if DEBUG` 判据需在项目首次生成 `.csproj` 后**实测确认一次**（当前 `game-feature-branch/` 尚无 `.csproj`）。若 Godot 的 Release 导出配置未如预期取消定义 `DEBUG`，改用自定义 `<DefineConstants>`，**方案形态不变**。

## 裁决记录（2026-08-09 · 用户选定）

| # | 决定项 | 选定 | 落在本文档何处 |
|---|--------|------|----------------|
| 1 | `All()` 的处置 | **删除 `All()`**，只留 `AllEnabled()` + `AllIncludingDisabled()`；过渡期以 `[Obsolete(error: true)]` 占位 | 子项 2a / 2b、改动清单 6–7 |
| 2 | `DrawPool<T>` 类型层加固 | **采纳**，排到**第二阶段（内容）开工前**、第一份内容 FR 之前落地；本阶段 `AllEnabled()` 仍返回 `IReadOnlyList<T>` | 子项 2c、改动清单第 8 项 |
| 3 | `UseOfflineBackend` 开关载体 | **ProjectSettings 自定义项**；`[Export] bool UseOfflineBackend` 这一表述**作废**，(甲)「autoload 直接指向 `.cs`」升为无例外约定 | 子项 1d、「与既有决策的张力」 |
| 4 | 「纪律可执行化阶梯」提炼位置 | **`systems/architecture.md` 新小节「纪律的可执行化」**，与八条 API 契约总则同层 | 子项 0 |

**四项均为「就地收敛」，不改变本方案的任何技术形态**——它们各自的落选分支在「备选方案」与「与既有决策的张力」中保留了否决理由，供日后回溯。

## 提炼落点（供 `/analyze-new-ideas`）

| 目标文档 | 该写什么 | 该删什么 |
|----------|----------|----------|
| `systems/architecture.md` | 新小节「纪律的可执行化」（子项 0 的四级阶梯 + 两条选级判据）；总则 5 补 EventBus 审计形态与切屏时机；总则 7 的开关形态改为 `BackendSelector` + ProjectSettings + `#if DEBUG` | 待决问题「EventBus 退订纪律的可执行性」整条；总则 7 中 `[Export] bool UseOfflineBackend` 一句 |
| `system-overview.md` | 第四节「后端接口化」改写为 `BackendSelector` 唯一选择点 + 条件编译删类 + ProjectSettings；第三节 (甲) 升为无例外约定 | 第五节 ⚠ 条（「能悄无声息发到线上的开关」）整条 |
| `systems/services/content-service.md` | 「统一操作接口」代码块与 API 面表改为新签名（`AllEnabled()` / `AllIncludingDisabled()` / `Obsolete` 闸）；`DrawPool<T>` 作为第二阶段前置项记一句 | 待决问题「`AllEnabled()` 纪律的可执行性」整条 |
| `systems/common-properties.md` | `ContentEnabled` 条与「API 契约总则（摘要）」的措辞跟改：抽取走 `AllEnabled()`，全量走 `AllIncludingDisabled()` | — |
| `open-questions/05-service-contracts.md` | — | 三条（`UseOfflineBackend` 防护 / EventBus 退订可执行性 / `AllEnabled()` 可执行性）整体移出 |
| `.claude/rules/data-resource-rules.md` | 「不要自己写 `All().Where(...)`」一句跟改——`All()` 届时已不存在 | — |

> **归档提示：** 本方案未新增 ADR。子项 0 的阶梯若日后被反复引用，可作为 ADR 候选记在 `systems/architecture.md` 的「决策(-> ADR)」小节，与既有的「API 契约总则」ADR 候选并列。
