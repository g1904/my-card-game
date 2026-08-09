# 架构（引用层）

MyCardGame 的**导航文件**。本层不复述设计——只回答三件事：**代码现在是什么样**、**权威文档在哪**、**写代码时哪几条纪律会改变我的写法**。

> **知识层 = 薄引用层（已定案）。** 凡在 `game-design-documents/` 里已是代码形态的东西（方法签名、枚举、`record` 定义、EventBus 负载表、接口清单、schema），**这里只留链接，不留副本**——副本是下一次漂移的来源。要看形状就去读权威文档。

## 知识 ↔ 设计文档对照（权威在右）

| 知识文件 | 权威设计文档 |
|----------|--------------|
| `architecture.md`（本文件） | `systems/architecture.md`（结构与边界的权威，含 API 契约总则八条、物化模型、EventBus 负载契约、共享核心类型） |
| 运行链路 | `program-overview.md`（端到端运行时视角）、`system-overview.md`（工程形态：文件夹布局、autoload 注册、代码形态） |
| `dictionary.md` | `terminology.md`（根级术语表） |
| `systems/*` | `systems/`（类模型化结构） |
| `data/*` | `systems/`（内容即各系统的字段 / 内嵌类型） |
| `scenes/*` | `ux/`（screen-flow、combat-ux、onboarding） |
| `autoloads/*` | `systems/services/`（七服务 + 层级词表 + 各服务 API 契约表） |
| 已定案决策 | `decisions/ADR-*` |
| 待答问题 | `open-questions.md` |
| 可构建规格 | `requirements/FR-*` |

## 代码现状（知识层独有的真值）

`game-feature-branch/` 目前**只有 Godot 脚手架**：`project.godot`、`icon.svg`、`.godot` 缓存、git 属性文件。**尚不存在任何场景、C# 脚本、autoload 或数据资源**，`project.godot` 无 `[autoload]` 段、未设主场景。设计文档里的一切都是**待构建的规划**——在代码里亲眼见到之前，不要假定某系统已存在。

引擎与平台（读自 `project.godot`）：
- **Godot 4.7** + **.NET/C#**，程序集名 `game-feature-branch`。
- 渲染器 **GL Compatibility**（`gl_compatibility`，`.mobile` 亦然）；Windows 编辑器用 `d3d12` 驱动。
- 显示 `stretch/mode = canvas_items`、`stretch/aspect = expand`，**竖屏**、移动优先。
- 目标平台 **Android / iOS（主要）、桌面、网页**；**强制在线 · 云端权威**，`user://` 仅作缓存。
- 3D 物理设为 Jolt（脚手架默认；本作是 2D，未使用）。

## 结构骨架（一句话版，细节见权威）

- **层级：service ⊃ manager ⊃ module ⊃ processor ⊃ handler**（现有实例止于第三级 `DeckModule`）。 七个服务以 autoload 存在，各自命中「①自有状态机 / ②事务性跨字段写 / ③外部 I/O 边界」三判据之一；manager 是服务内部的普通 C# 对象。清单见 `autoloads/_index.md`。
- **拆分轴 = 生命周期层 + 行为边界，不是数据类型。** 不按 power / item / card 各开服务，也不为九类 AdventureEvent 各开服务——只有 Combat 真有状态机，其余差异在**数据**而非代码。
- **两条唯一入口 + 一个编排顶点：** 内容读取 = `content-service.ContentRegistry`；档案写入 = `profile-service.ProfileManager.TryApply(spec)`；编排顶点 = game-progression（非服务，串联核心循环）。
- **展示层三层：** 静态文案留在 `XxxData : Resource` → 运行时 / 存档态只带 `Id` + 可变状态 → 呈现期 ViewModel 组装（不落存档、不进云端负载）。
- **物化模型：** `AdventureEventData`（模板）→ future-event-service（**唯一物化点**）→ `EventOption`（**产出即定稿、不可变、落存档**）。同一通则也适用于 `EnemyData` → `EnemyInstance`。→ `systems/architecture.md`「总则 6」。
- **核心循环一批只有一次操作：择一进入。** 跳过通道整体移除（08-06c）——无 `skipCost` / `ifMandatory` / `AdvanceMode`，每次选择后整批重算。选择约束只剩 `Priority` 一条轴（取值域 `{0, 1}`，future-event-service 独占置位，PlotManager 不可改）。
- **内容三层存储：** `res://content/` 基线 + `user://overlay/` 热更（**只改不增**）→ 合并后统一校验 → ContentRegistry 按 `Id` 索引。→ `data/_index.md`。
- **启动契约：** `main` 场景 = `BootstrapScreen.tscn`，按序驱动四个边界服务的 `InitializeAsync`。→ `autoloads/_index.md`。

