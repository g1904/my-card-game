# 协议契约：表达形式、信封、错误码分层与版本协商

- id: 2026-08-11-contract-expression-envelope-and-error-codes
- date: 2026-08-11
- topic: contracts/envelope · contracts/content-manifest（回改）· operations（兼容矩阵 / 错误码台账）· decisions（一条 ADR 候选）
- status: distilled
- distilled-to: contracts/envelope.md, contracts/_index.md, contracts/content-manifest.md, operations/_index.md, decisions/_index.md, open-questions/01-contracts.md, open-questions/06-platform-stack.md, answer-logs/log-contract-expression-envelope-and-error-codes.md

## Intent（distilled）

**一句话：** 契约的边界层一次立齐——表达形式定为 **OpenAPI 3.1 + JSON Schema 单点**（明确否决共享 DTO 代码）；**信封是 HTTP 头**；错误体统一为 `code` / `class` / `message` / `detail` / `requestId` 五字段并配一张 **`code` → `OpError` 映射台账**；**强更闸门判定在服务端、但只在登录 / 启动点生效**；**后端对 Profile 是半透明的**，不复述客户端的存档结构。

`open-questions/01-contracts.md` 的四条不是四个独立问题，而是同一层的四个切面：表达形式不定，字段名无处落笔；信封不定，错误码与版本协商无处搭载。因此一并答结，外加 `content-manifest.md` 推给本层的两项欠账（信封携带 `flagsVersion`、`minAppVersion` 与强更闸门的分工）。

本 handoff **不**产出 `auth.md` / `profile-sync.md` 的报文本体——它们是这一层定稿后的下一批。

### 1. 表达形式：OpenAPI 3.1 + JSON Schema，否决共享 DTO 代码

**这条不依赖技术栈选型，依据在根约定。** 根约定写明「客户端与后端是两条彼此独立的分支线，从不互相合并」，理由是后端代码不得被编译进游戏程序集。共享 DTO 要成立就需要一个被两条分支线同时引用的编译期依赖：它要么住在某一条分支里（当场违反上述理由），要么需要第三个发布物，其版本节奏要同时迁就 Godot 4.7 的 .NET 目标框架与后端运行时。

因此：**即使后端最终也选 C#，契约仍是文档级 OpenAPI + JSON Schema，两侧各自持有自己的 DTO。**「后端用 C# 就能共享 DTO」这个此前被假定的耦合**不成立**——`01` 因此从 `06` 的下游里摘了出来，两者可并行推进。

| 项 | 定案 |
|---|---|
| 规范 | **OpenAPI 3.1**（schema 方言即 JSON Schema 2020-12，避免 3.0 的子集裁剪与 `nullable` 方言差） |
| 落点 | `contracts/openapi.yaml` + `contracts/schemas/*.json` |
| markdown ↔ spec 分工 | markdown 承载语义 / 理由 / 承重纪律；spec 承载字段名 / 类型 / 必填性 / 枚举值。冲突时**字段形态以 spec 为准，语义以 markdown 为准** |
| 代码生成 | **不强制**——契约不规定实现手段 |
| 落地时机 | **不现在建空壳**；在首个端点进入实现时同时落 `openapi.yaml`，在此之前 markdown 的字段表即视为草案 |

**推论：`content-manifest.md` 的字段名就地转正**——它已在用的 lowerCamelCase / RFC 3339 / 忽略未知字段三条正是下面的全局约定，那份文档的「字段名待表达形式」限定随本 handoff 解除。

### 2. 序列化与命名约定（全局一次定死）

HTTPS + JSON（`application/json; charset=utf-8`）· 字段 **lowerCamelCase** · 枚举值为**字符串且与客户端 C# 枚举名逐字相同** · **两侧都必须忽略未知字段** · 时间为 RFC 3339 UTC 带 `Z`、字段名以 `AtUtc` 结尾 · `revision`（`long`）**以 JSON number 传输，不转字符串** · **不下发 `null`**（可选字段缺失即省略）· 二进制不进 JSON。

