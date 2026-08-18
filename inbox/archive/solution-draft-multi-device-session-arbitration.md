---
type: solution-draft
date: 2026-08-16
decided: 2026-08-16（用户裁定三项：会话上限 1 台 · 同设备重登替换 · `reasonKey` 用 PascalCase）
question: 多设备并发裁决的落地细节：会话的存储键与吊销粒度、`signin` 的幂等如何真正成立、以及同设备重登时旧会话怎么办
source: open-questions/02-account-compliance.md → 「多设备并发登录的裁决语义」
relates-to: inbox/solution-draft-compliance-codes-and-reason-keys.md（同期在办 · 共享部分以它为准，但其两处 `reasonKey` 表须按本稿裁定改形，见文末）
targets: contracts/auth.md（§2 token 表补 `sid` claim · 新增「§4a 会话裁决」· §7 幂等表补一行 · §8 旋钮表补两行 · §10 取值表追加 `SessionSuperseded`） · open-questions/06-platform-stack.md（承接会话存储与吊销的实现层）
status: distilled
reviewed: 2026-08-16（用户裁定三项：会话上限 1 台 · 同设备重登替换 · `reasonKey` 用 PascalCase）
distilled-to: `handoffs/2026-08-16c-compliance-contract-and-session-arbitration.md`（与 `solution-draft-compliance-codes-and-reason-keys.md` 同批提炼）
---

# 方案草稿 — 多设备会话裁决的落地细节（补强稿 · 已裁定）

## ⚠ 先读：本草稿与在办草稿的关系

本次运行开始时，`inbox/` 中已有一份同期在办的草稿 **`solution-draft-compliance-codes-and-reason-keys.md`**，它的「建议 5」与「具体形态 B」已经覆盖了本问题的两个主干：

- **裁决策略** = 后登录挤下线（并给出了一条更强的论证：`auth.md` §2 的整段推理只在这一裁决下成立，故它是**已被 §2 隐含定案**，而非仍待裁决）；
- **`auth.session_revoked.detail.reasonKey` 的取值表**。

**取值表的落笔归那份，本草稿不复述、不另立一版**——两份并存的取值表就是两个权威，正是本库反复要避免的形态。

但本稿裁定的三项**反向修改了那份的两处形态**（大小写 · 同设备重登的处置 · 需追加一个取值）。**必须改的三处逐条列在文末「对在办另一份草稿的必需改动」**，两份须一起提炼，不得只提炼其中一份。

## 问题

裁决策略定了「后登录挤下线」之后，仍有四件事没有答案，且每一件都会在实现时被迫临时决定：

1. `signout` 要吊销「当前会话」——但请求里没有任何字段能标识是哪一条会话。
2. 「一台设备一条会话」是靠什么保证的？会话记录的键是什么？
3. `auth.md` §7 要求 `signin` 幂等，但**一次性验证码天然反幂等**：请求已达、应答丢失，客户端拿同一个 `code` 重试必然失败。「同 `deviceId` 不吊销既有会话」只解决了这个问题的一半。
4. 单账号允许几条活跃会话——严格 1 条，还是手机 + 平板各一？

## 已裁定（2026-08-16，用户）

| # | 议题 | 裁定 |
|---|---|---|
| ① | 单账号活跃会话上限 | **1 台**。严格单活跃会话，不做「上限 2 + LRU 挤出」 |
| ② | 同一 `deviceId` 重新登录时的旧会话 | **替换**（旧 refresh token 立即失效），不并存到自然过期。幂等改由建议 3 的 60 秒回放窗口承担 |
| ③ | `reasonKey` 的取值形态 | **PascalCase**（`SignedInElsewhere` 等），与契约面全部可枚举取值一致。**选定后锁死** |

其余各项按本稿原推荐定案。三项的完整论证与被否决的另一侧见「备选方案」。

## 约束（来自既有设计）

