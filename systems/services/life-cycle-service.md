# life-cycle-service（服务）

> 轮回生命周期服务：开始（seed）、推进、胜/负、清理、篇章继承、状态机、重试模型。**对 `character-profile` / `player-profile` 提供 API 的服务层**。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **两层持有模型（大局骨架，细节未定）。** 账号级的 **玩家信息 / PlayerProfile** 跨轮回持久，持有一组 **角色信息 / CharacterProfile**；每个 CharacterProfile 是一次轮回 / 一个角色的状态与历史，对齐 CycleState 概念。life-cycle-service 是操作这两层的服务。
  - **PlayerProfile（元进程层）：** `List<CharacterProfile>`、`GameSetting`、`List<PlayerPower>`、`List<PlayerItem>`、`List<Achievements>`、`AccountInfo` 等。`PlayerPower` / `PlayerItem` / `Achievements` 是**独立于任何单次轮回**的账号级解锁与成就。（结构权威见 `systems/player-profile/`。）
  - **CharacterProfile（单次轮回）：** `status`（**ongoing | defeated | completed**）、`chapter`（当前篇章）、`Status`（**lifeTotal（单值，无上限字段）**、currentMana / manaLimit、**`experiencePoint`**、以及**隐藏属性** 道心 / faith、煞气 / malefic qi、寿元 / lifeSpan）、`List<AdventureEvent>`、`List<CharacterItems>`、**AdventurePlot key points**（剧情进度锚点；完整剧本内容不落存档，存于云端剧本服务，见 `systems/services/plot-manager.md`）等。（结构权威见 `systems/character-profile/`。）
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
- **重试计数只有一种：篇章重试，由 `CharacterProfile.chapterRetry` 承载（已定案 · 08-06 定形态）。** **`chapterRetry` 是 `CharacterProfile` 上的一个类**，计数第一 / 第二 / 第三篇章各自的重试次数——**因为 ch2 与 ch3 有重试上限**（无限 / 3 / 1，持 premium bundle 为 无限 / 9 / 3）。
  - **它是计数器容器，不是上限持有者。** 上限值仍按 ADR-0004 的既定纪律读取（**可被账号级持有状态改写，凡读取处不得硬编码常量**）；`chapterRetry` 只答「用掉了几次」，「还剩几次」是它与上限的差。
  - **推论：篇章解锁 / 重新锁定与「剩余重试次数展示」有了确定的数据源**——「某篇章无可重试角色时重新锁定」的判定此前没有明确的读取字段。
  - **形态 = 三个具名字段、通关后保留计数（已定案 · 08-06b）。** 不用字典 / 索引数组（篇章数是固定的游戏结构，不是可扩展列表）；不清零，故计数同时是一份历史。
  - **ch1 的角色级计数恒为 0，由账号级统计计数补位（已定案 · 08-06b）。** ch1 重试 = 随机生成新角色（07-30b **不改写**），角色级 ch1 计数因此对每个新角色恒为 0；「你在炼气段重开了多少次」由 **`PlayerProfile` 上的账号级统计计数**回答。**两层口径不同**：**只有角色级参与规则**（与上限相减得「还剩几次」，是 `RetryChapter` 的闸门输入），账号级是纯读数、跨角色累加、不参与任何判定。
  - **不存在事件级或篇章级的重试次数上限**：草案中「同一事件重试 < 10 次 / 篇章重试总数 < 30 次 / 超限强制 defeat」**未采纳**，其目的（防退出重进作弊）已由决策点存档达成。
  Source: `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md` + `handoffs/2026-08-06-ch1-band-widening-cross-realm-crush-and-chapter-retry.md` + `handoffs/2026-08-06b-asymmetric-ch1-band-consented-power-loss-and-chapter-retry-shape.md`。
- **篇章重试 = 重开一局（已定案 · 08-06）。** 重试时**换一套随机流**——角色状态仍按 ADR-0004 从该篇章起始存档带回（**「篇章继承 = 全部继承」不变**），变的只是这一遍的随机。**「重开一局」说的是随机流，不是角色。** **推论：`attemptIndex` 派生层整个删除**（见下条）。Source: `handoffs/2026-08-06-ch1-band-widening-cross-realm-crush-and-chapter-retry.md`。
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
    AdvanceStage FailedAt,      // None | ModeRejected | CostRejected | InnerFlow | OutcomeRejected | Cancelled
    CostKey      MissingElement,
    CycleStatus  StatusAfter);
