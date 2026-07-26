# life

> 生命 life —— 战斗血量（life + mana 双资源模型的血量侧）。炼气基线 10/10；无曲线。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **life = 战斗血量（血量侧资源）。** 战斗采用参考 **Magic: the Gathering** 与 **Hearthstone** 的 **life + mana**（生命 · 法力）双资源模型。life 为血量，对齐 `CharacterProfile.Status` 的 `currentHealth / healthLimit`。Source: `10-handoffs/2026-07-22-online-cloud-combat-and-meta-clarifications.md`。
- **无曲线 · 炼气基线 10/10（已定案）。** life 不采用递增曲线；**炼气期标准基线（起始满值）：life = 10/10**。Source: `10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。
- **life 是血量，不是寿元。** 隐藏属性 **寿元 / lifeSpan** 是独立于血量 life 的寿命预算（炼气起始 100，递减到 0 → defeated），归隐藏属性 / PlotManager，不在本文件。见 `20-systems/services/plot-manager.md`。Source: `10-handoffs/2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md`。

## 决策(-> ADR)
> _已定案的决定链接到 50-decisions/ADR-####。_

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **更高境界 life 基线未定。** 炼气 10/10 已定；筑基 / 金丹 / 元婴的 life 基线，以及 `healthLimit` 随境界的成长仍待定。→ 数值归 `20-systems/balance.md`。Source: `10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。

## 对应
提炼至：`.claude/knowledge/systems/character-profile/life.md`（待建）。
