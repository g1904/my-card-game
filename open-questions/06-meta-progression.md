# ⑥ 元进程的失败侧与中长期规划感 · 图鉴族与商业化

> 本分片属 `../open-questions.md` 的当前焦点区。
>
> **范围：** 元进程的失败侧与中长期规划感、角色强度与辨识度压力线，外加**图鉴族与商业化**的待答项（`GrantPoolMargin` / `K` 的取值与其余两格取池余量是同一条问题，条目在 `01-combat.md`；`LocationCodex` 的词条深度在 `02-event-options.md`；角色商业化轨道的待答项在本片）。

> 已答结并移出（09-06）：**失败螺旋的容错量验收** —— N = 2 三章统一（软 / 硬两种结转口径同得 2）；「典型失败」五格口径锁死；两层验收断言（A3 当前偏紧 1.09/1.10/1.12 如实入账归实测校准）；派生锚「一次典型失败 ≈ 本章预算 5%」标为待实测格的派生量。权威在 `systems/balance.md`「失败容错量 N 的反推台账」，见 `../answer-logs/log-failure-spiral-tolerance.md`。

> 已答结并移出（09-06）：**「失去能力」四支的频次预算配平** —— 上层口径改「持久三支合计 ≈1.0 次 / 完整轮回」的绝对次数表述（百分比降为换算副本）；`IgnoresProtection` 移出上层分子、自持战斗分母口径（5% → 3%，≈1.11 次 / 轮回）；神通 ≈0.5 · 法则置换 ≈0.3 · 法则禁用 ≈0.2，各支均不收窄；两文档编排规则矛盾裁给 `systems/balance.md`（无轮回内上限、`CycleState` 零状态位）。权威在 `systems/player-profile/player-power/_index.md` 四支目标频次表与 `systems/balance.md`，见 `../answer-logs/log-ability-loss-frequency-budget.md`。

> 已答结并移出（09-06）：**中长期规划感的空间那一角（「还有几步到 Finale」）** —— **不补，三章一律不显示任何「距 Finale / 距圆满」读数**，接受「知道自己在长多快、不知道还剩多远」；篇章进度条与「还需约 M 个事件」两条替代方案的否决理由已写进 `systems/game-progression.md` 正文。同批把 Finale 触发条件 `level == 该境界末级`（全局序 13 / 17 / 21）钉进进程侧。见 `../answer-logs/log-finale-distance-foresight.md`。

> 已答结并移出（09-06）：**主动弃置的发起入口** —— 入口唯一落在主菜单「切换篇章」面上、该篇章那一行 `ongoing` 角色旁的次级动作，轮回内不设第二入口；只对 `ongoing` 开放（不新增 `completed → defeated`，被接受的代价 = 已通关角色档无清理通道）；就地二段确认、无冷静期、无撤销通道，`RetriesLeft == 0` 走第三条键改说「该篇章将不再可挑战」；`DefeatCharacter` 扩为 `(reason, characterId)`；中文 UI 措辞用「放弃」。权威在 `ux/screen-flow.md` 与 `systems/services/life-cycle-service.md`，见 `../answer-logs/log-character-discard-entry.md`。

> 已答结并移出（09-06）：**`completed` 是否清理角色数据** —— 「清理」拆为三层（运行时拆解 / 运行态字段清空 / 实体状态处置），前两层两条出口一视同仁、第三层只在 `defeated` 上做；存档表达取单记录 + `chapterStartSnapshot`，`defeated` 留墓碑（snapshot 只回收 ch1 墓碑），ch3 通关档永久保留完整档；`pastEvent` / `pastItemUse` 跨篇章只追加、重试也不回滚。权威在 `systems/services/life-cycle-service.md`「轮回出口的三层处置」，见 `../answer-logs/log-completed-data-retention.md`。

> 已答结并移出（09-05）：**篇章通关（`completed`）那一刻的呈现**与**元婴界面（通关证书）的具体形态** —— 新增 `ChapterEndScreen` = 一屏三变体（变体轴 `chapter`，ch3 变体即元婴通关证书，只用已定字段、不做站外分享与独立回看），与 `CycleEndScreen` 合成轮回收尾族两屏；权威在 `ux/screen-flow.md`，见 `../answer-logs/log-run-end-and-chapter-completion-screens.md`。

