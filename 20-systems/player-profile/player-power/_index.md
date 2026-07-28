# player-power

> 玩家能力 / **PlayerPower** —— 账号级 always-available 能力，带开关（默认开启）；通过事件触发器的被动修正 / relic-joker，含 RelicData 定义。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **PlayerPower = 账号级 always-available 能力，带开关。** always-available，带**开关（默认开启）**；**通常全局、不与角色绑定**；可为 **QoL** 或**影响公平性的一定加强**（需衡量平衡）。由 PlayerProfile 持有（`List<PlayerPower>`），跨轮回持久。**获取越多后续越易，但 AdventureEvent 过程中也可能失去**已获取的 PlayerPower。Source: `10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。
- **定位 = 轻度提升（light improvement）。** 承认它影响平衡，但因**本作无 PvP、纯 PvE**，让 power 带来一定强度是**可容忍的**，并**打开更大的设计空间**去做有趣的 power。Source: `10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。
- **被动修正 = 挂接到事件触发器。** PlayerPower 通过响应游戏事件（触发器）施加被动修正（relic / joker 语义）。Source: `10-handoffs/2026-07-24-docs-restructure-class-model.md`。
- **RelicData 定义。** relic / joker 的**设计意图、触发条件与效果**及其数据定义（RelicData）归入本处。Source: `10-handoffs/2026-07-24-docs-restructure-class-model.md`。

- **开关落为 `status` 字段（启用 / 禁用）。** 「带开关」不只是 UX 描述，而是 PlayerPower 类上的持久字段；它与「拥有 / 失去」是**两个正交维度**（失去 = 移出 `List<PlayerPower>`，而非置禁用）。Source: `10-handoffs/2026-07-25b-event-cost-fields-capability-flags-and-service-hierarchy.md`。
- **全局设定类效果 = capability flag + modifier pipeline（已定案）。** 「让玩家看见隐藏属性」这类改变全局设定的 power，以 **capability flag（布尔）+ modifier pipeline（数值）** 两条通道实现——数据声明 → 中心聚合 → 单点查询，避免在每个受影响层加条件。模型见 `common-properties.md`。Source: 同上。

> 具体的触发器体系、`status` 开关模型、capability flag 提案、RelicData 字段等共有属性见 `common-properties.md`。

## 决策(-> ADR)
> _已定案的决定链接到 50-decisions/ADR-####。_

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **PlayerPower 平衡边界待定。** 是否影响 cycle seed / 计分公平、防 pay/grind-to-win 的边界均待定。→ 见 `20-systems/services/life-cycle-service.md`。Source: `10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。
- **获取 / 失去触发未设计。** 「AdventureEvent 过程中也可能失去」的具体触发、获取渠道、开关 UI 均未细化。→ 见 `20-systems/services/life-cycle-service.md`。
- **relic / joker 内容为占位。** 触发条件、效果关键字、RelicData 字段清单均尚未设计，需一次 handoff。

## 对应
提炼至：`.claude/knowledge/systems/player-profile/player-power/_index.md`（待建）；RelicData 见 `.claude/knowledge/data/_index.md`。
