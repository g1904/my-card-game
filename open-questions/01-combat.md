# ① 战斗机制（焦点之首 · 08-06d 后的残留）

> 本分片属 `../open-questions.md` 的当前焦点区。焦点判据见索引文件。

> 本片区历次答结问题的逐条移出记录见 `../answer-logs/`（归档权威在那里，本处不复述）。

> **⚠ 治理提示（08-15d 更新）：** **敌人意图机制已整条移除**（三档揭示 · `IntentCategory` · 快照语义 · 探查通道全部作废），敌人回合的可读性改由逐步执行呈现 + 敌人图鉴 + 战场承担。凡在别处读到「意图三档 / 越阶黑箱 / 仅类别 / 探查」的表述，一律以 `handoffs/2026-08-15d-intent-removal-lifespan-cost-visibility-and-design-audit.md` 为准；`±2` 赋级带**保留**（其消费点是 `baseMomentum` 起跑线）。

## 能力剥夺与统计计数的残留（08-10c 后）

> 「本轮回禁用」与置换型剥夺片区的**四条并列待答已全部答结**（承载字段 `disabledAbility` · 三档时长与生效判据 · 置换候选池与对价 · `ProfileChangeSpec` 三列表 element 形态 · `PlayerStatistics` 与首批两项 · 宽松同步口径五条 · `PushWarning` 对称落点归内容加载侧），见 `../answer-logs/log-ability-deprivation-and-player-statistics.md`。

- **用道具产生的栈条目落在 `StackEntryKind` 的哪个成员上（08-28 新增）。** 战斗内使用道具已定为一等玩家动作、入栈即 `targetState = Resolved`、栈条目的 `abilityId` 恒空；但 `StackEntryKind` 现有四值 `{ PlayedCard, TriggeredAbility, ActivatedAbility, Fatigue }` 没有一个显然对应「用道具」——道具不是牌、不是异能、更不是疲劳。待裁定：复用 `ActivatedAbility`（代价：`abilityId` 恒空成为该成员的一种合法形态，读取侧要分支）· 新增第五个成员 `UsedItem`（代价：枚举增员，凡按 `kind` 分支处 全部要补一路）· 或另立形态。→ `systems/services/combat-service.md`。
- **`RarityTier` 的分布与权重表（08-10c 新增）。** 五档已定名并挂上 `PowerData` / `ItemData` / `CardData` / `CultivationTechniqueData`（功法整体标稀有度）；**结构面已答定**——授予池权重表已给出结构与初值，置换候选池不需要权重表（同档等概率），分表维度按**用途**（授予 / 战后奖励）而非渠道、亦非 `(Kind, Scope)`。仍待定：**战后奖励池**各档权重（按优势档 `Tier` 三档各一张表；该池现为 `CardData` / `ItemData` / `CultivationTechniqueData` 三类混合，权重表的族维度须相应覆盖功法；**该表同时覆盖事件产出侧 `OutcomeRule.DeckOperation` 的 `AddLooseCard` 池抽，事件侧固定取一档、不按优势档选表**）、内容侧「每档应有多少条目」的编排口径、**三格取池余量**（`GrantPoolMargin` / `ResearchPoolMargin` / `ExchangePoolMargin`）与 `K` 的取值（结构已定，可先填 0 而不阻塞落地）。→ `systems/balance.md`、`systems/services/combat-service.md`。

## 结构与配置的残留

- **`EncounterTighten` 三格牌流量的六个界常量取值（08-22 新增）。** `MaxInitialDrawTighten` / `MaxDrawPerTurnTighten` / `MaxHandLimitTighten` 与 `MinInitialDraw` / `MinDrawPerTurn` / `MinHandLimit`。**结构已定**——每格必有一个内容侧上界与一条物化期下界钳制，且两条硬性约束先于取值成立（`MinDrawPerTurn >= 1`、`MinHandLimit >= MinInitialDraw`），否则剧本能把每回合抽牌压到 0；只欠数字，被基准值 4 / 2 / 7 的 ch1 校准阻塞。**只约束标定，不约束结构。** → `systems/balance.md`、`systems/services/plot-manager.md`。
- **`EnemyManaLimit` 初值 5 的校准（08-22 新增）。** 玩家侧 `manaLimit` 随大境界 +1，第三章差距达 4~7 点（玩家约 9~12 / 敌人 5），敌人的行动空间是否仍够用需实测；**参战方对称在 mana 这一项已被明写打破**，该「已知例外」的措辞同待复核。校准顺位已定：先逐条 `EncounterSpec.EnemyManaLimit` 覆写，改全局常量是第二顺位。→ `systems/balance.md`、`systems/services/combat-service.md`、`systems/character-profile/mana.md`。

