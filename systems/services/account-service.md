# account-service（服务）

> 账号与鉴权服务：登录渠道、token / 会话、合规。**判据 ③ —— 坐在外部 I/O 边界（平台 SDK + 后端）上。**

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **服务定位。** 本服务是**平台 SDK 与后端鉴权的唯一门面**。它把「登录成功、得到 `accountId` 与 token」这件事收敛为一个可被 mock 的边界——其余服务不接触任何渠道 SDK。强制在线下它是所有流程的前置：登录未成功则不进入主界面。
- **强制在线 · 无游客态。** 游客态已彻底移除，必须账号登录（`vision/scope.md`、`ux/onboarding.md`）。登录渠道优先级：**移动端手机 / 邮箱 → 微信 / QQ → 海外 / 跨平台**。**首版实现两条：`Phone` + `WeChat`**——Phone 是首选渠道且是实名 / 找回的天然载体，WeChat 覆盖面最大；`Email` / `QQ` 在契约里有形态但本版本不实现，追加时只增实现不增契约面。Source: `decisions/ADR-0003-online-cloud-authority.md`。
- **重账号路线。** 参考三国杀 Online 的重账号模型；账号是云端权威 PlayerProfile 的键。
- **token 失效与被挤下线的处置。** 二者**分开处理**：
  - **token 到期** → `RefreshToken()` 静默刷新。**刷新本身的失败必须按判据拆成两条，不是一条**：

    | refresh 的失败 | 判据 | 处置 |
    |---|---|---|
    | **网络失败** | 请求发不出 / 应答收不到 / `server.unavailable` | **视同断线**，走 `sync-service` 的**同一条缓冲通道**（待发队列 + 指数退避 + 缓冲上限 → 软阻塞），**不另开一套降级路径**。进行中的轮回**不被打断、不回退存档点** |
    | **明确拒绝** | 收到 `auth.session_revoked` 应答 | **硬阻塞重登**，走下一条的被挤下线路径；**暂停退避重试**（重试必然失败） |

    **判据是「收到了明确应答」，不是「失败了」。** 弱网下「服务端拒绝」与「应答没收到」不可区分，而误判成硬阻塞的代价（把一个只是信号差的玩家赶去重新登录）远大于多退避几次。这与 `Upgrade` 类错误的「暂停退避 + 恢复点 = 重新登录」结构相同。
    **分辨这两条所需的信息，API 面已经给足**：`RefreshTokenAsync` 返回 `OpResult<Session>`，失败侧带 `OpError` 与 `code`，调用方按 `code` 分流即可——**不需要为此扩签名**。真正的风险在措辞：本条此前写作「刷新失败视同断线」一句盖住两种情形，落到实现会被写成一条路径，收到 `auth.session_revoked` 的玩家将被无限退避重试卡住，而那是一次**永不恢复**的等待。契约侧对位见 `backend-design-documents/contracts/auth.md` §10。
  - **被后端明确挤下线**（多设备并发） → **硬阻塞**，要求重新登录；重登后同样**先 pull 后 flush**——若云端 `revision` 已领先，以云端为准丢弃本地缓冲，并明确告知玩家「另一设备的进度已生效」。**这一段不需要额外规则**：重登后的 pull 带回新的 `cloudRevision` 并覆写本地同步信封，随后的 flush 自然走 CAS 三分支判定（见 `sync-service.md`「`revision` 语义与幂等键」）。若重登的是**另一个账号**，信封 `accountId` 不匹配 → 丢弃信封与待发队列（必需缺失，`PushError`）。
  - **两条处置各自对上一个后端 `code`：** `auth.token_expired` / `auth.token_invalid` → 静默刷新那条；`auth.session_revoked` → 硬阻塞重登那条。**`auth.session_revoked` 有两个到达路径**（业务请求的应答 · refresh 的应答），**处置相同**——上一条的拆分正是为了让 refresh 那条路径不被吞进缓冲通道。**它们必须是两个 `code`**——若后端只给一个「401 未授权」，客户端无从区分，只能二选一，选错哪边都直接违反上面一条已定案语义。客户端因此**不得靠 HTTP 状态码分支**，一律以 `code` 为键查映射表（见 `systems/architecture.md` 总则 7 下「后端错误码 → `OpError`」）。
  - 断线降级的完整表与缓冲阈值见 `sync-service.md`。

