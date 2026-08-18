---
type: solution-draft
date: 2026-08-17
question: Research（闭关）类 AdventureEvent 的通用结算器数据形态、卡组操作清单与代价、卡组外产出、开局构筑事件的候选生成；以及 `manaLimit` 下降（−1）的承载点
source: open-questions/03-adventure-event-types.md → 「各类型的结算 / 机制细化」的 Research 一项 + 「`manaLimit` 下降（−1）的承载点（08-15c 新增）」
targets: systems/adventure-event/research/_index.md · systems/adventure-event/research/common-properties.md · systems/character-profile/mana.md · systems/character-profile/deck/_index.md · systems/services/future-event-service.md · systems/services/profile-service.md · systems/architecture.md（共享核心类型）· systems/balance.md
status: distilled
decided-on: 2026-08-17
reviewed: 2026-08-17 —— 五项取向一律取推荐项（选项 A）：增列 `DeckElements`（承重措辞松动获裁决通过）· `manaLimit` 下降改挂 Research 的玩家自选风险档 · 允许回复 `lifeTotal` · 常态 `AllowDecline` 默认 `true` · 三条顺带项一并采纳
distilled-to: handoffs/2026-08-17b-research-build-panel-and-deck-elements.md
---

> **本草稿已裁决（2026-08-17）：全部取向项一律按推荐方案定案。** 逐项见文末「## 仍需用户决定 → 已全部裁决」。

# 方案草稿 — Research 类 AdventureEvent 的通用结算器与卡组操作

## 问题

Research（闭关）是五类 AdventureEvent 之一，语义已定为「玩家调整 / 升阶自己的卡组」，且**开局那个强制的构筑事件归它**。但它的机制层至今只有语义、没有形态，具体悬着四个互相咬合的点：

1. **卡组操作的清单与代价** —— 升阶 / 弃置 / 学新各自的规则：一次事件能做几次操作？可选范围如何生成？是否有额外的资源代价？
2. **除卡组外是否另有产出** —— 回复 `lifeTotal`？推拉隐藏属性？领悟法则？若有，需与「Research = 调整卡组」的收窄语义划清边界。
3. **开局构筑事件的候选生成** —— 功法 / 法宝各三选一的候选池从哪来、是否受 seeded RNG 与 PlayerPower 影响。
4. **`manaLimit` 下降（−1）的承载点** —— 「罕见 −1（走火入魔类）」此前挂在探索秘境上；Explore 已收窄为纯元类型、无自己的产出口径，其可揭示的三类（Combat / Travel / Exchange）都不是自然的走火入魔场景。改挂 Research，还是接受「本作没有 `manaLimit` 下降」（= `manaLimit` 单调不减）。

它卡住的东西：Research 是**轮回内构筑的唯一落点**（升阶 / 弃置 / 学新全在这里），而开局构筑事件又是玩家进入轮回的第一屏。这一块不成形，`AdventureEventData` 的 outcome 定义、`ProfileChangeSpec` 的 element 清单、开局流程、以及 `CultivationTechniqueData` 的内容层开张都推不动。

**本草稿在推演中发现一处既有文档的缺口，它先于上述四问：** `systems/character-profile/deck/_index.md` 写明「升阶 / 弃置 / 学新三者都是轮回级卡组变更，走 `ProfileChangeSpec` → `TryApply`」，但 `ProfileChangeSpec` 的三个平级列表（`Elements` 资源 / `AbilityElements` 能力 / `Stats` 统计）**没有一个能承载卡组变更**——`AbilityKind` 只有 `{ Power, Item }`，功法与游离散牌都不在其中。见「## 前置依赖」与「## 与既有决策的张力」。

## 约束（来自既有设计）

