---
type: solution-draft
date: 2026-08-12
question: `contracts/auth.md` 的端点报文本体未定——token 生命周期（签发 / 刷新 / 吊销）、登录渠道的报文形态、以及它们与既有错误码台账的对位。
source: open-questions/01-contracts.md → 第 1 条「`auth.md` 尚未成文（下一份）」
targets: contracts/auth.md（新建）· contracts/envelope.md（§4a 例外说明 + §6 台账三处增改）· contracts/_index.md（状态行）· 跨库：game-design-documents/systems/services/account-service.md（新增 challenge 方法 · refresh token 的持有形态 · 「刷新失败」措辞精化）
status: distilled
decided: 2026-08-13
reviewed: 2026-08-13 —— 用户逐项评审并定案：四项取向全部选定推荐项（JWT + 15 min · rotation + 60 s 宽限 · Email 走验证码 / 密码后置 · `session_revoked.detail` 加 `reasonKey`），第五项张力「刷新失败视同断线」裁决松动、按「是否收到明确应答」拆两条路径。无遗留取向项。
distilled-to: handoffs/2026-08-13-auth-endpoint-contract.md
---

# 方案草稿 — `auth.md` 端点报文

> **本草稿已于 2026-08-13 由用户裁决定案**（`status: decided`）：四项取向全部选定推荐项，「刷新失败」的张力按建议松动。全文已按裁决改写——下方各节陈述的即是**待提炼的定案**，不再是并列选项。逐条裁决见「已裁决（2026-08-13）」。
> 落笔权仍在 `/analyze-new-ideas`：本文件是它的输入，不是主题文档。

## 问题

`contracts/` 的边界层已于 08-11 成文（`envelope.md`），`content-manifest.md` 亦已定稿；契约面只剩 `auth.md` 与 `profile-sync.md` 两份。`open-questions.md` 把 `auth.md` 排为**下一份**，理由是它承载 `auth.token_expired` / `auth.session_revoked` 这两个**必须分开**的 `code`。

悬着的是三样东西：

1. **token 生命周期** —— 签发什么、活多久、怎么刷新、怎么吊销。客户端已定案「token 到期 → 静默刷新、绝不打断轮回」，但契约侧从未说明这条静默刷新**用什么凭据**去换。
2. **登录渠道的报文形态** —— `LoginChannel { Phone, Email, WeChat, QQ }` 四个渠道的凭据结构差异很大（短信码 / 邮箱 / 渠道授权码），单一 request schema 装不下。
3. **多设备裁决触发 `auth.session_revoked` 的具体条件** —— 明确待 `02-account-compliance.md`。

本草稿的立场：**①②可由既有决策与通行做法推演到可 derive 的程度，③的裁决规则不碰，但可证明它不影响报文形态**——无论 02 选哪种裁决策略，客户端看到的都是同一个 `code`，只有触发条件与 `detail.reasonKey` 的取值集合待填。因此 `auth.md` 可以先写，02 落定后只补一张取值表。

## 约束（来自既有设计）

- **序列化与命名**：lowerCamelCase · 枚举值与客户端 C# 枚举名**逐字相同** · 不下发 `null`（缺省即省略） · 时间 RFC 3339 UTC 带 `Z`、字段名以 `AtUtc` 结尾 · `/v1/` 主版本前缀。→ `envelope.md` §2 §3
- **错误分支一律以 `code` 为键，客户端不得靠 HTTP 状态码分支**；`class` 对每个 `code` 固定不变。→ `envelope.md` §5b
- **`auth.token_expired` 与 `auth.session_revoked` 必须是两个 `code`**，因为客户端处置完全不同（静默刷新 / 硬阻塞重登）。→ `envelope.md` §6、`account-service.md`「意图」
- **强更闸门在签发 token 时判定一次**，会话期内不因阈值提升而中途变严。→ `envelope.md` §7b
- **客户端 API 面已定**（`account-service.md`）：`SignInAsync(LoginChannel, ct) → OpResult<Session>` · `RefreshTokenAsync(ct) → OpResult<Session>` · `SignOutAsync(ct) → OpResult` · `TryGetSession(out Session)`；`Session = record struct (AccountId, Token, ExpiresAtUtc)`。
- **刷新失败视同断线**，走 sync 的缓冲通道，**不硬阻塞**、不回退存档点。→ `account-service.md`、pillar #4
- **弱网优先：幂等重于优雅**——「请求已达、响应丢失」是常态。→ pillar #2
- **`AccountSeed` 由后端在账号创建时下发，落 `AccountInfo`**（PlayerProfile 的账号级字段）。→ `game-design-documents/systems/player-profile/account-info.md`
- **后端不重跑玩法**；账号能力之外的一切留在客户端。→ pillar #1