### `deviceId` 的生成与持久化

`signin` 上行必带一个设备标识，它是后端多设备裁决与幂等回放窗口的输入。**报文字段名 / 类型 / 必填性与后端侧的裁决规则由契约钉死，本库只对位不复述**（`backend-design-documents/contracts/auth.md` §4a 与 `POST /v1/auth/signin` 请求表）。

- **由客户端生成，不由后端下发。** 它是 `signin` 请求本身的必填字段，而首次 `signin` 之前没有任何会话；要让后端下发就得新开一个**无鉴权**的「领设备号」端点，它自身还得幂等、下发的值还得被客户端持久化——**同一个持久化问题被原样推后一步**，代价是多一条协议面与一次启动期网络往返。
- **取值 = `Guid.NewGuid().ToString("N")`**：32 位小写十六进制、无连字符，校验式 `^[0-9a-f]{32}$`。跨启动稳定由落盘保证，不碰撞由 122 bit 随机性保证（无需任何注册中心或后端协调）。形态与 `AccountSeed` 的「定长小写 hex · 无前缀 · 便于校验」同向，两侧因此不需要对大小写 / 分隔符做归一。
  - **排除全部平台硬件标识**（Android SSAID / OAID / IMEI / MAC，iOS `identifierForVendor` / IDFA）：采集设备硬件标识属个人信息，须单独告知、单独同意并进入隐私清单，而 PIPL 与渠道审核是本作必须正面处理的合规面（`decisions/ADR-0003`）；而契约已宣布「重装后变化可接受」，等于把这一整类方案的**唯一卖点（卸载后仍存活）声明为不需要**。收益为零、合规成本非零。附带一提：IDFV 在同厂商 App 全部卸载后即变、SSAID 在恢复出厂与部分 ROM 上不稳定，连那个卖点也兑现不满。
  - **不由 `accountId` / `AccountSeed` 派生**：二者是**账号维度**，同账号的两台设备会算出同一个值，后端 `(accountId, deviceId)` 唯一键退化为 `accountId` 唯一键，多设备裁决与幂等回放窗口一起失效。
- **落点 = `user://cache/device-id.json`，单字段 `{ "deviceId": string }`。** 与 `dismissed-recommended-version.json` 逐条同形：设备维度 · 原子写（走共享静态工具 `AtomicJsonFile`，见 `systems/architecture.md`）· 跨启动保留 · 不进存档 / 不进 Profile / 不上云 · **不按 `accountId` 分区**。
  - **「文件里没有 `accountId` 这一格」是承重设计，不是省略。** `sync-envelope.json` 与 `flags.json` 都带这一格，其纪律是「`accountId` ≠ 当前登录账号 → 丢弃 / 重建」；本文件若也带上，同设备切账号就会重新生成一个值，而后端唯一键是 `(accountId, deviceId)` ⇒ 同设备切回原账号被判成**一台新设备**、白挤掉一次会话。**这一格不存在，该错误在结构上不可能被写出来。**
  - **不带 `schemaVersion`。** 单字段没有迁移面，那一格纯属仪式；更重的是配套口径「版本不认识就整份丢弃」在本文件上有害——一次版本不认 = 重新生成 = 一次假换设备 = 后端一次假挤下线。判据与 `user://cache/` 各文件的版本处置见 `systems/architecture.md`。
  - **不进 `PlayerProfile` / `AccountInfo`**：Profile 是账号级、云端权威、跨设备一致的主档，上云后 A 设备会读到 B 设备写的值，多设备裁决当场失效。
  - **不进 `GameSetting`**：它不是玩家可见的设置项；且与设备本地设置文件的失效口径不同（那一份「不认识就整份丢弃」是安全的，本文件不是），两者各自一份文件，见 `systems/player-profile/game-setting.md`。
  - **不与 `sync-envelope.json` 合并**：信封按 `accountId` 校验、切账号时整份丢弃，本值会被**连坐清掉**，正是上面那条要防的错误。
  - **不与 refresh token 同文件**：两者失效口径**恰好相反**——refresh token 是鉴权材料、必须在切账号 / 登出时失效，本值必须切账号不变。同处一份文件会逼出一条「清一半留一半」的写入路径，而那正是最容易写错、错了以后症状（每次切账号被挤一次）指向不明的形态。
