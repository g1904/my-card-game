# auth —— 登录 · 会话 · token 续期与吊销

> 覆盖 `/v1/auth/…` 七个端点的报文本体。**边界层不在此重复**：序列化与命名约定、`/v1/` 主版本、传输信封、错误体形状、错误码台账、版本协商——全部见 `envelope.md`，本文件只写 auth 域**相对它的差异与例外**。
> 客户端侧门面见 `game-design-documents/systems/services/account-service.md`（那里描述**客户端怎么用**；此处描述**报文长什么样**）。
> Source: `handoffs/2026-08-13-auth-endpoint-contract.md` · `handoffs/2026-08-16b-account-identity-model.md` · `handoffs/2026-08-16c-compliance-contract-and-session-arbitration.md`。

## 1. 端点集：七个

```
POST /v1/auth/challenge   请求一次性验证码（短信 / 邮件）      —— 无鉴权
POST /v1/auth/signin      渠道登录，换取会话                   —— 无鉴权
POST /v1/auth/refresh     用 refresh token 换新 access token   —— 无鉴权（凭据在 body）
POST /v1/auth/signout     主动登出，吊销当前会话                —— 需鉴权
POST /v1/auth/bind        绑定一个渠道到当前账号                —— 需鉴权
POST /v1/auth/unbind      解绑一个渠道                         —— 需鉴权
POST /v1/auth/nickname    提交昵称，由服务端判定接受 / 拒绝      —— 需鉴权
```

`signin` / `refresh` / `signout` 与 `account-service` 的同名 B 形态方法一一对位；`challenge` / `bind` / `unbind` / `nickname` 对位客户端新增的四个方法。

**`challenge` 不是 `signin` 的内部实现，是它的前置一步。** 手机 / 邮箱登录必然是「先下发验证码、再提交验证码」的两步握手，UI 需要在两步之间停留（输入框 + 倒计时），单个 `signin` 端点表达不了。

**密码路线整体后置（§3），不为它预留端点空壳**（本库「先有设计再建文件」）。

**不设 `/v1/auth/me`。** 账号身份元数据在 `AccountInfo`，它是 `PlayerProfile` 的账号级字段，随 `/v1/profile/pull` 整聚合下行。另立一个身份查询端点会当场造出第二份真值——**绑定列表同样走这条路**（`profile-sync.md` §5 的后端写入表第三行），客户端因此不需要任何 auth 域的读取端点。

**绑定 / 解绑 / 改名进本契约，不单开一份文档。** 它们用同一套 `credential` 判别式、同一套会话、同一个域；分开会让 `oneOf` 在两份文档各写一遍。

## 1a. 身份模型：account ↔ identity 一对多（承重）

```
account  ──1───n──  identity
```

| 实体 | 字段 | 说明 |
|---|---|---|
| `account` | `accountId` · `createdAtUtc` · `status` | `accountId` 是 profile 主键 |
| `identity` | `accountId` · `channel` · `channelUserId` · `idKind` · `boundAtUtc` | 唯一约束在 `(channel, channelUserId)` |

- **一个 `account` 在同一 `channel` 下最多一条 identity。** 多绑同渠道无玩家价值，却让解绑语义与找回路径分叉。
- **`signin` 的语义由此确定**：校验 `credential` → 取得 `(channel, channelUserId)` → 查 identity。命中 → 取其 `accountId`；未命中 → 建 account + identity + profile 骨架（含 `accountSeed`、`createdAtUtc`），应答 `isNewAccount: true`。**§8 的 signin 报文一字不改。**
- **建号先于合规判定，合规拦截不回滚建号：**

  ```
  校验 credential → 取 (channel, channelUserId) → 查 identity
    命中   → 取 accountId
    未命中 → 建 account + identity + profile 骨架，isNewAccount = true
  → 合规判定（status / 实名 / 时段）
    通过   → 签发 token 对（会话裁决见 §4a）
    不通过 → 返回 compliance.*（账号已存在，不回滚）
  ```

  **实名不是建号的前置。** 那意味着一个尚无 `account` 的人要先提交实名信息，而那份信息只能挂在 identity 或某个临时态上——当场造出「半个账号」，并把上一条定的**原子建号**拆成两步。建号本身不泄漏任何东西：`accountId` 随机不可枚举、不含个人信息；一个建了却拿不到 token 的账号对外无任何可见面。合规域的落地见 `compliance.md`。
- **`channelUserId` 与 `idKind` 是服务端内部键，不出现在任何报文里**，也不写进玩家可导出的存档。
- **`status`（`active` · `restricted` · `banned` · `pendingDeletion`）同样不跨边界。** 它的客户端表现全部由 `signin` 应答分支与 `compliance.*` 承载；下发一份副本没有消费点，且会在会话中途过期（封禁发生时客户端那份仍写着 `active`）。它是 `02` 的三条待答项（合规分级 / 多设备裁决 / 风控处置）共用的挂接点——三者读写同一个字段，而不是各立一套「是否可玩」的真值。

**⚠ 承重：绝不做隐式账号合并。** 同一个人先用手机号登录、再用微信登录，会得到**两个** account、两份存档，**这是正确行为**。想合并只能由**已登录态**主动 `bind`，且目标渠道未被占用；已被占用 → 明确报 `auth.identity_already_bound`，**不静默转移 identity**。云端权威下一账号一份 profile，静默合并必然要丢弃其中一份存档，而玩家不会预期一次登录会删掉自己的进度。

**`accountId` 的形态：随机、不可枚举、不含个人信息**（ULID / 26 位 base32 一类），终身不变。不用自增整数（对外泄漏注册规模与先后，且可被枚举探测）；不用手机号 / openid（个人信息进主键，PIPL 面直接放大，且换渠道即换键）。

## 2. token 模型：短寿 access + 长寿 refresh

**双 token 是「静默刷新」这条已定客户端语义的必要条件，不是一个选项。** 单 token 模型下服务端要么接受过期 token（等于它没有过期），要么拒绝（那就没有静默刷新，只剩重登）。因此必须有一个与 access token 分离、寿命更长、**只用于换取 access token** 的刷新凭据。

