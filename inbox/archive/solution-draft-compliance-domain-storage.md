---
type: solution-draft
date: 2026-09-06
question: 合规域三类状态与产物的存储形态——`complianceTicket` 的存储与一次性消费（含 60 秒兑付回放窗口）· 注销冷静期这条跨天长时状态机的调度 · 数据导出产物的存储与不可枚举的下载链接签发；外加三个旋钮初值的确认与校准信号。
source: open-questions/06-platform-stack.md → 「合规域的存储与产物（08-16c 采集）」+ 其从属项「合规域三个旋钮的初值待实测校准」
targets: operations/compliance-ops.md（新建，本方案的主落点）· systems/account.md（三张表的事务边界与服务端保证）· operations/environments.md（旋钮清单 + 定时任务出口）· operations/observability.md（日志脱敏追加一条 · 三条运维探针）· contracts/compliance.md §10（`downloadUrl` 一句澄清，非语义变更）
counterpart: 无（本问题不跨库；客户端侧的合规流程编排已由 game-design-documents/systems/services/account-service.md 定死，本方案不产生新的客户端义务）
status: distilled
reviewed: 2026-09-06 · 批量评审 —— ① 取选项 A —— 保留 receipt_idem 全行 + 最小 account 墓碑；② signin 四条拦截码求值顺序写死
distilled-to: handoffs/2026-09-06-compliance-domain-storage.md
---

# 方案草稿 — 合规域的存储与产物

> **时间源在另一份草稿里。** 本方案中一切「到期」「消费时刻」「保留期」的判定，其时钟基准取 `inbox/solution-draft-trusted-server-clock.md` 第 1 条（**判定基准 = 该次事务的数据库时钟**）。本文件**不复述**那一半的论证——冷静期到期与未成年时段判定同吃一个时间源，口径必须只有一份。

## 问题

`contracts/compliance.md` 把合规域的**语义**定完了（六端点 · ticket 的一次性与 60 秒回放 · 冷静期 15 天 · 导出四状态与 `taskId` 形态 · 保留期），但把**怎么存、怎么调度、怎么签链接**全部留给了 `06`（§8 与 §11 后的 `## Open questions` 逐条点名）。三项互相独立、但都缺同一类东西：载体 · 键 · 生命周期 · 并发保证。

1. **`complianceTicket`** —— 存哪、以什么形式存、如何同时兑现「一次性消费」与「首次成功后 60 秒内原样回放」这一对**看似冲突**的要求。
2. **注销冷静期** —— 一条**跨天（15 天）的长时状态机**：到期生效、可撤销、必须幂等重入。`operations/environments.md`「定时任务出口」已为它预留位置，但明写「会追加对可靠调度的要求，形态待合规侧落定」。
3. **数据导出产物** —— 产物含个人信息，保留期 7 天，**链接不得可枚举**；`contracts/compliance.md` §10 已定 `downloadUrl` 是「绝对 HTTPS URL，签名在 URL 内、无鉴权可直下」，但没定它指向什么存储、签多久、过期后怎么收。

从属项：**三个旋钮的初值待实测校准**——实名提交次数上限 · 导出申请限流 · `pollAfterSeconds`。

## 约束（来自既有设计）

- **单库 PostgreSQL 承载全部权威状态；Redis 只承担限流计数器，不持有任何权威状态**（`systems/_index.md`）。
- **明确不引入**：独立文档数据库 · 消息队列 · 分布式事务协调器 · 分片 / 多主 / 读写分离（同上，逐条有理由）。
- **并发单元统一为 `account` 行**；契约条款优先落成**数据库不变式**而非应用层检查（「并发下只有约束是可靠的」，同上）。
- **CAS 用受影响行数分支，不要先 `SELECT` 再 `UPDATE`**（`systems/profile-store.md` 纪律 1）。
- **求值顺序照契约写死**（同上纪律 2）；`auth.md` §4 的先例是「**先判到期、再判宽限回放**」。
- **姓名 / 证件号永不回显、永不进任何应答、永不进日志**（`contracts/compliance.md` §10 · `envelope.md` §5a）。
- **`identity` 与 `profile` 分表分权限，使注销与数据导出能按数据类别定位**（`operations/environments.md`「区域与合规」）。
- **`receipt_idem` 永久保留、不设 TTL，且配置层有一条启动期断言**（`operations/purchase-ops.md`）——误配即重复发放漏洞且线上不可发现。
- **风控事件流保留 180 天，含可关联到个人的行为数据，不宜永久**（`operations/moderation.md`）。
- **`account.status` 四值 `active` / `restricted` / `banned` / `pendingDeletion` 是合规与风控共用的唯一挂接点**（`open-questions/02-account-compliance.md`）。
- **`restricted` / `banned` 的账号同样可以申请注销**（`contracts/compliance.md` §「POST /v1/compliance/deletion」）。
- **申请注销不吊销任何会话**；冷静期内玩家可继续游玩（同上）。
- **限流分层**：一般 fail-open，**有真金白银代价的通道 fail-closed 且计数落 Postgres**（`operations/environments.md`）。核验服务**按次计费**（`contracts/compliance.md` §9）。
- 客户端侧已定：ticket **只在 `ComplianceManager` 内存持有、不出任何 API 面、不落盘**；`ticketExpiresAtUtc` **读取即丢弃**（`game-design-documents/systems/services/account-service.md`）。本方案不改变这些。

## 建议方案

---

# A. `complianceTicket` 的存储与一次性消费

### A1. 载体 = Postgres 表，不是 Redis

`[既有推演]`

- `systems/_index.md` 已定「Redis 只承担限流计数器，**不持有任何权威状态**」。ticket 的消费态是权威状态：它决定一次实名核验会不会被重复调用（按次计费）、一次注销撤销会不会被重放。
- 更硬的理由：**消费必须与它触发的业务写入同一次事务**。跨存储会造出「ticket 已消费但实名结果未落」或反之——正是 `systems/_index.md` 拒绝独立文档数据库时逐字点名的那类失败态（「幂等记录与计数器同事务被拆成跨存储写入」）。
- 同一条判据的先例已在库内：`signin_replay`「需要与会话写入同一事务，因此放关系库而不是缓存」（`systems/account.md`）。**ticket 是这条判据的第二个实例。**

