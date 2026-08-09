---
type: solution-draft
date: 2026-08-09
question: `PlayerPowerFragment.FinaleWinOrdinal`（规则输入 · 幂等键）与账号级统计计数中的「总通关数」（纯读数）如何划清边界，使二者不被当成重复字段合并？
source: open-questions/06-meta-progression.md → 「`FinaleWinOrdinal` 与账号级统计计数的边界（08-09b 新增）」
targets: systems/player-profile/_index.md, systems/services/life-cycle-service.md, systems/services/sync-service.md, terminology.md
status: distilled
decided: 2026-08-09（用户裁定三项取向：通关口径 = 整轮回 · 展示渡劫成功次数且直读 `FinaleWinOrdinal` · `Ordinal` 命名约定立为硬约定）
---

# 方案草稿 — `FinaleWinOrdinal` 与账号级统计计数的边界

> **状态：已裁决，无剩余待决项。** 原三项取向选择已由用户于 2026-08-09 全部裁定，正文已按裁定结果改写为定稿口径；裁决记录见文末。可直接喂给 `/analyze-new-ideas`。

## 问题

08-09b 定案：道统残卷的状态落 `PlayerProfile.PlayerPowerFragment`，其中 `FinaleWinOrdinal` 是**账号级 Finale 胜利序号**，单调递增、不清零，**同时是掷骰的幂等键**（`roll = Hash64(AccountSeed, FinaleWinOrdinal) mod 10000`）。

08-06b 另立了一类新字段族——**账号级统计计数**（纯读数，首项为篇章重试的跨角色累计）。它的字段形态与首批统计项仍待答（`open-questions/01-combat.md`）。

悬着的是**两者的接壤处**：统计侧几乎必然会出现一个叫「总通关数」/「渡劫成功次数」的读数，与 `FinaleWinOrdinal` 口径相近。一旦被当成重复字段合并掉，**掷骰的幂等性就挂在了一个「被篡改也无所谓、可走宽松同步口径」的字段上**——防篡改与防重掷两条纪律同时失效，且失效是静默的（合并当天不会有任何症状）。

本草稿只答这条边界，不定统计计数的容器形态与完整统计项清单（那是 `01-combat.md` 的另一条，见「前置依赖」）。

## 约束（来自既有设计）

- **`FinaleWinOrdinal` 的语义已固定**：只在 **Finale 胜利**时 +1；Finale 失败、以及 1% 的「失败但存活」分支**都不自增**。同时是幂等键——同一序号重复结算得同一结果。Source: `handoffs/2026-08-09b-player-power-fragment-finale-bound-drop-chance.md` §5 / §7。
- **08-06b 的分层判据已立**：**参与规则判定的字段与纯读数的统计计数分属两层**；08-09b 已据此把 `PlayerPowerFragment` 排除在统计计数之外。Source: `systems/player-profile/_index.md`。
- **单一真值纪律**：派生量不落字段（`x = List<PlayerPower>.Count` 不落字段；`CapabilitiesChanged` 空负载、订阅者自行重查）。Source: 同上。
- **云端权威**：`revision` 由后端分配，冲突一律以云端为准，不做字段级三路合并（`ADR-0003` + `sync-service.md`）。
- **后端可离线复算任一次掷骰**：`AccountSeed` 在后端，`FinaleWinOrdinal` 与命中结果随 profile 上行。Source: `systems/player-profile/account-info.md`。
- **1% 分支的推进语义**：Finale 失败但 `lifeTotal` 未打穿 ⇒ **篇章照常完成、境界照常突破**。这条使「篇章完成」与「Finale 胜利」**在事实上就是两个不同的数**。

## 建议方案

### 1 · 把 08-06b 的判据升格为一条明写的**分层通则**，并补上「合并判据」

`[既有推演]` 08-06b / 08-09b 已两次用到同一条判据，但每次都是就事论事地写在具体字段旁。建议在 `systems/player-profile/_index.md` 立一个小节，把它写成**账号级字段的通则**：

