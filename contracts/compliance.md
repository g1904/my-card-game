# compliance —— 实名 · 防沉迷 · 注销 · 数据导出

> 覆盖 `/v1/compliance/…` 六个端点，以及 `compliance.*` 错误码在整个 API 面的落地规则。
> **边界层不在此重复**：序列化与命名约定、`/v1/` 主版本、传输信封、错误体形状、版本协商——全部见 `envelope.md`。
> 拦截发生在 `signin`，故 `auth.md` §5 与本文件互为对位：**那里定「什么时候拦」，这里定「拦住之后玩家怎么走出去」**。
> 客户端侧门面见 `game-design-documents/systems/services/account-service.md`。
> Source: `handoffs/2026-08-16c-compliance-contract-and-session-arbitration.md`（端点集 · ticket 机制 · 拦截落点 · 四条拦截码 · 时段与导出的承重纪律）、`handoffs/2026-09-03-compliance-endpoint-payloads.md`（§2 撤销端点方法 · §3 回放窗口 · 六端点报文字段表 · 端点自身的错误码 · §8 白名单 · §9 五个旋钮）、`handoffs/2026-09-03-nickname-moderation-and-risk-control.md`（`nicknameChangeRequired` 的语义来源 · §5 取值表首版不扩）。

## 1. 为什么独立成文

`_index.md` 的分域判据：**一个域的承重纪律若与既有任一份相反，就必须独立成文。** 合规域与 auth 域有两条相反的纪律：

| | auth 域 | 合规域 |
|---|---|---|
| 时间尺度 | 即时判定，端点内完成 | **长时状态机**（注销冷静期跨天）与**异步任务**（导出） |
| 可逆性 | 全部幂等可重放 | 注销生效**不可逆**，且撤销是一个独立动作 |

把两套相反的纪律塞进 `auth.md`，读者无法判断哪条管哪个端点——这与拒绝把 `purchase` 并入 `profile-sync` 是同一条理由。

**实名 / 时段不需要端点，注销 / 导出需要。** 前两者是**拦截**，走错误码即可；后两者是**玩家主动发起的操作**。它们不能省：PIPL 明确要求删除权与可携带权，国内应用商店审核亦查「App 内可注销」。

## 2. 端点集：六个

```
POST   /v1/compliance/realname          提交实名                —— 无鉴权，凭 complianceTicket
GET    /v1/compliance/status            查当前合规态             —— 需鉴权
POST   /v1/compliance/deletion          申请注销 → status = pendingDeletion   —— 需鉴权
POST   /v1/compliance/deletion/cancel   撤销注销申请             —— 需鉴权 或 凭 complianceTicket
POST   /v1/compliance/export            申请数据导出（异步任务）  —— 需鉴权
GET    /v1/compliance/export/{taskId}   查导出任务状态与下载链接  —— 需鉴权
```

**撤销注销走 `POST .../cancel` 而非 `DELETE`。** 免 token 态是这个端点存在的唯一理由，而 `envelope.md` §4a 的判据要求免鉴权端点的凭据**在 body 里**随请求送达；`DELETE` 携带 body 在 HTTP 规范中语义未定义，中间层剥离 body 是常见行为。一个「判据要求带 body、方法却不保证 body 能到达」的端点是结构性隐患。改用 `POST` 后端点数量、鉴权形态与判据均不变。

**`GET /v1/compliance/status` 与「不设 `/v1/auth/me`」不冲突。** `auth/me` 被否的理由是 `AccountInfo` 本就随 `/v1/profile/pull` 整聚合下行，再立一个读取端点即两份真值。而**合规态没有任何下行通道**：`account.status` 不跨边界（`auth.md` §1a）、实名状态含个人信息不得进玩家可导出的 profile、时段剩余会在会话中途变化。**没有第一份真值，就谈不上第二份。**

**六端点的报文字段表见 §10，端点自身的错误码见 §11。** 本节只定端点集与鉴权形态。

## 3. `complianceTicket`：无 token 态的凭据（承重）

拦截发生在 `signin`，因此**被拦住的玩家手里没有 access token**，调不动任何需鉴权的端点。解法不引入新机制：**拦截错误的 `detail` 携带一次性 `complianceTicket`**，对应端点无鉴权、凭 ticket 认账号。

`refresh`（凭据在 body）· `challenge` · `signin` 已是「无鉴权 + 凭据在 body」的先例。ticket 天然限定用途、账号与寿命，比 token scope 窄得多。

