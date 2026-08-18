# Answer log plot-data-encoding

- 日期：2026-08-16
- 来源：`inbox/solution-draft-plot-data-encoding.md`（`status: decided`）→ `handoffs/2026-08-16i-plot-data-encoding.md`
- 移出条数：2（均出自 `open-questions/04-hidden-attributes-plot.md`）

---

**AdventurePlot 数据编码与 key points 粒度** → **答定**。

- **树 = 纯调制，没有并行结构。** AdventurePlot 不产出事件、不持有事件序列，它是 `ComputeEventOptions` 内部的一个加权 / 框定输入。三条既定纪律各自独立地封死并行结构：唯一物化点 + 唯一出口 · 事件之间不存在预先编好的前后连边 · 只调内容不调约束。推论：剧本树的「节点」是一组调制参数 + 一段可选叙事 + 一组出边，玩家只会察觉摆在面前的事件变了。
- **key points 粒度 = 每条已激活 arc 一条**（`PlotKeyPoint(ArcId, NodeId, State, EnteredAtChapter, EnteredAtSeq)`）。粒度由悬空降级规则反推：全局单指针一处悬空即整层不可解析（违反硬约束）· 每节点一条随轮回线性膨胀且无消费方 · 每 arc 一条使一条悬空只惰性化那一条剧本线。两条硬约束显式满足：无 `InstanceId`、缺失时可安全跳过。
- **推进时点 = 已有的 `eventEnd`，单步推进**，并入 band 写入的同一次 `TryApply`，不新增存档点 / 结算阶段。
- **不持久化已走分支路径**（无消费方；日后履历展示落 `PastEventEntry`）。
- **side arc 并发上限 `MaxConcurrentSideArcs = 2`，超出排队不丢弃**；**排队即写 `State = Queued` 的 key point**（interview 裁定，见下）。
- 归档去向：`systems/services/plot-manager.md`「剧本树的数据形态」· `systems/character-profile/_index.md`（`plotKeyPoint` 字段）· `systems/balance.md`（`MaxConcurrentSideArcs`）。**剩余部分仍待答**：DnD 选分支的触发点与 UI（已在分片中剥为独立条目）。

**剧本内容类型的数据形态（含「剧本例外的可执行化」）** → **答定**。

- **两个内容类型 `PlotArcData` + `PlotNodeData`**，各进 ContentRegistry、各有仓储。不合为一个（arc 与 node 的激活面不同、锚点粒度落在 arc 上），不拆为四个（四级只差激活范围与并发规则，层级用枚举表达）。
- **剧本正文内嵌 `PlotNodeData.Body : LocalizedText`**，不复用状态转换触发的定性文案类型——那类照旧只改不增，寄生其上会让 overlay 新增 arc 时写不出正文。连带：一条新 arc 的全部构件都是剧本类型，天然自足。
- **`PlotModulation` 六字段 = PlotManager 权力面的逐条投影**，越权的写法在内容层没有字段可填（可执行化阶梯第 1 级）。
- **overlay 剧本例外的两条合并期闸**（`newIds` 双闸，全量非 `#if DEBUG`）：闸 A 新增 `Id` 的宿主类型必须 ∈ { `PlotArcData`, `PlotNodeData` }；闸 B 新增剧本条目引用的非剧本 `Id` 必须来自基线。
- **可执行化选级的处置：客户端天花板是第 3 级**（检查对象是 `.tres` 引用图，C# 类型系统与编译器触不到），**等价的第 2 级由打包工具承担**——同一份 `LoadAll()` 校验前移进 overlay 打包工具，不通过不产包；启动期 `PushError` 保留为兜底。写成阶梯的**通用补注**（`.tres` 引用图不止剧本一处），不写成剧本特例。
- 归档去向：`systems/services/plot-manager.md`· `systems/services/content-service.md`（双闸 + 结构性查表表新增 `PlotNodeData` 行）· `systems/architecture.md`（阶梯通用补注 + 应用表第四行）· `content/_index.md`（类型登记表拆为 `plot-arc/` + `plot-node/`）。

---

## interview 裁定（两项，均改动了草稿的原写法）

1. **`PlotArcData` 的放量语义 vs 后端契约。** `backend-design-documents/contracts/content-manifest.md` 原写「flags 通道对剧本条目无作用点」，前提是「剧本条目只由 key point 定位读取」；本次把剧本切成 arc（被激活抽取 ⇒ 产出侧）与 node（查表定位 ⇒ 结构性读取）后该前提对 arc 不再成立。**裁定以客户端本次为准，改写后端契约**：arc 参与 `AllEnabled()` 与 flags（只停新激活），node 恒启用（`false` → `PushError`）。收益是一条 overlay 热更推上去的坏 arc 可秒关。
2. **排队 arc 的持久化。** 草稿原定「队列不落存档、读时重建」，与「排队使触发恒定成立」自相矛盾——道心双向、煞气可被净化下拉，band 回落后重建的队列会静默丢掉那条 arc（等价于被否决的「丢弃」）。**裁定：`PlotArcState` 增加 `Queued` 值，触发即写一条 key point，出队改 `Active`。** 零新增字段，并发上限只数 `Active` 的口径原样成立。
