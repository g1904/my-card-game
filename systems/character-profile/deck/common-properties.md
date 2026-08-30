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
  //   Id / Kind / ManaCost(int, >= 0，仅 Activated) / MaxActivationsPerCombat(int, -1 = 不限，仅 Activated)
  //   TriggerWhen(仅 Triggered)
  //   Effects(EffectData[]，仅 Activated / Triggered) / StaticModifiers(StaticModifierData[]，仅 Static)  —— 二选一，见「效果原语与定义体」
  //   CounterNames(string[]，可空) —— 该异能声明的子计数器名；默认计数器（无 # 段）无须登记
  // TriggerConditionData : Resource
  //   TimingId("turn.start" / "turn.end" / "card.played"…) / OwnerScope / Filter(次类型、费用区间等)
  ```
- **加载时校验规则（坏数据启动即失败）。**

  | 规则 | 违反时 |
  |---|---|
  | `CardType` 必填 | `PushError`，带 `Id` 与 `.tres` 路径 |
  | `Sorcery` 不得带任何异能（`Abilities` 须为空） | `PushError`——结算后进弃牌堆、从不落场，三档异能都以「在场」为前提：静止式无生效载体、启动式无可启动的战场条目、触发式从不注册故永不触发。与 `Affliction` 那条合并同形 |
  | `Affliction` 不得带任何异能 | `PushError` |
  | `Affliction` 允许有 mana 费用与负向效果，但不得有正面效果 | `PushWarning`（软检查，例：业障带产道念的效果 → 警告）——正负难以机械判定，主要靠内容侧纪律 |
  | `Enchantment` 至少带一个异能 | `PushWarning`——不带异能的永久物是空条目，多半漏填 |
  | `MaxActivationsPerCombat == 0` | `PushError`，带 `Id` 与 `.tres` 路径——`0` 是未定义取值，见下 |
  | `Kind != Activated` 时 `MaxActivationsPerCombat != -1` | `PushError`——配额只对启动侧成立，静默忽略会让内容作者以为它生效了 |
  | `AbilityKind == Triggered` 时 `TriggerWhen` 非空 | `PushError` |
  | `Subtypes` 中每个 id 须在次类型注册表中存在 | `PushError`，报出悬空 id |
  | 次类型须与主类型匹配 | `PushError` |
  | `CounterNames` 每个元素匹配子计数器名正则 | `PushError`，带 `Id` 与 `.tres` 路径 |
  | 同一异能内 `CounterNames` 重复 | `PushError`，带 `Id` 与重复项 |
  | `CounterNames` 非空但该名从未被任何效果定义使用 | `PushWarning` —— 与「关键字未被任何 `KeywordRef` 引用」同构 |

  **`CounterNames` 把子计数器名从裸字符串提升为有登记、可悬空校验的标识**，使 `counters` 键的两段获得对称的校验能力——这正是当初选用具名 `AbilityData.Id` 作键主体的那条理由的另一半。不登记的后果不是「不够整洁」：拼错的子名会静默开一个新计数器，配额闸门读到的永远是 0，「每场限 N 次」就此静默失效且只在线上被玩家发现；正则拦不住这一类，因为拼错的名字通常仍然合法。**它是静态内容字段、不落存档**（与 `CardType` / `Subtypes` 同款）。子名正则、键语法与运行期读写两侧的校验见 `systems/services/combat-service.md`「`counters` 的键约定」。
  **启动式异能的代价面 = `ManaCost` 一格 + `MaxActivationsPerCombat` 配额闸，两格都不是 `ProfileChangeSpec`。** **两格都不是必填的**——零费且不限次的启动式异能是合法内容：**组合技达成无限是被接受的设计面**，本作的对局终止性由 `EncounterSpec.TurnLimit` 这条硬护栏承接，不由逐条异能的有限性闸承接。避免**非本意**的无限（作者没打算做无限却写出了无限）归内容侧纪律与 `/audit-content` 对账；工程侧只留一条链长护栏（单次动作链的栈条目总数上限，见 `systems/services/combat-service.md`「效果流水线」），它防的是进程不返回，不限制任何设计面。
  - **`ManaCost` 是独立整数格。** `ProfileChangeSpec` 的资源列以 `CostKey` 索引，而 `CostKey` 与两层 Profile 字段双向满射、其中没有 `CurrentMana`——战斗内的 `currentMana` 是 `activeCombat.sides[]` 上的回合内运行态、战斗外无意义，不是 Profile 字段。塞进去要么伪造一个 `CostKey.CurrentMana`（污染满射不变式），要么让 spec 承载两族语义（Profile 写入 / 战斗内运行态），此后每次读 spec 都要先分辨它属于哪一族——与「`KeywordRef.Amount` 不进 `counters`」被否决的理由逐字同构。**战斗内代价面首版收敛为单一刻度 mana**（不设 Profile 侧代价列）：内容作者不必区分「哪些启动会即时写 Profile」，也天然避开「一条启动式异能间接成为回寿 / 产灵石通道」；日后要开是加一个字段、零存档迁移。扣费时机与失败语义见 `systems/services/combat-service.md`「API 面」。
  - **`MaxActivationsPerCombat` 是显式内容字段，不是埋在效果条件里的一个判断。** 判据是**可预判性**：UI 必须在点下去之前把不可启动项灰显，埋在效果条件里的配额无法被机械预读，UI 只能让玩家点了才被拒。`-1` = 不限、`>= 1` = 配额、**`0` 未定义**——而 `0` 恰是 `[Export]` 的默认值，故漏填必须在加载期被拦（与 `KeywordRef.Amount` 用 `-1` 作哨兵并配一条加载期校验同款）。
  - **配额语义 = 每载体条目、每场。** 运行期落战场条目的 `counters[<abilityId>]`（存档零新增字段）：同一条 `AbilityData` 挂在两个条目上 ⇒ 两份独立计数，阵法多份同名时每份各有配额。它与「『每场限 N 次』类异能须在效果定义里引用自己 `AbilityData.Id` 作键」的内容侧纪律是**分工**关系——字段管启动侧的可预判闸，键引用纪律管触发式与效果内部条件，**两者写的是同一个 `counters` 键**。键语法与两次闸门查询见 `systems/services/combat-service.md`。
- **打出一张卡的结算（共有流程）。** 费用支付（mana）→ 目标选择 → 效果流水线依序执行 → 触发器响应事件。（具体阶段待设计。）**生命周期链路按 `CardType` 分叉**：`Sorcery` / `Affliction` 结算后进弃牌堆；`Enchantment` 结算后作为**永久物**落战场；`Item` 不经卡组、结算后进弃牌堆或按次数消耗；`Power` 开局入场且**永不入栈、永不离场**。

Source: `handoffs/2026-08-04b-mtg-loanwords-card-types-and-intent-snapshot.md` · `handoffs/2026-08-22-card-counters-api-and-key-space.md` · `handoffs/2026-08-26d-activate-ability-contract.md` · `handoffs/2026-08-28-item-use-effect-face-and-carrier-kind.md`

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
- **参数化 = 单个 `Amount` 占位，不做通用表达式。** `KeywordData.HasAmount : bool`；引用侧写 `KeywordRef(KeywordId, Amount)`。通用表达式会把「效果是数据不是代码分支」拖回一个需要求值器与沙箱的小语言，而 overlay 热更一段脚本的风险面远大于改一个数值。**取值域与具体数字归内容扩充后的统计校准**（`systems/balance.md`）。
  **`State` 展开时 `Amount` 落战场条目的 `amount` 一格**（默认 `-1` = 无参数，与 `HasAmount == false` 的约定同值）——同一关键字可用不同 `Amount` 施加两次，故它不可由 `keywordId` 推导；`BattlefieldEntryTemplate` 不带这一格，因为 `Amount` 来自引用侧的 `KeywordRef` 而非模板的属性。字段表见 `systems/services/combat-service.md`。
- **关键字状态的叠加层数没有独立落点，也不需要。** 每次 `ApplyState` 产出**一条独立的 `Transient` 条目**，层数 = 战场上同 `keywordId` + 同 `ownerSide` 的条目计数，一次遍历即得。合并成「单条 + 层数」会强制多次施加共享同一个过期时刻，而生命周期三件套本就是逐条独立倒数的。
- **展开在结算时做，不在加载时内联。** 否则 overlay 热更改一个关键字的定义时，已加载的卡牌拿的是旧展开——`XxxData` 是 ContentRegistry 里的共享只读单例，不能回写。这与「读取侧不过滤 `ContentEnabled`」是同一种收口。

### 清单归零，机制保留

**当前关键字清单为空，一条不留。** 上方的机制部分完整成立；清单本身随内容横向扩展再填。

- **没有任何一个关键字被规则直接引用**：`IgnoresProtection` 是效果级布尔字段、埋伏是次类型 `enchantment.ambush`、疲劳是规则。次类型能留一条是因为 `enchantment.ambush` 是**埋伏机制的定名**；关键字侧没有对应的东西。
- **准入判据照抄次类型的两条**：① 至少 **3 个内容条目**共享它；② 至少 **1 处目标筛选或 payoff 引用它**。**没有 payoff 的关键字就是风味词**，风味写进描述文本——这条纪律正是防止清单长成一批 filler 的机制。
- **重建时机 = ch1 内容横向扩展阶段**，切入点同为 starter deck 的设计过程。关键字的正确清单只能从「哪些组合真的重复了 ≥3 次」倒推，而当前内容条目数为零；预铺一批等于制造一批要在统计校准时全部重写的 filler。

Source: `handoffs/2026-08-16c-effect-keywords-and-targeting.md` · `handoffs/2026-08-22-card-counters-api-and-key-space.md`

## 效果原语与定义体

### `EffectData` = 抽象基类 + 一个原语一个 `[GlobalClass]` 子类

```csharp
// 基类：抽象、不挂 [GlobalClass]（不进检视器的 "New Resource" 选择器）
public abstract partial class EffectData : Resource
{
    [Export] public TargetSlot[]      TargetSlots { get; set; } = [];   // 可空 = 无目标；顺序即槽位序
    [Export] public KeywordRef?       Keyword     { get; set; }          // 非空 = 本元素是一次关键字展开
    [Export] public EffectCondition[] Conditions  { get; set; } = [];   // AND 语义，见下
}

