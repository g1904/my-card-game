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

### 展示字段的归属（已定案）
- 各「类」只携带编码（`Id` / 数值）。展示（充血）字段的归属**按生命周期切分三层**，而非为前端另建一套并行类：**静态展示文本**（显示名 / 描述 / 图标）留在 `XxxData : Resource` 上；**运行时 / 存档态**只带 `Id` + 可变状态，不复制展示文本；**组合展示**（数值代入、条件文案、随 capability flag 变化的可见性）由 UI 层轻量 **ViewModel** 按需组装，不落存档、不进云端负载。完整论证与待确认项见 `20-systems/architecture.md`。Source: `10-handoffs/2026-07-25b-event-cost-fields-capability-flags-and-service-hierarchy.md`。

### Seeded RNG 派生（确定性）
- 每个 run 存储一个 **seed**；所有玩法随机性（地图 / location 生成、抽卡、商店库存、奖励掷骰、敌人行为）从该 seed 派生，最好通过具名子流（sub-stream）隔离，避免系统间 desync。**不用未加种子的 `GD.Randi()` / `Random` 决定玩法结果。** 给定 seed 必须复现同一个 run。Source: `.claude/rules/state-save-rules.md`。
- 在存档中持久化足够的 RNG 状态，使恢复的 run 能确定性继续。

### 存档版本化与原子写入（强制在线 · 云端权威）
- **强制在线 · 云端权威**：进度实时同步云端，本地↔云端冲突以云端为准；本地 `user://` 仅作缓存 / 离线临时态。Source: `50-decisions/ADR-0003-online-cloud-authority.md`。
- **原子写入**：先序列化到临时文件，再重命名覆盖；对本地缓存与上行云端负载都原子、带版本。
- **给存档加 schema 版本字段 + 迁移路径**；读取时校验版本 / 内容 id / 字段，未知或不匹配以清晰错误 / 迁移处理，绝不静默 null。Source: `.claude/rules/state-save-rules.md`。

### Null / 结果校验（强制）
- 每次节点查找、资源加载、注册表 / 字典查找、存档读取之后，使用前**显式校验**：必需但缺失 → `GD.PushError` + 定位上下文（id / 路径）并退出；可选但缺失 → `GD.PushWarning` + 安全默认值。绝不把未检查的 null 向下游传递。Source: `.claude/rules/null-check-rules.md`。

### 日志约定
- 用 `GD.Print` / `GD.PushWarning` / `GD.PushError`，带 `[System-Method]` 标签（例：`[Combat-PlayCard]`）；在关键状态转换（run 开始 / 结束、遭遇战、卡牌结算、存档 / 读档）做有意义日志。Source: `.claude/rules/Context.md`。

### 服务协作约定（两级层次 service ⊃ manager）
- **service = 进程内模块单例，不是微服务。** 全部服务在同一 Godot 项目 / 同一二进制 / 同一进程内，以 **autoload** 形式存在，彼此为直接 C# 方法调用；manager 是服务持有的普通 C# 对象（非 `Node`）。唯一真实的进程边界是客户端 ↔ 后端。工程落地形态见根级 `system-overview.md`。
- **service = 边界单元**（判据三选一：① 自有状态机 / 长流程；② 事务性跨字段一致写；③ 外部 I/O 边界）；**manager = 服务内部的职能组件**，共享宿主服务的事务边界与生命周期，**不被跨服务直接调用**。服务清单与拆分轴见 `20-systems/services/_index.md`。Source: `10-handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md`。
- **拆分轴 = 生命周期层 + 行为边界，不是数据类型。** 不按 power / item / card / resource 各开服务（撕碎事务、横切生命周期层、退化为贫血 CRUD）；不为九类 AdventureEvent 各开服务（只有 Combat 有状态机，其余差异在数据而非代码）。
- **两条唯一入口：** 内容读取经 `content-service.ContentRegistry`（不散落 `ResourceLoader.Load`）；档案写入经 `profile-service.ProfileManager`（全量校验 → 全有或全无 → 单点提交，modifier pipeline 在此生效）。
- **服务之间不互相读写字段**——只经**编排顶点 game-progression** 调用，或经 **EventBus** 自动加载广播既成事实。Source: `.claude/rules/csharp-godot-rules.md`。

## 决策(-> ADR)
> _已定案的决定链接到 50-decisions/ADR-####。_

- **强制在线 · 云端权威** → `50-decisions/ADR-0003-online-cloud-authority.md`（Accepted）。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **共有属性提炼粒度：** 本文件为顶层共有层；哪些字段应下沉到子树各自的 `common-properties.md`、哪些应留在顶层，边界待随子树填充而细化。Source: `10-handoffs/2026-07-24-docs-restructure-class-model.md`。
- **`.claude/knowledge` 引用层改造形态：** 知识笔记降为对本库的引用层，本文件所引 `.claude/rules/*` 与本库的主从关系待随该改造 ADR 固化。Source: `10-handoffs/2026-07-24-docs-restructure-class-model.md`。

## 对应
提炼至：`.claude/knowledge/standards/`（引用层，待改造 / 待建）。
