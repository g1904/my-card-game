# ② eventOptions 生成流程（焦点）

> 本分片属 `../open-questions.md` 的当前焦点区。

> 已答结并移出（09-06）：**五类事件配比与 `combatTier` 三档配比** —— `BaseTypeWeights` 五格初值 0.35 / 0.13 / 0.13 / 0.32 / 0.07（三章同值仍写三行）；`Practice : Standard = 1 : 1` 三章统一，为内容编排口径而非运行期旋钮；载体 `BaseTypeWeightsData`；调制只补编排建议区间。权威在 `systems/balance.md`「`BaseTypeWeights`」条目，见 `../answer-logs/log-event-type-mix-ratios.md`。

- **事件类型配比的实测校准复核（09-07 归集 · 配比初值已于 09-06 答结移出，留下的是校准尾巴）。** 五格初值与 `Practice : Standard = 1 : 1` 均已定案；仍待定的是实测校准，且**校准对象是实现分布**（供给 × 玩家偏好）而非供给分布——实测须同时记录「供给了什么」与「选了什么」，用比值反推偏好后再调供给分布，不为此加任何机制。另两个前置：ch2 / ch3 的逐类型参考构成补齐后「三章同值」须复核；1:1 的校准依赖 Combat 条目池铺开。→ `systems/balance.md`、`systems/services/future-event-service.md`。
- **`LocationCodex` 的词条深度（08-06c 收窄 · 呈现形态那半已答结）。** **显影粒度已定案**（顶点级：去过 A 即显影 A 的全部邻接，连边由呈现层现算、存档零增量）；**浏览形态的五层套用亦已定案**（入口 / 索引格 / 完成度口径 / 文案分区 / 触控纪律与其余六本同形，只有单本页的内容区不套用）。仍待定：除连边外词条还写什么（风物文案 / 事件类型倾向 / 敌人清单 / `EventCountLimit`），以及随之待定的**单本页内容区如何画那张图**（缩放 / 平移 / 顶点布局）与**词条载体**（全屏页 vs 半屏 sheet）。→ `systems/player-profile/codex/_index.md`、`ux/screen-flow.md`。
