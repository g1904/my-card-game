---
type: solution-draft
date: 2026-08-17
question: 结算进行中的 `EventOption` 派生实例（Explore 揭示 / Exchange 刷新）如何落存档——派生实例是否替换当前批中的原实例，还是另有承载？
source: open-questions/02-event-options.md → 「结算进行中的 `EventOption` 派生实例如何落存档（08-17d 新增 · 承重）」（并在 systems/adventure-event/exchange/_index.md 的待决问题里以「reroll 后的库存如何落存档」重复登记）
targets: systems/services/future-event-service.md · systems/adventure-event/common-properties.md · systems/character-profile/_index.md · systems/services/profile-service.md · systems/adventure-event/explore/_index.md · systems/adventure-event/exchange/_index.md · systems/services/life-cycle-service.md · systems/services/sync-service.md
status: distilled
reviewed: 2026-08-17 —— 五项裁决全部取推荐项（③ 揭示不新增存档点 与 ④ RNG 只落不变式 标 [采纳推荐 — 待复核]；⑤ 命名与草稿的复数形态相反，按单数落笔）；合并 interview 另裁定：新增只读投影 Project(spec) 先算后提交（两条承重纪律都不改写）、当前批载体可空、activeEvent 与 SelectCost 同一次 TryApply 创建且判负那一路由失败流程清理、提交即本地原子写（措辞校正为「不新增决策点 / 不新增存档点类型」）、全链单数一致
distilled-to: handoffs/2026-08-17j-event-option-derived-persistence.md
---

# 方案草稿 — 结算进行中的 `EventOption` 派生实例的承载与落盘

> **范围声明（重要）。** 本草稿只回答**派生实例的承载与落盘形态**：承载在哪个存档节点、写入走哪条通道、原子写与 push 时序、退出重进的读取路径、「重掷不可刷」的机械保证。
> **它不定 `EventOption` 的字段清单**——凡引用字段一律只用已定的十一字段（`InstanceId` / `EventId` / `EventType` / `Priority` / `SelectCost` / `IsRevealed` / `RevealedEventId` / `DestinationLocationId` / `ResearchSlots` / `ExchangeStock` / `RerolledCount`）。清单可能被另一份同期草稿扩充，**本方案的承载形态对新增字段保持中立**：它存的是「整份定稿实例的快照」，加字段不改承载形状、不改任何一条不变式。

## 问题

`EventOption` 是「产出即定稿（finalized · immutable）、消费侧不得回查模板重算、不得改写其字段」的定稿实例（`systems/services/future-event-service.md`、`systems/architecture.md` 总则 6）。而事件结算进行中有**两处**会产生它的派生：

| 派生点 | 形态 | 必须在玩家可退出之前落盘的理由 |
|---|---|---|
| **Explore 揭示** | `revealed = option with { IsRevealed = true }`（`eventStart` 阶段内） | `IsRevealed` 保留的唯一理由就是「退出重进后呈现层要判断这一步已揭示过」（`explore/_index.md`） |
| **Exchange 刷新** | `option with { ExchangeStock = 新一批, RerolledCount = 前值 + 1 }` | 不落盘则退出重进即可把刷新价按回起点、并重掷一次库存（`exchange/_index.md`「重掷结果即时落存档」） |

**缺口有三层，本库都尚未指定：**

1. **派生实例住在哪。** 是原地替换当前批中的那一份，还是另有一个承载节点？
2. **当前批本身住在哪。** 「当前批 eventOptions 落存档」已答定（`answer-logs/log-service-api-contracts.md`、`systems/architecture.md` 总则 6 推论 1），但 `systems/character-profile/_index.md` 的字段清单里**没有任何一个字段承载它**——`pastEvent` / `activeCombat` / `disabledAbility` / `plotKeyPoint` / `chapterRetry` / `Status` / `Rng` 逐个列名，唯独当前批没有名字。派生实例的承载无从定义在一个不存在的载体之上。
3. **写入走哪条通道。** 「一切 Profile 写入经 `profile-service.ProfileManager`」是硬纪律，且 `ProfileChangeSpec` 的各列都已按施加语义分列；一个结构块（整份 `EventOption`）当前**没有列可落**。`activeCombat` 的写入通道在本库同样从未明写（见「越界发现」）。

## 约束（来自既有设计）

