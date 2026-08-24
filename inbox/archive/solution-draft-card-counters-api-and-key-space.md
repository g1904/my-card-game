---
type: solution-draft
date: 2026-08-22
question: 战斗内 `counters` 键空间的三条残留——非异能计数器往哪放、`CardInstanceSave.Counters` 的读写 API、子计数器名的字符集与登记。
source: open-questions/01-combat.md → 结构与配置的残留（三条并列条目）
targets: systems/services/combat-service.md · systems/character-profile/deck/common-properties.md · systems/common-properties.md
status: distilled
distilled-to: handoffs/2026-08-22-card-counters-api-and-key-space.md
reviewed: 2026-08-22 —— 五项取向全部裁定：`KeywordRef.Amount` 取 A（战场条目增一格 `amount:int`，**正式拍板**），其余四项（`:` 语法护栏 · `BumpCardCounter` 按结算成功计 · 子名正则允许下划线 · 两条权威落点）按推荐采纳；三条张力均按草稿主张处理。
confirmed: 2026-08-23 —— 全部 [采纳推荐 — 待复核] 项经复核会逐项确认，无推翻（answer-logs/log-0823.md）
---

# 方案草稿 — 战斗内运行态计数器：键空间、卡牌实例侧 API 与子名登记

## 问题

08-22 的运行态计数器定案把承载结构与键约定一次落定（`counters : Dictionary<string,int>`，键 `::= <abilityId> | <abilityId> "#" <子名>`），但**留下三个互相咬合的口子**，它们同属一个键空间、必须一起答：

1. **非异能计数器往哪放。** 键的第一段必须能解析出一条 `AbilityData`。`KeywordKind.State` 展开出的 `Transient` 战场条目、以及「关键字状态叠了几层」这类量，**不天然对应某一条异能**。当时取「暂不表态」，理由是「关键字清单归零、不为空清单预铺第二类键」——这条理由会随清单重建而过期，问题原样回来。
2. **`CardInstanceSave.Counters` 的读写 API。** 存档形态与键约定已定，但消费面只做了战场条目一侧（`GetCounter` / `BumpCounter` 按 `entryId` 寻址）。卡牌实例**不在战场上**（手牌 / 抽牌堆 / 弃牌堆里的牌照样可以带本体计数器），故这一半**当前没有任何读写通道**——存了没人能读。
3. **子计数器名的字符集与登记。** `#` 后半段当前只写了「点分小写短标识」这句自然语言。既没有正则，也**没有任何地方登记「这条异能有哪些子计数器」**——而键选用具名 `AbilityData.Id` 的**唯一理由**就是「让键具备与全库其他跨类型引用同款的悬空校验能力」。子名一侧现在没有这个能力，**键的一半仍是裸字符串**。

卡住的东西：`AbilityData` 的字段面（③ 要不要加一格）、`ActiveCombat` 的条目字段表（① 要不要加一格）、以及卡牌效果系统落地时消费面能不能直接开工（②）。

## 约束（来自既有设计）

