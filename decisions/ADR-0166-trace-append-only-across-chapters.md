# ADR-0166 — 痕迹序列跨篇章只追加：`pastEvent` / `pastItemUse` 不在篇章边界清空、不随重试回滚

- **状态：** Accepted
- **日期：** 2026-09-06
- **来源：** handoffs/2026-09-06-completed-data-retention.md · answer-logs/log-completed-data-retention.md

## 背景

`pastEvent` / `pastItemUse` 是角色的痕迹序列。原草稿提议在篇章边界清空它们（理由：两屏摘要只关心「本篇章发生了什么」，跨篇章累计的序列会越滚越长）。但清空要同时松动四条已成文的纪律，而它援引的那条论据——`future-event-service` 的开局构筑判定式——经直读**不构成论据**。

## 决策

**`pastEvent` / `pastItemUse` 跨篇章一路追加：既不在篇章边界清空，也不随篇章重试回滚。**

**两屏摘要的「本篇章事件数」改由篇章起始 `Seq` 锚点求差**——记该篇章第一条 `pastEvent` 的 `Seq`，用它把本篇章的切片从跨篇章累计序列里切出来。

字段归类与锚点落点 → `systems/services/life-cycle-service.md`、`systems/character-profile/_index.md`。

## 理由

- **只追加是这两个序列的既有语义**：`Seq` 单调、`PastEventEntry` 是不可变痕迹（`ADR-0021`）。在边界清空等于让 `Seq` 的含义按篇章重置，而序列本身没有承载篇章维。
- **锚点求差比清空便宜**：它只多存一个整数，而清空要新建一套「本篇章坐标系」并回答重试时该坐标系如何回滚。
- **不随重试回滚**：重试是玩家又走了一遍，痕迹应当记录这一事实；回滚会让「这个角色经历过什么」变成一个可被改写的量。

## 备选方案

- **篇章边界清空 `pastEvent`**（草稿原案） — 否决：援引的开局构筑判定式经直读不构成论据，且清空要同时松动四条已成文纪律。
- **两屏摘要写死 `pastEvent.Count`** — 否决：跨篇章累计后该读数直接失真；`ux/screen-flow.md` 两处已改为锚点求差口径。

## 后果

- **序列长度随角色寿命单调增长**，是被接受的体积代价；它与 `ADR-0165` 的「ch3 通关档永久保留」同向，不另设截断。
- **任何「本篇章的 X 计数」都必须经锚点求差得到**，不得直接取序列长度——这条须在消费侧写明。
- 受约束的文档：`systems/services/life-cycle-service.md` · `systems/character-profile/_index.md` · `ux/screen-flow.md` · `decisions/ADR-0021-past-event-trace-schema.md` · `decisions/ADR-0122-batch-layer-inventory-commit-and-trace.md`。
