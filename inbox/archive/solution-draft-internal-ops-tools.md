---
type: solution-draft
date: 2026-09-09
question: 内部运营工具面的形态 —— 昵称人工复核台与风控工单坐在什么上面，以及 `claimed_by` 所依赖的「内部人员身份」从哪来
source: open-questions/07-internal-tools.md → 「昵称人工复核台的形态」+「风控工单的落点同源」（两条同源，一并推演）
targets: operations/internal-tools.md（**建议新建，本面的权威落点**）· systems/account.md（承重列 + 事务边界）· operations/moderation.md（领取语义的 `:reviewer` 来源 · 处置阶梯的写回面）· operations/environments.md（密钥保管增一类托管条目）· operations/deployment.md（第二份发布前置清单增一项）· operations/content-delivery-ops.md（`publishedBy` 的取值域回链）· contracts/envelope.md（§3 表下一句非规范性护栏，是否入契约面由评审决定）
status: distilled
reviewed: 2026-09-09 —— 批量评审：① 首版使用人群取 A（仅维护者本人，沿用「当前单人维护」）；② 暴露形态取 A（仅 VPC 内可达，经堡垒机 / VPN）；③ `content-delivery-ops.md` A3「人类身份只有 SELECT」提升为全库通则；④ `operator_id` 同批收口 `publishedBy` / `config_knob` 更新者 / KMS 解包审计的「谁」三处；⑤ 租约回收一并置空 `claimed_by` 按标准默认采纳（非取向项）。
distilled-to: handoffs/2026-09-09-internal-ops-tools-and-operator-identity.md
---

# 方案草稿 — 内部运营工具面与内部人员身份

## 问题

`nickname_review` 的表形态、状态机、条件 `UPDATE` 取租约、部分唯一索引、服务端保证 M6–M8 都已落笔，`ADR-0027` 也已定「自动化止于工单、`account.status` 的任何变更须人工确认」。但**人坐在什么上面做这件事，全库零承载**：

1. **昵称人工复核台**：谁复核 · 是否分派 · 界面档次 · **`claimed_by` 的取值从哪来**。最后一条最承重 —— 它是租约归属与「迟到提交被拒」（M7）这条不变式的键，取值域定不下来，领取语义就只在纸面上成立（`ADR-0058` 已明记本决策「不依赖它成立：租约机制对取值域是中立的」，但可用性依赖它）。
2. **风控工单的落点**：工单进哪个系统 · 谁看 · 处置动作经什么面写回 `account.status`。

两条同源（07 分片明写「宜一并裁决，不要各定一套内部身份」），本草稿一并推演。

它不阻断任何已落笔的表形态，但阻断「复核这条链路端到端可用」——而**词表两档分级首版就启用**（`ADR-0055` 只否掉第④级第三方审核适配器），复核级命中首版即会持续产生待办。

## 约束（来自既有设计）

| # | 约束 | 来源 |
|---|---|---|
| K1 | 单库 PostgreSQL · 零消息队列 · 零调度中间件 · 零分布式锁 · 不引入新存储系统 | `systems/_index.md`「明确不引入」· `ADR-0021` |
| K2 | 三处环境跑同一个 artifact，只有配置不同 | `operations/deployment.md`「构建与制品」 |
| K3 | **人机接口 = CLI / 脚本；控制台若日后引入，只作调用方**——不动存储、不动纪律、不需迁移 | `operations/content-delivery-ops.md` A3′（全库唯一一处对「内部界面」的既有表态） |
| K4 | **人类身份对规则集表只有 `SELECT`**；「不存在原地编辑路径」若只体现在应用层 API、而运维仍持可写库凭据，纪律就停在评审级 | `operations/content-delivery-ops.md` A3 |
| K5 | `publishedBy` **必须解析到具名人类身份**，不得是流水线 / 共享服务账号；**不设强制第二人审批——当前单人维护，四眼原则是纯摩擦** | `operations/content-delivery-ops.md` A4 |
| K6 | 端点全集表是**机器读取面**（机检断言③的输入：端点集 ⇔ 六份契约正文，双向）；新增端点须同批改本表 | `contracts/envelope.md` §3 P-3 |
| K7 | 无鉴权例外的判据是「调用它的**玩家**此刻不可能持有 access token」——判据而非名单 | `contracts/envelope.md` §4a |
| K8 | `realName` / `idNumber` 在**应答、日志与 `response_snapshot` 中零出现**；手机号 / 邮箱明文绝不落库落日志 | `operations/deployment.md` 前置清单第 5 项 · `systems/account.md` C6 · `operations/environments.md`「区域与合规」 |
| K9 | 后端**绝不改写或置空**云端昵称，处置只落 `status` 侧；「运营带外改写 profile」已被结构性排除 | `ADR-0026` · `answer-logs/log-nickname-moderation-and-risk-control.md` |
| K10 | `restricted` / `banned` 一律需人工确认；`status` 变更连带吊销全部会话 | `ADR-0027` · `systems/account.md` S5 |
| K11 | 活凭据绝不明文落库（`ticket_hash` 存 SHA-256 · `identifier_mac` 存 HMAC · refresh 靠重算） | `systems/account.md`「存储形态：承重列」 |
| K12 | 词表 / 日历的人工输入**收敛到同一次发布动作，不存在旁路写入** | `operations/moderation.md` · `operations/compliance-ops.md` |
| K13 | 留位而不启用的能力，须**写死触发条件**——没有触发条件的留位会变成没有人会再想起来的空位 | `ADR-0055` / `operations/moderation.md` |

