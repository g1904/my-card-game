---
type: solution-draft
date: 2026-09-07
question: 成就体系整块 —— `Achievement` 条目 schema、`AchievementManager` 的采集面、两档奖励各给什么与奖励条目清单口径
source: open-questions/07-codex-monetization.md → 成就奖励的具体条目目录；systems/services/profile-service.md#待决问题（元进程字段结构 / 采集面）；systems/player-profile/achievement/common-properties.md#待决问题
targets:
  - systems/player-profile/achievement/_index.md
  - systems/player-profile/achievement/common-properties.md
  - systems/services/profile-service.md
  - systems/services/profile-schema-versions.md
  - systems/player-profile/_index.md
  - systems/common-properties.md
  - systems/architecture.md
  - content/_index.md
  - ux/screen-flow.md
  - systems/balance.md
status: distilled
reviewed: 2026-09-07 批量评审 —— 1 项取向（隐藏成就计入分母）+ 1 项张力（screen-flow 措辞松动、结论不变）已裁决
distilled-to: handoffs/2026-09-07c-achievement-schema-collection-and-rewards.md
---

# 方案草稿 — 成就体系整块（`Achievement` schema · 采集面 · 两档奖励口径）

> **评审状态：** 2026-09-07 批量评审（`/batch-provide-solution-draft game`）。1 项取向 + 1 项张力已由用户裁决，见文末 `## 仍需用户决定` 各条目下的「→ 已裁决」行。其余 44 项按通行做法 / 既有推演直接采纳，未出题。

## 问题

成就体系有三个互相咬合的缺口同时悬着，任何一个单独答都会把另外两个逼成臆造：

1. **`Achievement` 条目 schema 未定**（`systems/player-profile/achievement/common-properties.md:25`）。它是 `profile-service.md:445` 四条待决之一，并直接卡住 `profile-schema-versions.md:126` 的 v1 清单——`PlayerProfile.achievement` 的条目结构在它答定前**不得写入推测形状**（`:67`）。
2. **`AchievementManager` 的采集面未定**（`profile-service.md:443`）：EventBus 被动订阅（解耦但易漏）vs 各服务主动上报（可靠但反向依赖）。API 契约表 `:397` 的 `ReportProgress(AchievementSignal)` 是主动上报支的**超前落笔、明标非定案**，须与本条一并定案或整行取消。
3. **两档奖励各给什么、奖励条目清单口径未定**（`open-questions/07-codex-monetization.md:6`）。「能给什么」（法则 / 古宝，`Source.AchievementReward`，不计入残卷 `x`）与「怎么给」（指定条目 + 成就限定，`ExclusiveSource == AchievementReward`，恒不落空）**均已答结，本方案不重开**。

三者咬合点：奖励发放是**一次性、不可补发**的（`achievement/_index.md:12`），故必须有一个可信的幂等载体；幂等载体是存档字段 ⇒ 属 schema；而「什么时候判定跨档」取决于采集面把进度写在哪一次提交里。

## 约束（来自既有设计）

- **两层 Profile 的一切写入经 `ProfileManager.TryApply(spec)`，全有或全无、单点提交**（`profile-service.md:16`–`:33`；`ADR-0009`）。
- **`ProfileChangeSpec` 按施加语义分列，列表数不进承重表述**；「一条新语义该落在哪一层」走三级判据（分列 / 加 `Op` / 配表加列），六面核对（`profile-service.md:37`）。
- **成就奖励 = 指定条目 + 成就限定，不进任何抽取池**；三条校验（加载期 Id 存在 · 加载期 `ExclusiveSource == AchievementReward` · 发放时目标不在持有集合）合起来才等于「不落空」（`achievement/_index.md:11`–`:15`）。
- **`AccountStream` 不需要 `AchievementReward` 成员**——无随机 ⇒ 无掷骰 ⇒ 无序号（`achievement/_index.md:16`）。
- **`Source` 的合法子集表**：`AchievementReward` 只在 `(Power, Player)` / `(Item, Player)` 两格为 ✅（`common-properties.md:292`、`:303`）。
- **`AchievementReward` 得来的法则不计入残卷 `x`**（`monetization.md:38`、`common-properties.md:269`）；`Source` code `3` 已冻结。
- **付费的战斗价值主要由古宝承载、法则保持极其稀缺**（`monetization.md:26`–`:30`，承重的分工）。
- **派生量不可靠即不能当幂等键**；幂等靠水位字段（`monetization.md:80`）。**派生态不能承载原始事实**（`monetization.md:59`）。
- **同族最近先例（应尽量同构）**：`CodexEntry(string Id)` 单格 · 展示文案不进存档条目 · `CodexElements` 零 `Op` · 触发全部**搭既有提交点、零新增存档点** · 触发采集与去重归 `CodexManager`、**写入仍组装 element 经 `ProfileManager` 单点提交**、**不由 `ProfileManager` 自动派生**（否则 `AppliedChange` 记的账与 spec 不一致）+ `#if DEBUG` 兜底断言（`codex/common-properties.md:16`–`:69`、`profile-service.md:193`–`:210`）。
- **EventBus 三条负载纪律**：负载只带 `Id` + 值类型 · 空负载重查 · **广播 = 既成事实、不可否决**（`architecture.md:610`–`:612`）。且 `architecture.md:614` 已为本问题预留处置：「日后成就采集面若定为 EventBus 被动订阅且确有剧本条件，按 `PlotArcAdvanced` 补一行」。
- **纪律阶梯选级判据**：能上线且线上不可见 → 必须第 1/2 级（`architecture.md:633`）。
- **登记表形态纪律 ⑤**：引入一个新顶层键 ⇒ 进版本行；**⑥ 本表不写任何计数**（`profile-schema-versions.md:85`–`:91`）。首发前一切改动归 v1、**不 bump**（`:26`）。
- **内容 `Id` 约定** `<内容类型>.<snake_case_slug>`；四类持有条目用全名前缀（`content/_index.md:94`–`:101`）。**集合字段名恒为单数**（`ADR-0105`）。
- **内容侧编排纪律**：每条成就奖励需一个专属条目，成就目录与内容目录一一对应地一起增长（`achievement/_index.md:18`）。
- **现状**：`game-feature-branch/` 只有 Godot 工程骨架（`project.godot` + icon），**零 C# 脚本、无 `.csproj`**——本方案不得假定任何系统已存在。

