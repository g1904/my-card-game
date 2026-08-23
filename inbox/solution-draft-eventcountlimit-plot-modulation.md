---
type: solution-draft
date: 2026-08-22
question: `eventCountLimit`（地域事件容量上限）能否被 PlotManager / AdventurePlot 推拉？
source: open-questions/02-event-options.md → 「`eventCountLimit` 能否被剧本调制（08-05b 收窄）」
targets: systems/game-progression.md · systems/services/plot-manager.md · systems/services/future-event-service.md · systems/balance.md
status: distilled
reviewed: 2026-08-22 —— 主问按主推荐 A0 定案（`eventCountLimit` 不可调制，`PlotModulation` 不加第七字段）；「不可调制」只约束剧本层，overlay 照常可改（`[采纳推荐 — 待复核]`）。
distilled-to: handoffs/2026-08-22-eventcountlimit-plot-modulation.md
---

# 方案草稿 — `eventCountLimit` 能否被剧本调制

## 问题

`eventCountLimit` 是 `LocationData` 上的**硬闸门**字段：玩家在该地域最多经历几个事件，用尽即本批 eventOptions 整批收窄为 Travel（`Priority = 1`）。

**已定案的那一半**（不在本草稿的裁决范围内）：
- **计数口径** —— 只计「选择进入并结算」的事件，**Travel 不计入**；承载字段 `CharacterProfile.Status.LocationEventCount`（非 Travel 结算 `+1`、Travel 结算归 `0`，落在 `eventEnd` 那一次 `TryApply` 内）。
- **判定时点** —— `LocationEventCount >= 当前 location.EventCountLimit`，在**每一次整批重算**时求值，没有第二个判定时点。
- **具体取值** —— 各 location 填多少、一章途经几个地域，归内容制作阶段 / ch1 数值标杆专场。

**仍悬着的那一半，也就是本草稿要答的**：配额本身能否被 PlotManager 推拉？即 `PlotModulation` 是否要长出**第七个字段**去改这个数。

它卡住的东西：`plot-manager.md` 的合并算子表与「权力面逐条投影」表在**没有这条结论之前无法宣告闭合**（该表目前明写「抬 `eventPriority` → 无字段」「改模板字段 → 无字段」，但没有为 `eventCountLimit` 写过任何一行）；`game-progression.md` 的待决问题小节因此挂着一条，而它是 `open-questions.md` 里把该文档判为 `blocked` 的五条之一。

## 约束（来自既有设计）

- **`PlotModulation` 的字段面已有一条闭合判据**（`systems/services/plot-manager.md`）：
  > 新增一格物化字段时是否跟着加一格，只看它落在哪一面：落**内容面**（哪些条目进池、以什么权重出现、用哪个敌人池、带内赋级权重、遭遇参数）→ **已有字段够用**；落**约束面或模板字段面** → **不加字段**。
- **「PlotManager 只调内容不调约束」是承重边界**（`systems/services/future-event-service.md`）：`eventPriority` 的**置位方唯一 = future-event-service**；剧本的强制性只能靠**把候选池收窄**（`EventWhitelist`）表达。
- **抬升判据的子判据 (b)**（同上，与门三条之一）：收窄条件必须**由产出侧可确定判定**（配额计数 · 篇章 · `pastEvent` · 角色等级），**不读隐藏属性、不读剧本状态**。三条准入抬升的第一条正是 **配额闸门 Travel**，判定式 `Status.LocationEventCount >= location.EventCountLimit`。
- **两条同族旋钮已明写拒绝剧本覆盖**：`TravelFullFanoutChance = 0.80` —— 「**PlotManager 不得推拉它**，它改的是玩家选择空间的宽窄，落在约束面」；`BatchSizeWeights` —— 「**不接受任何覆盖参数**（与 `TravelFullFanoutChance` 同款收口）：批次规模改的是玩家选择空间的宽窄、落在约束面」（`systems/balance.md`、`future-event-service.md`）。
- **`eventCountLimit` 与 `lifeSpanCost` 是篇章节奏的两个旋钮，必须一同反推目标时长**（`systems/balance.md`）：`lifeSpanCost` 定「每个事件多贵」、`eventCountLimit` 序列定「一共能做几个」，各调各的会互相抵消。目标时长 30–40 / 35–45 / 45–55 分钟（熟练玩家口径）。
- **经验反推链明写是脆的**：「事件总数一变（`eventCountLimit` 调整、`lifeSpanCost` 重定价），整条阈值曲线跟着失效」，且有一条硬验收项——「按标准路线走能在预算内升满」（`systems/balance.md`、`systems/game-progression.md`）。
- **location 是结构性内容、恒启用**，`ContentEnabled` 与 flags 对它不生效；加载期已有 `EventCountLimit <= 0 → PushError`（`systems/game-progression.md`）。
- **`LocationCodex` 记连边、跨轮回重建整张图是设计目标**，「图的稳定性从设计选择升格为对玩家的隐性承诺」；该词条还有一条待答项明确把 `eventCountLimit` 列为候选词条内容（`systems/player-profile/codex/_index.md`）。
- **同族拒绝的先例还有一条在成本侧**：`SelectCost` 在权力面表上无字段——「成本侧、隔着遮罩改定价等于动全局时长旋钮」。

