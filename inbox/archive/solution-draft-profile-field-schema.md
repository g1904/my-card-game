---
type: solution-draft
date: 2026-08-17
question: `CharacterProfile` 与 `PlayerProfile` 的完整字段 schema 未定（承重）——卡住 sync-service 的上行负载字段面、主菜单五入口的数据源与整个元进程层。
source: open-questions.md 的 derive 就绪度表（`systems/character-profile/_index.md` · `systems/player-profile/_index.md` 两行）；open-questions/06-meta-progression.md 邻域
targets: systems/character-profile/_index.md · systems/player-profile/_index.md · systems/architecture.md（共享核心类型：`Realm` / `StatusFields` 增行）· systems/services/profile-service.md（`StatusFields` 逐行）· systems/services/sync-service.md（schema 版本一节）· systems/player-profile/game-setting.md
counterpart: backend-design-documents/inbox/solution-draft-profile-field-schema.md   # 跨边界承接（由 2026-08-17 批量评审的裁决 ④ 触发）
status: distilled
reviewed: 2026-08-17 —— 6 项裁决（④ 为逆推荐：集合字段名改单数、改后端契约；③ 与 ⑥ 标 [采纳推荐 — 待复核]）；合并 interview 另裁定：单数通则边界 = 两层 Profile 及其子对象的存档字段名、条目键名同批收口为 powerId / itemId、rng 片段一并 camelCase、currentMana 移位连带修正 combat-service 措辞、角色集合字段取 characterProfile、后端 counterpart 同批落笔
distilled-to: handoffs/2026-08-17h-profile-field-schema.md
---

# 方案草稿 — 两层 Profile 的完整字段 schema

## 问题

`CharacterProfile` 与 `PlayerProfile` 的字段在本库各处已被**大量逐条定过**（`lifeTotal` / `mana` / `jade` / `disabledAbility` / 三个 band / 两个 location 字段 / `rng` / `chapterRetry` / `pastEvent` / `activeCombat` / `plotKeyPoint` / `PlayerStatistics` / `PlayerPowerFragment` / `PlayerEntitlement` / `AccountInfo` 五字段……），但**从来没有一份把它们汇成一处的完整表**。后果是三件具体的事悬着：

1. **sync-service 的上行负载字段面无法定稿** —— diff 的顶层键集合就是 Profile 的字段集合，而后端契约 `backend-design-documents/contracts/profile-sync.md` §5 已按 JSON path **冻结**了一批透明路径；客户端字段名与那些 path 必须对得上，否则复算静默退化。
2. **`ux/screen-flow.md` 主菜单五个入口**（PlayerProfile / PlayerPower / Achievement / Settings / Store）各自「对应 PlayerProfile 字段」一列里有几格还没有真实字段可指。
3. **元进程层无从 derive** —— 就绪度表把这两行判为 `blocked`。

**本问题的性质是「收拢」而不是「发明」。** 本草稿的主体是一次**全量采集 + 按层归位 + 逐字段回链**；只对确实空白的格给提案，并逐条标注依据类型。

## 约束（来自既有设计）

- **两层是一个聚合，同步单位是整个 `PlayerProfile`；`CharacterProfile` 粒度只是传输优化，不是同步单元。** 故不做 per-`CharacterProfile` 版本号。→ `systems/services/sync-service.md`「`revision` 语义与幂等键」
- **唯一写入面是 `profile-service.ProfileManager.TryApply(spec)`；一切字段不提供 setter。** 五条 spec 列表（`Elements` / `AbilityElements` / `Stats` / `StatusChanges` / `DeckElements`）决定了一个字段「能被怎么改」，因此**每个字段必须能对上其中一列**，对不上即缺写入通道。→ `systems/services/profile-service.md`
- **运行时 / 存档态只带 `Id` + 可变状态**，不复制展示文本；`LocalizedText` 不落存档。→ `systems/common-properties.md`
- **透明路径的 JSON path 是契约的一部分**，移动或重命名 = 破坏性契约变更。逐条清单**权威在** `backend-design-documents/contracts/profile-sync.md` §5，本库不复制。
- **「重算不出来**且有消费方**的存，重算得出来的不存」** —— 全库既有判据。→ `systems/character-profile/_index.md`（`plotKeyPoint` / band 两处应用）
- **固定的游戏结构用具名字段，不用字典 / 索引数组**（`chapterRetry` 三个篇章、三个 band 的既定先例）。
- **命名硬约定（可机械检查）：** 后缀 `Ordinal` ⇒ 规则字段层（一个**位置**，参与判定 / 幂等键）；前缀 `Total` / 后缀 `Count` ⇒ 统计计数层（一个**数量**，纯读数）。→ `systems/player-profile/_index.md`
- **两层字段分层通则：** 规则字段层（被判定 / 闸门 / 幂等键读取，严格同步 · 后端可复算）vs 统计计数层（只被 UI 读，宽松口径）。依赖方向单向。同上。
- **当前无线上存档 ⇒ 一切 schema 变更为空迁移**，但 `MigrationManager` 的逐版骨架就此立起。

---

## 建议方案

### 1. 表的形态：一张两层总表 + 逐字段回链，权威仍在各自专题文档

`[既有推演]`

本草稿若被采纳，落笔形态建议是：在 `systems/character-profile/_index.md` 与 `systems/player-profile/_index.md` 各补**一张完整字段表**，每行只写 **字段名 / 类型 / 归属层 / 写入通道（spec 哪一列）/ 权威回链**，**绝不复述该字段的语义、取值域与校验**——那些留在已有的专题文档里。

- 依据：`systems/common-properties.md` 判据卡的硬边界——「同一个字段名在两份及以上文档中同时出现枚举成员表 / 数值 code / 完整校验语义 ⇒ 违规（第二权威）」。一张**只有形态列、没有语义列**的索引表不触这条线，而它正是当前缺的那样东西。
- 代价明写：这张表本身会随字段增长，需要维护；但它是「索引 + 回链」形态，与 `_index.md` 的既有职责一致。

### 2. `CharacterProfile` 完整字段表

层 / 通道列的取值：**写入通道** = 该字段经 `ProfileChangeSpec` 的哪一列写入（`—` = 不经 spec，由 life-cycle-service 在轮回创建 / 篇章边界直接赋值）。

