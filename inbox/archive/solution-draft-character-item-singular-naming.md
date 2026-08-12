---
type: solution-draft
date: 2026-08-12
question: `CharacterItem`（法宝）的标识符单复数不一致 —— 中文定名对应单数 `CharacterItem`，但全库既有写法是 `List<CharacterItems>`，是否统一？
source: open-questions/07-codex-monetization.md → ⑦ 图鉴族与商业化；systems/character-profile/item/_index.md#待决问题
targets: terminology.md、systems/character-profile/item/_index.md、systems/character-profile/item/common-properties.md、systems/character-profile/power/_index.md、systems/architecture.md、systems/services/life-cycle-service.md、systems/services/_index.md、systems/player-profile/codex/_index.md、ux/screen-flow.md
status: distilled
reviewed: 2026-08-12 — 用户裁决 5 项（集合字段取 `magicPack` · `List<Achievements>` 一并收口 · 历史文档不回改 · `pastEvent` 漂移一并纠正 · 其余按推荐定案）；`/analyze-new-ideas` 的 interview 再追加 2 项范围扩展（裸写 `Achievements` 一并单数化 + 文件夹 `achievements/` → `achievement/`；`pastEvent` 漂移三处全部纠正而非 1 处）
distilled-to: handoffs/2026-08-12c-identifier-singular-collapse.md
---

> **2026-08-12 已由用户裁决**（见文末「已裁决」小节）：集合字段取 **`magicPack`**、`List<Achievements>` **一并收口**、历史文档 **不回改**、`life-cycle-service.md` 的 `pastEvent` 漂移 **一并纠正**，其余按推荐定案。本文件已可直接喂给 `/analyze-new-ideas`。

# 方案草稿 — `CharacterItem` 标识符的单复数统一

## 问题

08-03 定名批次把轮回级角色道具的中文名定为 **法宝**、标识符定为 **`CharacterItem`（单数）**，与账号级的 `PlayerItem`、以及能力侧的 `PlayerPower` / `CharacterPower` 构成 `Player*` / `Character*` 的四格对称。但在此之前（07-24 的类模型重构起）全库一直写作 **`List<CharacterItems>`（复数）**，两种写法此后并存至今：`terminology.md` 第 39 行、`systems/character-profile/item/` 两份文档、`systems/architecture.md`、`systems/services/life-cycle-service.md` 的 `CharacterProfile` 字段清单、`ux/screen-flow.md` 的储物袋入口段落等处都写复数，而定名表、图鉴族（`CharacterItemCodex`）、`SourceCode` 覆盖的四类清单、置换同池判据等处写单数。

它卡住的是：**`CharacterProfile` 的存档 schema 字段无法定稿**（字段名与元素类型名都悬着），进而 `ItemData` ↔ 持有条目的分层、以及储物袋（9 格、按 `Id` 堆叠、`Charges` 每份各自）的落地面都无法被 `/derive-requirements` 消费。

## 约束（来自既有设计）

- **中文名不承担层级表达，层级对称只在英文标识符上成立**（`Player*` / `Character*`）。Source: `terminology.md` 08-03 定名纪律。
- **类型名 PascalCase，与 Godot C# API 大小写一致**；类型一致性须贯穿 UI → 服务 → 数据资源 → 存档模型全链路，层间不做隐式转换。Source: `.claude/rules/csharp-godot-rules.md`、`systems/common-properties.md`「字段命名与类型一致性」。
- **内容定义层是 `XxxData` 命名族**（`EnemyData` / `ItemData` / `PowerData` / `CardData` / `AdventureEventData`），全部单数；`ItemData` **两层共用**，靠 `Scope: AbilityScope { Character, Player }` 区分持久层。Source: `systems/character-profile/item/_index.md`（08-04b · 08-10c）、`terminology.md`。
- **持有条目是与内容定义分开的一层**：`SourceCode` / `status` / `Charges` 落持有条目，不落 `ItemData`。四类持有条目（法则 / 古宝 / 神通 / 法宝）形状同构。Source: `systems/common-properties.md`「授予来源共有字段」。
- **同一 `Id` 可持有多份，`Charges` 是每一份实例各自的次数**（不是「一条 Id 一个总次数」）。Source: `systems/character-profile/item/_index.md`（08-06d）。
- **储物袋 `magic pack` 是已定名的容器概念**：跨战斗内外存在、上限 9 格、计数单位 = 按 `Id` 堆叠后的条目数；战斗内那一份筛选视图称「随身」。Source: `terminology.md` 战斗借词表（08-04b）。
- **集合字段的既有命名风格是单数**：`pastEvent`、`disabledAbility`（08-10c 明写「单数命名，沿用 `pastEvent` 的既有风格」）；但 `eventOptions` 是复数。Source: `systems/character-profile/_index.md`、`terminology.md`。
- 当前**无线上账号、`game-feature-branch/` 尚无该系统的任何代码**，故命名改动的迁移成本为零。