- **产出即定稿 · 不得改写字段 · 消费侧不得回查模板重算。** → `future-event-service.md`「意图」、`architecture.md` 总则 6。
- **当前批里那份原实例不动。** `explore/_index.md` 的揭示伪码与 `adventure-event/common-properties.md` 的「结算阶段」两处都明写「派生实例，当前批里那份原实例不动」。
- **future-event-service 是 eventOptions 的唯一出口，且物化完成后不改这批实例、不持有跨批次状态。** → `future-event-service.md`「三点推演」。
- **一切 Profile 写入经 `ProfileManager.TryApply`，全有或全无、单点提交。** → `profile-service.md`。
- **一个事件的收口是一次事务、一个存档点；事件内部的**主动消费**即时提交**（两条判据：玩家主动按下的消费 + 不即时写就开出「退出重进即回滚」的窗口）。→ `adventure-event/common-properties.md`「事务纪律」。
- **`ct` 只在决策点被观察 ⇒ 取消点与存档点永远重合、中间态永不需要持久化。** → `life-cycle-service.md`「取消语义」、`combat-service.md`「挂起态的恢复与取消」。
- **决策点存档 + RNG `State` 持久化从根上关闭「退出重掷」。** → `life-cycle-service.md`、`systems/common-properties.md`「带种子的 RNG」。
- **存档点与 push 解耦**：每个存档点立即原子写本地缓存，push 走 5 秒防抖；软阻塞闸门只数**事件级**存档点，事件内决策点不参与判定。→ `sync-service.md`。
- **diff 粒度 = `CharacterProfile`**，挂在 `CharacterProfile` 上的块不新增同步单元。→ `sync-service.md`、`combat-service.md`「战斗存档」。
- **`ActiveCombat` 先例（本问题最强的类比）：** `CharacterProfile` 上一个**可空块**，战斗开始创建、`eventEnd` 收口置空，**不进 `pastEvent`**、不与 `Rng.Streams[]` 混住，带 `eventInstanceId` 供读档校验一致，可重算项一律不落。→ `combat-service.md`「战斗存档：`ActiveCombat`」。
- **快照判据：** 「重算不出来的存，重算得出来的不存」，完整口径是「重算不出来**且有消费方**」。→ `adventure-event/common-properties.md`、`character-profile/_index.md`（`plotKeyPoint` 的「不记已走分支路径」）。
- **存档 schema 带版本 + 原子写（临时文件 → rename）。** → `.claude/rules/state-save-rules.md`、`sync-service.md`。

## 建议方案

### 1 · 先给当前批一个具名载体：`CharacterProfile.eventOptions`

`[既有推演]`

「当前批落存档」已是定案，缺的只是字段名。建议登记为与 `pastEvent` / `activeCombat` / `disabledAbility` / `plotKeyPoint` **平级**的一个具名字段（**非空**，轮回进行中恒有一批）：

```jsonc
"eventOptions": {                   // 当前批的定稿快照；每次 RefreshAfterEvent 整块替换
  "batchId": "batch-0043",
  "effectivePriority": 0,
  "options": [ /* EventOption 定稿实例，1–5 项 */ ]
}
```

- **整块替换，不做增量。** 与「批次刷新只有一种形态：整批重算」「本服务不持有跨批次状态」完全同构——批与批之间没有承接关系，diff 上就是一次整键替换（`sync-service.md` 的 diff 形态本就是「顶层键出现即整键替换」）。
- **它不进 `pastEvent`**：未选项只归档 `UnchosenOptionRef` 四字段轻摘要，这条已定案，本字段不动它。
- **`EffectivePriority` 一并落**，避免读档后由 UI 自己 `Max(o.Priority)`（`future-event-service.md` 明写这是产出侧语义，呈现层只做呈现）。
- 体积：3 项 × 一份 `EventOption`（Exchange 批最重，含 `ExchangeStock`），量级 **1–6 KB**，每事件一次整键替换。远低于 `ActiveCombat` 的 93 KB/场，`sync-service.md` 的体积护栏（> 500 条 / > 512 KB 告警）不受威胁。
- **须与「`CharacterProfile` / `PlayerProfile` 字段 schema」那一路对齐**（见 `## 前置依赖`）——本条只主张「它需要一个平级具名字段」，字段的最终命名与排位归那一路。

### 2 · 派生实例的承载 = `CharacterProfile.activeEvent`（新的可空块）

`[既有推演]`（形状全部由 `ActiveCombat` 先例导出）· `[取向选择]`（A / B / C 三条路，见 `## 仍需用户决定` 第 1 项）

**建议 A：另立承载，不替换当批实例。**

```jsonc
"activeEvent": {                    // null = 当前没有正在结算的事件
  "eventInstanceId": "evt-0042",    // 被结算的那一项；必须能在 eventOptions.options 里按 InstanceId 找到
  "option": { /* 派生后的定稿实例全量快照 —— 结算期间的权威副本 */ }
}
```

