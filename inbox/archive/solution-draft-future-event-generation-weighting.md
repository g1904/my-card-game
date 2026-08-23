---
type: solution-draft
date: 2026-08-22
question: future-event-service 产出一批 eventOptions 时，类型概率修正用什么算子、三层框定按什么顺序叠加、多条 Active arc 的 PlotModulation 与 location 修正如何合并、批次规模 1–5 的两端由什么驱动
source: open-questions/02-event-options.md → 「生成 / 加权规则与叠加顺序（08-05b 收窄 · 08-15c 再收窄）」
targets: systems/services/future-event-service.md · systems/game-progression.md · systems/adventure-event/common-properties.md · systems/services/plot-manager.md · systems/adventure-event/travel/_index.md · systems/balance.md
status: distilled
reviewed: 2026-08-22 — 四项取向全部裁决；合并 interview 另裁定批次规模 N = 目标槽位数 + 收缩保底（收缩到 0 补一个 Travel，非单项补位）· `PlotModulation.EventWeights` 由「加成」松动为乘性系数 · 事件侧 `ChapterScope` 加 `(chapter, EventType)` 启动期断言且 Travel 一类豁免 · 十步管线仅适用常规批 · 满级 Finale 走闸门式旁路而非高权重
distilled-to: handoffs/2026-08-22-event-generation-weighting-pipeline.md
---

# 方案草稿 — 可用事件的生成 / 加权运算形态

## 问题

`future-event-service.ComputeEventOptions` 的**输入面**已经全部答定——location 携带哪两组字段、`eventCountLimit` 怎么计数、Travel 段的物化伪码、重算依据是角色整体历程、批次常态 3 区间 1–5、`PlotModulation` 的六个字段、赋级带 `±2` 与带内权重表——但**把这些输入合成一批 eventOptions 的那段算术从未写下来**。四个面同时悬着：

1. **类型概率修正的运算形态**：`LocationData.EventTypeModifiers` 里的一行到底是乘性系数、加性偏移，还是「白名单 + 权重」？其中的四类（Travel 之外）能否被修正到 0？
2. **月圆之夜式「策划」与随机权重的配比**：这套产出到底有多少是编排出来的、多少是掷出来的？
3. **三层叠加顺序**：location 框定 / `PlotModulation` / seeded RNG 谁先谁后；同时最多四条 `Active` arc（Story + Chapter + 至多 2 条 side）各带一份 `PlotModulation` 时，白名单**取交还是取并**、权重**相乘还是相加**。
4. **批次规模区间两端由什么驱动**：什么情况下产出 1 项、什么情况下放到 5 项。它同时卡住常规批里 Travel 的槽位数 `k`。

**卡住了什么。** 这段算术是 `ComputeEventOptions` 的主体；不定它，`future-event-service` 的 derive 无从落笔，`LocationData.EventTypeModifiers` 与 `PlotModulation.TypeWeights` 两个字段的取值域与加载期校验也写不出来（当前两处都只有一句注释）。

## 约束（来自既有设计）

**硬约束（不可松动，方案必须落在其内）：**

| 约束 | 来源 |
|---|---|
| location 的类型修正是**软框定**——「改权重，不改可及性」 | `systems/game-progression.md` 的 location 两组字段表（承重） |
| location 的框定面**只有两组字段**（类型修正 + `eventCountLimit`），不再有第三组 | 同上（承重） |
| **PlotManager 只调内容不调约束**；越权的写法「在内容层根本没有字段可填」 | `systems/services/future-event-service.md` · `plot-manager.md`（承重） |
| `PlotModulation` 新增字段的判据：落**内容面**→已有字段够用；落**约束面 / 模板字段面**→**不加字段** | `plot-manager.md`「新增一格物化字段时是否跟着加一格」 |
| 约束面由本服务独占置位；同款收口的先例是 `TravelFullFanoutChance = 0.80`「只有一份全局值，不接受任何按剧情线 / location 的覆盖参数」 | `systems/adventure-event/travel/_index.md` · `systems/balance.md` |
| **Travel 一行可被修正到 0 是安全的**（闸门是独立通道，死局兜底仍成立） | `travel/_index.md`（已确认） |
| 批次规模常态 3、区间 1–5；**1 项的批次合法，不需要额外规则允许它** | `adventure-event/common-properties.md` · `future-event-service.md` |
| 闸门批规模 = 出度（或 1），由 `locationMap` 出度 ≤ 5 的加载期校验封住 | `game-progression.md` |
| 常规批的 Travel 段伪码**已定**：「Travel 与其余四类一同按 location 的类型修正加权抽取，得槽位数 `k`（`k` 可为 0）」 | `future-event-service.md` |
| 全部玩法随机走 `SeedManager` 的 **map 子流**；产出即定稿、落存档、不重算 | `systems/common-properties.md` · `future-event-service.md` |
| 抽取一律经 `ContentRegistry.AllEnabled()`；**邻接集合是唯一例外** | `content-service.md` · `future-event-service.md` |
| `AdventureEventData` **不带 `Rarity`**——「事件不进抽取池的稀有度维度，**它的出现由权重与优先级控制**」 | `systems/common-properties.md`「内容共有字段 `Rarity`」 |
| 内容侧**不落裸数字**，走枚举档 + 平衡表映射（`ExperienceGrade` / `HiddenStatGrade` 是既有两例） | `game-progression.md` · `plot-manager.md` |
| 同时最多 4 条 `Active` arc（Story 1 + Chapter 1 + side ≤ `MaxConcurrentSideArcs = 2`）；上限存在的理由正是「调制是叠加的，三条同时改会变成谁也说不清的混合物」 | `plot-manager.md` · `systems/balance.md` |
| `PlotArcData.ExclusiveGroup`：同组 arc 一次轮回内至多激活一条；**超上限排队不丢弃**，使「触发恒定成立，只是延后」 | `plot-manager.md`（承重） |
| 候选池短缺的三道闸已定；闸 ② 判「该条目本次不进候选池」，闸 ③ 降级，**本服务不设单项补位** | `future-event-service.md` |

