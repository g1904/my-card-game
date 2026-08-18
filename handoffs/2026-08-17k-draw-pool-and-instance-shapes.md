# 抽取原语与物化实例形态

- id: 2026-08-17k-draw-pool-and-instance-shapes
- date: 2026-08-17
- topic: systems/services/content-service · systems/services/profile-service · systems/player-profile/player-power · systems/enemies · systems/services/future-event-service · systems/adventure-event/common-properties · systems/game-progression · systems/services/plot-manager · systems/services/combat-service · systems/common-properties · terminology
- status: distilled
- distilled-to: systems/enemies/_index.md, systems/enemies/common-properties.md, systems/services/future-event-service.md, systems/services/combat-service.md, systems/services/plot-manager.md, systems/services/profile-service.md, systems/services/content-service.md, systems/services/life-cycle-service.md, systems/adventure-event/common-properties.md, systems/game-progression.md, systems/common-properties.md, systems/player-profile/player-power/_index.md, systems/balance.md, systems/monetization.md, systems/architecture.md, terminology.md

## Intent（distilled）

三条待答项被合并收口，共同点是**都在问「物化 / 抽取侧的类型长什么样」**。收口的结果里有相当一部分是**把已在别处答定的结论收拢成单一权威**，而非新造设计。

### 一 · 抽取原语只有两级，不设第三级

| 级 | 类型 | 宿主 | 职责 |
|---|---|---|---|
| 第一级 | `DrawPool<T>`（`readonly struct`） | content-service | 抽取动作在语言层的唯一发起面：`Filter` / `PickOne` / `PickMany`（无放回）/ 加权重载 |
| 第二级 | `GrantPoolPicker`（`internal sealed`） | profile-service | 能力授予的唯一取池处：四道过滤 + 排重 + 稀有度锚定，残卷 / 礼包 / 置换共用 |

- **分界判据 = 这道过滤需不需要读 `Profile`。** 不需要的（`ContentEnabled` / `ExclusiveSource` / `Rarity`）留第一级；需要的（排除已持有）只能在第二级。
- 否决「再造一个通用原语」：第三级只会给「抽取代码只有一处」多一个绕行入口，且策略参数化无法被编译器约束。
- **推论**：全库抽取代码的落点恰好两处，其余调用方都是「构造 `DrawPool<T>` 再 `PickOne`」的三五行。
- **权重表结构面**：分表维度按**用途**（授予 / 战后奖励），不按渠道、不按 `(Kind, Scope)`；表住 `systems/balance.md`，不落 `DrawPool<T>`。
- **门面缺口补齐**：置换走具名方法 `TryPickReplacement(kind, scope, anchorRarity, rng, out pickedId)`，不给既有方法加可空 `anchorRarity` 形参——可空默认值会让「忘了锚定」成为最短路径，而忘了锚定的置换把 Tier1 换成 Tier5，能上线、线上不可见。
- **Exchange 的能力族商品走 `TryPickGrantableMany`**，其余三族直用第一级；不给第二级新开入口。

### 二 · 账号级 `ordinal` 一律「先算后写」

先算 `ordinal = 旧值 + 1` → 用它掷骰 → 同一个值随同一次 `TryApply` 写回。礼包侧本已如此写，残卷侧此前未明写。它不是文风问题：后端用**存档里的（自增后）**序号复算 `roll'` 并要求与 `LastRoll` 相等，两侧口径不一致会在**每一个正常账号上**稳定误报。序号自增与是否抽中 / 是否发放无关。

### 三 · `PoolScope` = 带两个具名可空字段的内嵌 `Resource`

`PoolScope { string LocationId; string PlotArcId; }`，匹配 = 逐维度与门、空维度恒真，arc 一侧传**全部 `Active` arc 的集合**（并发 arc 下「当前剧情线」不是单值，取单值会让 side arc 的专属敌人永不出现）。`EnemyData.PoolScope` 允许为 `null` = 通用池。

- 取具名字段而非 tag：悬空校验是硬要求且要求类型已知；维度由既有权力面封闭，tag 的可加性优势不存在。
- 字段定名 `PlotArcId`（本库剧情线的载体是 `PlotArcData`）。
- 加载期四条校验：两条悬空 `PushError`、空壳 `PushWarning`、**某 `EventType` 下通用池为空 → 启动期 `PushError`**。

### 四 · 敌人池归属单权威

`LocationData.EnemyTemplateIds` 删除，池归属的唯一权威是 `EnemyData.PoolScope`。两侧各存一份表达同一关系，会各自漂移而本库无机制发现。

