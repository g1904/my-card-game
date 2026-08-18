---
type: solution-draft
date: 2026-08-16
question: 账号自建 vs 接第三方定案后，客户端侧要承接什么？（AccountInfo 的绑定字段、account-service 的绑定方法面、渠道 SDK 边界、绑定 UX）
source: backend-design-documents/open-questions/02-account-compliance.md → 「账号系统自建还是接第三方」（问题主体归后端库）
targets: systems/player-profile/account-info.md · systems/services/account-service.md · ux/onboarding.md · ux/error-and-blocking-ux.md
counterpart: backend-design-documents/inbox/solution-draft-account-identity-model.md
status: distilled
reviewed: 2026-08-16 —— 3 项取向全部按推荐定案；提炼时经 interview 推翻两处（`Status` 不进 AccountInfo · 昵称由客户端写、故不需要改名后 pull）
distilled-to: handoffs/2026-08-16e-account-identity-client-adoption.md
---

> **3 项取向已于 2026-08-16 全部定案**，`counterpart` 的 4 项同日定案。定案内容见文末「已定案的取向（2026-08-16）」，正文各处已随之改写为定案措辞。

# 方案草稿 — 账号身份模型的客户端承接项

## 问题

「账号系统自建还是接第三方」这条待答项的**主体归后端库**（由后端实现 → 判据见 `backend-design-documents/open-questions.md` 的归属表），其方案在 `counterpart` 草稿中提出：**身份主体自建 · 渠道作为登录凭据 · account 与 identity 一对多**，并据此补齐 `contracts/auth.md` 的两处留白（绑定 / 解绑端点、渠道换 openid 的义务与错误映射）。

**本草稿只写客户端那一半**，即该方案一旦被采纳，客户端必须同步存在的东西。它对应两处客户端侧的既有待答：

- `systems/player-profile/account-info.md` 的「**字段 schema 未定**……多渠道绑定到同一账号的模型亦未定」；
- `systems/services/account-service.md` 的 API 面里**没有绑定 / 解绑 / 验证码请求**这三个方法。

后端契约中 `contracts/auth.md` §1 也把绑定端点显式挂在「待客户端 `account-info.md` 的多渠道绑定模型」上——**两侧互相等对方**，这正是本草稿要一次解开的。

**本草稿不复述后端的 identity 模型、端点报文与错误码定义**，需要时一律回链 `counterpart`。

## 约束（来自既有设计）

- **强制账号登录、无游客态**，渠道优先级 手机 / 邮箱 → 微信 / QQ → 海外 / 跨平台 —— `decisions/ADR-0003-online-cloud-authority.md`（Accepted）。
- **`account-service` 是平台 SDK 与后端鉴权的唯一门面**，其余服务不接触任何渠道 SDK；持有 `IAccountBackend`，经唯一选择点 `BackendSelector.CreateAccount()` 取实现 —— `systems/services/account-service.md`。
- **错误文案按 `code` 走 UI 层 `ErrorText`**，`Detail` 是诊断串不是玩家文案 —— 同上 + `systems/architecture.md` 总则 7。
- **UI 文案一律走 `res://text/` 翻译键，`ERR_*` 键由 `code` 机械变换而来、不得手写** —— `ux/error-and-blocking-ux.md`。
- **`AccountInfo` 是 `PlayerProfile` 的账号级字段**，持久化经 `profile-service.ProfileManager`、同步经 `sync-service` —— `systems/player-profile/account-info.md`。
- **竖屏 · 触控 · 无 hover-only 可供性** —— `.claude/rules/ui-input-rules.md`。

## 建议方案

### 一、`AccountInfo` 的绑定字段：只读投影，不是客户端的真值

`[既有推演]`

绑定关系的权威在后端（identity 表）。客户端持有的应当是一份**只读投影**，随 `/v1/profile/pull` 下行：

```csharp
public readonly record struct BoundIdentity(LoginChannel Channel, DateTime BoundAtUtc);
```

`AccountInfo` 上加 `IReadOnlyList<BoundIdentity> Identities`。三条纪律：

