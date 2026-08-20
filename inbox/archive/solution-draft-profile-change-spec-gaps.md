---
type: solution-draft
date: 2026-08-18
question: 三处「有纪律、无通道」的缺口（`activeCombat` / RNG 子流状态 / `pastEvent` 追加）各自该走 `ProfileChangeSpec` 的哪一列，以及收口时只读投影 `Project(spec)` 的语义面（与 `Evaluate` 的复用、是否钳制 / 判定终态、视图生命周期）。
source: open-questions/05-service-contracts.md → 三条「有纪律、无通道」缺口；open-questions/02-event-options.md → 收口时的只读投影设施形态
targets: systems/services/profile-service.md · systems/services/life-cycle-service.md · systems/services/combat-service.md · systems/adventure-event/common-properties.md · systems/character-profile/_index.md · systems/architecture.md
status: distilled
reviewed: 2026-08-19 — 用户逐条裁决完毕（取向零剩余）；批量提炼时的合并 interview 另有 48 项裁决，全部取推荐项
distilled-to: handoffs/2026-08-19-profile-change-spec-gaps.md
---

# 方案 — `ProfileChangeSpec` 的三处载体缺口 + `Project(spec)` 的语义面

## 问题

四条问题**必须一起答**，因为它们在同一次收口事务里互相咬合：

1. **`activeCombat` 没有任何 `ProfileChangeSpec` 列可落。** `activeEvent` 已定走 `EventStateChanges`（整块绝对置值），形态完全相同的 `activeCombat` 至今来路不明——`systems/character-profile/_index.md` 的字段表第 17 行写「—（combat-service 回写）」，而 `combat-service.md` 同时明写「战斗内的一切写入经 ProfileManager」。两句话之间没有通道。
2. **`Rng` 块同样没有列。** 不变式「凡消耗了子流随机的提交，该子流 `State` / `DrawCount` 必须在同一次原子写内更新」已落（`life-cycle-service.md`），但它**暂由组装方自律兑现**——没有任何结构能让「忘了带」被检出。
3. **`pastEvent` 的追加同样没有列。** `profile-service.md` 明写「`pastEvent` 写入经 life-cycle-service 组装 → `ProfileManager`」，但七列里没有一列装得下 `PastEventEntry`；三份结算流程图都把「记入 pastEvent」画在收口那次 `TryApply` **之外**，与「一个事件的收口是一次事务、一个存档点」直接相抵。
4. **`Project(spec)` 的语义面未定。** 它是「收口是一次事务、一个存档点」与「新一批依更新后的历程重算」两条承重纪律并存的**唯一支点**，但它与 `Evaluate(spec)` 的复用关系、是否钳制 / 判定终态、视图生命周期都未定。

前三条形状相同（都是「补一条通道」），第四条决定这些通道**被施加时**的语义——`TryApply` / `Evaluate` / `Project` 三者是否共用同一段施加代码。分开答会给三条形状相同的问题推出三个互不一致的答案，正是 `systems/architecture.md` 的三级判据要防的东西。

## 约束（来自既有设计）

- **三级判据（`systems/architecture.md`「一个新的施加语义该落在哪里」）是本题的裁决工具**：① 分列 ⟸ 施加语义在**六个面**（要不要钳制 · 是否走 modifier pipeline · 失败是否阻断整批 · 是否幂等 · 有无量纲 · 键与载荷的形状）上与既有各列**根本不同**；② 加 `Op` ⟸ 语义同族、方向不同；③ 配表加列 ⟸ 该性质是 element 类型的属性。**任一既有列在六面上全部对齐 ⇒ 不分列。**
- **「列表数不进承重表述」**——分列不受「已经七列了」这类考量约束。
- **一个事件的收口是一次事务、一个存档点；事件内部的主动消费即时提交**（`adventure-event/common-properties.md`）。
- **全有或全无、单点提交**；截断只发生在「施加到 Profile 字段」那一刻，spec 与快照记未截断原值。
- **`CanAfford` 与 `TryApply` 共用 `Evaluate(spec)`**，正是为了防两条路径算出不同结果。
- **`AppliedChange` = 本次事件的最终账**，可直接重放；它**已经**不再与收口那一次 `TryApply` 的入参逐字段相等（既定代价）。
- **`Key == EventOption` 置空是明令非法**（`PushError`）——轮回进行中把当前批置空即让玩家无路可走。
- **服务依赖方向**：life-cycle-service / combat-service → profile-service，**反向不成立**（profile-service 不得读 SeedManager）。
- **施加侧写严、读档侧读宽**（既有不对称，`(Kind, Scope, Source)` 与 `PlotElements` 两处先例）。

---

## 建议方案

### 1 · `activeCombat` → 收进既有的 `EventStateChanges`，不另开列

`[既有推演]`

按三级判据 ① 逐面核对 `ActiveCombat` 与 `EventStateChanges` 的既有语义：

