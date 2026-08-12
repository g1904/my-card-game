---
type: solution-draft
date: 2026-08-11
question: 协议契约四问：契约的事实来源与表达形式（OpenAPI + JSON Schema vs 共享 DTO 代码）、错误码体系与客户端 `OpError` 的映射、版本协商与强制更新、以及存档 schema 版本在契约中的承载形态。
source: open-questions/01-contracts.md → ① 协议契约（焦点之首 · 尚未建立）
targets:
  - backend-design-documents/contracts/envelope.md（新建；`contracts/_index.md` 已登记为计划文档，并已挂两项欠账）
  - backend-design-documents/contracts/_index.md（更新「现状」：表达形式定稿后，content-manifest 的字段名即可转正）
  - backend-design-documents/contracts/content-manifest.md（协调两处：flags 端点的域归属、路径前缀）
  - backend-design-documents/decisions/（ADR 候选：「契约表达形式 = OpenAPI 单点，不共享 DTO 代码」）
  - backend-design-documents/operations/（版本兼容矩阵的维护责任、错误码台账；栈落定后）
  - 跨库：game-design-documents/systems/services/sync-service.md · account-service.md（`Retry-After` 尊重、`flagsVersion` 读取点、错误码→`OpError` 映射表落点；需客户端侧另写一份 handoff）
status: distilled
decided-on: 2026-08-11
reviewed: 2026-08-11 —— 用户裁决三处取向，全部按推荐采纳：K1 信封走 HTTP 头 · K2 路径主版本 `/v1/` · K3 错误分层用四值 `class`；并追加一条要求：错误体除 `class` 外**必须**带 `message` 字段承载调试细节。张力项一并裁决：`/content/flags` 回改为 `/v1/content/flags`。提炼时另经 interview 裁决两项：`baseRevision` / `pushId` 留在 push body 的负载信封段；`Upgrade` 类错误只在登录 / 启动点硬阻塞。
distilled-to: backend-design-documents/handoffs/2026-08-11-contract-expression-envelope-and-error-codes.md
---

# 方案定案 — 协议契约：表达形式、信封、错误码分层与版本协商

> **状态：已由用户裁决定案（2026-08-11）。** 三处取向选择均已选定（信封走 HTTP 头 · `/v1/` 路径主版本 · 四值 `class`），其余按推荐采纳；用户另追加一条要求（错误体的 `message` 调试字段，见第 5 节）。张力项亦已裁决：`/content/flags` 回改为 `/v1/content/flags`。本文件已从提案改写为定案陈述，是 `/analyze-new-ideas` 的输入。
>
> 本定案覆盖 `open-questions/01-contracts.md` 的全部四条——它们不是四个独立问题，而是**同一层（信封与契约表达）的四个切面**：表达形式不定，字段名无处落笔；信封不定，错误码与版本协商无处搭载。因此一并答结。
>
> 本定案**不**产出 `auth.md` / `profile-sync.md` / `plot.md` 的报文本体——它们是这一层定稿后的下一批。

## 问题

`01-contracts.md` 的四条：

1. **契约的事实来源尚未成文**——端点、DTO、错误码、`contentVersion` / `manifest.json` 格式、存档 schema 版本与迁移路径全部未定。这是后端侧的第一优先项。
2. **契约的表达形式未定**——OpenAPI + JSON Schema 的文档级契约，还是（若后端也用 C#）共享 DTO 代码？此前被认为与 `06-platform-stack.md` 的技术栈选型耦合。**这条现在挡着一处具体落地**：Profile 上行负载的语义已在客户端侧定案（`pushId` / `baseRevision` / 信封三件套），但字段名与序列化形态等它。
3. **错误码体系与客户端 `OpError` 的映射**——后端错误码的分层（可重试 / 不可重试 / 需重登 / 需强更）与映射表未定。
4. **版本协商与强制更新**——`appVersion` 过旧时后端如何应答（软提示 / 硬闸门）、兼容矩阵由谁维护。

外加 `content-manifest.md` 定案时明确推给本层的**两项欠账**：信封须携带 `flagsVersion`；`minAppVersion` 与强更闸门的分工。**四条与两项欠账在本定案中全部答结。**

## 约束（来自既有设计）

**根约定（`.claude/rules/Context.md`，工程性约束，权威在 `.claude` 一侧）：**

- **客户端与后端是两条彼此独立的分支线，从不互相合并。** 两侧唯一的耦合点是协议契约，其权威在设计库。**这条直接裁决第 2 问**——见「定案 1」。

**本库既有：**

