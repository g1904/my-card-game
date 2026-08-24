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
| `log-refresh-cap-and-flags-gate.md` | 2026-08-23 | `inbox/archive/solution-draft-refresh-lifetime-cap.md` → `handoffs/2026-08-23-refresh-lifetime-cap-client-half.md` + `handoffs/2026-08-23-flags-version-client-gate.md` | 1（另两项本库取向同批定案） |
| `log-0823.md` | 2026-08-23 | 无草稿 —— `[采纳推荐 — 待复核]` 20 项复核会（零新增设计） | 20 |
| `log-combat-defeat-consequences.md` | 2026-08-22 | `inbox/archive/solution-draft-combat-defeat-consequences.md` → `handoffs/2026-08-22-combat-defeat-consequences.md` | 1 |
| `log-mana-baseline-realm-jump.md` | 2026-08-22 | `inbox/archive/solution-draft-mana-baseline-realm-jump.md` → `handoffs/2026-08-22-mana-baseline-realm-jump.md` | 1 |
| `log-encounter-tighten-fields.md` | 2026-08-22 | `inbox/archive/solution-draft-encounter-tighten-fields.md` → `handoffs/2026-08-22-encounter-tighten-fields.md` | 2 |
| `log-hidden-stat-grant-direction.md` | 2026-08-22 | `inbox/solution-draft-hidden-stat-grant-direction.md` → `handoffs/2026-08-22-hidden-stat-grant-direction.md` | 1 |
| `log-card-counters-api-and-key-space.md` | 2026-08-22 | `inbox/solution-draft-card-counters-api-and-key-space.md` → `handoffs/2026-08-22-card-counters-api-and-key-space.md` | 3（另新答定 2 条本批新发现缺口） |
| `log-singleton-balance-resource-registry.md` | 2026-08-22 | `inbox/solution-draft-singleton-balance-resource-registry.md` → `handoffs/2026-08-22-singleton-balance-resource-registry.md` | 1（另 1 条部分答定） |
| `log-eventcountlimit-plot-modulation.md` | 2026-08-22 | `inbox/solution-draft-eventcountlimit-plot-modulation.md` → `handoffs/2026-08-22-eventcountlimit-plot-modulation.md` | 1 |
| `log-plot-tree-chapter-packaging.md` | 2026-08-22 | `inbox/solution-draft-plot-tree-chapter-packaging.md` → `handoffs/2026-08-22-plot-tree-chapter-packaging.md` | 1 |
| `log-locationcodex-edge-granularity.md` | 2026-08-22 | `inbox/solution-draft-locationcodex-edge-granularity.md` → `handoffs/2026-08-22-locationcodex-edge-granularity.md` | 1（部分移出） |
| `log-enemy-deck-size-and-fatigue-knob.md` | 2026-08-22 | `inbox/solution-draft-enemy-deck-size-and-fatigue-knob.md` → `handoffs/2026-08-22-enemy-deck-size-and-fatigue-knob.md` | 2 |
| `log-purchase-count-statkey.md` | 2026-08-22 | `inbox/archive/solution-draft-purchase-count-statkey.md` → `handoffs/2026-08-22-purchase-count-statkey.md` | 1 |
| `log-0822.md` | 2026-08-22 | interview 新裁决（无草稿）→ `handoffs/2026-08-22-finale-failure-is-death.md` | 1（另记 12 条同场答定） |
| `log-future-event-generation-weighting.md` | 2026-08-22 | `inbox/archive/solution-draft-future-event-generation-weighting.md` → `handoffs/2026-08-22-event-generation-weighting-pipeline.md` | 1 |
| `log-event-outcome-spec-fields.md` | 2026-08-22 | `inbox/solution-draft-event-outcome-spec-fields.md` → `handoffs/2026-08-22-event-outcome-spec-fields.md` | 1 |
| `log-priority-elevation-conditions.md` | 2026-08-22 | `inbox/solution-draft-priority-elevation-conditions.md` → `handoffs/2026-08-22-priority-elevation-criterion.md` | 1 |
| `log-remaining-event-decision-points.md` | 2026-08-22 | `inbox/solution-draft-remaining-event-decision-points.md` → `handoffs/2026-08-22-non-combat-decision-points.md` | 1 |
| `log-enemy-pool-chapter-scoping.md` | 2026-08-22 | `inbox/solution-draft-enemy-pool-chapter-scoping.md` → `handoffs/2026-08-22-enemy-pool-chapter-scoping.md` | 1 |
| `log-band-boundary-config-placement.md` | 2026-08-22 | `inbox/solution-draft-band-boundary-config-placement.md` → `handoffs/2026-08-22-band-boundary-config-placement.md` | 2 |
| `log-combat-runtime-counter-persistence.md` | 2026-08-22 | `inbox/archive/solution-draft-combat-runtime-counter-persistence.md` → `handoffs/2026-08-22-combat-runtime-counter-persistence.md` | 1 |
| `log-echo-validation-scope.md` | 2026-08-22 | `inbox/archive/solution-draft-echo-validation-scope.md` → `handoffs/2026-08-22-echo-validation-scope-client-half.md` | 1 |
| `log-flags-fetch-throttle.md` | 2026-08-22 | `inbox/solution-draft-flags-fetch-throttle.md` → `handoffs/2026-08-22-flags-fetch-throttle.md` | 1（部分：两项取向待复核仍留清单） |
| `log-architecture-structural-residuals.md` | 2026-08-19 | `inbox/archive/solution-draft-architecture-structural-residuals.md` → `handoffs/2026-08-19-architecture-structural-residuals.md` | 3 |
| `log-translation-english-placeholder.md` | 2026-08-19 | `inbox/archive/solution-draft-translation-english-placeholder.md` → `handoffs/2026-08-19-translation-english-placeholder.md` | 1 完整 + 1 部分 |
| `log-pickmany-shortfall-handling.md` | 2026-08-19 | `inbox/archive/solution-draft-pickmany-shortfall-handling.md` → `handoffs/2026-08-19-pickmany-shortfall-handling.md` | 1 |
| `log-codex-entry-schema.md` | 2026-08-19 | `inbox/archive/solution-draft-codex-entry-schema.md` → `handoffs/2026-08-19-codex-entry-schema.md` | 3 |
| `log-device-id-provisioning.md` | 2026-08-19 | `inbox/archive/solution-draft-device-id-provisioning.md` → `handoffs/2026-08-19-device-id-provisioning.md` | 1 |
| `log-game-setting-schema.md` | 2026-08-19 | `inbox/archive/solution-draft-game-setting-schema.md` → `handoffs/2026-08-19-game-setting-schema.md` | 3 |
| `log-costkey-statkey-registry.md` | 2026-08-19 | `inbox/archive/solution-draft-costkey-statkey-registry.md` → `handoffs/2026-08-19-costkey-statkey-registry.md` | 2 |
| `log-bundle-grant-ordinal-authority.md` | 2026-08-19 | `inbox/archive/solution-draft-bundle-grant-ordinal-authority.md` → `handoffs/2026-08-19-bundle-grant-ordinal-authority.md` | 1 完整 + 1 部分 |
| `log-breakdown-granularity-and-signoff.md` | 2026-08-19 | `inbox/archive/solution-draft-breakdown-granularity-and-signoff.md` → `handoffs/2026-08-19-breakdown-granularity-and-signoff.md` | 1 |
| `log-profile-change-spec-gaps.md` | 2026-08-19 | `inbox/archive/solution-draft-profile-change-spec-gaps.md` → `handoffs/2026-08-19-profile-change-spec-gaps.md` | 4 |
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
