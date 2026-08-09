# Answer log past-event-trace-schema

- 日期：2026-08-09
- 来源：`inbox/solution-draft-past-event-trace-schema.md`（`/provide-solution-draft` 产出，用户已于 2026-08-07 逐项裁决）→ `handoffs/2026-08-09c-past-event-trace-schema.md`
- 移出条数：**1**（另 3 条收窄、1 条新增）

## 逐条移出

**`pastEvent` 的痕迹 schema（`open-questions/02-event-options.md`）** → **四个子问题一次性全部答结**（`systems/adventure-event/common-properties.md` 新增「`pastEvent` 的痕迹 schema」小节 + `## 决策` 的 ADR 候选行）：

- **① 快照存哪些字段** → **判据先于字段表**：「重算不出来的存，重算得出来的不存」。文本类字段（显示名 / 描述 / 图标 / **风味文案**）一律留在模板侧，快照里一个字符串正文都不存；物化产出的数值（`SelectCost` / `Priority` / Mystery 真身 / 敌人赋级）必存。条目类型 **`PastEventEntry`（13 字段）= 定稿实例快照 + `AppliedChange`（`eventEnd` 那一次合并 `TryApply` 的最终 spec，复用 `ProfileChangeSpec`，不引入新类型）**；`EventOutcome` 定为四值（`Resolved` / `CombatWon` / `CombatLost` / `Aborted`）；**`LifeSpanAfter` 收下并写明为判据的明示例外**。（归档去向：`systems/adventure-event/common-properties.md`、`systems/character-profile/_index.md`、`terminology.md`、`systems/architecture.md` 总则 6 推论 1）
- **② 未被选中的选项是否归档** → **归档轻摘要 `UnchosenOptionRef`**（`InstanceId` / `EventId` / `EventType` / `Priority`，~240 B / 事件）。依据：**「定稿实例必须落存档」对未选项不成立**——未选项永不被消费，只需**可回溯**而非**可重建**。副产品：`pastEvent` 由一串孤立事件升为一串**批次**。（归档去向：同上 + `systems/services/plot-manager.md`）
- **③ 与 AdventurePlot key points 的耦合方式** → **零结构耦合、单向只读**：`pastEvent` 不持有 key point 引用，key points 也不引用 `PastEventEntry`；PlotManager 经既有的 `ModulateEventOptions` 只读访问，派生索引读时计算、不落存档。**推论：本 schema 不被「key points 粒度」阻塞。**（归档去向：`systems/services/plot-manager.md`）
- **④ 快照体积对增量 push 粒度的影响** → **不影响**：单事件 ≈ **770 B**，落在既有 ~2 KB 预算内；整轮回 200 事件 ≈ 150 KB。新增两条明文：**`pastEvent` 只追加、不修改既有条目**（不变式）与**软上限告警**（条数 > 500 或序列化 > 512 KB → `GD.PushWarning`）。**明确否决**分页 / 冷热分离 / 独立存档段。（归档去向：`systems/services/sync-service.md`）

## 收窄（仍待答）

- **`EventOption` 的完整物化字段清单** → **「风味文案是否也物化」这一半已答结（不物化，跟随模板数据）**；剩余分叉只在数值与结构字段上，**不含任何文本类字段**。条目仍留在 `02-event-options.md`。
- **`CostKey` 的其余 element 与数据形态** → 语义不变，但**追加一条边界要求**：它与「每批 eventOptions 数量」共同决定 ~770 B 估算是否需复核。
- **PlotManager 的「数据编码与 key points 粒度」** → 与 `pastEvent` 的耦合方式已答定，本条**不再阻塞 `pastEvent`**，且不得以「让 key point 引用 `InstanceId`」的形态回答。

## 新增待答

- **物化后敌人实例的类型形态**（`EnemyInstance` 嵌在 `EventOption` 上还是只记引用）→ `02-event-options.md`。**不阻塞 `pastEvent` 的最小面已定**：至少存 `EnemyTemplateId` + 物化赋级 `Level`。

## 未被本次触及

`ADR-0003` / `ADR-0004` 未被触及；push 粒度、断线降级、`revision` / `pushId` 契约全部原样成立；`02-event-options.md` 其余 9 条不变。
