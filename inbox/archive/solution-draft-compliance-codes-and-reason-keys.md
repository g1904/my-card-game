---
type: solution-draft
date: 2026-08-16
question: `compliance.*` 错误码的具体清单、三处 `detail.reasonKey` 的取值集合、以及合规拦截在 `signin` 的分支形态
source: open-questions/01-contracts.md（三条横切项之一、二）· open-questions/02-account-compliance.md（合规落地 · 多设备并发裁决）
targets: contracts/envelope.md §6 台账 · contracts/auth.md §1a §2 §5 §8 §9 §10 · contracts/_index.md（契约面 五 → 六 份）· 新增 contracts/compliance.md
relates-to: inbox/solution-draft-multi-device-session-arbitration.md（补强稿 · 会话裁决的落地细节；两份的分歧已于 08-16 一并裁决，见「已定案」段）
status: distilled
decided: 2026-08-16（用户按推荐全部定案；`reasonKey` 大小写另行拍板为 PascalCase）
reviewed: 2026-08-16（用户评审并全部定案；提炼时另有两处 interview 裁决——`envelope.md` §4a 无鉴权例外扩为两个例外域并升级为判据 · `auth.md` §5a 的纪律措辞收窄为只约束「拦截」）
distilled-to: `handoffs/2026-08-16c-compliance-contract-and-session-arbitration.md`
---

# 方案草稿 — `compliance.*` 码清单与三处 `reasonKey` 取值表

> **状态：全部取向项已于 2026-08-16 由用户定案**（详见文末「已定案」段）。正文中原「建议」现为**待提炼的定稿内容**，落笔权仍在 `/analyze-new-ideas`。
> **与补强稿 `solution-draft-multi-device-session-arbitration.md` 的分歧亦已一并裁决**：同设备重登取「替换」（本份「建议 5」已按此改写）· `reasonKey` 取 **PascalCase**（本份三张取值表已按此改写）· 单账号活跃会话上限 1 台。

## 问题

五份契约已成文，**报文形状全部封定**，但三处显式留白至今悬着，且它们互为条件：

1. **`compliance.*` 错误码的具体清单**——实名 / 防沉迷 / 注销 / 导出各自的分支（`envelope.md` §6 台账目前只有两条示例）。
2. **三处 `detail.reasonKey` 的取值集合**——`auth.session_revoked` · `auth.nickname_rejected` · `compliance.*`。
3. **合规拦截的分支形态**——在 `signin` 应答返回，还是登录成功后由业务端点返回。

卡住的东西是具体的：客户端的 `ErrorText` 已把 `code → ERR_*` 机械化、并已定「`reasonKey` 只驱动二级措辞、未知取值回落一级文案」（`game-design-documents/ux/error-and-blocking-ux.md`），**它唯一缺的就是这张取值表**；而 `derive` 就绪度评估把 `auth.md` 判为 blocked，`reasonKey` 取值集合是其中一项。

## 约束（来自既有设计）

| 约束 | 来源 |
|---|---|
| **仅两处硬阻塞：登录与启动 pull。** 轮回中途不得硬拒 | `envelope.md` §7b · pillar #4 |
| **`compliance.*` 不打到 `/v1/profile/*`**——同步通道上返回合规拦截只剩「待同步 N 永不减」或「丢进度」两条路 | `profile-sync.md` §11（承重边界） |
| `class` 四值封定；**`class` 不因请求而变** | `envelope.md` §5b |
| **客户端不得解析 `message` 做分支**；需被代码消费的值一律进 `detail`，形状在台账里写死 | `envelope.md` §5a |
| **未知 `code` → 按 `class` 降级；未知 `reasonKey` → 回落该 `code` 的一级文案。** 后端新增取值不得要求客户端同批发版 | `envelope.md` §5b · `auth.md` §10 |
| **`account.status`（`active`/`restricted`/`banned`/`pendingDeletion`）是三条待答项共用的挂接点，且不跨边界** | `auth.md` §1a |
| **七个 auth 端点全部必须幂等**——`signin` 重放不得产生副作用 | `auth.md` §7 |
| **`refresh` 的错误清单只有两条**，以保客户端两条处置路径在报文层面互斥 | `auth.md` §8 §10 |
| **`accountId` 不含个人信息**；渠道内部键不跨边界，不写进玩家可导出的存档 | `auth.md` §1a |
| **昵称由客户端写 profile，后端只判定**；残留风险由存量扫描承接 | `auth.md` §8 |

