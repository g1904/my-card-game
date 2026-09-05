# `CombatSnapshot` 的 `faceDown` 按视角填充纪律：对侧面朝下条目整条不入列

- id: 2026-09-03-combat-snapshot-facedown
- date: 2026-09-03
- topic: systems/services/combat-service.md · systems/character-profile/deck/common-properties.md · ux/combat-ux.md
- status: distilled
- distilled-to: systems/services/combat-service.md, systems/character-profile/deck/common-properties.md, ux/combat-ux.md

## Intent（distilled）

`CombatSnapshot` 对三处信息泄漏面都写死了填充纪律 —— `SideSnapshot.HandCardInstanceIds`「仅 viewer 己方非空，公开面由 `HandCount` 承载」、`SideSnapshot.UsableItemIds`「仅 viewer 己方非空」、`BattlefieldEntryView.ActivatableAbilities`「只对 `ViewerSide` 己方条目填充」。而 `Battlefield` 是一条**单一列表**（条目自带 `OwnerSide`，呈现层分区渲染），条目自带 `faceDown` 与内容格，却没有写「对侧 `faceDown == true` 的条目怎么办」。照字面读，对手埋伏的**内容**在类型层是可读的，「对手只知有一张埋伏、不知是哪张」就退化为 UI 侧的一条约定。本次把这条纪律补齐，并把它依赖的两条前提机械化。

### 1. 对侧 `faceDown == true` 的条目整条不入 `Battlefield`

组装时按视角过滤（`entry.faceDown && entry.ownerSide != ViewerSide` → 该条目不进列表），而不是保留壳条目再把内容格置空。

- **不变式：** `Battlefield` 中不存在 `FaceDown == true && OwnerSide != ViewerSide` 的条目 ⇒ 视图内 `FaceDown == true` 恒指观察方己方的埋伏。
- `BattlefieldEntryView` **保留 `FaceDown` 一格**：己方埋伏要靠它决定折叠 / 逐条渲染与埋伏标记的呈现。
- 被剔除的条数由 `SideSnapshot.AmbushCount` 承载，**公开面零损失**。
- **`Battlefield.Count` 不再等于场上条目总数** —— 按长度算总数的消费者须补上对侧 `AmbushCount`。当前无此消费者（AI 的十项 term 与 UX 战场区都按 `OwnerSide` 分区读），但这一点必须写进文档。
- **视图内的 `entryId` 引用不得假定可解析**：栈条目的 `sourceEntryId` 与 `CombatFeedEntry.CauseEntryId` 链上的坐标都可能指向不在 `Battlefield` 列表中的条目（被视角过滤剔除，或已离场进弃牌堆 —— 埋伏触发后即进弃牌堆）。

置空 / 哨兵值的形态被否决，理由承重：内容格在类型上仍然存在，每个消费者读 `sourceId` / `keywordId` / `amount` 前都要先判 `faceDown`，漏判无人发现；且列表也能数出对侧埋伏数，与 `AmbushCount` 形成两个口径。另立对侧专用条目视图同样被否决：与「`SideSnapshot` 单类型，不拆己方 / 对方」「不为 AI 另立第二个投影类型」两条既定形状相抵，ViewModel 与 AI 各多一条会各自漂移的路径。

### 2. `AmbushCount` 的定义按 `faceDown` 收口（不改名）

定义写作「该侧 `faceDown == true` 的战场条目计数」，与过滤判据**逐字同源**。当前它与「次类型 `enchantment.ambush` 的条目计数」同值，故这不是语义变更；两处口径各写各的，一旦出现一个非埋伏的面朝下条目，列表少一条而计数不变，且没有任何机制发现。

不改名为 `FaceDownCount`：「埋伏计数」已是 `ux/combat-ux.md` 的必做项、也已进 `terminology.md`，改名的收益只是命名精确，代价是三处措辞连锁改动 + 玩家可见词汇分叉。

### 3. 前提机械化：`TargetSlot` 侧的 `IncludeFaceDown` 加一条加载期闸

子项 1 的正确性依赖「对侧 `faceDown` 条目永不出现在 `LegalTargets` 里」（否则 UI 会拿到一个自己列表里没有的 `entryId` 去高亮）。当前它靠「`IncludeFaceDown` 内容侧不使用」这句散文成立 —— 改成机械可发现：

