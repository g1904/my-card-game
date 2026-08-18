# Travel 专场：出场、代价、换图与 location 载体

- id: 2026-08-16g-travel-mechanics-and-location-carrier
- date: 2026-08-16
- topic: systems/adventure-event/travel · systems/game-progression.md · systems/services/future-event-service.md · systems/services/content-service.md · systems/balance.md · systems/character-profile/_index.md · systems/adventure-event/common-properties.md · terminology.md · content/_index.md
- status: distilled
- distilled-to: `systems/adventure-event/travel/_index.md`、`systems/adventure-event/travel/common-properties.md`、`systems/game-progression.md`、`systems/services/future-event-service.md`、`systems/services/content-service.md`、`systems/balance.md`、`systems/character-profile/_index.md`、`systems/adventure-event/common-properties.md`、`terminology.md`、`content/_index.md`

## Intent（distilled）

**一句话：** Travel 的五处悬空全部落地——**载体是 `LocationData` + 单份 `LocationMapData`（两者恒启用，不参与放量）· 常规出场走 location 既有的类型修正 · 80/20 是全局常量且不可被剧本调制 · 代价走既有定价表且必须 > 0 · 不设途中遭遇 · 换图后无特殊规则**。**本次不新增任何机制，只填数据形态与口径。**

### 1. location 的数据载体 = `LocationData : Resource`，平坦集合、无枚举、无层级

- **`[GlobalClass] public partial class LocationData : Resource`**，实例为 `.tres`，进 ContentRegistry 有自己的仓储。**不设 C# 枚举 `Location { … }`**——枚举会把地域数焊进程序集，新增地域必须发版，与 overlay 热更和「新增一个地域 = 新增一个 `.tres`」的可加性冲突，也与同族的 `AdventureEventData` / `EnemyData` / `HiddenStatBandData` 形态不一致。
- **`Id` 形态照全库既定的两段式 `<内容类型>.<snake_case_slug>`：`location.bamboo_sea` · `location.cloudveil_fair` · `location.cold_spring`。** 不引入风味族中段。
- **本作 location 是平坦集合，无层级、无区域分组，也不预留分组字段。** 层级目前没有承重消费方：难度不由换图承载（由赋级带承载）、图三章不变、`LocationCodex` 记的是连边而非分组。日后确需分组时加一个可空的纯风味字段即可，不改结构。

### 2. `locationMap` = 单份邻接表资源 `LocationMapData`，不由各 location 持边

三条理由：

- **对称性可机械保证。** 各 location 持边时 `A→B` 与 `B→A` 分写两处，漏写即单向边；而「图不变」是对玩家的隐性承诺，单向边会让 `LocationCodex` 重建出的图与实际路由不符——属**能上线、线上不可见**。单份资源可在加载期一次性校验对称、无自环、无重复、无悬空 `Id`。
- **连通性校验需要全图视角。**
- **与既定工程形态一致**：「不挂在 Travel 内容条目上、不在运行时算、启动加载一次常驻内存」——一份资源就是这句话最直接的落地。

**图是无向的**（连边即双向可通行）。若日后确需单向通道，是给边加一个 `OneWay` 布尔，不改载体。

### 3. `LocationData` 与 `LocationMapData` 都是结构性查表类，恒启用

**两者的 `ContentEnabled == false` → 加载期 `PushError`；解析走 `AllIncludingDisabled()`；flags 第三层对它们不生效。**

判据是 `HiddenStatBandData` 先例的直接延伸，并对其一句话判据作一次必要细化：原判据「能被抽取的才配有开关」在 location 上不够用——**location 有双重身份：既是 Travel 的目的地候选（看似产出侧），又是 `locationMap` 的结构顶点**。**结构身份优先**，两条理由：

- 关掉一个顶点 = 改图，而图的稳定性已升格为对玩家的隐性承诺（改连边 = 清空一份账号级 `LocationCodex` 资产）。
- flags 是**按账号解析、轮回中途可热应用、且不参与合并后强校验**的通道。若 location 参与 flags 过滤，线上关掉若干地域可使某玩家当前 location 的邻接集合为空 ⇒ 配额闸门时产不出任何 Travel ⇒ **轮回死锁**，而 Travel 恰恰是既定的死局兜底。这条风险**加载期校验够不着**。

**代价如实记下：失去「线上秒关一个问题地域」的运营手段**——地域出问题只能改 overlay、下次冷启动生效。这是为「图恒连通、Travel 恒可产出」付的价。

### 4. 常规出场概率 = location 的事件类型修正里的 Travel 一行，不设第二个机制