---

## 建议方案

### A. 存档形态：两个顶层键、三条 record

`[既有推演]`（`codex/common-properties.md:16`–`:34` 的字段面判据逐条套用 · `monetization.md:80` 的水位式幂等键 · `player-profile/_index.md:57`–`:74` 的 record 形态）

建议 `PlayerProfile` 上落**两个**顶层键，元素各取 `readonly record struct`：

```csharp
// 逐条成就的进度与达成态
public readonly record struct Achievement(string AchievementId, int Progress, bool Completed);

// 逐组的奖励发放水位（幂等载体）
public readonly record struct AchievementGroupState(string GroupId, int RewardedTierPercent);

IReadOnlyList<Achievement>           achievement;       // 既有字段，本方案给出元素形状
IReadOnlyList<AchievementGroupState> achievementGroup;  // 新增顶层键
```

- **条目稀疏，不预写全表**：只有产生过进度的成就才有条目。老档 / 新账号 = 空列表。这与 Codex「条目存在 ⟺ 已解锁」不同——成就的条目存在只意味着「有过进度」，故**必须有 `Completed` 一格**。
- **`Completed` 不可由 `Progress >= Target` 派生（承重）。** `Target` 住内容侧、可经 overlay 上调；派生会让**已达成的里程碑在一次内容更新后回退**，而奖励已经发了。这与「派生量不可靠即不能当幂等键」同一条判据。
- **`RewardedTierPercent ∈ {0, 60, 90}`，单调不减**，与 `BundleRedeemedOrdinal` 逐条同构：0 = 两档皆未发；发放时一格一格推。**不由「奖励条目已在持有列表」反推**——法则可被自愿置换换走（`monetization.md:31`），正是「派生量不可靠」被明写否决的那种形态。
- **键名取 `<Kind>Id`**（`achievementId` / `groupId`），与 `powerId` / `itemId` / `arcId` / `techniqueId` 全族一致（`player-profile/_index.md:68`）。
- **集合字段名单数**：`achievement` / `achievementGroup`（`ADR-0105`）。
- **展示字段一格不落存档**：名称 / 描述 / 图标 / 组名全在 `Resource` 上，由 ViewModel 装配（`achievement/common-properties.md:13`，与 Codex 逐字同款）。
- **首批不加任何元数据格**（达成时间 / 达成时篇章 / 达成序号）：理由与 `CodexEntry` 拒绝那三项逐字相同（客户端时钟不可信 · 实例信息不进账号级静态面 · 篇章对玩家无信息量），且**加一格是在 record 上加字段、老档补默认值、零迁移**，包装层已把加法窗口买下。

### B. 内容形态：`AchievementData` + `AchievementGroupData` 两个类

`[既有推演]`（`achievement/common-properties.md:11`–`:13` 已点名「组 key + 进度权重 + 可见性标记 + 展示字段」四项）· `[通行做法]`（结构化条件表 + 计数阈值是成就系统的行业标准形态）

```
AchievementData : Resource            Id = achievement.<snake_case_slug>
├ GroupId        : string             → AchievementGroupData.Id（必填，加载期交叉引用校验）
├ Weight         : int   = 1          组内加权进度的权重，[1, 100]
├ Hidden         : bool  = false      true = 隐藏成就，达成后才在目录出现
├ Target         : int   = 1          达成所需的累计计数，>= 1
├ Condition      : AchievementConditionData   （内联子资源，恰一条）
├ DisplayName    : LocalizedText      必填
├ Description    : LocalizedText      必填
├ Artwork        : Texture2D          可空（缺省走既有单一占位资产）
└ ContentEnabled : bool  = true       （共有字段，自动带）

AchievementGroupData : Resource       Id = achievement_group.<snake_case_slug>
├ DisplayName    : LocalizedText      必填
├ Description    : LocalizedText      可空
├ SortOrder      : int  = 0           目录排序（同值时按 Id 字典序，确定性）
├ Tier60Reward   : AchievementRewardSpec   必填
├ Tier90Reward   : AchievementRewardSpec   必填
└ ContentEnabled : bool = true

AchievementConditionData : Resource（内联，不独立开张内容类型）
├ SignalId  : string       封闭常量表 AchievementSignalIds 的成员（点分 id）
├ Filter    : string?      对该信号一格值的等值匹配；null = 不过滤
└ Amount    : int = 1      每次命中的进度增量，>= 1
```

- **`AchievementData` 恰一条 `Condition`，不做 AND / OR 组合**（首批）。`[通行做法]` + `[既有推演]`：`EffectCondition` 的「三个封闭谓词、AND 语义、单一落点」是同库先例；组合谓词的正确表达在本作是**再开一条成就**（成就本就分组、权重可调），而不是把成就条目做成一棵表达式树。**代价明写**：「同时满足 A 与 B」类成就首批写不出来。
- **`SignalId` 取点分字符串 + 代码侧封闭常量表，不改 C# 枚举**。依据是同库已立的先例：`TimingIds`（`terminology.md:54`）——「点分惯例已由次类型 id 规范立为先例，加载期封闭集校验拿到的安全性与枚举等同」。它同时让「加一个信号」不必动一个会被 `.tres` 按序号引用的枚举。
- **`Filter` 的类型安全由配表兜住，不由字段类型兜住**：每个 `SignalId` 在常量表里占一行 `(FilterKind, 说明)`，`FilterKind ∈ { None, ContentId, Enum, Int }`；加载期按行校验（`None` 却填了 → `PushError`；`ContentId` 经 `ContentRegistry` 解析不到 → `PushError`）。与 `StatusFields` / `SettingFields` 逐行配表同款判据（`profile-service.md:128`、`:177`）。
- **`achievement/` 与 `achievement-group/` 在 `content/` 下开张为两个类型文件夹**（`content/_index.md:50` 已登记 `achievement/`，本方案增登一行）。`AchievementConditionData` **不独立开张**——它几乎恒为某条成就的组成部分，照 `AbilityData` 的既定处置内联在宿主条目文档里（`content/_index.md:90`）。

