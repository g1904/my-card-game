# Phase A 报告 — 分片 A：`solution-draft-profile-field-schema.md`（两层 Profile 的完整字段 schema）

目标库：`game-design-documents/`（主库）。对侧牵连：`backend-design-documents/contracts/profile-sync.md`（因裁决 ④，见 🔴-3）。

## 1. 意图要点（我的理解）

1. 本草稿的性质是**收拢而非发明**：把散落十余份文档的两层 Profile 字段汇成两张**只有形态列**（字段名 / 类型 / 层 / 写入通道 / 权威回链）的总表，语义仍留在各专题文档，不制造第二权威。
2. 给 `CharacterProfile` 补五格从未登记但已被四处消费的字段：`id`（客户端生成 GUID）· `characterDataId`（角色模板引用）· `defeatReason`（`DefeatReason?`）· `technique` / `looseCard`（deck 的 build 层落档）· 并登记 `currentEventBatch` 这一格的存在（形状归 S3）。
3. 给 `PlayerProfile` 补六个 Codex 具名字段（元素 `CodexEntry(string Id)`）、四类持有条目的 record 形态（`CharacterItem` / `CharacterPower` / `PlayerItem` / `PlayerPower`，共有 `SourceCode`，item 两类多一个 `Charges`）。
4. 向共享核心类型登记 `Realm` 枚举、补 `StatusFields` 的 `ChapterLifeSpanBudget` 行、提案 `CostKey.Experience` 行与「道心 / 煞气是否列入 `CostKey`」的建议行。
5. 三条澄清：`schemaVersion` 不进 Profile（它是信封字段）· JSON 序列化取 camelCase 单点策略 ⇒ 透明段的 C# 字段名与 JSON path 机械对应 · `currentMana` 属战斗内运行态。
6. 用户已在评审中裁决六项（见 §2 的 ✅ 节），其中 ④ **逆推荐**：集合字段名全库统一为**单数**，后端透明路径白名单随之改名——这是一次破坏性契约变更。

## 2. 校验发现

### 🔴 冲突（必须 interview）

- **裁决 ④「集合字段名全库统一为单数」的适用边界未定，库内至少三处复数集合标识符落在边界的灰区。**
  - 想法侧：裁决 ④「后端白名单改为 `/playerPower[*]` 等单数形态，库内命名风格全库自洽（新字段一律沿用既有单数风格）」。
  - 既有权威：
    - `systems/character-profile/_index.md` 第 116–125 行的 rng 存档 schema 片段：`"rng": { "CycleSeed": …, "streams": [ { "name":…, "seed":…, … } ] }` —— **`streams` 是复数，且它是 `CharacterProfile` 的存档字段**。
    - `backend-design-documents/contracts/profile-sync.md` §3a / §4：`characterDiffs`（复数）是 push 负载的顶层键；对侧草稿的改名表**只列了 `/playerPowers` 与 `/playerItems`，未动 `characterDiffs`**。
    - `systems/services/future-event-service.md`：`EventOptionBatch.Options`；`systems/services/plot-manager.md`：`PlotNodeData.CharacterIds` —— 运行时 / 内容侧的复数集合属性。
  - 选项与后果：
    - **(a) 边界 = 「`PlayerProfile` / `CharacterProfile` 及其子对象的存档字段名」** ⇒ `rng.streams` → `rng.stream` 同批改（当前无线上存档，零迁移）；`characterDiffs` / `playerDiff` 属 **diff 报文结构**而非 Profile 字段，不动；运行时 / 内容侧属性不受约束。写入 `systems/player-profile/_index.md`（通则）+ `systems/character-profile/_index.md`（schema 片段改名）。对侧库：仅 §5 白名单四行（对侧草稿已覆盖）。
    - **(b) 边界 = 「一切落存档或进 push 负载的集合键」** ⇒ 连 `characterDiffs` 一并改为 `characterDiff`。对侧库改动面比对侧草稿写的更大，**须回改那份草稿**。
    - **(c) 边界 = 真·全库（含运行时类型属性与内容侧字段）** ⇒ `EventOptionBatch.Options`、`PlotNodeData.CharacterIds` 等一并改，改动面扩散到 5 份以上文档且与本批 B / C / E 的写入面直接相撞。
  - **推荐：(a)** —— 命名通则的唯一硬后果（后端静默复算退化）只发生在 **Profile 字段 → JSON path** 这条链上；`characterDiffs` 是后端**自己解析的信封结构**、不经 camelCase 字段映射产生，改它只有成本没有收益。依据：`contracts/profile-sync.md` §5「透明字段的 JSON path 是契约的一部分」约束的对象是 Profile 内的路径，§3a 的顶层键是另一层。