## 内容与数值的残留（多数留待内容扩充后的统计校准）

- **卡牌产 / 削道念的量纲基准（承重 · 已归属统计校准）。** 一张牌该产多少、10 个回合内一方的总产出相对起始 `baseMomentum` 的倍数、是否存在道念相关的状态与倍率——**它决定越级追分是否可能**。**它同时是本次多条初值的前置依赖**：道具折价系数、战斗内法则的 10% / 25% 闸门、乘法层对方差的放大，在法术基准定出之前都无法被校验。→ `systems/balance.md`、`systems/character-profile/deck/`。
- **起始卡组的具体内容。** `CardData` 的字段清单已收口（类型五分、异能三分、次类型、`Pool`、`Subtypes`、目标声明与效果引用、`ManaCost`、`OnPlay`）；**starter deck 装哪些牌**未设计——**它正是内容扩充后统计校准的切入点**。→ `systems/character-profile/deck/`。
- **关键字与次类型的首批清单（08-16c 新增）。** 两套机制均已完整定案、两套清单均为空；填什么条目要从「哪些组合真的重复了 ≥3 次」倒推，切入点同为 starter deck 的设计过程。→ `systems/character-profile/deck/common-properties.md`、`systems/balance.md`。
- **疲劳扣减是否进 `EncounterSpec` 覆写组（08-27 重开）。** `MoveCardEffect` 的 `From` 可取抽牌堆 ⇒「削减对手抽牌堆」在结构上已可写，`systems/balance.md` 那条的重开判据 ① 因此触发。需重估其三条理由是否仍成立；本次不答定、未改任何数值。→ `systems/balance.md`、`systems/services/combat-service.md`。
- **功法的规模参数（08-12f 新增 · 留待内容扩充后的统计校准）。** 功法（`CultivationTechnique`）已定为卡组的构筑单位、层数提升 = **整组替换**；仍待定：**一门功法含几张牌**、**层数上限 `MaxTier`** 是几、**每层的替换幅度**多大，以及**敌人功法层数的「篇章基准档」取值**（护栏形态已定：逐条目偏离基准档 ≤ ±1 档）。与「一张牌该产多少道念」「起始卡组给多少张」是同一个未知的几个面。→ `systems/balance.md`、`systems/character-profile/deck/`。
- **卡组规模的实际取值（08-11c 重定）。** 规则层两侧均**不设硬限**，故这是内容 / 构筑层的问题：起始卡组给多少张、敌人样本卡组的常用区间落在哪里。**疲劳规则使规模直接换算为后期失血速率**，与「一张牌该产多少道念」是同一个未知的两面 —— 留待内容扩充后的统计校准。→ `systems/balance.md`、`systems/character-profile/deck/`。
- **卡牌费用曲线是否随境界整体上移（承重 · 留待内容扩充后的统计校准 · 08-22 新增）。** 玩家 `manaLimit` 三章末约 6~7 / 8~10 / 10~13（事件推拉 +1~+2 每章，叠加每次大境界 +1），而**牌流上界三章同形**（一场流入约 14 张、手牌上限 7）⇒ ch2 / ch3 出现「有 mana 没牌打」的溢出，已知并接受。**费用曲线是否随境界上移是 mana 境界跃升这条结论唯一的翻盘前提**，此前不在任何清单上。同批待定 `RealmBreakthroughManaBonus` 初值 1 的校准。→ `systems/balance.md`、`systems/character-profile/mana.md`、`systems/character-profile/deck/common-properties.md`。
- **回寿法宝的总量护栏在内容编排面的口径未定（08-26 改写 · 承重）。** 储物袋不设容量上限后，回寿法宝能囤多少完全交给内容编排面承接——**出现频率 / 商店库存深度 / 定价**三者的口径都还空着。它是寿元这条压力线的**唯一剩余数量闸**：另两道加载期校验（`Scope == Player` 且产出 `LifeSpan` → 拒；`LifeSpan` 产出 + `UsableScene` 含 `InCombat` → 拒）管的是条目合法性，不约束持有量。连带需一并评估的还有道具整体的获取频率、商店库存深度与置换对价。→ `systems/character-profile/item/_index.md`、`systems/adventure-event/exchange/`、`systems/balance.md`。

## 呈现的残留

