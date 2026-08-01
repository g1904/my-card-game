# Open questions — 跨 session 待答清单

> 本文件是**客户端**（Godot 项目）的待答清单；后端侧的待答清单在 `backend-design-documents/open-questions.md`（`backend-design` 分支）。
>
> 每次 session 结束时，未答的 Open questions 汇总到此，供下次拾起；一旦答定，就从此处移除、归档进对应主题文档的 `## 待决问题` / `## 决策`，并在 `answer-logs/log-<draftSuffix>.md` 记一笔。此文件**只跟踪仍待答的问题**（不留已解决区），是导航 / 拾取清单，**权威归属在各主题文档**；已答定问题的移出记录见 `answer-logs/`。
>
> 最近更新：**2026-08-01（0801b）**。本次是 08-01 道念改写的**直接续篇**，把它留下的承重缺口一次性填上，答结 **9 条**：**① 战斗定长 10 个回合**（双方各 5，打满比道念；不设提前终止）；**② 道念产出途径 = 卡牌**（可互相削减、下限 0、**起始道念 = `baseMomentum`**）；**③ 胜利侧也读道念差** → 奖励厚度；**④ `life` 定名 `lifeTotal`**、**归 0 = defeated**、**经 event 恢复**（`DefeatReason.CombatLost` 作废）；**⑤ 意图三档的分界值给全** = **越阶硬门 + 同阶差值门槛**（推翻篇章容差表述）；**⑥ 敌人等级的来源** = `EnemyTemplate` + **future-event-service 物化时充实赋级**；**⑦ 全局等级序基数** = 连续 1–22 **不留跳变**（鸿沟改由 `baseMomentum` 承载）+ `baseMomentum` 表；**⑧ 敌人图鉴的记录深度** = 五项文案、**一次遭遇全解锁**（逐招式解锁否决）；**⑨ 抽象层级放开到五级并各自定名**（service / manager / **module** / processor / handler；`DeckManager` → **`DeckModule`**，「不设第三级」作废）。另有**三项新增设计**：**图鉴扩为五个成族**（Enemy / CharacterPower / PlayerPower / CharacterItem / PlayerItem）、**篇章目标时长上调**（30–40 / 35–45 / 45–55 分钟，熟练玩家口径）、**首次给出商业化形态**（premium bundle：随机 1 PlayerPower + 2 PlayerItem + 篇章重试 3→9 / 1→3）。**随后又追加答结 6 条**（本次提出的矛盾与待确认项全部拍板）：**ch1 分档 = `1–2` 仅类别 / `≥ 3` 无信息**；**`baseMomentum` 补齐**（筑基 20/24/28/32、金丹 45/55/65/75，表已完整）；**`CharacterPower` = 轮回级角色能力、对标 PlayerPower**（新建 `character-profile/power/`）；**平局 = 只发基础奖励**（不扣 lifeTotal，`CombatOutcome.Draw`）；**付费改写重试上限是有意的口径变化**（免费档为通关基准）；**`lifeTotal` 连代码字段一并改名**（`lifeTotal / lifeTotalLimit` / `RemainingLifeTotal`）。移出记录见 `answer-logs/log-0801b.md`（共 15 条）。
>
> 前次更新：**2026-08-01（0801）**。本次是**对整条玩法循环的一次结构性评审 + 逐条裁决**，答结 6 条、部分答结 3 条，并推翻两处既有定案：**① 战斗模型改写**——**计分 = 道念（momentum），且道念就是胜负判据**（道念高者胜），**life 重定位为战斗外耐久**、只在失败结算时按道念差扣减，「life + mana 双资源 / 胜负 = life 归零」**全部推翻**，空白的 `scoring.md` 由此填满；**② 寿元定价 = 时长旋钮**——`lifeSpanCost` 由目标时长（15–30 / 15–30 / 20–40 分钟）反推分档，预算不变、逐篇章上调，**剩余寿元跨篇章结转**，且**内容侧写正数量值、物化时取负**（带符号约定不变）；**③ 隐藏属性跨档给一条定性叙事**（数值仍隐藏，寿元告警改两段式 30% / 10%）；**④ 等级成长 = 事件产出**（不只战斗类、失败也可能给）+ **敌人等级在 eventOptions 上精确标注**（否决模糊危险度档位）；**⑤ 失败侧首次有产出**（EnemyCodex 遭遇即记 + 道统残卷 = 递增的 PlayerPower 掉落概率，不发货币）；**⑥ 两处「不做」**（跳过配额 / 递增 skipCost 不做——前提不成立；`manaLimit` 下界护栏与死牌转化不做——情形罕见）。移出记录见 `answer-logs/log-0801.md`；前次更新见 `answer-logs/`（07-30b · 07-30 · 07-27b · 07-27 · 07-26b · 07-25c）。

