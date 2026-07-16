# map-progression

> 每个 ante 的分支节点 map;位置;节点类型路径导航。

## 意图
> _设计意图,从 handoffs 中提炼。保持更新。_

- 一次 run 的结构为 **realm → chapter → encounter**。修炼阶梯(炼气 → 筑基 → 金丹 → 元婴)共四个 realm;一次 run 为**三个 chapter**,每个 chapter 是相邻两个 realm 之间的攀登。
- 在一个 chapter 内,进程由 **encounter 循环**驱动:玩家从当前可用的 encounter 中**选择一个 encounter** 来推进,每个 encounter 触发事件,改变玩家状态并塑造接下来会变为可用的内容。(节点类型路径导航 / 分支 map 形态待定。)
- **各 chapter 相互衔接。** 第 N+1 个 chapter 从第 N 个 chapter 的某个*可用结束点*开始——因此完成状态会分支,并为下一个 chapter 的起点埋下种子。
- 每个 chapter 边界都是角色档案上的一个**存档 / 记录点**(共三个);抵达元婴即为最终奖杯展示。
- 来源:`10-handoffs/2026-07-13.md`。

- **分支 map 的图编码(数据表达)。** encounter 已更名为 **修行历程 / AdventureEvent**(见 `terminology.md`)。每个 `AdventureEvent` 持有 `List<possibleFutureEvent>`(向前分叉的可选历程)与 `List<pastEvent>`(已走过的历史轨迹)——即分支 map 的一种图结构编码:向前是 DAG 式的可选走向,向后是面包屑历史。CharacterProfile 以 `List<AdventureEvent>` 持有整段进程。(具体节点 map 形态——完全分支 vs. 精心策划的历程菜单——仍待定。)Source: `10-handoffs/2026-07-15-adventure-event-profiles.md`。

## 决策(-> ADR)
> _已定案的决定链接到 50-decisions/ADR-####。_

## 待决问题
> _尚未解决,需要一次 handoff/决策。_

- **「可用结束点」已明确**:到达下一境界所落的**存档点**(炼气→筑基存档、筑基→金丹存档)即结束点,可读档开始下一 chapter。**chapter 途中死亡 → 从该 chapter 起始存档重试**;炼气(第 1 chapter)无限重试,后续 chapter 有限重试。Source: `10-handoffs/2026-07-15b-taxonomy-and-checkpoint-clarifications.md`。
- **各 chapter 之间继承哪些内容**(deck、relics/法宝、属性、叙事标记)仍未逐项敲定——读档续章时角色带入下一 chapter 的具体项待定。
- 每个 chapter 的节点 map 形态:完全分支(StS 风格)vs. 精心策划的 encounter 菜单(月圆之夜风格)?(AdventureEvent 的 possibleFutureEvent/pastEvent 图已定其数据编码,但玩法形态仍未定。)

## 对应
提炼至:`.claude/knowledge/systems/map-progression.md`
