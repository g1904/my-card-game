# game-progression

> 每个 ante 的进程推进、location（地域）、Travel 路由、节点类型路径导航、月圆之夜式菜单、横向滑动选择、篇章 / 境界推进、blind / ante 缩放。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

### 轮回结构与篇章 / 境界推进
- 一次轮回的结构为 **realm → chapter → AdventureEvent**。修炼阶梯（炼气 / Qi Refining → 筑基 / Foundation Establishment → 金丹 / Golden Core → 元婴 / Nascent Soul）共四个 realm；一次轮回为**三个 chapter**，每个 chapter 是相邻两个 realm 之间的攀登。
- 在一个 chapter 内，进程由 **eventOptions 循环**驱动：future-event-service 依当前 characterProfile 产出一批可选的 AdventureEvent（eventOptions），玩家**从中选择一个**来推进；每个 AdventureEvent 触发事件、改变玩家状态，随后 future-event-service **重算下一批 eventOptions**。见 `systems/services/future-event-service.md`。
- **各 chapter 相互衔接。** 第 N+1 个 chapter 从第 N 个 chapter 的某个*可用结束点*开始——因此完成状态会分支，并为下一个 chapter 的起点埋下种子。
- 每个 chapter 边界都是角色档案上的一个**存档 / 记录点**（共三个）；抵达元婴即为最终奖杯展示。
- **篇章收口 = 一次性的 Finale，胜负即推进闸门（承重）。** **每个篇章只有一个 Finale**——通过则篇章推进、境界突破并落存档点；**失败则角色当场终结、本篇章不推进**。
  - **失败后不可在同一篇章内再次挑战。** 想再渡一次这一劫，**唯一出路是重走整个篇章**（篇章重试，上限 ∞ / 3 / 1，付费 ∞ / 9 / 3）。
  - **推论：完成篇章数恒等于 Finale 通过次数**——两者之间没有第三条路径。
  - 完整语义见 `systems/adventure-event/combat/_index.md`。
- **篇章总数 = 四境三篇章。** 重试上限：第一章（炼气→筑基）无限、第二章（筑基→金丹）3、第三章（金丹→元婴）1。（重试 / 存档 / 篇章继承的完整生命周期语义归 `systems/services/life-cycle-service.md`。）
- **篇章继承 = 全部继承。** 读档续入下一 chapter 时，角色带入**上一篇章的全部信息**（deck、法宝、属性、叙事标记等），无逐项筛选。
- **每个篇章 = 一个移动端时段，时长由 `lifeSpanCost` 定价控制。** 目标时长（**熟练玩家口径**，新手更长）：第一篇章 **30–40 分钟**、第二篇章 **35–45 分钟**、第三篇章 **45–55 分钟**。**寿元预算增量是叙事阶梯的形式量，事件定价才是时长旋钮**；第三篇章预算 +300 远多于前两章，靠**上调 `lifeSpanCost`** 把时长压回区间。**剩余寿元跨篇章结转**（下一篇章预算 = 该章增量 + 上一章剩余），故「省着花」有跨篇章回报，寿元是贯穿整个轮回的一条资源线。分档表归 `systems/balance.md`。**推论：时段被拉长到接近一小时**，故中途存档续玩比先前更承重（已由决策点存档覆盖）。

### 修行等级体系（realm + level）

- **等级 = 境界内的层级。** 角色的修行位置由**境界（realm）+ 境界内等级（level）**合成：

  | 境界 | 层级 | 数量 | 篇章跨度 |
  |------|------|------|----------|
  | 炼气 Qi Refining | 1 层 ~ 13 层 | 13 | 第一篇章 1→13 |
  | 筑基 Foundation Establishment | 初期 / 中期 / 后期 / 巅峰 | 4 | 第二篇章 1→4 |
  | 金丹 Golden Core | 初期 / 中期 / 后期 / 巅峰 | 4 | 第三篇章 1→4 |
  | 元婴 Nascent Soul | 初期 | 1 | 终点 |
- **进阶即归位初期。** 每个篇章结束、突破进入下一境界后，等级一律重置为**新境界的初期（level 1）——元婴亦然**（元婴只有初期，且是游戏终点）。
- **一切等级比较建立在全局等级序上。** 「谁比谁高几级」的判据（首先是敌人赋级的 `±2` 带与 `baseMomentum` 起跑线）一律在**跨境界连续的全局序**上做，**不拿两个境界内的层号直接相减**——否则「筑基中期(2) vs 金丹初期(1)」会得出敌人更低的荒谬结论。全局序 = 境界基数 + 境界内层级：

  ```
  炼气 1层..13层  →  全局 1..13
  筑基 初期..巅峰 →  全局 14..17
  金丹 初期..巅峰 →  全局 18..21
  元婴 初期       →  全局 22
  ```

  **境界之间不留跳变：** 全局序就是连续的 1–22，枚举值自带描述（`level=1` → 炼气一层，`level=14` → 筑基初期，…）。**境界鸿沟改由 `baseMomentum` 承载**——每个等级对应一个战斗起始道念，筑基以上每级跨度持续放大（表见 `systems/balance.md`）。这条分工让等级序保持为一把简单的直尺，而把「跨境界有多难」放进战斗数值里。
