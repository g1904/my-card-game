---
type: solution-draft
date: 2026-08-16
question: Travel 子类型的通用结算器数据形态——常规出场概率、80/20 是否可被剧本调制、换图后刷新多少/何种事件、Travel 自身的代价与风险，以及 location / locationMap 的数据载体与定名。
source: open-questions/03-adventure-event-types.md → 「各类型的结算 / 机制细化」的 Travel 一段 + 「location 机制细节」一条；另与 open-questions/02-event-options.md 的「Travel 的常规出场概率」「location 与 locationMap 的数据载体」两条同题
targets: systems/adventure-event/travel/_index.md · systems/adventure-event/travel/common-properties.md · systems/game-progression.md · systems/services/future-event-service.md · systems/balance.md · systems/character-profile/_index.md
status: distilled
reviewed: 2026-08-16 —— 三项取向按推荐裁定；提炼时另经 interview 推翻两处（Id 取两段式 `location.bamboo_sea`；LocationData / LocationMapData 改判为结构性查表类恒启用、flags 不生效）。
distilled-to: handoffs/2026-08-16g-travel-mechanics-and-location-carrier.md
decided: 2026-08-16 —— 三项取向与一处张力**全部按推荐裁定**（80/20 常规口径取截断式 · 不加分组字段 · Travel 定价显著低于常规事件）。全文已按裁定改写为单一方案，不再保留并列选项。
---

# 方案草稿 — Travel 专场：出场、代价、换图与 location 载体

## 问题

Travel 的**结构面已大量定案**（非常驻可选项 · 闸门时以 `eventPriority = 1` 收窄同批 · 候选走 80/20 掷定 · 不计入 `eventCountLimit` · 目的地取自 `locationMap` 邻接集合 · 图全局不变三章共用），但**五处仍悬着**，使 Travel 无法进入 derive：

1. **常规（非闸门）出场概率由什么给出**——location 的类型修正？固定值？
2. **80/20 比例是全局常量，还是可由 PlotManager 推拉**（剧本表达「迷途」）。
3. **一次 Travel 换图后刷新多少 / 何种事件**——新 location 的第一批是否有特殊规则。
4. **Travel 自身的代价 / 风险**——是否消耗资源、是否可能触发途中遭遇。
5. **location 与 `locationMap` 的数据载体与定名**——`LocationData : Resource`？枚举？图是单份邻接表还是各 location 持边？是否受 `AllEnabled()` 与 overlay 管辖？地域是否有枚举 / 层级？

第 5 项是其余四项与 `LocationCodex`、future-event-service 物化链路的共同前置，**建议先答它**。

## 约束（来自既有设计）

- **`locationMap` 全局不变、三章共用、对玩家不可见；存档只存当前 location 的 `Id`；启动加载一次常驻、服务只读不写。** 图的稳定性已被抬为**对玩家的隐性承诺**（改连边 = 清空一份账号级 `LocationCodex` 资产）。→ `systems/game-progression.md`、`systems/services/future-event-service.md`
- **一批只有一次操作：择一进入。批次规模常态 3、区间 1–5。整批重算，不承接上一批。** → `systems/adventure-event/common-properties.md`
- **`eventPriority` 取值域两档，置位方唯一 = future-event-service；PlotManager 只调内容不调约束**，剧本的强制性只能靠收窄候选池表达。→ 同上、`systems/services/future-event-service.md`
- **`selectCost` 无条件施加、付不起也照付、支付后判定状态**；成本侧 element 清单当前只有 `lifeSpanCost`。→ `systems/adventure-event/common-properties.md`
- **`lifeSpanCost` 定价表的行 = `eventType` 五类（Combat 按 `combatTier` 细分）、列 = ch1/ch2/ch3；内容条目默认不填。** 明写「Travel 不消耗配额但仍可有定价——表上给不给它一行是取值问题，不是形态问题」。→ `systems/balance.md`
- **`eventCountLimit` 只计「选择进入并结算」的事件，Travel 不计入**；它与 `lifeSpanCost` 是篇章节奏的两个互相约束的旋钮。→ `systems/game-progression.md`
- **内容条目通则：** `[GlobalClass] XxxData : Resource` + 稳定 `Id` + `ContentEnabled` + 静态展示文本用 `LocalizedText`；产出侧经 `AllEnabled()` 取池、读取侧 `Get(id)` 不过滤；坏数据启动期 `PushError`。→ `systems/common-properties.md`、`systems/services/content-service.md`、`.claude/rules/data-resource-rules.md`
- **`HiddenStatBandData` 的先例：** 「查表读取」类内容走全量视图、`ContentEnabled == false` → `PushError`；「产出侧抽取」类才经 `AllEnabled()`。→ `systems/services/plot-manager.md`
- **Explore 可遮罩 Travel，且揭示出的 Travel 必走随机那一档。** → `systems/adventure-event/explore/_index.md`
- **Finale 的出现条件 = 角色已达本境界巅峰，由 `eventPriority = 1` 表达**（不需要新机制）。**篇章继承 = 全部继承。** → `systems/game-progression.md`

