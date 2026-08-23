---
type: solution-draft
date: 2026-08-22
question: 战斗内运行态计数器（`CharacterPower` / `PlayerPower` 的「本场已触发 N 次」、`PlayerItem` / `CharacterItem` 的「本场已用掉哪些、各自剩余次数」）的决策点存档字段形态如何落定？
source: open-questions/01-combat.md → 结构与配置的残留 → 战斗内运行态的决策点存档形态
targets: systems/services/combat-service.md（`ActiveCombat` 小节）· systems/character-profile/power/_index.md（待决问题「`Power` 的战斗内运行态存档形态未定」）· systems/player-profile/player-item/_index.md（待决问题「战斗内道具运行态的存档形态未定」）· systems/character-profile/item/_index.md
status: distilled
reviewed: 2026-08-22 — 三项取向全部裁决；合并 interview 另裁定计数写在结算成功那一刻（fizzle 不吃配额）· `counters` 键悬空统一为 `PushError` + 抛（不开例外）· 配额闸门结算时双查 · `AbilityData.Id` 不得含 `#`。**事实订正**：草稿称 `character-profile/item/_index.md` 未表态法宝即时写，实为已明写，该文件本次不改
distilled-to: handoffs/2026-08-22-combat-runtime-counter-persistence.md
---

# 方案草稿 — 战斗内运行态计数器的存档形态

## 问题

`ActiveCombat` 的整体 schema 与 D0–D6 决策点已在 `systems/services/combat-service.md`「战斗存档：`ActiveCombat`」中落定。待答清单仍挂着两块**运行态计数器**：

1. `CharacterPower`（神通）/ `PlayerPower`（法则）的「本场已触发 N 次」；
2. `PlayerItem`（古宝）/ `CharacterItem`（法宝）的「本场已用掉哪些、各自剩余次数」。

**首要发现（须先陈述，它改变了本问题的性质）：这两块的承载字段其实已经写在 `combat-service.md` 里了**——

- 战场条目字段表已有 `counters : Dictionary<string,int>`，并附一句「**`Power` 的战斗内运行态不需要独立结构——它就是战场条目的 `counters`**」；
- 「战斗内道具运行态」小节已给出 `readonly record struct CombatItemSave(string ItemId, int UsesThisCombat)`，并写明「只落『本场已用几次』」、剩余次数的权威在 Profile 侧的持有条目、战斗内再存一份就是双写；
- `CardInstanceSave` 亦已带 `IReadOnlyDictionary<string,int> Counters`。

**所以本问题的主体已被答定，只是两份主题文档（`power/_index.md`、`player-item/_index.md`）的待决问题小节与 `open-questions/01-combat.md` 尚未回填。** 本草稿因此**不重新设计承载结构**，而是：① 确认既有形态并给出它的完整依据；② 补齐既有形态里**真正还没写的那几格**——`counters` 的**键约定**、三条读档校验、法宝一侧的**对称性明写**、以及「谁来读这个计数器」的消费面。

真正悬着的空白是：**`counters` 的键是什么。** 没有键约定，「每场限用一次」这类效果就有 N 种写法，且悬空校验无从下手——这与本库既有的「具名字段而非 tag，因为悬空校验要求类型已知」（`enemies/_index.md` 的 `PoolScope` 论据）是同一条纪律。

## 约束（来自既有设计）