- **等级成长 = 事件产出经验值。** 境界内等级由 **AdventureEvent 的 reward 给予**，但**给的是经验值而非等级本身**：
  - **`experiencePoint`（经验值）是 CharacterProfile 上的一个字段。** **每个等级各有一个升级所需的经验阈值**；事件奖励**发放经验值**，累积达到阈值才升一级。**推论：事件不直接给等级**——中间隔一层累积量，产出因此可以做得**细碎而连续**（一次事件给几点经验），而不必每次都是一次跳级。**阈值曲线与给予量**，见下与 `systems/balance.md`。
  - **不只绑定战斗** —— 任何类型的修行事件都可能给经验产出（闭关、探索、交易皆可）。
  - **不只有胜利才给** —— **失败同样可能有经验产出**（挫折亦是修行）。这与「失败侧应有产出」的取向一致（见 `systems/player-profile/codex/`、`player-power/`）。**推论：经验值让「失败给的比胜利少」有了自然的表达**——同一个量的不同数值，不需要「给不给等级」这种全有全无的判断。
  - 它与 `manaLimit` 同属一套「由事件 cost / reward 推拉」的成长体系，走同一条 `ProfileChangeSpec` → `TryApply` 链路（见 `systems/services/life-cycle-service.md`）。**经验值是战斗奖励中「强制自动计入」的那一类**（见 `systems/services/combat-service.md`）。
  - **阈值曲线 = 境界内递增 + 境界间重置量纲。** **重置的理由不是美观，而是「进阶即归位初期」**：等级在境界边界被重置，若经验阈值仍连续累加就出现「等级归零、阈值不归零」的语义割裂。**跨境界的难度阶梯已由 `baseMomentum` 跨度独占承载**（既定分工：等级序是一把简单直尺，跨境界有多难放进战斗数值里），**经验侧不叠第二条跨境界曲线**。具体阈值与给予量见 `systems/balance.md`。
  - **产出分档 = `ExperienceGrade { None / Minor / Standard / Major }` 枚举 + 平衡表映射**，`AdventureEventData` 上**不落裸数字**。**阈值与给予量同比放大**（ch1 标准产出 4 / ch2 12 / ch3 16），与 `baseMomentum` 跨境界放大的数值语言同构。
  - **带经验的产出点约占事件总数 75%（初值）。** 全覆盖会让经验变成「时间的自动函数」、事件选择在成长维度上失去差异；覆盖率过低（< 50%）则玩家为了升级只挑带经验的事件，压扁事件池多样性。**75% 让「大多数路都在前进、但选得好前进得快」两件事同时成立。**
  - **档位偏置 = 「产出对位成本」的一致化（内容编排口径）**：Combat `Standard` 档胜利 `Major` · `Practice` 档胜利 `Standard`（低风险 ⇒ 产出对位低一档）· **`Finale` 档 `None` / `Minor`**（见下）· Research 闭关 `Major`（`lifeSpanCost` 最高）· Explore `Standard` / `Minor` · Exchange `None`（社交风味条目可给 `Minor`）。
    - **它与 location 的事件类型概率修正自然咬合**：荒野多 Combat = 经验更密但风险更高，坊市多 Exchange = 经验稀疏但资源丰——**地域由此自带成长节奏的风味，不需要为 location 再加一个经验修正字段**（与「敌人物化两条轴正交」同款克制）。
  - **失败产出 = 一条 reward 两个字段，不是两套内容**：`ExperienceGrade`（成功档位）+ `FailureRatio`（**百分比整数，默认 50**，逐条可覆写，留给「这场输了才真正学到东西」的特例）。折算在 `ProfileChangeSpec` 组装时完成（**向下取整、下限 1**，见 `systems/balance.md`），`TryApply` 收到的已是最终整数。**取百分比整数而非 `float`**：`AppliedChange` 要求可重放，整数百分比 + `floor` 是可复算的，浮点在跨平台重放上不是。字段面见 `systems/adventure-event/common-properties.md`。**50% 而非更低**：失败已经付了 `lifeTotal` 的硬代价（归 0 即角色终结），靠反复失败刷经验天然不是优势路线。
  - **承重推论：经验的目标点不是「篇章结束」，而是「Finale 之前」。** 「天劫的 `diff` 恰为 +1」这条自洽性验证隐含一条硬约束——**角色必须在进入 Finale 之前就已升满本境界**，否则 `±2` 带会给出一个更低的天劫等级，「渡劫 = 突破到下一境界」的叙事随之破裂。**推论 ①：全部升级所需经验必须由篇章的常规事件段供满**，Finale 本身不承担经验供给。**推论 ②：Finale 的出现条件 = 角色已达本境界巅峰**——不需要新机制，`eventPriority = 1` 已能表达（与 `eventCountLimit` 达成后 Travel 封锁同批的用法同构）。
  - **供给 / 需求 ≈ 1.15–1.20；满级后经验直接丢弃**（不结转、不开兑换通道，与「进阶即归位初期」同向）。**卡级的实际后果 = 寿元耗尽而等级未满 → `defeated`**，这是**有意保留的失败面**，但要求 `lifeSpanCost` 与 `eventCountLimit` 的反推**必须验证「按标准路线走能在预算内升满」**——这是把经验曲线绑进时长旋钮反推的一条验收项。
  - **承重推论：ch2 / ch3 的升级稀疏是一个必须补偿的节奏缺口。** ch1 每 2 个事件升一级，ch2 / ch3 每 9–11 个事件才升一级——**中段会出现连续十几分钟毫无等级反馈**，这直接撞上「中长期规划感的来源」那条长期待答。**补偿 = 经验进度条常驻于 EventOption 选择界面的角色状态条**（`当前 / 本级阈值`）：玩家读到「还差 12 点到筑基中期」就有了跨越十来个事件的中期目标。它在 ch1 是锦上添花，**在 ch2 / ch3 是唯一的连续进度感来源**。与寿元隐藏纪律不冲突——**经验从未被定为隐藏属性**。配套：**eventOption 卡片不标注该事件的经验产出档位**（保留探索感，与「给方向不给数字」一致）。见 `ux/screen-flow.md`。
  - **已知风险**：反推链是脆的（事件总数一变，整条阈值曲线失效）——**缓解是把「供给 / 需求比」做成一份可算的校验表**，每次调时长旋钮时重算，而不是死记数字；ch1 的 12 次升级可能让升级感变廉价（若实测如此，收口方向是**提高 ch1 阈值 + 降低覆盖率**，**不动炼气 13 层**）；**溢出即弃**会让后半章的经验奖励对已满级玩家毫无价值 → 缓解为满级后 UI 标注「已圆满」，并保证带经验的事件同时带其他产出（**不做纯经验事件**）。（阈值曲线 / 分档 / 分布 / Finale 前满级 / 经验条常驻）。

