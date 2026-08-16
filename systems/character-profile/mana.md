# mana

> 法力 mana —— **战斗内的出牌资源**（战斗内另一半是道念 / momentum，负责计分与胜负）。**每回合恢复至 `manaLimit`**；`manaLimit` 由事件 cost / reward 推拉；炼气基线 5/5。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **出牌资源 = mana（已定方向）。** 每回合的出牌资源采用 **mana** 模型，其形态参考 **Magic: the Gathering** 与 **Hearthstone**。对齐 `CharacterProfile.Status` 的 `currentMana / manaLimit`。**战斗内的两个量是 mana（出牌）与道念（计分与胜负）**——life 已退到战斗外承接失败惩罚（见 `life-total.md`、`systems/scoring.md`）。
- **无 mana 曲线。** 不采用递增曲线：既非 Hearthstone 式每回合 +1 上限，也非 MTG 式打地递增。**炼气期标准基线（起始满值）：mana = 5/5。**
- **战斗中每回合的开始阶段恢复至上限。** 战斗内，每个回合的**开始阶段**、**回合归属方**的 `currentMana` **自动恢复到其当前 `manaLimit`**（满值），且恢复排在「回合开始时」触发**之前**。回合内未用完的 mana **不结转**。**恢复的只是归属方的 mana**——本作没有交互与优先权（见 `systems/services/combat-service.md`），非归属方在对手回合无法出牌，其 mana 在那段时间没有用途，故 mana 的实际语义是「**每次轮到我时刷满**」。
- **`manaLimit` 的成长属于事件 cost / reward 范畴。** 上限**不随境界自动成长**，而是由 AdventureEvent 的产出 / 成本推高或压低——它是 `ProfileChangeSpec` 的一个变更目标，与灵玉、道具、隐藏属性同属一套推拉体系。**`manaLimit` 下降时，战斗内每回合的恢复上限随之下降。**
- **推论：mana 不是战斗内的节奏来源。** 每回合固定刷满意味着回合之间的资源量不变化——MTG / Hearthstone 的「曲线爬升」张力不存在。回合间的节奏张力由**道念的累积与反超**（见 `systems/scoring.md`）以及卡牌效果 / 敌人行为承担；构筑的长期成长体现在 `manaLimit` 的推拉上。
- **不设 `manaLimit` 下界护栏，不做死牌转化。** `manaLimit` **下降是非常罕见的情形**，不值得为它专门设计下界护栏或「高费卡在费用被压低后转化为可用形态」的规则。极端情形下高费卡成为死牌是**可接受的**。

- **`manaLimit` 的单次变动幅度恒为 1，不设 ±2 档。** 炼气基线 5/5 下，`+1` = **出牌预算 +20%**，已是玩家能明确感知的一档；`+2` = +40%，一次事件就能改写整个卡组的可打出性，**与「长期成长应是细步累积、不是跳变」不符**。幅度恒为 1 也让 `ProfileChangeSpec` 侧极简、玩家心算容易（「这个事件给不给 mana」是二元的）。
- **推拉的事件分档（内容编排口径）：**

  | 事件类型 | 推高 | 压低 | 说明 |
  |---------|------|------|------|
  | **闭关 Research** | **主通道 · 常见** +1 | — | 「钻研 / 潜修」在叙事上就是提升法力容量；且其 cost 侧天然是寿元 / 灵玉 ⇒ 形成**「花寿元换永久出牌力」这条核心权衡** |
  | **战斗 Combat · `Finale` 档** | **每篇章一次** +1 | — | 突破奖励的一部分，**保证每章至少 +1 的保底成长**，不完全依赖路线运气 |
  | **交易 Exchange** | 稀有 +1（高价灵玉购买 / 拜师 / 传功） | — | 给灵玉一个长期价值出口；社交风味的传功条目同走此行 |
  | **战斗 Combat · `Standard` / `Practice` 档** | **不给** | — | 战斗奖励已有「按道念差加厚」这条厚度轴；再叠 `manaLimit` 会让强者恒强、放大滚雪球 |
  | 前往 Travel | — | — | 纯路由，不带 `ProfileChangeSpec` 产出 |
  | **探索秘境 Explore** | 继承揭示后的实际类型 | 同 | 元类型，无自己的口径 |

  - **压低只以「负向奖励条目」的形态出现**（包在 reward 里，与业障进卡组同一个位置），不另立结构——与「下降极罕见、不设下界护栏」一致。
  - **⚠「战斗不给 `manaLimit`」是一条会被质疑的取向**：它让战斗成为**纯消耗**（花 lifeTotal 风险换灵玉 / 卡牌 / 经验），成长上限全靠非战斗事件。**这是有意的分工**（避免滚雪球），但若篇章内战斗占比过高，玩家会感到成长停滞——**须与事件池分布一并校准**。
  - **分档表本质上是取向**（「闭关是主通道」符合叙事，但也可以是「秘境才是主通道」），改动成本低（改的是事件内容的 reward 配置，不是规则）。
- **篇章预算感：一章内 `manaLimit` 净增 +1~+2**（炼气起 5 → 第一篇章末 6~7）。推导：`manaLimit` 每 +1，可打出的牌约多 0.5 张 / 回合 ≈ 2.5 张 / 场；而**一场的手牌流入约 14 张（起手 4 + 5×2）、手牌上限 7** —— 若 `manaLimit` 膨胀过快会出现「有 mana 没牌打」，mana 重新变成沉没成本。**上限收紧为 7 后这条耦合更紧**：牌流的有效上界被上限咬掉一截，`manaLimit` 的增长空间随之变窄。**牌流是 `manaLimit` 增长的天花板**，这是两条数值线的真实耦合点，须在 ch1 数值标杆专场一并回归。

Source: `handoffs/2026-07-22-online-cloud-combat-and-meta-clarifications.md` · `handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md` · `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md` · `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md` · `handoffs/2026-08-02b-stack-without-interaction-and-three-step-turn.md` · `handoffs/2026-08-06d-combat-open-questions-mass-closure.md`

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- **无曲线 · 每回合恢复至 `manaLimit` · 上限由事件推拉**。
- **不设下界护栏 / 死牌转化**（`manaLimit` 下降极罕见）。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **`manaLimit` 下降（−1）的承载点。** 「罕见 −1（走火入魔类）」此前挂在探索秘境上；Explore 现为纯元类型、无自己的产出口径，而它可揭示的三类（Combat / Travel / Exchange）都不是自然的走火入魔场景。**下降是否改挂 Research（闭关走火入魔，叙事更贴）、还是接受「本作没有 `manaLimit` 下降」**，未定。**注意它牵动一条既有判断**：下降此前被记为「唯一常见的下降来源」，取消它等于让 `manaLimit` 变成单调不减。→ `systems/adventure-event/research/_index.md`、`systems/balance.md`。
- **更高境界的 mana 基线。** 炼气 5/5 已定；上限既然由事件推拉、且一章净增仅 +1~+2，那么**进入筑基 / 金丹 / 元婴时是否另有一次基线跃升**（还是完全交给事件累积）未定。**注意它与 `lifeTotal` 的分工不同**：`lifeTotal` 已定为境界跃升（见 `life-total.md`），mana 尚未表态。→ `systems/balance.md`。

## 对应
提炼至：`.claude/knowledge/systems/character-profile/mana.md`（待建）。
