# 修行等级体系 · 意图三档揭示 · 决策点存档 · CharacterManager

- id: 2026-07-30b-combat-level-intent-and-decision-point-saves
- date: 2026-07-30
- topic: 20-systems/game-progression、20-systems/services/combat-service、20-systems/services/life-cycle-service、20-systems/adventure-event/combat|practice|finale、20-systems/character-profile（mana / deck / _index）、20-systems/player-profile/enemy-codex（新增）、40-ux/combat-ux、terminology、architecture / program-overview
- status: distilled
- distilled-to: terminology.md, program-overview.md, 20-systems/architecture.md, 20-systems/common-properties.md, 20-systems/game-progression.md, 20-systems/balance.md, 20-systems/services/_index.md, 20-systems/services/combat-service.md, 20-systems/services/life-cycle-service.md, 20-systems/adventure-event/combat/_index.md, 20-systems/adventure-event/practice/_index.md, 20-systems/adventure-event/finale/_index.md, 20-systems/character-profile/_index.md, 20-systems/character-profile/mana.md, 20-systems/character-profile/deck/_index.md, 20-systems/player-profile/_index.md, 20-systems/player-profile/enemy-codex/（新增）, 40-ux/combat-ux.md, open-questions.md, answer-logs/log-0730b.md

## Intent（distilled）

一句话：**引入「境界内等级」并把它接成全局等级序，用它驱动敌人意图的三档揭示；战斗改为按决策点存档（据此取消草案里的事件 / 篇章重试上限，重试仍归 ADR-0004）；combat-service 新增 CharacterManager 与 EnemyManager 平级、DeckManager 降为每参战方一份；mana 改为每回合恢复至 manaLimit 且 manaLimit 由事件推拉；新增账号级敌人图鉴。**

### 1. 修行等级体系（新概念）

**等级 = 境界内的层级**，与境界（realm）合成角色的修行位置：

| 境界 | 层级 | 数量 |
|------|------|------|
| 炼气 Qi Refining | 1 层 ~ 13 层 | 13 |
| 筑基 Foundation Establishment | 初期 / 中期 / 后期 / 巅峰 | 4 |
| 金丹 Golden Core | 初期 / 中期 / 后期 / 巅峰 | 4 |
| 元婴 Nascent Soul | 初期（终点） | 1 |

- **篇章跨度：** 第一篇章 1→13（炼气内），第二篇章 1→4（筑基内），第三篇章 1→4（金丹内）。
- **进阶即归位初期。** 每个篇章结束、突破进入下一境界后，等级一律重置为**新境界的初期（level 1）**——**元婴亦然**（元婴只有初期，且是终点）。

**规则建立在全局等级序上（定案）。** 一切「谁比谁高几级」的比较（首先是意图揭示判据）都在**跨境界连续的全局序**上做，而不是拿两个境界内的层号直接相减——否则「筑基中期(2) vs 金丹初期(1)」会得出敌人更低的荒谬结论。全局序由「境界基数 + 境界内层级」合成，形态：

```
炼气 1层..13层  →  全局 1..13
筑基 初期..巅峰 →  全局 14..17
金丹 初期..巅峰 →  全局 18..21
元婴 初期       →  全局 22
```

具体基数为可调数值（归 `20-systems/balance.md`）；**等级的成长途径尚未定义**，见 Open questions。

### 2. 敌人意图：三档揭示（取代「通常不揭示」）

**推翻 07-30 的「敌人意图通常不向玩家揭示」。** 新规则：**默认揭示，越级才降级**，降级分三档：

| 全局等级差（敌人 − 角色） | 玩家看到 |
|---|---|
| 在**篇章容差**内 | **完整意图**：动作类型 + 精确数值 |
| 超出容差 | **仅类别**：攻击 / 防御 / 增益 / 特殊——有符号无数值 |
| 大幅越级 | **完全无信息**，且**不提供任何替代线索** |

- **篇章容差：** 第一篇章 = 差值 **> 3** 才算「远高于」（即差 ≤ 3 仍给完整意图）；第二 / 第三篇章 = **高一级即算**（即差 ≤ 0 才给完整意图）。
- **「仅类别」与「完全无信息」的分界值未定**，见 Open questions。
- **不做「状态可读」补偿。** 「以敌人身上的显式状态标记（蓄力 / 凝聚 / 破绽）替代意图」的补偿方案**已否决**——大幅越级就是彻底的信息黑箱。

### 3. 探查（probe）：把情报做成可花代价获取的东西