| | access token | refresh token |
|---|---|---|
| 形态 | **自包含 JWT**（网关可离线验签） | **不透明随机串**（必须查库才能吊销） |
| claims | 含 `sid`（会话 id）——`signout` 据此精确吊销一条，见 §4a。**不进任何报文字段** | — |
| 用途 | 每个 API 请求的 `Authorization: Bearer` | **只用于** `POST /v1/auth/refresh` |
| 客户端对位 | `Session.Token` / `Session.ExpiresAtUtc` | **不进 `Session`**，见下 |
| TTL | **15 分钟**（初值，见 §8）；未成年账号收窄为 `min(15 分钟, 距时段结束剩余)`（`compliance.md` §7） | **30 天滑动续期**（初值） |
| 失效时的 `code` | `auth.token_expired` | `auth.session_revoked` |

**access token 自包含的代价与兜底：**「被挤下线」的最坏生效延迟 = access token TTL。窗口内旧设备的 push 由 `revision` CAS 拒绝（`sync.conflict`），**云端不会被污染**，代价只是旧设备丢一次本地缓冲——这正是既定的 conflict 处置。多设备并发在本作是罕见路径（单人游戏、无跨玩家交互），为它给 profile push 这条最热的路径加一次中心校验读不划算。

**本表的 TTL 论证同时覆盖未成年时段收窄。** 「服务端单方面终止会话，最坏延迟 = access token TTL」这条推理与触发原因无关——被挤下线与防沉迷到点是同一种事件的两个触发源，本就该走同一条路。把 TTL 卡在时段边界，使时段到点的强制下线精度为 0，而无需任何新通道（`compliance.md` §7）。

**`Session` record 一字不改。** refresh token 由客户端的 `HttpAccountBackend` 内部持有并落 `user://cache/`，与 `SyncEnvelope`（`baseRevision` 落 `user://cache/sync-envelope.json`）**同构**——都是传输层元数据，不进 Profile、不进存档 schema、不参与迁移，且同样适用「切账号即失效」的必需缺失处置。这条同构不是巧合：两者都是「客户端持有、后端定义、与玩法无关」的凭据。

## 3. 登录报文：`channel` + 按渠道分形的 `credential`

`channel` 取值与客户端 C# `LoginChannel` 枚举名**逐字相同**（`"Phone"` / `"Email"` / `"WeChat"` / `"QQ"`，`envelope.md` §2）。**四个渠道走同一个端点**，靠 `credential` 的判别式（OpenAPI 3.1 的 `oneOf` + `discriminator`）分形。

不为每个渠道立独立端点：渠道优先级**会扩张**（`game-design-documents/decisions/ADR-0003` 的第三档「海外 / 跨平台」尚未展开），每加一个渠道就加一个端点会让端点集随渠道数线性增长，而它们的**应答形态完全相同**。

**首版 `credential` 只有两类形态：**

| 类 | 渠道 | 形态 |
|---|---|---|
| 标识符 + 一次性验证码 | `Phone` · `Email` | `{ phone \| email, code }` |
| 渠道一次性授权码 | `WeChat` · `QQ` | `{ authCode }` |

**`Email` 走验证码，密码后置。** 两个自建渠道共用同一种 credential 形态，密码路线整体推迟到账号体系成熟后再议——由此免掉密码存储与强度策略、找回、改密这一整条链路，它们各自都要端点、都要合规面，而首版并不需要。密码届时是**加**第五种 `credential` 分形 + 相应端点，**不推翻本契约的任何一条**。

**首版上线两个渠道：`Phone` + `WeChat`。** Phone 是 ADR-0003 的首选且是实名 / 找回的天然载体，WeChat 覆盖面最大。**契约不因此改动**——四种 `credential` 分形照旧存在，只是首版不实现 `Email` / `QQ` 两条路径，服务端对它们返回 `auth.channel_rejected`。

> **不实现 ≠ 从契约删除。** 删掉再加回是一次破坏性契约变更，而追加实现不是。`QQ` 与 `WeChat` 共用同一套 `authCode` 形态，追加时**只增实现不增契约面**；`Email` 留到第三档海外渠道展开时一并考虑。

### 3a. 第三方渠道换取 openid：三条后端义务

第三方渠道（`WeChat` / `QQ`）走 `authCode`：客户端 SDK 拿到一次性授权码交给后端，**后端向渠道服务器换取 openid**。**契约层只声明后端义务与错误映射**，渠道 API 的具体调用形态归 `operations/`——它随渠道文档变动，写进契约会让契约跟着渠道版本漂。

1. **客户端只交 `authCode`，永不接触渠道 secret。** 与 `account-service` 的定位「平台 SDK 与后端鉴权的唯一门面」一致。
2. **`channelUserId` 取跨应用统一标识，无则取应用内标识**，并在 identity 上记 `idKind ∈ { openid, unionid }`。**首版即申请微信开放平台、以 `unionid` 建 identity**——这条是**不可逆的**：以 per-app 的 `openid` 建立的 identity，在日后新增第二个应用（小程序 / H5 / 第二款产品）时会分裂成两个身份，届时统一需要一次全量身份迁移；代价只是一次资质申请，**且必须在首个玩家建号之前完成**（落发布前置清单，归 `operations/`）。`idKind` 字段仍保留——它承载「这条 identity 当初以哪种标识建立」这一事实，而第三档海外渠道未必都有统一标识。
3. **渠道错误分两类映射，且必须在报文层面可区分：**

   | 渠道侧情形 | `code` | `class` | `detail` |
   |---|---|---|---|
   | **明确拒绝**（authCode 无效 / 过期 / 应用被封） | `auth.channel_rejected` | `Fatal` | `{ channel, channelCode }`，`channelCode` 为渠道原始错误码**原样透传** |
   | **服务不可达 / 超时 / 限流**（我方无从判定凭据真伪） | `server.unavailable` | `Retryable` | — |

   **把第二类也报成 `channel_rejected` 是一个具体的缺陷**：它是 `Fatal`，客户端会把一次渠道抖动当成终态、让玩家重走登录流程。这与 `purchase.md` §3「平台服务不可达须与『收据无效』在报文层面可区分」是同一条，理由同源。
   **`channelCode` 客户端不解析、只随日志上报**（与 §5a「客户端不得解析 `message` 做分支」同构）——渠道原始码是渠道版本的产物，任何依赖它的分支都会在渠道更新时静默失效。

