# profile-schema-versions —— 存档 `schemaVersion` 登记表

> 两层 Profile（`PlayerProfile` ⊃ `List<CharacterProfile>`）**每一版的序列化形状**的唯一登记面。
> 宿主服务是 `sync-service`（`MigrationManager` 在那里）；服务本体的设计见 `systems/services/sync-service.md`。
> `schemaVersion` 不是 `PlayerProfile` 的字段——它落三处信封，见该文件「JSON 序列化命名策略」。

Source: `handoffs/2026-09-03-schema-bump-ledger-authority.md`

## 登记表

**一行一个版本号。某次结构改动属于哪一版，以本表为准。**

| `schemaVersion` | 本版纳入的结构改动 | 老档处置口径 | 触碰透明 / 回声路径 | golden 形状快照 | 权威回链 |
|---|---|---|---|---|---|
| **1**（首发） | 首发形状，逐条见下方「v1 —— 首发形状」 | **空迁移**（首发形状，无老档） | **有**：首发形状即含透明段，且含两个受回声校验约束的顶层键 `accountInfo` · `entitlement`。逐条 JSON path 的权威在 `backend-design-documents/contracts/profile-sync.md` §5，**本库不复制** | `profile-shape-v1.json`（待建，见下方「`ProfileShapeCheck`」） | 逐条见清单内 |

### v1 —— 首发形状

**首发前的一切改动全部归入 `schemaVersion = 1`，不拆成多版**——拆开只会让迁移器多几级空跳，而这些版本永远不会有真实存档。补齐工作是往本清单里补条目，**不产生任何新的 bump**。

| # | 对象 | 纳入的结构 | 权威 |
|---|---|---|---|
| 1 | `CharacterProfile` | `id` · `characterDataId` · `defeatReason`（可空） | `systems/character-profile/_index.md` |
| 2 | `CharacterProfile` | `technique : TechniqueEntry[]` · `looseCard : string[]` | 同上 |
| 3 | `CharacterProfile` | `spiritStone` · `immortalJade`（`int`，顶层、相邻） | 同上 · `character-profile/currency.md` |
| 4 | `CharacterProfile` | `rng`（`cycleSeed` + `stream[]`，键名 camelCase）· `startContentVersion : int` · `lastContentVersion : int` | `systems/character-profile/_index.md` |
| 5 | `CharacterProfile` | `eventOption : EventOptionSave?` · `activeEvent : ActiveEventState?` | 同上 |
| 6 | `CharacterProfile` | `activeCombat : ActiveCombat?`（战斗中间态） | `systems/services/combat-service.md` |
| 7 | `CharacterProfile` | `pastEvent : PastEventEntry[]`（条目结构 13 字段，含 `EnemyTraceRef`） | `systems/adventure-event/common-properties.md` · `decisions/ADR-0021-past-event-trace-schema.md` |
| 8 | `CharacterProfile` | `pastItemUse : ItemUseEntry[]` | `systems/character-profile/_index.md` · `decisions/ADR-0122-batch-layer-inventory-commit-and-trace.md` |
| 9 | `CharacterProfile` | `plotKeyPoint : PlotKeyPoint[]` | `systems/character-profile/_index.md` |
| 10 | `CharacterProfile` | `disabledAbility : DisabledAbilityEntry[]`（顶层键） | 同上 |
| 11 | `CharacterProfile` | `chapterRetry` 三格具名字段 `Ch1RetryUsed` / `Ch2RetryUsed` / `Ch3RetryUsed` | 同上 |
| 12 | `CharacterProfile.Status` | 首发形状 **22 格**，**不含** `currentMana`（战斗内运行态，落 `activeCombat`） | 同上 · `decisions/ADR-0127-life-merged-into-lifespan.md` |
| 13 | `CharacterProfile.Status` | `FaithBand` · `BloodlustBand`（`sbyte`） | `systems/character-profile/_index.md` |
| 14 | `CharacterProfile.Status` | `CurrentLocationId` · `LocationEventCount` | 同上 |
| 15 | `PlayerProfile` | `entitlement : PlayerEntitlement`（2 字段） | `systems/player-profile/_index.md` |
| 16 | `PlayerProfile` | `PlayerPowerFragment` 七格：`Accumulated` · `FinaleWinOrdinal` · `Ch1/2/3FirstWinDone` · `LastRoll` · `LastEffectiveChance` | 同上 |
| 17 | `PlayerProfile` | `AccountInfo.AccountSeed` | `systems/player-profile/account-info.md` |
| 18 | `PlayerProfile` | 引入 `statistics`（`PlayerStatistics`）与 `disabledAbility` **两个顶层键**本身（见下方形态纪律的顶层键分界） | `systems/player-profile/_index.md` · `systems/character-profile/_index.md` |
| 19 | `PlayerProfile` | 全部 Codex 顶层键（元素 `CodexEntry`） | `systems/player-profile/codex/common-properties.md` |
| 20 | `PlayerProfile` | `gameSetting`（子对象 `GameSetting`） | `systems/player-profile/game-setting.md` |
| 21 | `PlayerProfile` | 四类持有条目定形，条目键名 `powerId` / `itemId`；**集合字段名一律单数** | `systems/player-profile/_index.md` · `decisions/ADR-0105-singular-collection-field-naming.md` |
| 22 | `ProfileChangeSpec` | 按施加语义分列的各列：`StatusChanges` · `DeckElements` · `PlotElements` · `EventStateChanges` · `RngElements` · `TraceElements` · `CodexElements` · `SettingChanges` · `ItemElements` · `ItemUseElements`（元素类型 `StatusAssignment` / `DeckChangeElement` / `PlotKeyPointAssignment` / `EventStateAssignment` / `RngStateAssignment` / `PastEventEntry` / `CodexUnlock` / `SettingAssignment` / `ItemChargeElement` / `ItemUseEntry`） | `systems/services/profile-service.md` · `decisions/ADR-0128-status-changes-assignment-column.md` |
| 23 | `ProfileChangeSpec` | `ChangeElement` 第三字段 `Op`；`ElementSpec` 第六列 `AllowedOps`；`DeckChangeOp` 含 `AddLooseCard` ⇒ `PastEventEntry.AppliedChange` 的形状随之定形 | `systems/services/profile-service.md` |
| 24 | `EventOption` | `OutcomeSpec` · `Encounter` · `DestinationLocationId` | `systems/adventure-event/common-properties.md` · `decisions/ADR-0128-status-changes-assignment-column.md` |
| 25 | `EventOption` | Exchange 物化三格 `ExchangeStock` · `BarterStock` · `RerolledCount` | `systems/adventure-event/exchange/common-properties.md` · `decisions/ADR-0126-exchange-barter-payment.md` |
| 26 | `EventOption` | `AbilityChangeSlots` | `systems/services/future-event-service.md` |
| 27 | `ActiveCombat` | 战场条目 `amount` · 栈条目 `itemId`（两格） | `systems/services/combat-service.md` · `decisions/ADR-0132-stack-entry-kind-used-item.md` |

