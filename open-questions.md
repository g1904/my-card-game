# Open questions — 后端待答清单（索引）

> 本文件是**后端**（云端服务）待答清单的**索引**；
> 问题条目本身按主题拆在 `open-questions/` 下的分片里。
> 客户端侧的待答清单在 `game-design-documents/open-questions.md`（`game-design` 分支），
> 两份互不覆盖：**一个问题落在哪一侧，看它由谁实现**。
>
> 此清单**只跟踪仍待答的问题**（不留已解决区），是导航 / 拾取清单，**权威归属在各主题文档**；
> 一旦答定就从分片中移除、归档进对应主题文档，并在 `answer-logs/log-<draftSuffix>.md` 记一笔。
>
> **最近更新：2026-09-08** —— 风控四张台账落形态、flags 服务文档建立，新开 `07` 内部工具片（详见 `open-questions/update-log.md` · `answer-logs/`）。
> （逐次更新摘要见 `open-questions/update-log.md`；答结归档见 `answer-logs/`。）

## 分片导航

| 分片 | 内容 |
|------|------|
| `open-questions/update-log.md` | 每次运行的更新摘要（答结 / 推翻 / 新增落点），倒序。不含问题条目本身。 |
| `open-questions/01-contracts.md` | **① 协议契约**（六份已成文，余一条错误码台账待核）：展开见表下 |
| `open-questions/02-account-compliance.md` | **② 账号与合规**（待答已清零，余一条外部事实挂账项）：展开见表下 |
| `open-questions/04-content-delivery.md` | **④ 内容分发（CDN）**（待答已清零，余条件化核对项与指路）：展开见表下 |
| `open-questions/06-platform-stack.md` | **⑥ 技术栈 · 托管 · 运维**（栈与运维形态已落定）：余一条成本模型，另有一节条件化核对项（昵称审核阈值，首版不启用故不定值）。 |
| `open-questions/07-internal-tools.md` | **⑦ 内部运营工具**（人工处置面）：两条——昵称人工复核台的形态（谁复核 · 经什么界面 · `claimed_by` 取值从哪来）· 风控工单的落点。两条同源，宜一并裁决。 |
| `open-questions/cross-boundary.md` | **跨边界承接**：客户端已定案、本库尚未落笔的条目。**不是待答问题**——答案已有，等的只是落笔；形态与关闭条件见分片抬头，机制设计见客户端库同名分片。 |

分片展开（承接上表）：

- **`01`** —— 六份契约**全部完全成文**（→ `contracts/envelope.md`、`content-manifest.md`、`auth.md`、`profile-sync.md`、`purchase.md`、`compliance.md`）；
  三条机检断言的工程承载亦已答结（设计库分支上的独立 workflow）。**余一条**：flags 端点零装载时的错误应答是否值得一条专属 `code`（当前走 §5a 兜底，不阻塞落笔）。
- **`02`** —— **待答已清零。** 身份模型、合规落地与多设备裁决、昵称审核口径、存量扫描、风控落地形态、**合规能力的上线分级（四项全部首版必备 · 昵称审核留位不启用）**均已答结
  （→ `contracts/auth.md`、`contracts/compliance.md`、`operations/moderation.md`、`systems/account.md`、`operations/deployment.md`、`operations/compliance-ops.md`、`vision/scope.md`）。
  余一条**挂账项**（须以真实过审要求核实，不是设计待答）：实名核验是否另需对接主管部门的实名认证系统。
- **`04`** —— 协议四条与运维三条均已答结（→ `contracts/content-manifest.md`、`operations/content-delivery-ops.md`），
  **剧本分包边界已由对侧答结**（不分包 → 客户端 `ADR-0029`，本库零机制增量）；
  **待答清单已清零**：多区域一致性以否定结论答结、传播窗口 T 重定义为跨实例窗口并取定初值。余一节条件化核对项（不是待办）与一张「已推给别处的」映射表。
- **`06`** —— 技术栈、托管形态与运维形态**均已落定**（C# / 腾讯云托管容器 / PostgreSQL 单主 / Redis / KMS / CDN，→ `systems/`、`operations/` 九份文档）；
  余下**两条**只差实测数据：成本模型（含收据归档与对账阈值的定值、剧本下载量上界）· `riskEventBufferRows`（风控事件旁路缓冲上界）。昵称审核两阈值已随 `02` 答结转为条件化核对项（首版不启用 ⇒ 不定值）。
- **`07`** —— **本次新开。** 内部运营人员坐在什么界面上做处置，全库此前零承载：昵称人工复核台的形态（尤其 `claimed_by` 的取值域 —— 本库至今无「内部人员身份」的概念）· 风控工单的落点。
  两条同源，宜一并裁决；不阻断已落笔的表形态，但阻断「复核链路端到端可用」。

> **编号 `05` 已空缺**：原「⑤ 剧本下发」分片于 2026-08-11 随云端剧本服务撤销而**整片删除**
> （剧本内容本地化为客户端内容层，见 `handoffs/2026-08-11-plot-service-retired.md`）。
> 编号不回填、不重排——`06` 的编号在别处已被引用，重排的代价高于留一个空位。
>
> **编号 `03` 已空缺**：原「③ 存档同步 / 冲突」分片于 2026-08-14 随 `contracts/profile-sync.md` 成文而**整片删除**
> （五条全部答结或被契约覆盖，实现层面的部分并入 `06`，见 `handoffs/2026-08-14-profile-sync-contract.md`）。
> 同样不回填、不重排。

## 当前焦点：`07` 内部运营工具面（新开），其次待实测取值与两条外部事实

**六份契约全部完全成文**——

- `envelope.md`（边界层，08-11）
- `content-manifest.md`（内容分发，08-11）
- `auth.md`（登录与会话，08-13）
- `profile-sync.md`（存档同步，08-14）
- `purchase.md`（付费验票与后端权威写入，08-16 · 三渠道接入面 09-03）
- `compliance.md`（实名 / 防沉迷 / 注销 / 导出，08-16 · 六端点报文字段表与端点自身错误码 09-03）。

**技术栈、托管形态与运维形态均已落定**（C# / ASP.NET Core · 腾讯云托管容器 · PostgreSQL 单主 · Redis · KMS · CDN），
`systems/` 三份服务文档与 `operations/` 九份文档全部建立——全库再无结构性前置。**合规能力的上线分级亦已答结**（四项全部首版必备 · 昵称审核留位不启用 · 两份发布前置清单），焦点因此落在一处新开的面与两类外部输入：

1. **`07` 内部运营工具面**（本次新开，唯一取决于设计取向的一条）—— 昵称复核台与风控工单的人工那一端，全库此前零承载；承重的是 `claimed_by` 的取值域，它是 `nickname_review` 租约归属这条不变式的键。
2. **`06` 两条待实测取值** —— 成本模型（实例规格 · 灾备副本数 · CDN 成本 · 收据归档与对账阈值的定值 · 剧本下载量上界，共同前置是 DAU 预期）· `riskEventBufferRows`。两条都不取决于任何形态决定。
3. **`01` 一条不阻塞的台账待核** —— flags 端点零装载错误应答是否值得专属 `code`，归 `envelope.md` §6 台账，下次触及契约面时一并核对。
4. **两条须以外部事实核实的项，不是设计待答** —— `02` 的挂账项（实名核验是否另需对接主管部门的实名认证系统，须以真实过审要求核实）·
   微信开放平台资质的审批到位时刻（`operations/external-providers.md` · `operations/deployment.md` 第一份前置清单第 4 项）。两者的共同处置都是：未到位则**推迟上线**，不降级放行。

## 判据：一个问题落在哪一侧

| 判据 | 归属 |
|------|------|
| 由客户端代码实现、后端不感知 | `game-design-documents/` |
| 由后端实现，或需要两侧约定报文 | 本库 |
| 客户端语义已定、只剩服务端如何兑现 | 本库（在条目中注明「客户端侧已定」+ 日期 + 回链） |

## derive 就绪度

> 本小节由 `/assess-derive-readiness` **独占写入**（`/analyze-new-ideas` 与 `/summarize-open-questions` 均不得改动）。就绪度需基于全库一次性全量扫描才有意义，顺带评估会迅速过时且互相矛盾。

