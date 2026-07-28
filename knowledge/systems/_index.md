# 系统索引（引用层）

> **权威：`game-design-documents/20-systems/`**（类模型化结构；内容即系统的字段 / 内嵌类型，不单列内容层）。已定案决策见 `50-decisions/ADR-*`。本索引是**导航表 + 代码现状**——设计内容不在此复述。

## 代码现状

**尚未实现任何系统**（全新脚手架，无 `.cs` / `.tscn` / `.tres`）。下表 `状态` 列如实反映这一点；每个系统**一旦在代码中存在**，才为它建独立的 `systems/<name>.md`——**不要预先创建空占位**。

| 系统 | 权威文档（`20-systems/`） | 状态 | 职责 |
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
| └ 前往某处地点 | `adventure-event/travel/` | TODO | **地图路由**：刷新角色所在 location。 |
| 角色档案 | `character-profile/_index.md` | TODO | 轮回级：`status`、`chapter`、life / mana + 隐藏属性（道心 / 煞气 / 寿元）、修行历程、key points、RNG 状态。 |
| ├ Deck | `character-profile/deck/` | TODO | draw/hand/discard 牌堆、seeded 洗牌、卡牌定义与结算。 |
| ├ 道具 | `character-profile/item/` | TODO | 角色持有的道具。 |
| ├ 货币 | `character-profile/currency.md` | TODO | 轮回货币（灵玉 jade）的获取 / 花费。 |
| ├ 生命 | `character-profile/life.md` | TODO | 生命 / HP。 |
| └ 法力 | `character-profile/mana.md` | TODO | 每回合出牌资源。 |
| 玩家档案 | `player-profile/_index.md` | TODO | 账号级元进程主档（跨轮回持久）。 |
| ├ 玩家道具 | `player-profile/player-item/` | TODO | 账号级、有次数限制的道具。 |
| ├ 玩家能力 | `player-profile/player-power/` | TODO | 被动修饰器 / relic-joker；capability flag + modifier pipeline。 |
| ├ 成就 | `player-profile/achievements/` | TODO | 成就分组与档位进度。归 AchievementManager。 |
| ├ 账号信息 | `player-profile/account-info.md` | TODO | 账号级元数据。 |
| └ 游戏设置 | `player-profile/game-setting.md` | TODO | 音频 / 显示 / 辅助功能等玩家设置。 |
| 服务层 | `services/_index.md` | TODO | 两级层次 + 七服务；各服务文档带 API 契约表。**服务清单见 `autoloads/_index.md`。** |
| 计分 | `scoring.md` | TODO | 计分模型去向待确认，见 `open-questions.md`。 |

## 承重纪律

- **拆分轴 = 生命周期层 + 行为边界，不是数据类型。** 不按 power / item / card / resource 各开服务，也不为九类 AdventureEvent 各开服务——**只有 Combat 真有状态机**，其余七类共享同一形状（呈现 → 选择或跳过 → 校验扣成本 → 应用产出 → 推拉隐藏属性 → 收口），差异在**数据**而非代码。落地为**两个** `IEventResolver` 实现，不是九个。
- **物化模型**（贯穿 adventure-event 与 future-event-service）：`AdventureEventData` 是模板，**future-event-service 是唯一物化点**，产出的 `EventOption` **即定稿、不可改写、落存档**；下游只读消费，不回查模板重算。
- **新增一个事件 = 新增一个 `.tres`**，不是新增一段代码。可加性是这套拆分的验收标准。

> 横切的引擎层关注（存档 / 读档、UI / 屏幕、输入 / 触摸、音频）不在 `20-systems/` 内单列——代码承载形式见 `autoloads/_index.md`、`scenes/_index.md` 与 `standards/*`。

## 如何添加一条系统说明

系统落地后创建 `systems/<name>.md`，写**代码侧**事实：入口点（场景 / 脚本）、涉及的类与文件路径、经 ProfileManager 读写哪些字段、发射 / 消费哪些 EventBus 事件、用哪条 RNG 子流、存档触点、已知的坑。回链到 `20-systems/` 的权威文档，并把此处状态改为一句摘要。**设计意图与字段 schema 写在设计库，不在这里复制。**
