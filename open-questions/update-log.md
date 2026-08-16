# Open questions — 更新日志（后端）

> 每次运行的更新摘要（答结 / 推翻 / 新增落点），倒序。不含问题条目本身——条目在各分片。

## 2026-08-14 — SplitMix64 测试向量填值答结（`01` 一条）

- **来源**：`inbox/archive/solution-draft-splitmix64-test-vectors.md`（08-14 产出并由用户裁决）→ `handoffs/2026-08-14-splitmix64-test-vectors.md`。
- **答结 1 条**：`01` 的「`profile-sync.md` §6 测试向量表的实际数值未填」。→ `answer-logs/log-splitmix64-test-vectors.md`。**「跨语言逐位一致」这条纪律自此有了唯一可执行的检查点**（此前不填 = 等于没有这条纪律，且失效形态是静默的作弊窗口）。
- **归档落点**：新建 `contracts/vectors/splitmix64.json`（数值权威 · 8 组 · 含算法常量与 `streams` 冻结映射 · 64 位值走 hex16 字符串）；`contracts/profile-sync.md` 新增 **§6a**（8 组对照表 + 选取依据 + 非规范性自测提示 + 「不得单方面改表迁就实现」的承重纪律），§6 末条改为指向 §6a，Open questions 删该条，「备选方案」新增 7 条（只给 `roll` · 只给 1–2 组 · 各抄进代码 · 各自重算 · 十进制表示 · 放进 `schemas/` · 另立 `Mix()` 向量表）；`contracts/_index.md` 现状段新增一段 + 目录形态标注已落笔。
- **一处措辞松动（用户裁决）**：填值时机由「向量值在**任一侧首次实现时**填入」改为**由独立参考实现预先算出，两侧实现后逐位对表**。松动的是时机不是复核要求——表从「实现的副产物」变成「实现的验收前置」。代价（依赖第三方参考实现的正确性）由新增的「先复核实现、再复核表，不得单方面改表」纪律接住。
- **新增落点**：无新增待答项。`01` 余下四条（`auth.md` 三处留白 · `compliance.*` 码清单 · `bundleGrantOrdinal` · 机检承载位置）与本次无关，原样保留。
- **未触发 interview**：输入草稿 `status: decided`，唯一取向项（填值时机）已由用户裁决，本库校验未发现新的 🔴 / 🟠。**数值经两道自检**：① `Mix` 与 `GOLDEN` 用公开的标准 SplitMix64 向量钉住；② 落盘后经一条不同的解析路径二次复算，8 组逐位比对全过。§6 独有的三参数逐级混入无外部参照，复核对象是那五行伪代码本身。
- **跨库**：**不改动任何报文语义，客户端侧不需要承接性 handoff**。但既有跨库欠账（`handoffs/2026-08-14-profile-sync-contract.md` 七点）的**第 6 点**（`AccountRng` 换随机源）自此有了可直接消费的验收物，客户端可**先于后端**完成并自验。
- **顺带发现（未改，归 `/update-readme`）**：`README.md` 文件夹图例中 `contracts/` 那行仍写「当前有两份」，实际已四份。

## 2026-08-14 — spec 的落笔时机与一致性核对规则答结（`01` 一条）

