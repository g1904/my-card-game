---
type: solution-draft
date: 2026-08-16
question: 效果关键字体系（可复用的效果词汇表）与目标规则的完整判据（合法目标集如何计算、谁可以指定谁）
source: open-questions/01-combat.md → 结构与配置的残留 → 「效果关键字体系与目标规则（承重 · 需一次专门 handoff）」
targets: systems/character-profile/deck/common-properties.md · systems/character-profile/deck/_index.md · systems/adventure-event/common-properties.md · systems/services/combat-service.md
status: distilled
decided: 2026-08-16 —— 四项取向全部按推荐项定案（见「## 已定案的取向」）
reviewed: 2026-08-16 —— 用户评审后另裁三项：战场条目新增 `keywordId` 并 bump schema（推翻本稿「不 bump 存档 schema」）· `PlayCard` 改收 `TargetRef` 列表且挂起三条件只管结算侧槽位 · `HandCard` 槽位的 `EntryFilter` 只吃 `RequiredSubtypes`
distilled-to: handoffs/2026-08-16c-effect-keywords-and-targeting.md
---

# 方案草稿 — 效果关键字体系与目标规则

## 问题

效果系统的**三层骨架已定**（`EffectData` 原子操作 → `BattlefieldEntry` 战场条目 → 加法层 + 乘法层求值管线），
`TargetRef` / `TargetKind` 的**运行时载体形态也已定**（`combat-service.md` 的 API 面与 `ActiveCombat` 存档 schema）。
但两处仍是结构占位：

1. **关键字体系** —— 可复用的效果词汇表。当前 `EffectData` 只有七个原子操作，
   一张牌若要表达「灼烧 2」这类反复出现的组合，只能每张牌各自把原子操作抄一遍。
   **卡面文本压缩没有载体、图鉴无处可查、`ContentEnabled` 无处可挂、效果筛选无从按状态名引用。**
2. **目标规则的完整判据** —— 已定的只有两条散点：「非永久条目可被针对，但效果须显式声明目标类别」
   与「目标合法性 = 类别匹配 且（`IsProtected == false` 或 `IgnoresProtection`）」。
   **合法目标集怎么算、谁能指定谁、多目标怎么表达、选定之后局面变了怎么办、什么时候要玩家点一下**，全部没有回答。

卡住的东西：`CardData` 的「目标声明 / 效果引用」两格字段无法定稿 ⇒ `CardData` 字段清单无法定稿 ⇒
starter deck 写不出来 ⇒ **ch1 数值标杆专场缺切入点**。同时 `systems/services/combat-service.md`
与 `systems/character-profile/deck/` 两份文档在 derive 就绪度里同为 blocked，本条是其中一处共同卡点。

## 约束（来自既有设计）

- **`EffectData` 是数据不是代码分支**：新增一张卡 = 新增 `.tres` 并组合已有元素，不编辑 switch。→ `deck/_index.md`「效果 / 状态系统 = 三层」。
- **一切增益减益都是战场条目**，本作不存在「参战方身上的 buff / debuff 列表」。→ 同上，承重推论。
- **`TargetKind { None, Side, BattlefieldEntry, HandCard }`，`StackEntry` 明确不入枚举**（本作不做反制栈上条目）。→ `combat-service.md`。
- **`TargetRef(Kind, Side, EntryId)`；`chosenTargets` 是按槽位顺序的 `TargetRef[]`；挂起态 `pending = { stackEntryId, slotIndex }` 全局至多一个。** ⇒ **效果本来就有「多个目标槽位」这一结构**，只是槽位的声明侧没写。→ `combat-service.md` 的 `ActiveCombat` 栈条目表。
- **`LegalTargets` 不落存档，恢复时按当前局面重算。** → 同上「挂起态」小节。
- **`controllerSide` 决定这次目标选择是否产生决策点**；敌人的目标选择由 EnemyManager 自行决定、不产生决策点。→ `combat-service.md` D4。
- **结算不是原子同步过程**：`RunCombatAsync` 的结算循环是可挂起、可中途恢复的状态机。→ 同上，承重推论 ②。
- **次类型必须能被效果引用**（「所有『灵兽』获得 +1」是次类型存在的主要理由）；次类型 = 稳定字符串 id + 注册表 + `<maintype>.<name>` 点号分段，**不用 C# 枚举**；准入判据 = ①≥3 条目共享 ②≥1 处筛选引用；**当前清单归零，只留 `enchantment.ambush`**。→ `deck/_index.md`「次类型体系的落地形态」。
- **`CardData.Pool { Character, Enemy, Both }`**：同一张牌可能同时出现在玩家侧与敌人侧。→ 同上「卡池划分」。
- **`IsProtected` 恒 true 只在 `Power`；`IgnoresProtection` 是效果级布尔，配额 ≈1%、配清单式 `PushWarning`。** → `terminology.md` · `deck/_index.md`。
- **无交互、无优先权、出牌时机唯一；战斗定长 10 回合（双方各 5）。** ⇒ 卡面必须能一眼读完，决策点不能因目标选择而暴增。
- **移动优先 · 竖屏 · 无 hover-only 可供性。** → `.claude/rules/ui-input-rules.md`。
- **内容文本走 `LocalizedText`，UI 文案走 `res://text/` 翻译键，两条链路不混。** → `systems/common-properties.md`。
- **加法先于乘法是规则不是实现细节；求值只在使用时聚合，没有回滚概念。** → `deck/_index.md` 第三层。

