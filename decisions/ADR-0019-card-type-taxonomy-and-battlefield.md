# ADR-0019 — 卡牌类型五分、异能三分、永久物；战场划线判据 =「是否在场上生效」

- **状态：** Accepted
- **日期：** 2026-08-11
- **来源：** handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md · handoffs/2026-08-04b-mtg-loanwords-card-types-and-intent-snapshot.md · handoffs/2026-08-11c-combat-turn-flow-fatigue-and-card-type-reduction.md

## 背景

战斗体系借用了一批 MTG 词汇（stack、permanent、static / activated / triggered ability），但本作已移除交互与优先权，直接照搬会带来对不上的语义。同时卡牌类型若不定，`CardData` 的 schema 写不出来；战场与两个参战方 manager 的划线此前卡在「属于谁」这个划不开的判据上。

## 决策

**① 卡牌类型 = 五值枚举 `CardType`，按「所在区 + 结算后去处」切分：**

| 值 | 中文 | 形态 |
|---|---|---|
| `Sorcery` | 法术 | 一次性，进弃牌堆 |
| `Enchantment` | 阵法 | 永久物落战场（埋伏是其次类型） |
| `Item` | 法宝 / 古宝 | 不洗进卡组，存于储物袋 |
| `Power` | 神通 / 法则 | 开局直接入场的受保护永久物 |
| `Affliction` | 业障 | 可打出但无正面效果，唯一作用是把自己送进弃牌堆 |

**三个来源区各自绕开的东西不同**，这是五类之间最本质的结构差别：卡组（受抽牌运制约）· 持有的道具（不受抽牌运制约）· 开局入场（无需玩家动作）。**从卡组打出的永久物只有阵法一类**，故永久物不区分实体 / 非实体。

**② 异能三分：静止式 / 启动式 / 触发式。** 静止式不入栈、载体在战场上即持续生效；启动式启动后压栈，**可用窗口 = 自己回合的行动阶段、栈为空时**（与出牌完全同窗口）；触发式命中后由 StackManager 压栈。**载体说的是「挂在谁身上」，异能类型说的是「怎么生效」**，两者正交。

**③ 永久物 = 落在战场上、无限期存在直到被移除或战斗结束的条目**（阵法 / `Power`）；非永久条目 = 带生命周期标记的持续状态。**与 MTG 的出入写明：** MTG 的 permanent 是区的成员资格，**本作的永久物只是战场条目的一个子集**。

**④ 战场与两个参战方 manager 的划线判据 = 「是否在场上生效」，不是「属于谁」。** 在场上生效、可被针对 / 查询、需在结束阶段被清理、需进决策点存档 → **战场条目，归 BattlefieldManager**，条目自带 `OwnerSide`；参战方的私有资源与牌堆（mana、道念、手牌、卡组、本场可用道具）→ 归 CharacterManager / EnemyManager。**单一战场记录，不分双场区容器；读侧统一（`CombatSnapshot`）、写侧分权。**

逐条推论、埋伏形态与目标合法性求解见 `systems/services/combat-service.md`。

## 理由

- **「属于谁」划不开**——附着在某一方身上的持续状态（「我方本回合所有牌 +1 道念」）要被针对、要被清理、要进存档，三件事全是战场的活。**「属于谁」只是条目的一个字段，不是它的住处**，这正是该问题此前卡住的地方。
- **单一记录 + `OwnerSide`**：跨归属方的触发（埋伏监听「对手打出牌时」）与全场查询（「场上所有阵法」）在单一记录下是一次遍历，分成两个容器则每次查询都要合并；呈现层按 `OwnerSide` 分区渲染即可。
- **启动式异能不引入交互**（关键自洽点）：它的窗口就是出牌那一个窗口，不构成「在对手回合插手」的通道；它还给 mana 第二个花费去向，缓解手牌不足时的沉没成本。
- **永久物子集化的收益是清理边界明确**：结束阶段只清理非永久条目中标记为回合内的那些，永远不碰永久物，故不存在「永久物会不会被误清」的歧义；且「可被移除」只对永久物有意义，目标合法性因此有了类型级判据。
- **本条只定下不定就无法写 schema 的结构性差别**，类型间的具体差异化留待日后。

## 备选方案

- **BattlefieldManager 提为参战方之上一层** — 否决四条：会变成 god object；级联降级把 `DeckModule` 压到第四级、强迫回答尚无判据的问题；层级词表的拆分轴是生命周期层 + 行为边界，而战场与两个参战方的生命周期完全同长；「拥有整场信息的顶点」已由 combat-service + `CombatSnapshot` 承担。
- **双方各一个场区容器** — 否决：跨归属方触发与全场查询每次都要合并。
- **引入 MTG 的指挥区（command zone）安置 `Power`** — 否决：战斗内已有六处位置，为一类不可交互的条目再开第七处，收益不抵竖屏 UI 与存档形态的成本。
- **照搬 MTG 的 permanent = 区成员资格** — 否决：本作战场上还住着带生命周期标记的持续状态，两者形态不同。

## 后果

- **`CardType` 五值枚举是内容体系的根**：`CardData` 的 schema、目标合法性筛选、结束阶段清理边界、三条来源路径的组装流程全部挂在它上面。
- **combat-service 第一次需要读 PlayerProfile**：参战方组装要同时读 CharacterProfile 的神通列表与 PlayerProfile 的法则列表（`Power` 入场的两条与门 = `status == 开启` 且 `UsableScene` 含 `InCombat`）。
- **`Power` 一律受保护**（战场条目上的 `IsProtected` 在 `CardType.Power` 落场时统一置 true，不由 `PowerData` 逐条目声明），唯一后门 = 效果侧声明 `IgnoresProtection`，其稀缺性归内容侧纪律（`PushWarning` 软检查）。
- **道具是战斗内唯一会即时写 Profile 的卡牌行为**：古宝的使用次数即时经 `ProfileManager.TryApply` 写入，堵死「用完退出重进恢复次数」。
- **`CardType` / `Subtypes` 不落存档**（静态字段，由 `CardId` 解析）。
- 影响文档：`systems/services/combat-service.md`（权威）· `systems/character-profile/deck/` · `systems/character-profile/item/` · `systems/character-profile/power/` · `systems/architecture.md`（战场划线判据的定义段）· `terminology.md`（借词定名）· `ux/combat-ux.md`。