### 进程形态与节点呈现
- **eventOptions 的服务化生成。** 「从当前可用的 AdventureEvent 中选择」由 **future-event-service** 依当前 characterProfile 产出一批 `List<EventOption> eventOptions`（见 `systems/services/future-event-service.md`）。**进程是逐批择一的线性推进，不是可俯瞰的分支地图**：事件之间没有预先连好的边，每一步的可选集都是当场算出来的；CharacterProfile 向后以 `pastEvent` 持有已走过的历程轨迹。
- **节点形态 = 月圆之夜风格。** 节点 / 修行事件的呈现**参考《月圆之夜》**——精心策划的事件菜单，而非 StS 式完全分支地图。
- **选择界面 = 横向滑动选择区。** eventOptions 通过一个**可横向滑动的选择区**（horizontal scrolling area）呈现，玩家滑动以选中要继续的目标 AdventureEvent。契合月圆之夜风格的「事件菜单」形态，且贴合竖屏触控。
- **AdventurePlot 调制 eventOptions（方向）。** 隐藏抽象 **AdventurePlot（隐藏剧情线）** 是一棵分支可能性树，在背景中**调制 future-event-service 产出的 eventOptions**。隐藏属性（道心 / 煞气 / 寿元）达阈值时驱动对应剧情线，改写后续可选事件；某些节点可像 DnD 那样让玩家选择分支。详见 `systems/services/plot-manager.md`。

### 地域 / location 与 Travel 路由

