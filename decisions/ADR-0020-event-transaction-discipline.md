# ADR-0020 — 事件的事务纪律：收口是一次事务、一个存档点；事件内部的主动消费即时提交

- **状态：** Accepted
- **日期：** 2026-08-17
- **来源：** handoffs/2026-08-17d-exchange-mechanics-and-transaction-discipline.md

## 背景

原先的纪律只有一句「一个事件的收口是一次事务、一个存档点」。Exchange 落地时它立刻不够用了：商店里买第二件的灰显判据必须读**扣掉第一件之后**的余额，而攒到收口就要维护一份「已扣未提交」的影子余额。同样的形状还出现在古宝使用次数、刷新（reroll）与战斗内的即时写入上。

## 决策

**纪律改写为两句，适用面是全局、不限 Exchange：**

1. **一个事件的收口（`eventEnd`）是一次事务、一个存档点。** 收口那一次 `TryApply` 合并 `ResolveOutcome` + `lifeSpanCost` + 隐藏属性推拉 + `TraceElements`（本次 `PastEventEntry`）+ `EventStateChanges` + `RngElements`。
2. **事件内部的主动消费即时提交一次 `TryApply`，不攒到 `eventEnd`。** 每笔提交是一次 Profile 变更，走既有「变更后由 sync-service 上行」通道，**不新增存档点类型**。

**两条可判定判据：** 一笔操作是**玩家主动发起的消费且本身自足**（成本与产出在这一笔内闭合）→ 即时提交；属于事件走向的结算产物 → 并入收口。当前的即时提交实例：商店购买 · 售出 · 刷新 · 古宝使用次数 · 战斗内的资源变更。

**「记入 `pastEvent`」在事务之内，不是事务之后**——它经 `TraceElements` 与收口的其余各列同批提交。**`AppliedChange` 因此是「本次事件的最终账」**：由 life-cycle-service 在组装痕迹时把逐笔已提交的 spec 累加进来——**记账，不再施加**。

伪码、逐族载体与列剔除清单见 `systems/adventure-event/common-properties.md` 与 `systems/adventure-event/exchange/_index.md`。

## 理由

- **`CanAfford` 的正确性要求余额是真的。** 攒到收口就要维护影子余额，而它与 `Evaluate(spec)` 是两条路径——正是「`CanAfford` 与 `TryApply` 必须走同一条 pipeline」要防的分裂。
- **它堵死「买完退出重进拿回灵玉」**，与古宝使用次数即时写入是同一条理由。
- **一笔交易本身就是自足事务**（`−jade` + 一条产出），「全有或全无」在这一笔内已闭合，不需要跨笔原子性。
- **收口并入 `TraceElements` 的直接收益**：「一个事件的收口是一次事务、一个存档点」由**结构**兑现，而不再由「记得把两步写在一起」这条约定兑现。
- **接受的代价明写**：中途退出的玩家停在「已买两件、第三件没买」的状态——**这正是玩家的真实意图**，不是半成品状态。

## 备选方案

- **全部攒到 `eventEnd` 一次提交** — 否决：影子余额与 `CanAfford` 的路径分裂；且「买完退出重进拿回灵玉」的窗口打开。
- **为事件内消费新增一种存档点类型** — 否决：既有通道已够，新增只会让存档点清单多一条要各处同步的规则。
- **`AppliedChange` 只记收口那一次 `TryApply` 的入参** — 否决：履历 / 剧本 / 诊断读不出玩家在商店里做了什么。

## 后果

- **`AppliedChange` 不再与「收口那一次 `TryApply` 的入参」逐字段相等**，两者的一致性**不能再机械断言**。诊断与回放一律以「最终账」为准；需要区分「哪些是收口施加的」时靠逐笔提交自身的可追溯性日志。
- 累加时有一条**列剔除清单**：装的是整块状态快照而非一笔变更的列一律剔除（当前即 `EventStateChanges`）——不剔除会让一条战斗痕迹胖到几十上百 KB。另有**自指防呆**：`AppliedChange` 恒不含 `TraceElements`，落为 `ProfileManager` 入口断言。
- 刷新（reroll）由此长出一条承重要求：**刷新价与新库存必须落在同一次 `TryApply`**，且消耗了 `Shop` 子流的随机 ⇒ 该子流的 `State` / `DrawCount` 必须在同一次原子写内更新。
- 即时提交**不计软阻塞闸门**（闸门只数事件级存档点，连按刷新不会弹模态）。
- 影响文档：`systems/adventure-event/common-properties.md`（权威）· `systems/services/profile-service.md` · `systems/adventure-event/exchange/_index.md` · `systems/services/life-cycle-service.md` · `systems/services/combat-service.md` · `systems/services/sync-service.md`。
