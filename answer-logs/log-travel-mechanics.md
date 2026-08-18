# Answer log travel-mechanics

- 日期：2026-08-16
- 来源：`inbox/solution-draft-travel-mechanics.md` → `handoffs/2026-08-16g-travel-mechanics-and-location-carrier.md`
- 移出条数：**4**（2 条整条移出 · 2 条部分收窄后仍留在清单）

## 整条移出（2）

**Travel 的常规出场概率，以及 80 / 20 是否可被剧本调制**（原 `open-questions/02-event-options.md`）
→ **常规出场 = location 的事件类型出现概率修正里的 Travel 一行**，与其余四类走同一条加权抽取，不设第二个机制、不新增字段；**Travel 一行可被修正到 0 是安全的**（闸门是独立通道，死局兜底不受影响）。
→ **80 / 20 是全局常量 `TravelFullFanoutChance = 0.80`，PlotManager 不得推拉**：它改的是玩家选择空间的宽窄，落在约束面，而 PlotManager 的边界是「只调内容不调约束」；且 `LocationCodex` 的跨轮回积累会在玩家无感知处失效。「迷途」改由多放 Explore 条目表达。
（归档去向：`systems/adventure-event/travel/_index.md` · `systems/balance.md` · `systems/services/future-event-service.md`）

**location 与 `locationMap` 的数据载体**（原 `open-questions/02-event-options.md`）
→ **`[GlobalClass] LocationData : Resource`**（不设 C# 枚举）+ **单份全局唯一的 `LocationMapData`**（无向边集，边为 `LocationEdgeData`，不由各 location 持边）。
→ **`Id` 照全库既定的两段式** `location.bamboo_sea`；**平坦集合，无层级、无分组字段**。
→ **两者都是结构性查表类内容，恒启用**：`ContentEnabled == false` → 加载期 `PushError`，解析走 `AllIncludingDisabled()`，**flags 对其不生效**。判据由「能被抽取的才配有开关」细化为「**结构顶点身份优先于抽取身份**」。
→ 八条加载期校验落定（多份/零份图 · 悬空 `Id` · 自环/重复边 · 出度 > 5 · 出度 == 0 · 图不连通 · `ContentEnabled == false` · `EventCountLimit <= 0`）。
（归档去向：`systems/game-progression.md` · `systems/services/content-service.md` · `terminology.md` · `content/_index.md`）

## 部分答定（2 —— 剩余部分仍留在待答清单）

**各类型的结算 / 机制细化**（`open-questions/03-adventure-event-types.md`）
→ **Travel 那一段整段收口**：常规出场概率 · 80/20 可否调制 · 换图后刷新多少何种事件（**无特殊规则，一次普通的整批重算**）· Travel 自身的代价（**定价表的 Travel 行，> 0 且为常规事件基准的 1/3 ~ 1/2**）与风险（**不设途中遭遇**，风险面 = 可能走到更不利的地域）。
→ **仍待设计：Exchange · Research · Explore** 三类的通用结算器数据形态。
（归档去向：`systems/adventure-event/travel/_index.md` · `systems/adventure-event/travel/common-properties.md` · `systems/balance.md`）

**location 机制细节**（`open-questions/03-adventure-event-types.md`，整条移出）
→ **地域的枚举 / 层级：无——本作 location 是平坦集合**，不设枚举、不设层级、不预留分组字段。
→ **Travel 如何映射到具体 location**：目的地取自 `LocationMapData` 上当前 location 的邻接集合（取全量图，不经 `AllEnabled()`）。
→ **一个 location 开放哪些事件池**：不硬分池，由类型修正软框定（既有定案）。
→ **location 是否随篇章 / 境界变化**：**不变，三章共用同一张图**；篇章切换时当前 location 继承，`CurrentLocationId` 跨篇章持久。
（归档去向：`systems/game-progression.md` · `systems/character-profile/_index.md`）
→ **仍留在别处的相关未答项**：`open-questions/02-event-options.md` 的「事件类型修正的运算形态」「批次规模区间两端由什么驱动」「`LocationCodex` 记连边的显影粒度」三条不受本次影响。

## 本次新增的待答（未移出，记此备查）

- **失去 flags 关地域后的运营替代**——location 恒启用是本次为「图恒连通、Travel 恒可产出」付的价；若日后确有「线上必须立刻停用某地域」的需求，需另设一条不改图的通道。落在 `systems/adventure-event/travel/_index.md` 的待决问题。