## 当前焦点：各系统机制细节

> **焦点判据（07-30 定）：** **规则、字段语义、流程与算法 = 机制细节 = 焦点**；**具体条目目录与数值 = 内容充实 = 搁置**（见下方「已搁置」）。与既定开发路线「框架 → 内容 → 平衡与体验 → 社交及其他」的第 ① 阶段一致。Source: `10-handoffs/2026-07-30-claude-engineering-scope-enemy-manager-and-requirement-breakdown.md`。
>
> 逐类型 AdventureEvent 的机制将**各开一次专门 session**（九类各一场），不在一次 handoff 里做完 —— 见 `20-systems/adventure-event/_index.md`。

### ① 战斗机制（焦点之首 · 08-01b 后的残留）

> 已答结并移出：意图揭示规则（三档）、例外条件、EnemyManager 是否细分、mana 恢复与上限成长、战斗存档 / 取消语义、Finale 结算归属（见 `answer-logs/log-0730b.md`）；计分模型去向、等级成长途径、等级差是否可见、图鉴解锁触发、`manaLimit` 下界护栏（见 `answer-logs/log-0801.md`）；**战斗终止条件、道念产出途径、胜利侧道念差、`lifeTotal` 归 0 与恢复、意图分界值、敌人等级来源、全局等级序基数、图鉴记录深度、抽象层级命名、ch1 分档、`baseMomentum` 补齐、平局判定、`lifeTotal` 字段改名**（见 `answer-logs/log-0801b.md`）。

**道念模型的残留（08-01b 后 · 优先级最高）**

- **道念差 → lifeTotal 损失 / 奖励厚度的换算公式，及其计算归属。** 公式（线性 / 分档 / 上下限；**胜负两侧是否同一条曲线**）归 `20-systems/balance.md`；**由谁计算**未定——combat-service 算好写进 `Spoils`，还是 life-cycle 依 `CombatResult` 的双方道念在 `eventEnd` 算。→ `20-systems/services/combat-service.md`、`life-cycle-service.md`、`20-systems/architecture.md`。
- **卡牌产 / 削道念的量纲基准（承重）。** 产出途径已定（卡牌、可互削、下限 0、起始 = `baseMomentum`）；但**一张牌该产多少**、**10 个回合内一方总产出应达到起始值的几倍**未给——**它决定越级追分是否可能**（开局落后 10 点时 5 个回合能否翻盘）。是否存在道念相关的状态与倍率亦未定。→ `20-systems/character-profile/deck/`、`20-systems/balance.md`。
- **`CombatSnapshot` / `PlayResult` 的道念字段形态。** 二者必须承载道念（否则战斗 UX 的「双方道念对比」主视觉无数据可读）；具体形态（当前值 + 本次增量？分来源？对方的削减量？）依赖卡牌内容设计。→ `20-systems/services/combat-service.md`。
- **Finale / Practice 的道念规则差异。** 二者是战斗变体、有独立胜负条件；**是否同为 10 回合**、如何改写道念判据（更高门槛？失败惩罚更轻？）未定。→ `20-systems/adventure-event/finale/`、`practice/`。
- **`lifeTotal` 的回复幅度与上限模型。** 「经 event 恢复」已定；单次幅度、哪些事件类型给回复、更高境界的 `lifeTotalLimit` 基线、以及上限是否也由事件推拉（与 `manaLimit` 同模型）未定。→ `20-systems/balance.md`、`20-systems/character-profile/life-total.md`。

**等级与意图（08-01b 后的残留）**