| 六面 | `EventStateChanges` | `ActiveCombat` 的写入 | 对齐 |
|---|---|---|---|
| 要不要钳制 | 不钳制 | 不钳制（结构块无取值域） | ✓ |
| 是否走 modifier pipeline | 恒不走 | 恒不走（一条法则若能改写战场 = 账号级内容改写轮回级定稿实例，与 `RerolledCount` 同款理由） | ✓ |
| 失败是否阻断整批 | 必需缺失 → 整批拒绝 | 同（悬空 `eventInstanceId` 写进 Profile 即坏档） | ✓ |
| 是否幂等 | 绝对置值 ⇒ 幂等 | 同 | ✓ |
| 有无量纲 | 无 | 无 | ✓ |
| 键与载荷的形状 | 固定键 → **整个结构块**（或置空） | 固定键 → 整个结构块（或置空） | ✓ |

**六面全部对齐 ⇒ 判据明文要求「不分列」。** 具体形态：

```csharp
public enum EventStateKey { ActiveEvent, EventOption, ActiveCombat }   // 追加一个成员

public readonly record struct EventStateAssignment(
    EventStateKey     Key,
    ActiveEventState? ActiveEvent,      // Key == ActiveEvent 时使用
    EventOptionSave?  EventOption,      // Key == EventOption 时使用
    ActiveCombat?     ActiveCombat);    // Key == ActiveCombat 时使用；其余格填 null
                                        // 全部为 null = 置空，仅 ActiveEvent / ActiveCombat 合法
```

- **列名不必改。** `combat-service.md` 与 `character-profile/_index.md` 都已把 `activeCombat` 定性为「**事件内的中间态**，寿命短于一次事件」——它本就在「事件态」的语义域内。**列名不是分列判据**；六面才是。
- **`ActiveCombat` 允许置空**（`eventEnd` 收口必须置空），与 `ActiveEvent` 同档；`EventOption` 仍不允许置空，该条不变式原样保留。
- **写入方 = combat-service**，在 D0–D5 每个决策点各组装一次 `TryApply`（与 `RngElements` 同批，见第 2 节）；**D6 并入 `eventEnd` 的那一次**（`ActiveCombat = null`），既定「D6 不单独落点」原样成立。
- **`ActiveCombat` 与 `ActiveEvent` 仍不合并**（既定：前者是战斗状态机中间态、后者是事件级中间态）。本方案让它们**共用一条写入通道**，不合并两个字段——共用通道正是「两个同形的中间态不该各长一套写入纪律」这条诉求的落点。
- **`CharacterProfile` 字段表第 17 行的写入通道列**由 `—（combat-service 回写）` 改为 `EventStateChanges`。

**新增失败语义（`ProfileManager` 入口）：**

| 情形 | 语义 | 处置 |
|---|---|---|
| `Key == ActiveCombat` 且值非空，但施加后 `activeEvent == null` | 必需缺失（组装缺陷） | `PushError` + 整批拒绝（战斗必然归属某个正在结算的事件） |
| `Key == ActiveCombat` 且值非空，但 `ActiveCombat.EventInstanceId != 施加后的 activeEvent.EventInstanceId` | 必需缺失 | `PushError` + 整批拒绝。它是 `character-profile/_index.md` 读档校验 ⑥ 的**施加侧对偶**，两侧同为拒绝 |
| 载荷格与 `Key` 不匹配 / 多格同时非空 | 必需缺失 | 既有行原样扩到三格 |
| 同批两条 `Key == ActiveCombat` | 必需缺失 | 既有行覆盖 |

> **代价明写：** 第二条把一条跨字段一致性校验放进了入口，与「`PlotElements` 的拓扑校验不在本入口、留给唯一组装方的 `#if DEBUG` 断言」略有张力。取入口的理由是**它在读档侧已经是 `PushError` 级**（校验 ⑥），两侧口径一致比分层纯度更值钱；且比对的两样东西都在同一次施加的可见范围内，不需要 ProfileManager 认识任何战斗规则。该分层纯度的替代形态（combat-service 侧 `#if DEBUG` 断言）**已在「用户裁决」⑤ 被否决**，定案取入口 `PushError`。

### 2 · RNG 子流状态 → 另开一列 `RngElements`

`[既有推演]` + `[取向选择]`（三个候选，推荐 B）

逐面核对，看有没有既有列在六面上全部对齐：

| 六面 | `RngStateAssignment`（本方案） | 最接近的既有列 |
|---|---|---|
| 要不要钳制 | 不钳制（u64 全域） | `EventStateChanges` ✓ · `PlotElements` ✓ |
| modifier pipeline | **恒不走**（一条法则若能改写随机流状态，比改写付费凭证更重——它能改写整条确定性链） | ✓ |
| 失败是否阻断整批 | 未知子流键 = 代码缺陷 → 整批拒绝 | ✓ |
| 是否幂等 | 绝对置值 upsert ⇒ 幂等 | ✓ |
| 有无量纲 | 无 | ✓ |
| **键与载荷的形状** | **按子流键（枚举）的 upsert，一次可带多条不同键**，载荷 = `(State, DrawCount)` 两个标量 | `EventStateChanges` ✗（固定键、每键至多一条、载荷是整个结构块）；`PlotElements` 形状同类但**键的取值空间与载荷字段集合完全不同**（内容 `Id`，须经 `ContentRegistry` 解析） |

