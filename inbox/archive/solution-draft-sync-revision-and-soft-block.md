---
type: solution-draft
date: 2026-08-09
question: 云端 `revision` 由谁分配、是什么形态、客户端如何持有基线值；以及「缓冲超限软阻塞」与「进入战斗前 Immediate flush」两条规则的先后顺序。
source: open-questions/05-service-contracts.md → 第 6、7 条（均 → systems/services/sync-service.md#待决问题）
targets:
  - systems/services/sync-service.md
  - systems/architecture.md（总则 7 的 IProfileBackend 签名）
  - systems/services/account-service.md（重登后「先 pull 后 flush」一段）
  - systems/services/combat-service.md（决策点清单 D0 一行注）
  - systems/services/life-cycle-service.md（自动存档点一段）
  - ux/screen-flow.md（常驻同步指示的口径 + 设置页「同步版本」）
  - ux/combat-ux.md（进入战斗前不额外提示）
  - backend-design-documents/open-questions.md（跨端契约的后端一侧登记）
status: distilled
reviewed-date: 2026-08-09
distilled-to: handoffs/2026-08-09-sync-revision-cas-and-immediate-flush-nonblocking.md
---

# 方案草稿 — `revision` 语义 与 软阻塞 × 进入战斗前 flush

> 两个问题合在一份草稿里，因为它们咬在同一处：**「一次 push 尝试」与「同步落后到什么程度算超限」是两层东西**。`revision` 定义了前者的成败判据，闸门定义了后者的状态。把这一层分开之后，第二个问题的答案几乎是自动的。
>
> **评审状态（2026-08-09）：已评审通过，无待决取向项。** 原「仍需用户决定」的两项 UX 取向已按推荐项签核，见「③ UX 呈现」小节。本草稿可直接交 `/analyze-new-ideas` 提炼。

## 问题

**① `revision` 的产生方与语义。** 断线恢复的合并语义已定案——`FlushPendingAsync` 前先 pull，「若云端 `revision` 已领先本地基线（多设备），以云端为准丢弃本地缓冲」。但 `revision` 本身悬着：单调递增计数？服务端时间戳？ETag？由谁分配？客户端把「本地基线值」持在哪里、跨启动怎么保留？没有它，`FlushPendingAsync` 的失败语义（`OpError.Conflict`）无法实现，`push` 信封里那个 `revision` 字段也填不出东西。属**客户端 ↔ 后端协议契约**。

**② 软阻塞与「进入战斗前强制 flush」的交互。** 「进入战斗前」是既定的 `Immediate` flush 点（= 战斗决策点 D0）。若此刻已处于断线缓冲超限态，玩家是被挡在战斗外，还是可以进入？软阻塞的既定触发时机是「下一次 AdventureEvent 选择前」，而战斗此时尚未开始——两条规则的先后顺序从未明写。

## 约束（来自既有设计）

| 约束 | 来源 |
|------|------|
| **云端权威**：本地 ↔ 云端冲突一律以云端为准；本地 `user://` 仅缓存 | `ADR-0003`（Accepted） |
| **不做静默合并、不引入字段级三路合并**——那会实质削弱 ADR-0003 | `sync-service.md`「断线降级」 |
| **绝不回退存档点。** 「云端权威」解决的是冲突，不是丢进度 | 同上（总原则） |
| **Push 失败不阻塞玩家**：变更进 `user://cache/pending/`，指数退避重试 | 同上（断线降级表） |
| 同步单位 = PlayerProfile 聚合；**增量 push 粒度 = 按 `CharacterProfile` diff** | `sync-service.md` |
| push 信封携带 `contentVersion` / `appVersion` / `revision`，让后端**不解 Profile** 即可聚合与异常检测 | 同上 + `content-service.md` |
| **闸门口径 = 事件级存档点**（轮回开始 / 事件结算后 / 篇章边界 / 轮回结束）；≥ 3 或最早一条滞留 ≥ 180 秒 | `sync-service.md`（08-06 定案） |
| **战斗内 D0–D5 照常写本地、照常防抖 push，但不参与软阻塞判定** | `combat-service.md:172` |
| 软阻塞**不打断进行中的事件**（战斗打完），模态弹在下一次 AdventureEvent 选择前 | `sync-service.md` + `life-cycle-service.md` 取消语义表 |
| `SelectCost` 一经施加即成事实，**不回滚** | `combat-service.md` / `life-cycle-service.md` |
| 总则 7：四个边界服务各持一个窄后端接口；本库只定**客户端的调用形状**，不定 HTTP 路径 / 报文字段 | `architecture.md` |
| 总则 2：业务失败 = 预期内的拒绝 → 返回 `OpResult`，绝不抛 | 同上 |

