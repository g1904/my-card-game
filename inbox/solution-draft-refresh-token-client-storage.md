---
type: solution-draft
date: 2026-08-22
question: refresh token 的客户端持有形态 —— 具体落点文件、字段面、失效路径与启动期的消费点
source: open-questions/05-service-contracts.md → 「refresh token 的客户端持有形态未落笔」（同条登记在 systems/services/account-service.md「待决问题」）
targets: systems/services/account-service.md（新增「refresh token 的持有与失效」一节 + 划掉该待决项）· systems/architecture.md（`user://cache/` 版本判据的逐份落点回链）· ux/screen-flow.md · ux/onboarding.md（仅当取向 3 取 A）
status: distilled
reviewed: 2026-08-22 — 3 项取向全部裁决；合并 interview 另裁定 AccountService.InitializeAsync 上提到 LoginScreen 之前、登录屏降为条件步 · 按后端契约订正本库三处强更闸门记载为「只在登录点」（pull 侧不做版本闸门，由 signin 独占）· 客户端不自收口，收口手段归后端 · 明文落盘的理由改写为「依托平台沙箱 + 后端 rotation 兜底」，不得再挂靠「不承诺防作弊」· ux/onboarding.md 不改。**待复核 2 项**：不存 refreshExpiresAtUtc · 明文落盘
confirmed: 2026-08-22 —— 全部 [采纳推荐 — 待复核] 项经批量评审确认，无推翻
distilled-to: handoffs/2026-08-22-refresh-token-client-storage.md
---

# 方案草稿 — refresh token 的客户端持有形态

## 问题

后端契约已定（`backend-design-documents/contracts/auth.md` §2）：refresh token **不进 `Session`**，由客户端的 `HttpAccountBackend` 内部持有并落 `user://cache/`，与 `SyncEnvelope` 同构。客户端侧只剩三件事没写死：**落在哪个文件、带哪些字段、在哪些时刻失效**。

**一条硬约束已成立：不得与 `user://cache/device-id.json` 合进同一文件**——refresh token 是鉴权材料、**必须**在切账号 / 登出时失效，而设备标识**必须**切账号不变；同处一份文件会逼出一条「清一半留一半」的写入路径，正是最容易写错、错了以后症状（每次切账号被挤一次）指向不明的形态（`systems/services/account-service.md`「`deviceId` 的生成与持久化」）。

推演过程中还浮出**第四件事**：本作目前**没有任何一处消费跨启动保留的 refresh token**——`ux/screen-flow.md` 定「登录屏 = 应用首屏」，启动链第二步是 `LoginScreen` 之后的 `SignInAsync`。若不补一条静默续期路径，**「跨启动保留」这条属性没有任何消费者**，30 天滑动续期的 TTL 也无从兑现。见子项 5 与取向 3。

## 约束（来自既有设计）

- **落点形态可直接复用 `deviceId` 那一节**：`user://cache/` 下的 json · 原子写走共享静态工具 `AtomicJsonFile` · 跨启动保留 · 不进存档 / 不进 Profile / 不上云（`systems/services/account-service.md`、`systems/architecture.md`「共享核心类型」）。
- **`Session` record 一字不改**（`Session(AccountId, Token, ExpiresAtUtc)`）；refresh token 是传输层元数据，与 `baseRevision` / `pushId` / `X-App-Version` 同类。
- **schema 版本按判据决定，不是全称要求**：多字段的结构体（存档聚合、信封）必须带 `schemaVersion` + 迁移路径；**单字段的设备维度小文件不带版本**，因为「版本不认识就整份丢弃」对它有害（`systems/architecture.md`）。
- **「切账号即失效」不是 `user://cache/` 的通则，是内含账号绑定数据的那几份文件各自的性质**（`systems/services/sync-service.md`）：带 `accountId` 且内容按账号成立 ⇒ 切账号即丢弃 / 重建。
- **refresh 失败的两条分流已定**（`account-service.md`）：网络失败视同断线走 sync-service 同一缓冲通道；收到 `auth.session_revoked` → 硬阻塞重登 + 暂停退避。
- **后端已定 rotation + 60 秒宽限窗口**：每次刷新返回新 refresh token、旧的立即失效；旧 token 在轮换后 60 秒内重放回**与上次相同**的那一对（`auth.md` §4）。
- **设备时钟不可信**：`X-Server-Time` 纯诊断，**不用于校正本地时钟**（`sync-service.md`）。
- **硬阻塞只有既定两处**（启动 pull 失败、被后端明确挤下线），不得新增。
- **UI 文案一律走翻译键**；登录屏分区键前缀 `LOGIN_`（`ux/error-and-blocking-ux.md`）。

