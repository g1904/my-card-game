# deck —— 共有属性

> deck 子系统的共有字段与共有机制：抽 / 弃 / 洗循环、CardData 定义（费用、目标、效果流水线、触发器）。为未来「每张卡一个 Markdown」预留结构。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **抽牌 / hand / 弃牌循环（共有机制）。** 卡从抽牌堆抽入 hand，打出后进弃牌堆；**弃牌堆不回流**——抽牌堆抽空即为空，此后每尝试抽一张牌抽牌方 −1 道念（疲劳，见 `systems/scoring.md`）。洗牌只在参战方组装时发生一次，由 cycle seed 驱动（确定性可复现，见 `state-save-rules.md`）。
- **CardData 共有字段（数据即资源）。** 每张卡是一个 `CardData : Resource`（`.tres`），共有字段预期含：稳定唯一 `Id`、显示名 / 描述（与 `Id` 分离、可本地化）、**费用（mana cost）**、**目标（target）**、**效果流水线（effect pipeline）**、**触发器（trigger）**。数值读自资源，不硬编码。
- **三个新增共有字段：**

  | 字段 | 类型 | 说明 |
  |---|---|---|
  | `CardType` | `CardType` | **必填，无默认值**（逼内容侧显式声明；缺失 → 加载时 `PushError`）。五值：`Sorcery` / `Enchantment` / `Item` / `Power` / `Affliction` |
  | `Subtypes` | `string[]` | 次类型 id 列表，可空。**须在次类型注册表中存在**，否则加载时 `PushError`；且须与主类型匹配（「埋伏」只能挂 `Enchantment`） |
  | `Abilities` | `AbilityData[]` | 该牌携带的异能列表，可空 |

  **`CardType` 与 `Subtypes` 是静态字段，不进存档**（存档只记 `Id`），故**无迁移**。
- **`AbilityData`（跨载体可复用的异能资源）。** 异能不是 `CardData` 的私有字段结构——神通、持续状态、道具都能带异能，故抽为独立资源，由 `CardData` / `PowerData` / `ItemData` / 战场条目共同引用。

  ```csharp
  public enum AbilityKind { Static = 0, Activated = 1, Triggered = 2 }
  public enum TriggerOwnerScope { Self = 0, Opponent = 1, Either = 2 } // Opponent ← 埋伏靠这个成立

  // AbilityData : Resource
  //   Id / Kind / ActivationCost(ProfileChangeSpec?，仅 Activated) / TriggerWhen(仅 Triggered) / Effect
  // TriggerConditionData : Resource
  //   TimingId("turn.start" / "turn.end" / "card.played"…) / OwnerScope / Filter(次类型、费用区间等)
  ```
- **加载时校验规则（坏数据启动即失败）。**

  | 规则 | 违反时 |
  |---|---|
  | `CardType` 必填 | `PushError`，带 `Id` 与 `.tres` 路径 |
  | `Sorcery` 不得带 `Static` / `Activated` 异能 | `PushError`——不留场，无生效载体 |
  | `Affliction` 不得带任何异能 | `PushError` |
  | `Affliction` 允许有 mana 费用与负向效果，但不得有正面效果 | `PushWarning`（软检查，例：业障带产道念的效果 → 警告）——正负难以机械判定，主要靠内容侧纪律 |
  | `Enchantment` 至少带一个异能 | `PushWarning`——不带异能的永久物是空条目，多半漏填 |
  | `AbilityKind == Activated` 时 `ActivationCost` 非空 | `PushError`——零费启动式异能会造成无限循环 |
  | `AbilityKind == Triggered` 时 `TriggerWhen` 非空 | `PushError` |
  | `Subtypes` 中每个 id 须在次类型注册表中存在 | `PushError`，报出悬空 id |
  | 次类型须与主类型匹配 | `PushError` |
- **打出一张卡的结算（共有流程）。** 费用支付（mana）→ 目标选择 → 效果流水线依序执行 → 触发器响应事件。（具体阶段待设计。）**生命周期链路按 `CardType` 分叉**：`Sorcery` / `Affliction` 结算后进弃牌堆；`Enchantment` 结算后作为**永久物**落战场；`Item` 不经卡组、结算后进弃牌堆或按次数消耗；`Power` 开局入场且**永不入栈、永不离场**。