- **地域 / location = 带两组字段的内容条目（承重）。** 角色当前所在地点，是介于「原始生成」与「AdventurePlot 调制」之间的一层框定。它**携带两样东西**：

  | 字段 | 框定强度 | 作用面 |
  |------|----------|--------|
  | **事件类型出现概率修正**（event type possibility modifiers） | **软**（改权重，不改可及性） | 物化时的事件类型配比：荒野多 Combat、坊市多 Exchange、洞天多 Research。**一行 = 一个乘性系数**，缺省 1.0；Travel 行 `>= 0`、其余四类 `> 0`（见下） |
  | **`eventCountLimit`**（事件容量上限） | **硬**（计数闸门） | 玩家在该地域最多经历几个事件 |

  - **类型修正的运算形态 = 乘性系数，乘在该类型的基础权重上，五类系数乘完后一次归一化（承重）。** 它是「软 = 改权重，不改可及性」这条定义的直接推演：加性偏移做不到（一个大负偏移把权重按到 0 或负，可及性就没了，还要额外裁「负权重怎么办」），「白名单 + 权重」本身就是**硬**框定，且白名单这条通道已被 `PlotModulation.EventWhitelist` 独占——两处白名单等于两个权威。完整管线（location 修正与剧本调制如何合并、归一化在哪一步发生）见 `systems/services/future-event-service.md`。
    - **Travel 之外的四类不得被修正到 0，是定义的推演而非数值偏好。** 修正到 0 = 改可及性 = 那一行不再是软框定。Travel 之所以是例外，理由只对它成立：**闸门是独立通道**，可及性由 `eventCountLimit` 闸门保证，故它的权重为 0 时可及性并未被改（见 `systems/adventure-event/travel/_index.md`）。内容作者想表达「坊市几乎不出 Combat」，写一个极小的正系数。
    - **推论：系数恒为正 ⇒ 归一化的分母恒 > 0**，「加权抽取抽不出东西」这个失败态在类型层不存在。

  - **两侧的框定都不是分池。** 事件侧是**对候选池的类型出现概率施加修正**；敌人侧是**并集式的作用域**——通用敌人恒可在任何地域出现，某地域的专属条目在通用池之上**叠加**。**location 条目不持敌人清单**：池归属的唯一权威是 `EnemyData.PoolScope`（见 `systems/enemies/_index.md`），两侧各存一份会让「竹海的敌人」在 location 条目与每条专属敌人上各写一遍，两份表各自漂移而无机制发现。
  - **代价明写：**「这个地域会遇到什么」不再能从一份 location 条目里一眼读全，需要反查——那是 `LocationCodex` 词条（运行时统计）的职责，不是内容编写面。
  - **类型修正的粒度止于类型，及不到 Explore 的真身分布（承重）。** 修正表的 Explore 一行只能表达「洞天多秘境」，表达不了「洞天的秘境多半是战斗」——**秘境不需要、也不会得到条目级的子权重行**。为它开条目级粒度等于把第二套 `EventWeights` 塞进 `LocationData`，粒度与既有两组字段不一致，并立刻引出「PlotManager 能不能改它」（而 `PlotModulation` 无字段可填，两侧能力不对称本身就是漂移源）。真身分布由 Explore 条目池的组成涌现，见 `systems/adventure-event/explore/_index.md`。
  - **数据载体 = `[GlobalClass] LocationData : Resource`，实例为 `.tres`，进 ContentRegistry 有自己的仓储。不设 C# 枚举。** 枚举会把地域数焊进程序集、新增地域必须发版，与 overlay 热更和「新增一个地域 = 新增一个 `.tres`」的可加性冲突，也与同族的 `AdventureEventData` / `EnemyData` / `HiddenStatBandData` 形态不一致。

    ```csharp
    [GlobalClass]
    public partial class LocationData : Resource
    {
        [Export] public string        Id             { get; set; }   // "location.bamboo_sea"
        [Export] public LocalizedText DisplayName    { get; set; }
        [Export] public LocalizedText Description    { get; set; }   // LocationCodex 词条正文
        [Export] public EventTypeModifierData[] EventTypeModifiers { get; set; } // 五类各一行，缺省 = 无修正
        [Export] public int           EventCountLimit  { get; set; } // 硬闸门：该地域的事件容量上限
        [Export] public bool          ContentEnabled   { get; set; } = true;   // 恒 true，false → PushError
    }
    ```

    ```csharp
    [GlobalClass]
    public partial class EventTypeModifierData : Resource
    {
        [Export] public EventType Type       { get; set; }          // 五值之一
        [Export] public float     Multiplier { get; set; } = 1.0f;  // 乘性系数；> 0（Travel 行允许 == 0）
    }
    ```

    - **`Id` 照全库既定的两段式** `<内容类型>.<snake_case_slug>`：`location.bamboo_sea` · `location.cloudveil_fair`（约定见 `content/_index.md`）。
    - **本作 location 是平坦集合，无层级、无区域分组，也不预留分组字段。** 层级没有承重消费方：难度不由换图承载（由赋级带承载）、图三章不变、`LocationCodex` 记的是连边而非分组。**在有消费方之前，分组字段是一个无人读的字段**；日后确需分组时加一个可空的纯风味字段即可，不改结构。
    - **内嵌类型一律是 `Resource` 派生**（`EventTypeModifierData` / `LocationEdgeData`），因为 `[Export]` 只接受 Variant 兼容类型与 `Resource`；`EventOption` / `PastEventEntry` 那类**不导出**的运行时定稿实例照旧用 `sealed record`。
  - **推论（承重）：敌人物化的两条轴至此正交。** **当前 location 影响「派谁来」**（经敌人条目的 `PoolScope` 叠加该地域的专属条目），**相对角色等级的赋级带决定「有多强」**（三章统一 `±2`，见 `systems/services/future-event-service.md`）。地域的生态与风味不需要另设机制。
  - **具体数值归内容制作阶段**：各 location 的类型修正取值与 `eventCountLimit` 的数字均在内容阶段定；哪些敌人属于该地域，在敌人条目一侧编写。
