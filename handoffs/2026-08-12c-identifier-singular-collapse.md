# 标识符单数收口：`CharacterItem` / `Achievement` / `magicPack`，与 `pastEvent` 类型漂移纠正

- id: 2026-08-12c-identifier-singular-collapse
- date: 2026-08-12
- topic: terminology.md, systems/character-profile/item/, systems/player-profile/achievement/, systems/architecture.md, systems/services/life-cycle-service.md, ux/screen-flow.md, program-overview.md, decisions/ADR-0004
- status: distilled
- distilled-to: `terminology.md`, `program-overview.md`, `systems/architecture.md`, `systems/_index.md`, `systems/monetization.md`, `systems/character-profile/item/`（`_index.md`, `common-properties.md`）, `systems/character-profile/power/_index.md`, `systems/player-profile/`（`_index.md`, `achievement/`, `player-item/_index.md`, `account-info.md`, `codex/_index.md`, `codex/enemy-codex.md`）, `systems/services/`（`_index.md`, `life-cycle-service.md`, `profile-service.md`）, `ux/screen-flow.md`, `vision/scope.md`, `decisions/ADR-0004-realm-checkpoint-retry-model.md`, `open-questions/`（`07-codex-monetization.md`, `deferred-content.md`, `update-log.md`）, `answer-logs/`（`log-character-item-singular-naming.md`, `_index.md`）

## Intent（distilled）

**一句话：** 全库把「集合元素类型」的复数写法整体作废——类型名恒单数、复数只属于集合字段名；法宝的集合字段就此定名为 `CharacterProfile.magicPack`，与已定名的容器概念「储物袋」显式同名。这是一次**纯标识符收口，机制侧零改动、不 bump 存档 schema、无迁移**。

### 1. 三层分工写死（本次的承重条目）

单复数之所以能并存两个月，根因是「`CharacterItem` 指的到底是哪一层」从未写清。四层一次定死：

| 层 | 标识符 | 说明 |
|---|---|---|
| 内容定义（`Resource`，ContentRegistry 只读单例） | **`ItemData`** | 两层共用，`Scope == AbilityScope.Character` 者即法宝。**不存在 `CharacterItemData` 类型。** |
| 持有条目（存档态，落 `CharacterProfile`） | **`CharacterItem`** | 一份实例 = 集合的一个元素；带 `ItemId` / `SourceCode` / `Charges` / `status`。 |
| 集合字段（`CharacterProfile` 上） | **`magicPack`**，类型 `List<CharacterItem>` | 储物袋：上限 9 格，计数单位 = 按 `ItemId` 堆叠后的条目数。 |
| 领域词 / 图鉴 | **法宝** / `CharacterItemCodex` | 本就是单数形态，统一后反而自洽。 |

**与 08-06d 自洽的推论：** 因为同 `ItemId` 可持有多份、`Charges` 是每一份实例各自的次数，集合元素必须是**一份实例**而非「一条 Id 一行」——这正是元素类型该用单数的实证。储物袋的「按 `ItemId` 堆叠显示 `×N`、堆叠后只占 1 格」是**呈现层的聚合**，不是存储形态。

### 2. 为什么是单数（三条各自独立成立）

- **对称性。** 四类持有条目里 `PlayerPower` / `PlayerItem` / `CharacterPower` 三个都是单数，`CharacterItems` 是唯一的离群项；08-03 定名表本身写的也是 `CharacterItem`。拉回单数改一处，反向统一要改三处并推翻定名表。
- **命名族一致。** 内容层 `ItemData` / `PowerData` / `EnemyData` / `CardData` / `AdventureEventData` 全部单数；`CharacterItemCodex`、`AbilityChangeElement.Kind { Power, Item }`、置换同池判据 `CharacterItem ↔ CharacterItem` 也已在用单数。复数形态在全库只剩「`List<...>` 的泛型参数位」这一个出现点。
- **泛型参数位的复数是语义错误。** `List<CharacterItems>` 读作「一个『多件法宝』的列表」，即两层复数。C# 侧通行约定同向：**类型名恒为单数，复数只属于集合变量 / 字段名**。

### 3. 集合字段名取 `magicPack`（三选一的裁决）