- **Research 走通用结算器，不走战斗结算。** 五类事件只有两个 resolver，Research 落 `GenericEventResolver`（读模板上的数据驱动 outcome / effect 定义）。resolver **只描述结果（`ResolveOutcome`），不自行写档**。`systems/services/life-cycle-service.md`、`systems/adventure-event/common-properties.md`「结算阶段」。
- **一个事件 = 一次事务 = 一个存档点。** 全部产出与成本在 `eventEnd` 合并为**一次** `TryApply`。同上。
- **`selectCost` 无条件施加、`AbilityElements` 在 `selectCost` 内恒为空（承重）。** 能力得失只能出现在 outcome / reward 侧。`systems/adventure-event/common-properties.md`。
- **决策点面板的形状已存在，不必新造：** 「结算时（`eventEnd` 之前）预先掷定候选 → 玩家择一 → 与 `eventEnd` 那一次 `TryApply` 合并」，且**候选必须预先算定并落决策点存档，否则退出重进可以重掷**。同上「outcome 侧的对应形态」+ `systems/services/combat-service.md` 战后奖励。
- **产出即定稿、物化产出的数值必进快照。** `EventOption` 一经输出即冻结，消费侧不得回查模板重算。`systems/services/future-event-service.md`。
- **抽取一律经 `AllEnabled()` / `DrawPool<T>`；`PickMany` 无放回；加权键是 `Rarity: RarityTier`。** `systems/services/content-service.md`、`systems/common-properties.md`。
- **能力条目的抽取只有一处：`GrantPoolPicker`**（取池 → `(Kind, Scope)` → 去成就限定 → 排除已持有 → 可选锚定 `Rarity` → 按 `RarityTier` 加权 seeded 抽取）。`systems/services/profile-service.md`。
- **授予必须带 `Source`，且 `(Kind, Scope, Source)` 须落在合法子集表内。** 表中 `EventOutcome` 行：`(Power, Player)` ❌ · `(Item, Player)` ❌ · `(Power, Character)` ✅ · `(Item, Character)` ✅。`systems/common-properties.md`。
- **通用结算器算出的授予一律记 `Source.EventOutcome`**（判据 = 谁组装出这条 element）。`systems/services/future-event-service.md`。
- **`manaLimit` 单次变动幅度恒为 1，不设 ±2 档；不设下界护栏、不做死牌转化；Research 是推高的主通道（常见 +1）。** `systems/character-profile/mana.md`。
- **功法 = 卡组的构筑单位；进化 = 整组替换；存档存「功法 `Id` + 层数」+ 游离牌 `Id` 列表；弃置不设限（含角色绑定的两门）。** `systems/character-profile/deck/_index.md`。
- **Research 不可被 Explore 遮罩；闭关的 `lifeSpanCost` 高于常规事件。** `systems/adventure-event/explore/_index.md`、`systems/balance.md`。
- **开局构筑事件不需要新机制**——`eventPriority = 1` 已能表达「本批必须进这个」。`systems/adventure-event/research/_index.md`。

---

## 建议方案

### 1. Research 的结算形态 = 「构筑面板」，由若干**决策槽**组成

`[既有推演]`

建议把 Research 的通用结算器数据形态定为：**模板持有 N 个决策槽（slot），物化时为每个槽预先掷定一组候选操作，结算时玩家逐槽择一，全部选择与 `lifeSpanCost` 合并为 `eventEnd` 的一次 `TryApply`。**

三条依据：

- **它不是新机制，是既有面板的第三个实例。** 「结算时预先掷定候选 + 玩家择一 + 并入 `eventEnd` 那一次 `TryApply`」这套形状，战后奖励面板与能力置换面板已各用一次。Research 用第三次，零新增结构。
- **决策槽的复数形态是被开局事件逼出来的，不是为扩展预留。** 开局构筑事件要求「选**一门功法**与**一件法宝**，各三选一」——这在同一个 Research 事件内就是**两个**决策槽。常态条目填 1 个槽，开局条目填 2 个。**若只支持单槽，开局事件就必须另设机制**，而既定意图明写它「不需要第六类、不需要新机制」。
- **它与「一批只有一次操作：择一进入」不冲突。** 那条约束的是**批次层**（面对一批 eventOptions 只能选一个进入）；槽是**事件内部**的结算结构，与战后奖励面板在事件内部做一次选择同层。

**候选掷定的时机 = 物化阶段，随 `EventOption` 落存档。** 依据是「候选必须预先算定并落决策点存档，否则退出重进可以重掷」这条既定纪律，加上「物化产出的数值必进快照」。这条**同时是走火入魔风险档能够成立的前提**（见第 5 节）。

### 2. 操作清单 = 六类，闭合

`[既有推演]` + `[通行做法]`

| 操作 | 语义 | 载体 element | 依据 |
|---|---|---|---|
| **`LearnTechnique`** | 学会一门新功法（入组，层数 = 1） | 卡组 element（见第 3 节） | `deck/_index.md` 三种变更之一 |
| **`UpgradeTechnique`** | 已持有功法层数 +1（该组牌整组替换） | 卡组 element | 同上 |
| **`ForgetTechnique`** | 弃置一门已持有功法（含角色绑定的两门） | 卡组 element | 同上；「弃置不设限」已定 |
| **`RemoveLooseCard`** | 移除一张游离散牌（业障 / 单卡奖励） | 卡组 element | 业障进卡组已有通道，出卡组此前无落点——StS 的「移除一张牌」是构筑事件的标准动作 |
| **`GrantItem`** | 获得一件法宝 `CharacterItem` | `AbilityChangeElement(Grant, Item, Character, id, Source.EventOutcome)` | 合法子集表该格为 ✅；开局的「法宝三选一」正是它 |
| **`Recuperate`** | 回复 `lifeTotal` | `ChangeElement(CostKey.LifeTotal, +n)` | 见第 4 节 |

**`manaLimit ±1` 不单列为一种操作**——它是上述操作的**附带产出**（钻研到位则容量提升，走火入魔则容量受损），与「压低只以负向奖励条目的形态出现、不另立结构」一致。见第 5 节。

