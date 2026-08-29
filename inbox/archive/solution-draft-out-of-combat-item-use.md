---
type: solution-draft
date: 2026-08-28
question: 战斗外道具（`UsableScene = OutOfCombat`）被使用时，是否单独构成一个存档点；以及在事件之外使用时没有 `PastEventEntry` 可挂，痕迹落点为何。
source: open-questions/03-adventure-event-types.md → 战斗外道具的使用入口未设计（08-17f 新增 · 承重）
targets: systems/character-profile/item/_index.md · systems/services/profile-service.md · systems/services/life-cycle-service.md · systems/services/sync-service.md · systems/character-profile/_index.md · systems/adventure-event/common-properties.md · systems/common-properties.md · ux/screen-flow.md
counterpart: backend-design-documents/inbox/solution-draft-out-of-combat-item-use.md
status: distilled
reviewed: 2026-08-28 — 批量合并 interview，六题全取推荐项（本稿相关：Q1 新列 `ItemElements` 为准 · Q2 单一门面 `UseItemOutOfCombat` · **Q3 `ItemUseEntry` 收为五字段，`LifeSpanAfter` / `ChargesAfter` 两个派生字段都不写、`ADR-0021` 一字不改**）。草稿两项取向（加载期禁令 C · `pastItemUse` 分列两条序列）按 08-28 评审裁决落笔；张力 2 经核查前提不成立，无需改写任何 ADR。与后端对侧草稿同批成对采纳。
distilled-to: handoffs/2026-08-28-out-of-combat-item-use-savepoint-and-trace.md
---

# 方案草稿 — 战斗外道具使用的存档点归属与痕迹落点

## 问题

`UsableScene = OutOfCombat` 的道具，其**使用入口已定**：储物袋面板内、详情卡片上的「使用」键（`ux/screen-flow.md`）。剩下两问：

1. **一次使用是否单独构成一个存档点？**（挂在「决策点粒度」上——ADR-0036 的决策点公理为事件内的流程而写，而这一次使用发生在流程之外。）
2. **痕迹落点未定。** 在事件之外使用时**没有 `PastEventEntry` 可挂**：`AppliedChange` 是「本次事件的最终账」，而这一次消费不属于任何事件。后果是**元进程的寿元曲线会出现一段无痕迹的回升**——补天丹一类的回寿法宝正是 `UsableScene = OutOfCombat` 的第一个具体条目形态（`ADR-0066` / `answer-logs/log-lifespan-gain-paths.md`），它的 `+n` 会让下一条 `PastEventEntry.LifeSpanAfter` 凭空变高而无从解释。原问题把落点指向 `Source`，并指出「`Source` 只挂在 `Remove` 上，扣 `Charges` 没有对应成员可用」。

**推演过程中另外触到一处此前未被记下的空缺（承重，见「建议方案 ③」）：`ProfileChangeSpec` 当前的十一列没有任何一列能表达「扣一份道具实例的 `Charges`」。**

- `systems/character-profile/_index.md` 的字段表把 `magicPack` 的**写入通道登记为 `AbilityElements`**——那一列的语义是「集合成员操作：幂等增删、无量纲」，`Op` 值域为 `Grant` / `Remove` / `Disable`，**它表达的是「持有 / 不持有」，表达不了「把某份实例的 `Charges` 减 1」**。
- `profile-service.md` 的 API 表另有一行门面 `ApplyResult ConsumePlayerItem(string itemId, int count = 1)`（失败语义「次数不足 → `ApplyResult.Fail`」），但**未写明它内部组装哪一列 spec**；且它**只覆盖账号级古宝**，轮回级法宝的次数扣减连门面方法都没有。

⇒ 「古宝 / 法宝使用次数的扣减即时经 `ProfileManager.TryApply` 写档」这条已定纪律**没有可落地的 element 形态**，与「一切写入经 `TryApply`」之间有一段未接上的线。它同时挡住本问题的两问（第 2 问的痕迹内容就是这条 element）。

## 约束（来自既有设计）

**入口与发生时机**

- 储物袋**入口挂在角色状态条上、只出现于 EventOption 选择界面**（`systems/character-profile/item/_index.md` · `ux/screen-flow.md`）。
  **推论（承重）：战斗外道具的使用恒发生在批次层、事件之外，`CharacterProfile.activeEvent` 在使用时刻恒为 `null`。** 不存在「事件之内使用战斗外道具」这条路径。
- 储物袋是**跨两个持久层的呈现视图**（`ADR-0097`）：法宝 `CharacterProfile.magicPack` 与古宝 `PlayerItem` 同屏，条目带 `AbilityScope`。⇒ 同一个「使用」键要同时覆盖两层。

**存档点与决策点**

