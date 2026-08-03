# balance

> 可调的全局数值：lifeTotal / mana 基线、ante 曲线、掉落权重、重试上限等。系统从数据（`.tres`）读取，不硬编码。

## 意图
> _从 handoffs 中提炼的设计意图。保持更新。_

- **炼气期基线（起始满值）：** 生命 lifeTotal = **10 / 10**、法力 mana = **5 / 5**。mana 采用**无曲线 · 每回合恢复至 `manaLimit`** 模型，且 **`manaLimit` 由事件 cost / reward 推拉**（见 `systems/character-profile/mana.md`），**不设下界护栏**。**lifeTotal 现为战斗外耐久**（战斗内不参与，只在失败结算时按道念差扣减，见 `systems/scoring.md`、`character-profile/life-total.md`）——**数值未变，语义变了**。这些是可调数值，存入 `.tres` 而非硬编码。Source: `handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md` + `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md` + `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。
- **全局等级序的境界基数（已定案 · 连续无跳变）。** 修行等级由「境界 realm + 境界内 level」合成为全局序 **1–22**：**炼气 1–13 / 筑基 14–17 / 金丹 18–21 / 元婴 22**，枚举值自带描述（`level=1` → 炼气一层，`level=14` → 筑基初期，…）。**境界之间不留跳变**——境界鸿沟改由 `baseMomentum` 的跨度放大承载（见下表），这条分工使等级序本身保持为一把简单的直尺。Source: `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md` + `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。

- **`baseMomentum`：每个等级的战斗起始道念（可调数值 · 承重）。** 战斗开始时双方各持一个由自身等级决定的起始道念（模型见 `systems/scoring.md`）：

  | 境界 | 全局等级 | `baseMomentum` |
  |------|---------|----------------|
  | 炼气（1 层 ~ 13 层） | 1–13 | **1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 15** |
  | 筑基（初期 ~ 巅峰） | 14–17 | **20, 24, 28, 32** |
  | 金丹（初期 ~ 巅峰） | 18–21 | **45, 55, 65, 75** |
  | 元婴（初期） | 22 | **100** |

  - **形状是有意的：** 炼气段线性 +1（第十三层跳到 15，作为突破前的台阶），筑基以上**每级跨度持续放大**（炼气段 +1、第十三层 +3；筑基段 +4；金丹段 +10；境界之间 +5 / +13 / +25）。**境界鸿沟由此承载**，这正是全局等级序基数不必留跳变的原因。
  - **它是战斗强度的主刻度：** 等级差 → 起点差 → 开局领先量。炼气十层（10）挑战筑基初期（20）即开局落后 10 点，须在 10 个回合内追回。
  - **表已完整**：22 个全局等级各有一个 `baseMomentum`。
  Source: `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。

- **意图揭示的分界值（已定案）。** 判据 = **越阶硬门 + 同阶差值门槛**（`diff` = 敌人全局等级 − 角色全局等级）：**越阶（敌人境界更高）一律完全无信息**；同阶时——**第一篇章** `diff ≤ -3` 完整 / `-2 ~ 2` 仅类别 / `≥ 3` 无信息，**第二 · 第三篇章** `diff ≤ -2` 完整 / `-1 ~ 1` 仅类别 / `≥ 2` 无信息（ch2 · ch3 两端各收紧一级）。三处门槛皆为可调数值。**完整意图因此是碾压专属，「仅类别」是常态档。** Source: `handoffs/2026-08-02c-intent-threshold-inversion-and-aggregate-intent.md`。
- **敌人赋级的上界 = 高一个大境界的初期（已定案 · 08-03）。** 物化赋级的天花板由角色**当前境界**决定：炼气 → 最高筑基初期（全局 14）、筑基 → 最高金丹初期（18）、金丹 → 最高元婴初期（22）；元婴无更高境界。**上界档必然是越阶 ⇒ 必然完全黑箱**（最难的遭遇即最不可读）。**上界只约束「最高出到几级」，不约束分布**（出现频次与权重待定）。**⚠ 它与「一次惨败不打穿耐久」的初衷存在算术冲突**（炼气一层对筑基初期 = 开局落后 19 > `lifeTotal` 10），见待决问题。Source: `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md`。
- **寿元预算与消耗（可调数值）：** 炼气起始寿元 = **100**、抵达筑基 **+100**、抵达金丹 **+300**、抵达元婴 **+500**（隐藏属性；递减到 0 → defeated，见 `systems/services/plot-manager.md`）。**剩余寿元跨篇章结转**——第二篇章可用预算 = `+100 + 第一篇章剩余`，故「省着花」有跨篇章回报。消耗侧：每个 AdventureEvent 的 `lifeSpanCost` 由内容侧以**正数量值**书写（物化时取负，见 `systems/services/future-event-service.md`）。Source: `handoffs/2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md` + `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。