// 每个原语一个子类，参数是它自己的 [Export] 格
[GlobalClass] public sealed partial class ModifyMomentumEffect : EffectData { [Export] public SideConstraint Side; [Export] public int Amount; }
[GlobalClass] public sealed partial class DrawEffect           : EffectData { [Export] public SideConstraint Side; [Export] public int Count;  }
// …（清单见下方原语表）
```

**为什么取子类树而非「`Op` 枚举 + 扁平参数表」（四条判据，不是偏好）：**

| 判据 | 子类树 | `Op` 枚举 + 扁平参数表 |
|---|---|---|
| **检视器可写性**（内容作者天天面对） | 选定子类后**只看得见这个原语的参数**，且各参数有名字与类型 | 一张表上永远摆着全部原语的并集参数格，作者须记住「`Op == Draw` 时只有 `Count` 有意义」，填错的格静默被忽略 |
| **链路类型一致性** | `Count` 是 `int`、`Side` 是 `SideConstraint`、目标类别是 `TargetKind`——各就各位 | 参数表要么压成 `int[]` / `string[]`（让类型说谎），要么摆一排大部分永远无意义的可空格 |
| **加载期校验** | 「`Draw` 的 `Count >= 1`」写在该子类的校验里，天然只对它成立 | 校验须先 `switch (Op)` 再挑格子——正是可加性纪律要消灭的那个 switch |
| **可加性** | 新增原语 = 新增一个子类文件 + 一个 handler 文件，**不编辑任何既有文件的分支** | 新增原语 = 编辑枚举 + 编辑校验 switch + 编辑结算 switch |

- **分派用 `Dictionary<Type, IEffectHandler>`，不引入 `EffectKind` 判别枚举。** 枚举是一处必须随每个新原语编辑的中心清单；按类型注册后，新增原语只在装配根的注册列表里加一行。错误消息与日志用 `GetType().Name`（形如 `[Combat-Effect] unsupported effect type=ModifyMomentumEffect`），不需要枚举来产出可读串。
- **否决效果表达式串 / 小语言。** 与 `Amount` 参数化否决通用表达式同一条理由且更重：求值器 + 沙箱，overlay 热更一段脚本的风险面远大于改一个数值；效果本体一旦可写脚本，「效果是数据不是代码分支」这条承重纪律当场作废。
- **多态子类树在这里成立，与 `ProfileChangeSpec` 的 `ChangeElement` 否决多态不冲突——判据不同，须写在一起。** `ChangeElement` **落存档、进 diff、在事务热路径上构造**，多态会破坏它 `readonly record struct` 的零分配与 diff / 序列化的简单形态；`EffectData` 是**内容侧 `Resource`、启动时加载一次、恒不落存档、恒不进 diff**，其性能压力落在结算读取而非构造。两条判据不并置就会被当成矛盾（层级判据的权威见 `systems/architecture.md`）。
- **Godot 侧可行性是常规做法**：`[Export] Godot.Collections.Array<EffectData>` 中放子类实例，`.tres` 以 `sub_resource` + 脚本引用序列化，多态还原正常；基类保持 `abstract` 且不加 `[GlobalClass]`，使检视器只能选出具体原语。

### `StaticModifierData` —— 与 `EffectData` 并列的第二种定义体

```csharp
[GlobalClass] public sealed partial class StaticModifierData : Resource
{
    [Export] public EffectScope     Scope  { get; set; }   // SideConstraint + EntryFilter，求值瞬间动态匹配
    [Export] public ModifierTarget  What   { get; set; }   // 被修正的量，见下表
    [Export] public ModifierLayer   Layer  { get; set; }   // Additive | Multiplicative —— 既定的两层求值
    [Export] public int             Amount { get; set; }   // Additive 取带符号增量；Multiplicative 取万分比整数（10000 = ×1.0）
}