| # | 字段 | 类型 | 写入通道 | 状态 | 权威 |
|---|---|---|---|---|---|
| 1 | `id` | `string` | — | **本草稿提案** | 见 §3.1 |
| 2 | `characterDataId` | `string` | — | **本草稿提案** | 见 §3.2 |
| 3 | `status` | `CycleStatus` | — | 已定 | `_index.md` · ADR-0004 · `architecture.md` |
| 4 | `defeatReason` | `DefeatReason?` | — | **本草稿提案** | 见 §3.3 |
| 5 | `chapter` | `int`（1–3） | — | 已定 | ADR-0004 · `game-progression.md` |
| 6 | `realm` | `Realm` | — | 半定（枚举未登记） | 见 §3.4 |
| 7 | `level` | `int`（境界内层号） | — | 已定（全局序为派生） | `game-progression.md` |
| 8 | `Status` | `CharacterStatus`（具名子类） | 见下表 | 已定 | `_index.md` |
| 9 | `jade` | `int` | `Elements`（`CostKey.Jade`） | 已定 | `currency.md` |
| 10 | `technique` | `IReadOnlyList<TechniqueEntry>` | `DeckElements` | 半定（条目名未定） | 见 §3.5 |
| 11 | `looseCard` | `IReadOnlyList<string>` | `DeckElements` | 半定（**入组 Op 缺口 · 待 S4**） | 见 §3.5 |
| 12 | `magicPack` | `IReadOnlyList<CharacterItem>` | `AbilityElements` | 半定（条目 schema） | 见 §3.6 |
| 13 | `characterPower` | `IReadOnlyList<CharacterPower>` | `AbilityElements` | **本草稿提案**（字段名未定） | 见 §3.6 |
| 14 | `disabledAbility` | `IReadOnlyList<DisabledAbilityEntry>` | `AbilityElements`（`Disable`） | **已完整定案** | `_index.md` |
| 15 | `pastEvent` | `IReadOnlyList<PastEventEntry>` | — （life-cycle 追加） | **已完整定案** | `adventure-event/common-properties.md` |
| 16 | `plotKeyPoint` | `IReadOnlyList<PlotKeyPoint>` | — （并入 `eventEnd`） | 已定 · **集合型载体形状待 S4** | `_index.md` · `plot-manager.md` |
| 17 | `activeCombat` | `ActiveCombat?` | — （combat-service） | 已定为一格 · schema 归 combat-service | `combat-service.md` |
| 18 | `currentEventBatch` | ⟨**形状待 S3**⟩ | — （future-event） | **缺口** | 见 §3.7 |
| 19 | `chapterRetry` | `ChapterRetry`（具名子类 · 三字段） | — （`RetryChapter`） | 已定形态 · **字段名有命名冲突** | 见 §3.8 |
| 20 | `rng` | `RngState`（具名子类） | — （SeedManager） | **已完整定案** | `_index.md` · `common-properties.md` |
| 21 | `startContentVersion` | ⟨`string` 或 `int` · **见张力**⟩ | — | 已定为字段 · **类型不一致** | 见 §3.9 |
| 22 | `lastContentVersion` | 同上 | — | 同上 | 同上 |

**`CharacterProfile.Status`（具名子类 · 数值型运行状态）**

| 字段 | 类型 | 写入通道 | 取值域权威 | 状态 |
|---|---|---|---|---|
| `lifeTotal` | `int` | `Elements`（`CostKey.LifeTotal`） | `ResourceElements`：`(0, null, LifeTotalExhausted, null, null)` | **已定案** |
| `currentMana` | `int` | 战斗内（不经 spec，战斗运行态回写） | — | 半定（见 §3.10） |
| `manaLimit` | `int` | `Elements`（`CostKey.ManaLimit`） | `(0, null, null, null, null)` | **已定案** |
| `experiencePoint` | `int` | `Elements`（**`CostKey` 成员待补**） | ⟨待「cost element 清单」⟩ | 半定（见 §3.11） |
| `faith` | `int` | `Elements`（**待「道心 / 煞气 是否列入 `CostKey`」**） | `[0, 100]` 已定 | 半定（见 §3.12） |
| `bloodlust` | `int` | 同上 | `[0, 100]` 已定 | 同上 |
| `lifeSpan` | `int` | `Elements`（`CostKey.LifeSpan`） | `(0, null, LifeSpanExhausted, LifeSpanCost, null)` | **已定案** |
| `FaithBand` | `sbyte` | `StatusChanges` | `StatusFields`：`(Int, -2, 2)` | **已定案** |
| `BloodlustBand` | `sbyte` | `StatusChanges` | `(Int, 0, 3)` | **已定案** |
| `LifeSpanBand` | `sbyte` | `StatusChanges` | `(Int, 0, 2)` | **已定案** |
| `ChapterLifeSpanBudget` | `int` | `StatusChanges` | **`StatusFields` 缺行** → 见 §3.13 | 半定 |
| `CurrentLocationId` | `string` | `StatusChanges` | `(Id, -, -)` | **已定案** |
| `LocationEventCount` | `int` | `StatusChanges` | `(Int, 0, null)` | **已定案** |
| ⟨隐藏属性第四项？⟩ | — | — | — | **仍待答**（不在本草稿范围） |

> **`Status` 的边界（已定，本草稿只复述一句作为归位判据）：** `Status` 装**数值型运行状态**；集合型 build 状态（deck / 神通 / 储物袋 / 禁用表 / 剧本锚点）与 `Status` **平级**，不落其内。→ `systems/character-profile/_index.md`

### 3. `PlayerProfile` 完整字段表

| # | 字段 | 类型 | 层 | 写入通道 | 状态 | 权威 |
|---|---|---|---|---|---|---|
| 1 | `accountInfo` | `AccountInfo`（5 字段） | 规则 | — （后端写三项 / 客户端写 `Nickname`） | **已完整定案** | `account-info.md` |
| 2 | `characterProfiles`? | `IReadOnlyList<CharacterProfile>` | 规则 | — | **字段名未定** | 见 §3.14 |
| 3 | `playerPowers` | `IReadOnlyList<PlayerPower>` | 规则（透明段） | `AbilityElements` | **字段名由契约反向锁定** | 见 §3.14 |
| 4 | `playerItems` | `IReadOnlyList<PlayerItem>` | 规则 | `AbilityElements` / `ConsumePlayerItem` | 同上 | 同上 |
| 5 | `achievement` | `IReadOnlyList<Achievement>` | 规则 | AchievementManager | 字段名已定 · **条目 schema 待专场** | `achievement/_index.md` |
| 6–11 | 六个 Codex 字段 | 见 §3.15 | 规则（不透明） | `ProfileChangeSpec` | **本草稿提案** | `codex/_index.md` |
| 12 | `statistics` | `PlayerStatistics`（2 字段） | **统计** | `Stats`（`StatDelta`） | **已完整定案** | `player-profile/_index.md` |
| 13 | `playerPowerFragment` | `PlayerPowerFragment`（7 字段） | 规则（透明段） | `Elements`（四条具名 element） | **已完整定案** | 同上 |
| 14 | `entitlement` | `PlayerEntitlement`（1 字段） | 规则（透明段 · 后端写） | `Elements`（`BundleGrantOrdinal` 置值） | **已完整定案** | 同上 · `monetization.md` |
| 15 | `gameSetting` | `GameSetting`（具名类） | — | ⟨待⟩ | **清单待答** | 见 §3.16 |

