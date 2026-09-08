# achievement / common-properties（Achievement 共有属性）

> 所有成就条目共有的属性 / 字段与通用流程。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

### 存档形态：两个顶层键、两条 record

```csharp
// 逐条成就的进度与达成态
public readonly record struct Achievement(string AchievementId, int Progress, bool Completed);

// 逐组的奖励发放水位（幂等载体）
public readonly record struct AchievementGroupState(string GroupId, int RewardedTierPercent);
```

两者各落 `PlayerProfile` 的一个顶层键 `achievement` / `achievementGroup`（形态列见 `../_index.md` 的完整字段表，写入通道见「写入通道」小节）。

- **条目稀疏，不预写全表。** 只有产生过进度的成就才有条目；新账号 = 空列表。这与图鉴的「条目存在 ⟺ 已解锁」不同——成就的条目存在只意味着**有过进度**，故必须有 `Completed` 一格。
- **`Completed` 不可由 `Progress >= Target` 派生（承重）。** `Target` 住内容侧、可经 overlay 上调；派生会让**已达成的里程碑在一次内容更新后回退**，而奖励已经发出去且不可补发。这与「派生量不可靠即不能当幂等键」是同一条判据。
- **`Progress` 的取值域是 `[0, Target]`**，`Target` 逐条目由内容侧给出；施加时按该上界钳制，`Progress == Target ⇒ Completed = true`，**单向、永不回落**。
- **`RewardedTierPercent ∈ {0, 60, 90}`，单调不减。** `0` = 两档皆未发；发放时一格一格推，与 `PlayerEntitlement.BundleRedeemedOrdinal` 的水位式幂等键逐条同构。**不由「奖励条目已在持有列表」反推**——法则可被自愿置换换走，那正是「派生量不可靠即不能当幂等键」明写否决的形态。
- **条目键名取 `<Kind>Id`**（`achievementId` / `groupId`），与 `powerId` / `itemId` / `arcId` / `techniqueId` 全族一致；**集合字段名单数**（`decisions/ADR-0105-singular-collection-field-naming.md`）。
- **展示字段一格不落存档。** 成就名 / 描述 / 图标 / 组名全在 `Resource` 上，组合展示由 UI 层 ViewModel 装配。
- **首批不加任何元数据格**（达成时间 / 达成时篇章 / 达成序号）：客户端时钟不可信 · 实例信息不进账号级静态面 · 篇章对玩家无信息量；且**加一格是在 record 上加字段、老档补默认值、零迁移**，包装层已把加法窗口买下，预先加没有收益。
- **本形态属 `schemaVersion` 1**，登记见 `systems/services/profile-schema-versions.md`。

**读档校验（读宽写严）：**

| 情形 | 语义 | 处置 |
|---|---|---|
| `AchievementId` / `GroupId` 经 `ContentRegistry` 解析不到 | 可选缺失 | `PushWarning` + **保留条目**（overlay 热更可能移除条目，与 `CodexEntry` 同口径） |
| `Progress < 0` | 可选缺失 | `PushWarning` + 钳制到 `0` |
| `Progress > Target` | 可选缺失 | `PushWarning` + 钳制到 `Target`；**`Completed` 原样保留**（内容下调 `Target` 不得撤销里程碑） |
| 同 `AchievementId` 多条 | 可选缺失 | `PushWarning` + 保留 `Progress` 最大者、`Completed` 取或 |
| `RewardedTierPercent ∉ {0, 60, 90}` | 可选缺失 | `PushWarning` + **向下**取到最近合法档——向上等于吞掉一次尚未发放的一次性奖励 |
| 同 `GroupId` 多条 | 可选缺失 | `PushWarning` + 保留水位最大者 |

### 内容形态：两个 `Resource` 类 + 一个内联子资源

```
AchievementData : Resource            Id = achievement.<snake_case_slug>
├ GroupId        : string             → AchievementGroupData.Id（必填，加载期交叉引用校验）
├ Weight         : int   = 1          组内加权进度的权重，[1, 100]
├ Hidden         : bool  = false      true = 隐藏成就，达成后才在目录出现
├ Target         : int   = 1          达成所需的累计计数，>= 1
├ Condition      : AchievementConditionData   （内联子资源，恰一条）
├ DisplayName    : LocalizedText      必填
├ Description    : LocalizedText      必填
├ Artwork        : Texture2D          可空（缺省走既有占位资产回落）
└ ContentEnabled : bool  = true       （共有字段，自动带）

AchievementGroupData : Resource       Id = achievement_group.<snake_case_slug>
├ DisplayName    : LocalizedText      必填
├ Description    : LocalizedText      可空
├ SortOrder      : int  = 0           目录排序（同值时按 Id 字典序，确定性）
├ Tier60Reward   : AchievementRewardSpec   必填
├ Tier90Reward   : AchievementRewardSpec   必填
└ ContentEnabled : bool = true

AchievementConditionData : Resource   （内联，不独立开张内容类型）
├ SignalId  : string       封闭常量表 AchievementSignalIds 的成员（点分 id）
├ Filter    : string?      对该信号一格值的等值匹配；null = 不过滤
└ Amount    : int = 1      每次命中的进度增量，>= 1
```