**最近全量评估：2026-09-08（由 `/assess-derive-readiness` 产出）。** 扫描范围：`vision/`（2）· `contracts/`（7 份 `.md` + `vectors/splitmix64.json`）· `systems/`（`_index.md` + `account.md` + `profile-store.md` + **新建的 `content-delivery.md`**）· `operations/`（`_index.md` + 9 份正文）· `decisions/`（**60 份 ADR，全部 Accepted** + `_index.md`），共 **85 份**。旁证：`requirements/` **零 FR**（无「已覆盖」项）· `handoffs/` **40 份全为 `distilled`** 且 40 行台账逐条对齐（`raw` / `triaged` 仅出现在 `_TEMPLATE.md`）· `inbox/` 顶层为空（`archive/` 36 ↔ 36）· `answer-logs/` 33 ↔ 33 · `operations/_index.md` 9 ↔ 9 · `systems/_index.md` **3 ↔ 3**（09-07 那条声明式计划行已兑现）· `decisions/_index.md` 60 ↔ 60。

**全局结论：ready 12 份 · partial 5 份 · blocked 其余（全部为非 derive 对象或结构性 blocked）—— 全库主干已整体越过就绪门槛，可 derive 的份数由 7 增至 12，且新增的 5 份全部是「越过 partial 直接升 ready」或首评即 ready。** 09-07 记录的三条解锁路径**在 24 小时内全部兑现**：① `auth.md` §4 滑动截止的 `reasonKey` 消歧（`ADR-0053` 以「`reasonKey` 分辨玩家措辞而非机制自述」收编三种情形）；② `02` 合规能力的上线分级（`ADR-0054` 四项全部首版必备 · `ADR-0055` 第三方昵称审核留位不启用并写死唯一启用触发条件）；③ `systems/content-delivery.md` 建立（`ADR-0060` 另堵上落笔中推演出的 flags 版本预热自锁）。同期 `content-manifest.md` 的两条卡点由 `ADR-0051` / `ADR-0052` 钉死，风控四张台账的存储形态由 `ADR-0056`~`0059` 落形，ADR 由 50 份扩至 **60 份**。

**09-07 那份评估的以下判定已作废，本次逐条订正：** ①「`auth.md` 距 ready 只差一行消歧」→ 消歧已落，现为 **ready**；②「`02` 上线分级是唯一横切排除面」→ 已裁决，三处第④级排除面由「未裁决的占位」降级为**已裁决的否定断言**，不再构成就绪度卡点；③「`systems/content-delivery.md` 尚未建立」→ 已建立且首评即 **ready**；④「`content-delivery-ops.md` 的 A6–A9 孤儿路径」→ 已迁入新文档（**迁移而非复制**，双向回链、互不复述），该文件转 **ready**；⑤「`moderation.md` 卡于第三方适配器 + 台账存储形态两条」→ 两条均已消除，但被 `07` 新开的人工处置面顶替，判定仍为 partial；⑥「50 份 ADR」→ 60 份；⑦ **「跨边界两向零欠账」→ 不再成立**（见下方跨边界一节，本次唯一的结论反转）；⑧ 漂移清单 14 条中的 D-1 / D-2 / D-3（`vision/scope.md` 三处失真，曾连记五次）、`envelope.md` 抬头份数与前言漏列、13 处「ADR 候选」悬空指向、`_index.md` 写死取值条数、三处「归 `06`」悬空指路、`content-manifest.md` 缓存层悬空指路、`envelope.md` 文末跨库待办五项、`operations/_index.md` 自陈相抵、`06` 与 `02` 分类口径不一致 —— **全部已修平销号**。

**三条贯穿全库的判据说明（先读，避免误判）：**

- **判据 1 的形式说明（沿旧）。** 六份契约中只有 `content-manifest.md` 带正式 `## 意图` 标题；其余五份把同等分量的范围陈述放在标题下的 `>` 前言里。**全库无一处模板占位符 `> _..._`。** 判据 1 按「有真实内容」判定，**不按标题字面判定**。
- **库级 derive 限定语（沿旧，仍成立）。** `contracts/envelope.md` §1 自陈「在某端点的 spec 落笔前，其 markdown 字段表视为草案」。**处置不变：以 markdown 为源 derive，待 `openapi.yaml` 落笔时做一次纯形态对账——不作为闸门。** `openapi.yaml` 与 `schemas/` 至今不存在，符合「不预先建空壳」，触发点是任一侧首个端点进入实现。
- **「非 FR 面」不是欠账。** `vision/` 两份（北极星与五条裁决原则）、各 `_index.md` 台账、`vectors/splitmix64.json`、60 份 ADR 按定义就不是 derive 对象，**永远判 blocked 不代表缺内容**。给它们补验收标准会把北极星文档变成第二份契约。

**卡点结构已由「两类」缩为「一类新增 + 两类参数化」：**

- **🔴 `07` 内部运营工具面（本次新开，唯一取决于设计取向、且唯一制造孤儿路径的一条）** —— 人工处置那一端全库零承载。承重的是 **`claimed_by` 的取值域**：它是 `nickname_review` 租约归属与「迟到提交被拒」这条不变式的键，而本库至今没有「内部人员身份」的概念（`account` 表承载的是玩家）。**它不阻断任何已落笔的表形态与服务端保证**（M1–M11 断言的是数据库侧行为，与界面无关，`:reviewer` 可作不透明字符串参数化），**但阻断两处**：① 处置阶梯上半档（`restricted` / `banned` 的人工确认路径）——`moderation.md` 定「自动化止步于工单」，而工单进哪个系统、处置动作经什么面写回 `account.status`，**无归属系统可指**（判据 5 · 孤儿路径，与 09-07 对 A6–A9 的判法同款）；② 复核链路端到端可用性——本地词表两档分级是**首版就启用**的（`ADR-0055` 只否掉第④级第三方审核），故这一条不是可后置项。
- **🟠 `06` 两条待实测取值** —— 成本模型（共同前置 = DAU 预期）· `riskEventBufferRows`。两条**均不取决于任何形态决定**：能力要求、旋钮位置与校准公式已全部落笔 ⇒ derive 时一律写成「存在该旋钮 + 落 `config_knob` + 改值不发版」的形态断言，不取数字。同款纪律见 `profile-sync.md` §10 / §12。
- **🟠 `02` 一条外部事实挂账项** —— 实名核验是否另需对接主管部门的实名认证系统。它**不阻塞任何已落笔的形态**（分级结论、两份前置清单与合规六端点均按「只用商用持牌核验」成立），按 `04` 分片先例写进 FR 的 Scope 段作条件化核对项，不作验收断言。

**跨边界闭合（强制检查项）—— ⚠ 本库欠对侧 2 条，「两向零欠账」不再成立。**

- **本库欠对侧：2 条（🔴 新发现，且两侧台账都没有它）。** 来源 `handoffs/2026-09-07-manifest-schema-path-branch-and-cdn-failure-codes.md`，该 handoff 自陈「两项承接义务，归对侧裁决，本库不代为决定」：① 客户端须**按内置的 `manifestSchema` 支持集合拼出请求路径** `<contentRoot>/s<manifestSchema>/manifest`（而非固定 `/manifest`），是 `content-service` 启动链第一步；② 客户端须**对 CDN 域的 4xx 按两分处置**（入口对象 = 环境 / 配置面 → `PushWarning` 不上报；入口之后的对象 = 发布原子性被违反 → `Validation` + 上报 + 不重试），其中「不对 4xx 走 3 次退避重传」是对既有下载重试语义的一次**收窄**。**直读核实客户端库：零登记、零落笔** —— `game-design-documents/open-questions/cross-boundary.md`「待承接」为空；`systems/services/content-service.md:244` 讲的仍只是「schema 不受支持则跳过」这一版本比较，未提路径分支；`:253` 更新流程②仍写「失败重下该文件（指数退避，最多 3 次）」，恰是义务 ② 要收窄的那一句。
  > **病因与 08-14 那七点欠账逐字相同：告知写在了 handoff 里，而 handoff 不是台账——没有任何东西会再读它。** 后端侧已尽告知义务（有专节、并注明「客户端半可任意延后，当下零在架客户端无兼容负担」），但它**没有进入任何一侧的清单**。处置：补登进 `game-design-documents/open-questions/cross-boundary.md` 的「待承接」。**本技能只报告、不写对侧**（见该分片的「谁维护」一节）。
