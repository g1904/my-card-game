# C# ↔ Godot 规则

附着在 Godot 节点上的 C# 脚本的约定。深入配套文档：`.claude/knowledge/standards/csharp-conventions.md`。

## 命名与结构
- 类、方法、属性、信号和导出字段使用 `PascalCase`。私有字段使用 `_camelCase`。与 Godot 的 C# API 大小写保持一致（`_Ready`、`_Process`、`QueueFree`）。
- 每个文件一个主节点脚本；类名与文件名以及（通常）它所驱动的节点一致。
- 对设计师应在检视器（inspector）中调整的值使用 `[Export]`（属性、速度、prefab 引用）。不要硬编码平衡数值 —— 那些属于数据资源（参见 `data-resource-rules.md`）。
- 优先使用 `partial class Foo : Node`（Godot 4 的源生成器要求 `partial`）。

## 节点访问
- 在 `_Ready` 中**一次性**解析子节点并缓存到字段。绝不每帧调用 `GetNode`。
- 优先使用 `GetNodeOrNull<T>(...)` + 显式的 null 检查，而非 `GetNode<T>`（参见 `null-check-rules.md`）。对场景唯一（scene-unique）的节点使用 `%UniqueName`。
- 绝不用冗长的 `../../` 链来构造路径 —— 使用唯一名、分组或导出的 `NodePath`/节点引用。

## 生命周期与性能
- 在 `_Process` / `_PhysicsProcess` 热路径中不做分配、不用 LINQ、不做 `string` 拼接。预先计算并复用缓冲区/集合。
- 有意识地断开信号并释放自己拥有的节点（`QueueFree`）；不要在多个轮回之间泄漏实例化的卡牌/敌人。
- 避免 `async void`（除了确实需要它的顶层事件处理器）。对 Godot 流程的异步优先使用信号/`await ToSignal(...)`。
- 在物理/信号回调期间改动场景树时使用 `CallDeferred`。

## 信号 vs 直接调用
- 场景内父→子：直接方法调用没问题。
- 跨系统 / 解耦的事件（轮回事件、遭遇战结果、货币变动）：走 **EventBus** 自动加载，而非直接引用。参见 `game-design-documents/systems/architecture.md` 的「总则 5 —— EventBus」。
- **一致地**连接信号 —— 每个场景选定代码连接或编辑器连接，不要任意混用。