- **两处签发**：`compliance.realname_required`（走 `POST /v1/compliance/realname`）· `compliance.account_deleting`（走 `POST /v1/compliance/deletion/cancel`）。
- **一次性**：消费后即失效；寿命见 §9。
- **ticket 不是 token**：不进 `Authorization` 头，不可用于任何其他端点，不携带任何权限维度。
- **兑付成功后不签发 token。** 玩家重走完整 `signin`——强更闸门与合规判定的唯一落地点是 `signin`（`auth.md` §5 §5a），从合规端点签发会话会造出第二个绕开闸门的出口，且会让 ticket 事实上成为一个 scope 受限凭据。代价有界且极小：`Phone` 渠道的玩家多收一条短信，而实名是每账号一生一次的动作；第三方渠道的 `authCode` 可再取，零成本。

**兑付的 60 秒回放窗口。** 弱网下「请求已达、应答丢失」是常态，客户端持同一 ticket 重试会撞上「已消费」——而它其实已经成功了。因此：**首次成功后的 60 秒内，同一 ticket 的兑付原样回放上次应答，不再消费、不产生任何副作用；窗口外再次到达 → `compliance.ticket_invalid` + `reasonKey: "Consumed"`。**

这不削弱「一次性」——回放不消费、无副作用，窗口外即终态。它与 refresh 宽限窗口（`auth.md` §4）、`signin` 幂等回放（`auth.md` §4a）、`pushId` 重放（`profile-sync.md` §9）是**同一模式在本域的第四次兑现**，同值同理由：窗口须覆盖客户端指数退避的头几次重试。

> **为什么不给 scope 受限 token。** 那要为一个域引入一整套授权维度，而 `auth.md` §2 的双 token 私有模型刻意没有 scope。ticket 用既有先例即可覆盖，且它的滥用面被「一次性 + 10 分钟 + 单端点」三重夹住。

**无鉴权例外的判据见 `envelope.md` §4a**：例外只允许给「玩家此刻不可能持有 access token」的端点，auth 前三端点与本域两个 ticket 端点同源。

## 4. 拦截只在 `signin`（承重）

**`compliance.*` 作为登录拦截，只在 `POST /v1/auth/signin` 的应答中出现；业务端点一律不返回。** 完整论证与并列纪律见 `auth.md` §5。

**本纪律约束的是「拦截」，不是 `compliance.` 这个前缀。** 合规域端点自身的操作错误（ticket 过期、核验拒绝、冷静期已过、导出任务不存在）另有码，**见 §11**，并已登记进 `envelope.md` §6 台账。

## 5. `compliance.*` 四条拦截码

台账在 `envelope.md` §6（`class` · `OpError` · 客户端处置 · `detail` 形状 · `message` 必含项五列），此处只写它们各自的 `reasonKey` 取值与理由。

**四条全为 `Fatal`**（重试同一次 `signin` 不会改变结果），**全映 `OpError.Compliance`**——与客户端 `account-service` 的既定映射逐条对上。

| `code` | `reasonKey` 取值 | 触发 |
|---|---|---|
| `compliance.realname_required` | `NotSubmitted` | 从未提交实名 |
| | `VerificationFailed` | 已提交但核验未通过（姓名 / 证件号不匹配） |
| | `VerificationPending` | 核验异步未回。**仍是 `Fatal`**——重试同一次 `signin` 不改变结果，玩家应稍后重新登录 |
| `compliance.playtime_blocked` | `MinorCurfew` | 未成年人处于非允许时段 |
| | `MinorDailyLimit` | 当日允许时长已用尽 |
| `compliance.account_restricted` | `UnderReview` | 风控观察中（`status = restricted`） |
| | `Banned` | 封禁（`status = banned`） |
| `compliance.account_deleting` | `CoolingOff` | 注销冷静期内，可撤销 |

**`restricted` 与 `banned` 共用一个 `code`，靠 `reasonKey` 分辨。** 它们的玩家处置相同（无法进入，看措辞不同），拆两个 `code` 会让客户端处置表多一行却走同一条路径——`reasonKey` 正是为这种「同处置、异措辞」而设。

**`MinorCurfew` 与 `MinorDailyLimit` 分列**，尽管现行国内口径下二者几乎重合（那一小时既是时段也是全部时长）：措辞不同（「现在不是可游玩时段」vs「今天的时长已用完」），且监管口径变动时不必改 `code`。

`reasonKey` 的形态与二级文案键的机械变换规则见 `auth.md` §10——**三处 `reasonKey` 共用同一套规则，本文件不另立**。

