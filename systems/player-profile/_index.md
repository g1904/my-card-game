# player-profile

> 玩家信息 / **PlayerProfile** —— 账号级主档，跨轮回持久，持有一组 CharacterProfile 及账号级元数据。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **PlayerProfile = 账号级主档（元进程层）。** 跨轮回持久，持有 `List<CharacterProfile>`（单次轮回状态见 `../character-profile/`）及账号级元数据。与「强制在线 · 云端权威」一致——PlayerProfile 是云端权威主档。
- **PlayerProfile 的完整字段表。** 本表**只有形态列**（字段 / 类型 / 层 / 写入通道 / 权威）——语义、取值域与读档校验一律留在权威列所指的文档里。**层** = 规则字段层 / 统计计数层（判据见下方分层通则）；**写入通道** = 该字段经 `ProfileChangeSpec` 的哪一列写入。`PlayerPower` / `PlayerItem` / `Achievement` / Codex 是**独立于任何单次轮回**的账号级解锁、成就与收集。

  | # | 字段 | 类型 | 层 | 写入通道 | 权威 |
  |---|---|---|---|---|---|
  | 1 | `accountInfo` | `AccountInfo`（5 字段） | 规则 | —（后端写 `AccountSeed` / `CreatedAtUtc` / `Identities`，无客户端通道、**受回声约束**；客户端写 `Nickname`） | `account-info.md` |
  | 2 | `characterProfile` | `IReadOnlyList<CharacterProfile>` | 规则 | — | `../character-profile/_index.md` |
  | 3 | `playerPower` | `IReadOnlyList<PlayerPower>` | 规则（透明段） | `AbilityElements` | `player-power/_index.md` |
  | 4 | `playerItem` | `IReadOnlyList<PlayerItem>` | 规则 | `AbilityElements`（持有）+ `ItemElements`（次数） | `player-item/_index.md` |
  | 5 | `achievement` | `IReadOnlyList<Achievement>` | 规则 | AchievementManager | `achievement/_index.md` |
  | 6 | `enemyCodex` | `IReadOnlyList<CodexEntry>` | 规则 | `CodexElements` | `codex/_index.md` |
  | 7 | `characterPowerCodex` | `IReadOnlyList<CodexEntry>` | 规则 | `CodexElements` | `codex/_index.md` |
  | 8 | `playerPowerCodex` | `IReadOnlyList<CodexEntry>` | 规则 | `CodexElements` | `codex/_index.md` |
  | 9 | `characterItemCodex` | `IReadOnlyList<CodexEntry>` | 规则 | `CodexElements` | `codex/_index.md` |
  | 10 | `playerItemCodex` | `IReadOnlyList<CodexEntry>` | 规则 | `CodexElements` | `codex/_index.md` |
  | 11 | `locationCodex` | `IReadOnlyList<CodexEntry>` | 规则 | `CodexElements` | `codex/_index.md` |
  | 12 | `techniqueCodex` | `IReadOnlyList<CodexEntry>` | 规则 | `CodexElements` | `codex/_index.md` |
  | 13 | `statistics` | `PlayerStatistics`（2 字段） | **统计** | `Stats`（`StatDelta`，2 个 `StatKey`） | 本文档 |
  | 14 | `playerPowerFragment` | `PlayerPowerFragment`（7 字段） | 规则（透明段） | `Elements`（7 个 `CostKey`） | 本文档 |
  | 15 | `entitlement` | `PlayerEntitlement`（2 字段） | 规则（透明段） | `Elements`（客户端置值 `BundleRedeemedOrdinal`）；`BundleGrantOrdinal` 由后端写、经 pull 下行，无客户端通道、**受回声约束** | 本文档 · `systems/monetization.md` |
  | 16 | `gameSetting` | `GameSetting`（4 字段） | —（既不被规则读，也不是统计计数） | `SettingChanges` | `game-setting.md` |

  - **不进 `PlayerProfile` 的三样：** `baseRevision` / `revision`（传输层元数据）· `schemaVersion`（存档 / 传输的信封字段，见 `systems/services/sync-service.md`）。**三者共有的排除判据是「进 Profile 会自指」**——每次 push 都会改动被 push 的那样东西，且版本号会被卷进它自己的迁移路径。
    - **这是一条精确判据，不是「传输层元数据一律不进」。** 别的东西不进 Profile 可以有别的理由，那些理由各自记在自己的文档里，不并进本条——放宽成一条笼统的排除通则，会让「自指」这个可机械核对的判断退化为要读上下文。**设备维度的标识（`deviceId`）不进 Profile 走的就是另一条理由**：Profile 是账号级、云端权威、跨设备一致的主档，A 设备会读到 B 设备写的值，多设备裁决当场失效；它不自指，落点与理由见 `systems/services/account-service.md`。
  - **「受回声约束」标注的判据是机械的，不逐字段临时判：** 某顶层键内的某条 path 受约束 ⟺ 它在后端写入字段封闭表内（权威在 `backend-design-documents/contracts/profile-sync.md`，本表不复制）。上行组装该键时这些路径只能原样回声最近一次 pull 的值，且不参与读档钳制 / 缺省补齐 / 格式归一化；通则与 push 前自检见 `systems/services/sync-service.md`。
    - **`AccountInfo.AccountId` 虽由后端产生，却不在那张封闭表内、不受回声约束。** 「写入方是后端」与「受回声约束」是两件事——按前者反推后者会导出一份多一行的错误清单，而清单的每一次偏差都正是这条纪律要防的漂移。
  - 表随字段增长、需要维护；它是索引 + 回链形态，与 `_index.md` 的既有职责一致。