## 建议方案

### 1. 落点：合规拦截**只在 `signin`**，业务端点一律不返回 `compliance.*`

`[既有推演]`

三个候选落点里有两个已被既有决策排除，**剩下的只有一个**：

- `/v1/profile/*` → `profile-sync.md` §11 已封死；
- 业务端点（轮回中途的任何写入）→ 直接撞 `envelope.md` §7b「仅两处硬阻塞」与 pillar #4；
- **启动 pull 虽是第二个硬阻塞点，但它是 `/v1/profile/pull`，同样被 §11 排除。**

因此「在 `signin` 应答返回」不是一个取向选择，而是**推演的唯一解**。建议在 `auth.md` §5 旁新增一条同构纪律：**`signin` 是 `compliance.*` 在整个 API 面的唯一落地点**——与「强更闸门只在 `signin` 判定」并列，理由同源（会话期内不因外部状态变化而中途变严）。

> 这条同时把 `01-contracts.md` 与 `envelope.md` §6 里「待 `02` 决定分支形态」的措辞降级为**已可落笔**。

### 2. `signin` 的求值顺序：建号在合规判定**之前**，合规拦截不回滚建号

`[既有推演]`

`02` 问「实名是否为**建号**前置——若是，`auth.md` §1a 的『未命中即建号』要插一步」。**建议不做建号前置**，理由是推演性的：

- 实名前置意味着一个**尚无 `account` 的人**要先提交实名信息，那份信息只能挂在 identity 或某个临时态上——当场造出「半个账号」，而 `accountId` 的发放与 `accountSeed` / profile 骨架写入是 §1a 定的**同一步原子动作**。
- 建号本身不泄漏任何东西：`accountId` 随机不可枚举、不含个人信息（§1a）。一个建了却拿不到 token 的账号，对外无任何可见面。

因此 `signin` 的语义定为：

```
校验 credential → 取 (channel, channelUserId) → 查 identity
  命中   → 取 accountId
  未命中 → 建 account + identity + profile 骨架，isNewAccount = true
→ 合规判定（status / 实名 / 时段）
  通过   → 签发 token 对
  不通过 → 返回 compliance.*（账号已存在，不回滚）
```

**§1a 与 §8 的报文一字不改。**

### 3. 实名的死锁与解法：`complianceTicket`

`[既有推演]` + `[通行做法]`

上一条留下一个必须解掉的死锁：`signin` 因 `compliance.realname_required` 失败 → 客户端**没有 access token** → 无法调用任何需鉴权的实名提交端点。

两条出路，**建议第二条**：

| 出路 | 评价 |
|---|---|
| `signin` 签发一个 **scope 受限的 token**（仅可访问 compliance 域） | 引入 token scope 机制，而本库的双 token 模型（§2）刻意没有 scope；为一个域加一整套授权维度不划算 |
| **`compliance.realname_required.detail` 携带一次性 `complianceTicket`**，实名提交端点无鉴权、凭 ticket 认账号 | ✅ 无需新机制。`refresh` 已是「无鉴权 + 凭据在 body」的先例（§6），`challenge`/`signin` 亦然；ticket 天然限定用途、账号与寿命 |

**因此 `compliance.realname_required` 的 `detail` 由 `{ reasonKey }` 扩为 `{ reasonKey, complianceTicket, ticketExpiresAtUtc }`**（`envelope.md` §6 台账需同批改）。ticket 初值寿命 **10 分钟**——覆盖一次实名表单填写，远短于 refresh token。

同一条 ticket 机制也覆盖 `compliance.account_deleting`（冷静期内撤销注销同样发生在无 token 态）。

### 4. 防沉迷时段中途到点：复用 `session_revoked`，**不新增任何机制**

`[既有推演]`

