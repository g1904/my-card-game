# adventure-event / finale（AdventureEvent-Finale）

> 篇章边界高潮：渡劫 / 境界突破。**大部分是战斗的变体**（渡劫的对手 = 天劫，天劫是一个带定制卡组的 Enemy）；少部分非战斗形态待日后定制。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **境界突破 = AdventureEvent-Finale（已定案）。** 篇章边界的境界突破定义为 **AdventureEvent-Finale**，**独立类型、区别于 Combat**，并作为**第七类正式并入 ADR-0002 枚举**。Source: `systems/adventure-event/_index.md`、`handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。
- **篇章边界高潮。** Finale 出现在篇章（Chapter）边界，对应修行阶梯上境界的跃迁（炼气 → 筑基 → 金丹 → 元婴）；一次轮回含三个篇章。通过后角色进入新境界，**等级归位为新境界的初期**（见 `systems/game-progression.md`）。Source: `terminology.md`（修行阶梯）。
- **大部分 Finale 是战斗的变体（已定案）。** Finale 使用 combat-service 的 **CharacterManager + EnemyManager**，与 Combat 同一套回合循环与参战方模型；区别在于**独立的胜负条件与奖励结构**，而非另起一套结算代码。Source: `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md`。
- **Finale = 三档难度中的「Boss 盲」（已定案）。** Practice / Combat / Finale 对位 Balatro 的 **small / big / boss blind**——Finale 是**最重的一档**：其**胜负条件与回合数均可相对 Combat 改写**，整体**比 Combat 更难**。标准 Combat 是 10 回合、道念高者胜；Finale 可以要求更高的门槛（例如必须领先若干点）或改变回合数。**推论：这给了「独立胜负条件」一个具体落点**——它不是另起一套结算代码，而是同一套判定的参数被拧紧。具体改写值未给，见待决问题。**注：借的是难度分档结构，不是出现节律**——Finale 只在篇章边界出现，与 Balatro 每 ante 一次 boss blind 形似而不同源。Source: `handoffs/2026-08-02-momentum-conversion-reward-structure-and-mtg-stack.md`。
- **渡劫的对手 = 天劫，天劫是一个 Enemy（已定案）。** 天劫作为敌人条目存在，**带定制卡组**——这是「每个 enemy 各持有一个卡组」的直接应用。Source: 同上。
- **天劫同受赋级约束，无等级规则上的例外（已定案 · 08-05 · 答结「天劫是否天然大幅越级」）。** **天劫只是 Enemy 的一种，遵循同一套境界与赋级规则**——赋级的合法区间同样是**角色当前等级 `±2`**（见 `systems/services/future-event-service.md`）。
  - **推论 ①（自洽性验证 · 叙事与规则天然吻合）：** 篇章末角色处在境界巅峰（全局 13 / 17 / 21），下一境界的初期是 14 / 18 / 22 —— **`diff` 恰为 +1，稳稳落在 `±2` 带内**。「渡劫 = 突破到下一境界」这句叙事**不需要为它开任何规则口子**就能成立。
  - **推论 ②（承重）：Finale 的信息压迫感完整保留。** 天劫落在下一境界 ⇒ **越阶** ⇒ 按越阶硬门**完全无意图信息**。**天劫不是大幅越级（最多 +2），但天然越阶**——信息面的结果与「大幅越级」完全相同，而数值面不至于失控，两个目标同时达成。
  - **推论 ③：天劫走同一条物化路径**（`EnemyData` → 充实 / 改写 → 指派），与常规敌人无异；它的特殊性全部落在**定制卡组**与**遭遇参数**（回合数 / 胜负门槛可拧紧）上，**不落在等级上**。
  Source: `handoffs/2026-08-05-level-band-stack-save-and-token-free-deck.md`。
- **Finale 的具体改写值 = `TurnLimit 12` + `VictoryRule(WinMargin N, DrawCountsAsLoss false)`（已定案 · 初值）。** `N` 初值：**ch1 3 / ch2 5 / ch3 8**（分别对应开局落后 5 / 13 / 25 点）。
  - **加到 12 回合而非减少**：Finale 若同时减回合会退化为**纯粹的起跑线检定**（谁 `baseMomentum` 高谁赢），玩家一整个篇章攒起来的 build 无从表达。**Finale 是 build 的检验场——「更难」体现在门槛，不体现在窗口。**
  - **⚠ Finale 存在四重压迫叠加**：（a）天然越阶 ⇒ 意图完全黑箱；（b）开局落后 5 / 13 / 25；（c）`WinMargin` 额外门槛；（d）失败时道念差最大 ⇒ 扣 `lifeTotal` 最狠。四条**都是既有定案的必然结果**，`WinMargin` 是其中唯一新增的一条，故初值取得保守（不到开局落差的一半），12 回合是对（b）的部分补偿。**若实测过难，先砍 `WinMargin` 再动回合数。**
  Source: `handoffs/2026-08-06d-combat-open-questions-mass-closure.md`。
- **Finale 失败不直接 `defeated`（已定案 · 承重）。** **不新增 `DefeatReason.FinaleFailed`** —— `DefeatReason { Discarded, LifeSpanExhausted, LifeTotalExhausted }` 旁已明写「**战斗失败本身不终结角色，只扣 lifeTotal**」，加一条等于推翻这条已定案。**不需要新规则，因为死亡通道已经存在**：Finale 失败按 1:1 扣 `lifeTotal`，而 Finale 的道念差本就最大（越阶 + 高 `WinMargin`），很容易打穿 → 经既有的 `LifeTotalExhausted` 自然导向 defeated。**结果上「Finale 失败常常等于死」，但走的是既有通道。**
  - **失败后角色留在本篇章**：`lifeTotal` 未归零即可继续消耗寿元找事件——这是「战斗失败本身不终结角色」的直接延伸，不在战斗层另开一条终结通道。篇章边界失败的语义由 ADR-0004（境界存档 · 篇章重试模型）承担，措辞须与 `systems/services/life-cycle-service.md` 对齐。
  Source: 同上。
- **每个篇章只有一个 Finale，失败后不可在同一篇章内再次挑战（已定案 · 08-09b · 推翻 08-06d 的「可再次挑战」）。** 天劫是篇章的**一次性收口**，不是可反复刷的遭遇。想再渡一次这一劫，只能**重走整个篇章**（篇章重试，ch2 / ch3 另有上限 3 / 1，付费 9 / 3）。
  - **推论（承重）：残卷的可刷性由结构封死。** 「一篇章一个 Finale + 败后不可重战」⇒ 每个角色每篇章**至多累积一次或掷骰一次，且二者互斥**；要多累积一次得付出 30–55 分钟重走一章的代价。**道统残卷因此不需要任何额外的冷却 / 次数上限规则**（见 `systems/player-profile/player-power/_index.md`）。
  Source: `handoffs/2026-08-09b-player-power-fragment-finale-bound-drop-chance.md`。
- **Finale 失败但存活（约 1%）⇒ 篇章照常完成、境界照常突破（已定案 · 08-09b · 承重）。** 失败的道念差通常足以打穿 `lifeTotal`，但**未被打穿的那一小部分情形里角色存活并顺利完成该篇章**。
  - **承重推论：渡劫的胜负不再是篇章推进的闸门。** 胜负只决定两件事——`lifeTotal` 的损失量，以及**残卷是否兑现**（发放只认胜利；失败但存活者照常累积、但不掷骰不发放）。
  - **叙事需要一句补白**（「侥幸捱过天劫者亦得突破，只是无所得」量级），否则「失败也能突破」读起来像笔误。落点见待决问题。
  Source: 同上。
- **Finale 是道统残卷的唯一累积源与唯一兑现点（已定案 · 08-09b）。** 失败累积 · 胜利掷骰 · 在**该 Finale 的 eventReward 界面**即时发放，全部并入该事件 `eventEnd` 的那一次 `TryApply`——**不新增结算阶段、不新增存档点**（Finale 结算本就是篇章边界的 `Immediate` flush 点）。**失败侧不给玩家任何提示**（无文案 / 无进度条 / 无百分比）。完整规则见 `systems/player-profile/player-power/_index.md`。Source: 同上。
- **Finale 不承担经验供给（已定案 · 由经验模型推出）。** 天劫的 `diff = +1` 这条自洽性验证隐含一条硬约束：**角色必须在进入 Finale 之前就已升满本境界**，否则 `±2` 带会给出一个更低的天劫等级，「渡劫 = 突破到下一境界」的叙事随之破裂。**推论 ①：全部升级所需经验必须由篇章的常规事件段供满**，Finale 自身的 `ExperienceGrade` 取 `None` 或 `Minor`。**推论 ②：Finale 的出现条件 = 角色已达本境界巅峰**——这不需要新机制，`eventPriority` + `ifMandatory` 已能表达（与 `eventCountLimit` 达成后 Travel 封锁同批的用法同构）。见 `systems/game-progression.md`。Source: 同上。
- **少部分 Finale 不是战斗。** 存在非战斗形态的境界突破，其形态**留待日后定制**，届时才需要战斗框架之外的结算路径。Source: 同上。

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- **境界突破 = AdventureEvent-Finale，第七类，独立于 Combat** → `decisions/ADR-0002-adventure-event-taxonomy.md`（Accepted，07-23 修订）。
- **Finale 为战斗变体（复用参战方结构与回合循环）；天劫 = 带定制卡组的 Enemy** —— 已定案。Source: `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md`。
- **天劫同受 `±2` 赋级带约束，无等级例外；它天然越阶故 Finale 全程无意图信息** —— 已定案。Source: `handoffs/2026-08-05-level-band-stack-save-and-token-free-deck.md`。
- **每篇章一个 Finale、败后不可重战；失败但存活亦完成篇章；Finale 是道统残卷的唯一累积源与兑现点** —— 已定案。Source: `handoffs/2026-08-09b-player-power-fragment-finale-bound-drop-chance.md`。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **Finale 奖励的加厚幅度：** 形态已定（`BaseReward` 与 `RewardPoolId` 随物化定稿）；**具体取值**与 `WinMargin` 的最终数值一并归 **ch1 数值标杆专场**。→ `systems/balance.md`。
- **非战斗形态的 Finale：** 哪些境界突破走非战斗路径、其结算形态如何，留待日后定制。
- **1% 存活分支的叙事补白落点（08-09b 新增）。** 「渡劫 = 突破到下一境界」现有一个「失败也能突破」的分支，需一句让它读起来不像笔误的文案。归 `ux/screen-flow.md` 的篇章收口呈现，还是 `systems/services/plot-manager.md` 的叙事层？Source: `handoffs/2026-08-09b-player-power-fragment-finale-bound-drop-chance.md`。
- **与隐藏属性的交互：** 「大限将至」等隐藏属性剧情线触发后是否转入 Finale、Finale 是否消耗 / 检定隐藏属性未定。→ `systems/services/plot-manager.md`。

## 对应
提炼至：`.claude/knowledge/systems/adventure-event/finale.md`（待建）
