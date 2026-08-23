# ② eventOptions 生成流程（焦点）

> 本分片属 `../open-questions.md` 的当前焦点区。

- **五类之间的配比，以及 Combat 内 `combatTier` 三档的配比（08-15c 新增 · 08-22 收窄）。** 一段修行历程中五类事件的分布权重、由 location 与 AdventurePlot 如何调制未定；**Combat 内部另有一层**——每篇章一个 `Finale` 已定，`Practice` 与 `Standard` 的比例未定。**运算形态已定**（`BaseTypeWeights` 以乘性参与、归一化在类型分布层发生），本条只欠取值。→ `systems/adventure-event/_index.md`、`systems/balance.md`。
- **`HiddenStatDirection` 不设 `Unset = 0` 哨兵 —— `[采纳推荐 — 待复核]`（08-22 新增 · 轻）。** 已按「二值封闭，依 `OutcomeRule.Direction` 全库无哨兵的先例」落笔。已知代价：内容作者忘填 `Direction` 会静默落成枚举 0 值 `Raise`，而 `Raise` 对煞气（累积物、以上行为主）恰是常见方向，比一般字段更难在测试中显形。待用户复核。→ `systems/architecture.md`。
- **`HiddenStatGrants` 的校验 9（`Stat == LifeSpan` → `PushError`）—— `[采纳推荐 — 待复核]`（08-22 新增 · 轻）。** 已按「拒绝」落笔，堵住绕过 `lifeSpanCost` 定价表 / 回寿量表与 Travel 回寿禁令的书写出口（现行校验 6 只覆盖 `OutcomeRule` 两侧，看不见 `HiddenStatGrants`）。它收窄了一个既有字段的取值域；若日后确想让事件以档位口径推寿元，须先翻此条。待用户复核。→ `systems/adventure-event/common-properties.md`。
- **`HiddenStatGrant.Stat` 保持宽类型、以加载期校验收窄 —— `[采纳推荐 — 待复核]`（08-22 新增 · 轻）。** 已按 `OutcomeRule.PoolKind` + 校验收窄的既有先例落笔（类型仍是 `HiddenStat`，校验限定为 `{ Faith, Bloodlust }`），不新开 `PushableHiddenStat` 子枚举。待用户复核。→ `systems/architecture.md`、`systems/adventure-event/common-properties.md`。
- **`GrantFromPool` 不加加载期池断言 —— `[采纳推荐 — 待复核]`（08-22 新增 · 轻）。** 已按「不加闸①、短缺时物化期降级 + `PushWarning`」落笔；待用户复核。→ `systems/services/future-event-service.md`。
- **`OutcomeRule` 不支持多选一 / 加权掷一条 —— `[采纳推荐 — 待复核]`（08-22 新增 · 轻）。** 已按「一条规则一条产出」落笔；待用户复核。→ `systems/adventure-event/common-properties.md`。
- **三条抬升子判据作为准入闸的密度成本 —— `[采纳推荐 — 待复核]`（08-22 新增）。** `Priority = 1` 的抬升判据（唯一出口 / 产出侧可确定判定 / 表达结构而非难度叙事）已按推荐写进本服务作为准入闸；待用户复核这条纪律是否值得加。→ `systems/services/future-event-service.md`。
- **`lifeSpanCost` 定价表的 Explore 行取值（08-16e 新增 · 轻）。** Explore 自成一行、不由真身推导、条目不得覆盖**已答定**；仍待定**该行填多少**（归 ch1 数值标杆专场）。→ `systems/balance.md`、`systems/adventure-event/explore/_index.md`。
- **`LocationCodex` 的词条深度与呈现形态（08-06c 收窄 · 承重那半已答结）。** **显影粒度已定案**（顶点级：去过 A 即显影 A 的全部邻接，连边由呈现层现算、存档零增量）；仍待定：除连边外词条还写什么（风物文案 / 事件类型倾向 / 敌人清单 / `EventCountLimit`），以及它不同于其余五本的呈现形态（一张逐步显影的图 vs 列表 / 网格）。→ `systems/player-profile/codex/_index.md`、`ux/screen-flow.md`。
- **`LocationCodex` 边缘顶点显示程度与显影半径 —— `[采纳推荐 — 待复核]`（08-22 新增 · 轻）。** 已按「真实地名 + 灰态 + 词条锁着」与「显影半径固定 1 跳、不设旋钮」落笔；纯呈现层旋钮、可逆、不影响存档，待用户复核。→ `systems/player-profile/codex/_index.md`。
- **「`eventCountLimit` 不可调制」只约束剧本层、overlay 照常可改 —— `[采纳推荐 — 待复核]`（08-22 新增）。** 主问已拍板：`PlotModulation` 不加第七字段。待复核的是这条结论的**边界**——`EventCountLimit` 是否仍是一格普通内容字段（overlay 改值下次冷启动生效），使「把问题地域配额压到 1」这条运营通道候选保持开着；替代取向是连 overlay 也视为不可动（时长反推更稳，但失去唯一一条不改图就能软化问题地域的运营手段）。→ `systems/game-progression.md`、`systems/services/content-service.md`。
- **选择区的呈现与导航手感（本次归集 · 此前未进清单）。** 进程形态已定为**逐批择一的线性推进**（月圆之夜式菜单 + 横向滑动选择，**不是**可俯瞰、可回溯的分支地图）；仍待定：每批的**选项排布与滑动手感**、竖屏下如何在同一屏容下 1–5 个选项（批次规模区间是 1–5，两端差 5 倍）、以及寿元告警的静态标注如何嵌进这套排布。→ `systems/game-progression.md`、`ux/screen-flow.md`。
- **`lifeSpanCost` 一律定值 —— `[采纳推荐 — 待复核]`（08-17 新增 · 轻）。** 形态已定为非负整数定值（不带区间、不带公式），定价表因此不设区间列。否决区间旋钮的两条理由——Band 0 / Band 1 不显示 `selectCost` ⇒ 方差对玩家不可感知；区间会损害时长旋钮的反推精度——**成立与否待实测复核**。若复核推翻，改动面是模板侧两个字段 + 一次掷定 + 一条校验 + 定价表反推口径。→ `systems/adventure-event/common-properties.md`、`systems/balance.md`。
