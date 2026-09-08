# 成就体系整块：`Achievement` schema · 采集面 · 两档奖励

- id: 2026-09-07c-achievement-schema-collection-and-rewards
- date: 2026-09-07
- topic: systems/player-profile/achievement · systems/services/profile-service · systems/services/profile-schema-versions · systems/player-profile · systems/common-properties · systems/architecture · content · ux/screen-flow · systems/balance
- status: distilled
- distilled-to: `systems/player-profile/achievement/_index.md`、`systems/player-profile/achievement/common-properties.md`、`systems/services/profile-service.md`、`systems/services/profile-schema-versions.md`、`systems/player-profile/_index.md`、`systems/common-properties.md`、`systems/architecture.md`、`content/_index.md`、`ux/screen-flow.md`、`systems/balance.md`、`answer-logs/log-achievement-schema-and-rewards.md`

## Intent（distilled）

成就体系的三个缺口互相咬合，一次联立求解：**条目 schema**（存档形态 + 内容形态）· **`AchievementManager` 的采集面** · **两档奖励各给什么**。咬合点是「奖励一次性、不可补发」⇒ 必须有可信的幂等载体 ⇒ 幂等载体是存档字段 ⇒ 属 schema；而「何时跨档」取决于采集面把进度写在哪一次提交里。

### 存档形态 —— 两个顶层键、两条 record

```csharp
public readonly record struct Achievement          (string AchievementId, int Progress, bool Completed);
public readonly record struct AchievementGroupState(string GroupId,       int RewardedTierPercent);

IReadOnlyList<Achievement>           achievement;       // 既有字段，本次给出元素形状
IReadOnlyList<AchievementGroupState> achievementGroup;  // 新增顶层键
```

- 条目**稀疏**：只有产生过进度的成就才有条目 ⇒ 条目存在只意味着「有过进度」，故必须有 `Completed` 一格（与 Codex「条目存在 ⟺ 已解锁」不同）。
- `Completed` **不由 `Progress >= Target` 派生**：`Target` 住内容侧、可经 overlay 上调，派生会让已达成的里程碑在一次内容更新后回退，而奖励已经发了。
- `RewardedTierPercent ∈ {0, 60, 90}`、单调不减，是奖励发放的幂等水位；**不由「奖励条目已在持有列表」反推**（法则可被自愿置换换走）。
- 键名 `<Kind>Id`、集合字段名单数、展示字段一格不落存档、首批不加达成时间 / 篇章 / 序号三类元数据。

### 内容形态 —— `AchievementData` + `AchievementGroupData` + 内联 `AchievementConditionData`

条件恰一条、不做 AND / OR 组合（组合诉求的正确表达是再开一条成就）；`SignalId` 取点分字符串 + 代码侧封闭常量表 `AchievementSignalIds`，逐行带 `FilterKind` 与来源指名；`Filter` 的类型安全由配表兜住。`achievement/` 与 `achievement-group/` 在 `content/` 下开张为两个类型文件夹，条件不独立开张。

### 组内加权进度

分子 = 该组内启用且已达成的成就权重和；分母 = 该组内启用成就的权重和（走 `AllEnabled()`）；`percent = 分子 × 100 / 分母`，整数运算、全程只取整一次。水位单调不减 ⇒ 分母变化只影响未来、不撤销已发。**隐藏成就计入分母**。

### 采集面 —— 与 `CodexManager` 逐字同构的第三形态

触发采集与去重归 `AchievementManager`，写入仍组装 element 经 `ProfileManager` 单点提交；每一条采集都搭在一次已经存在的提交上。信号分两支，分界判据 = **该信号是不是一次落档变更**：落档类走服务内 spec 旁听（同住 profile-service，不经 EventBus、无反向依赖），不落档的过程量走 EventBus 被动订阅。`ReportProgress(AchievementSignal)` **整行取消**——`void` 门面漏调能上线且线上不可见，给不出任何强制。

### 两档奖励

每档恰一个专属条目（不是列表），`AchievementRewardSpec(AbilityCarrierKind Kind, string AbilityId)`、`Scope` 不进字段。**60% 档给古宝 `(Item, Player)`、90% 档给法则 `(Power, Player)`**——低门槛档给有 `Charges` 节流的那一族、高门槛档给保持极其稀缺的那一族，是既有付费分工的直接读数；分给两族同时结构性地满足「两档奖励不同」。首批不做第三种形态的账号级奖励（穷举后账号级可给之物恰好只剩这两族）。

奖励条目清单口径在既有三条校验之上补第四条：**双向唯一性**（每个奖励槽指向的条目恰被一个槽引用，且每个成就限定条目恰被一个槽引用）。它挡住「同一条目被两个组引用 ⇒ 第二次必然空发」与「无人引用的死条目」，两者都能上线且线上不可见。

### 写入通道与 API 面

两条新列各自独立分列：`AchievementElements`（按 `AchievementId` 的带符号增量、累加、按 `Target` 钳制）· `AchievementTierElements`（按 `GroupId` 的档位水位置值）。两列恒不走 modifier pipeline，恒不出现在 `SelectCost` 与 `EventOutcomeSpec` 内。API 面一删两增（删 `ReportProgress`，增 `CollectAchievements(draft)` 与 `GroupProgressPercent(groupId)`），事件面新增 `AchievementCompleted(string AchievementId)`。

## Clarifications（interview 产物）

本次输入是一份已由 2026-09-07 批量评审裁决完毕的方案草稿，两项裁决视同用户拍板：

- **隐藏成就是否计入组内进度分母** → **计入**（选项 ①）。90% 档因此必须碰到约一半隐藏成就，隐藏成就获得真实机制回报；`AchievementData.Hidden` 只承担渲染语义。⇒ 组内加权进度公式与「组内启用成就数 ≥ 10」的结构下限照原样成立。
- **`ux/screen-flow.md` 篇章结束屏「成就零呈现」的理由是否松动** → **松动措辞、不松动结论**。「成就结算」重新定性为**呈现时点**；结论「本屏成就零呈现」原样保留，理由由「读不到」改为「这一刻不该给第二条情绪线」。`life-cycle-service.md` 的轮回收尾四步时序一字不改。成就发放留在收口那一次 `TryApply` 事务内，零新增存档点 / flush 点。

草稿另有 44 项按通行做法 / 既有推演直接采纳、未出题；本次落笔逐条沿用。

## 顺带清理（同批机械落笔）

- `PlayerProfile` 字段表 `achievement` 行的写入通道由 `AchievementManager` 改为 `AchievementElements`，并新增 `achievementGroup` 行。
- 「两档奖励三选（PlayerPower / PlayerItem / 账号级）」的陈旧登记按已收窄口径订正（四处）。
- `content/_index.md` 的 `achievement/` 就绪度改 🟢，新增 `achievement-group/` 一行。
- 「采集面未定」的四处登记同批清空。

## Open questions

- **成就条目目录本身**（哪些成就、分几组、每组几条）—— 属内容编排，依赖法则 / 古宝的条目。本次只定形态与编排下限（组内启用成就数 ≥ 10）。
- **`AchievementSignalIds` 的首批清单** —— 形态已定，具体有哪些信号随成就目录一并定。
- **`achievement` / `achievementGroup` 两个顶层键是否进透明段、是否受回声校验约束** —— 权威在 `backend-design-documents/contracts/profile-sync.md` §5，本库判不了。倾向不进（成就不参与后端复算、不承载付费凭证、被篡改无跨端结算后果）；若成立则后端零配合。