**清单只写对象 + 字段名 + 一句话，不复述类型 / 取值域 / 校验语义**——那些的权威在「权威」列所指的字段所在文档。这与 `content/` 的硬边界是同一条纪律。

## 形态纪律

**① 本表的语义是「每一版的形状」，不是「一次的内容清单」，也不是首发前的改动流水账。** 判据即它与 `ProfileShapeCheck` 的 golden 快照**严格同构、逐行对得上**——那是本方案唯一可机检的兑现。写成「这一次改了什么」会让版本行与它的 golden 文件对不上。

**② 别处一律回链本表，不得就地宣布 bump。** 字段所在文档、服务文档与 ADR 里提到某格「随本次落定 bump」时，改写为固定句式：

> 本字段属 `schemaVersion` 1，登记见 `systems/services/profile-schema-versions.md`。

三类**非自称**的 bump 表述不适用本条、保持原样：**否定式**（「不 bump」「零迁移」）· **假设式**（「日后若要做，最小路径 = … + 一次 bump」）· **纪律式**（改名 / 移动透明路径必须 bump）。它们讲的是规则，不是某次做过了；回链掉会毁掉规则本身。

**③ 老档默认值口径留在字段所在处，不搬进本表。** 「缺字段 → 空列表 / `0` / `null`」直接由该字段的类型与语义决定，按共有属性的分层判据（`systems/common-properties.md`）应定义在最小公共祖先 = 字段本身；本表只投影「哪一版纳入了它」+ 回链。搬进来会让本表变成第二份字段规格。

**④ 删除类改动的处置口径是本表的唯一例外，且不进任何版本行的形状清单。** 字段已经不在了，没有「字段所在处」可以承载它，故它落在版本行的「老档处置口径」列：**老档中该格原样丢弃，不迁移、不告警。**
- **首发前删除的字段不进任何版本行**——它从未存在于任何真实存档中，而 v1 是首发形状，它里面本就没有那些格。追溯归 git 与对应 ADR。
- 自 v2 起真实发生的删除，其五步流程（含最后一步「在本表追加一行」）见 `systems/architecture.md`「删除一个资源 element 同样恰好五步」。

