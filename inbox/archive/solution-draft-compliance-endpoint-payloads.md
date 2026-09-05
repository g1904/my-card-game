---
type: solution-draft
date: 2026-09-02
question: `contracts/compliance.md` 六端点的报文字段表（含 `taskId` 形态与导出任务状态机取值）与合规域端点自身的错误码尚未落笔
source: open-questions/01-contracts.md → 第 2 条「合规域端点自身的错误码（随报文本体落笔，非设计未决）」；背景见 open-questions.md「最短解锁路径」第 1 项
targets: contracts/compliance.md（§2 端点集一行 · 新增报文字段表节 · §5 旁的端点错误码节 · §9 旋钮表增行）· contracts/envelope.md（§3 端点清单一行 · §4a 例外表一行 · §6 台账新增三行）· decisions/ADR-0016（例外表一行）· contracts/_index.md（compliance 行状态列）
status: distilled
reviewed: 2026-09-02（用户批量评审：草稿内取向与张力逐条裁决）；2026-09-03（/batch-analyze-new-ideas 合并 interview 十项裁决，见 handoff 的 Clarifications）
distilled-to: handoffs/2026-09-03-compliance-endpoint-payloads.md
---

# 方案草稿 — 合规域六端点的报文字段表与端点自身错误码

## 问题

`contracts/compliance.md` 已封定端点集、`complianceTicket` 机制、拦截落点、四条 `compliance.*` 拦截码与各自 `reasonKey`、时段口径落配置、导出的最简形态与四个旋钮初值。**两处未落笔：**

1. **六端点的报文字段表** —— 请求 / 应答字段、`taskId` 形态、数据导出任务的状态机取值；
2. **这六个端点自身的错误码** —— ticket 过期 / 已消费、核验服务拒绝、冷静期已过、导出任务不存在或未就绪。

它是本库**唯一**向客户端传导的欠账，`contracts/compliance.md` 亦是全库唯一被判 blocked 且卡点为「纯落笔」的契约。

**一处需要就地纠正的既有表述。** 本库 `open-questions.md`「derive 就绪度」小节把对侧 `game-design-documents/open-questions/cross-boundary.md`「待承接」区的唯一条目（`ComplianceManager` 覆盖面切分）记作「因本欠账而写不出验收标准」。核对对侧原文后：**该条目明写切分是客户端自己的取向、不等本库任何输入**，其关闭条件是对侧自行落笔（权威在对侧该文件及其分片抬头）。本次落笔为对侧的**报文对位**提供输入，但**不关闭**那条待承接项。两处表述的差额建议在落笔时一并修正——细节不在本草稿复述。

本草稿给出可被 `/derive-requirements` 直接消费的形态提案。**它是提案，不是定案**；落笔权在 `/analyze-new-ideas`。

## 约束（来自既有设计）

- **序列化与命名**：lowerCamelCase · 枚举为字符串且与客户端 C# 成员名逐字相同 · 时间 RFC 3339 UTC 带 `Z` 且字段名以 `AtUtc` 结尾 · **绝不下发 `null`，可选字段缺席即省略** · 两侧忽略未知字段 · 可能 > 2⁵³ 的整数走字符串。→ `envelope.md` §2
- **鉴权例外是一条判据**（「调用它的玩家此刻不可能持有 access token」），例外域两个，合规域内只有实名提交与撤销注销够格；`GET /v1/compliance/status` 是判据明写的**负例**。→ `envelope.md` §4a、`decisions/ADR-0016`
- **错误体五字段**、`class` 四值且随 `code` 恒定、**客户端不得靠 HTTP 状态码分支**、`message` 给人读 / `detail` 给代码读、`message` 必须可安全落日志。→ `envelope.md` §5 §5a §5b
- **新增 `code` 一律登记进 `envelope.md` §6 台账**，五列俱全。
- **`reasonKey` 形态 PascalCase 锁死**，二级文案键由 `code` + `reasonKey` 机械变换，未知取值退回一级键（故后端扩表不要求客户端同批发版）。→ `ADR-0015`、`auth.md` §10
- **拦截只在 `signin`**；本域端点自身的操作错误另有码，**不受该纪律约束**（`compliance.md` §4 明写「本纪律约束的是『拦截』，不是 `compliance.` 这个前缀」）。
- **`complianceTicket` 一次性 · 10 分钟 · 单端点 · 不进 `Authorization` 头**。→ `compliance.md` §3
- **服务端内部键不跨边界**：`channelUserId` · `idKind` · `sid` · `account.status` 均不出现在任何报文字段里。→ `auth.md` §1a §4a
- **时段口径不进契约**，只给 `reasonKey` 与 `resumeAtUtc`；时间源必须是可信服务端时钟。→ `compliance.md` §6
- **导出产物不含任何渠道内部键**。→ `compliance.md` §8
- **技术栈未定** ⇒ 停在协议与语义层，不指定语言 / 框架 / 存储；可信时钟、ticket 存储、冷静期状态机调度、导出产物存储与链接签发全部归 `06`。
- **pillar #2 弱网优先**：每一处写入都必须能被安全重放。

## 建议方案

### A. 一条贯穿全域的幂等纪律：ticket 兑付走 60 秒回放窗口

`[既有推演]`

`complianceTicket` 是一次性的（§3）。弱网下「请求已达、应答丢失」是常态（pillar #2），客户端持同一 ticket 重试会撞上「已消费」——**而它其实已经成功了**。这与 `signin` 的一次性验证码撞上的是同一个坑，`auth.md` §4a 已给出解法。

