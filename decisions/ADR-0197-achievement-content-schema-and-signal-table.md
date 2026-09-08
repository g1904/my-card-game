# ADR-0197 — 成就内容形态：条件恰一条不做组合；`SignalId` 取点分字符串 + 封闭常量表

- **状态：** Accepted
- **日期：** 2026-09-07
- **来源：** handoffs/2026-09-07c-achievement-schema-collection-and-rewards.md · answer-logs/log-achievement-schema-and-rewards.md

## 背景

条目 schema 是采集面与奖励幂等的共同前置——不定它，`AchievementManager` 采集什么、按什么判达成都无从写起。

## 决策

**内容形态取三类：`AchievementData` + `AchievementGroupData` + 内联的 `AchievementConditionData`。**

**条件恰一条，不做 AND / OR 组合。**

**`SignalId` 取点分字符串 + 代码侧封闭常量表 `AchievementSignalIds`**（逐行带 `FilterKind ∈ {None, ContentId, Enum, Int}` 与来源指名），**不用 C# 枚举**。

`achievement/` 与 `achievement-group/` 在 `content/` 下开张为两个类型文件夹；条件不独立开张。字段清单、五条口径与启动期两条断言见 `systems/player-profile/achievement/common-properties.md`。

## 理由

`systems/player-profile/achievement/common-properties.md`：同库先例 `EffectCondition` 取的是「封闭谓词 + AND 语义 + 单一落点」；**组合谓词在本作的正确表达是再开一条成就**，而不是把条目做成一棵表达式树。

`SignalId` 不用枚举的依据：`.tres` 按序号引用枚举，**枚举重排会静默错位**。`Filter` 的类型安全由配表兜住，不由字段类型兜住。

## 备选方案

- `SignalId` 用 C# 枚举 — 否决：`.tres` 按序号引用、重排静默错位。
- 条件做成表达式树 / AND-OR 组合 — 否决：理由如上；**代价明写——「同时满足 A 与 B」类成就首批写不出来**。
- `AchievementConditionData` 独立开张为内容类型 — 否决：照 `AbilityData` 的既定处置内联。

## 后果

- 约束内容侧只能写单条件成就。
- `Weight == 0` 在加载期 `PushError`。
- `AchievementSignalIds` 的首批清单仍开放，逐条落在 `systems/player-profile/achievement/common-properties.md`。