防沉迷是三条合规能力里唯一**会在会话中途到点**的（国内口径：未成年人仅周五 / 六 / 日与法定节假日 20:00–21:00 可玩）。它看起来需要一条「会话中途的拦截通道」，而那条通道恰恰是被 §7b 与 §11 双重封死的。

**建议解法：把它映射进已有的两条路径，一个字段都不加。**

1. 对**已判定为未成年**的账号，`signin` 签发的 access token TTL 取 `min(15 分钟, 距时段结束的剩余秒数)`；
2. 时段结束 → access token 自然过期 → 客户端按既定路径静默 `refresh`；
3. 服务端在 `refresh` 时发现已出时段 → 吊销该账号全部会话，返回 **`auth.session_revoked`**，`detail.reasonKey = "playtimeEnded"`；
4. 客户端按既定「被挤下线」路径：**硬阻塞重登 + 暂停退避 + 本地缓冲保留**；
5. 玩家重登 → `signin` 返回 `compliance.playtime_blocked`，`detail.resumeAtUtc` 给出下次可玩时间。

它同时满足四条既有约束，且没有一条是勉强的：

- **`refresh` 的错误清单仍是两条**（§8）——`session_revoked` 正是其中之一，判据「收到的是不是 `auth.session_revoked`」不受影响；
- **「绝不回退存档点」成立**——`session_revoked` 的既定处置就是保留缓冲、重登后先 pull 后 flush；
- **强制下线的时间精度 = 0**（TTL 卡在时段边界，不是 15 分钟的最坏延迟）；
- **不新增端点、不新增报文字段、不新增客户端路径。**

> 这也解释了为什么 `auth.md` §2 的「access token TTL = 被挤下线的最坏生效延迟」这条论证可以复用到合规上：**两者都是「服务端单方面终止会话」，本就该走同一条路。**

### 5. 多设备并发裁决：`auth.md` §2 其实**已经答了**，`02` 只需补一条 `deviceId` 规则

`[既有推演]`

`02` 把「后登录挤下线？拒绝？只让先到的写入生效？」列为待答，但 `auth.md` §2 的整段论证——

> 「被挤下线」的最坏生效延迟 = access token TTL … 窗口内旧设备的 push 由 `revision` CAS 拒绝，代价只是旧设备丢一次本地缓冲

——**只有在「后登录挤下线」这一裁决下才成立**。另两个选项（拒绝后登录 / 双活）都不会产生「旧设备在窗口内继续 push」这一情形。建议把它记为**已被 §2 隐含定案**，而非仍待裁决。

`deviceId` 如何参与，则是一条必须补上的推演：

- **单账号活跃会话上限 = 1 台**（08-16 定案）。客户端全部既定语义（`auth.session_revoked` 的存在、阻塞屏「被挤下线」变体、`sync-service` 的 CAS 冲突叙事）都建立在「同时只有一个活跃写入方」之上；放宽到 N 台会让 `sync.conflict`（既定处置 = 丢弃本地缓冲）成为常态。
- **不同 `deviceId` → 吊销该账号全部既有会话**，被吊销方在下一次请求收到 `auth.session_revoked` + `reasonKey = "SignedInElsewhere"`。
- **同一 `deviceId` 再次 `signin` → 替换**该 `(accountId, deviceId)` 的会话记录，旧 refresh token 立即失效；旧 refresh token 若在替换后到达 → `auth.session_revoked` + `reasonKey = "SessionSuperseded"`。

> **⚠ 本条已按补强稿改写（08-16）。** 本草稿初稿写的是「同 `deviceId` **不吊销**、让旧会话自然过期」，理由是保 §7 要求的 `signin` 幂等。该理由**已不成立**：`solution-draft-multi-device-session-arbitration.md` 的「建议 3」指出，一次性验证码 / `authCode` 在首次请求时即被消费，「不吊销」只堵住了「重试踢掉自己」这一半，重试仍会撞 `auth.challenge_expired`——幂等本就该由**60 秒回放窗口**（与 §4 refresh 宽限窗口同模式同值）承担。幂等有了干净的承载后，「不吊销」不但多余，还与 §4 的 rotation 纪律（旧 refresh 立即失效）方向相反，并让「该账号有几条活跃会话」不再是一个可用于风控的数。
>
> **会话裁决的完整落地形态**（`sid` claim · `(accountId, deviceId)` 唯一约束 · 60 秒回放窗口 · 移交 `06` 的三项）**归补强稿，本份不复述**——两份并存的同一套形态就是两个权威。