**建议：ticket 的兑付在首次成功后的 60 秒内可被重放，原样回放上次应答，不再消费、不产生任何副作用；窗口外再次到达 → `compliance.ticket_invalid` + `reasonKey: "Consumed"`。**

窗口取 **60 秒**，与 refresh 宽限窗口、`signin` 幂等回放窗口**同值同理由**（覆盖客户端指数退避的头几次重试）。这是 pillar #2 的同一模式在本域的第四次兑现，**不是新机制**。

### B. 兑付成功后不签发 token，玩家重走 `signin`

`[取向选择]` —— 见 `## 仍需用户决定` 第 1 条。**本草稿其余部分按「不签发」落笔。**

推荐「不签发」的依据：让 `POST /v1/compliance/realname` 的应答带上 token 对，等于让 `complianceTicket` 事实上成为一个 scope 受限凭据，而 `compliance.md` §3 与 `ADR-0016` 都明确否决了这条路；且强更闸门与合规判定的**唯一落地点是 `signin`**（`auth.md` §5 §5a），从合规端点签发 token 会造出第二个绕开闸门的出口——正是 `auth.md` §5b 刚刚花一整节收口的那一类缺口。

代价如实记下：`Phone` 渠道的玩家要多收一条短信（实名是每账号一生一次的动作，代价上界 = 每账号一条短信）；第三方渠道无此代价（`authCode` 可再取、零成本）。

### C. 六端点的请求 / 应答字段

`[既有推演]` + `[通行做法]`，逐端点形态见 `## 具体形态`。承重的几条单列：

- **实名端点只接受 ticket 态，不接受已登录态。** 实名未完成的账号在 `signin` 必被拦，因此「已登录且未实名」在结构上不存在——给它开一条鉴权态入口是为一个不可达情形加一条路径。**否定断言可直接写成验收标准。**
- **出生日期永不跨边界。** §7 已定未成年判定的数据源是核验返回的出生日期；它与 `channelUserId` / `idKind` / `sid` 同属服务端内部事实，**不出现在任何报文字段里**，只以 `isMinor` 布尔跨边界。
- **`GET /v1/compliance/status` 不下发 `account.status`。** `auth.md` §1a 已封定它不跨边界。冷静期这一唯一有客户端消费点的事实，以 `deletionEffectiveAtUtc` 单字段承载——存在即在冷静期，缺席即不在。
- **`POST /v1/compliance/deletion` 幂等：重复申请回同一个 `deletionEffectiveAtUtc`，绝不顺延冷静期。** 顺延会让弱网重试无声地推迟玩家的注销生效时刻。
- **撤销一个不存在的注销申请 → `204`。** 与 `signout` 对已失效会话、`unbind` 解绑不存在的绑定**同一条纪律**（`auth.md` §7）。
- **`POST /v1/compliance/export` 幂等：存在未过期的 `Pending` / `Ready` 任务时回同一 `taskId` 且 `deduplicated: true`。** 与 `purchase.md` §3 的 `deduplicated` 同构、复用同一字段名。它同时解决「客户端丢失 `taskId`（重装 / 换设备）后如何找回」——重新 `POST` 即可，不需要任务列表端点。
- **`GET /v1/compliance/export/{taskId}` 必须校验任务归属当前账号，不归属时回 `resource.not_found` 而非「无权访问」。** 回「无权」会泄漏 `taskId` 的存在性。
- **状态一律走应答体的 `status` 字段，不靠 HTTP 状态码表达。** 导出申请回 `200` 而非 `202`——`envelope.md` §5b 已定客户端不得靠状态码分支。

### D. `taskId` 的形态：32 位小写十六进制

`[既有推演]`

**建议 `^[0-9a-f]{32}$`**，与客户端 `deviceId` 的取值形态逐字相同（`Guid.NewGuid().ToString("N")` 的产物形态），与 `accountSeed`（16 位小写 hex）同向。

- **定长小写 hex · 无前缀 · 无分隔符** ⇒ 两侧不需要对大小写 / 分隔符做归一，这条理由客户端已就 `deviceId` 写过一遍。
- **URL 安全**（进 `{taskId}` path 段，无需转义）。
- **不用 ULID**：ULID 的时间前缀会泄漏任务的申请时刻与相对顺序，而 `taskId` 是一个只靠随机性防遍历的标识。
- 不可枚举性是**纵深防御**，不是访问控制——归属校验（上一条）才是。

### E. 导出任务状态机：四个取值

`[既有推演]`（取值形态与「处置相同不拆」判据）+ `[通行做法]`（保留期分层）

| 取值 | 语义 | 客户端处置 |
|---|---|---|
| `Pending` | 已受理、产物尚未就绪（含排队与生成中） | 按 `pollAfterSeconds` 继续轮询 |
| `Ready` | 产物就绪，`downloadUrl` 与 `downloadExpiresAtUtc` 同批下发 | 呈现下载入口 |
| `Failed` | 生成失败，终态 | 呈现「生成失败，请重新申请」 |
| `Expired` | 产物保留期已过，终态 | 呈现「已过期，请重新申请」 |

- **不拆 `Queued` / `Running`**：客户端处置逐字相同（继续轮询），拆开只让状态表多一行走同一条路径——与 `restricted` / `banned` 共用一个 `code` 是同一条判据（`compliance.md` §5）。
- **保留 `Expired` 而不让它退化为 `resource.not_found`**：玩家几天后回来点旧入口时，「已过期，重新申请一次」与「找不到」是两句完全不同的话。代价是任务**记录**的保留期须长于**产物**的保留期（旋钮见下），成本是一行元数据。
- **`Failed` 不带 `failureReasonKey`**：生成失败的全部子类对玩家是同一句话、同一个动作（重新申请）。日后确有分辨需求时再加取值——`reasonKey` 的扩张不要求客户端同批发版（`ADR-0015`）。