**`compliance.account_restricted` 的取值表首版不扩。** 风控三档处置对玩家没有可执行差异（掷骰复算异常与昵称违规的出路同为站外申诉），而告知判据的具体维度等于把判据外泄、反向指导规避；昵称违规的处置也不落 `restricted`，它走 §10 的 `nicknameChangeRequired` 标记（`operations/moderation.md` 的存量扫描与复核通道）。日后确需区分时扩表是纯增量——新增 `reasonKey` 不要求客户端同批发版（`envelope.md` §5b）。

## 6. 时段口径不写进契约（承重）

**契约只给 `reasonKey` 与 `resumeAtUtc`，具体时段表落后端配置**（归 `operations/`）。监管口径变动时不必改契约、不必发版，与 pillar #5「线上可干预」一致。

现行国内口径（未成年人仅周五 / 六 / 日与法定节假日 20:00–21:00 可玩）可作**说明性注释**写入 `operations/`，但**不具规范性**——写进契约即成为第二权威，而它恰恰是最容易被监管变动推翻的那一条。

**时段判定的时间源必须是可信的服务端时钟。** `envelope.md` §4b 已定 `X-Server-Time` 仅供诊断、设备时钟不可信；时段判定若读设备时钟，改一次系统时间即绕过。时钟源的实现形态归 `06`。

## 7. 防沉迷中途到点：复用 `auth.session_revoked`

防沉迷是三条合规能力里唯一**会在会话中途到点**的。它看起来需要一条「会话中途的拦截通道」，而那条通道被 `envelope.md` §7b（仅两处硬阻塞）与 `profile-sync.md` §11（同步通道不承载合规拦截）双重封死。

**映射进已有的两条路径，一个字段都不加：**

1. 已判定为未成年的账号，`signin` 签发的 access token TTL 取 `min(15 分钟, 距时段结束的剩余秒数)`；
2. 时段结束 → token 自然过期 → 客户端按既定路径静默 `refresh`；
3. 服务端在 `refresh` 时发现已出时段 → 吊销该账号全部会话 → `auth.session_revoked` + `reasonKey = "PlaytimeEnded"`；
4. 客户端走既定「被挤下线」路径：硬阻塞重登 + 暂停退避 + **本地缓冲保留**；
5. 玩家重登 → `signin` 返回 `compliance.playtime_blocked` + `detail.resumeAtUtc`。

四条既有约束同时满足：`refresh` 的错误清单仍是两条（`auth.md` §8）· 「绝不回退存档点」成立（`session_revoked` 的既定处置就是保留缓冲、重登后先 pull 后 flush）· 强制下线的时间精度 = 0（TTL 卡在时段边界，不是 15 分钟的最坏延迟）· 不新增端点 / 报文字段 / 客户端路径。

> `auth.md` §2 那句「access token TTL = 被挤下线的最坏生效延迟」的论证在此直接复用：**两者都是服务端单方面终止会话，本就该走同一条路。**

**未成年判定的数据源是实名核验返回的出生日期**，不单独存年龄——年龄会过期，出生日期不会；且它已随核验回来，不必二次采集。

## 8. 数据导出的最简形态

**首版必做，取最简形态**：异步生成一份 JSON，含 profile 明文 + 账号元数据。合规要求通常在过审阶段才显形，届时补做会挤在发版窗口里。

**产物是一份正列白名单，不写排除列表**——排除列表会在新增内部字段时静默漏项，而这是一份直接交到玩家手里的文件。

```
单个 UTF-8 JSON 文件
├─ profile   ← 整份 profile 原样（后端半透明，不重排、不裁剪）
└─ account   ← accountId · createdAtUtc · identities[]（每条仅 channel 与 boundAtUtc）
```

由白名单直接得出：产物**不含**渠道内部键（`channelUserId` / `idKind`）· `sid` · `deviceId` · 任何会话 / token 材料 · 姓名 / 证件号 / 出生日期。前者承 `auth.md` §1a「服务端内部键不跨边界」；后者的理由独立且同样承重——**实名材料是核验的输入，不是玩家的游戏进度**，把它放进导出物等于把最敏感的那一项重新交出去一次。

导出产物含个人信息，链接有效期见 §9。产物的存储形态与链接签发方式归 `06`。

## 9. 数值初值（可调旋钮，非硬编码）