### C. 组内加权进度：公式、分母口径与整数纪律

`[既有推演]`（`achievement/_index.md:21` 已定「组内加权进度」+ 60/90 两档）· `[通行做法]`（万分比整数已是全库量纲纪律）

```
分子 = Σ Weight  over  { a ∈ group | a.ContentEnabled && 该账号 entry.Completed }
分母 = Σ Weight  over  { a ∈ group | a.ContentEnabled }
percent = 分子 * 100 / 分母        // 整数运算，向零取整，全程只取整一次
```

- **分母走 `AllEnabled()`**（`common-properties.md:170` 的既定纪律：一切产出侧过滤走 `AllEnabled()`）；**分子的「已达成」读存档、读取侧不过滤**——被线上关掉的成就若已达成，分子与分母同时不计，百分比不回退。
- **水位单调不减 ⇒ 分母变化只影响未来，不撤销已发**：新增成就使百分比下降时不收回已发奖励；关闭成就使百分比上升到跨档时正常补发。这条闭合语义使内容侧可以放心增删成就。
- **`percent` 只取整一次**，与 modifier pipeline 的「同层求和 → 只乘一次 → 只取整一次」同一条纪律（`profile-service.md:340`）——分步取整会让 60 / 90 两个阈值在边界上出现 off-by-one。
- **`Weight == 0` → 加载期 `PushError`**：权重 0 的成就对进度零贡献，达成它什么都不动，是内容缺陷不是编排手段。
- **隐藏成就计入分母**（已裁决，见 `## 仍需用户决定` ①）。`AchievementData.Hidden` 因此**只承担渲染语义**，不承担「排除出分母」语义。

### D. 采集面：与 `CodexManager` 逐字同构的第三形态；`ReportProgress` 整行取消

`[既有推演]`（`profile-service.md:206`–`:210` + `codex/common-properties.md:56`–`:59` 的四条纪律逐条套用）

**结论：既不是「纯 EventBus 被动订阅」，也不是「各服务主动上报」，而是与 Codex 同构的第三形态**——原问题的二选一在 Codex 上已经被同一条判据消解过一次。

> **触发采集与去重归 `AchievementManager`；写入仍组装 `AchievementElements` / `AchievementTierElements` 经 `ProfileManager` 单点提交；每一条采集都搭在一次已经存在的提交上，不新增存档点、不新增 push、不新增决策点。**

信号来源分两支，**分界判据 = 该信号是不是一次落档变更**：

| 支 | 信号类型 | 采集形态 | 举例 |
|---|---|---|---|
| **(a) 服务内 spec 旁听** | 一切经 `TryApply` 的落档变更 | `AchievementManager` 与 `ProfileManager` **同住 profile-service**，提交成功后由服务内部回调 `OnApplied(spec)` 把命中的信号入 pending 队列——**同服务内、不经 EventBus、不构成任何反向依赖** | 获得一条法则 · 收录一条图鉴 · 习得一门功法 · 使用一次古宝 |
| **(b) EventBus 被动订阅** | 不落档的过程量 | `AchievementManager` 自订阅，`_Ready` 订阅 / `_ExitTree` 退订（`architecture.md:186`） | 战斗胜负 · 回合数 · 剧本阈值触发 |

**pending 队列的冲刷点 = 下一次由 life-cycle-service 组装的收口 `TryApply`**，经一个新门面方法一次取走（签名见 §I）。它在收口五步组装里落在**投影之前**（新增列一律按默认落在投影之前——与 `CodexElements` 同批同位，`codex/common-properties.md:57`）；成就奖励授予会改变持有列表，落在投影之前正是它该在的位置。

**四条论证，逐条对上既有判据：**

1. **`ReportProgress(AchievementSignal)` 整行取消。** 它是一个 `void` 方法，漏调**能上线且线上不可见**（成就进度少了一点，没有任何一侧会报错）——按纪律阶梯选级判据（`architecture.md:633`）这要求做到第 1 或第 2 级，而一个门面方法给不出任何强制。本方案的 (a) 支相反：信号从**已提交的 spec** 里读出来，「忘了报」在结构上写不出来（第 1 级）。
2. **不由 `ProfileManager` 自动派生成就 element。** 与 Codex 那条否决逐字同理：自动派生会让 `AppliedChange` 记的账与组装方提交的 spec 不一致，违反「提交的是已算好的整块，本 manager 不做合并 / 增量」。(a) 支读的是**已提交**的 spec、产出**下一批**的 element，不改变任何一次 spec 的内容。
3. **纯 EventBus 被动订阅不够用**（这是原问题里「易漏」的准确形态）：广播发生在 `TryApply` **之后**，在回调里再提交即新开一个存档点，与「零新增提交点」正面相抵；且 EventBus 负载只带 `Id` + 值类型，落档类信号所需的量大半不在负载表里，逐个补广播会把负载契约表撑成 profile 的镜像。
4. **纯主动上报要给每个服务开第二条指向 profile-service 的调用边**，而它不写档、语义与 `TryApply` 分裂——本库对这类形态的既有处置一律是「收进宿主 manager」（`CodexManager` / `GrantPoolManager` 皆然）。

**可执行护栏（纪律阶梯第 3 级，与 Codex 那条同款）：** 一批变更中出现已登记为成就信号的 element（`AbilityElements[Grant]` · `CodexElements` · `DeckElements[LearnTechnique]` …），而 `AchievementManager` 的 pending 队列在该批提交后仍为空 → `#if DEBUG` `PushWarning`。

**代价明写：** pending 队列是内存态，进程崩溃会丢失**至多一个事件内**尚未随收口提交的成就进度（收口必然发生在同一事件内，故丢失窗口是一次事件而非一次轮回）。已达成并已提交的里程碑不受影响。**不为它引入 pending 的持久化**——那等于新开一处存档点，代价与它挡住的窗口失配。