- **子系统的文件形态。** **`player-item/`、`player-power/`、`achievement/`、`codex/` 各成文件夹**（有子结构，`_index.md` + `common-properties.md`）；**`account-info.md`、`game-setting.md` 结构轻，各为独立 markdown**。
- **图鉴族归本层，共七个。** 图鉴是**跨轮回持久的知识资产**，故归账号级而非角色级；它与战斗内敌人回合的逐步执行呈现按「事前知识 vs 事中情报」分层。除 **EnemyCodex** 外还有 **CharacterPowerCodex / PlayerPowerCodex / CharacterItemCodex / PlayerItemCodex / LocationCodex / TechniqueCodex**（**LocationCodex 是玩家不可见的 `locationMap` 唯一的显影通道，「去过即记」**；**TechniqueCodex 按 `CultivationTechnique` 的 `Id` 索引，敌我共用同一套功法条目**），七者形状相同（账号级、按 `Id` 索引、静态文案、存档只记解锁状态），合为一族。**它是元进程的第三条积累线**（与 PlayerPower 的「能力」、Achievement 的「成就」并列）。见 `codex/`。
- **七个 Codex 落七个具名字段，条目取 record。**

  ```csharp
  IReadOnlyList<CodexEntry> enemyCodex;
  IReadOnlyList<CodexEntry> characterPowerCodex;
  IReadOnlyList<CodexEntry> playerPowerCodex;
  IReadOnlyList<CodexEntry> characterItemCodex;
  IReadOnlyList<CodexEntry> playerItemCodex;
  IReadOnlyList<CodexEntry> locationCodex;
  IReadOnlyList<CodexEntry> techniqueCodex;

  public readonly record struct CodexEntry(string Id);   // 首批只有解锁这一态
  ```

  - **不落成 `Dictionary<CodexKind, …>`**：增删一本图鉴本就要加一个 UI 页与一条收录触发，字典只换来一层查找与一处可空——与 `chapterRetry` 拒绝字典的判据逐字相同。**也不落成单表 + `Kind` 字段**：各本的呈现形态确定不同（LocationCodex 是一张逐步显影的图，其余各本是列表 / 网格），单表会让每个消费点先按 `Kind` 过滤一遍。
  - **不落成裸 `IReadOnlyList<string>`，尽管确实只有一个 `Id`。** 用 `CodexEntry` 包一层，日后加一格是在 record 上加字段（老档补默认值、零迁移），用裸 `string` 则每个 Codex 字段的**元素形状**都从标量变成对象，对 diff 的序列化形态是一次真实的破坏性变更。**加法窗口在写下第一批存档时关闭**，与 `LocalizedText` / `DrawPool<T>` 是同一类窗口判断。**代价明写：每条多一层 JSON 对象嵌套。**
  - **首批一格计数字段都不加**，正因为加一格是零迁移的——包装层已经把加法窗口买下了，预先加没有收益，而计数是纯读数、与规则字段层混装。逐条目计数因此不可得，读数类需求的落点是 `PlayerStatistics` 的聚合项。完整依据与代价见 `codex/common-properties.md`。
  - **解锁 = 一次性全量写入 ⇒ 条目存在 ⟺ 已解锁，不需要 `IsUnlocked` 布尔。**
  - **`LocationCodex` 的连边不落存档**——连边随 location 内容条目静态给出，存档形态仍是 id 集合。
  - 读档校验：`Id` 经 `ContentRegistry` 解析不到 → **可选缺失** → `PushWarning` + 保留条目（图鉴是历史知识，一条读不出的旧条目不该阻断登录）。
