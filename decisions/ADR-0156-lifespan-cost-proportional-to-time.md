# ADR-0156 — `lifeSpanCost` 的定价形状：`round(t(type) × λ(chapter))`，正比于玩家实际耗时

- **状态：** Accepted
- **日期：** 2026-09-03
- **来源：** handoffs/2026-09-03-lifespan-cost-table-and-budget-scale.md

## 背景

`lifeSpanCost` 在本库里只有一个职责——控制篇章时长。此前它是一张「事件类型 × 篇章」的定价表，但**每格取值没有可复算的来源**：三条相对关系各自被论证过（Research 最贵 · Travel 最便宜 · Combat 三档分别给值），格与格之间却是孤立的经验数字。重定价时只能逐格重估，而调时长本该是「改一张表」的事。

更硬的约束是套利：若某类事件时间贵而寿元便宜，它的单位时间价就低于其他类型，最优策略变成尽量只选它，篇章时长随之爆表——而旋钮精度正是这张表存在的唯一理由。

## 决策

**每格 `lifeSpanCost` = `round(t(type) × λ(chapter))`，半值一律四舍五入向上。**

- **`t(type)` 是一张标定台账**（单位分钟，逐类耗时），住 `systems/balance.md`，**不进任何 `Resource`**；Explore 一行按整个条目池的真身分布期望标定，产出仍是与任何具体真身无关的常数。
- **`λ(chapter)` 由一条反推式（篇章预算 / 回寿 / 失败期望扣减 / 结转四项联立）解出**，八个输入连同两个待实测校准的标定假设全部写进 `systems/balance.md`，使全表可复算。
- **重定价时改 λ 或改 `t`，整张表自动重算。**
- 载体是 `LifeSpanCostTableData`，一份独立的 `ISingletonContent`，**不并入 `CombatRulesData`**；经 `Content.Single<T>()` 取。

逐格取值、`t` 台账、λ 反推式与三条加载期校验 → `systems/balance.md`。

## 理由

- **耗时正比是唯一不产生套利的定价形状**：单位时间价对所有事件类型相等，玩家就没有「只做某一类」的最优策略，`lifeSpanCost` 才真的是时长旋钮。
- **它把三条各自论证过的既定相对关系统一为一条式子**——Research 最贵 ⟸ 闭关最慢；Travel 最便宜 ⟸ 结算是毫秒级；Combat 三档分别给值 ⟸ 那是三个不同的 `t`。原本三条独立结论，现在是同一条式子的三个代入。
- **载体分开的判据是覆写纪律相反**：`LifeSpanCostTableData` 不接受任何覆写参数，而 `CombatRulesData` 可被 `EncounterSpec` 覆写；消费者也不同（future-event-service 的物化阶段 vs combat-service）。

## 备选方案

- **逐格手写经验值** — 否决：格与格之间无可复算关系，重定价即逐格重估，且无机制阻止套利。
- **把已取整的格子字面放大（量纲放大时）** — 否决：那会让 ch1 → ch2 的变化率一位不改，量纲改动买的唯一东西（分辨率）当场落空；放大必须发生在 λ 层。
- **抬高 `t(Research)` 以让 ch3 Research 成为全类型最贵** — 否决：与耗时驱动的定价形状正面相抵；改为收窄解读「在玩家可自由比价的行之间最高」。
- **并入 `CombatRulesData`** — 否决：覆写纪律相反、消费者不同。

## 后果

- **`t` 是推导来源、不是运行期字段**，绝不进 `.tres`；落表的是算出来的那些格。
- **结转是 ch2 的必要预算构成**（不计结转时 `λ_2` 不高于 `λ_1`）——这条须在 `systems/balance.md` 与 `systems/character-profile/life-span.md` 明写，不留暗账；把 ch1 花到只剩个位数的玩家在 ch2 面对结构性偏紧的预算，是有意的失败面。
- **条目级偏移按比例在新表上重算**，不是把旧的绝对偏移照搬；落点是 `/audit-content` 的一项汇总，不进加载期校验。
- **三条加载期校验**：任一格 < 0 → `PushError`；某章 `Travel == 0` → `PushError`；`Travel` 越出相对 `Exchange` 的既定区间 → `PushWarning`（分母取 `Exchange` 并在两处写死，堵零成本 reroll）。
- **两个标定假设（熟练玩家败率 · `E[道念差]`）显式标注「待实测校准，不是设计结论」**，明令不得引为承重依据 → `open-questions.md`。
- 受约束的文档：`systems/balance.md`（定价表 · `t` 台账 · λ 反推式 · 载体与校验）· `systems/character-profile/life-span.md` · `systems/game-progression.md` · `systems/adventure-event/*` · `decisions/ADR-0109-lifespan-cost-fixed-value.md` · `decisions/ADR-0031-lifespan-budget-countdown.md`。