---

## 建议方案

### 1. 本面的权威落点：新建 `operations/internal-tools.md`

`[既有推演]` 07 分片抬头自陈「权威落点尚未确定」。本面横跨三处既有文档（`moderation.md` 的复核队列 · `account.md` 的承重列与事务边界 · `environments.md` 的凭据托管），塞进其中任一处都会让另两处回链到一个非权威位置。建议新建一份主题文档承载：内部身份 · 内部接入面 · 复核台 · 工单台 · 可见字段范围 · 服务端保证 I*。

它与 `operations/` 其余文件同类（「系统自己怎么跑」→「人坐在什么上面做处置」是同一册运维形态的两面），不新开分区。

### 2. 内部人员身份：本库自己的 `operator_id`，与 `account` 完全分离

`[既有推演]` **两套身份必须完全分离**，理由逐条可从既有约束推出，不是洁癖：

- `account` 是**合规删除权的对象**：注销执行按 `account_id` 逐表硬删。内部人员挂进 `account` 会使一次误判的注销把复核员本身删掉，且 `deletion_audit` / `nickname_review` 的外键含义当场混淆。
- `session` 上有 `UNIQUE (account_id) WHERE revoked_at_utc IS NULL`（**单账号活跃会话上限 1**）。这条不变式对玩家是刻意的，对内部人员是错的（一人两台机器办公即撞索引）。
- `identity` 的渠道取值域**封闭为三条登录渠道**（微信 / Apple / Google），没有「企业身份」这一档；硬塞会污染 `contracts/auth.md` §3a 的渠道语义。
- `account` 行是全库唯一的并发单元，玩家热路径的行锁与内部动作无关。

**形态（与玩家侧同构，刻意的）：**

```
operator          (operator_id PK, display_name, role, credential_hash,
                   created_at_utc, disabled_at_utc,
                   索引 (disabled_at_utc))

operator_identity (operator_id FK, issuer, subject, bound_at_utc,   ← 留位不启用，见 §3
                   UNIQUE (issuer, subject),
                   UNIQUE (operator_id, issuer))
```

- **`operator_id` 是本库分配的稳定内部键，不是外部身份源的登录名 / subject。** 这一手法与玩家侧逐字同构：`account_id` 是内部键、`identity(channel, channel_user_id)` 是外部映射。理由也同构 —— 外部身份源可换（换 IdP / 换云厂商）、登录名会变（改名、离职后复用），而 `claimed_by` 是租约归属键与审计外键，**必须永久稳定**。直接把登录名写进 `claimed_by`，一次改名就让历史审计指向一个不存在的人。
- **形态建议 `op_` 前缀 + 不可枚举的服务端生成串**；`operator_id` 与 `accountId` 是**两个永不相交的命名空间**，前缀使它们在日志里一眼可分。`accountId` 形态本身仍在发布前置清单第 3 项待定稿，本方案**不依赖**它的取值形态。
- **`credential_hash` 存 SHA-256，明文凭据绝不落库**（K11 的第三个实例，同 `ticket_hash` / `identifier_mac`）。
- **停用而非删除**：`disabled_at_utc` 非空即失效。删行会让 `claimed_by` / `operator_audit` 的外键悬空，而审计的价值恰在于人走了记录还在（同 `account` 墓碑行的取向）。

**`operator_id` 一次性填上全库三处「操作者」的取值空洞。** 除 `claimed_by` 外，本库已有三处写下了「操作者」却无取值域：`publishedBy`（flags 规则集留痕四项 + 内容发布留痕八字段 + 词表发布 + 时段规则集，K5 还要求它「必须解析到具名人类身份」）、`config_knob` 的「更新者」、KMS 解包事件审计的「谁」。它们与 `claimed_by` 是**同一个空洞**；给内部人员定两套标识毫无理由。建议一次收口：**凡本库记录「哪个人做了这件事」，一律记 `operator_id`。**

### 3. 认证：首版一枚长期内部凭据；企业 IdP 留位不启用（带触发条件）

`[既有推演]` `[通行做法]` K5 已在库内写实「**当前单人维护**」。据此：

**首版形态 —— 凭据即身份，不建会话：**

- 请求头 `Authorization: Bearer <operator_id>.<secret>`；服务端按 `operator_id` 取行，比对 `SHA-256(secret) = credential_hash`，并断言 `disabled_at_utc IS NULL`。
- **不签发会话、不做 rotation、不复制 refresh 那套机制**。判据是调用形状：内部面的调用量是每天个位数的人工动作，会话机制解决的是「高频调用不该反复出示长期凭据」，这个前提在此不成立。复制一套 `session` / `generation` / 宽限回放，是为一个不存在的问题付一整套实现与运维成本。
- **凭据轮换 = 写一行新 `operator` 行 + 停用旧行**（或原地换 `credential_hash`）。节奏沿用密钥轮换的既有取向：例行 90 天 + 疑似泄漏立即换。
- **托管自成一类**：内部访问凭据是继会话密钥 / 内容签名密钥 / 渠道验票凭据 / 外接能力凭据之后的第五类托管条目，**不与既有各类钥匙共用托管配置**（`environments.md`「各类钥匙不共用托管配置」原样适用）。维度是 **operator × 环境**；本地 feature 环境用开发专用 operator，与线上 `operator_id` 空间隔离、永不共用（同开发专用 `kid` 的纪律）。

**企业 IdP（OIDC / 企业微信 / 飞书 / 云厂商 IAM）留位不启用**，形态即上表的 `operator_identity`。按 K13 写死触发条件：

