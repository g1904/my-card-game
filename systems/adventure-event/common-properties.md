# adventure-event / common-properties（AdventureEvent 顶层共有属性）

> 所有 AdventureEvent 子类型共有的属性 / 字段与通用流程。各子类型专有属性见其各自的 `common-properties.md`。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

### 共有属性 / 字段

- **AdventureEvent 之间不存在前后连边。** 单个 AdventureEvent 只是一份自足的内容条目，**不持有指向后续事件的引用**——事件之间的走向不由内容作者预先连线，而由 **future-event-service 在运行时依角色状态产出的一批 `List<EventOption> eventOptions`** 决定：受角色当前 location（地域）框定，并被隐藏剧本层 AdventurePlot 持续调制（见 `systems/services/future-event-service.md`、`systems/services/plot-manager.md`）。
- **`pastEvent`（历程轨迹 · CharacterProfile 侧）。** 与向前的走向相对，向后的**已经历轨迹**仍需持久化：`pastEvent` 是一条**扁平的时序列表**（不是图的反向边），记录角色走过哪些事件。它归属 CharacterProfile 的轮回状态，不挂在 AdventureEvent 上。**只有一种痕迹：进入并结算**——跳过通道已整体移除（见下方「一批只有一次操作」）。条目类型 `PastEventEntry` 与字段表见下方「`pastEvent` 的痕迹 schema」。
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
    - **连带收窄：** 待答项「遮罩下的 `selectCost` 呈现」（Explore 真身与遮罩壳的成本不一致会泄漏信息）在 Band 0 / Band 1 **自动消解**（什么都不显示就没有泄漏面），**只在 Band 2 才需要回答**。
  - **支付 `selectCost` 是无条件的可推进行为（承重）。** 选中一个事件时，`selectCost` **照常施加，不因「付不起」被拒绝**；**支付之后做状态判定，判负则进入既有的失败流程**（寿元归 0 → 「大限将至」→ `defeated`）。
    - **明确不存在的东西：** `AdvanceEventAsync` 里**没有**「`TryApply(SelectCost)` ← 付不起则拒绝，不产生任何写入」这一步，`program-overview.md` 阶段 4 也**没有**「付不起 → 拒绝，回到呈现步」这条回路。不要把它们加回来。
    - **推论 ①（承重）：「付不起唯一可选项 ⇒ 轮回无法推进」这个死锁在规则层不成立**，且**不是靠产出侧保证闭合的**——future-event-service 不欠 `selectCost` 侧任何可负担性保证（与「不给可战胜保证」同一种收口：不给保护，给出口）。
    - **推论 ②：终态由支付后的状态判定给出，而不是由「付不起」这个事实给出。** 支付后未必死——付寿元才可能触发终态，付非终结性资源只是变穷。
    - **推论 ③：「付不起」在事件选择面整体消失。** UI **不需要不可选 / 置灰态**。**「明知是死路仍然走」是有意义的玩家决策**（与「打不过也得打」同构），而它所需的信息由 **Band 2 的精确展示**兑现——`selectCost` 只在寿元 < 10% 时如实展示，常态档不显示，见上条。
    - **事务性不变、可负担性校验去掉。** `ProfileManager.TryApply` 仍是全有或全无的单点提交；**它不为事件推进做「先校验付得起、否则整体拒绝」**。**负值施加时各资源的钳制规则待定**，见待决问题。
  - **代码形态 = `ProfileChangeSpec`（三个平级列表）。** 该复合成本类型即 `ProfileChangeSpec`——`Elements`（资源，`ChangeElement.BaseValue` **带符号**：负 = 消耗，正 = 产出）· `AbilityElements`（能力，按 `Id` 的集合成员操作）· `Stats`（统计计数，纯自增）。**`selectCost` 只用得到第一个列表**：另两个在成本侧恒为空（见下）——**成本与产出共用一个类型**，因为「全有或全无、单点提交」本就要求二者落在同一事务内。`selectCost` 在**物化时组装**（modifier pipeline 尚未施加，它在 `ProfileManager.TryApply` 那一刻才生效）。
  - **内容侧写正数量值，spec 里仍是负数（两条约定各自成立）。** 带符号约定**不变**；但**内容作者标注的成本一律是正数量值（magnitude）**——「这个事件耗 3 点寿元」写 `3`，不写 `-3`。**取负发生在 future-event-service 物化组装 `selectCost` 的那一刻**（见 `systems/services/future-event-service.md`）。二者并行不悖：作者面对的是「花多少」，`TryApply` 面对的是带符号 element。

    | 层 | 形态 |
    |----|------|
    | `AdventureEventData.tres` / 平衡分档表 | **正数量值** |
    | `EventOption.SelectCost` 内的 `ChangeElement.BaseValue` | **取负**（`-magnitude`） |
    | `ProfileManager.TryApply` | 照常按带符号 element 施加 |
  - **能力 element 恒不出现在 `selectCost`（承重）。** `ProfileChangeSpec.AbilityElements` 在 `EventOption.SelectCost` 内**恒为空**——事件对能力的三种操作（`Grant` / `Remove` / `Disable`，即置换型剥夺与本轮回禁用）**只能出现在 outcome / reward 侧**。四条支撑：① **成本侧只放可如实计价的量**（`selectCost` 的展示纪律是让玩家能自己算出「这一步可能是最后一步」，面向可计量资源；一条法则值多少寿元无法回答）；② **成本侧无条件施加，与置换的「先看后决 · 拒绝无代价」正面冲突**；③ **能力得失是事件的后果，不是入场费**——三级严重度阶梯描述的是事件**造成**了什么；④ **它换来一条可机械检查的不变式**：`SelectCost.AbilityElements` 恒空 ⇒ 物化组装后断言 + 内容模板加载期校验，两处均 `PushError`。
  - **outcome 侧的对应形态**（置换与禁用共用同一条链路）：

    | | 形态 |
    |---|---|
    | 候选何时掷定 | **结算时**（`eventEnd` 之前），走 `reward` 子流 |
    | 玩家看到什么 | 结算面板展示「失去 A · 得到 B」+ 接受 / 拒绝；禁用型只展示告知，无选择 |
    | 「拒绝」是什么 | 点「拒绝」，什么都不发生（零代价） |
    | 事件内决策点 | **有**，形状与战后奖励面板完全同构 |
    | 落存档 | 决策点存档记录已掷定的候选；结果进 `PastEventEntry.AppliedChange` |

    **不新增机制**——战后奖励面板已经是「预先算定的候选 + 玩家择一 + 随后并入 `eventEnd` 那一次 `TryApply`」。**候选必须预先算定并落决策点存档**，否则退出重进可以重掷候选。**推论：`PastEventEntry.SelectCost` 的快照形状不受影响**（它只装资源 element），`AppliedChange` 则新增能力 element 与统计 element。规则权威见 `systems/player-profile/player-power/_index.md`，element 形态见 `systems/services/profile-service.md`。