- `vision/pillars.md` #3「契约单点定义」：**一个**事实来源，两侧都从它派生，任何一侧不得私自扩展报文。
- `vision/pillars.md` #1「云端是权威，但不是玩法的执行者」：后端校验、排序、存储，**不重跑玩法**；防作弊只靠少数可复算掷骰 + 风控。
- `vision/pillars.md` #2「弱网优先：幂等重于优雅」；#4「不阻塞玩家」；#5「线上可干预」。
- `vision/scope.md` 硬约束：移动网络是常态（请求已达 / 响应丢失 / 后台挂起）。
- `contracts/_index.md`：**报文字段名与客户端字段名可以不同**，但语义须一一对应且显式给出映射——不靠「同名即同义」。
- `contracts/content-manifest.md`（本库第一份契约，语义已定案）：字段名已实际使用 **lowerCamelCase**（`manifestSchema` / `contentVersion` / `minAppVersion` / `files[].path`）；时间为 **RFC 3339 UTC**；**客户端必须忽略未知字段**已是契约条款；`manifestSchema` 只在破坏性变更时 +1，破坏时并存 N-1 / N 两版端点；`contentRoot` 随信封 / 配置下发，不写进被签名的 manifest。
- `open-questions/06-platform-stack.md`：技术栈 / 托管 / 数据库**全未定** ⇒ 本定案停在协议与语义层，**不指定语言 / 框架 / 库**。

**客户端侧已定案（硬前提，本定案不推翻）：**

- `OpError` 枚举**固定为九值**：`None, Network, Auth, Compliance, Validation, NotFound, Conflict, Cancelled, Migration`（`systems/architecture.md`）；失败经 `OpResult(bool Success, OpError Error, string Detail)` 返回，`Detail` 是字符串。
- **token 失效与被挤下线分开处理**（`account-service.md`）：刷新失败**视同断线**走 sync 缓冲通道、不打断轮回；被明确挤下线 → **硬阻塞**重登。
- **绝不回退存档点**；push 失败一律进待发队列 + 指数退避 + **不阻塞玩家**，`PushPolicy` 不改变这一条（`sync-service.md`）。
- **两处硬阻塞，仅此两处**：启动 pull 失败、被后端明确挤下线。
- **CAS 三分支**与 **`pushId` 幂等**（`ProfilePayload` / `PushAck` 的客户端形状已定案）；信封三件套 `contentVersion` · `appVersion` · `revision` 已写在客户端 record 上。
- **统计计数层：后端不复算、不校验，且不得用统计数据驱动任何发放**（`sync-service.md` 第 5 条，明确要求写进本库）。
- **迁移是客户端的事**：`OpError.Migration` 指的是**客户端本地**存档版本迁移失败（`MigrationManager`），不是后端拒绝。

## 定案

### 1. 表达形式：OpenAPI 3.1 + JSON Schema 单点，**明确否决共享 DTO 代码**

`[既有推演]`（强）

**这条不依赖 `06` 的技术栈选型——依据在根约定，不在选型。** 根约定写明「客户端与后端是两条彼此独立的分支线，**从不互相合并**」，理由是「后端塞进 `game-*` 会让后端代码被编译进游戏程序集」。共享 DTO 代码要成立，需要一个被两条分支线同时引用的程序集或包，这恰好在两条线之间造出一个**共享编译期依赖**——它要么住在某一条分支里（当场违反上述理由），要么需要第三个发布物（一个只为消解协议分歧而存在的包，其版本节奏要同时迁就 Godot 4.7 的 .NET 目标框架与后端运行时）。

因此：**即使后端最终也选 C#，契约的表达形式仍是文档级 OpenAPI + JSON Schema，两侧各自持有自己的 DTO。** 「后端用 C# 就能共享 DTO」这个此前被假定的耦合**不成立**，第 2 问因此**可以先于 `06` 定稿**——这是本定案最有价值的一条推演：它把 `01` 从 `06` 的下游里摘了出来。

`[通行做法]` 具体形态：

| 项 | 定案 |
|---|---|
| 规范 | **OpenAPI 3.1**（其 schema 方言即 JSON Schema 2020-12，避免 3.0 的子集裁剪与 `nullable` 之类的方言差） |
| 落点 | `contracts/openapi.yaml` + 拆分的 `contracts/schemas/*.json`（与 markdown 契约文档同处 `contracts/`） |
| **markdown 与 spec 的分工** | **markdown 承载语义、理由与承重纪律；spec 承载字段名、类型、必填性、枚举值。** 冲突时：字段形态以 spec 为准，语义以 markdown 为准 |
| 代码生成 | **不强制**。两侧可生成也可手写 DTO；契约不规定实现手段（`06` 未定，也不该规定） |
| 落地时机 | **不现在建空壳**（本库「先有设计再建文件」）。在**首个端点进入实现**时同时落 `openapi.yaml`；在此之前 markdown 契约文档的字段表即视为草案 |

