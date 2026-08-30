# flags 缓存的报文侧对位 · blob 通道不承载二进制（后端半）

- id: 2026-08-30-client-flag-cache-and-binary-overlay
- date: 2026-08-30
- topic: contracts/content-manifest（`no-cache` 层次澄清 + 后端零义务 + B 组第 7 条依赖登记 + blob 不承载二进制 + 两条 Open question 关闭）· decisions/ADR-0002（后果段措辞纠正）
- status: distilled
- distilled-to: contracts/content-manifest.md, decisions/ADR-0002-flags-channel-content-enabled-scope.md
- counterpart: `game-design-documents/handoffs/2026-08-30-client-flag-cache-and-binary-overlay.md`

> **本 handoff 只写归后端的那一半：报文形态、服务端义务边界、契约层的能力声明。** 客户端的缓存策略 / 失效语义 / 断网降级、overlay 合并期对二进制的处置与随包基线约束**全部归对侧**，见 `counterpart`。凡涉及客户端语义处一律写路径回链，不复述。
> 本库技术栈未定，本 handoff 停在协议与语义层面，不指定语言 / 框架 / 库 / 存储形态。

## Intent（distilled）

**一句话：** `contracts/content-manifest.md` 里两条「把球踢给对侧、而对侧未接」的 Open question 同批关闭；关闭动作本身零报文改动，真正新增的是三句只有本库有权威的话 —— `no-cache` 约束到哪一层为止 · 后端对客户端缓存的义务为零 · blob 通道的能力对文件类别中立。

### 1. `no-cache` 是传输层缓存指令，不约束客户端的应用层持久化

**这是本次后端侧最有价值的一句。** 端点表里 `/v1/content/flags` 的 `no-cache` 约束的是 HTTP 缓存层：中间层 / 代理 / CDN 不得把一份**按账号计算**的应答当作可复用对象存起来——它防的是灰度分桶串号。它**不是**、也无力约束「客户端把已应用的结果自己存一份用于降级」——那发生在应用层，存的是这台设备这个账号自己的结果。

不写清这一层区分，两个方向的误读都会发生：有人据 `no-cache` 反对客户端落盘（把一条防串号的传输指令当成禁止持久化的禁令），或反过来以为后端应当下发某种缓存策略字段去指挥客户端。**两者都错，且都只会在实现期才显形。**

落笔在 `content-manifest.md`「flags 通道」一节并回链 `envelope.md` §3 —— §3 说的是它**为什么**在 API 域，本次新增说的是它**约束到哪一层为止**；**不在 §3 侧复制第三份。**

### 2. 后端对客户端缓存的义务 = 零

四条否定性义务：不下发 TTL / `max-age` 语义字段 · 不在应答体回显 `accountId` · 不提升 `flagsSchema` · 不新增服务端保证。写下它们不增加实现负担，只减少日后被反复追问的次数——与本库既有的「A 组不提供的……」是同一种写法。

### 3. B 组第 7 条的依赖方从一项变两项（依赖登记，非新增条款）

客户端的降级缓存之所以能作为降级值使用，其正确性前提正是第 7 条「同一 `(flagsVersion, 账号)` 的解析结果恒定」：若允许同版本内容漂移，客户端盘上那批就不再等于服务端同版本的那批，而客户端只比版本号、没有任何手段发现这件事。

**条款本体一字不改**，新增的只是一行依赖登记（等值不拉 · 客户端降级缓存的可复用性）。**否决为此新写一条服务端保证**——第 7 条已逐字覆盖，新写一条 = 同一义务两处表述，两份各自漂移而无机制发现。

### 4. blob 通道不承载二进制资产，且**这不是契约能力不足**

对侧裁为「不开放」。本库侧：`files[]` 继续只承载 `.tres`；A 组四条、schema 字段表、签名形态、`manifestSchema` 一字不改。

**关闭时必须写清「这不是契约能力不足」**——若只写「不开放」，日后读到的人会合理地推断「大概是 CDN / 契约做不到」，然后在复议时把力气花在错误的地方。事实相反：报文层对文件类别中立，这一点已被「剧本文本」一节验证过一次。内容寻址 · 稳定 URL 与字节不可变 · 发布原子性 · 完整性覆盖面（一次验签 manifest 原始字节 + N 次 SHA-256）· `files[].path` 校验面——五项对非 `.tres` 逐字成立。**限制来自对侧的字段形态与其资源引用模型，不来自本契约。**

**否决把「blob 不承载二进制」写成 A 组第 5 条服务端保证**：它不是服务端的义务，而是对侧的合并纪律；写进 A 组等于声称后端会拒绝二进制文件，那既非事实（报文层不区分类别），也无人执行（CDN 直接服务静态对象）。正确落点是陈述 + 回链。

