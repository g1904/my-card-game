# Answer log eventcountlimit-plot-modulation

- 日期：2026-08-22
- 来源：`inbox/solution-draft-eventcountlimit-plot-modulation.md` → `handoffs/2026-08-22-eventcountlimit-plot-modulation.md`
- 移出条数：1

---

**`eventCountLimit` 能否被剧本调制（PlotManager / AdventurePlot 推拉地域配额）？** → **不可调制。** `PlotModulation` 不加第七个字段，`eventCountLimit` 恒为内容侧定值。零结构增量：不新增字段 / 枚举 / 合并算子行 / 加载期校验，不 bump 存档 schema，抬升判据 (b) 不松动。剧本仍可经 `TypeWeights[Travel]` **加速离开**，但**不能延长停留**。（归档去向：`systems/game-progression.md`「`eventCountLimit` 达成 → 本批只剩 Travel」小节 + `systems/services/plot-manager.md` 权力面逐条投影表）

**剩余部分：** 「不可调制只约束剧本层、overlay 照常可改」这一半为 `[采纳推荐 — 待复核]`，**仍留在待答清单**（落 `open-questions/02-event-options.md`）。各 location 的 `EventCountLimit` 具体取值归 ch1 数值标杆专场，本次未答、也不受本条阻塞。