---

## 建议方案 ①：`revision`

### 1-1 形态 = 服务端分配的账号级单调递增整数（`long`）

`[既有推演]` + `[通行做法]`

- **分配权在后端。** 「云端权威」这条决策本身就规定了版本号的分配权必须落在权威一侧——让客户端分配 `revision`，等于让非权威一侧决定「谁更新」，`ADR-0003` 会在这一点上被架空。这一条**不建议留作选项**。
- **排除服务端时间戳**：移动端多设备场景下要比较的是「谁的写入更后」，时间戳需要后端时钟单调且无回拨，且同毫秒并发无法定序；它相对整数计数器没有任何收益。
- **排除 ETag 字符串**：ETag 只支持**判等**，而既定语义要的是**有序比较**（「云端 `revision` 已领先本地基线」）。判等能实现「拒绝冲突写入」，但实现不了「区分落后 vs 不可能态」。
- **账号级一个 `revision`，不做 per-`CharacterProfile` 版本号。** `[既有推演]`：同步单位是 PlayerProfile 聚合，`CharacterProfile` 粒度 diff 只是**传输优化**，不是同步单元。给每个角色各一个 `revision` 会自然诱导出「这个角色以本地为准、那个以云端为准」的**字段级合并**——已被明确否决的那件事。

### 1-2 客户端持有 `baseRevision`：传输层元数据，不进 Profile

`[既有推演]`

- **`baseRevision` = 最后一次被后端确认的版本号**（pull 成功、或 push 被接受时后端返回的值）。初值 `0` = 本设备尚无任何云端确认。
- **它不落 `PlayerProfile` / `CharacterProfile`。** 依据是既定的「运行时 / 存档态只带 `Id` + 可变状态」与三层切分——`revision` 不是档案内容，是**传输层元数据**。把它塞进 Profile 会有两个具体代价：每次 push 都改动 Profile 本身（自指），且它会被卷进存档 schema 版本与迁移。
  - **连带（重要）：本方案不 bump 存档 schema 版本、无迁移。**
- **落点建议：`user://cache/sync-envelope.json`**，与既定的待发队列 `user://cache/pending/` 同处、同样**原子写**（临时文件 → rename）、同样跨启动保留。

```jsonc
// user://cache/sync-envelope.json —— 传输层元数据，不是存档
{
  "accountId":     "acc-1042",
  "baseRevision":  1337,        // 最后一次被后端确认的 revision；0 = 尚无云端确认
  "schemaVersion": 3,
  "lastAckAtUtc":  "2026-08-09T04:12:07Z"
}
```

- **切账号即失效**：`accountId` 不匹配 → 丢弃信封、`baseRevision` 归 0、清空待发队列（跨账号的待发变更没有任何合法去处）。这是一处**必需缺失 → `PushError` + 定位上下文**的检查点，不是静默重置。

### 1-3 上行 = 乐观并发（CAS），三分支闭合

`[通行做法]`（optimistic concurrency control / compare-and-set，是有权威副本的同步系统的标准解法）

push 请求携带 `baseRevision` 作为前置条件，后端比对：

