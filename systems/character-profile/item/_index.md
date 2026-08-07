# item

> **法宝 / CharacterItem** —— CharacterProfile 持有的、随单次轮回存在的道具（现有写法 `List<CharacterItems>`），含道具设计内容。占位结构，细节待定。
> **中文定名 = 法宝**（08-03 定，取代「角色道具 / 角色物品」）；账号级的对应物是 **古宝 / PlayerItem**。**中文名不表达层级**。**标识符的单复数待统一**（`CharacterItem` vs `CharacterItems`），见待决问题。Source: `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md`。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **角色级道具随轮回存在。** CharacterProfile 持有 `List<CharacterItems>`（角色物品），与账号级的 **PlayerItem**（`player-profile/player-item/`）区分开：CharacterItems 属单次轮回 / 单角色，随轮回清理；PlayerItem 跨轮回持久、有使用次数限制。Source: `handoffs/2026-07-24-docs-restructure-class-model.md`。

- **见过的角色道具会进 CharacterItemCodex。** 图鉴族（见 `../../player-profile/codex/`）为角色道具单列一本——**图鉴是账号级、跨轮回持久的**，而 `List<CharacterItems>` 随轮回清理：轮回结束后道具没了，但「见过它」这条知识留下。解锁触发（获得即记？见到即记？）未定，见图鉴族的待决问题。Source: `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。

- **法宝在战斗内以 `CardType.Item` 呈现（已定案 · 08-04b · 承重）。** 它同时是「事件中使用的道具」与「战斗内的卡牌类型」——**这不是推翻，是补全**。战斗内的形态：
  - **不洗进卡组**，故**不受抽牌运制约**（「像精灵球一样随时可用」），也不占手牌位、不受满手影响；抽牌堆的 seeded 确定性完全不受道具影响。
  - **存于储物袋（`magic pack`）** —— 角色的道具容器，**跨战斗内外存在**、上限 **99**（≈ 不设限，仅防溢出）。**储物袋不是战斗概念**：战斗只从中筛出 `UsableScene` 含 `InCombat` 的那些，形成参战方持有的「本场可用道具」。**敌人没有储物袋但同样持有道具**（来自 `EnemyData`），正说明容器与本场视图必须分开。
  - **使用窗口 = 自己回合的行动阶段、栈为空时**，与出牌 / 启动式异能完全同窗口——**「随时」= 不受抽牌运制约，不是不受回合限制**，交互不回归。
  - **可带 mana 费用与异能**（以启动式为主），零费亦合法。
  - **消耗即时经 `ProfileManager.TryApply` 写 CharacterProfile**，不攒到收口。
  - **推论：道具的强度必须比同费法术低**——「确定性 + 不占手牌位 + 不受抽牌运」三重优势若再配同等强度，会让卡牌相形见绌。**折价系数已按 `Charges` 分层定案**，见下。

  Source: `handoffs/2026-08-04b-mtg-loanwords-card-types-and-intent-snapshot.md`。
- **同一 `Id` 的道具可以持有多份（已定案）。** 储物袋按 `Id` **堆叠显示 `×N`**，这既让 99 的容量上限实质上更宽裕，也让「同名道具满屏」的视觉噪音消失。**推论：`Charges` 是每一份实例各自的次数，不是「一个条目带一个总次数」。** Source: `handoffs/2026-08-06d-combat-open-questions-mass-closure.md`。
- **折价系数 `itemPowerRatio` 按 `Charges` 分层，不是单一常数（已定案）。** 判据一句话：**`道具的效果量 ≤ 同 ManaCost 法术的效果量 × itemPowerRatio(Charges)`**。
  - 三重优势逐项估价：不受抽牌运 **×1.40**（单张特定牌本场可用概率 ≈ 0.7）· 不占手牌位 **×1.10** · 使用时机确定 **×1.15** → 合计 ≈ ×1.77 → 等价折价 ≈ 0.57。
  - 但 **`Charges` 是一个反向修正**：次数越少，三重优势越不成立（只能用一次的道具，「不受抽牌运」只兑现一次）。故分层为 **-1（无限法宝）0.55 / ≥5 0.65 / 2–4 0.75 / 1（一次性）0.90**。
  - **这条分层让 monetization 的既定分工有了数字**：古宝（必有 `Charges`）落在 **0.75–0.90**，单次强度接近法术但总量被次数封死，正是「付费收益 = 关键时刻多几次转圜，而非永久变强」。单一常数会把**最该强的一次性古宝**削到与无限法宝同价。
  - **「不受抽牌运的溢价」写成公式而非常数**：`1 / P(本场见到该牌)`，`P` 由卡组规模与抽牌数算出，随二者调整自动跟随。
  - 系数表与前置依赖（「同费法术的效果量」本身仍待 ch1 数值标杆专场定出）见 `systems/balance.md`。
  Source: `handoffs/2026-08-06d-combat-open-questions-mass-closure.md`。
- **`ItemData` 的字段形态（08-04b）。** `Id` · `Scope: ItemScope { Character, Player }`（决定持久层：CharacterProfile / PlayerProfile）· `UsableScene { InCombat, OutOfCombat, Both }`（**必填**，非 `InCombat` / `Both` 者不进战斗道具区）· `ManaCost`（可选，允许为 0）· `Charges`（使用次数；古宝必有，法宝可为「无限 = -1」）· `Abilities` · `Subtypes`。**使用窗口是全局规则，不是字段。** 校验：`UsableScene` 缺失 → `PushError`（默认值会让漏填的东西悄悄进战斗）；`Scope == Player` 时 `Charges > 0` → 否则 `PushError`。Source: 同上。

> 本文件夹为「每类角色道具 / 每份道具设计一个 Markdown」预留结构；具体语义见 `common-properties.md` 与待决问题。

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **`CharacterItem` 的标识符单复数不一致（08-03 新增）。** 中文定名「法宝」对应 `CharacterItem`（单数），但全库既有写法是 `List<CharacterItems>`（复数）。是否统一为 `CharacterItem` 未定。→ `terminology.md`。Source: `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md`。
- **角色级道具语义未设计（08-04b 部分落定）。** **已定：战斗内形态 = `CardType.Item`、储物袋、`UsableScene` 三档、`ItemData` 字段形态、消耗即时写 Profile**（见上）。**仍未设计**：道具的种类目录、战斗外的获取途径与效果、以及「什么该做成一张卡 / 一件道具 / 一个神通」的判据。
- **道具的获取途径与「什么该做成道具」的判据。** 战斗内形态与折价系数均已定案；**战斗外的获取途径**（哪些事件给、给几件）与**「什么该做成一张卡 / 一件道具 / 一个神通」的判据**仍未给。→ `systems/adventure-event/`、`systems/balance.md`。

> **储物袋的 UI 形态已定案**（不进主菜单、滚动网格 + 筛选 chip、战斗内视图称「随身」= 角标 + 底部抽屉），见 `ux/screen-flow.md` 与 `ux/combat-ux.md`。

## 对应
提炼至：`.claude/knowledge/systems/character-profile/item/`（待建）。