**最强的一条形态先例（本方案的骨架来源）：** 赋级带内分布权重已经答定为
**「基础权重表 × 调制修正（乘性，只改权重不改支撑集） × 截断重分配」**，并明写「调制修正（乘性）……PlotManager 可对本批 / 本剧情线整体施加偏移系数（如把 `+1 / +2` 权重翻倍后归一化）」（`systems/balance.md`）。
**同一个服务、同一条物化管线、同一个 map 子流、同一批调制源**——事件类型加权若换一套算子语言，就是同一处代码里两种权重语义。

## 建议方案

### ① 类型修正 = 乘性系数，作用于归一化前的权重；支撑集不变

`[既有推演]`

**形态：** `EventTypeModifierData` 的一行是一个**乘性系数**（`float`，量纲无单位），乘在该类型的基础权重上；五类系数乘完后一次归一化。

```
w_type(t) = BaseTypeWeight(t)            // 平衡表，按篇章分格；取值归「五类配比」那条待答项
          × LocationMod(t)               // LocationData.EventTypeModifiers 的该行，缺省 = 1.0
          × Π_arc PlotTypeMod(arc, t)    // 全部 Active arc 的 PlotModulation.TypeWeights，缺省 = 1.0
P(t) = w_type(t) / Σ_t' w_type(t')
```

**三条依据，逐条上锁：**

- **软框定的定义直接给出算子。** location 那一行明写是「**软**（改权重，不改可及性）」。加性偏移**做不到不改可及性**（一个 `-100` 的偏移把权重按到 0 或负，可及性没了，还要额外裁「负权重怎么办」）；「白名单 + 权重」本身就是**硬**框定（它改的正是可及性），与表上写的「软」正面冲突，且白名单这条通道已经被 `PlotModulation.EventWhitelist` 独占——两处白名单等于两个权威。**只有乘性系数天然满足「改权重不改可及性」**：正系数缩放权重，支撑集一格不动。
- **与赋级带的调制修正逐字同构。** 「乘性，只改权重不改支撑集 + 归一化」是本库已经答定过一次的算子（`systems/balance.md`）。同一段物化管线里两种权重语义是纯粹的漂移源。
- **乘法可交换 ⇒ 顺序问题在这一层自动消失。** 这是选乘性的第三笔收益，见 ③。

**取值域与校验：**

| 项 | 取值 | 加载期处置 |
|---|---|---|
| `EventTypeModifierData` 的 Combat / Exchange / Research / Explore 四行 | **`> 0`**，缺省 1.0 | `<= 0` → `PushError` + location `Id` + 类型 |
| `EventTypeModifierData` 的 **Travel 行** | **`>= 0`**（0 合法 = 该地域常规不出 Travel） | `< 0` → `PushError` |
| `PlotModulation.TypeWeights` 各行 | **`> 0`**，缺省 1.0 | `<= 0` → `PushError` + arc `Id` + 节点 `Id` |

**「其余四类不得修正到 0」是软框定定义的直接推演，不是数值偏好。** 修正到 0 = 改可及性 = 那一行不再是软框定。Travel 之所以是例外，理由已写在库里且只对它成立：**闸门是独立通道**，可及性由 `eventCountLimit` 闸门保证，故它的权重为 0 时可及性没有被改。
**剧本侧连 0 都不给**（取值域 `> 0`，不设 Travel 例外）：剧本要表达「这一段不出某类事件」的正确形态是 `EventWhitelist` 收窄候选池——那是既定的、唯一的剧本强制性表达位。

**推论（免费拿到的一条）：** 系数恒为正 ⇒ **归一化的分母恒 > 0**，「加权抽取抽不出东西」这个失败态在类型层不存在；类型层的空只可能来自**收窄后该类型没有条目**，那由 ② 的口径处理。

### ② 三层框定的叠加顺序 = 一条十步管线；seeded RNG 不是并列的第三层

`[既有推演]`

**承重的一句：三层框定里的「seeded RNG」根本不与前两层并列。** location 与 `PlotModulation` 是**框定**（改支撑集与权重），map 子流是**消费者**（在已经定形的分布上掷）。把它写成第三层会让人以为存在「RNG 先于框定」的可能形态，而那形态不存在。