**`architecture.md:614` 的 `PlotArcAdvanced` 预案照常成立**：本方案的 (b) 支正是它设想的那一支；确需剧本条件时按该处所写补一行负载，**而不是**开一条 `ReportProgress` 旁路。

### E. 写入通道：两条新列，各自独立分列

`[既有推演]`（`profile-service.md:37` 的三级判据六面核对）

```csharp
// 列 1：按 AchievementId 的带符号增量（首批只开正向）
public readonly record struct AchievementProgressElement(string AchievementId, int Delta);

// 列 2：按 GroupId 的档位水位置值
public readonly record struct AchievementTierAward(string GroupId, int TierPercent);
```

**六面核对（为何必须分列）：**

| 面 | `AchievementElements` | `AchievementTierElements` | 最接近的既有列 |
|---|---|---|---|
| 键 | `AchievementId` | `GroupId` | — |
| 载荷 | `int Delta` | `int TierPercent` | — |
| 幂等 | **否**（累加） | 是（置值） | `ItemElements` 否 / `SettingChanges` 是 |
| 量纲 | 有 | 无 | — |
| 钳制 | `[0, Target]`，按内容条目逐条 | 无（取值域 `{60,90}` 由校验兜住） | `ItemElements` 按 `ItemData.Charges` |
| pipeline | **恒不走** | **恒不走** | — |

- **不塞进 `Elements`**：`CostKey` 是枚举、按标量索引，装不下一个字符串键；给它加成员会破坏它与两层 Profile 字段表的**双向满射**，并留下一行填不出 `(Min, Max, DepletionDefeat)` 的配表条目（上界是逐条目的 `Target`，不是常量）——与 `ItemElements` 拒绝并入时逐字相同的论证。
- **两列彼此也不合并**：施加语义根本不同（累加 vs 置值）、键不同（条目 vs 组）——按「施加语义根本不同就分列」直接分列。
- **恒不经 modifier pipeline**：一条法则若能放大成就进度，等于让内容自己刷出成就奖励；与 `BundleRedeemedOrdinal` 两个修正列必须为空同源同重。
- **`Completed` 由钳制机械置位，不由组装方声明。** 施加时 `Progress = Clamp(Progress + Delta, 0, Target)`；`Progress == Target` ⇒ `Completed = true`（**单向、永不回落**）。这不违反「本 manager 不做加减」——`ItemElements` 已是「按内容条目的 `Charges` 钳制」的同款先例，读内容做钳制是既有形态。

### F. 奖励形态：每档恰一个专属条目；60% 给古宝、90% 给法则

`[既有推演]`（`achievement/_index.md:11`、`:18` + `monetization.md:26`–`:30` 的承重分工 + `common-properties.md:292` 合法子集表）

```csharp
public readonly record struct AchievementRewardSpec(AbilityCarrierKind Kind, string AbilityId);
// Kind ∈ { Power, Item }；Scope 不进字段，恒为 AbilityScope.Player
```

- **`Scope` 不进字段。** 合法子集表里 `AchievementReward` 只对 `(Power, Player)` / `(Item, Player)` 开 ✅，轮回级两格明确关死（「发一件随轮回清理的东西作为成就回报，与『付费内容不会被游戏销毁』正面冲突」，`common-properties.md:303`）。写进字段等于允许写错一个恒定值——与 `GrantPower` 的 `source` **无默认值**是同一条纪律的反向应用：恒定的不给位置，可变的不给默认。
- **每档恰一条，不是列表。** ① 内容侧编排纪律已定「每条成就奖励需要一个专属条目」；② 单条使「发放时目标不在持有集合」这条断言逐条可判；③ 要给更多时，正确加法是**再开一个成就组**（组是分母的载体），而不是加厚单档。
- **两档族分配：60% → 古宝 `(Item, Player)`；90% → 法则 `(Power, Player)`。** 三条依据全部落在既有承重段上：
  1. **`monetization.md:26`–`:30` 的承重分工**：战斗价值主要由古宝承载（`Charges` 是天然节流阀）、**法则保持极其稀缺**。低门槛档给节流的那一类、高门槛档给稀缺的那一类，是这条分工的直接读数。
  2. **两档奖励必须不同**（`achievement/_index.md:21` 已定）。分给两个族**结构上**满足这一条，不依赖内容作者记得写成两样东西。
  3. **`AchievementReward` 在合法子集表上恰好开两格**，两档各占一格 ⇒ 表上没有一格是死的，也不需要为「两档都给法则」论证法则配额（`UsableScene ≤ 1/5` 的比例检查会被成就目录的增长直接压上）。
- **首批不做第三种形态的账号级奖励。** 穷举账号级可给之物后剩下的**恰好**是这两族：图鉴条目走「接触即记」、给不出来；账号级货币已被「本作没有账号级可支配货币」关死（`monetization.md:150`）；重试上限属 `PlayerEntitlement`、给它等于重演口径变化并绕开「付费凭证只由后端推进」的纪律；纯外观**架构预留、首批不做**（`monetization.md:154`）；寿元是角色级，且与「礼包两个抽取池一概不得产出寿元」同源被关死（`monetization.md:148`）。
- **成就限定条目的 `Rarity` 只剩展示语义**（它不进任何抽取池 ⇒ 权重表读不到它）。内容口径建议：60% 档取中档、90% 档取高档，与门槛梯度视觉对齐；**不为它加任何校验**。

### G. 奖励条目清单口径：加载期四条校验（既有三条 + 新增一条双向唯一性）

`[既有推演]`（`achievement/_index.md:15` 的三条 + 「恒不落空」这条不变式的补全）

| # | 时点 | 判定 | 失败 | 出处 |
|---|---|---|---|---|
| ① | 内容加载期 | 每个 `AchievementRewardSpec.AbilityId` 经 `ContentRegistry` **可解析** | `PushError` | 既有 |
| ② | 内容加载期 | 该条目 `ExclusiveSource == Source.AchievementReward` | `PushError` | 既有 |
| ③ | 发放时 | 目标条目**不在**玩家持有集合中 | `PushError` | 既有 |
| ④ | 内容加载期 | **双向唯一性**：每个奖励槽指向的条目**恰被一个槽引用**；且每个 `ExclusiveSource == AchievementReward` 的条目**恰被一个槽引用** | `PushError` + 两侧 `Id` | **本方案新增** |