**明确不在清单内的三项：**

- **加一张游离散牌（`AddLooseCard`）不作为 Research 的正向操作。** 构筑单位是功法，正向的卡组增长应走 `LearnTechnique`；单卡加入卡组的既有通道是**战斗奖励与事件负向奖励**，Research 再开一条会让「功法是构筑单位」的颗粒度被单卡稀释。（业障作为 Research 的**负向**结果进卡组不受此限——那走的是既有的负向奖励条目通道。）
- **领悟法则（`PlayerPower`）不做。** 合法子集表里 `EventOutcome × (Power, Player)` 是 ❌（暂不开放，取决于尚未设计的「法则的第三条获取渠道」）。这不是取向问题，是一条现成的机械约束。
- **授予神通 `CharacterPower`（`(Power, Character)` = ✅）暂不放进 Research。** 语义上归战斗奖励与 Exchange 更自然；技术上随时可开（合法子集表已经允许），属内容口径而非规则改动。

### 3. 卡组变更的载体：`ProfileChangeSpec` 需要第四个平级列表 `DeckElements`

`[既有推演]`（这是本草稿最需要用户裁决的结构性一条，见「## 与既有决策的张力」）

**问题：** `deck/_index.md` 已写明卡组变更「走 `ProfileChangeSpec` → `TryApply`」，但三个现存列表没有一个装得下它：

- `Elements` 是**带符号的量**（`CostKey` + `int`）——功法层数不是可加的资源量，游离牌不是量纲。
- `AbilityElements` 是**按 `Id` 的集合成员操作**，但 `AbilityKind` 只有 `{ Power, Item }`，且它的语义是**幂等的集合增删**。功法与散牌都不满足：
  - **功法带层数**，`UpgradeTechnique` 既不是 `Grant` 也不是 `Remove`，塞进去只能靠「先 Remove 再 Grant 同 id」这种谎报（还会撞上 `PairKey` 的配对校验语义）。
  - **游离散牌是多重集**：同一张业障可以在卡组里出现多张。而 `AbilityElements` 的失败语义明写「`Grant` 的目标已持有 → `PushWarning` + 空操作」——把散牌塞进去，第二张同名业障会被静默吞掉。
  - `AbilityElements` 强制携带 `Source`，而卡组条目没有 `SourceCode` 字段（`SourceCode` 的挂载面明确是四类持有条目：PlayerPower / PlayerItem / CharacterPower / CharacterItem）。

**建议形态：**

```csharp
public enum DeckChangeOp { LearnTechnique, UpgradeTechnique, ForgetTechnique, RemoveLooseCard }

public readonly record struct DeckChangeElement(
    DeckChangeOp Op,
    string       Id,          // 功法 Id（前三个 Op）或卡牌 Id（RemoveLooseCard）
    int          Tier);       // 仅 LearnTechnique(=1) / UpgradeTechnique(=目标层数) 有意义，其余写 -1

// ProfileChangeSpec 第四个平级列表
public IReadOnlyList<DeckChangeElement> DeckElements { get; }
```

- **绝不走 modifier pipeline**（同 `AbilityElements` / `Stats`）：一条法则若能把「层数 +1」放大成 +2，「进化 = 整组替换、每层一整套定义」直接失去意义（不存在「1.5 层」的卡牌定义）。
- **`Tier` 写目标层数而非增量**，理由与 `AbilityChangeElement` 只承载已定稿 `Id` 同源：`AppliedChange` 要可直接重放，写增量会让重放结果依赖当时的层数。
- **`DeckElements` 在 `selectCost` 内恒为空**，与 `AbilityElements` 同一条不变式、同样落为物化组装后的断言 + 内容模板加载期校验。理由完全同构：成本侧只放可如实计价的量，而「一门功法值多少寿元」无法回答。
- **加载期 / 施加期校验（与既有失败语义表同档）：**

  | 情形 | 语义 | 处置 |
  |---|---|---|
  | `UpgradeTechnique` 的目标不在卡组 / 已达层数上限 | 可选缺失 | `PushWarning` + 该 element 空操作，不使整批失败 |
  | `ForgetTechnique` / `RemoveLooseCard` 的目标不在卡组 | 可选缺失 | 同上 |
  | `LearnTechnique` 的目标已在卡组 | 可选缺失 | 同上（候选池已排除已有，出现即内容错误） |
  | `Id` 解析不到内容条目（功法 / 卡牌注册表） | 必需缺失 | `PushError` + 整批拒绝（悬空 `Id` 写进 Profile 会污染存档） |
  | `Op ∈ { LearnTechnique, UpgradeTechnique }` 且 `Tier < 1`，或其余 `Op` 且 `Tier != -1` | 必需缺失 | `PushError` + 整批拒绝 |
  | `DeckElements` 出现在 `SelectCost` 内 | 必需缺失 | `PushError` + 整批拒绝 |