```
① 取池        AllEnabled<AdventureEventData>()
② 白名单收窄   全部 Active arc 的非空 EventWhitelist 取并 → 收窄支撑集（见 ③）
③ 条目级闸     闸 ②（Research 槽 / Exchange 库存的可产出性）+ Explore 壳的真身过滤
              → 不合格条目本次不进候选池（既定，PushWarning）
④ 类型分布     w_type = 基础表 × location 系数 × Π arc 系数 → 在①②③之后仍有条目的类型上归一化
⑤ 批次规模 N   按篇章的规模权重表掷定（map 子流），N ∈ [1, 5]（见 ④ 小节）
⑥ 类型指派     逐槽按 ④ 的分布有放回抽 N 次 → 各类型的槽位数；Travel 抽中几次即 k
⑦ 条目抽取     槽内按 w_event = 档位映射值 × Π arc EventWeights 系数，**无放回**抽取（同批不重复 EventId）
⑧ Travel 段    照既有伪码：掷 map 子流 → 80% 从邻接抽 min(k, 邻接数) 个 / 20% 抽 1 个
⑨ 逐项物化     赋级 / Research 候选 / Exchange 库存 / OutcomeSpec / SelectCost 取负 / Priority 置位
⑩ 断言         Priority ∈ {0,1} · OutcomeSpec != null · Encounter 按真身判 · SelectCost 三条不变式
```

**排序理由（每一步「为什么必须在这一步」）：**

- **收窄支撑集（②③）必须先于算权重（④）。** 否则会算出一个包含空类型的分布，抽中即落空——而本服务**不设单项补位**，落空只能整格丢掉，等于让批次规模被静默腐蚀。先收窄再归一，空类型自动退出分母。
- **闸 ②③ 在②之后而非之前**：白名单可能把一整类条目筛没，先跑池计数是白算。且闸 ② 的口径明写「与实际抽取链同口径」——抽取链是收窄后的那一条。
- **④ 之内 location 与 arc 谁先无所谓 —— 乘法可交换。** **这正是「叠加顺序」这一问在类型权重那一半的真正答案：选了乘性，顺序就不是一个需要裁决的量。** 剩下需要真正定序的只有 ②（支撑集）与 ⑤（规模），而它们各自只有一个来源。
- **⑤ 在 ④ 之后**：规模是约束面、与内容面的分布无关，两者不互相输入；写成先后只为让 ⑥ 有确定的 N。
- **⑥ 有放回、⑦ 无放回**：一批里出现两个 Combat 是正常的（`combatTier` 三档共用一个类型），出现同一个 `EventId` 两次不是——后者与 `PickMany` 无放回的既有契约同款理由（`content-service.md`）。
- **⑧ 在 ⑦ 之外单列**：Travel 的目的地取自**邻接集合**，那是唯一不经 `AllEnabled()` 的取池（既定例外），不能混进 ⑦ 的内容池抽取。

**RNG 消耗计入 map 子流的 `DrawCount`，照既有纪律持久化**；本管线不新开子流。

### ③ 多条 Active arc 的合并：白名单**取并**、权重**相乘**

`[既有推演]` + `[取向选择]`（白名单那一半，见「仍需用户决定」）

| 字段 | 合并算子 | 缺省 |
|---|---|---|
| `TypeWeights` | **相乘**（Π 各 arc 的系数） | 缺省行 = 1.0，恒等元 |
| `EventWeights` | **相乘**（Π 各 arc 的系数） | 同上 |
| `EventWhitelist` | **非空者取并**；全部为空 = 不收窄 | 空数组 = 不参与 |
| `EnemyPoolScope` | 已定：arc 一侧传**全部 `Active` arc 的集合**（`future-event-service.md`），即已经是取并 | — |
| `LevelBias` | 已定：`systems/balance.md` 的「调制修正（乘性）」；多条 arc 相加后作用于带内权重 | 0 |
| `Tighten` | 逐字段取**更紧**的那一个（本方案不展开，见「前置依赖」） | null |

**权重相乘的三条依据：**

- **恒等元 = 1，缺省不需要特判。** 相加时「不修正」要写 0、「翻倍」要写 +100%——两种语义混在同一个数组里，而 `.tres` 里读不出作者想的是哪一种。相乘时缺省行 1.0 就是「什么也没做」。
- **相加会让两条 arc 的调制互相湮灭。** arc A 写 `+3`、arc B 写 `-3`，合并后 Combat 权重回到基础值 —— 两条剧情线都在「显影」，玩家却什么也感知不到。**这与「排队不丢弃：触发恒定成立，只是延后」正面冲突**：那条纪律的全部目的就是不让一次触发变成「有时不生效」。相乘时 `2.0 × 0.5 = 1.0` 理论上同样可以互相抵消，但正系数下**任一条 arc 单独把某类推高都不会被另一条推成 0**，湮灭是连续的而非全有全无。
- **与赋级带的调制修正逐字同构**（`systems/balance.md` 明写「乘性」）。

**白名单取并的三条依据：**

- **取交在正常内容编排下几乎必然为空。** 两条不同剧情线的 `EventWhitelist` 是两组不相交的 `EventId`——交集为空是常态而非异常。而空候选池在本服务是**坏数据 → `PushError` + 抛**（既定失败语义）。**一次完全正常的内容编排（煞气 arc 与心魔 arc 同时 Active）会把游戏打崩**，这不是一个能接受的算子。
- **取交让一条 arc 能静默取消另一条的强制性**，与「排队不丢弃、触发恒定成立」同一条纪律相抵。取并下每条 arc 的收窄都恒定生效：本批必出这几条线之一。
- **可读性的护栏已经在别处架好了**：`MaxConcurrentSideArcs = 2` 与 `ExclusiveGroup` 正是为「调制是叠加的、多了会变成混合物」而设的两道闸。合并算子不需要**再**承担一次同样的职责。