## 建议方案

### 1. 关键字 = 一个内容层注册表条目，形态照抄次类型 `[既有推演]`

**建议 `[GlobalClass] partial class KeywordData : Resource`**，与 `CardSubtypeData` 完全同构：
稳定字符串 `Id`（`<kind>.<name>` 点号分段）· 经 ContentRegistry 加载 · `.tres` 编写 · 带 `ContentEnabled` ·
`Rarity` 不挂（关键字不进抽取池）。

**为什么必须是独立条目，而不是「纯呈现层的文案简写」——三条理由与功法否决「纯标记方案」的三条逐条同构：**

| 理由 | 纯文案简写方案会怎样 |
|---|---|
| ① **效果筛选要能按关键字引用** | 战场条目**没有 `Subtypes` 字段**（次类型挂在 `CardData` 上，而持续状态条目的来源可能是异能而非某张牌）。「移除对方所有带『灼烧』的条目」这类 payoff 在纯文案方案里**根本没有筛选键** |
| ② **`ContentEnabled` 的原子性** | 关掉一个关键字要改 N 张卡的效果定义，**漏一张即得到一条半生效的规则** |
| ③ **一处可读 / 可校验** | 「这个关键字到底是什么意思」要 grep 全库；关键字拼错从编译期推迟到运行时，且悬空引用无从校验 |

**两种关键字，与既定三层各归其位（这条切分是承重的）：**

| 种类 | `KeywordKind` | 定义体 | 落在三层的哪一层 | 例（形态说明，非清单） |
|---|---|---|---|---|
| **关键字动作** | `Action` | 一段 `EffectData[]` 模板 | 第一层（结算时执行的原子操作组合） | 「〈某动作〉N」= `Discard(N)` + `Draw(N)` 这类固定组合的命名 |
| **关键字状态** | `State` | 一份**战场条目模板**（`AbilityData[]` + 默认 `EntryLifetime` / `CountdownSide`） | 第二层（`ApplyState` 产出的非永久战场条目） | 「〈某状态〉N」= 一条带静止式修正的 `ForTurns(N)` 条目 |

**关键字不新增第四类东西**——`Action` 展开为已有的原子操作，`State` 展开为已有的战场条目。
它是**命名与复用的一层**，不是机制的一层。这条必须写死，否则日后会有人把「关键字」当成第三种效果载体。

**参数化：单个 `Amount` 占位，不做通用表达式。** `KeywordData.HasAmount : bool`；引用侧写 `KeywordRef(KeywordId, Amount)`。
理由：MTG 的 `scry N` / StS 的 `Vulnerable N` 覆盖了绝大多数实际需求，而通用表达式会把
「效果是数据不是代码」拖回一个需要求值器的小语言。**取值域与具体数字归 ch1 数值标杆专场，本方案只定形态。**

