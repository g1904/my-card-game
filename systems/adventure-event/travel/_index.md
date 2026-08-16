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

  - **该掷定对常规出场与配额闸门一律适用**——规则只有一条，不按场景分叉。
  - **Explore 揭示出的 Travel 必为随机那一档**（见 `../explore/_index.md`）——秘境把人带到别处，本就不该让人挑。
  - **20% 档不产生死局**：即便只剩一个目的地，轮回仍可推进（`selectCost` 无条件可支付）。
  - **推论：`LocationCodex` 的路线规划价值仍然成立，只是被打了折。** 八成的岔路口仍是有信息的选择，两成是被命运推着走——后者反而让「记连边」的知识有了「知道却用不上」的张力。
- **通过 location 换图，框定下一批可用事件。** location（地域）**框定 eventOptions** —— 它携带事件类型出现概率修正、一组特定的 `EnemyData`、以及 `eventCountLimit`（字段语义见 `systems/game-progression.md`）；Travel 事件是刷新 location 的手段。
- **Travel = 结构性闸门，不只是可选路由（承重）。** 玩家在当前 location 达到 `eventCountLimit` 后，**本批 eventOptions 收窄为仅剩 Travel**。承载它**只需一个既有字段**：Travel 选项以**最高 `eventPriority`（= 1）**出场即可封锁同批其余选项——本批的每一项本就都是必做项，**不需要额外的强制标记字段**。
  - **推论：地域迁移是被规则驱动的必经节点**，每个 location 都有一个确定的出口时刻。**进程的形状由此清晰：一次篇章 = 若干 location 的串联，location 之间由 Travel 缝合。**
  - **闸门给多个目的地：** 收窄后剩下的是**若干个并列的 Travel 选项**，各指向 **`locationMap`** 上当前 location 的一个邻接地域——**「去哪」本身是一次真实的玩家决策**（80% 的场景；另 20% 只给一个，见上）。**推论：这是逐批择一的线性进程里唯一一个带地理含义的分岔点**；因 `locationMap` 对玩家不可见，第一次走是盲选，随 `LocationCodex` 积累而变成有信息的选择——**跨轮回的知识增长在此变现**。
  - **Travel 不占用所在 location 的 `eventCountLimit` 配额：** 配额只计「选择进入并结算」的事件，**离开的动作本身不算做事**。
  - **推论：Travel 同时是死局兜底。** 配额用尽后 Travel 顶上，保证**任何时刻至少有一个可推进的选项**——且它必然可被选中（`selectCost` 无条件可支付，见 `../common-properties.md`）。

Source: `handoffs/2026-07-24-docs-restructure-class-model.md` · `handoffs/2026-08-05b-location-fields-event-count-limit-and-skip-refill-closure.md` · `handoffs/2026-08-15c-event-type-collapse-and-batch-shape.md`

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- **Travel 为五类分类法之一；非常驻可选项；候选走 80 / 20 掷定** → `decisions/ADR-0002-adventure-event-taxonomy.md`。
- **location 框定 eventOptions、由 Travel 刷新**（方向已定）。

Source: `handoffs/2026-07-24-docs-restructure-class-model.md` · `handoffs/2026-08-15c-event-type-collapse-and-batch-shape.md`

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **Travel 与 game-progression 的具体交互？** **触发时机与可达来源均已定案**（`eventCountLimit` 达成即收窄为仅剩 Travel；目的地取自 `locationMap` 的邻接集合）；仍待定：`locationMap` 与 location 的**载体形态与定名**（单份邻接表资源？各 location 持边？）。→ `systems/game-progression.md`。
- **80 / 20 掷定是否可被剧本调制？** 掷定规则本身已定案；**比例是全局常量还是可由 PlotManager 推拉**未定（剧本要表达「迷途」可以调高随机档的比例）。→ `systems/services/plot-manager.md`。
- **常规出场的概率？** 「非配额闸门时不保证出场」已定案；**出场概率由什么给出**（location 的事件类型概率修正？固定值？）未定。→ `systems/services/future-event-service.md`、`systems/game-progression.md`。
- **一次 Travel 刷新多少 / 何种事件？** location 换图后 eventOptions 的生成规则（数量、类型配比的运算形态）未定。→ `systems/services/future-event-service.md`、`../common-properties.md`。
- **Travel 的代价 / 风险？** 前往是否消耗资源、是否可能触发途中遭遇未定。**不存在「付不起因而走不了」的死锁**：`selectCost` 无条件可支付，付不起也能走——只是走完可能判负。
- **与篇章 / 境界推进的关系？** Travel 是否与篇章边界 / Finale 触发耦合未定。

Source: `handoffs/2026-08-05b-location-fields-event-count-limit-and-skip-refill-closure.md` · `handoffs/2026-08-15c-event-type-collapse-and-batch-shape.md`

## 对应
提炼至：`.claude/knowledge/systems/adventure-event/travel.md`（待建）
location（地域）主文档见：`systems/game-progression.md`。
