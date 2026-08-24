# ① 战斗机制（焦点之首 · 08-06d 后的残留）

> 本分片属 `../open-questions.md` 的当前焦点区。焦点判据见索引文件。

> 本片区历次答结问题的逐条移出记录见 `../answer-logs/`（归档权威在那里，本处不复述）。

> **⚠ 治理提示（08-15d 更新）：** **敌人意图机制已整条移除**（三档揭示 · `IntentCategory` · 快照语义 · 探查通道全部作废），敌人回合的可读性改由逐步执行呈现 + 敌人图鉴 + 战场承担。凡在别处读到「意图三档 / 越阶黑箱 / 仅类别 / 探查」的表述，一律以 `handoffs/2026-08-15d-intent-removal-lifespan-cost-visibility-and-design-audit.md` 为准；`±2` 赋级带**保留**（其消费点是 `baseMomentum` 起跑线）。

## 能力剥夺与统计计数的残留（08-10c 后）

> 「本轮回禁用」与置换型剥夺片区的**四条并列待答已全部答结**（承载字段 `disabledAbility` · 三档时长与生效判据 · 置换候选池与对价 · `ProfileChangeSpec` 三列表 element 形态 · `PlayerStatistics` 与首批两项 · 宽松同步口径五条 · `PushWarning` 对称落点归内容加载侧），见 `../answer-logs/log-ability-deprivation-and-player-statistics.md`。

- **`RarityTier` 的分布与权重表（08-10c 新增）。** 五档已定名并挂上 `PowerData` / `ItemData` / `CardData`；**结构面已答定**——授予池权重表已给出结构与初值，置换候选池不需要权重表（同档等概率），分表维度按**用途**（授予 / 战后奖励）而非渠道、亦非 `(Kind, Scope)`。仍待定：**战后奖励池**各档权重（按优势档 `Tier` 三档各一张表）、内容侧「每档应有多少条目」的编排口径、**三格取池余量**（`GrantPoolMargin` / `ResearchPoolMargin` / `ExchangePoolMargin`）与 `K` 的取值（结构已定，可先填 0 而不阻塞落地）。→ `systems/balance.md`、`systems/services/combat-service.md`。

## 结构与配置的残留

- **`EncounterTighten` 三格牌流量的六个界常量取值（08-22 新增）。** `MaxInitialDrawTighten` / `MaxDrawPerTurnTighten` / `MaxHandLimitTighten` 与 `MinInitialDraw` / `MinDrawPerTurn` / `MinHandLimit`。**结构已定**——每格必有一个内容侧上界与一条物化期下界钳制，且两条硬性约束先于取值成立（`MinDrawPerTurn >= 1`、`MinHandLimit >= MinInitialDraw`），否则剧本能把每回合抽牌压到 0；只欠数字，被基准值 4 / 2 / 7 的 ch1 校准阻塞。**只约束标定，不约束结构。** → `systems/balance.md`、`systems/services/plot-manager.md`。
- **隐藏属性与战斗资源的共存面（本次归集 · 此前未进清单）。** 隐藏属性（道心 / 煞气 / 寿元）**如何被战斗推拉已定**（三档默认口径 + 胜负同施），**经调制通道拧遭遇参数**也已是既定路径；仍未定的是它们与 **mana / 道念 / lifeTotal 在战斗内是否还有直接耦合**——即除「调制遭遇参数」这条间接通道外，隐藏属性是否会在一场战斗内被读取或作用于结算本身。**它是一道边界题而非数值题**：答「无直接耦合」即关死一整类设计空间，答「有」则要给出耦合面。→ `systems/adventure-event/combat/_index.md`、`systems/services/plot-manager.md`、`systems/services/life-cycle-service.md`。
- **`EnemyManaLimit` 初值 5 的校准（08-22 新增）。** 玩家侧 `manaLimit` 随大境界 +1，第三章差距达 4~7 点（玩家约 9~12 / 敌人 5），敌人的行动空间是否仍够用需实测；**参战方对称在 mana 这一项已被明写打破**，该「已知例外」的措辞同待复核。校准顺位已定：先逐条 `EncounterSpec.EnemyManaLimit` 覆写，改全局常量是第二顺位。→ `systems/balance.md`、`systems/services/combat-service.md`、`systems/character-profile/mana.md`。

## 内容与数值的残留（多数已归 ch1 数值标杆专场）