- **绝不回退存档点；本地存档点与 push 解耦**（`ADR-0032`）。
- **决策点公理**：状态机即将停下来等玩家输入的时刻，且该时刻之前消耗的随机已全部反映在持久化的 RNG `State` 里（`ADR-0036`）。非战斗四类的决策点**不触发第二次写入**，只是 `ct` 的观察位。
- **一次 `TryApply` 提交 ⇒ 一次本地原子写；push 另计**（`systems/services/sync-service.md`）。「不新增存档点」在全库一律读作「不新增决策点 / 不新增存档点类型」，**从不表示「这一次变更不落盘」**。
- **立即 flush 清单五项**：篇章边界 · 轮回结束 · 角色 `defeated` · 进入战斗前 · 应用失焦 / 挂起。
- `SavePointReason { CycleStarted, EventResolved, ChapterBoundary, CycleEnded, MetaChanged }`；`PushPolicy { Debounced, Immediate }`。成员名与 `Source` 同档对待——**第一批存档写下前冻结**（`sync-service.md`）。
- **事件内的主动消费即时提交**，两条判据缺一不可：① 玩家主动按下的一次消费；② 不即时写就开出「退出重进即回滚」的窗口（`ADR-0020`）。

**痕迹与账**

- `PastEventEntry.AppliedChange` = **本次事件的最终账**（`ADR-0021`）；收口那一次 spec + 事件内逐笔已提交的 spec 累加。**累加时剔除装整块状态快照的列**（当前即 `EventStateChanges`）；**恒不含 `TraceElements`**（自指防呆）。
- 痕迹判据：**重算不出来且有消费方的存**。`LifeSpanAfter` 是该判据的**明示例外**（4 字节 × 200 条换掉一次全序列重放），**写明不是先例**。
- `TraceElements`：序列尾部只追加、载荷是一整个 `PastEventEntry`、**一次事件恰一条**（同批两条即组装缺陷）、绝不走 modifier pipeline。

**`Source` / `Charges` 的既有形态**

- `Source` 九值 + 兜底 `Unknown`；**成员名与 code 双双冻结、永不复用**；`ExchangeSell` / `PackSell` 记的是「怎么没的」，**只出现在 `Op == Remove` 上**。`PackSell` **一个字节也不进存档**（只进 `TryApply` 可追溯性日志），其代价「事后不可重建」被明写接受（`systems/common-properties.md`）。
- 持有条目 `CharacterItem(string ItemId, int Charges, bool Status, Source SourceCode)`；**`Charges` 允许取 `0`**（储物袋「已耗尽」筛选 chip 读它），无限法宝恒为 `-1`（`systems/player-profile/_index.md`）。**同 `ItemId` 多份 = 多个元素，条目上没有实例 Id。**
- `ProfileChangeSpec` 当前十一列：`Elements` · `AbilityElements` · `Stats` · `StatusChanges` · `DeckElements` · `PlotElements` · `EventStateChanges` · `RngElements` · `TraceElements` · `SettingChanges` · `CodexElements`。分列判据 = **施加语义根本不同就分列**，**列表数不进承重表述**。
- 回寿法宝：`Scope = Character` · `UsableScene = OutOfCombat` · `Charges` 为有限正整数 · ability 产出 `ChangeElement(CostKey.LifeSpan, +n)`（`ADR-0066`）。**回寿数字的展示与 `selectCost` 同一个开关**：Band 0 / Band 1 定性、Band 2 才给精确 `+n`。

---

## 建议方案

### ① 一次使用**不构成决策点**，但**构成一次即时提交**（本地原子写）

`[既有推演]`

逐条对判据：

| 判据 | 战斗外道具使用 | 结论 |
|---|---|---|
| 决策点公理「状态机即将停下来等玩家输入」 | 使用发生在批次层，`AdvanceEventAsync` 未在运行、无状态机在推进 | **不是决策点** |
| `ct` 的观察位 | 没有进行中的长流程可取消 | **不是取消点** |
| 即时提交判据 ①「玩家主动按下的一次消费」 | 成立（点「使用」键） | ✅ |
| 即时提交判据 ②「不即时写就开出退出重进即回滚的窗口」 | 成立：不写则玩家可「用丹 → 退出 → 重进」无限回寿 | ✅ |

⇒ 两条即时提交判据同时成立 ⇒ **一次 `TryApply`，随之一次本地原子写**（「不允许提交了但不落盘」）。

**因此它不进任何既有决策点清单**——D0–D7（战斗内）与 R1 / R2 / X1 / X2 / X3（非战斗四类事件内）都是**事件内**清单，而这一次发生在事件之外。建议在 `life-cycle-service.md`「非战斗四类的事件内决策点」小节后**另起一行注记**：「批次层（EventOption 选择界面）的储物袋操作——**战斗外道具使用**与**随售**——不是事件内决策点，它们是独立的即时提交」。

**三条连带纪律（均为既有约定的直接落地，不新增机制）：**

- **使用不触发 `RefreshAfterEvent`，当前批 `eventOption` 一字不变。** 重算会消耗 `map` 子流 ⇒ 它当场变成一个真的决策点，并开出「用一颗丹刷新这一批事件」的通道。重算的既定触发点只有 `StartCycle` 与 `eventEnd`，本方案不加第三个。
- **使用后照跑终态判定**（复用 life-cycle-service 那个私有方法，`finaleFailed = false`）。战斗外道具不限于回寿，一件扣资源的道具能把某条资源打到 `Min`；不判定就会出现「资源触底但角色仍 `ongoing`」。判负 → `DefeatCharacter` → 落既有 `defeated` 的 `Immediate` flush，**这不是新规则**。
- **使用不计软阻塞闸门**（闸门只数事件级存档点），与事件内即时提交同款。

