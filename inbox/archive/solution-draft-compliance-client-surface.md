---
type: solution-draft
date: 2026-09-03
question: 后端合规域 2026-09-03 落笔后，客户端侧的三条新 `code` 如何呈现，以及 `ComplianceManager` 的覆盖面如何切分？
source: open-questions/cross-boundary.md（`compliance.md`#10 #11 承接项 · `ComplianceManager` 覆盖面切分）→ systems/services/account-service.md#待决问题
targets: systems/services/account-service.md（`ComplianceManager` 覆盖面 · API 面）· ux/error-and-blocking-ux.md（三条新 `ERR_*` 一级键与二级键 · 变体表准入复核）· systems/architecture.md（`code → (OpError, 处置)` 数据表补三行）· ux/screen-flow.md（实名屏 · PlayerProfile 屏的注销 / 导出区）
status: distilled
reviewed: 2026-09-03 · 用户评审定案三项（注销取就地二段确认 · 冷静期只在 PlayerProfile 屏内呈现 · 授权把对侧 `envelope.md` §6 台账那一列改为回链客户端库，本批不执行）；2026-09-03 合并 interview 追加裁决一项（强制改名维持 fail-open 并明写边界）+ 标准默认三项（`ExportTaskInfo` 改可空并补 `Deduplicated` · 三条 `code` 处置落 `account-service.md` 而非在 `architecture.md` 开逐 `code` 表 · `GET status` 失败归入不变式③ 第二形状）
distilled-to: handoffs/2026-09-03-compliance-client-surface.md
---

# 方案草稿 — 合规域的客户端呈现面与 `ComplianceManager` 切分

## 问题

后端合规域已于 2026-09-03 完全落笔（`backend-design-documents/contracts/compliance.md` §10 六端点报文字段表、§11 三条端点错误码，台账三行在 `contracts/envelope.md` §6）。对侧 `compliance.md:365` 明写「本库只定边界另一侧的报文」，把三件事交回客户端：

1. **三条新 `code` 的 `ERR_*` 键与呈现**——`compliance.ticket_invalid`（带 `reasonKey`）· `compliance.verification_failed`（带 `reasonKey`）· `compliance.deletion_irrevocable`（**不设 `reasonKey`**）。
2. **`ComplianceManager` 的客户端侧覆盖面切分**——实名 / 防沉迷 / 注销 / 数据导出四域中，哪些环节由它承接、哪些落在登录屏本身。这一条登记在两处（`open-questions/cross-boundary.md` 与 `systems/services/account-service.md:234`），且**对侧明写归客户端自己裁决、不等对侧输入**。

它卡住的是：`account-service.md` 的 derive 就绪度（`ComplianceManager` 一直是它 `partial` 的卡点之一）、以及三条新码在客户端的落地面（数据表 / 翻译资源 / 呈现屏）。

**范围边界。** `playtimeRemainingSeconds` 的倒计时呈现与 `nicknameChangeRequired` 的改名流程落屏**已由 `inbox/solution-draft-backend-batch-client-obligations.md` 的 A / B 两项承担**（`awaiting-review`），本草稿**不重复设计**，只在两处与它衔接：那两项所依赖的 `GET /v1/compliance/status` 调用点由本草稿定为 `ComplianceManager` 的单点，且两份须成对采纳（见「前置依赖」）。

## 约束（来自既有设计）