## 4. 刷新：rotation + 60 秒宽限窗口（承重）

**启用 refresh token rotation**：每次刷新返回新的 refresh token、旧的立即失效；已被使用过的 refresh token 再次到达 → 判定为泄漏 → 吊销该账号全部会话。

**但裸 rotation 与 pillar #2 直接冲突，因此必须带宽限窗口。**「刷新请求已达、应答丢失」在移动网络下是常态：客户端仍持旧 refresh token 重试 → 被判重放 → 全账号吊销 → 玩家在轮回中途被硬踢下线。

**定案：旧 refresh token 在被轮换后的 60 秒内仍可被接受，且返回与上次相同的那一对新 token**（幂等回放，不再轮换）；**窗口外**再次出现 → 才判泄漏并吊销该账号全部会话。

> 这与 `pushId` 的「重复到达不再 `+1`，直接回上次结果」是**同一个模式，理由同源**——auth 域的幂等与 sync 域的幂等是同一条 pillar #2 在两个端点上的兑现，不是两套机制。

## 4a. 会话裁决：单账号一条活跃会话（承重）

**裁决策略 = 后登录挤下线。** 这不是一个独立取向：§2 那段「窗口内旧设备的 push 由 `revision` CAS 拒绝」的论证**只有在这一裁决下才成立**——另两个选项（拒绝后登录 / 双活并存）都不会产生「旧设备在窗口内继续 push」这一情形。

### `sid`：会话的标识

`POST /v1/auth/signout` 需鉴权、无 body，语义是「吊销当前会话」。请求里唯一的身份材料是 access token；若它只带 `accountId`，服务端无从知道「当前会话」是哪一条，`signout` 只能退化为「吊销该账号全部会话」——那会把另一台设备一并踢下线，凭空造出一次硬阻塞，与「主动登出」的玩家预期完全不符。

**access token 的 JWT claims 含 `sid`**（服务端生成、随机不可枚举），`signout` 按 `sid` 精确吊销一条。**`sid` 不出现在任何报文字段里**，只存在于 token claims 中——与 `channelUserId` / `idKind` 同一条纪律（§1a），客户端无消费点。

### 会话记录

会话表以 **`(accountId, deviceId)` 为唯一键**，且一个账号在任一时刻**只有 1 条活跃会话**。

| 字段 | 说明 |
|---|---|
| `sid` | 会话 id；进 access token claims，**不进任何报文字段** |
| `accountId` | — |
| `deviceId` | 客户端自报；**唯一约束 `(accountId, deviceId)`** |
| `refreshTokenHash` | 不存明文 |
| `issuedAtUtc` · `refreshExpiresAtUtc` | — |
| `revokedAtUtc` · `revokedReason` | 吊销时间与原因；`revokedReason` 即下行的 `reasonKey`（§10） |

**上限 1 与唯一约束是两条独立的约束，都要留。** 上限 1 保证「异设备登录即挤掉」；`(accountId, deviceId)` 唯一保证「同设备重登不产生第二条记录」。只有后者时，同设备的历史记录仍会以 `revoked` 态堆积；只有前者时，同设备重登会先建后删、留下一个可观测的假「挤下线」。

**上限取 1 而非 2 + LRU 挤出**：客户端全部既定语义（`auth.session_revoked` 的存在、阻塞屏「被挤下线」变体、`sync-service` 的 CAS 冲突叙事）都建立在「同时只有一个活跃写入方」之上。放宽到 N 台会让 `sync.conflict`（既定处置 = **丢弃本地缓冲**）从异常路径变成常态，即「在 A 设备打完的一场战斗被 B 设备抹掉」成为日常。代价是双端玩家换设备要重登一次，这是被接受的取向。

### 求值顺序

```
校验 credential → 取得 (channel, channelUserId) → 查 identity → 得 accountId
  ├─ 60 秒内已有同 (channel, 凭据标识符, deviceId) 的成功登录
  │     → 原样回放上次的 token 对，不签发、不吊销，结束
  ├─ 写入 (accountId, deviceId) 的会话记录
  │     存在则原地替换 sid 与 refresh token，旧记录标 SessionSuperseded
  └─ 吊销该 accountId 下 deviceId ≠ 本次的全部会话，标 SignedInElsewhere
  ※ 后两步在同一次事务内 —— 半吊销态会让玩家被踢却仍能刷新，或反之
```

**同一 `deviceId` 重登 = 原地替换，旧 refresh token 立即失效。** 与 §4 的 rotation 纪律同向：同一凭据链上永远只有最新的一对有效。让旧会话并存到自然过期，会使同账号同设备最长 30 天存在两对有效 token，并让「该账号有几条活跃会话」不再是一个可用于风控的数。

触发 `SessionSuperseded` 的是罕见路径（清缓存后重登、换绑渠道后重登时旧进程仍在跑）；正常的弱网重试落在下方的回放窗口内，**不产生**吊销、**不产生**任何 `reasonKey`。

### `signin` 的幂等 = 60 秒回放窗口

§7 要求「`signin` 的重试必须能被安全重放」但未给机制，而**一次性凭据天然反幂等**：验证码在首次请求时即被消费，客户端拿同一个 `code` 重试 → `auth.challenge_expired` → 玩家被赶回验证码输入框重来一遍，而他刚刚其实已经登录成功了。第三方渠道的 `authCode` 形态完全相同。

**一次 `signin` 成功后的 60 秒内，同一 `(channel, 凭据标识符, deviceId)` 的重复请求返回与上次完全相同的那一对 token**，不重新签发、不重新吊销任何会话。窗口外再用同一个凭据 → 照常 `auth.challenge_expired` / `auth.credential_invalid`。

窗口取 60 秒，与 §4 的 refresh 宽限窗口**同值同理由**：覆盖客户端指数退避的头几次重试。这与 `pushId` 的重放回放是同一模式的第三次兑现。

> **回放窗口是「替换」得以成立的前提，两条必须一起成立。** 只取替换、不取回放窗口，弱网重试的玩家会在登录成功后被赶回验证码输入框。

### `deviceId` 的定位