> **账号级字段分两层，判据是「它有没有被规则读」：**
>
> | | **规则字段层** | **统计计数层** |
> |---|---|---|
> | 判据 | 被任何判定 / 闸门 / 幂等键读取 | 只被 UI 读来展示 |
> | 例 | `PlayerPowerFragment.*`、`CharacterProfile.chapterRetry` | 篇章重试的跨角色累计、总轮回数 |
> | 同步口径 | 严格：随 profile diff 上行，**后端可复算校验** | 宽松：被篡改无玩法后果 |
> | 读档校验 | 越界钳制 + 告警；**不由历史重建** | 告警即可，不阻塞、不修复 |
> | 篡改后果 | 直接改变发不发一条法则 / 还剩几次重试 | 只是数字不好看 |

并补上**合并判据**（这是本次真正缺的一条）：

> **两个字段口径相近不构成合并理由。可以合并，当且仅当「语义 + 同步口径 + 篡改后果」三者全同。** 跨层的两个字段**永远不满足**这条——它们的同步口径与篡改后果按定义就不同。

理由：08-09b 的开放问题描述的风险不是「有人故意合并」，而是**后来者看到两个都叫「Finale 胜利次数」的整数，理所当然地去重**。把判据写成通则并给出反向的「何时才能合并」，才是可被后来者主动执行的纪律；只写一句「注意别合并」会在半年后失效。

### 2 · 统计侧**不设**「Finale 胜利数」字段；展示时直读 `FinaleWinOrdinal`（已裁定）

`[既有推演]` + **用户裁定（08-09）：渡劫成功次数向玩家展示，且直读 `FinaleWinOrdinal`，不新增统计字段。**

这是最强的防合并手段——不靠注释提醒，而是**让重复字段从一开始就不存在**。

- 「你渡劫成功了几次」的展示数据源 = `PlayerProfile.PlayerPowerFragment.FinaleWinOrdinal`，**统计计数层不持有这个数**。依据是既有的单一真值纪律（与「`x` 不落字段」同款）：落字段即制造第二份真值，而这份真值恰好是幂等键。
- **依赖方向是单向的**：规则字段层**可以**被统计 / UI 层读取展示；统计计数层**绝不可**被任何规则读取。这条写进通则，同时防住反向的错误（哪天有人拿统计计数去做闸门输入）。
- **展示不改变分层**：被 UI 读到不会把 `FinaleWinOrdinal` 变成统计计数——判据是「有没有被**规则**读」，它仍是规则字段层，同步与校验一律走严格口径。
- 展示口径的一句注解（呈现措辞归 `ux/`）：`FinaleWinOrdinal` 计的是**渡劫成功**次数，1% 的「失败但存活」不计入——因此它可能小于已完成的篇章数，这个差值本身是有味道的信息，不是 bug。

### 3 · 统计侧的「通关」= **完成整个轮回**（已裁定），与 `FinaleWinOrdinal` 数值天然不等

`[通行做法]` + `[既有推演]` + **用户裁定（08-09）：采用整轮回口径（原选项 A），不设「篇章完成数」统计项。**

- **「通关」= 完成整个轮回**（三篇章全通、抵达元婴），字段 **`TotalCyclesCompleted`**。与 roguelike 通行口径一致（一次 run 一次胜利：Slay the Spire 的 victory count、Balatro 的 wins）。
- 一次完整通关贡献 **3 次** Finale 参与，其中 Finale 胜利数 ≤ 3（1% 分支下可以只有 2 次胜利却仍完成三个篇章）。
- 因此 **`TotalCyclesCompleted` 与 `FinaleWinOrdinal` 在任何账号上都不相等**（除极端巧合），二者放在同一张字段表里也不会看起来像同一个数。**这条比任何注释都可靠。**
- **不设 `TotalChaptersCompleted`**（原选项 C 未采用）：它与 `FinaleWinOrdinal` 只差 1% 分支的那一点，数值几乎恒等，恰好是最容易被误合并的形态。若日后统计面板确需「篇章进度」读数，须独立命名并**明写它计入 1% 的「失败但存活」分支**，且照样受 §1 的合并判据约束。

### 4 · 命名硬约定：`Ordinal` 后缀保留给规则序号 / 幂等键（已裁定）

`[既有推演]` + `[通行做法]` + **用户裁定（08-09）：立为硬约定。**

