# ① 协议契约（六份已成文 · 余下四条待答项）

> 客户端 ↔ 后端边界的**唯一**耦合点。两侧都读它，因此必须单点定义。权威落点：`contracts/`。
> 跨越这条边界的客户端成分有**三个**：`account-service`、`content-service`、`sync-service`——全部是服务本身，没有任何 manager 跨边界（剧本内容已本地化，2026-08-11）。
>
> **边界层四条已于 2026-08-11 全部答结** → `contracts/envelope.md`（移出记录见 `answer-logs/log-contract-expression-envelope-and-error-codes.md`）。
> **auth 域已于 2026-08-13 成文** → `contracts/auth.md`（移出记录见 `answer-logs/log-auth-endpoint-contract.md`）。
> **sync 域已于 2026-08-14 成文** → `contracts/profile-sync.md`（两端点报文 · diff 顶层键浅合并 · 可见字段白名单 · SplitMix64 随机源 · 复算边界 · CAS / 幂等 / 限流语义；移出记录见 `answer-logs/log-profile-sync-contract.md`）。
> **purchase 域已于 2026-08-16 成文** → `contracts/purchase.md`（验票端点 + 收据幂等读 · 写入只由 verify 承担 · 渠道回调降为对账通道 · 序号与 `revision` 同事务自增 · 服务端保证四条）。同批把 `profile-sync.md` §2 §5 的「后端只读」改写为**封闭写入表**并补入 `/entitlement/bundleGrantOrdinal` 白名单行。移出记录见 `answer-logs/log-cross-library-alignment.md`。
> **auth 域的身份模型已于 2026-08-16 补齐** → `contracts/auth.md` §1 §1a §3a（端点集扩到七个 · account↔identity 一对多 · 换 openid 的三条义务与两类错误映射）；同批把 `profile-sync.md` §5 写入表扩到四行并加固护栏（新增「够格进表」两条判据）。**换 openid 的报文与渠道错误映射就此答结**，移出记录见 `answer-logs/log-account-identity-model.md`。
> **合规域已于 2026-08-16 成文** → `contracts/compliance.md`（第六份 · 六端点 · `complianceTicket` · 拦截只在 `signin` · 四条 `compliance.*` 与取值 · 防沉迷复用 `session_revoked`）。同批填满 `auth.md` 的**三处 `reasonKey` 留白**（形态 PascalCase · `session_revoked` 七值 · `nickname_rejected` 三值）、新增 `auth.md` §4a 会话裁决，并把 `envelope.md` §4a 的无鉴权例外由点名 auth 改写为一条判据。移出记录见 `answer-logs/log-compliance-and-session-arbitration.md`。
> **契约面因此为六份**；两次开新契约都是按 `contracts/_index.md` 的分域判据行使它，判据本身未变。
> **SplitMix64 测试向量已于 2026-08-14 填值答结** → `contracts/profile-sync.md` §6a（8 组数值 + 选取依据）+ `contracts/vectors/splitmix64.json`（数值权威）；填值时机由「等任一侧首次实现」提前为**预先算出 + 两侧实现后逐位对表**，并补一条「不得单方面改表迁就实现」的纪律（移出记录见 `answer-logs/log-splitmix64-test-vectors.md`）。**「跨语言逐位一致」自此有了可执行的检查点。**
> **spec 的落笔与一致性核对规则已于 2026-08-14 答结** → `contracts/_index.md`「契约变更的完成判据」+ `contracts/envelope.md` §1（触发点 = 任一侧首个端点 · 形态收 spec 单点 · 三条机检断言 + 人工清单 · 变更内原子；移出记录见 `answer-logs/log-openapi-spec-timing-and-consistency.md`）。**`contracts/` 的最后一项结构性欠账就此结清。**
> 本分片余下的全部是**横切待答项**，不挡任何一份契约成文。

- **`refresh` 的滥用面与限流形态（待 `06`）。** 契约侧刻意不给 `rate.limited`（为保客户端两条失败路径在报文层面互斥），若 `06` 认定必须限流，需回头松动并同时给出客户端的第三条路径，**不能只在网关侧悄悄加**。→ `contracts/auth.md` §8 §10。

- **合规域端点自身的错误码（随报文本体落笔，非设计未决）。** `contracts/compliance.md` 的六端点只落了端点集与语义，字段表与它们各自的错误码（ticket 过期 / 核验拒绝 / 冷静期已过 / 导出任务不存在）应由一次正式的契约变更承担。**四条 `compliance.*` 拦截码已进台账**，本条与它们无关。

- **回声校验的适用面与比较口径（08-22 新增 · 承重）。** `contracts/profile-sync.md` §5c 已定「后端写入路径在上行侧只接受回声」，当前的执行面只有 `/entitlement/bundleGrantOrdinal`（整数，数值相等无歧义）。**`/accountInfo` 是同形的第二处**（键内混有后端写入的 `accountSeed` / `createdAtUtc` / `identities` 与客户端写入的 `nickname`，由改昵称触发），尚未定两件事：① 受约束路径的封闭清单如何表述（逐条列举 还是 与后端写入字段表恒等）；② **非整数路径的比较口径**——时间串按时刻还是按字面、对象数组按序还是按集合、是否按原始字节。**② 选错的后果是正常客户端被整批拒绝 = 玩家丢进度**，故 §5c 已明写「落笔之前不得按字节相等实现」。
  **已有一份 `decided` 的方案草稿承接本条**：`inbox/solution-draft-echo-validation-scope.md`（与客户端库同名草稿成对采纳），走 `/analyze-new-ideas` 提炼即关闭。→ `contracts/profile-sync.md` §4 §5 §5c §7a。
  **承接项（2026-08-22 · 成对采纳未完成）：客户端半已于同日落笔**——组装规则、回声值唯一来源、回声路径不参与钳制 / 补默认 / 归一化、push 前自检，见 `game-design-documents/systems/services/sync-service.md`「后端主动写入的唯一情形」一节（客户端只登记「受约束顶层键」这一层，逐条 path 与比较口径仍以本库为权威、不复述）。**本条余下的后端半仍未落笔**：① `/accountInfo` 的受约束路径清单如何表述；② 非整数路径的比较口径。**在它落笔之前 §5c 的「不得按字节相等实现」原样有效**；客户端半的「不得再加工」纪律在两种口径下都成立，故不阻塞客户端。

- **三条机检断言的承载位置未定（待 `06`）。** 落笔规则与一致性核对方式已于 2026-08-14 全部答结（→ `contracts/_index.md`「契约变更的完成判据」+ `envelope.md` §1；移出记录见 `answer-logs/log-openapi-spec-timing-and-consistency.md`）。**唯一仍开放的是工程承载**：设计库侧是否存在自动化流水线、跑在哪里——随 `06-platform-stack.md` 落定。断言本身与后端栈无关（校验的是 markdown 与 YAML / JSON），**不等 `06`**：在此之前三条以人工清单的前三项形式执行，其余条款不受影响。具体校验工具刻意不点名，只立能力要求：能校验 OpenAPI 3.1 / JSON Schema 2020-12，且能在设计库侧运行。