## 建议方案

### 1. 统一为单数 `CharacterItem`，`CharacterItems` 整体作废

`[既有推演]`

三条依据各自独立成立：

- **对称性。** 四类持有条目里 `PlayerPower` / `PlayerItem` / `CharacterPower` 三个都是单数，`CharacterItems` 是**唯一的离群项**；08-03 定名表本身写的也是 `CharacterItem`。把离群项拉回单数只改一处，反向统一要改三处并推翻定名表。
- **命名族一致。** 内容层 `ItemData` / `PowerData` / `EnemyData` 全部单数；`CharacterItemCodex`（图鉴族第四本）、`AbilityChangeElement` 的 `Kind { Power, Item }`、置换同池判据 `CharacterItem ↔ CharacterItem` 也已经在用单数。复数形态在全库只剩「`List<...>` 的泛型参数位」这一个出现点。
- **泛型参数位的复数是语义错误。** `List<CharacterItems>` 读作「一个『多件法宝』的列表」，即两层复数。C# 侧的通行约定同向：**类型名恒为单数，复数只属于集合变量 / 字段名**（`.claude/rules/csharp-godot-rules.md` 的 PascalCase 条款在类型侧只允许一种读法）。

### 2. 三层分工写死，避免同一漂移再长回来

`[既有推演]` 单复数之所以能并存两个月，是因为「`CharacterItem` 指的到底是哪一层」从未写清。建议在 `item/_index.md` 顶部一次写死：

| 层 | 标识符 | 说明 |
|---|---|---|
| 内容定义（`Resource`，ContentRegistry 只读单例） | **`ItemData`** | 两层共用，`Scope == AbilityScope.Character` 者即法宝。**不存在 `CharacterItemData` 类型。** |
| 持有条目（存档态，落 `CharacterProfile`） | **`CharacterItem`** | 一份实例 = 集合的一个元素；带 `Id` / `SourceCode` / `Charges` / `status`。 |
| 集合字段（`CharacterProfile` 上） | **`List<CharacterItem>`** | 见下一项定名。 |
| 领域词 / 图鉴 | **法宝** / `CharacterItemCodex` | 均已是单数形态，无需改动。 |

**推论（与 08-06d 自洽）：** 因为同 `Id` 可持有多份、`Charges` 每份各自，集合元素必须是**一份实例**而非「一条 Id 一行」——这正是元素类型该用单数的实证，储物袋的「按 `Id` 堆叠显示 `×N`」是**呈现层的聚合**，不是存储形态。

### 3. 集合字段名 = `magicPack`（已裁决 · 08-12）

`[取向选择 → 已定]` **取选项 C：`CharacterProfile.magicPack`，类型 `List<CharacterItem>`。** 三个候选与取舍如下（保留论证，便于提炼时写清理由）：

| 选项 | 字段 | 依据 | 代价 |
|---|---|---|---|
| A | `characterItem`（单数） | 沿用 `pastEvent` / `disabledAbility` 的既有风格，08-10c 已明写这条风格 | 与 .NET 集合命名惯例相悖；`eventOptions` 已是反例，风格本就不统一 |
| B | `characterItems`（复数） | .NET / C# 通行：集合成员用复数 | 与 08-10c「单数命名」的既有风格表述形成张力，需一并松动那句话 |
| **C（已取）** | **`magicPack`** | 字段直接命名它承载的**已定名概念「储物袋」**；9 格上限、按 `Id` 堆叠、`UsableScene` 筛出「随身」等规则全部挂在储物袋上，字段名与规则面对齐 | 需在术语表补一行「`magicPack` = `CharacterProfile` 上的法宝持有字段」，让容器概念与存档字段显式同名 |

取 **C** 的理由：单复数之争在 C 下直接消失（`magicPack` 无单复数歧义），且它让「储物袋」从一个只在 UX / 规则文本里出现的词落成真实字段，减少一次「概念 → 字段」的翻译。**连带动作：** `terminology.md` 的储物袋条目补一句「`CharacterProfile.magicPack` 即其存档承载字段」，让容器概念与字段显式同名。

### 4. `List<Achievements>` 一并收口（已裁决 · 08-12）

`[既有推演]` 同一缺陷类，**推演逐条同构**：类型名恒单数、复数只属字段名。定为：