```

- **`CycleStartSpec.Seed` 的生成方（已定案）：`RetryChapter` 内部生成一个新 seed，与首次 `StartCycle` 走同一条生成路径。** 篇章重试 = 换一套完整的新随机流（地图、事件池、商店、奖励、战斗全部不同），故 `attemptIndex` 无事可做、整层删除。见下方「取消语义」与 `systems/common-properties.md`。

四点推演：

- **`AdvanceEventAsync` 收 `EventOption`（定稿实例）而非 `AdventureEventData`。** 它需要**物化时置位**的 `Priority` / `SelectCost` 来校验「这一步合法吗」并施加成本。**08-06c 后不再收 `AdvanceMode`**——跳过通道已移除，推进只有一种形态。传 `Resource` 就拿不到这些字段，且会诱使调用方回查模板重算，违「产出即定稿」（见 `systems/architecture.md` 总则 6）。
- **不收 `character` 参数。** 每篇章至多一个 `ongoing`（ADR-0004），当前角色是本服务状态机的持有物；把它当参数传等于允许调用方指定「对哪个角色推进」，是一处不必要的越权面。（`StartCycle` / `RetryChapter` 例外，它们要选角色。）
- **返回 `AdvanceResult` 而非 `void`。** 编排顶点需要一个可判定的返回值——**推进后的 `StatusAfter`** 尤其关键：`selectCost` 支付后可能直接判负（08-06c），编排顶点据此转入失败流程而非事件屏。**「付不起 → 拒绝，回到呈现步」这条回路已删除**，`FailedAt = CostRejected` / `MissingElement` 在事件推进路径上不再产生（是否整体删除见待决问题）。
- **`Stream(RngStream)` 暴露 `RandomNumberGenerator` 而非 `int Next()`。** Godot 的 `RandomNumberGenerator` 自带可序列化的 `Seed` / `State`，正是既定 RNG 持久化形态（`State` + `DrawCount`）的载体；各子流独立实例天然满足「互不干扰」。

### `AdvanceEventAsync` 的固定结算流程（已定案）

`eventStart` / `eventEnd` 是**本方法内部结算流程的两个阶段名**，不是 `AdventureEventData` 上的方法（见 `systems/adventure-event/common-properties.md`「结算阶段」）：

```
校验选项合法性（Priority < EffectivePriority → 拒绝）
  → TryApply(SelectCost)                     ← 无条件施加；不做「付得起」校验（08-06c）
  → 终态判定 ①（支付后立即）                 ← 判负 → 短路进失败流程，不再进入 resolver
  → 【eventStart 阶段】选 resolver、Mystery 揭示
  → resolver.ResolveAsync(option, ct)        ← Combat/Finale 转 combat-service，其余走通用结算器
  → 【eventEnd 阶段】合并 ResolveOutcome + lifeSpanCost + 隐藏属性推拉为**一次** TryApply
  → 记入 pastEvent（按 InstanceId，携带定稿实例快照）
  → CycleStateManager 终态判定 ②（结算后）→ EventBus 广播 → sync 自动存档点
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
- **推进只有一种形态（已定案 · 08-06c）。** 跳过通道整体移除，`AdvanceMode { Select, Skip }` 枚举删除、`mode = Skip` 分支删除、`pastEvent` 只剩「进入并结算」一种痕迹。**理由：每次结算后 eventOptions 整批重算，选中一个本就等价于跳过其余。**
- **终态判定有两处（已定案 · 08-06c）。** ① **紧接 `TryApply(SelectCost)` 之后**——支付本身可能耗尽寿元，此时**短路进失败流程**，事件不再结算；② 事件结算后照常判定。这是「支付 `selectCost` 是可推进行为、支付后判定状态、判负进失败流程」的直接落地，**推翻了「付不起则拒绝、不产生任何写入」**。Source: `handoffs/2026-08-06c-skip-channel-removal-priority-two-tier-and-location-codex-edges.md`。
- **`eventEnd` 阶段把 `CombatResult.Spoils`（一份 `ProfileChangeSpec`）连同 `lifeSpanCost`、**战斗失败时按道念差扣减的 lifeTotal**、等级产出与隐藏属性推拉合并为一次 `TryApply`**，从而「一个事件 = 一次事务 = 一个存档点」。**分工已定案：计算归 combat-service、施加归本服务**——奖励厚度、失败侧 lifeTotal 扣减（道念差 **1:1**）与可选奖励的玩家选择**全部在战斗流程内完成**，本服务收到的 `Spoils` 已是最终 spec，不再重算。Source: `handoffs/2026-08-02-momentum-conversion-reward-structure-and-mtg-stack.md`。
- **Finale 结算额外并入道统残卷的一组 element（已定案 · 08-09b）。** 该事件 `eventEnd` 的那一次 `TryApply` 在 Finale 上多承载一组账号级写入，**不新增结算阶段、不新增存档点**：
  - **失败**（含「失败但存活」的 1% 分支）：`PlayerPowerFragment.Accumulated` 按 `(x, chapter)` 分档表累加（钳制到 10000）；**不掷骰、不发放**。
  - **胜利**：`Spoils` 内含**授予法则** element（走既有 `ProfileManager.GrantPower(powerId)` 语义，只是这次由 Spoils 触发）+ `Accumulated` 重置 element + `FinaleWinOrdinal` 自增 element + 首胜标记置位 element。
  - **掷骰在本服务侧完成、走账号级 RNG**（`Hash64(AccountSeed, FinaleWinOrdinal)`），**不经 SeedManager 的任何子流**——子流由 `CycleSeed` 派生而篇章重试会换 `CycleSeed`，挂上去即可刷。**`FinaleWinOrdinal` 是幂等键**，与决策点存档的防重掷同一条纪律。
  - 完整规则（分档表、首胜优先、重置口径、隐含呈现）见 `systems/player-profile/player-power/_index.md`；数值归 `systems/balance.md`。
  Source: `handoffs/2026-08-09b-player-power-fragment-finale-bound-drop-chance.md`。
