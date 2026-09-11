# account —— 账号 · 身份 · 会话（服务内部设计）

对位客户端的 `account-service`。**边界报文的权威在 `contracts/auth.md` 与 `contracts/compliance.md`，本文件不复述报文**，只写后端内部如何兑现它们：数据怎么存、并发怎么串行、凭据怎么算、密钥怎么用。

公共的存储与并发前提（单库 PostgreSQL · 并发单元 = `account` 行 · 约束即不变式）见 `_index.md`，此处不重复。

## 存储形态：承重列

只列承重列与约束，不是完整 DDL。

```
account        (account_id PK, created_at_utc, status, deleted_at_utc)

identity       (account_id FK, channel, channel_user_id, id_kind, bound_at_utc,
                UNIQUE (channel, channel_user_id),
                UNIQUE (account_id, channel))

session        (sid PK, account_id, device_id,
                token_id, generation, refresh_key_id,
                prev_token_id, prev_generation,
                issued_at_utc, refresh_expires_at_utc, absolute_expires_at_utc,
                revoked_at_utc, revoked_reason,
                UNIQUE (account_id, device_id),
                UNIQUE (account_id) WHERE revoked_at_utc IS NULL)

signin_replay  (channel, identifier_mac, device_id, sid, generation, created_at_utc,
                PRIMARY KEY (channel, identifier_mac, device_id))

compliance_ticket (ticket_hash PK, account_id, purpose, issued_at_utc,
                   expires_at_utc, consumed_at_utc, response_snapshot,
                   索引 (expires_at_utc))

account_deletion  (account_id PK, requested_at_utc, effective_at_utc,
                   state, previous_status, executed_at_utc,
                   索引 (state, effective_at_utc))

export_task       (task_id PK, account_id, state, requested_at_utc, ready_at_utc,
                   object_key, size_bytes, artifact_expires_at_utc,
                   record_expires_at_utc, attempt_count,
                   UNIQUE (account_id) WHERE state IN ('Pending','Ready'),
                   索引 (state, requested_at_utc))

risk_event     (occurred_at_utc, event_id, account_id, kind, severity,
                subject, expected, actual, request_id, device_id,
                app_version, content_version, context jsonb,
                PARTITION BY RANGE (occurred_at_utc) —— 月分区,
                PRIMARY KEY (occurred_at_utc, event_id),
                每分区索引 (account_id, kind, occurred_at_utc),
                每分区索引 (kind, occurred_at_utc))

deletion_audit (event_id PK, account_id, kind, occurred_at_utc,
                request_id, context jsonb,
                索引 (account_id, occurred_at_utc))

nickname_review (review_id PK, account_id, submitted_nickname, wordlist_version,
                 request_id, enqueue_reason, state, decision,
                 claimed_by REFERENCES operator(operator_id), claim_expires_at_utc, claim_attempts,
                 enqueued_at_utc, decided_at_utc,
                 UNIQUE (account_id) WHERE state IN ('Pending','Claimed'),
                 索引 (state, enqueued_at_utc),
                 索引 (state, claim_expires_at_utc),
                 索引 (decided_at_utc) WHERE state = 'Decided')

nickname_scan  (account_id PK, last_accepted_nickname, accepted_at_utc,
                reviewed_wordlist_version, review_state, last_scanned_at_utc,
                索引 (reviewed_wordlist_version),
                索引 (last_scanned_at_utc))

operator       (operator_id PK, display_name, role, credential_hash,
                created_at_utc, disabled_at_utc,
                索引 (disabled_at_utc))

operator_identity (operator_id FK, issuer, subject, bound_at_utc,
                UNIQUE (issuer, subject),
                UNIQUE (operator_id, issuer))

ops_ticket     (ticket_id PK, account_id, kind, severity,
                trigger_occurred_at_utc, trigger_event_id,
                state, decision, decided_status, note,
                claimed_by REFERENCES operator(operator_id),
                claim_expires_at_utc, claim_attempts,
                opened_at_utc, decided_at_utc,
                UNIQUE (account_id) WHERE state IN ('Open','Claimed'),
                索引 (state, opened_at_utc),
                索引 (state, claim_expires_at_utc),
                索引 (account_id, opened_at_utc))

operator_audit (audit_id PK, operator_id, action, occurred_at_utc,
                account_id, target_kind, target_id, request_id, context jsonb,
                索引 (occurred_at_utc),
                索引 (account_id, occurred_at_utc),
                索引 (operator_id, occurred_at_utc))
```

