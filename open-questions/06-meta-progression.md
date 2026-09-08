# ⑥ 元进程的失败侧与中长期规划感（08-01 新增焦点）

> 本分片属 `../open-questions.md` 的当前焦点区。

> 已答结并移出（09-06）：**失败螺旋的容错量验收** —— N = 2 三章统一（软 / 硬两种结转口径同得 2）；「典型失败」五格口径锁死；两层验收断言（A3 当前偏紧 1.09/1.10/1.12 如实入账归实测校准）；派生锚「一次典型失败 ≈ 本章预算 5%」标为待实测格的派生量。权威在 `systems/balance.md`「失败容错量 N 的反推台账」，见 `../answer-logs/log-failure-spiral-tolerance.md`。

> 已答结并移出（09-06）：**「失去能力」四支的频次预算配平** —— 上层口径改「持久三支合计 ≈1.0 次 / 完整轮回」的绝对次数表述（百分比降为换算副本）；`IgnoresProtection` 移出上层分子、自持战斗分母口径（5% → 3%，≈1.11 次 / 轮回）；神通 ≈0.5 · 法则置换 ≈0.3 · 法则禁用 ≈0.2，各支均不收窄；两文档编排规则矛盾裁给 `systems/balance.md`（无轮回内上限、`CycleState` 零状态位）。权威在 `systems/player-profile/player-power/_index.md` 四支目标频次表与 `systems/balance.md`，见 `../answer-logs/log-ability-loss-frequency-budget.md`。

> 已答结并移出（09-06）：**中长期规划感的空间那一角（「还有几步到 Finale」）** —— **不补，三章一律不显示任何「距 Finale / 距圆满」读数**，接受「知道自己在长多快、不知道还剩多远」；篇章进度条与「还需约 M 个事件」两条替代方案的否决理由已写进 `systems/game-progression.md` 正文。同批把 Finale 触发条件 `level == 该境界末级`（全局序 13 / 17 / 21）钉进进程侧。见 `../answer-logs/log-finale-distance-foresight.md`。

> 已答结并移出（09-06）：**主动弃置的发起入口** —— 入口唯一落在主菜单「切换篇章」面上、该篇章那一行 `ongoing` 角色旁的次级动作，轮回内不设第二入口；只对 `ongoing` 开放（不新增 `completed → defeated`，被接受的代价 = 已通关角色档无清理通道）；就地二段确认、无冷静期、无撤销通道，`RetriesLeft == 0` 走第三条键改说「该篇章将不再可挑战」；`DefeatCharacter` 扩为 `(reason, characterId)`；中文 UI 措辞用「放弃」。权威在 `ux/screen-flow.md` 与 `systems/services/life-cycle-service.md`，见 `../answer-logs/log-character-discard-entry.md`。

> 已答结并移出（09-06）：**`completed` 是否清理角色数据** —— 「清理」拆为三层（运行时拆解 / 运行态字段清空 / 实体状态处置），前两层两条出口一视同仁、第三层只在 `defeated` 上做；存档表达取单记录 + `chapterStartSnapshot`，`defeated` 留墓碑（snapshot 只回收 ch1 墓碑），ch3 通关档永久保留完整档；`pastEvent` / `pastItemUse` 跨篇章只追加、重试也不回滚。权威在 `systems/services/life-cycle-service.md`「轮回出口的三层处置」，见 `../answer-logs/log-completed-data-retention.md`。

> 已答结并移出（09-05）：**篇章通关（`completed`）那一刻的呈现**与**元婴界面（通关证书）的具体形态** —— 新增 `ChapterEndScreen` = 一屏三变体（变体轴 `chapter`，ch3 变体即元婴通关证书，只用已定字段、不做站外分享与独立回看），与 `CycleEndScreen` 合成轮回收尾族两屏；权威在 `ux/screen-flow.md`，见 `../answer-logs/log-run-end-and-chapter-completion-screens.md`。

