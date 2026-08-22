# envelope —— 契约的边界层（表达形式 · 信封 · 错误码 · 版本协商）

> 覆盖**全部端点共有**的那一层：契约用什么表达、报文怎么序列化、信封带什么、错误长什么样、版本怎么协商。
> 各端点的报文本体在 `auth.md` / `profile-sync.md` / `content-manifest.md`；它们**不另立一套**错误码或版本机制。
> 客户端侧门面见 `game-design-documents/systems/services/`（那里描述**客户端怎么用**；此处描述**报文长什么样**）。
> Source: `handoffs/2026-08-11-contract-expression-envelope-and-error-codes.md`、`handoffs/2026-08-13-auth-endpoint-contract.md`（§4a 的 auth 例外域 · 台账两条新 `code` 与 `session_revoked.detail`）、`handoffs/2026-08-14-profile-sync-contract.md`（§2 的超 2⁵³ 整数判据 · §8 可见字段子集回链）、`handoffs/2026-08-14-openapi-spec-timing-and-consistency.md`（§1 的落笔规则 · 形态收 spec 单点 · `info.version`）、`handoffs/2026-08-16c-compliance-contract-and-session-arbitration.md`（§3 端点清单 · §4a 无鉴权例外判据 · §6 台账四条 `compliance.*`）。

## 1. 表达形式与文档分工

**契约的表达形式 = OpenAPI 3.1 + JSON Schema 单点。明确否决共享 DTO 代码——即使后端最终也选 C#。**

依据在根约定而非技术栈选型：客户端与后端是两条彼此独立的分支线，从不互相合并（理由是后端代码不得被编译进游戏程序集）。共享 DTO 要成立就需要一个被两条分支线同时引用的编译期依赖——它要么住在某一条分支里（当场违反该理由），要么需要第三个发布物，其版本节奏要同时迁就 Godot 4.7 的 .NET 目标框架与后端运行时。→ ADR 候选③。

| 项 | 定案 |
|---|---|
| 规范 | **OpenAPI 3.1**（schema 方言即 JSON Schema 2020-12；不用 3.0——其 schema 是 JSON Schema 的裁剪方言，`nullable` 一类差异会以「字段可空性对不上」的形式在实现期才暴露） |
| 落点 | `contracts/openapi.yaml` + 拆分的 `contracts/schemas/*.json`，与 markdown 契约文档同处 `contracts/` |
| **markdown ↔ spec 分工** | **markdown 承载语义、理由与承重纪律；spec 单点承载字段名、类型、必填性、枚举值。**markdown 中的形态性文字（示例报文等）**均为说明性，不具规范性**。冲突裁决规则保留为兜底：**字段形态以 spec 为准，语义以 markdown 为准** |
| 代码生成 | **不强制**。两侧可生成也可手写 DTO——契约不规定实现手段 |
| 落地时机 | **不预先建空壳**（本库「先有设计再建文件」）。**任一侧**（客户端或后端）的首个端点进入实现时，由**动手的那一侧**落 `openapi.yaml`（即使动手方是客户端，spec 仍落本库），范围 = **全部共有层 + 该一个端点**；其余端点路径在各自进入实现时逐个追加。**在某端点的 spec 落笔前，其 markdown 字段表视为草案** |
| **形态的迁移** | 某端点的形态一旦进入 spec，其 markdown 字段表**同批删除规范性形态列**（类型 / 必填 / 枚举取值），降级为「字段名 + 语义 / 用途 / 承重纪律」；示例报文保留。瘦身**随 spec 覆盖面逐步推进**，不一次性做完四份——任何时刻形态都只有一处权威 |
| 覆盖面 | spec 的 `paths` **覆盖 API 域与 CDN 域两侧**（`/v1/…` 与 `<contentRoot>/manifest`·`manifest.sig`·`/blobs/<sha256>`，以两个 `server` 表达）。CDN 域无鉴权，其安全声明差异在 spec 内显式给出 |
| `info.version` | spec 自身的发布版本，semver，**与 `/v1/` 和 `schemaVersion` 三者互不复用**（节奏完全不同，见 §3）。报文形态破坏性变更 bump major，新增可选字段 / 新增端点 bump minor，纯描述修订 bump patch。三者分工在 spec 顶部注释里显式声明 |

