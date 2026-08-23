# ADR-0002 — 修行事件分类法（五类）

- status: Accepted
- date: 2026-08-15
- supersedes:
- superseded-by:

## Context
逐时逐刻的游玩单元 **修行事件 / AdventureEvent** 需要一套稳定的类型分类，以驱动内容设计、选择界面与「并非每个事件都是战斗」这一支柱。此决定级联影响 `systems/adventure-event/`（各子类型文件夹）、内容 schema（每个 `.tres` 事件带一个类型）与选择 UX。

粒度的风险在两端：**过细**会让类型间语义重叠（自我精进类彼此含混、战斗的三种形态各占一个枚举值却共用同一套结算），**过粗**会让内容与 UX 失去可编排的分类维度。判据取**「是否共有同一套特征」**——共有一套结算形状与呈现形状的，归为一类；类内的差异用**参数 / 档位**表达，而非新增枚举值。参见 `handoffs/2026-08-15c-event-type-collapse-and-batch-shape.md`。

## Decision
修行事件分为**五类**：

| 中文 | 英文 / 代码 | 说明 |
|------|------------|------|
| 战斗 | Combat | 正式回合制战斗遭遇——玩家与敌人战斗并获取资源。**最高频的一类** |
| 交易 | Exchange | 以资源换取 item / cultivationTechnique / 等；含与 NPC / 势力打交道的社交语境 |
| 闭关 | Research | 玩家**调整 / 升阶自己的卡组** |
| 探索秘境 | Explore | **元类型**：遮罩一个**固定的** Combat / Travel / Exchange 事件，进入后才揭示 |
| 前往某处地点 | Travel | **地图路由选择**——刷新角色所在的 `location`（地域），由此框定下一批 eventOptions |

- **战斗的三种形态合为一类，差异由 `combatTier` 承担。** 修炼（Practice）、常规战斗（Standard）、境界突破（Finale）**共用同一套回合循环、参战方结构与结算代码**，差异只在胜负条件、回合数与奖惩——那是**参数**，不是类型。三者收为 `Combat` 一个 `eventType`，档位由 **`combatTier { Practice, Standard, Finale }`** 表达：

  | 档位 | 对位 Balatro | 遭遇参数 |
  |---|---|---|
  | `Practice` | small blind | `TurnLimit 8` · `WinMargin 0`（道念相等即胜） |
  | `Standard` | big blind | `TurnLimit 10` · 道念高者胜 |
  | `Finale` | boss blind | `TurnLimit 12` · `WinMargin 0`（不落后即通过；落后即角色终结） |

  **`combatTier` 是必需的，不是修饰。** Finale 是篇章边界闸门、ADR-0004 篇章重试模型的锚点、道统残卷的唯一累积源与兑现点；这三处都需要一个**可机械判定**的判据。靠内容 `Id` 或 location 配置去认出「这是渡劫」是反模式（见 `data-resource-rules.md`「绝不用场景路径、数组索引或显示名作内容的键」的同源理由）。
- **Explore 是元类型，继承遮罩语义。** 遮罩一个**固定的**事件（在该 Explore 内容条目上已指定，**非点击时临时生成**），进入时才揭示。可被遮罩的真身取值域 = **Combat / Travel / Exchange**；**Research 不可被遮罩**（卡组编辑是玩家主动规划的动作，藏起来只制造挫败），**Explore 自身不可嵌套**（元类型定义使然）。
- **交易吸收社交。** 「与 NPC 谈条件」与「在商店买东西」共有同一套事件式结算形状与呈现形状，分成两类只是在内容风味上切一刀，而风味不需要枚举值来承载。
- **Travel 不是常驻可选项。** 仅当当前 location 的 `eventCountLimit` 达成时**必定**出现（本批收窄为仅剩 Travel）；其余时候是否出场不保证，即便地图上连通的邻接地域也不保证都出场。候选的呈现走 **80 / 20 掷定**：80% 列出全部邻接，20% seeded 随机取一个；**Explore 揭示出的 Travel 必为随机那一档**。
- **休养 / Rest 不作为顶层类型**——休整 / 恢复并入 **战斗** 或 **闭关** 之中发生。
- **开局强制构筑事件归 Research。** 起始批次中让玩家选一门功法 + 一件法宝（各三选一）的那个强制事件，是 Research 的一个条目——不需要第六类，承载机制是既有的 `eventPriority = 1`。

## Consequences
- **内容 schema：** 每个 `AdventureEvent` 数据条目带一个类型枚举（**五值**）；`eventType == Combat` 的条目另带 `combatTier`（三值）。`Explore` 需要一个「揭示」机制，在进入时映射到其被遮罩的固定事件。
- **结算路径不变，仍是两个 resolver。** `CombatEventResolver` 接 `Combat` 一类（三档共用），`GenericEventResolver` 接其余四类。收为五类后这条拆分更干净：**resolver 的数量与 `eventType` 的数量本就不对应**，因为拆分轴是「有没有状态机」，不是「有几个类型」。
- **Practice / Finale 的既有设计整体保留**，只是挂载点从 `eventType` 移到 `combatTier`：Finale 的天劫 Enemy、`±2` 赋级带、遭遇参数初值、「一篇章一个 Finale、败后不可重战」、残卷规则；Practice 的 small blind 参数与 `EnemyData.EncounterScopes` 两层敌人池（`[Practice]` / `[Combat]` 改为按档位取值），全部照旧。
- **落实「并非每个事件都是战斗」**：五类中只有 `Combat` 走战斗结算，其余四类是事件 / 抉择流程；`Explore` 视其真身可能落到战斗结算上。
- 无独立的休整节点类型；恢复必须由 Combat / Research 事件承载，或由其它系统（法宝 / 属性）提供。
- **`combatTier` 的字段形态：它是模板常量，落 `EncounterSpec.Tier`（由 future-event-service 物化时从模板代入），`EventOption` 与 `PastEventEntry` 两处都不加独立字段**——呈现与履历两个消费方本就要按 `EventId` 查模板取显示名，tier 在同一次查表里拿到。见 `systems/adventure-event/combat/_index.md`。
- 待办：`Explore` 揭示池的权重，属内容与平衡设计范畴。
- Source: `handoffs/2026-08-15c-event-type-collapse-and-batch-shape.md`。
