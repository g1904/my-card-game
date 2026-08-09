# sync-service（服务）

> 存档与云同步服务：Profile 上下行、本地缓存原子写、schema 版本迁移。**判据 ②③ —— 事务性写入 + 外部 I/O 边界。**
> Source: `handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md`。

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

### 存档点与 push 解耦（已定案）

- **「存档点」与「push」是两件事。** 逻辑存档点清单（轮回开始 / 每个 AdventureEvent 结算后 / 篇章边界 / 轮回结束）**保持不变**，每个点**立即原子写本地缓存**（毫秒级，无流量 / 电量顾虑，是崩溃恢复的第一道防线）；**受频率约束的只是网络 push**。
- **合并窗口：push 5 秒防抖**——窗口内多次变更合成一次上行。一次 AdventureEvent 以分钟计，5 秒足以吃掉「事件结算 + 奖励 + 属性推拉」这类连续写。
- **强制立即 flush（不受防抖约束）：** 篇章边界、轮回结束、角色 `defeated`、**进入战斗前**、**应用失焦 / 挂起**（`NOTIFICATION_APPLICATION_PAUSED` / `WM_GO_BACK_REQUEST`）。最后一条比调频率重要得多——它是**移动端被系统杀死前的最后机会**。
- 由此 `Push(profile, reason)` 增加 **`PushPolicy { Debounced | Immediate }`**。
- **增量 push 粒度 = 按 `CharacterProfile` 做 diff（已定案）。** `PlayerProfile` 整聚合含全部历史角色、随账号年龄**单调增长**，整体上行不可持续。粗算一次轮回约 200 事件 × ~2 KB diff ≈ **400 KB**，移动网络可接受。
- **规则字段层与统计计数层同走一条 push 通道，只在校验强度上分开（已定案 · 08-09d）。** 账号级字段分两层（判据 = 有没有被**规则**读，通则见 `systems/player-profile/_index.md`）：**规则字段**（`PlayerPowerFragment.*`、`chapterRetry` 等）严格上行、**后端可复算校验**；**统计计数**（`TotalCyclesCompleted` 等纯读数）走宽松口径、**可容忍丢失与最终一致**。二者**在同一次 diff 里、经同一次 `ProfileManager.TryApply` 写入**，不为统计计数另开写入通道或传输通道；**宽松口径不削弱规则字段的严格上行**。**不做两层之间的交叉一致性校验**——例如「`FinaleWinOrdinal` 应约等于统计通关数」这类校验等于在实现层宣称两个已被刻意分开的数应当相等。Source: `handoffs/2026-08-09d-field-layering-merge-criterion-and-ordinal-naming.md`。
- **`pastEvent` 只追加，不修改既有条目（不变式 · 已定案 · 08-09c）。** 一次事件只新增一条尾部 `PastEventEntry`，因此它对 diff 尤其友好：**只要 diff 能表达「列表尾部追加」，增量就是这一条本身，与列表已有长度无关**。这条不变式是下面体积估算成立的前提，也给 diff 实现一条可依赖的性质。
- **单事件 `pastEvent` 增量 ≈ 770 B（JSON 明文），落在 ~2 KB 预算内 ⇒ push 粒度不变（已定案 · 08-09c）。**

  | 组成 | 估算 |
  |------|------|
  | 标识与坐标（`Seq` / `InstanceId` / `EventId` / `BatchId` / `LocationId`） | ~150 B |
  | `SelectCost`（1–3 个 `ChangeElement`） | ~80 B |
  | `AppliedChange`（3–8 个 `ChangeElement`） | ~200 B |
  | 结算结果与冗余（`Outcome` / `LifeSpanAfter` / 敌人摘要） | ~100 B |
  | 未选项轻摘要 × 4 | ~240 B |
  | **合计** | **~770 B** |

  `pastEvent` 约占既有粗算的三分之一，整轮回 200 事件 ≈ 150 KB。**「按 `CharacterProfile` 做 diff」的既定粒度成立，不为快照体积新增任何机制。** 估算随「`CostKey` 的 element 清单」与「每批 eventOptions 数量」两项答定需复核（本次按 element 1–3 / 3–8 条、每批 5 项计）。
- **体积护栏 = 软上限告警（已定案 · 08-09c）。** 单个 `CharacterProfile` 的 `pastEvent` **条数 > 500 或序列化 > 512 KB** 时 `GD.PushWarning` 带 `characterId` 与实际值。理由：`PlayerProfile` 是**整聚合 pull** 的单位（启动时全量一次），失控增长首先伤的是**启动 pull**，而那条路径是**硬阻塞**的。**告警不改变行为**，只让异常在被玩家感知之前先被看到。
  - **明确否决：现阶段不做 `pastEvent` 的分页 / 冷热分离 / 归档到独立存档段。** 无证据需要，且会把「云端权威 · 整聚合 pull」这条语义重新打开。
  Source: `handoffs/2026-08-09c-past-event-trace-schema.md`。
- **push 负载信封携带** `contentVersion` / `appVersion` / `revision`，让后端**不解 Profile** 即可做版本维度的聚合与异常检测（见 `content-service.md` 的双 `contentVersion` 记录）。
- Source: `handoffs/2026-07-27-content-gating-offline-resilience-and-rng-persistence.md`。