**完整的落笔规则、`schemas/*.json` 拆分判据、一致性核对的三条机检断言与人工清单，见 `_index.md` 的「约定」段。**
Source: `handoffs/2026-08-14-openapi-spec-timing-and-consistency.md`。

## 2. 序列化与命名约定（全局）

| 项 | 定案 | 理由 |
|---|---|---|
| 传输 | HTTPS + JSON（`application/json; charset=utf-8`） | — |
| 字段命名 | **lowerCamelCase** | 第一份契约（`content-manifest.md`）已在用 |
| 枚举值 | **字符串**，取值与客户端 C# 枚举名**逐字相同**（`"Conflict"` / `"EventResolved"` / `"Immediate"`） | 契约允许字段名不同但要求显式映射；枚举**值**同名可省掉一整张映射表，而这类表最容易写漏一项 |
| 未知字段 | **两侧都必须忽略未知字段** | 已是 manifest 侧契约条款，推广到全部报文 |
| 时间 | RFC 3339、**UTC、带 `Z`**；字段名以 `AtUtc` 结尾 | 与客户端 `SyncEnvelope.LastAckAtUtc` 对齐 |
| 整数 | JSON number。**`revision`（`long`）不转字符串**。**判据：取值域可能超出 2⁵³ 的整数一律走字符串** | 账号级 `revision` 每次事件推进 +1，一生也到不了 2⁵³；转字符串会给两侧各加一道解析。判据与这条论证同源——JSON number 在双精度实现里超 2⁵³ 会**静默丢低位**，故 `accountSeed`（`ulong` 随机数，且是逐位复算的输入）以 16 位小写 hex 字符串下发，见 `profile-sync.md` §2 |
| `null` | **不下发 `null`**——可选字段缺失即省略 | 与客户端「绝不把未经检查的 null 向下游传递」同向 |
| 二进制 | 不进 JSON（blob 是独立 GET；签名用 base64 字符串） | manifest 已如此 |

## 3. 端点风格与主版本

**API 面带主版本前缀 `/v1/`；`contentRoot` 下的静态对象不带。**

```
/v1/auth/…            验证码 / 登录 / 刷新 / 登出 / 绑定 / 解绑 / 改名   → auth.md（七端点，封定）
/v1/compliance/…      实名 / 合规态 / 注销 / 数据导出                    → compliance.md（六端点）
/v1/profile/pull      整聚合下行                   → profile-sync.md
/v1/profile/push      diff 上行（CAS + 幂等）      → profile-sync.md
/v1/purchase/…        验票 / 收据幂等读             → purchase.md
/v1/content/flags     按账号解析后的开关结果        → content-manifest.md

<contentRoot>/manifest        静态、无鉴权、CDN
<contentRoot>/manifest.sig    同上
<contentRoot>/blobs/<sha256>  同上，immutable
```

- **`/v1/` 与 `schemaVersion` 的分工**：URL 主版本 = **端点集与传输信封**的破坏性变更（并存两版一段时间，同 `manifestSchema` 的处理）；报文内的 `schemaVersion` = **存档负载**自身的版本（见 §8）。二者不复用一个数字——变更节奏完全不同。
- **`/v1/content/flags` 归 API 域，不在 `contentRoot` 下。** 它需鉴权、按账号计算、`no-cache`——本质是 API 而非静态对象。放在 CDN 域会诱导中间层按静态对象缓存，导致**灰度分桶串号**：这类事故只在放量时显形且极难定位。

## 4. 信封：传输信封（HTTP 头）与负载信封（body 段）

「信封」指两样不同的东西，此处分开命名，**不得混用**：

| 名称 | 位置 | 内容 | 谁读 |
|---|---|---|---|
| **传输信封** | HTTP 头 | 见下两表 | 网关 / 日志层即可读，**不解 body** |
| **负载信封** | `POST /v1/profile/push` 的 body 顶层段 | `pushId` · `baseRevision` · `schemaVersion` · `reason` | 应用层解析，据此判定 CAS 与幂等（详见 `profile-sync.md`） |