- **对侧欠本库：零。** 本库 `cross-boundary.md`「待承接」为空，其下 11 条对账基线全为已闭合留痕。**常规触发源未触发**——直读对侧 `profile-schema-versions.md`：`schemaVersion` 登记表仍只有 `1`（首发）一行，v1 首发形状清单虽已由 #34 扩至 **#37**（新增 `achievement` / `achievementGroup` 两个顶层键与 `ProfileChangeSpec` 的两列），但全部在 v1 行内 ⇒ 不构成 bump；本库 `operations/version-matrix.md` 的 `schemaVersion` 子表 `{1}` 无需新增行。三项均落不透明段、不进 §5 白名单，契约零改动（同 08-25 Codex 扩员的通则）。
- **两条常驻机械义务的本次核查结果**：① `profile-schema-versions.md` 新增行 ⇒ 登进 `version-matrix.md`，顺序恒为「矩阵先加、客户端后发」——**未触发**；② `auth.md` §4 任一条被改写 ⇒ 触发对侧重评 refresh token 本地存放取向——**未触发**：09-07~09-08 对 `auth.md` 的四处改动全部落在 §4 之外（§4a / §8 / §10 的落点回链重定向 + Open questions 收口），rotation / 60 秒宽限 / 「窗口外重放即吊销全部会话」语义一字未动。
- **预警仍未触发**（两侧均已登记）：`characterProfile` 的资源字段一旦提进透明档，必须同批把钳制语义与 `AppliedChange` 累加语义写进 `profile-sync.md`，否则后端复算会在正常账号上误报。直读核实 `profile-sync.md:63` `characterDiffs` 仍标「整体不透明」，`:168` / `:446` 明写否决提为透明 ⇒ 相关字段仍落不透明段。
- **09-07 记的三条客户端承接义务（内容签名 standby 公钥内置 · `OpError.Purchase` 成员 · 合规域三条新 `code` 的 `ERR_*` 与落屏）实为 09-05 即已成对采纳关闭**，本次逐条直读确认**均已落笔**（`content-service.md:279` · `architecture.md:134` / `:300` · `ux/error-and-blocking-ux.md:22` / `:329-335`）。该组就此销号。

