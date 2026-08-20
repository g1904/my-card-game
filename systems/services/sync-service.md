# sync-service（服务）

> 存档与云同步服务：Profile 上下行、本地缓存原子写、schema 版本迁移。**判据 ②③ —— 事务性写入 + 外部 I/O 边界。**

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

### 同步模型

```
                云端（权威）
                     ↑ Push（每个自动存档点）
                     │ Pull（启动时全量一次）
                     ↓
   PlayerProfile ⊃ List<CharacterProfile>   ← 内存中的运行态
                     ↓ 原子写
   user://cache/     仅缓存 / 断线临时态，非权威
```

- **`PlayerProfile` 持有 `List<CharacterProfile>`**，故同步单位是**整个 PlayerProfile 聚合**；轮回内的高频变更以增量 push 提交。
- **启动时全量 pull 一次**（登录成功后）；**轮回内每个自动存档点 push**。自动存档点：轮回开始、每个 AdventureEvent 结算后、篇章边界、轮回结束。
- **冲突一律以云端为准**（`ADR-0003`）。本地 `user://cache/` 不是权威，仅作缓存与断线临时态。
- **原子写**：先序列化到临时文件，再 rename 覆盖真实文件 —— 写入中途崩溃不损坏缓存。对上行云端负载同样带版本。
- **schema 版本 + 迁移路径**：读取时校验版本、所引用的内容 `Id`（经 ContentRegistry）、必需字段；不匹配则**迁移或清晰拒绝**，绝不静默 null，绝不在较旧的存档上崩溃。
- **运行时 / 存档态只带 `Id` + 可变状态**，不复制展示文本 —— 文案变更不触发存档迁移（见 `systems/common-properties.md` 的三层切分）。

### 存档点与 push 解耦

- **「存档点」与「push」是两件事。** 逻辑存档点清单（轮回开始 / 每个 AdventureEvent 结算后 / 篇章边界 / 轮回结束）**保持不变**，每个点**立即原子写本地缓存**（毫秒级，无流量 / 电量顾虑，是崩溃恢复的第一道防线）；**受频率约束的只是网络 push**。
- **commit 与 push 的粒度对位：一次 `ProfileManager.TryApply` 提交 ⇒ 一次本地原子写；push 另计（承重）。** 本地写的粒度是**提交**，push 的粒度是**存档点 + 防抖窗口**——事件内的即时提交（古宝次数、战斗中的血 / mana、逐笔交易、Exchange 刷新、事件态置值）照常立即写本地缓存，只是**不新增存档点类型、不计软阻塞闸门**。
  - **不允许「提交了但不落盘」。** 那会开出一个「已提交但未落盘 ⇒ 退出重进即回滚」的窗口，与「绝不回退存档点」和防重掷纪律同时相抵；本地写是毫秒级、无流量与电量顾虑，省下它换不到任何东西。
  - **推论：「不新增存档点」这句话在全库一律读作「不新增决策点 / 不新增存档点类型」**，从不表示「这一次变更不落盘」。
- **合并窗口：push 5 秒防抖**——窗口内多次变更合成一次上行。一次 AdventureEvent 以分钟计，5 秒足以吃掉「事件结算 + 奖励 + 属性推拉」这类连续写。
- **强制立即 flush（不受防抖约束）：** 篇章边界、轮回结束、角色 `defeated`、**进入战斗前**、**应用失焦 / 挂起**（`NOTIFICATION_APPLICATION_PAUSED` / `WM_GO_BACK_REQUEST`）。最后一条比调频率重要得多——它是**移动端被系统杀死前的最后机会**。
- 由此 `Push(profile, reason)` 增加 **`PushPolicy { Debounced | Immediate }`**。
- **账号级设置变更走 `PushPolicy.Debounced` + `SavePointReason.MetaChanged`，不新增 reason、不新增 flush 点。** 立即 flush 清单五项的共性是「不发出去就会丢玩家进度」或「这是被系统杀死前的最后机会」；一次音量变更丢失的代价是一个滑条位置。**它天然被「应用失焦 / 挂起」那一条兜住**——玩家改完设置切后台，那次 `Immediate` flush 顺带把它带走。这是「不必为设置新增 flush 点」的完整理由：不是「丢了也无所谓」，而是**既有机制已经覆盖**。离线时改设置照常可用（进待发队列、不阻塞）。设置的字段面与写入通道见 `systems/player-profile/game-setting.md`。
- **增量 push 粒度 = 按 `CharacterProfile` 做 diff。** `PlayerProfile` 整聚合含全部历史角色、随账号年龄**单调增长**，整体上行不可持续。粗算一次轮回约 200 事件 × ~2 KB diff ≈ **400 KB**，移动网络可接受。
- **规则字段层与统计计数层同走一条 push 通道，只在校验强度上分开。** 账号级字段分两层（判据 = 有没有被**规则**读，通则见 `systems/player-profile/_index.md`）：**规则字段**（`PlayerPowerFragment.*`、`chapterRetry` 等）严格上行、**后端可复算校验**；**统计计数**（`TotalCyclesCompleted` 等纯读数）走宽松口径、**可容忍丢失与最终一致**。二者**在同一次 diff 里、经同一次 `ProfileManager.TryApply` 写入**，不为统计计数另开写入通道或传输通道；**宽松口径不削弱规则字段的严格上行**。**不做两层之间的交叉一致性校验**——例如「`FinaleWinOrdinal` 应约等于统计通关数」这类校验等于在实现层宣称两个已被刻意分开的数应当相等。
- **「宽松」具体宽在哪五处。** 统计计数层的容器是 `PlayerStatistics`（见 `systems/player-profile/_index.md`）；两层同走一条 push 通道这一点不变，差异**穷举为五条**：

  | # | 面 | 规则字段层 | 统计计数层（宽松） |
  |---|---|---|---|
  | 1 | **施加失败** | element 缺失 → `ApplyResult.Fail`，整批不落 | **未知 `StatKey` → `PushWarning` + 跳过该条，不影响同批其余变更** |
  | 2 | **modifier pipeline** | 数值 element 经 `Apply(key, baseValue)` | **绝不经过 pipeline**——否则一条法则能改写统计数字 |
  | 3 | **读档校验** | 越界 → 钳制 + 告警；**不由历史重建** | 负值 / 越界 → `PushWarning` + 钳制到 0；**同样不由历史重建**，不阻塞 |
  | 4 | **上行被拒（`OpError.Conflict`）** | 按既定语义以云端为准丢弃本地缓冲 | **随之一并丢弃，不做补偿重放**——统计只会偏小，且补偿机制会重新造出一份客户端权威的第二真值 |
  | 5 | **后端** | 可复算校验 | **不复算、不校验，且不得用统计数据驱动任何发放**（活动奖励 / 解锁） |

  - **第 5 条是防滑坡的关键纪律：** 宽松口径成立的**全部前提**是「被篡改无玩法后果」。任何一处用统计去驱动发放都会当场击穿这个前提——**一旦这么用，它就变成了规则字段，必须整体升层**。这条须同时写进 `backend-design-documents/`。
  - **推论：统计层新增字段的成本近乎为零**——宽松同步 + 老档缺字段以默认值补齐（无损）+ 不参与任何判定 ⇒ 加一项统计既不需要迁移路径也不需要后端配合。这正是「首批清单最小化」的依据。
