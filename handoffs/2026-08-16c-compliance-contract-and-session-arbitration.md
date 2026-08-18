# 合规域成文（第六份契约）与会话裁决落地

- id: 2026-08-16c-compliance-contract-and-session-arbitration
- date: 2026-08-16
- topic: contracts/compliance（新建 · 第六份）· contracts/auth（§1a 求值顺序 · §2 `sid` · 新增 §4a 会话裁决 · §5 拦截落地点 · §7 幂等 · §8 §9 §10 取值表与旋钮）· contracts/envelope（§3 端点清单 · §4a 例外域判据 · §6 台账四条）· contracts/_index（五 → 六份）· open-questions/01 · 02 · 06
- status: distilled
- distilled-to: `contracts/compliance.md`、`contracts/auth.md`、`contracts/envelope.md`、`contracts/purchase.md`、`contracts/_index.md`、`README.md`、`open-questions/01-contracts.md`、`open-questions/02-account-compliance.md`、`open-questions/06-platform-stack.md`、`open-questions.md`、`open-questions/update-log.md`、`answer-logs/log-compliance-and-session-arbitration.md`、`game-design-documents/open-questions/cross-boundary.md`

## Intent（distilled）

**一句话：** 把 `auth.md` 悬着的三处取值留白一次填满，并为此开出第六份契约 `contracts/compliance.md`——合规拦截只在 `signin` 落地，会话裁决收敛为「单账号一条活跃会话」。

来源是两份 `status: decided` 的方案草稿，**必须同批提炼**：主稿给出码清单与取值表，补强稿给出使这些取值得以产生的会话机制。分开提炼会让 `SessionSuperseded` 这个取值在契约里没有产生它的机制。

### 1. 合规拦截的唯一落地点 = `signin`

三个候选落点里两个已被既有决策排除（`/v1/profile/*` 被 `profile-sync.md` §11 封死；业务端点撞 `envelope.md` §7b 与 pillar #4），启动 pull 本身就是 `/v1/profile/pull`，同样出局。**这不是取向选择，是推演的唯一解。**

与之并列的既有纪律是「强更闸门只在 `signin` 判定」，理由同源：会话期内不因外部状态变化而中途变严。

**纪律的措辞范围经 interview 收窄**：约束的是**拦截**，不是 `compliance.` 这个前缀。合规域端点自身的操作错误（ticket 过期、核验拒绝）另有码，随报文本体一并落笔。

### 2. `signin` 的求值顺序：建号先于合规判定，拦截不回滚建号

```
校验 credential → 取 (channel, channelUserId) → 查 identity
  命中   → 取 accountId
  未命中 → 建 account + identity + profile 骨架，isNewAccount = true
→ 合规判定（status / 实名 / 时段）
  通过   → 签发 token 对
  不通过 → 返回 compliance.*（账号已存在，不回滚）
```

实名不做建号前置：那意味着一个尚无 `account` 的人先提交实名信息，那份信息只能挂在一个临时态上，当场造出「半个账号」，而 `accountId` 发放与 profile 骨架写入是 §1a 定的同一步原子动作。建号本身无暴露面——`accountId` 随机不可枚举、不含个人信息。**报文一字不改。**

### 3. `complianceTicket` 解实名死锁

`signin` 因 `compliance.realname_required` 失败 → 客户端没有 access token → 调不动任何需鉴权的实名提交端点。

解法不引入新机制：**错误的 `detail` 携带一次性 `complianceTicket`**，实名提交端点无鉴权、凭 ticket 认账号。`refresh` / `challenge` / `signin` 已是「无鉴权 + 凭据在 body」的先例。同一条机制覆盖 `compliance.account_deleting`（冷静期内撤销注销同样发生在无 token 态）。

否决的另一侧：`signin` 签发 scope 受限 token——为一个域引入整套 scope 授权维度，而 §2 的双 token 私有模型刻意没有它。

### 4. 防沉迷时段中途到点：复用 `session_revoked`，一个字段都不加

防沉迷是三条合规能力里唯一会在会话中途到点的。它看起来需要一条「会话中途的拦截通道」，而那条通道恰被 §7b 与 §11 双重封死。映射进已有的两条路径即可：

