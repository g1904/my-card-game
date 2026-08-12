# 「本轮回禁用」与置换型剥夺一次收口；`PlayerStatistics` 与宽松同步口径定形

- id: 2026-08-10c-ability-disable-replacement-and-player-statistics
- date: 2026-08-10
- topic: systems/character-profile、systems/character-profile/power、systems/character-profile/item、systems/player-profile、systems/player-profile/player-power、systems/player-profile/player-item、systems/adventure-event/common-properties、systems/architecture、systems/services/profile-service、systems/services/combat-service、systems/services/life-cycle-service、systems/services/sync-service、systems/services/content-service、systems/common-properties、systems/balance、terminology
- status: distilled
- distilled-to: `systems/character-profile/_index.md`、`systems/character-profile/power/_index.md`、`systems/character-profile/item/_index.md`、`systems/player-profile/_index.md`、`systems/player-profile/player-power/_index.md`、`systems/player-profile/player-item/_index.md`、`systems/adventure-event/common-properties.md`、`systems/architecture.md`、`systems/services/profile-service.md`、`systems/services/combat-service.md`、`systems/services/life-cycle-service.md`、`systems/services/sync-service.md`、`systems/services/content-service.md`、`systems/common-properties.md`、`systems/balance.md`、`terminology.md`

## Intent（distilled）

**一句话：** 08-06b 只定了「法则不被强制剥夺」的**语义**，本次把**形态**整块补齐——禁用落 `CharacterProfile.disabledAbility`、生效判据统一为「截断在进入生效面那一步」、置换是 outcome 侧的一个决策点、`ProfileChangeSpec` 拆成资源 / 能力 / 统计三个平级列表，并顺带定名内容稀有度 `RarityTier` 与账号级统计容器 `PlayerStatistics`。

### 0 · 一条统一判据：静止式 ⇒ 禁用 = 不入场；启动式 ⇒ 禁用 = 不可启动

四类分成两组：**神通 / 法则 ≈ MTG 的静止式异能（static ability）**（存在即生效），**法宝 / 古宝 ≈ 启动式异能（activated ability）**（需玩家主动启用）。

> 这两句**只作「禁用应当在哪一层截断」的分界依据，不收窄既有的异能三分**——`PowerData.Abilities` 明写「静止式 / 启动式 / 触发式皆可」，`ItemData.Abilities`「以启动式为主」，法则的「探查」样板正是启动式。08-04b 的字段约束不动。

由此得到**统一的禁用生效判据**：**禁用一律截断在「进入生效面」的那一步，而不是「在生效面里做例外判断」**——与既定的「`status` 关闭 = 不入场，而非入场但不生效」完全同构。

| 生效面 | 被禁用时 |
|---|---|
| 战斗内 `CardType.Power` 入场 | **不入场**（战场上根本不出现该条目） |
| 战斗内的「本场可用道具」 | **不进该列表**（储物袋里仍在，本场不可选） |
| 战斗外 capability flag 聚合 | **不进生效能力集** |
| 战斗外 modifier pipeline | **不进修正表** |
| 事件触发器（relic / joker 语义的被动修正） | **不注册** |

- **推论 ①：`Power` 的入场条件由两条与门变成三条与门** —— `status == 开启` 且 `UsableScene` 含 `InCombat` 且**不在 `disabledAbility` 内**。三字段正交不可合并：`UsableScene` 是内容侧静态属性、`status` 是账号级玩家开关、`disabledAbility` 是轮回级外部抑制。
- **推论 ②（承重 · 连带修正一处既定 schema）：`combat-service.md` 的「不落存档的可重建项」必须补一项。** 现载「`Power` 的入场本身可由两个 Profile 的持有列表 + `status` + `UsableScene` 重放」**不再成立**，重放依据须补 `disabledAbility`。禁用表就在 `CharacterProfile` 上、随存档走，**重建仍是确定性的，不需要给 `activeCombat` 新增任何字段**。「本场可用道具」的派生规则同理加一条禁用过滤。
- **推论 ③：`CapabilitiesChanged` 多了一个触发源，但不新增机制。** 禁用表写入后 `CapabilityManager` 重新聚合并广播空负载的 `CapabilitiesChanged`。因 profile-service 同时拥有两层 profile，「聚合账号级法则时要读轮回级禁用表」**不跨服务、不新增依赖边**。

