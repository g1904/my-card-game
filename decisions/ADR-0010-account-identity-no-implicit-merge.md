# ADR-0010 — 身份主体自建、`account ↔ identity` 一对多，绝不做隐式账号合并

- **状态：** Accepted
- **日期：** 2026-08-16
- **来源：** `handoffs/2026-08-16b-account-identity-model.md` · `answer-logs/log-account-identity-model.md`

## 背景

「账号系统自建还是接第三方」曾作为一个二选一挂在待答清单里，而它实际盖住三层各自独立的东西：**身份主体**（`accountId` 与存档主键）、**登录凭据**（渠道 credential）、**原子能力**（短信 / OAuth 换取）。同时 `contracts/auth.md` 有两处显式留白——多渠道绑定模型、第三方渠道换 openid 的报文——而客户端侧已定案要 `SetNicknameAsync`，不同批落契约就会造出「客户端有方法、后端无端点」的两侧漂移。

## 决策

**身份主体自建，`account ↔ identity` 一对多，`identity` 唯一约束落在 `(channel, channelUserId)`，同一 account 在同一 `channel` 下最多一条 identity。**

- **绝不做隐式账号合并。** 合并只能由已登录态主动 `POST /v1/auth/bind`；目标渠道已被占用即报 `auth.identity_already_bound`，**不静默转移 identity**。
- `accountId` 随机不可枚举、终身不变，**不用自增整数、不用手机号 / openid**。
- 第三方渠道换 openid 履行三条后端义务（客户端只交 `authCode`、永不接触渠道 secret；`channelUserId` 取跨应用统一标识、`idKind ∈ { openid, unionid }`；渠道错误分两类映射——明确拒绝 → `auth.channel_rejected`（`Fatal`，`detail` 扩 `{ channel, channelCode }` 原样透传），不可达 / 超时 / 限流 → `server.unavailable`（`Retryable`））。
- 端点集由四扩到七，新增 `bind` / `unbind` / `nickname`（均需鉴权），全部并入 `auth.md`，**不单开契约**；新增三个 `code`：`auth.identity_already_bound` · `auth.identity_required` · `auth.nickname_rejected`。

实体表、唯一约束、三条义务与两类错误映射表 → `contracts/auth.md` §1 §1a §3a §9。

## 理由

A 层只能自建的四条逼迫理由（`contracts/auth.md` 备选方案表、`handoffs/2026-08-16b-account-identity-model.md`）：`accountId` 是 profile 主键，用外部 user id 等于**把存档主键租给第三方**，换服务商即全量存档迁移；建号必须与 `accountSeed` 写入 profile 骨架同一步，托管 IdP 只能 webhook 事后追平，失败形态是「玩家登录成功但没有存档」；三条会话语义（宽限窗口幂等回放、`session_revoked.reasonKey`、强更闸门只在 `signin`）无托管 IdP 现成表达；合规能力必须能落到账号状态上并影响 `signin` 分支。

不隐式合并的承重论证在 `contracts/auth.md` §1a：**云端权威下一账号一份 profile，静默合并必然要丢弃其中一份存档，而玩家不会预期一次登录会删掉自己的进度。**

渠道错误分两类的论证与 `contracts/purchase.md` §3 同源：把渠道抖动也报成 `channel_rejected` 是一个具体缺陷——它是 `Fatal`，会把一次抖动变成终态。

## 备选方案

- **接托管身份服务（Firebase Auth / Auth0 / Cognito）作身份主体** — 主键租给第三方；建号时刻不在本方；三条会话语义无处表达；境外托管与国内数据存放要求冲突。
- **以渠道 openid 直接作 `accountId`** — 换渠道即换键；个人标识进主键；手机号渠道无对应物，两类渠道主键来源分叉。
- **本方实现完整 OAuth2 / OIDC provider** — 无第三方消费者，成本沉没在 discovery / JWKS / 授权码流。
- **登录时按手机号 / 邮箱隐式合并已有渠道账号** — 必然丢弃一份存档。
- **同一 `channel` 允许绑多条 identity** — 无玩家价值，却让解绑语义与找回路径分叉。
- **为绑定 / 解绑单开一份契约** — 同一套 credential、同一套会话、同一域，`oneOf` 判别式要在两份文档各写一遍。
- **另立 `GET /v1/auth/identities` 下行绑定列表 / 由客户端自行写入** — 前者造第二下行口（同 `/v1/auth/me` 被否的理由）；后者在新设备首登时列表为空。
- **昵称由后端写进 profile** — 不满足 `contracts/profile-sync.md` §5 写入表判据（真值在客户端输入）。
- **`account.status` / `channelUserId` 随 `AccountInfo` 下行** — 无消费点；会话中途过期的第二真值；内部键跨边界即成契约。
- **渠道不可达也报 `channel_rejected`** — 见上。

## 后果

- `signin` 语义自此封定为「查 identity，命中取 `accountId`，未命中建 account + identity + profile 骨架并应答 `isNewAccount: true`」，**§8 signin 报文一字不改**。
- `channelUserId` / `idKind` **永不跨边界**，也不进玩家可导出物——连带约束 `contracts/compliance.md` §8 导出物不含渠道内部键。
- `contracts/profile-sync.md` §5 后端写入表由两行扩为四行（新增 `/accountInfo/identities` 与 `/accountInfo/createdAtUtc`），属**破坏性契约变更**；`contracts/envelope.md` §6 台账新增三行并为 `channel_rejected.detail` 扩字段。
- 放弃：不做 OAuth2 / OIDC provider；放弃同渠道多绑；放弃昵称的服务端权威写入（改包可绕过判定，残留风险由存量扫描承接 → `open-questions/02-account-compliance.md`）。
- 微信开放平台资质与 `unionid` 的取用是**不可逆**选择，且必须在首个玩家建号之前完成 → `contracts/auth.md` §3a；选型与排期归 `open-questions/06-platform-stack.md`。
- 合规拦截落在 `signin`、建号先于合规判定且拦截不回滚建号，那条在 §1a 求值顺序框内，权威属 `ADR-0011`——本 ADR 不复述。
- 客户端侧对位（`account-service` 新增四方法、`SignInAsync` 扩 credential 参数、`AccountInfo` 字段面）权威在 `game-design-documents/systems/services/account-service.md` 与 `game-design-documents/systems/player-profile/account-info.md`；承接见 `game-design-documents/handoffs/2026-08-16e-account-identity-client-adoption.md`。