1. 已判定为未成年的账号，`signin` 签发的 access token TTL 取 `min(15 分钟, 距时段结束的剩余秒数)`；
2. 时段结束 → token 自然过期 → 客户端按既定路径静默 `refresh`；
3. 服务端在 `refresh` 时发现已出时段 → 吊销该账号全部会话，返回 `auth.session_revoked` + `reasonKey = "PlaytimeEnded"`；
4. 客户端走既定「被挤下线」路径：硬阻塞重登 + 暂停退避 + 本地缓冲保留；
5. 重登 → `signin` 返回 `compliance.playtime_blocked` + `detail.resumeAtUtc`。

四条既有约束同时满足且无一勉强：`refresh` 错误清单仍是两条 · 「绝不回退存档点」成立 · 强制下线精度 = 0（TTL 卡在时段边界）· 不新增端点 / 字段 / 客户端路径。**`auth.md` §2 那句「access token TTL = 被挤下线的最坏生效延迟」的论证可以直接复用——两者都是服务端单方面终止会话。**

### 5. 会话裁决：单账号一条活跃会话

裁决策略「后登录挤下线」**已被 §2 隐含定案**：§2 那段「窗口内旧设备的 push 由 `revision` CAS 拒绝」的论证，只有在这一裁决下才成立；另两个选项（拒绝后登录 / 双活）都不会产生「旧设备在窗口内继续 push」这一情形。

落地机制（补强稿的承载）：

- **access token 的 JWT claims 含 `sid`。** `signout` 无 body、语义是「吊销当前会话」；若 token 只带 `accountId`，服务端无从知道是哪一条，`signout` 只能退化为吊销全部会话，把另一台设备一并踢下线。`sid` 不出现在任何报文字段里。
- **会话表以 `(accountId, deviceId)` 为唯一键，且账号活跃会话上限 = 1。** 两条是独立约束，都要留：上限 1 保证异设备登录即挤掉；唯一约束保证同设备重登不产生第二条记录。
- **同一 `deviceId` 重登 → 原地替换**，旧 refresh token 立即失效，被替换记录标 `SessionSuperseded`。与 §4 rotation 纪律同向。
- **`signin` 幂等靠 60 秒回放窗口**，与 §4 refresh 宽限窗口同值同理由。§7 提了「重试必须能被安全重放」却没给机制——一次性验证码 / `authCode` 在首次请求时即被消费，重试必然撞 `auth.challenge_expired`。**回放窗口是「替换」得以成立的前提**：两条必须一起采纳，只取替换会让弱网重试的玩家在登录成功后被赶回验证码输入框。
- **`deviceId` 只做裁决与观测的输入，永不参与鉴权。** 它是客户端自报可伪造的字符串；伪造它的收益仅仅是「不挤掉自己的另一台设备」，无攻击面。

### 6. 第六份契约 `contracts/compliance.md`

实名 / 时段是**拦截**，走错误码即可；注销与导出是**玩家主动发起的操作**，必须有端点，且 PIPL 明确要求删除权与可携带权、国内应用商店审核查「App 内可注销」。

归属判据用 `_index.md` 已立的那条——一个域的承重纪律若与既有任一份相反，就必须独立成文。合规域与 auth 域确有两条相反的纪律：

| | auth 域 | 合规域 |
|---|---|---|
| 时间尺度 | 即时判定，端点内完成 | 长时状态机（注销冷静期跨天）与异步任务（导出） |
| 可逆性 | 全部幂等可重放 | 注销生效不可逆，且撤销是一个独立动作 |

端点集**六个**（realname / status / deletion 申请与撤销 / export 申请与查询）。`GET /v1/compliance/status` 与「不设 `/v1/auth/me`」不冲突：`auth/me` 被否的理由是 `AccountInfo` 本就随 profile pull 整聚合下行、再立读取端点即两份真值；而**合规态没有任何下行通道**（`status` 不跨边界、实名状态含个人信息不得进可导出 profile、时段剩余会中途变化）。没有第一份真值，就谈不上第二份。

