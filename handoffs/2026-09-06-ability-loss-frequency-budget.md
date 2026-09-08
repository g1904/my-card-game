# 「失去能力」四支的频次预算配平

- id: 2026-09-06-ability-loss-frequency-budget
- date: 2026-09-06
- topic: systems/player-profile/player-power | systems/character-profile/power | systems/balance | systems/services/future-event-service
- status: distilled
- distilled-to: systems/player-profile/player-power/_index.md, systems/character-profile/power/_index.md, systems/balance.md, systems/services/future-event-service.md

## Intent（distilled）

一句话：「失去能力」四支（法则置换 · 法则禁用 · 战斗内 `IgnoresProtection` · 神通置换/禁用）的频次预算按新分母（一轮回 114 个事件、约 37 场战斗类遭遇）重新配平——**上层口径改为「持久三支合计 ≈ 1 次 / 完整轮回」的绝对次数表述，`IgnoresProtection` 移出上层分子、自持战斗分母口径（5% 下调至 3%）**，各支均不收窄。

### 1. 上层口径的书写形态：百分比 → 每完整轮回期望次数

百分比口径已被分母漂移三次静默重定价（86–102 → ≈83 → 114），而没有任何设计意图要求目标变严或变松——内容编排关心的是「玩家一局撞上几次」，不是「占事件池百分之几」。上层口径改写为**「一次完整轮回中，玩家撞上『可能失去能力』场合的期望次数」**；百分比降为括号里的换算副本，分母变动时只重算括号、目标值本身不动。本次重标定即实证：分母 83 → 114，三支持久支的绝对次数一格未动。

### 2. `IgnoresProtection` 移出上层分子，单独持有自己的口径

现状是两个口径嵌套（既有战斗分母的自持目标、又计入上层「全部事件的 1%」），嵌套正是超支的成因。解除嵌套三条依据：

1. **它不写 Profile**（`systems/services/profile-service.md`）——本场结束即恢复，上层口径保护的「构筑投入不被拿走」心理契约它不触碰。
2. **分母不同**（战斗类遭遇 vs 全五类事件）——子集百分比嵌进全集百分比，战斗占比一变内层目标即被静默重定价（本次战斗分母涨 61%、事件分母涨 37%，涨幅不同）。
3. **控制旋钮不同**——它由载体编排控制（R1 / R2 两条硬准入），三支持久支落在内容编排与抽取权重侧，两者不共享任何一个可调的数。

这不违反「不另立一套」——那条纪律针对神通侧，神通仍留在上层口径内；`IgnoresProtection` 的独立口径本已存在且更详尽（`systems/balance.md`），本次只删掉重复计账的那一层。

### 3. 目标频次（各支均不收窄）

| 支 | 目标频次（次 / 完整轮回） | 说明 |
|---|---|---|
| 战斗内 `IgnoresProtection` | ≈1.11（= 3% × 37 场战斗类遭遇） | 5% 下调至 3%：分母 23 → 37 后按绝对次数保住「一轮回约 1 次」量级；正确的收紧位置是这一格，不是压三支持久支 |
| 神通置换 + 禁用合计 | ≈0.5（置换 : 禁用 ≈ 2 : 1） | 新增第四支的份额，四支中最高——轮回级损失、随轮回清理 |
| 法则置换型 | ≈0.3 | 与旧口径反推值持平，不收窄 |
| 法则禁用型 | ≈0.2 | 唯一取低值的一格——无同意的施加最伤构筑契约，份额转给有同意的置换侧 |
| **上层口径 = 持久三支合计** | **≈1.0（≈0.88%，分母 114）** | 新的承重表述 |
| 四支合计（导出量 · 非闸门） | ≈2.11 | 只作叙事密度 sanity check |

三支持久支按「持久度 × 是否经玩家同意」两条轴分配：频次与「持久度 × 无同意」反相关——轮回级最常见、无同意的最稀有，顺序为神通 > 法则置换 > 法则禁用。

