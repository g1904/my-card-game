# Research 的构筑面板形态与卡组变更 element

- id: 2026-08-17b-research-build-panel-and-deck-elements
- date: 2026-08-17
- topic: systems/adventure-event/research · systems/architecture · systems/services/profile-service · systems/services/future-event-service · systems/character-profile/mana · systems/character-profile/deck · systems/services/content-service · systems/balance · terminology
- status: distilled
- distilled-to: systems/adventure-event/research/_index.md, systems/adventure-event/research/common-properties.md, systems/adventure-event/common-properties.md, systems/architecture.md, systems/services/profile-service.md, systems/services/future-event-service.md, systems/services/content-service.md, systems/character-profile/mana.md, systems/character-profile/deck/_index.md, systems/balance.md, terminology.md

## Intent（distilled）

**一句话：** Research（闭关）的机制层此前只有语义、没有形态。本次给出它的完整结算形态——**由若干决策槽组成的构筑面板**，操作清单闭合为六类，卡组变更获得语义诚实的载体 `DeckElements`，`manaLimit` 的下降有了唯一承载点（玩家自选的风险档），且**候选生成零新增抽取代码**。

### ① Research 的结算形态 = 构筑面板，由若干决策槽组成

模板持有 N 个**决策槽（slot）**；物化时为每个槽预先掷定一组候选操作；结算时玩家逐槽择一，全部选择与 `lifeSpanCost` 合并为 `eventEnd` 的**一次** `TryApply`。

- **它不是新机制，是既有决策点面板的第三个实例**（前两个：战后奖励面板、能力置换面板）。「预先掷定候选 + 玩家择一 + 并入 `eventEnd` 那一次 `TryApply`」这套形状零新增结构。
- **槽的复数形态是被开局构筑事件逼出来的**，不是为扩展预留：开局要求「一门功法 + 一件法宝，各三选一」= 同一事件内的**两个**槽。单槽形态会逼开局事件另设机制，而它已明写「不需要新机制」。
- **它与「一批只有一次操作：择一进入」不冲突**——那条约束批次层，槽是事件内部的结算结构。
- **候选掷定的时机 = 物化阶段，随 `EventOption` 落存档。** 依据是「候选须预先算定并落决策点存档，否则退出重进可以重掷」+「物化产出的数值必进快照」。这同时是风险档能够成立的技术前提。

### ② 操作清单 = 六类，闭合

| 操作 | 语义 | 载体 element |
|---|---|---|
| `LearnTechnique` | 学会一门新功法（入组，层数 = 1） | `DeckChangeElement` |
| `UpgradeTechnique` | 已持有功法层数 +1（该组牌整组替换） | `DeckChangeElement` |
| `ForgetTechnique` | 弃置一门已持有功法（含角色绑定的两门） | `DeckChangeElement` |
| `RemoveLooseCard` | 移除一张游离散牌（业障 / 单卡奖励） | `DeckChangeElement` |
| `GrantItem` | 获得一件法宝 `CharacterItem` | `AbilityChangeElement(Grant, Item, Character, id, Source.EventOutcome)` |
| `Recuperate` | 回复 `lifeTotal` | `ChangeElement(CostKey.LifeTotal, +n)` |

**`manaLimit ±1` 不单列为一种操作**——它是上述操作的**附带产出**，与「压低只以负向奖励条目的形态出现、不另立结构」一致。

**明确不在清单内的三项：** `AddLooseCard`（正向卡组增长走 `LearnTechnique`，单卡入组的既有通道是战斗奖励与事件负向奖励；业障作为负向结果进卡组走既有通道，不受此限）· 领悟法则 `PlayerPower`（合法子集表 `EventOutcome × (Power, Player)` = ❌，机械约束）· 授予神通 `CharacterPower`（技术上随时可开，语义上归战斗奖励与 Exchange 更自然，属内容口径）。

### ③ `ProfileChangeSpec` 增第五条列表 `DeckElements`

```csharp
public enum DeckChangeOp { LearnTechnique, UpgradeTechnique, ForgetTechnique, RemoveLooseCard }

public readonly record struct DeckChangeElement(
    DeckChangeOp Op,
    string       Id,     // 功法 Id（前三个 Op）或卡牌 Id（RemoveLooseCard）
    int          Tier);  // 仅 LearnTechnique(=1) / UpgradeTechnique(=目标层数) 有意义，其余写 -1
```

