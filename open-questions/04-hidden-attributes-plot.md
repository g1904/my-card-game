# ④ 隐藏属性 / 剧本机制（焦点）

> 本分片属 `../open-questions.md` 的当前焦点区。

> **档位划分与阈值**、**跨档叙事文案的归属与呈现**两条已于 08-12d 答结（一套档位表统一三个消费方：道心 5 档 / 煞气 4 档，共 9 档 + 回滞 δ——寿元已退出隐藏属性体系，明文常驻恒精确；文案挂档位不挂事件、走内容层、**只挂极值档**、结算面板逐条陈列。权威在 `systems/services/plot-manager.md` 与 `ux/screen-flow.md`；移出记录见 `../answer-logs/log-hidden-stat-bands-and-crossing-narrative.md`）。

> **AdventurePlot 数据编码 / key points 粒度**与**剧本内容类型的数据形态**两条已于 08-16i 答结（树 = 纯调制无并行结构；剧本内容落 `PlotArcData` + `PlotNodeData`，正文内嵌节点；key points 每条已激活 arc 一条、含 `Queued` 态；overlay 剧本例外获得合并期 `newIds` 双闸。权威在 `systems/services/plot-manager.md` 与 `systems/services/content-service.md`；移出记录见 `../answer-logs/log-plot-data-encoding.md`）。

> **隐藏属性的推拉触发**已于 09-09 答结（清单 / 取值域 / 档位表 / 阈值 / 回滞 / 允许面此前已定；本次补齐语义 → `(Stat, Direction, Grade)` 的编排判据表、Combat 三档默认阶梯、两条剧情线的结构形态与内容大纲，剩余为纯内容编排工作量。权威在 `systems/adventure-event/common-properties.md`、`systems/adventure-event/combat/_index.md` 与 `systems/services/plot-manager.md`；移出记录见 `../answer-logs/log-event-reward-and-hidden-stat-orchestration.md`）。

> **非境界突破的寿元增长途径**已于 08-17f 答结（存在；三条通道共用 `ChangeElement(LifeSpan, +n)`、只走 outcome 侧、成本侧取值域收紧为非负、数字与 `selectCost` 一律恒精确展示、护栏为三道软闸 + Travel 禁令，零结构增量。权威在 `systems/adventure-event/common-properties.md` 与 `systems/balance.md`；移出记录见 `../answer-logs/log-lifespan-gain-paths.md`）。

- **`HiddenStatGrade` 的三个映射值（08-12d 新增 · 留待内容扩充后的统计校准）。** 初值 `Minor 2 / Standard 5 / Major 10` 与「每属性每篇章跨档 2–4 次」是**反推验收项，不是死数字**（作用面为道心 / 煞气两属性）；校准输入现已齐备——哪些事件推拉、各推哪一档由编排判据表与 Combat 三档阶梯给出，剩下的是内容铺开后的统计校准。**不阻塞任何结构**——它约束的是标定。→ `systems/balance.md`。
- **角色专属 SideStory 的激活口（09-12 新增 · 工程推演题，不是取向题）。** 现有两条 arc 激活通路是 `PlotTriggerId`（隐藏属性跨档）与篇章边界（Story / Chapter arc 各恒一条）；一条「角色专属、不由隐藏属性触发」的 SideStory arc 没有明写的激活口。角色专属剧情对免费 / 付费两轨道一视同仁地铺已定案 ⇒ 这个缺口须先补。**归一次 `/provide-solution-draft`。** → `systems/services/plot-manager.md`。
- **`PlotArcData.CharacterIds` 的 gating 语义（09-12 新增）。** 何时比对（激活期一次？每次解析？）、不匹配时是不激活还是惰性——`ChapterScope` / `ExclusiveGroup` 都有明确落位，唯独这一格只有一行字段注释。与上一条同批答。→ `systems/services/plot-manager.md`。