**采纳方向，但实现搁置。** 「以代价换取当回合敌人意图」的效果定名为 **探查**。它是意图揭示之外的第二条信息通道（意图揭示由等级差被动决定，探查由玩家主动付出获得）。

**具体形态归卡牌 / 技能内容的横向扩展阶段**——花费形式（mana / 弃牌 / 每场次数）、授予途径（卡牌、能力、道具）、可探查到哪一档（完整 or 仅类别）均**在本阶段暂不设计**。这也是草案「某些能力或道具可以授予窥视意图」的落点：窥视意图 = 探查能力的一种授予形式。

### 4. 敌人图鉴（EnemyCodex，账号级）

类 Pokédex 的收集：**记录玩家已遭遇过的敌人信息**，跨轮回持久，归 **PlayerProfile**（新建 `20-systems/player-profile/enemy-codex/`）。

**与意图体系分层（采纳）：**

- **图鉴给「静态知识」** —— 这个敌人**会做哪些事**（招式 / 意图类型池、大致强度）。
- **意图揭示与探查给「动态情报」** —— 它**这一回合**要做哪件事。

两者互补而不互相替代：图鉴再全也不告诉你本回合的具体选择，因此**图鉴不架空越级时的意图黑箱**。

### 5. combat-service 结构：新增 CharacterManager，DeckManager 降为每参战方一份

- **CharacterManager 与 EnemyManager 平级**，管理玩家一侧的对战信息。
- **两者共享大量接口定义**（参战方的公共面：生命 / mana、卡组、状态、出牌）；**差异在驱动方式**——EnemyManager 含**代理操作**（AI 行为选择、意图生成），CharacterManager **监听玩家操作**。
- **EnemyManager 内部不再细分职能**（敌人实例与状态 / AI 行为选择 / 意图生成三者合一，定案）。
- **DeckManager 不再是与之平级的组件**，而是 **CharacterManager 与 EnemyManager 各自持有的子组件：每个 character / 每个 enemy 各有一个卡组。** 敌人也出牌，且可带定制卡组。

### 6. Practice / Finale = 战斗的变体（推翻 Finale 的「独立结算」表述）

- **Practice** 与 **Finale** 都使用 EnemyManager + CharacterManager，是 combat 的变体。
- **Finale 大部分情况是战斗。** 渡劫的对手 = **天劫**，天劫**是一个 Enemy**，带**定制卡组**。此前「Finale 走独立结算，而非 Combat 的战斗结算」的表述**作废**——正确表述是：**同一套战斗框架 + 独立的胜负条件与奖励结构**。
- **少部分 Finale 不是战斗**，形态留待日后定制。

### 7. 存档：事件过程按决策点落存档（推翻「战斗过程不落存档点」）

草案原意是「战斗过程不落存档点，另加事件 / 篇章重试次数上限来防退出重试作弊」。**改为更直接的做法：事件过程中（含战斗）按决策点落存档。**

- **决策点存档**使「退出重进」得到的是**同一个局面、同一份 RNG 状态**，作弊窗口从根上关闭，无需再用重试计数去堵。
- 因此**草案中的「同一事件重试 < 10 次、篇章重试总数 < 30 次、超限强制 defeat」不予采纳**。
- **重试模型依然按 `50-decisions/ADR-0004`**（第一篇章无限 / 第二篇章 3 / 第三篇章 1），不变。
- **重试计数只保留「每个角色的篇章重试」**，且**只有角色进入第二 / 第三篇章后才存在**：第一篇章是**随机生成起始角色**的重试，**不能指定重试同一个角色**。
- **`selectCost` 不回滚。** 选中事件时施加的成本（含 `lifeSpanCost`）一经施加即成事实，中途退出不退还。

### 8. mana：每回合恢复至上限；上限由事件推拉（推翻「逐步恢复」）

- **战斗中每回合开始，mana 自动恢复到角色当前的 `manaLimit`**（满值）。此前「上限 + 逐步恢复、非每回合全额刷满」的定案**作废**。
- **`manaLimit` 的变动属于事件的 cost / reward 范畴**——由 AdventureEvent 的产出 / 成本推高或压低，**不是随境界自动成长**。
- **`manaLimit` 下降时，战斗内每回合的恢复上限随之下降。**
- 推论：**mana 不再是战斗内的节奏来源**，而是每回合固定的行动预算；构筑的长期成长体现在 `manaLimit` 上，节奏张力须由卡牌效果与敌人行为提供。

### 9. 术语：power 定译「能力」

`PlayerPower` 的中文定名为**玩家能力**，`power` 单独出现时译**能力**。