### ② push 走 `Debounced`，并新增一个 `SavePointReason` 成员 `InventoryChanged`

`[既有推演]`

**policy = `Debounced`：** 它不落在立即 flush 清单五项内，且被「应用失焦 / 挂起」那一条天然兜住——这与「账号级设置变更走 `Debounced` + 不新增 flush 点」的完整论证逐字同构（`sync-service.md`）。本地已原子写 ⇒ 进度不丢，push 迟到只影响云端新鲜度。

**reason = 新增成员 `InventoryChanged`（第六值）：**

- 事件内的即时提交（X1 / X2 / 古宝次数 / 血 mana）其 diff 由**所在事件收口那一次 `EventResolved`** 的防抖窗口带走；批次层的这一次**没有所在事件**，上一次 `EventResolved` 的窗口早已过 ⇒ 它必须自己发一次 push，必须自己带一个 reason。
- **不复用 `EventResolved`。** `reason` 驱动日志、重试策略与合并窗口；用「事件已结算」标注一次事件之外的操作，会让「这次 push 是哪来的」在日志与后端 reason 统计上**永久不可分辨**。依据是 `Source` 清单已经写过的那条非对称论证：**细了可以永远不用（成本恒为零），粗了要补回来得追加新成员且老数据无法回填**。
- **成本 = 一个枚举成员，当前无线上存档 ⇒ 零迁移**；成员名冻结纪律照常适用（第一批存档写下前冻结）。
- **它同时补上随售的同一个洞。** `Source.PackSell` 已定，但「随售那一次提交用哪个 reason」在本库同样空着——两者都是批次层的储物袋操作，**一个成员覆盖两处**。

### ③ 新增 `ProfileChangeSpec` 的第十二列 `ItemElements`，承载 `Charges` 的扣减

`[既有推演]`（前置：这是回答第 2 问的必要条件——痕迹的内容就是这条 element）

现有十一列无一装得下「扣一份实例的次数」：`Elements` 只装 `CostKey` 标量资源（表已「与 `CostKey` 全部成员双向满射」，加一个 `CostKey` 成员即破坏该满射，且它没有 `Min` / `Max` / `DepletionDefeat` 可填——上界是逐条目的 `ItemData.Charges`，不是一个常量）；`AbilityElements` 是**集合成员操作**（幂等增删、无量纲、`Grant`/`Remove`/`Disable`），扣次数**有量纲且不幂等**；`StatusChanges` 绑定 `CharacterProfile.Status` 的规则字段。按「施加语义根本不同就分列」⇒ **分列**。

```csharp
public readonly record struct ItemChargeElement(
    AbilityScope Scope,      // Character → CharacterProfile.magicPack；Player → PlayerProfile 的古宝列表
    string       ItemId,     // 指向 ItemData.Id
    int          Delta);     // 恒为负（消耗）。首批只开消耗向，见下
```

- **语义 = 按 `(Scope, ItemId)` 选定一份实例、对其 `Charges` 施加带符号增量，施加后钳制到 `[0, ItemData.Charges]`。**
- **实例选取规则（纯函数 · 承重）：** 持有条目上**没有实例 Id**（`CharacterItem` 是 `readonly record struct`，同 `ItemId` 多份彼此值相等），而储物袋按 `ItemId` 堆叠 `×N`、玩家点的是堆叠而非某一份 ⇒ 必须有一条确定性规则。
  **取同 `(Scope, ItemId)` 中 `Charges > 0` 且 `Charges` 最小者；并列取存档列表中靠前者；`Charges == -1`（无限）的实例不参与选取。**
  纯函数 + 只依赖存档列表顺序 ⇒ **同一份 spec 重放两次得同一结果**，满足「`AppliedChange` 可直接重放」。取最小非零是为了让可用次数尽快收敛到少数几份、堆叠的 `×N` 与「已耗尽」chip 的读数可预期。
- **无限法宝（`Charges == -1`）使用时不产出本 element**（组装方按上面的选取规则得空 ⇒ 不组装）。
- **`Delta > 0` 首批一律拒绝**（必需缺失 → `PushError` + 整批拒绝）：「古宝次数如何补充」是既有待答项（`systems/player-profile/player-item/_index.md`），在它答定前不开正向书写位——留一个无人组装的口子只会被误用。
- **恒不经 modifier pipeline。** 一条法则若能改写次数扣减，古宝「总量被次数封死」这条付费分工当场失效——与 `BundleRedeemedOrdinal` 两个修正列必须为空同源同重。
- **`ItemElements` 在 `SelectCost` 内恒为空**，与 `AbilityElements` / `DeckElements` / `PlotElements` / `EventStateChanges` / `SettingChanges` / `CodexElements` 同款不变式、独立成行。理由同构：成本侧只放**可如实计价的量**，而「扣一次道具次数值多少寿元」无法回答。
- **连带收益（零改动）：战斗内使用道具的次数扣减自此也有了 element 形态**，「消耗即时经 `ProfileManager.TryApply` 写 CharacterProfile」这条已定纪律不再悬空；战斗侧流程一字不改（它本就是一次即时提交）。