**第六面不对齐 ⇒ 分列。** 具体形态：

```csharp
public IReadOnlyList<RngStateAssignment> RngElements { get; }   // ProfileChangeSpec 追加一列

public readonly record struct RngStateAssignment(   // 按子流键的绝对置值 upsert
    RngStream Stream,     // 键：Map | Combat | Shop | Reward（SeedManager 内的常量清单）
    ulong     State,      // 恢复权威字段
    int       DrawCount); // 诊断与迁移保险；本次提交之后的累计值
```

- **不配表。** `ResourceElements` / `StatusFields` 存在的理由是「逐 key 各不相同的取值域 / 终态 / 修正准入」；四条子流在这六个性质上**完全相同**（无取值域、不构成终态、恒不走 pipeline），配一张四行全同的表只会长出一处必须与 `RngStream` 同步增删的枚举镜像。**这正是三级判据 ③ 的反面**：该性质不是逐 key 不同的类型属性。
- **`Seed` 不进 spec。** `streamSeed = Hash64(CycleSeed, streamName)` 随时可重算，存档里存它**只为诊断与自校验**（既定）——把一个可重算的值放进 spec 等于让重放依赖一份冗余真值。
- **`RngElements` 在 `SelectCost` 内恒为空**，与 `AbilityElements` / `DeckElements` / `PlotElements` / `EventStateChanges` 同款、**独立成行**（既定：不要合并成「非 `Elements` 的列一律为空」的通则）。落为物化组装后的断言。
- **同批两条同 `Stream` → `PushError` + 整批拒绝**（绝对置值下两条同键 = 组装方自己也不知道最终该落哪一份，与 `EventStateChanges` 同款）。
- **`DrawCount` 回退（小于 profile 现值）→ `PushError` + 整批拒绝**：单调不减是「不许回滚 `State` 重掷」这条纪律的可机械校验形态，与 `RerolledCount` 的单调不减校验同构。

**不变式的机械保证形态**（这是本条真正要买的东西）：

```
SeedManager 侧（唯一持有四条子流的地方）：
  ① 每条子流记一个「自上次清账以来的消耗计数」pending[stream]
  ② 唯一组装路径 SeedManager.AttachRngState(spec) —— 把全部 pending != 0 的子流
     以当前 (State, DrawCount) 写进 spec.RngElements，并清账
  ③ #if DEBUG：任一 Stream(...) 取用前，若上一次 TryApply 之后仍有未清账的 pending
     → PushError 带 characterId + 子流名（纪律阶梯第 3 级：大声失败）
```

- **为什么不让 `TryApply` 自动捕获**（即 ProfileManager 提交时自己去问 SeedManager 要状态）：那要求 **profile-service 读 life-cycle-service**，与既定的服务依赖方向相反；且 spec 里没有 RNG 条目会让 `AppliedChange` 重放不出同一份 `State`，把一条「可直接重放的账」悄悄变成不完整的账。
- **恢复路径自校验保留并因此有了载体**：`DrawCount` 与本次提交声明的消耗数不一致 → `PushWarning` 带 `characterId` + 子流名（可降级，它是诊断保险不是恢复权威）。

**连带（承重）：`activeCombat.rng` 与 `Rng.Stream[Combat]` 的二份真值必须收敛。**

`combat-service.md` 的 `ActiveCombat` schema 里有 `"rng": { seed, state, drawCount }`，而 `RngStream.Combat` 同时在 `CharacterProfile.rng.stream[]` 里占一条 ⇒ **同一条子流的状态有两处承载**，无任何机制保证两份相等；而 `systems/common-properties.md` 已明写「战斗内随机**直接用 `combat` 子流，不在其上再派生一层**」——不派生一层就不存在第二个随机源，那么第二个状态字段是纯冗余。

- **推荐（收敛）：删掉 `ActiveCombat.rng` 这一格**，战斗内随机的状态由 `Rng.Stream[Combat]` 承载，经 `RngElements` 在每个决策点那一次 `TryApply` 内更新。收益：二份真值消失、不变式对战斗内同样是机械保证、`ActiveCombat` 少三个字段。
- 替代（保留两处 + 写回规则）**已在「用户裁决」② 被否决**，定案取收敛。

### 3 · `pastEvent` 的追加 → 另开一列 `TraceElements`

`[既有推演]`

| 六面 | `PastEventEntry` 的追加 | 最接近的既有列 |
|---|---|---|
| 要不要钳制 | 不钳制 | 多列 ✓ |
| modifier pipeline | 恒不走（一条法则若能改写履历 = 改写「到底发生过什么」这条账） | ✓ |
| 失败是否阻断整批 | 必需缺失 → 整批拒绝 | ✓ |
| **是否幂等** | **不幂等**——它是序列尾部追加，同一条提交两次得两条 | `EventStateChanges` ✗ · `PlotElements` ✗（两者都是幂等的置值 / upsert） |
| 有无量纲 | 无 | — |
| **键与载荷的形状** | **序列尾部追加一个大结构块**（`Seq` 是时序坐标，不是键） | `DeckElements` 的 `AddLooseCard` 形状同类（多重集追加、不幂等），但载荷是 `(Op, Id, Tier)` 三个标量且须解析内容注册表 ✗ |

