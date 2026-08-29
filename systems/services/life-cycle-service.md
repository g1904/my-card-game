# life-cycle-service（服务）

> 轮回生命周期服务：开始（seed）、推进、胜/负、清理、篇章继承、状态机、重试模型。**对 `character-profile` / `player-profile` 提供 API 的服务层**。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **两层持有模型（大局骨架，细节未定）。** 账号级的 **玩家信息 / PlayerProfile** 跨轮回持久，持有一组 **角色信息 / CharacterProfile**；每个 CharacterProfile 是一次轮回 / 一个角色的状态与历史，对齐 CycleState 概念。life-cycle-service 是操作这两层的服务。
  - **PlayerProfile（元进程层）：** 持有一组 `CharacterProfile`，以及账号级的能力 / 道具 / 成就 / 图鉴 / 统计 / 设置 / 账号信息等——它们**独立于任何单次轮回**。**完整字段表见 `systems/player-profile/_index.md`**，本文件不复述字段清单。
  - **CharacterProfile（单次轮回）：** 一次轮回 / 一个角色的状态与历史——`status`（**ongoing | defeated | completed**）、当前篇章与境界、数值型运行状态 `Status`（含**隐藏属性** 道心 / faith、煞气 / Bloodlust、寿元 / lifeSpan）、修行历程 `pastEvent`（存的是定稿实例快照 + 本次结算的最终账，不是 `Resource`）、储物袋、以及 **AdventurePlot 进度锚点**（剧本正文不落存档，作为本地内容条目经 ContentRegistry 读取，见 `systems/services/plot-manager.md`）等。**完整字段表见 `systems/character-profile/_index.md`**，本文件不复述字段清单。
- **角色状态分类法。** `status` 收敛为单一终态集 `ongoing | defeated | completed`：`discarded`（主动弃置）是 `defeated` 的一个**原因子类型**。`defeated` 与 `completed` 数据都会在轮回结束时被清理。
- **寿元按 AdventureEvent 扣减、归 0 → defeated。** 隐藏属性 **寿元 / lifeSpan** 是独立于 `lifeTotal` 的寿命预算（炼气起始 100、抵达筑基 +100、抵达金丹 +300、抵达元婴 +500——元婴为游戏终点，该增量无可消耗预算，仅作最后一次数值更新并存档），初始隐藏；**30% 起给定性叙事提示、10% 起给红字数值倒数**（见 `ux/screen-flow.md`）。**每完成一个 AdventureEvent，life-cycle-service 按该事件的 `lifeSpanCost` 扣减寿元**（内容侧为正数量值，物化时已取负）；递减到 **0** 即触发「大限将至」，角色置 `status = defeated`。`lifeSpanCost` 是 AdventureEvent 的共有字段（见 `systems/adventure-event/common-properties.md`），其分档是**控制篇章时长的主旋钮**（见 `systems/balance.md`）。
- **剩余寿元跨篇章结转。** 篇章突破时**不清空剩余寿元**：下一篇章的可用预算 = **该篇章增量 + 上一篇章的剩余**（例：第二篇章 = `+100 + 第一篇章剩余`）。因此「省着花」有**跨篇章回报**，寿元成为一条贯穿整个轮回的资源线，而非每章重置的计时器。它是 ChapterManager 在篇章边界的一项明确职责。

  - **推论：寿元百分比的分母 = `CharacterProfile.Status.ChapterLifeSpanBudget`（承重）。** 结转使寿元没有固定分母——若拿「本章增量」（100 / 100 / 300）作分母，省着花的玩家在第二篇章一开局就可能超过 100%，30% / 10% 阈值的含义随之漂移。**ChapterManager 在篇章边界把「结转后的可用预算」冻结为该字段**，此后一章之内不变；它同时给了「寿元还剩多少比例」一个可显示、可复算的口径，供 EventOption 界面的静态标注读取。**这是既有篇章边界职责的一个赋值，不新增存档点、不新增流程**；篇章重试时随该篇章起始存档一并带回。
- **`lifeTotal` 归 0 → `defeated`（第二条终结路径）。** **`lifeTotal`** 是角色的生命值（见 `systems/character-profile/life-total.md`）；它按战斗失败的道念差被扣减，**归 0 即 `status = defeated`**，与「寿元归 0（大限将至）」并列。二者分工：**寿元按事件流逝，lifeTotal 按失败流逝**。**恢复途径 = AdventureEvent 的 reward**，与等级 / `manaLimit` 同走 `ProfileChangeSpec` → `TryApply` 链路。**`DefeatReason` 里没有「输掉一场普通战斗」这一项**——输一场 `Practice` / `Standard` 战斗本身不终结角色，扣的是 `lifeTotal`，故对应项是 **`LifeTotalExhausted`**。终结原因恰四种：**主动弃置 / 寿元耗尽 / lifeTotal 耗尽 / 渡劫失败**——前三种是资源触底，末一种是篇章闸门（`Finale` 档失败即终结，见 `systems/adventure-event/combat/_index.md`）。
- **重试上限是基线值，可被付费礼包改写。** ADR-0004 的「无限 / 3 / 1」**不是常量**：持有 premium bundle 的账号为「**无限 / 9 / 3**」。
  - **`RetryChapter` 的上限判定读 `profile-service.HasPremiumBundle`**（只读属性、单点查询，`=> Entitlement.BundleGrantOrdinal > 0`），**不读任何事件负载、不缓存**。
  - **两档上限表是数据不是常量**：「无限 / 3 / 1」与「无限 / 9 / 3」两行落 `systems/balance.md` 的平衡资源，本服务读 `HasPremiumBundle` **选行**。**可重复购买不产生第三行**（③ ④ 只在首次购买生效）。
  - 见 `systems/monetization.md`。
