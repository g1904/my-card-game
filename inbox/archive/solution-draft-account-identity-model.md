---
type: solution-draft
date: 2026-08-16
question: 账号系统自建还是接第三方？（重账号的注册 / 登录 / 找回 / 多端绑定全链路由谁承担）
source: open-questions/02-account-compliance.md → 「账号系统自建还是接第三方」
targets: contracts/auth.md（§1 绑定端点留白 · §3 换 openid 留白 · §9 错误码）· contracts/envelope.md §6 台账 · contracts/profile-sync.md §5 后端写入表 · systems/account.md（待建）· open-questions/02-account-compliance.md
counterpart: game-design-documents/inbox/solution-draft-account-identity-model.md
status: distilled
reviewed: 2026-08-16 —— 4 项取向全部按推荐定案；提炼时另有 3 项经 interview 裁决（昵称由客户端写·后端只判定 · `status` 不进客户端、只加 `createdAtUtc` · 改名端点同批落契约）
distilled-to: handoffs/2026-08-16b-account-identity-model.md
---

> **4 项取向已于 2026-08-16 全部定案**（含「与既有决策的张力」那一处裁决）。定案内容见文末「已定案的取向（2026-08-16）」，正文各处已随之改写为定案措辞。

# 方案草稿 — 账号自建 vs 接第三方

## 问题

ADR-0003 定下**重账号 · 已删游客态**，意味着注册 / 登录 / 找回 / 多端绑定全链路都要有；但「这条链路自建，还是接渠道账号 / 托管身份服务」一直未定。

它卡着的东西比它本身多：`contracts/auth.md` 的四端点报文虽已封定，但其中**两处显式留白**（§1 绑定 / 解绑端点、§3 第三方渠道换取 openid 的报文与错误码映射）直接以本条为前置；`open-questions.md` 的「解锁顺序」把它列为第 2 位，理由正是「自建 vs 第三方是其余全部取值表的前置」。

**本草稿只答这一条。** 合规能力的分级（②）、多设备并发裁决与 `reasonKey` 取值表（③）、风控形态（④）是同分片的另外三条，此处只在**接缝处**声明它们如何挂接，不代它们落表。

## 约束（来自既有设计）

- **重账号 · 云端权威 · 无游客态**，登录渠道优先级 手机 / 邮箱 → 微信 / QQ → 海外 / 跨平台 —— `game-design-documents/decisions/ADR-0003-online-cloud-authority.md`（Accepted）。
- **`accountId` 是权威 profile 的键**，且 `AccountSeed` 在**账号创建时**由后端写进该账号的 profile 骨架 —— `contracts/auth.md` §11、`contracts/profile-sync.md` §2。⇒ 账号的创建时刻与主键归属是本方的事，不能是一个外部服务的副产品。
- **四渠道共用一个 `signin` 端点**，靠 `credential` 的 `oneOf` 判别式分形；首版只有「标识符 + 验证码」与「渠道 authCode」两类形态 —— `contracts/auth.md` §3。
- **双 token 模型是既定的**（自包含 JWT 15 min + refresh rotation + 60 秒宽限窗口），且 `signout` / `refresh` 的幂等语义已封定 —— `contracts/auth.md` §2 §4 §7。
- **不设 `/v1/auth/me`**：账号身份元数据在 `AccountInfo`，随 `/v1/profile/pull` 整聚合下行 —— `contracts/auth.md` §1 §22 行。
- **后端对 profile 透明段只读，写入字段表封闭在两项**（`/accountInfo/accountSeed`、`/entitlement/bundleGrantOrdinal`），扩表须显式引用护栏、不得静默加行 —— `contracts/profile-sync.md` §5。
- **pillar #3 契约单点**：两侧唯一耦合点是协议，任何一侧不得私自扩展报文。
- **技术栈未定** ⇒ 本草稿停在**协议与语义层**，不指定语言 / 框架 / 存储 / 服务商（`06-platform-stack.md`）。

## 建议方案

### 一、把「自建 vs 第三方」拆成三层，分别回答（这是本草稿的主张）

`[既有推演]`

这个问题之所以久悬，是因为它被当成一个二选一，而实际有三层各自独立的东西被同一个词盖住了：

