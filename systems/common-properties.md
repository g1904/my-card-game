# common-properties（系统层共有属性）

> systems 顶层的**共有属性 / 约定**：所有系统文档共享的字段命名、稳定 Id 键、seeded RNG 派生、存档版本化、null 校验、日志约定等。深层子树（adventure-event、character-profile、player-profile）另有各自的 `common-properties.md`；本文件是它们之上的**顶层共有层**。


## 意图
> _系统层所有「类」共享的约定。保持更新。_

### 稳定 Id 键
- 每个内容条目都有一个**稳定、唯一的字符串 `Id`**。Id 是其他一切引用的键（存档文件、注册表查找、跨系统交互）。**绝不用场景路径、数组索引或显示名作为内容的键。** Source: `.claude/rules/data-resource-rules.md`。
- 显示字符串（名称、描述）与 `Id` **分离**，可改动 / 本地化而不破坏引用。

### 字段命名与类型一致性
- 类、方法、属性、信号、导出字段用 `PascalCase`；私有字段 `_camelCase`；与 Godot C# API 大小写一致。Source: `.claude/rules/csharp-godot-rules.md`。
- **贯穿整条链路的类型一致性。** 参数 / 返回类型在 UI/输入 → 系统/管理器 → 数据资源（`.tres`）→ 存档模型 全流程对齐；层与层之间不做隐式装箱 / 转换。Source: `.claude/rules/Context.md`。
- 领域术语的中文 ↔ 英文 / 代码标识符权威在 `terminology.md`（例：修行事件 / AdventureEvent、角色信息 / CharacterProfile）。

### 数据即资源
- 每种内容类型是一个 `[GlobalClass] partial class XxxData : Resource`，带 `[Export]` 字段；实例以 `.tres` 编写，由 `content-service` 的 **ContentRegistry** 在启动时按 `Id` 索引。玩法代码经注册表的**泛型仓储接口**（`Get` / `TryGet` / `AllEnabled` / `AllIncludingDisabled` / `Where`）查找，不散落 `ResourceLoader.Load`。Source: `.claude/rules/data-resource-rules.md`。
- **内容分三层：** `res://content/` 基线（随包发布、只读）+ `user://overlay/` 云端热更增量（按 `Id` 覆盖）→ 合并进 ContentRegistry；**校验点在合并之后**（重复 / 悬空 `Id` → `GD.PushError` 启动期早失败）。详见 `systems/services/content-service.md`。Source: `handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md`。
- **可调平衡数值不硬编码**，归 `systems/balance.md` 或导出字段（见 `data-resource-rules.md`）。

### 内容共有字段 `ContentEnabled`（已定案）
- 每种 `XxxData : Resource` 携带 **`ContentEnabled: bool`，默认 `true`**——线上放量开关，overlay 只改这个既有布尔字段，不触碰「不得新增 `Id`」纪律。
- **过滤只发生在产出侧：** 一切**抽取**（eventOptions、商店库存、奖励掷骰）走 `ContentRegistry` 的 **`AllEnabled()`**；**读取侧 `Get(id)` 不过滤**，故存档引用到被关闭的条目仍能正确解析。**任何从内容集合抽取的代码必须走 `AllEnabled()`**——与「不散落 `ResourceLoader.Load`」同级的纪律。
- **这条纪律由命名强制，不只靠条款：仓储上没有中性名 `All()`**——只有 `AllEnabled()`（抽取池）与 `AllIncludingDisabled()`（全量：启动期校验 / 图鉴统计 / 调试），过渡期保留一个 `[Obsolete(error: true)] All()` 编译闸。选级判据见 `systems/architecture.md`「纪律的可执行化」。Source: `handoffs/2026-08-09e-discipline-enforceability.md`。
- **合并后强校验对 disabled 条目照常全量执行**（`Id` 唯一性、交叉引用不悬空），走 `AllIncludingDisabled()`。完整论证见 `systems/services/content-service.md`。Source: `handoffs/2026-07-27-content-gating-offline-resilience-and-rng-persistence.md`。

### 展示字段的归属（已定案）
- 各「类」只携带编码（`Id` / 数值）。展示（充血）字段的归属**按生命周期切分三层**，而非为前端另建一套并行类：**静态展示文本**（显示名 / 描述 / 图标）留在 `XxxData : Resource` 上；**运行时 / 存档态**只带 `Id` + 可变状态，不复制展示文本；**组合展示**（数值代入、条件文案、随 capability flag 变化的可见性）由 UI 层轻量 **ViewModel** 按需组装，不落存档、不进云端负载。完整论证与待确认项见 `systems/architecture.md`。Source: `handoffs/2026-07-25b-event-cost-fields-capability-flags-and-service-hierarchy.md`。