- **能力禁用表与统计层带来的存档 schema 影响：bump 一次，空迁移。** `CharacterProfile.disabledAbility`（老档缺字段 → 空列表）· `PlayerProfile.statistics`（→ 全 0）· `ProfileChangeSpec` 由单列表扩为按施加语义分列的多个列表（已落存档于 `PastEventEntry.SelectCost` / `AppliedChange`；老档单列表 → 读为 `Elements`，其余各列为空）。当前无线上存档 ⇒ **空迁移**，走既有 MigrationManager 骨架。**diff 粒度与体积估算不受影响**（禁用表条目 ≤ 数条，统计是两个 int）。
- **`pastEvent` 只追加，不修改既有条目（不变式）。** 一次事件只新增一条尾部 `PastEventEntry`，因此它对 diff 尤其友好：**只要 diff 能表达「列表尾部追加」，增量就是这一条本身，与列表已有长度无关**。这条不变式是下面体积估算成立的前提，也给 diff 实现一条可依赖的性质。
- **单事件 `pastEvent` 增量 ≈ 770 B（JSON 明文），落在 ~2 KB 预算内 ⇒ push 粒度不变。**

  | 组成 | 估算 |
  |------|------|
  | 标识与坐标（`Seq` / `InstanceId` / `EventId` / `BatchId` / `LocationId`） | ~150 B |
  | `SelectCost`（1–3 个 `ChangeElement`） | ~80 B |
  | `AppliedChange`（3–8 个 `ChangeElement`） | ~200 B |
  | 结算结果与冗余（`Outcome` / `LifeSpanAfter` / 敌人摘要） | ~100 B |
  | 未选项轻摘要 × 4 | ~240 B |
  | **合计** | **~770 B** |

  `pastEvent` 约占既有粗算的三分之一，整轮回 200 事件 ≈ 150 KB。**「按 `CharacterProfile` 做 diff」的既定粒度成立，不为快照体积新增任何机制。** 估算按每条痕迹 element 1–3 / 3–8 条计。
- **两个事件态字段的体积复核：+1–8 KB / 事件，不新增同步单元。** 批的规模已定（常态 3、区间 1–5），故可给出口径：`eventOption` 每事件一次**整键替换**约 1–6 KB（Exchange 批最重，含 `ExchangeStock`；`EventOption` 的 `Encounter` 格内嵌 `EnemyInstance` 后进一步上抬），`activeEvent` 额外复制其中最重的一份 option。
  - **整键替换对 diff 友好**：批与批之间没有承接关系，diff 上就是一次顶层键替换，与 `pastEvent` 的尾部追加同属可依赖的性质。
  - 两个字段都挂 `CharacterProfile` ⇒ **不新增同步单元**，diff 粒度不变；体积护栏（`pastEvent` > 500 条 / 序列化 > 512 KB）不受威胁。
- **体积护栏 = 软上限告警。** 单个 `CharacterProfile` 的 `pastEvent` **条数 > 500 或序列化 > 512 KB** 时 `GD.PushWarning` 带 `characterId` 与实际值。理由：`PlayerProfile` 是**整聚合 pull** 的单位（启动时全量一次），失控增长首先伤的是**启动 pull**，而那条路径是**硬阻塞**的。**告警不改变行为**，只让异常在被玩家感知之前先被看到。
  - **明确否决：现阶段不做 `pastEvent` 的分页 / 冷热分离 / 归档到独立存档段。** 无证据需要，且会把「云端权威 · 整聚合 pull」这条语义重新打开。
- **信封携带** `contentVersion` / `appVersion` / `revision`，让后端**不解 Profile** 即可做版本维度的聚合与异常检测（见 `content-service.md` 的双 `contentVersion` 记录）。**「信封」是两样东西**：前两项走 HTTP 头（**传输信封**），`baseRevision` / `pushId` / `schemaVersion` / `reason` 留 push body 顶层段（**负载信封**）。对位表见下方「传输信封的字段对位」。

### 断线降级

**总原则：绝不回退存档点。** 回退会抹掉玩家已打完的战斗；「云端权威」解决的是**冲突**，不是**丢进度**。

| 通道 | 失败时行为 |
|------|-----------|
| **Push（上行存档）** | **不阻塞玩家。** 变更进本地待发队列（`user://cache/pending/`，原子写，跨启动保留），指数退避重试；UI 常驻「离线 · 待同步 N」指示 |
| **Pull（启动全量）** | **硬阻塞。** 强制在线下无权威档即不可玩；呈现「重试 / 退出」，**不提供本地缓存开局**（本地非权威，用它开局等于制造必然冲突） |

> **只有这两条通道。** **表里没有「剧本请求」一行**——剧本内容属本地内容层，读取是纯内存的 ContentRegistry 查找，**不存在网络失败态**。唯一的缺失情形是悬空 key point，走 `PushWarning` + 叙事降级、不阻塞轮回（见 `plot-manager.md`），不是降级通道。

- **缓冲上限（两个闸门，先到先触发）：** 未同步的**事件级存档点数 ≥ 3**，或**最早一条待发变更滞留 ≥ 180 秒**。
  - **口径 = 事件级存档点。** 计的是**轮回开始 / 每个 AdventureEvent 结算后 / 篇章边界 / 轮回结束**这四类，**不含事件推进过程中的决策点存档**。理由：决策点密度约 **31 点 / 场战斗**，若把它们计入，一场战斗打到第三个决策点就会撞上闸门并弹出软阻塞模态，显然不是该闸门的本意。
  - **推论 ①：这把「存档点与 push 解耦」贯彻到了闸门口径上** —— **闸门计的是 push 单位，不是本地写入单位**。
  - **推论 ②：决策点存档回归本职** = 纯本地的崩溃恢复与防重掷手段，**不驱动 push、不计入闸门、不影响断线判定**；**决策点粒度不构成 push 防抖压力**，它只影响本地写入频率（毫秒级、无流量顾虑）。
  - **推论 ③：账号级设置变更同样不计闸门。** 它不是事件级存档点，故落在既定口径之外——这与「决策点存档不计入闸门」是**同一条推论的第二个实例**。**须明写而不靠读者自行推导**：否则一个在主菜单反复拖滑条的玩家会在离线时把闸门推满，弹出一个「网络异常，正在重连」的模态，显然不是那个闸门的本意。
  - **推论 ④：两个闸门的语义齐了** —— 都以事件级 push 为单位；且软阻塞的触发时机（「不打断进行中的事件，在下一次 AdventureEvent 选择前弹模态」）与闸门口径**自动对齐**，不必各说一次。
