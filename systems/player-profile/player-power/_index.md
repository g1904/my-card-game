# player-power

> **法则 / PlayerPower** —— 账号级 always-available 能力，带开关（默认开启）；通过事件触发器的被动修正 / relic-joker，含 RelicData 定义。
> **中文定名 = 法则**（08-03 定，取代「玩家能力」）；轮回级的对应物是 **神通 / CharacterPower**（`../../character-profile/power/`）。**中文名不表达层级** —— 账号级 ↔ 轮回级的对称只在英文标识符上成立。Source: `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md`。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **PlayerPower = 账号级 always-available 能力，带开关。** always-available，带**开关（默认开启）**；**通常全局、不与角色绑定**；可为 **QoL** 或**影响公平性的一定加强**（需衡量平衡）。由 PlayerProfile 持有（`List<PlayerPower>`），跨轮回持久。**获取越多后续越易，但 AdventureEvent 过程中也可能失去**已获取的 PlayerPower。Source: `handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。
- **定位 = 轻度提升（light improvement）。** 承认它影响平衡，但因**本作无 PvP、纯 PvE**，让 power 带来一定强度是**可容忍的**，并**打开更大的设计空间**去做有趣的 power。Source: `handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。
- **被动修正 = 挂接到事件触发器。** PlayerPower 通过响应游戏事件（触发器）施加被动修正（relic / joker 语义）。Source: `handoffs/2026-07-24-docs-restructure-class-model.md`。
- **RelicData 定义。** relic / joker 的**设计意图、触发条件与效果**及其数据定义（RelicData）归入本处。Source: `handoffs/2026-07-24-docs-restructure-class-model.md`。

- **开关落为 `status` 字段（启用 / 禁用）。** 「带开关」不只是 UX 描述，而是 PlayerPower 类上的持久字段；它与「拥有 / 失去」是**两个正交维度**（失去 = 移出 `List<PlayerPower>`，而非置禁用）。Source: `handoffs/2026-07-25b-event-cost-fields-capability-flags-and-service-hierarchy.md`。
- **道统残卷 = 失败累积的 PlayerPower 掉落概率（已定案 · 元进程的失败侧产出）。** 失败不再是零推进：
  - **不发放账号级货币。** 失败累积的是**一个递增的概率**——「**下一次轮回获得新 PlayerPower**」的掉落概率；**一旦获得新 PlayerPower，该概率即重置**。
  - **为何不是货币：** 可支配的货币会引入**第二套账号级经济**（获取 → 囤积 → 兑换 → 定价），而本作的元进程只想要「失败也在推进」这一条效果。递增概率给了同样的推进感，却不新增任何经济系统。
  - 因此「道统残卷」是一个**账号级的隐含状态**（一个概率值 + 重置规则），不是玩家可查看余额、可花费的资源。
  - **累积规则与上限未定**，见待决问题。
  Source: `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。
- **第二条获取渠道 = premium bundle（已定案）。** 付费礼包一次性给予**随机 1 个 PlayerPower**（外加随机 2 个 PlayerItem）。它与「道统残卷」（失败累积的掉落概率）是**同一个获取面上的两条渠道**——一条靠打，一条靠买；二者是否互相影响（礼包给的 power 是否重置残卷概率）未陈述，见待决问题。礼包全貌见 `systems/monetization.md`。Source: `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。
- **已获得的 PlayerPower 会进 PlayerPowerCodex。** 图鉴族（见 `../codex/`）为 PlayerPower 单列一本——它记录「见过 / 得到过哪些能力」的静态文案，与当前**持有**的 `List<PlayerPower>` 是两回事（失去某个 power 不会从图鉴中抹去它）。Source: 同上。
- **全局设定类效果 = capability flag + modifier pipeline（已定案）。** 「让玩家看见隐藏属性」这类改变全局设定的 power，以 **capability flag（布尔）+ modifier pipeline（数值）** 两条通道实现——数据声明 → 中心聚合 → 单点查询，避免在每个受影响层加条件。模型见 `common-properties.md`。Source: 同上。

> 具体的触发器体系、`status` 开关模型、capability flag 提案、RelicData 字段等共有属性见 `common-properties.md`。

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **道统残卷概率的累积规则与上限（08-01 新增）。** 方向已定（失败累积概率、获得即重置）；仍待定：**累积粒度**（每次失败 +X%？按抵达的篇章 / 等级深度加权？）、**上限**（是否封顶，封在哪）、**与 seed 公平性的关系**（掉落掷骰走哪条 RNG 子流、是否影响轮回可复现性）、以及概率状态**落在 PlayerProfile 的哪个字段**。→ `systems/services/life-cycle-service.md`、`systems/common-properties.md`。Source: `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。
- **PlayerPower 平衡边界待定。** 是否影响 cycle seed / 计分公平、防 pay/grind-to-win 的边界均待定。→ 见 `systems/services/life-cycle-service.md`。Source: `handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。
- **获取 / 失去触发未设计。** 「AdventureEvent 过程中也可能失去」的具体触发、开关 UI 均未细化。**已有两条获取渠道**：道统残卷（轮回开始时的概率掉落）与 premium bundle（付费随机 1 个）；**二者的交互未定**——礼包给的 power 是否重置残卷概率？两条渠道的「随机」是否共用同一个候选池与排重规则？走哪条 RNG（**不应污染轮回 seed 的确定性**）？→ `systems/monetization.md`、`systems/services/life-cycle-service.md`。Source: `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。
- **法则能否承载战斗内触发（08-03 新增）。** 轮回级的**神通（CharacterPower）已确认可承载**战斗内的触发式效果（与牌上触发器、场上持续状态并列）；账号级的法则能否也承载未陈述。若可，则 combat-service 组装参战方时还要读 PlayerProfile 一侧的持有列表。→ `systems/services/combat-service.md`。Source: `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md`。
- **relic / joker 内容为占位。** 触发条件、效果关键字、RelicData 字段清单均尚未设计，需一次 handoff。

## 对应
提炼至：`.claude/knowledge/systems/player-profile/player-power/_index.md`（待建）；RelicData 见 `.claude/knowledge/data/_index.md`。
