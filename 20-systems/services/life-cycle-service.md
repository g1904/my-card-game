# life-cycle-service（服务）

> Run 生命周期服务：开始（seed）、推进、胜/负、清理、篇章继承、状态机、重试模型。**对 `character-profile` / `player-profile` 提供 API 的服务层**。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **两层持有模型（大局骨架，细节未定）。** 账号级的 **玩家信息 / PlayerProfile** 跨 run 持久，持有一组 **角色信息 / CharacterProfile**；每个 CharacterProfile 是一次 run / 一个角色的状态与历史，对齐 RunState 概念。life-cycle-service 是操作这两层的服务。
  - **PlayerProfile（元进程层）：** `List<CharacterProfile>`、`GameSetting`、`List<PlayerPower>`、`List<PlayerItem>`、`List<Achievements>`、`AccountInfo` 等。`PlayerPower` / `PlayerItem` / `Achievements` 是**独立于任何单次 run** 的账号级解锁与成就。（结构权威见 `20-systems/player-profile/`。）
  - **CharacterProfile（单次 run）：** `status`（**ongoing | defeated | completed**）、`chapter`（当前篇章）、`Status`（currentHealth / healthLimit、currentMana / manaLimit、以及**隐藏属性** 道心 / faith、煞气 / malefic qi、寿元 / lifeSpan）、`List<AdventureEvent>`、`List<CharacterItems>`、**AdventurePlot key points**（剧情进度锚点；完整剧本内容不落存档，存于云端剧本服务，见 `20-systems/services/plot-manager.md`）等。（结构权威见 `20-systems/character-profile/`。）
- **角色状态分类法（已定案）。** `status` 收敛为单一终态集 `ongoing | defeated | completed`：`discarded`（主动弃置）是 `defeated` 的一个**原因子类型**。`defeated` 与 `completed` 数据都会在 run 结束时被清理。Source: `10-handoffs/2026-07-22-online-cloud-combat-and-meta-clarifications.md`。
- **寿元按 AdventureEvent 扣减、归 0 → defeated（已定案）。** 隐藏属性 **寿元 / lifeSpan** 是独立于血量 `life` 的寿命预算（炼气起始 100、抵达筑基 +100、抵达金丹 +300、抵达元婴 +500——元婴为游戏终点，该增量无可消耗预算，仅作最后一次数值更新并存档），初始隐藏、低于 10% 时显示。**每完成一个 AdventureEvent，life-cycle-service 按该事件的 `lifeSpanCost`（默认 -1）扣减寿元**；递减到 **0** 即触发「大限将至」，角色置 `status = defeated`。`lifeSpanCost` 是 AdventureEvent 的共有字段（见 `20-systems/adventure-event/common-properties.md`），基准值为可调平衡数值（见 `20-systems/balance.md`）。Source: `10-handoffs/2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md`。
- **多角色并存 + 每篇章至多一个 ongoing（语义已确认）。** 玩家可同时持有多个 CharacterProfile；但**每个篇章内至多一个 `ongoing`**——只要有一个角色在该篇章尚未结束进程（ongoing），就**不能在该篇章使用其他角色游玩**；不同篇章之间可各自并行。Source: `10-handoffs/2026-07-22-online-cloud-combat-and-meta-clarifications.md`。
- **篇章继承：全部继承（已定案）。** 读档续章时，角色带入下一篇章的是**上一篇章的全部信息**（deck、法宝、属性、叙事标记等），无逐项筛选。Source: `10-handoffs/2026-07-22-online-cloud-combat-and-meta-clarifications.md`。
- **篇章解锁触发（已定案）。** 解锁触发 = **角色通关上一篇章**，随即成为下一篇章的**可挑战角色**；若某篇章没有可重试 / 可挑战的角色，该篇章**重新进入锁定（隐藏）**状态。见 `40-ux/onboarding.md`。Source: `10-handoffs/2026-07-22-online-cloud-combat-and-meta-clarifications.md`。
- **篇章存档 · 读档续章 · 重试模型。** 篇章通关即在所达境界落一个**存档点**（如打通炼气→筑基得到筑基存档）；可读档从该境界起始下一篇章。**炼气起手为随机角色，失败可近乎无限重试**；而**落过境界存档的角色，在后续篇章有有限的重试次数**——存档角色是一种会被耗尽的有限资源。**重试上限（四境三篇章）：** 第一章（炼气→筑基）= **无限**；第二章（筑基→金丹）= **3**；第三章（金丹→元婴）= **1**。挑战成功进入下一境界，不能重试之前篇章。Source: `10-handoffs/2026-07-15b-taxonomy-and-checkpoint-clarifications.md` + `10-handoffs/2026-07-22-online-cloud-combat-and-meta-clarifications.md`。
- **账号级能力 / 道具语义（已澄清）。**（细节结构权威见 `20-systems/player-profile/`。）
  - **PlayerPower：** always-available 能力，带**开关（默认开启）**；可为 **QoL** 或**影响公平性的一定加强**（需衡量平衡），**通常全局、不与角色绑定**；获取越多后续越易，但 **AdventureEvent 过程中也可能失去**已获取的 PlayerPower。**定位 = 轻度提升（light improvement）：** 承认它影响平衡，但因**本作无 PvP、纯 PvE**，让 power 带来一定强度是**可容忍的**，并**打开更大的设计空间**。Source: `10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。
  - **PlayerItem：** 有**使用次数限制**的道具。
  - **Achievements：** 玩家**只能查看进度 / 领取奖励**；奖励按**组内加权进度**发放（见 `40-ux/screen-flow.md`）。
  - Source: `10-handoffs/2026-07-22-online-cloud-combat-and-meta-clarifications.md`。
- **属性模型 = 隐藏（已定案）。** 借鉴 **Reigns** 的属性模型，但**与 Reigns 相反：属性隐藏、不作可见仪表**，在背后影响 AdventureEvent。隐藏属性（**道心 / faith**、**煞气 / malefic qi**、**寿元 / lifeSpan**）落在 `CharacterProfile.Status` 内，随 run 推进被 AdventureEvent 推拉；达阈值驱动 **AdventurePlot（隐藏剧本层）**——见 `20-systems/services/plot-manager.md`。Source: `10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。

