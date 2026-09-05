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
- **明文存放，不上平台密钥库。** 理由是**依托各平台的应用沙箱 + 后端 rotation 与「窗口外重放即吊销全部会话」兜底**（`auth.md` §4）；同时不改变任何契约，日后换实现无需两侧配合。**这条不挂靠「不承诺防作弊」那条威胁模型**——那条的成立前提是「作弊者只损害自己」，而凭据泄漏的受害者是账号所有者本人以外的人，两者不同类。**已知残余风险照录**：root / 越狱设备、系统备份提取、共享设备上的他人访问——沙箱在这三种情形下不成立。平台密钥库（Android Keystore / iOS Keychain）是**后置评估项而非否决项**；「后置」的兑现物是下方的能力矩阵与五条触发条件——**只写「日后评估」而不给可判定的触发条件，等于没有评估**：那种留口不会在某天被想起来，只会在下一次「看看还有什么没做」时被再次记为后置。

  **四端能力矩阵。** 带 `[待核实]` 标注的格子是**尚未验证的事实、不是断言**，核实前不得据以推理；三项核实（Godot 4.7 有无内置安全存储绑定 · Web 导出 `user://` 的持久化后端 · Android Keystore 密钥失效的具体异常与触发面）并入 `game-feature-branch/` 首次生成 `.csproj` 后的那一次实测批次，不单独排一次验证。

  | | **Android** | **iOS** | **桌面（Win / macOS / Linux）** | **Web** |
  |---|---|---|---|---|
  | **是否存在 OS 级密钥 / 凭据机制** | 有 —— Android Keystore（系统持有密钥、应用不接触密钥材料） | 有 —— Keychain Services（`kSecClassGenericPassword`） | 有，但**三套互不相同**：Windows DPAPI / 凭据管理器 · macOS Keychain · Linux Secret Service（**不保证存在**，取决于桌面环境） | **无等价机制** |
  | **Godot 4.7 是否内置绑定** | 否——需自建 Android 插件（Java/Kotlin 侧）`[待核实：Godot 4.7 是否有内置安全存储 API]` | 否——需自建 iOS 插件（Obj-C/Swift 侧）`[同上待核实]` | 否——需 GDExtension，且三套 OS 各写一份 | 不适用 |
  | **`user://` 的实际落点** | 应用私有目录（沙箱内） | 应用沙箱内 | **用户可读写的普通目录**——同用户下任意进程可直接读取 | 浏览器持久化存储（Web 导出经 Emscripten 落到浏览器端存储）`[待核实：具体后端与持久化保证]` |
  | **消掉哪几条已登记残余风险** | 备份提取 ✅（密钥不随备份迁移）· 共享设备 ⚠ 部分（取决于是否挂生物识别 / 锁屏门）· **root ❌**（root 下的保护取决于是否硬件后备，且应用自身可被注入） | 备份提取 ✅（须显式选 `ThisDeviceOnly` 类可访问性，否则随 iCloud Keychain / 备份走）· 共享设备 ⚠ 部分 · **越狱 ❌** | **一条也消不掉**——桌面威胁模型下，能读 OS 凭据库的正是「以该用户身份运行的进程」，与能读 `user://` 的是同一批 | **一条也消不掉**——同源的任意脚本可读，且不存在「OS 拒绝应用读取」这一层 |
  | **升级后新增的坏路径** | 锁屏 / 生物识别凭据变更可使密钥永久失效；换机恢复后旧条目不可解密 `[待核实：具体异常与触发面]` | **Keychain 条目在应用卸载后仍存活**——重装即读到一份旧 token（后端已吊销 ⇒ 走 `auth.session_revoked` → 登录屏，可自愈，但**必须明写**，否则读者会以为「重装 = 干净态」） | 三套 OS 各自的可用性问题；Linux 上服务可能根本不存在 → 必须有明文回退 | 浏览器在存储压力 / 用户清理下可整体清空 → 表现为一次强制重登（既有的可自愈路径） |
  | **升级的边际成本** | 一个自建插件工程 + 导出配置 | 一个自建插件工程 + 导出配置 + 上架复验 | 三份 GDExtension，**收益为零** | 不适用 |

  矩阵读出的两条结论：**收益集中在移动双端，且只覆盖三条残余风险中的「备份提取」一条半**——root / 越狱这条恰是三条里唯一被主动攻击者利用的，密钥库消不掉；这使升级的定性从「补上安全短板」降为「关掉备份提取这一条被动泄漏面」。**桌面与 Web 的升级收益是零、不是「小」**：桌面是威胁模型使然，Web 是机制缺失。

  **升级触发条件穷举五条。** 判据取两条轴——「明文的依据是否仍成立」与「升级的边际成本是否已被别的事付掉」；每条都是**可机械判定的事件**，不是「等有空」。命中任一条 ⇒ 该评估从后置项转为**必须在当次同批裁决的工作项**：**裁决可以是「仍不升级」，但必须给出结论，不得再记为后置。**

  | # | 触发事件 | 轴 | 为什么它是分界线 |
  |---|---|---|---|
  | **T1** | `backend-design-documents/contracts/auth.md` §4 的 **rotation** 或 **「窗口外重放即吊销全部会话」**任一条被改写、削弱或取消 | 依据失效 | 明文的全部辩护建立在这两条之上；它们一动，明文当场没有依据——这不是「再评估」，是**必须重做决定** |
  | **T2** | 客户端出现**第二份落盘的鉴权 / 支付材料**（不含 `deviceId`、不含可降级缓存），判据同本条的「泄漏后的受害者是账号所有者以外的人」 | 依据失效 | 一份文件可以逐份论证；两份就需要一条通则 |
  | **T3** | 首次为 Android **或** iOS 引入**任何自有原生插件**（第一候选 = 商业化落地时的平台内购 SDK） | 成本已被付掉 | 当前成本的大头是「为这一件事单独建一个插件工程」；插件工程若因别的原因已存在，边际成本降到「加一个方法」，成本侧的否决理由随之消失 |
  | **T4** | 出现**一例**经确认的凭据泄漏 / 盗号工单，其路径落在三条已登记残余风险内 | 依据失效 | **不设阈值，>0 即触发**——「已登记的残余风险实际发生了」本身就证伪了「风险被接受」这一判断 |
  | **T5** | 上架渠道 / 合规审核**以条款形式**要求凭据受 OS 级保护 | 外部硬约束 | 与本库的取舍无关，是准入条件 |

  **明确不构成触发条件**（写下来是为了防日后被「补全」）：「有空了」· root 设备占比的统计数字（无阈值可依，且五条已覆盖真正的分界线）· 竞品做了 · 「安全总是好的」。

  **升级不引入平台分支**，三条理由：① **能力差异不落在 API 面上，落在一处实现内**——落盘点已收敛为 `AuthManager` 私有的一处且无公开取值方法，升级 = 换掉这一处的读写实现，服务 API 面、`Session`、六条失效路径、三条读写失败处置一格不动；② **Web / 桌面不是「降级分支」，而是同一个默认实现**——明文实现不被移除，它是四端共同的缺省，Android / iOS 在**插件可用时**替换，判据是「**这一端有没有可用的凭据存储实现**」（运行期一次探测，探测不到即用缺省），而不是「我在哪个平台」；这与 `BackendSelector` 的「唯一选择点 + 换实现而非插 `if`」是同一条纪律的第二次应用；③ **因此也不碰条件编译清单**——平台实现的有无是**构建产物**层面的事（某端的导出里没有那个插件），不是 `#if` 分支。推论：`.claude/rules/ui-input-rules.md` 的「仅在某项能力确有本质差异处分支」这一口子在此用不上，因为根本没有分支。

  **现在不预留 `ICredentialStore` 之类的抽象。** 落盘点只有一处、只有一个实现、API 面已隔离，此刻抽接口只满足 `systems/architecture.md` 的抽象反判据（只被调用一次且无变体 / 为了让结构看起来更完整）。**替换成本已经是最低的**，预留抽象换不来任何东西；真要落第二个实现时再抽，那时它自动满足「≥ 2 个同形态的实现」这条判据。

  **升级真发生时的落地形态**（备好以便触发时不必从零想，**不构成现在就做的建议**）：

  - **存的还是同一份 JSON 串**（`{ schemaVersion, accountId, refreshToken }`），只是载体从文件换成密钥库条目 ⇒ `schemaVersion` 与「版本不认识就整份丢弃」原样保留，**存档 schema 零影响**。
  - **迁移 = 一次性搬迁**：升级版本首次启动时，密钥库为空且明文文件存在 → 读明文 → 写密钥库 → 删明文；搬迁失败即删明文走登录屏（代价上界 = 一次重登，上一条已论证该上界可接受）。
  - **失败语义落回既有那一格**：密钥库不可用 / 写入失败 → `PushWarning` + 本次进程内存持有、不阻塞登录，**不新增阻塞点**。
  - **iOS 侧必须显式选「不随备份 / 不随 iCloud 同步」的可访问性**，否则「消掉备份提取」这条唯一收益当场归零；且**必须明写「Keychain 条目在卸载后存活」**及其自愈路径。
  - **原子写纪律不适用于密钥库条目**（它不是 `user://` 文件）⇒ `AtomicJsonFile` 的调用方名单相应少一处，`systems/architecture.md` 那份写入方清单须在搬迁同批复核。

  两条已被考虑并否决的替代取向，理由承重故写下：**在客户端自行加密后落明文文件**——密钥必须与密文同处一个可读位置，安全性提升为零，代价是一层假保障，比明文更糟，因为它会让人以为已经处理过了；**Web 端禁止持久化凭据、每次启动重登**——为它单开一条登录流即制造平台分支，且把一条可自愈的存储清空路径升级成常态摩擦。
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
  **协议维度的强更闸门只在 `signin` 判定，`refresh` 永不判定**（`auth.md` §5），故靠静默续期长期在线的客户端在协议维度上不经过闸门，直到它下一次真的走 `signin`。**收口全在后端侧**（refresh token 链有一个在 `signin` 时锚定、rotation 永不顺延的绝对寿命上限，到期即 `auth.session_revoked`），机制、旋钮与报文的权威在 `backend-design-documents/contracts/auth.md` §5b，**本库不复述**。
  **客户端不自收口，这条是承重的**：自加一条「距上次 `signin` 超过 N 天则强制回登录屏」会撞「设备时钟不可信」——一台时钟偏了的设备会凭空强制重登或永不重登。到期重登走的是**既有**的「收到 `auth.session_revoked` → 硬阻塞重登」那一条路（同一个 `code`、同一条处置），**本节不新增阻塞点**；玩家侧的差别只是一句二级文案（`ux/error-and-blocking-ux.md`）。

  **软着陆信号 `reauthRecommended` 的客户端形态（三条，缺一条都会把它变成一个本地时钟判断）：**

  - **只在内存里持有，绝不落盘。** 它是本次进程内的一次性提示；落盘就变成一个「过期了还在生效」的本地状态，且会破坏本文件「只放鉴权材料」这条字段集判据。
  - **不做任何时间判断。** 收到即为真、未收到即为假；**不推算、不折算、不与任何本地时钟比较**。判定发生在服务端正是因为只有那一侧的时钟可信——这也是后端把它做成布尔而不是时间戳的原因。
  - **反应 = 在下一个自然时机主动走一次 `signin`，而不是任何阻塞。** 自然时机取**启动期**：静默续期成功且收到该信号 → 直接呈现登录屏（会话此刻仍然有效，故它是**可跳过的**）。启动期是唯一一个必然经过、必然空闲、且已有现成屏幕的时刻，**零新增屏幕、零新增触发接线**。**失败即忽略**：玩家取消或登录失败时当前会话照常有效，游戏继续——它是一次邀请，不是一道门，真正的强制力在后端的绝对上限。

  **三件明确不做的事**（写下来是为了防日后被「补全」）：不新增阻塞点；**不持有、不推算、不展示任何「还有几天到期」**（没有一处 UI 需要它，而持有它就等着被拿去做本地判断）；软信号**不使任何 token 失效**——它不是下方六条失效路径的第七条，只是提前去换一条新链。

  **API 面零改动**：软信号的读写全在 `AuthManager` 内，不新增方法、不改 `Session`、不改任何签名——与 `deviceId` / refresh token 同款，一个公开取值口就把「挂个本地判断」变成一行代码的距离。