**取并的代价明写（被接受）：** 多条 arc 同时收窄时，每条的强制性被稀释为「本批必出这些线之一」而非「本批只出我这条线」。**要表达独占，正确形态是 `ExclusiveGroup`**（同组至多一条 Active），那正是它存在的理由；把独占性塞进白名单合并算子等于制造第二个 `ExclusiveGroup`。

**空交集不需要兜底分支，因为不存在取交。** 这是取并顺带买到的第二笔收益：管线上少一条「白名单收窄后候选池为空」的失败路径。

### ④ 批次规模 N：由**篇章级平衡表**掷定；location / 剧本 / 隐藏属性三个候选被结构性排除

`[既有推演]`（排除三个候选） + `[取向选择]`（剩下的形态，见「仍需用户决定」）

**先把提问面收窄——原问句列的四个候选里有三个已经被既有决策排除，不需要用户再裁一次：**

| 候选驱动源 | 结论 | 依据 |
|---|---|---|
| **location** | **排除** | 「location 的框定面 = **两组**字段（承重）」。批次规模会是第三组，直接推翻这条承重定案。且 `LocationData` 明写「在有消费方之前，多余字段是无人读的字段」的克制取向。 |
| **剧本 / `PlotModulation`** | **排除** | 批次规模 = **玩家选择空间的宽窄** = **约束面**。`plot-manager.md` 的判据：落约束面 → **不加字段**。这与 `TravelFullFanoutChance` 被判为「不接受任何按剧情线 / location 的覆盖参数」是**逐字同一条论证**——那一条明写的依据正是「掷定改变的是玩家的选择空间宽窄，落在约束面」。 |
| **隐藏属性** | **排除** | 隐藏属性的输入侧**只有两条既有通道**（调制通道 = `PlotModulation` 六字段；结算输入通道 = outcome 求值），明写「不新增机制、不新增字段」。走调制通道即落回上一行的排除。 |
| **本服务 + 平衡表** | **保留** | 约束面由本服务**独占置位**（`eventPriority` 与 `TravelFullFanoutChance` 两个先例）；可调数值住平衡资源。 |

**建议形态：一张按篇章分格的规模权重表，众数 3，走 map 子流掷定。**

```
N ~ BatchSizeWeights[chapter]        // 平衡资源，五格权重，Σ 归一
```

| chapter | N=1 | N=2 | N=3 | N=4 | N=5 |
|---|---|---|---|---|---|
| **初值（三章暂用同一行，待 ch1 数值标杆专场分格）** | 5% | 20% | **45%** | 22% | 8% |

- **数字是纯经验初值**，与赋级带权重表同款标注（「待 ch1 数值标杆专场回归校准」）。众数 3 由既定的「常态 3」直接给出；两端稀薄使 1 与 5 成为**有记忆点的少见形状**而不是日常。
- **形态与赋级带权重表同构**（一张按情境分格的权重表 + map 子流 + 归一化），实现侧不引入新概念。
- **分格轴取「篇章」是既有的唯一合法分格轴**：`lifeSpanCost` 定价表按「事件类型 × 篇章」分格、经验阈值按篇章重置量纲、`baseMomentum` 按境界放大——篇章是本库节奏旋钮的标准分格维度。
- **不接受任何覆盖参数**（与 `TravelFullFanoutChance` 同款收口）：不给这个口子，就不存在「谁有权用它」。
- **它不与结构性场景冲突，因为那些场景根本不走这张表：**

  | 场景 | N 从哪来 | 状态 |
  |---|---|---|
  | 配额闸门批 | = 邻接数（80%）或 1（20%） | **已定**，`game-progression.md` |
  | `Priority = 1` 收窄批（开局构筑 / 剧情线关键节点） | = 该档条目数，通常 1 | **已定**，`adventure-event/_index.md` |
  | 闸 ② / 闸 ③ 移出条目后 | 少一项，「1 项的批次本就合法」 | **已定**，`future-event-service.md` |
  | **常规批** | **本表掷定** | **本方案** |

**`k` 不需要独立答案 —— 伪码里已经有了。** `future-event-service.md` 明写「Travel 与其余四类一同按 location 的类型修正加权抽取，得槽位数 `k`（`k` 可为 0）」。按上面 ⑥ 的口径，`k` = N 个槽位中类型抽中 Travel 的次数，是 N 与类型分布的**副产品**，不是一个独立旋钮。**「批次规模两端由什么驱动」一答定，`k` 同时收口**——这正是待答清单里那句「它同时决定 `k` 从何而来」的兑现方式。

### ⑤ 条目基础权重：新增 `SelectionWeightGrade` 枚举档 + 平衡表映射

`[既有推演]`

**这是一处被现有文档隐含承诺、但全库没有承载字段的空格。** `systems/common-properties.md` 明写 `AdventureEventData` 不需要 `Rarity`，理由是「**它的出现由权重与优先级控制**」——但**那个权重当前不存在于任何字段上**。`PlotModulation.EventWeights` 是「单条 `AdventureEventData` 的权重**加成**」，加成必须有被加成的基数。⑦ 步的槽内抽取因此写不出来。

**建议：**

```csharp
// AdventureEventData 上新增一格
[Export] public SelectionWeightGrade SelectionWeight { get; set; } = SelectionWeightGrade.Common;

public enum SelectionWeightGrade { Rare, Uncommon, Common }
```

