# Answer log fatigue-in-encounter-tighten

- 日期：2026-08-30
- 来源：`inbox/archive/solution-draft-fatigue-in-encounter-tighten.md` → `handoffs/2026-08-30-fatigue-not-in-encounter-override.md`
- 移出条数：1

## 移出的条目

**疲劳扣减是否进 `EncounterSpec` 覆写组（08-27 重开）** → **维持不进覆写组，也不开 `EncounterTighten` 第六格。** 三条既有理由重估结果：① 仍成立且被加强（削堆条目只是又一个**内容侧**决定因素，档位侧仍是零条）；② 仍成立（「`MoveCard` 能搬对手抽牌堆」本就写在这条理由的正文里，不是新事实；重开判据 ① 要的是**已签核条目**，而 `content/` 零条目 ⇒ 判据字面未触发）；③ 结论不变、论据改写为「常规抽牌预算已被覆写组三格 + `Tighten` 两格覆盖，`DrawEffect` 能抬高实际抽牌次数但逐条有限，终止性由 `TurnLimit` 独立封顶」。另新增第 ④ 条独立否决论据「方向不单调」（过不了 `EncounterTighten` 的全序 + 单调难度方向判据）。原重开判据 ②「某个遭遇档需要显式调节疲劳压力」由三条既有承接通道表取代；判据 ① 收紧为「`Pool` 覆盖敌人侧、以削堆为主要效果、**已签核**的条目，且密度足以让一方在 `TurnLimit` 前 40% 内空堆」，并明写结构可写性不构成触发。零字段、零数值、零存档改动。（归档去向：`systems/balance.md`）

## 同批裁决（本身不在待答清单上，故不计入移出条数）

- **`ADR-0052` / `ADR-0077` / `systems/services/plot-manager.md` 三处「无覆写基准可拧」是否改写** → **三处均不动。** 该句在原文语境里正确（破折号从句已界定「覆写基准」= per-encounter 基准），且不存在支撑改写的新事实。新论据只进 `systems/balance.md`，与既有论据并行共存。
- **`ModifierTarget.FatigueAmount` 是否限定为只能下调** → **保持双向，不加方向约束**（用户确认，此前为「采纳推荐 — 待复核」）。落地面是零动作；结论以一句话写进 `systems/balance.md` 的承接通道表。

## 未随本次移出

- **`MoveCardEffect` 缺一格方位声明**（`ADR-0119` 断言 `From` 可取对手抽牌堆，但原语表未给它 `Side : SideConstraint`）—— 本次**新增**进待答清单，见 `open-questions/01-combat.md`「结构与配置的残留」。
- **卡组规模的实际取值**、**疲劳的呈现** 两条与本题相邻，原样留在待答清单。
