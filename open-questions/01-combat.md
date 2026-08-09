# ① 战斗机制（焦点之首 · 08-06d 后的残留）

> 本分片属 `../open-questions.md` 的当前焦点区。焦点判据见索引文件。

> 已答结并移出：意图揭示规则（三档）、例外条件、EnemyManager 是否细分、mana 恢复与上限成长、战斗存档 / 取消语义、Finale 结算归属（见 `../answer-logs/log-0730b.md`）；计分模型去向、等级成长途径、等级差是否可见、图鉴解锁触发、`manaLimit` 下界护栏（见 `../answer-logs/log-0801.md`）；战斗终止条件、道念产出途径、胜利侧道念差、`lifeTotal` 归 0 与恢复、意图分界值、敌人等级来源、全局等级序基数、图鉴记录深度、抽象层级命名、ch1 分档、`baseMomentum` 补齐、平局判定、`lifeTotal` 字段改名（见 `../answer-logs/log-0801b.md`）；道念差 1:1 换算、奖励计算归属、失败侧奖励结构、奖励两类形态且选择不是决策点、Practice / Finale 的回合数与胜负条件可变、越级追分可能性、`momentum` 字段类型、`experiencePoint` 为新字段、stack 连响应窗口一并借入（见 `../answer-logs/log-0802.md`）；stack 的借入深度、回合三步结构、交互式回合的移动端形态与时长约束、响应是否耗 mana（见 `../answer-logs/log-0802b.md`）；满手时抽牌 = 抽不进、触发式效果的载体形态、道念下限 0 每次结算截断、敌人赋级上界、战场与栈各升为一个 manager（见 `../answer-logs/log-0803.md`）；借入的 MTG 术语第一批全部定名、触发条件可跨归属方、法则能承载战斗内触发、意图 = 快照故不一致不做处理、战场与参战方的边界判据（见 `../answer-logs/log-mtg-loanwords-and-card-types.md`）；敌人赋级重定义为对称带、栈必须落存档、埋伏进敌人卡池但不计入意图、`IgnoresProtection` ≈1% 配额、不会有凭空生成的牌（见 `../answer-logs/log-0805.md`）；失去法则的 1% 分母 = 全部 event、sync 缓冲闸门口径 = 事件级存档点、`attemptIndex` 整层删除（见 `../answer-logs/log-0806.md`）；法则不会被强制剥夺、`chapterRetry` 的形态（见 `../answer-logs/log-0806_2.md`）；**本片区的战斗待答 38 条一次性全部答结**——意图阈值收紧与赋级带回退 `±2`、`lifeTotalLimit` 概念删除、`ActiveCombat` 存档 schema 与 D0–D6 决策点、卡牌侧数值与效果系统骨架、遭遇参数收进 `EncounterSpec`、enemies 升格为独立系统、九项呈现形态（见 `../answer-logs/log-combat-solutions.md`）。

> **⚠ 治理提示：** 08-06 / 08-06b 曾定「ch1 赋级带 `[−4, +2]` + 降阶碾压硬门、阈值不动」；**08-06d 以更晚的用户裁决取而代之**——**赋级带回退三章统一的对称 `±2`，改由收紧意图阈值化解冲突，降阶硬门取消**。凡在别处读到 `[−4, +2]` 或「降阶 = 碾压」的表述，一律以 08-06d 为准。

## 「本轮回禁用」与置换型剥夺（08-06b 新增 · 优先级最高）

- **「本轮回禁用」的承载字段与生效面（承重）。** 事件侧失去法则已定案为**不强制剥夺**（自愿置换才真移除，其余降级为本轮回禁用）；禁用集合**必须落在轮回级状态上**（账号级 `status` 开关不能承载它）——落 `CharacterProfile` 的哪个位置、被禁用的法则是**开局根本不入场**还是入场后立刻被移除、是否对进行中的战斗立即生效、是否对玩家可见，均未定。→ `systems/character-profile/`、`systems/player-profile/player-power/`、`systems/services/combat-service.md`。
- **置换型剥夺的候选池与对价规则。** 换来的法则从哪个池抽（全池 / 排除已有 / 同稀有度）、玩家能否先看到换来的是什么再决定、拒绝置换是否有代价，以及**置换能否移除神通**（`Scope == Character` 一侧尚未表态）。→ `systems/player-profile/player-power/`、`systems/character-profile/power/`。
- **`ProfileChangeSpec` 表达三类移除的 element 形态。** 按 `Id` 指定 / 随机 / 按 `Scope` 限定；「置换」是原子的双向 element 还是「移除 + 给予」两条；能否出现在 `SelectCost` 侧（置换似乎合理，禁用型不该）；以及 `PushWarning` 逐条列举是否要在事件 outcome 侧补一处对称落点。→ `systems/adventure-event/common-properties.md`、`systems/services/future-event-service.md`。
- **账号级统计计数的容器形态与首批统计项清单（08-09d 收窄）。** 落成 `PlayerStatistics` 类还是直接挂字段？除篇章重试累计与 `TotalCyclesCompleted` 外首批还统计什么（总 defeated 数 / 各 `DefeatReason` 计数）？**宽松同步口径的具体形态**是什么？**已答结的部分：** 与规则字段层的边界（两层通则 + 合并判据 + `Ordinal` 命名硬约定）、统计计数落**宽松侧**、「通关」= 完成整个轮回（`TotalCyclesCompleted`）、**不设 Finale 胜利数与篇章完成数**。→ `systems/player-profile/_index.md`、`systems/services/life-cycle-service.md`、`sync-service.md`。