### A2. 表形态

`[通行做法]` + `[既有推演]`

```
compliance_ticket (ticket_hash    BYTEA PRIMARY KEY,
                   account_id     TEXT NOT NULL,
                   purpose        TEXT NOT NULL,      -- Realname | DeletionCancel
                   issued_at_utc  TIMESTAMPTZ NOT NULL,
                   expires_at_utc TIMESTAMPTZ NOT NULL,
                   consumed_at_utc TIMESTAMPTZ NULL,
                   response_snapshot JSONB NULL,
                   INDEX (expires_at_utc))
```

- **存哈希不存明文。** ticket 是一枚活凭据；`systems/account.md` 已把这条纪律立了两次（`identifier_mac` 存 HMAC、refresh 宽限回放「不缓存明文，靠重算」）。`ticket_hash = SHA-256(ticket)` 即可（ticket 本身是高熵随机串，无需加盐 / 加密钥抗字典）。
- **ticket 明文形态：32 位小写十六进制**（128 bit 随机）。与 `taskId` 的 `^[0-9a-f]{32}$` 和 `accountSeed`（16 位小写 hex）同向——定长 · 无前缀 · 无分隔符 ⇒ 两侧不需要对大小写或分隔符做归一。库内不再多立一套编码约定。
- **`purpose` 两值** `Realname` / `DeletionCancel`，兑现契约 §3 的「ticket 不可用于任何其他端点」。端点校验 `purpose` 不匹配 ⇒ `compliance.ticket_invalid` + `Unknown`（契约 §11 的取值表已把「用于非签发它的那个端点」归入 `Unknown`，无需新增取值）。
- **`response_snapshot` 只装应答体，绝不装请求体。** realname 端点存 `{realnameStatus, isMinor}`；cancel 端点回 `204` 无体 ⇒ 存空对象。**`realName` / `idNumber` 不进这张表的任何一列**——脱敏纪律约束的是「永不进任何应答、永不进日志」，而一份会被原样回放成应答的快照正是应答本身。
- **不设 `account_id` 上的唯一约束。** 同一账号可同时存在多枚未消费 ticket（见 A5），并发面由「10 分钟寿命 + 单端点 + 一次性」三重夹住（契约 §3）。

### A3. 一次性 + 60 秒回放：条件更新 + 受影响行数分支

`[既有推演]`

契约把这一对写成看似冲突的两条（§3：「一次性，消费后即失效」+「首次成功后 60 秒内原样回放上次应答，**不再消费、不产生任何副作用**」）。**它们不冲突**：一次性约束的是**副作用**，回放只是重发一份已产生的应答。落地形态：

```
UPDATE compliance_ticket
   SET consumed_at_utc = now(),
       expires_at_utc  = GREATEST(expires_at_utc, now() + interval '60 seconds')
 WHERE ticket_hash = :h AND consumed_at_utc IS NULL
```

**受影响行数分支**（照 `systems/profile-store.md` 纪律 1 的 CAS 手法，不先 `SELECT` 再 `UPDATE`）：

- **1 行** ⇒ 本次是首次消费。在**同一事务**内执行业务副作用（调核验服务并落结果 / 撤销注销），把要回给客户端的应答体写进 `response_snapshot`，提交。
- **0 行** ⇒ 再读该行判两种情形：
  - 行存在且 `now() - consumed_at_utc ≤ 60 秒` ⇒ **原样回放 `response_snapshot`，零副作用**；
  - 否则 ⇒ `compliance.ticket_invalid`（取值见 A4）。

> **核验服务调用在事务内的一句提醒：** 它是一次外部 HTTP 调用，放在持锁事务里会把外部延迟变成锁持有时长。建议形态：**先条件更新占位（标记消费）并提交** → 调核验 → **第二次事务写结果与 `response_snapshot`**。此时第二次事务未完成前的重试会读到「已消费但 `response_snapshot` 为空」——处置是**回 `server.unavailable`（`Retryable`）**，与契约 §11「核验服务不可达 → `server.unavailable`」逐字一致，客户端照既有路径重试即可。这条不新增任何 `code`。

### A4. 求值顺序写死，且回放窗口做成寿命的延长而非第二把尺

`[既有推演]`

顺序照 `auth.md` §4 的先例（**先判到期、再判宽限回放**），逐级短路，使应答唯一：

```
① 按 ticket_hash 查行           查不到 → ticket_invalid { Unknown }
② purpose / account 匹配        不匹配 → ticket_invalid { Unknown }
③ expires_at_utc < now()        已过期 → ticket_invalid { Expired }
④ consumed_at_utc IS NOT NULL   已消费 → 回放（窗口内，见下）
⑤ 否则                          首次消费，走 A3
```

**关键一笔：消费时把 `expires_at_utc` 拉到 `max(原值, consumed_at_utc + 60 秒)`（A3 的 SQL 已含）。** 这使 60 秒回放窗口成为**寿命的延长**，而不是与寿命竞争的第二把尺——否则会出现一个边角：在第 9 分 30 秒消费、第 10 分 30 秒回放，此时「已过期」与「在回放窗口内」同时为真，③ 与 ④ 的先后决定应答，而契约没有给这个边角定过口径。做成延长后**边角消失**，③ 与 ④ 的顺序可以放心照 `auth.md` 写死。

代价：一条 `GREATEST(...)`。收益：`Expired` 与 `Consumed` 在任何时刻都是互斥且确定的，验收断言无歧义。

### A5. 签发：每次拦截签发新的一枚，旧的不主动作废

`[通行做法]`

- 签发落点是 `signin` 判定被拦的那一刻，**与拦截应答同一次请求、同一次事务**（`signin` 本就握着 `account` 行锁）。
- **每次拦截签发新 ticket，不复用未消费的旧枚。** 理由是**寿命重置**：玩家在第 9 分钟重试登录时若拿到一枚只剩 1 分钟的复用 ticket，实名表单根本填不完，而 10 分钟这个初值的推导正是「覆盖一次实名表单填写 + 一次重试」（契约 §9）。旧枚不主动作废、自然到期；多枚并存不构成滥用面（单端点 · 单账号 · 10 分钟 · 一次性）。
- `detail` 随 ticket 一同下发 `ticketExpiresAtUtc`（台账 `envelope.md` §6 已写死形状），**客户端读取即丢弃**（客户端侧已定），本方案不改。

