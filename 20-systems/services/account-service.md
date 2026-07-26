# account-service（服务）

> 账号与鉴权服务：登录渠道、token / 会话、合规。**判据 ③ —— 坐在外部 I/O 边界（平台 SDK + 后端）上。**
> Source: `10-handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md`。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **服务定位。** 本服务是**平台 SDK 与后端鉴权的唯一门面**。它把「登录成功、得到 `accountId` 与 token」这件事收敛为一个可被 mock 的边界——其余服务不接触任何渠道 SDK。强制在线下它是所有流程的前置：登录未成功则不进入主界面。
- **强制在线 · 无游客态。** 游客态已彻底移除，必须账号登录（`00-vision/scope.md`、`40-ux/onboarding.md`）。登录渠道优先级：**移动端手机 / 邮箱 → 微信 / QQ → 海外 / 跨平台**。Source: `50-decisions/ADR-0003-online-cloud-authority.md`。
- **重账号路线。** 参考三国杀 Online 的重账号模型；账号是云端权威 PlayerProfile 的键。

## 管理器

| manager | 职责 |
|---------|------|
| **AuthManager** | 渠道登录、token 获取 / 刷新 / 失效处理、会话保持；产出 `accountId` |
| **ComplianceManager** | 实名认证、防沉迷时长校验、账号注销 / 数据导出的客户端侧流程 |

## API 面（意图草图 · 签名待定）

- `SignIn(channel)` → 走渠道 SDK 与后端换取 token，产出 `accountId`；失败带明确原因（网络 / 渠道拒绝 / 合规拦截）。
- `SignOut()` → 清会话与本地缓存中的凭据。
- `RefreshToken()` → token 到期前静默刷新；失败则降级为要求重新登录。
- `GetSession()` → 当前 `accountId` / token，供 sync-service 与 content-service 携带。
- **事件面：** 登录成功 / 失败、token 失效、被合规拦截（防沉迷时长到达）等经 EventBus 广播。

## 与其他服务的关系

- **下游：** `sync-service` 用它产出的 `accountId` 拉取 PlayerProfile；`content-service` 用它的 token 请求内容版本；`future-event-service.PlotManager` 用它的 token 请求云端剧本。
- **不做的事：** 不碰 PlayerProfile 的字段（那是 profile-service 的写入面），不做存档同步（那是 sync-service）。

## 决策(-> ADR)

- **强制在线 · 云端权威 · 重账号 · 无游客态** → `50-decisions/ADR-0003-online-cloud-authority.md`（Accepted）。

## 待决问题

- **ComplianceManager 的客户端侧覆盖面。** 实名 / 防沉迷 / 注销 / 数据导出中，哪些环节由客户端呈现与拦截、哪些纯后端裁决，切分未定。→ `50-decisions/ADR-0003`。后端 / 账号系统的具体选型与合规实现归**后端库**：`backend-design-documents/open-questions.md`。
- **token 失效时正在进行的 run 如何处理。** 阻塞玩家、允许在本地继续并缓冲上行、还是回退到上一个存档点？与 sync-service 的断线降级策略耦合。→ `20-systems/services/sync-service.md`。
- **多设备并发登录的客户端表现。** 云端如何裁决（后登录挤下线？拒绝？）归后端库；客户端在被挤下线时的提示与流程回退未定。

## 对应
提炼至：`.claude/knowledge/systems/account-service.md`（引用层，待建）。