- **`lifeSpanCost` = 控制篇章时长的主旋钮（已定案 · 目标时长驱动的分档）。** 先前记载的「基准 -1 / 基准 1」**只是占位值，不是设计意图**。真正的判据是**目标游玩时长**——一个篇章 = 移动端一个时段：

  | 篇章 | 寿元增量 | 目标时长（熟练玩家口径） | `lifeSpanCost` 取向 |
  |------|---------|------------------------|---------------------|
  | 第一篇章 炼气→筑基 | 起始 **100** | **30–40 分钟** | **基准档** |
  | 第二篇章 筑基→金丹 | **+100**（外加第一篇章结转的剩余） | **35–45 分钟** | **略微上调**（例：闭关耗时更长） |
  | 第三篇章 金丹→元婴 | **+300**（远多于前两章） | **45–55 分钟** | **相应上调**，把时长压回区间 |

  - **口径 = 已掌握策略的熟练玩家。** 新手所需时间更长，故这三个区间是**下限口径**而非平均值。Source: `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。
  - **寿元预算不变，靠调 `lifeSpanCost` 控时长。** 预算增量（100 / +100 / +300 / +500）是**叙事与阶梯的形式量**；**事件定价才是时长旋钮**。
  - **时长上调改写了旋钮的绝对水平（08-01b）。** 目标时长几乎翻倍而预算未变，故**单次定价的绝对值要比先前设想低得多、一个篇章的事件总数要多得多**；但**篇章之间「逐章上调」的相对关系仍成立**（第三篇章 300 点预算对 45–55 分钟，单价仍显著高于第一篇章 100 点对 30–40 分钟）。
  - 事件之间定价有差异（**闭关 Research 比常规事件耗时更长**）；**具体分档表待定**，见待决问题。
  Source: `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md` + `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。

