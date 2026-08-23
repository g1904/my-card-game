# 战斗内运行态计数器：键空间、卡牌实例侧 API 与子名登记

- id: 2026-08-22-card-counters-api-and-key-space
- date: 2026-08-22
- topic: systems/services/combat-service · systems/character-profile/deck/common-properties · systems/common-properties
- status: distilled
- distilled-to: systems/services/combat-service.md, systems/character-profile/deck/common-properties.md, systems/common-properties.md

## Intent（distilled）

**一句话：** `counters` 键空间收口——键形态维持单一 `<abilityId>[#<子名>]`，子名获得正则与登记（`AbilityData.CounterNames`）从而两段对称可校验，卡牌实例侧补上对称的读写 API 落参战方，`KeywordRef.Amount` 由战场条目新增一格 `amount` 承载。

08-22 的运行态计数器定案定下了承载结构与键约定（`counters : Dictionary<string,int>`，键 `::= <abilityId> | <abilityId> "#" <子名>`），但留下三个同属一个键空间、必须一起答的口子。本次一并收口。

### ① 非异能计数器往哪放 —— 键空间维持单一形态

`counters` 的键形态**只有** `<abilityId>[#<子名>]` 一种，这条待答项就此关闭。依据不是「关键字清单当前为空故暂不表态」，而是两条不会过期的结构理由：

- **「关键字状态叠了几层」是可重算的派生量。** 每次 `ApplyState` 产出**一条独立的 `Transient` 战场条目**；层数 = 战场上同 `keywordId` + 同 `ownerSide` 的条目计数，一次遍历即得。依「可重算的东西不进存档」判据，它不该有独立的计数器落点。
- **合并成「单条 + 层数」是语义损失。** 生命周期三件套（`Lifetime` / `CountdownSide` / `RemainingTurns`）逐条独立倒数；合并等于强制两次施加共享同一个过期时刻。分条不要求任何新规则，合并要求一条本库从未定过的规则。

因此「`Transient` 条目没有 `AbilityData` 主体」不构成缺口——它压根不需要计数器。第一类键覆盖的是**配额**（「每场限 N 次」），配额天然挂在某一条异能上，这在关键字侧同样成立（`BattlefieldEntryTemplate` 里就是 `AbilityData[]`）。

**语法护栏（零成本）：** 内容条目 `Id` 的字符集**同时排除 `#` 与 `:`**。`#` 是键的分隔符；`:` 保留为未来非异能键的命名空间前缀（`:<namespace>.<name>`），它与异能键**天然不相交**，日后真需要第二类键时无需迁移。这不是预铺第二类键，只是不把门钉死。

### ①' `KeywordRef.Amount` 的承载 —— 战场条目增一格 `amount`

`State` 关键字若 `HasAmount == true`，展开出的 `Transient` 条目要把 `Amount` 带在身上——同一关键字可以用不同 `Amount` 施加两次，故它**不可由 `keywordId` 推导**，与 `keywordId` 自己不可由 `sourceId` 推导逐字同构。战场条目字段表因此**增一格 `amount : int`（默认 `-1` = 无参数，与 `KeywordRef` 的既定约定同值）**；`BattlefieldEntryTemplate` 侧不需要（`Amount` 来自引用侧的 `KeywordRef`，不是模板的属性）。

否决用 `counters` 的第二类键承载：`counters` 的语义是**计数**（值域 `>= 0`、为 0 不写入、单调 bump），`Amount` 是**参数**；「为 0 的键不写入」对它是错误语义，且键空间从此承担两族语义，此后每次读键都要先分辨它属于哪一族。

代价被明确接受：这一格是为当前为空的关键字清单预铺的。**接受的理由**是量级为零（`ActiveCombat` 当前无线上存档 ⇒ 空迁移；≤ 4 字节 / `Transient` 条目）而不加的代价可能不为零（第一条带 `Amount` 的 `State` 关键字落地时 schema 或已上线，届时加格不再是空迁移）。

