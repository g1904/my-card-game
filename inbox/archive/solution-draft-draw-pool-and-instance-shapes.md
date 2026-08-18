---
type: solution-draft
date: 2026-08-17
question: 统一抽取原语（残卷 / 礼包 / 置换共用一段伪码）、`PoolScope` 的数据形态、以及物化后 `EnemyInstance` 的类型落位——三者都是「物化 / 抽取侧的类型与算法形态」
source: open-questions/01-combat.md → 「一次合并收口的机会（非阻塞）」·「`PoolScope` 的数据形态」；open-questions/07-codex-monetization.md → 授予渠道候选池；open-questions/02-event-options.md → 「物化后敌人实例的类型形态（08-09c）」
targets: systems/services/profile-service.md · systems/services/content-service.md · systems/player-profile/player-power/_index.md · systems/monetization.md · systems/enemies/_index.md · systems/enemies/common-properties.md · systems/services/future-event-service.md · systems/adventure-event/common-properties.md · systems/game-progression.md · systems/services/plot-manager.md
status: distilled
reviewed: 2026-08-17 —— 六项取向全部取推荐项（第 2、6 项标 [采纳推荐 — 待复核]）；合并 interview 另裁定：维持删除 LocationData.EnemyTemplateIds 并明写「地域 / arc 专属条目是叠加而非替代」、推翻第 4 项的「删」——PlotModulation.EnemyPoolScope 保留且维持六字段并新增加载期悬空校验、交叉校验第 4 条降为 EventType 单维并新增「敌人池篇章框定载体」待答、activeCombat.enemyRef = EnemyInstance.InstanceId（经 activeEvent 比对）、嵌套结论保留但依据重写 + 结算期以 activeEvent 为权威、对侧承接取「确认对齐 + 措辞消歧」
distilled-to: handoffs/2026-08-17k-draw-pool-and-instance-shapes.md
---

# 方案草稿 — 抽取原语与物化实例形态

## 问题

三条待答项被 `01-combat.md` 明确认定为「一次合并收口的机会」，它们的共同点是**都在问「物化 / 抽取侧的类型长什么样」**：

1. **统一抽取形态。** `PlayerPower` 两条获取渠道（残卷 / 礼包）的候选池与排重规则，与置换候选池是同一形状的问题——`AllEnabled()` 全池 → 排除已有 → seeded 抽一条，差别只在残卷侧不限稀有度、走账号级 RNG。清单明写「宜一次答定、共用同一段抽取伪码」。**卡住的是**：全库有五个抽取调用点，若各写一段，`AllEnabled()` / `ExclusiveSource` / 排重 / 加权四道过滤中漏掉任何一道都是「能上线、线上不可见」的洞。
2. **`PoolScope` 的数据形态。** 敌人条目的池归属（通用 / 地点专属 / 剧情线专属）是一个带两个可空字段的内嵌类型，还是一组 tag？与 location / 剧情线的内容条目如何交叉校验（悬空引用）？**卡住的是**：`EnemyData` 的加载期校验已写下「非空但指向不存在的 location / 剧情线 → `PushError`」，但没有类型就写不出这条校验。
3. **物化后敌人实例的类型形态。** `EnemyInstance` 是嵌在 `EventOption` 上还是只记引用？**卡住的是**战斗类 `pastEvent` 痕迹的定稿。

**推演过程中的首要发现（先于任何提案）：三条问题里有两条实际上已在别处答定，清单与部分主题文档没有跟上。** 本草稿因此有相当一部分工作是**指出漂移、收口到既有结论**，而不是新造设计：

| 清单条目 | 实况 |
|---|---|
| ①「两条渠道抽哪一条」 | **已答定**：`answer-logs/log-ability-grant-draw-pool.md` + `systems/player-profile/player-power/_index.md`「授予候选池 = 三条渠道共用的一段抽取（承重）」已给出完整取池链与伪码。**残留是收口与四处补齐**，见下。 |
| ③「`EnemyInstance` 嵌在 `EventOption` 上还是只记引用」 | **已答定**：`answer-logs/log-combat-solutions.md` 第 8 条 + `systems/enemies/_index.md` 的 `## 决策(-> ADR)` 明写「嵌在 `EventOption` 上随批次落存档」。但 `systems/services/future-event-service.md` 仍把它列为待决，且 `EventOption` 的 record 定义里**没有任何承载敌人的字段**。**残留是字段级形态**，见子项 3。 |
| ②「`PoolScope` 的数据形态」 | 真未定，且推演过程中发现一条此前未登记的**结构性重复**（见子项 2 的 🔴）。 |

## 约束（来自既有设计）

- **产出侧唯一取池入口 = `AllEnabled()`**；仓储上没有中性名 `All()`（`[Obsolete(error: true)]` 编译闸），全量走 `AllIncludingDisabled()`。→ `systems/services/content-service.md`、`systems/common-properties.md`。
- **`DrawPool<T>`（`readonly struct`，零堆分配）是抽取动作在语言层的唯一发起面**，`PickOne` / `PickMany` / `Filter` 只定义在它上面；`PickMany` **无放回**写进契约；`PickOne` / `PickMany` 需要**按 `RarityTier` 的加权重载**；随机源是**泛型约束的 `IRandomSource`**（`where TRng : IRandomSource`），不是裸接口参数。排期：第二阶段（内容）开工前、第一份内容 FR 之前，与 `LocalizedText` 同批。→ `systems/services/content-service.md`。
- **五个已登记的 `DrawPool<T>` 调用方**：future-event-service 物化 · 商店库存 · 奖励掷骰 · 能力授予池（残卷 / 礼包 / 置换，宿主 `GrantPoolPicker`）· 闭关构筑面板的功法候选。
- **两级 seeded RNG 互不相交**：轮回级 = Godot `RandomNumberGenerator` 的四条子流（`map` / `combat` / `shop` / `reward`，`State` 权威 + `DrawCount` 诊断）；账号级 = 契约定义的纯函数 SplitMix64，形态 `AccountRng.For(AccountStream stream, int ordinal)`，`AccountStream { PowerFragment = 0, PremiumBundle = 1 }` **成员序已冻结**，`ordinal` 保持 `int`。**结果写 `PlayerProfile` 的随机绝不可从 `CycleSeed` 派生。**→ `systems/common-properties.md`。
- **`ExclusiveSource != null` 的条目不进任何抽取池**（成就限定条目；这是「成就奖励恒不落空」的机械保证）。**排重发生在取池阶段而非掷骰之后** ⇒ 抽不出重复，`HasGrantable()` ⟺ 池非空 ⟺ 残卷全局前置。→ `systems/common-properties.md`、`systems/player-profile/player-power/_index.md`。
- **抽取结果在 spec 组装之前定稿**；`AbilityChangeElement` 只承载已定稿的 `Id`；授予通道**强制携带 `Source`，无默认值**。
- **`GrantPoolPicker` 是 `internal`，宿主 profile-service**；理由是抽取同时需要内容池（跨服务门面可读）与已持有集合（本服务自有状态），反向放置会违反「服务之间不读写对方字段」。
- **敌人取池 = 三层框定全部叠在 `AllEnabled()` 之后**：`EncounterScopes`（事件类型）+ `PoolScope`（地点 / 剧情线）+ 篇章。`EncounterScopes` 空数组 → `PushError`；`PoolScope` **允许为空 = 通用池，不报错**。→ `systems/enemies/`。
- **剧情线不可调制敌人模板**；差异化只能靠「换一个池子抽」。PlotManager 的权力面逐条投影为 `PlotModulation` 六字段，其中 `EnemyPoolScope : string` 注释即「对上 `PoolScope`」。→ `systems/services/plot-manager.md`。
- **物化产出即定稿（immutable）、必须落存档、消费侧不得回查模板重算。** `EncounterSpec` 的 `TurnLimit` / `VictoryRule` / `RewardPoolId` / `BaseReward` 全部物化时定稿，`EnemyData` 完全不携带。`EncounterSpec.Enemy : EnemyInstance` **单数、恒非空**。→ `systems/services/future-event-service.md`、`systems/services/combat-service.md`。
- **`PastEventEntry` 的快照判据 = 「重算不出来的存，重算得出来的不存」**；未选项只求**可回溯**不求**可重建**。→ `systems/adventure-event/common-properties.md`。
- **本作不存在多敌人场景 ⇒ 承载字段一律写单数，不留伸缩位。**
- 范围外（本草稿不答）：`RarityTier` 各档的权重**数值**、`GrantPoolMargin` / `K` 的取值、成就奖励条目清单、敌人 AI 决策算法、敌人是否也以功法构筑卡组、`EnemyData` 其余字段清单——全部归 ch1 数值标杆 / 内容编排专场。

