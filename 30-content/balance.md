# balance

> 可调的全局数值:每回合 energy、ante 曲线、掉落权重。

## 意图
> _从 handoffs 中提炼的设计意图。保持更新。_

- **炼气期战斗基线(起始满值):** 生命 life = **10 / 10**、法力 mana = **5 / 5**。mana 采用**无曲线 · 上限 + 逐步恢复**模型(见 `20-systems/energy-economy.md`)。这些是可调数值,存入 `.tres` 而非硬编码。Source: `10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。

## 决策(-> ADR)
> _已敲定的决定链接到 50-decisions/ADR-####。_

## 待解问题
> _尚未解决,需要一次 handoff/决策。_

- **mana 逐步恢复速率 / 上限成长:** 每回合恢复量(固定 +N?按比例?)、manaLimit 随境界成长、更高境界(筑基 / 金丹 / 元婴)的 life / mana 基线待定(炼气仅给了 10/10 · 5/5)。→ `20-systems/energy-economy.md`。
- **重试上限是否作平衡项再调:** 无限 / 3 / 1 已定案(`20-systems/run-manager.md`);若后续视作可调平衡项则归此。

## 提供给
提炼进:`.claude/knowledge/data/_index.md`
