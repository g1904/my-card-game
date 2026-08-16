# profile-service（服务）

> 档案服务：**`PlayerProfile` 与 `CharacterProfile` 的唯一写入面**；capability 聚合；成就。**判据 ② —— 需要事务性地跨多个字段一致写入。**

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

### 为何是**一个**服务同时拥有两层 profile

**`PlayerProfile` 持有 `List<CharacterProfile>`**（见 `systems/player-profile/_index.md`）——两层本就是一个聚合。由**单一 profile-service** 作为两者的唯一写入面，带来：

- **事务天然闭合。** 一次结算里「扣账号级 `PlayerItem` 使用次数 + 扣轮回级灵玉 + 加卡牌」落在**同一事务**内，不需要跨服务协调原子性。
- **存档提交点唯一。** 一次变更 = 一次提交，交给 sync-service 上行，不会出现「半套写入已上行」的中间态。
- `life-cycle-service` / `combat-service` / `future-event-service` **都只经它写档**，自身不直接改 Profile 字段。

### ProfileManager：统一变更施加点

两个 Profile 的**一切变更**经一个入口，以**声明式的变更规格**驱动：

```csharp
var result = _profileManager.TryApply(spec);   // spec = ProfileChangeSpec（element 列表，BaseValue 带符号）
if (!result.Success)
{
    GD.PushWarning($"[ProfileManager-TryApply] insufficient, missing={result.MissingElement}");
    return;   // 全有或全无，不产生半成品状态
}
```

