# 系统索引（引用层）

> **权威：`game-design-documents/systems/`**（类模型化结构；它持有**类定义**，具体**条目实例**归平级的 `game-design-documents/content/`）。已定案决策见 `decisions/ADR-*`。本索引是**导航表 + 代码现状**——设计内容不在此复述。

## 代码现状

**尚未实现任何系统**（全新脚手架，无 `.cs` / `.tscn` / `.tres`）。下表 `状态` 列如实反映这一点；每个系统**一旦在代码中存在**，才为它建独立的 `systems/<name>.md`——**不要预先创建空占位**。

| 系统 | 权威文档（`systems/`） | 状态 | 职责 |
|--------|------|--------|----------------|
| 架构总览 | `architecture.md` | 参考 | 结构与边界的权威：API 契约总则、物化模型、EventBus 负载契约、共享核心类型。 |
| 系统层共有属性 | `common-properties.md` | 参考 | 所有系统共享的字段 / 约定。 |
| ViewModel 层 | `viewmodel.md` | 参考 | 呈现期对象的横切纪律（依赖方向 / 生命周期 / 组装源 / 重组装触发面 / 缓存归属 / 永不渲染清单）。非服务、非 autoload。 |
| 平衡 | `balance.md` | TODO | 花费、伤害、掉落权重、ante 缩放。 |
| 游戏进程 | `game-progression.md` | TODO | eventOptions 循环推进、location（地域）、travel 路由、blind/ante 缩放。**编排顶点**。 |
| 修行事件（顶层） | `adventure-event/_index.md` | TODO | 顶层 + 顶层共有属性；下含**五个**子类型（ADR-0002）。 |
| ├ 战斗 | `adventure-event/combat/` | TODO | 回合结构、敌人 AI、胜负结算。**`combatTier` 三档共用同一套代码，差异只在遭遇参数**——档位成员与各档 `TurnLimit` 取值去权威文档看。 |
| ├ 交易 | `adventure-event/exchange/` | TODO | 交易 / 商店机制；**社交语境并入本类**。 |
| ├ 闭关 | `adventure-event/research/` | TODO | 钻研 / 潜修；开局的强制构筑事件归本类。 |
| ├ 探索秘境 | `adventure-event/explore/` | TODO | **唯一的元类型**：遮罩一个固定事件，进入即揭示真身。 |
| └ 前往某处地点 | `adventure-event/travel/` | TODO | **地图路由**：刷新角色所在 location。`eventCountLimit` 用尽即收窄为仅剩 Travel —— **结构性闸门**，别写成「可选的移动事件」。 |
| 敌人 | `enemies/` | TODO | **与 adventure-event 平级**：`EnemyData` ↔ `EnemyInstance`、样本卡组、作用域取池、**`±2` 赋级带**（无例外硬规则——赋级函数不接受任何区间覆盖参数；代码标识符叫 `EnemyLevelRange`，**不叫 `LevelBand`**，Band 已被隐藏属性档占用）。三个 `combatTier` 档共享同一批条目。 |
| 角色档案 | `character-profile/_index.md` | TODO | 轮回级主档（字段面见权威）。**隐藏属性恰两项 —— 道心 `Faith` / 煞气 `Bloodlust`**；寿元是明文资源、**不在其列**（`HiddenStat` 只有两个成员，写第三个编译不过）。**模板 `CharacterData` ≠ 轮回态 `CharacterProfile`**。 |
| ├ Deck | `character-profile/deck/` | TODO | draw/hand/discard 牌堆、seeded 洗牌、卡牌定义与结算。**构筑单位 = 功法 `CultivationTechnique`**（整组入组 / 整组替换），带层数 `TechniqueTier`。 |
| ├ 道具 | `character-profile/item/` | TODO | 角色持有的道具。 |
| ├ 神通（CharacterPower） | `character-profile/power/` | TODO | 轮回级能力，对标账号级 PlayerPower（法则）。 |
| ├ 货币 | `character-profile/currency.md` | TODO | 轮回货币**两层**：灵石 `spiritStone`（基础）· 仙玉 `immortalJade`（高阶）。**二者完全不可兑换**——不设任何兑换通道，写一条即让双层退化为「单层 + 汇率」。 |
| ├ 寿元 | `character-profile/life-span.md` | TODO | **`lifeSpan` = 角色唯一的一条命**，既是寿命预算也是失败惩罚承受量。**单值：无上限字段、无上限截断**（别拆成 `currentLifeSpan / lifeSpanLimit`）；**战斗内不被读写**，只在收口时刻被扣；归 0 → `defeated`。 |
| └ 法力 | `character-profile/mana.md` | TODO | 每回合出牌资源；`manaLimit` 幅度恒为 1。 |
| 玩家档案 | `player-profile/_index.md` | TODO | 账号级元进程主档（跨轮回持久）。 |
| ├ 玩家道具 | `player-profile/player-item/` | TODO | 账号级、有次数限制的道具。 |
| ├ 玩家能力 | `player-profile/player-power/` | TODO | 被动修饰器 / relic-joker；capability flag + modifier pipeline。 |
| ├ 成就 | `player-profile/achievement/` | TODO | 成就分组与档位进度；归 AchievementManager。 |
| ├ 图鉴 | `player-profile/codex/` | TODO | **图鉴族七本**（成员表见权威）。账号级静态文案知识，不含动态情报；**接触即记、七本在战斗中一律不可查**。`LocationCodex` 是唯一词条间有拓扑关系的（记连边，故呈现形态必然不同）。 |
| ├ 账号信息 | `player-profile/account-info.md` | TODO | 账号级元数据。 |
| └ 游戏设置 | `player-profile/game-setting.md` | TODO | 音频 / 显示 / 辅助功能等玩家设置。 |
| 服务层 | `services/_index.md` | TODO | 层级词表 + 七服务；各服务文档带 API 契约表。**服务清单见 `autoloads/_index.md`。** |
| 计分 | `scoring.md` | TODO | **计分模型 = 道念（momentum）**：既是胜利点数，也**就是战斗的胜负判据**。 |
| 商业化 | `monetization.md` | TODO | premium bundle —— **唯一付费点、买断式一次授予**（授予内容与「只在首次购买生效、不叠加」的限定见权威）；法则闸门配额。 |