- **API 面零改动**：不新增方法、不改 `Session`、不改任何签名；`RefreshTokenAsync()` / `SignInAsync()` / `SignOutAsync()` 的现有形态原样承载全部六条失效路径。**存档 schema 零影响、零迁移；后端零改动、零新增义务。**

### 合规域的客户端覆盖面

合规四域（实名 / 防沉迷 / 账号注销 / 数据导出）在客户端的切分判据一句话：**凡需要「一段流程」（多于一次请求、或需要持有一个流程内凭据）的，归 `ComplianceManager`；凡只是「把一次失败说清楚」的，归发起它的那一屏。**

| 域 | 环节 | 归属 | 落屏 |
|---|---|---|---|
| **实名** | `signin` 被 `compliance.realname_required` 拦 | 登录屏（呈现） | 登录屏 |
| | 表单填写 + 提交 + 失败分流 + 成功后重走 `signin` | **ComplianceManager**（编排 + 持 ticket） | 实名屏（登录流程内） |
| **防沉迷** | 拦截呈现 + `resumeAtUtc` | 登录屏 | 登录屏 |
| | 会话中途到点 | **`AuthManager`**（既有 `auth.session_revoked` 路径） | 阻塞屏（既有「被挤下线」变体） |
| | 剩余时长的呈现 | 数据由 `ComplianceManager` 的 status 单点提供 | 呈现形态另定 |
| **注销** | 申请 / 撤销（已登录态） | **ComplianceManager** | PlayerProfile 屏 |
| | 冷静期内被拦 + 撤销（未登录态，凭 ticket） | 呈现归登录屏，调用归 **ComplianceManager** | 登录屏 |
| **数据导出** | 申请 + 轮询 + 打开下载链接 | **ComplianceManager** | PlayerProfile 屏 |
| **昵称须改名** | `nicknameChangeRequired` 的读取 | `ComplianceManager` 的 status 单点 | 呈现形态另定 |
| | 改名提交本身 | **`AuthManager`**（既有 `SetNicknameAsync`） | 既有改名入口 |