**施加失败语义（并入 `profile-service.md` 的表）：**

| 情形 | 语义 | 处置 |
|---|---|---|
| `(Scope, ItemId)` 无任何持有实例 | 可选缺失 | `PushWarning` + 该 element 空操作，不整批失败（与 `Remove` 目标不在持有列表同档） |
| 全部实例 `Charges == 0` | 可选缺失 | `PushWarning` + 空操作（UI 本不该让它可按，这是防御位） |
| `ItemId` 经 `ContentRegistry` 解析不到 | 必需缺失 | `PushError` + 整批拒绝（悬空 `Id` 写进 Profile 会污染存档） |
| `Delta > 0` | 必需缺失 | `PushError` + 整批拒绝（首批无补充机制） |
| `Delta == 0` | 必需缺失 | `PushError` + 整批拒绝（空操作 element 是组装缺陷） |
| `ItemElements` 出现在 `SelectCost` 内 | 必需缺失 | `PushError` + 整批拒绝（不变式） |

**可追溯性日志（非告警）：** `[ProfileManager-TryApply] itemCharge scope=Character id=xxx delta=-1 after=2`。

**门面收敛：`ConsumePlayerItem` → `ConsumeItem(AbilityScope scope, string itemId, int count = 1)`**

`[既有推演]` 现有门面 `ApplyResult ConsumePlayerItem(string itemId, int count = 1)` 只覆盖账号级古宝，而**同一个「使用」键要同时服务两层**（储物袋是跨两层的呈现视图，`ADR-0097`）。为法宝再开一个 `ConsumeCharacterItem` 会重演「按类分裂的枚举 / 方法」——`PowerScope` / `ItemScope` 合并为 `AbilityScope`、`Source` 不按类拆成四个，都是同一条纪律的先例。故**收敛为单一门面，用已是全库两层路由键的 `AbilityScope` 选层**。

- **内部实现 = 组装 `ItemElements` + （事件之外时）`ItemUseElements`，交 `TryApply`**，「一切写入经 `TryApply`」自此无例外——这正是既有文本缺的那一句。
- **失败语义分两层，不重复：** 门面在组装前查一次持有与剩余次数，**不足 → `ApplyResult.Fail`**（业务失败，绝不抛；沿用现有 `ConsumePlayerItem` 的语义，供 UI 灰显「使用」键）；element 层那两条「可选缺失 + `PushWarning` + 空操作」是**防御位**，正常链路不可达。
- **改名当前零成本**（无实现、无线上存档、非跨边界契约枚举）。

### ④ **不新增任何 `Source` 成员**——那条路既走不通、也不需要走

`[既有推演]`（这一条直接答结原问题的后半句「扣 `Charges` 没有对应成员可用」）

三条各自独立成立：

1. **扣 `Charges` 到 0 不产生 `Op == Remove`。** 持有条目的 `Charges` **允许取 `0`**，且储物袋的「已耗尽」筛选 chip 正是读 `Charges == 0`（`systems/player-profile/_index.md` · `ux/screen-flow.md`）⇒ **耗尽的道具仍留在储物袋**，条目不移除。没有 `Remove`，就没有 `Source` 的挂载位。
2. **`Source` 的语义是「这条持有条目怎么来的 / 怎么没的」。** 扣一次次数既不是「来」也不是「没」——它是持有条目上一个数值字段的变更，与 `SourceCode`（写入时刻 = 授予时刻，此后不变）正交。
3. **即便加了成员，它也承载不了本问题的消费方。** `PackSell` 的先例明写：这类成员**不进存档**，只进 `TryApply` 可追溯性日志，其代价「事后不可重建」被接受。而本问题的消费方是**元进程的寿元曲线**——它读的是存档，不是日志。**用 `Source` 解这一半，是把一个存档态问题交给一条日志。**

⇒ **`Source` 九值 + 兜底保持不变**，合法子集表不加行，冻结纪律不受触动。

### ⑤ 痕迹落点 = `CharacterProfile.pastItemUse`（新序列），经新增列 `ItemUseElements` 写入

`[既有推演]` + `[通行做法]`

痕迹判据（`ADR-0021`）：**重算不出来且有消费方的存**。一次事件之外的道具使用**两条都满足**——它由玩家在批次层的即时操作产生，重算不出来；消费方是元进程的角色履历寿元曲线（以及诊断「这段回升哪来的」）。