### 6. 注销与导出：建议新开第六份契约 `contracts/compliance.md`

`[取向选择]` —— **08-16 定案：开。** 依据是 `_index.md` 已立的分域判据（见下表）。

实名 / 时段是**拦截**，走错误码即可；注销与导出是**玩家主动发起的操作**，必须有端点。它们不能省——PIPL 明确要求删除权与可携带权，国内应用商店审核亦查「App 内可注销」。

**归属判据**用 `_index.md` 已立的那条：「一个域的承重纪律若与既有任一份相反，就必须独立成文」。合规域与 auth 域确有两条相反的纪律：

| | auth 域 | 合规域 |
|---|---|---|
| 时间尺度 | 即时判定，端点内完成 | **长时状态机**（注销冷静期跨天）与**异步任务**（导出） |
| 可逆性 | 全部幂等可重放 | 注销生效**不可逆**，且撤销是一个独立动作 |

建议端点集（**五个**）：

```
POST   /v1/compliance/realname          提交实名（凭 complianceTicket，无鉴权）
GET    /v1/compliance/status            查当前合规态                    —— 需鉴权
POST   /v1/compliance/deletion          申请注销 → status = pendingDeletion
DELETE /v1/compliance/deletion          撤销注销申请（凭 token 或 ticket）
POST   /v1/compliance/export            申请数据导出（异步任务）
GET    /v1/compliance/export/{taskId}   查导出任务状态与下载链接
```

**`GET /v1/compliance/status` 与「不设 `/v1/auth/me`」不冲突，判据要写清楚**，否则读者会以为它撑开了先例：`auth/me` 被否的理由是「`AccountInfo` 本就随 profile pull 整聚合下行，再立一个读取端点即两份真值」；而**合规态没有任何下行通道**——`account.status` 已定不跨边界（§1a），实名状态含个人信息不得进玩家可导出的 profile，时段剩余会中途变化。**没有第一份真值，就谈不上第二份。**

## 具体形态（可 derive 的落地面）

### A. `envelope.md` §6 台账：`compliance.*` 四条

| `code` | `class` | `OpError` | 客户端处置 | `detail` 形状 | `message` 必含 |
|---|---|---|---|---|---|
| `compliance.realname_required` | `Fatal` | `Compliance` | 阻塞屏 + 「去实名」动作，凭 ticket 走实名流程 | `{ reasonKey, complianceTicket, ticketExpiresAtUtc }` | 触发的合规规则标识（**不含**姓名 / 证件号任何片段） |
| `compliance.playtime_blocked` | `Fatal` | `Compliance` | 阻塞屏 + 展示 `resumeAtUtc`，无重试动作 | `{ reasonKey, resumeAtUtc }` | 触发的时段规则与解除时间 |
| `compliance.account_restricted` | `Fatal` | `Compliance` | 阻塞屏 + 申诉入口（申诉走站外，不占端点） | `{ reasonKey }` | `status` 值与置入时间 |
| `compliance.account_deleting` | `Fatal` | `Compliance` | 阻塞屏 + 「撤销注销」动作（凭 ticket） | `{ reasonKey, deletionEffectiveAtUtc, complianceTicket, ticketExpiresAtUtc }` | 冷静期起止时间 |

四条全为 `Fatal`（重试同一次 `signin` 不会改变结果），全映 `OpError.Compliance`——与客户端 `account-service.md` 的既定映射「实名 / 防沉迷拦截 → `OpError.Compliance`」逐条对上。

`compliance.account_restricted` 承接 `02` 的风控三档：`restricted` 与 `banned` 两个 `status` **共用这一个 `code`**，靠 `reasonKey` 分辨——它们的玩家处置相同（无法进入，看措辞），拆两个 `code` 会让客户端处置表多一行却走同一条路径。

### B. 三处 `reasonKey` 取值表

