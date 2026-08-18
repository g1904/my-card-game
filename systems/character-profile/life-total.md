# lifeTotal（生命总量）

> **`lifeTotal` = 这个角色的生命值** —— 战斗外的耐久 / 失败惩罚承受量。战斗过程中不参与；只在战斗**收口时**按道念差被扣减，**通过 AdventureEvent 恢复**，**归 0 → 角色 `defeated`**。**单值，无上限字段、无上限截断**；炼气基线 10，进入更高境界时一次性跃升。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **只有 `lifeTotal` 一个字段：`lifeTotalLimit` 概念整体删除（承重）。** 角色**只跟踪当前耐久这一个值**——没有上限字段、没有上限截断、也没有「上限推拉」这回事。回复类事件直接给 `lifeTotal` 加值，失败按道念差扣 `lifeTotal`，归零即 `LifeTotalExhausted`。
  - **与 mana 的非对称是有意的，必须连同理由写清**（否则日后极易被当作不一致而「顺手统一」）：**mana 是每回合重置的节奏资源**，故需要 `currentMana / manaLimit` 两个字段；**耐久是跨事件累积的容错资源**，只需要一个数。

    | | 字段 | 推拉对象 | 上限 |
    |---|------|---------|------|
    | **mana** | `currentMana` + `manaLimit` | 事件推拉 **`manaLimit`**（±1，长期成长） | `currentMana` 每回合恢复到 `manaLimit` |
    | **耐久** | **`lifeTotal` 一个字段** | 事件 reward / cost 与战斗失败**直接加减** | **无上限** |

  - **「满血时喝药浪费」这一整类挫败感因此不存在**，且「提升耐久上限」这一档奖励并入「回复耐久」——**内容侧少一个旋钮、少一层解释**。
  - **玩家把 `lifeTotal` 堆得很高是他自己攒来的容错，不是漏洞**：`lifeTotal` 的真正压力来自寿元与篇章时长，堆耐久要花事件位，本身就有机会成本。
- **定名 = `lifeTotal`。** 领域词与**代码标识符**统一：`CharacterProfile.Status` 上是 **`lifeTotal`** 单值，**不设 `lifeTotalLimit` 一类的上限字段，也不写成 `currentHealth / healthLimit`**；`CombatResult` 上是 **`RemainingLifeTotal`**。
- **lifeTotal = 战斗外的耐久。** 它**不是战斗内的血量资源**：战斗过程中既不被消耗也不被读取，胜负由**道念（momentum）**判定（见 `systems/scoring.md`）。它承担的是**跨事件的耐久 / 失败惩罚承受量**——一条决定「还能失败几次」的战斗外资源线。
- **唯一扣减时刻 = 战斗 / 修炼失败的结算。** 战斗结束时若判负，角色损失 lifeTotal，损失量由「**角色道念 − 敌人道念**」的差值决定。战斗**过程中**不动 lifeTotal。
- **换算 = 1:1。** 道念差**就是**损失量：`lifeTotal -= (敌人道念 − 角色道念)`，中间不隔一层系数或分档。**不设上限截断：** 1:1 就是全部规则。**「一次惨败打穿耐久」的风险由赋级规则在规则层封住**——敌人赋级带三章统一为 `±2`（见 `systems/enemies/`、`systems/balance.md`），最坏情形是境界边界的跨越（炼气十三层 `baseMomentum` 15 遇筑基中期 24 = 落后 9），落在炼气基线 10 之内。**内容侧的遭遇编排纪律退为第二道防线**，不再是唯一防线。
- **境界基线 = 进入该境界时的一次性跃升（初值）。** 「跃升 + 无截断」共同维持上一条的规则层保证，**不再依赖任何上限字段**：

  ```
  lifeTotal 境界基线 ≈ ceil(1.1 × 该境界内可能出现的最坏开局落差)
  ```

  | 境界 | 带内最坏开局落差 | 境界基线 |
  |------|----------------|---------|
  | 炼气 | 9 | **10**（公式恰好复现之） |
  | 筑基 | 23 | **25** |
  | 金丹 | 35 | **40** |
  | 元婴 | —（终点，不产生遭遇） | **40**（仅供元婴界面展示） |

  - **余量系数 1.1 使既定的炼气 10 成为公式的一个解**，不必为第一篇章开特例；它把「最惨的一次失败几乎但不完全打穿耐久」这条隐含口径显式化，使 `baseMomentum` 表调整时基线能自动跟随。
  - **配套硬要求：回复类事件的单次幅度必须随境界基线跳档**（10 → 25 → 40 的量纲），否则后两章的回复事件不痛不痒。
  - **已知风险**：开局落差 ≠ 最终道念差（后者可能更大），1.1 的余量是否够取决于「一张牌产多少道念」——上表是**初值，不是安全证明**；三个基线之比（1 : 2.5 : 4）小于 `baseMomentum` 之比（约 1 : 2 : 5），故**跨境界容错率实际是收紧的**（越高越险，有意接受）。归 ch1 数值标杆专场回归校准。
