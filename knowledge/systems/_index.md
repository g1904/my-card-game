# 系统索引（引用层）

> **权威：`game-design-documents/systems/`**（类模型化结构；它持有**类定义**，具体**条目实例**归平级的 `game-design-documents/content/`）。已定案决策见 `decisions/ADR-*`。本索引是**导航表 + 代码现状**——设计内容不在此复述。

## 代码现状

**尚未实现任何系统**（全新脚手架，无 `.cs` / `.tscn` / `.tres`）。下表 `状态` 列如实反映这一点；每个系统**一旦在代码中存在**，才为它建独立的 `systems/<name>.md`——**不要预先创建空占位**。

| 系统 | 权威文档（`systems/`） | 状态 | 职责 |
|--------|------|--------|----------------|
| 架构总览 | `architecture.md` | 参考 | 结构与边界的权威：API 契约总则、物化模型、EventBus 负载契约、共享核心类型。 |
| 系统层共有属性 | `common-properties.md` | 参考 | 所有系统共享的字段 / 约定。 |
| ViewModel 层 | `viewmodel.md` | 参考 | 呈现期对象的横切纪律（依赖方向 / 生命周期 / 组装源 / 重组装触发面 / 缓存归属 / 永不渲染清单）。非服务、非 autoload。 |
| 平衡 | `balance.md` | TODO | 花费、伤害、掉落权重、篇章 / 等级维度的缩放曲线。 |
| 游戏进程 | `game-progression.md` | TODO | eventOptions 循环推进、location（地域）、travel 路由、难度与数值缩放的**分格轴**。**编排顶点**。 |
| 修行事件（顶层） | `adventure-event/_index.md` | TODO | 顶层 + 顶层共有属性；下含**五个**子类型（ADR-0002）。 |
| ├ 战斗 | `adventure-event/combat/` | TODO | 回合结构、敌人 AI、胜负结算。**`combatTier` 三档共用同一套代码，差异只在遭遇参数**——档位成员与各档 `TurnLimit` 取值去权威文档看。**`combatTier` 是模板常量，物化管线里没有任何一步在掷 tier**——配比是内容编排的涌现结果，不得为它加字段 / 加权重表 / 加管线步骤（`decisions/ADR-0173-combat-tier-mix-authoring-only.md`）。**唯一的族级例外：战后奖励候选池四族中 `PowerData` 只进 `Standard` / `Finale`，`Practice` 整族排除**（`decisions/ADR-0169-combat-reward-four-family-pool.md`）。 |
| ├ 交易 | `adventure-event/exchange/` | TODO | 交易 / 商店机制；**社交语境并入本类**。 |
| ├ 闭关 | `adventure-event/research/` | TODO | 钻研 / 潜修；开局的强制构筑事件归本类。 |
| ├ 探索秘境 | `adventure-event/explore/` | TODO | **唯一的元类型**：遮罩一个固定事件，进入即揭示真身。 |
| └ 前往某处地点 | `adventure-event/travel/` | TODO | **地图路由**：刷新角色所在 location。`eventCountLimit` 用尽即收窄为仅剩 Travel —— **结构性闸门**，别写成「可选的移动事件」。 |
| 敌人 | `enemies/` | TODO | **与 adventure-event 平级**：`EnemyData` ↔ `EnemyInstance`、样本卡组、作用域取池、**赋级带是无例外的硬规则**——赋级函数不接受任何区间覆盖参数，带边界住平衡资源、随 overlay 可调（取值见权威「赋级带的接受面」）；代码标识符叫 `EnemyLevelRange`，**不叫 `LevelBand`**（Band 已被隐藏属性档占用）。三个 `combatTier` 档共享同一批条目。 |
| 角色档案 | `character-profile/_index.md` | TODO | 轮回级主档（字段面见权威）。**隐藏属性是一个封闭的两成员枚举 `HiddenStat`，寿元不在其列**（成员表与「写第三个编译不过」的依据见 `architecture.md`「共享核心类型」与 `decisions/ADR-0168-hidden-stat-roster-closure.md`）。**模板 `CharacterData` ≠ 轮回态 `CharacterProfile`**。 |
| ├ Deck | `character-profile/deck/` | TODO | draw/hand/discard 牌堆、seeded 洗牌、卡牌定义与结算。**构筑单位 = 功法 `CultivationTechnique`**（整组入组 / 整组替换），带层数 `TechniqueTier`。 |
| ├ 道具 | `character-profile/item/` | TODO | 角色持有的道具。 |
| ├ 神通（CharacterPower） | `character-profile/power/` | TODO | 轮回级能力，对标账号级 PlayerPower（法则）。 |
| ├ 货币 | `character-profile/currency.md` | TODO | 轮回货币分**两层**，且**二者完全不可兑换**——不设任何兑换通道，写一条即让双层退化为「单层 + 汇率」。层名、字段名与取值面见权威。 |
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
| 商业化 | `monetization.md` | TODO | **商业化三支**：① premium bundle（**MVP 唯一已实施的付费点**、可重复购买——能力 / 道具项每次都给，重试上限项只在首购生效、不叠加；授予按账号级序号水位**逐次兑现**，授予内容 / 三道空池闸 / 序号形态见权威）· ② 纯外观（架构预留）· ③ **付费解锁角色系列**（后续版本引入；系列化推出、单向棘轮、整系列礼包定价、**严格横向不卖强度**）。② ③ **首批均一格不落**。法则闸门配额。→ `decisions/ADR-0255-paid-character-series-track.md` |