### 内容共有字段 `Rarity: RarityTier`（已定案 · 08-10c）

- **凡「会被抽取或置换」的内容定义都带 `Rarity`**：`PowerData` · `ItemData` · `CardData`。`AdventureEventData` **不需要**（事件不进抽取池的稀有度维度，它的出现由权重与优先级控制）。
- **`RarityTier { Tier1, Tier2, Tier3, Tier4, Tier5 }`，五档，档号越高越稀有。**
- **落在内容定义上，不落在持有条目上**——与 `SourceCode` 恰好相反：稀有度是**内容本身的属性**（同一条法则无论从哪来都是同一档），来源是**这一次获取的属性**。
- **类型名是 `RarityTier`，不是裸 `Tier`（硬约定）。** `Tier { Narrow, Solid, Crushing }` 已被战后奖励的**优势档**占用（道念差归一化后的碾压程度）。**两者不得复用同一枚举，也不得互相换算**；准确口径是「稀有度权重表按 `RarityTier` 五档索引，由优势档 `Tier` 三档选表」。见 `systems/balance.md`。
- **三个消费点：** ① 战后奖励池的稀有度权重；② **置换候选池的过滤键**（同 `(Kind, Scope)` 且同 `Rarity` 才同池，见 `systems/player-profile/player-power/_index.md`）；③ **账号级授予池的加权键**（残卷 / 礼包共用一张「授予池稀有度权重表」，见 `systems/balance.md`）。Source: `handoffs/2026-08-12e-ability-grant-draw-pool.md`。
- **加载时校验：** 缺失 → `GD.PushError`（默认值会让漏填条目悄悄落进 `Tier1` 池并污染置换候选）。
- **它不是凭空引入的新概念**——既有设计（奖励池「稀有度权重」、可购道具的预期共有字段）一直在依赖它，本次只是定名并统一挂载面。
Source: `handoffs/2026-08-10c-ability-disable-replacement-and-player-statistics.md`。

### 授予来源共有字段 `SourceCode` + `Source` 枚举（已定案 · 08-12b）

- **凡「可被授予并持有」的条目都带 `SourceCode`**，记录它是被**哪条渠道**给到玩家的。覆盖四类：**法则 PlayerPower** · **古宝 PlayerItem**（账号级，落 `PlayerProfile`）· **神通 CharacterPower** · **法宝 CharacterItem**（轮回级，落 `CharacterProfile`）。
- **落在持有条目上，不落在 `PowerData` / `ItemData` 上。** 这是物化模型的直接推论：`XxxData : Resource` 是 ContentRegistry 里的**共享只读单例**，而同一条法则可由不同渠道获得——**来源是「这一次获取」的属性，不是内容定义的属性**。它与 `status` 同层，属持有条目的运行态 / 存档态字段。
- **写入时刻 = 授予时刻，此后不变。** 条目被移除后再次获得 = 一次新的获取，写新的 `SourceCode`。
- **`Source` 是单一的 C# 枚举，不按类拆成四个（已定案 · 08-12b）。** 四类共用**同一条授予通道**（`AbilityChangeElement` 的 `Op == Grant` 与 `ProfileManager.Grant*`），一个 `Source` 形参贯穿全链；每类各一枚举会把它逼成 `object` / `int` / 泛型，直接撞上本文件「贯穿整条链路的类型一致性」。同型判断已有先例：08-10c 把 `PowerScope` / `ItemScope` 合并为单一 `AbilityScope`。**分域差异由校验表承载，不由类型系统承载**（见下）。
- **成员带 code 与 value：** **code** = 显式的稳定整数，是存档里实际序列化的东西（**重命名成员不破坏存档；已删成员的 code 永不复用**）；**value** = 展示文案，与 code 分离、可本地化、**不落存档**（走翻译键；但 `SourceCode` 当前不对玩家可见，翻译键暂不铺开）。与既定纪律同构——capability flag 的载体是 `enum CapabilityFlag` 而非字符串 key，显示字符串一律与键分离（见上方「稳定 Id 键」）。**⚠ 上行负载的序列化形态未收口**，见下方「待决问题」。
- **成员清单 = 七值 + 兜底（已定案 · 08-12b，推翻 08-10b 的封闭三值）：**

  | 成员 | code | 语义 | 计入残卷的 `x` |
  |---|---|---|---|
  | `Unknown` | 0 | **防御性成员，不是一条途径**：老档缺字段 / 无法识别取值的归入处 | 否 |
  | `FinaleWin` | 1 | 渡劫成功时由道统残卷掷中并发放 | **是（唯一计入者）** |
  | `PremiumBundle` | 2 | 付费礼包给予 | 否 |
  | `AchievementReward` | 3 | 成就奖励给予 | 否 |
  | `EventOutcome` | 4 | 非战斗类 AdventureEvent 的 outcome 授予 | 否 |
  | `CombatReward` | 5 | 战斗类遭遇的 `Spoils` 授予（Combat / Practice；Finale 的残卷那一路走 `FinaleWin`） | 否 |
  | `ExchangePurchase` | 6 | Exchange（交易）事件中购买所得 | 否 |
  | `InitialGrant` | 7 | 开局初始持有（角色创建时随 `CharacterProfile` 初始化的起手配置） | 否 |

  **推翻的是「清单是封闭的」这条**：08-10b 的三值全是账号级法则的授予途径，而神通 / 古宝 / 法宝各有真实存在的来路，字段应如实记录它们（否则轮回级两类只能一律落 `Unknown`）。**`FinaleWin = 1` / `PremiumBundle = 2` / `AchievementReward = 3` 的 code 已冻结**——后端复算 `x` 依赖它们。