## 建议方案

### 1. 端点集：四个，不是三个

`[既有推演]` `[通行做法]`

```
POST /v1/auth/challenge   请求一次性验证码（短信 / 邮件）      —— 无鉴权
POST /v1/auth/signin      渠道登录，换取会话                   —— 无鉴权
POST /v1/auth/refresh     用 refresh token 换新 access token   —— 无鉴权（凭据在 body）
POST /v1/auth/signout     主动登出，吊销当前会话                —— 需鉴权
```

后三个与客户端三个 B 形态方法一一对位。**`challenge` 是推演出来的第四个**：`LoginChannel.Phone` 是已定案的**首选**渠道，而手机号登录必然需要一次「先下发验证码、再提交验证码」的两步握手——单个 `signin` 端点表达不了。它对客户端 API 面提出一条反向要求，见「后果」。

**不设 `/v1/auth/me`**：账号身份元数据在 `AccountInfo`，它是 PlayerProfile 的账号级字段，随 `/v1/profile/pull` 下行。另立一个身份查询端点会当场造出第二份真值。

### 2. token 模型：短寿 access + 长寿 refresh（双 token）

`[既有推演]`

客户端已定案「token 到期 → `RefreshTokenAsync()` 静默刷新」。**单 token 模型下这条语义不可能成立**：静默刷新意味着拿一个已过期的凭据去换新凭据，服务端要么接受过期 token（等于它没有过期），要么拒绝（那就没有静默刷新，只剩重登）。因此必须有一个与 access token 分离、寿命更长、**只用于换取 access token** 的刷新凭据。

| | access token | refresh token |
|---|---|---|
| 形态 | **自包含 JWT**（已裁决 08-13） | **不透明随机串**（必须查库才能吊销） |
| 用途 | 每个 API 请求的 `Authorization: Bearer` | 只用于 `POST /v1/auth/refresh` |
| 客户端对位 | `Session.Token` / `Session.ExpiresAtUtc` | **不进 `Session`**，见下 |
| TTL | **15 分钟**（已裁决 08-13；初值，见「数值初值」） | **30 天滑动续期**（初值） |
| 过期时的 `code` | `auth.token_expired` | `auth.session_revoked` |

**access token = 自包含 JWT + 15 分钟 TTL（已裁决 08-13）。** 网关可离线验签，profile push 这条最热的路径不需要每次读会话存储。代价是「被挤下线」的最坏生效延迟 = TTL；窗口内旧设备的 push 由 `revision` CAS 拒绝（`sync.conflict`），**云端不会被污染**，代价只是旧设备丢一次本地缓冲——这正是既定的 conflict 处置。多设备并发在本作是罕见路径（单人游戏、无跨玩家交互），为它给最热路径加一次中心校验读不划算。

**`Session` record 一字不改。** refresh token 由 `HttpAccountBackend` 内部持有并落 `user://cache/`，与 `SyncEnvelope`（`baseRevision` 落 `user://cache/sync-envelope.json`）**同构**——都是传输层元数据，不进 Profile、不进存档 schema、不参与迁移，且同样适用「切账号即失效」的必需缺失处置。这条同构不是巧合：两者都是「客户端持有、后端定义、与玩法无关」的凭据。

### 3. 登录报文：`channel` + 按渠道分形的 `credential`

`[既有推演]` `[通行做法]`

`channel` 取值与 C# 枚举名逐字相同（`"Phone"` / `"Email"` / `"WeChat"` / `"QQ"`），这是 `envelope.md` §2 已定的约定，此处直接受用——**四个渠道走同一个端点**，靠 `credential` 的判别式（discriminated union，OpenAPI 3.1 的 `oneOf` + `discriminator`）分形。

不为每个渠道立独立端点的理由：渠道优先级是**会扩张**的（ADR-0003 的第三档「海外 / 跨平台」尚未展开），每加一个渠道就加一个端点会让端点集随渠道数线性增长，而它们的应答形态**完全相同**。