### F. 端点自身的错误码：只新增三条

`[既有推演]`

四类待落笔的失败面里，**有两类不该新增码**：

- **核验服务不可达 / 超时 / 限流 → 复用 `server.unavailable`（`Retryable`）。** 与 `auth.md` §3a「渠道不可达报 `server.unavailable`、不报 `channel_rejected`」、`purchase.md` §3「平台不可达须与『收据无效』在报文层面可区分」**逐字同源**：把它报成 `Fatal` 会让客户端把一次抖动当成终态，让玩家重填一遍身份证号。
- **导出任务不存在 → 复用既有 `resource.not_found`**（`detail { resource }`，台账已有）。与 `auth.md` §9「**不新增** `auth.account_not_found` → 用既有 `resource.not_found`」是同一条判断。
- **「任务未就绪」根本不是错误**：`GET export/{taskId}` 回 `200` + `status: "Pending"`。
- 导出申请 / 实名提交的频次超限 → 复用 `rate.limited`。

**新增三条**（台账行见 `## 具体形态`）：

| `code` | 覆盖 | 为什么必须新增 |
|---|---|---|
| `compliance.ticket_invalid` | ticket 过期 / 已消费 / 未知 | 三种情形的客户端处置**完全相同**（回登录屏重新登录以取得新 ticket），靠 `reasonKey` 分辨措辞——`restricted` / `banned` 先例 |
| `compliance.verification_failed` | 核验服务**明确拒绝**（姓名 / 证件号不匹配、格式非法） | 必须与「核验服务不可达」在报文层面可区分，否则客户端无从判断该不该重试 |
| `compliance.deletion_irrevocable` | 冷静期已过 / 注销已进入不可逆执行，撤销请求来晚了 | 与「没有申请过」（回 `204`）必须可区分：一个是「你已经不在冷静期了」，一个是「本来就没这回事」 |

三条**全为 `Fatal`**、**全映 `OpError.Compliance`**——与客户端 `account-service` 既定的「实名 / 防沉迷拦截 → `OpError.Compliance`」映射一致。

**这三条不违反「拦截只在 `signin`」**：它们是本域端点自身的操作错误，`compliance.md` §4 已明写该纪律约束的是「拦截」而非 `compliance.` 前缀。**建议在落笔时于 §4 追加一句指路**，指向新的错误码节——否则读者会在两处之间来回找。

### G. 实名端点的限流是承重的，不是运维细节

`[通行做法]`

实名核验**按次计费**，且「提交姓名 + 证件号看是否匹配」本身就是一个撞库面。**建议契约层声明「本端点必须限流」并给旋钮初值**（单账号 5 次 / 天），实现与实际阈值归 `06`。

这与 `auth.md` 对 `challenge` 的处理同构（验证码重发间隔 / 日上限进 §8 旋钮表，实现归 `06`），**不是**把运维搬进契约。

### H. `downloadUrl` 不是本 API 的端点

`[既有推演]`

`downloadUrl` 指向的是一个**外部对象 URL**（签名在 URL 内、无鉴权可直下、有效期见 `downloadExpiresAtUtc`）——客户端用系统浏览器 / 下载器打开它，那条请求不会带 `Authorization` 头。

- 它的签发形态与存储归 `06`（`compliance.md` §8 已把产物存储与链接签发指向那里）。
- **它不进 `openapi.yaml` 的 `paths`。** 这一句必须写下：机检断言③校验「markdown 中出现的每个 `METHOD 路径` ⇔ spec 的 `paths` 键」，不写明会被误判成漏项。

### I. 导出产物的账号元数据白名单

`[既有推演]`

§8 已定「不含任何渠道内部键」。**建议把它写成一份正列白名单**，使这条纪律可验收：

产物 = 单个 UTF-8 JSON 文件，含两段——
- `profile`：整份 profile 原样（后端对它半透明，原样输出即可，不重排、不裁剪）；
- `account`：`accountId` · `createdAtUtc` · `identities[]`（每条只有 `channel` 与 `boundAtUtc`）。

**明确不含**：`channelUserId` · `idKind` · `sid` · `deviceId` · 任何会话 / token 材料 · 姓名 / 证件号 / 出生日期（实名材料是**核验的输入**，不是玩家的游戏进度；把它放进导出物等于把最敏感的那一项重新交出去一次）。

## 具体形态（可 derive 的落地面）

> 下列字段表按 `envelope.md` §1 属**草案**（该端点的 spec 未落笔前皆然）。类型列在 `openapi.yaml` 覆盖到本域时同批删除。

### 端点集（§2 的一处修订）

```
POST   /v1/compliance/realname          提交实名                —— 无鉴权，凭 complianceTicket
GET    /v1/compliance/status            查当前合规态             —— 需鉴权
POST   /v1/compliance/deletion          申请注销 → status = pendingDeletion   —— 需鉴权
POST   /v1/compliance/deletion/cancel   撤销注销申请             —— 需鉴权 或 凭 complianceTicket   ← 由 DELETE 改
POST   /v1/compliance/export            申请数据导出（异步任务）  —— 需鉴权
GET    /v1/compliance/export/{taskId}   查导出任务状态与下载链接  —— 需鉴权
```

