# 跳过通道整体移除 · eventPriority 两档定形 · LocationCodex 记连边

- id: 2026-08-06c-skip-channel-removal-priority-two-tier-and-location-codex-edges
- date: 2026-08-06
- topic: systems/adventure-event/common-properties, systems/services/（future-event-service, life-cycle-service, profile-service）, systems/architecture, systems/game-progression, systems/player-profile/codex, systems/adventure-event/travel, terminology, program-overview, system-overview
- status: distilled
- distilled-to: terminology.md, systems/adventure-event/（common-properties.md, travel/_index.md, travel/common-properties.md）, systems/services/（future-event-service.md, life-cycle-service.md, profile-service.md, _index.md）, systems/architecture.md, systems/game-progression.md, systems/balance.md, systems/player-profile/（codex/_index.md, player-power/common-properties.md）, program-overview.md, system-overview.md, open-questions.md, open-questions/（02-event-options.md, 06-meta-progression.md, update-log.md）, answer-logs/log-0806b.md, `systems/services/（future-event-service.md, life-cycle-service.md, profile-service.md, combat-service.md, _index.md）`

## Intent（distilled）

**一句话：** eventOptions 专场第二场——**把「跳过」这条通道连同它的两个字段（`skipCost` / `ifMandatory`）整体删除**（选另一个事件本就等价于跳过其余），**`selectCost` 付不起不再是拒绝而是可推进行为**（支付 → 判定 → 判负则进失败流程），**`eventPriority` 定形为两档且只由 future-event-service 置位**，并**答结 `LocationCodex` 记连边**（跨轮回重建整张 `locationMap` 是设计目标）。

### ① `LocationCodex` 记连边 —— 跨轮回重建整张 `locationMap` 是设计意图（答结承重待答）

图鉴族第六本的词条**记「它通向哪些地域」**。玩家因此能在多次轮回中**把整张 `locationMap` 重建出来**——这不是要规避的泄露，而是**设计目标**。

- **「去过即记」的完整语义 = 去过 A 就记下 A 及 A 的连边。** 图鉴显影的不只是「我到过这里」，还有「从这里能去哪」。
- **推论 ①：`locationMap` 的不可见是「初见不可见」，不是「永远不可见」。** 轮回内不给俯瞰图这条不变；变的是**跨轮回的知识可以逼近那张图**。两者不冲突——玩家的地图在脑子里（在图鉴里），不在 HUD 上。
- **推论 ②：这条把「中长期规划感 / 方位感」的候选从「候选」推到了**能承担**。** Travel 闸门给多个并列目的地，而图鉴告诉你每个目的地又通向哪里 ⇒ **玩家能提前两步规划路线**，方位感有了确定的信息基础。
- **推论 ③：`LocationCodex` 是六本图鉴里唯一一本词条之间有拓扑关系的。** 其余五本是平坦的条目集合，它是一张**逐步显影的图**——存档形态仍是 id 集合（连边随 location 条目静态给出），但**呈现形态必然不同**（其余五本是列表 / 网格，它是一张图）。
- **推论 ④：它强化了「图不变」这条前置约束。** 玩家花几十个轮回拼出来的图若被改版重排，积累直接作废——`locationMap` 的稳定性从「设计选择」升格为**对玩家的隐性承诺**（内容热更可改 location 的字段，但改连边等于清空一份账号级资产）。

### ② `skipCost` 概念整体移除

`skipCost` **太复杂、不值得**——整个概念删除，不做保留、不做降级。

### ③ 跳过通道整体移除，`ifMandatory` 随之删除

**跳过（skip）这个玩法通道整体不做。** 理由是它本就是冗余的：**每完成一次选择，eventOptions 无论如何都会整批重算**——因此**选中某一个事件，本身就等价于跳过了同批的其余全部事件**。跳过通道只是把「不做这件事」额外做成了一个要付费、要留痕、要补位的独立机制，而玩家早已通过「选别的」得到了同样的结果。