## 结构与配置的残留

- **带边界与意图阈值门槛的配置落点（08-06b 立）。** 三章的带边界（当前三章同为 `±2`）与意图阈值的三处门槛，放在同一份平衡资源里，还是分属各自的服务配置？是否需要加载时校验（例如「下界不得使 `diff` 门槛不可达」这类一致性检查）？→ `systems/balance.md`、`systems/services/future-event-service.md`。
- **效果关键字体系与目标规则（承重 · 需一次专门 handoff）。** 效果的原子操作清单、求值管线（加法层 + 乘法层）、目标引用形态（`TargetRef`）与「非永久条目须显式声明目标类别」均已定案；**可复用的效果关键字词汇表**与**目标规则的完整判据**（合法目标集如何计算、谁可以指定谁）仍是结构占位。→ `systems/character-profile/deck/common-properties.md`、`systems/adventure-event/common-properties.md`。
- **先后手由谁决定。** 「不设先后手抽牌差」已定案（本作胜负是打满回合比总量、不设提前终止，**先手抢先致死的 tempo 优势根本不存在**，故无需补偿）；但**谁先手**依什么决定（固定角色先手？按等级？随战斗子流掷？）未定。→ `systems/services/combat-service.md`。
- **战斗之外的事件类型的决策点清单。** 战斗内 D0–D6 已定案；其余八类 AdventureEvent 的事件内决策点（每次选择后？揭示后？）尚未逐类给出——它们共享同一形状，清单应当很短。→ `systems/services/life-cycle-service.md`、`systems/adventure-event/`。

## 内容与数值的残留（多数已归 ch1 数值标杆专场）

- **卡牌产 / 削道念的量纲基准（承重 · 已归属专场）。** 一张牌该产多少、10 个回合内一方的总产出相对起始 `baseMomentum` 的倍数、是否存在道念相关的状态与倍率——**它决定越级追分是否可能**。**它同时是本次多条初值的前置依赖**：道具折价系数、战斗内法则的 10% / 25% 闸门、乘法层对方差的放大，在法术基准定出之前都无法被校验。→ `systems/balance.md`、`systems/character-profile/deck/`。
- **`CardData` 的完整字段清单与起始卡组内容。** 类型六分、异能三分、次类型、`Pool`、`Subtypes` 均已定；其余字段（费用、目标声明、效果引用、触发器）与 **starter deck 的具体内容**未设计——**起始卡组正是 ch1 数值标杆专场的切入点**。→ `systems/character-profile/deck/`。
- **敌人 AI 的规划算法。** 「回合级一次性规划」与规划输入（卡组 + 战场 + 本场可用道具 + 对手埋伏计数）已定；具体算法、多回合行为倾向、难度旋钮的落点未定义。→ `systems/enemies/`。
- **敌人各等级的道念产出缩放。** 起始值已由 `baseMomentum` 给定，产出能力的缩放曲线未定。→ `systems/balance.md`。
- **`PoolScope` 的数据形态。** 是一个带 `LocationId?` / `PlotLineId?` 两个可空字段的内嵌类型，还是一组 tag？与 location / 剧情线的内容条目如何交叉校验（悬空引用）？→ `systems/enemies/`、`systems/services/future-event-service.md`。
- **阵法与灵宠的区分轴（用户明确留待日后）。** 目前二者的规则差别为零；次类型只是各自的内部分档，不构成主类型间的差异化。→ `systems/character-profile/deck/`。

## 呈现的残留

- **第二档「仅类别」的视觉语言（承重级别按篇章不同）。** 四类的**正式枚举已定案**（`Offense / Defense / Buff / Special`，20% 贡献阈值选主类别，单行横排永不换行、区域 ≈ 屏高 8%）；仍待定**符号 / 剪影体系本身**——用什么图形表达、如何与完整意图的图标体系区分。**在 ch1 它是常态呈现、直接决定战斗可读性；在 ch2 · ch3 退为窄档**（第二档只剩 `diff = 0`）。→ `ux/combat-ux.md`。
- **道念对比的视觉形态、回合进度与道念差的组合呈现、lifeTotal 是否常驻战斗屏。** 主视觉地位已定，形态未定。→ `ux/combat-ux.md`。
- **栈与战场的同屏呈现。** ticker 已答结了「连锁可读性」的一半；仍待定竖屏上如何同时表达「哪些在等待结算、以什么顺序」与「哪些已经在生效」、两区如何视觉区分、结算动画如何不拖慢节奏。→ `ux/combat-ux.md`。
- **战后奖励面板的形态。** 候选固定 3 项、预先算定、不设放弃通道均已定案；**强制项与可选项如何同屏区分**、竖屏排布、与事件收口的视觉衔接未定。→ `ux/combat-ux.md`。
- **竖屏分区的整体排布（本作压力最大的一处）。** 需容下战场 / 栈 / 手牌 / 道念对比 / 回合计数 / 意图区，再加法则条、随身角标、埋伏标记；**己方战场区左右两侧同时挂法则条与随身角标会挤压战场可用宽度，须在实际排版时验证**。→ `ux/combat-ux.md`。
- **战斗屏幕的其余形态整体未设计**——出牌手势、手牌布局、回合节奏与动画时长、敌我分区、敌方出牌的呈现方式，待一次专门的战斗 UX 专场。→ `ux/combat-ux.md`。