- **⚠ 仍不为「置换所得」设成员（禁令 · 08-10b 保留并强化）。** 扩清单后这条从「顺带没写」变成一条必须主动守住的禁令：新设一个 `Replacement` 成员会立刻打破 `x` 的单调不减，重开「用置换刷回高掉率」的通道。
- **合法取值域按 `(Kind, Scope)` 分域（已定案 · 08-12b）。** `(Kind, Scope)` 是全库既有的分类键（置换同池判据即它全同），四类 = 该二元组的四个取值：

  | 成员 | 法则 `(Power, Player)` | 古宝 `(Item, Player)` | 神通 `(Power, Character)` | 法宝 `(Item, Character)` |
  |---|:--:|:--:|:--:|:--:|
  | `FinaleWin` | ✅ | ❌ | ❌ | ❌ |
  | `PremiumBundle` | ✅ | ✅ | ❌ | ❌ |
  | `AchievementReward` | ✅ | ✅ | ❌ | ❌ |
  | `EventOutcome` | ❌ ※ | ❌ ※ | ✅ | ✅ |
  | `CombatReward` | ❌ | ❌ | ✅ | ✅ |
  | `ExchangePurchase` | ❌ ※ | ✅ | ✅ | ✅ |
  | `InitialGrant` | ❌ | ❌ | ✅ | ✅ |
  | `Unknown` | ✅（仅读档兜底） | ✅（同左） | ✅（同左） | ✅（同左） |

  - **账号级不接 `CombatReward` / `InitialGrant`：** 账号级授予唯一的战斗入口就是残卷，而它已有专用成员 `FinaleWin`；「开局初始持有」是角色创建时的行为，账号级两类不随角色创建发放。
  - **轮回级不接 `PremiumBundle` / `AchievementReward`：** 二者按定义是账号级发放——发一件随轮回清理的东西作为付费 / 成就回报，与「付费内容不会被游戏销毁」（08-06b 推论 ①）正面冲突。
  - **`Unknown` 只作读档兜底，不是授予时的合法入参**（授予侧传 `Unknown` = 调用方漏填，与「不设默认值」同一条纪律）。
  - **※ 三格 ❌ 是「暂不开放」，不是「语义上不可能」。** 它们取决于尚未设计的「法则的第三条获取渠道」（见 `systems/player-profile/player-power/_index.md` 的待决项）；在那条答定前一律 ❌，**日后开放 = 在校验表里翻一格，无任何结构改动**。
  - **合法子集表落为一张静态查表**（`(Kind, Scope) → 允许的 Source 集合`），与置换同池判据共用 `(Kind, Scope)` 键；它是**代码常量，不是内容资源**——它约束的是代码组装而非内容编写，**不进 `.tres`、不走 overlay**。