> **触发启用的条件（满足其一）：内部人员超过一人，或出现非工程岗（运营 / 客服）复核员。**

启用是纯增量：新增 `operator_identity` 行，`operator_id` 与全部历史 `claimed_by` / `publishedBy` **一字不变**。这正是把 `operator_id` 定为内部键换来的东西。

### 4. 接入面：`/internal/` 前缀，不属于契约面，不进端点全集表

`[既有推演]` 这是本方案里判据最硬的一条。

| 判据 | 结论 |
|---|---|
| K6：§3 端点全集表是机检断言③的**输入**（端点集 ⇔ **六份契约正文**，双向） | 内部端点在六份客户端契约中永不出现 ⇒ 一旦进表，断言③**当场红灯**。**内部端点不进 §3 表、不进 `contracts/openapi.yaml`、不进 §6 错误码台账** |
| pillar #3：客户端与后端唯一的耦合点是协议，`contracts/` 是它的单一事实来源 | 内部面**不跨客户端边界** ⇒ 它根本不是契约的对象。契约的稳定性承诺（`/v1/` 主版本、并存两版）对它无意义——它与后端同一制品同批发布 |
| K7：无鉴权例外的判据主语是「**玩家**」 | 内部面没有玩家 ⇒ 该判据既不适用也**无需扩写**。**内部端点一律必带凭据，无例外**（同 N10 的形态） |

**因此：**

- 路径前缀 **`/internal/`**，**不带 `/v1/`**。建议在 `internal-tools.md` 写死一条护栏：`/internal/` 前缀被保留，**永不出现在 `/v1/` 下、永不进端点全集表**——否则日后有人「顺手补全」会踩中 P-3。（是否同时在 `envelope.md` §3 表下加一句非规范性说明，见「仍需用户决定」之外的评审判断；本草稿倾向加，一句话即可，理由是 P-3 的读者在那里。）
- **同一制品、同一进程、独立监听**（K2）。不拆成第四个部署单元：那与「零新增部署形态」相抵，且处置动作必须与 `account` 域写入同事务——拆进程即跨进程写同一张表，白白多一个故障域。
- **复用序列化惯例，不复用契约机制**：JSON / lowerCamelCase / RFC 3339 `…AtUtc` / 不下发 `null` / 忽略未知字段照旧（零成本，且让日志与既有脱敏管道一致）；`X-Request-Id` 照带（把内部动作接进两侧日志）。**但错误只需人读**，不引入 `code` / `class` / `detail` 三段与台账 —— `code` 的存在理由是「客户端据它分处置路径」，内部面的读者是人。
- **限流**：内部面不进 fail-open / fail-closed 那套（面向受控来源）。唯一需要计数的是凭据校验失败，超阈值即告警。
- **暴露形态**见「仍需用户决定」第 2 条 —— 全库对入站运维通道零承载，这是库外事实。

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

**明确不提供任意查询面**：没有「按任意条件查 `account` / `profile` / `identity`」的端点，没有任意 SQL 面。判据 —— 端点集与已定的处置动作**一一对应且封闭**；一个通用查询页会当场绕过 `identity` 与 `profile` 分表分权限（`environments.md`），而那正是 K8 的承载方式。

### 5. 界面档次：首版 CLI；控制台日后引入只作调用方

`[既有推演]` K3 已给出本库对内部界面的既有取向，**逐字适用**：人机接口 = CLI / 脚本，控制台若日后引入只作调用方，不动存储、不动纪律、不需迁移。

- 首版**不做 Web 页**。理由不是省事，是 K5 的「当前单人维护」使 Web 页的收益（非工程岗可用）此刻为零，而它的成本（一套前端、一套内部会话与 CSRF 面）非零。
- **「首版就用运维脚本 + 人工读写数据库」不可取**，两条硬理由：
  1. 人直接 `UPDATE nickname_review` 会绕过条件 `UPDATE`，M6 / M7（恰好被一人领到 · 迟到提交被拒）在纸面成立而线上不成立；`claimed_by` 也仍然没有来源。
  2. K4 的同源纪律：规则集表上「人类身份只有 `SELECT`」已被写实。给人一个可写库凭据去处置，等于把这条纪律限缩成「只有 flags 那一张表算数」。**建议把 K4 提升为全库通则：人类身份对业务表恒只有 `SELECT`，一切写入经内部端点。**
- 控制台的启用触发条件与 §3 的 IdP 同一条（出现非工程岗复核员），两者本就同时需要。

### 6. 复核台：`claimed_by` 的机械形态

`[既有推演]` 承接 `operations/moderation.md` 的伪码，只补它缺的那一格：

| 项 | 定 |
|---|---|
| `claimed_by` 类型 | `text`（同 `review_state` 存 `text` 不用数据库 enum 的纪律） |
| **取值域** | `operator` 表中 `disabled_at_utc IS NULL` 的行的 `operator_id`。**加外键 `REFERENCES operator(operator_id)`** —— 把「`claimed_by` 是一个真实存在的内部人员」落成数据库不变式而非应用层约定，同本库「约束即不变式」的一贯手法。`operator` 只停用不删行 ⇒ 外键不阻碍任何既有路径；`nickname_review` 终态行按批 `DELETE` 的方向是 review → operator，同样不受影响 |
| **来源** | 服务端从本次内部请求**已认证的凭据**解析得出。**绝不接受请求体传入 `claimedBy` / `operatorId`** —— 同 `eventId` 由服务端生成、不接受客户端提供的纪律。允许传入即任何持凭据者都能冒名判定，M7 在纸面成立而实际被绕过 |
| 伪码里的 `:reviewer` | 即上述 `operator_id`，两处（领取的 `SET`、判定的 `WHERE`）恒为同一个值 |