- `identity` 的两条唯一约束分别兑现「一个渠道身份只属于一个账号」与「一个账号在同一渠道最多一条 identity」（`contracts/auth.md` §1a）。
- `session` 的部分唯一索引兑现「单账号活跃会话上限 1」，普通唯一约束兑现「同设备重登是原地替换、不产生第二条记录」。**两条都要留**，理由在契约侧已写明。
- `signin_replay` 的键含手机号 / 邮箱这类个人信息，故以 `identifier_mac = HMAC(identifierSecret, identifier)` 存储，**明文绝不落库、绝不落日志**。它需要与会话写入同一事务（否则会出现「回放了但会话没落」或反之），因此放关系库而不是缓存。行保留 10 分钟后清理即可（窗口 60 秒 + 余量），不必分区。
- **`compliance_ticket` 存哈希不存明文**（`ticket_hash = SHA-256(ticket)`），与 `identifier_mac` 存 HMAC、refresh 宽限回放靠重算是同一条纪律：ticket 是一枚活凭据。它的消费态是权威状态（决定一次按次计费的核验会不会被重复调用、一次撤销会不会被重放），**必须与它守护的状态写入同一事务**，故落关系库而不是缓存——这是 `signin_replay` 那条判据的第二个实例。`response_snapshot` **只装应答体，绝不装请求体**：`realName` / `idNumber` 不进这张表的任何一列。
- **`account_deletion.previous_status` 是承重列，不是审计装饰。** `restricted` / `banned` 的账号同样可以申请注销，撤销时若把 `status` 无脑置回 `active`，就成了用「申请注销 + 撤销」洗白风控处置的一条路径。撤销必须恢复到 `previous_status`。这一处漏掉后**线上不可发现**：表现只是「某些被封号的玩家又能进了」，没有任何报错。
- **`account.status = pendingDeletion` 由「存在 `state='CoolingOff'` 的行」派生**，与 `nicknameChangeRequired` 由云端状态算出是同一手法；契约的 status 四值一字不改。`account.deleted_at_utc` 非空表示墓碑行，**不进 status 枚举**。
- **`export_task` 的部分唯一索引兑现「同时至多一个在办导出任务」**：两次并发 `POST export` 靠应用层「先查再插」会各建一个任务，落成数据库不变式才可靠；冲突即读出既有行回幂等应答，同 `push_idem` 的处置。
- **后四张表的写入方都在本域**（昵称判定链、存量扫描、合规域端点），故承重列在此；**分区 / 索引选型 / 裁剪 / 领取语义 / 探针在 `operations/moderation.md`**——与 `receipt_idem`（承重列在 `profile-store.md`、运维形态在 `purchase-ops.md`）同一分工。四张表都是新建，不涉及迁移三步。
- **`risk_event` 的主键含分区键**是 PostgreSQL 分区表唯一索引的硬要求；`event_id` 因此不是跨分区全局唯一，这不影响它「去重与工单关联的键」的语义——它由服务端生成、去重发生在写入侧，工单关联恒带时间戳。
- **`deletion_audit` 与 `risk_event` 分表**：`DeletionRequested` / `DeletionCancelled` 服务于举证而非风控判定，保留期 3 年且**注销执行时不删**（条目不含个人信息，与 `account` 墓碑同一性质）。它与 `account_deletion` 的插入 / 删除同事务，是撤销这个动作在库内的唯一留痕。
- **`nickname_review` 的部分唯一索引兑现「同一账号在办至多一条待复核」**——同一玩家反复改名撞复核级会连开多条条目、让人工重复判定；命中冲突即更新既有在办条目为最新一次提交，不新插行。它的领取走**条件 `UPDATE` 取租约**（不持锁到人工判定结束），理由与形态在运维侧。
- **`nickname_scan` 独立成表、不给 `account` 加列**：`account` 行是全库唯一的并发单元，一条纯离线批处理去批量更新 `last_scanned_at_utc` 会与 `signin` / `push` / `bind` 争同一把行锁。它一行一账号、不随时间增长，故不分区、无到期过期。
- **末四张表的写入方是内部运营工具面**，故承重列在此、工具面形态（内部身份 · 接入面 · 复核台与工单台的动作语义 · 可见字段范围 · 服务端保证 I*）在 `operations/internal-tools.md`——与上一条同一分工。四张表都是新建，不涉及迁移三步。
- **内部人员不挂进 `account`**：`account` 是合规删除权的对象、`session` 上有「单账号活跃会话上限 1」、`identity` 的渠道取值域封闭为三条登录渠道，三条中任一条都会在内部人员身上给出错误行为。`operator_id` 是本库分配的稳定内部键（非外部身份源的登录名 / subject），与 `accountId` 是两个永不相交的命名空间；`credential_hash` 存 SHA-256，**明文凭据绝不落库**（同 `ticket_hash` / `identifier_mac` 的纪律）。**只停用不删行**——删行会让 `claimed_by` / `operator_audit` 的外键悬空，而审计的价值恰在于人走了记录还在（同 `account` 墓碑行的取向）。
- **`nickname_review.claimed_by` 与 `ops_ticket.claimed_by` 的外键是承重的**：它把「持有租约的是一个真实存在的内部人员」落成数据库不变式而非应用层约定。`operator` 只停用不删行 ⇒ 外键不阻碍任何既有路径；两张表终态行按批 `DELETE` 的方向是 ticket / review → operator，同样不受影响。
- **`ops_ticket` 的触发事件是软引用的两列，不建外键。** `risk_event` 主键含分区键 ⇒ 引用需两列；而到期整分区 `DROP` 会让指向它的外键失效或阻塞裁剪。工单可能活得比它的触发事件更久，这被接受——`ops_ticket` 自身已记下 `kind` / `severity` / 时间。它的部分唯一索引兑现「同一账号在办至多一条工单」，判据与 `nickname_review` 那条逐字相同。
- **`operator_audit` 的 `context` 只装内部键与结果，绝不装昵称串、`note` 或任何个人信息。** 这是刻意设计出的性质：**「这张表含不含个人信息」决定它的保留期与是否进注销删除清单**。⇒ 保留 3 年、注销执行不删，与 `deletion_audit` 同判据；存 `account_id` 不破坏这一点。可关联到个人的载荷留在 `nickname_review` / `ops_ticket`（180 天 + 注销硬删）。

