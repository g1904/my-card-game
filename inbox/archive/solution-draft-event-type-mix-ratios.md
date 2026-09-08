---
type: solution-draft
date: 2026-09-06
question: 五类事件之间的配比（`BaseTypeWeights` 取值），以及 Combat 内 `combatTier` 三档的配比
source: open-questions/02-event-options.md → 「五类之间的配比，以及 Combat 内 `combatTier` 三档的配比」；取值经 2026-09-06 批量评审裁决（Combat 最高频 + 篇章时长上移）后由 solution-draft-chapter-duration-rescale.md 反推定案
targets: systems/balance.md · systems/adventure-event/_index.md · systems/adventure-event/combat/_index.md · systems/services/future-event-service.md · systems/game-progression.md
status: distilled
reviewed: 2026-09-06 批量评审定案 —— Combat 最高频保措辞、配比迁就（0.35 / 0.13 / 0.13 / 0.32 / 0.07 三章同值）· `Practice : Standard = 1 : 1` 为内容编排口径 · Finale 不作扣除 · 调制零新增只补建议区间；落笔取 rescale 新口径
distilled-to: handoffs/2026-09-06-event-type-mix-ratios.md
---

# 方案 — 五类事件配比与 `combatTier` 三档配比

## 问题

`BaseTypeWeights` 的**运算形态已定**（五类各一格、以乘性方式参与类型分布、归一化在类型分布层发生 —— `decisions/ADR-0026-event-generation-weighting-pipeline.md`、`systems/services/future-event-service.md:162`），只欠四件事：

1. 五类（Combat / Research / Explore / Exchange / Travel）每格填多少；
2. location 与 AdventurePlot 如何调制它（形态已定为乘性，待定的是编排取值区间与钳制口径）；
3. Combat 内部 `Practice : Standard` 的比例（每篇章一个 `Finale` 已定）；
4. 逐章是否变化、旋钮落在哪。

它卡住的是：`systems/adventure-event/_index.md:44-45`、`systems/services/future-event-service.md:544`、`systems/game-progression.md:200`、`systems/adventure-event/common-properties.md:409` 四处同一条待决，以及 `systems/balance.md:813` 的占位行。

## 约束（来自既有设计）

- **分母与反推源**：篇章目标时长与逐章事件数已按 2026-09-06 裁决整体上移（`T_c` = 55 / 58 / 68 · 事件数 35 / 36 / 43 合 114 · 新 ch1 参考构成 35 事件 / 55.5 分钟），**取值的完整反推与三条验算见 `solution-draft-chapter-duration-rescale.md`**；本稿承载配比的结构结论与落地形态。
- **Combat 是最高频的一类**（`systems/adventure-event/_index.md:18`、`combat/_index.md:10`）——用户裁决保住措辞、改配比迁就，幅度为「略高于 `Exchange`」。
- **Finale 是 ④ 之前的闸门式旁路，不参与类型加权**（`future-event-service.md:181-182`）；每篇章恰一个（`combat/_index.md:47`）。
- **配额闸门批整批 Travel，在 ① 之前短路，不进管线**（`future-event-service.md:141,155`）。
- **`combatTier` 是模板常量，物化不可改**：「一个 AdventureEvent 条目只有一个档」「没有任何调制源能改变某个实例的档位」（`combat/_index.md:25`）。
- **Explore 的 `t` 标定已内含 `Practice : Standard = 1 : 1`**（`balance.md:211`）；Explore 真身 `Combat : Exchange : Travel ≈ 5 : 3 : 2` 是内容编排口径而非运行期旋钮（`explore/_index.md:43`、`future-event-service.md:328`）。
- **灵石口径 = 战斗**（`balance.md:326-334`）；购买力校验绑住 Exchange 次数（`balance.md:372`）。
- **调制形态与取值域均已定**：location 侧 `EventTypeModifierData.Multiplier > 0`（Travel 行允许 `== 0`，`game-progression.md:105`、三条加载期校验 `:154-156`）；剧本侧 `PlotModulation.TypeWeights` 恒 `> 0`（`plot-manager.md:325,337`），多 arc 相乘（`:354`），`Active` 的 side arc ≤ 2（`balance.md:389`）。

## 方案

### 一、`BaseTypeWeights` 五格初值（定案）

