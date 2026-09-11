# 内部运营工具面与内部人员身份

- id: 2026-09-09-internal-ops-tools-and-operator-identity
- date: 2026-09-09
- topic: operations/internal-tools（**新建**）· systems/account · operations/moderation · operations/environments · operations/deployment · operations/content-delivery-ops · operations/compliance-ops · contracts/envelope（§3 表下一句非规范性护栏）
- status: distilled
- distilled-to: `operations/internal-tools.md`、`systems/account.md`、`operations/moderation.md`、`operations/environments.md`、`operations/deployment.md`、`operations/content-delivery-ops.md`、`operations/compliance-ops.md`、`contracts/envelope.md`

## Intent（distilled）

**一句话：** 内部人员用本库自己的 `operator_id` 身份，经 `/internal/` 面（不属于契约面）上的六个端点做昵称复核与风控工单处置——这把 `claimed_by` 这个空洞、以及全库另外三处「操作者」的空洞，用同一个答案一次填上。

### 1. 权威落点：新建 `operations/internal-tools.md`

本面横跨三处既有文档（`moderation.md` 的复核队列 · `account.md` 的承重列与事务边界 · `environments.md` 的凭据托管），塞进其中任一处都会让另两处回链到一个非权威位置。它与 `operations/` 其余文件同类——「系统自己怎么跑」与「人坐在什么上面做处置」是同一册运维形态的两面，不新开分区。

### 2. 内部人员身份：`operator_id`，与 `account` 完全分离

分离的四条理由逐条来自既有约束，不是洁癖：`account` 是合规删除权的对象（误判的注销会删掉复核员本身）· `session` 的「单账号活跃会话上限 1」对内部人员是错的 · `identity` 的渠道取值域封闭为三条登录渠道 · `account` 行是全库唯一的并发单元。

四张新表：`operator` · `operator_identity`（留位不启用）· `ops_ticket` · `operator_audit`。`operator_id` 是本库分配的稳定内部键，与玩家侧 `account_id` ↔ `identity` 的分层逐字同构，理由也同构——外部身份源可换、登录名会变，而它是租约归属键与审计外键，必须永久稳定。

**它一次性填上全库四处「操作者」的取值空洞**：`claimed_by` · `publishedBy`（flags 规则集 / 内容发布 / 词表 / 时段规则集）· `config_knob` 更新者 · KMS 解包事件审计的「谁」。四处是同一个空洞，给内部人员定两套标识没有理由。

### 3. 认证与接入面

- **一枚长期内部凭据，凭据即身份**（`Bearer <operator_id>.<secret>`，比对 SHA-256）。不签发会话、不做 rotation——判据是调用形状：内部面是每天个位数的人工动作，会话机制解决的是「高频调用不该反复出示长期凭据」，这个前提不成立。
- **企业 IdP 与内部 Web 控制台留位不启用**，触发条件写死：**内部人员超过一人，或出现非工程岗复核员**。启用是纯增量，`operator_id` 与全部历史留痕一字不变。
- **`/internal/` 前缀不属于契约面**：内部端点不跨客户端边界 ⇒ 在六份契约正文中永不出现 ⇒ 进 `envelope.md` §3 端点全集表会让机检断言③当场红灯。因此不进 §3 表、不进 `openapi.yaml`、不进 §6 错误码台账；无鉴权例外的判据主语是「玩家」，内部面不够格，**一律必带凭据**。
- **同一制品、同一进程、独立监听**，不拆第四个部署单元（处置须与 `account` 域同事务）。**仅 VPC 内可达，经堡垒机 / VPN**。
- **复用序列化惯例，不复用契约机制**：`code` / `class` / `detail` 三段与台账不引入——`code` 的存在理由是「客户端据它分处置路径」，内部面的读者是人。

### 4. 复核台与工单台

