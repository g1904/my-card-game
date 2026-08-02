# ① 战斗机制（焦点之首 · 08-02 后的残留）

> 本分片属 `../open-questions.md` 的当前焦点区。焦点判据见索引文件。

> 已答结并移出：意图揭示规则（三档）、例外条件、EnemyManager 是否细分、mana 恢复与上限成长、战斗存档 / 取消语义、Finale 结算归属（见 `../answer-logs/log-0730b.md`）；计分模型去向、等级成长途径、等级差是否可见、图鉴解锁触发、`manaLimit` 下界护栏（见 `../answer-logs/log-0801.md`）；战斗终止条件、道念产出途径、胜利侧道念差、`lifeTotal` 归 0 与恢复、意图分界值、敌人等级来源、全局等级序基数、图鉴记录深度、抽象层级命名、ch1 分档、`baseMomentum` 补齐、平局判定、`lifeTotal` 字段改名（见 `../answer-logs/log-0801b.md`）；**道念差 1:1 换算（及不设截断、改由内容侧赋级上界规避）、奖励计算归属、失败侧奖励结构、奖励两类形态且选择不是决策点、Practice / Finale 的回合数与胜负条件可变、越级追分可能性、`momentum` 字段类型、`experiencePoint` 为新字段、stack 连响应窗口一并借入**（见 `../answer-logs/log-0802.md`，其中最后一条已被 08-02b 收窄）；**stack 的借入深度（交互与优先权移除）、回合三步结构、交互式回合的移动端形态与时长约束、响应是否耗 mana**（见 `../answer-logs/log-0802b.md`）；**满手时抽牌 = 抽不进、触发式效果的载体形态（开放式多载体）、道念下限 0 在每次结算时截断、敌人赋级上界 = 高一个大境界的初期、战场与栈各升为一个 manager**（见 `../answer-logs/log-0803.md`）。

## 战斗结构的残留（08-02 后 · 优先级最高）

