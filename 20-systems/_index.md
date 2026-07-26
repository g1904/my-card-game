# 系统 —— 设计意图索引（类模型化结构）

各游戏系统的动态设计文档，以**类概念（Java class 式）**组织：每个系统是一个「类」，其内容（数据定义）是该类的「字段 / 内嵌类型」。复杂类型下沉为文件夹（含 `_index.md` 与 `common-properties.md`），简单主题保持单 `.md`。

文件名 / 文件夹与 `.claude/knowledge/systems/` 对应；`.claude/knowledge/*` 为指向本库的**引用层**（本库为游戏内容 + 技术结构的双重事实来源）。

| 文档 / 文件夹 | 用途 |
|-----|---------|
| [architecture](architecture.md) | 代码库如何运作的高层指南；系统结构总览、服务边界。 |
| [common-properties](common-properties.md) | 系统层共有属性（所有系统共享的字段 / 约定）。 |
| [balance](balance.md) | 平衡表：花费、伤害、掉落权重、ante 缩放。 |
| [game-progression](game-progression.md) | 每个 ante 的分支节点 map、location（地域）、Travel 路由、blind/ante 缩放。 |
| [adventure-event/](adventure-event/_index.md) | 修行事件顶层：9 个子类型 + 顶层共有属性。 |
| &nbsp;&nbsp;├ [combat/](adventure-event/combat/_index.md) | 战斗事件；回合结构、敌人意图/AI、结算。 |
| &nbsp;&nbsp;├ [finale/](adventure-event/finale/_index.md) | 境界突破 / 收尾战。 |
| &nbsp;&nbsp;├ [mystery/](adventure-event/mystery/_index.md) | 神秘事件。 |
| &nbsp;&nbsp;├ [practice/](adventure-event/practice/_index.md) | 修行 / 练习事件。 |
| &nbsp;&nbsp;├ [exchange/](adventure-event/exchange/_index.md) | 交易 / 商店机制（可购道具定义见 player-profile/player-item）。 |
| &nbsp;&nbsp;├ [research/](adventure-event/research/_index.md) | 闭关 / 研究事件。 |
| &nbsp;&nbsp;├ [explore/](adventure-event/explore/_index.md) | 探索秘境（第八类）。 |
| &nbsp;&nbsp;├ [social/](adventure-event/social/_index.md) | 社交事件。 |
| &nbsp;&nbsp;└ [travel/](adventure-event/travel/_index.md) | 前往某处地点（第九类；地图路由，刷新 location）。 |
| [character-profile/](character-profile/_index.md) | 角色档案（单次 run / 单角色的状态与历史）。 |
| &nbsp;&nbsp;├ [deck/](character-profile/deck/_index.md) | 卡组、抽牌/hand/弃牌、seeded 洗牌、卡牌定义、起始卡组。 |
| &nbsp;&nbsp;├ [item/](character-profile/item/_index.md) | 角色持有的道具。 |
| &nbsp;&nbsp;├ [currency](character-profile/currency.md) | run 货币 gold。 |
| &nbsp;&nbsp;├ [life](character-profile/life.md) | 生命 / 战斗血量。 |
| &nbsp;&nbsp;└ [mana](character-profile/mana.md) | 法力 / 每回合出牌资源。 |
| [player-profile/](player-profile/_index.md) | 玩家档案（跨 run 的元进程）。 |
| &nbsp;&nbsp;├ [player-item/](player-profile/player-item/_index.md) | 可购道具定义。 |
| &nbsp;&nbsp;└ [player-power/](player-profile/player-power/_index.md) | 被动修正 / relic-joker。 |
| [services/](services/_index.md) | 服务层索引：**两级层次 service ⊃ manager**、拆分轴原则、七个服务清单。 |
| &nbsp;&nbsp;├ [account-service](services/account-service.md) | 登录渠道、token / 会话、合规。（AuthManager、ComplianceManager） |
| &nbsp;&nbsp;├ [content-service](services/content-service.md) | 内容资产：`res://` 基线 + `user://overlay/` 热更、按 Id 索引、统一仓储接口。**唯一内容读取入口。** |
| &nbsp;&nbsp;├ [sync-service](services/sync-service.md) | 存档与云同步：Pull / Push、原子写、schema 迁移。 |
| &nbsp;&nbsp;├ [profile-service](services/profile-service.md) | **两个 Profile 的唯一写入面**；capability 聚合；成就。（ProfileManager、CapabilityManager、AchievementManager） |
| &nbsp;&nbsp;├ [life-cycle-service](services/life-cycle-service.md) | Run 生命周期：开始(seed)、推进、胜/负、清理。（RunStateManager、ChapterManager、SeedManager） |
| &nbsp;&nbsp;├ [future-event-service](services/future-event-service.md) | 依 characterProfile 产出 eventOptions；**eventOptions 的唯一出口**。 |
| &nbsp;&nbsp;│&nbsp;&nbsp;└ [plot-manager](services/plot-manager.md) | **manager，隶属 future-event-service**：隐藏剧本（剧本层级、隐藏属性驱动、key points、eventOptions 调制）。 |
| &nbsp;&nbsp;└ [combat-service](services/combat-service.md) | 战斗驱动：回合循环、抽/弃/洗、敌人意图。（TurnManager、DeckManager、IntentManager） |
| [scoring](scoring.md) | 计分模型。去向待确认，见 open-questions。 |

> 只有在确有真实设计意图时，才在此新增系统文档 / 文件夹；保持文件名与 knowledge 索引一致。复杂主题新增时下沉为文件夹（`_index.md` + `common-properties.md`）。
