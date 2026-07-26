# 标准 —— 信号与 EventBus（深入）

`.claude/rules/csharp-godot-rules.md`（信号章节）的配套文档。

## 何时用什么
- **直接方法调用** —— 父级驱动其自身子级，或单个场景内紧耦合的 node。最简单；场景内部默认使用它。
- **局部 `[Signal]`** —— 子级在不知道谁在监听的情况下通知其父级/所有者（例如某个 `Card` 发射 `Played`），限于场景边界内。
- **EventBus autoload** —— 跨系统、跨场景、解耦的事件，其中发射方与监听方不应互相引用（run 生命周期、gold 变化、能力触发、事件结算）。**这是服务之间唯一的间接通路**：服务之间不互相读写字段，只经编排顶点（game-progression）调用，或经 EventBus **广播既成事实**。

## EventBus 设计
- 单个 autoload，为全局事件暴露 `[Signal]` 声明。各系统在 `_Ready` 中 `Connect`，并适当地 `Disconnect`/释放。
- **保持载荷 Variant 简单：** 传递 id 与基本类型（`string cardId`、`int newGold`），而非富 C# 对象——编组更安全、耦合更松。监听方通过 `ContentRegistry`（静态内容）/ `CharacterProfile`（运行时状态）解析富数据。
- 将事件命名为**过去时的事实**：`RunStarted`、`EventResolved`、`CardPlayed`、`GoldChanged`、`CapabilitiesChanged`。命名为事实而非指令，正是「广播既成事实」纪律的体现。
- **呈现决策经 EventBus 下发到呈现层：** `CapabilityManager` 聚合后广播 `CapabilitiesChanged`，**各 UI 组件自行订阅并自查** flag 决定可见性——业务逻辑层不写 `if (hasPowerX)`。

## 陷阱
- **泄漏：** 指向一个已被释放的场景 node 的连接会悬空。优先从生命周期更长的一方连接，或在 `_ExitTree` 中断开。
- **顺序：** 不要假设监听方的执行顺序。若顺序重要（relic 触发优先级），就显式建模（由一个系统解析出的优先级列表），而不是依赖连接顺序。
- **反馈回路：** 一个发射同一事件的事件处理器会递归。在效果可链式触发处（relic 响应 relic）防范重入。