## 事务边界

每一行是一次事务；并发获取一律落在 `account` 行（`session` 自身的 rotation 除外）。

| 操作 | 同一事务内的写入 | 并发获取 |
|---|---|---|
| `signin` | ①先吊销该 `accountId` 下 `deviceId` ≠ 本次的全部会话 · ②后 upsert 本设备会话 · `signin_replay` 插入 ·（新账号时）建 `account` + `identity` + profile 骨架且 `revision = 1` | `SELECT … FOR UPDATE` on `account`；新账号靠 `identity` 唯一索引兜住并发建号 |
| `refresh` | `session.generation += 1`（旧值落 `prev_generation`、旧 `token_id` 落 `prev_token_id`）· `refresh_expires_at_utc` 顺延 · `absolute_expires_at_utc` **不动** | `SELECT … FOR UPDATE` on `session` |
| `signout` | 按 `sid` 标 `revoked_at_utc` / `revoked_reason` | `SELECT … FOR UPDATE` on `session` |
| `bind` / `unbind` | `identity` 增删 · profile 的 `/accountInfo/identities` 更新 · `revision += 1` | `SELECT … FOR UPDATE` on `account` |
| 实名兑付 `POST /compliance/realname` | ①条件更新 `compliance_ticket` 占位消费（`WHERE consumed_at_utc IS NULL`）并提交 · ②调核验（外部 HTTP，**不在事务内**）· ③第二次事务写核验结果与 `response_snapshot` | 受影响行数分支，无需行锁；②③ 之间崩溃 ⇒ 回 `server.unavailable`（`Retryable`），玩家重走 `signin` 取新 ticket |
| `POST /compliance/deletion` | `account_deletion` 的 `INSERT … ON CONFLICT (account_id) DO NOTHING`，`previous_status = account.status` | `SELECT … FOR UPDATE` on `account`；插入 0 行即回既有 `deletionEffectiveAtUtc` + `deduplicated`，**绝不顺延** |
| `POST /compliance/deletion/cancel` | 删除 `state='CoolingOff'` 的 `account_deletion` 行 · 同事务把 `account.status` 恢复为 `previous_status` · 落一条 `DeletionCancelled` 风控事件 | 同上；0 行且无行 ⇒ `204`（幂等）；行为 `Executing` / `Executed` ⇒ `compliance.deletion_irrevocable` |
| 复核领取 | 条件 `UPDATE nickname_review` 取租约（`SKIP LOCKED` 只在选行那一条语句内，事务立即提交）；`claimed_by` 取自本次内部请求已认证的凭据 | 无行锁跨人工时长 |
| 复核判定 | `nickname_review` 转终态 ·（判 `Violation` 时）一条 `NicknameViolation` 落 `risk_event` · `nickname_scan.review_state` / `reviewed_wordlist_version` 更新 · 一条 `operator_audit` | 条件 `UPDATE` 的受影响行数分支 |
| 工单处置 | `account.status` 更新 · 该账号全部会话吊销（`OperatorRevoked`）· `ops_ticket` 转终态 · 一条 `operator_audit` | `SELECT … FOR UPDATE` on `account`；**`baseAccountStatus` 与库内当前值不等即拒**，无任何写入（形态与理由见 `operations/internal-tools.md`） |
| 注销执行（周期任务） | 按数据类别逐表硬删（`identity` · 实名材料 · `profile` · `signin_replay` · `compliance_ticket` · `session` · `export_task` 与其对象 · `risk_event` · `nickname_review` · `nickname_scan` · `ops_ticket` · `push_idem`）· `account` 行降为墓碑 · `state='Executed'`；**`deletion_audit` 与 `operator_audit` 不在删除清单内**——两者的条目都不含个人信息，且它们正是这次删除与历次内部处置的举证依据；`operator` / `operator_identity` 与玩家删除路径无关，永不涉及 | `FOR UPDATE SKIP LOCKED` 领取，逐账号各自一次事务；**全有或全无**，中途崩溃即回滚，下一轮重新领取 |