### 2. 关键字首批清单 = 空 `[既有推演]`

**建议与次类型「清单归零，机制保留」完全同构：机制现在就定，清单一条不预铺。**

- 当前**没有任何一个关键字被规则直接引用**——`IgnoresProtection` 是效果级布尔字段（不是关键字）、
  埋伏是次类型（`enchantment.ambush`）、疲劳是规则。次类型能留一条是因为 `enchantment.ambush` 是**埋伏机制的定名**；
  关键字侧**没有对应的东西**，故一条都不留。
- **准入判据照抄次类型的两条**：① 至少 **3 个内容条目**共享它；② 至少 **1 处目标筛选或 payoff 引用它**。
  **没有 payoff 的关键字就是风味词**，风味写进描述文本。
- **重建时机 = ch1 内容横向扩展阶段**，切入点同样是 starter deck 的设计过程。

**这不是把问题推走，而是把它推到唯一能答对的地方**：关键字的正确清单只能从「哪些组合真的重复了 ≥3 次」倒推，
而当前内容条目数为零。预铺一批 = 制造一批 filler，且每条都要在 ch1 专场推翻重来。

### 3. 目标（target）与作用域（scope）是两个东西，必须分开建模 `[既有推演 · 承重]`

这是本方案最承重的一条，也是「目标规则完整判据」缺的那一半。
既有文档里它**已经隐含存在但从未命名**——`CardInstance` 运行态判据的第二条理由写着
「『所有灵兽获得 +1』作用于一个随时间变化的集合，写进实例语义直接错」。给它命名：

| | **目标 target** | **作用域 scope** |
|---|---|---|
| 锚定 | 结算那一刻由 `TargetRef` 锚定到**具体条目** | 求值那一刻按筛选条件**动态匹配** |
| 承载 | `EffectData.TargetSlots` | 静止式修正的 `EffectScope` |
| 玩家参与 | 可能需要玩家点选（挂起态） | **永不需要玩家输入** |
| 局面变了 | 可能非法 → fizzle（见 4） | 无所谓，下次求值自然重算 |
| 落存档 | `chosenTargets : TargetRef[]` | **不落存档**（不是状态，是筛选条件） |
| 卡面文案 | 「目标〈类别〉」 | 「所有〈筛选〉」 |

**推论 ①：静止式修正永远不需要目标规则**，故「效果必须显式声明目标类别」这条纪律
只约束 `TargetSlots`，不约束 `EffectScope`。此前这两者混在一起，是「目标规则写不下去」的直接原因。

**推论 ②：两者共用同一个筛选结构 `EntryFilter`，不各写一套**（否则两份筛选条件各自漂移，
而本库没有机制发现它们不一致——`common-properties.md` 判据卡的硬边界）。
差别只在**是否需要 `TargetRef` 锚定**。

### 4. 合法目标集的完整判据 `[既有推演]` + fizzle 语义 `[通行做法]`

**合法目标集 = 在需要它的那一刻，对当前局面跑一遍筛选。永不预存、永不缓存。**
（这是既定「`LegalTargets` 不落存档、恢复时按当前局面重算」的正面表述。）

```
LegalTargets(slot, controllerSide, battlefield, hands) =
    候选集 ← 按 slot.Kind 取全集
              None            → { }                     // 无需求解
              Side            → { Character, Enemy }
              BattlefieldEntry→ battlefield 全部条目
              HandCard        → controllerSide 的手牌实例   // 见下方「信息边界」
    过滤 ① 方位：slot.SideConstraint 相对 controllerSide 解析（Any / Self / Opponent）
    过滤 ② 类别：slot.AllowedEntryKinds 命中（PermanentCard / PermanentPower / Transient）
    过滤 ③ 保护：entry.IsProtected == false || slot.IgnoresProtection
    过滤 ④ 筛选：slot.Filter（次类型 ∩ 关键字 ∩ faceDown 可见性）
    → 结果集
```

**四条过滤的顺序不是规则**（结果与顺序无关，交集可交换）——写成这个顺序只为可读与短路。
与「加法先于乘法是规则」相区分，此处应明写「顺序非规则」，免得日后被误当成第二条顺序敏感性。

