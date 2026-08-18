# ① 战斗机制（焦点之首 · 08-06d 后的残留）

> 本分片属 `../open-questions.md` 的当前焦点区。焦点判据见索引文件。

> 已答结并移出：意图揭示规则（三档）、例外条件、EnemyManager 是否细分、mana 恢复与上限成长、战斗存档 / 取消语义、Finale 结算归属（见 `../answer-logs/log-0730b.md`）；计分模型去向、等级成长途径、等级差是否可见、图鉴解锁触发、`manaLimit` 下界护栏（见 `../answer-logs/log-0801.md`）；战斗终止条件、道念产出途径、胜利侧道念差、`lifeTotal` 归 0 与恢复、意图分界值、敌人等级来源、全局等级序基数、图鉴记录深度、抽象层级命名、ch1 分档、`baseMomentum` 补齐、平局判定、`lifeTotal` 字段改名（见 `../answer-logs/log-0801b.md`）；道念差 1:1 换算、奖励计算归属、失败侧奖励结构、奖励两类形态且选择不是决策点、Practice / Finale 的回合数与胜负条件可变、越级追分可能性、`momentum` 字段类型、`experiencePoint` 为新字段、stack 连响应窗口一并借入（见 `../answer-logs/log-0802.md`）；stack 的借入深度、回合三步结构、交互式回合的移动端形态与时长约束、响应是否耗 mana（见 `../answer-logs/log-0802b.md`）；满手时抽牌 = 抽不进、触发式效果的载体形态、道念下限 0 每次结算截断、敌人赋级上界、战场与栈各升为一个 manager（见 `../answer-logs/log-0803.md`）；借入的 MTG 术语第一批全部定名、触发条件可跨归属方、法则能承载战斗内触发、意图 = 快照故不一致不做处理、战场与参战方的边界判据（见 `../answer-logs/log-mtg-loanwords-and-card-types.md`）；敌人赋级重定义为对称带、栈必须落存档、埋伏进敌人卡池但不计入意图、`IgnoresProtection` ≈1% 配额、不会有凭空生成的牌（见 `../answer-logs/log-0805.md`）；失去法则的 1% 分母 = 全部 event、sync 缓冲闸门口径 = 事件级存档点、`attemptIndex` 整层删除（见 `../answer-logs/log-0806.md`）；法则不会被强制剥夺、`chapterRetry` 的形态（见 `../answer-logs/log-0806_2.md`）；**本片区的战斗待答 38 条一次性全部答结**——意图阈值收紧与赋级带回退 `±2`、`lifeTotalLimit` 概念删除、`ActiveCombat` 存档 schema 与 D0–D6 决策点、卡牌侧数值与效果系统骨架、遭遇参数收进 `EncounterSpec`、enemies 升格为独立系统、九项呈现形态（见 `../answer-logs/log-combat-solutions.md`）；**「本轮回禁用」与置换型剥夺片区的四条一次性全部答结**——`disabledAbility` 承载字段与三档时长、禁用生效判据（截断在进入生效面那一步）、置换候选池与对价、`ProfileChangeSpec` 三列表 element 形态、`PlayerStatistics` 与首批两项、宽松同步口径五条（见 `../answer-logs/log-ability-deprivation-and-player-statistics.md`）；效果关键字体系与目标规则的完整判据（见 `../answer-logs/log-effect-keywords-and-targeting.md`）。

> **⚠ 治理提示（08-15d 更新）：** **敌人意图机制已整条移除**（三档揭示 · `IntentCategory` · 快照语义 · 探查通道全部作废），敌人回合的可读性改由逐步执行呈现 + 敌人图鉴 + 战场承担。凡在别处读到「意图三档 / 越阶黑箱 / 仅类别 / 探查」的表述，一律以 `handoffs/2026-08-15d-intent-removal-lifespan-cost-visibility-and-design-audit.md` 为准；`±2` 赋级带**保留**（其消费点是 `baseMomentum` 起跑线）。
>
> 更早：08-06 / 08-06b 曾定「ch1 赋级带 `[−4, +2]` + 降阶碾压硬门」，**08-06d 已以更晚的用户裁决取而代之**——赋级带回退三章统一的对称 `±2`，降阶硬门取消。凡读到 `[−4, +2]` 或「降阶 = 碾压」，一律作废。

## 能力剥夺与统计计数的残留（08-10c 后）

> 「本轮回禁用」与置换型剥夺片区的**四条并列待答已全部答结**（承载字段 `disabledAbility` · 三档时长与生效判据 · 置换候选池与对价 · `ProfileChangeSpec` 三列表 element 形态 · `PlayerStatistics` 与首批两项 · 宽松同步口径五条 · `PushWarning` 对称落点归内容加载侧），见 `../answer-logs/log-ability-deprivation-and-player-statistics.md`。

