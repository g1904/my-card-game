# `auth.md` 端点报文契约成文

- id: 2026-08-13-auth-endpoint-contract
- date: 2026-08-13
- topic: contracts/auth（新建）· contracts/envelope（§4a 例外 + §6 台账三处）· contracts/_index · decisions
- status: distilled
- distilled-to: `contracts/auth.md`、`contracts/envelope.md`、`contracts/_index.md`、`decisions/_index.md`、`open-questions/01-contracts.md`、`open-questions/02-account-compliance.md`、`open-questions/03-sync-conflict.md`、`open-questions.md`、`answer-logs/log-auth-endpoint-contract.md`

## Intent（distilled）

**一句话：** auth 域封定为四个端点、双 token（短寿 JWT + 可轮换 refresh）、渠道分形 credential，其中 `refresh` 的宽限窗口与 `pushId` 的幂等回放是**同一条 pillar #2**，而强更闸门在 auth 域只有 `signin` 一个落地点。

来源：`inbox/archive/solution-draft-auth-endpoint-contract.md`（2026-08-12 产出，2026-08-13 由用户逐项裁决定案，`status: decided`）。

### 1. 端点集：四个，封定

`challenge` / `signin` / `refresh` / `signout`。后三个与 `account-service` 的三个 B 形态方法一一对位；**`challenge` 是推演出来的第四个**——`LoginChannel.Phone` 是已定案首选渠道，而手机号登录必然是「先下发验证码、再提交验证码」的两步握手，单个 `signin` 表达不了。它对客户端 API 面提出一条反向要求（见「客户端侧影响」）。

密码路线整体后置 ⇒ **端点集就此封定在四个**，不为它预留空壳。不设 `/v1/auth/me`（`AccountInfo` 随 profile pull 下行，另立端点即第二份真值）。绑定 / 解绑 / 换绑**显式留白**——多渠道绑定模型未定。

### 2. 双 token 是「静默刷新」的必要条件，不是选项

单 token 模型下服务端要么接受过期 token（等于它没过期），要么拒绝（那就没有静默刷新）。因此：

- **access token = 自包含 JWT，TTL 15 分钟**。网关可离线验签，profile push 这条最热路径不需要每次读会话存储。
- **refresh token = 不透明随机串，30 天滑动续期**，只用于 `POST /v1/auth/refresh`。
- 代价「被挤下线的最坏生效延迟 = TTL」由 `revision` CAS 兜住：窗口内旧设备的 push 被 `sync.conflict` 拒绝，**云端不被污染**，代价只是旧设备丢一次本地缓冲——这正是既定的 conflict 处置。

**`Session` record 一字不改**：refresh token 由客户端 `HttpAccountBackend` 内部持有、落 `user://cache/`，与 `SyncEnvelope` **同构**（都是客户端持有、后端定义、与玩法无关的传输层元数据；不进 Profile、不进存档 schema、不参与迁移、切账号即失效）。

### 3. 渠道分形 credential，首版只有两类形态

`channel` 取值与 C# `LoginChannel` 逐字相同，四渠道走同一端点，`credential` 以 `oneOf` + `discriminator` 分形。**`Email` 走验证码、密码后置**，因此首版只有「标识符 + 一次性码」（`Phone` / `Email`）与「渠道 authCode」（`WeChat` / `QQ`）两类。密码届时是**加**第五形，不推翻任何一条。

### 4. rotation + 60 秒宽限窗口（承重）

裸 rotation 与 pillar #2 直接冲突：「刷新请求已达、应答丢失」→ 客户端持旧 token 重试 → 被判重放 → 全账号吊销 → 玩家在轮回中途被硬踢下线。

定案：**旧 refresh token 在轮换后 60 秒内仍可被接受，且回与上次相同的那一对新 token**（幂等回放，不再轮换）；窗口外才判泄漏。**这与 `pushId` 的「重复到达不再 `+1`，直接回上次结果」是同一个模式、理由同源**——auth 域的幂等与 sync 域的幂等不是两套机制。

### 5. 强更闸门只在 `signin`

