# game-progression

> 每个 ante 的进程推进、location（地域）、Travel 路由、节点类型路径导航、月圆之夜式菜单、横向滑动选择、篇章 / 境界推进、blind / ante 缩放。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

### 轮回结构与篇章 / 境界推进
- 一次轮回的结构为 **realm → chapter → AdventureEvent**。修炼阶梯（炼气 / Qi Refining → 筑基 / Foundation Establishment → 金丹 / Golden Core → 元婴 / Nascent Soul）共四个 realm；一次轮回为**三个 chapter**，每个 chapter 是相邻两个 realm 之间的攀登。
- 在一个 chapter 内，进程由 **eventOptions 循环**驱动：future-event-service 依当前 characterProfile 产出一批可选的 AdventureEvent（eventOptions），玩家**从中选择一个**来推进；每个 AdventureEvent 触发事件、改变玩家状态，随后 future-event-service **重算下一批 eventOptions**。见 `systems/services/future-event-service.md`。
- **各 chapter 相互衔接。** 第 N+1 个 chapter 从第 N 个 chapter 的某个*可用结束点*开始——因此完成状态会分支，并为下一个 chapter 的起点埋下种子。
- 每个 chapter 边界都是角色档案上的一个**存档 / 记录点**（共三个）；抵达元婴即为最终奖杯展示。
- **篇章收口 = 一次性的 Finale，胜负不是推进闸门（承重）。** **每个篇章只有一个 Finale，失败后不可在同一篇章内再次挑战**——想再渡一次这一劫只能重走整个篇章（走篇章重试，上限 ∞ / 3 / 1，付费 ∞ / 9 / 3）。
  - **Finale 失败通常打穿 `lifeTotal` ⇒ 经既有 `LifeTotalExhausted` 通道 defeated**；但**未被打穿的那约 1% 情形里角色存活并照常完成该篇章、照常突破境界**。
  - **因此渡劫的胜负只决定两件事**：`lifeTotal` 的损失量，以及**道统残卷是否兑现**（发放只认胜利）。**篇章推进本身不再由 Finale 的胜负把关。**
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
  - **失败产出 = 一条 reward 两个字段，不是两套内容**：`ExperienceGrade`（成功档位）+ `FailureRatio`（默认 **0.5**，逐条可覆写，留给「这场输了才真正学到东西」的特例）。折算在 `ProfileChangeSpec` 组装时完成，`TryApply` 收到的已是最终整数。**50% 而非更低**：失败已经付了 `lifeTotal` 的硬代价（归 0 即角色终结），靠反复失败刷经验天然不是优势路线。
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

- **地域 / location = 带三组字段的内容条目（承重）。** 角色当前所在地点，是介于「原始生成」与「AdventurePlot 调制」之间的一层框定。它**携带三样东西**：

  | 字段 | 框定强度 | 作用面 |
  |------|----------|--------|
  | **事件类型出现概率修正**（event type possibility modifiers） | **软**（改权重，不改可及性） | 物化时的事件类型配比：荒野多 Combat、坊市多 Exchange、洞天多 Research |
  | **敌人模板集合**（一组特定的 `EnemyData`） | **硬**（限定取池） | 战斗类事件物化时「派谁来」 |
  | **`eventCountLimit`**（事件容量上限） | **硬**（计数闸门） | 玩家在该地域最多经历几个事件 |

  - **「不同地点开放不同的事件池」这句旧措辞由此收窄：** 事件侧**不是硬分池**，而是**对候选池的类型出现概率施加修正**；硬分池只发生在**敌人**那一侧。一软一硬是两种框定形态。
  - **推论：location 已具备内容条目的形态**——携带字段集合、由内容作者编写、被物化读取，故应有稳定 `Id`、经 `ContentRegistry` 索引、受 `ContentEnabled` 与 overlay 热更管辖（见 `data-resource-rules.md`）。**数据载体的定名与形态待答**，见待决问题。
  - **推论（承重）：敌人物化的两条轴至此正交。** **location 决定「派谁来」**（模板池），**相对角色等级的赋级带决定「有多强」**（三章统一 `±2`，见 `systems/services/future-event-service.md`）。地域的生态与风味不需要另设机制——这两个字段就是它的全部表达。
  - **具体数值归内容制作阶段**：各 location 的类型修正取值、模板清单、`eventCountLimit` 的数字均在内容阶段定。