枚举值同名的理由：契约允许字段名不同但要求显式映射，而枚举**值**同名可省掉一整张映射表——这类表最容易写漏一项。

### 3. 端点风格与路径版本

**API 面带主版本前缀 `/v1/`；`contentRoot` 下的静态对象不带。**

```
/v1/auth/…            登录 / 刷新 / 登出        → auth.md
/v1/profile/pull      整聚合下行                 → profile-sync.md
/v1/profile/push      diff 上行（CAS + 幂等）    → profile-sync.md
/v1/content/flags     按账号解析后的开关结果      → content-manifest.md

<contentRoot>/manifest        静态、无鉴权、CDN
<contentRoot>/manifest.sig    同上
<contentRoot>/blobs/<sha256>  同上，immutable
```

- **`/v1/` 与 `schemaVersion` 分工**：URL 主版本 = 端点集与信封的破坏性变更（并存两版一段时间，同 `manifestSchema` 的处理）；报文内的 `schemaVersion` = 存档负载自身的版本。二者变更节奏完全不同，不复用一个数字。
- **`/content/flags` 回改为 `/v1/content/flags`，归 API 域。** 它需鉴权、按账号计算、`no-cache`——本质是 API 而非 CDN 对象。放在 `contentRoot` 下会诱导中间层按静态对象缓存，导致**灰度分桶串号**，这类事故只在放量时显形且极难定位。manifest / manifest.sig / blob 三个静态对象保持在 `contentRoot` 下不变。

### 4. 信封走 HTTP 头

**传输信封是 HTTP 头，不是 body 字段。**

请求头（每个 API 请求都带）：`Authorization: Bearer <token>` · `X-App-Version`（semver 三段）· `X-Content-Version` · `X-Request-Id`（每次重试都换，仅日志用）。

应答头（任意应答都带）：`X-Flags-Version` · `X-Min-App-Version`（仅信息性）· `X-Recommended-App-Version`（软提示）· `X-Server-Time`（RFC 3339 UTC，纯诊断用的时钟偏差观测，**不参与任何玩法判断**）· `Retry-After`（仅限流 / 可重试错误时）。

三条理由：

1. **「随任意应答下发 `flagsVersion`」这条已定语义，只有放在头上才真正成立**——body 字段覆盖不到 `204`、错误应答与未来任何非 JSON 应答，而 flags 秒关正是靠搭任意一次应答的车压到分钟级。
2. `sync-service.md` 已写明信封的目的是让后端「不解 Profile 即可做版本维度的聚合与异常检测」——放在头上，网关 / 日志层直接可读；放在 body 里则每层都得先解一遍 JSON。
3. **GET 端点没有 body**，否则 `/v1/content/flags`、`/v1/profile/pull` 各自例外——有例外的信封不是信封。

**对客户端已定 record 无影响**：`ProfilePayload` 的 `ContentVersion` / `AppVersion` 是客户端内部形态，由 `HttpProfileBackend` 发请求时搬到头上即可。

### 5. 两种「信封」的命名分离（interview 裁决）

「信封」一词此前同时指两样东西，本 handoff 把它们拆开命名：

| 名称 | 位置 | 内容 | 谁读 |
|---|---|---|---|
| **传输信封** | HTTP 头 | `Authorization` · `X-App-Version` · `X-Content-Version` · `X-Request-Id` | 网关 / 日志层即可读，不解 body |
| **负载信封** | `POST /v1/profile/push` 的 body 顶层段 | `pushId` · `baseRevision` · `schemaVersion` · `reason` | 应用层解析，据此判定 CAS 与幂等 |

**`baseRevision` / `pushId` 留在 push body 的负载信封段**，不搬到 HTTP 头、也不用 `If-Match` / ETag 表达 CAS。理由：CAS 前置条件与它所保护的负载留在同一层面，重放与签名边界说得清；且 pull 等端点没有这两项，搬到头上会造出「仅某端点有」的例外。`If-Match` / 412 虽是标准语义，但已定案的三分支应答仍需在 body 回 `cloudRevision`，且 `pushId` 幂等无标准头可用，最终仍是两套机制并存。

