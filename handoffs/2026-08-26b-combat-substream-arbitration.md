# `combat` 子流收口为单流

- id: 2026-08-26b-combat-substream-arbitration
- date: 2026-08-26
- topic: systems/services/combat-service.md · systems/character-profile/deck/_index.md · systems/enemies/common-properties.md
- status: distilled
- distilled-to: `systems/services/combat-service.md`、`systems/character-profile/deck/_index.md`、`systems/enemies/common-properties.md`

## Intent（distilled）

### 起因：全库对「战斗内随机走几条流」有五处互不相容的表述

| # | 出处 | 原话要点 |
|---|---|---|
| ① | `systems/services/combat-service.md`「确定性」 | 敌人抽牌走与玩家抽牌**不同的子流**，使玩家侧的一次额外抽牌不打乱敌人牌序 |
| ② | 同上，同一 bullet 内 | 派生形态 = **`Hash64(combatStreamSeed, eventId)`，就这一层** |
| ③ | 同文件「战斗内随机的状态不落本块」 | 战斗内随机**直接用 `combat` 子流、不在其上再派生一层** |
| ④ | `systems/services/life-cycle-service.md` · `systems/common-properties.md` · `systems/character-profile/_index.md` 的 `rng.stream[]` schema | 子流清单是 `SeedManager` 内的常量，**恰四条**：map / combat / shop / reward |
| ⑤ | `systems/character-profile/deck/_index.md`（敌人卡组）· `systems/enemies/common-properties.md` | 敌人抽牌**走独立的战斗 RNG 子流**（①的两份副本） |

①⑤ 与 ③④ 直接互斥；② 与 ③ 在**同一份文档内**互斥。第六处出处（`life-cycle-service.md` 的 SeedManager 段）与 ③④ 同侧，无冲突。

### 裁决：战斗两侧共用单一 `combat` 子流，其上不派生任何层

`RngStream` 枚举与 `CharacterProfile.rng.stream[]` schema **一字不改**（四条常量清单即定案），零迁移、不 bump 版本。①②⑤ 三处表述改写为与 ③④ 一致。

三条依据：

1. **①⑤ 想保护的那条性质，抽牌根本不消耗随机，因此它不需要被保护。** `DeckModule` 没有重洗代码路径、seeded 洗牌只发生在参战方组装时的一次初洗（`decisions/ADR-0052-no-reshuffle-fatigue.md` 的推论），`ActiveCombat.sides[].drawPile` 是一条有序 `CardInstanceId` 序列 ⇒ 两侧牌序在 D0 之前各自一次性洗定，此后每次抽牌只是从定序列表头部取值。「玩家的一次额外抽牌打乱敌人牌序」在当前规则下**结构上不可能发生**。
   > **连带订正：统一为单流的代价实为零。** 待答台账登记的代价（「放弃『玩家额外抽牌不打乱敌人牌序』」）不成立——该性质由「不重洗 + 一次初洗」提供，与子流数量无关。
2. **② 的 `eventId` 派生层与三条既有结构规则同时冲突，无法落地。** 派生流的 `Seed` 不等于 `Hash64(CycleSeed, "combat")` ⇒ 破坏「`Seed` 可由 `CycleSeed` + 子流名重算、不进 spec」；每个事件起一条新流 ⇒ 其 `DrawCount` 从 0 起算，必然触发 `DrawCount` 单调不减的入口校验（例外口子只有 `StartCycle` 与篇章重试整流重置）；`ActiveCombat` 明确不带随机流状态，派生流没有落点。它自称的收益「跨事件隔离防重掷」已由 `decisions/ADR-0036-*` 的决策点存档从结构上达成。
3. **保留 ①⑤ 会把「这一处随机属于哪一侧」变成每一条含随机的卡牌效果都要回答的新问题。** 战斗内除抽牌外仍有真实随机消耗（先后手掷点、AI 决策、`Ability` / `EffectData` 内的随机选择），而**双向效果**（「双方各随机弃一张」「随机重排对手手牌」）没有干净的侧归属。单流零分类负担。

### 落地形态

| 出处 | 处置 |
|---|---|
| `combat-service.md`「确定性」bullet | 整段改写：一切战斗内随机直接取 `combat` 子流本身，不派生任何层（既不按 `eventId`、也不按 `attemptIndex`、也不按参战方）；不叠派生层的理由回链 `systems/common-properties.md` 与 `systems/services/life-cycle-service.md` |
| 同 bullet 下 | 新增「两侧牌序互不打乱由结构提供、与子流数无关」的正面陈述 |
| 同 bullet 下 | 新增**洗牌顺序规则**与**确定性三条断言**（见下） |
| `combat-service.md`「抽牌堆不重洗」推论 ④ | 补一句「抽牌零随机消耗」+ 一条内容侧触发条件（见下） |
| `combat-service.md` 参战方段 | 明写 `sides` 索引序（`sides[0]` = 玩家侧、`sides[1]` = 敌方侧），并说明它是承重的 |
| `deck/_index.md` 敌人卡组条 | 「但走不同的战斗 RNG 子流」改为「双方共用同一条 `combat` 子流」+ 理由 |
| `enemies/common-properties.md` 战斗侧引用关系 | 同上改写 + 回链 `combat-service.md`「确定性」 |
| `combat-service.md`「战斗内随机的状态不落本块」· `life-cycle-service.md` · `common-properties.md` · `character-profile/_index.md` 的 `rng.stream[]` schema · `enemies/_index.md`「确定性约束」 | **一字不改**——均已在被保留的一侧 |