**`deviceId` 只做裁决与观测的输入，永不参与鉴权。** 它是客户端自报、可任意伪造的字符串：不得用它做设备绑定、不得用它放宽任何校验、不得因它不匹配而拒绝一次凭据有效的登录。用它做安全判定是假安全，真实后果是换机 / 重装的玩家被挡在门外；而伪造它的收益仅仅是「不挤掉自己的另一台设备」，无攻击面。

**对它的两条要求**（生成与持久化落点归客户端）：**跨启动稳定** · **不同安装实例之间不得碰撞**。重装后 `deviceId` 变化可接受——旧会话记录在该设备上已不存在，挤掉它无玩家可见后果。

### 移交实现层的三项

契约层只声明语义，实现归 `operations/`（与 `profile-sync.md` 把 CAS / 幂等记录的存储移交 `06` 同一条纪律）：会话记录的存储形态与 `(accountId, deviceId)` 唯一约束的并发语义 · 「吊销其余会话」与「写入本设备会话」的同事务保证 · `signin` 幂等回放记录的存储与保留期（可与 `(accountId, pushId)` 幂等记录同处）。

## 5. 强更闸门只在 `signin` 判定，`refresh` 不判定（承重）

`envelope.md` §7b 已定「闸门在签发 token 时判定一次，会话期内不因阈值提升而中途变严」。`refresh` 也签发 access token，若它也判定闸门，运营提升 `minAppVersion` 就会在**会话期内**把玩家踢出——直接违反 §7b 的实现语义与「仅两处硬阻塞」。

- `POST /v1/auth/signin` → 可返回 `client.version_unsupported`（`class: Upgrade`）。**这是协议维度强更闸门在 auth 域的唯一落地点。**
- `POST /v1/auth/refresh` → **永不**返回 `client.version_unsupported`，无论 `X-App-Version` 多旧。

漏掉这一条，`envelope.md` §7b 就只是一句无处兑现的话。

### 5a. 合规拦截也只在 `signin` 落地（同构纪律）

**`compliance.*` 作为登录拦截，只在 `POST /v1/auth/signin` 的应答中出现。** 业务端点一律不返回合规拦截。

这与上一条并列，理由同源：**会话期内不因外部状态变化而中途变严**。而它同时是一个推演的唯一解——三个候选落点里两个已被既有决策排除：

- `/v1/profile/*` → `profile-sync.md` §11 已封死（同步通道上返回合规拦截，客户端只剩「待同步 N 永不减」或「丢进度」两条路）；
- 业务端点（轮回中途的任何写入）→ 直接撞 `envelope.md` §7b「仅两处硬阻塞」与 pillar #4；
- 启动 pull 虽是第二个硬阻塞点，但它是 `/v1/profile/pull`，同样被 §11 排除。

**本纪律约束的是「拦截」，不是 `compliance.` 这个前缀。** 合规域端点自身的操作错误（ticket 过期、核验拒绝一类）另有码，与本条无关——落点与取值见 `compliance.md`。

防沉迷时段在**会话中途**到点时的处置不走新通道，而是复用 `auth.session_revoked`，见 `compliance.md` §7。

## 6. 鉴权例外与请求头

`envelope.md` §4a 的通则是「每个 API 请求都带 `Authorization`」。**auth 域是它的唯一例外域**：

| 端点 | `Authorization` | `X-App-Version` | `X-Content-Version` |
|---|---|---|---|
| `challenge` | 不带 | 带 | **可缺省**（登录前尚无生效 overlay） |
| `signin` | 不带 | **必带**（强更闸门的输入） | 可缺省 |
| `refresh` | 不带（凭据在 body） | 带（**仅日志，不判闸门**，见 §5） | 带 |
| `signout` | **必带** | 带 | 带 |
| `bind` · `unbind` · `nickname` | **必带** | 带 | 带 |

`X-Request-Id` 七个端点都带（`envelope.md` §4a，每次重试都换）。应答头照 §4b 全带——**含 `X-Flags-Version`**：登录应答是启动链上客户端能拿到 flags 版本的**最早一次机会**（`content-service` 取 flags 是登录之后的一步），这里搭上车正是 §4「随任意应答下发」的设计意图。

## 7. 全部七个端点必须幂等

弱网下 auth 域的每一个写入都会「请求已达、应答丢失」并被重试：`challenge` 的重发、`signin` 的重试、`refresh` 的重放（§4）、`signout`、以及三个已登录态写入端点。**都必须能被安全重放。**

**`signout` 尤其要写明：对一个已失效的会话再次登出，返回 `204` 而非错误。** 若返回 `auth.token_invalid`，客户端会按 `envelope.md` §6 台账去走静默刷新——而它刚刚才主动登出。

**同一条纪律外扩到三个新端点：**

| 重放情形 | 应答 |
|---|---|
| `signin` 在 60 秒窗口内重复提交同一 `(channel, 凭据标识符, deviceId)` | `200`，回**与上次完全相同**的 token 对；不重新签发、不重新吊销任何会话（§4a） |
| `bind` 重复绑同一 identity 到**同一** account | `200`（与首次同形） |
| `bind` 绑到**另一** account 已占用的 identity | `auth.identity_already_bound` |
| `unbind` 解绑一条不存在的绑定 | `204`（与 `signout` 对已失效会话同一条纪律） |
| `unbind` 会使账号 identity 归零 | `auth.identity_required`——账号将永久不可登录，等于一次绕过合规流程的静默注销。注销有它自己的路径（`compliance.md` §2） |
| `nickname` 重复提交同一昵称 | `204` |

## 8. 端点报文

> 字段形态在 `openapi.yaml` 落笔后以 spec 为准，语义以本文件为准（`envelope.md` §1）。

### `POST /v1/auth/challenge`

请求：

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `channel` | string | ✅ | 仅 `"Phone"` / `"Email"`；第三方渠道无此步 |
| `identifier` | string | ✅ | 手机号（E.164）或邮箱 |
| `purpose` | string | ✅ | `"SignIn"` \| `"Rebind"` —— `"Rebind"` 是 `bind` 的前置一步（自建渠道绑定同样先走验证码握手） |

应答 `200`：