```csharp
public sealed record ItemUseEntry(        // 事件之外的道具使用痕迹：immutable，只追加，落存档
    int               Seq,                // 角色内单调递增，首条为 0；与 pastEvent 的 Seq 是两条独立序列
    int               AfterEventSeq,      // 使用时刻已完成的最后一条 PastEventEntry.Seq；首个事件之前 = -1
    string            ItemId,             // 溯源模板（disabled 条目照常解析）
    AbilityScope      Scope,              // Character（法宝）/ Player（古宝）—— 同一入口两层持有物，须区分
    int               ChargesAfter,       // 被选中那一份实例使用后的剩余次数
    ProfileChangeSpec AppliedChange,      // 这一次使用的账：就是那一次 TryApply 的入参
    int               LifeSpanAfter);     // 使用后剩余寿元 —— 与 PastEventEntry 同款的明示例外
```

- **写入通道 = `ProfileChangeSpec` 新增列 `ItemUseElements`**（语义：序列尾部只追加、载荷 `ItemUseEntry`、不幂等、无键、绝不走 modifier pipeline、`SelectCost` 内恒为空）。与 `TraceElements` 同形但**不合并**，理由见「与既有决策的张力」。
- **`AppliedChange` 的两条既有不变式原样适用且必须扩到本列：** 它**恒不含 `TraceElements` 也恒不含 `ItemUseElements`**（否则自指），**恒不含 `EventStateChanges`**（整块状态快照不进账）。落为 `ProfileManager` 入口断言。
- **`Seq` 连续性由入口校验**（`Seq != 末条 Seq + 1`，空列表时 `!= 0` → 整批拒绝），与 `pastEvent` 同款、同理由。
- **`AfterEventSeq` 校验**：`> pastEvent` 末条 `Seq` 或 `< -1` → 必需缺失，`PushError` 带 `characterId` + `seq`。
- **一次使用恰一条**，同批两条即组装缺陷（与 `TraceElements` 同款）。
- **不写进 `pastEvent`、也不并进下一条 `PastEventEntry.AppliedChange`。** 后者会污染「本次事件的最终账」这条已定语义，且**使用后再无事件时痕迹永远落不下来**（玩家用完丹就退出）。
- **曲线的读取口径（消费侧，不新增字段）：** 履历寿元曲线 = `pastEvent[].LifeSpanAfter` 与 `pastItemUse[].LifeSpanAfter` 按 `(AfterEventSeq, Seq)` 归并；序列尾部（最后一次使用之后尚无事件）取 `Status.lifeSpan` 当前值补一点。**回升段自此可解释。**
- **读档校验：** `ItemId` 经 `ContentRegistry` 解析不到 → **可选缺失** → `PushWarning` + 该条降级为「仅标识可读」，**不阻断读档**（与 `PastEventEntry.EventId` 逐字同款——历程是历史记录）。`Seq` 不连续 / 重复 → 必需缺失 → `PushError` 带 `characterId` + `seq`。
- **体积：** 单条 ≈ 一两条 element + 五个小字段 ≈ 100–200 B；条数由 `Charges` 与内容编排（出现频率 / 库存深度 / 定价）天然封顶，**不设硬上限**——与「回寿总量护栏落在内容编排面、规则层不设持有上限」（`ADR-0097`）同一条纪律。
- **账号级古宝的使用痕迹同样落在角色档**（`Scope = Player` 标识之）。理由：这条痕迹的消费方是**这个角色这段轮回的曲线**。**代价明写：** 轮回清理时它随之消失，古宝的跨轮回使用史不留存；需要时的落点是 `PlayerStatistics` 的聚合项，**首批不加**（与「首批一格计数字段都不加」同款）。

### ⑥ 呈现：使用后就地反馈，数值走既有寿元 Band 门控

`[既有推演]`

- 使用在储物袋面板内**就地生效并就地反馈**（条目 `Charges` 立即 `-1`、`×N` 与「已耗尽」chip 立即重算），**不新开屏、不新增弹层**——与「售出后条目直接移出列表」同一处交互层级。
- **回寿数值照既有门控**：Band 0 / Band 1 只给定性文案（「服之可补益寿元」），**Band 2 才由 UI 追加一行精确 `+n`**。这是寿元档位表**已登记的第六个消费方**，不新增字段、不新增开关。
- 文案走 `PROFILE_` 分区 / `profile.csv` 普通键，**不占 `ERR_` 前缀**（本地业务提示，没有后端 `code`），与售出文案同款。

---

## 具体形态（可 derive 的落地面）

**新增 / 改动一览**

| # | 落点 | 改动 | 是否 bump schema |
|---|---|---|---|
| 1 | `ProfileChangeSpec` | 新增列 `ItemElements`（`ItemChargeElement`） | **是** |
| 2 | `ProfileChangeSpec` | 新增列 `ItemUseElements`（`ItemUseEntry`） | **是**（与 1 同一次 bump） |
| 3 | `CharacterProfile` | 新增字段 `pastItemUse: List<ItemUseEntry>` | **是**（同上） |
| 4 | `SavePointReason` | 新增成员 `InventoryChanged` | 否（跨边界枚举，不落存档 schema；成员名须在第一批存档前冻结，且**与后端同批确认**——枚举值以名逐字序列化） |
| 5 | `profile-service` API 表 | `ConsumePlayerItem` → `ConsumeItem(AbilityScope, string, int)`，并写明内部组装哪两列 | 否 |
| 6 | `character-profile/_index.md` 字段表第 13 行 | `magicPack` 的写入通道由 `AbilityElements` 改为 **`AbilityElements`（持有）+ `ItemElements`（次数）** | 否（表述订正） |
| 7 | `player-profile` 侧古宝字段 | 同上，写入通道补 `ItemElements` | 否 |
| 8 | `Source` | **不变** | — |
| 9 | `CharacterItem` / `PlayerItem` / `ItemData` | **不变** | — |
| 10 | `PastEventEntry` | **不变** | — |
| 11 | `EventOutcome` | **不变** | — |
| 12 | `CostKey` / `ResourceElements` 表 | **不变**（不为 `Charges` 加成员，见 ③ 的否决理由） | — |

