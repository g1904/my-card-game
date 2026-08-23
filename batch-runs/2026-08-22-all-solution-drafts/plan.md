# Batch run — all solution drafts (2026-08-22)

主库：`game-design-documents/`（用户显式指定）。对侧库 `backend-design-documents/` 仅 echo-validation 一份可能触及（前置未满足，待 interview 裁决）。

## 范围（10 份，用户指定「all solution drafts」）

| # | 草稿 slug | 主要写入面 |
|---|---|---|
| 1 | future-event-generation-weighting | fes · game-progression · ae/common-properties · plot-manager · travel/_index · balance |
| 2 | event-outcome-spec-fields | fes · ae/common-properties · architecture · explore/_index · profile-service |
| 3 | priority-elevation-conditions | fes · ae/common-properties · combat/_index · research/_index |
| 4 | remaining-event-decision-points | life-cycle-service · exchange/_index · explore/_index · travel/_index · research/_index |
| 5 | enemy-pool-chapter-scoping | enemies/_index · enemies/common-properties · fes · content/_index |
| 6 | band-boundary-config-placement | balance · fes · enemies/_index |
| 7 | combat-runtime-counter-persistence | combat-service · power/_index · player-item/_index · item/_index |
| 8 | echo-validation-scope | sync-service · player-profile/_index · account-info（跨库前置） |
| 9 | refresh-token-client-storage | account-service · architecture · ux/screen-flow · ux/onboarding |
| 10 | flags-fetch-throttle | content-service · balance |

## 写入面热点（决定波次）

`future-event-service.md`（1,2,3,5,6）· `adventure-event/common-properties.md`（1,2,3）· `balance.md`（1,6,10）·
`architecture.md`（2,9）· `enemies/_index.md`（5,6）· `explore/_index.md`（2,4）· `travel/_index.md`（1,4）· `research/_index.md`（3,4）

## Phase A（并行 · 只读）

10 个 worker 全并行，各产出 `questions-<slug>.md`。

## Phase B 波次（每波内写入面互不相交）

- **W1**（并行 3）：① generation-weighting ② combat-runtime-counter ③ echo-validation
- **W2**（并行 2）：② event-outcome-spec ⑩ flags-throttle
- **W3**（并行 2）：③ priority-elevation ⑨ refresh-token
- **W4**（并行 2）：④ remaining-decision-points ⑤+⑥ enemy-pool + band-boundary（同一 worker 串行写）

## 共享台账（orchestrator 收尾统一写）

`handoffs/_index.md` · `open-questions/*` 分片 + `update-log.md` · `open-questions.md` 索引「最近更新」一行 ·
`answer-logs/_index.md` · `inbox/_index.md` + 草稿归档。**不碰「derive 就绪度」小节。**