- **`locationMap`（地域图）= 一张全局不变的连通图（承重）。** 地域之间的连边由一份**独立的 `locationMap` 数据**承载——**既不挂在 Travel 事件的内容条目上，也不在运行时算**；Travel 的目的地从当前 location 在图上的**邻接集合**中取。
  - **三个篇章共用同一张图 ⇒ location 不随篇章 / 境界变化。** **难度的篇章差异不由「换一张更难的图」承载，而由敌人赋级带（相对角色当前等级）承载**——同一张图在三个篇章重走，敌人强度自动跟着角色走。这与「全局等级序是一把简单的直尺、境界鸿沟由 `baseMomentum` 承载」是同一种分工：**结构保持简单，难度放进数值。**
  - **推论：熟悉度成为跨轮回的资产。** 图不变 ⇒ 不同轮回走的是**同一片世界**，地名、地域的事件倾向、哪片区域出什么敌人都会被记住并复用。**这是把「重复游玩」转化为「越玩越懂」的结构基础**，也正是 `locationCodex` 的存在理由。
  - **载体 = 单份 `[GlobalClass] LocationMapData : Resource`（全局唯一），持一个无向边集；不由各 location 持边。**

    ```csharp
    [GlobalClass]
    public partial class LocationMapData : Resource, ISingletonContent   // 全局唯一，条数由通用单例校验兜住
    {
        [Export] public LocationEdgeData[] Edges { get; set; }   // 无向；A-B 只写一条
        [Export] public bool ContentEnabled { get; set; } = true;   // 恒 true，false → PushError
    }

    [GlobalClass]
    public partial class LocationEdgeData : Resource
    {
        [Export] public string FromId { get; set; }
        [Export] public string ToId   { get; set; }
    }
    ```

    - **对称性可机械保证。** 各 location 持边时 `A→B` 与 `B→A` 分写两处，漏写即单向边——而图的稳定性是对玩家的隐性承诺，单向边会让 `LocationCodex` 重建出的图与实际路由不符，属**能上线、线上不可见**。单份资源可在加载期一次性校验对称、无自环、无重复、无悬空 `Id`。
    - **连通性校验需要全图视角**，各自持边拿不到。
    - **图是无向的**（连边即双向可通行）。若日后确需单向通道，是给边加一个 `OneWay` 布尔，不改载体。
  - **推论（工程形态）：不变 + 高频读 ⇒ 只读静态数据，启动加载一次、常驻内存。** 它进 `ContentRegistry`（受 overlay 热更管辖，但**一次轮回内视为不变**），future-event-service **只读不写**；**存档不存图本身，只存「当前所在 location 的 `Id`」**。
  - **`LocationData` 与 `LocationMapData` 都是结构性查表类内容，恒启用：`ContentEnabled == false` → 加载期 `PushError`，解析走 `AllIncludingDisabled()`，flags 第三层对它们不生效**（与 `HiddenStatBandData` 同类，判据见 `systems/services/content-service.md`）。
    - **location 有双重身份**——既是 Travel 的目的地候选（看似产出侧），又是 `locationMap` 的**结构顶点**。**结构身份优先**：关掉一个顶点 = 改图，而改连边等于清空一份账号级 `LocationCodex` 资产。
    - **承重理由：flags 是按账号解析、轮回中途可热应用、且不参与合并后强校验的通道。** 若 location 参与 flags 过滤，线上关掉若干地域可使某玩家当前 location 的邻接集合为空 ⇒ 配额闸门时产不出任何 Travel ⇒ **轮回死锁**，而 Travel 恰是既定的死局兜底。**这条风险加载期校验够不着。**
    - **代价如实记下：失去「线上秒关一个问题地域」的运营手段**——地域出问题只能改 overlay、下次冷启动生效。这是为「图恒连通、Travel 恒可产出」付的价。
  - **加载期校验（全部 `PushError` + 定位上下文）。** 图与地域的坏数据只能在加载期发现，故一次全查：

    | 违规 | 理由 |
    |---|---|
    | 边引用了不存在的 `LocationData.Id` | 悬空目的地 |
    | 自环（`FromId == ToId`）、重复边 | 无意义边会污染邻接计数 |
    | 某 location 出度 **> 5** | 闸门批次规模 = 出度，会溢出批次规模区间上限 5 |
    | 某 location 出度 **== 0**（孤立点） | 进得去出不来，配额用尽即死锁 |
    | 图不连通 | 列出被隔离的 `Id` 集合 |
    | `ContentEnabled == false`（两个类型皆是） | 结构性查表类恒启用 |
    | `EventCountLimit <= 0` | 0 会让该地域一进入即触发闸门 |
    | `EventTypeModifierData.Multiplier <= 0` 且 `Type != Travel`（带 location `Id` + 类型） | 修正到 0 即改可及性，那一行不再是软框定 |
    | `EventTypeModifierData.Multiplier < 0`（Travel 行；带 location `Id`） | 负权重无定义；Travel 的 `0` 才是合法下界 |
    | 同一 location 的 `EventTypeModifiers` 中某类型出现多行（带 location `Id` + 类型） | 两行谁生效无定义，静默取其一即漂移 |

    **`LocationMapData` 的份数不在本表内**：它标记为 `ISingletonContent`，条数由 ContentRegistry 的**通用单例校验**统一兜住（见 `systems/services/content-service.md`「单例内容的注册与校验」）。本表因此不自带一条手写的份数检查——逐份手写的形态里，漏写一份就是一个静默的洞。

    **出度 ≤ 5 把「批次规模区间」从一句约定变成一条可机械校验的内容侧纪律**，副作用是正面的——它也让 `LocationCodex` 的连边词条在竖屏上一屏可读。
  - **`locationMap` 在轮回内对玩家不可见。** 「进程是逐批择一的线性推进，不是可俯瞰的分支地图」这条不变——**图存在但不呈现**。玩家可见的那一面是账号级的 **`LocationCodex`（图鉴族第六本）**，「去过即记」**且记连边**，见 `systems/player-profile/codex/_index.md`。**推论：不可见是「初见不可见」而非「永远不可见」**——跨轮回的知识可以逼近整张图，这是设计目标；两者不冲突，因为地图长在玩家脑子里（在图鉴里），不在 HUD 上。**连带：图的稳定性从设计选择升格为对玩家的隐性承诺**，改连边等于清空一份账号级资产。