**迁移：** 当前无线上存档 ⇒ **空迁移**，走既有 `MigrationManager` 骨架。三处改动合并为一次 bump。

**存档 schema 增量（`CharacterProfile`）**

```
pastItemUse : ItemUseEntry[]        // 单数字段名，与 pastEvent / disabledAbility / achievement 同形
```

**触发面汇总**

| 面 | 取值 |
|---|---|
| 决策点 | **不是**（不进 D0–D7，也不进 R1 / R2 / X1 / X2 / X3） |
| 本地原子写 | **是**（一次 `TryApply` ⇒ 一次原子写，既有通则） |
| 存档点类型 | 复用即时提交路径；push 侧新增 reason `InventoryChanged` |
| push policy | `Debounced`（例外：若使用致资源触底 → 走既有 `defeated` 的 `Immediate`） |
| 软阻塞闸门 | **不计**（闸门只数事件级存档点） |
| RNG | **不消耗任何子流**；若日后出现带随机效果的战斗外道具，该次提交须同批带 `RngElements`（既有不变式，不为本方案开例外） |
| eventOptions 重算 | **不触发**，当前批一字不变 |
| 终态判定 | **照跑**（复用私有方法，`finaleFailed = false`） |

---

## 后果

- **`ProfileChangeSpec` 由十一列增至十三列。** 既定纪律明写「列表数不进承重表述——它随字段族增长」，故这不违反任何约定；但 `profile-service.md` 那一长条列举需同步扩写，`architecture.md`「共享核心类型」的类型定义同增两条。
- **一次存档 schema bump**（三处改动合并），空迁移。
- **`AppliedChange` 的自指防呆断言从「只覆盖 `TraceElements` 一列」扩为覆盖两列。** 原文明写「这条断言只覆盖 `TraceElements` 一列」，需改写。
- **`systems/adventure-event/common-properties.md`「寿元回复通道 B」的一处措辞需订正：** 现文写「使用时即时经 `ProfileManager.TryApply` 写档（**事件内部的主动消费即时提交**）」。按入口的既定形态，战斗外道具的使用**恒发生在事件之外**，它不是「事件内部的主动消费」——判据①②仍成立，但归类应改为「批次层的主动消费即时提交」。**这是本方案发现的一处既有文本失真，不是本方案引入的。**
- **`answer-logs/log-lifespan-gain-paths.md` 的「零结构增量」结论被本方案部分推翻。** 该处写「不新增字段、不新增 element、不 bump 存档 schema」；本方案需要两列 + 一个字段 + 一次 bump。原结论成立的前提是「使用走既有 `ChangeElement(CostKey.LifeSpan, +n)`」——**那一半仍然成立**（寿元的施加路径确实零增量），增量全在**次数扣减**与**痕迹**两侧，而这正是当时挂起为待答项的那两问。answer log 不需要改写（它已列明「战斗外道具的使用入口」是随该次答定新增的待答项），但 `item/_index.md` 与 `adventure-event/common-properties.md` 中「零结构成本」的措辞需要限定作用域。
- **随售（`Source.PackSell`）顺带获得一个 reason。** 它此前没有——这是本方案的免费副产品，不改随售的任何既有规则。
- **战斗内道具使用的次数扣减自此有了 element 形态**，`combat-service.md` 无需改动（它本就是一次即时提交），但该文档中提到「次数即时写 Profile」的几处可回链新列。**战斗内使用不写 `pastItemUse`**（它在事件内，账已由 `AppliedChange` 承载）；组装判据可机械判定：**`activeEvent == null` ⇒ 写 `ItemUseElements`；否则不写**。
- **`SavePointReason` 增员是一次跨边界改动。** 该枚举以**成员名逐字序列化**上行（`sync-service.md`），故新增成员须在 `backend-design-documents/` 侧留一条承接项（后端的 reason 取值识别面）。**本草稿不替后端落笔**——若采纳，应按跨库纪律在后端库同步登记一条待答 / 承接项。

---

## 备选方案（已考虑并否决）

