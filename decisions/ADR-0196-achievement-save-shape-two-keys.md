# ADR-0196 — 成就存档 = 两个顶层键两条 record；`Completed` 不由 `Progress >= Target` 派生

- **状态：** Accepted
- **日期：** 2026-09-07
- **来源：** handoffs/2026-09-07c-achievement-schema-collection-and-rewards.md · answer-logs/log-achievement-schema-and-rewards.md

## 背景

「奖励一次性、不可补发」这条既定语义要求一个可信的幂等载体；幂等载体必须是存档字段；于是它属 schema，必须先定形状。

## 决策

**两个顶层键、两条 record：**

- `Achievement(string AchievementId, int Progress, bool Completed)`
- `AchievementGroupState(string GroupId, int RewardedTierPercent)`

条目**稀疏**；**`Completed` 不由 `Progress >= Target` 派生**；`RewardedTierPercent ∈ {0, 60, 90}` 单调不减，且**不由「奖励条目已在持有列表」反推**。键名 `<Kind>Id`、集合字段名单数、展示字段一格不落存档、首批不加达成时间 / 篇章 / 序号三类元数据。

六行读档校验表见 `systems/player-profile/achievement/common-properties.md`。

## 理由

`systems/player-profile/achievement/common-properties.md`：`Target` 住内容侧、可经 overlay 上调；派生会让**已达成的里程碑在一次内容更新后回退**，而奖励已经发出去且不可补发——这与「派生量不可靠即不能当幂等键」是同一条判据。

水位不由持有列表反推的依据同源：法则可被自愿置换换走（`decisions/ADR-0048-consented-power-loss-ladder.md`）。

## 备选方案

- `Completed` 由 `Progress >= Target` 派生 — 否决：理由如上。
- 水位由持有列表反推 — 否决：法则可被置换换走。
- 首批加达成时间 / 篇章 / 序号 — 否决：客户端时钟不可信 · 实例信息不进账号级静态面 · 篇章对玩家无信息量。加一格是在 record 上加字段、老档补默认值、零迁移，预先加没有收益。

## 后果

- 新增顶层键 `achievementGroup`（v1 清单 +1 行，**首发前仍属 `schemaVersion` 1、不 bump、零迁移**）。
- `RewardedTierPercent ∉ {0, 60, 90}` 时**向下**取档——向上等于吞掉一次未发放的一次性奖励。
- 约束 `systems/player-profile/_index.md` 字段表与 `systems/services/profile-schema-versions.md` 逐版登记。
