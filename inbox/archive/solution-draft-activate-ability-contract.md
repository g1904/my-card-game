---
type: solution-draft
date: 2026-08-26
question: 启动式异能没有服务侧 API 方法 —— `ActivateAbility` 的完整签名、代价形态、每场次数限制与拒绝语义待定。
source: open-questions/05-service-contracts.md → 「启动式异能没有 API 方法（08-25f 新增）」
targets: systems/services/combat-service.md（API 面 · 决策点清单 · 事件面）· systems/character-profile/deck/common-properties.md（`AbilityData` 字段与加载期校验）· ux/combat-ux.md（灰态与长按原因，仅一句回链）
status: distilled
reviewed: 2026-08-26 —— 批量评审裁决：启动代价取选项 A（首版只开 `ManaCost`，不加 `ProfileCost`）；张力 1 判为字段形态的缺口、取拆格方案；张力 2 按分工读法；张力 3 加载期校验放宽照采纳；战斗内拒绝走 `COMBAT_` 分区普通键。连带：正文第 2 节的三格表、三选一校验、`ActivationCostUnaffordable` 与 `COMBAT_ABILITY_COST_UNAFFORDABLE` 随裁决 A 全部撤回，提炼时按两格 / 二选一 / 两个拒绝成员 / 两条翻译键落笔。
distilled-to: handoffs/2026-08-26d-activate-ability-contract.md
---

# 方案草稿 — `ActivateAbility` 的服务契约

## 问题

决策点 **D2** 明写「一次出牌 / **启动** / 用道具结算完毕」，栈条目 `kind` 明写 `ActivatedAbility`，`CombatActionKind` 却只有 `PlayCard / UseItem / EndTurn`，combat-service 的 API 面上也只有 `PlayCard` / `UseItem` / `ProvideTarget` / `EndTurn`。**`UseItem` 已于 08-25 补齐，`ActivateAbility` 是同一档的真实空缺。**

UI 宿主已定（长按 `Power` 图标升起的 bottom sheet 内的启动键，`ADR-0099` / `ux/combat-ux.md`），服务侧仍缺：**方法签名 · 启动代价落在哪一列 · 每场次数限制的存档表达 · 拒绝语义的完整枚举 · 与栈 / `ActionResult` / `CombatFeedEntry` / 决策点的关系**。空缺的直接后果是这条动作无法被 `/derive-requirements` 消费，而它是 mana 的第二个花费去向（`ADR-0019` 推论 ③）——缺它，战场就退回纯被动区。

## 约束（来自既有设计）

- **窗口与出牌完全相同**：自己回合的行动阶段、栈为空时（`terminology.md`「出牌时机（唯一）」· `ADR-0019` · `ADR-0039`）。启动式异能**不引入交互**，`RunCombatAsync` 的状态机形状不变。
- **启动后压栈**，`StackEntryKind.ActivatedAbility` 已在栈条目枚举内（`combat-service.md`「栈条目」）。
- **`ActivationCost` 当前形态 = `ProfileChangeSpec?`，仅 `Activated` 时非空**，加载期校验「零费启动式异能会造成无限循环 → `PushError`」（`deck/common-properties.md`）。
- **`Power` 无 mana 费用字段，「启动式异能的启动费另算」**（`power/_index.md`）。
- **`ActivationCost` 已付但 fizzle 的启动式不吃配额，成本仍不退**；**计数只在弹栈结算成功那一刻 +1**，`BumpCounter` / `BumpCardCounter` 调用点唯一（`combat-service.md`「管理器」· `handoffs/2026-08-22-combat-runtime-counter-persistence.md`）。
- **配额闸门查两次**：宣告 / 触发注册时一次、结算时一次；不为配额引入「已预留」这类第二份运行态。
- **`counters` 键空间已定**：`<abilityId>[#<子名>]`，值域 `>= 0`、为 0 不写入；落战场条目的 `counters`（有过期时刻）或 `CardInstanceSave.Counters`（随牌本体）。
- **`ActionResult` 是玩家动作的统一返回类型**，业务失败绝不抛（`ADR-0087` · 架构总则 1 形态 A / 总则 2 三分失败语义）。
- **`ProfileChangeSpec` / `CostKey` 全 16 行**已与两层 Profile 字段满射，**其中没有 `CurrentMana`**（只有 `ManaLimit`）——战斗内的 `currentMana` 住在 `activeCombat.sides[]`，不是 Profile 字段。
- **本地业务拒绝没有后端 `code`，一律走所属分区普通键、不占 `ERR_` 前缀**（`ux/error-and-blocking-ux.md` 禁令一节）。
- **灰显即答案，不做点击弹提示**；不可用项灰显 + 长按给原因；弹层与随身抽屉同规格禁用（敌人回合 / 结算中 / 选目标态）（`ux/combat-ux.md` · `ADR-0099`）。
- **决策点 `ADR-0036` / 存档点永不回退 `ADR-0032`**：新增决策点须有「产生了重算不出来的新状态且流程在此停下等玩家输入」的理由。

