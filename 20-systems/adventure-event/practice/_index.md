# adventure-event / practice（AdventureEvent-Practice）

> 修炼：比试 / 切磋——低风险战斗式历练。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **修炼（Practice）= 战斗的变体（低风险历练）。** 语义为比试 / 切磋；与 Combat 一样**走战斗结算**，但风险较低。Source: `20-systems/adventure-event/_index.md`、`terminology.md`。
- **属于走战斗结算的类型。** Practice 复用 Combat 的回合制战斗模型：**mana 出牌 + 道念定胜负**，失败时按道念差扣 life（见 `20-systems/scoring.md`）。Source: `20-systems/adventure-event/_index.md` + `10-handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。
- **复用 combat-service 的参战方结构（已定案）。** Practice 使用 **CharacterManager + EnemyManager**，与 Combat 同一套回合循环与参战方模型——它是 combat 的**变体**，差异在胜负条件、风险与奖励结构，不在代码结构。因此**切磋对手就是 Enemy**（各自持有卡组）。Source: `10-handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md`。
- **意图揭示规则同 Combat。** 按全局等级差三档揭示（见 `20-systems/services/combat-service.md`）；Practice 若被设计为「低风险历练」，其对手等级通常应落在容差内，天然给完整意图。Source: 同上。

## 决策(-> ADR)
> _已定案的决定链接到 50-decisions/ADR-####。_

- **Practice 为分类法第一类，修炼 ≈ 比试** → `50-decisions/ADR-0002-adventure-event-taxonomy.md`。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **「低风险」的具体机制：** Practice 与 Combat 的差异（失败无惩罚 / 降低惩罚？life 不实际扣减？奖励更小？）未定。
- **对手来源：** 对手为 Enemy 已定；仍待定它是**复用 Combat 的敌人条目**还是另立一批「切磋对手」条目。→ 亦见 combat 的 enemies 归属待决项。
- **与隐藏属性的交互：** 修炼是否推拉道心 / 煞气 / 寿元未定。→ `20-systems/services/plot-manager.md`。

## 对应
提炼至：`.claude/knowledge/systems/adventure-event/practice.md`（待建）