- **来源**：`inbox/archive/solution-draft-openapi-spec-timing-and-consistency.md`（08-14 产出并由用户裁决）→ `handoffs/2026-08-14-openapi-spec-timing-and-consistency.md`。
- **答结 1 条**：`01` 的「`openapi.yaml` / `schemas/*.json` 尚未落笔 + 一致性核对方式未定」——**`contracts/` 的最后一项结构性欠账结清**。→ `answer-logs/log-openapi-spec-timing-and-consistency.md`。
- **归档落点**：`contracts/envelope.md` §1（落地时机改写为「任一侧首个端点、动手方落笔、共有层 + 该端点」· markdown ↔ spec 分工改为**形态收 spec 单点** · 新增「形态的迁移」「覆盖面」「`info.version`」三行）+ Open questions 第三条中性化为待落笔项；`contracts/_index.md` 现状段 + 「约定」段新增**契约变更的完成判据**（六条 + 三条机检断言表 + 人工清单四项）与 **`schemas/` 拆分判据 + 落笔后目录形态 + `profile-visible-subset.json` 的三条纪律**；`contracts/profile-sync.md` §6 补「数值权威在 `vectors/splitmix64.json`」；`operations/_index.md` 错误码台账登记流程由「先文档后实现」扩展为**「先文档 → 后 spec → 后实现」**并接入断言②。
- **新增落点**：`01` 的该条**降级重写**为「三条机检断言的**承载位置**待 `06`」（工程承载，非设计未决；断言与后端栈无关，不等 `06`，在此之前走人工清单）；`01` 的 SplitMix64 向量条补落点 `contracts/vectors/splitmix64.json`；索引「当前焦点」第 2 条把该承载位置并入 `06` 的承接面。
- **⚠ 触发 interview，两项**：① **🔴 草稿自相矛盾**——第 2 条「四份 markdown 字段表**同批**瘦身」与同稿 §1 改写表「未落笔端点的字段表视为草案」互斥（首落只含共有层 + 一个端点，四份全瘦身会让未进 spec 的三个端点**形态无处承载**）⇒ 用户裁定**随 spec 覆盖面逐步瘦身**，过渡期风格不齐写明为预期状态；② **🟠 CDN 域端点是否进 `paths`** 未定（`<contentRoot>/manifest`·`.sig`·`/blobs/<hash>` 不在 `/v1/` 下，而草稿断言③ 只写了 `METHOD /v1/…`）⇒ 用户裁定**进 `paths`、以 `contentRoot` 为独立 server**，断言③ 措辞随之放宽为「每个 `METHOD 路径`」。另有一项本库校验推演：`manifest.json` 即便进 `paths` 也只被**一个** path 引用，故 `schemas/` 判据写成**两条并列款**（+「独立可被签名 / 校验、需脱离 spec 单独引用的产物」），而非给 manifest 开例外。
- **跨库**：本次**不改动任何报文语义**，客户端侧无需承接性 handoff。但有一条跨库**操作**约定需客户端知晓：客户端若先于后端进入某端点实现（`HttpProfileBackend` 最可能），**由客户端侧发起本库 `contracts/openapi.yaml` 的落笔**，后端在同一次跨库 handoff 中确认——即客户端的第一次真实请求实现是「先落 spec、再按 spec 编码」，不是按 markdown 草案编码。

## 2026-08-14 — `profile-sync.md` 成文，契约面封顶（`01` 一条 + `03` 整片五条）