`TargetSlot.Kind == BattlefieldEntry` 且 `Filter.IncludeFaceDown == true` 且 `Side != Self` → `PushError`，报出引用它的 `CardData.Id` / `AbilityData.Id` 与槽位序号。

与同表既有的「`TargetSlot.Kind == HandCard` 且 `AllowedEntryKinds` / `RequiredKeywords` / `IncludeFaceDown` 非空 → `PushError`」逐字同构（同为「隐藏信息不进目标面」这条判据的落点）。`Side != Self` 同时拦下 `Any`，是有意的按最严收口。

`EffectScope` / `TriggerFilter` 两处的 `IncludeFaceDown` 不受限：它们纯服务端求值、不经视图。日后真要写「揭示 / 清除一张埋伏」，走 `EffectScope`（随机 / 全部，无 `TargetRef`）即可 —— 与「弃掉对手一张手牌」逐字同构，也是隐藏信息上唯一诚实的形态。

### 4. 揭示时刻：不加翻面态，由栈条目 + 战报承担

对手的埋伏被触发时玩家从哪里看到它是哪张 —— **不给战场条目加「已翻面 / 已揭示」态、不加任何战场条目字段**。埋伏触发即压栈，其可观测面由该次触发的栈条目与 `CombatFeedEntry(Kind = AbilityTrigger)` 承担，与「敌方启动的可观测性由飘字与战报承担」同一条纪律。

两条承接面各缺一格「哪张牌」，本次一并补齐：

- **`StackEntryView.SourceCardId`** —— 该视图此前一个字段都没成文（只在 `CombatSnapshot.Stack` 一格被引用），本次是给它定第一格。栈是完全公开面，这一格**不条件填充**，对有卡牌来源的栈条目恒非空。
- **`CombatFeedEntry.SourceCardId`** —— 填法：`CardPlay` / `AbilityActivation` / `AbilityTrigger` 有卡牌来源时非空，`ItemUse` / `Fatigue` 为 `string.Empty`。

两处缺格的理由同款：`SourceId` 在 `AbilityTrigger` 时是 `abilityId`，而 `AbilityData` 是独立可复用资源、由多个 `CardData` / `PowerData` 共同引用 ⇒ `abilityId → CardData` 的反查在设计上就是多义的；`SourceInstanceId` 的解析通道（对侧实例表）本就不在视图里。而栈条目在结算完即消失、战报保留本场全部条目 ⇒ 战报缺这一格就**永久**失去「那张埋伏是哪张」，而这正是战报存在的理由。

### 5. `PendingTarget` 补一条按视角的填充纪律

`CombatSnapshot.PendingTarget` **仅当 `pending.controllerSide == ViewerSide` 时填充，否则恒 `null`**，与另外三条填充纪律齐平。`PendingTargetRequest` 的 `SourceCardId`（呈现用，「埋伏·XX 需要一个目标」）与 `LegalTargets` 两格承载的都是挂起方的内容；`CombatSnapshot` 是双视角的单一投影，`ViewerSide == Enemy` 时不加这条纪律，这两格上承载的正是玩家侧的牌。

## Clarifications

- **`CombatSnapshot.PendingTarget` 是不是第四条泄漏面 → 是，补一条按视角的填充纪律（子项 5）。** 这条**推翻**了草稿子项 3 末尾那句建议：「`PendingTargetRequest.SourceCardId` 不是泄漏面 —— 挂起三条与门的第 ② 条要求 `controllerSide == Character`，故该格恒为观察方己方的来源」。该论断在双视角投影下是假命题：`ViewerSide` 取该敌人的 `OwnerSide` 时，挂起恒由玩家侧动作产生，那两格承载的就是观察方的对手内容。实际不发生泄漏靠的是时序（AI 只在自己回合读快照、彼时栈空），而非结构 —— 时序保证正是本次通篇要消灭的那一档，且它依赖一条从未成文的前提。**该论断一律不得写进任何文档。**
- **`CombatFeedEntry` 是否同样增 `SourceCardId` → 增（子项 4）。** 这条**细化**了草稿子项 3「其可观测面由既有两条承担」的自陈：两条里只有栈条目一条能用，`CombatFeedEntry` 的 `SourceId` / `SourceInstanceId` 两格在对侧视角下都解析不出卡牌，而草稿给 `StackEntryView` 补格的那条理由对它同样成立却未处理。呈现层自行缓存的替代路径被直接否决 —— 那是同一事实的第二份持有。
- **子项 1 的走向（三条候选路）→ 取「整条不入列」**（2026-09-03 批量评审）。原待答项只并列了「内容格置空 / 哨兵值」与「另立对侧专用条目视图」两条，本次取的是第三路；`Battlefield.Count` 不再等于场上条目总数须随提炼写进文档。
- **`EntryFilter.IncludeFaceDown` 对目标面收窄为「只能取己方」→ 按标准默认直接落笔**（非取向项，未出题）。它与同表既有的 `HandCard + IncludeFaceDown → PushError` 逐字同构，且有明确替代路径（该玩法走 `EffectScope` 随机 / 全部）。**代价明写接受**：若日后确实要做「点选对手的一张埋伏」，本填充纪律须整条重议。