**不进 `PlayerProfile` 的三样（已定 / 本草稿澄清）：** `baseRevision`（传输层元数据，进 Profile 会自指）· `revision`（同）· `schemaVersion`（见 §3.17）。

---

## 具体形态（对空白格的逐条提案）

### 3.1 `CharacterProfile.id` —— 必须存在，形态取 GUID

`[既有推演]` **它已经被四处消费，只是从未被登记：** `CycleStarted(string CharacterId, …)` / `EventResolved` / `ChapterCompleted` / `CharacterDefeated` 四个 EventBus 负载、`RetryChapter(string characterId)`、`CharacterProfileDiff` 的键、以及 `pastEvent` / `disabledAbility` / `CurrentLocationId` 三处读档校验的定位上下文（`PushError` 带 `characterId`）。**没有它，diff 无法寻址、日志无法定位。**

建议形态：

```csharp
string Id;   // 轮回创建时由客户端生成的 GUID（"N" 格式，32 位小写十六进制无连字符）
```

- **客户端生成、不向后端申请。** 依据：`CharacterProfileDiff` 的键值以下对后端完全不透明（`sync-service.md`），后端从不解析它；向后端申请一个 id 会在轮回开始处插入一次网络往返，而轮回开始是既定的**自动存档点而非阻塞点**。
- **不用「第 N 个角色」的序号。** 序号需要一个账号级计数器（又一个规则字段 + 又一条幂等问题），且角色不会被删除（`PlayerProfile` 只增不删）却仍可能并行创建于多篇章。GUID 零协调。
- **不用 `characterDataId`（模板 id）作键**——同一模板可在不同篇章各有一个 ongoing 角色。

### 3.2 `CharacterProfile.characterDataId` —— 角色模板的引用

`[既有推演]` 角色已升格为**有身份的模板 `CharacterData`**（自带一个神通 + 两门绑定功法，每局一致，→ `character-profile/_index.md`）。要让「同一个角色的每一局手感相同」这条设计成立，存档必须记住**这一局是哪个模板**；此外 `plot-manager.md` 的 `PlotNodeData.CharacterIds`（限定角色模板）需要一个可比对的字段。

```csharp
string CharacterDataId;   // 指向 CharacterData.Id；轮回创建时写一次，此后不变
```

读档校验建议：解析不到 → **必需缺失** → `PushError` 带 `characterId` + `characterDataId`（与 `CurrentLocationId` 同档：角色模板是结构性内容，解析不到即坏档，不能像 `pastEvent` 那样降级）。

### 3.3 `CharacterProfile.defeatReason` —— 三值原因需要一格

`[既有推演]` ADR-0004 定「`defeated` 为单一终态，**原因收敛为三种**」，`DefeatReason` 枚举已在共享核心类型中、`CharacterDefeated` 负载已携带它，`ResourceElements` 表的 `DepletionDefeat` 列产出它——**但没有任何字段保存它**。而它有真实消费方：元进程界面的角色履历（「这个角色是怎么没的」）与轮回结束屏。

```csharp
DefeatReason? DefeatReason;   // null ⟺ status != Defeated
```

- **不用 `DefeatReason.None` 哨兵值**：`DefeatReason` 是**三值封闭**枚举（`Discarded` / `LifeSpanExhausted` / `LifeTotalExhausted`），加一个 `None` 会让每个消费点都要处理一个不该出现的分支；可空引用 / 可空值类型是 C# 表达「这一维只在某状态下有意义」的既有形态。
- 读档校验：`status == Defeated` 且本字段为 null → **可选缺失** → `PushWarning`（履历少一行，不阻断）；`status != Defeated` 且本字段非 null → 不可能态 → `PushWarning` + 按 null 处理。

### 3.4 `Realm` 枚举需要登记，`realm` + `level` 两字段落存档、全局序不存

`[既有推演]` `Realm` 已被 `ChapterCompleted(string CharacterId, int Chapter, Realm ReachedRealm)` 使用，但**未出现在 `systems/architecture.md`「共享核心类型」的枚举清单里**——那份清单是全库枚举的单一登记处。建议补：

```csharp
public enum Realm { QiRefining, FoundationEstablishment, GoldenCore, NascentSoul }
```

**存 `realm` + `level`，不存全局序 `globalLevel`。** 依据「重算得出来的不存」：全局序是 `(realm, level)` 的纯函数（13 + 4 + 4 + 1 = 22，见 `game-progression.md`）。反向也是纯函数，故理论上存哪一个都可以；**取 `realm` + `level` 是因为 `realm` 自己有独立消费点**——`lifeTotal` 境界基线（10 / 25 / 40）、寿元境界增量（+100 / +300 / +500）、境界名展示、`ChapterCompleted` 负载——若只存 `globalLevel`，这四处每次都要反查一张区间表。

### 3.5 卡组：`technique` + `looseCard` 两个字段

`[既有推演]` deck 的「**存档存 build 层而非展开层**」已定案：「卡组落存档的是『功法 `Id` + 层数』列表 + 游离牌 `Id` 列表」（`deck/_index.md` 推论 ③）。这直接给出两个字段，只是名字与条目类型没写下来：

```csharp
IReadOnlyList<TechniqueEntry> technique;   // 单数命名，沿用 pastEvent / disabledAbility 的既有风格
IReadOnlyList<string>         looseCard;   // 游离散牌，多重集：同一 CardData.Id 可出现多次

public readonly record struct TechniqueEntry(
    string TechniqueId,   // 指向功法内容条目的稳定 Id
    int    Tier);         // 当前层数，>= 1
```

- **`TechniqueEntry` 取 `readonly record struct`**（两个字段、一批只有个位数条、要落存档且进 diff）——与 `StatusAssignment` / `DeckChangeElement` 同款；`PastEventEntry`（13 字段）与 `EventOption`（字段多）才取引用型 `record`，判据即 `future-event-service.md` 已写下的那条。
- **`looseCard` 是裸 `string` 列表而非 record 列表**：散牌没有任何随实例变化的状态（`CardInstance` 的运行态只存在于战斗内、随 `activeCombat` 走），故一个 `Id` 就是全部信息。
- **`looseCard` 的入组通道仍缺 element**（`DeckChangeOp` 只有 `RemoveLooseCard`）——**这一格由 S4 分片回答，本草稿不定形**；本字段的**存档形态**不依赖那个答案（无论增向落成新 `Op` 还是落到别的列，落进来的都是一个 `Id`）。
- 读档校验：`TechniqueId` / `looseCard` 元素解析不到 → **必需缺失** → `PushError`（与 `DeckChangeElement.Id` 的施加侧校验同口径：悬空 `Id` 写进 Profile 即污染存档）；`Tier < 1` → `PushError`。