## 承重纪律

- **拆分轴 = 生命周期层 + 行为边界，不是数据类型**：**只有 Combat 真有状态机**，其余四类事件共享同一形状、差异在数据而非代码 ⇒ 落地为**两个** `IEventResolver` 实现，不是五个。→ `systems/architecture.md`「总则 8」、`decisions/ADR-0011-api-contract-principles.md`
- **物化模型**：`AdventureEventData` 是模板，**future-event-service 是唯一物化点**，`EventOption` 产出即定稿、不可改写、落存档；下游只读消费、不回查模板重算。→ `systems/architecture.md`「总则 6」
- **新增一个事件 = 新增一个 `.tres`**，不是新增一段代码——可加性是这套拆分的验收标准。
- **跳过通道整体不存在**：一批只有一次操作（择一进入），别为「跳过」写任何分支或字段。→ `systems/game-progression.md`
- **不存在「参战方身上的 buff 列表」**：集合性 / 有过期时刻的效果一律走**战场**，栈与战场是两个区。→ `systems/services/combat-service.md`
- **`DeckModule` 没有重洗代码路径**：弃牌堆不回流，抽空后继续抽即**疲劳** ⇒ 道念的削减通道有两条，别假设「一切结算都经卡牌」。→ `systems/services/combat-service.md`
- **疲劳是一等栈条目（`StackEntryKind.Fatigue`），不是抽牌循环里的一段内联扣分**：照常压栈、LIFO 结算、可被监听 / 可被响应、扣减量可经 `ModifierTarget.FatigueAmount` 削到 0。写进抽牌流程即在结算之外开第二个后门。→ `decisions/ADR-0088-fatigue-as-stack-entry.md`
- **收口前的重算走只读投影 `profile-service.Project(spec)`，不开第二个写入面**：新一批 eventOptions 必须依**更新后的** profile 算出，故先投影、再把结果以 `with` 派生回同一份 spec、**一次** `TryApply`。投影只在该段同步代码内用，不存字段、不跨 `await`。→ `decisions/ADR-0108-profile-readonly-projection.md`
- **集合字段名与元素类型名恒为单数形态对应，且二者不得逐字相同**（`RealmArtworks : RealmArtwork[]`）——同名会让类内成员查找遮蔽同名类型，`new RealmArtwork()` 当场无法解析。→ `decisions/ADR-0105-singular-collection-field-naming.md`
- **灵根修习准入不进 `DrawPool<T>`**：它要读 `Profile` 的 `Affinities`，故由调用方在 `PickMany` 之前筛掉，**玩家侧四处取池点各叠一层**（闭关 / 开局构筑 / 商店功法族 / 战后奖励功法族）——漏一处即放出学不了的功法。→ `decisions/ADR-0123-affinity-technique-learning-gate.md`

> 横切的引擎层关注（存档 / 读档、UI / 屏幕、输入 / 触摸、音频）不在 `systems/` 内单列——代码承载形式见 `autoloads/_index.md`、`scenes/_index.md` 与 `standards/*`。

## 如何添加一条系统说明

系统落地后创建 `systems/<name>.md`，写**代码侧**事实：入口点（场景 / 脚本）、涉及的类与文件路径、经 ProfileManager 读写哪些字段、发射 / 消费哪些 EventBus 事件、用哪条 RNG 子流、存档触点、已知的坑。回链到 `systems/` 的权威文档，并把此处状态改为一句摘要。**设计意图与字段 schema 写在设计库，不在这里复制。**
