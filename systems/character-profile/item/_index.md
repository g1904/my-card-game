# item

> **法宝 / CharacterItem** —— CharacterProfile 持有的、随单次轮回存在的道具（字段 `magicPack: List<CharacterItem>`），含道具设计内容。占位结构，细节待定。
> **中文定名 = 法宝**（08-03 定，取代「角色道具 / 角色物品」）；账号级的对应物是 **古宝 / PlayerItem**。**中文名不表达层级**。Source: `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md`。

**三层分工（已定案 · 08-12c · 承重）。** 「`CharacterItem` 指哪一层」一次写死，杜绝单复数漂移再长回来：

| 层 | 标识符 | 说明 |
|---|---|---|
| 内容定义（`Resource`，ContentRegistry 只读单例） | **`ItemData`** | 两层共用，`Scope == AbilityScope.Character` 者即法宝。**不存在 `CharacterItemData` 类型。** |
| 持有条目（存档态，落 `CharacterProfile`） | **`CharacterItem`** | 一份实例 = 集合的一个元素；带 `ItemId` / `Charges` / `status` 等，见 `common-properties.md`。 |
| 集合字段（`CharacterProfile` 上） | **`magicPack`**，类型 `List<CharacterItem>` | 储物袋本身：字段直接命名它承载的已定名概念，9 格上限与堆叠 / 筛选规则全部挂在它上面。 |
| 领域词 / 图鉴 | **法宝** / `CharacterItemCodex` | 本就是单数形态。 |

**通则：类型名恒为单数，复数只属于集合字段名。** Source: `handoffs/2026-08-12c-identifier-singular-collapse.md`。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **角色级道具随轮回存在。** CharacterProfile 通过 `magicPack: List<CharacterItem>` 持有，与账号级的 **PlayerItem**（`player-profile/player-item/`）区分开：CharacterItem 属单次轮回 / 单角色，随轮回清理；PlayerItem 跨轮回持久、有使用次数限制。Source: `handoffs/2026-07-24-docs-restructure-class-model.md`。

