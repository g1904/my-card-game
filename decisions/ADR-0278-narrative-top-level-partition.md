# ADR-0278 — 新建顶层 `narrative/` 分区：世界观与叙事的内部事实源，不是玩家可见面

- **状态：** Accepted
- **日期：** 2026-09-12
- **来源：** handoffs/2026-09-12-series-packaging-and-narrative.md · answer-logs/log-monetization-packaging-and-narrative.md

## 背景

碎片化 lore 一旦开始铺，就会产生一类此前无处安放的知识：地名、宗门、世界事件的先后、角色之间的暗线关系。它既不是机制类定义（`systems/`）也不是条目实例（`content/`），而是写条目时**要先查**的上游事实。没有落点意味着两个角色的事件会互相矛盾，同一个地名在两条剧本线里会是两回事，而本库没有任何机制能发现这种不一致。

## 决策

**新建顶层 `narrative/` 分区**，与 `vision/` · `systems/` · `content/` · `art/` · `ux/` 平级。

**承载四类：** 世界观设定 · 时间线 · 人物关系 · 碎片台账（哪条 lore 撒在哪个事件 / 剧本节点上，用于反查与去重）。

**它是内部事实源，不是玩家可见面。** 玩家永远看不到这里的任何一份文档 —— 本作不做设定集、不做 lore 图鉴、不做任何可回看的档案面。

分区职责、叙事纪律与跨分区关系表的权威在 `narrative/_index.md`（**本 ADR 不复述**）。

## 理由

`narrative/_index.md`：它是 `systems/` 与 `content/` **共同的上游** —— 写一条剧本 arc、一个事件、一个角色背景时先来这里查世界观事实。放进任何一侧都会让另一侧反向依赖。

不并入 `vision/`：`vision/` 的三份是「保持简短稳定」的裁决基准文档，性格与**持续变长**的 lore 台账相反。叙事会随内容滚动增长，给它自己的分区不会挤压其他区。

不并入 `content/`：条目文档写正文时**查**这里的事实，且条目不复述世界观设定、需要时回链本分区 —— 这正是 `decisions/ADR-0005-knowledge-thin-reference-layer.md` 的副本判据在叙事侧的应用。

## 备选方案

- **并入 `vision/`** — 否决：`vision/` 要短且稳，lore 台账要长且滚动。
- **并入 `content/`** — 否决：它是 `content/` 的上游而非同层，条目要查它。
- **并入 `systems/services/plot-manager.md`** — 否决：那里管剧本的**机制**（arc / node、激活、调制、校验），本分区管**写什么**。
- **不建分区，lore 散在各条目里** — 否决：没有可核对的底稿，交叉与去重无从谈起。

## 后果

- 连带两处结构登记同改：`README.md` 的文件夹图例加一行、`.claude/rules/design-library-routing.md` 的两库结构差异表加一行（该表明写两库结构变更时须同改）。
- **仍未定：** 本分区的**内部结构与文档清单** —— 本条只定「建它、放什么类东西」，切成几份文档留给首次建区时按实际底稿量决定。
- 本分区承载的叙事纪律进一步落成三条独立决策：`decisions/ADR-0279-lore-ephemeral-in-cycle-only.md` · `decisions/ADR-0280-lore-cold-fragmentary-documentary-voice.md` · `decisions/ADR-0281-story-crossover-implicit-only.md`。
