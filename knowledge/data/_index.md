# 数据索引（引用层）

> **类定义与条目实例分两处**：**「这类内容怎么运作」的权威在 `game-design-documents/systems/`**（字段、schema、取值域、平衡数值），**「有哪些条目」的权威在 `game-design-documents/content/`**（一条内容一份文档 + 类型档案）；管线、仓储接口、三层覆盖与增量下载的完整形状在 `systems/services/content-service.md`。**此处只留导航、代码现状与承重一句话——字段表、枚举、流程步骤一律去权威文档看。** 规则：`.claude/rules/data-resource-rules.md`。

## 代码现状

**尚未编写任何内容。** `game-feature-branch/` 无 `.tres`、无 `XxxData : Resource` 类、无 `res://content/` 目录。**`content/` 也尚无任何已开张的类型**（只有 `_index.md` 与模板）。下表是**规划**。

## 内容类型 → 权威位置

| 类型 | Resource 类（规划） | 权威设计位置（`systems/`） |
|------|--------------------|------------------------------|
| Card（卡牌） | `CardData` | `character-profile/deck/` |
| 卡牌次类型 | `CardSubtypeData` | `character-profile/deck/`（`.tres` 注册表，**不是 C# 枚举**） |
| 异能 | `AbilityData` | `character-profile/deck/` |
| 功法 | `CultivationTechniqueData` | `character-profile/deck/`——**卡组的构筑单位** |
| 角色（模板） | `CharacterData` | `character-profile/`（≠ 轮回态 `CharacterProfile`） |
| 法则 / 神通（Power） | `PlayerPowerData` / `PowerData` | `player-profile/player-power/`、`character-profile/power/` |
| Enemy（敌人） | `EnemyData` ↔ `EnemyInstance` | `enemies/`（与 adventure-event 平级） |
| AdventureEvent（修行事件） | `AdventureEventData` | `adventure-event/`（五个子类型，ADR-0002） |
| 可购道具 | `ItemData` / `PlayerItemData` | `player-profile/player-item/`、`character-profile/item/` |
| 效果关键字 | `KeywordData` | `character-profile/deck/`（首批清单为空、机制保留） |
| Location（地域） | `LocationData` | `game-progression.md`（平坦集合，**无 C# 枚举**） |
| `locationMap`（地域图） | `LocationMapData` | `game-progression.md`（**单份全局邻接表资源**，不由各 location 各持边；`ISingletonContent`） |
| 隐藏属性档位 | `HiddenStatBandData` | `services/plot-manager.md` |
| 遭遇参数 | `EncounterSpec`（`sealed record`，非 `Resource`） | `adventure-event/combat/` |
| 平衡配置（单例） | `CombatRulesData` / `EnemyLevelingData`（`ISingletonContent`，逐份切、**无兜底大表**） | `balance.md`；注册形态 → `services/content-service.md` |
| 剧本线 / 剧本节点 | `PlotArcData` / `PlotNodeData` | `services/plot-manager.md`（**本地内容层**，随 overlay 分发） |

**内容条目的共有字段**（`ContentEnabled` · `LocalizedText` · `Rarity` · `SourceCode` + `Source` · `ExclusiveSource`）**定义只在最小公共祖先一层**，权威见 `systems/common-properties.md`「内容共有字段」——各落点只写投影，此处不复制字段表。

## 承重纪律（写代码时会改变写法的那几条）

