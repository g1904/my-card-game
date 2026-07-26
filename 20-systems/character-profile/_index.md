# character-profile

> 角色信息 / **CharacterProfile** —— 单次 run / 单个角色的状态与历史（对齐 RunState 概念）。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **CharacterProfile = 单次 run / 单个角色的状态与历史。** 每个 CharacterProfile 对齐 **RunState** 概念：一次 run、一个角色所走过 / 可走的整段修行历程与当前状态。它由账号级的 **PlayerProfile** 持有（`List<CharacterProfile>`）。Source: `10-handoffs/2026-07-24-docs-restructure-class-model.md`（+ `20-systems/services/life-cycle-service.md`、`terminology.md`）。
- **CharacterProfile 的字段（大局骨架，细节未定）。** `status`（**ongoing | defeated | completed**）、`chapter`（当前篇章）、`Status`（`currentHealth / healthLimit`、`currentMana / manaLimit`，以及**隐藏属性** 道心 / faith、煞气 / malefic qi、寿元 / lifeSpan）、`List<AdventureEvent>`（修行历程）、角色级道具（见 `item/`）、run 货币 gold（见 `currency.md`），以及 **AdventurePlot key points**（剧情进度锚点；完整剧本内容不落存档，存于云端剧本服务）。Source: `20-systems/services/life-cycle-service.md`。
- **角色状态是终态收敛的状态机。** `status` 收敛为 `ongoing | defeated | completed`（`defeated` 内含 discarded、寿元归 0 等原因子类型）；`defeated` 与 `completed` 数据都会在 run 结束时被清理。→ 见 `20-systems/services/life-cycle-service.md` 与 `50-decisions/ADR-0004-realm-checkpoint-retry-model.md`。Source: `10-handoffs/2026-07-24-docs-restructure-class-model.md`。

## 子系统导航

| 子系统 | 文件 | 内容 |
|--------|------|------|
| 卡组 deck | `deck/_index.md`、`deck/common-properties.md` | 抽牌堆 / hand / 弃牌堆、seeded 洗牌、deck 变更；卡牌 / CardData 定义（费用、目标、效果流水线、触发器）；起始卡组等内容设计。 |
| 角色道具 item | `item/_index.md`、`item/common-properties.md` | 角色级道具（含道具设计内容；细节待定）。 |
| run 货币 currency | `currency.md` | run 货币 gold 的获取 / 消耗。 |
| 生命 life | `life.md` | 战斗血量；炼气基线 10/10；无曲线。 |
| 法力 mana | `mana.md` | 每回合出牌资源；上限 + 逐步恢复；炼气基线 5/5。 |

## 决策(-> ADR)
> _已定案的决定链接到 50-decisions/ADR-####。_

- **子系统结构（已定案）。** `deck` 与 `item` 为**文件夹**——除规则外还要容纳**内容设计**（起始卡组 starter decks、道具设计 item designs）；`life` / `currency` / `mana` 为**扁平 `.md`**——它们是系统性资源（systematic resource），预期规则足够短，暂以单文件承载。Source: `10-handoffs/2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md`。
- **境界存档 · 篇章重试模型**（CharacterProfile 状态机 `ongoing | defeated | completed`、全部继承、重试上限）→ `50-decisions/ADR-0004-realm-checkpoint-retry-model.md`（Accepted）。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **CharacterProfile 字段结构细节：** 各字段的具体 schema、隐藏属性完整清单与阈值、AdventurePlot key points 粒度仍待定。→ 见 `20-systems/services/life-cycle-service.md`、`20-systems/services/plot-manager.md`。

## 对应
提炼至：`.claude/knowledge/systems/character-profile/_index.md`（待建）。
