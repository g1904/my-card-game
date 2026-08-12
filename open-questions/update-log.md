# Open questions — 更新日志（后端）

> 每次运行的更新摘要（答结 / 推翻 / 新增落点），倒序。不含问题条目本身——条目在各分片。

## 2026-08-11 — 剧本服务撤销（`05` 整片作废 + `01` 一条）

- **来源**：`game-design-documents/handoffs/2026-08-11-plot-content-localization.md`（客户端侧决策）→ `handoffs/2026-08-11-plot-service-retired.md`。
- **答结 4 条**：剧本下发协议（问题消失）· 生成式 vs 预写式（**预写式**，客户端侧裁定）· 延迟预算与兜底（问题消失）· `plot.md` 端点契约（不再需要）。→ `answer-logs/log-0811.md`。
- **分片删除**：`open-questions/05-plot-service.md` **整片删除**，编号 `05` 空缺且不回填（`06` 的编号在别处已被引用，重排代价更高）；索引导航表与「当前焦点」同步。
- **归档落点**：`contracts/content-manifest.md` 新增「剧本文本：一类普通内容文件」一节（含两条推论：overlay 新增 `Id` 是客户端合并纪律非契约条款 · flags 对剧本条目无作用点，撤回剧情只能前滚）；`contracts/envelope.md` 删 `/v1/plot/…` 端点域与 `plot.unavailable` 错误码；`contracts/_index.md` 删 `plot.md` 计划行；`systems/_index.md` 删 `plot.md` 计划服务；`vision/scope.md` 边界表四→三、In scope 删「剧本下发」、Out of scope 新增一条；`README.md` 三处；`decisions/_index.md` 增一行客户端约束。
- **新增落点**：`04-content-delivery.md` 增一条——**剧本内容的体积与分包**（本地化换来的新问题，原「按需请求」天然回避了它），与客户端侧同题需一致。
- **未触发 interview**：输入是客户端侧已完成 interview 并 `distilled` 的 handoff。两项由本库校验推演新增（客户端未点名）：`envelope.md` 的端点域 / 错误码、`vision/scope.md` 的边界表与 In scope。
- **跨库**：本次不新增任何边界语义，**客户端侧无需再写 handoff**。

## 2026-08-11 — 协议契约边界层六条答结（`01` + `content-manifest` 两项欠账）

- **来源**：`inbox/archive/solution-draft-contract-expression-envelope-and-error-codes.md` → `handoffs/2026-08-11-contract-expression-envelope-and-error-codes.md`。
- **答结 6 条**（`01-contracts.md` 的四条边界层条目全部清空 + `content-manifest.md` 推给信封的两项欠账）：契约事实来源 · 表达形式 · 错误码分层与 `OpError` 映射 · 版本协商与强更 · 信封携带 `flagsVersion` · `minAppVersion` 与强更闸门分工。→ `answer-logs/log-contract-expression-envelope-and-error-codes.md`。
- **归档落点**：新建 `contracts/envelope.md`（边界层：OpenAPI 3.1 单点 · 序列化约定 · `/v1/` 主版本 · 传输信封 HTTP 头 / 负载信封 body 段 · 错误体五字段 + 15 条 `code` 台账 · 强更闸门只在登录 / 启动点 · Profile 三段可见性）；`contracts/_index.md` 重写「现状」；`contracts/content-manifest.md` 两处回改（`/content/flags` → `/v1/content/flags` 归 API 域；解除「字段名待表达形式」限定）；`operations/_index.md` 增版本兼容矩阵与错误码台账登记流程；`decisions/_index.md` 增 ADR 候选③。
- **新增落点**：`01` 分片改承各端点报文本体（`auth` 先行 · `profile-sync` 的后端可见字段子集 · `plot` · `compliance.*` 码清单 · spec 落笔时机）；`06-platform-stack.md` 删去「与 `01` 表达形式一起决」的耦合表述——**`01` 已从 `06` 的下游摘出**，两者可并行。
- **interview 裁决两项**（草稿未定的形态）：`baseRevision` / `pushId` 留在 push body 的负载信封段（「信封」拆为传输 / 负载两名）；`Upgrade` 类错误只在登录 / 启动点硬阻塞，中途 push 遇 `sync.payload_schema_unsupported` 保留待发队列 + 暂停退避 + 非模态提示。
- **跨库待办**：本次改动客户端 ↔ 后端语义，**客户端侧需另写一份 handoff**（五点，见 handoff 的「客户端侧影响」段），本库不代为改动。

## 2026-08-11 — 内容分发协议四条答结（`04`）

- **来源**：`inbox/archive/solution-draft-content-delivery-manifest-and-flags.md` → `handoffs/2026-08-11-content-delivery-manifest-signing-and-flags.md`。
- **答结 4 条**（`04-content-delivery.md` 全片清空）：增量粒度与失败恢复 · overlay 防篡改 · `manifest.json` schema 与版本化 · `ContentEnabled` 下发通道。→ `answer-logs/log-content-delivery-manifest-and-flags.md`。
- **归档落点**：新建 `contracts/content-manifest.md`（本库第一份契约文档）；`contracts/_index.md`、`operations/_index.md`、`decisions/_index.md` 同步扩写。
- **新增落点**：`04` 分片改承三条运维 / 选型条目（flags 数据源与灰度分桶的运营形态、签名私钥保管与 CI 签名步骤、多区域内容分发一致性）；`01` 增两项欠账（信封携带 `flagsVersion`、`minAppVersion` 与强更闸门分工）——已在 `contracts/_index.md` 点名，未重复写进 `01` 分片。
- **松动一处既有决策**（用户裁决）：客户端 `content-service.md` 的「overlay 是唯一热更层」被 flags 第三层取代，限定条款为「只覆盖 `ContentEnabled` 一个布尔」。**客户端侧需另写 handoff**，本库不代为改动。
- **ADR 候选 2 条**登记进 `decisions/_index.md`（内容寻址 + `contentVersion` 单调递增 · flags 第三层边界条款），未写正文。

## 2026-08-10 — 建库：结构对齐 `game-design-documents`

- **本库从「README + 单文件 open-questions」扩为与客户端设计库同构的骨架**：`vision/` · `handoffs/` · `inbox/`（含 `archive/`）· `decisions/` · `systems/` · `contracts/` · `operations/` · `requirements/` · `open-questions/` 分片 · `answer-logs/`。
- **待答清单拆片**：原单文件的五个主题段落拆为 `01-contracts` · `02-account-compliance` · `03-sync-conflict` · `04-content-delivery` · `05-plot-service`，并新开 `06-platform-stack`（原「后端 / 账号系统具体选型」中的技术栈部分移入此片）。编号即优先级，`01` 为焦点之首。
- **新增待答条目**（由既有条目推演，未经用户裁定，可直接删）：错误码体系与 `OpError` 映射、版本协商 / 强制更新、风控与滥用面、`manifest.json` schema 版本化、`ContentEnabled` 下发通道、剧本生成式 vs 预写式、剧本延迟预算、环境分层、可观测性口径、成本模型。
- **未答结任何问题**——本次只动结构。