第三方渠道（WeChat / QQ）走 `authCode`：客户端 SDK 拿到一次性授权码交给后端，**后端向渠道服务器换取 openid**——客户端不接触渠道 secret。这是渠道接入的标准形态，也与 `account-service` 的定位「平台 SDK 与后端鉴权的唯一门面」一致。

**`Email` 走验证码，密码后置（已裁决 08-13）。** 首版两个自建渠道（`Phone` / `Email`）**共用同一种 `credential` 形态**（标识符 + 一次性验证码），密码路线整体推迟到账号体系成熟后再议。由此免掉密码存储与强度策略、找回、改密这一整条链路——它们各自都要端点、都要合规面，而首版并不需要。**推论：首版端点集就此封定在四个**（`challenge` / `signin` / `refresh` / `signout`），不为密码预留端点空壳（本库「先有设计再建文件」）。密码留作后置可选能力，届时是**加**一种 `credential` 分形 + 相应端点，不推翻本次任何定案。

### 4. 刷新：rotation + 60 秒宽限窗口

`[通行做法]` + `[既有推演]`

通行做法是 **refresh token rotation**：每次刷新返回新的 refresh token、旧的立即失效；若一个已被使用过的 refresh token 再次到达 → 判定为泄漏 → 吊销该账号全部会话。

**但裸 rotation 与 pillar #2 直接冲突。** 「刷新请求已达、应答丢失」在移动网络下是常态：客户端仍持旧 refresh token 重试 → 被判重放 → 全账号吊销 → 玩家在轮回中途被硬踢下线。这正是 `pushId` 存在的同一个理由，只是换了个端点。

**定案（已裁决 08-13）：启用 rotation + 60 秒宽限窗口。** 旧 refresh token 在被轮换后的 **60 秒内**仍可被接受，且**返回与上次相同的那一对新 token**（幂等回放，不再轮换）；窗口外再次出现 → 才判泄漏并吊销该账号全部会话。这与 `pushId` 的「重复到达不再 `+1`，直接回上次结果」是同一个模式，理由同源——**auth 域的幂等与 sync 域的幂等是同一条 pillar #2 在两个端点上的兑现，不是两套机制。**

### 5. 强更闸门只在 `signin` 判定，`refresh` **不**判定

`[既有推演]`

`envelope.md` §7b 已明写「闸门在签发 token 时判定一次，会话期内不因阈值提升而中途变严」。`refresh` 也签发 access token，若它也判定闸门，运营提升 `minAppVersion` 就会在**会话期内**把玩家踢出——直接违反 §7b 的实现语义，也违反「仅两处硬阻塞」。

因此：
- `POST /v1/auth/signin` → 可返回 `client.version_unsupported`（`class: Upgrade`，硬闸门）；
- `POST /v1/auth/refresh` → **永不**返回 `client.version_unsupported`，无论 `X-App-Version` 多旧。

这条必须写成 `auth.md` 的承重纪律——它是「闸门只在登录与启动 pull 生效」这条已定语义在端点层面的唯一落地点，漏掉它，§7b 就只是一句无处兑现的话。

### 6. 三个端点的鉴权例外与请求头

`[既有推演]`

`envelope.md` §4a 写的是「每个 API 请求都带 `Authorization`」。auth 域必须是例外，且需要写明白：

| 端点 | `Authorization` | `X-App-Version` | `X-Content-Version` |
|---|---|---|---|
| `challenge` | 不带 | 带 | **可缺省**（登录前尚无生效 overlay） |
| `signin` | 不带 | **必带**（强更闸门的输入） | 可缺省 |
| `refresh` | 不带（凭据在 body） | 带（仅日志，不判闸门） | 带 |
| `signout` | **必带** | 带 | 带 |

`X-Request-Id` 四个端点都带（`envelope.md` §4a，每次重试都换）。应答头照 §4b 全带——**含 `X-Flags-Version`**：登录应答是启动链上客户端能拿到 flags 版本的最早一次机会（`content-service` 取 flags 是登录之后的一步），这里搭上车正是 §4 「随任意应答下发」的设计意图。

### 7. `signout` 必须幂等

`[既有推演]`

弱网下 `signout` 同样会「请求已达、应答丢失」并被重试。**对一个已失效的会话再次登出，返回 `204` 而非错误**——若返回 `auth.token_invalid`，客户端会按台账去走静默刷新，而它刚刚才主动登出。

