# character-profile

> 角色信息 / **CharacterProfile** —— 单次轮回 / 单个角色的状态与历史（对齐 CycleState 概念）。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **CharacterProfile = 单次轮回 / 单个角色的状态与历史。** 每个 CharacterProfile 对齐 **CycleState** 概念：一次轮回、一个角色所走过 / 可走的整段修行历程与当前状态。它由账号级的 **PlayerProfile** 持有（`List<CharacterProfile>`）。Source: `handoffs/2026-07-24-docs-restructure-class-model.md`（+ `systems/services/life-cycle-service.md`、`terminology.md`）。
- **CharacterProfile 的字段（大局骨架，细节未定）。** `status`（**ongoing | defeated | completed**）、`chapter`（当前篇章）、**`realm` + `level`（境界与境界内等级，见 `systems/game-progression.md`）**、`Status`（`lifeTotal / lifeTotalLimit`、`currentMana / manaLimit`，以及**隐藏属性** 道心 / faith、煞气 / malefic qi、寿元 / lifeSpan）、`List<AdventureEvent>`（修行历程）、角色级道具（见 `item/`）、角色能力 `List<CharacterPower>`（见 `power/`）、轮回货币 jade（见 `currency.md`），以及 **AdventurePlot key points**（剧情进度锚点；完整剧本内容不落存档，存于云端剧本服务）。Source: `systems/services/life-cycle-service.md` + `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md`。
- **`realm` + `level` 是角色的修行位置（已定案）。** 二者合成**全局等级序**上的位置，是敌人意图三档揭示的判据；篇章突破后 `level` 归位为新境界的初期。**`manaLimit` 不随境界自动成长**，由事件 cost / reward 推拉（见 `mana.md`）。Source: `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md`。
- **决策点存档（已定案）。** 事件推进过程中（含战斗内）在**决策点**落存档，使退出重进恢复到同一局面与同一份 RNG 状态；`selectCost` **不回滚**。存档点清单见 `systems/services/life-cycle-service.md`。Source: 同上。
- **RNG 状态与内容版本落在 CharacterProfile 上（已定案）。** 新增三组字段，随本次存档 **schema bump**（当前无线上存档 → 空迁移，但迁移骨架就此立起）：

  | 字段 | 类型 | 语义 |
  |------|------|------|
  | `StartContentVersion` | `string` | 轮回开始时生效的内容版本，**写一次不再变** |
  | `LastContentVersion` | `string` | **每个自动存档点**更新为当时生效的版本；与上一字段不等 = 该轮回跨过内容更新（数值突变类反馈的第一判据） |
  | `Rng.CycleSeed` | `ulong` | 轮回开始时生成，不变 |
  | `Rng.Streams[]` | `Name` / `Seed` / `State` / `DrawCount`（`string` / `ulong` / `ulong` / `int`） | 具名子流状态；`State` 为恢复权威字段，`DrawCount` 为诊断与迁移保险 |

  schema 形态：

  ```jsonc
  "rng": {
    "CycleSeed": 12345678901234567890,        // u64，轮回开始时生成，不变
    "streams": [
      { "name": "map",    "seed": 0, "state": 0, "drawCount": 0 },
      { "name": "combat", "seed": 0, "state": 0, "drawCount": 0 },
      { "name": "shop",   "seed": 0, "state": 0, "drawCount": 0 },
      { "name": "reward", "seed": 0, "state": 0, "drawCount": 0 }
    ]
  }
  ```

  派生规则与恢复语义见 `systems/common-properties.md`；双 `contentVersion` 的诊断用途见 `systems/services/content-service.md`。Source: `handoffs/2026-07-27-content-gating-offline-resilience-and-rng-persistence.md`。
- **角色状态是终态收敛的状态机。** `status` 收敛为 `ongoing | defeated | completed`（`defeated` 的三种原因：discarded / 寿元归 0 / lifeTotal 归 0）；`defeated` 与 `completed` 数据都会在轮回结束时被清理。→ 见 `systems/services/life-cycle-service.md` 与 `decisions/ADR-0004-realm-checkpoint-retry-model.md`。Source: `handoffs/2026-07-24-docs-restructure-class-model.md`。

## 子系统导航

| 子系统 | 文件 | 内容 |
|--------|------|------|
| 卡组 deck | `deck/_index.md`、`deck/common-properties.md` | 抽牌堆 / hand / 弃牌堆、seeded 洗牌、deck 变更；卡牌 / CardData 定义（费用、目标、效果流水线、触发器）；起始卡组等内容设计。 |
| 法宝 item | `item/_index.md`、`item/common-properties.md` | **CharacterItem**：轮回级角色道具（含道具设计内容；细节待定）。 |
| 轮回货币 currency | `currency.md` | 轮回货币 jade 的获取 / 消耗。 |
| 神通 power | `power/_index.md`、`power/common-properties.md` | **CharacterPower**：轮回级角色能力，**对标账号级 PlayerPower（法则）**（同一概念的两层，分界是生命周期）；随轮回清理，**可承载战斗内触发式效果**。 |
| 生命总量 lifeTotal | `life-total.md` | **战斗外的耐久 / 失败惩罚承受量**（战斗内不参与，失败结算时按道念差扣减）；**归 0 → defeated**；经 AdventureEvent 恢复；炼气基线 10/10；无曲线。 |
| 法力 mana | `mana.md` | 每回合出牌资源；**每回合恢复至 `manaLimit`**，上限由事件推拉；炼气基线 5/5。 |

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- **子系统结构（已定案）。** `deck` / `item` / `power` 为**文件夹**——除规则外还要容纳**内容设计**（起始卡组 starter decks、道具设计 item designs、能力条目）；`life-total` / `currency` / `mana` 为**扁平 `.md`**——它们是系统性资源（systematic resource），预期规则足够短，暂以单文件承载。Source: `handoffs/2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md`。
- **境界存档 · 篇章重试模型**（CharacterProfile 状态机 `ongoing | defeated | completed`、全部继承、重试上限）→ `decisions/ADR-0004-realm-checkpoint-retry-model.md`（Accepted）。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **CharacterProfile 字段结构细节：** 各字段的具体 schema、隐藏属性完整清单与阈值、AdventurePlot key points 粒度仍待定。→ 见 `systems/services/life-cycle-service.md`、`systems/services/plot-manager.md`。

## 对应
提炼至：`.claude/knowledge/systems/character-profile/_index.md`（待建）。
