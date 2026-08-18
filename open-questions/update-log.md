# Open questions — 更新日志（后端）

> 每次运行的更新摘要（答结 / 推翻 / 新增落点），倒序。不含问题条目本身——条目在各分片。

## 2026-08-17（`/batch-analyze-new-ideas` 跨库同批 · 移出 2 条 · 新增 0 条）

- **来源**：`inbox/solution-draft-profile-field-schema.md`（本库那一半，`awaiting-review`）→ `handoffs/2026-08-17-profile-field-naming.md`。它是客户端 5 份草稿批量提炼的**对侧承接**，两侧同批落笔、互相回链；客户端那一半见 `game-design-documents/handoffs/2026-08-17h-profile-field-schema.md`。移出记录见 `../answer-logs/log-profile-field-schema.md`。
- **答结 2 条**（均出自草稿的「仍需用户决定」，本库分片零对应条目）：
  - **透明路径改名的切换时序取 A** —— 线上无真实账号数据 ⇒ **直接切，不写迁移、不设兼容期**。兼容期在此处不是安全网：按 §7a 的处置语义（复算不一致仅记账 + 上报风控，不拒绝、不改写），兼容期内**没有任何信号**能告诉任一侧「对方还没改」，不一致会变得永久不可见。
  - **残卷 `ordinal` 口径确认** —— §7 现有措辞（「在 `finaleWinOrdinal` **递增的那一次** push 上」）已蕴含自增后口径，与客户端本批明写的「先算 +1 → 掷骰 → 同一次写回」一致。**零改动关闭**，只在客户端伪码那一行做了一句措辞消歧。
- **§5 白名单四条路径由复数改单数**（`/playerPower[*]/powerId` · `/playerPower[*]/sourceCode` · `/playerPower[*]/status` · `/playerItem`），条目键名随客户端全族收口 `id → powerId`；新增 **§5b 集合命名通则**并写明**一次性切换的三个成立前提**（线上无真实账号数据 · 两侧同批落笔 · 一次性不设兼容期），缺一即不成立。`schemaVersion` 并入客户端那一次 bump（清单权威在客户端 `sync-service.md`）。
- **`characterDiffs` 一格不动** —— 它是 diff 报文结构键，不在集合命名通则的约束面内；该划界由客户端侧同批钉死，本库只在 §5 排除清单旁注一句。
- **`envelope.md` §8 的可见性表路径示例一并同步** —— 它是本库内唯一复述白名单路径的第二处，只改一处会留下相反表述，正是「路径是契约的一部分」要防的漂移。
- **§6 算法与 §6a 的 8 组测试向量零改动**（已三重自查：diff 不含任何向量值 / 向量表逐行核对 / `contracts/vectors/splitmix64.json` 未被触碰）。三参数派生的输入是 `(accountSeed, stream, ordinal)`，与字段名无关。
- **新增待答 0 条。** `cross-boundary.md` 的「对账基线」区新增 2 条留痕（两侧字段命名同批落笔无欠账 · `ordinal` 口径两侧已对齐），**均不进「待承接」区**——待承接的语义是「客户端已定、本库尚未落笔」，本次落笔已完成。

## 2026-08-16f（`/analyze-new-ideas` 跨库同批 · 移出 0 条 · 新增 1 条）