**第四、六两面均不对齐 ⇒ 分列。**

```csharp
public IReadOnlyList<PastEventEntry> TraceElements { get; }   // ProfileChangeSpec 追加一列
                                                              // 语义：向 pastEvent 尾部只追加
```

- **直接复用 `PastEventEntry`，不建镜像类型。** `PlotElements` 用镜像 `PlotKeyPointAssignment` 的理由是**五个标量的镜像成本近零**；`PastEventEntry` 有 13 字段且会随快照判据继续增长，镜像一份等于制造两张必须同步增删的字段表——而本库对「两处必须同步的真值」的既定处置是不要。（替代形态**已在「用户裁决」③ 被否决**，定案取直接复用。）
- **一次事件恰一条**：同批两条 `TraceElements` → `PushError` + 整批拒绝（组装缺陷）。
- **`AppliedChange` 恒不含 `TraceElements` 列（新增不变式）。** 否则 `PastEventEntry.AppliedChange` 会自指。落为入口断言：`spec.TraceElements[i].AppliedChange.TraceElements` 与 `.RngElements` 必须为空 → 否则 `PushError`。它与既定的「`AppliedChange` 不再与收口入参逐字段相等」同向——**账记的是变更，不记「账本身被写进去了」这件事**。
- **`TraceElements` 在 `SelectCost` 内恒为空**，独立成行的不变式（同上款）。

**新增失败语义：**

| 情形 | 语义 | 处置 |
|---|---|---|
| `Seq != 现有 pastEvent 末条 Seq + 1`（空列表时 `!= 0`） | 必需缺失 | `PushError` + 整批拒绝（「只追加 + 单调递增不复用」的入口保证；读档侧既有的 `Seq` 不连续 / 重复校验是它的对偶） |
| `InstanceId` 为空 | 必需缺失 | `PushError` + 整批拒绝 |
| `EventId` / `RevealedEventId` / `Enemy.EnemyId` 经 `ContentRegistry` 解析不到 | 必需缺失 | `PushError` + 整批拒绝（施加侧写严；读档侧对同一字段仍取 `PushWarning` + 降级，既有不对称原样成立——读档侧的悬空来自 overlay 热更，施加侧的来自组装缺陷） |
| 同批两条 `TraceElements` | 必需缺失（组装缺陷） | `PushError` + 整批拒绝 |
| `AppliedChange.TraceElements` / `.RngElements` 非空 | 必需缺失 | `PushError` + 整批拒绝（自指防呆） |

**直接收益：「记入 pastEvent」并入收口那一次 `TryApply`**，三份结算流程图里画在事务之外的那一步就此消失，「收口是一次事务、一个存档点」由结构兑现而非由约定兑现。

- **`Aborted` 那一路**（终态判定 ① 短路）同样记一条痕迹：由失败流程组装**一次** `TryApply`，同时承载 `TraceElements[Aborted 条目]` + `EventStateChanges[ActiveEvent = null]`（失败流程本就要清理 `activeEvent`，两者落在同一笔）。**不新增存档点**。
- **可追溯性日志（非告警）：** 追加时打一行 `[ProfileManager-TryApply] trace seq=<Seq> instance=<InstanceId> outcome=<Outcome>`。

### 4 · `Project(spec)` 的语义面

#### 4a · 与 `Evaluate(spec)` 复用同一段施加代码 —— **必须复用**

`[既有推演]`

`CanAfford` 与 `TryApply` 共用 `Evaluate(spec)` 的既定理由是「否则 UI 显示买得起而实际拒绝」。投影的对应风险**更重**：投影若另写一段施加代码，「新一批所依据的 profile」与「实际提交后的 profile」可能分叉，而新一批**已经落存档**——玩家会拿到一批依据一份从未存在过的历程算出来的选项，且事后无从发现。

**形态：一段施加代码，三个门面。**

```csharp
// profile-service 内部唯一的施加实现
private ApplyOutcome Evaluate(ProfileChangeSpec spec);
// ApplyOutcome = (bool Ok, CostKey? Missing, PlayerProfile Projected)

TryApply(spec) = Evaluate(spec) → 提交 + 广播 CapabilitiesChanged + 落存档点
Project(spec)  = Evaluate(spec) → 取 Projected，丢弃提交
CanAfford(spec)= Evaluate(spec) → 取 Ok
```

