# 标准 —— 信号与 EventBus（引用层）

`.claude/rules/csharp-godot-rules.md`（信号章节）的配套。**权威：`game-design-documents/systems/architecture.md`**「总则 5」与「EventBus 负载契约」——**事件清单、负载 schema、`Emit` 代码形状去那边看**，此处不复制。

## 何时用什么

| 场合 | 用什么 |
|------|--------|
| 父级驱动自身子级、场景内紧耦合 node | **直接方法调用**（默认） |
| 跨服务、需要返回值 | **直接方法调用** `Xxx.Instance.Method(...)` |
| 子级通知其父 / 所有者，不知道谁在听（`Card` 发 `Played`） | **局部 `[Signal]`**，限场景边界内 |
| 跨系统、跨场景的**既成事实**广播 | **EventBus autoload** |

## 承重纪律

1. **EventBus 用 C# 泛型 `event` + `readonly record struct` 负载，不用 Godot `[Signal]`。** `[Signal]` 的自定义负载须继承 `GodotObject` → 每次广播分配一个引用对象 + `Variant` 装箱，直接撞上「不做隐式装箱」与「热路径不分配」；而核心循环每步广播 `EventResolved`、战斗内每张牌广播 `CardResolved`。EventBus 本身仍是 autoload `Node`（留在场景树里、可做泄漏检查）。
2. **负载只带 `Id` + 值类型** ——绝不带 `CharacterProfile` / `Resource` / `EventOption` 引用。传引用等于给每个订阅者开一条绕过唯一写入入口的旁路，也让定稿实例有被下游改写的可能。需要完整实例的订阅者按 `InstanceId` 去 future-event-service 取。
3. **`_Ready` 订阅、`_ExitTree` 退订。** C# 事件上漏退订**不会报错**，直接变成泄漏（且让已释放的 node 被回调）。兜底是 EventBus 的 `#if DEBUG` 订阅审计（切屏后由 game-progression 触发一次，豁免 autoload 订阅）——**它只在开发期生效，不替代退订**。
4. **广播 = 既成事实，不可否决。** EventBus 不承载「请求 / 询问」；需要返回值的一律是直接方法调用。
5. **事件命名为过去时的事实**：`CycleStarted`、`EventResolved`、`CardResolved`、`CapabilitiesChanged`。命名为事实而非指令，正是这条纪律的体现。
6. **`CapabilitiesChanged` 空负载** ——订阅者收到后自行 `ProfileService.Instance.Has(flag)` 重查。把生效集塞进负载会制造第二份真值。

**代价（已接受）：** GDScript 与编辑器信号面板订阅不了 EventBus——本项目纯 C#，不构成损失。若日后确需编辑器可视化连接，可为少数低频事件**额外**挂 `[Signal]`，但不作为主通道。

## 陷阱

- **顺序：** 不要假设订阅者的执行顺序。若顺序重要（PlayerPower 触发优先级），显式建模成一份解析出的优先级列表，而不是依赖订阅顺序。
- **反馈回路：** 一个发射同一事件的处理器会递归。在效果可链式触发处（power 响应 power）防范重入。
- **泄漏：** 见纪律 3。兜底是 `#if DEBUG` 订阅审计（切屏后触发一次，**不在 `Emit` 里查** ——那会在热路径上分配），**订阅侧无需登记来源、`+=` 惯用形态原样保留**。→ `systems/architecture.md`。
