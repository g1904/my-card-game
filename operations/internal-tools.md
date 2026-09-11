# 内部运营工具面与内部人员身份

> 「人坐在什么上面做处置」这一面的权威落点。它与本目录其余文档的区别是**谁在用**——其余记的是系统自己怎么跑（定时任务、探针、发布流水线），本文件记的是内部人员通过什么身份、什么接入面、什么动作去处置。
> 处置动作本身的**语义**权威仍在别处：昵称判定链与存量扫描在 `systems/account.md`，词表分级与处置阶梯在 `operations/moderation.md`，风控事件与阈值同上。本文件不复述它们。
> 四张新表的**承重列与事务边界**在 `systems/account.md`（写入面与 `account` 域同事务，故随该域登记），本文件只记工具面形态——同 `receipt_idem` 的承重列在 `systems/profile-store.md`、运维形态在 `operations/purchase-ops.md` 的分工。

## 内部人员身份：本库自己的 `operator_id`，与 `account` 完全分离

内部人员**不是 `account`**。两套身份完全分离，理由逐条来自既有约束：

- `account` 是**合规删除权的对象**——注销执行按 `account_id` 逐表硬删。把内部人员挂进 `account`，一次误判的注销会把复核员本身删掉，且 `deletion_audit` / `nickname_review` 的外键含义当场混淆。
- `session` 上有 `UNIQUE (account_id) WHERE revoked_at_utc IS NULL`（单账号活跃会话上限 1）。这条不变式对玩家是刻意的，对内部人员是错的——一人两台机器办公即撞索引。
- `identity` 的渠道取值域**封闭为三条登录渠道**，没有「企业身份」这一档；硬塞会污染 `contracts/auth.md` §3a 的渠道语义。
- `account` 行是全库唯一的并发单元，玩家热路径上的行锁与内部动作无关。

**`operator_id` 是本库分配的稳定内部键，不是外部身份源的登录名或 subject。** 这与玩家侧逐字同构（`account_id` 是内部键、`identity(channel, channel_user_id)` 是外部映射），理由也同构：外部身份源可换、登录名会变（改名、离职后复用），而 `operator_id` 是租约归属键与审计外键，**必须永久稳定**。把登录名直接写进 `claimed_by`，一次改名就让历史审计指向一个不存在的人。

- 形态：`op_` 前缀 + 不可枚举的服务端生成串。`operator_id` 与 `accountId` 是**两个永不相交的命名空间**，前缀使它们在日志里一眼可分；本面不依赖 `accountId` 的取值形态。
- `credential_hash` 存 SHA-256，**明文凭据绝不落库**（同 `ticket_hash` 存哈希、`identifier_mac` 存 HMAC 的既有纪律）。
- **停用而非删除**：`disabled_at_utc` 非空即失效。删行会让 `claimed_by` / `operator_audit` 的外键悬空，而审计的价值恰在于人走了记录还在（同 `account` 墓碑行的取向）。

**`operator_id` 是全库「哪个人做了这件事」的唯一标识。** 除 `nickname_review.claimed_by` 外，本库另有三处写下了「操作者」却无取值域，它们与 `claimed_by` 是同一个空洞、同一个答案：

| 处 | 权威 |
|---|---|
| flags 规则集留痕的 `publishedBy` · 内容发布留痕八字段的 `publishedBy` | `operations/content-delivery-ops.md`（A1 / A4 · 留痕八字段） |
| 词表发布 · 时段规则集的 `published_by` | `operations/moderation.md` · `operations/compliance-ops.md` |
| `config_knob` 的更新者 · KMS 解包事件审计的「谁」 | `operations/environments.md` |

**凡本库记录「哪个人做了这件事」，一律记 `operator_id`。** 各处的既有列保留不动（就地可读是它的价值），本文件只定它们的取值域。

## 认证：一枚长期内部凭据，凭据即身份

首版使用人群 = **仅维护者本人**，沿用「当前单人维护」这条库内既有事实（`operations/content-delivery-ops.md` A4）。据此：

