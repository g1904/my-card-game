# map-progression

> 每个 ante 的分支节点 map;位置;节点类型路径导航。

## 意图
> _设计意图,从 handoffs 中提炼。保持更新。_

- 一次 run 的结构为 **realm → chapter → AdventureEvent**。修炼阶梯(炼气 → 筑基 → 金丹 → 元婴)共四个 realm;一次 run 为**三个 chapter**,每个 chapter 是相邻两个 realm 之间的攀登。
- 在一个 chapter 内,进程由 **AdventureEvent 循环**驱动:玩家从当前可用的 AdventureEvent 中**选择一个 AdventureEvent** 来推进,每个 AdventureEvent 触发事件,改变玩家状态并塑造接下来会变为可用的内容。(节点类型路径导航 / 分支 map 形态待定。)
- **各 chapter 相互衔接。** 第 N+1 个 chapter 从第 N 个 chapter 的某个*可用结束点*开始——因此完成状态会分支,并为下一个 chapter 的起点埋下种子。
- 每个 chapter 边界都是角色档案上的一个**存档 / 记录点**(共三个);抵达元婴即为最终奖杯展示。
- 来源:`10-handoffs/2026-07-13.md`。

- **分支 map 的图编码(数据表达)。** AdventureEvent(原 encounter,现为唯一术语,见 `terminology.md`)。每个 `AdventureEvent` 持有 `List<possibleFutureEvent>`(向前分叉的可选历程)与 `List<pastEvent>`(已走过的历史轨迹)——即分支 map 的一种图结构编码:向前是 DAG 式的可选走向,向后是面包屑历史。CharacterProfile 以 `List<AdventureEvent>` 持有整段进程。Source: `10-handoffs/2026-07-15-adventure-event-profiles.md`。
- **节点形态 = 月圆之夜风格(已定案)。** 节点 / 修行事件的呈现**参考《月圆之夜》**——精心策划的事件菜单,而非 StS 式完全分支地图。**术语:`encounter` 已在全部设计文档中覆写为 `AdventureEvent`(唯一术语);代码 / 知识笔记中残留的 `encounter` / `EncounterData` 同样一律重构为 `AdventureEvent` / `AdventureEventData`(代码改名留待 blueprint / implement)。** Source: `10-handoffs/2026-07-22-...` + `10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。
- **篇章继承 = 全部继承(已定案)。** 读档续入下一 chapter 时,角色带入**上一篇章的全部信息**(deck、法宝、属性、叙事标记等),无逐项筛选。此项解锁本文档走向 `/derive-requirements`。Source: 同上。
- **选择界面 = 横向滑动选择区(已定案)。** 「从当前可用的 AdventureEvent 中选择」通过一个**可横向滑动的选择区**(horizontal scrolling area)呈现,玩家滑动以选中要继续的目标 AdventureEvent。契合月圆之夜风格的「事件菜单」形态,且贴合竖屏触控。Source: `10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。
- **AdventurePlot 调制 possibleFutureEvent(新,方向)。** 新抽象 **AdventurePlot(隐藏剧情线)** 是一棵分支可能性树,在背景中**影响角色的 `possibleFutureEvent`** ——即调制「向前会变为可用的走向」。隐藏属性(煞气 / 寿元)达阈值时驱动对应剧情线,改写后续可选事件;某些节点可像 DnD 那样让玩家选择分支。详见 `30-content/events.md`;编码方式(是调制既有 possibleFutureEvent 图,还是并行结构)待定。Source: 同上。

## 决策(-> ADR)
> _已定案的决定链接到 50-decisions/ADR-####。_

- **境界存档 · 篇章重试模型（四境三篇章、篇章衔接、重试无限/3/1）** → `50-decisions/ADR-0004-realm-checkpoint-retry-model.md`（Accepted）。

## 待决问题
> _尚未解决,需要一次 handoff/决策。_

- **「可用结束点」已明确**:到达下一境界所落的**存档点**(炼气→筑基存档、筑基→金丹存档)即结束点,可读档开始下一 chapter。**chapter 途中死亡 → 从该 chapter 起始存档重试**;炼气(第 1 chapter)近乎无限重试,后续 chapter 有限重试(数值见 `run-manager.md`)。Source: `10-handoffs/2026-07-15b-taxonomy-and-checkpoint-clarifications.md`。
- **篇章总数 = 四境三篇章(已确认)。** 重试上限:第一章(炼气→筑基)无限、第二章(筑基→金丹)3、第三章(金丹→元婴)1;草稿中的「第四章」为笔误,已废弃。Source: `10-handoffs/2026-07-22-online-cloud-combat-and-meta-clarifications.md`。

## 对应
提炼至:`.claude/knowledge/systems/map-progression.md`