- **四类持有条目的 record 形态。** 四者共有 `SourceCode`（授予来源，权威见 `systems/common-properties.md`），`Status` 归 power 两类与 item 两类共有的启用开关，`Charges` 只归 item 两类：

  ```csharp
  // 轮回级（落 CharacterProfile）
  public readonly record struct CharacterItem (string ItemId,  int Charges, bool Status, Source SourceCode);
  public readonly record struct CharacterPower(string PowerId,              bool Status, Source SourceCode);
  // 账号级（落 PlayerProfile）
  public readonly record struct PlayerItem    (string ItemId,  int Charges, bool Status, Source SourceCode);
  public readonly record struct PlayerPower   (string PowerId,              bool Status, Source SourceCode);
  ```

  - **条目键名取 `<Kind>Id` 而非 `Id`**：`Id` 在本库指「本条目自身的稳定 Id」，而这一格指向的是内容条目；`DisabledAbilityEntry.AbilityId` / `PlotKeyPoint.ArcId` / `TechniqueEntry.TechniqueId` 已是同一形态，四类条目由此命名全族一致。
  - **`Charges` 只在 item 两类上**：内容侧 `ItemData.Charges` 是上限 / 初值，持有条目上的是**剩余次数**。允许取 `0`（储物袋的「已耗尽」筛选 chip 读它），无限法宝恒为 `-1`。
  - **`Status` 落 `bool`（true = 启用）而非枚举**：它是二值开关；「本轮回禁用」是第三维、已落 `CharacterProfile.disabledAbility`，不挤进这一格。
  - **`magicPack` 的元素是「一份实例」而非「一条 Id 一行」**：同 `ItemId` 多份 = 多个元素，按 `ItemId` 堆叠是呈现层聚合。
  - **四者取 `readonly record struct`**（字段少、要落存档且进 diff），与 `StatusAssignment` / `DeckChangeElement` 同款。
- **集合字段名恒为单数，且这是一条跨边界通则（承重）。** 集合字段名与类型名**一律单数**——`pastEvent` / `disabledAbility` / `achievement` / `playerPower` / `characterProfile` 同形。
  - **适用边界 = 两层 Profile 及其子对象的存档字段名。** 不受约束的两类：diff 报文的结构键（后端自己解析的信封结构，不经字段映射产生）；运行时与内容侧的集合属性（如 `EventOptionBatch.Options`、`PlotNodeData.CharacterIds`）。
  - **为什么是跨边界的：** 存档字段的 C# 名经 camelCase 单点策略**机械映射**为 JSON path，故 Profile 透明段字段改名 = 破坏性契约变更，须 bump `schemaVersion` 并与后端同批改。透明路径白名单在 `backend-design-documents/contracts/profile-sync.md` §5，本库不复制。
  - **可机械检查是这条通则的全部价值**：一旦开一个复数例外，「这个字段该不该是单数」就要逐个读上下文，通则退化为习惯。持有一组 `CharacterProfile` 的字段名 `characterProfile` 与类型名仅首字母之差，这是被接受的代价。
  - **改名的成立前提有三条**（它们同时成立才允许一次性切换、不设兼容期）：线上无真实账号数据 · 两侧同批落笔 · 一次性不留双读期。