**推论（答结第 1 问的一半）：`content-manifest.md` 的字段名就地转正。** 它已在用的 lowerCamelCase / RFC 3339 / 忽略未知字段三条，正是下面第 2 节定死的全局约定——那份文档的「字段名待表达形式」这条限定随本定案解除。

### 2. 序列化与命名约定（全局，一次定死）

`[既有推演]` 从 `content-manifest.md` 的既成事实推广 + `[通行做法]`

| 项 | 定案 | 依据 |
|---|---|---|
| 传输 | HTTPS + JSON（`application/json; charset=utf-8`） | `[通行做法]` |
| 字段命名 | **lowerCamelCase** | `[既有推演]` 第一份契约已在用 |
| 枚举值 | **字符串**，取值与客户端 C# 枚举名**逐字相同**（如 `"Conflict"` / `"EventResolved"` / `"Immediate"`） | `[既有推演]` 契约允许字段名不同但要求显式映射；枚举**值**同名可省掉一整张映射表，且这类映射表最容易写漏一项 |
| 未知字段 | **两侧都必须忽略未知字段** | `[既有推演]` 已是 manifest 侧契约条款，推广到全部报文 |
| 时间 | RFC 3339、**UTC、带 `Z`**；字段名以 `AtUtc` 结尾 | `[既有推演]` 与 `SyncEnvelope.LastAckAtUtc` 对齐 |
| 整数 | JSON number。**`revision`（`long`）不转字符串** | `[通行做法]` 账号级 `revision` 每次事件推进 +1，一生也到不了 2⁵³；转字符串会给两侧各加一道解析 |
| `null` | **不下发 `null`**——可选字段缺失即省略 | `[通行做法]` 与客户端「绝不把未经检查的 null 向下游传递」的纪律同向 |
| 二进制 | 不进 JSON（blob 是独立 GET；签名用 base64 字符串） | `[既有推演]` manifest 已如此 |

### 3. 端点风格与路径版本

`[通行做法]` + `[用户裁决 2026-08-11 · K2]`

**定案：API 面带主版本前缀 `/v1/`；CDN 静态对象不带。**

```
/v1/auth/…            登录 / 刷新 / 登出        → auth.md
/v1/profile/pull      整聚合下行                 → profile-sync.md
/v1/profile/push      diff 上行（CAS + 幂等）    → profile-sync.md
/v1/plot/…            剧本下发                   → plot.md
/v1/content/flags     按账号解析后的开关结果      → content-manifest.md（见下方协调项）

<contentRoot>/manifest           静态、无鉴权、CDN     → content-manifest.md
<contentRoot>/manifest.sig       同上
<contentRoot>/blobs/<sha256>     同上，immutable
```

- **`/v1/` 与 `schemaVersion` 的分工**：URL 主版本 = **端点集与信封**的破坏性变更（并存两版一段时间，同 `manifestSchema` 的处理）；报文内的 `schemaVersion` = **存档负载**自身的版本（见第 6 节）。二者不复用一个数字——它们的变更节奏完全不同。
- **协调项（`content-manifest.md` 须回改，用户已裁决 2026-08-11）** `[既有推演]`：**`/content/flags` 归 API 域，改为 `/v1/content/flags`，不在 `contentRoot` 下。** 那份文档已定它「按账号计算后只给结果」且 `no-cache`——一个**需要鉴权、按账号变化、不可缓存**的端点，本质是 API 而非 CDN 对象。放在 `contentRoot` 下会诱导它被当成静态对象缓存（灰度分桶会因此串号，这是最难查的一类线上事故）。manifest / blob 三个静态对象保持在 `contentRoot` 下不变。

### 4. 信封：请求走 HTTP 头，应答的搭车字段也走头

`[用户裁决 2026-08-11 · K1]` + `[既有推演]`

**定案：信封是 HTTP 头，不是 body 字段。**

请求头（每个 API 请求都带）：

| 头 | 语义 | 客户端对位 |
|---|---|---|
| `Authorization: Bearer <token>` | 会话 | `Session.Token` |
| `X-App-Version` | 客户端二进制版本，semver 三段 | `ProfilePayload.AppVersion` |
| `X-Content-Version` | 当前生效的 overlay 版本 | `ProfilePayload.ContentVersion` |
| `X-Request-Id` | 单次请求的调试关联 id（**每次重试都换**） | 新增（仅日志用） |

应答头（**任意应答**都带）：