- **等级成长 = 事件产出经验值。** 境界内等级（见 `systems/game-progression.md`）由 **AdventureEvent 的 reward 给予**——**不只绑定 Combat / Practice**，也**不只有胜利才给**：失败同样可能有产出。**产出的是 `experiencePoint`（经验值）而非等级本身**：每个等级各有一个升级所需的经验阈值，累积达阈值才升级——**事件不直接给等级**。**推论：`experiencePoint` 是 `CharacterProfile.Status` 上的一个新字段**，与 `lifeTotal` / `mana` / 隐藏属性同属角色状态；升级判定是 ProfileManager 施加经验后的一次派生检查。它与 `manaLimit` 同属一套「由事件 cost / reward 推拉」的成长体系，走同一条 `ProfileChangeSpec` → `TryApply` 链路。阈值曲线与产出分布未定，见待决问题。
- **多角色并存 + 每篇章至多一个 ongoing（语义已确认）。** 玩家可同时持有多个 CharacterProfile；但**每个篇章内至多一个 `ongoing`**——只要有一个角色在该篇章尚未结束进程（ongoing），就**不能在该篇章使用其他角色游玩**；不同篇章之间可各自并行。
- **篇章继承：全部继承。** 读档续章时，角色带入下一篇章的是**上一篇章的全部信息**（deck、法宝、属性、叙事标记等），无逐项筛选。
- **篇章解锁触发。** 解锁触发 = **角色通关上一篇章**，随即成为下一篇章的**可挑战角色**；若某篇章没有可重试 / 可挑战的角色，该篇章**重新进入锁定（隐藏）**状态。见 `ux/onboarding.md`。
- **篇章存档 · 读档续章 · 重试模型。** 篇章通关即在所达境界落一个**存档点**（如打通炼气→筑基得到筑基存档）；可读档从该境界起始下一篇章。**炼气起手为随机角色，失败可近乎无限重试**；而**落过境界存档的角色，在后续篇章有有限的重试次数**——存档角色是一种会被耗尽的有限资源。**重试上限（四境三篇章 · 基线值）：** 第一章（炼气→筑基）= **无限**；第二章（筑基→金丹）= **3**；第三章（金丹→元婴）= **1**——**持有 premium bundle 的账号为 无限 / 9 / 3**（见 `systems/monetization.md`）。挑战成功进入下一境界，不能重试之前篇章。
- **重试计数只有一种：篇章重试，由 `CharacterProfile.chapterRetry` 承载。** **`chapterRetry` 是 `CharacterProfile` 上的一个类**，计数第一 / 第二 / 第三篇章各自的重试次数——**因为 ch2 与 ch3 有重试上限**（无限 / 3 / 1，持 premium bundle 为 无限 / 9 / 3）。
  - **它是计数器容器，不是上限持有者。** 上限值仍按 ADR-0004 的既定纪律读取（**可被账号级持有状态改写，凡读取处不得硬编码常量**）；`chapterRetry` 只答「用掉了几次」，「还剩几次」是它与上限的差。
  - **推论：篇章解锁 / 重新锁定与「剩余重试次数展示」有了确定的数据源**——「某篇章无可重试角色时重新锁定」的判定此前没有明确的读取字段。
  - **形态 = 三个具名字段、通关后保留计数。** 不用字典 / 索引数组（篇章数是固定的游戏结构，不是可扩展列表）；不清零，故计数同时是一份历史。
  - **ch1 的角色级计数恒为 0。** ch1 重试 = 随机生成新角色，角色级 ch1 计数因此对每个新角色恒为 0；「你在炼气段重开了多少次」**目前没有字段回答**——`PlayerStatistics` 首批只有 `TotalCyclesCompleted` / `TotalCyclesDefeated`，后者不区分篇章，需要时纯加法补一项。**两层口径不同**：**只有角色级参与规则**（与上限相减得「还剩几次」，是 `RetryChapter` 的闸门输入），账号级是纯读数、跨角色累加、不参与任何判定。
  - **不设事件级或篇章级的重试次数上限**（「同一事件重试 < N 次 / 篇章重试总数 < N 次 / 超限强制 defeat」一类）：它要防的退出重进作弊已由决策点存档从根上关闭，再加一层计数上限只是在惩罚正常的中断游玩。
- **篇章重试 = 重开一局。** 重试时**换一套随机流**——角色状态仍按 ADR-0004 从该篇章起始存档带回（**「篇章继承 = 全部继承」不变**），变的只是这一遍的随机。**「重开一局」说的是随机流，不是角色。** **推论：战斗随机不需要 `attemptIndex` 派生层**（见下条）。
- **事件过程按决策点落存档。** 一个 AdventureEvent 的推进过程**不是存档盲区**：**战斗与其他事件一律在决策点落存档**，使「退出重进」恢复到同一个局面与同一份 RNG 状态。这从根上关闭了「退出重掷」的作弊窗口，因此无需再用重试计数去堵。**`selectCost` 不回滚**——选中事件时施加的成本（含 `lifeSpanCost`）一经施加即成事实，中途退出不退还。这同时答结了 `AdvanceEventAsync` / `RunCombatAsync` 取消语义中「已施加的 `SelectCost` 如何处置」的问题：**视同已结算，不回滚**。逐类的决策点清单：战斗内见 `combat-service.md` 的 D0–D7，其余四类见下方「非战斗四类的事件内决策点」。
- **账号级能力 / 道具语义（已澄清）。**（细节结构权威见 `systems/player-profile/`。）
  - **PlayerPower：** always-available 能力，带**开关（默认开启）**；可为 **QoL** 或**影响公平性的一定加强**（需衡量平衡），**通常全局、不与角色绑定**；获取越多后续越易，但 **AdventureEvent 过程中也可能失去**已获取的 PlayerPower。**定位 = 轻度提升（light improvement）：** 承认它影响平衡，但因**本作无 PvP、纯 PvE**，让 power 带来一定强度是**可容忍的**，并**打开更大的设计空间**。
  - **PlayerItem：** 有**使用次数限制**的道具。
  - **Achievement：** 玩家**只能查看进度 / 领取奖励**；奖励按**组内加权进度**发放（见 `ux/screen-flow.md`）。
- **属性模型 = 隐藏。** 借鉴 **Reigns** 的属性模型，但**与 Reigns 相反：属性隐藏、不作可见仪表**，在背后影响 AdventureEvent。隐藏属性（**道心 / faith**、**煞气 / Bloodlust**、**寿元 / lifeSpan**）落在 `CharacterProfile.Status` 内，随轮回推进被 AdventureEvent 推拉；达阈值驱动 **AdventurePlot（隐藏剧本层）**——见 `systems/services/plot-manager.md`。

Source: `handoffs/2026-07-15b-taxonomy-and-checkpoint-clarifications.md` · `handoffs/2026-07-22-online-cloud-combat-and-meta-clarifications.md` · `handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md` · `handoffs/2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md` · `handoffs/2026-07-27-content-gating-offline-resilience-and-rng-persistence.md` · `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md` · `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md` · `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md` · `handoffs/2026-08-02-momentum-conversion-reward-structure-and-mtg-stack.md` · `handoffs/2026-08-06-ch1-band-widening-cross-realm-crush-and-chapter-retry.md` · `handoffs/2026-08-06b-asymmetric-ch1-band-consented-power-loss-and-chapter-retry-shape.md` · `handoffs/2026-08-12d-hidden-stat-bands-and-crossing-narrative.md` · `handoffs/2026-08-15b-monetization-entitlement-purchase-shape-and-scope.md` · `handoffs/2026-08-17h-profile-field-schema.md` · `handoffs/2026-08-22-finale-failure-is-death.md` · `handoffs/2026-08-22-non-combat-decision-points.md` · `handoffs/2026-08-23g-hidden-stat-combat-boundary-event-backdrop-and-itemized-rewards.md`

## 管理器

| manager | 职责 |
|---------|------|
| **CycleStateManager** | `status` 状态机：`ongoing → completed \| defeated`；终态判定与清理 |
| **ChapterManager** | 篇章边界、境界存档点、篇章继承、**剩余寿元结转 + 下一篇章寿元增量 + 把结转后的可用预算冻结为 `Status.ChapterLifeSpanBudget`**（寿元百分比档位的分母，见下）、重试上限（基线 ∞ / 3 / 1；持礼包为 ∞ / 9 / 3）、解锁与重新锁定 |
| **SeedManager** | `CycleSeed` 持有；按 **`Hash64(CycleSeed, streamName)`** 派生具名 RNG 子流（map / combat / shop / reward），互不干扰；**子流清单是本 manager 内的常量**；存 / 取 `State` + `DrawCount`，读档时对新增 / 移除子流分别 warn + 初始化 / warn + 丢弃 |