| 字段 | 类型 | 说明 |
|---|---|---|
| `expiresAtUtc` | string | 验证码有效期截止 |
| `resendAfterSeconds` | number | 距离可再次请求的秒数（客户端据此禁用「重发」按钮） |

错误：`rate.limited`（`Retry-After` + `detail.retryAfterSeconds`）· `auth.credential_invalid`（标识符格式非法）。

### `POST /v1/auth/signin`

请求：

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `channel` | string | ✅ | `"Phone"` / `"Email"` / `"WeChat"` / `"QQ"`，与 C# `LoginChannel` 逐字相同 |
| `credential` | object | ✅ | 按 `channel` 分形，见下 |
| `deviceId` | string | ✅ | 客户端生成、跨启动稳定的设备标识；**多设备裁决与幂等回放窗口的输入**，规则见 §4a。**永不参与鉴权** |

`credential` 的四种形态：

```
Phone   → { "phone": "+8613800138000", "code": "123456" }
Email   → { "email": "a@b.com",        "code": "123456" }
WeChat  → { "authCode": "<渠道 SDK 返回的一次性授权码>" }
QQ      → { "authCode": "<同上>" }
```

应答 `200`：

| 字段 | 类型 | 必填 | 客户端对位 |
|---|---|---|---|
| `accountId` | string | ✅ | `Session.AccountId` |
| `accessToken` | string | ✅ | `Session.Token` |
| `expiresAtUtc` | string | ✅ | `Session.ExpiresAtUtc` |
| `refreshToken` | string | ✅ | **不进 `Session`**，落 `user://cache/`（§2） |
| `refreshExpiresAtUtc` | string | ✅ | 同上 |
| `isNewAccount` | boolean | 可选 | 缺省即 `false`（`envelope.md` §2「不下发 `null`」）；**仅驱动首玩引导与日志，不是玩法判断的输入** |

错误：`auth.credential_invalid` · `auth.challenge_expired` · `auth.channel_rejected` · `client.version_unsupported`（§5）· `rate.limited`
· 四条合规拦截（§5a，语义见 `compliance.md`）：`compliance.realname_required` · `compliance.playtime_blocked` · `compliance.account_restricted` · `compliance.account_deleting`。

### `POST /v1/auth/refresh`

请求：`{ "refreshToken": "…" }`（**不带 `Authorization`**）。
应答：与 `signin` 应答**同形**（含轮换后的新 `refreshToken`），`isNewAccount` 恒不下发。
**宽限窗口内的重放**（同一个旧 `refreshToken` 在轮换后 60 秒内再次到达）→ 回**与上次完全相同**的那一对 token，不再轮换、不判泄漏（§4）。

错误：**只有两条**——`auth.session_revoked`（refresh token 已失效 / 被吊销 / 超出宽限窗口的重放）· `server.unavailable`。
**永不返回 `client.version_unsupported`**（§5）；**永不返回 `auth.token_expired`**（那会让客户端递归刷新）。

> 只给两条是刻意的：客户端对 refresh 失败的两条处置路径（§10）以「收到的是不是 `auth.session_revoked`」为判据，报文层面只有两种可能才使这个判据无歧义。

### `POST /v1/auth/signout`

请求：无 body（会话取自 `Authorization`）。应答 `204`，**幂等**。
错误：只有 `server.unavailable`；**对已失效会话不报错**（§7）。

### `POST /v1/auth/bind`

请求：`{ channel, credential }`——**`credential` 复用 `signin` 的同一个 `oneOf` 判别式**，不新造形态。Phone / Email 的绑定先走 `challenge`（`purpose: "Rebind"`）。
应答 `200`：`{ channel, boundAtUtc }`。

错误：`auth.identity_already_bound` · `auth.credential_invalid` · `auth.challenge_expired` · `auth.channel_rejected` · `server.unavailable` · `rate.limited`。

**绑定成功后，后端把新的绑定列表写进 profile 的 `/accountInfo/identities`**（`profile-sync.md` §5 写入表第三行）；客户端在紧随其后的一次 pull 中取回，**不本地追加**。

### `POST /v1/auth/unbind`

请求：`{ channel }`。应答 `204`，**幂等**。
错误：`auth.identity_required`（会使 identity 归零）· `server.unavailable`。写入同 `bind`。

### `POST /v1/auth/nickname`

请求：`{ nickname }`。应答 `204`。
错误：`auth.nickname_rejected`（`detail { reasonKey }`，三值见 §10）· `rate.limited` · `server.unavailable`。

**⚠ 本端点只判定，不写 profile。** 昵称的真值在客户端（玩家输入），落 `/accountInfo/nickname` 由客户端经既有 push 通道写入；本端点的应答只回答「这次提交是否被接受」。

> **为什么不由后端写。** 「够格进 `profile-sync.md` §5 后端写入表」的判据是**真值只可能在服务端产生**且**客户端无任何其他通道能取到它**——昵称两条都不满足，把它塞进那张表会用一个不满足判据的先例把护栏撑开。
>
> **代价如实记下：** 改包客户端可以跳过本端点、直接把未过审昵称 push 上去。本作是单人游戏、昵称**没有任何玩家间可见性**，因此残留风险面只剩合规抽查一项——由后端侧对 `/accountInfo/nickname`（透明只读路径）的**存量扫描**承接，触发频率与处置归 `02`。若日后出现玩家间可见性（排行榜、分享），这条判断需要重新做。
>
> **客户端只做长度与空白这类无争议的输入约束**，敏感词与频次一律由本端点判定——客户端自带一份词表就是第二权威，且改词表要发版。

### 数值初值（可调旋钮，非硬编码）

| 旋钮 | 初值 | 推导 |
|---|---|---|
| access token TTL | **15 分钟** | 它等于「被挤下线」的最坏生效延迟。15 分钟把窗口压到一次战斗量级以内，同时刷新频率对一次 1 小时的轮回只有 ~4 次，无感 |
| refresh token TTL | **30 天**滑动续期 | 覆盖「两周不玩、回来仍在登录态」这一移动游戏常态；滑动续期使活跃玩家永不被动重登 |
| refresh 宽限窗口 | **60 秒** | 需覆盖客户端指数退避的头几次重试；远短于 TTL，泄漏风险面可忽略 |
| `signin` 幂等回放窗口 | **60 秒** | 与上一行同值同理由——覆盖的是同一件事（§4a） |
| 单账号活跃会话上限 | **1** | 客户端全部既定语义都建立在「同时只有一个活跃写入方」之上（§4a） |
| 验证码有效期 | **5 分钟** | 通行值 |
| 验证码重发间隔 | **60 秒** | 通行值；短信是**有成本且被刷**的通道 |
| 单标识符验证码日上限 | **10 次** | 初值，待实测校准 |