| 后端判定 | 语义 | 后端行为 | 客户端处置 |
|----------|------|----------|-----------|
| `baseRevision == cloudRevision` | 正常 | 接受写入，`cloudRevision += 1`，回 `newRevision` | 更新信封 `baseRevision = newRevision`，从待发队列移除该批 |
| `baseRevision < cloudRevision` | **多设备已写入** | 拒绝，回当前 `cloudRevision` | **既定语义**：以云端为准丢弃本地缓冲，`OpError.Conflict`，明确告知玩家 |
| `baseRevision > cloudRevision` | **不可能态**（客户端信封被改 / 后端回滚） | 拒绝，回当前 `cloudRevision` | **同 Conflict 处置**（以云端为准）+ `GD.PushError` 上报一次；不试图自愈 |

第三行值得单列而不是并进第二行：它们的**处置相同**（云端权威下答案唯一），但**它是一个应当被观测到的异常**，静默按第二行处理会让「客户端 `user://` 被改写」这类事件永远看不见。与 content-service 的「验签失败 → 拒绝 + 上报一次」同构。

### 1-4 幂等键 `pushId`：本方案里最承重的一条

`[通行做法]` + `[既有推演]`

**单靠单调 `revision` 会在一个真实场景下丢玩家进度**，而「绝不回退存档点」是本服务的总原则：

```
客户端 push(baseRevision=100) ──▶ 后端接受，写入，cloudRevision=101
                              ◀── 响应在回程丢包 / 客户端超时
客户端：未收到 ack ⇒ baseRevision 仍是 100，该批留在待发队列
客户端重试 push(baseRevision=100) ──▶ 后端：100 < 101 ⇒ 判为 Conflict
                                  ◀── 客户端「以云端为准丢弃本地缓冲」
结果：玩家看到「另一设备的进度已生效」——而根本没有另一台设备，
      被丢弃的正是他刚打完的那场战斗。
```

这不是理论风险：移动网络下「请求已达、响应丢失」是常态，而 `Immediate` flush 点里有一个是**应用失焦 / 挂起**——那正是响应最容易收不到的时刻。

**建议：每个上行批次携带一个客户端生成的幂等键 `pushId`（GUID），重试时保持不变。** 后端记录最近若干个已接受的 `pushId`，重复到达时**不再 +1**，直接回上次的结果（`newRevision` 与 `Deduplicated = true`）。客户端据此把信封推进到正确的 `baseRevision`，进度不丢。

- `pushId` 在**该批变更被组装时**生成一次，写进待发队列条目并随之持久化——**跨启动重试必须用同一个 `pushId`**，否则幂等键失去意义。
- 「后端记忆多少个 / 保留多久」是后端侧参数，见「前置依赖」。

### 1-5 对客户端 API 面的影响

`revision` 必须能从后端**返回**给客户端，而当前 `IProfileBackend` 的两个签名都没有承载它的位置（`PushAsync` 返回裸 `OpResult`，`PullAsync` 返回 `OpResult<PlayerProfile>`）。建议按下节「具体形态」修订这两个签名，并给服务门面加一个只读诊断属性。

---

## 建议方案 ②：软阻塞 × 进入战斗前 flush

### 2-1 结论：**不挡。`Immediate` flush 的失败永不阻塞玩家。**

`[既有推演]`——三条既有定案各自独立地指向同一个答案：

1. **既定的断线降级表已经答了。** Push 通道的既定行为是「**不阻塞玩家**，变更进本地待发队列，指数退避重试」。这条行为没有按 `PushPolicy` 分叉——`Immediate` 与 `Debounced` 的差别在**是否等 5 秒防抖窗口**，从来不在**失败处置**。让 `Immediate` 的失败具备阻塞力，是给这条既定规则开一个未经决策的例外。
2. **软阻塞的定案措辞已经排除了它。** 原文是「不打断进行中的事件（**战斗打完**）」。而在核心循环里，玩家选中 Combat 事件的那一刻事件**已经开始**了——`TryApply(SelectCost)` 已施加、终态判定 ① 已过、`eventStart` 阶段已进入，`RunCombatAsync` 是该事件的内部流程。把玩家挡在战斗外**就是**打断进行中的事件，与既定措辞直接冲突。
3. **`SelectCost` 不回滚这条纪律把代价说死了。** 玩家已经付掉了寿元 / 灵玉，此时挡住他 = 付了成本却拿不到事件。**这比丢一次同步严重得多**，且它恰好是「绝不回退存档点」所要保护的那类损害的等价物（一个抹掉已打完的战斗，一个抹掉已付出的成本）。
4. **D0 不参与闸门判定已是定案。** `combat-service.md` 明写「战斗内 D0–D5 ⋯ 不参与软阻塞判定」。D0 **就是**「进入战斗前」这个 flush 点。既然 D0 的存档不加计数，它的 flush 失败自然也不该触发阻塞——否则同一个点一边被排除在计数外、一边又能独立触发模态。