**M6 / M7 因此机械成立**：领取 `SET claimed_by = :operatorId`；判定 `UPDATE … WHERE state='Claimed' AND claimed_by = :operatorId`，按受影响行数分支。租约过期后条目已回 `Pending`（或被他人领走），两条件都不再同时满足 ⇒ 命中 0 行 ⇒ 迟到提交被拒。

**一处补正：租约回收时一并置空 `claimed_by` 与 `claim_expires_at_utc`。** 既有伪码只写了「置回 `Pending`，`claim_attempts += 1`」。留着旧 `claimed_by` 会让「谁在办」这一列在 `Pending` 行上说谎，而它是审计要读的列（判定被拒本身不依赖清空——`state` 已变即 0 行）。

**判定的落地形态：**

- `decision` 取值 **`Violation` / `Clean`**（PascalCase 字符串，存 `text`，同 `kind` / `severity` 清单可增量的纪律）。
- `enqueue_reason` 取值建议 **`WordlistReview`**（N8 复核级命中）· **`Bypassed`**（S2 的 T1 绕过检出）· **`ThirdPartyReview`**（N9，适配器启用后）· **`Rescan`**（T2 / T3 重扫判疑）。
- **判 `Violation` 的一次事务内**：`nickname_review` 转终态 → 一条 `NicknameViolation` 落 `risk_event` → 按处置阶梯置「须改名」档（更新 `nickname_scan.review_state`）。对位 S4：**`/accountInfo/nickname` 在云端一字不变**（K9）。
- **判 `Clean` 的一次事务内**：`nickname_review` 转终态 → 更新 `nickname_scan.review_state` 与 `reviewed_wordlist_version` 为当前版本（使 T2 不再重扫）。**不产事件。**
- **这两次 `risk_event` 写入走同事务直写，不走旁路缓冲。** 不违反「绝不在同步热路径上裁决」—— 被禁的是裁决在**玩家同步热路径**上；内部面本就是人工裁决面，且 `NicknameViolation` 与 `NicknameBypassed` 同属确定性检出，没有累计冗余可丢（`ADR-0059` 的同一条判据）。
- **判定结果回灌词表仍走发布动作，复核台不设旁路**（K12）。首版**不新增候选词条表**：`Decided` 行保留 180 天，下一次词表发布时按 `decided_at_utc` 取一批即可。

**不分派（不按渠道 / 语言）。** `[既有推演]` 昵称是单一字段、词表是统一的一份，语言维度没有承载对象；渠道维度需要一张路由表加一个「谁负责哪一片」的组织事实，而首版人群是一人。`SKIP LOCKED` 的批量领取本就是无分派的公平队列。日后需要时形态是纯增量：给 `nickname_review` 加一列 `assigned_group`、在领取语句的 `WHERE` 加一个等值条件，**不动任何不变式**。

### 7. 风控工单：本库一张 `ops_ticket` 表，与复核台共用同一套身份与同一个面

`[既有推演]` 07 分片明写两条宜一并裁决。落点判据：

- **不进外部工单系统。** 处置动作必须与 `account.status` 写入**同一次事务**（K10 + 会话吊销），跨系统即让「工单已关、`status` 未改」成为可达状态；且引入第二个系统与「明确不引入」的一贯取向相抵。
- **不能只靠在 `risk_event` 上按阈值聚合出待办**：那样没有「已看过 / 已驳回」这一态，同一账号会永远浮在待办里。**需要一张有状态机的表**，且它的形态判据与 `nickname_review` 逐条相同（体量随待办积压增长 · 按状态取待办 + 按账号点查 · 不分区 · 终态按批 `DELETE`）。

```
ops_ticket (ticket_id PK, account_id, kind, severity,
            trigger_occurred_at_utc, trigger_event_id,      ← 软引用，见下
            state, decision, decided_status, note,
            claimed_by FK operator, claim_expires_at_utc, claim_attempts,
            opened_at_utc, decided_at_utc,
            UNIQUE (account_id) WHERE state IN ('Open','Claimed'),
            索引 (state, opened_at_utc),
            索引 (state, claim_expires_at_utc),
            索引 (account_id, opened_at_utc))
```

- **触发事件是软引用的两列，不是外键。** `risk_event` 的主键是 `(occurred_at_utc, event_id)`（分区表唯一索引必须含分区键）⇒ 引用需两列；而分区到期整分区 `DROP` 会让任何指向它的外键失效或阻塞裁剪 ⇒ **不建外键**。工单可能活得比它的触发事件更久，这是被接受的：`ops_ticket` 自身已记下 `kind` / `severity` / 时间。
- **`UNIQUE (account_id) WHERE state IN ('Open','Claimed')`**：同一账号在办至多一条，理由与 M8 逐字相同（阈值反复触发会连开多条、让人对同一账号重复判定）。命中冲突 ⇒ **更新既有在办条目的触发引用与 `severity` 为最新一次**，不新插行。
- **领取语义与 `nickname_review` 逐条相同**（条件 `UPDATE` 取租约 · `SKIP LOCKED` 只在选行那一瞬 · 租约回收任务）——**共用一条既有的定时任务通道**，不新开。租约超时初值可与复核共用一个旋钮，或另立一个；建议**另立**（工单判定要读窗口计数，比昵称复核慢，30 分钟偏紧），初值 **60 分钟**，待实测校准，落 `config_knob`。
- `decision` 取值 **`Dismiss` / `Restrict` / `Ban`**；`decided_status` 记落定后的 `account.status`（`Dismiss` 时为空）。
- **`note` 是给人读的自由文本**，明写纪律：**不得记入任何个人信息**；它随注销硬删，因此**不作为举证依据**（举证走 `operator_audit`，见 §8）。

