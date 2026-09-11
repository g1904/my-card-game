# Open questions — 更新日志（后端）

> 每次运行的更新摘要（答结 / 推翻 / 新增落点），倒序。不含问题条目本身——条目在各分片。

## 2026-09-11 — 清单专职重整：**零移出**，补登跨边界承接 1 条（`/summarize-open-questions backend`，批量运行 `progress-sync` 波次 3）

一次专职归集整理，不引入新想法、不裁决任何问题。**本次无任何条目可移出，故不新建 answer log**，`answer-logs/_index.md` 台账零增行。五份按编号分片（`01` / `02` / `04` / `06` / `07`）**一字未改**；改动只有三处：索引的「最近更新」行与 `cross-boundary` 导航行、`cross-boundary.md` 新增 1 条待承接、本日志本节。

- **待答面（4 条，无增无减）**：`06` 两条待实测取值（成本模型 · `riskEventBufferRows`）· `07` 两条相邻真空（告警接收人 / 值班形态 · 客服侧的账号查询入口）。另有**不属设计待答**的两类：`02` 一条外部事实挂账项（实名核验是否另需对接主管部门实名认证系统）· `04` / `06` 各一节条件化核对项。`01` / `04` / `cross-boundary`「待承接」均为空。
- **主题文档 ↔ 分片逐条对账**：全库 **7 处** `## Open questions`（`vision/scope.md` · `contracts/auth.md` · `compliance.md` · `envelope.md` · `profile-sync.md` · `purchase.md` · `operations/internal-tools.md`）逐一直读——`auth.md` / `compliance.md` / `profile-sync.md` / `purchase.md` **四处自陈「无待答项 / 无」**；`scope.md` 自陈「范围面本身无待答项」并把唯一相关项指回 `06`；`envelope.md` 唯一条目（`openapi.yaml` / `schemas/*.json` 落笔）自陈属待落笔项，已由 `01` 分片抬头承接；`internal-tools.md` 两条与 `07` 分片两条**逐字同题**，零漂移。`handoffs/` 无 `raw` / `triaged`（`grep` 零命中），`inbox/` 顶层为空（只有 `_TEMPLATE.md` / `_index.md` / `archive/`）⇒ **无未进清单的散落未决项**。
- **波次 1（`/write-adr backend` 新增 `ADR-0063`）对本清单零影响**：该 ADR 固化的是既有正文（人类身份对业务表恒只有 `SELECT`），不答结、不新增任何待答条目；其登记处落在 `## derive 就绪度`（漂移清单第 11 条已由波次 2 销号）。
- **台账对账**：`open-questions/` **7 份文件 ⇔ 索引分片导航表 7 行**；`answer-logs/` **35 份 log ⇔ `_index.md` 35 行**。均零悬空行、零孤儿文件。索引顶部说明块 **13 行 / 最长 136 字**，两项上限（≤15 行 / ≤200 字）均未触及，**无需下沉**。
- **跨边界：新增承接项 1 条**（本波次客户端 worker 收工后由 orchestrator 转交，避免并发写同一文件）。`cross-boundary.md`「待承接」由**空 → 1 条**：客户端 `ADR-0255`（付费解锁角色系列）给后端新增三项义务——系列级 SKU 定价 · 验票后由后端主动写入解锁 · 封闭表加行；落点 `contracts/purchase.md` + `systems/`（承接文档待定）。**该条是本分片的一处例外**：对侧 ADR 自陈载体与字段形态「首批一格不落、归 `/provide-solution-draft` 推演」⇒ 它是**待答 / 提案形态**，不是答案已有只等落笔的常态承接项；后端侧要决的是「SKU 粒度是系列级还是角色级」与「封闭表加的是哪张表」。**本库不预设形态、不代为裁决**，口径一律回链对侧 ADR、不复述。索引的 `cross-boundary` 导航行同步注明这一例外。
- **对侧的待落笔项不变**：`game-design-documents/open-questions/cross-boundary.md`「待承接」两条（`ADR-0051` · `ADR-0052`，均 2026-09-07）仍是对侧的待落笔项，本库不代办、不催办、不复述。
- **只报告不改的一处（属 `## derive 就绪度`，`/assess-derive-readiness` 独占写入）**：波次 2 刚整体重写的该小节仍对 `contracts/compliance.md` 写「`## Open questions` 章节整体不存在 ⇒ 判据 2 直接成立」，而该章节**实际存在**（`compliance.md:377`，内容为「- **无。**」+ 一句落点指路）。**结论不受影响**（判据 2 两种读法皆成立），但陈述失真，为连续第二次记录，留待下一次全量评估订正。
- **两个受保护小节原样保留、一字未改**：`## 下一阶段` · `## derive 就绪度`（波次 2 刚整体重写，ready 14 · partial 4 · 63 份 ADR）。

## 2026-09-11 — 收尾立档：新增 `ADR-0063` 一份（`/write-adr backend`，批量运行 `progress-sync` 波次 1）

一次专职立档，不引入任何新设计、不裁决任何决策。**候选清单侧零变动**——`open-questions.md` 的 `## 下一阶段` 本就不含 ADR 候选条目，`decisions/_index.md` 的「ADR 候选」表已于 08-19 整节删除，`handoffs/` 中晚于 `ADR-0062` 的条目为零（最新一份为 09-09，其自陈两条候选已于 09-10 那批立档）。本次唯一候选来自**连记两次的簿记登记项**：`## derive 就绪度` 漂移清单第 11 条与 09-10 update-log 的「识别为候选但未建档」。

- **`ADR-0063`** 人类身份对业务表恒只有 `SELECT`，一切写入经服务端受控面（全库通则，不限于 flags 规则集表 · 权限分层落在建库脚本里 · 推论：内部处置不发放可写库凭据）。事实依据双处直读核实：`operations/content-delivery-ops.md` A3 与「存储选型判据」· `operations/internal-tools.md`「界面档次」。**决策本体早已由用户裁决**（`answer-logs/log-internal-ops-tools.md`「同批裁决的取向项」第三条，2026-09-09：「→ **提升为全库通则**」），此前未建档的唯一原因是来源 handoff 未自评为 ADR 候选——而该理由与本库既有先例相抵（`ADR-0054` ~ `ADR-0059` 六份均来自全文未自评 ADR 的 handoff），故本次照「台账绝不领先于事实」核对后立档。日期取用户裁决日 2026-09-09，不取建档日。
- **台账**：`decisions/_index.md` 决策表新增 1 行（最新置顶，同日按编号降序置于 `ADR-0062` 之上）；对账 **63 行 ⇔ 63 份 ADR**，无孤儿文件、无悬空行，**本次无失真可修**。「已对后端构成约束的客户端决定」表一格未动。
- **`open-questions.md` 一字未改**：`## 下一阶段` 无可移除条目；本次候选的登记处落在 `## derive 就绪度`（漂移清单第 11 条），该小节属 `/assess-derive-readiness` **独占写入**，本技能不代改 ⇒ 该条的销号留待下一次全量评估。
- **未处理的相邻漂移**（属主题文档，不在本技能写入面）：`ADR-0017` / `ADR-0025` 的回链仍是单向的（第五次记录）。

## 2026-09-10 — 清单专职重整：**零移出**，只修平索引一处条数失真（`/summarize-open-questions backend`，批量运行 `progress-sync` 波次 3）

一次专职归集整理，不引入新想法、不裁决任何问题。**全库对账后确认清单与主题文档已同步**——ADR-0061 / ADR-0062 答定的两条（昵称人工复核台形态含 `claimed_by` 取值域 · 风控工单落点）已由 09-09 那批同步移出并归档（`../answer-logs/log-internal-ops-tools.md`），本次**无任何条目可移出，故不新建 answer log**，`answer-logs/_index.md` 台账零增行。

- **待答面（4 条，无增无减）**：`06` 两条待实测取值（成本模型 · `riskEventBufferRows`）· `07` 两条相邻真空（告警接收人 / 值班形态 · 客服侧的账号查询入口）。另有**不属设计待答**的两类：`02` 一条外部事实挂账项（实名核验是否另需对接主管部门实名认证系统）· `04` / `06` 各一节条件化核对项。`01` / `04` / `cross-boundary`「待承接」均为空。
- **主题文档 ↔ 分片逐条对账**：全库 7 处 `## Open questions`（`vision/scope.md` · `contracts/auth.md` · `compliance.md` · `envelope.md` · `profile-sync.md` · `purchase.md` · `operations/internal-tools.md`）逐一读过——**五处自陈「无待答项」**；`envelope.md` 唯一条目（`openapi.yaml` / `schemas/*.json` 落笔）自陈属待落笔项，已由 `01` 分片抬头承接；`internal-tools.md` 两条与 `07` 分片两条**逐字同题**，零漂移。`handoffs/` 无 `raw` / `triaged`（42 份全 `distilled`），`inbox/` 顶层为空 ⇒ **无未进清单的散落未决项**。
- **唯一改动（索引分片导航表）**：`06` 行原写「余一条成本模型」，与同文件分片展开段与 `06-platform-stack.md` 抬头的「余两条」相抵 ⇒ 改写为「余**两条待实测取值**——成本模型 · `riskEventBufferRows`」。分片本体一字未改。
- **跨边界**：本次**零新增承接项**。直读核实对侧 `game-design-documents/open-questions/cross-boundary.md`「待承接」现有两条（`ADR-0051` · `ADR-0052`，均 2026-09-07），仍**未落笔**——那是对侧的待落笔项，本库不代办、不催办、不复述。本库 `cross-boundary.md`「待承接」为空，无条目可开。
- **只报告不改的一处（属 `## derive 就绪度`，`/assess-derive-readiness` 独占写入）**：该小节对 `contracts/compliance.md` 写「`## Open questions` 章节整体不存在 ⇒ 判据 2 直接成立」，而该章节**实际存在**（`compliance.md:377`，内容为「无。」+ 一句落点指路）。**结论不受影响**（判据 2 无论按「不存在」还是按「存在且自陈无待答」都成立），但陈述本身失真，留待下一次全量评估订正。
- **两个受保护小节原样保留、一字未改**：`## 下一阶段`（波次 1 `/write-adr` 已核对，本库该节不含 ADR 候选）· `## derive 就绪度`（波次 2 `/assess-derive-readiness` 刚整体重写，ready 14 · partial 4）。

## 2026-09-10 — 09-09 那批定案立档：新增 `ADR-0061` / `ADR-0062` 两份（`/write-adr backend`，批量运行 `progress-sync`）

一次专职立档，不引入任何新设计、不裁决任何决策。**候选清单侧零变动**——`open-questions.md` 的 `## 下一阶段` 本就不含 ADR 候选条目，`decisions/_index.md` 的「ADR 候选」表已于 08-19 整节删除。候选来自唯一一份晚于 `ADR-0060` 且自评带候选的 handoff（`2026-09-09-internal-ops-tools-and-operator-identity.md`，自陈两条）。逐条按「台账绝不领先于事实」核对过主题文档才建档：**零条查无实据、零条与主题文档矛盾。**

- **`ADR-0061`** 内部人员身份自成一套 `operator_id`，与 `account` 完全分离（四条分离理由 · 内部键 / 外部映射分层与玩家侧同构 · 一次填上全库四处「操作者」空洞 · `claimed_by` 加外键且来源恒取自认证凭据）。事实依据：`operations/internal-tools.md`「内部人员身份」· `systems/account.md` 四张表承重列与事务边界。
- **`ADR-0062`** 内部运营工具面不属于契约面，`/internal/` 永不进端点全集表（判据是机检断言③而非风格 · 不进 `openapi.yaml` / §6 台账 · 一律必带凭据 · 复用序列化惯例不复用契约机制 · 同制品同进程独立监听、仅 VPC 内可达）。事实依据：`operations/internal-tools.md`「接入面」· `contracts/envelope.md` §3 表下非规范性说明。
- **另一份 09-09 handoff（`-flags-zero-load-no-dedicated-code.md`）自陈「不新增 ADR」**——它是既有 §6 台账判据的一次应用，本次照其自评不建档。
- **台账**：`decisions/_index.md` 决策表新增 2 行（最新置顶，同日按编号降序）；对账 **62 行 ⇔ 62 份 ADR**，无孤儿文件、无悬空行，**本次无失真可修**。「已对后端构成约束的客户端决定」表一格未动。`open-questions.md` **一字未改**（`## 下一阶段` 无可移除条目，`## derive 就绪度` 属 `/assess-derive-readiness` 独占）。
- **识别为候选但未建档**（无用户裁决，本次无人值守运行不代拍板）：「人类身份对任何业务表恒只有 `SELECT`」由 A3 提升为**全库通则**——已落笔于 `operations/internal-tools.md`「界面档次」，事实依据充分且可被单独推翻，但来源 handoff 未自评为 ADR 候选，留待用户裁决是否立档。
- **未处理的相邻漂移**（属主题文档，不在本技能写入面）：`ADR-0017` / `ADR-0025` 的回链仍是单向的（第四次记录）。