- **生命周期与 `ActiveCombat` 同款**：`AdvanceEventAsync` 校验选项合法性、施加 `SelectCost`、终态判定 ① 未判负之后**创建**（值 = 当批那一项的原样拷贝）；`eventEnd` 收口后**置空**（与 `activeCombat` 同一处清空）。
- **`activeEvent` 是结算期间唯一的权威副本。** 一条读取规则收口全部歧义：

  > **`activeEvent != null` 时，本次结算涉及的 `EventOption` 一律读 `activeEvent.option`；批中的原实例只用于「呈现尚未开始的那些选项」与组装 `Unchosen` 轻摘要。**

- **两个派生点各是一次对 `activeEvent.option` 的整体置值：**

  ```
  Explore 揭示（eventStart 内）：
      activeEvent.option = activeEvent.option with { IsRevealed = true }
      —— 当前批里那份原实例不动（explore/_index.md 原句一字不改）

  Exchange 刷新（事件内玩家主动消费）：
      activeEvent.option = activeEvent.option with {
          ExchangeStock = 新一批 offer,          // 走同一条取池链、同一个 Shop 子流
          RerolledCount = 前值 + 1 }
      —— 与 ChangeElement(Jade, -刷新价) 同一次 TryApply 提交
  ```

- **为什么不替换当批实例（B）**：① `explore/_index.md` 与 `adventure-event/common-properties.md` 两处明写「当前批里那份原实例不动」，B 要正面改写这两句；② `EventOptionBatch.Options` 是 `IReadOnlyList`，替换要重建整个 batch，而批的持有者是 future-event-service，它明写「物化完成后本服务不改这批实例」——B 等于给这个「无记忆的纯产出侧」加一个运行时写入面；③ 更硬的一条：B 把「有一个事件正在结算」这个**态**藏进批里，读档时无法一次判空得知，而 `activeCombat` 那条路已经用可空块给出了先例，两条路形状不一致会各自长出自己的恢复分支。
- **`activeEvent` 与 `activeCombat` 并存、不合并。** 两者语义不同层：`activeEvent` 是**事件级**中间态（哪一项在结算、它派生成什么样），`activeCombat` 是**战斗状态机**的中间态。硬约束一条：`activeCombat != null ⇒ activeCombat.eventInstanceId == activeEvent.eventInstanceId`（落读档校验，见下）。**不把 `activeCombat` 塞进 `activeEvent` 之内**——那是一次纯重构，牵动 `combat-service.md` 的整段 schema，收益为零（最小扰动）。

### 3 · 写入通道：`ProfileChangeSpec` 增一列 `EventStateChanges`

`[既有推演]`（原子性要求）· `[取向选择]`（是否新增列，见 `## 仍需用户决定` 第 2 项）

**最硬的约束来自 Exchange 刷新的原子性**：`-jade`（`Elements` 的一条 `ChangeElement`）与**新库存 + `RerolledCount`** 必须落在**同一次 `TryApply`** 内。否则「全有或全无」在这一笔上破掉，而破掉的两个方向都是线上事故：

- 只落 `-jade`、库存未落 → 玩家付了钱，退出重进看到旧库存，**可用同一笔钱再刷一次**（还是那个被防重掷纪律封死的窗口）；
- 只落库存、`-jade` 未落 → **免费刷新**。

`Elements` 只装带符号的资源量，装不下一个结构块；`StatusChanges` 的 key 逐行声明在 `StatusFields` 表里、值是标量或 id，也装不下。故按 `profile-service.md` 明写的判据——**「施加语义根本不同就分列」，且「列表数不进承重表述，它随字段族增长」**——建议增一列：

```csharp
public sealed record EventStateAssignment(          // 绝对置值：赋一份已算好的块，或置空
    EventStateKey Key,                              // ActiveEvent | EventOptionBatch
    object        Value);                           // null = 置空（仅 ActiveEvent 合法）

public enum EventStateKey { ActiveEvent, EventOptionBatch }
```

- **语义 = 绝对置值**（与 `StatusChanges` 同款）：组装方先算好整块再置入，`ProfileManager` 不做任何合并 / 增量。
- **恒不走 modifier pipeline。** 一条法则若能改写 `RerolledCount` 或库存，等于账号级内容改写轮回级的定稿实例。
- **`selectCost` 内恒为空**，落一条**独立**的物化组装后断言 + 一处加载期校验（**不与 `AbilityElements` / `DeckElements` 那两条合并**——`profile-service.md` 与 `adventure-event/common-properties.md` 已明写不得合并成「非 `Elements` 的列一律为空」的通则，日后新增的列未必都该被排除在成本侧之外）。
- **组装方 = life-cycle-service**（与三个 band 字段、两个 location 字段同款：resolver 只描述结果、不自行写档）。Exchange 面板的刷新按钮把「新库存 + 计数」交给 resolver 描述、由 life-cycle-service 组装进那一次即时 `TryApply`。
- **`Value` 的类型形态**：草稿写成 `object` 只为示意；落地时按 key 分成两个具名可空字段（`ActiveEventState?` / `EventOptionBatchSave?`）比裸 `object` + 装箱更符合本库「贯穿链路的类型一致性、不做隐式装箱」的工程纪律。

