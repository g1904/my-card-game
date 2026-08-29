# ADR-0043 — `eventCountLimit` 用尽即 Travel 以最高 `eventPriority` 出场；Travel 由可选路由升格为结构性闸门

- **状态：** Accepted
- **日期：** 2026-08-05
- **来源：** handoffs/2026-08-05b-location-fields-event-count-limit-and-skip-refill-closure.md

## 背景

若地域迁移是纯粹可选的，玩家会停在最优地域反复刷事件；而地域的差异（事件类型概率修正、敌人模板集合）也就失去意义。同时需要一个机制保证轮回不会因为某地域产不出事件而死锁。

## 决策

每个 location 带一个 `eventCountLimit` 配额。**配额用尽即由 Travel 以最高 `eventPriority` 出场**——地域迁移因此是**被规则驱动的必经节点**。

**Travel 由「可选路由」升格为结构性闸门。** 它同时是批次收缩时的保底出口。

配额语义（不可被剧本调制）→ `systems/game-progression.md`；闸门形态与结算写入判据 → `systems/adventure-event/travel/_index.md`。

## 理由

配额把「在这个地域能待多久」变成内容可编排的量，同时使地域差异真的作用于玩家——不迁移就无事可做。

作为保底出口，Travel 是唯一一类**恒有候选**的事件（目的地取自邻接集合，而图恒连通，→ `ADR-0042`），因此它是死局兜底的自然人选：任何其他类型都可能因池空而产不出。

## 备选方案

- **地域迁移完全可选** — 否决：玩家会停在最优地域，地域差异失效。
- **另设一个独立的「无事可做」兜底事件** — 未采纳：Travel 已恒可产出，另设即第二条兜底路径。

## 后果

- Travel 使用 `eventPriority = 1`，但它**没有 `IsMandatory` 字段**——闸门语义由 priority 表达（→ `ADR-0047`）。
- Travel 不计入 `eventCountLimit` 本身，也不适用回寿禁令。
- 结算写入的判据是 `DestinationLocationId != ""` 而非 `EventType == Travel`——因为 Explore 揭示出的 Travel 真身同样要写。
