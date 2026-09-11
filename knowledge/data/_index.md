# 数据索引（引用层）

> **类定义与条目实例分两处**：**「这类内容怎么运作」的权威在 `game-design-documents/systems/`**（字段、schema、取值域、平衡数值），**「有哪些条目」的权威在 `game-design-documents/content/`**（一条内容一份文档 + 类型档案）；管线、仓储接口、三层覆盖与增量下载的完整形状在 `systems/services/content-service.md`。**此处只留导航、代码现状与承重一句话——字段表、枚举、流程步骤一律去权威文档看。** 规则：`.claude/rules/data-resource-rules.md`。

## 代码现状

**尚未编写任何内容。** `game-feature-branch/` 无 `.tres`、无 `XxxData : Resource` 类、无 `res://content/` 目录。**`content/` 也尚无任何已开张的类型**（只有 `_index.md` 与模板）。下表是**规划**。

## 内容类型 → 权威位置

| 类型 | Resource 类（规划） | 权威设计位置（`systems/`） |
|------|--------------------|------------------------------|
| Card（卡牌） | `CardData` | `character-profile/deck/` |
| 卡牌次类型 | `CardSubtypeData` | `character-profile/deck/`（`.tres` 注册表，**不是 C# 枚举**；**清单已归零、机制保留**——`enchantment.ambush` 是埋伏定名而非清单条目 → `content/_index.md`） |
| 功法 | `CultivationTechniqueData` | `character-profile/deck/`——**卡组的构筑单位** |
| 角色（模板） | `CharacterData` | `character-profile/`（≠ 轮回态 `CharacterProfile`） |
| 法则 / 神通（Power） | **两层共用 `PowerData`**（层级由 `AbilityScope` 声明） | `player-profile/player-power/`、`character-profile/power/` |
| 异能 / 效果原语 / 触发条件 | `AbilityData` / `EffectData` / `TriggerConditionData` / `StaticModifierData` | `character-profile/deck/common-properties.md`「效果原语与定义体」；**异能不独立开张为内容文件夹**，先内联在宿主条目内 → `content/_index.md` |
| Enemy（敌人） | `EnemyData` ↔ `EnemyInstance` | `enemies/`（与 adventure-event 平级） |
| 敌人 AI 策略 | `EnemyAiProfileData` | `enemies/` |
| 成就 | `AchievementData`（**内联 `AchievementConditionData`**，不独立开张） | `player-profile/achievement/` |
| 成就组 | `AchievementGroupData` | `player-profile/achievement/`（成就按组授奖，**两个 `Resource` 类型 = 两个内容类型**） |
| AdventureEvent（修行事件） | `AdventureEventData` | `adventure-event/`（五个子类型，ADR-0002） |
| 法宝 / 古宝（可购道具） | **两层共用 `ItemData`**（古宝另受 `Charges > 0` 硬约束） | `player-profile/player-item/`、`character-profile/item/` |
| 效果关键字 | `KeywordData` | `character-profile/deck/`（首批清单为空、机制保留） |
| Location（地域） | `LocationData` | `game-progression.md`（平坦集合，**无 C# 枚举**） |
| `locationMap`（地域图） | `LocationMapData` | `game-progression.md`（**单份全局邻接表资源**，不由各 location 各持边；`ISingletonContent`） |
| 隐藏属性档位 | `HiddenStatBandData` | `services/plot-manager.md` |
| 遭遇参数 | `EncounterSpec`（`sealed record`，非 `Resource`） | **类定义在 `services/combat-service.md`**；`adventure-event/combat/` 是消费方 |
| 平衡配置（单例） | 若干 `ISingletonContent` 资源（**逐份切、无兜底大表**；切分判据是**三问**——① 消费者是谁 ② 覆写纪律（相反 ⇒ 必须分开）③ 有无跨字段不变式（有 ⇒ 必须同住）） | 三问判据与逐份落点 / 清单 → `balance.md`；注册形态与加载期校验 → `services/content-service.md` |
| 剧本线 / 剧本节点 | `PlotArcData` / `PlotNodeData` | `services/plot-manager.md`（**本地内容层**，随 overlay 分发） |

**内容条目有一组顶层共有字段，定义只在最小公共祖先一层**；字段清单、各字段的挂载面与判据卡在 `systems/common-properties.md`「内容共有字段」，**此处不复制**。

## 承重纪律（写代码时会改变写法的那几条）

