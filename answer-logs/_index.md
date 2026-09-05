# Answer logs — 已答定问题的归档台账（后端）

待答清单（`open-questions.md` 索引 + `open-questions/` 分片）只跟踪**仍待答**的问题。一旦某个问题被拍板，它就从那份清单**移出**，并写入本文件夹的一份 `log-<draftSuffix>.md`。

## 命名：`log-<draftSuffix>.md`

`draftSuffix` = 触发本次移出的那份输入的后缀：

- 处理 `inbox/draft-<suffix>.md` → `log-<suffix>.md`。草稿后缀**含序列字母**（`MMDD` + `a`/`b`/`c`…，见 `../inbox/_index.md`），**原样照抄**：`draft-0816a.md` → `log-0816a.md`。
- 处理 `inbox/solution-draft-<slug>.md` → `log-<slug>.md`。
- **一次运行同批提炼多份草稿**（互为前提、拆开提炼会让一侧的取值失去产生它的机制）→ 取一个覆盖两者的合成 slug，并在 log 的「来源」行逐一列出全部草稿路径。仍是**一次移出一个文件**。
- 无草稿来源（粘贴文本、或清单独立汇总）→ 用当天 `MMDD`（**不加序列字母**——没有草稿序列可跟随，且这样一眼可区分「有草稿来源」与「无」）；若同名已存在，追加 `_2`、`_3`。
- `_2` / `_3` 是**同名冲突**后缀，与 `a`/`b`/`c` 的**同日序列**后缀是两套东西，不要混用。
- **每次移出新建一个文件**，不追加进旧 log。一次运行若没有任何问题被答定，则不建文件。

## 内容形态

每份 log 是一次移出的快照：日期、来源 handoff / 草稿、以及逐条「问题 → 结论（归档去向）」。log 是**只读的历史记录**，不是权威——结论的权威归属仍在各主题文档与 `decisions/ADR-*`。

**跨边界的答定**：若一次裁决同时改动客户端语义，本 log 只记后端侧结论，并回链客户端侧的 `game-design-documents/answer-logs/log-*.md`。

## 台账

