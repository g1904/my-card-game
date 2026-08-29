# adventure-event / common-properties（AdventureEvent 顶层共有属性）

> 所有 AdventureEvent 子类型共有的属性 / 字段与通用流程。各子类型专有属性见其各自的 `common-properties.md`。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

### 共有属性 / 字段

- **AdventureEvent 之间不存在前后连边。** 单个 AdventureEvent 只是一份自足的内容条目，**不持有指向后续事件的引用**——事件之间的走向不由内容作者预先连线，而由 **future-event-service 在运行时依角色状态产出的一批 `List<EventOption> eventOptions`** 决定：受角色当前 location（地域）框定，并被隐藏剧本层 AdventurePlot 持续调制（见 `systems/services/future-event-service.md`、`systems/services/plot-manager.md`）。
- **`pastEvent`（历程轨迹 · CharacterProfile 侧）。** 与向前的走向相对，向后的**已经历轨迹**仍需持久化：`pastEvent` 是一条**扁平的时序列表**（不是图的反向边），记录角色走过哪些事件。它归属 CharacterProfile 的轮回状态，不挂在 AdventureEvent 上。**只有一种痕迹：进入并结算**——跳过通道已整体移除（见下方「一批只有一次操作」）。条目类型 `PastEventEntry` 与字段表见下方「`pastEvent` 的痕迹 schema」。
  - **一个权威、两种寿命（承重边界）。** **事件内的过程态是纯呈现层、不落存档**：战斗内逐条结算的可读记录归**战报 `combatLog`**（形态见 `ux/combat-ux.md`），战斗结束或退出重进即从空开始。**事件之间的账目归 `PastEventEntry`、落存档**——「一个事件里到底发生了什么」的事实来源只有它一份。**推论：不为任何事件类型另立一份「事件日志」类型。** 三条理由各自独立：① 那会让同一批事实有**两份权威**，而 `PastEventEntry` 已被剧本、履历、诊断三方消费，并且是 future-event-service 每批重算的一等输入，两份表各自漂移而本库无机制发现；② **非战斗事件没有可记的时间轴**——其余四类都是单决策点事件（择一 → 结算 → 收口一次 `TryApply`），而战报成立的两条前提（LIFO 栈使因果链长于 1、敌人不作事前预告故事中呈现是唯一情报通道）一条都不外延；③ **非战斗事件里唯一「值得记」的东西恰好必须隐藏**——玩家自己选了什么他本就知道，他不知道的是隐藏属性被推了多少、剧本被怎么调制，而 `systems/services/plot-manager.md` 明写「给方向不给数字、调制才是隐藏属性的主要显影通道，中间档的跨越对玩家完全无提示」。诚实的事件日志会掀开这层，不诚实的只剩零信息条目。
- **`eventType`（类型标签 · 子类型枚举 · **五值**）。** 每个 AdventureEvent 带一个 `eventType` 字段，归属五类之一（**Combat / Exchange / Research / Explore / Travel**）。Explore 为元类型，遮罩一个固定的 Combat / Travel / Exchange 事件——被遮罩事件的真实 `eventType` 在揭示前对玩家不可见。`eventType == Combat` 的条目另带 **`combatTier { Practice, Standard, Finale }`**（遭遇档位，落在 `EncounterSpec` 上）。术语见 `terminology.md`。
- **`selectCost`（选择成本 · 共有字段）= 一个定制的复合成本类型。** 选中该 AdventureEvent 以推进轮回所需付出的代价。`selectCost` **不是单一数值，而是一个定制类**——它由**若干成本 element 组成**，**`lifeSpanCost` 是其中一个 element**。因此一个事件的选择代价可以同时涉及多种资源（寿元 + 其他），由该成本类型统一承载，而非在 AdventureEvent 上平铺一堆并列的成本字段。它把「从 eventOptions 中推进」建模为一次**付费的取舍**，而非单纯的菜单点选——契合月圆之夜式事件菜单的策划取向。
  - **`lifeSpanCost`（成本 element）：** 完成该事件对角色**寿元 / lifeSpan** 的扣减，由内容作者以**正数量值**标注；见下方独立条目。
  - **element 清单当前只有 `lifeSpanCost` 一项。** 除寿元外**没有其他资源进成本侧**——`selectCost` 现阶段实质上是寿元扣减的一个包装。
    - **但复合形态保留，不塌缩为单一 `int`。** 塌缩会连带改写三处（`PastEventEntry.SelectCost` 的快照形状、物化取负链路、future-event-service 的物化组装段），而**保留复合形态的成本是零**——日后真需要第二个 element 时零成本加上。这与「成本与产出共用 `ProfileChangeSpec` 一个类型」的既定形状也一致。
    - **推论：`selectCost` 的展示只需处理单一量值**——不需要多资源的组合心算。**但它是否被展示按寿元档位分档，见下条。**
  - **`selectCost` 的展示挂寿元档位：只在 Band 2 给精确值（承重）。**

    | 寿元 Band | 余量 | 既有的寿元呈现 | **`selectCost` 展示** |
    |---|---|---|---|
    | **Band 0** | > 30% | 无提示 | **完全不显示**（eventOption 上没有任何寿元成本信息） |
    | **Band 1** | 10% – 30% | 跨档时一条定性叙事 | **完全不显示** |
    | **Band 2** | < 10% | 标红的数值倒数（精确余量，常驻静态标注） | **如实展示精确扣减量** |

    - **不是新机制，是既有档位表的第五个消费方。** 寿元 / 道心 / 煞气档位表已被 eventOptions 调制 / 剧情线触发 / 跨档叙事文案 / 寿元红字标注四处消费；本条是第五处，判据同为「寿元 Band == 2」，**与红字倒数同一个开关、同时开启**。不新增字段、不新增流程、不 bump schema。档位表权威见 `systems/services/plot-manager.md`。
    - **为什么挂得上去：** 「隐藏属性只给方向不给数字」这条纪律在寿元上本就有明写的例外——Band 2 的「标红精确数值倒数」使寿元成为三个隐藏属性里**唯一有精确显示通道**的一个。故问题不是「显不显示」，而是「从哪一档开始显示」，而这张表现成可挂。
    - **两段式告警的语义因此更完整**：Band 1 给方向（时日无多），Band 2 给账本（**既知道还剩多少，也知道每一步花多少**）。数字只在最后阶段给，那时它已不是优化工具而是倒计时。
    - **「明知是死路仍然走」在最关键的区间仍然成立**：真正的死路判断只发生在寿元濒尽时，而那正是 Band 2、正是精确可见的那一档。
    - **规则层完全不动**：`selectCost` 无条件施加、支付后判定状态、判负进失败流程、**不设不可选 / 置灰态**（三档一律），本条只改呈现层。
    - **已知代价（明写接受）：** 「省着花有跨篇章回报」这条策略性回报在 Band 0 / Band 1 **不可被精细执行**——玩家只能凭定性感知粗略调整，无法做电子表格式的寿元预算优化。**这正是取向本身**，与既定的「eventOption 卡片不标注经验产出数字、给方向不给数字、不可电子表格化优化」是同一条纪律的第二个实例。
    - **退让位（属实测调整，不是重新裁决）：** 若新手对「时间在流逝」缺乏体感，给 Band 1 补上定性档位标签（「耗时甚久 / 寻常 / 片刻」），仍不给数字——那是三档表上现成的中间态。
    - **遮罩下展示的是 Explore 壳自己的 `selectCost`，不存在「两份成本二选一」。** 支付先于揭示（`TryApply(SelectCost)` 在 `eventStart` 阶段的 Explore 揭示之前），被施加的必然是 Explore 模板物化出的那一份，真身模板的成本字段从头到尾不在链路上。泄漏面因而不在展示侧，而在**定价侧**——`lifeSpanCost` 的 Explore 行不得由真身推导、Explore 条目不得标条目级覆盖值，见 `explore/_index.md`。
  - **支付 `selectCost` 是无条件的可推进行为（承重）。** 选中一个事件时，`selectCost` **照常施加，不因「付不起」被拒绝**；**支付之后做状态判定，判负则进入既有的失败流程**（寿元归 0 → 「大限将至」→ `defeated`）。
    - **明确不存在的东西：** `AdvanceEventAsync` 里**没有**「`TryApply(SelectCost)` ← 付不起则拒绝，不产生任何写入」这一步，`program-overview.md` 阶段 4 也**没有**「付不起 → 拒绝，回到呈现步」这条回路。不要把它们加回来。
    - **推论 ①（承重）：「付不起唯一可选项 ⇒ 轮回无法推进」这个死锁在规则层不成立**，且**不是靠产出侧保证闭合的**——future-event-service 不欠 `selectCost` 侧任何可负担性保证（与「不给可战胜保证」同一种收口：不给保护，给出口）。
    - **推论 ②：终态由支付后的状态判定给出，而不是由「付不起」这个事实给出。** 支付后未必死——付寿元才可能触发终态，付非终结性资源只是变穷。「哪些资源的耗尽构成终态」逐条写在 `ResourceElements` 表里。
    - **推论 ③：「付不起」在事件选择面整体消失。** UI **不需要不可选 / 置灰态**。**「明知是死路仍然走」是有意义的玩家决策**（与「打不过也得打」同构），而它所需的信息由 **Band 2 的精确展示**兑现——`selectCost` 只在寿元 < 10% 时如实展示，常态档不显示，见上条。
    - **事务性不变、可负担性校验去掉。** `ProfileManager.TryApply` 仍是全有或全无的单点提交；**它不为事件推进做「先校验付得起、否则整体拒绝」**。**负值施加时的钳制与终态判据查 `ResourceElements` 表**——寿元与耐久归 0 构成终态，两种货币归 0 均只是变穷；表的定义见 `systems/architecture.md`「共享核心类型」，逐行取值与理由见 `systems/services/profile-service.md`。**落进 `PastEventEntry.SelectCost` / `AppliedChange` 的快照记未截断的原值**，截断只发生在施加到 Profile 字段那一刻。
  - **代码形态 = `ProfileChangeSpec`（平级列表，逐条按施加语义分列）。** 该复合成本类型即 `ProfileChangeSpec`——`Elements`（资源，`ChangeElement.BaseValue` **带符号**：负 = 消耗，正 = 产出）· `AbilityElements`（能力，按 `Id` 的集合成员操作）· `Stats`（统计计数，纯自增）· `StatusChanges`（Status 规则字段，绝对置值）· `DeckElements`（卡组，带层数的构筑变更与多重集增删）。**`selectCost` 只用得到 `Elements`**：其余各列在成本侧恒为空（见下）——**成本与产出共用一个类型**，因为「全有或全无、单点提交」本就要求二者落在同一事务内。`selectCost` 在**物化时组装**（modifier pipeline 尚未施加，它在 `ProfileManager.TryApply` 那一刻才生效）。
  - **内容侧写正数量值，spec 里仍是负数（两条约定各自成立）。** 带符号约定**不变**；但**内容作者标注的成本一律是正数量值（magnitude）**——「这个事件耗 3 点寿元」写 `3`，不写 `-3`。**取负发生在 future-event-service 物化组装 `selectCost` 的那一刻**（见 `systems/services/future-event-service.md`）。二者并行不悖：作者面对的是「花多少」，`TryApply` 面对的是带符号 element。

    | 层 | 形态 |
    |----|------|
    | `AdventureEventData.tres` / 平衡分档表 | **正数量值** |
    | `EventOption.SelectCost` 内的 `ChangeElement.BaseValue` | **取负**（`-magnitude`） |
    | `ProfileManager.TryApply` | 照常按带符号 element 施加 |
  - **能力 element 恒不出现在 `selectCost`（承重）。** `ProfileChangeSpec.AbilityElements` 在 `EventOption.SelectCost` 内**恒为空**——事件对能力的三种操作（`Grant` / `Remove` / `Disable`，即置换型剥夺与本轮回禁用）**只能出现在 outcome / reward 侧**。四条支撑：① **成本侧只放可如实计价的量**（`selectCost` 的展示纪律是让玩家能自己算出「这一步可能是最后一步」，面向可计量资源；一条法则值多少寿元无法回答）；② **成本侧无条件施加，与置换的「先看后决 · 拒绝无代价」正面冲突**；③ **能力得失是事件的后果，不是入场费**——三级严重度阶梯描述的是事件**造成**了什么；④ **它换来一条可机械检查的不变式**：`SelectCost.AbilityElements` 恒空 ⇒ 物化组装后断言 + 内容模板加载期校验，两处均 `PushError`。
  - **卡组 element 同样恒不出现在 `selectCost`（承重 · 同一条判据的第二个实例）。** `ProfileChangeSpec.DeckElements` 在 `EventOption.SelectCost` 内**恒为空**——功法的升阶 / 弃置 / 学新与散牌移除**只能出现在 outcome 侧**。理由与能力侧同构且更直白：**成本侧只放可如实计价的量**，而「一门功法值多少寿元」无法回答；卡组变更是事件**造成**的构筑后果，不是入场费。**两条不变式各自落一处断言 + 一处加载期校验，一律 `PushError`**——它们是两条独立的检查，不要合并成「非 `Elements` 的列表一律为空」的通则，日后新增的列未必都该被排除在成本侧之外。
  - **outcome 侧的对应形态**（置换与禁用共用同一条链路）：

    | | 形态 |
    |---|---|
    | 候选何时掷定 | **物化时**（随 `EventOption` 一并定稿），走 `Reward` 子流 |
    | 玩家看到什么 | 结算面板展示「失去 A · 得到 B」+ 接受 / 拒绝；禁用型只展示告知，无选择 |
    | 「拒绝」是什么 | 点「拒绝」，什么都不发生（零代价） |
    | 事件内决策点 | **有**，形状与战后奖励面板完全同构 |
    | 落存档 | 候选随 `EventOption.AbilityChangeSlots` 落存档（物化时定稿）；结果进 `PastEventEntry.AppliedChange` |

    **不新增机制**——战后奖励面板已经是「预先算定的候选 + 玩家择一 + 随后并入 `eventEnd` 那一次 `TryApply`」。**候选必须预先算定**，否则退出重进可以重掷候选；掷定落在物化那一刻，与 Research 槽、Exchange 库存**三个决策点面板的掷定时点由此一致**。承载字段 `AbilityChangeSlot` 的形状见 `systems/services/future-event-service.md`。
    - **它不由 `OutcomeSpec` 承载。** `ProfileChangeSpec` 的 element 只装已定稿的最终账，而决策点需要的是一份**施加之前**的候选，两者不是同一层东西；`OutcomeSpec.AbilityElements` 相应只承载物化时定稿的**授予**（`Op == Grant`）。
    - **推论：`PastEventEntry.SelectCost` 的快照形状不受影响**（它只装资源 element），`AppliedChange` 则新增能力 element 与统计 element。规则权威见 `systems/player-profile/player-power/_index.md`，element 形态见 `systems/services/profile-service.md`。