---

## 建议方案

### 子项 1a — 抽取原语只有两级，不新增第三级

`[既有推演]`

「统一抽取形态」这一问的答案**不是造一个新原语，而是承认库内已有的两级分工并把它写成唯一权威**：

| 级 | 类型 | 宿主 | 泛型面 | 职责 |
|---|---|---|---|---|
| **第一级** | `DrawPool<T>`（`readonly struct`） | content-service | 任意 `T : Resource` | **抽取动作的语言层唯一入口**：`Filter` / `PickOne` / `PickMany`（无放回）/ 加权重载。它不知道「已持有」「成就限定」这些概念。 |
| **第二级** | `GrantPoolPicker`（`internal sealed`） | profile-service | 能力条目（`PowerData` / `ItemData`） | **能力授予的唯一取池处**：在第一级之上固化那四道过滤 + 排重 + 稀有度锚定，供残卷 / 礼包 / 置换三条渠道共用。 |

**两级的分界判据 = 这道过滤需不需要读 `Profile`。** 不需要的（`ContentEnabled`、`ExclusiveSource`、`Rarity`）留在第一级；需要的（排除已持有）只能在第二级。这条判据同时解释了为什么其余三个 `DrawPool<T>` 调用方（物化取池、商店库存、奖励掷骰）**不经第二级**——它们抽的不是能力条目、没有「已持有」这个概念（Exchange 库存例外，见下表脚注）。

**推论：全库抽取代码的落点恰好是两处**，其余调用方都是「构造一个 `DrawPool<T>` 然后 `PickOne`」的三五行。这正是清单「共用同一段抽取伪码」想要的东西，不需要新机制。

### 子项 1b — 唯一那段伪码（含全部参数化点）

`[既有推演]` 照抄 `systems/player-profile/player-power/_index.md` 的既定取池链，只把参数化点显式标出（`⟦…⟧` 为调用点参数）：

```
GrantPoolPicker.Pick(kind, scope, ⟦anchorRarity?⟧, ⟦rng⟧, ⟦count⟧):

  ① pool = Content.AllEnabled<TData>()                       // 产出侧唯一取池入口，不可替换
  ②      .Filter(d => d.Kind == kind && d.Scope == scope)    // 四个独立池；判据同置换
  ③      .Filter(d => d.ExclusiveSource == null)             // 去成就限定：专属条目不进任何抽取池
  ④      .Filter(d => !owned.Contains(d.Id))                 // 排重：排除已持有（读 Profile，故只能在本级）
  ⑤     [.Filter(d => d.Rarity == ⟦anchorRarity⟧)]           // 仅置换：锚定被换出条目的稀有度
  ⑥      .PickOne(⟦rng⟧, weightByRarity)                     // 加权；⑤ 生效时退化为同档等概率
     或  .PickMany(⟦rng⟧, ⟦count⟧, weightByRarity)           // 多条：无放回

  空池（②–⑤ 之后为空）→ 返回 false + PushWarning(kind, scope, anchorRarity, poolSize=0)
  日志：[GrantPool-Pick] kind=… scope=… stream=… ordinal=… poolSize=… picked=… rarity=…
```

**三条不过滤的维度原样保留**（`UsableScene` / `status` + `disabledAbility` / 无需为 `ContentEnabled` 另写规则），理由见 `player-power/_index.md`，本草稿不重述。

**排重语义（三条，答清单的「排重规则」那一问）：**

1. **排重的位置是取池阶段，不是掷骰之后** ⇒ **不存在「抽到重复怎么办」这个分支**。这不是本次的选择，而是既有全局前置「尚未拥有的法则数 > 0 才掷骰」唯一自洽的读法。
2. **一次授予内的多条走无放回**（`PickMany`）；跨授予之间靠 ④ 天然排重（第二次礼包不可能给到与第一次相同的条目）。
3. **`status` 关闭 / 本轮回禁用的条目照常算作「已持有」**（生效维度 ≠ 持有维度），故照常被 ④ 排除。

**空池行为按渠道分档（全部为既定结论的汇总，本草稿只补第 5、6 行）：**

| 渠道 | 空池处置 | 依据 |
|---|---|---|
| 残卷 | **静默停摆**，概率停在原值；`FinaleWinOrdinal` 仍 `+1`、`LastRoll` / `LastEffectiveChance` 仍写 | 玩家侧彻底隐含；不写则后端复算无输入、稳定误报 |
| 礼包 | **三道闸（加载期 / 购买入口 / 兑现）+ 不补发、不折价、不降级替代** | 付过钱，静默少发 = 客诉级 |
| 置换 | **整个置换成为空操作**（不移除、不给予）+ `PushWarning` | 「拒绝置换无代价」的自然分支 |
| Research 法宝候选 | ⟨建议：不足 3 条则按可选缺失少给几个候选槽 + `PushWarning`，不空面板⟩ | `PickMany` 的既定「不足 count → 返回 false + `PushWarning`，不静默少给」需要一个调用侧处置，此前未写 |
| Exchange 库存 | ⟨建议：少给几个商品位 + `PushWarning`，不留空商店⟩ | 同上 |

**稀有度权重接入点唯一 = ⑥ 的 `weightByRarity`**，它是一张按 `RarityTier` 五档索引的表，**住 `systems/balance.md`、不落 `DrawPool<T>`**。本草稿只定结构面：

- **授予池（残卷 + 礼包）共用一张表**（已定，且数值已给：40 / 27 / 18 / 10 / 5）——共用是为保留单一旋钮。
- **置换池不需要权重表**（锚定稀有度后同档等概率）。
- **战后奖励池另有三张表，按优势档 `Tier { Narrow, Solid, Crushing }` 选表**——`Tier` 与 `RarityTier` 是两个枚举，**不得复用、不得互相换算**；准确口径是「表按 `RarityTier` 索引，由 `Tier` 选表」。数值待定，不在本草稿范围。
- **权重按剩余池即时归一**（排除已持有之后再归一）；**任一档权重为 0 → `PushError`**（否则「池非空但抽不出来」会让 `HasGrantable()` 说谎）。

