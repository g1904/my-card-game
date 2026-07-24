# 系统 —— 设计意图索引

各游戏系统的动态设计文档。文件名与 `.claude/knowledge/systems/` 一一对应,因此每份文档恰好对应一条 knowledge 笔记。

| 文档 | 用途 | 对应 knowledge |
|-----|---------|-------------------|
| [run-manager](run-manager.md) | Run 生命周期:开始(seed)、推进、胜/负、清理。 | `systems/run-manager.md` |
| [map-progression](map-progression.md) | 每个 ante 的分支节点 map;位置;路径导航。 | `systems/map-progression.md` |
| [adventure-plot](adventure-plot.md) | 隐藏剧本层:剧本层级、隐藏属性驱动、Character key points、云端剧本服务。 | `systems/adventure-plot.md`（待建） |
| [adventure-event-combat](adventure-event-combat.md) | 回合结构、敌人意图/AI、结算。 | `systems/adventure-event-combat.md` |
| [deck-hand](deck-hand.md) | 抽牌/hand/弃牌、seeded 洗牌、deck 变更。 | `systems/deck-hand.md` |
| [card-resolution](card-resolution.md) | 费用、目标选择、效果流水线、触发器。 | `systems/card-resolution.md` |
| [energy-economy](energy-economy.md) | 每回合 energy;run 货币(gold)。 | `systems/energy-economy.md` |
| [relics-jokers](relics-jokers.md) | 通过事件触发器实现的被动修正。 | `systems/relics-jokers.md` |
| [scoring](scoring.md) | 计分模型(chips×mult 或并入战斗)。 | `systems/scoring.md` |
| [shop-rewards](shop-rewards.md) | Shop 库存、购买、升级、奖励。 | `systems/shop-rewards.md` |

> 只有在确有真实设计意图时,才在此新增系统文档;保持文件名与 knowledge 索引一致。