| 文档 | 判定 | 卡点 / 就绪切片 |
|---|---|---|
| `contracts/auth.md` | **ready**（09-07 为 partial，**一行消歧兑现**） | 09-07 的两条卡点均已解除：① §4 求值顺序第四分支「`now ≥ refreshExpiresAtUtc`（滑动截止）」现已有取值——§4 补「**两个截止到期共用 `SessionExpired`**」与「`tokenId` 无从识别时取值同为 `SessionExpired`」，§10 该行改写为「**三种情形共用本取值**：滑动截止 / 绝对截止 / `tokenId` 无从识别」并附判据「`reasonKey` 分辨的是**玩家措辞**，不是机制」（`ADR-0053`），且逐条否决了单立 `SessionIdleExpired` / `CredentialUnknown`；② 判定链第④级已由 `ADR-0055` 裁决。**就绪切片 = 全文**：§1 / §1a 七端点 + 身份模型（`accountId` 自建 · 一对多 · 绝不隐式合并 · `channelUserId` / `idKind` / `sid` / `status` 不进任何报文，可写成否定断言）· §2 双 token 与 TTL 表 · §3 / §3a 渠道分形与换 openid 三条义务及两类错误映射 · §4 rotation + 60 秒宽限 + 四分支求值顺序 · §4a 会话裁决（`(accountId, deviceId)` 唯一 · 活跃上限 1 · 60 秒幂等回放 · `deviceId` 永不参与鉴权）· §5 / §5a / §5b 闸门只在 `signin` + 绝对寿命上限 60 天 + `reauthRecommended` · §6 头矩阵 · §7 七端点重放表 · §8 报文 + 四级短路判定链 + 13 行旋钮初值表（含 `TooFrequent` 已定值 3 次 / 30 天，`ADR-0043`）· §9 五个错误码 · §10 两张取值表 · §11。`## Open questions` 自陈「无待答项」。**排除面（已裁决的否定断言，不是卡点）**：第④级第三方审核适配器写成「恒返回 Pass、不产生任何外部调用」 |
| `contracts/content-manifest.md` | **ready**（09-07 为 partial，**两条卡点双双钉死**） | ① **分流机制已二选一**：`ADR-0051` 定「`manifestSchema` 双发走**客户端选路的路径分支**」`<contentRoot>/s<manifestSchema>/manifest`（`.sig` 同 · `s1` 从第一天就在 · **blob 不分支**），承重推论是判定方**只能**是客户端——CDN 域无鉴权、不带 `X-App-Version`、manifest 拉取排在登录之前；`appVersion` 服务端分流与 `?manifestSchema=` query 变体**双双否决**（后者曾是「会成为 §3 端点全集之外未登记形态」的隐患，随之消失）。保留时长改为「**覆盖率条件 ∧ 时间下界**」的 T0/T1/T2 三段式，`T2 = T1 + refresh 链绝对寿命上限`。② **CDN 三端点失败状态码已在契约层钉死**：`ADR-0052` 的 11 行表（端点 × 失败面 × HTTP × 可否负缓存 × 客户端处置）+ **4xx 两分判据** + 逐字写死「版本已被回滚 / 撤下这一失败面**结构性不存在**」（回滚 = 前滚）。**就绪切片 = 全文**：端点四行表（含字面量 `public, max-age=31536000, immutable`）· `manifestSchema: 1` 八行字段表 + 全量清单 / 路径穿越 / semver 三段比较 · ES256 detached（覆盖原始字节 · P1363 `r‖s` 非 DER · `keyId` 轮换 · 拒绝 `contentVersion` 回退）· 三版本号分工 · A 组四条 + B 组三条与三个失效来源的堵法 + `X-Flags-Version` 取 `min(高水位, 本实例可兑现)`（`ADR-0047`）· flags 报文五字段（`enabledIds` 恒空是硬契约）· 剧本 arc / node 分野 · 对客户端缓存的四行零义务否定表 · `## blob 通道不承载二进制资产`。全文无 `## Open questions` |
| `contracts/profile-sync.md` | **ready** | 维持 ready（08-28 之后本文件零编辑）。**就绪切片 = 全文**：§1 两端点封定（含「`accountId` 绝不进 query/body」否定断言）· §2 pull 三字段与建号骨架（`accountSeed` 16 位小写 hex · `revision=1`）· §3 六字段负载信封 + 空 diff 照常 `+1` + 未知 `reason` 宽容 · §3a 顶层键浅合并 · §4 三分支 + 幂等命中五行表 + **判定顺序**（`schemaVersion` → 形状 → CAS → 回声 → 写入）+ 四类拒绝均不消耗 `revision` + 「宽容不适用于 `schemaVersion`」的不对称声明 · §5 十三行白名单 + 后端写入封闭四行表 + 「够格进表」两条判据与三条反例 · §5a / §5b · §5c 完整四段 · §6 / §6a SplitMix64 + 8 组已填向量（外部权威 `vectors/splitmix64.json`，可逐位断言）· §7 复算三检查 · §7a 仅记账不拒绝 · §8 账号级线性化 + 读己所写 · §9 · §10 · §11 · §12。`## Open questions` 明写无待答项。**三条参数化纪律（不是排除面）**：风控事件写成「记一条结构化事件」· §10 的 60 次 / 分钟与 §12 四个初值写成配置阈值 · §4 的「`schemaVersion` 越出兼容集合」分支只断言形态、不断言边界 |
| `contracts/purchase.md` | **ready** | 维持 ready。**就绪切片 = 全文**：§1 三端点 + 全部需鉴权 · §2 写入只由 verify 承担、回调降为对账 · §3 请求根判别式（`oneOf` + `discriminator`，`ADR-0018`）+ 六行失败面表 + 不返回 `compliance.*` · §3a 三张渠道 `receipt` 字段表 + 三张渠道状态映射表 + `receiptId` 三渠道前缀 / 字符集 `[A-Za-z0-9._~-]` / 上界 1024 / 不截断不哈希 · §3b 下单端点与 `Unknown` 预落记录（`ADR-0019`）· §4 `status` 三值 + `Rejected` 复用 verify 终态 `code`（`ADR-0046`）· §5 复算沿用 §7a · §6 七条栈中立服务端保证 · §7 `receiptId` 全局唯一键 + 永久保留不设 TTL。`## Open questions` 自陈无待答项。**参数化项**：归档触发三阈值与对账信号 N 待实测，但形态、旋钮 key 与校准公式已由 `operations/purchase-ops.md` §3d / §4 与 `ADR-0045` 定死 |
| `contracts/compliance.md` | **ready** | 维持 ready，且 §1 已补「四项能力**全部首版实装**」（`ADR-0054`）。**就绪切片 = 全文**：§2 六端点集与鉴权形态（撤销走 `POST .../cancel`）· §3 ticket 机制（一次性 · 10 分钟 · 单端点 · 不进 `Authorization` 头 · 60 秒兑付回放窗口 · 兑付不签发 token）· §4 拦截只在 `signin` · §5 四条 `compliance.*` 拦截码 + 七值 `reasonKey` 表 + **求值顺序写死**（`ADR-0037`）· §6 时段口径落配置 + 可信服务端时钟 · §7 防沉迷复用 `auth.session_revoked` 五步映射 · §8 导出正列白名单 · §9 九行旋钮初值 · §10 六端点报文字段表（`ComplianceRealnameStatus` 四值 · `isMinor` · `playtimeRemainingSeconds` 为相对量 · `deletionEffectiveAtUtc` · `nicknameChangeRequired` · `downloadUrl` 每次现签 · `taskId` 形态 `^[0-9a-f]{32}$` · 导出四状态机）· §11 三条端点自身错误码及各自 `reasonKey`。**09-07 记的「陈旧 `## Open questions` 条目应清理」已兑现**——该章节整体已不存在，判据 2 由「已有决策覆盖」升为**直接成立** |
| `systems/account.md` | **ready**（09-07 为 partial，唯一卡点已由 `ADR-0055` 裁决消除） | **就绪切片 = 全文**：存储形态承重列**已由七表扩到十一表**（新增 `risk_event` 月分区 + 双索引 · `deletion_audit` · `nickname_review` 四索引含部分唯一 · `nickname_scan` 双索引）· 事务边界七行表（含 `signin` 两步反序的实现纪律 · 注销执行行含十一表删除清单与 `deletion_audit` 这一唯一例外）· `tokenId` 与 `sid` 的分工 · refresh token 五分支校验（两处叶子 `reasonKey` 已由 `ADR-0053` 补齐）· access token 签发四条 · 渠道能力适配层两条纪律 · 昵称判定链 **N1–N10 全表（含 N9）** · 存量扫描 **S1–S5** · 合规域 **C1–C6 / D1–D7 / E1–E6 / P1–P5**（P 组为 09-07 新补的时段判定保证，是对 `compliance-ops.md` 既有形态的机械对位）。无 `## Open questions`。这三组表本身即模板要求的「给定请求 / 状态 → 期望应答 / 存储结果」形态，逐行可直接落成验收标准。**两块排除面（均为已裁决的否定断言或窄项，不是卡点）**：① 判定链第④级 + N9 → 写「恒返回 Pass、不产生任何外部调用」；② `nickname_review.claimed_by` 的取值域（`07`）→ 仅影响该列的类型 / 来源断言，不触及任何 N / S / C / D / E / P 行。**参数化纪律**：改名频次上限 · ticket 寿命 / 60 秒回放 · 冷静期 15 天 · 导出保留期一律写「配置阈值」 |
| `systems/profile-store.md` | **ready，无排除面** | 维持 ready（09-06 之后零编辑）。**就绪切片 = 全文**：承重列四表 · 事务边界四行 · 四条实现纪律（CAS 用受影响行数分支 · 判定顺序照契约写死 · 类型感知语义相等 · 零判定权字段关闭 enum 严校验而驱动判定的枚举仍封闭）· 两类幂等记录的分轴对照 · `push_idem` 月分区与「条数降级为观测阈值」· `receipt_idem` 全局唯一键与同事务序号推进 · 读己所写「玩家读路径全走写入区」· 512 KB 体积软告警。依赖全闭合（`contracts/profile-sync.md` 与 `contracts/purchase.md` 双双 ready）；`ADR-0008` · `0013` · `0017` · `0021` · `0045` 全 Accepted |
| `systems/content-delivery.md` | **ready**（**本次新建 · 09-07 时不存在，首评即 ready**） | 它是 09-07 三条解锁路径之一的兑现物（`handoffs/2026-09-08-flags-service-internal-doc-home.md`），且**只迁不复制**——`content-delivery-ops.md` 的 A 表止于 A5，原位留一行回链，新文档自陈「运维形态的权威在 ops，本文件两者都不复述」，双向回链、互不复述。**就绪切片 = 全文**：**三份缓存的分工表**（规则集缓存 / 当前版本读取缓存 / 应答签名结果缓存 —— 键 · 值 · 位置 · 生命周期四列，并写明混用任意两份各破坏哪条纪律）· 规则集缓存必须进程内不得落 Redis 的承重理由（落 Redis 则「本实例能兑现的最大版本」当场失去指称对象）· single-flight 回源 · **版本预热的请求无关触发**（`ADR-0060`，并给出懒加载 + 「头永不领先」合成自锁的完整推演，及「全体一致地落后 ⇒ 极差恒为 0 ⇒ 现有探针发现不了」）· 「一次快照引用」的应答构造手法（把「应答体 `flagsVersion` 绝不取自高水位」从纪律变成结构上不可能违反）· `X-Flags-Version = min(高水位, 本实例可兑现)` 与偏斜不对称性 · 取数面 = 已装载的最大键 · **回源失败三分支降级**（已装载旧版本则以旧版本兑现不报错 / 零装载则报 `Retryable` 且绝不以空 `disabledIds` 兑现 / 失败不写负缓存）· LRU 上限 8 · 四条实现纪律 · **服务端保证 F1–F8**（与 `account.md` 的 N / S / C 同体例，逐行可转验收）。**两块窄排除面**：① 「存储形态：承重列」与「唯一写入面与事务边界」两节仍是**回链占位**（实体在 ops 的 A1–A3 / A5），方向与 `account` / `profile-store` 相反，handoff 已明写「方向反转被接受、待下次触及时补齐」⇒ FR 的 `Data & state touchpoints` 需跨文档取；② 零装载错误应答是否值一条专属 `code` 归 `envelope.md` §6 台账（`01` 唯一待答项），F7 已用 `server.unavailable` / `Retryable` 兜底，**不阻断** |
| `operations/content-delivery-ops.md` | **ready**（09-07 为 partial，**孤儿路径卡点已消解**） | 09-07 的唯一卡点（判据 5 · A6–A9 的 FR `service:` 无处可指）作废——`systems/content-delivery.md` 已建立并承接，`systems/_index.md` 台账 3 ↔ 3 对齐。**就绪切片**：CDN 两类对象两种 TTL · **内容发布流水线 ⓪–⑦ 全序**（含 ③b DER→P1363 编码归一 · ④ 必须用客户端内置公钥自验 · ⑤ 探针走 CDN 域）+ **双发期读法五条**（步 ②③④ 各分支各签各验 · 步 ⑥ 分支间不要求原子 · 步 ①⑤ 不变 · `contentVersion` 单序列）· **发布侧校验闸 C1–C6**（尤其 C6 逐在架基线各跑一遍，`ADR-0050`）· 留痕八字段（含 `gateAttestation`、双发期 `manifestSha256` 双值）· **A1–A5** 规则集存储形态与变更通道（不可变版本化 · `bucketSalt` 随版本冻结 · `publish` 为唯一写入面且 `rollback` ≡ `publish` · 直连写入权限禁止 · A5 指纹自检）· flags 发布 / 回滚 **O1–O7 与留痕四项** · B1–B5 私钥保管判据与 standby（`ADR-0049`）· `keyId` 轮换三类触发 / 四阶段 / 覆盖率 95% 口径 / T2 后 48 小时观察窗与回切 · 传播窗口 T 的口径、三项预算与 gauge 极差探针 · **数值初值一览 10 行全部有初值**。**明确排除面（文档自陈，不构成卡点）**：A4' 池规模缩放（已定形态 · 未采纳，触发前一字不动）· 对 CDN 的能力要求与三路径负缓存（基础设施配置）· 内容校验规则本体（权威在客户端库，本库只验背书，`ADR-0048`） |
| `operations/purchase-ops.md` | **ready** | 维持 ready。**就绪切片 = 全文**：§1 三渠道凭据与轮换 · 托管形态（云 Secrets · 渠道 × 环境 · `credentials[]` 新旧并存 · 5 分钟周期刷新）· **收据环境校验以部署环境配置为准、不以收据自述为准** · §2 三条对账通道 +「推送只作更快知道、周期拉取才是正确性来源」+ 对账不驱动任何自动写入 · §3a S1–S3 选型判据 · §3b 哈希分区与部分索引 · §3c **TTL 禁用断言**（部署时读取过期策略，非「永不过期」即拒绝启动）· §3d 三层分工 / 哨兵行五列 / 读路径五分支 / 归档任务三步顺序不可颠倒 / 断言逐表逐分区覆盖 / 同一 PITR 一致点 · §4 两条对账信号与 N 的校准公式 · §5 风控高优四项。**三块排除面**：§3a 退化形态（S1 已由单库 PostgreSQL 满足）· §3d 归档任务（`receiptArchiveEnabled` 初值 `false`）· **下单端点的滥用阈值**（无初值、无旋钮 key、不在任何旋钮表 ⇒ 只能写形态断言「须有按账号频次上限，同构 push 滥用阈值」，不能写值；该处另有一条遗留旧就绪度断言，见漂移清单） |
| `operations/compliance-ops.md` | **ready** | **就绪切片 = 全文**：可信时钟基准与两处例外 · 同步纪律（只 slew 不后跳 · 不可逆动作在时钟异常期间暂停一轮）· 时段规则集承重列与「判定时读当前最高版本、不做预约生效」· 法定节假日日历两类条目与**四步判定顺序**（`WorkingWeekend` 排最前）· F1 / F2 / F3 三个失败面的降级语义与降级路径下 `resumeAtUtc` 取兜底周规则 · ticket 条件更新 + 受影响行数分支 + **五级短路求值顺序** + 「消费时把 `expires_at_utc` 拉到 `max(原值, +60 秒)`」· 外部核验两段事务与终局出路 · 注销冷静期状态三值与三端点分支 · **执行时删什么已由九行扩为 13 行表**（新增 `nickname_review` / `nickname_scan` 硬删两行 + `deletion_audit` 保留一行）与保留项的硬理由 · 导出任务部分唯一索引 / 私有桶 / 每次现签 15 分钟链接 / 白名单序列化器三条断言 / 两道保留期 · 周期任务四条与八个旋钮的校准信号 · 上线分级四行表。ADR 前置齐备（`0028`~`0037` 全 Accepted）。**条件化核对项（不作验收断言）**：`02` 的主管部门实名认证系统接入义务，按 `04` 分片先例写进 Scope 段 |
| `operations/external-providers.md` | **ready** | **就绪切片 = 全文**：A1–A6 共有形状 · 四个接口签名 · **三张归一映射表**（按调用点所在域取 · `auth.challenge_expired` 永不来自服务商 · 不可达归 `code` 的判据是有无 `retryAfter`、不得靠 `providerCode` 分支）· 逐能力供应商数与灾备判据表 · 短信切换触发判据与回切滞后（可写成定量断言）· 禁并发双发 / 同码转备用至多一次且只在首家未返回受理 id / 禁双验 ·「一次 `challenge` 至多两次外部调用」· 选型判据 H1–H4 / S1–S4 · 凭据托管（能力 × 供应商 × 环境，独立审计线）· 可观测性五行增量与余额低水位两档 · 微信资质过闸断言 · 数值初值六行。`ADR-0038`~`0042` 全 Accepted。**排除面较 09-07 收缩**：昵称审核阈值面由「未裁决占位」降级为**已裁决的否定断言**——灾备表该行原文即「第三方昵称审核 · **0（首版不启用）**」（`ADR-0055`）⇒ FR 直接写「首版该能力供应商数为 0，判定链第④级恒 Pass」。**余下排除面两块**：不点名具体服务商（A6 把归一点放在调用方、适配层只产 `Outcome` 三档，FR 因此与服务商无关，这正是该抽象的设计目的）· 微信资质前置链（外部审批日程，非 FR） |
| `operations/moderation.md` | **partial**（09-07 的两条卡点**均已消除**，被 `07` 新开的一条顶替） | **两条旧卡点作废**：① 第三方适配器启用与否 → `ADR-0055` 已裁决，降为排除面；② 台账自身的存储形态仍待 `06` → 已由 `ADR-0056`~`0059` + 新增整节答结（`06` 现只余两条待实测取值，且自陈不阻断 derive）。**就绪切片（较 09-07 大幅扩张）**：词表两档分级与不可变版本化发布 · 存量扫描 T1 / T2 / T3 与台账六字段 · 处置阶梯三档（「须改名」豁免拦截不豁免计数）· `nicknameChangeRequired` 由云端状态算出、改名 push 后由 T1 比对自动清零、不在端点判定通过那一刻清零 · 风控事件字段表与 `kind` 十值 · 累计阈值分档与全局熔断（1% / 0.5%）· **新增「四张台账的存储形态」整节**（四表总纲 · `risk_event` 月 RANGE 分区与整分区 `DROP`、主键 `(occurred_at_utc, event_id)`、两条索引各对一条已写死的读路径、**不建 rollup** ·「只追加」禁的是什么与恰有两条非业务删除路径 · 旁路有界缓冲与三类同事务例外 · `deletion_audit` 3 年不删 · `nickname_review` 条件 `UPDATE` 取租约含 SQL 骨架与部分唯一索引 · `nickname_scan` 一行一账号 · **过期方向判据表**）· **服务端保证 M1–M11** · 数值初值表 16 行。**卡点（🔴 `07` · 判据 5 孤儿路径）**：`claimed_by` 是「内部人员身份」标识而全库无此概念 ⇒ 该列的类型 / 来源写不出断言；且「自动化止于工单」的**工单落点无归属系统**，`restricted` / `banned` 的人工确认经什么面写回 `account.status` 无处可指。⇒ **可 derive = 四表存储形态 + M1–M11 + 词表发布 + 扫描 T1–T3 + 阈值与熔断**；**须整体排除 = 处置阶梯上半档的人工确认路径 + 复核队列的端到端可用性** |
| `operations/deployment.md` | **partial**（小切片，主体属非 FR 面；可产出 FR 的面**由 2 处扩到 5 处**） | **可产出 FR 的**：① **启动自检解析时区名失败即拒绝启动**（给定规则集含不可解析 IANA 名 → 进程拒绝启动，`ADR-0029`）；② G-1「`/v1/auth/refresh` 上不存在任何返回限流码的限流」与 G-2「push 走应用层账号维度」两条否定断言；③ **两份发布前置清单中带机检形态的过闸断言**（清单一第 4 项 `idKind` 落 `unionid` · 第 5 项 `realName` / `idNumber` 在应答 / 日志 / `response_snapshot` 零出现 · 第 6 项时段规则集 `version ≥ 1` 且含 `WorkingWeekend`、非允许时段 `signin` 得 `compliance.playtime_blocked` + `detail.resumeAtUtc`）。**非 FR 面**：构建与制品 · expand→deploy→contract · 两份清单的人工过闸流程 · 周期性运维日程 · 共享 DTO 护栏。**未闭合项（自陈，非漂移）**：`contract-spec-check` workflow 与校验脚本**尚未落地**（已实测：仓库无 `.github/workflows/`、无 `scripts/`），三条机检断言当前以人工清单前三项执行——**首批 FR 落笔时会撞上它** |
| `operations/environments.md` | **partial**（窄切片，宜随服务 FR 兑现；切片略扩） | **就绪切片**：**「限流的实现分层」整节**（fail-open 默认 · 三条 fail-closed 例外：验证码短信计数 / 实名提交 / 未成年时段判定，`ADR-0031` · Redis 不可用放行并告警 · `refresh` 零限流的否定断言 · `Retry-After` 与 `detail.retryAfterSeconds` 同时给）· 密钥轮换「旧 `kid` 保留 ≥ access token TTL + 时钟偏移余量」· **本次新增可断言项**：「定时任务出口」的 `SELECT … FOR UPDATE SKIP LOCKED` 条件转移（多副本互不重叠、崩溃即回滚下一轮重领）· `identifier_mac = HMAC(...)` 明文不落库不落日志 · 本地开发 `kid` 空间与线上永不共用。**其余属非 FR 面**：环境实体 · 配置三层与旋钮清单（数据登记）· 区域与合规 · 拓扑与副本 · 容量形状 · 密钥保管。**已声明的排除（非卡点）**：实例规格 / 副本数 / 备份保留期待成本模型（`06`），文档已明写「不在此定稿」、只写能力要求 |
| `operations/observability.md` | **partial**（窄切片，宜随服务 FR 兑现；切片扩了两组） | **就绪切片 = 探针发射面**：五条契约语义探针——尤其「透明路径缺失」的**带前提判定**（只有该顶层键出现在本次 diff 中时才检查其下白名单路径）与「未知 `schemaVersion`」的**按大小关系二分** · CAS 冲突率与回声拒绝率分开计数 · **日志脱敏中间件**（给定含 token / `downloadUrl` / 姓名 / 证件号的事件 → 输出中不出现明文，纯否定断言）· 合规域三条探针与时钟两条探针 · 日历到期告警 · **本次新增两组**：flags 版本预热落后量 gauge（`flagsVersionHighWater − 本实例可兑现最大版本`，持续 > T 即告警，`ADR-0060`，它正是「全体一致地落后」这个极差探针盲区的补位）· 风控台账四条探针（`risk_event` 分区裁剪滞后量是「个人信息超期留存」唯一的机制发现面）。**非 FR 面 / 参数化**：告警阈值与 P1 分级属运维配置 · RED / 连接池 / 复制延迟属基座通用监控 · 时钟两条探针阈值待实测校准 |
| `operations/version-matrix.md` | **partial**（窄，宜随 auth / content FR 兑现；**卡点缩小一半**） | **就绪切片**：四项形态表 +「当前矩阵」四行 + `schemaVersion` 集合已展开为**一版一行的四列子表并登入 `1`**（第四列为客户端登记回链，本库一个字段名都不写——可作否定断言）· 「闸门在签发 token 时判定一次、会话期内不中途变严」· 「提升 `appVersion` 下界的覆盖上限 = refresh 绝对寿命」· `schemaVersion` 登记流程「矩阵先加、客户端后发」的顺序断言 · **`manifestSchema` 双发下线序列 T0 / T1 / T2 三时点已完整落表**并回链 ops 的覆盖率口径（明写不复制第二份，`ADR-0051`）。**卡点已收窄为两个取值**：`appVersion` 下界仍「待定」· `schemaVersion` 行的「接受起始」为「首个版本上线时（待落）」⇒ `client.version_unsupported` 与 `sync.payload_schema_unsupported` 两码的**形态可断言、边界不可断言**，并向下传导进 `profile-sync.md` §4。矩阵数据本身是旋钮登记，属非 FR 面 |
| `contracts/envelope.md` | blocked（**结构性，非欠账**） | 共有层，**不存在独立可构建的增量**（无自身端点即无「请求 → 应答」验收断言），故即便内容极完备也判 blocked——FR 只能挂在其他契约的端点上兑现（`X-Flags-Version` 的验收挂 `/v1/content/flags`，`class` 四值挂具体 `code`）。**内容上已完备、随首个 FR 即可兑现**：§1 表达形式与 spec 落笔规则 + 降级形态 · §2 序列化八条（含 > 2⁵³ 走字符串 · 绝不下发 `null`）· §3 **端点全集表 + P-3 机器读取面护栏**（`manifestSchema` 路径分支三行已同批改，只改行内容不改表结构 ⇒ 提取脚本无须同改）· §4a 无鉴权例外**判据**（含 `GET /v1/compliance/status` 这个负例，`ADR-0016`）· §4b 应答头五项 · §5 错误体五字段 + §5a 脱敏 + §5b 三条降级 · §6 **30 行错误码台账 + P-1 护栏**（`class` 随 `code` 恒定是可断言不变式）· §7a–§7d · §8 三段可见性。`ADR-0003` Accepted。`## Open questions` 唯一条目是 `openapi.yaml` 落笔，**自陈属待落笔项而非设计未决**，不是就绪度卡点 |
| `systems/_index.md` | blocked（**非 FR 面**） | 索引 + 三份服务文档的公共前提。「共用的存储与并发形态」六条与「契约条款 → 数据库不变式」五行表是实质内容、可直接转为断言，但**无独立可观测的应答 / 存储结果**（触发拆解下界 L1 / L2）⇒ 落点应在 `account` / `profile-store` / `content-delivery` 的 FR 内。「明确不引入」四条是否定性架构结论，同理。**台账：服务表 3 行 ↔ 3 份实际文件，09-07 那条声明式计划行已兑现**，零悬空行、零孤儿文件 |
| `operations/_index.md` | blocked（**非 FR 面**） | 台账 **9 行 ↔ 9 份正文，逐条对上、全标「已建立」，零悬空行、零孤儿文件**。**09-07 记的两处自相抵触均已修复**：自陈已改写为「除文档表外只保留两节**跨文档的交叉点**——它们记的是某个运维面对其余运维面提出的要求与登记流程，落在任何单一文档里都会成为那份文档的越界内容」；收据幂等 TTL 断言已压回纯回链「见 `purchase-ops.md` §3c，本索引不复述其形态与理由」。**残留半句待收**：该行仍在正文断言「它与 O6『历史规则集永久保留』是同形取舍」（见漂移清单） |
| `contracts/_index.md` · `contracts/vectors/splitmix64.json` | blocked（**非 derive 对象**） | 索引 / 台账与机器可读的对表产物。`_index.md` 承载契约面清单、分域判据、「契约变更的完成判据」六条 + 三条机检断言 + 人工清单四项 + 两条提取护栏 + `schemas/` 拆分判据——全部是**流程约束与元规则**，无端点无报文，写不出「请求 → 应答」断言；六份契约状态列均为「已成文」。**09-07 记的「写死取值条数」已修**：现写「条数以 `auth.md` §10 为准、此处不复述——它按设计会持续扩张，写死一个数目就是一份会漂移的副本」。`splitmix64.json` 是 `profile-sync.md` §6a **唯一可执行的验收检查点**（8 组已填，两侧实现后逐位对表，不得单方面改表迁就实现），`_index.md` 已明写它不属 spec、三条机检断言不覆盖它 |
| `vision/scope.md` · `vision/pillars.md` | blocked（**非 FR 面**） | 北极星与五条裁决原则，只陈述边界与硬约束，**零可验证行为断言**——`scope.md` 最接近断言的「硬约束」三条都是对协议的**元要求**（协议必须对重试与幂等成立 · 后端只能约束不能改变写入语义 · 不承诺跨内容版本可复现），写不成「给定请求 / 状态 → 期望应答 / 存储结果」。作为其余文档的挂靠前置成立（`pillars.md` 为 `profile-sync` 的「幂等与 CAS 是承重」、`purchase` 的「读己所写」、`content-manifest` 的「热更优先于跨版本可复现」提供承重论证），自身不产需求。**建议不进入 derive 候选池。** **连记五次的 D-1 / D-2 / D-3 三处失真本次全部消解**：In scope 已由四条扩为六条并独立列出合规域与付费验票域 · 抬头与文末两处「技术栈全未定」已改为「已落定（`ADR-0021`）」· 边界表三行已把合规六端点与付费验票三端点各自落位。`scope.md` 文末自陈「范围面本身无待答项」，成立 |
| `decisions/ADR-0001` ~ `ADR-0060`（**60 份全部 Accepted**）· `decisions/_index.md` | blocked（**非 derive 对象**） | 已采纳的决策记录与台账，作为其余文档的就绪前置，本身不产 FR。**就绪判据第 3 条对六份契约与全部 `systems/` `operations/` 文档全部成立**——**无一份文档受任何 `Proposed` / 未采纳 ADR 约束**（60 份逐份核对，非 Accepted 者 **0** 份）。**台账 60 行 ↔ 60 份实际 ADR 逐条一致**（`ADR-0001`~`0060` 连号无缺），无孤儿文件、无悬空行。「ADR 候选」小节确已于 08-19 整节删除（现存唯一「ADR 候选」字样出现在「已对后端构成约束的客户端决定」表内，指的是**客户端侧**的候选，属正当引用） |