## 建议方案

### 1. 方法签名 —— 寻址战场条目，不是寻址 `Power`

`[既有推演]`

```csharp
// combat-service 的 API 面，形态 A（不跨边界、不带 Async）
ActionResult ActivateAbility(string entryId, string abilityId, IReadOnlyList<TargetRef> targets);
```

- **`entryId`（战场条目 id）而非 `powerId`。** 启动式异能不是 `Power` 专属：`PowerData.Abilities` 与 `CardData.Abilities` 取值域相同（静止式 / 启动式 / 触发式皆可），而**阵法（`Enchantment`）是留场永久物**，「留场 + 每回合花 mana 启动」正是 `ADR-0019` 推论 ③ 点名的形态。按 `powerId` 寻址会把阵法侧排除在外，日后必然再开第二个方法。`entryId` 是战场条目**唯一 id、且已是目标引用的锚点**，与 `TargetRef.EntryId` / `pending` / `CauseEntryId` 同一命名空间，不新增寻址概念。
- **`abilityId` 必须显式给。** 一个条目可挂多个异能（`PowerData.Abilities` 明写可含多个，配额也正因此挂在**某一个异能**上而非条目上）——只给 `entryId` 表达不出「启动的是哪一条」。
- **`targets` 与 `PlayCard` 逐字同构**：长度必须等于该效果的 `TargetSlots` 长度，顺序即 `slotIndex`，无目标槽位写 `TargetRef(None, _, string.Empty)`。**玩家主动发起的动作，槽位一律在发起前由 UI 一次收齐、入栈即 `targetState = Resolved`**——这条既定纪律的判据是「玩家主动出牌」而非「打的是不是牌」，启动同属主动动作，故适用。挂起态仍只来自结算中途回头问的那些。
- **不叫 `UseAbility` / `Activate`。** `activated ability` 的既定中译是「启动式异能」，动词取「启动」= `Activate`；`Use` 已被道具占用（`UseItem`），两个动词分给两条不同的来源路径，读签名即知走的是哪一条。
- **敌人侧不经本方法。** 与出牌 / 用道具同款：EnemyManager 在自己回合内自行决定启动，走内部路径、**不产生 `ActionResult`**（没有调用方），照常广播 `CombatFeedEntry`。这与「AI 决策是局面 + `combat` 子流的纯函数、敌人回合内部不落决策点」完全一致，**不为敌人另开 API**。

### 2. 启动代价 —— mana 是独立一格，`ProfileChangeSpec` 表达不了它

`[既有推演]`（这是本稿最实质的一处发现）

**`ActivationCost : ProfileChangeSpec?` 的现行形态无法承载 mana 费用。** `ProfileChangeSpec` 的资源列以 `CostKey` 索引，而 `CostKey` 全 16 行**与两层 Profile 字段双向满射**，其中只有 `ManaLimit`、**没有 `CurrentMana`**——战斗内的 `currentMana` 是 `activeCombat.sides[]` 上的回合内运行态，明写「战斗外无意义」，它**不是 Profile 字段**，也不该为它去开一个 `CostKey` 成员（那等于把回合内运行态塞进 Profile 写入通道，并要求它每次启动都走一次 `TryApply` 与云端同步）。

而 `ADR-0019` 推论 ③ 的整条价值主张就是「**启动式异能给 mana 第二个花费去向**」。两者相加 ⇒ **现行字段形态与既定意图之间有一处结构缺口**。建议把 `AbilityData` 的代价面拆成三格：