- **归属 = `AuthManager` 私有，不出任何服务的 API 面。** 唯一消费点是 `signin` 上行，**不提供 `TryGetDeviceId()` 这类公开取值方法**——一个公开取值口就把「挂个本地判断」变成一行代码的距离。私有化把「不得把任何本地判断挂在它上面」这条纪律从**纪律阶梯第 4 级（评审清单）抬到第 1 级（跨服务代码里根本写不出来）**，与 `internal sealed` manager、`AccountSeed` 不出 API 面同款手法。**代价照录：客服排障时无法让玩家直接报设备号**（后端侧以 `(accountId, deviceId)` 为键的反查路径仍在）。
- **不落 `sync-service.LocalCacheManager`**，两条独立理由：① 边界纪律禁止本服务伸手进 sync-service 的 manager，而 sync-service 的 API 面上也不该出现「替我原子写一个任意文件」这种方法；② **启动顺序对不上**——签名发生在本服务的初始化期内、`ContentService.RefreshFlagsAsync` 之前，那一刻 sync-service 尚未初始化。
- **时机 = 惰性**（首次组装 `signin` 请求时才读文件）。**启动链第一步跑在登录之前**，此时生成一个只有 `signin` 用得上的值没有任何收益；而静默续期那条路径根本不组装 `signin` 请求，提前生成的值在它上面一次也用不到。
- **必须先落盘成功、内存里才认（承重）。** 若允许「先上行、后落盘」，一旦写盘失败就形成「本次上行用了 X，盘上没有 X」：下次启动生成 Y，玩家**每次启动都自己把自己挤下线一次**，且这个症状永不自愈。

  | 情形 | 判定 | 处置 |
  |---|---|---|
  | 文件不存在 | 可选缺失（首次运行的正常态） | 生成 → 落盘 → 使用，并打一行 `GD.Print("[Auth-DeviceId] generated new device id")`。**信息级、不是告警**——首次生成是一次不可回溯的一次性事件，静默发生则日后排查「玩家为什么被判成新设备」时无任何痕迹 |
  | 解析失败 / 字段缺失 / 不匹配校验式 / 空串 | 可选缺失（异常） | `GD.PushWarning("[Auth-DeviceId] cached device id invalid, regenerating; path=user://cache/device-id.json")` + 重新生成 + 覆写 |
  | 落盘失败 | 可选缺失（异常） | `GD.PushWarning("[Auth-DeviceId] persist failed; using in-memory id for this session")` + 本次进程用内存态值，**不阻塞登录**。后果照录：该次登录被后端记成一台新设备，可能挤掉本设备上一次的会话（玩家表现 = 一次多余的重登提示）；`user://` 写不了本身已是异常态 |

  **三处一律 `PushWarning` 而非 `PushError` + 抛**：该值永不参与鉴权，缺它不阻断任何流程，最坏后果只是后端多记一条设备记录、多做一次会话替换；抛会把一次可降级的缓存问题升级成**登不上游戏**。