**`SideConstraint` 相对施放者解析，绝不写绝对方 `[既有推演]`。**
理由是 `CardData.Pool = Both` 的直接推论：同一张牌可能同时出现在玩家卡组与敌人卡组里，
写绝对方会让它在敌人手里语义翻转。**加载期校验：`TargetSpec` 不得出现绝对方取值**（枚举里就不放）。

**结算时重检 + MTG 式部分 fizzle `[通行做法]`。**
LIFO 连锁下，栈上更靠上的条目可能移除掉下面那条已选定的目标 ⇒ **fizzle 情形在本作真实存在**（不是理论问题）。
建议照借 MTG 的成熟规则：

- 结算时**逐槽位重检**合法性；
- **部分槽位非法 → 该槽位不产生效果，其余槽位照常结算**；
- **全部有目标的槽位都非法 → 整条不结算**（`Declared` 记为 0，ticker 明写「目标已不存在」）。

否决「全有全无」：一张两槽位的牌因为对手拆掉其中一个目标就整条落空，在 5 回合定长对局里是过重的惩罚，
且玩家没有响应窗口去补救。**逐步反馈是硬要求 ⇒ fizzle 必须在 ticker 上可见**，这是 `ux/combat-ux.md` 的连带项。

### 5. 什么时候才让玩家点一下 `[既有推演]`

挂起态 `pending` 昂贵：它是一个决策点（D4）、要落存档、要 push、要打断结算状态机。
既定条件是「`controllerSide` 决定这次目标选择是否产生决策点」，建议把它补全为三条：

> **槽位产生挂起，当且仅当：**
> ① `Kind ∈ { BattlefieldEntry, HandCard }`（`None` / `Side` 恒可自动解析）；
> ② `controllerSide == Character`（敌人侧由 EnemyManager 自行决定，既定）；
> ③ `LegalTargets.Count > 1`。

- **`Count == 1` → 自动选定，不挂起。** 省一次无意义点击，且省一个决策点与一次存档写。
  在 5 回合定长 + 移动端竖屏下这是实打实的节奏收益。
- **`Count == 0` → 该槽位判非法**，走第 4 条的 fizzle 分支，不挂起（不能让玩家面对一个空的高亮集）。
- **推论：`Kind == Side` 且 `SideConstraint != Any` 的槽位永不挂起。**
  「削对方 3 点道念」= 一个 `Side / Opponent` 槽位，自动解析，玩家无需点击——
  **绝大多数产 / 削道念的牌因此零点击**，与既定的低交互定位一致。

### 6. `HandCard` 槽位强制 `Self` `[既有推演]`

`SideSnapshot.HandCardInstanceIds` **敌方恒为空**（既定填充纪律），`HandCount` 只给计数。
⇒ **玩家看不见对手手牌的任何条目 ⇒ UI 无从高亮 ⇒「指定对手某张手牌」不可能成为合法目标。**

建议：`TargetSpec.Kind == HandCard` 时 `SideConstraint` 必须为 `Self`，否则加载期 `PushError`。
这同时封住一条会与既定信息面正面冲突的设计口子（对手手牌的可见性是埋伏之外的第二条信息泄漏面）。

**注：这不封死「弃掉对手一张手牌」这类效果**——那走 `EffectScope`（随机 / 全部，无 `TargetRef`），不走目标槽位。
`Discard` 原子操作本就在清单里。**这正是第 3 条切分的第一个实用价值。**

### 7. 卡面文案纪律 `[既有推演]`

- **每个目标槽位必须在卡面显式点名类别**（既定纪律的落地：「摧毁目标阵法」而非「摧毁目标」）。
- **多槽位时，卡面文案顺序 = 槽位顺序 = 玩家被询问的顺序**（`slotIndex` 即两者）。这是硬要求，否则玩家不知道现在在选哪个。
- **关键字在卡面只印名字，提醒文本走长按**（`ReminderText`）——竖屏卡面装不下完整定义，
  且「无 hover-only 可供性」要求触控等价物。**永远长按，首次出现不自动展开**（已定案 ②）——
  「首次」这件事要记账（落哪个 Profile？跨轮回还是轮回内？），**为一条呈现便利新增一个存档字段不划算**。
  若实测新手看不懂，自动展开一次是现成的退让位。