- **全有或全无。** 一次 `TryApply` 是**单点提交**：要么全部 element 一起落，要么一个都不落——不允许半套写入。**事件推进不做「先全量校验付得起、否则整体拒绝」**：`selectCost` **无条件施加**，支付后由 life-cycle-service 做终态判定。**事务性与可负担性校验是两件事**——前者是本服务的硬保证，后者不在事件推进路径上；负值施加时各资源的钳制规则待定，见待决问题。
- **它是已定 `selectCost` 复合成本类型的唯一消费点。**（它是 **`ProfileChangeSpec`**——由若干 `ChangeElement` 组成，`lifeSpanCost` 是其中一个 element；见 `systems/adventure-event/common-properties.md`。）**成本与产出用同一个类型**：`ChangeElement.BaseValue` 带符号（负 = 消耗，正 = 产出），使一次结算的扣减与收益天然落在同一事务内。
- **modifier pipeline 在此生效。** ProfileManager 读取每个 element 数值的那一刻走 `Apply(key, baseValue)`，因此 PlayerPower 的全局数值修正（`lifeSpanCost`、商店价格、掉落权重……）**不需要任何消费层写 `if (hasPowerX)`**。新增一个修正 = 新增一条数据，受影响系统零改动。
- **首批具名 element 中已确定的一组：道统残卷。** 「cost element 清单未定」这条待答由此添了具体条目——`PowerFragmentAccumulated`（累加 / 置值）、`PowerFragmentWinOrdinal`（自增）、`PowerFragmentFirstWin(chapter)`（置位）、以及**授予法则**（复用 `GrantPower` 语义，但作为 `Spoils` 的一个 element 提交；**该 element 必须携带 `Source`，残卷这一路取 `Source.FinaleWin`**——凡授予 power / item 的 element 一律强制带来源，见 `systems/common-properties.md`）。四者与 `baseReward` / `lifeTotal` 扣减 / `lifeSpanCost` 落在 Finale 的**同一次 `TryApply`** 内，符合「一个事件 = 一次事务 = 一个存档点」。**`Accumulated` 是万分比整数、施加后钳制到 `[0, 10000]`**——它是「负值施加的钳制规则」这条待答项在账号级侧的第一个已定案例。
- **`ProfileChangeSpec` = 三个平级只读列表（承重）。** `Elements`（资源）· `AbilityElements`（能力）· `Stats`（统计计数）。三者**施加语义根本不同**——资源是量（可加、要钳制、走 modifier pipeline），能力是集合成员操作（幂等增删、无量纲、**绝不走 modifier pipeline**），统计是纯计数（不钳制、失败不阻断）；压进一个带符号 `int` 是让类型说谎。类型定义见 `systems/architecture.md`「共享核心类型」。**三个列表在同一次 `TryApply` 内提交，「全有或全无、单点提交」不变。**
  - **`AbilityChangeElement` 只承载已定稿的 `Id`。** 「随机挑一条来移除」「限定只能动神通」都是**结算侧的选取规则**，在 spec 组装之前就已掷完——把随机性留在 spec 里等于让同一份 spec 重放两次得到不同结果，而 `PastEventEntry.AppliedChange` 正要求它可重放。这与「`EventOption` 产出即定稿、落存档不重算」是同一条纪律。
  - **置换 = `Remove` + `Grant` 两条 element，由 `PairKey` 配对，不是一条 `Replace`。** ① 原子性已由「全有或全无」免费提供，复合 element 等于在类型层重复实现事务；② `Grant` / `Remove` 各有独立用途（残卷授予法则是纯 `Grant`，事件负向条目是纯 `Remove`），一条 `Replace` 会让「给予半边」与独立 `Grant` 分裂成两条施加路径；③ `PairKey` 保住可读性（履历与 UI 要显示「你用 A 换了 B」，`AppliedChange` 重放时因果还原得出来）；④ **代价明写**：列表形态约束不了配对，故需一条入口校验。
  - **三类移除的表达就此闭合：** 置换型剥夺 = `Remove` + `Grant`（同 `PairKey`）· 三档禁用 = `Disable` 带 `Duration` · 不强制剥夺 = **不表达**（缺省，没有 element）· 战斗内 `IgnoresProtection` = **仍不进 spec**（只动战场条目，不写 Profile）。
  - **施加失败语义表：**

    | 情形 | 语义 | 处置 |
    |---|---|---|
    | `Remove` / `Disable` 的目标不在持有列表 | 可选缺失 | `PushWarning` + 该 element 空操作，**不使整批失败** |
    | `Grant` 的目标已持有 | 可选缺失 | 同上（候选池已排除已有，出现即内容错误） |
    | `AbilityId` 解析不到内容条目 | 必需缺失 | `PushError` + 整批拒绝（悬空 `Id` 写进 Profile 会污染存档） |
    | `PairKey` 配对不成立（非空却未恰好配成 `Remove` + `Grant`，或两者 `(Kind, Scope)` 不同） | 必需缺失 | `PushError` + 整批拒绝 |
    | `Op == Grant` 且 `(Kind, Scope, Source)` 不在合法子集表内，**或 `Source == Unknown`** | 必需缺失（代码组装缺陷） | `PushError` + 整批拒绝（与 `PairKey` 同档）。合法子集表见 `systems/common-properties.md`；它是**代码常量静态查表**，与置换同池判据共用 `(Kind, Scope)` 键。**读档侧相反——遇不合法的既有条目 `PushWarning` + 保留原值**，回落 `Unknown` 会压低残卷的 `x` 并让档位回跳 |
    | `AbilityElements` 出现在 `SelectCost` 内 | 必需缺失 | `PushError` + 整批拒绝（不变式，见 `systems/adventure-event/common-properties.md`） |
    | 未知 `StatKey` | 可选缺失（统计层宽松口径） | `PushWarning` + 跳过该条，**不影响同批其余变更** |

  - **可追溯性日志（非告警）：** 施加任一 `AbilityChangeElement` 时打一行 `[ProfileManager-TryApply] ability op=Remove kind=Power scope=Player id=xxx pair=yyy`。能力得失是玩家最在意、也最容易被投诉的一类变更，必须在日志里留痕。
  - **施加 `Disable` 时若 `activeCombat != null`**，同步调用战场侧的移除路径——**复用 `IgnoresProtection` 已有的「从战场移除一个受保护 `Power` 条目」内部路径**，不新写第二条；并在 `#if DEBUG` 下 `PushWarning`（该路径在当前链路下不可达，属纪律阶梯第 3 级的大声失败）。
  - **`PowerScope` / `ItemScope` 合并为单一 `AbilityScope`**（值域与语义完全相同；保留两个会逼 element 侧写一层无意义的转换。当前无线上存档 ⇒ 零迁移）。
