---
type: solution-draft
date: 2026-08-27
question: 效果原语 / 异能语法未定案 —— `EffectData` 的数据形态、原语清单、触发器与条件的表达形态、效果流水线的阶段划分尚缺，卡住五个内容类型的全部条目写作
source: open-questions.md「仍然不要 derive」① · content/_index.md 类型登记表（`ability/` 🔴）· systems/character-profile/deck/common-properties.md#待决问题
targets: systems/character-profile/deck/common-properties.md · systems/character-profile/deck/_index.md · systems/services/combat-service.md · content/_index.md
status: distilled
reviewed: 2026-08-27 — 用户逐条评审并裁决；提炼时另经一场合并 interview（8 问）补齐三条真冲突与两处跨草稿矛盾
distilled-to: handoffs/2026-08-27-ability-primitive-grammar.md
---

# 方案草稿 — 效果原语 / 异能语法

## 问题

`content/_index.md` 把 `ability/`（`AbilityData` / `EffectData` / `TriggerConditionData`）标为 🔴「语法未定案」，它是**卡牌 / 神通 / 法宝 / 法则 / 古宝**五个内容类型的共同底座；`open-questions.md` 把它列为玩法侧三处欠账中解锁面最大的一处。

具体缺口有六个，本草稿逐个给形态：

1. **`EffectData` 的数据形态** —— 是 `Resource` 子类树，还是带 `Op` 枚举的扁平条目 + 参数表，抑或表达式串？
2. **原语（动词）清单与各自参数** —— `deck/_index.md` 给了七个原子操作的名字，没给参数。
3. **触发器（trigger）的表达形态** —— `TriggerConditionData` 只有 `TimingId` / `OwnerScope` / `Filter` 三个名字，`TimingId` 的值域与 `Filter` 的结构未定。
4. **条件（condition）的表达形态** —— 全库尚无落点，而「每场限 N 次」「场上有 ≥N 个 X 时」这类效果已被既有定案预设为可写。
5. **效果流水线的阶段划分** —— `deck/common-properties.md` 明写「（具体阶段待设计）」。
6. **`CardData` 的费用与触发器两格** —— 仍是结构占位。

**边界：** 本草稿只给**语法与结构**。具体卡牌条目、`Amount` 取值域、道念量纲、starter deck 内容一概不给——那属内容横向扩展阶段的统计校准，已在 `systems/balance.md` 有归属。

## 约束（来自既有设计）

**硬前提，方案必须咬合、不得重新发明：**

- **效果 / 状态系统三层**：第一层 `EffectData`（结算时执行的原子操作）· 第二层 `BattlefieldEntry`（战场条目 + 生命周期三件套）· 第三层求值管线（加法层 → 乘法层，「加法先于乘法」是**规则**）。→ `deck/_index.md`「效果 / 状态系统 = 三层」，`ADR-0061`。
- **关键字是命名与复用的一层，不是第四层**：`KeywordKind.Action` 展开为第一层的原子操作组合、`KeywordKind.State` 展开为第二层的战场条目；**展开在结算时做，不在加载时内联**。参数化 = **单个 `Amount` 占位，明确否决通用表达式**（需求值器 + 沙箱，overlay 热更一段脚本的风险面远大于改一个数值）。→ `deck/common-properties.md`「效果关键字体系」。
- **target 与 scope 分开建模、共用 `EntryFilter`**：`EffectData.TargetSlots : TargetSlot[]`（一槽位 = 恰好一个目标）· 静止式修正用 `EffectScope`（无 `TargetRef`、不挂起、不 fizzle、不落存档）。`EntryFilter` 组合语义**恒为 AND，不支持 OR / NOT**。`SideConstraint` 一律相对施放者解析。→ `ADR-0062`。
- **异能三分**：`AbilityKind { Static, Activated, Triggered }`；`AbilityData` 已有 `Id` / `Kind` / `ManaCost` / `MaxActivationsPerCombat` / `TriggerWhen` / `Effect` / `CounterNames` 七格，其中 `Effect` 是占位。启动式代价面 = `ManaCost` 一格 + `MaxActivationsPerCombat` 配额闸，**不进 `ProfileChangeSpec`**。
- **栈与 LIFO**：`StackEntry` = `stackEntryId` / `kind { PlayedCard, TriggeredAbility, ActivatedAbility, Fatigue }` / `controllerSide` / `sourceInstanceId` / `sourceEntryId` / `abilityId` / `chosenTargets : TargetRef[]` / `targetState { Resolved, AwaitingChoice }`。栈非空不得出牌，不借交互与优先权。→ `ADR-0086` · `ADR-0039`。
- **结算时逐槽位重检 + 部分 fizzle**：部分槽位非法 → 该槽位不产生效果、其余照常；全部有目标的槽位非法 → 整条不结算（`Declared` 记 0）。挂起当且仅当三条同时成立（`Kind ∈ {BattlefieldEntry, HandCard}` ∧ `controllerSide == Character` ∧ `LegalTargets.Count > 1`）。
- **事件视图两级粒度**：`ActionResult`（一次玩家动作链路的汇总）与 `CombatFeedEntry`（逐次结算粒度，带 `EntryId` / `CauseEntryId` 因果树、`FizzledSlots` 位掩码、`MomentumDelta{Before, After, Declared, Actual}`）。→ `ADR-0087`。
- **疲劳是一等栈条目**（`StackEntryKind.Fatigue`），可被监听、可被响应、可被取消；三格（`sourceInstanceId` / `sourceEntryId` / `abilityId`）恒空。→ `ADR-0088`。
- **`counters` 键空间闭合**：`<abilityId>[#<子名>]` 一种形态，子名须登记在 `AbilityData.CounterNames`，读写两侧都校验；`KeywordRef.Amount` 落战场条目的 `amount` 一格，**不进 `counters`**。→ `ADR-0075`。
- **无衍生物封闭卡集**：一场战斗内卡牌是闭集，只在区之间流转，**没有 token、没有运行时新造的卡牌实体**。→ `ADR-0041`。
- **数据即资源**：`[GlobalClass] partial class XxxData : Resource` + `[Export]` + 稳定 `Id` + ContentRegistry + **启动期大声失败** + 内容可加性（「新增一张卡 = 新增一个 `.tres`，不是编辑 switch」）。→ `.claude/rules/data-resource-rules.md`。
- **下沉到 handler 的判据**：存在一个**开放的** `kind` 枚举、且各 kind 的处理互不共享状态 ⇒ 一个 kind 一个 handler；「handler 的价值在可加性——新增一个 kind = 新增一个 handler 文件，与『新增一张卡 = 新增一个 `.tres`』是同一条可加性纪律在代码侧的投影」。→ `systems/architecture.md`（层级 service ⊃ manager ⊃ module ⊃ processor ⊃ handler）。
- **物化模型**：`XxxData : Resource` 是 ContentRegistry 里的**共享只读单例**，任何服务不得在运行时写它。
- **热路径纪律**：结算与广播是热路径，不做 `string` 拼接、不做 LINQ 分配；负载只带 `Id` 与值类型。

