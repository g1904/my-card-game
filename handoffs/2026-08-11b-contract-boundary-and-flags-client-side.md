# 契约边界层的客户端侧承接：传输信封 · 错误码映射 · Upgrade 处置 · flags 第三层

- id: 2026-08-11b-contract-boundary-and-flags-client-side
- date: 2026-08-11
- topic: systems/architecture（总则 4 启动链 · 总则 7 新增映射小节）· systems/services/sync-service · systems/services/content-service · systems/services/account-service
- status: distilled
- distilled-to: systems/architecture.md, systems/services/sync-service.md, systems/services/content-service.md, systems/services/account-service.md, open-questions/05-service-contracts.md, open-questions/deferred-content.md, answer-logs/log-0811_2.md

## Intent（distilled）

**一句话：** 后端两份 08-11 契约 handoff（`envelope` 与 `content-delivery`）的客户端侧一次承接——**传输信封走 HTTP 头、客户端 record 一字不改**；**错误处置以 `code` 为键的数据表**，未知项按 `class` 走四条保守默认路径，**硬阻塞仍只有两处且只由已知 `code` 触发**；**`Upgrade` 类错误在非闸门点不硬阻塞，但闸门口径不变、只换模态文案**；`ContentEnabled` 多出 **flags 第三层覆盖来源**，`AllEnabled()` 取池随之三层合并。

来源：`backend-design-documents/handoffs/2026-08-11-contract-expression-envelope-and-error-codes.md`「客户端侧影响」段五点，以及它牵出的 `backend-design-documents/handoffs/2026-08-11-content-delivery-manifest-signing-and-flags.md`「客户端侧影响」段五点——后者的 flags 通道正是前者第 2 点（`X-Flags-Version`）的承接对象，**分开写会让 `content-service.md` 引用一个它没定义的通道**，故本次一并吃下。

本 handoff **不**改动任何客户端 record / 存档 schema：传输信封是 `HttpXxxBackend` 内部的搬运，flags 是运行时态、不入存档。

### 1. 传输信封：客户端 record 不改，`HttpXxxBackend` 搬字段

**报文字段名与客户端字段名不同是契约允许的**；对位关系在客户端侧只需记明一次。

| 客户端持有 | 报文位置 |
|---|---|
| `Session.Token` | `Authorization: Bearer <token>` 请求头 |
| `ProfilePayload.AppVersion` | `X-App-Version` 请求头（semver 三段） |
| `ProfilePayload.ContentVersion` | `X-Content-Version` 请求头 |
| — （新增，仅日志） | `X-Request-Id` 请求头 |
| `ProfilePayload.PushId` / `.BaseRevision` / `.SchemaVersion` / `.Reason` | **留在 push body 的负载信封段** |

- **`X-Request-Id` 与 `pushId` 是一对反向纪律，不可混同：** `pushId` 是幂等键，**跨启动重试必须不变**；`X-Request-Id` 是日志关联键，**每次重试都必须换**。两者写在同一个请求里，写反哪一个都会静默失效——一个丢进度，一个让日志无法定位单次尝试。
- **`baseRevision` / `pushId` 不搬到头、不用 `If-Match`/ETag 表达 CAS。** CAS 前置条件与它保护的负载留在同一层面；已定案的三分支应答本就要在 body 回 `cloudRevision`。既定 record 与三分支表原样成立。
- **应答头的读取点是共享的**：三个 `HttpXxxBackend` 不各写一遍请求头组装与应答头解析，收敛到 `src/Core/` 的一处——与 `BackendSelector` 唯一选择点同构（多于一处就会出现「一部分带了头、另一部分没带」的半配置态）。
- **应答头的客户端语义：**

  | 头 | 客户端处置 |
  |---|---|
  | `X-Flags-Version` | 与内存中的 `flagsVersion` 不同 → 触发一次全量 flags 拉取（见第 4 节） |
  | `X-Min-App-Version` | **仅诊断，客户端不比较、不据此阻塞**——硬闸门判定权在服务端 |
  | `X-Recommended-App-Version` | 软提示「有新版本」，**永不阻塞** |
  | `X-Server-Time` | **纯诊断**的时钟偏差观测；不参与任何玩法判断，**也不用于校正本地时钟** |
  | `Retry-After` | 退避下界（见第 2 节） |