Travel 是 `eventType` 五值之一，而 location 已携带**对候选池中各 `eventType` 的出现权重修正**（软框定）。**Travel 的常规出场因此不需要任何新字段**——它与其余四类走同一条加权抽取，「荒野常出 Travel（路多）、洞天罕出 Travel（深居）」由内容侧填该行表达。

**推论：Travel 的类型修正允许被修正到 0** = 该地域常规不出 Travel、只在配额闸门时出场（闸门路径不受类型修正影响，死局兜底仍成立）。这给了「某个类型能否被修正到 0」那条待答项一个**在 Travel 上安全的正面答案**；其余四类不在本次作用域。

### 5. 80/20 落到批次的口径：闸门批整批归 Travel，常规批按抽得的槽位数截断

80% 档要「列出全部邻接各为一个并列选项」，而批次规模上限是 5——**规则仍只有一条**（80% 给全部候选 / 20% 给一个），本次只明确它落到批次时怎么占位：

| 场景 | 80% 档 | 20% 档 | 批次形状 |
|---|---|---|---|
| **配额闸门** | 全部邻接各一个选项 | seeded 随机一个 | **整批只有 Travel**，规模 = 邻接数（或 1） |
| **常规出场** | Travel 分得的槽位数 `k` 个目的地（从邻接集合按 map 子流抽 `k` 个） | 1 个 | Travel 占 `k` 个位，其余位给别的类型 |
| **Explore 揭示** | —— | 恒随机档，1 个 | 不占批次（进入即揭示即结算） |

**配套硬约束：`locationMap` 的最大出度 ≤ 5**，加载期超限 → `PushError` 带该 location 的 `Id` 与出度。闸门批次规模 = 出度，而批次区间上限是 5；这条把「批次规模区间」从一句约定变成一条可机械校验的内容侧纪律。**副作用是正面的**——出度 ≤ 5 也让 `LocationCodex` 的连边词条在竖屏上一屏可读。

### 6. 80/20 不可被 PlotManager 调制

- **依据：** PlotManager 的边界是「只调内容不调约束」。80/20 掷定改变的是**玩家的选择空间宽窄**（多个可选目的地 vs 一个被指定的目的地），这落在**约束面**。允许剧本推拉它，等于给 PlotManager 开一条绕过既定边界的后门。
- **第二条依据（承重）：** `LocationCodex` 记连边 ⇒ 「提前两步规划路线」是跨轮回知识的变现通道，也是既定设计目标。剧本若能悄悄把随机档拉高，这份积累会在玩家不知情时失效——而他连「被调过」都感知不到。
- **落地：** `TravelFullFanoutChance = 0.80` 住平衡资源，可线上调，**但只有一份全局值、不接受任何按剧情线 / location 的覆盖参数**——与「赋级函数不接受任何区间覆盖参数」同款收口：不给这个口子，就不存在「谁有权用它」。
- **「迷途」仍可表达，换一条既有通道：** 让该剧情线的候选池多出 Explore 条目（Explore 遮罩的 Travel 必走随机档）——这正是「剧本靠收窄候选池表达强制性」的标准用法。

### 7. Travel 的代价 = 定价表的 Travel 一行，取非 0 的低值；不设途中遭遇

**（a）代价走既有通道，不新增机制。** 定价表的行本就是 `eventType` 五类，Travel 有它的一行；内容条目默认不填、取表值。

**（b）该行必须 > 0（结构性理由，不是数值偏好）。** 若 Travel 的 `lifeSpanCost` 为 0：Travel 不计入 `eventCountLimit`（配额闸拦不住它）+ 换图 = 换类型修正 + 整批重算 ⇒ **零成本的事件池 reroll**，「来回横跳直到刷出想要的事件」成为最优策略，而它恰是本库反复否决的那类可电子表格化优化。**寿元定价是唯一能拦住它的闸。**

**取值严格为正，且显著低于常规事件基准——相对区间为常规事件的 1/3 ~ 1/2**（「赶路便宜，但不是免费的」）：换图的策略价值保住，reroll 漏洞被寿元堵死，20% 随机档也不至于显得亏。绝对数字归 ch1 数值标杆专场。

**（c）不设途中遭遇。** 三条依据：与「一次选择只结算一个事件 / 一批 = 一次操作 = 一次配额消耗」直接冲突；「路上可能有事」这一语义已由 **Explore 遮罩 Travel** 承载；Travel 的风险面已足——付出寿元却可能走到一个更不利的地域（类型修正不合自己的 build、敌人池更凶），且它由 `LocationCodex` 的知识积累化解，正是设计目标。

### 8. 换图后的第一批：无特殊规则，只是输入变了

