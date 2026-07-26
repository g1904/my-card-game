# adventure-event / combat / common-properties（Combat 子类型共有属性）

> Combat 类 AdventureEvent 共有的属性 / 字段。顶层共有属性见 `../common-properties.md`。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

### Combat 专有属性 / 字段

- **敌人组合（enemy roster）。** 一个 Combat 事件引用一组敌人（各自带 HP、intent、行为），以 `Id` 引用敌人数据资源。Source: `data-resource-rules.md`。
- **回合结构。** 回合制、意图预告式；玩家在其回合内以 mana 出牌，敌人按预告的 intent 行动。
- **战斗资源引用。** 战斗读取 `CharacterProfile.Status` 的 `currentHealth/healthLimit`、`currentMana/manaLimit`（life + mana 模型，无曲线 · 上限 + 逐步恢复）。Source: `10-handoffs/2026-07-22-online-cloud-combat-and-meta-clarifications.md` + `10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。
- **胜 / 负结算钩子。** Combat 走战斗结算（区别于 Finale 的独立结算与其余子类型的事件式结算）。

## 决策(-> ADR)
> _已定案的决定链接到 50-decisions/ADR-####。_

- 见 `_index.md`（life + mana 模型、Combat 分类）。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **敌人数据 schema：** 敌人字段（HP、intent 列表、行为脚本、缩放）未定义。
- **回合结构细节：** 抽 / 弃 / 出牌顺序、mana 每回合恢复量、回合上限等未定。→ 见 `_index.md` 与 `20-systems/character-profile/mana.md`。

## 对应
提炼至：`.claude/knowledge/systems/adventure-event/combat.md`（待建）
