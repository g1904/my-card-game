# ⑥ 元进程的失败侧与中长期规划感（08-01 新增焦点）

> 本分片属 `../open-questions.md` 的当前焦点区。

> 已答结并移出（08-30）：**`experiencePoint` 的阈值曲线与产出分布** —— 阈值公式与逐章合计、`ExperienceGrade` 枚举 × 平衡表映射、带经验产出点约占事件总数 75%、失败走 `FailureRatio`（默认 50）向下取整下限 1 均已定案，权威在 `systems/balance.md` 与 `systems/game-progression.md`；见 `../answer-logs/log-0830.md`。**它的验收侧「N 次典型失败仍能升满」仍待答**，留在本分片末条。

> 已答结并移出（08-16）：**`EventOutcome` 与 `CombatReward` 是否合并** —— **不合并**；判据钉为「谁组装出这条 element」，并在 `eventEnd` 加一条单向组装校验，见 `../answer-logs/log-event-outcome-vs-combat-reward.md`。

> 已答结并移出（08-16）：**道统残卷的可验证性** —— 隐含性与分档复杂度**均为设计初衷，不简化**（它是分发账户级加强的核心算法，不打算被玩家学到），见 `../answer-logs/log-0815c.md`。

> 已答结并移出：`FinaleWinOrdinal` 与账号级统计计数的边界（两层通则 + 合并判据 + `Ordinal` 命名硬约定 + 统计侧「通关」= 整轮回，见 `../answer-logs/log-finale-win-ordinal-vs-statistics.md`）· Finale「失败但存活」分支的叙事补白（归 plot-manager 的叙事层，两版文案 · 等概率随机 · 属内容层，见 `../answer-logs/log-0810b.md` 与 `log-0810b_2.md`）· 置换所得条目的 `SourceCode`（**继承被换出条目的来源**，关死「用置换刷回高掉率」的通道）· **`Source` 三值封闭清单与轮回级两类的取值冲突**（**推翻「清单是封闭的」**，扩为按 `(Kind, Scope)` 分域的七值开放清单 + 合法子集校验表；残卷 `x` 口径不变，见 `../answer-logs/log-grant-source-per-kind-scope.md`）。

- **死亡 / 轮回结束屏尚无设计（08-22 新增）。** 全库对角色终结的呈现只有一句「寿元归 0 即角色终结」。而终结原因现为三值（弃置 / 寿元耗尽 / **渡劫失败**），三条路径的观感与叙事分量差别很大，应否区分呈现未定。「渡劫身死」的**文案载体已定**（挂 `ResolveOutcome` 的内容层定性文案），**呈现它的那一屏未定**。→ `ux/screen-flow.md`、`systems/services/plot-manager.md`。
- **中长期规划感的来源（08-06c 大幅收窄 · 08-30 再收窄，只剩「还有几步到 Finale」那一角）。** **地理方位感已落地**：`LocationCodex` **记连边**（08-06c 定案），玩家因此能跨轮回重建整张 `locationMap` 并在 Travel 闸门处**提前两步规划路线**。**进度感的时间那一半也已承接**：经验条常驻于 EventOption 选择界面的角色状态条（`当前 / 本级阈值`），它在 ch2 / ch3 是唯一的连续进度感来源（`ux/screen-flow.md` 明写这是本条的一个答复）。**仍待定的只剩空间那一角**：没有任何通道回答「还有几步到 Finale」，是否需要轮回内的补充（篇章进度条？前瞻提示？），还是接受「知道自己在长多快、不知道还剩多远」。→ `systems/game-progression.md`、`ux/screen-flow.md`。
- **「失去法则」三支的频次预算需重新配平（08-16 新增 · 由 `IgnoresProtection` 上调牵出）。** `IgnoresProtection` 的目标频次由 1% 上调至 ≈5%（战斗类遭遇为分母）后，**单这一支就已接近「三类合计 ≈ 全部事件的 1%」的全部预算**（≈1~2 次 / 轮回 vs 上层预算约 1 次）。两个口径都是内容编排侧目标值、都不可机械校验，故未预先拍板：**上层合计口径随之上调，还是置换型 / 禁用型两支相应收窄**——归 ch1 内容编排一并定。→ `systems/player-profile/player-power/_index.md`、`systems/services/future-event-service.md`。
- **全池指定下角色强度差是否仍塌缩为单一最优（08-30 新增）。** 灵根把差异推向「能修哪一路功法」，但仍可能存在一个综合最优的属性池；ch1 无限重试放大该效应。待实测。→ `systems/character-profile/_index.md`。
- **多灵根角色的强度对齐换算尚无解法（08-30 新增）。** 对冲手段（`MaxCharacterAffinityCount == 1` 的单灵根专属功法）结构已就位，但「多宽的可修池 = 多强的专属功法」这条换算没有答案，且依赖尚未定的道念量纲。首批全为单灵根，故在首批不发生；引入第一个多灵根角色时必须先答。→ `systems/character-profile/deck/_index.md`、`systems/balance.md`。
- **两门绑定功法的初始层数（08-30 新增）。** 角色开局时那两门功法各处于第几层（是否恒为 1、是否可逐条编排）全库无明文；它是 `content/character/` 条目写到 ready 的前置。→ `systems/character-profile/_index.md`、`systems/character-profile/deck/_index.md`。
- **失败螺旋的容错量验收（08-30 新增）。** 战斗失败既直接扣寿元、又经 `FailureRatio` 折半经验 ⇒ 输一场同时减少本章可做的事件数与每个事件的经验产出，两者叠成一条正反馈曲线。螺旋本身是被接受的设计取向，待答的是它的标定：`systems/game-progression.md` 的验收项现写作「即使发生 N 次典型失败仍能在预算内升满」——N 的取值与「典型失败」的口径未定。→ `systems/game-progression.md`、`systems/balance.md`。