### 1 · 承载字段 `disabledAbility`

**落点：`CharacterProfile` 上与 `pastEvent` / `chapterRetry` / `activeCombat` 平级的新字段，不落 `Status` 内。** 判据：`Status` 装的是数值型运行状态（`lifeTotal` / `currentMana` / `experiencePoint` / 隐藏属性），禁用表是**集合型 build 状态**，与 deck、神通持有列表同层。

```csharp
IReadOnlyList<DisabledAbilityEntry> disabledAbility;   // 单数命名，沿用 pastEvent 的既有风格

public sealed record DisabledAbilityEntry(
    AbilityKind     Kind,             // Power | Item —— 两个 Id 空间不同，必须显式区分
    AbilityScope    Scope,            // Character | Player —— 决定它抑制哪一层的持有列表
    string          AbilityId,        // PowerData / ItemData 的稳定 Id
    DisableDuration Duration,         // NextEvent | ThisChapter | ThisCycle
    int             AppliedAtSeq,     // 施加时的 pastEvent 时序坐标
    int             AppliedAtChapter, // 施加时的篇章
    string          SourceInstanceId  // 施加它的事件实例，供履历展示与诊断
);

public enum AbilityKind     { Power, Item }
public enum DisableDuration { NextEvent, ThisChapter, ThisCycle }
```

- **存「施加时坐标 + 时长」，不存「到期坐标」。** 施加坐标是「重算不出来的原始事实」，到期判定是它的纯函数；篇章边界的 `Seq` 在施加当时还不知道，存到期坐标要么存不出来、要么要事后回写（回写破坏只追加的便利）。判据同 08-09c 的「重算不出来的存」。
- **三档时长的到期判定**（`life-cycle-service` 在两个时点各跑一次纯函数式剔除）：

  | 档 | 覆盖范围 | 剔除条件 | 剔除时点 |
  |---|---|---|---|
  | `NextEvent` | 施加之后玩家进入的**下一个** AdventureEvent 全程 | `currentSeq >= AppliedAtSeq + 1` | 记入 `pastEvent` 之后（`eventEnd` 收口后） |
  | `ThisChapter` | 至当前篇章结束 | `currentChapter > AppliedAtChapter` | 篇章边界 |
  | `ThisCycle` | 至轮回结束 | —— | 无需剔除，随 `CharacterProfile` 整体拆解 |

- **`NextEvent` 是「本事件禁用」在成本侧被排除后的唯一可用读法（承重）。** 施加只发生在 outcome 侧（见第 5 节），而 outcome 在 `eventEnd`——此时本次事件已结算完毕，「本事件禁用」等于空操作。因此第一档定名为 **`NextEvent`**，语义是「你下一次进入的那个事件里它失效」。**枚举成员的名字必须说实话**：叫 `ThisEvent` 会让每个读到它的人先算一遍才发现它管的是下一个事件。三档因此全部有效、无死成员（与 08-09c「不为未定形态预留枚举成员」同一条纪律）。
- **去重键 = `(Kind, Scope, AbilityId)`；重复禁用不叠加，取时长较长的一条。** 叠加会造出「禁用三次到底禁到什么时候」这种无谓语义。长短序 `NextEvent < ThisChapter < ThisCycle`。
- **禁用不影响持有，也不影响 `Charges`。** 被禁用的古宝仍在 `PlayerProfile` 里、次数分毫不动。**残卷的 `x` 不受禁用影响**——08-09b 已明写「`status` 开关与本轮回禁用不影响计数，那是生效维度不是持有维度」。
- **同 `Id` 多份的道具按 `Id` 整体禁用**，不区分实例（储物袋本就按 `Id` 堆叠显示 `×N`）。
- **禁用表条目不因失去持有而自动移除。** 生效面按「持有 ∩ 未禁用」求交，空指向条目是无害的幂等残留；主动清理反而要在两处维护一致性。

