# Answer logs — 已答定问题的归档台账

待答清单（`open-questions.md` 索引 + `open-questions/` 分片）只跟踪**仍待答**的问题。一旦某个问题被拍板，它就从那份清单**移出**，并写入本文件夹的一份 `log-<draftSuffix>.md`。

## 命名：`log-<draftSuffix>.md`

`draftSuffix` = 触发本次移出的那份输入的后缀：

- 处理 `inbox/draft-<suffix>.md` → `log-<suffix>.md`。草稿后缀**含序列字母**（`MMDD` + `a`/`b`/`c`…，见 `../inbox/_index.md`），**原样照抄**：`draft-0816a.md` → `log-0816a.md`。
- 无草稿来源（粘贴文本、或 `/summarize-open-questions` 独立运行）→ 用当天 `MMDD`（**不加序列字母**——没有草稿序列可跟随，且这样一眼可区分「有草稿来源」与「无」）；若同名已存在，追加 `_2`、`_3`。
- `_2` / `_3` 是**同名冲突**后缀，与 `a`/`b`/`c` 的**同日序列**后缀是两套东西，不要混用。
- **每次移出新建一个文件**，不追加进旧 log。一次运行若没有任何问题被答定，则不建文件。

## 内容形态

每份 log 是一次移出的快照：日期、来源 handoff / 草稿、以及逐条「问题 → 结论（归档去向）」。log 是**只读的历史记录**，不是权威——结论的权威归属仍在各主题文档的 `## 决策` / `## 意图` 与 `decisions/ADR-*`。

## 台账

**本表是索引，不是台账正文**（`decisions/ADR-0005`）：每行只写 log 文件、日期、来源 handoff、移出条数。
逐条结论、论据与口径**只活在各 log 文件自身**，本表不复述——要看某次移出了什么，点开那份 log。
（瘦身前本表每行都复述了整段叙述；那些叙述已原样并入各 log 文件的 `## 台账原记` 一节。）