- **批次规模 = 常态 3 项，取值区间 1–5。** 一批 eventOptions **通常摆 3 个**选项，允许的范围是 **1 到 5**。**推论 ①：批次不是固定宽度**，产出侧要按批给出数量而非套一个常数。**推论 ②：1 项的批次是合法的**，此时「择一进入」退化为「只能进这一个」——它与 `eventPriority = 1` 收窄到单项、以及 Travel 的 20% 随机档天然同形，**不需要额外规则来允许它**。
  - **区间两端由 `BatchSizeWeights` 驱动**——一张**按篇章分格的五格权重表**（N = 1…5），常规批每次走 map 子流掷定，众数 3、两端稀薄使 1 与 5 成为有记忆点的少见形状。它住平衡资源、**不接受任何按剧情线 / location 的覆盖参数**（与 `TravelFullFanoutChance` 同款收口：批次规模改的是玩家选择空间的宽窄，落在约束面，而 future-event-service 独占约束面的置位权）。取值与校验见 `systems/balance.md`。
  - **三种结构性场景不走这张表**：配额闸门批（规模 = 邻接数或 1）· `Priority = 1` 收窄批（= 该档条目数，通常 1）· 闸 ②③ 移出条目后（少一项）。
  - **掷出的 N 是目标槽位数，不是产出数量。** 实际输出允许少于 N（Travel 的 20% 档、闸 ③ 降级），下界由「收缩到 0 时补一个 Travel」的保底规则兜住，故 `1 <= Count <= 5` 恒成立。管线与保底规则见 `systems/services/future-event-service.md`。
- **`SelectionWeight`（条目基础权重 · 共有字段 · `SelectionWeightGrade` 枚举，默认 `Common`）。** 同类型内各条目被抽中的相对权重，档 → 权重的映射住平衡资源（见 `systems/balance.md`）。
  - **它补上的是 `Rarity` 被排除时所承诺的那个「权重」。** `AdventureEventData` 不进稀有度维度，理由正是「它的出现由**权重**与优先级控制」——而在此之前那个权重不存在于任何字段上，`PlotModulation.EventWeights` 的乘性系数也就没有基数可乘。两者不同名不同表：`Rarity` 承载跨内容族共用一张 `GrantPoolWeights` 的稀有度语义，本档只承载出现频率。
  - **取枚举档而非裸 `int`**，是「内容侧不落裸数字、走枚举档 + 平衡表映射」的第三个实例（前两个是 `ExperienceGrade` / `HiddenStatGrade`）：改一张表即可全局调节奏，不必重扫数百个 `.tres`，也避免同类条目在不同作者手里权重漂移。**默认 `Common` ⇒ 内容作者的默认动作是不填。**
  - **加载期处置：** 枚举天然封闭，无需取值域校验；平衡表映射值 `<= 0` → `PushError`（同 `GrantPoolWeights`「任一档权重为 0 → 池非空却抽不出来」）。
- **`ChapterScope`（篇章框定 · 共有字段 · `int[]`，空 = 不限）。** 该条目可在哪几个篇章进入候选池，与 `PlotArcData.ChapterScope` / `EnemyData.ChapterScope` **同名同形同义**；取池管线在 `AllEnabled()` 之后按它过滤（见 `systems/services/future-event-service.md` 十步管线第 ① 步）。
  - **加载期处置：** 取值域 `1..3`，越界 → `PushError` + 条目 `Id` + 越界值；重复值 → `PushWarning` + 去重（**只告警，共享只读模板不写回**）；空数组合法。
  - **另加一条启动期断言：每个 `(chapter, EventType)` 组合下 `ChapterScope` 命中的条目数 ≥ 1，否则 `PushError` + 该组合。** 与敌人侧的「每 `(eventType, chapter)` 通用池非空」逐字同构。**理由：**`ChapterScope` 一旦落地，「第二章没有任何 Explore 条目」就成了一种可静默编排出来的坏数据；不加断言它只会在运行期以「内容池为空 → `PushError` + 抛」的形式炸在玩家的轮回中途，而坏数据必须在启动期大声失败。粒度取 `(chapter, EventType)` 而非 `(chapter)`——后者宽松到几乎必然通过，等于没有断言。
  - **`eventType == Travel` 的条目豁免本字段：`ChapterScope` 必须为空，非空 → 加载期 `PushError` + 条目 `Id`（承重）。** **Travel 是结构性通道而非内容**——它不计入 `eventCountLimit`、它的 outcome 不得含 `LifeSpan` 产出，本条是同一族禁令的第三条。**不豁免的后果是直接的**：某个篇章若没有一条 `ChapterScope` 命中它的 Travel 条目，配额闸门批就产不出任何选项，而「邻接集合不经 `AllEnabled()` ⇒ Travel 兜底恒可产出 ⇒ 轮回死锁在规则层不成立」这条承重结论会当场失效。既然 Travel 的目的地取自地域图（三章共用同一张、恒启用），给它一个篇章维度也没有任何可表达的语义。
- **整批重算的依据 = 角色的整体历程，不是上一批。** 一次事件完成后新的一批**不是在上一批基础上增删**，而是**依角色的整体状态与历程重新产出**——**重度依赖 `pastEvent`**（以及 location 框定与 PlotManager 调制）。
  - **它加强而非改动既有形状**：「AdventureEvent 之间不存在前后连边」讲的是内容侧不预先连线，这条讲的是**产出侧也不承接上一批的形状**——两端都不留连边，批与批之间唯一的信息通道就是角色状态本身。
  - **推论：`pastEvent` 从「历史记录」升为「产出侧的一等输入」。** 它此前的消费方是剧本、履历与诊断；现在 future-event-service 每批都读它。**这不改 `pastEvent` 的 schema**（`Unchosen` 轻摘要正好让产出侧也读得出「玩家回避了什么」），但它把「痕迹必须完整可靠」的重要性又抬了一级。