public enum ModifierLayer  { Additive = 0, Multiplicative = 1 }
public enum ModifierTarget { MomentumProduced = 0, MomentumReduced = 1, CardManaCost = 2, DrawCount = 3, FatigueAmount = 4 }
```

- **`Multiplicative` 取万分比整数而非 `float`**：全库数值面是整数（道念 / mana / `counters` 皆然），浮点会在「加法层结果 × 若干乘数」处引入舍入取向。**合并算法 = 同层求和 → 只乘一次 → 只取整一次**，使「舍入只发生一次」成为可断言的不变式；最后按下限 0 截断。
- **`ModifierTarget` 五项，成员序视同冻结、只能追加**（与 `AccountStream` / `Source` 同款纪律——它会出现在内容 `.tres` 里）。五项逐项都对应一个已被举过的形态：所有『灵兽』获得 +1（产道念）· 削减对方道念的加成 · 「本场所有『符箓』费用 −1」（`CardManaCost`）· 牌流向 build（`DrawCount`）· 免疫 / 削减疲劳（`FatigueAmount`）。**不收 `HandLimit` / `ManaLimit` / `TurnLimit`**：`manaLimit` 是轮回级由事件推拉的量、`TurnLimit` 是物化时定稿的遭遇参数，让战斗内的静止式修正去改它们会跨越已定的层级边界，各需单独论证。
- **`Scope` 按「被修正量的宿主对象」匹配。** 宿主是战场条目时按 `EntryFilter` 全套匹配；**宿主是卡牌时只吃 `RequiredSubtypes`**——手牌是 `CardInstance` 不是战场条目，`AllowedEntryKinds` / `RequiredKeywords` / `IncludeFaceDown` 对它无对象或无意义（与 `HandCard` 槽位那条既定纪律逐字同构）。没有这一条，「本场所有『符箓』费用 −1」这个样板解释不成 `EffectScope`。
- **`AbilityData` 的定义体按 `Kind` 分两格，加载期 XOR 校验**——与 `KeywordData` 的 `Effects` / `StateTemplate` 二选一逐字同构，不新造风格：

  | `AbilityKind` | 定义体格 | 另一格须为空 |
  |---|---|---|
  | `Static` | `StaticModifiers : StaticModifierData[]`（非空） | `Effects` |
  | `Activated` / `Triggered` | `Effects : EffectData[]`（非空） | `StaticModifiers` |

  **静止式异能因此在结构上就装不下任何原子操作**——「静止式不执行原子操作」这条纪律由类型形状承担，不必再写一条校验。

### 首批原语八个（开放可加）

| # | 子类 | `[Export]` 参数 | 语义 |
|---|---|---|---|
| 1 | `ModifyMomentumEffect` | `Side` · `Amount`（带符号） | 产 / 削道念。**下限 0 逐次截断、溢出不结转**；`Declared` = 求值后的标称量，`Actual = After − Before` → `systems/scoring.md` |
| 2 | `DrawEffect` | `Side` · `Count (>= 1)` | 抽 `Count` 张；满手落空（牌留抽牌堆、不产生弃牌堆流量）；抽牌堆空 ⇒ 逐张走疲劳通道 |
| 3 | `DiscardEffect` | `Side` · `Count (>= 1)` · `Selection : DiscardSelection { Random, Chosen }` | 弃牌堆两条填充通道之一。`Chosen` 须配一个 `TargetKind.HandCard` 槽位（强制 `Self`）；`Random` 走 `EffectScope`、**不产生目标交互**——「弃掉对手一张手牌」正是走这条 |
| 4 | `ModifyManaEffect` | `Side` · `Amount` | 改 `sides[].currentMana`，**不改 `manaLimit`**；下限 0 截断 |
| 5 | `ApplyStateEffect` | `Template : BattlefieldEntryTemplate` · `Side` | 产出一条非永久战场条目（`kind = Transient`）；`keywordId` / `amount` 两格由引用侧 `KeywordRef` 填 |
| 6 | `RemoveEntryEffect` | （无独有参数，目标经 `TargetSlots`） | 受目标类别 + `IsProtected` + `TargetSlot.IgnoresProtection` 约束 |
| 7 | `MoveCardEffect` | `From : CardZone` · `To : CardZone` · `Insert : InsertPosition { Top, Bottom }` · `Count : int` · `Selection` | **闭集内的流转，不新造牌**（`ADR-0041`）。`CardZone { DrawPile, Hand, DiscardPile, Battlefield }`——六处位置里**栈不作为流转端点**（栈是结算队列不是区）。`Insert` **仅 `To == DrawPile` 有意义**：顶 / 底是同一个区的两个插入位、不是两个区，存档仍只记一条 `Id` 序列。载体消耗性纪律见 `_index.md` 与 `ADR-0052` |
| 8 | `BumpCounterEffect` | `CounterName : string`（空 = 默认计数器）· `Delta : int` · `Space : CounterSpace { Entry, CardInstance }` | 写 `counters`。**子计数器的写入面只能是效果侧**（`CounterNames` 的悬空校验由它闭环）。键由**宿主 `AbilityData.Id` + `#` + `CounterName`** 在结算期拼出，**内容作者不写完整键**。`Space` 受既定归属判据约束：有过期时刻 → `Entry`，随牌本体整场存活 → `CardInstance` |