- **授予通道必须带上来源：** 凡授予 power / item 的 element（08-10c 起即 `AbilityChangeElement`，`Op == Grant`）**必须携带 `Source`，不设默认值**——省略即产生来源未知的条目，而 `x` 直接读这个字段。`ProfileManager` 的授予签名相应带上来源（`GrantPower(string powerId, Source source)`，见 `systems/services/profile-service.md`）。
- **校验：入口严、读档宽（已定案 · 08-12b）。** `Op == Grant` 且 `(Kind, Scope, Source)` 不在合法表内、或 `Source == Unknown` → **必需缺失**，`GD.PushError` + **整批拒绝**（与 `PairKey` 配对不成立同档）。读档遇不合法的**既有条目** → **可选缺失**，`GD.PushWarning` + **保留原值**，不阻塞、不改写。**这条非对称是唯一安全的方向**：读档回落 `Unknown` 会把一条 `FinaleWin` 法则改判为非 `FinaleWin`，压低 `x` 并让档位回跳，违背单调不减。缺失字段 / 无法识别取值仍归入 `Unknown`（老档迁移即补 `Unknown`，当前无线上账号，迁移成本为零）。
- **不 bump 存档 schema。** 字段形状不变（仍是一个整数 code），仅值域扩大；老档中的 `Unknown` 原样保留，无迁移动作。
- **置换不改变来源（已定案 · 08-10b）：置换所得条目继承被换出条目的 `SourceCode`。** 目的是**关死「用置换刷回高掉率」的通道**——若置换产物记为一条新来源，换掉一条 `FinaleWin` 法则即使 `x` 下降、档位回跳。**推论：置换对 `x` 完全中性，08-09b 的「`x` 单调不减 ⇒ 档位只降不回跳」原样保住**；代价是来源字段记的是「这条能力最初从哪条途径进入账号」而非「上一次易手的方式」，这是有意的取舍。
- **消费点分两层（已定案 · 08-12b，改写 08-10b 的「唯一消费点」表述）：**
  - **规则消费点仍唯一** = 道统残卷的分档自变量 `x`（= 已拥有且 `SourceCode == Source.FinaleWin` 的法则数，见 `systems/player-profile/player-power/_index.md`），且只看 `FinaleWin`。它因此仍是**纯规则字段**（严格同步口径 · 后端可复算，见 `systems/player-profile/_index.md` 的两层通则），`Source` 也因此是一条**会被后端读到**的字段——取值的稳定性同时是一条客户端 ↔ 后端契约。**新增四个成员没有一个能出现在法则上并被计入 `x`**，扩清单对残卷零影响。
  - **非规则用途两处**（现成落点，不新增机制）：① `ProfileManager.TryApply` 的可追溯性日志（来源正是那行最该带的信息）；② 客服 / 数据侧的账号溯源（付费给予 vs 玩法所得的区分是退款与申诉的第一手依据）。
  - **承认的代价：** 轮回级两类的 `SourceCode` **仍没有任何规则消费点**——在那两类上它依然是「只写不读」的字段，只是取值不再恒为兜底值。这条张力真实存在，只是从「字段无意义」降级为「字段有信息但暂无规则消费者」。
- **⚠ 与 `SourceInstanceId` 是两个不同字段。** `SourceCode` = 授予**渠道**，落**持有条目**；`SourceInstanceId` = 施加禁用的那个**来源事件实例**，落 `disabledAbility` 条目、供「长按查看来源事件」反查 `pastEvent`。名字相邻，**不得合并**。
Source: `handoffs/2026-08-12b-grant-source-per-kind-scope.md`（推翻 / 取代 `handoffs/2026-08-10b-grant-source-and-fragment-source-scoping.md` 的封闭三值）。

### 内容共有字段 `ExclusiveSource: Source?`（准入标记 · 已定案 · 08-12e）

- **凡可被抽取授予的内容定义都带 `ExclusiveSource: Source?`，默认 `null` = 通用。** 覆盖 `PowerData` / `ItemData`。它声明**这条内容只能由哪条渠道给出**：`!= null` 的条目**不进任何抽取池**（残卷 / 礼包 / 置换的换入侧一律排除，见 `systems/player-profile/player-power/_index.md` 的取池链）。
- **⚠ 它与 `SourceCode` 名字相近、方向相反，必须并排读：**

  | | `ExclusiveSource` | `SourceCode` |
  |---|---|---|
  | 落点 | **内容定义**（`PowerData` / `ItemData`） | **持有条目** |
  | 语义 | 这条内容**只能由哪条渠道给出**（准入） | 这一次获取**实际来自哪条渠道**（记账） |
  | 消费点 | 取池过滤（产出侧） | 残卷的 `x` |
  | 不填的含义 | `null` = 通用，任何渠道都能给 | 无「不填」——授予通道强制携带 |

