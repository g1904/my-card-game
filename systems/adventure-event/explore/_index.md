# adventure-event / explore（AdventureEvent-Explore）

> **元类型「探索秘境」**：遮罩一个**固定的** Combat / Travel / Exchange 事件，进入后才揭示。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **探索秘境（Explore）= 元类型（meta-type）。** Explore 本身不是一种独立玩法，而是**遮罩另一个 AdventureEvent**；玩家在批次里选中一个 Explore，等于「选了一个未知」，进入后才揭示其真实类型与内容。语义上「探索一处秘境」——秘境里有什么，进去才知道。
- **遮罩的是一个固定的 AdventureEvent。** Explore 揭示的是一个**预先确定的、固定的**事件，而**非在点击时临时生成**——遮罩层只隐藏类型与内容，被遮罩的具体事件在该 Explore 内容条目上已固定指定。**推论：既有的 `IsRevealed` / `RevealedEventId` 两个物化字段与 `PastEventEntry.RevealedEventId` 原样沿用，不新增机制。**
- **可被遮罩的真身取值域 = Combat / Travel / Exchange。**
  - **不含 Research**——卡组编辑是玩家主动规划的动作，把它藏在未知后面只制造挫败，不制造张力。
  - **不含 Explore 自身**（不嵌套）——元类型定义使然。
  - **Travel 可被遮罩，但揭示出的 Travel 必走随机那一档**：只给一个 seeded 随机邻接地域，玩家无从选择去哪（见 `../travel/_index.md` 的 80 / 20 掷定）。这与「秘境把人带到别处」的叙事同向。
- **一次选择仍只结算一个事件。** Explore 不是嵌套的二级菜单——进入即揭示即结算，`pastEvent` 上仍是**一条**痕迹（`EventType` 记当时呈现给玩家的 Explore，`RevealedEventId` 记真身）。
- **只存在一份 `selectCost`：Explore 壳自己的那一份（承重）。** 支付先于揭示——`TryApply(SelectCost)` 排在 `eventStart` 阶段的揭示**之前**，被施加的必然是 Explore 模板物化出的 `EventOption.SelectCost`，**真身模板的成本字段从头到尾不在链路上**；`PastEventEntry` 上也只有一份 `SelectCost`。因此「Band 2 该展示哪一份成本」不是二选一：如实展示唯一存在的那一份即可，展示侧没有泄漏面。
  - **物化纪律（可机械检查）：** 物化一个 Explore `EventOption` 时，`SelectCost` 一律取 Explore 模板 + 定价表的 **Explore 行**，**不读真身模板的任何成本字段**。物化组装后加一条断言，与「`SelectCost.AbilityElements` 恒空」同一处、同一档（`PushError`）。
  - **真身模板的成本字段不是死字段。** 同一个 Combat / Travel / Exchange 条目**也可能作为普通选项直接出现**在同批 eventOptions 里，那时它自己的 `selectCost` 照常施加。「被遮罩时不读」是 Explore 这条路径的局部规则，不是对该字段的全局否定。
- **泄漏面在定价侧，由两条纪律封死。**
  - **Explore 在 `lifeSpanCost` 定价表上自成一行，该行不得由真身推导。** 若成本取自真身（「遮罩什么就收什么价」），Band 2 的精确展示会让玩家**用成本数值反推真身类型**——Combat / Travel / Exchange 三行定价不同即构成指纹。
  - **Explore 条目禁用条目级成本覆盖值。** `lifeSpanCost` 一律取定价表的 Explore 行，内容条目**不得**标偏移 / 覆盖值——作者写出的差异化成本本身就是第二种指纹（玩家会记住「这个秘境花 4 点的总是打架」），会把上一条封死的泄漏面从另一侧重新捅开。落地为**内容模板加载期校验**，违规条目 `PushError` + `Id`。
    - **代价（明写接受）：** Explore 作者失去一个风味旋钮，无法用成本表达「这个秘境格外凶险」——那类表达改由文案与美术承载。要求「同一 location / 篇章内取值齐平」的折中效果等价，但**无法机械检查**、只能靠作者自律，而本库对内容侧的收口方式是「能加载期校验的就不留自律」。
    - **这是 Explore 独有的例外，不是对定价表通则的收紧。** 其余四类照常「不填即取类型基准，需要时标偏移 / 覆盖」。
  - **Band 0 / Band 1 本就完全不显示 `selectCost`**，故上述两条只在 Band 2 承重；但校验一律生效，不随 Band 开关。