| 旋钮 | 初值 | 推导 |
|---|---|---|
| `complianceTicket` 寿命 | **10 分钟** | 覆盖一次实名表单填写 + 一次重试；远短于 refresh token，泄漏面可忽略 |
| 注销冷静期 | **15 天** | 国内通行区间 7–15 天，取上界：「误触注销」的代价是**永久丢失全部进度**（云端权威下无本地兜底），而多给 8 天的代价只是一行配置 |
| 导出任务保留期 | **7 天** | 下载链接有效期；导出产物含个人信息，不宜长留 |
| 未成年 access token TTL | `min(15 分钟, 距时段结束剩余)` | §7；上界沿用 `auth.md` §8 的既有初值 |
| ticket 兑付回放窗口 | **60 秒** | 与 `auth.md` §8 的 refresh 宽限窗口 / `signin` 幂等回放窗口同值同理由——覆盖客户端指数退避的头几次重试（§3） |
| 实名提交次数上限 | **5 次 / 账号 / 天** | 覆盖一次输入失误加数次重试；核验按次计费，且「提交姓名 + 证件号看是否匹配」本身是撞库面。**本端点必须限流**是契约层声明，与 `auth.md` 对 `challenge` 的处理同构 |
| 导出申请限流 | **1 次 / 账号 / 24 小时** | 生成是重操作且产物含个人信息；PIPL 只要求可携带，不要求高频 |
| 导出任务**记录**保留期 | **30 天** | 产物本身 7 天。记录多留使 `Expired` 与 `resource.not_found` 可区分（§10），成本是一行元数据 |
| 导出任务建议轮询间隔 | **5 秒** | `pollAfterSeconds` 的初值；生成一份 JSON 的量级。待实测校准 |

**落点是后端配置而非代码常量**，与 `auth.md` §8 的旋钮同处。

## 10. 六端点的报文字段表

> 字段形态在 `openapi.yaml` 覆盖本域后以 spec 为准，语义以本文件为准；在此之前本节的类型 / 必填列属草案（`envelope.md` §1）。
> 序列化与命名照 `envelope.md` §2：lowerCamelCase · 枚举为字符串且与客户端 C# 成员名逐字相同 · 时间 RFC 3339 UTC 带 `Z` 且字段名以 `AtUtc` 结尾 · **不下发 `null`，可选字段缺席即省略**。

### 共有取值：`ComplianceRealnameStatus`

| 取值 | 语义 | 对应 `compliance.realname_required` 的 `reasonKey` |
|---|---|---|
| `NotSubmitted` | 从未提交 | `NotSubmitted` |
| `Pending` | 已提交，核验异步未回 | `VerificationPending` |
| `Verified` | 核验通过 | —（不再拦截） |
| `Failed` | 已提交但核验未通过 | `VerificationFailed` |

**取值与 §5 的 `reasonKey` 表机械对应但不同名。** `reasonKey` 是**拦截**语境的词汇（`VerificationPending` 读作「因为核验未回所以拦你」），状态字段是**状态**语境的词汇；强行同名会把一张封定的表拖进新语境。

### `POST /v1/compliance/realname`

请求：无 `Authorization`；带 `X-App-Version` / `X-Request-Id`，`X-Content-Version` 可缺省（与 `auth.md` §6 的无 token 端点同档）。

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `complianceTicket` | string | ✅ | 取自 `compliance.realname_required` 的 `detail`（§3）。一次性，60 秒回放窗口见 §3 |
| `realName` | string | ✅ | 姓名。**永不回显、永不进任何应答、永不进日志**（`envelope.md` §5a 的脱敏纪律） |
| `idNumber` | string | ✅ | 证件号。同上 |

应答 `200`：

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `realnameStatus` | string | ✅ | `ComplianceRealnameStatus`；本端点可回 `Verified` / `Pending`（`Failed` 走 §11 的错误码） |
| `isMinor` | boolean | 可选 | 缺席即 `false`。仅在 `Verified` 时可能出现。由核验返回的出生日期算得，**出生日期本身永不下发** |

- **只接受 ticket 态，不接受已登录态。** 实名未完成的账号在 `signin` 必被拦，「已登录且未实名」在结构上不存在；给它开一条鉴权态入口是为不可达情形加一条路径。
- **不设 `deviceId`**：本端点不签发会话，多设备裁决与它无关。
- **不设证件类型字段**：首版仅支持中国大陆居民身份证。扩展时追加一个可选字段（缺席即默认），不是破坏性变更——与 `auth.md` §3 对密码路线的处理同一条。
- **重复提交幂等**：已 `Verified` 的账号再次提交回 `200` 与 `Verified`，**不重复调用核验服务**（按次计费）。

错误：`compliance.ticket_invalid` · `compliance.verification_failed` · `rate.limited` · `server.unavailable`（核验服务不可达）。**不返回**四条 `compliance.*` 拦截码（§4）。