- **`ifMandatory` 一并删除。** 它的唯一职责是封锁跳过通道；通道没了，字段失去对象。
- **它承载的设计意图不但没丢，反而更强了：** 「每批必有不可跳过项、打不过也得打」现在**升级为结构性事实**——**本批的每一项都是必做项**，唯一的推进方式就是择一进入，回避通道在规则层根本不存在。**不需要字段来表达它**。
- **`TryRefill`（单项补位）整个机制随之删除。** 补位只为「被跳过的那个位置空了」而存在；没有跳过就没有空位。**批次刷新只有一种形态：一次选择 → 整批重算。**
- **推论（字段面净减，一次删掉五处结构）：**

  | 结构 | 变化 |
  |------|------|
  | `EventOption` | 九字段 → **七字段**（删 `IsMandatory` / `SkipCost`） |
  | `EventOptionBatch` | 删 `AnySkippable`；删「每批至少一个 `IsMandatory`」的恒真不变式 |
  | `AdvanceMode { Select, Skip }` | **整个枚举删除**；`AdvanceEventAsync` 少一个参数、`EventResolved` 负载少一个字段 |
  | future-event-service API 面 | 五个方法 → **四个**（删 `TryRefill`） |
  | `CapabilityFlag` | 删 `ShowSkipCost`；modifier key 清单删 `skipCost` |

- **推论：`pastEvent` 只剩一种痕迹。** 「区分『进入并结算』与『跳过』两种痕迹」这个 schema 难题**直接消解**——每一条痕迹都是「进入并结算」。这是 `pastEvent` schema 待答项的净收窄（**未被选中的选项是否随批次快照一并归档，仍未定**，见 Open questions）。
- **推论：跳过侧的两条产出侧保证全部作废**（不生成付不起 `skipCost` 的事件 / 不生成整批全跳的批次）——前提消失。
- **推论：`eventCountLimit` 的计数口径简化。** 只剩「只计选择进入并结算的事件，Travel 不计」；「跳过不计入」失去对象。**一批 = 一次操作 = 一次配额消耗**，地域节奏变成一条干净的计数。
- **推论：Travel 闸门的承载机制简化为一个字段。** 配额用尽时 Travel 只需以**最高 `eventPriority`** 出场即可封锁其余选项；`ifMandatory = true` 那一半不再需要，「一批可以全部 mandatory 的第一个真实用例」这句表述随之作废。
- **推论：「跳过什么类型的事件反向影响剧本 / 隐藏属性」这条内容侧方向作废。** 剧本仍可读 `pastEvent` 的选择偏好——但读的是**选了什么**，不再有**回避了什么**这条信号（除非未选项也归档，见 Open questions）。

### ④ 付不起必做项 `selectCost` 的终态 = 支付即推进、支付后判定、判负进失败流程（答结承重待答）

**支付 `selectCost` 是一个可推进行为**——它**不因「付不起」而被拒绝**。流程改为：**照常支付 → 支付后做状态判定 → 若判负则进入既有的失败流程**。

- **推翻既定流程的一处明文：** `AdvanceEventAsync` 的 `TryApply(SelectCost) ← 付不起则拒绝，不产生任何写入`（同时写在 `architecture.md` 总则 8、`life-cycle-service.md`、`adventure-event/common-properties.md`、`program-overview.md` 阶段 4）。**「付不起 → 拒绝 → 回到呈现步」这条回路整体删除。**
- **推论 ①（承重）：死锁问题彻底闭合，且不是靠产出侧保证闭合的。** 「付不起唯一可选项 ⇒ 轮回无法推进」这个死局**在规则层不成立**——任何选项在任何资源状态下都可被选中。**future-event-service 因此不欠 `selectCost` 侧任何可负担性保证**（与 08-05b 「不需要可战胜保证」同一种收口方式：不给保护，给出口）。
- **推论 ②：这比「直接判负」更细腻。** 支付后**未必死**——付的是寿元才可能触发「大限将至」，付的是灵玉之类的非终结性资源则只是穷了。**终态由支付后的状态判定给出，而不是由「付不起」这个事实给出。**
- **推论 ③：「付不起」这个概念在事件选择面整体消失。** UI **不需要不可选 / 置灰态**；但**必须如实展示 `selectCost`**——玩家要能自己算出「这一步可能是最后一步」。**明知是死路仍然走**是一个有意义的玩家决策，与「打不过也得打」完全同构。
- **推论 ④：`AdvanceResult` 的 `CostRejected` / `MissingElement` 在事件推进路径上不再产生。** 它们是否整体删除，取决于是否还有别的消费点需要「余额不足即拒」（例如 Exchange 内的商店购买），见 Open questions。
- **推论 ⑤：`ProfileManager.TryApply` 的「全有或全无」不变，但「先全量校验付得起、否则整体拒绝」不再是它对事件推进的语义。** 事务性（单点提交、不半套写入）与可负担性校验是两件事，这次只拆掉后者。