## 2026-09-09 — 内部运营工具面落定 · flags 零装载不给专属码（`/batch-analyze-new-ideas backend` ×2）

两份已评审 `solution-draft` 同批提炼（4 项裁决 + 1 项标准默认已于同日批量评审写回草稿，本次只做落笔）。**移出 3 条**（`07` 两条同源 · `01` 唯一一条），**新增待答 2 条**（均落 `07`）。**`01` 分片待答清单就此清零**；`07` 由「开片两条」换成「两条相邻真空」。→ `../answer-logs/log-internal-ops-tools.md` · `log-flags-zero-load-code.md`

- **内部人员身份是本库自己的 `operator_id`，与 `account` 完全分离。** 四条理由逐条来自既有约束、不是洁癖：`account` 是合规删除权的对象（一次误判的注销会把复核员本身删掉）· `session` 的「单账号活跃会话上限 1」对内部人员是错的（一人两台机器办公即撞索引）· `identity` 的渠道取值域封闭为三条登录渠道、没有企业身份这一档 · `account` 行是全库唯一的并发单元。手法与玩家侧逐字同构（`operator_id` 是内部键、`operator_identity` 是外部映射），理由也同构——外部身份源可换、登录名会变，而它是**租约归属键与审计外键，必须永久稳定**；直接把登录名写进 `claimed_by`，一次改名就让历史审计指向一个不存在的人。**只停用不删行**（`disabled_at_utc`），同 `account` 墓碑的取向。
- **它一次性填上全库四处「操作者」的取值空洞。** `claimed_by` · `publishedBy`（flags 规则集 / 内容发布 / 词表 / 时段规则集）· `config_knob` 更新者 · KMS 解包事件审计的「谁」——四处是同一个空洞、同一个答案，给内部人员定两套标识毫无理由。既有各表的留痕列**保留不动**（就地可读是它的价值），`operator_audit` 是横向的第二视图，两者同事务同批写入。
- **内部工具面不属于契约面，判据是机检而非风格。** `envelope.md` §3 端点全集表是机检断言③的**输入**（端点集 ⇔ 六份契约正文，双向），而内部端点在六份客户端契约中永不出现 ⇒ **一旦进表，断言③当场红灯**。故 `/internal/` 不带 `/v1/`、不进 §3 表、不进 `openapi.yaml`、不进 §6 台账；§4a 无鉴权例外的判据主语是「玩家」，内部面不够格 ⇒ **一律必带凭据，无例外**。§3 表下加一句非规范性说明（**表本身不加行**，守 P-3），因为会「顺手补全」的读者在那里。
- **认证按调用形状定，不按对称性定。** 首版一枚长期内部凭据、凭据即身份，**不签发会话、不复制 refresh 那套**——会话机制解决的是「高频调用不该反复出示长期凭据」，而内部面是每天个位数的人工动作。企业 IdP 与内部 Web 控制台**留位不启用且写死触发条件**（人数 > 1 或出现非工程岗复核员），启用是纯增量、`operator_id` 与全部历史留痕一字不变——这正是把它定为内部键换来的东西。托管**自成第五类条目**（operator × 环境），不与既有四类钥匙共用。
- **`baseAccountStatus` 是封号动作上唯一的一道防线。** 把契约层的 CAS 手法（`baseRevision`）原样用在最高危的动作上：工单是几分钟前领的，期间该账号可能已申请注销或已被另一次处置改过；不等即拒、`status` 一字不变。之所以是「唯一」——库内已明写「当前单人维护，四眼原则是纯摩擦」，故不设第二人审批，而这道防线成本为零。
- **「这张表含不含个人信息」是可设计的，不是事后声明。** `operator_audit` 的 `context` 刻意只装内部键与结果 ⇒ 保留 3 年、注销执行不删（与 `deletion_audit` 同判据）；可关联到个人的载荷留在 `nickname_review` / `ops_ticket`（180 天 + 注销硬删）。这一手法决定了保留期与是否进删除清单两件事。
- **A3「人类身份对规则集表只有 `SELECT`」提升为全库通则**（用户裁决）：限缩到单张表等于承认其余表可以带外改，而昵称复核与风控处置正是最需要它的两处。首版因此**不给人可写库凭据去处置**——那会绕过条件 `UPDATE` 取租约，让 M6 / M7 在纸面成立而线上不成立。
- **flags 零装载失败刻意不给专属 `code`。** 七条判据（自 §6 台账既有裁决理由归纳）逐条套用后全否或反向支持：客户端处置逐字相同 · 玩家面为空（永不落屏 ⇒ `ERR_*` 键永不被取用，登表反而逼客户端配一条永不显示的文案）· `class` 相同 · 不消费 `detail` · **「两条曲线」的两个限定均不成立**——区分所需的事实就在服务端进程内，且本库已有「同码 + 指标层分辨」的既定解法（`sync.conflict`）。**当区分所需的事实在我方进程内时，本库的既定做法是打点，不是开码。**
- **专属码解决不了它宣称要解决的问题。** 悬项的原始动机是「空集合会被客户端持久化为降级值」，而这条风险由两条**结构事实**堵死、与 `code` 取什么值无关：错误应答体不含 flags 报文任何字段（F7 已写成可验收断言）⇒ 不存在「拿到一个空集合」这个中间态；客户端缓存的写入时点唯一 = 一批 flags 通过单调闸并被应用之后。
- **不给码不等于不留痕**：三处主题文档写死裁定（`envelope.md` §6 承重项 · `content-manifest.md` B 组 · `content-delivery.md` 末行），并同批把 `observability.md` 的**零装载失败计数器**落下来——把风险从契约转移到指标，指标不落地就等于把风险抹掉而不是转移。它补的正是既有两条 flags gauge 结构性看不见的那一块：零装载实例没有「本实例可兑现的最大版本」这个数，两条 gauge 在它身上都无值，而「gauge 无值」极易被读成「零落后」。
- **顺带落笔三处纯机械订正**（答案已定、无取向）：`moderation.md` 伪码的租约回收补「一并置空 `claimed_by`」（留着旧值会让「谁在办」这一列在 `Pending` 行上说谎）· `compliance-ops.md`「执行时删什么」补 `ops_ticket` 硬删与 `operator_audit` 保留两行并把「三条保留」改「四条保留」（该表是注销删除清单的第二权威，只改 `account.md` 一侧会让两份表相抵）· `envelope.md` §6 承重项引导句写死的「五条」改为不写死（原文实列 8 条，同「写死一个数目就是一份会漂移的副本」的既有纪律）。
- **ADR 候选两条**（立档归 `/write-adr`）：内部人员身份与 `account` 完全分离、`operator_id` 为全库唯一内部人员标识 · 内部工具面不属于契约面。flags 那条**不产生新 ADR**——它是既有台账判据的一次应用。
- **契约报文零改动、客户端零义务零发版、跨库零承接项**（两份草稿均如此，逐条核实：不新增 `code`、`code` 全量枚举不变、§3 表与 §6 台账均不加行、`profile` 的 `doc` 零新增字段）。
- **不动 `open-questions.md` 的「derive 就绪度」小节**（`/assess-derive-readiness` 独占写入），**唯一例外是用户点名的一处定点删除**：「最短解锁路径」第 6 条中「并标注该条可能后续替换」半句随销号删去。该小节内另有三处记述因本批而过时（`moderation.md` 的 `07` 卡点 · `content-delivery.md` 的第二块窄排除面 · 最短解锁路径第 2 与第 6 条），**如实留待下一次全量评估刷新，不越权代改**。

## 2026-09-08 — 09-07 / 09-08 那批定案集中立档：新增 `ADR-0051` ~ `ADR-0060` 十份（`/write-adr backend`）

一次专职立档，不引入任何新设计、不裁决任何决策。**候选清单侧零变动**——`open-questions.md` 的 `## 下一阶段` 本就不含 ADR 候选条目，`decisions/_index.md` 的「ADR 候选」表已于 08-19 整节删除。候选来自**五份晚于 `ADR-0050` 的 handoff**（`2026-09-07-*` ×3 · `2026-09-08-*` ×2）里散落的已定案方向。逐条按「台账绝不领先于事实」核对过主题文档才建档：**零条查无实据、零条与主题文档矛盾。**

- **内容分发 2 份**（来源 `-manifest-schema-path-branch-and-cdn-failure-codes.md`，该 handoff 自陈两条值得固化）：`ADR-0051` `manifestSchema` 双发走客户端选路的路径分支（`s1` 从第一天就在 · blob 不分支 · 保留时长挂 refresh 绝对寿命上限）· `ADR-0052` CDN 域 4xx 按「入口对象 / 入口之后的对象」两分。
- **auth 1 份**（`-refresh-expiry-reasonkey.md`，自陈一条）：`ADR-0053` `reasonKey` 分辨玩家措辞而非机制自述 ⇒ `SessionExpired` 收编三种情形。
- **合规上线分级 2 份**（`-compliance-launch-tiering.md`，该 handoff **全文未自评 ADR**——属簿记漏项）：`ADR-0054` 四项能力全部首版必备 + 「后置是否需要对存量账号追溯」这条判据 + 前置清单拆两份 · `ADR-0055` 第三方昵称审核首版不启用且写死唯一启用触发条件（两条可各自单独推翻，故分立）。
- **风控台账 4 份**（`-risk-ledger-storage-shapes.md`，同样全文未自评 ADR）：`ADR-0056` 四张表与逐表形态判据（月分区 · 整分区 `DROP` · 两条索引 · 不建 rollup）· `ADR-0057` `deletion_audit` 单独成表保留 3 年、注销执行不删 · `ADR-0058` 复核队列取条件 `UPDATE` 租约 · `ADR-0059` 有界旁路缓冲 + 三类同事务例外，并写死「只追加」「不在热路径裁决」各自禁的是什么。
- **flags 1 份（追认）**：`ADR-0060` 规则集装载必须有请求无关的触发。其来源 handoff `-flags-service-internal-doc-home.md` 自陈「本次不新增 ADR」，但**该自评只覆盖了「文档归属」那一半**，未评价同批推演出的这条机制定案；**用户 2026-09-08 裁决一并立档**（承根约定「一切皆可改」，与 09-07 追认三条同一先例）。
- **台账**：`decisions/_index.md` 决策表新增 10 行（最新置顶、日期降序、同日按编号降序）；对账 **60 行 ⇔ 60 份 ADR**，逐条一致、无孤儿文件、无悬空行，「影响文档」列引用的路径全部存在（含一条跨库全路径），**本次无失真可修**。「已对后端构成约束的客户端决定」表一格未动。`open-questions.md` **一字未改**。
- **未处理的相邻漂移**（属主题文档，不在本技能写入面）：`ADR-0017` / `ADR-0025` 的回链仍是单向的（第三次记录）。09-07 记录的「六份契约 `## 决策(-> ADR)` 段指向已删除的登记处」已于 09-08 那批订正中修平，就此销号。

## 2026-09-08 — 风控四张台账落存储形态 · flags 服务内部文档建立 · 新开 `07` 内部工具片（`/batch-analyze-new-ideas backend` ×2）

两份已评审 `solution-draft` 同批提炼（3 项取向已于同日批量评审裁决，本次只做落笔）。**移出 2 条**（风控三张台账的存储形态 · A6–A9 的文档归属），**新增待答 4 条**（`07` 两条 · `06` 一条 · `01` 一条），**新开分片 `07-internal-tools.md`**。待答面由「`06` 一条」扩为「`07` 两条 + `06` 两条 + `01` 一条」。→ `../answer-logs/log-risk-ledger-storage-shapes.md` · `log-flags-service-internal-doc-home.md`