- 请求头 `Authorization: Bearer <operator_id>.<secret>`；服务端按 `operator_id` 取行，比对 `SHA-256(secret) = credential_hash`，并断言 `disabled_at_utc IS NULL`。
- **不签发会话、不做 rotation、不复制 refresh 那套机制。** 判据是调用形状：内部面是每天个位数的人工动作，而会话机制解决的是「高频调用不该反复出示长期凭据」——这个前提在此不成立。为一个不存在的问题复制一套 `session` / `generation` / 宽限回放，要付一整套实现与运维成本。
- **凭据轮换 = 写一行新 `operator` + 停用旧行**（或原地换 `credential_hash`）。节奏沿用密钥轮换的既有取向：例行 90 天 + 疑似泄漏立即换。
- **限流**：内部面面向受控来源，不进 fail-open / fail-closed 那套分层。唯一需要计数的是**凭据校验失败**，超阈值即告警。

**企业 IdP（OIDC / 企业微信 / 飞书 / 云厂商 IAM）留位不启用**，形态即 `operator_identity` 表。**启用触发条件（满足其一）：内部人员超过一人，或出现非工程岗（运营 / 客服）复核员。** 启用是纯增量——新增 `operator_identity` 行，`operator_id` 与全部历史 `claimed_by` / `publishedBy` 一字不变。这正是把 `operator_id` 定为内部键换来的东西。

**托管自成一类。** 内部访问凭据是继会话密钥 / 内容签名密钥 / 渠道验票凭据 / 外接能力凭据之后的第五类托管条目，**不与既有各类钥匙共用托管配置**（轮换节奏互不相同，共用会让最慢的那条绑架其余）。维度是 **operator × 环境**；本地 feature 环境用开发专用 operator，与线上 `operator_id` 空间隔离、永不共用（同开发专用 `kid` 的纪律）。指路见 `operations/environments.md`「密钥保管」。

## 接入面：`/internal/` 前缀，不属于契约面

内部端点**不跨客户端边界**，因此它不是契约的对象：

| 判据 | 结论 |
|---|---|
| `contracts/envelope.md` §3 的端点全集表是机检断言③的输入（端点集 ⇔ 六份契约正文，双向） | 内部端点在六份客户端契约中永不出现 ⇒ **不进 §3 表、不进 `openapi.yaml`、不进 §6 错误码台账**。一旦进表，断言③当场红灯 |
| 客户端与后端唯一的耦合点是协议，`contracts/` 是它的单一事实来源 | 内部面不跨这条边界 ⇒ 契约的稳定性承诺（`/v1/` 主版本、并存两版）对它无意义——它与后端同一制品同批发布 |
| `contracts/envelope.md` §4a 无鉴权例外的判据主语是「调用它的**玩家**此刻不可能持有 access token」 | 内部面没有玩家 ⇒ 该判据既不适用也无需扩写。**内部端点一律必带凭据，无例外** |

因此：

- **路径前缀 `/internal/`，不带 `/v1/`。** 该前缀被保留，**永不出现在 `/v1/` 下、永不进端点全集表**——`envelope.md` §3 表下已留一句同向的非规范性说明，因为踩中 P-3 的读者在那里。
- **同一制品、同一进程、独立监听。** 不拆成第四个部署单元：处置动作必须与 `account` 域写入同事务，拆进程即跨进程写同一张表，白白多一个故障域；且与「三处环境跑同一个 artifact」相抵。
- **暴露形态：仅 VPC 内可达，经堡垒机 / VPN 访问**，内部监听不对公网暴露。纵深理由：应用凭据出 bug 时网络层仍成立。接入通道（堡垒机实例或 VPN）是内部处置台可用的前置条件，随发布前置清单一并过闸（`operations/deployment.md`）。
- **复用序列化惯例，不复用契约机制。** JSON / lowerCamelCase / RFC 3339 `…AtUtc` / 不下发 `null` / 忽略未知字段照旧（零成本，且让日志与既有脱敏管道一致）；`X-Request-Id` 照带，把内部动作接进两侧日志。**但错误只需人读**——不引入 `code` / `class` / `detail` 三段与台账，`code` 的存在理由是「客户端据它分处置路径」，而内部面的读者是人。