- **首个也是当前唯一的用例 = 成就限定条目**（`ExclusiveSource == Source.AchievementReward`）。成就奖励给的是**指定条目**而非抽取结果，把这些条目挡在全部抽取池之外，才使「成就奖励恒不落空」成为机械保证而非口头约定；完整论证与三条校验见 `systems/player-profile/achievement/_index.md`。
- **选 `Source?` 而非新开一个布尔（如 `AchievementExclusive`）**：同一诉求日后必然重演（活动限定、剧情限定条目），复用既有枚举让「限定给谁」成为一次数据填写，而非每次新增一个布尔字段——与「新增内容 = 新增 `.tres`，不改 switch」同一条纪律。取值域随 `Source` 清单扩张而自然扩大。
- **不落存档**（它是内容定义的属性，不是持有条目的属性），故不 bump schema。
Source: `handoffs/2026-08-12e-ability-grant-draw-pool.md`。

### Seeded RNG 派生（确定性）
- 每个轮回存储一个 **seed**；所有玩法随机性（地图 / location 生成、抽卡、商店库存、奖励掷骰、敌人行为）从该 seed 派生，最好通过具名子流（sub-stream）隔离，避免系统间 desync。**不用未加种子的 `GD.Randi()` / `Random` 决定玩法结果。**
- 在存档中持久化足够的 RNG 状态，使恢复的轮回能确定性继续。**持久化形态已定案：**
  - **子流派生 `streamSeed = Hash64(CycleSeed, streamName)`**——子流 seed 可随时从 `CycleSeed` 重算，存档中存它**只为诊断与自校验**。
  - **`State`（u64）是恢复用的权威字段**：重建子流后回填 `RandomNumberGenerator.State`，**O(1)**，不必重放。
  - **`DrawCount`（int）是诊断与迁移保险**：`State` 是引擎实现细节，Godot 升级可能改变其语义；届时用 **`seed + drawCount` fast-forward 重放**恢复（一次轮回抽取数千次，重放成本可忽略）。冗余成本每流 4 字节。
  - **子流清单是 `SeedManager` 内的常量**（map / combat / shop / reward）。读档遇存档中没有的**新子流** → `GD.PushWarning` + 按 `Hash64(CycleSeed, name)` 全新初始化；遇清单里已不存在的**旧子流** → 警告并丢弃。**增删子流不 bump schema 版本。**
  - **防 re-roll 的派生层已整层删除（已定案 · 08-06）。** 原方案是战斗内随机不直接用 `combat` 子流、而是每场再派生 `Hash64(combatStreamSeed, eventId, attemptIndex)`。**两个动机都已消解：** ① 「退出重进重掷」已由决策点存档 + RNG `State` 持久化从根上关闭；② 「篇章重试是否换一套战斗随机」答定为**换**，而换法是**给这一次重试一套新的随机流**，不是在既有流上再派生一层。**`attemptIndex` 因此没有任何剩余职责，字段与派生层一并去掉**；篇章重试次数改由 `CharacterProfile.chapterRetry` 承载（它是重试上限的计数器，与 RNG 无关，见 `systems/services/life-cycle-service.md`）。Source: `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md` + `handoffs/2026-08-06-ch1-band-widening-cross-realm-crush-and-chapter-retry.md`。
  - 存档 schema 见 `systems/character-profile/_index.md`；派生方是 `life-cycle-service.SeedManager`。Source: `handoffs/2026-07-27-content-gating-offline-resilience-and-rng-persistence.md`。