| 字段 | 类型 | 语义 |
|---|---|---|
| `ManaCost` | `int`（`>= 0`） | **战斗内代价**，由 combat-service 直接扣 `sides[Character].currentMana`，**不经 `ProfileManager`**（它不是 Profile 字段） |
| `ProfileCost` | `ProfileChangeSpec?` | Profile 侧代价（灵石 / 寿元 / 资源列）。非空时**即时经 `ProfileManager.TryApply` 提交**，与古宝次数、法宝 `Charges` 同款纪律——「事件内部的主动消费即时提交」。**开不开这一格见「仍需用户决定」** |
| `MaxActivationsPerCombat` | `int`（`-1` = 不限） | 本场配额，见下一节 |

- **`ManaCost` 是独立整数格、不塞进 `ProfileChangeSpec`。** 塞进去要么伪造一个 `CostKey.CurrentMana`（污染满射不变式与 `ResourceElements` 表），要么让 spec 承载两族语义（Profile 写入 / 战斗内运行态），此后每次读 spec 都要先分辨它属于哪一族——与「`KeywordRef.Amount` 不进 `counters`」被否决的理由逐字同构。
- **扣费时机 = 压栈那一刻**（与出牌的费用支付同时机），**fizzle 不退**（既定纪律，`ActivationCost` 已付但 fizzle 的启动式成本不退）。
- **加载期校验改写**（替换现行「`Activated` ⇒ `ActivationCost` 非空」一行）：
  `AbilityKind == Activated` 时，**`ManaCost >= 1` · `ProfileCost` 非空 · `MaxActivationsPerCombat >= 1` 三者至少成立其一**，否则 `PushError` + `Id` + `.tres` 路径。
  理由不变还是那条——**零费且无配额的启动式异能会造成无限循环**（栈为空时可反复启动）；这条校验要的是「存在一条有限性闸」，三格任一都足以充当，写成三选一比强绑 `ActivationCost` 非空更准确，也不再逼一条纯配额型异能（「每场一次、免费」）去编造一个假费用。

### 3. 每场次数限制 —— 存档一格不加，复用 `entry.counters`

`[既有推演]`

- **落点 = 战场条目的 `counters[<abilityId>]`**（默认计数器，无 `#` 段）。既定键约定第一句就是「该异能的默认计数器（**触发 / 启动次数**）」，键主体取 `AbilityData.Id` 的理由（`PowerData.Abilities` 可含多个异能、配额天然挂在某一条上）**正是为启动式配额准备的**。`ActiveCombat` **一格不加**。
- **配额值 `MaxActivationsPerCombat` 是 `AbilityData` 上的显式内容字段**，不是效果定义内部的一个条件。判据是**可预判性**：UI 必须在点下去之前就把不可启动的项灰显（「灰显即答案，不做点击弹提示」），埋在效果条件里的配额无法被机械预读，UI 只能让玩家点了才被拒——那正是 `ux/combat-ux.md` 为随身抽屉明确否决的形态。
- **既定的两次闸门查询原样成立**：第一次在 `ActivateAbility` 内（宣告时，读到的是旧值）→ 拒绝理由 `AbilityQuotaExceeded`；第二次在 StackManager 的结算收口回调（读到已 +1 的值，拦住同一结算链内的第二条）。**计数仍只在弹栈结算成功那一刻 `BumpCounter(entryId, abilityId, +1)`**，不在压栈处、不在付费处——`handoffs/2026-08-22` 已明确推翻过「付费成功后 +1」的写法，本稿不重开。
- **清理 = 无。** 条目离场 `counters` 随之消失；`activeCombat` 在 `eventEnd` 整块置空 ⇒ **本场配额随战斗自然清零，轮回结束时不需要任何额外清理动作**，与「有过期时刻的计数落战场条目」这条既定归属判据自洽。
- **跨场的「本轮回限 N 次」不在本稿范围**：那没有过期时刻，按既定判据不该落 `entry.counters`；当前无此需求，**不预铺**。

### 4. 拒绝语义 —— 三条通用 + 三条新增，全部走 `ActionResult`

`[既有推演]` + `[通行做法]`

```csharp
public enum CombatActionKind { PlayCard, UseItem, ActivateAbility, EndTurn }   // 新增一个成员

public enum ActionRejection
{ None, NotYourTurn, NotActionStep, StackNotEmpty, InsufficientMana, IllegalTarget, CardNotInHand,
  ItemNotAvailable, ItemChargesExhausted, ItemUsesThisCombatExceeded,
  AbilityNotAvailable, AbilityQuotaExceeded, ActivationCostUnaffordable }     // 新增三个成员
```

