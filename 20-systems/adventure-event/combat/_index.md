# adventure-event / combat（AdventureEvent-Combat）

> 正式回合制战斗遭遇：回合结构、敌人意图 / AI、**mana + 道念战斗模型**、胜 / 负结算。含敌人内容定义。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

### 战斗定位

- **Combat = AdventureEvent 的一个子类型。** 与 ADR-0002 分类法一致。
- **战斗是回合制且易读，而非实时 / 拼 APM。** 敌人以「意图（intent）」表达下一步行动；**意图是否呈现给玩家由等级差决定**（见下）。Source: `10-handoffs/2026-07-13.md`。

### 战斗模型 = mana（出牌）+ 道念（计分与胜负）（已定案）

- **胜负 = 道念高者胜（已定案）。** 战斗内的胜负标尺是**道念（momentum）**——计分用的胜利点数，双方各持一份，**高者胜**。**战斗过程中 lifeTotal 不参与**（既不消耗也不读取）；失败时角色在**结算时刻**按「角色道念 − 敌人道念」的差值损失 lifeTotal。完整模型见 `20-systems/scoring.md`；lifeTotal 的战斗外语义见 `20-systems/character-profile/life-total.md`。Source: `10-handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。
- **一场战斗 = 固定 10 个回合（已定案）。** 双方各 5 个回合、交替行动，**打满即止**再比道念；不设提前终止（无「先到某值即胜」，也不以卡组耗尽终止）。**推论：战斗是定长的**——每场的时长可预测，直接服务于篇章时长控制。Source: `10-handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。
- **道念的规则骨架（已定案）：** 由**卡牌**产出、**可互相削减**、**下限为 0**；**起始道念 = `baseMomentum`（按自身全局等级）**，故**等级差直接变成开局的起跑线差**——这与「敌人等级精确标注」形成闭环：看到等级即看到起跑线。表与系数归 `20-systems/balance.md`，完整模型见 `20-systems/scoring.md`。Source: 同上。
- **胜利侧也读道念差（已定案）。** 赢多少也算数：**道念差越大，奖励越厚**（碾压 > 险胜）。道念差因此是一个双向刻度——胜侧给奖励厚度，负侧扣 lifeTotal。Source: 同上。
- **不是 StS 纯 HP，也不是 Balatro 的 chips × mult。** 道念是**双方对抗的相对量**（比谁高），不是对抗静态阈值的绝对量——与「敌人也出牌、双方对称」的参战方模型一致。
- **mana = 无曲线 · 每回合恢复至 `manaLimit`（已定案）。** 不采用 mana 曲线（既非 Hearthstone 式每回合 +1 上限，也非 MTG 式打地递增）：战斗内**每回合开始 mana 自动恢复到 `manaLimit`**；`manaLimit` 本身**由 AdventureEvent 的 cost / reward 推拉**（可升可降），不随境界自动成长；**不设下界护栏**（下降极罕见）。**炼气期标准基线（起始满值）：** life = **10/10**、mana = **5/5**——战斗模型改写**未改动这两个数值**，只改了 life 的语义。Source: `10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md` + `10-handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md` + `10-handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。

### 危险度 = 精确标注敌人等级（已定案）

- **不做模糊的危险度档位。** 「同阶 / 略高 / 越阶 / 无从揣度」一类模糊标签**否决**；Combat / Practice / Finale 在 **eventOptions 上精确标注敌人的等级**。Source: `10-handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。
- **推论 ①：等级差对玩家可见。** 玩家可自行把标注的敌人等级与自身等级比对，从而**理解意图为何被遮蔽**——信息遮蔽有了可解释的因，而不是无来由的惩罚。见 `40-ux/combat-ux.md`。
- **推论 ②：越级挑战成为可主动选择的风险 / 回报维度。** 信息可见，抉择才成立：玩家可以明知山有虎地去打高几级的敌人。Source: 同上。

### 意图的三档揭示（已定案）

- **默认揭示，越级才降级。** 三档：**完整意图**（类型 + 数值）→ **仅类别**（攻击 / 防御 / 增益 / 特殊，无数值）→ **完全无信息**（不给任何替代线索）。Source: `10-handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md`。
- **分界值 = 同阶差值 + 越阶硬门（已定案）。** **越阶（敌人境界高于角色）一律完全无信息**——不论全局等级差多小；同阶时按篇章取差值门槛（ch1：`diff ≤ 0` 完整 / `1–2` 仅类别 / `≥ 3` 无信息；ch2 · ch3：`diff ≤ 0` 完整 / `= 1` 仅类别 / `≥ 2` 无信息）。**这把「境界鸿沟」从数值差提升为一条结构性规则**，也推翻了先前「ch1 差 > 3 才降级」的篇章容差表述。完整规则与呈现见 `20-systems/services/combat-service.md`、`40-ux/combat-ux.md`。Source: `10-handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。
- **探查（probe）是第二条信息通道** —— 玩家主动付代价换取当回合意图；形态归卡牌 / 技能内容的横向扩展阶段，本阶段搁置。Source: `10-handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md`。
- **敌人图鉴给静态知识**（这个敌人会做哪些事），**不给动态情报**（它这回合做什么），故不架空越级黑箱。**一次遭遇即解锁全部词条文案**（人物背景 / 功法简介 / 运作方式 / 特点与弱点 / 样本卡组的关键卡牌）。见 `20-systems/player-profile/codex/enemy-codex.md`。Source: 同上 + `10-handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。

### 敌人

