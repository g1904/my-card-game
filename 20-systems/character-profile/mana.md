# mana

> 法力 mana —— **战斗内的出牌资源**（战斗内另一半是道念 / momentum，负责计分与胜负）。**每回合恢复至 `manaLimit`**；`manaLimit` 由事件 cost / reward 推拉；炼气基线 5/5。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **出牌资源 = mana（已定方向）。** 每回合的出牌资源采用 **mana** 模型，其形态参考 **Magic: the Gathering** 与 **Hearthstone**。对齐 `CharacterProfile.Status` 的 `currentMana / manaLimit`。**战斗内的两个量是 mana（出牌）与道念（计分与胜负）**——life 已退到战斗外承接失败惩罚（见 `life-total.md`、`20-systems/scoring.md`）。Source: `10-handoffs/2026-07-22-online-cloud-combat-and-meta-clarifications.md` + `10-handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。
- **无 mana 曲线（已定案）。** 不采用递增曲线：既非 Hearthstone 式每回合 +1 上限，也非 MTG 式打地递增。**炼气期标准基线（起始满值）：mana = 5/5。** Source: `10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。
- **战斗中每回合的起始步恢复至上限（已定案 · 08-02b 精确化）。** 战斗内，每个回合的**起始步**、**回合归属方**的 `currentMana` **自动恢复到其当前 `manaLimit`**（满值），且恢复排在「回合开始时」触发**之前**。回合内未用完的 mana **不结转**。**恢复的只是归属方的 mana**——交互与优先权已移除（见 `20-systems/services/combat-service.md`），非归属方在对手回合无法出牌，其 mana 在那段时间没有用途，故 mana 的实际语义是「**每次轮到我时刷满**」。Source: `10-handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md` + `10-handoffs/2026-08-02b-stack-without-interaction-and-three-step-turn.md`。
- **`manaLimit` 的成长属于事件 cost / reward 范畴（已定案）。** 上限**不随境界自动成长**，而是由 AdventureEvent 的产出 / 成本推高或压低——它是 `ProfileChangeSpec` 的一个变更目标，与灵玉、道具、隐藏属性同属一套推拉体系。**`manaLimit` 下降时，战斗内每回合的恢复上限随之下降。** Source: 同上。
- **推论：mana 不是战斗内的节奏来源。** 每回合固定刷满意味着回合之间的资源量不变化——MTG / Hearthstone 的「曲线爬升」张力不存在。回合间的节奏张力由**道念的累积与反超**（见 `20-systems/scoring.md`）以及卡牌效果 / 敌人行为承担；构筑的长期成长体现在 `manaLimit` 的推拉上。Source: 同上 + `10-handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。
- **不设 `manaLimit` 下界护栏，不做死牌转化（已定案）。** `manaLimit` **下降是非常罕见的情形**，不值得为它专门设计下界护栏或「高费卡在费用被压低后转化为可用形态」的规则。极端情形下高费卡成为死牌是**可接受的**。Source: `10-handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。

## 决策(-> ADR)
> _已定案的决定链接到 50-decisions/ADR-####。_

- **无曲线 · 每回合恢复至 `manaLimit` · 上限由事件推拉** —— 已定案。Source: `10-handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md`。
- **不设下界护栏 / 死牌转化** —— 已定案（`manaLimit` 下降极罕见）。Source: `10-handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **`manaLimit` 推拉的分档未定。** 机制已定（由事件 cost / reward 推拉、可升可降），**下界护栏已明确不做**；仍待定：**哪些事件类型 / 具体事件**推高或压低、**单次幅度**。→ `20-systems/balance.md`、`20-systems/adventure-event/`。Source: `10-handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md` + `10-handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。
- **更高境界的 mana 基线。** 炼气 5/5 已定；上限既然由事件推拉，那么**进入筑基 / 金丹 / 元婴时是否另有一次基线跃升**（还是完全交给事件累积）未定。→ `20-systems/balance.md`。

## 对应
提炼至：`.claude/knowledge/systems/character-profile/mana.md`（待建）。