| 层 | 内容 | 建议 |
|---|---|---|
| **A. 身份主体** | `accountId` 的发放、账号生命周期（创建 / 状态 / 注销）、会话签发与吊销 | **自建** |
| **B. 登录凭据（渠道）** | 玩家用什么证明自己是谁：手机 / 邮箱验证码、微信 / QQ 授权 | **两类并存**，形态 `auth.md` §3 已封定 |
| **C. 原子能力** | 短信 / 邮件下发、实名核验、支付验票 | **一律接第三方**，以适配器隔离 |

三层分开后，答案是**唯一**的，而非取向：A 只能自建、C 只能外接、B 已经在契约里定完了。

### 二、A 层身份主体：自建（`accountId` 由本方发放）

`[既有推演]`

不选托管身份服务（Firebase Auth / Auth0 / Cognito 一类）**不是选型偏好，是四条既定设计逼出来的**：

1. **`accountId` 是 profile 的主键。** 用外部服务的 user id 当键，等于把存档的主键租给第三方——换服务商 = 全量存档迁移，且迁移期间「同一个人」在两套 id 下有两份档。
2. **账号创建时刻必须由本方掌控。** `auth.md` §11 / `profile-sync.md` §2 要求账号创建时同一步写入 profile 骨架与 `accountSeed`。托管 IdP 的建号发生在它那侧，本方只能靠 webhook 事后追平——那是一条会失败、会乱序、会重放的链路，而它的失败形态是「玩家登录成功但没有存档」。
3. **会话语义是本方业务语义。** 60 秒宽限窗口的幂等回放（§4）、`session_revoked.detail.reasonKey`（§10）、强更闸门只在 `signin` 判定（§5）——没有哪个托管 IdP 现成表达这三条，而它们各自都是承重的。
4. **合规能力必须能落到账号上。** 注销冷静期、数据导出、实名状态、防沉迷时段——这些要读写账号状态并影响 `signin` 的应答分支，托管在外部则每一条都要跨一次网络且真值在别人手里。国内渠道的数据存放地要求（`06`）也基本排除境外托管身份服务。

**同时明确不做的一件事：本方不成为 OAuth2 / OIDC provider。** 没有任何第三方需要接入我们的账号；实现一套标准 OIDC（授权码、PKCE、discovery、JWKS 对外暴露）是给不存在的消费者付成本。`auth.md` 已定的双 token 是一个**精简私有模型**，这条建议只是把它显式化。

### 三、B 层登录凭据：identity 与 account 分离的一对多模型

`[通行做法]` + `[既有推演]`

移动游戏账号体系的通行形态，也是唯一能同时满足「同一人多渠道登录到同一份存档」与「渠道可增可减」的形态：

```
account  ──1───n──  identity
```

- **`account`** 持有 `accountId`（主键）· `createdAtUtc` · `status`。
- **`identity`** 持有 `accountId` · `channel` · `channelUserId` · `boundAtUtc`，唯一约束在 **`(channel, channelUserId)`**。
- 一个 `account` 在同一 `channel` 下**首版最多一条** identity（多绑同渠道无玩家价值，却让解绑语义与找回路径分叉）。

**`signin` 的语义随之确定：** 校验 credential → 取得 `(channel, channelUserId)` → 查 identity。命中 → 取其 `accountId`；未命中 → **建 account + identity + profile 骨架（含 `accountSeed`），应答 `isNewAccount: true`**。这与 `auth.md` §8 的 `isNewAccount` 字段、§11 的建号时写 seed 完全对齐，无需改任何报文。

**⚠ 承重：绝不做隐式账号合并。** 同一个人先用手机号登录、再用微信登录，会得到**两个** account、两份存档，这是**正确行为**。想合并只能由**已登录态**主动发起绑定（见下），且目标渠道未被占用；已被占用 → 明确报错，**不静默转移 identity**。理由是云端权威下一账号一份 profile：静默合并必然要丢弃其中一份存档，而玩家不会预期一次登录会删掉自己的进度。这条与 pillar #1「云端是权威」是同一件事的两面。

### 四、绑定 / 解绑端点：补 `auth.md` §1 的留白，不单开契约

`[既有推演]`