- **超限 → 软阻塞：** 不打断进行中的事件（战斗打完），但在**下一次 AdventureEvent 选择前**弹模态「网络异常，正在重连」，提供「重试 / 退出到主界面」。退出时待发队列**保留本地**。**该模态有第二种文案变体**，用于版本过旧导致的不可恢复态，见下方「`Upgrade` 类错误在非闸门点」。
- **限流（`rate.limited`）→ `OpError.Network`，走本表的 push 行**：进待发队列、不阻塞玩家、指数退避。**退避间隔取 `max(本地退避计算值, 服务端给的等待时间)`**——`Retry-After` 应答头或 `detail.retryAfterSeconds`；服务端值是**下界不是精确值**，本地抖动（jitter）照常叠加，避免同一批客户端齐步重试。**限流绝不映 `Conflict`**：它不改变 `cloudRevision`，原样重试即可（`pushId` 保证幂等），映成 `Conflict` 会按既定语义丢弃本地缓冲——把一次限流变成一次进度丢失。
- **恢复后的合并语义：** `FlushPending()` 前**先 pull**；若云端 `revision` 已领先本地基线（多设备），**以云端为准丢弃本地缓冲**，并明确告知玩家「另一设备的进度已生效，本次离线进度未保留」。**不做静默合并、不引入字段级三路合并**——那会实质削弱 `ADR-0003`。
- **push 侧退避的形态（数值见 `balance.md`「同步 / 内容管线旋钮」）：**
  - **指数阶梯 + 只向上的抖动**：`实际间隔 = max(本地退避计算值, 服务端给的等待时间) × (1 + rand[0, 0.2])`。**抖动只向上**——服务端给的是**下界**，双向抖动会以近半的概率产出低于下界的间隔，把一次限流变成第二次限流；只向上抖仍然把同一批客户端散在一个窗口内，错峰效果不减。
  - **上限必须小于滞留闸门。** 否则「最早一条待发变更滞留 ≥ 180 秒」这个判定可能在一次退避睡眠的中途才被发现，软阻塞比它该弹的时刻晚。上限之下至少要留出两次窗口内重试。
  - **没有放弃阈值**——退避无限进行、以上限封顶。三条依据的合取：① 放弃一条待发变更 = 丢玩家进度，直接违反「绝不回退存档点」，与重试了多少次无关；② 「告知玩家 + 拦住他继续累积」的职责已由上方两个闸门承担，且闸门以**次数 / 时长**触发、与重试耗尽无关；③ 真正「重试必然失败」的两种态各自定了**暂停**而非放弃（见下条与「`Upgrade` 类错误在非闸门点」）。**队列条目的淘汰路径只有既定的三条**：被后端接受、按云端权威丢弃、切账号清空。
  - **应用挂起期间不补偿、不追赶。** 恢复前台时按恢复那一刻重新起算下一次退避，**不重置阶梯层级**，也不为挂起时长补发多次重试——滞留计时器已如实记录玩家离线了多久，补发只会在恢复瞬间打出一串必然同时失败或同时成功的请求。
- **一行索引（本节不复述别处的降级）：** 内容与 flags 侧的降级见 `content-service.md`；身份侧的刷新失败分流见 `account-service.md`。
- **三条不变式（新增失败态时先拿它们核对）：**
  1. **阻塞点是穷举的四处**：登录 / 启动 pull 的版本闸门、被后端明确挤下线、启动 pull 失败本身（迁移失败落在它之内），以及购后 pull 的主菜单内重试。**没有第五处。**
  2. **「回退存档点」在任何降级路径上零次出现。** 云端权威只在**冲突**与**迁移失败**处生效，两者都不把玩家已打完的进度倒回去。
  3. **降级只有三种形状**：进队列 + 退避（push 侧）· 用上一个已知好值（内容 / flags 侧）· 硬阻塞并给出唯一动作（身份 / 权威档侧）。**新的失败态必须归入这三种之一，不得发明第四种。**
- **token 失效 / 被挤下线：** `RefreshToken()` 静默刷新；**刷新的失败按判据分流**——**网络失败**（发不出 / 收不到 / `server.unavailable`）**视同断线**走同一缓冲通道（不另开一套），**收到 `auth.session_revoked` 应答**则走下一条的硬阻塞、并**暂停退避重试**（重试必然失败）；被后端**明确挤下线** → **硬阻塞**要求重登，重登后同样**先 pull 后 flush**。判据与理由见 `account-service.md`，本文不复述。

### `revision` 语义与幂等键

- **`revision` = 后端分配的账号级单调递增整数（`long`）。** 分配权在**权威一侧**——「云端权威」这条决策本身就规定了它；让客户端分配版本号等于让非权威一侧决定「谁更新」，`ADR-0003` 会在这一点上被架空。
  - **排除服务端时间戳**：需要后端时钟单调且无回拨，同毫秒并发无法定序，相对整数计数器零收益。
  - **排除 ETag 字符串**：只支持判等，而既定语义要的是**有序比较**（「云端已领先」），且判等区分不出「落后」与「不可能态」。
  - **账号级一个 `revision`，不做 per-`CharacterProfile` 版本号**——同步单位是 PlayerProfile 聚合，`CharacterProfile` 粒度 diff 只是**传输优化**、不是同步单元；逐角色版本号会自然诱导出已被否决的字段级 / 角色级合并。
- **客户端只持一个基线值 `baseRevision`，它是传输层元数据，不进 Profile。** `baseRevision` = 最后一次被后端确认的版本号（pull 成功、或 push 被接受时后端返回的值），初值 `0` = 本设备尚无云端确认。依据是既定的「运行时 / 存档态只带 `Id` + 可变状态」：把它塞进 Profile 会**自指**（每次 push 都改动被 push 的东西），且会被卷进存档 schema 与迁移。
  - **落点 `user://cache/sync-envelope.json`**（`accountId` / `baseRevision` / `schemaVersion` / `lastAckAtUtc`），与待发队列 `user://cache/pending/` 同处、同样**原子写**、同样跨启动保留。
  - **连带：`revision` / `pushId` 的引入不 bump 存档 schema 版本、无迁移。**
  - **切账号即失效**：信封 `accountId` ≠ 当前登录账号 → **必需缺失**处置（`GD.PushError` + 定位上下文），丢弃信封、`baseRevision` 归 0、清空待发队列（跨账号的待发变更没有任何合法去处），**不是静默重置**。
  - **「切账号即失效」不是 `user://cache/` 的通则，是内含账号绑定数据的那几份文件各自的性质（承重）。** 本信封与 `flags.json` 带 `accountId` 且内容按账号成立，故切账号即丢弃 / 重建；而**一个账号字段也没有的设备维度小文件切账号不失效**——`device-settings.json`（设备本地偏好，见 `systems/player-profile/game-setting.md`）· `device-id.json`（设备标识，见 `systems/services/account-service.md`）· `dismissed-recommended-version.json`。**按通则理解会写出真实缺陷**：清掉设备标识 = 同设备切回原账号被判成一台新设备、白挤掉一次会话；清掉设备偏好 = 玩家的语言在换号时莫名其妙跳回系统语言。