### 2-2 两条规则不是先后关系，而是不同层

建议在 `sync-service.md` 明写这一句，它一次性消解这个待答项：

> **flush 是一次「尝试」，闸门是一个「状态」。** `Immediate` 只声明「这一批不等防抖窗口，立刻发」，不声明「发不出去就停下」。它对软阻塞的**唯一**影响是：成功则清空闸门（待发队列空、滞留计时归零），失败则闸门计数**不变**（战斗内的存档点本就不计入）。阻塞与否始终只由闸门在**既定时机**判定——下一次 AdventureEvent 选择前。

由此，原问题描述的两种情形各自闭合、**都不需要新机制**：

| 时刻 | 闸门状态 | 结果 |
|------|---------|------|
| **事件选择前**已超限 | 触发 | 模态在**那时**就弹了（既定时机）。玩家重试成功 → 闸门清空 → 正常进入战斗；或退出到主界面。**走不到「进入战斗前」这一步。** |
| 事件选择前未超限，**选中 Combat 后**才断网 | 未触发 | 进入战斗前的 `Immediate` flush 失败 → 变更进待发队列 → **照常进入战斗** |

### 2-3 三条连带推论（建议一并明写）

- **战斗结束后闸门自然对齐。** 一场战斗打完，事件结算是**事件级**存档点，给闸门 +1。若因此达到 3，模态在**下一次事件选择前**弹出——正是既定时机。既有的「口径自动对齐」这条推论在战斗路径上同样成立，不需要补规则。
- **滞留计时不因战斗进行而暂停。** 一场战斗常常超过 180 秒；「进战斗前 push 失败 → 打 6 分钟 → 战斗结束时最早一条已滞留 360 秒」会在下一次事件选择前触发闸门。**这是正确行为**，不是需要打补丁的边角：玩家确实已经离线 6 分钟了。
- **「进入战斗前」这个 flush 点的意图应当写清楚。** 它 flush 的主要不是 D0 自己那点 diff（D0 是决策点存档，本就不计闸门），而是**趁着即将进入一段长时间无事件级存档点的区间，尽力把队列里已有的事件级变更送出去**。这解释了它为什么是 `Immediate`——也正因为它的目的是「尽力」，失败就更不该有阻塞力。同理适用于**应用失焦 / 挂起**那个 flush 点（且应用都不在前台，也无处弹模态）。
- **唯一不受本条影响的是既定的两处硬阻塞**：启动 pull 失败、被后端明确挤下线。它们与 push 通道无关。

---

## 建议方案 ③：UX 呈现（两项取向已签核 · 2026-08-09）

### 3-1 进入战斗前 flush 失败 → **不加任何额外提示，仅沿用既定的常驻「离线 · 待同步 N」指示**

`[取向选择 · 已签核]`

- 断线期间**每一场**战斗的入口都会命中这条路径；在此处弹 toast 等于把一次性的网络状态变成**逐场重复的打扰**，且它出现的时机恰是玩家最专注的时刻。
- 与既有手感取向一致：「玩家主动退出取静默退出，不做二次确认弹窗——手感优先，不在最频繁的操作上加一次模态」（`life-cycle-service.md`）。进入战斗与退出同属最高频操作。
- 玩家的知情权由**既定的常驻指示**承担：`SyncStateChanged` → UI 单点查询 `PendingCount` → 渲染「离线 · 待同步 N」。**该指示在战斗屏内也必须可见**（这是本条成立的前提——若战斗屏隐藏了它，静默就变成了失联）。
- **边界**：真正需要打断玩家的情形仍由既定机制承担——缓冲超限的软阻塞模态（下一次事件选择前）与两处硬阻塞（启动 pull 失败、被挤下线）。本条只否决「在战斗入口新增一层提示」。