### 6. 错误体与 `OpError` 映射

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

必填四项 `code` · `class` · `message` · `requestId`；`detail` 可选，形状按 `code` 在台账中固定。

- **`code`** —— 稳定字符串 `<域>.<原因>`，**永不复用、永不改写含义**。它是客户端映射表的键。
- **`class`** —— 处置分层，四值 `Retryable` / `Fatal` / `Reauth` / `Upgrade`（正是 `01` 点名的「可重试 / 不可重试 / 需重登 / 需强更」）。布尔 `retryable` 表达不了「需重登」与「需强更」这两条同样不可重试、但处置完全不同的路径。
- **`message`** —— **面向开发者的英文调试说明，必填，且必须写到能定位问题**（含触发该错误的关键值）。
- **`detail`** —— 结构化补充，**给代码读**。
- **`requestId`** —— 回显 `X-Request-Id`，把两侧日志接起来。

**`message` 与 `detail` 的分工**：`message` 给人读、`detail` 给代码读；客户端**不得**解析 `message` 做任何分支（措辞可随时改写，依赖它的分支会在某次改文案时静默失效）。`message` **也不直接展示给玩家**——玩家可见文案由客户端 UI 层按 `OpError` 决定。`message` **必须可安全落日志**：不得含 token / 完整凭据 / 密钥，账号与 `pushId` 一类标识按前缀截断。客户端侧把 `message` + `requestId` 拼进 `OpResult.Detail` 并随 `GD.PushError` / `GD.PushWarning` 输出。

**三条承重纪律：**

- **客户端不得靠 HTTP 状态码分支**，一律以 `code` 为键。状态码只承担传输层语义——否则「401 到底是 token 过期还是被挤下线」永远做不干净，而这两者的处置在客户端侧已定案且完全不同。
- **未知 `code` → 按 `class` 降级处置；未知 `class` → 当作 `Fatal` + 上报一次。** 与「绝不静默通过」同构。
- **`class` 是契约的一部分，不是提示**：服务端为每个 `code` 固定一个 `class`，不因请求而变，否则客户端的重试策略无法静态推理。

首批映射台账见 `contracts/envelope.md`。其中两条最承重：

- **`auth.token_expired` 与 `auth.session_revoked` 必须是两个 `code`**——客户端已定案二者处置完全不同（静默刷新、绝不打断轮回 vs 硬阻塞重登）。只给一个「401 未授权」，客户端只能二选一，选错哪边都直接违反一条已定案语义。
- **限流是 `Retryable` 而非 `Conflict`**——限流不改变 `cloudRevision`，原样重试即可（`pushId` 保证幂等）；映成 `Conflict` 会丢弃本地缓冲，把一次限流变成一次进度丢失。

`Cancelled` 与 `Migration` **不得有任何后端 `code` 映射到它们**：前者是客户端 `CancellationToken` 的本地语义，后者是客户端本地存档迁移失败（`MigrationManager`）。后端拒绝一个不认识的 `schemaVersion` 是**上行校验失败**，不是迁移——映到 `Migration` 会让客户端去跑一条本地迁移路径，而问题根本不在本地。

### 7. 强更闸门：判定在服务端，但只在登录 / 启动点生效

