# `ActivateAbility` 的服务契约

- id: 2026-08-26d-activate-ability-contract
- date: 2026-08-26
- topic: systems/services/combat-service.md · systems/character-profile/deck/common-properties.md · systems/character-profile/power/_index.md · ux/combat-ux.md
- status: distilled
- distilled-to: `systems/services/combat-service.md`、`systems/character-profile/deck/common-properties.md`、`systems/character-profile/power/_index.md`、`ux/combat-ux.md`

## Intent（distilled）

### 起因：启动式异能有窗口、有栈条目、有决策点，唯独没有 API 方法

决策点 **D2** 明写「一次出牌 / **启动** / 用道具结算完毕」，栈条目 `kind` 明写 `ActivatedAbility`，UI 宿主也已定（长按 `Power` 图标升起的弹层内的启动键）；而 `CombatActionKind` 只有 `PlayCard / UseItem / EndTurn`，combat-service 的 API 面上也只有 `PlayCard` / `UseItem` / `ProvideTarget` / `EndTurn`。缺口的直接后果是这条动作无法被消费：启动式异能是 mana 的第二个花费去向，缺它战场就退回纯被动区。

本次一次性给出：方法签名 · 启动代价的字段形态 · 每场配额的存档表达 · 拒绝语义的完整枚举 · 与栈 / `ActionResult` / `CombatFeedEntry` / 决策点 / 灰态预判的关系。

### 1. 方法签名 —— 寻址战场条目，不是寻址 `Power`

```csharp
ActionResult ActivateAbility(string entryId, string abilityId, IReadOnlyList<TargetRef> targets);
```

- **`entryId`（战场条目 id）而非 `powerId`。** 启动式异能不是 `Power` 专属：`PowerData.Abilities` 与 `CardData.Abilities` 取值域相同，而**阵法（`Enchantment`）是留场永久物**，「留场 + 每回合花 mana 启动」正是启动式异能的样板形态。按 `powerId` 寻址会把阵法侧排除在外，日后必然再开第二个方法。`entryId` 已是目标引用的锚点（与 `TargetRef.EntryId` / `pending` / `CauseEntryId` 同一命名空间），不新增寻址概念。
- **`abilityId` 必须显式给。** 一个条目可挂多个异能，配额也正因此挂在**某一条异能**上而非条目上；只给 `entryId` 表达不出「启动的是哪一条」。
- **`targets` 与 `PlayCard` 逐字同构**：长度 = 该效果 `TargetSlots` 长度，顺序即 `slotIndex`，无目标槽位写 `TargetRef(None, _, string.Empty)`，入栈即 `targetState = Resolved`。「玩家主动发起的动作，槽位一律在发起前一次收齐」这条纪律的判据是**主动发起**而非「打的是不是牌」，故适用；挂起态仍只来自结算中途回头问的那些。
- **动词取 `Activate` 不取 `Use`。** `Use` 已被道具占用，两个动词分给两条不同的来源路径，读签名即知走的是哪一条。
- **敌人侧不经本方法。** EnemyManager 在自己回合内自行决定启动，走内部路径、**不产生 `ActionResult`**（没有调用方），照常广播 `CombatFeedEntry`。不为敌人另开 API。

### 2. 启动代价 = `ManaCost` 一格，`ProfileChangeSpec` 表达不了它

`ProfileChangeSpec` 的资源列以 `CostKey` 索引，而 `CostKey` 与两层 Profile 字段双向满射、其中**没有 `CurrentMana`**——战斗内的 `currentMana` 是 `activeCombat.sides[]` 上的回合内运行态（战斗外无意义），不是 Profile 字段。而启动式异能的整条价值主张是「给 mana 第二个花费去向」。两者相加 ⇒ 现行的单格 `ProfileChangeSpec?` 代价面与既定意图之间有一处结构缺口。

代价面拆为**两格**：

| 字段 | 类型 | 语义 |
|---|---|---|
| `ManaCost` | `int`（`>= 0`） | 战斗内代价，由 combat-service 直接扣 `sides[controllerSide].currentMana`，**不经 `ProfileManager`** |
| `MaxActivationsPerCombat` | `int`（`-1` = 不限） | 本场配额，见第 3 节 |

