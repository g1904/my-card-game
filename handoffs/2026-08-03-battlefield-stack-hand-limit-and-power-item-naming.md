# 战场与栈成为独立 manager · 满手不抽 · 触发载体开放 · 能力 / 道具中文重定名 · 赋级上界

- id: 2026-08-03-battlefield-stack-hand-limit-and-power-item-naming
- date: 2026-08-03
- topic: systems/services/combat-service、systems/character-profile/deck、systems/adventure-event/combat、systems/scoring、systems/services/future-event-service、terminology、ux/combat-ux
- status: distilled
- distilled-to: terminology.md, systems/services/combat-service.md, systems/services/_index.md, systems/services/future-event-service.md, systems/architecture.md, systems/character-profile/deck/_index.md, systems/character-profile/power/_index.md, systems/character-profile/item/_index.md, systems/character-profile/_index.md, systems/adventure-event/combat/_index.md, systems/scoring.md, systems/balance.md, systems/player-profile/player-power/_index.md, systems/player-profile/player-item/_index.md, systems/player-profile/_index.md, systems/player-profile/codex/_index.md, systems/_index.md, ux/combat-ux.md, ux/screen-flow.md, program-overview.md, open-questions/01-combat.md, open-questions/07-codex-monetization.md, answer-logs/log-0803.md, `systems/services/（combat-service.md, _index.md, future-event-service.md）`, `systems/character-profile/（_index.md, deck/_index.md, power/_index.md, item/_index.md）`, `systems/player-profile/（_index.md, player-power/_index.md, player-item/_index.md, codex/_index.md）`, `ux/（combat-ux.md, screen-flow.md）`, `open-questions.md`, `open-questions/（01-combat.md, 07-codex-monetization.md, update-log.md）`

## Intent（distilled）

一句话：**战斗内的「公共区」被显式建模——引入 battlefield（战场）并把它与栈各自升为一个 manager；同时答结四条承重残留（满手不抽、触发载体开放、道念截断在每次结算、敌人赋级上界），并把 power / item 两层四个概念的中文定名整体改写为仙侠词。**

### 1. 手牌达到上限 = 抽不进（已定案）

**满手时抽牌抽不进——牌留在抽牌堆，这次抽牌无事发生。**「加入手牌」类效果同理：目标进不了手牌，该次效果落空。

- **不引入「抽出即弃」与「直接销毁」两条路线**：手牌上限因此是一条**纯上界**，不产生任何弃牌堆流量、不消耗抽牌堆。
- **推论 ①：弃牌不是一条被规则强制的动作原语。** 回合末不弃、满手不弃——弃牌堆只由「打出后进弃牌堆」与「卡牌效果显式弃牌」填充。
- **推论 ②：抽牌堆顺序不被满手情形扰动**，seeded 洗牌的确定性不因此分叉；「本回合抽 N 张」在满手时等价于抽 0 张。
- **推论 ③：满手的代价是 tempo 而非资源。** 牌没丢，只是这一拍没拿到——手牌上限成为一条**节奏约束**（逼玩家出牌腾位），而不是惩罚。
- **推论 ④：UI 必须表达「这次没抽进」。** 规则已定，剩下的是表现形式（见 `ux/combat-ux.md`）。
- **上限数值仍未给**（敌人侧是否同值亦未给）。

### 2. 触发式效果的载体 = 开放式多载体（已定案）

**触发器不是卡牌的专属属性。** 牌上的触发器、**场上的持续状态**、**CharacterPower（神通）** 都可能承载触发式效果——且**清单开放**，日后可再增载体。

- **推论 ①：需要一个统一的触发注册 / 匹配面。** 载体多样意味着「谁在监听哪个时点」不能由某一类载体自己管，否则每类载体各写一套匹配逻辑。
- **推论 ②：该注册面坐在 battlefield 上。** 「场上有哪些触发器在等待、挂在谁身上」正是「场上的准确数据」的一部分（见下一节）。
- **推论 ③：CharacterPower 承载触发 ⇒ 轮回级能力必须能被战斗内读到。** 此前神通只被描述为轮回内 build 的组件；现在参战方组装时要把角色持有的神通**注册进战场**，combat-service 因此要读 CharacterProfile 上的这份列表。
- **推论 ④：压栈者与载体解耦。** 触发一旦命中，把被触发的能力压入栈的是 **StackManager**，与它挂在哪个载体上无关。
- **仍待定：** 触发条件能否写「对手的回合开始时」这类跨归属方的时点；以及**账号级的 PlayerPower（法则）能否也承载战斗内触发**——既然轮回级的神通能，法则大概率也能，但未陈述。

### 3. 引入 battlefield（战场），并新增两个 manager（已定案 · 承重）