## 管理器

| manager | 职责 |
|---------|------|
| **RunStateManager** | `status` 状态机：`ongoing → completed \| defeated`；终态判定与清理 |
| **ChapterManager** | 篇章边界、境界存档点、篇章继承、重试上限（∞ / 3 / 1）、解锁与重新锁定 |
| **SeedManager** | run seed 持有；派生具名 RNG 子流（map / combat / shop / reward），互不干扰 |

## 服务角色 / API 面
> _life-cycle-service 作为服务（判据 ① —— 拥有 run 的状态机），提供 run 生命周期 API。以下为意图层的方法 / 事件 / 数据契约草图；具体签名待细化（见待决问题与 `20-systems/architecture.md`）。_

- **服务定位。** life-cycle-service 不持有独立数据；它是这两个「类」的 run 生命周期操作面。上层（**编排顶点 game-progression**）通过它开始、推进、结算、清理一次 run，而非直接改这两层的字段。
- **一切 Profile 写入经 `profile-service.ProfileManager`。** 本服务负责**状态机与编排**，不直接改 Profile 字段——扣成本、加产出、推拉隐藏属性都以 CostSpec / RewardSpec 交给 ProfileManager 原子施加（全有或全无）。
- **方法面（意图草图 · 签名待定）：**
  - `StartRun(seed, chapter, characterSource)` → 新建或读档一个 CharacterProfile，置 `status = ongoing`。炼气起手 = 随机角色；后续篇章 = 从存档角色续入（全部继承）。SeedManager 派生子流。
  - `AdvanceEvent(character, chosenAdventureEvent, mode)` → 推进修行历程。**`mode = Select | Skip`——跳过复用同一入口的分支**，两者施加的是同一套成本体系（`selectCost` / `skipCost` 同类型），只是取值不同。流程：施加成本 → `eventStart` → 事件内部流程（Combat / Finale 转 combat-service，其余走通用结算器）→ `eventEnd` → 施加产出与 `lifeSpanCost` → 记入 `List<AdventureEvent>` → 终态判定。
  - `CompleteChapter(character)` → 篇章通关，落境界存档点，置 `status = completed`（并解锁下一篇章的可挑战角色）。
  - `DefeatCharacter(character, reason)` → 置 `status = defeated`（reason 含 discarded、寿元归 0 等子类型），清理该角色数据；触发重试计数扣减。
  - `RetryChapter(character)` → 从该篇章起始存档重试，受重试上限（无限 / 3 / 1）约束。
  - `TeardownRun(character)` → run 结束清理，避免跨 run 残留。
