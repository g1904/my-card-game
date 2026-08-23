---
type: solution-draft
date: 2026-08-22
question: `CombatRulesData` 一类单例平衡表怎么进 ContentRegistry —— `Id` 形态？走哪个仓储？`AllEnabled()` 对单例是否有意义？
source: open-questions/01-combat.md → 结构与配置的残留 → 单例平衡资源如何进 ContentRegistry（08-22 新增）
targets: systems/services/content-service.md（仓储面 + 「结构性查表类恒启用」表 + 单例读取入口与校验）· systems/balance.md（平衡资源的注册形态与切分判据）· systems/game-progression.md（`LocationMapData` 的「多份 / 零份」校验改为回链）· content/_index.md（一句澄清：不建 content/ 类型 ≠ 不进注册表）
status: distilled
reviewed: 2026-08-22 —— 四项取向与两条张力全部按推荐裁定（两段式 `combat_rules.default` · 标记接口 `ISingletonContent` · 早于 `LoadAll()` 的旋钮写死为常量 + 如实标注 · 两处补澄清），其中「不设兜底大表、按三问判据逐份切」经第 1 轮阻断题正式拍板。
distilled-to: `handoffs/2026-08-22-singleton-balance-resource-registry.md`
---

# 方案草稿 — 单例平衡资源如何进 ContentRegistry

## 问题

全库已经反复把可调数值落到「平衡资源 `.tres`」上：`CombatRulesData`（起手 4 / 每回合抽 2 / 手牌上限 7，可被 `EncounterSpec` 可空覆写）、08-22 新定的 `EnemyLevelingData`（三章赋级带 + 带内权重）、`TravelFullFanoutChance`、`BatchSizeWeights`、`GrantPoolWeights`、`SelectionWeightGrades`、`rewardPerMomentum` 单价表、`itemPowerRatio` 四档、篇章重试上限两行……并已把「平衡表」归入本地内容层的**「被存档引用 · 只改不增」**一栏（`systems/services/content-service.md`、`decisions/ADR-0007`）。

**但全库没有一处说明它们怎么进注册表。** 缺的是四件事：

1. 单例平衡资源的 **`Id` 形态**是什么（全库 id 约定是两段式 `<内容类型>.<snake_case_slug>`，而单例只有一条，slug 写什么？）；
2. 它**走哪个仓储**——是既有的泛型 `IContentRepository<T>`，还是另开一条路？
3. **`AllEnabled()` 对单例是否有意义**——单例不是抽取池的成员，取池入口那条纪律套不上来；
4. 调用方**怎么把那一条取出来**——`Repo<CombatRulesData>().Get("???")` 里那个字符串从哪来。

卡住的是实现面：`/blueprint` 消费 `balance.md` 时会立刻撞上「combat-service 启动时从哪拿到这份 `CombatRulesData`」，而文档给不出答案；每个消费者各自发明一次，就会长出五种取法。

## 约束（来自既有设计）