- **序列化约定的客户端侧后果：** 枚举值为字符串且**与 C# 枚举名逐字相同**（`SavePointReason.EventResolved` → `"EventResolved"`）⇒ **重命名一个跨边界枚举值即是破坏性契约变更**，必须与后端同批改，不能当作纯客户端重构。其余（lowerCamelCase 字段名 · 两侧都忽略未知字段 · 时间 RFC 3339 UTC 带 `Z` 且字段名以 `AtUtc` 结尾 · `revision` 以 JSON number 传输 · 不下发 `null`）对客户端形态无影响。

### 2. 限流与退避：`Retry-After` 是下界

- `rate.limited` → `OpError.Network`，走**既有断线降级通道**：变更进本地待发队列、不阻塞玩家、指数退避重试。
- **退避间隔取 `max(本地退避计算值, 服务端给的等待时间)`**——`Retry-After` 头或 `detail.retryAfterSeconds`，二者取到哪个用哪个。服务端值是**下界不是精确值**：本地抖动（jitter）照常叠加，避免同一批客户端在同一秒齐步重试。
- **限流绝不映 `Conflict`。** 限流不改变 `cloudRevision`，原样重试即可（`pushId` 保证幂等）；映成 `Conflict` 会按既定语义丢弃本地缓冲——把一次限流变成一次进度丢失。

### 3. 错误码 → `OpError`：一张数据表，不是 switch

**落点：`systems/architecture.md` 总则 7 下新增小节（契约文字）+ `src/Core/`（三个 `HttpXxxBackend` 共用的实现）。** 依据：总则 7 是「后端接口化」的既有权威落点，共享核心类型一律在 `src/Core/`；逐服务的具体处置仍留在各服务文档。

- **形态是数据表**（`code → (OpError, 处置)`），不是 switch 语句——与「新增内容 = 新增数据，不编辑 switch」的可加性纪律一致。新增一个后端 `code` = 表里加一行。
- **三条承重纪律（客户端侧）：**
  1. **不得靠 HTTP 状态码分支**，业务分支一律以 `code` 为键。状态码只承担传输层语义。
  2. **不得解析 `message` 做任何分支**——措辞可随时改写，依赖它的分支会在某次后端改文案时静默失效。需要被代码消费的值一律取 `detail`。
  3. **`message` 不进玩家可见弹窗。** 它是英文调试串：与 `requestId` 一起拼进 `OpResult.Detail`，随 `GD.PushError` / `GD.PushWarning` 输出。`requestId` 是**跨越进程边界的那个定位标识符**，正是客户端日志纪律要求的东西。玩家可见文案由 UI 层决定。
- **默认路径（未知 `code` 按 `class` 降级；未知 `class` 当作 `Fatal` + 上报一次）：**

  | `class` | 默认 `OpError` | 默认处置 |
  |---|---|---|
  | `Retryable` | `Network` | 既定断线降级（进待发队列 + 退避 + 不阻塞） |
  | `Fatal` | `Validation` | 拒绝本次操作 + **上报一次** |
  | `Reauth` | `Auth` | **静默刷新一次；刷新失败视同断线**走同一缓冲通道 |
  | `Upgrade` | `Validation` | 非闸门点的非阻塞处置（第 5 节） |

  **承重推论：硬阻塞仍然只有两处，且只由已知 `code` 触发**——`auth.session_revoked`（被挤下线）与登录 / 启动 pull 点的 `client.version_unsupported`。**一个未知 `code` 永远不得新增第三处硬阻塞**：未知 `Reauth` 走保守的静默刷新而非硬阻塞重登，代价是一个真失效的会话可能多跑一小会儿（下一次操作仍会被拒），收益是一条后端新加的错误码不可能打断玩家进行中的轮回。
