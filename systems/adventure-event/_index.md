# adventure-event（AdventureEvent 系统）

> 修行事件（AdventureEvent）系统总览：逐时逐刻的游玩单元、**五类子类型**、进入 / 结算通用流程。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **AdventureEvent = 逐时逐刻的游玩单元。** 玩家从当前可用项（eventOptions，由 future-event-service 产出）中择一以推进轮回。
- **并非每个 AdventureEvent 都是一场战斗。** 战斗存在，但这是对 Slay the Spire「每个节点都战斗」节奏的有意背离——**五类中仅 战斗（Combat）走战斗结算**（其内部三个 `combatTier` 档共用同一套回合循环与参战方结构，差异在胜负条件与奖惩），其余四类是非战斗事件；Explore 视其揭示出的真身可能落到战斗结算上。
- **事件 / 抉择机制参照《月圆之夜》（Night of the Full Moon）建模。** AdventureEvent 呈现事件 / 选择，其后果影响玩家及未来状态；节点呈现形态为精心策划的事件菜单。
- **底层压力遵循一种类 Reigns 的属性平衡手感**——选择在相互竞争的仪表间摆动，而非优化单一数值；但本作属性**隐藏**（见 `systems/services/plot-manager.md`）。
- **五类子类型。** 见下表；顶层共有属性见 `common-properties.md`。分类权威：`decisions/ADR-0002-adventure-event-taxonomy.md`。

### 子类型索引（五类）

| 中文 | 英文 / 代码 | 直观含义 | 文档 |
|------|------------|----------|------|
| 战斗 | Combat | 与敌人战斗并获取资源；**最高频的一类**，走战斗结算 | `combat/_index.md` |
| 交易 | Exchange | 以资源换取 item / cultivationTechnique / 等（含社交语境） | `exchange/_index.md` |
| 闭关 | Research | 玩家调整 / 升阶自己的卡组 | `research/_index.md` |
| 探索秘境 | Explore | **元类型**：遮罩一个固定的 Combat / Travel / Exchange 事件（进入后揭示） | `explore/_index.md` |
| 前往某处地点 | Travel | 地图路由选择：刷新角色所在的 location（地域）；**非常驻可选项** | `travel/_index.md` |

- **分类粒度的判据 = 「是否共有同一套特征」。** 共有一套结算形状与呈现形状的归为一类，**类内差异用参数 / 档位表达，而非新增枚举值**：
  - **战斗的三种形态是 Combat 的 `combatTier` 三档**（`Practice` 修炼 / `Standard` 常规 / `Finale` 境界突破，对位 Balatro small / big / boss blind），共用回合循环、参战方结构与结算代码，差异只在 `EncounterSpec` 的遭遇参数。见 `combat/_index.md`。
  - **Explore 是唯一的元类型**：遮罩—揭示语义，真身取值域 = Combat / Travel / Exchange（不含 Research、不嵌套自身）。见 `explore/_index.md`。
  - **社交语境归 Exchange**：「与 NPC 谈条件」与「在商店买东西」共有同一套事件式结算与呈现形状；风味不需要枚举值来承载。见 `exchange/_index.md`。
- **开局有一个强制的构筑事件，归 Research。** 起始事件中**必有一个强制事件**，让玩家选**一门功法**与**一件法宝**（各三选一）——形态取 Slay the Spire 第一章的味道。**它不需要新机制**：既有 `eventPriority = 1`（有效可选集收窄）已能表达「本批必须进这个」。**推论：轮回内构筑的多轮性由 adventureEvent 承载**——升阶 / 弃置 / 学新功法都发生在 Research 事件里（见 `systems/character-profile/deck/_index.md`），开局只定起手形状。
- **逐类型各开一次专门 session（流程意图）。** 各子类型的机制细化**不在一次 handoff 里做完**：为每一类各开一次专门的 session（Combat / Exchange / Research / Explore / Travel），逐类填充其 `<type>/` 子文档。**Combat 已开过第一场专场**，其 `Practice` / `Finale` 两档亦已有大量定案；其余四类仍在**等各自的专场**，而非被遗漏——不要在通用文档里替它们臆造机制。

Source: `handoffs/2026-07-13.md` · `handoffs/2026-07-22-online-cloud-combat-and-meta-clarifications.md` · `handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md` · `handoffs/2026-07-24-docs-restructure-class-model.md` · `handoffs/2026-07-30-claude-engineering-scope-enemy-manager-and-requirement-breakdown.md` · `handoffs/2026-08-12f-cultivation-technique-deck-building.md` · `handoffs/2026-08-15c-event-type-collapse-and-batch-shape.md`

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- **修行事件分类法 = 五类：** Combat（含 `combatTier` 三档）/ Exchange / Research / Explore / Travel → `decisions/ADR-0002-adventure-event-taxonomy.md`（Accepted）。
- **开局强制构筑事件归 Research**。

Source: `handoffs/2026-08-15c-event-type-collapse-and-batch-shape.md`

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **子类型间的公平配比与出现频率：** 一段修行历程中各类事件的分布、权重、由 location（地域）与 AdventurePlot 如何调制，未定。分布维度是五类，且 Combat 内部另有一层 `combatTier` 配比要定。→ 亦见 `systems/game-progression.md`、`systems/services/future-event-service.md`、`systems/services/plot-manager.md`。
- **`combatTier` 三档在一个篇章内的配比：** 每篇章一个 `Finale` 已定；`Practice` 与 `Standard` 的比例未定。→ `systems/balance.md`。

## 对应
提炼至：`.claude/knowledge/systems/adventure-event/_index.md`（待建）