- **一批只有一次操作：择一进入。没有跳过通道（承重）。** 面对一批 eventOptions，玩家**唯一能做的事就是选中其中一个进入**——**不设跳过（skip）通道**，也**不设 `skipCost` 与 `ifMandatory` 两个字段**。
  - **理由 = 跳过本就是冗余机制。** **每完成一次选择，eventOptions 无论如何都会整批重算**；因此**选中某一个事件本身就等价于跳过了同批其余全部事件**。跳过通道只是把「不做这件事」额外做成了一个要付费、要留痕、要补位的独立机制，而玩家早已通过「选别的」得到同样的结果。
  - **它承载的设计意图不但没丢，反而更强：** 「每批必有不可跳过项、打不过也得打」**升级为结构性事实**——**本批的每一项都是必做项**，回避通道在规则层根本不存在，**不需要字段来表达它**。
  - **单项补位（`TryRefill`）随之删除。** 补位只为「被跳过的那个位置空了」而存在；没有跳过就没有空位。**批次刷新只剩一种形态：一次选择 → 整批重算。**
  - **推论（一次删掉五处结构）：** `EventOption` 九字段 → **七字段**（删 `IsMandatory` / `SkipCost`）· `EventOptionBatch` 删 `AnySkippable` 与「每批至少一个 `IsMandatory`」的恒真不变式 · `AdvanceMode { Select, Skip }` **整个枚举删除**（`AdvanceEventAsync` 少一个参数、`EventResolved` 负载少一个字段）· future-event-service 的 API 面五方法 → **四方法** · `CapabilityFlag` 删 `ShowSkipCost`、modifier key 清单删 `skipCost`。
  - **推论：`pastEvent` 只有一种痕迹**（进入并结算）——不存在「区分两种痕迹」的 schema 难题。**未被选中的选项随批次归档轻摘要**，见下方「`pastEvent` 的痕迹 schema」。
  - **推论：产出侧不欠跳过相关的任何保证**（无需「不生成付不起 `skipCost` 的事件」「不生成整批全跳的批次」一类规则）。
  - **推论：「回避了什么反向影响剧本」这条内容侧方向仍然成立，只是换了形态。** 它不是一个**独立的玩家操作**，而是选择的**补集**——由 `PastEventEntry.Unchosen`（同批未选项轻摘要）承载，剧本照常读得出「同批还摆着什么而没选」。见下方「`pastEvent` 的痕迹 schema」。
- **`eventPriority`（事件优先级 · 共有字段）。** **唯一**约束玩家选择权的字段，约束面是**同批 eventOptions 内的可选范围**：
  - **取值域只有两档：`0`**（常态——玩家可从本批中任选）与 **`1`**（本批一旦出现，**有效可选集收窄为该档**，`0` 档本轮被封锁）。
  - **有效可选集 = 本批中最高优先级档的全部事件**，同档内玩家自由择一。
  - **置位方唯一 = future-event-service，在物化时置位；PlotManager 不得改变它。** **推论（边界澄清 · 承重）：PlotManager 只调内容不调约束**——它能影响哪些事件进池、以什么权重出现，但**不能通过抬优先级强制玩家做某件事**；剧本要表达强制性，只能靠**把候选池收窄**（整批只出这一类）。这是更诚实的表达：玩家看到的仍是一批可选项，而非一个被系统钉死的选项。
  - **载体类型是 `int`，不塌缩为 `bool`；取值域由断言兑现。** 塌缩要连改三处——`EventOption.Priority` · `PastEventEntry.Priority`（**落存档字段**）· `EventOptionBatch.EffectivePriority` 与「有效可选集 = 本批最高优先级档」这条语义（`bool` 下退化为两次布尔比较）；日后需要第三档时那是一次真实的存档迁移。**保留 `int` 的成本是零，故按「哪一侧日后更贵」选。** 「让类型说实话」这个诉求由**物化组装后断言 `Priority ∈ { 0, 1 }`**（`PushError` + `EventId`）兑现，与「`SelectCost.AbilityElements` 恒空」同一档、同一处。**它是对自己代码的防呆**——置位方本就唯一（future-event-service），内容作者在 `.tres` 上根本没有这个字段可填。
  - **推论：两档 ⇒ 不存在「优先级 2 压过优先级 1」的层叠语义。** Travel 闸门用的「最高优先级」就是 `1`；**同批若出现多个 `1` 档，同档内玩家自由择一**——这条兜底零成本且在日后新增抬升条件时自动生效，故保留它而不删。
  - **抬升判据由 future-event-service 独占给出：「抬升当且仅当不抬升会使一条结构性规则失效」**，另附三条与门子判据（唯一出口 / 产出侧可确定判定 / 表达结构而非难度叙事）。当前闭合的三条抬升条件、六条被否决的候选、以及「同批多个 `1` 档为何不新增收窄规则」全部归 `systems/services/future-event-service.md`——本处不复述，避免同一条判据出现两个书写位。
- **寿元消耗 `lifeSpanCost`（`selectCost` 成本类型的一个 element）。** 表示完成该事件对角色**寿元 / lifeSpan** 的扣减；它不是 AdventureEvent 上的独立平铺字段，而是**成本类型 `selectCost` 的组成 element 之一**（见上）。**内容侧以正数量值书写**（`1` = 消耗 1 点寿元），物化时取负。寿元由 life-cycle-service 在事件结算时按 `lifeSpanCost` 扣减，归 0 → `defeated`（大限将至）。
  - **定价是时长旋钮，不是固定基准。** 设计判据是**目标游玩时长**：**ch1 30–40 / ch2 35–45 / ch3 45–55 分钟**（熟练玩家口径）——**寿元预算不变，靠调 `lifeSpanCost` 把时长压回区间**（第三篇章预算 +300 远多于前两章，故定价相应**大幅上调**）。
  - **定价归属 = 「事件类型 × 篇章」的统一定价表，不逐条目手写。** 寿元消耗由 `systems/balance.md` 的一张表给出（如**闭关 Research 比常规事件耗时更长**、`combatTier` 各档可各有取值），**内容条目只在需要体现代价差异时标一个偏移 / 覆盖值**。**Explore 是这条通则的唯一例外**——它自成一行且禁用条目级覆盖，理由与校验见 `explore/_index.md`。
    - **理由：定价的设计判据本就是全局的目标时长，不是单个条目的风味。** 改一张表即可全局调时长，不必重扫数百个 `.tres`；也避免同类事件在不同作者手里定价漂移。
    - **推论：内容作者的默认动作是「不填」**——不填即取表上的类型基准值。「写正数量值、物化时取负」的约定对表值与覆盖值一视同仁，链路不变。
    - **表的具体取值仍待定**，留待内容扩充后的统计校准，见 `systems/balance.md`。
  - 个别事件可在表值之外设**更小**的覆盖值以体现代价差异；覆盖值遵循同一约定（内容侧写正数量值，物化取负）。
  - **形态 = 一个非负整数定值，不带区间、不带公式（承重）。** 模板侧不填 = 取定价表「事件类型 × 篇章」那一格；可填偏移 / 更小的覆盖值（Explore 禁填）；物化时取负填入 `ChangeElement.BaseValue`，`SelectCost` 内因此是一个**已定稿的单一负值**。**变异位共三个且无一新增**：定价表按类型 × 篇章分格 · 条目级偏移 / 覆盖 · `ModifierKey.LifeSpanCost`。三条理由各自独立成立：
    - **它是时长旋钮，判据是全局目标时长。** 区间掷定会让一个篇章的寿元支出成为随机变量，反推目标时长时要按期望值算并接受方差——旋钮精度直接下降，而这是定价表存在的唯一理由。
    - **Band 0 / Band 1 完全不显示 `selectCost` ⇒ 变异对玩家不可感知。** 一个察觉不到的随机化，设计表达为零而结构成本非零（模板侧两个字段 + 一次掷定 + 一条校验 + 定价表反推口径改写）。
    - **公式另外撞上两条：** 「内容侧不落裸数字、走枚举档 + 平衡表映射」的既有范式（表达式比裸数字更远）；以及运行期的成本变异已有 `ModifierKey.LifeSpanCost` 一条通道——再加一条公式即两处真值。
  - **Band 2 的精确展示取只读查询，不写回定稿实例。** 展示值 = `ApplyModifier(LifeSpanCost, SelectCost 内的 LifeSpan 值)` 的查询结果；施加点仍在 `TryApply`。写回会打两次折，见 `systems/services/profile-service.md`。
  - **`selectCost` 内的 `LifeSpan` 恒为消耗向：取值域收紧为非负（承重 · 同一条判据的第三个实例）。** 内容侧的表值与条目覆盖值**一律 ≥ 0**，物化取负后 `BaseValue ≤ 0`；**寿元回复只能落在 outcome / reward 侧**，见下方「寿元回复通道」。三条理由：
    - **成本侧回寿会改写终态判定 ① 的语义。** 既定流程是「`TryApply(SelectCost)` → 立刻判负 → 判负则短路」；若某条目在成本侧写产出向，玩家在寿元剩 1 点时选它**反而先被加寿元**，「支付后判定」这一步从压力点变成救命点——「明知是死路仍然走」这条承重取向被一个内容条目的符号翻转悄悄取消。
    - **成本侧回寿会让 Band 2 的展示自相矛盾。** Band 2 的语义是「如实展示精确扣减量」；一条 `+8` 的「扣减量」要么显示成负扣减（读者当场读成 bug），要么要为它单开一套呈现分支——为一个可以不存在的形态加一层 UI 状态。
    - **入场费与后果是两个概念。** 与「能力 element 恒不出现在 `selectCost`」「卡组 element 恒不出现在 `selectCost`」同判据：**成本侧只放「进这扇门要付什么」，产出一律是事件的后果。** 一条能倒贴的入场费不是入场费。
    - **形状与前两条不变式不同，故不合并：** 前两条是「某个列表恒为空」，本条是 `Elements` 内某个 key 的**取值域**收紧（`Elements` 在成本侧本就非空）。两处检查各自独立：**内容模板加载期**——`lifeSpanCost` 的表值 / 覆盖值为负 → `PushError` + 条目 `Id`；**物化组装后断言**——`SelectCost.Elements` 中 `Key == LifeSpan` 且 `BaseValue > 0` → `PushError`。
    - **代价明写（被接受）：** 内容作者少一个书写位——「一个便宜又回寿的事件」要写成「表值定价 + outcome 侧产出」两处。代价很小：定价表本就默认不填、取类型基准值，作者的默认动作不变。