- **它不进 `SignInAsync` 的签名。** 它是**传输层元数据**，与 `X-App-Version` 请求头、`baseRevision`、`pushId` 同类——由服务自己填，登录屏既无从提供也不该看见；加进签名等于把上面刚关掉的那个取值口从另一侧重新开出来。**填充点 = `AuthManager` 取到值后交给内部的 `IAccountBackend`**（不在服务 API 面上）：放这里而不是沉进 HTTP 实现层，是因为离线实现也要能拿到它记日志，且文件 I/O 不该在传输层。
- **五种情形的语义**（规则见契约，本表只列对位）：

  | 情形 | 客户端取值 | 后端侧结果 | 玩家可见后果 |
  |---|---|---|---|
  | 缓存被清 / `user://` 被删 | 重新生成 | 视作新设备；旧 `(accountId, 旧值)` 会话被吊销 | **无**——被吊销的是本机自己的旧会话，其进程早已不在 |
  | 重装 / 换机 | 重新生成 | 同上 | 同上（契约已明写「重装后变化可接受」） |
  | 多设备、同账号 | 各设备各不相同 | 活跃会话上限 1 ⇒ 后登录挤掉先登录 | 先登录那台**硬阻塞重登**（见「意图」既定语义，本条不新增） |
  | **同设备、多账号** | **不变**（文件无 `accountId` 分区） | 两条记录各成一条，互不影响 | **无** |
  | 同设备、同账号重登 | 不变 | 原地替换该条会话，旧 refresh token 立即失效；短时间内的重试落幂等回放窗口 | **无** |

  后两行正是「不按 `accountId` 分区」的兑现点：**切账号与重登都不产生一次假的挤下线。**
- **存档 schema 零影响、零迁移；后端零改动、零新增义务。**

### refresh token 的持有与失效

refresh token **不进 `Session`**，由本服务落 `user://cache/`（契约对位：`backend-design-documents/contracts/auth.md` §2 §4 §4a；rotation、宽限窗口与 TTL 的语义以契约为权威，本库不复述）。

- **落点 = `user://cache/refresh-token.json`，字段 `{ schemaVersion: int, accountId: string, refreshToken: string }`。** 原子写走共享静态工具 `AtomicJsonFile` · 跨启动保留 · 不进存档 / 不进 Profile / 不上云。
- **独立一份文件，不与任何既有文件合并**：

  | 不与谁合并 | 理由 |
  |---|---|
  | `device-id.json` | **失效口径恰好相反**——本文件必须在切账号 / 登出时失效，设备标识必须切账号不变；同处一份文件会逼出一条「清一半留一半」的写入路径 |
  | `sync-envelope.json` | 失效口径虽相同，但① 归属服务不同（本文件归 `AuthManager`，信封归 `sync-service.LocalCacheManager`）；② 启动顺序对不上——静默续期发生在登录期，那一刻 sync-service 尚未初始化；③ 合并后**一次信封丢弃会连坐清掉登录态**，玩家侧表现是一次凭空的强制重登 |
  | `flags.json` | 归 content-service；且 flags 是可降级的缓存，登录凭据不是 |
  | `device-settings.json` | 设备维度、切账号不变，与本文件相反；且它是玩家可见设置，本文件不是 |

