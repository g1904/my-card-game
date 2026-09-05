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
| `data/*` | `systems/`（类定义：字段 / 内嵌类型）+ `content/`（条目实例层：一条内容一份文档 + 类型档案） |
| `scenes/*` | `ux/`（screen-flow、combat-ux、onboarding） |
| ViewModel 层（知识层无对应文件） | `systems/viewmodel.md`（呈现期对象的横切纪律：依赖方向 / 生命周期 / 组装源 / 重组装触发面 / 缓存归属） |
| `autoloads/*` | `systems/services/`（七服务 + 层级词表 + 各服务 API 契约表） |
| 美术 / 音频（知识层无对应文件） | `art/`（`visuals/` · `soundtracks/`；只存 vision / 参考登记 / guide，**生成出的二进制资产归 `game-feature-branch/`**——目前一件都还没有） |
| 协议契约（客户端只有投影） | `backend-design-documents/contracts/`——**报文形态的权威在后端库**，本库只定客户端的调用形状 |
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
- **拆分轴 = 生命周期层 + 行为边界，不是数据类型。** 不按 power / item / card 各开服务，也不为五类 AdventureEvent 各开服务——只有 Combat 真有状态机，其余差异在**数据**而非代码。
- **两条唯一入口 + 一个编排顶点：** 内容读取 = `content-service.ContentRegistry`；档案写入 = `profile-service.ProfileManager.TryApply(spec)`；编排顶点 = game-progression（非服务，串联核心循环）。
- **展示层三层：** 静态文案留在 `XxxData : Resource`（类型 `LocalizedText`）→ 运行时 / 存档态只带 `Id` + 可变状态 → 呈现期 ViewModel 组装（不落存档、不进云端负载）。三层并列定义在 `systems/architecture.md`「展示层契约」，**第三层的展开权威已单列 `systems/viewmodel.md`**。
- **文案两条链路、一个语言开关：** 界面走 `res://text/` 翻译键（随包、发版才改），内容走条目内嵌 `LocalizedText`（overlay 可热更），二者共用 `TranslationServer.GetLocale()`。归属判据（四问）→ `ux/_index.md`。
- **物化模型：** `AdventureEventData`（模板）→ future-event-service（**唯一物化点**）→ `EventOption`（**产出即定稿、不可变、落存档**）。同一通则也适用于 `EnemyData` → `EnemyInstance`。→ `systems/architecture.md`「总则 6」。
- **核心循环一批只有一次操作：择一进入。** 跳过通道整体不存在，别为「跳过」写任何分支；选择约束只剩 `Priority` 一条轴，future-event-service 独占置位。→ `systems/game-progression.md`
- **内容三层覆盖来源：** 基线 < overlay < flags → 合并后统一校验 → ContentRegistry 按 `Id` 索引。→ `data/_index.md`
- **一切内容都在本地，没有云端内容通道**：跨进程边界收敛为**鉴权 · 进度同步 · 内容分发**三处窄接口，玩法回路全程零网络请求。**已预告第四个 `IPurchaseBackend`（商业化落地时）；把支付方法挂进 `IProfileBackend` 已被明确否决。** → `systems/architecture.md`「总则 7」；「剧本纯本地」这一条 → `systems/services/plot-manager.md`
- **启动契约：** `main` 场景 = `BootstrapScreen.tscn`，按序驱动**三个**边界服务的 `InitializeAsync`，并在登录之后插入一次 `RefreshFlagsAsync`。→ `autoloads/_index.md`。

## 承重纪律（写代码时会改变写法的那几条）

> **上位判据 —— 纪律的可执行化。** 遇到「这条约定该怎么强制」时套四级阶梯（**写不出来 / 编译不过 / 大声失败 / 评审清单**）：**能上线且线上不可见的违规必须落在前两级**——断言只在跑到那一步时生效，而这类违规的症状恰恰是「一切正常」。**别用注释和评审清单去挡会上线的错误。** → `systems/architecture.md`「纪律的可执行化」。

1. **确定性的边界 = 同一 `contentVersion` 内。** 随机性一律经 SeedManager 的具名子流，**不用未加种子的 `GD.Randi()`**；已明确**放弃跨内容版本复现**（overlay 即时生效、不冻结版本）。→ `standards/rng-determinism.md`
2. **抽取走 `AllEnabled()`；仓储上没有中性名 `All()`**（全量走 `AllIncludingDisabled()`，写下 `All()` 会编译失败）。读取侧 `Get(id)` **不**过滤（存档引用不能悬空）。→ `data/_index.md`
3. **档案写入只经 `ProfileManager.TryApply(spec)`**（全量校验 → 全有或全无 → 单点提交），成本与产出在**同一次** `TryApply` 内。**收口前若要依「更新后的」profile 重算，走只读投影 `Project(spec)` 先算后提交，不开第二个写入面**（投影不存字段、不跨 `await`）。→ `decisions/ADR-0108-profile-readonly-projection.md`**modifier pipeline 对 `Elements` 是 opt-in 白名单、缺省豁免**——缺省若取「经 pipeline」，一条法则可静默改写幂等键 / 付费凭证。→ `systems/architecture.md`
4. **运行时绝不写 `XxxData : Resource`** ——它是注册表里的共享只读单例，写回会污染同一轮回的后续批次与其他角色。服务签名里**传实例，不传 `Resource`**。
5. **方法形态看签名即知边界：** B（跨后端）/ C（跨多帧长流程）**带 `Async` 后缀并返回 `Task`**，A（纯内存 / 纯本地事务）**不带**。三者不许混用。
6. **业务失败不抛异常**（付不起成本、网络不通、token 失效 → 返回 `OpResult` / `ApplyResult`）；只有「必需缺失 = 程序缺陷 / 坏数据」才 `GD.PushError` + `throw`。→ `.claude/rules/null-check-rules.md`
7. **EventBus 用 C# 泛型 `event` + `readonly record struct` 负载**，不用 Godot `[Signal]`；负载**只带 `Id` + 值类型**；**`_Ready` 订阅 / `_ExitTree` 退订**。→ `standards/signal-eventbus.md`
8. **服务间只经 `Xxx.Instance.Method(...)` 调用**，不读写对方字段、不伸手进对方 manager（跨服务方法调用本身是允许的）；manager 类型 `internal sealed`；服务不返回内部可变集合。
9. **集合字段名与元素类型名恒为单数形态对应，且二者不得逐字相同**（`RealmArtworks : RealmArtwork[]`）——同名会让类内成员查找遮蔽同名类型，`new RealmArtwork()` 当场解析不了；且字段名机械映射为 JSON path，改名即破坏性契约变更。→ `decisions/ADR-0105-singular-collection-field-naming.md`

## 其余导航

系统 → `systems/_index.md`　·　数据 → `data/_index.md`　·　场景 → `scenes/_index.md`　·　服务 → `autoloads/_index.md`　·　术语 → `dictionary.md`　·　引擎实践 → `standards/`