### 3-2 `BaseRevision` 在设置页暴露为「同步版本 #1337」

`[取向选择 · 已签核]`

- 落点：`Settings(设置)` 屏（`ux/screen-flow.md` 已列该屏，职责为「音量等常规系统设置」+ `GameSetting`）。**只读一行小字**，与版本号 / 账号 ID 同区。
- 取值：`SyncService.Instance.BaseRevision`（本方案新增的形态 A 只读属性）。`0` 时显示为「尚未同步」而非 `#0`。
- 理由：强制在线 + 云端权威的产品形态下，线上问题几乎都是「这台设备停在哪个版本」。让玩家和客服**对上同一个数字**的成本近乎为零，而替代方案（导出日志）在移动端基本不可行。
- **纪律**：它是**诊断展示**，不是玩法数据——ViewModel 只在设置屏读一次，不进任何玩法路径、不参与判断。这正是 1-5 中「服务门面 `PullProfileAsync` 不外泄 `Revision`」那条纪律的另一面：暴露给**人**看可以，暴露给**代码**判断不行。

---

## 具体形态（可 derive 的落地面）

### 共享类型（sync-service 内部，`src/Services/Sync/`）

```csharp
// 传输层元数据：不进 PlayerProfile、不进存档 schema、不参与迁移
internal sealed record SyncEnvelope(
    string   AccountId,
    long     BaseRevision,        // 最后一次被后端确认的 revision；0 = 尚无云端确认
    int      SchemaVersion,
    DateTime LastAckAtUtc);

// 上行负载（总则 7 的 IProfileBackend.PushAsync 参数，形状既定名为 ProfilePayload）
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

### 对既定签名的修订（总则 7 的窄接口 + 服务 API 面）

```csharp
internal interface IProfileBackend
{
    // 修订：返回类型带上 Revision —— 否则客户端无从得到基线值
    Task<OpResult<ProfileSnapshot>> PullAsync(string accountId, CancellationToken ct);
    Task<OpResult<PushAck>>         PushAsync(ProfilePayload p, CancellationToken ct);
}
```

| 方法 | 形态 | 完整签名 | 失败语义 |
|------|------|----------|----------|
| 拉取 | B | `Task<OpResult<PlayerProfile>> PullProfileAsync(string accountId, CancellationToken ct)` | **不变**（服务门面仍只回 Profile；`Revision` 由服务内部写入信封，不外泄给调用方——它不是玩法数据） |
| 上行 | B | `Task<OpResult> PushAsync(SavePointReason reason, PushPolicy policy, CancellationToken ct)` | **不变**。失败进待发队列，`OpError.Network`；**不阻塞玩家——`policy` 不改变这一条** |
| 补提交 | B | `Task<OpResult> FlushPendingAsync(CancellationToken ct)` | **不变**。内部先 pull；`cloudRevision > baseRevision` → 丢弃本地缓冲 + `OpError.Conflict`；`cloudRevision < baseRevision`（不可能态）→ 同处置 + `GD.PushError` |
| 同步态 | A | `SyncState State { get; }` | — |
| 待发条数 | A | `int PendingCount { get; }` | — |
| **同步版本（新增）** | A | `long BaseRevision { get; }` | — 只读诊断用；不参与玩法、不进 ViewModel 的玩法路径 |

- **`PullProfileAsync` 的服务门面签名刻意不变。** `Revision` 是本服务的内务，profile-service / game-progression 不该看见它——泄漏出去就会有人拿它做判断，而「谁是权威」这件事不该被第二处代码回答。

### `PushPolicy` 的语义补全（不改枚举，只明写）

```csharp
public enum PushPolicy { Debounced, Immediate }
// Debounced : 进 5 秒合并窗口
// Immediate : 跳过合并窗口，立刻发
// 两者在【失败处置】上完全一致：进待发队列 + 指数退避 + 不阻塞玩家。
// Immediate 声明的是「不等」，不是「必须成功」。
```

### 校验点（对齐 `null-check-rules.md` 四检查点）

| 检查点 | 缺失语义 | 处置 |
|--------|---------|------|
| 读 `sync-envelope.json` 失败 / 不存在 | **可选** | `GD.PushWarning` + `baseRevision = 0`，随后一次 pull 会补齐 |
| 信封 `accountId` ≠ 当前登录账号 | **必需** | `GD.PushError($"[Sync-LoadEnvelope] account mismatch, envelope={a}, session={b}")` + 丢弃信封与待发队列 |
| 待发队列条目缺 `pushId` | **必需**（旧格式 / 损坏） | `PushError` + 丢弃该条目（无幂等键的重试比不重试更危险） |
| `baseRevision > cloudRevision` | **必需**（不可能态） | `PushError` + 按 Conflict 处置，以云端为准 |

## 后果

- **不 bump 存档 schema 版本、无迁移**——`revision` / `pushId` 全部落在 `user://cache/` 的传输层元数据里，与 `PlayerProfile` 无关。这是把它排除在 Profile 之外换来的直接收益。
- `systems/services/sync-service.md`：「断线降级」需补 `revision` 三分支表与 `pushId`；「API 面」需补 `BaseRevision` 一行并修订 `IProfileBackend`；新增一小节「`Immediate` flush 的失败语义」。
- `systems/architecture.md` 总则 7 的 `IProfileBackend` 代码块需同步修订（两个返回类型）。
- `systems/services/account-service.md`「被挤下线 → 重登后先 pull 后 flush」一段获得确切实现：重登后的 pull 会带回新的 `cloudRevision` 并覆写信封，随后 flush 自然走 CAS 判定，不需要额外规则。
- `systems/services/combat-service.md` 决策点清单 D0 的 `push policy` 一格可加一句注：「flush 失败不阻塞进入战斗」。
- `systems/services/life-cycle-service.md` 自动存档点一段：`Immediate` 的语义补一句「不等防抖，但失败处置与 `Debounced` 相同」。
- `ux/screen-flow.md`：设置屏新增只读一行「同步版本 #N」；并明写常驻「离线 · 待同步 N」指示**在战斗屏内同样可见**（3-1 成立的前提）。
- `ux/combat-ux.md`：补一句「进入战斗前的同步失败不产生任何额外提示，由常驻指示承担告知」——与该文档已有的「退出不做二次确认，告知由别处承担」是同一条纪律的第二个实例。
- **后端侧新增两项契约要求**：账号级单调 `revision` 计数器 + CAS 语义；`pushId` 幂等窗口。建议同步登记进 `backend-design-documents/open-questions.md`「协议契约」与「存档同步 / 冲突」两节（该库已有「幂等键未定」一句，本方案给了客户端侧的形状，后端侧的窗口大小 / 保留时长仍待定）。