- **泄漏面还有字段侧的一条：`RevealedEventId` 与 `DestinationLocationId` 同属揭示前不得进入呈现层的字段（承重）。** 两者**都在物化时掷定并落在壳实例上**（目的地必为随机那一档，见 `../travel/_index.md` 的 80 / 20 掷定）——这是既有防重掷纪律的要求：候选须预先算定并落决策点存档，否则玩家退出重进即可刷一个更合意的真身 / 地域。**落在实例上不等于可呈现**：ViewModel 在 `IsRevealed == false` 时**这两个字段一个都不读**。两者写在同一条里而非分列两条，因为它们是同一条纪律的两个实例——分开写迟早会有人只守其中一条。
  - **同一条纪律在呈现侧的完整形态：遮罩态卡面只取 Explore 模板自己的**显示名 / 描述 / 风味文案 / 图标。真身的任何一个字段泄漏到卡面上，都会成为定价侧两条纪律之外的又一种指纹。呈现细节（卡片与其余 eventOption 完全同构、揭示转场层）见 `ux/screen-flow.md`。
  - **遮罩态不标注敌人等级。** 「战斗类事件在物化时精确标注敌人等级」按**呈现给玩家的类型**成立，而遮罩态呈现的是 Explore，无等级可标；揭示后的战斗前展示照常精确标注。

### 真身类型的分布

- **真身类型分布 = Explore 条目池的组成 × 既有的加权抽取，不设第二套权重机制（承重）。** 遮罩的是一个固定条目 ⇒ 运行时**没有任何一个时刻可以掷这个权重**：揭示阶段读的是模板上写死的 `RevealedEventId`，不掷骰。玩家观察到的「秘境里有多大概率是一场架」= ∑（被抽中的 Explore 条目权重）按其真身 `eventType` 分组的自然结果。
  - **三处数据类一律不加字段：** `AdventureEventData` 上不加 Explore 权重字段 · `LocationData` 上不加 Explore 子权重行 · `PlotModulation` 不加第七个字段。三处都是「加一个字段就要回答谁有权改它」的口子，本库对这类口子的收口方式是不给（对位 `TravelFullFanoutChance` 与「赋级函数不接受区间覆盖参数」）。
  - **三档调制能力因此不对称，且这是可接受的：**

    | 调制源 | 能表达 | 不能表达 | 判定 |
    |---|---|---|---|
    | **location** | 「洞天多秘境」（`eventType` 修正表的 Explore 一行） | 「洞天的秘境多半是战斗」 | **接受**——location 的软框定本就是类型级粒度，为它开条目级粒度等于把第二套 `EventWeights` 塞进 `LocationData` |
    | **AdventurePlot** | 「这条线上多出指向 Combat 真身的秘境」（`PlotModulation.EventWeights` 对单条 Explore 条目加权） | —— | **既有能力，零改动**；与「迷途 = 让候选池多出 Explore 条目」是同一条用法 |
    | **篇章** | 由该篇章可用的 Explore 条目池自然给出 | —— | 不设专门旋钮 |

  - **剧本对真身分布的调制是间接的，而这恰好合规。** 它靠「挑哪些 Explore 条目加权」实现，落在**内容面**（PlotManager 的合法权力），而非**约束面**。若另设一个「真身类型权重」字段，剧本一旦能改它，就等于隔着遮罩改变玩家实际面对的事件类型分布而玩家全程无感——与否决「剧本推拉 80/20」是同一条理由。