### 4 · 落盘时机：零新增存档点、零新增结算阶段

`[既有推演]`

- **Explore 揭示不需要自己的存档点。** 判据链：`ct` **只在决策点被观察** ⇒ 揭示到「随后进入的第一个决策点」之间**不存在可退出窗口**；而三种真身各自的第一个可退出点都是既有的：Combat 真身 → **D0**（`Immediate`，既定「进入战斗前」flush 点）· Exchange 真身 → 商店面板打开的那个事件内决策点 · Travel 真身 → 无玩家输入，直接走到 `eventEnd` 的收口存档点。**故揭示随后续第一个存档点一并落盘，不新增点、不新增阶段。**
- **Exchange 刷新即时提交**，与逐笔交易完全同形（同一条既定纪律的第四个实例；两条判据都成立：玩家主动按下 + 不即时写就开出退出重进即回滚的窗口）。本地立即原子写，push 走 **`Debounced`**。
- **闸门口径不变**：这些都是**事件内**存档点，照常写本地、照常防抖 push，**不计入软阻塞闸门**（闸门只数事件级存档点 ≥ 3）。刷新按钮不会因为连按三次而弹出模态。
- **`eventEnd` 收口**：`activeEvent` 置空与 `activeCombat` 置空并入同一次 `TryApply`（收口仍是一次事务、一个存档点）。

### 5 · RNG 同事务不变式（本方案发现的一处必须明写的裂缝）

`[既有推演]`

刷新消耗 `RngStream.Shop` 的随机 ⇒ `Rng.Streams["shop"]` 的 `State` / `DrawCount` **必须与新库存落在同一次原子提交内**。两侧不同步的后果各自都是可利用的漏洞：

| 落盘情形 | 后果 |
|---|---|
| `State` 落了、库存没落 | 退出重进看到旧库存，再刷一次得到**不同**结果 ⇒ 事实上的重掷通道 |
| 库存落了、`State` 没落 | 下一次刷新从同一个 `State` 起掷 ⇒ 重复同一批结果，且 `DrawCount` 诊断口径失真 |

本库现有文本只说「`State` 是恢复用的权威字段」，**没有说 RNG 状态的写入走哪条通道、与 `TryApply` 是什么时序关系**。建议：

- 先落一条**可断言的不变式**：「凡消耗了子流随机的提交，该子流的 `State` / `DrawCount` 必须在同一次原子写内更新」，并在恢复路径上加一条自校验（`DrawCount` 与本次提交声明的消耗数一致 → 否则 `PushWarning`）。
- 是否把 `Rng` 块也纳入 `EventStateChanges`（或另一列）作为形态收口，见 `## 仍需用户决定` 第 4 项。**同一条裂缝对 `ActiveCombat` 一样成立**（`combat` 子流），故它不是本问题引入的，只是本问题第一次把它逼到台面上（见「越界发现」）。

### 6 · 「重掷不可刷」的机械保证

`[既有推演]`

不靠自律，落成一组可断言的不变式与读档校验：

| # | 检查 | 时机 | 失败语义 |
|---|---|---|---|
| 1 | `activeEvent.eventInstanceId` 能在 `eventOptions.options` 中按 `InstanceId` 找到 | 读档 | **必需缺失** → `PushError` + `characterId` + `instanceId`（内部一致性破损） |
| 2 | `activeEvent.option.InstanceId == eventInstanceId` 且 `EventId` 与批中原实例一致 | 读档 | 同上 |
| 3 | `activeEvent.option.RerolledCount >= 批中原实例.RerolledCount` | 读档 | 同上（单调不减是刷新价递增的前提） |
| 4 | `IsRevealed` 只允许 `false → true`（派生方向单调） | 运行时断言 | `PushError`（回落 = 重新遮罩，等于开一次重掷） |
| 5 | `RerolledCount` 增加 ⇒ `ExchangeStock` 整批替换（不允许只涨计数不换库存，或反之） | 运行时断言 | `PushError` |
| 6 | `activeCombat != null ⇒ activeCombat.eventInstanceId == activeEvent.eventInstanceId` | 读档 | **必需缺失** → `PushError` + 拒绝恢复该战斗（与 `combat-service.md` 既有第 ① 条校验同档、同处置） |
| 7 | `RerolledCount <= MaxRerollCount` | 读档 + 运行时 | `PushWarning` + 钳到上界（内容侧数值可能被 overlay 调低，属可降级） |