> **取值形态 = PascalCase**（08-16 定案）。判据：契约面上「一个字段的取值来自封闭集合」这件事，现存全部先例都是 PascalCase（`"Phone"` · `"SignIn"` · `"Rebind"` · `"Conflict"`，`envelope.md` §2）；让 `reasonKey` 成为唯一异形，只会让「到底该写哪种」在日后每加一个取值时被重新提出一次。
>
> **连带纪律（同批写死）：客户端的二级文案键由 `code` + `reasonKey` 机械变换得到**——`ERR_AUTH_SESSION_REVOKED_SIGNED_IN_ELSEWHERE`；未知 `reasonKey` → 退回一级键 `ERR_AUTH_SESSION_REVOKED`。与客户端已定的「`ERR_*` 由 `code` 机械变换、无手写对照表」同构（`game-design-documents/ux/error-and-blocking-ux.md`）。**大小写自此锁死**——中途改形态会让已发版客户端的机械变换全部落空。

**`auth.session_revoked.detail.reasonKey`**（七值）

| 取值 | 触发 | 依据 |
|---|---|---|
| `SignedInElsewhere` | 另一 `deviceId` 完成 `signin` | 建议 5 |
| `SessionSuperseded` | **同一** `deviceId` 重新登录，旧会话被替换；旧 refresh token 在替换后到达 | 建议 5（08-16 定案「替换」的必然配套） |
| `SignedOut` | 玩家主动 `signout`（含另一设备发起的全端登出） | `auth.md` §8 |
| `OperatorRevoked` | 运营吊销 —— `status` 变更为 `restricted` / `banned` 时连带吊销全部会话 | `02` 的风控三档挂接点 |
| `PlaytimeEnded` | 未成年人时段到点强制下线 | 建议 4 |
| `CredentialChanged` | `bind` / `unbind` 改变了账号的登录方式，既有会话失效 | `auth.md` §7 的三个写入端点 |
| `TokenReuseDetected` | refresh token 在宽限窗口外重放，判定泄漏，吊销全部会话 | **`auth.md` §4 已定这个行为，却没有对应的 `reasonKey`** |

> `SessionSuperseded` 不能省。定案取「替换」后，「同设备重登 → 旧 refresh token 随后到达」是一个**已知且常态**的情形；不给它取值等于让它长期占用「未知 → 兜底文案」那条路，而那条兜底是为**日后新增**取值准备的（`envelope.md` §5b）。

> ⚠ **后两条是当前契约的实际漏洞，不是新设计。** §4（rotation 判泄漏 → 吊销全账号会话）与 §7（`bind`/`unbind` 改变登录方式）都会产生 `auth.session_revoked`，而 §10 只举了「另一设备登录 / 运营吊销」两例——落到实现，玩家会在自己刚绑定一个渠道之后看到「你的账号已在另一台设备登录」。**这两条应当补进契约，与 `02` 的裁决规则无关。**

**`auth.nickname_rejected.detail.reasonKey`**（三值）

| 取值 | 触发 |
|---|---|
| `SensitiveWord` | 命中敏感词 / 违禁词表（词表与审核口径归 `02`，阈值与服务商归 `06`） |
| `TooFrequent` | 改名频次超限（阈值归 `06`，与 §8 的旋钮同处） |
| `Malformed` | 长度 / 字符集不合法——**服务端兜底**。客户端已定只做「长度与空白这类无争议的输入约束」（§8），改包可绕过 |

**不收 `Duplicated`（昵称唯一性）。** 本作是单人游戏、昵称无任何玩家间可见性（§8 已如实论证过这一点），唯一性无价值却会引入一次全表查重与一条重试路径。

**`compliance.*` 各自的 `reasonKey`**

| `code` | 取值 | 触发 |
|---|---|---|
| `compliance.realname_required` | `NotSubmitted` | 从未提交实名 |
| | `VerificationFailed` | 已提交但核验未通过（姓名 / 证件号不匹配） |
| | `VerificationPending` | C 层核验异步未回（提示稍后重试；仍是 `Fatal`——重试同一次 `signin` 不改变结果） |
| `compliance.playtime_blocked` | `MinorCurfew` | 未成年人处于非允许时段 |
| | `MinorDailyLimit` | 当日允许时长已用尽 |
| `compliance.account_restricted` | `UnderReview` | 风控观察中（`status = restricted`） |
| | `Banned` | 封禁（`status = banned`） |
| `compliance.account_deleting` | `CoolingOff` | 注销冷静期内，可撤销 |