## 建议方案

### 主张：**不可调制** —— `PlotModulation` 不长第七个字段，`eventCountLimit` 恒为内容侧定值
`[既有推演]`

**建议在 `plot-manager.md` 的权力面投影表里补一行，与既有的两条「无字段」并列：**

| 既定权力 | 承载字段 |
|---|---|
| … | … |
| 改 `eventCountLimit` / 地域配额 | **无字段**——落约束面，写不出来 |

**并建议在 `game-progression.md` 的 `eventCountLimit` 小节补一句正面表述：**「配额是**内容侧定值**，只由 `LocationData` 的该格与 overlay 决定；**PlotManager 无字段可推拉它**——它是硬闸门，落约束面（判据见 `systems/services/plot-manager.md`）。」

五条依据，第 ② 条最硬：

**① 判据直接判给约束面。** `eventCountLimit` 在 `game-progression.md` 的字段表里被明写为**硬（计数闸门）**，与同表的类型修正**软（改权重，不改可及性）**成对照。既有判据的内容面清单（哪些条目进池 / 以什么权重出现 / 用哪个敌人池 / 带内赋级权重 / 遭遇参数）**没有一格覆盖它**——它决定的不是「摆什么」，而是「还能摆几批」。落约束面 ⇒ 不加字段。**这条判据存在的全部目的就是让字段面不必随物化清单每次增长再逐格复核**，本题正是它的第一个真实用例。

**② 开放即打穿抬升判据 (b)，PlotManager 由此获得抬 `Priority = 1` 的间接能力。** 配额闸门 Travel 是三条准入抬升的第一条，它能通过 (b) 的**唯一理由**是判定式只读一个计数器。若 arc 能推拉 `EventCountLimit`，闸门的触发时点就变成**剧本状态的函数** ⇒ 一条煞气 arc 把某地域的配额压到 1，即可在下一批把玩家整批锁进 `Priority = 1` 的 Travel。这不是「调内容」，这是**借道内容字段完成一次约束置位**——而 (b) 存在的价值被明写为「把『PlotManager 只调内容不调约束』从一句纪律变成一条可机械核对的准入条件」。**开放这个字段，(b) 当场退化为一句纪律。**

**③ 三个相邻旋钮不能有两套纪律。** `TravelFullFanoutChance`（去哪能选几个）、`BatchSizeWeights`（一批摆几个）、`eventCountLimit`（这个地域还能选几批）是同一族——都定**玩家选择空间的形状**，前两者已各自明写「不得推拉 / 不接受覆盖参数」，且理由逐字相同（「改的是玩家选择空间的宽窄，落在约束面」）。第三个单独开口，等于让三个挨着的旋钮走两套纪律，而这类不对称正是本库反复点名的漂移源。