- **应答体无法解析为契约错误体**（网关 502、非 JSON 错误页）→ 按 HTTP 状态码降级为 `server.unavailable`（`Retryable`）。不要求网关也产出契约错误体。
- **`OpError.Cancelled` 与 `OpError.Migration` 不得出现在映射表的取值域里。** 前者是 `CancellationToken` 的本地语义，后者是 `MigrationManager` 的本地存档迁移失败。后端拒绝一个它不认识的 `schemaVersion` 是**上行校验失败**（`Validation`），映成 `Migration` 会让客户端去跑一条本地迁移路径，而问题根本不在本地。**这条可机械检查**（表的 `OpError` 列排除两值），是「纪律的可执行化」阶梯上便宜的一级。
- **映射表不含 `plot` 域。** 后端台账现存的 `plot.unavailable` 与端点表的 `/v1/plot/…` 是 08-11 剧本内容本地化之前的残留——客户端已定案剧本内容归本地内容层、`IPlotBackend` 整套作废，故客户端不映射任何 `plot.*` code，也不因此恢复任何跨边界成分。**另一侧需要一份对应 handoff**（见 Notes）。
- `auth.token_expired` / `auth.session_revoked` **两个 code 与 `account-service` 既定的两条处置逐一对上**：前者静默刷新、绝不打断轮回；后者硬阻塞重登、重登后先 pull 后 flush。这正是「必须是两个 code」的理由在客户端侧的兑现——只给一个 401，客户端只能二选一，选错哪边都直接违反一条已定案语义。

### 4. flags：`ContentEnabled` 的第三层覆盖来源

**`res://` 基线 < `user://overlay/` < flags（只覆盖 `ContentEnabled`，不改任何数值）。**「overlay 是唯一热更层」不再成立。

- **为什么这一层安全（三条，逐条对上既有纪律）：** 不改任何数值 ⇒ 不触碰合并后强校验的任何输入，校验模型原样成立；不新增 / 不删除 `Id` ⇒ 完全落在「热更只改不增」纪律内；不影响读取侧 ⇒「存档引用未知内容」的风险依然为零。**它之所以能秒关，恰恰因为它被限制得足够窄。**
- **作用点唯一：`AllEnabled()` 取池。** 读取侧 `Get(id)` 照旧不过滤；合并后强校验照旧走 `AllIncludingDisabled()`，**flags 不参与校验**。
- **首次拉取排在登录之后（对启动链的实质改动）。** `/v1/content/flags` **需鉴权**，而 content-service 是启动链**第一步**（登录之前）——两者对不上。因此 `ContentService.InitializeAsync` 仍只做 manifest 比对 + overlay 合并 + 校验，flags 的首次拉取另立一个方法，由 Bootstrap 在 `SignInAsync` **之后**、`SyncService.InitializeAsync` **之前**调用：抽取池必须在轮回开始前正确，而它失败不阻塞、排在硬阻塞的 pull 之前不增加任何阻塞风险。
- **刷新时机 = 搭车信封，零轮询。** 共享应答头处理点观察到 `X-Flags-Version` 与内存值不同 → 拉一次全量 flags。秒关的实际延迟 = 该玩家的下一次上行，分钟级以内。不引入长连接 / 第三方推送。
- **热应用：拉到即生效于下一次抽取。** 不需重启、不需重新合并 overlay、不触碰 ContentRegistry 的校验 ⇒ **轮回进行中安全**。这与数值型 overlay 不同，正是把它独立出来的收益。
- **本地缓存 `user://cache/flags.json`**（`accountId` / `flagsVersion` / `disabledIds`；原子写、跨启动保留、与 `sync-envelope.json` 同处同纪律）。
  - **后端标注的「不缓存则离线开局时被秒关的条目复活」这个缺口，在客户端并不存在**：启动 pull 是**硬阻塞**、强制在线下无权威档即不可玩 ⇒ 根本不存在「断网启动并进入轮回」这条路径。**缓存的收益因此不在离线开局。**
  - 真实收益只有一处：**登录成功但 flags 拉取失败**（网络抖动 / 该端点单独故障）时的降级值——用上一次已知 flags 优于回落到 overlay 里的布尔（后者会让被秒关的条目复活）。
  - **切账号即失效**：`accountId` 不匹配 → 丢弃（`PushError` + 定位上下文）。分桶是**按账号解析后的结果**，跨账号复用等于灰度串号。与 `sync-envelope.json` 的切账号纪律同构。
- **失败处置：`PushWarning` + 用缓存（无缓存则用 overlay 的 `ContentEnabled` 值）+ 绝不阻塞。** 下一次搭车观察到版本差异时自然重试——不需要为它另开重试机制。
- **flags 走同一密钥体系**（ES256 detached + `keyId`）。**验签失败 / `keyId` 未知 → 拒绝这批 flags + `PushError` + 上报一次 + 保留上一批**，与 overlay 验签失败 → 拒绝 + 回退基线同构。
- **分桶规则哪也不放在客户端。** 端点按账号计算后只给结果，客户端始终只看到「这些 `Id` 现在不进抽取池」，永远不知道分桶规则存在。