**为何必须上调上层合计而非收窄（推演，不是取向）：** 保持旧 1% 总额则 `IgnoresProtection` 一支（1.11）已超总额，其余三支份额为负——唯一收窄解是三条已完整设计的机制（`AbilityChangeSlots` 决策点、结算面板、`GrantPoolManager.TryPickReplacement`、`disabledAbility` 三档等）一次都不出现，与「不为不存在的失控路径写规则」相悖。**≈1.0 档的取向依据：** 唯一不收窄任何既有支的档位；法则两支合计 0.5 次/轮回 = 每两轮回一次，保住「跨篇章尺度的稀有事件」定性；更低（≈0.83）让法则禁用几乎不可见（每 7 轮回一次），更高（≈1.5）与定性拉扯。

### 4. 两文档矛盾裁决：`IgnoresProtection` 无轮回内上限、`CycleState` 不设状态位

`systems/balance.md` 明写「只有 R1 / R2 两条硬准入，不加篇章配额 / 轮回内次数上限 / 加载期核对表；`CycleState` 上不设与本机制相关的任何状态位」，而 `player-power/_index.md` 的复述段却写出「每篇章至多 1 个载体 · 一次轮回内至多结算一次 · 需要一个轮回级布尔位落 `CycleState`」——该段自述「见 `systems/balance.md`」，即声称复述却写出了权威明令不加的规则。**裁给 `balance.md`（复述侧失真）**，`player-power/_index.md` 该段删除、改为回链——与「回链而非复述」纪律一致。本预算按无上限口径取期望 1.11。

### 5. 旋钮全落内容侧，零字段、零校验、零状态位

| 支 | 旋钮 |
|---|---|
| `IgnoresProtection` | 带该效果的 boss 档载体条目数（R1 限定）+ 载体在其池内的出现权重 |
| 法则 / 神通 置换 · 禁用 | ① 带 `AbilityChangeSlots` 的 `AdventureEventData` 条目数；② 各条目的 `SelectionWeight` 档（`Rare` 已是最低档 ⇒ 主旋钮实为条目数，典型每支 1–2 条 `Rare` 档条目） |
| 全局微调 | `PlotModulation` 的既有 arc 系数（`future-event-service.md` 管线，不为本条新增） |

全部数字为待实测校准的初值；「几条 `Rare` 条目 = 几次/轮回」的精确换算归内容阶段（需各类型池条目规模）。

## Clarifications

- 本 handoff 提炼自已评审定案的 `inbox/solution-draft-ability-loss-frequency-budget.md`（status: decided），六项裁决（书写形态改绝对次数 · `IgnoresProtection` 解除嵌套 · 四支目标频次 · 旋钮全落内容侧 · 两文档矛盾裁给 `balance.md` · 六条备选方案否决）均为草稿定案，批量合并 interview 无本分片待裁项。
- 与 rescale 重标定（`2026-09-06-chapter-duration-rescale.md`）重叠的改动点（5% → 3%、分母 114 / 37、跨档叙事密度分母）已由该 handoff 先行落笔，本次只落本稿独有的部分（口径形态、解除嵌套、四支分配、复述失真收口）。

## Open questions

- 各类型事件池的条目规模未定（归内容阶段）⇒「几条 `Rare` 档条目 = 目标频次」的换算待 ch1 内容铺开后实测校准。
- ch2 / ch3 逐类型构成表补齐后，括号里的百分比换算副本须重算（绝对次数不受影响）。

## Notes / triage

- 路由：`systems/player-profile/player-power/_index.md`（上层口径改写 + 四支频次表 + 复述段改回链）· `systems/character-profile/power/_index.md`（神通侧份额）· `systems/balance.md`（`IgnoresProtection` 不计入上层合计 + 换算细化）· `systems/services/future-event-service.md`（⑦ 处一行回链）。
- 由本次答结：`open-questions/06-meta-progression.md` 的「失去能力四支频次预算」条目 → `answer-logs/log-ability-loss-frequency-budget.md`。