- **批次规模 = 常态 3 项，取值区间 1–5。** 一批 eventOptions **通常摆 3 个**选项，允许的范围是 **1 到 5**。**推论 ①：批次不是固定宽度**，产出侧要按批给出数量而非套一个常数。**推论 ②：1 项的批次是合法的**，此时「择一进入」退化为「只能进这一个」——它与 `eventPriority = 1` 收窄到单项、以及 Travel 的 20% 随机档天然同形，**不需要额外规则来允许它**。**区间两端由什么驱动**（location？篇章？剧本？）未定，见待决问题。
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
  - **推论：两档 ⇒ 不存在「优先级 2 压过优先级 1」的层叠语义。** Travel 闸门用的「最高优先级」就是 `1`，与剧情线的强制事件**共用同一档**——两者同批出现时玩家在它们之间自由择一。
- **寿元消耗 `lifeSpanCost`（`selectCost` 成本类型的一个 element）。** 表示完成该事件对角色**寿元 / lifeSpan** 的扣减；它不是 AdventureEvent 上的独立平铺字段，而是**成本类型 `selectCost` 的组成 element 之一**（见上）。**内容侧以正数量值书写**（`1` = 消耗 1 点寿元），物化时取负。寿元由 life-cycle-service 在事件结算时按 `lifeSpanCost` 扣减，归 0 → `defeated`（大限将至）。
  - **定价是时长旋钮，不是固定基准。** 设计判据是**目标游玩时长**：**ch1 30–40 / ch2 35–45 / ch3 45–55 分钟**（熟练玩家口径）——**寿元预算不变，靠调 `lifeSpanCost` 把时长压回区间**（第三篇章预算 +300 远多于前两章，故定价相应**大幅上调**）。
  - **定价归属 = 「事件类型 × 篇章」的统一定价表，不逐条目手写。** 寿元消耗由 `systems/balance.md` 的一张表给出（如**闭关 Research 比常规事件耗时更长**、`combatTier` 各档可各有取值），**内容条目只在需要体现代价差异时标一个偏移 / 覆盖值**（含产出向的回寿事件）。
    - **理由：定价的设计判据本就是全局的目标时长，不是单个条目的风味。** 改一张表即可全局调时长，不必重扫数百个 `.tres`；也避免同类事件在不同作者手里定价漂移。
    - **推论：内容作者的默认动作是「不填」**——不填即取表上的类型基准值。「写正数量值、物化时取负」的约定对表值与覆盖值一视同仁，链路不变。
    - **表的具体取值仍待定**，归 ch1 数值标杆专场，见 `systems/balance.md`。
  - 个别事件可在表值之外设更小或**产出向**（回寿）的覆盖值以体现代价差异——产出向的写法遵循同一约定（内容侧写量值，语义由字段方向承载）。
