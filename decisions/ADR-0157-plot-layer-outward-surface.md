# ADR-0157 — 剧本层的对外面：EventBus 恰好一条事件，剧本段走门面只读查询

- **状态：** Accepted
- **日期：** 2026-09-03
- **来源：** handoffs/2026-09-03-plot-eventbus-broadcast.md

## 背景

剧本层有一个空位：分支揭示 / 分支选择 / key point 推进这三件事是否走 EventBus 广播。追这个空位时牵出一条至今无明文的链路——结算面板要渲染 `PlotSegment`（正文 + 分支按钮），但 `TryResolvePlot` 是 `internal sealed` manager 的内部方法、不上门面，`AdvanceResult` 里也没有它：**呈现侧没有任何拿到剧本段的合法通道**。

## 决策

**剧本层的 EventBus 事件保持恰好一条 `PlotThresholdReached`**——分支揭示 / 分支选择 / key point 推进一律不广播。既有行不动（负载与广播者原样保留），只补写广播时点：**在 `eventEnd` 五步组装的提交那一批里广播，与 `EventResolved` 同批。**

**剧本段的送达 = 宿主服务门面上的一次纯只读查询 `TryGetPlotSegment`**：可重入、无副作用（内部即一次 `TryResolvePlot` 的转发——不消耗随机子流、不写存档、不推进 key point、不重算 eventOptions），故面板重绘 / 退出重进都安全。失败语义原样继承 `TryResolvePlot`（返回 `false` + `PushWarning`，呈现侧不渲染剧本段、面板照常出「继续」，**不是失败路径**）。调用时点：`AdvanceEventAsync` 返回、成功且非终态之后。

**若日后确需广播：预留路标，不预留结构**——只在 `systems/services/plot-manager.md` 记一句候选签名，不建事件。

签名与失败语义 → `systems/services/future-event-service.md`、`systems/services/plot-manager.md`。

## 理由

- **分支揭示写不进负载**：要送达的是 `PlotSegment`（`LocalizedText` + 列表 + `Resource`），**完整实例一律不进负载**；退化成只传 id 后订阅者必须回查，而唯一能回查的实现体是 `internal sealed` 的 PlotManager ⇒ 这条事件对任何订阅者都不可消费。**先建一条不可消费的事件、再补一条查询方法，是把一件事做两遍。**
- **分支揭示在语义上是「询问」**：它的全部目的是等玩家输入并据此推进 arc；EventBus 不承载请求 / 询问，需要返回值的一律直接方法调用。
- **分支选择与 key point 推进当前零跨系统消费方**（不触发 `RefreshAfterEvent` · 终态判定恒 no-op · 不新增存档点 · key point 变化随 `CharacterProfile` 自然进 sync 的 diff）。**订阅者列表为空的事件不是解耦，是一处必然漂移的死契约。**
- **广播时点排在提交之后**：广播 = 既成事实，而事务提交前跨档这件事还不是事实（`TryApply` 全有或全无，中途广播会在回滚时留下一条已发出的假事实）。

## 备选方案

- **为分支揭示 / 选择 / key point 推进各建一条 EventBus 事件** — 否决：不可消费 / 询问不走广播 / 零消费方。
- **剧本段随 `AdvanceResult` 由 life-cycle 转交** — 否决：`AdvanceResult` 会从纯值类型变成携带引用字段的载体，且 life-cycle 就此承担剧本呈现的转发职责（它当前对剧本层零认知）。其自称收益「呈现侧只与一个服务对话」本就不成立——`ChooseBranch` 的既有门面投影已使呈现侧必须与 future-event 对话。
- **现在就把 `PlotArcAdvanced` 建成真事件** — 否决：唯一可预见的消费方是 AchievementManager，而它的采集面尚未定；按「不预留冻结结构，但把正确做法记一句」处理。

## 后果

- **EventBus 负载契约表零新增行、零改行**；`systems/architecture.md` 只多一句不含签名的结论，完整候选签名住 `systems/services/plot-manager.md`（两处都写完整签名会制造第二权威）。
- **代价明写**：PlotManager 在服务门面上从一处投影变成两处，「唯一对外投影」的**数量表述**随之松动——松动的是数量，不是纪律：`TryGetPlotSegment` 仍由宿主服务代为转发，PlotManager 类型仍 `internal sealed`、仍不被跨服务直接调用（`decisions/ADR-0014-plot-manager-inside-future-event-service.md` 的决定本身不变）。`systems/services/future-event-service.md` 的 API 面计数句按既有纪律去掉数字。
- **存档 schema 零改动、零迁移**；不新增存档点、不新增结算阶段、不新增 RNG 子流；`AdvanceResult` 形状不变。
- **无跨库承接**：EventBus 是进程内 C# 事件、剧本内容属本地内容层、PlotManager 无后端接口，后端库零改动。
- 受约束的文档：`systems/services/plot-manager.md`（事件面 + 路标签名）· `systems/architecture.md`（负载契约表下的注解）· `systems/services/future-event-service.md`（门面 API 表新增 `TryGetPlotSegment`）· `ux/screen-flow.md`（方法名换成 `TryGetPlotSegment`，呈现结论一字不动）。