## 建议方案

### 1. location 的数据载体 = `LocationData : Resource`，无枚举、无层级

`[既有推演]`

- **`[GlobalClass] public partial class LocationData : Resource`**，实例为 `.tres`，进 ContentRegistry 有自己的仓储。**不设 C# 枚举 `Location { ... }`。**
  理由是既有通则的直接推论：location 已被明写为「具备内容条目的形态——携带字段集合、由内容作者编写、被物化读取、应有稳定 `Id`、经 `ContentRegistry` 索引、受 `ContentEnabled` 与 overlay 热更管辖」。**枚举会把地域数焊进 C# 程序集**，与「新增一个地域 = 新增一个 `.tres`」的可加性、与 overlay 热更直接冲突，也与同族的 `AdventureEventData` / `EnemyData` / `HiddenStatBandData` 形态不一致。
- **`Id` 形态：** `location.<风味族>.<名>`，例 `location.wilds.bamboo_sea` · `location.market.cloudveil_fair` · `location.grotto.cold_spring`。与 `plot.band.faith.2` 的点分小写同构。
- **不引入区域 / 层级分组（已裁定）。** 待答项里的「地域的枚举 / 层级」——**层级目前没有承重消费方**：难度不由换图承载（由赋级带承载）、图三章不变、`LocationCodex` 记的是连边而非分组。**明写「本作 location 是平坦集合，无层级」**；**不预留 `RegionId` 一类的分组字段**——在有消费方之前它是一个无人读的字段，日后确需分组时加一个可空的纯风味字段即可，不改结构。

### 2. `locationMap` = **单份**邻接表资源 `LocationMapData`，不由各 location 持边

`[既有推演]` `[通行做法]`

**推荐单份资源**，三条理由：

- **对称性可机械保证。** 各 location 持边时，`A→B` 与 `B→A` 分写两处，漏写即出现单向边——而「图不变」是对玩家的隐性承诺，单向边会让 `LocationCodex` 重建出的图与实际路由不符，**能上线且线上不可见**。单份资源可在加载期一次性校验对称、无自环、无重复、无悬空 `Id`。
- **连通性校验需要全图视角。** 「某个 location 被 `ContentEnabled = false` 关掉后图是否仍连通」只能在拿到整张图时判定。
- **与既定工程形态一致**：「不挂在 Travel 内容条目上、不在运行时算、启动加载一次常驻内存」——一份资源就是这句话最直接的落地。

**图是无向的**（连边即双向可通行）。若日后确需单向通道，是给边加一个 `OneWay` 布尔，不改载体。

### 3. `ContentEnabled` 的管辖：location 经 `AllEnabled()`，图走全量视图

`[既有推演]`

严格照 content-service 的既定不对称 + `HiddenStatBandData` 先例分两侧：

