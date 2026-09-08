# Answer log finale-distance-foresight

- 日期：2026-09-06
- 来源：`inbox/solution-draft-finale-distance-foresight.md` → `handoffs/2026-09-06-finale-trigger-and-foresight-declined.md`
- 移出条数：1

## 移出条目

**中长期规划感的来源（08-06c 大幅收窄 · 08-30 再收窄，只剩「还有几步到 Finale」那一角）：没有任何通道回答「还有几步到 Finale」，是否需要轮回内的补充（篇章进度条？前瞻提示？），还是接受「知道自己在长多快、不知道还剩多远」** → **不补。三章一律不显示任何「距 Finale / 距圆满」的读数**（用户裁决 B，未采纳草稿推荐的 A「加一格『距圆满 N 级』读数」）。接受「知道自己在长多快、不知道还剩多远」，保住「一步一步走下去」的未知感。

- **落笔面收缩到零：** 角色状态条不动，`ux/screen-flow.md` 与 `systems/services/future-event-service.md` 均零改动；无新增字段 / schema 迁移 / 存档点 / 翻译键。
- **被接受的代价（明知而选）：** ch2 / ch3 中段那条已被认定「必须补偿」的节奏缺口只补一半；失败螺旋只能事后发觉；除等级外无第二个量能回答该角。
- **两条附带否决理由已写进主题文档正文**（防止日后重新提出）：篇章进度条的分母在运行中不存在、且事件数不是 Finale 的闸门；「还需约 M 个事件」的估算要暴露隐藏的经验档位映射且是会被打脸的期望值。
- **连带定案：** 空间那一角不再是待答缺口，而是已裁决的取舍 ⇒ 该条在待答清单分片与 `systems/game-progression.md` 的 `## 待决问题` 两处同时关闭。
- **同批落笔的一条事实：** Finale 触发条件 = `level == 该境界末级`（全局序 13 / 17 / 21），由 future-event-service 物化时以 `Priority = 1` / `prioReason = Finale` 抬升。此前只在 `systems/services/future-event-service.md` 有落点，本次钉进 `systems/game-progression.md` 的承重推论 ②（只写判定式 + 回链，不复述抬升条件表）。

（归档去向：`systems/game-progression.md`「修行等级体系（realm + level）」小节的承重推论 ② + 新增「承重取向：轮回内不提供任何『距 Finale』读数」bullet；`## 待决问题` 首条移出。）

**子项：ch1 是否与 ch2 / ch3 一视同仁地显示** → **不适用而消解**——三章都不显示，「哪几章显示」不再存在。

## 未答定、仍留在待答清单的部分

无——该条整条答定。

另注（本次**不登记**为新待答项）：`systems/game-progression.md` 的「满级后 UI 标注『已圆满』」是一条已定但尚无落点的标注；草稿的方案 A 本会给它落点（状态条那一格），A 被否决后它仍无落点。它不在本条的覆盖面内、也非本次新产生，故不因关闭本条而顺带登记。
