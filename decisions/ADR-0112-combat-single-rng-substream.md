# ADR-0112 — 战斗两侧共用单一 `combat` 子流、其上不派生任何层；初洗按 `sides[]` 序

- **状态：** Accepted
- **日期：** 2026-08-26
- **来源：** handoffs/2026-08-26b-combat-substream-arbitration.md

## 背景

全库对「战斗内随机走几条流」有五处互不相容的表述：一处说敌人抽牌走与玩家不同的子流；同一 bullet 内又说派生形态是 `Hash64(combatStreamSeed, eventId)`；同一文件第三处说直接用 `combat` 子流不再派生；而 `rng.stream[]` schema 明确子流恰四条。互斥的表述使 `systems/enemies/` 与 `deck/` 无法 derive。

## 决策

**战斗两侧共用单一 `combat` 子流，其上不派生任何层**——既不按 `eventId` 分流、也不按 `attemptIndex` 分流、也不按参战方分流。`RngStream` 枚举与 `rng.stream[]` schema **一字不改**（四条常量清单即定案），零迁移、不 bump 版本。

**洗牌顺序是规则，不是实现细节**：参战方组装时按 `ActiveCombat.sides[]` 存档序依次初洗，**`sides[0]` = 玩家侧、`sides[1]` = 敌方侧**（该索引序是承重的），`FirstSide == null` 时的先后手掷点排在两次初洗之后。

确定性验收三条断言、子流在一场战斗内的消耗点穷举 → `systems/services/combat-service.md`「确定性」。

## 理由

**分侧想保护的那条性质根本不需要被保护。** 抽牌堆不重洗（`ADR-0052`），seeded 洗牌只发生在参战方组装时的一次初洗，此后每次抽牌只是从定序列表头部取值——**抽牌零随机消耗**。「玩家的一次额外抽牌打乱敌人牌序」在当前规则下结构上不可能发生。该性质由「不重洗 + 一次初洗」提供，与子流数量无关，故统一为单流的代价实为零。

**`eventId` 派生层与三条既有结构规则同时冲突，无法落地**：派生流的 `Seed` 不等于 `Hash64(CycleSeed, "combat")`，破坏「`Seed` 可由 `CycleSeed` + 子流名重算」；每个事件起新流则 `DrawCount` 从 0 起算，必然触发单调不减的入口校验；`ActiveCombat` 明确不带随机流状态，派生流没有落点。它自称的「跨事件隔离防重掷」已由决策点存档从结构上达成（`ADR-0036`）。

**分侧会把「这一处随机属于哪一侧」变成每一条含随机的卡牌效果都要回答的新问题。** 双向效果（「双方各随机弃一张」）没有干净的侧归属。单流零分类负担。

洗牌顺序必须写成规则：单流之下两侧初洗共用同一条流，谁先取随机就决定了两侧牌序，不写下来即为一处未定义行为。掷点排在初洗之后，使 `FirstSide` 是否被内容侧显式指定不改变两侧牌序——内容编排改一个字段不会连锁抖动整场牌序。

## 备选方案

- **玩家侧 / 敌方侧各一条子流** — 否决：它想保护的性质由结构提供、与子流数无关；且双向效果无侧归属。
- **在 `combat` 上按 `eventId` 再派生一层** — 否决：与三条既有结构规则同时冲突，收益已由决策点存档达成。
- **按 `attemptIndex` 派生** — 否决：该派生层已整层删除 → `ADR-0101`。

## 后果

- `systems/services/combat-service.md` 是权威；`systems/character-profile/deck/_index.md` 与 `systems/enemies/common-properties.md` 的敌人抽牌表述随之改写为「双方共用同一条 `combat` 子流」。
- 复现断言必须**显式钉住 `contentVersion` 相同**（`ADR-0033` 的边界），否则任何一次 overlay 热更都会让它误报失败。
- `sides` 索引序自此是承重约定，参战方组装、`CardInstanceId` 发号序（`c#0` 先、`e#0` 后）与洗牌顺序三处依赖它。