- **风控台账定为四张表，不是三张。** 判据是「体量随什么增长」与「访问模式是不是点查」，不是「它们都叫台账」：`risk_event` 随时间只追加 ⇒ 按 `occurred_at_utc` 月 RANGE 分区、**整分区 `DROP`**（K4 的「到期整体过期」字面就是分区裁剪的规格说明，日分区换来的只是过期精度而保留期是下界性质 ⇒ 实际保留 [180, 210] 天）· `nickname_review` 随待办积压增长 ⇒ 不分区、终态按批删 · `nickname_scan` 随账号数增长、一行一账号 ⇒ 不分区、无过期。索引只按已写死的读路径铺两条，**不建 rollup**（为尚不存在的聚合压力先建派生数据路径不划算，先走 `purchase-ops.md` §3d 的四项排除法）。
- **`DeletionRequested` / `DeletionCancelled` 两个 `kind` 从 `risk_event` 分出，另落 `deletion_audit` 表、保留 3 年、注销执行时不删。** 判据是**过期代价的不对称性**（与 `receipt_idem` 永不设 TTL 同一条判据的第二次应用）：撤销即删行 ⇒ 事件流是「谁在什么时候申请 / 撤销过」在库内的唯一留痕，而删号客诉往往在半年、一年后才到；多留的代价是一张每账号一生零到一次的空表，少留的代价是一条**不可举证**的删号客诉。长留不构成个人信息超期留存，因为 `context` 已明写「不含任何个人信息」——与 `account` 墓碑同一性质，故不需要任何删除路径。其余八个 `kind` 的 180 天与整分区裁剪一字不改。
- **「只追加」禁的到底是什么，写成一句话止争**：业务路径上条目永不改写、永不因业务原因单条删除；**恰有两条删除路径且都不是业务路径**——到期整分区 `DROP`、注销执行按 `account_id` 硬删。同理澄清 K5：被禁的是**裁决**（阈值判定与处置升级）在同步热路径上，不是记一行账 ⇒ 三类例外（两个删除类 kind 已移至 `deletion_audit` · `NicknameBypassed`）必须同事务写、不走可丢弃的旁路缓冲。**没有累计冗余的信号不能走可丢弃的通道。**
- **复核队列的领取语义不照抄合规域。** 合规域四条周期任务是 `FOR UPDATE SKIP LOCKED` 持锁到事务结束，前提是处置在毫秒到秒级完成；复核是**人工**动作、持有时长以分钟计，开着事务等人点按钮会长期占住连接、把最长事务时长打成常态告警并阻塞 autovacuum。改为 **`SKIP LOCKED` 只用在选行那一条语句、条件 `UPDATE` 取租约**（30 分钟初值），判定写条件 `UPDATE` 靠受影响行数分支拒掉迟到提交 —— 仍是零分布式锁、零调度中间件。
- **A6–A9 的文档归属裁决为新建 `systems/content-delivery.md`**（三个服务自此各有一份服务文档，职责表不再指向不存在的文件）。**只迁 A6–A9**：新文档的承重列与事务边界两节暂为回链 `ops` 的占位，由此产生的**回链方向反转**是已知且被接受的结构不齐，待下一次触及内容分发时补齐。`ops:3` 的自陈范围一字不改——这正是该选项相对「就地留在运维文档」的直接好处（后者要改三处自陈 / 台账）。
- **落笔中推演出一处机制缺口并同批堵上：flags 版本预热。** A6 读起来装载是请求驱动的懒加载，而 A8 把头钉成 `min(高水位, 本实例可兑现)`、客户端又「等值不拉」⇒ 自锁：实例未装载 → 头不涨 → 客户端不拉 → 该实例收不到请求 → 永不装载。集群内每个实例都懒加载时，**一次 `publish` 可能对全体设备永不生效，而现有极差探针发现不了**（全体一致地落后 ⇒ 极差恒为 0）。处置：当前版本读取缓存每次刷新发现高水位更大时**主动装载**（请求无关触发），并在 `observability.md` 补一条「高水位 − 本实例可兑现的最大版本持续 > T 即告警」。
- **顺带落笔七处纯机械订正**（答案已定、无取向）：`systems/_index.md`「不引入 MQ」收尾句改写为「风控事件落同库 `risk_event` 表（旁路批量写入），告警走指标出口——两者都不需要消息队列」（**结论与论证一字不动**，改的只是会被读成「风控事件不落库」的字面表述）· `compliance-ops.md`「执行时删什么」+3 行与 `systems/account.md` 注销事务行同改 · `ADR-0047` 结尾指路分指两处 · `observability.md` 两组新探针 · `systems/_index.md:41` 与 `:9` 改回链新文档 · `content-delivery-ops.md`「该端点的真实负载」按归属拆分 · 删除 `moderation.md` 那条已悬空的「归 `06`」指路（`06` 全片对该问题零命中，即它此前**没有任何台账在跟踪**）。
- **契约面另有一批订正同批完成**：`envelope.md` 抬头份数与前言漏列 · 9 处「ADR 候选」改为直接引具体 ADR 编号 · `operations/_index.md` 自陈与正文相抵 + 收据 TTL 断言的第二权威收归 `purchase-ops.md` §3c 单点 · 7 处已答结却仍写「归 `06`」的悬空指路 · `envelope.md` 文末「跨库待办（客户端侧）」五项经逐项核实对侧已落笔后整段删除。**契约报文零改动。**
- **不动 `open-questions.md` 的「derive 就绪度」小节**（`/assess-derive-readiness` 独占写入）。本次闭合的三处记述（`content-delivery.md` 尚未建立 · A6–A9 孤儿路径 · derive 顺序第 7 条的前置动作）全在该小节内，**如实留待下一次全量评估刷新，不越权代改**。

## 2026-09-07 — 合规能力的上线分级答结：四项全部首版必备，昵称审核留位不启用（`/analyze-new-ideas backend`）

一份已评审 `solution-draft` 的落笔。**移出 2 条**（`02` 上线分级整条含从属项 · `06` 昵称审核阈值取值改造为条件化核对项），**新增待答 0 条，新增挂账项 1 条**。待答面由三条收为**一条**（`06` 成本模型），另有 `02` 一条挂账项与两片条件化核对项。→ `../answer-logs/log-compliance-launch-tiering.md`

- **分级结论：四项能力不分档，全部首版必备**（实名核验 · 防沉迷时段 · 账号注销 · 数据导出）；可后置的是各项的**增强项**，不是能力本身。判据收敛为一条——「后置之后再补，是否需要对存量账号做一次追溯动作？需要 → 不得后置」，它正是发布前置清单四项所用的既有判据，本次只是复用到合规域，**不新造纪律**。**契约面零改动、schema 零改动、跨库零承接项。**
- **`operations/deployment.md` 拆成两份前置清单。** 实名 + 防沉迷追加进「首个真实账号建号之前」（第 5、6 项，过闸断言照第 4 项体例写成**可验证的运行时事实**）；注销 + 导出落**新增的第二份**「首次面向公众发行之前」（另含域名备案与国内发行资质）。两份的未就绪处置相同：**推迟上线，不降级放行**（沿用 `ADR-0042` 对微信资质的处置）——合规项没有「先上线后补」的形态：拦截只在 `signin`、四码求值顺序写死、无灰度旋钮。
- **第三方昵称审核（判定链第④级）首版不启用，且由「悬而未决的默认」升为「有触发器的默认」**：唯一启用触发条件 = 渠道过审点名要求接入第三方内容审核能力；触发时以真实人工判定样本标定两阈值。后置成本 ≈ 0 由 `ADR-0044` / `ADR-0038` / `ADR-0015` 三条共同担保（不改报文、不新增 `code`、不要求客户端发版）。→ `operations/moderation.md` · `operations/external-providers.md`
- **两项外部事实由用户批量评审当场裁决**：① 首版 = **中国大陆正式发行**（iOS / Android 国内渠道 + 微信）⇒ 分级原样成立；② 主管部门实名认证系统的接入义务**暂不裁决**，按现状（只用商用持牌核验）落笔并在 `02` 登记**挂账项**——本库对该接入的沉默是**尚未核实的空白，不是「已确认无此义务」**，核实所需的外部信息与两种核实结果的改动面已逐条写明。
- **顺带落笔两处**（答案已定、无取向）：`systems/account.md`「合规域的服务端保证」表补一组**时段判定保证 P1–P5**（日历四步顺序 / 未成年 token TTL 卡时段边界 / 会话中途到点复用 `session_revoked` / F2 · F3 对未成年 fail-closed 而成年不受影响 / 降级时 `resumeAtUtc` 取兜底周规则——全部是对 `operations/compliance-ops.md` 既有形态的机械对位，无新形态）· `06` 的昵称阈值条按 `04` 的先例改造为**条件化核对项**（09-07 漂移清单第 11 条「分类口径不一致」就此销号）。
- **顺手清理两处悬空指路**（漂移清单第 9 条 ②）：`contracts/compliance.md` 与 `operations/compliance-ops.md` 的 `## Open questions` 均写「实名核验服务商与灾备归 `06`」，而该形态 09-06 已由 `operations/external-providers.md` + `ADR-0038`~`0040` 答结、`06` 分片已无此条 —— 前者改写为「无待答项 + 现状陈述」，后者整节删除。
- **不动 `open-questions.md` 的「derive 就绪度」小节**（`/assess-derive-readiness` 独占写入）。裁决使判定链第④级由「未裁决的占位」变为「已裁决的未启用能力」，**是否据此收缩三处排除面，留待下一次全量评估判定**，本次不代判。

## 2026-09-07 — 两份已评审草稿同批提炼：`auth.md` 的一行消歧落地、`manifestSchema` 双发定为路径分支（`/analyze-new-ideas backend` ×2）

两份 `solution-draft` 的取向项已于同日批量评审裁决（各 1 项），本次只做落笔。**移出 0 条、新并入 0 条、新增待答 0 条，不建 answer log**——两份草稿的问题来源都是 `open-questions.md` 的「derive 就绪度」小节（`/assess-derive-readiness` 独占写入，本技能不得改动），`01` / `04` 分片的待答清单本就为空。**待答面维持三条不变**（`02` 上线分级 · `06` 两条待实测取值）。

- **`SessionExpired` 收编三种情形**（滑动截止到期 · 绝对截止到期 · `tokenId` 无从识别）。判据是 `auth.md` §10 自己那一条——`reasonKey` 分辨的是**玩家措辞**而非机制自述，三者对玩家是一字不差的同一句话；分列会在客户端产出逐字相同的二级文案副本，而客户端的文案审计只查一级键、无从发现不同步。**不新增取值、不新增 `code`、`envelope.md` §6 台账连 `detail` 形状都不动**（无会话行时 `revokedAtUtc` 取本次判定时刻，形状因此恒定）。→ `contracts/auth.md` §4 · §8 · §10、`systems/account.md`。
- **`manifestSchema` 双发 = 客户端按内置支持集合选路径分支** `<contentRoot>/s<manifestSchema>/manifest`（`.sig` 同，`s1` 从第一天就在，blob 不分支）。承重推论：判定方**只能**是客户端——CDN 域无鉴权、不带 `X-App-Version`，且 manifest 拉取排在登录之前。query 变体与「按 `appVersion` 服务端分流」双双否决。**`envelope.md` §3 端点全集同批改三行**（只改行内容、不改表结构 ⇒ 提取脚本无须同改）。保留时长 = 覆盖率条件 ∧ 时间下界，下界挂 `auth.md` 的 refresh 绝对寿命上限、不另立旋钮。
- **CDN 三端点失败状态码在契约层钉死**，4xx 判据两分：**入口对象（manifest）的 4xx = 环境 / 配置面**（跳过更新用基线 + 本地告警、不上报）· **入口之后的对象（`.sig` / blob）的 4xx = 发布原子性被违反**（`Validation` + 上报一次 + 不进退避重试）· 传输面照旧。另逐字写下「回滚 / 撤下这一失败面结构性不存在」（回滚 = 前滚），使该问题此后不再被问。→ `contracts/content-manifest.md`、`operations/version-matrix.md`、`operations/content-delivery-ops.md`。
- **顺带落笔两处纯机械订正**（答案已定、无取向）：`contracts/_index.md` 写死「`session_revoked` 八值 · `nickname_rejected` 三值」改为指路（09-07 漂移清单第 4 条销号）· 同文件断言②的 `reasonKey` 权威指路补 `compliance.md` §11（原只写 §5）。
- **客户端承接义务**：`auth` 那一份为**零**；`manifest` 那一份两项（按支持集合拼请求路径 · 对 CDN 域 4xx 按两分处置，其中「不对 4xx 走 3 次退避重传」是对既有下载重试语义的收窄），已写进 handoff 的「客户端侧影响」，**本库不代为裁决**。

## 2026-09-07 — 全库对账整理：分片零增删，四处主题文档指路失真待用户处理（`/summarize-open-questions backend`）

