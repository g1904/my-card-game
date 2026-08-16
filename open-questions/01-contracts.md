# ① 协议契约（四份全部成文 · 只剩横切待答项）

> 客户端 ↔ 后端边界的**唯一**耦合点。两侧都读它，因此必须单点定义。权威落点：`contracts/`。
> 跨越这条边界的客户端成分有**三个**：`account-service`、`content-service`、`sync-service`——全部是服务本身，没有任何 manager 跨边界（剧本内容已本地化，2026-08-11）。
>
> **边界层四条已于 2026-08-11 全部答结** → `contracts/envelope.md`（移出记录见 `answer-logs/log-contract-expression-envelope-and-error-codes.md`）。
> **auth 域已于 2026-08-13 成文** → `contracts/auth.md`（移出记录见 `answer-logs/log-auth-endpoint-contract.md`）。
> **sync 域已于 2026-08-14 成文** → `contracts/profile-sync.md`（两端点报文 · diff 顶层键浅合并 · 可见字段白名单 · SplitMix64 随机源 · 复算边界 · CAS / 幂等 / 限流语义；移出记录见 `answer-logs/log-profile-sync-contract.md`）。**契约面四份齐备，无第五份。**
> **SplitMix64 测试向量已于 2026-08-14 填值答结** → `contracts/profile-sync.md` §6a（8 组数值 + 选取依据）+ `contracts/vectors/splitmix64.json`（数值权威）；填值时机由「等任一侧首次实现」提前为**预先算出 + 两侧实现后逐位对表**，并补一条「不得单方面改表迁就实现」的纪律（移出记录见 `answer-logs/log-splitmix64-test-vectors.md`）。**「跨语言逐位一致」自此有了可执行的检查点。**
> **spec 的落笔与一致性核对规则已于 2026-08-14 答结** → `contracts/_index.md`「契约变更的完成判据」+ `contracts/envelope.md` §1（触发点 = 任一侧首个端点 · 形态收 spec 单点 · 三条机检断言 + 人工清单 · 变更内原子；移出记录见 `answer-logs/log-openapi-spec-timing-and-consistency.md`）。**`contracts/` 的最后一项结构性欠账就此结清。**
> 本分片余下的全部是**横切待答项**，不挡任何一份契约成文。

- **`auth.md` 的三处显式留白（全部待 `02` / 客户端）。** 报文形状已定且不受影响，待补的只是取值与分支：① `auth.session_revoked.detail.reasonKey` 的**取值集合**（待 `02` 的多设备并发裁决规则）；② `compliance.*` 在 `signin` 的**分支**——合规拦截是在 `signin` 应答返回还是登录成功后由业务端点返回（待 `02`）。**边界已收窄**：`profile-sync.md` §11 已定**同步通道不承载合规拦截**，`/v1/profile/*` 出局，候选只剩 `signin` 与业务端点；③ **绑定 / 解绑 / 换绑端点**——待客户端 `account-info.md` 的多渠道绑定模型。另有 `refresh` 的**滥用面与限流形态**待 `06`：契约侧刻意不给 `rate.limited`（为保客户端两条失败路径在报文层面互斥），若 `06` 认定必须限流，需回头松动并同时给出客户端的第三条路径。

- **`compliance.*` 错误码的具体清单未定。** 实名 / 防沉迷 / 注销 / 导出各自的分支、以及各自 `detail` 里的 `reasonKey` 取值集合。`envelope.md` 的台账只立了两条示例与它们的 `class`，待 `02-account-compliance.md` 的合规方案。**落点边界已定**（见上条②）。

- **`bundleGrantOrdinal` 的透明路径未定。** `PremiumBundle` 域的账号级序号在**客户端**的存档落点仍待答（`game-design-documents/systems/monetization.md` 的「付费凭证存档表达」）⇒ 该域的复算暂不列进 `profile-sync.md` §5 的白名单，表中已**预留一行**。落定后按同形态补入，**不改任何已定形状**，也不挡本契约其余部分。

- **三条机检断言的承载位置未定（待 `06`）。** 落笔规则与一致性核对方式已于 2026-08-14 全部答结（→ `contracts/_index.md`「契约变更的完成判据」+ `envelope.md` §1；移出记录见 `answer-logs/log-openapi-spec-timing-and-consistency.md`）。**唯一仍开放的是工程承载**：设计库侧是否存在自动化流水线、跑在哪里——随 `06-platform-stack.md` 落定。断言本身与后端栈无关（校验的是 markdown 与 YAML / JSON），**不等 `06`**：在此之前三条以人工清单的前三项形式执行，其余条款不受影响。具体校验工具刻意不点名，只立能力要求：能校验 OpenAPI 3.1 / JSON Schema 2020-12，且能在设计库侧运行。