- **键约定既定，不重开**：`<abilityId>[#<子名>]`；`#` 前段必须经 `ContentRegistry` 解析出一条 `AbilityData`；`AbilityData.Id` 不得含 `#`（加载期 `PushError`）；值域 `>= 0`、为 0 的键不写入；键悬空走读档校验 ②（`PushError` + 抛，不开例外）。**战场条目与 `CardInstanceSave.Counters` 共用同一套键**。→ `systems/services/combat-service.md`
- **「可重算的东西不进存档」**是本服务已明写的判据（触发器注册面 / `Power` 入场 / 合法目标集据此全部不落档）。→ 同上
- **`CardInstance` 运行态判据（承重）**：「**有过期时刻的 → 战场条目；无过期时刻且属于这张牌本体的 → `CardInstance`**」；允许写入实例的只有两类——无时限的本体改写与**本体计数器**。→ `systems/character-profile/deck/_index.md`
- **关键字不新增第四类东西**：`State` 展开为**已有的战场条目**；`BattlefieldEntryTemplate = AbilityData[] + 默认三件套`；`KeywordRef(KeywordId, Amount)`，`HasAmount == false` 时 `Amount` 恒为 `-1`；**展开在结算时做，不在加载时内联**。→ `systems/character-profile/deck/common-properties.md`
- **战场条目已有 `keywordId` 一格**（仅 `State` 展开出的 `Transient` 条目非空），其存在理由正是「不可由 `sourceId` 推导」。条目字段表**没有承载关键字 `Amount` 的格**。→ `systems/services/combat-service.md`
- **API 契约总则**：形态 A = 同步直返（纯内存查询与本地事务，不带 `Async`）；失败三分（必需缺失 → `PushError` + 抛 / 可选缺失 → `TryXxx` + `PushWarning` / 业务失败 → 结果对象绝不抛）；manager `internal sealed`；服务不返回内部可变集合。→ `systems/architecture.md`
- **`BumpCounter` 的调用点唯一**，落在 StackManager 的结算收口回调；配额闸门双查；`ActivationCost` 已付但 fizzle 不吃配额。→ `systems/services/combat-service.md`
- **栈条目自带 `controllerSide` 与 `sourceInstanceId`**；实例表 `instances` 是**参战方**（`sides[]`）的字段，战场条目在 BattlefieldManager。→ 同上
- **`content/` 的硬边界（承重）**：内容层**只写「填了什么值 + 权威回链」，绝不复述字段的类型 / 取值域 / 枚举 / 校验语义**；违反即制造第二权威。→ `content/_index.md`
- **`ability/` 类型就绪度 🔴（语法未定案）**，`CardData` 字段清单未定案。→ `content/_index.md`、`deck/common-properties.md`

## 建议方案

### ① 非异能计数器往哪放 —— 建议**维持单一键形态，但换一条不会过期的理由**

`[既有推演]`

推荐结论：**`counters` 键空间保持 `<abilityId>[#<子名>]` 一种形态**，并把这条待答项**关闭**（而非继续挂着）。理由不再是「清单归零故暂不表态」，而是：

- **「关键字状态叠了几层」是可重算的派生量。** 每次 `ApplyState` 产出**一条独立的 `Transient` 战场条目**（这是既有模型的形状，不是新规定）；层数 = 战场上**同 `keywordId` + 同 `ownerSide`** 的条目计数，一次遍历即得。依「可重算的东西不进存档」判据，它**不该**有独立的计数器落点。
- **合并成「单条 + 层数」反而是语义损失。** 生命周期三件套（`Lifetime` / `CountdownSide` / `RemainingTurns`）逐条独立倒数；把两次施加合并为一条带层数的条目，等于强制两次施加共享同一个过期时刻——两次「持续 2 回合」的施加会在同一刻一起消失，而分条时它们各自倒数。合并**要求**一条本库从未定过的规则，分条**不要求任何新规则**。
- **因此「`Transient` 条目没有 `AbilityData` 主体」不构成缺口**：它压根不需要计数器。第一类键覆盖的是**配额**（「每场限 N 次」），配额天然挂在某一条异能上——这条既定判据在关键字侧同样成立（`BattlefieldEntryTemplate` 里就是 `AbilityData[]`，带配额的异能自己有 `Id`）。

`[取向选择]` **唯一真实的残留缺口不是计数器，是 `KeywordRef.Amount` 没有承载字段。**

`State` 关键字若 `HasAmount == true`，展开出的 `Transient` 条目要把 `Amount` 带在身上（同一关键字可以用不同 `Amount` 施加两次，故它**不可由 `keywordId` 推导**——与 `keywordId` 自己不可由 `sourceId` 推导逐字同构）。当前条目字段表 13 格里没有它。三个选项：

| 选项 | 形态 | 后果 |
|---|---|---|
| **A（推荐）** | 战场条目增一格 `amount : int`（默认 `-1` = 无参数，与 `KeywordRef` 的既定约定同值），`BattlefieldEntryTemplate` 侧不需要（`Amount` 来自引用侧的 `KeywordRef`，不是模板的属性） | 纯加法；`ActiveCombat` 无线上存档 ⇒ 空迁移；体积 ≤ 4 字节 / `Transient` 条目。**代价：它是为「当前为空的关键字清单」预铺的一格**——与「不为空清单预铺」那条纪律有张力（见下） |
| B | 用 `counters` 的第二类键承 `Amount`（如 `kw:<keywordId>`） | **否决建议**：`counters` 的语义是**计数**（值域 `>= 0`、为 0 不写入、单调 bump）；`Amount` 是**参数**不是计数，「为 0 的键不写入」对它是错误语义。键空间从此承担两种语义，此后每一次读键都要先分辨它是哪一族 |
| C | 维持不表态（现状） | 第一条带 `Amount` 的 `State` 关键字落地时才发现存档缺格；届时 schema 可能已上线，加格不再是空迁移 |