> `MinorCurfew` 与 `MinorDailyLimit` 在现行国内口径下几乎重合（那一小时既是时段也是全部时长），**仍建议分列**：措辞不同（「现在不是可游玩时段」vs「今天的时长已用完」），且监管口径变动时不必改 `code`。

### C. 数值旋钮（初值，落后端配置，非代码常量）

| 旋钮 | 初值 | 推导 |
|---|---|---|
| `complianceTicket` 寿命 | **10 分钟** | 覆盖一次实名表单填写 + 一次重试；远短于 refresh token，泄漏面可忽略 |
| 注销冷静期 | **15 天**（08-16 定案） | 国内通行区间 7–15 天；取上界，因为「误触注销」的代价是**永久丢失全部进度**（云端权威下无本地兜底），而多给 8 天的代价只是一行配置 |
| 导出任务保留期 | **7 天** | 下载链接有效期；导出产物含个人信息，不宜长留 |
| 未成年 access token TTL | `min(15 分钟, 距时段结束剩余)` | 建议 4；上界沿用 §8 的既有初值 |
| 未成年判定数据源 | 实名核验返回的**出生日期** | 不单独存年龄——年龄会过期，出生日期不会；且它已随核验回来，不必二次采集 |

## 后果

| 受影响 | 改什么 |
|---|---|
| `contracts/envelope.md` §6 | 台账新增两条（`account_restricted` · `account_deleting`），既有两条的 `detail` 形状改写（`realname_required` 扩三字段）；§6 台账下方「取值集合待 `02` 填表」的措辞删除 |
| `contracts/auth.md` §5 | 新增「`signin` 是 `compliance.*` 的唯一落地点」纪律，与强更闸门并列 |
| `contracts/auth.md` §1a | 求值顺序显式化（建号在合规判定之前，拦截不回滚建号）；**报文不变** |
| `contracts/auth.md` §8 §9 §10 | 补 `session_revoked` 六值表与 `nickname_rejected` 三值表；`signin` 错误清单里的 `compliance.*`（清单待 `02`）改为四条实名列举 |
| `contracts/auth.md` §2 | 补一句「本表的 TTL 论证同时覆盖未成年时段收窄」；多设备裁决由「待 `02`」改为「§2 已隐含定案 + `deviceId` 规则 + 上限 1 台」。**`sid` claim 与会话表归补强稿，本份不重复列** |
| `contracts/_index.md` | **契约面 五 → 六 份**；分域判据段落追加合规域的两条相反纪律 |
| **新增** `contracts/compliance.md` | 六端点报文本体 |
| `open-questions/01-contracts.md` | 前两条横切项可整条移出（第三条「机检断言承载位置」不受影响） |
| `open-questions/02-account-compliance.md` | 「合规落地」与「多设备并发裁决」两条大幅收窄；仅剩**风控系统的有无与形态**、敏感词词表口径、未过审昵称的存量扫描频率 |
| `open-questions/06-platform-stack.md` | 新增两项：**可信服务端时钟**（时段判定不得依赖设备时钟，`envelope.md` §4b 已定 `X-Server-Time` 仅供诊断）· 导出产物的存储与链接签发 |

**存档 schema：无影响。** 合规态一律不进 profile——`account.status` 已定不跨边界，实名信息不得进玩家可导出的存档（PIPL 面 + §1a 的同一条理由）。**无迁移。**

**对客户端的影响是机械的，不构成新的设计决策：** `code → ERR_*` 是机械变换、`reasonKey → 二级措辞` 的结构与兜底规则已定（`game-design-documents/ux/error-and-blocking-ux.md`）。客户端两处待答项（`ux/error-and-blocking-ux.md` 的「三处取值集合待后端定」· `systems/services/account-service.md` 的「ComplianceManager 覆盖面切分」）会因本方案变为可落笔——**但本库不代为决定它们**，那是客户端库自己的裁决。