- **`RarityTier` 的分布与权重表（08-10c 新增）。** 五档已定名并挂上 `PowerData` / `ItemData` / `CardData`；**结构面已答定**——授予池权重表已给出结构与初值，置换候选池不需要权重表（同档等概率），分表维度按**用途**（授予 / 战后奖励）而非渠道、亦非 `(Kind, Scope)`。仍待定：**战后奖励池**各档权重（按优势档 `Tier` 三档各一张表）、内容侧「每档应有多少条目」的编排口径、`GrantPoolMargin` / `K` 的取值。→ `systems/balance.md`、`systems/services/combat-service.md`。
- **`StatKey` 的完整成员清单（08-10c 新增 · 轻）。** 首批两项已定；随统计项增长的命名与登记方式、如何在书写上与 `CostKey` 明确分开未定。→ `systems/services/profile-service.md`。

## 结构与配置的残留

- **带边界的配置落点（08-06b 立 · 08-15d 收窄）。** 三章的 `±2` 带边界放在平衡资源里，还是服务配置里？**意图阈值那一半随机制移除而作废**，「下界不得使 `diff` 门槛不可达」这类一致性检查亦随之消失。→ `systems/balance.md`、`systems/services/future-event-service.md`。
- **战斗之外的事件类型的决策点清单。** 战斗内 D0–D6 已定案；其余四类 AdventureEvent 的事件内决策点尚未逐类给出——它们共享同一形状，清单应当很短。**Research 那一条已给出**（构筑面板的每个决策槽各是一个决策点，候选在物化时即已掷定）；仍欠 Exchange / Explore / Travel 三类。→ `systems/services/life-cycle-service.md`、`systems/adventure-event/`。

## 内容与数值的残留（多数已归 ch1 数值标杆专场）

- **卡牌产 / 削道念的量纲基准（承重 · 已归属专场）。** 一张牌该产多少、10 个回合内一方的总产出相对起始 `baseMomentum` 的倍数、是否存在道念相关的状态与倍率——**它决定越级追分是否可能**。**它同时是本次多条初值的前置依赖**：道具折价系数、战斗内法则的 10% / 25% 闸门、乘法层对方差的放大，在法术基准定出之前都无法被校验。→ `systems/balance.md`、`systems/character-profile/deck/`。
- **`CardData` 的完整字段清单与起始卡组内容。** 类型五分、异能三分、次类型、`Pool`、`Subtypes`、**目标声明与效果引用两格**均已定；其余字段（费用、触发器）与 **starter deck 的具体内容**未设计——**起始卡组正是 ch1 数值标杆专场的切入点**。→ `systems/character-profile/deck/`。
- **关键字与次类型的首批清单（08-16c 新增）。** 两套机制均已完整定案、两套清单均为空；填什么条目要从「哪些组合真的重复了 ≥3 次」倒推，切入点同为 starter deck 的设计过程。→ `systems/character-profile/deck/common-properties.md`、`systems/balance.md`。
- **敌人 AI 的决策形态（08-15d 收窄 · 约束已解除）。** 「回合级一次性规划」这条硬约束**已随意图移除而解除**，AI 可在自己回合内逐张决策。具体算法、决策粒度（一次性 vs 逐张）、多回合行为倾向、难度旋钮的落点均未定义。→ `systems/enemies/`。
- **敌人各等级的道念产出缩放。** 起始值已由 `baseMomentum` 给定，产出能力的缩放曲线未定。→ `systems/balance.md`。
- **敌人池的篇章框定载体未定（08-17 新增 · 承重）。** 敌人取池的第三层写着「篇章框定照旧」，而 `EnemyData` 的字段面（`EncounterScopes` / `PoolScope` / `OverridesDeck`）没有任何一格表达篇章。载体定下之前，「通用池在某组合下为空 → 启动期 `PushError`」这条校验只能按 `EventType` 单维实现；它同时决定内容侧「一个敌人属于哪几章」写在哪。→ `systems/enemies/`、`systems/services/future-event-service.md`。
- **功法的规模参数（08-12f 新增 · 归 ch1 数值标杆专场）。** 功法（`CultivationTechnique`）已定为卡组的构筑单位、层数提升 = **整组替换**；仍待定：**一门功法含几张牌**、**层数上限**是几、**每层的替换幅度**多大。与「一张牌该产多少道念」「起始卡组给多少张」是同一个未知的几个面。→ `systems/balance.md`、`systems/character-profile/deck/`。
- **敌人是否也以功法构筑卡组（08-12f 新增）。** 功法已定为**角色侧**的构筑单位；`EnemyData` 的样本卡组仍是直接的卡牌列表。若敌人也用功法，图鉴词条②「功法简介」可与系统概念合流、敌人内容的编写颗粒度随之变粗。→ `systems/enemies/`、`systems/player-profile/codex/enemy-codex.md`。
- **卡组规模的实际取值（08-11c 重定）。** 规则层两侧均**不设硬限**，故这是内容 / 构筑层的问题：起始卡组给多少张、敌人样本卡组的常用区间落在哪里。**疲劳规则使规模直接换算为后期失血速率**，与「一张牌该产多少道念」是同一个未知的两面 —— 归 ch1 数值标杆专场。→ `systems/balance.md`、`systems/character-profile/deck/`。
- **疲劳量是否可调（08-11c 新增 · 轻）。** 当前固定「每张 1 点」。是否作为 `EncounterSpec` 的可空覆写（与抽牌数 / 手牌上限同一档旋钮），取决于是否会出现「疲劳流」这类构筑方向。→ `systems/balance.md`。
- **失败后果的其余部分（08-16b 采集 · 此前未进清单）。** 胜利奖励随道念差变厚已定；**失败除扣 `lifeTotal` 外是否另有后果**未定（`Finale` 档失败 = 不另开终结通道，已定）。→ `systems/adventure-event/combat/_index.md`。
- **储物袋 9 格对道具经济的回压（08-11c 新增 · 承重）。** 满袋再获得一件如何处理（拒收 / 强制择一丢弃 / 奖励侧过滤）、道具获取频率与商店库存深度是否同步下调、置换对价是否需要重估 —— 这些此前都建立在 99 格近乎无限的前提上。→ `systems/character-profile/item/_index.md`、`systems/adventure-event/exchange/`。