**处置的事务边界（一次事务）：**

```
SELECT … FOR UPDATE on account            ← 并发获取恒落 account 行（既有通则）
  ├ 断言 account.status = :baseAccountStatus   ← 不等即拒，见下
  ├ UPDATE account.status = restricted | banned
  ├ 吊销该账号全部会话（revoked_reason = OperatorRevoked，对位 S5）
  ├ UPDATE ops_ticket → state='Decided', decision, decided_status, decided_at_utc
  └ INSERT operator_audit 一条
```

- **`baseAccountStatus` 是必填的乐观前置条件，不是装饰。** 这是把 pillar #2 的 CAS 手法（`baseRevision`）原样用在最高危的那个动作上：工单是几分钟前领的，期间该账号可能已申请注销（`status → pendingDeletion`）或已被另一次处置改过。不等即拒、`status` 一字不变。它防的是误操作，成本为零 —— 而 K5 已明确否决四眼原则（当前单人维护，纯摩擦），所以这是唯一一道防线。
- **解除处置（`banned`/`restricted` → 恢复）走同一个端点**，`decision` 取 `Dismiss` 且带 `baseAccountStatus`；恢复目标沿用既有语义：**只改回 `status`，永不带外改写昵称**（`nicknameChangeRequired` 由云端状态算出，玩家自己改名即清零）。
- **`Restrict` / `Ban` 之外的自动化一步不进**：`ADR-0027` 原样成立，本方案只是给「人工确认」这个动作补上它一直缺的那个面。

### 8. 内部动作审计：`operator_audit`，3 年，注销执行不删

`[既有推演]` 一条 append-only 的内部动作留痕，形态与 `deletion_audit` 同构：

```
operator_audit (audit_id PK, operator_id, action, occurred_at_utc,
                account_id, target_kind, target_id, request_id, context jsonb,
                索引 (occurred_at_utc),
                索引 (account_id, occurred_at_utc),
                索引 (operator_id, occurred_at_utc))
```

- **`context` 只装内部键与结果，绝不装昵称串、`note` 或任何个人信息。** 这是刻意设计出来的性质而非事后声明：**「这张表含不含个人信息」决定它的保留期与是否进注销删除清单**，而它是可设计的。把可关联到个人的载荷留在 `nickname_review` / `ops_ticket`（180 天 + 注销硬删），审计只留「谁 · 何时 · 对哪个内部对象 · 做了什么 · 结果」。
- ⇒ **保留 3 年、注销执行不删**，与 `deletion_audit` 同判据（条目不含个人信息，与 `account` 墓碑同一性质；且注销执行时删掉它等于在最需要举证的那一刻销毁证据）。存 `account_id` 不破坏这一点 —— `deletion_audit` 已是先例。
- 到期按批 `DELETE`，挂既有周期通道，**不分区**（体量 = 人工动作数，一生几千行量级）。
- `action` 取值随端点集增长：`NicknameReviewDecide` · `TicketDecide` · `WordlistPublish` · `FlagsPublish` · `ContentPublish` · `KnobUpdate` …——**它是 `publishedBy` / 「更新者」那几处留痕的共同落点**，使全库的内部动作有一条可读的时间线，而不是散在五张表的五个列上。既有各表的 `publishedBy` 列**保留不动**（就地可读是它的价值），`operator_audit` 是横向的第二视图，两者由同一次事务同批写入。

### 9. 可见字段范围与合规面

`[既有推演]` K8 逐字覆盖内部面 —— **无需新造断言**：「`realName` / `idNumber` 在应答、日志与 `response_snapshot` 中零出现」里的「应答」包含内部端点的应答。补三条落地口径：

| 面 | 复核员可见 | 恒不可见 |
|---|---|---|
| 复核台条目 | `review_id` · `account_id` · `submitted_nickname` · `wordlist_version` · `enqueue_reason` · `enqueued_at_utc` · `claim_attempts` | 其余一切 |
| 工单条目 | `ticket_id` · `account_id` · `kind` · `severity` · `subject` / `expected` / `actual` · 窗口计数 · `app_version` / `content_version` · `account.status` | 其余一切 |
| 恒不可见（全库） | — | `realName` / `idNumber` · 手机号 / 邮箱（库内本就只有 `identifier_mac`）· `profile` 的 `doc` 内容 · 会话凭据 / `sid` / `tokenId` · `response_snapshot` |

- `account_id` 对内部人员可见是必需的（它是处置的对象键），且它不是个人信息（同 `deletion_audit` 注销后仍留它的判据）。
- **`device_id` 不呈现**：它只作观测维度、永不参与判定，呈现给人只会诱导按它做判断。
- 07 分片抬头提到的「**客服侧的账号查询入口**」两条待答项均未展开，**本草稿不设计它** —— 它是可见字段面风险最高的一块（一个通用账号查询页是 K8 最可能的破口），应单独立题。

### 10. 上线时点：进第二份发布前置清单

`[既有推演]` 按 `deployment.md` 两份清单的既有判据：