## 备选方案（已考虑并否决）

- **合规拦截落在业务端点** — 会在轮回中途硬拒，撞 `envelope.md` §7b 与 pillar #4；且业务端点的错误清单会各自长出一份 `compliance.*`，等于把一个横切关注点复制到每一份契约。
- **为防沉迷时段新增一条「会话中途拦截」通道**（如给 `refresh` 加第三个 `code`，或加一个心跳端点） — 前者破坏 §8 刻意收紧的两码互斥（客户端两条处置路径的判据会变得有歧义）；后者为一条罕见路径新增一个高频端点，且心跳失败的语义与断线不可区分。
- **实名作为建号前置** — 造出「半个账号」（实名信息无处挂），并把 §1a 的原子建号拆成两步；而 `accountId` 不含个人信息，早建号无任何暴露面。
- **`signin` 未实名时签发 scope 受限 token** — 为一个域引入整套 scope 授权维度，而 §2 的双 token 私有模型刻意没有它；`complianceTicket` 用既有的「无鉴权 + body 凭据」先例即可覆盖。
- **`restricted` 与 `banned` 各给一个 `code`** — 玩家处置完全相同（进不去、看措辞），拆开只是让客户端处置表多一行走同一条路径；`reasonKey` 正是为这种同处置异措辞而设。
- **收 `nickname_rejected.Duplicated`（昵称唯一）** — 昵称无玩家间可见性（§8），唯一性无价值却引入全表查重与一条重试路径。
- **`reasonKey` 用 camelCase**（08-16 否决）— 理由本身成立（`reasonKey` 不是 C# 枚举，客户端必须容忍未知值故永不为它建枚举，`envelope.md` §2「枚举值逐字同 C# 枚举名」对它无适用对象），但代价是让它成为契约面上唯一的非 PascalCase 封闭取值集；这类不一致正是「到底该写哪种」在每次新增取值时被重新提出的来源。
- **同一 `deviceId` 重登时旧会话并存到自然过期**（08-16 否决，本草稿初稿的写法）— 它当初的唯一理由是保 `signin` 幂等，而幂等已由 60 秒回放窗口更干净地承担；并存则与 §4 rotation 纪律方向相反，且让活跃会话数不再可用于风控。见建议 5 的改写说明。
- **单账号活跃会话上限放宽到 2 台以上**（08-16 否决）— 会让 `sync.conflict`（既定处置 = 丢弃本地缓冲）从异常路径变成常态；本作是单人游戏，没有同时用两台设备推进同一份存档的需求。代价是双端玩家换设备要重登一次，可接受。
- **注销 / 导出走 auth 域，扩到第十、十一个端点** — 长时状态机与异步任务的纪律与 auth 域「即时幂等判定」相反，塞进同一份文档后读者无法判断哪条纪律管哪个端点（正是 `_index.md` 拒绝把 `purchase` 并入 `profile-sync` 的同一条理由）。
- **注销 / 导出走站外（官网 / 客服）** — 国内应用商店审核查「App 内可注销」；且站外流程需要另一套身份核验，成本高于一个端点。
- **合规态随 `AccountInfo` 下行** — 与 `account.status` 被否的理由逐字相同（会话中途过期的第二真值），且实名状态含个人信息，进 profile 即进玩家可导出的存档。

## 与既有决策的张力

**一处，且已有既定判据可援引：`contracts/_index.md` 现写「契约面五份」。** 建议 6（**08-16 已定案采纳**）使它变成六份。这不构成推翻——该段本身已声明「**不作『就此封顶』的断言**」，并给出了分域判据（承重纪律相反即独立成文）。本方案是**按那条判据行使它**，不是绕过它；提炼时须把 `_index.md` 的份数与分域判据段落**同批重写**，否则那句「五份」立刻成为一处失真。

其余三处是**形状扩写而非冲突**，按 `_index.md`「契约变更的完成判据」在同一次变更内原子完成即可：`compliance.realname_required` / `account_deleting` 的 `detail` 扩字段（台账同批改）· `auth.md` §8 `signin` 错误清单实名列举 · §2 论证段落追加一句。