- **闭合性核对：** 疲劳**不是原语**（疲劳栈条目结算时执行一条内建的 `ModifyMomentum(Self, −N)`，`N` 经求值管线，故「削减疲劳量」类静止式修正天然可写）· 持续状态 → ⑤ · 驱散 / 拆永久物 → ⑥ · 牌序便利类 → ⑦ · counters → ⑧。起始卡组所需的全部动词落在 ① ② ⑤ 的组合内。
- **扩展方式（写下来，使日后加原语有章可循）：** ① 新增 `XxxEffect : EffectData` 子类文件；② 新增 `XxxEffectHandler : IEffectHandler` 文件；③ 在装配根注册一行；④ 在加载期校验表加一行它自己的参数校验。**不编辑任何既有原语的文件，不编辑任何 switch。**
- **准入判据（照抄次类型 / 关键字那两条的形状）：新原语只有在既有原语的组合确实表达不出该语义时才该存在。** 能用组合表达的一律用组合，否则原语表会长成一批同义词。**首批清单的最终确认须等 starter deck 设计过程走一遍**——那正是关键字与次类型清单重建的同一个切入点。

### 触发器 `TriggerConditionData`

```csharp
[GlobalClass] public sealed partial class TriggerConditionData : Resource
{
    [Export] public string             TimingId   { get; set; } = "";  // 见下方常量表
    [Export] public TriggerOwnerScope  OwnerScope { get; set; }        // Self / Opponent / Either
    [Export] public TriggerFilter      Filter     { get; set; }
}

public sealed record TriggerFilter(
    EntryFilter EntryFilter,     // 复用既定结构（次类型 ∩ 关键字 ∩ faceDown），条目类时点用
    CardType[]  CardTypes,       // 空 = 不限；卡牌类时点用
    int         ManaCostMin,     // -1 = 不限
    int         ManaCostMax);    // -1 = 不限

public static class TimingIds    // 首批十个，封闭，随广播点一同增长
{
    public const string CombatStart     = "combat.start";
    public const string TurnStart       = "turn.start";
    public const string TurnEnd         = "turn.end";
    public const string CardPlayed      = "card.played";
    public const string CardDrawn       = "card.drawn";
    public const string CardDiscarded   = "card.discarded";
    public const string EntryEntered    = "entry.entered";
    public const string EntryLeft       = "entry.left";
    public const string Fatigue         = "fatigue";
    public const string MomentumChanged = "momentum.changed";
}
```