## 承重纪律（写代码时会改变写法的那几条）

> **上位判据 —— 纪律的可执行化**（已定案 · **ADR 候选**，与八条 API 契约总则同层）。遇到「这条约定该怎么强制」时直接套四级阶梯：**1 写不出来 / 2 编译不过 / 3 大声失败 / 4 评审清单**。两条选级判据：**能上线且线上不可见 → 必须第 1 或第 2 级**（第 3 级不够——断言只在跑到那一步时生效，而这类违规的症状恰恰是「一切正常」）；**只在开发期显形且会累积 → 第 3 级足够**。已应用三处：离线后端删类（1）、删掉中性诱饵名 `All()`（1 / 2）、EventBus 订阅审计（3）。**别用注释和评审清单去挡会上线的错误。** → `systems/architecture.md`「纪律的可执行化」。

1. **确定性的边界 = 同一 `contentVersion` 内。** 随机性一律经 SeedManager 的具名子流，**不用未加种子的 `GD.Randi()`**；已明确**放弃跨内容版本复现**（overlay 即时生效、不冻结版本）。→ `standards/rng-determinism.md`
2. **抽取走 `AllEnabled()`；仓储上没有中性名 `All()`**（全量走 `AllIncludingDisabled()`，写下 `All()` 会编译失败）。读取侧 `Get(id)` **不**过滤（存档引用不能悬空）。→ `data/_index.md`
3. **档案写入只经 `ProfileManager.TryApply(spec)`：** 全量校验 → 全有或全无 → 单点提交。成本与产出在**同一次** `TryApply` 内（`ProfileChangeSpec` 带符号，无 `CostSpec`/`RewardSpec` 两个类型）。
4. **运行时绝不写 `XxxData : Resource`** ——它是注册表里的共享只读单例，写回会污染同一轮回的后续批次与其他角色。服务签名里**传实例，不传 `Resource`**。
5. **方法形态看签名即知边界：** B（跨后端）/ C（跨多帧长流程）**带 `Async` 后缀并返回 `Task`**，A（纯内存 / 纯本地事务）**不带**。三者不许混用。
6. **业务失败不抛异常**（付不起成本、网络不通、token 失效 → 返回 `OpResult` / `ApplyResult`）；只有「必需缺失 = 程序缺陷 / 坏数据」才 `GD.PushError` + `throw`。→ `.claude/rules/null-check-rules.md`
7. **EventBus 用 C# 泛型 `event` + `readonly record struct` 负载**，不用 Godot `[Signal]`；负载**只带 `Id` + 值类型**；**`_Ready` 订阅 / `_ExitTree` 退订**。→ `standards/signal-eventbus.md`
8. **服务间只经 `Xxx.Instance.Method(...)` 调用**，不读写对方字段、不伸手进对方 manager（跨服务方法调用本身是允许的）；manager 类型 `internal sealed`；服务不返回内部可变集合。

## 其余导航

系统 → `systems/_index.md`　·　数据 → `data/_index.md`　·　场景 → `scenes/_index.md`　·　服务 → `autoloads/_index.md`　·　术语 → `dictionary.md`　·　引擎实践 → `standards/`