- **Travel / 前往某处地点 = 地图路由（AdventureEvent-Travel）。** Travel 是 adventure-event 的一个子类型，**功能上是一次地图路由选择**——选择 Travel 事件即**刷新角色所在的 location**，从而换掉下一批 eventOptions。即：Travel 是玩家在月圆之夜式菜单中「换图 / 换地点」的入口。子类型定义见 `systems/adventure-event/travel/`；本文档持有 location 抽象与路由语义。
- **`eventCountLimit` 达成 → 本批只剩 Travel（承重）。** 玩家在当前 location 选够事件、达到 `eventCountLimit` 后，**最后剩下的 eventOption 是「前往另一个 location」**。
  - **承载它只需一个既有字段：** Travel 选项以**最高 `eventPriority`（= 1）**出场即可封锁同批其余选项。**没有跳过通道、也没有 `ifMandatory` 一类的强制标记**——本批的每一项本就都是必做项，闸门不需要第二个字段来封死回避通道。
  - **闸门给多个 Travel 目的地，按 80 / 20 掷定。** **80% 的场景**列出 `locationMap` 上当前 location 的**全部邻接地域**，各为一个并列选项——**「去哪」本身是一次真实的玩家决策**；**20% 的场景**只 seeded 随机给出一个邻接地域。**该掷定对常规出场与闸门场景一律适用**，规则只有一条；**它落到批次时怎么占位**（闸门批整批归 Travel、常规批的 80% 档受本批槽位数截断）见 `systems/adventure-event/travel/_index.md`。**80 / 20 是全局常量 `TravelFullFanoutChance = 0.80`，不接受任何按剧情线 / location 的覆盖参数。****推论：闸门是逐批择一的线性进程里唯一一个带地理含义的分岔点**；结合 `LocationCodex`，它是玩家把跨轮回积累的地理知识**变现**的地方——八成的岔路口有得选，两成被命运推着走。见 `systems/adventure-event/travel/_index.md`。
  - **推论：Travel 由「可选路由」升格为结构性闸门。** 地域迁移是**被规则驱动的必经节点**，不再只是玩家想换图时才选的事件。**进程的形状由此清晰：一次篇章 = 若干 location 的串联，每个 location 内是一段定长的 eventOptions 循环，location 之间由 Travel 缝合。**
  - **推论：`eventCountLimit` 是篇章节奏的结构单位。** 篇章事件总数 ≈ 途经各 location 的容量之和，故它与时长主旋钮 `lifeSpanCost` **互相约束**，须一同反推目标时长（见 `systems/balance.md`）。
  - **配额是内容侧定值，剧本推拉不到它（承重）。** `PlotModulation` 没有承载 `eventCountLimit` 的字段：它是**硬闸门、落约束面**，而剧本的权力面只覆盖内容面（判据与权力面逐条投影见 `systems/services/plot-manager.md`）。**开放它等于让剧本借道一格内容字段完成一次约束置位**——把某地域的配额压到 1，即可在下一批把玩家整批锁进 `eventPriority = 1` 的 Travel，而闸门 Travel 之所以获准抬 `Priority`，全部理由就是它的判定式只读一个计数器（见 `systems/services/future-event-service.md` 的抬升判据）。它与 `TravelFullFanoutChance`、`BatchSizeWeights` 是同一族旋钮——三者都定**玩家选择空间的形状**，走同一条收口。
    - **剧本仍能影响地域节奏，但只能加速离开、不能延长停留。** 抬高 `TypeWeights[Travel]` 让 Travel 更常出现在常规批，玩家自行提前走即令 `LocationEventCount` 归 `0`。**不对称是有意的**：硬上限是对篇章时长预算的承诺，而「更快赶路」最终仍由玩家点下去。
    - **恒为定值的连带收益：一章的事件总数可枚举** ⇒ 它与 `lifeSpanCost` 的时长反推是一个算术问题，而不是一个只能按期望值算并接受方差的分布问题；「按标准路线走能在预算内升满」那条验收项也因此可算。
    - **代价如实记下：** 剧本表达不了「这片林子把你困住了，得多走几步才出得去」这类**硬性延长**的叙事，只能软化为「这一段更凶 + 更容易出现某类事件」。
    - **这条只约束剧本层。** `EventCountLimit` 仍是一格普通的内容字段，**overlay 照常可改**（location 恒启用、不受 flags 管辖，改值下次冷启动生效，见 `systems/services/content-service.md`）——「线上让人快点离开某个问题地域」这条运营通道不被本条封死。
  - **计数口径：只计「选择进入并结算」的事件，Travel 不计入。** **推论：配额是「在这个地域做了几件事」的纯计数**——离开的动作本身不算做事。**一批 = 一次操作 = 一次配额消耗**，地域节奏是一条干净的计数。
  - **计数的承载字段 = `CharacterProfile.Status.LocationEventCount`（int）。** **非 Travel 事件结算 → `+1`；Travel 事件结算 → 归 `0`**，连同 `CurrentLocationId` 一并更新，落在 `eventEnd` 那**一次** `TryApply` 内（不新增结算阶段、不新增存档点）。
    - **归 0 恒成立，包括由 Explore 揭示而来的 Travel**——该 Explore 的 `+1` 随即被归 0 覆盖，因为计数的语义是「在这个地域做了几件事」，换了地域即作废。
    - **闸门判定 = `LocationEventCount >= 当前 location 的 EventCountLimit`**，在**每一次整批重算**时求值（没有第二个判定时点）。