**四件明确不归它的事**（写下来是为了防日后被「补全」）：

1. **任何判定**——不读年龄、不比时钟、不算时段、不判是否未成年。`isMinor` / `playtimeRemainingSeconds` 只作**呈现的输入**，永不用于决定能否继续游玩（`decisions/ADR-0024` 与 `systems/monetization.md`：客户端不做任何本地合规拦截，强制力在后端）。
2. **会话中途下线**——`AuthManager` 的既有路径，本节一个字都不改它。
3. **昵称合法性判定与提交**——既有 `SetNicknameAsync`。
4. **拦截错误的措辞选择**——那是 UI 层 `ErrorText` 的事，manager 不碰文案（`ux/error-and-blocking-ux.md`）。

**客户端侧的「强制改名」不是硬阻塞（边界必须明写）。** 它的兑现依赖 `GET /v1/compliance/status` 这一次**可降级**的请求：请求取不到即本次会话不呈现须改名面，下次会话再拦。**后端侧的兜底是存量扫描与复核通道**（语义见 `backend-design-documents/contracts/compliance.md` 与 `backend-design-documents/operations/moderation.md`）。这与「合规的强制力在后端、客户端只呈现」逐条一致——把它升级成启动阻塞就会新增一处阻塞点，而阻塞点是穷举的（`sync-service.md`「三条不变式」①）。