### 断线降级（已定案）

**总原则：绝不回退存档点。** 回退会抹掉玩家已打完的战斗；「云端权威」解决的是**冲突**，不是**丢进度**。

| 通道 | 失败时行为 |
|------|-----------|
| **Push（上行存档）** | **不阻塞玩家。** 变更进本地待发队列（`user://cache/pending/`，原子写，跨启动保留），指数退避重试；UI 常驻「离线 · 待同步 N」指示 |
| **Pull（启动全量）** | **硬阻塞。** 强制在线下无权威档即不可玩；呈现「重试 / 退出」，**不提供本地缓存开局**（本地非权威，用它开局等于制造必然冲突） |
| **剧本请求** | **事务前置。** 剧本内容取得**之前**不施加任何成本、不推进 key point；取不到 → 该事件呈现「内容加载失败 · 重试」，**Profile 零变更**（见 `plot-manager.md`） |

- **缓冲上限（两个闸门，先到先触发）：** 未同步的**事件级存档点数 ≥ 3**，或**最早一条待发变更滞留 ≥ 180 秒**。
  - **口径 = 事件级存档点（已定案 · 08-06）。** 计的是**轮回开始 / 每个 AdventureEvent 结算后 / 篇章边界 / 轮回结束**这四类，**不含事件推进过程中的决策点存档**。理由：决策点密度约 **31 点 / 场战斗**，按旧口径一场战斗打到第三个决策点就会撞上闸门并弹出软阻塞模态，显然不是该闸门的本意。
  - **推论 ①：这把「存档点与 push 解耦」贯彻到了闸门口径上** —— **闸门计的是 push 单位，不是本地写入单位**。
  - **推论 ②：决策点存档回归本职** = 纯本地的崩溃恢复与防重掷手段，**不驱动 push、不计入闸门、不影响断线判定**；「决策点粒度决定 push 防抖压力」这句表述**作废**，粒度只影响本地写入频率（毫秒级、无流量顾虑）。
  - **推论 ③：两个闸门的语义齐了** —— 都以事件级 push 为单位；且软阻塞的触发时机（「不打断进行中的事件，在下一次 AdventureEvent 选择前弹模态」）与闸门口径**自动对齐**，不必各说一次。
  Source: `handoffs/2026-08-06-ch1-band-widening-cross-realm-crush-and-chapter-retry.md`。
- **超限 → 软阻塞：** 不打断进行中的事件（战斗打完），但在**下一次 AdventureEvent 选择前**弹模态「网络异常，正在重连」，提供「重试 / 退出到主界面」。退出时待发队列**保留本地**。
- **恢复后的合并语义：** `FlushPending()` 前**先 pull**；若云端 `revision` 已领先本地基线（多设备），**以云端为准丢弃本地缓冲**，并明确告知玩家「另一设备的进度已生效，本次离线进度未保留」。**不做静默合并、不引入字段级三路合并**——那会实质削弱 `ADR-0003`。
- **token 失效 / 被挤下线：** `RefreshToken()` 静默刷新；刷新失败**视同断线**走同一缓冲通道（不另开一套）；被后端**明确挤下线** → **硬阻塞**要求重登，重登后同样**先 pull 后 flush**。（见 `account-service.md`。）
- Source: 同上。

### `revision` 语义与幂等键（已定案 · 08-09）

- **`revision` = 后端分配的账号级单调递增整数（`long`）。** 分配权在**权威一侧**——「云端权威」这条决策本身就规定了它；让客户端分配版本号等于让非权威一侧决定「谁更新」，`ADR-0003` 会在这一点上被架空。
  - **排除服务端时间戳**：需要后端时钟单调且无回拨，同毫秒并发无法定序，相对整数计数器零收益。
  - **排除 ETag 字符串**：只支持判等，而既定语义要的是**有序比较**（「云端已领先」），且判等区分不出「落后」与「不可能态」。
  - **账号级一个 `revision`，不做 per-`CharacterProfile` 版本号**——同步单位是 PlayerProfile 聚合，`CharacterProfile` 粒度 diff 只是**传输优化**、不是同步单元；逐角色版本号会自然诱导出已被否决的字段级 / 角色级合并。
- **客户端只持一个基线值 `baseRevision`，它是传输层元数据，不进 Profile。** `baseRevision` = 最后一次被后端确认的版本号（pull 成功、或 push 被接受时后端返回的值），初值 `0` = 本设备尚无云端确认。依据是既定的「运行时 / 存档态只带 `Id` + 可变状态」：把它塞进 Profile 会**自指**（每次 push 都改动被 push 的东西），且会被卷进存档 schema 与迁移。
  - **落点 `user://cache/sync-envelope.json`**（`accountId` / `baseRevision` / `schemaVersion` / `lastAckAtUtc`），与待发队列 `user://cache/pending/` 同处、同样**原子写**、同样跨启动保留。
  - **连带：`revision` / `pushId` 的引入不 bump 存档 schema 版本、无迁移。**
  - **切账号即失效**：信封 `accountId` ≠ 当前登录账号 → **必需缺失**处置（`GD.PushError` + 定位上下文），丢弃信封、`baseRevision` 归 0、清空待发队列（跨账号的待发变更没有任何合法去处），**不是静默重置**。
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
- Source: `handoffs/2026-08-09-sync-revision-cas-and-immediate-flush-nonblocking.md`。

