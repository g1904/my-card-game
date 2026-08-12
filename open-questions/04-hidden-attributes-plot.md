# ④ 隐藏属性 / 剧本机制（焦点）

> 本分片属 `../open-questions.md` 的当前焦点区。

> **档位划分与阈值**、**跨档叙事文案的归属与呈现**两条已于 08-12d 答结（一套档位表统一四个消费方：道心 5 档 / 煞气 4 档 / 寿元 3 档 + 回滞 δ；文案挂档位不挂事件、走内容层、**只挂极值档**、结算面板逐条陈列。权威在 `systems/services/plot-manager.md` 与 `ux/screen-flow.md`；移出记录见 `../answer-logs/log-hidden-stat-bands-and-crossing-narrative.md`）。

- **隐藏属性清单与推拉触发（08-12d 收窄）。** 已定 **道心 / 煞气 / 寿元** 三项且均隐藏，**取值域 `[0,100]`、档位表、阈值、回滞与跨档叙事形态均已定案**；仍待定：**是否还有第四项隐藏属性**、**增减触发（哪些 AdventureEvent 推拉、各推哪一档 `HiddenStatGrade`）**、**每条剧情线的具体内容**（目录已由两条扩为三条：煞气反噬 / 心魔滋生 / 大限将至）。→ `systems/services/plot-manager.md`、`life-cycle-service.md`。
- **`HiddenStatGrade` 的三个映射值（08-12d 新增 · 归 ch1 数值标杆专场）。** 初值 `Minor 2 / Standard 5 / Major 10` 与「每属性每篇章跨档 2–4 次」是**反推验收项，不是死数字**，校验依赖上一条的「增减触发」。**不阻塞任何结构**——它约束的是标定。→ `systems/balance.md`。
- **各篇章 `lifeSpanCost` 的具体分档表（08-01 收窄 · 08-01b 目标值改写 · 承重）。** **定价方向已定**（目标时长反推；预算不变、逐篇章上调；闭关 Research 更耗；剩余寿元跨篇章结转；内容侧正数量值、物化取负）；**目标时长已上调为 30–40 / 35–45 / 45–55 分钟**（熟练玩家口径），故反推出的**单次定价将显著低于先前设想、一个篇章的事件总数显著变多**。仍待定：**哪些事件类型多耗、单次幅度各是多少**。→ `systems/balance.md`、`systems/adventure-event/`。
- **非境界突破的寿元增长途径。** 是否存在（回寿类事件产出）未定。→ `systems/adventure-event/`、`systems/balance.md`。
- **AdventurePlot 数据编码与 key points 粒度（08-11 收窄）。** 四级结构、剧本内容归属（**本地内容层**，`res://` 基线 + overlay，经 ContentRegistry 读）均已定；**剧本服务契约、离线降级、预取与事务前置的边界整条消失**（云端剧本服务已撤销）。仍待定：树的数据表达（**调制** eventOptions 还是并行结构）、key points 粒度 / schema、DnD 式选分支触发点与 UI。**两条硬约束**：key point 不得引用 `InstanceId`；**必须能在其剧本节点缺失时被安全跳过**。→ `systems/services/plot-manager.md`。
- **剧本内容类型的数据形态（08-11 新增）。** 剧本条目是一种 `XxxData : Resource`（进 ContentRegistry、有自己的仓储）还是别的载体？若进 ContentRegistry，则「新增剧本条目不得引用本次 overlay 之外的新 `Id`」这条约束**需要一个可机械检查的形态**（属「能上线且线上不可见」⇒ 阶梯第 1 / 2 级）。→ `systems/services/plot-manager.md`、`systems/services/content-service.md`。
- **剧本内容的体积与分发粒度（08-11 新增）。** 三篇章完整剧本树的包体 / 下载量；是否按篇章分包、按进度增量下载（文件级事务已现成，**分包边界**未定）。本地化后这成为一笔真实成本——原云端方案的「按需请求」天然回避了它。→ 同上。