- **平衡表属本地内容层**（`res://` 基线 + `user://overlay/` 热更），**只改不增**、**需启动期强校验**。→ `systems/services/content-service.md`、`decisions/ADR-0007-local-content-layer-and-overlay.md`
- **ContentRegistry 是全游戏唯一内容读取入口，代码中不散落 `ResourceLoader.Load`。** 新增一种内容类型 = 新增一个 `XxxData` 与一个仓储条目，**不新增服务、不改调用方**。→ `systems/services/content-service.md`「统一操作接口」
- **仓储上没有中性名 `All()`**：`AllEnabled()`（抽取池，产出侧唯一入口）/ `AllIncludingDisabled()`（全量：启动期校验 / 图鉴统计 / 调试）/ `[Obsolete(error: true)] All()` 编译闸。**删掉中性诱饵名**是这条纪律的执行形态。→ 同上「`AllEnabled()` 纪律的可执行化」
- **结构性查表的内容类型恒启用**：不是抽取池成员、而是被查表读取的结构 ⇒ `ContentEnabled == false` → 加载期 `PushError`，解析走 `AllIncludingDisabled()`，**flags 第三层对其不生效**。现表四行：`HiddenStatBandData` · `LocationData` · `LocationMapData` · `PlotNodeData`。→ 同上
- **已有一个「全局唯一资源」的完整先例**：`LocationMapData` 是单份全局唯一，已定「进 `ContentRegistry`、启动加载一次常驻、只读不写、存档只存当前 location 的 `Id`」，且**已手写一条加载期校验「存在多份 / 零份 → `PushError`」**。→ `systems/game-progression.md`
- **条目 `Id` 约定 = `<内容类型>.<snake_case_slug>`**，各类型档案照抄不各自发明；**稳定 `Id` 是其他一切引用的键**，绝不用路径 / 索引 / 显示名。→ `content/_index.md`、`systems/common-properties.md`「稳定 Id 键」
- **overlay 合并按 `Id` 覆盖基线**；合并期 `newIds` 双闸中的**闸 A** 规定：overlay 新增的 `Id` 其宿主类型必须 ∈ { `PlotArcData`, `PlotNodeData` }，否则 `PushError`。→ `systems/services/content-service.md`
- **纪律的可执行化阶梯**：能上线且线上不可见的错误必须做到第 1 / 2 级（类型 / 可见性 / 编译期），第 3 级（加载期）是兜底。→ `systems/architecture.md`、`decisions/ADR-0013`
- **切分判据的先例**：`EnemyLevelingData` **不并入** `CombatRulesData` —— 消费者不同（物化 vs 战斗）、覆写纪律相反（不接受覆写 vs `EncounterSpec` 可空覆写）；合成一份会让「哪些字段可被覆写」变成逐字段记忆。→ `systems/balance.md`
- **`content/` 层不定义字段、且「平衡数值归 `systems/balance.md`，不是条目」**（已裁定不单开 `content/balance/` 类型）。→ `content/_index.md`
- **启动链第一步是 content-service 的 `InitializeAsync`（manifest 比对 + overlay 合并 + `LoadAll()` 校验）**；flags 首次拉取排在登录之后。→ `systems/architecture.md` 总则 4、`systems/services/content-service.md`
- **可调数值不硬编码，系统从数据中读取；坏数据必须在启动期大声失败。** → `.claude/rules/data-resource-rules.md`

## 建议方案

### 1. 单例平衡资源**进** ContentRegistry，不另开通道
`[既有推演]`

不是一个选择题：平衡表已被归入本地内容层的「只改不增」一栏，而**该栏的三项性质（overlay 可热更 · 合并后强校验 · 按 `Id` 索引）全部由 ContentRegistry 兑现**。把它挪出注册表意味着同时失去这三项：

- 在服务里 `ResourceLoader.Load("res://content/balance/combat_rules.tres")` → 直接读的是 `res://` 基线，**overlay 覆盖层被绕过**，「平衡数值可热更而不发版」这条 ADR-0007 的核心收益当场失效（overlay 是按 `Id` 合并进注册表的，不在文件系统层做覆盖）；
- 同时绕开合并后强校验，坏平衡表要等到轮回中途才炸；
- 同时违反「不散落 `ResourceLoader.Load`」。

**故本题的第一个正面答案：进注册表，与其他内容同一条路。** 与它同形的先例是 `LocationMapData`——它同样是「单份全局唯一、启动加载一次、只读常驻、不进存档」，已定为进 `ContentRegistry`。

### 2. `Id` 形态 = 照抄全库两段式；**`Id` 的消费者是 overlay 合并，不是调用方**
`[既有推演]` + 第 2 题为 `[取向选择]`

**关键澄清（本条是本草稿最容易被误解的一处）：单例资源之所以必须有稳定 `Id`，不是因为有人要用 `Id` 去查它，而是因为 overlay 按 `Id` 覆盖基线。** 没有稳定 `Id` 就没有热更；而调用方**不应该**、也**不需要**看到这个 `Id`（见第 4 条的 `Single<T>()`）。这两件事必须分开说，否则会得出「既然没人查，那给不给 `Id` 无所谓」这个错误结论。

形态建议照抄 `content/_index.md` 的两段式，slug 取固定的 `default`：