- **寿元回复通道（非境界突破的寿元增长途径）。** 寿元除随境界突破按篇章增量抬升外，另有**回复通道**，三条获取路径共用**一条施加路径** `ChangeElement(CostKey.LifeSpan, +n)`：
  - **A · 回寿事件产出** —— AdventureEvent 的 outcome 侧产出，随 `ResolveOutcome` 并入 `eventEnd` 那一次合并 `TryApply`。
  - **B · 补天丹一类的法宝** —— `ItemData`，形态与准入边界见 `systems/character-profile/item/_index.md`；使用时即时经 `ProfileManager.TryApply` 写档（**批次层的主动消费即时提交**——即时提交的两条判据不看它发生在事件内还是事件外）。
  - **C · 商店购入 B** —— 补天丹是 `ExchangeGoodsKind.CharacterItem` 一族的普通内容条目，走既有购买路径与定价表，见 `systems/adventure-event/exchange/_index.md`。**纯内容编排，零新增结构。**
  - **寿元的施加路径零结构成本（承重）：** 三条通道共用 `ChangeElement(CostKey.LifeSpan, +n)`，不新增字段、不新增 element、不 bump 存档 schema——`LifeSpan` 已在 `ResourceElements` 表里、`BaseValue` 已带符号、`AppliedChange` 已记本次的账。**结构成本在通道 B 上另有两处，落在次数扣减与痕迹两侧**（`ProfileChangeSpec` 的道具次数列与使用痕迹列，见 `systems/services/profile-service.md`）——它们不属于寿元的施加路径。
  - **曲线的回升段两侧各有承载：事件内的由 `PastEventEntry.LifeSpanAfter` 自动画出；事件之外的由 `CharacterProfile.pastItemUse` 承载**，两条序列按 `(AfterEventSeq, Seq)` 归并、寿元值在同一趟遍历内由最近的事件锚点累加得出（算法见 `systems/character-profile/_index.md`）。**代价全在呈现与平衡两侧**（见下两条）。
  - **它与 Research 的 `Recuperate` 是两个量：** 后者回复 `lifeTotal`（战斗耐久），本条回复 `lifeSpan`（寿命预算）；两者在 `ResourceElements` 表里各占一行、终态原因各异。
  - **回寿的数字与 `selectCost` 同一个开关（承重）。** 精确数值**只在寿元 Band 2 出现**，Band 0 / Band 1 一律定性文案：

    | 位置 | Band 0 / Band 1 | Band 2 |
    |---|---|---|
    | eventOption 卡片的收益标注 | 定性标签（「延年」），无数字 | 如实展示 `+n`，与 `selectCost` 的 `−m` 并列 |
    | 补天丹的道具描述 | 定性正文（「服之可补益寿元」），无数字 | 正文之外由 UI 追加一行精确值 |
    | 结算面板的寿元行 | 定性一行 | 精确值 |

    - **依据是一条反证：** 若一个 eventOption 明写「+10 寿元」，寿元的绝对量纲当场泄露，玩家由此可反推每一步花了多少、还剩多少步——而「Band 0 / Band 1 不显示 `selectCost`」付出的全部代价正是为了封住这件事。**只封成本侧不封产出侧等于留一扇后门，而后门比正门更宽**：成本是逐事件的小数，回寿是一次性的大数，更容易被当作标尺。
    - **它是既有档位表的第六个消费方**，判据仍是「寿元 Band == 2」，与红字倒数、`selectCost` 精确展示**同一个开关、同时开启**。不新增字段、不新增流程。
    - **道具描述的门控形态：** `ItemData` 的描述是 `LocalizedText` 静态文案，做不到按 Band 变体 ⇒ **正文恒为定性文案，精确值由 UI 在 Band 2 追加一行**（数值取自 ability 定义，不写进文案）。这与「快照里一个字符串正文都不存」「文案跟随模板」的分层一致，翻译侧也不必为两种 Band 各写一版。
    - **代价明写（被接受）：** 玩家在常态档无法比较「这颗丹值不值这个价」。**这正是取向本身**，与「eventOption 不标注经验产出数字」是同一条纪律的又一个实例。
  - **平衡护栏 = 三道软闸 + 一条结构性禁令，不设硬上限。** 风险是**时长旋钮被架空**（定价表按目标时长反推，不受控的回寿能把一轮回无限拉长）。**不设「每篇章回寿总量上限」**——它需要一个新的存档字段与一处新校验，而下列软闸已把正反馈掐死：① 回寿事件照常付 `selectCost` ⇒ 净收益恒小于回寿量；② 回寿事件占 `eventCountLimit` 配额 ⇒ 它挤掉的是别的事件；③ 回寿法宝的**总量护栏落在内容编排面**——出现频率、商店库存深度与定价共同封顶它的可得量，规则层不设持有上限（口径见 `systems/character-profile/item/_index.md`）。
    - **结构性禁令：`eventType == Travel` 的条目其 outcome 侧不得含 `LifeSpan` 产出**（加载期 `PushError` + 条目 `Id`）。Travel **不计入 `eventCountLimit`** ⇒ 软闸 ② 对它整条失效，只剩定价最低一档的软闸 ①；一条带回寿的 Travel 条目就是「来回横跳换寿元」，与「Travel 定价那一格必须 > 0」要堵的零成本 reroll 是同一个漏洞的两半。**Explore 遮罩的情形自动覆盖**——被遮罩的真身本身就是一个 Travel 条目，模板侧校验照常命中。
    - **可调旋钮全在内容侧**：回寿事件 / 补天丹的 `RarityTier` 档与抽取权重、回寿量的表值。**改数值不改结构。**
    - 回寿量的标定口径（占本章 `ChapterLifeSpanBudget` 的百分比）与三档取值见 `systems/balance.md`。
  - **产出侧的 modifier 口径不变：** `LifeSpan` 行的 `GainModifier` 保持 `null`，故回寿不经 modifier pipeline，见 `systems/services/profile-service.md`。
  - **回升的叙事静默：** 回寿使 `|BandIndex|` 减小 = 靠近常态 ⇒ 不播文案，只更新 band 字段；回滞 δ 挡住阈值上的抖动。见 `systems/services/plot-manager.md`。
  - **不抬高 `ChapterLifeSpanBudget`，也不给寿元设 `Max` 上界。** 前者：回寿后剩余寿元可能超过冻结的分母（百分比 > 100%），这被接受——分母是篇章边界的口径量，章内抬高会让 30% / 10% 阈值在章内漂移，而回滞机制假定阈值不动；>100% 仍落在 Band 0，无呈现问题。后者：加上界会引出「补满时用丹浪费」这一整类挫败感，而 `lifeTotal` 那条线正是专门不设上限来消掉它的。
- **稳定 Id。** 作为数据资源，每个 AdventureEvent 内容条目有稳定唯一的字符串 `Id`（供 eventOptions 引用、`pastEvent` 轨迹、存档 key points、注册表查找）。Source: `data-resource-rules.md`。

### 模板侧的产出格（`OutcomeSpec` 的参数空间 · 共有字段）

**`AdventureEventData` 上的产出格共五格，`eventType` 不限**（Travel 另受 `LifeSpan` 禁令约束）。它们是**参数空间**，由 future-event-service 在物化时展开成 `EventOption.OutcomeSpec` 与 `EventOption.AbilityChangeSlots`；定稿形态与断言清单见 `systems/services/future-event-service.md`。

```csharp
[Export] public ExperienceGrade   ExperienceGrade   { get; set; } = ExperienceGrade.None;
[Export] public int               FailureRatio      { get; set; } = 50;   // 百分比整数，不用 float
[Export] public HiddenStatGrant[] HiddenStatGrants  { get; set; }         // (Stat, Grade, Direction)；胜负同施
[Export] public OutcomeRule[]     OnResolvedRules   { get; set; }
[Export] public OutcomeRule[]     OnFailureRules    { get; set; }
```

**`OutcomeRule` 的形状照抄 `ExchangeStockRule` / `ResearchSlotSpec` 已有的「规则 → 物化展开」范式，不发明第三种：**

```csharp
[GlobalClass] public partial class OutcomeRule : Resource
{
    [Export] public OutcomeRuleKind   Kind;          // FixedResource | GrantFromPool | DeckOperation
    // Kind == FixedResource
    [Export] public CostKey           ResourceKey;   // 可写 key 见下方白名单
    [Export] public int               Magnitude;     // 正数量值（与 lifeSpanCost 同一条书写约定）
    [Export] public OutcomeDirection  Direction;     // Gain | Loss —— 取负发生在物化组装，与 SelectCost 同处
    // Kind == GrantFromPool —— 只用于能力族授予
    [Export] public ExchangeGoodsKind PoolKind;      // 收窄为 { CharacterItem, CharacterPower }
    [Export] public RarityTier[]      RarityFilter;  // 空 = 不限。GrantFromPool 与 DeckOperation 两个 Kind 共用本格
    [Export] public int               Count = 1;     // 同上，两个 Kind 共用本格
    // Kind == DeckOperation
    [Export] public DeckChangeOp      DeckOp;        // element 层五值
    [Export] public string            TargetId;      // 定值条目；空 = 走池抽（仅 AddLooseCard 允许，见下）
    [Export] public CardType[]        CardTypeFilter;// 仅池抽路径有意义；空 = 不限。「随机两张业障」写 [Affliction]
}
```

