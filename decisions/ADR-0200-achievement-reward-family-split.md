# ADR-0200 — 成就两档奖励各给恰一个专属条目：60% 档古宝、90% 档法则

- **状态：** Accepted
- **日期：** 2026-09-07
- **来源：** handoffs/2026-09-07c-achievement-schema-collection-and-rewards.md · answer-logs/log-achievement-schema-and-rewards.md

## 背景

「两档奖励三选（PlayerPower / PlayerItem / 账号级）」的旧登记散在四处未收窄；而「奖励一次性、不可补发」要求发放恒不落空，形态必须先定死。

## 决策

**每档恰一个专属条目（不是列表）**，承载形态 `AchievementRewardSpec(AbilityCarrierKind Kind, string AbilityId)`，**`Scope` 不进字段**。

**60% 档 → 古宝 `(Item, Player)`；90% 档 → 法则 `(Power, Player)`。首批不做第三种形态的账号级奖励。**

奖励条目清单在既有三条校验之上补第四条**双向唯一性**：每个奖励槽指向的条目恰被一个槽引用，且每个成就限定条目恰被一个槽引用；失败时报出两侧 `Id`。

## 理由

`systems/player-profile/achievement/_index.md`：低门槛档给节流的那一族、高门槛档给稀缺的那一族，是这条分工的直接读数；**「两档奖励不同」由结构兑现，不依赖内容作者记得写成两样东西**；`AchievementReward` 在合法子集表上恰好开两格，两档各占一格，表上没有一格是死的。

`Scope` 不进字段的依据：写进字段等于允许写错一个恒定值。

第四条校验的依据：同一条目被两个组引用 ⇒ 第二次发放必然撞上第三条校验，**而那一刻奖励已经「发了」、玩家什么也没拿到**；无人引用的成就限定条目 ⇒ 一条永远不可能被任何渠道拿到的死条目。

## 备选方案

- **每档给一个列表** — 否决：单条使校验逐条可判；要给更多的正确加法是再开一个成就组。
- **第三种形态的账号级奖励** — 穷举后否决：图鉴走「接触即记」给不出来 · 账号级可支配货币本作没有 · 重试上限属 `PlayerEntitlement` · 纯外观首批不做 · 寿元是角色级。
- **成就奖励也走随机抽取** / **指定通用条目 + 已持有则改发别的** — 均否决。

## 后果

- 成就目录与内容目录一一对应地一起增长（**内容侧工作量代价明写**）。
- 成就限定条目的 `Rarity` 只剩展示语义。
- 第四条校验落**发布管线**大声失败，不新增管线。
- 约束 `systems/common-properties.md` · `ux/screen-flow.md` · `content/_index.md` · `systems/monetization.md` 逐处按两族分工表述。