- **战场条目单表 + `kind`，`Power` 是其中一档（`PermanentPower`）**；`Power` 一律 `IsProtected`、开局入场、永不入栈。→ `combat-service.md`、`character-profile/power/_index.md`
- **「可重算的东西不进存档」是硬判据**：`Power` 的入场本身、触发器注册面、「本场可用道具」列表、合法目标集均已明确不落存档。→ `combat-service.md`「不落存档的可重建项」
- **古宝的使用次数即时经 `ProfileManager.TryApply` 写 PlayerProfile，不攒到收口**，为的是堵死「用完退出重进恢复次数」。→ `player-profile/player-item/_index.md`
- **持有条目的形态已定**：`CharacterItem(string ItemId, int Charges, bool Status, Source SourceCode)` / `PlayerItem(...)` 同形；`Charges` 是**剩余次数**，无限法宝恒为 `-1`。→ `player-profile/_index.md`
- **`AbilityData` 是跨载体可复用的独立资源，带稳定 `Id`**；`PowerData.Abilities` **至少一个、可多个**。→ `deck/common-properties.md`、`power/_index.md`
- **战斗内确实存在「每场限 N 次」这类配额效果**：法则的样板能力就是「**每场一次**重排手牌」「查看抽牌堆顶」。→ `player-profile/player-power/_index.md`
- **`ActiveCombat` 挂 `CharacterProfile`、收口置空**；写入通道 = `ProfileChangeSpec.EventStateChanges[ActiveCombat]`，整块绝对置值。→ `combat-service.md`
- **读档校验四个检查点全部命中，缺失分「必需 → `PushError` + 抛」/「可选 → `PushWarning` + 安全默认」两档。** → `.claude/rules/null-check-rules.md`、`state-save-rules.md`
- **多字段结构体带 schema 版本**；`ActiveCombat` 是新增块，随下一次 bump 走，当前无线上存档 = 空迁移。→ `state-save-rules.md`、`combat-service.md`

## 建议方案

### 1. `Power` 的「本场已触发 N 次」= 战场条目的 `counters`，不新增结构（确认既有）
`[既有推演]`

依据链条是闭合的、不需要新决策：`Power` 在参战方组装阶段作为 `CardType.Power` **注册进战场** → 战场条目字段表已有 `counters` → 战场条目整表随 `ActiveCombat.battlefield` 落每一个决策点存档。**建议原样保留，并把这条从 `power/_index.md` 的待决问题移入其意图段。**

三条连带确认（目前未明写，建议一并写下）：

- **未入场的 `Power` 不需要计数器落点。** `status` 关闭 / `UsableScene` 不含 `InCombat` / 在 `disabledAbility` 内 → 三条与门任一不成立即**不入场**，它本场也不可能触发，故「没有战场条目 = 没有计数器」不是缺口而是自洽。
- **`PlayerPower`（账号级）的本场计数器落在轮回级的 `ActiveCombat` 里是正确的**，不是层级错配：计数的是「**本场**触发了几次」，寿命等于这场战斗；账号级持久的那一半（持有 / `Status` / 残卷）在 `PlayerProfile`，两者语义不同、不构成双写。
- **敌人侧同表承载**：敌人的 `Power` 同样是战场条目（`ownerSide = Enemy`），不另立第二结构。

### 2. `counters` 的键 = `AbilityData.Id`，可带 `#` 子计数器后缀（本草稿的实际新内容）
`[既有推演]` + `[通行做法]`

**键的主体必须是 `AbilityData.Id`，不是 `PowerId` / `CardId`。** 理由是硬的：`PowerData.Abilities` 可含多个异能，「本场已触发 N 次」的配额天然挂在**某一个异能**上（样板「每场一次重排手牌」是一条异能的配额，不是整个法则的）。以条目为单位记数，一个双异能的法则就写不出「A 每场一次、B 不限」。

形态建议：

```
counters 的键 ::= <abilityId>                 // 该异能的默认计数器（触发 / 启动次数）
               | <abilityId> "#" <name>       // 该异能自己命名的第二个计数器，<name> 为点分小写短标识
```