---

## 建议方案

### 1. `EffectData` 的数据形态 = `Resource` 子类树（一个原语一个 `[GlobalClass]` 子类）

`[既有推演]`

```csharp
// 基类：抽象、不挂 [GlobalClass]（不进检视器的 "New Resource" 选择器）
public abstract partial class EffectData : Resource
{
    [Export] public TargetSlot[]      TargetSlots { get; set; } = [];   // 既定：可空 = 无目标，顺序即槽位序
    [Export] public KeywordRef?       Keyword     { get; set; }          // 既定：非空 = 本元素是一次关键字展开
    [Export] public EffectCondition[] Conditions  { get; set; } = [];   // 新增，见第 5 节；AND 语义
}

// 每个原语一个子类，参数是它自己的 [Export] 格
[GlobalClass] public sealed partial class ModifyMomentumEffect : EffectData { [Export] public SideConstraint Side; [Export] public int Amount; }
[GlobalClass] public sealed partial class DrawEffect           : EffectData { [Export] public SideConstraint Side; [Export] public int Count;  }
// …（清单见第 3 节）
```

**为什么取子类树而非「`Op` 枚举 + 扁平参数表」（四条，逐条是判据不是偏好）：**

| 判据 | 子类树 | `Op` 枚举 + 扁平参数表 |
|---|---|---|
| **检视器可写性**（内容作者天天面对） | 选定子类后**只看得见这个原语的参数**，且各参数有名字与类型 | 一张表上永远摆着全部原语的并集参数格，作者必须记住「`Op == Draw` 时只有 `Count` 有意义」，填错的格静默被忽略 |
| **链路类型一致性**（`systems/common-properties.md` 硬约束） | `Count` 是 `int`、`Side` 是 `SideConstraint`、目标类别是 `TargetKind` —— 各就各位 | 参数表要么全压成 `int[]` / `string[]`（让类型说谎），要么摆一排可空格（等价于把子类的字段拍平后失去归属） |
| **加载期校验** | 「`Draw` 的 `Count >= 1`」写在该子类的校验里，天然只对它成立 | 校验必须先 `switch (Op)` 再挑格子——正是可加性纪律要消灭的那个 switch |
| **可加性** | 新增原语 = 新增一个 `EffectData` 子类文件 + 一个 handler 文件，**不编辑任何既有文件的分支** | 新增原语 = 编辑 `Op` 枚举 + 编辑校验 switch + 编辑结算 switch |

**Godot 侧可行性已核实为常规做法**：`[Export] Godot.Collections.Array<EffectData>` 中放子类实例，`.tres` 以 `sub_resource` + 脚本引用序列化，多态还原正常。基类保持 `abstract` 且不加 `[GlobalClass]`，使检视器只能选出具体原语。

**分派用 `Dictionary<Type, IEffectHandler>`，不引入 `EffectKind` 判别枚举。** 一个枚举就是一处必须随每个新原语编辑的中心清单；按类型注册后，新增原语只在**装配根的注册列表**里加一行。错误消息与日志用 `GetType().Name`（形如 `[Combat-Effect] unsupported effect type=ModifyMomentumEffect`），不需要枚举来产出可读串。

**否决表达式串**：`deck/common-properties.md` 已就 `Amount` 参数化明确否决通用表达式（求值器 + 沙箱 + overlay 热更风险）；效果本体的理由完全相同且更重——效果串一旦可写脚本，「效果是数据不是代码分支」这条承重纪律当场作废。

### 2. 静止式修正不是 `EffectData`，是并列的第二种定义体 `StaticModifierData`

`[既有推演]`

**这是本草稿最重要的一处结构补齐。** 三层里第一层的定义是「**结算时执行**的原子操作」，而静止式修正**不入栈、不参与 LIFO、只在求值瞬间被读取**（`deck/_index.md` 写死）。把它塞进 `EffectData` 会让「第一层是结算时执行的操作」这句定义立刻失真，且 `EffectData.TargetSlots` 对它恒为空、`EffectScope` 对其余原语恒无意义——两族语义混装一个类型。

```csharp
[GlobalClass] public sealed partial class StaticModifierData : Resource
{
    [Export] public EffectScope     Scope { get; set; }   // 既定结构：SideConstraint + EntryFilter，求值瞬间动态匹配
    [Export] public ModifierTarget  What  { get; set; }   // 被修正的量，见下
    [Export] public ModifierLayer   Layer { get; set; }   // Additive | Multiplicative —— 既定的两层求值
    [Export] public int             Amount { get; set; }  // Additive 取带符号增量；Multiplicative 取百分比（100 = ×1.0）
}

public enum ModifierLayer { Additive = 0, Multiplicative = 1 }
```

- **`Multiplicative` 取百分比整数而非 `float`**：全库数值面是整数（`momentum` / `mana` / `counters` 皆然），引入浮点会在「加法层结果 × 若干乘数」处引入舍入取向问题，而整数百分比的截断规则可一次写死（**先累乘百分比、最后一次整除 10000…，最终向下取整，再按下限 0 截断**）。舍入只发生一次是可断言的不变式。
- **`AbilityData` 的定义体按 `Kind` 分两格，加载期 XOR 校验**——与 `KeywordData` 的 `Effects` / `StateTemplate` 二选一逐字同构（既有先例，不新造风格）：

  | `AbilityKind` | 定义体格 | 另一格须为空 |
  |---|---|---|
  | `Static` | `StaticModifiers : StaticModifierData[]`（非空） | `Effects` |
  | `Activated` / `Triggered` | `Effects : EffectData[]`（非空） | `StaticModifiers` |

  这把 `AbilityData` 上那格占位的 `Effect` 落定为**两格 + 一条 XOR 校验**。

- **`ModifierTarget` 的首批清单是一个玩法取向问题**，见 `## 仍需用户决定` 第 2 条。结构本身与清单大小无关。

