# Answer log contract-expression-envelope-and-error-codes

- 日期：2026-08-11
- 来源：`inbox/archive/solution-draft-contract-expression-envelope-and-error-codes.md` → `handoffs/2026-08-11-contract-expression-envelope-and-error-codes.md`
- 移出条数：6（`open-questions/01-contracts.md` 的四条边界层条目 + `contracts/content-manifest.md` 推给本层的两项欠账）

---

**契约的事实来源尚未成文（端点 / DTO / 错误码 / 存档 schema 版本与迁移路径全部未定）**
→ 边界层一次立齐为 `contracts/envelope.md`：序列化与命名约定（lowerCamelCase · 枚举值与客户端 C# 枚举名逐字相同 · 两侧必须忽略未知字段 · RFC 3339 UTC 带 `Z` · `revision` 以 JSON number 传输 · 不下发 `null`）、`/v1/` 主版本前缀（`contentRoot` 下的静态对象不带）、传输信封与负载信封、错误体与台账、版本协商。**端点报文本体（`auth.md` / `profile-sync.md` / `plot.md`）不在本次范围**，仍留在 `01` 分片。存档 schema 的归属一并答结：见下面第 4 条。
（归档去向：`contracts/envelope.md` §1–4 · `contracts/_index.md` §现状）

**契约的表达形式（OpenAPI + JSON Schema vs 共享 DTO 代码）**
→ **OpenAPI 3.1 + JSON Schema 单点，明确否决共享 DTO 代码——即使后端最终也选 C#。** 依据在根约定而非技术栈选型：共享 DTO 需要一个被两条独立分支线同时引用的编译期依赖，它要么住在某一条分支里（当场违反「后端不得被编译进游戏程序集」），要么需要第三个发布物，其版本节奏要同时迁就 Godot 4.7 的 .NET 目标框架与后端运行时。**推论：`01` 从 `06-platform-stack.md` 的下游摘出**，两者可并行推进；`content-manifest.md` 的字段名就地转正。markdown ↔ spec 分工：markdown 承载语义、spec 承载字段形态，冲突时各以己方为准。`openapi.yaml` 不预先建空壳，首个端点进入实现时同时落地。
（归档去向：`contracts/envelope.md` §1 · `decisions/_index.md` ADR 候选③ · `open-questions/06-platform-stack.md` 解耦）

**错误码体系与客户端 `OpError` 的映射**
→ 错误体统一为 **`code` · `class` · `message` · `detail` · `requestId`**（前四项与 `requestId` 必填，`detail` 可选）。`class` 四值 `Retryable` / `Fatal` / `Reauth` / `Upgrade`（用户裁决 K3；布尔 `retryable` 表达不了「需重登」与「需强更」）。`message` 为**面向开发者的英文调试串**、必填、须写到能定位问题、不得落敏感值、不得被客户端解析做分支、不直接展示给玩家（用户追加要求）。三条承重纪律：**客户端不得靠 HTTP 状态码分支**；未知 `code` → 按 `class` 降级，未知 `class` → 当作 `Fatal` 并上报一次，无法解析的应答体（网关 / 非 JSON）→ 降级为 `server.unavailable`；**`class` 是契约的一部分**，同一 `code` 不得因请求而变。首批 15 条 `code` 的台账（含 `detail` 形状与 `message` 必含关键值）已立。**`auth.token_expired` 与 `auth.session_revoked` 必须是两个 `code`**（客户端两条处置完全不同）；**限流是 `Retryable` 而非 `Conflict`**；**`Cancelled` / `Migration` 不得有任何后端 `code` 映射**。
（归档去向：`contracts/envelope.md` §5–6 · `operations/_index.md` §错误码台账登记流程）

**版本协商与强制更新（软提示 / 硬闸门、兼容矩阵由谁维护）**
→ **判定权在服务端**（不下发阈值让老客户端自己比——semver 字典序坑已有前车之鉴），以 `client.version_unsupported`（`class: Upgrade`）拒绝；`X-Min-App-Version` 仅信息性，`X-Recommended-App-Version` 为软提示且永不阻塞。**闸门只在登录与启动 pull 生效**（本就是已定案的仅有两处硬阻塞），且**在签发 token 时判定一次**、会话期内不变严——运营提升下界永远不会打断进行中的轮回。**兼容矩阵由后端单点维护**（落 `operations/`），客户端不持有副本。**同时答结存档 schema 版本在契约中的承载**：`schemaVersion` 是上行负载的版本，其结构权威与迁移路径都在客户端，契约不复述 Profile 字段表；后端对 Profile **半透明**（负载信封透明 / 后端可见字段子集透明 / 其余不透明按原样存回），只在 `schemaVersion` 越出兼容集合时拒绝。
（归档去向：`contracts/envelope.md` §7–8 · `operations/_index.md` §版本兼容矩阵）

**欠账①：信封须携带 `flagsVersion`（来自 `content-manifest.md`）**
→ 落为**应答头 `X-Flags-Version`**，随任意应答下发。**必须在头上而非 body**：body 字段覆盖不到 `204`、错误应答与非 JSON 应答，而 flags 秒关正是靠搭任意一次应答的车压到分钟级；且网关 / 日志层不解 JSON 即可读，GET 端点也无 body 可用。
（归档去向：`contracts/envelope.md` §4b · `contracts/content-manifest.md` §flags 通道回改）

**欠账②：`minAppVersion` 与强更闸门的分工（来自 `content-manifest.md`）**
→ **互不兼职**：`minAppVersion`（manifest 内）是**内容维度**，由客户端自行比对，效果只是跳过本次 overlay、照常用基线，**永不阻塞、永不强更**；`X-Min-App-Version` / `client.version_unsupported` 是**协议维度**，由服务端判定，在登录 / 启动点硬阻塞。内容太新只是不更新内容；协议不兼容才拦人。
（归档去向：`contracts/envelope.md` §7d · `contracts/content-manifest.md` §版本化）

---

## 同批裁决的两项（interview，非清单条目）

- **`baseRevision` / `pushId` 的落位** → 留在 `POST /v1/profile/push` 的 **body 负载信封段**，不搬 HTTP 头、不用 `If-Match` / ETag。「信封」一词拆为**传输信封（HTTP 头）**与**负载信封（body 段）**两个名字。（`contracts/envelope.md` §4）
- **`Upgrade` 类错误在非闸门点的处置** → 推出通用纪律「**`Upgrade` 类错误只在登录 / 启动 pull 构成硬阻塞**」。`sync.payload_schema_unsupported` 在轮回中途的 push 上返回时：本地缓冲**保留不丢弃**、非模态升级提示、**暂停自动退避重试**、恢复点是更新后重新登录先 pull 后 flush。（`contracts/envelope.md` §7c）

## 跨边界

本次裁决同时改动客户端语义，**客户端侧需另写一份 handoff**（本库不代为决定）：`Retry-After` 的尊重 · `X-Flags-Version` 的读取点 · 错误码 → `OpError` 映射表的落点与形态（建议为数据表）· `Upgrade` 类错误的非阻塞处置与「缓冲超限 → 软阻塞」的衔接 · `HttpProfileBackend` 把 `ContentVersion` / `AppVersion` 搬到 HTTP 头。详见 `handoffs/2026-08-11-contract-expression-envelope-and-error-codes.md` 的「客户端侧影响」段。
