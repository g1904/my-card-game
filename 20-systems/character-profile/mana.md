# mana

> 法力 mana —— 每回合出牌资源（life + mana 双资源模型的资源侧）。上限 + 逐步恢复；炼气基线 5/5；恢复速率待定。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **出牌资源 = mana（已定方向）。** 每回合的能量采用 **mana** 模型，参考 **Magic: the Gathering** 与 **Hearthstone**——与 life + mana 战斗模型一致（见 `life.md`、`20-systems/adventure-event/combat/`）。对齐 `CharacterProfile.Status` 的 `currentMana / manaLimit`。Source: `10-handoffs/2026-07-22-online-cloud-combat-and-meta-clarifications.md`。
- **无 mana 曲线 · 上限 + 逐步恢复（已定案）。** **不采用递增曲线**（既非 Hearthstone 每回合 +1 上限，也非 MTG 打地）；mana 有一个**上限**，每回合**逐步恢复**（而非按曲线爬升，也非每回合全额刷满）。**炼气期标准基线（起始满值）：mana = 5/5。** Source: `10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。

## 决策(-> ADR)
> _已定案的决定链接到 50-decisions/ADR-####。_

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **恢复速率与成长待定（已收窄）。** 「上限 + 逐步恢复」已定案；**仅剩：** 每回合逐步恢复的**具体速率**（固定 +N？按上限比例？）、**manaLimit 随境界的成长**、更高境界（筑基 / 金丹 / 元婴）的 mana 基线，以及溢出 / 结转规则。→ 数值归 `20-systems/balance.md`。Source: `10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。

## 对应
提炼至：`.claude/knowledge/systems/character-profile/mana.md`（待建）。