- **存档面：** `PastEventEntry.AppliedChange` 随 `ProfileChangeSpec` 自动获得卡组变更的账，**不新增字段**；但 `ProfileChangeSpec` 增列 ⇒ **bump 存档 schema 版本**（当前无线上存档 ⇒ 空迁移，走既有 MigrationManager 骨架）。

**否决的两个替代：**

| 替代 | 否决理由 |
|---|---|
| 扩 `AbilityKind` 加 `Technique` | 层数无处安放（`AbilityChangeElement` 无 `Tier` 格，加上去则该格对 Power / Item 恒无意义）；强制携带的 `Source` 对功法无落点；且 `AbilityScope` 对功法恒为 `Character`，等于引入一个取值域恒定的字段 |
| 塞进 `Elements`，用 `CostKey.TechniqueTier(id)` 一类参数化 key | `CostKey` 是封闭枚举 + `ResourceElements` 一行一语义，参数化 key 直接打穿「启动期断言表覆盖 `CostKey` 全部成员」；且散牌的多重集语义仍无处表达 |

### 4. 卡组外的产出：只开两扇门（`lifeTotal` 回复 · `manaLimit ±1`）

`[既有推演]` + `[通行做法]`

- **允许回复 `lifeTotal`（建议采纳）。** 三条支撑：① 「**不单列休养 / Rest，休养语义并入闭关**」是既定决策——休养并进来了，它的产出（回血）却没地方去，等于并了一半；② `life-total.md` 已定「恢复途径 = 通过 event 恢复」，未限定事件类型；③ **`Recuperate` 与 `UpgradeTechnique` 在同一个决策槽内并列，正是 StS 篝火（rest / smith）的形状**——一个玩家真正会犹豫的二选一，而这恰好给了当前纯收益的 Research 一条内部张力。载体是既有的 `ChangeElement(CostKey.LifeTotal, +n)`，零新增。
- **隐藏属性推拉照常。** 它是**全部五类事件共有**的通道（`eventEnd` 合并施加 + 跨档定性叙事），不是 Research 的专有产出，无需在 Research 侧做任何表态。
- **领悟法则不做**（合法子集表 ❌，见第 2 节）。
- **不给灵玉 `Jade` 产出。** `mana.md` 已把「给灵玉一个长期价值出口」分派给 Exchange；Research 产灵玉会与之抢同一条价值线。

**边界一句话（建议写进 `research/_index.md`）：** Research 的产出面 = **卡组** + **`manaLimit`** + **`lifeTotal`** + 全类型共有的隐藏属性推拉；此外不给。这条收窄使「Research = 调整卡组」不至于被泛化成「万能的正向事件」。

### 5. `manaLimit` 下降：建议**改挂 Research**，且做成玩家自选的风险档

`[取向选择]`（推荐项明确，但取消下降也是自洽的一条路，见「## 仍需用户决定」）

**建议：把「走火入魔」定为 Research 的一个风险型决策槽候选**——玩家可以选一个高风险的钻研选项，成功 `manaLimit +1`，失败 `manaLimit −1`；掷定发生在**物化阶段**并随 `EventOption` 落存档（退出重进不改变结果）。

四条依据：

1. **叙事轴与 mana 分档表天然对齐。** `mana.md` 已把 Research 定为推高的**主通道**（「钻研 / 潜修在叙事上就是提升法力容量」）；走火入魔是同一条轴的反面，挂同一类型不需要新叙事前提。Explore 已收窄为纯元类型、可揭示的三类都不是走火入魔场景——它确实无处可挂。
2. **它给 Research 补上唯一缺失的张力。** 目前 Research 是**纯收益事件**：付寿元、拿构筑，没有任何可能变糟。而闭关的 `lifeSpanCost` 又是全类型最贵的一档——一个「最贵且必然赚」的事件在批次里会成为无脑首选，压掉「从一批里择一」的决策价值。风险档把它变回一次真实取舍。
3. **取消下降会让三条既有决策变成无消费方的空文。** 「不设 `manaLimit` 下界护栏」「不做死牌转化」「极端情形下高费卡成为死牌是可接受的」——这三条**全部以「下降存在」为前提**。取消下降后它们不是错，而是永远不会被触发；等于留下三条无人消费的决策债。
4. **「玩家自选」而非「随机惩罚」是关键的一半。** 被系统随机扣上限，玩家只会感到被惩罚；**自己按下那个按钮**则是既定取向「明知是死路仍然走 / 打不过也得打」的同族——风险是被选择的，不是被施加的。

**配套（若采纳）：** `manaLimit` 需要进 `CostKey`：