一次专职整理，不引入新想法、不裁决任何问题。范围 = 全部主题文档（`vision/` 1 · `contracts/` 6 · `systems/` 3 · `operations/` 10）+ `handoffs/`（**35 份全 `distilled`**，`_index.md` 35 行 ⇔ 35 份文件逐条对齐，无未采集意图面）+ `inbox/` 顶层（空）+ 五份分片。**移出 0 条，新并入 0 条，新增待答 0 条，本次不建 answer log。**

- **待答面维持三条**（与 09-06c 收窄后完全一致）：`02` 合规能力的上线分级（含从属项「第三方昵称审核首版是否启用」）· `06` 昵称审核 `rejectThreshold` / `reviewThreshold` 取值 · `06` 成本模型。`01` / `04` 仍清零。三条全部只差**排期或实测数据**，无一条取决于形态决定。
- **跨边界两向仍闭合。** 对侧 `game-design-documents/handoffs/` 中 **2026-09-04 及以后的 21 份逐份核对，对本库产生义务的为 0 份**——三份触及边界的（`baseline-superset-and-pack-proof` · `iap-channel-integration` · `backend-batch-client-obligations`）后端半均已落笔或方向相反（后端义务落给客户端），其余明写「后端零配合 / 零参与」或全文零后端提及。对侧 `cross-boundary.md`「待承接」为空；本库同区亦空。
- **常规触发源未触发。** 对侧 `systems/services/profile-schema-versions.md` 登记表**仍只有 `1` 一行**（v1 首发形状清单已扩至 #34 条，但均在 v1 行内、不构成 bump），本库 `operations/version-matrix.md` 的 `schemaVersion` 子表 `{1}` 无需新增行。对侧 09-05 已显式裁决「不去后端库补一句显式否定」。
- **本次唯一产出是四处失真的登记（属主题文档，不在本技能写入面，交用户处理）：** ① `vision/scope.md` 的 Open questions 指路两句全过时（称边界层「余下各端点报文本体」、称技术栈 / 托管「全未定」）；② `contracts/auth.md` 称「改名频次阈值归 `06`」，而该阈值已定值 3 次 / 30 天（09-06 落本文件 §8），且同段自称「取值表已封定」自相矛盾；③ `contracts/compliance.md` 与 `operations/compliance-ops.md` 两处「实名核验服务商与灾备归 `06`」为**悬空指路**——灾备形态 09-06 已答结（`operations/external-providers.md`：首版 1 家 + 一家完成合规评估不接入 · 禁双验 · 切换两条件），`06` 分片已无此条，而「选哪家」被 `external-providers.md` 明写为商业决定、不点名、不属设计待答；④ `contracts/purchase.md` 称冷存归档「形态需真实体量才能定」，而三层形态与对账阈值 N 的初值 / 校准公式 09-06 已定（`operations/purchase-ops.md` §3d §4），残留的只是实测定值。四处均**不改任何就绪度判定、不阻塞 derive**。

## 2026-09-07 — 09-06 那批定案集中立档，并追认三条被 handoff 自评挡下的候选：新增 `ADR-0028` ~ `ADR-0050` 二十三份（`/write-adr backend`）

一次专职立档，不引入任何新设计。**候选清单侧零变动**——`open-questions.md` 的 `## 下一阶段` 本就不含 ADR 候选条目，`decisions/_index.md` 的「ADR 候选」表已于 08-19 整节删除。候选来自**七份 `2026-09-06-*` handoff 里散落的已定案方向**（晚于 `ADR-0027`，此前在 `decisions/` 无落点）+ **09-06 那次运行识别出、但被 handoff 自评挡下的三条**。逐条按「台账绝不领先于事实」核对过主题文档才建档：**零条查无实据、零条与主题文档矛盾**。

- **合规域与可信时钟 10 份**（来源 `-trusted-server-clock.md` 与 `-compliance-domain-storage.md`，两份 handoff **全文零次出现 "ADR"**——属簿记漏项而非已判定）：`ADR-0028` 事务库时钟为判定基准 + 只 slew 不后跳 · `ADR-0029` 时段规则集不可变版本化（时区入集）· `ADR-0030` 节假日日历人工录入与两类条目 · `ADR-0031` fail-closed 的例外判据 · `ADR-0032` ticket 载体与「回放窗口 = 寿命的延长」· `ADR-0033` 冷静期独立表与 `previous_status` · `ADR-0034` `SKIP LOCKED` 周期扫描零新增组件 · `ADR-0035` 注销执行的两条保留 · `ADR-0036` 导出产物私有桶与现签短链 · `ADR-0037` `signin` 四码求值顺序。
- **外接能力 6 份**（`-external-provider-selection-dr.md` 与 `-iap-channel-integration.md`，同样零次出现 "ADR"）：`ADR-0038` 适配层 `Outcome` 三档与单一归一点 · `ADR-0039` 逐能力冗余度 · `ADR-0040` 禁双发 / 禁双验 · `ADR-0041` 向外调用类凭据分立托管（**渠道凭据与外接凭据合成一份**——同一条「按轮换驱动方分立」判据的两个实例，不能独立推翻）· `ADR-0042` 微信资质过闸断言 · `ADR-0043` 频次闸豁免拦截不豁免计数。
- **购买域 2 份**（`-receipt-idem-cold-archive.md` · `-iap-channel-integration.md`）：`ADR-0045` 收据幂等三层归档与哨兵行永不删 · `ADR-0046` `Rejected` 原因复用 verify 终态 `code`。
- **内容分发 1 份**（`-flags-propagation-window-and-instance-skew.md`）：`ADR-0047` 传播窗口以实例为主体 + A7–A9「头永不领先」（T = 60 秒作为关键取值写进决策段；探针与「多区域以否定结论收口」作为后果，**不单独立档**——后者是 `ADR-0021` 单区域拓扑的直接推论）。
- **追认三条（用户 2026-09-07 裁决「全部建档」，越过 handoff 自评）**：`ADR-0044` 昵称 accept-then-review（**原属漏列**，其来源 handoff 只自陈两条候选）· `ADR-0048` 发布侧校验闸只验背书不复制规则 · `ADR-0049` 首版即内置 active/standby 两把公钥 · `ADR-0050` 合并校验逐基线各跑。后三条出自两份**明确自陈「无 ADR 候选」**的 handoff（`2026-09-03-content-delivery-ops.md` · `2026-09-06-baseline-superset-and-pack-proof.md`），按根约定「一切皆可改」由用户推翻其自评。
- **识别为候选但本次不建档**：`2026-09-06-spec-check-automation-hosting.md` 的五条（机检承载 = 设计库分支独立 workflow · 不引 PR 门 · spec 未落笔期的降级形态 · 存在性驱动的切换判据 · 三条提取护栏 P-1/P-2/P-3）——该 handoff 自陈的是「**不新建 ADR → 采纳**」，即**当时的用户裁决**而非 handoff 自评，故不推翻。另有若干条判为非方向性、并入他条后果段：`status` 三值 PascalCase（`ADR-0013` 内已就地承载）· 选型硬判据 H1–H4 · TTL 断言逐表扩写 · `tier='hot'` 部分索引 · `claimingSweepMinutes` 旋钮化 · 对账阈值 N 的校准公式与静默观测期 · `/blobs/*` 关负缓存与步⑤探针走 CDN 域 · 三个合规旋钮初值沿用。
- **未处理的相邻漂移**（属主题文档，不在本技能写入面，第四次记录）：六份契约的 `## 决策(-> ADR)` 段仍指向已删除的「ADR 候选」登记处，且 `auth.md` 与 `content-manifest.md` 本地编号互撞（都称候选④）；`ADR-0017` / `ADR-0025` 的回链仍是单向的。
- **台账**：`decisions/_index.md` 决策表新增 23 行（最新置顶、日期降序、同日按编号降序）；27 份既有 ADR 与文件已对账，**无孤儿文件、无悬空行，本次无失真可修**。「已对后端构成约束的客户端决定」表**一格未动**。`open-questions.md` **一字未改**。

## 2026-09-06c — 六份已评审草稿一次清空 inbox：`01` / `04` 待答清零，`06` 收窄至两条待实测取值（`/batch-analyze-new-ideas backend`）

一次批量运行覆盖 `inbox/` 顶层全部六份 solution-draft，**移出 6 条**（`01` ×1 · `04` ×1 · `06` ×4），新建两份运维文档，`operations/` 九份自此全部建立。全部取向裁决来自用户 2026-09-06 的批量评审（已写回各草稿），合并 interview 仅追加**一题**——见下方「唯一新出题项」。

- **`01` 三条机检断言的工程承载。** 承载定为**设计库分支（`backend-design`）上的一条独立 workflow**（`contract-spec-check`，push + 手动触发，路径过滤 `contracts/**`），**不挂镜像构建流水线**——`contracts/` 只存在于设计库分支，跨分支检出会把两条独立分支线在 CI 层重新耦合。绿灯 = 完成判据第 4 条的兑现物；红灯 = 该次契约变更未完成，修复形式是前滚一次提交；无条件触发、不设跳过开关；失败走代码托管方默认通知、不进 `observability.md` 告警面；同一套检查须能本地一条命令跑完。spec 未落笔期跑降级形态（①报 `skipped: no spec yet` 而非 `pass`），切换判据 = `openapi.yaml` 的**存在性**，不设开关。**workflow 与脚本本批不落地**（本次授权只写设计库），在此之前以人工清单前三项执行。→ `../answer-logs/log-spec-check-automation-hosting.md`
  **唯一新出题项（Phase A 实测发现草稿缺陷，用户当场裁决）：** 断言③′ 原定基准是 `envelope.md` §3 端点清单，但 §3 实为**前缀 + 省略号且不带 HTTP 方法**，按原样实现会把 auth / compliance / purchase 三域 16 个端点全报成「§3 缺失」。**裁决：§3 展开为 `METHOD 路径` 端点全集表并升为机器读取面**，配一条 P-3 护栏（改端点须同改本表），保住跨文档双向核对——与断言②「错误码台账 ⇔ 六份契约正文」同构。