- **⚠ 赋级上界与 lifeTotal 的算术冲突（08-03 新增 · 承重 · 需用户裁决）。** 上界已定为**高一个大境界的初期**，但它按**境界**给而非按 `diff` 给——**境界内低层角色面对的最坏差距远大于高层角色**：炼气一层（`baseMomentum` 1）对筑基初期（20）开局落后 19，而炼气 `lifeTotal` 仅 10/10，**一次惨败即打穿耐久**，恰是这条上界原本要规避的情形。收口候选：① 再叠一条相对 `diff` 上界；② 只在境界后期才允许出到上界档；③ 抬 `lifeTotalLimit` 的境界基线。→ `20-systems/services/future-event-service.md`、`20-systems/balance.md`、`20-systems/character-profile/life-total.md`。
- **BattlefieldManager 与两个参战方 manager 的边界划线（08-03 新增 · 承重）。** 「属于某一方的归参战方、场上生效的归战场」是推演出的划法，未经陈述：**附着在某一方身上的持续状态**（例：「我方本回合所有牌 +1 道念」）算战场条目还是参战方状态？双方各自的场区是否分开记录？→ `20-systems/services/combat-service.md`。
- **战场与栈的存档形态（08-03 新增）。** 决策点存档要求局面可恢复 ⇒ **战场条目须可序列化**；**栈是否需要落存档**取决于「决策点是否总落在栈为空的时刻」（栈非空时双方都不能出牌，故很可能是），未确认。→ `20-systems/services/combat-service.md`、`sync-service.md`。
- **触发条件能否跨归属方（08-02b 新增 · 08-03 收窄）。** **载体形态已答定**（牌上触发器 / 场上持续状态 / CharacterPower，清单开放）；仍待定触发条件能否写「对手的回合开始时」这类跨归属方的时点（时点本身有归属方，但监听方未必是归属方）。→ `20-systems/character-profile/deck/`、`20-systems/services/combat-service.md`。
- **PlayerPower（法则）能否承载战斗内触发（08-03 新增）。** 神通（CharacterPower）已确认可承载；账号级的法则未陈述。若可，则 combat-service 还要读 PlayerProfile 一侧的持有列表。→ `20-systems/player-profile/player-power/`、`20-systems/services/combat-service.md`。
- **「加入手牌」落空时凭空生成的牌去哪（08-03 新增）。** 从抽牌堆抽的情形已明确（**留在堆里**）；但若效果是**生成一张新牌**（token 类）或**从弃牌堆 / 牌库外取牌**，满手时该牌是根本不产生、还是产生后进弃牌堆？→ `20-systems/character-profile/deck/`。
- **回合三步结构留下的其余卡牌侧空缺（08-02b 新增 · 08-03 部分收窄）。** **每回合抽牌数**、首回合是否抽、起始手牌数、先后手是否有抽牌差；**手牌上限的数值**（敌人侧是否同值）；**「回合内状态」的判定边界**——**承载结构已定**（战场上带生命周期标记的条目），仍待定取值（结束步清理哪些东西、「持续到下回合结束」如何表达）。→ `20-systems/character-profile/deck/`、`20-systems/adventure-event/combat/`。
- **敌人赋级的分布规则（08-03 收窄）。** **上界已答定**（高一个大境界的初期）；仍待定**分布**——上界档多久出现一次、以什么权重出现、依什么决定这次给几级。→ `20-systems/services/future-event-service.md`、`20-systems/balance.md`。
- **Finale 的天劫是否同受赋级上界约束（08-03 新增）。** 若受约束则**天劫 = 下一境界的初期**（与「渡劫即突破到该境界」的叙事吻合）；若不受则天劫可任意越阶。→ `20-systems/adventure-event/finale/`。
- **`experiencePoint` 的阈值曲线与产出分布（08-02 新增 · 承重）。** 载体已定案（新字段、每级一个阈值、事件发经验、失败也给）；仍待定：**各级阈值曲线**（炼气 13 级 / 筑基 · 金丹各 4 级，线性还是递增、每境界是否重置量纲）、**单次事件的经验给予量**（与阈值互为倒数，须一同定）、在事件池中的分布、失败给的比胜利少多少。→ `20-systems/game-progression.md`、`20-systems/balance.md`。
- **胜利侧的「道念差 → 奖励厚度」换算。** 负侧已 1:1；胜侧仍是定性表述（碾压 > 险胜）。若也 1:1，「1 点道念差」在奖励侧等于什么单位（灵玉？候选项数量？某个权重）未定。→ `20-systems/balance.md`。
- **可选奖励的候选生成（08-02 新增）。** 候选项数量、抽自哪个池、是否受道念差影响未定。**约束已给**：候选须**预先算定**（走 `Reward` 子流、随战斗 RNG `State` 持久化），使退出重进得到同一组选项——**奖励选择因此不是决策点**。→ `20-systems/services/combat-service.md`、`20-systems/balance.md`。
- **回合数与胜负判据落在哪个类型上（08-02 新增）。** 二者已定为**遭遇参数**（可被 Practice / Finale 改写），故 `EncounterSpec` 需携带它们，或由 `EnemyTemplate` / 事件模板带入——当前 `EncounterSpec` 只有 `(EncounterId, IsFinale)`。→ `20-systems/services/combat-service.md`。
- **Practice / Finale 的具体改写值。** 方向已定（一简一难，对位 small / boss blind）；**取值未给**：Practice 是更少回合（更快）还是更多回合（更宽容）？Finale 的额外门槛取什么形式（必须领先 N 点？）、失败是否直接 defeated？→ `20-systems/adventure-event/practice/`、`finale/`、`20-systems/balance.md`。
- **借入的 MTG 术语清单与中文定名（08-02 新增 · 08-02b 收窄）。** 借词纪律已立（须在 `terminology.md` 登记为已定含义、不覆盖既有仙侠定名）。**已定：`instant`（瞬间）不借**（交互移除）；**已登记：stack = 堆栈、回合结构三步、回合归属方**。**待定名的第一批 = `sorcery speed` / `start step` / `main phase` / `end step` / `resolve` / `trigger`**。→ `terminology.md`、`20-systems/character-profile/deck/`。
- **`CombatSnapshot` / `PlayResult` 的道念字段形态。** 类型已定（`momentum` = 非负整数）；二者必须承载道念（否则战斗 UX 的「双方道念对比」主视觉无数据可读），但**结构**（当前值 + 本次增量？分来源？**意图削减量 vs 实际削减量**？）依赖卡牌内容设计。→ `20-systems/services/combat-service.md`。

