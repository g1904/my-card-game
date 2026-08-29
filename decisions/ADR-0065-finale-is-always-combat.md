# ADR-0065 — 全部 Finale 均为天劫战，不设非战斗形态的境界突破路径

- **状态：** Accepted
- **日期：** 2026-08-17
- **来源：** handoffs/2026-08-17e-finale-combat-only-and-hidden-stat-io.md

## 背景

境界突破是篇章的终点。除了「打赢天劫」，还可以设想别的形态：试炼求值、抉择链、以某种等效换算判定通过。这些形态能给篇章结尾更多变化。

## 决策

**全部 Finale 均为天劫战；不设非战斗形态的境界突破路径（承重）。** 境界突破只有一条路径——**打赢天劫**。

`EncounterSpec.Enemy` 在 Finale 档恒非空；`CombatEventResolver` 内部**无分派**。

→ `systems/adventure-event/combat/_index.md`；resolver 侧 → `systems/services/combat-service.md`。

## 理由

非战斗形态会连带出**三套平行机制**：第二套奖惩换算（试炼的成败给什么）、第二套残卷判定（`ADR-0049` 焊在 Finale 胜负上）、第二条失败通道（`DefeatReason` 要新增成员）。三者都要各自平衡，而收益只是篇章结尾的形态多样性。

单一路径同时让 Finale 成为一个**确定的能力检查点**：玩家知道每个篇章末尾要面对什么，构筑目标因此明确。

## 备选方案

- **引入试炼求值 / 抉择链 / 等效道念差映射** — 否决：连带三套平行机制，各自需要平衡。

## 后果

- `CombatEventResolver` 无内部分派，Finale 与常规战斗走同一条结算路径，只是档位不同。
- Finale 失败即角色终结（→ `ADR-0025`），判定二值化，`WinMargin` 在该档退场。
- 剧本要加压 Finale 只能走敌人侧的两个字段（→ `ADR-0077`）。