- **`04` 多区域一致性与传播窗口 T。** CDN 侧三问以**否定结论**收口：单区域部署下不存在「多区域」这个对象，`contentRoot` 按区域下发不启用（自由度保留，用途改述为域名 / 厂商切换与日后独立部署），区域间时序差降格为边缘缓存传播。**T 重定义为跨实例窗口**（契约主体由「全部区域」改为「全部对外服务的实例」）、初值 **60 秒**（分项：版本读取缓存 TTL 5 秒 · 副本滞后预算 10 秒，当前实际 0），并配三条服务端纪律 A7–A9 使偏斜的误报方向结构性不可能（**头永不领先于本实例能兑现的规则集**）。另补两条 CDN 能力要求（`/blobs/*` 关负缓存 · 发布步⑤ 探针走 CDN 域）。**契约零报文改动、零 schema 提升、客户端零义务。** → `../answer-logs/log-cdn-multi-region-propagation-window.md`
- **`06` 可信服务端时钟。** 判定基准 = **事务库时钟**（两处例外另述）· NTP **只 slew 不后跳**、时钟异常期间暂停不可逆动作（注销执行是本库唯一不可逆的周期动作）· 时区 IANA 名随时段规则集**同版本发布**、不进代码常量也不落 `config_knob` · `playtime_ruleset` 走词表式的不可变版本化发布 · 法定节假日日历两类条目（含调休工作周末）与四步判定顺序 · 三个失败面各自的降级语义，日历过期时未成年账号一律 **fail-closed**。配套：tzdata 启动断言（解析失败拒绝启动）、年度日历录入的周期性运维日程、时钟两条探针与日历到期告警。→ `../answer-logs/log-trusted-server-clock.md`
- **`06` 合规域的存储与产物。** `complianceTicket` 落 PG，一次性消费由**条件更新**兑现、60 秒回放做成「寿命的延长」而非第二套机制；冷静期走 `SELECT … FOR UPDATE SKIP LOCKED` 周期扫描，**零新增组件**（无调度中间件 / 消息队列 / 分布式锁）；数据导出走私有桶 + **每次现签短寿命链接**（7 天是**产物保留期**、不是链接寿命，契约 §10 就此补一句读法澄清）。三个旋钮初值沿用契约 §9 并各自补上校准信号。**账号注销执行保留 `receipt_idem` 全行 + 最小 `account` 墓碑**（墓碑不含个人信息、不可关联到自然人），identity / 存档 / 实名材料 / 风控事件照常硬删。同批把 `signin` 四条拦截码的求值顺序写死（`account_deleting` → `account_restricted` → `realname_required` → `playtime_blocked`）。→ `../answer-logs/log-compliance-domain-storage.md`
- **`06` `receiptId` 幂等记录的冷存归档与对账阈值。** 三层形态：热层 = 现有 `receipt_idem`（哨兵五列常驻、**行永不删**）· 温层 = 同库 `receipt_idem_archive`（按 `record_at_utc` 年度 RANGE 分区、每分区唯一索引，仍是点查）· 冷层 = 对象存储导出，只作备份与离线分析、不在任何在线读路径上。归档只搬记录体列并置 `NULL`；任务默认关闭，`receiptArchiveAgeMonths` 初值 24 个月。原三条触发阈值中「行数 > 5,000 万」**重分类为容量 / 扩容信号**——哨兵行常驻使归档不可能降低行数。对账阈值 N 初值 3 天不改、提为旋钮，校准公式 `N := clamp(ceil(P99(追平时长_天)) + 1, 3, 14)`，上线后静默观测 4 周；**只作人工 / 工单入口，不驱动任何自动写入**。**「哨兵行永不删」由同批合规域裁决坐实**，两份一致落笔、互相回链而不复述。→ `../answer-logs/log-receipt-idem-cold-archive.md`
- **`06` 外接原子能力的选型与灾备（部分移出）。** 四类能力（短信 / 邮件 / 实名核验 / 第三方昵称审核）的适配接口共有形状与四个签名 · 硬超时初值 · 归一映射 · 逐能力的供应商数与灾备切换（禁并发双发 / 禁双验 / 同码转备用两条件）· 选型判据与凭据托管（能力 × 供应商 × 环境，独立审计线）· 微信开放平台资质的前置链与**可验证的过闸断言**（在 `backend-testing` 完成一次真实微信登录、取到非空 `unionid` 且 `idKind` 落为 `unionid`），资质延误取**推迟上线**、不以 `openid` 先行建号。`TooFrequent` 定值 **3 次 / 30 天滚动**；`nicknameChangeRequired` 为真时**豁免频次闸的拦截、不豁免计数**（否则处置阶梯与频次闸互锁且无自解通道）。**残留**：`rejectThreshold` / `reviewThreshold` 的取值，从属 `02` 的上线分级。→ `../answer-logs/log-external-provider-selection-dr.md`
- **三处「归一到本库已有的 `code`」措辞同批订正为「按调用点所在域取」**并剔除 `auth.challenge_expired`（该 `code` 由本方生成 / 存储 / 判超时，服务商侧无对应物；其定义与其余引用一律不动）。三处处置不一刀切：`02` 顶部引言只改措辞、`06` 那条整条移出并留残余、`systems/account.md` 是唯一需要同改列举的一处。
- **顺带落笔（答案已定的机械项）：** `deployment.md`「同一条流水线」改写为设计库分支上的独立 workflow · `systems/_index.md` 的 `content-delivery.md` 两项欠账全部闭合 · `environments.md` 旋钮清单本批 **+15 行**（含悬挂 `claiming` 清理阈值补登与昵称改名频次阈值回填）· `contracts/compliance.md` §10 `downloadUrl` 读法澄清。**多处「三把钥匙 / `kind` 八值 / 三条不变式」一类写死的计数同批去计数化**——本批新增第四类凭据与两个 `kind` 值会让这些计数同时失真，而漂移时没有任何机制会报错。
- **契约面净变化：零新增 `code`、零报文字段改动、零 schema 提升。** `contracts/auth.md` §8 补列的 `server.unavailable` 是把 §3a 早已定死的事实写进错误清单（一处既有文本失真），不是新增。

## 2026-09-06b — 渠道凭据托管形态 + `Rejected` 原因取值 + C6 / A4' 定案 + envelope 拦截码措辞承接（`/batch-analyze-new-ideas` 跨库两对 · 后端半）

- **移出 2 条。** ① `06` 的「三渠道验票凭据的托管形态（部分答结）」整条答结：托管载体 = 云 Secrets（SSM）条目、渠道 × 环境粒度、`credentials[]` 数组承载新旧并存、启动拉取 + 周期刷新（旋钮初值 5 min）、第三条独立审计线，落 `operations/purchase-ops.md` §1；连带 `contracts/purchase.md` §4 补「`Rejected` 时附 `code`（⊂ { `purchase.receipt_invalid`, `purchase.receipt_claimed` }）与可选 `detail`」——零新码、零台账行。→ `../answer-logs/log-iap-channel-integration.md`。② `cross-boundary.md` 待承接仅有的一条（`envelope.md` §6 四条 `compliance.*` 拦截码「客户端处置」列改回链客户端库）已机械落笔关闭。→ `../answer-logs/log-0906.md`。
- **裁决落笔（草稿批量评审已定）：** `status` 三值统一 PascalCase `{ Unknown, Verified, Rejected }`（`ADR-0013` 一行 + `ADR-0019` 四处 + `purchase.md` §3b §4 §6 + `purchase-ops.md` 字面值，全库小写残留清零）· C6「超集成立可只跑最新」经推演**不成立**，逐基线各跑定为长期形态、不再是待优化项；A4' 优化路径改写为「已定形态、未采纳」+ 读数面 / 采纳触发两表（`operations/content-delivery-ops.md`，数值初值 +2 行）。
- 两对 counterpart handoff（`2026-09-06-iap-channel-integration` · `2026-09-06-baseline-superset-and-pack-proof`）与客户端侧互链；客户端半摘要见 `game-design-documents/open-questions/update-log.md`。零新增契约面、零报文改动（§4 的 `code` 字段属应答体普通字段，客户端处置零新增、仅知会）。

## 2026-09-06 — 09-03 那批定案集中立档：新增 `ADR-0018` ~ `ADR-0027` 十份（`/write-adr backend`）

一次专职立档，不引入任何新设计。**候选清单侧零变动**——`open-questions.md` 的 `## 下一阶段` 本就不含 ADR 候选条目，`decisions/_index.md` 的「ADR 候选」表已于 08-19 整节删除。本次候选全部来自**六份 `2026-09-03-*` handoff 里散落的已定案方向**（它们晚于 `ADR-0017`，此前在 `decisions/` 无落点），逐条按「台账绝不领先于事实」核对过主题文档后才建档。

- **购买域 2 份**（来源 `2026-09-03-purchase-channel-integration.md`，该 handoff 自陈两条候选）：`ADR-0018` 验票请求的判别式在请求根 · `ADR-0019` 微信下单端点不改写入权威分配。
- **合规域 1 份**（`2026-09-03-compliance-endpoint-payloads.md` 自陈一条候选）：`ADR-0020` ticket 兑付的 60 秒回放窗口（pillar #2 的第四次兑现，与 `ADR-0004` 互为回链）。
- **技术栈与登记权威 5 份**（`-backend-stack-and-hosting.md` 与 `-schema-bump-ledger-authority.md`，两份 handoff **全文零次出现 "ADR"**——既未表态有候选、也未表态无候选，属簿记漏项而非已判定）：`ADR-0021` 单主运行时形态与读路径拓扑（栈 + 拓扑合成一份，两者互相牵动、不能独立推翻）· `ADR-0022` refresh token 派生串 · `ADR-0023` KMS 不进签发热路径 · `ADR-0024` `schemaVersion` 登记权威与发布顺序 · `ADR-0025` 未知取值宽容的判据边界（`ADR-0017` 的反面，两条一起才是完整判据）。
- **昵称与风控 2 份**（`-nickname-moderation-and-risk-control.md` 自陈两条候选）：`ADR-0026` 处置只落 `status` 侧 · `ADR-0027` 自动处置止步工单 + 全局熔断。
- **识别为候选但本次未建档**（交用户裁决，全部**已落地**、不缺事实依据）：昵称 accept-then-review（该 handoff 只自陈两条候选，第三条未列）· 发布侧校验闸 C1 的分工切法 · 首版即内置 active/standby 两把公钥（后两条出自 `-content-delivery-ops.md`，该 handoff **明确自陈「无 ADR 候选」**，故不越过它的自评建档）。
- **未处理的相邻漂移**（属主题文档，不在本技能写入面）：六份契约的 `## 决策(-> ADR)` 段仍指向已删除的「ADR 候选」登记处，且 `auth.md` 与 `content-manifest.md` 本地编号互撞（都称候选④）；`ADR-0017` 的回链仍是单向的，现 `ADR-0025` 落笔后更值得一并收。

## 2026-09-05 — 全库对账整理：剧本分包由对侧答结、多区域条收窄、两处对账基线补齐（`/summarize-open-questions backend`）

一次专职整理，不引入新想法。范围 = 全部主题文档（`vision/` · `contracts/` · `systems/` · `operations/`）+ `handoffs/`（21 份全 `distilled`，无未采集意图面）+ `inbox/` 顶层（空）+ 五份分片。**移出 1 条，新并入 1 条，改写 1 条，新增待答 0 条。**

- **移出 1 条（`04`）**：**剧本内容的体积与分发形态** —— 答案落在**对侧库**：客户端裁定剧本树**不按篇章分包**，整体随 `res://` 基线发布、更新走 overlay 文件级增量（`game-design-documents/decisions/ADR-0029-plot-tree-single-baseline-package.md`，**Accepted**）。对本库是**零机制增量**（manifest 不加字段 · `manifestSchema` 不提升 · 报文无变化），原条目「契约形态由本库定」那一半无需落笔即闭合。**残余换归属而非未答**：首包 / 增量下载量上界与 CDN 成本 → `06` 的成本模型条。对应 answer log：`answer-logs/log-0905.md`。
- **新并入 1 条（`06`）**：`contracts/compliance.md` 的 `## Open questions` 里挂着**三个旋钮初值待实测校准**（实名提交次数上限 · 导出申请限流 · `pollAfterSeconds`），此前**任何分片都未跟踪**。作为「合规域的存储与产物」的从属项并入，与 `receiptId` 冷存 / 对账阈值同属「需真实体量才能定」。
- **改写 1 条（`04` 多区域一致性）**：后端服务侧那一半已被 `operations/environments.md` 答定（主区在中国大陆境内 · **单区域部署、不做跨区域多活** · 个人信息不出境），条目据此收窄为只承载 **CDN 侧**的三问（`contentRoot` 按区域下发是否启用 · 跨区 `contentVersion` 是否同步推进 · 区域间时序差）**+ 传播窗口 T 的数值**。仍待答，不移出。
- **`04` 新增「条件化核对项（不是待办）」一节** —— 关闭 08-30 就绪度评估记录的**孤儿指路**（漂移清单第 5 条第 ③ 项）：`content-manifest.md` 的 blob 一节写「展开见 `04-content-delivery.md`」，而该文件里此前**没有这三点的任何一行**。现由 `04` 承接三点并注明「条件化于日后开放、不构成待办」，**不复述契约正文的判据**。契约正文未动（主题文档非本技能写入面）。
- **`cross-boundary.md`「对账基线」补两条**（均**只回链不复述**、均**不改任何就绪度判定**）：
  ① **剧本不分包** —— 客户端定案、本库零义务，与上方移出条对位；
  ② **`2026-08-30-exchange-barter-support.md` 的存档结构未产生新 `schemaVersion`** —— 关闭 08-30 漂移清单第 7 条（「本库零留痕」）。核实结论**比原判断更干净**：对侧登记表 `profile-schema-versions.md` **只有 `1` 一行**，Exchange 物化字段与 `Source.ExchangeBarter = 10` 均折入 **v1 首发形状**（v1 清单第 25 条），**根本不是一次 bump** ⇒ 「常规触发源」条件未成立、无条目可开；本库矩阵已于 09-03 登入 `1`。故它不是欠账，只是处置不一致（08-25 同类记了 handoff、08-30 未记），现补留痕闭合。
