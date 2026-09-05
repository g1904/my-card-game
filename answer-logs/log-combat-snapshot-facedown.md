# Answer log combat-snapshot-facedown

- 日期：2026-09-03
- 来源：`inbox/archive/solution-draft-combat-snapshot-facedown.md` → `handoffs/2026-09-03-combat-snapshot-facedown.md`
- 移出条数：1

---

**`CombatSnapshot.Battlefield` 缺一条 `faceDown` 的按视角填充纪律 —— 对侧 `faceDown == true` 条目的内容格是否一律置空 / 置哨兵值，还是另立一个对侧专用的条目视图？** → 全部答定，且**两条候选均不采**，取第三路：

- **走向 = 对侧 `faceDown == true` 的条目整条不入 `Battlefield`。** 过滤判据 `entry.faceDown && entry.ownerSide != ViewerSide`；不变式「`Battlefield` 中不存在 `FaceDown == true && OwnerSide != ViewerSide` 的条目」⇒ 视图内 `FaceDown == true` 恒指观察方己方的埋伏。置空 / 哨兵把泄漏防线从结构降为约定（且与 `AmbushCount` 形成两个计数口径）；另立第二个条目视图与「`SideSnapshot` 单类型」「不为 AI 另立第二个投影类型」相抵。
- **公开面 = `SideSnapshot.AmbushCount` 唯一承载**，其定义按 `faceDown == true` 收口（不按次类型计数）、与过滤判据逐字同源；**不改名** `FaceDownCount`。
- **`BattlefieldEntryView` 保留 `FaceDown` 一格**（己方埋伏的折叠 / 逐条渲染与埋伏标记消费它）。
- **`Battlefield.Count` 不再等于场上条目总数**，按长度算总数须补对侧 `AmbushCount`；当前无此消费者，但已写进文档。
- **视图内的 `entryId` 引用不得假定可解析**（栈条目的 `sourceEntryId` 与 `CombatFeedEntry.CauseEntryId` 链可能指向已被剔除或已离场的条目）；不新增字段。
- **前提机械化**：`deck/common-properties.md` 的「加载期校验（坏数据启动即失败）」表 +1 行 —— `TargetSlot.Kind == BattlefieldEntry` 且 `Filter.IncludeFaceDown == true` 且 `Side != Self` → `PushError`（`!= Self` 连 `Any` 一并拦下，按最严收口）。`EffectScope` / `TriggerFilter` 两处的 `IncludeFaceDown` 仍为散文纪律。
- **揭示时刻不加翻面态、不加战场条目字段**：承接面 = 该次触发的栈条目 + `CombatFeedEntry(AbilityTrigger)`。为此两处各补一格 `SourceCardId` —— `StackEntryView`（该视图第一格成文的字段，不条件填充）与 `CombatFeedEntry`（`CardPlay` / `AbilityActivation` / `AbilityTrigger` 有卡牌来源时非空，`ItemUse` / `Fatigue` 为 `string.Empty`）。两条流均不落存档 ⇒ 零 schema 影响。
- **`CombatSnapshot.PendingTarget` 同补一条按视角的填充纪律**：仅当 `pending.controllerSide == ViewerSide` 时填充，否则恒 `null`，与另三条齐平。草稿据以宣称「它不是泄漏面」的理由（挂起要求 `controllerSide == Character` 故该格恒为观察方己方来源）在双视角投影下是假命题，不予采纳。
- **连带**：`combat-service.md` 的 AI「输入面限对称可见信息」由「战场全部条目」改写为「双方全部面朝上条目 + 己方面朝下条目」；`ux/combat-ux.md` 对手侧措辞由「不渲染任何条目级入口或标记」改写为「不进入战斗态视图」+ 指向契约面的回链。`terminology.md` 无改动。

归档去向：`systems/services/combat-service.md`（`CombatSnapshot` 小节 · 权威）· `systems/character-profile/deck/common-properties.md`（加载期校验表 + `EntryFilter` 纪律段）· `ux/combat-ux.md`（战场区措辞 + 回链）。

**仍开放（未随本条移出）**：`BattlefieldEntryView` 与 `StackEntryView` 的**完整**字段面仍未成文（本次只定其中三格）；该条目下的子条目「同专场的四项具体形态 —— 道具区 / 神通法则条 / 埋伏标记 / 卡牌类型标识」归竖屏分区专场，与本条无关，原样保留在待答清单。