- **道念（momentum）相关数值。** 计分 = 道念、胜负 = 道念高者胜、**标准 Combat 定长 10 个回合**（见 `systems/scoring.md`）。**已定的两项：起始值**（上方 `baseMomentum` 表）与**负侧换算 = 道念差 1:1 扣 lifeTotal**（不是系数、不是分档）。仍归本文件待设计的有三组：**各卡牌 / 行为的道念产出与削减量**、**胜利侧「道念差 → 奖励厚度」的换算**（是否也 1:1 未定）、**敌人各等级的道念产出能力（缩放曲线）**。**「一张牌该产多少」的基准由 `baseMomentum` 与回合数共同框定**——它决定越级追分的难度（**追分可能，但很难，境界差越大越难**；`baseMomentum` 跨度随境界放大正是为此）。Source: 同上 + `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md` + `handoffs/2026-08-02-momentum-conversion-reward-structure-and-mtg-stack.md`。
- **每场战斗的时长可预测（已定案 · 08-02b 恢复）。** 回合数固定、且每个回合的步骤固定为三步（起始步 / 主阶段 / 结束步，见 `systems/services/combat-service.md`）——**交互与优先权移除后，「定长 = 时长可预测」重新成立**，故**无须为战斗内交互次数另设护栏**（响应次数上限 / 计时一类）。这条直接服务篇章时长控制：一场标准 Combat 的时长可作为反推 `lifeSpanCost` 的稳定输入。Source: `handoffs/2026-08-02b-stack-without-interaction-and-three-step-turn.md`。
- **数值标杆归一场专门的「ch1 数值模型」session（已定案 · 流程）。** 卡牌的道念产 / 削量纲、`lifeTotal` 的回复幅度等**具体数值标杆**，在**内容横向扩展阶段**定义；切入点是**设计起始角色 starter deck 的过程**，届时聚焦并定义**第一篇章（ch1）的数值标杆**。**并且优先打磨 ch1 的内容。** **推论：这些条目不再是机制焦点区的阻塞项**，而是排进了一场已被点名的专场——与既定的「机制先行、内容随后」路线一致（见 `vision/scope.md` 的开发路线）。Source: `handoffs/2026-08-02-momentum-conversion-reward-structure-and-mtg-stack.md`。
- **元婴 +500 无玩法影响（阶梯闭合项）。** 抵达元婴 = 第三篇章通关 = **游戏终点**（四境三篇章，见 `systems/game-progression.md`），轮回到此结束——因此 +500 **不产生任何可消耗的寿元预算**，只是**最后一次数值更新并存档**。它是形式上的阶梯完整性，**不是平衡杠杆**：调整它不改变任何一局的可玩长度。**但它有明确的读者（已定案）：元婴界面**——一块**类似「通关证书」的终局展示面**——需要读到最终寿元值，因此该字段更新**值得保留**，不是死字段。见 `ux/screen-flow.md`。Source: `handoffs/2026-07-25b-event-cost-fields-capability-flags-and-service-hierarchy.md` + `handoffs/2026-07-26-event-priority-skip-semantics-and-hotfix-scope.md`。
- **平衡数值集中管理。** 可调数值（lifeTotal / mana 基线、寿元预算、ante 曲线、掉落权重、重试上限、缩放）存放在导出字段或专门的平衡资源中，系统从数据中读取——与 `data-resource-rules.md` 一致。Source: `handoffs/2026-07-24-docs-restructure-class-model.md`。
- **同步 / 内容管线旋钮（初值已给，待实测校准）。** 这些不是玩法平衡值，但同属「不硬编码、可线上调」的可调数值，归本文件或运行时配置：

  | 旋钮 | 初值 | 归属 |
  |------|------|------|
  | push 防抖窗口 | **5 s** | `systems/services/sync-service.md` |
  | 断线缓冲上限（未同步存档点数） | **3** | 同上 |
  | 断线缓冲上限（最早变更滞留时长） | **180 s** | 同上 |
  | overlay 下载重试次数 / 退避 | **3 次 / 1s · 2s · 4s** | `systems/services/content-service.md` |
  | 剧本预取深度 | **下一批 eventOptions 对应的 key points** | `systems/services/plot-manager.md` |

  Source: `handoffs/2026-07-27-content-gating-offline-resilience-and-rng-persistence.md`。

