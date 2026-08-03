# lifeTotal（生命总量）

> **`lifeTotal` = 这个角色的生命值** —— 战斗外的耐久 / 失败惩罚承受量。战斗过程中不参与；只在战斗**结算时**按道念差被扣减，**通过 AdventureEvent 恢复**，**归 0 → 角色 `defeated`**。炼气基线 10/10；无曲线。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **定名 = `lifeTotal`（已定案 · 取代 `life`）。** 领域词与**代码标识符**统一为 `lifeTotal`：`CharacterProfile.Status` 上为 **`lifeTotal / lifeTotalLimit`**（`currentHealth / healthLimit` 作废）、`CombatResult` 上为 **`RemainingLifeTotal`**。含义就是「这个角色的生命值」。Source: `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。
- **lifeTotal = 战斗外的耐久（已定案）。** 它**不是战斗内的血量资源**：战斗过程中既不被消耗也不被读取，胜负由**道念（momentum）**判定（见 `systems/scoring.md`）。它承担的是**跨事件的耐久 / 失败惩罚承受量**——一条决定「还能失败几次」的战斗外资源线。Source: `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。
- **唯一扣减时刻 = 战斗 / 修炼失败的结算（已定案）。** 战斗结束时若判负，角色损失 lifeTotal，损失量由「**角色道念 − 敌人道念**」的差值决定。战斗**过程中**不动 lifeTotal。Source: 同上。
- **换算 = 1:1（已定案）。** 道念差**就是**损失量：`lifeTotal -= (敌人道念 − 角色道念)`，中间不隔一层系数或分档。**不设上限截断（已定案）：** 1:1 就是全部规则。「一次惨败打穿耐久」的风险**由内容设计侧规避**——遭遇编排不会给出会导致该结果的等级差，故规则层不加护栏、`lifeTotalLimit` 也不必被迫涨到与 `baseMomentum` 同量级。**推论：约束转移到了内容侧**——future-event-service 的敌人赋级规则须把「最坏情况下的道念差」控制在当前 `lifeTotal` 可承受范围内。Source: `handoffs/2026-08-02-momentum-conversion-reward-structure-and-mtg-stack.md`。
- **归 0 = `defeated`（已定案 · 轮回级终结）。** lifeTotal 归 0 使角色 `status = defeated`——它与**寿元归 0（大限将至）**并列，是角色终结的**第二条路径**。二者分工清晰：**寿元按事件流逝，lifeTotal 按失败流逝**。连带：`DefeatReason` 中原先的 `CombatLost` 作废（战斗失败本身不终结角色），改为 `LifeTotalExhausted`。Source: `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。
- **恢复途径 = AdventureEvent（已定案）。** lifeTotal 通过事件恢复——与等级、`manaLimit` 同属「由事件 cost / reward 推拉」的成长体系，走同一条 `ProfileChangeSpec` → `TryApply` 链路（见 `systems/services/life-cycle-service.md`）。**推论：回复类事件由此有了明确的玩法位置**——它是玩家在「继续冒险」与「补耐久」之间的常态权衡，也是「寿元 vs lifeTotal」两条资源线互相兑换的接口（花寿元买回耐久）。Source: 同上。
- **无曲线 · 炼气基线 10/10。** lifeTotal 不采用递增曲线；**炼气期标准基线（起始满值）= 10/10**。Source: `handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。
- **lifeTotal 是耐久，不是寿元。** 隐藏属性 **寿元 / lifeSpan** 是独立的**寿命预算**（炼气起始 100，递减到 0 → defeated），归隐藏属性 / PlotManager，不在本文件。见 `systems/services/plot-manager.md`。Source: `handoffs/2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md`。

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- **`life` 定名为 `lifeTotal`；归 0 → `defeated`；恢复途径 = AdventureEvent** —— 已定案。Source: `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。
- **lifeTotal 为战斗外耐久 / 失败惩罚承受量；战斗内不参与；按道念差扣减** —— 已定案。Source: `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **更高境界的基线。** 炼气 10/10 已定；筑基 / 金丹 / 元婴的基线未定。**这是一个普通的数值待办，不是承重矛盾**——1:1 换算下的「一次惨败打穿耐久」已由**内容设计侧的等级差约束**规避，故上限不必被迫与 `baseMomentum` 同量级。→ `systems/balance.md`。Source: `handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md` + `handoffs/2026-08-02-momentum-conversion-reward-structure-and-mtg-stack.md`。
- **回复的幅度与来源分布（已归属专场）。** 「通过 event 恢复」已定；**单次回复多少**明确推迟到**内容横向扩展阶段的「ch1 数值模型」session**；哪些事件类型给回复、回复的成本形态仍未定。→ `systems/adventure-event/`、`systems/balance.md`。Source: `handoffs/2026-08-02-momentum-conversion-reward-structure-and-mtg-stack.md`。
- **`lifeTotalLimit` 是否也由事件推拉。** `manaLimit` 已定为「由事件 cost / reward 推拉、不随境界自动成长」（见 `mana.md`）；上限是否采用同一模型，还是保留境界基线跃升，未陈述。→ `systems/balance.md`。Source: `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md`。

## 对应
提炼至：`.claude/knowledge/systems/character-profile/life-total.md`（待建）。
