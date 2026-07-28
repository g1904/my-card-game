# Answer log service-api-contracts

- 日期：2026-07-27
- 来源：`90-inbox/solution-draft-service-api-contracts.md` → `10-handoffs/2026-07-27b-service-api-contracts.md`
- 移出条数：**5**（另有 4 条部分收窄，仍留在待答清单）

## 已答定（从 open-questions.md 移出）

**⚠ 服务 API 契约（七个服务的方法签名、参数 / 返回类型、事件负载 schema 未定义）** → 已定案：**八条契约总则** —— ① 三种方法形态按边界划分（A 同步直返 / B `Task<OpResult<T>>` + `CancellationToken` / C `Task<T>` 由信号推进；B、C 带 `Async` 后缀）；② 三种失败语义与 null-check 规则一一对应（必需缺失 `PushError`+抛 / 可选缺失 `TryXxx`+`PushWarning` / **业务失败返回 `OpResult` 绝不抛**）；③ 服务门面固定骨架（manager `internal sealed`、不暴露 manager 引用、不返回可变集合）；④ 启动契约（`_Ready` 只装配，I/O 归 `IBootstrappable.InitializeAsync`，由 Bootstrap 屏幕驱动）；⑤ EventBus 用 **C# 泛型 `event` + `readonly record struct` 负载**（不用 Godot `[Signal]`）；⑥ 物化模型；⑦ 后端接口化（四个窄接口 × Http/Offline 两份实现）；⑧ 结算阶段名取代事件自带钩子。另加共享核心类型（`OpResult` / `ApplyResult` / `ProfileChangeSpec` / 各枚举）、逐服务首版签名骨架、14 条 EventBus 负载 schema 与三条负载纪律、API 书写规范。（归档去向：`20-systems/architecture.md`「API 契约总则」为权威；摘要在 `20-systems/common-properties.md`；逐服务方法表在七份服务文档 + `plot-manager.md` 的「API 面（契约）」小节；代码形态在 `system-overview.md`。）

**`eventStart` / `eventEnd` 与 `AdvanceEvent` 的职责边界（谁写 CharacterProfile、谁扣成本、谁推拉隐藏属性、谁触发重算；签名与返回形态）** → 已答定：**`eventStart` / `eventEnd` 是 `AdvanceEventAsync` 内部结算流程的两个阶段名，不是 `AdventureEventData` 上的方法**（若是 `Resource` 虚方法，新增事件就要新建 C# 子类，可加性失效；且共享单例持中间态会跨事件泄漏）。落地为 `IEventResolver` 的两个实现（`CombatEventResolver` / `GenericEventResolver`）。职责边界由此完全明确：**扣成本、推拉隐藏属性、写 Profile 全由 life-cycle-service 经 ProfileManager 完成**，resolver 只描述结果。（归档去向：`20-systems/adventure-event/common-properties.md`「结算阶段」、`20-systems/services/life-cycle-service.md`、`combat-service.md`。）

**谁持有 `CombatResult` 并把它翻译成 Profile 变更** → 已答定：**`CombatResult.Spoils` 是一份 `ProfileChangeSpec`**——combat-service 只**描述**结果，life-cycle-service 在 `eventEnd` 阶段把它连同 `lifeSpanCost` 与隐藏属性推拉**合并为一次 `TryApply`**，从而「一个事件 = 一次事务 = 一个存档点」。战斗过程中的血 / mana 变更仍即时经 ProfileManager。（归档去向：`20-systems/services/combat-service.md`、`life-cycle-service.md`。）

**「服务之间不互相读写字段」与服务互相调用门面的张力** → 已答定：措辞收紧为 **服务之间不读写对方字段、不伸手进对方 manager；跨服务的方法调用（经 `Xxx.Instance.Method(...)`）允许**。编排顶点 game-progression 的定位不变（屏幕流程串联），但不再被读作「一切跨服务调用的必经中转」。这只是措辞澄清，不改变任何既定行为。（归档去向：`20-systems/architecture.md`、`20-systems/common-properties.md`、`20-systems/services/_index.md`、`system-overview.md`。）

**eventOptions 的持久化形态（存进 CharacterProfile 落地 vs 读档时按 seed 重算）** → 已答定：**落地物化后的定稿实例快照，不重算**。理由是物化用了 seeded RNG + 当时的角色状态 + 可被 overlay 热更的模板，而确定性只在同一 `contentVersion` 内成立；重算会导致「呈现时看到的事件」与「结算时执行的事件」不一致。这是用户「产出即定稿」裁决的直接逻辑后果，对应备选方案「只存 `EventId` 事后重算」已被明确否决。**剩余的快照字段形态 / schema 仍在待答清单。**（归档去向：`20-systems/services/future-event-service.md`、`20-systems/adventure-event/common-properties.md`。）

## 部分收窄（仍留在待答清单）

- **`EventOption` 的字段清单** —— 骨架九字段已定（`InstanceId` / `EventId` / `EventType` / `Priority` / `IsMandatory` / `SelectCost` / `SkipCost` / `IsRevealed` / `RevealedEventId`），先前问的「是否携带已结算的 cost 实例、Mystery 揭示状态」**答案是携带**；但「多数属性由物化决定」意味着还有一批未列出的字段，**完整物化字段清单**仍待一次内容侧 handoff。
- **`pastEvent` 的痕迹 schema** —— 持久化方式已定（存定稿实例快照、按 `InstanceId` 索引）；「如何区分进入并结算 vs 跳过」「存哪些字段」仍未定，并新增一条硬约束：快照体积影响增量 push 粒度。
- **成本 element 清单** —— 代码形态已定为 `ProfileChangeSpec`（element 带符号，成本与产出合一）；`CostKey` 的**成员清单**与「是否允许部分抵扣」仍未定。
- **产出侧的可负担性保证** —— 既然 `selectCost` 是物化时组装的，这条保证天然有落点（物化阶段对照 `CanAfford` 调整）；「要不要给这条保证」与兜底形态仍未定。