### 2 · 「战斗中立即生效」的落地形态

规则表述：**禁用一经写入即在全部生效面上立即生效，包括进行中的战斗**——已入场的 `Power` 战场条目立即移除，已在「本场可用道具」列表中的 `Item` 立即移出。

同时如实记一笔：**在当前既定链路下，「战斗进行中禁用表被改写」这条路径不可达**——禁用的唯一写入点是 `TryApply`，唯一施加时机是 `eventEnd`（战斗已收口）；战斗内的 `TryApply` 只用于道具消耗与古宝次数。

因此落地是**一条不变式加一处断言**，而非一段中途重算参战方的代码：

- `ProfileManager` 施加 `Disable` 时若 `activeCombat != null`，同步调用战场侧的移除路径——**复用 `IgnoresProtection` 已有的那条「从战场移除一个受保护 `Power` 条目」内部路径**，不新写第二条。
- 同时 `#if DEBUG` 下 `PushWarning` 报出「战斗进行中施加了禁用」及 `abilityId`——按纪律阶梯属**第 3 级（大声失败）**：它现在不该发生，将来若有内容真这么用，我们要第一时间看见。

### 3 · 对玩家可见

- **角色面板 / 元进程界面**：被禁用的神通 · 法则 · 法宝 · 古宝**照常列出**（仍被持有），呈灰态 + 徽标，文案按 `Duration` 三档给：「下一事件失效 / 本篇章失效 / 本轮回失效」。**长按查看来源事件**（由 `SourceInstanceId` 反查 `pastEvent`）——不设 hover-only 可供性。
- **事件结算面板**：施加禁用的那一刻必须明确告知（这是「玩家未必同意」的负向条目，静默施加会被读成 bug）。
- **战斗屏不呈现被禁用条目。** 它们不在场上，而战场只呈现在场的东西；且竖屏分区已是本作压力最大的一处，为「不存在的东西」再开一处角标不划算。玩家在进入战斗前的结算面板上已被告知过。

### 4 · 置换的候选池与对价

**排除已有 · 同稀有度 · 先看后决 · 拒绝无代价 · 四类通用但只同类型置换。**

- **同池判据 = `(Kind, Scope)` 全同。** 四个独立池：`PlayerPower ↔ PlayerPower`、`CharacterPower ↔ CharacterPower`、`CharacterItem ↔ CharacterItem`、`PlayerItem ↔ PlayerItem`。跨 `Scope` 置换会把账号级资产换成轮回级（隐性剥夺）或反之（白嫖账号级内容）。
- **候选抽取 = `AllEnabled()` 全池 → 过滤同 `(Kind, Scope)` → 过滤同 `Rarity` → 排除已持有 → seeded 抽一条**，走 **`reward` 子流**，不新增子流。
- **空池回退：候选为空 → 整个置换成为空操作**（不移除、不给予），`PushWarning` 带 `(Kind, Scope, Rarity, characterId)`。「拒绝置换无代价」已确立「置换不成立时玩家零损失」，空池只是它的自然分支；相比「降级到相邻稀有度」，它不引入新规则，且把问题暴露在告警里。
- **置换能移除神通。** 08-06b 三形态表里「置换型剥夺」一行已写「法则 · 神通同理」，`Scope == Character` 一侧此前只是没表态。
- **置换所得条目继承被换出条目的 `SourceCode`**（08-10b 既定），故置换对残卷的 `x` 完全中性。

**稀有度字段 `Rarity`：五档 `RarityTier { Tier1, Tier2, Tier3, Tier4, Tier5 }`，档号越高越稀有。**