### 洗牌顺序须写成规则

单流之下两侧初洗共用同一条流，**谁先取随机就决定了两侧牌序**，顺序不写下来即为一处未定义行为。规则：**参战方组装时按 `ActiveCombat.sides[]` 存档序依次初洗**（`sides[0]` = 玩家侧、`sides[1]` = 敌方侧），**`FirstSide == null` 时的先后手掷点排在两次初洗之后**。

- 玩家侧在前，与 `CardInstanceId` 的确定性发号序（`c#0` 先、`e#0` 后）同向。全库此前从未指定哪一侧在 `sides[0]`，故这一格必须一并明写，否则洗牌顺序规则悬在一个不存在的约定上。
- 掷点排在初洗之后，使 `FirstSide` 是否被内容侧显式指定**不改变两侧牌序**——内容编排改一个字段不会连锁抖动整场牌序。

### 确定性验收的三条断言

1. **复现**：同一 `CycleSeed` + 同一 `contentVersion` + 同一玩家动作序列 ⇒ 同一场战斗（两侧初始牌序、先后手、AI 每一步选择、效果内随机结果逐项一致）。**`contentVersion` 相同这一前提须显式钉住**（`ADR-0033` 的边界），否则任何一次 overlay 热更都会让它误报失败。
2. **存档面**：一场战斗全程 `CharacterProfile.rng.stream[]` 恰四条，只推进 `name == "combat"` 那一条的 `State` / `DrawCount`，其余三条零变化。
3. **退出重进**：任一决策点 D0–D6 退出重进，恢复后的局面与 `rng.stream[combat].state` 与退出前逐字相等，后续推进与不退出时一致。

### `combat` 子流在一场战斗内的消耗点（穷举）

| 时刻 | 消耗 | 备注 |
|---|---|---|
| 参战方组装（D0 之前） | 玩家侧初洗 → 敌方侧初洗 | 各一次，按 `sides[]` 序 |
| 参战方组装（D0 之前） | `FirstSide == null` 时掷先后手 | 排在两次初洗之后；`FirstSide` 非空则零消耗 |
| 行动阶段 / 结算 | 卡牌 / 异能效果内的随机选择 | 双向效果共用同一条流，无归属问题 |
| 敌人回合内部 | AI 决策掷骰 | 不落决策点，整段由 D5 覆盖并可确定性重放 |
| **抽牌** | **零** | 抽牌堆不重洗 ⇒ 抽牌只是从定序列表取值 |
| 胜负判定后 | 奖励候选抽定 | 走 `Reward` 子流，不在本表 |

### 内容侧触发条件（已写进 `combat-service.md`）

若日后出现「把一张牌随机洗回抽牌堆 / 随机置入抽牌堆第 N 张」这类关键字，抽牌堆重新成为战斗中途的随机消耗点。届时**仍不拆分子流**（消耗照常记 `combat`、`State` 照常随决策点同批持久化），但「`DeckModule` 没有重洗代码路径」与「抽牌堆只减不增」两条推论须相应放宽。

## Clarifications

- **三选一裁决本身（🔴）→ A：单一 `combat` 子流、其上不派生任何层。** 用户在裁决前反问「单流是否仍支持重洗牌库类卡牌效果」，经全库事实核实确认**重洗与子流数量正交**（单流与独立流今天都做不了，挡住它的是两条全称推论），据此选定 A。推翻了原始输入中 ①②⑤ 三处表述。
- **是否连带删掉 `Hash64(combatStreamSeed, eventId)` 派生层（🟠）→ 一并删除。** 台账只登记了三句，② 是读文档时发现的第四处冲突且与 ③ 同文件互斥；不删则 `combat-service.md` 内部仍自相矛盾。改动面因此确定为「改三句 + 删 `eventId` 派生层」。
- **是否同批开「卡牌效果重洗牌库」的口子 → 不开。** 不兼动 `ADR-0052`；该空白改为登记进待答清单。
- **`enemies/common-properties.md` 那条取「改写为正确表述 + 回链」而非纯删除**（采纳的默认）——与同批 `deck/_index.md` 的处置对称，且活文档须独立可读：读者在敌人文档里问「敌人抽牌走哪条流」应当场得到答案。
- **`sides[]` 的索引序须一并明写为「玩家侧 `sides[0]`、敌方侧 `sides[1]`」**（采纳的默认）——全库从未指定哪一侧在前，不补这一句则洗牌顺序规则无所依附；取值依据是 `CardInstanceId` 发号序（角色先、敌人后）的既有先例。
- **不回改 `answer-logs/log-combat-solutions.md` 的第 20 条**（采纳的默认）——answer-log 是只读的历史记录，结论权威归主题文档与 ADR。
- **`combat-service.md` 删去派生层论证后不丢承重理由**（采纳的默认）——「不加 `attemptIndex`」的否决理由已完整活在 `systems/common-properties.md` 与 `systems/services/life-cycle-service.md`，本文档压成一句回链即可，两处各留一份论证正是本次要收的第二权威。

## Open questions

- **卡牌效果重洗牌库的口子是否开、以何形态开。** 全库从未提出或裁决，只被两条全称推论顺带排除；与子流数量正交。真要开只能是有限次、消耗性的一次性效果（无限重洗使疲劳永不可达，而疲劳是本作对局终止压力的承重来源），且须同批重写那两条推论与 `deck/_index.md` 「闭集流转」与「只减不增」两句的措辞不一致。