**④ 是本方案对「恒不落空」的补全，不是可选项。** 既有三条挡不住两种情形：**同一条目被两个组的奖励槽引用** ⇒ 第二次发放必然撞上 ③ 的断言（而那一刻奖励已经「发了」、玩家什么也没拿到，且是不可补发的一次性回报）；**存在没有任何槽引用的成就限定条目** ⇒ 一条永远不可能被任何渠道拿到的死条目（它不进池、也没人发它）。两者都是内容编排缺陷、都能上线、都线上不可见——按选级判据必须在**发布管线**上大声失败（内容侧纪律的等价第 2 级 = 发布管线跑同一份校验，`architecture.md:638`），与内容包的既有发布侧校验闸**共用同一条管线，不新增管线**。

### H. 隐藏成就与呈现口径

`[既有推演]`（`achievement/_index.md:21` 的 80/20 · `common-properties.md:12` 的可见性标记）

- **不需要第四格 `Revealed`**：揭示条件 = `Completed == true`，与「达成」完全同刻，多一格即两处真值。
- **目录渲染判据 = `AchievementData.Hidden && !entry.Completed ⇒ 不渲染`**，**不按「存档里有没有这个条目」渲染**——隐藏成就在未达成时同样会累积进度并落存档，按条目存在渲染会当场泄露它的存在。这条纪律必须明写在 UX 侧。
- **隐藏成就的名称 / 描述在未达成时不加载、不进 ViewModel**——避免「内存里有、被人扒出来」的次生泄露。这是 `[通行做法]`，成本近零。

### I. API 面与事件面的具体改动

`[既有推演]`（`architecture.md:616` API 书写规范 · `profile-service.md:374`–`:398` 现表）

**API 表（`profile-service.md`「API 面（契约）」）：**

| 动作 | 方法 | 形态 | 完整签名 | 失败语义 |
|---|---|---|---|---|
| **删** | 成就采集 | A | ~~`void ReportProgress(AchievementSignal signal)`~~ | **整行取消**（采集面定为方案 D，门面不开这个方法） |
| **增** | 成就批采集 | A | `AchievementBatch CollectAchievements(ProfileChangeSpec draft)` | 纯内存、**不提交、不广播、不落存档点**；返回值恒非 `null`（无成就时各列为空）。**消费点唯一 = life-cycle-service 的收口组装**，新增消费点须同批评审（与 `Project(spec)` 同款纪律） |
| **增** | 组进度查询 | A | `int GroupProgressPercent(string groupId)` | 组不存在 → `PushWarning` + 返回 `0`（可选缺失）。它是 §C 公式的**唯一落点**，ViewModel 不自算 |

```csharp
public readonly record struct AchievementBatch(
    IReadOnlyList<AchievementProgressElement> Progress,
    IReadOnlyList<AchievementTierAward>       Tiers,
    IReadOnlyList<AbilityChangeElement>       Grants);   // Op == Grant, Source.AchievementReward
```

**事件面：**

| 事件 | 负载 | 处置 |
|---|---|---|
| `AchievementTierReached` | `(string GroupId, int TierPercent)` | **一格不改**（`architecture.md:602` 既有行） |
| `AchievementCompleted` | `(string AchievementId)` | **新增一行**。里程碑达成需要即时反馈（toast），负载只带 `Id`、合规于三条负载纪律 |

### J. 数值初值（全部标为待实测 / 待内容侧校准）

`[通行做法]` + 一条可推导的编排下限

| 参数 | 初值 | 推导 | 旋钮位置 |
|---|---|---|---|
| 档位阈值 | 60 / 90 | **已定，非本方案给出** | `achievement/_index.md` |
| `Weight` 默认 | `1` | 等权是最小惊讶默认；差异化留给内容 | `AchievementData.Weight`（`.tres`） |
| `Weight` 取值域 | `[1, 100]` | 上界只为挡住「一条成就吃掉整组」的编排事故；100 倍差已远超任何合理编排 | 代码常量表 |
| `Target` 默认 | `1` | 多数成就是「做过一次」 | `AchievementData.Target` |
| **组内成就数下限** | **≥ 10** | **可推**：目录 20% 为隐藏 ⇒ 组内 < 10 时隐藏成就数在整数化后要么是 0（该组无隐藏、破坏 80/20）要么占比失真；且 60 / 90 两个阈值在条目数 < 10 时与实际权重和错位（等权下 9 条的可达百分比是 0/11/22/…/100，90% 档不可达）。**这是一条结构约束、不是手感取向** | `content/achievement-group/` 编排口径 |
| 首批组数 | 4–6 组 | 主菜单成就屏一屏可扫完的量级（竖屏、移动优先）；**纯待内容侧定** | 内容编排 |

**数值一律属数据资源、不硬编码**（`.claude/rules/data-resource-rules.md`）；组内成就数下限落**加载期校验**（每个启用组的启用成就数 ≥ 10，不足 `PushError`），与既有三格取池余量同款形态。

---

## 具体形态（可 derive 的落地面）

### 存档字段与 v1 清单补入

| 对象 | 字段 | 类型 | 层 | 写入通道 | 老档缺字段 |
|---|---|---|---|---|---|
| `PlayerProfile` | `achievement` | `IReadOnlyList<Achievement>` | 规则 | `AchievementElements` | 空列表 |
| `PlayerProfile` | `achievementGroup` | `IReadOnlyList<AchievementGroupState>` | 规则 | `AchievementTierElements` | 空列表 |
| `Achievement` | `AchievementId` | `string` | — | 构造必填，无默认 | — |
| `Achievement` | `Progress` | `int` | — | `[0, Target]` | `0` |
| `Achievement` | `Completed` | `bool` | — | 单向置位，永不回落 | `false` |
| `AchievementGroupState` | `GroupId` | `string` | — | 构造必填，无默认 | — |
| `AchievementGroupState` | `RewardedTierPercent` | `int` | — | `{0, 60, 90}`，单调不减 | `0` |

