# ADR-0148 — 轮回结束屏 `CycleEndScreen` = 一屏三变体

- **状态：** Accepted
- **日期：** 2026-09-02
- **来源：** handoffs/2026-09-02-cycle-end-screen.md

## 背景

`DefeatReason` 是三值封闭枚举 `{ Discarded, LifeSpanExhausted, FinaleFailed }`；状态机、清理、统计计数、重试计数全部齐备，唯独**没有任何一屏**承载角色终结——`ux/screen-flow.md` 甚至已在引用一个尚不存在的「终态死亡屏」。同时，「渡劫身死」定性文案原挂在 `ResolveOutcome` → `eventEnd` 上，而三因里有两因根本不经事件收口。

## 决策

立 **`CycleEndScreen`，一屏三变体**（变体轴 `DefeatReason`），**只承载 `defeated` 三因**；篇章通关 `completed` 不走本屏。它**借 `BlockingNoticeScreen` 的形态（一屏 + 变体表），不借它的屏**。

- **载体** = 一屏全屏（安全区内），不进屏幕栈、无返回路径、非弹层。
- **时点** = `DefeatCharacter(reason)` 提交完成之后；点主按钮 → `TeardownCycle` → 成就结算 → 回主菜单，这一段既定顺序一格不动。**不新增存档点**。
- **数据源** = `DefeatCharacter` 内、清理之前组装的一份**只读值摘要**（值类型 + 内容 `Id` + 文案条目 `Id`，不持 `CharacterProfile` 引用）。
- **出路只有「返回主菜单」**；残卷零呈现、商业化零入口零文字、无自动跳转 / 倒计时 / 二次确认；常驻同步指示照常可见。
- **定性文案改按 `DefeatReason` 查表**、由本屏呈现（文案载体仍是内容层条目，只换定位键）；`Discarded` 变体不配文案。

逐格变体表与呈现清单 → `ux/screen-flow.md`「轮回结束屏」、`systems/services/life-cycle-service.md`。

## 理由

- **一屏三变体而不是三屏**：三因走完之后结构完全相同（`defeated` → 清理 → 重试计数已减 → 回主菜单），差别只在「这一次为什么结束」，那是一句话的差别、不是一条流程的差别；三份等价布局各自维护、各自适配竖屏与安全区必然漂移成三种不一致的观感。
- **不复用 `BlockingNoticeScreen`**：那张变体表只收「由已知后端 `code` 触发、且玩家无自愈路径」的终局态，二者缺一即不进；轮回结束不由任何 `code` 触发，且它是一次**正常的游戏结果**——共用会让「角色死了」和「存档读不出来」观感同级。
- **不放「再试一次」**：① 主菜单是既定唯一开局入口且挂着三道闸（待兑现购买置灰 / 每篇章至多一个 `ongoing` / 篇章解锁门禁），第二入口要么复制三道闸（必然漂移）要么绕过它们；② ch1（重走角色选择、新建 `CharacterProfile`）与 ch2 / ch3（`RetryChapter`）路径形态不同，一个按钮要在最低情绪点上分叉出两条流程。
- **文案改定位键**：`ResolveOutcome` 覆盖不到三因中的两因——`Discarded` 根本不经事件收口，`LifeSpanExhausted` 可能在终态判定 ① 命中、那一路没有 `eventEnd`。挂在它上面，三因里只有一因有文案。
- **剩余重试不是推销面**：既定纪律禁的是「提示购买」，不禁「告知剩余次数」；本屏无任何付费入口。上限读两行表之一，本屏只读差值、不硬编码常量（`decisions/ADR-0117-chapter-retry-limit-carrier.md`）。
- 同步指示不隐藏：这一刻恰好发生一次 `Immediate` flush（`decisions/ADR-0104-immediate-flush-never-blocks.md`），隐藏指示就是把「失联」伪装成「已保存」。

## 备选方案

- **三因各立一屏** — 否决：三份等价布局必然漂移成三种观感。
- **复用 `BlockingNoticeScreen` 的变体表** — 否决：不由后端 `code` 触发、且是一次正常游戏结果，进不了那张表。
- **本屏放「再试一次」第二入口** — 否决：复制或绕过主菜单三道闸；且 ch1 与 ch2/ch3 重试路径形态不同。
- **回顾加寿元曲线 / 呈现本轮回的账号级收获（图鉴 / 成就）** — 否决：第一版应把「玩家现在要做什么决定」说清楚；且呈现账号级收获要把成就结算提到 `TeardownCycle` 之前，与既定编排相抵，还会与紧邻的「残卷完全静默」在同屏内并存两种口径。

## 后果

- **零新增存档点、零写入**（本屏是已提交事务之后的一次纯呈现）；结果三行取既有数据、零新增字段。
- 新增 `CYCLE_` 分区 / `cycle.csv`；不复用 `EVENT_` / `MENU_`、不占 `ERR_`（无后端 `code`，见 `decisions/ADR-0053-error-copy-client-owned.md`）。定性文案不进 `cycle.csv`——属内容层。
- 相关文档因此这么写：`ux/screen-flow.md`（变体表与收敛门槛）· `ux/error-and-blocking-ux.md`（分区表 + 与 `BlockingNoticeScreen` 的边界）· `systems/services/life-cycle-service.md`（`DefeatCharacter` 组装只读结束摘要）· `systems/services/plot-manager.md`（死亡文案改按 `DefeatReason` 定位）。
- **跨档叙事的 `BandNarrativeIds` 通道原样保留**，`Practice` 档战斗失败的定性文案照旧走 `ResolveOutcome`。
- 待定项：主动弃置的发起入口全库无明文（不阻塞本屏——不论从哪里发起都经 `DefeatCharacter(Discarded)` 落到同一变体）。
