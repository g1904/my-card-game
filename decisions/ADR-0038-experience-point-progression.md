# ADR-0038 — 等级成长走 `experiencePoint`：事件给经验值而非等级；阈值曲线境界内递增、境界间重置量纲

- **状态：** Accepted
- **日期：** 2026-08-02
- **来源：** handoffs/2026-08-02-momentum-conversion-reward-structure-and-mtg-stack.md, handoffs/2026-08-06d-combat-open-questions-mass-closure.md

## 背景

初版是「事件 reward 直接给等级」。这让等级成为一个整数台阶——奖励的厚薄只能表达为「给 0 级还是 1 级」，中间没有刻度，且同一场战斗的胜负差异无法落在同一个量纲上。

## 决策

等级成长走 **`experiencePoint`**：事件奖励发放的是**经验值**而非等级本身，每级各有阈值。

阈值曲线**境界内递增、境界间重置量纲**。

阈值表、给予量分布与 `ExperienceGrade` 分档 → `systems/balance.md`；模型与全局序的关系 → `systems/game-progression.md`。

## 理由

经验值给了奖励厚薄一把连续的尺子，胜负、事件档位、Finale 加厚都可以落在同一量纲上。

**境界间重置量纲**的理由不是美观，而是既定的「进阶即归位初期」：跨境界的难度阶梯**已由 `baseMomentum` 跨度独占承载**（→ `ADR-0034`），经验侧再叠一条跨境界曲线就是第二条难度阶梯，两条互相掩盖。

## 备选方案

- **事件 reward 直接给等级** — 推翻（08-02）：整数台阶无中间刻度，胜负差异无法同量纲表达。
- **阈值曲线跨境界连续递增** — 否决：与 `baseMomentum` 构成第二条跨境界难度曲线。
- **按 `DefeatReason` 分解经验统计** — 否决（08-06d）：统计层的切分不该反过来定义规则层的量纲。

## 后果

- `experiencePoint` 是 `CharacterProfile` 的一格，写入通道走 `CostKey`。
- 阈值曲线与给予量分布留在 `systems/balance.md` 的统计校准面，本 ADR 不定取值。
- 失败侧的经验给予（同档 50%、下限 1）是这条模型的一个参数，不是另一条规则。
