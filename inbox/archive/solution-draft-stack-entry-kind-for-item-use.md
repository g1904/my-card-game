---
type: solution-draft
date: 2026-08-28
question: 用道具产生的栈条目落在 `StackEntryKind` 的哪个成员上（复用既有成员、新增一员、还是另立形态）。
source: open-questions/01-combat.md → 能力剥夺与统计计数的残留（08-28 新增那条）
targets: systems/services/combat-service.md（栈条目字段行 · `UseItem` 段的入栈填法 · `CombatFeedKind` · 读档校验 ②）· decisions/（新 ADR，或并入 `ADR-0121` 的「后果」）
status: distilled
reviewed: 2026-08-30 · 批量合并 interview：`TimingIds.ItemUsed` 确认不开。另采纳三项草稿未点名的连带改动：读档校验 ②/⑥ 分档 · 存档「新增字段一格」→ 两格 · `UseItem` 段补齐 mana 扣费与 `InsufficientMana`。
distilled-to: handoffs/2026-08-30-stack-entry-kind-for-item-use.md
---

# 方案草稿 — 用道具的栈条目类型

## 问题

战斗内使用道具已定为一等玩家动作：`UseItem(itemId, targets)` 返回 `ActionResult`、`targets` 与 `PlayCard` 逐字同构、**入栈即 `targetState = Resolved`**、效果本体是 `ItemData.CombatUseEffects`，且**栈条目的 `abilityId` 恒空**（道具没有宿主 `AbilityData`，故收口阶段的「默认 counters +1」对它不成立）。

但 `StackEntryKind` 现有四值 `{ PlayedCard, TriggeredAbility, ActivatedAbility, Fatigue }` 没有一个对应「用道具」——道具不是牌、不是异能、不是疲劳。枚举成员未定，`UseItem` 的「入栈填法」那一段就写不出来（对位 `ActivateAbility` 已有的那一段），实现侧只能各自猜。

## 约束（来自既有设计）

- **栈条目的八格**：`stackEntryId` · `kind` · `controllerSide` · `sourceInstanceId` · `sourceEntryId` · `abilityId` · `chosenTargets` · `targetState`。栈内位置由数组顺序承载。→ `systems/services/combat-service.md`「栈条目」
- **`abilityId` 恒空已定**（本问题的前提，不在待裁范围内）。→ 同上「API 面」`UseItem` 段
- **阶段 5 的「默认 counters +1」判据是 `abilityId` 非空，不是 `kind`。** → 同上「效果流水线」
- **`counters` 键空间闭合于 `<abilityId>[#<子名>]`，键的第一段恒为 `AbilityData.Id`。** → 同上「战场条目与计数器」
- **读档校验 ②**：`cardId` / `sourceId` / `abilityId` 解析不到 → `PushError` 并报出 id。**读档校验 ④**：三区 `Id` 序列的并集 ≡ `instances` 全集（闭集不变式）。
- **道具不是 `CardInstance`**：不洗进卡组、存于储物袋、不占手牌位；三区（手牌 / 抽牌堆 / 弃牌堆）闭集不含储物袋。运行态只有 `CombatItemSave(ItemId, UsesThisCombat)`，按 `ItemId` 索引、**没有实例 id**。→ `systems/character-profile/item/_index.md`、`terminology.md`
- **道具从不进场**，没有战场条目、没有 `entryId`（`ItemData` 因此移除了 `Abilities` 一格）。→ `ADR-0121`
- **`CombatActionKind { PlayCard, UseItem, ActivateAbility, EndTurn }` 已把「用道具」列为一等成员**；`ActionResult.SubjectId` 对 `UseItem` 读作 `ItemId`。→ `ADR-0087`
- **同款先例（承重）**：`ActivateAbility` 落地时的连带定案是「`CombatActionKind` 增 `ActivateAbility`、`CombatFeedKind` 增 `AbilityActivation`」，且**「启动复用 `CombatFeedKind.AbilityTrigger`」被明确否决**——理由是战报因果树读不出「我启动的」与「被触发的」之别。→ `ADR-0114`、`answer-logs/log-activate-ability-contract.md`
- **枚举增员的存档成本先例**：疲劳一等化时明写「存档 schema 一格不加：多的只是 `kind` 枚举的一个取值」。→ `ADR-0088`
- **新增字段的成本先例**：战场条目的 `amount` 一格在关键字清单为空时先行铺下，理由是「当前无线上存档 ⇒ 空迁移，此刻加格成本恒为零；不加的成本在第一条用得上它的内容落地时可能已不为零」。→ `systems/services/combat-service.md`「存档」
- **`TimingIds` 首批十个是封闭常量表，随广播点一同增长**；表内**没有一个时点按栈条目 `kind` 命中**。→ `systems/character-profile/deck/common-properties.md`