- **`TimingId` 的值域是代码侧封闭常量表，不是内容层注册表。** 判据与「capability flag 的载体是 C# `enum` 而不是字符串 key」同源：**一个时点必须有一处对应的广播点，而广播点是代码**；`.tres` 里写下一个没人广播的时点，会得到一条静默永不触发的异能，且它在加载期完全合法。**新增时点 = 新增一处广播点 + 表里加一行**，两者一同增长。
- **保留点分字符串形态而不改成枚举。** `"turn.start"` 这一惯例已被 `CardSubtypeData` 的 id 规范**显式引用为先例**（见 `_index.md`「次类型体系的落地形态」），改形态要连带改另一处已定案的措辞；字符串 + **加载期封闭集校验**（`TimingId ∉ TimingIds.All` → `PushError` + 报出宿主 `AbilityData.Id`）拿到的安全性与枚举等同，差别只在编译期 vs 启动期，而本库对内容错误的既定标准恰是**启动期大声失败**。
- **每个时点声明一个 `SubjectKind { None, Card, Entry, Side }`**（代码侧同表），加载期校验 `TriggerFilter` 只填了与该 subject 相容的格：`Card` ⇒ `EntryFilter` 须为空 · `Entry` ⇒ `CardTypes` / `ManaCost*` 须为空 · `None` ⇒ 整个 `Filter` 须为空。防的是「给『回合开始时』写了一条按次类型的筛选」这种静默无效的填写。

