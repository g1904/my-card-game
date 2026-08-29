# ④ 隐藏属性 / 剧本机制（焦点）

> 本分片属 `../open-questions.md` 的当前焦点区。

> **档位划分与阈值**、**跨档叙事文案的归属与呈现**两条已于 08-12d 答结（一套档位表统一四个消费方：道心 5 档 / 煞气 4 档 / 寿元 3 档 + 回滞 δ；文案挂档位不挂事件、走内容层、**只挂极值档**、结算面板逐条陈列。权威在 `systems/services/plot-manager.md` 与 `ux/screen-flow.md`；移出记录见 `../answer-logs/log-hidden-stat-bands-and-crossing-narrative.md`）。

> **AdventurePlot 数据编码 / key points 粒度**与**剧本内容类型的数据形态**两条已于 08-16i 答结（树 = 纯调制无并行结构；剧本内容落 `PlotArcData` + `PlotNodeData`，正文内嵌节点；key points 每条已激活 arc 一条、含 `Queued` 态；overlay 剧本例外获得合并期 `newIds` 双闸。权威在 `systems/services/plot-manager.md` 与 `systems/services/content-service.md`；移出记录见 `../answer-logs/log-plot-data-encoding.md`）。

- **隐藏属性清单与推拉触发（08-12d 收窄 · 08-16 再收窄）。** 已定 **道心 / 煞气 / 寿元** 三项且均隐藏，**取值域 `[0,100]`、档位表、阈值、回滞与跨档叙事形态均已定案**；**推拉的允许面亦已答结（08-16）——所有事件都有可能推拉这三个属性，不限事件类型，且是「允许携带」而非「强制携带」**（不填 = 不推）。仍待定：**是否还有第四项隐藏属性**、**逐条目的映射**（具体哪条内容推哪个属性、各推哪一档 `HiddenStatGrade`）、**每条剧情线的具体内容**（目录已由两条扩为三条：煞气反噬 / 心魔滋生 / 大限将至）。→ `systems/services/plot-manager.md`、`life-cycle-service.md`。
> **非境界突破的寿元增长途径**已于 08-17f 答结（存在；三条通道共用 `ChangeElement(LifeSpan, +n)`、只走 outcome 侧、成本侧取值域收紧为非负、数字与 `selectCost` 同 Band 2 门控、护栏为三道软闸 + Travel 禁令，零结构增量。权威在 `systems/adventure-event/common-properties.md` 与 `systems/balance.md`；移出记录见 `../answer-logs/log-lifespan-gain-paths.md`）。

- **`HiddenStatGrade` 的三个映射值（08-12d 新增 · 留待内容扩充后的统计校准）。** 初值 `Minor 2 / Standard 5 / Major 10` 与「每属性每篇章跨档 2–4 次」是**反推验收项，不是死数字**，校验依赖上一条的「增减触发」。**不阻塞任何结构**——它约束的是标定。→ `systems/balance.md`。
- **各篇章 `lifeSpanCost` 的具体分档表（08-01 收窄 · 08-01b 目标值改写 · 承重）。** **定价方向已定**（目标时长反推；预算不变、逐篇章上调；闭关 Research 更耗；剩余寿元跨篇章结转；内容侧正数量值、物化取负）；**目标时长已上调为 30–40 / 35–45 / 45–55 分钟**（熟练玩家口径），故反推出的**单次定价将显著低于先前设想、一个篇章的事件总数显著变多**。仍待定：**哪些事件类型多耗、单次幅度各是多少**。→ `systems/balance.md`、`systems/adventure-event/`。
- **DnD 式选分支的触发点与 UI（08-16i 从「数据编码」一条中剥出）。** 数据挂点已定（`PlotEdge.BranchLabel` 非空 = 对玩家可见的分支，`PlotSegment.Branches` 承载，`branchId` = 该边的 `ToNodeId`）；仍待定：**何时把分支摆给玩家、摆在哪一屏**、玩家可见 / 不可见分支的边界。→ `systems/services/plot-manager.md`、`ux/screen-flow.md`。
