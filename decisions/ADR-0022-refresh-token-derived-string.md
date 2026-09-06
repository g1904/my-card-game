# ADR-0022 — refresh token 取 `<tokenId>.<mac>` 派生串：内部键不外泄、宽限回放靠重算

- **状态：** Accepted
- **日期：** 2026-09-03
- **来源：** `handoffs/2026-09-03-backend-stack-and-hosting.md` · `answer-logs/log-backend-stack-and-hosting.md`

## 背景

`ADR-0004` 要求 `refresh` 的 60 秒宽限窗口内**回放完全相同的那一对 token**，`ADR-0011` 要求凭 `sid` 精确吊销。落实现时最直觉的载荷形态是 `<sid>.<generation>.<mac>`——它把服务端内部键与轮换代次一起放上报文，而 `contracts/auth.md` 有两条相反的承重条款：「refresh token 是不透明随机串」「`sid` 不出现在任何报文字段里」。同时该形态分辨不了「会话被替换」与「凭据泄漏」这两种失败，而契约要求 `SessionSuperseded` 有确定取值、不能落进兜底文案。

## 决策

**refresh token 载荷 = `<tokenId>.<mac>`，其中 `mac = HMAC-SHA256(refreshSecret[kid], tokenId ‖ generation)` 截断编码；`tokenId` 与内部键 `sid` 分离，`generation` 不上报文。**

- **不缓存明文**：宽限回放靠 `generation - 1` **重算** mac，而不是把上一代活凭据存活 60 秒。
- 会话行加 **`prev_token_id` / `prev_generation`** 两列，用以分辨 `SessionSuperseded` 与 `TokenReuseDetected`。
- `refreshSecret` 的 `kid` 落 `refresh_key_id`，轮换时旧 secret 保留至最长 refresh 链自然到期。
- **`contracts/auth.md` 因此零改动**；求值顺序、校验流程与表结构 → `systems/account.md`。

## 理由

**服务端内部键一旦跨边界就成了契约的一部分**，而客户端对 `sid` 没有任何消费点。分出 `tokenId` 的代价只是会话行上多一列，换来的是 refresh 凭据可被独立轮换、且内部键不外泄（`systems/account.md`）。

派生串同时满足契约对 refresh token 的全部要求——不透明、高熵不可预测、必须查库才能吊销——**同时让「回放完全相同的那一对 token」不必缓存任何活凭据**。

`prev_*` 两列是必须补的缺口，不是可选加固：没有它们，「同设备重登被替换」与「旧凭据泄漏重放」在服务端不可分辨。

## 备选方案

- **`<sid>.<generation>.<mac>`（草稿原形态）** — 内部键与代次上报文，抵触两条承重契约条款；且分辨不了会话替换与凭据泄漏。
- **纯随机串 + Redis 缓存 60 秒明文以支持回放** — 可行且更简单，但让活凭据明文在缓存里存活 60 秒；且 Redis 失效会把弱网重试的玩家赶回验证码输入框，**正是 `ADR-0004` 要消除的那一幕**。保留为明写备选。

## 后果

- 会话行多 `token_id` / `generation` / `refresh_key_id` / `prev_token_id` / `prev_generation` 五列；refresh 凭据可独立于 `sid` 轮换。
- 放弃**无状态自校验**的 refresh 串——服务端仍要读会话行判定吊销态与到期（这本就是契约要求）。
- **`contracts/auth.md` 报文面一字未改**，客户端零义务：这既是本决策的约束，也是它一半的价值。
- `SessionSuperseded` / `TokenReuseDetected` 的取值自此在服务端可确定判出 → `contracts/auth.md` §10 的 `session_revoked` 取值表不再依赖兜底。
- `refreshSecret` 的保管形态从属 `ADR-0023`。