### 3. 首批原语清单 = 既有七个 + `BumpCounter`，共八个

`[既有推演]`（七个）· `[通行做法]`（第八个）

| # | 子类 | 参数（`[Export]`） | 语义与既有依据 |
|---|---|---|---|
| 1 | `ModifyMomentumEffect` | `Side : SideConstraint` · `Amount : int`（带符号） | 产 / 削道念。**下限 0 逐次截断、溢出不结转**；`Declared` = 求值后的标称量，`Actual` = `After − Before`。→ `systems/scoring.md` |
| 2 | `DrawEffect` | `Side : SideConstraint` · `Count : int (>= 1)` | 抽 `Count` 张；满手落空（牌留抽牌堆、不产生弃牌堆流量）；抽牌堆空 ⇒ 逐张走疲劳通道。→ `deck/_index.md` |
| 3 | `DiscardEffect` | `Side : SideConstraint` · `Count : int (>= 1)` · `Selection : DiscardSelection { Random, Chosen }` | 弃牌堆的两条填充通道之一（另一条是「打出后进弃牌堆」）。`Chosen` 须配一个 `TargetKind.HandCard` 槽位（强制 `Self`，既定）；`Random` 走 `EffectScope` 式随机、**不产生目标交互**——这正是「弃掉对手一张手牌」得以成立的路径 |
| 4 | `ModifyManaEffect` | `Side : SideConstraint` · `Amount : int` | 改 `sides[].currentMana`，**不改 `manaLimit`**（后者是轮回级事件推拉）。下限 0 截断 |
| 5 | `ApplyStateEffect` | `Template : BattlefieldEntryTemplate` · `Side : SideConstraint` | 产出一条非永久战场条目（`kind = Transient`）。`keywordId` / `amount` 两格由引用侧 `KeywordRef` 填（既定） |
| 6 | `RemoveEntryEffect` | （无独有参数；目标经 `TargetSlots`） | 受目标类别 + `IsProtected` + `TargetSlot.IgnoresProtection` 约束（既定） |
| 7 | `MoveCardEffect` | `From : CardZone` · `To : CardZone` · `Count : int` · `Selection` | **闭集内的流转，不新造牌**（`ADR-0041`）。`CardZone { DrawPile, Hand, DiscardPile, Battlefield }`——六处位置里栈不作为流转端点（栈是结算队列不是区） |
| 8 | **`BumpCounterEffect`**（新增） | `CounterName : string`（空 = 默认计数器）· `Delta : int` · `Space : CounterSpace { Entry, CardInstance }` | 写 `counters`。**必须存在**：`AbilityData.CounterNames` 的加载校验里已明写「该名从未被任何**效果定义**使用 → `PushWarning`」——子计数器的写入面只能是效果侧。键由「宿主 `AbilityData.Id` + `#` + `CounterName`」在结算期拼出，**内容作者不写完整键**（避免自造裸字符串，与既有内容侧纪律一致）。`Space` 的取值受既定归属判据约束：有过期时刻 → `Entry`，随牌本体整场存活 → `CardInstance` |

**闭合性核对（能否拼出已定语义）：**

- 疲劳 → **不是原语**。疲劳栈条目结算时执行一条内建的 `ModifyMomentum(Self, −N)`，`N` 经求值管线（故「削减疲劳量」类静止式修正天然可写）。存档与栈结构一格不加。
- 道念产 / 削 → ①；抽牌 → ②；counters → ⑧；持续状态 → ⑤；驱散 / 拆永久物 → ⑥；牌序便利类（看牌堆顶、重排手牌）→ ⑦。
- 起始卡组所需的全部动词落在 ① ② ⑤ 的组合内。

**扩展方式（写下来，使日后加原语有章可循）：** 新增一个原语 = ① 新增 `XxxEffect : EffectData` 子类文件；② 新增 `XxxEffectHandler : IEffectHandler` 文件；③ 在装配根注册一行；④ 在加载期校验表加一行它自己的参数校验。**不编辑任何既有原语的文件，不编辑任何 switch。** 准入判据照抄次类型 / 关键字那两条的形状：**新原语只有在既有原语的组合确实表达不出该语义时才该存在**——能用组合表达的一律用组合，否则原语表会长成一批同义词。

### 4. 触发器 = `TriggerConditionData`，`TimingId` 取「点分字符串 + 代码侧封闭常量表」

`[既有推演]` + `[通行做法]`

```csharp
[GlobalClass] public sealed partial class TriggerConditionData : Resource
{
    [Export] public string             TimingId   { get; set; } = "";  // 见下方常量表
    [Export] public TriggerOwnerScope  OwnerScope { get; set; }        // 既定：Self / Opponent / Either
    [Export] public TriggerFilter      Filter     { get; set; }        // 见下
}

public sealed record TriggerFilter(
    EntryFilter EntryFilter,     // 复用既定结构（次类型 ∩ 关键字 ∩ faceDown），条目类时点用
    CardType[]  CardTypes,       // 空 = 不限；卡牌类时点用
    int         ManaCostMin,     // -1 = 不限
    int         ManaCostMax);    // -1 = 不限
```

**`TimingId` 的值域是代码侧封闭常量表，不是内容层注册表。** 判据与既定的「capability flag 的载体是 C# `enum` 而不是字符串 key」同源：**一个时点必须有一处对应的广播点，广播点是代码**；`.tres` 里写下一个没人广播的时点，会得到一条静默永不触发的异能，而它在加载期完全合法。故：

```csharp
public static class TimingIds        // 首批，封闭，随广播点一同增长
{
    public const string CombatStart   = "combat.start";
    public const string TurnStart     = "turn.start";
    public const string TurnEnd       = "turn.end";
    public const string CardPlayed    = "card.played";
    public const string CardDrawn     = "card.drawn";
    public const string CardDiscarded = "card.discarded";
    public const string EntryEntered  = "entry.entered";
    public const string EntryLeft     = "entry.left";
    public const string Fatigue       = "fatigue";        // ADR-0088 的「疲劳时」
    public const string MomentumChanged = "momentum.changed";
}
```