## 决策(-> ADR)
> _已敲定的决定链接到 decisions/ADR-####。_

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **⚠ 赋级上界与 lifeTotal 的算术冲突（08-03 新增 · 承重 · 需裁决）：** 上界已定为**高一个大境界的初期**，但它按**境界**给而非按 `diff` 给——**境界内低层角色面对的最坏差距远大于高层角色**：炼气一层（`baseMomentum` 1）对筑基初期（20）开局落后 19，而炼气 `lifeTotal` 仅 10/10，**一次惨败即打穿耐久**，恰是这条上界原本要规避的情形。可能的收口：① 再叠一条相对 `diff` 上界；② 只在境界后期才允许出到上界档；③ 抬 `lifeTotalLimit` 的境界基线。→ `systems/services/future-event-service.md`、`systems/character-profile/life-total.md`。Source: `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md`。
- **`experiencePoint` 的升级阈值曲线（08-02 新增 · 承重）：** 每级一个经验阈值、事件奖励发经验已定案；**各级阈值**与**单次事件的经验给予量**未定，两者互为倒数须一同确定（炼气 13 级 / 筑基 · 金丹各 4 级）。→ `systems/game-progression.md`。Source: 同上。
- **`manaLimit` 推拉的分档：** 恢复机制已定（每回合恢复至上限）、成长途径已定（事件 cost / reward 推拉）、**下界护栏已明确不做**；仍待定：哪些事件推高 / 压低、单次幅度，以及进入更高境界时是否另有一次基线跃升。→ `systems/character-profile/mana.md`。Source: `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md` + `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。
- **各篇章 `lifeSpanCost` 的具体分档表（08-01 新增 · 承重）：** 定价方向已定（目标时长驱动、逐篇章上调、闭关更耗）；仍待定**哪些事件类型多耗、单次幅度各是多少**——需以 **30–40 / 35–45 / 45–55 分钟**（08-01b 上调后）**反推**，且反推出的单次定价将显著低于先前设想。→ `systems/adventure-event/`。Source: `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。
- **道念的三组数值（08-01 新增 · 08-02 再收窄）：** **起始值已定**（`baseMomentum` 表）、**负侧换算已定**（道念差 1:1）。仍待定：卡牌的道念产出 / 削减量（**已归 ch1 数值模型专场**）、**胜利侧「道念差 → 奖励厚度」是否也 1:1**（若是，1 点道念差在奖励侧等于什么单位？）、敌人各等级的道念产出缩放。→ `systems/scoring.md`、`systems/adventure-event/combat/`。Source: 同上 + `handoffs/2026-08-02-momentum-conversion-reward-structure-and-mtg-stack.md`。
- **可选奖励的候选生成参数（08-02 新增）：** 候选项数量、抽自哪个池、走哪条 RNG 子流（`Reward` 已存在）、是否受道念差影响（赢得越多候选越好，还是道念差只影响强制部分的厚度）。→ `systems/services/combat-service.md`。Source: 同上。
- **Practice / Finale 的难度改写值（08-02 新增）：** 二者的回合数与胜负条件可相对标准 Combat（10 回合 / 道念高者胜）改写，Practice 更简单、Finale 更难；**具体取值未给**。→ `systems/adventure-event/practice/`、`finale/`。Source: 同上。
- **等级产出的频次与分布（08-01 收窄）：** **途径已定** —— 等级成长 = AdventureEvent 的 reward（不只 Combat / Practice，失败也可能给，见 `systems/game-progression.md`）；仍待定：一章内需要多少个升级型产出才能从 1 爬到 13 / 1 到 4、如何分布、失败产出是否弱于胜利。**它与寿元预算的花法互相约束。** Source: 同上。
- **敌人物化时「充实 / 改写」的规则：** 来源已答定（`EnemyTemplate` + future-event-service 物化赋级）；仍待定**依什么决定这次给几级、卡组怎么改**（角色等级？篇章？location？剧本调制？）。→ `systems/services/future-event-service.md`、`systems/adventure-event/combat/`。Source: `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。
- **成本类型的 element 清单与数值分档未定：** `selectCost` 已定为**定制复合成本类型**、`lifeSpanCost` 为其一个 element（内容侧正数量值）；其余 element（jade / mana / 道具 / 隐藏属性推拉？）、各 element 的数据形态与基准分档、以及 `skipCost` 的数值取向均未定。→ `systems/adventure-event/common-properties.md`。Source: `handoffs/2026-07-25b-event-cost-fields-capability-flags-and-service-hierarchy.md`。
- **重试上限是否作平衡项再调：** 基线 无限 / 3 / 1 已定案，**持有 premium bundle 为 无限 / 9 / 3**（见 `systems/monetization.md`）；两套数值若后续视作可调平衡项则归此。
- **blind / ante 缩放曲线：** 具体 ante 缩放 / blind 要求 / 奖励曲线尚未陈述（进程语义见 `systems/game-progression.md`）；一旦落定，数值归此。Source: `handoffs/2026-07-24-docs-restructure-class-model.md`。

## 对应
提炼至：`.claude/knowledge/data/_index.md`（引用层，待建）。