### 条件 `EffectCondition` —— 封闭的谓词小集合，AND 语义

```csharp
public abstract partial class EffectCondition : Resource { }

[GlobalClass] public sealed partial class CounterAtLeastCondition : EffectCondition
{ [Export] public string CounterName = ""; [Export] public CounterSpace Space; [Export] public int Value; }

[GlobalClass] public sealed partial class EntryCountCondition : EffectCondition
{ [Export] public EffectScope Scope; [Export] public int Min = -1; [Export] public int Max = -1; }  // -1 = 不限

[GlobalClass] public sealed partial class MomentumCondition : EffectCondition
{ [Export] public SideConstraint Side; [Export] public int Min = -1; [Export] public int Max = -1; }
```

- **组合语义恒为 AND，不支持 OR / NOT**——与 `EntryFilter` 的既定处理逐字同构（可机械校验、卡面文案好写；OR 的需求由内容侧写两条 element 绕过）。三个谓词覆盖已被既有定案预设为可写的全部条件形态：「每场限 N 次」类（配 ⑧ 的写入侧）· 「场上有 ≥N 个带某关键字的条目时」类 · 「对方道念低于 X 时」类。扩展方式同原语：新增一个谓词 = 一个子类 + 一个求值器。
- **条件不满足 ≠ fizzle。** 二者必须分开，否则战报读不出「为什么没生效」：**fizzle 专指目标非法**（由 `FizzledSlots` 位掩码表达）；**条件不满足是该 element 整条跳过**，`Declared` 对该 element 记 0、**不置 `FizzledSlots` 任何位**。
- **求值时机 = 逐 element 就地求，读当前局面**（含同序列内前序 element 的产物）；数值则整条一次求完。两个时机刻意不同，理由与 AI 试算侧的例外见 `systems/services/combat-service.md`「效果流水线」。
- **内容侧硬纪律：凡 UI 需要在点下去之前预判的门，一律不得表达为 `EffectCondition`。** 这是「`MaxActivationsPerCombat` 是显式内容字段、不是埋在效果条件里的一个判断」的一般化——埋在条件里的门无法被机械预读，UI 只能让玩家点了才被拒。`EffectCondition` 只承载**结算时才求值、UI 不必预判**的门。加载期无法机械校验，落为内容侧纪律 + `/audit-content` 对账。
- **条件挂 `EffectData` 一处，不挂 `AbilityData`。** 触发侧的门由 `TriggerConditionData` 承担、启动侧由 `ManaCost` + 配额承担，剩下的「这一步在什么局面下才发生」是 element 级的事。挂两处即第二权威，两处各自漂移。

### 关键字模板的 `Amount` 代入 = 哨兵值

- **`EffectData.KeywordAmountSentinel = int.MinValue`。** 模板里任何一个整数 `[Export]` 参数写成该哨兵，即表示「此处代入引用侧 `KeywordRef.Amount`」。
- **取 `int.MinValue` 而非 `-1`**：`-1` 已被两处占用（`KeywordRef.Amount` 的「无参数」约定、`RemainingTurns` 的「不适用」），且 `-1` 是合法的削减量；哨兵必须是绝不可能作为真实数值出现的取值。
- **关键字不得引用关键字**（`KeywordData` 模板内的 `EffectData.Keyword` 须为空）→ 保证展开**恰好一层收敛**，无递归、无展开深度、无环检测。

### `CardData` 的字段清单收口

| 格 | 结论 | 依据 |
|---|---|---|
| **费用** | `[Export] int ManaCost`（`>= 0`），**独立整数格** | 与 `AbilityData.ManaCost` 那条推理逐字适用：`currentMana` 是 `activeCombat.sides[]` 上的回合内运行态、不是 Profile 字段，`CostKey` 与两层 Profile 字段双向满射且其中没有 `CurrentMana` |
| **触发器** | **不设这一格**，`Abilities : AbilityData[]` 已完整承载触发式（`Kind == Triggered` + `TriggerWhen`） | 「触发的匹配逻辑不能写死在卡牌类型里」+「异能抽为独立可复用资源」两条既定推论直接得出。再开一格即第二权威：同一张牌的触发有两个落点，两处各自漂移而本库无机制发现 |
| **打出时效果** | `[Export] EffectData[] OnPlay` | `Sorcery` / `Affliction` 打出时的一次性效果不属异能三分中的任何一档（没有「打出时」这一 `AbilityKind`），必须有自己的格 |

