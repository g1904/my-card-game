# adventure-event / practice（AdventureEvent-Practice）

> 修炼：比试 / 切磋——低风险战斗式历练。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **修炼（Practice）= 战斗的变体（低风险历练）。** 语义为比试 / 切磋；与 Combat 一样**走战斗结算**，但风险较低。Source: `20-systems/adventure-event/_index.md`、`terminology.md`。
- **属于走战斗结算的两类之一。** 分类法中「仅 战斗（及其变体 修炼）走战斗结算」——Practice 复用 Combat 的 life + mana 回合制战斗模型。Source: `20-systems/adventure-event/_index.md`。

## 决策(-> ADR)
> _已定案的决定链接到 50-decisions/ADR-####。_

- **Practice 为分类法第一类，修炼 ≈ 比试** → `50-decisions/ADR-0002-adventure-event-taxonomy.md`。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **「低风险」的具体机制：** Practice 与 Combat 的差异（失败无惩罚 / 降低惩罚？life 不实际扣减？奖励更小？）未定。
- **对手来源：** Practice 是否复用 Combat 的敌人数据资源，或用独立的「切磋对手」定义未定。→ 亦见 combat 的 enemies 归属待决项。
- **与隐藏属性的交互：** 修炼是否推拉道心 / 煞气 / 寿元未定。→ `20-systems/services/plot-manager.md`。

## 对应
提炼至：`.claude/knowledge/systems/adventure-event/practice.md`（待建）
