---
type: solution-draft
date: 2026-08-26
question: 战斗随机到底走几条 RNG 子流？「敌人抽牌走独立子流」「不在 `combat` 子流上再派生一层」「子流常量清单只有 map / combat / shop / reward 四条」三句不能同时成立，需裁一句。
source: open-questions/01-combat.md → 内容与数值的残留 →「`combat` 子流的三句互相矛盾（08-25 采集）」
targets: systems/services/combat-service.md · systems/character-profile/deck/_index.md · systems/enemies/common-properties.md · systems/services/life-cycle-service.md · systems/common-properties.md
status: distilled
reviewed: 2026-08-26 — 裁决 A（单一 `combat` 子流、其上不派生任何层）；连带删除 `Hash64(combatStreamSeed, eventId)` 派生层；不同批开「卡牌效果重洗牌库」的口子，该空白改为登记成新待答项。
distilled-to: handoffs/2026-08-26b-combat-substream-arbitration.md
---

# 方案草稿 — `combat` 子流的三句互相矛盾

## 问题

全库对「战斗内随机走几条流、怎么派生」有互不相容的多处表述。清单登记为三句，**实际落笔处有五句、横跨四份文档**：

| # | 出处 | 原话（要点） |
|---|---|---|
| ① | `systems/services/combat-service.md`「确定性」 | **敌人抽牌走与玩家抽牌不同的子流**，使玩家侧的一次额外抽牌不打乱敌人牌序 |
| ② | `systems/services/combat-service.md`「确定性」 | 派生形态 = **`Hash64(combatStreamSeed, eventId)`，就这一层** |
| ③ | `systems/services/combat-service.md`「战斗内随机的状态不落本块」 | 战斗内随机**直接用 `combat` 子流、不在其上再派生一层**，故不存在第二个随机源 |
| ④ | `systems/services/life-cycle-service.md`（SeedManager）· `systems/common-properties.md` · `systems/character-profile/_index.md` 的 `rng.stream[]` schema | 子流清单是 SeedManager 内的常量，**恰四条：map / combat / shop / reward** |
| ⑤ | `systems/character-profile/deck/_index.md`（敌人卡组）· `systems/enemies/common-properties.md` | 敌人抽牌**走独立的战斗 RNG 子流**（重复 ①，另两份文档各一份副本） |

①⑤ 与 ③④ 直接互斥；② 与 ③ 在**同一份文档内**互斥（②「派生一层」vs ③「不派生任何层」）。

**它卡住了什么。** 就绪度台账把它记为第 12、20 两步 derive 的**硬前置**：它决定 `RngStream` 枚举有几个成员、`rng.stream[]` schema 是几条、以及**确定性验收标准怎么写**（「同一 seed 复现同一场战斗」要断言的到底是一条流的 `State` 还是两条）。

## 约束（来自既有设计）

- **`ADR-0033`** — 确定性只到同一 `contentVersion` 内；RNG 以 `State` + `DrawCount` 双字段持久化。
- **`ADR-0036`** — 事件过程按决策点落存档；退出重进得到同一局面与同一份 RNG 状态。**重掷窗口已由结构关死，不靠子流隔离去堵。**
- **`ADR-0052` / `combat-service.md` 推论 ④** — 抽牌堆不重洗；**`DeckModule` 没有重洗代码路径，seeded 洗牌只发生在参战方组装时的一次初洗**。
- **`ADR-0092` / `enemies/_index.md`** — AI 决策是「局面 + **`combat` 子流**」的纯函数，随机**只取 `combat` 子流、不再派生新流**。
- `combat-service.md`「先后手」— `EncounterSpec.FirstSide == null` 时**由 `combat` 子流掷**。
- `character-profile/_index.md` — `Rng.Stream[]` 的 `Seed` **可由 `CycleSeed` + 子流名重算，不进 spec**；`DrawCount` 有**单调不减**入口校验，例外只有 `StartCycle` 初始化与篇章重试整流重置。
- `life-cycle-service.md` — 凡消耗了子流随机的提交，该子流 `State` / `DrawCount` 必须在同一次原子写内更新（承重不变式）；载体是 `ProfileChangeSpec.RngElements`，由 SeedManager 清账 + `#if DEBUG` 比对兜底。
- `common-properties.md` — **增删子流不 bump schema 版本**；读档遇新子流 warn + 初始化、遇旧子流 warn + 丢弃。
- `.claude/rules/state-save-rules.md` — 玩法随机一律经 SeedManager 的**具名子流**隔离；不用未加种子的 `Random`。