- **客户端从不写它**（绑定成功后不本地追加，靠**绑后一次 pull** 取回）。本地追加会在弱网下造出一份与云端不一致的展示，而它的错误形态是玩家看到一个其实没绑上的渠道。
- **渠道侧的用户标识（openid 一类）不进客户端**——它是后端内部键，见 `counterpart` 的「身份模型」表。
- **下行路径已定案（08-16）：随 `/v1/profile/pull` 整聚合下行**，由后端写入 profile 的 `/accountInfo/identities`（`counterpart` 已裁决扩 `profile-sync.md` §5 的后端写入表）。客户端侧因此**不需要任何新的读取端点**——它就是 `AccountInfo` 上的一个普通只读字段，走既有的 pull 与存档路径。

### 二、`AccountInfo` 的其余字段：本次一并收口

`[既有推演]` + `[取向选择]`

`account-info.md` 的待答项列了「账号 id、绑定渠道、昵称 / 头像、注册时间、封禁 / 实名状态？」。按归属逐条建议：

| 字段 | 建议 | 依据 |
|---|---|---|
| `AccountId` | **有**（`Session.AccountId` 的持久化投影，展示用） | 已在 `signin` 应答中下发 |
| `AccountSeed` | **已定**，形态见 `common-properties.md`（另有一条跨库欠账在办，不在本草稿范围） | `account-info.md` |
| `Identities` | **有**，见「一」 | 本草稿 |
| `CreatedAtUtc` | **有**（注册时间，玩家档案屏展示） | 通行做法 |
| `Status` | **有**，只读枚举投影 | 后端权威，见 `counterpart`「七」 |
| `Nickname` | **有**（`string`，玩家输入，**不是 `LocalizedText`**——它是用户数据不是 UI 文案） | 定案 08-16 |
| 头像 | **无**（首版不做，见「已定案的取向」1） | 定案 08-16 |
| 实名 / 防沉迷状态 | **不在本草稿** —— 归后端库 `02` 的合规分级 | `account-info.md` 待答项第二条已如此指向 |

**schema 影响：** `AccountInfo` 增字段 ⇒ 存档 schema 版本 bump，迁移 = 老档缺字段以默认值补齐（空列表 / 默认时间），无损。

### 三、`account-service` 的 API 面：新增四个 B 形态方法

`[既有推演]`

对位 `counterpart` 的端点（报文形态见那侧，此处只定客户端签名）：

| 方法 | 形态 | 签名 | 失败语义 |
|---|---|---|---|
| 请求验证码 | B | `Task<OpResult<ChallengeInfo>> RequestChallengeAsync(LoginChannel channel, string identifier, ChallengePurpose purpose, CancellationToken ct)` | 业务失败 → `OpResult`；`rate.limited` → `OpError.Network`? **见下** |
| 绑定渠道 | B | `Task<OpResult> BindChannelAsync(LoginChannel channel, CancellationToken ct)` | 业务失败 → `OpResult`（`auth.identity_already_bound` → `OpError.Auth`） |
| 解绑渠道 | B | `Task<OpResult> UnbindChannelAsync(LoginChannel channel, CancellationToken ct)` | 同上（`auth.identity_required` → `OpError.Auth`） |
| 改昵称 | B | `Task<OpResult> SetNicknameAsync(string nickname, CancellationToken ct)` | 业务失败 → `OpResult`（`auth.nickname_rejected` → `OpError.Auth`） |

```csharp
public readonly record struct ChallengeInfo(DateTime ExpiresAtUtc, int ResendAfterSeconds);
public enum ChallengePurpose { SignIn, Rebind }
```

- **`RequestChallengeAsync` 是 `SignInAsync` 的前置一步，不是它的内部实现。** 手机 / 邮箱登录是「先下发验证码、再提交验证码」的两步握手，UI 需要在两步之间停留（输入框 + 倒计时），把它藏进 `SignInAsync` 内部则倒计时与重发按钮无从驱动。
- **`SignInAsync` 现签名需带上凭据。** 现签名 `SignInAsync(LoginChannel channel, ...)` 对第三方渠道够用（authCode 由 SDK 现取），但自建渠道要交 `identifier + code`。建议扩为 `SignInAsync(LoginChannel channel, LoginCredential credential, CancellationToken ct)`，`LoginCredential` 是一个判别式 record（对位 `counterpart` 的 `oneOf`），第三方渠道传 `LoginCredential.None` 由服务内部走 SDK 取 authCode。
- **`rate.limited` 映射到 `OpError.Network`**（定案 08-16）：它与网络类失败共享同一条客户端处置（可重试 + 退避），而 `Auth` 档的语义是「凭据失效」，混进去会让处置分支走错。**文案不受影响**——文案按 `code` 取，`ERR_RATE_LIMITED` 仍可精确措辞。
- **昵称的合法性不由客户端判定。** 敏感词与改名频次是服务端义务（见 `counterpart` 的「后果」新增承接项）；客户端只做**长度与空白**这类无争议的输入约束，判定与拒绝一律由后端下发 `code`。客户端自带一份词表 = 第二权威，且改词表要发版。
- **绑定 / 解绑 / 改昵称成功后各强制一次 pull**（与购买段「购后强制一次 pull」同一形态），据此刷新「一」「二」的只读投影。