- **上行 = 乐观并发（CAS），三分支闭合。** push 携带 `baseRevision` 作为前置条件：

  | 后端判定 | 语义 | 后端行为 | 客户端处置 |
  |----------|------|----------|-----------|
  | `baseRevision == cloudRevision` | 正常 | 接受写入，`cloudRevision += 1`，回 `newRevision` | 信封 `baseRevision = newRevision`，从待发队列移除该批 |
  | `baseRevision < cloudRevision` | **多设备已写入** | 拒绝，回当前 `cloudRevision` | 既定语义：以云端为准丢弃本地缓冲，`OpError.Conflict`，明确告知玩家 |
  | `baseRevision > cloudRevision` | **不可能态**（信封被改 / 后端回滚） | 拒绝，回当前 `cloudRevision` | 同 Conflict 处置 + `GD.PushError` 上报一次；**不试图自愈** |

  第三行单列而不并进第二行：**处置相同**（云端权威下答案唯一），但**它是应当被观测到的异常**——静默按第二行处理会让「客户端 `user://` 被改写」永远看不见。与 content-service 的「验签失败 → 拒绝 + 上报一次」同构。
- **幂等键 `pushId`（承重）。** 单靠单调 `revision` 会在「**请求已达、响应丢失**」这一移动网络常态下丢玩家进度：后端已接受并 `cloudRevision = 101`，客户端未收到 ack、仍以 `baseRevision = 100` 重试 → 被判 Conflict → 丢弃的正是玩家刚打完的那场战斗，而**根本没有第二台设备**。这直接违反「绝不回退存档点」，且 `Immediate` flush 点里恰有一个是**应用失焦 / 挂起**——响应最容易收不到的时刻。
  - **每个上行批次携带客户端生成的 `pushId`（GUID），重试时保持不变。** 后端记录最近若干已接受的 `pushId`，重复到达时**不再 +1**，直接回上次结果（`newRevision` + `Deduplicated = true`）；客户端据此把信封推进到正确的 `baseRevision`。
  - `pushId` 在**该批变更被组装时**生成一次，随待发队列条目持久化——**跨启动重试必须用同一个 `pushId`**，否则幂等键失去意义。缺 `pushId` 的队列条目按**必需缺失**处置：`PushError` + 丢弃该条目（无幂等键的重试比不重试更危险）。
  - 后端记忆窗口（记多少个 / 保留多久）属后端侧参数，本库不定。

### 后端主动写入的唯一情形 = 购买段，靠一条时机纪律关闭冲突窗口（承重）

> **premium bundle 的购买段由后端把云端 `bundleGrantOrdinal` 与 `cloudRevision` 各 +1**（付费凭证不能只信客户端，见 `systems/monetization.md`），这是同步模型此前没有的**第四种情形：后端主动写入**。它会让 `cloudRevision` 领先客户端 `baseRevision`，而 CAS 三分支表对这种情形判 `Conflict` ⇒ **以云端为准丢弃本地缓冲**。**若购买发生在轮回中途，被丢掉的正是玩家刚打完的战斗——直接违反「绝不回退存档点」。**

**解法不新增任何机制，只有一条时机纪律：**

> **购买流程只能在主菜单（轮回外）发起，且进入付费流程前待发队列必须为空。**

- 主菜单处无进行中的轮回变更，待发队列应为空；若非空（上一轮回残留 / 断线缓冲）→ **先 `FlushPendingAsync` 成功才允许进入付费流程**。这与礼包既有的闸 ②（购买入口不可用）合并为**同一张前置条件表**（见 `systems/monetization.md`），**不新增拦截点**。
- 购买成功后**强制一次 pull**（而非等下一次启动），拿到新 `revision` 与新序号，再本地兑现（兑现 = 客户端掷骰 + 一次 `TryApply` + `Immediate` push，后端复算校验）。验票端点与其应答形态见 `backend-design-documents/contracts/purchase.md`（verify 只回序号 + `revision`、不内联 profile，故这一次 pull 是必须的）。
- **购后 pull 失败 = 阻塞在主菜单重试直到成功（承重）。** 玩家已付款、后端已 `+1`，但客户端拉不到新序号 ⇒ **停在主菜单重试，不允许在未兑现状态下开始新轮回**。依据与「不收钱又不给货」那条纪律同向；且此刻玩家**本就在主菜单**（购买入口前置条件 1），阻塞代价最小——没有任何进行中的轮回被打断。
  - 重试路径走后端的**收据幂等读**（`purchase.md`），`receiptId` 随待兑现态持久化。**但它只是加速补查的优化，不是正确性的承载者**：正确性由 `/entitlement` 两字段之差（`bundleGrantOrdinal > bundleRedeemedOrdinal`）承载。**跨启动补入口因此是「每次启动 pull 之后、进入主菜单之前比较一次两字段」**，不依赖本地待兑现态是否还在——本地态存在时可省掉一次「先 verify 再 pull」的往返。字段与不变式见 `systems/player-profile/_index.md`。
  - UI 是 Store 流程内的**全屏模态进度态**（`STORE_` 分区文案），**不是 `BlockingNoticeScreen` 的变体**——它不由任何后端 `code` 触发且有自愈路径，故不进变体表；**硬阻塞仍只有既定两处**，本处不新增拦截点。形态见 `ux/error-and-blocking-ux.md`。
  - **否决「允许离开、下次启动补兑现」**：兑现被推迟到不确定的时刻，期间玩家看不到自己买的东西。**否决「本地先乐观兑现、后端复算兜底」**：等于客户端有权发货，正是购买段权威分配里已明确否决的那条。
- **上行组装 `entitlement` 键时必须原样回声 pull 下来的 `bundleGrantOrdinal`，客户端永不自行赋值（承重）。** diff 语义是「顶层键出现即整键替换」⇒ **每一次兑现 push 都会提交 `entitlement` 整键**（其中真正变化的只有客户端写的 `bundleRedeemedOrdinal`），因此每次兑现都会被后端拿这一位与云端值比对。**不一致即该批被拒**——校验规则、拒绝语义与其风控处置的权威在 `backend-design-documents/contracts/profile-sync.md`，本库不复述。**客户端侧不新增任何分支**：收到该情形的 `Conflict` 一律走既有处置（以云端为准、丢弃本地缓冲、重新 pull，随后按两字段之差重新判定是否仍有待兑现）。
- 于是冲突窗口在结构上被关闭：**那一刻客户端没有任何未上行的变更，`Conflict` 分支不可能踩到。** CAS 三分支表与「冲突一律以云端为准」原样成立，不为购买开任何例外。
- **否决「购买入口在轮回内可用 + 为它设计冲突合并」**——等于为一个可以靠时机纪律消除的问题引入字段级三路合并，而那已被 `ADR-0003` 明确排除。
- **这条纪律同时是一条 UX 结论**：礼包入口在轮回内 / 战斗内 / 结算流程内**不存在**——不是观感取舍，是同步模型的结构要求（因此「重试耗尽时提示购买」在结构上就不可行，见 `ux/screen-flow.md`）。

### `Immediate` flush 的失败语义

> **flush 是一次「尝试」，闸门是一个「状态」。** `Immediate` 只声明「这一批不等防抖窗口，立刻发」，**不声明「发不出去就停下」**。它对软阻塞的**唯一**影响是：成功则清空闸门（待发队列空、滞留计时归零），失败则闸门计数**不变**。阻塞与否始终只由闸门在**既定时机**判定——下一次 AdventureEvent 选择前。