**这些是待实测校准的初值，落点是后端配置而非代码常量。** 具体限流实现与阈值归 `open-questions/06-platform-stack.md`（栈落定后进 `operations/`）；契约层只声明语义，不指定实现。

## 9. auth 域新增的五个错误码

登记进 `envelope.md` §6 台账（`envelope.md`「新增 `code` 一律在此登记」）：

| `code` | `class` | `OpError` | `detail` | 理由 |
|---|---|---|---|---|
| `auth.credential_invalid` | `Fatal` | `Auth` | — | 自建渠道的凭据校验失败（验证码错、标识符格式非法）。既有 `auth.channel_rejected` 的语义是**第三方渠道侧**拒绝，装不下这一类 |
| `auth.challenge_expired` | `Fatal` | `Auth` | — | 验证码过期。与上一条**分列**：玩家处置不同（重新获取 vs 重新输入），而客户端文案按 `code` 分辨 |
| `auth.identity_already_bound` | `Fatal` | `Auth` | `{ channel }` | 目标渠道已绑到另一个账号。**必须能被玩家看懂**：那边有另一份进度，绑定不会合并两份存档（§1a） |
| `auth.identity_required` | `Fatal` | `Auth` | `{ channel }` | 解绑会使 identity 归零。`message` 必含「这是最后一个登录方式」 |
| `auth.nickname_rejected` | `Fatal` | `Auth` | `{ reasonKey }` | 昵称被拒。`reasonKey` 区分拒绝理由——与 `session_revoked` / `compliance.*` 复用同一个字段名，不新造机制。三值见 §10 |

**`auth.channel_rejected.detail` 由 `{ channel }` 扩为 `{ channel, channelCode }`**（`channelCode` 可选，缺省即渠道未给码；§3a）。

**不新增**：`auth.account_not_found` → 用既有 `resource.not_found`。

## 10. `reasonKey`：形态、两张取值表与兜底纪律

`envelope.md` §6 要求 `auth.session_revoked` 的 `message` 必含**触发源**，而 §5a 定的是**客户端不得解析 `message` 做任何分支**——只写在 `message` 里，触发源就只存在于一个客户端不许读的字段里。

而触发源**确实需要驱动客户端行为**：客户端的错误文案按 `code` 走 UI 层 `ErrorText`，而「另一设备登录」与「账号被运营吊销」对玩家是两句完全不同的话，却共用同一个 `code`。

**因此 `detail` 为 `{ revokedAtUtc, reasonKey }`。** 这不是新增机制——`compliance.*` 各条台账在用 `reasonKey` 这个字段名做同一件事。

### 形态：PascalCase（锁死）

**`reasonKey` 的全部取值用 PascalCase**，三处共用同一套规则（`auth.session_revoked` · `auth.nickname_rejected` · `compliance.*`）。

判据：契约面上「一个字段的取值来自一个封闭集合」这件事，现存全部先例都是 PascalCase（`envelope.md` §2 的枚举值约定，`"Phone"` · `"SignIn"` · `"Rebind"` · `"Conflict"`）。让 `reasonKey` 成为唯一异形，只会让「到底该写哪种」在日后每加一个取值时被重新提出一次。

**连带纪律：客户端的二级文案键由 `code` + `reasonKey` 机械变换得到。** `reasonKey` 按大写字母切分为 UPPER_SNAKE 后拼在一级键之后——`auth.session_revoked` + `SignedInElsewhere` → `ERR_AUTH_SESSION_REVOKED_SIGNED_IN_ELSEWHERE`。与客户端已定的「`ERR_*` 由 `code` 机械变换、无手写对照表」同构。

**形态自此锁死。** 中途改大小写会让已发版客户端的机械变换全部落空，且是一次**静默失效**——文案回落到一级键，没有任何报错。

**未知 `reasonKey` → 退回一级键**（`ERR_AUTH_SESSION_REVOKED`），与 `envelope.md` §5b「未知 `code` → 按 `class` 降级」同构。后端新增一个取值**不要求客户端同批发版**——这条是取值表可以持续扩张的前提。

### `auth.session_revoked.detail.reasonKey`（七值）

| 取值 | 触发 | 依据 |
|---|---|---|
| `SignedInElsewhere` | 另一 `deviceId` 完成 `signin` | §4a |
| `SessionSuperseded` | **同一** `deviceId` 重新登录、旧会话被替换，且旧 refresh token 在替换后到达（60 秒回放窗口之外） | §4a |
| `SignedOut` | 玩家主动 `signout` | §8 |
| `OperatorRevoked` | 运营吊销——`status` 变更为 `restricted` / `banned` 时连带吊销全部会话 | §1a |
| `PlaytimeEnded` | 未成年人时段到点强制下线 | `compliance.md` §7 |
| `CredentialChanged` | `bind` / `unbind` 改变了账号的登录方式，既有会话失效 | §7 |
| `TokenReuseDetected` | refresh token 在宽限窗口外重放，判定泄漏，吊销全部会话 | §4 |

**`SessionSuperseded` 不能省。** 「同设备重登 → 旧 refresh token 随后到达」是一个已知且常态的情形；不给它取值，等于让它长期占用「未知 → 兜底文案」那条路，而那条兜底是为**日后新增**取值准备的。

**后两条填的是既有漏洞。** §4（rotation 判泄漏 → 吊销全账号会话）与 §7（`bind`/`unbind` 改变登录方式）都会产生 `auth.session_revoked`，而此前只举了「另一设备登录 / 运营吊销」两例——落到实现，玩家会在自己刚绑定一个渠道之后看到「你的账号已在另一台设备登录」。

### `auth.nickname_rejected.detail.reasonKey`（三值）