| `CostKey` | Min | Max | 归 Min 时 | `CostModifier` | `GainModifier` | 依据 |
|---|---|---|---|---|---|---|
| `ManaLimit` | 0 | 无 | **无**（不构成终态） | `null` | `null` | `Min = 0` 只排除「负上限」这个无法定义的状态（每回合恢复到负值讲不通），**不是被否决的那两条护栏**（保底 ≥ 1、死牌转化仍然不做）；两个修正列留空是硬要求——**任一列开放，一条法则即可把 ±1 放大为 ±2，直接推翻「单次变动幅度恒为 1」这条承重规则** |

这一行与 `08-16d` 已写下的口径一致（「`manaLimit` 若进 `CostKey`，其 `Min = 0` 是取值域而非下界护栏」），本草稿只是把它从假设句变成登记行。

### 6. 候选生成：功法与法宝走两条既有抽取链，零新增抽取代码

`[既有推演]`

| 槽内候选 | 取池链 | 随机源 |
|---|---|---|
| **法宝三选一** | **直接复用 `GrantPoolPicker`**：`TryPickGrantableMany(AbilityKind.Item, AbilityScope.Character, rng, 3)`——取池 → `(Kind, Scope)` → 去成就限定（`ExclusiveSource != null` 排除）→ 排除已持有 → 按 `RarityTier` 加权 → **无放回**抽 3 条 | `RngStream.Reward` 子流的 `GodotRandomSource` |
| **功法三选一（学新）** | `ContentRegistry` 的 `CultivationTechniqueData` 仓储 → `AllEnabled()` / `DrawPool<T>` → 排除卡组中已持有的功法 `Id` → 按 `RarityTier` 加权 → `PickMany(rng, 3)`（无放回） | 同上 |
| **升阶候选** | 卡组内**已持有且未达层数上限**的功法（不足 3 门时给几门算几门；一门都没有则该操作不进候选） | 同上 |
| **弃置 / 移除散牌候选** | 卡组内已持有的功法 / 游离散牌 | 同上 |

- **法宝那一路是纯复用**：`GrantPoolPicker` 已被文档定义为「账号级 / 轮回级能力条目的**唯一抽取处**」，法宝三选一恰好是 `(Item, Character)` + `count = 3`，一行调用即可，**不新增任何抽取代码**。
- **功法那一路需要一次加权抽取，但形状与 `GrantPoolPicker` 完全同构**（`CultivationTechniqueData` 带 `Rarity`，见 `deck/_index.md` 的功法 header 形态）。它落 `DrawPool<T>` 的第五个调用方——建议在 `content-service.md` 的调用方清单里同步登记。
- **RNG 子流建议复用 `RngStream.Reward`，不新开子流。** 依据：`Reward` 已承载「战后奖励候选一次性抽定」这一完全同构的用途（预先掷定 + 落存档 + 绝不重抽）；子流的作用是隔离不相关系统，而奖励候选与构筑候选**从不并发**（一次只结算一个事件）。**这条顺带答了 `deck/_index.md` 的待决项「功法 / 法宝三选一的 RNG 子流归属」**——那条不在本次锁定范围内，采纳与否请一并裁决。
- **是否受 PlayerPower 影响：建议否（候选池不接 modifier pipeline）。** `AbilityElements` 永不走 pipeline 是既定纪律；候选池的**权重**若可被法则推拉，等于开一条「账号级内容改写轮回级构筑运气」的通道，而它在 `ContentEnabled` / `ExclusiveSource` 之外无人校验。**唯一例外是 capability flag**：日后若有「看见候选的稀有度」这类呈现向 flag，那走的是呈现层，不改池。

### 7. 开局构筑事件 = 上述形态的一个内容条目，不需要任何专属规则

`[既有推演]`

- **`eventPriority = 1`**（本批有效可选集收窄为该档）——既定，不新增机制。**置位方是 future-event-service**，故它是「`Priority = 1` 依什么条件抬升」那条待答项的第二个确定答案（第一个是配额闸门的 Travel）。
- **两个决策槽**：槽 1 限定 `LearnTechnique`（候选 3），槽 2 限定 `GrantItem`（候选 3）。
- **两槽均 `AllowDecline = false`**（见下）——开局底盘明写为「2 个角色绑定功法 + 1 个选来的功法 + 1 件选来的法宝」，允许拒绝会让底盘残缺，且它是玩家的第一屏，不该以「什么都不选」开场。
- **`lifeSpanCost` 建议取 0（表值的条目级覆盖）。** 它是被强制进入的第一个事件，收寿元等于开局即扣，而玩家没有做出任何取舍。这落在「个别事件可在表值之外设更小的覆盖值」这条既有通道内，不需要新规则。

### 8. 决策槽的字段形态（可 derive 的落地面）

`[既有推演]`

模板侧（`AdventureEventData` 上 Research 专有的一格，`eventType != Research` 时恒空 → 加载期 `PushError`）：