## 具体形态（可 derive 的落地面）

```csharp
// ── 关键字 ────────────────────────────────────────────────
public enum KeywordKind { Action = 0, State = 1 }

[GlobalClass] // KeywordData : Resource
//   Id           : string          — <kind>.<name>，点号分段、snake_case 词身（沿用 TimingId / 次类型惯例）
//   Kind         : KeywordKind     — 必填，无默认值
//   DisplayName  : LocalizedText   — 卡面印的那个词
//   ReminderText : LocalizedText   — 长按展开的完整定义
//   HasAmount    : bool            — 是否带单个数值参数
//   Effects      : EffectData[]    — 仅 Kind == Action：展开成的原子操作序列
//   StateTemplate: BattlefieldEntryTemplate?  — 仅 Kind == State：展开成的战场条目模板
//   ContentEnabled : bool = true

public readonly record struct KeywordRef(string KeywordId, int Amount);  // Amount 在 HasAmount == false 时恒为 -1

// ── 筛选（目标与作用域共用，不各写一套）─────────────────────
public enum SideConstraint { Any = 0, Self = 1, Opponent = 2 }   // 一律相对 controllerSide 解析

public sealed record EntryFilter(
    BattlefieldEntryKind[] AllowedEntryKinds,  // 空 = 不限
    string[]               RequiredSubtypes,   // 次类型 id；组合语义恒为 AND（已定案 ③，无 OR / NOT）
    string[]               RequiredKeywords,   // 关键字 id；组合语义恒为 AND（同上）
    bool                   IncludeFaceDown);   // 默认 false（已定案 ④）；内容侧纪律 = 当前不使用

// ── 目标槽位（声明侧；运行时载体仍是既定的 TargetRef）───────
public sealed record TargetSlot(              // 一槽位 = 恰好一个目标（已定案 ①，无 TargetCount 字段）
    TargetKind     Kind,               // None | Side | BattlefieldEntry | HandCard（既定枚举，不扩）
    SideConstraint Side,
    EntryFilter    Filter,
    bool           IgnoresProtection); // 既定的效果级布尔，落在槽位上

// ── 作用域（静止式修正用；无 TargetRef、不挂起、不 fizzle）──
public sealed record EffectScope(
    SideConstraint Side,
    EntryFilter    Filter);
```

**`EffectData` 补两格字段**（其余七个原子操作不变）：

| 字段 | 类型 | 说明 |
|---|---|---|
| `TargetSlots` | `TargetSlot[]` | 可空 = 无目标。顺序即 `slotIndex`，与 `chosenTargets` 一一对应 |
| `Keyword` | `KeywordRef?` | 非空 = 本元素是一次关键字展开；展开在**结算时**做，不在加载时内联 |

**关键字展开在结算时做，不在加载时内联** —— 否则 overlay 热更改一个关键字的定义，
已加载的卡牌拿的是旧展开（`XxxData` 是共享只读单例，不能回写）。这与「读取侧不过滤 `ContentEnabled`」同一种收口。

**加载期校验（坏数据启动即失败）：**

| 规则 | 违反时 |
|---|---|
| `KeywordData.Id` 重复 | `PushError`，报出两个 `.tres` 路径 |
| `Kind == Action` 且 `Effects` 为空 / `Kind == State` 且 `StateTemplate` 为空 | `PushError` |
| `Kind == State` 且 `Effects` 非空（反之亦然） | `PushError` —— 关键字不是第三种效果载体 |
| `KeywordRef.KeywordId` 在注册表中不存在 | `PushError`，报出悬空 id + 引用它的 `CardData.Id` |
| `HasAmount == false` 但 `KeywordRef.Amount != -1` | `PushError` |
| `TargetSlot.Kind == HandCard` 且 `Side != Self` | `PushError` —— 对手手牌不可见（见建议 6） |
| `TargetSlot.Kind ∈ { None, Side }` 且 `Filter` 非空 | `PushError` —— 方位类目标没有可筛选的条目 |
| `EntryFilter.RequiredSubtypes` / `RequiredKeywords` 中的 id 悬空 | `PushError`，报出悬空 id |
| `IgnoresProtection == true` | `PushWarning` —— **清单式软检查**，与既定的 `IgnoresProtection` 清单警告同一处，使 ≈1% 配额始终可人工审阅 |
| 关键字未被任何 `KeywordRef` 引用 | `PushWarning` —— 与「次类型 X 未被任何筛选条件引用」同构 |