### 5. 若日后开放，三点核对项（条件化记录，不是待办）

`files[].size` 口径与磁盘预检在 MB 级下的运维含义 · A 组「字节级 Range 不写进契约」这条否定**须与对侧同批重估**（对侧那条否决带一个量级前提）· CDN 缓存与回源成本模型。**登记为待办会让 `04-content-delivery.md` 的清单虚长**，而该分片其余条目都是真待办。三点中的第 ② 条是本次唯一被识别出的、会被拆成两半后遗漏的跨库对位项。

## Clarifications

- **「换图 / 加图不发版」的取向题在对侧，用户已裁为「不开放」**（2026-08-28 批量评审）。本库据此把建议 5–7 按「不开放」落笔，三点核对项**维持条件化记录形态、不升格为待办**。
- **关闭 flags 缓存那条时必须纠正问句里的「以支撑离线开局」，这是强制项**：对侧启动 pull 是硬阻塞，强制在线下不存在「断网启动并进入轮回」这条路径。照原措辞关闭会把一个错误前提固化进本库契约。
- **该错误前提的纠正面比草稿点名的更宽，共三处：** 除 `contracts/content-manifest.md` 的 Open question 与 `open-questions/04-content-delivery.md` 表末行外，**`decisions/ADR-0002` 的后果段逐字保留着同一句**。草稿的落点清单漏了它——照原样落笔会宣称「已纠正错误前提」而实际留下第三处副本，且留在最难改的一侧。已同批改写为「flags 的客户端持久化形态已由对侧裁决 + 回链」，**`ADR-0002` 的决策本体（flags 只覆盖 `ContentEnabled`）一字不动**。第四处同款措辞在 `handoffs/2026-08-11-*`，属过程档案，不改。
- **`content-manifest.md`「剧本文本」一节的「上述三条服务端保证」是陈旧计数**（服务端保证现为 A 组四条）。本次必须同改，否则与紧接其后新写的五项能力表在同一屏内自相矛盾。**取去计数化**（改为「A 组的服务端保证」），与本库「Codex 顶层键去计数化」的既有做法同款。
- **草稿的四处引文订正：** 「已成文的四份契约」实为**六份**（`contracts/_index.md` 明写契约面六份）——照抄即把一个旧计数重新注回本库，故落笔取去计数化表述；约束 H 的「一次验签 + N 次 hash」是从既有两条推出的正确概括、不是文档原话，故只作论证用、不当既有条款回链；两条 Open question 的实际顺序与草稿列举相反（blob 在前、flags 在后）；建议 4 的「名单从一项变两项」实为**新造**一份显式依赖登记，现有形态是一段散文而非可枚举名单。
- **`no-cache` 层次澄清只落 `content-manifest.md`，不落 `envelope.md`。** 两处现有的「flags 归 API 域」段落已近乎逐字重复，不再制造第三份。

## Open questions

无新增。本 handoff 关闭的两条见 `answer-logs/log-client-flag-cache-and-binary-overlay.md`；`content-manifest.md` 的 Open questions 由四条降为两条（余下：多区域一致性 · flags 数据源与分桶的运营形态）。

## Notes / triage

- 落笔面两份：`contracts/content-manifest.md`（flags 通道追加两段 · B 组第 7 条依赖登记 · 剧本文本节的计数去计数化 · 新增「blob 通道不承载二进制资产」一节 · Open questions 删两条）· `decisions/ADR-0002-flags-channel-content-enabled-scope.md`（后果段末行）。
- **报文形态零改动：** `flagsSchema` / `manifestSchema` 均不提升，无新增 / 删除 / 改名字段，A 组仍四条、B 组仍三条，端点 / 域划分 / 缓存指令 / 签名形态无变化，`openapi.yaml`（尚未落笔）不受影响。
- 本库本次**无欠账**——两条都是本库把球踢出去、对侧接住并回传，`open-questions/cross-boundary.md` 的「待承接」不新增条目。
- 既有小漂移，记录不处理：`content-manifest.md` 与 `envelope.md` 的「flags 归 API 域」段近乎逐字重复（是否合并归一次独立对账）。

## 客户端侧影响

**本 handoff 不改动客户端 ↔ 后端边界的任何报文语义**——契约零改动，客户端零配合。

它与对侧**成对落笔**：对侧同批写下 `flags.json` 的落盘纪律（`schemaVersion` · 写入时点绑定「应用」· 失效三条 · 无 TTL）、`Artwork` 的 overlay 收口与非 `.tres` 文件的两道处置。权威回链 `game-design-documents/handoffs/2026-08-30-client-flag-cache-and-binary-overlay.md` 与 `game-design-documents/systems/services/content-service.md`。**本库不复述、不催办。**