### 4a. 请求头（每个 API 请求都带）

| 头 | 语义 | 客户端对位 |
|---|---|---|
| `Authorization: Bearer <token>` | 会话 | `Session.Token` |
| `X-App-Version` | 客户端二进制版本，semver 三段 | `ProfilePayload.AppVersion` |
| `X-Content-Version` | 当前生效的 overlay 版本 | `ProfilePayload.ContentVersion` |
| `X-Request-Id` | 单次请求的调试关联 id，**每次重试都换** | 新增（仅日志用） |

**无鉴权例外的判据（不是一份名单）：** 一个端点可以免带 `Authorization`，**当且仅当调用它的玩家此刻不可能持有 access token**。凭据因此只能在 body 里随请求送达。

按此判据，例外域有**两个**：

| 例外域 | 免鉴权的端点 | 玩家此刻为什么没有 token |
|---|---|---|
| auth | `challenge` · `signin` · `refresh` | 尚未登录；`refresh` 的存在前提就是 access token 已失效 |
| compliance | `POST /v1/compliance/realname` · `DELETE /v1/compliance/deletion` | 被 `signin` 的合规拦截挡在门外，凭 `complianceTicket` 认账号（`compliance.md` §3） |

**其余端点一律照上表全带**，包括合规域自己的另外四个端点。`X-Content-Version` 在登录前无生效 overlay 可报，同样只在这两个域缺省。逐端点的例外表见 `auth.md` §6。`X-Request-Id` **无例外**——全部端点都带。

> **判据而非枚举，是刻意的。** 「例外仅限 auth 域」这种点名式护栏，在第二个域出现时只能靠改名单，而改名单的人不必论证自己够不够格。判据把「够格」变成一次必须通过的检验：`GET /v1/compliance/status` 同属合规域却**不够格**——能查合规态的玩家已经登录成功了。
Source: `handoffs/2026-08-13-auth-endpoint-contract.md`。

### 4b. 应答头（任意应答都带）

| 头 | 语义 |
|---|---|
| `X-Flags-Version` | 当前 flags 批次版本，客户端据此决定是否拉全量 flags |
| `X-Min-App-Version` | 硬闸门阈值，**仅信息性**——判定权在服务端（见 §7） |
| `X-Recommended-App-Version` | 软提示阈值，客户端可提示「有新版本」。**永不阻塞** |
| `X-Server-Time` | RFC 3339 UTC，供客户端做**纯诊断**用的时钟偏差观测。**不参与任何玩法判断**——设备时钟不可信 |
| `Retry-After` | 仅在限流 / 可重试错误时下发 |

**为什么传输信封走头而非 body 字段：**

1. **「随任意应答下发 `flagsVersion`」这条已定语义，只有放在头上才成立。** body 字段覆盖不到 `204`、错误应答与未来任何非 JSON 应答；而 flags 的秒关延迟正是靠「搭任意一次应答的车」压到分钟级的。
2. `sync-service` 已定信封的目的是让后端「不解 Profile 即可做版本维度的聚合与异常检测」——放在头上，网关 / 日志层直接可读；放在 body 里则每层都得先解一遍 JSON。
3. **GET 端点没有 body。** 若信封在 body，`/v1/content/flags`、`/v1/profile/pull` 就得各自例外——一个有例外的信封不是信封。

**为什么 `baseRevision` / `pushId` 反而留在 body：** CAS 前置条件与它所保护的负载留在同一层面，重放与签名边界说得清；且 pull 等端点没有这两项，搬到头上会造出「仅某端点有」的例外。（`If-Match` / ETag / 412 虽是标准语义，但三分支应答仍需在 body 回 `cloudRevision`，且 `pushId` 幂等无标准头可用——最终仍是两套机制并存。）

**对客户端已定 record 的影响：无。** `ProfilePayload` 的 `ContentVersion` / `AppVersion` 是**客户端内部形态**，由 `HttpProfileBackend` 在发请求时搬到头上即可；契约本就允许「报文字段名与客户端字段名不同」。