**运行时不变式（可断言）：**

- `chosenTargets.Length == TargetSlots.Length`（**一槽位恰好一个 `TargetRef`**，已定案 ①），槽位无目标时写 `TargetRef(None, _, string.Empty)`；
- `pending` 非空 ⇒ 该槽位 `Kind ∈ { BattlefieldEntry, HandCard }` 且 `controllerSide == Character` 且 `LegalTargets.Count > 1`；
- 静止式修正的求值路径上**恒不出现 `TargetRef`**（第 3 条切分的机械形态）。

## 后果

- **`CardData` 的「目标声明 / 效果引用」两格由此定稿** ⇒ 那条待答项从「四格全空」收窄为「费用 / 触发器两格」+ starter deck 内容。
- **新增一个内容类型 `KeywordData`** ⇒ `content/_index.md` 的类型登记表 + `content/keyword/` 类型档案需开张（`/scaffold-content-type keyword`）。**但清单为空 ⇒ 不急，与次类型同批处理即可。**
- **不 bump 存档 schema。** `chosenTargets` / `pending` / `LegalTargets` 三处形态均已在 `ActiveCombat` 里定过，本方案只补**声明侧**；`EffectScope` 与 `KeywordRef` 都不落存档（内容定义的属性）。
- **`ux/combat-ux.md` 多两条连带项**：① fizzle 必须在 ticker 上可见（承接「逐步反馈是硬要求」）；② 关键字提醒文本的长按入口。两者都落在已排期的战斗 UX 专场内，不新开场次。
- **`combat-service.md` 的 `PendingTargetRequest` 需补一格 `slotIndex`** —— 当前它只带 `StackEntryId`，而 `pending` 存档结构里已有 `slotIndex`，两侧不齐。这是本方案顺带暴露的一处既有不一致。
- **顺带发现（不属本方案范围，但需登记）：** `combat-service.md` 的 `CombatSnapshot` 仍带 `IntentView? Intent` 字段，注释写「仅玩家回合有值；不达档时为 null」——**这是 08-15d 意图整条移除之后的漂移残留**，应删。本草稿不改它，请在 `/analyze-new-ideas` 时一并清理。

## 备选方案（已考虑并否决）

- **关键字 = C# 枚举 `EffectKeyword`。** 否决：与「次类型不用 C# 枚举」的既定选择同一道题——
  内容侧可扩展的词汇一旦焊进枚举，新增一个关键字就要改 C# 类 + 发版，且 overlay 永远补不上。
  （`CapabilityFlag` 用枚举是因为它的消费点必然是一段 UI 代码；关键字的消费点是内容数据，方向相反。）
- **关键字 = 纯呈现层的文案简写，机制仍逐卡展开原子操作。** 否决：三条理由见建议 1 的表——
  最硬的是**战场条目没有筛选键**，「移除所有带某状态的条目」这类 payoff 直接写不出来。
- **通用效果表达式 / 小型脚本语言。** 否决：把「效果是数据不是代码分支」拖回需要求值器与沙箱的形态，
  且 overlay 热更一段脚本的风险面远大于改一个数值。单 `Amount` 参数已覆盖同类作品的绝大多数需求。
- **fizzle 采「全有全无」。** 否决：见建议 4——5 回合定长 + 无响应窗口下惩罚过重。
- **目标与作用域共用一个类型（都叫 target）。** 否决：它们在「是否可被玩家选择 / 是否 fizzle / 是否落存档」三处行为完全相反，
  合成一个类型会让每个消费点都要先判一次「这是哪种 target」。**这正是本条待答项此前写不下去的原因。**