- **来源**：`game-design-documents/inbox/solution-draft-plot-data-encoding.md` → 对侧 handoff `game-design-documents/handoffs/2026-08-16i-plot-data-encoding.md`；本库 handoff `handoffs/2026-08-16d-plot-content-shape-adoption.md`。客户端把剧本内容收口为 `PlotArcData` + `PlotNodeData` 两个内容类型，**本库只承接跨边界的两半**。
- **改写 `contracts/content-manifest.md`「剧本文本」一节的一条推论**：原写「flags 通道对剧本条目无作用点」，其前提（剧本条目只由 key point 定位读取）在 arc / node 分层后对 **arc 不再成立**。改为按分野表述——**arc 进 `disabledIds` 生效**（停止新激活，已在 key point 里的照常解析、不悬空），**node 进 `disabledIds` 无效且危险**（客户端 `PushError`）。**服务端仍不感知这一分野，报文层零改动、无新增字段。** 连带把运营后果的措辞收精确：flags 能做的是**停止新激活**（分钟级），**撤回一整段剧情仍是「回滚即前滚」**（冷启动级）。
- **新增待答 1 条**（`04-content-delivery.md`）：**发布侧内容校验闸的运维形态**——客户端定的两条 overlay 合并期闸只能做到启动期 `PushError`（检查对象是 `.tres` 引用图，编译期够不着），等价的更强形态是**产包前跑同一份校验、不通过不产包**；执行时点在发布流程上故落本库，校验逻辑本身归客户端。与「签名私钥保管与 CI 签名步骤」多半是同一条流水线，共同前置 `06-platform-stack.md`。
- **零改动面**：端点、schema、错误码、签名形态、`decisions/`、其余五份契约。

## 2026-08-16e（`/analyze-new-ideas` · 合规域成文 · 移出 2 条 · 契约面 五 → 六）

- **来源**：`inbox/solution-draft-compliance-codes-and-reason-keys.md` + `inbox/solution-draft-multi-device-session-arbitration.md`（两份均 `status: decided`）→ `handoffs/2026-08-16c-compliance-contract-and-session-arbitration.md`。**两份必须同批提炼**——补强稿承载的会话机制正是主稿 `SessionSuperseded` 这个取值的产生源，分开提炼会让取值在契约里没有机制。
- **答结 2 条**（→ `answer-logs/log-compliance-and-session-arbitration.md`）：`02` 的「合规落地」（分级排期外全部）与「多设备并发登录的裁决语义」。
- **新建 `contracts/compliance.md`（第六份）**：六端点 · `complianceTicket` 解无 token 态死锁 · 拦截**只在 `signin`**（推演唯一解，另两个落点已被 §7b 与 `profile-sync.md` §11 排除）· 四条 `compliance.*` 与各自 `reasonKey` · 防沉迷时段中途到点**复用 `auth.session_revoked`**（TTL 卡在时段边界，不新增任何通道）· 时段口径落配置不进契约 · 冷静期 15 天 / ticket 10 分钟 / 导出保留 7 天 · 数据导出首版必做取最简 JSON。**单开而非并入 `auth.md`** 的判据仍是 `_index.md` 那条：合规域有两条与 auth 域相反的承重纪律（长时状态机 / 不可逆）。
- **`auth.md` 三处 `reasonKey` 留白一次填满**：形态 **PascalCase 锁死**（客户端二级文案键由 `code` + `reasonKey` 机械变换、未知取值退回一级键）· `session_revoked` **七值** · `nickname_rejected` **三值**。其中 `TokenReuseDetected` 与 `CredentialChanged` **填的是既有漏洞**——§4 与 §7 都会产生 `session_revoked`，此前只举了两例，落到实现玩家会在刚绑定渠道后看到「已在另一台设备登录」。
- **新增 `auth.md` §4a 会话裁决**：`sid` claim（`signout` 的前提，否则只能退化为吊销全部会话）· 会话表 `(accountId, deviceId)` 唯一约束 · **活跃会话上限 1** · 同设备重登**原地替换** · **`signin` 幂等 = 60 秒回放窗口**（与 §4 同值同理由，且是「替换」得以成立的前提）· `deviceId` 永不参与鉴权。
- **一次 interview 裁决改写了护栏形态**：`envelope.md` §4a 的「无鉴权例外仅限 auth 域」与合规域的两个 ticket 端点冲突（**两份草稿的后果表都没列它**）。裁定**扩为两个例外域，并把点名式枚举升级为一条判据**——例外只允许给「玩家此刻不可能持有 access token」的端点。护栏因此**更严而非更松**：`GET /v1/compliance/status` 同属合规域却不够格。
- **第二次 interview**：`auth.md` §5a 新纪律的措辞范围收窄为**只约束「拦截」**，不约束 `compliance.` 前缀本身——否则会禁掉合规域表达 ticket 过期一类自有语义，而那批码本就被推迟到一次正式契约变更。
- **两处草稿内部计数笔误按三方互证取大者**（非 interview 项）：端点集 **6 个**（主稿正文写「五个」却列了 6 行）· `session_revoked` **7 值**（主稿后果表写「六值」却列了 7 行）。
- **`_index.md` 的「②断言不下探到 `reasonKey`」一条新立**：它是 `detail` 内的取值集合，spec 只能表达 `detail` 是对象，正确性归人工清单第 1 项；漏项的后果不是静默走错分支而是回落一级文案。
- **新增待答**：`01` 一条（合规域端点自身的错误码，随报文本体落笔）· `06` 三条（可信服务端时钟 · 合规域存储与导出产物 · 会话记录存储与同事务吊销）。
- **对侧库**：`game-design-documents/open-questions/cross-boundary.md` 立一条承接项（三处 `reasonKey` 取值与机械变换规则 → 客户端 `ux/error-and-blocking-ux.md` 与 `account-service.md`）。**本库不代为决定客户端的呈现切分。**
- **未动 `## derive 就绪度`**（`/assess-derive-readiness` 独占）。