```csharp
[GlobalClass] public partial class ResearchSlotSpec : Resource
{
    [Export] public DeckOperationKind[] AllowedOperations { get; set; }  // 该槽允许出哪几类操作，空 = 加载期 PushError
    [Export] public int  CandidateCount { get; set; } = 3;               // 候选数；实际不足则给几个算几个
    [Export] public bool AllowDecline   { get; set; } = true;            // 是否允许「什么都不做」
    [Export] public bool AllowRisk      { get; set; } = false;           // 是否可掷出走火入魔风险档候选
}
```

物化产物（进 `EventOption`，随批次落存档 —— 它属「物化产出的数值必进快照」那一侧）：

```csharp
public sealed record ResearchSlot(                      // 定稿：immutable
    int                                  SlotIndex,
    bool                                 AllowDecline,
    IReadOnlyList<ResearchCandidate>     Candidates);   // 已掷定，退出重进不重掷

public sealed record ResearchCandidate(
    DeckOperationKind Kind,      // LearnTechnique / UpgradeTechnique / ForgetTechnique /
                                 // RemoveLooseCard / GrantItem / Recuperate
    string            TargetId,  // 功法 Id / 卡牌 Id / 法宝 Id；Recuperate 为空串
    int               Amount,    // Recuperate 的回复量 / Upgrade 的目标层数；不适用时 -1
    int               ManaDelta, // 附带的 manaLimit 变动，取值 { -1, 0, +1 }（已掷定）
    bool              IsRisky);  // 面板上标注为风险档；结果已定但不预先展示
```

- **文本一律不进快照**（候选的显示名 / 描述由 UI 按 `TargetId` 现场取模板组装）——与「文本类字段一律留在模板侧、快照里一个字符串正文都不存」一致。
- **`ManaDelta` 已在物化时掷定并落存档**，这是「退出重进不能重掷」的落地点，也是风险档能够成立的技术前提。
- **`ResolveOutcome` 不新增结构**：resolver 把玩家所选候选翻译为 `DeckElements` / `AbilityElements` / `Elements` 三份 element，照常交给 `eventEnd` 的那一次 `TryApply`。

### 9. 代价：建议不另收资源代价

`[取向选择]`（推荐明确）

**建议：Research 的卡组操作不另收灵玉 / 其他资源，代价全部由 `lifeSpanCost` 的 Research 行承载**（该行已定为高于常规事件）。

- **它兑现的是既定的核心权衡**：`mana.md` 明写 Research「cost 侧天然是寿元 / 灵玉 ⇒ 形成『**花寿元换永久出牌力**』这条核心权衡」。再叠一层灵玉，权衡就从一条变成两条，而寿元那一条才是本作的时间压力主轴。
- **它保住「付不起」在事件选择面整体消失这条承重定案**：`selectCost` 无条件施加是全局规则；若槽内操作另收灵玉，就会出现「进来了但买不起任何一个操作」的死屏——而规则层刚刚把这类不可选态整体删掉。
- **想表达代价差异时用既有旋钮**：条目级的 `lifeSpanCost` 覆盖值（「深度闭关」耗更多寿元）。

---

## 具体形态（可 derive 的落地面）

汇总本草稿新增 / 改动的结构，供 `/derive-requirements` 消费：

| # | 落点 | 改动 |
|---|---|---|
| 1 | `systems/architecture.md`「共享核心类型」 | `ProfileChangeSpec` 增第四个平级列表 `DeckElements`；新增 `DeckChangeElement` / `DeckChangeOp` |
| 2 | 同上 | `CostKey` 增成员 `ManaLimit`（若采纳第 5 节） |
| 3 | `systems/services/profile-service.md` | `ResourceElements` 增 `ManaLimit` 一行（两修正列均 `null`）；`TryApply` 的失败语义表增 `DeckElements` 六条 |
| 4 | `systems/adventure-event/research/_index.md` + `common-properties.md` | 决策槽形态、操作清单六类、产出面收窄的一句话边界、走火入魔风险档 |
| 5 | `systems/services/future-event-service.md` | 物化时组装 `ResearchSlot[]` 与候选掷定（`RngStream.Reward`）；`EventOption` 物化字段清单 +1 格；`DrawPool<T>` 调用方 +1 |
| 6 | `systems/character-profile/mana.md` | 下降承载点定为 Research；分档表「压低」列补 Research 行 |
| 7 | `systems/character-profile/deck/_index.md` | 卡组变更的载体由「走 `ProfileChangeSpec`」具体化为 `DeckElements`；顺带答结「候选里出现已持有功法 → 排除」与「三选一 RNG 子流 → `Reward`」两条待决项 |
| 8 | `systems/balance.md` | 新增待定格：`Recuperate` 的回复量、走火入魔候选的出现权重、开局条目 `lifeSpanCost = 0` 的覆盖登记 |
| 9 | 存档 | `ProfileChangeSpec` 增列 ⇒ **bump schema 版本**；当前无线上存档 ⇒ 空迁移 |

## 后果