- **进入战斗前的 flush 失败不挡玩家**（原「软阻塞 × 进战斗前 flush 的先后顺序」之问就此消解——两者不是先后关系，而是不同层）。四条既有定案各自独立地指向同一答案：① 断线降级表已写明 push 失败**不阻塞玩家**，且该行为**从不按 `PushPolicy` 分叉**；② 软阻塞的措辞是「不打断进行中的事件（战斗打完）」，而选中 Combat 那一刻事件**已经开始**（`SelectCost` 已施加、终态判定 ① 已过），挡在战斗外**就是**打断；③ `SelectCost` 不回滚 ⇒ 挡住 = 付了成本却拿不到事件，比丢一次同步严重得多；④ **D0 不参与闸门判定已是定案**，而 D0 就是「进入战斗前」这个 flush 点——同一个点不能一边被排除在计数外、一边又能独立触发模态。
- 由此两种情形各自闭合，**都不需要新机制**：

  | 时刻 | 闸门状态 | 结果 |
  |------|---------|------|
  | **事件选择前**已超限 | 触发 | 模态在**那时**就弹了（既定时机）。重试成功 → 闸门清空 → 正常进入战斗；或退出到主界面。**走不到「进入战斗前」这一步** |
  | 事件选择前未超限，**选中 Combat 后**才断网 | 未触发 | 进战斗前的 `Immediate` flush 失败 → 变更进待发队列 → **照常进入战斗** |

- **三条连带推论：**
  - **战斗结束后闸门自然对齐。** 事件结算是事件级存档点，给闸门 +1；若因此达到 3，模态在下一次事件选择前弹出——正是既定时机。「口径自动对齐」这条推论在战斗路径上同样成立。
  - **滞留计时不因战斗进行而暂停。** 一场战斗常超过 180 秒，「进战斗前 push 失败 → 打 6 分钟 → 战斗结束时最早一条滞留 360 秒」会在下一次事件选择前触发闸门。**这是正确行为**——玩家确实已经离线 6 分钟了。
  - **「进入战斗前」这个 flush 点的意图**不是 flush D0 自己那点 diff（D0 本就不计闸门），而是**趁着即将进入一段长时间无事件级存档点的区间，尽力把队列里已有的事件级变更送出去**。这解释了它为什么是 `Immediate`——也正因目的是「尽力」，失败更不该有阻塞力。同理适用于**应用失焦 / 挂起**那个点（应用不在前台，也无处弹模态）。
- **唯一不受本条影响的是既定的两处硬阻塞**：启动 pull 失败、被后端明确挤下线。它们与 push 通道无关。
- **呈现纪律：进入战斗前 flush 失败不产生任何额外提示**，告知由既定的常驻「离线 · 待同步 N」指示承担（**该指示在战斗屏内也必须可见**）。见 `ux/combat-ux.md` 与 `ux/screen-flow.md`。

### `Upgrade` 类错误在非闸门点

> **承重纪律：`Upgrade` 类错误只在登录 / 启动 pull 构成硬阻塞，其余时机一律降级为非阻塞。** 典型情形是 `sync.payload_schema_unsupported` 在**轮回中途的 push** 上返回，且它重试**永远不会成功**。

- 四条处置：**本地缓冲保留、不丢弃**（绝不回退存档点）· UI 出一条**非模态**「需更新版本才能同步」提示 · **暂停自动退避重试**（重试必然失败，退避只是空耗电量与流量）· 恢复点 = 玩家更新并**重新登录**后先 pull 后 flush。
- **暂停退避的唯一解除条件是「重新登录成功」**——不因时间流逝、不因应用重启自动恢复。退避的前提是「可能会好」，这里不会。
- **与「缓冲超限 → 软阻塞」的衔接：两个闸门的口径完全不变**（事件级存档点数 ≥ 3 或最早一条滞留 ≥ 180 秒），仍在下一次 AdventureEvent 选择前弹软阻塞模态。**变的只有文案与选项**——同一处模态的**第二种变体**：「需更新版本才能同步」，选项「去更新 / 退出到主界面」，**没有「重试」**。
  - 理由：同步在本会话内**永不恢复**，继续玩只会累积必然无法上行的进度——**软阻塞的本意正是拦住这一点**。冻结闸门会让玩家整轮回打完才发现全部进度无处可去。只有文案与选项该变，机制不该变。
  - 沿用既定的「不打断进行中的事件（战斗打完）」时机，不引入第三种阻塞时机。
- **`UpgradeRequired` 的呈现落点：** 常驻同步指示改写为 **`需更新 · 待同步 N`**（**必须换掉「离线」二字**——「离线」隐含「会自己好」，而本态在本会话内永不恢复），点按打开更新引导半屏；同时**吸收掉**「建议更新」软提示横幅。三档去重规则见 `ux/error-and-blocking-ux.md`。
- **UI 如何区分两种变体：** `SyncStateChanged(SyncState, OpError)` 分辨不出「`Failed` + `Validation`」是 `sync.payload_invalid` 还是 `sync.payload_schema_unsupported`。**不新增 `SyncState` 值**，改为本服务增一个只读属性 `UpgradeRequired`，UI 收到事件后**单点查询**——与 `PendingCount`（「不塞进负载，收到事件后单点查询本属性」）及 `CapabilitiesChanged` 空负载同构。置位于收到任一 `class: Upgrade` 错误，清零于重新登录后的一次成功 pull。

### 传输信封的字段对位

**客户端 record 一字不改；`HttpProfileBackend` 在发请求时搬字段。** 契约本就允许「报文字段名与客户端字段名不同」。

| 客户端持有 | 报文位置 |
|---|---|
| `Session.Token` | `Authorization: Bearer <token>` 请求头 |
| `ProfilePayload.AppVersion` | `X-App-Version` 请求头（semver 三段） |
| `ProfilePayload.ContentVersion` | `X-Content-Version` 请求头 |
| —（新增，仅日志） | `X-Request-Id` 请求头 |
| `ProfilePayload.PushId` / `.BaseRevision` / `.SchemaVersion` / `.Reason` | **留在 push body 的负载信封段** |

- **`X-Request-Id` 与 `pushId` 是一对反向纪律，不可混同：** `pushId` 是幂等键，**跨启动重试必须不变**；`X-Request-Id` 是日志关联键，**每次重试都必须换**。两者写在同一个请求里——写反哪一个都会静默失效：一个丢进度，一个让日志无法定位单次尝试。
- **`baseRevision` / `pushId` 不搬到头、不用 `If-Match`/ETag 表达 CAS**：CAS 前置条件与它保护的负载留在同一层面，且三分支应答本就要在 body 回 `cloudRevision`。既定 record 与三分支表原样成立。
- **请求头组装与应答头解析收敛到 `src/Core/` 的一处**，三个 `HttpXxxBackend` 共用——与 `BackendSelector` 唯一选择点同构（多于一处就会出现「一部分带了头、另一部分没带」的半配置态）。应答头的客户端语义：`X-Flags-Version`（触发 flags 拉取，见 `content-service.md`）· `X-Min-App-Version`（**仅诊断，客户端不比较、不据此阻塞**）· `X-Recommended-App-Version`（软提示，永不阻塞）· `X-Server-Time`（**纯诊断**，不参与玩法判断，**也不用于校正本地时钟**）· `Retry-After`（退避下界）。
- **枚举值序列化与 C# 枚举名逐字相同**（`SavePointReason.EventResolved` → `"EventResolved"`）⇒ **重命名一个跨边界枚举值即是破坏性契约变更**，必须与后端同批改，不能当作纯客户端重构。**`CostKey` / `StatKey` 同受这一条**：两者随 `ProfileChangeSpec` 落进 `PastEventEntry.SelectCost` / `AppliedChange`，故成员名是存档与上行契约的一部分——**只可追加，永不改名 / 复用**；成员**序**则不构成契约。清单与配套的启动期断言见 `systems/architecture.md` 与 `systems/services/profile-service.md`。**`Source` 同受这一条**：上行走成员名、存档走整数 code，**映射就在本服务组装上行负载时做一次**（不在 profile-service 内部做，存档态始终是 code）；名与 code 双双冻结，见 `systems/common-properties.md`。