### `GET /v1/compliance/status`

请求：需鉴权，无 body、无 query 参数（账号取自 `Authorization`，同 `profile-sync.md`「`accountId` 绝不进 query / body」）。**应答须带 `no-cache`**——合规态会在会话中途变化，这正是本端点存在的理由（§2）。

应答 `200`：

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `realnameStatus` | string | ✅ | `ComplianceRealnameStatus` |
| `isMinor` | boolean | 可选 | 缺席即 `false` |
| `playtimeRemainingSeconds` | number | 可选 | 仅未成年账号下发。当前时段内剩余可游玩秒数，**服务端按可信时钟算好**（§6）。相对量而非时刻 ⇒ 客户端做倒计时无需任何本地时钟比较 |
| `playtimeResumeAtUtc` | string | 可选 | 仅未成年账号且当前不在允许时段内时下发。与 `compliance.playtime_blocked` 的 `detail.resumeAtUtc` 同名同义 |
| `deletionEffectiveAtUtc` | string | 可选 | **存在即处于注销冷静期**，缺席即不在。这是 `pendingDeletion` 这一事实的**唯一**跨边界形态 |
| `nicknameChangeRequired` | boolean | 可选 | 缺席即 `false`。为真表示该账号须改一个合规昵称才算解除处置。判定与清零语义见 `operations/moderation.md` 的存量扫描；**不带 `reasonKey`**——三档处置对玩家无可执行差异（§5） |

- **不下发**：`account.status`（`auth.md` §1a）· 时段表与规则本身（§6）· 出生日期 · 最近一次导出任务的 `taskId`（客户端持有；丢失即重新 `POST export`）。
- `playtimeRemainingSeconds` 使时段到点从一次硬阻塞变成一次有预告的软着陆——与 `auth.md` §5b 为绝对寿命上限配 `reauthRecommended` 软信号是同一个取舍。字段成本近乎为零：服务端本就要算它才能判时段。呈现形态归客户端库（`game-design-documents/ux/error-and-blocking-ux.md`），本库不代为决定。

错误：`server.unavailable`（及信封通则的 `auth.token_expired` / `auth.token_invalid`）。

### `POST /v1/compliance/deletion`

请求：需鉴权，**无 body**。二次确认是客户端 UI 的职责，不进契约。

应答 `200`：

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `deletionEffectiveAtUtc` | string | ✅ | 冷静期结束、注销生效的时刻（冷静期 15 天，§9） |
| `deduplicated` | boolean | 可选 | 缺席即 `false`。已在冷静期内重复申请时为 `true`，`deletionEffectiveAtUtc` 与首次逐字相同 |

- **重复申请绝不顺延冷静期**：顺延会让弱网重试无声地推迟玩家的注销生效时刻，与 pillar #2 的幂等纪律相抵。
- **不吊销任何会话。** 冷静期内数据尚未删除，玩家可继续游玩；强行吊销会凭空造出一次硬阻塞（`envelope.md` §7b + pillar #4）并要为它新开一个 `reasonKey`。下次 `signin` 由 `compliance.account_deleting` 拦住并给撤销 ticket。
- `restricted` / `banned` 的账号**同样可以申请注销**：PIPL 的删除权不因风控状态而消失。

错误：`rate.limited` · `server.unavailable`。

### `POST /v1/compliance/deletion/cancel`

请求：需鉴权**或**凭 ticket（二者取其一，都不带即拒）。

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `complianceTicket` | string | 可选 | 取自 `compliance.account_deleting` 的 `detail`（§3）。带 `Authorization` 时不需要；两者都不带 → `compliance.ticket_invalid` + `reasonKey: "Unknown"` |

应答 `204`，**幂等**：撤销一个不存在的注销申请同样回 `204`（同 `auth.md` §7 对 `signout` / `unbind` 的纪律）。ticket 态的重放走 §3 的 60 秒窗口。

错误：`compliance.ticket_invalid` · `compliance.deletion_irrevocable` · `server.unavailable`。

### `POST /v1/compliance/export`

请求：需鉴权，**无 body**。

应答 `200`：

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `taskId` | string | ✅ | 形态见下 |
| `status` | string | ✅ | 新建任务恒为 `Pending`；命中既有任务时为该任务的当前状态 |
| `deduplicated` | boolean | 可选 | 缺席即 `false`。命中既有未过期的 `Pending` / `Ready` 任务时为 `true`，`taskId` 与首次逐字相同 |
| `pollAfterSeconds` | number | 可选 | 建议轮询间隔。**节奏由服务端给，客户端不硬编码**——与 `auth.md` §8 `challenge` 的 `resendAfterSeconds` 同构 |