### 两个待答项的移出

本方案若被采纳，`open-questions/05-service-contracts.md` 的第 6、7 条与 `systems/services/sync-service.md#待决问题` 的对应两条**整体移出**，归档进 `answer-logs/`。**同分片剩余 8 条不受影响**；`sync-service.md` 的另一条待答「迁移失败的玩家侧表现」相邻但不耦合，**保留**。

## 备选方案（已考虑并否决）

- **`revision` 用服务端时间戳。** 否决：需要后端时钟单调且无回拨，同刻并发无法定序，相对整数计数器零收益。
- **`revision` 用 ETag 字符串。** 否决：只能判等，无法表达「云端已领先」这个既定语义所要求的有序比较，也无法把「不可能态」与「正常落后」区分开。
- **客户端分配 `revision`（如本地递增计数）。** 否决：与 `ADR-0003` 的「云端权威」直接冲突——版本号的分配权就是权威本身。
- **per-`CharacterProfile` 各持一个 `revision`。** 否决：会诱导出字段级 / 角色级三路合并，而这一条已被明确定案排除。
- **`revision` 落进 `PlayerProfile` 字段。** 否决：自指（每次 push 都改动被 push 的东西），且把传输层元数据卷进存档 schema 与迁移路径。
- **只靠 `revision` 不引入幂等键。** 否决：见 1-4，会在「请求已达、响应丢失」这一移动网络常态下**丢玩家进度**，违反「绝不回退存档点」。
- **进入战斗前 flush 失败即挡住玩家（软阻塞前移到战斗入口）。** 否决：见 2-1 四条，与四处既有定案冲突，且 `SelectCost` 已施加使代价不可接受。
- **进入战斗前 flush 失败 → 回滚 `SelectCost` 并退回选择界面。** 否决：与「`SelectCost` 不回滚，视同已结算」直接冲突，且会开出「不满意就断网重选」的窗口。