## 建议方案

### 1. 落点 = `user://cache/refresh-token.json`，与 `sync-envelope.json` 同构

`[既有推演]` `auth.md` §2 已明写它与 `SyncEnvelope` **同构**：「都是传输层元数据，不进 Profile、不进存档 schema、不参与迁移，且同样适用『切账号即失效』的必需缺失处置」。契约已经给出了形态，本条只是把它落到具体文件名与字段面。

**独立一份文件，不与任何既有文件合并。四条否决各有理由：**

| 不与谁合并 | 理由 |
|---|---|
| `device-id.json` | **失效口径恰好相反**（硬约束，既定） |
| `sync-envelope.json` | 失效口径**相同**（都是切账号即丢弃），但：① **归属服务不同**——本文件归 `account-service.AuthManager`，信封归 `sync-service.LocalCacheManager`；② **启动顺序对不上**——静默续期发生在登录期，那一刻 sync-service 尚未初始化（与 `deviceId` 不落 `LocalCacheManager` 的第②条理由逐字同源）；③ 合并后**一次同步信封的丢弃会连坐清掉登录态**，玩家侧表现是一次凭空的强制重登 |
| `flags.json` | 归 content-service；且 flags 是可降级的缓存，登录凭据不是 |
| `device-settings.json` | 设备维度、切账号不变，与本文件相反；且它是玩家可见设置，本文件不是 |

### 2. 字段面 = `{ schemaVersion, accountId, refreshToken }`，**不存过期时刻**

`[取向选择]`（见「仍需用户决定」1）。**推荐形态：**

| 字段 | 类型 | 作用 |
|---|---|---|
| `schemaVersion` | `int` | 见子项 3 |
| `accountId` | `string` | 归属账号。用于「切账号即失效」判定与刷新后的一致性断言 |
| `refreshToken` | `string` | 凭据本身 |

- **`accountId` 必须在**：它正是「切账号即失效」这条性质的载体，与 `sync-envelope.json` / `flags.json` 同纪律。**这与 `device-id.json` 刻意没有这一格恰好相反**——那份文件里「这一格不存在，该错误在结构上不可能被写出来」，本份文件则是「这一格存在，切账号清除才有判据」。两条纪律各自成立，不是互相矛盾。
- **不存 `refreshExpiresAtUtc`（推荐）。** 它看似有用（提前知道要重登），但客户端**没有任何一处可以合法地据它分支**：设备时钟不可信是既定纪律，一台时钟快了一个月的设备会拒绝去尝试一个其实完全有效的刷新 ⇒ **凭空一次强制重登**。而「refresh token 是否仍有效」的唯一权威是后端的 `auth.session_revoked` 应答，试一次的代价是一次请求。**存一个不允许被读的字段，只会等着被人读。**
- **不存 access token。** 它 15 分钟即过期、`Session` 已在内存持有，落盘只是把一份短寿凭据写进磁盘，扩大泄漏面而零收益。
- **不存渠道 / 手机号 / 昵称等便利字段**（「上次用微信登录」这类）——那是 UI 便利，不是鉴权材料，若确有需求应落 `device-settings.json`（设备维度、切账号不变），不与凭据同处。

### 3. **带** `schemaVersion`，与 `deviceId` 那一节的处置刻意不同

