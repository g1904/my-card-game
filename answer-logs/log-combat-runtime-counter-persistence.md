# Answer log combat-runtime-counter-persistence

- 日期：2026-08-22
- 来源：`inbox/solution-draft-combat-runtime-counter-persistence.md` → `handoffs/2026-08-22-combat-runtime-counter-persistence.md`
- 移出条数：1

---

**战斗内运行态的决策点存档形态（`CharacterPower` / `PlayerPower` 的「本场已触发 N 次」、`PlayerItem` / `CharacterItem` 的「本场已用掉哪些、各自剩余次数」）** → **两块运行态的形态齐备，整条移出。**
承载字段沿用既有：战场条目 `counters : Dictionary<string,int>` · `CardInstanceSave.Counters` · `CombatItemSave(ItemId, UsesThisCombat)`；**剩余次数不落战斗存档**（唯一权威在 Profile 侧持有条目的 `Charges`，即时写）。本次补齐三块：① `counters` 键约定 `<abilityId>["#"<子名>]`，`#` 前一段须经 `ContentRegistry` 解析出 `AbilityData`，值域 `>= 0`、为 0 不写入，`AbilityData.Id` 不得含 `#`（加载期 `PushError`），当前仅此一种键形态；② 消费面 `GetCounter` / `BumpCounter` 落 BattlefieldManager，计数只在**弹栈结算成功后** +1（调用点唯一、落 StackManager 结算收口回调），`ActivationCost` 已付但 fizzle 不吃配额、成本不退，配额闸门宣告 + 结算**双查**；③ 读档校验四检查点扩为六，新增「`counters` 值为负 / `UsesThisCombat < 0` → `PushError` + 抛」「`CombatItemSave.ItemId` 不在重建结果内 → `PushWarning` + 丢弃该条」，`counters` 键悬空**走既有校验 ②（`PushError`）、不开例外**。
（归档去向：`systems/services/combat-service.md`「战斗存档：`ActiveCombat`」与「管理器」两节；`systems/character-profile/power/_index.md` 与 `systems/player-profile/player-item/_index.md` 的意图段。）

**剩余仍待答的部分**（作为新条目并回 `open-questions/01-combat.md`）：非异能计数器（关键字状态叠加层数等）的落点未表态；`CardInstanceSave.Counters` 的读写 API 待卡牌效果系统落地时再定；子计数器名的字符集正则待 `content/` 的 id 约定表成型时统一定。