- **首版不开 Profile 侧代价列。** 战斗内代价面收敛为单一刻度 mana：读者与内容作者不必区分「哪些启动会即时写 Profile」，避免每次启动都产生一次 `TryApply` 与一次上行 diff，也天然避开「一条启动式异能间接成为回寿 / 产灵石通道」。代价是「花寿元换一次强力启动」这类设计空间此刻关闭；日后要开是加一个字段、零存档迁移。
- **`ManaCost` 是独立整数格、不塞进 `ProfileChangeSpec`。** 塞进去要么伪造一个 `CostKey.CurrentMana`（污染满射不变式），要么让 spec 承载两族语义（Profile 写入 / 战斗内运行态），此后每次读 spec 都要先分辨它属于哪一族——与「`KeywordRef.Amount` 不进 `counters`」被否决的理由逐字同构。
- **扣费时机 = 压栈那一刻**（与出牌的费用支付同时机），**fizzle 不退**。
- **扣的是 `sides[controllerSide].currentMana`，不写死玩家侧**：敌人同样启动（走内部路径），故按启动方解析。与「`SideConstraint` 一律相对施放者解析、枚举里不放绝对方取值」同构。
- **加载期校验由「有费用」放宽为「有有限性闸」**：`Kind == Activated ⇒ ManaCost >= 1 || MaxActivationsPerCombat >= 1`。防无限循环的目的不变（零费且无配额的启动式在栈为空时可反复启动），但判据更准确，也不再逼一条纯配额型异能（「每场一次、免费」）去编造一个假费用。

### 3. 每场配额 —— 存档一格不加，复用 `entry.counters`

- **落点 = 战场条目的 `counters[<abilityId>]`**（默认计数器，无 `#` 段）。既定键约定第一句就是「该异能的默认计数器（**触发 / 启动次数**）」，键主体取 `AbilityData.Id` 的理由（一个条目可挂多个异能、配额天然挂在某一条上）正是为启动侧准备的。`ActiveCombat` **一格不加、空迁移**。
- **语义 = 每载体条目、每场。** 同一条 `AbilityData` 挂在两个条目上 ⇒ 两份独立计数（`Power` 只有一个条目故无差别，阵法多份同名时每份各有配额）。这一条必须写进正文，否则内容作者会按「全场合计」编排。
- **配额值是 `AbilityData` 上的显式内容字段，不是效果定义内部的一个条件。** 判据是**可预判性**：UI 必须在点下去之前把不可启动项灰显，埋在效果条件里的配额无法被机械预读，UI 只能让玩家点了才被拒——那正是随身抽屉明确否决的形态。它与「『每场限 N 次』类异能须在效果定义里引用自己 `AbilityData.Id` 作键」的内容侧纪律是**分工**关系：字段管启动侧的可预判闸，键引用纪律管触发式与效果内部条件，两者写的是同一个 `counters` 键。
- **既定的两次闸门查询原样成立**：宣告时一次（读到旧值）→ `AbilityQuotaExceeded`；结算收口时再一次（读到已 +1 的值，拦住同一结算链内的第二条）。**计数仍只在弹栈结算成功那一刻 +1**，不在压栈处、不在付费处。
- **清理 = 无。** 条目离场 `counters` 随之消失，`activeCombat` 在 `eventEnd` 整块置空 ⇒ 本场配额随战斗自然清零。
- **跨场的「本轮回限 N 次」不在范围内**：它没有过期时刻，按既定归属判据不该落 `entry.counters`；当前无此需求，不预铺。

### 4. 拒绝语义 —— 三条通用 + 两条新增，全部走 `ActionResult`

| 情形 | 拒绝理由 |
|---|---|
| 不是自己回合 / 不在行动阶段 / 栈非空 | `NotYourTurn` · `NotActionStep` · `StackNotEmpty`（与出牌 / 用道具完全同窗口） |
| `entryId` 不在战场 / `ownerSide != Character` / `abilityId` 不挂该条目 / `Kind != Activated` | `AbilityNotAvailable`——**合并为一条**，与 `ItemNotAvailable` 同款粒度：四种情形对玩家是同一句话，拆成四条只增加调用方分支而不增加任何可呈现的差别 |
| `currentMana < ManaCost` | `InsufficientMana`（复用既有成员，不另立） |
| 配额撞上 `MaxActivationsPerCombat` | `AbilityQuotaExceeded`（对位 `ItemUsesThisCombatExceeded`） |
| 目标非法 / 槽位数不匹配 | `IllegalTarget`（与 `PlayCard` 同） |

