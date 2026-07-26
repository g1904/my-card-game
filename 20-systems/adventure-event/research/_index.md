# adventure-event / research（AdventureEvent-Research）

> 闭关：钻研 / 潜修。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **闭关（Research）= 钻研 / 潜修。** 一种非战斗 AdventureEvent 子类型，走事件式结算；语义上是角色静修钻研。Source: `20-systems/adventure-event/_index.md`、`terminology.md`。
- **吸收「休养 / Rest」。** 休养 / Rest 不单列，并入 战斗 或 闭关——闭关承担其中的静养 / 修整语义。Source: `20-systems/adventure-event/_index.md`、`terminology.md`。

## 决策(-> ADR)
> _已定案的决定链接到 50-decisions/ADR-####。_

- **Research 为分类法第三类，闭关 ≈ 研究；休养并入闭关（或战斗）** → `50-decisions/ADR-0002-adventure-event-taxonomy.md`。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **闭关的具体机制：** 产出（回复 life？强化牌组？升级 / 领悟？推拉隐藏属性？）、代价（消耗时间 / 寿元？）均未定。
- **与卡牌 / 牌组系统的交互：** 闭关是否用于升级 / 移除卡牌（类 StS 的 rest/campfire）未定。→ `20-systems/character-profile/deck/`。

## 对应
提炼至：`.claude/knowledge/systems/adventure-event/research.md`（待建）