1. **`Id` 是稳定唯一的字符串，也是唯一的交叉引用键**——绝不按名称、数组下标或场景路径引用内容。**`Id` 内不含 `#` / `:`**（这两个字符已被战斗内 counters 键语法占用，混入即让键空间失去可解析性）。→ `systems/services/combat-service.md`
2. **抽取走 `AllEnabled()`，读取侧 `Get(id)` 不过滤**（存档引用不能悬空）；**仓储上没有中性名 `All()`**，全量走 `AllIncludingDisabled()`，写下 `All()` 会编译失败。漏写过滤即线上事故：能上线、线上不可见。→ `systems/services/content-service.md`
3. **抽取代码全库只有两处落点**：`DrawPool<T>`（content-service，只认内容侧过滤）与 `GrantPoolManager`（profile-service，读 `Profile` 的排重与稀有度锚定；**不叫 `GrantPoolPicker`**——`Picker` 后缀不在层级词表内），**不设第三级原语**；其余调用方都是「构造 `DrawPool<T>` 再 `PickOne`」的三五行。**`DrawPool<T>` · `LocalizedText` · `ISingletonContent` + `Single<T>()` 是同一次 `XxxData` / 注册表面的纯加法改造，同批排在第二阶段开工前、第一份 `.tres` 之前**（此前 `AllEnabled()` 仍返回 `IReadOnlyList<T>`），不可再往后拖——写完再改就从纯加法退化为改全部调用方 / 全部资产。→ `systems/services/content-service.md`
4. **`XxxData : Resource` 是模板不是成品，运行时绝不写它**——它是注册表里的共享只读单例，写回会污染同一轮回的后续批次与其他角色；**服务签名里传实例，不传 `Resource`**。→ `systems/architecture.md`
5. **「内容定义 + 情境 / 轮回内状态」恒是两个类型**：`AdventureEventData` ↔ `EventOption`（定稿不可变、落存档）、`EnemyData` ↔ `EnemyInstance`（同左，等级即物化产物）、`CardData` ↔ `CardInstance`（运行态可变）。→ `systems/architecture.md`「总则 6」
6. **静态展示文案留在 `XxxData` 上、类型是 `LocalizedText` 而非裸 `string`**，`Get()` 只读、绝不把解析结果写回条目（那会污染注册表共享单例）；`LocalizedText` 不落存档、不进上行负载。→ `systems/common-properties.md`
7. **校验点在合并之后**：overlay + 基线合并完再统一校验重复 `Id` 与悬空引用，启动期 `GD.PushError` 早失败；**`ContentEnabled == false` 的条目照常参与全量校验**。→ `systems/services/content-service.md`
8. **可调数值存导出字段 / 单例平衡资源**，绝不硬编码在系统逻辑里；**不散落 `ResourceLoader.Load`**，一切内容经 ContentRegistry——**平衡表也走同一条路**（直读 `res://content/balance/*.tres` 即当场失去 overlay 热更与合并后强校验）。唯一例外是消费点早于 `LoadAll()` 的管线旋钮，写死为代码常量。→ `systems/services/content-service.md`
9. **单例平衡资源用 `Content.Single<T>()` 取，调用方不碰 `Id`**；单例身份由标记接口 `ISingletonContent` 声明，`where T : ISingletonContent` 是编译闸（对 `CardData` 调 `Single<T>()` 编译不过），条数 `!= 1` 或 `ContentEnabled == false` 在加载期 `PushError` + 抛。写 `Id` 字面量去查单例即引回一个可拼错的字符串键。→ `systems/services/content-service.md`
10. **敌人与玩家共用 `CardData` 体系但不共用卡池**：`Pool` 是必填、无默认值，漏填即坏数据（默认值会让敌方内容悄悄进玩家奖励池）；**卡组规模两侧皆不设硬限**（代价由疲劳承接）。→ `systems/character-profile/deck/_index.md`（`Pool` 定义与卡池划分）、`systems/enemies/_index.md`（敌方卡组规模）
11. **敌人池归属的唯一权威是 `EnemyData` 上的作用域字段**（`LocationData` 不持敌人清单）；地域 / arc 专属条目是**叠加而非替代**——通用敌人恒可在任何地域出现。取池是叠在 `AllEnabled()` 之后的三层过滤，**各层「空」的语义不对称是有意的，别当漏写去「修正」**。→ `systems/enemies/_index.md`、`systems/enemies/common-properties.md`
12. **`MoveCardEffect` 只有一格 `Side`，`From` 与 `To` 恒同侧——跨方搬牌在结构上写不出来，这是有意的**（闭集不变式按侧成立）；别拆成 `FromSide` / `ToSide`。配套校验：`Selection == Chosen` 且 `Side != Self` → `PushError`。→ `systems/character-profile/deck/common-properties.md`
13. **本作不存在多敌人场景**——敌人实例单数，嵌在 `EventOption.Encounter` 内，不要预留 `List<EnemyInstance>`。→ `systems/adventure-event/combat/common-properties.md`、`systems/enemies/_index.md`
14. **奖励池是 `.tres` 上的具名成员清单（id 形态 `reward.<chN>.<tier>`），不是过滤器组**——`EncounterSpec` 携带的是 `string` id（过滤器组装不出 id），且「取池不足」的加载期断言要求加载期能数出条数；`combatTier` 的厚薄差异**只换池，不换权重表、不换抽数**。→ `decisions/ADR-0241-named-reward-pools-per-chapter-tier.md`
15. **`EncounterSpec.RewardPoolId` 可空**——别照第 10 条 `Pool` 必填的样子把它也写成必填：为空 ⇒ 本场不开可选奖励，`activeCombat.reward` 恒 `null`、决策点 `D6` 不出现、呈现层不渲染空面板。→ `decisions/ADR-0240-reward-pool-id-nullable-throughput.md`
16. **`RarityFilter` 只表达族 / 档倾向，绝不用来整档排除**——三处产出面五档一律可达，卡档会让权重表某几格变成死配置且篇章维静默归零；「每池五档非空」是 `/audit-content` 的报告项、不是加载期硬闸。→ `decisions/ADR-0238-every-pool-covers-all-five-tiers.md`
17. **稀有度权重表与授予表同住一份 `ISingletonContent`（`RarityWeightsData`），且权重表不进 `DrawPool<T>`**；加载期三闸缺一不可——权重 > 0、逐篇章随机占优、任一 `r_eff < 1`（漏掉上界闸即分布单调上升、最稀有档反成最常见）。取值表去权威看。→ `decisions/ADR-0237-rarity-weight-tables-and-chapter-multiplier.md`、`systems/balance.md`
18. **事件掉散牌与商店库存恒取 `Solid` 权重表 × 本篇章 `m(c)`，不新增表也不新增字段**——这两侧没有 `advantage` 可填，必须硬走 Solid 分支，别留空或默认取第一张表。→ `decisions/ADR-0239-non-combat-draws-use-solid-table.md`
19. **起始卡组逐角色独立立形，不建「共享底盘 + 变体覆写」的模板层**；**角色选择屏不得新增 `IsRecommended` 一类推荐标记字段、不得按复杂度排序**（排序即隐式推荐），玩法简介走既有 `LocalizedText`。→ `decisions/ADR-0229-no-shared-starter-deck-baseline.md`、`ADR-0234-first-play-brief-without-recommendation.md`
20. **`BaseReward` 的默认 element 面结构上只有灵石一格**——不得开第二格、不得改成集合；额外惩罚一律写成 `Spoils` 内的负向 `ChangeElement`。开第二格即与仙玉 / 经验 / 回寿 / `ManaLimit` / 四族内容各自已有的通道构成双发放通道。→ `decisions/ADR-0249-base-reward-single-element-slot.md`
21. **`HiddenStatGrants` 对五类事件一律开放；「`Travel` 不带推拉」与语义 → `(Stat, Direction, Grade)` 映射表只做 `/audit-content` 汇总项，绝不写成加载期校验**——顺手补一条 `if (type == Travel && grants.Count > 0) PushError` 编译得过、看着更严谨，却在结构上推翻了「五类无一例外开放」。→ `decisions/ADR-0251-hidden-stat-semantic-orchestration-table.md`
22. **回寿法宝的频率 / 深度 / 定价三格只进 `/audit-content` 报告，不写成加载期 `PushError`**（铺内容途中会持续报错，该写法已被明确否决）；不为它单设 stock rule、不开 `RarityFilter` 专属位、不填 `PriceOffset`。→ `decisions/ADR-0247-lifespan-item-orchestration-guardrails.md`
23. **道具战斗外可写 key 是白名单 `{ CostKey.LifeSpan }`，加载期硬校验 `I-13`（`PushError` + 条目 `Id` + 报出该 `Key`）**——货币 / `ManaLimit` / `ExperiencePoint` / `Faith` / `Bloodlust` 与六个账号层 `CostKey` 全在拒绝面。**`I-13` 与 `I-6` 并存不合并**（`I-6` 管 `Op` 是否在 `AllowedOps` 内，`I-13` 管 key 的编排准入），**事件侧与道具侧的两张 key 表各自独立、永不合并**。放开任一格即从道具侧重开已封的经验 / 隐藏属性 / 道统碎片三个口。→ `decisions/ADR-0260-item-outofcombat-key-whitelist.md`、`systems/character-profile/item/_index.md`
24. **只有产出进入某条已被反推封账的预算线的道具族才需要独立供给护栏**（寿元账 / 货币账 / 经验账 / 卡组规模口径）——战斗内八原语的六族一条都不进，由既有的折价系数 + 定价表 + 稀有度权重表承接，**不要为它们补第四套口径**。→ `decisions/ADR-0261-family-guardrail-necessity-criterion.md`
25. **Exchange 逐族库存深度上界按 `Kind` 分组求和即得，不新开字段**（与槽位总数上界是同一次分组）；它与 barter 的两格护栏（档差对价、≤ 1 条 / 店）**一律只进 `/audit-content` 汇总、不落加载期硬校验**——编排口径不是不变式，合理例外存在。事件侧给法宝的 `X-1` 是 `PushWarning` 而非拒绝，职责是让每个例外被看见。→ `decisions/ADR-0262-exchange-per-kind-stock-depth.md`、`ADR-0264-barter-tier-gap-and-count-cap.md`、`ADR-0263-event-side-item-grant-volume.md`