- **`/playerPower[*]/id` 的条目键名未随本次破坏性改名一并收口（窗口只此一次）。**
  - 想法侧：§3.14 末段「建议客户端字段直接命名 `Id`，不引入序列化改名层」——该论据的前提是「契约已冻结 `id`、动它要付破坏性变更的代价」。
  - 既有权威：`contracts/profile-sync.md` §5 冻结 `/playerPowers[*]/id`；而库内四类持有条目的既有风格是 `<Kind>Id`——`CharacterItem.ItemId`（`systems/character-profile/item/common-properties.md`）、`DisabledAbilityEntry.AbilityId`、`PlotKeyPoint.ArcId`、`TechniqueEntry.TechniqueId`。
  - **裁决 ④ 已经付掉了那笔代价**（bump + 两侧同批 + 一次性），故「不动 `id`」的原论据在本批**已不成立**。
  - 选项与后果：
    - **(a) 同批把条目键名一并改为 `powerId` / `itemId`** ⇒ 对侧 `contracts/profile-sync.md` §5 的两行 + §7 复算伪码的字段引用改名（**算法与 §6a 的 8 组测试向量一字不动**）；客户端四类持有条目命名全族一致；对侧草稿的改名表须**补两行**。
    - **(b) 保留 `id`** ⇒ `PlayerPower.Id` / `PlayerItem.Id` 与 `CharacterPower.PowerId` / `CharacterItem.ItemId` 在同一族里两种风格并存，理由只写在一处；下次要收口须再付一次破坏性变更。
  - **推荐：(a)** —— 依据是本库反复行使的「窗口判断」（`LocalizedText` / `DrawPool<T>` / 本草稿 §3.15 同款）：破坏性契约变更的窗口本批已开，同批收口边际成本≈0，错过则永久两种风格。

- **对侧库草稿 `status: awaiting-review` 且不在本批范围 ⇒ 单侧提炼会制造两侧不一致的窗口，而该不一致按契约「不报错、只产生风控噪声」。**
  - 想法侧：客户端草稿「后果」节：「若用户反向裁决（改契约对齐库内单数风格），则是一次破坏性契约变更，须 bump `schemaVersion` 并与后端同批改」；对侧草稿「前置依赖」：「两份须同批落笔，任一侧单独提炼都会制造一段两侧不一致的窗口」。
  - 既有权威：`.claude/rules/design-library-routing.md`「对称落笔 …… **不允许只改一侧就宣称收口**」；`contracts/profile-sync.md` §7a「复算不一致仅记账 + 上报风控，不拒绝、不改写」⇒ 不一致的症状不是报错。
  - 选项与后果：
    - **(a) 把对侧草稿纳入本批 Phase B**（新增一个后端分片）⇒ 写 `backend-design-documents/contracts/profile-sync.md` §5 白名单四行（若采 🔴-2 则六行）+ §7 字段引用 + 一句命名通则 + `schemaVersion` bump；**并须一并回答对侧草稿自己的两项待决**（切换时序 A 直接切 / B 双读期；残卷 `ordinal` 是否确按「递增后的值」实现）。
    - **(b) 客户端本批只落非命名部分**（§3.1–3.13、3.15、3.17），命名通则与总表里的两个字段整体延后到两侧同批 ⇒ 两层总表本批落不全，本草稿要解决的核心问题（sync 上行字段面）继续悬着。
    - **(c) 客户端照落，后端库只登记一条承接待答项** ⇒ 明知留下不一致窗口，仅在 `backend-design-documents/open-questions/cross-boundary.md` 留痕。
  - **推荐：(a)** —— 与跨库纪律「对称落笔」逐字相符；且对侧草稿已成文，纳入的增量成本只是一场 interview 里多两问。若用户不愿在本批引入后端分片，退 (c) 而非 (b)（(b) 会让本批最重要的产物残缺）。

