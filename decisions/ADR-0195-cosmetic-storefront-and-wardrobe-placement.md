# ADR-0195 — 外观购买落 Store 屏内、换装落角色选择屏；不开 Wardrobe 入口

- **状态：** Accepted
- **日期：** 2026-09-07
- **来源：** handoffs/2026-09-07b-cosmetic-monetization-shape.md · answer-logs/log-cosmetic-monetization-shape.md

## 背景

新增一个付费面天然拉出「要不要开一个 Wardrobe 主菜单入口」这一问。

## 决策

**外观的购买呈现落 Store 屏内**——不新增屏、不新增主菜单入口。

**换装的落点是角色选择屏**（玩家已经会在那里看到角色形象，换装是就地操作而非一次跳转），**明确排除设置屏**。

## 理由

`systems/monetization.md`：Store 已是一屏多结果态 ⇒ 外观购买是它的又一个列表 / 结果态；**主菜单入口预算已明确紧张**——同一条理由否决过「逐本图鉴开七个入口」（`decisions/ADR-0147-codex-single-entry-three-layer-browse.md`）。

设置屏被排除的依据在 `systems/player-profile/game-setting.md`：该屏语义已钉死为三段 + 一行只读诊断。

## 备选方案

- **新开 Wardrobe 主菜单入口** — 否决：理由如上。

## 后果

- `ux/screen-flow.md` 的屏清单不变。
- 列表布局、预览方式、未持有项的呈现留给落地时的 UX 专场，本条不预判。