- **保留点分字符串形态而不改成枚举**，虽然 `CapabilityFlag` 的先例指向枚举：`"turn.start"` 这一惯例已被 `CardSubtypeData` 的 id 规范**显式引用为先例**（`deck/_index.md`「沿用 `TriggerConditionData.TimingId` 的 `"turn.start"` 惯例」），改形态要连带改另一处已定案的措辞。字符串 + **加载期封闭集校验**拿到的安全性与枚举等同（`TimingId ∉ TimingIds.All` → `PushError` + 报出 `AbilityData.Id`），差别只在编译期 vs 启动期，而本库对内容错误的既定标准恰是「启动期大声失败」。
- **每个时点声明一个 `SubjectKind { None, Card, Entry, Side }`**（代码侧同表），加载期校验 `TriggerFilter` 只填了与该 subject 相容的格：`SubjectKind == Card` 时 `EntryFilter` 须为空、`SubjectKind == Entry` 时 `CardTypes` / `ManaCost*` 须为空、`SubjectKind == None` 时整个 `Filter` 须为空。防的是「给『回合开始时』写了一条按次类型的筛选」这种静默无效的填写。
- **`CardData` 不另开触发器格**，见第 6 节。

### 5. 条件 = 封闭的谓词 `Resource` 小集合，AND 语义，绝不是表达式

`[既有推演]`

`EffectData.Conditions : EffectCondition[]`，**组合语义恒为 AND，不支持 OR / NOT**——与 `EntryFilter` 的既定处理逐字同构（可机械校验、卡面文案好写；OR 的需求由内容侧写两条 element 绕过）。

```csharp
public abstract partial class EffectCondition : Resource { }

[GlobalClass] public sealed partial class CounterAtLeastCondition : EffectCondition
{ [Export] public string CounterName = ""; [Export] public CounterSpace Space; [Export] public int Value; }

[GlobalClass] public sealed partial class EntryCountCondition : EffectCondition
{ [Export] public EffectScope Scope; [Export] public int Min = -1; [Export] public int Max = -1; }  // -1 = 不限

[GlobalClass] public sealed partial class MomentumCondition : EffectCondition
{ [Export] public SideConstraint Side; [Export] public int Min = -1; [Export] public int Max = -1; }
```

- **三条覆盖已被既有定案预设为可写的全部条件形态**：「每场限 N 次」类（`CounterAtLeastCondition`，配 ⑧ 的写入侧）· 「场上有 ≥N 个带某关键字的条目时」类（`EntryCountCondition`，复用 `EffectScope`）· 「对方道念低于 X 时」类（`MomentumCondition`）。扩展方式同原语：新增一个谓词 = 新增一个子类 + 一个求值器，不编辑既有文件。
- **条件不满足 ≠ fizzle。** 二者必须分开，否则战报读不出「为什么没生效」：**fizzle 专指目标非法**（呈现层由 `FizzledSlots` 位掩码表达）；**条件不满足是该 element 整条跳过**，`Declared` 对该 element 记 0、不置 `FizzledSlots` 任何位。
- **内容侧硬纪律：凡 UI 需要在点下去之前预判的门，一律不得表达为 `EffectCondition`。** 这是既定判据「`MaxActivationsPerCombat` 是显式内容字段，不是埋在效果条件里的一个判断——UI 必须在点下去之前把不可启动项灰显，埋在效果条件里的配额无法被机械预读」的一般化。`EffectCondition` 只承载**结算时才求值、UI 不必预判**的门；可预判的门必须是 `AbilityData` / `CardData` 上的显式字段。加载期无法机械校验，落为内容侧纪律 + `/audit-content` 对账。
- **条件挂在 `EffectData` 上而非 `AbilityData` 上（单一落点）。** 触发侧的门由 `TriggerConditionData` 承担、启动侧的门由 `ManaCost` + `MaxActivationsPerCombat` 承担，剩下的「这一步在什么局面下才发生」是 element 级的事。挂两处会制造第二权威。

### 6. `CardData` 的费用与触发器两格：费用 = `ManaCost : int`，触发器格**取消**，另立 `OnPlay`

`[既有推演]`

| 格 | 结论 | 依据 |
|---|---|---|
| **费用** | `[Export] int ManaCost`（`>= 0`），**独立整数格** | 与 `AbilityData.ManaCost` 那条已定推理**逐字适用**：`currentMana` 是 `activeCombat.sides[]` 上的回合内运行态、不是 Profile 字段，`CostKey` 与两层 Profile 字段双向满射且其中没有 `CurrentMana`。塞进 `ProfileChangeSpec` 要么伪造 `CostKey`、要么让 spec 承载两族语义 |
| **触发器** | **不设这一格。** `Abilities : AbilityData[]` 已完整承载触发式（`Kind == Triggered` + `TriggerWhen`） | 「触发的匹配逻辑不能写死在卡牌类型里」+「异能抽为独立可复用资源」两条既定推论直接得出。再开一格即第二权威：同一张牌的触发会有两个落点，两处各自漂移而本库无机制发现 |
| **（新）打出时效果** | `[Export] EffectData[] OnPlay` | `Sorcery` / `Affliction` 打出时的一次性效果不属异能三分中的任何一档（没有「打出时」这一 `AbilityKind`），必须有自己的格 |

**阵法（`Enchantment`）不需要 `OnPlay`**：入场效果（ETB）写成一条 `Triggered` 异能 + `TimingId = "entry.entered"` + `OwnerScope = Self` 即可，形态与其余触发完全同构，不为它开第二条路径。加载期强制 `OnPlay` 为空。

**由此得出 `CardData` 的完整字段清单（本草稿认为可收口）：**
`Id` · `DisplayName` / `Description`（`LocalizedText`）· `CardType`（必填无默认）· `Subtypes`（`string[]`）· `Pool`（必填无默认）· `Rarity`（必填）· `ContentEnabled` · **`ManaCost`** · **`OnPlay : EffectData[]`** · `Abilities : AbilityData[]` · `CodexFlavor?` · 美术引用。

### 7. target / scope 如何挂进来：槽位在**栈条目层扁平化编号**

`[既有推演]`

既定的 `PlayCard(card, targets)` 要求「`targets` 长度 = 该效果的 `TargetSlots` 长度」，但一张牌持有的是 `EffectData[]`（多个 element，各带自己的 `TargetSlots`）。**必须写下的推论：**

> **一个栈条目的槽位序列 = 它全部 element 的 `TargetSlots` 按 element 顺序拼接后的扁平序列；`slotIndex` 是这条扁平序列的下标。**