**④ 它会把时长旋钮的反推变成不可算的量。** `eventCountLimit` 与 `lifeSpanCost` 是**必须一同反推**目标时长的两个旋钮，且经验曲线的验收项（「按标准路线能在预算内升满」）直接建立在「一章事件总数」之上。让配额成为隐藏属性 / 剧本进度的函数 ⇒ 事件总数成为**玩家不可见、设计侧不可枚举**的分布：反推只能按期望值算并接受方差，而**旋钮精度正是这两张表存在的唯一理由**（`lifeSpanCost` 定价表拒绝区间列用的就是这条理由，逐字适用）。更糟的是方差落在**隐藏**维度上——玩家察觉不到，只会觉得「这一局怎么这么长 / 这么短」。

**⑤ 想要的效果已有更便宜的表达位，且没有一个需要新字段**（见下节）。**内容侧定值本就能表达「这个地域待得短」**——那是 `LocationData` 那一格的本职；剧本层再开一格是把同一件事做两遍。

### 替代通道：剧本仍能影响地域节奏，只是**只能加速离开、不能延长停留**
`[既有推演]`

| 剧本想表达 | 已有的表达位 | 形态 |
|---|---|---|
| 「这条线催着你赶路」 | `TypeWeights[Travel]` 抬高 | **软**：Travel 更常出现在常规批，玩家可选择提前走 ⇒ `LocationEventCount` 归 0，实际停留被缩短 |
| 「这一段只出这条线的事件」 | `EventWhitelist` | 既定的**唯一**剧本强制表达位 |
| 「这地方待久了越来越凶」 | `LevelBias` / `EnemyPoolScope` / `Tighten` | 压力升级，不动配额 |
| 「这个地域本来就待不久」 | `LocationData.EventCountLimit` 定值 | 内容阶段编排，与本题无关 |
| 「运营上要让人快点离开某个问题地域」 | 同上，走 overlay 改定值 | 见「仍需用户决定」第 3 条 |

**不对称是有意的，也是这条方案的正面价值**：剧本可以**加速离开**（软，最终由玩家点下去），**不能延长停留**（硬上限是对时长预算的承诺）。`TypeWeights` 恒 `> 0`、剧本侧不设 Travel 例外，故这条通道也无法被反用来把 Travel 压没。

### 落地面：零结构增量
`[既有推演]`

- **不新增字段 / 枚举 / 合并算子行 / 加载期校验；不 bump 存档 schema；不动 `LocationEventCount` 的任何语义。**
- 十步管线、闸门伪码、三条抬升条件、`PlotModulation` 六字段与合并算子表**逐字不动**。
- `game-progression.md` 与 `plot-manager.md` 各加一句 / 一行明写（防止日后被逐条加回，同「明确被否决的抬升候选」那张表的用法）。

## 具体形态（可 derive 的落地面）

采纳「不可调制」时，可被 `/derive-requirements` 消费的形态只有三条**文字纪律**，无字段：

| # | 落点 | 内容 |
|---|---|---|
| 1 | `systems/services/plot-manager.md`「权力面逐条投影」表 | 新增一行：`改 eventCountLimit / 地域配额` → **无字段**（落约束面） |
| 2 | `systems/game-progression.md` `eventCountLimit` 小节 | 一句正面表述：配额恒为内容侧定值，PlotManager 无字段可推拉 |
| 3 | `systems/services/future-event-service.md`「明确被否决的抬升候选」表 | 可选：补一行「**经推拉 `EventCountLimit` 间接抬升**」→ 被 **(b)** 拒 |

**校验形态：无新增。** 这条纪律与 `eventPriority` 同款——「内容作者根本写不出那个字段」，故**不需要任何运行期检查**（`plot-manager.md` 明写：这是剧本数据面做到可执行化阶梯第 1 级的地方）。

## 后果

- **影响文档**：`systems/game-progression.md`（移除待决问题一条 + 意图侧补一句）· `systems/services/plot-manager.md`（权力面表 +1 行）· `systems/services/future-event-service.md`（否决候选表 +1 行，可选）· `systems/balance.md`（可在 `eventCountLimit` 那条补一句「恒为定值 ⇒ 一章事件总数可枚举，反推可算」）。
- **待答清单**：`open-questions/02-event-options.md` 移出该条；`open-questions.md` 中 `systems/game-progression.md` 的 `blocked` 理由减少一条（**仍 blocked**，其余四条未答）。
- **存档 / 迁移**：无。`LocationEventCount`、`CurrentLocationId`、`PlotKeyPoint` 全部不变。
- **对内容制作的影响**：各 location 的 `EventCountLimit` 取值与「一章途经几个地域」照旧归 ch1 数值标杆专场，且**因为恒为定值，那次反推是一个可枚举的算术问题**而不是分布问题。
- **失去的能力（如实记）**：剧本无法表达「因为你煞气重，这片林子把你困住了，得多走几步才出得去」这类**硬性延长**的叙事。它只能被软化为「这一段更凶 + 更容易出现某类事件」。