| 头 | 语义 |
|---|---|
| `X-Flags-Version` | 当前 flags 批次版本 → **答结 `content-manifest.md` 的欠账①** |
| `X-Min-App-Version` | 硬闸门阈值（仅信息性，判定权在服务端，见第 5 节） |
| `X-Server-Time` | RFC 3339 UTC，供客户端做纯诊断用的时钟偏差观测（**不参与任何玩法判断**——设备时钟不可信已是既定纪律） |
| `Retry-After` | 仅在限流 / 可重试错误时 |

三条理由 `[既有推演]`：

1. **「随任意应答下发 `flagsVersion`」这条已定语义，只有放在头上才真正成立。** body 字段覆盖不到 `204`、错误应答、以及未来任何非 JSON 应答；而 flags 的秒关延迟正是靠「搭任意一次应答的车」压到分钟级的。
2. **`sync-service.md` 已写明信封的目的是让后端「不解 Profile 即可做版本维度的聚合与异常检测」。** 放在头上，网关 / 日志层直接可读，这个目的字面成立；放在 body 里则每一层都得先解一遍 JSON。
3. **GET 端点没有 body。** 若信封在 body，`/v1/content/flags`、`/v1/profile/pull` 就得各自例外——一个有例外的信封不是信封。

**对客户端已定 record 的影响：无。** `ProfilePayload` 里的 `ContentVersion` / `AppVersion` 是**客户端内部形态**，由 `HttpProfileBackend` 在发请求时搬到头上即可；契约本就允许「报文字段名与客户端字段名不同」。**不需要改客户端的 record 定义。**

### 5. 错误码分层与 `OpError` 映射

`[通行做法]` + `[既有推演]` + `[用户裁决 2026-08-11 · K3 与 `message` 追加要求]`

**错误体（所有非 2xx 的 JSON 应答统一此形状）：**

```json
{
  "error": {
    "code": "sync.conflict",
    "class": "Fatal",
    "message": "push rejected: baseRevision=136 is behind cloudRevision=137 (account acc_8f21, pushId 0c9e…)",
    "detail": { "cloudRevision": 137 },
    "requestId": "req_01J8ZK…"
  }
}
```

| 字段 | 必填 | 语义 |
|---|---|---|
| `code` | ✅ | **稳定字符串**，`<域>.<原因>`，**永不复用、永不改写含义**。它是客户端映射表的键 |
| `class` | ✅ | **处置分层**，四值：`Retryable` / `Fatal` / `Reauth` / `Upgrade`（正是 `01` 点名的「可重试 / 不可重试 / 需重登 / 需强更」） |
| `message` | ✅ | **面向开发者的调试说明**，英文自由文本。**每个错误应答都必须带，且必须写到能定位问题**——含触发该错误的关键值（如上例的两个 revision、账号与 `pushId` 前缀） |
| `detail` | 可选 | **结构化**补充（`cloudRevision` / `retryAfterSeconds` / 合规原因串），按 `code` 取固定形状。给**代码**读 |
| `requestId` | ✅ | 回显本次请求的 `X-Request-Id`，把客户端日志与服务端日志接起来 |

**`message` 与 `detail` 的分工（避免二者退化成同一样东西）** `[用户裁决 + 既有推演]`：

- **`message` 给人读，`detail` 给代码读。** 客户端**不得**解析 `message` 做任何分支——它的措辞可随时改写，任何依赖它的分支都会在某次后端改文案时静默失效。需要被代码消费的值一律进 `detail`（且在该 `code` 的台账条目里写死形状）。
- **`message` 也不直接展示给玩家。** 玩家可见文案由客户端 UI 层按 `OpError` 决定（客户端已定：`OpResult.Detail` 承载面向玩家的原因串仅用于 `Compliance` 一类）。`message` 是英文调试串，进日志、进上报，不进弹窗。
- **`message` 必须可安全落日志**：**不得**包含 token、完整账号凭据或任何密钥;账号 / `pushId` 一类标识按前缀截断。
- **客户端侧的承载**：`message` + `requestId` 拼进 `OpResult.Detail` 并随 `GD.PushError` / `GD.PushWarning` 输出（客户端日志纪律要求每条消息带定位标识符——`requestId` 正是跨越进程边界的那个标识符）。

**三条承重纪律** `[既有推演]`：

