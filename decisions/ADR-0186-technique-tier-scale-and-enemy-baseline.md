# ADR-0186 — `MaxTier` 上界 5、每层 +20%；敌人层数篇章基准档 2 / 3 / 4

- **状态：** Accepted
- **日期：** 2026-09-07
- **来源：** handoffs/2026-09-07-combat-scale-baseline.md · answer-logs/log-combat-scale-baseline.md

## 背景

`MaxTier` 的取值是 starter deck、`InitialTier` 与角色模板池内容量账的共同硬阻；敌人层数若不设护栏，就等于在唯一可见的难度刻度（等级）之外再开一条不可见的强度轴。

## 决策

**`MaxTier` 设计上界取 5**（逐条目字段、不是全局常量；首批多数功法写 2–3 层）。

**每层替换幅度 = 该组卡牌效果量 +20%**（同费更强，费用带不在层内上移）。

**敌人功法层数的篇章基准档 = 2 / 3 / 4**，逐条目偏离 ≤ ±1 ⇒ 实际支撑集 1–3 / 2–4 / 3–5，恰落在上界 5 之内。

## 理由

`MaxTier = 5` 下 tier1 → tier5 总倍率 1.2⁴ ≈ 2.07×，与「mana 从 5 涨到 11.5 = 2.3×」同量级 ⇒ **两条成长线不互相压过对方**（`systems/character-profile/deck/_index.md`）。

取 30% 则总倍率 2.86×，卡组层数会盖过 mana 成为唯一成长面，与「构筑的长期成长主要体现在 `manaLimit` 上」相抵（`systems/balance.md`）。

## 备选方案

- **每层 +30%** — 否决：理由如上。
- `MaxTier` 随灵根契合度折减 / 抬升 — 在更早一次决策中已否决，本次未重开。

## 后果

- 约束了「一档层数差 ≈ 一档 `diff` 落差」的比值表（`systems/balance.md`）。
- **代价明写：ch3 只留 1 档余量**——越阶追分因此不能由卡组承担，见 `decisions/ADR-0187-chapter-three-overlevel-catchup-carrier.md`。
- 与 `decisions/ADR-0185-starting-deck-and-enemy-deck-sizes.md` 互为前提：15 = 3 × 5 且每门 5 张 × 5 层是同一本产能账。