## 建议方案

### 1. 新增第五个成员 `StackEntryKind.UsedItem`

`[既有推演]`

推荐 `kind { PlayedCard, TriggeredAbility, ActivatedAbility, UsedItem, Fatigue }`。四条依据：

- **动作侧已经把它定为一等成员。** `CombatActionKind` 里 `UseItem` 与 `PlayCard` / `ActivateAbility` 平级。`CombatActionKind`（我发起了什么）/ `StackEntryKind`（栈上这条是什么来源）/ `CombatFeedKind`（战报这条是什么事）是同一条链路的三个切面；三者在「用道具」这一格上不对齐，本身就是缺口而不是设计。
- **`ADR-0114` 的同款先例已经答过一次同形的题**，结论是分立而非复用，理由是因果可读性。用道具与启动异能在这一点上完全同档：战报要读得出「他喝了一瓶药」与「他启动了阵法上的异能」之别，而两者的道念增量在快照上可以完全相同。
- **复用 `ActivatedAbility` 的代价比问题陈述里写的更重。** 不只是「`abilityId` 恒空、读取侧要分支」：`ActivatedAbility` 的既定填法是 `sourceEntryId = entryId`（载体所在的战场条目）· `abilityId = abilityId`，而道具**从不进场 ⇒ `sourceEntryId` 同样恒空**。复用后该成员的三个来源格里有两格变成可空，「`ActivatedAbility` ⇒ 有载体条目、有异能主体」这条不变式被整条抹掉，`ActivateAbility` 的「`SubjectId` 取 `entryId` 因为它是唯一寻址」那条纪律在该成员上也不再成立。这不是加一个分支，是让一个成员失去它的形状。
- **「凡按 `kind` 分支处全部要补一路」这项代价，在当前设计面上是空集。** 阶段 5 的收口按 `abilityId` 非空判、不按 `kind` 判；`TimingIds` 十个时点没有一个按栈条目 `kind` 命中；`EntryFilter` 筛的是战场条目不是栈条目（栈没有第二个可寻址面，`ADR-0088` 已把这条钉死）。目前唯一按 `kind` 分的地方是**呈现层映射到 `CombatFeedKind`**——而那一处正是需要它分开的地方。存档面按 `ADR-0088` 的先例同样是「多一个取值」，零迁移。

### 2. 成员名取 `UsedItem`（栈侧）/ `ItemUse`（战报侧）

`[通行做法]`

三个枚举各自内部一致，**不跨枚举统一词形**——这与本库已并存的三套词形一致，不是漂移：

| 枚举 | 词形 | 新成员 |
|---|---|---|
| `StackEntryKind` | 过去分词 + 名词（`PlayedCard` / `TriggeredAbility` / `ActivatedAbility`）——它命名的是「已发生的事」 | **`UsedItem`** |
| `CombatFeedKind` | 名词短语（`CardPlay` / `AbilityActivation` / `AbilityTrigger`）——它命名的是「一类事件」 | **`ItemUse`** |
| `CombatActionKind` | 动词短语（`PlayCard` / `UseItem` / `ActivateAbility`）——它命名的是方法 | 已有 `UseItem` |

`Fatigue` 在前两个枚举里同名，是因为它本身就是名词、无词形可分。

### 3. `CombatFeedKind` 同批增 `ItemUse`

`[既有推演]`