- **事件面（意图草图）：** run 开始 / 结束、篇章通关 / 解锁 / 重新锁定、角色 defeated、隐藏属性达阈值（转交 future-event-service 的 PlotManager）等，走 EventBus 解耦广播。
- **数据契约：** 输入 / 输出以稳定 `Id` 引用内容与角色（经 `content-service.ContentRegistry` 解析）；持久化交 `sync-service`（原子写 + schema 版本）；RNG 由 SeedManager 从 run seed 派生（见 `20-systems/common-properties.md`）。
- **自动存档点：** 在状态机边界（run 开始、每个事件结算后、篇章边界、run 结束）触发 `sync-service.Push(...)`。
- **状态机（CharacterProfile.status）：** `ongoing → completed`（篇章通关）或 `ongoing → defeated`（战败 / 主动弃置 / 寿元归 0）。`completed` 解锁下一篇章可挑战角色；`defeated` 清理数据并消耗重试次数。

## 决策(-> ADR)
> _已定案的决定链接到 50-decisions/ADR-####。_

- **境界存档 · 篇章重试模型（四境三篇章、全部继承、状态机、重试无限/3/1、篇章解锁）** → `50-decisions/ADR-0004-realm-checkpoint-retry-model.md`（Accepted）。
- **强制在线 · 云端权威（含重账号）** → `50-decisions/ADR-0003-online-cloud-authority.md`（Accepted）。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **服务边界与 API 契约：** 上文方法 / 事件面为意图草图，**具体签名、参数、返回类型、事件负载 schema 尚未定义**，属 `20-systems/architecture.md` 待细化。Source: `10-handoffs/2026-07-24-docs-restructure-class-model.md`。
- **跳过通道的玩法语义未定。** API 归属已定（`AdvanceEvent` 的 `mode = Skip` 分支）；仍待定：跳过是否计入 `List<AdventureEvent>` 修行历程、是否照扣 `lifeSpanCost`（时间是否照样流逝）、能否整批全跳。→ `20-systems/adventure-event/common-properties.md`。Source: `10-handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md`。
- **`AdvanceEvent` 与事件自身 `eventStart` / `eventEnd` 的职责边界未定。** 大方向已定（服务负责状态机与编排、写入统一经 ProfileManager），但**具体切分点**仍未定：`eventStart` 是否直接把控制权交给 combat-service、事件内部流程的返回形态（结算结果对象？）、谁翻译 `CombatResult` 为 Profile 变更。→ `20-systems/adventure-event/common-properties.md`、`combat-service.md`。Source: 同上。
- **元进程持久化范围：** `PlayerPower` / `PlayerItem` / `Achievements` / `GameSetting` / `AccountInfo` 语义已澄清（见「意图」），但**各自字段结构与解锁 / 获取 / 失去的具体触发**仍待定；账号级 meta 或许值得单独一份系统文档。**PlayerPower 平衡边界**（防 pay/grind-to-win、是否影响 run seed / 计分公平）待定。
- **后端 / 账号合规落地：** 已定**强制在线 · 云端权威 + 重账号**（`50-decisions/ADR-0003`）；仅剩实现级待决：后端 / 账号系统具体选型、合规落地（PIPL / 实名 / 防沉迷 / 渠道审核 / 注销 / 数据导出）——这些归**后端库**，见 `backend-design-documents/open-questions.md`。Source: `10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。
- **隐藏属性细节：** 属性隐藏、`faith` = 道心、寿元按 `lifeSpanCost` 扣减 / 归 0 → defeated 均已定案；仍待定：**隐藏属性完整清单**（道心 / 煞气 / 寿元之外）、各自阈值与增减触发、是否有非境界突破的寿元增长途径、AdventurePlot 树的数据编码（归 `20-systems/services/plot-manager.md`）。Source: `10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。

## 对应
提炼至：`.claude/knowledge/systems/life-cycle-service.md`（引用层，待建）。