- `stackEntry.chosenTargets.Length == Σ(element.TargetSlots.Length)`，运行时不变式、可断言。
- `pending.slotIndex` 与 `PendingTargetRequest.SlotIndex` 指的是**同一个扁平下标**；`CombatFeedEntry.FizzledSlots` 位掩码的位序同此。
- **`FizzledSlots` 是 `int` 位掩码 ⇒ 单个栈条目的槽位总数硬上限 32**：加载期校验 `Σ TargetSlots.Length <= 32` → `PushError`；另配 `> 4` → `PushWarning`（清单式软检查，与既有 `IgnoresProtection` 清单警告同构）。理由：多目标牌在 5 回合定长 + 竖屏下本就该稀少，而这条上限此前从未被写下来。

**`EffectScope` 只挂 `StaticModifierData`**（第 2 节）与 `EntryCountCondition`、以及 `DiscardEffect` / `MoveCardEffect` 的 `Random` 选择面——**它永不出现在需要玩家点选的路径上**，这与既定的「静止式修正的求值路径上恒不出现 `TargetRef`」这条可断言不变式一致。

### 8. `KeywordData` 与原语的关系：展开一层、`Amount` 用哨兵代入

`[既有推演]`

- **`KeywordKind.Action`** 的 `Effects : EffectData[]` 就是**第一层原语的一段模板**；结算期展开后就地内联进宿主的 element 序列（保持 element 顺序）。
- **`KeywordKind.State`** 的 `StateTemplate : BattlefieldEntryTemplate` 由宿主的一条 `ApplyStateEffect` 消费。
- **`Amount` 的代入形态 = 哨兵值 `EffectData.KeywordAmountSentinel = int.MinValue`。** 模板里任何一个整数 `[Export]` 参数写成该哨兵，即表示「此处代入引用侧 `KeywordRef.Amount`」。
  - **取 `int.MinValue` 而非 `-1`**：`-1` 已被两处占用（`KeywordRef.Amount` 的「无参数」约定、`remainingTurns` 的「不适用」），且 `-1` 是合法的削减量；哨兵必须是一个绝不可能作为真实数值出现的取值。
  - 加载期校验：`HasAmount == true` ⇒ 模板中**至少一处**哨兵，否则 `PushError`（参数化了却没有代入点 = 必是漏填）；`HasAmount == false` ⇒ 模板中**不得出现**哨兵。
  - 这条不引入任何求值器，与「参数化 = 单个 `Amount` 占位，不做通用表达式」的定案完全相容。
- **关键字不得引用关键字**（`KeywordData` 的模板内 `EffectData.Keyword` 须为空）→ `PushError`。保证展开**恰好一层收敛**，无递归、无展开深度、无环检测。

### 9. 效果流水线 = 六个阶段，挂起点唯一

`[既有推演]`

一个栈条目被弹出后的结算流程（`StackManager.ResolveStackEntry`）：

```
阶段 1  重检目标 / 挂起      逐槽位按既定四条过滤重检 → 非法槽位置 FizzledSlots 对应位
                            三条与门成立 ⇒ 写 pending、落决策点 D4、等 ProvideTarget（恢复后从本阶段同一槽位继续）
                            全部有目标的槽位非法 ⇒ 整条不结算，直接跳到阶段 6（Declared 记 0）
阶段 2  条件求值             逐 element 求 Conditions（AND）；不满足者标记跳过，不置 FizzledSlots
阶段 3  关键字展开           Keyword != null 的 element 按 KeywordData 就地展开（Action 内联 / State 供 ApplyState）
                            Amount 哨兵在此刻代入。展开产物不再展开（一层）
阶段 4  数值求值             每个数值参数经求值管线：遍历战场匹配的静止式修正 → 先全部加法、再全部乘法 → 得 Declared
阶段 5  施加                 按 element 顺序依次执行原语；ModifyMomentum 在此按下限 0 截断得 Actual
阶段 6  收口                 ① 默认 counters +1（仅当阶段 5 实际生效）② 收集本次引发的触发式异能、按 element 顺序压栈
                            ③ 广播一条 CombatFeedEntry（FizzledSlots / MomentumDelta / CauseEntryId）
                            ④ 交回 StackManager 判断是否进决策点 D2
```

**五条须写成规则而非实现细节的：**

1. **挂起点唯一 = 阶段 1。** 阶段 2–6 恒不挂起。这**正是**既定推论「结算走到一半被取消是不可能的 ⇒ 中间态永不需要持久化」得以成立的结构依据——此前它只是被断言，没有落点。
2. **element 顺序是规则**（与 LIFO、「加法先于乘法」同款处理）：同一条 element 序列内先后可观测（前一条改了道念，后一条的条件读到的是改后的值）。
3. **触发在阶段 6 统一收集并压栈，阶段 5 内不即时压栈**，且**按 element 顺序压入** ⇒ LIFO 下**最后一个 element 引发的触发最先结算**。不写死则同一组触发在不同实现下顺序不同，而 LIFO 已被明确定位为「卡牌设计可利用的资源」。
4. **求值（阶段 4）先于施加（阶段 5），整条一次求完。** 否则「本回合我所有牌 +1 道念」这类修正在一条 element 序列中途被移除时，同一条牌的前后两个 element 会吃到不同的修正——语义不可预期且无法在卡面上表达。
5. **阶段 4 / 5 之间就是「无副作用 / 有副作用」的分界，也是 AI 试算模式的边界（承重）。** `combat-service.md` 已把「AI 试算不展开连锁触发」写成**规则而非实现细节**，并要求「每个候选的收益按该动作自身 `EffectData` 在求值管线上跑一遍得出」。本方案的阶段划分**恰好使这条可执行**：AI 只跑**阶段 1（只重检、不挂起）→ 2 → 3 → 4** 拿到 `Declared`，不进阶段 5、不进阶段 6（故不改战场、不写 counters、不压栈、不广播 feed、**不消耗 `combat` 子流**）。
   - **由此得出一条对原语的硬要求：阶段 1–4 的全部代码路径必须无副作用**——`IEffectHandler` 的接口因此分成两段：`int Evaluate(ctx)`（阶段 4，纯函数）与 `void Apply(ctx, evaluated)`（阶段 5，唯一允许写状态的地方）。**任何把写入塞进 `Evaluate` 的原语实现都会让 AI 试算污染真实局面**，且因 AI 每回合试算多个候选，污染是静默且累积的。这条须写进原语的实现纪律。
   - **原语内的随机同理**：一律取 `combat` 子流（既定），但**只能在 `Apply` 内取**；`Evaluate` 阶段遇到随机取**期望值或标称值**。否则 AI 每试算一次就推进一次 `State`，「同一 `CycleSeed` 复现同一场战斗」当场失效。