### 建议的 derive 顺序（被依赖的契约先于依赖它的系统）

**第一波 —— 两条完全无排除面的纵向切片：**

1. **`/derive-requirements backend contracts/profile-sync.md`** —— 全库最成熟的一份。协议面完整、ADR 前置齐备、跨边界两向对它零欠账，且有 `vectors/splitmix64.json` 这个全库唯一可执行的验收检查点。**无排除面**，遵守三条参数化纪律即可。
2. **`/derive-requirements backend systems/profile-store.md`** —— 紧接上一份，同一条纵向切片的服务内部面（承重列 · 事务边界 · 两类幂等记录 · 读己所写）。**无排除面。** 与 1 合并成一次 derive 亦可，但分开更贴「一个 FR = 一个可构建增量」。

**第二波 —— 购买纵向切片（契约与运维面双双 ready）：**

3. **`/derive-requirements backend contracts/purchase.md`** + **`operations/purchase-ops.md`** —— `## Failure & retry semantics` 可写全。三块排除面标清（§3a 退化形态 · §3d 归档任务默认关闭 · 下单端点滥用阈值只写形态）。

**第三波 —— 合规纵向切片（三份全 ready，只带一个外部事实挂账项）：**

4. **`/derive-requirements backend contracts/compliance.md`** + **`operations/compliance-ops.md`** —— 六端点逐端点断言可写全，四项能力首版全实装已由 `ADR-0054` 定死，不再需要「首版做哪几项」这个范围参数。`02` 的主管部门实名认证接入义务写进 Scope 段作条件化核对项。
5. **`/derive-requirements backend operations/external-providers.md`** —— ready，且它是 4 与 6 的共同下游依赖（三张归一映射表）。排除第三方昵称审核能力面（供应商数 0，写否定断言）与微信资质前置链。