### 3.6 三个持有条目：`CharacterItem` / `CharacterPower` / `PlayerPower` / `PlayerItem`

`[既有推演]` 四类持有条目的字段已被分散定齐，只是没有并成 record 形态。**四者共有 `SourceCode`**（权威 `systems/common-properties.md`），`status` 归 power 两类，`Charges` 归 item 两类：

```csharp
// 轮回级（落 CharacterProfile）
public readonly record struct CharacterItem(string ItemId,  int Charges, bool Status, Source SourceCode);
public readonly record struct CharacterPower(string PowerId,             bool Status, Source SourceCode);
// 账号级（落 PlayerProfile）
public readonly record struct PlayerItem (string ItemId,  int Charges, bool Status, Source SourceCode);
public readonly record struct PlayerPower(string PowerId,             bool Status, Source SourceCode);
```

- **`Charges` 只在 item 两类上**：`ItemData.Charges` 是内容侧的**上限 / 初值**（法宝可为无限 `-1`，古宝必 `> 0`），持有条目上的 `Charges` 是**剩余次数**。允许取 `0`（`ux/screen-flow.md` 的储物袋筛选 chip 有一项 `已耗尽` 读 `Charges == 0`）；无限法宝恒为 `-1`。
- **`Status` 落 `bool`（true = 启用）而非枚举**：它是二值开关，`player-power/common-properties.md` 明写「启用 / 禁用，默认启用」；三值以上的可能性不存在（**本轮回禁用**是第三维，已落 `disabledAbility`，不挤进这一格）。
- **`magicPack` 的元素是「一份实例」而非「一条 Id 一行」**（已定案，→ `character-profile/item/common-properties.md`）：同 `ItemId` 多份 = 多个元素，按 `ItemId` 堆叠是**呈现层聚合**。
- **`characterPower` 字段名**：`item` 一族借了已定名的容器概念（储物袋 `magicPack`），power 一族**没有对应的已定名容器**，故退回库内既有的单数风格（`pastEvent` / `disabledAbility` / `achievement`），取 `characterPower`。这正是 `achievement/_index.md` 为自己那一格写下的同一条理由。
- ⚠ **`playerPowers` / `playerItems` 的字段名不能自由选**——见 §3.14。

### 3.7 `currentEventBatch` —— 当前批物化选项必须有一格

`[既有推演]` `future-event-service.md` 明写「**定稿实例必须落存档** …… 当前批 eventOptions 与 `pastEvent` 痕迹都存物化后的快照」，且 `EnemyInstance` / `ResearchSlot[]` / `ExchangeOffer[]` 三者都「随 `EventOption` 落存档」。**但当前批在两层 Profile 上没有任何一格。** 而它必须在 `CharacterProfile` 上：它是单角色、单轮回的状态，且决策点存档要能恢复到同一批选项。

**本草稿只登记这一格的存在与归属层（`CharacterProfile` 顶层、与 `activeCombat` 平级），不定它的形状——形状由 S3 分片回答**（含「派生实例是否替换当前批中的原实例」这一问；`future-event-service.md` 已写下 Explore 揭示是 `revealed = option with { IsRevealed = true }` 且**当前批里那份原实例不动**，S3 应以此为硬前提）。

### 3.8 `chapterRetry` 的三个字段名撞上命名硬约定

`[既有推演]` 形态已定案：**三个具名字段、通关后不清零、不用字典 / 索引数组**。但**具体字段名从未写下**，而最自然的写法 `Ch1RetryCount` **违反既定的命名硬约定**——「后缀 `Count` ⇒ 统计计数层」，而 `chapterRetry` 明确是**规则字段层**（它是 `RetryChapter` 的闸门输入）。`Ordinal` 后缀同样不合：它的语义是「第几次」这个**位置**、且要当幂等键用，而重试次数两者都不是。

**建议：**

```csharp
public sealed class ChapterRetry     // 规则字段层：严格同步 · 参与闸门判定
{
    public int Ch1RetryUsed { get; }   // ch1 = 随机换新角色 ⇒ 对每个角色恒为 0（已定，不是缺陷）
    public int Ch2RetryUsed { get; }   // 上限 3 / 持礼包 9
    public int Ch3RetryUsed { get; }   // 上限 1 / 持礼包 3
}
```

`Used` 后缀既避开两个被占用的词缀，也逐字对上文档已有的措辞（「`chapterRetry` 只答『用掉了几次』」）。**这条需要用户点头**——见「仍需用户决定」①，因为它可能被理解为要给命名约定加第三个词缀。

### 3.9 `startContentVersion` / `lastContentVersion` 的类型不一致（🔴）

`character-profile/_index.md` 与 `content-service.md` 的字段表都写 **`string`**；而 `content-service` 的门面属性是 **`int ContentVersion { get; }`**，`sync-service` 的 `ProfilePayload` 也写 **`int ContentVersion`**。同一个量在链路上有两种类型，直接撞上「**贯穿整条链路的类型一致性：层与层之间不做隐式装箱 / 转换**」。

**建议统一为 `int`**，理由三条：① 它的唯一玩法用途是**判等**（「两者不等 = 该轮回跨过内容更新」），`int` 判等零歧义；② 它在 manifest 里与「拒绝 `contentVersion` 小于本地已生效版本」这条**有序比较**一起使用（`content-service.md` 的防回放），有序比较要求数值型——字符串比较会在 `"9"` vs `"10"` 上给出错误答案；③ 传输侧已经是 `int`（`ProfilePayload`），改存档侧一处比改传输 + 契约两处便宜。

**这条须用户裁决**（见「仍需用户决定」②）：它牵动三份文档的字段表，且如果将来 `contentVersion` 想走 semver（像 `appVersion` 那样三段），答案会反转。

### 3.10 `currentMana` 的存档必要性

`[既有推演 · 但需确认]` `currentMana` 每回合恢复到 `manaLimit`、回合内不结转（`mana.md`）⇒ **它是纯战斗内运行态**，战斗外恒等于 `manaLimit`，按「重算得出来的不存」**它不该落在 `Status` 上，而该落在 `activeCombat` 内**（决策点存档要恢复「我这回合还剩几点法力」）。