## 服务角色 / API 面（契约）
> _life-cycle-service 作为服务（判据 ① —— 拥有轮回的状态机），提供轮回生命周期 API。总则与共享类型见 `systems/architecture.md`「API 契约总则」。本服务**纯本地**，永不跨进程边界，故不实现 `IBootstrappable`。_

- **服务定位。** life-cycle-service 不持有独立数据；它是这两个「类」的轮回生命周期操作面。上层（**编排顶点 game-progression**）通过它开始、推进、结算、清理一次轮回，而非直接改这两层的字段。
- **一切 Profile 写入经 `profile-service.ProfileManager`。** 本服务负责**状态机与编排**，不直接改 Profile 字段——扣成本、加产出、推拉隐藏属性都以 `ProfileChangeSpec` 交给 ProfileManager 原子施加（全有或全无）。

| 方法 | 形态 | 完整签名 | 失败语义 |
|------|------|----------|----------|
| 开始轮回 | A | `OpResult<CharacterProfile> StartCycle(CycleStartSpec spec)` | 业务失败（该篇章已有 ongoing、重试次数耗尽）→ `OpResult` |
| 推进 | **C** | `Task<AdvanceResult> AdvanceEventAsync(EventOption chosen, CancellationToken ct)` | 业务失败 → `AdvanceResult`，绝不抛 |
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
    AdvanceStage FailedAt,      // None | ModeRejected | InnerFlow | OutcomeRejected | Cancelled
    CycleStatus  StatusAfter);
```

- **`CycleStartSpec.Seed` 的生成方：`RetryChapter` 内部生成一个新 seed，与首次 `StartCycle` 走同一条生成路径。** 篇章重试 = 换一套完整的新随机流（地图、事件池、商店、奖励、战斗全部不同），故 `attemptIndex` 无事可做、整层删除。见下方「取消语义」与 `systems/common-properties.md`。

四点推演：

- **`AdvanceEventAsync` 收 `EventOption`（定稿实例）而非 `AdventureEventData`。** 它需要**物化时置位**的 `Priority` / `SelectCost` 来校验「这一步合法吗」并施加成本。**不收 `AdvanceMode`**——推进只有一种形态。传 `Resource` 就拿不到这些字段，且会诱使调用方回查模板重算，违「产出即定稿」（见 `systems/architecture.md` 总则 6）。
- **不收 `character` 参数。** 每篇章至多一个 `ongoing`（ADR-0004），当前角色是本服务状态机的持有物；把它当参数传等于允许调用方指定「对哪个角色推进」，是一处不必要的越权面。（`StartCycle` / `RetryChapter` 例外，它们要选角色。）
- **返回 `AdvanceResult` 而非 `void`。** 编排顶点需要一个可判定的返回值——**推进后的 `StatusAfter`** 尤其关键：`selectCost` 支付后可能直接判负，编排顶点据此转入失败流程而非事件屏。
- **`AdvanceStage` 没有 `CostRejected`，`AdvanceResult` 没有 `MissingElement`。** 「付不起 → 拒绝，回到呈现步」这条回路在本作不存在（`selectCost` 无条件施加），故这两个成员**不可达**；不可达的拒绝语义留在类型上不只是死代码，它会主动诱导后来者把付得起校验加回推进路径。**主动消费侧的拒绝语义仍然完整**——`ProfileService.CanAfford` 与 `ApplyResult.MissingElement` 保留给 Exchange 的商店购买，见 `systems/services/profile-service.md`。
- **`Stream(RngStream)` 暴露 `RandomNumberGenerator` 而非 `int Next()`。** Godot 的 `RandomNumberGenerator` 自带可序列化的 `Seed` / `State`，正是既定 RNG 持久化形态（`State` + `DrawCount`）的载体；各子流独立实例天然满足「互不干扰」。

### `AdvanceEventAsync` 的固定结算流程

`eventStart` / `eventEnd` 是**本方法内部结算流程的两个阶段名**，不是 `AdventureEventData` 上的方法（见 `systems/adventure-event/common-properties.md`「结算阶段」）：

```
校验选项合法性（Priority < EffectivePriority → 拒绝）
  → TryApply(SelectCost + EventStateChanges[ActiveEvent = 该项原样拷贝])  ← 同一次事务；不做「付得起」校验
  → 终态判定 ①（支付后立即）                 ← 判负 → 短路进失败流程，activeEvent 随失败流程一并清理
  → 【eventStart 阶段】选 resolver、Explore 揭示
       Explore：TryApply( EventStateChanges[ActiveEvent = option with { IsRevealed = true }] )
  → resolver.ResolveAsync(activeEvent.Option, ct)   ← 传派生后的那一份；Combat/Finale 转 combat-service
       Exchange 刷新（玩家主动按下）：
         TryApply( Elements[SpiritStone, -刷新价] + EventStateChanges[ActiveEvent = 刷新后的那一份] )
  → 【eventEnd 阶段】五步组装（见下）→ **一次** TryApply
  → CycleStateManager 终态判定 ②（结算后）→ EventBus 广播 → sync 自动存档点
```

**`eventEnd` 的五步组装顺序（承重）：**

```
① 组装收口 spec 的全部「重算依据」列：
     Elements(ResolveOutcome + lifeSpanCost) · AbilityElements · Stats
     · StatusChanges(三个 band + 两个 location，绝对值由本服务算出)
     · DeckElements · PlotElements
     · EventStateChanges[ActiveEvent = null, ActiveCombat = null]
     · TraceElements[本次 PastEventEntry]      ← 快照取自 activeEvent.Option；
                                                  LifeSpanAfter 由「前值 + 本次账」纯函数算出并钳制
     · CodexElements[本次事件的收录]           ← 条目由 CodexManager 采集并展开后交来
② projected = Project(spec)                    ← 其 pastEvent 已含本条、Status 已是结算后值
③ 新一批 = RefreshAfterEvent(projected)        ← 消耗 map 子流
④ 以 with 派生补齐两列（且只补这两列）：
     EventStateChanges[EventOption = 新一批]
     RngElements[本次事件内消耗过的全部子流的终态]
⑤ 一次 TryApply(spec) → 终态判定 ② → EventBus 广播 → 自动存档点
```

- **`PastEventEntry` 必须在投影之前进入 spec。** 「整批重算的依据 = 角色的整体历程，重度依赖 `pastEvent`」要求新一批看得见刚走完的这个事件；痕迹若留在事务之外，新一批依据的是一份**少一条**的历程。
- **闭合性条件（承重）：`Project` 之后只允许追加「不构成重算依据」的列。** 恰有两列符合——新一批不依赖自己，重算读的是随机源而不是 `State` 字段。**任何新增列默认落在 ① 之前**；要放进 ④ 必须显式论证它不是重算依据。落为 `#if DEBUG` 断言：投影视图记下投影时的列指纹，`TryApply` 时若 ① 类列发生变化 → `PushError`。**这一条取纪律阶梯第 3 级即可**——「投影之后改了 ① 类列」是组装代码的静态形状，开发期必现；投影视图本身的「不跨 `await` 持有」则做到第 1 级（`ref struct`），见 `systems/services/profile-service.md`。
- **`CodexElements` 落 ① 类列，采集与展开归 `CodexManager`、并入 spec 归本服务。** 落 ① 而非 ④ 是缺省——④ 只容得下「不构成重算依据」的列，而放宽这个缺省要为每一列各做一次论证；图鉴收录并入 ① 不需要任何论证，且**零成本**（新一批不读图鉴，位置对结果无影响）。这与 band / location 两组 `StatusAssignment` 的分工同款：**采集与判定归专责 manager，组装进收口 spec 归本服务**，保住「收口是一次事务、一个存档点」。触发口径与逐本组装方见 `systems/player-profile/codex/common-properties.md`。