| 资源 | `Id` | 基线路径 |
|---|---|---|
| `CombatRulesData` | `combat_rules.default` | `res://content/balance/combat_rules.tres` |
| `EnemyLevelingData` | `enemy_leveling.default` | `res://content/balance/enemy_leveling.tres` |

理由：**全库只保留一种 id 语法**（「恰好一个点」是可机械检查的），且日后若某份资源真的长出第二行（例如按 `x` 分档的多份配置），语法不必改。代价是 `.default` 这一段当前不携带信息。备选见「仍需用户决定」第 1 题。

- **前缀沿用「不用裸 `item.` / `power.`」那条前缀词表纪律**：平衡资源的类型前缀是资源自己的全名 snake_case（`combat_rules` / `enemy_leveling`），不与次类型命名空间撞车。
- **`Id` 写在 `.tres` 里，不写进任何 C# 常量**——写常量就等于把它变成调用方可见的字符串键，而字符串键正是本库反复否决的形态（`CapabilityFlag` 用 enum 不用字符串 key，判据是「拼错了从编译期推迟到运行时」）。

### 3. 走既有泛型仓储，**不新增仓储种类、不新增服务**
`[既有推演]`

`IContentRepository<T> where T : Resource` 对全部内容类型是**同一形状**，而「新增一种内容类型 = 新增一个 `XxxData` 与一个仓储条目」已是既定条款。单例是「条目数恰好为 1 的类型」，**不是另一种东西**——为它开第二种仓储接口，等于给「唯一内容读取入口」开一个平行入口，且会立刻要求回答「哪些类型走哪条路」这种逐类型记忆的问题。

**故：`Repo<CombatRulesData>()` 与 `Repo<CardData>()` 是同一件事**，差别只在这个类型的合法条目数被声明为 1（第 5 条）。

### 4. 读取面 = 注册表上的 `T Single<T>()`，带**编译期**的类型约束
`[通行做法]`（单例注册表 + LINQ `Single()` 的既有语义）

调用方需要的是「把那一条拿出来」，而不是「用一个我背下来的字符串去查」。建议在 ContentRegistry 上加一个方法：

```csharp
T Single<T>() where T : Resource, ISingletonContent;
//   恰好一条 → 返回它
//   零条 / 多条 → 在 LoadAll() 时就已 PushError + throw（见第 5 条），此处不可能到达
```

三条理由，逐条对上既有纪律：

- **`Id` 字面量彻底不出现在调用方**——`combat-service` 写 `Content.Single<CombatRulesData>()`，没有可拼错的字符串。这与「`CapabilityFlag` 用 enum 不用字符串 key」、「`Repo<T>()` 而非七个具名属性」是同一种偏好。
- **`where T : ISingletonContent` 是一道编译闸（阶梯第 2 级）**：对 `CardData` 调 `Single<T>()` **编译不过**。这正是本库「删掉中性诱饵名 `All()`」那条纪律的同款做法——不靠条款靠类型。
- **语义与 LINQ 的 `Single()` 逐字一致**（不是 1 条就抛），读者零学习成本；名字不必发明。

**它不是第二个诱饵名。** `AllEnabled()` / `AllIncludingDisabled()` 那对名字的问题是「两个语义、一个中性名」；`Single<T>()` 只在单例类型上可见，**在它可见的地方它就是唯一正确的取法**，不存在第二种语义可选。

### 5. 单例身份由**标记接口**声明，加载期校验条数
`[既有推演]` + 识别方式为 `[取向选择]`（第 2 题）

```csharp
/// 标记：这个内容类型全库恰好一条。ContentRegistry 据此做条数校验并开放 Single<T>()。
public interface ISingletonContent { }

[GlobalClass] public partial class CombatRulesData   : Resource, ISingletonContent { … }
[GlobalClass] public partial class EnemyLevelingData : Resource, ISingletonContent { … }
[GlobalClass] public partial class LocationMapData   : Resource, ISingletonContent { … }
```

加载期校验（合并后强校验内，全量、非 `#if DEBUG`，全部带类型名定位）：

