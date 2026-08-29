# ② eventOptions 生成流程（焦点）

> 本分片属 `../open-questions.md` 的当前焦点区。

- **五类之间的配比，以及 Combat 内 `combatTier` 三档的配比（08-15c 新增 · 08-22 收窄）。** 一段修行历程中五类事件的分布权重、由 location 与 AdventurePlot 如何调制未定；**Combat 内部另有一层**——每篇章一个 `Finale` 已定，`Practice` 与 `Standard` 的比例未定。**运算形态已定**（`BaseTypeWeights` 以乘性参与、归一化在类型分布层发生），本条只欠取值。→ `systems/adventure-event/_index.md`、`systems/balance.md`。
- **`lifeSpanCost` 定价表的 Explore 行取值（08-16e 新增 · 轻）。** Explore 自成一行、不由真身推导、条目不得覆盖**已答定**；仍待定**该行填多少**（留待内容扩充后的统计校准）。→ `systems/balance.md`、`systems/adventure-event/explore/_index.md`。
- **`LocationCodex` 的词条深度与呈现形态（08-06c 收窄 · 承重那半已答结）。** **显影粒度已定案**（顶点级：去过 A 即显影 A 的全部邻接，连边由呈现层现算、存档零增量）；仍待定：除连边外词条还写什么（风物文案 / 事件类型倾向 / 敌人清单 / `EventCountLimit`），以及它不同于其余五本的呈现形态（一张逐步显影的图 vs 列表 / 网格）。→ `systems/player-profile/codex/_index.md`、`ux/screen-flow.md`。
- **选择区的呈现与导航手感（本次归集 · 此前未进清单）。** 进程形态已定为**逐批择一的线性推进**（月圆之夜式菜单 + 横向滑动选择，**不是**可俯瞰、可回溯的分支地图）；仍待定：每批的**选项排布与滑动手感**、竖屏下如何在同一屏容下 1–5 个选项（批次规模区间是 1–5，两端差 5 倍）、以及寿元告警的静态标注如何嵌进这套排布。→ `systems/game-progression.md`、`ux/screen-flow.md`。