**首版端点最小集（6 条）：**

| `METHOD 路径` | 用途 |
|---|---|
| `GET /internal/nickname-review` | 列待办计数与我持有租约的条目 |
| `POST /internal/nickname-review/claim` | 领一批租约（body: `batch`） |
| `POST /internal/nickname-review/{reviewId}/decide` | 判定（body: `decision`） |
| `GET /internal/tickets` | 列在办工单 |
| `POST /internal/tickets/{ticketId}/claim` | 领工单租约 |
| `POST /internal/tickets/{ticketId}/decide` | 处置（body: `decision` · `baseAccountStatus` · `note`） |

这一组是「复核链路端到端可用」的最小充分集：少任一条，某个已落笔的状态转移就没有触发面。

**明确不提供任意查询面**：没有「按任意条件查 `account` / `profile` / `identity`」的端点，没有任意 SQL 面。判据——端点集与已定的处置动作**一一对应且封闭**；一个通用查询页会当场绕过 `identity` 与 `profile` 的分表分权限，而那正是「敏感字段零出现」这条纪律的承载方式。

## 界面档次：CLI，控制台只作调用方

人机接口 = CLI / 脚本；控制台若日后引入，**只作内部端点的调用方**——不动存储、不动纪律、不需迁移（同 flags 发布侧 A3′ 的既有取向）。

- **不做 Web 页。** 理由不是省事：单人维护使 Web 页的收益（非工程岗可用）为零，而它的成本（一套前端 + 一套内部会话与 CSRF 面）非零。控制台的启用触发条件与企业 IdP 同一条——两者本就同时需要。
- **不给人可写库凭据去处置。** 人直接 `UPDATE nickname_review` 会绕过条件 `UPDATE` 取租约，「恰好被一人领到」与「迟到提交被拒」两条保证在纸面成立而线上不成立；且 `claimed_by` 仍然没有来源。
- **人类身份对业务表恒只有 `SELECT`，一切写入经服务端受控面。** 这是全库通则，不限于 flags 规则集表——「不存在原地编辑路径」若只体现在应用层 API、而运维仍持可写库凭据，纪律就停在评审级。适用范围的原始陈述见 `operations/content-delivery-ops.md` A3。

## 昵称复核台：`claimed_by` 的机械形态

承接 `operations/moderation.md` 的领取伪码，只补它缺的那一格：

| 项 | 定 |
|---|---|
| `claimed_by` 类型 | `text`（同 `review_state` 存 `text` 不用数据库 enum 的纪律） |
| 取值域 | `operator` 表中 `disabled_at_utc IS NULL` 的行的 `operator_id`，**加外键 `REFERENCES operator(operator_id)`** —— 把「`claimed_by` 是一个真实存在的内部人员」落成数据库不变式而非应用层约定。`operator` 只停用不删行 ⇒ 外键不阻碍任何既有路径；`nickname_review` 终态行按批 `DELETE` 的方向是 review → operator，同样不受影响 |
| 来源 | 服务端从本次内部请求**已认证的凭据**解析得出。**绝不接受请求体传入 `claimedBy` / `operatorId`**（同 `eventId` 由服务端生成、不接受调用方提供的纪律）。允许传入即任何持凭据者都能冒名判定 |
| 伪码里的 `:reviewer` | 即上述 `operator_id`；领取的 `SET` 与判定的 `WHERE` 恒为同一个值 |

**租约回收时一并置空 `claimed_by` 与 `claim_expires_at_utc`。** 留着旧 `claimed_by` 会让「谁在办」这一列在 `Pending` 行上说谎，而它是审计要读的列。（判定被拒不依赖这一点——`state` 已变即命中 0 行。）

**判定的落地形态：**

