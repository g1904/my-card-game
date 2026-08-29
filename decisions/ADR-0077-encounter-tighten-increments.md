# ADR-0077 — `PlotModulation.Tighten` = 五格带方向约束的增量；对 `Finale` 整档豁免；不进 `EncounterSpec`、不落存档

- **状态：** Accepted
- **日期：** 2026-08-22
- **来源：** handoffs/2026-08-22-encounter-tighten-fields.md

## 背景

剧本需要一条给战斗加压的通道。最直接的形态是让剧本**覆写** `EncounterSpec` 的字段（把敌人换成更强的、把回合上限调低）。但覆写意味着剧本可以把任何遭遇改成任何样子，而赋级带 `±2` 的硬规则（→ `ADR-0044`）当场失效。

## 决策

`PlotModulation.Tighten` 的类型是 **`EncounterTighten` —— 五格带方向约束的增量，不是绝对覆写值**。「更紧」落成 `min` / `max` 极值算子。

**`Tighten` 对 `Finale` 整档豁免**——剧本要加压 Finale，**只能走敌人侧的两个字段**。

**`EncounterTighten` 本身不进 `EncounterSpec`、不落存档。**

字段面与止于五格的两条判据 → `systems/services/plot-manager.md`；消费侧 → `systems/services/combat-service.md`。

## 理由

增量 + 方向约束使剧本**只能加压不能减压**，且加压幅度受格值上限约束——赋级带与数值安全性因此不受剧本影响。极值算子（而非加法）保证多条 arc 同时生效时结果仍在约束内。

Finale 豁免：Finale 是篇章的能力检查点（→ `ADR-0065`），它的难度必须由平衡面独占决定；允许剧本加压等于让某些剧本线不可通关。

不落存档：`Tighten` 是**每次生成时现算**的调制结果，落存档会让它与剧本状态漂移。

## 备选方案

- **绝对覆写值** — 否决：赋级带硬规则失效。
- **加入 `Enemy` / `Tier` / `FirstSide` 三格** — 否决：无难度全序，「更紧」在这三格上无定义。
- **加入 `RewardPoolId` / `BaseReward`** — 否决：属产出侧，不是加压。
- **加入疲劳量** — 否决：无覆写基准（疲劳是全局常量，→ `ADR-0052`）。

## 后果

- 五格是封闭的：新增一格必须先回答「更紧在这一格上是什么方向」。
- 剧本对战斗的全部影响面收敛为这五格 + 敌人侧两个字段。
- 六个界常量的取值属统计校准面，本 ADR 只定结构。