- **`FailureRatio` 用百分比整数不用 `float`。** `AppliedChange` 要求可重放，整数百分比 + `floor` 是可复算的；浮点在跨平台重放上不是。折算口径（同档的 50%、**向下取整、下限 1**）见 `systems/game-progression.md` 与 `systems/balance.md`；折算本身在 `ProfileChangeSpec` 组装时完成，`TryApply` 收到的已是最终整数。
- **`DeckOp` 取 element 层的 `DeckChangeOp` 五值，不取面板层的 `DeckOperationKind`（承重）。** 后者是 Research 面板「玩家在这个槽里能选什么」的枚举，其中 `GrantItem` 落 `AbilityElements`、`Recuperate` 落 `Elements`，**都不落 `DeckElements`**；且它不含 `AddLooseCard`，而业障入组正走这一个 `Op`。用面板层枚举既装不下要装的、又装进了不该装的。
- **两个 `Kind` 的职责不重叠：`GrantFromPool` ↔ `AbilityElements`，`DeckOperation` ↔ `DeckElements`。** 故 `PoolKind` 收窄为能力族两值，卡牌 / 功法一律走 `DeckOperation`——否则「从卡牌池抽一张塞进卡组」有两个写法，作者只能靠约定选一个，而断言也没法逐 `Kind` 写死落哪一列。**`PlayerItem` 直接拒绝：事件产出不能给账号级古宝。**

**内容模板加载期校验**（一律 `PushError` + 条目 `Id`）：

| # | 校验 |
|---|---|
| 1 | `FailureRatio ∈ [0, 100]` |
| 2 | `Kind == FixedResource` 时 `ResourceKey ∈ { LifeSpan, LifeTotal, ManaLimit, SpiritStone, ImmortalJade }` 且 `Magnitude >= 0` |
| 3 | `Kind == FixedResource` 且 `ResourceKey == ManaLimit` 时 `Magnitude == 1` |
| 4 | `Kind == GrantFromPool` 时 `PoolKind ∈ { CharacterItem, CharacterPower }` 且 `Count >= 1` |
| 5 | `Kind == DeckOperation` 且 `TargetId` 非空时须经 `ContentRegistry` 解析（前三个 `Op` 解析功法、后两个解析卡牌） |
| 5b | `Kind == DeckOperation` 且 `TargetId` 为空且 `DeckOp != AddLooseCard` → 拒绝（其余四个 `Op` 无可抽之池，见下方取池链一节） |
| 5c | `Kind == DeckOperation` 且 `TargetId` **非空**时 `CardTypeFilter` / `RarityFilter` 须为空且 `Count == 1`（定值路径不吃过滤器；写了却静默无效是最难查的一类编排错） |
| 5d | `CardTypeFilter` 含 `Item` 或 `Power` → 拒绝（**卡组只装法术 / 阵法 / 业障**，抽到即无处可放） |
| 5e | `Kind == DeckOperation` 时 `Count >= 1`（与校验 4 同款） |
| 5f | 池抽路径的合法池（叠完全部过滤后）条目数 `< Count` → **`PushWarning`**（清单式软检查，报出 want / got，**不拒绝加载**）。它让「这个池实际有多大」在启动期就摆到内容作者面前；**不升格为拒绝**——事件产出没付过钱、短缺不构成空面板，逐条阻塞加载会在首批业障内容为零时拦下全部池抽规则 |
| 6 | `eventType == Travel` 的条目两侧规则不得出现 `ResourceKey == LifeSpan` 且 `Direction == Gain`（既有结构性禁令的模板侧落点） |
| 7 | `HiddenStatGrants` 内同一 `HiddenStat` 出现两条 → 拒绝（两条同属性的档位值互相覆盖，作者自己也不知道该落哪份） |
| 8 | `HiddenStatGrants` 内 `Grade == None` → 拒绝（一条什么都不做的 grant 是编排错误，不是缺省） |
| 9 | `HiddenStatGrants` 内 `Stat == HiddenStat.LifeSpan` → 拒绝（堵住绕过 `lifeSpanCost` 定价表 / 回寿量表与 Travel 回寿禁令的书写出口；现行校验 6 只覆盖 `OutcomeRule` 两侧，看不见 `HiddenStatGrants`） |

**`HiddenStatGrant` 的三格 `(Stat, Grade, Direction)`：类型定义与方向位的落点论证见 `systems/architecture.md`「共享核心类型」。** 模板侧只写「哪个属性 · 多大 · 哪个方向」，**符号在物化组装时由 `Direction` 取负**，与 `SelectCost` 的 `lifeSpanCost`、`OutcomeRule.Direction` 同处；作者在模板上从不落负数。

- **校验 8 与 `ExperienceGrade == None` 不同构。** 后者是一个**字段默认值**——缺省即不产出，是内容作者的默认动作；前者是**数组里的一条**，写了一条什么都不做的行是编排错误。这与「不产生无消费方的空条目」同向。
- **校验 9 堵的是一个真实可写出的口子。** `HiddenStat` 是三成员枚举 `{ Faith, Bloodlust, LifeSpan }`，故作者写得出 `(LifeSpan, Major, Raise)`，而它当场撞三条纪律：① `HiddenStatGrade` 的映射值是 `[0, 100]` 取值域的标定，套不到跨章 100 / 200 / 300+ 的寿元预算上（见 `systems/balance.md`）；② 它给寿元开出**第二个书写位**，绕过 `lifeSpanCost` 定价表与回寿量表这两张时长旋钮；③ **校验 6 只看 `OutcomeRule` 两侧，看不见 `HiddenStatGrants`** ⇒ `eventType == Travel` 不得回寿这条结构性禁令在 grant 侧原本没有落点。
- **方向位不需要新增去重校验。** 加上方向后 `(Faith, Minor, Raise)` + `(Faith, Minor, Lower)` 会净成 0，而校验 7 本就拒绝同一 `HiddenStat` 出现两条 ⇒ 这个坏形态已被封死。

**`ExperiencePoint` / `Faith` / `Bloodlust` 不在 `FixedResource` 的可写 key 内（承重）。** 它们只能由物化组装从 `ExperienceGrade` / `HiddenStatGrade` 的平衡表映射展开——**「物化后可出现的 key」与「模板可声明的 key」是两张表**。写成一张即让内容作者能落裸数字，同一个产出当场有两个书写位，「内容侧不落裸数字、走枚举档 + 平衡表映射」这条既定范式与平衡表的反推口径同时失效。

**`Elements` 的 outcome 侧取值域收紧是第四条不变式**，与「`AbilityElements` 恒空」「`DeckElements` 恒空」「`LifeSpan` 成本侧非负」三条并列、各自独立成行，同样两处各跑一遍（内容模板加载期 + 物化组装后）。逐条取值见 `systems/services/future-event-service.md`。

#### `DeckOperation` 走池抽的取池链与短缺处置

**走池抽（`TargetId` 为空）只对 `AddLooseCard` 开放，其余四个 `Op` 的 `TargetId` 必填非空。** 逐 `Op` 核对：

| `Op` | 池抽 | 依据 |
|---|:--:|---|
| `AddLooseCard` | **成立** | 过滤条件全部只读内容（`Pool` / 成员卡索引 / `CardType` / `RarityTier`）⇒ 干净落在第一级 `DrawPool<CardData>`，零结构成本 |
| `LearnTechnique` | **不开** | 见下方两条理由 |
| `UpgradeTechnique` | 不成立 | `Tier` 是**目标层数**，一次抽取给不出「抽哪门 + 到第几层」两个量 |
| `ForgetTechnique` | 不成立 | 「池」= 玩家当前卡组（运行期状态，非内容仓储），且卡组可被弃空 |
| `RemoveLooseCard` | 不成立 | 同上；散牌是多重集，随机移除还须另定义「同名多张抽哪一张」 |

**取池链逐字沿用商店 `Card` 族那一条，不另写一段**（该链本身也沿用授予池那一条）：

```
AllEnabled() → CardData 仓储
→ 叠 Pool != Enemy                            （玩家侧取池的通例）
→ 排除「被任一功法引用的成员卡」               （反建索引取 AllIncludingDisabled()）
→ CardTypeFilter 过滤
→ RarityFilter 过滤
→ 按 RarityTier 权重表 PickMany(rewardRng, Count)   // 无放回
```

- **掷定时点 = 物化时，不是结算时。** 抽出的卡在物化组装时展开为 `Count` 条独立的 `DeckChangeElement(AddLooseCard, drawnCardId, Tier = -1)`，随定稿实例落存档、**绝不重抽**——这与「产出侧的定稿载体是 `OutcomeSpec`，抽取 / 权重在物化时掷定」逐字一致。改在结算时掷会开出重掷窗口：Combat 类事件的产出在战斗之后结算，其间隔着多个决策点存档。
- **随机源 = `RngStream.Reward` 子流，不新开子流**（既有明文，见 `systems/services/future-event-service.md`）。
- **权重表挂战后奖励池那一张**（族维度已含卡牌，同为轮回内用途）；**事件产出侧固定取一档，不按战斗优势档选表**。取值见 `systems/balance.md`。
- **不新增 `DeckChangeElement` 的 count 格**：`Count` 在物化组装时展开为多条 element，与「同名多张 = 提交多条 element」一致（一条 element ↔ 一次可重放的操作）。产出的 element **不带 `Source`**，沿用 `DeckElements` 整列的既定形态。

**`LearnTechnique` 不开池抽的两条理由**（任一条成立即足够）：① 玩家侧功法取池共四处，**四处全部是玩家从候选里选**——功法是「一组必须整组入组的卡牌」，是玩家做构筑决策的颗粒度；开这一路会造出唯一「随机塞给你、不给选」的第五处。② 功法池抽必须**排除已持有** ⇒ 需读 `Profile` ⇒ 按 `ADR-0068` 落第二级，而第二级是**能力授予**的唯一取池处、功法不是能力族；要么扩它的职责、要么造第三级（明禁）。**内容侧的等价出口**：想给「一门随机功法」写多条定值 `TargetId` 并由事件模板自己编排分支；想给「三选一」，那正是 Research 类事件在做的事。

**运行期短缺处置**（与 Exchange 侧逐字同款，不发明第三种）：

| 情形 | 语义 | 处置 |
|---|---|---|
| 抽到 `0 < n < Count` | 可选缺失 | `PushWarning` + want / got；该规则产出 n 条 element，**不补位、不用定值顶替** |
| 抽到 0 条 | 可选缺失 | 同上；该规则贡献 0 条 element，**同一事件的其余 `OutcomeRule` 照常结算** |

