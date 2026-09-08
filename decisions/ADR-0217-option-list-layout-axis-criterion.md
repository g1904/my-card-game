# ADR-0217 — 候选项排布轴判据：推进进程的择一走横滑，面板内的择一与列举走纵向

- **状态：** Accepted
- **日期：** 2026-09-08
- **来源：** handoffs/2026-09-08-portrait-option-list.md · answer-logs/log-portrait-option-list.md

## 背景

每新增一个决策面（战后奖励、置换、构筑槽、剧本分支、Exchange、储物袋）都要重裁一次排布——这正是「不发明第二种选择语言」所要防的漂移。

## 决策

**一批候选项的排布轴由一条判据决定：推进进程的择一 → 横滑等宽 carousel；面板内 / 事件内的择一与列举 → 纵向堆叠或网格。**

六处既有落点照此归位：eventOptions 与角色选择屏在横滑侧；Exchange 网格、剧本分支按钮、储物袋 / 图鉴网格、战后奖励 / 置换 / 构筑槽在纵向侧。**新增决策面按判据落位，不逐个重裁。**

## 理由

`ux/screen-flow.md` · `ux/_index.md`：**横滑是「推进进程」这一层的专属语汇**——复用横滑会让两个层级的操作读成同一件事。

## 备选方案

未权衡其他方案——本条是把已经在事实上生效的做法写成明文纪律。

## 后果

- 约束新决策面不得自选排布轴。
- 两个待答场景各落在轴的两侧 ⇒ 它们共用的不是轴而是构件与标注语言，这一点使 `decisions/ADR-0218-candidate-item-widget-and-annotation-layers.md` 成为可独立成立的一层。
- 与 `decisions/ADR-0215-post-combat-reward-panel-form.md`「绝不横滑」互为同一判据的两处应用。
