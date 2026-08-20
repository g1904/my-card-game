# ADR-0009 — 两条唯一入口 + 一个编排顶点

- **状态：** Accepted
- **日期：** 2026-07-25
- **来源：** handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md

## 背景

架构体检列出的八处闭环缺口里有两处同源：**PlayerProfile 侧无服务**（账号级数据谁写）与**编排顶点缺失**（「谁在什么时机调谁」无人负责）。同时内容读取若各处散落 `ResourceLoader.Load`，热更合并与启动期校验都失去唯一挂点。

## 决策

**内容读取唯一入口 = `content-service.ContentRegistry`。** 代码中不散落 `ResourceLoader.Load`；所有服务经泛型仓储按 `Id` 取内容。

**档案写入唯一入口 = `profile-service.ProfileManager`。** 由**单一 profile-service** 同时拥有两层 profile（`PlayerProfile ⊃ List<CharacterProfile>`），写入形态固定为 `TryApply(spec)`：全量校验 → 全有或全无 → 单点提交，modifier pipeline 在此生效。life-cycle-service / combat-service / future-event-service 都只经它写档。

**编排顶点 = game-progression**（不是服务，是屏幕流程编排层）。核心循环 `ComputeEventOptions → 呈现 → 玩家选择 → AdvanceEvent → 重算` 由它串联；但它**不是**一切跨服务调用的必经中转——既成事实经 EventBus 广播。

## 理由

- **两层 profile 是包含关系，不是并列关系**（`PlayerProfile ⊃ List<CharacterProfile>`），分成两个服务写等于让同一棵对象树有两个写入面，事务边界无从划。
- **单点提交是「全有或全无」的前提**：一次结算要同时改多种资源，`ProfileChangeSpec` 各列在同一次 `TryApply` 内提交才能保证不出现半套写入。
- **唯一入口给校验与修正一个必经点**：`CanAfford` 与 `TryApply` 走同一条 pipeline，modifier 只有一个施加点，否则「打两次折」这类 bug 无法在结构上排除。
- **编排顶点不兼任中转**：让它成为一切调用的中转会把它变成 god object；跨服务的既成事实广播已由 EventBus 承担。

## 备选方案

- **PlayerProfile 与 CharacterProfile 各开一个服务** — 否决：包含关系被切开，事务边界无从划。
- **让编排顶点成为一切跨服务调用的必经中转** — 否决：god object；既成事实的传播由 EventBus 更合适。
- **各处直接 `ResourceLoader.Load`** — 否决：热更合并与启动期强校验失去唯一挂点。

## 后果

- 约束了服务间的调用形态：跨服务只经 `Xxx.Instance.Method(...)`，manager 声明为 `internal sealed`，跨服务代码里根本写不出对方 manager 的类型名。
- 使「新增一种内容类型 = 新增一个 `XxxData` 与一个仓储条目，不新增服务、不改调用方」成为可加性事实。
- 放弃了「某个系统直接改 profile 字段」这条捷径——一切写入都要组装 spec。
- 影响文档：`systems/architecture.md`（权威，「两条唯一入口 + 一个编排顶点」）· `systems/services/profile-service.md` · `systems/services/content-service.md` · `systems/game-progression.md`。