```csharp
internal interface IEventResolver          // 按 eventType 注册，共 2 个实现
{
    Task<ResolveOutcome> ResolveAsync(EventOption option, CancellationToken ct);
}
// CombatEventResolver  → Combat（三个 combatTier 档共用），转 combat-service
// GenericEventResolver → 其余四类，读物化后 EventOption 上的定稿 OutcomeSpec
```

- **五类事件只有两个 resolver**——与既定拆分轴「只有 Combat 真有状态机、其余差异在数据而非代码」一致，保住「新增一个事件 = 新增一个 `.tres`」的可加性。
- **推进只有一种形态。** 没有 `AdvanceMode` 枚举、没有 skip 分支、`pastEvent` 只有「进入并结算」一种痕迹。**理由：每次结算后 eventOptions 整批重算，选中一个本就等价于跳过其余。**
- **终态判定有两处。** ① **紧接 `TryApply(SelectCost)` 之后**——支付本身可能耗尽寿元，此时**短路进失败流程**，事件不再结算；② 事件结算后照常判定。这是「支付 `selectCost` 是可推进行为、支付后判定状态、判负进失败流程」的直接落地；**「付不起则拒绝、不产生任何写入」不是本作的语义**。
- **两处判定共用一个私有方法。判据 = 一条显式旁路 + 一张资源表。**

  ```
  终态判定(character, finaleFailed):
      if finaleFailed:                                    ← 旁路：非资源触底的终结
          DefeatCharacter(DefeatReason.FinaleFailed); return;
      foreach (key, spec) in ResourceElements where spec.DepletionDefeat != null:
          if 读取(character, key) == spec.Min:
              DefeatCharacter(spec.DepletionDefeat.Value); return;
  ```

  - **表驱动那一半承担全部「资源触底」型终结。** 逐字段硬编码检查寿元与 `lifeTotal` 会让「新增一个终态资源」变成改判定逻辑；查表使它变成表里加一行 + `DefeatReason` 加一个成员。判据写 `== Min` 而非 `<= 0`，是因为施加侧已截断到 `Min`，两种写法同解。表的定义见 `systems/architecture.md`「共享核心类型」，逐行取值与理由见 `systems/services/profile-service.md`。
  - **⚠ 旁路那一半是必须的，不能塞进表里（承重）。** Finale 失败**不是任何资源触底**——它没有对应的 `CostKey`，`ResourceElements` 表里没有、也不该有它的一行。**实现侧不能以为「照表走就行」**：判定②在 Finale 事件上必须先问一句「本次是否 Finale 失败」。这是表驱动之外的**唯一一条**旁路，新增终态资源仍照表扩展。
  - **旁路只在判定②生效。** `finaleFailed` 由本次事件的 `CombatResult`（`Tier == Finale` 且 `Outcome == Defeat`）得出，而判定①在 `TryApply(SelectCost)` 之后、事件尚未结算，恒无战斗结果 ⇒ 判定①的入参恒为 `false`。
- **`eventEnd` 阶段把 `CombatResult.Spoils`（一份 `ProfileChangeSpec`）连同 `lifeSpanCost`、**战斗失败时按道念差扣减的 lifeTotal**、等级产出与隐藏属性推拉合并为一次 `TryApply`**，从而「一个事件的收口是一次事务、一个存档点」。**分工：计算归 combat-service、施加归本服务**——奖励厚度、失败侧 lifeTotal 扣减（道念差 **1:1**）与可选奖励的玩家选择**全部在战斗流程内完成**，本服务收到的 `Spoils` 已是最终 spec，不重算。
- **事件内部的主动消费即时提交，本服务只在收口时把它们记进账。** 古宝使用次数、战斗过程中的血 / mana、Exchange 的逐笔交易由各自的消费点**即时经 `ProfileManager.TryApply` 写档**（纪律与两条判据见 `systems/adventure-event/common-properties.md`）。本服务在组装 `PastEventEntry` 时**把这些已提交的 spec 累加进 `AppliedChange`**——**记账，不再施加**；`AppliedChange` 因此是「本次事件的最终账」，而不是收口那一次 `TryApply` 的入参。**代价明写：两者不再逐字段相等，一致性不能再机械断言。**
- **`eventEnd` 合并时校验授予来源的组装归属（单向）。** 合并出的 spec 内凡 `Op == Grant` 的 element：**本次事件未走过 combat-service**（等价于未产生 `CombatResult`）却带 `Source == CombatReward` → **必需缺失**，`GD.PushError` + **整批拒绝**；反向（走过 combat-service 的事件里出现 `EventOutcome`）**不判非法**——战斗事件除 `Spoils` 外仍可携带事件级 outcome。**判据取「是否走过 combat-service」，不取 `EventOption.EventType`**：Explore 选项的 `EventType` 恒为 `Explore`，照它判会把一个揭示出战斗真身的事件的合法 `CombatReward` 误判为非法并整批拒绝。单向而非双向，与 `(CarrierKind, Scope, Source)` 入口校验同属「入口严、读档宽」一档；读档侧照旧宽（保留原值、不改写）。见 `systems/common-properties.md`。
- **Finale 结算额外并入道统残卷的一组 element。** 该事件 `eventEnd` 的那一次 `TryApply` 在 Finale 上多承载一组账号级写入，**不新增结算阶段、不新增存档点**：
  - **失败**（`d < 0`；该角色在同刻终结，见上方终态判定）：`PlayerPowerFragment.Accumulated` 按 `(x, chapter)` 分档表累加（钳制到 10000）；**不掷骰、不发放**。
  - **⚠ 写入顺序纪律（承重）：`Accumulated` 的累加必须在角色终结提交之前完成。** 它是**账号级**写入（落 `PlayerProfile`），而 `DefeatCharacter` 会走**角色终态数据清理**（见 `decisions/ADR-0004-realm-checkpoint-retry-model.md`）。落地顺序固定为：**`eventEnd` 的那一次 `TryApply`（含账号级残卷累加）提交成功 → 终态判定② → `DefeatCharacter`**。**顺序颠倒 = 「Finale 失败累积残卷」这条机制在每一次失败上都丢**——而失败恒等于终结，即该机制 100% 失效、且失效是静默的。
  - **通过**：`Spoils` 内含**授予法则** element（走既有 `ProfileManager.GrantPower(powerId, Source.FinaleWin)` 语义，只是这次由 Spoils 触发；**来源必须显式带上**——它是残卷分档自变量 `x` 的唯一数据源，见 `systems/common-properties.md`）+ `Accumulated` 重置 element + `FinaleWinOrdinal` 自增 element + 首胜标记置位 element + **`LastRoll` / `LastEffectiveChance` 两个中间值 element**（每次通过必写，即使当次不发放——后端据它复算，见 `systems/player-profile/_index.md`）。
  - **「通过」是一个二值判据（`d >= 0`），不分厚薄。** 勉强通过与碾压通过在残卷这条线上**完全同等**：照常掷骰、序号照常 +1、首胜照常置位并享 100%。**这四项不可拆**——`FinaleWinOrdinal` 同时是掷骰序号、幂等键与后端复算入参，「序号 +1 却不掷骰」会使后端校验稳定失败。**已知代价（接受）：** 玩家可能用一次刚好打平的通过，兑掉该篇章一生一次的首胜里程碑；反向的选项（不给或折算）会把「第一次渡劫成功却空手」这个体验事故按新判据重新制造出来。
  - **掷骰在本服务侧完成、走账号级 RNG**（**先算 `ordinal = FinaleWinOrdinal + 1`**，再 `AccountRng.For(AccountStream.PowerFragment, ordinal)`，最后把同一个 `ordinal` 随同一次 `TryApply` 写回——「先算后写」的通则与理由见 `systems/common-properties.md`；随机源是契约定义的纯函数 SplitMix64），**不经 SeedManager 的任何子流**——子流由 `CycleSeed` 派生而篇章重试会换 `CycleSeed`，挂上去即可刷。**`FinaleWinOrdinal` 是幂等键**，与决策点存档的防重掷同一条纪律。
  - 完整规则（分档表、首胜优先、重置口径、隐含呈现）见 `systems/player-profile/player-power/_index.md`；数值归 `systems/balance.md`。
