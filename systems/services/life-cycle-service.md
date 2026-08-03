# life-cycle-service（服务）

> 轮回生命周期服务：开始（seed）、推进、胜/负、清理、篇章继承、状态机、重试模型。**对 `character-profile` / `player-profile` 提供 API 的服务层**。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **两层持有模型（大局骨架，细节未定）。** 账号级的 **玩家信息 / PlayerProfile** 跨轮回持久，持有一组 **角色信息 / CharacterProfile**；每个 CharacterProfile 是一次轮回 / 一个角色的状态与历史，对齐 CycleState 概念。life-cycle-service 是操作这两层的服务。
  - **PlayerProfile（元进程层）：** `List<CharacterProfile>`、`GameSetting`、`List<PlayerPower>`、`List<PlayerItem>`、`List<Achievements>`、`AccountInfo` 等。`PlayerPower` / `PlayerItem` / `Achievements` 是**独立于任何单次轮回**的账号级解锁与成就。（结构权威见 `systems/player-profile/`。）
  - **CharacterProfile（单次轮回）：** `status`（**ongoing | defeated | completed**）、`chapter`（当前篇章）、`Status`（lifeTotal / lifeTotalLimit、currentMana / manaLimit、**`experiencePoint`**、以及**隐藏属性** 道心 / faith、煞气 / malefic qi、寿元 / lifeSpan）、`List<AdventureEvent>`、`List<CharacterItems>`、**AdventurePlot key points**（剧情进度锚点；完整剧本内容不落存档，存于云端剧本服务，见 `systems/services/plot-manager.md`）等。（结构权威见 `systems/character-profile/`。）