- **客户端表现已定案，本条不得改动**：被明确挤下线 → 硬阻塞重登 → 先 pull 后 flush（`game-design-documents/systems/services/account-service.md`「意图」）。本库只定后端何时挤、挤谁。
- **access token 自包含、网关离线验签；吊销的最坏生效延迟 = access token TTL（15 分钟）**，窗口内旧设备的 push 由 `revision` CAS 兜住（`auth.md` §2）。**「吊销不是实时的」已写进契约**，本方案沿用、不扩大。
- **不给 profile push 这条最热路径加中心校验读**（`auth.md` §2）。
- **七个 auth 端点必须幂等**（`auth.md` §7）；弱网下「请求已达、应答丢失」是常态（pillar #2）。
- **refresh token 走 rotation，旧的立即失效，宽限窗口 60 秒**（`auth.md` §4）。
- **服务端内部键不跨边界**（`channelUserId` / `idKind` / `status` 三条先例，`auth.md` §1a）。
- **硬阻塞只有两处**，不得新增第三处（`game-design-documents/systems/architecture.md` 总则 7）。
- **枚举值取字符串，契约面现存全部可枚举取值为 PascalCase**（`envelope.md` §2；`"Phone"` · `"SignIn"` · `"Rebind"` · `"Conflict"`）。

## 方案

### 1. access token 必须携带会话标识 `sid`

`[既有推演]`——这是一条**必要性**，不是取向。

`POST /v1/auth/signout` 需鉴权、**无 body**，语义是「吊销当前会话」（`auth.md` §8）。请求里唯一的身份材料是 access token；若它只带 `accountId`，服务端无从知道「当前会话」是哪一条，`signout` 只能退化为「吊销该账号全部会话」——那会把另一台设备一并踢下线，凭空造出一次硬阻塞。

**定案：access token 的 JWT claims 含 `sid`（会话 id，服务端生成、随机不可枚举）；`signout` 按 `sid` 精确吊销一条。**

**`sid` 不出现在任何报文字段里**，只存在于 token claims 中——与 `channelUserId` / `idKind` 同一条纪律，客户端无消费点。

> 这条不是「多设备裁决」的取向面，而是它的前提：没有 `sid`，「吊销哪一条会话」这个概念在服务端不存在。

### 2. 会话记录的存储键 = `(accountId, deviceId)` 唯一约束；账号活跃会话上限 = 1

`[既有推演]` + 裁定 ①

在办草稿把 `deviceId` 的作用写成了**行为规则**（同设备不吊销 / 异设备吊销全部），但没写它在存储层靠什么成立。若不加唯一约束，同一台设备反复 `signin` 会**累积**会话记录，「该账号有几条活跃会话」变成一个随重试次数增长的数——它同时是限流、异常检测与风控事件（`02` 第三条）的输入。

**定案：会话表以 `(accountId, deviceId)` 为唯一键；且一个账号在任一时刻只有 1 条活跃会话**（上限 1，不做 LRU 挤出）。

| 字段 | 说明 |
|---|---|
| `sid` | 会话 id；进 access token claims，**不进任何报文字段** |
| `accountId` | — |
| `deviceId` | 客户端自报；**唯一约束 `(accountId, deviceId)`** |
| `refreshTokenHash` | 不存明文 |
| `issuedAtUtc` · `refreshExpiresAtUtc` | — |
| `revokedAtUtc` · `revokedReason` | 吊销时间与原因；`revokedReason` 即下行的 `reasonKey` |

> **上限 1 与唯一约束是两条独立的约束，都要留。** 上限 1 保证「异设备登录即挤掉」；`(accountId, deviceId)` 唯一保证「同设备重登不产生第二条记录」。只有后者时，同设备的历史记录仍会以 `revoked` 态堆积；只有前者时，同设备重登会先建后删、留下一个可观测的假「挤下线」。

**`deviceId` 只做裁决与观测的输入，永不参与鉴权。** 它是客户端自报、可任意伪造的字符串：不得用它做设备绑定、不得用它放宽任何校验、不得因它不匹配而拒绝一次凭据有效的登录。伪造它的收益仅仅是「不挤掉自己的另一台设备」，无攻击面。

**对它的两条要求**（生成与持久化落点归客户端，已登记在 `game-design-documents/systems/services/account-service.md` 的待决问题）：**跨启动稳定** · **不同安装实例之间不得碰撞**。重装后 `deviceId` 变化可接受——旧会话记录在该设备上已不存在，挤掉它无玩家可见后果。

### 3. `signin` 的幂等靠 60 秒回放窗口，不能只靠「不吊销」

`[既有推演]`（与 `auth.md` §4 的 refresh 宽限窗口、`profile-sync.md` 的 `pushId` 回放**同一模式、同一理由**）