### 透明路径的稳定性纪律（承重）

> **Profile 里有一小撮字段是后端读得懂的**（复算与不变式校验的输入），它们的 **JSON path 本身就是契约的一部分**。逐条清单的权威在 `backend-design-documents/contracts/profile-sync.md` §5，本库不复制。

- **移动或重命名任一透明路径 = 破坏性契约变更**，必须 bump `schemaVersion` 并与后端同批改——与「重命名跨边界枚举值」同一条纪律。
- **为什么它比普通重构危险：** 把某个字段挪个位置、改个名，在客户端侧是纯重构（老档靠迁移无损通过），但**在后端侧会静默变成「这个字段消失了」**——复算退化为空操作，**且两侧都不会报错**。后端对缺失的透明路径记告警级台账、不拒绝上行，使这类漂移在线上可见，但那是事后发现，不是防线。
- **先按人工清单执行，暂不机械化。** 落在「纪律的可执行化」阶梯的低档是有意的——不为一条**尚无实例**的纪律先行造工具。**留一条触发条件：首次真的发生透明路径漂移（后端告警台账记到第一条）时，回头把它升级为机械检查**，而不是等它攒够教训。
- **diff 的序列化形态须与契约的顶层键浅合并逐字对齐**：`PlayerProfileDiff` 中出现的顶层键即整键替换、未出现的保持不变、空对象 = 无变化、**不表达删除**（`PlayerProfile` 只增不删，无需删除语义）。`CharacterProfileDiff` 同理，整体替换该 `characterId` 下的值。键值以下的结构对后端完全不透明——**本服务因此不得依赖后端做任何逐元素合并**。
Source: `handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md` · `handoffs/2026-07-27-content-gating-offline-resilience-and-rng-persistence.md` · `handoffs/2026-08-06-ch1-band-widening-cross-realm-crush-and-chapter-retry.md` · `handoffs/2026-08-09-sync-revision-cas-and-immediate-flush-nonblocking.md` · `handoffs/2026-08-09c-past-event-trace-schema.md` · `handoffs/2026-08-09d-field-layering-merge-criterion-and-ordinal-naming.md` · `handoffs/2026-08-10c-ability-disable-replacement-and-player-statistics.md` · `handoffs/2026-08-11-plot-content-localization.md` · `handoffs/2026-08-11b-contract-boundary-and-flags-client-side.md` · `handoffs/2026-08-12-error-copy-and-update-prompts.md` · `handoffs/2026-08-15b-monetization-entitlement-purchase-shape-and-scope.md` · `handoffs/2026-08-16b-cross-library-alignment-and-bridge-ledger.md` · `handoffs/2026-08-17j-event-option-derived-persistence.md` · `handoffs/2026-08-19-bundle-grant-ordinal-authority.md` · `handoffs/2026-08-19-costkey-statkey-registry.md` · `handoffs/2026-08-19-game-setting-schema.md` · `handoffs/2026-08-19-architecture-structural-residuals.md`

## 管理器

| manager | 职责 |
|---------|------|
| **ProfileSyncManager** | Pull / Push（5 秒防抖 + Immediate 直通）、`CharacterProfile` 粒度 diff、冲突以云端为准、断线缓冲队列与重试 |
| **LocalCacheManager** | 本服务名下 `user://` 文件的读写与失效（同步信封、待发队列 `user://cache/pending/` 的持久化）。**原子写本身不由它实现**——它调用共享静态工具 `AtomicJsonFile`（见 `systems/architecture.md`），与 `user://cache/` 的其余写入方同用一份 |
| **MigrationManager** | 存档 schema 版本校验、逐版迁移路径、无法迁移时的清晰拒绝 |

## API 面（契约）

> 总则与共享类型见 `systems/architecture.md`「API 契约总则」。本服务实现 `IBootstrappable`（启动链第三步：pull + 迁移）。

| 方法 | 形态 | 完整签名 | 失败语义 |
|------|------|----------|----------|
| 拉取 | B | `Task<OpResult<PlayerProfile>> PullProfileAsync(string accountId, CancellationToken ct)` | 业务失败 → `OpResult`；迁移失败 → `OpError.Migration`，`Detail` 带 `fromVersion → toVersion` |
| 上行 | B | `Task<OpResult> PushAsync(SavePointReason reason, PushPolicy policy, CancellationToken ct)` | 失败进本地待发队列，`OpError.Network`；**不阻塞玩家——`policy` 不改变这一条** |
| 补提交 | B | `Task<OpResult> FlushPendingAsync(CancellationToken ct)` | **内部先 pull**；`cloudRevision > baseRevision` → 丢弃本地缓冲 + `OpError.Conflict`；`cloudRevision < baseRevision`（不可能态）→ 同处置 + `GD.PushError` |
| 同步态 | A | `SyncState State { get; }` | — |
| 待发条数 | A | `int PendingCount { get; }` | — （既定的「离线 · 待同步 N」指示由 UI 收到 `SyncStateChanged` 后单点查询本属性，而非塞进负载——同 `CapabilitiesChanged` 的纪律） |
| 同步版本 | A | `long BaseRevision { get; }` | — **只读诊断用**（设置屏「同步版本 #N」）；不参与玩法判断、不进玩法路径 |
| 需更新 | A | `bool UpgradeRequired { get; }` | — UI 收到 `SyncStateChanged` 后**单点查询**，据此选软阻塞模态的第二种文案变体；置位于任一 `class: Upgrade` 错误，清零于重登后的一次成功 pull |

```csharp
public enum SavePointReason { CycleStarted, EventResolved, ChapterBoundary, CycleEnded, MetaChanged }
public enum PushPolicy      { Debounced, Immediate }
public enum SyncState       { Idle, Syncing, Buffered, Offline, Failed }
// Debounced : 进 5 秒合并窗口   Immediate : 跳过合并窗口，立刻发
// 两者在【失败处置】上完全一致：进待发队列 + 指数退避 + 不阻塞玩家。
// Immediate 声明的是「不等」，不是「必须成功」。
```

- **`PullProfileAsync` 的服务门面签名刻意不带 `Revision`。** 它是本服务的内务，profile-service / game-progression 不该看见——泄漏出去就会有人拿它做判断，而「谁是权威」这件事不该被第二处代码回答。`BaseRevision` 属性是这条纪律的另一面：**暴露给人看可以，暴露给代码判断不行。**

三点推演：