#### `complianceTicket` 只在内存里，绝不落盘、绝不出 API 面

ticket 一次性、单端点、寿命由后端定（语义权威在 `backend-design-documents/contracts/compliance.md`）。

- **只在 `ComplianceManager` 内存持有**，随进程消亡。落盘就造出一个「过期了还在生效」的本地状态——与 `reauthRecommended` 的「只在内存里持有、绝不落盘」是同一条论证；且它会给 `user://cache/` 添一份需要自己失效口径的小文件，而那个口径恰恰是客户端不该自己判的（设备时钟不可信）⇒ 落盘后唯一正确的读法仍是「拿去试一次，失败就回登录屏」，与不落盘完全等价。
- **不出任何服务的 API 面**——不提供 `TryGetComplianceTicket()` 这类公开取值方法，与 `deviceId` / refresh token 同款手法。实名屏与登录屏都**看不见 ticket**：它由 manager 从拦截错误的 `detail` 里取出、在下一次请求时自己填上，故它也不进任何方法签名。
- **`detail` 里随 ticket 一同下发的 `ticketExpiresAtUtc`，客户端读取即丢弃。** 这一句必须明写，否则读者会以为是漏了、进而拿它做一次本地时钟比较——与 `refreshExpiresAtUtc` 同一条处置。
- **过期 / 已消费的唯一发现方式是拿去用一次**，收到 `compliance.ticket_invalid` 即按下方失败映射处置。**客户端不做任何过期预判。**

