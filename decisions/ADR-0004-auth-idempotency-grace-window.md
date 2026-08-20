# ADR-0004 — auth 域的幂等与 sync 域的幂等是同一条纪律

- **状态：** Accepted
- **日期：** 2026-08-13
- **来源：** `handoffs/2026-08-13-auth-endpoint-contract.md` · `answer-logs/log-auth-endpoint-contract.md`

## 背景

refresh token rotation 是标准做法：每次刷新返回新 token、旧的立即失效，已用过的旧 token 再次到达即判泄漏并吊销全账号会话。但「请求已达、应答丢失」在移动网络下是常态——裸 rotation 下，客户端持旧 token 重试就会被判重放，玩家在轮回中途被硬踢下线。同样的形状出现在 `signin`：一次性凭据（验证码 / 第三方 `authCode`）天然反幂等，首次请求即被消费，重试撞 `auth.challenge_expired`，而玩家其实刚刚已经登录成功。

## 决策

**auth 域的幂等按与 sync 域相同的模式兑现：重复到达不再推进状态，直接回上次结果。**

- `POST /v1/auth/refresh` 采用 rotation，**并带 60 秒宽限窗口**：窗口内旧 refresh token 回放**与上次相同的那一对新 token**，不再轮换、不判泄漏；**窗口外**再次出现才判泄漏并吊销该账号全部会话。
- `POST /v1/auth/signin` 带 **60 秒幂等回放窗口**（同值同理由）。
- **七个 auth 端点全部幂等**；同一 `deviceId` 重登 = 原地替换，旧 refresh token 立即失效。
- 报文、旋钮初值、`auth.session_revoked.detail.reasonKey` 七值 → `contracts/auth.md` §4 §4a §7 §8 §10。

## 理由

这与 `pushId` 的「重复到达不再 `+1`，直接回上次结果」是**同一个模式、理由同源**：pillar #2「弱网优先：幂等重于优雅」。两者不是两套机制，而是同一条支柱在两个域上的兑现——`signin` 的回放窗口是它的第三次。→ `contracts/auth.md` §4 §4a、`contracts/profile-sync.md` §9。

窗口取 60 秒的推导：需覆盖客户端指数退避的头几次重试，而它远短于 refresh token TTL，泄漏风险面可忽略。

## 备选方案

- **裸 rotation（无宽限窗口）** — 把一次弱网变成一次全账号吊销 + 轮回中途硬踢下线，与 pillar #2 直接冲突。
- **不做 rotation** — 泄漏的 refresh token 在整个 TTL 内长期有效，而它的 TTL 恰是最长的那个。
- **靠「同 `deviceId` 不吊销」单独承担 `signin` 的幂等** — 只堵住一半：一次性凭据已被消费，重试仍会撞 `auth.challenge_expired`。
- **同设备重登时旧会话并存到自然过期** — 同账号同设备最长 30 天存在两对有效 token，且使「活跃会话数」不再可用于风控。

## 后果

- 服务端必须为 refresh 保留「上一次轮换结果」与为 `signin` 保留幂等回放记录；两者的存储与保留期归 `06-platform-stack.md`（可与 `(accountId, pushId)` 幂等记录同处）。
- 「rotation 是标准做法，为什么要开宽限口子」不再是开放问题——重新提出它等于要求推翻 pillar #2 在本域的兑现。
- `POST /v1/auth/refresh` 的错误清单**只有两条**（`auth.session_revoked` · `server.unavailable`），使「刷新失败按有无明确应答分两条路径」这个客户端判据在报文层面无歧义 → `contracts/envelope.md` §6。
- `TokenReuseDetected` 作为 `auth.session_revoked` 的 `reasonKey` 之一登记在 `contracts/auth.md` §10，玩家可见措辞归客户端（`game-design-documents/ux/error-and-blocking-ux.md`）。