Travel 结算后的重算就是**一次普通的整批重算**（依角色整体历程 + 新 location 框定 + PlotManager 调制 + map 子流），数量照常常态 3 / 区间 1–5，类型配比照常由新 location 的类型修正给出。**不需要「换图首批」这个概念。**

唯一需要明写的是配额计数器：

- `CharacterProfile.Status.LocationEventCount`（int）——在当前 location 已结算的事件数。
- **非 Travel 事件结算 → `+1`；Travel 事件结算 → 归 `0`**（连同 `CurrentLocationId` 一并更新，落在 `eventEnd` 那**一次** `TryApply` 内）。**归 0 恒成立，包括由 Explore 揭示而来的 Travel**——该 Explore 的 `+1` 随即被归 0 覆盖，因为计数的语义是「在这个地域做了几件事」，换了地域即作废。
- 闸门判定 = `LocationEventCount >= 当前 location 的 EventCountLimit`，在**每一次整批重算**时求值。

### 9. Travel 与篇章 / 境界推进：不耦合

- **篇章边界由 Finale 承载，不由 Travel 承载。** Finale 的出现条件是「角色已达本境界巅峰」，是一条**等级条件**，与所在 location 无关。**Finale 不绑定特定 location，不设「渡劫场」地域**——否则「必须先走到某地才能渡劫」会与「Finale 之前必须升满」形成两条互相牵制的进度闸，任一条卡住即卡死轮回。
- **篇章切换时当前 location 继承。** 「篇章继承 = 全部继承」+「三章共用同一张图」⇒ 下一篇章从上一篇章结束时所在的 location 继续，不重置到起点，也不需要「起始地域」这个概念。
- **推论：`CurrentLocationId` 是跨篇章持久的存档字段**，不随 chapter 边界清零。

### 10. Travel 的 `pastEvent` 痕迹：`LocationId` 记出发地

`PastEventEntry.LocationId` 的语义是「当时所在地域」。Travel 是唯一一类会在自己结算过程中改变该字段的事件，故**Travel 的痕迹记出发地**（与其余四类一致——都是「这一步发生在哪」），目的地由**下一条痕迹**的 `LocationId` 自然给出。不新增字段，只消除一处歧义；`LocationCodex` 从痕迹序列读出的路径因此是连贯的。

### 具体形态

```csharp
[GlobalClass]
public partial class LocationData : Resource
{
    [Export] public string        Id             { get; set; }   // "location.bamboo_sea"
    [Export] public LocalizedText DisplayName    { get; set; }
    [Export] public LocalizedText Description    { get; set; }   // LocationCodex 词条正文
    [Export] public EventTypeModifierData[] EventTypeModifiers { get; set; } // 五类各一行，缺省 = 无修正
    [Export] public string[]      EnemyTemplateIds { get; set; } // 硬框定：该地域的 EnemyData 取池
    [Export] public int           EventCountLimit  { get; set; } // 硬闸门：该地域的事件容量上限
    [Export] public bool          ContentEnabled   { get; set; } = true;   // 恒 true，false → PushError
}

[GlobalClass]
public partial class LocationMapData : Resource      // 单份；全局唯一
{
    [Export] public LocationEdgeData[] Edges { get; set; }   // 无向；A-B 只写一条
    [Export] public bool ContentEnabled { get; set; } = true;   // 恒 true，false → PushError
}

[GlobalClass]
public partial class LocationEdgeData : Resource
{
    [Export] public string FromId { get; set; }
    [Export] public string ToId   { get; set; }
}
// ⟨EventTypeModifierData 的运算形态（乘性 / 加性 / 白名单+权重）不在本次作用域，见「前置依赖」⟩
```

**内嵌类型是 `Resource` 而非 `record`：** `[Export]` 只接受 Variant 兼容类型与 `Resource` 派生；`EventOption` / `PastEventEntry` 那类**不导出**的运行时定稿实例照旧用 `sealed record`，两条路不冲突。

**加载期校验（全部 `PushError` + 定位上下文）：**

| 违规 | 处置 |
|---|---|
| `LocationMapData` 存在多份 / 零份 | `PushError`（图是全局唯一对象） |
| 边引用了不存在的 `LocationData.Id` | `PushError` 带悬空 `Id` |
| 自环（`FromId == ToId`）、重复边 | `PushError` 带边两端 `Id` |
| 某 location 出度 **> 5** | `PushError` 带 `Id` + 出度（闸门批次会溢出批次规模上限） |
| 某 location 出度 **== 0**（孤立点） | `PushError`——进得去出不来，配额用尽即死锁 |
| 图不连通 | `PushError` 列出被隔离的 `Id` 集合 |
| `LocationData` / `LocationMapData` 的 `ContentEnabled == false` | `PushError`（结构性查表类恒启用） |
| `EventCountLimit <= 0` | `PushError`（0 会让该地域一进入即触发闸门） |

