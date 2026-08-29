---
type: draft
date: 2026-08-23
topic: 货币体系拆分（灵石 spiritStone = 基础货币 · 仙玉 immortalJade = 高阶货币）
targets: terminology.md · systems/character-profile/currency.md · systems/balance.md · systems/architecture.md · systems/adventure-event/exchange/
status: distilled
reviewed: 2026-08-25 批量 interview 四项待决全部答定（见文末裁决记录）
distilled-to: handoffs/2026-08-25-currency-split-spirit-stone-and-immortal-jade.md
---

# 定案草稿 — 货币体系拆分

> 原始想法记于 2026-08-23（草稿中首次出现「仙玉」一词），经 2026-08-24 设计讨论裁决：非笔误，而是引入双层货币。2026-08-25 批量 interview 答定全部四项细部。

## 定案

### 1. 货币拆分为两层
`[用户拍板]`
- **灵石 `spiritStone`** —— 基础货币。承接原「灵玉（jade）」的角色：轮回级软通货、主要花销在 Exchange。
- **仙玉 `immortalJade`** —— 高阶货币，**轮回级**（随轮回清理，归 `CharacterProfile`）。

原定名「灵玉（jade）」整体退役，`jade` 这个标识符不再指代任何东西。

### 2. 仙玉是轮回级（08-25 裁定）
归 `CharacterProfile`，随轮回清理。
- 落点：`CharacterProfile` 字段表新增一行；`CostKey` 由 15 值增至 16 值（注释同改）；`ResourceElements` 轮回层加一行；`systems/character-profile/currency.md` 扩为双币文档。
- **不触碰**「本作没有账号级可支配货币」这条取向的任何一处承载——`player-profile/player-power/_index.md`「为何不是货币：可支配的货币会引入第二套账号级经济」· `systems/monetization.md` 的付费面排除表「消耗型货币 / 硬通货」一行与空池处置的否决项 · `decisions/ADR-0023`（Accepted）的否决理由。四处零改动，ADR-0023 不动。
- 依据：同一场 08-24 评审的 `draft-0823e` 刚援引这条取向去否决「古宝可售」，说明它在用户手里仍生效；且账号级路线要从零设计获取 / 囤积 / 兑换 / 定价四件事并新增通胀护栏，而轮回级路线只是「照灵石的行再加一行」。
- **回填给 `draft-0823e`：** 仙玉的非战斗查看落点定为**储物袋**这一单一落点（原稿「储物袋 / 元界面」两义，元界面是 PlayerProfile 级，与轮回级仙玉不符）。

### 3. 获取与花销通道（08-25 按唯一自洽组合定案）
- **获取 = 稀有 AdventureEvent 产出。** 走既有 `OutcomeSpec.Elements` 路径，零新机制；`systems/services/future-event-service.md` 的合法子集表加一格（该表现为 `LifeTotal · ManaLimit · Jade` 三项开 ✅）。
- **花销 = 高阶 Exchange 商品。** Exchange 全套已成文（`ExchangeGoodsKind` 五族 · 「族 × 稀有度」定价表 · `CanAfford` / `TryApply` 单条 pipeline），加一种支付币种是在既有表上加一列。
- **被排除的选项及理由：** 付费获取 → 会造出一条可反复付费的消耗型硬通货，撞穿 `monetization.md`「当前只有一个付费点：premium bundle、买断式一次授予」的排除表；成就奖励 → 成就是账号级，产出轮回级货币构成跨层输血；Finale 产出 → 轮回级下在篇章收口处发放、随后即被清理，价值可疑；特殊置换花销 → 置换对象是账号级资产，用轮回级仙玉支付即跨层输血，正是 `draft-0823e` 刚否掉的那件事；新事件类型 → `eventType` 是五值封闭枚举，牵动物化链与 `AdventureEventData` 全套字段。
- **仙玉的「高阶」由稀有度与价格量级表达，不由新机制表达。**

### 4. 兑换关系：完全不可兑换（08-25 定案）
灵石与仙玉之间不设任何单向或双向兑换。`systems/character-profile/currency.md` 写一条正面纪律，零机制。理由即草稿自陈的那条——可兑换会使双层退化为单层加一个汇率；且与「禁止跨层兑换以防清仓换经济成为最优解」的同款论证结构一致。