- **等级产出的频次与分布。** **途径已定**（等级成长 = event reward，不只战斗类、失败也可能给）；仍待定：一章内需要多少个「升级型产出」才能从 1 爬到 13 / 1 到 4、如何分布在事件池中、失败产出是否弱于胜利。**它与寿元预算的花法互相约束**，且**篇章时长上调后事件总数变多**，这条更承重。→ `20-systems/game-progression.md`、`20-systems/balance.md`。
- **意图类别的枚举。** 第二档展示粒度定为「攻击 / 防御 / 增益 / 特殊」，其正式枚举与敌人行为的映射未定；第二档的视觉语言（是同一图标去掉数值，还是另一套模糊化视觉）亦未定。→ `20-systems/adventure-event/combat/`、`40-ux/combat-ux.md`。
- **`EnemyTemplate` 与 `EnemyData` 是否同一个东西；物化后的敌人实例如何承载。** 来源已答定（模板 + 物化赋级）；仍待定：二者是否需统一定名、实例叫什么（`EnemyInstance`？）、**嵌在 `EventOption` 上随批次落存档还是战斗开始时再展开**、一个事件带多个敌人时如何组织，以及 `EncounterSpec` 如何承载它。→ `20-systems/services/future-event-service.md`、`combat-service.md`。
- **物化时「充实 / 改写」敌人的规则。** 依什么决定这次给几级、样本卡组怎么改（角色等级？篇章？location？剧本调制？）未陈述。→ `20-systems/services/future-event-service.md`、`20-systems/balance.md`。
- **敌人等级标注的措辞。** 承载已定（随物化产物定稿）；仍待定用什么措辞（境界名 + 层级 / 全局序数字 / 并列）、是否同屏并列玩家自身等级。→ `40-ux/combat-ux.md`。
- **敌人图鉴的写作规格与实例信息。** 五项词条内容已定（背景 / 功法 / 运作方式 / 特点与弱点 / 关键卡牌）、一次遭遇全解锁已定；仍待定：每项的长度与写作口径、「关键卡牌」列几张由谁标注、**词条挂模板而敌人等级是物化产物**——是否需标注「本次遭遇的是 X 级」、是否影响战斗内呈现、战斗内能否查阅。→ `20-systems/player-profile/codex/enemy-codex.md`。

**结构与存档**

- **module 以下的下沉判据未给。** 五级层级词已定（service / manager / module / processor / handler），但「什么时候一个 module 该再拆出 processor」没有判据——第四 / 第五级目前只有名字、无实例。→ `20-systems/architecture.md`。
- **决策点的粒度。** 「事件过程按决策点落存档」已定，但决策点具体指哪些位置（事件内每次选择后？战斗内每回合开始 / 每次出牌后 / 每次目标选择后？）未定；粒度直接决定本地写入频率与 push 防抖压力。→ `20-systems/services/combat-service.md`、`life-cycle-service.md`、`sync-service.md`。
- **`attemptIndex` 是否还需要（动机已消解）。** 决策点存档 + RNG `State` 持久化已关闭「退出重进重掷」窗口。剩余问题收窄为：**篇章重试（ADR-0004）重开同一篇章时，同名事件是否应换一套战斗随机**——若应则保留派生层并令 `attemptIndex` = 篇章重试次数，若不应则整层可去掉。→ `20-systems/common-properties.md`、`20-systems/services/life-cycle-service.md`。
- **`AdvanceEventAsync` 的取消触发方。** 成本处置已定（`SelectCost` 不回滚、视同已结算）；仍待定「**谁**会取消一场进行中的事件 / 战斗」（玩家主动退出 / 断线 / 应用挂起）及取消如何与最近决策点对齐。→ `20-systems/services/life-cycle-service.md`、`sync-service.md`。

**战斗内容与规则（既有残留）**

- **回合内的效果 / 状态系统。** 增益 / 减益 / 持续效果的载体形态、结算顺序、与 `CardInstance` 运行态可变性的关系 —— 完全空白。**mana 每回合刷满后，回合间的节奏张力必须由此承担**，其重要性上升。→ `20-systems/adventure-event/combat/`。
- **敌方卡组的设计形态。** 敌人也出牌已定；其卡牌是与玩家共用 `CardData` 体系 / 共用卡池，还是另立敌方卡池，以及卡组规模与抽牌规则均未定。→ `20-systems/character-profile/deck/`、`20-systems/adventure-event/combat/`。
- **探查（probe）的实现形态。** 定名与方向已定，**本阶段明确搁置**：花费形式（mana / 弃牌 / 每场次数）、授予途径（卡牌 / 能力 / 道具）、可探查到哪一档，归卡牌与技能内容的横向扩展阶段。→ `20-systems/character-profile/deck/`、`20-systems/player-profile/player-power/`。
- **`manaLimit` 推拉的分档。** 机制已定（由事件 cost / reward 推拉、可升可降），**下界护栏与死牌转化已明确不做**（下降极罕见）；哪些事件推高 / 压低、单次幅度未定；`lifeTotalLimit` 是否采用同一模型亦未陈述。→ `20-systems/character-profile/mana.md`、`life-total.md`、`20-systems/balance.md`。
- **`EncounterSpec` / `CombatSnapshot` / `TargetRef` / `PlayResult` 的完整字段。** API 骨架已定，字段依赖战斗内容设计。→ `20-systems/services/combat-service.md`。
- **Finale 的独立胜负条件与奖励结构。** 「Finale 是战斗变体、天劫为带定制卡组的 Enemy」已定；区别于 Combat 的胜负判定与奖励结构未定；**天劫是否天然属于「大幅越级」**（即 Finale 全程无意图信息）会直接决定其压迫感。少部分非战斗形态的 Finale 待日后定制。→ `20-systems/adventure-event/finale/`。
- **Practice「低风险」的具体机制与对手来源。** 对手为 Enemy 已定；失败惩罚差异、是否复用 Combat 敌人条目未定。→ `20-systems/adventure-event/practice/`。
- **enemies 归属。** 现归 `adventure-event/combat/`；**Practice 与 Finale 均已确认使用敌人**（天劫即 Enemy），是否升为共享内容层待拍板。→ `20-systems/adventure-event/combat/`、`20-systems/architecture.md`。