- **`#` 前那一段必须能经 `ContentRegistry` 解析出一条 `AbilityData`**——这使键具备与全库其他跨类型引用同款的**悬空校验能力**（`PoolScope.LocationId` / `PlotArcData.ParentArcId` / `KeyCardIds` 全是这个模式）。裸自造字符串键做不到这一点。
- **值域 `>= 0`**；**为 0 的键不写入**（等价于「没记过」），与 `CardInstanceSave.Counters`「空则整字段省略」的既有约定同向——省下的是每个决策点 2–4 KB diff 里的一堆零。
- **`CardInstanceSave.Counters` 与战场条目 `counters` 共用同一套键约定**，不写成两套：两处都是「某条异能在本场的运行态计数」，分两套约定只会让效果侧的读写函数写两遍。

### 3. 计数器的消费面 = BattlefieldManager 的一个只读查询
`[既有推演]`

「每场限 N 次」的闸门要能在**启动 / 触发之前**读到当前计数，否则配额只是存了但没人管。建议：

- 读：`int GetCounter(string entryId, string counterKey)`（缺键返回 0）——由 BattlefieldManager 提供，与「战场持有场上的全部准确数据」一致。
- 写：计数只在**该异能实际生效的那一刻** +1（触发式 = 压栈成功时；启动式 = 支付 `ActivationCost` 成功之后）。**fizzle 掉的条目不计数**——`combat-service.md` 已定「全部有目标的槽位都非法 → 整条不结算」，一条没结算的异能不该吃掉配额。
- 这两条不新增 manager、不新增事件，落在既有的 BattlefieldManager 职责内。

### 4. 道具运行态 = `CombatItemSave(ItemId, UsesThisCombat)`，剩余次数不落 `ActiveCombat`（确认既有 + 补对称性）
`[既有推演]`

**「本场已用掉哪些、各自剩余次数」这句问题陈述里，后半句的答案是「不存」**：剩余次数的唯一权威是 Profile 侧持有条目上的 `Charges`，且使用次数**即时**经 `TryApply` 写入。在 `ActiveCombat` 里再存一份剩余次数 = 第二个落点、无机制保证两份相等——与 `enemyRef` 拒绝「拷贝整份实例」是同一条判据。

`UsesThisCombat` 则**必须存**，它是「每场限用一次」这类**本场配额**的唯一载体（与第 2 条的 `counters` 是同一类语义在道具侧的落点）。

**须补写的对称性（当前文档只论证了古宝一侧）：法宝 `CharacterItem` 的 `Charges` 同样即时写 `CharacterProfile.magicPack`，不攒到收口。** 理由与古宝一字不差（堵死退出重进恢复次数），且 `magicPack` 本就随每个决策点的 `ActiveCombat` 同一次 `TryApply` 走。**两级道具在存档面上完全对称，`CombatItemSave` 一个结构覆盖两级**——`ItemData.Scope` 是内容侧静态字段，故 `ItemId` 已唯一决定它是哪一级，`CombatItemSave` **不需要再带 `Scope` 字段**。

**敌人侧同样用 `CombatItemSave`**：敌人没有储物袋、道具来自 `EnemyData` 持有列表，没有 Profile 侧的 `Charges` 可写，故**敌人道具的次数上限只能靠 `UsesThisCombat` 对着 `ItemData.Charges` 比**。这是 `UsesThisCombat` 的第二个不可替代用途，建议一并写明。

### 5. 三条读档校验（并入既有的四检查点）
`[既有推演]`

| 违规 | 语义 | 处置 |
|---|---|---|
| `counters` 某键的 `abilityId` 段经 `ContentRegistry` 解析不到 | 可选缺失（计数器丢失只影响一次配额，不破坏局面） | `PushWarning` + 丢弃该键、其余照常恢复，带 `entryId` + 键 |
| `counters` 值为负、或 `UsesThisCombat < 0` | 不可能态 / 内部一致性破损 | `PushError` + 抛，带 `entryId` / `itemId` |
| `CombatItemSave.ItemId` 不在该侧「本场可用道具」的重建结果内 | 存了一件本场根本不可用的道具（多半是 `disabledAbility` 或 `UsableScene` 中途变化） | `PushWarning` + 丢弃该条，不阻断恢复 |

