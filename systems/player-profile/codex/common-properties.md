# codex — 共有属性

> 五个图鉴的条目共有字段与解锁语义。族总览见 `_index.md`；敌人图鉴的具体词条见 `enemy-codex.md`。

## 已定的约束

- **条目按对象的稳定 `Id` 索引。** 图鉴条目以对应内容条目（`EnemyTemplate` / `PlayerPowerData` / `ItemData` …）的 `Id` 为键——与全库「稳定 `Id` 是一切引用的键」一致（见 `systems/common-properties.md`）。绝不用显示名或索引作键。
- **只记录静态知识。** 条目承载「这个东西是什么、会做哪些事」，**不承载任何运行态**（本回合意图、当前道念、场上状态）——那些属于 `combat-service` 的战斗内状态，战斗结束即消失。分层论证见 `_index.md`。
- **展示文案不进图鉴条目。** 显示名 / 描述 / 立绘 / 词条正文留在对应的 `Resource` 上；图鉴的**存档条目只带 `Id` + 解锁状态 + 计数类可变字段**，呈现时由 ViewModel 组装。这是全库「运行时 / 存档态只带 `Id` + 可变状态」的直接应用。**推论：图鉴的存档负担接近一个 id 集合**，文案改版不触发存档迁移，也不撑大增量 push。
- **写入经 `profile-service.ProfileManager`。** 解锁与计数更新是 `ProfileChangeSpec` 的变更目标，不绕过唯一写入面。
- **解锁是一次性的全量写入（已定案，由 EnemyCodex 确立）。** 触发一次即解锁该条目的**全部词条文案**——**逐项 / 逐招式解锁已否决**。因此解锁状态**只需表达「已解锁」这一态**；「已击败」「使用过 N 次」之类若需要，是额外的计数字段，**不是解锁前提**。Source: `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。
- **EnemyCodex 的触发 = 遭遇（不必击败）。** 失败的战斗同样留下知识。其余四个图鉴的触发未定，见 `_index.md`。Source: `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。

## 待定的字段清单

⟨待定：计数字段（遭遇次数 / 击败次数 / 败于其手次数 / 使用次数）、首次解锁的元数据（篇章 / 境界 / 日期）、能力与道具类图鉴的触发语义与词条深度——见 `_index.md` 的待决问题。⟩

## 对应
提炼至：`.claude/knowledge/systems/player-profile/codex/common-properties.md`（待建）。