- **`locationMap`（地域图）= 一张全局不变的连通图（承重）。** 地域之间的连边由一份**独立的 `locationMap` 数据**承载——**既不挂在 Travel 事件的内容条目上，也不在运行时算**；Travel 的目的地从当前 location 在图上的**邻接集合**中取。
  - **三个篇章共用同一张图 ⇒ location 不随篇章 / 境界变化。** **难度的篇章差异不由「换一张更难的图」承载，而由敌人赋级带（相对角色当前等级）承载**——同一张图在三个篇章重走，敌人强度自动跟着角色走。这与「全局等级序是一把简单的直尺、境界鸿沟由 `baseMomentum` 承载」是同一种分工：**结构保持简单，难度放进数值。**
  - **推论：熟悉度成为跨轮回的资产。** 图不变 ⇒ 不同轮回走的是**同一片世界**，地名、地域的事件倾向、哪片区域出什么敌人都会被记住并复用。**这是把「重复游玩」转化为「越玩越懂」的结构基础**，也正是 `locationCodex` 的存在理由。
  - **推论（工程形态）：不变 + 高频读 ⇒ 只读静态数据，启动加载一次、常驻内存。** 它进 `ContentRegistry`（受 overlay 热更管辖，但**一次轮回内视为不变**），future-event-service **只读不写**；**存档不存图本身，只存「当前所在 location 的 `Id`」**。
  - **`locationMap` 在轮回内对玩家不可见。** 「进程是逐批择一的线性推进，不是可俯瞰的分支地图」这条不变——**图存在但不呈现**。玩家可见的那一面是账号级的 **`LocationCodex`（图鉴族第六本）**，「去过即记」**且记连边**，见 `systems/player-profile/codex/_index.md`。**推论：不可见是「初见不可见」而非「永远不可见」**——跨轮回的知识可以逼近整张图，这是设计目标；两者不冲突，因为地图长在玩家脑子里（在图鉴里），不在 HUD 上。**连带：图的稳定性从设计选择升格为对玩家的隐性承诺**，改连边等于清空一份账号级资产。
- **Travel / 前往某处地点 = 地图路由（AdventureEvent-Travel）。** Travel 是 adventure-event 的一个子类型，**功能上是一次地图路由选择**——选择 Travel 事件即**刷新角色所在的 location**，从而换掉下一批 eventOptions。即：Travel 是玩家在月圆之夜式菜单中「换图 / 换地点」的入口。子类型定义见 `systems/adventure-event/travel/`；本文档持有 location 抽象与路由语义。
- **`eventCountLimit` 达成 → 本批只剩 Travel（承重）。** 玩家在当前 location 选够事件、达到 `eventCountLimit` 后，**最后剩下的 eventOption 是「前往另一个 location」**。
  - **承载它只需一个既有字段：** Travel 选项以**最高 `eventPriority`（= 1）**出场即可封锁同批其余选项。**没有跳过通道、也没有 `ifMandatory` 一类的强制标记**——本批的每一项本就都是必做项，闸门不需要第二个字段来封死回避通道。
  - **闸门给多个 Travel 目的地，按 80 / 20 掷定。** **80% 的场景**列出 `locationMap` 上当前 location 的**全部邻接地域**，各为一个并列选项——**「去哪」本身是一次真实的玩家决策**；**20% 的场景**只 seeded 随机给出一个邻接地域。**该掷定对常规出场与闸门场景一律适用**，规则只有一条。**推论：闸门是逐批择一的线性进程里唯一一个带地理含义的分岔点**；结合 `LocationCodex`，它是玩家把跨轮回积累的地理知识**变现**的地方——八成的岔路口有得选，两成被命运推着走。见 `systems/adventure-event/travel/_index.md`。
  - **推论：Travel 由「可选路由」升格为结构性闸门。** 地域迁移是**被规则驱动的必经节点**，不再只是玩家想换图时才选的事件。**进程的形状由此清晰：一次篇章 = 若干 location 的串联，每个 location 内是一段定长的 eventOptions 循环，location 之间由 Travel 缝合。**
  - **推论：`eventCountLimit` 是篇章节奏的结构单位。** 篇章事件总数 ≈ 途经各 location 的容量之和，故它与时长主旋钮 `lifeSpanCost` **互相约束**，须一同反推目标时长（见 `systems/balance.md`）。
  - **计数口径：只计「选择进入并结算」的事件，Travel 不计入。** **推论：配额是「在这个地域做了几件事」的纯计数**——离开的动作本身不算做事。**一批 = 一次操作 = 一次配额消耗**，地域节奏是一条干净的计数。
- **归属划分。** location 抽象、字段语义与路径导航归本文档（game-progression）；Travel 作为**事件类型**的呈现 / 数据（含非常驻出场与 80 / 20 掷定）归 `adventure-event/travel/`；二者通过「Travel 刷新 location → location 框定 eventOptions」协作。

### blind / ante 缩放
- blind / ante 的**要求、奖励与 scaling** 归本文档（进程侧）；缩放曲线为可调数值，存入 `.tres` 并归 `systems/balance.md`（ante 曲线）。**具体 blind 要求 / 奖励 / 缩放曲线尚未陈述**，见待决问题。