| Log | 日期 | 来源 | 移出条数 |
|-----|------|------|----------|
| `log-draw-pool-and-instance-shapes.md` | 2026-08-17 | `inbox/archive/solution-draft-draw-pool-and-instance-shapes.md` → `handoffs/2026-08-17k-draw-pool-and-instance-shapes.md` | 3 完整 + 1 部分 |
| `log-event-option-derived-persistence.md` | 2026-08-17 | `inbox/archive/solution-draft-event-option-derived-persistence.md` → `handoffs/2026-08-17j-event-option-derived-persistence.md` | 1 |
| `log-event-option-materialized-fields.md` | 2026-08-17 | `inbox/archive/solution-draft-event-option-materialized-fields.md` → `handoffs/2026-08-17i-event-option-materialized-fields.md` | 4 |
| `log-profile-field-schema.md` | 2026-08-17 | `inbox/archive/solution-draft-profile-field-schema.md` → `handoffs/2026-08-17h-profile-field-schema.md` | 10 |
| `log-element-carrier-gaps.md` | 2026-08-17 | `inbox/archive/solution-draft-element-carrier-gaps.md` → `handoffs/2026-08-17g-element-carrier-gaps.md` | 4 |
| `log-lifespan-gain-paths.md` | 2026-08-17 | `inbox/archive/solution-draft-lifespan-gain-paths.md` → `handoffs/2026-08-17f-lifespan-restoration-paths.md` | 1 |
| `log-combat-finale-and-hidden-attributes.md` | 2026-08-17 | `inbox/archive/solution-draft-combat-finale-and-hidden-attributes.md` → `handoffs/2026-08-17e-finale-combat-only-and-hidden-stat-io.md` | 2 |
| `log-exchange-mechanics.md` | 2026-08-17 | `inbox/archive/solution-draft-exchange-mechanics.md` → `handoffs/2026-08-17d-exchange-mechanics-and-transaction-discipline.md` | 4 |
| `log-explore-mechanics.md` | 2026-08-17 | `inbox/archive/solution-draft-explore-mechanics.md` → `handoffs/2026-08-17c-explore-reveal-mechanics.md` | 4 |
| `log-research-mechanics.md` | 2026-08-17 | `inbox/archive/solution-draft-research-mechanics.md` → `handoffs/2026-08-17b-research-build-panel-and-deck-elements.md` | 5 |
| `log-0817.md` | 2026-08-17 | 无草稿——`open-questions/cross-boundary.md` 待承接项直接落笔 | 3（均为承接项） |
| `log-plot-data-encoding.md` | 2026-08-16 | `inbox/archive/solution-draft-plot-data-encoding.md` → `handoffs/2026-08-16i-plot-data-encoding.md` | 2 |
| `log-event-outcome-vs-combat-reward.md` | 2026-08-16 | `inbox/archive/solution-draft-event-outcome-vs-combat-reward.md` → `handoffs/2026-08-16h-grant-source-assembler-criterion.md` | 1 |
| `log-travel-mechanics.md` | 2026-08-16 | `inbox/archive/solution-draft-travel-mechanics.md` → `handoffs/2026-08-16g-travel-mechanics-and-location-carrier.md` | 4 |
| `log-elements-modifier-pipeline-rule.md` | 2026-08-16 | `inbox/archive/solution-draft-elements-modifier-pipeline-rule.md` → `handoffs/2026-08-16f-elements-modifier-pipeline-opt-in.md` | 1 |
| `log-account-identity-model.md` | 2026-08-16 | `inbox/solution-draft-account-identity-model.md` | 1 |
| `log-cost-side-closure.md` | 2026-08-16 | `inbox/archive/solution-draft-cost-side-closure.md` → `handoffs/2026-08-16d-cost-side-closure.md` | 3 |
| `log-effect-keywords-and-targeting.md` | 2026-08-16 | `inbox/archive/solution-draft-effect-keywords-and-targeting.md` → `handoffs/2026-08-16c-effect-keywords-and-targeting.md` | 1 |
| `log-cross-library-alignment.md` | 2026-08-16 | `inbox/archive/solution-draft-cross-library-alignment.md` → `handoffs/2026-08-16b-cross-library-alignment-and-bridge-ledger.md` | 1 |
| `log-0815c.md` | 2026-08-16 | `handoffs/2026-08-16-design-audit-adjudication-and-hand-limit.md` | 8 |
| `log-0815b.md` | 2026-08-15 | `handoffs/2026-08-15d-intent-removal-lifespan-cost-visibility-and-design-audit.md` | 4 |
| `log-0815a.md` | 2026-08-15 | `handoffs/2026-08-15c-event-type-collapse-and-batch-shape.md` | 6 |
| `log-monetization-entitlement-and-scope.md` | 2026-08-15 | `handoffs/2026-08-15b-monetization-entitlement-purchase-shape-and-scope.md` | 3 |
| `log-claude-rules-design-content-thinning.md` | 2026-08-14 | `handoffs/2026-08-14b-claude-rules-design-content-thinning.md` | 1 |
| `log-common-properties-layering.md` | 2026-08-14 | `handoffs/2026-08-14-common-properties-layering.md` | 1 |
| `log-translation-key-rollout-and-content-localization.md` | 2026-08-13 | `handoffs/2026-08-13-translation-key-rollout-and-content-localization.md` | 2 |
| `log-0812a.md` | 2026-08-12 | `handoffs/2026-08-12f-cultivation-technique-deck-building.md` | 0 |
| `log-hidden-stat-bands-and-crossing-narrative.md` | 2026-08-12 | `handoffs/2026-08-12d-hidden-stat-bands-and-crossing-narrative.md` | 2 |
| `log-ability-grant-draw-pool.md` | 2026-08-12 | `handoffs/2026-08-12e-ability-grant-draw-pool.md` | 2 |
| `log-character-item-singular-naming.md` | 2026-08-12 | `handoffs/2026-08-12c-identifier-singular-collapse.md` | 1 |
| `log-grant-source-per-kind-scope.md` | 2026-08-12 | `handoffs/2026-08-12b-grant-source-per-kind-scope.md` | 1 |
| `log-error-copy-and-update-prompts.md` | 2026-08-12 | `handoffs/2026-08-12-error-copy-and-update-prompts.md` | 3 |
| `log-combat-system.md` | 2026-08-11 | `handoffs/2026-08-11c-combat-turn-flow-fatigue-and-card-type-reduction.md` | 2 |
| `log-0811_2.md` | 2026-08-11 | `handoffs/2026-08-11b-contract-boundary-and-flags-client-side.md` | 3 |
| `log-0811.md` | 2026-08-11 | `handoffs/2026-08-11-plot-content-localization.md` | 3 |
| `log-ability-deprivation-and-player-statistics.md` | 2026-08-10 | `inbox/solution-draft-ability-deprivation-and-player-statistics.md` | 4 |
| `log-0810b_2.md` | 2026-08-10 | `inbox/draft-0810b.md` | 5 |
| `log-0810b.md` | 2026-08-10 | `inbox/draft-0810b.md` | 1 |
| `log-discipline-enforceability.md` | 2026-08-09 | `inbox/solution-draft-discipline-enforceability.md` | 3 |
| `log-finale-win-ordinal-vs-statistics.md` | 2026-08-09 | `inbox/solution-draft-finale-win-ordinal-vs-statistics.md` | 1 |
| `log-past-event-trace-schema.md` | 2026-08-09 | `inbox/solution-draft-past-event-trace-schema.md` | 1 |
| `log-legacy-fragment-chance.md` | 2026-08-09 | `inbox/solution-draft-legacy-fragment-chance.md` | 2 |
| `log-sync-revision-and-soft-block.md` | 2026-08-09 | `inbox/solution-draft-sync-revision-and-soft-block.md` | 2 |
| `log-combat-solutions.md` | 2026-08-06 | `inbox/combat-solutions.md` | 38 |
| `log-0806b.md` | 2026-08-06 | `inbox/draft-0806b.md` | 5 |
| `log-0806_2.md` | 2026-08-06 | `inbox/draft-0806.md` | 5 |
| `log-0805b_2.md` | 2026-08-06 | — | 4 |
| `log-0806.md` | 2026-08-06 | — | 4 |
| `log-0805b.md` | 2026-08-05 | `inbox/draft-0805b.md` | 2 |
| `log-0805.md` | 2026-08-05 | `inbox/draft-0805.md` | 6 |
| `log-mtg-loanwords-and-card-types.md` | 2026-08-04 | `inbox/solution-draft-mtg-loanwords-and-card-types.md` | 5 |
| `log-0804.md` | 2026-08-04 | `inbox/draft-0804.md` | 1 |
| `log-0803.md` | 2026-08-03 | `inbox/draft-0803.md` | 6 |
| `log-0802c_2.md` | 2026-08-02 | — | 2 |
| `log-0802c.md` | 2026-08-02 | `handoffs/2026-08-02c-intent-threshold-inversion-and-aggregate-intent.md` | 6 |
| `log-0802b_2.md` | 2026-08-02 | — | 3 |
| `log-0802b.md` | 2026-08-02 | `handoffs/2026-08-02b-stack-without-interaction-and-three-step-turn.md` | 4 |
| `log-0802.md` | 2026-08-02 | `inbox/draft-0802.md` | 11 |
| `log-0801b.md` | 2026-08-01 | `inbox/draft-0801b.md` | 15 |
| `log-0801.md` | 2026-08-01 | `inbox/draft-0801.md` | 6 |
| `log-0730b.md` | 2026-07-30 | `inbox/draft-0730b.md` | 6 |
| `log-0730.md` | 2026-07-30 | `inbox/draft-0730.md` | 3 |
| `log-0728.md` | 2026-07-28 | — | 1 |
| `log-service-api-contracts.md` | 2026-07-27 | `inbox/solution-draft-service-api-contracts.md` | 5 |
| `log-0727.md` | 2026-07-27 | `inbox/draft-0727.md` | 9 |
| `log-0726b.md` | 2026-07-26 | `inbox/draft-0726b.md` | 8 |
| `log-0725c.md` | 2026-07-25 | — | 35 |