- **客户端不得靠 HTTP 状态码分支**，一律以 `code` 为键映射。状态码只承担传输层语义（谁重试、谁记日志），业务分支全在 `code` 上——否则「401 到底是 token 过期还是被挤下线」这类区分会永远做不干净，而客户端已定案这两者**处置完全不同**。
- **未知 `code` → 按 `class` 降级处置**；**未知 `class` → 当作 `Fatal` + `GD.PushError` 上报一次**。与 null 校验纪律「绝不静默通过」、与 content-service「验签失败 → 拒绝 + 上报一次」同构。
- **`class` 是契约的一部分，不是提示。** 服务端为每个 `code` 固定一个 `class`，不因请求而变——否则客户端的重试策略无法静态推理。

**首批错误码 → `OpError` 映射表**（覆盖两侧已定的全部语义分支）：

| `code` | `class` | 客户端 `OpError` | 客户端处置（全部是既定行为，本表只做对位） |
|---|---|---|---|
| `auth.token_expired` | `Reauth` | `Auth` | `RefreshTokenAsync()` 静默刷新；**刷新失败视同断线**走 sync 缓冲通道，**不硬阻塞** |
| `auth.token_invalid` | `Reauth` | `Auth` | 同上 |
| `auth.session_revoked` | `Reauth` | `Auth` | **硬阻塞**重登（被挤下线）；重登后先 pull 后 flush |
| `auth.channel_rejected` | `Fatal` | `Auth` | 登录屏呈现失败原因 |
| `compliance.realname_required` | `Fatal` | `Compliance` | `Detail` 携带面向玩家的原因串，文案由 UI 层决定 |
| `compliance.playtime_blocked` | `Fatal` | `Compliance` | 同上 |
| `sync.conflict` | `Fatal` | `Conflict` | 以云端为准丢弃本地缓冲 + 明确告知玩家（CAS 第二分支） |
| `sync.revision_ahead` | `Fatal` | `Conflict` | 同上 **+ `GD.PushError` 上报一次**；不试图自愈（CAS 第三分支 / 不可能态） |
| `sync.payload_schema_unsupported` | `Upgrade` | `Validation` | 见第 6 节：后端不认识的 `schemaVersion` |
| `sync.payload_invalid` | `Fatal` | `Validation` | 报文结构 / 必填字段不合法——**这是 bug 面，不是玩家面**，上报 |
| `rate.limited` | `Retryable` | `Network` | 进待发队列 + 退避；**须尊重 `Retry-After`**（跨库待办，见「后果」） |
| `server.unavailable`（5xx / 网关） | `Retryable` | `Network` | 同既定断线降级 |
| `client.version_unsupported` | `Upgrade` | `Auth` | 强更闸门，见第 6 节（**只在登录 / 启动点触发**） |
| `plot.unavailable` | `Retryable` | `Network` | 事务前置：呈现「内容加载失败 · 重试」，**Profile 零变更** |
| `resource.not_found` | `Fatal` | `NotFound` | — |

- **`Cancelled` 与 `Migration` 不出现在本表**，且**不应有任何后端 `code` 映射到它们** `[既有推演]`：前者是客户端 `CancellationToken` 的本地语义，后者是**客户端本地**存档迁移失败（`MigrationManager`）。后端拒绝一个它不认识的 `schemaVersion` 是**上行校验失败**（`Validation`），不是迁移——把它映到 `Migration` 会让客户端去跑一条本地迁移路径，而问题根本不在本地。
- **`auth.token_expired` 与 `auth.session_revoked` 必须是两个 `code`。** 这是本节最承重的一条：客户端已定案二者处置**完全不同**（一个静默刷新、绝不打断轮回；一个硬阻塞重登）。若后端只给一个「401 未授权」，客户端无从区分，只能二选一——选错哪一边都直接违反一条已定案语义。
- **限流是 `Retryable`，不是 `Conflict`。** 限流不改变 `cloudRevision`，客户端原样重试（`pushId` 保证幂等）即可；若映成 `Conflict` 会丢弃本地缓冲，等于把一次限流变成一次进度丢失。

### 6. 版本协商、强制更新与存档 schema 的承载

#### 6a. 强更闸门：判定权在服务端，**但只在登录 / 启动点生效**

`[既有推演]`（强）+ `[通行做法]`

- **判定在服务端，不是下发阈值让客户端自己比。** `content-manifest.md` 已因 semver 字典序坑（`1.10.0 < 1.9.0`）而明写比较规则；把硬闸门交给老客户端的比较逻辑，等于把闸门的正确性押在**可能正是需要被闸掉的那个版本**上。服务端判定后直接以 `client.version_unsupported`（`class: Upgrade`）拒绝。`X-Min-App-Version` 应答头仅供展示与诊断。
- **软提示与硬闸门分离**：`X-Recommended-App-Version`（软，客户端可提示「有新版本」）与 `client.version_unsupported`（硬，拒绝）。软提示永不阻塞。
- **闸门只在登录与启动 pull 这两个点生效** `[既有推演]`：这两处**本就是**已定案的仅有两处硬阻塞。轮回进行中的 push **不得**因版本过旧被硬拒——那会让玩家刚打完的战斗无处可去，直接违反「绝不回退存档点」与 pillar #4。
  - **实现语义**：闸门在**签发 token 时**判定一次，会话期内不因阈值提升而中途变严；阈值提升在玩家**下一次登录**时生效。这让「运营提升 `minAppVersion`」这个动作永远不会打断进行中的轮回。