- `decision` 取值 **`Violation` / `Clean`**（PascalCase 字符串，存 `text`，同 `kind` / `severity` 清单可增量的纪律）。
- `enqueue_reason` 取值：**`WordlistReview`**（复核级命中）· **`Bypassed`**（存量扫描检出的绕过写入）· **`ThirdPartyReview`**（第三方审核适配器启用后）· **`Rescan`**（重扫判疑）。
- **判 `Violation` 的一次事务内**：`nickname_review` 转终态 → 一条 `NicknameViolation` 落 `risk_event` → 按处置阶梯置「须改名」档（更新 `nickname_scan.review_state`）。**云端昵称一字不变**——后端绝不改写或置空昵称，处置只落 `status` 侧。
- **判 `Clean` 的一次事务内**：`nickname_review` 转终态 → 更新 `nickname_scan.review_state` 与 `reviewed_wordlist_version` 为当前版本（使定期重扫不再重复判疑）。**不产事件。**
- **这两次 `risk_event` 写入走同事务直写，不走旁路缓冲。** 被禁的是**裁决**发生在玩家同步热路径上；内部面本就是人工裁决面，且这两个 `kind` 属确定性检出、没有累计冗余可丢——与既有的三类同事务例外同一条判据。
- **判定结果回灌词表仍走发布动作，复核台不设旁路**（三条来源通道收敛到同一次发布动作）。**不新增候选词条表**：`Decided` 行保留 180 天，下一次词表发布时按 `decided_at_utc` 取一批即可。

**不分派（不按渠道 / 语言）。** 昵称是单一字段、词表是统一的一份，语言维度没有承载对象；渠道维度需要一张路由表加一个「谁负责哪一片」的组织事实，而首版人群是一人。`SKIP LOCKED` 的批量领取本就是无分派的公平队列。日后需要时形态是纯增量：给 `nickname_review` 加一列 `assigned_group`、在领取语句的 `WHERE` 加一个等值条件，不动任何不变式。

## 风控工单：本库一张 `ops_ticket`，与复核台共用同一套身份与同一个面

落点判据：

- **不进外部工单系统。** 处置动作必须与 `account.status` 写入**同一次事务**（含会话吊销），跨系统即让「工单已关、`status` 未改」成为可达状态；且与「明确不引入新存储系统」的一贯取向相抵。
- **不能只靠在 `risk_event` 上按阈值聚合出待办**：那样没有「已看过 / 已驳回」这一态，同一账号会永远浮在待办里。需要一张有状态机的表，其形态判据与 `nickname_review` 逐条相同（体量随待办积压增长 · 按状态取待办 + 按账号点查 · 不分区 · 终态按批 `DELETE`）。

要点：

- **触发事件是软引用的两列，不是外键。** `risk_event` 的主键是 `(occurred_at_utc, event_id)`（分区表唯一索引必须含分区键）⇒ 引用需两列；而分区到期整分区 `DROP` 会让指向它的外键失效或阻塞裁剪 ⇒ **不建外键**。工单可能活得比它的触发事件更久，这是被接受的：`ops_ticket` 自身已记下 `kind` / `severity` / 时间。
- **`UNIQUE (account_id) WHERE state IN ('Open','Claimed')`**：同一账号在办至多一条。命中冲突 ⇒ **更新既有在办条目的触发引用与 `severity` 为最新一次**，不新插行。阈值反复触发会连开多条、让人对同一账号重复判定。
- **领取语义与 `nickname_review` 逐条相同**（条件 `UPDATE` 取租约 · `SKIP LOCKED` 只在选行那一瞬 · 租约回收任务），**共用一条既有的定时任务通道**，不新开。租约超时**另立一个旋钮**，初值 60 分钟：工单判定要读窗口计数，比昵称复核慢，复核的 30 分钟偏紧。
- `decision` 取值 **`Dismiss` / `Restrict` / `Ban`**；`decided_status` 记落定后的 `account.status`（`Dismiss` 时为空）。
- **`note` 是给人读的自由文本**，**不得记入任何个人信息**；它随注销硬删，因此**不作为举证依据**——举证走 `operator_audit`。

