# adventure-event / travel（AdventureEvent-Travel）

> 「前往某处地点」：一次地图路由选择，刷新角色所在的 location（地域）。**非常驻可选项**，候选呈现走 80 / 20 掷定。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **前往某处地点（Travel）= AdventureEvent 的一个子类型。** **功能上是一次地图路由选择**——刷新角色所在的 **location（地域）**。见 `terminology.md`。
- **Travel 不是常驻可选项。** 它**只在配额闸门时必定出现**（`eventCountLimit` 达成，见下）；其余时候是否出场**不保证**——即便地图上与当前 location 连通，邻接目的地也不保证都出场。**推论：地域停留时长的下限由玩家的运气与选择共同决定，上限由 `eventCountLimit` 封死。**
- **候选呈现 = 80 / 20 掷定。**

  | 概率 | 呈现 | 玩家决策 |
  |---|---|---|
  | **80%** | 列出当前 location 在 `locationMap` 上的**全部邻接地域**，各为一个并列的 Travel 选项 | 「去哪」是一次真实的选择 |
  | **20%** | **seeded 随机取一个**邻接地域 | 无从选择去哪，只能决定去不去 |

  - **该掷定对常规出场与配额闸门一律适用**——规则只有一条，不按场景分叉。**它落到批次时怎么占位，见下方「掷定的批次占位」。**
  - **80 / 20 是全局常量，不可被剧本调制。** `TravelFullFanoutChance = 0.80` 住平衡资源（可线上调），**只有一份全局值，不接受任何按剧情线 / location 的覆盖参数**——与「赋级函数不接受任何区间覆盖参数」同款收口：不给这个口子，就不存在「谁有权用它」。
    - **依据 ①：** PlotManager 的边界是「只调内容不调约束」。掷定改变的是**玩家的选择空间宽窄**（多个可选目的地 vs 一个被指定的目的地），这落在**约束面**——允许剧本推拉它等于开一条绕过该边界的后门。
    - **依据 ②（承重）：** `LocationCodex` 记连边 ⇒ 「提前两步规划路线」是跨轮回知识的变现通道。剧本若能悄悄把随机档拉高，这份积累会在玩家不知情时失效——而他连「被调过」都感知不到。**这条依据的信息基础是确定的**：去过一个地域即显影它的全部邻接（显影粒度与半径见 `systems/player-profile/codex/_index.md`），故闸门给出的每个目的地，玩家都能预知它又通向哪里。**显影半径同样是约束面参数，与本条同款收口——不设旋钮。**
    - **「迷途」仍可表达，换一条既有通道**：让该剧情线的候选池多出 Explore 条目（Explore 遮罩的 Travel 必走随机档）——这正是「剧本靠收窄候选池表达强制性」的标准用法，不需要新旋钮。
  - **Explore 揭示出的 Travel 必为随机那一档**（见 `../explore/_index.md`）——秘境把人带到别处，本就不该让人挑。
  - **20% 档不产生死局**：即便只剩一个目的地，轮回仍可推进（`selectCost` 无条件可支付）。
  - **推论：`LocationCodex` 的路线规划价值仍然成立，只是被打了折。** 八成的岔路口仍是有信息的选择，两成是被命运推着走——后者反而让「记连边」的知识有了「知道却用不上」的张力。
