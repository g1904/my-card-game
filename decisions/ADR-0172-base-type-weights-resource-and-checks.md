# ADR-0172 — 五类事件基础权重落 `BaseTypeWeightsData`：三章各一行、三条加载期校验、刻意不校验和为一

- **状态：** Accepted
- **日期：** 2026-09-06
- **来源：** handoffs/2026-09-06-event-type-mix-ratios.md · answer-logs/log-event-type-mix-ratios.md

## 背景

`BaseTypeWeights` 是 eventOptions 生成管线第 ① 步的输入，此前只有形态没有取值，四处文档各自登记着同一个缺口。旧的候选初值（`Combat 0.28` / `Exchange 0.39`）还与「Combat 是最高频的一类」这条既有定性正面矛盾。

## 决策

**五格初值定案 `Combat 0.35` / `Research 0.13` / `Explore 0.13` / `Exchange 0.32` / `Travel 0.07`；三章同值，但仍写三行。**

**载体 = 新开一份平衡资源 `BaseTypeWeightsData`**（五个具名 `float`，经 `Content.Single<T>()` 取，**不接受任何覆盖参数**）。

**加载期三条校验**，且**刻意不校验「五格和 = 1」**——与 `BatchSizeWeights` / `EnemyLevelRange` 的权重表在这一点上相反，故必须写明。

**`Finale` 不作任何扣除**：它在第 ④ 步之前旁路、恒占一个槽位；`Combat` 那一格只标定非 Finale 的战斗。

**`Combat 0.35` 与 `Exchange 0.32` 差 0.03 是刻意取小**，为的是保住「Combat 是最高频的一类」这条定性；**如实写下：不含 `Finale` 的 ch1 整数构成是 10 : 10 平手**——承重的是权重表的大小关系，不是这一格的取整结果。

逐格取值、三条校验全文与「供给分布 ≠ 实现分布」的校准须知 → `systems/balance.md`。

## 理由

- **不校验和 = 1**：归一化发生在类型分布层，权重表只表达**相对大小**；强制和为一会让「只想调高某一类」变成必须同时改另外四格。
- **三章同值仍写三行**：分格轴取「篇章」是本库节奏旋钮的标准分格维度，服务侧只读当前篇章那一行；写成一行会在日后分章时逼出一次结构改动。
- **不接受覆写**：本表是节奏的地基，`EncounterSpec` 一类的局部覆写会让「这一章的类型分布」变成不可预测的量。
- **`Finale` 旁路**是 `Combat` 格语义的定义部分——不写明，读者会把 Finale 的那一次算进 0.35 里，整章事件数当场偏。

## 备选方案

- **旧初值 0.28 / 0.14 / 0.14 / 0.39 / 0.05** — 否决：与「Combat 最高频」的既有定性矛盾。
- **逐章分行给不同值** — 否决：为估算量做分化 = 把噪声焊进配置。
- **并入 `LifeSpanCostTableData`** — 否决：行粒度不同、三问判据不同住。
- **`Travel` 填 0** — 否决：被 `> 0` 校验拦下，且「自愿换图」这条路径被预设存在。
- **每章硬性配额** — 否决：撞「本服务不持有跨批次状态」。

## 后果

- **本表是供给分布，不是实现分布**——实际出现次数还要过条目池组成与 `SelectionWeight`，验收时不得直接拿本表的比例去对实测。
- **四处待决登记就此关闭**（`adventure-event/_index.md` · `adventure-event/common-properties.md` · `services/future-event-service.md` · `balance.md`）。
- 受约束的文档：`systems/balance.md` · `systems/adventure-event/_index.md` · `systems/adventure-event/common-properties.md` · `systems/services/future-event-service.md` · `systems/game-progression.md` · `decisions/ADR-0026-event-generation-weighting-pipeline.md` · `decisions/ADR-0074-balance-resource-is-the-only-config-layer.md`。