`[既有推演]` `systems/architecture.md` 的判据是「**这份文件的结构会不会增长到需要逐版迁移**」，而不是「字段数」。本文件是**多字段信封**，与 `sync-envelope.json`（4 字段 + 版本）同形；更关键的是配套口径「版本不认识就整份丢弃」在这里**是安全的**：

> 丢弃一份 refresh token = **玩家多登录一次**。丢弃一份 `device-id.json` = **一次假换设备 + 一次假挤下线**。

两者不在同一量级，这正是 `deviceId` 那一节不带版本、而本文件带版本的完整理由。**须在文档里明写这条对照**，否则读者会按「都是 `user://cache/` 小文件」照抄错误的一侧。

### 4. 失效路径（穷举六条）

`[既有推演]` 这是本方案的主体。**处置一律是「删除文件 + 清内存」，或「覆写」，绝无第三种。**

| # | 时刻 | 处置 | 依据 |
|---|---|---|---|
| 1 | **登出成功**（`SignOutAsync` 返回成功） | 删除文件 | 主动登出的玩家预期就是「下次要重新登录」 |
| 2 | **收到 `auth.session_revoked`**（refresh 应答或业务请求应答，两个到达路径） | 删除文件 + 走既定硬阻塞重登 | 该 token 在服务端已失效，留着只会在下次启动多打一次必然失败的请求 |
| 3 | **`signin` 成功且 `accountId` ≠ 文件中的** | **覆写**（写入新账号的新 token） | 切账号即失效的兑现点 |
| 4 | **`signin` 成功且 `accountId` 相同**（同设备重登） | 覆写 | 后端已定「原地替换会话，旧 refresh token 立即失效」 |
| 5 | **每次 refresh 成功**（rotation） | 覆写为应答中的新 token | 后端 rotation：旧的立即失效 |
| 6 | **读取时解析失败 / 缺字段 / `schemaVersion` 不认识 / `accountId` 为空** | 删除文件 + 走登录屏 | 见下方处置表 |

**读取与写入的失败处置（对位 `deviceId` 那一节的三行表）：**

| 情形 | 判定 | 处置 |
|---|---|---|
| 文件不存在 | **可选缺失**（首次运行 / 已登出的正常态） | 走登录屏。**不打任何日志**——它是最常见的正常态 |
| 解析失败 / 字段缺失 / 版本不认识 / `accountId` 空串 | 可选缺失（异常） | `GD.PushWarning("[Auth-RefreshToken] cached refresh token invalid, discarding; path=user://cache/refresh-token.json")` + 删除 + 走登录屏 |
| 落盘失败（写入时） | 可选缺失（异常） | `GD.PushWarning("[Auth-RefreshToken] persist failed; session valid for this launch only")` + **本次进程内存持有该 token，不阻塞登录**。后果照录：**下次启动需重新登录**（一次性、可自愈，玩家侧只是多登一次） |

- **三处一律 `PushWarning` 而非 `PushError` + 抛**，与 `deviceId` 同一条判据：缺它不阻断任何流程，最坏后果是玩家多登录一次；抛会把一次可降级的缓存问题升级成**登不上游戏**。
- **⚠ 与 `deviceId` 的「必须先落盘成功、内存里才认」刻意不同（承重）。** 那条纪律成立是因为 deviceId 的「盘上没有」会造成**永不自愈**的症状（每次启动自己把自己挤下线一次）。refresh token 落盘失败的症状是**一次性的**（下次启动多登一次），而按那条纪律处理反而更糟——它会让一次写盘失败**当场作废一个刚拿到的有效会话**。**判据是「失败症状是否自愈」，不是「是不是凭据」**，这条须与规则同处，否则读者会误以为两处不一致是漏改。
- **rotation 的落盘时机：先拿到应答、再落盘、再更新内存。** 若落盘失败，60 秒宽限窗口保证**旧 token 在窗口内仍可用**，但这条**不作为设计依赖**——窗口是弱网重放的保险，不是落盘失败的兜底。
- **待发队列不受本文件影响。** 队列条目的淘汰路径只有既定三条（被后端接受 / 按云端权威丢弃 / 切账号清空）；本文件的删除**不淘汰任何队列条目**，切账号时的队列清空由信封 `accountId` 不匹配那条既定路径承担。

