# ADR-0259 — 首批五角刻意压平在同一复杂度档；复杂度谱系由后续系列向上展开

- **状态：** Accepted
- **日期：** 2026-09-10
- **来源：** handoffs/2026-09-10-character-series-identity-and-monetization.md · answer-logs/log-character-technique-identity.md

## 背景

五行主动词的繁简天然不同（木的滚雪球运营比火的直接爆发繁得多）。此前的取向是「五个角色的复杂度差异本身是产品特色」——让玩家在选择屏上自己挑难度。但选择屏**不标推荐项**，新玩家因此要在毫无信息的前提下撞进一个可能极繁的角色。

## 决策

**首批五角刻意压平到同一复杂度档：五个都直白。** 五行动词的繁简差在首批内收窄到同档表达。

**复杂度谱系由后续系列的角色向上展开**（单灵根进阶批与双灵根批）。

**压平是内容编排取向，不是配比约束**——类型配比仍逐角色独立立形。
→ `systems/character-profile/_index.md`「角色模板池的形态」· `systems/character-profile/deck/_index.md`。

## 理由

`systems/character-profile/deck/_index.md`：**「新手友好」不由底盘统一性承担**——它改由角色选择屏的玩法简介承担，并由首批五角压平在同一复杂度档兜底。这让两条既有结论同时保住而不必互相让步：「不设统一底盘」与「不标推荐项」都原样成立，只是理由改写为「同档无需推荐」。

## 备选方案

- **维持「复杂度差异本身是产品特色」** — 否决：用户确认推翻。在不标推荐项的选择屏上，复杂度差异对新玩家是不可见的陷阱而非特色。
- **改为标注推荐 / 难度** — 否决：与 `decisions/ADR-0234-first-play-brief-without-recommendation.md` 冲突，且标难度等于承认入口不友好。

## 后果

- 三处正文与两份 ADR 的**理由句**同批改写：`systems/character-profile/_index.md` 选择屏段 · `systems/character-profile/deck/_index.md` 起始卡组段 · `ux/onboarding.md`；`decisions/ADR-0229-no-shared-starter-deck-baseline.md`（备选 / 后果）与 `decisions/ADR-0234-first-play-brief-without-recommendation.md`（背景 / 理由）**结论均保留、仅理由改写**。
- 约束对首批神通的实际设计同样生效（神通与灵根主动词的关系逐角色自由定，但不得越出同档表达）。
- 它给了后续系列一个明确的产品位：**复杂度是后续系列的卖点之一**，与 `decisions/ADR-0255-paid-character-series-track.md`「付费卖新玩法与复杂度」直接对接。