Source: `handoffs/2026-08-04b-mtg-loanwords-card-types-and-intent-snapshot.md`

## 效果关键字体系

**关键字 = 一个内容层的注册表条目，形态与次类型同构。** `[GlobalClass] partial class KeywordData : Resource`：稳定字符串 `Id` · 经 ContentRegistry 加载 · `.tres` 编写 · 带 `ContentEnabled`。**不挂 `Rarity`**——它不进任何抽取池，与「凡会被抽取或置换的内容定义都带 `Rarity`」（`systems/common-properties.md`）的判据一致。

**它必须是独立条目，不能是纯呈现层的文案简写**，三条理由与功法否决「纯标记方案」逐条同构：

| 理由 | 纯文案简写方案会怎样 |
|---|---|
| ① **效果筛选要能按关键字引用** | 战场条目没有 `Subtypes` 字段（次类型挂 `CardData`，而持续状态条目的来源可能是异能而非某张牌）。「移除对方所有带某状态的条目」这类 payoff 没有筛选键，**根本写不出来** |
| ② **`ContentEnabled` 的原子性** | 关掉一个关键字要改 N 张卡的效果定义，**漏一张即得到一条半生效的规则** |
| ③ **一处可读 / 可校验** | 「这个关键字到底是什么意思」要 grep 全库；拼错从编译期推迟到运行时，且悬空引用无从校验 |

**两种关键字，与既定的效果三层各归其位（这条切分承重）：**

| 种类 | `KeywordKind` | 定义体 | 落在三层的哪一层 |
|---|---|---|---|
| **关键字动作** | `Action` | 一段 `EffectData[]` 模板 | 第一层（结算时执行的原子操作组合） |
| **关键字状态** | `State` | 一份战场条目模板 `BattlefieldEntryTemplate` | 第二层（`ApplyState` 产出的非永久战场条目） |

**关键字不新增第四类东西**——`Action` 展开为已有的原子操作，`State` 展开为已有的战场条目。它是**命名与复用的一层，不是机制的一层**；这条必须写死，否则日后会有人把关键字当成第三种效果载体。

- **`BattlefieldEntryTemplate` = 非永久战场条目字段表的内容侧模板**：`AbilityData[]` + 默认 `Lifetime` / `CountdownSide` / `RemainingTurns`。字段语义与清理判据的权威在 `_index.md`「回合内状态 = 生命周期三件套」，此处不复述。
- **参数化 = 单个 `Amount` 占位，不做通用表达式。** `KeywordData.HasAmount : bool`；引用侧写 `KeywordRef(KeywordId, Amount)`。通用表达式会把「效果是数据不是代码分支」拖回一个需要求值器与沙箱的小语言，而 overlay 热更一段脚本的风险面远大于改一个数值。**取值域与具体数字归 ch1 数值标杆专场**（`systems/balance.md`）。
- **展开在结算时做，不在加载时内联。** 否则 overlay 热更改一个关键字的定义时，已加载的卡牌拿的是旧展开——`XxxData` 是 ContentRegistry 里的共享只读单例，不能回写。这与「读取侧不过滤 `ContentEnabled`」是同一种收口。

### 清单归零，机制保留

**当前关键字清单为空，一条不留。** 上方的机制部分完整成立；清单本身随内容横向扩展再填。

- **没有任何一个关键字被规则直接引用**：`IgnoresProtection` 是效果级布尔字段、埋伏是次类型 `enchantment.ambush`、疲劳是规则。次类型能留一条是因为 `enchantment.ambush` 是**埋伏机制的定名**；关键字侧没有对应的东西。
- **准入判据照抄次类型的两条**：① 至少 **3 个内容条目**共享它；② 至少 **1 处目标筛选或 payoff 引用它**。**没有 payoff 的关键字就是风味词**，风味写进描述文本——这条纪律正是防止清单长成一批 filler 的机制。
- **重建时机 = ch1 内容横向扩展阶段**，切入点同为 starter deck 的设计过程。关键字的正确清单只能从「哪些组合真的重复了 ≥3 次」倒推，而当前内容条目数为零；预铺一批等于制造一批要在 ch1 专场全部重写的 filler。

Source: `handoffs/2026-08-16c-effect-keywords-and-targeting.md`

## 目标（target）与作用域（scope）

