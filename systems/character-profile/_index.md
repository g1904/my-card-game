# character-profile

> 角色信息 / **CharacterProfile** —— 单次轮回 / 单个角色的状态与历史（对齐 CycleState 概念）。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **CharacterProfile = 单次轮回 / 单个角色的状态与历史。** 每个 CharacterProfile 对齐 **CycleState** 概念：一次轮回、一个角色所走过 / 可走的整段修行历程与当前状态。它由账号级的 **PlayerProfile** 持有（`List<CharacterProfile>`）。Source: `handoffs/2026-07-24-docs-restructure-class-model.md`（+ `systems/services/life-cycle-service.md`、`terminology.md`）。
- **CharacterProfile 的字段（大局骨架，细节未定）。** `status`（**ongoing | defeated | completed**）、`chapter`（当前篇章）、**`realm` + `level`（境界与境界内等级，见 `systems/game-progression.md`）**、`Status`（**`lifeTotal`（单值，无上限字段）**、`currentMana / manaLimit`、`experiencePoint`，以及**隐藏属性** 道心 / faith、煞气 / malefic qi、寿元 / lifeSpan）、`List<AdventureEvent>`（修行历程）、**`activeCombat`（可空，进行中战斗的中间态）**、角色级道具（见 `item/`）、角色能力 `List<CharacterPower>`（见 `power/`）、轮回货币 jade（见 `currency.md`），以及 **AdventurePlot key points**（剧情进度锚点；完整剧本内容不落存档，存于云端剧本服务）。Source: `systems/services/life-cycle-service.md` + `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md`。
- **`realm` + `level` 是角色的修行位置（已定案）。** 二者合成**全局等级序**上的位置，是敌人意图三档揭示的判据；篇章突破后 `level` 归位为新境界的初期。**`manaLimit` 不随境界自动成长**，由事件 cost / reward 推拉（见 `mana.md`）。Source: `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md`。
- **决策点存档（已定案）。** 事件推进过程中（含战斗内）在**决策点**落存档，使退出重进恢复到同一局面与同一份 RNG 状态；`selectCost` **不回滚**。存档点清单见 `systems/services/life-cycle-service.md`；**战斗内的 D0–D6 决策点清单见 `systems/services/combat-service.md`**。Source: 同上。
- **`activeCombat`：进行中战斗的中间态（已定案 · CharacterProfile 上的可空块）。** 战斗开始时创建、`eventEnd` 收口时**置空**；**不进 `pastEvent`**（历史事件只留定稿快照），也不与 `Rng.Streams[]` 混住——它是**事件内的中间态，寿命短于一次事件**。
  - **为什么挂 CharacterProfile 而非独立的战斗存档实体**：与「每篇章至多一个 ongoing」自洽，且 diff 天然落在 `CharacterProfile` 粒度（sync-service 的既定 diff 单位），**无需新增同步单元**。
  - 内容 = 遭遇参数 + 回合 / 步状态 + 战斗子流 RNG + 两个参战方（含三区 `Id` 序列与 `CardInstance` 运行态）+ 战场条目 + 栈条目 + 挂起态。**完整 schema 与读档校验归 `systems/services/combat-service.md`**（本文件只登记它是 CharacterProfile 的一个字段）。
  - 随 `activeCombat` 一起 **bump schema 版本**（当前无线上存档 → 空迁移）。
  Source: `handoffs/2026-08-06d-combat-open-questions-mass-closure.md`。
- **`chapterRetry`：篇章重试计数器（已定案 · 08-06 · CharacterProfile 上的新字段）。** 一个**类**，计数第一 / 第二 / 第三篇章各自的重试次数——**因为 ch2 与 ch3 有重试上限**（无限 / 3 / 1，持 premium bundle 为 无限 / 9 / 3，见 ADR-0004）。**它是计数器容器，不是上限持有者**：上限仍按 ADR-0004 的既定纪律读取（可被账号级持有状态改写、凡读取处不得硬编码常量），`chapterRetry` 只答「用掉了几次」。**推论：篇章解锁 / 重新锁定与「剩余重试次数展示」有了确定的数据源。**
  - **形态 = 三个具名字段（已定案 · 08-06b）**，第一 / 第二 / 第三篇章各一，**不是字典也不是按索引的数组**。**与「四境三篇章」这条硬事实对齐**（篇章数是游戏结构，不是可扩展列表）：具名字段让存档 schema 显式、读取处不必处理「键不存在」的分支，也免去按索引访问的越界校验。**代价是新增篇章需改 schema——但篇章数不是设计变量。**
  - **通关后保留计数，不清零（已定案 · 08-06b）** ⇒ **它是历史，不只是配额**。一个通关角色身上留着「我在筑基段挣扎了 3 次」的记录，可供元进程界面的角色履历展示；**同时它简化实现**——没有清零时机就没有「何时清零」的边界情形。
  - **ch1 的角色级计数恒为 0，这不是缺陷（已定案 · 08-06b）。** ch1 重试 = 随机生成新角色（07-30b，**不改写**），故角色级 ch1 计数对每个新角色恒为 0；**「你在炼气段重开了多少次」由账号级的统计计数回答**，见 `systems/player-profile/_index.md`。**两层口径不同，不是同一个数的两份拷贝**：角色级参与闸门判定，账号级只被读来看。
  - **连带：`attemptIndex` 派生层整层删除**（篇章重试 = 换一套随机流，见 `systems/common-properties.md`）。
  Source: `handoffs/2026-08-06-ch1-band-widening-cross-realm-crush-and-chapter-retry.md` + `handoffs/2026-08-06b-asymmetric-ch1-band-consented-power-loss-and-chapter-retry-shape.md`。
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
- **「本轮回禁用」的法则集合落在 `CharacterProfile` 的哪个位置（08-06b 新增）：** 事件侧「失去法则」已定案为**不强制剥夺**（只有自愿置换能真正移除，其余降级为本轮回禁用，见 `systems/player-profile/player-power/`）；禁用集合**必须是轮回级状态**（账号级 `status` 开关不能承载它，否则轮回结束忘了恢复即等同永久剥夺）。落 `Status` 内还是与 deck 平级、被禁用的法则是否开局根本不入场，均未定。→ `systems/player-profile/player-power/`、`systems/services/combat-service.md`。Source: `handoffs/2026-08-06b-asymmetric-ch1-band-consented-power-loss-and-chapter-retry-shape.md`。

## 对应
提炼至：`.claude/knowledge/systems/character-profile/_index.md`（待建）。