- **`abilityId` 经 `ContentRegistry` 解析不到 → `PushError` + 抛，不是业务拒绝**（真悬空 = 内容被删或键被写错，与读档校验 ② 同档）；**解析得到但不挂在该条目 / 不是启动式 → 业务拒绝**（UI 可能持有一份刚被移除条目的陈旧 id，属预期内）。这条分界必须写明，否则两侧会各写一半。
- **`ActionRejection` 不落存档，故追加成员无迁移、无冻结约束**（与随 `PastEventEntry` 逐字序列化的 `CostKey` / `StatKey` 不同档）。
- **文案键走 `COMBAT_` 分区普通键，不占 `ERR_` 前缀**：战斗内拒绝是本地业务拒绝、没有后端 `code`，手写 `ERR_*` 会与日后新增的后端 `code` 撞键。本次只需两条新键 `COMBAT_ABILITY_UNAVAILABLE` · `COMBAT_ABILITY_QUOTA_EXCEEDED`（mana 不足与出牌 / 用道具共用 `COMBAT_INSUFFICIENT_MANA`）。

### 5. 灰态预判 vs 服务重校验的分工

- **UI 侧预判、灰显、长按给原因；服务侧仍全量重校验、绝不信任 UI。** 这不是重复：服务是规则权威，而 UI 不预判就只能让玩家点了才被拒，撞上「使用窗口是全局规则，UI 应把它表达为可供性的有无」这条既定要求。
- **预判所需数据由服务算好交给 UI。** `BattlefieldEntryView` 增一格 `IReadOnlyList<AbilityAvailability> ActivatableAbilities`：

  ```csharp
  public readonly record struct AbilityAvailability(
      string AbilityId, int ManaCost, int RemainingUses, bool CanActivate, ActionRejection Reason);
  ```

  理由：配额计数活在 `entry.counters` 里、UI 拿不到；让 UI 自行重演窗口 / mana / 配额三条规则等于把规则实现成两份。`CombatSnapshot` 本就按变更广播 + 缓存，多这一格不落在热路径的分配面上。
- **只对 `ViewerSide` 己方条目填充，对侧条目恒为空列表**——与「对侧的 `HandCardInstanceIds` / `UsableItemIds` 恒为空」同一条填充纪律。灰态预判服务的是观察方可发起的动作；给对手条目算 `CanActivate` 既无消费者，又是一条信息泄漏面。
- **被 `disabledAbility` 抑制的载体本就不入场**（参战方组装的三条与门），其上的启动式异能天然不可见、由 `AbilityNotAvailable` 兜底，**不需要第二条禁用过滤**。
- **拒绝真发生时不弹 toast**：`Accepted == false` 时 UI 只回到原态；解释由灰态 + 长按承担，与选目标态「不做『点非法目标弹提示』」同一条纪律。

### 6. 栈 / `ActionResult` / `CombatFeedEntry` / 决策点

- **入栈**：`StackEntryKind.ActivatedAbility`（枚举成员已存在，不新增）。`controllerSide = 启动方` · `sourceEntryId = entryId`（载体条目）· `abilityId = abilityId` · `sourceInstanceId` = 载体条目的 `sourceInstanceId`（阵法有值、`Power` 为空）· `chosenTargets` = 传入列表 · `targetState = Resolved`。
- **`ActionResult`**：`Kind = ActivateAbility`、**`SubjectId = entryId`**。取 `entryId` 而非 `abilityId`：它是唯一寻址（同一条 `AbilityData` 可同时挂在多个条目上），且与 `CauseEntryId` / `TargetRef.EntryId` 同一命名空间；调用方本就知道自己启动的是哪条异能，`ActionResult` 是同一次动作的回执，不必把请求参数原样回传。`ManaSpent` 填 `ManaCost`；其余字段语义不变。
- **`CombatFeedEntry`**：新增 `CombatFeedKind.AbilityActivation`。现有 `AbilityTrigger` 的语义是触发式，合用会让战报因果树分不清「**我启动了** X」与「X **被触发了**」——而战报的全部价值就是「谁引发了谁」可读。条目取值：`EntryId = stackEntryId` · `CauseEntryId = string.Empty`（玩家主动动作是因果树的根，与 `CardPlay` 同）· `SourceId = abilityId` · `SourceInstanceId` = 载体条目的 `sourceInstanceId` · `FizzledSlots` 照常。
- **决策点清单不加行。** 判据是「状态机停下来等玩家输入」——启动的结算与出牌完全同形，D2 本就点名了它；结算中途要目标则落既有的 D4。密度口径也不变：启动**替代**一次出牌占用行动阶段的一个动作位，不是额外叠加。

