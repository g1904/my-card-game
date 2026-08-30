# 用道具的栈条目类型：`StackEntryKind` 增 `UsedItem`

- id: 2026-08-30-stack-entry-kind-for-item-use
- date: 2026-08-30
- topic: systems/services/combat-service.md · systems/character-profile/deck/common-properties.md
- status: distilled
- distilled-to: systems/services/combat-service.md, systems/character-profile/deck/common-properties.md

## Intent（distilled）

战斗内使用道具已是一等玩家动作（`UseItem(itemId, targets)` 返回 `ActionResult`、`targets` 与 `PlayCard` 逐字同构、入栈即 `targetState = Resolved`、栈条目的 `abilityId` 恒空），但 `StackEntryKind` 的四个成员没有一个对应它 —— 道具不是牌、不是异能、不是疲劳。本次把这一格补齐。

### 1. `StackEntryKind` 增第五个成员 `UsedItem`

不复用 `ActivatedAbility`：复用会让 `sourceEntryId`（载体条目）与 `abilityId`（异能主体）两格同时变成可空，「`ActivatedAbility` ⇒ 有载体条目、有异能主体」这条不变式被整条抹掉，`ActivateAbility` 的「`SubjectId` 取 `entryId` 因为它是唯一寻址」在该成员上也不再成立 —— 那不是加一个分支，是让一个成员失去形状。

`CombatActionKind`（我发起了什么）/ `StackEntryKind`（栈上这条是什么来源）/ `CombatFeedKind`（战报这条是什么事）是同一条链路的三个切面，动作侧早已把 `UseItem` 列为一等成员；三者在这一格上不对齐本身就是缺口。

「凡按 `kind` 分支处全部要补一路」这项代价在当前设计面上是空集：阶段 5 的收口按 `abilityId` 非空判、不按 `kind` 判；`TimingIds` 十个时点无一按栈条目 `kind` 命中；`EntryFilter` 筛的是战场条目不是栈条目。唯一按 `kind` 分的地方是呈现层映射到 `CombatFeedKind` —— 而那正是需要它分开的地方。

### 2. 栈条目新增 `itemId` 一格

`kind == UsedItem` 时非空、其余成员恒空，双向不变式，读档期可断言。它不可由三个来源格推导：道具不是 `CardInstance`（无实例 id）、从不进场（无 `entryId`）、没有宿主 `AbilityData` —— 三格对它全部恒空，而结算要按它解析 `ItemData.CombatUseEffects`、战报要按它显示用的是哪件道具。

存档面：加格成本此刻恒为零（无线上存档 ⇒ 空迁移），量级只在 `UsedItem` 条目上有值、一场至多几条。`kind` 增员本身不加字段，多的只是一个取值。

### 3. `CombatFeedKind` 增 `ItemUse`

战报侧同样分立、不与启动 / 触发合流：因果树要读得出「他喝了一瓶药」与「他启动了阵法上的异能」之别，而两者的道念增量在快照上可以完全相同。取值段对位 `AbilityActivation`：`EntryId = stackEntryId` · `CauseEntryId = string.Empty`（主动动作是因果树的根）· `SourceId = itemId` · `SourceInstanceId = string.Empty` · `Side` = 使用方。敌人用道具同样广播（它没有 `ActionResult`，战报是唯一可观测面）。

成员名词形按各枚举内部一致取：`StackEntryKind.UsedItem`（过去分词 + 名词）/ `CombatFeedKind.ItemUse`（名词短语）/ `CombatActionKind.UseItem`（动词短语）。三个枚举不跨枚举统一词形。

### 4. 读档校验 ② 扩一项，并写明 ②/⑥ 的分档

栈条目的 `itemId` 走 ②（强解析 → `PushError` 并报出 id）；`CombatItemSave.ItemId` 仍走 ⑥（不在本场可用道具内 → `PushWarning` + 丢弃该条计数）。同一个 id 在两处的失败语义不同：栈上那条是正在结算的事实，解析不到即真悬空；`items` 里那条只是本场计数，其道具本场不再可用是预期内的状态变化。故一条 `UsedItem` 栈条目在它对应的 `CombatItemSave` 被 ⑥ 丢弃时**照常结算**。

### 5. 连带补齐 `UseItem` 段的既有缺口

`ItemData.ManaCost` 一格早已存在，而 `UseItem` 段自始至终未写 mana 扣费。按 `ActivateAbility` 的同款模板补齐：压栈那一刻扣 `sides[controllerSide].currentMana`、fizzle 不退、不经 `ProfileManager`，`currentMana < ManaCost` → `InsufficientMana`（复用，不另立），`ManaSpent` 填 `ManaCost`。次数消耗与 mana 是两条互不代替的账。同批补上入栈填法、敌人侧路径。

### 6. `card.played` 不由 `UseItem` 广播

道具在战斗内以 `CardType.Item` 呈现，但它不是被打出的牌 —— 并进 `card.played` 会让「打出一张牌时」的监听者被一件道具意外唤醒。连带在 `deck/common-properties.md` 的校验表补一条软检查（校验 20）：`TimingId == card.played` 且 `TriggerFilter.CardTypes` 仅含 `Item` → `PushWarning`（该异能永不触发）。

## Clarifications

- **是否同批开 `TimingIds.ItemUsed` → 不开（用户确认）。** 时点表随广播点一同增长，当前没有内容需要它；开它要连带给 `SubjectKind` 增一档「道具」并扩 `TriggerFilter` 的相容校验矩阵。日后要开是纯加法（一行常量 + 一处广播点 + 一档 subject）。
- **读档校验 ②/⑥ 分档需要显式写明**（草稿未点名）—— 不写明，两侧会各写一半。
- **存档小节「本块新增的字段只有战场条目的 `amount` 一格」随本次变假 → 就地改写为两格**，沿用同一条空迁移论证。
- **战报引言「五类情形」→「六类」**，`## 决策(-> ADR)` 里对应的「四类共用」一句同改，否则新增的 `ItemUse` 会在两处枚举面之外无声存在。
- **`StackEntryView` 不补字段** —— 全库对该类型没有任何字段面定义（只在 `CombatSnapshot` 里被引用），为它补一格等于新造一处未被要求的契约。
- **`systems/architecture.md` 的 `CombatFeedEntry` 签名行不改** —— 该行只列字段名与类型，不复述枚举值域。

## Open questions

- 无。（本次结论完整，无剩余远期未知。）

## Notes / triage

- 路由：`systems/services/combat-service.md`（栈条目段 · 读档校验 ② 与其引注 · 存档新增字段段 · API 面 `UseItem` 段与方法表失败语义列 · 战报段 · `## 决策(-> ADR)`）；`systems/character-profile/deck/common-properties.md`（校验表新增第 20 条）。
- **承接项（交下一次 `/write-adr`）**：`ADR-0121` 末行登记的「待答：用道具产生的栈条目落在 `StackEntryKind` 哪个成员上」在本次之后已失效，应在固化本决策时一并清理（新开一条 ADR 或并入 `ADR-0121` 的「后果」，由那次 session 判定）。本次不动 `decisions/`。
- 不跨库：本题全在客户端进程内（栈 / 战报 / 本地存档块 `ActiveCombat`），不触及任何客户端 ↔ 后端报文。
