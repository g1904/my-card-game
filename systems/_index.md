# 系统 —— 设计意图索引（类模型化结构）

各游戏系统的动态设计文档，以**类概念（Java class 式）**组织：每个系统是一个「类」，其内容（数据定义）是该类的「字段 / 内嵌类型」。复杂类型下沉为文件夹（含 `_index.md` 与 `common-properties.md`），简单主题保持单 `.md`。

文件名 / 文件夹与 `.claude/knowledge/systems/` 对应；`.claude/knowledge/*` 为指向本库的**引用层**（本库为游戏内容 + 技术结构的双重事实来源）。

**本区持有「这类内容怎么运作」（类定义）；具体条目实例归平级的 `../content/`**（`content/<类型>/<id>.md`）。判据：**讲这一类内容的规则 → 本区；讲某一个具体条目 → `content/`。** 条目文档只写「填了什么值 + 回链本区」，不复述字段定义。

| 文档 / 文件夹 | 用途 |
|-----|---------|
| [architecture](architecture.md) | 代码库如何运作的高层指南；系统结构总览、服务边界。 |
| [common-properties](common-properties.md) | 系统层共有属性（所有系统共享的字段 / 约定）。 |
| [balance](balance.md) | 平衡表：花费、伤害、掉落权重、ante 缩放。 |
| [viewmodel](viewmodel.md) | 展示层第三层的结构契约：依赖方向、组装源、重组装触发面、只读消费与缓存归属、永不渲染清单。 |
| [game-progression](game-progression.md) | 每个 ante 的进程推进（eventOptions 循环）、location（地域）、Travel 路由、blind/ante 缩放。 |
| [adventure-event/](adventure-event/_index.md) | 修行事件顶层：**5 个子类型** + 顶层共有属性。 |
| &nbsp;&nbsp;├ [combat/](adventure-event/combat/_index.md) | 战斗事件；**`combatTier` 三档**（修炼 / 常规 / 境界突破）、mana + 道念模型、敌人 AI（**行动不作事前预告**，可读性归敌人回合的逐步执行呈现）、结算。 |
| &nbsp;&nbsp;├ [exchange/](adventure-event/exchange/_index.md) | 交易机制，含社交语境（可购道具定义见 player-profile/player-item）。 |
| &nbsp;&nbsp;├ [research/](adventure-event/research/_index.md) | 闭关：调整 / 升阶卡组（含开局强制构筑事件）。 |
| &nbsp;&nbsp;├ [explore/](adventure-event/explore/_index.md) | 探索秘境；**唯一的元类型**，遮罩一个固定事件。 |
| &nbsp;&nbsp;└ [travel/](adventure-event/travel/_index.md) | 前往某处地点（地图路由，刷新 location；非常驻可选项）。 |
| [enemies/](enemies/_index.md) | **敌人**（与 adventure-event 平级）：`EnemyData` ↔ `EnemyInstance`、样本卡组、item / power 持有列表、`EncounterScopes` 与 `PoolScope`、`±2` 赋级带的接受面。三个 `combatTier` 档共享同一批条目。 |
| [character-profile/](character-profile/_index.md) | 角色档案（单次轮回 / 单角色的状态与历史）。 |
| &nbsp;&nbsp;├ [deck/](character-profile/deck/_index.md) | 卡组、抽牌/hand/弃牌、seeded 洗牌、卡牌定义、起始卡组。 |
| &nbsp;&nbsp;├ [item/](character-profile/item/_index.md) | 角色持有的道具。 |
| &nbsp;&nbsp;├ [power/](character-profile/power/_index.md) | **神通 CharacterPower**（轮回级，对标账号级 PlayerPower / 法则）。 |
| &nbsp;&nbsp;├ [currency](character-profile/currency.md) | 轮回货币：灵石 spiritStone · 仙玉 immortalJade。 |
| &nbsp;&nbsp;├ [lifeSpan](character-profile/life-span.md) | 寿元 / **角色唯一的资源命线**（两个扣减来源：事件成本与战斗失败；战斗过程中不被读写；归 0 → defeated；回复走 outcome 侧三通道）。 |
| &nbsp;&nbsp;└ [mana](character-profile/mana.md) | 法力 / 每回合出牌资源。 |
| [player-profile/](player-profile/_index.md) | 玩家档案（跨轮回的元进程）。 |
| &nbsp;&nbsp;├ [player-item/](player-profile/player-item/_index.md) | 可购道具定义。 |
| &nbsp;&nbsp;├ [player-power/](player-profile/player-power/_index.md) | 被动修正 / relic-joker。 |
| &nbsp;&nbsp;├ [achievement/](player-profile/achievement/_index.md) | 分组成就与两档（60% / 90%）一次性奖励。 |
| &nbsp;&nbsp;├ [codex/](player-profile/codex/_index.md) | **图鉴族**：Enemy / CharacterPower / PlayerPower / CharacterItem / PlayerItem / Location / Technique —— 账号级静态文案知识，不含动态情报，战斗中一律不可查。 |
| &nbsp;&nbsp;├ [account-info](player-profile/account-info.md) | 账号身份与状态元数据。 |
| &nbsp;&nbsp;└ [game-setting](player-profile/game-setting.md) | 账号级常规系统设置。 |
| [services/](services/_index.md) | 服务层索引：**层级 service ⊃ manager ⊃ module ⊃ processor ⊃ handler**、拆分轴原则、七个服务清单。 |
| &nbsp;&nbsp;├ [account-service](services/account-service.md) | 登录渠道、token / 会话、合规。（AuthManager、ComplianceManager） |
| &nbsp;&nbsp;├ [content-service](services/content-service.md) | 内容资产：`res://` 基线 + `user://overlay/` 热更、按 Id 索引、统一仓储接口。**唯一内容读取入口。** |
| &nbsp;&nbsp;├ [sync-service](services/sync-service.md) | 存档与云同步：Pull / Push、原子写、schema 迁移。 |
| &nbsp;&nbsp;├ [profile-service](services/profile-service.md) | **两个 Profile 的唯一写入面**；capability 聚合；成就。（ProfileManager、CapabilityManager、AchievementManager） |
| &nbsp;&nbsp;├ [life-cycle-service](services/life-cycle-service.md) | 轮回生命周期：开始(seed)、推进、胜/负、清理。（CycleStateManager、ChapterManager、SeedManager） |
| &nbsp;&nbsp;├ [future-event-service](services/future-event-service.md) | 依 characterProfile 产出 eventOptions；**eventOptions 的唯一出口**。 |
| &nbsp;&nbsp;│&nbsp;&nbsp;└ [plot-manager](services/plot-manager.md) | **manager，隶属 future-event-service**：隐藏剧本（剧本层级、隐藏属性驱动、key points、eventOptions 调制）。 |
| &nbsp;&nbsp;└ [combat-service](services/combat-service.md) | 战斗驱动：**固定 10 回合**循环、抽/弃/洗、敌人 AI 与意图（**三档揭示**）；**Practice / Finale 为其变体**。（TurnManager、CharacterManager、EnemyManager；`DeckModule` 为参战方内部第三级组件） |
| [scoring](scoring.md) | **计分模型 = 道念（momentum）**：胜利点数，且**就是战斗的胜负判据**（**固定 10 回合**后道念高者胜；起始道念 = `baseMomentum`）。 |
| [monetization](monetization.md) | 商业化：**premium bundle**（随机 1 PlayerPower + 2 PlayerItem + 篇章重试上限 3→9 / 1→3）。 |

> 只有在确有真实设计意图时，才在此新增系统文档 / 文件夹；保持文件名与 knowledge 索引一致。复杂主题新增时下沉为文件夹（`_index.md`，按需 + `common-properties.md`）。
>
> **`common-properties.md` 按内容建，不按对称建。** 一层要建 `common-properties.md`，须**两条同时成立**：① 该层存在**其子节点共有、且不适用于全库**的属性或机制（否则它属顶层）；② 这批内容的篇幅已压过 `_index.md` 的索引职责（经验界：约 40 行以上，或超过该层 `_index.md` 的一半）。因此 `character-profile/` 与 `player-profile/` **有意不建**中间层 `common-properties.md`（两者的横切共性各只有一两句，已写在各自 `_index.md` 内），而 `adventure-event/` 与 `enemies/` 建了。**结构不对称不是缺陷，是判据的正确产物**——空壳 `common-properties.md` 会成为一个「看起来该写点什么」的坑，把本属顶层的字段吸下来复述一遍，造出第二权威。字段写在哪一层的完整判据卡见 [common-properties](common-properties.md) 的 `## 内容共有字段` 节首。

Source: `handoffs/2026-08-30-life-lifespan-merge.md` · `handoffs/2026-08-14-common-properties-layering.md`