- **角色状态分类法（已定案）。** `status` 收敛为单一终态集 `ongoing | defeated | completed`：`discarded`（主动弃置）是 `defeated` 的一个**原因子类型**。`defeated` 与 `completed` 数据都会在轮回结束时被清理。Source: `handoffs/2026-07-22-online-cloud-combat-and-meta-clarifications.md`。
- **寿元按 AdventureEvent 扣减、归 0 → defeated（已定案）。** 隐藏属性 **寿元 / lifeSpan** 是独立于 `lifeTotal` 的寿命预算（炼气起始 100、抵达筑基 +100、抵达金丹 +300、抵达元婴 +500——元婴为游戏终点，该增量无可消耗预算，仅作最后一次数值更新并存档），初始隐藏；**30% 起给定性叙事提示、10% 起给红字数值倒数**（见 `ux/screen-flow.md`）。**每完成一个 AdventureEvent，life-cycle-service 按该事件的 `lifeSpanCost` 扣减寿元**（内容侧为正数量值，物化时已取负）；递减到 **0** 即触发「大限将至」，角色置 `status = defeated`。`lifeSpanCost` 是 AdventureEvent 的共有字段（见 `systems/adventure-event/common-properties.md`），其分档是**控制篇章时长的主旋钮**（见 `systems/balance.md`）。Source: `handoffs/2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md` + `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。
- **剩余寿元跨篇章结转（已定案）。** 篇章突破时**不清空剩余寿元**：下一篇章的可用预算 = **该篇章增量 + 上一篇章的剩余**（例：第二篇章 = `+100 + 第一篇章剩余`）。因此「省着花」有**跨篇章回报**，寿元成为一条贯穿整个轮回的资源线，而非每章重置的计时器。它是 ChapterManager 在篇章边界的一项明确职责。Source: `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。
- **`lifeTotal` 归 0 → `defeated`（已定案 · 第二条终结路径）。** `life` 已定名为 **`lifeTotal`**（角色的生命值，见 `systems/character-profile/life-total.md`）；它按战斗失败的道念差被扣减，**归 0 即 `status = defeated`**，与「寿元归 0（大限将至）」并列。二者分工：**寿元按事件流逝，lifeTotal 按失败流逝**。**恢复途径 = AdventureEvent 的 reward**，与等级 / `manaLimit` 同走 `ProfileChangeSpec` → `TryApply` 链路。连带：`DefeatReason` 的 `CombatLost` 作废（输一场战斗本身不终结角色），改为 **`LifeTotalExhausted`**；终结原因收敛为**主动弃置 / 寿元耗尽 / lifeTotal 耗尽**三种。Source: `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。
- **重试上限是基线值，可被付费礼包改写（已定案）。** ADR-0004 的「无限 / 3 / 1」不再是常量：持有 premium bundle 的账号为「**无限 / 9 / 3**」。这使 `RetryChapter` 的上限判定需读账号级的持有状态（落点未定，见待决问题）。见 `systems/monetization.md`。Source: 同上。
- **等级成长 = 事件产出经验值（已定案 · 08-02 改写）。** 境界内等级（见 `systems/game-progression.md`）由 **AdventureEvent 的 reward 给予**——**不只绑定 Combat / Practice**，也**不只有胜利才给**：失败同样可能有产出。**产出的是 `experiencePoint`（经验值）而非等级本身**：每个等级各有一个升级所需的经验阈值，累积达阈值才升级（「事件直接给等级」的先前表述作废）。**推论：`experiencePoint` 是 `CharacterProfile.Status` 上的一个新字段**，与 `lifeTotal` / `mana` / 隐藏属性同属角色状态；升级判定是 ProfileManager 施加经验后的一次派生检查。它与 `manaLimit` 同属一套「由事件 cost / reward 推拉」的成长体系，走同一条 `ProfileChangeSpec` → `TryApply` 链路。阈值曲线与产出分布未定，见待决问题。Source: 同上 + `handoffs/2026-08-02-momentum-conversion-reward-structure-and-mtg-stack.md`。
- **多角色并存 + 每篇章至多一个 ongoing（语义已确认）。** 玩家可同时持有多个 CharacterProfile；但**每个篇章内至多一个 `ongoing`**——只要有一个角色在该篇章尚未结束进程（ongoing），就**不能在该篇章使用其他角色游玩**；不同篇章之间可各自并行。Source: `handoffs/2026-07-22-online-cloud-combat-and-meta-clarifications.md`。
- **篇章继承：全部继承（已定案）。** 读档续章时，角色带入下一篇章的是**上一篇章的全部信息**（deck、法宝、属性、叙事标记等），无逐项筛选。Source: `handoffs/2026-07-22-online-cloud-combat-and-meta-clarifications.md`。
- **篇章解锁触发（已定案）。** 解锁触发 = **角色通关上一篇章**，随即成为下一篇章的**可挑战角色**；若某篇章没有可重试 / 可挑战的角色，该篇章**重新进入锁定（隐藏）**状态。见 `ux/onboarding.md`。Source: `handoffs/2026-07-22-online-cloud-combat-and-meta-clarifications.md`。
- **篇章存档 · 读档续章 · 重试模型。** 篇章通关即在所达境界落一个**存档点**（如打通炼气→筑基得到筑基存档）；可读档从该境界起始下一篇章。**炼气起手为随机角色，失败可近乎无限重试**；而**落过境界存档的角色，在后续篇章有有限的重试次数**——存档角色是一种会被耗尽的有限资源。**重试上限（四境三篇章 · 基线值）：** 第一章（炼气→筑基）= **无限**；第二章（筑基→金丹）= **3**；第三章（金丹→元婴）= **1**——**持有 premium bundle 的账号为 无限 / 9 / 3**（见 `systems/monetization.md`）。挑战成功进入下一境界，不能重试之前篇章。Source: `handoffs/2026-07-15b-taxonomy-and-checkpoint-clarifications.md` + `handoffs/2026-07-22-online-cloud-combat-and-meta-clarifications.md`。
- **重试计数只有一种：每个角色的篇章重试（已定案）。** 计数**挂在角色上**，且**只有角色进入第二 / 第三篇章后才存在**——第一篇章是**随机生成起始角色**的重试，**不能指定重试同一个角色**，故第一篇章不存在「某个角色的重试计数」这回事。**不存在事件级或篇章级的重试次数上限**：草案中「同一事件重试 < 10 次 / 篇章重试总数 < 30 次 / 超限强制 defeat」**未采纳**，其目的（防退出重进作弊）已由决策点存档达成。Source: `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md`。
- **事件过程按决策点落存档（已定案）。** 一个 AdventureEvent 的推进过程**不是存档盲区**：**战斗与其他事件一律在决策点落存档**，使「退出重进」恢复到同一个局面与同一份 RNG 状态。这从根上关闭了「退出重掷」的作弊窗口，因此无需再用重试计数去堵。**`selectCost` 不回滚**——选中事件时施加的成本（含 `lifeSpanCost`）一经施加即成事实，中途退出不退还。这同时答结了 `AdvanceEventAsync` / `RunCombatAsync` 取消语义中「已施加的 `SelectCost` 如何处置」的问题：**视同已结算，不回滚**。决策点的具体粒度未定，见待决问题。Source: 同上。
- **账号级能力 / 道具语义（已澄清）。**（细节结构权威见 `systems/player-profile/`。）
  - **PlayerPower：** always-available 能力，带**开关（默认开启）**；可为 **QoL** 或**影响公平性的一定加强**（需衡量平衡），**通常全局、不与角色绑定**；获取越多后续越易，但 **AdventureEvent 过程中也可能失去**已获取的 PlayerPower。**定位 = 轻度提升（light improvement）：** 承认它影响平衡，但因**本作无 PvP、纯 PvE**，让 power 带来一定强度是**可容忍的**，并**打开更大的设计空间**。Source: `handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。
  - **PlayerItem：** 有**使用次数限制**的道具。
  - **Achievements：** 玩家**只能查看进度 / 领取奖励**；奖励按**组内加权进度**发放（见 `ux/screen-flow.md`）。
  - Source: `handoffs/2026-07-22-online-cloud-combat-and-meta-clarifications.md`。