**短缺不给玩家任何提示、不新增文案键。** 运行期到达此处只可能是 flags 收缩了池（`ContentEnabled` 按账号解析），而事件的其余产出照常成立——按既定层次这属可选缺失。

### 物化（materialize）：模板 `AdventureEventData` → 定稿实例 `EventOption`

**`AdventureEventData : Resource` 是模板 / 素材，不是成品。** 它承载稳定 `Id`、`eventType`、静态展示文案、基准数值与**可变体的参数空间**、数据驱动的 outcome / effect 定义。**多数**具体属性由 **future-event-service 依情境物化产出**——目的是「按不同情境制造更多变化与风味」。`eventPriority` 的动态置位只是这条规则的一个特例。

```
AdventureEventData(.tres)  ──▶  ContentRegistry 只读模板  ──▶  future-event-service 物化  ──▶  EventOption（定稿，immutable）
= 静态素材 / 参数空间              共享单例、可热更                情境代入                       只读消费，落存档
```

- **唯一物化点 = future-event-service。** 物化输入 = 模板（经 `AllEnabled()` 取池）+ CharacterProfile（含隐藏属性、修行历程）+ location 框定 + PlotManager 调制 + SeedManager 的 map 子流。
- **模板不可在运行时写。** `AdventureEventData` 是注册表里的**共享只读单例**且可被 overlay 热更覆写；写回它会污染同一轮回的后续批次与其他角色。
- **产出即定稿（finalized）。** `EventOption` 一经输出即冻结：life-cycle-service / combat-service / ViewModel 一律只读消费，**不得回查模板重算、不得改写其字段**。这保证「同一个事件在呈现、结算、记入历程三处看到的是同一份数据」。
- **定稿实例落存档，不重算。** 物化用了 seeded RNG、当时的角色状态、以及可热更的模板，确定性只在同一 `contentVersion` 内成立。因此**当前批 eventOptions 与 `pastEvent` 痕迹都存物化后的快照**。
- **`InstanceId` 与 `EventId` 并存：** 同一模板可在一次轮回里被物化多次，`pastEvent` / 事件负载一律按 `InstanceId` 定位。
- **哪些字段落定稿实例由一条物化判据给出，不逐字段拍板：** 由 seeded RNG 掷定 · 由情境代入而定 · 物化时组装或变换而成——命中任一条即落 `EventOption`，三条皆不命中的留在模板侧；文本类字段是反向的硬边界。**判据全文与反向边界归 `systems/services/future-event-service.md`。**
  - **它与快照判据是孪生的两条，分工不同：物化判据答「这一格在不在定稿实例上」，快照判据答「这一格要不要再抄进 `PastEventEntry`」。** 二者取值可以不同——`ExchangeStock` 在定稿实例上，痕迹侧却只靠 `AppliedChange` 记账。
  - **产出侧的定稿载体是 `EventOption.OutcomeSpec`**：抽取 / 权重在物化时掷定，结算时只按走向选一侧、不掷骰。走向 → 侧的映射表与 Combat 类的产出边界归 `systems/services/future-event-service.md`。
- 字段骨架与完整论证见 `systems/services/future-event-service.md` 与 `systems/architecture.md`「总则 6」。

### 结算阶段：`eventStart` / `eventEnd` 是流程阶段名，不是资源上的方法

**`eventStart` / `eventEnd` 是 `life-cycle-service.AdvanceEventAsync(...)` 内部结算流程的两个阶段名**，**不是 `AdventureEventData` 上的一对生命周期钩子**——事件不自带钩子。

**为何不是资源上的方法：** 若钩子是 `Resource` 上的虚方法，**新增一个事件就要新建一个 C# 子类**——「新增内容 = 新增一个 `.tres`」的可加性直接失效；且 `Resource` 是注册表里的共享单例，在其方法里持有本次结算的中间态会跨事件泄漏。

落地为一个数据驱动的结算器，五类事件共**两个**实现（resolver 的数量与 `eventType` 的数量本就不对应——拆分轴是「有没有状态机」，不是「有几个类型」）：

```csharp
internal interface IEventResolver          // 按 eventType 注册
{
    Task<ResolveOutcome> ResolveAsync(EventOption option, CancellationToken ct);
}
// CombatEventResolver  → Combat（三个 combatTier 档共用），转 combat-service
// GenericEventResolver → 其余四类，读物化后 EventOption 上的定稿 OutcomeSpec
```

固定流程（权威见 `systems/services/life-cycle-service.md`）：

```
校验选项合法性（Priority < EffectivePriority → 拒绝）
  → TryApply(SelectCost + EventStateChanges[ActiveEvent = 该项原样拷贝])  ← 同一次事务
  → 终态判定 ①（支付后立即）                 ← 判负 → 短路进失败流程，activeEvent 随失败流程一并清理
  → 【eventStart 阶段】选 resolver、Explore 揭示
  → resolver.ResolveAsync(activeEvent.Option, ct)      ← 传派生后的那一份
  → 【eventEnd 阶段】合并 ResolveOutcome + lifeSpanCost + 隐藏属性推拉
                     + TraceElements[本次 PastEventEntry]（快照取自 activeEvent.Option）
                     + EventStateChanges[ActiveEvent = null, ActiveCombat = null, EventOption = 新一批]
                     + RngElements[本次事件内消耗过的子流终态] 为**一次** TryApply
  → 终态判定 ②（结算后）→ EventBus 广播 → 自动存档点
```

**「记入 `pastEvent`」在收口那一次事务之内。** 痕迹经 `ProfileChangeSpec.TraceElements` 与其余各列同批提交，故「收口是一次事务、一个存档点」由结构兑现，而不依赖两步被写在一起。收口内部的组装顺序（先投影、后补两列）见 `systems/services/life-cycle-service.md`。

**结算期间的读取权威是 `activeEvent`（承重）。** `CharacterProfile.activeEvent != null` 时，本次结算涉及的 `EventOption` **一律读 `activeEvent.Option`**——它是派生后的那一份；当前批里的原实例只用于**呈现尚未开始的那些选项**与组装 `Unchosen` 轻摘要。收口时 `PastEventEntry` 的定稿实例快照同样取自它，否则履历会记下 `IsRevealed = false` 与刷新前的旧库存，而「同一个事件在呈现、结算、记入历程三处看到的是同一份数据」正是定稿纪律要买的东西。`activeEvent` 与当前批 `eventOption` 两个字段的形态、生命周期与七条读档校验见 `systems/character-profile/_index.md`。

**`eventStart` 那一步对 Explore 的具体形态：** `revealed = option with { IsRevealed = true }` 派生一个新实例（当前批里那份原实例不动，符合「产出即定稿、不得改写其字段」），随后**按真身的 `eventType` 选 resolver，而不是按 `EventOption.EventType`**——后者恒为 `Explore`，照它选会把一个战斗真身送进 `GenericEventResolver`。这正是「resolver 的拆分轴是有没有状态机、不是有几个类型」的直接落地。见 `explore/_index.md`。

**终态判定有两处：** ① 紧接 `TryApply(SelectCost)` 之后——支付本身可能耗尽寿元，此时**短路进失败流程**，事件不再结算；② 事件结算后照常判定。这是「支付 `selectCost` 是可推进行为、支付后判定状态」的直接落地。

由此职责边界完全明确：**扣成本、推拉隐藏属性、写 CharacterProfile 全部由 life-cycle-service 经 `profile-service.ProfileManager` 完成**；resolver 只**描述**结果（`ResolveOutcome`），不自行写档。

**事务纪律（承重）：一个事件的收口是一次事务、一个存档点；事件内部的主动消费即时提交。**

- **收口侧**：`eventEnd` 把 `ResolveOutcome` + `lifeSpanCost` + 隐藏属性推拉、以及 `EventStateChanges[ActiveEvent = null, EventOption = 新一批]` 合并为**一次** `TryApply`，全有或全无、单点提交，随后落一个自动存档点。**不新增结算阶段、不新增存档点类型。** 新一批依**更新后的** profile 算出（life-cycle-service 先取一份只读投影，见 `systems/services/profile-service.md`），故「依整体历程重算」与「收口是一次事务」同时成立。
- **事件内部侧**：玩家在事件内做出的**主动消费**即时经 `ProfileManager.TryApply` 写档，不攒到收口。当前四个实例：古宝使用次数的扣减 · 战斗过程中的血 / mana 变更 · Exchange 的逐笔交易 · **Exchange 的刷新**（`-灵石` 与新库存 + `RerolledCount` 落在同一次 `TryApply`）。
- **一次提交即一次本地原子写。** `TryApply` 提交后本地缓存立即原子写、push 另计——commit 与 push 的粒度对位见 `systems/services/sync-service.md`。**「不新增存档点」说的是不新增决策点与存档点类型，不是「这一次提交不落盘」**；两者解耦会开出「已提交但未落盘 ⇒ 退出重进即回滚」的窗口，正是本库明确要封的东西。事件内提交照常**不计**软阻塞闸门（闸门只数事件级存档点）。
- **两条判据，缺一不可：** ① 它是**玩家主动按下的一次消费**（不是结算算出来的后果）；② **不即时写就会开出一个「退出重进即回滚」的窗口**，或让「买得起吗」这类前置校验读到一份与 `Evaluate(spec)` 分裂的影子余额。两条都成立才即时提交——事件的**后果**一律留到收口。
- **接受的代价（明写）：** 中途退出的玩家会停在「已消费一部分」的状态。**这正是玩家的真实意图**，不是半成品状态；「全有或全无」约束的是**每一次提交**内部，不是整个事件。
- 施加侧的形态与失败语义见 `systems/services/profile-service.md`。

**隐藏属性推拉 = 一份 `HiddenStatGrade` + 一个方向，胜负同施，不套用 `FailureRatio`（承重）。** 一个事件条目为某个隐藏属性标一档并标一个推拉方向，**结算走向不改变施加的量，也不改变方向**——战斗胜负、事件成败都施同一份。