- **换图后的第一批无特殊规则。** Travel 结算后的重算就是一次**普通的整批重算**（依角色整体历程 + 新 location 框定 + PlotManager 调制 + map 子流），数量照常常态 3 / 区间 1–5，类型配比照常由新 location 的类型修正给出。**不存在「换图首批」这个概念**——「一次选择 → 整批重算」是唯一的刷新形态。
- **Travel 与篇章 / 境界推进不耦合（承重）。**
  - **篇章边界由 Finale 承载，不由 Travel 承载。** Finale 的出现条件「角色已达本境界巅峰」是一条**等级条件**，与所在 location 无关。**Finale 不绑定特定 location，不设「渡劫场」地域**——否则「必须先走到某地才能渡劫」会与「Finale 之前必须升满」形成两条互相牵制的进度闸，任一条卡住即卡死轮回。
  - **篇章切换时当前 location 继承。** 「篇章继承 = 全部继承」+「三章共用同一张图」⇒ 下一篇章从上一篇章结束时所在的 location 继续，不重置到起点，也不需要「起始地域」这个概念。这与「同一张图在三个篇章重走、敌人强度跟着角色走」完全同向。
  - **推论：`CurrentLocationId` 是跨篇章持久的存档字段**，不随 chapter 边界清零（篇章重试时随该篇章起始存档一并回滚）。