## 建议方案

### 裁决：保留 ③④，废止 ①②⑤ —— 战斗两侧共用单一 `combat` 子流，其上不派生任何层
`[既有推演]`

推荐**裁掉 ①⑤（敌人独立子流）与 ②（`eventId` 派生层）**，`RngStream` 与 `rng.stream[]` 保持四条不变。三条依据，都是从既有决策推出来的，不是取舍偏好：

**依据 ①（决定性 · 承重）：①⑤ 想保护的那条性质，抽牌根本不消耗随机，因此它不需要被保护。**
`ADR-0052` 的推论 ④ 已定死：**`DeckModule` 没有重洗代码路径，seeded 洗牌只发生在参战方组装时的一次初洗**；`ActiveCombat.sides[].drawPile` 是一条**有序 `CardInstanceId` 序列**。也就是说——**两侧的牌序在 D0 之前就各自一次性洗定，此后每一次抽牌都只是「从这条定序列表头部取」，零随机消耗**。「玩家的一次额外抽牌打乱敌人牌序」这件事在当前规则下**结构上不可能发生**，独立子流保护的是一个不存在的风险。①⑤ 是「不重洗」定案之前的遗留表述，`ADR-0052` 落地时漏改了这三处。

> 台账里记的代价「统一为单一 `combat` 子流 = 放弃『玩家额外抽牌不打乱敌人牌序』」因此需要修正：**该性质由「不重洗 + 一次初洗」提供，与子流数无关，统一后一分不失。**

**依据 ②：② 的 `eventId` 派生层与三条既有结构规则同时冲突，无法落地。**
若战斗真的跑在 `Hash64(combatStreamSeed, eventId)` 派生出的流上：
- 该流的 `Seed` **不等于** `Hash64(CycleSeed, "combat")` ⇒ 破坏「`Seed` 可由 `CycleSeed` + 子流名重算、不进 spec」；
- 每个事件起一条新流 ⇒ 其 `DrawCount` 从 0 起算，**必然触发 `DrawCount` 单调不减的入口校验**，而该校验的例外口子只有两个（`StartCycle` / 篇章重试），明写过「不开例外口子」；
- `ActiveCombat` **明确不带随机流状态**（`log-profile-change-spec-gaps.md` 已删掉 `ActiveCombat.rng` 三格），派生流没有落点。

② 自称的收益是「不同事件的战斗随机互相隔离，成本为零」。**隔离在此没有用途**：它唯一能防的是「同一 seed 下换个事件重掷」，而这条通道已被 `ADR-0036` 的决策点存档从结构上关死；成本也不为零（上面三条）。

**依据 ③：保留 ①⑤ 会把「这一处随机属于哪一侧」变成每一条卡牌效果都要回答的新问题。**
战斗内除抽牌外仍有真实的随机消耗：先后手掷点、AI 决策、`Ability` / `EffectData` 里的随机选择（随机弃一张、随机命中一个战场条目等）。两条流一旦成立，每一处都要判归属，而**双向效果**（「双方各随机弃一张」「随机重排对手手牌」）**没有干净答案**——它同时属于两侧。这正是 `.claude/rules/csharp-godot-rules.md` 与 `ADR-0013` 反复排斥的那类「靠自律维持、无法机械校验」的分类负担。单流零分类。

