# Answer log plot-eventbus-broadcast

- 日期：2026-09-03
- 来源：`inbox/solution-draft-plot-eventbus-broadcast.md`（→ `handoffs/2026-09-03-plot-eventbus-broadcast.md`）
- 移出条数：1

**plot 分支揭示 / 选择、key point 推进是否走 EventBus？若走，事件名与负载形状为何。** → **不走 EventBus。** 剧本层的 EventBus 事件保持**恰好一条** `PlotThresholdReached`（负载 `(string CharacterId, HiddenStat Stat, int BandIndex)` 与广播者 `future-event（代 PlotManager）` 原样不动，只补写广播时点 = `eventEnd` 五步组装 ⑤ 提交之后那一批、与 `EventResolved` 同批）；分支揭示改由 `future-event-service` 门面的只读查询 `bool TryGetPlotSegment(CharacterProfile character, out PlotSegment segment)` 送达（依据：完整实例不进负载 + 询问不走广播）；分支选择与 key point 推进当前零跨系统消费方，不广播。`systems/architecture.md` 的 EventBus 负载契约表**零新增行、零改行**，仅在表下补一句结论性注解。日后成就采集面若定为 EventBus 被动订阅且确有剧本条件，按 `PlotArcAdvanced`（形状与触发条件住 `plot-manager.md`「事件面」）补一行。
（归档去向：`systems/services/plot-manager.md`「事件面」+ 投影句 · `systems/architecture.md`「EventBus 负载契约」表下注解 · `systems/services/future-event-service.md` API 面 +1 行 · `ux/screen-flow.md`「事件结算面板的剧本段」方法名）

**连带裁决（同一草稿，不单独计条）：**
- 剧本段送达通道取「门面新增只读投影」而非「随 `AdvanceResult` 由 life-cycle 转交」；PlotManager 在门面上从一处投影变为两处，`plot-manager.md` / `future-event-service.md` 共三处措辞 + 一处计数句随之松动（松动数量表述，不松纪律）。
- `plot-manager.md`「事件面」原「同样由宿主服务代为广播」一句经用户裁定为占位表述、可改写。