- **账号级统计计数 = `PlayerStatistics` 具名类，首批两项。** 与 `Achievement` 相邻但不同——**成就是有奖励的里程碑，统计计数是纯读数**；它与 `CharacterProfile.chapterRetry` 一类规则字段**口径不同**：角色级参与闸门判定，**账号级不参与任何规则判定，只被读来看**。

  ```csharp
  public sealed class PlayerStatistics          // 纯读数层：绝不被任何规则 / 闸门 / 幂等键读取
  {
      public int TotalCyclesCompleted { get; }  // 通关（三篇章全通 · 抵达元婴）的轮回数
      public int TotalCyclesDefeated  { get; }  // 以 defeated 收场的轮回数（三种 DefeatReason 合计）
  }
  ```

  - **为什么是一个具名类而不是散挂字段：一个类型就是一道可见的边界。** 两层通则里最关键的一条是「统计计数层绝不可被规则读取」，而散挂字段在语法上无法与规则字段区分；收进 `PlayerStatistics` 之后，「有人在闸门判定里读了统计」在 review 时是一眼可见的 `Statistics.` 前缀——这把该纪律从纪律阶梯第 4 级（评审清单）抬到接近第 3 级。
  - **命名合规**：两项均为 `Total` 前缀 ⇒ 统计层；**类内禁用 `Ordinal` 后缀**（可机械检查）。
  - **`StatKey` 的成员名 = 字段名逐字，成员清单 = 首批两项**（`TotalCyclesCompleted` / `TotalCyclesDefeated`）。`Total` 前缀让「一个裸 key 名属于哪一层」保持可机械判定——一个既无 `Total` 也无 `Count` 的 key 名恰好落在词缀约定管不着的形态里，那会把这条约定降级回「要读上下文」，正是它明写要避免的降级。逐字对齐还使下方那条双向覆盖断言写得出来。
  - **新增一个统计项恰好三步：** ① `PlayerStatistics` 加一个只读字段（名必须带 `Total` 前缀或 `Count` 后缀）→ ② `StatKey` 加一个**同名**成员 → ③ 无需迁移（老档缺字段 → 0，宽松同步口径）。
  - **明确不给统计族建 `StatFields` 配表（承重）。** 与 `ResourceElements` 对照，六列逐列为空：统计层**不钳制**（读档越界只告警不修复）· **不构成任何终态** · **恒不走 modifier pipeline**（一条法则能改写统计数字）· 只有一种施加方式（`StatDelta` 是纯自增，无 `Op` 维度）。**建表等于建一张全空表**，而「按内容建，不按对称建」。反过来说，**「有没有配表」本身就是两族的第一条可机械核对的分野**——一个 key 若需要说清取值域 / 终态 / 修正准入，它按定义属于资源族。
  - **配表的替代品是一条启动期双向覆盖断言：** `StatKey` 的每个成员在 `PlayerStatistics` 上有同名字段，且每个字段有同名成员。成本是一行反射遍历、只在 `#if DEBUG` 生效，与「表覆盖 `CostKey` 全部成员」同档（纪律阶梯第 3 级）。见 `systems/services/profile-service.md`。
  - **未知 `StatKey` 走宽松口径**（`PushWarning` + 跳过该条，不影响同批其余变更），与资源族「缺行 = `PushError` + 整批拒绝」形成**两族第二条可机械核对的分野**。
  - **写入时机**：轮回结束时随 `SavePointReason.CycleEnded` / 角色 `defeated` 那一次 `TryApply` 带上 `StatDelta(+1)`，与规则字段**同批、同事务**。字段全部只读，**唯一写入路径是 `StatDelta` 经 `TryApply`**，不提供 setter。
  - **首批就这两项。** 统计层新增字段的成本近乎为零（宽松同步、缺字段补默认值、零迁移、后端零配合），故首批清单的价值在于**小而无歧义**。**代价明写：`TotalCyclesDefeated` 不区分篇章也不区分 `DefeatReason`，回答不了「你在炼气段重开了多少次」**——「篇章重试的账号级累计」不在首批（`chapterRetry` 在 ch1 恒为 0 是一个**展示需求**，需要时纯加法补一项即可）。
  - **不做按 `DefeatReason` 的分解**（首批）：分布是**平衡诊断**需求，正确落点是后端聚合（push 信封已带 `contentVersion` / `appVersion`），不是玩家存档里的三个计数器。
  - **schema 影响**：老档缺字段 → 全 0（无损）。宽松同步口径的五条具体形态见 `systems/services/sync-service.md`。
- **`PlayerPowerFragment` = `PlayerProfile` 上的具名小类，参与规则判定、不并入统计计数。** 道统残卷（Finale 失败累积、Finale 通过掷定的 PlayerPower 掉落概率，机制见 `player-power/_index.md`）的状态载体：

  | 字段 | 类型 | 语义 | 默认 |
  |------|------|------|------|
  | `Accumulated` | `int` | 累积概率，**万分比整数** 0–10000。**不用 `float`**：存档 / 跨端一致性 + 后端可复算，且避免浮点比较 | `0` |
  | `FinaleWinOrdinal` | `int` | 账号级 Finale **通过**序号，单调递增、不清零（失败不自增；勉强通过与碾压通过同等看待）；同时是掷骰的**幂等键** | `0` |
  | `Ch1FirstWinDone` / `Ch2FirstWinDone` / `Ch3FirstWinDone` | `bool` | 各篇章 Finale 是否已首次通过（首胜 100% 的判定源；**仅通过置位**） | `false` |
  | `LastRoll` | `int` | 最近一次 Finale 通过掷骰的原始值，`[0, 9999]`。**供后端逐位复算比对**——它自算 `roll'` 并校验相等，抓种子篡改 / 序号刷 / 换设备重掷 | `0` |
  | `LastEffectiveChance` | `int` | 那一次掷骰当刻的生效概率，万分比 `[0, 10000]`。供后端做「未命中却新增 `FinaleWin` 法则 ⇒ 异常」的单向蕴含校验 | `0` |

  - **两条承重的写入约定（缺任一条即在正常账号上触发后端风控误报）：**
    - **每一次 Finale 通过都掷这一骰并写 `LastRoll`，即使当次不发放。** 「未拥有法则数 = 0 ⇒ 静默停摆」时 `FinaleWinOrdinal` 照常 `+1`（它是通过序号），若此时不写 `LastRoll`，后端的复算比对会稳定失败。**掷骰本身零成本**，只是结果不被消费。
    - **首胜时 `LastEffectiveChance` 写 `10000`。** 首胜 100% 优先于闸门，那一次的生效概率就是 100%，如实记录即可——**首胜因此不是校验的例外**。
  - **两个字段都进透明段**（JSON path `/playerPowerFragment/lastRoll` · `/lastEffectiveChance`），受路径稳定性纪律约束，见 `systems/services/sync-service.md`。**不存掷骰历史列表**：CAS 保证上行严格串行、每次 Finale 通过必然产生一次 push，「最近一次」两个字段即等价；列表会随账号年龄单调增长，正是 `pastEvent` 已被立护栏防范的那种形态。
  - **读档校验**：两者越界 → `GD.PushWarning` + 钳制到各自区间；**不由历史重建**（与三个首胜布尔同口径）。

  - **不并入账号级统计计数容器。** 判据是**参与规则判定的字段与纯读数的统计计数分属两层**。残卷概率直接决定「发不发一条法则」，是规则输入，与 `CharacterProfile.chapterRetry` 同性质；混进统计计数会让「统计可走宽松同步口径」这条便利判断失效。
  - **三个首胜标记落具名布尔**，沿用 `chapterRetry` 的既定形态（篇章数是固定的游戏结构，不是可扩展列表），不用字典 / 索引数组。
  - **`x` 不落字段**——它是对 `List<PlayerPower>` 的一次**带过滤计数**（**只数 `SourceCode == Source.FinaleWin` 的条目**），落字段即制造第二份真值（与「`CapabilitiesChanged` 空负载、订阅者自行重查」同一条纪律）。
  - **读档校验：** `Accumulated` 落在 `[0, 10000]` 外 → `GD.PushWarning` + 钳制；三个首胜布尔与通关史不一致时**以布尔为准**（它是权威，不由通关史重建）。
  - **schema 影响：** 本类 7 个字段 + `AccountInfo.AccountSeed` ⇒ 存档 schema 版本 bump。迁移分两路：**客户端写入的字段缺失 → 以默认值补齐**（无损）；**回声路径缺失（含 `AccountInfo.AccountSeed`）→ 走必需缺失处置**（`GD.PushError` + 该顶层键本次不进 diff + 触发一次 pull 重取权威值），**不补默认值**——补一个客户端造出来的值去回声，会在正常老档上稳定把上行打成整批拒绝。见 `systems/services/sync-service.md` 与 `account-info.md`。