### 🟠 含糊（必须 interview）

- **JSON 命名策略（§3.18）与一份已定案的 schema 片段自相矛盾：`rng` 片段里 `CycleSeed` 是 PascalCase，同层的 `streams` / `name` / `seed` / `state` / `drawCount` 是 camelCase。**
  - 既有权威：`systems/character-profile/_index.md` 第 116–125 行。
  - 选项：(a) 本批一并改为 `cycleSeed`（camelCase 单点策略落地，当前无线上存档 ⇒ 零迁移）；(b) 只写策略、片段留待后续统一（则本库存在一处已知违反自己策略的示例 schema）。
  - **推荐 (a)** —— §3.18 的推论「C# 名与 JSON path 由策略机械对应」若在库内第一个示例上就不成立，这条推论无法被读者信任。

- **裁决 ③（`currentMana` 移入 `activeCombat`）实际上是「删除一处重复登记」而非新增，且要连带修一句错话。**
  - 既有权威：`systems/services/combat-service.md` 第 130 行——参战方 `sides` 已列 `currentMana / manaLimit`，括注「**（战斗内不变，落它只为读档自洽）**」。而 `mana.md` 明写 `currentMana` 每回合刷满、回合内消耗 ⇒ 该括注对 `currentMana` **是错的**，只对 `manaLimit` 成立。
  - 选项：(a) 从 `Status` 删 `currentMana`，并把那句括注改写为「`manaLimit` 战斗内不变，落它只为读档自洽；`currentMana` 是回合内消耗量，决策点存档必须恢复它」；(b) 只删 `Status` 那一格，不动 combat-service 的措辞（留一句错话在权威文档里）。
  - **推荐 (a)**。注意：这使 A 的写入面新增 `systems/services/combat-service.md`（plan.md 的表未列，见 §6）。

- **`CostKey` 的两条提案行（`Experience` · `Faith` / `MaleficQi`）本批是否落笔。**
  - 想法侧：§3.11 / §3.12 自标「提案而非定案」，前置依赖是 `profile-service.md` 的待决项「cost element 清单（资源族）未定（承重）」与「道心 / 煞气是否列入 `CostKey`（轻）」。
  - 选项：(a) 本批落笔（`ResourceElements` 补 `Experience → (0, null, null, null, null)`、`Faith` / `MaleficQi → (0, 100, null, null, null)`，并把 `CostKey` 那条「轻」待决项移出）；(b) 只在总表里标 ⟨待「cost element 清单」⟩，一行都不落。
  - **推荐 (a) 的「轻」那一半**：`Faith` / `MaleficQi` 的区间与终态语义已定，落行是纯登记；`Experience` 的 `GainModifier` 一列是真实取向点（开它意味着「满级前能否升满」的 1.15–1.20 供需比要按老账号全开校准），按 modifier pipeline「缺省豁免」的既定方向填 `null`。
  - ⚠ **跨分片**：分片 D（element 层载体缺口）可能同批动 `CostKey` / `DeckChangeOp` / `ProfileChangeSpec` 列，须与 D 的 Phase A 结论合并核对。

- **`characterProfile`（单数）作为 `IReadOnlyList<CharacterProfile>` 的字段名可读性。**
  - 单数通则落地后，`PlayerProfile` 上持有一组角色的字段名与类型名仅首字母大小写之差。
  - 选项：(a) 照通则取 `characterProfile`；(b) 给它开一个复数例外（通则第一天就有例外）；(c) 借一个容器概念另起名（如 `roster`），与 `magicPack` 借「储物袋」同款。
  - **推荐 (a)** —— `achievement` / `pastEvent` 已是同款形态（类型 `Achievement` / 字段 `achievement`），开例外会让刚立的通则失去可机械检查性。