## 等级与意图（08-01b 后的残留）

- **等级产出的频次与分布。** **途径已定**（等级成长 = event reward，不只战斗类、失败也可能给）；仍待定：一章内需要多少个「升级型产出」才能从 1 爬到 13 / 1 到 4、如何分布在事件池中、失败产出是否弱于胜利。**它与寿元预算的花法互相约束**，且**篇章时长上调后事件总数变多**，这条更承重。→ `20-systems/game-progression.md`、`20-systems/balance.md`。
- **意图类别的枚举（08-02c 加压 · 承重）。** 展示粒度定为「攻击 / 防御 / 增益 / 特殊」，其正式枚举与敌人行为的映射未定；视觉语言（同一图标去掉数值，还是另一套模糊化视觉）亦未定。**阈值下移后第二档是常态档**（同级对局也只给类别），这条因此直接决定战斗可读性；**跨类别呈现已答定 = 主类别并行陈列**，故视觉语言还须容纳一条摘要里 2~4 个类别符号的竖屏排布。→ `20-systems/adventure-event/combat/`、`40-ux/combat-ux.md`。
- **承诺与执行不一致时如何处理（08-02c 追加 · 由「意图即承诺」推出）。** 意图公布后不重算已定案；但玩家行动可能让计划中的某张牌在敌人回合无法照原样执行（mana / 资源变化、目标状态改变、牌被移出手牌）：**跳过该张照打其余**、**降级执行**（打出但效果打折）、还是**允许临场替换**（等于开了重算的口子）？其呈现方式亦未定。→ `20-systems/services/combat-service.md`、`20-systems/character-profile/deck/`、`40-ux/combat-ux.md`。
- **意图区收起后的布局稳定性（08-02c 追加）。** 「敌人回合内收起」已定案；**怎么收**未定——固定预留高度还是让其余元素上移？是否有收起 / 展开动画？竖屏下位置与尺寸未定。→ `40-ux/combat-ux.md`。
- **`EnemyTemplate` 与 `EnemyData` 是否同一个东西；物化后的敌人实例如何承载。** 来源已答定（模板 + 物化赋级）；仍待定：二者是否需统一定名、实例叫什么（`EnemyInstance`？）、**嵌在 `EventOption` 上随批次落存档还是战斗开始时再展开**、一个事件带多个敌人时如何组织，以及 `EncounterSpec` 如何承载它。→ `20-systems/services/future-event-service.md`、`combat-service.md`。
- **物化时「充实 / 改写」敌人的规则。** 依什么决定这次给几级、样本卡组怎么改（角色等级？篇章？location？剧本调制？）未陈述。→ `20-systems/services/future-event-service.md`、`20-systems/balance.md`。
- **敌人等级标注的措辞。** 承载已定（随物化产物定稿）；仍待定用什么措辞（境界名 + 层级 / 全局序数字 / 并列）、是否同屏并列玩家自身等级。→ `40-ux/combat-ux.md`。
- **敌人图鉴的写作规格与实例信息。** 五项词条内容已定（背景 / 功法 / 运作方式 / 特点与弱点 / 关键卡牌）、一次遭遇全解锁已定；仍待定：每项的长度与写作口径、「关键卡牌」列几张由谁标注、**词条挂模板而敌人等级是物化产物**——是否需标注「本次遭遇的是 X 级」、是否影响战斗内呈现、战斗内能否查阅。→ `20-systems/player-profile/codex/enemy-codex.md`。

## 结构与存档