1. **`Id` 是稳定唯一的字符串，也是唯一的交叉引用键**——绝不按名称、数组下标或场景路径引用内容。**`Id` 内不含 `#` / `:`**（这两个字符已被战斗内 counters 键语法占用，混入即让键空间失去可解析性）。→ `systems/services/combat-service.md`
2. **抽取走 `AllEnabled()`，读取侧 `Get(id)` 不过滤**（存档引用不能悬空）；**仓储上没有中性名 `All()`**，全量走 `AllIncludingDisabled()`，写下 `All()` 会编译失败。漏写过滤即线上事故：能上线、线上不可见。→ `systems/services/content-service.md`
3. **抽取代码全库只有两处落点**：`DrawPool<T>`（content-service，只认内容侧过滤）与 `GrantPoolPicker`（profile-service，读 `Profile` 的排重与稀有度锚定），**不设第三级原语**；其余调用方都是「构造 `DrawPool<T>` 再 `PickOne`」的三五行。**`DrawPool<T>` 排期在第二阶段开工前落地**（此前 `AllEnabled()` 仍返回 `IReadOnlyList<T>`），但不可再往后拖——抽取侧写完再改返回类型就从纯加法退化为改调用方。→ `systems/services/content-service.md`
4. **`XxxData : Resource` 是模板不是成品，运行时绝不写它**——它是注册表里的共享只读单例，写回会污染同一轮回的后续批次与其他角色；**服务签名里传实例，不传 `Resource`**。→ `systems/architecture.md`
5. **「内容定义 + 情境 / 轮回内状态」恒是两个类型**：`AdventureEventData` ↔ `EventOption`（定稿不可变、落存档）、`EnemyData` ↔ `EnemyInstance`（同左，等级即物化产物）、`CardData` ↔ `CardInstance`（运行态可变）。→ `systems/architecture.md`「总则 6」
6. **静态展示文案留在 `XxxData` 上、类型是 `LocalizedText` 而非裸 `string`**，`Get()` 只读、绝不把解析结果写回条目（那会污染注册表共享单例）；`LocalizedText` 不落存档、不进上行负载。→ `systems/common-properties.md`
7. **校验点在合并之后**：overlay + 基线合并完再统一校验重复 `Id` 与悬空引用，启动期 `GD.PushError` 早失败；**`ContentEnabled == false` 的条目照常参与全量校验**。→ `systems/services/content-service.md`
8. **可调数值存导出字段 / 单例平衡资源**，绝不硬编码在系统逻辑里；**不散落 `ResourceLoader.Load`**，一切内容经 ContentRegistry——**平衡表也走同一条路**（直读 `res://content/balance/*.tres` 即当场失去 overlay 热更与合并后强校验）。唯一例外是消费点早于 `LoadAll()` 的管线旋钮，写死为代码常量。→ `systems/services/content-service.md`
9. **单例平衡资源用 `Content.Single<T>()` 取，调用方不碰 `Id`**；单例身份由标记接口 `ISingletonContent` 声明，`where T : ISingletonContent` 是编译闸（对 `CardData` 调 `Single<T>()` 编译不过），条数 `!= 1` 或 `ContentEnabled == false` 在加载期 `PushError` + 抛。写 `Id` 字面量去查单例即引回一个可拼错的字符串键。→ `systems/services/content-service.md`
10. **敌人与玩家共用 `CardData` 体系但不共用卡池**：`Pool` 是必填、无默认值，漏填即坏数据；**卡组规模两侧皆不设硬限**（代价由疲劳承接）。→ `systems/enemies/_index.md`
11. **敌人池归属的唯一权威是 `EnemyData.PoolScope`**（`LocationData` 不持敌人清单）；地域 / arc 专属条目是**叠加而非替代**——通用敌人恒可在任何地域出现。**篇章不住 `PoolScope`**：它是与 `EncounterScopes` 平级的顶层字段 `EnemyData.ChapterScope`，取池是叠在 `AllEnabled()` 之后的三层过滤；**空 = 不限**（与 `EncounterScopes` 空即 `PushError` 的不对称是有意的，别当漏写去「修正」）。→ `systems/enemies/_index.md`、`systems/enemies/common-properties.md`
12. **本作不存在多敌人场景**——敌人实例单数，嵌在 `EventOption.Encounter` 内，不要预留 `List<EnemyInstance>`。→ `systems/adventure-event/combat/_index.md`

## 三层覆盖来源与热更边界

`res://content/` 基线 < `user://overlay/` 热更 < **flags**（只覆盖 `ContentEnabled` 一个布尔），合并后统一校验 → ContentRegistry 按 `Id` 索引。**完整形状、校验闸与下载事务见 `systems/services/content-service.md`，此处只留边界纪律：**

- **热更范围 = 只改不增；剧本内容是唯一例外**，且该例外已是合并期硬校验、不再是约定。→ `systems/services/content-service.md`
- **flags 只能覆盖 `ContentEnabled`，不得携带任何数值 / 文案 / 新 `Id`**——它能秒关正因为被限制得足够窄；作用点唯一 = `AllEnabled()` 取池。→ `systems/services/content-service.md`
- **结构性查表类恒启用**（`LocationData` / `LocationMapData` / `HiddenStatBandData`）：`ContentEnabled == false` 即加载期 `PushError`，flags 对它们不生效——线上关掉若干地域会让邻接集合为空、轮回死锁。→ `systems/services/content-service.md`
- **不冻结轮回的 `contentVersion`**：overlay 更新对进行中的轮回立即生效，已放弃跨内容版本的 seed 可复现。→ `standards/rng-determinism.md`
- **增量下载 = 文件级事务 + manifest 签名**，原子写 manifest 即提交点，**永不存在半套 overlay**。→ `systems/services/content-service.md`
- **一切内容都在本地，没有云端内容通道**（含剧本文本）：运行时内容零网络请求，网络只在启动期做 manifest 比对与增量下载。→ `systems/services/plot-manager.md`