- **`derive 就绪度` 小节原样未动**（由 `/assess-derive-readiness` 独占写入）。但需注意它**成文于 2026-08-30、早于 09-03 的两批落笔**，其中「`systems/` 目录下仍只有 `_index.md`」「`operations/` 尚无文档」「矩阵落 `operations/` 而栈未定故当前空置」等描述均已过时——`systems/`（3 份）与 `operations/`（8 份）现已成文。**结论请以一次新的 `/assess-derive-readiness` 为准。**
- **主题文档滞留项 5 条已清理（用户当场授权，超出本技能默认写入面）** —— `auth.md` / `profile-sync.md` / `purchase.md` 的 `## Open questions` 里 5 条已于 09-03 答结却未清理的条目。**逐条只删已答部分、保留仍开放的残余**，并把被删条目里承重的约束就地迁进正文（不是丢弃）：
  - `auth.md` 删 2 条（refresh 限流形态 · token 签名密钥保管与会话存储与限流实现）。**承重约束迁入 §8 refresh 错误清单段**：「刻意不给 `rate.limited` · 网关侧也不得静默加 · 日后若限流须回改本节并同时给客户端第三条处置路径」，回链 `operations/deployment.md` G-1。另修一处**同源失真**：§8 旋钮表下的「限流实现与阈值归 `06`（栈落定后进 `operations/`）」改指 `operations/environments.md` 的「旋钮清单」与「限流的实现分层」，并点明**昵称改名频次阈值是该表唯一未定值项**。保留的 1 条 = 改名频次阈值与第三方审核服务商。
  - `profile-sync.md` 删 2 条，**该节现为「无待答项」** + 一张四行「原待答项 → 现落点」对照表（`operations/moderation.md` · `systems/profile-store.md` · `operations/environments.md` ×2）。契约当初即写明「归 `06`、落 `operations/`、不回头改契约」，故**契约语义一字未改**。
  - `purchase.md` 删 1 条**并改写为其真实残余**：存储选型与事务实现已落 `systems/profile-store.md` + `operations/purchase-ops.md`；仍开放的是**冷存归档形态与对账信号阈值 N**（本就在 `06` 跟踪，此前契约侧未如实反映）。
  - **溯源补齐**：`auth.md` / `profile-sync.md` 的 `Source:` 行补入 `handoffs/2026-09-03-backend-stack-and-hosting.md`（与 `-nickname-moderation-and-risk-control.md`），并注明这两份**只落实现侧、契约未改**——按「活文档不留考古、溯源由 `Source:` 承载」的根约定，删掉的内容由它兜住。
  - **本次清理不改任何报文面**：不新增 / 删除 / 改动字段、端点、错误码 ⇒ 不 bump `openapi.yaml` 的 `info.version`，不触发 `contracts/_index.md` 的三条机检断言。待答总数因此**净减 5**（分片侧不变——这 5 条本就只滞留在主题文档，分片早已不跟踪）。

## 2026-09-03b — `schemaVersion` 兼容矩阵的输入、登记流程与漏登告警（跨库成对 · 后端半）

`/batch-analyze-new-ideas` 的一个分片（另一半在客户端库同批落笔）。**移出 1 条，新增 0 条。**

- **答结**：「`profile-sync.md` 把 bump 清单的权威指回客户端，而那张清单已漏批 ⇒ 两侧都以为对方在记」。对侧同批把清单拆成逐版登记表 `game-design-documents/systems/services/profile-schema-versions.md`（核实后其漏登面远大于登记时所记：就地自称 24 处 + 5 份 ADR，v1 行补齐 27 条）；本库 `version-matrix.md` 的 `schemaVersion` 集合由一个标量展开为**一版一行的四列子表**，第四列是**回链不是摘要**——本库一个字段名都不写，判据即 `envelope.md` §8「不把 Profile 字段表抄进本库」。
- **裁决两项**：① 未知 `schemaVersion` 告警取**按与已登记集合的大小关系二分**（> 最大值 ⇒ 工程告警叫人；< 最小值 ⇒ 信息级、只上看板）——旧客户端制造的越界与「透明路径缺失」那行的预期噪声同类，处理手法一致，**拒绝语义不变**；② 矩阵**本批即登 `schemaVersion = 1`**，不等首个客户端版本——客户端 v1 既已定案，按本库自己的「矩阵先加、客户端后发」纪律，等待就是无成本的反序，且不登会让第四列回链落笔当天即无处可指。
- **登记流程进 `operations/_index.md`**，与错误码台账的登记流程并列：触发点 = 对侧登记表新增一行 · 承载 = `cross-boundary.md` 四段式条目 · 责任人两段（开条目归发起方 = 恒为客户端；落笔矩阵归后端）· 顺序 = 矩阵先加、客户端后发（补一版只需改旋钮不发版，反序的代价由玩家承担）。这与错误码的「先文档 → 后 spec → 后实现」是同一条纪律的第二个实例。
- **漏登的机制发现面 = `observability.md` 第五条探针**（未知 `schemaVersion`，计数器 + 低基数双标签，阈值 0）。没有它，漏登的表现是一批玩家安静地上不去进度、客户端只出一条非模态提示，**后端侧零信号**。
- **同批附带**：`envelope.md` §7e 补一句指路（**语义未改**——核实确认 §7e 本就是内容完整的指路条款，此前「§7e 全空」的说法不成立）；§8 统计层推论按跨库裁决**收窄**到「已有的不透明顶层键内的追加」，引入新顶层键与受回声约束键内追加各自不适用；`profile-sync.md` 补一句不对称声明（`reason` 的宽容不适用于 `schemaVersion`，判据 = 有无判定权），**`reason` 那条一字未改**。
- **报文形态零改动**：不新增字段 / 端点 / 错误码 ⇒ 不 bump `openapi.yaml` 的 `info.version`，不触发 `contracts/_index.md` 的三条机检断言。
- **新增 1 条待承接**（`cross-boundary.md`，来自客户端同批的另一分片）：`envelope.md` §6 台账中四条 `compliance.*` 拦截码的「客户端处置」列改为回链客户端库——语义不变，只消除措辞不一致。
- 对应 answer log：`answer-logs/log-schema-bump-ledger-authority.md`。

## 2026-09-03 — 五份草稿批量提炼：技术栈落定 · 合规域完全成文 · 三渠道接入面 · 内容分发与风控的运维形态（`/batch-analyze-new-ideas backend`）

一次清空 `inbox/` 顶层的全部五份 solution-draft。Phase A 四个分片并行只读校验，合并去重后开一场 interview（🔴 9 · 🟠 4 → 去重与跨草稿核对后 **10 问**，用户逐项裁决、**全部采纳推荐项**）；Phase B 按写入面分区并行落笔。

**移出 17 条 + 2 条部分答结，新增 0 条。** 逐分片：`01` 2 条（合规域端点自身的错误码 · `refresh` 的限流形态）· `02` 3 条主项 + 1 条从属项（敏感词词表与审核口径 · 未过审昵称的存量扫描 · 风控与滥用面 · 三档处置的可见粒度）· `04` 3 条（flags 数据源与变更通道 · 签名私钥保管与 CI 及 `keyId` 轮换 · 发布侧内容校验闸）· `06` 8 条整条（技术栈与托管 · 区域与合规托管 · token 签名密钥与会话存储 · 会话记录的并发语义 · 环境分层与发布线 · 可观测性口径 · 同步侧语义的实现落地 · 读己所写对拓扑的约束）+ 2 条部分（`receiptId` 幂等记录的存储已定、冷存归档与对账阈值仍留；三渠道接入面已定、验票凭据托管形态仍留）。

**合并 interview 的十项裁决：**

1. refresh token 载荷改为 `<tokenId>.<mac>`（`tokenId` 与 `sid` 分离、`generation` 不上报文）⇒ **`contracts/auth.md` 零改动**，且顺带补齐 `SessionSuperseded` 与 `TokenReuseDetected` 的分辨。
2. access token 保持 EdDSA，**KMS 只保管被包裹的私钥、签名在进程内**——KMS 不在登录热路径，停机不影响登录；逐次签名审计降级为解包事件审计。
3. flags 应答**逐账号签名**，按 `(flagsVersion, accountId)` 缓存 `sig`；内容签名私钥因此**在 flags 读路径上**，可用性档位与 flags 端点同档（草稿原写的「不在任何请求路径上、可低一档」当场不成立，连带修正其成本分析与轮换止血论证）。
4. `ADR-0007` 连带条款首行改写为「幂等键**不由客户端生成**」——微信渠道的商户订单号由后端下单时分配，「由平台发放」只是另两家的事实描述；决策本体与其余五条逐字不变。
5. 读路径拓扑**统一走写入区**，flags 的自由度只留档不启用（两个分片措辞逐字对齐，不写「读路径分档表」、不引入例外）。
6. 首版即内置 active + standby **两把内容签名公钥**（兑现契约已写的「一组映射」，报文零改动），客户端承接项跨库对称落笔。
7. 新增 `OpError.Purchase`；`purchase.payload_invalid` 仍映 `Validation`（bug 面 / 玩家面之分）。
8. 爆炸半径闸退化为**纯计数 > 20 条**——后端不感知内容类别，契约「服务端不区分内容类别」保住。
9. 新增第五条 `purchase.channel_disabled`，与 `receipt_invalid` 分列（未开通发生在下单、玩家尚未付款）。
10. standby 私钥 = 同一密钥服务内的独立密钥（权限平时不授予任何身份）；灾备副本**不定数量、只写能力要求**。

**结构性变化：** `operations/_index.md` 长到 30 KB，按两份草稿自己写的展开条件（「栈落定后展开」，条件本批已满足）拆为 `operations/content-delivery-ops.md` 与 `operations/moderation.md`，索引回归索引；`systems/account.md` 与 `systems/profile-store.md` 新建；`operations/` 另新增 `environments.md` · `deployment.md` · `observability.md` · `version-matrix.md` · `purchase-ops.md`。**全库再无结构性前置**，焦点下移到合规上线分级与外部依赖选型。

**跨库：** 三条客户端承接义务（standby 公钥内置 · `OpError.Purchase` 成员 · 合规域三条新 `code` 的 `ERR_*`）在客户端库登记为提案形态承接项，**本库不代为裁决**；对侧 `ComplianceManager` 覆盖面切分的待承接项**不由本批关闭**。

答案 log：`answer-logs/log-compliance-endpoint-payloads.md` · `log-nickname-moderation-and-risk-control.md` · `log-purchase-channel-integration.md` · `log-content-delivery-ops.md` · `log-backend-stack-and-hosting.md`。

## 2026-09-02 — `contracts/auth.md` §4 加客户端下游依赖登记（跨库成对 · `/batch-analyze-new-ideas` 的对侧半）

客户端本批答结「refresh token 平台密钥库的后置评估」，其明文存放取向的**全部辩护挂在本库 `contracts/auth.md` §4 §5b 的 rotation 与「窗口外重放即吊销全部会话」语义上**，而本库此前**零登记**——`auth.md` 文末反而宣称「两侧无遗留欠账」，属失真陈述。按跨库纪律「对称落笔、不允许只改一侧就宣称收口」，本次在对侧库落两处：

- **§4 末新增一条只回链、不复述的下游依赖登记**：客户端凭据本地存放取向以本节语义为支点，语义的权威在 `game-design-documents/systems/services/account-service.md`（本库不复述）；**本节任一条被改写、削弱或取消 ⇒ 须同批触发客户端侧重评**。
- **文末「跨库待办」尾句措辞调整**：由「两侧无遗留欠账」改为「无遗留的实现欠账，但有一条常驻的反向依赖」，并指向 §4 末的登记。

它**不是待答项**（无人需要回答什么），而是一条已成立的下游依赖事实，故落契约正文而非 `open-questions/cross-boundary.md`。**本次移出 0 条、新增 0 条。**

## 2026-08-30 — flags 缓存的报文侧对位 + blob 不承载二进制（跨库成对 · `/batch-analyze-new-ideas` 的对侧半）

- `contracts/content-manifest.md` 的 Open questions **四条 → 两条**（余：多区域一致性 · flags 数据源与分桶的运营形态）。
- 新增：`no-cache` 的**层次澄清**（回链 `envelope.md` §3，不在该侧复制）· **后端义务 = 零**的四行否定性义务表 · B 组第 7 条的依赖方登记为两项 · `## blob 通道不承载二进制资产`（含「这不是契约能力不足」的能力中立声明 + 三点条件化核对项）。
- 连带：`decisions/ADR-0002` 后果末行去掉「以支撑离线开局」这一**错误前提**（客户端库明写缓存的收益只在「登录成功但 flags 拉取失败」时的降级值；该错误措辞此前有三份副本，草稿只点名了两份）· 「剧本文本」节「上述三条服务端保证」去计数化为「A 组的服务端保证」。
- **报文零改动**：`flagsSchema` / `manifestSchema` 均不提升，A 组仍四条、B 组仍三条。
- 客户端半同批落笔，两侧互相回链、无一处复述对方设计。answer log：`answer-logs/log-client-flag-cache-and-binary-overlay.md`（2 条）。