- **`PushAsync` 不接收 profile 参数。** profile 的内存权威在 profile-service，本服务只负责**持久化与传输**；让调用方递一份 profile 进来等于把「谁是权威」这件事再打开一次。本服务内部经 `ProfileService.Instance.Snapshot` 取快照，做 `CharacterProfile` 粒度 diff。
- **`reason` 保留**，它同时驱动日志、重试策略与合并窗口；`policy` 决定是否受 5 秒防抖约束（`Immediate` 直通）。
- **信封仍带** `contentVersion` / `appVersion` / `revision`——传输信封走 HTTP 头、负载信封留 body，见「传输信封的字段对位」。

**后端接口（总则 7）：** 本服务持有 `IProfileBackend`（`PullAsync` / `PushAsync`），两份实现 `HttpProfileBackend` / `OfflineProfileBackend`（内存回显）。两个方法的返回类型**都带 `revision`**——否则客户端无从得到基线值：

```csharp
internal interface IProfileBackend
{
    Task<OpResult<ProfileSnapshot>> PullAsync(string accountId, CancellationToken ct);
    Task<OpResult<PushAck>>         PushAsync(ProfilePayload p, CancellationToken ct);
}

// 传输层元数据：不进 PlayerProfile、不进存档 schema、不参与迁移
internal sealed record SyncEnvelope(string AccountId, long BaseRevision, int SchemaVersion, DateTime LastAckAtUtc);

internal sealed record ProfilePayload(
    string                              PushId,          // 幂等键：批次组装时生成一次，跨启动重试保持不变
    long                                BaseRevision,    // CAS 前置条件
    SavePointReason                     Reason,
    IReadOnlyList<CharacterProfileDiff> CharacterDiffs,
    PlayerProfileDiff                   PlayerDiff,
    int                                 SchemaVersion,
    int                                 ContentVersion,  // 信封三件套（既定）
    string                              AppVersion);

public readonly record struct PushAck(long NewRevision, bool Deduplicated);
public sealed record ProfileSnapshot(PlayerProfile Profile, long Revision, int SchemaVersion);
```

> 本库只定**客户端的调用形状**与「客户端每批携带稳定幂等键、后端据它去重」这一**语义**；报文字段名、后端记忆窗口不在本库定稿（总则 7 的边界）。

**事件面：** `SyncStateChanged(SyncState State, OpError LastError)` —— 一个负载覆盖同步成功 / 失败、进入断线缓冲态、缓冲超限（软阻塞）、离线进度被云端覆盖（`State = Failed` + `LastError = Conflict`）；UI 据此渲染「同步中 / 离线 · 待同步 N」指示与模态阻塞。迁移发生 / 拒绝走 `OpError.Migration`。

### 图鉴六键的序列化形态与体积口径

六本图鉴落 `PlayerProfileDiff` 的**六个顶层键**，元素是 `CodexEntry`（只有一个 `Id`；字段面权威见 `systems/player-profile/codex/common-properties.md`）：

```jsonc
"enemyCodex":          [ { "id": "enemy_..." }, { "id": "enemy_..." } ],
"characterPowerCodex": [ { "id": "power_..." } ],
"playerPowerCodex":    [ … ],
"characterItemCodex":  [ … ],
"playerItemCodex":     [ … ],
"locationCodex":       [ { "id": "loc_..." } ]
```

- **六个键都是顶层键 ⇒ 整键替换。** **推论：解锁一条 = 整本图鉴的 id 列表全量上行。** 六个名已合规（单数 · camelCase）。
- **体积口径（承重）：** 单条约 25–35 B；某本的上限约「该内容类型的条目总数 × 30 B」，六本合计在内容规模成型后落在 **20–40 KB** 量级。它小于单轮回 `pastEvent` 的量级，但与之同形——**随账号年龄单调增长且永不收缩**。
- **体积护栏（软上限告警）：** 任一本图鉴的条目数 **>** 该内容类型经 `AllIncludingDisabled()` 得到的条目总数 → `GD.PushWarning` 带图鉴名与两个数值。它抓的是**重复条目 / 悬空条目**这类真实缺陷（正常账号永远达不到上限），成本近乎为零。
- **明确不做：** 不为图鉴引入分页 / 冷热分离 / 独立存档段——与 `pastEvent` 那条否决同理由、同证据强度（无证据需要，且会重开「云端权威 · 整聚合 pull」的语义）。
- **本地缓存无独立文件。** 图鉴随整个 `PlayerProfile` 走 `LocalCacheManager`，不新增缓存文件、不新增序列化路径。
- **六个键不进透明路径白名单。** 后端不复算图鉴、不据它发放任何东西 ⇒ 零配合。**但字段名仍受 camelCase 机械映射约束**——改名仍是破坏性契约变更。⚠ 若图鉴完成度将来被用于驱动发放，六个键须整体升为透明路径并与后端同批落笔。
- **`CodexKind` 随 `PastEventEntry.AppliedChange` 落存档**（`AppliedChange` 是 `ProfileChangeSpec` 快照），虽落在不透明部分，**成员名仍须在第一批存档写下前冻结**，与 `SavePointReason` / `Source` 同档对待。
- **图鉴统计的分母走 `AllIncludingDisabled()`**（「已解锁 X / 共 Y」必须含 disabled 条目，否则线上关一条内容会让完成度百分比跳变）。

### 存档 schema 版本