### 🔵 可推演（不进 interview）

- **`Realm` 枚举确实未登记**：全库 grep `enum Realm` 只命中本草稿；而 `ChapterCompleted(string, int, Realm)` 已在 `systems/architecture.md` 的 EventBus 负载表里使用。成员名 `QiRefining / FoundationEstablishment / GoldenCore / NascentSoul` 与 `terminology.md` 第 178–181 行的英文名逐字对应。（依据：`systems/architecture.md`「共享核心类型」枚举清单是全库枚举的单一登记处。）
- **存 `realm` + `level`、不存全局序**：`systems/game-progression.md` 第 32–41 行明写全局序 = 境界基数 + 境界内层级（纯函数），且 `realm` 自身有四处独立消费点（`lifeTotal` 境界基线、寿元境界增量、境界名展示、`ChapterCompleted` 负载）。符合「重算得出来的不存」。
- **`StatusFields` 缺 `ChapterLifeSpanBudget` 行是既有缺口**：`StatusKey` 枚举已含该成员，`StatusFields` 表末显式留了 `⟨ChapterLifeSpanBudget 及其余 …… 逐条补⟩`，而「启动期断言表覆盖 `StatusKey` 全部成员」是硬要求 ⇒ 补 `(Int, 0, null)` 是必然推论。
- **§1 的索引表不触第二权威硬边界**：`systems/common-properties.md` 第 136 行的硬边界针对「同一字段名在**两份及以上 `common-properties.md`** 中同时出现枚举成员表 / 数值 code / 完整校验语义」；只有形态列、落在 `_index.md` 的索引表不命中。
- **`id` / `characterDataId` / `defeatReason` 三格确有消费方且重算不出**：四个 EventBus 负载（`CycleStarted` / `EventResolved` / `ChapterCompleted` / `CharacterDefeated`）全部以 `string CharacterId` 开头；`PlotNodeData.CharacterIds` 需要可比对的模板 id；`DefeatReason` 由 `ResourceElements` 的 `DepletionDefeat` 列产出、`CharacterDefeated` 负载携带，却无任何字段保存。
- **四类持有条目取 `readonly record struct`**：与 `StatusAssignment` / `DeckChangeElement` / `ChangeElement` 同款（字段少、进 diff、要落存档）；`PastEventEntry`（13 字段）与 `EventOption`（`sealed record`，`future-event-service.md` 第 198 行给了理由）取引用型。判据既有，直接沿用。
- **`technique` / `looseCard` 两格直接来自 `deck/_index.md` 推论 ③**（「存档存 build 层：功法 `Id` + 层数 列表 + 游离牌 `Id` 列表」）；`looseCard` 取裸 `string` 多重集，因为 `CardInstance` 运行态只存在于战斗内（推论 ②「一场战斗内卡牌是闭集」）。
- **`schemaVersion` 不进 Profile**：`SyncEnvelope` / `ProfilePayload` / `ProfileSnapshot` 三处既有形态已一致地把它放在信封层；理由与 `baseRevision` 逐字相同（版本号塞进被版本化的对象会自指）。
- **`contentVersion` 的改动面比草稿写的窄（事实订正）**：`systems/services/content-service.md` 的双 `contentVersion` 表**只有「语义」列、没有类型列**（第 136–139 行），其门面属性第 259 行已是 `int ContentVersion { get; }`。⇒ 裁决 ② 的实际改写点是 **`systems/character-profile/_index.md` 第 108–109 行的类型列一处**，不是草稿说的「两处字段表」。
- **`ux/screen-flow.md` 主菜单五入口的字段列已全部填满**（第 13–19 行五格皆有字段），草稿「问题」节第 2 条已过时。但该表第 16 行写 `List<PlayerPower>`、第 17 行写 `achievement: List<Achievement>` ⇒ 单数通则落地后此表须同步为新字段名（见 §3）。
- **客户端库内当前零处复数集合字段**：grep `playerPowers|playerItems|characterProfiles|characterDiffs` 在 `systems/` + `ux/` 下无命中 ⇒ 裁决 ④ 在客户端侧是**纯新增字段的命名选择**，不产生任何既有文档的改名成本（成本全在对侧契约）。
- **`GameSetting` 只定形态（具名类、非字典）**，两条待决项（清单 · 设备本地 vs 账号级切分）一条都不移出；总表里 `gameSetting` 行的「写入通道」列留 ⟨待⟩，与 `StatusFields` / `CostKey` 表既有的 ⟨待定⟩ 占位形态一致，可接受。