## 2026-08-28（`/write-adr backend` · 全量范围 · 一条候选固化 · 移出 0 条 · 新增 0 条）

- **增量运行**：上次（08-26）已把 handoff 里的散落定案扫到 08-23，本次只需覆盖其后新增的两份 handoff。`open-questions.md`「下一阶段」仍不含 ADR 候选条目，`decisions/_index.md` 的「ADR 候选」表已于 08-19 整节删除，故候选仍全部来自 `status: distilled` 的 handoff。
- **固化一条**：**`ADR-0017` 零判定权字段的取值清单不是校验闸：未知取值宽容接收，清单增量不 bump 契约版本**（08-28，→ `contracts/profile-sync.md` §2 L65–66 + §5a，来源 `handoffs/2026-08-28-save-point-reason-inventory-changed.md` · `handoffs/2026-08-12-grant-source-code-contract.md`）。逐条回主题文档核对，判为**已落地**。它把此前只在 `sourceCode` 一个字段上作过的处置**上升为按「是否驱动判定」分类的通则**，并连带定死两侧的发版顺序自由度与「不 bump 契约版本」。
- **同批的另一半判为不适合立档**：`reason` 取值清单五值扩六值（追加 `"InventoryChanged"`）本身是**纯表格增量**——字段类型 / 必填性 / 判定路径 / 契约版本均不变，成员语义权威在客户端库，不含方向性取向，只作为 `ADR-0017` 的触发场景写进其背景。
- **08-25 的 Codex 顶层键去计数化维持不立**（08-26 已判：报文形态一字未变、纯编辑性，且其后缀判据以 `ADR-0014` 的命名通则为前提）。
- **台账**：`decisions/_index.md` 决策表新增一行（最新置顶，日期降序）。16 份既有 ADR 与文件已对账，**无孤儿文件、无悬空行，本次无失真可修**。「已对后端构成约束的客户端决定」表**一格未动**（跨库引用表，非候选）。
- **`open-questions.md` 一字未改**：「下一阶段」无候选条目；`## derive 就绪度` 属 `/assess-derive-readiness` 独占（其中「`decisions/ADR-0001` ~ `ADR-0016`（16 份）」的计数自本次起过时，待下一次全量评估刷新）。
- **未收口的候选登记处依旧**：`contracts/profile-sync.md` §407「决策(-> ADR)」三条仍写着「登记于 `decisions/_index.md`」而候选表已删——主题文档归本技能红线之外，**未改**。

## 2026-08-26（`/write-adr backend` · 全量范围 · 七条候选固化 · 移出 0 条 · 新增 0 条）

- **候选全部来自 handoff 的散落定案**——`open-questions.md`「下一阶段」不含 ADR 候选条目，`decisions/_index.md` 的「ADR 候选」表已于 08-19 整节删除，故本次逐份扫 `status: distilled` 的 handoff 取候选，再逐条回主题文档核对，七条均判为**已落地**：
  - **`ADR-0010` 身份主体自建、`account ↔ identity` 一对多，绝不做隐式账号合并**（08-16，→ `contracts/auth.md` §1 §1a §3a §9，来源 `handoffs/2026-08-16b-account-identity-model.md`）。
  - **`ADR-0011` 单账号一条活跃会话：后登录挤下线 + `sid` 精确吊销 + `signin` 回放窗口**（08-16，→ `contracts/auth.md` §4a §5a §7 §10 + `contracts/compliance.md`，来源 `handoffs/2026-08-16c-compliance-contract-and-session-arbitration.md`）。
  - **`ADR-0012` 授予来源 `Source` 的跨边界表示：契约走字符串枚举名，名与 code 双双冻结**（08-14 收口定案，→ `contracts/profile-sync.md` §5 §5a，来源 `handoffs/2026-08-12-grant-source-code-contract.md` · `handoffs/2026-08-14-profile-sync-contract.md`）。
  - **`ADR-0013` `receiptId` 全局唯一 · 永久保留 + 读己所写**（08-22，→ `contracts/purchase.md` §4 §6 §7 + `contracts/profile-sync.md` §8 §9，来源 `handoffs/2026-08-22-entitlement-echo-and-receipt-idempotency.md`）。
  - **`ADR-0014` 透明路径的集合字段名恒为单数，改名一次性切换不设兼容期**（08-17，→ `contracts/profile-sync.md` §5 §5b，来源 `handoffs/2026-08-17-profile-field-naming.md`）。
  - **`ADR-0015` `reasonKey` 形态锁死为 PascalCase + 二级文案键机械变换**（08-16，→ `contracts/auth.md` §10，来源同 `ADR-0011`）。
  - **`ADR-0016` 免鉴权是判据不是名单**（08-16，→ `contracts/envelope.md` §4a，来源同 `ADR-0011` + `handoffs/2026-08-13-auth-endpoint-contract.md`）。
- **一条候选经用户裁决不立**：**refresh 链绝对寿命上限**（08-23，已完整落进 `contracts/auth.md` §5b）——其来源 handoff 的 Notes 段自行裁定「不立 ADR，它是 §5 既有承重条款的一个连带收口，写在契约正文即可」，用户裁定**尊重该自裁**。
- **另三条判为不适合立档**：云端剧本服务撤销（`handoffs/2026-08-11-plot-service-retired.md` 明写「本库不另立 ADR」，已登记在跨库引用表）· 后端需求拆解粒度与签核（落点 `requirements/_index.md` 不在主题文档区，属工艺纪律）· Codex 顶层键去计数化（报文形态一字未变，纯编辑性，且其后缀判据以 `ADR-0014` 的命名通则为前提）。
- **台账**：`decisions/_index.md` 决策表新增七行（按日期降序 / 同日编号降序插入）；修平一处台账 ↔ 文件不一致——`ADR-0008` 的日期格由 `2026-08-22` 改为 `2026-08-22 · 08-23`，与该 ADR 文件头两个定案批次一致。九份既有 ADR 与文件已逐份对账，无孤儿文件、无悬空行。「已对后端构成约束的客户端决定」表**一格未动**（跨库引用表，非候选）。
- **`open-questions.md` 一字未改**：其「下一阶段」不含 ADR 候选条目；`## derive 就绪度` 属 `/assess-derive-readiness` 独占（其中「`ADR-0001` ~ `ADR-0007`（7 份）」的计数与「`purchase.md` §7 被标为 ADR 候选」两处记述现已过时，待下一次全量评估刷新）。
- **未收口的候选登记处依旧**：`contracts/profile-sync.md` §5c 与 `contracts/content-manifest.md` 的「决策(-> ADR)」仍写着「登记于 `decisions/_index.md`」，而候选表已删——主题文档归本技能红线之外，**未改**。

## 2026-08-25（`/batch-analyze-new-ideas draft-0823c` 的后端分片 · 移出 0 条 · 新增 0 条）

- **客户端图鉴族由六本扩为七本**（新增功法图鉴），本库唯一失真处是 `contracts/profile-sync.md` §5 排除清单里那句带计数的「六个 Codex」。**处置是换判据而不是换数字**：改为按 `*Codex` 顶层键后缀恒定覆盖全族，从根上消除下次扩员再漂移，并回链客户端族清单权威（本库不复述客户端的图鉴设计）。
- **字段面零配合，逐条推演已落 handoff**：新顶层键落不透明段 ⇒ 不进白名单 ⇒ 按 §5c 适用面恒等式（受回声约束的 path 集合 ≡ 封闭写入表四行）**结构性地**不受回声校验约束，且 §5c 无需加行 ⇒ 不触发追加字段刚性 ⇒ 打不到 §4 四类拒绝面。§3a 整键替换对顶层键集合本就开放，存储形态无依赖。**报文形态一字未变，不 bump URL 主版本 / `info.version`。**
- **一条非零义务如实记录**：客户端 bump `schemaVersion` 后，新值须进 `envelope.md` §7e 兼容矩阵，否则该版本的全量 push 被 `sync.payload_schema_unsupported` 拒。这是**每次 bump 都存在的既有机械义务**、由 §7e 通则唯一承接、且矩阵落 `operations/` 而栈未定当前空置 ⇒ 记进 handoff 不进契约正文（复述即制造第二权威）。
- **`contracts/_index.md` 不动**（契约面仍六份）；`cross-boundary.md`「对账基线」加一条、「待承接」保持空——同批落笔完毕，先加后删是净零。**本次不建 answer log。**

## 2026-08-23d（`/write-adr backend` · 批量运行的后端分片 · 两条候选固化 · 移出 0 条 · 新增 0 条）

- **`ADR-0008` 后端写入路径在上行侧只接受回声，不等即整批拒绝**（日期 08-22 本体 / 08-23 通则化，→ `contracts/profile-sync.md` §5c，来源 `handoffs/2026-08-22-entitlement-echo-and-receipt-idempotency.md` · `handoffs/2026-08-23c-echo-validation-scope.md`）。
- **`ADR-0009` flags 规则集不可变版本化：`flagsVersion` 严格单调 + 同版本结果恒定**（08-23，→ `contracts/content-manifest.md`「服务端保证」B 组 + `operations/_index.md`，来源 `handoffs/2026-08-23b-flags-version-monotonic.md`）。两条候选均逐条回主题文档核对，判为「已落地」。
- **台账**：`decisions/_index.md` 决策表新增两行（最新置顶）；顺带修平一处失真——「已对后端构成约束的客户端决定」表的抬头原写「后端尚未产出自己的 ADR」，与九份已 Accepted 的事实相反，改为不含计数的中性表述。该表**一格未动**（跨库引用表，非候选）。
- **`open-questions.md` 一字未改**：其「下一阶段」不含 ADR 候选条目，`## derive 就绪度` 属 `/assess-derive-readiness` 独占（其中「`decisions/_index.md` 两处失真」的记述现已过时，待下一次全量评估刷新）。
- **未收口的候选登记处**：`contracts/profile-sync.md` §5c 与 `contracts/content-manifest.md` 的「决策(-> ADR)」仍写着「登记于 `decisions/_index.md`」，而候选表已于 08-19 整节删除 —— 主题文档归本技能红线之外，**未改**，留待 `/analyze-new-ideas` 或用户处置。

## 2026-08-23c（`/analyze-new-ideas` 跨库 · 三份草稿同批提炼 · 移出 4 条 · 新增 0 条）

- **本库欠对侧的三条跨边界条目一次性全部落笔，三处成对采纳均完成。** 这是本库自 08-16 以来跨边界台账首次归零（反向方向仍欠 `compliance.md` 六端点报文字段表）。
- **答结 1 · 回声校验的适用面与比较口径**（`01-contracts.md`）→ `contracts/profile-sync.md` §5c 新增三节：**适用面写成一条恒等式**（受约束 path ≡ 后端写入字段表行集合 ⇒ 面结构性封闭、扩表自动连带、无需第二份清单）· **类型感知的语义相等**比较口径表（整数按数值 · hex 逐字 · **RFC 3339 按时刻** · **对象数组有序逐元素**）· 栈中立验收断言五条；并补一条连带刚性「受约束顶层键内追加字段 = 两侧同批」，`envelope.md` §8 留指路。**两项此前是「采纳推荐 — 待复核」的比较口径，本次提炼前已由用户逐条确认**（均维持推荐）。上游草稿登记的「§4 拒绝清单两类变三类」计数有误，实际为四类、契约现文已正确。→ `answer-logs/log-echo-validation-scope.md`
- **答结 2 · flags「回滚即前滚」的对位条款**（`content-manifest.md` Open questions）→ 把「服务端保证（三条，仅此三条）」**重构为 A 组 overlay 分发 / B 组 flags 通道**两组，`contentVersion` 严格单调那条同批**上提**进 A 组（位置迁移，内容不变），B 组新增三条：单一全局单调序列 · 严格单调 + 回滚即以历史规则内容发布更大版本 · **同一 `(flagsVersion, 账号)` 结果恒定**。附三个失效来源的堵法与「缓存层若引入则缓存键含版本」。**新增 ADR 候选④**（不并进候选①：前滚零成本的理由不同源）。→ `answer-logs/log-flags-version-monotonic.md`
- **答结 3 · flags 改动的审计留痕**（`04` 分片的一小问）→ 在本题定案：四项最低要求（操作者 · RFC 3339 UTC · **`derivedFrom` 来源版本** · 变更摘要与生效范围）+ O1–O7 落 `operations/_index.md`，并同批改写发布流程 ⑤（原写「秒关 / 灰度改数据源即可」，正是「同版本内容漂移」的来源）。`04` 该条目其余部分（规则存在哪 / 由谁改 / 是否引入缓存层）仍开放。
- **答结 4 · `auth.md` §5 静默续期的闸门收口** → `contracts/auth.md` **新增 §5b**：refresh 链绝对寿命上限（`signin` 锚定 · rotation 永不顺延 · 有效性 = `min(滑动, 绝对)` · 初值 60 天）· 到期复用 `auth.session_revoked` + 新 `reasonKey` `SessionExpired`（**不新增错误码**，refresh 错误面仍两条）· `refreshExpiresAtUtc` 收紧为 `min(...)` · 软信号 `reauthRecommended`（服务端算好的可选 body 布尔，**不得是时间戳**，提前量 3 天）。连带：滑动续期的承诺收窄为「不因**闲置**而被动重登」。→ `answer-logs/log-refresh-lifetime-cap.md`
- **横切收口（不是问题条目）**：契约正文里写死的封闭计数一律改为不带数目的回链——`envelope.md` §6 台账的 `reasonKey` 条数 · `auth.md` §8 §9 的「三值见 §10」 · `content-manifest.md` 的「三条，仅此三条」。计数是会漂移的副本。客户端同形写法同批处理。
- **对侧库改动（跨库运行）**：`game-design-documents` 侧落了 refresh 收口的客户端对位（二级文案键 + 软信号反应形态）与 flags 单调闸的补齐（应答体版本也过闸）。逐条见该库 `open-questions/update-log.md` 与 `answer-logs/log-refresh-cap-and-flags-gate.md`。
- **零改动面**：`## derive 就绪度` 小节（归 `/assess-derive-readiness`）· `decisions/`（ADR 候选④只登记在契约的「决策(-> ADR)」，立档归 `/write-adr`）· `contracts/compliance.md` · `contracts/purchase.md`（§5 判据前一批已在位）。