- **稳定 Id。** 作为数据资源，每个 AdventureEvent 内容条目有稳定唯一的字符串 `Id`（供 eventOptions 引用、`pastEvent` 轨迹、存档 key points、注册表查找）。Source: `data-resource-rules.md`。

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
// GenericEventResolver → 其余四类，读模板上的数据驱动 outcome / effect 定义
```

固定流程（权威见 `systems/services/life-cycle-service.md`）：

```
校验选项合法性（Priority < EffectivePriority → 拒绝）
  → TryApply(SelectCost)                     ← 无条件施加；不做「付得起」校验
  → 终态判定 ①（支付后立即）                 ← 判负 → 短路进失败流程，不再进入 resolver
  → 【eventStart 阶段】选 resolver、Explore 揭示
  → resolver.ResolveAsync(option, ct)
  → 【eventEnd 阶段】合并 ResolveOutcome + lifeSpanCost + 隐藏属性推拉为**一次** TryApply
  → 记入 pastEvent（按 InstanceId，携带定稿实例快照）
  → 终态判定 ②（结算后）→ EventBus 广播 → 自动存档点
```

**终态判定有两处：** ① 紧接 `TryApply(SelectCost)` 之后——支付本身可能耗尽寿元，此时**短路进失败流程**，事件不再结算；② 事件结算后照常判定。这是「支付 `selectCost` 是可推进行为、支付后判定状态」的直接落地。

由此职责边界完全明确：**扣成本、推拉隐藏属性、写 CharacterProfile 全部由 life-cycle-service 经 `profile-service.ProfileManager` 完成**（一个事件 = 一次事务 = 一个存档点）；resolver 只**描述**结果（`ResolveOutcome`），不自行写档。

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

**痕迹条目 ≠ `EventOption`，而是「定稿实例快照 + 本次结算的最终账」。** 一个事件的权威事实是 `eventEnd` 那**一次**合并 `TryApply` 的 spec，而非分散在 `ResolveOutcome` / `lifeSpanCost` / 隐藏属性推拉里的若干片段——**存最终 spec 一份，胜过存若干片段再让读取方自己合**。

```csharp
public sealed record PastEventEntry(          // 痕迹条目：immutable，只追加，落存档
    int                Seq,                   // 角色内单调递增的时序坐标；不复用、不因迁移重排
    string             InstanceId,            // 定位键；与被结算的那个 EventOption 同值
    string             EventId,               // 溯源模板（disabled 条目照常解析）
    EventType          EventType,             // 当时呈现给玩家的类型；Explore 时 = Explore 本身
    string             RevealedEventId,       // Explore 真身；非 Explore 为空串
    int                Priority,              // 当时的物化置位 { 0, 1 }；回溯「这一步是不是被闸门收窄的」
    string             BatchId,               // 归属批次；与未选项摘要同批
    string             LocationId,            // 当时所在地域
    ProfileChangeSpec  SelectCost,            // 物化组装的定稿 spec（带符号，已取负）
    ProfileChangeSpec  AppliedChange,         // eventEnd 那一次合并 TryApply 的最终 spec
    EventOutcome       Outcome,               // 结算走向
    int                LifeSpanAfter,         // 结算后剩余寿元 —— 判据的明示例外，见下
    IReadOnlyList<UnchosenOptionRef> Unchosen // 同批未被选中的选项轻摘要
    /* ⟨随「EventOption 完整物化字段清单」与「敌人实例类型形态」两项答定后扩充；
        文本类字段不在扩充范围内 —— 风味文案跟随模板⟩ */);

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
- **`Seq` 是时序坐标，不是内容键。** 「绝不用数组索引作内容的键」约束的是内容键；`Seq` 显式写出来才能在日志、履历展示与诊断中安全提及。角色内单调递增、不复用、不因迁移重排。
- **`LifeSpanAfter` 是上述判据的明示例外。** 它可由 `AppliedChange` 全序列重放得出，按判据本不该存；但它**已在 `EventResolved` 负载里**（`LifeSpanRemaining`），且元进程的角色履历要画寿元曲线。**成本 4 字节 × 200 条 = 800 字节，换掉一次全序列重放。** 它是**写明的例外，不是先例**——不得据此放宽判据。
- **`Aborted` 是跳过通道移除后的直接产物。** 支付 `selectCost` 后立即判负会短路、事件不再结算，但**这一步仍然发生过**（成本已施加、`selectCost` 不回滚），必须留痕且必须与正常结算可区分——否则履历上会出现一条「结算了但什么也没产出」的诡异记录。它通常是角色的**最后一条**痕迹。
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
- **写入点不新增。** 上方结算流程里「记入 `pastEvent`」这一步的语义具体化为：**由 life-cycle-service 组装 `PastEventEntry`（含从被替换的当前批取未选项摘要），经 `profile-service.ProfileManager` 写入**——与「档案写入的唯一入口」一致，不绕过。