#### `GET /v1/compliance/status`：单点调用与可降级

- **调用点唯一：`ComplianceManager`。** 合规态没有任何下行通道（不随 `AccountInfo` 下行，理由见对侧契约）⇒ 必须有这一次请求。**排在会话到手之后、`SyncService.InitializeAsync` 之前**，与 `ContentService.RefreshFlagsAsync` 同一落点判据（需鉴权 + 失败不阻塞，见 `systems/architecture.md` 总则 4）。**不写作「`signin` 成功之后」**——静默续期那条路径根本不走 `signin`，照那个措辞写会让续期玩家永不取 status。
- **PlayerProfile 屏进入时可再取一次**（冷静期状态会变化）。**这不是第二个真值源**——两次都是同一个 manager 的同一个方法，取回即用即弃，**不缓存、不落盘、不进 `PlayerProfile`**。它是会话中途会变的呈现输入，进主档即制造第二真值。
- **失败按「可选缺失」降级：** 退避重试一次 → 仍失败则 `GD.PushWarning("[Compliance-Status] fetch failed; continuing without compliance surface")` + **照常进主菜单**，本次会话不呈现须改名 / 剩余时长等附加合规面。**不阻塞启动链**——合规的强制力在 `signin` 的拦截，status 只驱动呈现；让一次呈现性请求卡住启动，等于把一个可降级失败升级成登不上游戏。
- **它归入三条不变式③ 的第二形状**（「用上一个已知好值 / 缺省值」）：此处的缺省 = 无附加合规面。**不是第四种降级形状**（口径见 `sync-service.md`「三条不变式」③）。
- **合规端点上的 `server.unavailable` 不走 sync 的缓冲通道。** 那条「进待发队列 + 退避」是 push 通道的形状；合规端点是玩家主动发起的请求 ⇒ 就地呈现 + 允许再点一次，与登录屏对 `signin` 失败的处置同族。不新增任何机制。

#### 实名表单的两条输入侧纪律

- **输入约束只做长度与字符集**，与昵称同构；**不做证件号校验位、不做地区码判定**——判定权在后端。
- **核验被拒时保留玩家已输入的内容、不自动清空**（被拒的通常只有一项）。这与实名材料的脱敏纪律不冲突：那条禁的是**服务端回显 / 进应答 / 进日志**，客户端进程内输入框里的内容不在其列。

Source: `handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md` · `handoffs/2026-07-27-content-gating-offline-resilience-and-rng-persistence.md` · `handoffs/2026-08-11b-contract-boundary-and-flags-client-side.md` · `handoffs/2026-08-19-device-id-provisioning.md` · `handoffs/2026-08-22-refresh-token-client-storage.md` · `handoffs/2026-08-23-refresh-lifetime-cap-client-half.md` · `handoffs/2026-09-03-compliance-client-surface.md` · `decisions/ADR-0003-online-cloud-authority.md`

## 管理器

| manager | 职责 |
|---------|------|
| **AuthManager** | 渠道登录、token 获取 / 刷新 / 失效处理、会话保持；产出 `accountId` |
| **ComplianceManager** | 实名 / 注销 / 数据导出的客户端侧流程编排；合规态的呈现驱动。**不做任何判定**——不读年龄、不比时钟、不算时段（覆盖面见「意图」的「合规域的客户端覆盖面」） |

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
| 查合规态 | B | `Task<OpResult<ComplianceStatus>> GetComplianceStatusAsync(CancellationToken ct)` | **可降级**，见「合规域的客户端覆盖面」 |
| 提交实名 | B | `Task<OpResult<RealnameResult>> SubmitRealnameAsync(string realName, string idNumber, CancellationToken ct)` | 业务失败 → `OpResult`；**ticket 不进签名** |
| 申请注销 | B | `Task<OpResult<DeletionInfo>> RequestAccountDeletionAsync(CancellationToken ct)` | 业务失败 → `OpResult` |
| 撤销注销 | B | `Task<OpResult> CancelAccountDeletionAsync(CancellationToken ct)` | 同上；**鉴权态 / ticket 态由 manager 内部择一，调用方不分辨** |
| 申请导出 | B | `Task<OpResult<ExportTaskInfo>> RequestDataExportAsync(CancellationToken ct)` | 同上 |
| 查导出任务 | B | `Task<OpResult<ExportTaskInfo>> GetDataExportTaskAsync(string taskId, CancellationToken ct)` | 同上 |