| 档 | 平衡表映射（初值） | 编排语义 |
|---|---|---|
| `Common` | **100** | 缺省；绝大多数条目不填 |
| `Uncommon` | **40** | 有分量的条目，希望它偶尔出现 |
| `Rare` | **12** | 标志性条目，一轮回见到一两次即可 |

- **取枚举档而非裸 `int`，是既有范式的第三个实例**（`ExperienceGrade` / `HiddenStatGrade` 是前两个）：「内容侧不落裸数字、走枚举档 + 平衡表映射」。收益一致——改一张表即可全局调节奏，不必重扫数百个 `.tres`；也避免同类条目在不同作者手里权重漂移。
- **默认值 `Common` ⇒ 内容作者的默认动作是「不填」**，与 `lifeSpanCost` 的定价表默认口径同构。
- **加载期校验：** 枚举天然封闭，无需取值域校验；平衡表映射值 `<= 0` → `PushError`（同 `GrantPoolWeights`「任一档权重为 0 → `PushError`，否则会出现池非空但抽不出来」）。
- **它不与 `Rarity` 的既定排除冲突**：`Rarity` 承载的是**稀有度语义**（跨内容族共用一张 `GrantPoolWeights`、参与置换的稀有度锚定），事件不进那套体系；本档只承载**出现频率**这一个用途，两者不同名不同表。

### ⑥ 「策划 vs 随机」的配比 = 涌现量，不是参数

`[既有推演]` + `[通行做法]`

**建议：不设第三个旋钮，也不设「策划批 / 随机批」这个概念。** 策划性已经由三条既有通道逐级承载：

| 层 | 通道 | 策划度 |
|---|---|---|
| **完全策划** | `eventPriority = 1`（开局构筑事件 · 配额闸门 Travel · Finale 出现条件） | 玩家没有类型层面的选择 |
| **半策划** | `PlotModulation.EventWhitelist`（池收窄）/ `EventWeights`（单条抬权） | 池被剧本框住，仍在池内掷 |
| **加权随机** | 类型分布 × 条目权重 | 上面两层都没作用时的常态 |

- **配比因此是可算的涌现量，不是要拍板的数字。** 用已定数字估一次量级：一轮回约 86–102 个事件（`plot-manager.md` 的文案频次推导），其中完全策划批 ≈ 3 个开局构筑 + 3 个 Finale + 途经各 location 的闸门批（按篇章若干 location 串联计，量级十余次）**≈ 12–20%**；半策划批取决于 Active arc 的密度与白名单覆盖面，剩余为加权随机。**这些是从既有数字推出的量级估计，不是新定的指标**——它的用途是给内容编排一个可核对的靶子。
- **与月圆之夜的对位是形态而非比例。** 月圆之夜的「精心策划」体现在**每个事件条目本身写得像一段剧**，而不是在生成器里预排一条固定序列；本库既定的「事件之间不存在预先编好的前后连边」「剧本树不产出任何事件、不持有任何事件序列（承重）」已经把「预排序列」这条路封死。策划感的落点因此在**内容编写**与**白名单收窄**，不在产出算子。
- **否决为它开一个「策划度」旋钮**：那会是一个改变玩家选择空间的参数，落约束面，且没有任何消费方能说出 0.3 与 0.4 有什么区别——与「在有消费方之前，多余字段是无人读的字段」同款克制。

## 具体形态（可 derive 的落地面）

### 字段与类型

```csharp
// LocationData 上（既有字段，本方案定其内部形态）
[GlobalClass]
public partial class EventTypeModifierData : Resource
{
    [Export] public EventType Type        { get; set; }          // 五值之一
    [Export] public float     Multiplier  { get; set; } = 1.0f;  // 乘性系数；> 0（Travel 行允许 == 0）
}

// PlotModulation 上（既有字段，本方案定其内部形态）
[GlobalClass]
public partial class EventTypeWeight : Resource
{
    [Export] public EventType Type       { get; set; }
    [Export] public float     Multiplier { get; set; } = 1.0f;   // 乘性系数；恒 > 0，不设 Travel 例外
}

[GlobalClass]
public partial class EventWeight : Resource
{
    [Export] public string Id         { get; set; }              // AdventureEventData.Id；加载期校验悬空
    [Export] public float  Multiplier { get; set; } = 1.0f;      // 乘性系数；恒 > 0
}

// AdventureEventData 上（本方案新增一格）
[Export] public SelectionWeightGrade SelectionWeight { get; set; } = SelectionWeightGrade.Common;
public enum SelectionWeightGrade { Rare, Uncommon, Common }
```

> **注：`EventWeight` 现有注释写的是「权重**加成**」。** 本方案取乘性系数，措辞需一并对齐——见「与既有决策的张力」。

### 平衡资源新增两格

| 旋钮 | 形态 | 初值 | 归属 |
|---|---|---|---|
| `BatchSizeWeights` | 按篇章分格，五格权重（N = 1…5） | 5 / 20 / 45 / 22 / 8（三章暂共用一行） | `systems/balance.md` |
| `SelectionWeightGrades` | 三档 → 权重映射 | Rare 12 / Uncommon 40 / Common 100 | `systems/balance.md` |

> 基础类型权重表 `BaseTypeWeights`（五类各一格，按篇章分格）**不在本方案的作用域内**——它的取值归「五类之间的配比，以及 Combat 内 `combatTier` 三档的配比」那条待答项。本方案只定它以**乘性**方式参与运算，以及归一化在何处发生。

### 加载期校验（全部 `PushError` + 定位上下文，接进内容合并后强校验那一遍）