- **`minAppVersion`（manifest 内）与强更闸门的分工 —— 答结 `content-manifest.md` 的欠账②：**

| | 承载 | 谁判定 | 效果 |
|---|---|---|---|
| `minAppVersion`（manifest 内） | **内容维度**：应用此 overlay 所需的最低客户端版本 | **客户端**自行比对 | 跳过本次 overlay 更新、照常用基线。**永不阻塞、永不强更**（已定案） |
| `X-Min-App-Version` / `client.version_unsupported` | **协议维度**：能否继续与后端通话 | **服务端** | 登录 / 启动点硬阻塞要求更新 |

  二者**互不兼职**：内容太新只是不更新内容；协议不兼容才拦人。

- **兼容矩阵由后端单点维护** `[既有推演]`：它是服务端判定的输入，必须与判定逻辑同处。落点 `operations/`（栈落定后），至少含：支持的 `appVersion` 下界、并存的 URL 主版本、并存的 `manifestSchema` / `schemaVersion` 集合、各自的下线计划。客户端不持有这张表的任何副本。

#### 6b. 存档 schema 版本：契约**不复述** Profile 内部结构

`[既有推演]`（这条同时答结第 1 问里「存档 schema 版本与迁移路径」的归属）

- **`schemaVersion` 是上行负载的版本，其结构权威在客户端**（Profile 是客户端定义的类模型），迁移路径也在客户端（`MigrationManager`）。契约**不把 Profile 的字段表抄进本库**——那会当场制造两份真值，且违反本库「不复述另一侧的设计」的约定。
- **后端对 Profile 是「半透明」的**，契约显式声明三段：

  | 段 | 后端可见性 | 依据 |
  |---|---|---|
  | 信封（`pushId` / `baseRevision` / `schemaVersion` / `reason`） | **完全透明**，后端解析并据此判定 | CAS 与幂等是后端职责 |
  | **后端可见字段子集**（复算所需：`AccountSeed` 相关掷骰序号与命中结果、`PlayerPowerFragment.*` 等规则字段） | **透明**，逐字段列进契约 | `03` 已定「后端可复算校验」 |
  | Profile / diff 的其余部分 | **不透明**：按不透明 JSON 存储并**原样回传** | pillar #1「不重跑玩法」 |

- **不透明段的纪律** `[通行做法]`：后端**不得**对不透明段做结构校验、不得改写、不得因其内部字段变化而拒绝上行。**推论：客户端加一个纯统计字段或纯展示字段，不需要后端配合、不需要提升 `schemaVersion`**——这正是 `sync-service.md` 已推出的「统计层新增字段成本近乎为零」在契约侧的兑现。
- **后端只在 `schemaVersion` 越出兼容集合时拒绝**（`sync.payload_schema_unsupported`，`class: Upgrade`）。兼容集合进上面那张兼容矩阵。
- **一并写进本库的客户端纪律**（`sync-service.md` 第 5 条点名要求）：**后端不复算、不校验统计计数层，且不得用统计数据驱动任何发放**（活动奖励 / 解锁）。一旦这么用，该字段就必须整体升为规则字段。→ 落 `contracts/envelope.md` 与 `operations/`。

## 具体形态（可 derive 的落地面）

### `contracts/envelope.md` 的成文骨架（即本定案的落点目录）

1. 表达形式与文档分工（OpenAPI 3.1 + JSON Schema；markdown ↔ spec 的冲突裁决规则）
2. 序列化与命名约定（第 2 节整表）
3. 端点风格与 `/v1/` 主版本 ↔ `schemaVersion` 的分工
4. 请求 / 应答信封头（第 4 节两表）
5. 错误体形状（`code` / `class` / `message` / `detail` / `requestId`）+ `class` 四值定义 + 三条承重纪律 + `message` ↔ `detail` 分工
6. **错误码台账**（`code` → `class` → `OpError` → 客户端处置 → `detail` 形状 → `message` 必含关键值，第 5 节整表；新增 `code` 一律在此登记）
7. 版本协商与强更闸门（含 `minAppVersion` 分工表）
8. Profile 负载的三段可见性 + 统计层的后端纪律