| 对象 | 取池方式 | `ContentEnabled == false` 时 |
|---|---|---|
| **`LocationData`**（作为 Travel 目的地候选） | **经 `AllEnabled()`** —— 这是产出侧抽取 | 该地域不再作为目的地出场 |
| **`LocationData`**（存档里当前 location 的 `Id` 解析） | **`Get(id)` 不过滤** —— 读取侧 | 照常解析，轮回可继续 |
| **`LocationMapData`** | **全量视图，不经 `AllEnabled()`** —— 这是查表读取 | **`PushError`** —— 关掉图 = 全体玩家路由崩塌 |

**配套的加载期校验（关一个地域可能断图）：** 以 `AllEnabled()` 后的 location 集合为顶点、图为边，若出现**孤立顶点或不连通分量** → `PushError` 带上被隔离的 `Id` 清单。这是放量开关在本对象上的唯一真实风险，且**只能在加载期发现**。

### 4. 常规出场概率 = location 的 `EventTypeModifiers` 里的 Travel 一行，不设第二个机制

`[既有推演]`

Travel 是 `eventType` 五值之一，而 location 已携带**对候选池中各 `eventType` 的出现权重修正**（软框定）。**Travel 的常规出场因此不需要任何新字段**——它与其余四类走同一条加权抽取，「荒野常出 Travel（路多）、洞天罕出 Travel（深居）」由内容侧填该行表达。

**推论：Travel 的类型修正允许被修正到 0** = 该地域常规不出 Travel、只在配额闸门时出场（此时闸门路径不受类型修正影响，死局兜底仍然成立）。这同时给了「某个类型能否被修正到 0」那条待答项一个**在 Travel 上安全的正面答案**——因为 Travel 有闸门这条独立通道保底，修正到 0 不产生不可达。其余四类能否修正到 0 不在本草稿作用域内（见「前置依赖」）。

### 5. 80/20 落到批次时的口径细化：闸门批整批归 Travel，常规批按抽得的槽位数截断

`[既有推演（细化，非推翻）]` **· 已裁定**

**这里存在一个此前未被点明的机制冲突：** 80% 档要「列出全部邻接地域，各为一个并列选项」，而批次规模上限是 5。若某地域有 6 个邻接，闸门批次就会溢出。**裁定按下表收口**（保住「一律适用」这句既定措辞），**规则仍只有一条**（80% 给全部候选 / 20% 给一个），只是明确它落到批次时怎么占位：

| 场景 | 80% 档 | 20% 档 | 批次形状 |
|---|---|---|---|
| **配额闸门** | 全部邻接各一个选项 | seeded 随机一个 | **整批只有 Travel**，规模 = 邻接数（或 1） |
| **常规出场** | Travel 分得的槽位数 `k` 个目的地（从邻接集合按 map 子流抽 `k` 个） | 1 个 | Travel 占 `k` 个位，其余位给别的类型 |
| **Explore 揭示** | —— | 恒随机档，1 个 | 不占批次（进入即揭示即结算） |

**配套硬约束：`locationMap` 的最大出度 ≤ 5**，加载期超限 → `PushError` 带该 location 的 `Id` 与出度。理由：闸门批次规模 = 出度，而批次区间上限是 5；这条把「批次规模区间」从一句约定变成一条可机械校验的内容侧纪律。**副作用是正面的**——出度 ≤ 5 也让 `LocationCodex` 的连边词条在竖屏上一屏可读。

### 6. 80/20 **不可**被 PlotManager 调制（推荐全局常量）

`[既有推演]` + 一处需用户点头

