# ADR-0189 — 「每回合 +X 道念」的永久物允许，配 rate `ManaCost ≈ X × 3` 与 `X ≤ 20% × manaLimit`

- **状态：** Accepted
- **日期：** 2026-09-07
- **来源：** handoffs/2026-09-07-combat-scale-baseline.md · answer-logs/log-combat-scale-baseline.md

## 背景

`systems/balance.md` 有一条硬规则禁止「每回合 +X 道念」。若把它读成全域禁令，卡牌侧永久物（`Enchantment`）的核心 build 表达面当场消失。

## 决策

**允许「每回合 +X 道念」的永久物**，并配一条编排 rate：**`ManaCost ≈ X × 3`**（回本点落在打出后第 3 个己方回合），**单条 `X ≤ 20% × manaLimit(篇章)`**（ch1 ≤ 1 · ch2 ≤ 2 · ch3 ≤ 2）。

即：把那条禁令**收窄为按载体的作用域判据**——它约束的是法则与神通，不约束卡牌侧永久物。

## 理由

`systems/character-profile/deck/common-properties.md`：该禁令的三条前提（跨轮回累积 · 不可被针对 · 无需付费）在卡牌侧**一条都不成立**——永久物每次都付 mana、可被 `RemoveEntryEffect` 拆掉。

回本点定在第 3 回合的依据：己方仅 5 个回合，回本点若早于第 3 回合则「先手抢铺场」成为唯一解，与「先手 tempo 优势不存在」的既定结构相抵。

## 备选方案

未权衡其他方案（该项在 handoff 中记为标准默认、直接采纳）。

## 后果

- 约束永久物的定价与 X 的上界，两者互相锁定。
- 把一条看似全域的禁令改造为按载体判定，`systems/character-profile/power/_index.md` 的跨载体边界表因此须与本条对齐。