栈侧分立而战报侧合流，等于把第 1 条买到的可读性当场丢掉；且 `CombatFeedEntry` 的 `SourceId` 一格现有三种读法（`CardId` / `AbilityId` / 空），用道具复用哪一种都读不通——它要装的是 `ItemId`。故 `CombatFeedKind { CardPlay, AbilityActivation, AbilityTrigger, ItemUse, Fatigue }`，`SourceId` 的注释扩为 `... / ItemId（ItemUse）`。

条目取值（对位 `AbilityActivation` 那一段）：`EntryId = stackEntryId` · `CauseEntryId = string.Empty`（玩家主动动作是因果树的根，与 `CardPlay` / `AbilityActivation` 同）· `SourceId = itemId` · `SourceInstanceId = string.Empty`（道具没有卡牌实例）· `Side = 使用方` · `FizzledSlots` 照常。**敌人用道具同样广播本条、不产生 `ActionResult`**（与 `ActivateAbility` 敌人侧同款：没有调用方就没有返回值）。

`systems/architecture.md` 的 `CombatFeedEntry` 签名行**不需要改**（它列字段与类型，不复述枚举值域）。

### 4. 连带缺口：栈条目需要一格承载 `itemId`

`[既有推演]`

定了成员名还不够——**现有八格没有一格装得下「是哪一件道具」**，这一条不答，`UseItem` 的入栈填法仍然写不出来：

- `PlayedCard` 靠 `sourceInstanceId` → `instances` 表 → `cardId` 拿到内容 id；道具**不是 `CardInstance`**，`sourceInstanceId` 恒空（硬塞进去即撞闭集不变式与读档校验 ④）。
- `sourceEntryId` 恒空（从不进场）。
- `abilityId` 恒空（已定；且键空间闭合于 `AbilityData.Id`，塞 `ItemId` 会同时撞 `counters` 键约定与读档校验 ② 的强解析）。

⇒ 三个来源格与 `Fatigue` 逐字相同，而结算侧要按 `itemId` 解析 `ItemData.CombatUseEffects`、战报侧要 `SourceId = itemId`。建议：

- **栈条目新增 `itemId : string`**，`kind == UsedItem` 时非空、其余成员恒空（双向不变式，读档期可校验）。
- **读档校验 ② 扩为**：`cardId` / `sourceId` / `abilityId` / **`itemId`** 解析不到 → `PushError` 并报出 id。（`Get(id)` 不过滤 `ContentEnabled` 的既定性质原样适用，故战斗中途某道具被线上关闭仍能恢复。）
- **成本论证复用 `amount` 那条先例**：当前无线上存档 ⇒ 空迁移、不 bump `schemaVersion`，此刻加格成本恒为零；而不加的成本在第一件带 `CombatUseEffects` 的道具落地时可能已不为零。量级同样可忽略（`kind == UsedItem` 的条目才有值，一场至多几条）。

### 5. `card.played` 不因用道具广播；`item.used` 时点本次不开

`[既有推演]` + 一项待定（见「仍需用户决定」）

建议明写：**`TimingIds.CardPlayed` 只由 `PlayCard` 广播，`UseItem` 不广播它。** 依据是既定结构而非取舍——`card.played` 的 `SubjectKind` 是 `Card`，其 `TriggerFilter` 按 `CardTypes` / `ManaCostMin/Max` 筛选，需要一个卡牌 subject，而用道具没有 `CardInstance` 可交。不写明这一条，两侧会各写一半。

**「使用道具时」这一时点本次不开**（是否同批开列在「仍需用户决定」）：与 `ADR-0121`「战斗外触发点首版不开」同一条纪律——时点随广播点一同增长，无内容需求时不预铺；且 `SubjectKind { None, Card, Entry, Side }` 目前装不下「道具」这一档 subject，开它要连带增员。日后要开是**新增一行 `TimingId` + 一处广播点**，纯加法——**而分立的 `UsedItem` 正是让它此后写得出来的那一格**。

## 具体形态（可 derive 的落地面）