- **属性模型 = 隐藏（已定案）。** 借鉴 **Reigns** 的属性模型，但**与 Reigns 相反：属性隐藏、不作可见仪表**，在背后影响 AdventureEvent。隐藏属性（**道心 / faith**、**煞气 / malefic qi**、**寿元 / lifeSpan**）落在 `CharacterProfile.Status` 内，随轮回推进被 AdventureEvent 推拉；达阈值驱动 **AdventurePlot（隐藏剧本层）**——见 `systems/services/plot-manager.md`。Source: `handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。

## 管理器

| manager | 职责 |
|---------|------|
| **CycleStateManager** | `status` 状态机：`ongoing → completed \| defeated`；终态判定与清理 |
| **ChapterManager** | 篇章边界、境界存档点、篇章继承、**剩余寿元结转 + 下一篇章寿元增量**、重试上限（基线 ∞ / 3 / 1；持礼包为 ∞ / 9 / 3）、解锁与重新锁定 |
| **SeedManager** | `CycleSeed` 持有；按 **`Hash64(CycleSeed, streamName)`** 派生具名 RNG 子流（map / combat / shop / reward），互不干扰；**子流清单是本 manager 内的常量**；存 / 取 `State` + `DrawCount`，读档时对新增 / 移除子流分别 warn + 初始化 / warn + 丢弃 |

## 服务角色 / API 面（契约）
> _life-cycle-service 作为服务（判据 ① —— 拥有轮回的状态机），提供轮回生命周期 API。总则与共享类型见 `systems/architecture.md`「API 契约总则」。本服务**纯本地**，永不跨进程边界，故不实现 `IBootstrappable`。Source: `handoffs/2026-07-27b-service-api-contracts.md`。_

- **服务定位。** life-cycle-service 不持有独立数据；它是这两个「类」的轮回生命周期操作面。上层（**编排顶点 game-progression**）通过它开始、推进、结算、清理一次轮回，而非直接改这两层的字段。
- **一切 Profile 写入经 `profile-service.ProfileManager`。** 本服务负责**状态机与编排**，不直接改 Profile 字段——扣成本、加产出、推拉隐藏属性都以 `ProfileChangeSpec` 交给 ProfileManager 原子施加（全有或全无）。

| 方法 | 形态 | 完整签名 | 失败语义 |
|------|------|----------|----------|
| 开始轮回 | A | `OpResult<CharacterProfile> StartCycle(CycleStartSpec spec)` | 业务失败（该篇章已有 ongoing、重试次数耗尽）→ `OpResult` |
| 推进 | **C** | `Task<AdvanceResult> AdvanceEventAsync(EventOption chosen, AdvanceMode mode, CancellationToken ct)` | 业务失败 → `AdvanceResult`，绝不抛 |
| 篇章通关 | A | `OpResult CompleteChapter()` | 业务失败 → `OpResult` |
| 角色终结 | A | `OpResult DefeatCharacter(DefeatReason reason)` | 同上 |
| 重试 | A | `OpResult<CharacterProfile> RetryChapter(string characterId)` | 超出重试上限（基线 ∞ / 3 / 1，持礼包 ∞ / 9 / 3）→ `OpResult.Fail` |
| 清理 | A | `void TeardownCycle()` | — |
| 当前角色 | A | `bool TryGetActiveCharacter(out CharacterProfile c)` | **可选缺失**——主菜单无进行中轮回是正常态 |
| RNG 子流 | A | `RandomNumberGenerator Stream(RngStream stream)` | 未知子流 = 程序缺陷 → `PushError` + 抛 |

```csharp
public readonly record struct CycleStartSpec(ulong Seed, int Chapter, string SourceCharacterId /* 空 = 炼气新角色 */);