```csharp
public readonly record struct Session(string AccountId, string Token, DateTime ExpiresAtUtc);
public readonly record struct ChallengeInfo(DateTime ExpiresAtUtc, int ResendAfterSeconds);
public enum LoginChannel { Phone, Email, WeChat, QQ }   // 优先级序见 ADR-0003；无 Guest
public enum ChallengePurpose { SignIn, Rebind }

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
public readonly record struct DeletionInfo(DateTime DeletionEffectiveAtUtc, bool Deduplicated);

public readonly record struct ExportTaskInfo(
    string           TaskId,
    ExportTaskStatus Status,
    bool             Deduplicated,
    DateTime?        RequestedAtUtc,
    int?             PollAfterSeconds,
    string           DownloadUrl,            // 仅 Ready；否则 string.Empty
    DateTime?        DownloadExpiresAtUtc,
    long?            SizeBytes);
```

- **字段语义的权威在 `backend-design-documents/contracts/compliance.md`，本表只定 C# 侧的调用形状与可空性。**
- **枚举成员名与对侧的字符串取值逐字相同**（跨边界的枚举即成员名），故两侧不需要任何映射表。
- **可选值类型用可空类型；可选字符串用 `string.Empty`，不用 `string?`**——对侧「不下发 `null`，可选字段缺席即省略」，而把 `null` 往下游传撞 `.claude/rules/null-check-rules.md`。`bool` 型可选字段缺席即 `false`。
- **`ExportTaskInfo` 一型承载「申请」与「查任务」两个应答**：申请的应答不带 `requestedAtUtc`，故该格可空——**客户端绝不本地填 `DateTime.UtcNow` 补齐它**（设备时钟不可信）。`Deduplicated` 的语义与 `DeletionInfo` 同格：命中既有未过期任务时为真。
- **`DeletionEffectiveAtUtc` 在 `DeletionInfo` 与 `ComplianceStatus` 上同名同义**，不因来源不同而取两个名字。

- **`RequestChallengeAsync` 是 `SignInAsync` 的前置一步，不是它的内部实现。** 手机 / 邮箱登录是「先下发验证码、再提交验证码」的两步握手，UI 需要在两步之间停留（输入框 + 倒计时）；把它藏进 `SignInAsync` 内部，倒计时与重发按钮就无从驱动，两步握手在 UI 上退化成一次不可见的等待。
- **`SignInAsync` 带凭据。** `LoginCredential` 是一个判别式 record（对位后端 `credential` 的分形）：自建渠道交 `identifier + code`，第三方渠道传 `LoginCredential.None`，由本服务内部走 SDK 取 authCode。
- **`bind` 与 `signin` 走同一条取 authCode 的路径**——同一个 SDK 调用、同一层错误归一，不为绑定另开一条。否则渠道 SDK 的初始化 / 授权 / 错误处理会有两份，而它们必然漂移。
- **昵称的合法性不由客户端判定。** 客户端只做长度与空白这类无争议的输入约束；敏感词与改名频次由后端判定并下发 `code`。**判定通过后由客户端写 `AccountInfo.Nickname`**（客户端是该字段的写入方，见 `systems/player-profile/account-info.md`），走既有 push 上行。
- **绑定 / 解绑成功后各强制一次 pull**，据此刷新 `AccountInfo.Identities` 这份只读投影。**该次 pull 失败不阻塞**——列表暂不刷新，下次 pull 自然一致；绑定列表是只读投影，展示滞后无实际损失。这与购买段「购后 pull 失败阻塞在主菜单重试」**刻意不同**：那里阻塞是因为付费权益必须落地。**改昵称不需要这一步**（客户端自己是写入方）。
- **不为绑定新开一个 service**——它用同一套渠道 SDK、同一套会话，本服务的门面定位已覆盖。