```csharp
// 栈条目（systems/services/combat-service.md「栈条目」）
kind { PlayedCard, TriggeredAbility, ActivatedAbility, UsedItem, Fatigue }
// 新增一格：itemId —— kind == UsedItem 时非空，其余成员恒空

public enum CombatFeedKind { CardPlay, AbilityActivation, AbilityTrigger, ItemUse, Fatigue }
// CombatFeedEntry.SourceId 注释扩写：
//   CardId（CardPlay）/ AbilityId（AbilityActivation | AbilityTrigger）
// / ItemId（ItemUse）/ string.Empty（Fatigue）
```

**`UseItem` 的入栈填法**（新增一段，对位 `ActivateAbility` 已有的那一条）：

| 格 | 取值 |
|---|---|
| `kind` | `UsedItem` |
| `controllerSide` | 使用方（敌人侧同走本填法，只是不经 `UseItem` API） |
| `itemId` | 该道具的 `ItemData.Id` |
| `sourceInstanceId` | `string.Empty` —— 道具不是 `CardInstance` |
| `sourceEntryId` | `string.Empty` —— 道具从不进场 |
| `abilityId` | `string.Empty` —— 已定；⇒ 收口阶段不 bump 默认 counters |
| `chosenTargets` | 传入的 `targets`（长度 = `Σ CombatUseEffects[i].TargetSlots.Length`） |
| `targetState` | `Resolved` —— 已定（主动发起，槽位发起前一次收齐） |

**对应的 `CombatFeedEntry`**：`Kind = ItemUse` · `Side` = 使用方 · `EntryId = stackEntryId` · `CauseEntryId = string.Empty` · `SourceId = itemId` · `SourceInstanceId = string.Empty` · `FizzledSlots` 照常 · 双方 `MomentumDelta` 照常。

**扣费**：与启动式同款——压栈那一刻扣 `sides[controllerSide].currentMana`（`ItemData` 可带 mana 费用，零费亦合法），`fizzle` 不退，不经 `ProfileManager`。次数消耗的既定落点（`Charges` 即时写 Profile · `UsesThisCombat` 落 `CombatItemSave`）不变。

## 后果

- **`systems/services/combat-service.md`**：「栈条目」一行改（枚举 +1 成员、字段 +1 格 `itemId`）· 「API 面」`UseItem` 段补一条「入栈」填法 · `CombatFeedKind` +1 成员并补一条对位 `AbilityActivation` 的取值段 · `CombatFeedEntry.SourceId` 注释扩写 · 读档校验 ② 扩一项 · 阶段 5 那条措辞**照旧成立**（判据本就是 `abilityId` 非空，无需因增员改写）。
- **`systems/architecture.md`**：`CombatFeedEntry` 的签名行不变。
- **`decisions/`**：建议以一条新 ADR 固化，或并入 `ADR-0121` 的「后果」（该 ADR 末行本就把这条列为待答）。**本草稿不写 ADR。**
- **存档**：`ActiveCombat.stack[].itemId` 一格新增；当前无线上存档 ⇒ **空迁移**、不 bump `schemaVersion`，与战场条目的 `amount` 一格同批处理。`CombatItemSave` 结构原样。
- **内容侧**：无新增字段、无新增加载期校验（`BumpCounterEffect` / `CounterAtLeastCondition` 在 `CombatUseEffects` 内是加载期错误——这条既定校验的依据是 `abilityId` 恒空，不受本方案影响）。
- **连带建议（可选，未纳入主方案）**：`ItemData` 在战斗内以 `CardType.Item` 呈现，故内容侧写得出「`card.played` + `CardTypes = [Item]`」这样一条**永不触发**的异能。若采纳第 5 条，可加一条加载期 `PushWarning` 把它点出来（与「能上线、线上不可见 ⇒ 必须提到写不出来这一级」同向）。是否加属工程细节，不阻塞本问题定案。

## 备选方案（已考虑并否决）