- **通过 location 换图，框定下一批可用事件。** location（地域）**框定 eventOptions** —— 它携带事件类型出现概率修正、一组特定的 `EnemyData`、以及 `eventCountLimit`（字段语义见 `systems/game-progression.md`）；Travel 事件是刷新 location 的手段。
- **Travel = 结构性闸门，不只是可选路由（承重）。** 玩家在当前 location 达到 `eventCountLimit` 后，**本批 eventOptions 收窄为仅剩 Travel**。承载它**只需一个既有字段**：Travel 选项以**最高 `eventPriority`（= 1）**出场即可封锁同批其余选项——本批的每一项本就都是必做项，**不需要额外的强制标记字段**。
  - **推论：地域迁移是被规则驱动的必经节点**，每个 location 都有一个确定的出口时刻。**进程的形状由此清晰：一次篇章 = 若干 location 的串联，location 之间由 Travel 缝合。**
  - **闸门给多个目的地：** 收窄后剩下的是**若干个并列的 Travel 选项**，各指向 **`locationMap`** 上当前 location 的一个邻接地域——**「去哪」本身是一次真实的玩家决策**（80% 的场景；另 20% 只给一个，见上）。**推论：这是逐批择一的线性进程里唯一一个带地理含义的分岔点**；因 `locationMap` 对玩家不可见，第一次走是盲选，随 `LocationCodex` 积累而变成有信息的选择——**跨轮回的知识增长在此变现**。
  - **Travel 不占用所在 location 的 `eventCountLimit` 配额：** 配额只计「选择进入并结算」的事件，**离开的动作本身不算做事**。
  - **推论：Travel 同时是死局兜底，且有两个触发面。** 兜底保证**任何时刻至少有一个可推进的选项**——且它必然可被选中（`selectCost` 无条件可支付，见 `../common-properties.md`）。**兜底成立的前提是邻接集合恒非空**：故 location 与 `locationMap` 恒启用、出度 ≥ 1 由加载期校验封住（见 `systems/game-progression.md`）。

    | 触发面 | 情形 | 产出 |
    |---|---|---|
    | **配额闸门** | `LocationEventCount >= EventCountLimit` | 整批归 Travel，规模 = 邻接数（或 1） |
    | **常规批的收缩保底** | 常规批经 20% 档缩水与闸 ③ 降级后 `Options.Count` 收缩到 0 | 补**一个** Travel，该批规模 = 1 |

    - **收缩保底不是单项补位。** 它不重新取池、不挑条目，只走这条恒可产出的通道；「本服务不设单项补位」管的是「批次少一项时不另取一条填补」，而本条管的是「批次空掉时仍有一个出口」，两者不是同一件事。管线落位见 `systems/services/future-event-service.md`。
    - **两个触发面共用同一条通道，故兜底的前提也只有那一条**（邻接集合恒非空），不需要第二套保证。

  - **Travel 条目的 `ChapterScope` 必须为空（加载期 `PushError`）。** 篇章框定对 Travel 不适用——它是结构性通道而非内容，目的地取自三章共用的同一张地域图，给它一个篇章维度没有可表达的语义；而一旦某章没有命中的 Travel 条目，上表两个触发面同时失效、轮回死锁。禁令与其余两条（不计入 `eventCountLimit` · outcome 不得含 `LifeSpan` 产出）同族，字段语义见 `../common-properties.md`。

- **掷定的批次占位（规则仍只有一条，此处只说它怎么落到批次上）。**

  | 场景 | 80% 档 | 20% 档 | 批次形状 |
  |---|---|---|---|
  | **配额闸门** | 全部邻接各一个选项 | seeded 随机一个 | **整批只有 Travel**，规模 = 邻接数（或 1） |
  | **常规出场** | Travel 分得的槽位数 `k` 个目的地（从邻接集合按 map 子流抽 `k` 个） | 1 个 | Travel 占 `k` 个位，其余位给别的类型 |
  | **Explore 揭示** | —— | 恒随机档，1 个 | 不占批次（进入即揭示即结算） |

  - **常规场景的 80% 档受本批分得的槽位数截断**：不加这层口径，一个 4 邻接的地域在常规批里掷中 80% 档就要摆 4 个 Travel + 其余类型 ⇒ 溢出批次规模区间 1–5，或把常规批挤成事实上的闸门批（「想做别的却只能走」），后者直接违背「Travel 不是常驻可选项」。
  - **配套硬约束：`locationMap` 的最大出度 ≤ 5**（闸门批次规模 = 出度，而批次区间上限是 5）。校验归 `systems/game-progression.md`。**副作用是正面的**——出度 ≤ 5 也让 `LocationCodex` 的连边词条在竖屏上一屏可读。