| 违规 | 语义 | 处置 |
|---|---|---|
| 某 `ISingletonContent` 类型的条目数 `!= 1` | 单例被写成零份 / 多份，读取面无定义 | `PushError` + 抛，带类型名与实际条数 |
| 某 `ISingletonContent` 条目 `ContentEnabled == false` | 结构性查表类恒启用（第 6 条） | `PushError` + 抛，带类型名 |

- **这不是新增一条校验，而是把一条已存在的手写校验一般化。** `systems/game-progression.md` 的图校验表里已经有「`LocationMapData` 存在多份 / 零份 → `PushError`」这一行；标记接口让它对**全部**单例类型自动成立，那一行随之改为回链，不必逐份手写（漏写一份就是一个静默的洞）。
- **overlay 侧已被闸 A 兜住**：overlay 新增的 `Id` 其宿主类型必须 ∈ { `PlotArcData`, `PlotNodeData` }，故 overlay **不可能**把一份单例变成两份。条数校验因此主要防的是 `res://` 基线的编写错误（复制粘贴出第二份 `.tres`）。

### 6. `AllEnabled()` 对单例**没有意义**，且这不是「无害地没意义」——单例归入「结构性查表类恒启用」
`[既有推演]`

`content-service.md` 已给出判据：**有一类内容不是抽取池的成员，而是被查表读取的结构；对它们「放量开关无处安放」——关掉一条不会让它不再被抽到，只会在结构上造出空洞。** 这条判据逐字适用于单例平衡资源：关掉 `CombatRulesData`，战斗就没有起手手牌数、抽牌数与手牌上限，不是「少一个候选」而是**规则层缺了一块**。

故建议在 `content-service.md` 的「结构性查表的内容类型恒启用」表上**追加一行（按判据，不按逐类型枚举）**：

| 类型 | 结构身份 | 关掉一条会怎样 |
|---|---|---|
| **一切 `ISingletonContent`（含各单例平衡资源）** | 被查表读取的全局唯一结构 | 消费它的规则整块缺失（如战斗没有起手 / 抽牌 / 手牌上限），不是「少一个候选」 |

推论三条，全部是既有语义的直接套用：

- **`ContentEnabled` 字段随内容共有字段照带，但无语义**，`false` → 加载期 `PushError`；
- **flags 第三层对单例不生效**——flags 只作用于 `AllEnabled()` 取池，而单例不经取池；
- **`Single<T>()` 内部走全量口径（`AllIncludingDisabled()`）**，与合并后强校验、`LocationData` 解析同款。

**否决「给单例仓储砍掉 `AllEnabled()`」**：那要求单例走一个形状不同的仓储接口，直接打破「对外是同一形状」这条既定条款，换来的只是挡住一个本就没人会写的调用（`Repo<CombatRulesData>().AllEnabled()` 返回一条，无害且无用）。**用类型约束把正确路径变成最短路径**（第 4 条）已经够了，不必再为一个无害调用改接口形状。

### 7. 切成几份：沿用 `EnemyLevelingData` 已经用过的三问判据，**不设兜底大表**
`[既有推演]` + 是否设兜底大表为 `[取向选择]`（第 3 题）

08-22 裁定「`EnemyLevelingData` 不并入 `CombatRulesData`」时用的理由，正好可以提炼成一份通用判据。建议明写为三问：

| 问 | 分开的信号 |
|---|---|
| ① **消费者是谁**（哪个 service / manager 读它） | 消费者不同 ⇒ 倾向分开 |
| ② **覆写纪律是什么**（可被 `EncounterSpec` 一类可空覆写 / 不接受任何覆盖参数） | 纪律相反 ⇒ **必须**分开（否则「哪些字段可覆写」退化为逐字段记忆） |
| ③ **有没有跨字段不变式** | 有（如带宽 == 权重数组长度）⇒ **必须**同住一份，否则产生无人校验的跨文件不变式 |