## 2026-08-16d（`/analyze-new-ideas` 跨库同批 · 移出 1 条 · 部分移出 1 条）

- **来源**：`inbox/solution-draft-account-identity-model.md`（`status: decided`）→ `handoffs/2026-08-16b-account-identity-model.md`。**与客户端库同批运行**（counterpart：`game-design-documents/handoffs/2026-08-16c-account-identity-client-adoption.md`）。
- **答结 1 条**：`02` 的「账号系统自建还是接第三方」——**拆成三层后没有一层是取向**：A 身份主体自建 · B 登录凭据两类并存（契约早已封定）· C 原子能力一律外接。→ `answer-logs/log-account-identity-model.md`。
- **连带填掉 `auth.md` 的三处显式留白**（本就不是清单条目，故不计移出）：绑定 / 解绑端点 · 换 openid 的三条后端义务与两类错误映射 · 绑定列表的下行路径。端点集由四扩到**七**（+ `bind` / `unbind` / `nickname`），新增三个 `code`。
- **一次纪律松动（用户已裁决）**：`profile-sync.md` §5 后端写入表由两行扩到**四行**（+ `/accountInfo/identities`、`/accountInfo/createdAtUtc`）。护栏同批**加固而非放松**：措辞仍是例外式「除表内四项外」、写入时机在表内写死、并新立**「够格进表」两条判据**（真值只可能在服务端产生 ∧ 客户端无其他通道），使「引先例扩表」变成一次必须逐条通过的检验。
- **三次 interview**：① 昵称由**客户端写、后端只判定**（按新判据它不够格进写入表；改包可绕过的代价如实记在 `auth.md` §8，残留风险面由 `02` 的存量扫描承接）；② `status` **不进客户端**、只加 `createdAtUtc`（推翻了 counterpart 草稿把 `Status` 列进 `AccountInfo` 的那一行）；③ 改名端点**同批落契约**，而非只记一条承接项。
- **一处指向纠错**：`purchase.md` 的 `receipt` 形态此前挂在本条下，实为**支付渠道**（与登录渠道不同轴）→ 改指 `06`。
- **新增待答**：`02` 三小项（实名是否建号前置 · `nickname_rejected.reasonKey` 与词表口径 · 未过审昵称的存量扫描）· `06` 两条（服务商选型与灾备 · 微信开放平台资质，**首个玩家建号前必须完成**）。
- **未动 `## derive 就绪度`**（`/assess-derive-readiness` 独占）。

## 2026-08-16c — 购买域成文（第五份契约）· 移出 2 条 · 新增 `cross-boundary` 分片