- **`code` → `ERR_*` 是机械变换**（`ERR_` + 全大写 + `.` 换 `_`），二级键 = 一级键 + `_` + `reasonKey` 转 UPPER_SNAKE；**不得手写第二张对照表**；`reasonKey` 取值集合的权威在后端契约，**本库不复述取值**。→ `ux/error-and-blocking-ux.md`
- **阻塞屏变体表的准入判据：只由已知后端 `code` 触发、且玩家没有任何自愈路径**，二者缺一即不进。→ `ux/error-and-blocking-ux.md`「什么不进这张变体表」
- **硬阻塞只有两处，且只由已知 `code` 触发；一个 `code` 永远不得新增第三处硬阻塞。** → `systems/architecture.md` 总则 7、`systems/services/sync-service.md`「三条不变式」①
- **`code → (OpError, 处置)` 是数据表不是 switch**，新增 `code` = 表里加一行（纯追加）。→ `systems/architecture.md`
- **客户端不读年龄、不做任何本地合规拦截**，只承接后端 `code` 展示对应 `ERR_*` 文案。→ `decisions/ADR-0024`、`systems/monetization.md`
- **设备时钟不可信**；任何「还剩多久」一律用服务端算好的相对量，不做本地时刻比较。→ `systems/services/account-service.md`（`reauthRecommended` 三条）
- **鉴权 / 流程材料不出服务 API 面**（`deviceId`、refresh token 均为 `AuthManager` 私有，**不提供公开取值方法**）——一个公开取值口就把「挂个本地判断」变成一行代码的距离。→ `systems/services/account-service.md`
- **翻译分区划的是「界面」不是「内容域」**；`ERR_` 分区保留给机械变换，人不得手写。→ `ux/error-and-blocking-ux.md`「键命名规范」
- **绑定 / 昵称等账号管理落在主菜单的 PlayerProfile 屏，不在登录屏**；两处必须的二次确认已有先例。→ `ux/screen-flow.md`、`ux/onboarding.md`
- **服务是 autoload、manager 不是**；跨服务只经 `Xxx.Instance.Method(...)`。→ `systems/architecture.md`

## 建议方案

### 一、三条新 `code` 的 `ERR_*` 键：零新增纪律，三行数据表 + 若干翻译条目

`[既有推演]`

三条码**全为 `Fatal`、全映 `OpError.Compliance`**（对侧 §11 已定，与本库既有的合规映射逐条对上）⇒ **不新增 `OpError` 成员**、**变体表一格不动**、**不新增硬阻塞**。客户端侧的全部动作只有两件：

**(1) 在 `code → (OpError, 处置)` 数据表追加三行**（纯追加，与「新增 `code` = 表里加一行」逐字一致）：

| `code` | `OpError` | 客户端处置 |
|---|---|---|
| `compliance.ticket_invalid` | `Compliance` | **结束当前合规流程 → 回登录屏**（重新 `signin` 取新 ticket）。三种 `reasonKey` 只驱动措辞，处置同一条 |
| `compliance.verification_failed` | `Compliance` | **留在实名表单屏、允许重填**（受 `rate.limited` 约束）；**保留玩家已输入的内容、不自动清空**——被拒的通常只有一项 |
| `compliance.deletion_irrevocable` | `Compliance` | 呈现终态提示、**无重试动作**；出口回发起点（登录屏 / PlayerProfile 屏），且此后不再呈现撤销入口 |

**(2) 在 `res://text/errors.csv` 补翻译条目**，键全部由机械变换得出：

| 层级 | 键 | 来源 |
|---|---|---|
| 一级 | `ERR_COMPLIANCE_TICKET_INVALID` | `code` 的像 |
| 一级 | `ERR_COMPLIANCE_VERIFICATION_FAILED` | 同上 |
| 一级 | `ERR_COMPLIANCE_DELETION_IRREVOCABLE` | 同上；**该码不设 `reasonKey` ⇒ 它只有这一个键** |
| 二级 | 一级键 + `_` + `reasonKey` 的 UPPER_SNAKE 像 | 逐条按**对侧 §11 的取值表**补，**本库的设计文档里不再抄一张取值表** |

三条连带，都是既有纪律的直接兑现、**不需要为合规域新立任何规则**：

- **正向审计自动覆盖三条一级键**——`ErrorText.AuditTranslations()` 遍历的正是处置表的全部已知 `code`，(1) 落地后三条新码自动进入枚举面，缺条目即在启动期报出。
- **反向审计不会误报二级键**——判据已放宽为「以某个已知 `code` 的像为前缀 + `_` + 一段 UPPER_SNAKE 后缀」，新增的二级键天然合法；`deletion_irrevocable` 只有一级键，等于该 `code` 的像，同样合法。
- **`errors.csv` 里的二级行不是「第二张取值表」。** 它是**措辞的载体**，不是取值域的声明：漏写一条 → 该情形走未知回落（一级文案），是既定的可降级失败；多写一条 → 反向审计前缀匹配照样放行、该键永不被取用。**本库因此仍不持有 `reasonKey` 清单**，「不复述取值」这条纪律在设计文档层面完整成立。

