# Answer logs — 已答定问题的归档台账（后端）

待答清单（`open-questions.md` 索引 + `open-questions/` 分片）只跟踪**仍待答**的问题。一旦某个问题被拍板，它就从那份清单**移出**，并写入本文件夹的一份 `log-<draftSuffix>.md`。

## 命名：`log-<draftSuffix>.md`

`draftSuffix` = 触发本次移出的那份输入的后缀：

- 处理 `inbox/draft-<suffix>.md` → `log-<suffix>.md`。草稿后缀**含序列字母**（`MMDD` + `a`/`b`/`c`…，见 `../inbox/_index.md`），**原样照抄**：`draft-0816a.md` → `log-0816a.md`。
- 处理 `inbox/solution-draft-<slug>.md` → `log-<slug>.md`。
- 无草稿来源（粘贴文本、或清单独立汇总）→ 用当天 `MMDD`（**不加序列字母**——没有草稿序列可跟随，且这样一眼可区分「有草稿来源」与「无」）；若同名已存在，追加 `_2`、`_3`。
- `_2` / `_3` 是**同名冲突**后缀，与 `a`/`b`/`c` 的**同日序列**后缀是两套东西，不要混用。
- **每次移出新建一个文件**，不追加进旧 log。一次运行若没有任何问题被答定，则不建文件。

## 内容形态

每份 log 是一次移出的快照：日期、来源 handoff / 草稿、以及逐条「问题 → 结论（归档去向）」。log 是**只读的历史记录**，不是权威——结论的权威归属仍在各主题文档与 `decisions/ADR-*`。

**跨边界的答定**：若一次裁决同时改动客户端语义，本 log 只记后端侧结论，并回链客户端侧的 `game-design-documents/answer-logs/log-*.md`。

## 台账

| Log | 日期 | 来源 | 移出条数 |
|-----|------|------|----------|
| `log-splitmix64-test-vectors.md` | 2026-08-14 | `inbox/archive/solution-draft-splitmix64-test-vectors.md` → `handoffs/2026-08-14-splitmix64-test-vectors.md` | 1 |
| `log-openapi-spec-timing-and-consistency.md` | 2026-08-14 | `inbox/archive/solution-draft-openapi-spec-timing-and-consistency.md` → `handoffs/2026-08-14-openapi-spec-timing-and-consistency.md` | 1（部分残留：机检承载位置转 `06`） |
| `log-profile-sync-contract.md` | 2026-08-14 | `inbox/archive/solution-draft-profile-sync-contract.md` → `handoffs/2026-08-14-profile-sync-contract.md` | 6（`03` 整片清空并删除） |
| `log-0811.md` | 2026-08-11 | `game-design-documents/handoffs/2026-08-11-plot-content-localization.md` → `handoffs/2026-08-11-plot-service-retired.md` | 4 |
| `log-contract-expression-envelope-and-error-codes.md` | 2026-08-11 | `inbox/archive/solution-draft-contract-expression-envelope-and-error-codes.md` → `handoffs/2026-08-11-contract-expression-envelope-and-error-codes.md` | 6 |
| `log-auth-endpoint-contract.md` | 2026-08-13 | `inbox/archive/solution-draft-auth-endpoint-contract.md` → `handoffs/2026-08-13-auth-endpoint-contract.md` | 2 |
| `log-content-delivery-manifest-and-flags.md` | 2026-08-11 | `inbox/archive/solution-draft-content-delivery-manifest-and-flags.md` → `handoffs/2026-08-11-content-delivery-manifest-signing-and-flags.md` | 4 |
