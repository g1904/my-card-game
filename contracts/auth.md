# auth —— 登录 · 会话 · token 续期与吊销

> 覆盖 `/v1/auth/…` 四个端点的报文本体。**边界层不在此重复**：序列化与命名约定、`/v1/` 主版本、传输信封、错误体形状、错误码台账、版本协商——全部见 `envelope.md`，本文件只写 auth 域**相对它的差异与例外**。
> 客户端侧门面见 `game-design-documents/systems/services/account-service.md`（那里描述**客户端怎么用**；此处描述**报文长什么样**）。
> Source: `handoffs/2026-08-13-auth-endpoint-contract.md`。

## 1. 端点集：四个，封定

```
POST /v1/auth/challenge   请求一次性验证码（短信 / 邮件）      —— 无鉴权
POST /v1/auth/signin      渠道登录，换取会话                   —— 无鉴权
POST /v1/auth/refresh     用 refresh token 换新 access token   —— 无鉴权（凭据在 body）
POST /v1/auth/signout     主动登出，吊销当前会话                —— 需鉴权
```

后三个与 `account-service` 的三个 B 形态方法一一对位（`SignInAsync` / `RefreshTokenAsync` / `SignOutAsync`）。

**`challenge` 是第四个，且客户端尚无对位调用面。** `LoginChannel.Phone` 是已定案的首选渠道，手机号登录必然是「先下发验证码、再提交验证码」的两步握手——单个 `signin` 端点表达不了。它对客户端 API 面提出一条反向要求，见 §9。

**首版端点集就此封定在四个。** 密码路线整体后置（§3），因此不为它预留端点空壳（本库「先有设计再建文件」）。

**不设 `/v1/auth/me`。** 账号身份元数据在 `AccountInfo`，它是 `PlayerProfile` 的账号级字段，随 `/v1/profile/pull` 整聚合下行。另立一个身份查询端点会当场造出第二份真值。

**绑定 / 解绑 / 换绑端点不在本契约范围**——多渠道绑定到同一账号的模型未定（客户端 `account-info.md` 的字段 schema 待决）。此处**显式留白**，不预留空壳端点。

## 2. token 模型：短寿 access + 长寿 refresh

**双 token 是「静默刷新」这条已定客户端语义的必要条件，不是一个选项。** 单 token 模型下服务端要么接受过期 token（等于它没有过期），要么拒绝（那就没有静默刷新，只剩重登）。因此必须有一个与 access token 分离、寿命更长、**只用于换取 access token** 的刷新凭据。

| | access token | refresh token |
|---|---|---|
| 形态 | **自包含 JWT**（网关可离线验签） | **不透明随机串**（必须查库才能吊销） |
| 用途 | 每个 API 请求的 `Authorization: Bearer` | **只用于** `POST /v1/auth/refresh` |
| 客户端对位 | `Session.Token` / `Session.ExpiresAtUtc` | **不进 `Session`**，见下 |
| TTL | **15 分钟**（初值，见 §8） | **30 天滑动续期**（初值） |
| 失效时的 `code` | `auth.token_expired` | `auth.session_revoked` |

**access token 自包含的代价与兜底：**「被挤下线」的最坏生效延迟 = access token TTL。窗口内旧设备的 push 由 `revision` CAS 拒绝（`sync.conflict`），**云端不会被污染**，代价只是旧设备丢一次本地缓冲——这正是既定的 conflict 处置。多设备并发在本作是罕见路径（单人游戏、无跨玩家交互），为它给 profile push 这条最热的路径加一次中心校验读不划算。

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

第三方渠道（`WeChat` / `QQ`）走 `authCode`：客户端 SDK 拿到一次性授权码交给后端，**后端向渠道服务器换取 openid**——客户端不接触渠道 secret。这与 `account-service` 的定位「平台 SDK 与后端鉴权的唯一门面」一致。渠道侧换取的具体报文与渠道错误码到 `auth.channel_rejected.detail` 的映射待 `open-questions/02-account-compliance.md`。

## 4. 刷新：rotation + 60 秒宽限窗口（承重）

**启用 refresh token rotation**：每次刷新返回新的 refresh token、旧的立即失效；已被使用过的 refresh token 再次到达 → 判定为泄漏 → 吊销该账号全部会话。

**但裸 rotation 与 pillar #2 直接冲突，因此必须带宽限窗口。**「刷新请求已达、应答丢失」在移动网络下是常态：客户端仍持旧 refresh token 重试 → 被判重放 → 全账号吊销 → 玩家在轮回中途被硬踢下线。