**⇒ 分表维度的结论：按「用途」分表（授予 / 战后奖励），不按「渠道」分表（打 / 买），也不按 `(Kind, Scope)` 分表。** 前者是三个不同的分布诉求，后两者会让付费直接买到更高档强度、或让四个池各多一张要维护的表。

### 子项 1c — 门面签名：现存四个 + 建议补一个

`[既有推演]` `systems/services/profile-service.md` 已有四个形态 A 方法：

```csharp
bool HasGrantable   (AbilityKind kind, AbilityScope scope);                       // ⟺ 残卷全局前置
int  GrantableCount (AbilityKind kind, AbilityScope scope);                       // ⟺ 礼包闸 ②
bool TryPickGrantable    <TRng>(AbilityKind kind, AbilityScope scope, TRng rng,
                                out string pickedId)                    where TRng : IRandomSource;
bool TryPickGrantableMany<TRng>(AbilityKind kind, AbilityScope scope, TRng rng, int count,
                                out IReadOnlyList<string> pickedIds)    where TRng : IRandomSource;
```

**一处缺口（建议补齐）：置换需要传 `anchorRarity`，而门面上没有这个入口。** `player-power/_index.md` 写着「置换候选池复用同一 picker，只多传一个 `anchorRarity`」，但 API 表里四个方法都没有该形参。建议**新增一个具名方法而不是加可空形参**：

```csharp
bool TryPickReplacement<TRng>(AbilityKind kind, AbilityScope scope, RarityTier anchorRarity,
                              TRng rng, out string pickedId) where TRng : IRandomSource;
```

- **取具名方法而非 `RarityTier? anchorRarity = null` 重载**：与本库「删掉中性诱饵名 `All()`」同一条纪律——一个可空形参的默认值会让「忘了锚定稀有度」成为最短路径，而**忘了锚定的置换会把 Tier1 换成 Tier5**，且能上线、线上不可见。名字里带 `Replacement` 则调用者必须显式选择语义。
- 它内部仍是同一个 `GrantPoolPicker`（⑤ 生效、⑥ 退化为等概率）⇒ **全库仍只有一处抽取能力条目的代码**，既定纪律不被破坏。

### 子项 1d — RNG 分配与 `ordinal` 的「先算后写」

`[既有推演]` 各调用点的随机源已分别定案，此处汇总成一张表并**补一条统一纪律**：

| 调用点 | 随机源 | 具名域 / 子流 | `ordinal` / `State` |
|---|---|---|---|
| 残卷掷骰 + 掷中后的抽取 | `AccountRandom`（SplitMix64） | `AccountStream.PowerFragment` | `FinaleWinOrdinal` |
| 礼包一次授予 3 条 | `AccountRandom` | `AccountStream.PremiumBundle` | `BundleGrantOrdinal` |
| 置换候选 | `GodotRandomSource` | `RngStream.Reward` 子流 | 子流 `State` 持久化 |
| Research 法宝 / 功法候选 | `GodotRandomSource` | `RngStream.Reward` 子流 | 同上 |
| Exchange 库存 / 刷新 | `GodotRandomSource` | `RngStream.Shop` 子流 | 同上 |
| 敌人物化（选池 / 赋级 / 卡组改写 / Travel 目的地） | `GodotRandomSource` | `RngStream.Map` 子流 | 同上 |

**统一纪律（本草稿新提，答清单的「`ordinal` 先算后写」那一问）：**

> **账号级授予一律用「本次的序号」掷骰 —— 即先算 `ordinal = 旧值 + 1`，用它掷骰，再把同一个值随同一次 `TryApply` 写回。绝不用自增前的旧值掷骰。**

- 礼包侧已明写这条（`ordinal = Entitlement.BundleGrantOrdinal + 1` 在伪码第一行），**残卷侧只写了 `AccountRng.For(AccountStream.PowerFragment, FinaleWinOrdinal)`，未说明这里的 `FinaleWinOrdinal` 是自增前还是自增后。**
- **这不是文风问题，是一条会稳定误报的缺口**：后端拿到上行 profile 后用**存档里的** `FinaleWinOrdinal`（必然是自增后的值）复算 `roll'` 并要求与 `LastRoll` 相等。若客户端用自增前的值掷骰，两侧永远对不上——而这条校验的既定用途正是「抓种子篡改 / 序号刷 / 换设备重掷」，它在**每一个正常账号上**都会触发。
- **序号自增与「是否抽中 / 是否发放」无关**（既定）：静默停摆时照常 `+1`，否则下一次复用同一 `ordinal`、掷出完全相同的序列，幂等键当场失效。
- 建议落笔处：`systems/common-properties.md`「Seeded RNG 派生」的账号级小节加一条通则，两个渠道文档各留一句回链（不复述）。

### 子项 1e — 调用点参数化差异表（答「三个（或更多）调用点各自的参数化差异」）

| # | 调用点 | 经第二级? | `(Kind, Scope)` | `count` | 锚定 `Rarity` | 加权表 | rng | 空池 | 授予 `Source` |
|---|---|:--:|---|:--:|:--:|---|---|---|---|
| 1 | 残卷（掷中后） | ✅ | `(Power, Player)` | 1 | ✗ | 授予池表 | `AccountRandom`(PowerFragment, `FinaleWinOrdinal`) | 静默停摆 | `FinaleWin` |
| 2 | 礼包 ① | ✅ | `(Power, Player)` | 1 | ✗ | 授予池表（同 #1） | `AccountRandom`(PremiumBundle, `BundleGrantOrdinal`)，**与 #3 共用同一 rng 实例连抽** | 三道闸 · 不补发 | `PremiumBundle` |
| 3 | 礼包 ② | ✅ | `(Item, Player)` | 2（无放回） | ✗ | 授予池表 | 同 #2 | 同上 | `PremiumBundle` |
| 4 | 置换（四类通用） | ✅ | 与被换出条目全同 | 1 | ✅ 被换出条目的档 | 无（同档等概率） | `GodotRandomSource`(Reward) | 空操作 + `PushWarning` | **继承被换出条目的 `SourceCode`** |
| 5 | Research 法宝候选 | ✅ | `(Item, Character)` | 3（无放回） | ✗ | 授予池表 | `GodotRandomSource`(Reward) | ⟨少给 + 警告⟩ | `EventOutcome`（结算时） |
| 6 | Research 功法候选 | ✗ 直用第一级 | — | `CandidateCount` | ✗ | ⟨功法侧权重：待内容侧⟩ | `GodotRandomSource`(Reward) | ⟨少给 + 警告⟩ | — |
| 7 | Exchange 库存 | ✗ 直用第一级※ | 按 `Kind` 映射仓储 | `SlotCount` | `RarityFilter` 过滤 | `RarityTier` 权重 | `GodotRandomSource`(Shop) | ⟨少给 + 警告⟩ | `ExchangePurchase`（购买时） |
| 8 | 战后奖励掷骰 | ✗ 直用第一级 | — | 3（既定候选固定 3 项） | ✗ | **战后奖励三表，按 `Tier` 选表** | `GodotRandomSource`(Reward) | ⟨待战后奖励专场⟩ | `CombatReward` |
| 9 | 敌人物化选模板 | ✗ 直用第一级 | — | 1 | ✗ | 框定后加权（内容侧） | `GodotRandomSource`(Map) | **`PushError` + 抛**（内容池为空 = 坏数据，既定） | — |

