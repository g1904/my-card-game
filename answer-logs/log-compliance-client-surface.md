# Answer log compliance-client-surface

- 日期：2026-09-03
- 来源：`inbox/solution-draft-compliance-client-surface.md`（→ `handoffs/2026-09-03-compliance-client-surface.md`）
- 移出条数：4

**`ComplianceManager` 的客户端侧覆盖面切分**（登记在 `open-questions/cross-boundary.md` 与 `systems/services/account-service.md` 待决问题两处） → 已答定。切分判据取「凡需要一段流程（多于一次请求、或需持有流程内凭据）的归 `ComplianceManager`；凡只是把一次失败说清楚的归发起它的那一屏」，四域十环节逐格归属落表；另明写四件不归它的事（任何判定 · 会话中途下线 · 昵称合法性判定与提交 · 措辞选择）。两处登记同批移除。（归档去向：`systems/services/account-service.md`）

**三条新 `code` 的 `ERR_*` 键与呈现** → 已答定。键由既有机械变换直接得出（`ERR_COMPLIANCE_TICKET_INVALID` / `_VERIFICATION_FAILED` / `_DELETION_IRREVOCABLE`），二级键同理，**本库不建任何对照表、不复述 `reasonKey` 取值**（只加一条指向对侧 §11 的回链）。处置三行写进 `account-service.md`「失败映射」段——**本库此前没有任何逐 `code` 表**，在 `architecture.md` 开一张只有合规三条的半张表会制造与对侧台账重复的第二权威，故 `architecture.md` 零改动。七条 `compliance.*` 逐条核过阻塞屏变体表准入判据，**一条也不进**，`BlockingNoticeKind` 一格不动。（归档去向：`ux/error-and-blocking-ux.md`、`systems/services/account-service.md`）

**强制改名的强制力边界（客户端 fail-open 是否可接受）** → 已裁决：维持 fail-open，并在 `account-service.md` **明写边界**——客户端侧的强制改名不是硬阻塞，其兑现依赖一次可降级的请求；后端侧的兜底是存量扫描与复核通道。不要求对侧在 `signin` 补拦截，后端处置主线不动。（归档去向：`systems/services/account-service.md`）

**`GET status` 失败的降级归属** → 已裁决：归入 `sync-service.md` 三条不变式③ 的**第二形状**，并就地把「用上一个已知好值」明确到**含缺省值**（此处缺省 = 无附加合规面）。不变式仍是三条，属澄清而非松动。（归档去向：`systems/services/sync-service.md`、`systems/services/account-service.md`）

**未答结、仍留在清单上的相邻项：** `open-questions/cross-boundary.md` 中同一条承接项的另两项（`playtimeRemainingSeconds` 的剩余时长呈现 · `nicknameChangeRequired` 为真时的改名流程落屏）**仍待落笔**，归在办草稿 `inbox/solution-draft-backend-batch-client-obligations.md` 的 A / B 项；本次只提供其数据源与调用点。