- **规则序号 / 幂等键** → `...Ordinal`（语义是「第几次」，是一个**位置**，不是一个**数量**）。
- **统计读数** → `Total...`（或 `...Count`），语义是「一共多少」。
- **统计计数层不得使用 `Ordinal` 后缀**；`Ordinal` 出现即意味着「有人用它当键」。
- 约定成本为零、可机械检查：`/derive-requirements` 与 code review 阶段可直接按后缀核对字段所属层。当前库内只有 `FinaleWinOrdinal` 一个 `Ordinal`，零迁移成本。
- `terminology.md` 补一行「Finale 胜利序号 / `FinaleWinOrdinal`」，明写它**不是**通关数统计（或在道统残卷条目内补这一句）。

### 5 · 同步与校验：差别只体现在口径，不体现在写入路径

`[既有推演]` 不为统计计数另开写入通道——两层都经 `ProfileManager.TryApply` 的同一次事务写入（既定的「唯一写入面」）。差异只在两处：

- **同步权威性**：规则字段随 `CharacterProfile` diff 严格上行、后端可复算；统计计数**可容忍丢失与最终一致**（宽松口径的具体形态归 `01-combat.md` 那条，本草稿只主张「它落在宽松侧」）。
- **读档校验**：`FinaleWinOrdinal` 沿用 08-09b 已定的「不由通关史重建」；**且明确不做两层之间的交叉一致性校验**——写一条「`FinaleWinOrdinal` 应约等于统计通关数」的校验，等于在代码里承认它们该相等，是把已排除的合并从后门放回来。

## 具体形态（可 derive 的落地面）

| 层 | 字段 | 类型 | 何时变 | 被规则读 | 被 UI 读 | 同步口径 | 读档校验 |
|---|---|---|---|---|---|---|---|
| 规则 | `PlayerPowerFragment.FinaleWinOrdinal` | `int` | **仅 Finale 胜利** +1 | **是**（掷骰幂等键） | **是**（渡劫成功次数） | 严格 · 后端可复算 | 不由历史重建；单调性被破坏 → `GD.PushError` |
| 统计 | `TotalCyclesCompleted` | `int` | 轮回完成（三篇章全通 · 抵达元婴）+1 | 否 | 是（总通关数） | 宽松 | 告警不阻塞、不修复 |
| —— | ~~`TotalFinaleWins`~~ | —— | **不设**：直读 `FinaleWinOrdinal` | —— | —— | —— | —— |
| —— | ~~`TotalChaptersCompleted`~~ | —— | **首批不设**（与 ordinal 数值几近恒等） | —— | —— | —— | —— |

命名硬约定（可机械检查）：

```
后缀 Ordinal  ⇒ 规则字段层，参与判定 / 幂等键，严格同步
前缀 Total    ⇒ 统计计数层，纯读数，宽松同步
统计计数层禁用 Ordinal 后缀
```

不变式（写进 `player-profile/_index.md` 作为**说明**，解释「为什么它们不是同一个数」）：

```
FinaleWinOrdinal ≥ TotalCyclesCompleted × 3 - (失败但存活的次数)
TotalCyclesCompleted × 3 ≥ FinaleWinOrdinal 不成立         // 可只通一章反复胜利
```
更简明的说法：**一次通关贡献 3 次 Finale 参与、至多 3 次胜利；而 Finale 胜利可以完全不伴随通关。** 二者不存在固定倍率关系，**不作为读档校验实现**（见 §5）。

日志：统计计数变更不单独打日志（纯读数，无诊断价值）；`FinaleWinOrdinal` 的变更已由 08-09b 的 `[LifeCycle-FinaleResolve] ... ordinal={o} ...` 覆盖。

## 后果

