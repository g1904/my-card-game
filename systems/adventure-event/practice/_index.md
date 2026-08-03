# adventure-event / practice（AdventureEvent-Practice）

> 修炼：比试 / 切磋——低风险战斗式历练。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **修炼（Practice）= 战斗的变体（低风险历练）。** 语义为比试 / 切磋；与 Combat 一样**走战斗结算**，但风险较低。Source: `systems/adventure-event/_index.md`、`terminology.md`。
- **属于走战斗结算的类型。** Practice 复用 Combat 的回合制战斗模型：**mana 出牌 + 道念定胜负**，失败时按道念差扣 life（见 `systems/scoring.md`）。Source: `systems/adventure-event/_index.md` + `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。
- **复用 combat-service 的参战方结构（已定案）。** Practice 使用 **CharacterManager + EnemyManager**，与 Combat 同一套回合循环与参战方模型——它是 combat 的**变体**，差异在胜负条件、风险与奖励结构，不在代码结构。因此**切磋对手就是 Enemy**（各自持有卡组）。Source: `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md`。
- **Practice = 三档难度中的「小盲」（已定案）。** Practice / Combat / Finale 对位 Balatro 的 **small / big / boss blind**——Practice 是**最轻的一档**。**「低风险」由难度旋钮直接承担**：Practice 的**胜负条件与回合数均可相对 Combat 改写**，整体**比 Combat 更简单**。**推论：不必靠「失败不扣惩罚」这类特例来实现低风险**——把回合数与胜负门槛拧松即可，结算规则与 Combat 保持同一套。标准 Combat 是 10 回合、道念高者胜；Practice 的具体改写值未给，见待决问题。Source: `handoffs/2026-08-02-momentum-conversion-reward-structure-and-mtg-stack.md`。
- **意图揭示规则同 Combat。** 按全局等级差三档揭示（见 `systems/services/combat-service.md`）；Practice 若被设计为「低风险历练」，其对手等级通常应落在容差内，天然给完整意图。Source: 同上。

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- **Practice 为分类法第一类，修炼 ≈ 比试** → `decisions/ADR-0002-adventure-event-taxonomy.md`。
- **Practice = small blind 档，回合数与胜负条件可相对 Combat 改写、整体更简单** —— 已定案。Source: `handoffs/2026-08-02-momentum-conversion-reward-structure-and-mtg-stack.md`。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **「更简单」的具体改写值：** 方向已定（回合数与胜负条件可变、整体比 Combat 简单）；仍待定 Practice 是**更少回合**（更快收束）还是**更多回合**（更宽容），胜负门槛如何放宽，以及奖励是否相应变薄。→ `systems/scoring.md`、`systems/balance.md`。Source: `handoffs/2026-08-02-momentum-conversion-reward-structure-and-mtg-stack.md`。
- **对手来源：** 对手为 Enemy 已定；仍待定它是**复用 Combat 的敌人条目**还是另立一批「切磋对手」条目。→ 亦见 combat 的 enemies 归属待决项。
- **与隐藏属性的交互：** 修炼是否推拉道心 / 煞气 / 寿元未定。→ `systems/services/plot-manager.md`。

## 对应
提炼至：`.claude/knowledge/systems/adventure-event/practice.md`（待建）