public readonly record struct AdvanceResult(
    bool         Success,
    AdvanceStage FailedAt,      // None | ModeRejected | CostRejected | InnerFlow | OutcomeRejected
    CostKey      MissingElement,
    CycleStatus  StatusAfter);
```

四点推演：

- **`AdvanceEventAsync` 收 `EventOption`（定稿实例）而非 `AdventureEventData`。** 它需要**物化时置位**的 `Priority` / `IsMandatory` / `SelectCost` / `SkipCost` 来校验「这一步合法吗」并施加成本。传 `Resource` 就拿不到这些字段，且会诱使调用方回查模板重算，违「产出即定稿」（见 `systems/architecture.md` 总则 6）。
- **不收 `character` 参数。** 每篇章至多一个 `ongoing`（ADR-0004），当前角色是本服务状态机的持有物；把它当参数传等于允许调用方指定「对哪个角色推进」，是一处不必要的越权面。（`StartCycle` / `RetryChapter` 例外，它们要选角色。）
- **返回 `AdvanceResult` 而非 `void`。** 「付不起 → 拒绝，回到呈现步」是 `program-overview.md` 阶段 4 的明文流程，编排顶点需要一个可判定的返回值，且 `MissingElement` 直接喂给 UI 提示。
- **`Stream(RngStream)` 暴露 `RandomNumberGenerator` 而非 `int Next()`。** Godot 的 `RandomNumberGenerator` 自带可序列化的 `Seed` / `State`，正是既定 RNG 持久化形态（`State` + `DrawCount`）的载体；各子流独立实例天然满足「互不干扰」。

### `AdvanceEventAsync` 的固定结算流程（已定案）

`eventStart` / `eventEnd` 是**本方法内部结算流程的两个阶段名**，不是 `AdventureEventData` 上的方法（见 `systems/adventure-event/common-properties.md`「结算阶段」）：

```
校验 mode 合法性（IsMandatory + Skip → 拒绝；Priority < EffectivePriority → 拒绝）
  → TryApply(SelectCost | SkipCost)          ← 付不起则回 AdvanceResult 拒绝，不产生任何写入
  → 【eventStart 阶段】选 resolver、Mystery 揭示
  → resolver.ResolveAsync(option, ct)        ← Combat/Finale 转 combat-service，其余走通用结算器
  → 【eventEnd 阶段】合并 ResolveOutcome + lifeSpanCost + 隐藏属性推拉为**一次** TryApply
  → 记入 pastEvent（按 InstanceId，携带定稿实例快照）
  → CycleStateManager 终态判定 → EventBus 广播 → sync 自动存档点
```

```csharp
internal interface IEventResolver          // 按 eventType 注册，共 2 个实现
{
    Task<ResolveOutcome> ResolveAsync(EventOption option, CancellationToken ct);
}
// CombatEventResolver  → Combat / Finale，转 combat-service
// GenericEventResolver → 其余七类，读模板上的数据驱动 outcome / effect 定义
```

- **九类事件只有两个 resolver**——与既定拆分轴「只有 Combat 真有状态机、其余差异在数据而非代码」一致，保住「新增一个事件 = 新增一个 `.tres`」的可加性。
- **`mode = Skip` 分支**跳过 resolver 环节，且**通常不扣 `lifeSpanCost`**（时间通常不流逝），仅在该事件带 `skipCost` 时按其 element 扣减；跳过**仍记入 `pastEvent`**（作为行为轨迹，需与「进入并结算」区分），随后由 future-event-service 单项补位。Source: `handoffs/2026-07-26-event-priority-skip-semantics-and-hotfix-scope.md`。
- **`eventEnd` 阶段把 `CombatResult.Spoils`（一份 `ProfileChangeSpec`）连同 `lifeSpanCost`、**战斗失败时按道念差扣减的 lifeTotal**、等级产出与隐藏属性推拉合并为一次 `TryApply`**，从而「一个事件 = 一次事务 = 一个存档点」。**分工已定案：计算归 combat-service、施加归本服务**——奖励厚度、失败侧 lifeTotal 扣减（道念差 **1:1**）与可选奖励的玩家选择**全部在战斗流程内完成**，本服务收到的 `Spoils` 已是最终 spec，不再重算。Source: `handoffs/2026-08-02-momentum-conversion-reward-structure-and-mtg-stack.md`。
- **隐藏属性跨档时附一条定性叙事。** `eventEnd` 合并施加隐藏属性推拉；若某属性因此**跨过一个隐藏档位**，则在 `ResolveOutcome` 上附带一条定性描述（不给数字）随事件收口一并呈现。**复用既有链路，无新结构**；档位与文案归 `plot-manager.md`。Source: `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。

