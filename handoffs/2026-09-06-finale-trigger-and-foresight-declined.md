# Finale 触发条件钉入进程侧 · 「距 Finale」前瞻读数不做

- id: 2026-09-06-finale-trigger-and-foresight-declined
- date: 2026-09-06
- topic: systems/game-progression
- status: distilled
- distilled-to: systems/game-progression.md

## Intent（distilled）

中长期规划感的三角中，地理方位感（`LocationCodex` 记连边）与进度感的时间那一半（经验条常驻 EventOption 选择界面的角色状态条）都已落地，**仍悬着的是空间那一角**：全库没有任何通道回答「还有几步到 Finale」。玩家读得到「我在长多快」（经验条）与「我还能走多远」（寿元恒精确），读不到「我还需要走多远」。

本次定两件事。

### 一、Finale 的触发条件是一条等级判定式，进程侧此前只有定性表述

Finale 的出现条件 = **`level == 该境界末级`（全局序 13 / 17 / 21）**，由 future-event-service 在物化时以 `Priority = 1` 抬升（`prioReason = Finale`）；Finale 不绑定 location，也不受 `eventCountLimit` 牵制。

这条判定式的权威一直在 `systems/services/future-event-service.md`（抬升条件表 + 置位段伪码），而 `systems/game-progression.md` 侧只有两处**定性**表述（「Finale 的出现条件 = 角色已达本境界巅峰」「是一条等级条件，与所在 location 无关」），既没有判定式也没有 13 / 17 / 21。同一小节上方十几行就是全局序表（1–22），读者读到「本境界巅峰」时须跳到另一份服务文档才能把它换算成一个数。

⇒ **把「承重推论 ②」由定性表述钉成判定式，并回链服务文档**。进程侧只写判定式 + 一句回链，**不复述** future-event-service 的完整抬升条件表——复述即制造第二权威。

### 二、轮回内不提供任何「距 Finale / 距圆满」的读数（三章一律不显示）

**不补这一角。** 接受「知道自己在长多快、不知道还剩多远」，保住「一步一步走下去」的未知感。

- **代价明知而接受：** ch2 / ch3 中段那条已被本库自己认定「必须补偿」的节奏缺口只补了「长多快」这一半；**失败螺旋只能事后发觉**——玩家在寿元见底那一刻才知道自己卡级，而那正是全游戏情绪最低点；且除等级外没有第二个量能回答这一角。
- **落笔面收缩到零：** 角色状态条不动，`ux/screen-flow.md` 与 `systems/services/future-event-service.md` 均**零改动**；无新增字段、无 schema 迁移、无新增存档点、无新增翻译键。

**两条附带的否决理由须留在正文**（不写下来日后必被重新提出）：

- **篇章进度条（`x / N`）：分母在轮回进行中不存在。** 篇章事件总数 ≈ 途经各 location 的容量之和，而往后途经哪些 location 由玩家自己在 Travel 闸门处选，各地域 `EventCountLimit` 取值不同 ⇒ 运行中算不出 N。**且事件数不是 Finale 的闸门**——闸门是等级，进度条会把注意力引向一个不是闸的量。
- **「预计还需约 M 个事件」的估算读数：** 要算 M 必须暴露隐藏的经验档位映射（`Minor / Standard / Major`），直接撞「eventOption 卡片不标注该事件的经验产出档位」这条既定纪律；且算出的是会被两次失败打脸的期望值。与「寿元恒精确、但否决『大限将至』一类预警文案」同调：**给一个不会错的数，不给一个会错的估。**

**连带定案：** 既然不补，「空间那一角」不再是待答缺口，而是**已裁决的取舍** ⇒ 「中长期规划感的来源」在待答清单与 `systems/game-progression.md` 的待决问题小节两处同时关闭。

## Clarifications

- 这一角到底补不补？ → **不补，三章一律不显示**（用户裁决；未采纳原草稿推荐的「补一格『距圆满 N 级』读数」）。用户在明知代价（节奏缺口只补一半 · 失败螺旋只能事后发觉 · 该角将长期无第二个量能回答）的前提下选择保住未知感。
- ch1 是否与 ch2 / ch3 一视同仁地显示？ → **不适用而消解**——三章都不显示，「哪几章显示」不再存在。

## Open questions

- **无本次新产生的待答项。**
- 另注（**本次不登记**，仅记录）：`systems/game-progression.md` 的「满级后经验直接丢弃 → 缓解为满级后 UI 标注『已圆满』」这条标注**已定但仍无落点**。它不在本次答定的那条待答项的覆盖面内，也不由本次改动引入。

## Notes / triage

- 来源草稿：`inbox/solution-draft-finale-distance-foresight.md`（主体提案 A–G 各节整体作废，只消费上述两项）。
- 落点：`systems/game-progression.md`「修行等级体系（realm + level）」小节（承重推论 ② 钉成判定式 + 新增「承重取向：不提供距 Finale 读数」bullet）；`## 待决问题` 首条移出。