- **为什么另立一列：** 复用既有分列判据——**施加语义根本不同就分列**。`Elements` 是带符号的量（功法层数不可加、散牌无量纲）；`AbilityElements` 是幂等的集合成员操作（功法带层数，`Upgrade` 既非 `Grant` 也非 `Remove`；散牌是**多重集**，同名业障可多张，而 `Grant` 的「已持有 → 空操作」会静默吞掉第二张；且 `AbilityElements` 强制携带 `Source`，卡组条目没有 `SourceCode` 挂载面）。
- **绝不走 modifier pipeline。** 一条法则若能把「层数 +1」放大成 +2，「进化 = 整组替换、每层一整套定义」直接失效（不存在「1.5 层」的卡牌定义）。
- **`Tier` 写目标层数而非增量**，与 `AbilityChangeElement` 只承载已定稿 `Id` 同源：`AppliedChange` 要可直接重放，写增量会让重放结果依赖当时的层数。
- **`DeckElements` 在 `selectCost` 内恒为空**，与 `AbilityElements` 同一条不变式（物化组装后断言 + 内容模板加载期校验，两处 `PushError`）。理由同构：成本侧只放可如实计价的量，「一门功法值多少寿元」无法回答。
- **存档：** `PastEventEntry.AppliedChange` 随 `ProfileChangeSpec` 自动获得卡组变更的账，**不新增字段**；但增列 ⇒ **bump schema 版本**（当前无线上存档 ⇒ 空迁移）。

**否决的两个替代：** 扩 `AbilityKind` 加 `Technique`（层数无处安放；强制的 `Source` 对功法无落点；`AbilityScope` 对功法恒为 `Character`，等于引入取值域恒定的字段）· 塞进 `Elements` 用参数化 `CostKey`（打穿「启动期断言表覆盖 `CostKey` 全部成员」，且散牌的多重集语义仍无处表达）。

### ④ 卡组外的产出：只开两扇门（`lifeTotal` 回复 · `manaLimit ±1`）

- **允许回复 `lifeTotal`。** 「休养并入闭关」是既定决策，休养并进来了产出却没地方去等于并了一半；`life-total.md` 已定「恢复途径 = 通过 event 恢复」，未限定类型；且 `Recuperate` 与 `UpgradeTechnique` 在同一槽内并列正是 StS 篝火（rest / smith）的形状——一个真会犹豫的二选一。载体是既有的 `ChangeElement(CostKey.LifeTotal, +n)`，零新增。
- **隐藏属性推拉照常**（五类共有的通道，Research 侧无需表态）。**领悟法则不做**（合法子集表 ❌）。**不给灵玉产出**（`Jade` 的长期价值出口已分派给 Exchange，Research 产灵玉会抢同一条价值线）。
- **边界一句话：** Research 的产出面 = 卡组 + `manaLimit` + `lifeTotal` + 全类型共有的隐藏属性推拉；此外不给。

### ⑤ `manaLimit` 下降改挂 Research，做成玩家自选的风险档

玩家可选一个高风险的钻研候选：成功 `manaLimit +1`，失败 `−1`；**掷定发生在物化阶段并随 `EventOption` 落存档**（退出重进不改变结果）。

- **叙事轴与分档表天然对齐**：Research 已是推高的主通道，走火入魔是同一条轴的反面。Explore 已收窄为纯元类型、可揭示的三类都不是走火入魔场景。
- **它补上 Research 唯一缺失的张力**：此前 Research 是纯收益事件，而闭关的 `lifeSpanCost` 又是最贵一档——「最贵且必然赚」会成为批次里的无脑首选，压掉择一的决策价值。
- **三条既有决策由此获得消费方**：「不设 `manaLimit` 下界护栏」「不做死牌转化」「极端情形下高费卡成为死牌可接受」全部以下降存在为前提。
- **「玩家自选」而非「随机惩罚」是关键的一半**：被系统随机扣上限只产生被惩罚感；自己按下按钮则与「明知是死路仍然走」同族。

配套：`manaLimit` 进 `CostKey`，`ResourceElements` 增一行 `(Min = 0, Max 无, 无终态, 两个修正列均 null)`。两个修正列留空是硬要求——任一列开放，一条法则即可把 ±1 放大为 ±2，直接推翻「单次变动幅度恒为 1」。

### ⑥ 候选生成：两条既有抽取链，零新增抽取代码