### 四、渠道 SDK 边界：一条纪律，零例外

`[既有推演]`

`account-service` 是渠道 SDK 的唯一触碰者这条已在文档里，本草稿只补一句它在绑定链路上的推论：**`bind` 与 `signin` 走同一条取 authCode 的路径**（同一个 SDK 调用、同一层错误归一），不为绑定另开一条。否则渠道 SDK 的初始化 / 授权 / 错误处理会有两份，而它们必然漂移。

### 五、两个新 `code` 的文案键

`[既有推演]`

`counterpart` 新增 `auth.identity_already_bound` 与 `auth.identity_required`，客户端须有对位 `ERR_*` 键（由 `code` 机械变换，不手写）：

- `ERR_AUTH_IDENTITY_ALREADY_BOUND` —— 「该渠道已绑定到另一个账号」
- `ERR_AUTH_IDENTITY_REQUIRED` —— 「这是你最后一个登录方式，不能解绑」
- `ERR_AUTH_NICKNAME_REJECTED` —— 昵称被拒（`detail.reasonKey` 区分「含敏感词」与「改名过于频繁」；**未知 `reasonKey` 须有兜底文案**，与 `auth.session_revoked` 那条同构）

**连带**：`auth.channel_rejected.detail` 增一个 `channelCode` 字段，**客户端不解析它、只随日志上报**（与「客户端不解析 `message`」同构）——文案仍按 `code` 取，不因 `channelCode` 分叉。

### 六、绑定管理的 UX：在「玩家档案」屏，不在登录屏

`[通行做法]` + `[既有推演]`

- **登录屏只做登录**：渠道按钮 + 手机 / 邮箱两步握手（输入 → 倒计时重发）。触控目标尺寸达标、倒计时状态始终可见（**不做 hover 提示**）。
- **绑定 / 解绑放主菜单「PlayerProfile（玩家档案）」屏**——`account-info.md` 已定它是 `AccountInfo` 的展示落点，绑定列表天然属于那里；且绑定是低频操作，放登录屏会让最高频路径变重。
- **列表形态**：每个渠道一行，已绑显示绑定时间 + 「解绑」，未绑显示「绑定」。竖屏 `VBoxContainer`，行高满足触控目标尺寸。
- **只列出首版已上线的渠道**（定案 08-16 ⇒ 首版即 `Phone` + `WeChat` 两行）。`Email` / `QQ` 虽在契约里有形态，但未实现——展示一个点了没反应的入口比不展示更差。**呈现的依据是「本版本实现了哪些渠道」，不是 `LoginChannel` 枚举的全部成员**：枚举遍历式的 UI 会在契约新增渠道时自动多出一行未实现的入口。
- **昵称在同屏可编辑**（首版无头像）：点按进入输入 → 提交 → 等待后端判定 → 失败按 `code` 出 `ErrorText`。**不做本地即时预览式改名**——后端可能拒绝，先改后回滚在观感上像 bug。
- **两处必须的二次确认**：解绑（不可逆地移除一条登录方式）、以及**绑定失败为 `identity_already_bound` 时**——后者要明确告诉玩家「那个渠道下有另一份进度，绑定不会合并两份存档」，否则玩家会以为是 bug。这一条直接对应 `counterpart` 的「绝不做隐式账号合并」。

## 后果