| | `TryApply` | `Evaluate`（内部） | `Project` | `CanAfford` |
|---|---|---|---|---|
| 施加 spec 全部各列 | ✓ | ✓ | ✓ | ✓ |
| 钳制（查 `ResourceElements`） | ✓ | ✓ | **✓** | ✓ |
| modifier pipeline（opt-in 白名单） | ✓ | ✓ | **✓** | ✓ |
| 失败语义表（整批拒绝 / 空操作） | ✓ | ✓ | **✓**（失败即无投影可交，见下） | ✓ |
| **提交（写 Profile 字段）** | ✓ | ✗ | **✗** | ✗ |
| 广播 `CapabilitiesChanged` | ✓ | ✗ | ✗ | ✗ |
| 落存档点 / 触发 push | ✓ | ✗ | ✗ | ✗ |
| **终态判定** | ✗（在 `CycleStateManager`，读 `Snapshot.Status`） | ✗ | **✗** | ✗ |
| 返回 | `ApplyResult` | `ApplyOutcome` | 只读 `PlayerProfile` 视图 | `bool` |

- **`Project` 在 `Evaluate` 失败时返回什么：** 与 `TryApply` 同档——`Ok == false` 时**没有投影**。签名取 `bool TryProject(ProfileChangeSpec spec, out PlayerProfile projected)`，失败时 `PushError` 带 `MissingElement` 并由调用方按「组装缺陷」处置（收口 spec 组装失败本就是必须大声失败的情形）。

#### 4b · 投影**做**钳制，**不做**终态判定

`[既有推演]`

- **钳制：做。** 既定「截断只发生在**施加到 Profile 字段**那一刻」——投影正是施加。不钳制则 `RefreshAfterEvent` 会看到 `lifeSpan < 0`，而寿元百分比（分母 `ChapterLifeSpanBudget`）与 Band 判定都没有负轴语义；且「不钳制」等于两段施加代码分叉，直接违反 4a。
- **终态判定：不做，且不需要为此写一条规则。** 终态判定**本来就不在 `Evaluate` 内**——它是 `CycleStateManager` 在两个明确时点跑的**读取侧纯函数**（遍历 `ResourceElements` 里 `DepletionDefeat != null` 的行，判 `读取(character, key) == spec.Min`）。`Project` 只施加、不判定，是既有分层的自然结果。
- **「一份已判负的投影交给重算方」意味着什么 —— 照常重算、照常提交（推荐）。** 三条理由：
  - **短路撞既有校验。** 若投影判负就跳过重算并把 `eventOption` 置空，需要 `Key == EventOption` 的置空路径合法化——而它当前是明令 `PushError`（「轮回进行中把当前批置空即让玩家无路可走」）。为一条永远不会被玩家看到的省略去松动一条承重校验，不划算。
  - **短路等于新增第三处终态判定。** 判定 ① / ② 之外多一个「投影阶段的预判」，就多一处可能与判定 ② 不一致的真值。
  - **白算一批的成本是一次纯内存物化**，而判负后 `CycleStateManager` 会整体拆解 `CharacterProfile`，那一批随之消失，无任何后果。
- **推论：`RefreshAfterEvent` 不需要知道自己拿到的是不是一份「已判负」的投影**——它的入参语义恒为「结算后的角色状态」，不多一个分支。

#### 4c · 生命周期 = **一次性值，不缓存、不跨 await 持有**

`[既有推演]`

- 它是「**未提交**的只读视图」。一旦真正提交（或期间发生任何一次即时提交），缓存的投影就成为一份**过期的第二真值**，而它**不触发 `CapabilitiesChanged`**，持有者收不到任何失效通知——本库对「第二权威」的既定处置是不要。
- **纪律：** `Project` 的返回值只在**同一段同步代码内**使用（组装 → 投影 → 重算 → 补列 → `TryApply`），**不得存字段、不得跨 `await` 持有**。跨 `await` 期间可能落地一次事件内即时提交，投影当场过期。
- **机械保证：** `ProfileManager` 持一个内部提交计数 `commitOrdinal`；投影视图带上投影时刻的 `commitOrdinal`，读取时若与当前值不等 → `#if DEBUG` `PushError`（纪律阶梯第 3 级）。零运行时成本、零存档字段。
- **消费点唯一 = life-cycle-service 的收口重算**（`RefreshAfterEvent`）。**新增消费点须同批评审**——多一个消费点就多一处可能把投影存起来的地方。

#### 4d · 收口的组装顺序（承重 —— 四条问题在这里咬合）

```
① 组装收口 spec 的全部「重算依据」列：
     Elements(ResolveOutcome + lifeSpanCost) · AbilityElements · Stats
     · StatusChanges(三个 band + 两个 location，绝对值由组装方算)
     · DeckElements · PlotElements
     · EventStateChanges[ActiveEvent = null, ActiveCombat = null]
     · TraceElements[本次 PastEventEntry]      ← LifeSpanAfter 由「前值 + 本次账」纯函数算出并钳制，
                                                  与 band 绝对值同款，不需要先投影
② projected = Project(spec)                    ← 其 pastEvent 已含本条、Status 已是结算后值
③ 新一批 = RefreshAfterEvent(projected)        ← 消耗 map 子流
④ 补齐两列（且只补这两列）：
     EventStateChanges[EventOption = 新一批]
     RngElements[本次事件内消耗过的全部子流的终态]   ← SeedManager.AttachRngState(spec)
⑤ 一次 TryApply(spec) → 终态判定 ② → EventBus 广播 → 自动存档点
```