> **已裁决（2026-08-22 · 批量评审）：取 A** —— 战场条目增一格 `amount : int`（默认 `-1`）。**正式拍板**，非待复核。与「不为空清单预铺」的张力由用户明确接受（见张力 2）。

`[通行做法]` **另建议一条零成本的语法护栏（无论上面取哪个选项都成立）**：把「键的第一段恒为 `AbilityData.Id`」写成显式不变式，并在内容条目 `Id` 的字符集里**同时排除 `#` 与 `:`**。日后若真需要第二类键，`:` 前缀可开一个与异能键**天然不相交**的命名空间（`:<namespace>.<name>`），且**无需迁移**——因为旧键在语法上永远进不了那个空间。这不是预铺第二类键，只是不把门钉死。

### ② `CardInstanceSave.Counters` 的读写 API —— 建议对称补两个方法，落**参战方**

`[既有推演]`

```csharp
// 形态 A（同步直返，纯内存）。落 CharacterManager / EnemyManager 共享的参战方接口。
int  GetCardCounter(string cardInstanceId, string counterKey);            // 缺键 → 0
void BumpCardCounter(string cardInstanceId, string counterKey, int by);   // 仅在计数事件实际发生时调用
```

- **不与 `GetCounter` / `BumpCounter` 同名重载。** 两者签名同为 `(string, string)` / `(string, string, int)`，重载在编译期完全无法区分，调用点把 `entryId` 传进卡牌一侧**编译照过、运行期静默开一个新计数器**。取不同方法名是唯一能让编译器帮上忙的形态（`.claude/rules/csharp-godot-rules.md` 的命名纪律 + 「贯穿整条链路的类型一致性」）。
- **落参战方而非 BattlefieldManager，也不新增 manager。** 战场那两个方法的落点理由是「战场持有场上的全部准确数据，读写落在它的既有职责内」；**同一条判据在这里指向参战方**——实例表 `instances` 是 `sides[]` 的字段，战场并不持有不在场的牌（手牌 / 抽牌堆 / 弃牌堆里的牌照样能带本体计数器）。
- **敌人侧同样需要**（`e#…` 系列实例同样可带本体计数器，敌人卡牌与玩家卡牌共用 `CardData` 体系）⇒ 落在**两者共享的参战方接口**上，不是只给 CharacterManager。这与「`DeckModule` 每个 character / enemy 一份」同构。
- **寻址不需要任何新状态。** 调用点在 StackManager 的结算收口回调，栈条目自带 `controllerSide` 与 `sourceInstanceId` ⇒ 「找哪一侧的实例表」是现成信息。**不需要**按 `c#` / `e#` 前缀解析实例 id（那会把发号格式变成隐式契约），**也不需要**一张跨侧的全局实例索引（那是第二份持有关系）。
- **失败语义（总则 2 + `null-check-rules.md`）：**

  | 情形 | 处置 |
  |---|---|
  | `cardInstanceId` 不在该侧实例表中 | **必需缺失** → `GD.PushError($"[Battle-BumpCardCounter] instance not found, id={cardInstanceId}")` + 抛。闭集不变式（读档校验 ④）已保证它必然存在，找不到 = 内部一致性破损 |
  | `counterKey` 缺失（读） | 返回 `0` —— 与战场一侧逐字相同 |
  | `by` 使计数降到负数 | `PushError` + 抛，带 `cardInstanceId` / `counterKey`。与读档校验 ⑤ 同档，只是在**写入侧**提前拦下 |
  | `counterKey` 的 `abilityId` 段解析不到 | `PushError` + 抛（既有读档校验 ② 的写入侧对应物） |

- **键约定共用不变**：第一段仍须解析出 `AbilityData`；内容侧纪律「『每场限 N 次』类异能必须引用自己 `AbilityData` 的稳定 `Id` 作键，不得自造裸字符串」照旧覆盖两侧。
- **两个计数器空间的归属判据 —— 直接复用既有那条，不新造。**

  > **有过期时刻的 → 战场条目；无过期时刻且属于这张牌本体的 → `CardInstance`。**

  即：**随条目消亡的计数落 `entry.counters`；随牌本体、整场存活的计数落 `CardInstanceSave.Counters`。** 一张 `Enchantment` 同时拥有两个计数器空间**不是重复**——条目离场即消失（「这个永久物在场期间触发了几次」），实例计数整场存活（「这张牌本场被打出过几次」，即便它已回到弃牌堆）。

