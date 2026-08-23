# Answer log future-event-generation-weighting

- 日期：2026-08-22
- 来源：`inbox/solution-draft-future-event-generation-weighting.md` → `handoffs/2026-08-22-event-generation-weighting-pipeline.md`
- 移出条数：1（另有 1 条部分答定、仍留在待答清单）

## 移出

**`open-questions/02-event-options.md` — 「生成 / 加权规则与叠加顺序（08-05b 收窄 · 08-15c 再收窄）」** → 整条答定：

- **类型修正 = 乘性系数**，作用于归一化前的权重、支撑集不变；location 侧 Travel 行 `>= 0`、其余四类 `> 0`，剧本侧恒 `> 0` 且不设 Travel 例外。（归档去向：`systems/game-progression.md`、`systems/services/plot-manager.md`）
- **叠加顺序 = 一条十步管线，适用范围 = 常规批**（闸门批在第 ① 步之前短路）；**seeded RNG 是消费者不是并列的第三层框定**；**乘法可交换 ⇒ location 与 arc 的先后不是需要裁决的量**。（归档去向：`systems/services/future-event-service.md`）
- **多条 `Active` arc 的合并算子**：`TypeWeights` / `EventWeights` **相乘** · `EventWhitelist` **非空者取并** · `EnemyPoolScope` 取并 · `LevelBias` 相加 · `Tighten` 逐字段取更紧。（归档去向：`systems/services/plot-manager.md`）
- **批次规模 N 由按篇章分格的 `BatchSizeWeights` 掷定**（五格 N=1…5，初值 5/20/45/22/8）；location / `PlotModulation` / 隐藏属性三个候选被结构性排除。**N 是目标槽位数而非产出数量**，实际输出允许少于 N，收缩到 0 时补一个 Travel（走既有死局兜底通道，**不是单项补位**）。**`k` 是 N 与类型分布的副产品，不是独立旋钮**。（归档去向：`systems/adventure-event/common-properties.md`、`systems/adventure-event/travel/_index.md`、`systems/balance.md`）
- **条目基础权重 = `AdventureEventData.SelectionWeight : SelectionWeightGrade`**（`Rare / Uncommon / Common`，默认 `Common`）+ 平衡表 `SelectionWeightGrades` 映射（12 / 40 / 100）。（归档去向：`systems/adventure-event/common-properties.md`、`systems/balance.md`）
- **「策划 vs 随机」的配比 = 涌现量，不设旋钮**（策划度由 `Priority = 1` / `EventWhitelist` + `EventWeights` / 加权随机三条既有通道逐级承载）。（归档去向：`systems/services/future-event-service.md`）

## 部分答定（仍留在待答清单）

**`open-questions/02-event-options.md` — 「五类之间的配比，以及 Combat 内 `combatTier` 三档的配比」** → **运算形态已定**（`BaseTypeWeights` 以乘性方式参与、归一化在类型分布层发生）；**本条只欠取值**，仍开放。

## 本次连带定下（不属上述条目，来自合并 interview）

- `AdventureEventData.ChapterScope : int[]` 的**事件侧**取值域、加载期处置与 `(chapter, EventType)` 启动期断言。（`systems/adventure-event/common-properties.md`）
- **`eventType == Travel` 的条目豁免 `ChapterScope`**（必须为空，加载期 `PushError`）。（同上 + `travel/_index.md`）
- **满级后 Finale 条目走闸门式旁路**（恒进候选池、直接占一个槽位、不参与类型加权）。（`systems/services/future-event-service.md`）