- **账号级随机与轮回随机是两条不相交的线（已定案 · 08-09b）。** 判据：**结果写 `PlayerProfile` 的随机，绝不可从 `CycleSeed` 派生**——四条子流全由 `Hash64(CycleSeed, streamName)` 得出，而**篇章重试会生成全新的 `CycleSeed`**，把账号级掉落挂上去等于让玩家靠重试换一次结果。
  - **形态 = 具名域 + 单调序号（08-12e 修订，由两参数扩为三参数）：**

    ```csharp
    enum AccountStream { PowerFragment, PremiumBundle }   // 成就奖励无随机，不占域

    // 派生一次、连续抽多条；序列由 (stream, ordinal) 完全确定 ⇒ 幂等
    RandomNumberGenerator AccountRng.For(AccountStream stream, int ordinal);
    // 内部：seed = Hash64(AccountSeed, (ulong)stream, (ulong)ordinal)
    ```

    `AccountSeed` 是后端下发、落 `AccountInfo` 的 `ulong`（见 `systems/player-profile/account-info.md`）。**它不进 `SeedManager`、不进子流清单**，故不触及「增删子流不 bump schema 版本」那条纪律。
  - **为什么必须有具名域（08-12e）：** 原形态 `Hash64(AccountSeed, ordinal)` 的唯一用例是残卷。礼包一旦也走账号级掷骰，它必然有自己的序号（`1, 2, …`），于是**同一 `AccountSeed` + 同一整数 ⇒ 同一 `Hash64` 输出**——礼包的第 1 次授予与残卷的第 1 次胜利掷骰共享同一随机数。两者消费方式不同、玩家不可感知，但这是一条没有理由留着的相关性，且第三条渠道加入时会越来越难排查。**否决「给各渠道分配不相交的序号区间」**：效果相同但更脆（区间耗尽 / 新渠道加入需重新分配，且区间约定不可机械校验）。**⚠ `AccountSeed` 的复算契约因此多一个参数，后端侧需同步。**
  - **单调序号同时是幂等键**——同一 `(stream, ordinal)` 重复结算得同一结果，退出重进 / push 重放都不改变结果，与决策点存档的防重掷同一条纪律。**一次授予要抽多条时（礼包的 1 法则 + 2 古宝）共用同一个 rng 实例连续抽**，故整次授予由 `(stream, ordinal)` 完全确定。
  - **对轮回可复现性零影响**（不派生自 `CycleSeed`、不消耗任何子流 `State`）。两个用例：**道统残卷**（`PowerFragment` 域，序号 = `FinaleWinOrdinal`，见 `systems/player-profile/player-power/_index.md`）与 **premium bundle**（`PremiumBundle` 域，序号 = `BundleGrantOrdinal`，落点见 `systems/monetization.md` 的待决项）。**「持有的账号级内容不同 ⇒ 同一 seed 的轮回体验不同」不构成公平性问题**：账号状态本就是轮回的输入（deck、法则、古宝皆然），既定的确定性承诺只覆盖「同一存档恢复后能正确继续」。
  Source: `handoffs/2026-08-09b-player-power-fragment-finale-bound-drop-chance.md` + `handoffs/2026-08-12e-ability-grant-draw-pool.md`。
- **确定性的边界：同一 `contentVersion` 内（已定案）。** 内容热更**以 overlay 更新为准**——轮回进行中 overlay 更新时新数值立即生效，**不冻结该轮回的 `contentVersion`**。因此本项目**不承诺「同一 seed 跨内容版本复现同一轮回」**：seeded RNG 的目的是消除未加种子的随机、保证存档恢复后能正确继续，而非提供跨版本的绝对可复现性。数值可随时线上修正的价值高于跨版本复现。Source: `handoffs/2026-07-26-event-priority-skip-semantics-and-hotfix-scope.md`、`systems/services/content-service.md`。

### 存档版本化与原子写入（强制在线 · 云端权威）
- **强制在线 · 云端权威**：进度实时同步云端，本地↔云端冲突以云端为准；本地 `user://` 仅作缓存 / 离线临时态。Source: `decisions/ADR-0003-online-cloud-authority.md`。
- **原子写入**：先序列化到临时文件，再重命名覆盖；对本地缓存与上行云端负载都原子、带版本。
- **给存档加 schema 版本字段 + 迁移路径**；读取时校验版本 / 内容 id / 字段，未知或不匹配以清晰错误 / 迁移处理，绝不静默 null。Source: `.claude/rules/state-save-rules.md`。

### Null / 结果校验（强制）
- 每次节点查找、资源加载、注册表 / 字典查找、存档读取之后，使用前**显式校验**：必需但缺失 → `GD.PushError` + 定位上下文（id / 路径）并退出；可选但缺失 → `GD.PushWarning` + 安全默认值。绝不把未检查的 null 向下游传递。Source: `.claude/rules/null-check-rules.md`。

### 日志约定
- 用 `GD.Print` / `GD.PushWarning` / `GD.PushError`，带 `[System-Method]` 标签（例：`[Combat-PlayCard]`）；在关键状态转换（轮回开始 / 结束、遭遇战、卡牌结算、存档 / 读档）做有意义日志。Source: `.claude/rules/Context.md`。

