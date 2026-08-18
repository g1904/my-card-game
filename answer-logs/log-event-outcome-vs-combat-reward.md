# Answer log event-outcome-vs-combat-reward

- 日期：2026-08-16
- 来源：`inbox/archive/solution-draft-event-outcome-vs-combat-reward.md` → `handoffs/2026-08-16h-grant-source-assembler-criterion.md`
- 移出条数：1

## 逐条

**`Source` 的 `EventOutcome`(4) 与 `CombatReward`(5) 是否终将合并为一个成员** → **不合并，两个成员分立保留**，问题就此关闭（归档去向：`systems/common-properties.md` 的「授予来源共有字段」节）。

裁定要点：

- **判据钉为「谁组装出这条 element」**，不看它属于哪类事件、也不看它最后被谁写进去。出自 `CombatResult.Spoils` → `CombatReward`（`Finale` 胜利的残卷那一路例外，走 `FinaleWin`）；出自通用结算器的 outcome / effect 定义 → `EventOutcome`；出自购买流程 → `ExchangePurchase`。
- **施加路径不是判据。** 三者今天就已走同一条施加链路（都是 `ProfileChangeSpec`、都在 `eventEnd` 由同一次 `TryApply` 写入）；若「施加路径同一 ⇒ 应合并」成立，`InitialGrant` 也该一并合并，而清单不是按这条轴切的。
- **两处按事件类型表述会被打穿的边界因此一并答掉**：① Explore 揭示出战斗真身时，战利品出自 combat-service，记 `CombatReward`；② Exchange 的非购买 outcome 归 `EventOutcome`（只有走购买流程的那一条走 `ExchangePurchase`）。
- **合并会丢掉不可重建的信息维度**：`TryApply` 的可追溯性日志与客服 / 数据侧的账号溯源都依赖「战斗掉落 vs 事件产出」这条区分，而持有条目上没有任何字段能事后补出它。对价只是一个零维护成本的枚举成员。
- **唯一的张力及其处置（本次的核心反驳）：** `(Kind, Scope)` 校验表中两行逐格相同（❌ ❌ ✅ ✅），这是合并方最强的论据。**「行相同」不构成合并判据**——同表中 `PremiumBundle` 与 `AchievementReward` 同样逐格相同（✅ ✅ ❌ ❌）而无人主张合并。行相同只说明**挂载面**相同，渠道说的是**由哪条路径给出**，两个正交维度。
- **附带采纳一条 `eventEnd` 单向组装校验**（落 `systems/services/life-cycle-service.md`）：未走过 combat-service 的事件出现 `CombatReward` → `GD.PushError` + 整批拒绝；反向不判非法。判据取「是否产生过 `CombatResult`」，不取 `EventOption.EventType`。
- **重开触发器（可观察）：** 仅当 `RunCombatAsync` 不再自算 `Spoils`、或战后可选奖励选择步骤被取消、或奖励厚度不再由道念差决定时重新评估。

零改动面：`Source` 成员清单与 code · `(Kind, Scope)` 合法子集表 · 存档 schema（不 bump、无迁移）· 后端契约与 `backend-design-documents/` 全库。