**恢复即读结果、绝不重掷**：恢复路径读 `activeEvent.option` 的 `ExchangeStock` / `IsRevealed` 直接呈现，**不重新走取池链**。这与「奖励候选预先算定、恢复时读结果不重抽」是同一条纪律的又一个实例。

### 7 · 痕迹侧：从派生后的实例取快照，`PastEventEntry` 不新增字段

`[既有推演]`

- **收口时 `PastEventEntry` 的定稿实例快照取自 `activeEvent.option`，不取批中的原实例。** 否则履历会记下 `IsRevealed = false` 与刷新前的旧库存——而「同一个事件在呈现、结算、记入历程三处看到的是同一份数据」正是定稿纪律要买的东西。
- **`ExchangeStock` / `RerolledCount` 不进 `PastEventEntry`。** 按判据的完整口径「重算不出来**且有消费方**」：库存虽重算不出，但事件收口后**永无消费方**（本次已买的东西在 `AppliedChange` 里、`Unchosen` 只要四字段）。与 `plotKeyPoint`「不记已走分支路径」同款处置。
- `RevealedEventId` 本就恒存在 `PastEventEntry` 上，Explore 的回溯不欠任何字段。**故本条零 schema 增量。**

## 具体形态（可 derive 的落地面）

```csharp
// —— CharacterProfile 上两个新字段（与 pastEvent / activeCombat / disabledAbility / plotKeyPoint 平级）——

EventOptionBatchSave eventOptions;   // 非空：轮回进行中恒有一批
ActiveEventState?    activeEvent;    // 可空：null = 当前没有正在结算的事件

public sealed record EventOptionBatchSave(
    string                     BatchId,
    IReadOnlyList<EventOption> Options,            // 1–5 项定稿实例
    int                        EffectivePriority); // 0 或 1；产出侧算好，呈现层不自算

public sealed record ActiveEventState(
    string      EventInstanceId,   // 被结算项的 InstanceId；读档时与 eventOptions.options 交叉校验
    EventOption Option);           // 派生后的定稿实例 —— 结算期间的权威副本
```

| 字段 | 类型 | 语义 | 生命周期 |
|---|---|---|---|
| `eventOptions` | `EventOptionBatchSave` | 当前批定稿快照 | `StartCycle` 写第一批；每次 `RefreshAfterEvent` **整块替换** |
| `activeEvent` | `ActiveEventState?` | 正在结算的那一项 + 其派生态 | `TryApply(SelectCost)` + 终态判定 ① 通过后创建；`eventEnd` 收口置空 |

**`ProfileChangeSpec` 的新列**（第六列，形态见「建议方案 3」）：`EventStateChanges: IReadOnlyList<EventStateAssignment>`，绝对置值 · 恒不走 modifier pipeline · `selectCost` 内恒空（独立断言 + 独立加载期校验）。

**三条写入时序（全部在既有阶段内，无新增阶段）：**

```
AdvanceEventAsync(chosen)
  校验 Priority < EffectivePriority → 拒绝
  → TryApply( SelectCost + EventStateChanges[ActiveEvent = 该项原样拷贝] )   ← 同一次事务
  → 终态判定 ①（判负 → 短路；activeEvent 随失败流程一并清理）
  → 【eventStart】Explore：TryApply( EventStateChanges[ActiveEvent = option with { IsRevealed = true }] )
                          ← 不单独落存档点，随后续第一个决策点 / 收口一并写盘
  → resolver.ResolveAsync(activeEvent.option, ct)      ← 传派生后的那一份
       Exchange 刷新（玩家主动按下）：
         TryApply( Elements[Jade, -刷新价]
                 + EventStateChanges[ActiveEvent = option with { ExchangeStock=新, RerolledCount=+1 }] )
         ← 即时提交、本地原子写、push = Debounced、不计闸门
  → 【eventEnd】合并 ResolveOutcome + lifeSpanCost + 隐藏属性推拉
                 + EventStateChanges[ActiveEvent = null, EventOptionBatch = 新一批]
                 → 一次 TryApply、一个存档点
  → 记入 pastEvent（快照取自 activeEvent.option）→ 终态判定 ② → 广播
```

**恢复流程（读档）：**

```
读 CharacterProfile
  → activeEvent == null ? 呈现 eventOptions 的横滑选择区（无事件在结算）
  : 有事件在结算：
      activeCombat != null ? 校验 eventInstanceId 一致 → 走 combat-service 既有恢复路径
      : 按 activeEvent.option 恢复该事件的面板态
          （Exchange：读 ExchangeStock 直接呈现，绝不重走取池链
            Explore：IsRevealed == true ⇒ 呈现真身，不再播揭示转场）
```

## 后果