**先例。** `ADR-0052` 处理过一次形状完全相同的收口：`enemies/common-properties.md` 曾写「样本卡组规模 15」，与全库其余六处「不设硬限」冲突，裁决是**保留结构侧、删掉那一处遗留**。本条同形——①⑤ 与 ② 是遗留表述，③④ 是被 `ADR-0033` / `ADR-0036` / `ADR-0092` 与存档 schema 共同承重的结构侧。

### 落地形态：五句改三句、一句删、清单不动
`[既有推演]`

| 出处 | 处置 |
|---|---|
| `combat-service.md`「确定性」bullet | **改写**：删末句「敌人抽牌走与玩家抽牌不同的子流……」；删 `Hash64(combatStreamSeed, eventId)` 派生层的整段表述。改为：洗牌 / 先后手掷点 / AI 决策掷骰 / 效果内随机**一律直接取 SeedManager 的 `combat` 子流本身，不派生任何层**（既不加 `eventId`，也不加 `attemptIndex`），与 map / shop / reward 隔离。 |
| `combat-service.md`「战斗内随机的状态不落本块」 | **不动**（③ 即定案措辞）。 |
| `character-profile/deck/_index.md`（敌人卡组条） | **改写**：「**但走不同的战斗 RNG 子流**（玩家的一次额外抽牌不打乱敌人牌序）」→「**双方共用 `combat` 子流**；两侧牌序在参战方组装时各洗一次即定，抽牌本身不消耗随机（`ADR-0052` 推论 ④），故不存在互相打乱牌序的通道」。 |
| `enemies/common-properties.md`「敌人的抽牌走独立的战斗 RNG 子流」整条 | **删除**，或压成一句回链 `systems/services/combat-service.md`「确定性」。（本库纪律：不留「原为 X / 已改」的考古。） |
| `life-cycle-service.md` SeedManager 行 · `common-properties.md` 子流清单 · `character-profile/_index.md` 的 `rng.stream[]` schema | **一字不改**——四条常量清单即定案。 |
| `enemies/_index.md`「确定性约束」 | **不动**（已与 ③ 一致）。 |

### 洗牌顺序须写成规则
`[通行做法]`

单流之下，两侧初洗**共用同一条流**，因此**谁先洗决定两侧牌序**——顺序不写下来就是一处未定义行为。建议明写：**参战方组装时按 `ActiveCombat.sides[]` 的存档序依次初洗**（`sides` 恰两条，玩家侧在前、敌方侧在后），先后手掷点（`FirstSide == null` 时）**排在两次初洗之后**。

理由：`sides` 的存档序本就是既有的稳定序，复用它不新增任何约定；把掷点排在初洗之后，使 `FirstSide` 是否被内容侧显式指定**不改变两侧牌序**（内容编排改一个字段不会连锁抖动整场牌序，编排者的心智负担更低）。

### 确定性验收标准的落笔形态（第 12 / 20 步 derive 直接消费）
`[既有推演]`

裁决落定后，验收标准写成三条可在 Godot 编辑器内观察的断言：

1. **复现**：同一 `CycleSeed` + 同一 `contentVersion` + 同一玩家动作序列 ⇒ 同一场战斗（两侧初始牌序、先后手、AI 每一步选择、效果内随机结果逐项一致）。
2. **存档面**：一场战斗全程，`CharacterProfile.rng.stream[]` **恰四条**，战斗只推进 `name == "combat"` 那一条的 `State` / `DrawCount`；其余三条零变化。
3. **退出重进**：任一决策点 D0–D6 退出重进，恢复后的局面与 `rng.stream[combat].state` 与退出前逐字相等，后续推进与不退出时一致。

注意第 1 条的边界由 `ADR-0033` 给定：**不承诺跨 `contentVersion` 复现**，验收标准须显式钉住 `contentVersion` 相同这一前提，否则它会在任何一次 overlay 热更后误报失败。

## 具体形态（可 derive 的落地面）