第一条与第三条取「可选缺失」是有依据的：`combat-service.md` 已定「战斗中途某条目被线上关闭仍能恢复」，读取侧 `Get(id)` 不过滤 `ContentEnabled` 正是为此；把计数器缺失升级为拒绝恢复，会让一次内容运维动作废掉玩家进行中的战斗。

## 具体形态（可 derive 的落地面）

```csharp
// 既有（确认，不改）——战场条目字段表中的一格
// counters : Dictionary<string,int>   键 = AbilityData.Id [ "#" 子名 ]；值 >= 0；为 0 不写入

// 既有（确认，不改）
public readonly record struct CombatItemSave(
    string ItemId,          // ItemData.Id；Scope 由内容侧静态字段决定，不重复落
    int    UsesThisCombat); // 本场已用次数，>= 0；剩余次数不落此处

// 新增（消费面，落 BattlefieldManager）
int  GetCounter(string entryId, string counterKey);          // 缺键 → 0
void BumpCounter(string entryId, string counterKey, int by); // 仅在异能实际生效时调用
```

存档落点一览（全部为既有字段，本草稿不新增任何 `ActiveCombat` 字段）：

| 运行态 | 落点 | 权威 |
|---|---|---|
| `Power` 本场触发次数 | `activeCombat.battlefield[i].counters` | 唯一 |
| 卡牌实例本场计数 | `activeCombat.sides[i].instances[j].Counters` | 唯一 |
| 本场已用哪些道具 / 用了几次 | `activeCombat.sides[i].items[k]` | 唯一 |
| 道具**剩余**次数（玩家侧） | `PlayerProfile.playerItem[].Charges` / `CharacterProfile.magicPack[].Charges` | 唯一（战斗内即时写） |
| 道具**总次数上限**（敌人侧） | `ItemData.Charges`（内容侧静态） | 唯一 |
| 「本场可用道具」列表 | **不落存档**，按 `UsableScene` ∩ 持有 ∩ ¬`disabledAbility` 重建 | 派生 |

## 后果

- **`ActiveCombat` schema 不变**——本方案不新增字段，故既定的「单次决策点 diff 2–4 KB / 一场 ≈93 KB」量级不受影响，版本化仍是随下一次 bump 的空迁移。
- **三份主题文档回填**：`power/_index.md` 与 `player-item/_index.md` 各删掉一条待决问题、改写为意图；`combat-service.md` 补键约定、三条校验、法宝对称性与消费面签名；`character-profile/item/_index.md` 补「法宝次数即时写」这半句。
- **内容侧多一条纪律**：「每场限 N 次」类异能必须给自己的 `AbilityData` 一个稳定 `Id`（本就必须），并在效果定义里引用该键，不得自造裸字符串。
- **`open-questions/01-combat.md` 的该条可整条移出**（若第 2 条的键约定被采纳）；移出与 `answer-logs/` 归档由 `/analyze-new-ideas` 执行，不在本草稿范围。

## 备选方案（已考虑并否决）

- **给 `ActiveCombat` 新增一张顶层 `powerCounters` 表（按 `PowerId` 索引）** —— 否决：`Power` 已是战场条目，另立一表即同一对象两个落点；且它会把「未入场的 Power 有没有计数器」变成一个必须回答的歧义问题。
- **`counters` 键用 `PowerId` / `CardId`** —— 否决：多异能条目写不出 per-ability 配额（见第 2 条）。
- **在 `ActiveCombat` 里存道具的剩余次数** —— 否决：与 Profile 侧 `Charges` 双写，且「即时写以堵死退出重进」这条定案会被架空。
- **`CombatItemSave` 带 `Scope` 字段** —— 否决：`ItemData.Scope` 已唯一决定，冗余字段是可以不一致的第二真值（与「栈内位置不落 `position` 字段」同款判据）。
- **计数器缺失即拒绝恢复战斗** —— 否决：与「读取侧不过滤 `ContentEnabled`、战斗中途被线上关闭仍能恢复」冲突，代价与收益完全不成比例。