- **战报条目的文案体系（08-15d 新增 · 承重 · 08-25f 收窄）。** 战报（`combatLog`）是**唯一**的动态情报通道，它写什么、写多细直接决定战斗是否可读。**已定**：展开态为按结算批次缩进、按回合分组的因果树；排布约束（单行、永不换行、固定预留 ≈ 屏高 6%）；条目粒度 = 结算事件。**仍待定**：收起态单行的信息量、**截断量与目标落空两条硬要求如何在单行内表达**、**与飘字的分工边界**。→ `ux/combat-ux.md`。
- **道念对比的视觉形态、回合进度与道念差的组合呈现、lifeTotal 是否常驻战斗屏。** 主视觉地位已定，形态未定；形态须容纳「双方头像与数值分居对比条两端」这一已定落位。→ `ux/combat-ux.md`。
- **栈与战场的同屏呈现（08-25f 收窄）。** 「连锁可读性」由战报展开态的因果树承担，不在本条残留内；仍待定竖屏上如何同时表达「哪些在等待结算、以什么顺序」与「哪些已经在生效」、两区如何视觉区分、结算动画如何不拖慢节奏。→ `ux/combat-ux.md`。
- **战后奖励面板的形态（08-23g 收窄）。** 交互已定：候选固定 3 项、预先算定、**逐项列出并逐项领取 / 跳过**（不是择一）、已处置不可反悔。**仍待定**：强制项与可选项如何同屏区分、逐项列表的竖屏排布、**已领取 / 已跳过两态的视觉处置**、与事件收口的视觉衔接。→ `ux/combat-ux.md`。
- **逐项领取后的奖励厚度重估（08-23g 新增）。** 择一改为三项各自可领，使单场可选奖励的期望价值上移；`Tier` 三档的质量落差与 `BaseReward` 的相对分量需随之重估。**留待内容扩充后的统计校准**，与「三档奖励厚薄的具体取值」同批处理。→ `systems/balance.md`、`systems/services/combat-service.md`。
- **竖屏分区的整体排布（本作压力最大的一处 · 08-15d 加压说明）。** 需容下战场 / 栈 / 手牌 / 双方道念位 / 回合计数 / 战报，再加法则条、随身角标、埋伏标记；**08-25f 加压：新增玩家侧头像位**（战报因收起 / 展开共用同一格而净增 0 个区）；**己方战场区左右两侧同时挂法则条与随身角标会挤压战场可用宽度，须在实际排版时验证**。**体检登记：根子是把 MTG 的完整分区模型搬进手机竖屏**——尤其**栈在零交互下玩家做不了任何事、只能看**，它是否必须常驻（而非结算时的临时演出层）值得重估。意图区移除已释放约屏高 8%，但未触及根因。**已排期：单开一个专门 session 答疑（08-16 确认）**，不在逐次 handoff 中零敲碎打。**08-26 新增三项待容纳形态**：只读层（神通 / 法则条）的形状（角标 vs 常驻一排小图标）· 启动式 `Power` 的静态启动可供性标记 · 随身抽屉内 `AbilityScope` 两级标识的视觉形态。→ `ux/combat-ux.md`。
- **道具区 / 神通法则条 / 埋伏标记 / 卡牌类型标识的四项具体形态（08-16b 采集 · 此前未进清单）。** 落位与视觉语言已定方向（道具 = 角标 + 抽屉、`Power` = 低权重小图标条且长按查看详情、埋伏 = 只给计数、卡牌类型 = 卡框色 + 类型角标，**且仅适用于会以卡面出现的类型**）；**具体形态未定**——其中卡框色与类型角标在 full art 下是卡面唯一的非 `manaCost` 呈现元素，其权重与可辨性因此升格。它是上一条竖屏分区压力的四个具体来源，宜在同一场专场内一并定。→ `ux/combat-ux.md`。 **同专场须一并答掉：阵法（`Enchantment`）上启动式异能的 UI 宿主。** 启动式异能不是 `Power` 专属，现有形态只定了 `Power` 那一半（长按弹层内的启动键）；服务契约按战场条目 id 寻址、与宿主无关，但没有宿主就没有玩家可发起的路径。
- **疲劳的呈现（08-11c 新增 · 08-25f 收窄）。** 战报侧的归因区分已由条目粒度答定（疲劳扣减单占一条）；仍待定抽牌堆剩余张数是否常驻、见底预警、以及**飘字侧**疲劳扣减与「被对手削减」如何视觉区分（两者都是自己的道念下跌，归因完全不同）。→ `ux/combat-ux.md`。
- **战斗屏幕的其余形态整体未设计**——手牌布局、敌我分区、敌方出牌的呈现方式，待一次专门的战斗 UX 专场。→ `ux/combat-ux.md`。
- **卡牌详情页的内容清单与排布（08-25f 新增）。** full art 把规则文字、卡名、关键字名与完整定义、`Power` 的明示内容全部后置到点按升起的详情页；仍待定：一屏装哪些项、如何排布、竖屏 bottom sheet 内是否需要分区或滚动、关键字定义在详情页内是否仍需长按二级展开。→ `ux/combat-ux.md`。
