# 内容 — 设计意图索引

内容的"是什么" — 先于已编写的 `.tres` 资源的设计意图。内容类型与 `.claude/knowledge/data/_index.md` 相对应。

| 文档 | 内容类型 | 提供给(knowledge) |
|-----|--------------|-------------------|
| [cards](cards.md) | 卡牌 / `CardData` | `data/_index.md` |
| [relics](relics.md) | Relic·Joker / `RelicData` | `data/_index.md` |
| [enemies](enemies.md) | 敌人 / `EnemyData` | `data/_index.md` |
| [encounters](encounters.md) | encounter / `EncounterData` | `data/_index.md` |
| [events](events.md) | event / `EventData` | `data/_index.md` |
| [blinds-antes](blinds-antes.md) | Blind·Ante / `BlindData` | `data/_index.md` |
| [balance](balance.md) | 平衡配置 / `BalanceData` | `data/_index.md` |

> 此处的设计意图使用稳定的字符串 **`Id`** 作为交叉引用键(绝不用名称/索引),与 data-resource 规则保持一致 — 这样一条设计条目可以直接映射到它的 `.tres`。
