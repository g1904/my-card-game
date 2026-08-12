# Handoffs — Index（后端）

后端设计 handoff 的时间线日志。最新的置顶。每个 handoff 一个文件；可自由编辑 / 修正（非仅追加，历史归 git）。

客户端侧的 handoff 在 `game-design-documents/handoffs/`。**跨边界的意图写在哪一侧，看它由谁实现**——若一次意图同时改动两侧，两侧各写一份 handoff 并互相回链，不要一份跨库承载。

| id | date | topic | status | distilled-to |
|----|------|-------|--------|--------------|
| `2026-08-12-grant-source-code-contract` | 2026-08-12 | contracts/profile-sync（计划中）· contracts/envelope（枚举序列化约定需复核） | raw | — |
| `2026-08-11-plot-service-retired` | 2026-08-11 | vision/scope · contracts/envelope · contracts/content-manifest · systems · open-questions（`05` 作废） | distilled | `vision/scope.md`、`contracts/_index.md`、`contracts/envelope.md`、`contracts/content-manifest.md`、`systems/_index.md`、`decisions/_index.md`、`README.md`、`open-questions.md`、`open-questions/01-contracts.md`、`open-questions/04-content-delivery.md`、`answer-logs/log-0811.md` |
| `2026-08-11-contract-expression-envelope-and-error-codes` | 2026-08-11 | contracts/envelope · contracts/content-manifest（回改）· operations · decisions | distilled | `contracts/envelope.md`、`contracts/_index.md`、`contracts/content-manifest.md`、`operations/_index.md`、`decisions/_index.md`、`open-questions/01-contracts.md`、`open-questions/06-platform-stack.md`、`answer-logs/log-contract-expression-envelope-and-error-codes.md` |
| `2026-08-11-content-delivery-manifest-signing-and-flags` | 2026-08-11 | contracts/content-manifest · operations · decisions | distilled | `contracts/content-manifest.md`、`contracts/_index.md`、`operations/_index.md`、`decisions/_index.md`、`open-questions/04-content-delivery.md`、`answer-logs/log-content-delivery-manifest-and-flags.md` |

## 状态词汇
- `raw` — 已捕获，尚未处理。
- `triaged` — 已阅读并分流到正确的主题，但尚未撰写成文。
- `distilled` — 已折叠进某个主题文档（和/或某个 ADR）；`distilled-to:` 指明去向。