**定案：旧 refresh token 在被轮换后的 60 秒内仍可被接受，且返回与上次相同的那一对新 token**（幂等回放，不再轮换）；**窗口外**再次出现 → 才判泄漏并吊销该账号全部会话。

> 这与 `pushId` 的「重复到达不再 `+1`，直接回上次结果」是**同一个模式，理由同源**——auth 域的幂等与 sync 域的幂等是同一条 pillar #2 在两个端点上的兑现，不是两套机制。

## 5. 强更闸门只在 `signin` 判定，`refresh` 不判定（承重）

`envelope.md` §7b 已定「闸门在签发 token 时判定一次，会话期内不因阈值提升而中途变严」。`refresh` 也签发 access token，若它也判定闸门，运营提升 `minAppVersion` 就会在**会话期内**把玩家踢出——直接违反 §7b 的实现语义与「仅两处硬阻塞」。

- `POST /v1/auth/signin` → 可返回 `client.version_unsupported`（`class: Upgrade`）。**这是协议维度强更闸门在 auth 域的唯一落地点。**
- `POST /v1/auth/refresh` → **永不**返回 `client.version_unsupported`，无论 `X-App-Version` 多旧。

漏掉这一条，`envelope.md` §7b 就只是一句无处兑现的话。

## 6. 鉴权例外与请求头

`envelope.md` §4a 的通则是「每个 API 请求都带 `Authorization`」。**auth 域是它的唯一例外域**：

| 端点 | `Authorization` | `X-App-Version` | `X-Content-Version` |
|---|---|---|---|
| `challenge` | 不带 | 带 | **可缺省**（登录前尚无生效 overlay） |
| `signin` | 不带 | **必带**（强更闸门的输入） | 可缺省 |
| `refresh` | 不带（凭据在 body） | 带（**仅日志，不判闸门**，见 §5） | 带 |
| `signout` | **必带** | 带 | 带 |

`X-Request-Id` 四个端点都带（`envelope.md` §4a，每次重试都换）。应答头照 §4b 全带——**含 `X-Flags-Version`**：登录应答是启动链上客户端能拿到 flags 版本的**最早一次机会**（`content-service` 取 flags 是登录之后的一步），这里搭上车正是 §4「随任意应答下发」的设计意图。

## 7. 全部四个端点必须幂等

弱网下 auth 域的每一个写入都会「请求已达、应答丢失」并被重试：`challenge` 的重发、`signin` 的重试、`refresh` 的重放（§4）、`signout`。**都必须能被安全重放。**

**`signout` 尤其要写明：对一个已失效的会话再次登出，返回 `204` 而非错误。** 若返回 `auth.token_invalid`，客户端会按 `envelope.md` §6 台账去走静默刷新——而它刚刚才主动登出。

## 8. 端点报文

> 字段形态在 `openapi.yaml` 落笔后以 spec 为准，语义以本文件为准（`envelope.md` §1）。

### `POST /v1/auth/challenge`

请求：

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `channel` | string | ✅ | 仅 `"Phone"` / `"Email"`；第三方渠道无此步 |
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
| `deviceId` | string | ✅ | 客户端生成、跨启动稳定的设备标识；**多设备裁决的输入**（规则待 `02`） |

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

错误：`auth.credential_invalid` · `auth.challenge_expired` · `auth.channel_rejected` · `client.version_unsupported`（§5）· `compliance.*`（清单待 `02`）· `rate.limited`。

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

### 数值初值（可调旋钮，非硬编码）

| 旋钮 | 初值 | 推导 |
|---|---|---|
| access token TTL | **15 分钟** | 它等于「被挤下线」的最坏生效延迟。15 分钟把窗口压到一次战斗量级以内，同时刷新频率对一次 1 小时的轮回只有 ~4 次，无感 |
| refresh token TTL | **30 天**滑动续期 | 覆盖「两周不玩、回来仍在登录态」这一移动游戏常态；滑动续期使活跃玩家永不被动重登 |
| refresh 宽限窗口 | **60 秒** | 需覆盖客户端指数退避的头几次重试；远短于 TTL，泄漏风险面可忽略 |
| 验证码有效期 | **5 分钟** | 通行值 |
| 验证码重发间隔 | **60 秒** | 通行值；短信是**有成本且被刷**的通道 |
| 单标识符验证码日上限 | **10 次** | 初值，待实测校准 |

**这些是待实测校准的初值，落点是后端配置而非代码常量。** 具体限流实现与阈值归 `open-questions/06-platform-stack.md`（栈落定后进 `operations/`）；契约层只声明语义，不指定实现。

## 9. 新增的两个错误码

登记进 `envelope.md` §6 台账（`envelope.md`「新增 `code` 一律在此登记」）：