### 5. 代码定名：`jade` 整体退役（08-25 定案）
灵石 = `spiritStone`，仙玉 = `immortalJade`。`CostKey.Jade` → `CostKey.SpiritStone`，`CharacterProfile.jade` → `.spiritStone`。
- **改名波及实测（Grep `jade|灵玉`）：全库 78 份文件 237 处。** 需回改的**活文档 31 份约 91 处**，最密集处：`exchange/_index.md`(14) · `currency.md`(7) · `exchange/common-properties.md`(6) · `architecture.md`(5，含 `CostKey` 枚举与 `ResourceElements` 注释) · `profile-service.md`(5) · `future-event-service.md`(5) · `balance.md`(5) · `mana.md`(4) · `research/_index.md`(4) · `ADR-0022`(4) · `ADR-0020`(3) · `adventure-event/common-properties.md`(3，含 `ResourceKey` 校验集合) · `terminology.md`(整行替换) · `ux/screen-flow.md`(角色状态条 ASCII 图) · `ux/error-and-blocking-ux.md` 等。
- **不回改**：`handoffs/` · `inbox/archive/` · `answer-logs/` · `update-log-archive.md` 等过程档案共约 146 处（历史归 git）。
- **库外**：`.claude/knowledge/` 3 处（`dictionary.md` · `systems/_index.md` · `scenes/_index.md`）归 `/sync-knowledge`，不由本次改。
- **明确否决的方案：** 把 `jade` 改派给仙玉——现存 91 处 `Jade`/`jade` 全部指基础货币，改派后每一处未改到的引用都静默变成错的意思且无任何机制发现，与 `data-resource-rules.md` 的稳定 `Id` 纪律直接相抵。

## 后果
- `terminology.md`：删「灵玉 | jade」整行，新增「灵石 | `spiritStone`」与「仙玉 | `immortalJade`」两行。
- `systems/character-profile/currency.md`：改名 + 扩为双币文档（含不可兑换纪律 + 仙玉的数值面阻塞登记）。
- `systems/character-profile/_index.md` · `systems/architecture.md`：字段表与 `CostKey` / `ResourceElements` 加行改名。
- `systems/services/future-event-service.md`：合法子集表加仙玉一格。
- `systems/adventure-event/exchange/`：改名 + 高阶商品以仙玉计价的支付币种口径。
- `systems/balance.md`：改名 + 仙玉定价的分格说明。
- 其余约 15 份活文档：纯改名。
- `systems/monetization.md` / `ADR-0023` / `player-power/_index.md`：**仅改名，不改语义**（轮回级路线不触碰账号级经济那条取向）。

**仙玉沿用灵石的既有语义：** 取值域 `[0, ∞)`、归 0 不构成终态、`ResourceElements` 行 `(0, null, null, null, null, Add)`、两个修正列恒 `null`、不设篇章维涨价。`DefeatReason` 三值封闭，新增货币不承载终态语义。

## 与既有决策的张力
- 「避免引入第二套账号级经济」：仙玉定为轮回级后**无冲突**，四处权威与 ADR-0023 全部零改动。

## 前置依赖
无。**下游依赖：** `draft-0823e` 的储物袋售出所得与仙玉查看落点须采用本稿的定名与层级。

## 仍待答（不阻塞落笔）
- **仙玉的获取量与花销价格未设计** —— 形态定后仍欠取值，与既有的「灵石（原 jade）获取渠道与掉落权重整体未设计（承重）」同归内容扩充后的统计校准；两者互相约束（双币经济的相对价值由两条产出曲线共同决定）。灵石那一半的空白**不因本稿答定而移出**。

## interview 裁决记录（2026-08-25 批量）

- **仙玉的层级** → 轮回级（归 `CharacterProfile`）；同时回填 `draft-0823e` 的查看落点为单一的「储物袋」。
- **代码定名** → `jade` 整体退役，灵石 = `spiritStone`，仙玉 = `immortalJade`。
- 标准默认（未出题，直接采纳）：获取 = 稀有事件产出、花销 = 高阶 Exchange（层级定下后其余组合均构成跨层输血或撞穿付费面排除表，唯一自洽）；兑换关系 = 完全不可兑换；「灵玉 → 灵石」的纯改名部分不依赖任何其他裁决；仙玉的 `ResourceElements` 行按灵石同款起草。