| 槽内候选 | 取池链 |
|---|---|
| **法宝三选一** | **直接复用 `GrantPoolPicker`**：`TryPickGrantableMany(Item, Character, rng, 3)`——取池 → `(Kind, Scope)` → 去成就限定 → 排除已持有 → 按 `RarityTier` 加权 → 无放回抽 3 条 |
| **功法三选一（学新）** | `CultivationTechniqueData` 仓储 → `AllEnabled()` / `DrawPool<T>` → **排除卡组中已持有的功法 `Id`** → 按 `RarityTier` 加权 → `PickMany(rng, 3)`（无放回） |
| **升阶候选** | 卡组内已持有且未达层数上限的功法（不足 3 门时给几门算几门；一门都没有则该操作不进候选） |
| **弃置 / 移除散牌候选** | 卡组内已持有的功法 / 游离散牌 |

- **RNG 子流复用 `RngStream.Reward`，不新开。** `Reward` 已承载完全同构的用途（预先掷定 + 落存档 + 绝不重抽），而奖励候选与构筑候选**从不并发**（一次只结算一个事件），新开子流换来零隔离收益。
- **候选池不接 modifier pipeline（不受 PlayerPower 影响）。** 候选池的权重若可被法则推拉，等于开一条「账号级内容改写轮回级构筑运气」的通道，而它在 `ContentEnabled` / `ExclusiveSource` 之外无人校验。唯一例外是 capability flag（呈现向，不改池）。
- 功法那一路是 `DrawPool<T>` 的**第五个**调用方。

### ⑦ 开局构筑事件 = 上述形态的一个内容条目，无专属规则

`eventPriority = 1`（置位方是 future-event-service，故它是「`Priority = 1` 依什么条件抬升」那条待答项的第二个确定答案）· 两个槽（槽 1 限 `LearnTechnique`、槽 2 限 `GrantItem`，各 3 候选）· 两槽均 `AllowDecline = false`（开局底盘明写为「2 门绑定功法 + 1 门选来的功法 + 1 件选来的法宝」，允许拒绝会让底盘残缺）· `lifeSpanCost` 取 0 的条目级覆盖（被强制进入的第一个事件，收寿元等于开局即扣而玩家未做任何取舍；落在既有的条目级覆盖通道内）。

### ⑧ 决策槽的字段形态

模板侧（`AdventureEventData` 上 Research 专有的一格，`eventType != Research` 时恒空 → 加载期 `PushError`）：

```csharp
[GlobalClass] public partial class ResearchSlotSpec : Resource
{
    [Export] public DeckOperationKind[] AllowedOperations { get; set; }  // 空 = 加载期 PushError
    [Export] public int  CandidateCount { get; set; } = 3;               // 实际不足则给几个算几个
    [Export] public bool AllowDecline   { get; set; } = true;
    [Export] public bool AllowRisk      { get; set; } = false;           // 是否可掷出走火入魔候选
}
```

物化产物（进 `EventOption`，随批次落存档）：

```csharp
public sealed record ResearchSlot(int SlotIndex, bool AllowDecline,
                                  IReadOnlyList<ResearchCandidate> Candidates);

public sealed record ResearchCandidate(
    DeckOperationKind Kind,       // 六类操作之一
    string            TargetId,   // 功法 / 卡牌 / 法宝 Id；Recuperate 为空串
    int               Amount,     // Recuperate 的回复量 / Upgrade 的目标层数；不适用时 -1
    int               ManaDelta,  // 附带的 manaLimit 变动，取值 { -1, 0, +1 }（已掷定）
    bool              IsRisky);   // 面板标注为风险档；结果已定但不预先展示
```

- **`DeckOperationKind`（六值，面板层）与 `DeckChangeOp`（四值，element 层）是两个枚举**：前者是玩家在槽里能选什么，后者是卡组变更的施加语义。`GrantItem` / `Recuperate` 落别的列表，故不在后者中。
- **文本一律不进快照**（显示名 / 描述由 UI 按 `TargetId` 现场取模板组装）。
- **`ManaDelta` 已在物化时掷定并落存档**——这是「退出重进不能重掷」的落地点。
- **`ResolveOutcome` 不新增结构**：resolver 把所选候选翻译为 `DeckElements` / `AbilityElements` / `Elements` 三份 element，照常交给 `eventEnd` 那一次 `TryApply`。

### ⑨ 代价：不另收资源代价

Research 的卡组操作不另收灵玉，代价全部由 `lifeSpanCost` 的 Research 行承载（已定为高于常规事件）。