- **归属划分。** location 抽象、字段语义与路径导航归本文档（game-progression）；Travel 作为**事件类型**的呈现 / 数据（含非常驻出场与 80 / 20 掷定）归 `adventure-event/travel/`；二者通过「Travel 刷新 location → location 框定 eventOptions」协作。

### blind / ante 缩放
- blind / ante 的**要求、奖励与 scaling** 归本文档（进程侧）；缩放曲线为可调数值，存入 `.tres` 并归 `systems/balance.md`（ante 曲线）。**具体 blind 要求 / 奖励 / 缩放曲线尚未陈述**，见待决问题。

Source: `handoffs/2026-07-13.md` · `handoffs/2026-07-15-adventure-event-profiles.md` · `handoffs/2026-07-15b-taxonomy-and-checkpoint-clarifications.md` · `handoffs/2026-07-22-online-cloud-combat-and-meta-clarifications.md` · `handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md` · `handoffs/2026-07-24-docs-restructure-class-model.md` · `handoffs/2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md` · `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md` · `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md` · `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md` · `handoffs/2026-08-02-momentum-conversion-reward-structure-and-mtg-stack.md` · `handoffs/2026-08-05b-location-fields-event-count-limit-and-skip-refill-closure.md` · `handoffs/2026-08-06c-skip-channel-removal-priority-two-tier-and-location-codex-edges.md` · `handoffs/2026-08-06d-combat-open-questions-mass-closure.md` · `handoffs/2026-08-09b-player-power-fragment-finale-bound-drop-chance.md` · `handoffs/2026-08-15c-event-type-collapse-and-batch-shape.md` · `handoffs/2026-08-16g-travel-mechanics-and-location-carrier.md` · `handoffs/2026-08-17c-explore-reveal-mechanics.md` · `handoffs/2026-08-22-finale-failure-is-death.md` · `handoffs/2026-08-22-event-generation-weighting-pipeline.md` · `handoffs/2026-08-22-event-outcome-spec-fields.md` · `handoffs/2026-08-22-eventcountlimit-plot-modulation.md`

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- **境界存档 · 篇章重试模型（四境三篇章、篇章衔接、重试无限/3/1）** → `decisions/ADR-0004-realm-checkpoint-retry-model.md`（Accepted）。
- **修行事件分类（含 Explore / Travel）** → `decisions/ADR-0002-adventure-event-taxonomy.md`（Accepted；ADR-0002 待补订 Explore / Travel）。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **中长期规划感的来源。** 进程是**逐批择一的线性推进**，既无俯瞰地图也无前方预告。**地理方位感这一半已落地**：`LocationCodex` 记连边，玩家因此能**提前两步规划路线**——跨轮回的知识增长直接转化为轮回内的决策质量。**仍待定的是进度感那一半**：图鉴不回答「还有几步到 Finale」，是否还需轮回内的补充（篇章进度条？前瞻提示？）。→ 亦见 `ux/`、`systems/player-profile/codex/`。
- **「可用结束点」已明确**：到达下一境界所落的**存档点**即结束点，可读档开始下一 chapter。**chapter 途中死亡 → 从该 chapter 起始存档重试**；炼气（第 1 chapter）近乎无限重试，后续 chapter 有限重试（数值见 `systems/services/life-cycle-service.md`）。
- **选择区的呈现与导航手感**：月圆之夜式菜单 + 横向滑动选择，但**每批 eventOptions 的选项数量 / 排布 / 滑动手感**尚未落定。注意进程形态是**逐批择一的线性推进**（每次从当前 eventOptions 中选一个，选完重算下一批），**不是可俯瞰、可回溯的分支地图**。
- **eventOptions 的五类配比未定。** 生成 / 加权的**运算形态已定**（十步管线、类型修正是乘性系数、多 arc 权重相乘 / 白名单取并、批次规模由 `BatchSizeWeights` 掷定，见 `systems/services/future-event-service.md`）；仍待定的是**基础类型权重表 `BaseTypeWeights` 每格填多少**。→ `systems/balance.md`。
- **blind / ante 缩放（未陈述）：** 具体 blind 要求 / 奖励 / ante 缩放曲线**尚未陈述**；缩放数值最终归 `systems/balance.md`。

## 对应
提炼至：`.claude/knowledge/systems/game-progression.md`（引用层，待建）。
