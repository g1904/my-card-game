# Answer log combat-scale-baseline

- 日期：2026-09-07
- 来源：`inbox/solution-draft-combat-scale-baseline.md` → `handoffs/2026-09-07-combat-scale-baseline.md`
- 移出条数：5

**卡牌产 / 削道念的量纲基准（承重）** → 兑换率 **1 点 mana ≈ 1 点道念**（产 / 削同刻度，在该篇章的基准层数上）；摆幅口径 `P(c) ≈ 0.9 × 5 × manaLimit(c)` ⇒ 篇章末约 29 / 40 / 52，`P/baseMomentum` ≈ 1.9 / 1.3 / 0.7。道念相关的状态与倍率：加法层启用、**乘法层首批不作用于道念两格**（保留给 `CardManaCost` / `DrawCount` / `FatigueAmount`），「每回合 +X 道念」的永久物允许并配一条 rate（`ManaCost ≈ X × 3`、`X ≤ 20% × manaLimit`）。它是**可复算的初值不是设计结论**——由 `E[道念差]` = 5 反推，与那一格同级。（`systems/balance.md` 三张标定台账 · `systems/character-profile/deck/_index.md` · `deck/common-properties.md`）

**卡组规模的实际取值** → 玩家起始 **15 张**（3 门 × 5）、中后期 **≈ 18–22 张**；敌人常用区间 **10–25 张**、常态 **15–18**、轻量档 **10–12**、天劫定制 **20–25**。15 张被三条回代钉住（`Standard` 流入 14 恰好不疲劳 / `Finale` 流入 16 触发一次扣 1 点 / `Practice` 恒不触发）。（`systems/character-profile/deck/_index.md` · `systems/enemies/_index.md` · `systems/balance.md`）

**功法的规模参数** → 一门功法 **5 张**（允许 4–6 浮动）· `MaxTier` 设计上界 **5**（仍是逐条目字段，首批多数条目写 2–3 层）· 每层替换幅度 **+20%**（同费更强，费用带不在层内上移）· 敌人功法层数的篇章基准档 **2 / 3 / 4**（既有护栏 ±1 档不变）。（`systems/character-profile/deck/_index.md` · `systems/enemies/_index.md` · `systems/balance.md`）

**牌流三个基准值 4 / 2 / 7 的取值校准** → **三项全部维持、三章统一**。三条原有依据代入平均费用后升级为可复算。**其正确性来自费用曲线上移**——若费用曲线改为不上移，4/2/7 必须逐章收紧，二者必居其一。（`systems/balance.md`「战斗规则的卡牌侧数值」）

**卡牌费用曲线是否随境界整体上移（含 `RealmBreakthroughManaBonus` 初值 1）** → **上移**，口径 `avgManaCost(c) ≈ 5 × manaLimit(c) / 14` ⇒ **2 / 3 / 4**。三章末推算按此重算后**全部落在「恰好饱和」**，ch2 / ch3 的 mana 溢出随之消解。`RealmBreakthroughManaBonus` **维持 1**（购买力三章 +0.5 / +0.33 / +0.25 张每回合，逐章递减但仍可感知）。（`systems/character-profile/mana.md` · `systems/balance.md`）

## interview 裁决（两项）

**第三篇章的越阶追分应由什么承担？** → **选 A：接受「ch3 光靠卡组追不平一次越阶」**，改由神通（单条上沿 25% × `baseMomentum`）/ 战斗内法则（老账号合计 25%）/ 道具三者承担。`baseMomentum` 表、`±2` 赋级带（`ADR-0044`）、`MaxTier` 上界 5 三者均不因此改动。代价：老账号与新账号在 ch3 的越阶能力显著分化。（`systems/balance.md` 越级追分锚点的回代表）

**起始 15 张使「常规遭遇永不疲劳」，是否触发「疲劳几乎从不触发」这条重开判据？** → **不触发。** 疲劳在每一场天劫与每一个轻量敌人上稳定现身即算咬合；一门功法 5 张 / 起始卡组 15 张维持不变，`itemPowerRatio` 的 ×1.40 项不重算。（`systems/character-profile/deck/_index.md`）

## 顺带答定

**神通的战斗内强度闸门 X** → **25%**（单条道念净贡献 / 本方 `baseMomentum`）。读法：单条神通的上沿 ≈ 老账号全部法则合计的上沿。它是评审参考上沿、不可机械校验，落纪律阶梯第 4 级。神通强度尺度的另两格（每轮回条数 · 相对同费法术的效果量系数 · 各 `RarityTier` 条目数）仍待定。（`systems/balance.md` · `systems/character-profile/power/_index.md`）