- **隐藏属性跨档时附一条定性叙事（无新阶段）。** `eventEnd` 合并施加隐藏属性推拉；若某属性因此**跨入一个离常态更远的档**，则在 `ResolveOutcome` 上附带一条定性描述（不给数字）随事件收口一并呈现。**复用既有链路，无新结构、无新存档点**；档位表、阈值与回滞、文案规则归 `plot-manager.md`，呈现归 `ux/screen-flow.md`。

  ```
  eventEnd 阶段
    → 合并 ResolveOutcome + lifeSpanCost + 隐藏属性推拉为一次 TryApply        ← 既有
    → 【纯函数比对】对三个属性各算一次 newBand（读 Status 前值 + AppliedChange + 回滞）
         newBand != 存档 band  → 更新 Status 上的 band 字段（并入同一次 TryApply 的 spec，不另开事务）
         且 |newBand| > |oldBand| → 记一条跨档叙事；反向（回到离常态更近的档）只更新字段、不播
    → 本服务以 `with` 复制把 BandNarrativeIds 附加到 ResolveOutcome
    → 记入 pastEvent → 终态判定 ② → 广播 → 存档点                            ← 既有
  ```

  - **`ResolveOutcome` 增加一个字段** `IReadOnlyList<string> BandNarrativeIds`，**resolver 侧恒填空**，只由本服务在 `TryApply` 之后填——这保住「resolver 只描述结果、不自行写档」的既有边界。
  - **band 按「前值 + `AppliedChange`」算绝对值**；道心 / 煞气施加后截断到 `[0, 100]` **不构成终态**，且不影响档判定（最外档已覆盖边界），故与 `TryApply` 内部钳制无差异。这两个区间同时是「钳制必须逐 element 配表、不能定一条全局通则」的例证——它们与寿元的 `[0, ∞)`、残卷的 `[0, 10000]` 互不相同，且都不由任何通则给出。
  - **band 字段的写入并入 `eventEnd` 那一次 `TryApply`**，「收口是一次事务、一个存档点」原样成立。载体是 `ProfileChangeSpec.StatusChanges` 的 `StatusAssignment`（绝对置值），见 `systems/services/profile-service.md`。
- **地域位置与地域配额的写入同样并入 `eventEnd` 那一次 `TryApply`，由本服务组装。** `GenericEventResolver` 对 Travel **不产出任何写入描述**；两条 `StatusAssignment` 由本服务在组装 `eventEnd` 的 spec 时从 `option.DestinationLocationId` 直接读出并置入——与 band 字段由本服务算出绝对值、resolver 侧恒填空**同款**，保住「resolver 只描述结果、不自行写档」的边界。

  ```
  LocationEventCount 的新值 = option.DestinationLocationId != "" ? 0 : 前值 + 1
  CurrentLocationId  的新值 = option.DestinationLocationId != "" ? 该值 : 不提交这一条
  ```

  - **判据取 `DestinationLocationId != ""`，不取 `EventType == Travel`（承重）。** 前者一次性覆盖「Explore 揭示出的 Travel 也归 0」——该情形下 `EventType` 恒为 `Explore`，按类型判会漏；且它不需要在 `EventOption` 上再加一个 `RevealedEventType` 字段，也不需要回查模板（消费侧被明令禁止的动作）。这与 `eventEnd` 组装校验取「是否走过 combat-service」而非取 `EventType` 是同一条纪律。
- **两个事件态字段由本服务组装写入，与 band / location 字段同款。** `activeEvent` 在 `TryApply(SelectCost)` 那一次一并创建（值 = 当批那一项的原样拷贝），Explore 揭示与 Exchange 刷新各是一次对它的整体置值，`eventEnd` 置空；当前批 `eventOption` 在 `StartCycle` 写第一批、此后每次收口整块替换。载体是 `ProfileChangeSpec.EventStateChanges`（绝对置值），resolver **只描述结果、不自行写档**的边界原样成立。字段形态与读档校验见 `systems/character-profile/_index.md`。
  - **`activeEvent` 与 `SelectCost` 同一次提交的代价明写：** 终态判定 ① 判负而短路的那一路会留下一个非 `null` 的 `activeEvent`，**必须由失败流程一并清理**（失败流程本就要拆解整个 CharacterProfile，清理是免费的）。换来的是零新增提交，且「这一项已被选中」与支付落在同一笔——与「`selectCost` 不回滚、已经发生的事就是发生了」同向。
  - **收口时先投影后提交。** 新一批必须依**更新后的** profile 算出（`pastEvent` 是 future-event-service 的一等输入），故本服务先用 `profile-service.Project(收口 spec)` 得到一份未提交的只读视图交给 `RefreshAfterEvent`，再把算出的批以 `with` 派生回同一份 spec、一次 `TryApply`。**收口仍是一次事务、一个存档点**，且两次读取之间不存在决策点。投影视图**只在这一段同步代码内使用**，不存字段、不跨 `await` 传递；语义面与机械保证见 `systems/services/profile-service.md`。
  - **投影判负不改变流程。** 一份「已判负」的投影照常交给重算方、照常提交，`RefreshAfterEvent` 不多一个分支；短路要动的是「`Key == EventOption` 不得置空」这条承重校验，而白算一批只是一次纯内存物化，随失败流程一并拆解。
  - **`activeCombat` 与 `activeEvent` 在收口那一次一并置空**，两者共用 `EventStateChanges` 这一条通道。