**battlefield = 战斗的公共区**，记录**场上的全部准确数据**：有哪些卡牌正在生效、有哪些持续状态、有哪些触发器在等待。配套新增两个第二级组件：**BattlefieldManager** 与 **StackManager**。

| 组件 | 职责 |
|---|---|
| **BattlefieldManager** | 战场：场上生效中的卡牌 / 持续状态 / 触发器注册面，及其生命周期（回合内 / 跨回合）标记与清理 |
| **StackManager** | 栈：压栈、LIFO 结算、连锁触发的解决顺序 |

- **推论 ①：栈与战场是两个不同的区。** **栈 = 等待结算的队列；战场 = 已结算并正在生效的东西。** 结算的完整路径因此是：**打出 → 入栈 →（LIFO）弹出结算 → 效果施加 →（若是持续效果）落到战场**。
- **推论 ②：这给了「回合内状态 / 跨回合状态」一个确切落点。** 它们是**战场上的条目**，携带生命周期标记；结束步「清理回合内状态」= 清掉战场上标记为回合内的条目——此前悬空的「回合内状态判定边界」有了归属结构（取值仍待定）。
- **推论 ③：TurnManager 回落为纯粹的回合状态机。** 栈的持有与结算从它身上拆走，它只管「轮到谁、走到三步的哪一步」。
- **推论 ④：战斗内状态出现第三类持有者。** 属于**某一方**的东西（mana、道念、手牌、卡组）仍归 CharacterManager / EnemyManager；**已离开手牌、正在场上生效**的东西归 BattlefieldManager。边界的确切划线未陈述，见 Open questions。
- **推论 ⑤：决策点存档必须能恢复战场。** 「退出重进得到同一局面」要求战场条目可序列化。**栈则可能不必落存档**——「栈非空时双方都不能出牌」意味着任何可退出的时刻栈都应为空；这一点待确认。
- **推论 ⑥：EnemyManager 规划意图时要读战场。** 「本回合出牌的合并结果」会被场上的持续状态改写，故回合级一次性规划必须以战场当前状态为输入。
- **推论 ⑦：呈现层新增一个区。** 战斗屏此前已需表达栈（触发连锁可读性），现在还要表达战场——竖屏窄高下「战场 / 栈 / 手牌」三区的排布压力上升。

### 4. 道念下限 0 = 每次结算时截断（已定案）

多个削减效果同时在栈上时，**饱和减法在每一次结算时就截断**，不是全栈结算完后再截断。

- **推论 ①：更保护落后方，且差异是可算的。** 对方道念 5、栈上有「削 8」与「+3」：每次结算截断 → `5-8 → 0`，再 `+3 → 3`；全栈后截断 → `5-8+3 = 0`。**溢出的削减量不结转**，故落后方不会被一次连锁按在 0 上。
- **推论 ②：LIFO 顺序因此对最终结果有实际影响**——削减与产出交错时结算顺序改变结果，这把「栈序是卡牌设计可利用的资源」从原则变成了具体的算术。
- **推论 ③：`PlayResult` 必须携带本次的实际削减量。** 截断发生在每一次结算，故每次结算都是一个可观测事件，「意图削减量 vs 实际削减量」的差在连锁中必然出现。

### 5. 敌人赋级的上界 = 高一个大境界的初期（已定案）

物化赋级的天花板：**敌人最高只能是比角色当前境界高一个大境界的初期**。例：**炼气期的角色，最高遇到筑基初期**。

- **上界按境界给，不按等级差给。** 它是一条**绝对天花板**（由角色所处**境界**决定），不是一条 `diff` 上限。
- **推论 ①：上界档的敌人必然是越阶 ⇒ 必然完全黑箱。** 按既定的意图规则（越阶 = 硬门），「本篇章可能遇到的最强敌人」天然没有任何意图信息——**最难的遭遇即最不可读**，这是规则的必然结果而非另加的设计。
- **推论 ②：Finale 的天劫等级由此有了自然候选。** 若 Finale 同受此上界约束，则天劫 = **下一境界的初期**——与「渡劫即突破到该境界」的叙事恰好吻合。待确认。
- **推论 ③：元婴（全局 22）无更高境界**，上界退化为同境界；且抵达元婴即轮回终点，实际不产生遭遇。
- **推论 ④：上界只约束「最高能出到几级」，不约束分布。** 多久出现一次上界档、以什么权重出现，仍归物化的加权规则。
- **⚠ 与「一次惨败不打穿耐久」的初衷存在算术冲突**，见 Open questions。

### 6. 中文定名重写：法则 / 古宝 / 神通 / 法宝（已定案）

power / item 两层四个概念的中文定名整体改写为仙侠词：

