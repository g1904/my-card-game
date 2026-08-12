# player-power —— 共有属性

> PlayerPower / RelicData 的共有字段与共有机制：开关、事件触发器、被动修正、RelicData 定义。为未来「每个 power / relic 一个 Markdown」预留结构。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **`status`（共有字段：启用 / 禁用，默认启用）。** 每个 PlayerPower 都是 always-available 且**带开关**——开关落为 PlayerPower 类上的持久字段 `status`（启用 / 禁用），玩家可关闭。Source: `handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md` + `handoffs/2026-07-25b-event-cost-fields-capability-flags-and-service-hierarchy.md`。
- **`SourceCode`（共有字段：授予来源，类型 `Source` 枚举）。** 每个持有条目记录**它是被哪条渠道给到玩家的**（`FinaleWin` / `PremiumBundle` / `AchievementReward` / …），写入时刻 = 授予时刻、此后不变。**它落在持有条目上，不落在 `PowerData` 上**——同一条法则可由不同渠道获得，来源是「这一次获取」的属性。**它的唯一消费点是道统残卷的分档自变量 `x`**（= `SourceCode == FinaleWin` 的法则数，见 `_index.md`）——**没有第二个消费点**：不对玩家可见、不进图鉴、不参与其他判定。**本层合法取值（08-12b 分域清单的法则列）= `FinaleWin` / `PremiumBundle` / `AchievementReward`**（+ 读档兜底 `Unknown`）——恰是 08-10b 那三值，故**法则一侧的取值域没有任何变化**；`CombatReward` / `InitialGrant` 在此不合法（账号级唯一的战斗入口是残卷、已有专用成员 `FinaleWin`；账号级不随角色创建发放）。**`EventOutcome` / `ExchangePurchase` 暂不开放**——取决于尚未设计的「法则的第三条获取渠道」（见 `_index.md` 的待决项），日后开放只需在校验表里翻一格，无结构改动。**置换所得继承被换出条目的来源。** 枚举清单、分域校验表（入口严 / 读档宽）与授予通道的强制携带规则见 `systems/common-properties.md`。Source: `handoffs/2026-08-12b-grant-source-per-kind-scope.md`。
- **`status` 与「拥有 / 失去」是两个正交维度。** PlayerProfile 的 `List<PlayerPower>` 表达**拥有哪些**；`status` 表达拥有的这些里**哪些当前生效**。「AdventureEvent 过程中可能失去 PlayerPower」是把条目**移出列表**，而非置 `status = 禁用`。存档需同时表达这两态。Source: `handoffs/2026-07-25b-event-cost-fields-capability-flags-and-service-hierarchy.md`。
- **事件触发器 → 被动修正（共有机制）。** power / relic 挂接到游戏事件的**触发器**上，命中时施加**被动修正**。这与 `csharp-godot-rules.md` 的 EventBus / 信号解耦事件一致。Source: `handoffs/2026-07-24-docs-restructure-class-model.md`。
- **RelicData 共有字段（数据即资源）。** relic / joker 是**数据**（预期 `RelicData : Resource`，`.tres`，带稳定唯一 `Id`）；共有字段预期含 `Id`、显示名 / 描述（与 `Id` 分离、可本地化）、触发条件、效果定义。数值读自资源，不硬编码。Source: `data-resource-rules.md`。

### 全局设定类效果的实现模型（**已定案**）

> 原问题：像「让玩家看见角色隐藏属性数值」这类**更改全局设定**的 PlayerPower，如何系统性定制，而不是在每个受影响的层去加定制条件？**已定案：capability flag（布尔）+ modifier pipeline（数值）两条通道。** Source: `handoffs/2026-07-25b-event-cost-fields-capability-flags-and-service-hierarchy.md`。

统一形状：**数据声明 → 中心聚合 → 单点查询**，分两条通道。

**通道一 · 布尔型「能力标记 / capability flag」**（可见性、解锁、QoL）
- 每个此类效果定义为一个**具名 flag**（例：`RevealHiddenStats`、`ShowMysteryType`）。PlayerPower 的效果定义在 `.tres` 上**声明它授予哪些 flag**——新增能力 = 新增数据，不改系统代码。
- 一个 **capability 聚合面**在启动及 PlayerProfile 变更时，把所有**拥有且 `status = 启用`** 的 PlayerPower 所授予的 flag 聚合为一份**生效能力集**，变更时经 **EventBus** 广播 `CapabilitiesChanged`。（该聚合面缺少宿主服务——见 `systems/architecture.md` 的账号级服务缺口。）
- **消费侧收敛为「一个 flag ↔ 一处消费点」。** 让**受影响的组件自己订阅**：隐藏属性显示组件默认隐藏，自查 `Has(RevealHiddenStats)` 并响应 `CapabilitiesChanged` 重绘；业务逻辑层完全不知道该 power 存在。**条件散落的根因是把呈现决策写进了业务层**——决策点归位后，条件自然只剩一处。

**通道二 · 具名数值「修正管线 / modifier pipeline」**（平衡修正）
- 非布尔的全局修正（`lifeSpanCost`、商店价格、掉落权重……）由 PlayerPower 注册**具名 modifier**（key + 运算 + 数值，同为 `.tres` 字段）。
- 系统读取该数值时**统一走一个入口** `Apply(key, baseValue)`，而非各消费层写 `if (hasPowerX) value -= 1`。新增一个修正 = 新增一条数据，受影响系统零改动。

两条通道均满足 `data-resource-rules.md` 的「内容保持可加性：新增 = 新增 `.tres`，而非编辑 switch 语句」。

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- **全局设定类效果 = capability flag + modifier pipeline（数据声明 → 中心聚合 → 单点查询）** → 已定案，**ADR 候选**（待固化）。Source: `handoffs/2026-07-25b-event-cost-fields-capability-flags-and-service-hierarchy.md`。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **触发器体系与 RelicData 字段未定案。** 触发条件枚举、效果关键字体系、开关（`status`）的持久化 / UI、RelicData 字段清单尚无实质设计，需一次 handoff。
- **capability flag + modifier pipeline 的落地细节（模型已定案，细节待定）：** flag 的枚举 / 命名空间、聚合面的**宿主服务**（当前无账号级服务——PlayerProfile 侧待完善，见 `systems/architecture.md`）、`status` 与「拥有 / 失去」两态的存档表达、**冲突 / 叠加规则**（两个 power 授予同一 flag、多条 modifier 的运算顺序）。Source: `handoffs/2026-07-25b-event-cost-fields-capability-flags-and-service-hierarchy.md`。

## 对应
提炼至：`.claude/knowledge/data/_index.md`（RelicData）；`.claude/knowledge/systems/player-profile/player-power/`（待建）。
