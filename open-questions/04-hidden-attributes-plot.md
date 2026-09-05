# ④ 隐藏属性 / 剧本机制（焦点）

> 本分片属 `../open-questions.md` 的当前焦点区。

> **档位划分与阈值**、**跨档叙事文案的归属与呈现**两条已于 08-12d 答结（一套档位表统一三个消费方：道心 5 档 / 煞气 4 档，共 9 档 + 回滞 δ——寿元已退出隐藏属性体系，明文常驻恒精确；文案挂档位不挂事件、走内容层、**只挂极值档**、结算面板逐条陈列。权威在 `systems/services/plot-manager.md` 与 `ux/screen-flow.md`；移出记录见 `../answer-logs/log-hidden-stat-bands-and-crossing-narrative.md`）。

> **AdventurePlot 数据编码 / key points 粒度**与**剧本内容类型的数据形态**两条已于 08-16i 答结（树 = 纯调制无并行结构；剧本内容落 `PlotArcData` + `PlotNodeData`，正文内嵌节点；key points 每条已激活 arc 一条、含 `Queued` 态；overlay 剧本例外获得合并期 `newIds` 双闸。权威在 `systems/services/plot-manager.md` 与 `systems/services/content-service.md`；移出记录见 `../answer-logs/log-plot-data-encoding.md`）。

- **隐藏属性清单与推拉触发（08-12d 收窄 · 08-16 再收窄）。** 已定 **道心 / 煞气** 两项且均隐藏（寿元已合并为明文常驻的单一资源、退出隐藏属性体系），**取值域 `[0,100]`、档位表、阈值、回滞与跨档叙事形态均已定案**；**推拉的允许面亦已答结（08-16）——所有事件都有可能推拉这两个属性，不限事件类型，且是「允许携带」而非「强制携带」**（不填 = 不推）。仍待定：**是否还有第三项隐藏属性**、**逐条目的映射**（具体哪条内容推哪个属性、各推哪一档 `HiddenStatGrade`）、**每条剧情线的具体内容**（目录为两条：煞气反噬 / 心魔滋生）。→ `systems/services/plot-manager.md`、`life-cycle-service.md`。
> **非境界突破的寿元增长途径**已于 08-17f 答结（存在；三条通道共用 `ChangeElement(LifeSpan, +n)`、只走 outcome 侧、成本侧取值域收紧为非负、数字与 `selectCost` 一律恒精确展示、护栏为三道软闸 + Travel 禁令，零结构增量。权威在 `systems/adventure-event/common-properties.md` 与 `systems/balance.md`；移出记录见 `../answer-logs/log-lifespan-gain-paths.md`）。

- **`HiddenStatGrade` 的三个映射值（08-12d 新增 · 留待内容扩充后的统计校准）。** 初值 `Minor 2 / Standard 5 / Major 10` 与「每属性每篇章跨档 2–4 次」是**反推验收项，不是死数字**（作用面为道心 / 煞气两属性），校验依赖上一条的「增减触发」。**不阻塞任何结构**——它约束的是标定。→ `systems/balance.md`。