- **`accountId` 必须在**：它正是「切账号即失效」这条性质的载体，与 `sync-envelope.json` / `flags.json` 同纪律。**这与 `device-id.json` 刻意没有这一格恰好相反**——那份文件是「这一格不存在，该错误在结构上不可能被写出来」，本文件则是「这一格存在，切账号清除才有判据」。两条纪律各自成立。
- **不存过期时刻。** 客户端没有任何一处可以合法地据它分支：设备时钟不可信是既定纪律，一台时钟快了一个月的设备会拒绝去尝试一个其实完全有效的刷新 ⇒ 凭空一次强制重登；而「refresh token 是否仍有效」的唯一权威是后端的 `auth.session_revoked` 应答，试一次的代价只是一次请求。**存一个不允许被读的字段，只会等着被人读。** 连带：**`signin` 应答里的 `refreshExpiresAtUtc` 客户端读取即丢弃**——这一句必须明写，否则读者会以为是漏了。
- **不存 access token**（15 分钟即过期、`Session` 已在内存持有，落盘只是把一份短寿凭据写进磁盘，扩大泄漏面而零收益）；**不存渠道 / 手机号 / 昵称等便利字段**（那是 UI 便利、不是鉴权材料，若确有需求落 `device-settings.json`，不与凭据同处）。
- **带 `schemaVersion`，与 `device-id.json` 的处置刻意不同。** 判据是**这份文件的结构会不会增长到需要逐版迁移**（见 `systems/architecture.md`），不是字段数：本文件是多字段信封、与 `sync-envelope.json` 同形；且配套口径「版本不认识就整份丢弃」在这里是安全的——**丢弃一份 refresh token = 玩家多登录一次，丢弃一份 `device-id.json` = 一次假换设备 + 一次假挤下线**。两者不在同一量级。**这条对照须写在此处**，否则读者会按「都是 `user://cache/` 小文件」照抄错误的一侧。
- **明文存放，不上平台密钥库。** 理由是**依托各平台的应用沙箱 + 后端 rotation 与「窗口外重放即吊销全部会话」兜底**（`auth.md` §4）；同时不改变任何契约，日后换实现无需两侧配合。**这条不挂靠「不承诺防作弊」那条威胁模型**——那条的成立前提是「作弊者只损害自己」，而凭据泄漏的受害者是账号所有者本人以外的人，两者不同类。**已知残余风险照录**：root / 越狱设备、系统备份提取、共享设备上的他人访问——沙箱在这三种情形下不成立。平台密钥库（Android Keystore / iOS Keychain）是**后置评估项而非否决项**。
- **失效路径穷举六条，处置只有「删除文件 + 清内存」与「覆写」两种：**

  | # | 时刻 | 处置 |
  |---|---|---|
  | 1 | **登出成功**（`SignOutAsync` 返回成功） | 删除文件 —— 主动登出的玩家预期就是「下次要重新登录」 |
  | 2 | **收到 `auth.session_revoked`**（refresh 应答 / 业务请求应答两个到达路径） | 删除文件 + 走既定硬阻塞重登；该 token 服务端已失效，留着只会在下次启动多打一次必然失败的请求 |
  | 3 | **`signin` 成功且 `accountId` ≠ 文件中的** | 覆写为新账号的新 token —— 切账号即失效的兑现点 |
  | 4 | **`signin` 成功且 `accountId` 相同**（同设备重登） | 覆写（后端原地替换会话，旧 refresh token 立即失效） |
  | 5 | **每次 refresh 成功**（rotation） | 覆写为应答中的新 token |
  | 6 | **读取时解析失败 / 缺字段 / 版本不认识 / `accountId` 为空** | 删除文件 + 走登录屏（见下表） |

- **读取与写入的失败处置：**

  | 情形 | 判定 | 处置 |
  |---|---|---|
  | 文件不存在 | 可选缺失（首次运行 / 已登出的正常态） | 走登录屏。**不打任何日志**——它是最常见的正常态 |
  | 解析失败 / 字段缺失 / 版本不认识 / `accountId` 空串 | 可选缺失（异常） | `GD.PushWarning("[Auth-RefreshToken] cached refresh token invalid, discarding; path=user://cache/refresh-token.json")` + 删除 + 走登录屏 |
  | 落盘失败（写入时） | 可选缺失（异常） | `GD.PushWarning("[Auth-RefreshToken] persist failed; session valid for this launch only")` + **本次进程内存持有该 token，不阻塞登录**。后果照录：下次启动需重新登录（一次性、可自愈） |

  **三处一律 `PushWarning` 而非 `PushError` + 抛**：缺它不阻断任何流程，最坏后果是玩家多登录一次；抛会把一次可降级的缓存问题升级成**登不上游戏**。
  **⚠ 本文件刻意不沿用 `deviceId` 的「必须先落盘成功、内存里才认」（承重）。** 那条纪律成立是因为 deviceId 的「盘上没有」会造成**永不自愈**的症状；本文件落盘失败的症状是一次性的，照那条处理反而更糟——它会让一次写盘失败**当场作废一个刚拿到的有效会话**。**判据是「失败症状是否自愈」，不是「是不是凭据」**；这条须与规则同处，否则读者会误以为两处不一致是漏改。
