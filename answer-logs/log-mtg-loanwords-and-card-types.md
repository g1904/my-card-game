# Answer log mtg-loanwords-and-card-types

- 日期：2026-08-04
- 来源：`inbox/solution-draft-mtg-loanwords-and-card-types.md` → `handoffs/2026-08-04b-mtg-loanwords-card-types-and-intent-snapshot.md`
- 移出条数：**5**（另 1 条部分答定）

## 逐条

**借入的 MTG 术语清单与中文定名（第一批）** → **全部定名。** `sorcery speed` **不借、整条删除**（机制改由「出牌时机（唯一）」这条全局规则表述，规则不变）；三步定名为 **开始阶段 / 行动阶段 / 结束阶段**（`start step` / `action step` / `end step`，`main phase` 弃用——本作无双主阶段、无战斗步骤，对照系不存在）；**`resolve` = 结算**（专指栈上对象），**战斗收口处的「结算」改称「收口」（`settle`）**，一词两义就此消除；**`trigger` = 触发**。定名连带落定四个体系：**卡牌类型六分**（`Sorcery` 法术 / `Creature` 灵宠 / `Enchantment` 阵法 / `Item` 法宝·古宝 / `Power` 神通·法则 / `Affliction` 业障）、**异能三分**（静止式 / 启动式 / 触发式）、**永久物**（战场条目的子集，永不被结束阶段清理）、**次类型**（稳定字符串 id + `.tres` 注册表，非 C# 枚举）。（归档去向：`terminology.md`——删 1 条、改 6 条、新增一整节 20 条；`systems/character-profile/deck/_index.md` 与 `common-properties.md`；`systems/services/combat-service.md`）

**触发条件能否跨归属方** → **能。** 时点本身有归属方（「回合开始时」是某一方的），但**监听方不必是该归属方**——可写「对手的回合开始时」「对手打出牌时」（`TriggerOwnerScope { Self / Opponent / Either }`）。这是「规则体系须支持奥秘式埋伏牌」的逻辑前提；**埋伏 = 阵法的次类型**（面朝下、是永久物、触发后进弃牌堆、同名不可重复布置、对手只知计数不知内容），是本作**唯一一条在对手回合发生作用的通道**，且结算入口不变（StackManager 压栈）。（归档去向：`systems/services/combat-service.md`、`systems/character-profile/deck/_index.md`、`terminology.md`）

**PlayerPower（法则）能否承载战斗内触发** → **能。** 法则与神通走同一条路径，作为 `CardType.Power` **开局入场**（条件 = `status == 开启` 且 `UsableScene` 含 `InCombat`），是受保护的永久物。**故 combat-service 参战方组装时要读两个 Profile——这是它第一次需要读 PlayerProfile。** 战斗内异能因此成为法则的**第三条生效通道**（前两条 = capability flag / modifier pipeline），**允许但极其稀缺**：`InCombat` 法则应 ≤ 1/5（加载时统计、超标 `PushWarning`），强度偏体验改善与容错；**付费的战斗价值主要由古宝承载**（次数限制即节流阀）。（归档去向：`systems/player-profile/player-power/_index.md`、`systems/character-profile/power/_index.md`、`systems/services/combat-service.md`、`systems/monetization.md`、`systems/balance.md`）

**承诺与执行不一致时如何处理** → **不做处理。** **意图 = 按当时局面用公式推算出的预期决策链路的快照**，公布后不重算，**但不保证与执行一致**——敌人回合按执行时的真实局面求值，偏差是常态。三个候选解（跳过该张照打其余 / 降级执行 / 允许临场替换）**全部不采用**：它们都在为「让快照与执行对齐」造机制，而快照本不承担对齐义务。**EnemyManager 因此不需要一致性校验与回退逻辑**（三个候选里唯一不新增状态的解）。代价 = **呈现层承担解释责任**：意图语气改为「预估」、敌人回合执行过程须逐步可见。（归档去向：`systems/services/combat-service.md`、`systems/adventure-event/combat/_index.md`、`ux/combat-ux.md`、`terminology.md`）

**BattlefieldManager 与两个参战方 manager 的边界划线** → **判据 = 「是否在场上生效」，不是「属于谁」；层级不动。** 在场上生效、可被针对 / 查询、需在结束阶段清理、需进决策点存档 → **战场条目**（自带 `OwnerSide`）；参战方的私有资源与牌堆（mana / 道念 / 手牌 / 卡组 / 本场可用道具）→ 参战方 manager。故「我方本回合所有牌 +1 道念」是**战场条目**——**「属于谁」只是它的一个字段，不是它的住处**。**双方场区不分开记录**（单一战场记录 + `OwnerSide`）；**读侧统一**（`CombatSnapshot`）、**写侧分权**。**BattlefieldManager 不提级**（四条理由：god object、强迫回答 module 以下的下沉判据、层级词表的拆分轴不是信息范围、整场信息的顶点已由 combat-service 承担）。（归档去向：`systems/services/combat-service.md`、`systems/architecture.md`、`terminology.md`）

## 部分答定（剩余部分仍留在待答清单）

**「回合内状态」的判定边界** → **永久物二分排除了一半**：结束阶段**只清理非永久条目中标记为回合内的那些，永远不碰永久物**，「永久物会不会被误清」这个歧义消失。**仍待答**：非永久条目自身的标记取值、「持续到下回合结束」如何表达、非永久条目可否被针对 / 移除。仍留在 `open-questions/01-combat.md`。