### A6. 清理

`[通行做法]`

`expires_at_utc` 过后再留 **24 小时**（供排障对上一次 `Consumed` / `Expired` 判定溯源），之后按批删除。挂在既有的周期任务通道上（`operations/environments.md`「定时任务出口」，与幂等记录分区滚动同处）。

**不分区、不设 TTL 扩展机制**：稳态存量极小——实名是每账号一生一次的动作，注销撤销更罕见。

---

# B. 注销冷静期：跨天长时状态机

### B1. 状态承载 = 独立表，`status = pendingDeletion` 由它派生

`[既有推演]`

```
account_deletion (account_id      TEXT PRIMARY KEY,
                  requested_at_utc TIMESTAMPTZ NOT NULL,
                  effective_at_utc TIMESTAMPTZ NOT NULL,
                  state           TEXT NOT NULL,   -- CoolingOff | Cancelled | Executing | Executed
                  previous_status TEXT NOT NULL,   -- 申请前的 account.status
                  cancelled_at_utc TIMESTAMPTZ NULL,
                  executed_at_utc  TIMESTAMPTZ NULL,
                  INDEX (state, effective_at_utc))
```

- **为什么不是 `account` 上的两列：** 注销是一个有多个时刻与三个终态的对象，还要能被审计追问（「谁在什么时候申请、什么时候撤销的」）。`account.status` 是「当前可玩性」的单点，不该兼职承载时刻与历史。
- **`account.status = pendingDeletion` 由「存在 `state = 'CoolingOff'` 的行」派生**，与 `nicknameChangeRequired`「由云端状态算出」是同一手法（`operations/moderation.md`）。契约的 status 四值**一字不改**。
- **`previous_status` 是承重列，不是审计装饰。** 契约明写 `restricted` / `banned` 的账号同样可以申请注销（PIPL 的删除权不因风控状态而消失）；撤销时若无脑把 `status` 置回 `active`，就成了**用注销申请 + 撤销来洗白风控处置**的一条路径。撤销必须恢复到 `previous_status`。
  > 这条是本方案里最容易被实现漏掉、且漏掉后**线上不可发现**的一处（表现为「某些被封号的玩家又能进了」，没有任何报错）。

### B2. 调度形态：周期扫描 + `FOR UPDATE SKIP LOCKED`，零新增组件

`[既有推演]` + `[通行做法]`

`operations/environments.md` 明写「合规侧的注销冷静期是一条跨天长时状态机，会追加对可靠调度的要求——出口已预留」。**本方案的结论是：那条追加要求由单库即可满足，不需要引入任何调度中间件或消息队列**（后者已被 `systems/_index.md` 明确不引入）。

```
每 5 分钟一轮（初值）：
  BEGIN
    SELECT account_id FROM account_deletion
     WHERE state = 'CoolingOff' AND effective_at_utc <= now()
     ORDER BY effective_at_utc
     FOR UPDATE SKIP LOCKED
     LIMIT :batch
  → 逐个账号在各自的事务里执行 B4 的删除，成功则 state = 'Executed'
  COMMIT
```

四条性质逐一对上「可靠调度」的要求：

| 要求 | 兑现方式 |
|---|---|
| **多副本安全** | `SKIP LOCKED` 使两个容器同时跑同一个任务互不重叠 ⇒ **不需要 leader 选举、不需要分布式锁** |
| **幂等重入** | 执行是条件转移 `UPDATE … WHERE state = 'CoolingOff'`，受影响行数分支；进程中途崩溃 ⇒ 事务回滚，下一轮重新领取 |
| **到期精度** | 冷静期 15 天，晚几分钟生效无任何语义影响——**这正是可以不引入调度中间件的判据**，写下来使它不必被重新论证 |
| **不与撤销竞态** | 撤销与执行争用同一行的行锁，先到者赢；撤销在 `state != 'CoolingOff'` 时回 `deletion_irrevocable`（见 B3） |

**时钟异常时暂停本任务一轮**（见 `inbox/solution-draft-trusted-server-clock.md` 第 3 条）——注销执行是本库唯一不可逆的动作，不在时钟可疑时执行。

### B3. 三个端点的落地语义

`[既有推演]`

| 端点 | 事务内写入 | 分支 |
|---|---|---|
| `POST /deletion` | `INSERT … ON CONFLICT (account_id) DO NOTHING`，`effective_at_utc = now() + 冷静期`，`previous_status = account.status` | 插入 0 行且既有行 `state='CoolingOff'` ⇒ 回既有 `deletionEffectiveAtUtc` + `deduplicated: true`（**绝不顺延**，契约已定）；既有行为终态 ⇒ 新起一行（先删旧行或以 `requested_at_utc` 归档，见下） |
| `POST /deletion/cancel` | `UPDATE … SET state='Cancelled', cancelled_at_utc=now() WHERE account_id=? AND state='CoolingOff'`；同事务把 `account.status` 恢复为 `previous_status` | 1 行 ⇒ `204`；0 行且**无行** ⇒ `204`（幂等，契约已定「撤销一个不存在的申请同样回 204」）；0 行且行为 `Executing` / `Executed` ⇒ `compliance.deletion_irrevocable` |
| `GET /status` | — | `deletionEffectiveAtUtc` 仅在 `state='CoolingOff'` 时下发（契约：**存在即处于冷静期**） |

- **`Cancelled` 行的处置：** 撤销后玩家可以再次申请注销 ⇒ 主键 `account_id` 会冲突。建议**撤销时直接删除该行**（`account_deletion` 不承担历史归档职责），把「谁在什么时候申请 / 撤销过」交给风控事件流（`operations/moderation.md` 的只追加事件表，保留 180 天）——它已经是本库登记这类行为记录的地方，`kind` 增量新增两值 `DeletionRequested` / `DeletionCancelled`（`kind` 清单契约已定为**可增量、未知取值不驱动判定**）。这样 `account_deletion` 恒为「至多一行在办」的小表，且不额外造一份需要自己定保留期的历史。
- **申请不吊销任何会话**（契约已定），因此 `POST /deletion` 不触碰 `session` 表。