- **占比只在内容编排口径上被控制，不是运行时约束。初值 `Combat : Exchange : Travel ≈ 5 : 3 : 2`**（待 ch1 数值标杆实测校准）。
  - **Combat 过半**——Explore 的张力来源是「可能是一场架」；战斗占比过低，秘境退化为「随机小惊喜」，元类型的风险语义消失，而 Combat 本就是最高频的一类。
  - **Travel 压最低档**——揭示出的 Travel 会强制换图并把该地域计数归 0，频率一高就打乱「一次篇章 = 若干 location 串联」的地域节奏，且玩家无从选择目的地（必走随机档），连续几次会读成「系统在踢我走」。
  - **Exchange 居中作为正向面**——三类都必须有非零占比，否则「未知」在几次之后就不再未知；Exchange 是唯一纯正向的那一类，它让秘境不是纯粹的风险赌注。与 `Standard` / `Minor` 的经验档位偏置自洽：秘境是中等产出，不该被编排成战斗浓度更高的伪 Combat。
  - **口径是「条目池加权后的期望占比」：** 不做配额保证、不做「连续 N 次未出 Exchange 则保底」——保底是一套新机制，且它把「未知」变成可推算的。
  - **取池期过滤会轻微偏移实际占比**（被关闭的真身、库存池不足的 Exchange 真身，其壳都被移出候选池），**不为此设任何补偿**——占比本就是期望值而非配额。方向也是正确的：一个此刻产不出内容的事件，不该靠遮罩偷渡上场。
  - 落点：`adventure-event` 内容类型开张时，其类型档案的 Explore 分区台账登记每条的真身 `Id` 与真身 `eventType`；`/audit-content` 汇总三类占比与目标区间比对，**只报告不阻断**（它是编排口径，不是校验）。

### 取池与校验

- **取池期附加一条过滤，两个分支同形同档（承重）：真身被 `ContentEnabled == false` 关闭，**或**真身是 Exchange 且其库存池前置不通过 ⇒ 该 Explore 壳本次不进候选池。** 判定发生在 future-event-service 的取池阶段，与 `AllEnabled()` 同一档。
  - **第二个分支拦的是同一形状的第二个洞：** Exchange 是可被遮罩的三类真身之一，而它的库存池会在运行期收缩（flags 秒关、能力族取池链排除已持有）。壳自己是 enabled 的、真身也是 enabled 的，于是玩家照常付掉壳的 `lifeSpanCost`、揭示之后撞上一个**空商店**——**失败点落在付费之后**，且直接违反「两处都不能留空面板」。判据与 `ContentEnabled` 那条一字不差地成立，故不单列为一种新机制。前置的计数口径与三道闸的层次见 `systems/services/future-event-service.md`。
  - **Research 不在真身取值域内**，故构筑面板那一侧无需穿透。
  - **不加这条就有一个能上线、线上不可见的洞：** 线上用 flags 关掉一个坏掉的 Combat 条目后，指向它的 Explore 壳仍在 `AllEnabled()` 池里（壳自己是 enabled 的），玩家照常选中、照常付费，揭示后落到那个被关闭的条目上（读取侧不过滤，能解析、不崩）——**放量开关对这条路径静默失效**。
  - **它是抽取侧过滤，不违反「读取侧不过滤」纪律**：过滤只决定「这次能不能抽到它」；`pastEvent` 回溯与图鉴解析照常解析 disabled 条目，历史痕迹不受影响。
  - **代价明写接受：** 关掉一个 Combat 条目会连带压低 Explore 的实际出场率（壳被排除）。这是正确的方向——一个被判定为坏掉的事件，不该靠遮罩偷渡上场。**否决的替代是「揭示后降级为空结算」**：玩家已付费却什么也没发生是最坏的观感，且会在 `pastEvent` 上留下一条「结算了但什么也没产出」的诡异记录。
  - **真身的启用态不进 `EventOption` 快照**（它随 flags 变，重算不保证同结果且无消费方），只在取池那一刻查一次。
- **内容模板加载期的四条校验合为一段**（违规一律 `PushError` + 条目 `Id`）：

  | # | 校验 | 失败语义 |
  |---|---|---|
  | 1 | `RevealedEventId` 非空且经 `ContentRegistry` 解析得到 | 必需缺失 → `PushError` + `Id` + 悬空目标 `Id` |
  | 2 | 真身的 `eventType ∈ { Combat, Travel, Exchange }` | 同上（`Research` 与 `Explore` 均在此被拦） |
  | 3 | 真身不是另一个 Explore（不嵌套） | 由 #2 蕴含，**仍单列一条以给出可读的报错**——「不嵌套」是元类型定义，值得一条自己的消息 |
  | 4 | Explore 条目不得标 `lifeSpanCost` 的条目级偏移 / 覆盖值 | 同上（见上方定价侧纪律） |

  四条与**物化组装后**那两条断言（`SelectCost` 不读真身任何成本字段 · `SelectCost.AbilityElements` 恒空）共享同一个 Explore 校验段，避免散落。