- 它兑现既定的核心权衡「**花寿元换永久出牌力**」；再叠一层灵玉会把一条权衡变成两条，而寿元那条才是时间压力主轴。
- 它保住「付不起在事件选择面整体消失」：`selectCost` 无条件施加是全局规则，若槽内操作另收灵玉，会出现「进来了但买不起任何操作」的死屏。
- 想表达代价差异时用既有旋钮：条目级 `lifeSpanCost` 覆盖值（「深度闭关」耗更多寿元）。

### 落地面

| # | 落点 | 改动 |
|---|---|---|
| 1 | `systems/architecture.md` | `ProfileChangeSpec` 增 `DeckElements`；新增 `DeckChangeElement` / `DeckChangeOp`；`CostKey` 增 `ManaLimit`；`EventOption` 增 `ResearchSlots` |
| 2 | `systems/services/profile-service.md` | 各列表清单 +`DeckElements`；`ResourceElements` 增 `ManaLimit` 行；失败语义表增六条 |
| 3 | `systems/adventure-event/common-properties.md` | `selectCost` 恒空不变式由一条变两条 |
| 4 | `systems/adventure-event/research/_index.md` + `common-properties.md` | 决策槽形态、六类操作、产出面边界、风险档、开局条目 |
| 5 | `systems/services/future-event-service.md` | 物化 `ResearchSlot[]` 与候选掷定（`RngStream.Reward`）；`EventOption` 骨架 +1 |
| 6 | `systems/services/content-service.md` | `DrawPool<T>` 调用方四处 → 五处 |
| 7 | `systems/character-profile/mana.md` | 下降承载点定为 Research；分档表「压低」列补 Research 行 |
| 8 | `systems/character-profile/deck/_index.md` | 卡组变更载体具体化为 `DeckElements`；三条待决项答结 |
| 9 | `systems/balance.md` | 新增三个待定格 |
| 10 | `terminology.md` | 登记「走火入魔」 |

## Clarifications（评审裁决）

草稿以 `status: decided` 进入本次提炼，五项取向一律取推荐项：

1. **`ProfileChangeSpec` 是否增列 `DeckElements`** → **增列**。用户同时定案「那条承重定案的判据本就是『按施加语义分列』」，故承重措辞不写列表数——本次是同一条判据的又一次应用，不是推翻它。**代价如实记：** 一次空迁移；`selectCost` 的「恒为空」不变式由一条变两条（断言与加载期校验各多一条）；`architecture.md` / `profile-service.md` / `adventure-event/common-properties.md` 三处的列举各需同改。
2. **`manaLimit` 下降的承载点** → **改挂 Research 的玩家自选风险档**（成功 +1 / 失败 −1，物化时掷定并落存档）；`mana.md` 分档表「压低」列补 Research 行。
3. **是否允许 Research 回复 `lifeTotal`** → **允许**，与升阶在同一决策槽内并列。
4. **常态条目的 `AllowDecline` 默认值** → **`true`**（与置换面板的「拒绝零代价」同构，且避免「只剩一门功法却被迫弃置」这类内容侧死结），开局条目显式 `false`。
5. **三条顺带项一并采纳**：功法 / 法宝三选一复用 `RngStream.Reward` · 候选排除已持有功法（不折算为升阶——折算会模糊「学新」与「升阶」的边界）· 卡组弃空不做内容侧回避（疲劳规则已表达后果，`AllowDecline = true` 已足以让玩家不被迫弃空）。

## Open questions

- **`Recuperate` 的回复量、走火入魔候选的出现权重、开局条目 `lifeSpanCost = 0` 的覆盖登记**——三个待定数值格，归 ch1 数值标杆专场。
- **功法的层数上限**未定 ⇒ `UpgradeTechnique` 的「未达层数上限」过滤条件有形态无取值，`ResearchCandidate.Amount` 的取值域待它答定。归 ch1 数值标杆专场。
- **`CardData` 完整字段清单与 starter deck** 未定 ⇒ 功法候选池当前内容条目为零，本方案的抽取链无法在 ch1 专场之前被真实验证。
- **`EventOption` 的完整物化字段清单**仍待一次内容侧 handoff；本次只把 `ResearchSlots` 这一个结构性字段提前落定（纯加法）。

## Notes / triage

- 输入：`inbox/solution-draft-research-mechanics.md`（`status: decided`），已归档进 `inbox/archive/`。
- 本次答结并移出 5 条待答项，见 `answer-logs/log-research-mechanics.md`。
- 本次是 `ProfileChangeSpec` 分列的第二次应用（第一次是同日的 `StatusChanges`）；两者共用同一条承重判据，措辞里不写列表数。