| 取值 | 触发 |
|---|---|
| `SensitiveWord` | 命中敏感词 / 违禁词表（词表与审核口径归 `02`，服务商与阈值归 `06`） |
| `TooFrequent` | 改名频次超限（阈值归 `06`，与 §8 的旋钮同处） |
| `Malformed` | 长度 / 字符集不合法——**服务端兜底**。客户端只做长度与空白这类无争议的输入约束（§8），改包可绕过 |

**不收「昵称重复」这一值。** 本作是单人游戏、昵称无任何玩家间可见性（§8 已如实论证），唯一性无价值却会引入一次全表查重与一条重试路径。

### `compliance.*` 的取值

四条码各自的 `reasonKey` 取值见 `compliance.md` §5——**取值表随它的码走**，本文件不复述。

### refresh 失败的两条路径（客户端处置，本契约的对位）

`account-service.md` 原写「**刷新失败**视同断线，走 sync 缓冲通道，不硬阻塞」。这四个字同时盖住了两种情形，落到实现时会被写成一条路径。**已裁决按判据拆开：**

| refresh 的失败 | 判据 | 处置 |
|---|---|---|
| **网络失败** | 请求发不出 / 应答收不到 / `server.unavailable` | **视同断线**，走 sync 缓冲通道 + 指数退避，**不硬阻塞**（原语义一字不变） |
| **明确拒绝** | 收到 `auth.session_revoked` 应答 | **硬阻塞重登**，走既定的被挤下线路径：重登后**先 pull 后 flush**；**暂停退避重试**（重试必然失败） |

**承重点在判据是「收到了明确应答」而非「失败了」**：收不到应答一律算网络失败——弱网下二者不可区分，且误判成硬阻塞的代价远大于多退避几次。这与 `envelope.md` §7c 为 `Upgrade` 类错误定的「暂停退避 + 非模态提示 + 恢复点 = 重新登录」结构相同。

> 客户端侧的措辞修正归 `game-design-documents/`，本库不代为改动（见 §12）。

## 11. `AccountSeed` 不走 auth 应答

`AccountSeed` 落在 `AccountInfo` 上，而 `AccountInfo` 是 `PlayerProfile` 的账号级字段——它**本来就随 `/v1/profile/pull` 整聚合下行**。auth 应答再带一份，就是在两个端点各放一份同一个值：两处真值，且新设备首次登录时二者必然要对账。

因此：**后端在账号创建时生成 seed 并写进该账号的 profile，客户端在紧随其后的启动 pull 中拿到**——启动链顺序（登录 → pull）本就保证了这一点。`signin` 应答只需带 `isNewAccount`。

> 本文件只主张「不进 auth 报文」这一半；**另一半已于 2026-08-14 定稿在 `profile-sync.md` §2**：后端在账号创建时把 `accountSeed`（16 位小写 hex 字符串）写进 profile 骨架，客户端在启动 pull 中拿到。

## 决策(-> ADR)

- **auth 域的幂等 = sync 域的幂等**：`refresh` 的 60 秒宽限窗口与 `pushId` 的重放回放是**同一条 pillar #2 在两个端点上的兑现**，不是两套机制。值得固化——否则「rotation 是标准做法，为什么要开宽限口子」会反复被重新提出，而答案（弱网下「请求已达、应答丢失」是常态）恰恰是本库的第二条支柱。→ ADR 候选④，登记于 `decisions/_index.md`。

## 备选方案（已考虑并否决）