**第四波 —— 账号与会话纵向切片（本次由 partial 升 ready，是本轮最大的解锁）：**

6. **`/derive-requirements backend contracts/auth.md`** + **`systems/account.md`** —— 09-07 那条「落笔前先做一句消歧」的前置动作**已不再需要**。两块排除面写成否定断言即可（第④级恒 Pass · `claimed_by` 类型面留待 `07`）。`version-matrix.md` 与 `deployment.md` G-1 / G-2 的窄切片随本波兑现。

**第五波 —— 内容分发纵向切片（三份全 ready，本次由「排除面最大」变为「零机制卡点」）：**

7. **`/derive-requirements backend contracts/content-manifest.md`** + **`systems/content-delivery.md`** + **`operations/content-delivery-ops.md`** —— 09-07 的「前置动作：先裁决 A6–A9 的 FR 归属」**已兑现**。`systems/content-delivery.md` 的 F1–F8 与 ops 的 C1–C6 / O1–O7 / A1–A5 可直接落成验收标准。**排除**：A4' 池规模缩放 · 客户端侧义务 · 承重列两节需跨文档取。**落笔前建议先补登本库欠对侧的那 2 条**（见跨边界一节）——它们正是这一波的客户端对位面。

**第六波 —— 昵称与风控（唯一带真实卡点的一份，宜排最后）：**