- **存档：** bump 一次 schema（空迁移）。`PastEventEntry` **不新增字段**——`AppliedChange` 随 `ProfileChangeSpec` 自动覆盖卡组变更。
- **内容层：** `content/cultivation-technique/` 从「阻于卡牌条目」变为「阻于卡牌条目 + 层数上限数值」——本草稿不解除它的阻塞，但把它需要的字段面（`Rarity` 参与加权、层数上限参与升阶候选过滤）确定下来。
- **UX：** 新增一种事件内面板（构筑面板），竖屏形态与战后奖励面板同构（候选纵向排列、点按选中、确认提交）；风险档需要一个明确的视觉标注 + 无 hover-only 的说明通道。归 `ux/screen-flow.md`，本草稿不展开。
- **`manaLimit` 不再单调不减**（若采纳第 5 节），既有的三条「不设护栏」决策由此获得真实消费方。
- **Research 从纯收益事件变为带取舍的事件**——这会改变它在批次里的被选率，须与事件池分布一并校准（`mana.md` 已标注的「战斗占比过高则成长停滞」是同一处校准）。

## 备选方案（已考虑并否决）

- **Research 只做一件事，不设面板（进入即执行一个固定操作）。** 否决：开局事件要求两次选择，单操作形态无法承载；且「玩家调整卡组」的语义核心就是**选择**，固定操作把它退化为一次自动结算。
- **把卡组变更塞进 `AbilityElements`（扩 `AbilityKind`）。** 否决理由见第 3 节表（层数无处安放、散牌多重集语义被吞、`Source` 无落点）。
- **走火入魔挂 Explore。** 否决：Explore 已收窄为纯元类型、无自己的产出口径，其可揭示的三类都不是走火入魔场景——这正是本问题被重新提出的原因。
- **走火入魔做成随机惩罚（进入 Research 即有概率扣上限）。** 否决：被施加的风险与本库「明知是死路仍然走」的自选取向不同族；且它会让玩家回避 Research，而 Research 是构筑的唯一落点。
- **Research 的操作另收灵玉。** 否决理由见第 9 节（双权衡冲淡寿元主轴 + 可能造成「进来了却什么都做不了」的死屏）。
- **为功法三选一新开一条 RNG 子流。** 否决：`Reward` 子流的用途（预先掷定候选 + 落存档 + 不重抽）与之完全同构，两者从不并发；新开子流换来零隔离收益。

## 与既有决策的张力

**一处，需要用户裁决：`ProfileChangeSpec` = 三个平级列表被明写为「（承重）」。**

- **冲突的是哪一条：** `systems/architecture.md`「共享核心类型」与 `systems/services/profile-service.md` 都把「`ProfileChangeSpec` = 三个平级只读列表」标为承重定案。本草稿第 3 节提议加第四个列表。
- **为什么需要它松动：** 那条承重定案的**论证依据恰好支持增列**——它的理由是「三者施加语义根本不同，压进一个带符号 `int` 是让类型说谎」。卡组变更的施加语义（带层数的替换 / 多重集增删 / 不走 pipeline / 无 `Source`）与现有三者**同样根本不同**，把它塞进任何一个现存列表，正是那条定案要防的「让类型说谎」。**故这不是推翻它，而是按它自己的判据再切一刀。**
- **松动的代价：** ① bump 一次存档 schema（当前无线上存档，空迁移，代价接近零）；② 「三个列表」这个数字在多处文档中被复述，需要一并改写（`architecture.md` / `profile-service.md` / `adventure-event/common-properties.md` 的 `selectCost` 段各一处）；③ `selectCost` 的「恒为空」不变式从一条变成两条（`AbilityElements` + `DeckElements`），断言与加载期校验各多一条。
- **不松动时的替代方案：** 扩 `AbilityKind` 加 `Technique`（第 3 节已列出三条否决理由）；或**把卡组状态整个移出 `ProfileChangeSpec`**，另设 `DeckManager.ApplyDeckChange(...)` 单独提交——但那会直接打穿「一个事件 = 一次事务 = 一个存档点」与「档案写入的唯一入口」两条更重的承重定案，代价远高于增一列。**故推荐增列。**

**另需注意（不是冲突，是一处需同步改写的表述）：** `mana.md` 的推拉分档表目前「压低」列**全部为空**（Research 行也是「—」）。若采纳第 5 节，该表的 Research 行须补上「罕见 −1（走火入魔风险档）」。

## 前置依赖