## 备选方案（已考虑；完整形态列出以供比较，最终由用户裁决）

> 这两条**不是拍板否决**，是「若用户要开放，形态应该长这样」的完整答案——本草稿的主张是 A0（不开放），但代价差必须能被并排读到。

### 备选 A · 双向可调（完整第七字段形态）

**① 字段形态**

```csharp
// 追加到 PlotModulation（第七格）
[Export] public int EventCountLimitDelta { get; set; } = 0;   // 中性值 0 = 不参与
```

- **取加性 `Delta` 而非乘性系数**：这一格是**整数计数**（`EventCountLimit` 是 `int`，典型个位数），乘性系数会立刻引出「向上还是向下取整」，且 `0.5 × 3` 与 `0.5 × 8` 的手感完全不同。**它与 `LevelBias` 同类**（同为整数偏移、同为「在既定结构上挪一格」），故沿用 `LevelBias` 的加性语言，而非 `TypeWeights` / `EventWeights` 的乘性语言。
- **中性值 = 0**（加性恒等元），与 `LevelBias` 的缺省一致。

**② 合并算子（补进那张已定死的表）**

| 字段 | 合并算子 | 缺省（= 不参与） |
|---|---|---|
| `EventCountLimitDelta` | **相加**（Σ 各 `Active` arc），**合并后再一次性 Clamp** | 0 |

- **相加**：与 `LevelBias` 同行同款，理由沿用——加性字段的恒等元是 0、多 arc 叠加是连续的。
- **「合并后再 Clamp」而非逐 arc Clamp**：逐 arc 截断会让合并结果依赖 arc 的枚举顺序，而合并表的其余各行都是**可交换**的（乘法 / 取并 / 相加），破坏这一性质会让「location 与 arc 谁先」重新变成一个需要裁决的量。
- **明写的代价**：这是六字段里**唯一一个会互相湮灭**的格（arc A 写 `+2`、arc B 写 `−2` ⇒ 两条线都在显影而玩家什么也感知不到）——正是「权重相乘」那三条理由里第 ② 条点名要避免的形态。`LevelBias` 已经背了一次这个代价（它作用于**带内权重**、不改 `±2` 带边界，湮灭是局部的）；本格若湮灭，湮灭的是**进程结构**。

**③ 存档表达**

- **建议不落存档，读时重算。** 判据是既有的「重算不出来的存」：生效值 = `location.EventCountLimit + Σ Active arc 的 Delta`，两侧输入（`CurrentLocationId`、`plotKeyPoint` 的 `Active` 集合）**都已在存档里**，且判定本就发生在每一次整批重算时。落一份「当前生效配额」等于制造第二份真相，迁移与重放时必然对不齐（同 `pastEvent` 派生索引不落存档的处置）。
- **跨篇章结转**：**不结转，也无处结转**——`Delta` 是 arc 的属性，arc 有 `ChapterScope`；篇章推进时不再 `Active` 的 arc 自然退出求和。`LocationEventCount` 的归 0 语义完全不变。
- **热更 / arc 出队引起的生效值下降 ⇒ 可能出现 `LocationEventCount >= 新生效值` 立刻成立**（本批直接进闸门）。这与 overlay 改 `EventCountLimit` 的既有情形同形，可接受，但需要一条 `PushWarning` 留痕。

**④ 护栏（必须与字段同时落，否则直接打穿时长反推）**