- **挂载范围**：`PowerData` / `ItemData` / `CardData`——一切会被抽取或置换的内容。`AdventureEventData` 不需要。
- **类型名是 `RarityTier`，不是裸 `Tier`（硬约定）。** 战后奖励的优势档已占用 `Tier { Narrow, Solid, Crushing }`（道念差归一化的碾压程度）；裸 `Tier` 会在 `balance.md` 同一页造出两个含义。**两者不得复用同一枚举，也不得互相换算。**
- **它不是凭空引入的新概念**：`combat-service.md` 的战后奖励池已写「稀有度权重按 `Tier` 调整」，`player-item/common-properties.md` 也列了「稀有度 / 权重」——既有设计一直在依赖它，只是没定名。**奖励池的稀有度权重表应改为按 `RarityTier` 五档索引。**
- **加载时校验**：`Rarity` 缺失 → `PushError`（默认值会让漏填条目悄悄落进 `Tier1` 池并污染置换候选）。

### 5 · 禁用与置换都不出现在 `selectCost`，只出现在 outcome / reward 侧（推翻旧措辞）

`ProfileChangeSpec.AbilityElements` **在 `EventOption.SelectCost` 内恒为空**；三种能力操作（`Grant` / `Remove` / `Disable`）**只能出现在事件的 outcome / reward 侧**。四条支撑：

1. **成本侧只放可如实计价的量。** `selectCost` 的展示纪律是「让玩家能自己算出这一步可能是最后一步」，面向**可计量的资源**。能力得失不可计价——一条法则值多少寿元？——塞进成本侧会让展示从一列数字变成「数字 + 一段能力说明」。
2. **成本侧无条件施加，与「先看后决 · 拒绝无代价」正面冲突。** 置换的定义性质就是玩家可以看完再拒绝；`selectCost` 的定义性质是无条件施加。把前者塞进后者，兑现拒绝权只能靠「不选这个事件」，等于把一次独立的玩法决策折叠进事件选择。
3. **能力得失始终是事件的后果，不是入场费。** 三级严重度阶梯描述的是事件**造成**了什么；挪到成本侧会与 08-06b 推论 ③「置换是正向设计、是一个决策点」直接相悖。
4. **它换来一条可机械检查的不变式。** `SelectCost.AbilityElements` 恒空 ⇒ 物化组装后断言 + 内容模板加载期校验，两处均 `PushError`。允许它出现则这条检查不存在。

**由此定型的 outcome 侧形态**（置换与禁用共用同一条链路）：

| | 形态 |
|---|---|
| 候选何时掷定 | **结算时**（`eventEnd` 之前），走 `reward` 子流 |
| 玩家看到什么 | 结算面板上展示「失去 A · 得到 B」+ 接受 / 拒绝；禁用型只展示告知，无选择 |
| 「拒绝」是什么 | 点「拒绝」，什么都不发生（零代价） |
| 事件内决策点 | **有**，形状与战后奖励面板完全同构 |
| 落存档 | 决策点存档记录已掷定的候选；结果进 `PastEventEntry.AppliedChange` |

- **不新增机制。** 战后奖励面板已经是「预先算定的候选 + 玩家择一 + 随后并入 `eventEnd` 那一次 `TryApply`」。
- **候选必须预先算定并落决策点存档**，否则退出重进可以重掷候选。
- **`PastEventEntry.SelectCost` 的快照形状不受本次改动影响**（它只装资源 element）；`AppliedChange` 则新增能力 element 与统计 element。

### 6 · `ProfileChangeSpec` 的 element 形态：拆成三个平级只读列表

现有 `ChangeElement(CostKey Key, int BaseValue)` 是「枚举 + 带符号的量」，**表达不了按 `Id` 动一条能力**；08-09b 的「授予法则作为 `Spoils` 的一个 element」已经欠着同一笔债。

