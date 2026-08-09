# `revision` 语义（服务端 CAS + 幂等键）与「Immediate flush 永不阻塞玩家」

- id: 2026-08-09-sync-revision-cas-and-immediate-flush-nonblocking
- date: 2026-08-09
- topic: systems/services/sync-service · systems/architecture（总则 7）· systems/services/account-service · systems/services/combat-service · systems/services/life-cycle-service · ux/screen-flow · ux/combat-ux
- status: distilled
- distilled-to: systems/services/sync-service.md, systems/architecture.md, systems/services/account-service.md, systems/services/combat-service.md, systems/services/life-cycle-service.md, ux/screen-flow.md, ux/combat-ux.md, backend-design-documents/open-questions.md

## Intent（distilled）

**一行摘要：** `revision` = **后端分配的账号级单调递增 `long`**，客户端只持一个**传输层**基线值 `baseRevision`（落 `user://cache/sync-envelope.json`，不进存档），上行走 **CAS 三分支** + **幂等键 `pushId`**；而 **`Immediate` flush 是一次「尝试」、软阻塞闸门是一个「状态」**——`Immediate` 声明的是「不等防抖」，不是「必须成功」，因此**进入战斗前的 flush 失败绝不挡玩家**。

两个问题合并处理，因为它们咬在同一处：**「一次 push 尝试」与「同步落后到什么程度算超限」是两层东西**。分层之后，第二个问题的答案由既有定案自动推出。

### ① `revision` 的形态与分配权

- **分配权在后端，形态 = 账号级单调递增整数（`long`）。** 「云端权威」（`ADR-0003`）本身就规定了版本号的分配权必须落在权威一侧——让客户端分配 `revision` 等于让非权威一侧决定「谁更新」。
- **排除服务端时间戳**：要比较的是「谁的写入更后」，时间戳需要后端时钟单调且无回拨，同毫秒并发无法定序，相对整数计数器零收益。
- **排除 ETag 字符串**：ETag 只支持**判等**，而既定语义（「云端 `revision` 已领先本地基线」）要的是**有序比较**；判等区分不出「落后」与「不可能态」。
- **账号级一个 `revision`，不做 per-`CharacterProfile` 版本号。** 同步单位是 PlayerProfile 聚合，`CharacterProfile` 粒度 diff 只是**传输优化**、不是同步单元。给每个角色各一个版本号会自然诱导出「这个角色以本地为准、那个以云端为准」的字段级合并——已被明确否决的那件事。

### ② 客户端只持 `baseRevision`，且它是传输层元数据

- **`baseRevision` = 最后一次被后端确认的版本号**（pull 成功、或 push 被接受时后端返回的值）；初值 `0` = 本设备尚无任何云端确认。
- **不落 `PlayerProfile` / `CharacterProfile`。** 依据是既定的「运行时 / 存档态只带 `Id` + 可变状态」与三层切分。塞进 Profile 有两个具体代价：每次 push 都改动被 push 的东西（自指），且它会被卷进存档 schema 版本与迁移。
- **落点 `user://cache/sync-envelope.json`**，与既定待发队列 `user://cache/pending/` 同处、同样**原子写**（临时文件 → rename）、同样跨启动保留。
- **连带（重要）：本方案不 bump 存档 schema 版本、无迁移。** 这是把 `revision` 排除在 Profile 之外换来的直接收益。
- **切账号即失效**：信封 `accountId` 与当前登录账号不匹配 → 丢弃信封、`baseRevision` 归 0、清空待发队列（跨账号的待发变更没有任何合法去处）。这是**必需缺失 → `PushError` + 定位上下文**的检查点，不是静默重置。

### ③ 上行 = 乐观并发（CAS），三分支闭合

push 携带 `baseRevision` 作为前置条件，后端比对当前 `cloudRevision`：

| 后端判定 | 语义 | 后端行为 | 客户端处置 |
|----------|------|----------|-----------|
| `baseRevision == cloudRevision` | 正常 | 接受写入，`cloudRevision += 1`，回 `newRevision` | 信封 `baseRevision = newRevision`，从待发队列移除该批 |
| `baseRevision < cloudRevision` | **多设备已写入** | 拒绝，回当前 `cloudRevision` | 既定语义：以云端为准丢弃本地缓冲，`OpError.Conflict`，明确告知玩家 |
| `baseRevision > cloudRevision` | **不可能态**（信封被改 / 后端回滚） | 拒绝，回当前 `cloudRevision` | 同 Conflict 处置 + `GD.PushError` 上报一次；**不试图自愈** |

第三行单列而不并进第二行：**处置相同**（云端权威下答案唯一），但**它是一个应当被观测到的异常**——静默按第二行处理会让「客户端 `user://` 被改写」这类事件永远看不见。与 content-service 的「验签失败 → 拒绝 + 上报一次」同构。

### ④ 幂等键 `pushId`：本方案最承重的一条

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

这不是理论风险：移动网络下「请求已达、响应丢失」是常态，而 `Immediate` flush 点里有一个正是**应用失焦 / 挂起**——那恰是响应最容易收不到的时刻。