`auth.md` §7 要求「`signin` 的重试必须能被安全重放」，但**没有写它怎么做**。在办草稿用「同 `deviceId` 不吊销既有会话」堵住了「重试踢掉自己」这一半，但**另一半仍然通着**：一次性验证码在首次请求时已被消费，客户端拿同一个 `code` 重试 → `auth.credential_invalid` / `auth.challenge_expired` → 玩家被迫回到验证码输入框重来一遍，而他刚刚其实已经登录成功了。第三方渠道的 `authCode` 同样是一次性的，形态完全相同。

**定案：一次 `signin` 成功后的 60 秒内，同一 `(channel, credential 标识符, deviceId)` 的重复请求返回与上次完全相同的那一对 token**，不重新签发、不重新吊销任何会话。窗口外再用同一个凭据 → 照常 `auth.challenge_expired` / `auth.credential_invalid`。

窗口取 **60 秒**，与 refresh 宽限窗口**同值**——它要覆盖的是同一件事：客户端指数退避的头几次重试。

> **这条是裁定 ② 成立的前提。** 有了回放窗口，「同设备重登」不必再靠「不吊销旧会话」来假装幂等，可以干净地**替换**。两者必须一起采纳：只取替换、不取回放窗口，会让弱网重试的玩家在登录成功后被赶回验证码输入框。

### 4. 同一 `deviceId` 重登：替换旧会话，`reasonKey = SessionSuperseded`

裁定 ② + `[既有推演]`

**定案：`signin` 命中已存在的 `(accountId, deviceId)` 记录时，原地替换 `sid` 与 refresh token，旧 refresh token 立即失效**，被替换的记录标 `revokedReason = SessionSuperseded`。

- 与 `auth.md` §4 的 rotation 纪律同向：**同一凭据链上永远只有最新的一对有效**。「并存到自然过期」会让同账号同设备最长 30 天存在两对有效 token，且使「活跃会话数」不再是一个可用于风控的数。
- **必须给出 `SessionSuperseded` 这个取值**：旧 refresh token 在替换后若再到达，服务端必须回一个 `reasonKey`。不给取值等于让一个**已知**情形常态占用「未知 → 兜底文案」那条路，而那条兜底是为**日后新增**取值准备的（`envelope.md` §5b · `auth.md` §10）。
- 触发它的是罕见路径（清缓存后重登、换绑渠道后重登时旧进程仍在跑）；正常的弱网重试落在 60 秒回放窗口内，**不产生**吊销、**不产生**任何 `reasonKey`。

### 5. `reasonKey` 取值形态 = PascalCase

裁定 ③

**定案：`reasonKey` 的全部取值用 PascalCase**（`SignedInElsewhere` · `SessionSuperseded` · `TokenReuseDetected` · `OperatorRevoked` · `PlaytimeEnded` · `CredentialChanged` · `SignedOut` …，完整取值表归在办的另一份草稿）。

理由：契约面上「一个字段的取值来自一个封闭集合」这件事，现存全部先例都是 PascalCase（`envelope.md` §2 的枚举值约定，`"Phone"` · `"SignIn"` · `"Rebind"` · `"Conflict"`）。破例会让 `reasonKey` 成为唯一的异形，而这类不一致正是日后「到底该写哪种」反复被重新提出的来源。

**连带纪律（同批写死）：** 客户端的二级文案键由 `code` + `reasonKey` **机械变换**得到——`reasonKey` 按大写字母切分为 UPPER_SNAKE 后拼在一级键之后，如 `auth.session_revoked` + `SignedInElsewhere` → **`ERR_AUTH_SESSION_REVOKED_SIGNED_IN_ELSEWHERE`**；与 `game-design-documents/ux/error-and-blocking-ux.md` 已定的「`ERR_*` 由 `code` 机械变换、无手写对照表」同构。**未知 `reasonKey` → 退回一级键 `ERR_AUTH_SESSION_REVOKED`**（既定兜底）。

**形态自此锁死。** 中途改大小写会让已发版客户端的机械变换全部落空，且是一次静默失效——文案回落到一级键，没有任何报错。

### 6. 移交 `06` 的实现层三项

`[既有推演]`——契约层只声明语义，实现归 `operations/`（与 `profile-sync.md` 把 CAS / 幂等记录的存储移交 `06` 同一条纪律）。

- 会话记录的存储形态与 `(accountId, deviceId)` 唯一约束的并发语义；
- **「吊销其余会话」与「写入本设备会话」须在同一次事务内**——半吊销态会让玩家被踢却仍能刷新，或反之；
- `signin` 幂等回放记录的存储与保留期（可与 `(accountId, pushId)` 幂等记录同处，那条已在 `06` 清单上）。