`envelope.md` §7b 定「闸门在签发 token 时判定一次，会话期内不变严」。`refresh` 也签发 access token——若它也判闸门，运营提升 `minAppVersion` 就会在会话期内把玩家踢出。故 `refresh` **永不**返回 `client.version_unsupported`。**这是 §7b 在端点层面的唯一落地点**，漏掉它 §7b 就是一句无处兑现的话。

### 6. auth 域是 `envelope.md` §4a 的唯一鉴权例外域

四端点的 `Authorization` / `X-App-Version` / `X-Content-Version` 各不相同（例外表见 `contracts/auth.md` §6）。应答头照 §4b 全带——**含 `X-Flags-Version`**：登录应答是启动链上客户端能拿到 flags 版本的最早一次机会。

### 7. 四个端点全部幂等

尤其 `signout`：**对已失效会话再次登出回 `204` 而非错误**——若回 `auth.token_invalid`，客户端会按台账去走静默刷新，而它刚刚才主动登出。

### 8. `session_revoked.detail` 扩为 `{ revokedAtUtc, reasonKey }`

`envelope.md` 要求 `message` 必含触发源，而 §5a 又禁止客户端解析 `message`——触发源曾只存在于一个客户端不许读的字段里。但它**确实需要驱动客户端行为**：「另一设备登录」与「账号被运营吊销」对玩家是两句完全不同的话，却共用一个 `code`。

`reasonKey` 不是新增机制（`compliance.*` 已在用同名字段）。**取值集合待 `02`，但字段本身现在就进契约**——它是 `auth.md` 与 `02` 之间的接缝：先立字段、后填取值，`02` 落定时只补一张表，不必回头改报文形状。连带纪律：**客户端对未知 `reasonKey` 必须有兜底文案**。

### 9. 新增两个错误码，`AccountSeed` 不进 auth 报文

- `auth.credential_invalid`（`Fatal` / `Auth`）：自建渠道凭据校验失败——既有 `auth.channel_rejected` 语义是**第三方渠道侧**拒绝，装不下这一类。
- `auth.challenge_expired`（`Fatal` / `Auth`）：与上一条分列，因玩家处置不同（重新获取 vs 重新输入）。
- `AccountSeed` **不随任何 auth 应答返回**：它落 `AccountInfo`，本就随 `/v1/profile/pull` 下行；auth 再带一份即两处真值。`signin` 只带 `isNewAccount`（驱动首玩引导与日志，**不是玩法判断的输入**）。定稿权仍在 `profile-sync.md`。

## Clarifications（interview 产物）

草稿于 2026-08-12 产出时留了四项取向 + 一项张力；**2026-08-13 由用户逐项裁决，本次 `/analyze-new-ideas` 因此未触发新的 interview。** 逐条裁决：

| # | 事项 | 用户裁决 | 它改动了原始输入的哪一句 |
|---|---|---|---|
| 1 | access token 形态与吊销即时性 | **自包含 JWT + 15 分钟 TTL** | 草稿原并列「JWT 离线验签」与「不透明 + 中心校验」两种取向，未选定 |
| 2 | `refresh` 是否 rotation | **rotation + 60 秒宽限窗口**（窗口内幂等回放，窗口外判泄漏） | 草稿原把宽限窗口列为需裁决的取向 |
| 3 | `Email` 走验证码还是密码 | **验证码优先、密码后置**；由此**端点集封定在四个** | 草稿原在 `credential` 里为 `Email` 保留 password 分支 |
| 4 | `session_revoked.detail` 是否加 `reasonKey` | **加**——触发源必须对代码可见 | 草稿原把「加字段 vs 只写 message」列为取向 |
| 5 | 「刷新失败视同断线」的张力 | **松动，按判据拆两条**：网络失败 → 不硬阻塞（原语义不变）；收到明确的 `auth.session_revoked` → 硬阻塞重登 + 暂停退避 | 推翻了 `account-service.md`「刷新失败视同断线」这句话的**覆盖面**（不是它的内容）——判据由「失败了」改为「收到了明确应答」 |

**第 5 项是一次跨库松动**：被松动的那句话住在客户端库。本 handoff 只在 `contracts/auth.md` §10 写下**契约侧的对位**（`refresh` 的错误清单收紧为两条，使两条路径在报文层面互斥），客户端侧的措辞修正**不由本库代为改动**——见下方「客户端侧影响」。