### ② eventOptions 生成流程（焦点）

- **生成 / 加权规则与叠加顺序。** 从 CharacterProfile 生成 / 加权抽取下一批 eventOptions 的具体规则（月圆之夜式策划 vs 随机权重、每批数量、事件类型配比、带种子 RNG 派生），以及 **location 框定 / AdventurePlot 调制 / seeded RNG 的叠加顺序**未定。→ `20-systems/services/future-event-service.md`、`20-systems/game-progression.md`。
- **`EventOption` 的完整物化字段清单。** 骨架九字段已定（`InstanceId` / `EventId` / `EventType` / `Priority` / `IsMandatory` / `SelectCost` / `SkipCost` / `IsRevealed` / `RevealedEventId`）。但物化模型说「**多数**属性由物化决定」，故仍待定：还有哪些字段由物化产出（哪些数值可被情境改写？风味文案是否也物化？outcome 权重是否在物化时固化？）。→ `20-systems/services/future-event-service.md`、`20-systems/adventure-event/common-properties.md`。
- **补位落空的判定规则。** 何种条件下 future-event-service 补不出新事件？eventOptions 是否允许被跳到只剩 0 个？若剩 0 个玩家如何推进（死局兜底）？→ `20-systems/services/future-event-service.md`。
- **全部 mandatory + 付不起 `selectCost` 的死锁。** 一批可全部 mandatory 且高优先级封锁其余选项；若付不起唯一可选事件的 `selectCost`，轮回无法推进。既然 `selectCost` 是**物化时组装**的，这条保证天然有落点（物化阶段即可对照 `CanAfford` 调整）；剩下的只是「要不要给」与兜底形态。→ 同上。
- **`eventPriority` 与 `ifMandatory` 的叠加规则。** 高优先级事件**能否被跳过**？若被跳过，本轮是否解除对低优先级事件的封锁？二者都限制选择权，是否语义重叠（高优先级是否应蕴含 mandatory）？→ `20-systems/adventure-event/common-properties.md`、`20-systems/services/future-event-service.md`。
- **`eventPriority` 的取值域与置位方。** 两档（0 / 1）还是任意整数档位？是否也由 future-event-service / PlotManager 动态置位（用户仅明确了 `ifMandatory`）？→ 同上。
- **跳过语义的残留细节。** 主干已定（单项补位 / 通常不扣寿元 / 计入 `pastEvent` / **只对可选事件开放，不设配额与递增 `skipCost`**）；仍待定：**能否整批全跳**、**付不起 `skipCost` 时如何表现**。→ `20-systems/adventure-event/common-properties.md`、`20-systems/services/life-cycle-service.md`。
- **`CostKey` 的其余成员与 element 数据形态。** 代码形态已定为 `ProfileChangeSpec`（element 带符号）；仍待定：`CostKey` 除 `lifeSpanCost` 外的成员（jade / mana / 道具 / 隐藏属性推拉？）、各 element 的数据形态（固定值 / 区间 / 公式）、是否允许**部分抵扣**。→ `20-systems/adventure-event/common-properties.md`、`20-systems/character-profile/currency.md`、`20-systems/balance.md`。
- **`pastEvent` 的痕迹 schema。** 持久化方式已定（存**物化后的定稿实例快照**、按 `InstanceId` 索引，不重算）；仍待定：如何区分「进入并结算」与「跳过」两种痕迹及各自成本、快照存哪些字段、**快照体积对增量 push 粒度的影响**。→ `20-systems/adventure-event/common-properties.md`、`20-systems/services/sync-service.md`。

### ③ 逐类型 AdventureEvent 机制（焦点 · 各开一次专门 session）

