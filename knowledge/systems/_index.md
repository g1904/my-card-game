# 系统索引（引用层）

> **权威设计意图：`game-design-documents/20-systems/`**（类模型化结构；本库为**内容 + 技术结构的双重事实来源**）。本索引已降为**指向该库的引用层**——结构一一对应，不再自持副本。已定案的决策见 `game-design-documents/50-decisions/ADR-*`。
>
> **内容即系统的字段 / 内嵌类型**——不单列内容层。Source: `game-design-documents/10-handoffs/2026-07-24-docs-restructure-class-model.md`。

roguelike 卡组构建游戏的游戏系统。每个系统**一旦在代码中存在**，就成为独立的 `systems/<name>.md` 说明——不要预先创建空占位。状态如实标注：目前尚未实现任何系统（全新脚手架）。

| 系统 | 权威设计文档（`20-systems/`） | 状态 | 职责 |
|--------|------|--------|----------------|
| 架构总览 | `architecture.md` | 参考 | 代码库如何运作的高层指南；系统结构总览、微服务边界。 |
| 系统层共有属性 | `common-properties.md` | 参考 | 所有系统共享的字段 / 约定。 |
| 平衡 | `balance.md` | TODO | 花费、伤害、掉落权重、ante 缩放。 |
| 游戏进程 | `game-progression.md` | TODO | 每 ante 的分支节点 map、location（地域）、travel 路由、blind/ante 缩放。 |
| 修行事件（顶层） | `adventure-event/_index.md` | TODO | 修行事件顶层 + 顶层共有属性；下含 9 个子类型。 |
| ├ 战斗 | `adventure-event/combat/` | TODO | 回合结构、敌人 intent/AI、胜负结算。 |
| ├ 境界突破 | `adventure-event/finale/` | TODO | 篇章边界高潮 / 收尾战。 |
| ├ 未知 | `adventure-event/mystery/` | TODO | 遮罩一个固定 AdventureEvent。 |
| ├ 修炼 | `adventure-event/practice/` | TODO | 比试 / 切磋——低风险战斗式历练。 |
| ├ 交易 | `adventure-event/exchange/` | TODO | 交易 / 商店机制（可购道具定义见 player-profile/player-item）。 |
| ├ 闭关 | `adventure-event/research/` | TODO | 钻研 / 潜修。 |
| ├ 探索秘境 | `adventure-event/explore/` | TODO | **探索一处秘境**（第八类，新增）。 |
| ├ 社交 | `adventure-event/social/` | TODO | 与 NPC / 势力的社交互动。 |
| └ 前往某处地点 | `adventure-event/travel/` | TODO | **地图路由选择**：刷新角色所在 location（第九类，新增）。 |
| 角色档案 | `character-profile/_index.md` | TODO | 单次 run / 单角色状态：`status`（ongoing/defeated/completed）、`chapter`、life / mana + 隐藏属性（道心 / 煞气 / 寿元）、修行历程、key points。由 `PlayerProfile` 持有。 |
| ├ Deck | `character-profile/deck/` | TODO | draw/hand/discard 牌堆、seeded 洗牌、卡牌定义与结算。 |
| ├ 道具 | `character-profile/item/` | TODO | 角色持有的道具。 |
| ├ 货币 | `character-profile/currency.md` | TODO | run 货币（gold）的获取/花费。 |
| ├ 生命 | `character-profile/life.md` | TODO | 生命 / HP。 |
| └ 法力 | `character-profile/mana.md` | TODO | 每回合出牌资源。 |
| 玩家档案 | `player-profile/_index.md` | TODO | 账号级元进程主档（跨 run 持久）。 |
| ├ 玩家道具 | `player-profile/player-item/` | TODO | 可购道具定义。 |
| └ 玩家能力 | `player-profile/player-power/` | TODO | 被动修饰器 / relic-joker，通过 EventBus 挂接。 |
| 服务层（总览） | `services/_index.md` | TODO | **两级层次 service ⊃ manager**、拆分轴原则、七服务清单。详见下表与 `autoloads/_index.md`。 |
| ├ 账号 | `services/account-service.md` | TODO | 登录渠道、token / 会话、合规。（AuthManager、ComplianceManager） |
| ├ 内容 | `services/content-service.md` | TODO | `res://` 基线 + `user://overlay/` 热更、按 Id 索引。**唯一内容读取入口。**（ContentRegistry、ContentUpdateManager） |
| ├ 同步 | `services/sync-service.md` | TODO | 存档与云同步：Pull / Push、原子写、schema 迁移。（ProfileSyncManager、LocalCacheManager、MigrationManager） |
| ├ 档案 | `services/profile-service.md` | TODO | **两个 Profile 的唯一写入面**；capability 聚合；成就。（ProfileManager、CapabilityManager、AchievementManager） |
| ├ 生命周期 | `services/life-cycle-service.md` | TODO | Run 生命周期：开始(seed)、推进、胜/负、清理。（RunStateManager、ChapterManager、SeedManager） |
| ├ 未来事件 | `services/future-event-service.md` | TODO | 依 CharacterProfile 产出 eventOptions；**唯一出口**。（EventOptionManager、PlotManager） |
| │　└ 剧本管理器 | `services/plot-manager.md` | TODO | **manager，隶属 future-event-service**（非独立服务）：隐藏剧本层级、隐藏属性驱动、key points、eventOptions 调制。 |
| └ 战斗 | `services/combat-service.md` | TODO | 回合循环、抽/弃/洗、敌人意图。**Finale 复用同一状态机。**（TurnManager、DeckManager、IntentManager） |
| 计分 | `scoring.md` | TODO | 计分模型（chips × mult，或并入战斗）。去向待确认，见 `open-questions.md`。 |

> **编排顶点 = game-progression**（不是服务，是屏幕流程编排层）：核心循环 `ComputeEventOptions → 呈现 → 玩家选择 → AdvanceEvent → 重算` 由它串联；**服务之间不互相直呼**。
>
> **拆分轴 = 生命周期层 + 行为边界，不是数据类型。** 不按 power / item / card / resource 各开服务，也不为九类 AdventureEvent 各开服务——只有 Combat 真有状态机，其余七类共享同一形状（呈现 → 选择或跳过 → 校验扣成本 → 应用产出 → 推拉隐藏属性 → 收口），差异在**数据**而非**代码**；Mystery 揭示后落到真实 `eventType`。

> 横切的引擎层关注（存档/读档、UI/屏幕、输入/触摸、音频）不在 `20-systems/` 内单列，其代码承载形式见 `autoloads/_index.md`、`scenes/_index.md` 及 `standards/*`（存档格式、移动端 UI）。

## 如何添加一条系统说明
当你实现一个系统时，创建 `systems/<name>.md`，涵盖：入口点（场景/脚本）、涉及的类、它如何经 **ProfileManager** 读写 **PlayerProfile / CharacterProfile**、发射/消费哪些 **EventBus** 信号、用哪条 **SeedManager 具名 RNG 子流**、存档触点，以及已知的坑。回链到 `20-systems/` 的对应权威文档，然后将此处的状态改为一句简短的摘要。