```
POST /v1/auth/bind     绑定一个渠道到当前账号     —— 需鉴权
POST /v1/auth/unbind   解绑一个渠道               —— 需鉴权
```

- **`bind` 的 body 复用 `signin` 的 `credential` 判别式**（同一个 `oneOf`），不新造形态。Phone / Email 的绑定同样先走 `challenge`——`auth.md` §8 的 `purpose` 已预留 `"Rebind"`，此处正是它的消费点。
- **幂等**（auth 域四端点全幂等的纪律外扩到这两个）：重复绑同一 identity 到**同一** account → `200`；绑到**另一** account 已占用的 identity → `auth.identity_already_bound`。
- **`unbind` 解绑一条不存在的绑定 → `204`**（与 `signout` 对已失效会话返回 `204` 同一条纪律）。
- **解绑到零条 identity → 拒绝**（`auth.identity_required`）：账号将永久不可登录，等于一次绕过合规注销流程的静默注销。注销有它自己的路径（②）。
- **不为绑定单开一份契约文档。** 它是 auth 域的同一套 credential 与同一套会话，进 `auth.md` §1 的既有留白位；契约文档表不变。

### 五、第三方渠道换 openid：契约只声明后端义务与错误映射

`[既有推演]` + `[通行做法]`

`auth.md` §3 把「渠道侧换取的具体报文与渠道错误码映射」留给了本条。建议**契约层只写三条义务，渠道 API 的具体调用形态归 `operations/`**（它随渠道文档变动，写进契约会让契约跟着渠道版本漂）：

1. **客户端只交 `authCode`，永不接触渠道 secret。** 与 `account-service` 的定位「平台 SDK 与后端鉴权的唯一门面」一致，`auth.md` §3 已述，此处只确认它是后端义务的镜像。
2. **`channelUserId` 的取值：优先取跨应用统一标识（如微信 `unionid`），无则取应用内标识（`openid`）**，并在 identity 上记 `idKind ∈ { openid, unionid }`。这条是**不可逆的**：`openid` 是 per-app 的，一旦以它建了 identity，日后再想统一到 `unionid` 需要一次全量身份迁移。**已定案（08-16）：申请微信开放平台，首版即以 `unionid` 建 identity**——`idKind` 字段仍保留，因为它承载「这条 identity 当初以哪种标识建立」这一事实，且第三档海外渠道未必都有统一标识。
3. **渠道错误分两类映射，且必须在报文层面可区分**：
   - 渠道**明确拒绝**（authCode 无效 / 过期 / 应用被封）→ `auth.channel_rejected`（`Fatal`），`detail = { channel, channelCode }`，`channelCode` 为渠道原始错误码**原样透传**；**客户端不解析它、只随日志上报**（与 §5a「客户端不得解析 `message` 做分支」同构）。
   - 渠道**服务不可达 / 超时 / 限流**（我们这一侧无从判定凭据真伪）→ `server.unavailable`（**可重试**）。
   
   **把第二类也报成 `channel_rejected` 是一个具体的缺陷**：它是 `Fatal`，客户端会把一次渠道抖动当成终态、让玩家重走登录流程。这与 `purchase.md` §3「平台服务不可达须与『收据无效』在报文层面可区分」是同一条，理由同源。

### 六、C 层原子能力：一律外接，以适配器隔离

`[通行做法]`

短信 / 邮件下发、实名核验、支付验票**没有自建选项**（资质、通道、平台校验各自都在别人手里）。建议的唯一纪律是：

- **每类能力在后端内部有一个稳定的内部接口，服务商实现可换**。理由与客户端的 `IAccountBackend` / `BackendSelector` 同源：短信通道是**会被换、会需要多供应商灾备**的一类依赖。
- **服务商的错误码不上契约面**，一律先归一到本库已有的 `code`（`rate.limited` / `auth.credential_invalid` / `auth.challenge_expired` / `server.unavailable`）。具体服务商选型与灾备策略归 `06`。

### 七、账号状态：`status` 是 auth 域的字段，且是三条待答项的挂接点

`[既有推演]`（只立接缝，不代 ②③④ 落表）

建议 `account.status` 为封闭枚举：`active` · `restricted` · `banned` · `pendingDeletion`。它是三条同分片待答项各自的落点：