但 `character-profile/_index.md` 与 `life-cycle-service.md` 两处的既有措辞都是「`Status`（…… `currentMana / manaLimit` ……）」。**建议：把 `currentMana` 从 `Status` 移入 `activeCombat`**，`Status` 只留 `manaLimit`。这与 `activeCombat` 已定的内容（「回合 / 步状态 + 两个参战方」）自洽，且省掉「战斗外的 `currentMana` 是什么意思」这个无答案的问题。**完整 schema 归 `combat-service.md`**，本草稿只提出移位。→ 「仍需用户决定」③

### 3.11 `experiencePoint` 需要一个 `CostKey` 成员

`[既有推演]` 「事件奖励**发放经验值**」（`game-progression.md`）⇒ 它必须经 `ProfileChangeSpec.Elements` 写入 ⇒ 它必须在 `CostKey` 中占一个成员、在 `ResourceElements` 中占一行。建议行：

| `CostKey` | Min | Max | 归 Min 时 | `CostModifier` | `GainModifier` | 依据 |
|---|---|---|---|---|---|---|
| `Experience` | 0 | 无 | 无（不构成终态） | `null` | ⟨**取向 · 见下**⟩ | 经验只增不减（无「扣经验」的既定通道）；`DefeatReason` 三值封闭无经验项 |

- **`CostModifier` 恒 `null`** —— 不存在消耗向。
- **`GainModifier` 是一个真实的取向点**：一条「修行事半功倍：经验 +20%」的法则是元进程里最自然的一类 QoL 法则，但开这一格意味着「满级前能否升满」这条已写下的验收项（`game-progression.md`「供给 / 需求 ≈ 1.15–1.20」）要按**老账号全开**校准。按既定的**缺省豁免**方向，本草稿填 `null`，日后确需时加一行即可。
- **本行落在「cost element 清单（资源族）」那条待答项之内**，故它是**提案而非定案**——见「前置依赖」。

### 3.12 `faith` / `bloodlust` 的存档形态

`[既有推演]` 两者的**区间 `[0, 100]` 与「触底不构成终态」已定**（`profile-service.md` 待决项原文），band 字段已定案 ⇒ 原始值必须落存档（band 有回滞 ⇒ band 不是当前值的纯函数，但当前值也不是 band 的函数，**两者都得存**，这正是既定的 band 持久化理由的另一半）。

```csharp
int Faith;        // [0, 100]
int Bloodlust;    // [0, 100]
```

- **常态点（`FaithBand == 0` 对应哪个区间）归 `plot-manager.md` 的档位表**，本草稿不填——那里是阈值 / 回滞 δ 的权威。
- **它们是否与资源族共用 `CostKey`** 是一条**已在册的待答项**（`profile-service.md`：「道心 `Faith` / 煞气 `Bloodlust` 是否列入 `CostKey`（轻）」）。**建议列入**（`[既有推演]`）：它们由事件推拉、要钳制、有明确区间，与 `ResourceElements` 五列逐列对得上；不列入则需要第六条写入通道来做同一件事。行形态：`(0, 100, null, null, null)`——两个修正列留空，理由与 band 同源且更重（一条法则能伪造隐藏属性即等于伪造整条剧本线的触发条件）。

### 3.13 `StatusFields` 需补 `ChapterLifeSpanBudget` 一行

`[既有推演]` `architecture.md` 的 `StatusFields` 表当前显式留了 `⟨ChapterLifeSpanBudget 及其余 Status 规则字段随各自专场逐条补⟩`，而「启动期断言表覆盖 `StatusKey` 的全部成员」是硬要求 ⇒ 缺行即启动期 `PushError`。建议行：

```
ChapterLifeSpanBudget → (Int, 0, null)
```

`Min = 0` 的理由与寿元同源（结转要求它是一个可加的**非负预算**）；无上界（结转累积无天花板）。

### 3.14 `PlayerProfile` 上的集合字段名：**被后端契约反向锁定**（🔴）

后端契约 `backend-design-documents/contracts/profile-sync.md` §5 的透明路径白名单里已冻结两条 **复数** path（`/playerPowers[*]/…`），而本库既有的集合字段命名风格是**单数**（`pastEvent` / `disabledAbility` / `magicPack` / `achievement`，且 `achievement/_index.md` 明写「**类型名恒为单数，复数只属于集合字段名**」——它自己却取了单数字段名 `achievement`）。

**两处不一致，必须在落笔前收口：**

| 面 | 现状 | 后果 |
|---|---|---|
| 契约冻结的 JSON path | `/playerPowers[*]`（复数） | 客户端字段若命名 `playerPower`，序列化出的 path 是 `/playerPower[*]` ⇒ **后端侧静默变成「这个字段消失了」，复算退化为空操作，两侧都不报错** |
| 库内集合字段风格 | `achievement` / `pastEvent`（单数） | 若为对齐契约把两个 power / item 字段写成复数，同一份 `PlayerProfile` 上就有两种风格并存 |
| 契约里的条目键名 | `/playerPowers[*]/id`（不是 `powerId`） | 与 `CharacterItem.ItemId` / `DisabledAbilityEntry.AbilityId` 的既有风格不一致 |

**建议（`[既有推演]`，但需用户点头 —— 见「仍需用户决定」④）：以契约侧为准，因为透明路径的稳定性纪律使它是两侧中更硬的约束**：

```csharp
IReadOnlyList<PlayerPower>      playerPowers;        // 契约冻结
IReadOnlyList<PlayerItem>       playerItems;         // 契约冻结（对称，虽在不透明段）
IReadOnlyList<CharacterProfile> characterProfiles;   // 对称
```

并把「集合字段名恒为复数」升为**一条全库通则**，`achievement` / `pastEvent` / `disabledAbility` / `plotKeyPoint` / `looseCard` / `technique` / `magicPack` **不改**——理由：`achievement/_index.md` 已为「若日后全库统一把集合字段改为复数风格，本字段随那次统一一并改，不单独例外」留了明确的口子，而**现在还不是那次统一**（改 `pastEvent` 等于改一条已冻结的 JSON path 邻域，收益是观感、代价是契约面）。**如实记下的代价：`PlayerProfile` 上会有两种风格并存**，且理由（一半被契约锁定）只写在这里。

**条目键名 `/playerPowers[*]/id`：建议客户端字段直接命名 `Id`**，不引入序列化改名层。虽然 `Id` 在本库通常指「本条目自身的稳定 Id」而此处指向内容条目，但引入一层字段名映射即制造两处真值——恰是本库反复否决的形态；补一行注释比补一层映射便宜。

### 3.15 六个 Codex：六个具名字段，条目取 record 而非裸 `string`

`[既有推演]` 「六者形状相同、账号级、按 `Id` 索引、静态文案、**存档只记解锁状态**」已定案，且**固定结构用具名字段不用字典**是既定先例（`chapterRetry` 三字段、三个 band）。