## 前置依赖

- **风控系统的有无与形态（`02` 同分片余项）。** `compliance.account_restricted` 的两个 `reasonKey` 已够用，但若风控要向玩家区分「哪一类异常」，取值表需再扩——**本方案不阻塞它**：新增 `reasonKey` 无需客户端同批发版（`envelope.md` §5b 的兜底纪律）。
- **`06` 的三项。** 改名频次阈值 · 实名核验服务商与灾备 · **可信服务端时钟**（时段判定的输入；`X-Server-Time` 已定仅供诊断，设备时钟不可信）。三项都不挡取值表落笔，只挡实现。
- **客户端侧的 `ComplianceManager` 覆盖面切分**（`game-design-documents/systems/services/account-service.md` 的待答项）。本方案给出的是**边界另一侧的报文**，客户端呈现与拦截的切分仍归客户端库裁决，本库不代为决定。
- **`contracts/compliance.md` 的端点报文本体**（六个端点的字段表）在本草稿中**只给端点集与语义，未给字段表**——它应由一次正式的契约变更落笔（`_index.md`「契约变更的完成判据」四条），而不是在草稿里预写。**这是提炼后的下一件事，不是本草稿的欠账。**
- **补强稿 `solution-draft-multi-device-session-arbitration.md` 须与本份同批提炼。** 两份的分歧已裁决，但它承载的 `sid` claim · `(accountId, deviceId)` 唯一约束 · 60 秒回放窗口是本份「建议 5」定案形态的**实际承载**；只提炼本份会让 `SessionSuperseded` 这个取值在契约里没有产生它的机制。

## 已定案（2026-08-16 · 用户裁决）

**无仍待用户决定项。** 本份四项按推荐定案，与补强稿的三处分歧一并裁决如下。

| # | 决定 | 落在正文何处 |
|---|---|---|
| ① | **开第六份契约 `contracts/compliance.md`。** 依据 `_index.md` 的分域判据——合规域有两条与 auth 域相反的承重纪律（长时状态机 / 不可逆）。**不并入 `auth.md`**：那会让一份文档同时承载两套相反纪律，读者无法判断哪条管哪个端点 | 建议 6 · 后果表 · 张力段 |
| ② | **数据导出首版必做，取最简形态**——异步生成一份 JSON，含 profile 明文 + 账号元数据，**不含任何渠道内部键**（`channelUserId` / `idKind` 已定不进玩家可导出物，`auth.md` §1a）。理由：合规要求通常在过审阶段才显形，届时补做会挤在发版窗口里 | 建议 6 端点集 · 数值旋钮（保留期 7 天） |
| ③ | **注销冷静期 = 15 天** | 数值旋钮表 |
| ④ | **未成年时段口径不写死在契约里。** 契约只给 `reasonKey` 与 `resumeAtUtc`，具体时段表落后端配置（归 `operations/`）——监管口径变动时不必改契约、不必发版，与 pillar #5「线上可干预」一致。现行口径可作**说明性注释**写入，但**不具规范性**，以免成为第二权威 | 建议 4 · 数值旋钮表 |
| ⑤ | **`reasonKey` 取值形态 = PascalCase**（补强稿 ③，用户另行拍板）。连带写死：客户端二级文案键由 `code` + `reasonKey` 机械变换得到；未知取值退回一级键。**形态自此锁死** | 具体形态 B 抬头 · 三张取值表 |
| ⑥ | **同一 `deviceId` 重登 = 替换旧会话**（补强稿 ②，推翻本草稿初稿的「并存到自然过期」）。配套追加取值 `SessionSuperseded` | 建议 5（含改写说明）· 取值表 |
| ⑦ | **单账号活跃会话上限 = 1 台**（补强稿 ①） | 建议 5 |

**提炼时的两条注意：**

1. **本份与补强稿须同批提炼**（见「前置依赖」末条）——分开提炼会让 `SessionSuperseded` 在契约里没有产生它的机制。
2. **`contracts/_index.md` 的「契约面五份」须同批重写为六份**，否则它当场成为一处失真。
