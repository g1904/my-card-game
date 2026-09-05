# 死亡 / 轮回结束屏

- id: 2026-09-02-cycle-end-screen
- date: 2026-09-02
- topic: ux/screen-flow.md · ux/error-and-blocking-ux.md · systems/services/life-cycle-service.md · systems/services/plot-manager.md
- status: distilled
- distilled-to: ux/screen-flow.md, ux/error-and-blocking-ux.md, systems/services/life-cycle-service.md, systems/services/plot-manager.md

## Intent（distilled）

`DefeatReason` 是三值封闭枚举 `{ Discarded, LifeSpanExhausted, FinaleFailed }`。状态机、清理、统计计数、重试计数全部齐备，唯独**没有任何一屏**承载角色终结——`ux/screen-flow.md` 甚至已在引用一个尚不存在的「终态死亡屏」。本次定下这一屏。

### 一屏三变体，不是三屏

三因走完之后的结构完全相同（角色 `defeated` → 数据清理 → 重试计数已减 → 回主菜单），差别只在**这一次为什么结束**，那是一句话的差别、不是一条流程的差别。三份等价布局要各自维护、各自适配竖屏与安全区，而它们会长得一模一样；差异一旦只靠版式表达，必然漂移成三种不一致的观感。

屏名 `CycleEndScreen`，**只承载 `defeated` 三因**；篇章通关 `completed` 与整轮回通关（元婴界面）不走本屏。

**借 `BlockingNoticeScreen` 的形态（一屏 + 变体表），不借它的屏。** 阻塞屏那张变体表只收「由已知后端 `code` 触发、且玩家没有任何自愈路径」的终局态，二者缺一即不进；轮回结束不由任何 `code` 触发，且它是一次**正常的游戏结果**——共用会让「角色死了」和「存档读不出来」在观感上同级。

### 位置、时点与数据源

- 载体 = **一屏全屏**（安全区内），不进屏幕栈、无返回路径、非弹层。弹层意味着它浮在一个仍然有效的轮回界面之上，而这个轮回已经不存在了。
- 时点 = `DefeatCharacter(reason)` 提交完成（含既定 `Immediate` flush 与 `TotalCyclesDefeated +1`）之后；玩家点主按钮 → `TeardownCycle` → 成就结算 → 回主菜单，**这一段既定顺序一格不动**。
- 数据源 = **`DefeatCharacter` 内、清理之前组装的一份只读值摘要**（值类型 + 内容 `Id` + 文案条目 `Id`，不持 `CharacterProfile` 引用）。清理与 `TeardownCycle` 的时点因此不被呈现层牵制。
- **不新增存档点**——本屏是已提交事务之后的一次纯呈现，零写入。

### 承载什么

定性文案 + 结果三行 + 剩余重试 + 一个主按钮，竖屏单列自上而下。

- **结果三行取既有数据、零新增字段**：境界 + 篇章 · `pastEvent.Count` · `Status.lifeSpan`（恒精确，`LifeSpanExhausted` 变体上恒为 `0`）。
- **剩余重试照实展示 `RetriesLeft`**；ch1 上限无限 → 走「无限」键，不显示一个假的大数。上限读的是两行表之一（基线 ∞/3/1、持礼包 ∞/9/3），本屏只读差值、不硬编码常量。**它不是推销面**：既定纪律禁的是「提示购买」，不禁「告知剩余次数」；本屏无任何付费入口、无任何指向礼包的文字（结构上也不可行——购买只能在主菜单发起）。
- **残卷零呈现**：不给文案、不给暗示、不给进度条、不给百分比。`FinaleFailed` 变体尤其吃紧——它恰是残卷累积发生的那一刻。
- **出路只有「返回主菜单」一个**，不放「再试一次」。两条理由：① 主菜单是既定唯一开局入口且挂着三道闸（待兑现购买置灰 / 每篇章至多一个 `ongoing` / 篇章解锁门禁），第二入口要么复制三道闸（必然漂移）要么绕过它们；② ch1（重走角色选择、新建 `CharacterProfile`）与 ch2 / ch3（`RetryChapter`）的重试路径形态不同，一个按钮要在最低情绪点上分叉出两条流程。
- **无自动跳转、无倒计时、无二次确认**；常驻同步指示照常可见——这一刻恰好发生一次 `Immediate` flush，隐藏指示就是把「失联」伪装成「已保存」。
- 音效 / 演出：一次短音效、无震动、无入场动画强调（时长与音效为待实测初值）。

### 定性文案改按 `DefeatReason` 定位

文案载体不变（内容层定性文案条目，一条文案、不做随机二选一、不按篇章 / 隐藏属性分化），**改的只是定位键**：从「随 `ResolveOutcome` 传到结算面板」改为「按 `DefeatReason` 查表，由轮回结束屏呈现」。理由：`ResolveOutcome` 覆盖不到三因中的两因——`Discarded` 根本不经事件收口；`LifeSpanExhausted` 可能在终态判定 ①（支付 `selectCost` 后短路）命中，那一路事件未结算、没有 `eventEnd`、没有结算面板。挂在它上面，三因里只有一因有文案。

**只有死亡文案换定位键。** 跨档叙事的 `ResolveOutcome.BandNarrativeIds` 通道原样保留；`Practice` 档战斗失败的定性文案照旧走 `ResolveOutcome` → `eventEnd`，不受影响。

`Discarded` 变体不配定性文案（内容条目留空）——主动弃置是玩家自己的决定，写挽留 / 惋惜文案像在评价玩家的选择。这属内容编排取向，可随时补上、不改结构。

### 文案分区

新增 `CYCLE_` 分区 / `cycle.csv`：三个标题、结果行标签、剩余重试行（含「无限」）、主按钮。不复用 `EVENT_`（事件选项框架）、不复用 `MENU_`（本屏不属主菜单）、不占 `ERR_`（无后端 `code`）。定性文案不进 `cycle.csv`——四问皆是，属内容层。

## Clarifications

- **本轮回回顾的深度 → 极简三行。** 寿元曲线不进第一版（数据与算法均已就位，随时可加）。理由：本屏第一版应把「玩家现在要做什么决定」说清楚，把重实现放在全游戏情绪最低点收益最不确定。
- **是否呈现本轮回的账号级收获（图鉴 / 成就）→ 不呈现。** 阶段 5 的既定编排顺序（成就结算在 `TeardownCycle` 之后）一字不动；账号级收获在主菜单的图鉴 / 成就面照常可见。
- **「渡劫身死」文案的落点由 `ResolveOutcome` 改为按 `DefeatReason` 定位 → 松动，采纳。** 这推翻了 `plot-manager.md`「走同一条落点（`ResolveOutcome` → `eventEnd` 阶段）」那一句；结构增量仍为零。**跨档叙事的 `BandNarrativeIds` 通道原样保留**，只有死亡文案换定位键。
- **不复用 `BlockingNoticeScreen`**（标准默认）：轮回结束不由任何后端 `code` 触发，结构上就不进那张变体表。

## Open questions

- **主动弃置的发起入口全库无明文**：玩家从哪一屏、以什么形态弃置一个角色、是否二次确认。不阻塞本屏（不论从哪里发起都经 `DefeatCharacter(Discarded)` 落到同一变体）。
- **篇章通关 `completed` 那一刻的呈现**同样无明文，与本屏形态相邻。
- **元婴界面（通关证书）的具体形态**：若日后给它一份「修行历程摘要」，应与本屏的回顾深度一并考虑，避免两处各做一套历程展示。