- **允许 `TargetKind.StackEntry`。** 否决：既定纪律明写「本作不做反制栈上条目这一形态的效果，枚举里不留永无消费者的取值」。

## 与既有决策的张力

**一处，且是本方案自己引入的：** 建议 5 的「`LegalTargets.Count == 1` 自动选定」使
**同一张牌在不同局面下产生的决策点数量不同** ⇒ 一场战斗的决策点总数不再是固定的 31 个
（`combat-service.md` 的「已知代价」按 ≈31 个决策点估算过存档体积 ≈93 KB）。

- **代价是单向的**：自动选定只会**减少**决策点，估算的 93 KB 是上界而非典型值，体积护栏不受威胁。
- **不松动任何既定条款**：D4 的定义（「`pending` 写入那一刻」）原样成立，只是写入条件更严。
- **不采纳它的替代**：`Count == 1` 也照常挂起，玩家每次都得点一下唯一那个高亮项——纯噪声，且多一个存档写。

其余各条均落在既有决策之内，无需任何条款松动。

## 前置依赖

- **ch1 数值标杆专场**（`systems/balance.md`）—— 关键字的**具体清单与数值**在它之前无法定稿。
  本方案已把这一半明确排除在外（建议 2：清单为空、机制先定），故**不构成阻塞**。
- **次类型清单归零** —— `EntryFilter.RequiredSubtypes` 当前无可填值。同上，机制成立、清单待长。
- **`CardData` 的费用 / 触发器两格** —— 与本方案正交，各自定稿即可。
- **「敌人 AI 决策形态」** —— 建议 5 的条件 ② 把敌人侧目标选择留给 EnemyManager，
  本方案不指定 AI 如何选目标；那条待答项答定后**不会回头改本方案的任何形态**。

## 已定案的取向（2026-08-16 用户裁决 · 四项全部取推荐项）

> 本节记录的是**已裁决**的四项，不再是待答项。形态已并入上方「具体形态」，此处只留裁决与理由。

1. **多目标的表达形态 = 「一槽位 = 一个目标」，多目标靠多槽位。**
   `TargetSlot` **不设 `TargetCount` 字段**；`chosenTargets` 与 `pending.slotIndex` 的既定结构直接够用，UI 一次只问一个。
   **否决 `TargetCount { Exactly(N), UpTo(N) }`：** 竖屏多选态是真实成本，且 `pending` 的「一个 slotIndex」结构要扩。
   **方向不对称是采纳它的关键理由**——5 回合定长对局里「选两个目标」的牌本就该稀少；
   日后真需要时补一个字段是**纯加法**，而先做多选再退回单选要改存档结构。

2. **关键字提醒文本永远走长按，首次出现不自动展开。**
   与既定的「不打断节奏」「无 hover-only 但也不弹窗」一致。
   **否决「本轮回首次出现时自动展开一次」：** 要为「首次」这件事记账（落 `CharacterProfile` 还是 `PlayerProfile`？跨轮回还是轮回内？），
   **为一条呈现便利新增一个存档字段不划算**。若实测新手看不懂，自动展开一次是**现成的退让位**（属实测调整，不是重新裁决）。

3. **`EntryFilter` 的多条件组合语义恒为 AND，不支持 OR / NOT。**
   可机械校验、卡面文案好写（「带『甲』且『乙』的条目」）。
   **否决 OR / NOT：** 筛选条件会从一张表变成一棵树，卡面文案立刻变长——与竖屏可读性相反。
   **OR 的需求由内容侧绕过**（把两个关键字都挂上），不进结构。

4. **`IncludeFaceDown` 保留字段、默认 `false`，内容侧纪律 = 当前不使用。**
   保留的成本为零，日后真有「揭示一张埋伏」这类效果时不必改 schema。
   **否决「删掉字段、规则层写死埋伏永不可被点名」**：那是把一个可能的设计面焊死换取少一个旋钮，不划算。
   **「保留但默认不用」与 `CountdownSide.Either` 的处理同构**——机制在、纪律管住它。

**四项裁决对上方各节的影响面：** 均已并入「具体形态」与「建议 7」，
**没有任何一项改变建议 1–6 的结论**，也**不新增前置依赖**。