| 选项 | 字段 | 依据 | 代价 |
|---|---|---|---|
| A | `characterItem`（单数） | 沿用 `pastEvent` / `disabledAbility` 的既有风格（08-10c 明写） | 与 .NET 集合命名惯例相悖 |
| B | `characterItems`（复数） | .NET / C# 通行：集合成员用复数 | 与 08-10c「单数命名」形成张力，需一并松动那句话 |
| **C（已取）** | **`magicPack`** | 字段直接命名它承载的**已定名概念「储物袋」**；9 格上限、按 `ItemId` 堆叠、`UsableScene` 筛出「随身」等规则全部挂在储物袋上，字段名与规则面对齐 | 术语表需补一行让容器概念与存档字段显式同名 |

取 C 的理由：单复数之争在 C 下**直接消失**（`magicPack` 无单复数属性），且它让「储物袋」从一个只在 UX / 规则文本里出现的词落成真实字段，减少一次「概念 → 字段」的翻译。**连带动作：** `terminology.md` 的储物袋条目补一句「`CharacterProfile.magicPack` 即其存档承载字段」。

### 4. `Achievements` 一并收口（同一缺陷类，推演逐条同构）

- **元素类型 `Achievement`**（单数）——与 `PlayerPower` / `PlayerItem` / `CharacterItem` 同族。
- **集合字段 `achievement`**（单数）——成就**没有**「储物袋」那样的已定名容器概念，C 路线在此无对应物；退回库内既有的单数字段风格（`pastEvent` / `disabledAbility`），**零张力**。若日后全库统一把集合字段改为复数风格，本字段随那次统一一并改，不单独例外。
- **裸提及一并单数化**（本次澄清追加，见 Clarifications ①）：作为系统名 / 概念名 / 菜单入口出现的裸写 `Achievements` 全部改为 `Achievement`，使「`PlayerPower` / `PlayerItem` / `Achievement` / `GameSetting`」这类并列句在文字层也对称。
- **文件夹 `systems/player-profile/achievements/` 改名为 `achievement/`**（本次澄清追加），与 `player-item/` / `player-power/` 的单数文件夹风格对齐；全库指向该路径的交叉引用同步改写。
- **分组成就的结构不受影响**——组内加权进度、60% / 90% 两档一次性奖励、80/20 可见比例全部原样。

### 5. `pastEvent` 的类型漂移一并纠正（三处）

`systems/character-profile/_index.md` 在 08-09c 已定案修行历程 = **`IReadOnlyList<PastEventEntry>`**（存的是定稿实例快照 + 本次结算的最终账，不是 `Resource`），但三份活文档仍写 `List<AdventureEvent>`：`systems/services/life-cycle-service.md` 的 `CharacterProfile` 字段清单、`program-overview.md` 的端到端调用链图、`decisions/ADR-0004` 的「数据模型对齐」句。三处全部对齐权威表述。ADR-0004 那一处是**类型标注订正，不改变该 ADR 的任何决策语义**（它讲的是境界检查点与重试模型）。

### 6. 迁移与落地节奏

无线上账号、`game-feature-branch/` 尚无该系统的任何代码 ⇒ **纯文档改写，不 bump 存档 schema 版本、不需迁移路径**。这是把命名一次改到位的最便宜窗口；等 `CharacterProfile` 的存档字段进了线上账号再改，就要付一次迁移。

改写范围**只覆盖活文档**：`handoffs/`、`answer-logs/`、`inbox/archive/` 中的复数写法**不回改**——它们是带日期的当时意图快照，而「活文档只保留最新设计」的约定作用面是活文档。`terminology.md` 里「（现有写法 `List<CharacterItems>`，单复数待统一）」整段删除，不留「原写法为 X」的考古。

### 7. 定稿形态

```csharp
// 内容定义（content-service / ContentRegistry，共享只读单例）
ItemData { Id, Scope: AbilityScope, UsableScene, ManaCost?, Charges, Abilities, Rarity: RarityTier, Subtypes, ContentEnabled }

// 持有条目（存档态，落 CharacterProfile）
CharacterItem { string ItemId, Source SourceCode, int Charges, bool status }

// CharacterProfile 字段
List<CharacterItem> magicPack;              // 储物袋：上限 9（计数 = 按 ItemId 堆叠后的条目数）
IReadOnlyList<PastEventEntry> pastEvent;    // 修行历程（连带纠正 08-09c 的类型漂移）

// PlayerProfile 字段（连带收口）
List<Achievement> achievement;
```