- **凡消耗了子流随机的提交，该子流的 `State` / `DrawCount` 必须在同一次原子写内更新（不变式 · 承重）。** 两侧不同步各自都是可利用的漏洞：`State` 落了而结果没落 ⇒ 再做一次得到**不同**结果，等于绕过决策点存档的重掷通道；结果落了而 `State` 没落 ⇒ 下一次从同一 `State` 起掷、重复同一批结果，且 `DrawCount` 的诊断口径失真。
  - **恢复路径自校验：** `DrawCount` 与本次提交声明的消耗数不一致 → `PushWarning` 带 `characterId` + 子流名（可降级——它是诊断保险，不是恢复权威）。
  - **它同样约束 `activeCombat`**（`combat` 子流），不是事件态引入的新约束。
  - **载体是 `ProfileChangeSpec.RngElements`，不变式由结构兑现。** SeedManager 是唯一持有四条子流的地方，它按下面三条把「忘了带 RNG」变成可检出的：

    ```
    ① 每条子流记一个「自上次清账以来的消耗计数」pending[stream]
    ② 唯一组装路径 SeedManager.AttachRngState(spec) —— 把全部 pending != 0 的子流
       以当前 (State, DrawCount) 派生进 spec.RngElements，并清账；它是纯函数，返回新的 spec
    ③ #if DEBUG：决策点持久化 / 收口提交之前，组装方比对 SeedManager 的 pending 与 spec.RngElements，
       有未清账的子流没进 spec → PushError 带 characterId + 子流名（纪律阶梯第 3 级）
    ```

  - **③ 的检查点落在组装方（本服务 / combat-service 的决策点持久化前），不落 `ProfileManager` 入口。** 落入口要求 profile-service 认识 SeedManager，与「服务之间不读写对方字段」相反。**也不落在「取用子流之前」**：敌人整个回合内部不落决策点，其间数十次随机消耗之间没有任何提交，按取用时刻判会在每一场战斗里连续误报。
  - **`StartCycle` 的子流初始化与篇章重试的整流重置不走本列**（它们是附带写入 / 换一套新随机流），故 `DrawCount` 单调不减的入口校验不需要任何例外口子。

**事件面：**

| 事件 | 负载 |
|------|------|
| `CycleStarted` | `(string CharacterId, int Chapter, ulong Seed)` |
| `EventResolved` | `(string CharacterId, string InstanceId, string EventId, int LifeSpanRemaining)` |
| `ChapterCompleted` | `(string CharacterId, int Chapter, Realm ReachedRealm)` |
| `CharacterDefeated` | `(string CharacterId, DefeatReason Reason, int RetriesLeft)` |

负载**只带 `Id` + 值类型**，绝不带 `CharacterProfile` / `EventOption` 引用（传引用等于给订阅者开一条绕过唯一写入入口的旁路，也让定稿实例有被下游改写的可能）。需要完整实例的订阅者按 `InstanceId` 向 future-event-service 取。
- **数据契约：** 输入 / 输出以稳定 `Id` 引用内容与角色（经 `content-service.ContentRegistry` 解析）；持久化交 `sync-service`（原子写 + schema 版本）；RNG 由 SeedManager 从 cycle seed 派生（见 `systems/common-properties.md`）。
- **自动存档点：** 在状态机边界（轮回开始、每个事件结算后、篇章边界、轮回结束）**以及事件推进过程中的每个决策点**（含战斗内）触发 —— **每个决策点都是一个可退出点；该时刻若产生了尚未落盘的新状态，则立即原子写本地缓存**（非战斗四类的新状态已由既有写入覆盖，故不触发第二次写入，见下方「非战斗四类的事件内决策点」），网络上行则经 `sync-service.Push(profile, reason, policy)` 按 **5 秒防抖**合并；**篇章边界 / 轮回结束 / `defeated` / 进入战斗前 / 应用失焦挂起**为 `Immediate`，不受防抖约束。**`Immediate` 只声明「不等防抖窗口」，失败处置与 `Debounced` 完全相同**（进待发队列 + 指数退避 + **不阻塞玩家**）——它不是「必须成功」，见 `sync-service.md`「`Immediate` flush 的失败语义」。存档点清单本身**未因频率考量而改动**（存档点与 push 已解耦）。每个存档点同时更新 `CharacterProfile.LastContentVersion`。
- **`StartCycle` 附带写入：** 生成 `Rng.CycleSeed`、派生四条子流、写 `StartContentVersion`（此后不变）。
- **`disabledAbility` 的到期剔除由本服务在两个时点各跑一次纯函数。** 禁用表存的是「施加时坐标 + 时长」而非「到期坐标」（施加坐标是重算不出来的原始事实，到期判定是它的纯函数；篇章边界的 `Seq` 在施加当时还不知道）。剔除：

  | 档 | 剔除条件 | 剔除时点 |
  |---|---|---|
  | `NextEvent` | `currentSeq >= AppliedAtSeq + 1` | **记入 `pastEvent` 之后**（`eventEnd` 收口后） |
  | `ThisChapter` | `currentChapter > AppliedAtChapter` | **篇章边界**（ChapterManager 的一项职责） |
  | `ThisCycle` | —— | 无需剔除，随 `CharacterProfile` 整体拆解 |

  **不新增存档点**——两个时点本就是既定的存档边界。字段定义见 `systems/character-profile/_index.md`。
- **置换 / 禁用的施加落在 outcome 侧，是一个事件内决策点。** 能力 element **恒不出现在 `selectCost`**；置换候选在**物化时**走 `Reward` 子流掷定并随 `EventOption.AbilityChangeSlots` 落存档（否则退出重进可重掷），**该决策点因此不触发第二次写入**；玩家接受则 `Remove` + `Grant` 两条 element 并入 `eventEnd` 那一次 `TryApply`，拒绝则零 element、零代价。**形状与战后奖励面板完全同构，不新增结算阶段、不新增存档点。** 见 `systems/adventure-event/common-properties.md`。
  - **同构落在「逐项处置」这条轴上。** 置换面板是**逐槽接受 / 拒绝**，奖励面板是**逐项领取 / 跳过**——「拒绝 = 零 element、零代价」与「跳过」逐字同义，两者形状一致。差别只在存档：置换候选在**物化时**掷定并已随 `EventOption.AbilityChangeSlots` 落存档 ⇒ 该决策点不触发第二次写入；而奖励的领取进度是战斗内新产生的状态，需落 `activeCombat.reward`。
- **轮回结束时顺带写账号级统计计数。** `SavePointReason.CycleEnded` / 角色 `defeated` 那一次 `TryApply` 带上 `StatDelta(+1)`（`TotalCyclesCompleted` 或 `TotalCyclesDefeated`），**与规则字段同批、同事务**，不新增写入通道。字段见 `systems/player-profile/_index.md`。
- **终态判定 ① 判负短路的那一路也留一条痕迹，且与轮回结束的收尾落在同一次 `TryApply`。** 失败流程组装**一次**提交，同时承载 `TraceElements[Outcome = Aborted 的那一条]` + `EventStateChanges[ActiveEvent = null, ActiveCombat = null]` + `StatDelta(+1)` + 本次已消耗子流的 `RngElements` + `CodexElements[本次事件的收录]`。**不新增存档点**——这一步「成本已施加、事件未结算」的事实必须留痕且必须与正常结算可区分，而把它拆成两笔就重新制造了「同一个逻辑事件两次提交」，正是痕迹进事务要消掉的东西。**图鉴收录同样搭在这一笔上**：图鉴的判据是遭遇而非胜利，败于其手也要入账，而这条路径没有 `eventEnd` ——不带上它，战败者永远拿不到本场遭遇的词条。
- **战斗内随机直接用 `combat` 子流，不在其上再派生一层。** 「每场按重试次数再派生一次以防 re-roll」这条加法不要做：退出重进已由决策点存档 + RNG `State` 持久化封住，篇章重试则整个换一套新的随机流。见 `systems/common-properties.md`。
- **状态机（CharacterProfile.status）：** `ongoing → completed`（篇章通关）或 `ongoing → defeated`（主动弃置 / 寿元归 0 / lifeTotal 归 0）。`completed` 解锁下一篇章可挑战角色；`defeated` 清理数据并消耗重试次数。