### 错误体 JSON schema

```json
{
  "error": {
    "code": "rate.limited",
    "class": "Retryable",
    "message": "push rate limit hit for account acc_8f21: 6 pushes in 10s, window resets in 12s",
    "detail": { "retryAfterSeconds": 12 },
    "requestId": "req_01J8ZK…"
  }
}
```

- `class` ∈ `{ "Retryable", "Fatal", "Reauth", "Upgrade" }`。`code` 与 `class` 的对应见台账，**服务端不得为同一 `code` 返回不同 `class`**。
- **必填四项：`code` · `class` · `message` · `requestId`**；`detail` 可选，形状按 `code` 在台账中固定。
- **错误码台账每条至少四列**：`code` | `class` | `detail` 形状 | `message` 里必须出现的关键值。最后一列使「调试信息够不够」成为契约里可核对的东西，而不是各端点各凭自觉。

### 客户端映射的落地形态（供跨库 handoff 参考，不在本库定稿）

映射表应是**数据**而非 switch 语句——一张 `code → (OpError, 处置)` 的表，未知 `code` 落到按 `class` 的四条默认路径。这与客户端「新增内容 = 新增数据，不编辑 switch」的可加性纪律一致。

## 后果

- **`contracts/envelope.md` 可以立即成文**，且它一落地，`content-manifest.md` 的「字段名与序列化形态待定」限定即解除、`contracts/_index.md` 的「现状」段需重写（表达形式不再是悬项）。
- **`01` 从 `06` 的下游里摘出。** 「后端若用 C# 则可共享 DTO」这个假定被根约定否掉后，契约表达形式不再等技术栈——`01` 与 `06` 可并行推进。这也让 `open-questions.md` 的「当前焦点」段（现写着「先定表达形式，与 `06` 一起决」）需要更新。
- **`content-manifest.md` 两处回改（已裁决）**：`/content/flags` 移入 `/v1/` API 域（端点表 + flags 小节的路径示意）；两项欠账（`flagsVersion` 进信封、`minAppVersion` 与强更分工）标记为已答结并回链 `envelope.md`。
- **`auth.md` / `profile-sync.md` / `plot.md` 的前置解除**，可按此序开工（`auth.md` 先行——它承载 token 生命周期与那两个必须分开的 `code`）。
- **`operations/` 多两个具体对象**：版本兼容矩阵的维护责任与下线计划；错误码台账的登记流程。
- **ADR 候选一条**：「契约表达形式 = OpenAPI 单点，不共享 DTO 代码」——它的依据是根约定的分支线独立性，值得固化，否则「后端也用 C# 了，不如共享 DTO」会反复被重新提出。
- **不影响存档 schema、不影响客户端已定 record**：信封搬到 HTTP 头是 `HttpProfileBackend` 的实现细节。

### 跨库待办（客户端侧，本库不代为决定）

需 `game-design-documents/` 另写一份 handoff，至少三点：

1. **`Retry-After` / `retryAfterSeconds` 的尊重**——客户端已定「指数退避」，需明确：收到限流时以服务端给的等待时间为下界。这是既有退避策略的一处小改动。
2. **`X-Flags-Version` 的读取点与触发拉取时机**（`content-manifest.md` 已把这条列为客户端侧待办，本定案把它落到了具体的应答头上）。
3. **错误码 → `OpError` 映射表在客户端的落点与形态**（建议为数据表，见上）；以及确认 `auth.token_expired` / `auth.session_revoked` 两分支与已定案的两条处置路径逐一对上。

## 备选方案（已考虑并否决）