## 与既有决策的张力

**无实质冲突；有两处对既定文本的修订，性质均为「补全」而非「松动」。**

1. **总则 7 的 `IProfileBackend` 两个签名要改返回类型。** 既定文本写的是 `Task<OpResult<PlayerProfile>> PullAsync(...)` 与 `Task<OpResult> PushAsync(...)`。它们没有为 `revision` 留返回位置——不是因为决定不要，而是因为 `revision` 的形态当时正是这个待答项。本方案不动总则 7 的**原则**（四个窄接口、两份实现、`OpResult` 语义、本库只定调用形状），只补两个返回类型。
2. **`pushId` 是一个新概念，且它落在跨端协议契约上。** 总则 7 明写「本库只定客户端的调用形状，不定 HTTP 路径 / 报文字段」——本方案遵守这条边界：定的是「客户端每批携带一个稳定的幂等键、后端据它去重」这一**语义**，报文字段名与后端记忆窗口不在本库定稿。

## 前置依赖

- **后端技术栈与协议表达形式未定**（`backend-design-documents/open-questions.md`「协议契约」节：OpenAPI + JSON Schema，还是共享 C# DTO）。本方案的**语义**不依赖它，但报文字段名与序列化形态要等它才能定稿。
- **`pushId` 幂等窗口的具体参数**（后端记忆多少个 / 保留多久）属后端侧，本库不定。客户端侧只需保证：`pushId` 随待发队列条目持久化、跨启动重试不变。
- **多设备并发登录的云端裁决规则**（后端待答）。本方案的 CAS 三分支在「后登录挤下线」与「拒绝后登录」两种裁决下都成立，故**不阻塞本方案定稿**；但「玩家实际多久会撞上一次 Conflict」取决于它。
- 与 `sync-service.md` 另一个待答项「**迁移失败的玩家侧表现**」相邻但不耦合：本方案只涉及 `OpError.Conflict` 的告知，不涉及 `OpError.Migration` 的 UX。

## 仍需用户决定

**无。** 原列出的两项 UX 取向已于 2026-08-09 评审签核，**均取推荐项**，并已上升为方案的一部分（见「建议方案 ③」）：

| 取向项 | 裁定 | 被否决的备选 |
|--------|------|-------------|
| 进入战斗前 flush 失败的提示强度 | **仅沿用常驻「离线 · 待同步 N」指示，不加额外提示** | 进战斗前弹一次非阻塞 toast（断线期间逐场重复打扰，且时机撞在玩家最专注处）· 完全静默（与既定常驻指示矛盾） |
| `BaseRevision` 是否对玩家可见 | **设置屏显示只读一行「同步版本 #N」** | 只写日志不进 UI（移动端排障要玩家导出日志，基本不可行） |

两项均为呈现层取向，**不改动本方案的任何契约形状**——`BaseRevision` 属性本就在 1-5 的 API 面里，3-2 只是给它加了一个消费点。