## 与既有决策的张力

**一处，且是文档一致性而非设计冲突：** `open-questions/01-combat.md`、`power/_index.md`、`player-item/_index.md` 三处仍把本问题记为「字段形态未定」，而 `combat-service.md` 已经给出了形态（08-17h / 08-19 两次 handoff 写入）。这是**待答清单落后于主题文档**，不是两处设计打架。本草稿按「主题文档为准」处理，并把三处的回填列进后果。若用户认为 `combat-service.md` 的那两格本身尚未获批准，则第 1、4 条需退回为待裁决项——**请在评审时明确这一点**。

另：`character-profile/item/_index.md` 对「法宝次数是否即时写」**未表态**，`player-item/_index.md` 只论证了古宝一侧。第 4 条的对称性建议是**补白，不是既有定案的复述**，需要用户点头。

## 前置依赖

- **无阻断性前置。** 计数器的**取值**（「每场几次」具体给几）依赖 ch1 数值标杆专场与「一张牌该产多少道念」的量纲，但**字段形态不依赖它**——本草稿只定形态。
- 弱依赖：`AbilityData` 的 `Id` 命名规范尚未在 `content/_index.md` 的 id 约定表中登记（`content/` 下尚无任何类型档案）。第 2 条的键约定只要求「点分小写 + 可解析」，不要求先定死前缀，故不阻塞。

## 仍需用户决定 → **已全部裁决（2026-08-22 · 批量评审）**

> 逐条裁决（`/batch-provide-solution-draft` 合并 interview）：
> 1. `counters` 的键约定 → **已裁决：A · `<abilityId>[#<子名>]`，`#` 前一段须能经 `ContentRegistry` 解析（悬空校验）**
> 2. 法宝 `CharacterItem.Charges` 是否与古宝对称、同样即时写 → **已裁决：是 · 对称即时写**
> 3. `combat-service.md` 已写的 `counters` / `CombatItemSave` 两格是否视为已批准的定案 → **已裁决：视为定案** ⇒ 本稿相关条目为回填，另须把 `open-questions/01-combat.md` · `power/_index.md` · `player-item/_index.md` 三处落后的登记一并改正


1. **`counters` 的键约定取哪一档？**（本草稿的唯一实质取向）
   - **A（推荐）：`<abilityId>[#<子名>]`，`#` 前一段必须可解析出 `AbilityData`，加载 / 读档时悬空校验。** 理由：与全库「具名 id + 悬空校验」的既有纪律一致，且天然支持一个异能挂多个计数器。代价：内容侧写效果时要引用异能自己的 `Id`。
   - B：键为**自由字符串**，只在读档时对未知键 `PushWarning`。更省事，但悬空拼写错误要到运行时才显形，且「这个键是谁的」无法机械回答——与 `PoolScope` 否决 tag 方案的理由同构。
   - C：为计数器另立一个内容层注册表 `CounterData`。最严格，但为一个纯运行态的键引入第三个注册表，收益不抵成本。
2. **法宝 `CharacterItem` 的 `Charges` 是否与古宝对称、同样即时写？**（第 4 条）推荐**是**——不对称会让内容侧多背一条「哪一级的道具能靠退出重进恢复次数」的例外表，而这正是既定纪律要堵的洞。若用户选「否」（法宝次数攒到收口），则 `CombatItemSave` 需要为法宝一侧额外承载剩余次数，形态随之变化。
3. **`combat-service.md` 里已写的 `counters` / `CombatItemSave` 两格，是否视为已获批准的定案？**（见「与既有决策的张力」）若视为定案，本草稿的第 1、4 条只是回填文档；若不视为定案，它们需要在本轮一并拍板。