```csharp
public sealed class ProfileChangeSpec
{
    public IReadOnlyList<ChangeElement>        Elements        { get; }  // 资源：带符号的量
    public IReadOnlyList<AbilityChangeElement> AbilityElements { get; }  // 能力：按 Id 的集合成员操作
    public IReadOnlyList<StatDelta>            Stats           { get; }  // 统计计数：纯自增
}

public readonly record struct AbilityChangeElement(
    AbilityChangeOp Op,          // Grant | Remove | Disable
    AbilityKind     Kind,        // Power | Item
    AbilityScope    Scope,       // Character | Player
    string          AbilityId,   // 目标 Id（Grant 时 = 已掷定的候选）
    DisableDuration Duration,    // 仅 Op == Disable 有意义；其余置 NextEvent 且被忽略
    Source          Source,      // 仅 Op == Grant 有意义；授予通道强制带来源（08-10b）
    string          PairKey);    // 置换配对键：同一次置换的 Remove 与 Grant 共用一个非空键；非置换为空串

public enum AbilityChangeOp { Grant, Remove, Disable }
public readonly record struct StatDelta(StatKey Key, int Delta);
```

**为什么是三个列表，而不是给 `ChangeElement` 加可空字段**：三者的**施加语义根本不同**——资源是量（可加、要钳制、走 modifier pipeline），能力是集合成员操作（幂等增删、无量纲、**绝不走 modifier pipeline**），统计是纯计数（不钳制、失败不阻断）。把它们压进一个带符号 `int` 是让类型说谎；`ApplyResult.MissingElement: CostKey` 的语义也因此保持完好（它只对资源列表有意义）。**事务性不受影响**：三个列表在同一次 `TryApply` 内提交。

**置换 = 两条 element（`Remove` + `Grant`），由 `PairKey` 配对，不是一条 `Replace`。** 理由四条：

1. **原子性已由 `TryApply` 的「全有或全无」免费提供**；用复合 element 再表达一次，等于在类型层重复实现事务。
2. **`Grant` 与 `Remove` 各自还有独立用途**——残卷授予法则是纯 `Grant`，事件负向条目是纯 `Remove`。一条 `Replace` 会让「`Replace` 里的给予半边」和独立 `Grant` 变成两条施加路径。
3. **`PairKey` 保住可读性。** 履历与 UI 要显示「你用 A 换了 B」；`AppliedChange` 被重放时，配对键让因果还原得出来。
4. **代价明写**：列表形态约束不了配对，故需一条 `TryApply` 入口校验——**`PairKey` 非空时必须恰好配成 `Remove` + `Grant` 一对，且两者 `(Kind, Scope)` 相同，否则 `PushError` + 整批拒绝**。

**三类移除的表达就此闭合：**

| 语义 | 表达 |
|---|---|
| 置换型剥夺（真移除，写 Profile） | `Remove` + `Grant`，同一 `PairKey` |
| 下一事件 / 本篇章 / 本轮回禁用 | `Disable`，带 `Duration` |
| 不强制剥夺 | **不表达**——它是缺省，没有 element |
| 战斗内 `IgnoresProtection` | **仍不进 spec**（只动战场条目，不写 Profile） |

**「按 `Id` 指定 / 随机 / 按 `Scope` 限定」三选一的旧问就此消解**：element 只承载**已定稿的 `Id`**，「随机挑一条来移除」「限定只能动神通」都是**结算侧的选取规则**，在 spec 组装之前就已掷完。这与「`EventOption` 产出即定稿、落存档不重算」是同一条纪律——把随机性留在 spec 里，等于让同一份 spec 重放两次得到不同结果，而 `AppliedChange` 正要求它可重放。

**幂等与失败语义：**

| 情形 | 语义 | 处置 |
|---|---|---|
| `Remove` / `Disable` 的目标不在持有列表 | 可选缺失 | `PushWarning` + 该 element 空操作，**不使整批失败** |
| `Grant` 的目标已持有 | 可选缺失 | 同上（候选池已排除已有，出现即内容错误） |
| `AbilityId` 解析不到内容条目 | 必需缺失 | `PushError` + 整批拒绝（悬空 `Id` 写进 Profile 会污染存档） |
| `PairKey` 配对不成立 | 必需缺失 | `PushError` + 整批拒绝 |
| `AbilityElements` 出现在 `SelectCost` 内 | 必需缺失 | `PushError` + 整批拒绝（第 5 节的不变式） |