- **判据是语义差异，不是对称性偏好。** 经验有 `FailureRatio`（默认 0.5）是因为经验的语义是「**学到多少**」，失败也学到、按比例折算说得通；隐藏属性的语义是「**做了什么**」——屠戮就是屠戮，胜负不改变行为的性质。
- **且比率对双向属性无从解释：** 道心可正可负，「失败时道心下降取 50%」讲不通。
- **日后若确需让胜负推不同的量，正确形态是内容侧第二个可空的档位字段**（可正可负、语义自洽），**不是一个比率**——可空字段不牵动存档迁移。
- 三档 Combat 的默认口径见 `systems/adventure-event/combat/_index.md`；映射值与推拉量纲见 `systems/balance.md`；方向格的类型定义见 `systems/architecture.md`「共享核心类型」。

**隐藏属性的跨档定性反馈挂在 `eventEnd`（无新结构）。** 隐藏属性推拉在 `eventEnd` 阶段合并施加；**当某个隐藏属性因本次推拉而跨过一个隐藏档位时，附带一条定性的叙事描述**（不给数字）。它**复用已有的 `ResolveOutcome` → `eventEnd` 链路**，不引入新的结构或阶段。触发规则与档位归 `systems/services/plot-manager.md`，呈现归 `ux/screen-flow.md`。

### `pastEvent` 的痕迹 schema

**判据先于字段表：「重算不出来的存，重算得出来的不存」。**

> 凡「模板 + `EventId` 在任意 `contentVersion` 下都能稳定重建」的，**不进快照**；凡「由本次物化的情境 / seeded RNG / 当时角色状态决定，重建不出同一结果」的，**必进快照**。

**判据本身是这条设计的权威，字段表只是它当下的投影**——字段表会随「`EventOption` 完整物化字段清单」继续增长，判据不会。由它自动落定四条：

- **静态展示文案（显示名 / 描述 / 图标）不进快照**，按 `EventId` 经 `ContentRegistry.Get()` 随时取得（读取侧不过滤 `ContentEnabled`，被关闭的条目照常解析）。**文案改版不触发存档迁移**这条既有收益因此保住。
- **风味文案同样不进快照** —— 它跟随模板数据，与显示名 / 描述属同一层。**由此判据两侧再无灰色地带：所有文本类字段一律留在模板侧，快照里一个字符串正文都不存。**（这同时收窄了「`EventOption` 完整物化字段清单」那条待决问题的文本那一半，见下。）
- **模板上的基准数值、参数空间、outcome / effect 定义不进快照** —— 本次掷定的结果已经在 `AppliedChange` 里，存权重表等于存一份用不上的中间态。
- **物化产出的数值必进快照** —— `SelectCost`、`Priority`、Explore 真身、敌人赋级正是「重算不保证同结果」的那一半。

**「定稿实例必须落存档」与「存档态只带 `Id` + 可变状态、不复制展示文本」不冲突**（写明以免日后被误当成矛盾去松动其中一条）：后者管**展示文本**，前者管**物化数值**，快照存后者不存前者，两条同时成立。唯一可能让它们正面相撞的条件是「风味文案也物化」，而文案不物化，该条件不成立。

**痕迹条目 ≠ `EventOption`，而是「定稿实例快照 + 本次事件的最终账」。** 一个事件的权威事实是这次事件**总共发生了什么**，而非分散在 `ResolveOutcome` / `lifeSpanCost` / 隐藏属性推拉 / 事件内逐笔消费里的若干片段——**存最终账一份，胜过存若干片段再让读取方自己合**。

```csharp
public sealed record PastEventEntry(          // 痕迹条目：immutable，只追加，落存档
    int                Seq,                   // 角色内单调递增的时序坐标；不复用、不因迁移重排
    string             InstanceId,            // 定位键；与被结算的那个 EventOption 同值
    string             EventId,               // 溯源模板（disabled 条目照常解析）
    EventType          EventType,             // 当时呈现给玩家的类型；Explore 时 = Explore 本身
    string             RevealedEventId,       // Explore 真身；非 Explore 为空串
    int                Priority,              // 当时的物化置位 { 0, 1 }；回溯「这一步是不是被闸门收窄的」
    string             BatchId,               // 归属批次；与未选项摘要同批
    string             LocationId,            // 当时所在地域；Travel 记出发地（见下）
    ProfileChangeSpec  SelectCost,            // 物化组装的定稿 spec（带符号，已取负）
    ProfileChangeSpec  AppliedChange,         // 本次事件的最终账：收口那一次 spec + 事件内逐笔已提交的 spec
    EventOutcome       Outcome,               // 结算走向
    int                LifeSpanAfter,         // 结算后剩余寿元 —— 判据的明示例外，见下
    IReadOnlyList<UnchosenOptionRef> Unchosen,// 同批未被选中的选项轻摘要
    EnemyTraceRef      Enemy                  // 战斗类痕迹的敌人摘要；非战斗类为 null
    /* 产出侧不带来痕迹侧扩充 —— 本次事件的最终账已在 AppliedChange 里；
        文本类字段不在扩充范围内 —— 风味文案跟随模板 */);

public sealed record EnemyTraceRef(           // 战斗类痕迹的敌人摘要：只求可回溯，不求可重建
    string EnemyId,                           // 溯源模板 → EnemyCodex 词条 / 履历显示名（disabled 条目照常解析）
    int    Level);                            // 物化赋级产物，重算不出来 ⇒ 必存

public sealed record UnchosenOptionRef(       // 未选项：只求可回溯，不求可重建
    string    InstanceId,
    string    EventId,
    EventType EventType,
    int       Priority);

public enum EventOutcome { Resolved, CombatWon, CombatLost, Aborted }
// Resolved               = 非战斗类事件正常结算
// CombatWon / CombatLost = 战斗类事件的胜负（剧本与履历都要读，且不可由 AppliedChange 可靠反推）
// Aborted                = 支付 SelectCost 后终态判定 ① 即短路，事件未进入 resolver
```

- **`AppliedChange` 是核心，也是唯一真正新增的东西。** 有了它，「这个角色一路上到底发生了什么」是一条可直接重放的账；没有它，履历 / 剧本 / 诊断三个消费方各自去猜。它**复用既有的 `ProfileChangeSpec`，不引入新类型**。
- **`AppliedChange` 的语义 = 本次事件的最终账，不是某一次 `TryApply` 的入参（承重）。** 事件内部的主动消费即时提交（见上方事务纪律），故它们不在收口那一次里；**由 life-cycle-service 在组装痕迹时把逐笔已提交的 spec 累加进来——记账，不再施加**（它不是第二个写入点）。不这样做，履历 / 剧本 / 诊断就读不出玩家在商店里做了什么，而这正是引入 `AppliedChange` 要消除的坏状态。
  - **代价明写：** `AppliedChange` **不再与「收口那一次 `TryApply` 的入参」逐字段相等**，两者的一致性**不能再机械断言**。诊断与回放读它时一律以「最终账」为准；需要区分「哪些是收口施加的」时，靠逐笔提交自身的可追溯性日志，不靠比对这两者。
  - **可重放性不受影响**：累加后的 spec 仍是一串已定稿的 element，重放一次仍得同一结果——这正是「element 只承载已定稿的 `Id`」那条纪律买到的东西。**RNG 子流终态照常入账**（`RngElements` 不被剔除），故这条账连随机状态一起重放得出。
  - **累加时的列剔除清单（承重）：账记的是变更，不记账本本身。** 逐笔已提交的 spec 累加进来时，**装的是整块状态快照而非一笔变更的列一律剔除**——当前即 `EventStateChanges`（`activeEvent` / `eventOption` / `activeCombat` 三个中间态字段）。**不剔除的后果是可算的**：一次战斗事件在 D0–D5 各提交一次整块 `ActiveCombat`（单点 2–4 KB），全部累加即让单条痕迹胖到几十上百 KB，与本节「战斗类痕迹只存 `EnemyId` + `Level` 轻摘要」的体积纪律正面相抵——否决存 `DeckCardIds` 的理由（最胖的物化产物 + 痕迹侧的体积护栏）在这里逐字适用。
  - **`AppliedChange` 恒不含 `TraceElements`（不变式）。** 否则一条痕迹的账里装着一条痕迹，自指。落为 `ProfileManager` 入口断言。**它只覆盖这一列**——剔除清单（上一条）与自指防呆（本条）是两件事，前者按「是不是账本本身」判，后者按「会不会自指」判。
- **战斗类痕迹只存敌人的轻摘要（`EnemyId` + `Level`），不存整份 `EnemyInstance`。** 等级是物化赋级产物、重算不出来 ⇒ 必存；模板 `Id` 是 EnemyCodex 与履历显示名的溯源键。**不存 `DeckCardIds` / `ItemIds` / `PowerIds`** 三条理由：① 事件已结算，这三项永不会再被任何流程消费（与未选项同款论证）；② 它们是本作最胖的物化产物（每条痕迹一份完整卡组 `Id` 序列），而痕迹侧本就有体积护栏与增量 push 的顾虑；③ 三个消费方（EnemyCodex 遭遇即记 · 角色履历「这一步打了谁」· 诊断的越阶分布）要的都只是「打了谁、几级」。
  **如实记下代价**：日后若要做战斗回放，缺卡组序列就重放不出来——彼时正确的做法是给回放单独存一份，而不是让每条痕迹都胖一整副牌。
  字段名取 `EnemyId` 与 `EnemyInstance.EnemyId` 一致，全库一个名字指同一个东西。
