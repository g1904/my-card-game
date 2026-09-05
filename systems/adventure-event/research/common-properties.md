# adventure-event / research / common-properties（Research 子类型共有属性）

> Research 类 AdventureEvent 共有的属性 / 字段。顶层共有属性见 `../common-properties.md`。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **静修 / 修整语义。** Research 承载钻研 / 潜修（含并入的休养 / Rest）。结算形态、五类操作清单、产出面边界与风险档见 `_index.md`。

### 模板侧：`ResearchSlotSpec`

`AdventureEventData` 上 Research 专有的一格（`ResearchSlotSpec[]`）；`eventType != Research` 时**恒空**，否则加载期 `PushError`。

```csharp
[GlobalClass] public partial class ResearchSlotSpec : Resource
{
    [Export] public DeckOperationKind[] AllowedOperations { get; set; }  // 该槽允许出哪几类操作
    [Export] public int  CandidateCount { get; set; } = 3;               // 候选数
    [Export] public bool AllowDecline   { get; set; } = true;            // 是否允许「什么都不做」
    [Export] public bool AllowRisk      { get; set; } = false;           // 是否可掷出走火入魔风险档候选
}
```

- **`AllowedOperations` 为空 → 加载期 `PushError`**（一个出不了任何候选的槽必是漏填）。
- **`CandidateCount` 是上界不是保证**：候选池实际不足时给几个算几个（例：卡组只剩一门功法可升阶）。
- **`AllowDecline` 默认 `true`（承重）。** 与置换面板的「拒绝零代价」同构，且避免「只剩一门功法却被迫弃置」这类**内容侧死结**——内容作者不必逐条保证候选恒可执行。开局构筑事件显式填 `false`。
- **`AllowRisk` 默认 `false`**：风险档是内容作者主动开的一档，不是缺省行为。

### 物化产物：`ResearchSlot` / `ResearchCandidate`

进 `EventOption.ResearchSlots`，随批次落存档——属「物化产出的数值必进快照」那一侧。

```csharp
public sealed record ResearchSlot(                      // 定稿 · immutable
    int                              SlotIndex,
    bool                             AllowDecline,
    IReadOnlyList<ResearchCandidate> Candidates);       // 已掷定，退出重进不重掷

public sealed record ResearchCandidate(
    DeckOperationKind Kind,      // LearnTechnique / UpgradeTechnique / ForgetTechnique /
                                 // RemoveLooseCard / GrantItem
    string            TargetId,  // 功法 Id / 卡牌 Id / 法宝 Id
    int               Amount,    // Upgrade 的目标层数；不适用时 -1
    int               ManaDelta, // 附带的 manaLimit 变动，取值 { -1, 0, +1 }（已掷定）
    bool              IsRisky);  // 面板上标注为风险档；结果已定但不预先展示
```

- **`DeckOperationKind`（五值 · 面板层）与 `DeckChangeOp`（四值 · element 层）是两个枚举，不得合并。** 前者回答「玩家在这个槽里能选什么」，后者回答「卡组变更如何施加」；`GrantItem` 落 `AbilityElements` 列，故不出现在后者中。类型定义见 `systems/architecture.md`「共享核心类型」。
- **文本一律不进快照**：候选的显示名 / 描述由 UI 按 `TargetId` 现场取模板组装，与「文本类字段一律留在模板侧」一致。
- **`ManaDelta` 在物化时即已掷定并落存档。** 这是「退出重进不能重掷」的落地点，也是风险档能够成立的技术前提——面板上只标注「有风险」，不预先展示结果。
- **槽内选择不进快照。** 「玩家在槽 0 选了第 2 个候选」这个中间态**没有承载格，也不该有**——它不是物化产出、也不是即时提交，中途退出即丢失（恢复回面板初始态、候选不变），判据与「短缺标记不进快照」同款。语义见 `_index.md`。
- **`ResolveOutcome` 不新增结构**：resolver 把玩家所选候选翻译为 `DeckElements` / `AbilityElements` / `Elements` 三份 element，照常交给 `eventEnd` 那一次 `TryApply`。

### 候选取池：两条既有抽取链，零新增抽取代码

| 槽内候选 | 取池链 |
|---|---|
| **法宝三选一** | **直接复用 `GrantPoolManager`**：`TryPickGrantableMany(AbilityCarrierKind.Item, AbilityScope.Character, rng, 3)` —— 取池 → `(CarrierKind, Scope)` → 去成就限定 → 排除已持有 → 按 `RarityTier` 加权 → **无放回**抽 3 条 |
| **功法三选一（学新）** | `CultivationTechniqueData` 仓储 → `AllEnabled()` / `DrawPool<T>` → **排除 `Pool == Enemy`**（敌方专用功法，见 `systems/character-profile/deck/_index.md`「卡池划分」）→ **排除该角色修不了的功法**（灵根修习准入 `CanLearn`，见同文档「灵根修习准入」）→ **排除卡组中已持有的功法 `Id`** → 按 `RarityTier` 加权 → `PickMany(rng, 3)`（无放回） |
| **升阶候选** | 卡组内已持有、**未达层数上限**、且仍通过灵根修习准入的功法（不足 3 门时给几门算几门；一门都没有则该操作不进候选）。**准入这一层对升阶同样叠**——它只在 overlay 中途改动了灵根或功法属性时才会真正筛掉东西，处置是「不再进候选」而非没收已持有的功法 |
| **弃置 / 移除散牌候选** | 卡组内已持有的功法 / 游离散牌 |