**⑤ 顶层键分界：引入一个顶层键要进版本行，已登记顶层键内向对象追加字段不一定。** 三档：
- **引入一个新的顶层键** ⇒ 进版本行（它是浅合并的最小替换单位，形状上是一格新结构）。
- **不透明段内、已登记顶层键内向对象追加一个字段** ⇒ **不进版本行、不 bump**。典型是统计层加一项计数：宽松同步 + 老档缺字段补默认值 + 不参与任何判定 ⇒ 既不需要迁移路径也不需要后端配合（`systems/services/sync-service.md`；契约侧的对位推论在 `backend-design-documents/contracts/envelope.md` §8）。
- **受回声校验约束的顶层键内追加字段** ⇒ 与「移动 / 重命名透明路径」同档：两侧同批落笔并进版本行。理由见 `systems/services/sync-service.md`「透明路径的稳定性纪律」。

## 登记时点与责任人

- **判据（变更内原子）：任何改动 `PlayerProfile` / `CharacterProfile` 及其可达对象序列化形态的设计落笔，未登记进本表即视为未完成。**
- **登记人 = 写下该次设计改动的那一次落笔**，不是「日后由谁来收拾」。把 bump 一句写在 ADR 或字段所在文档里，等于就地登记在了第二本账上。
- **不设周期性对账。** 周期性对账允许漂移窗口存在，而那个窗口正是两侧按不同真值编码的时期。判据与后端 `contracts/_index.md`「契约变更的完成判据」同款。
- **跨边界的那一半：本表新增一行 = 一次 bump 定案，是跨边界承接分片的一类常规触发源**（`open-questions/cross-boundary.md`）。后端兼容矩阵的 `schemaVersion` 集合、登记流程与「矩阵先加、客户端后发」的顺序纪律在 `backend-design-documents/operations/version-matrix.md` 与 `operations/_index.md`，**本库一字不复述**。

## `ProfileShapeCheck`：把漏 bump 抬到纪律阶梯第 2 级

先套 `systems/architecture.md`「纪律的可执行化」的选级判据：**漏 bump 能不能上线？能。线上可不可见？不可见。** 结构改了而版本号没改 ⇒ 后端与旧客户端都以为是同一个 schema，没有任何一侧会报错；症状是复算悄悄退化、迁移器悄悄跳过。按判据**必须做到第 1 或第 2 级，第 3 级不够**。

检查对象是**序列化形状**，不在 C# 类型系统的作用域内，故取该处通用补注的等价物：

> **`ProfileShapeCheck`：由 `PlayerProfile` 递归导出序列化形状（JSON path + 类型，排序后规范化），与该版的 golden 快照文件逐字比对。不一致 ⇒ 校验失败。**

- **载体是 golden JSON 快照文件**（一份"空 `PlayerProfile`"的序列化结果），签入 `game-feature-branch/`，与 `SchemaVersion` 常量同处，命名 `profile-shape-v<N>.json`。**它必须带文件头注释：「本文件由 `ProfileShapeCheck` 生成，不是规格；规格见各字段文档。」** 失败时 `git diff` 直接指出是哪个 path 变了，这正是护栏失败那一刻的全部诉求。同库先例是签入仓库的机器可读对照物 `contracts/vectors/splitmix64.json`。
- **生成物不进设计库**（`decisions/ADR-0125-no-binary-over-overlay.md` 同向：产物随版本走，不经 overlay）。本表只记该版 golden 文件的**文件名**，文件本身在客户端分支。
- **一份实现、两个触发点**：落地在打包 / 发布管线，**不通过即不产包**（第 2 级等价物）；并在 `#if DEBUG` 启动期跑同一份校验（第 3 级，开发期即刻显形）。与「同一个 `LoadAll()` 路径喂给发布侧」同构，**不新增管线**——它与内容包的发布侧校验闸共用同一条。
- **本表每行记下该版 golden 文件**，于是「文档没登记」与「代码没 bump」收敛成**同一个可机检的事实**。这是本表唯一能让漏登被机制发现的部件，其余各条都只是纪律。
- **首发前只有 v1 一版 ⇒ 只保留当前版一份 golden 文件**，不为尚无实例的多版本回归先行造目录。
- **落地时点：** `game-feature-branch/` 尚无 `.csproj`，本护栏宜与那批既有实测项同批落地（`open-questions/05-service-contracts.md`），**不单独排期；设计形态不依赖实测结果**。
- **第 3 级的一条廉价旁证：** 「凡本表之外出现『bump schema 版本』字样 ⇒ 必须是回链或上述三类非自称形态」可作为 `/sync-knowledge` 的一条 grep 断言。它抓的是**文档漂移**，护栏抓的是**代码漂移**，两者不重叠。

## 对应
提炼至：`.claude/knowledge/systems/sync-service.md`（引用层，待建）。
