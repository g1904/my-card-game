# eventOptions 的生成 / 加权运算形态

- id: 2026-08-22-event-generation-weighting-pipeline
- date: 2026-08-22
- topic: systems/services/future-event-service · systems/game-progression · systems/services/plot-manager · systems/adventure-event/common-properties · systems/adventure-event/travel · systems/balance
- status: distilled
- distilled-to: systems/services/future-event-service.md, systems/game-progression.md, systems/services/plot-manager.md, systems/adventure-event/common-properties.md, systems/adventure-event/travel/_index.md, systems/balance.md

## Intent（distilled）

**一句话：** 把 `future-event-service.ComputeEventOptions` 那段从未写下来的算术定死——**类型修正 = 乘性系数（支撑集不变）· 三层框定 = 一条十步管线（seeded RNG 是消费者不是框定层）· 多条 `Active` arc 的白名单取并 / 权重相乘 · 批次规模 N 由按篇章分格的 `BatchSizeWeights` 掷定（`k` 随之成为其副产品）· 条目基础权重落 `SelectionWeightGrade` 三档枚举 + 平衡表映射**，并配齐取值域、加载期校验、物化后断言与日志。

### 1. 类型修正 = 乘性系数，作用于归一化前的权重；支撑集不变

```
w_type(t) = BaseTypeWeights(t) × LocationMod(t) × Π_arc PlotTypeMod(arc, t)
P(t)      = w_type(t) / Σ_t' w_type(t')
```

- location 那一行的定义就是「**软**（改权重，不改可及性）」——加性偏移做不到（一个大负偏移把权重按到 0 或负，可及性没了），「白名单 + 权重」本身就是**硬**框定且与 `PlotModulation.EventWhitelist` 撞权威。只有正的乘性系数天然满足「改权重不改支撑集」。
- 与赋级带已定的「调制修正（乘性，只改权重不改支撑集）+ 截断重分配」逐字同构：同一段物化管线、同一个 map 子流、同一批调制源不能有两套权重语义。
- **乘法可交换 ⇒「location 与 arc 谁先」不是需要裁决的量。**「叠加顺序」这一问在类型权重那一半自动收口。
- **取值域：** location 的 Combat / Exchange / Research / Explore 四行 `> 0`，Travel 行 `>= 0`（0 = 该地域常规不出 Travel，闸门通道不受影响）；剧本侧 `EventTypeWeight.Multiplier` 与 `EventWeight.Multiplier` 恒 `> 0`，**不设 Travel 例外**（剧本要表达「这一段不出某类」的正确形态是 `EventWhitelist`）。
- **推论：归一化分母恒 > 0**，「加权抽取抽不出东西」在类型层不存在；类型层的空只可能来自收窄后该类型没有条目。

### 2. 三层框定 = 一条十步管线，适用范围 = 常规批

`seeded RNG 根本不与前两层并列`——location 与 `PlotModulation` 是**框定**（改支撑集与权重），map 子流是**消费者**（在已定形的分布上掷）。写成第三层会让人以为存在「RNG 先于框定」的形态，而那形态不存在。

十步：① 取池（`AllEnabled()` → `ChapterScope` 命中当前篇章）· ② 白名单取并收窄 · ③ 条目级闸（闸 ② + Explore 壳过滤）· ④ 类型分布归一 · ⑤ N 掷定 · ⑥ 类型指派（有放回，按各类型可用条目数封顶）· ⑦ 条目无放回抽取 · ⑧ Travel 段 · ⑨ 逐项物化 · ⑩ 收缩保底 + 断言。

- **管线仅描述常规批。** 闸门批在 ① 之前短路（既有 Travel 段伪码）；`Priority = 1` 收窄批走既有规则。
- **满级后的 Finale 条目是管线之前的闸门式旁路**（恒进候选池、直接占一个槽位、不参与类型加权），见下方 Clarifications。

### 3. 多条 `Active` arc 的合并算子

| 字段 | 算子 | 缺省 |
|---|---|---|
| `TypeWeights` / `EventWeights` | **相乘** | 1.0（恒等元） |
| `EventWhitelist` | **非空者取并**；全部为空 = 不收窄 | 空数组 |
| `EnemyPoolScope` | 取并（既定） | — |
| `LevelBias` | 相加 | 0 |
| `Tighten` | 逐字段取更紧 | null |

相乘的三条理由：恒等元是 1 ⇒ 缺省不需特判 · 相加会让两条 arc 的调制全有全无地互相湮灭（与「排队不丢弃、触发恒定成立」相抵）· 与赋级带的调制修正同构。
取并的三条理由：取交在两条不相交白名单下必然为空 → 落既定的「内容池为空 = 坏数据 → `PushError` + 抛」，一次合法编排把游戏打崩 · 取交让一条 arc 静默取消另一条的强制性 · 可读性的护栏已由 `MaxConcurrentSideArcs = 2` 与 `ExclusiveGroup` 架好。**要表达独占用 `ExclusiveGroup`，不要把独占性塞进合并算子。**

### 4. 批次规模 N

- **N 由按篇章分格的 `BatchSizeWeights` 掷定**（五格 N=1…5，初值 5/20/45/22/8，三章暂共用一行，走 map 子流）。location / `PlotModulation` / 隐藏属性三个候选被结构性排除（location 框定面 = 两组字段 · 规模落约束面而 PlotManager 不调约束 · 隐藏属性输入侧只有两条既有通道）。
- **N 是目标槽位数，不是产出数量。** 实际输出允许少于 N（Travel 20% 档、闸 ③ 降级），只保底 `Count >= 1`。
- **`k` = N 个槽位中抽中 Travel 的次数**，是 N 与类型分布的副产品，不是独立旋钮。

### 5. 条目基础权重 `SelectionWeightGrade`

