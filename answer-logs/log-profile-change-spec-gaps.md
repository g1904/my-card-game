# Answer log profile-change-spec-gaps

- **日期：** 2026-08-19
- **来源：** `inbox/solution-draft-profile-change-spec-gaps.md` → `handoffs/2026-08-19-profile-change-spec-gaps.md`
- **移出条数：** 4（分片条目）+ 10（本次 interview 答定项）

> 结论的权威归属在括注的主题文档；本 log 只是移出记录。

## 移出条目（来自 `open-questions/`）

- **`activeCombat` 的写入通道未明写** → 收进既有的 `EventStateChanges`（`EventStateKey` 追加一员 + 载荷加第三个具名可空格）；六面全对齐 ⇒ 判据要求不分列。两个中间态字段仍不合并，共用的只是通道（`systems/architecture.md`、`systems/services/profile-service.md`、`systems/services/combat-service.md`、`systems/character-profile/_index.md`）。来源分片：`open-questions/05-service-contracts.md`。
- **RNG 状态的写入通道形态未定** → 另开一列 `RngElements`（按子流枚举键的双标量 upsert，不配表、`Seed` 不进 spec）；不变式由 SeedManager 清账 + 组装方 `#if DEBUG` 比对机械保证；连带删除 `ActiveCombat.rng` 三格（`systems/architecture.md`、`systems/services/profile-service.md`、`systems/services/life-cycle-service.md`、`systems/services/combat-service.md`）。来源分片：`open-questions/05-service-contracts.md`。
- **`pastEvent` 的追加没有 spec 列** → 另开一列 `TraceElements`（序列尾部只追加，载荷直接是 `PastEventEntry`）；「记入 `pastEvent`」并入收口那一次 `TryApply`，三份结算流程图同改（`systems/architecture.md`、`systems/services/profile-service.md`、`systems/services/life-cycle-service.md`、`systems/adventure-event/common-properties.md`）。来源分片：`open-questions/05-service-contracts.md`。
- **收口时的只读投影设施形态（`Project(spec)` 的语义面）** → 与 `TryApply` / `CanAfford` 共用同一段 `Evaluate(spec)`；做钳制、不判终态；判负照常重算并提交；一次性视图（`systems/services/profile-service.md`、`systems/services/life-cycle-service.md`）。来源分片：`open-questions/02-event-options.md`。

## 本次 interview 答定项

- **`Project` 的签名形态** → 直返形态的 `Project(spec)` + `PushError` + `throw`（必需缺失，落总则 2 第一档）；废弃 `bool TryProject(..., out ...)`（`systems/services/profile-service.md`）。
- **投影一次性纪律的分级** → 跨 `await` 持有做到第 1 级（`ref struct` 包装）；「`Project` 之后改了重算依据列」留第 3 级（`systems/services/profile-service.md`、`systems/services/life-cycle-service.md`）。
- **`AppliedChange` 的「恒不含」断言范围** → 只覆盖 `TraceElements`，`RngElements` 照常入账（`systems/adventure-event/common-properties.md`）。
- **累加进 `AppliedChange` 的列剔除清单** → 装「账本本身」的列（当前即 `EventStateChanges`）不累加，只累加变更（`systems/adventure-event/common-properties.md`、`systems/services/profile-service.md`）。
- **`SeedManager` 清账断言的检查点** → 决策点持久化前的组装方，不落 `ProfileManager` 入口、不落子流取用前（`systems/services/life-cycle-service.md`、`systems/services/combat-service.md`）。
- **`ProfileChangeSpec` 的可变性形态** → `sealed record` + `with` 派生，各列仍只读；否决 Builder 与可变列（`systems/architecture.md`）。
- **`Seq` 的起始值** → `0`，并在痕迹 schema 明写；追加连续性由入口校验（`systems/adventure-event/common-properties.md`、`systems/character-profile/_index.md`）。
- **`DrawCount` 单调不减校验的适用范围** → 只约束轮回进行中的 upsert；子流初始化与篇章重试的整流重置不走本列，不开例外口子（`systems/services/profile-service.md`、`systems/services/life-cycle-service.md`、`systems/character-profile/_index.md`）。
- **`Aborted` 痕迹与轮回结束统计的提交笔数** → 同一次 `TryApply`，不新增存档点（`systems/services/life-cycle-service.md`、`systems/adventure-event/common-properties.md`）。
- **三级判据第六面的措辞** → 「键与载荷的形状」= 访问形态 + 键的取值空间 + 载荷的字段集合，三样全同才算对齐（`systems/architecture.md`）。

## 仍留在待答清单

- `Project` 的第二个消费点（出现时须同批复核缓存问题）。
- 战斗之外四类事件的决策点清单（不阻塞本次三条通道）。