`bind` / `unbind` 推进 `revision` 是通则的一例——后端对 profile 的任何写入都推进它（`contracts/profile-sync.md` §5）。profile 侧的写入形态见 `profile-store.md`。

### `signin` 的两步顺序：与契约伪码相反地执行（实现纪律）

契约 `auth.md` §4a 的伪码是「先写入本设备、后吊销其余」。**实现必须反过来：先吊销其余，再写本设备。** 用部分唯一索引兑现「活跃会话上限 1」时，先写入会在语句之间瞬时出现两行活跃会话而当场违反索引，而 PostgreSQL 的部分唯一**索引**不能声明为 `DEFERRABLE`。

两步在同一次事务内 ⇒ 中间态不可观测 ⇒ 反序不改变任何外部语义，**契约因此无需改动**；但伪码会被照抄，这条纪律必须与实现同处。

## `tokenId` 与 `sid` 的分工（承重）

会话行上有两个互不相同的标识，职责分离是刻意的：

| | `sid` | `tokenId` |
|---|---|---|
| 是什么 | **会话的标识**，服务端生成、随机不可枚举 | **当前这一代 refresh 凭据的标识**，随机不可枚举 |
| 出现在哪 | access token 的 JWT claims 内；`signout` 据此精确吊销一条 | refresh token 载荷的前半段 |
| 是否跨边界 | **绝不出现在任何报文字段里**（与 `channelUserId` / `idKind` 同一条纪律） | 只作为不透明 refresh 串的一部分出现，客户端不解析、无消费点 |
| 生命周期 | 一条会话一个；同设备重登原地替换时换新 | **每次 rotation 换新**，旧值落 `prev_token_id` |

**把 `sid` 直接放进 refresh 串是不可取的**：服务端内部键一旦跨边界就成了契约的一部分，而客户端对它没有任何消费点。分出 `tokenId` 的代价只是会话行上多一列，换来的是 refresh 凭据可被独立轮换、且内部键不外泄。

## refresh token 的形态：可重算的派生串

**载荷 = `<tokenId>.<mac>`**，其中 `mac = HMAC-SHA256(refreshSecret[kid], tokenId ‖ generation)` 截断编码。**`generation` 不上报文。**

它满足契约对 refresh token 的全部要求——不透明、高熵不可预测、必须查库才能吊销（服务端仍要读会话行判定吊销态与到期）——同时让「回放完全相同的那一对 token」不必缓存任何活凭据。

**校验流程**（求值顺序照 `auth.md` §4 写死，先判到期、再判宽限回放）：