**改动理由**：撤销注销在免 token 态下**必须把 `complianceTicket` 放进 body**（`envelope.md` §4a 的判据原文：「凭据因此只能在 body 里随请求送达」）。而 `DELETE` 请求携带 body 的语义在 HTTP 规范里未定义，中间层剥离 body 是已知的常见行为——一个**判据要求带 body、方法却不保证 body 能到达**的端点是一处结构性隐患。改为 `POST .../cancel` 后，六端点数量不变、鉴权形态不变、判据不变。**连带需同批改三处**：`envelope.md` §3 端点清单、`envelope.md` §4a 例外表、`ADR-0016` 的例外表（该 ADR 后果段已写明「例外表是判据的当前解而非定义——表变了不等于判据被推翻」）。裁决见 `## 与既有决策的张力`。

### 共有取值：`ComplianceRealnameStatus`（枚举字符串，PascalCase）

| 取值 | 语义 | 对应 `compliance.realname_required` 的 `reasonKey` |
|---|---|---|
| `NotSubmitted` | 从未提交 | `NotSubmitted` |
| `Pending` | 已提交，核验异步未回 | `VerificationPending` |
| `Verified` | 核验通过 | —（不再拦截） |
| `Failed` | 已提交但核验未通过 | `VerificationFailed` |

**取值与 §5 的 `reasonKey` 取值表机械对应，但不同名。** `reasonKey` 表已封定且是**拦截**语境的词汇（`VerificationPending` 读作「因为核验未回所以拦你」），状态字段是**状态**语境的词汇。强行同名会把一张封定的表拖进新语境。

---

### `POST /v1/compliance/realname`

**请求**（无 `Authorization`；带 `X-App-Version` / `X-Request-Id`，`X-Content-Version` 可缺省——与 `auth.md` §6 的 ticket / 无 token 端点同档）

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `complianceTicket` | string | ✅ | 取自 `compliance.realname_required` 的 `detail`（§3）。**一次性**；60 秒回放窗口见方案 A |
| `realName` | string | ✅ | 姓名。**永不回显、永不进任何应答、永不进日志**（`envelope.md` §5a 的脱敏纪律） |
| `idNumber` | string | ✅ | 证件号。同上 |

- **不设 `deviceId`**：本端点不签发会话，多设备裁决与它无关。
- **不设证件类型字段**：首版仅支持中国大陆居民身份证。日后扩展是**追加一个可选字段**（缺席即默认），不是破坏性变更——与 `auth.md` §3「密码路线是加第五种 `credential` 分形，不推翻本契约任何一条」同一条处理。
- **重复提交幂等**：已 `Verified` 的账号再次提交 → `200` 回 `realnameStatus: "Verified"`，**不重复调用核验服务**（按次计费）。

**应答 `200`**

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `realnameStatus` | string | ✅ | `ComplianceRealnameStatus`；本端点可回 `Verified` / `Pending`（`Failed` 走错误码，见下） |
| `isMinor` | boolean | 可选 | 缺省即 `false`（`envelope.md` §2）。**仅在 `Verified` 时可能出现**。由核验返回的出生日期算得，**出生日期本身永不下发** |

**错误**：`compliance.ticket_invalid` · `compliance.verification_failed` · `rate.limited` · `server.unavailable`（核验服务不可达）。
**不返回**四条 `compliance.*` 拦截码（拦截只在 `signin`，§4）。

---

### `GET /v1/compliance/status`

**请求**：需鉴权，无 body，无 query 参数（账号取自 `Authorization`——与 `profile-sync.md`「`accountId` 绝不进 query / body」同一条纪律）。
**应答须带 `no-cache`**：合规态会在会话中途变化（§2 立此端点的理由本身）。

**应答 `200`**

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `realnameStatus` | string | ✅ | `ComplianceRealnameStatus` |
| `isMinor` | boolean | 可选 | 缺省即 `false` |
| `playtimeRemainingSeconds` | number | 可选 | **仅未成年账号下发**。当前时段内剩余可游玩秒数，**服务端按可信时钟算好**（§6）。相对量而非时刻 ⇒ 客户端做倒计时无需任何本地时钟比较 |
| `playtimeResumeAtUtc` | string | 可选 | **仅未成年账号、且当前不在允许时段内时下发**。与 `compliance.playtime_blocked` 的 `detail.resumeAtUtc` 同名同义 |
| `deletionEffectiveAtUtc` | string | 可选 | **存在即处于注销冷静期**，缺席即不在。这是 `pendingDeletion` 这一事实的**唯一**跨边界形态 |

- **不下发** `account.status`（`auth.md` §1a）· 时段表 / 规则本身（§6）· 出生日期 · 最近一次导出任务的 `taskId`（客户端持有；丢失即重新 `POST export`，见方案 C）。
- `playtimeRemainingSeconds` 的下发与否是一条取向，见 `## 仍需用户决定` 第 2 条。

**错误**：`server.unavailable`（及信封通则的 `auth.token_expired` / `auth.token_invalid`）。

---

### `POST /v1/compliance/deletion`

**请求**：需鉴权，**无 body**。二次确认是客户端 UI 的职责，不进契约。
**应答 `200`**

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `deletionEffectiveAtUtc` | string | ✅ | 冷静期结束、注销生效的时刻（冷静期初值 15 天，§9） |
| `deduplicated` | boolean | 可选 | 缺省即 `false`。已在冷静期内重复申请时为 `true`，**`deletionEffectiveAtUtc` 与首次逐字相同** |