**`profile-schema-versions.md` v1 清单建议补三行**（**仍属 `schemaVersion` 1、不 bump**，`:26` + `:126` 已明写答定后的处置）：

| # | 对象 | 纳入的结构 | 权威 |
|---|---|---|---|
| 35 | `PlayerProfile` | `achievement` 顶层键（元素 `Achievement`） | `systems/player-profile/achievement/common-properties.md` |
| 36 | `PlayerProfile` | `achievementGroup` 顶层键（元素 `AchievementGroupState`） | 同上 |
| 37 | `ProfileChangeSpec` | 新增两列 `AchievementElements` · `AchievementTierElements`（元素 `AchievementProgressElement` / `AchievementTierAward`） | `systems/services/profile-service.md` |

同批须删去 `:67` 与 `:126` 的两处「尚未进清单」占位；`profile-shape-v1.json` 的 golden 快照照既定排期（随 `.csproj` 生成那一批）落地，**本方案不改其排期**。

### 施加失败语义表新增行（`profile-service.md` 那张表）

| 情形 | 语义 | 处置 |
|---|---|---|
| `AchievementProgressElement.AchievementId` 经 `ContentRegistry` 解析不到 | 必需缺失 | `PushError` + 整批拒绝（悬空 `Id` 写进 Profile 会污染存档；与 `CodexUnlock.Id` 同档、同读写不对称） |
| `AchievementProgressElement.Delta <= 0` | 必需缺失 | `PushError` + 整批拒绝（进度单调不减；`0` 是空操作 element = 组装缺陷） |
| 同一批 `AchievementElements` 内出现两条同 `AchievementId` | **正常** | **先求和、再一次钳制**，不告警。同一批里同一信号命中多次是常态（与 `Elements` 那条例外同款判据、同款「先求和再钳制」语义） |
| 目标成就的 `Completed` 已为 `true` | **正常** | 该 element **空操作，不告警**（重复命中是常态，与 `CodexUnlock` 重复收录同款） |
| `AchievementTierAward.GroupId` 解析不到 | 必需缺失 | `PushError` + 整批拒绝 |
| `AchievementTierAward.TierPercent` ∉ `{60, 90}` | 必需缺失 | `PushError` + 整批拒绝 |
| `AchievementTierAward.TierPercent <=` 该组现有水位 | 必需缺失（组装缺陷） | `PushError` + 整批拒绝（水位单调递增；回退或重发都是缺陷。**一次提交跨两档时只提交最高档一条**，两档的两条 `Grant` 照常各一条） |
| 同一批 `AchievementTierElements` 内出现两条同 `GroupId` | 必需缺失（组装缺陷） | `PushError` + 整批拒绝（绝对置值下两条同键 = 调用方自己也不知道该落哪一份；与 `EventStateChanges` / `SettingChanges` 同款） |
| `AchievementElements` 出现在 `SelectCost` 内 | 必需缺失 | `PushError` + 整批拒绝（不变式，独立成行。理由同构：成本侧只放可如实计价的量，而「推进一格成就进度值多少寿元」无法回答） |
| `AchievementTierElements` 出现在 `SelectCost` 内 | 必需缺失 | 同上、独立成行 |
| `EventOutcomeSpec` 任一侧的 `AchievementElements` / `AchievementTierElements` 非空 | 必需缺失 | `PushError` + 整批拒绝，**逐列各自独立判定、不合并成通则**。判据同 `Stats` / `CodexElements` 那两行：内容作者能如实声明的量才进 `OutcomeSpec`，而**内容不得自己发成就** |

**可追溯性日志（非告警）：** 施加时各打一行

```
[ProfileManager-TryApply] achievement id=<AchievementId> delta=<Delta> after=<Progress>/<Target> completed=<bool>
[ProfileManager-TryApply] achievementTier group=<GroupId> tier=<TierPercent>
```

——成就发放是一次性、不可补发的回报，「我到底有没有拿到」是必然会被问到的一类变更。

### 读档校验（`sync-service` / 读档侧，读宽写严）

| 情形 | 语义 | 处置 |
|---|---|---|
| `AchievementId` / `GroupId` 解析不到 | 可选缺失 | `PushWarning` + **保留条目**（overlay 热更可能移除条目；与 `CodexEntry` 同口径、同理由） |
| `Progress < 0` | 可选缺失 | `PushWarning` + 钳制到 `0` |
| `Progress > Target` | 可选缺失 | `PushWarning` + 钳制到 `Target`；**`Completed` 原样保留**（内容下调 `Target` 不得撤销里程碑） |
| 同 `AchievementId` 多条 | 可选缺失 | `PushWarning` + 保留 `Progress` 最大者、`Completed` 取或 |
| `RewardedTierPercent` ∉ `{0,60,90}` | 可选缺失 | `PushWarning` + **向下**取到最近合法档（**绝不向上**——向上等于吞掉一次尚未发放的一次性奖励） |
| 同 `GroupId` 多条 | 可选缺失 | `PushWarning` + 保留水位最大者 |

### 启动期断言（`#if DEBUG`，纪律阶梯第 3 级）

1. `AchievementSignalIds` 常量表**覆盖全部信号 id**，且每一行的 `FilterKind` 非空 → 缺行 `PushError`（漏行即 `Filter` 的取值域不明，与 `ResourceElements` / `StatusFields` / `SettingFields` 同档）。
2. `AchievementSignalIds` 的每一条**指名它的来源**（EventBus 负载表的某一行某一格，或 `ProfileChangeSpec` 的某一列）→ 指不到 `PushError`。它把「加了信号却没有人产生它」变成开机可见。
3. 采集护栏：一批变更中出现已登记为成就信号的 element 而 pending 队列在提交后仍为空 → `PushWarning`（与 Codex 那条同款）。

### 内容侧登记（`content/_index.md`）

