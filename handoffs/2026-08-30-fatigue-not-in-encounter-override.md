# 疲劳扣减维持不进 `EncounterSpec` 覆写组（四条理由 + 收紧重开判据）

- id: 2026-08-30-fatigue-not-in-encounter-override
- date: 2026-08-30
- topic: systems/balance.md · systems/services/combat-service.md
- status: distilled
- distilled-to: systems/balance.md

## Intent（distilled）

`MoveCardEffect` 的 `From` 可取抽牌堆、`Side` 可指向对手 ⇒ 「削减对手抽牌堆」在效果语法层面已成立，这触发了 `systems/balance.md`「疲劳扣减刻意不进覆写组」写下的重开判据 ①。本次对那三条理由做完整重估，**结论是维持现状**：`EncounterSpec` 覆写组仍是四格、`EncounterTighten` 仍是五格、`FatiguePerDraw` 仍是每张 1 点的全局常量。**净落地面是文字：零字段、零数值、零存档改动。**

### 三条既有理由的重估

- **理由 ①（触发窗口不由档位决定）仍成立，且被加强。** 削堆条目只是给「触发窗口」再添一个**内容侧**的决定因素，档位侧仍是零条。同时显性化一处此前未写的反向咬合：`EncounterTighten` 的 `DrawPerTurnDelta` / `InitialDrawDelta` 恒 `<= 0`，收紧牌流量的同时**减轻**疲劳压力；两格若同向可拧，一条 arc 就能朝两个方向拧同一条压力线，净效果对内容作者不可预测。
- **理由 ②（payoff 面窄）仍成立 —— 被当作「新事实」的那件事本就写在这条理由里。** 理由 ② 的原文已含「`MoveCard` 虽能把对手抽牌堆的牌搬进别的区…但那是逐条内容、有限次、受载体消耗性约束的效果」。重开判据 ① 要的是**已签核的条目**，不是**结构可写性**；`content/` 当前零条目 ⇒ 判据在字面上尚未触发。
- **理由 ③（量纲）结论不变，论据换掉。** 原论据靠「从第 1 回合起就空堆这种极端不会发生」取信，削堆可写后这层修辞变弱。改写后的论据是：**常规**抽牌预算（起手 + 每回合抽）已被覆写组三格连同 `Tighten` 两格覆盖；内容侧 `DrawEffect` 能把单场实际抽牌次数抬到该预算之上，但它逐条有限、同受载体消耗性约束，而对局终止性由 `EncounterSpec.TurnLimit` 独立封顶 ⇒ 加一格档位旋钮买不到额外的安全性。
  > 这一句比原始草稿更精确：草稿写的是「疲劳总量 ≤ 抽牌预算，上界由抽牌预算封死」，但 `DrawEffect` 使实际抽牌次数**能超过**常规抽牌预算 —— 「硬上界」这个说法内容侧可突破，故不采用。

### 新增的第四条否决论据：方向不单调

疲劳作用于「抽牌方」而非「玩家」：同一个正向 delta 对小卡组构筑是加压、对大卡组是送礼。`EncounterTighten` 的准入判据要求该格上存在一个全序**加**一个单调难度方向；`FatiguePerDraw` 有全序（`int`）却没有单调方向 —— 失败在「单调」而非「全序」上，与 `Enemy` / `Tier` / `FirstSide` 被挡在增量组之外是同一条判据。它同时给 `EncounterTighten` 的五格封闭性提供了第一个具体实证。

### 遭遇级疲劳压力的三条既有承接通道

敌人卡组规模编排（`EnemyData`）· 内容侧的疲劳量修正（`StaticModifierData{ What = FatigueAmount }`，双向）· 牌流量本身（覆写组两格 + `Tighten` 两格）。三条通道齐备 ⇒ 原重开判据 ②「某个遭遇档需要显式调节疲劳压力」不构成开格理由，该判据由承接通道表取代。

### 重开判据 ① 收紧

改为：出现 `Pool` 覆盖敌人侧、以削减对手抽牌堆为**主要**效果、且**已签核（`ready`）**的内容条目，其在同一抽取池内的密度足以让一方在 `TurnLimit` 的**前 40%**（`Standard` 档 = 前 4 个回合，比例是待实测校准的占位）内空堆，并明写**结构可写性不构成触发**。

### 条件性预案（备查，非本次建议）

万一日后判据真被触发，形态取 `EncounterSpec` 覆写组第五格 `int? FatiguePerDraw`，**不取** `EncounterTighten` 第六格 —— 因为挡住 `Tighten` 的是「方向不单调」，那条在增量形态下无解，而覆写形态不要求单调性。

## Clarifications

- **`ADR-0052` / `ADR-0077` / `plot-manager.md` 里「无覆写基准可拧」这句是否要改写 → 三处均不动（用户裁决）。** 原始草稿称该句「读起来是错的」，但 `ADR-0052` 破折号后的从句已界定此处「覆写基准」指 per-encounter 基准（`EncounterSpec` 上没有这一格），并非「`CombatRulesData` 上有没有具名常量」；且 `FatiguePerDraw` 在两份 ADR 落笔时就已是具名常量，不存在支撑改写的新事实。新论据只作为 `balance.md` 的第 ④ 条理由落笔，与既有的「per-encounter 覆盖 = 每个遭遇各有一套终局速度」并行共存 —— 两条独立支撑同一结论，不互斥。
- **`ModifierTarget.FatigueAmount` 是否允许上调 → 保持双向，不加方向约束（用户确认）。** `ModifierTarget` 五项无一带方向约束，加约束才是需要理由的那一侧；上调的失控风险已被 `TurnLimit` 封顶与载体消耗性两条上界封死。落地面是零动作（`deck/common-properties.md` 本次不改），该结论以承接通道表的一句话形态写进 `balance.md`。
- **重开判据 ① 的「前 40%」现在是否填死 → 不填死，作占位并标注待实测**（依据：`balance.md` 全篇「待校准占位」的既有写法，如 `EnemyManaLimit = 5` 与 AI 兜底权重向量）。
- **原重开判据 ②「某个遭遇档需要显式调节疲劳压力」的处置 → 由三条承接通道表取代**（既然三条通道齐备，这条判据永远只会指向「用现成通道」而非「开新格」）。

## Open questions

- **`MoveCardEffect` 缺一格方位声明。** `ADR-0119` 断言「`From` 可取对手抽牌堆」，但原语表给它的 `[Export]` 只有 `From` / `To` / `Insert` / `Count` / `Selection` —— 没有 `Side : SideConstraint`，而同表的 `ModifyMomentum` / `Draw` / `Discard` / `ModifyMana` / `ApplyState` 五个原语逐个都有。「削减对手抽牌堆」在字段面上尚未闭合。补 `Side` 一格 / 复用 `EffectScope` / 保持 `From` 恒作用于己方三种收法各有代价，需一次独立推演。这不影响本次结论（四条否决论据独立成立）。

## Notes / triage

- 路由：`systems/balance.md`（唯一实质写入点，疲劳段四条理由 + 承接通道表 + 收紧判据）。`systems/services/combat-service.md` 的覆写组一节经核对**无需改动** —— 那句「疲劳量刻意不在覆写组内（同处给出理由）」未写死理由条数，回链仍然正确。
- `decisions/` 本次零改动。
- `systems/adventure-event/combat/_index.md` 的规则层措辞仍读作「直接扣减」（`ADR-0088` 已登记应在下一次触及该文件时抹平）—— 本次不触及该文件，未处理。