- **敌人持有道念、intent（意图）、行为，并持有自己的卡组（已定案）。** 敌人也出牌：每个 enemy 各有一个卡组，可为定制卡组（如 Finale 的天劫）。参战方结构见 `20-systems/services/combat-service.md` 的 EnemyManager / CharacterManager。**敌人侧的战斗内量与玩家侧对称，也是道念**——敌人同样以道念高低论胜负，不设独立的血量池。Source: `10-handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md` + `10-handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。
- **敌人带等级，等级是物化产物（已定案）。** 敌人的静态数据集中在 **`EnemyTemplate`**（稳定 `Id` + 图鉴文案 + 基准数值 + **样本卡组**）；**future-event-service 取一份模板 → 充实 / 改写 → 指派给该事件**，等级在这一步确定。因此**同一个敌人可在不同篇章 / 情境下以不同等级出场**，等级既是意图揭示的判据，也**随物化产物落进 `EventOption` 精确标注给玩家**。见 `20-systems/services/future-event-service.md`。Source: `10-handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。
- **敌人是数据资源。** 每个敌人模板为一个 `.tres` 内容条目，带稳定 `Id`；战斗 AdventureEvent 引用敌人组合。Source: `data-resource-rules.md`。
- **敌人的战斗强度以 `baseMomentum` 为主刻度。** 敌人等级 → 起始道念 → 开局领先量，这是越级压迫感的直接来源；「敌人各等级的道念产出缩放」仍待设计。→ `20-systems/balance.md`。Source: `10-handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。

## 决策(-> ADR)
> _已定案的决定链接到 50-decisions/ADR-####。_

- **战斗模型 = mana（出牌）+ 道念（计分与胜负）；胜负 = 道念高者胜；失败按道念差扣 lifeTotal** —— 已定案。Source: `10-handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。
- **战斗固定 10 回合（双方各 5）；道念由卡牌产出、可互削、下限 0、起始 = `baseMomentum`；胜利侧按道念差给奖励厚度** —— 已定案。Source: `10-handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。
- **敌人静态数据 = `EnemyTemplate`；敌人等级为 future-event-service 的物化产物** —— 已定案。Source: 同上。
- **意图分档 = 同阶差值 + 越阶硬门** —— 已定案（推翻篇章容差表述）。Source: 同上。
- **mana 无曲线 · 每回合恢复至 `manaLimit`、炼气基线 10/10 · 5/5** —— 已定案。Source: `10-handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md` + `10-handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md`。
- **敌人意图三档揭示（按全局等级差）；探查为第二条信息通道** —— 已定案。Source: `10-handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md`。
- **危险度 = eventOptions 上精确标注敌人等级（否决模糊档位）；等级差因此可见** —— 已定案。Source: `10-handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。
- **Combat 为分类法第二类** → `50-decisions/ADR-0002-adventure-event-taxonomy.md`。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **意图类别的枚举：** 第二档展示的粒度定为「攻击 / 防御 / 增益 / 特殊」，其正式枚举与敌人行为的映射未定。→ `20-systems/services/combat-service.md`、`40-ux/combat-ux.md`。Source: `10-handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md`。
- **`EnemyTemplate` 与既有 `EnemyData` 的关系：** 是同一个东西的两个名字（则统一定名），还是两层？**物化后的敌人实例**亦未定名，且「随 `EventOption` 落存档 vs 战斗开始时再展开」未定。→ `20-systems/services/future-event-service.md`。Source: 同上。
- **敌人卡组的设计形态：** 模板带**样本卡组**已定（物化时可改写）；其卡牌是与玩家共用 `CardData` 体系还是另立敌方卡池、卡组规模与抽牌规则均未定。→ `20-systems/character-profile/deck/`。Source: `10-handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md` + 同上。
- **平局已定案：** 10 回合打满道念相等 → **只发基础奖励**、不扣 lifeTotal（`CombatOutcome.Draw`）。
- **卡牌产 / 削道念的量纲基准：** 一张牌该产多少、10 回合内一方总产出相对起始值的倍数——**它决定越级追分是否可能**；是否存在道念相关的状态与倍率亦未定。→ `20-systems/character-profile/deck/`、`20-systems/balance.md`。Source: 同上。
- **道念差 → lifeTotal 损失 / 奖励厚度的换算公式：** 线性 / 分档 / 上下限均未定；**胜负两侧是否同一条曲线**亦未定。→ `20-systems/balance.md`。Source: 同上。
- **`manaLimit` 推拉的分档：** 哪些事件推高 / 压低、单次幅度（下界护栏已明确不做）。→ `20-systems/character-profile/mana.md`、`20-systems/balance.md`。
- **属性模型与战斗资源共存：** 隐藏属性（道心 / 煞气 / 寿元）与 mana / 道念 / lifeTotal 如何共存与推拉未定。→ `20-systems/services/plot-manager.md`、`20-systems/services/life-cycle-service.md`。
- **敌人 AI / intent 系统：** 意图选择逻辑、多回合行为脚本、敌人组合与出现规则均未定义。
- **敌人平衡：** 敌人各等级的道念**产出**能力（起始值已由 `baseMomentum` 给定）、随境界 / 篇章缩放未定。→ `20-systems/balance.md`。Source: 同上。
- **失败后果的其余部分：** 胜利奖励随道念差变厚已定；失败除扣 lifeTotal 外是否另有后果、与寿元 / Finale 的交互未定。
- **enemies 归属（Open question）：** 当前归 combat/；**Practice 与 Finale 均已确认使用敌人**（天劫即一个带定制卡组的 Enemy），是否应升为共享内容层待确认。Source: `10-handoffs/2026-07-24-docs-restructure-class-model.md` + `10-handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md`。

## 对应
提炼至：`.claude/knowledge/systems/adventure-event/combat.md`（待建）