| 违规 | 定位上下文 |
|---|---|
| `EventTypeModifierData.Multiplier <= 0` 且 `Type != Travel` | location `Id` + 类型 |
| `EventTypeModifierData.Multiplier < 0`（Travel 行） | location `Id` |
| 同一 location 的 `EventTypeModifiers` 中某类型出现多行 | location `Id` + 类型 |
| `EventTypeWeight.Multiplier <= 0`（剧本侧，无 Travel 例外） | arc `Id` + 节点 `Id` + 类型 |
| `EventWeight.Multiplier <= 0` | arc `Id` + 节点 `Id` |
| `EventWeight.Id` 悬空（不在 `AdventureEventData` 仓储内） | arc `Id` + 节点 `Id` + 悬空值 |
| `EventWhitelist` 内某 `Id` 悬空 | 同上 |
| `SelectionWeightGrades` 任一档映射值 `<= 0` | 档名 |
| `BatchSizeWeights` 五格全 0，或存在负值，或 N 的支撑集越出 `[1, 5]` | 篇章号 |

### 物化后断言（本方案新增一条，接在既有两条之后）

```
Assert: 1 <= EventOptionBatch.Options.Count <= 5     // PushError + BatchId
```

> 既有断言（`Priority ∈ {0,1}`、`OutcomeSpec != null`、`Encounter` 按真身判）不变。本条是「批次不是固定宽度、区间 1–5」这句约定的可机械检查形态——闸 ②③ 降级后仍须落在区间内，闸门批的规模由出度 ≤ 5 的加载期校验保证不越上界。

### 日志

```
[FutureEvent-Weight] location=<Id> arcs=<n> N=<n> dist=<Combat:.42,Exchange:.18,...> k=<n>
```

一批只在屏幕切换点产出一次，不落任何热路径（与「逐候选条目算一次池计数」同款代价论证）。

## 后果

| 面 | 影响 |
|---|---|
| `systems/services/future-event-service.md` | 「意图」新增一节：十步管线 + 三层叠加顺序的收口（RNG 是消费者不是框定层）；待决问题里的「生成 / 加权规则未定」「框定叠加顺序」两条可整条移出 |
| `systems/game-progression.md` | location 类型修正一行补上运算形态与取值域；待决问题「事件类型概率修正的形态」「location 与 AdventurePlot 调制的叠加顺序」两条移出 |
| `systems/services/plot-manager.md` | `PlotModulation` 三个权重字段补上「乘性 · 恒 > 0」与多 arc 合并算子；`EventWeights` 注释措辞对齐 |
| `systems/adventure-event/common-properties.md` | 批次规模一条补上驱动源；新增 `SelectionWeight` 到共有字段清单 |
| `systems/adventure-event/travel/_index.md` | 待决问题「运算形态」「`k` 从何而来」两条移出 |
| `systems/balance.md` | 新增 `BatchSizeWeights` 与 `SelectionWeightGrades` 两格 |
| **存档 schema** | **不动。** 批已经整批落 `CharacterProfile.eventOption`；权重与规模都是产出侧的中间量，重算不出来的那部分（定稿实例）本就已经在存档里。**无迁移。** |
| **内容资产** | `AdventureEventData` 多一格 `[Export]`，**有默认值 ⇒ 既有 `.tres` 不需要改**（当前存量为零，正处于纯加法窗口） |
| **服务 API 面** | **不动。** 四个方法、`EventOption` / `EventOptionBatch` 的字段面全不变 |

## 备选方案（已考虑并否决）

| 方案 | 否决理由 |
|---|---|
| **类型修正取加性偏移** | 做不到「改权重不改可及性」（软框定的定义）；恒等元是 0 而非 1，缺省要特判；还得裁「负权重怎么办」。 |
| **类型修正取「白名单 + 权重」** | 白名单是**硬**框定，与表上写死的「软」直接冲突；且白名单这条通道已被 `PlotModulation.EventWhitelist` 独占，两处白名单 = 两个权威。 |
| **多 arc 白名单取交** | 正常内容编排（两条不同 arc 各带白名单）交集必然为空 → 落既定的「内容池为空 = 坏数据 → `PushError` + 抛」，一次合法编排把游戏打崩；且让一条 arc 静默取消另一条的强制性，与「排队不丢弃、触发恒定成立」相抵。 |
| **多 arc 白名单按 `Tier` 优先级取最内层一条** | 需要新定一个层级序（Story / Chapter / SideChapter / SideStory 谁压谁），而「出边求值顺序取数组顺序而非优先级字段」的既有偏好正是为了不引出「同优先级怎么办」；且被压掉的那条 arc 的强制性同样静默失效。 |
| **多 arc 权重相加** | 恒等元 0 与「翻倍」语义混在同一数组；两条 arc 的调制可以全有全无地互相湮灭，让一次触发变成「有时不生效」。 |
| **批次规模由 location 驱动**（`LocationData` 加第三格） | 直接推翻「location 的框定面 = 两组字段」这条承重定案。 |
| **批次规模由 `PlotModulation` 驱动**（加第七个字段） | 落约束面 → 按 `plot-manager.md` 的判据「不加字段」；与 `TravelFullFanoutChance` 不可被剧本推拉是逐字同一条论证。 |
| **批次规模由候选池丰度驱动**（池大就多摆几个） | 让玩家能通过观察批次宽度反推内容池状态（可电子表格化优化的一种），且闸 ②③ 的运行期收缩会让批次宽度随 flags 秒关而抖动——玩家会把运营动作读成机制。 |
| **`AdventureEventData` 上放裸 `int` 权重** | 撞「内容侧不落裸数字、走枚举档 + 平衡表映射」的既有范式；且逐条目裸数字必然在多作者间漂移。 |
| **不设条目权重（同类型内等概率）** | 与 `Rarity` 被排除时写下的理由「它的出现由**权重**与优先级控制」直接矛盾；且 `EventWeights` 的「加成」失去基数。 |
| **为「策划 vs 随机」开一个配比旋钮** | 落约束面；且没有消费方能说出 0.3 与 0.4 的差别——「在有消费方之前，多余字段是无人读的字段」。 |

