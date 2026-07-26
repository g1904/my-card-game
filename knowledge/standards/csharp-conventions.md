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
- 场景内局部信号用 `[Signal] public delegate void FooEventHandler(...)`；跨系统事件走 EventBus。
- 编组（Marshalling）：只有与 Godot Variant 兼容的类型才能干净地跨越 C#/引擎边界（int、float、string、bool、Godot 类型，以及由这些构成的数组/字典）。让信号参数保持简单；跨总线传递 id，而非富对象。

## 性能
- `_Process`/`_PhysicsProcess` 是热点：不要每帧 `GetNode`、不要 LINQ、不要 `new`、不要字符串插值。在 `_Ready` 中缓存。
- 复用集合；用清空-重填代替重新分配。
- 用 `QueueFree` 释放实例化的 node；将不再拥有的缓存引用置空，以避免访问已释放对象。
- 若性能分析显示存在 GC 压力，对高频实例（卡牌、伤害数字）优先采用对象池。

## 异步 / 流程
- 避免 `async void`。引擎计时等待用 `await ToSignal(GetTree().CreateTimer(t), SceneTreeTimer.SignalName.Timeout)` 或动画/tween 信号。
- 不要阻塞主线程；默认不存在独立的游戏线程。

## 可空性
- 在可行处启用可空引用类型，并在四个检查点（node 查找、resource 加载、集合查找、存档读取）遵守 `null-check-rules.md`。