**当前可点名的单例平衡资源只有两份**（`CombatRulesData` · `EnemyLevelingData`）；`balance.md` 里其余尚未定名的旋钮（`GrantPoolWeights` · `BatchSizeWeights` · `SelectionWeightGrades` · `rewardPerMomentum` 单价表 · `itemPowerRatio` 四档 · 篇章重试上限两行 · `lifeSpanCost` 与商店两张定价表 · 回寿量小表 · 取池余量三格 · 残卷三张分档表 …）**本草稿不替它们切分**——那要逐条回答「消费者是谁」，属各自专场的事，现在切等于臆造。三问判据先立，切分随各旋钮的消费者明确时逐份做。

### 8. 边界：**消费点早于 `LoadAll()` 的旋钮不能住注册表**
`[既有推演]`

这是一条推演出来、但库内尚未写下的硬边界，且已有一个现成的违反候选：

`balance.md` 的「同步 / 内容管线旋钮」表里，**`overlay 下载重试次数 / 退避（3 次 / 1s · 2s · 4s）` 的消费点是 `ContentUpdateManager.CheckAndUpdateAsync`，它跑在 `LoadAll()` 之前**——那时 ContentRegistry 还不存在。把它做成注册表里的一份平衡资源即自指：要读它必须先合并 overlay，而要合并 overlay 必须先读它。

故建议明写一条准入：**一份平衡资源可以进 ContentRegistry，当且仅当它的全部消费点晚于 `LoadAll()`。**

逐条对照当前的管线旋钮表：

| 旋钮 | 消费点 | 能否进注册表 |
|---|---|---|
| overlay 下载重试次数 / 退避 | `CheckAndUpdateAsync`，**早于** `LoadAll()` | **不能**（处置见「仍需用户决定」第 4 题） |
| flags 拉取失败退避底数 / 因子 / cap | `RefreshFlagsAsync`，登录之后 ⇒ 晚于 `LoadAll()` | 能 |
| push 防抖窗口 / 断线缓冲上限 / push 退避五项 | sync-service，晚于 `LoadAll()` | 能 |
| 剧本预取深度 | plot-manager，轮回内 | 能 |
| 全部玩法平衡值 | 轮回内 | 能 |

**这条边界必须写下来，否则它会在实现期被一次「顺手也放进平衡资源」悄悄踩中**，而症状是启动死循环或一份永远读不到的配置。

## 具体形态（可 derive 的落地面）

```csharp
// —— 标记与读取面（content-service）——

/// 标记：该内容类型全库恰好一条。
public interface ISingletonContent { }

public interface IContentRegistry
{
    IContentRepository<T> Repo<T>() where T : Resource;

    /// 取该单例类型的唯一条目。条数不为 1 已在 LoadAll() 早失败，故本方法不返回 null、不需要 Try 形态。
    T Single<T>() where T : Resource, ISingletonContent;
}
```

| 方法 | 形态 | 完整签名 | 失败语义 |
|------|------|----------|----------|
| 取单例内容 | A | `T Single<T>() where T : Resource, ISingletonContent` | 条数 `!= 1` = 坏数据，**已在 `LoadAll()` 处 `PushError` + 抛**；本方法本身不会失败。对非单例类型调用 = **编译错误** |

**注册与 `Id`：**

| 类型 | `ISingletonContent` | `Id` | 基线路径 | 消费者 | 覆写纪律 |
|---|:--:|---|---|---|---|
| `CombatRulesData` | ✅ | `combat_rules.default` | `res://content/balance/combat_rules.tres` | combat-service | `EncounterSpec` 可空覆写 |
| `EnemyLevelingData` | ✅ | `enemy_leveling.default` | `res://content/balance/enemy_leveling.tres` | future-event-service（物化赋级） | **不接受任何覆盖参数** |
| `LocationMapData` | ✅ | `location_map.default` | `res://content/location/location_map.tres` | future-event-service（Travel 邻接） | — |

**加载期校验（合并后强校验内，全量，带类型名定位）：**

| 违规 | 处置 |
|---|---|
| 某 `ISingletonContent` 类型条目数 `!= 1` | `PushError` + 抛，带类型名与实际条数 |
| 某 `ISingletonContent` 条目 `ContentEnabled == false` | `PushError` + 抛，带类型名 |

**调用侧形态（示意）：**

