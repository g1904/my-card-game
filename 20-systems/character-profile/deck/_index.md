# deck

> 角色卡组 deck —— 抽牌堆 / hand / 弃牌堆、seeded 洗牌、deck 变更，以及卡牌 / **CardData** 定义与起始卡组内容设计。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **deck 是 CharacterProfile 的一部分。** 卡组、hand、以及打出一张卡的结算，都是单次轮回 / 单角色的状态；deck 随轮回推进被增 / 删 / 升级。Source: `10-handoffs/2026-07-24-docs-restructure-class-model.md`。
- **卡牌是道念的唯一产出途径（已定案 · 承重）。** 战斗的胜负标尺是道念（见 `20-systems/scoring.md`），而**道念由打出的卡牌产生**；卡牌**既能给自己加道念，也能削减对方道念**（削减在 0 处截断，无负道念；**截断发生在每一次结算时，溢出量不结转** —— 见 `20-systems/scoring.md`）。**推论：卡牌设计的第一维度是「产多少 / 削多少」**——它取代了 HP 消耗战里的「打多少伤害 / 挡多少」，也是与 `manaLimit`（每回合刷满）配合出节奏的那一维。战斗**定长 10 个回合**、**起始道念按等级给**，共同框定了「一张牌该值多少道念」的量纲（基准未定，见待决问题）。Source: `10-handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。
- **战斗中每个参战方各有一个 `DeckModule`（已定案）。** 卡组不是战斗内的全局单件：**每个 character、每个 enemy 各持有一个**，由 combat-service 的 CharacterManager / EnemyManager 各自持有（`DeckModule` = 第三级抽象，见 `20-systems/architecture.md`）。**敌人也出牌**，且可带定制卡组（如 Finale 的天劫）。本文档持有**角色侧**卡组的设计；敌方卡组的内容形态见 `20-systems/adventure-event/combat/`。Source: `10-handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md`。
- **卡牌结算 = MTG 的 stack，但**不含交互与优先权**（已定案 · 承重）。** 打出的卡牌**不立即生效**，而是先入栈，按**后进先出（LIFO）**依次结算——**「打出」与「结算」是两个时刻**，结算顺序由此成为一条明确的规则，也为至今空白的**回合内效果 / 状态系统**提供了天然骨架。**但交互（instant / 栈非空时出牌）与优先权传递整体移除**：它们**把对局拉得太长、决策点过多、复杂度高而深度收益小**。**推论 ①：回合回到「我打完换你打」**——只有回合归属方能在自己的主阶段出牌。**推论 ②：卡牌不多出「能否响应」这一维**，**instant 一类关键字明确不借**——所有牌都是 **sorcery speed**（只能在自己回合的主阶段打出），出牌时机是全局规则而非卡牌属性。**推论 ③：stack 的承重点是触发的解决顺序（已定案）**——**在栈上的牌可以触发能力，被触发的能力也进栈**，故**即便只打出一张牌，栈深也可以大于 1**；一次结算连锁产生的多个触发按 **LIFO** 解决，**后触发的先生效**，这使结算顺序成为卡牌设计可利用的资源。**「栈非空时不能出牌」对双方都成立**（不为归属方开口子，「主阶段连续压栈再统一结算」的路线不采用）。Source: `10-handoffs/2026-08-02b-stack-without-interaction-and-three-step-turn.md`（收窄 `10-handoffs/2026-08-02-momentum-conversion-reward-structure-and-mtg-stack.md`）。
- **回合结构 = 起始步 / 主阶段 / 结束步三步（已定案），卡牌侧的落点有三处。** ① **抽牌在起始步**（归属方 mana 恢复至 `manaLimit` → 触发「回合开始时」→ 抽牌）；② **主阶段是唯一出牌阶段**；③ **结束步触发「回合结束时」并清理回合内状态**，把状态分成「回合内临时」与「跨回合持续」两档。**三步是回合归属方的流程，双方不同时走。** 完整结构见 `20-systems/services/combat-service.md`。Source: 同上。
- **手牌上限是恒定不变式，不设弃牌机制（已定案）。** **手牌在任何时刻都不得超过上限**——**没有时间限制，也没有「结束步弃到上限」这类必须弃牌的机制**。**上限值待定。** **推论：约束点落在会让手牌增加的时刻**（抽牌、以及任何「加入手牌」类效果），而不是回合末的一次清算。Source: 同上。
- **满手时抽牌 = 抽不进（已定案 · 08-03 · 抽牌流程的前置条件已就位）。** 满手时抽牌**抽不进——牌留在抽牌堆，这次抽牌无事发生**；**「加入手牌」类效果同理落空**。「抽出即弃」「直接销毁」两条路线**均不采用**。**推论 ①：手牌上限是一条纯上界**——不产生任何弃牌堆流量、不消耗抽牌堆。**推论 ②：弃牌不是被规则强制的动作原语**（回合末不弃、满手也不弃）——**弃牌堆只由「打出后进弃牌堆」与「卡牌效果显式弃牌」填充**，这是弃牌堆流量的完整清单。**推论 ③：抽牌堆顺序不被满手情形扰动**，seeded 洗牌的确定性不因此分叉；「本回合抽 N 张」在满手时等价于抽 0 张。**推论 ④：满手的代价是 tempo 而非资源**——牌没丢，只是这一拍没拿到，手牌上限因此是**逼玩家出牌腾位的节奏约束**，不是惩罚。Source: `10-handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md`。
- **触发式效果的载体是开放的，不专属卡牌（已定案 · 08-03）。** 牌上的触发器、**场上的持续状态**、**CharacterPower（神通）** 都可能承载触发式效果，**清单开放**、日后可再增。**推论 ①：`CardData` 的触发器字段只是载体之一**——触发的匹配逻辑不能写死在卡牌类型里，需要一个统一的注册 / 匹配面（它坐在 **battlefield** 上，见 `20-systems/services/combat-service.md`）。**推论 ②：压栈者与载体解耦**——命中后把被触发的能力压入栈的一律是 StackManager。**推论 ③：轮回内 build 的三件套（卡牌 / 法宝 / 神通）在战斗内不再只有卡牌能说话**——神通可承载触发，意味着「这局我变强了多少」在战斗内有第二条表达通道。Source: 同上。
- **战场（battlefield）是牌离开手牌之后的去处（已定案 · 08-03）。** 打出的牌先入**栈**（等待结算），结算后若留下持续效果则落到**战场**（正在生效的东西）；两者各由 combat-service 的 StackManager / BattlefieldManager 持有。**推论：卡牌的生命周期链路补全为「卡组 → 手牌 → 栈 → 战场 / 弃牌堆」**，此前「打出之后到进弃牌堆之间」的那一段有了明确的两个位置。Source: 同上。
- **card / deck / combat 体系将大量借用 MTG 术语（已定案 · 方向）。** 借的是 MTG 的**结算模型与术语体系**（stack、resolve、trigger…），用以简化表达；**规避的仍是它的胜负模型**（血量归零）**与 mana 曲线**——二者不冲突。借词须在 `terminology.md` 登记为已定含义，避免同一个词在本库与 MTG 原义之间漂移。Source: 同上。
- **抽牌堆 / hand / 弃牌堆 · seeded 洗牌 · deck 变更。** 抽牌、手牌、弃牌的循环，以及洗牌必须由轮回种子（seed）驱动以保证确定性可复现。deck 变更（增卡 / 删卡 / 升级）来自遭遇（如 Exchange / 奖励）。
- **卡牌 / CardData 定义。** 卡牌是**数据**（`[GlobalClass] partial class CardData : Resource`，以 `.tres` 编写，带稳定唯一 `Id`）；打出一张卡涉及**费用（mana）、目标选择、效果流水线、触发器**。卡牌数值不硬编码，读自数据资源（见 `data-resource-rules.md`）。

> 具体的抽 / 弃 / 洗规则、CardData 字段（费用、目标、效果、触发器）、效果流水线阶段、起始卡组内容等见 `common-properties.md`。

## 决策(-> ADR)
> _已定案的决定链接到 50-decisions/ADR-####。_

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **卡牌设计意图为占位。** 卡牌的具体机制（手牌上限的**取值**、每回合抽牌数、效果关键字、目标规则、CardData 字段清单、起始卡组）均尚未设计，需一次 handoff。（**出牌时机已定**：所有牌为 sorcery speed；**手牌上限的存在性已定**，见上。）
- **道念产 / 削的量纲基准（承重 · 已归属专场）。** 「卡牌产道念、可互削、下限 0」已定；**一张牌该产多少**、**10 个回合内一方的总产出应达到起始 `baseMomentum` 的几倍**——**明确推迟到内容横向扩展阶段**，切入点是**设计起始角色 starter deck 的过程**，届时聚焦并定义 **ch1 的数值标杆**（一场专门的「ch1 数值模型」session）。**越级追分的结论已先给出：可能，但很难，境界差越大越难**——`baseMomentum` 跨度随境界放大正是为此。是否存在道念相关的状态与倍率仍未定。→ `20-systems/balance.md`、`20-systems/scoring.md`。Source: `10-handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md` + `10-handoffs/2026-08-02-momentum-conversion-reward-structure-and-mtg-stack.md`。
- **手牌上限的取值（08-02b 新增）。** 存在与语义已定（**满手抽不进**亦已定）；**数值未给**，敌人侧是否同值亦未给。Source: 同上。
- **「加入手牌」落空时凭空生成的牌去哪（08-03 新增）。** 从抽牌堆抽的情形已明确（**留在堆里**）；但若效果是**生成一张新牌**（token 类）或**从弃牌堆 / 牌库外取牌**，满手时该牌是**根本不产生**、还是**产生后进弃牌堆**？Source: `10-handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md`。
- **触发条件能否跨归属方（08-02b 新增 · 08-03 收窄）。** **载体形态已答定**（牌上触发器 / 场上持续状态 / CharacterPower，清单开放）；仍待定触发条件能否写「对手的回合开始时」这类跨归属方的时点。→ `20-systems/services/combat-service.md`。Source: 同上。
- **每回合抽牌数与首回合 / 起始手牌（08-02b 新增）。** 抽牌时机已定（起始步、「回合开始时」触发之后）；数量、先后手是否有抽牌差未给。Source: 同上。
- **借入的 MTG 术语清单与中文定名（08-02 新增 · 08-02b 收窄）。** 哪些词借、哪些不借（避免与既有仙侠定名冲突，如 mana 已定名「法力」、momentum 已定名「道念」）。**已定：`instant`（瞬间）不借**；**待定名的第一批 = sorcery speed / start step / main phase / end step / resolve / trigger**。→ `terminology.md`。Source: 同上。
- **出牌费用 = mana（已定案）。** 每回合出牌资源为 mana，**每回合开始恢复至 `manaLimit`**（炼气基线 5/5）；`manaLimit` 由事件 cost / reward 推拉。→ 见 `../mana.md`。
- **敌方卡组是否共用同一套 `CardData` 体系未定。** 敌人也持有卡组已定；其卡牌是与玩家共用卡池 / 共用 `CardData` 定义，还是另立敌方卡池，以及敌方卡组规模与抽牌规则均未定。→ `20-systems/adventure-event/combat/`。Source: `10-handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md`。
- **探查（probe）的卡牌 / 技能形态待设计。** 「付出代价换取当回合敌人意图」的效果已定名并归入本阶段之后的内容横向扩展；花费形式（mana / 弃牌 / 每场次数）与承载形态（卡牌 / 能力 / 道具）待设计。→ `20-systems/services/combat-service.md`。Source: 同上。

## 对应
提炼至：`.claude/knowledge/systems/character-profile/deck/_index.md`（待建）。