### 5. `Upgrade` 类错误在非闸门点：不硬阻塞，但闸门口径不变

**承重纪律：`Upgrade` 类错误只在登录 / 启动 pull 构成硬阻塞，其余时机一律降级为非阻塞。** 典型情形是 `sync.payload_schema_unsupported` 在**轮回中途的 push** 上返回，且它重试永远不会成功。

- 四条处置：**本地缓冲保留、不丢弃**（绝不回退存档点）· UI 出一条**非模态**「需更新版本才能同步」提示 · **暂停自动退避重试**（重试必然失败，退避只是空耗电量与流量）· 恢复点 = 玩家更新并**重新登录**后先 pull 后 flush。
- **暂停退避的唯一解除条件是「重新登录成功」**，不因时间流逝、不因应用重启自动恢复——退避的前提是「可能会好」，这里不会。
- **与「缓冲超限 → 软阻塞」的衔接（本次裁决）：两个闸门的口径完全不变**（未同步的事件级存档点数 ≥ 3，或最早一条待发变更滞留 ≥ 180 秒），仍在下一次 AdventureEvent 选择前弹软阻塞模态。**变的只有文案与选项**：这是同一处模态的**第二种变体**——「需更新版本才能同步」，选项「去更新 / 退出到主界面」，**没有「重试」**。
  - 理由：同步在本会话内**永不恢复**，继续玩只会累积必然无法上行的进度——软阻塞的本意正是拦住这一点。冻结闸门会让玩家整轮回打完才发现全部进度无处可去。**只有文案与选项该变，机制不该变。**
  - 沿用既定的「不打断进行中的事件（战斗打完）」时机，无需另立第三种阻塞时机。
- **UI 如何区分两种变体（自行推演）：** 既定的 `SyncStateChanged(SyncState, OpError)` 分辨不出「`Failed` + `Validation`」到底是 `sync.payload_invalid` 还是 `sync.payload_schema_unsupported`。**不新增 `SyncState` 值**，改为 sync-service 增一个只读属性 `bool UpgradeRequired { get; }`，UI 收到事件后**单点查询**——与既定的 `PendingCount`（「不塞进负载，由 UI 收到事件后单点查询本属性」）以及 `CapabilitiesChanged` 空负载完全同构。置位于收到任一 `class: Upgrade` 错误，清零于重新登录后的一次成功 pull。

### 6. 版本协商的客户端侧：两条互不兼职

| | 谁判定 | 客户端行为 |
|---|---|---|
| `minAppVersion`（manifest 内，**内容维度**） | **客户端**自行比对 | 低于它 → **跳过本次 overlay、照常用基线**，永不阻塞 |
| `X-Min-App-Version` / `client.version_unsupported`（**协议维度**） | **服务端** | 登录 / 启动 pull 点被拒 → 硬阻塞要求更新；客户端**不做这个比较** |

- **内容太新只是不更新内容；协议不兼容才拦人。**
- `minAppVersion` 的比较规则 = **semver 三段逐段整数比较**，不做字典序（字典序会判 `1.10.0 < 1.9.0`，且这类 bug 发版后才显形、无法在设备上复现）。
- **客户端不持有兼容矩阵的任何副本**（支持的 `appVersion` 下界、并存的 URL 主版本 / `manifestSchema` / `schemaVersion` 集合、下线计划）——它是服务端判定的输入，必须与判定逻辑同处。
- **`manifestSchema` 的两种情形必须分开：** 客户端内置一个「支持的 `manifestSchema` 集合」。**支持但本地 overlay 按旧 schema 落地** → 整包全量重下（既有表述）；**不受支持**（高于内置集合）→ **跳过本次更新、照常用现有 overlay / 基线**，与断网降级同构。既有文档只写了前者。

### 7. manifest 契约对位：客户端的四条义务

（后端 `content-delivery` 定案 1/2/3 落在客户端已定形态内，只补齐四条具体义务。）

