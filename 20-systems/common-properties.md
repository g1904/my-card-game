# common-properties（系统层共有属性）

> 20-systems 顶层的**共有属性 / 约定**：所有系统文档共享的字段命名、稳定 Id 键、seeded RNG 派生、存档版本化、null 校验、日志约定等。深层子树（adventure-event、character-profile、player-profile）另有各自的 `common-properties.md`；本文件是它们之上的**顶层共有层**。


## 意图
> _系统层所有「类」共享的约定。保持更新。_

### 稳定 Id 键
- 每个内容条目都有一个**稳定、唯一的字符串 `Id`**。Id 是其他一切引用的键（存档文件、注册表查找、跨系统交互）。**绝不用场景路径、数组索引或显示名作为内容的键。** Source: `.claude/rules/data-resource-rules.md`。
- 显示字符串（名称、描述）与 `Id` **分离**，可改动 / 本地化而不破坏引用。

### 字段命名与类型一致性
- 类、方法、属性、信号、导出字段用 `PascalCase`；私有字段 `_camelCase`；与 Godot C# API 大小写一致。Source: `.claude/rules/csharp-godot-rules.md`。
- **贯穿整条链路的类型一致性。** 参数 / 返回类型在 UI/输入 → 系统/管理器 → 数据资源（`.tres`）→ 存档模型 全流程对齐；层与层之间不做隐式装箱 / 转换。Source: `.claude/rules/Context.md`。
- 领域术语的中文 ↔ 英文 / 代码标识符权威在 `terminology.md`（例：修行事件 / AdventureEvent、角色信息 / CharacterProfile）。

### 数据即资源
- 每种内容类型是一个 `[GlobalClass] partial class XxxData : Resource`，带 `[Export]` 字段；实例以 `.tres` 编写，由 `content-service` 的 **ContentRegistry** 在启动时按 `Id` 索引。玩法代码经注册表的**泛型仓储接口**（`Get` / `TryGet` / `All` / `Where`）查找，不散落 `ResourceLoader.Load`。Source: `.claude/rules/data-resource-rules.md`。
- **内容分三层：** `res://content/` 基线（随包发布、只读）+ `user://overlay/` 云端热更增量（按 `Id` 覆盖）→ 合并进 ContentRegistry；**校验点在合并之后**（重复 / 悬空 `Id` → `GD.PushError` 启动期早失败）。详见 `20-systems/services/content-service.md`。Source: `10-handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md`。
- **可调平衡数值不硬编码**，归 `20-systems/balance.md` 或导出字段（见 `data-resource-rules.md`）。

### 内容共有字段 `ContentEnabled`（已定案）
- 每种 `XxxData : Resource` 携带 **`ContentEnabled: bool`，默认 `true`**——线上放量开关，overlay 只改这个既有布尔字段，不触碰「不得新增 `Id`」纪律。
- **过滤只发生在产出侧：** 一切**抽取**（eventOptions、商店库存、奖励掷骰）走 `ContentRegistry` 的 **`AllEnabled()`**；**读取侧 `Get(id)` 不过滤**，故存档引用到被关闭的条目仍能正确解析。**任何从内容集合抽取的代码必须走 `AllEnabled()`**——与「不散落 `ResourceLoader.Load`」同级的纪律。
- **合并后强校验对 disabled 条目照常全量执行**（`Id` 唯一性、交叉引用不悬空）。完整论证见 `20-systems/services/content-service.md`。Source: `10-handoffs/2026-07-27-content-gating-offline-resilience-and-rng-persistence.md`。

### 展示字段的归属（已定案）
- 各「类」只携带编码（`Id` / 数值）。展示（充血）字段的归属**按生命周期切分三层**，而非为前端另建一套并行类：**静态展示文本**（显示名 / 描述 / 图标）留在 `XxxData : Resource` 上；**运行时 / 存档态**只带 `Id` + 可变状态，不复制展示文本；**组合展示**（数值代入、条件文案、随 capability flag 变化的可见性）由 UI 层轻量 **ViewModel** 按需组装，不落存档、不进云端负载。完整论证与待确认项见 `20-systems/architecture.md`。Source: `10-handoffs/2026-07-25b-event-cost-fields-capability-flags-and-service-hierarchy.md`。