| 待答项 | 挂接方式 |
|---|---|
| ② 合规落地 | 实名 / 防沉迷拦截读 `status` 与合规子状态，在 **`signin` 应答**分支（**不在 `/v1/profile/*`**，边界已定 2026-08-14） |
| ③ 多设备裁决 | `auth.session_revoked.detail.reasonKey` 的取值集合里，「运营吊销」一类即 `status` 变更所触发 |
| ④ 风控处置 | 「观察 / 限制 / 封禁」三档处置的落点即 `restricted` / `banned` |

**本草稿不填这三张表**，只主张它们共用同一个 `status` 字段而不是各立一套——否则同一个账号会有三处互不相干的「是否可玩」真值。

## 具体形态（可 derive 的落地面）

### 新增端点（进 `auth.md` §1，端点集由四扩到六）

| 端点 | 鉴权 | 请求 | 应答 |
|---|---|---|---|
| `POST /v1/auth/bind` | 必需 | `{ channel, credential }`（复用 signin 的 `oneOf`） | `200`，`{ channel, boundAtUtc }` |
| `POST /v1/auth/unbind` | 必需 | `{ channel }` | `204`，幂等 |

### 新增错误码（须登记进 `envelope.md` §6 台账五列）

| `code` | `class` | `OpError` | `detail` | `message` 必含 |
|---|---|---|---|---|
| `auth.identity_already_bound` | `Fatal` | `Auth` | `{ channel }` | 冲突的渠道 |
| `auth.identity_required` | `Fatal` | `Auth` | `{ channel }` | 「这是最后一个登录方式」 |

`auth.channel_rejected.detail` 由 `{ channel }` **扩为** `{ channel, channelCode }`（`channelCode` 可选，缺省即渠道未给码）。

### 身份模型（协议可见的部分）

| 字段 | 形态 | 语义 |
|---|---|---|
| `accountId` | 不可猜的 URL-safe 字符串，终身不变 | profile 主键（`auth.md` §8 已在 signin 应答中下发） |
| `channel` | 字符串枚举，与客户端 `LoginChannel` 成员名逐字相同 | `envelope.md` §2 通则 |
| `channelUserId` | 字符串 | **不出现在任何报文里**——它是服务端内部键 |
| `idKind` | `openid` \| `unionid` | 同上，服务端内部 |
| `status` | `active` \| `restricted` \| `banned` \| `pendingDeletion` | 见「七」 |

**`accountId` 的形态建议：随机、不可枚举、不含个人信息**（ULID / 26 位 base32 一类）。**不用自增整数**（对外泄漏注册规模与先后，且可被枚举探测）；**不用手机号 / openid**（个人信息进主键，PIPL 面直接放大，且换渠道即换键）。

### 绑定列表如何下行给客户端（已裁决 08-16：扩 §5 写入表）

扩 `profile-sync.md` §5 的后端写入字段表，加**第三行**：

| JSON path | 写入时机 | 频次 | 语义权威 |
|---|---|---|---|
| `/accountInfo/identities` | 建号 / bind / unbind 成功时 | 反复 | `auth.md` |

形态：`[{ channel, boundAtUtc }]`，**不含 `channelUserId`**（后端内部键不过边界，也避免把渠道标识写进玩家可导出的存档）。

## 后果