| 情形 | 拒绝理由 | 备注 |
|---|---|---|
| 不是自己回合 | `NotYourTurn` | 通用三条，与出牌 / 用道具完全同窗口 |
| 不在行动阶段 | `NotActionStep` | 同上 |
| 栈非空 | `StackNotEmpty` | 同上 |
| `entryId` 不在战场 / `ownerSide != Character` / `abilityId` 不挂在该条目 / `AbilityKind != Activated` | `AbilityNotAvailable` | **合并为一条**，与 `ItemNotAvailable` 同款粒度。四种情形对玩家是同一句话（「这个不能启动」），拆成四条只增加调用方的分支而不增加任何可呈现的差别 |
| `currentMana < ManaCost` | `InsufficientMana` | 复用既有成员，不另立 |
| `counters[abilityId] >= MaxActivationsPerCombat` | `AbilityQuotaExceeded` | 对位 `ItemUsesThisCombatExceeded` |
| `ProfileCost` 非空且 `CanAfford` 不过 | `ActivationCostUnaffordable` | 复用 `ProfileManager.CanAfford` / `ApplyResult.MissingElement` 做灰显与提示 |
| 目标非法 / 槽位数不匹配 | `IllegalTarget` | 与 `PlayCard` 同 |

- **`abilityId` 经 `ContentRegistry` 解析不到 → `PushError` + 抛，不是业务拒绝。** 这是全库既定分档（读档校验 ② 同款：真悬空 = 内容被删或键被写错）。**解析得到但不挂在该条目 / 不是启动式 → 业务拒绝**（UI 可能持有一份刚被移除条目的陈旧 id，属预期内）。这条分界必须写明，否则两侧会各写一半。
- **`ActionRejection` 不落存档，故追加成员无迁移、无冻结约束**（与 `CostKey` / `StatKey` 的成员名冻结纪律不同档——那两个随 `PastEventEntry` 逐字序列化）。
- **文案键走 `COMBAT_` 分区普通键，绝不占 `ERR_` 前缀。** 战斗内拒绝是**本地业务拒绝、没有后端 `code`**，与「储物袋里『这件道具须在战斗中使用』→ `PROFILE_ITEM_COMBAT_ONLY`」逐字同构；手写一个 `ERR_*` 键会与日后新增的后端 `code` 撞键（`ADR-0053` 的禁令）。形态：`COMBAT_ABILITY_UNAVAILABLE` · `COMBAT_ABILITY_QUOTA_EXCEEDED` · `COMBAT_ABILITY_COST_UNAFFORDABLE` · `COMBAT_INSUFFICIENT_MANA`（后者出牌 / 用道具 / 启动共用一条）。**`ErrorText.For` 的三参形态与 `reasonKey` 机制在这里完全不适用**——那条链路服务的是后端 `OpError`。

### 5. 灰态预判 vs 调用后拒绝的分工

`[既有推演]`

- **UI 侧预判、灰显、长按给原因；服务侧仍全量重校验。** 这不是重复：**服务是规则权威、绝不信任 UI**（`ProvideTarget` 已写明「服务端仍以 `LegalTargets` 为准校验」），而 UI 不预判就只能让玩家点了才被拒，撞上「敌人回合 / 结算中：角标置灰、抽屉入口禁用 —— 使用窗口是全局规则，UI 应把它表达为可供性的有无，而不是让玩家点了才被拒」这条既定要求。
- **预判所需数据须由服务算好交给 UI，不让 UI 自己重演规则。** `CombatSnapshot` 的 `BattlefieldEntryView` 上加一格：

  ```csharp
  public readonly record struct AbilityAvailability(
      string          AbilityId,
      int             ManaCost,
      int             RemainingUses,   // -1 = 不限
      bool            CanActivate,
      ActionRejection Reason);         // CanActivate == true 时为 None
  // BattlefieldEntryView 上：IReadOnlyList<AbilityAvailability> ActivatableAbilities;（无启动式异能 ⇒ 空列表）
  ```
  理由：配额计数活在 `entry.counters` 里，UI 拿不到；而让 UI 自行按 `ContentRegistry` + snapshot 重算窗口 / mana / 配额三条规则，等于把规则实现成两份——正是本库反复否决的第二权威。`CombatSnapshot` 本就**按变更广播 + 缓存**（不是每次访问现组装），多这一格不落在热路径的分配面上。