- **不进第一份**（「首个真实账号建号之前」）。判据是「后置之后再补，是否需要对存量账号做一次追溯动作」——复核台后置只会让 `nickname_review` 积压 `Pending` 条目，补上工具后照常处理，**无追溯动作**。
- **进第二份**（「首次面向公众发行之前」），建议新增一项：

  > **内部处置台可用** —— 过闸断言 = 在 `backend-testing` 走通一次完整的昵称复核（领取 → 判定 `Violation` → `nickname_scan.review_state` 落「须改名」档、`/accountInfo/nickname` 一字未变）与一次完整的工单处置（领取 → `Ban` → 全部会话被吊销 → `operator_audit` 落一条）；且 `realName` / `idNumber` 在两条链路的应答与日志中零出现。

  理由：公开发行后复核级命中与风控阈值触发会持续产生待办，无人能处置即合规敞口；且 `ADR-0027` 的「人必须在回路里」在没有面的情况下无法兑现。未就绪的处置同两份清单：**推迟上线，不降级放行**。

---

## 具体形态（可 derive 的落地面）

### 新增三表的承重列（拟并入 `systems/account.md`「存储形态：承重列」）

见 §2（`operator` · `operator_identity`）、§7（`ops_ticket`）、§8（`operator_audit`）。四张表**全部新建**，不涉及 `expand → deploy → contract` 的迁移三步（线上无既有数据），与风控四张台账同批。

### 既有表的两处补正

| 表 | 补正 |
|---|---|
| `nickname_review` | `claimed_by text REFERENCES operator(operator_id)`；租约回收时一并置空 `claimed_by` 与 `claim_expires_at_utc` |
| 各留痕表（flags 规则集 · 内容发布 · 词表 · 时段规则集 · `config_knob`） | `published_by` / 「更新者」的取值域定为 `operator_id`（**不改列，只定取值域**） |

### 事务边界（拟并入 `systems/account.md` 事务边界表）

| 操作 | 同一事务内的写入 | 并发获取 |
|---|---|---|
| 复核领取 | 条件 `UPDATE nickname_review` 取租约（`SKIP LOCKED` 只在选行语句内，事务立即提交） | 无行锁跨人工时长 |
| 复核判定 | `nickname_review` 转终态 ·（`Violation` 时）一条 `NicknameViolation` 落 `risk_event` · `nickname_scan.review_state` / `reviewed_wordlist_version` 更新 · 一条 `operator_audit` | 条件 `UPDATE` 的受影响行数分支 |
| 工单处置 | `account.status` 更新 · 该账号全部会话吊销（`OperatorRevoked`）· `ops_ticket` 转终态 · 一条 `operator_audit` | `SELECT … FOR UPDATE` on `account`；`baseAccountStatus` 不等即拒 |

### 注销执行删除清单的增补

| 表 | 处置 | 理由 |
|---|---|---|
| `ops_ticket`（该账号全部条目） | **硬删除** | 含 `note` 自由文本与判定记录，属可关联到个人的行为数据（同 `nickname_review`） |
| `operator_audit` | **保留全行** | `context` 不含个人信息，与 `deletion_audit` / `account` 墓碑同一性质 |
| `operator` · `operator_identity` | **不涉及** | 内部人员不是 `account`，永不进任何玩家删除路径 |

### 新增旋钮（拟并入 `environments.md` 旋钮清单 + `moderation.md` 数值初值表）

| 旋钮 | 初值 | 推导 |
|---|---|---|
| 工单租约超时 | 60 分钟（待实测校准） | 工单判定要读窗口计数，比昵称复核的秒级判断慢；复核的 30 分钟偏紧 |
| 工单终态条目保留期 | 180 天 | 与 `nickname_review` 同期（含可关联到个人的行为数据） |
| 内部动作审计保留期 | 1095 天（3 年） | 与 `deletion_audit` 同期、同判据 |
| 内部凭据校验失败告警阈值 | 待定，上线后按实际调用量标定 | — |

### 服务端保证（与 M* / N* / S* / C* 同体例，建议编号 I*）

| # | 输入 | 期望 |
|---|---|---|
| I1 | 两个 operator 同时领取工单 | 每条待办**恰好被一个 operator 领到**（同 M6） |
| I2 | operator 租约超时后提交判定 | 命中 0 行、判定被拒；条目不被覆盖（同 M7） |
| I3 | 工单处置请求带的 `baseAccountStatus` 与库内当前值不等 | 拒绝；`account.status` 一字不变；无任何写入 |
| I4 | 任一内部端点未带凭据，或凭据属 `disabled_at_utc` 非空的 operator | 拒绝；无任何写入；失败计数 +1 |
| I5 | 任一内部端点的应答与日志 | `realName` / `idNumber` / 手机号 / 邮箱明文**零出现**（对位 C6 与发布前置清单第 5 项） |
| I6 | 一次 `Ban` 处置成功返回 | `account.status='banned'` · 该账号全部会话已吊销 · `ops_ticket` 已 `Decided` · 一条 `operator_audit` 已落，四者同事务；杀死进程于其间 ⇒ 四者都未发生 |
| I7 | 昵称复核判 `Violation` | `nickname_review` 终态 · 一条 `NicknameViolation` 落 `risk_event` · `nickname_scan.review_state` 更新，三者同事务；`/accountInfo/nickname` 在云端一字不变（对位 S4） |
| I8 | 请求体试图传入 `claimedBy` / `operatorId` | 被忽略；租约归属恒取自认证凭据 |
| I9 | 注销执行完成后 | 该 `account_id` 在 `ops_ticket` 中**零行**；`operator_audit` 条目**仍在** |
| I10 | 同一账号连续两次触发同一 `kind` 的升级阈值 | `ops_ticket` 中该账号在办条目恒为 **1** 条，触发引用与 `severity` 更新为最新一次（同 M8） |