| chapter | `Combat` | `Research` | `Explore` | `Exchange` | `Travel` |
|---|---|---|---|---|---|
| ch1 炼气 | **0.35** | **0.13** | **0.13** | **0.32** | **0.07** |
| ch2 筑基 | **0.35** | **0.13** | **0.13** | **0.32** | **0.07** |
| ch3 金丹 | **0.35** | **0.13** | **0.13** | **0.32** | **0.07** |

取值依据（完整推导与验算见 `solution-draft-chapter-duration-rescale.md` ②③⑤）：

- **`Combat 0.35 > Exchange 0.32`**：满足「略高于」的裁决幅度。差 0.03 是刻意取小——`Combat` 的 `t` 是 `Exchange` 的 2.25 倍，配比每往 `Combat` 挪 0.01，同样时长下一轮回事件总数少约 0.7 个。
- **`Travel 0.07`**：篇章变长 ⇒ 途经 location 由 4–5 增至 7–9，管线内的主动换图须跟上，否则「换图是可选策略」退化为「换图是被迫的」。
- **三章同值、但仍写三行**：与 `BatchSizeWeights` 逐字同款——「三章暂共用同一行，但仍写成三行——分格轴留着，校准时直接填」（`balance.md:404-405`）；`EnemyLevelingData` 亦同（`:89`）。服务侧只读「当前篇章的那一行」，不为分章写分支。
- **三条验算全部通过**：① Combat 最高频（权重 0.35 > 0.32 · ch1 计数含 Finale 11 > 10 · 结算口径 13.0 > 11.2）；② ch1 购买力（新构成 `BaseReward = 9.5S`，`S(ch1) = 10` ⇒ 95 ≈ 旧 99，25 格商店表零改动）；③ 时长预算（三章 55.5 / 57.5 / 68.2 分钟，均值 ≈60）。

**逐类跨章推算（供后续两章补构成表时对账；`P` = 管线事件数 30 / 31 / 37）：**

| 类型 | ch1 | ch2 | ch3 | 一轮回 |
|---|---|---|---|---|
| `Combat`（常规） | 10.5 | 10.9 | 13.0 | ≈ 34.4（+3 Finale ≈ 37） |
| `Research` | 3.9 | 4.0 | 4.8 | ≈ 12.7 |
| `Explore` | 3.9 | 4.0 | 4.8 | ≈ 12.7 |
| `Exchange` | 9.6 | 9.9 | 11.8 | ≈ 31.4 |
| `Travel`（加权 + 闸门） | 2.1 + 4 | 2.2 + 4 | 2.6 + 5 | ≈ 20 |

### 二、存储形态与旋钮落点

`[既有推演]` + `[通行做法]`

**载体：新开一份 `BaseTypeWeightsData`，形状照 `LifeSpanCostTableData` 的既有范式。** 按 `systems/balance.md:151` 的平衡资源三问：问 ①（消费者）= future-event-service 的产出阶段（步骤 ④）；问 ②（覆写纪律）= 不接受任何覆写参数（与 `TravelFullFanoutChance` / `BatchSizeWeights` 同款收口）；问 ③ = 15 格之间无跨字段不变式 ⇒ 不必与任何既有资源同住。

```csharp
[GlobalClass]
public partial class BaseTypeWeightsData : Resource, ISingletonContent
{
    // 三章各一行；篇章数是固定的游戏结构 ⇒ 具名字段，不用长度 3 的索引数组
    [Export] public BaseTypeWeightsRow Chapter1 { get; set; }
    [Export] public BaseTypeWeightsRow Chapter2 { get; set; }
    [Export] public BaseTypeWeightsRow Chapter3 { get; set; }
}

[GlobalClass]
public partial class BaseTypeWeightsRow : Resource   // 内嵌类型一律 Resource 派生
{
    [Export] public float Combat   { get; set; }
    [Export] public float Research { get; set; }
    [Export] public float Explore  { get; set; }
    [Export] public float Exchange { get; set; }
    [Export] public float Travel   { get; set; }
}
```

经 **`Content.Single<BaseTypeWeightsData>()`** 取，调用方不写任何 `Id` 字面量（`content-service.md` 的既有纪律）。

**五个具名字段而非数组**：`LocationData` 侧取数组是因为「缺省 = 无修正」允许缺行；基础权重表五格必须齐全（缺行 = 该类型权重未定义），具名字段让缺行在编译期就不可能。

**加载期校验（三条，全部带定位上下文）：**