- **把使用记成一条 `PastEventEntry`，`EventOutcome` 加一个成员** — 否决：① `PastEventEntry` 的必填字段（`EventId` / `InstanceId` / `BatchId` / `Priority` / `SelectCost` / `Unchosen`）对一次道具使用**全无意义**，塞空串是坏形状；② 既有明文「枚举成员的增删牵动存档迁移」，且该枚举刻意保持四值不为分支预留；③ 会打破 `TraceElements`「一次事件恰一条」的入口校验。
- **把批次层已提交的 spec 累加进**下一条 **`PastEventEntry.AppliedChange`** — 否决：① 污染「本次事件的最终账」这条已定语义（`ADR-0021`），且该语义已因累加事件内逐笔提交而付出过一次「不能再机械断言」的代价，不宜再放宽；② **使用后再无事件时痕迹永远落不下来**；③ 需要一个跨事件的暂存字段（`pendingBatchChange`）才能实现，反而比独立序列更贵。
- **新增一个 `Source` 成员（`Consumed` / `ItemUsed`）** — 否决：见「建议方案 ④」三条，其中第 3 条是决定性的——`Source` 不进存档，承载不了存档态的消费方。
- **不留痕迹，按 `PackSell` 先例明写代价** — 否决：`PackSell` 丢的是「这件法宝是随手卖掉的」这条**旁证**；本处丢的是**一条承重压力线曲线的可解释性**，两者量级不同。且当前是**纯加法窗口**（`XxxData`、`.tres`、存档存量全为零），「加法窗口在写下第一批存档时关闭」这条既有判断在此逐字适用。
- **给 `AbilityChangeElement` 加一个 `Op = ConsumeCharge`** — 否决：`AbilityElements` 的施加语义是「集合成员操作：幂等增删、无量纲」，扣次数**有量纲且不幂等**；按「施加语义根本不同就分列」应分列，塞进去会让该列的失败语义表出现一批只对某个 `Op` 成立的行。
- **给 `CharacterItem` / `PlayerItem` 加一个实例 `Id` 以精确定位扣哪一份** — 否决：四类持有条目**全族统一**为 `readonly record struct` 且键名为 `<Kind>Id`（指向内容条目），加一个自身 `Id` 会打破全族一致并给每份实例增加一个存档字段；而确定性选取规则以零字段代价解决同一问题。
- **为战斗外使用新增一个独立的 flush 点（`Immediate`）** — 否决：与「账号级设置不新增 flush 点」同一条论证——它被「应用失焦 / 挂起」兜住，且本地已原子写、进度不丢。
- **给 `CostKey` 加一个 `ItemCharge` 成员，走既有 `Elements` 列** — 否决：① `ResourceElements` 表已明写「与 `CostKey` 的全部成员**双向满射**」，加一个非资源成员即破坏该满射；② 表的每行要填 `(Min, Max, DepletionDefeat, CostModifier, GainModifier, AllowedOps)`，而次数的上界是**逐条目的 `ItemData.Charges`**、不是一个可写进表里的常量；③ `Elements` 按 `Key` 索引一个标量，装不下「哪一层 + 哪个 `ItemId` + 选哪一份实例」。
- **为法宝另开一个 `ConsumeCharacterItem` 门面** — 否决：按类分裂的方法 / 枚举在本库已被否决过两次（`PowerScope` / `ItemScope` 合并为 `AbilityScope`；`Source` 不按类拆成四个），而 `AbilityScope` 恰是全库既有的两层路由键。

---

## 与既有决策的张力

1. **`ItemUseElements` 与 `TraceElements` 的施加语义同形（序列尾部只追加），按「施加语义根本不同就分列」判据，两者本可合并。**
   不合并的理由：`TraceElements` 的两条入口校验（**一次事件恰一条**、**`AppliedChange` 恒不含本列**）以及「载荷直接是 `PastEventEntry`，不建镜像类型」都**绑定在 `PastEventEntry` 这个载荷类型上**；合并需要把载荷改成一个二成员 sum type，并把两条校验改成按载荷类型分支——**那正是分列要消掉的东西**。
   **代价明写：** 这是本库第一次出现「语义同形但仍分列」的两列，判据的表述可能需要补一句「载荷类型不同且校验绑定在载荷上时同样分列」。**建议提请用户裁决**（见「仍需用户决定」第 ②）。

2. **`answer-logs/log-lifespan-gain-paths.md` 与 `ADR-0066` 记的「零结构成本：不新增字段、不新增 element、不 bump 存档 schema」在本方案下不再全称成立。**
   本方案不推翻那条结论的**成立范围**（寿元的施加路径确实零增量），但两处文本的措辞是全称的。**处置建议：不改 ADR-0066 的决策本体，只在 `item/_index.md` 与 `adventure-event/common-properties.md` 的相应句子上限定作用域**（「寿元的施加路径零增量；次数扣减与痕迹两侧的结构成本随战斗外使用入口一并落定」）。若用户认为这构成对 ADR-0066 的实质修改，则应改 ADR 本体——**由用户裁决**。

3. **`SavePointReason` 增员与「不新增 reason」的既有克制取向。**
   `sync-service.md` 为设置变更明确写下「不新增 reason、不新增 flush 点」，其理由是「既有机制已经覆盖」。本处**没有**既有机制覆盖（批次层没有所在事件的窗口），故不构成同一情形；但两处并列时可能被读成不一致，建议在 `sync-service.md` 里把设置那一条的理由句**明确为条件式**（「当既有 reason 能如实描述该次提交时不新增」），而不是读作一条无条件禁令。