### 二、三条新码在哪一屏呈现：全部落在**发起该操作的那一屏**，一屏不新增

`[既有推演]`

三条都是**合规域端点自身的操作错误**（对侧 §4 §11：不受「拦截只在 `signin`」约束），即玩家**主动点了某个按钮之后**收到的失败——它们与四条**拦截**码在结构上是两类东西。

- **`verification_failed` / `ticket_invalid`（实名路径）** → 实名表单屏内联呈现。
- **`ticket_invalid`（撤销注销路径）** → 撤销确认处内联呈现 + 回登录屏。
- **`deletion_irrevocable`** → 撤销确认处内联呈现终态。

**三条一律不进 `BlockingNoticeScreen` 的变体表**，判据逐条核过：

| 判据 | `verification_failed` | `ticket_invalid` | `deletion_irrevocable` |
|---|---|---|---|
| 由已知 `code` 触发 | ✅ | ✅ | ✅ |
| **玩家没有任何自愈路径** | ❌（重填即可） | ❌（回登录屏重取 ticket） | ❌（回登录屏，可正常登录——冷静期已过意味着注销已生效或正在执行，玩家的下一步是接受或重开账号） |

二者缺一即不进 ⇒ 三条全不进。**更硬的一条理由：变体表的准入若在此松动，就会新增第三处由 `code` 触发的硬阻塞**，直接违反 `architecture.md` 总则 7 与 `sync-service.md` 三条不变式①。

### 三、四条**拦截**码的呈现落在登录屏本身，不进阻塞屏

`[既有推演]`

这一条是切分问题的前半，必须先答：**拦截全部发生在 `signin` 应答**（对侧 §4 承重），此刻玩家正在**登录屏**、手里没有 token。

- **一级呈现 = 登录屏就地呈现 `ErrorText.For(code, reasonKey, error)`**，`SignInAsync` 返回的 `OpResult` 失败侧照既有路径分流。登录屏本就是「未登录」的既定正常态承载屏（`TryGetSession` 已定为可选缺失），**它不是阻塞屏、也不需要变成阻塞屏**。
- **准入判据逐条不成立**：`realname_required` → 去实名；`playtime_blocked` → 到点再来（`resumeAtUtc` 已下发）；`account_deleting` → 撤销；`account_restricted` → 站外申诉，且**登录屏可换账号登录**本身即一条出路。四条都有自愈路径 ⇒ 一条也不进变体表。
- **主动作按钮落在登录屏上**，各自一个：

  | `code` | 登录屏主动作 | 去向 |
  |---|---|---|
  | `compliance.realname_required` | 「去实名」 | 实名屏（未登录态，凭 ticket） |
  | `compliance.playtime_blocked` | **无动作**（只呈现文案 + `resumeAtUtc`） | 停留 |
  | `compliance.account_restricted` | 「申诉」（站外链接） | 系统浏览器；`Banned` / `UnderReview` 只有措辞差异 |
  | `compliance.account_deleting` | 「撤销注销」 | 就地二段确认 → 凭 ticket 调撤销 |

- **`resumeAtUtc` 的呈现只做绝对时刻的格式化，不做倒计时**——倒计时需要本地时钟参与，撞「设备时钟不可信」。**会话内的剩余时长呈现是另一件事**，由在办草稿 B 项承担（数据源是 `playtimeRemainingSeconds` 这一相对量）。
- **防沉迷中途到点不归 `ComplianceManager`**：对侧 §7 已把它映射进 `auth.session_revoked`，客户端走**既有**的硬阻塞重登路径（`AuthManager` + 阻塞屏「被挤下线」变体），本方案**一个字都不改它**。

### 四、`ComplianceManager` 的覆盖面：只做「编排与呈现驱动」，不做任何判定