```
按 tokenId 查 session 行（查不到 → auth.session_revoked，reasonKey = SessionExpired）
  ├─ 用当前 generation 重算 mac，命中 → 正常 rotation
  ├─ 用 generation - 1 重算 mac，命中且在 60 秒宽限窗口内 → 回放上次那一对，不再轮换
  ├─ 用 generation - 1 重算 mac，命中但已出窗口 → 判泄漏 → 吊销该账号全部会话（TokenReuseDetected）
  └─ 均不命中 → 判泄漏 → auth.session_revoked，reasonKey = TokenReuseDetected（代次更旧即重放，见下）
```

**`tokenId` 查不到时无会话行可读**，`detail.revokedAtUtc` 取本次判定时刻（服务端时钟，`operations/compliance-ops.md` 的可信时钟基准），`detail` 形状因此恒定可填。取值与三种情形的合并判据见 `contracts/auth.md` §10。

- **不缓存明文。** 宽限回放靠重算，而不是把上一代活凭据存活 60 秒——那既是一份可被读取的活凭据，又会让弱网重试的玩家在缓存失效时被赶回验证码输入框。
- **`prev_token_id` / `prev_generation` 两列是分辨两种失败的凭据。** 同设备重登原地替换后，旧凭据带着已被替换掉的 `tokenId` 到达：查得到前一代 ⇒ 判 `SessionSuperseded`；查不到任何一代、或代次更旧 ⇒ 判 `TokenReuseDetected`。没有这两列，两者在服务端不可分辨，而契约要求 `SessionSuperseded` 有确定的取值、不能落进兜底文案。
- **`refreshSecret` 的 `kid` 落 `refresh_key_id`**，轮换时旧 secret 保留至最长 refresh 链自然到期（绝对寿命上限）。密钥保管与轮换见 `operations/environments.md`。

## access token 的签发

- **自包含 JWT，算法 EdDSA（Ed25519）。** 签名确定性（同输入同输出）是「回放完全相同的那一对 token」的前提；ECDSA 因签名含随机 `k` 不满足这一点。非对称使网关可用公钥离线验签，私钥只在签发侧。
- **`iat` / `exp` 从会话状态派生，不从 `now` 取**——否则同一次回放会产出字节不同的 token。
- **JWT header 带 `kid`**；未知 `kid` 的处置已在错误码台账内（`contracts/envelope.md` §6）。它与内容 manifest 的 `keyId` 是两套命名空间。
- **签名在进程内完成**，私钥只在内存；KMS 只保管被包裹的私钥，不在签发热路径上。理由与代价见 `operations/environments.md`。

## 渠道能力的适配层

短信 / 邮件 / 实名核验 / 第三方渠道换 openid 都是外接的原子能力，后端内部各有一个稳定接口使服务商可换（契约已定）。两条实现纪律：

- **服务商错误码不上契约面**——一律先归一到本库已有的 `code`，**按调用点所在域取**（auth 域的调用点归 auth 域的 `code`，合规域的归 `compliance.*`）；渠道原始码只随日志上报。归一映射的唯一一份权威表在 `operations/external-providers.md`，本文件不复述。
- **「明确拒绝」与「服务不可达」必须在归一时就分开**，这是 `auth.md` §3a 的映射表，不是适配层可以合并的两类。**适配层自身不认识 `code`**：它只产出判别式 `Outcome`，归一到 `code` 发生在调用方（端点），使换一家服务商不必重读错误码台账。

适配接口的形状要求、四个签名与硬超时、多供应商灾备与切换、选型判据与凭据托管见 `operations/external-providers.md`。

Source: `handoffs/2026-09-03-backend-stack-and-hosting.md` · `handoffs/2026-09-07-refresh-expiry-reasonkey.md`（refresh 校验流程两处叶子的 `reasonKey`）· `handoffs/2026-09-08-risk-ledger-storage-shapes.md`（四张台账的承重列 · 注销执行的删除清单）· `handoffs/2026-09-09-internal-ops-tools-and-operator-identity.md`（内部工具面四张表的承重列 · 三行事务边界 · `claimed_by` 的取值域与外键）。

## 昵称判定链与存量扫描的服务内部形态

`POST /v1/auth/nickname` 的判定是同步、即时、幂等的（auth 域纪律），**五级求值、四级短路**，第一个失败级决定 `reasonKey`：