- **`contracts/auth.md`**：§1 端点集由「四个，封定」改为六个并补两个端点报文；§3 补「换 openid 的三条后端义务 + 两类错误映射」；§9 增两个 `code`；`channel_rejected.detail` 扩一个字段。**§8 的 signin / refresh / signout 报文一字不改。**
- **`contracts/envelope.md`** §6 台账增两行（触发机检断言 ②，须与 spec 同批）。
- **`contracts/profile-sync.md`** §5 后端写入表由两行变三行 —— **破坏性契约变更**，须两侧同批评审（§5 护栏原文要求）。
- **`contracts/purchase.md`** §3 的 `receipt` 形态**不由本条解锁**：那里的 `platform` 是**支付渠道**（应用商店 / 平台 IAP），与本条的**登录渠道**不同轴。该 Open question 里「待 `02` 的自建 vs 接第三方」的指向应改精确，或改指向一条独立的支付渠道选型问题。
- **`systems/account.md`**（尚未建立）在 `06` 落定后可直接以本草稿的三层切分与 identity 模型开篇。
- **`open-questions/02-account-compliance.md`** 的首条可移出；②③④ 三条保留，但各自获得一个明确的挂接点（`status`）。
- **新增一条本库承接项（由对侧 08-16 定案带来）**：客户端定「`AccountInfo` 首版承载昵称、无头像」，昵称的**改名频次限制与敏感词过滤是服务端义务**——客户端只提交，判定与拒绝在后端。它需要一个改名端点（建议 `POST /v1/auth/nickname`，进 `auth.md` 而非单开契约）与一个 `code`（建议 `auth.nickname_rejected`，`detail { reasonKey }`，复用 `reasonKey` 这个既有字段名）。**本草稿不定其阈值与词表口径**——频次阈值归 `06`（配置而非代码常量，与 `auth.md` §8 的旋钮同处），词表与审核口径归 `02` 的合规分级。
- **`contracts/_index.md`** 的契约文档表**不变**（绑定端点进 `auth.md`，不单开第六份）。另注：该文件「契约面成文完毕——四份，无第五份」一句已被 `purchase.md` 的存在推翻，属既有欠账，不在本草稿范围。

## 备选方案（已考虑并否决）

- **接托管身份服务（Firebase Auth / Auth0 / Cognito）作为 A 层** — 主键租给第三方（换服务商 = 全量存档迁移）、建号时刻不在本方（无法与 `accountSeed` 写入同一步）、三条既定会话语义无处表达、境外托管与国内数据存放要求冲突。
- **以渠道账号（微信 openid）直接作为 `accountId`** — 换渠道即换键；个人身份标识进 profile 主键；且手机号渠道无对应物，两类渠道的主键来源会分叉。
- **登录时按手机号 / 邮箱**隐式合并**已有的渠道账号** — 必然要丢弃其中一份存档，而玩家不预期一次登录删掉进度。合并只能是显式的绑定动作。
- **本方实现完整 OAuth2 / OIDC provider** — 无第三方消费者；成本全部沉没在 discovery / JWKS / 授权码流上，而既定的双 token 私有模型已满足全部需求。
- **为绑定 / 解绑单开一份契约文档** — 同一套 credential、同一套会话、同一域，分开会让 `oneOf` 判别式在两份文档各写一遍。
- **`channelUserId` 随 `AccountInfo` 下行** — 后端内部键跨边界即成为契约的一部分，且把渠道身份标识写进玩家可导出的存档，PIPL 面无谓放大。
- **渠道不可达也报 `auth.channel_rejected`** — 它是 `Fatal`，把一次渠道抖动变成终态（与 `purchase.md` §3 同一条理由）。
- **同一 `channel` 允许绑多条 identity** — 无玩家价值，却让「解绑哪一条」「找回时以哪条为准」全部分叉。

## 与既有决策的张力

**一处，已于 2026-08-16 裁决：绑定渠道列表怎么下行给客户端 → 取 ①（扩 §5 写入表）。**

- `auth.md` §1 定「**不设 `/v1/auth/me`**，账号身份元数据在 `AccountInfo`，随 `/v1/profile/pull` 整聚合下行」；
- 而 `profile-sync.md` §5 定「后端对透明段只读，**写入字段表封闭在两项**，扩表须显式引用护栏、不得静默加行」。

绑定列表是**后端权威**的（identity 表在服务端），两条合起来使它当前**无路可下行**。三条出路：

| 出路 | 代价 | 裁决 |
|---|---|---|
| **① 扩 §5 写入表加 `/accountInfo/identities`** | 用掉护栏那句「任何要求扩表的提案须显式引用本护栏并说明为何不能用别的通道」——本节即是该说明。第三行会被后来者引为先例，护栏被再消耗一次 | **✅ 采纳（08-16）** |
| ② 立一个 auth 域只读端点（`GET /v1/auth/identities`） | 直接推翻 `auth.md` §1 的「不设 `/v1/auth/me`」，且身份元数据从此有两个下行口 | 否决 |
| ③ 客户端在 bind / unbind 成功后自己写进 profile | **有明确缺陷**：新设备首次登录时客户端从未写过，绑定列表为空——而它是后端权威的真值，客户端会展示一份错的 | 否决 |