`[既有推演]`

切分判据一句话：**凡需要「一段流程」（多于一次请求、或需要持有一个流程内凭据）的，归 `ComplianceManager`；凡只是「把一次失败说清楚」的，归发起它的那一屏。**

| 域 | 环节 | 归属 | 落屏 |
|---|---|---|---|
| **实名** | `signin` 被 `realname_required` 拦 | **登录屏**（呈现） | 登录屏 |
| | 表单填写 + 提交 + 失败分流 + 成功后重走 `signin` | **ComplianceManager**（编排 + 持 ticket） | 实名屏（登录流程内） |
| **防沉迷** | 拦截呈现 + `resumeAtUtc` | **登录屏** | 登录屏 |
| | 会话中途到点 | **`AuthManager`**（既有 `session_revoked` 路径） | 阻塞屏（既有变体） |
| | 剩余时长呈现 | 数据由 `ComplianceManager` 的 status 单点提供；**呈现形态见在办草稿 B 项** | — |
| **注销** | 申请 / 撤销（已登录态） | **ComplianceManager** | PlayerProfile 屏 |
| | 冷静期内被拦 + 撤销（未登录态，凭 ticket） | 呈现归**登录屏**，调用归 **ComplianceManager** | 登录屏 |
| **数据导出** | 申请 + 轮询 + 打开下载链接 | **ComplianceManager** | PlayerProfile 屏 |
| **昵称须改名** | `nicknameChangeRequired` 的读取 | `ComplianceManager` 的 status 单点 | **流程与落屏见在办草稿 A 项** |
| | 改名提交本身 | **`AuthManager`**（`SetNicknameAsync`，既有） | 既有改名入口 |

**四件明确不归它的事**（写下来是为了防日后被「补全」）：

1. **任何判定**——不读年龄、不比时钟、不算时段、不判是否未成年。`isMinor` / `playtimeRemainingSeconds` 只作**呈现的输入**，永不用于决定能否继续游玩（ADR-0024 + 既有「客户端不做本地拦截」）。
2. **会话中途下线**——`AuthManager` 的既有路径。
3. **昵称合法性判定与提交**——既有 `SetNicknameAsync`。
4. **拦截错误的措辞选择**——那是 UI 层 `ErrorText` 的事，manager 不碰文案。

### 五、`complianceTicket` 只在内存里，绝不落盘、绝不出 API 面

`[既有推演]`

ticket 寿命 10 分钟、一次性、单端点（对侧 §3 §9）。

- **只在 `ComplianceManager` 内存持有**，随进程消亡。落盘就造出一个「过期了还在生效」的本地状态——与 `reauthRecommended` 被判定为「只在内存里持有、绝不落盘」**逐字同一条论证**；且它会给 `user://cache/` 添一份需要自己的失效口径的小文件，而它的失效口径（10 分钟）恰恰是**客户端不该自己判的**（设备时钟不可信）⇒ 落盘后唯一正确的读法仍是「拿去试一次，失败就回登录屏」，那与不落盘完全等价。
- **不出任何服务的 API 面**——不提供 `TryGetComplianceTicket()` 这类取值方法，与 `deviceId` / refresh token 同款手法。实名屏与登录屏都**看不见 ticket**：它由 manager 从拦截错误的 `detail` 里取出、在下一次请求时自己填上。
- **过期 / 已消费的唯一发现方式是拿去用一次**，收到 `compliance.ticket_invalid` 即按上表处置回登录屏。**客户端不做任何过期预判**。

### 六、注销 / 导出的入口落 PlayerProfile 屏，不新增主菜单入口、不进设置屏

`[既有推演]` + `[通行做法]`

- **PlayerProfile 屏已是账号管理的既定落点**（绑定列表 + 昵称，`ux/screen-flow.md`）；注销与导出是同一类账号级低频操作，落在同一屏是既有结构的直接延伸。
- **不新增主菜单入口**——与「持有的古宝不为它新增主菜单入口」同一条克制纪律；且主菜单入口的克制布局本身是承重设计。
- **不落设置屏**——设置屏的语义是「音量 / 战斗 / 语言 + 一行只读诊断」，账号级不可逆操作放进去会撑破它已定的三段结构。
- **国内应用商店审核查「App 内可注销」的路径深度要求由此满足**：主菜单 → PlayerProfile → 注销，两跳可达且入口常驻可见。