**处置的事务边界**（一次事务，与 `account` 域同事务，登记在 `systems/account.md`）：

```
SELECT … FOR UPDATE on account            ← 并发获取恒落 account 行
  ├ 断言 account.status = :baseAccountStatus   ← 不等即拒
  ├ UPDATE account.status = restricted | banned
  ├ 吊销该账号全部会话（revoked_reason = OperatorRevoked）
  ├ UPDATE ops_ticket → state='Decided', decision, decided_status, decided_at_utc
  └ INSERT operator_audit 一条
```

- **`baseAccountStatus` 是必填的乐观前置条件，不是装饰。** 它把契约层的 CAS 手法（`baseRevision`）原样用在最高危的那个动作上：工单是几分钟前领的，期间该账号可能已申请注销（`status → pendingDeletion`）或已被另一次处置改过。不等即拒、`status` 一字不变。**它是唯一一道防线**——不设强制第二人审批（当前单人维护，四眼原则是纯摩擦），而这道防线的成本为零。
- **解除处置走同一个端点**，`decision` 取 `Dismiss` 且带 `baseAccountStatus`；恢复目标沿用既有语义：只改回 `status`，**永不带外改写昵称**（`nicknameChangeRequired` 由云端状态算出，玩家自己改名即清零）。
- **`Restrict` / `Ban` 之外的自动化一步不进**：自动化止于工单、`account.status` 的任何变更须人工确认，这条原样成立；本面只是给「人工确认」这个动作补上它一直缺的那个面。

## 内部动作审计：`operator_audit`

一条 append-only 的内部动作留痕，形态与 `deletion_audit` 同构。

- **`context` 只装内部键与结果，绝不装昵称串、`note` 或任何个人信息。** 这是刻意设计出来的性质而非事后声明：**「这张表含不含个人信息」决定它的保留期与是否进注销删除清单**，而它是可设计的。把可关联到个人的载荷留在 `nickname_review` / `ops_ticket`（180 天 + 注销硬删），审计只留「谁 · 何时 · 对哪个内部对象 · 做了什么 · 结果」。
- ⇒ **保留 3 年、注销执行不删**，与 `deletion_audit` 同判据。存 `account_id` 不破坏这一点——`deletion_audit` 已是先例。注销执行时删掉它，等于在最需要举证的那一刻销毁证据。
- 到期按批 `DELETE`，挂既有周期通道，**不分区**（体量 = 人工动作数，一生几千行量级）。
- `action` 取值随端点集增长：`NicknameReviewDecide` · `TicketDecide` · `WordlistPublish` · `FlagsPublish` · `ContentPublish` · `KnobUpdate` …——它是 `publishedBy` / 「更新者」那几处留痕的**共同落点**，使全库的内部动作有一条可读的时间线，而不是散在五张表的五个列上。既有各表的 `publishedBy` 列保留不动，`operator_audit` 是横向的第二视图，两者由同一次事务同批写入。

## 可见字段范围

「`realName` / `idNumber` 在应答、日志与 `response_snapshot` 中零出现」这条纪律里的「应答」**包含内部端点的应答**，无需新造断言。落地口径：

| 面 | 可见 |
|---|---|
| 复核台条目 | `review_id` · `account_id` · `submitted_nickname` · `wordlist_version` · `enqueue_reason` · `enqueued_at_utc` · `claim_attempts` |
| 工单条目 | `ticket_id` · `account_id` · `kind` · `severity` · `subject` / `expected` / `actual` · 窗口计数 · `app_version` / `content_version` · `account.status` |
| **恒不可见（全库）** | `realName` / `idNumber` · 手机号 / 邮箱（库内本就只有 `identifier_mac`）· `profile` 的 `doc` 内容 · 会话凭据 / `sid` / `tokenId` · `response_snapshot` |

两列之外的一切默认不可见。