8. **`/derive-requirements backend operations/moderation.md`** —— 只 derive「四张台账存储形态 + M1–M11 + 词表发布 + 扫描 T1–T3 + 阈值与熔断」这一半；**整体排除处置阶梯上半档的人工确认路径与复核队列端到端可用性**，等 `07` 有答案。若 `07` 先于本波答结，则本份可整体转 ready 并提前。

`envelope.md` **不单独 derive**（共有层，随上述任一份的**首个** FR 一并兑现信封、错误体与相关错误码）。`operations/environments.md` · `observability.md` · `deployment.md` · `version-matrix.md` 的窄切片**均不单独 derive**，随对应服务的 FR 一并兑现。

> **注意：首批 FR 会同时触发 `openapi.yaml` 的首落**（`contracts/_index.md` 定：触发点 = 任一侧首个端点进入实现，首落范围 = **全部共有层 + 该一个端点**，且 spec 始终落本库）。同批须过「契约变更的完成判据」六条 + 三条机检断言 + 人工清单四项——注意 `contract-spec-check` workflow **尚未落地**（已实测确认仓库无 `.github/workflows/`、无 `scripts/`），当前以人工清单前三项执行。

### 最短解锁路径

1. **🔴 补登本库欠对侧的 2 条承接义务** —— `manifestSchema` 路径分支拼法 · CDN 域 4xx 两分处置（含收窄「指数退避最多 3 次」）。它们**不阻塞本库任何一份的 derive**，但两侧不一致的代价是上线才炸，且这类被拆成两半的跨边界意图「第二半经常不会发生」已在本项目发生过两次。→ 在客户端库补登 `open-questions/cross-boundary.md`「待承接」，或直接 `/analyze-new-ideas game`。**本技能只报告、不写对侧。**
2. **🔴 `open-questions/07` 内部运营工具面** —— 本次**唯一**取决于设计取向、且唯一制造孤儿路径的一条。一条答案（尤其 `claimed_by` 的取值域 = 有没有「内部人员身份」这个概念）同时解锁 `moderation.md` 的处置阶梯上半档与复核链路端到端可用性，并让「自动化止于工单」的工单落点有归属系统可指。两条同源，宜一并裁决，不要各定一套内部身份。→ `/analyze-new-ideas backend`
3. **`operations/version-matrix.md` 的两个取值** —— `appVersion` 下界 · `schemaVersion` 的「接受起始」。**不阻断 derive**（形态可断言、边界不可断言，参数化即可），但它向下传导进 `profile-sync.md` §4 与两条 `code` 的边界断言，首个在架版本产生时即可填。
4. **🟠 `06` 两条待实测取值** —— 成本模型（前置 = DAU 预期）· `riskEventBufferRows`。**均不阻断 derive**：形态、旋钮 key 与校准公式已全部落笔，参数化即可。等实测数据，不必急于关闭。
5. **🟠 `02` 一条外部事实挂账项** —— 实名核验是否另需对接主管部门的实名认证系统。须以真实过审要求核实，**不是设计待答**；未到位的处置是推迟上线、不降级放行。同类的还有微信开放平台资质的审批到位时刻。
6. **`01` 一条不阻塞的台账待核** —— flags 端点零装载错误应答是否值得专属 `code`（当前走 `envelope.md` §5a 兜底的 `server.unavailable` / `Retryable`）。derive `/v1/content/flags` 时按兜底码落笔并标注该条可能后续替换；归 §6 台账，下次触及契约面时一并核对。
7. **`contracts/envelope.md` · `contracts/_index.md` · `vectors/splitmix64.json` · `vision/` 两份 · 60 份 ADR · 各 `_index.md`** —— **无解锁路径，也不需要**：共有层的 blocked 是结构性的（随首个 FR 自动兑现）；台账 / 对表产物 / 裁决原则 / 决策记录按定义就不是 derive 对象，**永远判 blocked 不代表有欠账**。

### 本次核实到的台账漂移（非就绪度断言，不阻塞 derive，建议同批处理）

全库主题文档与 `handoffs/` 中的**遗留旧就绪度断言：1 条**（见下方第 2 条；「可 derive / 暂缓 derive / 解锁 derive」在全库零命中）。

**已闭合、本次销号的旧漂移条（09-07 清单 14 条中的 10 条）：** ① `envelope.md` 抬头「四份」→ 已改「六份」，前言已补全五份；② 13 处「ADR 候选」悬空指向 → 全库零命中，五份契约的 `## 决策(-> ADR)` 段已全部改为直接引具体 ADR 路径；③ `contracts/_index.md` 写死取值条数 → 已改为指路；④ 三处已答结却仍写「归 `06`」的悬空指路（改名频次 / 实名服务商灾备 / 冷存归档形态）→ 全部改指实际落点；⑤ `content-manifest.md` 缓存层悬空指路 → 已改指 `systems/content-delivery.md`;⑥ `envelope.md` 文末「跨库待办（客户端侧）」五项 → 整段已删；⑦ `operations/_index.md` 自陈与自身内容相抵 → 已改写为「只保留两节跨文档交叉点」；⑧ 收据 TTL 断言的第二权威 → 已压回回链（残留半句，见下）；⑨ D-1 / D-2 / D-3 `vision/scope.md` 三处失真（连记五次）→ 全部消解；⑩ `06` 与 `02` 分类口径不一致 → `06` 昵称阈值条已改造为条件化核对项。

**仍在的漂移（逐条）：**

