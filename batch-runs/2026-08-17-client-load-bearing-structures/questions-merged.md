# 合并 interview 出题单

原始待决 **26 项**（S1 6 · S2 4 · S3 5 · S4 5 · S5 6）+ orchestrator 交叉核对新增 **2 项** → 去重合并后 **21 问**，分 4 轮。

## 交叉核对结果（orchestrator 独有产出）

| # | 交叉 | 结论 |
|---|------|------|
| X1 | S2「清单只缺两格」的缺口 B（`EncounterSpec` 承载，S2 不表态）↔ S5-3（加可空 `Encounter`，`EnemyInstance` 嵌其内） | **不矛盾，互补**：S2 留白 + S5 填。合并为一问 → Q5 |
| X2 | S3-②（`ProfileChangeSpec` 增 `EventStateChanges`）↔ S4-1（增 `PlotElements` + `ChangeElement` 增 `ApplyOp`） | **同一段代码块的同批两列**，两份各自说「第三度 / 第六列」实为同批。列数、断言写法、成本侧恒空断言必须一次定 → 合并为 Q6 |
| X3 | 五份各要求一次 schema bump（S1 / S2 / S3 / S4 / S5） | **无第二个合理选项** ⇒ orchestrator 直接按「合并为同一次 bump、同一段迁移说明」处理，不占 interview 名额，记入总报告 |
| X4 | S1-④（集合字段单复数）↔ S3-⑤（`eventOptions` 命名）↔ S5（`pastEvent.Enemy`） | S3-⑤ 与 S5 那一格由 S1-④ 的裁决统一覆盖 ⇒ S3-⑤ **消解**，不单独出题 |
| X5 | S1 独立发现「`looseCard` 缺增向 `Op`」+「`experiencePoint`/`faith`/`maleficQi` 缺 `CostKey` 成员」↔ S4-2/S4-3（`AddLooseCard` + `ApplyOp`） | **互相印证**（两个 worker 从两侧独立撞到同一裂缝，提高置信度）。S4-3 保留为定名题 → Q9；`CostKey` 三成员补登并入同问 |
| X6 | S5 指出：`Encounter` 嵌 `EventOption` ⇒ S3 的 `activeEvent` 存整份快照时**连带复制最胖载荷** | **新增交叉后果**，并入 Q5 一并裁（存档体积从 0.3–2 KB 上抬） |

## 轮次

**轮 1（🔴 权威归属 / 契约形状 / 硬冲突）**
1. S5-1 `PoolScope` vs `LocationData.EnemyTemplateIds` 权威归属（第二权威已落笔）
2. S1-④ 集合字段单复数（契约已冻结复数 path；错则后端复算静默失效）
3. S1-② `contentVersion` 类型统一（`string` vs `int`；B 为跨边界破坏性变更）
4. S2-1 outcome 定稿载体加不加（`Source.EventOutcome` 定义 vs 三处 resolver 注释硬冲突）

**轮 2（机制 / 承载形状）**
5. 事件进行中态的承载（S3-① + S5-3 + X1 + X6 合并）
6. `ProfileChangeSpec` 增列方案（S3-② + S4-1 + X2 合并）
7. S2-2 `combatTier` 落点
8. S5-4 `PlotModulation.EnemyPoolScope` 是否删除

**轮 3（命名 / 口径 / 落笔形态）**
9. S4-3 散牌增向定名 + `CostKey` 补登三成员（X5）
10. S1-① `chapterRetry` 命名
11. S1-⑤ Codex 条目类型 · S1-⑥ 索引表落笔形态
12. S1-③ `currentMana` 归属

**轮 4（轻量项打包）**
13–21：S2-3 · S2-4 · S3-③ · S3-④ · S4-2 · S4-4 · S4-5 · S5-2 · S5-5 · S5-6