## 与既有决策的张力

1. **`PlotModulation.EventWeights` 的现有注释是「单条 `AdventureEventData` 的权重**加成**」，本方案取乘性系数。**
   - 冲突面：措辞，不是结构。字段类型 / 数量 / 位置全不变。
   - 需要它松动的理由：与 `TypeWeights`、与赋级带的「调制修正（乘性）」保持同一种权重语言；混用加性与乘性会让同一段管线里两个相邻字段语义不同。
   - 松动的代价：`plot-manager.md` 与 `inbox/archive/solution-draft-plot-data-encoding.md` 两处注释需改一个词。
   - **不松动时的替代**：`EventWeights` 保持加性、`TypeWeights` 取乘性——但那样一条 arc 的两个权重字段语义相反，是纯粹的漂移源。**不建议。**

2. **`AdventureEventData` 新增 `SelectionWeight` 是一次内容面字段扩张。**
   - 冲突面：与「不预留无消费方的字段」的克制取向没有实质冲突（它有明确消费方：⑦ 步的槽内抽取），但它确实是本方案唯一新增的内容侧字段。
   - 若用户不接受，退路是「同类型内等概率」，代价见备选方案表最后两行。

3. **「其余四类不得修正到 0」是对内容编排自由度的一次收紧。**
   - 冲突面：内容作者可能想表达「坊市绝不出 Combat」。本方案要求他改用一个极小的正系数（如 0.02）来表达，而不是 0。
   - 代价：极小系数在小批次里与 0 的观感几乎一致，但保住了「软框定 = 不改可及性」这条定义与「加权抽取的分母恒 > 0」这条推论。
   - **若用户希望放开某一类，那是一次真实的裁决**（见「仍需用户决定」第 3 项）。

## 前置依赖

| 依赖项 | 本方案受阻的部分 |
|---|---|
| **五类之间的配比 + Combat 内 `combatTier` 三档配比**（`open-questions/02-event-options.md` 第二条） | `BaseTypeWeights` 的**取值**。本方案只定它参与运算的方式（乘性、归一化位置），**表里填什么不在作用域内**。 |
| **事件条目的篇章 / location 框定载体是否存在**（与 `systems/enemies/_index.md` 待决项「敌人池的篇章框定载体未定」同源） | 管线第 ① 步当前只有 `AllEnabled()`。若事件也需篇章框定，① 步要多一层过滤，且闸 ② 的池计数口径要跟着改。**这一条不阻塞本方案的算子形态，只影响 ① 步的具体过滤链。** |
| **ch1 数值标杆专场** | `BatchSizeWeights` 与 `SelectionWeightGrades` 的取值是纯经验初值，须回归校准。 |
| **`eventCountLimit` 能否被剧本调制**（同分片第五条） | 影响闸门批的出现频率，进而影响「完全策划批占比」那个估算。**不阻塞算子。** |
| **`EncounterTighten` 的字段面** | ③ 小节表里 `Tighten` 一行写的是「逐字段取更紧」，具体形态待该类型落笔。**不阻塞其余五个字段的合并算子。** |
| **`Priority = 1` 依什么条件抬升**（同分片第六条，本批 W2-B 分片在处理） | 决定「完全策划批」这一层还有哪些成员。**不阻塞管线，只影响 ⑥ 小节的配比估算。** |

## 仍需用户决定 → **已全部裁决（2026-08-22 · 批量评审）**

> 逐条裁决（`/batch-provide-solution-draft` 合并 interview）：
> 1. 多条 `Active` arc 的 `EventWhitelist` 合并算子 → **已裁决：A · 非空者取并**
> 2. 常规批的批次规模 N 由什么给出 → **已裁决：A · 按篇章分格的规模权重表掷定**（`k` 随之收口为其副产品）
> 3. Travel 之外的四类能否被 location 修正到 0 → **已裁决：A · 不允许（系数 `> 0`）**
> 4. 条目基础权重的承载形态 → **已裁决：A · `SelectionWeightGrade` 三档枚举 + 平衡表映射**
>
> 另：跨分片裁定「篇章框定层保留，`AdventureEventData` 与 `EnemyData` 两侧同形 `ChapterScope : int[]`（空 = 不限）」——即本稿「前置依赖」中「事件条目的篇章框定载体是否存在」一条已答定，管线第 ① 步的过滤链据此落笔。详见 `solution-draft-enemy-pool-chapter-scoping.md`。


### 1. 多条 `Active` arc 的 `EventWhitelist` 如何合并