- **不吊销任何会话。** 玩家在冷静期内可继续游玩——数据尚未删除，且强行吊销会凭空造出一次硬阻塞（`envelope.md` §7b「仅两处硬阻塞」+ pillar #4），还要为它新开一个 `reasonKey`。下次 `signin` 由 `compliance.account_deleting` 拦住并给撤销 ticket，这条路径已封定。
- `restricted` / `banned` 的账号**同样可以申请注销**：PIPL 的删除权不因风控状态而消失。**否定断言可直接写成验收标准。**

**错误**：`rate.limited` · `server.unavailable`。

---

### `POST /v1/compliance/deletion/cancel`

**请求**：需鉴权**或**凭 ticket（二者取其一，都不带即拒）

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `complianceTicket` | string | 可选 | 取自 `compliance.account_deleting` 的 `detail`（§3）。**带 `Authorization` 时不需要**；两者都不带 → `compliance.ticket_invalid` + `reasonKey: "Unknown"` |

**应答 `204`**，**幂等**：撤销一个不存在的注销申请同样回 `204`（`auth.md` §7 的同一条纪律）。ticket 态的重放走方案 A 的 60 秒窗口。

**错误**：`compliance.ticket_invalid` · `compliance.deletion_irrevocable` · `server.unavailable`。

---

### `POST /v1/compliance/export`

**请求**：需鉴权，**无 body**。
**应答 `200`**

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `taskId` | string | ✅ | `^[0-9a-f]{32}$`（方案 D） |
| `status` | string | ✅ | 新建任务恒为 `Pending`；命中既有任务时为该任务的当前状态 |
| `deduplicated` | boolean | 可选 | 缺省即 `false`。命中既有未过期的 `Pending` / `Ready` 任务时为 `true`，`taskId` 与首次逐字相同 |
| `pollAfterSeconds` | number | 可选 | 建议轮询间隔（初值 5 秒）。与 `auth.md` §8 `challenge` 的 `resendAfterSeconds` 同构：**节奏由服务端给，客户端不硬编码** |

- 上一个任务为 `Failed` / `Expired` 时 → 建新任务、新 `taskId`、`deduplicated` 缺席。

**错误**：`rate.limited`（申请限流初值 1 次 / 24 小时）· `server.unavailable`。

---

### `GET /v1/compliance/export/{taskId}`

**请求**：需鉴权，`taskId` 在 path。**任务不归属当前账号 → `resource.not_found`**（不泄漏存在性）。
**应答 `200`**

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `taskId` | string | ✅ | 回显 |
| `status` | string | ✅ | `Pending` / `Ready` / `Failed` / `Expired`（方案 E） |
| `requestedAtUtc` | string | ✅ | 申请时刻 |
| `pollAfterSeconds` | number | 可选 | **仅 `Pending` 时下发** |
| `downloadUrl` | string | 可选 | **仅 `Ready` 时下发**。绝对 HTTPS URL，签名在 URL 内、无鉴权可直下（方案 H）；**不进 spec 的 `paths`** |
| `downloadExpiresAtUtc` | string | 可选 | **仅 `Ready` 时下发**。产物保留期 7 天（§9） |
| `sizeBytes` | number | 可选 | **仅 `Ready` 时下发**。移动网络下下载前告知体积；产物是单份 JSON，永不接近 2⁵³ ⇒ 走 number 而非字符串（`envelope.md` §2 判据） |

**错误**：`resource.not_found` · `server.unavailable`。

---

### 提议登记进 `envelope.md` §6 台账的三行

| `code` | `class` | `OpError` | 客户端处置 | `detail` 形状 | `message` 必含 |
|---|---|---|---|---|---|
| `compliance.ticket_invalid` | `Fatal` | `Compliance` | 回登录屏重新 `signin` 以取得新 ticket；`reasonKey` 驱动二级措辞 | `{ reasonKey }` | ticket 的**前缀截断**、签发与过期时间、被判定的情形（**不含** ticket 原值全串） |
| `compliance.verification_failed` | `Fatal` | `Compliance` | 呈现失败原因并允许重填表单（受 `rate.limited` 约束）；`reasonKey` 驱动二级措辞 | `{ reasonKey }` | 失败的校验项标识（**不含**姓名 / 证件号任何片段，与既有 `compliance.realname_required` 那行同一条脱敏纪律） |
| `compliance.deletion_irrevocable` | `Fatal` | `Compliance` | 呈现「注销已生效 / 已不可撤销」，**无重试动作** | `{ deletionEffectiveAtUtc }` | `deletionEffectiveAtUtc` 与服务端当前时刻两值、账号前缀 |

### 提议的 `reasonKey` 取值表（PascalCase，`ADR-0015`）

`compliance.ticket_invalid`：

| 取值 | 触发 |
|---|---|
| `Expired` | ticket 超出 10 分钟寿命（§9） |
| `Consumed` | 已被兑付且落在 60 秒回放窗口之外（方案 A） |
| `Unknown` | 无法识别 / 伪造 / 与账号不匹配 / 用于非签发它的那个端点 |

`compliance.verification_failed`：

| 取值 | 触发 |
|---|---|
| `Mismatch` | 姓名与证件号不匹配 |
| `Malformed` | 证件号格式非法（服务端兜底；客户端只做长度与字符集这类无争议的输入约束，与 `auth.md` §8 昵称的 `Malformed` 同构） |

`compliance.deletion_irrevocable` **不设 `reasonKey`**：只有一种情形。

### 提议追加进 §9 旋钮表的五行