### 5. 消费点：启动期静默续期（本方案发现的缺口）

`[既有推演]` **跨启动保留一个 refresh token，当且仅当有人在启动时用它。** 目前没有。

**建议的路径（形态最小，不新增屏、不新增阻塞点）：**

```
启动链第二步（当前 = LoginScreen → SignInAsync）改为：
  读 user://cache/refresh-token.json
    缺失 / 无效        → 呈现 LoginScreen（既有路径，零改动）
    有效               → 直接 RefreshTokenAsync()
        成功                        → 得到 Session，跳过 LoginScreen，进启动链第三步（pull）
        auth.session_revoked        → 删除文件 → 呈现 LoginScreen（不是硬阻塞，见下）
        网络失败                    → 呈现 LoginScreen 并附「重试」（不是硬阻塞，见下）
```

- **启动期的 refresh 失败不走既定的两条分流。** 那两条（网络失败视同断线走缓冲通道 / `session_revoked` 硬阻塞重登）都以**会话期内**为前提：有进行中的轮回、有待发队列、有存档点不能回退。**启动期这三样一样都没有**——此刻还没登录、没有 pull、没有队列。故两种失败**一律落回登录屏**，那是「未登录」的既定正常态（`TryGetSession` 已定为可选缺失）。
- **因此不新增任何硬阻塞点**：既定两处（启动 pull 失败、被明确挤下线）原样成立。登录屏不是阻塞屏。
- **`refresh` 端点永不返回 `client.version_unsupported`**（后端 `auth.md` §5），故静默续期**绕不开也不承担**强更闸门——闸门仍只在 `signin` 判定一次。**这是一处必须明写的连带**：一个靠静默续期长期在线的旧版本客户端，**不会被强更闸门拦到**，直到它下一次真的走 `signin`。该缺口的收口（若需要）在后端侧，本库不代为决定。

### 6. 归属 = `AuthManager` 私有，不出任何服务的 API 面

`[既有推演]` 与 `deviceId` 同款手法：**不提供 `TryGetRefreshToken()` 这类公开取值方法**。理由更强——它是**鉴权材料**，一个公开取值口就把「把 token 记进日志 / 塞进诊断面板 / 上报到统计」变成一行代码的距离。

- 唯一消费点是 `RefreshTokenAsync` 与 `SignInAsync` 的应答处理，两者都在 `AuthManager` 内。
- **文件 I/O 落在 `AuthManager`，不沉进 `HttpAccountBackend`。** `auth.md` §2 写的是「由客户端的 `HttpAccountBackend` 内部持有」，但本库既有纪律更具体：`deviceId` 已定「填充点 = `AuthManager` 取到值后交给内部的 `IAccountBackend`，放这里而不是沉进 HTTP 实现层，是因为离线实现也要能拿到它记日志，且文件 I/O 不该在传输层」。**同一条理由逐字适用**：`OfflineAccountBackend` 也要能走通静默续期路径。
- **不打印 token 值本身**：任何日志只写 path 与判定结果，绝不写凭据（含前缀 / 后缀截断形式——截断值仍是凭据的一部分，且对排障无用）。

## 具体形态（可 derive 的落地面）

**文件：** `user://cache/refresh-token.json`

```jsonc
{
  "schemaVersion": 1,
  "accountId": "01J...",          // 归属账号；≠ 当前登录账号 ⇒ 覆写
  "refreshToken": "…"             // 凭据本体；每次 rotation 覆写
}
```

**`user://cache/` 全表（本方案新增一行，供文档对账）：**