| 英文 / 代码 | 新中文定名 | 旧定名（作废） |
|---|---|---|
| `PlayerPower` | **法则** | 玩家能力 |
| `PlayerItem` | **古宝** | 玩家道具 |
| `CharacterPower` | **神通** | 角色能力 |
| `CharacterItem` | **法宝** | 角色道具 / 角色物品 |

- **推论 ①：「`power` 的中文通译 = 能力」作废。** 两层不再共用一个中文词根。
- **推论 ②：中文名不再表达层级对称。** 账号级 ↔ 轮回级的对称此后**只在英文标识符上成立**（`Player*` / `Character*`）；中文侧是四个彼此独立的仙侠词。**故 UI 文案不能靠中文名传达「这是账号级的」**——层级须由界面归属（元进程界面 vs 轮回内界面）承担。
- **推论 ③：图鉴族五本随之改名**：敌人图鉴 / **神通**图鉴 / **法则**图鉴 / **法宝**图鉴 / **古宝**图鉴。
- **推论 ④：新词的语感与生命周期分界同向。** 法则（世界规则层，恒常）之于神通（个人术法，一时），古宝（传世之物）之于法宝（随身之器）——账号级的更"恒"、轮回级的更"随身"，与既定的生命周期拆分轴读感一致。

## Open questions

- **⚠ 赋级上界与 lifeTotal 的算术冲突（承重 · 需用户裁决）。** 上界按境界给，故**境界内低层角色面对的最坏差距远大于高层角色**：炼气一层（`baseMomentum` 1）对筑基初期（20）= 开局落后 19，而炼气 lifeTotal 只有 10/10 —— 一次惨败直接打穿耐久，**恰是这条上界原本要规避的情形**。可能的收口：① 再叠一条相对 `diff` 上界；② 只在境界后期才允许出到上界档（把上界与角色在境界内的进度挂钩）；③ 抬 `lifeTotalLimit` 的境界基线。未定。→ `systems/services/future-event-service.md`、`systems/balance.md`、`systems/character-profile/life-total.md`。
- **BattlefieldManager 与两个参战方 manager 的边界划线。** 「属于某一方的归参战方、场上生效的归战场」是推演出的划法，未经陈述：附着在某一方身上的持续状态（例：「我方本回合所有牌 +1 道念」）算战场条目还是参战方状态？双方各自的场区是否分开记录？→ `systems/services/combat-service.md`。
- **战场与栈的存档形态。** 决策点存档要求局面可恢复 ⇒ 战场条目须可序列化；**栈是否需要落存档**取决于「决策点是否总落在栈为空的时刻」（栈非空时双方都不能出牌，故很可能是）。未确认。→ `systems/services/combat-service.md`、`sync-service.md`。
- **触发条件能否跨归属方。** 「对手的回合开始时」这类时点——时点本身有归属方，但监听方未必是归属方。（08-02b 提出，本次未答。）→ `systems/character-profile/deck/`、`systems/services/combat-service.md`。
- **PlayerPower（法则）能否承载战斗内触发。** CharacterPower（神通）已确认可承载；账号级的法则未陈述。若可，则 combat-service 还要读 PlayerProfile 一侧。→ `systems/player-profile/player-power/`、`systems/services/combat-service.md`。
- **「加入手牌」落空时，凭空生成的牌去哪。** 从抽牌堆抽的情形已明确（留在堆里）；但若效果是**生成一张新牌**（token 类）或**从弃牌堆 / 牌库外取牌**，满手时该牌是根本不产生、还是产生后进弃牌堆？→ `systems/character-profile/deck/`。
- **`CharacterItem` 的标识符单复数不一致。** 中文定名「法宝」对应 `CharacterItem`（单数），但全库既有写法是 `List<CharacterItems>`（复数）。是否统一为 `CharacterItem` 未定。→ `terminology.md`、`systems/character-profile/item/`。
- **Finale 的天劫是否同受赋级上界约束。** 若受约束则天劫 = 下一境界初期（与叙事吻合）；若不受则天劫可任意越阶。→ `systems/adventure-event/finale/`。

## Notes / triage

- **答结六条**（满手不抽 / 触发载体开放 / 道念每次结算截断 / 赋级上界 / 中文重定名 / 战场与栈成为独立 manager），记入 `answer-logs/log-0803.md`。
- **推翻一处既有定名**：`power` 的中文通译「能力」（07-30b 定）作废，四个概念各自定名。
- **combat-service 的 manager 由三个增至五个**（TurnManager、CharacterManager、EnemyManager、**BattlefieldManager**、**StackManager**），层级表、服务清单与运行链路图一并更新。
- 顺手清理两处遗留失真：`systems/balance.md` 的意图分界值仍为 08-01b 的旧取值（已按 08-02c 重写）；`systems/architecture.md` 待决问题里的「道念差换算的计算归属」已于 08-02 答定（归 combat-service），已移除。