| 旋钮 | 初值 | 推导 |
|---|---|---|
| ticket 兑付回放窗口 | **60 秒** | 与 `auth.md` §8 的 refresh 宽限窗口 / `signin` 幂等回放窗口**同值同理由**——覆盖客户端指数退避的头几次重试 |
| 实名提交次数上限 | **5 次 / 账号 / 天** | 覆盖一次输入失误 + 数次重试；核验按次计费，且「提交姓名 + 证件号看是否匹配」本身是撞库面 |
| 导出申请限流 | **1 次 / 账号 / 24 小时** | 生成是重操作且产物含个人信息；PIPL 只要求可携带，不要求高频 |
| 导出任务**记录**保留期 | **30 天** | 产物 7 天（§9 已定）。记录多留使 `Expired` 与 `resource.not_found` 可区分（方案 E），成本是一行元数据 |
| 导出任务建议轮询间隔 | **5 秒** | `pollAfterSeconds` 初值。生成一份 JSON 的量级；待实测校准 |

**落点仍是后端配置而非代码常量**，与 §9 既有四个旋钮同处。

### 导出产物结构（方案 I 的可验收形态）

```
单个 UTF-8 JSON 文件
├─ profile   ← 整份 profile 原样（后端半透明，不重排、不裁剪）
└─ account   ← accountId · createdAtUtc · identities[]（每条仅 channel 与 boundAtUtc）
```

**正列白名单，不写排除列表**——排除列表会在新增内部字段时静默漏项。

## 后果

- **`contracts/compliance.md`**：§2 端点集一行改写（DELETE → POST cancel）+ 新增「报文字段表」与「端点自身的错误码」两节 + §4 追加一句指路 + §9 旋钮表增五行；状态由「已成文（报文字段表待落笔）」转为**完全成文**。
- **`contracts/envelope.md`**：§3 端点清单一行 · §4a 例外表一行 · **§6 台账新增三行**（21 → 24 行）· 第一条 Open question 关闭。
- **`decisions/ADR-0016`**：例外表一行（路径名）。判据不变，按其后果段「表可增行 / 改行不等于判据被推翻」。
- **`contracts/_index.md`**：compliance 行状态列去掉「（报文字段表待落笔）」；连带可修正已记录的两处台账漂移（`session_revoked` 七值 vs 八值 · 「四份」vs 六份）——**但那两处不属本次范围**。
- **`open-questions/01-contracts.md`** 第 2 条与 **`envelope.md`** 的第一条 Open question 同批移出（归 `/analyze-new-ideas`）。
- **derive 就绪度**：`compliance.md` 具备由 blocked 转 ready / partial 的条件（余下卡点全在 `06` 的实现层，且均已明写「契约层只声明语义」）。**但就绪度判定归 `/assess-derive-readiness` 独占**，本草稿不预判。
- **对侧解锁 —— 范围要说准**：本次落笔给出的是**边界另一侧的报文**，它是对侧写「合规端点对位」验收断言的输入。**它不关闭** `game-design-documents/open-questions/cross-boundary.md` 的那条待承接项（覆盖面切分按对侧自陈是客户端自己的取向，见「问题」段的纠正）。**本库不代为切分「哪些拦截由 `ComplianceManager` 呈现、哪些落在登录屏本身」。**
- **对客户端的既有机械义务为零**：三条新 `code` 与各自 `reasonKey` 走客户端既定的机械变换与降级兜底（未知 `code` 按 `class` 降级、未知 `reasonKey` 回落一级键），**不要求客户端同批发版**，且不得新增第三处硬阻塞。权威在 `game-design-documents/ux/error-and-blocking-ux.md` 与 `game-design-documents/systems/architecture.md`（**本库不复述**）。
- **存档 schema 零影响**：合规态、ticket、导出任务均不进 `PlayerProfile`，不 bump `schemaVersion`、无迁移。
- **契约变更的完成判据**：第 3 条（台账登记）· 第 5 条（人工清单四项）· 第 6 条（对侧 handoff 互链）本次全部适用；第 2 条见下方张力。
- **条件性连带**：若 `## 仍需用户决定` 第 2 条选定「下发 `playtimeRemainingSeconds`」，客户端将获得一个**新增**的呈现义务（游戏内防沉迷倒计时），届时须在客户端库另立承接项；选「不下发」则本次全部改动都只是解锁对侧已在等待的呈现面，无新增义务。

## 备选方案（已考虑并否决）

