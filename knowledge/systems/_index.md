# 系统索引（引用层）

> **权威：`game-design-documents/systems/`**（类模型化结构；它持有**类定义**，具体**条目实例**归平级的 `game-design-documents/content/`）。已定案决策见 `decisions/ADR-*`。本索引是**导航表 + 代码现状**——设计内容不在此复述。

## 代码现状

**尚未实现任何系统**（全新脚手架，无 `.cs` / `.tscn` / `.tres`）。下表 `状态` 列如实反映这一点；每个系统**一旦在代码中存在**，才为它建独立的 `systems/<name>.md`——**不要预先创建空占位**。

| 系统 | 权威文档（`systems/`） | 状态 | 职责 |
|--------|------|--------|----------------|
| 架构总览 | `architecture.md` | 参考 | 结构与边界的权威：API 契约总则、物化模型、EventBus 负载契约、共享核心类型。 |
| 系统层共有属性 | `common-properties.md` | 参考 | 所有系统共享的字段 / 约定。 |
| 平衡 | `balance.md` | TODO | 花费、伤害、掉落权重、ante 缩放。 |
| 游戏进程 | `game-progression.md` | TODO | eventOptions 循环推进、location（地域）、travel 路由、blind/ante 缩放。**编排顶点**。 |
| 修行事件（顶层） | `adventure-event/_index.md` | TODO | 顶层 + 顶层共有属性；下含九个子类型。 |
| ├ 战斗 | `adventure-event/combat/` | TODO | 回合结构、敌人 intent/AI、胜负结算。 |
| ├ 境界突破 | `adventure-event/finale/` | TODO | 篇章边界高潮 / 收尾战。复用 combat-service。 |
| ├ 未知 | `adventure-event/mystery/` | TODO | 遮罩一个固定 AdventureEvent；揭示后落到真实 `eventType`。 |
| ├ 修炼 | `adventure-event/practice/` | TODO | 比试 / 切磋——低风险战斗式历练。 |
| ├ 交易 | `adventure-event/exchange/` | TODO | 交易 / 商店机制。 |
| ├ 闭关 | `adventure-event/research/` | TODO | 钻研 / 潜修。 |
| ├ 探索秘境 | `adventure-event/explore/` | TODO | 探索一处秘境。 |
| ├ 社交 | `adventure-event/social/` | TODO | 与 NPC / 势力的社交互动。 |
| └ 前往某处地点 | `adventure-event/travel/` | TODO | **地图路由**：刷新角色所在 location。`eventCountLimit` 用尽即收窄为仅剩 Travel（结构性闸门），目的地取自 `locationMap` 邻接集合。 |
| 敌人 | `enemies/` | TODO | **与 adventure-event 平级**：`EnemyData` ↔ `EnemyInstance`、样本卡组、`EncounterScopes` / `PoolScope`、`±2` 赋级带。三类战斗事件共享同一批条目。 |
| 角色档案 | `character-profile/_index.md` | TODO | 轮回级：`status`、`chapter`、life / mana + 隐藏属性（道心 / 煞气 / 寿元）、修行历程、key points、RNG 状态。**模板 `CharacterData` ≠ 轮回态 `CharacterProfile`**（前者是内容条目，自带一个神通与两门绑定功法）。 |
| ├ Deck | `character-profile/deck/` | TODO | draw/hand/discard 牌堆、seeded 洗牌、卡牌定义与结算。**构筑单位 = 功法 `CultivationTechnique`**（整组入组 / 整组替换），带层数 `TechniqueTier`。 |
| ├ 道具 | `character-profile/item/` | TODO | 角色持有的道具。 |
| ├ 神通（CharacterPower） | `character-profile/power/` | TODO | 轮回级能力，对标账号级 PlayerPower（法则）。 |
| ├ 货币 | `character-profile/currency.md` | TODO | 轮回货币（灵玉 jade）的获取 / 花费。 |
| ├ lifeTotal | `character-profile/life-total.md` | TODO | **战斗外**的耐久与失败惩罚承受量（战斗内不参与）；归 0 → `defeated`；经 event 恢复。 |
| └ 法力 | `character-profile/mana.md` | TODO | 每回合出牌资源；`manaLimit` 幅度恒为 1。 |
| 玩家档案 | `player-profile/_index.md` | TODO | 账号级元进程主档（跨轮回持久）。 |
| ├ 玩家道具 | `player-profile/player-item/` | TODO | 账号级、有次数限制的道具。 |
| ├ 玩家能力 | `player-profile/player-power/` | TODO | 被动修饰器 / relic-joker；capability flag + modifier pipeline。 |
| ├ 成就 | `player-profile/achievement/` | TODO | 成就分组与档位进度（60% / 90% 两档一次性奖励）。归 AchievementManager。 |
| ├ 图鉴 | `player-profile/codex/` | TODO | **图鉴族六本**：Enemy / CharacterPower / PlayerPower / CharacterItem / PlayerItem / **Location**。账号级静态文案知识，不含动态情报。`LocationCodex` 是六本里唯一词条间有拓扑关系的（记连边）。 |
| ├ 账号信息 | `player-profile/account-info.md` | TODO | 账号级元数据。 |
| └ 游戏设置 | `player-profile/game-setting.md` | TODO | 音频 / 显示 / 辅助功能等玩家设置。 |
| 服务层 | `services/_index.md` | TODO | 层级词表 + 七服务；各服务文档带 API 契约表。**服务清单见 `autoloads/_index.md`。** |
| 计分 | `scoring.md` | TODO | **计分模型 = 道念（momentum）**：既是胜利点数，也**就是战斗的胜负判据**。 |
| 商业化 | `monetization.md` | TODO | premium bundle（随机 1 PlayerPower + 2 PlayerItem + 篇章重试上限提升）；法则闸门配额。 |