---

## 具体形态（可 derive 的落地面）

### 加载期校验清单（本方案新增；既有各条原样保留）

| # | 规则 | 违反时 |
|---|---|---|
| 1 | `AbilityData`：`Kind == Static` ⇒ `StaticModifiers` 非空且 `Effects` 为空 | `PushError` + `Id` + `.tres` 路径 |
| 2 | `AbilityData`：`Kind ∈ {Activated, Triggered}` ⇒ `Effects` 非空且 `StaticModifiers` 为空 | `PushError` + 同上 |
| 3 | `TriggerConditionData.TimingId ∉ TimingIds.All` | `PushError` + 报出该 id 与宿主 `AbilityData.Id` |
| 4 | `TriggerFilter` 填了与该 `TimingId` 的 `SubjectKind` 不相容的格 | `PushError`，指名是哪一格 |
| 5 | `StaticModifierData`：`Layer == Multiplicative` 且 `Amount < 0` | `PushError`（负乘数无定义语义） |
| 6 | `DrawEffect.Count < 1` / `DiscardEffect.Count < 1` / `MoveCardEffect.Count < 1` | `PushError` |
| 7 | `ModifyMomentumEffect.Amount == 0` / `ModifyManaEffect.Amount == 0` | `PushWarning`（空操作，多半漏填） |
| 8 | `MoveCardEffect`：`From == To` | `PushError` |
| 9 | `BumpCounterEffect.CounterName` 非空但未登记在宿主 `AbilityData.CounterNames` 内 | `PushError` + 报出名与宿主 `Id`（这条使既有的 `CounterNames` 悬空校验闭环） |
| 10 | `RemoveEntryEffect` 的 `TargetSlots` 为空 | `PushError`（「效果必须显式声明目标类别」的机械化） |
| 11 | 单个栈条目的槽位总数 `Σ TargetSlots.Length > 32` | `PushError`（`FizzledSlots` 位掩码的硬上限） |
| 12 | 同上 `> 4` | `PushWarning`（清单式软检查，使多目标牌始终可人工审阅） |
| 13 | `KeywordData` 模板内出现 `EffectData.Keyword != null` | `PushError`（关键字不得引用关键字） |
| 14 | `KeywordData.HasAmount == true` 但模板中无哨兵 / `== false` 但出现哨兵 | `PushError` |
| 15 | `CardData`：`CardType ∈ {Enchantment, Power, Item}` 且 `OnPlay` 非空 | `PushError` |
| 16 | `CardData`：`CardType == Power` 且 `ManaCost != 0` | `PushError`（`Power` 永不被打出） |
| 17 | `CardData`：`CardType == Sorcery` 且 `OnPlay` 与 `Abilities` 皆为空 | `PushWarning`（什么也不做的法术） |
| 18 | 需要选目标的触发式异能占全部触发式异能 `> 10%` | `PushWarning`（既定的编排口径，本方案给出它的机械落点） |
| 19 | 某个 `EffectData` 子类从未被任何内容条目使用 | `PushWarning`（与「关键字未被任何 `KeywordRef` 引用」同构） |

### 代码侧落点（层级）

```
combat-service (service)
└─ StackManager (manager)
   └─ EffectProcessor (processor)     ← 主持六阶段流水线
      ├─ IEffectHandler 注册表 Dictionary<Type, IEffectHandler>
      │  ├─ ModifyMomentumEffectHandler (handler)
      │  ├─ DrawEffectHandler
      │  └─ …（一原语一 handler）
      ├─ IConditionEvaluator 注册表 Dictionary<Type, IConditionEvaluator>
      └─ ModifierEvaluator                ← 阶段 4，读 BattlefieldManager 的静止式修正索引
```

与既定的五级层级词表（service ⊃ manager ⊃ module ⊃ processor ⊃ handler）及「开放 kind ⇒ 一 kind 一 handler」的判据完全对齐。`BattlefieldManager` 按 `TimingId` / `CardType` 预建索引这条既定性能要求，在本方案里同时服务于阶段 4 的修正匹配与阶段 6 的触发匹配。

### 存档面

**零新增字段，空迁移。** `EffectData` / `StaticModifierData` / `TriggerConditionData` / `EffectCondition` 全部是**内容侧静态定义**，经 `CardId` / `abilityId` 解析而来，不落 `ActiveCombat`（与 `CardType` / `Subtypes` 不落存档同款判据）。`BumpCounterEffect` 写的是既有的 `counters` / `Counters`。

### 内容层开张的连带

`content/ability/` 的就绪度由 🔴 转 🟢 的条件即本草稿被采纳；**但它未必需要独立开张为一个内容类型文件夹**——`AbilityData` / `EffectData` 实例几乎恒为某张卡 / 某个神通的组成部分，独立的 `.tres` 只在**跨载体复用**时才有价值。建议 `/scaffold-content-type` 时按「先内联在宿主条目文档里、出现 ≥3 处复用再抽独立条目」处理，判据形状照抄次类型 / 关键字的两条准入。依赖链上 `card` / `character-power` / `character-item` / `player-power` / `player-item` 五个类型随之解锁。

---

## 后果

- **改动面（若采纳）：**
  - `systems/character-profile/deck/common-properties.md` —— `EffectData` 形态、原语清单与参数、`AbilityData` 定义体两格 + XOR、`TriggerConditionData` 完整形态、`EffectCondition`、`CardData` 字段清单收口、加载校验表扩充。**主落点。**
  - `systems/character-profile/deck/_index.md` —— 「效果 / 状态系统 = 三层」小节的原语清单补第 8 个并加参数；补 `StaticModifierData` 是第一层的并列定义体而非 `EffectData` 子类。
  - `systems/services/combat-service.md` —— 新增「效果流水线六阶段」小节；补槽位扁平化编号这条不变式；补 `FizzledSlots` 的 32 位硬上限；（视 `## 仍需用户决定` 第 1 条的裁决，可能需改疲劳「可被取消」那一句）。
  - `content/_index.md` —— `ability/` 就绪度与依赖链下游五个类型的就绪度更新。