```
① 形态校验（本地 · 确定性 · 用原串）    失败 → auth.nickname_rejected { reasonKey: "Malformed" }
② 频次校验（本地 · 计数）              失败 → auth.nickname_rejected { reasonKey: "TooFrequent" }
                                       nicknameChangeRequired 为真 ⇒ 跳过本级的拦截（仍照常计数）
③ 词表判定（本地 · 版本化配置 · 用归一化串）
                                       命中「禁止级」→ auth.nickname_rejected { reasonKey: "SensitiveWord" }
                                       命中「复核级」→ 落 ⑤
④ 第三方审核适配器（可选 · 外接）       判「拒绝」→ SensitiveWord ；判「待复核」→ 落 ⑤ ；不可达 → 落 ⑤
⑤ 接受                                 204，并按需入复核队列（accept-then-review）
```

- **顺序不可颠倒。** 它使「既超长又含敏感词」这类输入的应答唯一（`Malformed`），验收断言因此无歧义；同时把唯一有外部成本的一级放在最后，被频次闸挡住的刷子不产生外部调用。
- **本端点只判定、不写 profile。** 昵称的真值是玩家输入，由客户端经既有 push 通道写入 `/accountInfo/nickname`。
- **归一化只用于词表匹配**：NFKC 规范化 → 剥离零宽 / 控制 / 变体选择符 → 大小写折叠 → 繁简折叠 →（可选）同形字与拼音变体折叠。长度与字符集判定用原串。
- **频次计数只对被接受的一次改名 `+1`**；重复提交同一昵称回 `204` 且不消耗配额。
- **处于「须改名」档的账号豁免频次闸的拦截，不豁免计数。** 该档的解除路径就是走一次改名流程（`operations/moderation.md` 处置阶梯），若他此前刚用尽配额，处置阶梯与频次闸会互相锁死且无自解通道——那是我方自己制造的死锁。照常 `+1` 使解除后立刻再刷仍会被挡住。
- **适配器不可达按「待复核」接受**，不返回 `SensitiveWord`——把外部抖动伪装成明确拒绝会让玩家以为自己的昵称违规。

**栈中立的服务端保证**（阈值一律参数化，落定后可直接转为验收用例）：

| # | 输入 | 期望 |
|---|---|---|
| N1 | 合法昵称、频次未超、未命中词表 | `204`；profile 不变 |
| N2 | 命中禁止级词表 | `SensitiveWord`；改名计数**不 `+1`** |
| N3 | 在同一禁止词中插入零宽空格 / 改全角 / 改繁体 | 同 N2（归一化生效） |
| N4 | 超出长度上界，或含控制字符 | `Malformed` |
| N5 | 同时超长且命中禁止词 | `Malformed`（短路顺序断言） |
| N6 | 频次已达上界，且 `nicknameChangeRequired` 为假 | `TooFrequent` |
| N6b | 频次已达上界，但 `nicknameChangeRequired` 为真 | `204`；计数照常 `+1` |
| N7 | 重复提交同一昵称 | `204`，不消耗频次配额 |
| N8 | 命中复核级词表 | `204`，复核队列新增一条（`accountId` · 提交串 · 词表版本 · `requestId`） |
| N9 | 第三方适配器不可达（启用时） | `204` + 入复核队列，不返回任何错误 |
| N10 | 未鉴权调用 | 本端点必带 `Authorization`，无例外 |

**存量扫描的服务端保证**（触发源、扫描台账与处置阶梯见 `operations/moderation.md`）：

| # | 输入 | 期望 |
|---|---|---|
| S1 | push 的 `playerDiff` 含 `accountInfo`，`nickname` == 该账号最近一次经端点接受的值 | 接受，无风控事件 |
| S2 | 同上但不等 | **接受写入**（不拒绝、不改写）+ 一条 `NicknameBypassed` 事件 + 入复核队列 |
| S3 | 新词表版本发布 | `reviewedWordlistVersion` 落后的账号进入重扫队列；已是最新版本的账号不重扫 |
| S4 | 存量扫描判定违规 | 一条 `NicknameViolation` 事件 + 按处置阶梯落 `nicknameChangeRequired`；**`/accountInfo/nickname` 在云端一字不变** |
| S5 | 处置置 `status = restricted` / `banned` | 该账号全部会话被吊销，下次 `refresh` 得 `auth.session_revoked` + `OperatorRevoked`；下次 `signin` 得 `compliance.account_restricted` |

改名频次阈值的初值与推导在 `contracts/auth.md` §8；第三方审核适配器的阈值形态在 `operations/moderation.md`，服务商侧接口与灾备在 `operations/external-providers.md`。