**连带的轻量改动：把 `PowerScope` 与 `ItemScope` 合并为单一 `AbilityScope`。** 两个枚举值域完全相同（`{ Character, Player }`）、语义完全相同（决定持久层），保留两个会逼 element 侧写一层无意义的转换。当前无线上存档 ⇒ 零迁移。

### 7 · `PushWarning` 的对称落点：落在内容加载侧，形态是「清单列举」而不是「比例校验」

**不在事件 outcome 侧补运行时统计告警。** 两条论证：

1. **outcome 侧的运行时统计口径样本量是 1。** 1% 是**出现频次**口径（08-06 已明写因此无法机械化校验），而单个玩家一次轮回的实际经历本就该有方差——一个玩家连撞两次不是内容错误。任何阈值都会误报。
2. **告警要落在能被看见的地方。** 内容编排的错误发生在内容侧，需在启动 / 编辑期被看见；落在玩家进程里的 `PushWarning` 等于落在没人看的地方。

因此对称落点是：**`ContentRegistry` 加载完成后，逐条列举携带 `AbilityChangeElement`（`Remove` / `Disable`）的事件条目，并报出它们在全部事件条目中的占比**，与既有的「战斗内法则 ≤ 1/5 配额」检查同形。**告警文案里必须明写：这个比例不是 1% 的口径**——1% 说的是玩家的出现频次、归内容编排与抽取权重侧；这里的比例只用来看清单本身有没有失控。

另加一条**非告警的可追溯性日志**：`TryApply` 施加任一 `AbilityChangeElement` 时打一行 `[ProfileManager-TryApply] ability op=Remove kind=Power scope=Player id=xxx pair=yyy`。能力得失是玩家最在意、也最容易被投诉的一类变更，必须在日志里留痕。

**不为置换 / 禁用设「一次轮回至多一次」的轮回级布尔位**——那是 `IgnoresProtection` 那一支为了把「平均 1%」拉成「体感 1%」而付的代价；置换与禁用没有同样的体感悬崖（分量由内容侧选档，且置换本就是正向设计）。

### 8 · `PlayerStatistics` 与首批统计项

**落成具名类 `PlayerStatistics`，挂 `PlayerProfile`。** 补一条 08-09d 没写出来的理由：**一个类型就是一道可见的边界**。08-09d 两层通则里最关键的一条是「统计计数层绝不可被规则读取」，而散挂字段在语法上无法与规则字段区分；收进 `PlayerStatistics` 后，「有人在闸门判定里读了统计」在 review 时是一眼可见的 `Statistics.` 前缀。这把该纪律从阶梯第 4 级（评审清单）抬到接近第 3 级。

```csharp
public sealed class PlayerStatistics          // 纯读数层：绝不被任何规则 / 闸门 / 幂等键读取
{
    public int TotalCyclesCompleted { get; }  // 通关（三篇章全通 · 抵达元婴）的轮回数
    public int TotalCyclesDefeated  { get; }  // 以 defeated 收场的轮回数（三种 DefeatReason 合计）
}
```

- **命名合规**：两项均为 `Total` 前缀 ⇒ 统计层；**类内禁用 `Ordinal` 后缀**（08-09d 的硬约定，可机械检查）。
- **写入时机**：轮回结束时随 `SavePointReason.CycleEnded` / 角色 `defeated` 那一次 `TryApply` 带上 `StatDelta(+1)`，与规则字段同批、同事务。
- **首批就这两项；08-06b 的「首项 = 篇章重试的账号级累计」由本次取代。** 理由：统计层新增字段的成本近乎为零（宽松同步、缺字段补默认值、零迁移、后端零配合），因此首批清单的价值在于**小而无歧义**；`chapterRetry` 在 ch1 恒为 0 是一个**展示需求**，需要时随时补。**代价明写**：`TotalCyclesDefeated` 不区分篇章也不区分 `DefeatReason`，**回答不了「你在炼气段重开了多少次」**——08-06b 用该字段化解 ch1 死字段的那条论证就此失效，不是被别的字段覆盖了。
- **不做按 `DefeatReason` 的分解**（首批）。分布是**平衡诊断**需求，正确落点是后端聚合（push 信封已带 `contentVersion` / `appVersion`），不是玩家存档里的三个计数器。
- **写入通道收窄**：`PlayerStatistics` 字段全部只读，唯一写入路径是 `StatDelta` 经 `TryApply`；不提供 setter。