### B4. 执行时删什么：一次事务、全有或全无

`[既有推演]` + 一条 `[取向选择]`（见「仍需用户决定」①）

`operations/environments.md` 已把前提铺好：「`identity` 与 `profile` 分表分权限，**使注销与数据导出能按数据类别定位**」。执行即按数据类别逐条落：

| 对象 | 处置 | 依据 |
|---|---|---|
| `identity` 行 | **硬删除** | 渠道身份是个人信息；删后同一 `unionid` 再登录即建**新** `accountId`（唯一约束不再冲突），进度不恢复 |
| 实名材料（姓名 / 证件号 / 出生日期） | **硬删除** | 最敏感的一项 |
| `profile` 行 | **硬删除** | 玩家进度 |
| `signin_replay` · `compliance_ticket` · `session` | **硬删除** | 含 `identifier_mac` / 活凭据 |
| `export_task` 与其对象存储产物 | **硬删除** | 产物含个人信息 |
| 风控事件（该账号的全部条目） | **硬删除** | `operations/moderation.md` 已定性为「可关联到个人的行为数据」 |
| `push_idem` | **硬删除** | 无独立价值，随 profile 走 |
| `account` 行 | **保留墓碑**：`account_id` + `created_at_utc` + `deleted_at_utc`，其余列置空 | 见下 |
| `receipt_idem` | **保留** | 见下 |

**两条保留各有硬理由，不是偷懒：**

- **`receipt_idem` 必须保留。** 它的 `receipt_id` 全局唯一是**防重复发放的唯一防线**（`systems/profile-store.md` · `operations/purchase-ops.md`：永久保留、不设 TTL、且有一条启动期断言）。删掉它 = 同一张收据可被新账号再核销一次，且**线上不可发现**（第二次提交查不到记录即当作新票，没有任何报错）。它含 `account_id` 但不含个人信息；交易记录另有法定保存期。
- **`account` 墓碑必须保留**，否则 `receipt_idem.account_id` 悬空、对账通道断裂。墓碑不含任何个人信息，只是一个已删除标记 + 时间戳。**它不进 `account.status` 枚举**（契约四值不动）——「已删除」由 `deleted_at_utc` 非空表达，而已删除账号在任何端点上都不可达（identity 已删，无从登录）。

**执行必须在一次事务内完成、全有或全无**：删到一半崩溃 ⇒ 回滚 ⇒ 下一轮重新领取（B2 的幂等重入）。逐表删除的顺序按外键依赖排即可，不需要额外机制。

---

# C. 数据导出：产物存储与链接签发

### C1. 任务表 + 一条数据库不变式

`[既有推演]`

```
export_task (task_id     CHAR(32) PRIMARY KEY,      -- ^[0-9a-f]{32}$，契约已定
             account_id  TEXT NOT NULL,
             state       TEXT NOT NULL,             -- Pending | Ready | Failed | Expired
             requested_at_utc  TIMESTAMPTZ NOT NULL,
             ready_at_utc      TIMESTAMPTZ NULL,
             object_key        TEXT NULL,
             size_bytes        BIGINT NULL,
             artifact_expires_at_utc TIMESTAMPTZ NULL,   -- 产物 7 天
             record_expires_at_utc   TIMESTAMPTZ NOT NULL, -- 记录 30 天
             attempt_count INT NOT NULL DEFAULT 0,
             UNIQUE (account_id) WHERE state IN ('Pending','Ready'),
             INDEX (state, requested_at_utc))
```

**那条部分唯一索引是承重项**：契约的幂等语义是「命中既有未过期的 `Pending` / `Ready` 任务时回同一 `taskId` + `deduplicated: true`」，而两次并发 `POST export` 若靠应用层「先查再插」会各建一个任务。把它落成**数据库不变式**，与「单账号活跃会话上限 1 = 部分唯一索引」是同一手法（`systems/_index.md`「三条契约条款直接落为数据库不变式」）。**并发下只有约束是可靠的。**

- 命中冲突 ⇒ 读出既有行回幂等应答（同 `push_idem` 的「主键冲突 ⇒ 读出回幂等应答」处置）。
- 上一个任务为 `Failed` / `Expired` 时索引不再拦截 ⇒ 自动建新任务、给新 `taskId`（契约已定）。

### C2. 产物存储：私有对象存储桶，**绝不走 CDN**

`[既有推演]`

- 载体 = 对象存储的**私有 bucket**，与内容分发用的公开 bucket **分开**（不同权限边界、不同保留策略、不同审计线）。
- **导出产物绝不进 CDN。** `operations/content-delivery-ops.md` 的 CDN 形态是「`/blobs/<hash>` → `public, max-age=31536000, immutable`」——把含个人信息的产物放进那条通道，等于把它复制到全部边缘节点，且**缓存生命周期不受 7 天保留期控制**，删了源对象边缘仍可能命中。这条是护栏，不是优化建议。
- **`object_key` 与 `taskId` 解耦**：`exports/<yyyy>/<mm>/<32 位随机 hex>.json`。`taskId` 会出现在客户端、URL path 与日志里；若用它作对象键，「拿到 taskId 即能构造对象路径」，不可枚举就只剩签名一道。两者解耦是**纵深防御**——与契约对 `taskId` 拒绝 ULID 时那句「不可枚举性是纵深防御，不是访问控制」同一取向。

### C3. 链接签发：每次查询现签一枚短寿命预签名 URL（承重）

`[通行做法]` + `[既有推演]`

**契约里有一处极易读错、且读错的后果很重：** §10 写「`downloadExpiresAtUtc` 仅 `Ready` 时下发。产物保留期 7 天（§9）」。照字面实现会签出一枚**有效期 7 天的预签名 URL**——那是一个**7 天有效、无鉴权、可直下含个人信息文件**的凭据，会落进浏览器历史、下载管理器、剪贴板与任何一次截屏。

**正确形态：**

