# ADR-0064 — Explore 真身分布 = 条目池组成 × 既有加权抽取，不设第二套权重；Explore 定价自成一行

- **状态：** Accepted
- **日期：** 2026-08-17
- **来源：** handoffs/2026-08-17c-explore-reveal-mechanics.md

## 背景

Explore 是「一张遮罩卡，进去才知道是什么」。它的真身类型分布需要一个来源。直觉方案是给 `AdventureEventData` / `LocationData` / `PlotModulation` 三处各加一个 Explore 权重字段，让内容与剧本都能调它。

## 决策

**Explore 真身的类型分布 = Explore 条目池组成 × 既有加权抽取，不设第二套权重机制。** 三处数据类**一律不加 Explore 权重字段**。

**Explore 在 `lifeSpanCost` 定价表上自成一行，该行不得由真身推导。**

揭示机制与物化侧字段 → `systems/adventure-event/explore/_index.md`。

## 理由

三处各加一个权重字段，每加一个都要回答**谁有权改它**。而剧本若能改它，就等于**隔着遮罩改变玩家实际面对的类型分布，而玩家全程无感**——这是一条不可能被玩家察觉、也不可能被测试发现的操纵通道。

定价自成一行同理：若成本取自真身，Band 2 的精确展示会让玩家**用成本数值反推真身类型**，遮罩当场失效。

## 备选方案

- **给三处数据类各加一个 Explore 权重字段** — 否决：见理由，且引入不可察觉的操纵面。
- **Explore 成本取自真身** — 否决：成本数值成为真身的旁路情报。

## 后果

- `RevealedEventId` 与 `DestinationLocationId` 同属**揭示前不得进入呈现层**的字段（承重）。
- 取池期须过滤「真身同样 enabled」，否则放量开关对 Explore 静默失效。
- 揭示 = `eventStart` 内一次 `with` 派生，且 **resolver 按真身选取**（不按 `EventOption.EventType`）。
