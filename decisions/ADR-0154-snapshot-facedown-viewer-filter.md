# ADR-0154 — 对侧 `faceDown` 战场条目整条排除出 `CombatSnapshot.Battlefield`

- **状态：** Accepted
- **日期：** 2026-09-03
- **来源：** handoffs/2026-09-03-combat-snapshot-facedown.md

## 背景

`CombatSnapshot` 对三处信息泄漏面已写死按视角的填充纪律（`HandCardInstanceIds` / `UsableItemIds` / `ActivatableAbilities`）。但 `Battlefield` 是一条**单一列表**（条目自带 `OwnerSide`，呈现层分区渲染），条目自带 `faceDown` 与内容格，却没有写「对侧 `faceDown == true` 的条目怎么办」。

照字面读，对手埋伏的**内容**在类型层是可读的——「对手只知有一张埋伏、不知是哪张」就退化为 UI 侧的一条约定，而 UI 约定不会在被违反时报错。同一份快照同时喂给 AI 与呈现层，泄漏面因此是双份的。

## 决策

**组装 `CombatSnapshot.Battlefield` 时按视角过滤：`faceDown` 且 `ownerSide != ViewerSide` 的条目整条不入列**，而不是保留壳条目再把内容格置空。

- **不变式：** `Battlefield` 中不存在 `FaceDown == true` 且 `OwnerSide != ViewerSide` 的条目 ⇒ 视图内 `FaceDown == true` 恒指观察方己方的埋伏。`BattlefieldEntryView` 保留 `FaceDown` 一格（己方埋伏靠它决定折叠 / 逐条渲染与埋伏标记）。
- 被剔除的条数由 **`SideSnapshot.AmbushCount`** 承载，公开面零损失；其定义按 `faceDown` 收口，与过滤判据逐字同源。
- **`Battlefield.Count` 不再等于场上条目总数**；**视图内的 `entryId` 引用不得假定可解析**。两条须写进填充纪律旁。
- **揭示时刻不加翻面态、不加任何战场条目字段**：改由 `StackEntryView.SourceCardId` 与 `CombatFeedEntry.SourceCardId` 各补一格承担。
- 前提机械化：`TargetSlot.Kind == BattlefieldEntry` 且 `Filter.IncludeFaceDown == true` 且 `Side != Self` → `PushError`。`PendingTarget` 同补一条按视角的填充纪律。

逐条填充纪律与字段面 → `systems/services/combat-service.md`。

## 理由

- **置空 / 哨兵值的形态无法收口**：内容格在类型上仍然存在，每个消费者读之前都要先判 `faceDown`，漏判无人发现；且列表也能数出对侧埋伏数，与 `AmbushCount` 形成两个口径。
- **`AmbushCount` 使公开面零损失**——「对手有几张埋伏」本就是应当可见的信息，它已有专门的承载格。
- **揭示时刻的可观测面归栈条目与战报**，与「敌方启动的可观测性由飘字与战报承担」同一条纪律；`abilityId → CardData` 的反查在设计上就是多义的，故两处各缺的那一格只能补。栈条目结算完即消失、战报保留本场全部条目 ⇒ 战报缺这一格就**永久**失去「那张埋伏是哪张」。
- **`TargetSlot` 侧的闸把正确性从散文变成机械可发现**：不加闸则 UI 可能拿到一个自己列表里没有的 `entryId` 去高亮。它与同表既有的 `HandCard + IncludeFaceDown → PushError` 逐字同构。

## 备选方案

- **保留壳条目、内容格置空 / 填哨兵值** — 否决：漏判无人发现，且与 `AmbushCount` 形成第二个口径。
- **另立对侧专用条目视图** — 否决：与「`SideSnapshot` 单类型，不拆己方 / 对方」「不为 AI 另立第二个投影类型」两条既定形状相抵，ViewModel 与 AI 各多一条会各自漂移的路径。
- **给战场条目加「已翻面 / 已揭示」态** — 否决：为一个瞬时时刻新增持久字段，而该时刻已有栈条目与战报两条既有承接面。
- **呈现层自行缓存「那张埋伏是哪张」** — 否决：同一事实的第二份持有。

## 后果

- **AI 输入面的表述随之改写**：`systems/services/combat-service.md` 的「战场全部条目」改为「双方全部**面朝上**条目 + 己方面朝下条目」。
- **代价明写接受**：`EntryFilter.IncludeFaceDown` 对目标面收窄为只能取己方（`Side != Self` 同时拦下 `Any`，按最严收口）；日后确要做「点选对手的一张埋伏」，本填充纪律须整条重议。替代路径是走 `EffectScope`（随机 / 全部，无 `TargetRef`），`EffectScope` / `TriggerFilter` 两处的 `IncludeFaceDown` 不受限。
- **存档面零影响**：`ActiveCombat` 保留全量真值，本次只约束运行时视图与战报流 ⇒ 无 schema bump、空迁移。
- 受约束的文档：`systems/services/combat-service.md`（填充纪律 · `StackEntryView` 首格 · `CombatFeedEntry` 字段面 · AI 输入面）· `systems/character-profile/deck/common-properties.md`（加载期校验表 +1 行 · `IncludeFaceDown` 纪律段）· `ux/combat-ux.md`（对手侧面朝下条目「不进入战斗态视图」+ 回链）。
