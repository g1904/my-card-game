# ⑥ 元进程的失败侧与中长期规划感（08-01 新增焦点）

> 本分片属 `../open-questions.md` 的当前焦点区。

> 已答结并移出（08-16）：**道统残卷的可验证性** —— 隐含性与分档复杂度**均为设计初衷，不简化**（它是分发账户级加强的核心算法，不打算被玩家学到），见 `../answer-logs/log-0815c.md`。

> 已答结并移出：`FinaleWinOrdinal` 与账号级统计计数的边界（两层通则 + 合并判据 + `Ordinal` 命名硬约定 + 统计侧「通关」= 整轮回，见 `../answer-logs/log-finale-win-ordinal-vs-statistics.md`）· Finale「失败但存活」分支的叙事补白（归 plot-manager 的叙事层，两版文案 · 等概率随机 · 属内容层，见 `../answer-logs/log-0810b.md` 与 `log-0810b_2.md`）· 置换所得条目的 `SourceCode`（**继承被换出条目的来源**，关死「用置换刷回高掉率」的通道）· **`Source` 三值封闭清单与轮回级两类的取值冲突**（**推翻「清单是封闭的」**，扩为按 `(Kind, Scope)` 分域的七值开放清单 + 合法子集校验表；残卷 `x` 口径不变，见 `../answer-logs/log-grant-source-per-kind-scope.md`）。

- **中长期规划感的来源（08-06c 大幅收窄，只剩进度感那一半）。** **地理方位感已落地**：`LocationCodex` **记连边**（08-06c 定案），玩家因此能跨轮回重建整张 `locationMap` 并在 Travel 闸门处**提前两步规划路线**——知识增长直接转化为轮回内的决策质量。**仍待定的是进度感**：图鉴不回答「还有几步到 Finale」，是否需要轮回内的补充（篇章进度条？前瞻提示？），还是接受「只有方位感、没有进度感」。→ `systems/game-progression.md`、`systems/player-profile/codex/`、`ux/`。
- **「失去法则」三支的频次预算需重新配平（08-16 新增 · 由 `IgnoresProtection` 上调牵出）。** `IgnoresProtection` 的目标频次由 1% 上调至 ≈5%（战斗类遭遇为分母）后，**单这一支就已接近「三类合计 ≈ 全部事件的 1%」的全部预算**（≈1~2 次 / 轮回 vs 上层预算约 1 次）。两个口径都是内容编排侧目标值、都不可机械校验，故未预先拍板：**上层合计口径随之上调，还是置换型 / 禁用型两支相应收窄**——归 ch1 内容编排一并定。→ `systems/player-profile/player-power/_index.md`、`systems/services/future-event-service.md`。
- **`EventOutcome` 与 `CombatReward` 是否终将合并（08-12b 新增）。** `Source` 扩清单时把「非战斗事件 outcome 授予」与「战斗遭遇 `Spoils` 授予」定为**两个成员**，前提是二者确为两条组装路径（当前文档支持这一判断）。若最终合流为同一条链路，两个成员应合并——**合并时 `CombatReward = 5` 的 code 作废并永不复用**，不得改判为别的语义。→ `systems/common-properties.md`、`systems/services/combat-service.md`、`systems/services/future-event-service.md`。
- **角色模板池的形态（08-12f 新增 · 承重）。** 角色已升格为有身份的模板 `CharacterData`（自带一个神通 + 两门绑定功法，每局一致）；仍待定：**池中有几个角色**、**是否账号级逐步解锁**、**能否重抽或指定**。这直接改写元进程压力模型——既定的「炼气可无限重试」在「重开就换一个角色」下与在「可指定角色」下是两种完全不同的手感。→ `systems/character-profile/_index.md`、`systems/player-profile/`。