- `systems/player-profile/account-info.md`：字段 schema 待答项**可移除**（合规字段那一半仍留给后端 `02`）；写入字段表 + 「客户端从不写 `Identities`」纪律；schema 版本 bump 一次。
- `systems/services/account-service.md`：API 面表增四行、`SignInAsync` 签名扩一个参数、`LoginCredential` / `ChallengeInfo` / `ChallengePurpose` 三个类型、失败映射表补 `rate.limited → OpError.Network`；「待决问题」第一条（ComplianceManager 覆盖面）不受影响、保留。
- `ux/onboarding.md`：登录屏补两步握手的状态与倒计时；首版渠道按钮只有 `Phone` + `WeChat`。
- `ux/error-and-blocking-ux.md`：三个 `ERR_*` 键进键表（含 `ERR_AUTH_NICKNAME_REJECTED` 的未知 `reasonKey` 兜底）。
- **不触及** `sync-service` / `profile-service` 的既有语义——`Identities` 是随整聚合下行的普通字段。
- 与 `counterpart` **须同批采纳**：客户端加了 `BindChannelAsync` 而后端没有端点（或反之）即两侧不一致。

## 备选方案（已考虑并否决）

- **客户端本地维护绑定列表**（绑定成功即本地追加）— 新设备首次登录时列表为空，而它是后端权威的真值；弱网下还会展示未真正生效的绑定。
- **把 `RequestChallengeAsync` 藏进 `SignInAsync`** — 倒计时与重发按钮无从驱动，两步握手在 UI 上退化成一次不可见的等待。
- **绑定入口放登录屏** — 绑定是已登录态的操作，放登录屏在语义上就不成立（未登录时无账号可绑）。
- **`channelCode` 参与文案分支** — 渠道原始码是渠道版本的产物，会随渠道更新漂移；`ux` 层文案按 `code` 取这条纪律不为它开例外。
- **为绑定新开一个 service** — 它用同一套渠道 SDK、同一套会话，`account-service` 的门面定位已覆盖。

## 与既有决策的张力

**无**（客户端侧）。本草稿「一」原有的一处外部前提——绑定列表的下行路径——**已于 2026-08-16 在后端库裁决为「扩 `profile-sync.md` §5 后端写入表」**，客户端承接结果：`Identities` 是随 pull 下行的普通只读字段，无新增端点、无新增读取路径。

## 前置依赖

- **`counterpart` 草稿整体** —— 本草稿的四个方法、三个 `code`、`Identities` 字段全部以那一侧的方案被采纳为前提。**须与它同批采纳，单侧采纳即两侧不一致。**（两侧取向均已于 08-16 定案，无遗留待决项。）
- **后端库 `02` 的合规分级** —— `AccountInfo` 的实名 / 防沉迷字段是否存在、由谁呈现，归那一条；本草稿显式不碰。
- **在办的 `solution-draft-cross-library-alignment.md`** —— 那份也改 `AccountInfo`（`AccountSeed` 的形态与 `profile-sync` 七点欠账）。两份改的是**不同字段**，但同一份文档；建议**先采纳那份、再采纳本份**，避免同一文件两次重写互相覆盖。

## 已定案的取向（2026-08-16）

三项全部按推荐定案。**无遗留待决项**——本草稿可直接喂给 `/analyze-new-ideas`。

1. **`AccountInfo` 首版承载昵称（`Nickname: string`），不做头像。** 昵称是「玩家档案」屏的基本面且零外部依赖；头像要拉来上传、审核、CDN 存储与合规审查（UGC 内容面），而本作是单人游戏、**没有任何玩家间可见性**，收益接近零。
   - **连带（跨库）：昵称的改名频次限制与敏感词过滤是服务端义务**，已作为承接项写进 `counterpart` 的「后果」——建议的落点是 `auth.md` 内的改名端点 + `auth.nickname_rejected`。客户端只做长度 / 空白这类无争议的输入约束。
   - 头像**后置而非否决**：若日后出现玩家间可见性（排行榜、分享），它可作为纯增量新增，不推翻本草稿任何一条。
2. **`rate.limited` 映射到 `OpError.Network`。** 它与网络类失败共享同一条客户端处置（可重试 + 退避），而 `Auth` 档的语义是「凭据失效」，混进去会让处置分支走错。**文案不受影响**——文案按 `code` 取，`ERR_RATE_LIMITED` 仍可精确措辞。
3. **「玩家档案」屏只列出本版本已实现的渠道**（首版即 `Phone` + `WeChat` 两行）。展示一个点了没反应的入口比不展示更差。**依据是「本版本实现了哪些渠道」而非遍历 `LoginChannel` 枚举**——否则契约新增渠道时 UI 会自动多出未实现的入口。