- **拒绝**（真发生时）**不弹 toast**：`ActionResult.Accepted == false` 时 UI 只需回到原态；玩家看得见的解释由灰态 + 长按承担。这与选目标态「不做『点非法目标弹提示』」同一条纪律。

### 6. 栈 / `ActionResult` / `CombatFeedEntry` / 决策点

`[既有推演]`

- **入栈**：`StackEntryKind.ActivatedAbility`（枚举成员已存在，**不新增**）。`controllerSide = Character`、`sourceEntryId = entryId`（载体条目）、`abilityId = abilityId`、`sourceInstanceId` = 该条目的 `sourceInstanceId`（阵法有值、`Power` 为空）、`chosenTargets` = 传入的列表、`targetState = Resolved`。
- **`ActionResult`**：`Kind = ActivateAbility`、**`SubjectId = entryId`**。取 `entryId` 而非 `abilityId`：它是**唯一寻址**（同一条 `AbilityData` 可同时挂在多个条目上，`abilityId` 定位不到是哪一个），且与 `CauseEntryId` / `TargetRef.EntryId` 同一命名空间；调用方本就知道自己启动的是哪条异能，`ActionResult` 是**同一次动作的回执**，不必把请求参数原样回传。`ManaSpent` 填 `ManaCost`；`CharacterMomentum` / `EnemyMomentum` 是**本次动作链路（含连锁触发）的汇总值**，与 `PlayCard` 同粒度；`AwaitingTarget` / `StackDepth` 语义不变（结算中途回头问目标时为 true）。
- **`CombatFeedEntry`**：新增一个 `CombatFeedKind.AbilityActivation`。现有 `AbilityTrigger` 的语义是**触发式**异能，把启动塞进去，战报的因果树就分不清「**我启动了** X」与「X **被触发了**」——而战报的全部价值就是「谁引发了谁」可读。条目取值：`EntryId = stackEntryId` · `CauseEntryId = string.Empty`（玩家主动动作是因果树的根，与 `CardPlay` 同）· `SourceId = abilityId` · `SourceInstanceId` = 载体条目的 `sourceInstanceId`（`Power` 载体时为空）· `FizzledSlots` 照常。
- **决策点：不加行，D0–D7 清单原样。** 判据是「状态机停下来等玩家输入」——启动的结算与出牌完全同形，**`D2`（一次出牌 / **启动** / 用道具结算完毕）本就点名了它**；结算中途要目标则落既有的 `D4`。`ADR-0036` / `ADR-0032` 不受触动，密度口径（≈31 点 / 场）也不变——启动**替代**一次出牌占用行动阶段的一个动作位，不是额外叠加。
- **`ProfileCost` 非空时的即时 `TryApply` 不新增存档点类型**（既定：事件内的即时提交走既有通道）。

## 具体形态（可 derive 的落地面）

```csharp
// ── combat-service API 面新增一行 ────────────────────────────────
// | 启动异能 | A | ActionResult ActivateAbility(string entryId, string abilityId,
//                                              IReadOnlyList<TargetRef> targets)
//   失败语义：业务失败（非自己回合 / 非行动阶段 / 栈非空 / mana 不足 / 条目或异能不可启动 /
//             本场配额用尽 / Profile 侧代价付不起 / 目标非法）→ ActionResult，绝不抛；
//             abilityId 经 ContentRegistry 解析不到 → PushError + 抛（坏数据档）

// ── AbilityData（deck/common-properties.md）代价面改写 ────────────
//   Id / Kind / ManaCost(int, >=0) / ProfileCost(ProfileChangeSpec?) /
//   MaxActivationsPerCombat(int, -1 = 不限) / TriggerWhen(仅 Triggered) / Effect / CounterNames
//   加载期校验：Kind == Activated ⇒ ManaCost >= 1 || ProfileCost != null
//                                   || MaxActivationsPerCombat >= 1，否则 PushError

public enum CombatActionKind { PlayCard, UseItem, ActivateAbility, EndTurn }
public enum CombatFeedKind   { CardPlay, AbilityActivation, AbilityTrigger, Fatigue }

// ActionRejection 追加：AbilityNotAvailable, AbilityQuotaExceeded, ActivationCostUnaffordable

public readonly record struct AbilityAvailability(
    string AbilityId, int ManaCost, int RemainingUses, bool CanActivate, ActionRejection Reason);
// BattlefieldEntryView 追加：IReadOnlyList<AbilityAvailability> ActivatableAbilities
```