- **具名 element `BundleGrantOrdinal`：置值语义，显式豁免 modifier pipeline（承重）。** 它被赋为**预先算好的** `ordinal`（不是加法），落 `ProfileChangeSpec.Elements`，与礼包的三条 `Grant` 在**同一次 `TryApply`** 内提交（全有或全无）。豁免的理由与统计层豁免同源，只是后果严重得多：**经 pipeline = 一条法则能改写付费凭证**。序号自增与「是否抽中」无关——闸 ③ 真发生时该项计未兑现、不补发，但序号照常 +1，否则下一次购买复用同一 `ordinal`、掷出完全相同的序列，幂等键当场失效。授予流程与三道闸见 `systems/monetization.md`。
- **统计计数经 `StatDelta` 写入，走宽松口径。** `PlayerStatistics` 字段全部只读，**唯一写入路径是 `Stats` 列表经 `TryApply`**，不提供 setter；它与规则字段**同批、同事务**提交。宽松之处只有两条落在本服务：**未知 `StatKey` 跳过而非整批失败**、**统计 element 绝不经过 modifier pipeline**（否则一条法则能改写统计数字）。其余三条（读档校验、上行被拒、后端）见 `sync-service.md`。
- **可加性。** 新增一种资源 element = 新增一个 element 类型 + 数据字段；不新增服务、不改调用方。这正是**不为 power / item / card / resource 各开一个 collection 服务**的替代品（见 `_index.md` 的拆分轴）。

### CapabilityManager：能力标记聚合面

capability flag 体系归本服务。

- 在启动及 PlayerProfile 变更时，遍历**拥有且 `status = 启用` 且不在 `CharacterProfile.disabledAbility` 内**的 `PlayerPower`，把它们声明授予的 **capability flag**（如 `RevealHiddenStats`、`ShowExploreType`）聚合为一份**生效能力集**，并把具名 **modifier** 聚合为修正表。**第三条与门是轮回级抑制**：被禁用的条目**不进生效能力集、不进修正表**（禁用一律截断在「进入生效面」那一步，见 `systems/character-profile/power/_index.md`）。因本服务同时拥有两层 profile，「聚合账号级法则时要读轮回级禁用表」**不跨服务、不新增依赖边**；禁用表写入后重新聚合并照常广播空负载的 `CapabilitiesChanged`——**多了一个触发源，不新增机制**。
- 变更时经 **EventBus** 广播 `CapabilitiesChanged`。
- **消费侧收敛为「一个 flag ↔ 一处消费点」：** 受影响的 UI 组件**自己订阅**并查询 `Has(flag)`，业务逻辑层完全不知道该 power 存在。散落条件的根因是把呈现决策写进了业务层；把决策点归位，条件自然只剩一处。
- **`status`（启用 / 禁用）与「拥有 / 失去」是正交两维：** 列表成员表达「拥有哪些」，`status` 表达「拥有的这些里哪些当前生效」。失去 = 移出 `List<PlayerPower>`，不是置 `status = 禁用`。详见 `systems/player-profile/player-power/common-properties.md`。

Source: `handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md` · `handoffs/2026-07-27b-service-api-contracts.md` · `handoffs/2026-08-06c-skip-channel-removal-priority-two-tier-and-location-codex-edges.md` · `handoffs/2026-08-09b-player-power-fragment-finale-bound-drop-chance.md` · `handoffs/2026-08-10b-grant-source-and-fragment-source-scoping.md` · `handoffs/2026-08-10c-ability-disable-replacement-and-player-statistics.md` · `handoffs/2026-08-15b-monetization-entitlement-purchase-shape-and-scope.md`