- **常规出场概率 = location 的事件类型出现概率修正里的 Travel 一行，不设第二个机制。** Travel 是 `eventType` 五值之一，与其余四类走**同一条加权抽取**；「荒野常出 Travel（路多）、洞天罕出 Travel（深居）」由内容侧填该行表达。**Travel 的常规出场因此不需要任何新字段。**
  - **运算形态 = 乘性系数**（缺省 1.0，乘在基础类型权重上，五类系数乘完后一次归一化）；**Travel 一行的取值域是 `>= 0`，其余四类是 `> 0`**。语义与依据见 `systems/game-progression.md`，落位见 `systems/services/future-event-service.md` 的十步管线第 ④ 步。
  - **`k` = 本批 N 个槽位中类型抽中 Travel 的次数**，是批次规模 N 与类型分布的**副产品，不是独立旋钮**——它由类型指派那一步（有放回抽 N 次、按各类型可用条目数封顶）直接给出，`k` 可为 0。
  - **推论：Travel 的类型修正允许被修正到 0** = 该地域常规不出 Travel、只在配额闸门时出场（闸门路径不受类型修正影响，死局兜底仍成立）。这给了「某个类型能否被修正到 0」那条待答项一个**在 Travel 上安全的正面答案**；其余四类不适用本推论。

- **Travel 的代价 = `lifeSpanCost` 定价表的 Travel 一行，取非 0 的低值。** 代价走既有通道、不新增机制；内容条目默认不填、取表值。
  - **该行必须 > 0，是结构性理由而非数值偏好。** Travel 不计入 `eventCountLimit`（配额闸拦不住它）+ 换图 = 换类型修正 + 整批重算 ⇒ 若定价为 0 即开出一条**零成本的事件池 reroll**，「来回横跳直到刷出想要的事件」成为最优策略，而它正是本库反复否决的那类可电子表格化优化。**寿元定价是唯一能拦住它的闸。**
  - **取值为同章 `Exchange` 行的 1/3 ~ 1/2**（「赶路便宜，但不是免费的」）：换图的策略价值保住、reroll 漏洞被寿元堵死、20% 随机档也不至于显得亏。当前取值 **ch1 9 / ch2 10 / ch3 25**，对同章 `Exchange` 的 23 / 25 / 63 分别为 0.39 / 0.40 / 0.40。
    - **分母写死为 `Exchange` 行。** 该纪律的目的是堵零成本 reroll 且不让换图显得亏，绑住的应当是**最便宜的那条常规行**——那是紧的一边；`Exchange` 恰是表上最便宜的非 Travel 行，故它同时是加载期校验的机械分母（越出 1/3 ~ 1/2 即 `PushWarning`）。表、校验与全部绝对数字见 `systems/balance.md`。

- **Travel 条目的 outcome 侧不得含 `LifeSpan` 产出（结构性禁令 · 加载期 `PushError` + 条目 `Id`）。** 它与上一条同源：寿元回复通道的平衡护栏之一是「回寿事件占 `eventCountLimit` 配额，挤掉的是别的事件」，而 **Travel 不计入配额** ⇒ 那道闸对它整条失效，只剩定价最低一档的那道。一条带回寿的 Travel 条目就是「来回横跳换寿元」，与零成本 reroll 是同一个漏洞的两半。**Explore 遮罩的情形自动覆盖**——被遮罩的真身本身就是一个 Travel 条目，模板侧校验照常命中。回寿通道的完整形态见 `systems/adventure-event/common-properties.md`。

- **不设途中遭遇。** 「路上可能有事」这一语义由 **Explore 遮罩 Travel** 承载（秘境把人带到别处），不再另设第二套机制。
  - **规则依据：** 「一次选择仍只结算一个事件」「一批 = 一次操作 = 一次配额消耗」是承重定案；途中遭遇 = 一次选择结算两个事件，且该遭遇算不算配额、写几条 `PastEventEntry` 都要新增规则。
  - **风险面已足：** Travel 的风险 = 付出寿元却可能走到一个更不利的地域（类型修正不合自己的 build、敌人池更凶）。**这已是一次真实的风险决策**，且它由 `LocationCodex` 的知识积累化解——正是设计目标。

