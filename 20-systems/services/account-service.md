# account-service（服务）

> 账号与鉴权服务：登录渠道、token / 会话、合规。**判据 ③ —— 坐在外部 I/O 边界（平台 SDK + 后端）上。**
> Source: `10-handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md`。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **服务定位。** 本服务是**平台 SDK 与后端鉴权的唯一门面**。它把「登录成功、得到 `accountId` 与 token」这件事收敛为一个可被 mock 的边界——其余服务不接触任何渠道 SDK。强制在线下它是所有流程的前置：登录未成功则不进入主界面。
- **强制在线 · 无游客态。** 游客态已彻底移除，必须账号登录（`00-vision/scope.md`、`40-ux/onboarding.md`）。登录渠道优先级：**移动端手机 / 邮箱 → 微信 / QQ → 海外 / 跨平台**。Source: `50-decisions/ADR-0003-online-cloud-authority.md`。
- **重账号路线。** 参考三国杀 Online 的重账号模型；账号是云端权威 PlayerProfile 的键。
- **token 失效与被挤下线的处置（已定案）。** 二者**分开处理**：
  - **token 到期 / 刷新失败** → `RefreshToken()` 静默刷新；**刷新失败视同断线**，走 `sync-service` 的**同一条缓冲通道**（待发队列 + 指数退避 + 缓冲上限 → 软阻塞），**不另开一套降级路径**。进行中的轮回**不被打断、不回退存档点**。
  - **被后端明确挤下线**（多设备并发） → **硬阻塞**，要求重新登录；重登后同样**先 pull 后 flush**——若云端 `revision` 已领先，以云端为准丢弃本地缓冲，并明确告知玩家「另一设备的进度已生效」。
  - 断线降级的完整表与缓冲阈值见 `sync-service.md`。Source: `10-handoffs/2026-07-27-content-gating-offline-resilience-and-rng-persistence.md`。

## 管理器

| manager | 职责 |
|---------|------|
| **AuthManager** | 渠道登录、token 获取 / 刷新 / 失效处理、会话保持；产出 `accountId` |
| **ComplianceManager** | 实名认证、防沉迷时长校验、账号注销 / 数据导出的客户端侧流程 |

## API 面（契约）

> 总则与共享类型见 `20-systems/architecture.md`「API 契约总则」。本服务实现 `IBootstrappable`（启动链第二步，`LoginScreen` 之后）。Source: `10-handoffs/2026-07-27b-service-api-contracts.md`。

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

**失败映射：** 网络不通 → `OpError.Network`；渠道拒绝 / token 失效 → `OpError.Auth`；实名 / 防沉迷拦截 → `OpError.Compliance`（`Detail` 携带面向玩家的原因串，文案由 UI 层决定）。

**后端接口（总则 7）：** 本服务持有 `IAccountBackend`，两份实现 `HttpAccountBackend` / `OfflineAccountBackend`，由 `[Export] bool UseOfflineBackend`（默认 `true`）选择。

**事件面：** `SessionChanged(bool SignedIn, OpError Reason)` 经 EventBus 广播（登录成功 / 失败、token 失效、合规拦截共用此负载）。

## 与其他服务的关系

- **下游：** `sync-service` 用它产出的 `accountId` 拉取 PlayerProfile；`content-service` 用它的 token 请求内容版本；`future-event-service.PlotManager` 用它的 token 请求云端剧本。
- **不做的事：** 不碰 PlayerProfile 的字段（那是 profile-service 的写入面），不做存档同步（那是 sync-service）。

## 决策(-> ADR)

- **强制在线 · 云端权威 · 重账号 · 无游客态** → `50-decisions/ADR-0003-online-cloud-authority.md`（Accepted）。

## 待决问题

- **ComplianceManager 的客户端侧覆盖面。** 实名 / 防沉迷 / 注销 / 数据导出中，哪些环节由客户端呈现与拦截、哪些纯后端裁决，切分未定。→ `50-decisions/ADR-0003`。后端 / 账号系统的具体选型与合规实现归**后端库**：`backend-design-documents/open-questions.md`。
- **多设备并发登录的云端裁决规则。** 后登录挤下线？拒绝？归**后端库**。客户端侧的表现已定（被挤下线 → 硬阻塞重登 → 先 pull 后 flush，见「意图」），仅剩裁决策略本身待后端定。

## 对应
提炼至：`.claude/knowledge/systems/account-service.md`（引用层，待建）。