## Clarifications

- **启动代价是否允许 Profile 侧一列（`ProfileCost`）→ 首版只开 `ManaCost`，不加 `ProfileCost`。** 连带确定：不需要同批圈定「`ProfileCost` 允许哪些 `CostKey`」的白名单；日后补开是加字段、零存档迁移。原始输入第 2 节写的三格表、三选一校验、`ActivationCostUnaffordable` 拒绝理由与 `COMBAT_ABILITY_COST_UNAFFORDABLE` 翻译键**随此裁决全部撤回**——落笔形态为两格 / 二选一校验 / 只加两个 `ActionRejection` 成员 / 只建两条翻译键。
- **`ActivationCost : ProfileChangeSpec?` 与「启动式异能给 mana 第二个花费去向」两条既定表述互斥 → 判为字段形态的缺口，取拆格方案。** 「启动式异能给 mana 第二个花费去向」原样成立、无需修订。
- **显式 `MaxActivationsPerCombat` 字段 vs「效果定义里引用自己 `AbilityData.Id` 作键」的内容侧纪律 → 按分工读法处理**（采纳的默认）：字段管启动侧的可预判配额闸，键引用纪律管触发式与效果内部条件，两者写同一个 `counters` 键。排他读法会让灰态预判失去数据源。
- **加载期校验放宽为「须存在一条有限性闸」**（采纳的默认）——判据由「有费用」改为「有有限性闸」，防无限循环的目的不变。
- **战斗内拒绝的文案键归属 → `COMBAT_` 分区普通键**（采纳的默认），不占 `ERR_` 前缀、不走 `ErrorText.For` 三参形态：那条链路服务的是后端 `OpError`，而战斗内拒绝是本地业务拒绝、无后端 `code`。
- **`ActionRejection` 只追加两个成员**（采纳的默认）：`AbilityNotAvailable` · `AbilityQuotaExceeded`。`ActivationCostUnaffordable` 不加——无 Profile 侧代价即无任何触发情形，枚举里不留永无消费者的取值（先例：`TargetKind` 不保留 `StackEntry`）。
- **`MaxActivationsPerCombat == 0` 非法，加载期 `PushError`**（采纳的默认）。`-1` = 不限、`>= 1` = 配额、`0` 未定义，而 `0` 恰是 `[Export]` 的默认值 ⇒ 内容作者漏填即落进未定义区。先例：`KeywordRef.Amount` 用 `-1` 作哨兵并配一条加载期 `PushError`。
- **`Kind != Activated` 且 `MaxActivationsPerCombat != -1` → `PushError`**（采纳的默认）。否则一条触发式异能上填了配额会被静默忽略——与 `CounterNames` 那条纪律的理由逐字同构。
- **扣的是 `sides[controllerSide].currentMana` 而非写死玩家侧**（采纳的默认）——敌人同样启动，先例是「`SideConstraint` 一律相对施放者解析」。
- **配额语义 = 每载体条目、每场**（采纳的默认）——由落点 `entry.counters` 直接推出。
- **`ActivatableAbilities` 只对 `ViewerSide` 己方条目填充**（采纳的默认）——逐字同构的先例是「对侧的 `HandCardInstanceIds` 与 `UsableItemIds` 恒为空，不是 bug」。
- **被 `disabledAbility` 抑制的载体不需要第二条禁用过滤**（采纳的默认）——入场三条与门已在更早一步截断。
- **`ActivationCost` 已付但 fizzle 不吃配额那一句的字段名同改为「启动代价（`ManaCost`）」**（采纳的默认）——规则本身不变，只是原字段名随本次拆格失效。
- **`ActionResult.SubjectId` 与 `CombatFeedEntry` 的 `Kind` / `SourceId` 三处内联注释同改**（采纳的默认）——四种动作就该有四种读法，注释漏一种即是失真。

## Open questions

- **阵法（`Enchantment`）上启动式异能的 UI 宿主未定。** 现有形态只定了 `Power` 那一半（长按图标升起的弹层内的启动键）。服务契约不依赖它（`entryId` 寻址与宿主无关），但没有宿主就没有玩家可发起的路径。归已排期的竖屏分区专场。
- **`MaxActivationsPerCombat` 的取值范围与内容侧编排口径**属统计校准，与「结构可定、数字随内容扩充后校准」同批，不另开条目。
