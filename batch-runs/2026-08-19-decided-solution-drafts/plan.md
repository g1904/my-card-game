# Batch run — 10 份 decided solution-draft 提炼

- 日期：2026-08-19
- 主库：`game-design-documents/`（用户显式给定 `game`）
- 底层技能：`/analyze-new-ideas`
- 范围：`game-design-documents/inbox/` 顶层全部 10 份 `solution-draft-*.md`（全部 `status: decided`，取向项零剩余）

## 分片清单（Phase A 一片一 worker，全并行只读）

| 分片 | 草稿 | 主要写入面 |
|---|---|---|
| costkey | solution-draft-costkey-statkey-registry.md | architecture · profile-service · player-profile/_index · character-profile/_index · sync-service |
| profile-change | solution-draft-profile-change-spec-gaps.md | profile-service · life-cycle-service · combat-service · adventure-event/common-properties · character-profile/_index · architecture |
| codex | solution-draft-codex-entry-schema.md | player-profile/codex/* · player-profile/_index · profile-service · sync-service |
| game-setting | solution-draft-game-setting-schema.md | player-profile/game-setting · player-profile/_index · profile-service · sync-service · ux/error-and-blocking-ux · ux/screen-flow · architecture |
| bundle | solution-draft-bundle-grant-ordinal-authority.md | monetization · profile-service · player-profile/_index · sync-service · ux/error-and-blocking-ux（跨库：后端半在 backend inbox 同名草稿，本次不写后端） |
| device-id | solution-draft-device-id-provisioning.md | services/account-service · player-profile/_index |
| pickmany | solution-draft-pickmany-shortfall-handling.md | adventure-event/research · adventure-event/exchange · future-event-service · content-service · profile-service · balance |
| arch-residuals | solution-draft-architecture-structural-residuals.md | architecture · sync-service · content-service · balance · systems/viewmodel.md（新建） |
| translation | solution-draft-translation-english-placeholder.md | ux/error-and-blocking-ux · content-service · requirements/FR-ux-translation-foundation |
| breakdown | solution-draft-breakdown-granularity-and-signoff.md | requirements/_index · .claude/skills/breakdown-requirements/SKILL.md |

## Phase B 波次（按写入面分区，铁律③）

写入面冲突图高度连通，能真正并行的只有 breakdown。

- **W1**：costkey + profile-change（同一 worker，共享 architecture / profile-service / character-profile） ‖ breakdown（写入面完全不相交）
- **W2**：codex + game-setting（共享 player-profile/_index · profile-service · sync-service）
- **W3**：bundle + device-id
- **W4**：pickmany
- **W5**：arch-residuals + translation

## orchestrator 独占写入（worker 一律不写）

`handoffs/_index.md` · `open-questions.md` 索引 · `open-questions/*` 分片 · `open-questions/update-log.md` · `answer-logs/_index.md` · `inbox/_index.md` · 草稿归档（git mv）。
不碰「derive 就绪度」小节。