```csharp
// combat-service：起手 / 抽牌 / 手牌上限，EncounterSpec 可空覆写
var rules   = Content.Single<CombatRulesData>();
int handCap = spec.HandLimit ?? rules.HandLimit;

// future-event-service：赋级带（不接受任何覆盖参数）
var band = Content.Single<EnemyLevelingData>().BandFor(chapter);
```

## 后果

- **`systems/services/content-service.md`：** 「统一操作接口」与「API 面（契约）」各加一行 `Single<T>()`；「结构性查表的内容类型恒启用」表追加 `ISingletonContent` 一行；新增一小节「单例内容的注册与校验」（`Id` 形态 · 条数校验 · 准入边界第 8 条）。
- **`systems/balance.md`：** 赋级带条目与 `CombatRulesData` 条目各补一句「它的注册形态见 content-service.md」；新增「平衡资源的切分三问判据」；「同步 / 内容管线旋钮」表标注哪一行**不进注册表**（overlay 下载重试 / 退避）。
- **`systems/game-progression.md`：** 图校验表里「`LocationMapData` 存在多份 / 零份」那一行改为回链到通用单例校验（**净减一条手写校验**）；`LocationMapData` 类定义加上 `ISingletonContent`。
- **`content/_index.md`：** 「不单开类型的两项 → 平衡数值」那条补一句澄清：**不建 `content/` 类型 ≠ 不进 ContentRegistry**（见「与既有决策的张力」）。
- **排期建议：** `ISingletonContent` + `Single<T>()` 是 `IContentRepository<T>` / 注册表面的**纯加法**改造，与已排期的 `DrawPool<T>` · `LocalizedText` 属同一次改动面，宜同批落在**第二阶段（内容）开工前、第一份 `.tres` 之前**。
- **无存档影响、不 bump schema**：单例平衡资源不进存档（存档只受它的数值间接影响），`ISingletonContent` 是代码侧标记、不进 `.tres`、不走 overlay。
- **无 FR 阻塞解除以外的玩法影响**：本方案不改任何数值、不改任何机制。

## 备选方案（已考虑并否决）

- **在各服务里 `ResourceLoader.Load` 直读平衡 `.tres`** —— 否决：绕开 overlay 覆盖层（平衡热更当场失效）、绕开合并后强校验、违反「不散落 `ResourceLoader.Load`」。
- **另开一个 `BalanceRegistry` / `balance-service`** —— 否决：给「唯一内容读取入口」开平行入口，且七服务的拆分判据（自有状态机 / 事务性一致写 / 外部 I/O）三条都套不上一份只读查表。
- **给单例开第二种仓储接口（砍掉 `AllEnabled()`）** —— 否决：打破「对外是同一形状」，换来的只是挡住一个无害且无人会写的调用（第 6 条）。
- **调用方写 `Repo<CombatRulesData>().Get(BalanceIds.CombatRules)`（`Id` 常量类）** —— 否决：把 `Id` 变成调用方可见的字符串键，与「`CapabilityFlag` 用 enum 不用字符串 key」同一条纪律相悖；且常量与 `.tres` 里的值仍可能不一致，而不一致的症状是运行期查不到。
- **单例识别改为「注册时声明」（`RegisterSingleton<T>()`）而非标记接口** —— 未否决，作为第 2 题的备选：它拿到同样的加载期校验，但**拿不到 `Single<T>()` 的编译期约束**（阶梯从第 2 级掉到第 3 级）。
- **把全部散落旋钮塞进一份 `GlobalBalanceData` 兜底大表** —— 倾向否决（第 3 题）：兜底表会成为默认倾倒处，而「哪些字段可被 `EncounterSpec` 覆写」随即退化为逐字段记忆——那正是「`EnemyLevelingData` 不并入 `CombatRulesData`」的否决理由。
- **单例 `Id` 用单段式（`combat_rules`，无 slug）** —— 未否决，作为第 1 题的备选。

## 与既有决策的张力

**两处，均为轻，且两处的建议都是「补一句澄清」而非「松动某条决策」——但两处都要动既有文档，故须由用户点头。**