- **元素类型 `Achievement`**（单数）——与 `PlayerPower` / `PlayerItem` / `CharacterItem` 同族。
- **集合字段 `achievement`**（单数，选项 A 风格）——成就**没有**「储物袋」那样的已定名容器概念，C 路线在此无对应物；退回库内既有的单数字段风格（`pastEvent` / `disabledAbility`，08-10c 明写），**零张力**。若日后全库统一把集合字段改为复数风格，本字段随那次统一一并改，不单独例外。
- **落点 3 处：** `systems/architecture.md`、`systems/services/life-cycle-service.md`、`ux/screen-flow.md` 的 `PlayerProfile` 字段清单 / 主菜单入口表。**分组成就的结构（组内加权进度、60% / 90% 两档奖励）不受影响**——这是纯标识符收口。

### 5. `pastEvent` 的类型漂移一并纠正（已裁决 · 08-12）

`[既有推演]` `systems/services/life-cycle-service.md` 的 `CharacterProfile` 字段清单仍写 `List<AdventureEvent>`，与 08-09c 的定案不符（存的是**定稿实例快照 + 本次结算的最终账**，不是 `Resource`）。改为 **`pastEvent: IReadOnlyList<PastEventEntry>`**，与 `systems/character-profile/_index.md` 的权威表述对齐。同一处的 `List<CharacterItems>` 一并按本方案改写，两处漂移一次收口。

### 6. 迁移与落地节奏

`[通行做法]` 无线上账号、无既有代码 ⇒ **纯文档改写，不 bump 存档 schema 版本、不需迁移路径**。这是把命名一次改到位的最便宜窗口；等 `CharacterProfile` 的存档字段进了线上账号再改，就要付一次迁移。

`[既有推演 → 已裁决]` 改写范围**只覆盖活文档**：`handoffs/`、`answer-logs/`、`inbox/archive/` 中的复数写法**不回改**——它们是带日期的当时意图快照，而「活文档只保留最新设计」的约定作用面是活文档。`terminology.md` 第 39 行里「（现有写法 `List<CharacterItems>`，单复数待统一）」整段删除，不留「原写法为 X」的考古。

## 具体形态（可 derive 的落地面）

裁决后的定稿形态：

```csharp
// 内容定义（content-service / ContentRegistry，共享只读单例）
ItemData { Id, Scope: AbilityScope, UsableScene, ManaCost?, Charges, Abilities, Rarity: RarityTier, Subtypes, ContentEnabled }

// 持有条目（存档态，落 CharacterProfile）
CharacterItem { string ItemId, Source SourceCode, int Charges, bool Status }   // 字段构成见「前置依赖」

// CharacterProfile 字段
List<CharacterItem> magicPack;   // 储物袋：上限 9（计数 = 按 ItemId 堆叠后的条目数）

// PlayerProfile 字段（连带收口）
List<Achievement> achievement;

// CharacterProfile 字段（连带纠正 08-09c 的类型漂移）
IReadOnlyList<PastEventEntry> pastEvent;
```

**待改写的活文档行（16 处）：**

| 文件 | 位置 | 现写法 |
|---|---|---|
| `terminology.md` | 第 39 行「法宝」条目 | `List<CharacterItems>`，单复数待统一 |
| `systems/character-profile/item/_index.md` | 顶部引言（第 3–4 行）、意图第 1 条、图鉴条、待决问题 | 4 处 |
| `systems/character-profile/item/common-properties.md` | 顶部引言、意图第 1 条 | 2 处 |
| `systems/character-profile/power/_index.md` | 意图「与 PlayerPower 的分界」、待决问题「与卡牌 / CharacterItems 的边界」 | 2 处 |
| `systems/architecture.md` | `CharacterProfile` 字段清单 | 1 处 |
| `systems/services/life-cycle-service.md` | `CharacterProfile` 字段清单 | 1 处 |
| `systems/services/_index.md` | 拆分轴论证第 2 条 | 1 处 |
| `systems/player-profile/codex/_index.md` | 图鉴族表格「CharacterItemCodex」行的对象列 | 1 处 |
| `ux/screen-flow.md` | 储物袋入口段落 | 1 处 |
| `systems/architecture.md` | `PlayerProfile` 字段清单 | `List<Achievements>` |
| `systems/services/life-cycle-service.md` | `PlayerProfile` 字段清单（含正文里并列的 `Achievements`） | `List<Achievements>` |
| `ux/screen-flow.md` | 主菜单入口表「Achievements(成就)」行 | `List<Achievements>` |
| `systems/services/life-cycle-service.md` | `CharacterProfile` 字段清单 | `List<AdventureEvent>` → `pastEvent: IReadOnlyList<PastEventEntry>` |