```csharp
IReadOnlyList<CodexEntry> enemyCodex;
IReadOnlyList<CodexEntry> characterPowerCodex;
IReadOnlyList<CodexEntry> playerPowerCodex;
IReadOnlyList<CodexEntry> characterItemCodex;
IReadOnlyList<CodexEntry> playerItemCodex;
IReadOnlyList<CodexEntry> locationCodex;

public readonly record struct CodexEntry(string Id);   // 首批只有解锁这一态
```

- **不落成 `codex: Dictionary<CodexKind, …>`**：增删一本图鉴本就要加一个 UI 页与一条收录触发，字典只换来一层查找与一处可空——与 `chapterRetry` 拒绝字典的判据逐字相同。
- **不落成裸 `IReadOnlyList<string>`**，尽管首批确实只有一个 `Id`：`codex/common-properties.md` 的待定清单里明确列着**计数字段**（遭遇次数 / 击败次数 / 败于其手次数 / 使用次数）与**首次解锁元数据**（篇章 / 境界 / 日期）两组候选。用 `CodexEntry` 包一层，日后加一格是**在 record 上加字段**（老档补默认值、零迁移）；用裸 `string` 则要把六个字段的类型全改一遍，且那六处 JSON path 的**元素形状**从标量变成对象——对 diff 的序列化形态是一次真实的破坏性变更。**这是本草稿唯一一处「为尚未答定的加法预留结构」，代价明写：首批每条多一层 JSON 对象嵌套。** → 「仍需用户决定」⑤
- **解锁 = 一次性全量写入**（已定案，`codex/common-properties.md`）⇒ 条目存在 ⟺ 已解锁，**不需要 `IsUnlocked` 布尔**。
- 读档校验：`Id` 解析不到 → **可选缺失** → `PushWarning` + 保留条目（与 `pastEvent` / `disabledAbility` 同口径：图鉴是历史知识，一条读不出的旧条目不该阻断登录）。
- **`LocationCodex` 的「记连边」不落存档**：连边随 location 内容条目静态给出（`codex/_index.md` 推论 ③ 已写明「存档形态仍是 id 集合」）。

### 3.16 `GameSetting`：只定形态，清单不填

`[通行做法 + 前置依赖]` 建议形态：**具名类，不是字典 / 键值表**（与 `CapabilityFlag` 用 `enum` 而非字符串 key、`PlayerEntitlement` 用具名字段而非集合，同一条纪律）。

**但本草稿不填任何设置项** —— `game-setting.md` 有两条在册待答项：设置项清单未定、**设备本地项 vs 账号级项的切分未定**。第二条是承重的：它决定哪些字段进 `PlayerProfile`（云端权威 · 进 diff）、哪些留 `user://`。在它答定前填字段等于替用户拍板一次同步口径。**建议的落笔顺序是：先答切分，再一次性定清单。** → 「前置依赖」

### 3.17 `schemaVersion` 不进 `PlayerProfile`

`[既有推演]` 存档必须带 schema 版本（`state-save-rules.md` / `common-properties.md`），但**它的落点是存档 / 传输的信封，不是 `PlayerProfile` 对象**——三处既有形态已经这么写了：`SyncEnvelope(AccountId, BaseRevision, SchemaVersion, LastAckAtUtc)` · `ProfilePayload(… SchemaVersion …)` · `ProfileSnapshot(PlayerProfile Profile, long Revision, int SchemaVersion)`。理由与 `baseRevision` 「不进 Profile」逐字相同：**把版本号塞进被版本化的对象会自指**，且会被卷进它自己的迁移路径。

本草稿只做这条**澄清**（当前三处形态已自洽，只是从未有一句话说「所以它不是 Profile 的字段」）。

### 3.18 JSON 序列化命名策略：camelCase，单点配置

`[既有推演]` 契约 §5 的全部 path 都是 camelCase（`/accountInfo/accountSeed` / `/playerPowerFragment/finaleWinOrdinal` / `/entitlement/bundleGrantOrdinal`），而客户端 C# 是 PascalCase（`.claude/rules/csharp-godot-rules.md`）。⇒ 序列化层需要一条 **camelCase 命名策略**，且**配置在一处**（与「请求头组装与应答头解析收敛到 `src/Core/` 的一处」同构：多于一处就会出现「一部分转了、另一部分没转」的半配置态）。

**推论（承重）：** 存档字段的 **C# 名与 JSON path 由这条策略机械对应** ⇒ **重命名任何一个透明段字段 = 破坏性契约变更**，不需要额外纪律，既有的「透明路径稳定性纪律」自动覆盖到 C# 字段名。

---

## 后果

- **文档影响：** `systems/character-profile/_index.md`（补总表 + 5 个新字段）· `systems/player-profile/_index.md`（补总表 + 六 Codex + 集合命名通则）· `systems/architecture.md`（`Realm` 枚举登记 · `StatusFields` 补 `ChapterLifeSpanBudget` · `CostKey` 补 `Experience` / 可能的 `Faith` / `Bloodlust`）· `systems/services/profile-service.md`（`ResourceElements` 补行 · `StatusFields` 逐行）· `systems/services/sync-service.md`（schema 版本一节 + `currentMana` 移位的连带）· `systems/player-profile/game-setting.md`（只补形态一句）· `systems/services/combat-service.md`（若采纳 `currentMana` 移位）。
- **存档 schema：bump 一次、空迁移**（当前无线上存档）。老档缺字段的补默认值口径：集合 → 空列表；`DefeatReason?` → null；`ChapterRetry` → 全 0；六 Codex → 空列表。
- **契约影响：零**（若按 §3.14 以契约为准落笔）。若用户反向裁决（改契约对齐库内单数风格），则是一次**破坏性契约变更**，须 bump `schemaVersion` 并与后端同批改 —— 那会在对侧库产生一份承接项。
- **diff 体积：** 新增字段全为标量或短列表，`sync-service.md` 的 ~2 KB / 事件预算与 400 KB / 轮回粗算**不受影响**；六 Codex 随账号年龄单调增长，落在既有「整聚合 pull」的关注面内——**建议沿用 `pastEvent` 的软上限告警形态**（阈值待定，不在本草稿）而非现在就做分页。

## 备选方案（已考虑并否决）