### ✅ 用户已在评审中定下（照定案处理，不进 interview）

- ① `chapterRetry` 三字段 → `Ch1RetryUsed` / `Ch2RetryUsed` / `Ch3RetryUsed`；`player-profile/_index.md` 的命名硬约定表**补一行**「规则层的『数量』用 `Used` 后缀」。
- ② `contentVersion` 统一为 `int`（改存档侧；实际改写点见 🔵 的事实订正）。
- ③ `currentMana` 移入 `activeCombat`，`Status` 只留 `manaLimit`（`[采纳推荐 — 待复核]`）。
- ④ 集合字段名**单数**，改后端契约白名单；破坏性变更，bump `schemaVersion` + 两侧同批改（⚠ 逆推荐项，用户已知悉并推翻原论据，不再复议**该轴本身**——但其**适用边界**与**条目键名**两点未被该裁决覆盖，见 🔴-1 / 🔴-2）。
- ⑤ 六 Codex 元素取 `CodexEntry` record，首批只一个 `Id`。
- ⑥ 两份 `_index.md` 各补一张只有形态列的总表（`[采纳推荐 — 待复核]`）。
- 连带：本草稿的 schema bump 与同批 S2–S5 的 bump **合并为同一次**、同一段迁移说明（由 orchestrator 编排）。

## 3. 拟改动文档清单