**这是两个东西，必须分开建模（承重）。** 它此前已隐含存在但从未命名——`_index.md` 中 `CardInstance` 运行态判据的第二条理由「『所有灵兽获得 +1』作用于一个随时间变化的集合」讲的正是作用域。

| | **目标 target** | **作用域 scope** |
|---|---|---|
| 锚定 | 结算那一刻由 `TargetRef` 锚定到**具体条目** | 求值那一刻按筛选条件**动态匹配** |
| 承载 | `EffectData.TargetSlots` | 静止式修正的 `EffectScope` |
| 玩家参与 | 可能需要玩家点选 | **永不需要玩家输入** |
| 局面变了 | 可能非法 → fizzle | 无所谓，下次求值自然重算 |
| 落存档 | `chosenTargets : TargetRef[]` | **不落存档**（不是状态，是筛选条件） |
| 卡面文案 | 「目标〈类别〉」 | 「所有〈筛选〉」 |

- **推论 ①：静止式修正永远不需要目标规则。** 故「效果必须显式声明目标类别」这条纪律**只约束 `TargetSlots`，不约束 `EffectScope`**。两者混在一起时目标规则写不下去。
- **推论 ②：两者共用同一个筛选结构 `EntryFilter`，不各写一套。** 两份筛选条件会各自漂移，而本库没有机制发现它们不一致。差别只在**是否需要 `TargetRef` 锚定**。

### 声明侧的形态

```csharp
public enum KeywordKind     { Action = 0, State = 1 }
public enum SideConstraint  { Any = 0, Self = 1, Opponent = 2 }   // 一律相对 controllerSide 解析

public readonly record struct KeywordRef(string KeywordId, int Amount);  // HasAmount == false 时 Amount 恒为 -1

public sealed record EntryFilter(
    BattlefieldEntryKind[] AllowedEntryKinds,  // 空 = 不限
    string[]               RequiredSubtypes,   // 次类型 id；组合语义恒为 AND
    string[]               RequiredKeywords,   // 关键字 id；组合语义恒为 AND
    bool                   IncludeFaceDown);   // 默认 false；内容侧纪律 = 当前不使用

public sealed record TargetSlot(               // 一槽位 = 恰好一个目标，无 TargetCount 字段
    TargetKind     Kind,                       // 既定枚举，不扩
    SideConstraint Side,
    EntryFilter    Filter,
    bool           IgnoresProtection);         // 既定的效果级布尔，落在槽位上

public sealed record EffectScope(              // 静止式修正用；无 TargetRef、不挂起、不 fizzle
    SideConstraint Side,
    EntryFilter    Filter);
```

**`EffectData` 补两格字段**（其余七个原子操作不变）：

| 字段 | 类型 | 说明 |
|---|---|---|
| `TargetSlots` | `TargetSlot[]` | 可空 = 无目标。**顺序即 `slotIndex`**，与 `chosenTargets` 一一对应 |
| `Keyword` | `KeywordRef?` | 非空 = 本元素是一次关键字展开 |

**一槽位 = 恰好一个目标，多目标靠多槽位。** `chosenTargets` 与 `pending.slotIndex` 的既定结构直接够用，UI 一次只问一个。否决 `TargetCount { Exactly(N), UpTo(N) }`：竖屏多选态是真实成本，且 `pending` 的「一个 `slotIndex`」结构要扩。**方向不对称是关键理由**——5 回合定长对局里「选两个目标」的牌本就该稀少，日后真需要时补一个字段是**纯加法**，而先做多选再退回单选要改存档结构。

**`SideConstraint` 一律相对施放者解析，枚举里不放绝对方取值。** 这是 `CardData.Pool = Both` 的直接推论：同一张牌可能同时出现在玩家卡组与敌人卡组里，写绝对方会让它在敌人手里语义翻转。

**`EntryFilter` 的多条件组合语义恒为 AND，不支持 OR / NOT。** 可机械校验、卡面文案好写（「带『甲』且『乙』的条目」）。筛选条件一旦支持 OR / NOT 就从一张表变成一棵树，卡面文案立刻变长——与竖屏可读性相反。**OR 的需求由内容侧绕过**（把两个关键字都挂上），不进结构。