- **来源**：`inbox/solution-draft-cross-library-alignment.md`（`status: decided`）→ `handoffs/2026-08-16-purchase-contract-and-cross-boundary-ledger.md`。**与客户端库同批运行**（counterpart：`game-design-documents/handoffs/2026-08-16b-cross-library-alignment-and-bridge-ledger.md`）。
- **答结 2 条**（→ `answer-logs/log-cross-library-alignment.md`）：`01` 的「购买段的新边界尚无契约承载」与「`bundleGrantOrdinal` 的透明路径未定」。
- **新建 `contracts/purchase.md`**：`POST /v1/purchase/verify` + `GET /v1/purchase/receipt/{receiptId}`；写入只由 verify 承担（渠道回调降为对账 / 补偿通道）· 平台收据 id 作幂等键 · 序号与 `revision` 同事务自增 · verify 不走 CAS 且不内联 profile · 复算回链 §6 · 四条栈中立的服务端保证。**单开而非并入 `profile-sync.md`** 的判据已写进 `_index.md`：承重纪律相反的域必须独立成文。
- **一次纪律松动（用户已裁决）**：`profile-sync.md` §2 §5 的「后端对透明段只读，唯一写入是 `accountSeed`」→ **封闭两行表** + 「本表封闭，加行是破坏性契约变更、须两侧同批评审」的护栏；被接受的代价（未来会被引作先例）如实写在 §5 的引述块里。同批补入 `/entitlement/bundleGrantOrdinal` 白名单行。
- **「契约面四份，无第五份」三处断言一并改写**（`contracts/_index.md` · `profile-sync.md` §1 · `README.md`）；`profile-sync.md` 文末的「跨库待办七点」改为一句客户端对位回链——七点已由客户端同批落笔。
- **新增分片 `cross-boundary.md`**（不带编号，与客户端库同名同形）：专装「客户端已定案、本库尚未承接」的条目。当前「待承接」为空，只留对账基线。机制设计写在客户端库那一份，本库不重复。
- **未动 `## derive 就绪度`**（`/assess-derive-readiness` 独占）。

## 2026-08-16b — `/summarize-open-questions` 全量对账（采集 3 条 · 推翻 1 条断言 · 无移出）

- **来源**：无草稿、无 handoff——纯归集整理。对账口径：`vision/` + `contracts/**` + `systems/_index.md` + `operations/_index.md` + `decisions/_index.md` 的 Open questions 小节 ↔ 4 个分片。
- **本次无移出**：逐条比对后，四个分片现存条目在其权威契约文档中均无定论（本库自 08-14 起无新决策）。**未建 answer log。**
- **⚠ 推翻一条断言：「契约面四份齐备，无第五份」作废。** 客户端 `game-design-documents/systems/monetization.md`（08-15b）已定案**购买由后端验票**、验票通过后**后端把云端 `bundleGrantOrdinal` 与 `cloudRevision` 各 +1**，客户端 `sync-service.md` 称其为同步模型此前没有的**第四种情形：后端主动写入**。本库对此**零承载**——无验票端点、`profile-sync.md` §5 仍写「`accountSeed` 是后端唯一写入的字段」、`contracts/_index.md` 仍宣称封顶四份。已在 `01-contracts.md` 立为首条待答项（含三个具体分叉：验票报文与渠道回调形态 · **后端主动写入如何与 `revision` CAS 共存**——客户端此时并未持有新 `revision`，下一次 push 必然 CAS 失败，需明确走 pull 还是走新的通知路径 · 同票据重复验证的幂等口径），并在索引的「当前焦点」与分片导航同步改正。**需一份本库 handoff 承接，本技能不代为裁决。**
- **采集 2 条漏网项**（在契约文档里登记过、从未进过本清单）：① **第三方渠道换取 openid 的具体报文**与渠道错误码到 `auth.channel_rejected.detail` 的映射 ⇒ `01`（与 `auth.md` 三处留白同源，待 `02` 的自建 vs 第三方）；② **token 签名密钥的保管与轮换 + 会话存储形态** ⇒ `06`（`auth.md` 已把它们归 `06` 落 `operations/`）。**②须与 `04` 的 ES256 内容签名私钥区分**——两把钥匙、两套轮换窗口，混为一谈会在轮换设计上出错。
- **未动分片结构**（四片体量均正常），**未动 `## derive 就绪度`**（`/assess-derive-readiness` 独占，原样保留 08-16 那份全量评估）。
- **未发现需报告的契约文档自身错漏**：四份契约的 Open questions 与其正文决策无矛盾。

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