- **`CardData` 的完整字段清单与 starter deck** 未定 ⇒ 功法的候选池当前**内容条目为零**，本方案的抽取链无法在 ch1 数值标杆专场之前被真实验证。（归 `systems/balance.md`。）
- **功法的规模参数**（一门功法含几张牌、**层数上限**、每层替换幅度）未定 ⇒ `UpgradeTechnique` 的「未达层数上限」过滤条件有形态无取值；`ResearchCandidate.Amount` 的取值域待它答定。（归 ch1 数值标杆专场。）
- **`lifeSpanCost` 定价表的具体取值**未定 ⇒ 「闭关比常规贵」有方向无数字，第 9 节「代价全部由寿元承载」的强度无法校准。
- **批次规模区间两端由什么驱动**未定 ⇒ 不影响本方案（Research 不占特殊槽位），但影响 Research 在一批里的实际出现频率。
- **`EventOption` 的完整物化字段清单**未定 ⇒ 第 8 节的 `ResearchSlot[]` 是往那份清单里加的第一格；它与该清单的其余分叉不冲突（纯加法），但最终定稿时应与之一并评审。
- **`cost element 清单`**（`CostKey` 其余成员）未定 ⇒ `ManaLimit` 一行是往那张表里加的一行，同属纯加法。

## 仍需用户决定 → **已全部裁决（2026-08-17）**

> **定案：五项一律取推荐项（选项 A）。** 即：
> ① **增列 `DeckElements`** —— 用户同时定案「`ProfileChangeSpec` 那条定案的判据本就是『按施加语义分列』」，故承重措辞由「三个平级列表」改写为「**逐条按施加语义分列**」，本次连同 Travel 草稿的 `StatusChanges` 一并**三 → 五**。张力节所述的「需要松动一条承重措辞」**已获裁决通过**。
> ② `manaLimit` 下降**改挂 Research 的玩家自选风险档**（成功 +1 / 失败 −1，物化时掷定并落存档）；`mana.md` 分档表的「压低」列补 Research 行。
> ③ **允许** Research 回复 `lifeTotal`。
> ④ 常态条目 `AllowDecline` 默认 **`true`**，开局条目显式 `false`。
> ⑤ 三条顺带项**一并采纳**：三选一复用 `RngStream.Reward` · 候选排除已持有功法 · 卡组弃空不做内容侧回避。
>
> 下列原文保留为选项与理由的溯源。

1. **【最重要】是否允许 `ProfileChangeSpec` 增第四个平级列表 `DeckElements`（第 3 节 + 张力节）。**
   - 选项 A（**推荐**）：增列。代价 = 一次空迁移 + 三处表述改写；收益 = 卡组变更有了语义诚实的载体，`deck/_index.md` 那句「走 `ProfileChangeSpec` → `TryApply`」第一次真正落地。
   - 选项 B：扩 `AbilityKind` 加 `Technique`。代价 = `AbilityChangeElement` 多一个对 Power / Item 恒无意义的 `Tier` 格 + 散牌的多重集语义仍无解（需再想第二条路）。
   - 选项 C：卡组状态另走一条提交路径。**不建议**——打穿两条更重的承重定案。

2. **`manaLimit` 下降的承载点（第 5 节）。**
   - 选项 A（**推荐**）：改挂 Research，做成玩家自选的风险档。收益 = 给 Research 补上唯一缺失的张力，三条「不设护栏」决策获得消费方。代价 = `CostKey` 多一行、内容侧要设计风险档条目、`mana.md` 分档表要改。
   - 选项 B：接受「本作没有 `manaLimit` 下降」（单调不减）。收益 = 结构最简，不必登记 `ManaLimit` 一行。代价 = 三条既有决策成为无消费方的决策债，且 Research 保持纯收益事件。
   - **若选 B，第 5 节整节作废，其余各节不受影响**（它们互相独立）。

3. **是否允许 Research 回复 `lifeTotal`（第 4 节）。**
   - 选项 A（**推荐**）：允许，与升阶在同一决策槽内并列（StS 篝火形状）。
   - 选项 B：不允许，`lifeTotal` 回复另找承载（但「休养并入闭关」是既定决策，选 B 需同时回答休养的产出去哪）。

4. **常态 Research 条目的 `AllowDecline` 默认值（第 1 / 7 节）。**
   - 选项 A（**推荐**）：默认 `true`（可拒绝，零额外代价，`selectCost` 不退），开局条目显式填 `false`。理由 = 与置换面板的「拒绝零代价」同构，且避免「只剩一门功法却被迫弃置」这类内容侧死结。
   - 选项 B：默认 `false`（进来就必须做点什么）。张力更强，但需要内容侧逐条保证候选恒可执行。

5. **顺带项（不在本次锁定范围，但本草稿给出了答案，请一并裁决是否采纳）：**
   - **功法 / 法宝三选一的 RNG 子流** → 建议复用 `RngStream.Reward`，不新开（`deck/_index.md` 待决项）。
   - **候选里出现已持有功法怎么办** → 建议**排除**（与 `GrantPoolPicker` 的「排除已持有」同构），不折算为升阶（折算会让「学新」与「升阶」两个操作的边界模糊）（`deck/_index.md` 待决项）。
   - **卡组被弃空的内容侧态度** → 建议**不做内容侧回避**（规则层已由疲劳规则表达后果，且「输是正常出口」是既定取向）；`AllowDecline = true` 已足以让玩家不被迫弃空（`deck/_index.md` 待决项）。