- **法宝那一路是纯复用**：`GrantPoolManager` 已是账号级 / 轮回级能力条目的**唯一抽取处**，法宝三选一恰好是 `(Item, Character)` + `count = 3`，一行调用即可。
- **功法那一路形状与之完全同构**（`CultivationTechniqueData` 带 `Rarity`），落 `DrawPool<T>` 的第五个调用方。
- **随机源 = `RngStream.Reward` 子流的 `GodotRandomSource`，不新开子流。** `Reward` 已承载「战后奖励候选一次性抽定」这一完全同构的用途（预先掷定 + 落存档 + 绝不重抽），而奖励候选与构筑候选**从不并发**（一次只结算一个事件）；新开子流换来零隔离收益。
- **候选池不接 modifier pipeline，故不受 PlayerPower 影响。** 候选池的**权重**若可被法则推拉，等于开一条「账号级内容改写轮回级构筑运气」的通道，而它在 `ContentEnabled` / `ExclusiveSource` 之外无人校验。**唯一例外是 capability flag**（如「看见候选的稀有度」这类呈现向 flag）——那走呈现层，不改池。

### 候选短缺：加载期断言 + 取池期拦截 + 物化期降级

三道闸的层次、分界判据与取池期拦截（闸 ②）的完整形态归 `systems/services/future-event-service.md`；本处只记 Research 侧的断言与逐情形行为。

**加载期断言（闸 ①，走 `AllIncludingDisabled()` 的同一遍强校验）：** 每个 `ResearchSlotSpec` 的 `AllowedOperations` 中每一类**内容池型**操作（`LearnTechnique` / `GrantItem`），其对应的通用池条目数须 ≥ `CandidateCount` + `ResearchPoolMargin`；不足 → `PushError` + 抛。

- **余量必须存在，不能只断言「≥ 所需」**：两条取池链都含**排除已持有**，池会随玩家推进单调收缩，一个恰好等于所需的静态池在轮回中段必然短缺。取值归 `systems/balance.md`。
- **功法那一路的池须按灵根收缩后的子集断言**：准入是第二重收缩，故断言的分母不是全池，而是**该角色可修的那个子集**；口径按可修条目最少的那个灵根定。见 `systems/balance.md` 与 `systems/character-profile/deck/_index.md`「灵根修习准入」。
- **断言只覆盖内容池型操作。** 其余三类（`UpgradeTechnique` / `ForgetTechnique` / `RemoveLooseCard`）取自卡组，加载期够不着，不写断言。

**物化期的逐情形行为（闸 ③）：**

| 情形 | 行为 |
|---|---|
| 某类操作抽到 **0** 条候选 | 该操作不进本槽候选（与「一门都没有则该操作不进候选」同句处置，只是推广到内容池型两类） |
| 某类操作抽到 **0 < n < 所需** | 给几条算几条 —— 这是 `CandidateCount`「上界不是保证」的直接兑现，不是新规则 |
| **整槽候选为 0** | 该槽不进 `ResearchSlot[]`；事件照常物化（其余槽仍有候选）。**`SlotIndex` 不重排**，保留模板槽序号 |
| **全部槽皆为 0** | 闸 ② 已拦，到达此处 = 缺陷 → `PushError` + 上报，该条目本次不进批次 |

- **「不留空面板」在 Research 侧的兑现 = 闸 ② + 空槽剔除**：面板上呈现的槽必然至少有 1 条候选，配合默认 `AllowDecline = true`，玩家永远有一个可执行的动作。
- **短缺不给玩家任何提示、不新增文案键。** 玩家看到的就是候选少一点的槽，它与内容作者编排出的小槽在观感上无法区分，也不需要区分。
- **快照只记实际结果：** `ResearchSlot.Candidates` 的长度就是实际候选数，**不新增「期望数量 / 短缺标记」字段**——期望值在模板的 `CandidateCount` 上随时读得到，落一份进快照就是无用中间态（与「模板上的 outcome / effect 定义不进快照」同一条判据）。
- **日志：**

  ```
  [ContentRegistry-Validate] research pool short: event=<EventId> slot=<SlotIndex> op=<DeckOperationKind> need=<CandidateCount+margin> pool=<n>
  [FutureEvent-ResearchSlot] instance=<InstanceId> event=<EventId> slot=<SlotIndex> op=<Kind> want=<n> got=<m>
  ```

Source: `handoffs/2026-08-30-affinity-and-technique-attributes.md` · `handoffs/2026-08-30-life-lifespan-merge.md` · `handoffs/2026-08-17b-research-build-panel-and-deck-elements.md` · `handoffs/2026-08-19-pickmany-shortfall-handling.md` · `handoffs/2026-08-22-non-combat-decision-points.md` · `handoffs/2026-08-25-enemy-deck-from-techniques-and-ai.md` · `handoffs/2026-08-23g-hidden-stat-combat-boundary-event-backdrop-and-itemized-rewards.md`

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- 见 `_index.md`。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **构筑面板的竖屏呈现形态。** 与战后奖励面板**在呈现层**同构（候选纵向排列、点按选中）已定方向——**交互层不同构**：本面板是「选完全部槽再一次确认提交」，奖励面板是逐项即时领取 / 跳过（见 `systems/services/combat-service.md`）；**风险档的视觉标注与说明通道**（不得为 hover-only）未设计。→ `ux/screen-flow.md`。
- 数值格见 `_index.md` 的待决问题。

## 对应
提炼至：`.claude/knowledge/systems/adventure-event/research.md`（待建）