---

## 前置依赖

- **`ItemChargeElement.Delta > 0` 的正向书写位**依赖「**古宝的次数补充机制**」这一既有待答项（`systems/player-profile/player-item/_index.md` · `open-questions/` 的元进程持久化范围一条）。本方案首批只开消耗向；补充机制答定后放开正向，**是把一行校验从 `PushError` 改为允许，无结构改动**。
- **战斗外道具的「其余效果形态」**（回寿之外的战斗外效果、道具种类目录）仍未设计（`item/_index.md` 待决问题）。本方案的痕迹与写入通道对效果内容**无假设**（`AppliedChange` 装的是已定稿的 element），故**不被它阻塞**；但「仍需用户决定 ①」那条的边界取决于它。
- **本方案不解除**「回寿法宝的总量护栏在内容编排面的具体口径未定」那条待答项——护栏是数量闸，本方案只解决痕迹与存档点归属。
- **`SavePointReason.InventoryChanged` 须与后端同批确认。** 该枚举以成员名逐字上行，属客户端 ↔ 后端契约面；按跨库纪律，本条采纳时应在 `backend-design-documents/` 侧落一条承接项（reason 取值识别面 + `contracts/profile-sync.md` 的取值清单），两侧互相回链。**单侧采纳即两侧不一致。** 本草稿只写客户端那一半，不替后端落笔。

---

## 仍需用户决定

**① 无限法宝（`Charges == -1`）在事件之外的使用如何处置。**
回寿法宝的 `Charges` 已被限定为有限正整数，但**其余战斗外效果**尚未设计——若出现一件 `Charges == -1` 且 `UsableScene` 含 `OutOfCombat`、又会写 Profile 的法宝，玩家可在批次层无限次点它，`pastItemUse` 会被刷成一条无界序列。

| 选项 | 后果 |
|---|---|
| A · 照常记痕迹 | 序列体积无界，只靠内容编排自律；一条设计失误就能撑爆单个角色的存档 |
| B · 无限法宝的使用不记痕迹 | 体积安全，但曲线重新出现无痕迹段——正是本问题要消掉的东西 |
| **C · 加载期禁令（推荐）** | **`ItemData.Charges == -1` 且 `UsableScene` 含 `OutOfCombat` 且其 abilities 会写 Profile ⇒ `PushError` + 条目 `Id`。** 与既有两条准入校验（`PowerData` 不得产寿元、含寿元产出者不得含 `InCombat`）**同一条判据的第三个实例**——判据都是「没有次数上限的重复消费源」 |

**推荐 C**，但它给内容侧关掉一个书写位（「无限次可用的战斗外道具」整类），且「会写 Profile」这个条件的精确边界（是否只限资源 / Status 类写入，还是含卡组 / 能力 / 剧本）取决于尚未设计的战斗外效果形态 ⇒ **边界需用户划定**。

→ **已裁决（2026-08-28 · 批量评审）：选 C —— 加载期禁令。** `ItemData.Charges == -1` 且 `UsableScene` 含 `OutOfCombat` 且其效果会写 Profile ⇒ `PushError` + 条目 `Id`。
**「会写 Profile」的边界在同批裁决下已收敛**：分片 B 的取向①同批定为「战斗外效果 = 纯 `ProfileChangeSpec` 模板」，故战斗外效果**恒**写 Profile ⇒ 该条件退化为「`Charges == -1` 且 `UsableScene` 含 `OutOfCombat` ⇒ `PushError`」，不再需要用户另行划定边界。提炼时按这条收敛后的判据落笔。

**② `pastItemUse` 与 `pastEvent` 是分列两条序列，还是合并为单一时序序列。**

| 选项 | 后果 |
|---|---|
| **A · 分列（推荐）** | 两条序列 + 两列 element；`TraceElements` 的两条入口校验与「载荷即 `PastEventEntry`」原样不动；读取侧按 `(AfterEventSeq, Seq)` 归并（一次 `O(n)` 合并） |
| B · 合并为单一序列 | `pastEvent` 元素类型变为二成员 sum type，`TraceElements` 载荷同变；读取侧免归并、`Seq` 天然全序；代价是「一次事件恰一条」与自指断言都要改成按载荷类型分支，且 `pastEvent` 这个已成文的字段语义（「修行历程」）被扩宽 |

**推荐 A**（改动面更小、既有校验零改写），但 B 在「曲线读取」这个唯一消费方上确实更直接，且能避免张力 1 里那条「语义同形却分列」的新例外。**这是一条真结构取向，两读法都自洽。**

→ **已裁决（2026-08-28 · 批量评审）：选 A —— `pastItemUse` 与 `pastEvent` 分列两条序列。** `TraceElements` 的两条入口校验与「载荷即 `PastEventEntry`」原样不动，读取侧按 `(AfterEventSeq, Seq)` 归并。
连带：张力 1 那条「语义同形但仍分列」成为本库第一个实例，判据表述需补一句（随提炼处理）。