## 2026-08-23（台账失真修正 · 用户当场授权 · 移出 0 条 · 新增 0 条）

- **失真**：`inbox/solution-draft-echo-validation-scope.md` 的 frontmatter 为 `status: awaiting-review`，而其正文明写「仍需用户决定 → 已全部裁决（2026-08-22 · 批量评审）」，本库五处台账（本文件的索引 `open-questions.md` L28 / L94 / L118 · `cross-boundary.md` · `01-contracts.md`）与 `inbox/_index.md` 说明列均已按 `decided` 陈述 —— **失真在 frontmatter，不在台账**。同库另两份「批量评审全部裁决」的草稿（`refresh-lifetime-cap` · `flags-version-monotonic`）均标 `decided`，本稿是漏改。
- **修正方向（用户裁定）**：草稿 `status` 改 `decided` 并补 `reviewed` 字段；`inbox/_index.md` status 列同改。
- **同批补注的一处此前无痕迹的实情**：三项裁决中**前两项比较口径（`createdAtUtc` 按时刻 · `identities` 有序逐元素）系 `[采纳推荐 — 待复核]`** —— 按 `.claude/rules/batch-orchestration.md` 铁律①，采纳推荐不等于用户拍板。原五处台账一律写作「一次提炼即关闭」，会让下一次 `/analyze-new-ideas backend` 径直落笔这两项口径。五处**逐处补上「提炼前须先由用户确认」**。第三项（受约束键内追加字段 = 两侧同批）与 `counterpart` 同项同裁，无待复核。
- **零改动面**：全部主题文档 · `contracts/**` · 四个分片的问题条目本体 · `answer-logs/` · `## derive 就绪度` 小节。客户端库**一字未动**——经核对，`game-design-documents/open-questions.md` 与 `open-questions/cross-boundary.md` 均未称该草稿 `decided`，两处只写「成对采纳尚未完成」，与事实一致。
- **仍未变的事实**：成对采纳尚未完成（客户端半已落 `handoffs/2026-08-22-echo-validation-scope-client-half.md`，本库半未落），`contracts/profile-sync.md` 仍为 partial。

## 2026-08-22b（`/analyze-new-ideas backend` · 回声校验与收据幂等承接 · 移出 0 条 · 新增 1 条）

- **来源**：`inbox/solution-draft-bundle-grant-ordinal-authority.md`（`status: decided`，三项取向 2026-08-19 全部取 A）→ `handoffs/2026-08-22-entitlement-echo-and-receipt-idempotency.md`。它是客户端 08-19 定案（`BundleGrantOrdinal` 施加权收归后端唯一 `+1`）的后端那一半；对侧已单独落笔，**成对采纳的硬要求由此满足**。
- **移出 0 条 —— 本次不建 answer log。** 本库四个分片与 `cross-boundary.md` 此前均无对应条目：该问题原本登记在**客户端库**的待答清单上（`05-service-contracts.md`），并已随对侧提炼移出（见 `game-design-documents/answer-logs/log-bundle-grant-ordinal-authority.md`）。本库这一侧是**承接落笔**，不是答结自己的待答项。
- **新增待答 1 条**（`01-contracts.md`）：**回声校验的适用面与非整数路径的比较口径**。`/accountInfo` 是「客户端整键替换覆写后端写入字段」的第二处同形，其受约束路径清单与比较口径（时间串按时刻还是按字面 · 数组按序还是按集合 · 是否按字节）未定，**选错会让正常客户端被整批拒绝 = 丢玩家进度**。故 `profile-sync.md` §5c 同批写死一条底线：**落笔之前不得按字节相等实现**。承接它的 `inbox/solution-draft-echo-validation-scope.md` 已 `decided`，走一次 `/analyze-new-ideas` 即关闭。
- **契约落笔面**（详见 handoff）：`profile-sync.md` §4（拒绝面四类 + 判定顺序 + 不消耗 revision）· §5（白名单补 `/entitlement/bundleRedeemedOrdinal`，**封闭写入表一格未动**，并把它记为「够格进表」判据的第三个反例）· **新增 §5c 回声校验**（封闭表的首个报文层执行点）· §7a（与 §5c 的所有权判据边界）· §8（只读副本受读己所写约束）· §9（`receiptId` 不同轴的旁注）；`purchase.md` §3（`platform` 收敛为三条具名渠道）· §4 · §5（判据）· §6（保证 3 升格 + 新增 5–7）· **新增 §7 收据幂等窗口**；`envelope.md` §6 台账（`sync.conflict` 的 `detail` 补 `field` 分支，**不新增 `code`**）。
- **`06-platform-stack.md` 两处新增 + 一处升级**：支付渠道由「可推后」升为 **MVP 内必答**（渠道本身已定三家，待落的是逐渠道接入面）· 读己所写对拓扑与读路径的约束（**本库唯一一条对读路径的实现约束**，选型时不满足即出局）· `receiptId` 幂等记录的存储与冷存归档。
- **`cross-boundary.md`「待承接」仍为空**，只在「对账基线」补一条已承接记录。**未动 `## derive 就绪度`**（`/assess-derive-readiness` 独占）——但可预期它下次评估时会变：`purchase.md` 的 `receipt` 形态卡点由「等渠道选型」变为「等逐渠道接入面」。

## 2026-08-22（`/summarize-open-questions backend` · 全库对账 · 移出 0 条 · 新增 1 条）

- **范围**：本库全部主题目录（`vision/` · `contracts/**` · `systems/` · `operations/`）+ `decisions/` + `handoffs/`（14 份**全为 `distilled`**，无 `raw` / `triaged` 待采集面）+ 四个分片 + `cross-boundary.md`。
- **移出 0 条 —— 本次不建 answer log。** 四个分片的全部条目逐条回主题文档核对，无一条在 `## 决策` / ADR 里已有定论：`01` 三条（`refresh` 限流 · 合规域端点错误码 · 机检断言承载位置）、`02` 四条、`04` 五条、`06` 十一条**全部仍开放**。08-19 的 `/write-adr` 与 08-20 的就绪度评估均未产生新定案（前者只搬运既有定案立档、后者只评估），故 08-17 之后本库无答结面。
- **新增待答 1 条**（`02-account-compliance.md`，作「风控与滥用面」的从属项）：**风控三档处置向玩家的可见粒度**。它此前**同时散在 `contracts/auth.md` 与 `contracts/compliance.md` 的 `## Open questions` 里、两处都注明「归 `02`」，但 `02` 分片零对应条目**——即两处权威文档都以为清单接住了，而清单从未收到。两处去重合并为一条。
  **列为从属项而非独立条目**：它的前提就是母条目（三档处置的判据不定，无从判断要不要分档展示），且两处原文都明写**不阻塞**（新增 `reasonKey` 不要求客户端同批发版，`envelope.md` §5b）。
- **跨库对账：两侧均无「一侧已定案、另一侧零承载」的缺口，故未在客户端库补登任何承接项。** 逐条核过：`envelope.md`「跨库待办」的五点（`Retry-After` 尊重 · `X-Flags-Version` 读取点 · 错误码映射表落点 · `Upgrade` 类非阻塞处置 · `HttpProfileBackend` 版本字段搬 HTTP 头）**对侧已落笔**（`game-design-documents/handoffs/2026-08-11b-contract-boundary-and-flags-client-side.md` → `systems/services/content-service.md`、`sync-service.md`）· `auth.md` 的 refresh token 客户端持有形态与 `compliance.md` 的 `ComplianceManager` 覆盖面切分**均已登记在对侧自己的清单上**（后者在对侧 `cross-boundary.md` 的「待承接」），本库不催办。本库 `cross-boundary.md` 的「待承接」仍为空，**一字未改**。
- **零改动面**：`01` · `04` · `06` 三个分片 · `cross-boundary.md` · 全部主题文档 · `answer-logs/`。索引只改「最近更新」一行。
- **未动 `## derive 就绪度`**（`/assess-derive-readiness` 独占）。其中「ADR 候选未 Accepted」类表述已由 08-20 的全量评估刷新，无残留。
- **两处主题文档的陈述失真已修正（用户当场授权，超出本技能常规范围）** —— 两处都是纯陈述失真、不含任何设计裁决：
  - `systems/_index.md`「现状」段：「协议契约**四份**已成文」→ **六份**，并补列 `purchase.md` · `compliance.md`。08-20 的就绪度评估已点名此处。
  - `operations/_index.md` 的 `observability.md` 行：同步正确性探针由**两条**改为**三条**（补 `sync.revision_ahead` 具名与**复算不一致率**），并补一条**透明路径缺失**告警口径。原文与 `06-platform-stack.md`、`contracts/profile-sync.md` §5 §7a 的要求不一致——漏掉的那条正是「后端不拒绝、只记账」的白名单漂移的**唯一可见面**，缺它则该告警在唯一的运维落点上无处挂靠。

## 2026-08-19（`/write-adr backend` · 七条 ADR 候选全部固化 · 移出 0 条 · 新增 0 条）

- **本库首批 ADR 落笔：`ADR-0001` ~ `ADR-0007`，全部 `Accepted`。** 七条候选逐条回主题文档核对，全部判为「已落地」（每条都能在契约正文里找到同一措辞的定案），无一条查无实据或与文档矛盾。
  - `ADR-0001` 内容寻址 + `contentVersion` 严格单调（08-11，→ `contracts/content-manifest.md`）
  - `ADR-0002` flags 第三层只覆盖 `ContentEnabled`（08-11，同上）
  - `ADR-0003` 契约表达形式 = OpenAPI 3.1 单点、不共享 DTO（08-11，→ `contracts/envelope.md` §1）
  - `ADR-0004` auth 域幂等 = sync 域幂等（08-13，→ `contracts/auth.md` §4 §4a）
  - `ADR-0005` 防作弊边界：可复算 `roll`、不复算阈值、仅记账不拒绝（08-14，→ `contracts/profile-sync.md` §7 §7a）
  - `ADR-0006` 账号级掷骰随机源 = 契约定义的 SplitMix64（08-14，→ `contracts/profile-sync.md` §6 §6a）
  - `ADR-0007` 购买写入只由 verify 承担（08-16，→ `contracts/purchase.md` §2）
- **`decisions/_index.md` 的「ADR 候选」整节删除**（过渡形态，表空即整节移除）。「已对后端构成约束的客户端决定」表**一格未动**（跨库引用表，非候选）。
- **`open-questions.md` 一字未改**：其「下一阶段」不含 ADR 候选条目（候选全在 `decisions/_index.md` 的候选表里），`## derive 就绪度` 属 `/assess-derive-readiness` 独占。就绪度里「ADR 候选未 Accepted」的表述现已过时，待下一次全量评估刷新。
- **主题文档零改动**（本技能只搬运立档，不改设计）。

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