| `code` | `class` | `OpError` | 理由 |
|---|---|---|---|
| `auth.credential_invalid` | `Fatal` | `Auth` | 自建渠道的凭据校验失败（验证码错、标识符格式非法）。既有 `auth.channel_rejected` 的语义是**第三方渠道侧**拒绝（`detail { channel }`），装不下这一类 |
| `auth.challenge_expired` | `Fatal` | `Auth` | 验证码过期。与上一条**分列**：玩家处置不同（重新获取 vs 重新输入），而客户端文案按 `code` 分辨 |

**不新增**：`auth.account_not_found` → 用既有 `resource.not_found`；渠道绑定冲突 → 多渠道绑定模型未定（§1），不预先立 `code`。

## 10. `auth.session_revoked` 的 `detail` 携带 `reasonKey`

`envelope.md` §6 要求 `auth.session_revoked` 的 `message` 必含**触发源**（另一设备登录 / 运营吊销），但 §5a 已定案**客户端不得解析 `message` 做任何分支**——触发源因此曾只存在于一个客户端不许读的字段里。

而触发源**确实需要驱动客户端行为**：客户端已定案错误文案「按 `code` 走 UI 层 `ErrorText`」，而「另一设备登录」与「账号被运营吊销」对玩家是两句完全不同的话，却共用同一个 `code`。

**因此 `detail` 为 `{ revokedAtUtc, reasonKey }`。** 这不是新增机制——`compliance.*` 两条台账已经在用 `reasonKey` 这个字段名做同一件事。

- **`reasonKey` 的取值集合待 `02` 的多设备裁决规则落定后填表**（此处显式留白），但**字段本身现在就进契约**：它是 `auth.md` 与 `02` 之间的接缝，先立字段、后填取值，`02` 落定时只补一张表，不必回头改报文形状。
- **连带纪律：客户端对未知 `reasonKey` 必须有兜底文案**（与 `envelope.md` §5b「未知 `code` → 按 `class` 降级」同构）。`02` 之后新增一个 `reasonKey` 不应要求客户端同批发版。

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
- **触发源只写在 `message` 里** — `envelope.md` §5a 已定案客户端不得解析 `message`，等于让这个信息对代码不可见（§10）。
- **`AccountSeed` 随 signin 应答下发 / 立 `/v1/auth/me`** — 与 `AccountInfo` 随 profile pull 下行制造两份真值（§1、§11）。
- **把 `signin` 的多设备裁决结果告知登录方**（如「已挤下线 1 台设备」）— 无客户端消费面；另一台设备会通过它自己的下一次请求得到 `auth.session_revoked`，这是既定路径。
- **`refresh` 凭据失效时返回 `server.unavailable`**（使客户端行为与「刷新失败视同断线」的原措辞严格一致）— 把一个确定的终态伪装成可重试的临时故障，玩家会一直看到「离线 · 待同步 N」而永远等不到恢复，与 §7c「`Upgrade` 类错误暂停退避」的立意正相反。

## Open questions

- **`auth.session_revoked.detail.reasonKey` 的取值集合**——待 `02-account-compliance.md` 的多设备并发裁决规则。**报文形状不受影响**，待补的只是一张取值表。
- **`compliance.*` 在 `signin` 的分支**——实名 / 防沉迷拦截是在 `signin` 应答返回，还是登录成功后由业务端点返回，待 `02`。本文件只在 `signin` 的错误清单里占位。
- **第三方渠道换取 openid 的具体报文**、以及渠道侧错误码到 `auth.channel_rejected.detail` 的映射——待 `02` 的「自建 vs 接第三方」。
- **绑定 / 解绑 / 换绑端点**——待客户端 `account-info.md` 的多渠道绑定模型（§1 显式留白）。
- **`refresh` 的滥用面与限流形态**——本文件把 `refresh` 的错误清单收紧为两条（§8），刻意不给 `rate.limited`，以保客户端两条路径在报文层面互斥。若 `06-platform-stack.md` 认定该端点必须限流，需回头松动这一条并同时给出客户端的第三条路径，**不能只在网关侧悄悄加**。
- **token 签名密钥的保管与轮换**、会话存储形态、限流的实现与实际阈值——均归 `06`，落 `operations/`。契约层只声明语义。

## 跨库待办（客户端侧，本库不代为决定）

需 `game-design-documents/` 另写一份 handoff——五点，见 `handoffs/2026-08-13-auth-endpoint-contract.md` 的「客户端侧影响」段：`account-service` 新增 challenge 方法 · refresh token 的客户端持有形态 · 「刷新失败」措辞按 §10 精化 · 两个新 `code` 的 `ErrorText` 文案 · `deviceId` 的生成与持久化落点。