> 已答结并移出（08-30）：**`experiencePoint` 的阈值曲线与产出分布** —— 阈值公式与逐章合计、`ExperienceGrade` 枚举 × 平衡表映射、带经验产出点约占事件总数 ≈55%、失败走 `FailureRatio`（默认 50）向下取整下限 1 均已定案，权威在 `systems/balance.md` 与 `systems/game-progression.md`；见 `../answer-logs/log-0830.md`。其验收侧已于 09-06 答结（N = 2 三章统一），见 `../answer-logs/log-failure-spiral-tolerance.md`。

> 已答结并移出（08-16）：**`EventOutcome` 与 `CombatReward` 是否合并** —— **不合并**；判据钉为「谁组装出这条 element」，并在 `eventEnd` 加一条单向组装校验，见 `../answer-logs/log-event-outcome-vs-combat-reward.md`。

> 已答结并移出（08-16）：**道统残卷的可验证性** —— 隐含性与分档复杂度**均为设计初衷，不简化**（它是分发账户级加强的核心算法，不打算被玩家学到），见 `../answer-logs/log-0815c.md`。

> 已答结并移出：`FinaleWinOrdinal` 与账号级统计计数的边界（两层通则 + 合并判据 + `Ordinal` 命名硬约定 + 统计侧「通关」= 整轮回，见 `../answer-logs/log-finale-win-ordinal-vs-statistics.md`）· Finale「失败但存活」分支的叙事补白（归 plot-manager 的叙事层，两版文案 · 等概率随机 · 属内容层，见 `../answer-logs/log-0810b.md` 与 `log-0810b_2.md`）· 置换所得条目的 `SourceCode`（**继承被换出条目的来源**，关死「用置换刷回高掉率」的通道）· **`Source` 三值封闭清单与轮回级两类的取值冲突**（**推翻「清单是封闭的」**，扩为按 `(Kind, Scope)` 分域的七值开放清单 + 合法子集校验表；残卷 `x` 口径不变，见 `../answer-logs/log-grant-source-per-kind-scope.md`）。

- **全池指定下角色强度差是否仍塌缩为单一最优（09-10 收窄：验收目标与处置基准已定，余实测半）。** 灵根把差异推向「能修哪一路功法」，但仍可能存在一个综合最优的属性池；ch1 无限重试放大该效应。「每个角色都能以合理体验通关」已定为验收目标（含付费角色），塌缩即触发内容向修正——**是否真塌缩待实测**。→ `systems/character-profile/_index.md`。
- **双灵根批两类专属内容的对铺量（09-10 收窄：区分模式已定为双机制组合，余数值半）。** `RequiredAffinities` 复合功法（宽池角色的独占亮点）与 `MaxCharacterAffinityCount = 1` 单灵根专属功法（窄池角色的补偿）如何对铺，具体量待实测且依赖道念量纲。首批全为单灵根故不发生；引入双灵根批时与那批角色同批答。→ `systems/character-profile/deck/_index.md`、`systems/balance.md`。
- **通用 / 专属分层梯度的逐档比例数值（09-10 收窄：口径已定为按稀有度分层的梯度、无硬限制，余取值半）。** 低档通用比例高且每种灵根都有低稀有度功法、高档通用限无条件直给型、build-around 一律带属性——逐档比例取值随 ch1 starter deck 的打磨定，`/audit-content` 按稀有度档统计作核对面。→ `systems/character-profile/deck/_index.md`。
- **付费角色系列的解锁载体与购买流程形态（09-10 新增）。** 轨道决策已定（系列化 · 单向棘轮 · 整系列礼包定价 · 严格横向）；`CharacterData` 轨道标记、`PlayerProfile` 具名集合、取池过滤、`schemaVersion` bump 与后端承接（SKU / 验票写入 / 封闭表加行）的具体形态归 `/provide-solution-draft` 推演。→ `systems/monetization.md`、`systems/character-profile/_index.md`。
- **双灵根批与付费系列的推出时点与主题包装（09-10 新增）。** 未讨论。→ `systems/monetization.md`。
- **付费角色与专属剧情的关系（09-10 新增）。** 付费角色是否附带专属剧情、剧情是否构成付费面的一部分；留给叙事落地专场或商业化后续。→ `systems/monetization.md`、`systems/services/plot-manager.md`。