**失败映射：** 网络不通 → `OpError.Network`；渠道拒绝 / token 失效 / 绑定冲突 / 昵称被拒 → `OpError.Auth`；**`signin` 上的四条合规拦截**（实名 / 防沉迷 / 账号受限 / 冷静期内）**与合规域六端点自身的操作失败一律 → `OpError.Compliance`**（逐条处置见下表）；**限流（`rate.limited`）→ `OpError.Network`** —— 它与网络类失败共享同一条处置（可重试 + 退避），而 `Auth` 档的语义是「凭据失效」，混进去会让处置分支走错。**文案不受影响**：文案按 `code` 取，限流仍可精确措辞——实名提交被限流走的正是这一格。

**合规域三条端点码的客户端处置**（`OpError` 只是兜底档，处置以 `code` 为键；本表写的是本服务的处置取向，逐 `code` 的跨边界台账权威在 `backend-design-documents/contracts/envelope.md`，**本库不复述**）：

| `code` | 客户端处置 |
|---|---|
| `compliance.ticket_invalid` | **结束当前合规流程 → 回登录屏**（重新 `signin` 取新 ticket）。`detail.reasonKey` 只驱动措辞，处置同一条 |
| `compliance.verification_failed` | **留在实名表单屏、允许重填**（受 `rate.limited` 约束）；**保留玩家已输入的内容、不自动清空** |
| `compliance.deletion_irrevocable` | 呈现终态、**无重试动作**；出口回发起点（登录屏 / PlayerProfile 屏），此后不再呈现撤销入口 |

**三条均不新增阻塞点、不进阻塞屏变体表**——它们是玩家主动操作的失败，落在发起它的那一屏（判据与呈现见 `ux/error-and-blocking-ux.md`）。**`OpError` 枚举一格不动。**

> **`Detail` 是诊断串，不是玩家文案。** 合规拦截的具体原因（实名未完成 / 时长受限 / 账号受限）**按 `code` 走 UI 层的 `ErrorText`**，与其他错误一致——合规文案恰是最需要精确措辞、也最需要按渠道调整的一类，正是「按 `code` 分辨」的典型受益者。语义见 `systems/architecture.md` 总则 7，呈现见 `ux/error-and-blocking-ux.md`。

**后端接口（总则 7）：** 本服务持有 `IAccountBackend`，两份实现 `HttpAccountBackend` / `OfflineAccountBackend`，经**唯一选择点 `BackendSelector.CreateAccount()`** 取得；离线实现整类包在 `#if DEBUG` 内，Release 构建里根本不存在（形态见 `system-overview.md` 第四节）。

**事件面：** `SessionChanged(bool SignedIn, OpError Reason)` 经 EventBus 广播（登录成功 / 失败、token 失效、合规拦截共用此负载）。

Source: `handoffs/2026-07-27b-service-api-contracts.md` · `handoffs/2026-08-12-error-copy-and-update-prompts.md` · `handoffs/2026-08-16e-account-identity-client-adoption.md` · `handoffs/2026-09-03-compliance-client-surface.md`

## 与其他服务的关系

- **下游：** `sync-service` 用它产出的 `accountId` 拉取 PlayerProfile；`content-service` 用它的 token 请求 flags（**登录之后**的启动链一步）。剧本内容属本地内容层，不经本服务取 token。
- **不做的事：** 不碰 PlayerProfile 的字段（那是 profile-service 的写入面），不做存档同步（那是 sync-service）。

## 决策(-> ADR)

- **强制在线 · 云端权威 · 重账号 · 无游客态** → `decisions/ADR-0003-online-cloud-authority.md`（Accepted）。

## 待决问题

- **多设备并发登录的云端裁决规则。** 后登录挤下线？拒绝？归**后端库**。客户端侧的表现已定（被挤下线 → 硬阻塞重登 → 先 pull 后 flush，见「意图」），仅剩裁决策略本身待后端定。

## 对应
提炼至：`.claude/knowledge/systems/account-service.md`（引用层，待建）。