```csharp
// life-cycle-service.SeedManager —— 一字不改
public enum RngStream { Map = 0, Combat = 1, Shop = 2, Reward = 3 }   // 恰四条

// 派生：streamSeed = Hash64(CycleSeed, streamName)，就这一层。
// 战斗内取用：Stream(RngStream.Combat) —— 直接取，不再 Hash 派生、不按侧分流、不按 eventId 分流。
```

```jsonc
// CharacterProfile.rng —— 一字不改
"rng": {
  "cycleSeed": 12345678901234567890,
  "stream": [
    { "name": "map",    "seed": 0, "state": 0, "drawCount": 0 },
    { "name": "combat", "seed": 0, "state": 0, "drawCount": 0 },   // ← 战斗内一切随机的唯一落点
    { "name": "shop",   "seed": 0, "state": 0, "drawCount": 0 },
    { "name": "reward", "seed": 0, "state": 0, "drawCount": 0 }
  ]
}
```

**`combat` 子流在一场战斗内的消耗点（穷举）：**

| 时刻 | 消耗 | 备注 |
|---|---|---|
| 参战方组装（D0 之前） | 玩家侧初洗 → 敌方侧初洗 | 各一次，按 `sides[]` 序 |
| 参战方组装（D0 之前） | `FirstSide == null` 时掷先后手 | 排在两次初洗之后；`FirstSide` 非空则零消耗 |
| 行动阶段 / 结算 | 卡牌 / 异能效果内的随机选择 | 有多少条随机效果消耗多少次；双向效果共用同一条流，无归属问题 |
| 敌人回合内部 | AI 决策掷骰（`ADR-0092` 纯函数的随机输入） | 不落决策点，整段由 D5 覆盖并可确定性重放 |
| **抽牌** | **零** | 抽牌堆不重洗、无重洗代码路径 ⇒ 抽牌只是从定序列表取值 |
| 胜负判定后 | 奖励候选抽定 | **走 `Reward` 子流，不在本表** |

## 后果

- **存档 schema 零增量、零迁移**：`RngStream` 与 `rng.stream[]` 均不变，不 bump 版本、不触及「增删子流不 bump」那条口子。
- **改动面 = 三份文档的三句话**（`combat-service.md` 一段改写、`deck/_index.md` 一句改写、`enemies/common-properties.md` 一条删除），另新增一句洗牌顺序规则。`life-cycle-service.md` / `common-properties.md` / `character-profile/_index.md` 不动。
- **`ADR-0092` 的「AI 决策 = 局面 + `combat` 子流的纯函数」原样成立**，不需要补「哪条流」的限定语。
- **`ADR-0033` / `ADR-0036` 不松动**，本方案完全在它们之内。
- **解锁第 12、20 两步 derive**：确定性验收标准的三条断言形态见上。
- **新增一条内容侧触发条件（需登记，不需现在答）**：若日后出现「把一张牌随机洗回抽牌堆 / 随机置入抽牌堆第 N 张」这类关键字，抽牌堆就重新成为战斗中途的随机消耗点。届时**仍不需要拆分子流**（消耗照常记在 `combat` 上、`State` 照常随决策点同批持久化），但 `ADR-0052`「没有重洗代码路径」这句要相应放宽。建议在 `combat-service.md` 明写这条触发条件，使日后加此类关键字时有人知道要回来改哪一句。

## 备选方案（已考虑并否决）