※ **Exchange 的能力族商品同样要排除已持有**（既定取池链明写「排除已持有（能力族）」），故它**部分**需要第二级的 ④。**这是本表唯一一处「分界判据」被撕开的地方**，两种收法：把 Exchange 的能力族商品也走 `TryPickGrantableMany`（则第 7 行分裂为「能力族经第二级 / 其余三族直用第一级」），或给 `GrantPoolPicker` 加一个「按 `RarityFilter` 取多条」的入口。**建议前者**——它不新增入口，且让「排除已持有」这道过滤仍然只写在一个地方。（列入待决第 6 项。）

---

### 子项 2 — `PoolScope` 的数据形态

#### 2a. 三个候选形态

| | 形态 | 写法 | 表达力 |
|---|---|---|---|
| **A** | **具名可空字段的内嵌 `Resource`** | `PoolScope { string? LocationId; string? PlotArcId; }` | 恰好两个维度；「某地点 + 某剧情线双重专属」可表达（两字段同时非空） |
| B | **一组 tag** | `string[] ScopeTags` | 任意维度可加；但**丢掉类型信息** ⇒ 悬空校验无从下手（不知道该拿这个字符串去 location 仓储还是 arc 仓储查） |
| C | **单一 scope key 字符串** | `string ScopeKey` | 最省；但「地点专属」与「剧情线专属」在数据上不可区分，且与 `LocationData` / `PlotArcData` 的 `Id` 是否同一命名空间说不清 |

#### 2b. 建议取 A，并把字段定名为 `PlotArcId`

`[既有推演]` 三条依据：

1. **维度数是封闭的，且由既有权力面封闭。** 敌人池的差异化来源只有两个：location（`LocationData` 的硬框定）与剧情线（`PlotModulation` 的唯一敌人字段）。**`PlotManager` 的权力面已被 `PlotModulation` 六字段逐条封死、写不出第三个敌人维度**；location 侧同理。**在维度封闭时 tag 的唯一优势（可加性）不存在**，而它的代价（丢类型 ⇒ 校验写不出来）是实打实的。
2. **悬空校验是硬要求，且它要求类型已知。** `enemies/common-properties.md` 已写下「非空但指向不存在的 location / 剧情线 → `PushError`」。**A 让这条校验成为两行代码**（各去对应仓储 `TryGet`）；B / C 下它要么写不出来，要么要引入一张「tag 前缀 → 该去哪个仓储查」的约定表——那张表不可机械校验，正是本库反复否决的形态。
3. **同族先例一致。** `LocationData.EnemyTemplateIds` / `PlotArcData.PlotTriggerId` / `PlotEdge.ToNodeId` 全是**具名的 `Id` 字段 + 加载期悬空校验**；没有一处用 tag 表达跨类型引用。
4. **命名修正（承重）：本库没有 `PlotLine` 这个类型。** 清单与两处文档写的是「剧情线 / `PlotLineId`」，而剧本内容的实际载体是 **`PlotArcData`**（`Id` 形如 `plot.arc.story.ashen_lineage`），「剧情线」在词表上对应的是一条 arc。**若字段定名 `PlotLineId`，它将是全库唯一一个指向不存在类型的 `Id` 字段名**——建议定名 **`PlotArcId`**，注释写明「对上 `PlotArcData.Id`」。

**具体形态：**

```csharp
[GlobalClass]                                    // 内嵌类型必须是 Resource 派生：[Export] 只接受
public partial class PoolScope : Resource        // Variant 兼容类型与 Resource（同 EventTypeModifierData）
{
    [Export] public string LocationId { get; set; }   // 空串 = 不限地点；非空 → 须存在于 LocationData 仓储
    [Export] public string PlotArcId  { get; set; }   // 空串 = 不限剧情线；非空 → 须存在于 PlotArcData 仓储
}
```

- **`EnemyData.PoolScope` 本身允许为 `null`**（= 通用池，既定「为空不报错」）；**两字段皆为空串的非 null 实例语义等同通用池**，加载期不报错但**给一条 `PushWarning`**（它是「填了个空壳」的信号，与本库「省略与还没想不可区分」同一种偏好）。
- **匹配语义 = 逐维度的与门，空维度恒真：**

  ```
  Matches(currentLocationId, activeArcIds):
      (LocationId 为空 || LocationId == currentLocationId)
   && (PlotArcId  为空 || activeArcIds.Contains(PlotArcId))
  ```

  - **剧情线一侧传的是集合而非单值**——`MaxConcurrentSideArcs` 允许同时有多条 `Active` arc（Story / Chapter 各恒有一条 + 上限 2 条 side），故「当前剧情线」本来就不是一个单值。**这一点必须写出来，否则实现会取「主线那一条」并让 side arc 的专属敌人永不出现。**
  - **两字段同时非空 = 双重专属**（只在那条 arc 活跃且身处那个地域时才进池）。它是内容侧最强的收窄手段，不需要额外规则允许它。
- **`PlotModulation.EnemyPoolScope : string` 的语义随之确定为「一个 `PlotArcData.Id`」**，且**通常就是该 arc 自己的 `Id`**。⇒ 建议**把该字段删掉、改为隐式取当前 arc 的 `Id`**：它当前允许一条 arc 去框定**另一条 arc** 的专属池，这既无用例，又打破「剧情线的差异化 = 它自己的专属条目」这条既定判据。（列入待决第 4 项——它改 `PlotModulation` 的字段数，属结构面。）

#### 2c. 交叉校验（加载期，落在合并后强校验，全部带定位上下文）

| 违规 | 语义 | 处置 |
|---|---|---|
| `PoolScope.LocationId` 非空且不在 `LocationData` 仓储内 | 悬空引用 | `PushError` + 敌人 `Id` + 悬空 `LocationId` + 抛 |
| `PoolScope.PlotArcId` 非空且不在 `PlotArcData` 仓储内 | 同上 | `PushError` + 敌人 `Id` + 悬空 `PlotArcId` + 抛 |
| 某 `LocationData.EnemyTemplateIds` 引用了不存在的 `EnemyData.Id` | 悬空引用（反向） | `PushError`（应已被通用悬空校验覆盖，此处只是点名它属同一族） |
| **通用池（`PoolScope == null` 或两字段皆空）在某个 `(EventType, 篇章)` 组合下为空** | **能上线、线上不可见的死锁**：物化时取不出敌人 ⇒ 既定「内容池为空 = 坏数据 → `PushError` + 抛」会在玩家进程里炸 | `PushError` + 报出该组合，**启动期早失败** |
| 某 arc / location 的专属池非空但其中条目的 `EncounterScopes` 与该 arc 可达的事件类型无交集 | 写了永不出现的内容 | `PushWarning` + 列举（人工审阅级，不硬校验） |

**第 4 行是本草稿新提的一条，且是三层框定叠加带来的必然要求**：`AllEnabled()` → `EncounterScopes` → `PoolScope` → 篇章四道过滤叠完后可能为空，而这条路径**只有在启动期全组合枚举才能发现**。它与「`overlay` 双闸」「`Rarity` 缺失 → `PushError`」同族——都是把「线上才显形的洞」提到启动期。

#### 2d. 🔴 推演中发现的结构性重复（必须由用户裁决）

**`PoolScope.LocationId` 与 `LocationData.EnemyTemplateIds` 表达的是同一条关系（location ↔ 敌人池），本库现在两侧各存一份，且没有任何机制发现它们不一致。**