这是 pillar #2 在写入端点上的一次普通兑现：auth 域的每一个写入（`challenge` 的重发、`signin` 的重试、`refresh` 的重放、`signout`）都必须能被安全重放。

### 8. `session_revoked` 的 `detail` 携带 `reasonKey`（已裁决 08-13）

`[既有推演]`

`envelope.md` §6 台账当前给 `auth.session_revoked` 的 `detail` 形状是 `{ revokedAtUtc }`，同时要求 `message` 必含「吊销时间与**触发源**（另一设备登录 / 运营吊销）」。但 §5a 已定案 **`message` 给人读、客户端不得解析 `message` 做任何分支**——于是触发源现在只存在于一个客户端不许读的字段里。

而触发源**确实需要驱动客户端行为**：客户端已定案合规与错误文案「按 `code` 走 UI 层 `ErrorText`」（`account-service.md` 08-12 收口），「另一设备登录」与「账号被运营吊销」对玩家是两句完全不同的话，却共用一个 `code`。

**定案：`detail` 扩为 `{ revokedAtUtc, reasonKey }`——触发源必须对代码可见，客户端按原因给出不同文案。** 这不是新增机制：`compliance.*` 两条台账已经在用 `reasonKey` 这个字段名做同一件事。`reasonKey` 的取值集合待 02 的裁决规则落定后填表（本草稿不预填），但**字段本身现在就进契约**——它是 `auth.md` 与 02 之间的接缝，先立字段、后填取值，02 落定时只补一张表，不必回头改报文形状。

**连带纪律：客户端对未知 `reasonKey` 必须有兜底文案**（与「未知 `code` → 按 `class` 降级」同构）。02 之后新增一个 `reasonKey` 不应要求客户端同批发版。

### 9. 需要新增的错误码：两条

`[既有推演]`

| 新增 `code` | `class` | `OpError` | 理由 |
|---|---|---|---|
| `auth.credential_invalid` | `Fatal` | `Auth` | 验证码错 / 密码错。现有 `auth.channel_rejected` 语义是**第三方渠道侧**拒绝（`detail { channel }`），装不下自建凭据的校验失败 |
| `auth.challenge_expired` | `Fatal` | `Auth` | 验证码过期。与上一条**分列**：玩家处置不同（重新获取 vs 重新输入），而客户端文案按 `code` 分辨 |

**不新增**：`auth.account_not_found` → 用既有 `resource.not_found`；渠道绑定冲突 → 多渠道绑定模型未定（见「前置依赖」），不预先立 `code`。

### 10. `AccountSeed` **不**走 auth 应答

`[既有推演]`

`03-sync-conflict.md` 把「`AccountSeed` 随哪条响应返回」列为待答项。本草稿的推演结论是：**不随任何 auth 应答返回。**

`AccountSeed` 落在 `AccountInfo` 上，而 `AccountInfo` 是 `PlayerProfile` 的账号级字段——它**本来就随 `/v1/profile/pull` 整聚合下行**。auth 应答再带一份，就是在两个端点各放一份同一个值：两处真值，且新设备首次登录时二者必然要对账。

`signin` 应答只需带 `isNewAccount: bool`，供客户端走首玩引导与日志（**不是**玩法判断的输入）。后端在账号创建时生成 seed 并写进该账号的 profile，客户端在紧随其后的启动 pull 中拿到——启动链顺序（登录 → pull）本就保证了这一点。

> 定稿权在 `03` / `profile-sync.md`；此处只主张「不进 auth 报文」这一半。

## 具体形态（可 derive 的落地面）

### `POST /v1/auth/challenge`

请求：

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `channel` | string | ✅ | 仅 `"Phone"` / `"Email"`（两者同形，08-13 裁决）；第三方渠道无此步 |
| `identifier` | string | ✅ | 手机号（E.164）或邮箱 |
| `purpose` | string | ✅ | `"SignIn"`（预留 `"Rebind"`，本期只实现 `"SignIn"`） |

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
| `deviceId` | string | ✅ | 客户端生成、跨启动稳定的设备标识；**多设备裁决的输入**（规则待 02） |

`credential` 的四种形态：

```
Phone   → { "phone": "+8613800138000", "code": "123456" }
Email   → { "email": "a@b.com",        "code": "123456" }   // 首版无 password 分支（08-13 裁决）
WeChat  → { "authCode": "<渠道 SDK 返回的一次性授权码>" }
QQ      → { "authCode": "<同上>" }
```

