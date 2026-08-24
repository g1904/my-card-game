# ADR-0030 — 单例内容走既有泛型仓储进 ContentRegistry：`ISingletonContent` + `Single<T>()`

- **状态：** Accepted
- **日期：** 2026-08-22
- **来源：** handoffs/2026-08-22-singleton-balance-resource-registry.md（承载机制四项的正式裁决见 answer-logs/log-0823.md 第二节，逐条移出见 answer-logs/log-singleton-balance-resource-registry.md）

## 背景

有一类内容类型**全库恰好一条**（`CombatRulesData` · `EnemyLevelingData` · `LocationMapData`）。它们不是抽取池的成员，没人会按 `Id` 去查它们，于是「要不要给它们 `Id`、要不要进 ContentRegistry、调用方怎么取那一条」一直没有定论。而平衡表已被归入本地内容层的「只改不增」一栏——若在服务里直读 `res://content/balance/*.tres`，「平衡数值可热更而不发版」当场失效。这个空白必须在写下第一份 `.tres` 之前填上，否则改动会从纯加法退化为改全部调用方。

## 决策

**单例内容与其他内容走同一条路：进 ContentRegistry、走同一个泛型仓储 `IContentRepository<T>`、有稳定两段式 `Id`；调用方不碰 `Id`，改用注册表上带编译期约束的 `Single<T>()` 取那一条；条数与启用态在加载期强校验。**

- **`Id` 形态 = 两段式 `<资源全名 snake_case>.default`**（`combat_rules.default` · `enemy_leveling.default` · `location_map.default`），写在 `.tres` 里，**不写进任何 C# 常量**。
- **`Id` 的消费者是 overlay 合并，不是调用方**——单例之所以必须有稳定 `Id`，是因为 overlay 按 `Id` 覆盖基线；调用方既不应该也不需要看到它。
- **单例身份由标记接口 `ISingletonContent` 声明**；读取面 `T Single<T>() where T : Resource, ISingletonContent`，对非单例类型调用即**编译错误**（可执行化阶梯第 2 级）。
- **加载期校验**（合并后强校验内，全量、非 `#if DEBUG`、带类型名定位）：某 `ISingletonContent` 类型条目数 `!= 1` → `PushError` + 抛；某 `ISingletonContent` 条目 `ContentEnabled == false` → `PushError` + 抛。
- **准入边界：一份资源可以进 ContentRegistry，当且仅当它的全部消费点晚于 `LoadAll()`。** 违反者（overlay 下载重试次数 / 退避）写死为代码常量，并在 `systems/balance.md` 标注「不可线上调」。
- **不新增仓储种类、不新增服务**；`Single<T>()` 内部走全量口径 `AllIncludingDisabled()`，flags 第三层对单例不生效。

逐类型的 `Id` / 基线路径 / 消费者 / 覆写纪律表、校验表与排期 → `systems/services/content-service.md`「单例内容的注册与校验」；`LocationMapData` 的份数校验并入通用单例校验 → `systems/game-progression.md`。

## 理由

- **不进注册表即同时失去三项。** 「只改不增」栏的三项性质——overlay 可热更 · 合并后强校验 · 按 `Id` 索引——全部由 ContentRegistry 兑现。直读 `res://` 绕过按 `Id` 合并的覆盖层（热更失效）、绕开合并后强校验（坏平衡表要到轮回中途才炸）、并违反「不散落 `ResourceLoader.Load`」。同形先例是 `LocationMapData`（单份全局唯一、启动加载一次、只读常驻、不进存档）。
- **单例是「合法条目数恰好为 1 的类型」，不是另一种东西。** 为它开第二种仓储接口等于给「唯一内容读取入口」开一个平行入口，并立刻要求回答「哪些类型走哪条路」这种逐类型记忆的问题。
- **用类型约束把正确路径变成最短路径。** `Id` 字面量彻底不出现在调用方（`Content.Single<CombatRulesData>()` 没有可拼错的字符串），与「`CapabilityFlag` 用 enum 不用字符串 key」「删掉中性诱饵名 `All()`」同款——不靠条款靠类型。`Single()` 的语义与 LINQ 逐字一致，名字不必发明。
- **标记接口是把一条本会逐份手写的校验一般化。** 图校验表里原有的「`LocationMapData` 存在多份 / 零份 → `PushError`」随之改为回链——逐份手写的形态里，漏写一份就是一个静默的洞。
- **准入边界不写下来就会被一次「顺手也放进平衡资源」踩中**，而症状是启动死循环（要读它必须先合并 overlay，要合并 overlay 必须先读它）或一份永远读不到的配置。

## 备选方案

- **不给单例 `Id`（既然没人查）** — 混淆了「谁消费 `Id`」：overlay 按 `Id` 覆盖基线，没有稳定 `Id` 就没有热更。
- **单段式 `Id`（`combat_rules`）** — 全库将出现两种 id 语法，「恰好一个点」这条可机械校验的约束失效；代价换来的只是省掉一段当前不携带信息的 `.default`。
- **注册时 `RegisterSingleton<T>()` 声明单例身份** — 加载期校验相同，但拿不到编译期约束，`Single<T>()` 对任意类型都可写。
- **给单例砍掉 `AllEnabled()`（单开一个仓储接口）** — 打破「对外是同一形状」这条既定条款，换来的只是挡住一个无害且无人会写的调用。
- **早于 `LoadAll()` 的旋钮改走随包 `res://` 直读小资源 / 由后端 manifest 携带** — 为三个稳态运维值开一条平行配置通道，成本远高于收益；如实标注「不可线上调」比让它假装是可调平衡值更好。

## 后果

- **`ISingletonContent` + `Single<T>()` 是注册表面的纯加法改造**，与 `DrawPool<T>` · `LocalizedText` 属同一次改动面，**须同批落在第二阶段（内容）开工前、第一份 `.tres` 之前**。窗口关闭后改动从「纯加法」退化为「改全部调用方」。
- **无存档影响、不 bump schema**：单例平衡资源不进存档，`ISingletonContent` 是代码侧标记、不进 `.tres`、不走 overlay。本决策不改任何数值、不改任何机制。
- **`systems/game-progression.md` 的图校验表不再自带 `LocationMapData` 的份数检查**（净减一条手写校验），`LocationMapData` 的类定义带上 `ISingletonContent`。
- **`content/_index.md` 须明写「不建 `content/` 类型 ≠ 不进 ContentRegistry」**——「平衡数值归 `systems/balance.md`，不是条目」裁定的只是不为平衡数值单开 `content/<类型>/` 文件夹与类型档案。
- **`systems/balance.md` 须标注**「overlay 下载重试次数 / 退避不进注册表、写死为常量、不可线上调」；平衡资源切成几份的判据与各旋钮的逐份落点亦归该文档（**该处目前尚未落笔**）。
- **overlay 侧不可能把一份单例变成两份**（已被合并期闸 A 兜住：overlay 新增的 `Id` 其宿主类型必须 ∈ { `PlotArcData`, `PlotNodeData` }）；条数校验主要防的是 `res://` 基线的编写错误。