取 ① 的理由：③ 有确定的错误行为、② 造第二下行口，而 ① 恰是护栏所设想的「显式论证后扩表」的正常用法。

**代价如实记下，且随定案一并要求写进 `profile-sync.md` §5：** 护栏在此被消耗第二次（第一次是 `bundleGrantOrdinal`）。为不让它退化成「后端有时可以写」，落笔时须**同批加固**两条：

- 规则措辞仍是「后端只读，**除表内三项外**」，**不改成列举式的『后端可写的字段有』**；
- **三项各自的写入触发点必须在表内写死**（建号 / 验票 / bind·unbind），使「哪些时机后端会写」本身也是封闭的——它比字段清单更能挡住下一次扩表。

**并附一条判据供后来者引用：** 一个字段够格进这张表，须同时满足「真值只可能在服务端产生」与「客户端无任何其他通道能取到它」。`identities` 两条都满足（identity 表在服务端 · 已否决另立端点）；反例是 `statistics` 一类——它的真值在客户端，永远不够格。

## 前置依赖

- **`02` 的合规分级（本分片第二条）** —— 「实名是否为**建号**前置」会决定 `signin` 在什么时点返回 `compliance.*`：若实名是建号前置，则 §三 的「未命中即建号」要插一步。本草稿的其余部分不受影响。
- **`06-platform-stack.md`** —— 数据存放地与备案要求反向约束 A 层的托管形态（本草稿只主张「自建」这一语义，不主张部署形态）；token 签名密钥保管、会话存储、`challenge` 与 `bind` 的限流实现同归 `06`。
- **`03`（多设备裁决，本分片第三条）不构成前置** —— 本草稿只声明 `status` 是 `reasonKey` 的来源之一，不填取值表。
- **对侧库**：`counterpart` 草稿的客户端一半（`AccountInfo` 字段、`account-service` 方法面、绑定 UX）须与本草稿**同批采纳**，单侧采纳即两侧不一致。「张力」一节已裁决为 ①，客户端读绑定列表的路径因此确定为「随 `/v1/profile/pull` 下行的只读投影」，对侧草稿已随之定稿。

## 已定案的取向（2026-08-16）

四项全部按推荐定案。**无遗留待决项**——本草稿可直接喂给 `/analyze-new-ideas`。

1. **首版上线渠道 = `Phone` + `WeChat`。** Phone 是 ADR-0003 的首选且是实名 / 找回的天然载体；WeChat 覆盖面最大。**契约不因此改动**——`credential` 的四种形态照旧存在，只是首版不实现 `Email` / `QQ` 两条路径。
   - **连带纪律：不实现 ≠ 从契约删除。** 未上线渠道的 `credential` 分形保留在 spec 里，服务端对它们返回既有的 `auth.channel_rejected`；删掉再加回是一次破坏性契约变更，而追加实现不是。
   - `QQ` 与 `WeChat` 共用同一套 `authCode` 形态，追加时**只增实现不增契约面**；`Email` 留到第三档海外渠道展开时一并考虑。
2. **申请微信开放平台，首版即以 `unionid` 建 identity。** 理由是不可逆性：以 `openid` 建立的 identity 在日后新增第二个应用（小程序 / H5 / 第二款产品）时会分裂成两个身份，届时统一需要全量身份迁移。代价只是一次资质申请，**且必须在首个玩家建号之前完成**——这条落在发布前置清单上，归 `operations/`。
3. **第三方渠道可单独建号，不强制绑定手机号。** 强制绑手机会在最高转化的登录路径上加一道墙，而实名是账号级的独立能力（`02` 的合规分级），不必借绑手机来实现。
   - **若 `02` 最终定「实名为建号前置」，本项自动被它覆盖**——那时限制来自实名而非绑手机，本条不需要回头重议。
4. **绑定列表的下行路径 = 扩 `profile-sync.md` §5 后端写入表（第三行 `/accountInfo/identities`）。** 裁决与被否决的两条见「与既有决策的张力」；护栏的加固措辞与「够格进表」的判据一并在那里定稿，落笔时须同批写入。