- **保留 `DELETE /v1/compliance/deletion` 并把 ticket 放进 query 参数** — 凭据进 URL 会落进网关 / CDN / 代理的访问日志，且与 §4a 判据明写的「凭据只能在 body 里随请求送达」直接相反。
- **保留 `DELETE` + body，接受中间层剥离的风险** — 免 token 态是这个端点存在的**唯一**理由；它一旦不可靠，端点等于没有。
- **realname 应答直接签发 token 对** — 见方案 B 与取向 1；它让 ticket 事实上成为 scope 受限凭据（§3 与 `ADR-0016` 明确否决），并造出第二个绕开强更闸门的出口。
- **给 `complianceTicket` 一个「可换一次 `signin`」的兑换语义** — 换了个名字的同一件事，且要为它新开一条求值路径。
- **实名端点同时接受鉴权态** — 「已登录且未实名」在结构上不存在（`signin` 必拦），为不可达情形加一条路径。
- **拆 `Queued` / `Running` 两个任务状态** — 客户端处置逐字相同，只让状态表多一行走同一条路径。
- **`Failed` 带 `failureReasonKey`** — 全部子类对玩家是同一句话、同一个动作；日后确有需要时扩表不要求客户端同批发版。
- **为「导出任务不存在」新增 `compliance.export_task_not_found`** — 既有 `resource.not_found` 逐字覆盖；`auth.md` §9 已就 `auth.account_not_found` 做过同一判断。
- **为「核验服务不可达」新增一条 `compliance.*` 码** — 它是 `Retryable`，混进全为 `Fatal` 的合规域会破坏客户端「`Compliance` 档 = 不可重试」的静态推理；`server.unavailable` 逐字覆盖（`auth.md` §3a 同源）。
- **`GET /v1/compliance/status` 下发 `account.status`** — `auth.md` §1a 已封定它不跨边界，且本地副本会在会话中途过期。
- **`GET /v1/compliance/status` 下发时段表 / 规则** — §6 已封定：写进契约即第二权威，而它恰是最易被监管推翻的一条。
- **应答下发出生日期供客户端自行判定未成年** — 把最敏感的一项个人信息跨边界，且判定权应与可信时钟同处服务端。
- **申请注销即吊销全部会话** — 凭空造出一次硬阻塞（`envelope.md` §7b + pillar #4），且要为它新开一个 `reasonKey`；冷静期的本意就是「还没删，随时可以反悔」。
- **重复 `POST deletion` 顺延冷静期** — 弱网重试会无声推迟玩家的注销生效时刻，违反 pillar #2 的幂等纪律。
- **新增「列出我的导出任务」端点** — `POST export` 的 `deduplicated` 幂等已覆盖「丢失 `taskId`」这唯一用例，新端点无第二个消费面。
- **`GET /v1/compliance/status` 携带最近一次 `taskId`** — 让一个查合规态的端点兼职任务列表，两处形态从此要同步演进。
- **导出申请回 `202 Accepted`** — 客户端不得靠 HTTP 状态码分支（`envelope.md` §5b）；状态已在 `status` 字段里。
- **`taskId` 用 ULID** — 时间前缀泄漏申请时刻与相对顺序；且与两侧既有的「定长小写 hex」形态不齐。
- **导出产物写排除列表（「不含 X / Y」）而非正列白名单** — 新增内部字段时静默漏项，而这是一份直接交到玩家手里的文件。
- **在本库规定合规相关的玩家可见文案 / `ComplianceManager` 的切分** — 归客户端库（`ux/error-and-blocking-ux.md` · `systems/services/account-service.md`），本库只定边界另一侧的报文。

## 与既有决策的张力

**① `DELETE /v1/compliance/deletion` → `POST /v1/compliance/deletion/cancel`（改动一份已成文契约 + 一份 Accepted ADR 的例外表）**

- 冲突的是：`compliance.md` §2 的端点集、`envelope.md` §3 端点清单与 §4a 例外表、`ADR-0016` 的例外表——四处都写着 `DELETE /v1/compliance/deletion`。
- 为什么需要松动：`envelope.md` §4a 的判据要求免 token 端点的凭据**在 body 里**送达，而 `DELETE` 携带 body 在 HTTP 规范中语义未定义、中间层剥离是已知常见行为。判据与方法互相打架。
- 松动的代价：一次四处同批的机械改动（端点数量、鉴权形态、判据本身均不变）。`ADR-0016` 后果段已预留这条路——「例外表是判据的**当前解**而非定义」。
- 不松动时的替代：保留 `DELETE` + body 并在 `operations/` 记一条「部署时须确认全链路不剥离 DELETE body」的约束。**不推荐**——把一条协议正确性押在部署环境的行为上，而这个端点的免 token 态是它存在的唯一理由。
- **裁决权在用户。**

**② 「契约变更的完成判据」第 2 条在本次不适用**

- `contracts/_index.md` 定「`openapi.yaml` 的形态已在**同一次变更内**更新」，只改一边视为未完成；而 `envelope.md` §1 同时定「**不预先建空壳**，触发点 = 任一侧首个端点**进入实现**」。
- 本次是**落笔字段表**，不是端点进入实现 ⇒ spec 尚不存在，第 2 条无对象。
- **建议**：落笔时在 `_index.md` 的完成判据处补一句限定——「第 2 条仅在 spec 已存在（或本次变更即触发首落）时适用」。否则本次变更会被后来的读者判成「未完成」，而这正是六条判据要防的那种含糊。**这一句是否补、怎么补，请用户裁决**（它改的是一条治理规则，不是报文）。

**③ 与 `purchase.md` §4 的枚举大小写不一致（越界，仅提示）**

- `purchase.md` §4 写 `status ∈ {unknown, verified, rejected}`（小写），而 `envelope.md` §2 与 `ADR-0015` 的取向都是 PascalCase 封闭取值集。本草稿的导出任务状态取 PascalCase。
- **本草稿不改 `purchase.md`**（不在本次范围）。仅登记：两处若长期不齐，「到底该写哪种」会在每次新增取值时被重新提出一次——这正是 `ADR-0015` 要消除的那类不一致。

## 前置依赖