1. **`content/_index.md`「平衡数值归 `systems/balance.md`，不是条目」 vs 本方案让平衡资源成为 ContentRegistry 里的正式条目。**
   - 冲突是**字面**的，不是实质的：那句话裁定的是「不为平衡数值单开一个 `content/<类型>/` 文件夹与类型档案」，理由是「填了什么值」的权威已经在 `balance.md` 逐表写着，开一份类型档案会制造第二权威——**这条理由本方案完全同意，不主张开张**。
   - 但读者按字面读会得出「平衡数值不是内容 ⇒ 不进 ContentRegistry」，而那与 ADR-0007 的「平衡表属本地内容层」正面矛盾。
   - **建议：** 在那一条后补一句「**不建 `content/` 类型 ≠ 不进 ContentRegistry**：平衡资源仍是 `.tres`、仍按 `Id` 进注册表、仍受合并后强校验，只是它的取值权威在 `systems/balance.md` 而非条目文档」。不改任何决定，只堵一个误读。
   → 已裁决（2026-08-22 · 批量评审）：按建议办 —— `content/_index.md` 补这一句澄清，不松动任何既定决策 `[采纳推荐 — 待复核]`

2. **`content-service.md`「内容按是否被存档引用分两类」表把「平衡表」列在**被存档引用**一栏，而存档里其实没有任何平衡表 `Id`。**
   - 该栏的实际作用是**决定 overlay 权限（只改不增）**，平衡表落在这一栏是**结论正确、理由标签不准**。
   - 风险很轻但真实：日后有人按字面去找「存档哪里引用了平衡表」，找不到就可能反推「那它是不是该归可新增 `Id` 的一类」——而平衡表**绝不可**由 overlay 新增（新增一份即触发第 5 条的条数校验，且闸 A 本就会拦）。
   - **建议：** 那张表加一个脚注——平衡表列于此栏的判据是「**必须只改不增**」，而非字面上被存档引用。
   → 已裁决（2026-08-22 · 批量评审）：按建议办 —— `content-service.md`「是否被存档引用」表加该脚注 `[采纳推荐 — 待复核]`

## 前置依赖

- **不阻塞。** 本方案的机制面（进注册表 · `Id` 形态 · 仓储 · 读取面 · 恒启用 · 条数校验 · 准入边界）全部可由既有决策推出，不依赖任何待答项。
- **完整的单例平衡资源清单依赖各旋钮的消费者定名**（多数归 ch1 数值标杆专场与各系统专场）。本方案只给切分三问判据与当前两份已定名资源；**清单本身不在本草稿范围内**，也不应在此臆造。
- **排期上与 `DrawPool<T>` / `LocalizedText` 同一个「纯加法窗口」**（第二阶段开工前、第一批 `.tres` 之前）。这是排期建议，不是阻塞——但窗口关闭后，改动会从「纯加法」退化为「改全部调用方」。

## 仍需用户决定 → **已全部裁决（2026-08-22 · 批量评审）**

> - **第 1 题 `Id` 形态** → **A · 两段式 `<类型>.default`（`combat_rules.default`）** `[采纳推荐 — 待复核]`
> - **第 2 题 单例身份声明** → **A · 标记接口 `ISingletonContent` + `Single<T>() where T : Resource, ISingletonContent`（编译期约束）** `[采纳推荐 — 待复核]`
> - **第 3 题 是否设兜底大表** → **A · 不设 `GlobalBalanceData`，按三问判据逐份切**。**正式拍板**（第 1 轮阻断题裁定，因它阻塞本批另外三道题），不是待复核。
> - **第 4 题 早于 `LoadAll()` 的旋钮** → **A · 写死为代码常量 + 在 `balance.md` 如实标注「不可线上调（消费点早于 `LoadAll()`）」** `[采纳推荐 — 待复核]`
> - **张力 1 / 张力 2** → 均按草稿建议「补一句澄清」采纳 `[采纳推荐 — 待复核]`（详见「与既有决策的张力」小节的裁决行）
>
> 四项。第 1 / 2 题会写进代码形态（改起来是全局重命名 / 改接口约束），第 3 / 4 题影响的是日后各旋钮怎么落。