### 非战斗四类的事件内决策点

> **判据与战斗侧共用同一条公理**（见 `combat-service.md`「决策点清单」）：**状态机即将停下来等玩家输入的时刻，且该时刻之前消耗的随机已全部反映在持久化的 RNG `State` 里**。判据不为非战斗类另立。

**落地口径（承重）：非战斗四类的决策点不触发第二次写入，它只是一个可退出点（`ct` 的观察位）。** 这四类**没有状态机**（resolver 的拆分轴就是「有没有状态机」）⇒ 每个决策点的全部可恢复状态**都已被既有的写入覆盖**——要么是 `activeEvent` 的一次整块置值，要么是即时提交的那一笔。**这一句必须写下来**，否则「决策点 = 存档点」会被读成「每个决策点都要新增一次持久化动作」，在非战斗类上凭空造出一批重复写盘。

| # | 决策点 | 精确时刻 | 持久化 | push policy |
|---|---|---|---|---|
| **R1** | Research 每个决策槽的择一 | 面板呈现该槽、等待玩家点选那一刻（逐槽，共 `ResearchSlots.Length` 个） | **无新增写**——候选已在 `activeEvent.Option.ResearchSlots` 里（物化时掷定并随批落存档） | — |
| **R2** | Research 收口 | 全部槽选完 + `lifeSpanCost` 合并 | 并入 `eventEnd` 的单一事务存档点 | 随 `eventEnd` |
| **X1** | Exchange 一笔购买 / 售出结算完毕 | 该笔 `TryApply` 提交之后、面板回到可操作态 | **与既有即时提交重合**（本地立即原子写） | `Debounced` |
| **X2** | Exchange 一次刷新结算完毕 | `TryApply(-spiritStone + 新库存 + RerolledCount+1)` 提交之后 | 同上；**同批带 `Shop` 子流的 `RngElements`** | `Debounced` |
| **X3** | Exchange 收口 | 玩家点「离开」 | 并入 `eventEnd` 的单一事务存档点 | 随 `eventEnd` |
| — | **Explore：无自有决策点** | 揭示不是决策点 | 揭示的 `EventStateChanges[ActiveEvent = revealed]` 照常本地写 | `Debounced` |
| — | Explore 揭示后**接入真身那一类的清单** | Combat 真身 → D0–D7 · Exchange 真身 → X1–X3 · Travel 真身 → 无 | — | — |
| — | **Travel：无事件内决策点** | 「去哪」发生在**批次层**（就是「择一进入」本身），不在事件内部 | — | — |
| — | Travel 收口 | `eventEnd` | 单一事务存档点 | 随 `eventEnd` |

**明确不是决策点：** Exchange 面板打开 · Explore 揭示 · Research 面板打开 · Travel 的任何一步 · **战后奖励面板打开**（打开时 `picks` 已算定并写入；**面板内的每一次领取 / 跳过则是决策点 `D6`**，见 `combat-service.md`）。五者的共同判据是**这一刻有没有新状态产生**，不是「形状对不对称」——Exchange 面板打开时库存与已扣的 `SelectCost` 已由 `TryApply(SelectCost + EventStateChanges[ActiveEvent])` 那一次覆盖，恢复即读 `activeEvent.Option.ExchangeStock`。

- **批次层的储物袋操作不是事件内决策点，它是独立的即时提交。** 战斗外道具使用与随售都发生在 EventOption 选择界面这一层——`AdvanceEventAsync` 未在运行、没有状态机在推进、没有可取消的长流程 ⇒ 它们不进本表，也不进战斗侧的 D0–D7。但即时提交的两条判据同时成立（玩家主动按下 · 不即时写就开出退出重进即回滚的窗口）⇒ **一次 `TryApply`，随之一次本地原子写**。连带三条纪律：**不触发 `RefreshAfterEvent`**（重算会消耗 `map` 子流，并开出「用一颗丹刷新这一批事件」的通道）· **照跑终态判定**（复用本服务的私有方法，`finaleFailed = false`；一件扣资源的道具能把某条资源打到 `Min`，不判定即出现「资源触底但角色仍 `ongoing`」）· **不计软阻塞闸门**（闸门只数事件级存档点）。规则权威见 `systems/character-profile/item/_index.md`，push 侧见 `systems/services/sync-service.md`。
- **X1 / X2 与既有的「事件内主动消费即时提交」逐字重合，这不是巧合。** 即时提交的两条判据（玩家主动按下 · 不即时写就开出回滚窗口）与决策点判据在 Exchange 上指向**同一批时刻**。**故 Exchange 的决策点清单不新增任何写入动作**，只是给既有实例贴上「这里也是取消点」的标签。纪律本体见 `systems/adventure-event/common-properties.md`。
- **R1 的「无新增写」等价于：Research 的槽内选择不落存档。** 决策点存档的**全部理由**是关掉「退出重进即重掷」的窗口，而 Research 候选在物化时就已掷定并落存档 ⇒ 该窗口本就不存在。代价是中途退出会丢失已做的槽内选择（恢复回面板初始态、候选一字不变），见 `systems/adventure-event/research/_index.md`。
- **密度与体积不构成新压力。** 非战斗四类合计决策点远低于战斗侧的 ≈31 个 / 单点 2–4 KB diff，既有的体积护栏与 push 频率讨论完全由战斗侧主导。

### `AdvanceEventAsync` 的取消语义

**取消只有两个真触发方：玩家自己要走，或后端把他踢下线。** 其余全部是既有定案已明确「不打断」的路径——把它们汇总到一处，使「谁会取消」这个问题的答案是**闭合的**：

| 触发方 | 是否取消 `ct` | 处置 |
|--------|--------------|------|
| **玩家主动退出到主界面 / 切角色** | **是** | 在最近决策点停下 → `Immediate` flush → `AdvanceResult(Success: false, FailedAt: Cancelled)` |
| 同上，但事件类型**零事件内决策点**（Travel · Explore 揭示出的 Travel） | **是**（但无观察位） | **取消请求不改变本次事件的结局**：流程走到收口、`pastEvent` 照常记，返 `AdvanceResult(Success: true, FailedAt: None)`；退出在收口**之后**生效 |
| **被后端明确挤下线 / 重登失败** | **是** | 同上，随后走 account-service 的硬阻塞重登流程；重登后**先 pull 后 flush**（既定） |
| 应用失焦 / 挂起 | **否** | 只做 `Immediate` flush（既定 flush 点），流程保持挂起等待回前台 |
| 进程被杀 / 崩溃 | 无 `ct` 可言 | 靠最近决策点的本地缓存恢复 |
| 网络断线 / push 失败 | **否** | 既定：不阻塞玩家，变更进待发队列 |
| 内容 overlay 热更 | **否** | 既定：轮回进行中更新即生效 |
| 缓冲超限的软阻塞 | **否** | 既定：不打断进行中的事件，模态弹在**下一次事件选择前** |
| 角色 `defeated` / 篇章通关 | **否** | 这是正常收口，不是取消 |