Source: `handoffs/2026-07-13.md` · `handoffs/2026-07-15-adventure-event-profiles.md` · `handoffs/2026-07-15b-taxonomy-and-checkpoint-clarifications.md` · `handoffs/2026-07-22-online-cloud-combat-and-meta-clarifications.md` · `handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md` · `handoffs/2026-07-24-docs-restructure-class-model.md` · `handoffs/2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md` · `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md` · `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md` · `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md` · `handoffs/2026-08-02-momentum-conversion-reward-structure-and-mtg-stack.md` · `handoffs/2026-08-05b-location-fields-event-count-limit-and-skip-refill-closure.md` · `handoffs/2026-08-06c-skip-channel-removal-priority-two-tier-and-location-codex-edges.md` · `handoffs/2026-08-06d-combat-open-questions-mass-closure.md` · `handoffs/2026-08-09b-player-power-fragment-finale-bound-drop-chance.md` · `handoffs/2026-08-15c-event-type-collapse-and-batch-shape.md`

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- **境界存档 · 篇章重试模型（四境三篇章、篇章衔接、重试无限/3/1）** → `decisions/ADR-0004-realm-checkpoint-retry-model.md`（Accepted）。
- **修行事件分类（含 Explore / Travel）** → `decisions/ADR-0002-adventure-event-taxonomy.md`（Accepted；ADR-0002 待补订 Explore / Travel）。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **中长期规划感的来源。** 进程是**逐批择一的线性推进**，既无俯瞰地图也无前方预告。**地理方位感这一半已落地**：`LocationCodex` 记连边，玩家因此能**提前两步规划路线**——跨轮回的知识增长直接转化为轮回内的决策质量。**仍待定的是进度感那一半**：图鉴不回答「还有几步到 Finale」，是否还需轮回内的补充（篇章进度条？前瞻提示？）。→ 亦见 `ux/`、`systems/player-profile/codex/`。
- **「可用结束点」已明确**：到达下一境界所落的**存档点**即结束点，可读档开始下一 chapter。**chapter 途中死亡 → 从该 chapter 起始存档重试**；炼气（第 1 chapter）近乎无限重试，后续 chapter 有限重试（数值见 `systems/services/life-cycle-service.md`）。
- **选择区的呈现与导航手感**：月圆之夜式菜单 + 横向滑动选择，但**每批 eventOptions 的选项数量 / 排布 / 滑动手感**尚未落定。注意进程形态是**逐批择一的线性推进**（每次从当前 eventOptions 中选一个，选完重算下一批），**不是可俯瞰、可回溯的分支地图**。
- **eventOptions 生成 / 加权**：future-event-service 服务化已定，但**从 characterProfile 如何生成 / 加权抽取**下一批 eventOptions（策划 vs 随机权重、带种子 RNG 派生）、以及 location 框定 / AdventurePlot 调制 / seeded RNG 的**叠加顺序**未定。→ `systems/services/future-event-service.md`。
- **location 与 `locationMap` 的数据载体与定名。** **字段与图的存在形态**（三组字段 + 一张全局不变的连通图，见「意图」）；仍待定：载体形态与定名（`LocationData : Resource` + `.tres`？枚举 + 资源两件套？`locationMap` 是单份邻接表资源还是由各 location 持边？）、稳定 `Id` 形态、是否与 `AdventureEventData` 一样受 `AllEnabled()` 与 overlay 管辖。
- **Travel 闸门给几个候选、怎么选。** **多个并列**；仍待定：是否把当前 location 的**全部邻接**都列出、还是 seeded 抽取其中几个，候选是否受剧本调制。→ `systems/adventure-event/travel/`。
- **`eventCountLimit` 是否随篇章 / 剧本调制而变。** **计数口径**（只计选择进入并结算的，Travel 不计入）；配额本身能否被 PlotManager 推拉未定。
- **事件类型概率修正的形态。** 乘性权重 / 加性偏移 / 「白名单 + 权重」？某个类型能否被修正到 0（= 该地域不出这类事件，软框定退化为硬框定）？**具体数值归内容制作阶段，但形态是机制。**
- **location 机制的其余细节（待定）：** 地域的枚举 / 层级、Travel 如何映射到具体 location、location 与 AdventurePlot 调制的叠加顺序、location 是否随篇章 / 境界变化——均**尚未陈述**。
- **blind / ante 缩放（未陈述）：** 具体 blind 要求 / 奖励 / ante 缩放曲线**尚未陈述**；缩放数值最终归 `systems/balance.md`。

## 对应
提炼至：`.claude/knowledge/systems/game-progression.md`（引用层，待建）。