| 文件 | 维度 | 带 `accountId` | 带 `schemaVersion` | 切账号 | 归属 |
|---|---|---|---|---|---|
| `sync-envelope.json` | 账号 | ✅ | ✅ | 丢弃 | sync-service |
| `pending/` | 账号 | —（随信封判定） | — | 清空 | sync-service |
| `flags.json` | 账号 | ✅ | （`flagsSchema`） | 丢弃 / 重建 | content-service |
| **`refresh-token.json`（新）** | **账号** | **✅** | **✅** | **覆写 / 删除** | **account-service** |
| `device-id.json` | 设备 | ❌（承重） | ❌（承重） | **不变** | account-service |
| `device-settings.json` | 设备 | ❌ | （见 `game-setting.md`） | 不变 | 设置层 |
| `dismissed-recommended-version.json` | 设备 | ❌ | ❌ | 不变 | UI 层 |

**API 面：零改动。** 不新增方法、不改 `Session`、不改任何签名。`RefreshTokenAsync()` / `SignInAsync()` / `SignOutAsync()` 的现有形态原样承载全部六条失效路径。

**存档 schema：零影响、零迁移。后端：零改动、零新增义务**（形态由 `auth.md` §2 已定，本方案只是落地客户端侧）。

## 后果

- `systems/services/account-service.md` 新增一节（与「`deviceId` 的生成与持久化」并列），并划掉该待决项。
- **若取向 3 取 A（做静默续期）**：`ux/screen-flow.md`「登录屏 = 应用首屏」需改写为「**未持有有效凭据时**的首屏」，`ux/onboarding.md` 的首次进入路径不受影响（首玩必然无凭据）。**这是本方案唯一触及 UX 文档的地方。**
- 启动链第二步的形态由「LoginScreen → SignInAsync」变为「凭据探测 → 二选一」，**阻塞点数量不变**。
- `.claude/knowledge/systems/account-service.md`（引用层，待建）日后建立时须覆盖本节。

## 备选方案（已考虑并否决）

- **与 `device-id.json` 合并** — 失效口径恰好相反，硬约束已成立（既定）。
- **与 `sync-envelope.json` 合并** — 归属服务不同、启动顺序对不上、且一次信封丢弃会连坐清掉登录态（子项 1）。
- **存进 `GameSetting` / 随 Profile 上云** — Profile 是账号级、云端权威、跨设备一致的主档；把设备本地的会话凭据上云，A 设备会读到 B 设备的 token，与「活跃会话上限 1」的裁决模型直接冲突。
- **不落盘、每次启动都重新登录** — 直接废掉后端已定的 30 天滑动续期与 rotation 模型，且是移动游戏体验的重伤（每次启动输一次验证码）。
- **存 `refreshExpiresAtUtc` 并据它判断是否尝试刷新** — 设备时钟不可信（既定纪律），一台快钟设备会拒绝尝试一个有效凭据 ⇒ 凭空强制重登。
- **落盘 access token 以跳过一次 refresh** — 15 分钟即过期，收益近乎为零，泄漏面翻倍。
- **沿用 `deviceId` 的「必须先落盘成功、内存里才认」** — 会让一次写盘失败当场作废一个刚拿到的有效会话；两者失败症状不同轴（自愈 vs 永不自愈），见子项 4。
- **平台密钥库存储（Android Keystore / iOS Keychain）** — 见「仍需用户决定」2。

## 与既有决策的张力

1. **与 `ux/screen-flow.md`「登录屏(应用首屏)」相抵**（仅当取向 3 取 A）。该句目前是无条件的；静默续期成立后它须改写为「未持有有效凭据时的首屏」。**不改写则子项 5 无从落地，而不落地则「跨启动保留」零消费者**——两者必须一起裁决。
2. **与 `auth.md` §2「由客户端的 `HttpAccountBackend` 内部持有」措辞相抵。** 本方案把持有点定在 `AuthManager`（backend 之上一层），依据是本库 `deviceId` 已立的同一条理由（离线实现也要能拿到、文件 I/O 不该在传输层）。**这是客户端内部的分层问题，不改变任何报文语义**，故不构成契约变更；但两侧措辞不一致，建议在采纳时于本库明写理由并回链，**不要求后端改写**。
3. **静默续期绕过强更闸门**（子项 5 末条）。后端已定「闸门只在 `signin` 判定一次、`refresh` 永不判定」，这是刻意的（避免会话期内中途变严）。静默续期把「一次会话」拉长到跨启动，使一个旧客户端可能长期不经过闸门。**本方案不擅自收口**（收口手段全在后端侧：滑动续期上限、强制 re-signin 周期等），只如实登记为一条新暴露的口子，供用户决定是否作为后端待答项承接。

