# ADR-0078 — `EventOption.OutcomeSpec` 复用 `ProfileChangeSpec`、只开放三列；`AbilityElements` 只承载 `Op == Grant` 且作用域恒为 `Character`

- **状态：** Accepted
- **日期：** 2026-08-22
- **来源：** handoffs/2026-08-22-event-outcome-spec-fields.md

## 背景

事件产出要写进 Profile，而 Profile 的统一写入载体是 `ProfileChangeSpec`（十列）。产出侧只需要其中少数几列——是该新建一个窄类型，还是复用宽类型并约定其余列恒空？

## 决策

**`EventOption.OutcomeSpec` 复用 `ProfileChangeSpec`，不新建窄类型。** 只开放 **`Elements` / `AbilityElements` / `DeckElements` 三列，其余恒空**（逐列穷举的断言清单归 `systems/services/future-event-service.md`）。

**`AbilityElements` 只承载 `Op == Grant`**，且**作用域恒为 `Character`**、`Source == EventOutcome`——**事件产出不能给账号级法则或古宝**。

字段面 → `systems/adventure-event/common-properties.md`；定稿形态与断言清单 → `systems/services/future-event-service.md`。

## 理由

成本与产出共用一个类型是既定形态，且 `SelectCost` 已经示范了「复用宽类型 + 恒空列断言」这个模式。新建窄类型会让同一条 element 在两个类型之间转换，转换处就是漏字段的地方。

作用域恒为 `Character` 是承重：账号级资产（法则、古宝）的授予渠道受 `ExclusiveSource` 与残卷机制约束（→ `ADR-0049`、`ADR-0051`），若事件产出可以直接给，那两套约束全部旁路。

## 备选方案

- **新建窄类型 `EventOutcomeSpec`** — 否决：转换处漏字段，且与 `SelectCost` 的既有形态不一致。
- **`AbilityElements` 允许 `Op == Remove`** — 否决：置换 / 禁用候选**前移到物化时掷定**，落 `EventOption.AbilityChangeSlots`，不由 `OutcomeSpec` 承载。

## 后果

- `ProfileChangeSpec` 的 element **只装已定稿的最终账**——这条与物化模型一致（→ `ADR-0012`）。
- 恒空列的断言在物化期执行，违反即拒绝整批。
- `common-properties.md` 侧只回链，不复述逐列穷举（→ `ADR-0057`）。