**事件面：**

| 事件 | 负载 |
|------|------|
| `CycleStarted` | `(string CharacterId, int Chapter, ulong Seed)` |
| `EventResolved` | `(string CharacterId, string InstanceId, string EventId, AdvanceMode Mode, int LifeSpanRemaining)` |
| `ChapterCompleted` | `(string CharacterId, int Chapter, Realm ReachedRealm)` |
| `CharacterDefeated` | `(string CharacterId, DefeatReason Reason, int RetriesLeft)` |

负载**只带 `Id` + 值类型**，绝不带 `CharacterProfile` / `EventOption` 引用（传引用等于给订阅者开一条绕过唯一写入入口的旁路，也让定稿实例有被下游改写的可能）。需要完整实例的订阅者按 `InstanceId` 向 future-event-service 取。
- **数据契约：** 输入 / 输出以稳定 `Id` 引用内容与角色（经 `content-service.ContentRegistry` 解析）；持久化交 `sync-service`（原子写 + schema 版本）；RNG 由 SeedManager 从 cycle seed 派生（见 `systems/common-properties.md`）。
- **自动存档点：** 在状态机边界（轮回开始、每个事件结算后、篇章边界、轮回结束）**以及事件推进过程中的每个决策点**（含战斗内）触发 —— 每点**立即原子写本地缓存**，网络上行则经 `sync-service.Push(profile, reason, policy)` 按 **5 秒防抖**合并；**篇章边界 / 轮回结束 / `defeated` / 进入战斗前 / 应用失焦挂起**为 `Immediate`，不受防抖约束。存档点清单本身**未因频率考量而改动**（存档点与 push 已解耦）。每个存档点同时更新 `CharacterProfile.LastContentVersion`。Source: `handoffs/2026-07-27-content-gating-offline-resilience-and-rng-persistence.md`。
- **`StartCycle` 附带写入：** 生成 `Rng.CycleSeed`、派生四条子流、写 `StartContentVersion`（此后不变）。
- **战斗内随机不直接用 `combat` 子流**，而由 combat-service 每场再派生 `Hash64(combatStreamSeed, eventId, attemptIndex)`，防「退出重进」重掷。见 `systems/common-properties.md`。
- **状态机（CharacterProfile.status）：** `ongoing → completed`（篇章通关）或 `ongoing → defeated`（主动弃置 / 寿元归 0 / lifeTotal 归 0）。`completed` 解锁下一篇章可挑战角色；`defeated` 清理数据并消耗重试次数。

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- **境界存档 · 篇章重试模型（四境三篇章、全部继承、状态机、重试无限/3/1、篇章解锁）** → `decisions/ADR-0004-realm-checkpoint-retry-model.md`（Accepted）。
- **强制在线 · 云端权威（含重账号）** → `decisions/ADR-0003-online-cloud-authority.md`（Accepted）。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **决策点的粒度。** 「事件过程按决策点落存档」已定，但决策点具体指哪些位置（事件内每次选择后？战斗内每回合开始 / 每次出牌后 / 每次结算后 / 三步中的某个步边界？）未定；粒度直接决定本地写入频率与 push 防抖压力。**「须覆盖响应窗口与优先权移交」这条加压已作废**（交互与优先权已移除，见 `combat-service.md`），回合内的可退出时刻回落到回合 / 出牌这一级。**战后奖励选择已明确不是决策点**（奖励预先算好，退出重开得到同样的选项）。→ `combat-service.md`、`sync-service.md`。Source: `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md` + `handoffs/2026-08-02b-stack-without-interaction-and-three-step-turn.md`。
- **`AdvanceEventAsync` 的取消触发方。** 取消后的**成本处置已定**（`SelectCost` 不回滚，视同已结算）；仍待定的是「**谁**会取消一场进行中的事件 / 战斗」（玩家主动退出？断线？应用挂起？），以及取消时如何与最近的决策点存档对齐。→ `combat-service.md`、`sync-service.md`。Source: `handoffs/2026-07-27b-service-api-contracts.md` + `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md`。
- **跳过语义的残留细节。** 主干已定（`mode = Skip`；通常不扣 `lifeSpanCost`；计入 `pastEvent`；单项补位）；仍待定：能否整批全跳、付不起 `skipCost` 时如何表现、`pastEvent` 区分两种痕迹的 schema。→ `systems/adventure-event/common-properties.md`。Source: `handoffs/2026-07-26-event-priority-skip-semantics-and-hotfix-scope.md`。
- **`attemptIndex` 是否还需要（动机已被消解）。** 防 re-roll 派生式 `Hash64(combatStreamSeed, eventId, attemptIndex)` 的原始动机是「退出重进会重掷战斗随机」；**决策点存档 + RNG `State` 持久化已从根上关闭该窗口**。剩下的问题收窄为：**篇章重试（ADR-0004）重开同一篇章时，同名事件是否应换一套战斗随机**——若应，`attemptIndex` 保留并取「篇章重试的第几次」（复用 ChapterManager 的既有计数）；若不应，该派生层可整个去掉。→ 亦见 `combat-service.md`、`systems/common-properties.md`。Source: `handoffs/2026-07-27-content-gating-offline-resilience-and-rng-persistence.md` + `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md`。
- **元进程持久化范围：** `PlayerPower` / `PlayerItem` / `Achievements` / `GameSetting` / `AccountInfo` 语义已澄清（见「意图」），但**各自字段结构与解锁 / 获取 / 失去的具体触发**仍待定；账号级 meta 或许值得单独一份系统文档。**PlayerPower 平衡边界**（防 pay/grind-to-win、是否影响 cycle seed / 计分公平）待定。
- **后端 / 账号合规落地：** 已定**强制在线 · 云端权威 + 重账号**（`decisions/ADR-0003`）；仅剩实现级待决：后端 / 账号系统具体选型、合规落地（PIPL / 实名 / 防沉迷 / 渠道审核 / 注销 / 数据导出）——这些归**后端库**，见 `backend-design-documents/open-questions.md`。Source: `handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。
- **隐藏属性细节：** 属性隐藏、`faith` = 道心、寿元按 `lifeSpanCost` 扣减 / 归 0 → defeated 均已定案；仍待定：**隐藏属性完整清单**（道心 / 煞气 / 寿元之外）、**各自的隐藏档位划分与阈值**（跨档定性反馈的触发依赖它）、增减触发、是否有非境界突破的寿元增长途径、AdventurePlot 树的数据编码（归 `systems/services/plot-manager.md`）。Source: `handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md` + `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。
- **`experiencePoint` 的阈值曲线与产出分布（08-02 改写）。** 载体已定案（新字段、每级一个阈值、事件发经验、失败也给）；仍待定：**各级阈值曲线**、单次事件的经验给予量、在事件池中如何分布、失败给的比胜利少多少。**它与寿元预算的花法互相约束**——事件总数少则单次给予必须更厚。→ `systems/game-progression.md`、`systems/balance.md`。Source: `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md` + `handoffs/2026-08-02-momentum-conversion-reward-structure-and-mtg-stack.md`。
- **重试上限可变后的存档表达（08-01b 新增）。** 上限由付费礼包改写为「无限 / 9 / 3」（见 `systems/monetization.md`），故 `RetryChapter` 的判定要读 PlayerProfile 上的持有状态。它落成什么——一个 `CapabilityFlag`、modifier pipeline 的一条具名修正，还是一个独立的 `Entitlement` 字段？→ `profile-service.md`、`systems/player-profile/`。Source: `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。

## 对应
提炼至：`.claude/knowledge/systems/life-cycle-service.md`（引用层，待建）。