### 9 · 宽松同步口径：具体宽在哪五处

| # | 面 | 规则字段层 | 统计计数层（宽松） |
|---|---|---|---|
| 1 | **施加失败** | element 缺失 → `ApplyResult.Fail`，整批不落 | **未知 `StatKey` → `PushWarning` + 跳过该条，不影响同批其余变更** |
| 2 | **modifier pipeline** | 数值 element 经 `Apply(key, baseValue)` | **绝不经过 pipeline**——否则一条法则能改写统计数字 |
| 3 | **读档校验** | 越界 → 钳制 + 告警；**不由历史重建** | 负值 / 越界 → `PushWarning` + 钳制到 0；**同样不由历史重建**，不阻塞 |
| 4 | **上行被拒（`OpError.Conflict`）** | 按既定语义以云端为准丢弃本地缓冲 | **随之一并丢弃，不做补偿重放**——统计只会偏小，且补偿机制会重新造出一份客户端权威的第二真值 |
| 5 | **后端** | 可复算校验 | **不复算、不校验，且不得用统计数据驱动任何发放**（活动奖励 / 解锁）——一旦这么用，它就变成了规则字段，必须整体升层 |

第 5 条是**防滑坡的关键纪律**：宽松口径成立的全部前提是「被篡改无玩法后果」。它须同时写进 `sync-service.md` 与 `backend-design-documents/`。

**推论：统计层新增字段的成本近乎为零** —— 宽松同步 + 老档缺字段以默认值补齐 + 不参与任何判定 ⇒ 加一项统计既不需要迁移路径也不需要后端配合。这正是「首批清单最小化」的依据。

### 存档 schema 影响

| 字段 | 层 | 迁移 |
|---|---|---|
| `CharacterProfile.disabledAbility` | 轮回级 | 老档缺字段 → 空列表 |
| `PlayerProfile.statistics` | 账号级 | 老档缺字段 → 全 0 |
| `ProfileChangeSpec` 三列表（已落存档于 `PastEventEntry.SelectCost` / `AppliedChange`） | 轮回级 | 老档单列表 → 读为 `Elements`，另两列表空 |

⇒ **bump 存档 schema 版本一次**；当前无线上存档 ⇒ **空迁移**，走既有 MigrationManager 骨架。

### 不新增什么（承重）

**不新增服务、不新增 manager、不新增 EventBus 事件、不新增存档点、不新增 RNG 子流。** 置换的决策点复用战后奖励面板的形状，禁用的生效复用 `IgnoresProtection` 的战场移除路径，可见性变更复用 `CapabilitiesChanged` 空负载。

## 备选方案（已考虑并否决）