- **依据：** PlotManager 的边界已定案为「**只调内容不调约束**——能影响哪些事件进池、以什么权重出现，但不能通过抬优先级强制玩家做某件事」。而 80/20 掷定改变的是**玩家的选择空间宽窄**（多个可选目的地 vs 一个被指定的目的地），这落在**约束面**，不是内容面。允许剧本推拉它，等于给 PlotManager 开了一条绕过既定边界的后门。
- **第二条依据（承重）：** `LocationCodex` 记连边 → 「提前两步规划路线」是**跨轮回知识的变现通道**，也是既定的设计目标。剧本若能悄悄把随机档拉高，这份积累会在玩家不知情时失效——而他连"被调过"都感知不到（隐藏属性只给方向不给数字）。
- **落地：** `TravelFullFanoutChance = 0.80` 住平衡资源（`systems/balance.md`），可线上调、**但只有一份全局值，不接受任何按剧情线 / location 的覆盖参数**——与 `±2` 带「赋级函数不接受任何区间覆盖参数」同款收口：不给这个口子，就不存在"谁有权用它"。
- **「迷途」仍可表达，换一条既有通道：** 让该剧情线的候选池多出 Explore 条目（Explore 遮罩的 Travel 必走随机档，见 `explore/_index.md`）——**这正是"剧本靠收窄候选池表达强制性"的标准用法**，不需要新旋钮。

### 7. Travel 的代价 = 既有 `lifeSpanCost` 定价表的 Travel 一行，取**非 0 的低值**；**不设途中遭遇**

`[既有推演]`

**（a）代价走既有通道，不新增机制。** 定价表的行本就是 `eventType` 五类，Travel 有它的一行；内容条目默认不填、取表值。

**（b）该行必须 > 0（结构性理由，不是数值偏好）。** 若 Travel 的 `lifeSpanCost` 为 0：
- Travel **不计入 `eventCountLimit`**，故配额闸门拦不住它；
- 换图 = 换 location 的类型修正 + **整批重算** ⇒ **零成本的事件池 reroll**；
- 于是「来回横跳直到刷出想要的事件」成为一条最优策略，而它恰好是本库反复否决的那类**可电子表格化优化**。

**寿元定价是唯一能拦住它的闸**（配额那道闸按定义对 Travel 不生效）。**取值严格为正，且显著低于常规事件基准——裁定的相对区间为常规事件的 1/3 ~ 1/2**（「赶路便宜，但不是免费的」）：换图的策略价值因此保住，reroll 漏洞被寿元堵死，而 20% 随机档也不至于显得亏（付的是小钱）。**绝对数字归 ch1 数值标杆专场**，但这条相对关系现在即成立，是内容侧的定价直觉。

**（c）不设途中遭遇。** 三条依据：
- **规则冲突：** 「一次选择仍只结算一个事件」「一批 = 一次操作 = 一次配额消耗」是承重定案；Travel 途中触发遭遇 = 一次选择结算两个事件，且该遭遇算不算配额、写几条 `PastEventEntry` 都要新增规则。
- **该语义已有承载者：** 「路上可能有事」正是 **Explore 遮罩 Travel** 的叙事（秘境把人带到别处），且已定案。再加一条途中遭遇是同一意图的第二套机制。
- **风险面已足：** Travel 的风险 = 付出寿元却可能走到一个更不利的地域（类型修正不合自己的 build、敌人池更凶）。**这已经是一次真实的风险决策**，且它由 `LocationCodex` 的知识积累化解——正是设计目标。

### 8. 换图后的第一批：**无特殊规则**，只是输入变了

`[既有推演]`

Travel 结算后的重算就是**一次普通的整批重算**（依角色整体历程 + 新 location 框定 + PlotManager 调制 + map 子流），数量照常常态 3 / 区间 1–5，类型配比照常由新 location 的 `EventTypeModifiers` 给出。**不需要「换图首批」这个概念**，也不需要为它新增字段——「一次选择 → 整批重算」是唯一的刷新形态，Travel 不是例外。

**唯一需要明写的是配额计数器的重置：**

- `CharacterProfile.Status.LocationEventCount`（int）——在当前 location 已结算的事件数。
- **非 Travel 事件结算 → `+1`；Travel 事件结算 → 归 `0`**（连同 `CurrentLocationId` 一并更新，落在 `eventEnd` 那**一次** `TryApply` 内）。
- 闸门判定 = `LocationEventCount >= 目标 location 的 EventCountLimit`，在**每一次整批重算**时求值（既定：没有第二个判定时点）。

