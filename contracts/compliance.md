# compliance —— 实名 · 防沉迷 · 注销 · 数据导出

> 覆盖 `/v1/compliance/…` 六个端点，以及 `compliance.*` 错误码在整个 API 面的落地规则。
> **边界层不在此重复**：序列化与命名约定、`/v1/` 主版本、传输信封、错误体形状、版本协商——全部见 `envelope.md`。
> 拦截发生在 `signin`，故 `auth.md` §5 与本文件互为对位：**那里定「什么时候拦」，这里定「拦住之后玩家怎么走出去」**。
> 客户端侧门面见 `game-design-documents/systems/services/account-service.md`。
> Source: `handoffs/2026-08-16c-compliance-contract-and-session-arbitration.md`。

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
DELETE /v1/compliance/deletion          撤销注销申请             —— 需鉴权 或 凭 complianceTicket
POST   /v1/compliance/export            申请数据导出（异步任务）  —— 需鉴权
GET    /v1/compliance/export/{taskId}   查导出任务状态与下载链接  —— 需鉴权
```

**`GET /v1/compliance/status` 与「不设 `/v1/auth/me`」不冲突。** `auth/me` 被否的理由是 `AccountInfo` 本就随 `/v1/profile/pull` 整聚合下行，再立一个读取端点即两份真值。而**合规态没有任何下行通道**：`account.status` 不跨边界（`auth.md` §1a）、实名状态含个人信息不得进玩家可导出的 profile、时段剩余会在会话中途变化。**没有第一份真值，就谈不上第二份。**

**六端点的报文字段表尚未落笔**（见文末 Open questions）——它应由一次正式的契约变更承担（`_index.md`「契约变更的完成判据」四条），本文件先定端点集、语义与承重纪律。

## 3. `complianceTicket`：无 token 态的凭据（承重）

拦截发生在 `signin`，因此**被拦住的玩家手里没有 access token**，调不动任何需鉴权的端点。解法不引入新机制：**拦截错误的 `detail` 携带一次性 `complianceTicket`**，对应端点无鉴权、凭 ticket 认账号。

`refresh`（凭据在 body）· `challenge` · `signin` 已是「无鉴权 + 凭据在 body」的先例。ticket 天然限定用途、账号与寿命，比 token scope 窄得多。

- **两处签发**：`compliance.realname_required`（走 `POST /v1/compliance/realname`）· `compliance.account_deleting`（走 `DELETE /v1/compliance/deletion`）。
- **一次性**：消费后即失效；寿命见 §6。
- **ticket 不是 token**：不进 `Authorization` 头，不可用于任何其他端点，不携带任何权限维度。

> **为什么不给 scope 受限 token。** 那要为一个域引入一整套授权维度，而 `auth.md` §2 的双 token 私有模型刻意没有 scope。ticket 用既有先例即可覆盖，且它的滥用面被「一次性 + 10 分钟 + 单端点」三重夹住。

**无鉴权例外的判据见 `envelope.md` §4a**：例外只允许给「玩家此刻不可能持有 access token」的端点，auth 前三端点与本域两个 ticket 端点同源。

## 4. 拦截只在 `signin`（承重）

**`compliance.*` 作为登录拦截，只在 `POST /v1/auth/signin` 的应答中出现；业务端点一律不返回。** 完整论证与并列纪律见 `auth.md` §5。

**本纪律约束的是「拦截」，不是 `compliance.` 这个前缀。** 合规域端点自身的操作错误（ticket 过期、核验拒绝、冷静期已过、导出任务不存在）另有码，随本文件的报文本体一并落笔并登记进 `envelope.md` §6 台账。

## 5. `compliance.*` 四条码

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

**不含任何渠道内部键。** `channelUserId` / `idKind` 已定不进玩家可导出物（`auth.md` §1a），导出是「玩家可导出物」的字面兑现，这条对它同样成立。

导出产物含个人信息，链接有效期见 §9。产物的存储形态与链接签发方式归 `06`。

## 9. 数值初值（可调旋钮，非硬编码）

| 旋钮 | 初值 | 推导 |
|---|---|---|
| `complianceTicket` 寿命 | **10 分钟** | 覆盖一次实名表单填写 + 一次重试；远短于 refresh token，泄漏面可忽略 |
| 注销冷静期 | **15 天** | 国内通行区间 7–15 天，取上界：「误触注销」的代价是**永久丢失全部进度**（云端权威下无本地兜底），而多给 8 天的代价只是一行配置 |
| 导出任务保留期 | **7 天** | 下载链接有效期；导出产物含个人信息，不宜长留 |
| 未成年 access token TTL | `min(15 分钟, 距时段结束剩余)` | §7；上界沿用 `auth.md` §8 的既有初值 |

**落点是后端配置而非代码常量**，与 `auth.md` §8 的旋钮同处。

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

## Open questions

- **六端点的报文字段表**——请求 / 应答字段、`taskId` 形态、导出任务的状态机取值。应由一次正式的契约变更落笔，与 `openapi.yaml` 的对应 `paths` 同批。
- **合规域端点自身的错误码**——ticket 过期 / 已消费、核验服务拒绝、冷静期已过、导出任务不存在 / 未就绪。随上一条落笔并登记进 `envelope.md` §6 台账（§4）。
- **风控三档处置与 `reasonKey` 的对应关系**——若风控要向玩家区分「哪一类异常」，`compliance.account_restricted` 的取值表需再扩。不阻塞本文件：新增 `reasonKey` 不要求客户端同批发版（`envelope.md` §5b）。归 `02`。
- **可信服务端时钟的形态**、**实名核验服务商与灾备**、**导出产物的存储与链接签发**——均归 `06`，落 `operations/`。契约层只声明语义。

## 跨库待办（客户端侧，本库不代为决定）

`ComplianceManager` 的覆盖面切分（哪些拦截由它呈现、哪些落在登录屏本身）归 `game-design-documents/systems/services/account-service.md`；`compliance.*` 四条码与各自 `reasonKey` 的玩家可见措辞归 `game-design-documents/ux/error-and-blocking-ux.md`。**本库只定边界另一侧的报文。**
