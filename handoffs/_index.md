# Handoffs — Index（后端）

后端设计 handoff 的时间线日志。最新的置顶。每个 handoff 一个文件；可自由编辑 / 修正（非仅追加，历史归 git）。

客户端侧的 handoff 在 `game-design-documents/handoffs/`。**跨边界的意图写在哪一侧，看它由谁实现**——若一次意图同时改动两侧，两侧各写一份 handoff 并互相回链，不要一份跨库承载。

| id | date | topic | status | distilled-to |
|----|------|-------|--------|--------------|
| `2026-08-14-splitmix64-test-vectors` | 2026-08-14 | contracts/profile-sync（§6a 向量表 + 填值时机松动 + 备选方案七条）· contracts/vectors（新建数值权威文件）· contracts/_index（现状段） | distilled | `contracts/vectors/splitmix64.json`、`contracts/profile-sync.md`、`contracts/_index.md`、`open-questions/01-contracts.md`、`open-questions.md`、`open-questions/update-log.md`、`answer-logs/log-splitmix64-test-vectors.md` |
| `2026-08-14-openapi-spec-timing-and-consistency` | 2026-08-14 | contracts/envelope（§1 落笔规则 + 形态收 spec 单点）· contracts/_index（完成判据 + 机检断言 + `schemas/` 判据）· contracts/profile-sync（§6 向量数值权威）· operations（台账登记流程扩展） | distilled | `contracts/envelope.md`、`contracts/_index.md`、`contracts/profile-sync.md`、`operations/_index.md`、`open-questions/01-contracts.md`、`open-questions.md`、`open-questions/update-log.md`、`answer-logs/log-openapi-spec-timing-and-consistency.md` |
| `2026-08-14-profile-sync-contract` | 2026-08-14 | contracts/profile-sync（新建 · 最后一份端点契约）· contracts/envelope（§2 超 2⁵³ 整数判据 + §8 回链）· contracts/_index · decisions | distilled | `contracts/profile-sync.md`、`contracts/envelope.md`、`contracts/_index.md`、`decisions/_index.md`、`open-questions/01-contracts.md`、`open-questions/02-account-compliance.md`、`open-questions/06-platform-stack.md`、`open-questions.md`（`03-sync-conflict.md` 整片删除）、`answer-logs/log-profile-sync-contract.md` |
| `2026-08-13-auth-endpoint-contract` | 2026-08-13 | contracts/auth（新建）· contracts/envelope（§4a 例外 + §6 台账三处）· contracts/_index · decisions | distilled | `contracts/auth.md`、`contracts/envelope.md`、`contracts/_index.md`、`decisions/_index.md`、`open-questions/01-contracts.md`、`open-questions/02-account-compliance.md`、`open-questions/03-sync-conflict.md`、`open-questions.md`、`answer-logs/log-auth-endpoint-contract.md` |
| `2026-08-12-grant-source-code-contract` | 2026-08-12 | contracts/profile-sync · contracts/envelope（枚举序列化约定复核） | distilled | `contracts/profile-sync.md`（§5 白名单 + §5a `sourceCode` 收口 + §7a 处置） |
| `2026-08-11-plot-service-retired` | 2026-08-11 | vision/scope · contracts/envelope · contracts/content-manifest · systems · open-questions（`05` 作废） | distilled | `vision/scope.md`、`contracts/_index.md`、`contracts/envelope.md`、`contracts/content-manifest.md`、`systems/_index.md`、`decisions/_index.md`、`README.md`、`open-questions.md`、`open-questions/01-contracts.md`、`open-questions/04-content-delivery.md`、`answer-logs/log-0811.md` |
| `2026-08-11-contract-expression-envelope-and-error-codes` | 2026-08-11 | contracts/envelope · contracts/content-manifest（回改）· operations · decisions | distilled | `contracts/envelope.md`、`contracts/_index.md`、`contracts/content-manifest.md`、`operations/_index.md`、`decisions/_index.md`、`open-questions/01-contracts.md`、`open-questions/06-platform-stack.md`、`answer-logs/log-contract-expression-envelope-and-error-codes.md` |
| `2026-08-11-content-delivery-manifest-signing-and-flags` | 2026-08-11 | contracts/content-manifest · operations · decisions | distilled | `contracts/content-manifest.md`、`contracts/_index.md`、`operations/_index.md`、`decisions/_index.md`、`open-questions/04-content-delivery.md`、`answer-logs/log-content-delivery-manifest-and-flags.md` |

## 状态词汇
- `raw` — 已捕获，尚未处理。
- `triaged` — 已阅读并分流到正确的主题，但尚未撰写成文。
- `distilled` — 已折叠进某个主题文档（和/或某个 ADR）；`distilled-to:` 指明去向。