- `[取向选择]` **`BumpCardCounter` 的调用时机**（见「仍需用户决定」第 3 项）：与配额计数完全同规则（结算成功后 +1，fizzle 不计），还是本体计数按「打出」计（压栈成功即 +1）。

### ③ 子计数器名的字符集与登记

`[既有推演]` **(a) 正则** —— 把既定的「点分小写短标识」逐字机械化：

```
子名 ::= ^[a-z][a-z0-9_]*(\.[a-z0-9_]+)*$        长度 ≤ 32
```

- 首字符限字母（排除纯数字段与前导点）；段间以 `.` 分隔；**不含 `#`**（它是分隔符，含之则语法不成立）；**不含 `:`**（为 ① 的命名空间护栏预留）。
- 是否允许 `_` 见「仍需用户决定」第 4 项（建议允许，与全库 `snake_case` 的 id 段一致）。

`[既有推演]` **(b) 权威落点：不进 `content/_index.md` 的 id 约定表。** 两条理由：

- **该文件自己的硬边界禁止它承载校验语义**（「绝不复述字段的类型 / 取值域 / 枚举 / 校验语义……可机械检查的越界信号：出现字段取值域穷举、`GD.PushError` 级校验语义的完整表述 ⇒ 违规」）。一条正则 + 一条 `PushError` 校验，正是它列举的越界信号。
- **子名不是内容条目 id**：它不进 `ContentRegistry`、不被任何 `.tres` 以 id 引用、没有条目文档。写进条目 id 约定表会给读者「子名是一类内容 id」的错觉。

建议权威落 **`systems/services/combat-service.md` 的「`counters` 的键约定」小节**——它已经是键语法的权威，正则是那句自然语言的机械化，落在同一处不产生第二权威。

> 与之相对，**`AbilityData.Id` 不得含 `#` / `:`** 属于**内容条目 `Id` 的字符集**，它的权威更适合落 `systems/common-properties.md`「稳定 Id 键」，`combat-service.md` 侧改为回链。现在把它写在键约定里是因果倒置：键约定**依赖**这条约束，不等于这条约束**归**键约定。（此项见「仍需用户决定」第 5 项。）

`[既有推演]` **(c) 登记面 —— 这是三条子问题里唯一的真缺口。**

当前没有任何字段登记「这条异能有哪些子计数器」。后果不是「不够整洁」，而是：**拼错的子名会静默开一个新计数器，配额闸门读到的永远是 `0` ⇒「每场限 N 次」静默失效**，且它**只在线上被玩家发现**。正则拦不住这一类（拼错的名字通常仍然合法）。建议：

```csharp
// AbilityData : Resource —— 增一格
string[] CounterNames;   // 该异能声明的子计数器名；可空。默认计数器（无 # 段）无须登记
```

| 检查点 | 时机 | 违反时 |
|---|---|---|
| `CounterNames` 每个元素匹配上述正则 | 加载期 | `PushError`，带 `AbilityData.Id` 与 `.tres` 路径 |
| 同一异能内 `CounterNames` 重复 | 加载期 | `PushError`，带 `Id` 与重复项 |
| `BumpCounter` / `BumpCardCounter` 的 `counterKey` 带 `#` 段，而该段不在对应 `AbilityData.CounterNames` 内 | 运行期（写入侧） | `PushError` + 抛，带 `abilityId` / 子名。与「`abilityId` 段解析不到」同档：程序缺陷或坏数据 |
| `GetCounter` / `GetCardCounter` 读到未登记的 `#` 段 | 运行期（读取侧） | 同上 —— 读侧也拦，否则「读到 0」与「键不存在」在闸门处无法区分 |
| `CounterNames` 非空但该名从未被任何效果定义使用 | 加载期 | `PushWarning` —— 与「关键字未被任何 `KeywordRef` 引用」同构 |