## 管理器

| manager | 职责 |
|---------|------|
| **ProfileManager** | 两个 Profile 的唯一写入面；`TryApply(spec)` 原子施加成本 / 产出；modifier pipeline 生效点 |
| **CapabilityManager** | capability flag 聚合 + 具名 modifier 表；`CapabilitiesChanged` 广播 |
| **AchievementManager** | 成就进度累计（组内加权）、60% / 90% 两档一次性奖励发放 |
| **GrantPoolPicker**（`internal`） | 账号级 / 轮回级能力条目的**唯一抽取处**：取池（`AllEnabled()` → `(Kind, Scope)` → 去成就限定 → 排除已持有 → 可选锚定 `Rarity`）+ 按 `RarityTier` 加权 seeded 抽取。残卷 · 礼包 · 置换三条渠道共用；见 `systems/player-profile/player-power/_index.md` |

## API 面（契约）

> 总则与共享类型见 `systems/architecture.md`「API 契约总则」。本服务**纯本地**，永不跨进程边界，故**全部方法为形态 A**、不实现 `IBootstrappable`。

| 方法 | 形态 | 完整签名 | 失败语义 |
|------|------|----------|----------|
| 载入 | A | `void Hydrate(PlayerProfile profile)` | `profile == null` = 程序缺陷 → `PushError` + 抛；触发 CapabilityManager 首次聚合 |
| 施加变更 | A | `ApplyResult TryApply(ProfileChangeSpec spec)` | **业务失败** → `ApplyResult.Fail(missingElement)`，全有或全无，绝不抛 |
| 预校验 | A | `bool CanAfford(ProfileChangeSpec spec)` | 供 UI 灰显 / 预览，**不提交** |
| 能力查询 | A | `bool Has(CapabilityFlag flag)` | 未授予 = `false`，非错误 |
| 数值修正 | A | `int ApplyModifier(ModifierKey key, int baseValue)` | 无修正 = 原值返回 |
| 开关 | A | `ApplyResult SetPowerStatus(string powerId, bool enabled)` | 未拥有该 power → `ApplyResult.Fail` |
| 授予 / 撤销 | A | `ApplyResult GrantPower(string powerId, Source source)` / `ApplyResult RevokePower(string powerId)` | 同上；**`source` 无默认值**——省略即产生来源未知的条目，而残卷的 `x` 直接读它。**`source` 须落在该条目 `(Kind, Scope)` 的合法子集内且不为 `Unknown`**，否则 `PushError` + 拒绝。见 `systems/common-properties.md` |
| 授予池 · 有无 | A | `bool HasGrantable(AbilityKind kind, AbilityScope scope)` | 池空 = `false`，非错误。**⟺ 残卷全局前置「尚未拥有的法则数 > 0」**（同一个判断，不是两个） |
| 授予池 · 计数 | A | `int GrantableCount(AbilityKind kind, AbilityScope scope)` | 供礼包购买入口判「够不够 2 件」（闸 ②） |
| 付费权益查询 | A | `bool HasPremiumBundle { get; }` | 未购买 = `false`，非错误。`=> Entitlement.BundleGrantOrdinal > 0`，**单点查询、不进任何事件负载**（同 `Has(flag)` / `PendingCount` / `UpgradeRequired` 的纪律）。消费方是 life-cycle-service 的重试上限选行，见 `systems/monetization.md` |
| 授予池 · 抽一条 | A | `bool TryPickGrantable(AbilityKind kind, AbilityScope scope, RandomNumberGenerator rng, out string pickedId)` | **可选缺失**（池空）→ `PushWarning`，由调用方决定降级方式（残卷静默停摆 / 礼包报错不补发） |
| 授予池 · 抽多条 | A | `bool TryPickGrantableMany(AbilityKind kind, AbilityScope scope, RandomNumberGenerator rng, int count, out IReadOnlyList<string> pickedIds)` | 同上，含「不足 count」的部分情形。**无放回**——保证多条互不相同 |
| 消耗账号道具 | A | `ApplyResult ConsumePlayerItem(string itemId, int count = 1)` | 次数不足 → `ApplyResult.Fail` |
| 成就采集 | A | `void ReportProgress(AchievementSignal signal)` | — |
| 只读快照 | A | `PlayerProfile Snapshot { get; }` | **只读视图**（非可变引用），供 sync / ViewModel 组装 |