- **闭合性条件（承重 · 新增纪律）：`Project` 之后只允许追加「不构成重算依据」的列。** 当前恰有两列符合：`EventStateChanges[EventOption]`（新一批不依赖自己）与 `RngElements`（重算不读 `State` 字段，只读随机源）。**任何新增列默认落在 ① 之前**；要放进 ④ 必须显式论证它不是重算依据。落为 `#if DEBUG` 断言：`Project` 返回的视图记录投影时的列指纹，`TryApply` 时若 ① 类列发生变化 → `PushError`。
- **`PastEventEntry` 在投影之前进入 spec 是必需的**，不是顺手——「整批重算的依据 = 角色的整体历程，**重度依赖 `pastEvent`**」要求新一批必须看得见刚走完的这个事件。若痕迹留在事务之外（今天的画法），新一批依据的是一份**少一条**的历程，这是当前缺口最实际的后果。
- **战斗内的每个决策点是一次独立提交**：`TryApply(EventStateChanges[ActiveCombat = 当前局面] + RngElements[combat 子流])`。它**不新增存档点类型**（D0–D5 本就是既定存档点），且照常**不计**软阻塞闸门（闸门只数事件级存档点）。

---

## 具体形态（可 derive 的落地面）

**`ProfileChangeSpec` 九列：**

```csharp
public sealed class ProfileChangeSpec
{
    public IReadOnlyList<ChangeElement>           Elements          { get; } // 资源：带符号的量
    public IReadOnlyList<AbilityChangeElement>    AbilityElements   { get; } // 能力：集合成员操作
    public IReadOnlyList<StatDelta>               Stats             { get; } // 统计：纯计数
    public IReadOnlyList<StatusAssignment>        StatusChanges     { get; } // Status 规则字段：绝对置值
    public IReadOnlyList<DeckChangeElement>       DeckElements      { get; } // 卡组：层数 / 多重集
    public IReadOnlyList<PlotKeyPointAssignment>  PlotElements      { get; } // 剧本：按 ArcId upsert
    public IReadOnlyList<EventStateAssignment>    EventStateChanges { get; } // 事件态：整块绝对置值（含 activeCombat）
    public IReadOnlyList<RngStateAssignment>      RngElements       { get; } // ★新 RNG 子流：按键 upsert
    public IReadOnlyList<PastEventEntry>          TraceElements     { get; } // ★新 履历：序列尾部只追加
}

public enum EventStateKey { ActiveEvent, EventOption, ActiveCombat };        // ★ 追加一员

public readonly record struct EventStateAssignment(
    EventStateKey Key, ActiveEventState? ActiveEvent,
    EventOptionSave? EventOption, ActiveCombat? ActiveCombat);               // ★ 第三格

public readonly record struct RngStateAssignment(                             // ★新
    RngStream Stream, ulong State, int DrawCount);
```

**九列的六面速查（供 `/derive-requirements` 与日后新增列比对）：**

| 列 | 钳制 | pipeline | 失败阻断 | 幂等 | 量纲 | 键与载荷形状 |
|---|---|---|---|---|---|---|
| `Elements` | ✓ 逐行查表 | 逐行 opt-in | 阻断 | 否（`Add`） | 有 | 键 → 带符号标量 |
| `AbilityElements` | ✗ | 恒不走 | 混合 | ✓ | 无 | 集合成员操作 |
| `Stats` | ✗ | 恒不走 | **不阻断** | 否 | 有（计数） | 键 → 增量 |
| `StatusChanges` | ✓ 逐行查表 | 恒不走 | 阻断 | ✓ | 混合 | 键 → 标量 / id |
| `DeckElements` | ✗ | 恒不走 | 混合 | 否 | 无 | 多重集 / 带层数成员操作 |
| `PlotElements` | ✗ | 恒不走 | 阻断 | ✓ | 无 | 内容 `Id` 键 → 带载荷 upsert |
| `EventStateChanges` | ✗ | 恒不走 | 阻断 | ✓ | 无 | 固定枚举键 → 整个结构块 |
| **`RngElements`** | ✗ | 恒不走 | 阻断 | ✓ | 无 | 子流枚举键 → 双标量 upsert |
| **`TraceElements`** | ✗ | 恒不走 | 阻断 | **✗** | 无 | **序列尾部追加大结构块** |

**`CharacterProfile` 字段表的写入通道列修订（`systems/character-profile/_index.md`）：**

| # | 字段 | 现值 | 改为 |
|---|---|---|---|
| 15 | `pastEvent` | `—（life-cycle 追加）` | `TraceElements` |
| 17 | `activeCombat` | `—（combat-service 回写）` | `EventStateChanges` |
| 21 | `rng` | `—（SeedManager）` | `RngElements`（`CycleSeed` 仍为 `—`，`StartCycle` 写一次不再变） |

