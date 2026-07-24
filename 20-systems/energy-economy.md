# energy-economy

> 每回合 energy;run 货币(gold)的获取/消耗。

## 意图
> _设计意图,从 handoffs 中提炼。保持更新。_

- **出牌资源 = mana(已定方向)。** 每回合的能量采用 **mana** 模型,参考 **Magic: the Gathering** 与 **Hearthstone**——与 life + mana 战斗模型一致(见 `20-systems/adventure-event-combat.md`)。角色 `Status` 已含 `currentMana / manaLimit` 字段(见 `20-systems/run-manager.md`)。Source: `10-handoffs/2026-07-22-online-cloud-combat-and-meta-clarifications.md`。
- **无 mana 曲线 · 上限 + 逐步恢复(已定案)。** **不采用递增曲线**(既非 Hearthstone 每回合 +1 上限,也非 MTG 打地);mana 有一个**上限**,每回合**逐步恢复**(而非按曲线爬升,也非每回合全额刷满)。**炼气期标准基线(起始满值):** life = **10/10**、mana = **5/5**。Source: `10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。

## 决策(-> ADR)
> _已定案的决定链接到 50-decisions/ADR-####。_

## 待决问题
> _尚未解决,需要一次 handoff/决策。_

- ~~**mana 曲线**~~ → **已定案:** 无曲线,采用「上限 + 逐步恢复」(见「意图」)。**仅剩:** 每回合逐步恢复的**具体速率**(固定 +N?按上限比例?)、**manaLimit 随境界的成长**、更高境界(筑基 / 金丹 / 元婴)的 life / mana 基线,以及溢出 / 结转规则。→ 数值归 `30-content/balance.md`。
- **run 货币(gold):** 获取 / 消耗尚未设计——与 `30-content/shop-rewards.md`、`交易 / Exchange` 事件关联。

## 对应
提炼至:`.claude/knowledge/systems/energy-economy.md`