| 文档 | 拟新增/修改的要点 |
|---|---|
| `systems/character-profile/_index.md` | ① 新增「`CharacterProfile` 完整字段表」（列：`#` / 字段 / 类型 / 写入通道 / 权威回链，**无语义列**），22 行：`id` `characterDataId` `status` `defeatReason` `chapter` `realm` `level` `Status` `jade` `technique` `looseCard` `magicPack` `characterPower` `disabledAbility` `pastEvent` `plotKeyPoint` `activeCombat` `eventOption`⟨形状归 S3⟩ `chapterRetry` `rng` `startContentVersion` `lastContentVersion` |
| 同上 | ② 子表「`CharacterProfile.Status`」：`lifeTotal`(int/`Elements`·`CostKey.LifeTotal`) `manaLimit`(int/`CostKey.ManaLimit`) `experiencePoint`(int/`CostKey.Experience`) `faith`(int/`CostKey.Faith`) `maleficQi`(int/`CostKey.MaleficQi`) `FaithBand`(sbyte/`StatusChanges`) `MaleficQiBand`(sbyte) `LifeSpanBand`(sbyte) `ChapterLifeSpanBudget`(int) `CurrentLocationId`(string) `LocationEventCount`(int) `lifeSpan`(int/`CostKey.LifeSpan`) —— **`currentMana` 不在其中**（裁决 ③） |
| 同上 | ③ 新字段五条正文：`string Id`（客户端生成 GUID · "N" 格式 32 位小写十六进制无连字符；不向后端申请，理由 = 轮回开始是自动存档点非阻塞点）· `string CharacterDataId`（指向 `CharacterData.Id`，写一次不变；解析不到 → **必需缺失** → `PushError` 带 `characterId` + `characterDataId`）· `DefeatReason? DefeatReason`（`null ⟺ status != Defeated`；**不设 `None` 哨兵**；两条读档校验皆 `PushWarning`）· `IReadOnlyList<TechniqueEntry> technique` + `public readonly record struct TechniqueEntry(string TechniqueId, int Tier)`（`Tier >= 1`，越界 → `PushError`）· `IReadOnlyList<string> looseCard`（多重集，元素解析不到 → `PushError`） |
| 同上 | ④ 第 108–109 行类型列 `string` → **`int`**（裁决 ②）；⑤ 第 116–125 行 rng schema 片段：`CycleSeed` → `cycleSeed`，`streams` → `stream`（**两点均待 interview 确认**，见 🟠-1 / 🔴-1）；⑥ 第 14 行「大局骨架」那条与第 32 行 `Status` 括注中的 `currentMana` 删除 |
| 同上 | ⑦「待决问题」节：「`CharacterProfile` 字段结构细节」收窄为**只剩「隐藏属性完整清单是否还有第四项」**；「角色模板池的形态」保留不动 |
| `systems/player-profile/_index.md` | ① 新增「`PlayerProfile` 完整字段表」15 行：`accountInfo`(AccountInfo/规则/—) `characterProfile`(`IReadOnlyList<CharacterProfile>`/规则/—) `playerPower`(`IReadOnlyList<PlayerPower>`/规则·透明段/`AbilityElements`) `playerItem`(同/规则/`AbilityElements`) `achievement`(规则/AchievementManager) 六个 Codex 字段 `statistics`(PlayerStatistics/**统计**/`Stats`) `playerPowerFragment`(规则·透明段/`Elements`) `entitlement`(规则·透明段·后端写/`Elements`) `gameSetting`(—/⟨待⟩) —— **字段名一律单数**（裁决 ④） |
| 同上 | ② 六个 Codex 具名字段 + 元素类型：`IReadOnlyList<CodexEntry> enemyCodex / characterPowerCodex / playerPowerCodex / characterItemCodex / playerItemCodex / locationCodex` + `public readonly record struct CodexEntry(string Id)`；不落字典、不落裸 `string`、**不需要 `IsUnlocked`**（解锁 = 一次性全量写入）；读档 `Id` 解析不到 → **可选缺失** → `PushWarning` + 保留条目 |
| 同上 | ③ 四类持有条目 record：`CharacterItem(string ItemId, int Charges, bool Status, Source SourceCode)` · `CharacterPower(string PowerId, bool Status, Source SourceCode)` · `PlayerItem(string ItemId, int Charges, bool Status, Source SourceCode)` · `PlayerPower(string PowerId, bool Status, Source SourceCode)` —— **`PowerId`/`ItemId` 的取名取决于 🔴-2**；`Charges` 允许 `0`（储物袋「已耗尽」筛选 chip 读它）、无限法宝恒为 `-1` |
| 同上 | ④ **命名通则新增一条**：「集合字段名恒为单数；类型名亦恒为单数」——并写明它是**跨边界通则**（客户端字段名经 camelCase 策略机械映射为 JSON path，透明段字段改名 = 破坏性契约变更）。适用边界按 🔴-1 的裁决落笔 |
| 同上 | ⑤ 命名硬约定表**补一行**：规则字段层的「数量」用后缀 **`Used`**（裁决 ①）；表内既有两行（`Ordinal` ⇒ 规则层位置 / `Total`·`Count` ⇒ 统计层数量）不动 |
| 同上 | ⑥「待决问题」节：「各账号级字段 schema 未定」收窄为**只剩 `achievement` 条目 schema + `GameSetting` 清单 + `StatKey` 完整成员** |
| `systems/architecture.md` | ① 共享核心类型枚举清单新增 `public enum Realm { QiRefining, FoundationEstablishment, GoldenCore, NascentSoul }`；② `StatusFields` 注释块补一行 `ChapterLifeSpanBudget → (Int, 0, null)` 并删除 `⟨ChapterLifeSpanBudget 及…⟩` 占位的前半；③ `CostKey` 枚举补 `Experience`（并按 🟠-3 的裁决决定是否补 `Faith` / `MaleficQi`） |
| `systems/services/profile-service.md` | ① `ResourceElements` 补行：`Experience → (0, null, null, null, null)`（`CostModifier` 恒 `null` = 不存在消耗向；`GainModifier` 取 `null` = 缺省豁免）；`Faith` / `MaleficQi → (0, 100, null, null, null)`（两个修正列留空，理由：一条法则能伪造隐藏属性即等于伪造整条剧本线的触发条件）—— **均待 🟠-3**；② 「待决问题」的「道心 / 煞气是否列入 `CostKey`（轻）」若落笔则移出；「元进程字段结构」条收窄 |
| `systems/services/sync-service.md` | schema 版本一节（第 259 行邻域）追加本次 bump 的字段清单：`CharacterProfile` 五个新字段 + `PlayerProfile` 六 Codex + 四类持有条目形态 + `contentVersion` 类型改 `int` + 单数改名；**与 S2–S5 的 bump 合并为同一次**（orchestrator 统一措辞）；老档补默认值口径：集合 → 空列表 / `DefeatReason?` → null / `ChapterRetry` → 全 0 |
| `systems/services/combat-service.md` | 第 130 行参战方字段行的括注改写：`manaLimit`（战斗内不变，落它只为读档自洽）· `currentMana`（回合内消耗量，决策点存档必须恢复）——待 🟠-2 |
| `systems/services/life-cycle-service.md` | 第 10 行 `CharacterProfile` 字段罗列中的 `currentMana / manaLimit` → `manaLimit`；该行整体改为**回链** `systems/character-profile/_index.md` 的新总表，不再复述字段清单（消除第二权威） |
| `systems/player-profile/game-setting.md` | 补一句形态：`GameSetting` 是**具名类，不是字典 / 键值表**（同 `CapabilityFlag` 用 `enum` 而非字符串 key、`PlayerEntitlement` 用具名字段）；**两条待决项一条都不移出**，并注明落笔顺序 = 先答「设备本地项 vs 账号级项的切分」再一次性定清单 |
| `systems/player-profile/achievement/_index.md` | **第 9 行必须改写**：现文「若日后全库统一把集合字段改为**复数**风格，本字段随那次统一一并改」——裁决 ④ 的方向与之相反，须改为「集合字段名恒为单数（全库通则），本字段已合规」。**（plan.md 的写入面表未列此文件）** |
| `ux/screen-flow.md` | 第 13–19 行主菜单表的「对应 PlayerProfile 字段」列按单数通则同步：`List<PlayerPower>` → `playerPower`、`achievement: List<Achievement>` → `achievement`、`entitlement: PlayerEntitlement` → `entitlement`。**（plan.md 未列此文件）** |
| ⟨对侧库 · 仅当 🔴-3 取 (a)⟩ `backend-design-documents/contracts/profile-sync.md` | §5 白名单：`/playerPowers[*]/id` → `/playerPower[*]/id`（或 `/powerId`，见 🔴-2）· `/playerPowers[*]/sourceCode` → `/playerPower[*]/sourceCode` · 排除项 `/playerPowers[*]/status` → `/playerPower[*]/status` · `/playerItems` → `/playerItem`；§7 复算伪码的字段引用随之改名（**算法与 §6a 的 8 组向量一字不动**）；补一句「§5 内集合字段恒为单数」；`schemaVersion` bump；写明本次改名成立的三个前提（线上无数据 · 两侧同批 · 一次性不设兼容期） |