**存档字段（`CharacterProfile.Status`）：**

| 字段 | 类型 | 语义 | 生命周期 |
|---|---|---|---|
| `CurrentLocationId` | `string` | 当前所在地域 | **跨篇章持久**，仅由 Travel 结算改写 |
| `LocationEventCount` | `int` | 当前地域已结算事件数（不计 Travel） | Travel 结算时归 0 |

**平衡资源新增一项：** `TravelFullFanoutChance = 0.80`（全局单值，无覆盖参数）。
**平衡表新增一行：** `lifeSpanCost` 定价表的 Travel 行，ch1/ch2/ch3 各一格，取值 > 0 且为常规事件基准的 1/3 ~ 1/2。

**物化伪码（future-event-service，落在既有 `ComputeEventOptions` 内，不新增方法）：**

```
若 LocationEventCount >= 当前 location.EventCountLimit：
    掷 map 子流：< TravelFullFanoutChance ? 全部邻接 : seeded 取一个
    该批 = 这些邻接各物化一个 Travel EventOption，Priority = 1
否则：
    Travel 与其余四类一同按 location 的类型修正加权抽取，得槽位数 k（k 可为 0）
    若 k > 0：掷 map 子流 → 80% 从邻接集合抽 min(k, 邻接数) 个 / 20% 抽 1 个
    Priority = 0
邻接集合取自全量图（location 恒启用，不经 AllEnabled() 过滤）
```

## Clarifications（interview 产物）

| # | 问题 | 用户裁决 | 它改了原始输入的哪一句 |
|---|------|---------|---------------------|
| 1 | location 的 `Id` 取三段式（`location.wilds.bamboo_sea`）还是全库既定的两段式？ | **两段式 `location.bamboo_sea`** | 推翻草稿第 1 节的 `location.<风味族>.<名>`。理由：`content/_index.md` 的 id 约定明写「不各自发明」且举例即 `location.yunmeng_marsh`；三段式的中段本身就是一种分组，与同节「不引入分组、平坦集合」的裁定自相矛盾。草稿援引的 `plot.band.faith.2` 是一处既有偏差，不构成先例授权（留作后续收口，不在本次作用域）。 |
| 2 | `LocationData` 的 `ContentEnabled` 归产出侧抽取（经 `AllEnabled()`）还是结构性查表（恒启用）？ | **结构性查表类，恒启用；flags 不生效** | 推翻草稿第 3 节的整张分派表与「`AllEnabled()` 后图不连通 → `PushError`」。理由：flags 通道按账号解析、轮回中途热应用且不参与合并后强校验，加载期连通性校验够不着它；线上关地域可使某玩家的邻接集合为空 ⇒ 闸门产不出 Travel ⇒ 轮回死锁，而 Travel 是既定的死局兜底。连带：`content-service.md` 的判据「能被抽取的才配有开关」细化为「结构顶点身份优先于抽取身份」。 |

**另有两处按既定语义径直修正，未占用提问额度：**

- 草稿第 8 节写「闸门判定 = `LocationEventCount >=` **目标** location 的 `EventCountLimit`」，与同节伪码及既有的闸门语义相左 ⇒ 取**当前** location。
- 草稿的 `public sealed record LocationEdge(...)` 被 `[Export]` 引用，而 Godot 只导出 Variant 兼容类型与 `Resource` 派生 ⇒ 改为 `[GlobalClass] LocationEdgeData : Resource`。

## Open questions

- **`EventTypeModifierData` 的运算形态**（乘性 / 加性 / 白名单+权重，能否修正到 0）——本次只定「Travel 走这条既有通道」与「Travel 这一行可为 0 是安全的」，算子形态待该项答定。
- **批次规模区间两端由什么驱动**（何时收到 1、何时放到 5）——第 5 项的槽位数 `k` 从何而来依赖它；出度 ≤ 5 这条校验不受影响（只依赖上限 5 这个已定的数）。
- **`lifeSpanCost` 定价表的具体取值**——归 ch1 数值标杆专场；本次只给「> 0 且为常规事件基准的 1/3 ~ 1/2」这条结构性约束。
- **`LocationCodex` 记连边的显影粒度**（列全部邻接 vs 只记走过的边）——不阻塞本次（`Description` 与 `LocationMapData` 两侧都已就位），但答定后会决定图鉴侧读哪一份。
- **失去 flags 关地域后的运营替代**——若日后确有「线上必须立刻停用某地域」的需求，需另设一条不改图的通道（例：把该地域的 `EventCountLimit` 压到 1 让人快速离开），本次不预设形态。