### 7. `reasonKey` 形态 = PascalCase，二级文案键机械变换

契约面上「取值来自封闭集合」的现存全部先例都是 PascalCase（`"Phone"` · `"SignIn"` · `"Rebind"` · `"Conflict"`）。让 `reasonKey` 成为唯一异形，只会让「到底该写哪种」在日后每加一个取值时被重新提出一次。

连带纪律同批写死：客户端二级文案键由 `code` + `reasonKey` 机械变换得到（`reasonKey` 按大写字母切分为 UPPER_SNAKE 拼在一级键后），未知取值退回一级键。**形态自此锁死**——中途改大小写会让已发版客户端的机械变换全部落空，且失效是静默的。

## Clarifications（interview 产物）

| 问题 | 用户裁决 | 它推翻 / 细化了什么 |
|---|---|---|
| `envelope.md` §4a 写死「无鉴权例外仅限 auth 域」，而合规域的 ticket 端点当场是第二个例外域 | **扩为两个例外域，并把枚举升级为判据**：无鉴权例外只允许给「玩家此刻不可能持有 access token」的端点 | 两份草稿的后果表都没列 `envelope.md` §4a——这是它们未觉察的碰撞。护栏由「点名 auth」改为「一条可复用的判据」，边界因此更严而非更松 |
| `auth.md` §5 新增的「`compliance.*` 唯一落地点」纪律，措辞范围 | **只约束「拦截」**：合规域端点自身的操作错误另有码，随 `contracts/compliance.md` 报文本体一并落笔 | 细化了主稿建议 1 的措辞。字面收死会禁掉 `compliance` 域表达 ticket 过期一类自有语义，而那批码本就被推迟到一次正式契约变更 |

**两处计数笔误按三方互证取大者**（非 interview 项，直接推演）：端点集 **6 个**（主稿正文写「五个」却列了 6 行，后果表与 inbox 台账均写「六端点」）· `session_revoked` **7 值**（后果表写「六值」却列了 7 行，补强稿要求追加第 7 值）。

## 客户端侧影响

**报文形状零改动，但给客户端补齐了三处它已在等的取值**——受影响成分是 `account-service`。

客户端的两条待答项因此变为可落笔：`ux/error-and-blocking-ux.md` 的「三处 `reasonKey` 取值集合待后端定」· `systems/services/account-service.md` 的 `ComplianceManager` 覆盖面切分。**本库不代为决定它们**，已在 `game-design-documents/open-questions/cross-boundary.md` 立承接项。

`deviceId` 的生成与持久化落点是一条**已登记**的客户端待答项，本次只对它追加两条要求：跨启动稳定 · 不同安装实例之间不得碰撞。重装后变化可接受。

**存档 schema 零影响、无迁移。** 合规态一律不进 profile；会话、`sid`、`deviceId` 都不进 `PlayerProfile`。

## Open questions

- **`contracts/compliance.md` 六端点的报文字段表。** 本次只落端点集、语义与承重纪律；字段表应由一次正式的契约变更落笔（`_index.md` 的完成判据四条），而非在提炼中预写。
- **合规域端点自身的错误码**（ticket 过期 / 核验拒绝 / 冷静期已过 / 导出任务不存在）。随上一条一并落笔并登记进 `envelope.md` §6 台账。
- **风控系统的有无与形态。** `compliance.account_restricted` 的两个 `reasonKey` 已够用；若风控要向玩家区分「哪一类异常」，取值表需再扩。不阻塞——新增 `reasonKey` 不要求客户端同批发版。
- **可信服务端时钟。** 时段判定不得依赖设备时钟，而 `X-Server-Time` 已定仅供诊断。归 `06`。
- **导出产物的存储与下载链接签发形态。** 归 `06`。

## Notes / triage

来源：`inbox/solution-draft-compliance-codes-and-reason-keys.md` + `inbox/solution-draft-multi-device-session-arbitration.md`，两份均 `status: decided`，已同批提炼并移入 `inbox/archive/`。

移出待答项 2 条，记于 `answer-logs/log-compliance-and-session-arbitration.md`。
