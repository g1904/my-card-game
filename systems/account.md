# account —— 账号 · 身份 · 会话（服务内部设计）

对位客户端的 `account-service`。**边界报文的权威在 `contracts/auth.md` 与 `contracts/compliance.md`，本文件不复述报文**，只写后端内部如何兑现它们：数据怎么存、并发怎么串行、凭据怎么算、密钥怎么用。

公共的存储与并发前提（单库 PostgreSQL · 并发单元 = `account` 行 · 约束即不变式）见 `_index.md`，此处不重复。

## 存储形态：承重列

只列承重列与约束，不是完整 DDL。

```
account        (account_id PK, created_at_utc, status)

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
```

- `identity` 的两条唯一约束分别兑现「一个渠道身份只属于一个账号」与「一个账号在同一渠道最多一条 identity」（`contracts/auth.md` §1a）。
- `session` 的部分唯一索引兑现「单账号活跃会话上限 1」，普通唯一约束兑现「同设备重登是原地替换、不产生第二条记录」。**两条都要留**，理由在契约侧已写明。
- `signin_replay` 的键含手机号 / 邮箱这类个人信息，故以 `identifier_mac = HMAC(identifierSecret, identifier)` 存储，**明文绝不落库、绝不落日志**。它需要与会话写入同一事务（否则会出现「回放了但会话没落」或反之），因此放关系库而不是缓存。行保留 10 分钟后清理即可（窗口 60 秒 + 余量），不必分区。

## 事务边界

每一行是一次事务；并发获取一律落在 `account` 行（`session` 自身的 rotation 除外）。

| 操作 | 同一事务内的写入 | 并发获取 |
|---|---|---|
| `signin` | ①先吊销该 `accountId` 下 `deviceId` ≠ 本次的全部会话 · ②后 upsert 本设备会话 · `signin_replay` 插入 ·（新账号时）建 `account` + `identity` + profile 骨架且 `revision = 1` | `SELECT … FOR UPDATE` on `account`；新账号靠 `identity` 唯一索引兜住并发建号 |
| `refresh` | `session.generation += 1`（旧值落 `prev_generation`、旧 `token_id` 落 `prev_token_id`）· `refresh_expires_at_utc` 顺延 · `absolute_expires_at_utc` **不动** | `SELECT … FOR UPDATE` on `session` |
| `signout` | 按 `sid` 标 `revoked_at_utc` / `revoked_reason` | `SELECT … FOR UPDATE` on `session` |
| `bind` / `unbind` | `identity` 增删 · profile 的 `/accountInfo/identities` 更新 · `revision += 1` | `SELECT … FOR UPDATE` on `account` |

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
按 tokenId 查 session 行（查不到 → auth.session_revoked）
  ├─ 用当前 generation 重算 mac，命中 → 正常 rotation
  ├─ 用 generation - 1 重算 mac，命中且在 60 秒宽限窗口内 → 回放上次那一对，不再轮换
  ├─ 用 generation - 1 重算 mac，命中但已出窗口 → 判泄漏 → 吊销该账号全部会话（TokenReuseDetected）
  └─ 均不命中 → auth.session_revoked
```

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

- **服务商错误码不上契约面**——一律先归一到本库已有的 `code`（`rate.limited` / `auth.credential_invalid` / `auth.challenge_expired` / `server.unavailable`），渠道原始码只随日志上报。
- **「明确拒绝」与「服务不可达」必须在归一时就分开**，这是 `auth.md` §3a 的映射表，不是适配层可以合并的两类。

具体服务商与多供应商灾备策略仍待选定（`open-questions/06-platform-stack.md`）。

Source: `handoffs/2026-09-03-backend-stack-and-hosting.md`。

## 昵称判定链与存量扫描的服务内部形态

`POST /v1/auth/nickname` 的判定是同步、即时、幂等的（auth 域纪律），**五级求值、四级短路**，第一个失败级决定 `reasonKey`：

```
① 形态校验（本地 · 确定性 · 用原串）    失败 → auth.nickname_rejected { reasonKey: "Malformed" }
② 频次校验（本地 · 计数）              失败 → auth.nickname_rejected { reasonKey: "TooFrequent" }
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
- **适配器不可达按「待复核」接受**，不返回 `SensitiveWord`——把外部抖动伪装成明确拒绝会让玩家以为自己的昵称违规。

**栈中立的服务端保证**（阈值一律参数化，落定后可直接转为验收用例）：

| # | 输入 | 期望 |
|---|---|---|
| N1 | 合法昵称、频次未超、未命中词表 | `204`；profile 不变 |
| N2 | 命中禁止级词表 | `SensitiveWord`；改名计数**不 `+1`** |
| N3 | 在同一禁止词中插入零宽空格 / 改全角 / 改繁体 | 同 N2（归一化生效） |
| N4 | 超出长度上界，或含控制字符 | `Malformed` |
| N5 | 同时超长且命中禁止词 | `Malformed`（短路顺序断言） |
| N6 | 频次已达上界 | `TooFrequent` |
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

改名频次阈值与第三方审核服务商 / 评分阈值归 `open-questions/06-platform-stack.md`。

Source: `handoffs/2026-09-03-nickname-moderation-and-risk-control.md`。