| 违规 | 语义 | 处置 |
|---|---|---|
| 某章五格全 0 | 分布不存在，④ 的归一化除零 | `PushError` + 抛，带章号 |
| 某章存在负值 | 负权重无定义 | `PushError` + 抛，带章号与类型名 |
| 某章任一格 `== 0` | 该类型在无 location 修正时不可及 = 静默改支撑集，与「类型修正只改权重不改支撑集」（`future-event-service.md:174`）正面冲突 | `PushError` + 抛，带章号与类型名 |

- **刻意不校验「五格和 = 1」**（与 `BatchSizeWeights` / `EnemyLevelRange` 的权重表在这一点上相反，故必须写明）：归一化发生在类型分布层（`future-event-service.md:162-163`），且乘完 location / arc 系数后和本就不再是 1 ⇒ 和是多少不影响任何结果；加一条和 = 1 的断言是自证冗余，且会在作者只想「把 Combat 调高一点」时逼他重算另外四格。初值取和为 1 只是呈现约定。

### 三、location 与 AdventurePlot 的调制形态与钳制

`[既有推演]`（形态）+ `[通行做法]`（区间）

**形态无需新增任何东西**——两侧都已定案为乘性系数、且取值域已带加载期校验（见约束）。本稿只补一条**编排口径**（不新增结构、不新增运行期钳制）：

> **建议区间：单条 location / 单条 arc 的类型修正落 `[0.5, 2.0]`；乘完全部修正并归一化后，任一类型的占比应落 `[5%, 55%]`。**

工作示例（用定案初值）：

| 场景 | 修正 | 归一化后占比 |
|---|---|---|
| 荒野（`Combat ×2.0` · `Exchange ×0.5`） | 0.70 / 0.13 / 0.13 / 0.16 / 0.07，Σ = 1.19 | Combat **58.8%** ✗ 越 55% 上沿 |
| 荒野（收到 `Combat ×1.7`） | 0.595 / 0.13 / 0.13 / 0.16 / 0.07，Σ = 1.085 | Combat **54.8%** ✓ 贴线 |
| 坊市（`Exchange ×2.0` · `Combat ×0.5`） | 0.175 / 0.13 / 0.13 / 0.64 / 0.07，Σ = 1.145 | Exchange **55.9%** ✗ 略越上沿 |
| 坊市（收到 `Exchange ×1.5`） | 0.175 / 0.13 / 0.13 / 0.48 / 0.07，Σ = 0.985 | Exchange **48.7%** ✓ |

**护栏咬在占比上而非系数上，因此不必为不同格写不同的系数上限**：对两个大格（`Combat 0.35` · `Exchange 0.32`），×2.0 都会略越 55% 上沿——想做「一半以上是打架 / 逛街」的风味地域，实际可用的系数约为 ×1.7 / ×1.5；三个小格则可用满 `[0.5, 2.0]`。

**落点 = `/audit-content` 的一项汇总，只报告不阻断**，与 `lifeSpanCost` 条目级偏移幅度同款处理（`balance.md:149`）。**不加运行期钳制**：钳制会把「只改权重不改支撑集」变成「有时也改权重的大小关系」，而现有的 `> 0` 校验已封死唯一的结构性风险。

### 四、`combatTier` 三档配比

#### 4.1 `Finale` 的「扣除方式」= 不作任何扣除

`[既有推演]` Finale 在 ④ 之前旁路，恒占一个槽位、不参与类型加权 ⇒ **`BaseTypeWeights` 的 `Combat` 格只标定非 Finale 战斗**，篇章实际战斗数 = `0.35 × P + 1`。同理 `Practice : Standard` 的分母不含 Finale——与 `balance.md:211` 的 Explore `t` 标定口径逐字一致。

#### 4.2 `Practice : Standard = 1 : 1`（三章统一 · 定案）

两条互相独立的既有依据同时给出 1:1：

1. `balance.md:211`：Explore 的 `t` 标定「Combat 加权只按 `Practice : Standard = 1 : 1` 计」——这个比例已被用进 `t(Explore) = 1.6`，进而进了 21 格定价表的 Explore 行；改动它就要重算定价表。
2. 新 ch1 参考构成 `Practice 5 / Standard 5`，同时通过时长、结转、购买力三道验收（见 rescale 稿 ③⑤）。

按新构成：一轮回常规战斗 ≈ 34.4 场 → **`Practice ≈ 17 / Standard ≈ 17`**，加 3 个 Finale ≈ 37 场 ✓。灵石侧自洽：ch1 `BaseReward = 5×0.5S + 5×S + 1×2S = 9.5S`，`S(ch1) = 10` ⇒ 95 ≈ 旧口径的 99——**1:1 是该式成立的前提**。

