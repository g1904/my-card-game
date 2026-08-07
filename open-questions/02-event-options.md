# ② eventOptions 生成流程（焦点）

> 本分片属 `../open-questions.md` 的当前焦点区。

- **生成 / 加权规则与叠加顺序（08-05b 收窄）。** **location 层的形态已答定**（事件类型概率修正 + 敌人模板池 + `eventCountLimit`），**具体数值归内容制作阶段**；仍待定：**每批数量**、类型修正的**运算形态**（乘性 / 加性 / 白名单 + 权重，能否修正到 0）、月圆之夜式策划与随机权重的配比，以及 **location 框定 / AdventurePlot 调制 / seeded RNG 的叠加顺序**。→ `systems/services/future-event-service.md`、`systems/game-progression.md`。
- **location 与 `locationMap` 的数据载体（08-05b 收窄）。** 字段与图的存在形态已定（**连通关系由全局不变的 `locationMap` 承载**），载体未定：`LocationData : Resource` + `.tres`？枚举 + 资源两件套？`locationMap` 是单份邻接表资源还是各 location 持边？是否受 `AllEnabled()` 与 overlay 管辖。→ `systems/game-progression.md`、`systems/adventure-event/travel/`。
- **Travel 闸门给几个候选、怎么选（08-05b 收窄）。** **多个并列已定案**；仍待定：是否列出**全部邻接**还是 seeded 抽取其中几个、候选是否受剧本调制。→ `systems/adventure-event/travel/`。
- **`LocationCodex`「记连边」的显影粒度（08-06c 收窄 · 承重）。** **记连边已定案**（跨轮回重建整张 `locationMap` 是设计目标）；仍待定：去过 A 之后列出的是 **A 的全部邻接（含从未去过的地名）** 还是**只记已走过的那几条边**？前者才支持「提前两步规划路线」，后者纯回溯。**本库现按前者理解，待确认。** 其余词条深度（风物文案 / 事件类型倾向 / 敌人清单 / 配额）与它不同于其余五本的呈现形态亦未定。→ `systems/player-profile/codex/_index.md`。
- **`eventCountLimit` 能否被剧本调制（08-05b 收窄）。** **计数口径已定案**（只计选择进入并结算的，Travel 不计入）；配额本身能否被 PlotManager 推拉未定。→ `systems/game-progression.md`。
- **哪些资源允许被打穿、各自的截断与终态判据（08-06c 新增 · 承重）。** `selectCost` 已改为无条件施加，于是必须回答：寿元归 0 = `defeated` 已定；**灵玉 / mana / 其余 element 打到负数怎么办**（截断到 0？允许为负？）、哪些资源的耗尽构成终态、哪些只是变穷。→ `systems/services/profile-service.md`、`systems/character-profile/currency.md`。
- **「余额不足即拒」还剩哪些消费点（08-06c 新增）。** 事件推进路径已不需要；Exchange 商店购买等主动消费点是否仍需？若全都不需要，`CanAfford` / `AdvanceResult.CostRejected` / `MissingElement` 可整体删除。→ `systems/services/profile-service.md`、`life-cycle-service.md`。
- **`Priority = 1` 依什么条件抬升（08-06c 收窄）。** **取值域两档、置位方唯一（future-event-service，PlotManager 不可改）已定案**；仍待定：依什么条件抬升（配额闸门之外还有哪些）、同批多个 `1` 档是否需额外收窄规则、以及字段是否从 `int` 退化为 `bool`。→ `systems/services/future-event-service.md`。
- **`EventOption` 的完整物化字段清单（08-06c 减为七字段）。** 骨架七字段已定（`InstanceId` / `EventId` / `EventType` / `Priority` / `SelectCost` / `IsRevealed` / `RevealedEventId`）。但物化模型说「**多数**属性由物化决定」，故仍待定：还有哪些字段由物化产出（哪些数值可被情境改写？风味文案是否也物化？outcome 权重是否在物化时固化？）。→ `systems/services/future-event-service.md`、`systems/adventure-event/common-properties.md`。
- **`CostKey` 的其余成员与 element 数据形态。** 代码形态已定为 `ProfileChangeSpec`（element 带符号）；仍待定：`CostKey` 除 `lifeSpanCost` 外的成员（jade / mana / 道具 / 隐藏属性推拉？）、各 element 的数据形态（固定值 / 区间 / 公式）。（「付不起时整体不可选 / 部分抵扣」一问已随 08-06c 作废，取而代之的是上面的「打穿后怎么办」。）→ `systems/adventure-event/common-properties.md`、`systems/character-profile/currency.md`、`systems/balance.md`。
- **`pastEvent` 的痕迹 schema（08-05b：已指定走 `/provide-solution-draft`；08-06c 收窄）。** 持久化方式已定（存**物化后的定稿实例快照**、按 `InstanceId` 索引，不重算），**且痕迹只剩一种**（跳过通道已移除）；仍待定：快照存哪些字段、**未被选中的选项是否随批次快照一并归档**（归档则剧本能读出「回避了什么」，代价是体积成倍增长）、**快照体积对增量 push 粒度的影响**。**用户已指示：本条与本分片其余 eventOptions 相关待答，先由 `/provide-solution-draft` 产出提案式草稿再评审。** → `systems/adventure-event/common-properties.md`、`systems/services/sync-service.md`。