### Seeded RNG 派生（确定性）
- 每个轮回存储一个 **seed**；所有玩法随机性（地图 / location 生成、抽卡、商店库存、奖励掷骰、敌人行为）从该 seed 派生，最好通过具名子流（sub-stream）隔离，避免系统间 desync。**不用未加种子的 `GD.Randi()` / `Random` 决定玩法结果。**
- 在存档中持久化足够的 RNG 状态，使恢复的轮回能确定性继续。**持久化形态已定案：**
  - **子流派生 `streamSeed = Hash64(CycleSeed, streamName)`**——子流 seed 可随时从 `CycleSeed` 重算，存档中存它**只为诊断与自校验**。
  - **`State`（u64）是恢复用的权威字段**：重建子流后回填 `RandomNumberGenerator.State`，**O(1)**，不必重放。
  - **`DrawCount`（int）是诊断与迁移保险**：`State` 是引擎实现细节，Godot 升级可能改变其语义；届时用 **`seed + drawCount` fast-forward 重放**恢复（一次轮回抽取数千次，重放成本可忽略）。冗余成本每流 4 字节。
  - **子流清单是 `SeedManager` 内的常量**（map / combat / shop / reward）。读档遇存档中没有的**新子流** → `GD.PushWarning` + 按 `Hash64(CycleSeed, name)` 全新初始化；遇清单里已不存在的**旧子流** → 警告并丢弃。**增删子流不 bump schema 版本。**
  - **防 re-roll：** 战斗内随机**不直接用 `combat` 子流**，而是每场再派生 **`Hash64(combatStreamSeed, eventId, attemptIndex)`**；否则「退出重进」会重掷战斗随机——强制在线 + 云端权威下这是最易被发现的漏洞。
  - 存档 schema 见 `20-systems/character-profile/_index.md`；派生方是 `life-cycle-service.SeedManager`。Source: `10-handoffs/2026-07-27-content-gating-offline-resilience-and-rng-persistence.md`。
- **确定性的边界：同一 `contentVersion` 内（已定案）。** 内容热更**以 overlay 更新为准**——轮回进行中 overlay 更新时新数值立即生效，**不冻结该轮回的 `contentVersion`**。因此本项目**不承诺「同一 seed 跨内容版本复现同一轮回」**：seeded RNG 的目的是消除未加种子的随机、保证存档恢复后能正确继续，而非提供跨版本的绝对可复现性。数值可随时线上修正的价值高于跨版本复现。Source: `10-handoffs/2026-07-26-event-priority-skip-semantics-and-hotfix-scope.md`、`20-systems/services/content-service.md`。

### 存档版本化与原子写入（强制在线 · 云端权威）
- **强制在线 · 云端权威**：进度实时同步云端，本地↔云端冲突以云端为准；本地 `user://` 仅作缓存 / 离线临时态。Source: `50-decisions/ADR-0003-online-cloud-authority.md`。
- **原子写入**：先序列化到临时文件，再重命名覆盖；对本地缓存与上行云端负载都原子、带版本。
- **给存档加 schema 版本字段 + 迁移路径**；读取时校验版本 / 内容 id / 字段，未知或不匹配以清晰错误 / 迁移处理，绝不静默 null。Source: `.claude/rules/state-save-rules.md`。

### Null / 结果校验（强制）
- 每次节点查找、资源加载、注册表 / 字典查找、存档读取之后，使用前**显式校验**：必需但缺失 → `GD.PushError` + 定位上下文（id / 路径）并退出；可选但缺失 → `GD.PushWarning` + 安全默认值。绝不把未检查的 null 向下游传递。Source: `.claude/rules/null-check-rules.md`。

### 日志约定
- 用 `GD.Print` / `GD.PushWarning` / `GD.PushError`，带 `[System-Method]` 标签（例：`[Combat-PlayCard]`）；在关键状态转换（轮回开始 / 结束、遭遇战、卡牌结算、存档 / 读档）做有意义日志。Source: `.claude/rules/Context.md`。

### 服务协作约定（两级层次 service ⊃ manager）
- **service = 进程内模块单例，不是微服务。** 全部服务在同一 Godot 项目 / 同一二进制 / 同一进程内，以 **autoload** 形式存在，彼此为直接 C# 方法调用；manager 是服务持有的普通 C# 对象（非 `Node`）。唯一真实的进程边界是客户端 ↔ 后端。工程落地形态见根级 `system-overview.md`。
- **service = 边界单元**（判据三选一：① 自有状态机 / 长流程；② 事务性跨字段一致写；③ 外部 I/O 边界）；**manager = 服务内部的职能组件**，共享宿主服务的事务边界与生命周期，**不被跨服务直接调用**。服务清单与拆分轴见 `20-systems/services/_index.md`。Source: `10-handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md`。
- **拆分轴 = 生命周期层 + 行为边界，不是数据类型。** 不按 power / item / card / resource 各开服务（撕碎事务、横切生命周期层、退化为贫血 CRUD）；不为九类 AdventureEvent 各开服务（只有 Combat 有状态机，其余差异在数据而非代码）。
- **两条唯一入口：** 内容读取经 `content-service.ContentRegistry`（不散落 `ResourceLoader.Load`）；档案写入经 `profile-service.ProfileManager`（全量校验 → 全有或全无 → 单点提交，modifier pipeline 在此生效）。
- **跨服务调用纪律（已定案的准确措辞）：服务之间不读写对方字段、不伸手进对方 manager；跨服务的方法调用允许**——经对方的服务门面 `Xxx.Instance.Method(...)`，不得触及 `private` manager 字段。**编排顶点 game-progression** 负责「谁在什么时机调谁」的屏幕流程串联，但**不是**一切跨服务调用的必经中转；既成事实经 **EventBus** 广播。Source: `10-handoffs/2026-07-27b-service-api-contracts.md`。

### API 契约总则（已定案 · 摘要）