- **rotation 的落盘时机：先拿到应答 → 再落盘 → 再更新内存。** 60 秒宽限窗口是弱网重放的保险，**不作为落盘失败的兜底**，不得写成设计依赖。
- **待发队列不受本文件影响。** 队列条目的淘汰路径只有既定三条（被后端接受 / 按云端权威丢弃 / 切账号清空）；本文件的删除不淘汰任何队列条目，切账号时的队列清空由信封 `accountId` 不匹配那条既定路径承担。
- **归属 = `AuthManager` 私有，不出任何服务的 API 面。** **不提供 `TryGetRefreshToken()` 这类公开取值方法**——它是鉴权材料，一个公开取值口就把「把 token 记进日志 / 塞进诊断面板 / 上报到统计」变成一行代码的距离。唯一消费点是 `RefreshTokenAsync` 与 `SignInAsync` 的应答处理，两者都在 `AuthManager` 内。**文件 I/O 落在 `AuthManager`、不沉进 `HttpAccountBackend`**：离线实现也要能走通静默续期路径，且文件 I/O 不该在传输层（与 `deviceId` 的填充点同源）。**任何日志只写 path 与判定结果，绝不写凭据值**——含前缀 / 后缀截断形式，截断值仍是凭据的一部分且对排障无用。
- **消费点 = 启动期静默续期。** 跨启动保留一个 refresh token，当且仅当有人在启动时用它。本服务的 `InitializeAsync` 排在登录屏**之前**（见「API 面」），其内部：

  ```
  读 user://cache/refresh-token.json
    缺失 / 无效  → 呈现登录屏（既有路径）
    有效         → RefreshTokenAsync()
        成功                  → 得到 Session，跳过登录屏，直接进启动链下一步
        auth.session_revoked  → 删除文件 → 呈现登录屏
        网络失败              → 呈现登录屏并附「重试」
  ```

  **三分支在报文层面是穷举的**：`refresh` 端点的错误码只有 `auth.session_revoked` 与 `server.unavailable` 两条（`auth.md` §8），不存在第四条路径。
  **启动期的 refresh 失败不走会话期内的那两条分流。** 那两条（网络失败视同断线走缓冲通道 / `session_revoked` 硬阻塞重登）都以会话期内为前提——有进行中的轮回、有待发队列、有不能回退的存档点；**启动期这三样一样都没有**。故两种失败一律落回登录屏，那是「未登录」的既定正常态（`TryGetSession` 已定为可选缺失）。**本节不新增阻塞点**（阻塞点的穷举清单见 `sync-service.md`「三条不变式」①；登录屏不是阻塞屏）。
  **协议维度的强更闸门只在 `signin` 判定，`refresh` 永不判定**（`auth.md` §5），故靠静默续期长期在线的旧客户端在协议维度上不经过闸门，直到它下一次真的走 `signin`。**本库不代为收口**——收口手段（滑动续期上限、强制 re-signin 周期）全在后端侧，客户端自加一条「距上次 `signin` 超过 N 天则强制回登录屏」会撞「设备时钟不可信」这条既定纪律。承接项见 `backend-design-documents/contracts/auth.md` §5。