- **把两层 Profile 的字段表写成一份独立的 `systems/profile-schema.md`。** 否决：它会与两份 `_index.md` 的「意图」节形成第二权威，而那两处已经承载了每个字段的语义与判据。索引表应当挨着它索引的东西。
- **给 `CharacterProfile` 加 `createdAtUtc` / `completedAtUtc`。** 否决：按「重算不出来**且有消费方**」的完整口径——目前没有任何一处要求角色的绝对时间（履历排序用 `pastEvent` 的 `Seq`，篇章进度用 `chapter`）。日后元进程界面真要「上次玩这个角色是什么时候」时纯加法补，零迁移。
- **用一个 `Dictionary<string, string>` 承载 `GameSetting`。** 否决：与 `CapabilityFlag` 拒绝字符串 key 同一条理由（把「拼错了」从编译期推迟到运行时），且它会让「哪些项是账号级」这个真问题被一个开放容器悄悄绕过。
- **给六个 Codex 建一个 `List<CodexEntry>` 单表 + `Kind` 字段。** 否决：六本图鉴的**呈现形态已确定不同**（LocationCodex 是一张逐步显影的图，其余五本是列表 / 网格），单表会让每个消费点都先按 `Kind` 过滤一遍；且它与「固定结构用具名字段」的既定先例相反。

## 与既有决策的张力

1. **`contentVersion` 的类型在链路上不一致（🔴）。** `CharacterProfile.StartContentVersion` / `LastContentVersion` 记为 `string`（`character-profile/_index.md` · `content-service.md` 两处字段表），而 `content-service.ContentVersion` 与 `ProfilePayload.ContentVersion` 是 `int`。这直接违反 `.claude/rules/Context.md` 与 `systems/common-properties.md` 的「贯穿整条链路的类型一致性」。**不松动任何一侧的替代方案不存在**——必须有一侧改。本草稿倾向改存档侧为 `int`（理由见 §3.9）。

2. **`PlayerProfile` 集合字段名：契约（复数）vs 库内风格（单数）（🔴）。** 详见 §3.14。**松动库内风格的代价** = 同一个对象上两种命名风格并存 + 一条只写在一处的理由；**松动契约的代价** = 一次破坏性契约变更 + 两侧同批改 + 后端复算面在过渡期不可靠。两者不对称，故倾向前者。

3. **`Count` 后缀被统计层独占，规则层缺一个表达「数量」的词缀（🟠）。** `chapterRetry` 是规则字段层却语义上是数量，`Ordinal`（位置）与 `Count`（统计层）两个既有词缀都不合。本草稿提 `Used` 后缀（§3.8）。**这是对既定命名硬约定的一次扩充，不是违反**——但它需要用户确认，否则「规则层不许用 `Count`」这条可机械检查的纪律会在第一次遇到反例时被悄悄放宽。

4. **`currentMana` 的归属与两处既有措辞相左（🟠）。** `character-profile/_index.md` 与 `life-cycle-service.md` 都把 `currentMana` 写在 `Status` 内；按「重算得出来的不存」它该在 `activeCombat` 内。**不松动的替代方案**：留在 `Status` 内并明写「战斗外恒等于 `manaLimit`，战斗内由 combat-service 回写」——可行但引入一个跨服务的隐式不变式，且给 `Status` 开了一个「纯战斗内运行态」的先例。

5. **六 Codex 条目取 record 而非裸 `string`，是本草稿唯一一处为未答项预留结构（🟠）。** 它与本库「不为一条尚无实例的纪律先行造工具」的偏好方向相反。理由是**这一处的加法窗口会关闭**（改元素形状是 diff 序列化的破坏性变更），与 `LocalizedText` / `DrawPool<T>` 排在「第一份内容 FR 之前」是同一类窗口判断。

## 前置依赖

本方案的以下部分在对应问题答定前**无法定稿**：

| 本草稿的哪一部分 | 依赖的待答问题 | 在册处 |
|---|---|---|
| §3.11 `Experience` 行 · §3.12 `Faith` / `Bloodlust` 是否列入 `CostKey` | **cost element 清单（资源族）未定** | `profile-service.md` 待决项 |
| §3.5 `looseCard` 的**写入通道** | **游离散牌入组的 element 载体未定（承重）** | `deck/_index.md` · `profile-service.md` —— **S4 分片正在答** |
| §2 第 16 行 `plotKeyPoint` 的集合型载体形状 | 同上（element 层三缺口） | **S4 分片正在答** |
| §3.7 `currentEventBatch` 的形状 | **结算进行中的 `EventOption` 派生实例如何落存档** | **S3 分片正在答** |
| `activeCombat` 内的 `EnemyInstance` 形态 | `EnemyInstance` / `PoolScope` 形态 | **S5 分片正在答** |
| §3.16 `GameSetting` 的字段清单 | 设置项清单 + **设备本地项 vs 账号级项的切分** | `game-setting.md` 待决项 |
| `achievement` 条目的 schema | 成就条目 schema 与进度模型未设计 | `achievement/_index.md` |
| `Status` 是否有**第四个隐藏属性** | 隐藏属性完整清单 | `character-profile/_index.md` |
| `characterDataId` 的**取值面**（池中几个角色、是否逐步解锁） | **角色模板池的形态（承重）** | `open-questions/06-meta-progression.md` —— 注：字段形态**不**依赖它，只有内容侧取值面依赖 |
| 六 Codex 的**计数字段是否要** | 各图鉴的解锁触发与词条深度 | `codex/_index.md` |

**未被阻塞的部分（可独立采纳）：** §3.1 `id` · §3.2 `characterDataId` · §3.3 `defeatReason` · §3.4 `Realm` 登记 · §3.6 四类持有条目 record · §3.13 `StatusFields` 补行 · §3.15 六 Codex 字段形态 · §3.17 `schemaVersion` 澄清 · §3.18 命名策略。**这九项合起来已经把两层 Profile 的「有哪些格」补齐**——被阻塞的都是某几格里装什么，不是格本身。

## 仍需用户决定 → **已全部裁决（2026-08-17 · 批量评审）**

> **定案（六项）：**
> **① 取 A** —— `Ch1RetryUsed / Ch2RetryUsed / Ch3RetryUsed`，命名硬约定表补一行「规则层的『数量』用 `Used`」。
> **② 取 A** —— `contentVersion` 统一为 `int`，改存档侧两处字段表。
> **③ 取 A `[采纳推荐 — 待复核]`** —— `currentMana` 移入 `activeCombat`。
> **④ 取 C —— ⚠ 逆推荐项，用户明确选择「改契约为单数」。** 后端白名单改为 `/playerPower[*]` 等单数形态，库内命名风格全库自洽（新字段一律沿用既有单数风格）。这是**破坏性契约变更**：须 bump `schemaVersion` + 两侧同批改，并在 `backend-design-documents/` 落一份承接项（已由本次批量运行落 `inbox/solution-draft-profile-field-schema.md` 的对侧配套草稿，两份互相回链）。原推荐 A 的「两侧硬度不对称」论据用户已知悉并推翻——记录在案，不再复议。
> **⑤ 取 A** —— `CodexEntry` record，首批只一个 `Id`。草稿中如实记下的反对意见（与「不为尚无实例的需求先行造结构」偏好相反）用户已见并仍取 A。
> **⑥ 取 A `[采纳推荐 — 待复核]`** —— 两份 `_index.md` 各补一张只有形态列的总表。
>
> **连带（orchestrator 统一编排）：** 本草稿要求的 schema bump 与同批 S2 / S3 / S4 / S5 的 bump **合并为同一次**、同一段迁移说明。
> 标 `[采纳推荐 — 待复核]` 者按 `.claude/rules/batch-orchestration.md` 铁律 ①**不计作用户拍板**，评审本草稿时可逐项推翻。
>
> 下列原文保留为选项与理由的溯源。