- `LocationData.EnemyTemplateIds : string[]` —— 「硬框定：该地域的 `EnemyData` 取池」，且已写进 `terminology.md` 的 location 词条（「携带三组字段……一组特定的 `EnemyData`（硬框定取池）」）。
- `EnemyData.PoolScope` —— 「池归属：通用 / 某地点专属 / 某剧情线专属」，取池伪码写作 `.Where(e => e.PoolScope.Matches(currentLocationId, activePlotLineId))`。
- **两侧同时存在时，「竹海」的敌人清单要在 `location.bamboo_sea.tres` 里写一遍，又要在每条竹海专属敌人的 `PoolScope.LocationId` 里写一遍。** 两份表会各自漂移（改一处忘另一处 ⇒ 敌人静默不出现，或出现在不该出现的地域），**而本库没有任何机制能发现它们不一致**——这正是本库反复点名的「第二权威」形态。

三个收法（详见 `## 仍需用户决定` 第 1 项），此处只给推荐：**保留 `PoolScope` 为唯一权威，`LocationData.EnemyTemplateIds` 删除。** 依据：① 归属判据是「这条信息是谁的属性」——`PoolScope` 与 `EncounterScopes` 同属「这条敌人能出现在哪」，两个作用域字段同侧才使三层框定是一段统一的 `Where` 链；② 加一条通用敌人到某地域，在 `PoolScope` 一侧是**零改动**（通用池自动覆盖全部地域），在 `EnemyTemplateIds` 一侧是**改 N 份 location 条目**；③ 敌人条目本就是本作最重的内容单元，作用域跟着它走，编写时一处填完。**代价：**「这个地域会遇到什么」不再能在一份 location 条目里一眼读全，需要反查——但那本就是 `LocationCodex` 词条（运行时统计）该干的事，不是内容编写面。

---

### 子项 3 — `EnemyInstance` 的类型落位

#### 3a. 大方向已答定，问题实为字段级形态 + 文档漂移

`[既有推演]` 「嵌在 `EventOption` 上还是只记引用」这一问**已答**：嵌在 `EventOption` 上随批次落存档（`answer-logs/log-combat-solutions.md` 第 8 条；`systems/enemies/_index.md` 的 `## 决策(-> ADR)` 与三条依据：唯一物化点 · 选择界面就要显示敌人等级 · 等级是物化产物）。`EnemyInstance` 的 record 定义也已完整（`InstanceId` / `EnemyId` / `Level` / `DeckCardIds` / `ItemIds` / `PowerIds`）。

**真正未定的是三件事：**

1. `EventOption` 的 record 上**目前没有任何承载敌人的字段**（十一字段里一个都不是），而 `EncounterSpec.Enemy : EnemyInstance` 恒非空、`EncounterSpec` 的其余五个字段也全部「物化时定稿」。**所以问题的准确形态是：战斗类 `EventOption` 如何承载整份 `EncounterSpec`。**
2. `PastEventEntry` 的敌人痕迹字段（最小面已定：至少 `EnemyTemplateId` + `Level`）。
3. `future-event-service.md` 与 `02-event-options.md` 仍把它列为待决 —— 需要与 `enemies/_index.md` 对齐。

#### 3b. 建议：`EventOption` 上一个可空 `EncounterSpec`，`EnemyInstance` 嵌在其内

`[既有推演]`

```csharp
public sealed record EventOption(
    …既有十一字段…,
    EncounterSpec Encounter        // 战斗类（Practice / Standard / Finale）非空；其余类型为 null
                                   // EnemyInstance 嵌在其内，全库只有这一份定稿副本
);
```

四条依据：

1. **它是「嵌在 `EventOption` 上」的最省形态。** `EncounterSpec` 的六个物化产物（`Tier` / `Enemy` / `TurnLimit` / `VictoryRule` / `FirstSide` / `RewardPoolId` / `BaseReward`）**无论如何都得落在定稿实例上**——消费侧不得回查模板重算。嵌一个可空引用 = **1 个字段**；平铺 = **7 个字段**且其中 6 个对四类非战斗事件恒为默认值。
2. **它让「敌人实例只有一份」成为结构事实。** 若 `EventOption` 平铺 `EnemyInstance Enemy` 而 `EncounterSpec` 也持 `Enemy`，则同一份敌人在存档里有两个落点、两条读取路径，且**没有任何机制保证它们相等**——与子项 2d 的第二权威同形。
3. **`RunCombatAsync(EncounterSpec, ct)` 的签名不动。** life-cycle-service 在进入战斗时直接把 `option.Encounter` 递进去，**不组装、不派生、不重算** ⇒ 不产生第二个物化点（既定封死项）。
4. **形态与 `ResearchSlots` / `ExchangeStock` 同族**：都是「按事件类型只对一类有意义的物化载荷」。差别只是那两个是列表、这个是单个可空引用——**因为「本作不存在多敌人场景 ⇒ 一律单数」**。

**`EncounterSpec.EncounterId` 与 `EventOption.InstanceId` 同值的冗余是有意保留的**：`combat-service` 只见 `EncounterSpec`、不见 `EventOption`，删掉它会让战斗侧日志与 `ActiveCombat` 存档失去溯源键。它是 `LifeSpanAfter` 那类**写明的例外**（可推出但仍存），不是先例。

**加载期 / 物化后校验（两条，可机械检查）：**

- `EventType ∈ { Practice, Combat, Finale }` 且 `Encounter == null` → **必需缺失** → `PushError` + `InstanceId` + 抛。
- `EventType ∉ 三档` 且 `Encounter != null` → 同档 `PushError`。**Explore 是唯一需要想一下的情形**：`EventType` 恒为 `Explore` 而真身在 `RevealedEventId`。**建议：真身为战斗类的 Explore 壳，其 `Encounter` 在物化时即填好**（与 `DestinationLocationId` 对 Travel 真身的既定处置完全同构，依据同为防重掷纪律——敌人若等到揭示那一刻才掷，玩家退出重进即可刷一个更弱的对手）。⇒ 校验的准确写法是按**真身类型**判，不按 `EventType` 判，与「resolver 按真身的 `eventType` 选取」是同一条纪律的第三处应用。

#### 3c. `PastEventEntry` 的敌人痕迹 = 轻摘要，不是整份实例

`[既有推演]` 依既定判据（「重算不出来的存，重算得出来的不存」+ 未选项「只求可回溯，不求可重建」）：

```csharp
public sealed record EnemyTraceRef(     // 战斗类痕迹的敌人摘要；非战斗类为 null
    string EnemyId,                     // 溯源模板 → EnemyCodex 词条 / 履历显示名（disabled 条目照常解析）
    int    Level);                      // 物化赋级产物，重算不出来 ⇒ 必存
```

- **正好覆盖既定的「不阻塞 `pastEvent` 的最小面」**（`EnemyTemplateId` + 物化赋级 `Level`），不多不少。字段名建议用 `EnemyId` 与 `EnemyInstance.EnemyId` 一致——`EnemyTemplateId` 是清单里的措辞，库内 record 用的是 `EnemyId`，**两个名字指同一个东西，宜统一为后者**。
- **不存 `DeckCardIds` / `ItemIds` / `PowerIds`**：三条依据——① 事件已结算，这三项**永不会再被任何流程消费**（与未选项同款论证）；② 它们是本作最胖的物化产物（一份卡组 15 个 `Id` × 每条痕迹），而 `pastEvent` 已有既定的体积护栏与增量 push 顾虑（`enemies/_index.md` 自己把「放大定稿快照体积」记为已知代价）；③ 履历 / 剧本 / 图鉴三个消费方要的都只是「打了谁、几级」。
- **消费方点名**：`EnemyCodex`（遭遇即记）· 角色履历（这一步打了谁）· 诊断（越阶分布）。**如实记下代价**：日后若要做「战斗回放」，缺卡组序列就重放不出来——但回放不在中期路线图内，且真要做时正确做法是给回放单独存一份，不是让每条痕迹都胖 15 个 `Id`。