- **每个上行批次携带客户端生成的幂等键 `pushId`（GUID），重试时保持不变。** 后端记录最近若干个已接受的 `pushId`，重复到达时**不再 +1**，直接回上次的结果（`newRevision` + `Deduplicated = true`）；客户端据此把信封推进到正确的 `baseRevision`，进度不丢。
- `pushId` 在**该批变更被组装时**生成一次，写进待发队列条目并随之持久化——**跨启动重试必须用同一个 `pushId`**，否则幂等键失去意义。
- 「后端记忆多少个 / 保留多久」属后端侧参数，本库不定。

### ⑤ 软阻塞 × 进入战斗前 flush：**不挡**

四条既有定案各自独立地指向同一个答案：

1. **既定的断线降级表已经答了。** Push 通道的既定行为是「不阻塞玩家，变更进待发队列，指数退避重试」。这条行为**没有按 `PushPolicy` 分叉**——两者的差别在是否等 5 秒防抖窗口，从来不在失败处置。
2. **软阻塞的定案措辞排除了它。** 原文是「不打断进行中的事件（**战斗打完**）」。玩家选中 Combat 事件的那一刻事件**已经开始**（`TryApply(SelectCost)` 已施加、终态判定 ① 已过、`eventStart` 已进入，`RunCombatAsync` 是该事件的内部流程）。把玩家挡在战斗外**就是**打断进行中的事件。
3. **`SelectCost` 不回滚这条纪律把代价说死了。** 玩家已付掉寿元 / 灵玉，此时挡住他 = 付了成本却拿不到事件——这比丢一次同步严重得多，且它正是「绝不回退存档点」所要保护的那类损害的等价物。
4. **D0 不参与闸门判定已是定案。** 「战斗内 D0–D5 不参与软阻塞判定」，而 D0 **就是**「进入战斗前」这个 flush 点。同一个点不能一边被排除在计数外、一边又能独立触发模态。

**核心表述（建议明写进 sync-service）：** **flush 是一次「尝试」，闸门是一个「状态」。** `Immediate` 只声明「这一批不等防抖窗口，立刻发」，不声明「发不出去就停下」。它对软阻塞的**唯一**影响是：成功则清空闸门，失败则闸门计数**不变**（战斗内的存档点本就不计入）。阻塞与否始终只由闸门在**既定时机**判定——下一次 AdventureEvent 选择前。

由此原问题的两种情形各自闭合，**都不需要新机制**：

| 时刻 | 闸门状态 | 结果 |
|------|---------|------|
| **事件选择前**已超限 | 触发 | 模态在**那时**就弹了（既定时机）。重试成功 → 闸门清空 → 正常进入战斗；或退出到主界面。**走不到「进入战斗前」这一步。** |
| 事件选择前未超限，**选中 Combat 后**才断网 | 未触发 | 进战斗前的 `Immediate` flush 失败 → 变更进待发队列 → **照常进入战斗** |

**三条连带推论：**

- **战斗结束后闸门自然对齐。** 事件结算是事件级存档点，给闸门 +1；若因此达到 3，模态在下一次事件选择前弹出——正是既定时机。「口径自动对齐」这条既有推论在战斗路径上同样成立。
- **滞留计时不因战斗进行而暂停。** 一场战斗常超过 180 秒；「进战斗前 push 失败 → 打 6 分钟 → 战斗结束时最早一条已滞留 360 秒」会在下一次事件选择前触发闸门。**这是正确行为**——玩家确实已经离线 6 分钟了。
- **「进入战斗前」这个 flush 点的意图**不是 flush D0 自己那点 diff（D0 本就不计闸门），而是**趁着即将进入一段长时间无事件级存档点的区间，尽力把队列里已有的事件级变更送出去**。这解释了它为什么是 `Immediate`——也正因为目的是「尽力」，失败就更不该有阻塞力。同理适用于**应用失焦 / 挂起**那个点（且应用都不在前台，也无处弹模态）。
- **唯一不受本条影响的是既定的两处硬阻塞**：启动 pull 失败、被后端明确挤下线。它们与 push 通道无关。

### ⑥ UX 呈现（两项取向已签核 · 2026-08-09）

- **进入战斗前 flush 失败 → 不加任何额外提示**，仅沿用既定的常驻「离线 · 待同步 N」指示。断线期间**每一场**战斗入口都会命中这条路径，在此弹 toast 等于把一次性的网络状态变成逐场重复的打扰，且时机恰是玩家最专注处。与「玩家主动退出取静默退出，不做二次确认弹窗」同一条手感纪律。**前提：该常驻指示在战斗屏内也必须可见**——若战斗屏隐藏了它，静默就变成了失联。
- **`BaseRevision` 在设置屏暴露为只读一行「同步版本 #1337」**（`0` 显示为「尚未同步」）。强制在线 + 云端权威下，线上问题几乎都是「这台设备停在哪个版本」；让玩家与客服**对上同一个数字**的成本近乎为零，而替代方案（导出日志）在移动端基本不可行。**纪律：它是诊断展示，不是玩法数据**——只在设置屏读一次，不进任何玩法路径、不参与判断。这正是「服务门面 `PullProfileAsync` 不外泄 `Revision`」那条纪律的另一面：**暴露给人看可以，暴露给代码判断不行。**

