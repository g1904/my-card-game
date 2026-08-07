# adventure-event / combat / common-properties（Combat 子类型共有属性）

> Combat 类 AdventureEvent 共有的属性 / 字段。顶层共有属性见 `../common-properties.md`。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

### Combat 专有属性 / 字段

- **敌人（单数）。** **本作不存在多敌人场景**：一个 Combat 事件恰有一个敌人，承载字段写单数 `EnemyInstance Enemy`（不写列表、不留伸缩位）。条目定义与物化规则见 `systems/enemies/`。Source: `handoffs/2026-08-06d-combat-open-questions-mass-closure.md`。
- **遭遇参数落 `EncounterSpec`。** `TurnLimit` / `VictoryRule` / `RewardPoolId` / `BaseReward` 由 future-event-service 在物化时从 `AdventureEventData` 模板代入，**`EnemyData` 完全不携带**——否则同一个敌人条目无法同时用于 Practice 与 Combat。见 `systems/services/combat-service.md`。Source: 同上。
- **回合结构。** 回合制、意图预告式；玩家在其回合内以 mana 出牌，敌人按预告的 intent 行动；**双方各自累积道念**。
- **战斗资源引用。** 战斗读取 `CharacterProfile.Status` 的 `currentMana / manaLimit`（无曲线；**每回合开始 mana 恢复至 `manaLimit`**，上限由事件 cost / reward 推拉），并维护**双方的道念**作为胜负标尺。`lifeTotal`（**单值，无上限字段**）**在战斗过程中不被读写**，只在结算时按道念差扣减（见 `systems/scoring.md`、`systems/character-profile/life-total.md`）。战斗**固定 10 个回合**（双方各 5）后比道念定胜负。Source: `handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md` + `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md` + `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。
- **等级引用。** 战斗读取角色的 `realm` + `level` 与敌人的等级，在**全局等级序**上求差，据此决定意图揭示档位（见 `_index.md`、`systems/game-progression.md`）。**敌人等级同时被精确标注在 eventOptions 上**，故它既是内部判据也是对外展示字段。Source: `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md` + `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。
- **胜 / 负结算钩子。** Combat 走战斗结算；**Practice 与 Finale 是其变体**（同一回合循环与参战方结构，独立的胜负条件与奖惩），其余六类走事件式结算。

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- 见 `_index.md`（mana + 道念模型、危险度精确标注、Combat 分类）。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **敌人数据 schema 的其余字段** → `systems/enemies/common-properties.md`。

## 对应
提炼至：`.claude/knowledge/systems/adventure-event/combat.md`（待建）