**无遗留取向项。** 余下未定的全部是 `02` / `03` / `06` 的前置依赖，它们不改变本次定案的任何报文形状。

## 由本库校验推演新增（草稿未点名）

- **`envelope.md` §6 台账 `auth.token_expired` 行的「客户端处置」单元格仍写着旧措辞**「刷新失败视同断线走 sync 缓冲通道，不硬阻塞」——裁决 #5 直接精化了它。草稿的「后果」只列了三处 envelope 增改，漏了这一处；本次一并改写为两条路径（判据 = 是否收到 `auth.session_revoked`）。
- **`auth.credential_invalid` 的语义需覆盖「标识符格式非法」**：草稿在 `challenge` 的错误清单里这样用了它，但在 §9 只描述为「验证码错 / 密码错」。台账描述据此写宽为「自建渠道的凭据校验失败（验证码错、标识符格式非法）」。

## Open questions

- **`reasonKey` 的取值集合**、**`compliance.*` 在 `signin` 的分支**、**第三方渠道换 openid 的报文与错误码映射** —— 全部待 `open-questions/02-account-compliance.md`。报文形状不受影响。
- **绑定 / 解绑 / 换绑端点** —— 待客户端 `account-info.md` 的多渠道绑定模型。
- **`refresh` 的滥用面与限流形态** —— 契约侧刻意不给 `rate.limited`（为保客户端两条路径互斥）。若 `06` 认定该端点必须限流，需回头松动并同时给出客户端的第三条路径，**不能只在网关侧悄悄加**。
- **token 签名密钥的保管与轮换 · 会话存储 · 限流实现与实际阈值** —— 归 `06`，落 `operations/`。

## Notes / triage

- 契约面自此只剩 `profile-sync.md` 一份；`contracts/_index.md` 的 `auth.md` 状态行由「计划中」改「已成文」。
- **不影响存档 schema**：本次涉及的一切都是传输层元数据，不进 `PlayerProfile`、不 bump `schemaVersion`、无迁移。
- **不影响 `revision` / `pushId` 语义**：auth 域与 profile 域完全解耦。
- 数值旋钮（TTL / 宽限窗口 / 验证码参数）是**待实测校准的初值**，落点是后端配置而非代码常量。
- ADR 候选④已登记进 `decisions/_index.md`：**auth 域的幂等 = sync 域的幂等**（同一条 pillar #2 的两次兑现）。

## 客户端侧影响

**是**——本 handoff 触及客户端 ↔ 后端边界的语义。受影响的客户端成分：**`account-service`**（`sync-service` 仅在「刷新失败 → 缓冲通道」这条既有衔接上被间接提及，语义不变；`content-service` 无关）。

需 `game-design-documents/` **另写一份 handoff**，本库不代为改动：

1. **`account-service` API 面缺一个方法** —— 验证码下发无对位调用面。建议新增 `Task<OpResult> RequestSignInChallengeAsync(LoginChannel channel, string identifier, CancellationToken ct)`（B 形态）。
2. **refresh token 的客户端持有形态** —— `Session` record 不改；refresh token 由 `HttpAccountBackend` 内部持有、落 `user://cache/`、原子写、跨启动保留、切账号即失效（与 `SyncEnvelope` 同构）。
3. **「刷新失败」的措辞需精化**（裁决 #5）—— `account-service.md`「意图」与 API 面 `RefreshTokenAsync` 的失败语义一栏，须改写为两条路径：**网络失败 → 缓冲通道**、**收到 `auth.session_revoked` → 硬阻塞重登 + 暂停退避**；判据是「有没有收到明确应答」。
4. **两个新 `code` 的 `ErrorText` 文案** —— `auth.credential_invalid` / `auth.challenge_expired`，落 `ux/error-and-blocking-ux.md`。另需**未知 `reasonKey` 的兜底文案**（§8 的连带纪律）。
5. **`deviceId` 的生成与持久化落点** —— 跨启动稳定、切账号不变；它是 `signin` 的必填字段与多设备裁决的输入。