- **账号级字段分两层，判据是「它有没有被规则读」（通则）。** `chapterRetry` 的账号级累计与 `PlayerPowerFragment` 不进统计计数用的是同一条判据，它是 `PlayerProfile` 上账号级字段的通则：

  | | **规则字段层** | **统计计数层** |
  |---|---|---|
  | 判据 | 被任何判定 / 闸门 / 幂等键读取 | 只被 UI 读来展示 |
  | 例 | `PlayerPowerFragment.*`、`CharacterProfile.chapterRetry` | `PlayerStatistics.TotalCyclesCompleted` / `TotalCyclesDefeated` |
  | 同步口径 | 严格：随 profile diff 上行，**后端可复算校验** | 宽松：被篡改无玩法后果 |
  | 读档校验 | 越界钳制 + 告警；**不由历史重建** | 告警即可，不阻塞、不修复 |
  | 篡改后果 | 直接改变发不发一条法则 / 还剩几次重试 | 只是数字不好看 |

  - **依赖方向单向：** 规则字段层**可以**被统计 / UI 层读取展示；统计计数层**绝不可**被任何规则读取（防住反向的错误——拿走宽松同步口径的读数去做闸门输入）。
  - **展示不改变分层：** 被 UI 读到不会把规则字段变成统计计数。判据是「有没有被**规则**读」，不是「有没有被人看见」。
  - **合并判据（承重）：两个字段口径相近不构成合并理由。可以合并，当且仅当「语义 + 同步口径 + 篡改后果」三者全同；跨层的两个字段永远不满足这条。** 真实风险不是有人故意合并，而是后来者看到两个都叫「Finale 胜利次数」的整数理所当然地去重——只有正向的「何时才允许合并」才是可被主动执行的纪律。
  - **命名硬约定（可机械检查）：** 后缀 `Ordinal` ⇒ 规则字段层（语义是「第几次」，一个**位置**，参与判定 / 幂等键，严格同步）；前缀 `Total` / 后缀 `Count` ⇒ 统计计数层（语义是「一共多少」，一个**数量**，纯读数，宽松同步）。**统计计数层禁用 `Ordinal` 后缀**——`Ordinal` 出现即意味着「有人用它当键」。当前库内只有 `FinaleWinOrdinal` 一个 `Ordinal`，零迁移成本。**规则字段层的「数量」用后缀 `Used`**（`CharacterProfile.chapterRetry` 的三个字段是首例）：规则层确实存在「用掉了几次」这类数量，而 `Ordinal` 是位置、`Count` 属统计层，两个既有词缀都不合；给它一个专属词缀，比放宽 `Count` 的单义性便宜——后者会让整条约定从「可机械检查」降级为「要读上下文」。
  - **元素键的分野就是字段分层的投影（承重）。** `CostKey` 是**规则字段层**的键（进 `ProfileChangeSpec.Elements`），`StatKey` 是**统计计数层**的键（进 `Stats`）；判据不是第二条新判据，就是上表那一条：**这个数会被规则 / 闸门 / 幂等键读吗？** 会 → `CostKey`；只被 UI 读来看 → `StatKey`。「展示不改变分层」同样原样适用——被 UI 读到不会把 `CostKey` 变成 `StatKey`。
  - **词缀约定从字段名扩到元素键名，两个枚举的成员名空间在构造上不相交（可机械检查）：**

    | | `CostKey` | `StatKey` |
    |---|---|---|
    | **必须** | 无 | 带 `Total` 前缀 **或** `Count` 后缀 |
    | **允许** | `Ordinal` 后缀（位置 / 幂等键）· `Used` 后缀（规则层的数量） | 无其他 |
    | **禁用** | `Total` 前缀 · `Count` 后缀 | `Ordinal` 后缀 · `Used` 后缀 |

    ⇒ 读到任意一个裸 key 名，**不查任何文档**即可判断它属于哪一族；当前两族成员零违例。**分野的主体保障已经在纪律阶梯第 1 级**——把一个 `StatKey` 塞进 `ChangeElement`、或把 `CostKey` 塞进 `StatDelta`，在语言层就写不出来（两个独立 `enum` × 两个独立 record struct × 两个独立列表）。词缀规则要防的是**另一件事**：新增一项时**放错枚举**；该错误在开发期即显形（缺 `ResourceElements` 行 ⇒ 启动期 `PushError`；错登为 `StatKey` ⇒ 双向覆盖断言失败），故第 3 级的启动期断言足够，无须付分析器的成本。
  - **key 名 ⟸ 标的字段在存档树上的可辨识路径的 PascalCase 拼接（约定，靠评审）。** 字段落在 profile 顶层或 `Status` 上 → 裸字段名（`SpiritStone` · `LifeSpan` · `ExperiencePoint`）；落在具名子类上 → 视裸字段名是否全局自明决定是否加容器前缀（`PowerFragmentAccumulated` 需要前缀，`Accumulated` 单独看不出是什么；`BundleRedeemedOrdinal` 本身已自明，不需要）。**「是否自明」需要人判断，故这一条停在纪律阶梯第 4 级（评审），代价如实写下**：不加对齐列的理由是命名不对齐连开发期错误都不是，是纯可读性问题，为它付一列常量加一段反射断言正是「为对称而加」；**留一条退让位**——若 `CostKey` 成员数长到 30+，性价比翻转，届时再议。
  - **`FinaleWinOrdinal` 的应用：统计侧不设「Finale 胜利数」字段**，「你渡劫成功了几次」的展示直读 `PlayerPowerFragment.FinaleWinOrdinal`。这是最强的防合并手段——让重复字段从一开始就不存在；依据是既有的单一真值纪律（落字段即制造第二份真值，而这份真值恰好是幂等键）。它计的是**渡劫通过**次数；由于通过是篇章推进的唯一出口，它**恒等于该账号累计完成的篇章数**。
  - **统计侧的「通关」= 完成整个轮回**（三篇章全通 · 抵达元婴），字段 `TotalCyclesCompleted`。一次通关贡献 3 次 Finale 参与、至多 3 次通过，而 Finale 通过可完全不伴随通关（通过了前两章、第三章身死）⇒ **两个数在任何账号上都不相等**，并列在同一张表里也不会看起来像同一个数（比任何注释都可靠）。**不设 `TotalChaptersCompleted`**：完成篇章数与 `FinaleWinOrdinal` **恒等**，落字段即是一份纯粹的第二真值——正是单一真值纪律要拦下的形态。
  - **不做两层之间的交叉一致性校验。** 写一条「`FinaleWinOrdinal` 应约等于统计通关数」的读档校验，等于在代码里承认它们该相等，是把已排除的合并从后门放回来。
  - **一个字段不为「部分落点无规则消费点」而拆出第二套同步口径。** `SourceCode` 是首例：它在**法则**上被残卷的 `x` 读取（规则字段层 · 严格同步 · 后端可复算），而在古宝 / 神通 / 法宝三类上**没有任何规则消费点**、后端也无从复算。**仍不单列**——同一字段两套同步口径的成本（两条上行路径、两处读档校验、两份契约措辞）高于收益；该字段**从所在 profile 的既有口径同步即可**。本条约束的是「同一字段的不同落点」，与上方「合并判据」约束的「两个不同字段」是两回事，互不削弱。