- **`CostSpec` / `RewardSpec` 已合并为单一 `ProfileChangeSpec`**（`ChangeElement.BaseValue` 带符号：负 = 消耗，正 = 产出）。两个类型会诱导出「先 `TryApply(cost)` 再 `TryApply(reward)`」这种半套写入，与「全有或全无、单点提交」直接冲突。
- **`CanAfford` 与 `TryApply` 必须走同一条 modifier pipeline**，否则 UI 显示「买得起」而实际拒绝。二者共用一个内部 `Evaluate(spec)`，`TryApply` = `Evaluate` + 提交。
- **`Snapshot` 返回只读视图**（总则 3）；运行态写入一律经 `TryApply`。
- **四个授予池方法为何落在本服务：** 抽取需要**内容池**（content-service）与**已持有集合**（profile-service）两样东西。后者是本服务的自有状态，前者可经对方服务门面跨服务读取（跨服务方法调用允许，不触及对方 manager 私有字段）；反向（放 content-service）则要求它读 `PlayerProfile`，违反「服务之间不读写对方字段」。它们**纯内存查询、不跨边界，故为形态 A、不带 `Async`**。**抽取结果在 spec 组装之前定稿** —— `AbilityChangeElement` 只拿到已定稿的 `Id`，与既定的「随机在 spec 组装前掷完」一致。置换候选池复用同一 picker（只多传一个 `anchorRarity`）⇒ 全库只有一处抽取能力条目的代码。
- **`CapabilityFlag` 是 C# `enum` 而非字符串 key**：flag 的消费点必然是一段 UI 代码，新增 flag 本就要写消费代码；字符串只是把「拼错了」从编译期推迟到运行时。可加的是 `.tres` 里**谁授予哪个已定义的 flag**。

**事件面：**

| 事件 | 负载 |
|------|------|
| `CapabilitiesChanged` | **空负载**——订阅者收到后自行 `ProfileService.Instance.Has(flag)` 重查（既定的「一个 flag ↔ 一处消费点 · 单点查询」；把生效集塞进负载反而制造第二份真值） |
| `AchievementTierReached` | `(string GroupId, int TierPercent)` |

Source: `handoffs/2026-07-27b-service-api-contracts.md` · `handoffs/2026-08-12b-grant-source-per-kind-scope.md` · `handoffs/2026-08-12e-ability-grant-draw-pool.md`

## 与其他服务的关系

- **上游写入方：** `life-cycle-service`（轮回状态与隐藏属性）、`combat-service`（战斗内的 life / deck / 道具变更）、`future-event-service`（key points 推进）——**都只经 ProfileManager 写**。
- **下游：** `sync-service` 负责把变更后的聚合持久化 / 上行；本服务不做 I/O。
- **内容查找：** 一切 `Id` → 内容的解析经 `content-service.ContentRegistry`。

## 决策(-> ADR)

- **capability flag（布尔）+ modifier pipeline（数值）两条通道** → **ADR 候选**（待固化）。
- **单一 profile-service 拥有两层 profile、ProfileManager 为唯一写入面** → **ADR 候选**（待固化）。

