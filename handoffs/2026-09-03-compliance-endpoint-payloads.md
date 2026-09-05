# 合规域六端点的报文字段表与端点自身的错误码

- id: 2026-09-03-compliance-endpoint-payloads
- date: 2026-09-03
- topic: contracts/compliance（§2 撤销端点方法 · §3 回放窗口与不签发 token · §4 指路 · §5 取值表不扩 · §8 白名单 · §9 五个旋钮 · 新增 §10 §11）· contracts/envelope（§4a 例外表 · §6 台账三行与承重表述）· decisions/ADR-0016（例外表 · 后果段）
- status: distilled
- distilled-to: `contracts/compliance.md`、`contracts/envelope.md`、`decisions/ADR-0016-unauthenticated-endpoint-criterion.md`、`contracts/_index.md`、`open-questions/01-contracts.md`、`answer-logs/log-compliance-endpoint-payloads.md`

## Intent（distilled）

**一句话：** 合规域从「端点集与语义已封定、报文未落笔」补齐为完全成文——六端点逐个的请求 / 应答字段、`taskId` 形态、导出任务状态机、端点自身的三条错误码；并顺带把撤销注销从 `DELETE` 改为 `POST .../cancel`，因为免鉴权判据要求凭据走 body、而 `DELETE` 带 body 不保证到达。

### 1. 撤销注销改用 `POST /v1/compliance/deletion/cancel`

免 token 态是这个端点存在的唯一理由，`envelope.md` §4a 的判据据此要求凭据在 body 里送达；而 `DELETE` 携带 body 在 HTTP 规范中语义未定义，中间层剥离是已知常见行为。**判据要求带 body、方法却不保证 body 能到达**，这是结构性隐患。改动面是四处同批的机械修订（`compliance.md` §2 §3、`envelope.md` §4a、`ADR-0016` 例外表），端点数量、鉴权形态与判据本身均不变——`ADR-0016` 后果段本就写着「例外表是判据的当前解而非定义」。

`envelope.md` §3 的端点清单**无需改动**：它只列到域级（`/v1/compliance/…`），不含方法与具体路径。

### 2. ticket 兑付的 60 秒回放窗口 = 同一模式的第四次兑现

`complianceTicket` 是一次性的，而弱网下「请求已达、应答丢失」是常态，客户端重试会撞上「已消费」——它其实已经成功了。**首次成功后 60 秒内原样回放上次应答，不再消费、无副作用；窗口外即 `compliance.ticket_invalid` + `Consumed`。**「一次性」不被削弱。它与 refresh 宽限窗口、`signin` 幂等回放、`pushId` 重放同值同理由（覆盖客户端指数退避的头几次重试）。

### 3. 兑付成功后不签发 token

实名 / 撤销端点只回状态，玩家重走完整 `signin`。让它们签发 token 对，等于让 ticket 事实上成为 scope 受限凭据（`compliance.md` §3 与 `ADR-0016` 都否决了这条），并造出第二个绕开强更闸门与合规判定的出口。代价有界且极小：`Phone` 渠道每账号至多一条额外短信（实名是一生一次的动作），第三方渠道零成本。

### 4. 六端点的报文字段（要点，全文在契约）

- **共有枚举 `ComplianceRealnameStatus`** 四值，与 §5 的 `reasonKey` 表机械对应但**不同名**（一个是状态语境、一个是拦截语境）。
- **出生日期永不跨边界**，只以 `isMinor` 布尔下行；`account.status` 同样不下发，冷静期以 `deletionEffectiveAtUtc` 的存在与否单字段承载。
- **`GET status` 下发 `playtimeRemainingSeconds`**（服务端按可信时钟算好的相对量）：把时段到点从一次硬阻塞变成一次有预告的软着陆，与 §5b 为绝对寿命上限配软信号是同一个取舍。呈现形态归客户端。
- **`GET status` 另带 `nicknameChangeRequired`**（见配套 handoff `2026-09-03-nickname-moderation-and-risk-control.md`：语义归那份，形态归本份）。
- **两处幂等**：重复 `POST deletion` 回同一 `deletionEffectiveAtUtc`（**绝不顺延冷静期**）；重复 `POST export` 命中未过期任务回同一 `taskId` + `deduplicated`，它同时覆盖「客户端丢失 `taskId`」这唯一用例，故不新增任务列表端点。
- **撤销一个不存在的申请回 `204`**，同 `signout` / `unbind` 的纪律。
- **`taskId` = `^[0-9a-f]{32}$`**：定长小写 hex、无前缀无分隔符、URL 安全；不可枚举性是纵深防御，访问控制靠归属校验（不归属回 `resource.not_found`，不泄漏存在性）。
- **导出任务四状态**（`Pending` / `Ready` / `Failed` / `Expired`），不拆 `Queued` / `Running`；保留 `Expired` 使「已过期，重新申请」与「找不到」是两句不同的话，代价是任务记录保留期长于产物保留期。
- **`downloadUrl` 是外部对象 URL，不进 spec 的 `paths`**——不写明会被机检断言③误判成漏项。