## 承重纪律

- **拆分轴 = 生命周期层 + 行为边界，不是数据类型。** 不按 power / item / card / resource 各开服务，也不为九类 AdventureEvent 各开服务——**只有 Combat 真有状态机**，其余七类共享同一形状（呈现 → 选择或跳过 → 校验扣成本 → 应用产出 → 推拉隐藏属性 → 收口），差异在**数据**而非代码。落地为**两个** `IEventResolver` 实现，不是九个。
- **物化模型**（贯穿 adventure-event 与 future-event-service）：`AdventureEventData` 是模板，**future-event-service 是唯一物化点**，产出的 `EventOption` **即定稿、不可改写、落存档**；下游只读消费，不回查模板重算。
- **新增一个事件 = 新增一个 `.tres`**，不是新增一段代码。可加性是这套拆分的验收标准。
- **跳过通道整体不存在（08-06c）。** 没有 `skipCost`、没有 `ifMandatory`、没有 `AdvanceMode` 枚举——**一批只有一次操作（择一进入）**，选中一个即等价于跳过其余。别为「跳过」写任何分支。
- **不存在「参战方身上的 buff 列表」。** 集合性 / 有过期时刻的效果一律走**战场**（battlefield）；栈与战场是两个区。`CardInstance` 的运行态判据 = 有无过期时刻。
- **`DeckModule` 没有重洗代码路径（08-11c）。** 弃牌堆不回流，一场战斗内只在组装时初洗一次；抽牌堆的 `Id` 序列**只减不增**，与「一场战斗的卡牌集合是闭集」合流。抽空后继续抽 → **疲劳**（每张 −1 道念，不入栈、不产生 `PlayResult`）⇒ **道念的削减通道有两条**，别再假设「一切结算都经卡牌」。满手与疲劳互不触发。

> 横切的引擎层关注（存档 / 读档、UI / 屏幕、输入 / 触摸、音频）不在 `systems/` 内单列——代码承载形式见 `autoloads/_index.md`、`scenes/_index.md` 与 `standards/*`。

## 如何添加一条系统说明

系统落地后创建 `systems/<name>.md`，写**代码侧**事实：入口点（场景 / 脚本）、涉及的类与文件路径、经 ProfileManager 读写哪些字段、发射 / 消费哪些 EventBus 事件、用哪条 RNG 子流、存档触点、已知的坑。回链到 `systems/` 的权威文档，并把此处状态改为一句摘要。**设计意图与字段 schema 写在设计库，不在这里复制。**