- **API 面零改动**：不新增方法、不改 `Session`、不改任何签名；`RefreshTokenAsync()` / `SignInAsync()` / `SignOutAsync()` 的现有形态原样承载全部六条失效路径。**存档 schema 零影响、零迁移；后端零改动、零新增义务。**

Source: `handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md` · `handoffs/2026-07-27-content-gating-offline-resilience-and-rng-persistence.md` · `handoffs/2026-08-11b-contract-boundary-and-flags-client-side.md` · `handoffs/2026-08-19-device-id-provisioning.md` · `handoffs/2026-08-22-refresh-token-client-storage.md` · `decisions/ADR-0003-online-cloud-authority.md`

## 管理器

| manager | 职责 |
|---------|------|
| **AuthManager** | 渠道登录、token 获取 / 刷新 / 失效处理、会话保持；产出 `accountId` |
| **ComplianceManager** | 实名认证、防沉迷时长校验、账号注销 / 数据导出的客户端侧流程 |

## API 面（契约）

> 总则与共享类型见 `systems/architecture.md`「API 契约总则」。本服务实现 `IBootstrappable`（**启动链第二步，登录屏之前**——它的 `InitializeAsync` 内部先做静默续期，登录屏只在续期未成功时才呈现，见「refresh token 的持有与失效」）。

| 方法 | 形态 | 完整签名 | 失败语义 |
|------|------|----------|----------|
| 请求验证码 | B | `Task<OpResult<ChallengeInfo>> RequestChallengeAsync(LoginChannel channel, string identifier, ChallengePurpose purpose, CancellationToken ct)` | 业务失败 → `OpResult` |
| 登录 | B | `Task<OpResult<Session>> SignInAsync(LoginChannel channel, LoginCredential credential, CancellationToken ct)` | 业务失败 → `OpResult` |
| 登出 | B | `Task<OpResult> SignOutAsync(CancellationToken ct)` | 同上 |
| 刷新 | B | `Task<OpResult<Session>> RefreshTokenAsync(CancellationToken ct)` | 失败**按判据分两条**，见「意图」 |
| 绑定渠道 | B | `Task<OpResult> BindChannelAsync(LoginChannel channel, LoginCredential credential, CancellationToken ct)` | 业务失败 → `OpResult` |
| 解绑渠道 | B | `Task<OpResult> UnbindChannelAsync(LoginChannel channel, CancellationToken ct)` | 同上 |
| 改昵称 | B | `Task<OpResult> SetNicknameAsync(string nickname, CancellationToken ct)` | 同上 |
| 取会话 | A | `bool TryGetSession(out Session session)` | **可选缺失**——未登录是登录屏的正常态，不是错误 |

```csharp
public readonly record struct Session(string AccountId, string Token, DateTime ExpiresAtUtc);
public readonly record struct ChallengeInfo(DateTime ExpiresAtUtc, int ResendAfterSeconds);
public enum LoginChannel { Phone, Email, WeChat, QQ }   // 优先级序见 ADR-0003；无 Guest
public enum ChallengePurpose { SignIn, Rebind }
```

- **`RequestChallengeAsync` 是 `SignInAsync` 的前置一步，不是它的内部实现。** 手机 / 邮箱登录是「先下发验证码、再提交验证码」的两步握手，UI 需要在两步之间停留（输入框 + 倒计时）；把它藏进 `SignInAsync` 内部，倒计时与重发按钮就无从驱动，两步握手在 UI 上退化成一次不可见的等待。
- **`SignInAsync` 带凭据。** `LoginCredential` 是一个判别式 record（对位后端 `credential` 的分形）：自建渠道交 `identifier + code`，第三方渠道传 `LoginCredential.None`，由本服务内部走 SDK 取 authCode。
- **`bind` 与 `signin` 走同一条取 authCode 的路径**——同一个 SDK 调用、同一层错误归一，不为绑定另开一条。否则渠道 SDK 的初始化 / 授权 / 错误处理会有两份，而它们必然漂移。
- **昵称的合法性不由客户端判定。** 客户端只做长度与空白这类无争议的输入约束；敏感词与改名频次由后端判定并下发 `code`。**判定通过后由客户端写 `AccountInfo.Nickname`**（客户端是该字段的写入方，见 `systems/player-profile/account-info.md`），走既有 push 上行。
- **绑定 / 解绑成功后各强制一次 pull**，据此刷新 `AccountInfo.Identities` 这份只读投影。**该次 pull 失败不阻塞**——列表暂不刷新，下次 pull 自然一致；绑定列表是只读投影，展示滞后无实际损失。这与购买段「购后 pull 失败阻塞在主菜单重试」**刻意不同**：那里阻塞是因为付费权益必须落地。**改昵称不需要这一步**（客户端自己是写入方）。
- **不为绑定新开一个 service**——它用同一套渠道 SDK、同一套会话，本服务的门面定位已覆盖。