- **不阻塞落笔的实现层项（全部已由 `compliance.md` 明写归 `06`）**：可信服务端时钟的形态 · `complianceTicket` 的存储与一次性消费保证 · 冷静期这条跨天长时状态机的调度形态 · 导出产物的存储与链接签发 · 实名核验服务商与灾备。本草稿全部停在协议与语义层，**不指定任何实现**，故这些不构成前置。
- **旋钮初值待实测校准**：实名提交次数上限 · 导出申请限流 · `pollAfterSeconds`。它们与 §9 既有四个旋钮同档——**初值不阻塞契约成文**。
- **合规能力的上线分级**（归 `02`）不阻塞本次：分级决定「哪些能力在首次上线前具备」，不改任何报文形态。
- **`openapi.yaml` 的首落**不构成前置，见张力②。
- **对侧无前置**：客户端 `ComplianceManager` 的覆盖面切分是客户端自己的取向（见「问题」段的纠正），既非本次落笔的上游、也不由本次落笔关闭。核对对侧后登记一条**事实**（不复述其内容、不代为决定）：客户端库当前对 `complianceTicket` 与注销 / 导出的屏幕流**尚无任何承载**，故本次落笔不与对侧任何既有设计相冲突。

## 仍需用户决定

**1. 实名提交 / 撤销注销成功后，玩家如何回到已登录态？**

| 选项 | 后果 |
|---|---|
| **(a) 端点只回状态，客户端重走完整 `signin`**（含重新获取验证码）**← 推荐** | `complianceTicket` 保持「一次性 · 单端点 · 不携带任何权限维度」的纯净形态（§3）；强更闸门与合规判定的唯一落地点仍是 `signin`（`auth.md` §5 §5a），不产生第二个绕开闸门的出口。**代价**：`Phone` 渠道玩家多收一条短信（实名是每账号一生一次的动作，上界 = 每账号一条短信；`WeChat` 渠道零成本），且多一次「输验证码」的步骤 |
| (b) 实名 / 撤销端点的应答直接签发 token 对 | 省一条短信、玩家流程更顺。**但** ticket 事实上成为 scope 受限凭据——正是 `compliance.md` §3 与 `ADR-0016` 明确否决的形态；且合规端点成为第二个签发会话的出口，`auth.md` §5b 刚花一整节收口的「绕开闸门」缺口会在此重开一个 |
| (c) 兑付成功后延长原验证码的可用期 | 直接违反「一次性凭据」纪律，且要为它新开一条求值路径；**不推荐** |

**推荐 (a)。** 理由：代价是有界且极小的（每账号一次），而 (b) 松动的是两条承重纪律。

→ **已裁决（2026-09-02 · 批量评审）：采纳 (a)** —— 端点只回状态，客户端重走完整 `signin`。

---

**2. `GET /v1/compliance/status` 是否下发未成年人的 `playtimeRemainingSeconds`（当前时段剩余可游玩秒数）？**

| 选项 | 后果 |
|---|---|
| **(a) 下发** ← 推荐 | 客户端可做游戏内倒计时 / 提前提醒，玩家不会在战斗中途毫无预兆地被踢（§7 的时段到点走 `session_revoked` 硬阻塞路径）。**对客户端是一项新增呈现义务**（需在客户端库另立承接项）。监管口径本身仍不进契约（§6），下发的只是一个服务端算好的相对量 |
| (b) 不下发 | 后端零新增义务，本次全部改动纯属解锁对侧已在等待的呈现面；**但**玩家只在被踢下线的那一刻才知道时长用尽，这在 pillar #4「不阻塞玩家」上是一处可预见的粗糙 |

**推荐 (a)。** 理由：字段本身成本近乎为零（服务端本就要算它才能判时段），且它把一次硬阻塞变成一次有预告的软着陆——与 `auth.md` §5b 为绝对寿命上限配 `reauthRecommended` 软信号是同一个取舍，那里已经选过一次「给着陆坡」。**但它给客户端新增义务，故不替用户拍。**

> 若选 (a)，建议同批在客户端库为「游戏内防沉迷倒计时的呈现形态」立一条承接项（本库不代为决定其形态）。

→ **已裁决（2026-09-02 · 批量评审）：采纳 (a)** —— 下发 `playtimeRemainingSeconds`。客户端侧的承接项已按同批裁决落成配套草稿 `game-design-documents/inbox/solution-draft-backend-batch-client-obligations.md`（呈现形态仍归客户端自决，本库不代为决定）。

---

## 批量评审同批裁决（本草稿的两条张力 + 一处跨草稿并入）

- **张力 1（`DELETE /v1/compliance/deletion` → `POST /v1/compliance/deletion/cancel`）→ 已按标准默认采纳。** `DELETE` 带 body 语义未定义、易被中间层剥离，属工程常识默认；`ADR-0016` 后果段已预留「例外表是判据的当前解而非定义」，判据本身不变。连带同批改 `compliance.md` §2、`envelope.md` §3 / §4a 与 `ADR-0016` 例外表。
- **张力 2（`contracts/_index.md`「契约变更完成判据」第 2 条）→ 已按标准默认采纳**：补一句限定「第 2 条仅在 spec 已存在、或本次即触发首落时适用」。本次是落笔字段表、非进入实现，spec 尚不存在故第 2 条无对象。
- **跨草稿并入（W5 · 昵称处置裁决为 P2）**：`GET /v1/compliance/status` 的应答须**再加一项「须改名」标记**——语义与判定归 `solution-draft-nickname-moderation-and-risk-control.md`，字段形态归本草稿。**两份草稿须一并被 `/analyze-new-ideas` 消费**，单侧提炼即两半对不上。
- 张力 3（`purchase.md` §4 枚举小写 vs 全库 PascalCase）**本批不动**：取值已由 `ADR-0013` 冻结，改动属正式契约变更，仅登记。
- 张力 4（`open-questions.md`「derive 就绪度」对「唯一待承接项由谁关闭」的表述失真）**不由本流程改**：该小节由 `/assess-derive-readiness` 独占写入。