### 服务协作约定（层级 service ⊃ manager ⊃ module ⊃ processor ⊃ handler）
- **service = 进程内模块单例，不是微服务。** 全部服务在同一 Godot 项目 / 同一二进制 / 同一进程内，以 **autoload** 形式存在，彼此为直接 C# 方法调用；manager 是服务持有的普通 C# 对象（非 `Node`）。唯一真实的进程边界是客户端 ↔ 后端。工程落地形态见根级 `system-overview.md`。
- **service = 边界单元**（判据三选一：① 自有状态机 / 长流程；② 事务性跨字段一致写；③ 外部 I/O 边界）；**manager = 服务内部的职能组件**，共享宿主服务的事务边界与生命周期，**不被跨服务直接调用**。服务清单与拆分轴见 `systems/services/_index.md`。Source: `handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md`。
- **拆分轴 = 生命周期层 + 行为边界，不是数据类型。** 不按 power / item / card / resource 各开服务（撕碎事务、横切生命周期层、退化为贫血 CRUD）；不为九类 AdventureEvent 各开服务（只有 Combat 有状态机，其余差异在数据而非代码）。
- **两条唯一入口：** 内容读取经 `content-service.ContentRegistry`（不散落 `ResourceLoader.Load`）；档案写入经 `profile-service.ProfileManager`（全量校验 → 全有或全无 → 单点提交，modifier pipeline 在此生效）。
- **跨服务调用纪律（已定案的准确措辞）：服务之间不读写对方字段、不伸手进对方 manager；跨服务的方法调用允许**——经对方的服务门面 `Xxx.Instance.Method(...)`，不得触及 `private` manager 字段。**编排顶点 game-progression** 负责「谁在什么时机调谁」的屏幕流程串联，但**不是**一切跨服务调用的必经中转；既成事实经 **EventBus** 广播。Source: `handoffs/2026-07-27b-service-api-contracts.md`。

### API 契约总则（已定案 · 摘要）

> 完整八条总则、共享核心类型与 EventBus 负载 schema 的**权威在 `systems/architecture.md`「API 契约总则」**。此处只列所有系统文档书写 API 时必须遵守的约束。Source: `handoffs/2026-07-27b-service-api-contracts.md`。

- **三种方法形态，按「它跨什么边界」决定，不允许混用：** **A · 同步直返**（纯内存查询与纯本地事务）／**B · `Task<OpResult<T>> + CancellationToken`**（跨客户端 ↔ 后端边界）／**C · `Task<T>` 由信号推进**（跨多帧的玩法长流程）。**形态 B / C 一律带 `Async` 后缀并返回 `Task`，形态 A 一律不带**——看签名即知它是否跨边界。
- **三种失败语义，与 null-check 规则一一对应：** 必需缺失 = 程序缺陷 → `GD.PushError` + `throw`；可选缺失 = 调用方可降级 → `bool TryXxx(..., out T)` + `GD.PushWarning`；**业务失败 = 预期内的拒绝 → 返回 `OpResult` / `OpResult<T>` / `ApplyResult`，绝不抛**。结果类型一律 `readonly record struct`（零堆分配）。
- **服务门面骨架：** manager 类型 `internal sealed`、服务只暴露方法不暴露 manager 引用、**服务不返回内部可变集合**（一律 `IReadOnlyList<T>` / `IReadOnlyDictionary<,>`）。
- **启动契约：** `_Ready` 只装配，I/O 归 `IBootstrappable.InitializeAsync(ct)`，由 Bootstrap 屏幕按固定顺序驱动。
- **EventBus 用 C# 泛型 `event` + `readonly record struct` 负载**（不用 Godot `[Signal]`——负载须继承 `GodotObject`，每次广播分配 + `Variant` 装箱，撞上本文件「不做隐式装箱 / 转换」与热路径不分配）。**负载只带 `Id` + 值类型，绝不带 `CharacterProfile` / `Resource` / 定稿实例引用**；订阅方 `_Ready` 订阅、`_ExitTree` 退订。
- **`CostSpec` / `RewardSpec` 合并为单一 `ProfileChangeSpec`**（`ChangeElement.BaseValue` 带符号：负 = 消耗，正 = 产出）——「全有或全无、单点提交」本就要求成本与产出在同一事务内。
- **capability flag 的载体是 C# `enum CapabilityFlag`**，不是字符串 key：flag 的消费点必然是一段 UI 代码，字符串只是把「拼错了」从编译期推迟到运行时。可加的是 `.tres` 里**谁授予哪个已定义的 flag**。
- **API 书写规范：** 各服务文档的「API 面（契约）」小节统一为四列表 **方法 | 形态(A/B/C) | 完整签名 | 失败语义**；形状依赖未答问题的写 `⟨待定：链接到待决项⟩`，不留空白也不臆造。

### 物化模型：内容定义 ↔ 运行时实例（已定案）

- **凡「内容定义 + 情境 / 轮回内状态」的组合都是两个类型**，服务签名里**传实例，不传 `Resource`**：
  - `AdventureEventData` ↔ **`EventOption`** —— 由 future-event-service **物化（materialize）**产出，**产出即定稿（immutable）**，落存档；
  - `CardData` ↔ **`CardInstance`** —— 运行态**可变**（手牌中的临时增益）。
