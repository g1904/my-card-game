# achievements

> 成就 / **Achievements** —— 账号级、分组的成就与其两档一次性奖励。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **Achievements = 账号级成就，独立于任何单次轮回。** 由 PlayerProfile 持有（`List<Achievements>`），跨轮回持久，随账号存于云端权威主档。Source: `10-handoffs/2026-07-24-docs-restructure-class-model.md`。
- **分组 + 两档一次性奖励（已定案）。** 成就按类别分组；每组按**组内加权进度**分两档一次性奖励：达 **60%** 发一次、达 **90%** 再发一次，两档奖励不同。**目录 80% 条目可见、20% 为隐藏成就**（达成后才显示）。玩家只能查看进度 / 领取奖励。详见 `40-ux/screen-flow.md`。Source: `10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。
- **服务归属：profile-service 的 AchievementManager。** 成就进度采集与奖励发放归 `20-systems/services/profile-service.md`；写入仍经 ProfileManager 单点提交。Source: `10-handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md`。
- **本子系统成文件夹（已定案）。** 与 `player-item/` / `player-power/` 并列成文件夹（有子结构）；`account-info` / `game-setting` 结构轻，各为独立 markdown。Source: `10-handoffs/2026-07-26-event-priority-skip-semantics-and-hotfix-scope.md`。

> 具体的成就条目字段、进度模型等共有属性见 `common-properties.md`。

## 决策(-> ADR)
> _已定案的决定链接到 50-decisions/ADR-####。_

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **两档各发放何种奖励未定：** 阈值（60% / 90%）、一次性、80/20 可见比例已定；发放的是 PlayerPower / PlayerItem / 其他账号级奖励待定。→ `40-ux/screen-flow.md`。
- **AchievementManager 的触发采集面未定：** 成就进度靠订阅 EventBus 被动采集（解耦但易漏）还是各服务主动上报（可靠但反向依赖）？→ `20-systems/services/profile-service.md`。
- **成就条目 schema 与进度模型未定：** 分组结构、加权进度的权重来源、条目触发条件、隐藏成就的揭示时机均未设计。

## 对应
提炼至：`.claude/knowledge/systems/player-profile/achievements/`（待建）。