- `claimed_by` 类型 `text`、取值域 = 未停用的 `operator_id`、**加外键**（把「持有租约的是一个真实存在的内部人员」落成数据库不变式）、**来源恒取自已认证凭据，绝不接受请求体传入**。
- **租约回收一并置空 `claimed_by` 与 `claim_expires_at_utc`**（补正而非改语义——迟到提交被拒不依赖它）。
- 工单落 `ops_ticket`，不进外部工单系统：处置必须与 `account.status` 写入同一次事务，跨系统即让「工单已关、`status` 未改」成为可达状态。
- **`baseAccountStatus` 是必填的乐观前置条件**——把契约层的 CAS 手法用在最高危的动作上，防的是「工单几分钟前领的，期间该账号已申请注销或已被另一次处置改过」。**不设第二人审批**（当前单人维护，四眼原则是纯摩擦），故这是唯一一道防线，而它成本为零。
- **`operator_audit` 的 `context` 刻意不含个人信息** ⇒ 保留 3 年、注销执行不删。这是设计出来的性质而非事后声明：「这张表含不含个人信息」决定它的保留期与是否进删除清单，而它是可设计的。

### 5. 界面与上线

首版 **CLI**，控制台日后引入只作调用方。**不给人可写库凭据去处置**——那会绕过条件 `UPDATE` 取租约，让两条已落笔的保证在纸面成立而线上不成立。进「首次面向公众发行之前」那份前置清单（第 4 项），不进「首个真实账号建号之前」那份（后置无追溯动作）。

## Clarifications（interview 产物）

本批的取向项与张力项均已由用户在同日的批量评审中裁决，逐条写回草稿；本次落笔视同用户当面裁决，不再重问。

- **首版内部处置面的使用人群？** → **A：仅维护者本人，沿用「当前单人维护」。** 首版 = `/internal/` + CLI，认证为一枚长期内部凭据，`operator` 表首版一行；企业 IdP 与内部 Web 控制台留位不启用，触发条件写死。
- **内部面的暴露形态？** → **A：仅 VPC 内可达，经堡垒机 / VPN。** 内部监听不对公网暴露；接入通道作为处置台可用的前置条件随发布前置清单一并过闸。
- **`content-delivery-ops.md` A3「人类身份只有 `SELECT`」是否提升为全库通则？** → **是。** 任何人类身份对任何业务表恒只有 `SELECT`，写入一律经服务端受控面；A3 的适用范围随之扩写。
- **`operator_id` 是否同批收口 `publishedBy` / `config_knob` 更新者 / KMS 解包审计的「谁」？** → **同批收口三处。** 对应处随本批一并落笔。
- **租约回收是否一并置空 `claimed_by`？** → **按标准默认采纳，补正照写。** 未作为取向问题出题——租约回收不置空归属键属工程常识默认，无相反取向可选。

## Open questions

- **告警接收人 / 值班形态**：本面的「凭据校验失败告警」与「工单积压告警」需要一个接收面，而 `operations/observability.md` 通篇只有告警口径、没有接收方。不阻断本面落笔，但它是同一族的真空。
- **客服侧的账号查询入口**：本次不设计。它与本面共用 `operator` 身份与 `/internal/` 面，但可见字段范围须单独裁决——一个通用账号查询页是敏感字段纪律最可能的破口。

## Notes / triage

- **ADR 候选两条**（立档归 `/write-adr`，本次不建）：① 内部人员身份与 `account` 完全分离、`operator_id` 为全库唯一内部人员标识；② 内部工具面不属于契约面（`/internal/` 永不进端点全集表）。
- **契约报文零改动**：`envelope.md` §3 端点全集表不加行、§6 台账不加行、`openapi.yaml` 不动。§3 的改动只是表下一句非规范性说明。
- 顺带落笔一处**未在草稿 `targets` 中、但不落即产生矛盾**的改动：`operations/compliance-ops.md`「执行时删什么」表补 `ops_ticket` 硬删与 `operator_audit` 保留两行（该表是注销删除清单的第二权威，只改 `account.md` 一侧会让两份表相抵）。

## 客户端侧影响

**零。** 不改动客户端 ↔ 后端边界的任何语义：报文一字不改、不新增 `code`、`profile` 的 `doc` 不新增字段、端点全集表不加行。三个跨边界客户端成分（`account-service` / `content-service` / `sync-service`）均不受影响，`game-design-documents/` 侧无需任何同步更新。