### 5. 端点自身的错误码：只新增三条

`compliance.ticket_invalid` · `compliance.verification_failed` · `compliance.deletion_irrevocable`，全 `Fatal`、全映 `OpError.Compliance`。**不新增**的四类：核验服务不可达 → `server.unavailable`（`Retryable`，混一条可重试进本域会破坏客户端「`Compliance` 档 = 不可重试」的静态推理）· 任务不存在 → `resource.not_found` · 任务未就绪不是错误（`200` + `Pending`）· 频次超限 → `rate.limited`。三条新码与新 `reasonKey` 对客户端零机械义务，不要求同批发版。

### 6. 导出产物写成正列白名单

`profile` 原样 + `account`（`accountId` · `createdAtUtc` · `identities[]` 仅 `channel` 与 `boundAtUtc`）。排除列表会在新增内部字段时静默漏项，而这是直接交到玩家手里的文件。由此**不含**姓名 / 证件号 / 出生日期——实名材料是核验的输入，不是玩家的游戏进度。

### 7. 五个新旋钮

ticket 兑付回放窗口 60 秒 · 实名提交 5 次 / 账号 / 天（**契约层声明本端点必须限流**，与 `challenge` 的处理同构）· 导出申请 1 次 / 24 小时 · 导出任务记录保留期 30 天（产物仍 7 天）· `pollAfterSeconds` 初值 5 秒。落点仍是后端配置。

## Clarifications（interview 产物）

- 实名 / 撤销成功后如何回到已登录态 → **端点只回状态，客户端重走完整 `signin`**（用户裁决）。代价（`Phone` 渠道每账号至多一条额外短信）如实接受。
- `GET status` 是否下发 `playtimeRemainingSeconds` → **下发**（用户裁决）。客户端侧的呈现义务由 `game-design-documents/inbox/solution-draft-backend-batch-client-obligations.md` 承接，本库不代为决定其形态。
- 撤销注销由 `DELETE` 改 `POST .../cancel`，连带改一份 Accepted ADR 的例外表 → **按标准默认采纳**（工程常识；判据本体不变）。
- `contracts/_index.md`「契约变更的完成判据」第 2 条补一句限定「仅在 spec 已存在、或本次变更即触发首落时适用」→ **按标准默认采纳**。本次是落笔字段表而非端点进入实现，spec 尚不存在，故第 2 条无对象。
- 自动采纳的标准默认（不占裁决）：ticket 60 秒回放窗口取与既有三处同值 · 只新增三条 `code`、四类复用既有码 · `taskId` 取 32 位小写 hex 而非 ULID · 导出任务四状态不拆 · 导出产物不含实名材料 · `nicknameChangeRequired` 由云端状态算出且不带 `reasonKey`。

## Open questions

- 可信服务端时钟的形态 · `complianceTicket` 的存储与一次性消费保证 · 冷静期长时状态机的调度 · 导出产物存储与链接签发 · 实名核验服务商与灾备 —— 全部归 `06`，落 `operations/`。契约层只声明语义，故不阻塞本次落笔。
- 三个新旋钮的初值待实测校准（实名提交上限 · 导出申请限流 · `pollAfterSeconds`）。
- `openapi.yaml` 的首落不构成前置：触发点是任一侧首个端点**进入实现**（`envelope.md` §1）。

## Notes / triage

来源：`inbox/solution-draft-compliance-endpoint-payloads.md`（已人工评审）。与 `handoffs/2026-09-03-nickname-moderation-and-risk-control.md` **成对**：`GET /v1/compliance/status` 的 `nicknameChangeRequired` 语义归那一份、形态归本份，单侧提炼即两半对不上。

本次产生的 ADR 候选（交 `/write-adr` 处置，不建 ADR、不动 `decisions/_index.md`）：**ticket 兑付的 60 秒回放窗口 = pillar #2 同一模式的第四次兑现**——值得固化，否则「一次性凭据为什么允许回放」会被反复重新提出。

## 客户端侧影响

**是，跨边界。** 本次落笔给出的是边界另一侧的报文，它是客户端写「合规端点对位」验收断言的输入。**但它不关闭** `game-design-documents/open-questions/cross-boundary.md`「待承接」区的那条 `ComplianceManager` 覆盖面切分——对侧原文明写切分是客户端自己的取向，不等本库任何输入。

客户端侧的承接面（三条新 `code` 的 `ERR_*` 二级文案 · `playtimeRemainingSeconds` 的倒计时呈现 · 注销 / 导出的屏幕流）已由 `game-design-documents/inbox/solution-draft-backend-batch-client-obligations.md` 承接。**对侧尚未落笔成正式文档，本次不宣称跨边界收口。**