## 5. 错误体

所有非 2xx 的 JSON 应答统一此形状：

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
| `class` | ✅ | **处置分层**，四值：`Retryable` / `Fatal` / `Reauth` / `Upgrade` |
| `message` | ✅ | **面向开发者的调试说明**，英文自由文本。**必须写到能定位问题**——含触发该错误的关键值 |
| `detail` | 可选 | **结构化**补充（`cloudRevision` / `retryAfterSeconds` / 合规原因串），按 `code` 取固定形状。给**代码**读 |
| `requestId` | ✅ | 回显本次请求的 `X-Request-Id`，把客户端日志与服务端日志接起来 |

`class` ∈ `{ "Retryable", "Fatal", "Reauth", "Upgrade" }`，对应 `01` 点名的「可重试 / 不可重试 / 需重登 / 需强更」。**不用布尔 `retryable`**：它表达不了「需重登」与「需强更」这两条同样不可重试、但处置完全不同的路径。

### 5a. `message` 与 `detail` 的分工

- **`message` 给人读，`detail` 给代码读。** 客户端**不得**解析 `message` 做任何分支——措辞可随时改写，任何依赖它的分支都会在某次后端改文案时静默失效。需要被代码消费的值一律进 `detail`，且在该 `code` 的台账条目里写死形状。
- **`message` 不直接展示给玩家。** 玩家可见文案由客户端 UI 层按 `OpError` 决定。`message` 是英文调试串——进日志、进上报，不进弹窗。
- **`message` 必须可安全落日志**：不得包含 token、完整账号凭据或任何密钥；账号 / `pushId` 一类标识按前缀截断。
- **客户端侧承载**：`message` + `requestId` 拼进 `OpResult.Detail` 并随 `GD.PushError` / `GD.PushWarning` 输出——客户端日志纪律要求每条消息带定位标识符，`requestId` 正是跨越进程边界的那个标识符。

### 5b. 三条承重纪律

- **客户端不得靠 HTTP 状态码分支**，一律以 `code` 为键映射。状态码只承担传输层语义（谁重试、谁记日志），业务分支全在 `code` 上——否则「401 到底是 token 过期还是被挤下线」这类区分永远做不干净，而这两者的客户端处置已定案且**完全不同**。
- **未知 `code` → 按 `class` 降级处置；未知 `class` → 当作 `Fatal` + 上报一次。** 与「绝不静默通过」、与 content-service「验签失败 → 拒绝 + 上报一次」同构。**应答体无法解析为上述形状**（网关 502 / 非 JSON 错误页）→ 按 HTTP 状态码降级为 `server.unavailable`（`Retryable`），不要求网关也产出契约错误体。
- **`class` 是契约的一部分，不是提示。** 服务端为每个 `code` 固定一个 `class`，**不因请求而变**——否则客户端的重试策略无法静态推理。

## 6. 错误码台账

**新增 `code` 一律在此登记。** 每条至少给出：`class` · 客户端 `OpError` · 客户端处置 · `detail` 形状 · `message` 必含的关键值。最后一列使「调试信息够不够」成为契约里**可核对**的东西，而不是各端点各凭自觉。