- **共享 C# DTO 代码（后端也用 C# 时）** — 否决：需要一个跨两条独立分支线的共享编译期依赖，与根约定「客户端与后端从不互相合并」及其理由直接冲突；且会把契约的版本节奏绑死在两个运行时的交集上。
- **OpenAPI 3.0** — 未采纳：其 schema 是 JSON Schema 的裁剪方言（`nullable` 等），两侧工具链行为差异会以「字段可空性对不上」的形式在实现期才暴露。
- **gRPC / Protobuf** — 未采纳：强类型与代码生成的收益在这里被两点抵消——CDN 侧的 manifest / blob 本就是裸 HTTP 静态对象（不可能走 gRPC，会造出两套栈），且客户端是 Godot / .NET 跨四端导出（含 Web），HTTP + JSON 的可用性与可调试性代价最低。请求量级（每玩家每事件一次上行）远不到需要二进制协议的地步。
- **信封放 body 字段** — 未采纳（见第 4 节三条理由）；关键是它无法覆盖「随任意应答下发 `flagsVersion`」这条已定语义。
- **只用 HTTP 状态码表达业务错误** — 否决：`401` 无法区分「静默刷新」与「硬阻塞重登」，而这两条处置在客户端侧已定案且完全不同。
- **只给 `retryable: bool` 而不给四值 `class`** — 否决（K3 裁决）：布尔表达不了「需重登」与「需强更」这两条**同样不可重试、但处置完全不同**的路径。
- **省掉 `message`，只给 `code` + `detail`** — 否决（用户追加要求）：`code` 只说「是哪一类」，说不出「这一次为什么」。线上排查的第一现场是日志里的那一行；没有自由文本，每次定位都要回到服务端翻上下文，而移动端最难复现的恰是只出现在玩家设备上的那一次。
- **强更闸门交客户端比较 `X-Min-App-Version`** — 否决：把闸门的正确性押在待闸版本自己的比较逻辑上；semver 字典序坑已有前车之鉴。
- **强更在任意请求点生效** — 否决：会在轮回中途把 push 硬拒，违反「绝不回退存档点」与「仅两处硬阻塞」。
- **把 Profile 内部 schema 抄进契约** — 否决：制造第二份真值，违反「不复述另一侧的设计」，且与 pillar #1「后端不重跑玩法」相悖。
- **`revision` 以字符串传输** — 未采纳：`long` 远不及 2⁵³，两侧各加一道解析没有收益。

## 与既有决策的张力

**一处，已由用户裁决（2026-08-11）——属回改而非推翻：**

- **张力对象**：`contracts/content-manifest.md` 的端点表把 `/content/flags` 与 manifest / blob 并列在同一域下。
- **裁决**：**flags 回改为 `/v1/content/flags`，归 API 域，不在 `contentRoot` 下。** 理由是它需鉴权、按账号计算、`no-cache`——它是 API，不是静态对象。
- **代价**：那份文档的端点表回改一行；客户端多记一个 base URL（API 域与 `contentRoot` 本就是两个）。
- **不改的风险（已避免）**：把一个按账号变化的应答放进 CDN 域，随时可能被中间层按静态对象缓存 → **灰度分桶串号**，这类事故只在放量时显形且极难定位。
- **落笔要求**：提炼时同步改写 `content-manifest.md` 的端点表与其「flags 通道」小节的路径示意；manifest / manifest.sig / blob 三个静态对象保持在 `contentRoot` 下不变。

其余部分与既有决策**无冲突**：均是在两侧已定案的语义内补齐边界层的兑现方式。

## 前置依赖

- **`06-platform-stack.md`** — **不再是本层的前置**（见定案 1）。它仍是 `operations/` 落地（兼容矩阵存放、限流实现、可观测性口径）的前置。
- **`02-account-compliance.md`** — `compliance.*` 错误码的**具体清单**（实名 / 防沉迷 / 注销 / 导出各自的分支）要等合规方案定；本定案只立了两条示例与它们的 `class`。多设备并发裁决规则定案后，`auth.session_revoked` 的**触发条件**才完整（`code` 与处置已可先定）。
- **`03-sync-conflict.md`** — `sync.*` 的错误码与 `class` 已可定；但 `pushId` 记忆窗口、限流阈值这些**参数**属服务端实现，不进本层契约。
- **客户端侧 handoff** — 见「跨库待办」三点。

## 仍需用户决定

无——三处取向选择均已于 2026-08-11 裁决，全部按推荐采纳：

| # | 项 | 裁决 | 承担的代价 |
|---|---|---|---|
| **K1** | 信封位置 | **HTTP 头**（`X-App-Version` / `X-Content-Version` / `X-Request-Id`；应答侧 `X-Flags-Version` 等） | 调试时要看头；`HttpProfileBackend` 需把两个字段从 record 搬到头上（客户端 record 定义不改） |
| **K2** | 路径主版本 | **`/v1/` 前缀**（API 面；`contentRoot` 下的静态对象不带） | 需与 `contentRoot` 的无前缀形态并行解释 |
| **K3** | 错误分层的表达 | **四值 `class`**（`Retryable` / `Fatal` / `Reauth` / `Upgrade`） | 服务端必须为每个 `code` 固定一个 `class`，不能临时改 |

**用户追加要求（同日）：错误体必须带 `message` 调试字段。** 已落在第 5 节：`message` 为必填、面向开发者、须写到能定位问题；并与 `detail`（给代码读）划清分工、附带一条「不得落敏感值」的纪律，以及 `requestId` 回显以贯通两侧日志。

余下的开放项均为**前置依赖**（等 `02` 与客户端 handoff），不是取向选择。