**profile-service API 面新增 / 修订一行：**

| 方法 | 形态 | 完整签名 | 失败语义 |
|---|---|---|---|
| 只读投影 | A | `bool TryProject(ProfileChangeSpec spec, out PlayerProfile projected)` | 施加失败 → `false` + `PushError`（收口 spec 组装缺陷）；成功返回**未提交**只读视图，**不提交、不广播、不落存档点、不判终态**；视图一次性，跨提交使用在 `#if DEBUG` 下 `PushError` |

**存档 schema：** 三处通道改动**不改任何存档字段**——`pastEvent` / `activeCombat` / `rng` 的 schema 一字不动，改的只是「谁把值写进去」。**唯一的 schema 改动落在推荐收敛 `ActiveCombat.rng` 那一项**（删三格），当前无线上存档 ⇒ 空迁移。

---

## 后果

- **受影响文档：** `systems/architecture.md`（共享核心类型的九列 + 两个新 record + `EventStateKey` 追加成员；六面判据第六面的措辞澄清）· `systems/services/profile-service.md`（三列的承重段 + 失败语义表新增 8 行 + `Project` 语义 + API 面）· `systems/services/life-cycle-service.md`（收口组装顺序、RNG 不变式的机械保证、`Aborted` 痕迹路径）· `systems/services/combat-service.md`（`ActiveCombat` 写入通道；若采纳收敛则删 `rng` 三格）· `systems/adventure-event/common-properties.md`（结算流程图把「记入 pastEvent」移进事务内 + `AppliedChange` 不含两列的不变式）· `systems/character-profile/_index.md`（字段表三行写入通道）。
- **存档 schema：** 除 `ActiveCombat.rng` 的收敛项外**零字段变动、零迁移**。
- **三条纪律由约定升级为机械保证：** 「一切写入经 `TryApply`」（`activeCombat` 补齐最后一处例外）· 「消耗随机即同批更新 `State`」（清账断言）· 「收口是一次事务、一个存档点」（痕迹进事务）。
- **`ProfileChangeSpec` 由七列变九列**，符合既定的「列表数不进承重表述」。

## 备选方案（已考虑并否决）

- **RNG 收进 `EventStateChanges`（加 `EventStateKey.Rng` + 一个载荷格）。** 否决：一次提交常需更新**多条**子流，而 `EventStateChanges` 有「同批两条同 `Key` = 组装缺陷 → 整批拒绝」这条承重校验。要么放松它（削掉一条已定不变式），要么把 `Rng` 整块置值（把没动的三条子流一并重写，让账说谎且重放时覆盖）。两条都比新开一列贵。
- **`TryApply` 自动捕获 RNG 状态**（ProfileManager 提交时向 SeedManager 索取）。否决：要求 profile-service 读 life-cycle-service，与既定服务依赖方向相反；且 spec 里没有 RNG 条目 ⇒ `AppliedChange` 重放不出同一份 `State`。
- **`activeCombat` 另开一列 `CombatStateChanges`。** 否决：三级判据 ① 明文要求六面全对齐即不分列，此处全对齐。分列只会让两个同形的中间态各长一套失败语义表——正是本问题要消掉的东西。
- **`pastEvent` 收进 `EventStateChanges`。** 否决：追加不幂等、载荷是序列而非固定键的块，第四、六两面均不对齐。
- **`Project` 另写一段轻量施加代码**（只算 `RefreshAfterEvent` 用得到的字段）。否决：见 4a——分叉的代价是玩家拿到一批依据从未存在过的历程算出的选项，且事后无从发现。
- **投影判负时短路重算 + 置空 `eventOption`。** 否决：撞既有的「`Key == EventOption` 不得置空」`PushError`，并新增第三处终态判定。

## 与既有决策的张力

1. **三级判据第六面「键与载荷的形状」的措辞需要一句澄清（承重）。** 按字面，`RngElements` 与 `PlotElements` 在六面上**全部对齐**（都是「带载荷的键值 upsert」），判据会推出「不分列 ⇒ 把 RNG 塞进 `PlotElements`」这个荒谬结论。**建议在 `systems/architecture.md` 该行补一句**：「形状包含**键的取值空间**（内容 `Id` / 固定枚举 / 无键的序列位置）与**载荷的字段集合**，不只是『标量还是 upsert』」。这是对一条承重判据的措辞修订，需用户点头；不改它，本方案第 2 节的分列结论就没有判据支撑。
2. **`AppliedChange` 恒不含 `TraceElements` / `RngElements` 两列**，是对「`AppliedChange` 复用 `ProfileChangeSpec`、不引入新类型」的一处收窄（同一个类型，两列在这个用法下恒空）。它与既定的「`AppliedChange` 不再与收口入参逐字段相等、一致性不能机械断言」同向，但把「不等」的范围又扩大了一点，须明写。
3. **入口做 `ActiveCombat.EventInstanceId` 一致性校验**与「`PlotElements` 的拓扑校验不在本入口」略有张力（见第 1 节的代价明写）。
4. **`ActiveCombat.rng` 的收敛**要改一份已定稿的存档 schema（删三格）。它与「战斗内随机不在 `combat` 子流上再派生一层」这条既定明文相容，实际上是把一处已存在的相抵消掉——但它确实是**推翻既有 schema 的一格**，须用户确认。
5. **三份结算流程图都要改**（`architecture.md` / `adventure-event/common-properties.md` / `life-cycle-service.md`），把「记入 pastEvent」从事务外移入事务内。三处画的是同一条流程，不同改即制造第二权威。