- **`ct` 只在决策点被观察**（推进到下一个决策点 → 持久化 → `ThrowIfCancellationRequested()` → 等玩家输入）。**推论：取消点与存档点永远重合**——「取消如何与最近决策点对齐」这个问题**因此不存在**，而不是「靠约定去对齐」；**中间态永不需要持久化**（结算走到一半被取消是不可能的）。详见 `combat-service.md`。
- **`AdvanceStage` 新增 `Cancelled`**：既定失败语义是「业务失败 = 预期内的拒绝 → 返回结果类型，绝不抛」，而**取消是预期内的**，不该以 `OperationCanceledException` 穿透到编排顶点（那会把一条正常路径伪装成异常）。**它与其余四值的区别是：不表示「这一步不合法」，而表示「这一步还没结束」**——编排顶点据此**不清理 `ActiveCombat`、不推进状态机、不记 `pastEvent`**。
- **玩家主动退出取静默退出，不做二次确认弹窗**（手感优先：退出即退出，不在最频繁的操作上加一次模态）。**已知代价**：「进度保留在当前决策点、成本不退还」这条规则玩家看不见，须由**别处**承担告知——战斗屏的常驻措辞或首次退出时的一次性提示，**不是弹窗流程**。归 `ux/combat-ux.md`。
- **取消不是即时的**：玩家点「退出」后流程要走到下一个决策点才真正停（战斗内至多是「当前这次结算做完」，毫秒级）。若某次结算带动画，**呈现层可立即切走 UI，逻辑在后台走完到决策点**。
- **未覆盖**：Godot 编辑器停止 / 强杀——无 `ct`、无 flush，靠最近决策点的本地缓存，与崩溃同路径。
- **零决策点的事件类型上，取消请求不改变本次事件的结局。** `ct` 无处被观察 ⇒ 流程直接走到收口，此时返回 `Cancelled` 会让编排顶点按「这一步还没结束」去处理一个**已经结束**的事件（`pastEvent` 已记），故返成功。它与「取消不是即时的 / 取消不产生任何回滚 / `SelectCost` 不回滚」逐条自洽，零类型改动。**推论：Travel 一经选中即不可取消**——其结算是纯内存计算，毫秒级，无实际手感影响。
- 取消不产生任何回滚，与「`SelectCost` 不回滚，视同已结算」一致。

Source: `handoffs/2026-07-27b-service-api-contracts.md` · `handoffs/2026-08-02-momentum-conversion-reward-structure-and-mtg-stack.md` · `handoffs/2026-08-06c-skip-channel-removal-priority-two-tier-and-location-codex-edges.md` · `handoffs/2026-08-06d-combat-open-questions-mass-closure.md` · `handoffs/2026-08-09b-player-power-fragment-finale-bound-drop-chance.md` · `handoffs/2026-08-10c-ability-disable-replacement-and-player-statistics.md` · `handoffs/2026-08-12d-hidden-stat-bands-and-crossing-narrative.md` · `handoffs/2026-08-16d-cost-side-closure.md` · `handoffs/2026-08-16h-grant-source-assembler-criterion.md` · `handoffs/2026-08-17-travel-destination-and-status-change-elements.md` · `handoffs/2026-08-17j-event-option-derived-persistence.md` · `handoffs/2026-08-19-profile-change-spec-gaps.md` · `handoffs/2026-08-22-finale-failure-is-death.md` · `handoffs/2026-08-22-non-combat-decision-points.md` · `handoffs/2026-08-25-info-economy-and-codex-expansion.md`

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- **境界存档 · 篇章重试模型（四境三篇章、全部继承、状态机、重试无限/3/1、篇章解锁）** → `decisions/ADR-0004-realm-checkpoint-retry-model.md`（Accepted）。
- **强制在线 · 云端权威（含重账号）** → `decisions/ADR-0003-online-cloud-authority.md`（Accepted）。
- **非战斗四类的事件内决策点清单（R1 / R2 / X1 / X2 / X3 + Explore / Travel 两条「无」）+ 决策点不触发第二次写入的口径** → `decisions/ADR-0036-decision-point-saves.md`（Accepted；该口径是它的承重落地句）。战斗侧对称的「D0–D7 决策点清单」见 `combat-service.md`。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **元进程持久化范围：** **`AccountInfo`（仅余合规字段待后端分级）· `GameSetting` · Codex 族的 `CodexEntry` 三者的字段面均已收口**，见 `systems/player-profile/account-info.md`、`game-setting.md`、`codex/common-properties.md`。仍待定：**`Achievement` 的条目 schema 与进度模型**、`PlayerPower` / `PlayerItem` **各自的解锁 / 获取 / 失去触发**，以及 **`PlayerPower` 的平衡边界**（防 pay/grind-to-win、是否影响 cycle seed / 计分公平）。→ `systems/player-profile/`、`systems/services/profile-service.md`。
- **后端 / 账号合规落地：** 已定**强制在线 · 云端权威 + 重账号**（`decisions/ADR-0003`）；仅剩实现级待决：后端 / 账号系统具体选型、合规落地（PIPL / 实名 / 防沉迷 / 渠道审核 / 注销 / 数据导出）——这些归**后端库**，见 `backend-design-documents/open-questions.md`。
- **隐藏属性细节：** 属性隐藏、`faith` = 道心、寿元按 `lifeSpanCost` 扣减 / 归 0 → defeated 均已定案；**取值域、档位表、阈值与回滞、跨档叙事形态已定案**（归 `systems/services/plot-manager.md`）。仍待定：**隐藏属性完整清单**（道心 / 煞气 / 寿元之外是否还有第四项）、**增减触发**（哪些 AdventureEvent 推拉、各推哪一档）、AdventurePlot 树的数据编码。**寿元的回复通道已定案**（存在，只走 outcome 侧；载体、展示门控与平衡护栏见 `systems/adventure-event/common-properties.md`）。
- **`experiencePoint` 的阈值曲线与产出分布。** 载体（新字段、每级一个阈值、事件发经验、失败也给）；仍待定：**各级阈值曲线**、单次事件的经验给予量、在事件池中如何分布、失败给的比胜利少多少。**它与寿元预算的花法互相约束**——事件总数少则单次给予必须更厚。→ `systems/game-progression.md`、`systems/balance.md`。

Source: `handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md` · `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md` · `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md` · `handoffs/2026-08-02-momentum-conversion-reward-structure-and-mtg-stack.md` · `handoffs/2026-08-06c-skip-channel-removal-priority-two-tier-and-location-codex-edges.md` · `handoffs/2026-08-16b-cross-library-alignment-and-bridge-ledger.md` · `handoffs/2026-08-17f-lifespan-restoration-paths.md`

## 对应
提炼至：`.claude/knowledge/systems/life-cycle-service.md`（引用层，待建）。