- **`Seq` 是时序坐标，不是内容键。** 「绝不用数组索引作内容的键」约束的是内容键；`Seq` 显式写出来才能在日志、履历展示与诊断中安全提及。角色内单调递增、不复用、不因迁移重排。**首条为 `0`**，此后每条 `+1`；起始值与 `PlotKeyPoint.EnteredAtSeq` 的下界校验（`< 0` 即坏档）同源——那一格引用的正是本字段。追加时的连续性由 `ProfileManager` 入口校验（`Seq != 末条 Seq + 1`，空列表时 `!= 0` → 整批拒绝），是读档侧「`Seq` 不连续 / 重复」校验的对偶。
- **`LifeSpanAfter` 是上述判据的明示例外。** 它可由 `AppliedChange` 全序列重放得出，按判据本不该存；但它**已在 `EventResolved` 负载里**（`LifeSpanRemaining`），且元进程的角色履历要画寿元曲线。**成本 4 字节 × 200 条 = 800 字节，换掉一次全序列重放。** 它是**写明的例外，不是先例**——不得据此放宽判据。
- **结算中被派生改写的两族字段不进痕迹（`ExchangeStock` / `RerolledCount`）。** 它们重算不出来，但事件收口后**永无消费方**——本次买下的东西已在 `AppliedChange` 里，未选项只要四字段轻摘要——故按判据的完整口径「重算不出来**且有消费方**」不存，与 `plotKeyPoint`「不记已走分支路径」同款处置。`IsRevealed` 同理，`RevealedEventId` 本就恒存。**故派生实例的承载不给痕迹侧带来任何 schema 增量。**
- **`EventType` 存、`combatTier` 不存 —— 这条口径不对称是有理由的，不是遗漏。** `EventType` 存的是**当时呈现给玩家的口径**：Explore 时它等于 `Explore` 本身而与真身不同，这是一条独立事实，模板重建不出来。`combatTier` 没有这种分叉——**一个内容条目只有一个档**，按 `EventId` 查一次模板即得，故按判据不存。履历与呈现两个消费方本就要按 `EventId` 取显示名 / 描述 / 图标，tier 在同一次 `ContentRegistry.Get()` 里免费拿到。
- **`Aborted` 是跳过通道移除后的直接产物。** 支付 `selectCost` 后立即判负会短路、事件不再结算，但**这一步仍然发生过**（成本已施加、`selectCost` 不回滚），必须留痕且必须与正常结算可区分——否则履历上会出现一条「结算了但什么也没产出」的诡异记录。它通常是角色的**最后一条**痕迹。
- **`LocationId` 的语义是「这一步发生在哪」，故 Travel 记出发地。** Travel 是唯一一类会在自己结算过程中改写角色所在 location 的事件；它的痕迹**记离开时所在的那个地域**，目的地由**下一条痕迹**的 `LocationId` 自然给出。这不新增字段，只消除一处歧义——`LocationCodex` 从痕迹序列读出的路径因此是连贯的。
- **枚举保持四值，不为 DnD 式选分支预留成员。** 分支形态未定时预留即臆造；日后若需要，是**新增一个可空字段**（`ChosenBranchId`），不是改枚举——**枚举成员的增删牵动存档迁移，可空字段不牵动**。

**未被选中的选项 = 归档轻摘要。** 论证基础是一条推演：**「定稿实例必须落存档」对未选项不成立**——该条的理由是「重算不保证同结果，而这份实例还要被消费」，而未选项在下一次整批重算时即被丢弃，**永远不会被任何流程消费**；它们不需要**可重建**，只需要**可回溯**。剧本要的信号是「玩家回避了什么类型 / 什么内容」，`EventType` + `EventId` 就足够；未选项的 `SelectCost` 永不会被施加，敌人实例永不会入场。

| | 方案 | 单事件增量 | 剧本可读出 | 结论 |
|---|------|-----------|-----------|------|
| A | 不归档 | 0 | 只有「选了什么」 | 否决：回避信号**永久丢掉**，日后想补要改 schema + 迁移 |
| **B** | **归档轻摘要**（四字段） | **~4 × 60 B ≈ 240 B** | 「选了什么」+「同批还摆着什么而没选」 | **采纳** |
| C | 归档完整快照 | ~4 × 500 B ≈ 2 KB | 同 B（多出字段无消费方） | 否决：体积翻数倍换零新增信息 |

**副产品：批次的完整性得以保留。** `pastEvent` 不再是一串孤立事件，而是一串**批次**——「这一步你面前摆着这四个，你选了第二个」。这对元进程的角色履历展示与日后的「回放 / 复盘」都是免费的地基。

**与 AdventurePlot key points：单向读取、零结构耦合。** `pastEvent` 不持有任何 key point 引用，key points 也不引用 `PastEventEntry`；PlotManager 只把 `pastEvent` 当只读输入。**推论：`pastEvent` 的 schema 不受「key points 粒度」这个待答项阻塞，两者各自定稿。** 详见 `systems/services/plot-manager.md`。

**存档与校验：**

- **本次落定 `pastEvent` 结构 → bump 存档 schema 版本**；当前无线上存档 → **空迁移**，走既有 MigrationManager 骨架。只追加不变式与体积护栏见 `systems/services/sync-service.md`。
- **加载时校验：** `EventId` 经 `ContentRegistry` 解析不到 → **可选缺失** → `GD.PushWarning` + 该条降级为「仅标识可读」（履历显示为未知条目），**不阻断读档**——历程是历史记录，一条读不出的旧条目不该让整个角色无法进入。`InstanceId` 缺失 / `Seq` 不连续 / `Seq` 重复 → **必需缺失** → `GD.PushError` 带 `characterId` + `seq`。
- **写入点不新增。** 上方结算流程里「记入 `pastEvent`」这一步的语义具体化为：**由 life-cycle-service 组装 `PastEventEntry`（含从被替换的当前批取未选项摘要），放进收口 spec 的 `TraceElements` 列，经 `profile-service.ProfileManager` 写入**——与「档案写入的唯一入口」一致，不绕过，且与收口的其余各列落在同一次事务里。**`Aborted` 那一条同样如此**：支付后终态判定 ① 短路的那一路由失败流程组装**一次**提交，同时承载这条痕迹与 `activeEvent` / `activeCombat` 的清空、轮回结束的统计计数，**不新增存档点**。


### 通用流程

- **呈现 = 月圆之夜风格。** 修行事件以精心策划的**事件菜单**形态呈现，参考《月圆之夜》。
- **选择 = 横向滑动选择区。** 「从可用修行事件（eventOptions）中选择」用一个**可横向滑动的选择区**（horizontal scrolling area），滑动选中目标 AdventureEvent。详见 `systems/game-progression.md`。
- **进入。** 玩家在选择区选中一个可用 AdventureEvent 后进入该事件；Explore 在进入时揭示其被遮罩的固定事件。Source: `terminology.md`。
- **结算与后果。** 事件结束后其后果影响玩家及未来状态（隐藏属性推拉、eventOptions 重算、location 刷新等）；结算规则因子类型而异——**仅 Combat 走战斗结算**（三个 `combatTier` 档共用同一回合循环与参战方结构，差异在遭遇参数），其余四类为事件式结算，Explore 视其真身而定。
- **自动存档边界。** 事件为合理的自动存档点之一（每场遭遇战 / 地图节点之后）。Source: `state-save-rules.md`。

Source: `handoffs/2026-08-25-currency-split-spirit-stone-and-immortal-jade.md` · `handoffs/2026-07-22-online-cloud-combat-and-meta-clarifications.md` · `handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md` · `handoffs/2026-07-24-docs-restructure-class-model.md` · `handoffs/2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md` · `handoffs/2026-07-25b-event-cost-fields-capability-flags-and-service-hierarchy.md` · `handoffs/2026-07-26-event-priority-skip-semantics-and-hotfix-scope.md` · `handoffs/2026-07-27b-service-api-contracts.md` · `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md` · `handoffs/2026-08-06c-skip-channel-removal-priority-two-tier-and-location-codex-edges.md` · `handoffs/2026-08-09c-past-event-trace-schema.md` · `handoffs/2026-08-10c-ability-disable-replacement-and-player-statistics.md` · `handoffs/2026-08-15c-event-type-collapse-and-batch-shape.md` · `handoffs/2026-08-15d-intent-removal-lifespan-cost-visibility-and-design-audit.md` · `handoffs/2026-08-16d-cost-side-closure.md` · `handoffs/2026-08-16g-travel-mechanics-and-location-carrier.md` · `handoffs/2026-08-17-travel-destination-and-status-change-elements.md` · `handoffs/2026-08-17c-explore-reveal-mechanics.md` · `handoffs/2026-08-17d-exchange-mechanics-and-transaction-discipline.md` · `handoffs/2026-08-17e-finale-combat-only-and-hidden-stat-io.md` · `handoffs/2026-08-17f-lifespan-restoration-paths.md` · `handoffs/2026-08-17j-event-option-derived-persistence.md` · `handoffs/2026-08-19-profile-change-spec-gaps.md` · `handoffs/2026-08-22-event-generation-weighting-pipeline.md` · `handoffs/2026-08-22-event-outcome-spec-fields.md` · `handoffs/2026-08-22-priority-elevation-criterion.md` · `handoffs/2026-08-22-hidden-stat-grant-direction.md` · `handoffs/2026-08-25-combat-presentation-and-action-result.md` · `handoffs/2026-08-27-card-pool-and-reshuffle.md`

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- **呈现形态、选择交互** 见「意图」及 `decisions/ADR-0002-adventure-event-taxonomy.md` 上下文。
- **`pastEvent` 痕迹 schema（`PastEventEntry` + 判据 + 未选项轻摘要）** 见「意图」的同名小节 → `decisions/ADR-0021-past-event-trace-schema.md`（Accepted）。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **五类之间的配比取值未定。** 生成规则的**运算形态已全部给出**（数量由 `BatchSizeWeights` 掷定、类型修正是乘性系数、多 arc 权重相乘 / 白名单取并、十步管线，见上与 `systems/services/future-event-service.md`）；仍待定的是**基础类型权重表 `BaseTypeWeights` 每格填多少**，以及 Combat 内 `combatTier` 三档的配比。→ `systems/balance.md`。
- **`lifeSpanCost` 定价表的具体取值：** 表的**形态**已定（「事件类型 × 篇章」统一定价表，内容条目只标偏移 / 覆盖值；目标时长驱动、逐篇章上调、闭关更耗）；仍待定**每格填多少**——需以 30–40 / 35–45 / 45–55 分钟反推。→ `systems/balance.md`。

Source: `handoffs/2026-07-25b-event-cost-fields-capability-flags-and-service-hierarchy.md` · `handoffs/2026-07-27b-service-api-contracts.md` · `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md` · `handoffs/2026-08-06c-skip-channel-removal-priority-two-tier-and-location-codex-edges.md` · `handoffs/2026-08-09c-past-event-trace-schema.md` · `handoffs/2026-08-15c-event-type-collapse-and-batch-shape.md` · `handoffs/2026-08-16d-cost-side-closure.md` · `handoffs/2026-08-22-hidden-stat-grant-direction.md`

## 对应
提炼至：`.claude/knowledge/systems/adventure-event/common-properties.md`（待建）