呈现要点（全部是既有纪律的应用，非新增）：

- **注销须二段确认**（不可逆 + 永久丢全部进度），与「解绑」二次确认同一条判据；确认文案须明写**冷静期天数与生效时刻取自应答的 `deletionEffectiveAtUtc`**，不硬编码天数（那是对侧的可调旋钮）。
- **导出：** 申请 → 按应答的 `pollAfterSeconds` 轮询（**不硬编码间隔**）→ `Ready` 时呈现下载入口，用系统浏览器 / 下载器打开 `downloadUrl`（该请求不带 `Authorization`，对侧已定）。**四个任务状态各一句话**，`Failed` / `Expired` 的出路都是「重新申请」。
- **`taskId` 不落盘、只在内存**：丢失即重新 `POST export`，对侧幂等已保证命中同一任务。这消掉一份 `user://` 文件及其失效口径，且与既有 `user://cache/` 文件的判据一致（那几份都有「跨启动必须稳定」的硬理由，本值没有）。
- **轮询只在该面可见时进行，离屏即停；不进 `_Process`**（与图鉴屏「ViewModel 随屏出生随屏消亡」同款工程纪律）。
- **文案分区不新开。** 登录流程内的实名 / 撤销走 `LOGIN_` 分区；PlayerProfile 屏的注销 / 导出走 `PROFILE_` 分区。**不建 `COMPLIANCE_` 分区**——分区划的是「界面」不是「内容域」，这是分区表已明写的边界。本地业务提示（如「请输入姓名」）走所属分区普通键，**不占 `ERR_` 前缀**。

### 七、`GET /v1/compliance/status` 的单点与失败降级

`[既有推演]` + `[通行做法]`

- **调用点唯一：`ComplianceManager`，排在 `signin` 成功之后、主菜单之前**（合规态没有任何下行通道——对侧 §2 已论证 `AccountInfo` 不承载它 ⇒ 必须有这一次请求）。在办草稿 A / B 两项所需的 `nicknameChangeRequired` 与 `playtimeRemainingSeconds` **共用这一次**，不各开一次。
- **PlayerProfile 屏进入时可再取一次**（冷静期状态会变化，且对侧已定该端点须 `no-cache`）。**这不是第二个真值源**——两次都是同一个 manager 的同一个方法，取回即用即弃，**不缓存、不落盘、不进 Profile**。
- **失败按「可选缺失」降级**：`server.unavailable` → 退避重试一次 → 仍失败则 `GD.PushWarning("[Compliance-Status] fetch failed; continuing without compliance surface")` + **照常进主菜单**，本次会话不呈现倒计时 / 须改名等附加合规面。**不阻塞启动链**——合规的强制力在 `signin` 的拦截（后端权威），status 只驱动呈现；让一次呈现性请求卡住启动，等于把一个可降级失败升级成登不上游戏。

## 具体形态（可 derive 的落地面）

### `ComplianceManager` 经 `AccountService` 暴露的方法（形态 B，`Task<OpResult<T>>`）

> 服务是 autoload、manager 不是 ⇒ 能力经服务 API 面暴露。**字段语义的权威在 `backend-design-documents/contracts/compliance.md` §10，本表只定 C# 侧的调用形状与可空性。**