---

## 具体形态（可 derive 的落地面）

**新增 / 修改的类型面（汇总，供 `/derive-requirements` 消费）：**

| 类型 | 动作 | 内容 |
|---|---|---|
| `IProfileService`（门面） | **加一个方法** | `bool TryPickReplacement<TRng>(AbilityKind, AbilityScope, RarityTier anchorRarity, TRng rng, out string pickedId) where TRng : IRandomSource` |
| `PoolScope` | **新建**（`[GlobalClass] : Resource`） | `string LocationId` · `string PlotArcId` + `Matches(currentLocationId, IReadOnlyCollection<string> activeArcIds)` |
| `EnemyData.PoolScope` | 类型确定 | `PoolScope`（允许 `null` = 通用池） |
| `EventOption` | **加一个字段** | `EncounterSpec Encounter`（战斗类 / 战斗真身的 Explore 非空，其余 `null`） |
| `PastEventEntry` | **加一个字段** | `EnemyTraceRef Enemy`（非战斗类 `null`） |
| `EnemyTraceRef` | **新建**（`sealed record`） | `string EnemyId` · `int Level` |
| `PlotModulation.EnemyPoolScope` | **建议删除** | 改为隐式取当前 arc 的 `Id`（待决第 4 项） |
| `LocationData.EnemyTemplateIds` | **建议删除** | 权威收归 `PoolScope`（待决第 1 项） |

**校验清单（全部落在 content-service 的合并后强校验 / 物化组装断言，均带定位上下文）：**

| # | 检查 | 处置 |
|---|---|---|
| 1 | `PoolScope.LocationId` / `PlotArcId` 非空且悬空 | `PushError` + 抛 |
| 2 | `PoolScope` 非 null 但两字段皆空 | `PushWarning`（空壳信号） |
| 3 | 通用敌人池在某 `(EventType, 篇章)` 组合下为空 | `PushError` + 抛（启动期早失败） |
| 4 | 战斗类 `EventOption`（按**真身**判）`Encounter == null` / 非战斗类 `Encounter != null` | `PushError` + `InstanceId` + 抛 |
| 5 | 授予池任一 `RarityTier` 档权重为 0 | `PushError`（已定，此处只是点名它属同族） |
| 6 | 某 arc / location 专属池与其可达 `EncounterScopes` 无交集 | `PushWarning` + 列举（人工审阅级） |

**存档 schema 影响：** `EventOption` 加 `Encounter`、`PastEventEntry` 加 `Enemy` ⇒ **bump 一次 schema 版本**；当前无线上存档 ⇒ **空迁移**，走既有 MigrationManager 骨架。`PoolScope` 是内容定义属性、**不落存档、不 bump**。建议与「`EventOption` 完整物化字段清单」（S2）、「派生实例承载形态」（S3）**合并进同一次 bump**——三者都动 `EventOption`，分三次 bump 是纯粹的浪费。

## 后果

- **`systems/services/profile-service.md`**：API 表加一行（`TryPickReplacement`）；`GrantPoolPicker` 职责行补「置换经具名方法而非可空形参」一句。
- **`systems/player-profile/player-power/_index.md`**：取池伪码原样保留，补「⑤ 的入口是具名方法」与「`ordinal` 先算后写」两句回链；「`Rarity` 的分布与权重表」待决项收窄为「战后奖励三表 + 内容侧每档条目数」（授予表已定这一半已写明，无需改）。
- **`systems/common-properties.md`**：账号级 RNG 小节加一条「本次序号」通则。
- **`systems/enemies/_index.md` + `common-properties.md`**：`PoolScope` 字段表填入类型与匹配语义；`PoolScope` 待决项移出；若采纳 2d 推荐，还要写明「location 侧不再持敌人清单」。**另有两处需顺带修正（见「越界发现」）。**
- **`systems/services/future-event-service.md`**：`EventOption` record 加 `Encounter`；「物化后敌人实例的类型形态未定」待决项移出（它与 `enemies/_index.md` 的既有决策本就矛盾）；敌人物化五旋钮管线的产出行补一句「随 `EncounterSpec` 嵌在 `EventOption` 上」。
- **`systems/adventure-event/common-properties.md`**：`PastEventEntry` 加 `Enemy` 字段并把注释里「随……敌人实例类型形态答定后扩充」那一句消掉。
- **`systems/game-progression.md` + `terminology.md`**：若采纳 2d 推荐，`LocationData` 的三组字段变两组，`terminology.md` 的 location 词条同改。**这是本草稿影响面最大的一处，也是最需要用户点头的一处。**
- **`systems/services/plot-manager.md`**：若采纳 2b 末的建议，`PlotModulation` 六字段变五字段，权力面对照表同改。
- **`systems/balance.md`**：不新增数值，只在权重表小节点明「分表维度 = 按用途，不按渠道 / 不按 `(Kind, Scope)`」这条结构结论。
- **`content/enemy/` 尚未开张**（`content/_index.md` 登记为 🟠 依赖卡牌）⇒ `PoolScope` 的字段核对清单可在 `/scaffold-content-type enemy` 时一次写对，**此刻是纯加法窗口**，与 `DrawPool<T>` / `LocalizedText` 的排期理由完全同构。

## 备选方案（已考虑并否决）

- **为「统一抽取」新建第三个原语（如 `IDrawStrategy` / 一个带策略参数的通用 `Draw(spec)`）** — 否决：库内已有的两级分工恰好对上「要不要读 `Profile`」这条判据；第三级只会让「抽取代码只有一处」这条纪律多一个绕行入口，且策略参数化的形态无法用编译器约束（一个填错的 spec 与一个正确的 spec 类型相同）。
- **`PoolScope` 用 tag 集合** — 否决：见 2a / 2b，丢类型 ⇒ 悬空校验写不出来，而这条校验是既定的硬要求。
- **`PoolScope` 三值互斥（枚举 `Kind` + 一个 `TargetId`）** — 否决：它把「某剧情线在某地域的专属敌人」变成不可表达，而这是内容侧最自然的强收窄手段；且枚举 + 裸 `TargetId` 仍然不知道该去哪个仓储查，等于 C 形态换一层壳。
- **`EnemyInstance` 平铺在 `EventOption` 上，`EncounterSpec` 在战斗开始时组装** — 否决：`EncounterSpec` 的另外六个字段全是物化产物，平铺要加 7 个字段且四类非战斗事件恒为默认值；更致命的是「战斗开始时组装」会在 combat-service 一侧形成第二个装配点，而唯一物化点是既定封死项。
- **`EventOption` 只记 `EnemyInstanceId`，实例另存一张表** — 否决：与「定稿实例必须落存档、消费侧不回查」冲突，且引入一张需要垃圾回收的表（一批 eventOptions 被整批换掉时谁去删旧实例？），换不回任何收益。
- **`PastEventEntry` 存整份 `EnemyInstance`** — 否决：见 3c，体积换零新增信息，与未选项那张三方案对照表的 C 行是同一形状的否决。
- **给残卷 / 礼包分开的稀有度权重表** — 否决（既定）：分表等于让付费直接买到更高档强度，与「礼包净强度已上升是被接受的」叠加两次。