| `code` | `class` | `OpError` | 客户端处置 | `detail` 形状 | `message` 必含 |
|---|---|---|---|---|---|
| `auth.token_expired` | `Reauth` | `Auth` | `RefreshTokenAsync()` 静默刷新；**刷新失败按判据分两条**（见台账下方）——网络失败走 sync 缓冲通道**不硬阻塞**，收到 `auth.session_revoked` 才硬阻塞 | — | token 签发时间与过期时间 |
| `auth.token_invalid` | `Reauth` | `Auth` | 同上 | — | 拒绝原因（签名 / 格式 / 未知 kid） |
| `auth.session_revoked` | `Reauth` | `Auth` | **硬阻塞**重登（被挤下线）；重登后先 pull 后 flush；**暂停退避重试**。`reasonKey` 驱动二级措辞（七值，`auth.md` §10） | `{ revokedAtUtc, reasonKey }` | 吊销时间与触发源 |
| `auth.channel_rejected` | `Fatal` | `Auth` | 登录屏呈现失败原因 | `{ channel, channelCode }`（`channelCode` 可选、渠道原始码原样透传，**客户端不解析、只随日志上报**） | 渠道名与渠道侧错误码 |
| `auth.credential_invalid` | `Fatal` | `Auth` | 登录屏呈现失败原因（自建渠道的凭据校验失败：验证码错、标识符格式非法） | — | 失败的校验项（**不含**凭据原值） |
| `auth.challenge_expired` | `Fatal` | `Auth` | 提示重新获取验证码（与上一条分列：玩家处置不同） | — | 验证码签发时间与过期时间 |
| `auth.identity_already_bound` | `Fatal` | `Auth` | 绑定屏呈现冲突：**必须说明那个渠道下有另一份进度、绑定不会合并两份存档**（`auth.md` §1a） | `{ channel }` | 冲突的渠道 |
| `auth.identity_required` | `Fatal` | `Auth` | 拒绝解绑并说明理由 | `{ channel }` | 「这是最后一个登录方式」 |
| `auth.nickname_rejected` | `Fatal` | `Auth` | 按 `code` 出文案；`reasonKey` 驱动二级措辞（三值，`auth.md` §10），**未知取值须有兜底** | `{ reasonKey }` | 拒绝理由标识（敏感词 / 频次 / 格式） |
| `compliance.realname_required` | `Fatal` | `Compliance` | 阻塞屏 + 「去实名」动作，凭 ticket 走实名流程 | `{ reasonKey, complianceTicket, ticketExpiresAtUtc }` | 触发的合规规则标识（**不含**姓名 / 证件号任何片段） |
| `compliance.playtime_blocked` | `Fatal` | `Compliance` | 阻塞屏 + 展示 `resumeAtUtc`，**无重试动作** | `{ reasonKey, resumeAtUtc }` | 触发的时段规则与解除时间 |
| `compliance.account_restricted` | `Fatal` | `Compliance` | 阻塞屏 + 申诉入口（申诉走站外，不占端点） | `{ reasonKey }` | `status` 值与置入时间 |
| `compliance.account_deleting` | `Fatal` | `Compliance` | 阻塞屏 + 「撤销注销」动作，凭 ticket | `{ reasonKey, deletionEffectiveAtUtc, complianceTicket, ticketExpiresAtUtc }` | 冷静期起止时间 |
| `sync.conflict` | `Fatal` | `Conflict` | 以云端为准丢弃本地缓冲 + 明确告知玩家（CAS 第二分支；**后端写入路径的回声校验不通过复用本码**，客户端处置逐字相同、不新增分支） | `{ cloudRevision }`；回声不通过时 `{ cloudRevision, field }`（`field` = 第一条不匹配的 JSON path，`profile-sync.md` §5c） | `baseRevision` 与 `cloudRevision` 两值、账号与 `pushId` 前缀；回声不通过时另含违规 path |
| `sync.revision_ahead` | `Fatal` | `Conflict` | 同上 **+ 上报一次**；不试图自愈（CAS 第三分支 / 不可能态） | `{ cloudRevision }` | 同上 |
| `sync.payload_schema_unsupported` | `Upgrade` | `Validation` | 见 §7c：**不硬阻塞**，保留待发队列 + 非阻塞升级提示 | `{ supportedSchemaVersions }` | 收到的 `schemaVersion` 与当前兼容集合 |
| `sync.payload_invalid` | `Fatal` | `Validation` | 报文结构 / 必填字段不合法——**这是 bug 面，不是玩家面**，上报 | `{ field }` | 违规字段路径与期望形态 |
| `rate.limited` | `Retryable` | `Network` | 进待发队列 + 退避；**须尊重 `Retry-After`** | `{ retryAfterSeconds }` | 触发的限流窗口与当前计数 |
| `server.unavailable` | `Retryable` | `Network` | 同既定断线降级 | — | 下游组件与失败阶段 |
| `client.version_unsupported` | `Upgrade` | `Auth` | 强更闸门（**只在登录 / 启动点触发**，见 §7） | `{ minAppVersion }` | 收到的 `appVersion` 与当前下界 |
| `resource.not_found` | `Fatal` | `NotFound` | — | `{ resource }` | 资源类型与 id |