## 前置依赖

- **`CostKey` 的资源 element 清单（资源族）** —— 本方案**不依赖**它、也不新增任何 `CostKey` 成员（RNG 与痕迹都不走 `Elements`）。列出仅为说明二者互不阻塞。
- **`EventOutcomeSpec` 的内部字段面** —— 不阻塞：`TraceElements` 装的是 `PastEventEntry`，其 `AppliedChange` 的内容随产出侧增长而增长，载体形态不变。
- **战斗之外四类事件的决策点清单** —— 不阻塞第 1 节（战斗内 D0–D6 已定），但**决定其余四类事件是否也在事件内提交 `EventStateChanges[ActiveEvent = ...]` 之外的中间态**；该清单答定前，本方案对非战斗类事件只覆盖已定的两处派生（Explore 揭示 · Exchange 刷新）。
- **`Project` 的第二个消费点** —— 目前恒为一个（`RefreshAfterEvent`）。4c 的「一次性值」纪律在**只有一个消费点**时代价为零；若日后出现第二个消费点，须同批复核缓存问题。

## 用户裁决（2026-08-19 · 全部定案）

**五项取向全部按本方案的推荐定案（各取 A）**：①② 沿用 2026-08-18 批量评审的裁决，③④⑤ 于本次一并采纳。本方案自此为**定案方案**，`## 建议方案` 与 `## 具体形态` 各节即最终形态，可直接喂给 `/analyze-new-ideas` 提炼。

| # | 取向 | 定案 | 承重理由（保留） |
|---|---|---|---|
| ① | RNG 状态的通道形态（承重） | **取 A —— 另开 `RngElements` 列**<br>*（2026-08-18 已裁，照录）* | 三级判据 ① 在第六面不对齐；且它是唯一能让「忘了带 RNG」被检出的形态。`AppliedChange` 由此天然带上 RNG 终态、可完整重放 |
| ② | `ActiveCombat.rng` 是否收敛 | **取 A —— 收敛，删 `ActiveCombat.rng` 三格**，战斗内随机状态由 `Rng.Stream[Combat]` 承载<br>*（2026-08-18 已裁，照录）* | `systems/common-properties.md` 已明写「战斗内随机不在 `combat` 子流上再派生一层」，不派生就不该有第二个状态字段。这是消掉一处**已存在的相抵**；当前无线上存档 ⇒ 空迁移 |
| ③ | `TraceElements` 的载荷类型 | **取 A —— 直接复用 `PastEventEntry`**，不建镜像类型 | 镜像的价值在「字段不同」，此处字段完全相同且数量大（13 字段），建镜像 = 两张必须同步增删的字段表，而快照判据还会继续增长。零镜像维护，spec 类型与存档类型在这一列上同一 |
| ④ | 投影判负时的处置 | **取 A —— 照常重算新一批、照常提交**，`RefreshAfterEvent` 不多分支 | B 撞一条承重校验（要把「`Key == EventOption` 置空」从 `PushError` 改为条件合法，并新增第三处终态判定），换来的只是省一次内存物化。白算一批是纯内存开销，随失败流程一并拆解 |
| ⑤ | `ActiveCombat.EventInstanceId` 一致性校验的落点 | **取 A —— `ProfileManager` 入口 `PushError` + 整批拒绝** | 与读档校验 ⑥ 两侧口径一致。读档侧已按 `PushError` 拒绝恢复，**施加侧宽于读档侧是本库唯一没有先例的方向**（既有不对称一律是「入口严、读档宽」）。代价仅是入口多认识一格字段名（不认识战斗规则） |

**① 连带的必做项（不补它，A 就没有判据支撑）：** 「与既有决策的张力」第 1 条所需的措辞补全 —— 三级判据第六面须明写「形状包含**键的取值空间**与**载荷的字段集合**」。**这一条必须与 ① 同批落笔。**

**跨草稿裁决（`ProfileChangeSpec` 总列面）：** 本批四份草稿各自独立增列，合计 7 → **11** 列（本方案的 `RngElements` + `TraceElements`，另加 `CodexElements` 与 `SettingChanges`）。**已裁决为接受**，硬要求：**四份必须单批收口、共用同一次 `schemaVersion` bump**，不得分开落笔造成列面连续 bump。

**落笔提醒：** 「张力 5」——三份结算流程图须同改，把「记入 `pastEvent`」移入事务内。这是提炼时最易漏的一处。