- **单 token + 服务端静默续期** — 与已定案的 `RefreshTokenAsync()` 语义不相容（拿过期凭据换新凭据），且无处表达「吊销」：一个能自我续期的长寿 token，被挤下线只能靠黑名单兜住，等于把状态又搬回中心存储却没拿到短寿 token 的好处。
- **每个渠道一个 signin 端点** — 端点集随渠道数线性增长，而四者应答形态完全相同；ADR-0003 的第三档渠道尚未展开，端点集会持续膨胀。
- **裸 refresh rotation（无宽限窗口）** — 「请求已达、应答丢失」会被误判为 token 泄漏并吊销全部会话，把一次弱网变成一次硬阻塞踢下线。与 pillar #2 直接冲突。
- **不做 rotation** — 泄漏的 refresh token 在整个 TTL 内长期有效，而它的 TTL 恰恰是最长的那个。
- **首版 `Email` 走密码** — 拉来密码存储与强度策略、找回、改密整条链路（各自都要端点与合规面），而首版并不需要；验证码路线使两个自建渠道共用一种 credential 形态。
- **`refresh` 也判定强更闸门** — 会在会话期内把玩家踢出，违反 `envelope.md` §7b 与「仅两处硬阻塞」。
- **触发源只写在 `message` 里** — `envelope.md` §5a 禁止客户端解析 `message`，等于让这个信息对代码不可见（§10）。
- **`AccountSeed` 随 signin 应答下发 / 立 `/v1/auth/me`** — 与 `AccountInfo` 随 profile pull 下行制造两份真值（§1、§11）。
- **把 `signin` 的多设备裁决结果告知登录方**（如「已挤下线 1 台设备」）— 无客户端消费面；另一台设备会通过它自己的下一次请求得到 `auth.session_revoked`，这是既定路径。
- **会话上限 2 + 按 `issuedAtUtc` 最旧者挤出** — 会让 `sync.conflict`（既定处置 = 丢弃本地缓冲）从异常路径变成常态，即「在 A 设备打完的一场战斗被 B 设备抹掉」成为日常；而这是单人游戏，没有同时用两台设备推进同一份存档的需求（§4a）。
- **同设备重登时旧会话并存到自然过期** — 同账号同设备最长 30 天存在两对有效 token，与 §4 rotation 纪律方向相反，且使「活跃会话数」不再可用于风控。它唯一的理由（保 `signin` 幂等）已被 60 秒回放窗口更干净地满足。
- **靠「同 `deviceId` 不吊销」单独承担 `signin` 的幂等** — 只堵住一半：一次性凭据已被消费，重试仍会撞 `auth.challenge_expired`（§4a）。
- **`signout` 吊销该账号全部会话（回避 `sid`）** — 会把另一台设备一并踢下线，凭空造出一次硬阻塞，与「主动登出」的玩家预期完全不符。
- **以 access token 的原始串作会话键** — 它随 rotation 变化，无法作为跨刷新的稳定标识；且把凭据本身当键会逼着服务端存明文。
- **`sid` 作为报文字段下行** — 服务端内部键跨边界即成为契约的一部分（§1a 的三条先例），客户端无任何消费点。
- **`deviceId` 参与鉴权（设备绑定 / 不匹配即拒绝）** — 它是客户端自报可伪造值，用它做安全判定是假安全；真实后果是换机 / 重装的玩家被挡在门外。
- **以 access token 为吊销粒度（黑名单）** — 等于给每个请求加一次中心查询，抵消「自包含 JWT 离线验签」的全部收益；§2 已按同一理由否决过给 push 加中心校验读。
- **服务端主动推送「你被挤下线了」** — 需要长连接 / 推送通道，在 `vision/scope.md` 的既定边界之外；refresh + CAS 两条路径已把最坏延迟压到 15 分钟且保证云端不被污染。
- **设备列表 / 远程踢出 UI** — 无客户端消费面，且要新增一整套端点。
- **`reasonKey` 用 camelCase** — 论据（它不是 C# 枚举、客户端必须容忍未知值、故 `envelope.md` §2 对它无适用对象）本身成立，但代价是让它成为契约面上唯一的非 PascalCase 封闭取值集；这类不一致正是「到底该写哪种」在每次新增取值时被重新提出的来源（§10）。
- **`compliance.*` 拦截落在业务端点或 `/v1/profile/*`** — 前者撞 §7b 与 pillar #4，后者被 `profile-sync.md` §11 封死（§5a）。
- **接托管身份服务（Firebase Auth / Auth0 / Cognito）作为身份主体** — 主键租给第三方（换服务商 = 全量存档迁移）、建号时刻不在本方（无法与 `accountSeed` 写入同一步，只能靠 webhook 事后追平，失败形态是「玩家登录成功但没有存档」）、§4 §5 §10 三条会话语义无处表达、境外托管与国内数据存放要求冲突。
- **以渠道账号（微信 openid）直接作为 `accountId`** — 换渠道即换键；个人身份标识进 profile 主键；且手机号渠道无对应物，两类渠道的主键来源会分叉。
- **本方实现完整 OAuth2 / OIDC provider** — 无第三方消费者；成本全部沉没在 discovery / JWKS / 授权码流上，而 §2 的双 token 私有模型已满足全部需求。
- **登录时按手机号 / 邮箱隐式合并已有的渠道账号** — 必然要丢弃其中一份存档，而玩家不预期一次登录删掉进度（§1a）。
- **为绑定 / 解绑单开一份契约文档** — 同一套 credential、同一套会话、同一域，分开会让 `oneOf` 判别式在两份文档各写一遍。
- **同一 `channel` 允许绑多条 identity** — 无玩家价值，却让「解绑哪一条」「找回时以哪条为准」全部分叉。
- **`channelUserId` 随 `AccountInfo` 下行** — 后端内部键跨边界即成为契约的一部分，且把渠道身份标识写进玩家可导出的存档，PIPL 面无谓放大。
- **渠道不可达也报 `auth.channel_rejected`** — 它是 `Fatal`，把一次渠道抖动变成终态（§3a，与 `purchase.md` §3 同一条理由）。
- **昵称由后端写进 profile** — 它不满足「够格进 `profile-sync.md` §5 写入表」的判据（真值在客户端输入），会用一个不合判据的先例撑开护栏（§8）。
- **`account.status` 随 `AccountInfo` 下行** — 客户端无消费点（表现全部由 `signin` 分支与 `compliance.*` 承载），且本地副本会在会话中途过期，制造一份必然滞后的第二真值。
- **`refresh` 凭据失效时返回 `server.unavailable`**（使客户端行为与「刷新失败视同断线」的原措辞严格一致）— 把一个确定的终态伪装成可重试的临时故障，玩家会一直看到「离线 · 待同步 N」而永远等不到恢复，与 §7c「`Upgrade` 类错误暂停退避」的立意正相反。

## Open questions

- **敏感词词表与审核口径**（`SensitiveWord` 的判定输入）归 `02`；**改名频次阈值**归 `06`（后端配置，与 §8 的旋钮同处）。取值表本身已封定（§10）。
- **未过审昵称的存量扫描**——本契约的改名端点只判定「这一次提交」，profile 里仍可能存在绕过判定写入的昵称（§8）。扫描触发频率与处置（改写 / 置空 / 标 `restricted`）归 `02`。
- **风控三档处置向玩家的可见粒度**——`OperatorRevoked` 与 `compliance.account_restricted` 的两个取值当前够用；若风控要区分「哪一类异常」，取值表需再扩。归 `02`，**不阻塞**（新增 `reasonKey` 不要求客户端同批发版，§10）。
- **`refresh` 的滥用面与限流形态**——本文件把 `refresh` 的错误清单收紧为两条（§8），刻意不给 `rate.limited`，以保客户端两条路径在报文层面互斥。若 `06-platform-stack.md` 认定该端点必须限流，需回头松动这一条并同时给出客户端的第三条路径，**不能只在网关侧悄悄加**。
- **token 签名密钥的保管与轮换**、会话存储形态、限流的实现与实际阈值——均归 `06`，落 `operations/`。契约层只声明语义。

## 跨库待办（客户端侧，本库不代为决定）

**本契约的客户端对位已于 2026-08-16 同批落笔**（`account-service` 的四个新方法与 `SignInAsync` 扩参、`AccountInfo` 的 `Identities` / `Nickname` / `CreatedAtUtc`、绑定管理的 UX、三个新 `code` 的 `ERR_*`），权威在 `game-design-documents/systems/services/account-service.md` 与 `systems/player-profile/account-info.md`。

`deviceId` 的生成与持久化落点**已由客户端侧落定**，权威见 `game-design-documents/systems/services/account-service.md`（本库不复述其形态）。余下一点仍在客户端侧待落：refresh token 的客户端持有形态（§2 已定「不进 `Session`、落 `user://cache/`」，客户端文档尚未写死落点）。**本库不催办**——它登记在客户端库自己的 `systems/services/account-service.md`「待决问题」。
