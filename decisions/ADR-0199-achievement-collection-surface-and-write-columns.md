# ADR-0199 — `AchievementManager` 采集面与 `CodexManager` 同构；写入开两条新列，API 面一删两增

- **状态：** Accepted
- **日期：** 2026-09-07
- **来源：** handoffs/2026-09-07c-achievement-schema-collection-and-rewards.md · answer-logs/log-achievement-schema-and-rewards.md

## 背景

「何时跨档」取决于采集面把进度写在哪一次提交里。而旧 API 面上的 `void ReportProgress(AchievementSignal)` 与四处「采集面未定」的登记互相抵触，两者不能同时成立。

## 决策

**采集面 = 与 `CodexManager` 逐字同构的第三形态**：触发采集与去重归 `AchievementManager`，**写入仍组装 element 经 `ProfileManager` 单点提交**，每条采集搭在一次已存在的提交上。**不新增存档点、不新增 push、不新增决策点。**

**信号分两支，分界判据 = 该信号是不是一次落档变更**：落档类走服务内 spec 旁听、不经 EventBus；过程量走 EventBus 被动订阅。

**写入通道 = 两条独立新列 `AchievementElements` / `AchievementTierElements`**，恒不走 modifier pipeline、恒不出现在 `SelectCost` 与 `EventOutcomeSpec` 内。

**API 面一删两增**：删 `ReportProgress`，增 `CollectAchievements(draft)` 与 `GroupProgressPercent(groupId)`；事件面新增 `AchievementCompleted(string AchievementId)`。

## 理由

`systems/services/profile-service.md`：`AchievementManager` 与 `ProfileManager` **同住本服务**，提交成功后由服务内部回调把命中的信号入 pending 队列——**同服务内、不经 EventBus、不构成任何反向依赖**。

它在收口组装里落在**投影之前**（与 `CodexElements` 同批同位）——成就奖励授予会改变持有列表，落在投影之前正是它该在的位置。

**内容不得自己发成就**（同上文件）。

## 备选方案

- 保留 `void ReportProgress(AchievementSignal)` 门面 — 整行取消：`void` 门面漏调能上线且线上不可见，给不出任何强制（纪律阶梯判据）。
- 两条新列合并成一条通则 — 否决：逐列各自独立判定、不合并成通则。

## 后果

- 零新增存档点 / flush 点；轮回收尾四步时序一字不改。
- `ProfileChangeSpec` +2 列（v1 清单 +2 行、不 bump）；EventBus +1 事件。
- 约束 `systems/architecture.md` · `systems/services/profile-schema-versions.md` · `systems/player-profile/_index.md` 的写入通道列同步登记；`systems/services/plot-manager.md` 保留唯一可预见消费方的预留条款。