1. **单例的 `Id` 形态：两段式 `combat_rules.default` 还是单段式 `combat_rules`？**（轻）
   - **A（推荐）：两段式 `<类型>.default`。** 理由：全库只保留一种 id 语法（「恰好一个点」可机械校验，`content/_index.md` 已定「各类型档案照抄本约定，不各自发明」）；日后某份资源真长出第二行时语法不必改。代价：`.default` 这一段当前不携带信息。
   - B：单段式 `combat_rules`。更短、更诚实地表达「只有一条」，但让 id 语法出现第二种形态，`/audit-content` 一类的机械核对要为它开一个例外分支。
   → 已裁决（2026-08-22 · 批量评审）：A · 两段式 `<类型>.default`（`combat_rules.default` / `enemy_leveling.default` / `location_map.default`） `[采纳推荐 — 待复核]`
2. **单例身份怎么声明：标记接口 `ISingletonContent`，还是注册时声明 `RegisterSingleton<T>()`？**（中）
   - **A（推荐）：标记接口 + `Single<T>() where T : ISingletonContent`。** 理由：拿到**编译期**约束（对 `CardData` 调 `Single<T>()` 编译不过），落在「纪律的可执行化」阶梯第 2 级；单例身份同时写在类型自己身上，读类定义即知。代价：`XxxData` 类多一个空接口。
   - B：注册时声明。加载期校验完全相同，但 `Single<T>()` 只能对全部 `Resource` 开放、误用要到运行期才炸（阶梯第 3 级）。少一个接口，多一个可能被漏声明的地方。
   → 已裁决（2026-08-22 · 批量评审）：A · 标记接口 `ISingletonContent` + `Single<T>() where T : Resource, ISingletonContent`（编译期约束） `[采纳推荐 — 待复核]`
3. **`balance.md` 里那些尚未定名的散落旋钮：现在就设一份 `GlobalBalanceData` 兜底大表，还是按三问判据逐份切、暂不设兜底？**（中）
   - **A（推荐）：不设兜底大表，按三问判据逐份切。** 理由：兜底表必然成为默认倾倒处，随后「哪些字段可被 `EncounterSpec` 一类覆写」退化为逐字段记忆——这正是 08-22 否决「`EnemyLevelingData` 并入 `CombatRulesData`」的理由。代价：短期内会出现若干份字段很少的小资源，且每份都要各自命名。
   - B：设一份兜底大表，凡「消费者唯一且不接受覆写」的全局单值先放进去（`TravelFullFanoutChance` / `MaxConcurrentSideArcs` 这类确实各自成表显得很碎）。少若干个文件，但要接受上述退化风险，并需要一条「什么时候该从大表里搬出来」的规则。
   → 已裁决（2026-08-22 · 批量评审）：A · **不设 `GlobalBalanceData` 兜底大表，按三问判据逐份切**。此项为**正式拍板**（第 1 轮阻断题 R1-2，因它阻塞本批另外三道题），**不带待复核**。
4. **消费点早于 `LoadAll()` 的旋钮（当前只有 `overlay 下载重试次数 / 退避 = 3 次 / 1s · 2s · 4s`）怎么落？**（轻）
   - **A（推荐）：写死为代码常量，并在 `balance.md` 那张表上如实标注「不可线上调（消费点早于 `LoadAll()`）」。** 理由：这三个数是稳态运维值、调它的收益远低于为它开一条平行配置通道的代价；如实标注比让它假装是可调平衡值更好。
   - B：放进一份随包 `res://` 直读的小资源（`ResourceLoader.Load` 一次，作为「不散落」纪律的显式单点例外）。可调性略好，但开了一个例外入口，且它仍不能被 overlay 覆盖（overlay 尚未合并），可调性其实是假的。
   - C：由后端 manifest 应答携带。真正可线上调，但让「下载 manifest 需要的重试参数」来自 manifest 自身，仍有一层自指，且给协议加字段。
   → 已裁决（2026-08-22 · 批量评审）：A · 写死为代码常量，并在 `balance.md` 那张表上如实标注「不可线上调（消费点早于 `LoadAll()`）」 `[采纳推荐 — 待复核]`