### ⑦ 落地面（客户端调用形状）

```csharp
// 传输层元数据：不进 PlayerProfile、不进存档 schema、不参与迁移
internal sealed record SyncEnvelope(
    string   AccountId,
    long     BaseRevision,        // 最后一次被后端确认的 revision；0 = 尚无云端确认
    int      SchemaVersion,
    DateTime LastAckAtUtc);

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

internal interface IProfileBackend   // 总则 7 的窄接口：两个返回类型带上 revision
{
    Task<OpResult<ProfileSnapshot>> PullAsync(string accountId, CancellationToken ct);
    Task<OpResult<PushAck>>         PushAsync(ProfilePayload p, CancellationToken ct);
}
```

- **服务门面签名不变**（`PullProfileAsync` / `PushAsync` / `FlushPendingAsync`），只新增只读诊断属性 `long BaseRevision { get; }`。`Revision` 是本服务的内务，profile-service / game-progression 不该看见它——泄漏出去就会有人拿它做判断，而「谁是权威」不该被第二处代码回答。
- **`PushPolicy` 不改枚举，只明写语义**：`Debounced` 进 5 秒合并窗口，`Immediate` 跳过窗口立刻发；**两者在失败处置上完全一致**（进待发队列 + 指数退避 + 不阻塞玩家）。

**校验点（对齐 `null-check-rules.md`）：**

| 检查点 | 缺失语义 | 处置 |
|--------|---------|------|
| 读 `sync-envelope.json` 失败 / 不存在 | 可选 | `GD.PushWarning` + `baseRevision = 0`，随后一次 pull 补齐 |
| 信封 `accountId` ≠ 当前登录账号 | 必需 | `GD.PushError($"[Sync-LoadEnvelope] account mismatch, envelope={a}, session={b}")` + 丢弃信封与待发队列 |
| 待发队列条目缺 `pushId` | 必需（旧格式 / 损坏） | `PushError` + 丢弃该条目（无幂等键的重试比不重试更危险） |
| `baseRevision > cloudRevision` | 必需（不可能态） | `PushError` + 按 Conflict 处置，以云端为准 |

## 与既有决策的张力

**无实质冲突；两处对既定文本的修订，性质均为「补全」而非「松动」。**

1. **总则 7 的 `IProfileBackend` 两个签名改返回类型。** 既定文本没有为 `revision` 留返回位置——不是因为决定不要，而是因为 `revision` 的形态当时正是待答项。总则 7 的**原则**（四个窄接口、两份实现、`OpResult` 语义、本库只定调用形状）不动。
2. **`pushId` 是新概念且落在跨端协议契约上。** 遵守总则 7 的边界：本库定的是「客户端每批携带一个稳定的幂等键、后端据它去重」这一**语义**，报文字段名与后端记忆窗口不在本库定稿。

## 已否决的备选

- `revision` 用服务端时间戳 / ETag 字符串 / 客户端分配 / per-`CharacterProfile` 各一个 / 落进 `PlayerProfile` 字段——理由见上文 ①②。
- 只靠 `revision` 不引入幂等键——会在「请求已达、响应丢失」这一移动网络常态下丢玩家进度。
- 进入战斗前 flush 失败即挡住玩家（软阻塞前移到战斗入口）——与四处既有定案冲突。
- 进入战斗前 flush 失败 → 回滚 `SelectCost` 并退回选择界面——与「`SelectCost` 不回滚」直接冲突，且会开出「不满意就断网重选」的窗口。
- 进战斗前弹一次非阻塞 toast / 完全静默 / `BaseRevision` 只写日志不进 UI——见 ⑥。

## Open questions

- **`pushId` 的后端记忆窗口**（记忆多少个 / 保留多久）属后端侧，本库不定。→ `backend-design-documents/open-questions.md`。
- **报文字段名与序列化形态**待后端协议表达形式（OpenAPI + JSON Schema vs 共享 C# DTO）定案后才能定稿；本方案的**语义**不依赖它。
- **多设备并发登录的云端裁决规则**（后登录挤下线？拒绝？）仍属后端待答。CAS 三分支在两种裁决下都成立，故不阻塞本方案；但「玩家实际多久会撞上一次 Conflict」取决于它。
- 与 `sync-service.md` 另一条待答「**迁移失败的玩家侧表现**」相邻但**不耦合**——本方案只涉及 `OpError.Conflict` 的告知，不涉及 `OpError.Migration` 的 UX。该条**保留**在待答清单。

## Notes / triage

来源：`inbox/archive/solution-draft-sync-revision-and-soft-block.md`（`/provide-solution-draft` 产出，2026-08-09 用户评审通过，两项 UX 取向按推荐项签核）。
移出待答：`open-questions/05-service-contracts.md` 的 `revision` 与「软阻塞 × 进战斗前 flush」两条 → `answer-logs/log-sync-revision-and-soft-block.md`。