- **B｜保留敌人独立子流，扩清单为五条（`map` / `combatPlayer` / `combatEnemy` / `shop` / `reward`，或四条 + `combatEnemyDraw`）。** 否决：① 它保护的性质由「不重洗 + 一次初洗」已经提供，收益为零；② 迫使每一处战斗内随机回答「属于哪一侧」，双向效果无解；③ 连带要改 `ADR-0092`、先后手掷点、`AI 纯函数`三处的「`combat` 子流」措辞，改动面反而最大。**它唯一便宜的地方是存档**——「增删子流不 bump schema 版本」使扩清单本身成本极低，但这不构成做它的理由。
- **C｜保留 ② 的 `eventId` 派生层（无论一条流还是两条）。** 否决：与「`Seed` 由 `CycleSeed` + 名重算」「`DrawCount` 单调不减、不开例外口子」「`ActiveCombat` 不带随机流状态」三条同时冲突，且其目标（跨事件隔离防重掷）已由 `ADR-0036` 的决策点存档达成。
- **D｜两侧初洗各用一次性子种子（`Hash64(combatStreamSeed, side)`）洗完即弃，其余随机仍走 `combat`。** 否决：这是 B 的轻量版，同样只为一个不存在的风险付费；且「洗完即弃的一次性 RNG」不进子流清单 ⇒ 它的消耗不进 `DrawCount`，`#if DEBUG` 清账比对看不见它，属于在承重不变式上开一个不可见的口子。
- **E｜把「敌人牌序不受玩家影响」升格为规则层承诺并写进验收标准。** 否决：它不是玩家可观测的性质（敌人抽牌堆顺序全程隐藏），写进验收标准等于验一件玩家永远看不见、也无从利用的事。

## 与既有决策的张力

**无 ADR 级张力。** 本方案与 `ADR-0033` / `ADR-0036` / `ADR-0052` / `ADR-0092` 全部同向，且 `ADR-0092` 的措辞正是本方案裁下的那一侧。

**一处需连带修正的既有归档措辞（非 ADR）：** `answer-logs/log-combat-solutions.md` 第 20 条「敌方卡组的设计形态 → 卡组规模固定 15、允许重复条目；抽牌同规则但走独立子流」——这条归档的**前半句已被 `ADR-0052` 推翻**（规模改为不设硬限），后半句即本条 ①⑤ 的源头。按本库「答结即归档、归档不改写」的惯例，`answer-logs/` 通常不回改；若用户希望避免它被后续 session 当作现行结论读回，可在该条追加一行指向本次裁决的更正。**处置权在用户。**

**一处台账措辞需修正：** `open-questions/01-combat.md` 记的代价「统一为单一 `combat` 子流的代价 = 放弃『玩家额外抽牌不打乱敌人牌序』」——按依据 ① 该代价实为零。该条移出时由 `/analyze-new-ideas` 一并处理。

## 前置依赖

**无。** 本方案完全由既有已定案条款推出，不依赖任何仍待答的问题。

反向说明（本条是别人的前置，不是别人是它的前置）：它是 derive 第 12、20 两步的硬前置，也是「敌人 AI 决策形态」（`open-questions/01-combat.md` 同分片，08-25 收窄）落地时「随机取哪条流」的前提——后者已按 `ADR-0092` 写成 `combat` 子流，与本方案一致，故本方案定案不会反过来改动它。

## 既有空白（2026-08-26 评审中发现 · 登记，非本题裁决对象）

**「卡牌效果重洗牌库」在全库从未被讨论过，却已被两条全称推论顺带排除。**

评审第 1 问时用户反问「单一子流是否支持实现重洗牌库的卡牌效果」，经全库逐字核实得到的事实：

| 事实 | 出处 |
|---|---|
| `ADR-0052` 的 `## 决策` 本体禁的是**自动重洗**——「弃牌堆不回流；抽牌堆为空时每尝试抽一张牌，抽牌方失去 1 点道念」 | `decisions/ADR-0052-no-reshuffle-fatigue.md` §决策 |
| 但主题文档把它推成**全称否定**：「`DeckModule` 没有重洗代码路径，seeded 洗牌只发生在参战方组装时的一次初洗」 | `systems/services/combat-service.md:118`（推论 ④） |
| 以及「抽牌堆的 `Id` 序列在一场战斗内**只减不增**」 | `systems/character-profile/deck/_index.md:69`（推论 ②） |
| **卡牌效果重洗全库既未允许也未禁止**——从未被提出或裁决，只是被上述推论排除 | 逐字检索「重洗 / 洗回 / Shuffle」的全部命中 |
| `EffectData` 七个原子操作中无洗牌；最接近的 `MoveCard` 只写「闭集内的流转，不新造牌」，**源区 / 目标区未枚举** | `deck/_index.md:172` |
| 一处措辞不一致：同文件 L63 把闭集流转写成 `卡组 ⇄ 手牌 ⇄ 弃牌堆`（**双向**箭头），与 L69 的「只减不增」相左 | `deck/_index.md:63` / `:69` |