- **见过的角色道具会进 CharacterItemCodex。** 图鉴族（见 `../../player-profile/codex/`）为角色道具单列一本——**图鉴是账号级、跨轮回持久的**，而 `magicPack` 随轮回清理：轮回结束后道具没了，但「见过它」这条知识留下。解锁触发（获得即记？见到即记？）未定，见图鉴族的待决问题。Source: `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。

- **法宝在战斗内以 `CardType.Item` 呈现（已定案 · 08-04b · 承重）。** 它同时是「事件中使用的道具」与「战斗内的卡牌类型」——**这不是推翻，是补全**。战斗内的形态：
  - **不洗进卡组**，故**不受抽牌运制约**（「像精灵球一样随时可用」），也不占手牌位、不受满手影响；抽牌堆的 seeded 确定性完全不受道具影响。
  - **存于储物袋（`magic pack`）** —— 角色的道具容器，**跨战斗内外存在**、上限 **9**（计数单位 = **按 `ItemId` 堆叠后的条目数**，故同 `ItemId` 多份只占 1 格；这是一条真正会咬人的构筑取舍位，不是溢出防护）。**储物袋不是战斗概念**：战斗只从中筛出 `UsableScene` 含 `InCombat` 的那些，形成参战方持有的「本场可用道具」。**敌人没有储物袋但同样持有道具**（来自 `EnemyData`），正说明容器与本场视图必须分开。
  - **使用窗口 = 自己回合的行动阶段、栈为空时**，与出牌 / 启动式异能完全同窗口——**「随时」= 不受抽牌运制约，不是不受回合限制**，交互不回归。
  - **可带 mana 费用与异能**（以启动式为主），零费亦合法。
  - **消耗即时经 `ProfileManager.TryApply` 写 CharacterProfile**，不攒到收口。
  - **推论：道具的强度必须比同费法术低**——「确定性 + 不占手牌位 + 不受抽牌运」三重优势若再配同等强度，会让卡牌相形见绌。**折价系数已按 `Charges` 分层定案**，见下。

  Source: `handoffs/2026-08-04b-mtg-loanwords-card-types-and-intent-snapshot.md`。
- **同一 `ItemId` 的道具可以持有多份（已定案）。** 储物袋按 `ItemId` **堆叠显示 `×N`**，且**堆叠后只占 1 格**——这既让 9 格的容量上限在「重复持有」方向上完全不受限（取舍落在**种类数**上，正是设计意图所在），也让「同名道具满屏」的视觉噪音消失。**推论：`Charges` 是每一份实例各自的次数，不是「一个条目带一个总次数」。** **这正是集合元素类型必须是单数 `CharacterItem`（一份实例）而非「一条 Id 一行」的实证；按 `ItemId` 堆叠是呈现层的聚合，不是存储形态**（08-12c）。 Source: `handoffs/2026-08-06d-combat-open-questions-mass-closure.md`。
- **折价系数 `itemPowerRatio` 按 `Charges` 分层，不是单一常数（已定案）。** 判据一句话：**`道具的效果量 ≤ 同 ManaCost 法术的效果量 × itemPowerRatio(Charges)`**。
  - 三重优势逐项估价：不受抽牌运 **×1.40**（单张特定牌本场可用概率 ≈ 0.7）· 不占手牌位 **×1.10** · 使用时机确定 **×1.15** → 合计 ≈ ×1.77 → 等价折价 ≈ 0.57。
  - 但 **`Charges` 是一个反向修正**：次数越少，三重优势越不成立（只能用一次的道具，「不受抽牌运」只兑现一次）。故分层为 **-1（无限法宝）0.55 / ≥5 0.65 / 2–4 0.75 / 1（一次性）0.90**。
  - **这条分层让 monetization 的既定分工有了数字**：古宝（必有 `Charges`）落在 **0.75–0.90**，单次强度接近法术但总量被次数封死，正是「付费收益 = 关键时刻多几次转圜，而非永久变强」。单一常数会把**最该强的一次性古宝**削到与无限法宝同价。
  - **「不受抽牌运的溢价」写成公式而非常数**：`1 / P(本场见到该牌)`，`P` 由卡组规模与抽牌数算出，随二者调整自动跟随。
  - 系数表与前置依赖（「同费法术的效果量」本身仍待 ch1 数值标杆专场定出）见 `systems/balance.md`。
  Source: `handoffs/2026-08-06d-combat-open-questions-mass-closure.md`。
- **`ItemData` 的字段形态（08-04b · 08-10c 补 `Rarity` 与 `AbilityScope`）。** `Id` · `Scope: AbilityScope { Character, Player }`（决定持久层：CharacterProfile / PlayerProfile；`PowerScope` / `ItemScope` 已合并为单一 `AbilityScope`）· `UsableScene { InCombat, OutOfCombat, Both }`（**必填**，非 `InCombat` / `Both` 者不进战斗道具区）· `ManaCost`（可选，允许为 0）· `Charges`（使用次数；古宝必有，法宝可为「无限 = -1」）· `Abilities` · `Rarity: RarityTier`（**必填**，缺失 → `PushError`）· `Subtypes`。**使用窗口是全局规则，不是字段。** 校验：`UsableScene` 缺失 → `PushError`（默认值会让漏填的东西悄悄进战斗）；`Scope == Player` 时 `Charges > 0` → 否则 `PushError`。**`SourceCode`（授予来源）不在此列——它是持有条目的字段，不是内容定义的字段**（见 `common-properties.md`）。Source: 同上。

- **法宝可被「本轮回禁用」，也可被置换（已定案 · 08-10c）。** 禁用的统一判据是「截断在进入生效面那一步」（完整表见 `../power/_index.md`）：**法宝 ≈ 启动式异能**，故被禁用 = **不进「本场可用道具」列表**——储物袋里仍在、`Charges` 分毫不动，只是本轮回 / 本篇章 / 下一事件不可启动。**同 `ItemId` 多份按 `ItemId` 整体禁用**，不区分实例。「本场可用道具」的派生规则（按 `UsableScene` 筛储物袋）因此**加一条禁用过滤**。置换与法宝同池（`(Kind, Scope)` 全同 + 同 `Rarity` + 排除已持有），见 `../../player-profile/player-power/_index.md`。禁用表字段见 `../_index.md` 的 `disabledAbility`。Source: `handoffs/2026-08-10c-ability-disable-replacement-and-player-statistics.md`。

> 本文件夹为「每类角色道具 / 每份道具设计一个 Markdown」预留结构；具体语义见 `common-properties.md` 与待决问题。

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **角色级道具语义未设计（08-04b 部分落定）。** **已定：战斗内形态 = `CardType.Item`、储物袋、`UsableScene` 三档、`ItemData` 字段形态、消耗即时写 Profile**（见上）。**仍未设计**：道具的种类目录、战斗外的获取途径与效果、以及「什么该做成一张卡 / 一件道具 / 一个神通」的判据。
- **道具的获取途径与「什么该做成道具」的判据。** 战斗内形态与折价系数均已定案；**战斗外的获取途径**（哪些事件给、给几件）与**「什么该做成一张卡 / 一件道具 / 一个神通」的判据**仍未给。→ `systems/adventure-event/`、`systems/balance.md`。

- **储物袋满时获得新道具的处理（08-11c 新增 · 承重）。** 上限收紧到 9 格后，「满袋再获得一件」从理论情形变成常态：拒收？强制择一丢弃？还是在奖励侧就过滤掉？连带**道具的获取频率、商店库存深度与置换对价是否需要同步下调**——这些此前都建立在容量近乎无限的前提上。→ 本文档、`systems/adventure-event/exchange/`、`systems/balance.md`。

> **储物袋的 UI 形态已定案**（不进主菜单、滚动网格 + 筛选 chip、战斗内视图称「随身」= 角标 + 底部抽屉），见 `ux/screen-flow.md` 与 `ux/combat-ux.md`。**9 格一屏可见，筛选 chip 的必要性下降**，排布待 UX 侧回归。

## 对应
提炼至：`.claude/knowledge/systems/character-profile/item/`（待建）。
