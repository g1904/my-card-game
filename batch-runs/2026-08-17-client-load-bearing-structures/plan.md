# Batch run — 客户端承重结构面五项方案草稿

- 日期：2026-08-17
- 技能：`/batch-provide-solution-draft`
- 库：`game-design-documents/`（客户端，单库；五项均无跨边界成分——Profile schema 的上行字段面权威在后端契约，但本批只写客户端侧的字段定义，契约侧已成文，故不触发对侧落笔）
- 用户圈选范围：A+B+C（主题 1–5）

## 分片与 slug 分配（写入面互不重叠）

| 分片 | 问题 | 预分配 slug | 独占写入文件 |
|------|------|-------------|--------------|
| S1 | `CharacterProfile` / `PlayerProfile` 字段 schema | `profile-field-schema` | `inbox/solution-draft-profile-field-schema.md` |
| S2 | `EventOption` 完整物化字段清单（含 `lifeSpanCost` 形态 / `combatTier` 落点 / outcome 权重 / `PlotModulation` 复核） | `event-option-materialized-fields` | `inbox/solution-draft-event-option-materialized-fields.md` |
| S3 | 结算进行中的 `EventOption` 派生实例如何落存档 | `event-option-derived-persistence` | `inbox/solution-draft-event-option-derived-persistence.md` |
| S4 | element 层三缺口：`ApplyOp` 列 · 游离散牌入组载体 · `plotKeyPoint` 集合型形态 | `element-carrier-gaps` | `inbox/solution-draft-element-carrier-gaps.md` |
| S5 | 抽取池共用形态（残卷 / 礼包 / 置换）+ `PoolScope` + `EnemyInstance` | `draw-pool-and-instance-shapes` | `inbox/solution-draft-draw-pool-and-instance-shapes.md` |

**共享台账**：`inbox/_index.md` 由 orchestrator 收尾统一写（worker 契约 ②）。

## 波次

全部 5 个分片**并行一波**——写入面完全不重叠。

## 预判的跨分片交叉（收尾必须核对）

- **S2 ↔ S3**：同一对象 `EventOption`。S2 定字段清单、S3 定派生实例承载。二者若对「派生是否替换当前批中的原实例」「`IsRevealed` / `RerolledCount` 的读取方」给出不同结论 → 🔴 进 interview。
- **S2 ↔ S4**：`lifeSpanCost` 形态（定值/区间/公式）与 element 层的 `ApplyOp` 语义可能互相约束。
- **S1 ↔ S3**：`CharacterProfile` schema 是否需要为「当前批 + 派生」留一格 → 两份必须一致。
- **S1 ↔ S4**：`plotKeyPoint` 的集合型载体与 `CharacterProfile` 的 `plotKeyPoint` 字段形态须一致。
- **S5 ↔ S1**：`PoolScope` / `EnemyInstance` 若落存档，须与 S1 的 schema 对齐。