- **禁用落 `CharacterProfile.Status` 内** — 否决：`Status` 是数值型运行状态，集合型 build 状态混入会让「隐藏属性完整清单」这类问题更难收口。
- **禁用 = 入场后立即移除** — 否决：与「`status` 关闭 = 不入场」不同构，且会让战场上短暂出现无效条目。
- **允许能力 element 出现在 `selectCost`** — 否决：见第 5 节四条。**这推翻了 08-06b 待决问题里「置换作为选择成本似乎合理」的旧措辞。**
- **保留 `ThisEvent` 档名** — 否决：施加只在 `eventEnd`，该名字管的实际是下一个事件。
- **`ChangeElement` 加可空 `TargetId` / 把 `Duration` 塞进 `BaseValue`** — 否决：`BaseValue` 的带符号约定会被枚举整数破坏，且 `MissingElement: CostKey` 对能力变更没有意义。
- **多态 element（`abstract record ChangeElement` + 子类）** — 否决：破坏 `readonly record struct` 的零分配与 diff / 序列化的简单形态。
- **置换 = 一条 `Replace(fromId, toId)` element** — 否决：原子性本就由 `TryApply` 免费提供；会逼出第四种 Op 并分裂授予路径。
- **候选池为空时降级到相邻稀有度** — 否决：引入新规则去掩盖一个应当被看见的内容缺口。
- **稀有度复用 `Tier { Narrow, Solid, Crushing }`** — 否决：优势档是道念差的归一化结果，与内容品质档无换算关系。
- **在事件 outcome 侧补运行时比例告警** — 否决：样本量 1，必然误报。
- **首批统计按 `DefeatReason` 三分** — 否决（首批）：分布是平衡诊断需求，正确落点是后端聚合。

## 与既有决策的张力（已逐条化解）

1. **「置换作为选择成本似乎合理」** ↔ 本次「禁用和置换都不出现在 `selectCost`」。**旧措辞已直接重写**（`player-power/_index.md`、`open-questions/01-combat.md`）。
2. **08-06b「统计计数首项 = 篇章重试的账号级累计」** ↔ 首批清单不含它。本次取代之；`player-profile/_index.md` 的那句已重写，并明写「ch1 重开次数暂无字段回答，需要时纯加法补」。
3. **08-06b 推论 ①「付费内容不会被游戏销毁」** ↔ 禁用（含 `ThisCycle` 档）对 `Scope == Player` 的古宝开放。**不冲突**——禁用不销毁、不扣 `Charges`、轮回结束即恢复，与法则可被本轮回禁用完全对称；不对称反而会让内容侧多背一条「哪些层能用哪些档」的例外表。但它确实是对付费内容的一次可感知削弱，因此补一条**内容侧纪律**：**禁用古宝的事件应比禁用法宝显著更稀有，且一并计入既定的 1% 分子**（评审清单级，不加代码硬规则）。
4. **`Rarity` 是本次唯一的新增内容字段**，但既有设计（奖励池稀有度权重、可购道具的预期共有字段）一直在依赖它。定名后须回改奖励池权重表的索引口径。

## Open questions

- **`StatKey` 的完整成员清单**：首批两项对应两个成员已定；随统计项增长的命名与登记方式（是否与 `CostKey` 同表书写）未定。→ `systems/services/profile-service.md`。
- **`Rarity` 的分布与权重表**：五档已定名，但各档在奖励池 / 置换池中的权重、以及内容侧「每档应有多少条目」的编排口径未定。→ `systems/balance.md`。
- **元进程界面上「被禁用条目」的具体视觉**：灰态 + 徽标 + 长按查看来源已定方向，排布与徽标形态未定。→ `ux/screen-flow.md`。
- **置换决策点的面板形态**：形状与战后奖励面板同构已定，竖屏排布与「失去 A · 得到 B」的对比呈现未定。→ `ux/screen-flow.md`。
- **一次合并收口的机会（非阻塞）**：`PlayerPower` 两条获取渠道的候选池与排重规则（残卷 / 礼包抽哪一条）**与本次的置换候选池是同一形状的问题**——`AllEnabled()` 全池 → 排除已有 → seeded 抽一条，差别只在残卷侧不限稀有度、走账号级 RNG。宜一次答定、共用同一段抽取伪码。→ `systems/monetization.md`、`systems/player-profile/player-power/_index.md`。

## Notes / triage

原始意图 `inbox/draft-0810a.md` → 提案式方案草稿 `inbox/solution-draft-ability-deprivation-and-player-statistics.md`（用户已逐条裁决，`status: decided`）→ 本 handoff。两份草稿已移入 `inbox/archive/`。

**原始意图中被用户后续裁决推翻的一条：** `draft-0810a.md` 写「置换和禁用都可以出现在 `selectCost`」，评审时裁决为**不能**（见第 5 节）。以裁决为准。