- **不下发阈值让客户端自己比。** `content-manifest.md` 已因 semver 字典序坑（`1.10.0 < 1.9.0`）明写比较规则；把硬闸门交给老客户端的比较逻辑，等于把闸门的正确性押在**可能正是需要被闸掉的那个版本**上。服务端判定后直接以 `client.version_unsupported`（`class: Upgrade`）拒绝，`X-Min-App-Version` 仅供展示与诊断。
- **软硬分离**：`X-Recommended-App-Version`（软，永不阻塞）与 `client.version_unsupported`（硬，拒绝）。
- **闸门只在登录与启动 pull 生效**——这两处本就是已定案的仅有两处硬阻塞。轮回进行中的 push 不得因版本过旧被硬拒，那会让玩家刚打完的战斗无处可去，直接违反「绝不回退存档点」与 pillar #4。
- **实现语义**：闸门在**签发 token 时**判定一次，会话期内不因阈值提升而中途变严；阈值提升在玩家下一次登录时生效。运营提升 `minAppVersion` 这个动作因此永远不会打断进行中的轮回。
- **`minAppVersion` 与强更闸门互不兼职**：前者是**内容维度**（客户端自行比对 → 跳过本次 overlay、照常用基线，**永不阻塞**）；后者是**协议维度**（服务端判定 → 登录 / 启动点硬阻塞）。内容太新只是不更新内容；协议不兼容才拦人。
- **兼容矩阵由后端单点维护**（落 `operations/`）：支持的 `appVersion` 下界、并存的 URL 主版本、并存的 `manifestSchema` / `schemaVersion` 集合、各自的下线计划。客户端不持有这张表的任何副本。

### 8. Upgrade 类错误在非闸门点的处置（interview 裁决）

**承重纪律：`Upgrade` 类错误只在登录 / 启动点构成硬阻塞，其余时机一律降级为非阻塞提示。**

`sync.payload_schema_unsupported` 会在**轮回中途的 push** 上返回，且它重试永远不会成功。客户端处置：**本地缓冲保留、不丢弃**（`绝不回退存档点`）；UI 出一条非模态「需更新版本才能同步」提示；**暂停自动退避重试**（重试必然失败）；恢复点是玩家更新并重新登录后**先 pull 后 flush**。它与「缓冲超限 → 软阻塞」的既定策略如何衔接属客户端侧，见跨库待办。

### 9. Profile 对后端半透明，契约不复述存档结构

`schemaVersion` 是上行负载的版本，其**结构权威在客户端**（Profile 是客户端定义的类模型），迁移路径也在客户端。契约不把 Profile 的字段表抄进本库——那会当场制造两份真值。三段可见性：

| 段 | 后端可见性 | 依据 |
|---|---|---|
| 负载信封（`pushId` / `baseRevision` / `schemaVersion` / `reason`） | **完全透明**，后端解析并据此判定 | CAS 与幂等是后端职责 |
| **后端可见字段子集**（复算所需：`AccountSeed` 相关掷骰序号与命中结果、`PlayerPowerFragment.*` 等规则字段） | **透明**，逐字段列进契约 | `03` 已定「后端可复算校验」 |
| Profile / diff 的其余部分 | **不透明**：按不透明 JSON 存储并原样回传 | pillar #1「不重跑玩法」 |

- 后端**不得**对不透明段做结构校验、不得改写、不得因其内部字段变化而拒绝上行。**推论：客户端加一个纯统计或纯展示字段，不需要后端配合、不需要提升 `schemaVersion`**——这是 `sync-service.md` 已推出的「统计层新增字段成本近乎为零」在契约侧的兑现。
- 后端只在 `schemaVersion` 越出兼容集合时拒绝（`sync.payload_schema_unsupported`）。兼容集合进兼容矩阵。
- **统计计数层：后端不复算、不校验，且不得用统计数据驱动任何发放**（活动奖励 / 解锁）。一旦这么用，该字段就必须整体升为规则字段。（`sync-service.md` 第 5 条点名要求写进本库。）

## Clarifications（interview 产物）

- **`baseRevision` / `pushId` 落在 HTTP 头还是 push body？** → **留在 push body 的负载信封段**。这细化了原草稿第 4 节（只列了四个请求头、未交代 `revision`）与第 6b 节（把它列进「负载内的透明段」）之间的形态不一致，并把「信封」一词拆成**传输信封 / 负载信封**两个名字（见第 5 节）。否决了搬到 `X-Base-Revision` 头与用 `If-Match` / ETag 两种形态。
- **`sync.payload_schema_unsupported`（`class: Upgrade`）在轮回中途的 push 上如何处置？** → **不硬阻塞，保留待发队列 + 非阻塞升级提示 + 暂停自动退避**。这补齐了原草稿只写「见第 6 节」的空缺，并推出一条通用纪律：**`Upgrade` 类错误只在登录 / 启动点构成硬阻塞**（见第 8 节）。否决了「视同 Fatal 丢弃本地缓冲」与「把 `schemaVersion` 判定前移到登录点」。