**阵法（`Enchantment`）不需要 `OnPlay`**：入场效果写成一条 `Triggered` 异能 + `TimingId = "entry.entered"` + `OwnerScope = Self` 即可，与其余触发完全同构，不为它开第二条路径（加载期强制 `OnPlay` 为空）。

**完整字段清单：** `Id` · `DisplayName` / `Description`（`LocalizedText`）· `CardType`（必填无默认）· `Subtypes` · `Pool`（必填无默认）· `Rarity`（必填）· `ContentEnabled` · **`ManaCost`** · **`OnPlay : EffectData[]`** · `Abilities : AbilityData[]` · `CodexFlavor?` · **`Artwork`（共有字段 · `Texture2D`）**。

- **`Artwork`（共有字段 · 类型 `Texture2D`）。** 本层落在 `CardData` 上 = **卡面插画**。
  - **本层合法取值 / 默认值 =** 可空，默认 `null`（尚未产出 → 呈现层回落占位）。
  - **本层消费点：** 手牌区 · 卡牌详情页 · 构筑界面。
  - 资产约束（竖版构图 · full art 不预留文字区 · 缩略尺寸下各卡须彼此可区分）见 `art/visuals/_index.md`「卡面插画」；类型定义与校验语义见 `systems/common-properties.md`。

### 加载期校验（本节新增；既有各条原样保留）

| # | 规则 | 违反时 |
|---|---|---|
| 1 | `AbilityData`：`Kind == Static` ⇒ `StaticModifiers` 非空且 `Effects` 为空 | `PushError` + `Id` + `.tres` 路径 |
| 2 | `AbilityData`：`Kind ∈ {Activated, Triggered}` ⇒ `Effects` 非空且 `StaticModifiers` 为空 | `PushError` + 同上 |
| 3 | `TriggerConditionData.TimingId ∉ TimingIds.All` | `PushError` + 报出该 id 与宿主 `AbilityData.Id` |
| 4 | `TriggerFilter` 填了与该 `TimingId` 的 `SubjectKind` 不相容的格 | `PushError`，指名是哪一格 |
| 5 | `StaticModifierData`：`Layer == Multiplicative` 且 `Amount < 0` | `PushError`（负乘数无定义语义） |
| 6 | `DrawEffect.Count < 1` / `DiscardEffect.Count < 1` / `MoveCardEffect.Count < 1` | `PushError` |
| 7 | `ModifyMomentumEffect.Amount == 0` / `ModifyManaEffect.Amount == 0` | `PushWarning`（空操作，多半漏填） |
| 8 | `MoveCardEffect`：`From == To` **且** `To != DrawPile` | `PushError`。**抽牌堆内重排是合法的**（把堆顶的废牌压到堆底），故它是这条的例外 |
| 9 | `BumpCounterEffect.CounterName` 非空但未登记在宿主 `AbilityData.CounterNames` 内 | `PushError` + 报出名与宿主 `Id`（使既有的 `CounterNames` 悬空校验闭环） |
| 10 | `BumpCounterEffect` 或 `CounterAtLeastCondition` 出现在 `CardData.OnPlay` 内 | `PushError`。两者的键由**宿主 `AbilityData.Id`** 拼出，而 `OnPlay` 的 element 没有宿主异能，键根本拼不出来（键空间闭合于 `<abilityId>[#<子名>]`） |
| 11 | `RemoveEntryEffect` 的 `TargetSlots` 为空 | `PushError`（「效果必须显式声明目标类别」的机械化） |
| 12 | 单个栈条目的槽位总数 `Σ TargetSlots.Length > 32` | `PushError`（`FizzledSlots` 位掩码的硬上限） |
| 13 | 同上 `> 4` | `PushWarning`（清单式软检查，使多目标牌始终可人工审阅） |
| 14 | `KeywordData` 模板内出现 `EffectData.Keyword != null` | `PushError`（关键字不得引用关键字） |
| 15 | `KeywordData.HasAmount == true` 但模板中无哨兵 / `== false` 但出现哨兵 | `PushError` |
| 16 | `CardData`：`CardType ∈ {Enchantment, Power, Item}` 且 `OnPlay` 非空 | `PushError` |
| 17 | `CardData`：`CardType == Power` 且 `ManaCost != 0` | `PushError`（`Power` 永不被打出） |
| 18 | `CardData`：`CardType == Sorcery` 且 `OnPlay` 为空 | `PushWarning`（什么也不做的法术。`Sorcery` 的 `Abilities` 恒空，故只判 `OnPlay` 一格——法术的一次性效果本就走 `OnPlay`） |
| 19 | 某个 `EffectData` 子类从未被任何内容条目使用 | `PushWarning`（与「关键字未被任何 `KeywordRef` 引用」同构） |
| 20 | `TimingId == card.played` 且该触发的 `TriggerFilter.CardTypes` 仅含 `Item` | `PushWarning`（该异能永不触发：道具在战斗内以 `CardType.Item` 呈现，但用道具不广播 `card.played`——形态见 `systems/services/combat-service.md` 的 `UseItem` 段。清单式软检查，与上方 `> 4` 一条同构） |