| 方法 | 完整签名 | 失败语义 |
|---|---|---|
| 查合规态 | `Task<OpResult<ComplianceStatus>> GetComplianceStatusAsync(CancellationToken ct)` | 可降级（见第七节） |
| 提交实名 | `Task<OpResult<RealnameResult>> SubmitRealnameAsync(string realName, string idNumber, CancellationToken ct)` | 业务失败 → `OpResult`；**ticket 不进签名** |
| 申请注销 | `Task<OpResult<DeletionInfo>> RequestAccountDeletionAsync(CancellationToken ct)` | 业务失败 → `OpResult` |
| 撤销注销 | `Task<OpResult> CancelAccountDeletionAsync(CancellationToken ct)` | 同上；**鉴权态 / ticket 态由 manager 内部择一，调用方不分辨** |
| 申请导出 | `Task<OpResult<ExportTaskInfo>> RequestDataExportAsync(CancellationToken ct)` | 同上 |
| 查导出任务 | `Task<OpResult<ExportTaskInfo>> GetDataExportTaskAsync(string taskId, CancellationToken ct)` | 同上 |

```csharp
public enum ComplianceRealnameStatus { NotSubmitted, Pending, Verified, Failed }
public enum ExportTaskStatus        { Pending, Ready, Failed, Expired }

public readonly record struct ComplianceStatus(
    ComplianceRealnameStatus RealnameStatus,
    bool                     IsMinor,
    int?                     PlaytimeRemainingSeconds,
    DateTime?                PlaytimeResumeAtUtc,
    DateTime?                DeletionEffectiveAtUtc,
    bool                     NicknameChangeRequired);

public readonly record struct RealnameResult(ComplianceRealnameStatus Status, bool IsMinor);
public readonly record struct DeletionInfo(DateTime EffectiveAtUtc, bool Deduplicated);

public readonly record struct ExportTaskInfo(
    string           TaskId,
    ExportTaskStatus Status,
    DateTime         RequestedAtUtc,
    int?             PollAfterSeconds,
    string           DownloadUrl,            // 仅 Ready；否则 string.Empty
    DateTime?        DownloadExpiresAtUtc,
    long?            SizeBytes);
```

- **枚举成员名与对侧的字符串取值逐字相同**（`envelope.md` §2 已定枚举跨边界即成员名），故两侧不需要任何映射表。
- **可选字段一律用可空类型**（对侧「不下发 `null`，可选字段缺席即省略」）；`bool` 型可选字段缺席即 `false`。
- **`ComplianceStatus` 不进 `PlayerProfile`、不进存档、不落盘**——它是会话中途会变的呈现输入，进 Profile 即制造第二真值（与对侧否决「合规态随 `AccountInfo` 下行」同一条理由）。

### 数据表与翻译资源的增量

| 落点 | 增量 |
|---|---|
| `code → (OpError, 处置)` 数据表 | **+3 行**（见第一节）；`OpError` 枚举**零改动** |
| `res://text/errors.csv` | +3 条一级键；二级键按对侧 §11 取值表逐条补 |
| `LOGIN_` 分区 | 实名屏与撤销确认的框架文案 |
| `PROFILE_` 分区 | 注销 / 导出区的框架文案与四个任务状态说明 |
| `BlockingNoticeKind` 与变体表 | **一格不动** |
| `user://` 文件 | **零新增** |
| 存档 schema | **零影响、零迁移、不 bump** |

### 屏幕面增量

| 屏 | 增量 |
|---|---|
| 登录屏 | 四条拦截码的呈现 + 各自主动作按钮（穷举四条，见第三节） |
| **实名屏（新增一屏）** | 登录流程内、未登录态可达；姓名 + 证件号两输入 + 提交；失败内联。竖屏单列、触控目标尺寸、安全区内、无 hover-only 可供性 |
| PlayerProfile 屏 | 新增「账号注销」与「数据导出」两区（低频操作，排在绑定列表与昵称之下） |
| 主菜单 | **零增量**（除非采纳待决 #2 的常驻提示） |

## 后果

- **不新增硬阻塞、不动阻塞屏变体表、不增 `OpError` 成员、不 bump 存档 schema、不新增 `user://` 文件、不新开翻译分区。** 全部增量集中在一张数据表的三行、若干翻译条目、一屏新增与两屏的区块新增。
- **对后端零新增义务**——本草稿全部落在对侧已落笔的报文之内，不要求对侧改任何字段。
- **`account-service.md` 的 derive 卡点由此可减一条**（`ComplianceManager` 覆盖面切分）。就绪度的重估归 `/assess-derive-readiness`，**本草稿不判定**。
- 影响文档：`systems/services/account-service.md`（覆盖面 + API 面六行 + 待决问题移除一条）· `ux/error-and-blocking-ux.md`（三条新键 + 变体表准入的一次复核留痕）· `systems/architecture.md`（数据表三行）· `ux/screen-flow.md`（实名屏 + PlayerProfile 两区）。