---

## 后果

- **不触碰任何契约**：报文一字不改，`profile` 的 `doc` 不新增字段，§3 端点全集表不动，`openapi.yaml` 不动，错误码台账不动。与风控四张台账同一性质（全是后端内部状态）。
- **新增四张表**（`operator` · `operator_identity` · `ops_ticket` · `operator_audit`）+ 两处既有表补正；全部新建，无迁移三步。
- **新增一份主题文档** `operations/internal-tools.md`，并牵动六份既有文档的小幅回链（见 front-matter `targets`）。
- **`ADR` 候选两条**：① 内部人员身份与 `account` 完全分离、`operator_id` 为全库唯一内部标识；② 内部工具面不属于契约面（`/internal/` 不进端点全集表）。是否立 ADR 由评审决定。
- **`open-questions/07-internal-tools.md` 的两条可随提炼一并移出**（由 `/analyze-new-ideas` 执行，本技能不动待答清单）。分片抬头提到的「客服侧账号查询入口」**不在本草稿范围内**，建议保留为该分片的新一条待答项。
- **运营成本**：`ADR-0027` 已把「人必须在回路里」记为被接受的运营成本；本方案不增加它，只把它从「无处可做」变成「一条命令可做」。

## 备选方案（已考虑并否决）

- **内部人员挂进 `account` 表 / 复用玩家会话体系** — 撞「单账号活跃会话上限 1」、撞 `identity` 的封闭渠道取值域、且会把内部人员拉进合规删除路径。
- **`claimed_by` 直接存外部身份源的登录名 / OIDC subject** — 登录名会变、身份源会换，而它是租约归属键与审计外键，必须永久稳定；玩家侧的 `account_id` ↔ `identity` 分层已给出正解。
- **`claimed_by` 首版定为「运维脚本传入的受控枚举 / 自由文本」** — 那正是 M6 / M7 停在纸面上的形态：无认证即人人可冒名，且无停用态。
- **首版就用运维脚本 + 人工读写数据库** — 绕过条件 `UPDATE` 取租约（M6 / M7 线上不成立），且与 `content-delivery-ops.md` A3「人类身份只有 `SELECT`」的同源纪律相抵。
- **首版就做内部后台 Web 页** — K5 的「当前单人维护」使其收益为零、成本非零；A3′ 已给出「控制台只作调用方」的既有取向，日后引入是纯增量。
- **工单进外部工单系统（或既有工单系统的一个视图）** — 处置必须与 `account.status` 写入同事务，跨系统即让「工单已关、`status` 未改」成为可达状态；且与「明确不引入新系统」相抵。
- **不建工单表，直接在 `risk_event` 上按阈值聚合出待办** — 没有「已驳回」态，同一账号永远浮在待办里。
- **内部端点落在 `/v1/` 下并进端点全集表** — 机检断言③（端点集 ⇔ 六份契约正文）当场红灯。
- **给内部端点开无鉴权例外** — §4a 的判据主语是「玩家」，内部面根本不够格；内部端点一律必带凭据。
- **内部面拆成第四个部署单元 / 独立服务** — 处置动作须与 `account` 域同事务，拆进程即跨进程写同一张表，多一个故障域换不到任何隔离收益；且与「三处跑同一个 artifact」相抵。
- **为内部面复制一套 session / refresh / 宽限回放** — 会话机制解决的是高频调用不该反复出示长期凭据，而内部面是每天个位数的人工动作。
- **高危处置强制双人审批（四眼原则）** — K5 已明写「当前单人维护，四眼原则是纯摩擦」；本方案改用零摩擦的 `baseAccountStatus` 前置条件防误操作。
- **内部动作审计合并进 `risk_event`** — 那八个 `kind` 是玩家行为信号、按 180 天整分区裁剪；内部审计要 3 年且注销不删，两条时间轴不同（同 `deletion_audit` 分表的判据）。
- **复核台直接写词表（把判违规的串加进禁止级）** — 撞「三条来源通道收敛到同一次发布动作，不存在旁路写入」。
- **首版新增「候选词条」表** — `Decided` 行保留 180 天已够下一次词表发布取批，零新表。

## 与既有决策的张力

**无实质冲突。** 三处需要评审确认「这是延伸而非改动」：

1. **`content-delivery-ops.md` A3「人类身份只有 `SELECT`」原文只约束规则集表。** 本方案建议把它**提升为全库通则**（人类身份对业务表恒只有 `SELECT`，一切写入经内部端点）。这是加严不是放松，但它是一条既有纪律的扩面，宜在评审时明确点头。
   → **已裁决（2026-09-09 · 批量评审）：提升为全库通则。** 任何人类身份对任何业务表恒只有 `SELECT`，写入一律经服务端受控面；`content-delivery-ops.md` A3 的适用范围随之扩写。
2. **`operations/moderation.md` 的租约回收伪码**只写「置回 `Pending`，`claim_attempts += 1`」，本方案补一句「一并置空 `claimed_by` 与 `claim_expires_at_utc`」。这是补正而非改语义（M7 不依赖它成立）。
   → **已按标准默认采纳（2026-09-09 · 批量评审）：补正照写**，未作为取向问题出题——租约回收不置空归属键属工程常识默认，无相反取向可选。