**存档面：零新增字段。** 配额计数落既有 `entry.counters[<abilityId>]`（值域 `>= 0`、为 0 不写入、读档校验 ②⑤ 原样覆盖），`ActiveCombat` schema 不动，**空迁移**。

**翻译键（`res://text/combat.csv`）：** `COMBAT_ABILITY_UNAVAILABLE` · `COMBAT_ABILITY_QUOTA_EXCEEDED` · `COMBAT_ABILITY_COST_UNAFFORDABLE`（`COMBAT_INSUFFICIENT_MANA` 与出牌 / 用道具共用）。

## 后果

- `systems/services/combat-service.md`：API 面表 +1 行；`CombatActionKind` / `ActionRejection` / `CombatFeedKind` 三个枚举各有增补；`CombatSnapshot` 的 `BattlefieldEntryView` 增一格；栈条目取值填法补一段；决策点清单**不改**。
- `systems/character-profile/deck/common-properties.md`：`AbilityData` 代价面由一格拆为三格，加载期校验表改一行。
- `systems/character-profile/power/_index.md`：「启动式异能的启动费另算」可补一句回链，不复述形态。
- `ux/combat-ux.md`：弹层内启动键的灰态与长按原因回链本方案的 `AbilityAvailability`，**不复述字段面**。
- **存档 schema 与迁移：无。** 运行期计数落既有 `counters`。
- **敌人侧无 API 变更**，但 EnemyManager 的兜底策略需把「启动场上条目的启动式异能」纳入可选行动（AI 形态本就待定，见下方前置依赖）。

## 备选方案（已考虑并否决）

- **`ActivateAbility(string powerId, ...)`（只寻址 `Power`）** — 排除阵法侧的启动式异能，而那正是 `ADR-0019` 点名的样板形态；日后必然再开第二个方法。
- **把 mana 费用塞进 `ActivationCost : ProfileChangeSpec`（新开 `CostKey.CurrentMana`）** — 污染「`CostKey` 与两层 Profile 字段双向满射」这条启动期断言，并把回合内运行态推上 Profile 写入与云端同步通道。
- **配额只写在效果定义的条件里、`AbilityData` 不加字段** — UI 无法机械预读，灰态判据落空，只能「点了才被拒」。
- **把四种「不可启动」拆成四个 `ActionRejection` 成员** — 对玩家是同一句话，只增加调用方分支。
- **启动复用 `CombatFeedKind.AbilityTrigger`** — 战报因果树读不出「我启动的」与「被触发的」之别。
- **为启动新增一个决策点** — 与出牌同形，D2 已覆盖；无重算不出来的新状态。
- **`SubjectId = abilityId`** — 同一 `AbilityData` 可挂多个条目，定位不到是哪一个。
- **拒绝时弹 toast 说明原因** — 与「灰显即答案，不做点击弹提示」正面冲突。

## 与既有决策的张力

1. **`AbilityData.ActivationCost : ProfileChangeSpec?` 与「启动式异能给 mana 第二个花费去向」两条既定表述实际互斥**（`CostKey` 无 `CurrentMana`，`currentMana` 不是 Profile 字段）。本稿判为**字段形态的缺口而非意图冲突**，取拆格方案；若用户判为「启动费本就不该是 mana」，则第 2 节整节需重写，且 `ADR-0019` 推论 ③ 要同批修订。**这一处必须由用户点头，不宜由推演直接落笔。**
   **→ 已裁决（2026-08-26 · 批量评审）：按本稿的读法处理 —— 判为字段形态的缺口，取拆格方案**（`ManaCost` 独立整数格，由 combat-service 直接扣、不经 `ProfileManager`）。`ADR-0019` 推论 ③「启动式异能给 mana 第二个花费去向」**原样成立，无需修订**，第 2 节不必重写。