**首版只有这四形、两类**（标识符 + 一次性码 / 渠道 authCode）。密码作为后置可选能力时是**加**第五形，不推翻此处任何一条。

应答 `200`：

| 字段 | 类型 | 必填 | 客户端对位 |
|---|---|---|---|
| `accountId` | string | ✅ | `Session.AccountId` |
| `accessToken` | string | ✅ | `Session.Token` |
| `expiresAtUtc` | string | ✅ | `Session.ExpiresAtUtc` |
| `refreshToken` | string | ✅ | **不进 `Session`**，落 `user://cache/` |
| `refreshExpiresAtUtc` | string | ✅ | 同上 |
| `isNewAccount` | boolean | 可选 | 缺省即 `false`（不下发 `null`）；仅驱动首玩引导与日志 |

错误：`auth.credential_invalid` · `auth.challenge_expired` · `auth.channel_rejected` · `client.version_unsupported`（**唯一的强更闸门点**）· `compliance.*`（清单待 02）· `rate.limited`。

### `POST /v1/auth/refresh`

请求：`{ "refreshToken": "…" }`（**不带 `Authorization`**）
应答：与 `signin` 应答**同形**（含轮换后的新 `refreshToken`），`isNewAccount` 恒不下发。
**宽限窗口内的重放**（同一个旧 `refreshToken` 在轮换后 60 秒内再次到达）→ 回**与上次完全相同**的那一对 token，不再轮换、不判泄漏。

错误：**只有两条**——`auth.session_revoked`（refresh token 已失效 / 被吊销 / 超出宽限窗口的重放）· `server.unavailable`。**永不返回 `client.version_unsupported`**（§5）；**永不返回 `auth.token_expired`**（那会让客户端递归刷新）。

### `POST /v1/auth/signout`

请求：无 body（会话取自 `Authorization`）。应答 `204`，**幂等**。
错误：只有 `server.unavailable`；**对已失效会话不报错**（§7）。

### 数值初值（可调旋钮，非硬编码）

| 旋钮 | 建议初值 | 推导 |
|---|---|---|
| access token TTL | **15 分钟** | 它等于「被挤下线」的**最坏生效延迟**。窗口内旧设备的 push 由 `revision` CAS 拒绝（`sync.conflict`），云端不会被污染，代价只是旧设备丢一次本地缓冲——这正是既定的 conflict 处置。15 分钟把窗口压到一次战斗量级以内，同时刷新频率对一次 1 小时的轮回只有 ~4 次，无感 |
| refresh token TTL | **30 天**滑动续期 | 覆盖「两周不玩、回来仍在登录态」这一移动游戏常态；滑动续期使活跃玩家永不被动重登 |
| refresh 宽限窗口 | **60 秒** | 需覆盖客户端指数退避的头几次重试；60 秒足够，且远短于 TTL，泄漏风险面可忽略 |
| 验证码有效期 | **5 分钟** | 通行值 |
| 验证码重发间隔 | **60 秒** | 通行值；短信是**有成本且被刷**的通道 |
| 单标识符验证码日上限 | **10 次** | 初值，待实测校准 |

这些是**待实测校准的初值**，落点是后端配置而非代码常量；具体限流实现与阈值归 `06`（栈落定后进 `operations/`）。

## 后果

- **新建 `contracts/auth.md`**；`contracts/_index.md` 的状态行由「计划中」改「已成文」，契约面只剩 `profile-sync.md` 一份。
- **`envelope.md` 需三处增改：**
  1. §4a 增一段 auth 域的鉴权例外表（本草稿 §6）；
  2. §6 台账新增两行（`auth.credential_invalid` · `auth.challenge_expired`）；
  3. §6 台账 `auth.session_revoked` 的 `detail` 形状由 `{ revokedAtUtc }` 改为 `{ revokedAtUtc, reasonKey }`。