- **module 以下的下沉判据未给。** 五级层级词已定（service / manager / module / processor / handler），但「什么时候一个 module 该再拆出 processor」没有判据——第四 / 第五级目前只有名字、无实例。→ `20-systems/architecture.md`。
- **决策点的粒度（08-02 加压 · 08-02b 减压）。** 「事件过程按决策点落存档」已定，但决策点具体指哪些位置（事件内每次选择后？战斗内每回合开始 / 每次出牌后 / 每次结算后 / 三步的某个步边界？）未定；粒度直接决定本地写入频率与 push 防抖压力。**「须覆盖响应窗口与优先权移交」这条加压已随交互移除而作废**，回合内的可退出时刻回落到回合 / 出牌这一级。（**战后奖励选择已明确不是决策点**。）→ `20-systems/services/combat-service.md`、`life-cycle-service.md`、`sync-service.md`。
- **`attemptIndex` 是否还需要（动机已消解）。** 决策点存档 + RNG `State` 持久化已关闭「退出重进重掷」窗口。剩余问题收窄为：**篇章重试（ADR-0004）重开同一篇章时，同名事件是否应换一套战斗随机**——若应则保留派生层并令 `attemptIndex` = 篇章重试次数，若不应则整层可去掉。→ `20-systems/common-properties.md`、`20-systems/services/life-cycle-service.md`。
- **`AdvanceEventAsync` 的取消触发方。** 成本处置已定（`SelectCost` 不回滚、视同已结算）；仍待定「**谁**会取消一场进行中的事件 / 战斗」（玩家主动退出 / 断线 / 应用挂起）及取消如何与最近决策点对齐。→ `20-systems/services/life-cycle-service.md`、`sync-service.md`。

## 战斗内容与规则（既有残留）

- **回合内的效果 / 状态系统。** 增益 / 减益 / 持续效果的**具体内容**仍空白，但**骨架已有三条**：① 结算模型 = stack（先入栈、后进先出，无响应窗口）；② 三步结构给出的两个触发时点（「回合开始时」/「回合结束时」）与「回合内状态」这一生命周期档位；③ **08-03：承载结构 = 战场（battlefield）上带生命周期标记的条目，触发载体开放（牌上触发器 / 场上持续状态 / 神通）**。仍待定的是各条目的取值与它与 `CardInstance` 运行态可变性的关系。**交互移除后，回合间的节奏张力全部落在效果系统与卡牌设计上**（不再有响应窗口分担）。→ `20-systems/adventure-event/combat/`、`20-systems/character-profile/deck/`。
- **敌方卡组的设计形态。** 敌人也出牌已定；其卡牌是与玩家共用 `CardData` 体系 / 共用卡池，还是另立敌方卡池，以及卡组规模与抽牌规则均未定。→ `20-systems/character-profile/deck/`、`20-systems/adventure-event/combat/`。
- **探查（probe）的实现形态。** 定名与方向已定，**本阶段明确搁置**：花费形式（mana / 弃牌 / 每场次数）、授予途径（卡牌 / 能力 / 道具）、可探查到哪一档，归卡牌与技能内容的横向扩展阶段。→ `20-systems/character-profile/deck/`、`20-systems/player-profile/player-power/`。
- **`manaLimit` 推拉的分档。** 机制已定（由事件 cost / reward 推拉、可升可降），**下界护栏与死牌转化已明确不做**（下降极罕见）；哪些事件推高 / 压低、单次幅度未定；`lifeTotalLimit` 是否采用同一模型亦未陈述。→ `20-systems/character-profile/mana.md`、`life-total.md`、`20-systems/balance.md`。
- **`EncounterSpec` / `CombatSnapshot` / `TargetRef` / `PlayResult` 的完整字段。** API 骨架已定，字段依赖战斗内容设计。→ `20-systems/services/combat-service.md`。
- **天劫是否天然属于「大幅越级」。** Finale 的胜负条件承载已定（回合数与判据可改写、更难，见上方「Practice / Finale 的具体改写值」）；仍独立待定的是：**天劫的等级档位**——若天然大幅越级，则 Finale 全程无意图信息，压迫感由此而来。少部分非战斗形态的 Finale 待日后定制。→ `20-systems/adventure-event/finale/`。
- **Practice 的对手来源。** 对手为 Enemy 已定，「更简单」的承载已定（回合数与胜负条件可放宽）；仍待定：**是否复用 Combat 的敌人条目**还是另立一批「切磋对手」。→ `20-systems/adventure-event/practice/`。
- **enemies 归属。** 现归 `adventure-event/combat/`；**Practice 与 Finale 均已确认使用敌人**（天劫即 Enemy），是否升为共享内容层待拍板。→ `20-systems/adventure-event/combat/`、`20-systems/architecture.md`。