- **壳的 `OutcomeSpec` 由真身模板物化：「成本取壳、产出取真身」是一条有意的不对称（承重）。** 物化一个 Explore `EventOption` 时，`OutcomeSpec`（以及 `AbilityChangeSlots`）一律取 `RevealedEventId` 指向的**真身模板**的产出格展开，而 `SelectCost` 一律取 Explore 壳自己的那一份。**物化组装后加一条断言，与上述两条同处、同档（`PushError`）。**
  - **成本侧取壳的唯一理由是防泄漏**——Band 2 精确展示会让成本数值成为真身类型的指纹。**产出在揭示前从不展示**（遮罩态卡面只取 Explore 模板自己的显示名 / 描述 / 风味文案 / 图标），该理由在产出侧整条不成立。
  - **产出侧的理由是防重掷，且已由 `Encounter` / `DestinationLocationId` 立过先例**：抽取型产出若等到揭示那一刻才掷，玩家退出重进即可重刷一件更合意的产出。
  - **取壳的后果是同一份数据两种行为**：一个「秘境里的商店」除了买卖之外拿不到真身条目写好的任何 outcome，真身模板的产出格在被遮罩时整条失效——而同一条目作为普通选项出现时它是生效的。
  - **必须把这条不对称写明**，否则后来者读到两条相反的处置会去「统一」其中一条，而统一到哪一侧都造成实际损坏（统一取壳 ⇒ 真身产出整条失效；统一取真身 ⇒ 成本数值成为指纹）。
  - **附带收益：** 「`eventType == Travel` 的条目 outcome 侧不得含 `LifeSpan` 产出」这条结构性禁令在遮罩路径上自动覆盖——被遮罩的真身本身就是 Travel 条目，模板侧校验与物化侧断言照常命中。取壳的话该禁令在这条路径上会失效。

### 揭示的结算形态

- **揭示 = `eventStart` 阶段内的一次 `with` 派生，不改写当前批。**

  ```
  【eventStart 阶段】
    revealed = option with { IsRevealed = true }      ← 派生实例，当前批里那份原实例不动
    TryApply( EventStateChanges[ActiveEvent = revealed] )   ← 整体置值；本地立即原子写
    resolver = 按 revealed 的真身 eventType 选取       ← 真身是 Combat → CombatEventResolver，否则 GenericEventResolver
    resolver.ResolveAsync(revealed, ct)
  ```

  - **resolver 的选取判据是真身，不是 `EventOption.EventType`。** `EventType` 恒为 `Explore`，照它选会把一个战斗真身送进 `GenericEventResolver`。这是既有「两个 resolver 的拆分轴是有没有状态机、不是有几个类型」的直接落地，也与 `Source` 的「按谁组装出这条 element 判」是同一条判据的镜像（Explore 揭示出战斗真身时战利品出自 combat-service）。
  - **`IsRevealed` 因此是本次结算内的瞬态标志，痕迹侧无消费方**（`PastEventEntry` 靠恒存的 `RevealedEventId` 即可回溯）。**字段保留**：派生后的那一份落 `CharacterProfile.activeEvent`，退出重进后呈现层读它判断「这一步已经揭示过了」——`IsRevealed == true` ⇒ 直接呈现真身，不再播揭示转场。承载与读档校验见 `systems/character-profile/_index.md`。
  - **揭示不新增决策点、不新增存档点类型，但本地写照常发生。** 判据链：`ct` **只在决策点被观察** ⇒ 揭示与随后进入的第一个决策点之间**不存在可退出窗口**；而三种真身各自的第一个可退出点都是既有的（Combat 真身 → 「进入战斗前」那个 `Immediate` flush 点 · Exchange 真身 → 商店面板的事件内决策点 · Travel 真身 → 无玩家输入，直接走到收口）。**新增一个揭示专属存档点换到的只是「强杀后不重播一次转场动画」**——强杀那一路本就回落到最近决策点，重进后重看一次揭示**只重看**、不改真身（`RevealedEventId` 在物化时就已定）。
  - **Explore 自身零决策点；揭示后按真身接入该类的决策点清单**（Combat 真身 → D0–D6 · Exchange 真身 → X1–X3 · Travel 真身 → 无）。逐类清单见 `systems/services/life-cycle-service.md`。**推论：真身为 Travel 时该事件整条不可取消**——壳没有观察位、Travel 也没有。