- **付费凭证 = `PlayerProfile` 上的具名小类 `PlayerEntitlement`，规则字段层，类内只放付费凭证本身与其兑现水位，不放任何派生量（承重）。** premium bundle 的持有状态改写篇章重试上限（无限 / 9 / 3）并授予随机 PlayerPower / PlayerItem，故它是 PlayerProfile 上的一项账号级状态：

  ```csharp
  public sealed class PlayerEntitlement    // 规则字段层：严格同步 · 后端可复算
  {
      public int BundleGrantOrdinal    { get; }   // 后端写：验票通过时 +1。客户端无写入通道
      public int BundleRedeemedOrdinal { get; }   // 客户端写：兑现事务内置为本次 ordinal。0 = 从未兑现
  }
  ```

  | 字段 | 类型 | 层 | 默认 | 语义 |
  |------|------|----|------|------|
  | `BundleGrantOrdinal` | `int` | 规则字段层（严格同步 · 后端可复算） | `0` | 礼包授予序号；单调递增、不清零；同时是 `AccountRng` 的 `ordinal` 与授予幂等键；`> 0 ⟺ 已购买`。**写入方只有后端**（验票事务内 +1），客户端经 pull 读到 |
  | `BundleRedeemedOrdinal` | `int` | 规则字段层（严格同步 · 后端可复算） | `0` | 兑现水位：已兑现到第几个授予序号。**写入方只有客户端**，且只在兑现事务内，经 `Elements` 置为本次的绝对 `ordinal` |

  - **不变式 `0 ≤ BundleRedeemedOrdinal ≤ BundleGrantOrdinal`，两者相等 ⟺ 无待兑现。** 兑现判定因此收敛为一次纯比较：跨启动、跨设备、清缓存后都成立，不依赖任何本地状态。
  - **两个字段不是同一个数的两份拷贝（承重）。** 它们**恰在存在待兑现购买时不相等**，这个差值正是第二个字段承载的信息；`HasPremiumBundle` 仍读 `BundleGrantOrdinal > 0`。它兜住的是整条链上唯一未被兜住的重复面：

    | 重复面 | 谁兜住 |
    |---|---|
    | 同一张票重复验票 | 后端收据幂等（权威在 `backend-design-documents/contracts/purchase.md`） |
    | 同一批变更重复上行 | `pushId` |
    | 多设备并发写 | `revision` CAS |
    | **pull 到同一序号重复兑现** | **`BundleRedeemedOrdinal`** |

    **`pushId` 与 CAS 都兜不住最后一行：** 第二次兑现是**另一批**变更、另一个 `pushId`，在 CAS 下是一次完全合法的推进，两侧都不报错——玩家凭一次付款拿到两份货。反过来，把待兑现态**只**放 `user://cache/` 则卸载重装 / 清缓存 / 换设备后它消失，而云端序号已推进 ⇒ 收了钱永不给货，且线上无痕迹。**本地缓存不是权威**在此正面生效：两个方向只有云端上的一个水位字段能同时闭合。
  - **不设第三个字段 `HasPremiumBundle` / `PremiumBundleCount`。** 三者是同一个数的三份拷贝：`HasPremiumBundle ⟺ BundleGrantOrdinal > 0`（一次带判断的派生读取，与 `x` 是「对 `List<PlayerPower>` 的一次带过滤计数」同构）；可重复购买下 `BundleGrantOrdinal` **就是**购买次数。这正是**合并判据**与 `FinaleWinOrdinal` 先例所指的形态——**让重复字段从一开始就不存在**，比任何注释可靠。**命名合规**：`Ordinal` 后缀 ⇒ 规则字段层；**类内禁用 `Total` 前缀 / `Count` 后缀**（出现即意味着有人复制了同一个数，可机械检查）。
  - **为何是具名字段而不是 `List<EntitlementKind>` / 字符串集合**：与「`CapabilityFlag` 用 `enum` 而非字符串 key」同一条纪律；付费点在本作被刻意限窄（负面边界见 `systems/monetization.md`），可扩展集合的成本高于收益。日后真新增第二个付费点 = 本类加一个具名字段 + bump 一次 schema。
  - **不落成 `CapabilityFlag`，也不走 modifier pipeline**——两者都是由内容条目聚合出的**派生态**、且受轮回级禁用截断，而付费凭证是账号上的**原始事实**、必须是不参与 pipeline 的硬状态。完整判据见 `systems/monetization.md`。
  - **读档校验**：`BundleGrantOrdinal` `< 0` → `GD.PushError` + **`entitlement` 顶层键本次不进 diff** + 触发一次 pull 重取权威值，**不钳制**——它是回声路径，任何方向的改写都是客户端在改写一个只由后端写入的字段，而钳制出来的值一旦被回声上行就会稳定招致整批拒绝。`BundleRedeemedOrdinal` 的两向钳制**原样成立**：`< 0` → 钳制到 `0`、`> BundleGrantOrdinal` → **钳制到 `BundleGrantOrdinal`**（判定为「无待兑现」），两向皆 `GD.PushWarning`——它是客户端写入路径，且读 `Grant` 只是读、不写回。两者**都不由购买历史重建**（与三个首胜布尔同口径——它们是权威）。**钳制方向偏向不重复发放**：坏档下最坏是少发一次，而少发有后端对账信号可查，多发则是不可回收的发放侧漏洞。
  - **schema 影响**：`PlayerProfile.entitlement` 的两个字段并入既有的同一次 bump，老档缺字段 → `0`（未购买 / 从未兑现，无损）。
  - **两条 JSON path `/entitlement/bundleGrantOrdinal` 与 `/entitlement/bundleRedeemedOrdinal` 都是透明路径。** 前者是**后端会写入**的字段（验票通过时 `+1`），后者后端只读并可校验不变式；白名单、后端写入字段的封闭表与只读语义见 `backend-design-documents/contracts/profile-sync.md` §5，写入端点见同库 `contracts/purchase.md`——本库不复述。移动或重命名任一 path = 破坏性契约变更，须 bump `schemaVersion` 并与后端同批改。