> 已答结并移出（08-30）：**`experiencePoint` 的阈值曲线与产出分布** —— 阈值公式与逐章合计、`ExperienceGrade` 枚举 × 平衡表映射、带经验产出点约占事件总数 75%、失败走 `FailureRatio`（默认 50）向下取整下限 1 均已定案，权威在 `systems/balance.md` 与 `systems/game-progression.md`；见 `../answer-logs/log-0830.md`。其验收侧已于 09-06 答结（N = 2 三章统一），见 `../answer-logs/log-failure-spiral-tolerance.md`。

> 已答结并移出（08-16）：**`EventOutcome` 与 `CombatReward` 是否合并** —— **不合并**；判据钉为「谁组装出这条 element」，并在 `eventEnd` 加一条单向组装校验，见 `../answer-logs/log-event-outcome-vs-combat-reward.md`。

> 已答结并移出（08-16）：**道统残卷的可验证性** —— 隐含性与分档复杂度**均为设计初衷，不简化**（它是分发账户级加强的核心算法，不打算被玩家学到），见 `../answer-logs/log-0815c.md`。

> 已答结并移出：`FinaleWinOrdinal` 与账号级统计计数的边界（两层通则 + 合并判据 + `Ordinal` 命名硬约定 + 统计侧「通关」= 整轮回，见 `../answer-logs/log-finale-win-ordinal-vs-statistics.md`）· Finale「失败但存活」分支的叙事补白（归 plot-manager 的叙事层，两版文案 · 等概率随机 · 属内容层，见 `../answer-logs/log-0810b.md` 与 `log-0810b_2.md`）· 置换所得条目的 `SourceCode`（**继承被换出条目的来源**，关死「用置换刷回高掉率」的通道）· **`Source` 三值封闭清单与轮回级两类的取值冲突**（**推翻「清单是封闭的」**，扩为按 `(Kind, Scope)` 分域的七值开放清单 + 合法子集校验表；残卷 `x` 口径不变，见 `../answer-logs/log-grant-source-per-kind-scope.md`）。

- **胜侧 `rewardPerMomentum[experiencePoint]` 是否计入经验供给账（09-06 新增 · 由容错量标定牵出的既有账目缺口）。** `systems/balance.md` 的胜侧单价表给出 ch1 `experiencePoint` 单价 1 / 点，而经验供需对账（供给 `G_c` = 92 / 290 / 460）只算了 `ExperienceGrade` 档位产出，未计道念差 × 单价的线性加成——新旧两版对账口径一致，均偏保守。计入则供给上移、失败容错量的经验侧上界随之上移（N = 2 的结论只会更宽松，不受威胁）；它同时是「失败少拿的第三笔代价」，当前的 N 反推台账未计入。答定后须同步重算 `balance.md` 的供需比与容错台账两处。→ `systems/balance.md`。
- **全池指定下角色强度差是否仍塌缩为单一最优（08-30 新增）。** 灵根把差异推向「能修哪一路功法」，但仍可能存在一个综合最优的属性池；ch1 无限重试放大该效应。待实测。→ `systems/character-profile/_index.md`。
- **多灵根角色的强度对齐换算尚无解法（08-30 新增）。** 对冲手段（`MaxCharacterAffinityCount == 1` 的单灵根专属功法）结构已就位，但「多宽的可修池 = 多强的专属功法」这条换算没有答案，且依赖尚未定的道念量纲。首批全为单灵根，故在首批不发生；引入第一个多灵根角色时必须先答。→ `systems/character-profile/deck/_index.md`、`systems/balance.md`。
- **通用功法（无属性要求）的占比口径（08-30 定案时产生 · 本次归集入清单）。** 空 `RequiredAffinities` = 通用功法；占比过高会把灵根辨识度稀释回「五个角色抽到的东西差不多」，与上两条（全池指定的强度塌缩 · 多灵根换算）是同一条辨识度压力线的第三面。编排取向已定（底盘共享、亮点分化），但这是**内容编排口径而非字段约束**，取值随 ch1 starter deck 的打磨定。此前只登记在主题文档与索引的就绪度小节，未进本清单。→ `systems/character-profile/deck/_index.md`。