「后期更险」不由配比承载——它已由**越阶只出现在境界末两级**（`balance.md:30` 推论 ②）与 `baseMomentum` 跨度放大独立承载。

#### 4.3 配比的**载体**：内容池编排口径，不是运行期旋钮（承重）

`[既有推演]` `combatTier` 是模板常量，十步管线里没有任何一步在掷 tier——⑥ 按类型指派槽位、⑦ 在槽内按 `w_event` 抽条目（`future-event-service.md:167`）。⇒ **玩家实际遇到的 `Practice : Standard` 比例 = Combat 条目池中两档条目的组成 × 各自 `SelectionWeight` 权重的涌现结果**，与 Explore 真身分布同构。因此：

- **不新增任何字段 / 不新增 `CombatTierWeights` 表 / 不在管线里加一步**；
- `1 : 1` 写成**内容编排口径**，落点照 Explore 5:3:2 的既有范式（`explore/_index.md:49`）：`adventure-event` 类型档案的 Combat 分区台账登记每条的 `combatTier`；`/audit-content` 汇总两档占比与目标比对，只报告不阻断；
- **调制侧的自然推论**：location 与剧本改得动「有多少 Combat」（`TypeWeights` 的 Combat 格），改不动「其中多少是切磋」——后者只能靠 `PlotModulation.EventWeights` 给单条 Combat 条目加权间接影响，落在内容面而非约束面。与 `explore/_index.md:42`「剧本对真身分布的调制是间接的，而这恰好合规」同一条判据，零改动。

## 具体形态（可 derive 的落地面）

| 落地面 | 形态 |
|---|---|
| 平衡资源 | 新开 `BaseTypeWeightsData : Resource, ISingletonContent` + 内嵌 `BaseTypeWeightsRow`（五个具名 `float`），三章各一行；经 `Content.Single<T>()` 取 |
| 初值 | 三章同值 `Combat 0.35 · Research 0.13 · Explore 0.13 · Exchange 0.32 · Travel 0.07` |
| 加载期校验 | 三条（五格全 0 / 存在负值 / 任一格 == 0）→ `PushError` + 抛，带章号与类型名；**不校验和 = 1** |
| 消费点 | `future-event-service` 十步管线的 ④：`w_type(t) = BaseTypeWeights(t) × LocationMod(t) × Π_arc PlotTypeMod(arc, t)` —— 公式一字不改 |
| 物化日志 | 既有 `[FutureEvent-Weight] … dist=<...>` 已能读出本表的效果（`future-event-service.md:185`），不新增日志 |
| `combatTier` 配比 | 无运行期旋钮；`Practice : Standard = 1 : 1`（三章统一）为内容编排口径，台账落 `adventure-event` 类型档案的 Combat 分区，`/audit-content` 汇总比对（只报告不阻断） |
| 调制编排口径 | 单条修正建议落 `[0.5, 2.0]`；归一化后任一类型占比建议落 `[5%, 55%]`；`/audit-content` 汇总，只报告不阻断 |
| 篇章分格 | 三行结构保留、当前同值；服务侧只读「当前篇章的那一行」，不为分章写分支 |
| 校准状态 | 全部为待实测校准的初值；校准对象是「实现分布」，不是「供给分布」（见下） |

**⚠ 供给分布 ≠ 实现分布（必须写明，否则校准时会对错靶子）。** `BaseTypeWeights` 决定的是**摆在玩家面前的**类型分布；玩家每批只选一个 ⇒ 实际走过的构成 = 供给分布 × 玩家偏好。上表初值取「供给 = 目标实现」，这在玩家无偏好时才严格成立。实测统计要同时记录「供给了什么」与「选了什么」，用比值反推偏好后再调供给分布。不为此加任何机制——偏好本身是玩法信息，不是要被抹平的噪声。

## 后果

