# account-service（服务）

> 账号与鉴权服务：登录渠道、token / 会话、合规。**判据 ③ —— 坐在外部 I/O 边界（平台 SDK + 后端）上。**

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **服务定位。** 本服务是**平台 SDK 与后端鉴权的唯一门面**。它把「登录成功、得到 `accountId` 与 token」这件事收敛为一个可被 mock 的边界——其余服务不接触任何渠道 SDK。强制在线下它是所有流程的前置：登录未成功则不进入主界面。
- **强制在线 · 无游客态。** 游客态已彻底移除，必须账号登录（`vision/scope.md`、`ux/onboarding.md`）。登录渠道优先级：**移动端手机 / 邮箱 → 微信 / QQ → 海外 / 跨平台**。Source: `decisions/ADR-0003-online-cloud-authority.md`。
- **重账号路线。** 参考三国杀 Online 的重账号模型；账号是云端权威 PlayerProfile 的键。
- **token 失效与被挤下线的处置。** 二者**分开处理**：
  - **token 到期 / 刷新失败** → `RefreshToken()` 静默刷新；**刷新失败视同断线**，走 `sync-service` 的**同一条缓冲通道**（待发队列 + 指数退避 + 缓冲上限 → 软阻塞），**不另开一套降级路径**。进行中的轮回**不被打断、不回退存档点**。
  - **被后端明确挤下线**（多设备并发） → **硬阻塞**，要求重新登录；重登后同样**先 pull 后 flush**——若云端 `revision` 已领先，以云端为准丢弃本地缓冲，并明确告知玩家「另一设备的进度已生效」。**这一段不需要额外规则**：重登后的 pull 带回新的 `cloudRevision` 并覆写本地同步信封，随后的 flush 自然走 CAS 三分支判定（见 `sync-service.md`「`revision` 语义与幂等键」）。若重登的是**另一个账号**，信封 `accountId` 不匹配 → 丢弃信封与待发队列（必需缺失，`PushError`）。
  - **两条处置各自对上一个后端 `code`：** `auth.token_expired` / `auth.token_invalid` → 静默刷新那条；`auth.session_revoked` → 硬阻塞重登那条。**它们必须是两个 `code`**——若后端只给一个「401 未授权」，客户端无从区分，只能二选一，选错哪边都直接违反上面一条已定案语义。客户端因此**不得靠 HTTP 状态码分支**，一律以 `code` 为键查映射表（见 `systems/architecture.md` 总则 7 下「后端错误码 → `OpError`」）。
  - 断线降级的完整表与缓冲阈值见 `sync-service.md`。

Source: `handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md` · `handoffs/2026-07-27-content-gating-offline-resilience-and-rng-persistence.md` · `handoffs/2026-08-11b-contract-boundary-and-flags-client-side.md` · `decisions/ADR-0003-online-cloud-authority.md`

## 管理器

| manager | 职责 |
|---------|------|
| **AuthManager** | 渠道登录、token 获取 / 刷新 / 失效处理、会话保持；产出 `accountId` |
| **ComplianceManager** | 实名认证、防沉迷时长校验、账号注销 / 数据导出的客户端侧流程 |

## API 面（契约）

> 总则与共享类型见 `systems/architecture.md`「API 契约总则」。本服务实现 `IBootstrappable`（启动链第二步，`LoginScreen` 之后）。

| 方法 | 形态 | 完整签名 | 失败语义 |
|------|------|----------|----------|
| 登录 | B | `Task<OpResult<Session>> SignInAsync(LoginChannel channel, CancellationToken ct)` | 业务失败 → `OpResult` |
| 登出 | B | `Task<OpResult> SignOutAsync(CancellationToken ct)` | 同上 |
| 刷新 | B | `Task<OpResult<Session>> RefreshTokenAsync(CancellationToken ct)` | 失败**视同断线**，交 sync-service 缓冲通道；不立即要求重登、不回退存档点 |
| 取会话 | A | `bool TryGetSession(out Session session)` | **可选缺失**——未登录是登录屏的正常态，不是错误 |

```csharp
public readonly record struct Session(string AccountId, string Token, DateTime ExpiresAtUtc);
public enum LoginChannel { Phone, Email, WeChat, QQ }   // 优先级序见 ADR-0003；无 Guest
```

**失败映射：** 网络不通 → `OpError.Network`；渠道拒绝 / token 失效 → `OpError.Auth`；实名 / 防沉迷拦截 → `OpError.Compliance`。

> **`Detail` 是诊断串，不是玩家文案。** 合规拦截的具体原因（实名未完成 / 时长受限 / 账号受限）**按 `code` 走 UI 层的 `ErrorText`**，与其他错误一致——合规文案恰是最需要精确措辞、也最需要按渠道调整的一类，正是「按 `code` 分辨」的典型受益者。语义见 `systems/architecture.md` 总则 7，呈现见 `ux/error-and-blocking-ux.md`。

**后端接口（总则 7）：** 本服务持有 `IAccountBackend`，两份实现 `HttpAccountBackend` / `OfflineAccountBackend`，经**唯一选择点 `BackendSelector.CreateAccount()`** 取得；离线实现整类包在 `#if DEBUG` 内，Release 构建里根本不存在（形态见 `system-overview.md` 第四节）。

**事件面：** `SessionChanged(bool SignedIn, OpError Reason)` 经 EventBus 广播（登录成功 / 失败、token 失效、合规拦截共用此负载）。

Source: `handoffs/2026-07-27b-service-api-contracts.md` · `handoffs/2026-08-12-error-copy-and-update-prompts.md`

## 与其他服务的关系

- **下游：** `sync-service` 用它产出的 `accountId` 拉取 PlayerProfile；`content-service` 用它的 token 请求 flags（**登录之后**的启动链一步）。剧本内容属本地内容层，不经本服务取 token。
- **不做的事：** 不碰 PlayerProfile 的字段（那是 profile-service 的写入面），不做存档同步（那是 sync-service）。

## 决策(-> ADR)

- **强制在线 · 云端权威 · 重账号 · 无游客态** → `decisions/ADR-0003-online-cloud-authority.md`（Accepted）。

## 待决问题

- **ComplianceManager 的客户端侧覆盖面。** 实名 / 防沉迷 / 注销 / 数据导出中，哪些环节由客户端呈现与拦截、哪些纯后端裁决，切分未定。→ `decisions/ADR-0003`。后端 / 账号系统的具体选型与合规实现归**后端库**：`backend-design-documents/open-questions.md`。
- **多设备并发登录的云端裁决规则。** 后登录挤下线？拒绝？归**后端库**。客户端侧的表现已定（被挤下线 → 硬阻塞重登 → 先 pull 后 flush，见「意图」），仅剩裁决策略本身待后端定。

## 对应
提炼至：`.claude/knowledge/systems/account-service.md`（引用层，待建）。
