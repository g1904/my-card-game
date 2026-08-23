# Answer log encounter-tighten-fields

- 日期：2026-08-22
- 来源：`inbox/solution-draft-encounter-tighten-fields.md` → `handoffs/2026-08-22-encounter-tighten-fields.md`
- 移出条数：2

**`EncounterTighten` 的字段面未定（合并算子表里 `Tighten` 一行只能写「逐字段取更紧」）** → 定为**五格带方向约束的增量** `TurnLimitDelta` / `WinMarginDelta` / `InitialDrawDelta` / `DrawPerTurnDelta` / `HandLimitDelta`（默认皆 `0`，整体默认 `null`）；「更紧」落成极值算子——四格取 `min`、`WinMarginDelta` 取 `max`；`Tier == Finale` 整档豁免；加载期方向 / 上界校验四条，物化期五条下界钳制；十个界常量同住 `CombatRulesData`。（归档去向：`systems/services/plot-manager.md` 持合并算子与类型形态 · `systems/services/combat-service.md` 持 `EncounterSpec` 形状 · `systems/balance.md` 持十个常量取值）

**`EncounterSpec` 的可空覆写组两份文档口径矛盾**（`balance.md` 写「抽牌数与手牌上限可覆写」，`combat-service.md` 的 record 上没有这三格） → **以 `balance.md` 为准**，`InitialDraw` / `DrawPerTurn` / `HandLimit` 三格 `int?` 补进 `EncounterSpec`，字段形状权威归 `combat-service.md`。（归档去向：`systems/services/combat-service.md`、`systems/balance.md`）

> 剩余未答定：三格牌流量的六个界常量取值、`EnemyManaLimit` 初值 `5` 的校准——两条均归 ch1 数值标杆专场，**只欠标定、不欠结构**，已作为新增待答项留在清单上。