## 与既有决策的张力

1. **🔴 `PoolScope` vs `LocationData.EnemyTemplateIds` 是一处已经落笔的第二权威。** 两侧都在生效文档里（后者还进了 `terminology.md`），本库现无机制发现它们不一致。**要么删一侧，要么明写主从并加一条双向一致性校验。** 不裁决就落笔会把这处重复固化进内容层——而内容层一旦开始写 `.tres`，改法就从「改两份文档」退化为「改 N 份内容条目」。详见 2d 与待决第 1 项。
2. **`future-event-service.md` 与 `enemies/_index.md` 对同一问题给出相反状态**（前者「未定」、后者已进 `## 决策(-> ADR)`）。按「活文档只保留最新设计」，应以已答定的一侧为准并删掉另一侧的待决项——**但这属于「改哪一份」的落笔动作，归 `/analyze-new-ideas`，本草稿只指出。**
3. **`PlotModulation.EnemyPoolScope` 的既有注释「对上 `PoolScope`」在 A 形态下语义唯一（一个 arc `Id`），但该字段允许一条 arc 框定另一条 arc 的专属池** —— 这与「剧情线的差异化 = 它自己的专属条目」这条既定判据轻微相悖。建议删字段（待决第 4 项），但它**减少 `PlotModulation` 的字段数**，而那六个字段被明写为「权力面的逐条投影，不多一个字段」——减字段等于收窄权力面，须用户点头。
4. **`EncounterSpec.EncounterId` 在嵌套形态下与 `EventOption.InstanceId` 冗余。** 建议保留（combat-service 看不到 `EventOption`），但它需要像 `LifeSpanAfter` 那样被**明写为例外而非先例**，否则「重算得出来的不存」这条判据会被后来者据此放宽。
5. **残卷侧 `ordinal` 的自增时点未明写，而后端复算校验依赖它。** 严格说这不是「张力」而是一处**会稳定误报的缺口**（见 1d）；把它列在此处是因为它触及一条已冻结的客户端 ↔ 后端契约（`backend-design-documents/contracts/profile-sync.md` §7 的三条校验），**若两侧对口径的理解不同，修正需要对侧库同步承接**。

## 前置依赖

- **`RarityTier` 各档权重数值、`GrantPoolMargin` / `K`** —— 本草稿只定「表挂在哪、按什么维度分表」的结构面；数值归 ch1 数值标杆专场。**结构面不阻塞于数值**（授予池那张表已有初值即是证明）。
- **战后奖励池的三张表（按优势档 `Tier` 选表）** —— 调用点表第 8 行的加权列因此仍是待定，不影响原语形状。
- **敌人卡组改写算子（旋钮 ③）** —— 既定已诚实标注「在 ch1 数值标杆专场之前只是框架」。它决定 `EnemyInstance.DeckCardIds` 的**取值**，不决定它的**形态** ⇒ 不阻塞本草稿。
- **`EventOption` 的完整物化字段清单（S2 分片在办）** —— 本草稿只主张**加一个** `Encounter` 字段，不主张任何其余字段。**若 S2 给出的清单与本草稿的 `Encounter` 不一致（例如它主张平铺敌人字段），须以一次合并裁决收口，不得两侧各写。**
- **结算进行中的 `EventOption` 派生实例如何落存档（S3 分片在办）** —— `Encounter` 嵌在 `EventOption` 上 ⇒ 任何 `with { … }` 派生都会**连带复制这份最胖的载荷**。派生实例的承载形态（替换当前批 / 另有承载）会决定这份复制发生几次、落几次盘。**本草稿的 `Encounter` 字段形态与 S3 的结论必须一致**，且 S3 若选「另有承载」，需明确 `Encounter` 是否随派生一起搬。
- **`CharacterProfile` / `PlayerProfile` schema（S1 分片在办）** —— `PastEventEntry.Enemy` 落在 `CharacterProfile.pastEvent` 内，字段增加牵动那一次 schema bump。**本草稿主张与 S2 / S3 合并进同一次 bump**，具体 bump 编排归 S1。

## 仍需用户决定 → **已全部裁决（2026-08-17 · 批量评审）**

> **定案（六项一律取推荐项 A）：**
> **1 取 A** —— **`PoolScope` 单权威，删 `LocationData.EnemyTemplateIds`**。三层框定收成一段统一 `Where` 链；加一条通用敌人到某地域零改动。连带改 `game-progression.md` 与 `terminology.md`（三组字段变两组），并把「反查」明确归 `LocationCodex` 职责。
> **2 取 A `[采纳推荐 — 待复核]`** —— `PoolScope` = 具名可空字段的内嵌 `Resource`（否决 tag：丢类型 ⇒ 悬空校验写不出）；字段定名 **`PlotArcId`**（本库没有 `PlotLine` 这个类型）；匹配语义 = 逐维度与门、空维度恒真，剧情线一侧传**全部 `Active` arc 的集合**而非单值；六条交叉校验全部采纳，含「通用敌人池在某 `(EventType, 篇章)` 组合下为空 → 启动期 `PushError`」。
> **3 取 A** —— 战斗类 `EventOption` **加一个可空 `EncounterSpec Encounter`，`EnemyInstance` 嵌其内**（加 1 字段而非平铺 7；单一副本；`RunCombatAsync` 签名不动、无第二装配点）。配套采纳：真身为战斗类的 Explore 壳其 `Encounter` 物化时即填好、校验按真身类型判、`PastEventEntry` 加轻摘要 `EnemyTraceRef(EnemyId, Level)`。`EncounterSpec.EncounterId` 在嵌套下冗余，**保留但须明写为例外而非先例**（同 `LifeSpanAfter` 的处置）。
> **4 取「删」** —— `PlotModulation.EnemyPoolScope` 删除，改为隐式取当前 arc 的 `Id`；六字段收窄为五。用户已知悉这是**收窄一个被明写为「逐条投影、不多一个字段」的权力面**，需在 `plot-manager.md` 明写理由。
> **5 取 A** —— 残卷侧 `ordinal` 口径**补写既有意图**（先算 `ordinal = 旧值+1` → 掷骰 → 同一次 `TryApply` 写回），**并通知对侧**：在 `backend-design-documents/` 落承接项，请后端确认 `contracts/profile-sync.md` §7 三条校验与此口径一致。与本轮 Q2 的契约改动同批递过去。
> **6 取 A `[采纳推荐 — 待复核]`** —— Exchange 能力族商品走 `TryPickGrantableMany`，其余三族直用第一级，不新增入口。
>
> **本轮同批裁定的连带（跨分片，orchestrator 合并）：**
> - 本草稿的第 3 项恰好填上同批 S2 明确留白的「缺口 B」⇒ **`EventOption` 本轮共加两格**：S2 的 `Outcome` + 本草稿的 `Encounter`，清单至此闭合。
> - 同批 S3 裁定派生实例承载 = `CharacterProfile.activeEvent`（持整份快照）⇒ 本草稿指出的「`Encounter` 嵌入使 `with` 派生连带复制最胖载荷」**成立且已被用户知悉**；存档体积相应上抬。
> - 第 4 项的删除会改写同批 S2 的「`PlotModulation` 六字段不变」复核结论 ⇒ 提炼时以本项为准（五字段）。
> - 五份草稿的 schema bump **合并为同一次**。
> - 本草稿「越界发现」第 2 条尤须落实：`enemies/_index.md` 中「意图档位在进入战斗前即需可算」是本决定的三条依据之一而**该依据已随 08-15d 意图移除而作废**——结论不变，**理由须重写**。
>
> 下列原文保留为选项与理由的溯源；第 1 项优先级最高——它的答案改变第 2 项的写法。