**不落笔的格（如实登记为待答，不臆造形状）：** `eventOption` 的形状（S3）· `looseCard` 的入组通道（S4）· `plotKeyPoint` 的集合型载体形状（S4）· `activeCombat` 内的 `EnemyInstance` 形态（S5）· `achievement` 条目 schema · `GameSetting` 清单 · `Status` 第四个隐藏属性 · `characterDataId` 的取值面（角色模板池）· 六 Codex 的计数字段。

## 4. 拟移出的 open-questions 条目

- **`open-questions/` 各分片文件中无对应条目可移出**——「Profile 字段 schema」这一问只登记在 ① `open-questions.md` 的「derive 就绪度」表（**由 `/assess-derive-readiness` 独占，本技能第 10 步禁止触碰**）与 ② 各主题文档自己的「待决问题」小节。
- 主题文档「待决问题」的收窄（不是移出分片）：`character-profile/_index.md`「字段结构细节」→ 只剩隐藏属性第四项 · `player-profile/_index.md`「各账号级字段 schema」→ 只剩三项 · `profile-service.md`「元进程字段结构」→ 收窄；若 🟠-3 取 (a)，`profile-service.md`「道心 / 煞气是否列入 `CostKey`（轻）」**整条移出**并记入 answer log。
- answer log 文件名（供 orchestrator 统一编排）：`answer-logs/log-profile-field-schema.md`（`solution-draft-<slug>` ⇒ `log-<slug>`）。