## 备选方案（已考虑并否决）

- **给合规拦截做阻塞屏的第四个变体** — 撞变体表准入判据（四条拦截码都有自愈路径），且会新增**第三处由 `code` 触发的硬阻塞**，直接违反总则 7 与三条不变式①。
- **三条端点错误码各自进变体表** — 同上；且它们是玩家主动操作的失败，天然属于「发起它的那一屏」。
- **在本库另写一张 `reasonKey` → 二级键的对照表** — 正面违反「能机械变换的绝不建第二张手写表」，并制造一份会随对侧扩表而漂移的副本。
- **`complianceTicket` 落 `user://cache/`** — 造出一个「过期了还在生效」的本地状态；且它的失效口径依赖时钟，而客户端时钟不可信 ⇒ 唯一正确的读法仍是「试一次」，落盘零收益。
- **`taskId` 落盘以便跨启动续查** — 对侧 `POST export` 的幂等已覆盖「丢失 `taskId`」这唯一用例；落盘要为它引入一份文件的失效口径，纯负担。
- **新开 `COMPLIANCE_` 翻译分区** — 分区划界面不划内容域（分区表已明写）；合规文案分属登录流程与 PlayerProfile 屏两处界面。
- **注销 / 导出入口落设置屏或新增主菜单入口** — 前者撑破设置屏已定的三段结构，后者违反主菜单入口的克制布局。
- **客户端自行判定 ticket 是否过期 / 是否未成年 / 是否在允许时段** — 全部撞「客户端不读年龄、不做本地拦截」与「设备时钟不可信」。
- **`GET status` 失败即阻塞启动** — 把一次呈现性请求的失败升级成登不上游戏；合规的强制力在 `signin` 的拦截，不在这一次请求。
- **`ComplianceStatus` 缓存进 `PlayerProfile` 以省一次请求** — 与对侧否决「合规态随 `AccountInfo` 下行」逐字同源：会话中途会变的状态进主档即第二真值。

## 与既有决策的张力

1. **对侧 `envelope.md` §6 台账把四条拦截码的「客户端处置」写作「阻塞屏 + XX 动作」，而本方案提议一律落登录屏。**
   - 这**不是设计冲突**：`compliance.md:365` 与该文件的跨库待办已明写呈现形态归客户端库、对侧不代为决定，故裁决权在本库；本库的变体表准入判据也给出了明确结论。
   - 但**措辞层面两侧读起来不一致**，后来者按台账那一列实现就会造出第三处硬阻塞。**建议在对侧同批把该列改为回链客户端库**（形如「呈现形态见 `game-design-documents/ux/error-and-blocking-ux.md`」）。**本草稿是单库分片，不代为修改对侧**——这一条须由用户裁决后另跑一次跨库落笔。

   → 已裁决（2026-09-03 · 批量评审）：**授权把对侧 `envelope.md` §6 台账那一列改为回链客户端库**（形如「呈现形态见 `game-design-documents/ux/error-and-blocking-ux.md`」）。语义不变，只消除措辞不一致。**本批不执行**——它改的是对侧主题文档，须由 `/analyze-new-ideas` 跨库落笔时同批完成。
2. **`OpError.Compliance` 的兜底语义（「账号当前无法进行此操作」+ 客户端「`Compliance` 档 = 不可重试」的静态推理）与 `verification_failed` 的「允许重填表单」处置表面相抵。**
   - 对侧 §11 已就此论证：客户端的映射是逐 `code` 表，`OpError` 只作兜底 ⇒ **不冲突**。
   - **但本库的数据表那一行必须写明处置**，否则实现者会照 `OpError` 兜底把表单锁死。这正是第一节 (1) 那张表存在的理由，已落笔。
