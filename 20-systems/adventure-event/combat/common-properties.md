# adventure-event / combat / common-properties（Combat 子类型共有属性）

> Combat 类 AdventureEvent 共有的属性 / 字段。顶层共有属性见 `../common-properties.md`。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

### Combat 专有属性 / 字段

- **敌人组合（enemy roster）。** 一个 Combat 事件引用一组敌人（各自带道念、intent、行为），以 `Id` 引用敌人数据资源。Source: `data-resource-rules.md`。
- **回合结构。** 回合制、意图预告式；玩家在其回合内以 mana 出牌，敌人按预告的 intent 行动；**双方各自累积道念**。
- **战斗资源引用。** 战斗读取 `CharacterProfile.Status` 的 `currentMana / manaLimit`（无曲线；**每回合开始 mana 恢复至 `manaLimit`**，上限由事件 cost / reward 推拉），并维护**双方的道念**作为胜负标尺。`lifeTotal / lifeTotalLimit` **在战斗过程中不被读写**，只在结算时按道念差扣减（见 `20-systems/scoring.md`、`20-systems/character-profile/life-total.md`）。战斗**固定 10 个回合**（双方各 5）后比道念定胜负。Source: `10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md` + `10-handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md` + `10-handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。
- **等级引用。** 战斗读取角色的 `realm` + `level` 与敌人的等级，在**全局等级序**上求差，据此决定意图揭示档位（见 `_index.md`、`20-systems/game-progression.md`）。**敌人等级同时被精确标注在 eventOptions 上**，故它既是内部判据也是对外展示字段。Source: `10-handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md` + `10-handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。
- **胜 / 负结算钩子。** Combat 走战斗结算；**Practice 与 Finale 是其变体**（同一回合循环与参战方结构，独立的胜负条件与奖惩），其余六类走事件式结算。

## 决策(-> ADR)
> _已定案的决定链接到 50-decisions/ADR-####。_

- 见 `_index.md`（mana + 道念模型、危险度精确标注、Combat 分类）。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **敌人数据 schema：** 敌人字段（等级、道念产出能力、intent 列表、行为脚本、缩放）未定义。Source: `10-handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。
- **回合结构细节：** 抽 / 弃 / 出牌顺序、**战斗终止条件**（回合上限 / 道念阈值 / 卡组耗尽）等未定。→ 见 `_index.md`、`20-systems/scoring.md` 与 `20-systems/character-profile/mana.md`。

## 对应
提炼至：`.claude/knowledge/systems/adventure-event/combat.md`（待建）