### 通用流程

- **呈现 = 月圆之夜风格。** 修行事件以精心策划的**事件菜单**形态呈现，参考《月圆之夜》。
- **选择 = 横向滑动选择区。** 「从可用修行事件（eventOptions）中选择」用一个**可横向滑动的选择区**（horizontal scrolling area），滑动选中目标 AdventureEvent。详见 `systems/game-progression.md`。
- **进入。** 玩家在选择区选中一个可用 AdventureEvent 后进入该事件；Explore 在进入时揭示其被遮罩的固定事件。Source: `terminology.md`。
- **结算与后果。** 事件结束后其后果影响玩家及未来状态（隐藏属性推拉、eventOptions 重算、location 刷新等）；结算规则因子类型而异——**仅 Combat 走战斗结算**（三个 `combatTier` 档共用同一回合循环与参战方结构，差异在遭遇参数），其余四类为事件式结算，Explore 视其真身而定。
- **自动存档边界。** 事件为合理的自动存档点之一（每场遭遇战 / 地图节点之后）。Source: `state-save-rules.md`。

Source: `handoffs/2026-07-22-online-cloud-combat-and-meta-clarifications.md` · `handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md` · `handoffs/2026-07-24-docs-restructure-class-model.md` · `handoffs/2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md` · `handoffs/2026-07-25b-event-cost-fields-capability-flags-and-service-hierarchy.md` · `handoffs/2026-07-26-event-priority-skip-semantics-and-hotfix-scope.md` · `handoffs/2026-07-27b-service-api-contracts.md` · `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md` · `handoffs/2026-08-06c-skip-channel-removal-priority-two-tier-and-location-codex-edges.md` · `handoffs/2026-08-09c-past-event-trace-schema.md` · `handoffs/2026-08-10c-ability-disable-replacement-and-player-statistics.md` · `handoffs/2026-08-15c-event-type-collapse-and-batch-shape.md` · `handoffs/2026-08-15d-intent-removal-lifespan-cost-visibility-and-design-audit.md`

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- **呈现形态、选择交互** 见「意图」及 `decisions/ADR-0002-adventure-event-taxonomy.md` 上下文。
- **`pastEvent` 痕迹 schema（`PastEventEntry` + 判据 + 未选项轻摘要）** 见「意图」的同名小节。**ADR 候选**（它同时约束存档 schema、同步粒度与剧本读取面）。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **`EventOption` 的完整物化字段清单未定：** 骨架**七字段**已定（见 `future-event-service.md`）；但「**多数**属性由物化决定」意味着还有一批未列出的字段——哪些数值可被情境改写？outcome 权重是否在物化时固化？需要一次**内容侧** handoff。**「风味文案是否也物化」这一半已答结：不物化，跟随模板数据** ⇒ **剩余分叉只在数值与结构字段上，不含任何文本类字段**。
- **可用事件的生成规则：** **数量**（常态 3、区间 1–5）、**重算依据**（角色整体历程，重度依赖 `pastEvent`，不承接上一批）；仍待定：**类型配比**的运算形态、location + AdventurePlot 的叠加顺序、以及**区间两端由什么驱动**（何时收到 1、何时放到 5——location？篇章？剧本？隐藏属性？）。→ 亦见 `systems/game-progression.md`、`systems/services/future-event-service.md`。
- **`lifeSpanCost` 的数据形态。** **element 清单已答结**（成本侧只有 `lifeSpanCost` 一项）、**定价归属已答结**（类型 × 篇章统一定价表 + 条目级覆盖）；仍待定：该 element 是固定值还是可带区间 / 公式（若带区间，它就落进「`EventOption` 完整物化字段清单」那一问）。→ `systems/balance.md`。
- **哪些资源允许被打穿、各自的截断与终态判据（承重）：** `selectCost` 无条件施加后必须回答——寿元归 0 = `defeated` 已定；**灵玉 / mana / 其余 element 打到负数怎么办**（截断到 0？允许为负？）、哪些资源的耗尽构成终态、哪些只是变穷。这直接决定 `ProfileManager.TryApply` 施加负值时的钳制规则。→ `systems/services/profile-service.md`、`systems/character-profile/currency.md`。
- **`Priority` 字段是否从 `int` 退化为 `bool`（轻）：** 语义已定为两档；保留 `int` 是留扩展余地，改 `bool` 是让类型说实话。
- **`lifeSpanCost` 定价表的具体取值：** 表的**形态**已定（「事件类型 × 篇章」统一定价表，内容条目只标偏移 / 覆盖值；目标时长驱动、逐篇章上调、闭关更耗）；仍待定**每格填多少**——需以 30–40 / 35–45 / 45–55 分钟反推。→ `systems/balance.md`。
- **「余额不足即拒」还剩哪些消费点：** 事件推进路径不需要它，且成本侧现已只剩寿元一项；**只剩 Exchange 内的商店购买这一个可能的消费点**。若它也不需要，`AdvanceResult.CostRejected` / `MissingElement` / `CanAfford` 可整体删除。→ `systems/adventure-event/exchange/_index.md`、`systems/services/profile-service.md`。

Source: `handoffs/2026-07-25b-event-cost-fields-capability-flags-and-service-hierarchy.md` · `handoffs/2026-07-27b-service-api-contracts.md` · `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md` · `handoffs/2026-08-06c-skip-channel-removal-priority-two-tier-and-location-codex-edges.md` · `handoffs/2026-08-09c-past-event-trace-schema.md` · `handoffs/2026-08-15c-event-type-collapse-and-batch-shape.md`

## 对应
提炼至：`.claude/knowledge/systems/adventure-event/common-properties.md`（待建）