- **跨库待办（客户端侧，本库不代为决定）** —— 需 `game-design-documents/` 另写一份 handoff：
  1. **`account-service` API 面缺一个方法**：验证码下发无对位调用面，建议新增 `Task<OpResult> RequestSignInChallengeAsync(LoginChannel channel, string identifier, CancellationToken ct)`（B 形态）。
  2. **refresh token 的客户端持有形态**：`Session` record 不改，refresh token 由 `HttpAccountBackend` 内部持有、落 `user://cache/`、原子写、跨启动保留、切账号即失效——与 `SyncEnvelope` 同构。
  3. **「刷新失败」的措辞需精化**（08-13 已裁决松动，见「与既有决策的张力」）：`account-service.md`「意图」与 API 面 `RefreshTokenAsync` 的失败语义一栏，须改写为**网络失败 → 缓冲通道**、**收到 `auth.session_revoked` → 硬阻塞重登 + 暂停退避**两条；判据是「有没有收到明确应答」。
  4. 新增两个 `code` 的客户端 `ErrorText` 文案（`ux/error-and-blocking-ux.md`）。
  5. `deviceId` 的生成与持久化落点（跨启动稳定、切账号不变）。
- **不影响存档 schema**：本草稿涉及的一切都是传输层元数据，不进 `PlayerProfile`、不 bump `schemaVersion`、无迁移。
- **不影响 `revision` / `pushId` 语义**：auth 域与 profile 域完全解耦。

## 备选方案（已考虑并否决）

- **单 token + 服务端静默续期** —— 与已定案的 `RefreshTokenAsync()` 语义不相容（拿过期凭据换新凭据），且无处表达「吊销」：一个能自我续期的长寿 token，被挤下线只能靠黑名单兜住，等于把状态又搬回中心存储却没拿到短寿 token 的好处。
- **每个渠道一个 signin 端点** —— 端点集随渠道数线性增长，而四者应答形态完全相同；ADR-0003 的第三档渠道（海外 / 跨平台）尚未展开，端点集会持续膨胀。
- **裸 refresh rotation（无宽限窗口）** —— 「请求已达、应答丢失」会被误判为 token 泄漏并吊销全部会话，把一次弱网变成一次硬阻塞踢下线。与 pillar #2 直接冲突，理由与 `pushId` 同源。
- **不做 rotation** —— 泄漏的 refresh token 在整个 TTL 内长期有效，而它的 TTL 恰恰是最长的那个。
- **`refresh` 也判定强更闸门** —— 会在会话期内把玩家踢出，违反 `envelope.md` §7b 的实现语义与「仅两处硬阻塞」。
- **`AccountSeed` 随 signin 应答下发** —— 与 `AccountInfo` 随 profile pull 下行制造两份真值（见 §10）。
- **立 `/v1/auth/me` 身份查询端点** —— 同上，`AccountInfo` 已是 PlayerProfile 的字段。
- **触发源只写在 `message` 里** —— §5a 已定案客户端不得解析 `message`，等于让这个信息对代码不可见（见 §8）。
- **把 `signin` 的多设备裁决结果告知登录方**（如「已挤下线 1 台设备」）—— 无客户端消费面；另一台设备会通过它自己的下一次请求得到 `auth.session_revoked`，这是既定路径。

## 与既有决策的张力

**一条，已于 2026-08-13 裁决松动：「刷新失败视同断线」按 refresh 的两种失败拆开。**

- 冲突的是哪一条：`account-service.md`「意图」与 API 面均写「**刷新失败**视同断线，走 sync 缓冲通道，**不硬阻塞**」。
- 为什么需要它松动：refresh 有两种失败——**网络失败**（请求发不出 / 应答收不到）与**明确拒绝**（refresh token 已被吊销、超出宽限窗口、账号被封）。前者视同断线完全正确；后者**重试永远不会成功**，按缓冲通道处理只会让客户端一直退避重试一条死路，直到缓冲闸门超限才弹软阻塞模态——而此时真正的原因（会话已终结）从未被告诉玩家。这与 `Upgrade` 类错误在非闸门点的情形**结构完全相同**（`sync-service.md` 08-11b 已为那一种定案：暂停退避 + 非模态提示 + 恢复点 = 重新登录）。
- **裁决（08-13）：按判据拆成两条路径，措辞随之精化。**

  | refresh 的失败 | 判据 | 处置 |
  |---|---|---|
  | **网络失败** | 请求发不出 / 应答收不到 / `server.unavailable` | **视同断线**，走 sync 缓冲通道 + 指数退避，**不硬阻塞**（原语义一字不变） |
  | **明确拒绝** | 收到 `auth.session_revoked` 应答 | **硬阻塞重登**，走既定的被挤下线路径：重登后**先 pull 后 flush**；**暂停退避重试**（重试必然失败） |

  二者并不真的矛盾——后者本就是 `session_revoked` 已定案的处置，只是「刷新失败」四个字同时盖住了两种情形，落到实现时会被写成一条路径。**承重点在判据是「收到了明确应答」而非「失败了」**：收不到应答一律算网络失败（弱网下不可区分，且误判成硬阻塞的代价远大于多退避几次）。