2. **「内容侧纪律：『每场限 N 次』类异能必须在效果定义里引用自己 `AbilityData` 的稳定 `Id` 作键」** 与本稿的显式 `MaxActivationsPerCombat` 字段并存。本稿的读法是二者分工而非冲突——**字段承载启动侧的可预判配额闸（触发式异能没有 UI 可灰）**，效果侧的键引用纪律照旧覆盖触发式与效果内部条件，**两者写的是同一个 `counters` 键**。若用户认为该纪律意在排他，则本稿第 3 节的字段方案须撤回，代价是灰态预判失去数据源。
3. **加载期校验「`Activated` ⇒ `ActivationCost` 非空」被改写为三选一。** 这是对既有校验行的**放宽**（允许零 mana + 有配额的启动式异能）；防无限循环的目的不变，但判据从「有费用」变成「有有限性闸」。

## 前置依赖

- **阵法（`Enchantment`）上启动式异能的 UI 宿主未定。** `ux/combat-ux.md` / `ADR-0099` 只定了 `Power` 那一半（长按弹层内的启动键）。本方案的服务契约不依赖它（`entryId` 寻址与宿主无关），但**没有宿主就没有玩家可发起的路径**，derive 出的验收标准会缺一半。归已排期的竖屏分区专场。
- **敌人 AI 的决策形态未定**（`combat-service.md` 待决问题）。「兜底策略如何权衡启动 vs 出牌」随该问题一并落定，本稿不预设。
- **`BattlefieldEntryView` 的完整字段面此前未成文**，本稿只增一格；若该视图在别处被一次性定稿，须与本格合并。
- **`MaxActivationsPerCombat` 的取值范围与内容侧编排口径**归 `systems/balance.md` 的统计校准，本稿不给数字。

## 仍需用户决定

> **全部裁决完毕（2026-08-26 · 批量评审）。** 裁决见下方 `→ 已裁决` 行。
>
> 同批**按标准默认直接采纳、未单独出题**的三项（依据充分，不构成取向）：
> ① 战斗内拒绝走 `COMBAT_` 分区普通键，**不占 `ERR_` 前缀、不走 `ErrorText.For` 三参**（`ADR-0053` 禁令——`ERR_*` 由后端 `code` 机械变换，而战斗内拒绝是本地业务拒绝、无后端 `code`）；
> ② 张力 2 按**分工**读法处理（`MaxActivationsPerCombat` 管启动侧可预判闸、键引用纪律管触发式与效果内部条件，两者写同一 `counters` 键）——排他读法会让灰态预判失去数据源；
> ③ 张力 3 的加载期校验放宽（判据由「有费用」改为「有有限性闸」）照本稿采纳。

- **启动代价是否允许 Profile 侧一列（`ProfileCost`），还是首版收窄为纯 `ManaCost`？**
  - **选项 A（推荐 · 首版只开 `ManaCost`，`ProfileCost` 不加）** — 战斗内代价面收敛为单一刻度 mana，读者与内容作者不必区分「哪些启动会即时写 Profile」；避免每次启动都产生一次 `TryApply` 与一次上行 diff（战斗内已有 D0–D6 六到七次决策点写入）；也天然避开「一条启动式异能间接成为回寿 / 产灵石通道」这类与 `PowerData` 不得含 `LifeSpan` 产出同源的担忧。**代价**：「花寿元换一次强力启动」这类设计空间关闭，日后要开需 bump `AbilityData` 字段（无存档迁移，成本低）。
  - **选项 B（保留 `ProfileCost`，与 `UseItem` 对齐）** — 古宝次数已即时写 `PlayerProfile`，通道现成、纪律现成（「事件内部的主动消费即时提交」），设计空间即刻打开。**代价**：多一条战斗内写 Profile 的路径，且必须同批回答「`ProfileCost` 允许哪些 `CostKey`」（否则内容侧一条 `.tres` 就能开出回寿口子），本稿无法替用户圈定这张白名单。
  - **理由**：这是产品取向（战斗内代价面的宽窄）而非工程最优；两条都自洽，差别在于打开多大的内容设计空间与随之而来的护栏工作量。推荐 A 的判据是本库反复出现的克制取向——**「加它的成本此刻不为零、不加的成本此刻也不为零」时取更窄的那一侧**，且本例中日后补开是零迁移。
  - **→ 已裁决（2026-08-26 · 批量评审）：A —— 首版只开 `ManaCost`，`ProfileCost` 不加。** 连带确定：**不需要**同批圈定「`ProfileCost` 允许哪些 `CostKey`」的白名单；日后补开是加字段、零存档迁移。
