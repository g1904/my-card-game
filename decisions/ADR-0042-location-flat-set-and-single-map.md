# ADR-0042 — location 是平坦的内容条目集合 + 一份全局无向邻接表；三个篇章共用同一张图

- **状态：** Accepted
- **日期：** 2026-08-05
- **来源：** handoffs/2026-08-05b-location-fields-event-count-limit-and-skip-refill-closure.md, handoffs/2026-08-16g-travel-mechanics-and-location-carrier.md

## 背景

地域需要一个载体。三个方向摆在面前：C# 枚举、带层级 / 区域分组的树、或平坦的内容条目集合。同时，连边（哪两个地域相邻）要么由各 location 各持自己的边，要么由一份全局图承载。

## 决策

**location 是平坦集合的内容条目** `LocationData : Resource`——**无枚举、无层级、无区域分组，也不预留分组字段**；带三组字段（事件类型概率修正 · 敌人模板集合 · `eventCountLimit`）。

连边由**单份全局唯一的 `LocationMapData : Resource`** 承载，持一个**无向**边集；**不由各 location 持边**。

两者**恒启用、不受 flags 管辖**。**三个篇章共用同一张图**——location 不随篇章 / 境界变化。

字段面与图校验 → `systems/game-progression.md`；Travel 侧的消费 → `systems/adventure-event/travel/_index.md`。

## 理由

枚举把地域数**焊进程序集**，与 overlay 热更直接冲突——加一个地域就得发版。

各 location 各持边的形态里，`A→B` 与 `B→A` 分写两处，**漏写一处即单向边**：玩家走进去就出不来，而这属于「能上线、线上不可见」的一类错误。单份无向边集在结构上排除了它。

三章共用一张图：难度的篇章差异**不由「换一张更难的图」承载**，而由敌人赋级带承载（→ `ADR-0044`）。两条通道都能表达难度时，必须只留一条。

## 备选方案

- **C# 枚举 `Location {…}`** — 否决：地域数焊进程序集，与 overlay 热更冲突。
- **各 location 各持自己的边** — 否决：漏写即单向边，属「能上线、线上不可见」。
- **location 硬分池（这个地点只开放这一批事件）** — 否决：改为软的类型概率修正；硬分池只发生在敌人一侧。
- **location 分层 / 区域分组字段** — 否决：本作规模不需要，预留即负债。

## 后果

- `LocationMapData` 是单例内容，经 `Content.Single<T>()` 取（→ `ADR-0030`）。
- 恒启用的代价如实记下：**地域没有「线上秒关」这条运营手段**，出问题只能改 overlay、下次冷启动生效。这是为「图恒连通、Travel 恒可产出」付的价。
- `LocationCodex` 的显影粒度建立在顶点之上（→ `ADR-0027`）。