**与本题的关系：正交。** 挡住重洗效果的是 `ADR-0052` 的两条全称推论，**不是子流数量**——单流与独立流今天都做不了。
若日后要开这类效果：

- **单流下**：重洗消耗 `combat` 流 ⇒ 玩家的重洗会推进敌人后续随机。**确定性不破**（同 `CycleSeed` + 同 `contentVersion` + 同动作序列仍复现同一场），失去的只是「玩家操作不扰动敌人牌序」这个便利性质。
- **独立流下**：**救不了**——「洗对手的牌堆」「双方各洗一次」这类双向效果没有干净的侧归属，只会加重 B 方案本就有的分类负担。
- **更硬的约束在别处**：疲劳是本作对局终止压力的承重来源，无限重洗使疲劳永不可达，而那正是 `ADR-0052` 明文推翻过的备选方案。真要开只能是**有限次、消耗性**的一次性效果，且须同批重写那两条推论与 L63 / L69 的措辞不一致。

**本次不处理**（用户已明确不同批开这个口子）。建议作为一条新的待答项登记进 `open-questions/01-combat.md`，由 `/analyze-new-ideas` 落地本草稿时一并新增。

## 仍需用户决定

> **全部裁决完毕（2026-08-26 · 批量评审）。** 逐条裁决见各项下的 `→ 已裁决` 行。

1. **三选一裁决本身（🔴 · 有强推荐）。** 选项：**A｜单一 `combat` 子流、不派生任何层（推荐）** · B｜扩清单、敌人抽牌独立成流 · C｜保留 `eventId` 派生层。
   - **推荐 A**，理由是依据 ①：B 保护的性质（玩家额外抽牌不打乱敌人牌序）在「抽牌堆不重洗 + 一次初洗」之下**结构上已经成立**，与子流数无关 ⇒ **统一的代价实为零**（台账登记的代价需据此修正）；且 B 会给每一条含随机的卡牌效果引入「属于哪一侧」的分类负担，双向效果无解。
   - **后果对比**：A = 改三句、schema 零增量、四个 ADR 全部不动；B = 改五处措辞（含 `ADR-0092` 的「`combat` 子流」限定语）+ 扩枚举与 schema 示例（不 bump 版本），换来零收益；C 与三条既有结构规则冲突，实际不可落地。
   - **→ 已裁决（2026-08-26 · 批量评审）：A —— 单一 `combat` 子流，其上不派生任何层。** 用户在裁决前提出一处反问（单流是否仍支持「重洗牌库」类卡牌效果），经一轮全库事实核实后确认**重洗与子流数量正交**（见下方「既有空白」一节），据此选定 A，且**不同批开重洗口子**——改动面维持「改三句」，不兼动 `ADR-0052`。

2. **是否连带删掉 `combat-service.md` 的 `Hash64(combatStreamSeed, eventId)` 派生层（🟠 · 超出台账登记的三句，故单列请示）。** 台账只登记了三句，②（`eventId` 层）是本次读文档时发现的第四处冲突，它与 ③ 在同一份文档内互斥。
   - **推荐「一并删除」**：它同时违反「`Seed` 由 `CycleSeed` + 名重算」「`DrawCount` 单调不减、不开例外口子」「`ActiveCombat` 不带随机流状态」三条，且其目标已由 `ADR-0036` 达成。
   - 若用户只想按台账原范围处理（只裁三句、暂留 ②），则 `combat-service.md` 内部仍留有一处自相矛盾，第 12 / 20 步 derive 会再次卡在同一处——**不建议**。
   - **→ 已裁决（2026-08-26 · 批量评审）：一并删除。** 本次改动面因此确定为「改三句 + 删 `eventId` 派生层」。
