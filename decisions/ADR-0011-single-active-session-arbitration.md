# ADR-0011 — 单账号一条活跃会话：后登录挤下线 + `sid` 精确吊销 + `signin` 回放窗口

- **状态：** Accepted
- **日期：** 2026-08-16
- **来源：** `handoffs/2026-08-16c-compliance-contract-and-session-arbitration.md` · `answer-logs/log-compliance-and-session-arbitration.md`

## 背景

`contracts/auth.md` 有三处悬空：`signout` 声称「吊销当前会话」，而 access token 只带 `accountId` 时服务端根本没有「当前会话」这个概念——只能退化为吊销全部会话，把另一台设备一并踢下线；§7 要求「`signin` 重试必须能被安全重放」却没给机制，而一次性验证码天然反幂等；三处 `reasonKey` 取值留白无人认领。同时合规能力（实名 / 防沉迷 / 注销 / 导出）无任何落点，且被拦住的玩家手里没有 access token，形成死锁。

## 决策

**单账号任一时刻只有 1 条活跃会话，裁决取「后登录挤下线」。**

- access token 的 JWT claims 含 **`sid`**（服务端生成、随机不可枚举、**不出现在任何报文字段里**），`POST /v1/auth/signout` 据此精确吊销一条。
- 会话表以 **`(accountId, deviceId)` 为唯一键**；**上限 1 与该唯一约束是两条独立约束，都要留**。同一 `deviceId` 重登 = 原地替换、旧 refresh token 立即失效、旧记录标 `SessionSuperseded`；吊销其余会话与写入本设备会话**同一事务内**完成。
- `signin` 幂等 = **60 秒回放窗口**：同 `(channel, 凭据标识符, deviceId)` 原样回放上次 token 对，**不签发、不吊销**（与 §4 refresh 宽限窗口同值同理由，见 `ADR-0004`）。
- `deviceId` 只做裁决与观测输入，**永不参与鉴权**。
- **合规拦截只在 `POST /v1/auth/signin` 应答中出现**，业务端点一律不返回；建号先于合规判定，拦截不回滚建号。合规域独立成第六份契约 `contracts/compliance.md`（六端点、`complianceTicket` 一次性 / 10 分钟 / 单端点 / 不进 `Authorization`、四条 `compliance.*` 码）。

会话记录表、求值顺序、拦截落地点与端点报文 → `contracts/auth.md` §4a §5a §7 §8 §10、`contracts/compliance.md`。

## 理由

裁决策略**不是一个独立取向**：`contracts/auth.md` §4a 明写「§2 那段『窗口内旧设备的 push 由 `revision` CAS 拒绝』的论证**只有在这一裁决下才成立**」——另两个选项不会产生「旧设备在窗口内继续 push」这一情形。

上限取 1 而非 2+LRU：客户端全部既定语义建立在「同时只有一个活跃写入方」之上，放宽会让 `sync.conflict`（既定处置 = 丢弃本地缓冲）从异常路径变成常态。

两条约束都留：只有唯一约束时同设备历史记录以 `revoked` 态堆积；只有上限 1 时同设备重登先建后删，留下可观测的假「挤下线」。

回放窗口与替换必须一起成立——只取替换、不取回放窗口，弱网重试的玩家会在登录成功后被赶回验证码输入框。

拦截落点是推演唯一解（§5a）：`/v1/profile/*` 被 `contracts/profile-sync.md` §11 封死，业务端点撞 `contracts/envelope.md` §7b 与 `vision/pillars.md` 第四条，启动 pull 本身即 `/v1/profile/pull` 同样出局。合规域独立成文按 `contracts/_index.md` 分域判据：合规域与 auth 域有两条相反的承重纪律（长时状态机 / 异步任务 vs 即时判定；不可逆 vs 幂等可重放）。

## 备选方案

