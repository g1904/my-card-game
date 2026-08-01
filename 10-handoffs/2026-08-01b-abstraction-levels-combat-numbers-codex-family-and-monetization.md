# 抽象层级命名 · 战斗数值骨架 · 图鉴族 · 商业化

- id: 2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization
- date: 2026-08-01
- topic: 20-systems/architecture · services/**（combat / future-event / life-cycle）· scoring · balance · game-progression · character-profile/life-total · player-profile/codex ⊃ 五图鉴 · player-profile/player-power · monetization（新增）· adventure-event/combat · 40-ux/combat-ux · 00-vision/scope · terminology
- status: distilled
- distilled-to: terminology.md, 20-systems/character-profile/power/（新增）, 20-systems/architecture.md, 20-systems/services/（_index, combat-service, future-event-service, life-cycle-service）, 20-systems/scoring.md, 20-systems/balance.md, 20-systems/game-progression.md, 20-systems/monetization.md（新增）, 20-systems/character-profile/life-total.md（由 life.md 改名）, 20-systems/character-profile/_index.md, 20-systems/adventure-event/combat/_index.md, 20-systems/player-profile/codex/**（由 enemy-codex/ 重构并扩为图鉴族）, 20-systems/player-profile/_index.md, 20-systems/player-profile/player-power/_index.md, 20-systems/_index.md, 40-ux/combat-ux.md, 00-vision/scope.md, 50-decisions/ADR-0004, program-overview.md, system-overview.md, open-questions.md, answer-logs/log-0801b.md, .claude/rules/Context.md

## Intent（distilled）

**一句话：** 补齐 08-01 道念改写留下的数值与规则骨架——**战斗打满 10 个回合、起始道念按等级给、卡牌产/削道念且不低于 0、胜负差同时决定奖励厚度与 lifeTotal 扣减**；同时**放开抽象层级到五级并各自定名**、**把敌人静态数据定为 EnemyTemplate 并由 future-event-service 物化赋级**、**把图鉴从一个扩成一族（五个）**、**上调三个篇章的目标时长**，并首次给出**商业化形态（premium bundle）**。

### ① 抽象层级：放开到五级，各级定名（推翻「不设第三级」）

- **新决策：service / manager 之外**允许更多层次；层级词固定为：

  | 层级 | 名称 | 说明 |
  |------|------|------|
  | 第一级 | **service（服务）** | 边界单元，autoload；三判据不变 |
  | 第二级 | **manager（管理器）** | 服务内部的职能组件 |
  | 第三级 | **module（模块）** | manager 内部的组件 |
  | 第四级 | **processor（处理器）** | 预留 |
  | 第五级 | **handler（处理器件）** | 预留 |

- **`DeckManager` 随之改名为 `DeckModule`**：它由 `CharacterManager` / `EnemyManager` 各自持有、每参战方一份，正是第三级。
- 由此**「不设第三级」的措辞作废**——它曾是 07-30b 遗留的一处张力（`architecture.md` / `services/_index.md` / `combat-service.md` 三处待决问题），现按「承认层级、给它一个名字」的路线闭合。
- **推论：命名即层级声明。** 今后新增的任何层内组件，名字的后缀就宣告了它在第几层；跨层直呼（如从 service 直接伸手进某个 module）仍被既有边界纪律禁止。第四 / 第五级目前**没有实例**，只是把名字先定下来以免日后各处自造词。

### ② 敌人意图揭示的分界值（三档的两道门槛全部给定）

- **判据从「纯全局等级差」改为「同阶差值 + 越阶硬门」：**

  | 情形 | 第一篇章 | 第二 / 第三篇章 |
  |------|---------|----------------|
  | 同阶（同境界）、敌人不高于角色（diff ≤ 0） | 完整意图 | 完整意图 |
  | 同阶、`diff` 1–2 | **仅类别** | — |
  | 同阶、`diff = 1` | — | **仅类别** |
  | 同阶、`diff ≥ 3` | **完全无信息** | — |
  | 同阶、`diff ≥ 2` | — | **完全无信息** |
  | **越阶**（敌人境界高于角色） | **完全无信息** | **完全无信息** |

- **越阶等同无信息**是一道硬门：不论全局等级差多小（例如 炼气十三层 vs 筑基初期，全局仅差 1），**只要跨了境界就是彻底黑箱**。这把「境界鸿沟」从数值差提升为一条**结构性**规则。
- **原文空档已拍板：** 「`0 < diff < 3` 仅类别 / `diff > 3` 无信息」之间的 `diff = 3` 归入**无信息**档（即 `≥ 3` 无信息，仅类别收窄为 1–2）。
- **它推翻了 07-30b 的「篇章容差」表述**（ch1 差 > 3 才降级 / ch2 · ch3 高一级即降级）：ch1 现在**差 1 即降级、差 3 即彻底黑箱**；ch2 / ch3 则是差 1 降一档、差 2 直接黑箱。

### ③ 敌人等级的来源 = EnemyTemplate + 物化时充实（答结）

- **`EnemyTemplate` 集合**承载敌人的**静态数据**，形态类同 EnemyCodex（图鉴即是它面向玩家的那一面：已遭遇敌人的简述）。
- **future-event-service 取一份 template → 充实 / 改写（enrich / modify）→ 指派给该事件。** 因此**敌人等级不是模板上的死值，而是物化产物**：同一个敌人模板可以在不同篇章、不同情境下以不同等级出场。
- **它与既定物化模型完全同构**（`architecture.md` 总则 6）：模板 = 参数空间，future-event-service = 唯一物化点，产出即定稿。敌人由此成为「内容定义 + 情境 → 两个类型」通则的第三个实例（前两个是 `AdventureEventData ↔ EventOption`、`CardData ↔ CardInstance`）。
- **连带答结「敌人等级标注的承载字段」的一半：** 既然等级在物化时确定，它就**落在物化产出上**（随 `EventOption` 一起定稿并存档），而不是由 ViewModel 现查模板。
- **模板携带「样本卡组」**（见 ⑤ 图鉴记录关键卡牌）——敌人的卡组同样是模板给基线、物化时可改写。

### ④ 全局等级序的基数与 baseMomentum（答结）

- **全局等级序 = 连续 1–22，境界之间不留跳变（答结）。** 枚举值即描述：

  ```
  level=1  desc=炼气一层    …    level=13 desc=炼气十三层
  level=14 desc=筑基初期    …    level=17 desc=筑基巅峰
  level=18 desc=金丹初期    …    level=21 desc=金丹巅峰
  level=22 desc=元婴初期
  ```

- **`baseMomentum`（每个等级的起始道念）：**

  | 境界 | 全局等级 | baseMomentum |
  |------|---------|--------------|
  | 炼气 | 1–13 | **1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 15** |
  | 筑基 | 14–17 | **20, 24, 28, 32** |
  | 金丹 | 18–21 | **45, 55, 65, 75** |
  | 元婴 | 22 | **100** |

- **形状是有意的：** 炼气段线性 +1（第十三层跳到 15 作为突破前的台阶），筑基以上**每一级的跨度都在放大**（炼气 +1 → 筑基 +4 → 金丹 +10；境界之间 +5 / +13 / +25）。境界鸿沟因此**由 baseMomentum 承载**，而不是由全局等级序的基数跳变承载——这正是「基数不留跳变」得以成立的原因。
- **原文缺的两档已补齐**（筑基中期 28、金丹后期 65），表完整覆盖 22 个全局等级。

### ⑤ 敌人图鉴的记录深度 = 全文案，一次遭遇全解锁（答结两问）

- **记录内容（五项）：** 人物背景 · 功法简介 · 运作方式 · 特点与弱点 · **EnemyTemplate 中样本卡组的关键卡牌**。
- **一次遭遇，全文案解锁。** 「逐招式解锁」**否决**——遭遇一次就拿到该敌人的完整词条。
- **它是文案而非数值。** 五项全部是**描述性文本**（含「关键卡牌」——给的是牌，不是牌的精确数值曲线）。这让图鉴**不侵蚀越级黑箱**这条既定分层得以维持：图鉴说「他会用什么路数、怕什么」，不说「他这回合出哪张」。
- **推论：图鉴条目的文案挂在 `EnemyTemplate` 上，存档只记「已遭遇」。** 与既定纪律「展示文案留在 `Resource` 上、运行时 / 存档态只带 `Id` + 可变状态」一致——图鉴的存档负担因此**接近于一个 id 集合**，先前担心的「存档体积」问题基本消解。

### ⑥ 战斗的终止条件 = 固定 10 个回合（答结 · 道念模型的首要缺口）

- **一场战斗打满 10 个回合结束**，**双方各 5 个回合**（「回合」= 单方的一次行动轮；双方交替，各 5 轮）。
- 结束时**比双方道念，高者胜**——不设「先到某个道念值即胜」的提前终止，也不以卡组耗尽终止。
- **推论 ①：战斗是定长的。** TurnManager 的状态机是一个**固定长度的循环**（`for turn in 1..10`），不需要动态终止判定；每场战斗的时间开销可预测，直接服务于「篇章 = 一个移动端时段」的时长控制。
- **推论 ②：节奏张力从「谁先撑不住」变成「10 回合内谁攒得多」。** 与 mana 每回合刷满、道念只增不减到负数共同构成一场**限时积分对抗**。
- **推论 ③：起始道念的领先必须在 10 回合内被追平才可能翻盘**——越级的压迫感因此有了确切的量纲（见 ⑦）。
- **平局 = 只发基础奖励。** 打满 10 回合后道念相等时**不判负、不扣 lifeTotal**，只发该事件的基础奖励（无厚度加成）。这与「道念差是双向刻度」自洽：**差值 0 就是两侧都不加码的那个原点**。落到类型上 `CombatOutcome` 需要 `Draw` 这一态。

### ⑦ 道念的产出途径与下限（答结）

- **产出途径 = 卡牌。** 道念由打出的卡牌产生。
- **可以互相削减。** 卡牌既能给自己加道念，也能削减对方道念——道念是**可攻可守的双向标尺**，不是单向累加的计分器。
- **道念不会小于 0。** 削减在 0 处截断（clamp），不存在负道念。
- **起始道念参考 `baseMomentum`。** 战斗开始时双方各自持有一个**由自身等级决定的起始道念**（见 ④ 的表）。
- **推论（承重）：等级差直接变成起点差。** 炼气十层（10）挑战筑基初期（20）= 开局落后 10 点，须在 10 个回合内追回。**「越级挑战」的风险因此是可计算的**，且与「敌人等级在 eventOptions 上精确标注」形成闭环：玩家看到等级，就等于看到起跑线。
- **推论：`baseMomentum` 同时是战斗强度的主刻度**——它既定起点，也隐含了「这个等级的一回合该产出多少道念」的量纲基准。

### ⑧ 胜利侧也读道念差 → 奖励厚度（答结）

- 失败按道念差扣 lifeTotal 已定；**胜利同样读道念差：差得越多，奖励越厚**（碾压 > 险胜）。
- **推论：道念差是一个双向的结算刻度**——同一个量在胜负两侧分别驱动奖励厚度与惩罚深度，不需要第二套结算量。

### ⑨ `life` → `lifeTotal`：改名、归 0 语义、恢复途径（答结两问）

- **改名：`life` → `lifeTotal`，领域词与代码字段一并改（已确认）。** 含义 = **这个角色的生命值**；`CharacterProfile.Status` 上为 `lifeTotal / lifeTotalLimit`（`currentHealth / healthLimit` 作废）、`CombatResult` 上为 `RemainingLifeTotal`。
- **`lifeTotal` 归 0 = `defeated`（轮回级终结）。** 它与「寿元归 0」并列，是角色终结的**第二条路径**。
- **恢复途径 = 通过 event 恢复。** AdventureEvent 的 reward 可回复 lifeTotal——与等级、`manaLimit` 同属「由事件 cost / reward 推拉」的成长体系，走同一条 `ProfileChangeSpec` → `TryApply` 链路。
- **推论：`DefeatReason.CombatLost` 作废。** 战斗失败本身不再终结角色（只扣 lifeTotal）；终结原因收敛为**主动弃置 / 寿元耗尽 / lifeTotal 耗尽**三种。

### ⑩ 图鉴不止一个：五个图鉴构成一族

- 除 **EnemyCodex** 外，还有 **CharacterPowerCodex · PlayerPowerCodex · CharacterItemCodex · PlayerItemCodex**。
- **共同形状：** 账号级、跨轮回持久、归 PlayerProfile、条目按内容 `Id` 索引、条目内容为**静态文案**（挂在对应的内容 `Resource` 上）、存档只记解锁状态。
- **推论：图鉴 = 元进程的「知识收集」轴。** 它与 PlayerPower（能力）、Achievements（成就）并列，是第三条跨轮回积累线；「失败也在积累」这一取向由它承载。
- **`CharacterPower` = 轮回级的角色能力，对标账号级的 `PlayerPower`（已确认）。** 二者是同一个「能力」概念在两个生命周期层上的实例：**分界是生命周期，不是能力种类**（与 `PlayerItem` ↔ `CharacterItems` 同一条分界）。它沿用 PlayerPower 那套形状（`status` 开关、事件触发器被动修正、capability flag + modifier pipeline），由 CharacterProfile 持有、随轮回清理。新建 `20-systems/character-profile/power/`。
- **推论：轮回内的 build 由三件事承载** —— deck（卡组）、CharacterItems（道具）、CharacterPower（能力）；PlayerPower 则承载跨轮回的那一半。

### ⑪ 篇章目标时长上调（推翻 08-01 的 15–30 / 15–30 / 20–40）

| 篇章 | 新目标时长 | 旧目标时长（作废） |
|------|-----------|------------------|
| 第一篇章 炼气→筑基 | **30–40 分钟** | 15–30 |
| 第二篇章 筑基→金丹 | **35–45 分钟** | 15–30 |
| 第三篇章 金丹→元婴 | **45–55 分钟** | 20–40 |

- **口径：面向已掌握策略的熟练玩家。** 新手所需时间更长，这三个区间是**下限口径**而非平均值。
- **「`lifeSpanCost` 是时长旋钮」不变，但旋钮方向被改写。** 寿元预算（100 / +100 / +300）未变而目标时长几乎翻倍，故**单次定价的绝对水平要比先前设想低得多、一个篇章的事件总数要多得多**。**篇章之间「逐章上调」的相对关系仍成立**（第三篇章 300 点预算对 45–55 分钟，单价仍显著高于第一篇章 100 点对 30–40 分钟）。
- **它与「一个篇章 = 一个移动端时段」的支柱仍相容**，但时段被拉长到接近一小时——**中途存档续玩的重要性上升**（既有的决策点存档已覆盖）。

### ⑫ 商业化：premium bundle（首次陈述）

- **形态 = 一个付费礼包（premium bundle）**，购买后给予：
  1. **随机 1 个 PlayerPower**；
  2. **随机 2 个 PlayerItem**；
  3. **第二篇章重试上限 3 → 9**；
  4. **第三篇章重试上限 1 → 3**。
- **第一篇章重试保持无限**（本就无限，礼包不涉及）。
- **推论 ①：重试上限首次成为可变量。** ADR-0004 的「无限 / 3 / 1」不再是常量，而是**基线值**，由账号级的礼包持有状态改写为「无限 / 9 / 3」。
- **推论 ②：它踩在既定的「轻度提升、PvE-only 可容忍」边界上。** PlayerPower 的既定定位（无 PvP，故容忍强度）正是这个礼包成立的前提；**重试次数**先前被明确定性为「有限资源、构成元进程压力」，付费放宽它是一次**经确认的、有意的口径变化**。连带纪律：**平衡以免费档（∞ / 3 / 1）为「应当可通关」的基准**，付费档是宽松化而非必需品。
- **推论 ③：随机 PlayerPower 与「道统残卷」（失败累积的 PlayerPower 掉落概率）共用同一个获取面**——二者是否互相影响（礼包给的 power 是否重置残卷概率）未陈述。

## Open questions

> 本 handoff 首轮提出的六项矛盾 / 待确认项**已在同一轮全部拍板**（ch1 分档 `1–2` / `≥ 3`、`baseMomentum` 补齐 28 与 65、`CharacterPower` 对标 PlayerPower、平局只发基础奖励、付费改写重试上限为有意的口径变化、`lifeTotal` 连代码字段一并改名），已折进正文，不再列于此。以下是仍未决的。

- **`CharacterPower` 与 PlayerPower 的复用边界。** 「对标」已定；仍待定二者是否共用同一份能力定义与 modifier pipeline、获取 / 失去触发、篇章突破是否随「全部继承」带入、与卡牌 / CharacterItems 的边界。→ `20-systems/character-profile/power/`。
- **其余四个图鉴的解锁触发。** EnemyCodex = 遭遇即记；PowerCodex / ItemCodex 的触发是「获得即记」「见过即记（含商店中见到）」还是「使用过即记」？→ `20-systems/player-profile/codex/`。
- **`EnemyTemplate` 与既有 `EnemyData` 是同一个东西吗？** 若是，则统一定名；若不是，则二者的分工需说明。且**物化后的敌人实例**尚未定名（`EnemyInstance`？随 `EventOption` 落存档还是战斗开始时再展开？）。→ `20-systems/services/future-event-service.md`、`20-systems/adventure-event/combat/`。
- **道念差 → 奖励厚度的换算。** 与「道念差 → lifeTotal 扣减」是同一条曲线的两侧，还是两套独立分档？上下限如何？→ `20-systems/balance.md`、`20-systems/adventure-event/combat/`。
- **卡牌产 / 削道念的量纲基准。** `baseMomentum` 给了起点，但「一张牌该产多少道念」「10 回合内一方总产出应达到起始值的几倍」这条基准未给——它决定越级追分是否可能。→ `20-systems/balance.md`、`20-systems/character-profile/deck/`。
- **Finale / Practice 是否也是 10 回合。** 二者是战斗变体、有独立胜负条件；固定回合数是否照搬未陈述。→ `20-systems/adventure-event/finale/`、`practice/`。
- **`lifeTotal` 的回复幅度与基线成长。** 「通过 event 恢复」已定；单次回复幅度、更高境界的 `lifeTotalLimit` 基线、以及 `lifeTotalLimit` 是否也由事件推拉（与 `manaLimit` 同模型）仍未定。→ `20-systems/balance.md`。
- **premium bundle 的商业化细则。** 一次性还是可重复购买？定价与地区？是否有其他付费点（外观 / 通行证）？随机 PlayerPower 是否与「道统残卷」概率互相影响？付费改写重试上限如何在 UX 上呈现（避免「付费才玩得下去」的观感）？→ `20-systems/monetization.md`。
- **重试上限可变后的存档表达。** 「无限 / 9 / 3」由账号级礼包状态改写，故重试上限的判定要读 PlayerProfile 的持有状态——它是一个 `capability flag`、一个 `modifier pipeline` 的具名修正，还是一个独立的 `Entitlement` 字段？→ `20-systems/player-profile/`、`20-systems/services/profile-service.md`。
- **第四 / 第五级（processor / handler）目前无实例。** 名字先定下，但何时该下沉到第四级、判据是什么未给——与 service / manager 各有三判据不同，module 以下暂无判据。→ `20-systems/architecture.md`。

## Notes / triage

- 本 handoff 是 `90-inbox/draft-0801b.md` 的整理稿，是 08-01 道念改写的**直接续篇**：把那次改写留下的「终止条件 / 产出途径 / 分界值 / 等级来源 / life 归 0」五个承重缺口一次性填上。
- **推翻的既有表述：** ①「两级层次 · 不设第三级」→ 五级命名；②「篇章容差 ch1 差 > 3 才降级」→ 同阶差值分档（ch1 `1–2` 仅类别 / `≥ 3` 无信息）+ 越阶硬门；③ 目标时长 15–30 / 15–30 / 20–40 → 30–40 / 35–45 / 45–55；④ `DefeatReason.CombatLost` → `LifeTotalExhausted`；⑤ 领域词与代码字段 `life` → `lifeTotal`（`currentHealth / healthLimit` → `lifeTotal / lifeTotalLimit`）；⑥ ADR-0004 的重试上限由常量降为基线值（付费为有意的口径变化）。
- **结构改动：** `20-systems/player-profile/enemy-codex/` 重构为 `20-systems/player-profile/codex/`（族目录 + `enemy-codex.md`）；`20-systems/character-profile/life.md` 改名为 `life-total.md`；新增 `20-systems/character-profile/power/`（CharacterPower）与 `20-systems/monetization.md`。