- **存档 schema：零改动、空迁移。**
- **derive 就绪度：** 本方案采纳后，`deck/` 一线仍余「starter deck 未设计 · 功法规模参数 · 量纲基准 · 关键字与次类型首批清单 · 抽弃洗数值」五项，**但这五项全部已归属统计校准且不阻断结构**——`deck/` 的 derive 阻塞点从「结构未定」降为「取值未定」。就绪度的正式判定归 `/assess-derive-readiness`，本草稿不代判。
- **内容产能：** 五个内容类型解锁，`content/` 17 个类型中的 🟠 大半转绿。

## 备选方案（已考虑并否决）

- **`Op` 枚举 + 扁平参数表** —— 否决：新增原语要编辑枚举 + 校验 switch + 结算 switch，正撞「新增内容 = 新增数据，不编辑 switch」；且参数表要么压成 `int[]`（让类型说谎）要么摆一排永远大部分无意义的可空格，检视器可写性差。
- **效果表达式串 / 小语言** —— 否决：`deck/common-properties.md` 已就 `Amount` 参数化明确否决通用表达式（求值器 + 沙箱，overlay 热更一段脚本的风险面远大于改一个数值）；效果本体的理由更重。
- **引入 `EffectKind` 判别枚举配合子类树** —— 否决：枚举是一处必须随每个新原语编辑的中心清单，而按 `Type` 注册后新增原语只动装配根一行；错误消息用 `GetType().Name` 即可读。
- **把静止式修正做成 `EffectData` 的一个子类** —— 否决：第一层的定义是「结算时执行的原子操作」，静止式修正不入栈、只在求值瞬间被读取；混装后 `TargetSlots` 对它恒空、`EffectScope` 对其余原语恒无意义，两族语义共用一个类型。
- **`TimingId` 改成 C# 枚举**（`CapabilityFlag` 先例指向它）—— 否决：`"turn.start"` 的点分惯例已被 `CardSubtypeData` 的 id 规范显式引用为先例，改形态要连带改另一处已定案的措辞；字符串 + 加载期封闭集校验拿到的安全性与枚举等同，差别只在编译期 vs 启动期，而本库对内容错误的既定标准恰是启动期大声失败。
- **`Conditions` 同时挂 `AbilityData` 与 `EffectData` 两处** —— 否决：第二权威，两处各自漂移。触发侧的门归 `TriggerConditionData`、启动侧归 `ManaCost` + 配额，element 级归 `EffectData.Conditions`，三者分工不重叠。
- **条件不满足并入 fizzle** —— 否决：战报读不出「为什么没生效」；`FizzledSlots` 的语义是「哪个槽位落空」，条件不满足没有对应槽位。
- **`CardData` 保留独立触发器格** —— 否决：`Abilities` 已完整承载，两个落点必然漂移。
- **`Multiplicative` 取 `float`** —— 否决：全库数值面是整数，浮点会在「加法层结果 × 若干乘数」处引入舍入取向问题；整数百分比可把舍入压成一次、成为可断言的不变式。
- **`Amount` 代入用 `-1` 哨兵** —— 否决：`-1` 已被「无参数」与「不适用」两处占用，且是合法的削减量。

## 与既有决策的张力

**① 与 `systems/architecture.md`「否决多态 element」的表面冲突（判据可区分，建议不视为真张力）。**
`ProfileChangeSpec` 的 `ChangeElement` 明确否决了「`abstract record` + 子类」的多态形态，理由是「破坏 `readonly record struct` 的零分配与 diff / 序列化的简单形态」。本方案给 `EffectData` 取多态子类树，**判据不同故不冲突**：`ChangeElement` 是**落存档、进 diff、在事务热路径上构造**的值类型；`EffectData` 是**内容侧 `Resource`、启动时加载一次、恒不落存档、恒不进 diff**，其零分配压力落在结算读取而非构造。**建议在落笔时把这条区分写进文档**，否则日后必有人拿 `ChangeElement` 那条来质疑本处——两条判据不写在一起就会被当成矛盾。

**② `ADR-0088`（疲劳可被取消）与 `ADR-0087` 一线的 `TargetKind` 无 `StackEntry` 直接冲突。**
`combat-service.md`「疲劳」一节写：「**可被取消**……它取消的是栈上那条疲劳条目，与取消任何其他栈条目同一条通道」；同一份文档的 API 面又写：「`TargetKind` 的 `StackEntry` **不保留**——本作不做『反制栈上条目』这一形态的效果……栈条目**从不作为效果的目标**」。两句不能同时为真：没有寻址栈条目的通道，「取消栈上那条疲劳条目」就写不出来。**本方案不替用户裁决**，见下一节第 1 条。

## 前置依赖

- **`Amount` 的取值域、道念产 / 削的量纲基准、starter deck 的具体内容、功法规模参数** —— 全部已归属「内容扩充后的统计校准」（`systems/balance.md`）。**它们不阻断本方案**：本草稿只给结构与语法，一个数值都不给。但**首批原语清单的最终确认须等 starter deck 设计过程走一遍**——那正是既定的切入点，也是关键字 / 次类型清单重建的同一个切入点。若 starter deck 设计中出现本清单表达不出的语义，按第 3 节的扩展方式补原语。
- **`ModifierTarget` 的清单**（下一节第 2 条）在答定前，第 2 节的 `StaticModifierData` 结构可定稿、**内容不可写**。
- **`combat` 子流三选一裁决**（`open-questions.md` 玩法侧欠账 ③）—— 与本方案无耦合，不构成阻塞。
- **关键字与次类型首批清单为空** —— 不构成阻塞：本方案只依赖两者的**机制**（`KeywordRef` / `EntryFilter.RequiredKeywords` / `RequiredSubtypes`），两条机制均已定案且明写「清单归零、机制保留」。

## 仍需用户决定

### 1. 疲劳「可被取消」的落地形态（🔴 两份已定案文档直接冲突，必须裁决）

**问题陈述：** `ADR-0088` 说疲劳栈条目「可被取消，与取消任何其他栈条目同一条通道」，故「免疫下一次疲劳」这类效果写得出来；而 `TargetKind` 的既定定案明写不保留 `StackEntry`、栈条目「从不作为效果的目标」。二者不能同时成立。裁决结果决定**原语清单里有没有第 9 个原语**。