### 8. 后果

- **存档 schema：** 字段名与元素类型名就此定稿；**无迁移**。`CharacterProfile` / `PlayerProfile` 的字段清单在 `systems/*-profile/`、`architecture.md`、`life-cycle-service.md` 多处并存，改写须同步，否则漂移换个地方继续——本次两处漂移都源于此。`architecture.md` 与 `life-cycle-service.md` 的清单处已有「结构权威见 `systems/*-profile/`」标注，故不新增约定，只需确保改写后各处一致。
- **图鉴 / 置换 / 禁用三处的既有表述无需改动**——它们本就写单数。
- **不影响任何已定决策的语义**：纯标识符收口，机制侧零改动。

## Clarifications（interview 产物）

① **裸写 `Achievements` 的处理边界。** 原草稿裁决 2 只写了「元素类型 `Achievement` + 字段 `achievement`」，但全库活文档另有约 10 处作为系统名 / 概念名 / 菜单入口出现的裸写 `Achievements`（`achievements/_index.md` 标题行、`vision/scope.md` 主菜单入口、`life-cycle-service.md` 与 `profile-service.md` 的字段族并列句、`terminology.md` 账号级统计计数条目、`codex/_index.md` 第三条积累线句）。
→ **用户裁决：一并改为 `Achievement`，且文件夹 `achievements/` 一并改名为 `achievement/`。** 这**扩展**了原草稿声明的「纯标识符收口、文件夹不动」范围——路径改名连带全库交叉引用改写。理由与四格对称一致：`player-item/` / `player-power/` 本就是单数文件夹，`achievements/` 是唯一的复数离群项。

② **`pastEvent` 漂移的覆盖范围。** 原草稿裁决 4 只点名 `life-cycle-service.md`（1 处），但同一漂移在 `program-overview.md` 的调用链图与 `decisions/ADR-0004` 的数据模型对齐句里同样存在。
→ **用户裁决：三处全部纠正。** 这**扩展**了原草稿的 1 处范围，并按根约定「ADR 可自由编辑」直接改写 ADR-0004 的那一行。

③ **草稿枚举的落点清单不全（自行推演补齐，无需裁定）。** 草稿列「16 处」，与全库实况核对后补入 5 处漏列的活文档落点：`systems/player-profile/player-item/_index.md`（「与角色级的 CharacterItems」）· `systems/architecture.md` 拆分轴论证段（与 `services/_index.md` 同源的第二份）· `systems/player-profile/_index.md`（`List<Achievements>`）· `systems/player-profile/achievement/_index.md`（`List<Achievements>`）· `character-profile/item/_index.md` 同一行内的第 2 个 token。依据：本次意图明确是「全库活文档收口」，枚举不全属清点疏漏，补齐是逻辑必然。

④ **`Id` / `ItemId` 的写法统一（自行推演，无需裁定）。** 草稿内两种写法并存，含义唯一（持有条目上指向 `ItemData.Id` 的引用字段）。统一写 **`ItemId`**，储物袋堆叠口径统一表述为「按 `ItemId` 堆叠」。

## Open questions

**无。** 原草稿标注的唯一前置依赖（「`SourceCode` 是否收窄到账号级两类」——若收窄则 `CharacterItem` 不带该字段）已由同日的 `handoffs/2026-08-12b-grant-source-per-kind-scope.md` 反向答结：`Source` 清单改为按 `(Kind, Scope)` 分域开放，法宝层的合法取值为 `EventOutcome` / `CombatReward` / `ExchangePurchase` / `InitialGrant`（+ 读档兜底 `Unknown`），**故 `CharacterItem` 确定携带 `SourceCode`**。该依赖本就只影响字段清单、不影响命名结论。

## Notes / triage

- 输入 = `inbox/solution-draft-character-item-singular-naming.md`（`/provide-solution-draft` 产物，用户已评审并在文末「已裁决」小节定下 5 项）。本次 interview 在此之上追加两项范围扩展（见 Clarifications ① ②）。
- 答结待答项 1 条（`CharacterItem` 单复数不一致），见 `answer-logs/log-character-item-singular-naming.md`。
- 无跨库影响：命名是客户端存档模型的内部标识符，未触及 `backend-design-documents/contracts/` 的任何报文字段。