**失败映射：** 网络不通 → `OpError.Network`；渠道拒绝 / token 失效 / 绑定冲突 / 昵称被拒 → `OpError.Auth`；实名 / 防沉迷拦截 → `OpError.Compliance`；**限流（`rate.limited`）→ `OpError.Network`** —— 它与网络类失败共享同一条处置（可重试 + 退避），而 `Auth` 档的语义是「凭据失效」，混进去会让处置分支走错。**文案不受影响**：文案按 `code` 取，限流仍可精确措辞。

> **`Detail` 是诊断串，不是玩家文案。** 合规拦截的具体原因（实名未完成 / 时长受限 / 账号受限）**按 `code` 走 UI 层的 `ErrorText`**，与其他错误一致——合规文案恰是最需要精确措辞、也最需要按渠道调整的一类，正是「按 `code` 分辨」的典型受益者。语义见 `systems/architecture.md` 总则 7，呈现见 `ux/error-and-blocking-ux.md`。

**后端接口（总则 7）：** 本服务持有 `IAccountBackend`，两份实现 `HttpAccountBackend` / `OfflineAccountBackend`，经**唯一选择点 `BackendSelector.CreateAccount()`** 取得；离线实现整类包在 `#if DEBUG` 内，Release 构建里根本不存在（形态见 `system-overview.md` 第四节）。

**事件面：** `SessionChanged(bool SignedIn, OpError Reason)` 经 EventBus 广播（登录成功 / 失败、token 失效、合规拦截共用此负载）。

Source: `handoffs/2026-07-27b-service-api-contracts.md` · `handoffs/2026-08-12-error-copy-and-update-prompts.md` · `handoffs/2026-08-16e-account-identity-client-adoption.md`

## 与其他服务的关系

- **下游：** `sync-service` 用它产出的 `accountId` 拉取 PlayerProfile；`content-service` 用它的 token 请求 flags（**登录之后**的启动链一步）。剧本内容属本地内容层，不经本服务取 token。
- **不做的事：** 不碰 PlayerProfile 的字段（那是 profile-service 的写入面），不做存档同步（那是 sync-service）。

## 决策(-> ADR)

- **强制在线 · 云端权威 · 重账号 · 无游客态** → `decisions/ADR-0003-online-cloud-authority.md`（Accepted）。

## 待决问题

- **ComplianceManager 的客户端侧覆盖面。** 实名 / 防沉迷 / 注销 / 数据导出中，哪些环节由客户端呈现与拦截、哪些纯后端裁决，切分未定。→ `decisions/ADR-0003`。后端 / 账号系统的具体选型与合规实现归**后端库**：`backend-design-documents/open-questions.md`。
- **多设备并发登录的云端裁决规则。** 后登录挤下线？拒绝？归**后端库**。客户端侧的表现已定（被挤下线 → 硬阻塞重登 → 先 pull 后 flush，见「意图」），仅剩裁决策略本身待后端定。

## 对应
提炼至：`.claude/knowledge/systems/account-service.md`（引用层，待建）。