- **归 0 = `defeated`（轮回级终结）。** lifeTotal 归 0 使角色 `status = defeated`——它与**寿元归 0（大限将至）**并列，是角色终结的**第二条路径**。二者分工清晰：**寿元按事件流逝，lifeTotal 按失败流逝**。**`DefeatReason` 里没有「输掉一场战斗」这一项**——战斗失败本身不终结角色，对应项是 `LifeTotalExhausted`；**Finale 失败同样走这条通道，不新增 `FinaleFailed`**（见 `systems/adventure-event/combat/`）。
- **恢复途径 = AdventureEvent。** lifeTotal 通过事件恢复——与等级、`manaLimit` 同属「由事件 cost / reward 推拉」的成长体系，走同一条 `ProfileChangeSpec` → `TryApply` 链路。**推论：回复类事件由此有了明确的玩法位置**——它是玩家在「继续冒险」与「补耐久」之间的常态权衡，也是「寿元 vs lifeTotal」两条资源线互相兑换的接口（花寿元买回耐久）。
- **取值域 `[0, ∞)`，归 0 构成终态。** `lifeTotal` 在 `ResourceElements` 表中占一行 `(Min = 0, Max = null, DepletionDefeat = DefeatReason.LifeTotalExhausted, CostModifier = null, GainModifier = null)`：**下界截断到 0**（负耐久无意义，且角色在归 0 那一刻即终结），**上界明确为空**——这正是「只跟踪单值、无上限截断」在施加侧的落地，表里的 `Max = null` 不是待填项而是定值。终态判定读表而非硬编码检查本字段，见 `systems/services/life-cycle-service.md`。
- **lifeTotal 是耐久，不是寿元。** 隐藏属性 **寿元 / lifeSpan** 是独立的**寿命预算**（炼气起始 100，递减到 0 → defeated），归隐藏属性 / PlotManager，不在本文件。

Source: `handoffs/2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md` · `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md` · `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md` · `handoffs/2026-08-02-momentum-conversion-reward-structure-and-mtg-stack.md` · `handoffs/2026-08-05-level-band-stack-save-and-token-free-deck.md` · `handoffs/2026-08-06d-combat-open-questions-mass-closure.md` · `handoffs/2026-08-16d-cost-side-closure.md`

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- **`life` 定名为 `lifeTotal`；归 0 → `defeated`；恢复途径 = AdventureEvent**。
- **lifeTotal 为战斗外耐久 / 失败惩罚承受量；战斗内不参与；按道念差扣减**。
- **`lifeTotalLimit` 概念整体删除，只跟踪单值、无上限截断；境界基线改由一次性跃升承载**。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **回复的幅度与来源分布（已归属专场）。** 「通过 event 恢复」已定，且**幅度必须随境界基线跳档**（10 → 25 → 40 量纲）；**单次回复多少**归**内容横向扩展阶段的「ch1 数值模型」session**；哪些事件类型给回复、回复的成本形态仍未定。→ `systems/adventure-event/`、`systems/balance.md`。

## 对应
提炼至：`.claude/knowledge/systems/character-profile/life-total.md`（待建）。
