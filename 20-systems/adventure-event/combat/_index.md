# adventure-event / combat（AdventureEvent-Combat）

> 正式回合制战斗遭遇：回合结构、敌人意图 / AI、life + mana 战斗模型、胜 / 负结算。含敌人内容定义。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

### 战斗定位

- **Combat = AdventureEvent 的一个子类型。** 与 ADR-0002 分类法一致。
- **战斗是回合制且易读（意图预告式），而非实时 / 拼 APM。** 敌人以「意图（intent）」预告下一步行动。Source: `10-handoffs/2026-07-13.md`。

### 战斗模型 = life + mana（已定案）

- **参考 Magic: the Gathering 与 Hearthstone 的 life + mana 双资源系统**（而非 StS 纯 HP，或 Balatro 的 chips×mult）。与 `CharacterProfile.Status` 的 `currentHealth/healthLimit`、`currentMana/manaLimit` 字段一致；mana 作为出牌资源见 `20-systems/character-profile/mana.md`。Source: `10-handoffs/2026-07-22-online-cloud-combat-and-meta-clarifications.md`。
- **mana = 无曲线 · 上限 + 逐步恢复（已定案）。** 不采用 mana 曲线（既非 Hearthstone 式每回合 +1 上限，也非 MTG 式打地递增）；改为「上限 + 逐步恢复」：mana 有上限，每回合逐步恢复。**炼气期标准基线（起始满值）：** life = **10/10**、mana = **5/5**。Source: `10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。

### 敌人

- **敌人拥有 HP、intent（意图）、行为。** 敌人在战斗中以意图预告式行动，供玩家读牌决策。
- **敌人是数据资源。** 每个敌人为一个 `.tres` 内容条目，带稳定 `Id`；战斗 AdventureEvent 引用敌人组合。Source: `data-resource-rules.md`。

## 决策(-> ADR)
> _已定案的决定链接到 50-decisions/ADR-####。_

- **战斗模型 = life + mana、无曲线 · 上限 + 逐步恢复、炼气基线 10/10 · 5/5** —— 已定案。Source: `10-handoffs/2026-07-22-online-cloud-combat-and-meta-clarifications.md` + `10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。
- **Combat 为分类法第二类** → `50-decisions/ADR-0002-adventure-event-taxonomy.md`。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **战斗模型细化（收窄）：** 仅剩 mana 逐步恢复的具体速率、manaLimit / 基线随境界的成长。→ `20-systems/character-profile/mana.md`、`20-systems/balance.md`。
- **属性模型与战斗资源共存：** 隐藏属性（道心 / 煞气 / 寿元）与 life + mana 战斗资源如何共存与推拉未定。→ `20-systems/services/plot-manager.md`、`20-systems/services/life-cycle-service.md`。
- **敌人 AI / intent 系统：** intent 类型枚举、意图选择逻辑、多回合行为脚本、敌人组合与出现规则均未定义。
- **敌人平衡：** 敌人 HP、伤害、随境界 / 篇章缩放未定。→ `20-systems/balance.md`。
- **胜 / 负结算细则：** 胜利奖励、失败后果（defeated 语义、是否与寿元 / Finale 交互）未定。
- **enemies 归属（Open question）：** 当前归 combat/（敌人只在 Combat/Finale 出现）；若未来 Practice 等也用敌人，是否应升为共享内容层待确认。Source: `10-handoffs/2026-07-24-docs-restructure-class-model.md`。

## 对应
提炼至：`.claude/knowledge/systems/adventure-event/combat.md`（待建）