- `account_id` 对内部人员可见是必需的（它是处置的对象键），且它不是个人信息——同 `deletion_audit` 注销后仍留它的判据。
- **`device_id` 不呈现**：它只作观测维度、永不参与判定，呈现给人只会诱导按它做判断。

**客服侧的账号查询入口不在本面内。** 它是可见字段面风险最高的一块（一个通用账号查询页是上述纪律最可能的破口），须单独裁决可见字段范围后再开；它将共用 `operator` 身份与 `/internal/` 面。

## 上线时点

**不进「首个真实账号建号之前」那份清单。** 判据是「后置之后再补，是否需要对存量账号做一次追溯动作」——复核台后置只会让 `nickname_review` 积压 `Pending` 条目，补上工具后照常处理，无追溯动作。

**进「首次面向公众发行之前」那份清单**，条目与过闸断言见 `operations/deployment.md`。理由：公开发行后复核级命中与风控阈值触发会持续产生待办，无人能处置即合规敞口；且「人必须在回路里」在没有面的情况下无法兑现。未就绪的处置同两份清单：**推迟上线，不降级放行。**

## 服务端保证

与 `systems/account.md` 的 N / S / C 组、`operations/moderation.md` 的 M 组同体例。

| # | 输入 | 期望 |
|---|---|---|
| I1 | 两个 operator 同时领取工单 | 每条待办**恰好被一个 operator 领到** |
| I2 | operator 租约超时后提交判定 | 命中 0 行、判定被拒；条目不被覆盖 |
| I3 | 工单处置请求带的 `baseAccountStatus` 与库内当前值不等 | 拒绝；`account.status` 一字不变；无任何写入 |
| I4 | 任一内部端点未带凭据，或凭据属 `disabled_at_utc` 非空的 operator | 拒绝；无任何写入；凭据校验失败计数 +1 |
| I5 | 任一内部端点的应答与日志 | `realName` / `idNumber` / 手机号 / 邮箱明文**零出现** |
| I6 | 一次 `Ban` 处置成功返回 | `account.status='banned'` · 该账号全部会话已吊销 · `ops_ticket` 已 `Decided` · 一条 `operator_audit` 已落，四者同事务；杀死进程于其间 ⇒ 四者都未发生 |
| I7 | 昵称复核判 `Violation` | `nickname_review` 终态 · 一条 `NicknameViolation` 落 `risk_event` · `nickname_scan.review_state` 更新，三者同事务；云端昵称一字不变 |
| I8 | 请求体试图传入 `claimedBy` / `operatorId` | 被忽略；租约归属恒取自认证凭据 |
| I9 | 注销执行完成后 | 该 `account_id` 在 `ops_ticket` 中**零行**；`operator_audit` 条目**仍在** |
| I10 | 同一账号连续两次触发同一 `kind` 的升级阈值 | `ops_ticket` 中该账号在办条目恒为 **1** 条，触发引用与 `severity` 更新为最新一次 |

## 数值初值（全部待实测校准，落后端配置）

| 旋钮 | 初值 | 推导所在 |
|---|---|---|
| 工单租约超时 | 60 分钟 | 风控工单一节（工单判定要读窗口计数，比昵称复核慢） |
| 工单终态条目保留期 | 180 天 | 同上（含可关联到个人的行为数据，与复核终态条目同期） |
| 内部动作审计保留期 | 1095 天（3 年） | 内部动作审计一节（与 `deletion_audit` 同期、同判据） |
| 内部凭据校验失败告警阈值 | 不定值 | 认证一节；上线后按实际调用量标定 |

## Open questions

- **告警接收人 / 值班形态**：本面的「凭据校验失败告警」与「工单积压告警」需要一个接收面，而 `operations/observability.md` 通篇只有告警口径、没有接收方。不阻断本面落笔（指标出口已存在），但它是同一族的真空。
- **客服侧的账号查询入口**：见「可见字段范围」末段，可见字段范围须单独裁决。

Source: `handoffs/2026-09-09-internal-ops-tools-and-operator-identity.md`。