## 前置依赖

- **无阻塞项。** 后端契约 `auth.md` §2 / §4 / §4a 已定全部对侧语义（不进 `Session`、落 `user://cache/`、rotation + 60 秒宽限、同设备重登原地替换），本方案不依赖任何待答项。
- 取向 3 若取 A，其 UX 改写与 `ux/screen-flow.md` 的其余内容无耦合，可与本方案同批落笔。

## 仍需用户决定 → **已全部裁决（2026-08-22 · 批量评审）**

> 逐条裁决（`/batch-provide-solution-draft` 合并 interview）：
> 1. 是否存 `refreshExpiresAtUtc` → **A · 不存** `[已确认 2026-08-22 · 批量评审]`（含「`signin` 应答里该字段读取即丢弃」）
> 2. 凭据的落盘保护强度 → **A · 明文 `user://cache/refresh-token.json`，与 `deviceId` 同等对待**（平台密钥库**后置评估而非否决**；残余风险 root / 越狱 / 备份提取 / 共享设备已知会）`[已确认 2026-08-22 · 批量评审]`
> 3. 是否落地启动期静默续期 → **已裁决：A · 落地** ⇒ 须同批改写 `ux/screen-flow.md`「登录屏（应用首屏）」为「未持有有效凭据时的首屏」；「静默续期绕过强更闸门」这条新暴露的口子按本稿原样登记，收口手段在后端侧，本库不擅自处置
>
> **全部待复核项已于 2026-08-22 经批量评审逐项确认，本草稿再无待复核项。**


1. **是否存 `refreshExpiresAtUtc`**（`[取向选择]`）
   - **A（推荐）—— 不存**：客户端无任何一处可合法据它分支（设备时钟不可信），存一个不许读的字段只会等着被人读。
   - **B —— 存但标注「仅诊断」**：可用于设置屏展示「登录有效期至 …」。代价是它会被当成判据用，且第一个这么用的人不会知道自己踩了时钟不可信这条线。
   - **C —— 存并据它跳过必然失败的刷新**：省一次请求，代价是快钟设备凭空强制重登。**明确不推荐。**
2. **凭据的落盘保护强度**（`[取向选择]`）
   - **A（推荐）—— 明文 `user://cache/`，与 `deviceId` 同等对待**：依托各平台的应用沙箱；泄漏面已由后端的 rotation + 重放即吊销全部会话兜住；**不改变任何契约，日后可换实现而无需两侧配合**。
   - **B —— 平台密钥库（Android Keystore / iOS Keychain）**：更强，但需平台插件、四端导出（含 Web）行为不一致，且本作**客户端侧已明确不承诺防作弊**（`content-manifest.md` 信任根一节的同一条威胁模型）。建议**后置而非否决**。
3. **是否落地启动期静默续期（子项 5）**（承重，`[取向选择]`）
   - **A（推荐）—— 落地**：否则「跨启动保留」这条属性**零消费者**，30 天滑动续期与 rotation 在客户端侧全部空转，且玩家每次启动都要重新登录一次。需同批改写 `ux/screen-flow.md` 一句（张力 1）。
   - **B —— 不落地，本文件只服务于单次进程内的刷新**：那么「跨启动保留」应当**改为不保留**（进程退出即删），文件本身随之退化为可有可无——**请注意 B 实质上是在推翻后端 `auth.md` §2 的「落 `user://cache/`」**，须两侧同批评估。