## Open questions

- **等级的成长途径未定义。** 章内从 1 爬到 13（炼气）/ 1 到 4（筑基 · 金丹）靠什么？若与 `manaLimit` 同属事件 cost / reward，则一章内需要足够多的「升级型产出」，这会反向约束该章的事件总数与寿元预算花法。**留待下一次 session。** → `20-systems/game-progression.md`、`20-systems/balance.md`。
- **全局等级序的具体基数。** 「炼气 1–13 / 筑基 14–17 / 金丹 18–21 / 元婴 22」是从阶梯直接推出的最简形态；是否要在境界之间留出跳变（例如突破时全局等级 +3 以表现境界鸿沟）未定。→ `20-systems/balance.md`。
- **「仅类别」与「完全无信息」的分界。** 三档结构已定、篇章容差已定（ch1 > 3 / ch2 · ch3 ≥ 1 进入降级），但**从「仅类别」进一步跌到「完全无信息」的等级差阈值未陈述**。→ `20-systems/services/combat-service.md`、`40-ux/combat-ux.md`。
- **意图类别的枚举。** 「攻击 / 防御 / 增益 / 特殊」是第二档要展示的粒度，其正式枚举与敌人行为的映射未定。→ `20-systems/adventure-event/combat/`。
- **探查的实现形态。** 定名已成、方向已定，但花费形式、授予途径、可探查档位均**本阶段搁置**，归卡牌 / 技能内容的横向扩展。→ `20-systems/character-profile/deck/`、`20-systems/player-profile/player-power/`。
- **敌人图鉴的字段与解锁粒度。** 记录哪些字段（招式池 / 意图类型池 / 强度区间 / 遭遇与击败次数）、解锁粒度（遭遇即记 vs 击败才记 vs 逐招式解锁）、是否影响战斗内呈现（图鉴已收录的招式是否在第二档下额外可读）均未定。→ `20-systems/player-profile/enemy-codex/`。
- **DeckManager 降为子组件与「两级层次 service ⊃ manager」的措辞冲突。** 既定架构明写「只有两级职能层次，不设第三级」；而 DeckManager 现在是 CharacterManager / EnemyManager 各自持有、且**每参战方一个实例**。两条出路：① 把它从「manager」改称为参战方内部的普通组件（保住两级规则），② 承认 combat-service 内存在第三级并修订该规则。**本次按 ① 的语义记录（DeckManager 不再列入 combat-service 的 manager 清单），但正式措辞待确认。** → `20-systems/architecture.md`、`20-systems/services/_index.md`。
- **`attemptIndex` 的防护动机被决策点存档消解。** 既定的战斗内 RNG 派生式 `Hash64(combatStreamSeed, eventId, attemptIndex)` 是为防「退出重进重掷」；决策点存档 + RNG `State` 持久化已从根上关闭该窗口。剩下的问题收窄为：**篇章重试（ADR-0004）重开同一篇章时，同名事件是否应换一套战斗随机**——若应，`attemptIndex` 保留并取「篇章重试的第几次」；若不应，该派生层可整个去掉。→ `20-systems/common-properties.md`、`20-systems/services/life-cycle-service.md`。
- **决策点的粒度。** 「按决策点存档」已定，但战斗内的决策点具体指哪些位置（每回合开始？每次出牌后？每次目标选择后？）未定；粒度直接决定存档写入频率与 push 防抖压力。→ `20-systems/services/combat-service.md`、`20-systems/services/sync-service.md`。
- **敌人等级的来源。** 意图规则以「敌人等级」为判据，但敌人等级是 `EnemyData` 上的固定字段，还是由遭遇战 / 篇章 / 角色等级缩放算出未定。→ `20-systems/adventure-event/combat/`、`20-systems/balance.md`。
- **`探查` 的英文 / 代码标识符。** 暂记为 `probe`，待正式确认。→ `terminology.md`。

## Notes / triage

- **本次推翻三处既有定案**，均按「活文档只保留最新设计」直接重写替换：① 意图「通常不揭示」→ 三档揭示；② mana「逐步恢复、非全额刷满」→ 每回合恢复至上限；③ Finale「独立结算，而非战斗结算」→ 战斗变体（天劫为 Enemy）。
- **草案中的「事件重试 < 10 / 篇章重试 < 30 / 超限强制 defeat」未采纳**——其目的（防退出重试作弊）已由决策点存档达成，ADR-0004 因此**无需改动**。
- **答结的待答项** 6 条已移出 `open-questions.md`，记入 `answer-logs/log-0730b.md`。