## 信息面的残留（意图移除后 · 08-16b 采集，此前未进清单）

> 意图机制整条移除后，事前知识只剩**敌人图鉴**一条主通道（战斗内的动态情报归 ticker，见下方「呈现的残留」）。这两条决定那条主通道够不够宽。

- **敌人图鉴的慷慨度是否该上调（承重）。** 图鉴现为**事前知识的主通道**；「一次遭遇即解锁全部词条」是否够、是否该给出**样本卡组的完整列表**而非只给关键卡牌，未定。它与 `07-codex-monetization.md` 的「其余四本图鉴的词条深度」是同一问题在 EnemyCodex 上的一面，宜一并答。→ `systems/player-profile/codex/enemy-codex.md`。
- **是否要一条「花代价买信息」的通道。** 当前没有这样的通道（探查随意图一并作废）。若要建，须先定义标的（敌人抽牌堆顶 N 张 / 敌人本场可用道具 / 其他）与代价形态。→ `systems/adventure-event/combat/_index.md`、`systems/character-profile/deck/`。

## 呈现的残留

- **结算 ticker 的文案体系（08-15d 新增 · 承重）。** 意图移除后 ticker 是**唯一**的动态情报通道，它写什么、写多细直接决定敌人回合是否可读。仍待定：单行文案的信息量、连锁触发如何在单行内表达、展开态的分组与排版、**与飘字的分工边界**。排布约束已定（单行、永不换行、固定预留 ≈ 屏高 6%）。→ `ux/combat-ux.md`。
- **道念对比的视觉形态、回合进度与道念差的组合呈现、lifeTotal 是否常驻战斗屏。** 主视觉地位已定，形态未定。→ `ux/combat-ux.md`。
- **栈与战场的同屏呈现。** ticker 已答结了「连锁可读性」的一半；仍待定竖屏上如何同时表达「哪些在等待结算、以什么顺序」与「哪些已经在生效」、两区如何视觉区分、结算动画如何不拖慢节奏。→ `ux/combat-ux.md`。
- **战后奖励面板的形态。** 候选固定 3 项、预先算定、不设放弃通道均已定案；**强制项与可选项如何同屏区分**、竖屏排布、与事件收口的视觉衔接未定。→ `ux/combat-ux.md`。
- **竖屏分区的整体排布（本作压力最大的一处 · 08-15d 加压说明）。** 需容下战场 / 栈 / 手牌 / 道念对比 / 回合计数 / 结算 ticker，再加法则条、随身角标、埋伏标记；**己方战场区左右两侧同时挂法则条与随身角标会挤压战场可用宽度，须在实际排版时验证**。**体检登记：根子是把 MTG 的完整分区模型搬进手机竖屏**——尤其**栈在零交互下玩家做不了任何事、只能看**，它是否必须常驻（而非结算时的临时演出层）值得重估。意图区移除已释放约屏高 8%，但未触及根因。**已排期：单开一个专门 session 答疑（08-16 确认）**，不在逐次 handoff 中零敲碎打。→ `ux/combat-ux.md`。
- **道具区 / 神通法则条 / 埋伏标记 / 卡牌类型标识的四项具体形态（08-16b 采集 · 此前未进清单）。** 落位与视觉语言已定方向（道具 = 角标 + 抽屉、`Power` = 低权重小图标条且长按查看详情、埋伏 = 只给计数、卡牌类型 = 卡框色 + 类型角标）；**具体形态未定**，且**带启动式异能的 `Power` 那个可点击入口如何与「视觉权重要低」并存**亦未定。它是上一条竖屏分区压力的四个具体来源，宜在同一场专场内一并定。→ `ux/combat-ux.md`。
- **疲劳的呈现（08-11c 新增）。** 抽牌堆剩余张数是否常驻、见底预警、以及疲劳扣减与「被对手削减」在视觉上如何区分（两者都是自己的道念下跌，归因完全不同）。→ `ux/combat-ux.md`。
- **战斗屏幕的其余形态整体未设计**——出牌手势、手牌布局、回合节奏与动画时长、敌我分区、敌方出牌的呈现方式，待一次专门的战斗 UX 专场。→ `ux/combat-ux.md`。