- **由此 `refresh` 的错误清单收紧为两条**（见「具体形态」）：`auth.session_revoked` 与 `server.unavailable`——契约侧不给第三种，客户端的两条路径才在报文层面互斥、无歧义。
- **不松动时的替代方案（已否决）**：契约侧让 `refresh` 在凭据失效时返回 `server.unavailable`（`Retryable`），使客户端行为与既定措辞严格一致。**否决理由**——它把一个确定的终态伪装成可重试的临时故障，玩家会一直看到「离线 · 待同步 N」而永远等不到恢复，与「`Upgrade` 类错误暂停退避」那条纪律的立意正相反。

## 前置依赖

- **`02-account-compliance.md`**（三处）：
  1. **多设备并发裁决规则** → 决定 `signin` 是否吊销其他会话、`auth.session_revoked` 的触发条件与 `detail.reasonKey` 的取值集合。**报文形态不受影响**（本草稿 §8 已论证），待补的只是一张取值表。
  2. **账号系统自建 vs 接第三方** → 决定 `credential` 第三方分支的细节（后端向渠道换 openid 的具体报文、渠道侧错误码到 `auth.channel_rejected.detail` 的映射）。
  3. **合规拦截发生在哪一步** → `compliance.realname_required` / `compliance.playtime_blocked` 是在 `signin` 应答返回，还是登录成功后由业务端点返回。本草稿只在 `signin` 的错误清单里占位，不定分支。
- **`03-sync-conflict.md`**：`AccountSeed` 的下发通道——本草稿主张「不进 auth 报文」，但**定稿在 `profile-sync.md`**。
- **`account-info.md` 的字段 schema（客户端库待决）**：多渠道绑定到同一账号的模型未定 ⇒ **绑定 / 解绑 / 换绑端点不在本草稿范围**，`auth.md` 应显式留白而非预留空壳端点。
- **`06-platform-stack.md`**：token 签名密钥的保管与轮换、限流的实现形态与实际阈值、会话存储——均落 `operations/`，栈落定后再写。契约层只声明语义，不指定实现。

## 已裁决（2026-08-13）

四项取向 + 一项张力，全部由用户定案。**本节是裁决记录；正文各节已按此改写，二者以正文为准。**

| # | 事项 | 裁决 | 落点 |
|---|---|---|---|
| 1 | access token 形态与吊销即时性 | **自包含 JWT + 15 分钟 TTL**。吊销延迟 ≤ TTL，窗口内旧设备的 push 由 CAS 兜住，云端不被污染 | §2 · 数值初值表 |
| 2 | `refresh` 是否 rotation | **启用 rotation + 60 秒宽限窗口**（窗口内幂等回放同一对新 token，窗口外才判泄漏） | §4 · `refresh` 报文 |
| 3 | `Email` 走验证码还是密码 | **验证码优先、密码后置**；首版 `credential` 只有「标识符 + 一次性码」与「渠道 authCode」两形，**端点集封定在四个** | §3 · §1 |
| 4 | `session_revoked.detail` 是否加 `reasonKey` | **加**——触发源必须对代码可见，客户端按原因给出不同文案；取值集合待 02，字段现在就进契约 | §8 · envelope 台账 |
| 5 | 「刷新失败视同断线」的张力 | **松动，按判据拆两条**：网络失败 → 不硬阻塞（原语义不变）；收到明确的 `auth.session_revoked` → 硬阻塞重登 + 暂停退避 | 「与既有决策的张力」 |

**无遗留取向项。** 余下未定的全部是 `02` / `03` / `06` 的**前置依赖**（见上节），它们不改变本草稿定案的任何报文形状——待补的只是 `reasonKey` 取值表、第三方渠道换 openid 的细节、合规拦截的落点，以及运维侧的密钥与限流参数。

**因此 `auth.md` 现在可以落笔。** 它会带三处显式留白：`reasonKey` 取值表（待 02）· `compliance.*` 在 `signin` 的分支（待 02）· 绑定 / 解绑 / 换绑端点（待客户端 `account-info.md` 的多渠道模型）。
