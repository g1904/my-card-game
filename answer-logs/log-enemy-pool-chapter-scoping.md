# Answer log enemy-pool-chapter-scoping

- 日期：2026-08-22
- 来源：`inbox/solution-draft-enemy-pool-chapter-scoping.md` → `handoffs/2026-08-22-enemy-pool-chapter-scoping.md`
- 移出条数：1

**敌人池的篇章框定载体未定（08-17 新增 · 承重）** → 载体 = `EnemyData` 上与 `EncounterScopes` 平级的顶层字段 `ChapterScope : int[]`（取值 `1..3`，对位 `CharacterProfile.chapter`；**空 = 不限，三章通用**，与 `PlotArcData.ChapterScope` 同名同义）。取池第三层落成一行 `Length == 0 || Contains(currentChapter)`，入参是单值 `int`。通用池空池校验由单维扩到 `(combatTier × 篇章)` 九组合，通用池判据保留「`PoolScope == null` 或两字段皆空」，`Finale` 三格放宽为「该组合下的池（含专属条目）非空」；新增两条加载期校验（越界 `PushError` / 重复值 `PushWarning` 且只告警不改条目）。连带就地订正 `EncounterScopes` 为 `CombatTier[]` / `{ Practice, Standard, Finale }`。（`systems/enemies/_index.md`、`systems/enemies/common-properties.md`、`systems/services/future-event-service.md`、`terminology.md`）

> 剩余部分：字段命名 `ChapterScope` 是否会与 `PlotArcData.ChapterScope` 造成跨类型混淆，为 `[采纳推荐 — 待复核]`，**仍留在待答清单**，不随本次移出。