- **恰一条 `Condition`，不做 AND / OR 组合（首批）。** 同库先例 `EffectCondition` 取的是「封闭谓词 + AND 语义 + 单一落点」；组合谓词在本作的正确表达是**再开一条成就**（成就本就分组、权重可调），而不是把条目做成一棵表达式树。**代价明写**：「同时满足 A 与 B」类成就首批写不出来。
- **`SignalId` 取点分字符串 + 代码侧封闭常量表 `AchievementSignalIds`，不用 C# 枚举。** 点分惯例已由次类型 id 规范立为先例（`terminology.md`），加载期封闭集校验拿到的安全性与枚举等同；而 `.tres` 按序号引用枚举，枚举重排会静默错位。它同时让「加一个信号」不必动一个被 `.tres` 引用的枚举。
- **`Filter` 的类型安全由配表兜住，不由字段类型兜住。** 每个 `SignalId` 在常量表里占一行 `(FilterKind, 说明)`，`FilterKind ∈ { None, ContentId, Enum, Int }`；加载期按行校验（`None` 却填了 → `PushError`；`ContentId` 经 `ContentRegistry` 解析不到 → `PushError`）。与 `StatusFields` / `SettingFields` 的逐行配表同款判据。
- **`Weight == 0` → 加载期 `PushError`。** 权重 0 的成就对进度零贡献，达成它什么都不动，是内容缺陷不是编排手段。
- **`AchievementConditionData` 不独立开张为内容类型**——它几乎恒为某条成就的组成部分，照 `AbilityData` 的既定处置内联在宿主条目文档里。条目层的两个类型文件夹见 `content/_index.md`。

**启动期断言（`#if DEBUG`，纪律阶梯第 3 级）：**

1. `AchievementSignalIds` 覆盖全部信号 id，且每一行的 `FilterKind` 非空 → 缺行 `PushError`（漏行即 `Filter` 的取值域不明，与 `ResourceElements` / `StatusFields` / `SettingFields` 同档）。
2. 每一条信号**指名它的来源**（EventBus 负载表的某一行某一格，或 `ProfileChangeSpec` 的某一列）→ 指不到 `PushError`。它把「加了信号却没有人产生它」变成开机可见。

### 组内加权进度

```
分子 = Σ Weight  over  { a ∈ group | a.ContentEnabled && 该账号 entry.Completed }
分母 = Σ Weight  over  { a ∈ group | a.ContentEnabled }
percent = 分子 * 100 / 分母        // 整数运算，向零取整，全程只取整一次
```

- **分母走 `AllEnabled()`**（一切产出侧过滤走 `AllEnabled()`，见 `systems/common-properties.md`）；**分子的「已达成」读存档、读取侧不过滤**——被线上关掉的成就若已达成，分子与分母同时不计，百分比不回退。
- **水位单调不减 ⇒ 分母变化只影响未来、不撤销已发。** 新增成就使百分比下降时不收回已发奖励；关闭成就使百分比上升到跨档时正常补发。这条闭合语义使内容侧可以放心增删成就。
- **只取整一次**，与 modifier pipeline 的「同层求和 → 只乘一次 → 只取整一次」同一条纪律——分步取整会让 60 / 90 两个阈值在边界上出现 off-by-one。
- **隐藏成就计入分母。** 等权下做完全部可见成就只到 80%，故 90% 档**必须**碰到约一半隐藏成就，隐藏成就因此有真实的机制回报、第二档成为长尾目标。**代价明写**：成就屏上会出现一段无法归因的缺口，那正是隐藏成就的设计意图。`AchievementData.Hidden` 因此**只承担渲染语义**，不承担「排除出分母」语义。
- **公式的唯一落点是 profile-service 的 `GroupProgressPercent(groupId)`**，ViewModel 不自算。

### 隐藏成就的呈现口径

- **不需要第四格 `Revealed`**：揭示条件 = `Completed == true`，与达成完全同刻，多一格即两处真值。
- **目录渲染判据 = `Hidden && !entry.Completed ⇒ 不渲染`**，**不按「存档里有没有这个条目」渲染**——隐藏成就在未达成时同样会累积进度并落存档，按条目存在渲染会当场泄露它的存在。
- **未达成的隐藏成就，其名称 / 描述不加载、不进 ViewModel**，避免「内存里有、被人扒出来」的次生泄露。

Source: `handoffs/2026-09-07c-achievement-schema-collection-and-rewards.md`

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **`AchievementSignalIds` 的首批清单。** 形态已定（点分 id + 封闭常量表 + 逐行 `FilterKind` + 逐行来源指名）；**具体有哪些信号随成就条目目录一并定**。当前可由既有 EventBus 负载表零改动覆盖的至少有 `CycleStarted` / `ChapterCompleted` / `CharacterDefeated` / `EventResolved` / `CombatFinished` / `PlotThresholdReached` 六条；落档类信号由 spec 旁听支从已提交的 spec 读出，不需要任何新广播。

## 对应
提炼至：`.claude/knowledge/systems/player-profile/achievement/common-properties.md`（待建）。