- **各类型的结算 / 机制细化。** 九类分类法已定（`50-decisions/ADR-0002` 九值枚举）。**Combat 已开过第一场专场**（07-30b：参战方结构、意图三档、mana、存档）；仍待设计：**Mystery** 揭示权重 / 机制；**Practice** 的风险 / 回报差异（结构已定为战斗变体）；**Finale** 的独立胜负条件与奖励结构（结构已定为战斗变体、天劫为 Enemy）；Exchange / Research / Explore / Social / Travel 各自的通用结算器数据形态。→ `20-systems/adventure-event/<type>/`、`50-decisions/ADR-0002`。
- **ADR-0002 补订。** Explore / Travel 尚未正式并入 ADR-0002 枚举。→ `20-systems/adventure-event/_index.md`。
- **location 机制细节。** 地域的枚举 / 层级、Travel 如何映射到具体 location、一个 location 开放哪些修行事件池、location 是否随篇章 / 境界变化。→ `20-systems/game-progression.md`。
- **子类型间的公平配比与出现频率。** 一段修行历程中各类事件的分布、权重、由 location 与 AdventurePlot 如何调制。→ `20-systems/adventure-event/_index.md`、`20-systems/services/future-event-service.md`。

### ④ 隐藏属性 / 剧本机制（焦点）

- **隐藏属性的档位划分与阈值（08-01 新增 · 承重）。** 「**跨档给一条定性叙事**」已定案，但**每个隐藏属性分几档、阈值在哪**未定——**定性反馈的触发完全依赖它**，不定则该机制无法落地。寿元已给两档（30% / 10%），道心 / 煞气未给。→ `20-systems/services/plot-manager.md`。
- **跨档叙事文案的归属与呈现（08-01 新增）。** 文案挂在档位定义上（每档一条固定文案），还是随触发它的事件而变？是否走内容层（可热更）？播在哪里（结算面板一行 / 独立小弹层）？同一次结算**多个属性同时跨档**如何呈现？→ `20-systems/services/plot-manager.md`、`40-ux/screen-flow.md`。
- **隐藏属性清单。** 已定 **道心 / 煞气 / 寿元** 三项且均隐藏；仍待定：是否还有其他隐藏属性、增减触发（哪些 AdventureEvent 推拉）、剧情线目录。→ `20-systems/services/plot-manager.md`、`life-cycle-service.md`。
- **各篇章 `lifeSpanCost` 的具体分档表（08-01 收窄 · 08-01b 目标值改写 · 承重）。** **定价方向已定**（目标时长反推；预算不变、逐篇章上调；闭关 Research 更耗；剩余寿元跨篇章结转；内容侧正数量值、物化取负）；**目标时长已上调为 30–40 / 35–45 / 45–55 分钟**（熟练玩家口径），故反推出的**单次定价将显著低于先前设想、一个篇章的事件总数显著变多**。仍待定：**哪些事件类型多耗、单次幅度各是多少**。→ `20-systems/balance.md`、`20-systems/adventure-event/`。
- **非境界突破的寿元增长途径。** 是否存在（回寿类事件产出）未定。→ `20-systems/adventure-event/`、`20-systems/balance.md`。
- **AdventurePlot 数据编码与剧本服务契约。** 四级结构、「Character 只存 key points、内容在剧本服务」、离线降级（事务前置 + `user://cache/plot/` LRU 预取）均已定；仍待定：树的数据表达（**调制** eventOptions 还是并行结构）、key points 粒度 / schema、剧本服务**请求 / 下发协议与版本化**、DnD 式选分支触发点与 UI。→ `20-systems/services/plot-manager.md`。
- **剧本预取与事务前置的边界。** **LRU 容量上限**、**预取失败是否静默**（留待实际请求时再报）未定。→ 同上。

### ⑤ 服务契约 / 工程侧残留（焦点，但均为下一层细节）

> 「七个服务的 API 面未定义」已答结（八条契约总则、共享核心类型、逐服务签名骨架、EventBus 负载 schema 均已定案，权威在 `20-systems/architecture.md`「API 契约总则」；移出记录见 `answer-logs/log-service-api-contracts.md`）。