- **服务归属：profile-service。** 账号级行为——PlayerPower 的获取 / 失去与 `status` 开关持久化、PlayerItem 使用次数扣减、成就进度与奖励发放、capability flag 聚合——归 **`systems/services/profile-service.md`**。因 `PlayerProfile ⊃ List<CharacterProfile>`，该服务**同时是两层 profile 的唯一写入面**（`ProfileManager.TryApply(spec)`，全有或全无），使「扣账号级 PlayerItem 次数 + 扣轮回级灵石」天然落在同一事务内。登录归 `account-service`，云端同步归 `sync-service`。

Source: `handoffs/2026-07-24-docs-restructure-class-model.md` · `handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md` · `handoffs/2026-07-26-event-priority-skip-semantics-and-hotfix-scope.md` · `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md` · `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md` · `handoffs/2026-08-06b-asymmetric-ch1-band-consented-power-loss-and-chapter-retry-shape.md` · `handoffs/2026-08-09b-player-power-fragment-finale-bound-drop-chance.md` · `handoffs/2026-08-09d-field-layering-merge-criterion-and-ordinal-naming.md` · `handoffs/2026-08-10b-grant-source-and-fragment-source-scoping.md` · `handoffs/2026-08-10c-ability-disable-replacement-and-player-statistics.md` · `handoffs/2026-08-12b-grant-source-per-kind-scope.md` · `handoffs/2026-08-15b-monetization-entitlement-purchase-shape-and-scope.md` · `handoffs/2026-08-16b-cross-library-alignment-and-bridge-ledger.md` · `handoffs/2026-08-17h-profile-field-schema.md` · `handoffs/2026-08-19-bundle-grant-ordinal-authority.md` · `handoffs/2026-08-19-costkey-statkey-registry.md` · `handoffs/2026-08-19-game-setting-schema.md` · `handoffs/2026-08-19-codex-entry-schema.md` · `handoffs/2026-08-19-device-id-provisioning.md` · `handoffs/2026-08-22-finale-failure-is-death.md` · `handoffs/2026-08-22-echo-validation-scope-client-half.md` · `handoffs/2026-08-25-info-economy-and-codex-expansion.md`