- 幂等命中同时解决「客户端丢失 `taskId`（重装 / 换设备）后如何找回」：重新 `POST` 即可，**不新增任务列表端点**（那个端点没有第二个消费面）。
- 上一个任务为 `Failed` / `Expired` 时建新任务、给新 `taskId`，`deduplicated` 缺席。

错误：`rate.limited` · `server.unavailable`。

### `GET /v1/compliance/export/{taskId}`

请求：需鉴权，`taskId` 在 path。**必须校验任务归属当前账号；不归属时回 `resource.not_found`** 而非「无权访问」——后者会泄漏 `taskId` 的存在性。

应答 `200`：

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `taskId` | string | ✅ | 回显 |
| `status` | string | ✅ | 导出任务状态机四值，见下 |
| `requestedAtUtc` | string | ✅ | 申请时刻 |
| `pollAfterSeconds` | number | 可选 | 仅 `Pending` 时下发 |
| `downloadUrl` | string | 可选 | 仅 `Ready` 时下发。绝对 HTTPS URL，签名在 URL 内、无鉴权可直下，客户端用系统浏览器 / 下载器打开，那条请求不带 `Authorization` |
| `downloadExpiresAtUtc` | string | 可选 | 仅 `Ready` 时下发。产物保留期 7 天（§9） |
| `sizeBytes` | number | 可选 | 仅 `Ready` 时下发。移动网络下下载前告知体积；产物是单份 JSON，永不接近 2⁵³ ⇒ 走 number 而非字符串（`envelope.md` §2 判据） |

**`downloadUrl` 指向的是外部对象，不是本 API 的端点，因此不进 spec 的 `paths`。** 这一句必须写下：`_index.md` 的机检断言③校验「markdown 中出现的每个 `METHOD 路径` ⇔ spec 的 `paths` 键」，不写明会被误判成漏项。链接签发与产物存储归 `06`（§8）。

**状态一律走应答体的 `status` 字段，不靠 HTTP 状态码表达**：导出申请回 `200` 而非 `202`，因为客户端不得靠状态码分支（`envelope.md` §5b）。

错误：`resource.not_found` · `server.unavailable`。

### `taskId` 形态：`^[0-9a-f]{32}$`

32 位小写十六进制，**定长 · 无前缀 · 无分隔符** ⇒ 两侧不需要对大小写或分隔符做归一；**URL 安全**（直接进 path 段，无需转义）；与 `accountSeed`（16 位小写 hex）同向。

**不用 ULID**：时间前缀会泄漏任务的申请时刻与相对顺序。**不可枚举性是纵深防御，不是访问控制**——访问控制靠上面那条归属校验。

### 导出任务状态机：四个取值

| 取值 | 语义 | 客户端处置 |
|---|---|---|
| `Pending` | 已受理、产物尚未就绪（含排队与生成中） | 按 `pollAfterSeconds` 继续轮询 |
| `Ready` | 产物就绪，`downloadUrl` 与 `downloadExpiresAtUtc` 同批下发 | 呈现下载入口 |
| `Failed` | 生成失败，终态 | 呈现「生成失败，请重新申请」 |
| `Expired` | 产物保留期已过，终态 | 呈现「已过期，请重新申请」 |

- **不拆 `Queued` / `Running`**：客户端处置逐字相同（继续轮询），拆开只让状态表多一行走同一条路径——与 `restricted` / `banned` 共用一个 `code` 是同一条判据（§5）。
- **保留 `Expired` 而不让它退化为 `resource.not_found`**：玩家几天后回来点旧入口时，「已过期，重新申请一次」与「找不到」是两句完全不同的话。代价是任务**记录**的保留期长于**产物**的保留期（§9），成本是一行元数据。
- **`Failed` 不带 `failureReasonKey`**：全部子类对玩家是同一句话、同一个动作（重新申请）。日后确有分辨需求时扩表是纯增量（`ADR-0015`）。

## 11. 端点自身的错误码：只新增三条

四类待覆盖的失败面里，**三类不该新增码**：