| 护栏 | 形态 |
|---|---|
| **下界** | 最终生效值 `Clamp(..., 1, ...)` —— `EventCountLimit <= 0` 已是加载期 `PushError`，运行时不得绕过它造出 0 |
| **上界** | `Clamp(..., ..., ceil(location.EventCountLimit × EventCountLimitCapRatio))`，`CapRatio` 是**平衡资源里的全局单值**（初值建议 **1.5**），**不接受任何按 arc / location 的覆盖参数**（同 `TravelFullFanoutChance` 收口） |
| **加载期校验** | `|EventCountLimitDelta| > EventCountLimitDeltaCap`（内容侧上界）→ `PushWarning` + arc `Id` + 节点 `Id`（同 `LevelBias` 越界那一行的处置） |
| **反推验收** | `systems/balance.md` 的「供给 / 需求比校验表」须按**最坏情形**（全部 arc 顶格推拉）复算一次，而不只按标称值 |
| **纪律松动** | **必须同时裁决**：抬升判据 **(b)** 要么为配额闸门开一条明写豁免，要么改写措辞。这一条**不是加法**，是既有承重纪律的松动 |

**⑤ 代价合计**：+1 字段 · +1 合并算子行 · +1 上界常量 · +1 加载期校验 · +1 反推验收口径 · **+1 条承重纪律的松动**。前五项是纯加法、无存档迁移；第六项不可加性回退。

### 备选 B · 只许收紧（`Delta <= 0`）

形态同 A，但字段取值域收紧为**非正**（加载期 `Delta > 0 → PushError`）。

- **收益**：时长反推只会**更短**不会更长 ⇒ 目标时长区间的**上界**仍被守住，`lifeSpanCost` 那一侧的预算不会被打穿。
- **仍未解决**：抬升判据 (b) 照样被打穿——**恰恰是收紧方向能把玩家提前锁进闸门**，(b) 要挡的正是这个。**故 B 只买到时长的一半安全，不买到纪律的任何一半。**
- 若用户确实想要剧本影响地域节奏，B 优于 A；但两者都不优于「抬 `TypeWeights[Travel]`」这条**已经存在、零成本、且不碰约束面**的通道。

## 与既有决策的张力

| # | 张力 | 说明 |
|---|---|---|
| 1 | **抬升判据 (b) / 「只调内容不调约束」**（`future-event-service.md`） | 本草稿主张与之**一致**；备选 A / B 与之**正面冲突**，采纳任一即须改写 (b) 或为配额闸门开豁免。**这是最重的一条，不能靠「实现上不会有人这么用」绕过。** |
| 2 | **`TravelFullFanoutChance` / `BatchSizeWeights` 的「不接受覆盖参数」** | 同族三旋钮的对称性；开放第三个即三者两套纪律 |
| 3 | **时长反推 + 经验供需比验收项**（`balance.md`） | 反推链明写是脆的；配额变成隐藏函数后，验收项从算术问题变成分布问题 |
| 4 | **`LocationCodex` 的跨轮回知识资产**（`codex/_index.md`） | 该词条的深度仍待答，且 `eventCountLimit` 被明列为候选词条内容。**若配额可被剧本推拉，这个词条要么写不了、要么会骗人**——而「图的稳定性是对玩家的隐性承诺」已是承重表述。**本条是备选 A / B 的一项此前未被记录的代价。** |

**与主张（不可调制）本身的张力：无。** 四条张力全部指向「开放」那一侧。

## 前置依赖

**无硬阻塞**——本条可独立定稿（它答的是「字段有没有」，不是「填多少」）。两条软关联，如实记下：

1. **各 location 的 `EventCountLimit` 取值 / 一章途经几个地域**（归 ch1 数值标杆专场，`balance.md` 待决）—— 只在采纳备选 A / B 时构成阻塞：`CapRatio` 的标定需要先有基准值。**采纳主张则不受其阻塞。**
2. **「失去 flags 关地域后的运营替代通道」**（`systems/adventure-event/travel/_index.md` 待决项，明写候选形态是「把该地域的 `EventCountLimit` 压到 1 让人快速离开」）—— 它与本题**共用同一格字段但走 overlay 通道、不走剧本**。见「仍需用户决定」第 3 条：本条结论不应被误读为把那条运营手段一并封死。

**不构成依赖的**：`EncounterTighten` 字段面（本题不动 `Tighten`）· `HiddenStatGrade` 映射值 · 五类配比取值 —— 三者均与本题正交。

