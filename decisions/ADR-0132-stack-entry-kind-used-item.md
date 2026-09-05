# ADR-0132 — 用道具的栈条目自成一员：`StackEntryKind.UsedItem` + `itemId` 一格

- **状态：** Accepted
- **日期：** 2026-08-30
- **来源：** handoffs/2026-08-30-stack-entry-kind-for-item-use.md

## 背景

战斗内使用道具已是一等玩家动作（`UseItem(itemId, targets)` 返回 `ActionResult`、`targets` 与 `PlayCard` 逐字同构、入栈即 `targetState = Resolved`、栈条目的 `abilityId` 恒空），但 `StackEntryKind` 的四个成员没有一个对应它——道具不是牌、不是异能、不是疲劳。`decisions/ADR-0121-item-use-effect-face-by-world.md` 把这一格明确留为待答。

## 决策

**`StackEntryKind` 增第五个成员 `UsedItem`；栈条目新增 `itemId` 一格**（`kind == UsedItem` 时非空、其余四个成员恒空，双向不变式，读档期可断言）。

**`CombatFeedKind` 增 `ItemUse`**，取值段对位 `AbilityActivation`：`EntryId = stackEntryId` · `CauseEntryId = string.Empty`（主动动作是因果树的根）· `SourceId = itemId` · `Side` = 使用方。**敌人用道具同样广播**（它没有 `ActionResult`，战报是唯一可观测面）。

**读档校验分档写明**：栈条目的 `itemId` 走强解析（`PushError` 并报出 id）；`CombatItemSave.ItemId` 仍走「不在本场可用道具内 → `PushWarning` + 丢弃该条计数」。**一条 `UsedItem` 栈条目在它对应的 `CombatItemSave` 被丢弃时照常结算。**

**`card.played` 不由 `UseItem` 广播**，也不为「使用道具时」新开时点。同批补齐 `UseItem` 段此前缺失的 mana 扣费（压栈那一刻扣、fizzle 不退、不经 `ProfileManager`，不足则复用 `InsufficientMana`）。

成员名词形按各枚举内部一致取：`StackEntryKind.UsedItem` / `CombatFeedKind.ItemUse` / `CombatActionKind.UseItem`，**三个枚举不跨枚举统一词形**。逐格填法、断言与战报取值段见 `systems/services/combat-service.md`。

## 理由

- **不复用 `ActivatedAbility`**：复用会让 `sourceEntryId`（载体条目）与 `abilityId`（异能主体）两格同时变成可空，「`ActivatedAbility` ⇒ 有载体条目、有异能主体」这条不变式被整条抹掉，`ActivateAbility` 的「`SubjectId` 取 `entryId` 因为它是唯一寻址」在该成员上也不再成立——**那不是加一个分支，是让一个成员失去形状**。
- **三个切面本就该对齐**：`CombatActionKind`（我发起了什么）/ `StackEntryKind`（栈上这条是什么来源）/ `CombatFeedKind`（战报这条是什么事）是同一条链路的三个切面，动作侧早已把 `UseItem` 列为一等成员；三者在这一格上不对齐本身就是缺口。
- **「凡按 `kind` 分支处全部要补一路」这项代价在当前设计面上是空集**：结算收口按 `abilityId` 非空判、不按 `kind` 判；`TimingIds` 十个时点无一按栈条目 `kind` 命中；`EntryFilter` 筛的是战场条目不是栈条目。唯一按 `kind` 分的地方是呈现层映射到 `CombatFeedKind`——而那正是需要它分开的地方。
- **`itemId` 不可由三个来源格推导**：道具不是 `CardInstance`（无实例 id）、从不进场（无 `entryId`）、没有宿主 `AbilityData`——三格对它全部恒空，而结算要按它解析 `ItemData.CombatUseEffects`、战报要按它显示用的是哪件道具。
- **战报侧分立**：因果树要读得出「他喝了一瓶药」与「他启动了阵法上的异能」之别，而两者的道念增量在快照上可以完全相同。
- **两处失败语义不同故须分档**：栈上那条是正在结算的事实，解析不到即真悬空；`items` 里那条只是本场计数，其道具本场不再可用是预期内的状态变化。
- **`card.played` 不并入**：道具在战斗内以 `CardType.Item` 呈现，但它不是被打出的牌——并进去会让「打出一张牌时」的监听者被一件道具意外唤醒。

## 备选方案

- **复用 `ActivatedAbility`** — 否决：见理由，会抹掉该成员的不变式。
- **同批开 `TimingIds.ItemUsed`** — 否决（用户确认）：时点表随广播点一同增长，当前没有内容需要它；开它要连带给 `SubjectKind` 增一档「道具」并扩 `TriggerFilter` 的相容校验矩阵。日后要开是纯加法。
- **给 `StackEntryView` 补字段** — 否决：全库对该类型没有任何字段面定义，为它补一格等于新造一处未被要求的契约。

## 后果

- 存档面加一格，**该格属 `schemaVersion` 1，登记见 `systems/services/profile-schema-versions.md`**；量级只在 `UsedItem` 条目上有值、一场至多几条；`kind` 增员本身不加字段，多的只是一个取值。
- `deck/common-properties.md` 增一条软检查：`TimingId == card.played` 且 `TriggerFilter.CardTypes` 仅含 `Item` → `PushWarning`（该异能永不触发）。
- 战报的「五类情形」改为六类。
- **`ADR-0121` 后果里那条「待答：用道具产生的栈条目落在 `StackEntryKind` 哪个成员上」自此关闭**，已改为指向本 ADR。
- **不跨库**：本题全在客户端进程内（栈 / 战报 / 本地存档块 `ActiveCombat`），不触及任何客户端 ↔ 后端报文。`systems/architecture.md` 的 `CombatFeedEntry` 签名行不改（该行只列字段名与类型，不复述枚举值域）。
- 因此必须这么写的文档：`systems/services/combat-service.md`（栈条目段 · 读档校验分档 · 存档新增字段段 · `UseItem` API 段与失败语义列 · 战报段）· `systems/character-profile/deck/common-properties.md`（校验表新增一条）。