- `GET /v1/compliance/export/{taskId}` **每次应答都现签一枚新的预签名 URL**，单次有效期 **15 分钟**（新旋钮初值）。`downloadUrl` 因此是每次应答各不相同的临时值——契约没有要求它稳定，客户端的用法是「拿到即用系统浏览器打开」（`game-design-documents/systems/services/account-service.md`）。
- **`downloadExpiresAtUtc` 仍下发产物保留期终点（7 天）**，它回答的是「这份产物还能取到多久」，不是「这条链接还能用多久」。玩家在 7 天内任意时刻重新查一次即可拿到新链接。
- 签名时一并指定 `Content-Disposition: attachment; filename="…"` 与 `Content-Type: application/json`，避免浏览器内联渲染个人信息。
- 15 分钟的推导：覆盖玩家从看到按钮、到系统浏览器起下载、到一次失败重试；产物是单份 JSON（KB–MB 级），不存在长时续传需求。**待实测校准。**

> **建议提炼时在 `contracts/compliance.md` §10 的 `downloadUrl` 行补一句澄清**（「链接为短寿命签名，每次查询现签；`downloadExpiresAtUtc` 是产物保留期终点，非链接有效期」）。这**不是契约变更**——不动字段、不动 `code`、不动 `class`，只是把已有字段的正确读法写死，防止实现照字面签 7 天。

### C4. 生成执行：与冷静期共用同一条周期任务通道

`[既有推演]`

- 领取形态与 B2 逐字相同（`FOR UPDATE SKIP LOCKED` 扫 `state='Pending'`），**不引入消息队列**（`systems/_index.md` 明确不引入；本域也没有削峰需求——导出限流是 1 次 / 账号 / 24 小时）。
- **有限重试**：`attempt_count` 达上限 **3 次**（新旋钮初值）后置 `Failed` 终态。没有重试上限，一次数据库抖动就让玩家白等满 24 小时限流窗口才能重新申请；没有上限则一个永久失败的任务会被无限重领。
- `Failed` **不带 `failureReasonKey`**（契约已定），内部原因只进日志与指标。

### C5. 产物内容：白名单序列化器 + 一条断言

`[既有推演]`

契约 §8 已把产物定成**正列白名单**（`profile` 整份 + `account` 的三项，`identities[]` 每条仅 `channel` 与 `boundAtUtc`）。落地时**加一条自动断言**，与 `operations/content-delivery-ops.md` 的发布侧校验闸同一取向：

```
产物顶层键集合            == { profile, account }
account 的键集合          == { accountId, createdAtUtc, identities }
identities 每项的键集合   == { channel, boundAtUtc }
```

理由：白名单靠人自觉必然漂移，而这是**一份直接交到玩家手里的文件**——漏一个内部字段出去不可撤回。断言校验的是一份 JSON，可作为普通检查步骤挂在既有流水线上（同 `operations/deployment.md` 对契约机检断言的承接判断）。

### C6. 保留期落地：两道，缺一不可

`[通行做法]`

| 层 | 做什么 | 缺了它会怎样 |
|---|---|---|
| **应用层过期扫描**（主路径） | 到 `artifact_expires_at_utc` ⇒ 删对象 + `state = 'Expired'`；到 `record_expires_at_utc` ⇒ 整行删除 | 只靠生命周期规则 ⇒ 对象没了但 `state` 仍是 `Ready`，客户端拿到一枚指向不存在对象的链接 |
| **对象存储生命周期规则**（兜底，7 天 + 余量） | 桶级自动删除 | 只靠应用扫描 ⇒ 扫描任务失效时**个人信息无限期留存**，是一次静默的合规事故 |

- `Expired` 状态被契约刻意保留（「玩家几天后回来点旧入口时，『已过期，重新申请一次』与『找不到』是两句完全不同的话」），**因此记录保留期 30 天 > 产物保留期 7 天**，两个列分开而不是共用一个。
- **兜底规则的余量要留**（建议桶规则设 8 天而非 7 天），使应用层始终是先动手的那一个，否则兜底会抢在扫描之前删掉对象、制造第一行那种不一致。

### C7. 日志与观测

`[既有推演]`

- **`downloadUrl` 绝不落日志**——它是一枚含签名的临时凭据。`operations/observability.md` 的日志脱敏是「一处白名单式序列化，而不是各处自觉」，本条追加为该白名单的一条。
- 三条运维探针（进 `observability.md` 的「其余最小集合」）：
  - **导出任务生成时长分布**（`Pending → Ready` 的 p50 / p95）——它是 `pollAfterSeconds` 的校准信号；
  - **`Failed` 率**（分子按内部原因分档，只上看板）；
  - **到期扫描的滞后量**（最老的一个已超 `artifact_expires_at_utc` 但仍未清理的任务的滞后秒数，**阈值应恒接近 0**）——它是「个人信息超期留存」唯一的机制发现面。

---

# D. 三个旋钮的初值确认与校准信号

`[既有推演]`

从属项要的是「初值待实测校准」的收口。**三个初值均确认沿用契约 §9 已给的值**（本方案不改动），补的是**校准信号**——即线上哪个指标动了就该改这个值。全部落 `config_knob`，改值不发版（`operations/environments.md`）。

| 旋钮 | 初值 | 推导（契约 §9 已有） | **校准信号（本方案补充）** | 计数落点 |
|---|---|---|---|---|
| 实名提交次数上限 | **5 次 / 账号 / 天** | 覆盖一次输入失误加数次重试；核验按次计费，且提交是撞库面 | 命中 `rate.limited` 的账号占比 **> 1%** ⇒ 上限偏低；`compliance.verification_failed{Mismatch}` 后同日仍重试的次数分布是直接依据 | **Postgres**（见下） |
| 导出申请限流 | **1 次 / 账号 / 24 小时** | 生成是重操作且产物含个人信息 | 命中数应**恒接近 0**（正常玩家一生几次）；非零即客户端重试风暴或滥用，先查客户端再动值 | Postgres（`export_task` 自带，见下） |
| `pollAfterSeconds` | **5 秒** | 生成一份 JSON 的量级 | C7 的生成时长 p95：若 p95 > 15 秒则提到 p95/3 量级，避免无效轮询把端点打成高频面 | — |

**两条计数落点的判据（`[既有推演]`）：**