**台账的五条承重项：**

- **「刷新失败」按判据拆成两条路径，判据是「有没有收到明确应答」而非「失败了」。** 网络失败（请求发不出 / 应答收不到 / `server.unavailable`）→ 视同断线走 sync 缓冲通道 + 指数退避，**不硬阻塞**；收到 `auth.session_revoked` → **硬阻塞重登 + 暂停退避**（重试必然成功不了）。收不到应答一律算网络失败——弱网下二者不可区分，且误判成硬阻塞的代价远大于多退避几次。`POST /v1/auth/refresh` 的错误清单因此**只有两条**（`auth.session_revoked` · `server.unavailable`），使这个判据在报文层面无歧义（见 `auth.md` §8 §10）。
- **`auth.session_revoked` 的触发源必须进 `detail.reasonKey`，不能只写在 `message` 里。** §5a 已定客户端不得解析 `message`，而「另一设备登录」与「账号被运营吊销」对玩家是两句完全不同的话却共用同一个 `code`——触发源必须对代码可见。三处 `reasonKey` 的形态（PascalCase）、二级文案键的机械变换与兜底纪律统一在 `auth.md` §10，**台账不复述取值表**。
- **四条 `compliance.*` 只在 `signin` 出现。** 它们全为 `Fatal`（重试同一次 `signin` 不改变结果）、全映 `OpError.Compliance`；业务端点与 `/v1/profile/*` 一律不返回（`auth.md` §5a · `profile-sync.md` §11）。`restricted` 与 `banned` **共用 `compliance.account_restricted`**，靠 `reasonKey` 分辨——玩家处置相同、只有措辞不同，拆两个 `code` 会让处置表多一行却走同一条路径。
- **`auth.token_expired` 与 `auth.session_revoked` 必须是两个 `code`。** 二者的客户端处置**完全不同**（一个静默刷新、绝不打断轮回；一个硬阻塞重登）。若后端只给一个「401 未授权」，客户端无从区分，只能二选一——选错哪一边都直接违反一条客户端语义。
- **限流是 `Retryable`，不是 `Conflict`。** 限流不改变 `cloudRevision`，客户端原样重试即可（`pushId` 保证幂等）；映成 `Conflict` 会丢弃本地缓冲，等于把一次限流变成一次进度丢失。
- **`Cancelled` 与 `Migration` 不得有任何后端 `code` 映射到它们。** 前者是客户端 `CancellationToken` 的本地语义；后者是**客户端本地**存档迁移失败（`MigrationManager`）。后端拒绝一个它不认识的 `schemaVersion` 是**上行校验失败**（`Validation`），不是迁移——映到 `Migration` 会让客户端去跑一条本地迁移路径，而问题根本不在本地。

**客户端侧的映射落地形态**（供跨库 handoff 参考，不在本库定稿）：映射应是**数据**而非 switch 语句——一张 `code → (OpError, 处置)` 的表，未知 `code` 落到按 `class` 的四条默认路径。这与客户端「新增内容 = 新增数据，不编辑 switch」的可加性纪律一致。

## 7. 版本协商与强制更新

### 7a. 强更闸门：判定在服务端

- **不下发阈值让客户端自己比。** `content-manifest.md` 已因 semver 字典序坑（字典序会判 `1.10.0 < 1.9.0`）而明写比较规则；把硬闸门交给老客户端的比较逻辑，等于把闸门的正确性押在**可能正是需要被闸掉的那个版本**上。服务端判定后直接以 `client.version_unsupported`（`class: Upgrade`）拒绝；`X-Min-App-Version` 应答头仅供展示与诊断。
- **软提示与硬闸门分离**：`X-Recommended-App-Version`（软，客户端可提示「有新版本」，**永不阻塞**）与 `client.version_unsupported`（硬，拒绝）。

### 7b. 闸门只在登录与启动 pull 生效