**本次自动采纳的标准默认项（未出题）：**

- **AI 输入面表述同改** → `combat-service.md` 的「输入面限对称可见信息：战场全部条目（含 `OwnerSide`）」在子项 1 之后字面为假，改写为「战场上双方全部**面朝上**条目（含 `OwnerSide`）+ 己方面朝下条目」，其后「对手埋伏**计数**」不变。依据：本条正是子项 1 要兑现的那句话，不改则同一段自相矛盾。`systems/adventure-event/combat/_index.md` 与 `systems/enemies/_index.md` 的措辞不含「战场全部条目」字样，无需改动。
- **新校验行落在哪张表** → `deck/common-properties.md` 的「加载期校验（坏数据启动即失败）」表（目标 / 作用域小节内），即 `HandCard` 那两行所在的同一张。依据：同判据同表，跨表放置会让两条同源规则分居两处。
- **`Side != Self` 顺带禁掉 `Any`** → 按最严收口并写明一句。`SideConstraint` 取值域为 `Any / Self / Opponent`，`!= Self` 即同时拦下 `Any`；与同库既有的「`MoveCardEffect`：`Selection == Chosen` 且 `Side != Self` → `PushError`，日后放宽是纯加法」同款处置。
- **视图内 `entryId` 引用不得假定可解析** → 写进 `Battlefield` 的填充纪律旁，**不新增字段**。依据：埋伏触发后进弃牌堆 ⇒ 该 `entryId` 迟早会离场，「引用恒可解析」本就不成立，子项 1 只是让它提前发生。
- **`ux/combat-ux.md` 需一处轻改写而非仅补回链** → 现文「对手侧的面朝下条目**不渲染**任何条目级入口或标记」预设该条目在视图里但不渲染；子项 1 之后它根本不入视图。改写为「不进入战斗态视图（契约面已整条剔除）」+ 一句指向契约面的回链，不复述字段面。同段「己方面朝下条目照常有启动入口」与埋伏标记必做项、竖屏专场归属三处原样保留。
- **`terminology.md` 无改动** —— 核对成立，「埋伏」条与本纪律无冲突。

## Open questions

- 无。（本次结论完整。`BattlefieldEntryView` 与 `StackEntryView` 的**完整**字段面仍未成文，但那是一项独立的登记缺口、不阻塞本纪律 —— 本次只定其中三格，届时一次性成文须与这三格合并而非另立。）

## Notes / triage

- 路由：`systems/services/combat-service.md`（AI 决策纯函数条的输入面 · `CombatSnapshot` / `SideSnapshot` / `PendingTargetRequest` 签名与填充纪律 · `StackEntryView` 首格 · `CombatFeedEntry` 字段面与战报段）；`systems/character-profile/deck/common-properties.md`（加载期校验表 +1 行、`EntryFilter.IncludeFaceDown` 纪律段拆两半）；`ux/combat-ux.md`（战场区对手侧措辞 + 回链）。
- 存档面零影响：`ActiveCombat` 保留全量真值（`faceDown` 原样是持久字段），本次只约束运行时视图与战报流，两者均明写不落存档 ⇒ 无 schema bump、空迁移。
- 双视角缓存不受影响：两份缓存本就按 `ViewerSide` 分别持有、同一次组装产出，过滤在各自那次组装内完成，不新增结构、不落热路径分配面。
- 不跨库：本题全在客户端进程内（战斗视图、加载期校验、呈现层），不触及任何客户端 ↔ 后端报文。