- **核验服务不可达 / 超时 / 限流 → `server.unavailable`（`Retryable`）。** 与 `auth.md` §3a「渠道不可达 ≠ 明确拒绝」、`purchase.md` §3「平台不可达须与『收据无效』在报文层面可区分」同源：报成 `Fatal` 会让客户端把一次抖动当成终态，让玩家重填一遍身份证号。它也**不能**混进本域——本域三条码全为 `Fatal`，掺一条 `Retryable` 会破坏客户端「`Compliance` 档 = 不可重试」的静态推理。
- **导出任务不存在 → 既有 `resource.not_found`**（`detail { resource }`）。同 `auth.md` §9「不新增 `auth.account_not_found`」的判断。
- **「任务未就绪」不是错误**：`GET export/{taskId}` 回 `200` + `status: "Pending"`。
- 实名提交 / 导出申请的频次超限 → 既有 `rate.limited`。

**新增三条**（五列台账在 `envelope.md` §6，此处只写取值与理由）：

| `code` | 覆盖 | 为什么必须新增 |
|---|---|---|
| `compliance.ticket_invalid` | ticket 过期 / 已消费 / 未知 | 三种情形的客户端处置完全相同（回登录屏重新登录以取得新 ticket），靠 `reasonKey` 分辨措辞 |
| `compliance.verification_failed` | 核验服务**明确拒绝**（姓名 / 证件号不匹配、格式非法） | 必须与「核验服务不可达」在报文层面可区分，否则客户端无从判断该不该重试 |
| `compliance.deletion_irrevocable` | 冷静期已过 / 注销已进入不可逆执行，撤销请求来晚了 | 与「没有申请过」（回 `204`）必须可区分：一个是「你已经不在冷静期了」，一个是「本来就没这回事」 |

三条**全为 `Fatal`**、**全映 `OpError.Compliance`**，与客户端 `account-service` 的既定映射一致。它们是端点自身的操作错误，不受「拦截只在 `signin`」约束（§4）。

`reasonKey` 取值（PascalCase，`ADR-0015`；形态与二级文案键的变换规则见 `auth.md` §10）：

| `code` | 取值 | 触发 |
|---|---|---|
| `compliance.ticket_invalid` | `Expired` | ticket 超出 10 分钟寿命（§9） |
| | `Consumed` | 已被兑付且落在 60 秒回放窗口之外（§3） |
| | `Unknown` | 无法识别 / 伪造 / 与账号不匹配 / 用于非签发它的那个端点 |
| `compliance.verification_failed` | `Mismatch` | 姓名与证件号不匹配 |
| | `Malformed` | 证件号格式非法（服务端兜底；客户端只做长度与字符集这类无争议的输入约束，与 `auth.md` §8 昵称的 `Malformed` 同构） |
| `compliance.deletion_irrevocable` | — | **不设 `reasonKey`**：只有一种情形 |

**对客户端零机械义务**：未知 `code` 按 `class` 降级、未知 `reasonKey` 回落一级键，三条新码不要求客户端同批发版（`envelope.md` §5b、`ADR-0015`）。`verification_failed` 的「重填表单」处置与 `OpError.Compliance` 的阻塞语义不冲突——客户端的映射是逐 `code` 表，`OpError` 只作兜底。

## 备选方案（已考虑并否决）