3. **`operator_id` 收口 `publishedBy` / `config_knob` 更新者 / KMS 解包审计的「谁」**，牵动 `content-delivery-ops.md` 与 `environments.md`。它们与 `claimed_by` 是同一个空洞、同一个答案，但落笔面超出 07 分片本身的两条问题 —— 是否同批落笔由评审决定（不同批落也不冲突，只是那两处继续悬着）。
   → **已裁决（2026-09-09 · 批量评审）：同批收口三处。** `publishedBy`（flags 规则集 / 内容发布 / 词表 / 时段规则集）· `config_knob` 更新者 · KMS 解包审计的「谁」一律取 `operator_id`，`content-delivery-ops.md` 与 `environments.md` 的对应处随本批一并落笔。

## 前置依赖

- **`accountId` 形态定稿**（`deployment.md` 前置清单第 3 项）—— 本方案**不依赖**它：`operator_id` 是独立命名空间，只要求两者永不相交，故不构成阻断。列此仅为说明二者的关系已被处理。
- **告警接收人 / 值班形态**（全库零承载）—— 本方案的「凭据校验失败告警」「工单积压告警」需要一个接收面，而 `observability.md` 通篇只有告警口径、没有接收方。**不阻断本方案落笔**（指标出口已存在），但它是同一族的真空，宜在 07 分片另立一条。
- **入站运维访问通道**（堡垒机 / VPN / 出口 IP，全库零承载）—— 见「仍需用户决定」第 2 条。
- **07 分片抬头的「客服侧账号查询入口」** —— 未展开，本草稿不设计；它与本方案共用 `operator` 身份与 `/internal/` 面，但可见字段范围须单独裁决。

## 仍需用户决定

### ① 首版内部处置面的使用人群 —— 沿用「当前单人维护」这条前提吗？

`[取向选择]` 本方案的两处形态（§3 认证 · §5 界面档次）全部架在 `operations/content-delivery-ops.md` A4 那句「**当前单人维护，四眼原则是纯摩擦**」之上。这条是库内已写实的事实，但它写于 flags 发布语境、且是组织事实（会变）。首版内部处置台（昵称复核 + 风控工单）的实际使用人群是：

| 选项 | 后果 |
|---|---|
| **A. 仅维护者本人（沿用「单人维护」）** — **推荐** | 首版 = `/internal/` 端点 + CLI 调用方；认证 = 一枚长期内部凭据（`credential_hash`）；`operator` 表首版一行；不做 Web 页、不接 IdP、不设审批流。企业 IdP 与控制台**留位不启用**，触发条件已写死（人数 > 1 或出现非工程岗）。成本最低，且日后启用是纯增量、`operator_id` 与全部历史留痕一字不变 |
| **B. 首版即含非工程岗（运营 / 客服）复核员，且已有企业身份源（企业微信 / 飞书 / 云厂商 IAM 的 OIDC）** | 首版即启用 `operator_identity` + OIDC 授权码流 + 内部会话 cookie，并做一个极简 Web 页。多一套内部会话与 CSRF 面，但不自建口令体系 |
| **C. 首版即含非工程岗复核员，但**没有**可接的企业身份源** | 只能自建口令（+ 离职回收 + 口令策略 + 可能的 TOTP），这是本方案唯一一处会引入真实负债的分支。若落到这一档，建议先评估能否用云厂商 IAM 子账号顶上，而不是自建 |

**推荐 A**，依据是 K5 的库内既有陈述。若实际已是 B / C，本草稿的 §3 与 §5 需要按该档重写（表形态、`operator_id`、`claimed_by` 语义、工单形态、审计形态**在三档下均不变**——变的只有认证与界面这两层）。

→ **已裁决（2026-09-09 · 批量评审）：A —— 仅维护者本人，沿用「当前单人维护」。** 首版 = `/internal/` 端点 + CLI 调用方，认证为一枚长期内部凭据，`operator` 表首版一行；企业 IdP 与内部 Web 控制台留位不启用，启用触发条件按 §3 写死（人数 > 1 或出现非工程岗）。

### ② 内部面的暴露形态 —— `/internal/` 从哪里可达？

`[取向选择]` 全库对**入站**运维访问通道零承载（检索确认：`内网` 只出现在 NTP 授时与外部服务商的**出网**白名单）。内部端点与玩家 API 同进程、独立监听，但「独立监听绑在哪、谁能连上」是库外的运维事实：

| 选项 | 后果 |
|---|---|
| **A. 仅 VPC 内可达，经云厂商堡垒机 / VPN 访问** — 若已有其一则**推荐** | 纵深最厚：应用凭据出 bug 时网络层仍成立。代价是要维护一条接入通道（堡垒机实例或 VPN），且 CLI 要在跳板上跑 |
| **B. 公网可达，但网关侧限来源 IP 白名单 + 应用凭据** | 零额外基础设施，双层防护。**前提是有固定出口 IP**；远程 / 移动办公下白名单会频繁变更，变更摩擦最终会导致有人把它放开 |
| **C. 公网可达，仅靠应用凭据** | 只有一层。凭据一旦泄漏即等于线上封号权限。**不推荐**，除非 A / B 都不可行且接受该风险 |

需要的输入是一个事实：**腾讯云侧是否已有（或愿意开）VPC 接入通道，以及是否有稳定的固定出口 IP。** 答案落定后写进 `internal-tools.md` 的接入面一节；三档都不改本方案的任何表形态或事务边界。

→ **已裁决（2026-09-09 · 批量评审）：A —— 仅 VPC 内可达，经堡垒机 / VPN 访问。** 内部监听不对公网暴露；接入通道（堡垒机实例或 VPN）作为首版内部处置台可用的前置条件，随 §10 的第二份发布前置清单一并过闸。
