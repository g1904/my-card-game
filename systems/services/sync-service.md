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
- **push 负载信封携带** `contentVersion` / `appVersion` / `revision`，让后端**不解 Profile** 即可做版本维度的聚合与异常检测（见 `content-service.md` 的双 `contentVersion` 记录）。
- Source: `handoffs/2026-07-27-content-gating-offline-resilience-and-rng-persistence.md`。

### 断线降级（已定案）

**总原则：绝不回退存档点。** 回退会抹掉玩家已打完的战斗；「云端权威」解决的是**冲突**，不是**丢进度**。

| 通道 | 失败时行为 |
|------|-----------|
| **Push（上行存档）** | **不阻塞玩家。** 变更进本地待发队列（`user://cache/pending/`，原子写，跨启动保留），指数退避重试；UI 常驻「离线 · 待同步 N」指示 |
| **Pull（启动全量）** | **硬阻塞。** 强制在线下无权威档即不可玩；呈现「重试 / 退出」，**不提供本地缓存开局**（本地非权威，用它开局等于制造必然冲突） |
| **剧本请求** | **事务前置。** 剧本内容取得**之前**不施加任何成本、不推进 key point；取不到 → 该事件呈现「内容加载失败 · 重试」，**Profile 零变更**（见 `plot-manager.md`） |

- **缓冲上限（两个闸门，先到先触发）：** 未同步的**自动存档点数 ≥ 3**，或**最早一条待发变更滞留 ≥ 180 秒**。
- **超限 → 软阻塞：** 不打断进行中的事件（战斗打完），但在**下一次 AdventureEvent 选择前**弹模态「网络异常，正在重连」，提供「重试 / 退出到主界面」。退出时待发队列**保留本地**。
- **恢复后的合并语义：** `FlushPending()` 前**先 pull**；若云端 `revision` 已领先本地基线（多设备），**以云端为准丢弃本地缓冲**，并明确告知玩家「另一设备的进度已生效，本次离线进度未保留」。**不做静默合并、不引入字段级三路合并**——那会实质削弱 `ADR-0003`。
- **token 失效 / 被挤下线：** `RefreshToken()` 静默刷新；刷新失败**视同断线**走同一缓冲通道（不另开一套）；被后端**明确挤下线** → **硬阻塞**要求重登，重登后同样**先 pull 后 flush**。（见 `account-service.md`。）
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
| 上行 | B | `Task<OpResult> PushAsync(SavePointReason reason, PushPolicy policy, CancellationToken ct)` | 失败进本地待发队列，`OpError.Network`；**不阻塞玩家** |
| 补提交 | B | `Task<OpResult> FlushPendingAsync(CancellationToken ct)` | **内部先 pull**；云端 `revision` 领先则丢弃本地缓冲并回 `OpError.Conflict` |
| 同步态 | A | `SyncState State { get; }` | — |
| 待发条数 | A | `int PendingCount { get; }` | — （既定的「离线 · 待同步 N」指示由 UI 收到 `SyncStateChanged` 后单点查询本属性，而非塞进负载——同 `CapabilitiesChanged` 的纪律） |

```csharp
public enum SavePointReason { CycleStarted, EventResolved, ChapterBoundary, CycleEnded, MetaChanged }
public enum PushPolicy      { Debounced, Immediate }
public enum SyncState       { Idle, Syncing, Buffered, Offline, Failed }
```

三点推演：

- **`PushAsync` 不接收 profile 参数。** profile 的内存权威在 profile-service，本服务只负责**持久化与传输**；让调用方递一份 profile 进来等于把「谁是权威」这件事再打开一次。本服务内部经 `ProfileService.Instance.Snapshot` 取快照，做 `CharacterProfile` 粒度 diff。
- **`reason` 保留**，它同时驱动日志、重试策略与合并窗口；`policy` 决定是否受 5 秒防抖约束（`Immediate` 直通）。
- **信封仍带** `contentVersion` / `appVersion` / `revision`。

**后端接口（总则 7）：** 本服务持有 `IProfileBackend`（`PullAsync` / `PushAsync`），两份实现 `HttpProfileBackend` / `OfflineProfileBackend`（内存回显）。

**事件面：** `SyncStateChanged(SyncState State, OpError LastError)` —— 一个负载覆盖同步成功 / 失败、进入断线缓冲态、缓冲超限（软阻塞）、离线进度被云端覆盖（`State = Failed` + `LastError = Conflict`）；UI 据此渲染「同步中 / 离线 · 待同步 N」指示与模态阻塞。迁移发生 / 拒绝走 `OpError.Migration`。

### 存档 schema 版本（已定案）

- 本次新增 `rng`（见 `systems/character-profile/_index.md`）、`StartContentVersion`、`LastContentVersion` → **bump schema 版本**。
- 当前无线上存档，故迁移为**空迁移**——**就在此刻**把 MigrationManager 的逐版迁移骨架立起来，这是最便宜的时机（等有了线上存档再补，成本高一个量级）。
- **增删 RNG 子流不 bump schema 版本**（子流清单是 `SeedManager` 内的常量，读档时按缺失 / 多余分别 warn + 初始化 / warn + 丢弃）。Source: 同上。

## 与其他服务的关系

- **上游：** `account-service` 提供 `accountId` 与 token；`profile-service.ProfileManager` 是内存态的唯一写入面，本服务只负责**持久化与传输**，不改字段语义。
- **触发方：** `life-cycle-service` 在状态机边界触发自动存档点；`game-progression` 在核心循环第 ⑤ 步触发。

## 决策(-> ADR)

- **强制在线 · 云端权威**（冲突以云端为准、本地仅缓存） → `decisions/ADR-0003-online-cloud-authority.md`（Accepted）。

## 待决问题

- **迁移失败的玩家侧表现。** 「清晰拒绝」在 UX 上是什么（提示重装？联系客服？回退到云端上一个可用版本？）。→ `ux/`。
- **`revision` 的产生方与语义。** 断线合并语义依赖比较云端与本地基线的 `revision`（单调递增计数？服务端时间戳？ETag？），由谁分配、客户端如何持有基线值，未定——这是**客户端 ↔ 后端协议契约**问题，应同步登记进 `backend-design-documents/open-questions.md`。Source: `handoffs/2026-07-27-content-gating-offline-resilience-and-rng-persistence.md`。
- **软阻塞与「进入战斗前强制 flush」的交互。** 进入战斗前是 Immediate flush 点；若此时已处于断线缓冲超限态，玩家是被挡在战斗外（软阻塞发生在 AdventureEvent 选择前，战斗尚未开始）还是可以进入？两条规则的先后顺序未明写。Source: 同上。

## 对应
提炼至：`.claude/knowledge/systems/sync-service.md`（引用层，待建）。