- **`[Export] bool UseOfflineBackend` 的发布期防护。** 四个边界服务的离线 stub 开关默认 `true` 直到后端上线；正式包如何保证它不为 `true`（导出预设 / 编译期 `#if` / 启动期断言）未定——**这是一个能悄无声息发到线上的开关**。→ `system-overview.md`。
- **`OpError` → 玩家文案的映射归属。** 这份映射表由谁持有（UI 层常量？本地化表？服务返回已本地化串？）。→ `40-ux/`。
- **EventBus 退订纪律的可执行性。** 「`_Ready` 订阅 / `_ExitTree` 退订」是约定；漏退订即泄漏且在 C# 事件上不报错。是否需要 EventBus 侧的调试期订阅计数 / 泄漏检查？→ `20-systems/architecture.md`。
- **`AllEnabled()` 纪律的可执行性。** 约定已立（抽取必走 `AllEnabled()`），但如何在代码评审之外强制未定：`All()` 是否应改名为 `AllIncludingDisabled()` 让默认路径就是安全路径？还是靠 Roslyn 分析器 / 评审清单？→ `20-systems/services/content-service.md`。
- **`manifestSchema` 的版本化。** 它触发整包全量重下，但自身版本号形态、与 `contentVersion` / `appVersion` 的关系未定。→ 同上。
- **`revision` 的产生方与语义。** 断线合并依赖比较云端与本地基线的 `revision`（单调递增计数？服务端时间戳？ETag？），由谁分配、客户端如何持有基线值未定——属**客户端 ↔ 后端协议契约**，应同步登记进 `backend-design-documents/open-questions.md`。→ `20-systems/services/sync-service.md`。
- **软阻塞与「进入战斗前强制 flush」的交互。** 进入战斗前是 Immediate flush 点；若此时已处于断线缓冲超限态，玩家是被挡在战斗外（软阻塞发生在 AdventureEvent 选择前）还是可以进入？两条规则的先后顺序未明写。→ 同上。
- **`.claude/rules/*` 中夹带的设计性表述如何处理。** 主从关系已定（`.claude` = 工程层，见 ADR-0005）；但现存规则文件里确实嵌着设计结论（`state-save-rules.md` 的确定性边界、`data-resource-rules.md` 的 `AllEnabled()` 语义）。这些是「一句话承重纪律 + 回链」的合法形态，还是应进一步瘦身？→ `20-systems/common-properties.md`。
- **`/breakdown-requirements` 的两项形态确认（07-30 新增）：** ① **子需求是否需要用户逐个签核**——当前技能取「**父 FR 签核即覆盖其子需求**」、子需求直接产出为 `ready`，需确认符合意图；② **拆解粒度判据**——当前定为「一次 `/blueprint` 能一口吃下的薄纵切片，1~5 条验收标准，且可在 Godot 中跑出来」，粒度上下界（最多改几个文件 / 是否允许纯数据资源型子需求）仍偏经验。→ `60-requirements/_index.md`。
- **共有属性提炼粒度。** 哪些字段应下沉到子树各自的 `common-properties.md`、哪些留在顶层。→ `20-systems/common-properties.md`。

### ⑥ 元进程的失败侧与中长期规划感（08-01 新增焦点）

- **道统残卷概率的累积规则与上限。** 方向已定（失败累积「下次轮回获得新 PlayerPower」的概率，获得即重置，**不发货币**）；仍待定：**累积粒度**（每次失败 +X%？按抵达的篇章 / 等级深度加权？）、**上限**（是否封顶、封在哪）、**与 seed 公平性的关系**（掷骰走哪条 RNG 子流、是否影响轮回可复现性）、概率状态**落在 PlayerProfile 的哪个字段**。→ `20-systems/player-profile/player-power/`、`20-systems/services/life-cycle-service.md`。
- **中长期规划感的来源（评审提出，未裁决）。** 进程是**逐批择一的线性推进**，既无俯瞰地图也无前方预告——玩家看不到「还有几步到 Finale」、无法为几步之后布局。**篇章时长上调到 30–55 分钟后这条更承重**（一个时段内的事件更多，缺乏方位感的代价更大）。中长期规划感由什么承担（可见的篇章进度条？eventOptions 的前瞻提示？还是有意不给）？→ `20-systems/game-progression.md`、`40-ux/`。

### ⑦ 图鉴族与商业化（08-01b 新增焦点）