- **存档 schema**：新增两个 `CharacterProfile` 字段 + `ProfileChangeSpec` 增一列 ⇒ **bump 一次**；当前无线上存档 ⇒ **空迁移**，走既有 MigrationManager 骨架。老档缺 `eventOptions` → 无法凭空重建（物化不可重算）⇒ 只能按「无进行中批次」处置并在下一次 `RefreshAfterEvent` 重算一批，这条要写进迁移说明。
- **同步**：两个字段都挂 `CharacterProfile` ⇒ diff 天然落在既定粒度，**不新增同步单元**。体积 +1–8 KB / 事件（`eventOptions` 整块替换是主要项），`sync-service.md` 第 60 行那句「估算随『每批 eventOptions 数量』答定需复核」由本条给出复核口径。
- **服务面**：future-event-service **零改动**（不新增方法、不新增写入面，仍是无记忆的纯产出侧）；`Current { get; }` 的语义收窄为「内存视图，权威在 `CharacterProfile.eventOptions`」这一句需要补写。life-cycle-service 多两处 `EventStateChanges` 的组装（与既有 band / location 组装同款）。
- **文档改动面**：`character-profile/_index.md`（登记两个字段）· `profile-service.md`（新列 + 校验表 + 断言）· `future-event-service.md`（承载与 `Current` 语义一句）· `adventure-event/common-properties.md`（结算阶段的读取权威一句）· `explore/_index.md` 与 `exchange/_index.md`（各自那条待决问题移出、指向承载）· `life-cycle-service.md`（组装时序）· `sync-service.md`（体积复核）。
- **零新增**：结算阶段 · 存档点类型 · resolver · 服务方法 · RNG 子流 · `PastEventEntry` 字段 · `EventOutcome` 成员。

## 备选方案（已考虑并否决）

- **B · 原地替换当前批中的原实例。** 否决理由三条（见「建议方案 2」）：要正面改写两处明写「原实例不动」的文本 · 给 future-event-service 加一个它明确没有的运行时写入面 · 把「有事件在结算」这个态藏进批里，读档时无法一次判空，与 `activeCombat` 那条路形状不一致。**但它有一条真实优点**（少存一份 option、无读取优先级规则），故仍列入待裁决项。
- **C · 只存派生增量（`revealedInstanceId` + `rerolledCount` + `rerolledStock` 三个散字段）。** 否决：库存是一个数组，散字段等于把 `EventOption` 的一半重新平铺一遍；且**每新增一个可派生字段就要新增一个散字段**——与同期正在扩充字段清单的那条待答项正面相撞，而「存整份快照」对字段增删完全中立。
- **D · 派生态不落存档，退出即回滚到未揭示 / 未刷新，并退还刷新费。** 否决：与「`SelectCost` 不回滚、已经发生的事就是发生了」正面冲突；且 Explore 一侧根本无法回滚（真身已被玩家看见，回滚只是让他免费看一次）。
- **E · 由 future-event-service 重掷 / 重算派生态。** 否决：违反「消费侧不得回查模板重算」，且物化确定性只在同一 `contentVersion` 内成立——overlay 热更后重算得到的是另一批库存。
- **F · 给 Explore 揭示单独开一个存档点（`Immediate`）。** 否决为**默认项**（仍列入待裁决第 3 项）：`ct` 只在决策点被观察 ⇒ 揭示与后续第一个决策点之间没有可退出窗口，独立存档点是一次无收益的写入；且 Combat 真身那一路的 D0 本就是 `Immediate`。

## 与既有决策的张力

1. **「future-event-service 是 eventOptions 的唯一出口」 vs `activeEvent.option` 是一份不由它产出的 `EventOption`。**
   派生方是 life-cycle-service（揭示）与 Exchange 的结算路径（刷新）。建议的松动**极小且应明写**：**「唯一出口」管的是「物化」这一动作，不管「已定稿实例的 `with` 派生」**——后者不取池、不掷新的物化随机（刷新掷的是库存，不是重新物化一个事件）、不改 `InstanceId` / `EventId`。若不写这一句，日后必有人据「唯一出口」把派生逻辑推回 future-event-service，而那会给这个明写「无记忆、不持有跨批次状态」的服务装上一个事件内的状态机。
2. **`ProfileChangeSpec` 增列 vs 「列表数不进承重表述」。** 这条纪律本就允许增列（它明写列表数随字段族增长），故不是冲突而是一次**第三度应用**（前两次是 `StatusChanges` 与 `DeckElements`）。但代价照既有惯例明写：**bump 一次 schema · 三处列举需同改 · 新增一条独立的「成本侧恒空」断言与加载期校验**。
3. **`activeCombat` 的写入通道从未明写，本方案给 `activeEvent` 明写了一条。** 两者形态相同却一条走 `TryApply` 的新列、一条来路不明，会长成两套写入纪律。**建议把 `activeCombat` 一并收进同一列**——但这落在 `combat-service.md` / `profile-service.md`，超出本问题的范围，故列为待裁决第 2 项的一个子选项，不在本草稿替用户拍板。
4. **不构成张力的一处（写明以免误判）：** 本方案与「产出即定稿、不得改写其字段」**不冲突**——两个派生点都是 `with` 产生新实例，批中的原实例一字未动，`explore/_index.md` 的伪码原句可原样保留。