- `achievement/` 行的就绪度由 🟠 改 🟢（欠的只剩条目本身）；新增 `achievement-group/` 一行，类定义权威同指 `systems/player-profile/achievement/`。
- 依赖图 `:78` 那一行照原样成立（`character-item / player-power / player-item └─▶ achievement（奖励目录指定条目）`），**本方案不改依赖方向**。

---

## 后果

- **文档面**：`achievement/_index.md`（采集面 + 两档族分配 + 第四条校验）· `achievement/common-properties.md`（字段清单成文，两处待决清空）· `profile-service.md`（两条新列 + 失败语义 10 行 + API 表一删两增 + 事件面一行 + manager 表 `AchievementManager` 职责改写）· `profile-schema-versions.md`（v1 清单 +3 行，删两处占位）· `player-profile/_index.md`（字段表 `achievement` 行写入通道列由 `AchievementManager` 改为 `AchievementElements`，并新增 `achievementGroup` 行）· `common-properties.md`（`Artwork` 挂载面表加 `AchievementData`；`ExclusiveSource` 段的「首个也是当前唯一用例」回链可指向第四条校验）· `architecture.md`（EventBus 负载表 +1 行 `AchievementCompleted`；`:614` 的 `PlotArcAdvanced` 预案保留）· `content/_index.md`（登记表 +1 行、就绪度改档）· `ux/screen-flow.md`（成就屏渲染判据 + `:264` 措辞，见「张力」）· `balance.md`（组内成就数下限一格，随 `GrantPoolMargin` 那批填）。
- **存档 schema**：新增一个顶层键 `achievementGroup`（形态纪律 ⑤ 第一档 ⇒ 进版本行），`achievement` 的元素形状定形。**首发前 ⇒ 仍属 v1、不 bump、零迁移。** golden 快照 `profile-shape-v1.json` 待建那条不受影响（它本就随 `.csproj` 一批）。
- **后端配合**：`achievement` / `achievementGroup` 两个顶层键是否进**透明段**、是否受回声校验约束，是跨边界事实，本库判不了（权威在 `backend-design-documents/contracts/profile-sync.md` §5）。**倾向不进透明段**（成就不参与后端复算、不承载付费凭证），若成立则后端零配合。见「前置依赖」。
- **代码面**：`game-feature-branch/` 尚无任何 C# 脚本 ⇒ 本方案不产生任何改代码的动作，只产生一份可 derive 的形态。
- **不产生的东西（明写）**：不新增服务 · 不新增 manager · 不新增存档点 / flush 点 / 决策点 · 不新增抽取池 · **不新增 `AccountStream` 成员**（无随机）· 不新增 `CostKey` / `StatKey` 成员 · 不改任何既有 element 的语义 · 不改 `Source` 枚举一格。

---

## 备选方案（已考虑并否决）

- **保留 `ReportProgress(AchievementSignal)`，采集面定为「各服务主动上报」** — 否决：`void` 方法的漏调**能上线且线上不可见**，按选级判据要求第 1/2 级强制而它给不出；且给每个服务开第二条指向 profile-service 的非写档调用边。
- **采集面定为「纯 EventBus 被动订阅」** — 否决：广播在 `TryApply` 之后 ⇒ 发放必然是第二次提交（新增存档点）；且落档类信号所需的量大半不在负载表里，逐个补广播会把负载表撑成 profile 的镜像。**方案 D 的 (b) 支保留了它真正管用的那一半**（不落档的过程量）。
- **由 `ProfileManager` 看到 element 就自动派生成就进度** — 否决：与 Codex 那条逐字同理，会让 `AppliedChange` 记的账与组装方提交的 spec 不一致。
- **`Completed` 由 `Progress >= Target` 派生、不落存档** — 否决：`Target` 经 overlay 上调会让已达成的里程碑回退，而奖励已发。
- **组水位由「奖励条目已在持有列表」反推、不新增顶层键** — 否决：法则可被自愿置换换走，正是「派生量不可靠即不能当幂等键」明写否决的形态。
- **两条新列合并为一列（带 `Op` 区分累加 / 置值）** — 否决：键不同（条目 vs 组）、载荷语义不同，合并即让载荷有一半字段对某个 `Op` 恒空，正是 `ChangeElement` 拒绝加可空字段时否决过的形状。
- **组水位塞进 `Elements` / `CostKey`** — 否决：键是字符串、`CostKey` 是枚举；加成员会破坏它与两层 Profile 字段表的双向满射，并留下一行填不出取值域的配表条目（与 `ItemElements` 拒绝并入同一论证）。
- **`AchievementRewardSpec` 做成列表（一档给多件）** — 否决：与「每条成就奖励一个专属条目」的既定编排纪律冲突，且让「发放时目标不在持有集合」的断言从逐条可判退化为逐批可判。要给更多的正确加法是再开一组。
- **成就条件做成表达式树 / 多谓词 AND-OR** — 否决：同库先例 `EffectCondition` 已取「封闭谓词 + AND 语义 + 单一落点」；组合诉求的正确表达是再开一条成就。
- **`SignalId` 用 C# 枚举而非点分字符串 + 封闭常量表** — 否决：`.tres` 按序号引用枚举，枚举重排会静默错位（`profile-service.md:355` 已为此立过断言）；`TimingIds` 是同库的正面先例。
- **`AchievementData` 加「达成时间 / 篇章 / 序号」元数据** — 否决：与 `CodexEntry` 拒绝那三项逐字同理（客户端时钟不可信 · 实例信息不进静态面 · 篇章无信息量），且加一格是零迁移的、首批没有理由预先加。
- **加第四格 `Revealed` 表达隐藏成就已揭示** — 否决：揭示与达成完全同刻，多一格即两处真值。
- **成就状态型条件（「当前拥有 20 条法则」）** — 否决：持有可减（置换），会让已达成的里程碑回退；等价写法是累计计数型（「累计获得 20 条法则」），且单调计数使 `Completed` 永不回落成为**结构**保证而非纪律。**代价明写**：目录里写不出「当前拥有」类成就。
- **两档都给法则 / 都给古宝** — 否决：`achievement/_index.md:21` 已定「两档奖励不同」，同族分配把这条降级为靠内容作者记得；且都给法则会与「法则保持极其稀缺」的承重分工正面顶上。
- **pending 队列持久化（防进程崩溃丢失至多一个事件内的进度）** — 否决：等于新开一处存档点，代价与它挡住的窗口失配。