- **卡牌产 / 削道念的量纲基准（承重 · 已归属专场）。** 一张牌该产多少、10 个回合内一方的总产出相对起始 `baseMomentum` 的倍数、是否存在道念相关的状态与倍率——**它决定越级追分是否可能**。**它同时是本次多条初值的前置依赖**：道具折价系数、战斗内法则的 10% / 25% 闸门、乘法层对方差的放大，在法术基准定出之前都无法被校验。→ `systems/balance.md`、`systems/character-profile/deck/`。
- **`CardData` 的完整字段清单与起始卡组内容。** 类型五分、异能三分、次类型、`Pool`、`Subtypes`、**目标声明与效果引用两格**均已定；其余字段（费用、触发器）与 **starter deck 的具体内容**未设计——**起始卡组正是 ch1 数值标杆专场的切入点**。→ `systems/character-profile/deck/`。
- **关键字与次类型的首批清单（08-16c 新增）。** 两套机制均已完整定案、两套清单均为空；填什么条目要从「哪些组合真的重复了 ≥3 次」倒推，切入点同为 starter deck 的设计过程。→ `systems/character-profile/deck/common-properties.md`、`systems/balance.md`。
- **敌人 AI 的决策形态（08-15d 收窄 · 约束已解除）。** 「回合级一次性规划」这条硬约束**已随意图移除而解除**，AI 可在自己回合内逐张决策。具体算法、决策粒度（一次性 vs 逐张）、多回合行为倾向、难度旋钮的落点均未定义。**连带一项（本次归集）：`EnemyData` 上「行为脚本的表达形态」**——AI 决策是逐敌人由数据描述（脚本 / 权重表 / 规则串），还是全局一套算法只吃参数，这一格与算法本身是同一个未知的两面。→ `systems/enemies/`、`systems/enemies/common-properties.md`。
- **敌人各等级的道念产出缩放。** 起始值已由 `baseMomentum` 给定，产出能力的缩放曲线未定。→ `systems/balance.md`。
- **功法的规模参数（08-12f 新增 · 归 ch1 数值标杆专场）。** 功法（`CultivationTechnique`）已定为卡组的构筑单位、层数提升 = **整组替换**；仍待定：**一门功法含几张牌**、**层数上限**是几、**每层的替换幅度**多大。与「一张牌该产多少道念」「起始卡组给多少张」是同一个未知的几个面。→ `systems/balance.md`、`systems/character-profile/deck/`。
- **敌人是否也以功法构筑卡组（08-12f 新增）。** 功法已定为**角色侧**的构筑单位；`EnemyData` 的样本卡组仍是直接的卡牌列表。若敌人也用功法，图鉴词条②「功法简介」可与系统概念合流、敌人内容的编写颗粒度随之变粗。→ `systems/enemies/`、`systems/player-profile/codex/enemy-codex.md`。
- **卡组规模的实际取值（08-11c 重定）。** 规则层两侧均**不设硬限**，故这是内容 / 构筑层的问题：起始卡组给多少张、敌人样本卡组的常用区间落在哪里。**疲劳规则使规模直接换算为后期失血速率**，与「一张牌该产多少道念」是同一个未知的两面 —— 归 ch1 数值标杆专场。→ `systems/balance.md`、`systems/character-profile/deck/`。
- **卡牌费用曲线是否随境界整体上移（承重 · 归 ch1 数值标杆专场 · 08-22 新增）。** 玩家 `manaLimit` 三章末约 6~7 / 8~10 / 10~13（事件推拉 +1~+2 每章，叠加每次大境界 +1），而**牌流上界三章同形**（一场流入约 14 张、手牌上限 7）⇒ ch2 / ch3 出现「有 mana 没牌打」的溢出，已知并接受。**费用曲线是否随境界上移是 mana 境界跃升这条结论唯一的翻盘前提**，此前不在任何清单上。同批待定 `RealmBreakthroughManaBonus` 初值 1 的校准。→ `systems/balance.md`、`systems/character-profile/mana.md`、`systems/character-profile/deck/common-properties.md`。
- **储物袋 9 格对道具经济的回压（08-11c 新增 · 承重）。** 满袋再获得一件如何处理（拒收 / 强制择一丢弃 / 奖励侧过滤）、道具获取频率与商店库存深度是否同步下调、置换对价是否需要重估 —— 这些此前都建立在 99 格近乎无限的前提上。→ `systems/character-profile/item/_index.md`、`systems/adventure-event/exchange/`。

## 信息面的残留（意图移除后 · 08-16b 采集，此前未进清单）

> 意图机制整条移除后，事前知识只剩**敌人图鉴**一条主通道（战斗内的动态情报归 ticker，见下方「呈现的残留」）。图鉴侧的慷慨度已定（关键卡 3 张，含退让阶梯），剩下这条决定要不要再开第二条通道。

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