### 9. Travel 与篇章 / 境界推进：**不耦合**

`[既有推演]`

- **篇章边界由 Finale 承载，不由 Travel 承载。** Finale 的出现条件已定为「角色已达本境界巅峰」并由 `eventPriority = 1` 表达——这是一条**等级条件**，与所在 location 无关。**建议明写：Finale 不绑定特定 location，不设「渡劫场」地域**；否则「必须先走到某地才能渡劫」会与经验曲线的「Finale 之前必须升满」形成两条互相牵制的进度闸，任一条卡住即卡死轮回。
- **篇章切换时当前 location 继承。** 「篇章继承 = 全部继承」+「三章共用同一张图」⇒ 下一篇章从上一篇章结束时所在的 location 继续，**不重置到起点**。这与「同一张图在三个篇章重走、敌人强度跟着角色走」完全同向，且不需要"起始地域"这个概念。
- **推论：`CurrentLocationId` 是跨篇章持久的存档字段**，不随 chapter 边界清零。

### 10. Travel 的 `pastEvent` 痕迹：`LocationId` 记**出发地**

`[既有推演]`

`PastEventEntry.LocationId` 的语义是「当时所在地域」。Travel 是唯一一类会在自己结算过程中改变该字段的事件，故须明写：**Travel 的痕迹记出发地**（与其余四类一致——都是"这一步发生在哪"），目的地由**下一条痕迹**的 `LocationId` 自然给出。这不新增字段，只是消除一处歧义；`LocationCodex` 的「去过即记」从痕迹序列读出的路径因此是连贯的。

## 具体形态（可 derive 的落地面）

```csharp
[GlobalClass]
public partial class LocationData : Resource
{
    [Export] public string        Id             { get; set; }   // "location.wilds.bamboo_sea"
    [Export] public LocalizedText DisplayName    { get; set; }
    [Export] public LocalizedText Description    { get; set; }   // LocationCodex 词条正文
    [Export] public EventTypeModifier[] EventTypeModifiers { get; set; } // 五类各一行，缺省 = 无修正
    [Export] public string[]      EnemyTemplateIds { get; set; } // 硬框定：该地域的 EnemyData 取池
    [Export] public int           EventCountLimit  { get; set; } // 硬闸门：该地域的事件容量上限
    [Export] public bool          ContentEnabled   { get; set; } = true;
}

[GlobalClass]
public partial class LocationMapData : Resource      // 单份；全局唯一
{
    [Export] public LocationEdge[] Edges { get; set; }   // 无向；A-B 只写一条
    [Export] public bool ContentEnabled { get; set; } = true;   // 恒 true，false → PushError
}

public sealed record LocationEdge(string FromId, string ToId);
// ⟨EventTypeModifier 的运算形态（乘性 / 加性 / 白名单+权重）不在本草稿作用域，见「前置依赖」⟩
```

**加载期校验（全部 `PushError` + 定位上下文）：**

| 违规 | 处置 |
|---|---|
| `LocationMapData` 存在多份 / 零份 | `PushError`（图是全局唯一对象） |
| 边引用了不存在的 `LocationData.Id` | `PushError` 带悬空 `Id` |
| 自环（`FromId == ToId`）、重复边 | `PushError` 带边两端 `Id` |
| 某 location 出度 **> 5** | `PushError` 带 `Id` + 出度（闸门批次会溢出批次规模上限） |
| 某 location 出度 **== 0**（孤立点） | `PushError`——进得去出不来，配额用尽即死锁 |
| `AllEnabled()` 后图不连通 | `PushError` 列出被隔离的 `Id` 集合 |
| `LocationMapData.ContentEnabled == false` | `PushError`（查表读取类，同 `HiddenStatBandData` 先例） |
| `EventCountLimit <= 0` | `PushError`（0 会让该地域一进入即触发闸门） |

**存档字段（`CharacterProfile.Status`）：**

