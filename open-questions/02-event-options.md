# ② eventOptions 生成流程（焦点）

> 本分片属 `../open-questions.md` 的当前焦点区。

- **生成 / 加权规则与叠加顺序。** 从 CharacterProfile 生成 / 加权抽取下一批 eventOptions 的具体规则（月圆之夜式策划 vs 随机权重、每批数量、事件类型配比、带种子 RNG 派生），以及 **location 框定 / AdventurePlot 调制 / seeded RNG 的叠加顺序**未定。→ `systems/services/future-event-service.md`、`systems/game-progression.md`。
- **`EventOption` 的完整物化字段清单。** 骨架九字段已定（`InstanceId` / `EventId` / `EventType` / `Priority` / `IsMandatory` / `SelectCost` / `SkipCost` / `IsRevealed` / `RevealedEventId`）。但物化模型说「**多数**属性由物化决定」，故仍待定：还有哪些字段由物化产出（哪些数值可被情境改写？风味文案是否也物化？outcome 权重是否在物化时固化？）。→ `systems/services/future-event-service.md`、`systems/adventure-event/common-properties.md`。
- **补位落空的判定规则。** 何种条件下 future-event-service 补不出新事件？eventOptions 是否允许被跳到只剩 0 个？若剩 0 个玩家如何推进（死局兜底）？→ `systems/services/future-event-service.md`。
- **全部 mandatory + 付不起 `selectCost` 的死锁。** 一批可全部 mandatory 且高优先级封锁其余选项；若付不起唯一可选事件的 `selectCost`，轮回无法推进。既然 `selectCost` 是**物化时组装**的，这条保证天然有落点（物化阶段即可对照 `CanAfford` 调整）；剩下的只是「要不要给」与兜底形态。→ 同上。
- **`eventPriority` 与 `ifMandatory` 的叠加规则。** 高优先级事件**能否被跳过**？若被跳过，本轮是否解除对低优先级事件的封锁？二者都限制选择权，是否语义重叠（高优先级是否应蕴含 mandatory）？→ `systems/adventure-event/common-properties.md`、`systems/services/future-event-service.md`。
- **`eventPriority` 的取值域与置位方。** 两档（0 / 1）还是任意整数档位？是否也由 future-event-service / PlotManager 动态置位（用户仅明确了 `ifMandatory`）？→ 同上。
- **跳过语义的残留细节。** 主干已定（单项补位 / 通常不扣寿元 / 计入 `pastEvent` / **只对可选事件开放，不设配额与递增 `skipCost`**）；仍待定：**能否整批全跳**、**付不起 `skipCost` 时如何表现**。→ `systems/adventure-event/common-properties.md`、`systems/services/life-cycle-service.md`。
- **`CostKey` 的其余成员与 element 数据形态。** 代码形态已定为 `ProfileChangeSpec`（element 带符号）；仍待定：`CostKey` 除 `lifeSpanCost` 外的成员（jade / mana / 道具 / 隐藏属性推拉？）、各 element 的数据形态（固定值 / 区间 / 公式）、是否允许**部分抵扣**。→ `systems/adventure-event/common-properties.md`、`systems/character-profile/currency.md`、`systems/balance.md`。
- **`pastEvent` 的痕迹 schema。** 持久化方式已定（存**物化后的定稿实例快照**、按 `InstanceId` 索引，不重算）；仍待定：如何区分「进入并结算」与「跳过」两种痕迹及各自成本、快照存哪些字段、**快照体积对增量 push 粒度的影响**。→ `systems/adventure-event/common-properties.md`、`systems/services/sync-service.md`。
