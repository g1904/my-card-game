# adventure-event / combat / common-properties（Combat 子类型共有属性）

> Combat 类 AdventureEvent 共有的属性 / 字段。顶层共有属性见 `../common-properties.md`。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

### Combat 专有属性 / 字段

- **敌人（单数）。** **本作不存在多敌人场景**：一个 Combat 事件恰有一个敌人，承载字段写单数 `EnemyInstance Enemy`（不写列表、不留伸缩位）。条目定义与物化规则见 `systems/enemies/`。
- **遭遇参数落 `EncounterSpec`。** `combatTier` / `TurnLimit` / `VictoryRule` / `RewardPoolId` / `BaseReward` 由 future-event-service 在物化时从 `AdventureEventData` 模板代入，**`EnemyData` 完全不携带**——否则同一个敌人条目无法同时用于 `Practice` 与 `Standard` 档。见 `systems/services/combat-service.md`。
- **回合结构。** 回合制；玩家在其回合内以 mana 出牌，敌人在其回合行动（**行动不作事前预告**，见 `_index.md`「敌人回合的可读性」）；**双方各自累积道念**。
- **战斗资源引用。** 战斗读取 `CharacterProfile.Status` 的 `currentMana / manaLimit`（无曲线；**每回合开始 mana 恢复至 `manaLimit`**，上限由事件 cost / reward 推拉），并维护**双方的道念**作为胜负标尺。寿元 `lifeSpan`（**单值，无上限字段**）**在战斗过程中不被读写**，只在收口时刻按道念差 × `lossPerMomentum` 扣减（见 `systems/scoring.md`、`systems/character-profile/life-span.md`）。战斗**固定 10 个回合**（双方各 5）后比道念定胜负。
- **等级引用。** 战斗读取角色的 `realm` + `level` 与敌人的等级，在**全局等级序**上定位，各自据 `baseMomentum` 表取得战斗起始道念（见 `_index.md`、`systems/game-progression.md`、`systems/balance.md`）。**敌人等级同时被精确标注在 eventOptions 上**，故它既是内部判据也是对外展示字段——**看到等级即看到起跑线**。
- **胜 / 负结算钩子。** Combat 是五类中唯一走战斗结算的一类，**三个 `combatTier` 档共用同一套结算代码**（差异在 `EncounterSpec` 的参数）；其余四类走事件式结算，Explore 视其揭示出的真身可能落到战斗结算上。

Source: `handoffs/2026-08-30-life-lifespan-merge.md` · `handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md` · `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md` · `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md` · `handoffs/2026-08-06d-combat-open-questions-mass-closure.md` · `handoffs/2026-08-15c-event-type-collapse-and-batch-shape.md`

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- 见 `_index.md`（mana + 道念模型、危险度精确标注、Combat 分类）。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **敌人数据 schema 的其余字段** → `systems/enemies/common-properties.md`。

## 对应
提炼至：`.claude/knowledge/systems/adventure-event/combat.md`（待建）
