# Answer log achievement-schema-and-rewards

- 日期：2026-09-07
- 来源：`inbox/archive/solution-draft-achievement-schema-and-rewards.md` → `handoffs/2026-09-07c-achievement-schema-collection-and-rewards.md`
- 移出条数：3 全条 + 1 部分

## 逐条移出

**成就奖励的具体条目目录 —— 两档各给什么（`open-questions/07-codex-monetization.md`）** → **60% 档给古宝 `(Item, Player)`、90% 档给法则 `(Power, Player)`**，每档恰一个成就限定的专属条目（`AchievementRewardSpec(AbilityCarrierKind Kind, string AbilityId)`，`Scope` 不进字段）。三条依据：付费分工「战斗价值主要由古宝承载、法则保持极其稀缺」的直接读数 · 分给两族使「两档奖励不同」由结构兑现 · `AchievementReward` 在合法子集表上恰好开两格。**首批不做第三种形态的账号级奖励**（穷举后账号级可给之物恰好只剩这两族）。奖励条目清单口径另补第四条加载期校验（奖励槽 ↔ 条目的双向唯一性）。→ 归档去向 `systems/player-profile/achievement/_index.md`。
> **剩余部分仍待答：** 具体奖励条目目录（哪些成就、分几组、每组配哪两个条目）属内容编排，改登记在 `open-questions/deferred-content.md`「成就条目目录」。

**成就两档奖励内容（`open-questions/deferred-content.md`）** → 同上一条，同批答结；该条改写为只欠条目的内容编排项。→ `systems/player-profile/achievement/_index.md`、`ux/screen-flow.md`。

**AchievementManager 的触发采集面（`open-questions/deferred-content.md`；另登记于 `achievement/_index.md`、`achievement/common-properties.md`、`profile-service.md` 三处主题文档待决区）** → **既不是纯 EventBus 被动订阅，也不是各服务主动上报，而是与 `CodexManager` 逐字同构的第三形态**：触发采集与去重归 `AchievementManager`，写入仍组装 element 经 `ProfileManager` 单点提交，每一条采集搭在一次已有提交上。信号分两支，分界判据 = 该信号是不是一次落档变更：落档类走**服务内 spec 旁听**（同住 profile-service，不经 EventBus、无反向依赖），不落档的过程量走 **EventBus 被动订阅**。`ReportProgress(AchievementSignal)` **整行取消**——`void` 门面的漏调能上线且线上不可见。四处登记同批清空。→ `systems/services/profile-service.md`。

**元进程持久化字段结构 —— `Achievement` 条目 schema 那一半（`open-questions/deferred-content.md`，部分移出）** → 两个顶层键、两条 record：`Achievement(string AchievementId, int Progress, bool Completed)` · `AchievementGroupState(string GroupId, int RewardedTierPercent)`；条目稀疏、`Completed` 不由 `Progress >= Target` 派生、水位 `{0, 60, 90}` 单调不减且不由持有列表反推；内容侧 `AchievementData` + `AchievementGroupData` + 内联 `AchievementConditionData`；写入通道两条新列 `AchievementElements` / `AchievementTierElements`。v1 清单补三行、仍属 `schemaVersion` 1 不 bump。→ `systems/player-profile/achievement/common-properties.md`、`systems/services/profile-service.md`、`systems/services/profile-schema-versions.md`。
> **剩余部分仍待答：** 各账号级条目的解锁 / 获取 / 失去触发。

## 同批 interview 裁决（草稿评审阶段已定，不占清单条目）

1. **隐藏成就计入组内进度分母**（选项 ①）⇒ 90% 档必须碰到约一半隐藏成就；`AchievementData.Hidden` 只承担渲染语义。
2. **`ux/screen-flow.md` 篇章结束屏「成就零呈现」松动措辞、不松动结论** ⇒「成就结算」重新定性为呈现时点，成就发放留在收口那一次 `TryApply` 事务内，零新增存档点 / flush 点；`life-cycle-service.md` 的四步时序一字不改。

## 同批连带落笔（本不在清单上）

- `PlayerProfile` 字段表 `achievement` 行写入通道由 `AchievementManager` 改为 `AchievementElements`，新增 `achievementGroup` 行（表行由 16 增至 17，序号顺延）。
- `profile-schema-versions.md` 删去两处「`achievement` 尚未进清单」占位（v1 清单末段 + 待决区一条承接项）。
- `content/_index.md`：`achievement/` 就绪度 🟠 → 🟢，新增 `achievement-group/` 一行，依赖链与「不单开类型」清单同批更新。
- `systems/common-properties.md`：`Artwork` 挂载面加 `AchievementData`；`ExclusiveSource` 段的校验条数由三条改四条。
- `systems/architecture.md`：EventBus 负载表新增 `AchievementCompleted`；`PlotArcAdvanced` 预案措辞去掉「若采集面定为被动订阅」的前提。
- `systems/balance.md`：新增 `AchievementGroupMinSize = 10` 的编排下限与推导。

## 新增待答项

无（原有条目均为收窄或改写，未产生新的独立待答项）。