## 承重纪律

- **拆分轴 = 生命周期层 + 行为边界，不是数据类型**：**只有 Combat 真有状态机**，其余四类事件共享同一形状、差异在数据而非代码 ⇒ 落地为**两个** `IEventResolver` 实现，不是五个。→ `systems/architecture.md`「总则 8」、`decisions/ADR-0011-api-contract-principles.md`
- **物化模型**：`AdventureEventData` 是模板，**future-event-service 是唯一物化点**，`EventOption` 产出即定稿、不可改写、落存档；下游只读消费、不回查模板重算。→ `systems/architecture.md`「总则 6」
- **新增一个事件 = 新增一个 `.tres`**，不是新增一段代码——可加性是这套拆分的验收标准。
- **跳过通道整体不存在**：一批只有一次操作（择一进入），别为「跳过」写任何分支或字段。→ `systems/game-progression.md`
- **不存在「参战方身上的 buff 列表」**：集合性 / 有过期时刻的效果一律走**战场**，栈与战场是两个区。→ `systems/services/combat-service.md`
- **`DeckModule` 没有重洗代码路径**：弃牌堆不回流，抽空后继续抽即**疲劳** ⇒ 道念的削减通道有两条，别假设「一切结算都经卡牌」。→ `systems/services/combat-service.md`
- **疲劳是一等栈条目（`StackEntryKind.Fatigue`），不是抽牌循环里的一段内联扣分**：照常压栈、LIFO 结算、可被监听 / 可被响应、扣减量可经 `ModifierTarget.FatigueAmount` 削到 0。写进抽牌流程即在结算之外开第二个后门。**「削到 0」是字面的**——经 `StaticModifierData { What = FatigueAmount }` 修正后的疲劳量允许取 0，**不得 clamp 到最小 1 或加保底**，极限精简是被支持的高阶路线。→ `decisions/ADR-0088-fatigue-as-stack-entry.md`、`ADR-0230-minimal-deck-as-supported-route.md`
- **五行动词（金削拆 / 木滚雪球 / 水连锁 / 火爆发 / 土稳固）只是内容归池口径，不得在代码中产生任何相生相克 / 属性克制判定**——灵根唯一的规则后果仍只是功法修习准入。顺手加一个五行克制系数编译得过、线上可见，却直接推翻 ADR-0123。→ `decisions/ADR-0232-affinity-combat-verb-mapping.md`、`ADR-0123-affinity-technique-learning-gate.md`
- **兜底敌人 AI 保持 1-ply、零随机、零记忆**，权重取向固定为「产道念 > 削 / 拆」；拆台一类的性格差异**只作逐条目 `EnemyAiProfileData` 覆写**，不进兜底层。→ `decisions/ADR-0233-fallback-ai-mirrors-player-tone.md`
- **两条隐藏属性剧情线同形且零新结构**：`PlotArcData` 取 `SideStory`（非 `SideChapter`）、**`ChapterScope` 恒空**（顺手填上会让剧情线跨篇章时静默不触发）、两条共用同一 `ExclusiveGroup`（不设互斥则双条件角色同时开两条线），boss 走 `PlotModulation` 既有六字段；不新增字段 / 内容类型 / 枚举成员 / 存档字段，不 bump `schemaVersion`。→ `decisions/ADR-0254-hidden-stat-side-story-shape.md`
- **收口前的重算走只读投影 `profile-service.Project(spec)`，不开第二个写入面**：新一批 eventOptions 必须依**更新后的** profile 算出，故先投影、再把结果以 `with` 派生回同一份 spec、**一次** `TryApply`。投影只在该段同步代码内用，不存字段、不跨 `await`。→ `decisions/ADR-0108-profile-readonly-projection.md`
- **集合字段名与元素类型名恒为单数形态对应，且二者不得逐字相同**（`RealmArtworks : RealmArtwork[]`）——同名会让类内成员查找遮蔽同名类型，`new RealmArtwork()` 当场无法解析。→ `decisions/ADR-0105-singular-collection-field-naming.md`
- **一个效果该做成卡牌 / 法宝 / 神通，按「每次生效要付什么代价」第一命中即定型**：重付代价（mana + 打出）→ 卡牌；有次数上限、玩家主动花 → 法宝；存在即生效、无代价、一局内不消耗 → 神通。**推论：`PowerData` 同时缺 mana 与 `Charges` 两格 ⇒ 任何随对局延长而累积的效果一律不得写成神通，回寿元恒不得写成神通；而战斗外的全局改写只能写成神通。** → `systems/character-profile/power/_index.md`
- **随进度变化的数值，分格轴只有两条**：全局等级序 1–22（相对量）与篇章 ch1–ch3（绝对量纲吸收）。新增任何缩放旋钮，其分格列必须是这两条之一；**需要第三条轴（章内进度 / 已走过 location 数一类）须先立 ADR**——本作不设 ante 式章内难度阶梯。→ `decisions/ADR-0163-no-ante-intra-chapter-difficulty-ladder.md`
- **轮回出口的「清理」分三层，两条出口不对称**：L1 运行时拆解 / L2 运行态字段清空两条出口都做；**L3 角色实体状态处置只在 `defeated` 做——`completed` 保留（那就是境界存档本身）**。`chapterRetry` 必须归第三类字段，否则重试计数永远停在 1、上限静默失效；`TeardownCycle()` 收窄为纯运行时拆解、零存档语义。→ `decisions/ADR-0165-cycle-exit-three-layer-teardown.md`
- **`pastEvent` / `pastItemUse` 跨篇章只追加**：不在篇章边界清空、不随篇章重试回滚；「本篇章事件数」由篇章起始 `Seq` 锚点求差得出，不另建篇章坐标系。→ `decisions/ADR-0166-trace-append-only-across-chapters.md`
- **灵根修习准入不进 `DrawPool<T>`**：它要读 `Profile` 的 `Affinities`，故由调用方在 `PickMany` 之前筛掉，**玩家侧四处取池点各叠一层**（闭关 / 开局构筑 / 商店功法族 / 战后奖励功法族）——漏一处即放出学不了的功法。→ `decisions/ADR-0123-affinity-technique-learning-gate.md`
- **引入多灵根角色是零结构变更**：区分模式取 `RequiredAffinities` 多元素（复合功法）+ `MaxCharacterAffinityCount`（数量上限）的**双机制组合，两条均已在现行 `CanLearn` 判定式内**——零新字段、零新机制、零新枚举；`Affinities` 本就是数组，「首批长度恰为 1」是内容编排口径而非字段约束，别把它写成校验。**通用 / 专属功法配比同样是编排口径、不是字段约束**（`/audit-content` 只报告不阻断）。→ `decisions/ADR-0258-multi-affinity-free-track-and-pool-split.md`、`ADR-0257-generic-technique-ratio-by-rarity.md`
- **能力的「启用开关」与「拥有 / 失去」是两条互不覆盖的写入通道**：`Status` 走 `AbilityStatusChanges`（绝对置值），获得 / 失去走 `AbilityElements` 的 `Grant` / `Remove`；**`StatusChanges` 不承载 `Status`**——它绑的是 `CharacterProfile.Status` 上的数值格，名字撞车、语义无交集，写错即把开关写进数值面。→ `systems/player-profile/_index.md`
- **成就的达成态与发放水位一律不可由派生量反推**：`Completed` 不写成 `Progress >= Target`（`Target` 可 overlay 上调 ⇒ 已达成的里程碑会在一次内容更新后回退，而奖励不可补发），`RewardedTierPercent` 也不由「奖励条目已在持有列表」反推。→ `decisions/ADR-0196-achievement-save-shape-two-keys.md`
- **后两支付费面都是「加法窗口保持开启」而非「先埋占位」**：外观首批不得增加任何字段（含 `PlayerEntitlement.Cosmetic`）、屏、内容类型或资产类目；**付费角色轨道同理——解锁载体（`PlayerProfile` 具名集合 + 取池过滤 + 一次 `schemaVersion` bump）与 `CharacterData` 的轨道标记字段首批一格不落**，形态待 `/provide-solution-draft` 推演。预先埋格没有收益且要多 bump 一次 schema。→ `systems/monetization.md`、`decisions/ADR-0255-paid-character-series-track.md`
- **法则（`(Power, Player)` 域）的合法 `Source` 恰三个**：`FinaleWin`（道统残卷）· `PremiumBundle` · `AchievementReward`（成就 90% 档）。**`EventOutcome` / `ExchangePurchase` 是规则层封死、不是「暂不开放」**——分域校验表上三格（`EventOutcome × (Power, Player)` · `EventOutcome × (Item, Player)` · `ExchangePurchase × (Power, Player)`）一律拒绝，顺手放开即开出一条后端无输入可复算的账号级永久授予，并旁路掉残卷那条受调控的递减曲线。→ `decisions/ADR-0267-player-power-three-acquisition-channels.md`、`systems/player-profile/player-power/_index.md`

> 横切的引擎层关注（存档 / 读档、UI / 屏幕、输入 / 触摸、音频）不在 `systems/` 内单列——代码承载形式见 `autoloads/_index.md`、`scenes/_index.md` 与 `standards/*`。

## 如何添加一条系统说明

系统落地后创建 `systems/<name>.md`，写**代码侧**事实：入口点（场景 / 脚本）、涉及的类与文件路径、经 ProfileManager 读写哪些字段、发射 / 消费哪些 EventBus 事件、用哪条 RNG 子流、存档触点、已知的坑。回链到 `systems/` 的权威文档，并把此处状态改为一句摘要。**设计意图与字段 schema 写在设计库，不在这里复制。**