- **`files[].path` 落盘前校验路径穿越**（禁 `..` 与绝对路径）——这是内容分发里唯一有实质危害的注入面。
- **`files[].size` 用于下载前的磁盘空间预检**，使「磁盘空间」这类失败提前判定，而非写到一半才失败（对上既定的 `OpError` 磁盘分支）。
- **拒绝 `contentVersion` 小于本地已生效版本的 manifest**（防回放）。**不做绝对时间 TTL**——设备时钟不可信，会误伤离线玩家。
- **内置一组 `keyId → publicKey` 映射**（不是一把）。轮换靠先发内置新旧两把的客户端版本、覆盖率足够后服务端再切私钥；没有 `keyId` 则轮换只能靠强更且事后无法补救。

## Clarifications（interview 产物）

- **点 2 牵出的 flags 通道，客户端侧吃下多少？** → **一并吃下全套**（含 `content-delivery` handoff 客户端侧五点）。理由：只写「读取点」会让 `content-service.md` 引用一个它自己没定义的通道。这扩大了原始输入（envelope 五点）的范围，是本 handoff 相对原始记录多出来的意图。
- **`Upgrade` 暂停退避与「缓冲超限 → 软阻塞」如何衔接？** → **闸门口径完全不变，只换模态文案与选项**（见第 5 节）。否决了「冻结闸门只留常驻非模态提示」（玩家可能整轮回打完才发现进度无处可去）与「只在轮回结束时阻塞」（引入既定机制里不存在的第三种阻塞时机）。
- **未知 `code` / 未知 `class` 的默认路径？** → **保守默认表**（见第 3 节），**不改后端台账**。已知 `code` 一律照台账，包括 `client.version_unsupported` → `OpError.Auth`；措辞问题由「UI 文案按 `code` 而非仅按 `OpError` 决定」回避（连带收窄既有待答项「`OpError` → 玩家文案的映射归属」）。
- **后端台账含 `plot.unavailable`、端点表含 `/v1/plot/…`，与 08-11 剧本本地化冲突，以哪一侧为准？** → **以客户端 08-11 为准**。客户端不映射任何 `plot.*`、不恢复 `IPlotBackend`；后端侧需删该端点与台账条目。这与客户端 `open-questions.md` 已挂着的「后端侧需要一份对应 handoff」是同一笔欠账。

## Open questions

- **两条「去更新」提示的呈现形态与去重**（`X-Recommended-App-Version` 的软提示 vs `Upgrade` 态的「需更新版本才能同步」非模态提示）——两条都指向同一个动作，不该在屏上叠成两个。→ `ux/`。
- **强更硬阻塞屏的形态**（`client.version_unsupported` 在登录 / 启动 pull 点）：是否跳应用商店 / 各渠道差异如何吸收。与既有待答项「迁移失败的玩家侧表现」同属一类，宜一并定。→ `ux/`。
- **flags 拉取的频次护栏**：`X-Flags-Version` 每次应答都带，若服务端版本短时间连续抖动，客户端是否需要一个最小拉取间隔（或只在版本**增大**时拉）？→ `systems/services/content-service.md`。

## Notes / triage

- 落点：`systems/architecture.md`（总则 4 启动链插入 flags 刷新一步 · 总则 7 下新增「后端错误码 → `OpError`」小节）· `systems/services/sync-service.md`（`Retry-After` 下界 · `Upgrade` 处置与闸门文案变体 · `UpgradeRequired` 属性 · 传输信封搬运）· `systems/services/content-service.md`（存储形态改为三层 · flags 通道整节 · `manifestSchema` 两种情形 · manifest 契约对位四条）· `systems/services/account-service.md`（两个 auth `code` 对位）。
- 答结 3 条：`05-service-contracts.md` 的 `pushId` 报文字段名与 `manifestSchema` 版本化、`deferred-content.md` 的 `ContentEnabled` 粒度 → `answer-logs/log-0811_2.md`。连带解除 `DrawPool<T>` 的唯一依赖（构造签名不必变成 `AllEnabled(bucketContext)`）。
- **⚠ 后端侧需要一份对应 handoff**（本次只写客户端库）：`contracts/envelope.md` §3 端点表删 `/v1/plot/…`、§6 台账删 `plot.unavailable`，并同步 `contracts/_index.md` 与 `systems/_index.md` 里 `plot.md` 的排期——理由是客户端 08-11 已把剧本内容整体本地化。此欠账与客户端 `open-questions.md` 已记的「后端侧需要一份对应 handoff」是同一笔。
- 不新增 ADR 候选：本次全部内容是既有决策（云端权威 · 仅两处硬阻塞 · 热更只改不增 · 唯一入口）在契约边界上的兑现，没有新的方向性选择。