## 仍需用户决定 → **已全部裁决（2026-08-22 · 批量评审）**

> - **①（主问）配额是否对剧本开放** → **A0 · 不可调制**。`PlotModulation` 不长第七字段。（用户单独作答，正式拍板）
> - **② 若选 A / B 时抬升判据 (b) 怎么处置** → **随 ① 的裁决消解，无需回答**（条件项，仅在选 A / B 时才需答）。
> - **③ 「不可调制」是否只约束剧本层** → **c-1 · 只约束 PlotManager**，`EventCountLimit` 仍是普通内容字段、overlay 照常可改。`[采纳推荐 — 待复核]`

**① `[取向选择]` 配额是否对剧本开放（主问）**

| 选项 | 后果 |
|---|---|
| **A0 · 不可调制（推荐）** | 零结构增量；四条张力全部消解；剧本仍可经 `TypeWeights[Travel]` 加速离开。**失去**「硬性延长停留」这一类叙事表达 |
| **A · 双向可调** | +1 字段 +1 合并算子行 +1 上界常量 +1 校验 +1 反推口径，**且必须松动抬升判据 (b)**；`LocationCodex` 的配额词条随之不可信 |
| **B · 只许收紧** | 同 A，但守住时长上界；**(b) 照样被打穿**（收紧方向恰恰是能把玩家锁进闸门的那一侧） |

**推荐 A0。理由**：判据已经判它落约束面（依据 ①）；开放会让一条**可机械核对**的准入条件退化回一句纪律（依据 ②，最重）；两个相邻旋钮已有明写的同款收口（依据 ③）；且想要的效果有零成本的既有通道。**A / B 的收益是一类叙事表达，代价是一条承重纪律——本库对这类交换的既有取向是不换。**

→ 已裁决（2026-08-22 · 批量评审）：**A0 · 不可调制** —— `PlotModulation` 不加第七字段，`eventCountLimit` 恒为内容侧定值。

**② `[取向选择]` 若选 A / B：抬升判据 (b) 怎么处置**

| 选项 | 后果 |
|---|---|
| **b-1 · 为配额闸门开一条明写豁免** | (b) 的其余部分保持可机械核对；但豁免本身是「清单化」的开端，而 (b) 的价值恰是「判据比清单值钱」 |
| **b-2 · 改写 (b) 的措辞**（例：「不读隐藏属性 / 剧本状态」→「不由剧本**直接**置位」） | 一句话改动，但它把 (b) 从**结构性禁止**降级为**意图性禁止**——PlotManager 借道任何内容字段间接影响约束都将变得可辩护 |

**推荐**：若非选 A / B 不可，取 **b-1**（豁免比措辞松动可控）。**但这一项本身就是不选 A0 的主要代价，请先答 ①。**

→ 随【①】裁决消解，无需回答（① 取 A0 后本项为不成立的条件项；抬升判据 (b) 保持原样，不松动）。

**③ `[取向选择]` 「不可调制」是否只约束剧本层**

采纳 A0 后，`EventCountLimit` 仍然是一格**普通的内容字段**，overlay 照常可改（location 恒启用、不受 flags 管辖，overlay 改值下次冷启动生效）。

| 选项 | 后果 |
|---|---|
| **c-1 · 只约束 PlotManager（推荐）** | overlay 改定值照常允许 ⇒ `travel/_index.md` 那条「运营替代通道」候选（把问题地域的配额压到 1）**保持开着**，日后可独立定稿 |
| **c-2 · 连 overlay 也视为不可动** | 时长反推的稳定性更强，但**失去唯一一条不改图就能软化问题地域的运营手段**（而 flags 关地域已因死锁风险被明确否决） |

**推荐 c-1**：本题问的是「剧本能不能推拉」，运营通道是另一条待答项，不应被本次结论顺手封死。**明写这一句是必要的**——否则「`eventCountLimit` 不可调制」这句话会在日后被读成 c-2。

→ 已裁决（2026-08-22 · 批量评审）：**c-1 · 只约束剧本层**（`EventCountLimit` 仍是普通内容字段，overlay 照常可改） [采纳推荐 — 待复核]
