# 标准 —— C# 约定（深入）

`.claude/rules/csharp-godot-rules.md` 的配套文档。规则文件是强制执行的摘要；本文是其推理与细节。

## 风格
- `PascalCase`：类型、方法、属性、公共字段、信号、`[Export]` 字段、枚举成员。
- `_camelCase`：私有/内部字段。局部变量用 `camelCase`。
- Godot C# API 采用 `PascalCase`（`_Ready`、`QueueFree`、`GetTree`）；与之保持一致。
- 派生自 Godot 类型的类必须为 `partial`（源生成器负责生成另一半）。
- 公共 API 优先使用显式类型；类型显而易见的局部变量用 `var` 即可。

## Godot 互操作
- `[Export]` 将字段暴露给检视面板——用于设计者可调的引用以及（少量）数值。内容数值应属于数据资源，而非按 node 导出。
- 场景内局部信号用 `[Signal] public delegate void FooEventHandler(...)`——这是 `[Signal]` 仅存的用武之地。**跨系统事件走 EventBus，而 EventBus 用 C# 泛型 `event` + `readonly record struct` 负载，不用 `[Signal]`**（`[Signal]` 的自定义负载须继承 `GodotObject` → 每次广播分配 + `Variant` 装箱）。见 `signal-eventbus.md`。
- 编组（Marshalling）：只有与 Godot Variant 兼容的类型才能干净地跨越 C#/引擎边界（int、float、string、bool、Godot 类型，以及由这些构成的数组/字典）。让 `[Signal]` 参数保持简单；传 id，而非富对象。EventBus 负载不经编组，但同样**只带 `Id` + 值类型**——不带 `CharacterProfile` / `Resource` / `EventOption` 引用。

## 性能
- `_Process`/`_PhysicsProcess` 是热点：不要每帧 `GetNode`、不要 LINQ、不要 `new`、不要字符串插值。在 `_Ready` 中缓存。
- 复用集合；用清空-重填代替重新分配。
- 用 `QueueFree` 释放实例化的 node；将不再拥有的缓存引用置空，以避免访问已释放对象。
- 若性能分析显示存在 GC 压力，对高频实例（卡牌、伤害数字）优先采用对象池。

## 异步 / 流程
- 避免 `async void`。引擎计时等待用 `await ToSignal(GetTree().CreateTimer(t), SceneTreeTimer.SignalName.Timeout)` 或动画/tween 信号。
- **服务方法的三种形态**（不许混用，见 `architecture.md`「API 契约总则」）：**A** 同步直返（纯内存 / 纯本地事务，**不带** `Async` 后缀）；**B** `Task<OpResult<T>>` + `CancellationToken`（跨客户端↔后端）；**C** `Task<T>` 由信号推进（跨多帧玩法长流程，内部 `await ToSignal(...)`）。**B / C 一律带 `Async` 后缀并返回 `Task`**——看签名即知是否跨边界。
- **autoload 的 `_Ready` 只装配，不做 I/O**（它不能 `await`）；异步初始化经 `IBootstrappable.InitializeAsync(ct)`，由 `BootstrapScreen` 按序驱动。**不要在 `_Ready` 里写 `async void` 做初始化**。
- **业务失败不抛异常** —— 付不起成本、网络不通、token 失效返回 `OpResult` / `ApplyResult`；只有「必需缺失 = 程序缺陷 / 坏数据」才 `GD.PushError` + `throw`。结果类型用 `readonly record struct`（核心循环每步产生，零堆分配）。
- 不要阻塞主线程；默认不存在独立的游戏线程。

## 可空性
- 在可行处启用可空引用类型，并在四个检查点（node 查找、resource 加载、集合查找、存档读取）遵守 `null-check-rules.md`。