3. 其余各项**未发现与既有决策的张力**：变体表准入、硬阻塞不变式、机械变换、鉴权材料不出 API 面、分区表边界、主菜单入口克制——本方案逐条是它们的直接应用而非例外。

## 前置依赖

- **与 `inbox/solution-draft-backend-batch-client-obligations.md` 须成对采纳。** 本草稿定的 `GET /v1/compliance/status` 单点是那份草稿 A（`nicknameChangeRequired` → 强制改名）与 B（`playtimeRemainingSeconds` → 剩余时长呈现）两项的**唯一数据源**；只采纳一份会让 status 的调用点在两处各写一遍，或让 A / B 两项落空。**两份不冲突**——本草稿不设计 A / B 的呈现形态，只提供数据与调用点。
- **A 项的强制力边界待其自身评审确认。** 本草稿第七节把 status 失败定为可降级（不阻塞启动）；若 A 项要求「须改名」具备更强的强制力，那需要对侧在 `signin` 侧补一条拦截——**本草稿不代为决定**，两份合并评审时一并看。
- **不依赖任何仍待答的问题。** 对侧合规域六端点报文与三条错误码均已落笔，本方案所需的语义全部就位。
- **待决 #1 / #2 未定不阻塞其余部分落笔**：两条都只影响一处呈现细节，其余七节可独立采纳。

## 仍需用户决定

1. **账号注销的确认强度。**
   - **(a) 就地二段确认（推荐）** —— 「注销账号」→「确认注销 · 将于 <生效时刻> 生效，此前可撤销」。与既有两处二次确认（解绑 / 绑定冲突）同形，**不发明第三种确认语言**；误触的兜底由 15 天冷静期 + 撤销通道承担（对侧取冷静期上界正是为此）。
   - (b) 强确认（要求输入昵称或走一次短信验证码） —— 把误触概率再压一档，代价是引入本作目前没有的第三种确认形态，且短信路径要复用 `RequestChallengeAsync` 并新增一个 `ChallengePurpose` 成员（契约面增量）。
   - **理由：** 冷静期已把「误触」的后果从不可逆降为「15 天内可反悔」，(b) 的边际收益小于它引入的一种新交互语言。

   → 已裁决（2026-09-03 · 批量评审）：**取 (a) 就地二段确认**。不新增 `ChallengePurpose` 成员，契约面零增量。

2. **冷静期内（已申请注销、仍可正常游玩）要不要在 PlayerProfile 屏之外常驻提醒？**
   - **(a) 只在 PlayerProfile 屏内呈现（推荐）** —— 安静，符合「不在最高频操作上加提示」；玩家进账号面才看见「注销将于 X 生效 · 撤销」。风险：玩家可能忘了自己申请过，15 天后进度永久消失。
   - (b) 主菜单一条**可关闭横幅**（复用「建议更新」横幅的既有形态与频次护栏） —— 有先例、成本低，代价是主菜单多一条可能被玩家长期忽略的横幅。
   - (c) 主菜单**常驻不可关闭**的提示 —— 最强告知，但把一条状态提示做成永不消失的打扰，与整个 UI 的克制取向相抵。
   - **理由：** 倾向 (a)，因为注销是玩家**主动发起、有明确心智**的操作，不同于「版本旧了」这类玩家不知情的状态；但「进度永久消失」的后果量级确实高于既有任何一条横幅所提示的事，故这一条的取舍权交给你。若选 (b)，建议**不套用「每个取值只提示一次」的护栏**——冷静期只有一次、关掉即永久关掉不合适，应改为「每次冷启动提示一次」。

   → 已裁决（2026-09-03 · 批量评审）：**取 (a) 只在 PlayerProfile 屏内呈现**。主菜单不加横幅、不加常驻指示。

> 其余子项（实名屏的具体版式 · 导出区四个任务状态的措辞 · 申诉链接的落点与来源 · PlayerProfile 屏内两区的排序）属既有约定内的常规落地，未列为取向；落笔时按各自主题文档的既有形态处理即可。三条 `ERR_*` 键与二级键因是机械变换，**不构成任何取向**。