这两处**本就是**客户端已定案的仅有两处硬阻塞。轮回进行中的 push **不得**因版本过旧被硬拒——那会让玩家刚打完的战斗无处可去，直接违反「绝不回退存档点」与 pillar #4「不阻塞玩家」。

**实现语义：闸门在签发 token 时判定一次**，会话期内不因阈值提升而中途变严；阈值提升在玩家**下一次登录**时生效。这让「运营提升 `minAppVersion`」这个动作永远不会打断进行中的轮回。

### 7c. `Upgrade` 类错误在非闸门点的处置（承重纪律）

**`Upgrade` 类错误只在登录 / 启动 pull 构成硬阻塞；其余时机一律降级为非阻塞提示。**

典型情形是 `sync.payload_schema_unsupported` 在**轮回中途的 push** 上返回，且它重试永远不会成功。客户端处置：

- **本地缓冲保留、不丢弃**（`绝不回退存档点`）；
- UI 出一条**非模态**「需更新版本才能同步」提示；
- **暂停自动退避重试**（重试必然失败，退避只是空耗电量与流量）；
- 恢复点：玩家更新并**重新登录**后 → 先 pull 后 flush。

它与客户端「缓冲超限 → 软阻塞」策略的衔接属客户端侧，见本文件末的跨库待办。

### 7d. `minAppVersion`（内容维度）与强更闸门（协议维度）互不兼职

| | 承载 | 谁判定 | 效果 |
|---|---|---|---|
| `minAppVersion`（manifest 内） | **内容维度**：应用此 overlay 所需的最低客户端版本 | **客户端**自行比对 | 跳过本次 overlay 更新、照常用基线。**永不阻塞、永不强更** |
| `X-Min-App-Version` / `client.version_unsupported` | **协议维度**：能否继续与后端通话 | **服务端** | 登录 / 启动点硬阻塞要求更新 |

内容太新只是不更新内容；协议不兼容才拦人。

### 7e. 兼容矩阵由后端单点维护

它是服务端判定的输入，必须与判定逻辑同处。落点 `operations/`（栈落定后），至少含：支持的 `appVersion` 下界 · 并存的 URL 主版本 · 并存的 `manifestSchema` / `schemaVersion` 集合 · 各自的下线计划。**客户端不持有这张表的任何副本。**

## 8. Profile 负载的三段可见性

**`schemaVersion` 是上行负载的版本，其结构权威在客户端**（Profile 是客户端定义的类模型），迁移路径也在客户端（`MigrationManager`）。契约**不把 Profile 的字段表抄进本库**——那会当场制造两份真值，并违反「不复述另一侧的设计」。

后端对 Profile 是**半透明**的：

| 段 | 后端可见性 | 依据 |
|---|---|---|
| 负载信封（`pushId` / `baseRevision` / `schemaVersion` / `reason`） | **完全透明**，后端解析并据此判定 | CAS 与幂等是后端职责 |
| **后端可见字段子集**（复算所需：`accountSeed`、`PlayerPowerFragment.*`、`playerPower[*]` 的 `powerId` 与 `sourceCode`） | **透明**，**逐 JSON path 的白名单见 `profile-sync.md` §5**（补集即不透明段；透明 ≠ 可改写；**路径本身是契约的一部分**） | 「后端可复算校验」已定；复算边界见 `profile-sync.md` §7 |
| Profile / diff 的其余部分 | **不透明**：按不透明 JSON 存储并**原样回传** | pillar #1「后端不重跑玩法」 |

- **不透明段的纪律：** 后端**不得**对不透明段做结构校验、不得改写、不得因其内部字段变化而拒绝上行。**推论：客户端加一个纯统计字段或纯展示字段，不需要后端配合、不需要提升 `schemaVersion`**——这是「统计层新增字段成本近乎为零」在契约侧的兑现。
- 后端**只在 `schemaVersion` 越出兼容集合时拒绝**（`sync.payload_schema_unsupported`）。兼容集合进 §7e 的兼容矩阵。
- **统计计数层：后端不复算、不校验，且不得用统计数据驱动任何发放**（活动奖励 / 解锁）。一旦这么用，该字段就必须整体升为规则字段。运维侧的对应约束见 `operations/_index.md`。