Source: `handoffs/2026-07-25b-event-cost-fields-capability-flags-and-service-hierarchy.md` · `handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md`
- **强制在线 · 云端权威** → `decisions/ADR-0003-online-cloud-authority.md`（Accepted）。

## 待决问题

- **`Elements` 是否一律走 modifier pipeline，通则未收口（承重）。** 本文写着「ProfileManager 读取每个 element 数值的那一刻走 `Apply(key, baseValue)`」，而统计层与 `BundleGrantOrdinal` 都已明确豁免。**建议一并答定通则：序号 / 幂等键 / 权益类 element 一律不经 pipeline**（残卷的 `PowerFragmentAccumulated` / `PowerFragmentWinOrdinal` 大概率也应豁免）——否则「一条法则能改写它」这个洞会随每条新 element 复现，且每次都要单独裁一遍。
- **cost element 清单未定（资源族；能力族与统计族已闭合）。** `TryApply` 的形状取决于它：**资源族**有哪些 element（jade / mana / 道具 / 隐藏属性推拉？）、各自数据形态（固定值 / 区间 / 公式）仍未定。**能力族已闭合**（`AbilityChangeElement`，三个 Op），**统计族已闭合**（`StatDelta`）；剩下的只有 `StatKey` 随统计项增长的成员清单（见下条）。→ `systems/adventure-event/common-properties.md`。
- **`StatKey` 的完整成员清单未定（轻）。** 首批两项（`CyclesCompleted` / `CyclesDefeated`）已定；随统计项增长的命名与登记方式、以及如何在书写上与 `CostKey` 明确分开未定。→ `systems/player-profile/_index.md`。
- **负值施加的钳制规则未定（承重）。** `selectCost` 无条件施加后必须回答：**哪些资源截断到 0、哪些允许为负、哪些的耗尽构成终态**（寿元归 0 = `defeated` 已定；灵玉 / mana / 其余 element 未定）。它决定 `TryApply` 在余额不足时的行为。→ `systems/character-profile/currency.md`。
- **`CanAfford` / 「余额不足即拒」还剩哪些消费点。** 事件推进路径不需要它；Exchange 内的商店购买等主动消费点是否仍需？若全都不需要，`CanAfford` 与 `AdvanceResult.CostRejected` / `MissingElement` 可整体删除。
- **capability flag 的枚举与命名空间；叠加 / 冲突规则。** 两个 power 授予同一 flag 如何处理；多个 modifier 作用于同一 key 时的**运算顺序**（加法先于乘法？声明序？优先级字段？）未定。→ `systems/player-profile/player-power/common-properties.md`。
- **`status` 与「拥有 / 失去」两态的存档表达。** 两个正交维度如何编码进 schema 未定。
- **AchievementManager 的触发采集面。** 成就进度靠订阅 EventBus **被动采集**（解耦但易漏），还是由各服务**主动上报**（可靠但反向依赖）？
- **成就两档奖励内容。** 阈值 60% / 90%、一次性、目录 80% 可见已定；**各档发放何种奖励**待定。→ `ux/screen-flow.md`。
- **元进程字段结构。** `PlayerPower` / `PlayerItem` / `Achievement` / `GameSetting` / `AccountInfo` 各自 schema 与解锁 / 获取 / 失去的具体触发未定；`player-profile/` 子系统范围（是否为 achievement / account-info / game-setting 各建文件夹）待确认。→ `systems/player-profile/`。
- **PlayerPower 的平衡边界。** 方向已定为「轻度提升、PvE-only 可容忍」；是否影响 cycle seed / 计分公平仍待定。

Source: `handoffs/2026-08-06c-skip-channel-removal-priority-two-tier-and-location-codex-edges.md` · `handoffs/2026-08-10c-ability-disable-replacement-and-player-statistics.md` · `handoffs/2026-08-15b-monetization-entitlement-purchase-shape-and-scope.md`

## 对应
提炼至：`.claude/knowledge/systems/profile-service.md`（引用层，待建）。