- **隐藏属性跨档时附一条定性叙事。** `eventEnd` 合并施加隐藏属性推拉；若某属性因此**跨过一个隐藏档位**，则在 `ResolveOutcome` 上附带一条定性描述（不给数字）随事件收口一并呈现。**复用既有链路，无新结构**；档位与文案归 `plot-manager.md`。Source: `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。

**事件面：**

| 事件 | 负载 |
|------|------|
| `CycleStarted` | `(string CharacterId, int Chapter, ulong Seed)` |
| `EventResolved` | `(string CharacterId, string InstanceId, string EventId, int LifeSpanRemaining)` |
| `ChapterCompleted` | `(string CharacterId, int Chapter, Realm ReachedRealm)` |
| `CharacterDefeated` | `(string CharacterId, DefeatReason Reason, int RetriesLeft)` |

负载**只带 `Id` + 值类型**，绝不带 `CharacterProfile` / `EventOption` 引用（传引用等于给订阅者开一条绕过唯一写入入口的旁路，也让定稿实例有被下游改写的可能）。需要完整实例的订阅者按 `InstanceId` 向 future-event-service 取。
- **数据契约：** 输入 / 输出以稳定 `Id` 引用内容与角色（经 `content-service.ContentRegistry` 解析）；持久化交 `sync-service`（原子写 + schema 版本）；RNG 由 SeedManager 从 cycle seed 派生（见 `systems/common-properties.md`）。
- **自动存档点：** 在状态机边界（轮回开始、每个事件结算后、篇章边界、轮回结束）**以及事件推进过程中的每个决策点**（含战斗内）触发 —— 每点**立即原子写本地缓存**，网络上行则经 `sync-service.Push(profile, reason, policy)` 按 **5 秒防抖**合并；**篇章边界 / 轮回结束 / `defeated` / 进入战斗前 / 应用失焦挂起**为 `Immediate`，不受防抖约束。**`Immediate` 只声明「不等防抖窗口」，失败处置与 `Debounced` 完全相同**（进待发队列 + 指数退避 + **不阻塞玩家**）——它不是「必须成功」，见 `sync-service.md`「`Immediate` flush 的失败语义」。存档点清单本身**未因频率考量而改动**（存档点与 push 已解耦）。每个存档点同时更新 `CharacterProfile.LastContentVersion`。Source: `handoffs/2026-07-27-content-gating-offline-resilience-and-rng-persistence.md`。
- **`StartCycle` 附带写入：** 生成 `Rng.CycleSeed`、派生四条子流、写 `StartContentVersion`（此后不变）。
- **战斗内随机直接用 `combat` 子流**（08-06：防 re-roll 的每场再派生层已整层删除——退出重进由决策点存档 + RNG `State` 持久化封住，篇章重试则换一套新的随机流）。见 `systems/common-properties.md`。
- **状态机（CharacterProfile.status）：** `ongoing → completed`（篇章通关）或 `ongoing → defeated`（主动弃置 / 寿元归 0 / lifeTotal 归 0）。`completed` 解锁下一篇章可挑战角色；`defeated` 清理数据并消耗重试次数。

### `AdvanceEventAsync` 的取消语义（已定案）

**取消只有两个真触发方：玩家自己要走，或后端把他踢下线。** 其余全部是既有定案已明确「不打断」的路径——把它们汇总到一处，使「谁会取消」这个问题的答案是**闭合的**：

| 触发方 | 是否取消 `ct` | 处置 |
|--------|--------------|------|
| **玩家主动退出到主界面 / 切角色** | **是** | 在最近决策点停下 → `Immediate` flush → `AdvanceResult(Success: false, FailedAt: Cancelled)` |
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
- 取消不产生任何回滚，与「`SelectCost` 不回滚，视同已结算」一致。

Source: `handoffs/2026-08-06d-combat-open-questions-mass-closure.md`。

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- **境界存档 · 篇章重试模型（四境三篇章、全部继承、状态机、重试无限/3/1、篇章解锁）** → `decisions/ADR-0004-realm-checkpoint-retry-model.md`（Accepted）。
- **强制在线 · 云端权威（含重账号）** → `decisions/ADR-0003-online-cloud-authority.md`（Accepted）。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **战斗之外的事件类型的决策点清单。** **战斗内的 D0–D6 已定案**（见 `combat-service.md`）；其余八类 AdventureEvent 的事件内决策点（每次选择后？揭示后？）尚未逐类给出——它们共享同一形状，清单应当很短。→ `systems/adventure-event/`。
- **`AdvanceResult` 的失败面还剩什么（08-06c 新增）。** 事件推进不再因「付不起」被拒绝，`FailedAt = CostRejected` 与 `MissingElement` 因此在这条路径上不再产生；是否整体删除取决于别处（Exchange 商店购买等）是否仍需「余额不足即拒」。**连带：`TryApply` 施加负值时各资源的钳制规则未定**（哪些截断到 0、哪些可为负、哪些的耗尽构成终态）。→ `profile-service.md`、`systems/adventure-event/common-properties.md`。Source: `handoffs/2026-08-06c-skip-channel-removal-priority-two-tier-and-location-codex-edges.md`。
- **账号级统计计数的容器形态与首批统计项清单（08-06b 新增 · 08-09d 收窄）。** 落成什么（`PlayerStatistics` 类？直接挂 `PlayerProfile` 的若干字段？）；除篇章重试累计与 `TotalCyclesCompleted` 外首批还统计什么（总 defeated 数 / 各 `DefeatReason` 计数）；**宽松同步口径的具体形态**（层归属已定：统计计数落宽松侧）。**已答结的部分：** 与规则字段层的边界（两层通则 + 合并判据 + `Ordinal` 命名硬约定）见 `systems/player-profile/_index.md`；**「通关」= 完成整个轮回（`TotalCyclesCompleted`，三篇章全通 · 抵达元婴 +1），统计侧不设 Finale 胜利数字段（展示直读 `FinaleWinOrdinal`）、首批不设篇章完成数**。→ `systems/player-profile/`、`systems/services/sync-service.md`。Source: `handoffs/2026-08-06b-asymmetric-ch1-band-consented-power-loss-and-chapter-retry-shape.md` + `handoffs/2026-08-09d-field-layering-merge-criterion-and-ordinal-naming.md`。
- **元进程持久化范围：** `PlayerPower` / `PlayerItem` / `Achievements` / `GameSetting` / `AccountInfo` 语义已澄清（见「意图」），但**各自字段结构与解锁 / 获取 / 失去的具体触发**仍待定；账号级 meta 或许值得单独一份系统文档。**PlayerPower 平衡边界**（防 pay/grind-to-win、是否影响 cycle seed / 计分公平）待定。
- **后端 / 账号合规落地：** 已定**强制在线 · 云端权威 + 重账号**（`decisions/ADR-0003`）；仅剩实现级待决：后端 / 账号系统具体选型、合规落地（PIPL / 实名 / 防沉迷 / 渠道审核 / 注销 / 数据导出）——这些归**后端库**，见 `backend-design-documents/open-questions.md`。Source: `handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。
- **隐藏属性细节：** 属性隐藏、`faith` = 道心、寿元按 `lifeSpanCost` 扣减 / 归 0 → defeated 均已定案；仍待定：**隐藏属性完整清单**（道心 / 煞气 / 寿元之外）、**各自的隐藏档位划分与阈值**（跨档定性反馈的触发依赖它）、增减触发、是否有非境界突破的寿元增长途径、AdventurePlot 树的数据编码（归 `systems/services/plot-manager.md`）。Source: `handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md` + `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。
- **`experiencePoint` 的阈值曲线与产出分布（08-02 改写）。** 载体已定案（新字段、每级一个阈值、事件发经验、失败也给）；仍待定：**各级阈值曲线**、单次事件的经验给予量、在事件池中如何分布、失败给的比胜利少多少。**它与寿元预算的花法互相约束**——事件总数少则单次给予必须更厚。→ `systems/game-progression.md`、`systems/balance.md`。Source: `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md` + `handoffs/2026-08-02-momentum-conversion-reward-structure-and-mtg-stack.md`。
- **重试上限可变后的存档表达（08-01b 新增）。** 上限由付费礼包改写为「无限 / 9 / 3」（见 `systems/monetization.md`），故 `RetryChapter` 的判定要读 PlayerProfile 上的持有状态。它落成什么——一个 `CapabilityFlag`、modifier pipeline 的一条具名修正，还是一个独立的 `Entitlement` 字段？→ `profile-service.md`、`systems/player-profile/`。Source: `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。

## 对应
提炼至：`.claude/knowledge/systems/life-cycle-service.md`（引用层，待建）。