## 决策(-> ADR)

- **契约表达形式 = OpenAPI 3.1 单点，不共享 DTO 代码** → ADR 候选③，登记于 `decisions/_index.md`。值得固化其依据（根约定的分支线独立性），否则「后端也用 C# 了，不如共享 DTO」会反复被重新提出。

## 备选方案（已考虑并否决）

- **共享 C# DTO 代码** — 需要跨两条独立分支线的共享编译期依赖，与根约定直接冲突；且会把契约的版本节奏绑死在两个运行时的交集上。
- **OpenAPI 3.0** — 其 schema 是 JSON Schema 的裁剪方言，两侧工具链差异会以「字段可空性对不上」的形式在实现期才暴露。
- **gRPC / Protobuf** — CDN 侧的 manifest / blob 本就是裸 HTTP 静态对象（会造出两套栈），且客户端是 Godot / .NET 跨四端导出（含 Web）。请求量级（每玩家每事件一次上行）远不到需要二进制协议的地步。
- **传输信封放 body 字段** — 无法覆盖「随任意应答下发 `flagsVersion`」这条已定语义（见 §4）。
- **`baseRevision` 搬到 HTTP 头 / 用 `If-Match` + 412 表达 CAS** — 前者把 CAS 前置条件与它保护的负载拆到两个层面，且造出「仅 push 端点有」的头；后者仍需在 body 回 `cloudRevision`，且 `pushId` 幂等无标准头可用。
- **只用 HTTP 状态码表达业务错误** — `401` 无法区分「静默刷新」与「硬阻塞重登」。
- **只给 `retryable: bool`** — 表达不了「需重登」与「需强更」这两条同样不可重试、但处置完全不同的路径。
- **省掉 `message`，只给 `code` + `detail`** — `code` 只说「是哪一类」，说不出「这一次为什么」。线上排查的第一现场是日志里的那一行；移动端最难复现的恰是只出现在玩家设备上的那一次。
- **强更闸门交客户端比较 `X-Min-App-Version`** — 把闸门的正确性押在待闸版本自己的比较逻辑上。
- **强更在任意请求点生效** — 会在轮回中途把 push 硬拒，违反「绝不回退存档点」与「仅两处硬阻塞」。
- **`sync.payload_schema_unsupported` 视同 Fatal 丢弃本地缓冲** — 玩家刚打完的进度因版本问题而非冲突被丢弃，与 pillar #4 相抵。
- **把 `schemaVersion` 兼容性判定前移到登录点** — 需在登录请求中额外声明 `schemaVersion`，且无法覆盖「会话中途客户端升级负载结构」的情形。
- **把 Profile 内部 schema 抄进契约** — 制造第二份真值，且与 pillar #1 相悖。

## Open questions

- **合规域端点自身的错误码**（ticket 过期 / 已消费、核验服务拒绝、冷静期已过、导出任务不存在或未就绪）——随 `compliance.md` 六端点的报文本体一并落笔并登记进 §6 台账。**与四条 `compliance.*` 拦截码无关**，后者已封定。
- **`openapi.yaml` / `schemas/*.json` 的实际落笔**——**规则已定**（§1 的触发点 / 范围 / 形态迁移，`_index.md` 的完成判据与三条机检断言），只待触发点到来，属待落笔项而非设计未决。唯一仍开放的是三条机检断言的**承载位置**（设计库侧有无自动化流水线），待 `06-platform-stack.md`；在此之前以人工清单执行。

## 跨库待办（客户端侧，本库不代为决定）

需 `game-design-documents/` 另写一份 handoff，见 `handoffs/2026-08-11-contract-expression-envelope-and-error-codes.md` 的「客户端侧影响」段：`Retry-After` 的尊重 · `X-Flags-Version` 的读取点 · 错误码映射表的落点与形态 · `Upgrade` 类错误在非闸门点的非阻塞处置与「缓冲超限 → 软阻塞」的衔接 · `HttpProfileBackend` 把两个版本字段搬到 HTTP 头。
