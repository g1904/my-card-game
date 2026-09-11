# ADR-0061 — 内部人员身份自成一套 `operator_id`，与 `account` 完全分离

- **状态：** Accepted
- **日期：** 2026-09-09
- **来源：** handoffs/2026-09-09-internal-ops-tools-and-operator-identity.md · answer-logs/log-internal-ops-tools.md

## 背景

`nickname_review.claimed_by` 是「谁持有这条复核租约」的归属键，而本库此前**没有「内部人员」这个概念**——`account` 承载的是玩家。同一个空洞另有三处：flags 规则集 / 内容发布 / 词表 / 时段规则集留痕的 `publishedBy`、`config_knob` 的更新者、KMS 解包事件审计的「谁」。这些列写下了「操作者」却无取值域，导致复核队列的租约归属、处置阶梯上半档的人工确认路径都写不出断言。

## 决策

内部人员**不是 `account`**：本库自行分配稳定内部键 **`operator_id`**（`op_` 前缀 + 不可枚举的服务端生成串），落 `operator` / `operator_identity`（留位不启用）/ `ops_ticket` / `operator_audit` 四张表；`credential_hash` 存 SHA-256，**只停用（`disabled_at_utc`）不删行**。

**凡本库记录「哪个人做了这件事」，一律记 `operator_id`** —— 上述四处「操作者」空洞由它一次填上；`claimed_by` 类型 `text`、取值域为未停用的 `operator_id` 并**加外键**，来源恒取自已认证凭据、绝不接受请求体传入。

形态、端点集、认证与审计细节见 `operations/internal-tools.md`；四张表的承重列与事务边界见 `systems/account.md`。

## 理由

分离的四条理由逐条来自既有约束（→ `operations/internal-tools.md`「内部人员身份」）：`account` 是合规删除权的对象，一次误判的注销会删掉复核员本身；`session` 上 `UNIQUE (account_id) WHERE revoked_at_utc IS NULL` 对内部人员是错的（一人两台机器办公即撞索引）；`identity` 的渠道取值域封闭为三条登录渠道，没有企业身份这一档；`account` 行是全库唯一的并发单元，与内部动作无关。

内部键 / 外部映射的分层与玩家侧（`account_id` ↔ `identity`）逐字同构，理由也同构：外部身份源可换、登录名会变，而 `operator_id` 是**租约归属键与审计外键，必须永久稳定**——把登录名写进 `claimed_by`，一次改名就让历史审计指向一个不存在的人。企业 IdP 日后启用是纯增量，`operator_id` 与全部历史留痕一字不变。

## 备选方案

- **内部人员挂进 `account`（加一个角色位）** — 撞上述四条既有不变式，且污染 `contracts/auth.md` §3a 的渠道语义。
- **`claimed_by` 直接存外部登录名 / IdP subject** — 改名或换身份源即让历史审计与租约归属失去指称对象。
- **给内部人员定两套标识（复核一套、发布留痕一套）** — 四处是同一个空洞，两套标识无理由且让「谁做了什么」无法汇成一条时间线。

## 后果

- `operations/internal-tools.md` 是本面的权威落点；`systems/account.md` 承载四张表的承重列、外键与三行事务边界。
- `operations/content-delivery-ops.md`（`publishedBy`）· `operations/moderation.md` / `operations/compliance-ops.md`（`published_by`）· `operations/environments.md`（`config_knob` 更新者 · KMS 解包审计）各处**既有列保留不动**，本决策只定其取值域；`operator_audit` 是横向的第二视图，与既有留痕同事务同批写入。
- `moderation.md` 的 `claimed_by` 由「无取值域」变为可断言项，`nickname_review` 复核链路与处置阶梯上半档因此有归属系统可指。
- 内部访问凭据成为第五类托管条目（operator × 环境），不与既有四类钥匙共用托管配置。
- 客户端零影响：报文一字不改、不新增 `code`、端点全集表不加行。