`AdventureEventData` 新增一格 `SelectionWeight : SelectionWeightGrade`（`Rare / Uncommon / Common`，默认 `Common`）+ 平衡表 `SelectionWeightGrades` 映射（12 / 40 / 100）。它是「内容侧不落裸数字、走枚举档 + 平衡表映射」的第三个实例（前两个是 `ExperienceGrade` / `HiddenStatGrade`），并补上了 `Rarity` 被排除时所承诺的那个「权重」——此前全库没有承载字段。

### 6. 「策划 vs 随机」不设旋钮

策划度由三条既有通道逐级承载（`eventPriority = 1` / `EventWhitelist` + `EventWeights` / 加权随机），是可算的**涌现量**而非要拍板的数字。「预排序列」这条路已被「剧本树不产出任何事件、不持有任何事件序列」封死；策划感的落点在内容编写与白名单收窄，不在产出算子。

## Clarifications（interview 产物）

- **批次规模 N 的语义，以及收缩到 0 怎么办**（草稿断言注写「闸 ②③ 降级后仍须落在区间内」，该句在三条收缩路径下都不成立）→ **裁决：N = 目标槽位数 + 收缩保底。** 实际输出允许少于 N，只保底 `Count >= 1`；**收缩到 0 时补一个 Travel，走既有死局兜底通道**，并**明写这不是单项补位**——不重新取池挑条目，只走那条恒可产出的通道。断言 `1 <= Count <= 5` 保留且保底路径显式化。这推翻了草稿「降级后仍落在区间内」的自证。
- **类型指派有放回 / 条目抽取无放回 ⇒ 槽位落空**（草稿只论证了「空类型退出分母」）→ **裁决：⑥ 步按各类型收窄后的可用条目数封顶**（抽满一类即移出分布并重新归一）。理由：允许落空会从后门重新引入草稿自己否决的「玩家可从批次宽度反推内容池状态」。
- **`PlotModulation.EventWeights` 的既有注释是「权重加成」，本方案取乘性系数** → **裁决：松动既有措辞，与 `TypeWeights` 统一为乘性系数。** 改的是措辞，字段类型 / 数量 / 位置全不变。
- **`AdventureEventData.ChapterScope` 的事件侧校验与断言未定** → **裁决：照抄敌人侧处置 + 另加事件侧启动期断言，粒度取 `(chapter, EventType)`。** 依据：「坏数据必须在启动期大声失败」；`ChapterScope` 一旦落地，「第二章没有任何 Explore 条目」就成了一种可静默编排出来的坏数据。
- **`eventType == Travel` 的条目豁免 `ChapterScope`**（来自敌人池分片的合并裁决）→ **裁决：Travel 一类的 `ChapterScope` 必须为空，加载期 `PushError`。** Travel 是**结构性通道而非内容**（与「Travel 不计入 `eventCountLimit`」「Travel 的 outcome 不得含 `LifeSpan` 产出」同族）；不豁免则某章无命中的 Travel 条目时闸门批产不出选项，「Travel 兜底恒可产出 ⇒ 无轮回死锁」这条承重结论当场失效。
- **十步管线的适用范围未标注** → **裁决：管线 = 常规批专用，闸门批在 ① 之前短路。** 既有 Travel 段伪码是承重文本，把闸门批塞进同一条管线等于无必要地重写它，且会模糊「邻接集合不经 `AllEnabled()`」这条明写的例外关系。
- **`SelectionWeight` 落哪一份文档** → **裁决：落 `adventure-event/common-properties.md`。** 挂载面按「五个事件子类型」算 —— `eventPriority` 与 `lifeSpanCost` 同样只挂在 `AdventureEventData` 一个类上，却都住在那里，本库既有的读法就是按事件子类型算挂载面。
- **满级后 Finale 条目如何进批**（连带输入，来自「`Priority = 1` 抬升条件」分片）→ **裁决：写成闸门式旁路，不写成高权重。** 在类型加权抽取之前判定，命中则该条目直接占一个槽位、不参与类型加权。理由：加权只能提高概率，而抬升需要的是必现；旁路形态同时封堵「剧本把 Combat 排除出白名单即间接封死篇章推进」这条 PlotManager 越权面。

## Open questions

- **五类之间的配比（`BaseTypeWeights` 的取值），以及 Combat 内 `combatTier` 三档的配比。** 本次只定它以乘性方式参与运算、归一化在类型分布层发生；**表里填什么仍开放**。
- **`BatchSizeWeights` 与 `SelectionWeightGrades` 的取值是纯经验初值**，随 ch1 数值标杆专场回归校准。
- **`EncounterTighten` 的字段面全库未定** ⇒ `plot-manager.md` 新增的合并算子表里 `Tighten` 一行只能写「逐字段取更紧」。

## Notes / triage

- 本次一并清理了同一个问题在全库的五份副本（`future-event-service.md`「生成 / 加权规则未定」+「框定叠加顺序」· `game-progression.md` 两条 + 第 174 行那条的两半 · `adventure-event/common-properties.md`「可用事件的生成规则」· `travel/_index.md` 两条 · `plot-manager.md`「多条 `Active` arc 的 `PlotModulation` 如何合并」）。
- `AdventureEventData.ChapterScope` 的**敌人侧对位**（`EnemyData.ChapterScope`）由敌人池分片落笔，本次不动 `systems/enemies/*`。
- `systems/common-properties.md` 不改：`Rarity` 对 `AdventureEventData` 的排除原样成立（本次落的是 `SelectionWeight`，不同名不同表）。
- 事件类型档案 `content/adventure-event/` 尚未开张，故 `SelectionWeight` / `ChapterScope` 在内容层没有回填面；开张时（`/scaffold-content-type adventure-event`）须把这两格纳入字段核对清单。