- **`systems/balance.md`**：`:813` 的占位行由本表替换；新增 `BaseTypeWeightsData` 一节（表 + 类形状 + 三条校验，反推回链时长重标定的落笔处）。`:211` 的 `Practice : Standard = 1 : 1` 由「Explore 标定的局部假设」升格为全库口径，两处互相回链。
- **`systems/adventure-event/_index.md`**：`:44-45` 两条待决关闭（它们是同一条待答被拆成两条，提炼时一并关闭）；「Combat 是最高频的一类」（`:18`）措辞一字不改。
- **`systems/adventure-event/combat/_index.md`**：新增一条「`combatTier` 配比是编排口径、无运行期旋钮」的意图；`:10` 措辞不动。
- **`systems/services/future-event-service.md`**：`:544` 待决项关闭；④ 的公式与十步管线一字不改。
- **`systems/game-progression.md`**：`:200` 待决项关闭；`:113` 处补类型修正的建议区间。
- **存档 / schema：零影响**；代码面：新增一份平衡资源 + 一处 `Content.Single<T>()` 读取，管线逻辑零改动。

## 备选方案（已考虑并否决）

- **旧初值 `0.28 / 0.14 / 0.14 / 0.39 / 0.05`**（由旧 ch1 参考构成 25 事件 / 39.3 分钟直接反推）——被两条裁决取代：`Exchange > Combat` 与「Combat 是最高频的一类」的定性表述矛盾，用户裁定保措辞、改配比，并把篇章时长整体上移以容纳增量（在旧时长约束下把 1 个 Exchange 换成 1 个 Standard 即越出 30–40 分钟区间，此路原本被算术堵死）。
- **为 `combatTier` 新开一格权重（`CombatTierWeights`）或在管线里加一步 tier 掷骰** — 否决：与「一个 AdventureEvent 条目只有一个档」「没有任何调制源能改变某个实例的档位」正面冲突；要让它成立，物化就得改写模板的 tier，连带推翻 tier 落 `EncounterSpec` 而 `EventOption` 不加字段的既有定案（`answer-logs/log-event-option-materialized-fields.md:18`）。
- **`Practice : Standard` 逐章右移（如 ch1 1:1 · ch2 2:3 · ch3 1:2）** — 否决：`t(Explore)` 的 Combat 加权 2.25 变成逐章不同 ⇒ 21 格定价表的 Explore 行要按章重算，三章灵石反推同改；买到的节奏差异（每章约 1 场从切磋变常规）与代价明显失配，且「后期更险」已有独立承载。
- **把 `BaseTypeWeights` 并入 `LifeSpanCostTableData`** — 否决：两表行粒度不同（定价表 7 行、权重表 5 格），并住会长出「7 行 ↔ 5 格如何对应」的跨字段不变式；按三问判据「无跨字段不变式 ⇒ 不必同住」。
- **逐章给不同的权重行** — 否决：三章事件数本身是估算，为估算量的小数位做分章分化是把噪声焊进配置；分格轴已留在结构里，实测后要分随时能分。
- **给 Travel 权重填 0，让换图全部由配额闸承担** — 否决：加载期校验会拦（任一格 == 0 即静默改支撑集），且「零成本 reroll 由寿元定价堵死」（`balance.md:130`）预设了自愿换图存在。
- **把配比写成每章硬性配额** — 否决：与「本服务不持有跨批次的状态」（`future-event-service.md:186`）冲突，且需要一个新的跨批次计数器落存档。

## 与既有决策的张力

**无。** 原有两条张力均已随时长重标定消解：①「Combat 最高频」vs `Exchange` 权重最高——新配比下 Combat 严格最高频，两处定性表述一字不改成立；② 75% 经验覆盖率 / 供给需求比 1.15–1.20 / ch1 参考构成三者不同时成立——已裁定覆盖率下修至 ≈55%，新分母下三者首次同时成立（覆盖率 54.3% · 供给需求比 1.16 · 构成自洽，验算见 rescale 稿 ⑦）。

## 前置依赖

- **ch2 / ch3 的逐类型参考构成尚不存在**（`balance.md:359`）⇒ 跨章推算是按同一行权重外推，非直读；两章构成表补齐后「三章同值」须复核。ch1 行不受影响。
- **ch2 / ch3 的 location 数与 `eventCountLimit` 归内容制作阶段**（`balance.md:421`）⇒ 闸门 Travel 数（4 / 4 / 5）是外推估算。
- **`Practice : Standard` 的实测校准依赖 Combat 条目池铺开** —— 在 `adventure-event` 内容类型开张、Combat 分区台账建起来之前，1:1 只能作为编排目标挂着。
- **λ 反推里的两个 ⚠ 格（败率 20% · `E[道念差]`）不得引为承重依据**（`balance.md:240`）——本稿未用到这两格（战斗场数是 λ 表的输入而非那两格的输出）。