- **`CounterNames` 是纯加法且不落存档**（静态内容字段，与 `CardType` / `Subtypes` 同款）⇒ **空迁移**。
- 它把子名从裸字符串提升为**有登记、可悬空校验**的标识，使键的两段获得对称的校验能力——这正是当初选用具名 `AbilityData.Id` 作键主体的那条理由的另一半。

## 具体形态（可 derive 的落地面）

**方法签名（三条，全部形态 A）**

| 方法 | 所属 | 签名 | 调用方向 | 失败语义 |
|---|---|---|---|---|
| 读条目计数（既有） | BattlefieldManager | `int GetCounter(string entryId, string counterKey)` | StackManager / 效果求值 → BattlefieldManager | 缺键 → 0；`entryId` 不存在 → `PushError` + 抛 |
| 写条目计数（既有） | BattlefieldManager | `void BumpCounter(string entryId, string counterKey, int by)` | StackManager 结算收口回调（唯一调用点） | 降至负 / 键未登记 → `PushError` + 抛 |
| **读实例计数（新）** | 参战方接口（CharacterManager / EnemyManager） | `int GetCardCounter(string cardInstanceId, string counterKey)` | StackManager / 效果求值 → 该侧参战方 | 缺键 → 0；实例不存在 → `PushError` + 抛 |
| **写实例计数（新）** | 同上 | `void BumpCardCounter(string cardInstanceId, string counterKey, int by)` | StackManager 结算收口回调（时机见取向项 3） | 同上 |

**字段增减**

| 位置 | 字段 | 类型 | 依赖哪个取向项 | 落存档 |
|---|---|---|---|:--:|
| `AbilityData` | `CounterNames` | `string[]`（可空） | 无（已采纳） | ✗ |
| 战场条目 / `BattlefieldEntryTemplate` 展开产物 | `amount` | `int`（默认 `-1`） | 取向项 1 已裁决取 A ⇒ **加** | ✓（`ActiveCombat`） |

**键语法（更新后）**

```
键 ::= <abilityId>                       // 该异能的默认计数器
     | <abilityId> "#" <子名>             // 须登记在 AbilityData.CounterNames 内
<子名> ::= ^[a-z][a-z0-9_]*(\.[a-z0-9_]+)*$      // 长度 ≤ 32
// 不变式：第一段恒为 AbilityData.Id；内容条目 Id 的字符集不含 '#' 与 ':'
// ':' 前缀保留为未来非异能键的命名空间，当前不使用
```

## 后果

- **`systems/services/combat-service.md`**：「`counters` 的键约定」小节改写（正则 + 登记校验 + 把「暂不表态」换成「层数 = 条目计数」的定论 + `:` 保留位）；「管理器」小节增两条方法与参战方接口一行；读档校验 ⑤ 的报错上下文由 `entryId` 扩为 `entryId / cardInstanceId`（它本就覆盖两处 `counters`）。**（取向项 1 已裁决取 A）** 条目字段表增 `amount` 一行，且「**本块不新增字段**」那句须改写。
- **`systems/character-profile/deck/common-properties.md`**：`AbilityData` 注释块增 `CounterNames`；加载期校验表增两行（正则 / 重复）+ 一行 `PushWarning`。
- **`systems/common-properties.md`**：**（取向项 5 已裁决采纳）**「稳定 Id 键」补一句字符集排除（不含 `#` / `:`），`combat-service.md` 改回链。
- **`content/_index.md`：明确不改**（硬边界）。
- **存档 schema**：②③ **不改** `ActiveCombat`；① 已裁决取 A ⇒ `ActiveCombat` 的 `Transient` 条目新增一格 `amount`，当前无线上存档 ⇒ **空迁移**，量级影响可忽略（≤ 4 字节 / `Transient` 条目，远低于 2–4 KB / 决策点的既有量级）。
- **待答清单**：①②③ 均可整条移出（① 取 A ⇒ 缺口关闭，不需要收窄留挂）。
- **下游**：卡牌效果系统落地时，`CardInstanceSave.Counters` 不再是「已知未覆盖面」，可直接 `/derive-requirements`。

## 备选方案（已考虑并否决）

