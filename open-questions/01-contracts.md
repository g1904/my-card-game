# ① 协议契约（六份已成文 · 当前无待答项）

> 客户端 ↔ 后端边界的**唯一**耦合点。两侧都读它，因此必须单点定义。权威落点：`contracts/`。
> 跨越这条边界的客户端成分有**三个**：`account-service`、`content-service`、`sync-service`——全部是服务本身，没有任何 manager 跨边界（剧本内容已本地化，2026-08-11）。
>
> **边界层四条已于 2026-08-11 全部答结** → `contracts/envelope.md`（移出记录见 `answer-logs/log-contract-expression-envelope-and-error-codes.md`）。
> **auth 域已于 2026-08-13 成文** → `contracts/auth.md`（移出记录见 `answer-logs/log-auth-endpoint-contract.md`）。
> **sync 域已于 2026-08-14 成文** → `contracts/profile-sync.md`（两端点报文 · diff 顶层键浅合并 · 可见字段白名单 · SplitMix64 随机源 · 复算边界 · CAS / 幂等 / 限流语义；移出记录见 `answer-logs/log-profile-sync-contract.md`）。
> **purchase 域已于 2026-08-16 成文** → `contracts/purchase.md`（验票端点 + 收据幂等读 · 写入只由 verify 承担 · 渠道回调降为对账通道 · 序号与 `revision` 同事务自增 · 服务端保证四条）。同批把 `profile-sync.md` §2 §5 的「后端只读」改写为**封闭写入表**并补入 `/entitlement/bundleGrantOrdinal` 白名单行。移出记录见 `answer-logs/log-cross-library-alignment.md`。
> **auth 域的身份模型已于 2026-08-16 补齐** → `contracts/auth.md` §1 §1a §3a（端点集扩到七个 · account↔identity 一对多 · 换 openid 的三条义务与两类错误映射）；同批把 `profile-sync.md` §5 写入表扩到四行并加固护栏（新增「够格进表」两条判据）。**换 openid 的报文与渠道错误映射就此答结**，移出记录见 `answer-logs/log-account-identity-model.md`。
> **合规域已于 2026-08-16 成文** → `contracts/compliance.md`（第六份 · 六端点 · `complianceTicket` · 拦截只在 `signin` · 四条 `compliance.*` 与取值 · 防沉迷复用 `session_revoked`）。同批填满 `auth.md` 的**三处 `reasonKey` 留白**（形态 PascalCase · `session_revoked` 与 `nickname_rejected` 的取值表，条数以 `contracts/auth.md` §10 为准、此处不复述）、新增 `auth.md` §4a 会话裁决，并把 `envelope.md` §4a 的无鉴权例外由点名 auth 改写为一条判据。移出记录见 `answer-logs/log-compliance-and-session-arbitration.md`。
> **契约面因此为六份**；两次开新契约都是按 `contracts/_index.md` 的分域判据行使它，判据本身未变。
> **SplitMix64 测试向量已于 2026-08-14 填值答结** → `contracts/profile-sync.md` §6a（8 组数值 + 选取依据）+ `contracts/vectors/splitmix64.json`（数值权威）；填值时机由「等任一侧首次实现」提前为**预先算出 + 两侧实现后逐位对表**，并补一条「不得单方面改表迁就实现」的纪律（移出记录见 `answer-logs/log-splitmix64-test-vectors.md`）。**「跨语言逐位一致」自此有了可执行的检查点。**
> **spec 的落笔与一致性核对规则已于 2026-08-14 答结** → `contracts/_index.md`「契约变更的完成判据」+ `contracts/envelope.md` §1（触发点 = 任一侧首个端点 · 形态收 spec 单点 · 三条机检断言 + 人工清单 · 变更内原子；移出记录见 `answer-logs/log-openapi-spec-timing-and-consistency.md`）。**`contracts/` 的最后一项结构性欠账就此结清。**
> **回声校验的适用面与比较口径已于 2026-08-23 答结** → `contracts/profile-sync.md` §5c（适用面恒等式 · 类型感知的比较口径 · 追加字段刚性；移出记录见 `answer-logs/log-echo-validation-scope.md`）。与客户端半的**成对采纳就此完成**。
> **`auth.md` §5 静默续期的闸门收口已于 2026-08-23 答结** → `contracts/auth.md` §5b（refresh 链绝对寿命上限 · 新 `reasonKey` `SessionExpired` · 软信号 `reauthRecommended`；移出记录见 `answer-logs/log-refresh-lifetime-cap.md`）。
> **合规域的报文本体与端点自身的错误码已于 2026-09-03 答结** → `contracts/compliance.md` §10 §11（六端点字段表 · `ComplianceRealnameStatus` · `taskId` 形态 · 导出任务四状态 · 三条新 `code` 与各自 `reasonKey`）+ `contracts/envelope.md` §6 台账三行、§4a 例外表（撤销注销改 `POST .../cancel`）。移出记录见 `answer-logs/log-compliance-endpoint-payloads.md`。**六份契约自此全部完全成文。**
> **`refresh` 的限流形态已于 2026-09-03 答结** → 网关不得对 refresh 施加限流，只记账 + 告警，落 `operations/deployment.md` 的两条网关纪律与逐次上线核对项；契约侧「刻意不给 `rate.limited`」因此不必松动。移出记录见 `answer-logs/log-backend-stack-and-hosting.md`。
> **三条机检断言的工程承载已于 2026-09-06 答结** → `contracts/_index.md`「契约变更的完成判据」+ `operations/deployment.md`（`backend-design` 分支上的 `contract-spec-check` workflow · spec 未落笔期的降级形态 · 存在性驱动的切换判据 · 断言③′ 的基准改为 `envelope.md` §3 的端点全集表并配 P-3 护栏）。移出记录见 `../answer-logs/log-spec-check-automation-hosting.md`。
> **本分片当前无待答项。**

*（当前无待答项）*