- **叠加而非替代（承重）：** 本作不存在地域独占生态——通用敌人恒可在任何地域出现，地域 / arc 专属条目是在通用池之上加项。这与「共享敌人池 + 作用域字段，而非另立一批条目」同一条判据。
- 代价如实记：「这个地域会遇到什么」需反查，归 `LocationCodex`（运行时统计），不是内容编写面。
- **`PlotModulation.EnemyPoolScope` 保留**，`PlotModulation` 维持六字段。它是一个 `PlotArcData.Id`、通常填本 arc 自己的 `Id`，但允许填别的 arc——这是一条有意保留的权力（「剧情线 boss」正靠它派心魔 / 煞气化身），代价用一条加载期悬空校验从「静默换池」变为「大声报错」。

### 五 · 战斗类 `EventOption` 承载 `EncounterSpec`

`EventOption` 加第 13 格可空 `EncounterSpec Encounter`，`EnemyInstance` 嵌其内。

- 嵌一格 vs 平铺七格；`RunCombatAsync(EncounterSpec, ct)` 签名不动，不产生第二装配点。
- 校验按**真身**类型判（战斗真身的 Explore 壳其 `Encounter` 物化时即填好，依据同为防重掷）。
- `EncounterId` 与 `EventOption.InstanceId` 冗余，**写明为例外而非先例**（同 `LifeSpanAfter`）。
- `activeCombat.enemyRef` = `EnemyInstance.InstanceId`，读档经 `activeEvent.Option.Encounter.Enemy.InstanceId` 比对。
- `PastEventEntry` 加轻摘要 `EnemyTraceRef(EnemyId, Level)`；不存卡组 / 道具 / power 三个列表。

## Clarifications（interview 产物）

- **删 `LocationData.EnemyTemplateIds` 会连带删掉「硬框定」这一能力本身 → 维持删除，并明写「叠加而非替代」。** 推翻了原文只写「反查代价」这一处轻描述，并改写了「硬分池只发生在敌人那一侧」「location 决定派谁来」两句承重表述。
- **`PlotModulation.EnemyPoolScope` 是否删除 → 保留（推翻原文的「删」）。** 原文删除的唯一论据是「无用例」，而「剧情线 boss」正是一个已写下的用例；字段可填错的代价用一条悬空校验消化。`PlotModulation` 维持六字段。
- **「通用池在某 `(EventType, 篇章)` 组合下为空 → `PushError`」 → 降为 `EventType` 单维。** 库内无任何字段表达篇章框定，两维校验今天写不出来；不臆造 `EnemyData` 的篇章字段，改立一条待答。
- **`activeCombat.enemyRef` 的形态（此前由两片互相 defer） → `EnemyInstance.InstanceId`。** 存模板 id 会丢等级、拷贝整份会造出第二个落点。
- **「敌人实例只有一份」这条依据在派生实例持整份快照之后如何成立 → 保留嵌套结论、重写依据。** 新依据：嵌套让敌人实例在同一份定稿实例内只有一个落点；跨落点副本由既定的快照语义统一管辖，结算期读取权威只有一处。
- **残卷 `ordinal` 口径的对侧处置 → 确认对齐 + 一处措辞消歧。** 后端契约的措辞已蕴含自增后口径，客户端补写即与它一致；对侧落一条确认性承接项，并在其客户端伪码行显式标注「本次（自增后）序号」。

## Open questions

- **敌人池的篇章框定载体未定。** 取池第三层写着「篇章框定」，而 `EnemyData` 上没有字段表达它；载体定下前，通用池空池校验只能按 `EventType` 单维实现。
- **`PickMany` 抽不足 `count` 时 Research 候选与 Exchange 库存的调用侧处置未定**（少给几个槽位 / 商品位，还是另有兜底）。
- **`RarityTier` 的战后奖励三表数值、`GrantPoolMargin` / `K` 取值** —— 本次只定结构面，数值归 ch1 数值标杆专场。
- `[采纳推荐 — 待复核]`：`PoolScope` 取具名可空字段的内嵌 `Resource`（第 2 项）· Exchange 能力族商品走 `TryPickGrantableMany`（第 6 项）。

## Notes / triage

来源草稿 `inbox/solution-draft-draw-pool-and-instance-shapes.md`（已评审，六项取向全部裁决）。三条移出的待答项与一条部分移出记于 `answer-logs/log-draw-pool-and-instance-shapes.md`。