> 「需要选目标的触发式异能 ≤ 10%」那条统计式 `PushWarning` **已存在**，落点在 `systems/services/combat-service.md`（决策点清单一节），不在本表重复登记。

### 存档面

**零新增字段、空迁移。** `EffectData` / `StaticModifierData` / `TriggerConditionData` / `EffectCondition` 全部是**内容侧静态定义**，经 `CardId` / `abilityId` 解析而来，不落 `ActiveCombat`（与 `CardType` / `Subtypes` 不落存档同款判据）。`BumpCounterEffect` 写的是既有的 `counters` / `Counters`。代码侧落点 = `combat-service > StackManager > EffectProcessor > handler`（一原语一 handler），与「开放 `kind` ⇒ 一 kind 一 handler」的既定判据对齐。

Source: `handoffs/2026-08-27-ability-primitive-grammar.md` · `handoffs/2026-08-28-item-use-effect-face-and-carrier-kind.md` · `handoffs/2026-08-28-content-artwork-enemy-lines-and-ai-weight-vector.md` · `handoffs/2026-08-30-stack-entry-kind-for-item-use.md`

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

- **`EffectData` = 抽象基类 + 一原语一 `[GlobalClass]` 子类（按 `Type` 分派，无判别枚举）；`StaticModifierData` 是并列的第二种定义体、`AbilityData` 按 `Kind` 分两格 + XOR 校验；首批八个原语与十个 `TimingId`；`EffectCondition` 三个谓词、AND 语义、条件不满足 ≠ fizzle；`CardData` 字段清单收口为 `ManaCost` + `OnPlay`、不设独立触发器格；存档零新增字段。**
- **关键字 = 内容层注册表条目 `KeywordData`（两种 `KeywordKind`，不新增第四类效果载体）；单 `Amount` 参数；展开在结算时做；清单归零、机制保留 + 两条准入判据。**
- **目标 target 与作用域 scope 分开建模，共用同一个 `EntryFilter`；「效果须显式声明目标类别」只约束 `TargetSlots`。**
- **一槽位 = 恰好一个目标；`SideConstraint` 相对施放者解析；`EntryFilter` 组合语义恒为 AND；`HandCard` 槽位强制 `Self` 且只吃 `RequiredSubtypes`。**
- **`AbilityData` 增 `CounterNames`（子计数器名登记，加载期三条校验，不落存档）；`KeywordRef.Amount` 落战场条目的 `amount` 一格；叠加层数由同 `keywordId` + 同 `ownerSide` 的条目计数重算，不设独立计数器。**
- **`AbilityData` 的启动代价面 = `ManaCost`（`int`，独立整数格、不进 `ProfileChangeSpec`）+ `MaxActivationsPerCombat`（`int`，`-1` = 不限、`0` 非法），首版不设 Profile 侧代价列；两格均非必填（无限组合是被接受的设计面，终止性由 `TurnLimit` 承接）；配额哨兵两条校验保留；配额语义为每载体条目每场、运行期落既有 `counters`。**

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **起始卡组的具体内容（starter deck）。** `CardData` 的字段清单已收口（见「效果原语与定义体」），装哪些牌仍空白；它同时是原语 / 关键字 / 次类型三份首批清单的共同切入点。→ `systems/balance.md`。
- **抽 / 弃 / 洗数值。** 手牌上限、每回合抽牌数、初始牌堆规模等属平衡数值 → `systems/balance.md`。

## 对应
提炼至：`.claude/knowledge/data/_index.md`（CardData）；`.claude/knowledge/systems/character-profile/deck/`（待建）。