- **来源**：`inbox/archive/solution-draft-profile-sync-contract.md`（08-13 产出、08-14 用户裁决五项）→ `handoffs/2026-08-14-profile-sync-contract.md`。
- **答结 6 条**：`01` 的「`profile-sync.md` 尚未成文」；`03` 的全部五条（`revision` CAS 服务端语义 · `pushId` 幂等窗口 · `AccountSeed` 下发与复算 · 上行负载版本化与合并细节 · 自动存档点频率的服务端约束）。→ `answer-logs/log-profile-sync-contract.md`。
- **分片删除**：`open-questions/03-sync-conflict.md` **整片删除**，编号 `03` 空缺且不回填（同 `05` 的处置）；实现层面的部分并入 `06`。
- **归档落点**：新建 `contracts/profile-sync.md`（两端点封定 · 负载信封四字段 · **diff 的顶层键浅合并** · 三分支 + 幂等命中应答 · **可见字段子集的逐 JSON path 白名单** · **SplitMix64 契约随机源** · **可复算 `roll` 不可复算阈值** · 不一致仅记账 · CAS 线性化 + 单主 · `pushId` 200 条/30 天 · 只设滥用阈值 · `compliance.*` 不进同步通道）；`contracts/envelope.md` 两处（§2 补「超 2⁵³ 整数走字符串」判据 · §8 第二段改为回链白名单）；`contracts/_index.md` 状态行转正 + 现状段；`decisions/_index.md` 增两条 ADR 候选（防作弊边界 · SplitMix64 随机源）；`handoffs/2026-08-12-grant-source-code-contract.md` 三条 open question 全部答结并转 `distilled`。
- **新增落点**：`01` 增两条（SplitMix64 测试向量数值 · `bundleGrantOrdinal` 透明路径）并全片改承「四份齐备、只剩横切项」；`02` 的合规条补落点边界（不得选在 `/v1/profile/*`）、风控条改承已定处置 + 已知残留通道；`06` 的可观测性条增至三探针 + 透明路径缺失告警，并新增一条「同步侧语义的实现落地」承接 `03` 的实现部分。
- **⚠ 触发 interview，两项 🔴 均推翻草稿原写法**：① **复算校验 ②③ 的形态**——草稿的双向等价会被客户端既定规则证伪（首胜 100% · 池空静默停摆 · 重置为 `Base(x+1)` 而非归 0），且**池空时不掷骰而序号照常 `+1`** 会让校验 ① 稳定失败 ⇒ 裁定为**单向蕴含 + 三条写入约定**（每次胜利必掷骰、首胜写 `10000`、不检查发放那次 `accumulated` 方向）；② **push diff 的合并语义**在两库均未定义而后端必须靠它维护整聚合 ⇒ 裁定为**顶层键粒度浅合并**（否决 RFC 7386 与段级全量替换）。另有一项本库校验推演修正：512 KB 初值的口径（客户端那条是 `pastEvent` 护栏，非整聚合）。
- **跨库**：本次改动客户端 ↔ 后端语义，**客户端侧需另写一份 handoff（七点）**，本库不代为改动。其中 ①②⑤⑥ 与本契约**互为前提**——含一次真实的类型改动（`AccountRng.For` 返回类型 `RandomNumberGenerator` → `AccountRandom`，连带 `DrawPool.PickOne/PickMany` 参数放宽）。

## 2026-08-13 — `auth.md` 成文（`01` 一条 + `02` 一条）

- **来源**：`inbox/archive/solution-draft-auth-endpoint-contract.md`（08-12 产出、08-13 用户逐项裁决）→ `handoffs/2026-08-13-auth-endpoint-contract.md`。
- **答结 2 条**：`01` 的「`auth.md` 尚未成文」（token 生命周期 + 登录渠道报文形态两部分答定，多设备触发条件仍留 `02`）· `02` 的「token 失效时的失效判定与续期窗口」（TTL 15 min / refresh 30 天滑动 / 60 秒宽限窗口）。→ `answer-logs/log-auth-endpoint-contract.md`。
- **归档落点**：新建 `contracts/auth.md`（四端点封定 · 双 token · 渠道分形 credential · rotation + 60 s 宽限 · 强更闸门只在 `signin` · 四端点全幂等 · `session_revoked.detail` 加 `reasonKey` · `AccountSeed` 不进 auth 报文）；`contracts/envelope.md` 四处（§4a auth 例外域 · 台账两条新 `code` · `session_revoked.detail` 改形 · 承重项由三条增为四条，含「刷新失败按判据拆两条」）；`contracts/_index.md` 状态行转正；`decisions/_index.md` 增 ADR 候选④（auth 幂等 = sync 幂等）。
- **新增落点**：`01` 改承 `auth.md` 的三处显式留白 + `refresh` 限流面（待 `06`）；`02` 的多设备条追加「同时卡着 `reasonKey` 取值表与 `deviceId` 裁决口径」；`03` 的 `AccountSeed` 条注明 **auth 侧已排除**、定稿仍在 `profile-sync.md`。
- **未触发 interview**：输入草稿 `status: decided`，四项取向 + 一项张力已由用户逐项裁决，本次校验未发现新的 🔴 / 🟠。**两项由本库校验推演新增**（草稿未点名）：`envelope.md` 台账 `auth.token_expired` 行的旧措辞需按裁决 #5 改写；`auth.credential_invalid` 的描述需写宽以覆盖 `challenge` 的「标识符格式非法」。
- **跨库**：本次改动客户端 ↔ 后端语义，**客户端侧需另写一份 handoff**（五点，见 handoff 的「客户端侧影响」段），本库不代为改动。其中第 3 点是一次**跨库松动**——`account-service.md`「刷新失败视同断线」的覆盖面按判据拆为两条路径。

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