### 1. 🔴 `PoolScope` 与 `LocationData.EnemyTemplateIds` 的权威归属（两处表达同一关系）

| 选项 | 形态 | 后果 |
|---|---|---|
| **A（推荐）** | **`PoolScope` 唯一权威，删 `LocationData.EnemyTemplateIds`** | 三层框定是一段统一的 `Where` 链；加一条通用敌人到某地域零改动；作用域与敌人条目同侧、编写时一处填完。**代价**：「这个地域会遇到什么」需反查（但那本是 `LocationCodex` 的职责）；要改 `game-progression.md` 的 `LocationData` 定义与 `terminology.md` 的 location 词条（三组字段变两组）。 |
| B | **`EnemyTemplateIds` 唯一权威，`PoolScope` 删掉 `LocationId`、只留 `PlotArcId`** | location 条目自解释、内容编写时「这个地域的生态」一眼读全。**代价**：加一条通用敌人到全部地域要改 N 份 location 条目；`PoolScope` 退化为单字段（那就不必是内嵌 `Resource`，一个 `string PlotArcId` 即可）；且 location 与剧情线两个同性质维度**分居两侧**，取池链变成两种写法。 |
| C | 两侧都留，明写主从 + 加一条双向一致性校验 | 保住两侧的可读性。**代价**：那条校验必须回答「不一致时以谁为准」，而**「两份表 + 一条校验」正是本库反复否决的形态**（`(Kind, Scope) → Source` 那张表明写「只约束客户端组装，后端不复制」即是同一条偏好）。 |

**推荐 A**，理由见 2d。**这一项不裁决则子项 2 的其余部分无法定稿。**

### 2. `PoolScope` 的数据形态：具名可空字段 vs tag

| 选项 | 后果 |
|---|---|
| **A（推荐）具名可空字段的内嵌 `Resource`** | 悬空校验两行写完；与同族的跨类型 `Id` 字段一致；维度封闭故不损失可加性。**代价**：日后真要加第三个维度需改类。 |
| B 一组 tag（`string[] ScopeTags`） | 维度任意可加。**代价（承重）**：丢类型 ⇒ 既定的悬空校验写不出来，或需引入一张不可机械校验的「前缀 → 仓储」约定表。 |

**推荐 A + 字段定名 `PlotArcId`（不是 `PlotLineId`——本库没有 `PlotLine` 这个类型，剧情线的载体是 `PlotArcData`）。** 顺带确认：**剧情线一侧的匹配输入是「全部 `Active` arc 的集合」而非单值**（`MaxConcurrentSideArcs` 允许并发）。

### 3. 战斗类 `EventOption` 的敌人承载形态

| 选项 | 后果 |
|---|---|
| **A（推荐）`EncounterSpec Encounter` 可空字段，`EnemyInstance` 嵌在其内** | 加 1 个字段；敌人实例全库只有一份定稿副本；`RunCombatAsync` 签名不动、不产生第二装配点。**代价**：`EncounterSpec.EncounterId` 与 `EventOption.InstanceId` 冗余（须明写为例外）；`with { … }` 派生会连带复制这份最胖载荷（与 S3 耦合）。 |
| B 平铺 `EnemyInstance Enemy` + 六个遭遇参数字段 | 与 `ResearchSlots` / `ExchangeStock` 的平铺风格更齐。**代价**：加 7 个字段、其中 6 个对四类非战斗事件恒为默认值；且 `EncounterSpec` 需在进入战斗时组装 ⇒ 第二个装配点。 |

**推荐 A。** 并请确认配套结论：**真身为战斗类的 Explore 壳，其 `Encounter` 在物化时即填好**（与 `DestinationLocationId` 的既定处置同构，依据同为防重掷）。

### 4. `PlotModulation.EnemyPoolScope` 是否删除

- **删（推荐）**：改为隐式取当前 arc 自己的 `Id`。理由：当前形态允许一条 arc 框定**另一条** arc 的专属池，无用例且与「剧情线的差异化 = 它自己的专属条目」相悖。**代价**：`PlotModulation` 六字段变五字段，而那六个字段被明写为「权力面的逐条投影」——删一个等于收窄已宣告的权力面。
- **留**：保持权力面不变，注释改写为「可框定任一 arc 的专属池」并承认这是一条有意的权力。**代价**：内容侧多一个可填错的字段（填成别的 arc `Id` 不会报错，只会静默换池）。

### 5. 残卷侧 `ordinal` 口径的确认（🟠 一致性修补）

**建议：账号级两条渠道统一为「先算 `ordinal = 旧值 + 1`，用它掷骰，同一次 `TryApply` 写回」。** 礼包侧已是这个写法，残卷侧未明写。**不统一的后果**：后端用存档里的（自增后）序号复算 `roll'`，与客户端用自增前序号掷出的 `LastRoll` 永不相等 ⇒ 那条既定的防篡改校验在**每一个正常账号上**稳定误报。请确认这是「补写既有意图」还是需要一并通知对侧库（`backend-design-documents/contracts/profile-sync.md` §7）。

### 6. Exchange 能力族商品的排重走哪一级

- **A（推荐）** 能力族商品走 `TryPickGrantableMany`（第二级），其余三族直用 `DrawPool<T>`：不新增入口，「排除已持有」仍只写在一处。**代价**：第 7 行调用点分裂为两种写法。
- **B** 给 `GrantPoolPicker` 加一个「按 `RarityFilter` 取多条」的入口：Exchange 一侧写法统一。**代价**：第二级多一个入口，而它已是全库唯一的能力抽取处，入口越多越容易漏用。

## 越界发现（相邻分片 / 相邻文档，本草稿不处理）

1. **`systems/enemies/_index.md` 与 `common-properties.md` 对样本卡组规模自相矛盾**：前者「规模逐条编排、**不设硬限**」，后者「**规模 15**」。两份都是生效文档，且 `common-properties.md` 那条还带 `PushError` 语义。属 `enemies/` 内部，归内容 / 数值侧。
2. **`systems/enemies/_index.md` 有三处意图机制的残留**（「敌人持有道念、**意图**、行为」·「埋伏不进入**意图**的呈现」·「③ **意图档位**在进入战斗之前即需可算」），而意图机制已于 08-15d 整条移除。第三处尤其要紧——它是「`EnemyInstance` 嵌在 `EventOption` 上」的三条依据之一，**依据本身已作废**（另两条仍成立，故结论不变，但理由要重写）。
3. **`enemies/common-properties.md` 与 `_index.md` 都写了「图鉴在意图黑箱档位下是唯一的信息来源」** —— 同源残留，措辞应改为「图鉴是事前知识的主通道」（`01-combat.md` 已按新口径表述）。
4. **`EnemyTemplateId`（清单 / `future-event-service.md` 的措辞）与 `EnemyId`（`EnemyInstance` record 的实际字段名）指同一个东西**，宜统一为后者。