| 选项 | 后果 |
|---|---|
| **(a)** 新增 `CancelStackEntryEffect` 原语，寻址走 `EffectScope` 式的**栈筛选**（无 `TargetRef`、不挂起、不 fizzle） | 「取消栈条目」成为一条完整的设计面（可取消触发、可反制敌方连锁）。代价：`EntryFilter` 的 `AllowedEntryKinds` 是 `BattlefieldEntryKind`，栈筛选需要**第二套筛选结构**——而「两者共用同一个 `EntryFilter`、各写一套会各自漂移」正是 `ADR-0062` 的承重理由 |
| **(b)** 恢复 `TargetKind.StackEntry` | 语义最直白，与 MTG 的「反制」同形。代价：直接推翻既定的「本作不做反制栈上条目这一形态的效果」；且反制类效果要求玩家在**对手回合**有响应窗口才有意义，而「不借交互与优先权」是 `ADR-0039` 的承重定案——玩家永远无法主动反制，只有埋伏能做到，设计面比看上去窄得多 |
| **(c)（推荐）** 不设取消通道：「免疫疲劳」写成一条 `ForTurns(1)` 的战场条目 + 一条 `StaticModifierData(What = FatigueAmount, Layer = Additive, Amount = +1)`，把疲劳量在求值管线里削到 0 | **零新增结构**：疲劳量已经过阶段 4 的求值管线（第 3 节），修正它与修正任何其他数值同一条路径。`ADR-0088` 的「可被监听、可被响应」原样成立，只有「可被取消」需改写为「可被削减至 0」。代价：`combat-service.md` 疲劳一节须改一句措辞；且真正的「反制」（取消一条已压栈的触发式异能）在本作中确定不存在 |

**推荐 (c)，理由：** ① 它是唯一不引入新寻址空间的选项，而两条既定的承重纪律（`EntryFilter` 单一筛选结构 · 不借交互与优先权）都指向「不要给栈开第二个可寻址面」；② `ADR-0088` 为「可被取消」给出的价值全部落在**「免疫下一次疲劳」这个具体例子**上，而 (c) 恰好完整覆盖它；③ 改动量最小——一句措辞 vs 一套新筛选结构或一条被推翻的定案。

→ **已裁决（2026-08-27 · 批量评审）：(c) 不设取消通道，改为「可被削减至 0」。** 原语清单**没有**第 9 个原语；`combat-service.md` 疲劳一节的「可被取消」须改写为「可被削减至 0」，`ADR-0088` 的「可被监听 / 可被响应」原样成立。连带：`FatigueAmount` 在下一条的清单里由可选变为**必需**。

### 2. `ModifierTarget` 的首批清单（真取向：它决定「哪些数值能被卡牌改写」这条设计面的宽度）

**问题陈述：** 第 2 节的 `StaticModifierData.What` 需要一个可修正量的清单。它不是工程问题——每加一项就多开一整类卡牌设计（也多一处平衡风险与一处 UI 呈现义务），清单宽度是玩法取向。

| 选项 | 清单 | 后果 |
|---|---|---|
| **最小（2 项）** | `MomentumProduced` · `MomentumReduced` | 静止式修正只影响道念产削。最好平衡、最易呈现；但「符箓费用 −1」这类经典 build-around 写不出来，而 `deck/common-properties.md` 恰好把它举为集合性效果的样板边界情形 |
| **中（推荐 · 5 项）** | `MomentumProduced` · `MomentumReduced` · `CardManaCost` · `DrawCount` · `FatigueAmount` | 覆盖已被既有文档举过例的全部形态：「所有『灵兽』获得 +1」（产道念）· 「本场所有『符箓』费用 −1」（`CardManaCost`，`deck/common-properties.md` 的样板）· 牌流向 build（`DrawCount`）· 免疫 / 削减疲劳（`FatigueAmount`，若第 1 条取 (c) 则**必需**）。风险：`CardManaCost` 与 `DrawCount` 都能滚雪球，需在数值校准时盯住 |
| **宽（8+ 项）** | 上述 + `HandLimit` · `ManaLimit` · `TurnLimit` … | 设计面最大。但 `manaLimit` 是**轮回级**由事件推拉的量（`systems/character-profile/mana.md`）、`TurnLimit` 是遭遇参数（`EncounterSpec`，物化时定稿）——让战斗内的静止式修正去改它们会跨越已定的层级边界，需要各自单独论证 |

**推荐「中（5 项）」，理由：** 五项**逐项都能在既有文档里找到一个被举过的例子**（不是为将来预留），而「宽」的三项各自撞上一条既定的层级归属。若第 1 条裁决取 (c)，`FatigueAmount` 从可选变为必需。**枚举成员序应视同冻结、只能追加**（与 `AccountStream` / `Source` 的既定纪律同款），因为它会出现在内容 `.tres` 里。

→ **已裁决（2026-08-27 · 批量评审）：中（5 项）** —— `MomentumProduced` · `MomentumReduced` · `CardManaCost` · `DrawCount` · `FatigueAmount`。第 1 条已取 (c)，故 `FatigueAmount` 为必需项。成员序视同冻结、只能追加。

---

### 3. `StaticModifierData` 的量纲与合并算法须与 `solution-draft-capability-flag-and-entitlement.md` 对齐（跨草稿新增项，非本草稿原有）

本草稿第 2 节的 `Multiplicative` 取**百分比整数**（100 = ×1.0）且算法为「先累乘百分比、最后一次整除」；同批草稿 `solution-draft-capability-flag-and-entitlement.md` 子项 5 的 `ModifierOp.Scale` 取**万分比增量**且算法为「同类求和不连乘 → 只乘一次 → 只取整一次」。同一个词「modifier」在库内出现两个量纲两套舍入，写内容时必然填错。

→ **已裁决（2026-08-27 · 批量评审）：两套并存，但强制对齐量纲与舍入。**
> - **Key 空间分开保留**：`ModifierTarget`（本草稿，战斗内数值，恒不落存档）与 `ModifierKey`（对侧草稿，Profile 侧具名修正，进事务与钳制表）不合并——合并会让「一个 `ModifierKey` 只能有一个施加点」（`ADR-0017` 既定不变式）被战斗内条目撑破。
> - **本草稿须改**：`Multiplicative` 的 `Amount` 由**百分比改为万分比整数**（`10000` = ×1.0），第 2 节正文、代码块注释、`## 备选方案` 中「整数百分比」的措辞一并改齐。
> - **本草稿须改**：合并算法由「先累乘百分比、最后一次整除」改为**「同层求和 → 只乘一次 → 只取整一次」**（对侧草稿子项 5 的算法）。「舍入只发生一次」这条不变式在两套算法下都成立，故本草稿为它给出的论证原样保留。
>
> 提炼时两份草稿须**同批**落笔，否则对齐即失效。