- **把实例计数 API 也挂 BattlefieldManager（配一张跨侧实例索引）** —— 制造第二份实例持有关系，而战场并不持有不在场的牌；与「读写落在持有它的那个 manager 的既有职责内」这条落点判据相反。
- **`GetCounter` / `BumpCounter` 加同签名重载覆盖两个寻址空间** —— 编译期完全无法区分，传错 id 静默开新计数器。
- **用 `counters` 承 `KeywordRef.Amount`（第二类键）** —— 计数语义与参数语义混住一个字典，「为 0 的键不写入」对参数是错误语义。
- **只做正则、不做登记** —— 拼错的子名合法且静默，配额闸门永远读到 0，「每场限 N 次」线上才失效。
- **把子名正则写进 `content/_index.md` 的 id 约定表** —— 触该文件自己列举的越界信号；且子名不是内容条目 id。
- **关键字状态合并为「单条条目 + 层数计数」** —— 强制多次施加共享同一过期时刻，要求一条本库从未定过的规则。

## 与既有决策的张力

1. **`combat-service.md` 现写「当前合法的键形态仅此一种……出现此类需求时再扩键约定，不预先为空清单铺第二类键」。** 本方案 ① **不扩键**（结论一致），但把依据从「清单归零故暂不表态」改写为「层数是可重算的派生量故不需要计数器」。**需要用户点头才能重写那段措辞**——它推翻的是理由不是结论，收益是这条理由不会随关键字清单重建而过期。
   → 已裁决（2026-08-22 · 批量评审）：按草稿主张 —— 重写那段措辞，把依据换成「层数是可重算的派生量」，结论（不扩键）不变 `[采纳推荐 — 待复核]`
2. **`ActiveCombat` 段的「本块不新增字段」与取向项 1 的 A 选项直接冲突**，且 A 确实是**为当前为空的关键字清单预铺一格**，与 08-22 裁决「不为空清单预铺」同源。松动代价：一句话改写 + 一行量级说明。不松动的替代就是选项 C，代价是日后加格可能不再是空迁移。**这一条请用户明确裁决，本草稿不替其绕过。**
   → 已裁决（2026-08-22 · 批量评审）：**松动** —— 取向项 1 取 A（正式拍板）⇒ `ActiveCombat` 段「本块不新增字段」须改写以容纳 `amount` 一格，并补一行量级说明（≤ 4 字节 / `Transient` 条目，当前无线上存档 ⇒ 空迁移）。
3. **08-22 裁决明写「子名正则待 `content/` 的 id 约定表成型时统一定」。** 本方案主张它**不该**落 `content/`（该库硬边界禁止承载校验语义）。这推翻的是那条裁决的**落点**而非其结论（正则照样定、口径照样统一）。需用户裁决落点。
   → 已裁决（2026-08-22 · 批量评审）：按草稿主张 —— 落点改为 `systems/services/combat-service.md` 键约定小节，不落 `content/_index.md` `[采纳推荐 — 待复核]`

## 前置依赖

- **`AbilityData` / `CardData` 字段清单未定案**（`content/_index.md` 记 `ability/` 就绪度 🔴「语法未定案」）。`CounterNames` 是纯加法、不依赖其余字段，**可先落**；但若日后异能语法整体重写，本格须随之复核。
- **「每场几次」的具体取值**依赖 ch1 数值标杆专场与「一张牌该产多少道念」的量纲（既有登记，本方案不触及——字段与 API 形态不依赖它）。
- **「`State` 关键字会不会用 `HasAmount == true`」这条依赖已解除**（2026-08-22 · 批量评审）：用户直接裁定取向项 1 取 A（`amount` 一格现在就加），不再以「清单归零、无实例佐证」为由推迟；张力 2 同批松动。

## 仍需用户决定 → **已全部裁决（2026-08-22 · 批量评审）**

> - **1 `KeywordRef.Amount` 的承载** → **A · 战场条目增一格 `amount : int`（默认 `-1`）**。**正式拍板**（此项此前不在任何待答清单上，为本批新发现的真缺口，用户当场答定），**不带待复核**。
> - **2 `:` 语法护栏** → **做**：内容条目 `Id` 字符集排除 `:`，`:` 前缀保留给未来非异能键 `[采纳推荐 — 待复核]`
> - **3 `BumpCardCounter` 计数时机** → **A · 与配额计数同规则（弹栈结算成功后 +1，fizzle 不计）** `[采纳推荐 — 待复核]`
> - **4 子名正则是否允许下划线** → **允许**：`^[a-z][a-z0-9_]*(\.[a-z0-9_]+)*$` ≤ 32 `[采纳推荐 — 待复核]`
> - **5 两条权威落点** → **(a) 子名正则落 `systems/services/combat-service.md` 键约定小节；(b) 「内容条目 `Id` 不含 `#` / `:`」上提到 `systems/common-properties.md`「稳定 Id 键」，`combat-service.md` 改回链** `[采纳推荐 — 待复核]`
> - **三条张力** → 均按草稿主张处理（详见「与既有决策的张力」小节的裁决行）
> - `AbilityData.CounterNames` 与 ② 的两个方法签名属 `[既有推演]`，用户无异议，按草稿采纳。