## 5. 拟新增的 open-questions 条目

- `open-questions/05-service-contracts.md`：**「集合字段单数通则的适用边界」**——若 🔴-1 只答定 Profile 面而把运行时 / 内容侧属性留待后议。
- `open-questions/cross-boundary.md`：**「透明路径复数 → 单数改名须两侧同批落笔」**承接项——若 🔴-3 取 (c)（客户端先落、后端库只留痕），须明写「未同批 ⇒ 后端复算按 §7a 不报错、只产生风控噪声」这一症状。取 (a) 则本条不新增。
- `open-questions/06-meta-progression.md`：**「`characterDataId` 的取值面」**——角色模板池形态已在册（第 152 行），本次只需在该条上补一句「字段形态已定、只剩内容侧取值面」，不新开条目。
- 无需新增：六 Codex 的计数字段（已在 `07-codex-monetization.md` 与 `codex/common-properties.md` 在册）· `GameSetting` 两条（已在 `game-setting.md` 在册）。

## 6. 越界发现（不处理，仅记录）

1. **分片 C 的当前批载体命名已被本分片的裁决反转。** `solution-draft-event-option-derived-persistence.md` 正文用 `CharacterProfile.eventOptions`（复数），其评审裁决 ⑤ 明写「由 S1 的裁决统一覆盖 ⇒ 应定名 `eventOption`（单数）」。plan.md 的波次顺序（D→A→B→C→E）已满足「A 先立通则」，但 **C 的 Phase B 必须按单数落笔**；另 C 还要新增 `activeEvent`（可空块），本分片的 `CharacterProfile` 总表须为这两格预留行位——建议 A 落表时**直接写入 `eventOption` 与 `activeEvent` 两行、形状列填 ⟨归 S3⟩**，避免 C 回头改表。
2. **plan.md 的写入面推算表遗漏本分片的四份文档：** `systems/services/combat-service.md`（裁决 ③ 连带）· `systems/services/life-cycle-service.md`（`currentMana` 措辞 + 字段罗列改回链；**与分片 B、C 相交**）· `systems/player-profile/achievement/_index.md`（第 9 行的「未来统一为复数」预言与裁决 ④ 相反，必须改写）· `ux/screen-flow.md`（主菜单表字段列）。Phase B 已是全串行，不构成并行冲突，但表应订正。
3. **分片 D 可能同批改动 `CostKey` / `ProfileChangeSpec` 的列结构**（element 层载体缺口），与本分片 🟠-3 的两条 `ResourceElements` 补行落在同一处代码块（`systems/architecture.md` 共享核心类型 + `profile-service.md`）。D 先于 A 落笔（plan 波次 1），A 需读 D 的产出后再写。
4. **后端库 `contracts/profile-sync.md` §5 / §7 的改名不在本批范围**，且对侧草稿自身尚有两项待用户裁决（切换时序 A/B · 残卷 `ordinal` 是否确按递增后的值实现）。本分片不写后端库任何文件；是否纳入本批见 🔴-3。