### `Immediate` flush 的失败语义（已定案 · 08-09）

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
- Source: 同上。

## 管理器

| manager | 职责 |
|---------|------|
| **ProfileSyncManager** | Pull / Push（5 秒防抖 + Immediate 直通）、`CharacterProfile` 粒度 diff、冲突以云端为准、断线缓冲队列与重试 |
| **LocalCacheManager** | `user://` 原子写（临时文件 → rename）、缓存读取与失效、待发队列 `user://cache/pending/` 的持久化 |
| **MigrationManager** | 存档 schema 版本校验、逐版迁移路径、无法迁移时的清晰拒绝 |

## API 面（契约）

> 总则与共享类型见 `systems/architecture.md`「API 契约总则」。本服务实现 `IBootstrappable`（启动链第三步：pull + 迁移）。Source: `handoffs/2026-07-27b-service-api-contracts.md`。

| 方法 | 形态 | 完整签名 | 失败语义 |
|------|------|----------|----------|
| 拉取 | B | `Task<OpResult<PlayerProfile>> PullProfileAsync(string accountId, CancellationToken ct)` | 业务失败 → `OpResult`；迁移失败 → `OpError.Migration`，`Detail` 带 `fromVersion → toVersion` |
| 上行 | B | `Task<OpResult> PushAsync(SavePointReason reason, PushPolicy policy, CancellationToken ct)` | 失败进本地待发队列，`OpError.Network`；**不阻塞玩家——`policy` 不改变这一条** |
| 补提交 | B | `Task<OpResult> FlushPendingAsync(CancellationToken ct)` | **内部先 pull**；`cloudRevision > baseRevision` → 丢弃本地缓冲 + `OpError.Conflict`；`cloudRevision < baseRevision`（不可能态）→ 同处置 + `GD.PushError` |
| 同步态 | A | `SyncState State { get; }` | — |
| 待发条数 | A | `int PendingCount { get; }` | — （既定的「离线 · 待同步 N」指示由 UI 收到 `SyncStateChanged` 后单点查询本属性，而非塞进负载——同 `CapabilitiesChanged` 的纪律） |
| 同步版本 | A | `long BaseRevision { get; }` | — **只读诊断用**（设置屏「同步版本 #N」）；不参与玩法判断、不进玩法路径 |

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
- **信封仍带** `contentVersion` / `appVersion` / `revision`。

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

### 存档 schema 版本（已定案）

- 本次新增 `rng`（见 `systems/character-profile/_index.md`）、`StartContentVersion`、`LastContentVersion`、**`activeCombat`（战斗中间态，可空；schema 见 `combat-service.md`）**、**`pastEvent` 的条目结构 `PastEventEntry`（08-09c；schema 见 `systems/adventure-event/common-properties.md`）** → **bump schema 版本**。当前无线上存档 ⇒ 空迁移。
- **`attemptIndex` 的删除不 bump schema 版本、无迁移**——它从未落存档（只是一个派生参数）。Source: `handoffs/2026-08-06d-combat-open-questions-mass-closure.md`。
- 当前无线上存档，故迁移为**空迁移**——**就在此刻**把 MigrationManager 的逐版迁移骨架立起来，这是最便宜的时机（等有了线上存档再补，成本高一个量级）。
- **增删 RNG 子流不 bump schema 版本**（子流清单是 `SeedManager` 内的常量，读档时按缺失 / 多余分别 warn + 初始化 / warn + 丢弃）。Source: 同上。

## 与其他服务的关系

- **上游：** `account-service` 提供 `accountId` 与 token；`profile-service.ProfileManager` 是内存态的唯一写入面，本服务只负责**持久化与传输**，不改字段语义。
- **触发方：** `life-cycle-service` 在状态机边界触发自动存档点；`game-progression` 在核心循环第 ⑤ 步触发。

## 决策(-> ADR)

- **强制在线 · 云端权威**（冲突以云端为准、本地仅缓存） → `decisions/ADR-0003-online-cloud-authority.md`（Accepted）。

## 待决问题

- **迁移失败的玩家侧表现。** 「清晰拒绝」在 UX 上是什么（提示重装？联系客服？回退到云端上一个可用版本？）。→ `ux/`。**与 `OpError.Conflict` 的告知不耦合**（后者已定，见「`revision` 语义与幂等键」）。
- **`pushId` 的后端记忆窗口与报文字段名。** 记忆多少个 / 保留多久属**后端侧**参数；字段名与序列化形态待后端协议表达形式（OpenAPI + JSON Schema vs 共享 C# DTO）定案。客户端侧语义已定。→ `backend-design-documents/open-questions.md`。

## 对应
提炼至：`.claude/knowledge/systems/sync-service.md`（引用层，待建）。