## 具体形态（可 derive 的落地面）

### `auth.md` §2 token 表补一行

| | access token |
|---|---|
| claims | 含 `sid`（会话 id）——`signout` 据此精确吊销一条；**不进任何报文字段** |

### 建议新增 `auth.md` §4a：会话裁决

```
校验 credential → 取得 (channel, channelUserId) → 查 identity → 得 accountId
  ├─ 60 秒内已有同 (channel, 标识符, deviceId) 的成功登录
  │     → 原样回放上次的 token 对，不签发、不吊销，结束
  ├─ 写入 (accountId, deviceId) 的会话记录
  │     存在则原地替换 sid 与 refresh token，旧记录标 SessionSuperseded
  └─ 吊销该 accountId 下 deviceId ≠ 本次的全部会话，标 SignedInElsewhere
  ※ 上面两步在同一次事务内
  ※ 账号活跃会话上限 = 1
```

### `auth.md` §7 幂等表补一行

| 重放情形 | 应答 |
|---|---|
| `signin` 在 60 秒窗口内重复提交同一 `(channel, 标识符, deviceId)` | `200`，回**与上次完全相同**的 token 对；不重新签发、不重新吊销任何会话 |

### `auth.md` §8 旋钮表补两行（后端配置，非代码常量）

| 旋钮 | 初值 | 推导 |
|---|---|---|
| `signin` 幂等回放窗口 | **60 秒** | 与 refresh 宽限窗口同值同理由：覆盖客户端指数退避的头几次重试 |
| 单账号活跃会话上限 | **1** | 客户端全部既定语义（`auth.session_revoked` 的存在、阻塞屏「被挤下线」变体、CAS 冲突叙事）都建立在「同时只有一个活跃写入方」之上 |

### `auth.md` §10 取值表追加一行（表本体归另一份草稿）

| `reasonKey` | 触发 |
|---|---|
| `SessionSuperseded` | 同一 `deviceId` 重新登录，旧会话被替换（60 秒回放窗口之外） |

## 后果

- **`contracts/auth.md`**：§2 补 `sid` claim · 新增 §4a · §7 补一行 · §8 补两行 · §10 取值表追加 `SessionSuperseded` 并整表改为 PascalCase。**报文形状零改动**——`signin` 的请求 / 应答字段、`session_revoked` 的 `detail` 形状全部维持原样，改的只是取值与新增语义小节。
- **`contracts/envelope.md`**：本稿不改台账的 `code` / `class` / `OpError` / 处置四列；仅 `auth.session_revoked` 行的 `detail` 注记随取值表同批更新（落笔归另一份草稿）。
- **`open-questions/06-platform-stack.md`**：新增上文三项实现层承接。
- **`open-questions/02-account-compliance.md`**：「多设备并发裁决」一条可整条移出（裁决策略 + `reasonKey` 取值 + `deviceId` 规则三项齐了）。
- **存档 schema：零影响。** 会话、`sid`、`deviceId` 都不进 `PlayerProfile`，不触及迁移。
- **客户端侧无新增义务。** 本稿给客户端提的唯一要求（`deviceId` 跨启动稳定 · 不碰撞）落在一条**已登记**的客户端待答项上（`game-design-documents/systems/services/account-service.md`「`deviceId` 的生成与持久化落点」）；行为语义（硬阻塞重登 → 先 pull 后 flush）本就已定案，未要求它改动任何一处。裁定 ③ 的机械变换规则落在另一条**已登记**的客户端待答项上（`reasonKey` 二级措辞的逐条文案 → `ux/error-and-blocking-ux.md`）。故不写对侧库草稿；采纳后若需在客户端库同步落笔，那是一次独立的 `/analyze-new-ideas --lib=game` 运行。

## 对在办另一份草稿的必需改动（裁定 ②③ 的连带）

`solution-draft-compliance-codes-and-reason-keys.md` 有三处与本稿裁定不一致，**两份须一起提炼**，且以本稿的裁定为准：

| # | 位置 | 现状 | 须改为 |
|---|---|---|---|
| 1 | 「具体形态 B」两处 `reasonKey` 表（`session_revoked` 六值 · `nickname_rejected` 三值）与 `compliance.*` 各自的取值 | camelCase（`signedInElsewhere` · `sensitiveWord` …） | **PascalCase**（裁定 ③，全部三处一致改） |
| 2 | 「建议 5」的 `deviceId` 规则 | 同一 `deviceId` 再次 `signin` → **不吊销**既有会话，让旧的自然过期 | **替换**旧会话（裁定 ②），幂等改由本稿建议 3 的 60 秒回放窗口承担 |
| 3 | 「具体形态 B」`session_revoked` 取值表 | 六值 | **七值**——追加 `SessionSuperseded`（裁定 ② 的连带，见本稿方案 4） |