| 选项 | 后果 |
|---|---|
| **A · 非空者取并**（推荐） | 每条 arc 的收窄都恒定生效；候选池不会因合并而为空 ⇒ 管线少一条失败路径。**代价：** 多条 arc 同时收窄时，每条的强制性稀释为「本批必出这些线之一」，要表达独占须改用 `ExclusiveGroup`。 |
| B · 取交 | 单条 arc 的强制性最强。**代价：** 两条不同 arc 的白名单交集在正常编排下必然为空 → 落「内容池为空 = 坏数据 → `PushError` + 抛」，一次合法编排把游戏打崩；且一条 arc 能静默取消另一条。必须额外发明一条「空交集则回退取并」的兜底分支。 |
| C · 按 `Tier` 层级取最内层一条 | 语义清晰、不会为空。**代价：** 要新定一个层级压制序（与「出边取数组顺序而非优先级字段」的既有偏好反向）；被压掉的 arc 的强制性静默失效，同样违反「触发恒定成立」。 |

**推荐 A。理由：** 它是唯一不引入「合法编排导致崩溃」或「触发静默失效」的选项；而「多条 arc 同时强制会互相稀释」这个担忧，既有的 `MaxConcurrentSideArcs = 2` 与 `ExclusiveGroup` 两道闸已经在管，合并算子不必再管一次。

### 2. 常规批的批次规模 N 由什么给出

| 选项 | 后果 |
|---|---|
| **A · 按篇章分格的规模权重表掷定**（推荐，众数 3，1–5 五格） | 与赋级带权重表同构；篇章是本库既有的标准分格轴；1 与 5 成为少见但有记忆点的形状。**代价：** 批次宽度是随机的，玩家无法预期下一屏摆几个。 |
| B · 常规批恒为 3，只有结构性场景才偏离 | 最简单，实现零随机；1–5 区间由闸门批（出度）与闸 ②③ 降级独占。**代价：** 「批次不是固定宽度、产出侧要按批给出数量」这条定案退化为「除了三种特例都是常数」，且 N=4 / N=5 在常规批里永不出现——上界 5 只被闸门批用到。 |
| C · 三章递增的定值（如 3 / 3 / 4） | 无随机、有篇章节奏差异。**代价：** 同 B，仍不产生 1 与 5；且「第三章批次更宽」需要一个设计理由，本库当前给不出。 |

**推荐 A。理由：** 定案原文明写「**批次不是固定宽度**——产出侧要按批给出数量，不能套一个常数」，B 与 C 实质上都是套常数；且 A 复用一张已经存在的表形态，实现侧不引入任何新概念。**但这一项确实是取向**——若你希望批次宽度对玩家可预期（竖屏一屏容下 1–5 个选项的排布问题本就是同分片另一条待答项），B 是更省心的答案。

### 3. Travel 之外的四类，是否也允许被 location 修正到 0

| 选项 | 后果 |
|---|---|
| **A · 不允许（系数 `> 0`）**（推荐） | 「软框定 = 改权重不改可及性」这条定义保持无例外；归一化分母恒 > 0；「某地域完全不出某类」由极小正系数近似表达。 |
| B · 允许任意类修正到 0 | 内容编排更自由（「坊市绝不出 Combat」可直写）。**代价：** location 那一行不再是软框定，表上的「软 / 硬」两列失去意义；且需要逐类回答「修正到 0 会不会造成死锁」（Research 是构筑的唯一落点，某地域完全不出 Research 是真实的构筑剥夺）。 |
| C · 逐类白名单式放开（例如只放开 Exchange / Explore） | 折中。**代价：** 引入一张「哪些类允许为 0」的表，而这张表没有可推演的判据——只能逐类拍板，且日后每加一类都要重拍一次。 |

**推荐 A。理由：** Travel 的例外之所以成立，是因为它有一条**独立的可及性通道**（配额闸门）；其余四类没有任何这样的通道，把它们的权重按到 0 就是真的把它们从该地域移除。若你确实想要 B，最小的安全形态是**只放开没有结构性职责的类**（Explore / Exchange），并为它加一条加载期校验：不得使某 location 的可及类型数少于 2。

### 4. 条目基础权重的承载形态

| 选项 | 后果 |
|---|---|
| **A · `SelectionWeightGrade` 三档枚举 + 平衡表映射**（推荐） | 与 `ExperienceGrade` / `HiddenStatGrade` 同款范式；改一张表全局调节奏；默认 `Common` ⇒ 作者默认不填。**代价：** 只有三档粒度，想要「比 Common 稍低一点」写不出来（退让位：加第四档，纯内容侧改动）。 |
| B · 裸 `int` 权重（默认 100） | 粒度无限。**代价：** 撞「内容侧不落裸数字」的既有范式；多作者间必然漂移；无法用一张表全局调。 |
| C · 不设字段，同类型内等概率 | 零新增字段。**代价：** 与 `Rarity` 被排除时写下的理由「出现由**权重**与优先级控制」矛盾；`EventWeights` 的「加成」失去基数；标志性条目与灌水条目同频出现。 |

**推荐 A。理由：** 它是本库已经用过两次的形态，且是唯一同时满足「不落裸数字」与「`EventWeights` 有基数可加成」两条的选项。

---

**四项之外的一切**（乘性算子、多 arc 权重相乘、十步管线顺序、RNG 是消费者不是框定层、`k` 是 N 的副产品、Travel 行可为 0、加载期校验清单、断言 `1 <= Count <= 5`）**均为 `[既有推演]`**，不需要你逐条点头——但若其中任何一条读起来与你的意图不符，它们同样可以被推翻。