**评审阶段（2026-08-11）已由用户裁决的三处取向**，本 handoff 按裁决落笔：K1 信封走 HTTP 头 · K2 路径主版本 `/v1/` · K3 错误分层用四值 `class`；并追加要求「错误体必须带 `message` 调试字段」。张力项一并裁决：`/content/flags` → `/v1/content/flags`。

## Open questions

- **`compliance.*` 错误码的具体清单**——实名 / 防沉迷 / 注销 / 导出各自的分支要等 `02-account-compliance.md` 的合规方案定；本层只立了两条示例与它们的 `class`。
- **`auth.session_revoked` 的触发条件**——待多设备并发裁决规则定案（`02`）。`code` 与处置已可先定。
- **`pushId` 记忆窗口、限流阈值**等服务端参数——属实现，不进本层契约（`03`）。
- **`openapi.yaml` / `schemas/*.json` 的实际落笔**——按定案推迟到首个端点进入实现时，届时需确认 markdown 字段表与 spec 的一致性核对方式。

## Notes / triage

- 落点：新建 `contracts/envelope.md`；`contracts/_index.md` 重写「现状」段；`contracts/content-manifest.md` 两处回改并解除字段名限定；`operations/_index.md` 增两个具体运维对象；`decisions/_index.md` 增一条 ADR 候选；`open-questions/01-contracts.md` 四条全部移出；`open-questions/06-platform-stack.md` 删去「与 `01` 一起决」的耦合表述。
- ADR 候选：**契约表达形式 = OpenAPI 单点，不共享 DTO 代码**——依据是根约定的分支线独立性，值得固化，否则「后端也用 C# 了，不如共享 DTO」会被反复重新提出。
- `auth.md` / `profile-sync.md` 的前置解除，可按此序开工（`auth.md` 先行——它承载 token 生命周期与那两个必须分开的 `code`）。

## 客户端侧影响

**本 handoff 改动客户端 ↔ 后端边界的语义**，受影响的客户端成分：`sync-service`、`account-service`、`content-service`。`game-design-documents/` 侧**需另写一份 handoff**（本库不代为决定），至少五点：

1. **`Retry-After` / `retryAfterSeconds` 的尊重**——客户端已定「指数退避」，需明确：收到限流时以服务端给的等待时间为下界。→ `systems/services/sync-service.md`。
2. **`X-Flags-Version` 的读取点与触发拉取时机**——`content-manifest.md` 已把这条列为客户端侧待办，本 handoff 把它落到了具体的应答头上。→ `systems/services/content-service.md`。
3. **错误码 → `OpError` 映射表在客户端的落点与形态**——建议为**数据表**而非 switch 语句（一张 `code → (OpError, 处置)` 表，未知 `code` 落到按 `class` 的四条默认路径），与「新增内容 = 新增数据，不编辑 switch」的可加性纪律一致；并确认 `auth.token_expired` / `auth.session_revoked` 两分支与已定案的两条处置路径逐一对上。→ `systems/services/_index.md` 或 `systems/architecture.md`。
4. **`Upgrade` 类错误在非闸门点的非阻塞处置**（本 handoff 第 8 节）——待发队列保留 + 暂停自动退避 + 非模态提示，以及它与「缓冲超限 → 软阻塞」的衔接。→ `systems/services/sync-service.md`。
5. **`HttpProfileBackend` 把 `ContentVersion` / `AppVersion` 搬到 HTTP 头**——客户端 record 定义不改，这是实现细节，但需在客户端文档中记明「报文字段名与客户端字段名不同」的这处具体对位。
