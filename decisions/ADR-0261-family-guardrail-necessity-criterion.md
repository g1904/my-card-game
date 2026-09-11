# ADR-0261 — 「一个道具功能族需不需要独立供给护栏」的判据 = 它的产出是否进入某条已被反推封账的预算线

- **状态：** Accepted
- **日期：** 2026-09-10
- **来源：** handoffs/2026-09-10-item-family-supply-guardrails.md · answer-logs/log-item-family-supply-guardrails.md

## 背景

回寿法宝拿到了三格口径（L-1 出现频率 / L-2 库存深度 / L-3 定价）。照搬到其余族上会得到一份逐族各写一套的表——而道具能表达的功能族本身会随原语增减而变，那份表从写下起就注定漂移。真正缺的是**判据**：哪些族需要独立护栏，哪些不需要。

## 决策

**一个道具功能族需要独立的供给护栏，当且仅当它产出的量进入某条已被反推封账的预算线**（λ 反推的寿元账 `B_c` / `R_c` · 货币账 `I(c)` / `J(c)` · 经验账 `G_c` / `D_c` · 卡组规模口径）。**日后新增效果原语或放宽某一列时照这条核对。**

逐列落位：

- **战斗内八原语的六族一条都不进** —— 产出随战斗结束一并消失、不落 Profile、不跨事件；`counters` 那一支已由 `I-9` 封死（道具没有宿主 `AbilityData`，键拼不出）。它们由「强度」维度的既有三件套（`itemPowerRatio(Charges)` 折价系数 · 25 格定价表 · 稀有度权重表）完整承接，**不需要第四套口径**。
- **战斗外仍开三列**（`Elements` / `CodexElements` / `Stats`）：白名单收窄后 `Elements` 只剩回寿；`CodexElements`（使用后幂等收录一条图鉴词条）与 `Stats`（纯计数自增）两族**一条都不进任何账** ⇒ 同样不需要三格口径。

→ `systems/character-profile/item/_index.md`。

## 理由

`systems/character-profile/item/_index.md`：三格口径的**唯一职责**是让某本已封的账可复算。一个不进任何账的族加上三格口径，既不增加任何保证，又会在铺内容时持续产生无信息的核对项——这与「不为一个不可机械校验的参考再加一把同样不可校验的闸」（`decisions/ADR-0244-single-strength-gate-baseline-momentum.md`）是同一条纪律。

判据写成**覆盖三列**的形态，而不是「战斗外只有一个族」这种会被证伪的断言——后者在下一次放宽白名单时即失真。

## 备选方案

- **逐族各写一套 L-1 / L-2 / L-3** — 否决：族的枚举随原语变动，表从写下起即注定漂移。
- **断言「战斗外只有一个族」** — 否决：会被下一次白名单放宽证伪。

## 后果

- **推论：三格口径在战斗内族上退化为既有物** —— L-1 退化为族占比 + 条目数矩阵，L-3 退化为「读表、不填 `PriceOffset`」，两者都已存在；战斗内族只欠 L-2（库存深度）那一半，由 `decisions/ADR-0262-exchange-per-kind-stock-depth.md` 补齐。
- 它是日后放宽 `OutOfCombatUseOutcome` 可写面时的核对入口（与 `decisions/ADR-0260-item-outofcombat-key-whitelist.md` 的可逆条件配套使用）。