- **换图后的第一批无特殊规则，只是输入变了。** Travel 结算后的重算就是**一次普通的整批重算**（依角色整体历程 + 新 location 框定 + PlotManager 调制 + map 子流），数量照常常态 3 / 区间 1–5，类型配比照常由新 location 的类型修正给出。**不存在「换图首批」这个概念**——「一次选择 → 整批重算」是唯一的刷新形态，Travel 不是例外。配额计数器的重置见 `systems/game-progression.md`。

- **与篇章 / 境界推进不耦合。** Finale 的出现条件是「角色已达本境界巅峰」，是一条**等级条件**，与所在 location 无关；**Finale 不绑定特定 location，不设「渡劫场」地域**。篇章切换时当前 location 继承。理由与推论见 `systems/game-progression.md`。

- **Travel 零事件内决策点 ⇒ 一经选中不可取消（承重）。** 整条结算路径上**没有任何玩家输入**——目的地在物化时已掷定并落在 `DestinationLocationId` 上，两条 `StatusAssignment` 由 life-cycle-service 在 `eventEnd` 组装。`ct` 只在决策点被观察 ⇒ Travel 上无观察位。
  - **取消请求不改变本次事件的结局**：流程走到收口、`pastEvent` 照常记，`AdvanceEventAsync` 返 `AdvanceResult(Success: true, FailedAt: None)`，退出在收口**之后**才生效。返 `Cancelled` 会让编排顶点按「这一步还没结束」处理一个已结束的事件。语义表与逐类决策点清单见 `systems/services/life-cycle-service.md`。
  - **代价可忽略**：Travel 的结算是**纯内存计算**（不含战斗、不含面板、不消耗事件内随机），毫秒级，玩家感知不到「点了退出还要等一下」。**Explore 揭示出的 Travel 同样适用**。

- **Travel 的 `pastEvent` 痕迹记出发地。** Travel 是唯一一类会在自己结算过程中改变 `PastEventEntry.LocationId` 的事件，故明写：**记出发地**（与其余四类一致——都是「这一步发生在哪」），目的地由**下一条痕迹**的 `LocationId` 自然给出。不新增字段；`LocationCodex` 从痕迹序列读出的路径因此连贯。

Source: `handoffs/2026-09-03-lifespan-cost-table-and-budget-scale.md` · `handoffs/2026-07-24-docs-restructure-class-model.md` · `handoffs/2026-08-05b-location-fields-event-count-limit-and-skip-refill-closure.md` · `handoffs/2026-08-15c-event-type-collapse-and-batch-shape.md` · `handoffs/2026-08-16g-travel-mechanics-and-location-carrier.md` · `handoffs/2026-08-17f-lifespan-restoration-paths.md` · `handoffs/2026-08-22-event-generation-weighting-pipeline.md` · `handoffs/2026-08-22-non-combat-decision-points.md` · `handoffs/2026-08-22-locationcodex-edge-granularity.md`

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- **Travel 为五类分类法之一；非常驻可选项；候选走 80 / 20 掷定** → `decisions/ADR-0002-adventure-event-taxonomy.md`。
- **location 框定 eventOptions、由 Travel 刷新**（方向已定）。

Source: `handoffs/2026-07-24-docs-restructure-class-model.md` · `handoffs/2026-08-15c-event-type-collapse-and-batch-shape.md`

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **Travel 一行的具体定价。** 结构性约束已定（> 0，且为常规事件基准的 1/3 ~ 1/2）；**绝对数字**留待内容扩充后的统计校准。→ `systems/balance.md`。
- **失去 flags 关地域后的运营替代。** location 恒启用 ⇒ 无法线上秒关一个问题地域。若日后确有此需求，需另设一条**不改图**的通道（例：把该地域的 `EventCountLimit` 压到 1 让人快速离开）；本次不预设形态。→ `systems/services/content-service.md`。

Source: `handoffs/2026-08-05b-location-fields-event-count-limit-and-skip-refill-closure.md` · `handoffs/2026-08-15c-event-type-collapse-and-batch-shape.md` · `handoffs/2026-08-16g-travel-mechanics-and-location-carrier.md`

## 对应
提炼至：`.claude/knowledge/systems/adventure-event/travel.md`（待建）
location（地域）主文档见：`systems/game-progression.md`。
