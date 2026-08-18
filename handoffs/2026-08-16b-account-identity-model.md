# 账号身份模型：身份主体自建 · account↔identity 一对多 · 绑定与改名端点

- id: 2026-08-16b-account-identity-model
- date: 2026-08-16
- topic: contracts/auth（§1 端点集四→七 · §3 换 openid 义务与错误映射 · §9 三个新 code）· contracts/envelope（§6 台账三行 + `channel_rejected.detail` 扩字段）· contracts/profile-sync（§5 写入表两行→四行 + 白名单三行 + 护栏加固）· contracts/_index · open-questions/02
- status: distilled
- distilled-to: `contracts/auth.md`、`contracts/envelope.md`、`contracts/profile-sync.md`、`contracts/_index.md`、`open-questions/01-contracts.md`、`open-questions/02-account-compliance.md`、`open-questions.md`、`open-questions/update-log.md`、`answer-logs/log-account-identity-model.md`
- counterpart: `game-design-documents/handoffs/2026-08-16e-account-identity-client-adoption.md`

## Intent（distilled）

**一句话：「账号自建还是接第三方」不是一个二选一——它盖住了三层各自独立的东西，分开之后答案是唯一的。**

### 三层切分

| 层 | 内容 | 结论 |
|---|---|---|
| **A. 身份主体** | `accountId` 的发放、账号生命周期、会话签发与吊销 | **自建** |
| **B. 登录凭据（渠道）** | 玩家用什么证明自己是谁 | 两类并存，形态在 `contracts/auth.md` §3 已封定 |
| **C. 原子能力** | 短信 / 邮件下发、实名核验、支付验票 | 一律外接，以适配器隔离 |

A 只能自建、C 只能外接、B 已经定完——**没有一层是取向**。

### A 层自建的四条逼迫理由

不选托管身份服务（Firebase Auth / Auth0 / Cognito 一类）不是选型偏好：

1. `accountId` 是 profile 主键——用外部服务的 user id 当键，等于把存档的主键租给第三方，换服务商 = 全量存档迁移。
2. 账号创建时刻必须由本方掌控——建号要与 `accountSeed` 写入 profile 骨架同一步；托管 IdP 的建号在它那侧，只能靠 webhook 事后追平，而那条链路的失败形态是「玩家登录成功但没有存档」。
3. 会话语义是本方业务语义——60 秒宽限窗口的幂等回放、`session_revoked.detail.reasonKey`、强更闸门只在 `signin` 判定，没有哪个托管 IdP 现成表达。
4. 合规能力必须能落到账号上——注销冷静期、数据导出、实名状态、防沉迷时段都要读写账号状态并影响 `signin` 分支。

**同时明确不做：本方不成为 OAuth2 / OIDC provider。** 没有任何第三方需要接入我们的账号。

### B 层：account ↔ identity 一对多

`account` 持 `accountId` / `createdAtUtc` / `status`；`identity` 持 `accountId` / `channel` / `channelUserId` / `idKind` / `boundAtUtc`，唯一约束在 `(channel, channelUserId)`；一个 account 在同一 channel 下最多一条 identity。

`signin` 语义随之确定：校验 credential → 取 `(channel, channelUserId)` → 查 identity；命中取其 `accountId`，未命中则建 account + identity + profile 骨架并应答 `isNewAccount: true`。**既有报文一字不改。**

**承重：绝不做隐式账号合并。** 同一个人先用手机号、再用微信登录 = 两个 account、两份存档，这是正确行为。合并只能由已登录态主动 `bind`，且目标渠道未被占用。

### 落地面

- **端点集由四扩到七**：`bind` / `unbind` / `nickname`（均需鉴权），全部进 `auth.md`，不单开第六份契约。
- **三个新 `code`**：`auth.identity_already_bound` · `auth.identity_required` · `auth.nickname_rejected`。
- **`channel_rejected.detail` 扩 `channelCode`**，渠道原始码原样透传、客户端不解析。
- **渠道换 openid 的两类错误映射**：渠道明确拒绝 → `auth.channel_rejected`（`Fatal`）；渠道不可达 / 超时 / 限流 → `server.unavailable`（可重试）。把第二类也报成 `channel_rejected` 是一个具体缺陷——它是 `Fatal`，会把一次渠道抖动变成终态。
- **`profile-sync.md` §5 后端写入表由两行变四行**（加 `/accountInfo/identities` 与 `/accountInfo/createdAtUtc`），破坏性契约变更，与客户端同批。

## Clarifications（interview 产物）

三项，均改写了草稿原文：

- **`AccountInfo.Nickname` 由谁写进 profile？** → **客户端写，后端只判定**。草稿两侧都没交代，而草稿自己立的「够格进写入表」判据（真值只可能在服务端产生 + 客户端无其他通道）恰好判它不够格——昵称是玩家输入的。故 `/accountInfo/nickname` **进透明白名单（后端只读，供合规抽查）但不进写入表**，改名端点只返回接受 / 拒绝。**如实记下的代价**：改包可绕过敏感词判定；本作单人、昵称无玩家间可见性，残留风险面只剩合规抽查，由后端侧的存量扫描承接（归 `02`）。
- **`Status` 与 `CreatedAtUtc` 怎么下行？** → **只加 `createdAtUtc`（进写入表，与 `accountSeed` 同一写入时机），`status` 不进客户端。** `status` 的客户端表现全部由 `signin` 分支与 `compliance.*` 承载，本地副本没有消费点且会在会话中途过期（封禁发生时本地仍写着 `active`）。这推翻了 counterpart 草稿把 `Status` 列进 `AccountInfo` 字段表的那一行。
- **改名端点本次是否落契约？** → **同批落进 `auth.md`**（端点集因此是七个而非六个）。客户端侧已定案要 `SetNicknameAsync`，只记承接项就会造出「客户端有方法、后端无端点」的两侧不一致——正是本次运行要消灭的那类漂移。阈值与词表口径仍归 `06` / `02`。

## Open questions

- **`02` 的合规分级若定「实名为建号前置」**，`signin` 的「未命中即建号」要插一步。报文形状不受影响，插的是服务端流程的一个前置判定。
- **昵称的改名频次阈值与敏感词词表口径**——前者归 `06`（后端配置，与 `auth.md` §8 的旋钮同处），后者归 `02` 的合规分级。`auth.nickname_rejected.detail.reasonKey` 的取值集合随后者落定。
- **`auth.nickname_rejected` 与合规存量扫描的关系**：改名端点拒绝的是「这一次提交」，而客户端可绕过写入意味着 profile 里仍可能存在未过审昵称。存量扫描的触发频率与处置（改写 / 置空 / 标 `restricted`）归 `02`。

## Notes / triage

来源：`inbox/solution-draft-account-identity-model.md`（`status: decided`，4 项取向已于 08-16 定案）。与客户端库同批运行，counterpart handoff 见文件头。

`systems/account.md` **不建**——它以 `06` 技术栈落定为前置（本库「先有设计再建文件」）。本 handoff 的三层切分与 identity 模型是它日后的开篇材料。

## 客户端侧影响

改动客户端 ↔ 后端边界语义，受影响成分 **`account-service`**（新增三个方法面 + `SignInAsync` 扩 credential 参数）与 **`sync-service`**（profile 的 `accountInfo` 段多出三个字段）。客户端侧的承接已于同日在 `game-design-documents/` 同批落笔，见 counterpart。**本库不代为决定客户端形态**。