- **`PlayerProfile.entitlement`（`PlayerEntitlement`，2 字段）⇒ bump 一次、空迁移**（老档缺字段 → 两个序号皆 `0` = 未购买 · 从未兑现，无损）。它是规则字段层：**严格上行、后端可复算**，两条透明路径 `/entitlement/bundleGrantOrdinal` 与 `/entitlement/bundleRedeemedOrdinal`；前者是**后端唯一会写入的第二个字段**（验票通过时 `+1`），后者由客户端写、后端只读并校验不变式。白名单与后端侧语义见 `backend-design-documents/contracts/profile-sync.md` §5。
- **`PlayerPowerFragment` 增 `LastRoll` / `LastEffectiveChance` 两个 `int`** ⇒ 同批 bump、老档补默认值（无损）。两者进透明段，供后端复算比对，见 `systems/player-profile/_index.md`。
- 本次新增 `rng`（见 `systems/character-profile/_index.md`）、`StartContentVersion`、`LastContentVersion`、**`activeCombat`（战斗中间态，可空；schema 见 `combat-service.md`）**、**`pastEvent` 的条目结构 `PastEventEntry`（schema 见 `systems/adventure-event/common-properties.md`）** → **bump schema 版本**。当前无线上存档 ⇒ 空迁移。
- **战斗随机的 `attemptIndex` 派生层不落存档**，故它的有无不影响 schema 版本。
- **两层 Profile 的字段面收口 ⇒ bump 一次、一段迁移说明。** 下列改动**合并为同一次 bump**——它们同批落笔、彼此的默认值互不依赖，拆成多次只会让迁移器多几级空跳。**后续同批新增的字段追加进本清单，不另起一次 bump。**

  | 对象 | 本次改动 |
  |---|---|
  | `ProfileChangeSpec` | 增列 `PlotElements` / `EventStateChanges` / `RngElements` / `TraceElements` / `CodexElements` / `SettingChanges`（元素类型 `RngStateAssignment` / `PastEventEntry` / `CodexUnlock` / `SettingAssignment`）；`ChangeElement` 增第三字段 `Op`；`ElementSpec` 增第六列 `AllowedOps`；`DeckChangeOp` 增 `AddLooseCard` ⇒ **`PastEventEntry.AppliedChange` 的形状随之变** |
  | `CharacterProfile` | 增 `id` / `characterDataId` / `defeatReason` / `technique` / `looseCard`；增 `eventOption` / `activeEvent`；`Status` 移除 `currentMana`（移入 `activeCombat`）；`startContentVersion` / `lastContentVersion` 由 `string` 改 `int`；`rng` 片段键名对齐 camelCase（`cycleSeed` / `stream`） |
  | `PlayerProfile` | 增六个 Codex 字段（元素 `CodexEntry`）；增 `gameSetting`（子对象 `GameSetting`）；四类持有条目定形，条目键名取 `powerId` / `itemId`；集合字段名一律改单数 |
  | `EventOption` | 增 `OutcomeSpec` 与 `Encounter` 两格 |
  | `PastEventEntry` | 增 `EnemyTraceRef` 一格 |

  - **`ProfileChangeSpec` 的四个新增列（`RngElements` / `TraceElements` / `CodexElements` / `SettingChanges`）与两个新增子对象 schema（`CodexEntry` / `GameSetting`）同属上表这一次 bump，不另起第二次。** 它们同批落笔、默认值互不依赖（缺列 / 缺字段一律补空列表或配表默认），拆成多次只会让迁移器多几级空跳。**bump 清单只有上表一份**——列面与字段面的每一项都登记在这里；别处提到「增列 ⇒ bump」指的都是**这同一次**，不构成第二次。
  - **老档补默认值口径：** 集合 → 空列表；`DefeatReason?` → `null`；`ChapterRetry` → 全 0；`eventOption` / `activeEvent` → `null`；`gameSetting` 缺字段 → 取 `SettingFields` 的默认列。当前无线上存档 ⇒ 实际为空迁移。
  - **集合字段改单数是破坏性契约变更**（Profile 透明段字段名经序列化策略机械映射为 JSON path），故它与后端白名单同批改；成立的三个前提是「线上无真实账号数据 · 两侧同批落笔 · 一次性不设兼容期」。通则与边界见 `systems/player-profile/_index.md`。

- 当前无线上存档，故迁移为**空迁移**——**就在此刻**把 MigrationManager 的逐版迁移骨架立起来，这是最便宜的时机（等有了线上存档再补，成本高一个量级）。
- **增删 RNG 子流不 bump schema 版本**（子流清单是 `SeedManager` 内的常量，读档时按缺失 / 多余分别 warn + 初始化 / warn + 丢弃）。

### JSON 序列化命名策略

- **存档 / 上行负载的 JSON 一律 camelCase，命名策略配置在一处。** 客户端 C# 字段是 PascalCase，而契约里的透明路径全是 camelCase；多于一处配置必然出现「一部分转了、另一部分没转」的半配置态——与「请求头组装与应答头解析收敛到一处」同构。
- **推论（承重）：C# 字段名与 JSON path 由这条策略机械对应。** 故**重命名任一透明段的存档字段 = 破坏性契约变更**，不需要额外纪律，透明路径稳定性纪律自动覆盖到 C# 字段名这一侧。集合字段名恒为单数这条通则由此成为跨边界通则，见 `systems/player-profile/_index.md`。
- **`schemaVersion` 不是 `PlayerProfile` 的字段。** 它的落点是存档 / 传输的信封——`SyncEnvelope` · `ProfilePayload` · `ProfileSnapshot` 三处形态一致。理由与 `baseRevision` 逐字相同：**把版本号塞进被版本化的对象会自指**，且会被卷进它自己的迁移路径。

### 迁移失败的「清晰拒绝」= 玩家侧两种情形

`MigrationManager` 的「无法迁移时清晰拒绝」在 UX 上落为**阻塞屏的两种变体**，先按判据分情形——绝大多数情况根本不是「存档坏了」：

| 情形 | 判据 | 玩家侧表现 |
|---|---|---|
| **云端 `schemaVersion` 高于客户端支持上界** | 迁移前即可判定 | 走阻塞屏的**「需更新」变体**，主按钮「去更新」。与 `client.version_unsupported` **同因不同径**——客户端太旧，只是这次由本地迁移器先发现 |
| **`schemaVersion` 在支持范围内但迁移逻辑抛错** | 迁移过程失败 | 走阻塞屏的**「存档读取失败」变体**，主按钮「重试」；**必上报一次**（`GD.PushError` + `fromVersion→toVersion` + `accountId`）——它是**真正的程序缺陷态**，对上本服务「处置相同但它是应当被观测到的异常，静默处理会让它永远看不见」那条纪律 |

- **绝不静默降级放行。** 带着半迁移的 Profile 进入主菜单，下一次 push 会把一份**已损坏的档写回云端**——那才是不可逆的。这是「必需缺失 → 报错退出」，不是「可选缺失 → 降级」。
- **否决「提示重装」**（存档权威在云端，重装不改变任何东西，只制造「我的进度没了」的误解）与**「回退到云端上一个可用版本」**（`revision` 严格单调递增，回退即主动丢弃已确认进度，违反云端权威）。
- **不新增硬阻塞点**：两种变体都发生在**启动 pull** 这一既定阻塞处之内。呈现形态见 `ux/error-and-blocking-ux.md`。

Source: `handoffs/2026-07-27b-service-api-contracts.md` · `handoffs/2026-08-12-error-copy-and-update-prompts.md` · `handoffs/2026-08-15b-monetization-entitlement-purchase-shape-and-scope.md` · `handoffs/2026-08-16b-cross-library-alignment-and-bridge-ledger.md` · `handoffs/2026-08-17h-profile-field-schema.md` · `handoffs/2026-08-19-bundle-grant-ordinal-authority.md` · `handoffs/2026-08-19-codex-entry-schema.md`

## 与其他服务的关系

- **上游：** `account-service` 提供 `accountId` 与 token；`profile-service.ProfileManager` 是内存态的唯一写入面，本服务只负责**持久化与传输**，不改字段语义。
- **触发方：** `life-cycle-service` 在状态机边界触发自动存档点；`game-progression` 在核心循环第 ⑤ 步触发。

## 决策(-> ADR)

- **强制在线 · 云端权威**（冲突以云端为准、本地仅缓存） → `decisions/ADR-0003-online-cloud-authority.md`（Accepted）。

## 待决问题

- **`pushId` 的后端记忆窗口。** 记忆多少个 / 保留多久属**后端侧**参数，客户端侧语义已定。→ `backend-design-documents/open-questions.md`。（**报文字段名与序列化形态已定**：表达形式 = OpenAPI 3.1 + JSON Schema 单点、两侧各持自己的 DTO，`pushId` / `baseRevision` / `schemaVersion` / `reason` 落 push body 的负载信封段。权威：`backend-design-documents/contracts/envelope.md`。）

## 对应
提炼至：`.claude/knowledge/systems/sync-service.md`（引用层，待建）。
