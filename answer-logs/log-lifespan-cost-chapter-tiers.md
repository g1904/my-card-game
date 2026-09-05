# Answer log lifespan-cost-chapter-tiers

- **日期：** 2026-09-03
- **来源：** `inbox/solution-draft-lifespan-cost-chapter-tiers.md` → `handoffs/2026-09-03-lifespan-cost-table-and-budget-scale.md`
- **移出条数：** 2 全条 + 1 部分

> 结论的权威归属在括注的主题文档 / ADR；本 log 只是移出记录。

## 移出条目

- **各篇章 `lifeSpanCost` 的具体分档表——哪些事件类型多耗、单次幅度各是多少（须与 `eventCountLimit`、战斗失败期望扣减一同反推）**（`open-questions/04-hidden-attributes-plot.md`）
  → **全条答定。** 定价形状 = `round(t(type) × λ(chapter))`；耗时台账 `t` 七行（2.0 / 2.5 / 3.0 / 2.8 / 1.6 / 1.0 / 0.4 分钟）；λ = 23 / 25 / 63；21 格 = 46/50/126 · 58/63/158 · 69/75/189 · 64/70/176 · 37/40/101 · 23/25/63 · 9/10/25，半值四舍五入向上。三个旋钮的联合反推式与八个输入（含两个标注为待实测的标定假设）连同 ch1 收支校验（25 批次 / 39.3 分钟 / 支出 904 / `C1` = 136）一并落表。载体 = `LifeSpanCostTableData`（独立 `ISingletonContent`），三条加载期校验。
  （`systems/balance.md` — 定价表本体 · 耗时台账 · 反推式 · 载体与校验；`systems/adventure-event/common-properties.md` — 相对关系与偏移幅度）

- **`lifeSpanCost` 定价表的 Explore 行取值**（`open-questions/02-event-options.md`）
  → **全条答定。** Explore 行 = **37 / 40 / 101**，由 `t(Explore) ≈ 1.6` 按整个条目池的真身分布期望标定（揭示转场 0.1 + 0.5 × Combat 加权 2.25 + 0.3 × Exchange 1.0 + 0.2 × Travel 0.4）。「设计期按真身分布期望标定 ≠ 运行期按真身取价」的区分同批写进 `explore/_index.md`。
  （`systems/balance.md`、`systems/adventure-event/explore/_index.md`）

- **闭关构筑面板的两个数值格**（`open-questions/03-adventure-event-types.md`）
  → **部分答定。** ② 开局构筑条目 `lifeSpanCost = 0` 的覆盖登记 —— 已随定价表在 `balance.md` 下方登记为该表在内容侧唯一在案的覆盖值，`research/_index.md` 互相回链。**① 走火入魔风险档候选的出现权重仍待答**，条目保留、改写为只剩一格。
  （`systems/balance.md`、`systems/adventure-event/research/_index.md`）

## 同批的既定决策改写（不是问题的答定）

- **`lossPerMomentum` ch1 由 1 改为 10** —— 这不是一条待答项的答定，而是**推翻既定的锁定值**：寿元量纲 ×10 而道念量纲不变，系数留在 1 会使形状锚（一次带内最坏落差的失败恒落本章可用预算的 8%–12%）当场破。用户确认后就地改写 `decisions/ADR-0018-momentum-scoring-model.md` 与 `decisions/ADR-0127-life-merged-into-lifespan.md` 的正文论证，并在 `scoring.md` / `life-span.md` / `combat/_index.md` / `combat-ux.md` / `balance.md` 同批改写。ch2 / ch3 取 5 / 10（候选值，定案仍归它自己那条待答项）。
- **寿元预算四格 ×10**（1000 / +1000 / +3000 / +5000）—— 取向裁决，波及 21 份活文档；`ADR-0031` / `ADR-0045` / `ADR-0127` 三份 ADR 的数字同批订正。
- **ch1 经验阈值曲线 79 → 55** —— 阈值是事件数的从属量，事件数下修后的重算，不是新决策。