## 前置依赖

- **`EventOption` 的完整物化字段清单（`02` 分片 · 同期在办）。** 本方案存的是「整份定稿实例快照」，对字段增删中立 ⇒ **不阻塞**。唯一的交界：若清单新增了**可在结算中被改写**的第三类字段（当前只有 `IsRevealed` 与 `ExchangeStock` / `RerolledCount` 两族），那条字段自动落入 `activeEvent.option`，**并需要给「建议方案 6」的不变式表补一行方向性约束**（形如「只允许单调 X→Y」）。
- **`CharacterProfile` / `PlayerProfile` 的字段 schema（同期在办）。** 本方案要在 `CharacterProfile` 上占两格（`eventOptions` / `activeEvent`）⇒ **命名、排位与该路的 schema 须对齐**；若那一路把「事件进行中态」整体重新分区，本方案的承载位置随之调整，**形态与不变式不变**。
- **「战斗之外的事件类型的决策点清单」（`life-cycle-service.md` 待决项）。** 它决定 Exchange 面板的哪些时刻是决策点 ⇒ 影响 `activeEvent` 被写盘的**精确时刻数**，但不影响本方案的形态（刷新走「主动消费即时提交」这条独立通道，本就不依赖决策点清单）。**建议方案 4 的「揭示随后续第一个决策点落盘」在该清单答定前只有形状、没有精确点位。**
- **`MaxRerollCount` / `RerollBaseCost` / `RerollCostStep` 的取值**（归 ch1 数值标杆专场）。只影响校验 #7 的钳制边界，不影响形态。
- **RNG 状态的写入通道**（本草稿新指出的裂缝，见「建议方案 5」）。它同时约束 `ActiveCombat`，**建议独立于本问题裁决**；在它答定前，本方案只落「同一次原子写」这条不变式。

## 仍需用户决定 → **已全部裁决（2026-08-17 · 批量评审）**

> **定案（五项一律取推荐项）：**
> **① 取 A** —— 承载 = 新可空块 `CharacterProfile.activeEvent`，持派生后的整份定稿实例；当批原实例一字不动（`explore/_index.md` 与 `adventure-event/common-properties.md` 的「原实例不动」两句原样保留）。顺带补上当前批的具名载体。
> **② 取 ②-a** —— 写入走 `ProfileChangeSpec` 新列 `EventStateChanges`；**不**把 `activeCombat` 一并收进来（不动 `combat-service.md`，该项超出本问题范围）。`activeCombat` 的写入通道仍未明写，作为一条独立待答项留下（见「越界发现」）。
> **③ 取 ③-a `[采纳推荐 — 待复核]`** —— Explore 揭示不新增独立存档点，随后续第一个决策点落盘。
> **④ 取 ④-a `[采纳推荐 — 待复核]`** —— 只落一条「消耗子流随机的提交须与该子流 `State`/`DrawCount` 同一次原子写」不变式 + 一条恢复自校验；`Rng` 块纳入 spec 列的收口形态另立一轮。
> **⑤ 由 S1 的裁决统一覆盖 —— ⚠ 结果与草稿采用的复数形态相反。** 同批用户裁定**改后端契约为单数**、库内命名风格全库自洽沿用既有单数 ⇒ 当前批载体应定名 **`eventOption`（单数）**，不是草稿里写的 `eventOptions`。提炼时按单数落笔。
>
> **本轮同批裁定的连带（跨分片，orchestrator 合并）：**
> - **`ProfileChangeSpec` 本轮一次增两列**：本草稿的 `EventStateChanges` + 同批 S4 的 `PlotElements`；同时 `ChangeElement` 增第三字段 `Op`、`ElementSpec` 增 `AllowedOps` 列。三处改动在同一段代码块内，**必须一次落笔**；成本侧恒空断言**逐列独立写**、不合并成通则。
> - 同批 S5 裁定 `EventOption` 增一个可空 `EncounterSpec Encounter`（`EnemyInstance` 嵌其内）⇒ **`activeEvent` 持整份快照时连带复制最胖载荷**，存档体积由本草稿估的 0.3–2 KB 上抬。用户已在裁决时知悉此后果。
> - 本草稿假设「结算中可被改写的字段族只有两族」**成立**：S2 新增的 `Outcome` 格明确不参与派生改写。
> - 五份草稿的 schema bump **合并为同一次**；本草稿指出的「老档缺当前批载体无法凭空重建」按「无进行中批次」迁移，下一次 `RefreshAfterEvent` 重算一批（当前无线上存档 ⇒ 实为空迁移）。
>
> 下列原文保留为选项与理由的溯源。