---

## 与既有决策的张力

**一处，已裁决。**

**`ux/screen-flow.md:264`：「成就 / 图鉴 — 零呈现——成就结算在玩家按下主按钮之后才跑，本屏读不到结果」**（`CycleEndScreen` 变体表）与 `life-cycle-service.md:170` 的四步时序「`CycleEndScreen` → 按主按钮 → `TeardownCycle()` → **成就结算** → 回主菜单」。

- **冲突点**：本方案的「零新增提交点」意味着轮回终结类成就的**写入**必然落在角色 `defeated` / `completed` 那一次 `TryApply` 内（`life-cycle-service.md:168` 的那一次），而那一次发生在 `CycleEndScreen` **之前** ⇒ 本屏其实读得到结果，`:264` 的因果陈述不再成立。
- **为什么方案需要它松动**：另一条路是把终结类成就的写入推到 `TeardownCycle()` 之后**另开一次提交**——那是一个新的存档点 + 新的 flush 点，与 Codex 那条「零新增提交点是最强的工程依据」正面相抵，且成就发放（授予法则 / 古宝）与角色终结分成两次事务后，中间崩溃即「角色没了、奖励也没发」。
- **松动的代价**：`:264` 的措辞要改；改后本屏「成就零呈现」这条**结论不变**，变的只是理由。
- **不松动时的替代方案**：把成就发放整体移出收口事务，放在 `TeardownCycle()` 之后单独一次 `TryApply` + 一次 `Immediate` push。**不推荐**：一个新存档点 + 一个非原子的两段发放，换来的只是一句文档措辞不用改。

**→ 已裁决（2026-09-07 · 批量评审）：松动措辞、不松动结论。**「成就结算」重新定性为**呈现时点**；`:264` 的结论「本屏成就零呈现」原样保留，理由由「读不到」改为「这一刻不该给第二条情绪线，成就呈现落主菜单成就屏与 `AchievementCompleted` toast」。`systems/services/life-cycle-service.md:170` 的四步时序**一字不改**（第 4 步的「成就结算」读作呈现）。成就发放留在收口那一次 `TryApply` 事务内，零新增存档点 / flush 点。

---

## 前置依赖

1. **`achievement` / `achievementGroup` 两个顶层键是否进透明段、是否受回声校验约束** —— 权威在 `backend-design-documents/contracts/profile-sync.md` §5，本库不复制。**本方案倾向「不进透明段」**（成就不参与后端复算、不承载付费凭证、被篡改无跨端结算后果），若成立则后端零配合、v1 行的「触碰透明 / 回声路径」列不变。**若判定进透明段**，则按登记表形态纪律 ⑤ 第三档「两侧同批落笔并进版本行」处理——**这一半归后端库，本草稿不承载**，届时需一份 counterpart 草稿。
2. **成就条目目录本身**（哪些成就、分几组、每组几条）—— 属内容编排，依赖法则 / 古宝的**条目**（`content/_index.md:50`：「类定义已齐备，欠的是条目本身」）。本方案只定形态与编排下限（组内 ≥ 10 条），**不写任何一条具体成就**。
3. **`AchievementSignalIds` 的首批清单** —— 形态已定（点分 id + 封闭常量表 + 逐行 `FilterKind` + 逐行来源指名），**具体有哪些信号随成就目录一并定**。当前可由既有 EventBus 负载表零改动覆盖的至少有：`CycleStarted` / `ChapterCompleted` / `CharacterDefeated` / `EventResolved` / `CombatFinished` / `PlotThresholdReached` 六条；落档类信号由 (a) 支从 spec 读出，**不需要任何新广播**。
4. **`profile-shape-v1.json` golden 快照** —— 既定排期项（随 `.csproj` 生成那一批，`open-questions/05-service-contracts.md:28`），**不阻塞本方案任何一项 derive**。

---

## 仍需用户决定

> 本节两项均已于 2026-09-07 批量评审中裁决，**零剩余**。

### ① 90% 档是否要求玩家必须达成部分隐藏成就（隐藏成就是否计入组内进度分母）

`[取向选择]`

目录 **80% 可见 / 20% 隐藏**已定。等权下，一个玩家**做完全部可见成就**只能拿到 **80%** ——高于 60% 档、**低于 90% 档**。因此「隐藏成就计不计入分母」直接决定第二档能不能靠可见成就单独拿到。

| 选项 | 后果 |
|---|---|
| **① 计入分母**（推荐） | 90% 档**必须**碰到至少一半的隐藏成就（20% 里要拿到 10 个百分点）。隐藏成就因此有真实的机制回报，第二档成为长尾目标；代价是玩家可能「不知道还差什么」——这正是隐藏成就的设计意图，但它会在成就屏上表现为一段无法归因的缺口 |
| ② 分母只含可见成就 | 全做完可见成就 = 100%，两档都能凭可见目录拿到。隐藏成就退化为**纯文本彩蛋、零机制回报**，与「有奖励的里程碑」这条 `Achievement` 与统计计数的分野（`terminology.md:72`）不再对齐 |
| ③ 分母含隐藏、但把 90% 降到 80% | 可见目录恰好卡在档上——**否决理由**：60/90 是已定阈值，改它牵动的是一条已答结的决策，且「恰好卡在档上」意味着任何一次内容增删都会让第二档在可达与不可达之间跳变 |

**→ 已裁决（2026-09-07 · 批量评审）：计入分母（选项 ①）。** ⇒ §C 的公式与 §J「组内启用成就数 ≥ 10」的结构下限照原样成立、无需重算；`AchievementData.Hidden` **只承担渲染语义**，不承担「排除出分母」语义。

### ② `ux/screen-flow.md:264` 的措辞松动

`🟠`（不是纯取向，是一条承重措辞的裁定）

**→ 已裁决（2026-09-07 · 批量评审）：松动措辞、不松动结论。** 详见上方 `## 与既有决策的张力` 一节的裁决行。