**第 2 项不是形态之争，改动有实质**：那份的「不吊销、自然过期」原本是它保 `signin` 幂等的唯一手段；抽掉它必须同时补上回放窗口，否则弱网重试的玩家会在登录成功后被赶回验证码输入框。**两条必须同批采纳。**

## 备选方案（已考虑并否决）

- **会话上限 2 + 按 `issuedAtUtc` 最旧者挤出**（裁定 ① 的另一侧）— 会让 `sync.conflict`（既定处置 = **丢弃本地缓冲**）从异常路径变成常态，即「玩家在 A 设备打完的一场战斗被 B 设备抹掉」成为日常；而这是单人游戏，没有同时用两台设备推进同一份存档的需求。代价是双端玩家换设备需重登一次，已接受。
- **同设备重登时旧会话并存到自然过期**（裁定 ② 的另一侧）— 同账号同设备最长 30 天存在两对有效 token，与 `auth.md` §4 rotation 纪律（旧的立即失效）方向相反，且使「活跃会话数」不再可用于风控。它当初的唯一理由（保 `signin` 幂等）已被 60 秒回放窗口更干净地满足。
- **`reasonKey` 用 camelCase**（裁定 ③ 的另一侧）— 论据是「它不是 C# 枚举、客户端必须容忍未知值、故 `envelope.md` §2 对它无适用对象」，成立但更弱：契约面现存全部封闭取值集合都是 PascalCase，破例会造出唯一异形。
- **`signout` 吊销该账号全部会话**（回避 `sid`）— 会把另一台设备一并踢下线，凭空造出一次硬阻塞；与「主动登出」的玩家预期完全不符。
- **以 access token 的原始串作会话键** — 它随 rotation 变化，无法作为跨刷新的稳定标识；且把凭据本身当键会逼着服务端存明文。
- **`sid` 作为报文字段下行** — 服务端内部键跨边界即成为契约的一部分（`auth.md` §1a 的三条先例），客户端无任何消费点。
- **`deviceId` 参与鉴权（设备绑定 / 不匹配即拒绝）** — 它是客户端自报可伪造值，用它做安全判定是假安全；真实后果是换机 / 重装的玩家被挡在门外。
- **靠「同 `deviceId` 不吊销」单独承担 `signin` 的幂等** — 只堵住一半：一次性凭据已被消费，重试仍会失败（方案 3）。
- **以 access token 为吊销粒度（黑名单）** — 等于给每个请求加一次中心查询，抵消「自包含 JWT 离线验签」的全部收益；`auth.md` §2 已按同一理由否决过给 push 加中心校验读。
- **服务端主动推送「你被挤下线了」** — 需要长连接 / 推送通道，在 `vision/scope.md` 的既定边界之外；既有的 refresh + CAS 两条路径已把最坏延迟压到 15 分钟且保证云端不被污染。
- **设备列表 / 远程踢出 UI** — 无客户端消费面，且要新增一整套端点。

## 与既有决策的张力

**与已成文契约无冲突。** 两处需要指出的相容性：

1. **「吊销不是实时的」** 看似裁决不彻底，但它是 `auth.md` §2 已写进契约并给出兜底的既定代价，本方案沿用、未扩大。
2. **60 秒幂等回放窗口** 是对 `auth.md` §7「signin 的重试必须能被安全重放」的**填空**，不是松动——§7 提了要求却未给机制。

原先记在此处的第三条张力（两份在办草稿对「同设备重登」的分歧）**已由裁定 ② 消解**，转为文末的必需改动清单。

## 前置依赖

- **`reasonKey` 取值表本体**归在办草稿 `solution-draft-compliance-codes-and-reason-keys.md`；本稿只追加 `SessionSuperseded` 一值并定形态为 PascalCase。**两份须一起提炼**。
- **会话存储的具体形态**依赖 `06` 技术栈落定，但**不阻塞本条**——契约层只声明语义（唯一约束 + 上限 1 + 同事务吊销）。

## 仍需用户决定

**无。** 原三项取向已于 2026-08-16 全部裁定，见「已裁定」小节。
