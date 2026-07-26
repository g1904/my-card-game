# balance

> 可调的全局数值：life / mana 基线、ante 曲线、掉落权重、重试上限等。系统从数据（`.tres`）读取，不硬编码。

## 意图
> _从 handoffs 中提炼的设计意图。保持更新。_

- **炼气期战斗基线（起始满值）：** 生命 life = **10 / 10**、法力 mana = **5 / 5**。mana 采用**无曲线 · 上限 + 逐步恢复**模型（见 `20-systems/character-profile/mana.md`）。这些是可调数值，存入 `.tres` 而非硬编码。Source: `10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。
- **寿元预算与消耗（可调数值）：** 炼气起始寿元 = **100**、抵达筑基 **+100**（累计 200）、抵达金丹 **+300**（累计 500）、抵达元婴 **+500**（累计 **1000**）（隐藏属性；递减到 0 → defeated，见 `20-systems/services/plot-manager.md`）。消耗侧：每个 AdventureEvent 的 `lifeSpanCost` **基准 = -1**（完成一个事件默认消耗 1 点寿元），个别事件可覆写。预算增量与 `lifeSpanCost` 基准均为可调数值，存入 `.tres`。Source: `10-handoffs/2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md` + `10-handoffs/2026-07-25b-event-cost-fields-capability-flags-and-service-hierarchy.md`。
- **元婴 +500 无玩法影响（阶梯闭合项）。** 抵达元婴 = 第三篇章通关 = **游戏终点**（四境三篇章，见 `20-systems/game-progression.md`），run 到此结束——因此 +500 **不产生任何可消耗的寿元预算**，只是**最后一次数值更新并存档**。它是形式上的阶梯完整性，**不是平衡杠杆**：调整它不改变任何一局的可玩长度。Source: `10-handoffs/2026-07-25b-event-cost-fields-capability-flags-and-service-hierarchy.md`。
- **平衡数值集中管理。** 可调数值（life / mana 基线、寿元预算、ante 曲线、掉落权重、重试上限、缩放）存放在导出字段或专门的平衡资源中，系统从数据中读取——与 `data-resource-rules.md` 一致。Source: `10-handoffs/2026-07-24-docs-restructure-class-model.md`。

## 决策(-> ADR)
> _已敲定的决定链接到 50-decisions/ADR-####。_

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **mana 逐步恢复速率 / 上限成长：** 每回合恢复量（固定 +N？按比例？）、manaLimit 随境界成长、更高境界（筑基 / 金丹 / 元婴）的 life / mana 基线待定（炼气仅给了 10/10 · 5/5）。→ `20-systems/character-profile/mana.md`。Source: `10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。
- **寿元 `lifeSpanCost` 分档待定：** 基准 -1 已定；仍待定：哪些事件类型 / 具体事件应覆写为更大 / 更小 / 正值（回寿），及其分档表。→ `20-systems/adventure-event/`。Source: `10-handoffs/2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md`。
- **成本类型的 element 清单与数值分档未定：** `selectCost` 已定为**定制复合成本类型**、`lifeSpanCost` 为其一个 element（基准 -1）；其余 element（gold / mana / 道具 / 隐藏属性推拉？）、各 element 的数据形态与基准分档、以及 `skipCost` 的数值取向均未定。→ `20-systems/adventure-event/common-properties.md`。Source: `10-handoffs/2026-07-25b-event-cost-fields-capability-flags-and-service-hierarchy.md`。
- **元婴 +500 的用途待定：** 既然无玩法影响，最终寿元值是否被终局结算 / 成就 / 排行读取？若否，是否值得保留该字段更新？→ `40-ux/screen-flow.md`。Source: 同上。
- **重试上限是否作平衡项再调：** 无限 / 3 / 1 已定案（`20-systems/services/life-cycle-service.md`）；若后续视作可调平衡项则归此。
- **blind / ante 缩放曲线：** 具体 ante 缩放 / blind 要求 / 奖励曲线尚未陈述（进程语义见 `20-systems/game-progression.md`）；一旦落定，数值归此。Source: `10-handoffs/2026-07-24-docs-restructure-class-model.md`。

## 对应
提炼至：`.claude/knowledge/data/_index.md`（引用层，待建）。
