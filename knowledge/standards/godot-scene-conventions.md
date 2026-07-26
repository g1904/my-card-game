# 标准 —— Godot 场景约定（深入）

`.claude/rules/scene-rules.md` 的配套文档。

## 组合
- 一个场景 = 一个内聚单元（一个屏幕、一张卡牌、一个敌人）。用较小的实例化场景组合大屏幕，而非一个巨大的 `.tscn`。
- 根 node 类型反映场景的角色：UI 屏幕/控件用 `Control`，世界/棋盘元素用 `Node2D`，纯逻辑容器用 `Node`。

## node 之间的引用
- **场景唯一名称**（`%Name`，编辑器中的 “Access as Unique Name”）用于脚本所需的重要 node——在树结构编辑后依然稳定。
- **分组（Groups）**用于“某一类的全部”（例如手牌中所有 `Card` node）：`AddToGroup("hand")`、`GetTree().GetNodesInGroup("hand")`。
- **导出的 `NodePath`/node 引用**用于某个 node 需要引用兄弟/表亲 node 时——在检视面板中连线，不要硬编码 `../../`。
- 集中管理 `res://...tscn`/`.tres` 字符串路径（一个常量类，或预加载的 `[Export] PackedScene`），这样移动某个文件只会在一处出错。

## 实例化
- 可复用元素编写一次（`Card.tscn`），运行时实例化：`_cardScene.Instantiate<Card>()`。
- 实例化的父级拥有生命周期；run/遭遇结束时 `QueueFree` 实例。别让旧卡牌/敌人跨 run 残留。

## 数据绑定
- 场景是**视图**。一个 `Card` node 绑定到某个 `CardData` 资源（通过 `Initialize(CardData)` 方法设置）并渲染它。`.tscn` 中不存放任何游戏数值。

## 主场景
- 一旦主场景存在，就在 `project.godot` 中设置引导/主场景（目前未设置）。一个专门的引导场景先初始化 autoload/加载，然后移交给 `MainMenu`，是一种干净的模式。