上述各处的法宝字段写法一律改为 **`List<CharacterItem> magicPack`**；`systems/services/life-cycle-service.md` 与 `ux/screen-flow.md` 各需在同一次改写里动两处（法宝 + 成就 / `pastEvent`）。

## 后果

- **存档 schema：** 字段名与元素类型名就此定稿；**无迁移**（无线上账号）。`CharacterProfile` 的字段清单在 `systems/character-profile/_index.md`、`architecture.md`、`life-cycle-service.md` 三处并存，改写须三处同步，否则漂移换个地方继续。
- **图鉴 / 置换 / 禁用三处的既有表述无需改动**——它们本就写单数，统一后反而自洽。
- **不影响任何已定决策的语义**：这是一次纯标识符收口，机制侧零改动。

**连带收口（08-12 裁决纳入本次范围）：**

1. **`List<Achievements>` → `List<Achievement> achievement`**（3 处）。同一缺陷类，推演同构；成就的分组结构与两档奖励不受影响。定名理由见方案 4。
2. **`life-cycle-service.md` 的 `List<AdventureEvent>` → `pastEvent: IReadOnlyList<PastEventEntry>`**（1 处）。补上 08-09c 定案未同步到的字段清单，与 `systems/character-profile/_index.md` 对齐。见方案 5。

**推论：`CharacterProfile` / `PlayerProfile` 的字段清单在三份文档里并存**（`character-profile/_index.md`、`player-profile/_index.md`、`architecture.md`、`life-cycle-service.md`），本次两处漂移都源于此。提炼时值得顺带在 `architecture.md` / `life-cycle-service.md` 的清单处标明「结构权威见 `systems/*-profile/`」——两处已有此标注，故不新增约定，只需确保改写后四处一致。

## 备选方案（已考虑并否决）

- **统一为复数 `CharacterItems`。** 否决：会逼四类里另三个也改成 `PlayerPowers` / `PlayerItems` / `CharacterPowers`（否则对称破裂），进而与 `XxxData` 单数命名族、`CharacterItemCodex`、`AbilityChangeElement.Kind` 全线冲突，且泛型参数位仍是双重复数。改一处 vs 改一片。
- **两种写法并存，靠上下文区分**（复数专指集合、单数专指条目）。否决：这正是当前状态，两个月里没有任何读者能从写法看出差别；`.claude/rules/Context.md` 的「贯穿整条链路的类型一致性」明确不容许同一概念在层间换形态。
- **另立 `CharacterItemEntry` / `MagicPackItem` 作为持有条目类型名。** 否决：与 08-03 已定名的 `CharacterItem` 冲突，并破坏四类持有条目的命名对称（另三类都不带后缀）。若日后确需区分「持有条目」与「内容定义」，分工已由 `ItemData` ↔ `CharacterItem` 承担，不必再加一层名字。

## 与既有决策的张力

**无。** 曾存在的唯一张力只在被否决的选项 B 下出现：08-10c 在 `disabledAbility` 处明写「单数命名，沿用 `pastEvent` 的既有风格」，而 B（`characterItems`，复数）会与之冲突。已取的 **C（`magicPack`）** 无单复数属性、成就字段取单数 `achievement`，两者均落在既有风格之内，08-10c 那句话原样保住。

## 前置依赖

- **`CharacterItem` 持有条目的字段构成**取决于 `systems/common-properties.md` 待决项「`SourceCode` 是否收窄到账号级两类」——若收窄，轮回级的 `CharacterItem` 不带 `SourceCode`。**该依赖只影响字段清单，不影响本草稿的命名结论**，命名可先定稿。

## 已裁决（2026-08-12）

| # | 项 | 裁决 |
|---|---|---|
| 1 | 集合字段名 | **C：`CharacterProfile.magicPack`，类型 `List<CharacterItem>`** |
| 2 | `List<Achievements>` | **一并收口** → `List<Achievement> achievement`（3 处） |
| 3 | 历史文档（`handoffs/` / `answer-logs/` / `inbox/archive/`） | **不回改** |
| 4 | `life-cycle-service.md` 的 `List<AdventureEvent>` 漂移 | **一并纠正** → `pastEvent: IReadOnlyList<PastEventEntry>` |
| 5 | 其余（统一为单数 · 三层分工 · 只改活文档 · 不 bump schema） | **按推荐定案** |

**仍需用户决定：无。** 本草稿可直接喂给 `/analyze-new-ideas`。
