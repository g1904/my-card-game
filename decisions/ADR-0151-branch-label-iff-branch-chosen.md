# ADR-0151 — `BranchLabel` 非空 ⟺ `Condition.Kind == BranchChosen`（加载期焊死）

- **状态：** Accepted
- **日期：** 2026-09-02
- **来源：** handoffs/2026-09-02-plot-branch-choice-ui.md

## 背景

`PlotEdge` 上有两格各自表达一件事：`BranchLabel` 非空 =「这条边对玩家可见」，`Condition.Kind == BranchChosen` =「这条边等玩家选」（`decisions/ADR-0015-plot-tree-data-shape.md`）。两格分离时，「哪些边玩家看得见」这条边界完全依赖内容作者的自觉；而两种错配各自都是坏状态，且都不会在编写时被任何机制发现。

## 决策

把两格**焊成充要关系**：**`BranchLabel` 非空 ⟺ `Condition.Kind == BranchChosen`**，异或成立即**加载期 `PushError`**，带 arc `Id` + 节点 `Id` + `ToNodeId`。

同时确立两条配套约束：

- **内容编排判据**（写成可见分支须三条同时成立）：① 它是一次**当下可理解的承诺**；② 两条分支在**调制上真的分岔**，而非两句措辞不同、汇回同一节点的文案；③ **不依赖玩家读出隐藏量**才能做出选择。其余一律写成自动边。
- **禁令：分支不得成为隐藏属性的读数口。** 既有软检查扩用到 `BranchLabel`：正文含属性名 / 阿拉伯数字 / 档位序号 → `PushWarning` 逐条列出。
- 频次是**内容编排目标值、不入结构**；单节点分支条数超出上限 → 加载期 `PushWarning`。

逐条校验与编排判据 → `systems/services/plot-manager.md`。

## 理由

- **两种违规各自都是坏状态**：有标签而由后台条件推进 = 一条摆给玩家看、点了却不生效的边；等玩家选却没有标签可呈现 = 该 arc 死锁（该节点出边全是 `BranchChosen`，不选即无出边可走，也没有按钮可点）。
- **结构判据可机械检查**，把「可见 / 不可见」从作者自觉降级为加载期断言——与本库「纪律要落在可执行的那一级」同向（`decisions/ADR-0013-discipline-enforceability-ladder.md`）。
- 由 `HiddenStatBand` / `EventResolved` / `EventCount` / `ChapterAdvanced` 驱动的推进，**正是隐藏属性显影纪律要求静默的部分**（`decisions/ADR-0016-hidden-stat-band-model.md`、`decisions/ADR-0081-hidden-stats-outside-combat.md`）；把它们写成可见分支等于开一条泄露通道。
- `BranchLabel` 是玩家能读到、由剧本节点触发的文案 ⇒ 它天然是隐藏属性泄露的一条新通道，故沿用档位文案那条软检查、严厉度一致。

## 备选方案

- **两格保持分离、由内容评审保证一致** — 否决：边界依赖作者自觉，两种错配都无机制发现，且其中一种直接导致 arc 死锁。
- **异或时只 `PushWarning`** — 否决：两种违规都会产生玩家可见的坏状态（点了不生效 / 死锁），不属可降级放行之列。

## 后果

- 加载期校验表新增一行硬校验（异或成立 → `PushError` + arc `Id` + 节点 `Id` + `ToNodeId`），另有 `BranchLabel` 正文与分支条数上限两行软检查。
- 内容侧被约束：写一条可见分支必须同时填 `BranchLabel` 与 `BranchChosen`，两者不可单填；隐藏属性驱动的推进一律写成自动边。**连带：`HiddenStatBand` 条件的边在结构上不可能带标签**，隐藏属性因此没有经由分支标签泄露档位的通道。
- 相关文档因此这么写：`systems/services/plot-manager.md`（`PlotEdge` 字段说明 + 充要关系 + 校验表三行 + 内容编排三判据）· `ux/screen-flow.md`（分支按钮承载 `BranchLabel` 全文，不截断）。
- 结构与存档零增量：不新增字段、不 bump `schemaVersion`、后端零配合。
- 待定项：`content/plot-arc/` · `content/plot-node/` 类型档案开张时，三条编排判据须逐条写进其字段核对清单。