## 子系统导航

| 子系统 | 文件 | 内容 |
|--------|------|------|
| 古宝 player-item | `player-item/_index.md`、`player-item/common-properties.md` | 账号级、有使用次数限制的道具（PlayerItem），含可购道具定义。 |
| 法则 player-power | `player-power/_index.md`、`player-power/common-properties.md` | 账号级 always-available 能力（PlayerPower，带开关）；通过事件触发器的被动修正（relic / joker 语义）。数据定义 = `PowerData`（与神通共用，字段面权威在 `character-profile/power/_index.md`）。 |
| 成就 achievement | `achievement/_index.md`、`achievement/common-properties.md` | 账号级分组成就与两档（60% / 90%）一次性奖励；80/20 可见比例。 |
| 图鉴族 codex | `codex/_index.md`、`codex/common-properties.md`、`codex/enemy-codex.md`、`codex/technique-codex.md` | **七个账号级图鉴**（Enemy / CharacterPower / PlayerPower / CharacterItem / PlayerItem / Location / Technique）：记录已遭遇 / 已获得对象的**静态文案知识**，不记录动态情报。 |
| 账号信息 account-info | `account-info.md` | 账号身份与状态元数据（AccountInfo）；强制账号登录，无游客态。 |
| 游戏设置 game-setting | `game-setting.md` | 玩家可调设置中**账号级的那一半**（GameSetting：三条音量轨 + 快速演出）；设备本地那一半的落点与切分判据同在该文档。 |

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- **强制在线 · 云端权威**（PlayerProfile 为云端权威账号主档）→ `decisions/ADR-0003-online-cloud-authority.md`（Accepted）。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **元进程持久化范围与平衡边界：** `achievement` 条目的 schema、以及各账号级条目的解锁 / 获取触发仍待定；PlayerPower 的平衡边界（防 pay/grind-to-win、是否影响 cycle seed / 计分公平）同样待定。→ 见 `systems/services/life-cycle-service.md`、`achievement/_index.md`。

## 对应
提炼至：`.claude/knowledge/systems/player-profile/_index.md`（待建）。