### ② `CardInstanceSave.Counters` 的读写 API —— 对称补两个方法，落参战方

```csharp
// 形态 A（同步直返，纯内存）。落 CharacterManager / EnemyManager 共享的参战方接口。
int  GetCardCounter(string cardInstanceId, string counterKey);            // 缺键 → 0
void BumpCardCounter(string cardInstanceId, string counterKey, int by);
```

- **不与 `GetCounter` / `BumpCounter` 同名重载。** 两者签名同为 `(string, string)` / `(string, string, int)`，重载在编译期完全无法区分，把 `entryId` 传进卡牌一侧会编译照过、运行期静默开一个新计数器。取不同方法名是唯一能让编译器帮上忙的形态。
- **落参战方而非 BattlefieldManager，也不新增 manager。** 战场那两个方法的落点理由是「读写落在持有它的那个 manager 的既有职责内」；同一条判据在这里指向参战方——实例表 `instances` 是 `sides[]` 的字段，战场并不持有不在场的牌，而手牌 / 抽牌堆 / 弃牌堆里的牌照样能带本体计数器。
- **敌人侧同样需要**（`e#…` 系列实例同样可带本体计数器）⇒ 落在两者共享的参战方接口上，与「`DeckModule` 每个 character / enemy 一份」同构。
- **寻址不需要任何新状态。** 调用点在 StackManager 的结算收口回调，栈条目自带 `controllerSide` 与 `sourceInstanceId`。不按 `c#` / `e#` 前缀解析实例 id（那会把发号格式变成隐式契约），也不建跨侧的全局实例索引（那是第二份持有关系）。
- **计数时机与配额计数完全同规则：弹栈结算成功后 +1，fizzle 不计。** 「`BumpCounter` 的调用点唯一」是既有定案的承重，开第二个时机等于把「什么时候算数」变成逐计数器记忆的事。
- **两个计数器空间的归属判据直接复用既有那条，不新造：** 有过期时刻的 → 战场条目；无过期时刻且属于这张牌本体的 → `CardInstance`。即随条目消亡的计数落 `entry.counters`，随牌本体、整场存活的计数落 `CardInstanceSave.Counters`。一张 `Enchantment` 同时拥有两个计数器空间不是重复。

失败语义（总则 2 + `null-check-rules.md`）：实例不在该侧实例表中 → `PushError` + 抛（闭集不变式已保证它必然存在，找不到 = 内部一致性破损）；`counterKey` 缺失（读）→ 返回 0；`by` 使计数降到负数 → `PushError` + 抛；`counterKey` 的 `abilityId` 段解析不到 → `PushError` + 抛。

### ③ 子计数器名的字符集与登记

**(a) 正则**（既定「点分小写短标识」的机械化）：

```
子名 ::= ^[a-z][a-z0-9_]*(\.[a-z0-9_]+)*$        长度 ≤ 32
```

首字符限字母（排除纯数字段与前导点）；段间以 `.` 分隔；不含 `#`（分隔符）与 `:`（命名空间保留位）。**允许下划线**——全库其他 id 段一律 `snake_case`，禁止 `_` 会造出第二套书写习惯，收益仅是名字略短。

**(b) 权威落点。** 子名正则落 `systems/services/combat-service.md` 的键约定小节——它已是键语法的权威，正则是那句自然语言的机械化。**不落 `content/_index.md` 的 id 约定表**：该文件的硬边界禁止承载校验语义（一条正则 + 一条 `PushError` 校验正是它列举的越界信号），且子名不是内容条目 id（不进 `ContentRegistry`、不被任何 `.tres` 以 id 引用、没有条目文档）。

与之相对，**「内容条目 `Id` 不含 `#` / `:`」是内容 id 的通则而非键约定的私有前提**，权威上提到 `systems/common-properties.md`「稳定 Id 键」，`combat-service.md` 侧改为回链。

**(c) 登记面 —— 三条子问题里唯一的真缺口。**