| 字段 | 类型 | 语义 | 生命周期 |
|---|---|---|---|
| `CurrentLocationId` | `string` | 当前所在地域 | **跨篇章持久**，仅由 Travel 结算改写 |
| `LocationEventCount` | `int` | 当前地域已结算事件数（不计 Travel） | Travel 结算时归 0 |

**平衡资源新增一项：** `TravelFullFanoutChance = 0.80`（全局单值，无覆盖参数）。
**平衡表新增一行：** `lifeSpanCost` 定价表的 Travel 行，ch1/ch2/ch3 各一格，**取值 > 0 且低于常规事件基准**（数字归 ch1 数值标杆专场）。

**物化伪码（future-event-service，落在既有 `ComputeEventOptions` 内，不新增方法）：**

```
若 LocationEventCount >= 当前 location.EventCountLimit：
    掷 map 子流：< TravelFullFanoutChance ? 全部邻接 : seeded 取一个
    该批 = 这些邻接各物化一个 Travel EventOption，Priority = 1
否则：
    Travel 与其余四类一同按 location.EventTypeModifiers 加权抽取，得槽位数 k（k 可为 0）
    若 k > 0：掷 map 子流 → 80% 从邻接集合抽 k 个 / 20% 抽 1 个（此时该批 Travel 位数为 1）
    Priority = 0
邻接集合恒经 AllEnabled() 过滤
```

## 后果

- **文档：** `travel/_index.md`（出场 / 代价 / 闸门口径）· `travel/common-properties.md`（目的地字段与物化置位）· `game-progression.md`（location 载体、图校验、篇章不耦合、配额计数器）· `future-event-service.md`（物化伪码与 `AllEnabled()` 取池）· `balance.md`（`TravelFullFanoutChance` + 定价表 Travel 行）· `character-profile/_index.md`（两个存档字段）。
- **存档 schema：** 新增 `CurrentLocationId` + `LocationEventCount` 两个字段 ⇒ **bump 版本**；当前无线上存档 ⇒ **空迁移**，走既有 MigrationManager 骨架。
- **内容侧：** 新增两个内容类型（`LocationData` / `LocationMapData`），需走 `/scaffold-content-type` 开张（依赖类定义先落地）。出度 ≤ 5 与连通性成为内容作者的硬纪律。
- **连带解锁：** 02 分片的「location 与 `locationMap` 的数据载体」与「Travel 的常规出场概率」两条可一并移出；`LocationCodex` 的词条载体（`Description` + 连边）由此有了挂靠对象。
- **不影响：** `EventOption` 七字段骨架、`PastEventEntry` schema（`LocationId` 只是语义澄清）、`eventPriority` 两档语义、批次规模区间——**本方案不新增任何机制，只填数据形态与口径**。

## 备选方案（已考虑并否决）

- **location 用 C# 枚举 + 资源两件套** —— 否决：把地域数焊进程序集，新增地域必须发版，与 overlay 热更和内容可加性直接冲突；同族的三个 `XxxData` 无一如此。
- **各 location 持自己的出边** —— 否决：对称性无法机械保证，单向边会让 `LocationCodex` 重建的图与实际路由不符，且属"能上线、线上不可见"。
- **Travel 的 `lifeSpanCost` 取 0（赶路免费）** —— 否决：配额闸对 Travel 不生效，寿元是唯一的闸；取 0 即开出零成本的事件池 reroll，是一条可电子表格化的最优策略。
- **加一个 `TravelRisk` / 途中遭遇机制** —— 否决：与「一次选择只结算一个事件」冲突，且该语义已由 Explore 遮罩 Travel 承载。
- **允许 PlotManager 乘性偏移 80/20** —— 否决：越过「只调内容不调约束」的既定边界，且会让 `LocationCodex` 的跨轮回积累在玩家无感知处失效。
- **放宽批次规模上限以容纳高出度地域** —— 否决：批次规模 1–5 是竖屏横向滑动选择区的呈现约束，改它的代价远大于给图加一条出度上限。
- **常规出场恒走随机档（80/20 只在闸门生效）** —— 否决（取向 1）：更简单，但要改写两处文档里「一律适用」的既定措辞，而截断式口径不改任何措辞即可消除咬合。
- **现在就加可空 `RegionId` 分组字段** —— 否决（取向 2）：在有消费方之前是一个无人读的字段。
- **Travel 与常规事件同价** —— 否决（取向 3）：换图变成一次昂贵决策虽拉长地域停留，但会让 20% 随机档显得很亏（付了常规价却没得选）。