Source: `handoffs/2026-09-03-nickname-moderation-and-risk-control.md` · `handoffs/2026-09-06-external-provider-selection-dr.md`。

## 合规域的服务端保证

阈值一律参数化，落定后可直接转为验收用例；与上方 N1–N10 / S1–S5 同体例。运维形态（存储、调度、产物、降级）见 `operations/compliance-ops.md`。

| # | 输入 | 期望 |
|---|---|---|
| C1 | 首次以有效 ticket 调 `POST realname` | `200` + `realnameStatus`；`consumed_at_utc` 落值；核验服务被调用**一次** |
| C2 | 同一 ticket 在 60 秒内重复调 | **逐字相同的应答**；核验服务不再被调用；无任何写入 |
| C3 | 同一 ticket 在 60 秒后重复调 | `compliance.ticket_invalid` + `Consumed` |
| C4 | 超出 10 分钟寿命且从未消费 | `compliance.ticket_invalid` + `Expired` |
| C5 | 以 `Realname` 用途的 ticket 调 `deletion/cancel` | `compliance.ticket_invalid` + `Unknown` |
| C6 | 任何路径下 | `realName` / `idNumber` 不出现在任何应答、日志与 `response_snapshot` 中 |
| D1 | 冷静期内 `POST deletion` 第二次 | `deduplicated: true`，`deletionEffectiveAtUtc` 与首次逐字相同 |
| D2 | `restricted` 账号申请注销后撤销 | `204`；`account.status` 恢复为 **`restricted`**（不是 `active`） |
| D3 | 从未申请过注销时调 `cancel` | `204`（幂等） |
| D4 | 执行已开始 / 已完成后调 `cancel` | `compliance.deletion_irrevocable` |
| D5 | 执行进程在删除中途被杀 | 全部回滚；下一轮重新领取并完成；无半删账号 |
| D6 | 两个容器同时跑到期扫描 | 每个到期账号**恰好被执行一次** |
| D7 | 注销执行完成后 | `receipt_idem` 该账号的行**仍在**；`identity` / `profile` / 实名材料 / 风控事件已删 |
| E1 | 并发两次 `POST export` | 只建一个任务；两次 `taskId` 相同，其一带 `deduplicated: true` |
| E2 | `GET export/{taskId}` 连查两次（`Ready` 态） | 两次 `downloadUrl` **不同**（各自新签），`downloadExpiresAtUtc` 相同 |
| E3 | 预签名 URL 超出单次有效期后访问 | 对象存储拒绝；重新 `GET` 即得新链接 |
| E4 | `taskId` 不属于当前账号 | `resource.not_found` |
| E5 | 产物到 7 天 | 对象已删、`state = 'Expired'`；记录仍在直到 30 天 |
| E6 | 产物 JSON | 顶层键集合恒为 `{ profile, account }` |
| P1 | 某本地日期同时命中日历的 `WorkingWeekend` 与 `StatutoryHoliday` | 判**不可玩**——四步判定顺序写死，`WorkingWeekend` 排最前（减法优先） |
| P2 | 已判未成年账号在允许时段 `signin` | 签发的 access token TTL = `min(15 分钟, 距时段结束的剩余秒数)`；不新增任何报文字段 |
| P3 | 已判未成年账号在会话中途走出允许时段并 `refresh` | 吊销该账号全部会话 + `auth.session_revoked` + `reasonKey = "PlaytimeEnded"`；`refresh` 的错误清单仍只有两条 |
| P4 | 时段规则集读取失败 或 日历已过期，账号已判未成年 | fail-closed：`compliance.playtime_blocked` + `MinorCurfew` |
| P5 | 同 P4 的失败面，账号为**成年** | 不做时段判定，**应答不受任何影响**；且该降级路径下 `compliance.playtime_blocked` 的 `detail.resumeAtUtc` 取兜底周规则算出的下一个允许时段起点（可能晚于实际可玩时刻，方向保守、形状完整） |

P1–P5 是时段判定在服务内部的保证面，与 `operations/compliance-ops.md` 的运维形态一一对位；未成年判定的数据源恒为实名核验回传的出生日期，服务端不单独存年龄。

Source: `handoffs/2026-09-06-compliance-domain-storage.md` · `handoffs/2026-09-07-compliance-launch-tiering.md`（P1–P5）。