### ⑤ `eventPriority` = 两档（0 / 1），由 future-event-service 赋值，PlotManager 不可改

取值域**只有两档**：`0`（常态，本批自由择一）与 `1`（有效可选集收窄为该档）。**置位方唯一：future-event-service**；**PlotManager 不得改变它**。

- **推论 ①（承重 · 边界澄清）：PlotManager 的调制面只调内容，不调选择约束。** 它能影响**哪些事件进池、以什么权重出现**，但**不能通过抬优先级来强制玩家做某件事**。剧本要表达强制性，只能靠**把候选池收窄**（整批只出这一类）——这是一条更诚实的表达方式：玩家看到的仍是「一批可选项」，而不是「一个被系统钉死的选项」。
- **推论 ②：选择约束至此只剩一条轴。** `ifMandatory` 已删，`eventPriority` 是**唯一**约束玩家选择权的字段；全库「两条约束轴」的表述作废。
- **推论 ③：`EffectivePriority` 的取值域 = {0, 1}**，`AnyHigherPriority` 之类的派生判断退化为一次布尔比较。字段是否从 `int` 退化为 `bool` 见 Open questions。
- **推论 ④：两档 ⇒ 不存在「优先级 2 压过优先级 1」的层叠语义**，Travel 闸门用的「最高优先级」就是 `1`，与剧情线的强制事件**共用同一档**——若两者同批出现，玩家在两者间自由择一（而非再分先后）。

## Open questions

- **「记连边」的显影粒度（新增 · 承重）。** 去过 A 之后，词条列出的是 **A 的全部邻接（含从未去过的 B，地名因此被提前看见）**，还是**只记已实际走过的那几条边**？前者才真正支持「提前两步规划路线」，也才让整张图在有限轮回内可重建；后者纯回溯、更保守。**本文按前者理解（这是「可跨轮回重建整张图」的必要条件），但需确认。**
- **哪些资源允许被打穿、各自的截断与终态判据（新增 · 承重）。** ④ 让 `selectCost` 无条件施加，于是必须回答：寿元归 0 = `defeated` 已定；**灵玉 / mana / 其余 element 打到负数怎么办**（截断到 0？允许为负？）、哪些资源的耗尽构成终态、哪些只是变穷。这直接决定 `ProfileManager.TryApply` 施加负值时的钳制规则。→ `systems/services/profile-service.md`、`systems/character-profile/currency.md`。
- **「余额不足即拒」还剩哪些消费点（新增）。** 事件推进路径已不需要它；Exchange 内的商店购买、其他主动消费点是否仍需？若全都不需要，`AdvanceResult.CostRejected` / `MissingElement` / `CanAfford` 可整体删除。→ `systems/services/profile-service.md`、`life-cycle-service.md`。
- **未被选中的选项是否随批次快照归档进 `pastEvent`（新增）。** 跳过痕迹消失后，「玩家回避了什么」这条信号也没了。若把整批快照（而非只有被选中的那一个）写进 `pastEvent`，剧本就能读出偏好，代价是快照体积成倍增长、直接压增量 push 粒度。→ `systems/adventure-event/common-properties.md`、`systems/services/sync-service.md`。
- **`Priority` 字段是否从 `int` 退化为 `bool`（新增 · 轻）。** 语义已确定为两档；保留 `int` 是留扩展余地，改 `bool` 是让类型说实话。
- **地域配额用尽的判定落点（收窄）。** 「补位落空 = 配额用尽」这条判据随 `TryRefill` 一并消失；`eventCountLimit` 用尽 → 收窄为仅剩 Travel 仍然成立，但它现在**只在整批重算时判定一次**（此前还有补位那一次）。判定时点需在 `ComputeEventOptions` / `RefreshAfterEvent` 上写实。

## Notes / triage

- 答结并移出待答清单：`LocationCodex` 记不记连边 · 付不起必做项 `selectCost` 的终态 · `eventPriority` 与 `ifMandatory` 的叠加规则（**以移除 `ifMandatory` 的方式消解**）· `eventPriority` 的取值域与置位方 · 已定稿批次存续期间资源下降（**前提消失而消解**）。见 `answer-logs/log-0806b.md`。
- 本次不评估 derive 就绪度。

## 待答清单账

答结 5 条 · 新增待答 5 条