- **合规拦截落在业务端点** — 会在轮回中途硬拒，撞 `envelope.md` §7b 与 pillar #4；且业务端点的错误清单会各自长出一份 `compliance.*`，等于把一个横切关注点复制到每一份契约。
- **合规拦截落在 `/v1/profile/*`** — `profile-sync.md` §11 已封死：同步通道上返回合规拦截，客户端只剩「待同步 N 永不减」或「丢进度」两条路。
- **为防沉迷时段新增一条会话中途拦截通道**（给 `refresh` 加第三个 `code`，或加一个心跳端点）— 前者破坏 `auth.md` §8 刻意收紧的两码互斥，使客户端两条处置路径的判据变得有歧义；后者为一条罕见路径新增一个高频端点，且心跳失败的语义与断线不可区分。
- **实名作为建号前置** — 造出「半个账号」（实名信息无处挂），并把 `auth.md` §1a 的原子建号拆成两步；而 `accountId` 不含个人信息，早建号无任何暴露面。
- **`signin` 未实名时签发 scope 受限 token** — 为一个域引入整套 scope 授权维度，而双 token 私有模型刻意没有它；`complianceTicket` 用既有的「无鉴权 + body 凭据」先例即可覆盖（§3）。
- **`restricted` 与 `banned` 各给一个 `code`** — 玩家处置完全相同（进不去、看措辞），拆开只是让客户端处置表多一行走同一条路径。
- **注销 / 导出扩进 auth 域，成为第八、九个端点** — 长时状态机与异步任务的纪律与 auth 域「即时幂等判定」相反，塞进同一份文档后读者无法判断哪条纪律管哪个端点。
- **注销 / 导出走站外（官网 / 客服）** — 国内应用商店审核查「App 内可注销」；且站外流程需要另一套身份核验，成本高于一个端点。
- **合规态随 `AccountInfo` 下行** — 与 `account.status` 被否的理由逐字相同（会话中途过期的第二真值），且实名状态含个人信息，进 profile 即进玩家可导出的存档。
- **把现行时段口径写进契约** — 它是最容易被监管变动推翻的一条，写死即成为第二权威且要求发版才能改（§6）。
- **导出产物含渠道内部键以便客服排障** — 排障有服务端日志，而导出物是交到玩家手里的；把 `channelUserId` 放进去等于把内部键跨边界（§8）。
- **保留 `DELETE /v1/compliance/deletion` 并把 ticket 放进 query 参数** — 凭据进 URL 会落进网关 / CDN / 代理的访问日志，且与 `envelope.md` §4a「凭据只能在 body 里随请求送达」直接相反。
- **保留 `DELETE` + body，靠部署时确认全链路不剥离 body** — 把一条协议正确性押在部署环境的行为上，而免 token 态是这个端点存在的唯一理由。
- **实名 / 撤销端点的应答直接签发 token 对** — 省一条短信，但让 ticket 事实上成为 scope 受限凭据（§3 与 `ADR-0016` 否决的形态），并造出第二个绕开强更闸门的出口。
- **给 `complianceTicket` 一个「可换一次 `signin`」的兑换语义** — 换个名字的同一件事，且要为它新开一条求值路径。
- **实名端点同时接受鉴权态** — 「已登录且未实名」在结构上不存在（`signin` 必拦），为不可达情形加一条路径。
- **拆 `Queued` / `Running` 两个任务状态** — 客户端处置逐字相同，只让状态表多一行走同一条路径。
- **`Failed` 带 `failureReasonKey`** — 全部子类对玩家是同一句话、同一个动作。
- **为「导出任务不存在」新增 `compliance.export_task_not_found`** — 既有 `resource.not_found` 逐字覆盖。
- **为「核验服务不可达」新增一条 `compliance.*` 码** — 它是 `Retryable`，混进全为 `Fatal` 的本域会破坏客户端「`Compliance` 档 = 不可重试」的静态推理。
- **`GET /v1/compliance/status` 携带最近一次 `taskId`** — 让查合规态的端点兼职任务列表，两处形态从此要同步演进。
- **新增「列出我的导出任务」端点** — `POST export` 的幂等已覆盖「丢失 `taskId`」这唯一用例。
- **导出申请回 `202 Accepted`** — 客户端不得靠 HTTP 状态码分支（`envelope.md` §5b）；状态已在 `status` 字段里。
- **`taskId` 用 ULID** — 时间前缀泄漏申请时刻与相对顺序，且与两侧既有的「定长小写 hex」形态不齐。
- **应答下发出生日期供客户端自行判定未成年** — 把最敏感的一项个人信息跨边界，且判定权应与可信时钟同处服务端。
- **申请注销即吊销全部会话** — 凭空造出一次硬阻塞，且冷静期的本意就是「还没删，随时可以反悔」。
- **重复 `POST deletion` 顺延冷静期** — 弱网重试会无声推迟玩家的注销生效时刻。
- **导出产物写排除列表而非正列白名单** — 新增内部字段时静默漏项，而这是一份直接交到玩家手里的文件。

## Open questions

- **可信服务端时钟的形态**、**实名核验服务商与灾备**、**导出产物的存储与链接签发**、**`complianceTicket` 的存储与一次性消费保证**、**冷静期这条跨天长时状态机的调度形态**——均归 `06`，落 `operations/`。契约层只声明语义。
- **旋钮初值待实测校准**：实名提交次数上限 · 导出申请限流 · `pollAfterSeconds`。与 §9 既有四个旋钮同档，不阻塞契约成文。

## 跨库待办（客户端侧，本库不代为决定）

`ComplianceManager` 的覆盖面切分（哪些拦截由它呈现、哪些落在登录屏本身）归 `game-design-documents/systems/services/account-service.md`；`compliance.*` 四条拦截码、§11 三条端点错误码与各自 `reasonKey` 的玩家可见措辞归 `game-design-documents/ux/error-and-blocking-ux.md`；`playtimeRemainingSeconds` 的倒计时呈现形态与「须改名」流程落在哪一屏，归 `game-design-documents/systems/services/account-service.md`。**本库只定边界另一侧的报文。**