## 三层覆盖来源与热更边界

`res://content/` 基线 < `user://overlay/` 热更 < **flags**（只覆盖 `ContentEnabled` 一个布尔），合并后统一校验 → ContentRegistry 按 `Id` 索引。**完整形状、校验闸与下载事务见 `systems/services/content-service.md`，此处只留边界纪律：**

- **热更范围 = 只改不增；剧本内容是唯一例外**，且该例外已是合并期硬校验、不再是约定。→ `systems/services/content-service.md`
- **发版通道的反方向同样封死：随包基线只增不删——跨发版的基线 `Id` 集合单调不减。** 超集**只在 `Id` 集合层面**成立（字段值与 `ContentEnabled` 可自由改，那正是退役路径的载体）；退役 = 置 `ContentEnabled = false` / 合规移除**掏空而非删除**；**改名 = 删 + 增，同样禁止**。机械闸在基线快照归档步，按 semver 版本序与上一版比对，出现「上一版有、本版无」的 `Id` → 非零退出。删一条 = 老档 `Get(id)` 抛错 ⇒ **升级即废档**。→ `decisions/ADR-0182-baseline-id-superset-invariant.md`
- **flags 只能覆盖 `ContentEnabled`，不得携带任何数值 / 文案 / 新 `Id`**——它能秒关正因为被限制得足够窄；作用点唯一 = `AllEnabled()` 取池。→ `systems/services/content-service.md`
- **结构性查表类与一切 `ISingletonContent` 恒启用**：`ContentEnabled == false` 即加载期 `PushError`、flags 对其不生效——线上关掉一条即结构空洞（邻接集合为空、轮回死锁），**清单去权威看、别在此处抄**。→ `systems/services/content-service.md`
- **不冻结轮回的 `contentVersion`**：overlay 更新对进行中的轮回立即生效，已放弃跨内容版本的 seed 可复现。→ `standards/rng-determinism.md`
- **增量下载 = 文件级事务 + manifest 签名**，原子写 manifest 即提交点，**永不存在半套 overlay**。→ `systems/services/content-service.md`
- **二进制资产不经 overlay / blob 通道下发**：overlay 只能把资产引用改指到**随包基线内已存在**的资产、或置空（→ ViewModel 占位回落）；换图 / 加图随版本发布。这正是「文件级事务、不做字节级断点续传」所依赖的前提。**纯加法窗口在第一批 `.tres` 写下时关闭。** → `decisions/ADR-0125-no-binary-over-overlay.md`
- **`Artwork` 可空是常态、缺失不是坏数据**：告警形态是 `LoadAll()` 收口一行汇总，**逐条目不告警**。→ `decisions/ADR-0120-content-artwork-and-enemy-lines.md`
- **一切内容都在本地，没有云端内容通道**（含剧本文本）：运行时内容零网络请求，网络只在启动期做 manifest 比对与增量下载。→ `systems/services/plot-manager.md`