## 与既有决策的张力

**一处，属口径细化而非推翻 —— 已裁定取「截断式」，既定措辞保持不变：**

`travel/_index.md` 与 `game-progression.md` 都写着「**该掷定对常规出场与配额闸门一律适用**——规则只有一条，不按场景分叉」。本草稿第 5 项在**常规出场**场景下给 80% 档加了一层「受本批分得的槽位数 `k` 截断」的口径。

- **它没有制造第二条规则**：掷定本身仍是同一条（80% 给全部候选 / 20% 给一个），只是承认"批次规模上限"这个既有约束在常规场景下会咬合。
- **不加这层口径的后果**：一个 4 邻接的地域在常规批次里掷中 80% 档，就要摆 4 个 Travel + 其余类型 ⇒ 超出 1–5，或把常规批次挤成事实上的闸门批次（"想做别的却只能走"），后者直接违背「Travel 不是常驻可选项、闸门才收窄」。
- **替代口径（已否决）**：常规出场恒走随机档（1 个目的地），80/20 只在闸门生效。它更简单、与 Explore 揭示档同形，但**要改写 `travel/_index.md` 与 `game-progression.md` 里「一律适用」那句话**——为一处可用口径细化解决的咬合去动一条既定措辞，代价不划算。**裁定取截断式。**

## 前置依赖

- **`EventTypeModifier` 的运算形态**（乘性 / 加性 / 白名单+权重，能否修正到 0）未定 → 本草稿第 4 项只给出"Travel 走这条既有通道"和"Travel 这一行可为 0 是安全的"，**具体算子形态待该项答定**。→ `open-questions/02-event-options.md`
- **批次规模区间两端由什么驱动**（何时收到 1、何时放到 5）未定 → 第 5 项的槽位数 `k` 从何而来依赖它；出度 ≤ 5 这条校验不受影响（它只依赖上限 5 这个已定的数）。
- **`lifeSpanCost` 定价表的具体取值**归 ch1 数值标杆专场 → 第 7 项只给出「> 0 且低于常规事件基准」这条**结构性约束**，不填数字。
- **`LocationCodex` 记连边的显影粒度**（列全部邻接 vs 只记走过的边）未定 → 不阻塞本草稿（`LocationData.Description` 与 `LocationMapData` 两侧都已就位，两种粒度都读得出），但答定后会决定图鉴侧读哪一份。

## 仍需用户决定

**无 —— 三项取向已于 2026-08-16 全部按推荐裁定（见下），本草稿已是单一方案，可直接喂给 `/analyze-new-ideas`。**

### 已裁定的取向（3 项）

| # | 取向 | 裁定 | 理由 |
|---|------|------|------|
| 1 | 常规批次里 80% 档的口径 | **受槽位数截断** | 保住「规则只有一条、一律适用」这句既定措辞；替代口径要改写两处文档措辞，代价不划算。 |
| 2 | 是否预留 location 分组字段 | **不加** | 无承重消费方（难度不由换图承载、图三章不变、图鉴记连边不记分组）；日后加一个可空字段即可，不改结构。 |
| 3 | Travel 定价的相对位置 | **常规事件的 1/3 ~ 1/2** | 「赶路便宜但不免费」：换图的策略价值保住、reroll 漏洞被寿元堵死、20% 随机档不至于显得亏。绝对数字仍归 ch1 数值标杆专场。 |

> 裁定只落在这三处取向与那一处口径张力上；**前置依赖四条不受影响**，仍按上节所述留待各自的专场答定。
