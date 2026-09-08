# ADR-0198 — 组内加权进度只取整一次；隐藏成就计入分母，每组启用成就数 ≥ 10

- **状态：** Accepted
- **日期：** 2026-09-07
- **来源：** handoffs/2026-09-07c-achievement-schema-collection-and-rewards.md · answer-logs/log-achievement-schema-and-rewards.md

## 背景

两档奖励按组内进度发放 ⇒ 分母口径与隐藏成就的归属直接决定 90% 档是否可达，也决定隐藏成就有没有真实的机制回报。

## 决策

**组内加权进度 = `分子(启用且已达成的权重和) × 100 / 分母(启用成就权重和，走 AllEnabled())`，整数运算全程只取整一次。**

**隐藏成就计入分母**——`Hidden` 只承担渲染语义。水位单调不减 ⇒ 分母变化只影响未来。

连带的编排下限：**每个启用组的启用成就数 ≥ 10**，加载期 `PushError`。

## 理由

`systems/player-profile/achievement/common-properties.md`：**只取整一次**，与 modifier pipeline 的「同层求和 → 只乘一次 → 只取整一次」同一条纪律——分步取整会让 60 / 90 两个阈值在边界上出现 off-by-one。

隐藏计入分母的后果被正面接受：等权下做完全部可见成就只到 80%，故 90% 档**必须**碰到约一半隐藏成就。

`systems/player-profile/achievement/_index.md`：组内少于 10 条时，20% 隐藏比例在整数化后要么归零、要么占比失真，且等权下 90% 档可能根本不可达（9 条的可达百分比是 0/11/22/…/100）。

## 备选方案

- **隐藏成就排除出分母** — 用户裁决否决：否则隐藏成就没有真实的机制回报。

## 后果

- 90% 档成为长尾目标。
- **代价明写：成就屏上会出现一段无法归因的缺口**，那正是隐藏成就的设计意图。
- 不需要第四格 `Revealed`——揭示条件即 `Completed`。
- 约束 `ux/screen-flow.md` 的成就呈现与 `systems/services/profile-service.md` 的 `GroupProgressPercent` 唯一落点。