**`IncludeFaceDown` 保留字段、默认 `false`，内容侧当前不使用。** 保留成本为零，日后真有「揭示一张埋伏」这类效果时不必改 schema；机制在、纪律管住它，与 `CountdownSide.Either` 的处理同构。

**`HandCard` 槽位强制 `Self`，且只吃 `RequiredSubtypes`。** `SideSnapshot.HandCardInstanceIds` 敌方恒为空、`HandCount` 只给计数 ⇒ 玩家看不见对手手牌的任何条目 ⇒ UI 无从高亮 ⇒「指定对手某张手牌」不可能成为合法目标；这同时封住对手手牌可见性这条信息泄漏面（埋伏之外的第二条）。该 `Kind` 下 `AllowedEntryKinds` / `RequiredKeywords` / `IncludeFaceDown` 须为空——手牌是 `CardInstance` 不是战场条目，前者无对象、后者无意义，且**关键字是效果的命名层而非卡牌的标签**，让它同时成为卡牌标记会给关键字第二重语义。
**这不封死「弃掉对手一张手牌」这类效果**——那走 `EffectScope`（随机 / 全部，无 `TargetRef`），`Discard` 原子操作本就在清单里。**这正是目标 / 作用域切分的第一个实用价值。**

### 加载期校验（坏数据启动即失败）

| 规则 | 违反时 |
|---|---|
| `KeywordData.Id` 重复 | `PushError`，报出两个 `.tres` 路径 |
| `Kind == Action` 且 `Effects` 为空 / `Kind == State` 且 `StateTemplate` 为空 | `PushError` |
| `Kind == State` 且 `Effects` 非空（反之亦然） | `PushError` —— 关键字不是第三种效果载体 |
| `KeywordRef.KeywordId` 在注册表中不存在 | `PushError`，报出悬空 id + 引用它的 `CardData.Id` |
| `HasAmount == false` 但 `KeywordRef.Amount != -1` | `PushError` |
| `TargetSlot.Kind == HandCard` 且 `Side != Self` | `PushError` |
| `TargetSlot.Kind == HandCard` 且 `AllowedEntryKinds` / `RequiredKeywords` / `IncludeFaceDown` 非空 | `PushError` |
| `TargetSlot.Kind ∈ { None, Side }` 且 `Filter` 非空 | `PushError` —— 方位类目标没有可筛选的条目 |
| `EntryFilter.RequiredSubtypes` / `RequiredKeywords` 中的 id 悬空 | `PushError`，报出悬空 id |
| `TargetSlot.IgnoresProtection == true` | `PushWarning` —— 清单式软检查，与既有的 `IgnoresProtection` 清单警告同一处，使配额始终可人工审阅（口径见 `systems/balance.md`） |
| 关键字未被任何 `KeywordRef` 引用 | `PushWarning` —— 与「次类型 X 未被任何筛选条件引用」同构 |

Source: `handoffs/2026-08-16c-effect-keywords-and-targeting.md`

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- **关键字 = 内容层注册表条目 `KeywordData`（两种 `KeywordKind`，不新增第四类效果载体）；单 `Amount` 参数；展开在结算时做；清单归零、机制保留 + 两条准入判据。**
- **目标 target 与作用域 scope 分开建模，共用同一个 `EntryFilter`；「效果须显式声明目标类别」只约束 `TargetSlots`。**
- **一槽位 = 恰好一个目标；`SideConstraint` 相对施放者解析；`EntryFilter` 组合语义恒为 AND；`HandCard` 槽位强制 `Self` 且只吃 `RequiredSubtypes`。**

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **CardData 字段清单未定案。** **已定：`CardType` / `Subtypes` / `Abilities` 三个共有字段与 `AbilityData` / `TriggerConditionData` 的形态**（见上），以及**目标声明（`TargetSlots`）与效果引用（`Keyword`）两格**（见「目标（target）与作用域（scope）」）；**仍为结构占位**：费用与触发器两格的具体类型与枚举、效果流水线的阶段划分。→ 亦见 `systems/balance.md`（starter deck 与量纲）。
- **抽 / 弃 / 洗数值。** 手牌上限、每回合抽牌数、初始牌堆规模等属平衡数值 → `systems/balance.md`。

## 对应
提炼至：`.claude/knowledge/data/_index.md`（CardData）；`.claude/knowledge/systems/character-profile/deck/`（待建）。