- **不给部分线索（危险度提示 / 类型图标暗示）（承重）。** 定价侧已用两条纪律封死「用成本数值反推真身」、展示侧本已无泄漏面，而**一个机械的危险度档位 / 类型图标等价于把真身类型直接印在卡上**——三类真身的危险度分布是可学习的（Combat 高、Exchange 低），玩过十次的玩家会把「危险度」直接读成「是不是架」，Explore 随之退化为一个换皮的 Combat 标签，元类型的全部价值消失。二值的「凶险 / 平和」标同样是可学习的映射，只是分辨率低一档。
  - 「这个秘境格外凶险」的表达位**已经让渡给文案与美术**（见上方放弃条目级成本旋钮那条）；给一个机械线索档就是把那个旋钮从另一侧拿回来。
  - **风味文案允许暗示气氛，但不得建立可学习的映射**——「洞口渗出血腥气」这类写法只要不与真身类型形成一一对应就无害。这**无法机械检查**，属作者自律，写进类型档案的作者须知。

### 明写接受的一处代价

**「战斗类事件在物化时精确展示敌人等级，让越级挑战成为可主动选择的风险 / 回报」在 Explore 路径上失效。** 玩家选中一个秘境时无法知道里面是不是一场架，更无从比对等级。

- **这不是缺陷，正是 Explore 的定价**——元类型出售的就是「不知道」。若为它补一条「秘境内的战斗不得越级」之类的保护，等于用规则把风险抹平，Explore 随之失去存在理由；且它会成为 `±2` 带那条**无例外硬规则**的一个例外，而该规则明写不接受例外。
- **风险的界仍由 `±2` 带给出**（赋级规则挂在 Enemy 上、`combatTier` 三档一视同仁），已经足够：秘境里的战斗不会比常规战斗更超纲，只是玩家事前不知道有没有。它与「打不过也得打是正常出口」自洽——产出侧本就不欠可战胜保证。

Source: `handoffs/2026-07-24-docs-restructure-class-model.md` · `handoffs/2026-08-15c-event-type-collapse-and-batch-shape.md` · `handoffs/2026-08-16d-cost-side-closure.md` · `handoffs/2026-08-17-travel-destination-and-status-change-elements.md` · `handoffs/2026-08-17c-explore-reveal-mechanics.md` · `handoffs/2026-08-17j-event-option-derived-persistence.md` · `handoffs/2026-08-19-pickmany-shortfall-handling.md` · `handoffs/2026-08-22-event-outcome-spec-fields.md` · `handoffs/2026-08-22-non-combat-decision-points.md`

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- **Explore 为五类分类法之一，且是唯一的元类型** → `decisions/ADR-0002-adventure-event-taxonomy.md`。
- **遮罩一个固定 AdventureEvent（非点击时生成）；真身取值域 = Combat / Travel / Exchange**。
- **遮罩下只存在 Explore 壳一份 `selectCost`；Explore 自成定价行且禁用条目级成本覆盖**。
- **真身类型分布不设第二套权重机制**（三处数据类均不加字段）；**取池期附加一条壳过滤（真身须同样 enabled，且真身为 Exchange 时其库存池前置须通过）**；**不给任何部分线索**。
- **揭示后的派生实例落 `CharacterProfile.activeEvent`，随后续第一个决策点写盘，不新增揭示专属存档点。**

Source: `handoffs/2026-08-15c-event-type-collapse-and-batch-shape.md` · `handoffs/2026-08-17c-explore-reveal-mechanics.md`

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **两个待实测初值。** 真身占比 `5 : 3 : 2` 归 ch1 数值标杆专场回归校准；揭示转场时长 ≈ 1.2s 是纯手感项，只能在真机上调。形态均已定，只欠取值。→ `systems/balance.md`、`ux/screen-flow.md`。
- **定价表 Explore 行的取值。** Explore 自成一行、不由真身推导已定；**填多少**待 ch1 数值标杆专场。→ `systems/balance.md`。

## 对应
提炼至：`.claude/knowledge/systems/adventure-event/explore.md`（待建）