1. **仍在（第三次记录）** —— **`ADR-0017` 与 `ADR-0025` 的回链是单向的**：`grep -rn "ADR-0017\|ADR-0025" contracts/` **零命中**，而 `decisions/_index.md` 已把两者记为 Accepted 且影响文档指向 `profile-sync.md`。决策本体已完整落进正文（`ADR-0017` ⇔ §3「未知取值：记录原值、不改写、不拒收」+「取值清单增量不 bump 契约版本」；`ADR-0025` ⇔ §4「§3 对未知 `reason` 的宽容语义不适用于 `schemaVersion`」），`profile-sync.md` 的 `## 决策(-> ADR)` 段只列 `ADR-0006` / `0008` / `0005`。**不是 derive 卡点**，是簿记漂移。
2. **新增（本次唯一一条遗留旧就绪度断言）** —— `operations/purchase-ops.md` 末行写下单端点滥用阈值「具体数值与实现**随栈落定**」。栈已于 09-03 落定（`ADR-0021`），该句未跟改；且该阈值**无初值、无旋钮 key、不在任何旋钮表**。建议改写为「形态同构 push 滥用阈值，取值待实测」并补进旋钮清单。
3. **新增（同一文件内新旧两说并存）** —— `operations/compliance-ops.md` 仍在一处写撤销留痕「交给**风控事件流**（只追加、有自己的保留期）」，而同文件另两处已按 09-08 裁决写为 `deletion_audit`（单独成表 · 保留 3 年 · 注销执行不删，`ADR-0057`）。09-08 那批未回改这一处。
4. **新增（三处，同源）** —— **三份契约仍以「技术栈未定」作为「停在语义层」的理由**：`purchase.md`「技术栈未定 ⇒ 本文件停在协议与语义层」· `profile-sync.md`「技术栈未定 ⇒ 停在语义层（本库纪律）」· `envelope.md`「落点 `operations/`（栈落定后）」（而下一句自己已回链已存在的 `version-matrix.md`）。三处的**结论仍成立且是本库纪律**，但**理由句已过期**，读作「等栈落定再说」会误导。建议改写为「本库纪律：契约层只声明语义，实现形态归 `systems/` / `operations/`」。
5. **新增（标签滞后，两处同源）** —— `operations/content-delivery-ops.md` 的 Source 行仍写「…（**A7–A9** · 传播窗口 T 的口径与预算 · CDN 负缓存两条）」，而本文件内已无 A6–A9 任何编号（已迁 `systems/content-delivery.md`）；`open-questions/04-content-delivery.md` 同样残留「配 **A7–A9** 三条服务端纪律」。按该标签检索会零命中。
6. **新增（标签滞后）** —— `operations/version-matrix.md` 的 `manifestSchema` 集合行值列仍写「待定」，而同格括号内实际已给出 `{1}`（首发，路径分支 `s1`）且下方 T0/T1/T2 序列已完整。读者会误判此项未决。
7. **仍在（部分收敛未尽）** —— `operations/_index.md` 的收据 TTL 行已压回回链形态并明写「本索引不复述其形态与理由」，但同行仍在正文断言「它与 O6『历史规则集永久保留』是**同形取舍**」这半句结论。彻底做法是连这半句一并移进 `purchase-ops.md` §3c 或 `moderation.md` 的过期方向判据表。
8. **新增（软指路，四处）** —— 已有实际落点却仍指向分片编号：`contracts/profile-sync.md` 两处写风控事件「落地形态…归 `02` / `06`」（实际已在 `operations/moderation.md` 的字段表 / `kind` 取值表 / 阈值分档 / 全局熔断，且该文件自己的 Open questions 表已如此登记）· `contracts/auth.md` 两处写「`02` 的三条待答项」与「词表与审核口径归 `02`」（`02` 待答已清零）。
9. **新增（「技术栈未定」的第二组，共三处 + 一处工程层）** —— `README.md` 与 `requirements/_index.md` 均以「**后端技术栈未定，无从设计实现形态**」为由把 `/blueprint` 与 `/implement` 排除在后端之外；`requirements/_index.md` 的拆解粒度判据 U2 依据栏另写「技术栈未定，文件边界不存在」。该理由已于 09-03 失效——**结论可能仍成立**（后端代码尚未开工、目录结构未定），但**措辞须改**为「后端尚未开工」而非「栈未定」。同一句在 `.claude/rules/design-library-routing.md` 另有一份同源副本，属 `.claude` 工程层，不在本技能写入面。**是否扩展这两个技能到后端是一个独立决定。**
10. **新增（🟠 README 台账失真，影响导航准确性）** —— `README.md` 的「当前状态」段仍写「焦点因此只剩外部输入：**成本模型（`06-platform-stack.md`，唯一待答）**、外部服务商选型与资质、以及 `02` 的一条挂账项」。该句写于 09-07，而 09-08 那批新增了 **4 条待答**（`07` ×2 · `06` ×1 · `01` ×1）并**新开了 `07` 分片**——README **完全未提及 `07-internal-tools.md` 的存在**。当前真实待答面为 **5 条**。对照之下本索引已正确更新（分片导航含 `07` 行、当前焦点标题即为「`07` 内部运营工具面（新开）」）⇒ **失真只在 README 一侧。**
11. **新增（两处轻微不齐，不影响任何判定）** —— ① `decisions/_index.md` 对 `ADR-0016` 的标题措辞与该文件 H1 不一致（台账写「调用者此刻不可能持有 access token」，文件写「「调用它的玩家此刻不可能持有 access token」」），语义同向；② `handoffs/2026-09-08-risk-ledger-storage-shapes.md` 的 frontmatter `distilled-to` 只列 4 份，比 `handoffs/_index.md` 同行少列 `operations/observability.md`（该文件的 `topic:` 行本身列了它）⇒ 属 frontmatter 漏列，**非漏落笔**。
12. **新增（对侧，只报告）** —— 客户端库 `open-questions/deferred-content.md` 两处写「`AccountInfo`（**仅余合规字段待后端**）」，而后端合规域已于 09-07 定案分级、三条 `code` 的 `ERR_*` 与四条拦截码落屏亦已于 09-05 在客户端落笔。属未清理的陈旧措辞，不构成实际欠账。
13. **工程欠账（非漂移，两处陈述一致）** —— `operations/deployment.md` 与 `operations/_index.md` 均写 `contract-spec-check` workflow 与校验脚本**尚未落地**（本次已实测确认仓库无 `.github/workflows/`、无 `scripts/`），三条机检断言当前以人工清单前三项执行。首批 FR 落笔时会撞上它。
14. **无失真** —— `decisions/_index.md` 60 行 ⇔ 60 份 ADR 逐条一致且**全 Accepted（非 Accepted 者 0 份）**，编号连号无缺，「影响文档」列 34 条引用路径（含 5 条跨库全路径）全部实际存在；`handoffs/_index.md` 40 行 ⇔ 40 份 handoff、全部 `distilled`（`raw` / `triaged` 仅存在于 `_TEMPLATE.md`）；`inbox/` 顶层为空（`archive/` 36 ⇔ 36）；`answer-logs/` 33 ⇔ 33；`operations/_index.md` 9 ⇔ 9；`systems/_index.md` **3 ⇔ 3**；`requirements/_index.md` 如实写「当前尚无 FR」并把就绪度权威指回本小节。

## 下一阶段

**契约骨架完整（六份）、再无取值留白，且技术栈与托管形态已落定**——本库的结构性前置就此清空。
客户端侧已定的四组语义（`revision` CAS · `pushId` 幂等 · `AccountSeed` 与掷骰复算 · 购买段验票与权威写入）全部有处可依；
三处 `reasonKey`、`compliance.*` 码清单与五条 `purchase.*` 码也已填表——客户端的 `ErrorText` 自此可以机械落地。

下一步落在三处，彼此可并行：

- **成本模型** —— 唯一仍待答的设计输入，是一批数值的共同前置（实例规格、灾备副本数、备份保留期、CDN 成本），本库已把这些一律写成能力要求而非具体数字。
- **两份发布前置清单的实际过闸** —— 「首个真实账号建号之前」六项与「首次面向公众发行之前」三项（`operations/deployment.md`）；**微信开放平台资质必须在首个玩家建号之前完成**，未到位则推迟上线。
- **两条外部事实的核实** —— 实名核验是否另需对接主管部门的实名认证系统（`02` 挂账项）· 服务商的具体选型（商业决定，形态已由 `operations/external-providers.md` 定死，不改任何验收断言）。

**唯一仍未落笔的契约面欠账**（属待落笔，不是设计未决）：`openapi.yaml` 与 `schemas/*.json`——触发点是任一侧首个端点进入实现。

**跨库未闭合项**见 `open-questions/cross-boundary.md` 与客户端库同名分片：本批带出的客户端承接义务（内容签名 standby 公钥内置 · `OpError.Purchase` 成员 · 合规域三条新 `code` 的 `ERR_*` 与相关落屏）已在客户端库登记为承接项，**本库不代为裁决**。
