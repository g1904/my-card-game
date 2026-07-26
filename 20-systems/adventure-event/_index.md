# adventure-event（AdventureEvent 系统）

> 修行事件（AdventureEvent）系统总览：逐时逐刻的游玩单元、九类子类型、进入 / 结算通用流程。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **AdventureEvent = 逐时逐刻的游玩单元。** 玩家从当前可用项（eventOptions，由 future-event-service 产出）中择一以推进 run。Source: `10-handoffs/2026-07-24-docs-restructure-class-model.md`。
- **并非每个 AdventureEvent 都是一场战斗。** 战斗存在，但这是对 Slay the Spire「每个节点都战斗」节奏的有意背离——仅 战斗（Combat）及其变体 修炼（Practice）走战斗结算、境界突破（Finale）走独立结算，其余子类型是非战斗事件。Source: `10-handoffs/2026-07-13.md`。
- **事件 / 抉择机制参照《月圆之夜》（Night of the Full Moon）建模。** AdventureEvent 呈现事件 / 选择，其后果影响玩家及未来状态；节点呈现形态为精心策划的事件菜单（已定案）。Source: `10-handoffs/2026-07-22-online-cloud-combat-and-meta-clarifications.md`。
- **底层压力遵循一种类 Reigns 的属性平衡手感**——选择在相互竞争的仪表间摆动，而非优化单一数值；但本作属性**隐藏**（见 `20-systems/services/plot-manager.md`）。Source: `10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。
- **九类子类型。** 见下表；顶层共有属性见 `common-properties.md`。Source: `terminology.md`、`10-handoffs/2026-07-24-docs-restructure-class-model.md`。

### 子类型索引（九类）

| 中文 | 英文 / 代码 | 直观含义 | 文档 |
|------|------------|----------|------|
| 战斗 | Combat | 正式回合制战斗遭遇（走战斗结算） | `combat/_index.md` |
| 境界突破 | Finale | 篇章边界高潮：渡劫 / 突破，独立于 Combat 的结算 | `finale/_index.md` |
| 未知 | Mystery | 元类型：遮罩一个**固定的** AdventureEvent（进入后揭示） | `mystery/_index.md` |
| 修炼 | Practice | 比试 / 切磋——低风险战斗式历练 | `practice/_index.md` |
| 交易 | Exchange | 交易 / 商店的交易机制 | `exchange/_index.md` |
| 闭关 | Research | 钻研 / 潜修 | `research/_index.md` |
| 探索秘境 | Explore | 探索一处秘境（第八类） | `explore/_index.md` |
| 社交 | Social | 与 NPC / 势力的社交互动 | `social/_index.md` |
| 前往某处地点 | Travel | 地图路由选择：刷新角色所在的 location（地域）（第九类） | `travel/_index.md` |

> 休养 / Rest 不单列，并入 战斗 或 闭关。Source: `terminology.md`。

## 决策(-> ADR)
> _已定案的决定链接到 50-decisions/ADR-####。_

- **修行事件分类法：** 修炼 / 战斗 / 闭关 / 交易 / 社交 / 未知 + 境界突破 Finale。→ `50-decisions/ADR-0002-adventure-event-taxonomy.md`（Accepted，07-23 修订加入 Finale）。
- **加入 Explore / Travel 为第八、九类**（ADR-0002 待补订）。Source: `10-handoffs/2026-07-24-docs-restructure-class-model.md`。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **ADR-0002 补订：** Explore / Travel 尚未正式并入 ADR-0002 枚举，需补订。Source: `10-handoffs/2026-07-24-docs-restructure-class-model.md`。
- **子类型间的公平配比与出现频率：** 一段修行历程中各类事件的分布、权重、由 location（地域）与 AdventurePlot 如何调制，未定。→ 亦见 `20-systems/game-progression.md`、`20-systems/services/future-event-service.md`、`20-systems/services/plot-manager.md`。

## 对应
提炼至：`.claude/knowledge/systems/adventure-event/_index.md`（待建）。