| Log | 日期 | 来源 | 移出条数 |
|-----|------|------|----------|
| `log-schema-bump-ledger-authority.md` | 2026-09-03 | `inbox/archive/solution-draft-schema-bump-ledger-authority.md` → `handoffs/2026-09-03-schema-bump-ledger-authority.md` | 1（`schemaVersion` 集合的输入与登记流程；跨库成对关闭。同批裁决两项：告警按大小关系二分 · 矩阵本批即登 `1`。未新增待答项） |
| `log-backend-stack-and-hosting.md` | 2026-09-03 | `inbox/archive/solution-draft-backend-stack-and-hosting.md` → `handoffs/2026-09-03-backend-stack-and-hosting.md` | 10（9 条整条：`06` 八条 + `01` 一条；另 1 条部分答结——`receiptId` 幂等记录的存储已定，冷存归档与对账阈值仍留 `06`） |
| `log-nickname-moderation-and-risk-control.md` | 2026-09-03 | `inbox/archive/solution-draft-nickname-moderation-and-risk-control.md` → `handoffs/2026-09-03-nickname-moderation-and-risk-control.md` | 4（`02` 三条主项 + 一条从属项；「合规能力的上线分级」仍留） |
| `log-content-delivery-ops.md` | 2026-09-03 | `inbox/archive/solution-draft-content-delivery-ops.md` → `handoffs/2026-09-03-content-delivery-ops.md` | 3（`04` 三条运维形态全部答结） |
| `log-purchase-channel-integration.md` | 2026-09-03 | `inbox/archive/solution-draft-purchase-channel-integration.md` → `handoffs/2026-09-03-purchase-channel-integration.md` | 2（**均为部分移出**：收据记录的冷存归档与对账阈值、渠道验票凭据的托管形态仍留 `06`） |
| `log-compliance-endpoint-payloads.md` | 2026-09-03 | `inbox/archive/solution-draft-compliance-endpoint-payloads.md` → `handoffs/2026-09-03-compliance-endpoint-payloads.md` | 1（`01` 合规域端点自身的错误码；六份契约自此全部完全成文） |
| `log-client-flag-cache-and-binary-overlay.md` | 2026-08-30 | `inbox/archive/solution-draft-client-flag-cache-and-binary-overlay.md` → `handoffs/2026-08-30-client-flag-cache-and-binary-overlay.md` | 2（`contracts/content-manifest.md`「Open questions」四条 → 两条；跨库成对，客户端同批移出 2 条） |
| `log-echo-validation-scope.md` | 2026-08-23 | `inbox/archive/solution-draft-echo-validation-scope.md` → `handoffs/2026-08-23c-echo-validation-scope.md` | 1（两小问一并答定） |
| `log-flags-version-monotonic.md` | 2026-08-23 | `inbox/archive/solution-draft-flags-version-monotonic.md` → `handoffs/2026-08-23b-flags-version-monotonic.md` | 2（其一部分答结：运营形态其余部分留 `04`） |
| `log-refresh-lifetime-cap.md` | 2026-08-23 | `inbox/archive/solution-draft-refresh-lifetime-cap.md` → `handoffs/2026-08-23-refresh-lifetime-cap.md` | 1 |
| `log-profile-field-schema.md` | 2026-08-17 | `inbox/archive/solution-draft-profile-field-schema.md` → `handoffs/2026-08-17-profile-field-naming.md` | 2 |
| `log-compliance-and-session-arbitration.md` | 2026-08-16 | `inbox/archive/solution-draft-compliance-codes-and-reason-keys.md` + `inbox/archive/solution-draft-multi-device-session-arbitration.md` → `handoffs/2026-08-16c-compliance-contract-and-session-arbitration.md` | 2（部分残留：合规能力的上线分级留在 `02`） |
| `log-account-identity-model.md` | 2026-08-16 | `inbox/solution-draft-account-identity-model.md` | 1 |
| `log-cross-library-alignment.md` | 2026-08-16 | `inbox/archive/solution-draft-cross-library-alignment.md` → `handoffs/2026-08-16-purchase-contract-and-cross-boundary-ledger.md` | 2 |
| `log-splitmix64-test-vectors.md` | 2026-08-14 | `inbox/archive/solution-draft-splitmix64-test-vectors.md` → `handoffs/2026-08-14-splitmix64-test-vectors.md` | 1 |
| `log-openapi-spec-timing-and-consistency.md` | 2026-08-14 | `inbox/archive/solution-draft-openapi-spec-timing-and-consistency.md` → `handoffs/2026-08-14-openapi-spec-timing-and-consistency.md` | 1（部分残留：机检承载位置转 `06`） |
| `log-profile-sync-contract.md` | 2026-08-14 | `inbox/archive/solution-draft-profile-sync-contract.md` → `handoffs/2026-08-14-profile-sync-contract.md` | 6（`03` 整片清空并删除） |
| `log-0811.md` | 2026-08-11 | `game-design-documents/handoffs/2026-08-11-plot-content-localization.md` → `handoffs/2026-08-11-plot-service-retired.md` | 4 |
| `log-contract-expression-envelope-and-error-codes.md` | 2026-08-11 | `inbox/archive/solution-draft-contract-expression-envelope-and-error-codes.md` → `handoffs/2026-08-11-contract-expression-envelope-and-error-codes.md` | 6 |
| `log-auth-endpoint-contract.md` | 2026-08-13 | `inbox/archive/solution-draft-auth-endpoint-contract.md` → `handoffs/2026-08-13-auth-endpoint-contract.md` | 2 |
| `log-content-delivery-manifest-and-flags.md` | 2026-08-11 | `inbox/archive/solution-draft-content-delivery-manifest-and-flags.md` → `handoffs/2026-08-11-content-delivery-manifest-signing-and-flags.md` | 4 |