> 完整八条总则、共享核心类型与 EventBus 负载 schema 的**权威在 `20-systems/architecture.md`「API 契约总则」**。此处只列所有系统文档书写 API 时必须遵守的约束。Source: `10-handoffs/2026-07-27b-service-api-contracts.md`。

- **三种方法形态，按「它跨什么边界」决定，不允许混用：** **A · 同步直返**（纯内存查询与纯本地事务）／**B · `Task<OpResult<T>> + CancellationToken`**（跨客户端 ↔ 后端边界）／**C · `Task<T>` 由信号推进**（跨多帧的玩法长流程）。**形态 B / C 一律带 `Async` 后缀并返回 `Task`，形态 A 一律不带**——看签名即知它是否跨边界。
- **三种失败语义，与 null-check 规则一一对应：** 必需缺失 = 程序缺陷 → `GD.PushError` + `throw`；可选缺失 = 调用方可降级 → `bool TryXxx(..., out T)` + `GD.PushWarning`；**业务失败 = 预期内的拒绝 → 返回 `OpResult` / `OpResult<T>` / `ApplyResult`，绝不抛**。结果类型一律 `readonly record struct`（零堆分配）。
- **服务门面骨架：** manager 类型 `internal sealed`、服务只暴露方法不暴露 manager 引用、**服务不返回内部可变集合**（一律 `IReadOnlyList<T>` / `IReadOnlyDictionary<,>`）。
- **启动契约：** `_Ready` 只装配，I/O 归 `IBootstrappable.InitializeAsync(ct)`，由 Bootstrap 屏幕按固定顺序驱动。
- **EventBus 用 C# 泛型 `event` + `readonly record struct` 负载**（不用 Godot `[Signal]`——负载须继承 `GodotObject`，每次广播分配 + `Variant` 装箱，撞上本文件「不做隐式装箱 / 转换」与热路径不分配）。**负载只带 `Id` + 值类型，绝不带 `CharacterProfile` / `Resource` / 定稿实例引用**；订阅方 `_Ready` 订阅、`_ExitTree` 退订。
- **`CostSpec` / `RewardSpec` 合并为单一 `ProfileChangeSpec`**（`ChangeElement.BaseValue` 带符号：负 = 消耗，正 = 产出）——「全有或全无、单点提交」本就要求成本与产出在同一事务内。
- **capability flag 的载体是 C# `enum CapabilityFlag`**，不是字符串 key：flag 的消费点必然是一段 UI 代码，字符串只是把「拼错了」从编译期推迟到运行时。可加的是 `.tres` 里**谁授予哪个已定义的 flag**。
- **API 书写规范：** 各服务文档的「API 面（契约）」小节统一为四列表 **方法 | 形态(A/B/C) | 完整签名 | 失败语义**；形状依赖未答问题的写 `⟨待定：链接到待决项⟩`，不留空白也不臆造。

### 物化模型：内容定义 ↔ 运行时实例（已定案）

- **凡「内容定义 + 情境 / 轮回内状态」的组合都是两个类型**，服务签名里**传实例，不传 `Resource`**：
  - `AdventureEventData` ↔ **`EventOption`** —— 由 future-event-service **物化（materialize）**产出，**产出即定稿（immutable）**，落存档；
  - `CardData` ↔ **`CardInstance`** —— 运行态**可变**（手牌中的临时增益）。
- **`XxxData : Resource` 是 ContentRegistry 里的共享只读单例，任何服务都不得在运行时写它**——写回会污染注册表，被同一轮回的后续批次与其他角色看到。
- 这与上方「展示字段的归属」三层切分同构：它把**第二层（运行时 / 存档态）的类型形态**明确了。物化模型的完整论证见 `20-systems/architecture.md`「总则 6」。Source: `10-handoffs/2026-07-27b-service-api-contracts.md`。

## 决策(-> ADR)
> _已定案的决定链接到 50-decisions/ADR-####。_

- **强制在线 · 云端权威** → `50-decisions/ADR-0003-online-cloud-authority.md`（Accepted）。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **共有属性提炼粒度：** 本文件为顶层共有层；哪些字段应下沉到子树各自的 `common-properties.md`、哪些应留在顶层，边界待随子树填充而细化。Source: `10-handoffs/2026-07-24-docs-restructure-class-model.md`。
- **`.claude/rules/*` 与本库的主从关系：** 知识笔记的形态已定（`50-decisions/ADR-0005`：薄引用），但 **ADR-0005 只覆盖 `.claude/knowledge/*`，未涉及 `.claude/rules/*`**——本文件所引的规则文件与本库主题文档谁主谁从（规则是本库的强制执行摘要，还是独立于本库的工程约束？冲突时以谁为准？）仍待定。Source: `10-handoffs/2026-07-24-docs-restructure-class-model.md`。

## 对应
提炼至：`.claude/knowledge/standards/`（ADR-0005：设计投影的三份 `signal-eventbus` / `rng-determinism` / `save-format` 为**薄引用**，回链本库；`csharp-conventions` / `godot-scene-conventions` / `mobile-portrait-ui` 讲 C#/Godot 引擎实践，在本库无权威，**保留实质**）。