- **实名限流走 Postgres，且 fail-closed。** `operations/environments.md` 的分层已给判据：一般限流 fail-open 走 Redis，**但「有真金白银代价的通道」是例外**（验证码 / 短信）。核验服务**按次计费**（契约 §9 明写），因此它与短信同档：计数落 Postgres，计数不可用时对该端点 **fail-closed 返回 `rate.limited`**。**这是那条既有例外的第二个实例，不是新规则。**
- **导出限流零新增存储**：`export_task` 表本身就是计数器——「24 小时内该账号是否已有任务行」是一次索引查询。不必再立一份计数。

**本方案另新增两个旋钮**（登记进 `operations/environments.md` 旋钮清单）：

| 旋钮 | 初值 | 推导 |
|---|---|---|
| 预签名 URL 单次有效期 | **15 分钟** | C3 |
| 导出生成重试上限 | **3 次** | C4 |
| 冷静期 / 导出扫描周期 | **5 分钟** | B2（到期精度要求极低） |

## 具体形态（可 derive 的落地面）

### 三张新表

`compliance_ticket`（A2）· `account_deletion`（B1）· `export_task`（C1）。全部落主库，**无新增存储组件**。

### 三条数据库不变式（照「并发下只有约束是可靠的」）

| 契约条款 | 数据库形态 |
|---|---|
| ticket 一次性消费（`compliance.md` §3） | `UPDATE … WHERE consumed_at_utc IS NULL` 的条件更新 + 受影响行数分支 |
| 同时至多一个在办导出任务（§10 的 `deduplicated` 语义） | `UNIQUE (account_id) WHERE state IN ('Pending','Ready')` |
| 冷静期至多一条在办（§10「重复申请绝不顺延」） | `account_deletion.account_id` 主键 + `ON CONFLICT DO NOTHING` |

### 服务端保证（阈值参数化，落定后可直接转为验收用例）

照 `systems/account.md` 的 N1–N10 / S1–S5 体例：

| # | 输入 | 期望 |
|---|---|---|
| C1 | 首次以有效 ticket 调 `POST realname` | `200` + `realnameStatus`；`consumed_at_utc` 落值；核验服务被调用**一次** |
| C2 | 同一 ticket 在 60 秒内重复调 | **逐字相同的应答**；核验服务**不再被调用**；无任何写入 |
| C3 | 同一 ticket 在 60 秒后重复调 | `compliance.ticket_invalid` + `Consumed` |
| C4 | 超出 10 分钟寿命且从未消费 | `ticket_invalid` + `Expired` |
| C5 | 以 `Realname` 用途的 ticket 调 `deletion/cancel` | `ticket_invalid` + `Unknown` |
| C6 | 任何路径下 | `realName` / `idNumber` **不出现在**任何应答、日志、`response_snapshot` 中 |
| D1 | 冷静期内 `POST deletion` 第二次 | `deduplicated: true`，`deletionEffectiveAtUtc` 与首次**逐字相同** |
| D2 | `restricted` 账号申请注销后撤销 | `204`；`account.status` 恢复为 **`restricted`**（不是 `active`） |
| D3 | 从未申请过注销时调 `cancel` | `204`（幂等） |
| D4 | 执行已开始 / 已完成后调 `cancel` | `compliance.deletion_irrevocable` |
| D5 | 执行进程在删除中途被杀 | 全部回滚；下一轮重新领取并完成；无半删账号 |
| D6 | 两个容器同时跑到期扫描 | 每个到期账号**恰好被执行一次**（`SKIP LOCKED`） |
| D7 | 注销执行完成后 | `receipt_idem` 该账号的行**仍在**；`identity` / `profile` / 实名材料 / 风控事件**已删** |
| E1 | 并发两次 `POST export` | 只建一个任务；两次应答的 `taskId` 相同，其一带 `deduplicated: true` |
| E2 | `GET export/{taskId}` 连查两次（`Ready` 态） | 两次 `downloadUrl` **不同**（各自新签），`downloadExpiresAtUtc` 相同 |
| E3 | 预签名 URL 超出单次有效期后访问 | 对象存储拒绝；重新 `GET` 即得新链接 |
| E4 | `taskId` 不属于当前账号 | `resource.not_found`（**不是**「无权访问」，契约已定） |
| E5 | 产物到 7 天 | 对象已删、`state = 'Expired'`；记录仍在直到 30 天 |
| E6 | 产物 JSON | 顶层键集合恒为 `{profile, account}`（C5 断言） |

## 后果

- **新建 `operations/compliance-ops.md`**（`operations/_index.md` 已登记为「待落笔」）。本方案与 `inbox/solution-draft-trusted-server-clock.md` 合起来正好是它的两半。
- **`systems/account.md`** 增三张表的承重列与事务边界行（它已承载「合规能力（注销 / 导出）的服务内部形态」，见 `systems/_index.md` 的服务表），并追加上面的服务端保证表。
- **`operations/environments.md`**：旋钮清单增三行；「定时任务出口」那句「形态待合规侧落定」可改写为**已落定**（周期扫描 + `SKIP LOCKED`，零新增组件）；「限流的实现分层」补一句把实名限流登记为 fail-closed 的第二个实例。
- **`operations/observability.md`**：脱敏白名单增 `downloadUrl` 一条；探针增三条（C7）。
- **`operations/moderation.md`** 的风控事件 `kind` 清单增两值 `DeletionRequested` / `DeletionCancelled`（清单契约已定为可增量）。
- **`contracts/compliance.md` §10** 的 `downloadUrl` 行补一句读法澄清（C3）——**不是契约变更**。
- **存储 / 迁移影响**：三张新表 + `account` 上一个 `deleted_at_utc` 列，走 `deployment.md` 的 expand → deploy → contract；**无既有数据迁移**（线上尚无真实账号）。
- **对客户端零义务、零发版。**

## 备选方案（已考虑并否决）