- `systems/player-profile/_index.md` 新增「账号级字段的两层与合并判据」小节（含命名硬约定）；`## 待决问题` 里 08-09b 追加的那条边界要求可移除。
- `systems/services/life-cycle-service.md` 的统计计数待决条目**范围收窄**：只剩「容器形态 + 首批统计项清单 + 宽松同步的具体形态」，边界一问不再挂在它上面；且首批统计项已确定**含 `TotalCyclesCompleted`、不含 Finale 胜利数与篇章完成数**。
- `sync-service.md` 需要一句：**统计计数走宽松口径不影响规则字段的严格上行**，二者在同一次 diff 里但校验强度不同。
- `terminology.md` 补一行 `FinaleWinOrdinal`（明写 ≠ 通关数）。
- `ux/` 侧多一处数据源指向：玩家档案界面的「渡劫成功次数」读 `FinaleWinOrdinal`、「总通关数」读 `TotalCyclesCompleted`；两个数并列展示且**允许不相等**，措辞不得暗示二者应当一致。
- **存档 schema 不受本草稿影响**：`FinaleWinOrdinal` 已在 08-09b 的 bump 里；`TotalCyclesCompleted` 的 bump 归统计计数形态那条问题。
- `open-questions/06-meta-progression.md` 的该条目可移出，剩余 2 条（进度感、1% 分支叙事补白）不受影响。

## 备选方案（已考虑并否决）

- **统计侧照常设 `TotalFinaleWins`，靠注释 / 文档说明「它与 `FinaleWinOrdinal` 不同」** — 否决：两者取值恒等（都只在 Finale 胜利时 +1），**它们本就是同一个数的两份拷贝**，注释救不了。真正的问题不是「说明不足」，而是不该存在这个字段。
- **「通关」按篇章计（原选项 B）** — 否决：与 `FinaleWinOrdinal` 只差 1% 分支，数值几乎恒等，是最容易被合并的形态。
- **通关数与篇章完成数都要（原选项 C）** — 未采用：信息更全，但为了一个次要读数重新引入「与 ordinal 几近恒等的整数」，与本条边界要解决的问题正面冲突。日后如确需，按 §3 末尾的约束加。
- **把 `FinaleWinOrdinal` 移进统计计数容器，另立一个纯幂等键（如 `LastRollSeq`）** — 否决：把一个数拆成两个仍需保持同步，幂等性变成两个字段的一致性问题，比现状更脆；且违背 08-06b / 08-09b 已两次采用的分层判据。
- **改用 `Hash64(AccountSeed, chapterId, characterId)` 之类的复合幂等键，彻底不需要序号** — 否决：同一角色同一篇章只有一次 Finale，看似可行，但**跨轮回重开同一篇章**会得到同一个 key ⇒ 同一账号在不同轮回的同章掷骰结果恒等，玩家可观测到「这章永远不掉」。单调序号没有这个性质。
- **加一条读档交叉校验 `FinaleWinOrdinal ≈ 统计通关数`** — 否决：见 §5，等于在实现层重新宣称二者应当相等。

## 与既有决策的张力

**无。** 本草稿完全建立在 08-06b 的分层判据与 08-09b 的字段定案之上，不触及 ADR-0003 / ADR-0004，不改变 `PlayerPowerFragment` 的任何既定语义，也不改 push 粒度与存档点清单。

唯一的**新增约束**是 `Ordinal` 命名硬约定——它对现有文档零冲突（当前库内只有 `FinaleWinOrdinal` 一个 `Ordinal`）。

## 前置依赖

- **账号级统计计数的字段形态与范围**（`open-questions/01-combat.md` · `life-cycle-service.md`）：容器落 `PlayerStatistics` 类还是直接挂字段、首批统计项完整清单、宽松同步的具体形态。本草稿**不依赖它定稿**——分层通则、不设 Finale 胜利数字段、命名硬约定、`TotalCyclesCompleted` 的口径四条与容器形态无关；容器一旦定型，`TotalCyclesCompleted` 按其形态落位即可。
- 若「通关」的中文定名（通关 / 飞升 / 圆满）需要与 `terminology.md` 的修真词表对齐，归术语侧，不影响本草稿的结构主张。

## 仍需用户决定

**无。** 原三项取向已于 2026-08-09 由用户全部裁定：

| 原取向项 | 裁定 |
|---|---|
| 统计侧「通关」口径 | **(A) 完成整个轮回**（`TotalCyclesCompleted`）；不设篇章完成数 |
| 是否展示「渡劫成功次数」 | **展示，直读 `FinaleWinOrdinal`**，不新增统计字段 |
| `Ordinal` 命名约定 | **立为硬约定**（统计计数层禁用 `Ordinal` 后缀） |