- **复用 `ActivatedAbility`** — 否决：`sourceEntryId` 与 `abilityId` 两格同时变可空，该成员的不变式被整条抹掉；且撞 `ADR-0114` 已否决过的同形选项（合流即因果不可读）。
- **复用 `PlayedCard`**（道具战斗内确以 `CardType.Item` 呈现）— 否决：`PlayedCard` 的既定填法是 `sourceInstanceId` = 那张牌的实例，而道具不是 `CardInstance`（三区闭集不变式不含储物袋）；复用即让「`PlayedCard` ⇒ 有实例」失效，并把「打出一张牌」的时点语义与用道具混为一谈。
- **道具不入栈、走独立结算路径** — 否决：撞 `ADR-0088` 的同一条论证（不入栈 = 不可被监听、战报无处挂），且「入栈即 `targetState = Resolved`」已定，栈已是既定路径。
- **把 `abilityId` 泛化为 `sourceContentId`（兼装 `AbilityId` / `ItemId`）** — 否决：撞 `counters` 键空间「键的第一段恒为 `AbilityData.Id`」这条闭合，也撞读档校验 ② 对 `abilityId` 的强解析；且「`abilityId` 恒空」已是既定前提。
- **把 `ItemId` 塞进 `sourceInstanceId`** — 否决：撞闭集不变式与读档校验 ④（实例表即三区并集）。
- **不新增 `itemId` 格，改为承诺「用道具的栈条目永不跨决策点存活」** — 否决：D4 是否发生不由发起方决定，且弹栈与结算的先后未被写成规则；这要求一条目前没有依据的新结构承诺，去换一格零成本的字段。
- **战报侧复用 `CardPlay`** — 否决：`SourceId` 读法冲突（`CardId` vs `ItemId`），且因果树读不出「喝药」与「出牌」之别。
- **同批开 `item.used` 时点** — 未否决，列入「仍需用户决定」。

## 与既有决策的张力

- **一条轻张力，不构成冲突**：`ADR-0088` 与 `ADR-0121` 都把「存档 schema 一格不加」列为卖点，而本方案新增 `itemId` 一格。两处原文都是「本次不需要加」而非「永不加格」，且同一份文档里的 `amount` 一格正是同款先例（先行铺下、空迁移、成本此刻恒为零）。故建议按 `amount` 的先例处理，并在提炼时如实写明这一格的由来，不把它藏进「零新增字段」的表述里。

## 前置依赖

- 无。本方案不依赖任何待答问题：`abilityId` 恒空、`targets` 形态、使用窗口、两道配额闸、次数写入通道均已定案；不涉及任何数值。

## 仍需用户决定

1. **是否同批开一个「使用道具时」触发时点（`TimingIds.ItemUsed`）。**
   - **不开（推荐）** —— 与 `ADR-0121`「战斗外触发点首版不开」同一条纪律：时点随广播点一同增长，无内容需求时不预铺；且 `SubjectKind { None, Card, Entry, Side }` 装不下「道具」这一档 subject，开它要连带增员并补一套 `TriggerFilter` 相容校验。代价：短期内写不出「对手用道具时」这类异能。日后要开是纯加法（一行常量 + 一处广播点 + 一档 subject），**而本方案分立出的 `UsedItem` 正是让它此后写得出来的前提**。
   - **同批开** —— 若已有「反制道具 / 惩罚用药」这类内容意图，现在开可省一次回头改；代价是 `SubjectKind` 增员 + `TriggerFilter` 的相容校验矩阵扩一列，且在首批内容出现之前无法验证它的筛选维度设计得对不对（撞「填什么条目要从『哪些组合真的重复了 ≥3 次』倒推」这条既定口径）。

   → **已按标准默认采纳（2026-08-28 · 批量评审 · `[采纳推荐 — 待复核]`）：不开 `TimingIds.ItemUsed`。**
   本项经 orchestrator 按 `/batch-provide-solution-draft` 第 4 步的分类纪律复核，判定**不属真取向**——它有既有推演给出的标准默认：`ADR-0121` 已定「战斗外触发点首版不开」同一纪律，且 `content/` 当前零条目 ⇒「无内容需求」是客观事实而非偏好，日后开它是纯加法。故未进合并 interview，按推荐直接采纳。
   **它不算用户拍板**，仍留在待答清单直至一次复核；主方案（`UsedItem` 增员等第 1–4 条）不受本项影响。
