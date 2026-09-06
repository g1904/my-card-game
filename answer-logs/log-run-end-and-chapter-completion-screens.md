# Answer log run-end-and-chapter-completion-screens

- 日期：2026-09-05
- 来源：`inbox/solution-draft-run-end-and-chapter-completion-screens.md`（已评审 · 用户裁定三项取向）→ `handoffs/2026-09-05-chapter-end-screen.md`
- 移出条数：2

## 移出

**篇章通关（`completed`）那一刻的呈现（原 `open-questions/06-meta-progression.md`）** → 新增 **`ChapterEndScreen` = 一屏三变体**，变体轴取 `chapter`（1 / 2 / 3）；与既有的 `CycleEndScreen` 合成**轮回收尾族**的两屏。

- **不是一屏五变体**：成功侧与失败侧的差异不止两格，且其中两处是互相否定的承重纪律（失败侧「账号级收获零呈现」vs 元婴变体必须有统计区）；剩余重试行在成功侧没有可显示的事实；演出口径相反。**不是三屏**：元婴就是 ch3 的 `CompleteChapter()`，独有内容恰好可表达为变体表里的两格开关。
- **形态**：一屏全屏 · 不进屏幕栈 · 无返回；结果三行与失败侧摘要同构；解锁行 ch3 不出现；商业化 / 残卷 / 成就 / 图鉴四项零呈现；常驻同步指示可见；唯一主按钮「返回主菜单」（**不放「继续下一篇章」**——主菜单是唯一开局入口，三道闸全挂在「开始新轮回」上）；**允许一次入场演出**（≈1.2s + 一次短音效 + 全屏任意触点跳过 + 无震动，逐条复用揭示转场语汇）；零存档写入。
- **数据源** = `CompleteChapter` 内组装的只读摘要 `ChapterEndSummary`，时点两条硬要求：在境界寿元增量施加之后、在 `TeardownCycle()` 与任何角色数据处置之前。**零新增存档字段 / 存档点 / schema bump，后端零配合。**
- **文案**：`CYCLE_` 分区扩容为「轮回收尾族」，**不新开 `CHAPTER_` 分区**；三条定性文案是内容层条目，写作口径归 `systems/services/plot-manager.md`，**不做多版随机**。
- **「通关」口径分离（用户裁定）**：ch1 / ch2 变体一律用「突破」，「通关」二字只留给 ch3 变体与统计区。

（归档去向：`ux/screen-flow.md`、`ux/error-and-blocking-ux.md`、`systems/services/life-cycle-service.md`、`systems/services/plot-manager.md`。）

**元婴界面（通关证书）的具体形态（原 `ux/screen-flow.md#待决问题`）** → **即 `ChapterEndScreen` 的 ch3 变体**，不另立一屏。

- **展示深度：只用已定字段（用户裁定，原选项 A）** —— 两行账号级统计（`FinaleWinOrdinal` + `TotalCyclesCompleted`，措辞不得暗示二者应当一致）+ 与 ch1 / ch2 同一套结果三行。**连带闭合**：零新增字段、零 schema bump 成立 ⇒ 不触发 `systems/services/profile-schema-versions.md` 新增版本行；`PlayerStatistics` 首批清单不成为硬前置。
- **何时弹出**：`CompleteChapter()` 提交完成之后（ch3 那一笔即 `TotalCyclesCompleted +1` 的那一笔）。
- **是否可回看：不做独立回看（用户裁定，原选项 A）** —— 两个账号级数字在玩家档案屏常驻可读即为回看通道；零新增账号级字段、零新增屏、零 `user://` 文件。
- **是否分享：否** —— 站外分享要一套截图渲染 + 平台分享 SDK，并牵出渠道差异吸收问题。

**否决记录：** 一屏五 / 六变体 · 三屏 · 借 `BlockingNoticeScreen` 的变体表 · 本屏放「继续下一篇章」· 本屏呈现本轮回的账号级收获 · 站外分享 / 出图 · 新开 `CHAPTER_` 分区 · 突破文案做多版随机池 · 本屏呈现经验条 / 寿元曲线 / 逐项奖励回顾 · 元婴变体展示「本次轮回用时」（库内无耗时字段，须新增字段 + schema bump）。

## 仍开放

三条定性文案的正文属内容条目层，待 `/author-content` 落条目；入场演出的 ≈1.2s 与「一次短音效」是待实测初值。