- **ticket 存 Redis 并靠 `SET NX` / `GETDEL` 做一次性** — Redis 已被定为「不持有任何权威状态」；且消费与业务写入会被拆成跨存储，正是 `systems/_index.md` 点名的失败态（幂等记录已落但业务未写，或反之）。
- **ticket 存明文** — 一枚可被直接读走的活凭据，与 `identifier_mac`、「不缓存明文 refresh」两条既有纪律相反。
- **回放窗口做成独立于寿命的第二把尺** — 会造出「同时已过期且在窗口内」的边角，而契约没给这个边角定口径；把窗口做成寿命的延长则边角消失。
- **同账号复用未消费的 ticket** — 玩家在第 9 分钟拿到一枚只剩 1 分钟的 ticket，实名表单填不完；而 10 分钟这个初值的推导正是「覆盖一次表单填写 + 一次重试」。
- **把请求体存进 `response_snapshot` 以便完整回放** — 会把姓名 / 证件号落进存储，直撞 §10 的脱敏纪律。
- **冷静期用消息队列 / 延时消息 / 外部调度服务** — MQ 已被明确不引入；到期精度要求是「15 天误差几分钟」，用一个新故障域去换一个不需要的精度。
- **冷静期靠分布式锁 + 单实例定时器** — `SKIP LOCKED` 零成本地做到同一件事，且没有锁续期与脑裂问题。
- **`pendingDeletion` 直接写进 `account.status` 列并在撤销时置回 `active`** — 会把「注销申请 + 撤销」变成洗白 `restricted` / `banned` 的一条路径；派生 + `previous_status` 解决它且不动契约的四值枚举。
- **注销执行时连 `receipt_idem` 一并删除** — 删掉防重复发放的唯一防线，且**线上不可发现**（第二次核销查不到记录即当作新票，无任何报错）。
- **注销执行时连 `account` 行一并删除** — `receipt_idem.account_id` 悬空，对账通道断裂。
- **`account_deletion` 保留全部历史申请 / 撤销记录** — 要为它再定一份保留期与脱敏口径，而风控事件流已经是本库登记这类行为记录的地方。
- **导出产物走 CDN 以省流量** — 把含个人信息的对象复制到全部边缘节点，且缓存寿命不受 7 天保留期控制；删了源对象边缘仍可能命中。
- **`object_key` 直接用 `taskId`** — 拿到 `taskId` 即可构造对象路径，不可枚举只剩签名一道；解耦是零成本的纵深防御。
- **签一枚 7 天有效的预签名 URL 以对齐 `downloadExpiresAtUtc`** — 那是一枚 7 天有效的无鉴权凭据，会落进浏览器历史 / 下载管理器 / 截屏；每次查询现签的成本为零。
- **新增一个「刷新下载链接」端点** — `GET export/{taskId}` 已经是那个端点，再立一个即两处形态从此要同步演进（同契约否决「列出我的导出任务」端点的理由）。
- **导出限流走 Redis 计数器** — `export_task` 表本身就是计数器，一次索引查询即可；再立一份计数是凭空造第二真值。
- **实名限流走 Redis 且 fail-open** — 核验按次计费，放行的代价是真金白银且不可回收；`environments.md` 已为这一类立了 fail-closed 的先例。
- **只靠对象存储生命周期规则收产物，不做应用层扫描** — `state` 不会变成 `Expired`，客户端会拿到指向已删对象的链接，且契约刻意保留 `Expired` 的措辞区分会落空。
- **只靠应用层扫描，不设桶级生命周期规则** — 扫描任务失效时个人信息无限期留存，是一次静默的合规事故。

## 与既有决策的张力

**一处真张力，需要用户裁决（同时列在「仍需用户决定」②）：**

**受限 / 封禁账号走不出注销撤销这条路。** 三条既有条款单独看都成立，合起来出现一个缝：

1. `restricted` / `banned` 的账号**可以**申请注销（`contracts/compliance.md`，PIPL 的删除权不因风控状态而消失）；
2. `status` 变更**连带吊销全部会话**（`operations/moderation.md`）⇒ 这类账号**没有 access token**；
3. **撤销注销的 ticket 只在 `compliance.account_deleting` 这一处签发**（`compliance.md` §3 两处签发）。

⇒ 一个 `restricted` 账号申请了注销又后悔：它调不动需鉴权的 `cancel`（无 token），而它下次 `signin` 若被 `compliance.account_restricted` 拦住，就**拿不到撤销 ticket**——15 天后账号被不可逆地删除，玩家没有任何出路。

**零契约改动的最小解：把 `signin` 的合规拦截求值顺序写死为 `account_deleting` 优先于 `account_restricted`。**

- 冷静期是**有时限且不可逆**的，风控处置是**可持续且可撤销**的——先给玩家走出不可逆那条路的机会，是唯一方向正确的排序。
- **不削弱风控**：撤销端点不签发任何会话（契约 §3「兑付成功后不签发 token」），玩家撤销后重登仍会被 `account_restricted` 拦住。风控处置一秒都没有松动。
- 它只是把一个**本来就必须在某处写死的求值顺序**写死（四条拦截码在同一次 `signin` 上可能同时成立，契约没定顺序），落 `operations/compliance-ops.md` 或 `systems/account.md`，**不动任何报文、`code`、`class`**。

**为什么仍要用户裁决：** 它改变了一类玩家的实际可达路径（受限账号能收到 `account_deleting` 而非 `account_restricted`），且「四条拦截码的求值顺序」此前从未被任何文档表达过——这是一次**新增的契约级事实**，不该由 worker 代拍。

## 前置依赖

- **`inbox/solution-draft-trusted-server-clock.md`**（同批）——本方案全部「到期」判定的时钟基准取自它第 1 条；它的第 3 条「时钟异常时暂停不可逆动作」直接约束 B2 的扫描任务。**两份须成对评审**：只采纳本份会留下一个没有定义时间源的冷静期。
- **`02` 的「合规能力的上线分级」**（`open-questions/02-account-compliance.md`，**本批未处理**）。数据导出已定首版必做 ⇒ C 组不受影响；注销与实名的上线时点未分级 ⇒ A / B 组的**形态不变、落地时点待定**。建议 `operations/compliance-ops.md` 逐组标注所属档次。
- **实名核验服务商选型**（`06` 的另一条，**本批未处理**）。它只影响 A3 那次外部调用的适配器细节与超时值；「按次计费 ⇒ 限流 fail-closed」这条已由契约 §9 定死，不阻塞。

## 仍需用户决定