1. **`KeywordRef.Amount` 在 `Transient` 战场条目上的承载。** A = 加一格 `amount : int`（默认 `-1`）／ B = 用 `counters` 第二类键承载／ C = 维持暂不表态。**推荐 A**（理由：与 `keywordId` 同款——都是「展开时才知道、不可由 `sourceId` 推导」的展开参数，落同一张表最自洽；纯加法、当前空迁移）。**但若你要严格恪守「不为空清单预铺」，正确选择是 C**——两者不可兼得，这一项本质是取向。B 建议否决（计数与参数混住一个键空间）。
   → 已裁决（2026-08-22 · 批量评审）：A · 战场条目增一格 `amount : int`（默认 `-1`）。**正式拍板**，不带待复核。连带：`ActiveCombat` 段「本块不新增字段」须松动（见张力 2）。
2. **是否现在加那条零成本语法护栏**（内容条目 `Id` 的字符集排除 `:`，把 `:` 前缀保留为未来非异能键的命名空间）。**推荐做**：成本为零、不引入第二类键、只是不把门钉死；不做的代价是日后引入第二类键时可能撞上已有的 id 形态。
   → 已裁决（2026-08-22 · 批量评审）：做 —— 内容条目 `Id` 字符集排除 `:`，把 `:` 前缀保留给未来非异能键 `[采纳推荐 — 待复核]`
3. **`BumpCardCounter` 的计数时机。** A = 与配额计数完全同规则（弹栈结算成功后 +1，fizzle 不计）／ B = 本体计数按「打出」计（压栈成功即 +1）。**推荐 A**：「`BumpCounter` 的调用点唯一」是既有定案的承重，开第二个时机等于把「什么时候算数」变成逐计数器记忆的事。B 的好处是「本场已被打出 N 次」的字面语义更准；**若选 B，须在 `combat-service.md` 明写两族计数器的时机表**。
   → 已裁决（2026-08-22 · 批量评审）：A · 与配额计数完全同规则（弹栈结算成功后 +1，fizzle 不计） `[采纳推荐 — 待复核]`
4. **子名正则是否允许下划线。** `^[a-z][a-z0-9_]*(\.[a-z0-9_]+)*$`（允许）／ `^[a-z][a-z0-9]*(\.[a-z0-9]+)*$`（不允许）。**推荐允许**：全库其他 id 段一律 `snake_case`，禁止 `_` 会造出第二套书写习惯，而收益仅是名字略短。
   → 已裁决（2026-08-22 · 批量评审）：允许下划线 —— `^[a-z][a-z0-9_]*(\.[a-z0-9_]+)*$`，长度 ≤ 32 `[采纳推荐 — 待复核]`
5. **两条权威落点。** (a) 子名正则落 `systems/services/combat-service.md` 键约定小节（**推荐**）／ 落 `content/_index.md`（08-22 裁决的原话，但触该库硬边界）／ 落 `systems/common-properties.md`。(b) 是否把「内容条目 `Id` 的字符集不含 `#` / `:`」上提到 `systems/common-properties.md`「稳定 Id 键」，`combat-service.md` 改回链（**推荐上提**，理由：那是内容 id 的通则，不是键约定的私有前提）。
   → 已裁决（2026-08-22 · 批量评审）：(a) 子名正则落 `systems/services/combat-service.md` 键约定小节；(b) 上提 —— 「内容条目 `Id` 不含 `#` / `:`」写进 `systems/common-properties.md`「稳定 Id 键」，`combat-service.md` 改回链 `[采纳推荐 — 待复核]`

> `AbilityData.CounterNames` 一格与 ② 的两个方法签名**不在上述取向项内**——它们是 `[既有推演]`，若你无异议即可按草稿采纳；有异议请直接在本文件上改。
