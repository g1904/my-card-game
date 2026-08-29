# Answer log enemy-ai-strategy-shape

- 日期：2026-08-26
- 来源：`inbox/solution-draft-enemy-ai-strategy-shape.md`（去向 handoff：`handoffs/2026-08-26c-enemy-ai-strategy-shape.md`）
- 移出条数：1

---

**「敌人 AI 的决策形态」（表达形态 / 具体算法 / 决策粒度 / 多回合行为倾向 / 兜底与定制的强弱差口径，五项全悬）** → 五项一次答定：

- **表达形态** = `AiProfile : EnemyAiProfileData`，`[Export]` **直接类型引用**、可空、`null` = 走通用兜底。它是一条**独立可复用资源**（进 ContentRegistry、带 `Id` + `ContentEnabled`、不挂 `Rarity`），内容只有 `AiWeight[] Weights`（内嵌 `Resource`，`Term` + `Value`），只列要覆写的项；profile 内没有第二类结构位。判据 = 待答项要求交代的「是否需跨条目复用」：打法风格原型天然被一批敌人共享。
- **具体算法** = 单层（1-ply）加权效用评分 + 确定性 argmax，`score(EndTurn) ≡ 0` 作绝对零点；`AiTerm` 十项初值、开放可加；试算**不展开连锁触发**（明写为规则）。目标选择复用同一评分函数，`LegalTargets` 为空的槽位使该候选整个不进候选集。
- **决策粒度** = **逐张**，每次执行到栈清空后重算候选集。
- **多回合行为倾向** = **零记忆**、纯局面函数；硬约束「可由 `ActiveCombat` 现有字段重算，否则必须落存档」按「可重算」一端满足 ⇒ **存档面零改动、零迁移**；AI 不得持有跨动作 / 跨回合的私有字段（`ChooseAction` 写成 `static`）。
- **强弱差口径** = 三条结构性上界（定制层只给权重不给代码 · 深度恒 1-ply · `Value` 钳在 `[AiWeightMin, AiWeightMax]`，越界 `PushError` + 抛），**不推翻** `ADR-0092` 的软口径、只加固；不另加带数字的胜率口径（不可测量的条款不写）。剩余不可机械校验的一小块仍留编排口径。

同批裁定的两项：**AI 全流程零随机**（平手取确定性字典序；`ADR-0092`「随机只取 `combat` 子流」在本方案下为空约束，保留作日后随机化权重项的约束）；**AI 的读取面 = `CombatSnapshot` 双视角化**（新增 `ViewerSide`，AI 与呈现共用同一投影、缓存按视角分别持有，**不新增 `AiCombatView`**）——字段语义不变，故「不读玩家手牌内容 / 抽牌堆顺序」仍停在 `ADR-0013` 第 1 级。

数值分层：兜底默认权重向量与 `AiWeightMin` / `AiWeightMax` 住 `CombatRulesData`；**profile 的逐条取值归内容层**（`content/enemy-ai/<id>.md`，类型档案待 `/scaffold-content-type` 开张）。

（归档去向：`systems/enemies/_index.md`、`systems/enemies/common-properties.md`、`systems/services/combat-service.md`、`systems/adventure-event/combat/_index.md`、`systems/balance.md`）

> **残留的数字面不新开条目**：兜底权重的数字初值被同一分片已有的「卡牌产 / 削道念的量纲基准」覆盖（该条已明写自己是本次多条初值的前置依赖），清单里不再另留一条。