```csharp
// AbilityData : Resource —— 增一格
string[] CounterNames;   // 该异能声明的子计数器名；可空。默认计数器（无 # 段）无须登记
```

不登记的后果不是「不够整洁」：**拼错的子名会静默开一个新计数器，配额闸门读到的永远是 0 ⇒「每场限 N 次」静默失效，且只在线上被玩家发现。** 正则拦不住这一类（拼错的名字通常仍然合法）。

| 检查点 | 时机 | 违反时 |
|---|---|---|
| `CounterNames` 每个元素匹配正则 | 加载期 | `PushError`，带 `AbilityData.Id` 与 `.tres` 路径 |
| 同一异能内 `CounterNames` 重复 | 加载期 | `PushError`，带 `Id` 与重复项 |
| `CounterNames` 非空但该名从未被任何效果定义使用 | 加载期 | `PushWarning` |
| 写入侧 `counterKey` 的 `#` 段不在对应 `AbilityData.CounterNames` 内 | 运行期 | `PushError` + 抛 |
| 读取侧读到未登记的 `#` 段 | 运行期 | 同上——读侧也拦，否则「读到 0」与「键不存在」在闸门处无法区分 |

`CounterNames` 是纯加法的静态内容字段、不落存档 ⇒ 空迁移。它把子名从裸字符串提升为**有登记、可悬空校验**的标识，使键的两段获得对称的校验能力——这正是当初选用具名 `AbilityData.Id` 作键主体的那条理由的另一半。

### ④ `EncounterSpec.FirstSide` 的来源措辞对账

**「剧情指定先手」= 内容侧在事件模板（`AdventureEventData`）上直接编排先手**，由 future-event-service 在物化 eventOption 时写入 `FirstSide`。`PlotModulation` 不承担这一项——它的六个字段无一格能表达先手，也不为此新增字段。本服务仍只读该字段、不问来源。

## Clarifications（interview 产物）

- **`KeywordRef.Amount` 在 `Transient` 条目上的承载** → **A · 战场条目增一格 `amount : int`（默认 `-1`）**。此项此前不在任何待答清单上，为本批新发现的真缺口，用户当场答定。连带松动 `combat-service.md`「本块不新增字段」那句。
- **`:` 语法护栏** → 做：内容条目 `Id` 字符集排除 `:`，`:` 前缀保留给未来非异能键。
- **`BumpCardCounter` 的计数时机** → 与配额计数完全同规则（弹栈结算成功后 +1，fizzle 不计），而非按「打出」计。
- **子名正则是否允许下划线** → 允许：`^[a-z][a-z0-9_]*(\.[a-z0-9_]+)*$`，长度 ≤ 32。
- **两条权威落点** → (a) 子名正则落 `combat-service.md` 键约定小节；(b) 「内容条目 `Id` 不含 `#` / `:`」上提到 `systems/common-properties.md`「稳定 Id 键」，`combat-service.md` 改回链。
- **①「非异能计数需求当前不表态」那段措辞** → 重写：结论（不扩键）不变，依据换成「层数是可重算的派生量故不需要计数器」，使这条理由不随关键字清单重建而过期。
- **08-22 裁决原写「子名正则待 `content/` 的 id 约定表成型时统一定」** → 落点改判：正则照样定、口径照样统一，但不落 `content/`（触该库硬边界）。
- **`EncounterSpec.FirstSide` 的「剧情指定」措辞** → 改为「内容侧在事件模板上编排先手」，删去 `plot-manager` 调制的说法，不新增 `PlotModulation` 字段。

## Open questions

- **`AbilityData` / `CardData` 字段清单整体未定案**（`ability/` 类型就绪度 🔴，语法未定案）。`CounterNames` 是纯加法、不依赖其余字段，可先落；若日后异能语法整体重写，本格须随之复核。
- **「每场限 N 次」的具体取值**依赖 ch1 数值标杆专场与「一张牌该产多少道念」的量纲（既有登记；字段与 API 形态不依赖它）。