> **本节两条已于 2026-09-06 的批量评审中全部裁决**（`/batch-provide-solution-draft backend`）。逐条裁决见各条目下的「→ 已裁决」行；`/analyze-new-ideas` 消费本草稿时按裁决落笔，不再重问。

### ① 注销执行的删除深度：`receipt_idem` 与 `account` 墓碑保不保留？

**→ 已裁决（2026-09-06 · 批量评审）：取选项 A —— 保留 `receipt_idem` 全行 + 最小 `account` 墓碑**（墓碑不含任何个人信息、不可关联到自然人）；identity / 存档 / 实名材料 / 风控事件照常硬删。理由：防重复发放的防线完整，成本近零；选项 B 会让「买 → 注销 → 重建号 → 再核销同一张收据」成为可反复白得商品且线上不可发现的路径，选项 C 会让退款对账断链并需新增一套匿名 id 空间。
**跨草稿影响（同批一并确认）**：本裁决同时坐实了 `solution-draft-receipt-idem-cold-archive.md` 的承重前提「哨兵行永不删」，该草稿无需重做。

**背景（自包含）：** `receipt_idem` 是内购收据的幂等表，`receipt_id` 全局唯一是**防止同一张收据被重复核销发放**的唯一防线（已定为永久保留、不设 TTL、且有一条启动期断言防止误配）。它带一个 `account_id` 列。账号注销执行时，删不删它？删了它，那个 `account_id` 指向的 `account` 行也就没有保留的必要。

**方向 A（推荐）—— 保留 `receipt_idem` 全行 + 保留最小 `account` 墓碑。**
- 墓碑 = `account_id` + `created_at_utc` + `deleted_at_utc`，**不含任何个人信息**；`identity` / `profile` / 实名材料 / 风控事件全部硬删。
- 后果：防重复发放的防线完整；交易记录可对账（渠道退款窗口以月计）。留下的是一个**无法反查到自然人**的内部键。
- 合规立场：PIPL 的删除权针对个人信息；交易凭据另有法定保存期，且墓碑不可关联到自然人。

**方向 B —— 全量硬删除，包括 `receipt_idem` 的行。**
- 后果：**同一张收据可被新账号再核销一次**，且线上不可发现（第二次提交查不到记录即当作新票，无任何报错）。攻击形态明确：买一次 → 注销 → 重建号 → 再核销同一张票。
- 收益：删除权最彻底，无任何残留行。
- 若选此项，必须同时给出替代防线（例如把 `receipt_id` 单独存进一张不含 `account_id` 的黑名单表）——那实质上就是方向 C。

**方向 C —— 保留 `receipt_idem` 但把 `account_id` 匿名化（置为墓碑 id 或哈希），不保留 `account` 行。**
- 后果：防线保住、`account` 行不留；代价是**退款对账断链**（`operations/purchase-ops.md` 的三条退款对账通道要按账号定位），且匿名化本身要新增一套 id 空间。
- 它是 A 与 B 的折中，但把一条现成的对账通道换成了一套新机制。

**推荐 A**，理由：墓碑不含个人信息、成本近似为零；而 B 打开的是一个**线上不可发现**的重复发放漏洞——库内已经为这条防线立过一条启动期断言，说明它的失效模式被认定为高代价。

**这一项为什么是取向而非推演：** 它取决于用户对「删除权彻底性」的合规立场（是否接受保留一个不可关联到自然人的内部键），而不是工程正确性——三个方向都能实现。

---

### ② `signin` 四条合规拦截码的求值顺序（受限账号能否走出注销撤销）

**→ 已裁决（2026-09-06 · 批量评审）：取方向 A —— `account_deleting` 优先于 `account_restricted`。完整顺序 `account_deleting` → `account_restricted` → `realname_required` → `playtime_blocked`。** 契约零改动；风控不松动（撤销端点只取消注销、不签发会话，受限账号撤销后依然进不去）；「受限账号申请注销后无路可撤、15 天被不可逆删除」这条死路就此消除。方向 C（不定顺序）被否决——它会让该死路随机发生且不可复现。

**背景（自包含）：** 一次 `signin` 上可能同时成立多条合规拦截——例如一个被风控限制（`restricted`）的账号又申请了注销（在 15 天冷静期内）。契约定了四条拦截码（`realname_required` / `playtime_blocked` / `account_restricted` / `account_deleting`），但**从未定过它们同时成立时先返回哪一条**。这个顺序有实际后果：**撤销注销所需的 ticket 只随 `account_deleting` 下发**，收不到这条码就拿不到 ticket，而这类账号因为会话已被吊销、也调不动需鉴权的撤销端点 ⇒ 15 天后账号被不可逆删除，玩家无出路。

**方向 A（推荐）—— `account_deleting` 优先于 `account_restricted`。**
- 受限账号在冷静期内 `signin` 收到 `compliance.account_deleting` + 撤销 ticket，可以走出注销；撤销后重登再被 `account_restricted` 拦住。
- 风控**一秒都没松动**：撤销端点不签发任何会话（契约 §3 已定），玩家撤销后依然进不去。
- 完整建议顺序：`account_deleting` → `account_restricted` → `realname_required` → `playtime_blocked`（不可逆 / 有时限的在前，可持续的在后；时段判定放最后因为它每天都会重新成立）。

**方向 B —— `account_restricted` 优先（风控优先）。**
- 语义上「被限制的账号看到的第一句话就是它被限制了」，但受限账号将**无法撤销注销**——这是一条会真实删掉玩家账号的死路。
- 若选此项，必须另给一条出路（站外申诉通道能撤销注销 / 或给 `account_restricted` 也下发撤销 ticket），两者都是新增机制。

**方向 C —— 不定顺序，由实现自行决定。**
- 不推荐，列出只为说明已考虑：不定顺序 ⇒ 同一输入的应答不确定，验收断言无从写，且这条死路会以随机概率发生。

**推荐 A**，理由：零契约改动、零新增机制、风控强度不变，且把一个本来就必须存在的求值顺序显式化。

**这一项为什么是取向而非推演：** 它新增了一条此前不存在的契约级事实（拦截码的求值顺序），并改变一类玩家的实际可达路径——不该由 worker 代拍。