**① `chapterRetry` 三个字段的名字（§3.8）。**
- **A（推荐）`Ch1RetryUsed / Ch2RetryUsed / Ch3RetryUsed`** —— 避开 `Ordinal`（位置 / 幂等键）与 `Count`（统计层）两个已被占用的词缀，逐字对上文档措辞「用掉了几次」。后果：命名硬约定实际上多了一个词缀（规则层的「数量」用 `Used`），须在 `player-profile/_index.md` 那张命名表里补一行。
- **B** `Ch1RetryCount / …` —— 直觉最顺，但**违反可机械检查的既定约定**（`Count` ⇒ 统计计数层），且会让那条约定在第一个反例上失效。
- **C** 放宽约定：`Count` 后缀不再单义，改由所在类的层属性决定。后果：那条约定从「可机械检查」降级为「要读上下文」，失去它被写下来的全部理由。
- **理由：** A 是唯一同时保住可机械检查性与语义准确性的选项。

**② `contentVersion` 的类型统一到哪一侧（§3.9 · 张力 1）。**
- **A（推荐）统一为 `int`**，改存档侧两个字段。后果：改 `character-profile/_index.md` 与 `content-service.md` 各一处字段表；判等与有序比较（manifest 防回放）都零歧义；传输侧与门面属性不动。
- **B** 统一为 `string`，改 `content-service.ContentVersion` 与 `ProfilePayload.ContentVersion`。后果：**`ProfilePayload` 是跨边界类型 ⇒ 需与后端同批改**；且 manifest 的「拒绝 `contentVersion` 小于本地已生效版本」要改为按语义化版本解析比较。
- **理由：** A 改动面更小、且落在「本库有权威」的一侧；B 的收益仅在「将来想走 semver」这一假设上，而 `appVersion` 已经承担了 semver 那条轴（`X-App-Version` semver 三段），`contentVersion` 与它分工明确。

**③ `currentMana` 是留在 `Status` 还是移入 `activeCombat`（§3.10 · 张力 4）。**
- **A（推荐）移入 `activeCombat`** —— 它是纯战斗内运行态（每回合刷满、不结转），战斗外无意义。后果：`Status` 少一格；`character-profile/_index.md` 与 `life-cycle-service.md` 两处措辞要改；`combat-service.md` 的 `activeCombat` schema 多一格（它本就要记「回合 / 步状态」）。
- **B** 留在 `Status`，明写「战斗外恒等于 `manaLimit`」。后果：不改任何既有措辞，但给 `Status`（数值型**角色**状态）开一个纯战斗内字段的先例，并引入一个跨服务的隐式不变式。
- **理由：** A 与「重算得出来的不存」逐字相符，且 `Status` 的既定定位是**跨事件持续的角色状态**——`currentMana` 的寿命短于一次事件，与 `activeCombat` 同族。

**④ `PlayerProfile` 集合字段的命名风格（§3.14 · 张力 2）。** ⚠ **这一项裁决错误的代价是后端复算静默失效。**
- **A（推荐）以契约为准：`playerPowers` / `playerItems` / `characterProfiles` 取复数，其余既有单数字段不动。** 后果：同一对象上两种风格并存（理由：一半被冻结的 JSON path 锁定）；契约零改动；`achievement/_index.md` 已为将来的统一留好了口子。
- **B** 全库统一为复数，包括改 `pastEvent` → `pastEvents`、`disabledAbility` → `disabledAbilities`、`achievement` → `achievements`、`plotKeyPoint` → `plotKeyPoints`。后果：风格一致，但**动到 `characterDiffs` 下的键名邻域**，且这些字段的 schema 刚刚定案不久，改名要连带 bump。
- **C** 改契约，让后端白名单改成 `/playerPower[*]`。后果：**破坏性契约变更**，须 bump `schemaVersion` + 两侧同批改，且在对侧库要落一份承接项。
- **理由：** 透明路径稳定性纪律明写「移动或重命名任一透明路径 = 破坏性契约变更」，而库内命名风格没有任何一处这样的硬后果——两侧硬度不对称。**A 附带一个动作：把「集合字段名恒为复数」写成通则、并明记既有单数字段是被冻结路径挡住的例外**，否则下一个人会照 `pastEvent` 的样子把新字段也写成单数。

**⑤ 六个 Codex 的条目类型（§3.15 · 张力 5）。**
- **A（推荐）`CodexEntry` record，首批只有一个 `Id` 字段。** 后果：首批每条多一层 JSON 对象嵌套（存档体积略增）；日后加计数 / 首解锁元数据是 record 加字段、零迁移。
- **B** 裸 `IReadOnlyList<string>`。后果：首批最省；但一旦要加计数字段，六个字段的**元素形状**从标量变对象——按「diff 顶层键整键替换、键值以下对后端不透明」这条，客户端侧仍是一次迁移，且六处一起改。
- **理由：** `codex/common-properties.md` 的「待定的字段清单」里已经明确列着两组候选字段，这不是假想的将来；而加法窗口在写下第一批存档时关闭。**如实记下的反对意见：** 这与本库「不为尚无实例的需求先行造结构」的偏好相反，若用户判定「计数字段大概率不做」，B 是正确选择。

**⑥ 是否接受本草稿的「索引表」落笔形态（§1）。**
- **A（推荐）** 在两份 `_index.md` 各补一张**只有形态列**（字段名 / 类型 / 层 / 写入通道 / 回链）的总表，语义仍归各专题文档。
- **B** 不建表，只把新字段逐条并入现有的「意图」节条目流。后果：不新增维护面，但「两层 Profile 一共有哪些字段」这个问题仍然没有一处能回答——而它正是本次要解决的那件事。
- **理由：** A 的表**不含任何语义列**，因此不触 `common-properties.md` 判据卡的第二权威硬边界；B 会让 sync 的字段面继续散落在十余份文档里。
