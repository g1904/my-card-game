# ADR-0161 — 失去能力的频次预算：承重口径取「每完整轮回期望次数」，百分比降为换算副本

- **状态：** Accepted
- **日期：** 2026-09-06
- **来源：** handoffs/2026-09-06-ability-loss-frequency-budget.md · answer-logs/log-ability-loss-frequency-budget.md

## 背景

「失去能力」有四条支路（神通失去 · 法则置换 · 法则禁用 · 战斗内 `IgnoresProtection`），此前它们的频次预算写成**百分比**，且四支共用一个上层合计口径。两个问题因此长期悬着：

- **百分比会被分母漂移静默重定价**——篇章时长与事件数一改，同一个百分比对应的实际次数就变了，而没有任何机制会报警；
- **`IgnoresProtection` 的分母根本不同**（战斗类遭遇 vs 全五类事件），把它计进上层合计即制造**双口径嵌套**：旧的 1% 总额下，单这一支就已超总额，其余三支份额为负。

## 决策

**承重表述取「每完整轮回的期望次数」，不取百分比。** 持久三支合计 **≈ 1 次 / 完整轮回**，且不限于战斗；百分比只作括号里的换算副本（≈0.88%，分母 ≈114）。

**`IgnoresProtection` 移出上层合计口径、自持战斗类遭遇的分母**——它不写 Profile，分母也不同，故单独持有本条口径。双口径嵌套就此解除。

**三条持久支按「持久度 × 是否经玩家同意」两条轴分配份额**，频次与「持久度 × 无同意」**反相关**（神通 > 法则置换 > 法则禁用，**法则禁用是唯一取低值的一格**）。

**频次的旋钮全落内容侧：零字段、零校验、零 `CycleState` 状态位**——旋钮是带 `AbilityChangeSlots` 的 `AdventureEventData` 条目数与各条目的 `SelectionWeight` 档。

逐支份额、分母口径与两条准入 → `systems/player-profile/player-power/_index.md`、`systems/balance.md`。

## 理由

- **绝对次数是唯一不被分母漂移静默重定价的口径**：验收动作本来就是「一个轮回里数到几次」，写成次数即所见即所测；篇章时长重标定（`ADR-0164`）当场证明了百分比口径的脆弱性。
- **解除嵌套是「改绝对次数」的必要配套**：两个分母不同的量放进同一个合计里，任何一支的调整都会污染另一支——这不是精度问题，是口径错误。
- **反相关的分配轴**：玩家同意过的失去（法则置换）比未经同意的（法则禁用）更可接受，故未经同意且持久的那一格必须最稀有；这与 `ADR-0048`「法则不会被强制剥夺、只有自愿置换能真正移除」同向。
- **不落代码**：加载期配额校验需要一个「本轮回已失去几次」的计数器与存档位，而该量的正确值本来就由内容池组成涌现——落代码是为一个内容侧事实造一份运行期账。

## 备选方案

- **保持旧 1% 总额、收窄三支持久支** — 否决：`IgnoresProtection` 一支 1.11 已超总额，其余三支份额为负；唯一收窄解是三条已完整设计的机制（`AbilityChangeSlots` 决策点 · 结算面板 · `GrantPoolManager.TryPickReplacement` · `disabledAbility` 三档）在一个轮回里一次都不出现。
- **合计取 ≈0.83**（法则禁用每 7 轮回一次） — 否决：几乎不可见，等于机制不存在。
- **合计取 ≈1.5** — 否决：与「跨篇章稀有事件」的既定定性拉扯。
- **`player-power` 侧那套写法**（每篇章至多 1 载体 / 轮回内至多一次 / `CycleState` 布尔位） — 否决：复述侧失真；矛盾裁给 `balance.md`，复述段改回链。

## 后果

- **`IgnoresProtection` 目标频次由 ≈5% 下调至 ≈3%**（分母口径与两条准入见 `systems/balance.md`），且**无轮回内次数上限**、`CycleState` 不设任何相关状态位——完全落内容编排层，兑现 `ADR-0106`。
- **`player-power/_index.md` 侧的复述段改为回链**，本机制的口径权威单点落在 `systems/balance.md`。
- **日后要加加载期配额校验，须先推翻本 ADR 的「零校验」那一格**——它不是省略，是决定。
- 受约束的文档：`systems/player-profile/player-power/_index.md` · `systems/balance.md` · `systems/character-profile/power/_index.md` · `systems/services/future-event-service.md` · `decisions/ADR-0106-ignores-protection-content-layer-only.md` · `decisions/ADR-0048-consented-power-loss-ladder.md`。