### ① 派生实例的承载形态：A / B / C

| 选项 | 形态 | 后果 |
|---|---|---|
| **A（推荐）** | 新可空块 `CharacterProfile.activeEvent`，持派生后的整份实例；当批实例不动 | 与 `ActiveCombat` 先例同形；读档一次判空即知「有事件在结算」；两处明写「原实例不动」的文本一字不改。代价：多存一份 option（0.3–2 KB）、多一条「结算中读 `activeEvent.option`」的读取优先级规则 |
| **B** | 原地替换当前批中那一项（重建 batch） | 只有一处承载、无读取优先级规则、体积最小。代价：要改写 `explore/_index.md` 与 `adventure-event/common-properties.md` 的「原实例不动」两句；给 future-event-service 加一个它明确没有的写入面；「事件进行中」态无法一次判空 |
| **C** | 三个散字段记增量 | 体积最小。代价：每新增一个可派生字段就加一个散字段，与同期扩充字段清单那条待答正面相撞 |

**推荐 A。** 理由是它**一条既有先例全覆盖**（`ActiveCombat` 的每一条形状——可空块 / 挂 `CharacterProfile` / `eventInstanceId` 交叉校验 / 收口置空 / 不进 `pastEvent` / 不新增同步单元——逐条对位可搬），且它是三者中**唯一不需要改写任何既有明文**的一条。

### ② 写入通道：新增 `ProfileChangeSpec` 列，还是别的？

| 选项 | 后果 |
|---|---|
| **② -a（推荐）** 增一列 `EventStateChanges`，**只承载 `activeEvent` / `eventOptions`** | 保住「唯一写入入口」与刷新那一笔的原子性；`activeCombat` 的写入通道仍未明写，两条同形的路各走各的 |
| **② -b** 增同一列，并**把 `activeCombat` 一并收进来** | 三个事件内中间态一条通道、一套纪律，最干净；代价是要动 `combat-service.md` 的战斗存档段（本问题的范围之外，需你点头才动） |
| **② -c** 不增列，由 life-cycle-service / combat-service 直写 `CharacterProfile` | 零 schema 增量；代价是刷新那一笔的「`-jade` + 新库存」**无法保证同一事务**，而这正是漏洞所在 —— **不推荐** |

**推荐 ② -b，其次 ② -a。** 判据是既有的「施加语义根本不同就分列」；选 ② -b 只是把同一条纪律一次性覆盖到形态相同的第二个块上，避免长出两套写入纪律。

### ③ Explore 揭示是否需要一个独立的存档点 / `Immediate` flush？

- **③ -a（推荐）不新增**，随后续第一个决策点（Combat 真身 = D0 · Exchange 真身 = 面板决策点 · Travel 真身 = 收口）落盘。依据：`ct` 只在决策点被观察 ⇒ 揭示与该点之间不存在可退出窗口。
- **③ -b 新增一个揭示存档点**（`Debounced` 或 `Immediate`）。多一次写入换一层「即使进程被强杀也不会重看一次揭示」的保险——但强杀那一路本就回落到最近决策点，重进后重看一次揭示**只重看**、不改真身（`RevealedEventId` 在物化时就已定），损失仅是转场动画重播一次。

**推荐 ③ -a。**

### ④ RNG 同事务不变式怎么落笔？

- **④ -a（推荐）** 只落一条不变式 +一条恢复自校验（「凡消耗了子流随机的提交，该子流 `State` / `DrawCount` 在同一次原子写内更新」），形态问题留给它自己那一轮。
- **④ -b** 现在就把 `Rng` 块纳入 `EventStateChanges`（或另开一列），一次性收口形态。牵动 `ActiveCombat` 与四条子流的全部写入点，**范围明显超出本问题**。

**推荐 ④ -a。**

### ⑤ 当前批的载体字段名与归属

`eventOptions`（与 `pastEvent` 平级、复数无 `s` 前缀风格沿用本库既有的 `pastEvent` / `disabledAbility` / `plotKeyPoint` 单数命名？）——**本草稿按 `eventOptions` 书写**，但命名与排位应与 `CharacterProfile` schema 那一路统一裁决；若那一路偏好单数风格，改名为 `eventOption` 会与「一批」的语义冲突，建议保留复数或改用 `eventOptionBatch`。**这是一个命名取向，不影响任何一条不变式。**
