# ADR-0114 — 启动式异能开 `ActivateAbility(entryId, abilityId, targets)`，代价面拆 `ManaCost` + `MaxActivationsPerCombat` 两格

- **状态：** Accepted
- **日期：** 2026-08-26
- **来源：** handoffs/2026-08-26d-activate-ability-contract.md · handoffs/2026-08-27-ability-primitive-grammar.md

## 背景

启动式异能有窗口（决策点 D2 明写「一次出牌 / 启动 / 用道具结算完毕」）、有栈条目（`StackEntryKind.ActivatedAbility`）、有 UI 宿主，唯独没有 API 方法——`CombatActionKind` 只有 `PlayCard / UseItem / EndTurn`。缺口的直接后果是这条动作无法被消费：启动式异能是 mana 的第二个花费去向，缺它战场就退回纯被动区。同时，`ProfileChangeSpec` 的资源列以 `CostKey` 索引，而 `CostKey` 里**没有 `CurrentMana`**，现行的单格代价面表达不了战斗内代价。

## 决策

**`ActionResult ActivateAbility(string entryId, string abilityId, IReadOnlyList<TargetRef> targets)`**——按**战场条目**寻址而非 `Power`；`abilityId` 必须显式给；`targets` 与 `PlayCard` 逐字同构；**敌人侧不经本方法**（走内部路径、不产生 `ActionResult`，照常广播 `CombatFeedEntry`）。

**代价面拆两格**：`ManaCost : int` 由 combat-service 直接扣 `sides[controllerSide].currentMana`、**不经 `ProfileManager`**、压栈时扣、fizzle 不退；`MaxActivationsPerCombat : int`（`-1` 不限 / `>= 1` / `0` 非法）。**首版不开 Profile 侧代价列。**

**每场配额落既有 `entry.counters[<abilityId>]`，`ActiveCombat` 一格不加**；语义 = **每载体条目、每场**；两次闸门查询保留，计数只在弹栈结算成功那一刻 +1。

**两格均非必填**——无限组合是被接受的设计面，终止性由 `TurnLimit` 与单次动作链的栈条目上限承接。

`ActionRejection` 只追加 `AbilityNotAvailable` / `AbilityQuotaExceeded` 两员；灰态预判由 `BattlefieldEntryView.ActivatableAbilities` 承载，服务侧仍全量重校验；新增 `CombatFeedKind.AbilityActivation`（不与 `AbilityTrigger` 合用）；决策点清单不加行。

完整签名、拒绝语义表与灰态字段 → `systems/services/combat-service.md`「API 面（契约）」；字段形态 → `systems/character-profile/deck/common-properties.md`。

## 理由

**按 `entryId` 而非 `powerId` 寻址：** 启动式异能不是 `Power` 专属——阵法（`Enchantment`）是留场永久物，「留场 + 每回合花 mana 启动」正是启动式的样板形态。按 `powerId` 寻址会把阵法排除在外，日后必然再开第二个方法。`entryId` 已是目标引用的锚点，不新增寻址概念。

**`abilityId` 必须显式给：** 一个条目可挂多个异能，配额也正因此挂在某一条异能上而非条目上。

**`ManaCost` 是独立整数格、不塞进 `ProfileChangeSpec`：** 塞进去要么伪造一个 `CostKey.CurrentMana`（污染满射不变式），要么让 spec 承载两族语义（Profile 写入 / 战斗内运行态），此后每次读 spec 都要先分辨它属于哪一族。

**首版不开 Profile 侧代价列：** 战斗内代价面收敛为单一刻度 mana，读者与内容作者不必区分「哪些启动会即时写 Profile」，也天然避开「一条启动式异能间接成为回寿 / 产灵石通道」。

**配额值是显式内容字段而非效果内部条件，判据是可预判性：** UI 必须在点下去之前把不可启动项灰显，埋在效果条件里的配额无法被机械预读。

**动词取 `Activate` 不取 `Use`：** `Use` 已被道具占用，两个动词分给两条不同来源路径，读签名即知走的是哪一条。

**`AbilityNotAvailable` 合并四种情形：** 与 `ItemNotAvailable` 同款粒度——四种情形对玩家是同一句话，拆开只增加调用方分支而不增加任何可呈现的差别。

## 备选方案

- **按 `powerId` 寻址** — 否决：排除阵法，日后必开第二个方法。
- **把 `ManaCost` 塞进 `ProfileChangeSpec`** — 否决：污染 `CostKey` 满射不变式或让 spec 承载两族语义。
- **配额另开 `ActiveCombat` 字段** — 否决：`entry.counters` 的键约定第一句就是「该异能的默认计数器（触发 / 启动次数）」，正是为此准备的。
- **加载期强制「`Kind == Activated` ⇒ `ManaCost >= 1 || MaxActivationsPerCombat >= 1`」（有限性闸）** — **首版曾拟采用，2026-08-27 撤回**：无限组合升为被接受的设计面，非本意的无限由内容侧纪律承接，工程侧改设单次动作链的栈条目总数上限。
- **为敌人侧另开 API** — 否决：敌人没有调用方，不产生 `ActionResult`。
- **把 `AbilityNotAvailable` 拆成四条** — 否决：见理由。
- **跨场的「本轮回限 N 次」配额** — 未取：它没有过期时刻，按既定归属判据不该落 `entry.counters`；当前无此需求，不预铺。

## 后果

- `systems/services/combat-service.md` 是契约权威；`systems/character-profile/deck/common-properties.md` 承载 `AbilityData` 的两格字段形态与配额哨兵校验。
- 配额语义「每载体条目、每场」必须写进正文——否则内容作者会按「全场合计」编排。
- 清理 = 无：条目离场 `counters` 随之消失，`activeCombat` 在 `eventEnd` 整块置空，本场配额随战斗自然清零。
- 拒绝真发生时不弹 toast，灰态是主通道 → `ux/combat-ux.md`。
- 效果原语与流水线 → `ADR-0115`。