- **`XxxData : Resource` 是 ContentRegistry 里的共享只读单例，任何服务都不得在运行时写它**——写回会污染注册表，被同一轮回的后续批次与其他角色看到。
- 这与上方「展示字段的归属」三层切分同构：它把**第二层（运行时 / 存档态）的类型形态**明确了。物化模型的完整论证见 `systems/architecture.md`「总则 6」。Source: `handoffs/2026-07-27b-service-api-contracts.md`。

### 与 `.claude` 的主从关系（已定案）

- **`.claude` 是工程层，只承载两类东西：** ① 工程相关的配置与规则（harness 配置、C#/Godot 互操作与场景 / 数据 / 存档 / UI / null 校验纪律）；② 可复用的技能。**一切设计相关的知识与细节归本库**，在 `.claude` 内只被**引用与轻描述**（指路 + 一句话承重纪律）。
- **冲突裁决：** 设计性内容（机制、数值、字段、契约、流程）冲突 → **以本库为准**，`.claude` 跟着改；工程性约束（命名、生命周期、热路径、工具 / PATH、目录纪律）冲突 → **以 `.claude/rules/*` 为准**（本库对此无权威）。判据即「这句话的权威在哪一侧」：讲**游戏是什么** → 本库；讲**代码怎么写** → `.claude`。
- 因此本文件各条目中的 `Source: .claude/rules/*` 指向的是**工程纪律的权威**；凡属设计结论者，权威在本库、规则文件只留摘要。完整论证见 `decisions/ADR-0005-knowledge-thin-reference-layer.md`。Source: `handoffs/2026-07-30-claude-engineering-scope-enemy-manager-and-requirement-breakdown.md`。

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- **强制在线 · 云端权威** → `decisions/ADR-0003-online-cloud-authority.md`（Accepted）。
- **`.claude` 是工程层、对设计只做薄引用；设计内容以本库为准 / 工程约束以 `.claude/rules` 为准** → `decisions/ADR-0005-knowledge-thin-reference-layer.md`（Accepted，07-30 把范围从 `knowledge/` 扩到整个 `.claude`）。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **⚠ `Source` 在上行负载里的序列化形态未收口（08-12b 新增 · 承重 · 收口归后端库）。** 本文件上方写「code 是**存档**里实际序列化的东西」，而 08-10b 的原措辞是「存档 / **上行负载**」；后者与 `backend-design-documents/contracts/envelope.md`（08-11 成文，晚于 08-10b）的「**枚举值一律字符串，取值与客户端 C# 枚举名逐字相同**」正面冲突，两条不能同时成立。**倾向的收口：契约侧走字符串名 · 存档侧走整数 code · 客户端在序列化边界做一次映射**（通则不开例外），若如此则须补一条「**成员名与 code 双双冻结、永不复用**」的纪律。**不阻塞扩清单落地**——它只决定线上表示形态。裁决在 `backend-design-documents/handoffs/2026-08-12-grant-source-code-contract.md`。Source: `handoffs/2026-08-12b-grant-source-per-kind-scope.md`。
- **`EventOutcome` 与 `CombatReward` 是否终将合并（08-12b 新增）。** 二者分立的前提是「战斗类遭遇的 `Spoils`」与「非战斗事件 outcome」确为两条组装路径（当前文档支持这一判断）。若最终合流为同一条链路，两个成员应合并为一个——**合并时 `CombatReward = 5` 的 code 作废并永不复用**，不得改判为别的语义。→ `systems/services/combat-service.md`、`systems/services/future-event-service.md`。Source: 同上。
- **共有属性提炼粒度：** 本文件为顶层共有层；哪些字段应下沉到子树各自的 `common-properties.md`、哪些应留在顶层，边界待随子树填充而细化。Source: `handoffs/2026-07-24-docs-restructure-class-model.md`。
- **`.claude/rules/*` 中夹带的设计性表述如何处理：** 主从关系已定（见「与 `.claude` 的主从关系」），但现存规则文件里确实嵌着设计结论（例：`state-save-rules.md` 的确定性边界、`data-resource-rules.md` 的 `AllEnabled()` 语义）。这些是「一句话承重纪律 + 回链」的合法形态，还是应进一步瘦身？边界判据待一次核对。Source: `handoffs/2026-07-30-claude-engineering-scope-enemy-manager-and-requirement-breakdown.md`。

## 对应
提炼至：`.claude/knowledge/standards/`（ADR-0005：设计投影的三份 `signal-eventbus` / `rng-determinism` / `save-format` 为**薄引用**，回链本库；`csharp-conventions` / `godot-scene-conventions` / `mobile-portrait-ui` 讲 C#/Godot 引擎实践，在本库无权威，**保留实质**）。