- **`CharacterPower` 的机制细节（概念已定，待专场）。** 「轮回级角色能力、对标 PlayerPower」已定案并建档；仍待定：与 PlayerPower 的**复用边界**（是否共用同一份能力定义与 modifier pipeline）、获取 / 失去触发、篇章突破是否随「全部继承」带入、与卡牌 / CharacterItems 的边界、数量与强度尺度。→ `20-systems/character-profile/power/`。
- **其余四个图鉴的解锁触发与词条深度。** EnemyCodex = 遭遇即记、五项文案；能力 / 道具类是「获得即记」「见到即记（含商店中见到）」还是「使用过即记」？词条该写什么？→ `20-systems/player-profile/codex/`。
- **`CharacterPower` 的机制细节（概念已定，待专场）。** 「轮回级角色能力、对标 PlayerPower」已定案；仍待定：与 PlayerPower 的**复用边界**（是否共用同一份 `PowerData` 与 modifier pipeline）、获取 / 失去触发、篇章突破是否随「全部继承」带入、与卡牌 / CharacterItems 的边界、数量与强度尺度。→ `20-systems/character-profile/power/`。
- **图鉴的入口与浏览形态。** 五本图鉴在主菜单如何组织、是否与成就 / 奖励挂钩、战斗内能否查阅（EnemyCodex 尤其相关）。→ `40-ux/screen-flow.md`、`40-ux/combat-ux.md`。
- **premium bundle 的其余细则。** 一次性还是可重复购买（可重复则重试上限如何叠加）？定价与地区？是否还有其他付费点、以及明确排除哪些（抽卡 / 消耗型货币）？→ `20-systems/monetization.md`。
- **两条 PlayerPower 获取渠道的交互与随机口径。** 礼包给的 power 是否重置「道统残卷」的累积概率？两条渠道的「随机」是否共用候选池与排重规则？走哪条 RNG（**不应污染轮回 seed 的确定性**）？→ `20-systems/player-profile/player-power/`、`20-systems/monetization.md`。
- **礼包持有状态的存档表达与服务端权威。** 落成 `CapabilityFlag`、modifier pipeline 的具名修正，还是独立的 `Entitlement` 字段？付费凭证不能只信客户端，故它同时是一条**客户端 ↔ 后端协议契约**，应同步登记进 `backend-design-documents/open-questions.md`。→ `20-systems/services/profile-service.md`、`sync-service.md`。
- **商业化的 UX 观感。** 礼包入口放在哪、是否在重试次数耗尽时提示购买——这直接决定观感是「增值」还是「付费才玩得下去」。→ `40-ux/screen-flow.md`。

---

## 已搁置：内容充实（07-30 起暂不推进）

> **搁置的是「具体条目目录与数值」**——卡牌 / 敌人 / 道具 / 各类事件的清单、平衡数值、奖励内容。它们归开发路线的第 ② ③ 阶段（内容 → 平衡与体验），当前不作为待答焦点。**下列条目不删除、不作废**，只是不再优先拾取；机制先行、内容随后填充。
>
> **交叠地带需确认：** 部分条目既是机制也带数值（例：`lifeSpanCost` 哪些事件类型覆写基准；`EventOption` 完整物化字段清单此前明确标注为「需要一次**内容侧** handoff」）。本次把**规则性的一半留在焦点区**、**目录 / 数值性的一半放入本区**；若解读有偏差请指出。

- **内容目录整体未编写：** 卡牌定义与起始卡组、**敌人目录（含其等级、招式与定制卡组）**、意图目录、遭遇战（encounter）编排、道具目录、各类型 AdventureEvent 的具体条目。→ `20-systems/character-profile/deck/`、`item/`、`20-systems/adventure-event/**`。
- **成就两档奖励内容：** 阈值（60% / 90%）、一次性、80/20 可见已定；仅剩**两档各发放何种奖励**（PlayerPower / PlayerItem / 账号级）待定。→ `40-ux/screen-flow.md`、`20-systems/player-profile/achievements/`。
- **平衡数值整体：** ante / 篇章缩放、掉落权重、成本档位、奖励曲线。→ `20-systems/balance.md`。
- **元进程持久化字段结构：** `PlayerPower` / `PlayerItem` / `Achievements` / `GameSetting` / `AccountInfo` 语义已澄清、服务归属已定（profile-service）、文档落位已定；但**各自字段 schema 与解锁 / 获取 / 失去触发**待定；`status`（启用 / 禁用）与「拥有 / 失去」两态的存档表达未定。→ `20-systems/services/profile-service.md`、`20-systems/player-profile/`。
- **PlayerPower 获取 / 失去触发与公平性：** 方向已定为**轻度提升、PvE-only 可容忍**，且**道统残卷已给出一条获取渠道**（轮回开始时的概率掉落，规则见焦点区 ⑥）；具体在哪些 AdventureEvent 获取 / 失去、是否影响 cycle seed / 计分公平仍待定。→ `20-systems/player-profile/player-power/`。
- **capability flag 的叠加 / 冲突规则：** 两个 power 授予同一 flag 如何处理；多个 modifier 作用于同一 key 的**运算顺序**（加法先于乘法？声明序？优先级字段？）。→ `20-systems/player-profile/player-power/common-properties.md`。
- **AchievementManager 的触发采集面：** 成就进度靠订阅 EventBus 被动采集（解耦但易漏）还是各服务主动上报（可靠但反向依赖）？→ `20-systems/services/profile-service.md`。
- **AccountInfo 字段 schema：** 账号 id / 绑定渠道 / 昵称头像 / 注册时间 / 封禁实名状态等未设计；多渠道绑定同一账号的模型未定。→ `20-systems/player-profile/account-info.md`。
- **GameSetting 的设备本地项 vs 账号级项切分：** 画质 / 震动等设备强相关设置是否应留在本地 `user://` 而不上行云端。→ `20-systems/player-profile/game-setting.md`。
- **disabled 条目被存档引用时的 UX：** 读取侧不过滤故存档能正确解析；但玩家手中一张「已被线上关闭」的卡 / 道具是否应有提示，还是完全静默照常可用？→ `20-systems/services/content-service.md`、`40-ux/`。
- **`ContentEnabled` 的粒度是否够用：** 单一布尔只支持「全开 / 全关」；**灰度与分批放量**需要按玩家分桶（百分比 / 白名单 / 篇章档位），分桶信息放哪（overlay 的另一层配置？后端下发的 bucket 列表？）未定。→ 同上。