- **会话上限 2 + 按 `issuedAtUtc` 挤出最旧者** — `sync.conflict` 由异常变常态，「在 A 设备打完的一场战斗被 B 设备抹掉」成为日常；单人游戏无双设备并推需求。
- **同设备重登时旧会话并存到自然过期** — 同账号同设备最长两对有效 token，与 rotation 纪律反向，「活跃会话数」不再可用于风控；它唯一的理由（保 `signin` 幂等）已被 60 秒回放窗口更干净地满足。
- **靠「同 `deviceId` 不吊销」单独承担 `signin` 幂等** — 只堵住一半：一次性凭据已被消费，重试仍撞 `auth.challenge_expired`。
- **`signout` 吊销全部会话以回避 `sid`** — 凭空造出一次硬阻塞。
- **以 access token 原始串作会话键 / `sid` 作报文字段下行 / 以 access token 为吊销粒度（黑名单）** — 随 rotation 变化且逼服务端存明文 / 内部键跨边界且客户端无消费点 / 抵消自包含 JWT 离线验签的全部收益。
- **`deviceId` 参与鉴权（设备绑定）** — 客户端自报可伪造，是假安全，真实后果是换机重装的玩家被挡在门外。
- **服务端主动推送「你被挤下线了」/ 设备列表与远程踢出 UI** — 需长连接，在 `vision/scope.md` 边界外 / 无客户端消费面且要新增整套端点。
- **合规拦截落在业务端点或 `/v1/profile/*`** — 见理由段。
- **为防沉迷新增会话中途拦截通道（`refresh` 加第三个 `code` 或心跳端点）** — 破坏 §8 刻意收紧的两码互斥；心跳失败与断线不可区分。
- **实名作为建号前置** — 造出「半个账号」，拆开 §1a 的原子建号。
- **`signin` 签发 scope 受限 token** — 为一个域引入整套 scope 授权维度，而双 token 私有模型刻意没有它。
- **注销 / 导出扩进 auth 域成第八九端点 / 走站外** — 两套相反纪律塞进一份文档 / 应用商店审核查「App 内可注销」。
- **`restricted` 与 `banned` 各给一个 `code`** — 玩家处置相同，只让处置表多一行走同一路径。

## 后果

- `signout` 必须能精确定位单条会话 ⇒ **`sid` 是 token claims 的必需项**；「吊销其余会话」与「写入本设备会话」必须同事务——半吊销态会让玩家被踢却仍能刷新。
- `refresh` 错误清单保持两条、不得扩张（后续 `SessionExpired` 亦复用 `auth.session_revoked`，未破此约）。
- **存档 schema 零影响、无迁移**：合规态、会话、`sid`、`deviceId` 均不进 `PlayerProfile`。
- 放弃多端同时在线；放弃为防沉迷开会话中途通道；`contracts/compliance.md` **六端点的报文字段表与其自身错误码本次不落笔**，推迟到一次正式契约变更——它至今仍是本库唯一向对侧传导的欠账（→ `open-questions.md`「最短解锁路径」第 1 条）。
- `contracts/envelope.md` §3 端点清单扩容、§6 台账新增四条；§4a 无鉴权例外由枚举改判据那一条属 `ADR-0016`，本 ADR 不复述。
- `reasonKey` 的形态与文案映射纪律属 `ADR-0015`；`signin` 60 秒回放窗口与 refresh 宽限窗口同源，论证权威在 `ADR-0004`。
- 客户端侧对位（`ComplianceManager` 覆盖面切分、`deviceId` 跨启动稳定且安装实例间不碰撞、三处 `reasonKey` 的玩家可见措辞）权威在 `game-design-documents/systems/services/account-service.md` 与 `game-design-documents/ux/error-and-blocking-ux.md`；承接登记见 `game-design-documents/open-questions/cross-boundary.md`。
- 可信服务端时钟、`complianceTicket` 存储与一次性消费、冷静期长时状态机、导出产物与链接签发的实现形态全部待 `open-questions/06-platform-stack.md`。