### UX 呈现细节（随内容一同搁置）

- **元婴界面（通关证书）的具体形态：** 用途已定（读取并显示最终寿元）；展示哪些字段（最终寿元、用时、修行历程摘要、成就？）、何时弹出、能否回看 / 分享未定。→ `40-ux/screen-flow.md`。
- **寿元告警是否伴随音效 / 震动：** 视觉形态已定（**静态标注于 EventOption 选择界面**）；是否附加听觉 / 触觉反馈未陈述。→ `40-ux/screen-flow.md`。
- **战斗屏幕的其余形态：** 出牌手势（拖拽 vs 点按）、目标指定、手牌布局、回合节奏与动画时长、竖屏下的敌我分区，以及**敌方出牌的呈现方式**（敌人也持有卡组）——待后续战斗 UX 专场。→ `40-ux/combat-ux.md`。（注：**信息面**已在 07-30b 定案为「意图三档 + 探查 + 图鉴」三通道；**主视觉**已在 08-01 定案为「双方道念对比」、lifeTotal 退居次要。二者的残留细节留在焦点区 ①。）
- **道念对比的视觉形态与 lifeTotal 在战斗屏的位置：** 主视觉地位已定；用什么形态（左右对比条 / 双数值 / 天平隐喻）、道念变化的反馈、「道念差」是否显式呈现、以及 lifeTotal 是否仍常驻显示（作为「失败会掉多少」的参照）均未定；**「还剩几回合」的呈现**（定长 10 回合的连带）亦未定。→ `40-ux/combat-ux.md`。

### 尚未设计（占位，暂无具体问题）

- 以下主题文档仍是空占位或仅有骨架，尚无成形问题，待各自专场 handoff 播种：
  - 角色档案：`20-systems/character-profile/item/`（`deck/` 已有骨架，具体卡牌机制仍空）。
  - 玩家档案：`20-systems/player-profile/player-item/`、`account-info.md`、`game-setting.md`（`codex/` 已于 07-30b 播种，问题见焦点区 ①）。
  - 事件内容：`20-systems/adventure-event/` 除 combat 之外的八类子类型（combat 已于 07-30b 开过第一场）。

## derive 就绪度

> **当前：全量回滚，本库尚未进入可 derive 的阶段。** 先前逐文档的 derive 就绪度判定（07-22 ~ 07-25）已**全部作废**——设计仍在快速演进，逐次 handoff 顺带下的就绪度结论会迅速过时且互相矛盾。
>
> **就绪度不再由 `/analyze-new-ideas` 顺带评估或更新。** 它由专门的 **`/assess-derive-readiness`** 全量扫描产出，**由用户在时机成熟时手动调用**；该技能是本小节的**唯一写入者**。在它跑过之前，本小节保持「尚未就绪」。

## 下一阶段

- **ADR 状态：** 已固化 **ADR-0002**（修行事件九类分类，九值枚举）、**ADR-0003**（强制在线 · 云端权威 · 重账号）、**ADR-0004**（境界存档 · 重试模型，含寿元归 0=defeated）、**ADR-0005**（**`.claude` 是工程层、对设计只做薄引用**；07-30 由 `knowledge/` 扩到整个 `.claude`，含 rules / skills 与冲突裁决规则）。ADR 候选：**开发顺序**（框架 → 内容 → 平衡与体验 → 社交及其他，见 `00-vision/scope.md`）；**内容载体形态**（随包基线 + overlay + 版本校验，见 `20-systems/services/content-service.md`）。（注：ADR 现可自由编辑，改决定直接改 ADR，不再新开取代 ADR。）
- **流水线闭环（07-30）：** design → code 链路补上 `/breakdown-requirements`（一份 FR → 一个文件夹的可执行子需求），完整形态见 `README.md` 与 `60-requirements/_index.md`。
- **架构闭环缺口：** 8 处**全部闭合**（移出记录见 `answer-logs/log-0725c.md` 与 `log-0726b.md`）；状态表见 `20-systems/architecture.md` 的「闭环缺口」小节。残留细节已下沉为上方各焦点小节的普通待决问题。
