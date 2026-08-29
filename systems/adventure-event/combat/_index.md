# adventure-event / combat（AdventureEvent-Combat）

> 正式回合制战斗遭遇：**三个遭遇档位**（修炼 / 常规 / 境界突破）、回合结构、敌人 AI、**mana + 道念战斗模型**、胜 / 负结算。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

### 战斗定位

- **Combat = 五类 AdventureEvent 中唯一走战斗结算的一类，也是最高频的一类。** 玩家在此与敌人战斗并获取资源。与 ADR-0002 分类法一致。
- **战斗是回合制且易读，而非实时 / 拼 APM。** 敌人的行动**不作事前预告**——可读性由敌人回合的逐步执行反馈、敌人图鉴与战场共同承担（见下方「敌人回合的可读性」）。

### 遭遇档位 `combatTier` 三档

**修炼（Practice）、常规战斗（Standard）、境界突破 / 渡劫（Finale）不是三个 `eventType`，而是 Combat 的三个遭遇档位。** 三者**共用同一套回合循环、参战方结构（CharacterManager + EnemyManager）与结算代码**，差异只在胜负条件、回合数与奖惩——那是**参数**，不是类型。对位 Balatro 的 small / big / boss blind。

| 档位 | 对位 | 遭遇参数（初值） | 语义 |
|---|---|---|---|
| `Practice` | small blind | `TurnLimit 8` · `VictoryRule(WinMargin 0)` | 比试 / 切磋——低风险历练，**道念相等即判胜**（点到为止） |
| `Standard` | big blind | `TurnLimit 10` · `VictoryRule(WinMargin 1)`（= 道念高者胜） | 常规遭遇 |
| `Finale` | boss blind | `TurnLimit 12` · `VictoryRule(WinMargin 0)` | 篇章边界高潮：渡劫 / 突破至下一境界——**不落后即通过，落后即角色终结** |

- **`combatTier` 是必需的锚点，不是修饰。** Finale 是**篇章边界闸门**、**ADR-0004 篇章重试模型的锚点**、**道统残卷的唯一累积源与兑现点**——这三处都需要一个可机械判定的判据；靠内容 `Id` 或 location 配置去认出「这是渡劫」是反模式。
- **档位落在 `EncounterSpec` 上，与 `TurnLimit` / `VictoryRule` / `RewardPoolId` / `BaseReward` 同层**，由 future-event-service 在物化时从 `AdventureEventData` 模板代入；`EnemyData` 完全不携带——否则同一个敌人条目无法同时用于 `Practice` 与 `Standard`。落在 `EncounterSpec.Tier`，**`EventOption` 与 `PastEventEntry` 两处都不加独立字段**——走 `EventId` → 模板溯源。
  - **理由：tier 是模板常量，不是物化产物。** `EnemyData` 不携带它（同一敌人条目可同时用于 `Practice` 与 `Standard`，但**一个 AdventureEvent 条目只有一个档**）；`PlotModulation` 写不出它；`±2` 赋级带对三档一视同仁。**没有任何调制源能改变某个实例的档位** ⇒ 物化判据三条一条都不命中，快照判据把它归在「重算得出来的」那一侧。
  - **两个消费方都不需要新字段，因为它们本来就要查模板。** 选择区区分「切磋 / 遭遇 / 渡劫」与履历读出「这一步是不是渡劫」都已按 `EventId` 取显示名 / 描述 / 图标，**tier 在同一次 `ContentRegistry.Get()` 里免费拿到**；剧本条件填 `PlotCondition.EventResolved` 的 `EventId` 即可，不需要新条件类型。
  - **额外收益：Explore 的遮罩纪律少一个守点。** 壳的 `EventId` 指向 Explore 模板（模板上没有 tier），真身的 tier 在 `RevealedEventId` 的模板上，而 ViewModel 在 `IsRevealed == false` 时这两个字段一个都不读已是既定纪律。把 tier 拷成壳实例上的一格，就多出一个必须记得「遮罩态不许读」的字段。
  - **唯一的退化情形（明写）：** 某条目在新 `contentVersion` 中被删除 ⇒ 该痕迹按既定语义降级为「仅标识可读」（`PushWarning`，履历显示为未知条目，不阻断读档），此时 tier 与显示名一同读不出，**不构成额外损失**。
- **回合数是节奏旋钮。** Practice 减到 8 回合：追分窗口少 2 回合，但追分要求从「反超」降到「追平」，两侧相抵，净效果是**更简单且更快**——快正是 small blind 该有的节奏，直接服务篇章时长控制。Finale 反而**加到 12 回合而非减少**：若同时减回合会退化为**纯粹的起跑线检定**（谁 `baseMomentum` 高谁赢），玩家一整个篇章攒起来的 build 无从表达——**Finale 是 build 的检验场**，12 回合是给 build 表达自己的窗口。
- **`WinMargin` 不是 Finale 的难度旋钮。** 三档的 `WinMargin` 取值分别由各自的语义直接推出（点到为止 / 高者胜 / 不落后即通过），**没有一档把它当作可调的难度参数**。Finale 的难度校准手段见 `systems/balance.md`。
- **`Practice` 与 `Finale` 同取 `WinMargin 0` 是巧合，不是共性（承重）。** 两者出自两条互不相干的理由——前者是「点到为止，打平即通过」，后者是「非胜即败，不落后即渡过」；两档的回合数、奖惩、残卷挂载、失败后果**全部不同**。**不要把两档的 `VictoryRule` 提取成共享常量**，那会把一个数值巧合固化成一条不存在的规则。
- **推论：`CombatOutcome.Draw` 只在 `Standard` 档可达。** 另两档各自退化：`Practice` 因门槛为 0 而相等即胜，`Finale` 因二值化而非胜即败。**两端退化都是干净的**，不是缺陷，但呈现层需知晓。
- **`EnemyData.EncounterScopes` 按档位取值。** 不另立一批「切磋对手」条目：同门师兄、道友一类标 `[Practice]`，凶兽、魔修一类标 `[Standard]`，两者皆可的标 `[Practice, Standard]`。**承重论据 = 图鉴的正向增益**——共享池使玩家能**先在低风险的 Practice 档遇到并解锁某个敌人的图鉴，再在 Standard 档正式对上它**。敌人的行动既不作事前预告，图鉴就是**事前知识的主通道**，这条「先遇见、再对上」的路径因此是可读性的重要来源；另立一批则图鉴要么翻倍、要么分裂成两套，且敌人条目是本作最重的内容单元之一。见 `systems/enemies/`。
- **三档一视同仁的规则（无例外）：** 敌人赋级一律落在角色当前等级 `±2` 带内。**低风险 / 高难度全部由遭遇参数承担，不由「派个更弱 / 更强的对手」承担。**

### `Finale` 档：篇章边界的境界突破

- **篇章边界高潮，两个出口。** Finale 出现在篇章（Chapter）边界，对应修行阶梯上境界的跃迁（炼气 → 筑基 → 金丹 → 元婴）；一次轮回含三个篇章。**通过**（`d >= 0`）则角色进入新境界、**等级归位为新境界的初期**、篇章推进并落存档点（见 `systems/game-progression.md`）；**未通过**（`d < 0`）则**角色当场终结、本篇章不推进**。两个出口之外没有第三种走向。
- **勉强通过（`d` 接近 0）拿到的是最低档奖励，这由既有换算自动兑现。** 强制奖励走线性 `1:1`，`d = 0` 时加成恰为 0；可选奖励走归一化 `advantage` 三档，代入各章 `baseMomentum` 后 `d` 的低区间整体落在**险胜 `Tier.Narrow`**。**不为此另立奖励线**——「最低档」是既有两条换算规则的自然结果，新增一条线等于给一个已被满足的需求造结构。**已知代价（接受）：** `Tier.Narrow` 不为该区间独占，「刚好打平」与「小幅领先」拿到同一档可选奖励，只在强制奖励的线性量上有差。换算与门槛见 `systems/balance.md`。
- **渡劫的对手 = 天劫，天劫是一个 Enemy。** 天劫作为敌人条目存在，**带定制卡组**——这是「每个 enemy 各持有一个卡组」的直接应用。
- **天劫同受赋级约束，无等级规则上的例外。** 合法区间同样是角色当前等级 `±2`。
  - **推论 ①（自洽性验证）：** 篇章末角色处在境界巅峰（全局 13 / 17 / 21），下一境界的初期是 14 / 18 / 22 —— **`diff` 恰为 +1，稳稳落在 `±2` 带内**。「渡劫 = 突破到下一境界」这句叙事**不需要为它开任何规则口子**就能成立。
  - **推论 ②：天劫走同一条物化路径**（`EnemyData` → 充实 / 改写 → 指派），特殊性全落在**定制卡组**与**遭遇参数**上，**不落在等级上**。
- **⚠ Finale 存在二重压迫叠加**：（a）开局落后 5 / 13 / 25；（b）**失败即角色终结**——压迫的顶点不是「扣得最狠」，而是不可逆的终结。两条**都是既有定案的必然结果**：(a) 出自 `baseMomentum` 表，(b) 出自篇章闸门语义。12 回合是对 (a) 的部分补偿。**这两重都不是可调的旋钮**——(a) 动它会同时改变全部战斗的起跑线，(b) 是二值的。Finale 的难度校准手段见 `systems/balance.md`。
- **Finale 失败即 `defeated`（承重）。** `d < 0` ⇒ 角色在该事件收口的同刻终结，走 **`DefeatReason.FinaleFailed`** 这条**独立的终结通道**——它不是资源触底，故不经 `LifeTotalExhausted`，也不由终态资源表驱动，而是终态判定上的一条显式旁路（形态见 `systems/services/life-cycle-service.md`）。**渡劫的胜负就是篇章推进的闸门**：胜则突破，败则本次轮回的该角色终结。篇章边界失败之后的去向（篇章重试）由 ADR-0004 承担。
  - **失败时那笔按道念差 1:1 扣的 `lifeTotal` 照常扣**（合进该事件 `eventEnd` 的那一次 `TryApply`），只是它不再是死亡判据——`CombatResult.RemainingLifeTotal` 与结算呈现照旧有定义。
- **每个篇章只有一个 Finale，失败后不可在同一篇章内再次挑战。** 天劫是篇章的**一次性收口**，不是可反复刷的遭遇。想再渡一次这一劫，只能**重走整个篇章**（篇章重试，ch2 / ch3 另有上限 3 / 1，付费 9 / 3）。
  - **推论（承重）：残卷的可刷性由结构封死。** 每个角色每篇章**至多累积一次或掷骰一次，且二者互斥**；要多累积一次得付出 30–55 分钟重走一章的代价。**道统残卷因此不需要任何额外的冷却 / 次数上限规则**（见 `systems/player-profile/player-power/_index.md`）。
- **「渡劫身死」有一条专属的定性叙事。** 归 `systems/services/plot-manager.md` 的叙事层，与「隐藏属性跨档定性叙事」同一条落点（`ResolveOutcome` → `eventEnd`），不新增结构；**属内容层**（有稳定 `Id`、需启动期校验，故 overlay 对它照旧**只改不增**）。它**不得暗示道统残卷**——残卷对玩家彻底隐含。
- **Finale 是道统残卷的唯一累积源与唯一兑现点。** 失败累积 · 通过掷骰 · 在**该 Finale 的 eventReward 界面**即时发放，全部并入该事件 `eventEnd` 的那一次 `TryApply`——**不新增结算阶段、不新增存档点**。**失败侧不给玩家任何提示**（无文案 / 无进度条 / 无百分比）。**累积发生在角色终结的同一刻**，故它那笔账号级写入的提交顺序是承重的——顺序纪律见 `systems/services/life-cycle-service.md`。完整规则见 `systems/player-profile/player-power/_index.md`。
- **Finale 不承担经验供给（由经验模型推出）。** 天劫的 `diff = +1` 隐含一条硬约束：**角色必须在进入 Finale 之前就已升满本境界**，否则 `±2` 带会给出一个更低的天劫等级，「渡劫 = 突破到下一境界」的叙事随之破裂。**推论 ①：全部升级所需经验必须由篇章的常规事件段供满**，Finale 自身的 `ExperienceGrade` 取 `None` 或 `Minor`。**推论 ②：Finale 的出现条件 = 角色已达本境界巅峰**——不需要新机制，`eventPriority = 1` 已能表达（与 `eventCountLimit` 达成后 Travel 封锁同批的用法同构）。见 `systems/game-progression.md`。
- **Finale 以 `Priority = 1` 出场（承重）。** 角色达本境界巅峰（全局 13 / 17 / 21）的那一批，Finale 选项被 future-event-service 抬到 `1` 档，本批有效可选集随之收窄为它——篇章边界因此是一个**确定的必经节点**，与配额闸门 Travel 同形。**它不是新机制**：`eventPriority` 就是本库用来表达这件事的唯一字段；用「保证必现但 `Priority = 0`」替代需要产出侧另造一条「某条目必进本批」的机制，那等于造第二条约束轴。抬升判据与置位段伪码见 `systems/services/future-event-service.md`。
  - **代价明写（接受）：取消了「先补一补 `lifeTotal` 再渡劫」的备战窗口。** 满级那一刻其余选项即被封锁，玩家无法再插入一个回寿或构筑事件。这是在既有二重压迫（开局落后 5 / 13 / 25 · 失败即角色终结）之上叠的第三重。
  - **实测过苛时的退让位**：**内容侧编排「满级前一批必有一个带 `Recuperate` 的 Research」**，以及 `systems/balance.md` 列出的三条 Finale 难度校准手段（天劫的赋级带位置 · 天劫定制卡组的强度 · `TurnLimit`）——**而不是回退抬升**。`WinMargin` 在该档恒为 0，不是可用的退让位。
  - **与「满级后 Finale 恒进候选池、不参与类型加权」成对成立**（闸门式旁路，见 `systems/services/future-event-service.md`）：抬升需要有一个对象，抽漏一次则本批无 Finale 可抬。
- **全部 Finale 均为天劫战；不设非战斗形态的境界突破路径（承重）。** 境界突破只有一条路径——打赢天劫。
  - **推论 ①：`EncounterSpec.Enemy` 恒非空。** 不存在「无敌人的 Finale」这一分支，`TurnLimit` / `FirstSide` 因此恒有意义。
  - **推论 ②：`CombatEventResolver` 无内部分派**，三档一律走 `combat-service.RunCombatAsync`。
  - **推论 ③：危险度刻度无例外。** 三档全部有敌人 ⇒「精确标注敌人等级」这条唯一的难度刻度不需要为任何一档开口子。
  - **推论 ④：残卷的累积源与兑现点无形态分叉**（见 `systems/player-profile/player-power/_index.md`）。

### 三档与隐藏属性

- **隐藏属性对五类事件的输入与输出两侧全开，Combat 三档不例外。** 产出侧走 `HiddenStatGrade`（可选字段、不填 = 不推），输入侧走**调制通道**（Band 触发 arc → `PlotModulation`）与**结算输入通道**（数据驱动 outcome 求值读取当前值）。**输入侧全开不等于把隐藏属性接进胜负判定**——`VictoryRule` 仍是单字段，隐藏属性影响一场遭遇的路径是**拧参数**（更凶的敌人模板、更高的敌人赋级、更差的起手；`Standard` 档另可拧 `WinMargin`），不是加一条并列的判定条件。权威见 `systems/services/plot-manager.md`。
- **战斗层不读写隐藏属性。** 战斗内仅有的两种资源是 `mana` 与道念；隐藏属性**不作为战斗内的资源或结算输入**，本类事件与隐藏属性的全部交互发生在**事件层**（生成期的调制、结算期的 outcome 求值、`eventEnd` 的 `HiddenStatGrade` 推拉）。**两处相邻情形不构成反例**：`lifeSpanCost` 在择一进入时施加、属事件成本；失败时按道念差扣的是战斗外耐久 `lifeTotal`、不是隐藏属性。权威见 `systems/services/plot-manager.md`。
- **三档的默认推拉口径**（内容编排口径，逐条目可覆盖）：

  | 档位 | 道心 faith | 煞气 Bloodlust |
  |---|---|---|
  | `Practice` | 推 `Raise`，**对位低一档** | **默认不推** |
  | `Standard` | 逐条目编排（方向随条目语义） | 推 `Raise`（杀伐类条目） |
  | `Finale` | **胜利与失败都推 `Raise`** | 逐条目编排 |

  方向位是 `HiddenStatGrant` 的第三格 `HiddenStatDirection { Raise, Lower }`（沿数值轴，不含价值判断），类型定义与落点论证见 `systems/architecture.md`。

  - **`Practice` 不积煞气**：`WinMargin 0`「道念相等即判胜」正是**点到为止**的机制表达——切磋是磨砺心性，不是杀伐。「对位低一档」沿用 `ExperienceGrade` 已有的档位偏置范式（低风险 ⇒ 产出对位低一档），不是新规则。
  - **`Finale` 胜负同推道心**：渡劫这件事本身塑造道心，成败只改变塑造的内容，不改变「它发生了」。**扩大「胜」的定义不改变施加量**——两支同施一份，判定线挪到哪里都不影响这一条。**推拉不套用 `FailureRatio`**，胜负同施一份 `HiddenStatGrade`（理由见 `systems/adventure-event/common-properties.md`）。
  - **Finale 不消耗隐藏属性**：`selectCost` 照定价表取 `Combat × Finale` 那一格，不额外扣道心 / 煞气——成本侧只放可如实计价的量，而隐藏量玩家永远算不出那一格。
  - 映射值留待内容扩充后的统计校准，见 `systems/balance.md`。

### 战斗模型 = mana（出牌）+ 道念（计分与胜负）

- **胜负 = 道念高者胜。** 战斗内的胜负标尺是**道念（momentum）**——计分用的胜利点数，双方各持一份，**高者胜**。**战斗过程中 lifeTotal 不参与**（既不消耗也不读取）；失败时角色在**收口时刻**按「角色道念 − 敌人道念」的差值损失 lifeTotal。完整模型见 `systems/scoring.md`；lifeTotal 的战斗外语义见 `systems/character-profile/life-total.md`。
- **一场 `Standard` 档战斗 = 固定 10 个回合。** 双方各 5 个回合、交替，**打满即止**再比道念；不设提前终止（无「先到某值即胜」，也不以卡组耗尽终止）。**回合数固定，且每个回合的步骤固定（三步，见下）**，故**「每场时长可预测」成立**——它直接服务篇章时长控制，无须为交互次数另加护栏。
- **道念的规则骨架：** 由**卡牌**产出、**可互相削减**、**下限为 0**；**起始道念 = `baseMomentum`（按自身全局等级）**，故**等级差直接变成开局的起跑线差**——这与「敌人等级精确标注」形成闭环：看到等级即看到起跑线。表与系数归 `systems/balance.md`，完整模型见 `systems/scoring.md`。
- **胜利侧也读道念差（换算 = 两条支路）。** 赢多少也算数：**道念差越大，奖励越厚**（碾压 > 险胜）。道念差因此是一个双向刻度——胜侧给奖励厚度，负侧扣 lifeTotal。**换算分两条支路**：**强制奖励（可数量）走线性 `1:1 × 可调单价`**（「1 点道念差 = 1 个 `rewardPerMomentum` 单位」，单价逐篇章下调）；**可选奖励（品质）走归一化 `advantage` 三档**（险胜 / 优胜 / 碾压，只改候选池的稀有度权重、不改数量）。公式、单价表与门槛见 `systems/balance.md`。
- **负侧换算 = 1:1。** 失败时 `lifeTotal -= (敌人道念 − 角色道念)`——道念差就是损失量，中间不隔系数。`momentum` 为 **`>= 0` 的 Integer**。
- **回合数与胜负判据是遭遇参数，落在 `EncounterSpec` 上**（不落 `EnemyData`），三档取值见上方档位表。**推论：10 回合与「道念高者胜」是 `Standard` 这一档的默认值，不是全局常量**。借的是 blind 的难度分档结构，不是它的计分结构。取值与理由见 `systems/balance.md`。
- **胜负判据参数化为一个数，不做「可替换的判定对象」。** `VictoryRule(int WinMargin)`：`d = 角色道念 − 敌人道念`；**`d >= WinMargin` → `Victory`；`d == WinMargin − 1` 且 `WinMargin >= 1` → `Draw`；`d < WinMargin − 1` → `Defeat`**。代入已陈述的全部需求（`Standard` `1`、`Practice`「打平即通过」`0`、`Finale`「不落后即通过」`0`）已完全覆盖——**无需策略枚举、无需分发**。**`WinMargin == 0` 的两档因此二值化**（`Draw` 分支的条件恒不成立），Finale 侧 `d < 0` 的 `Defeat` 即角色终结。
- **卡牌结算 = stack，但不含交互与优先权（承重）。** 借入 MTG 的 **stack**（先入栈、后进先出、「打出」与「结算」分两个时刻）；**但 instant / 栈非空时出牌与优先权传递整体不借**——理由是它们**拉长时长、决策点过多、复杂度高而深度收益小**。**推论：「双方各 5 个回合、我打完换你打」的简单交替成立**，且**「定长 = 每场时长可预测」成立**。规则细则见 `systems/character-profile/deck/`。
- **回合结构 = 三步。** **开始阶段**（回合归属方 mana 恢复至 `manaLimit` → 触发「回合开始时」→ 抽牌）→ **行动阶段**（唯一出牌阶段，只有归属方出牌）→ **结束阶段**（触发「回合结束时」→ 清理回合内的非永久条目）。**中文侧统一以「阶段」收尾、英文侧统一以 `step` 收尾**（`start step` / `action step` / `end step`；**不借 `main phase` 一词**）。**出牌时机是唯一的、且是全局规则**：自己回合的行动阶段、栈为空时——**`sorcery speed` 一词亦不借**。**三步是回合归属方的流程，双方不同时走**：每一方在自己的回合内各走一套完整的三步，「回合开始 / 回合结束」是有归属方的时点，不是双方同步的公共时刻。**不设战斗步骤、不设双主阶段**——**推论：没有 MTG 式的攻击阶段**，道念的产出与卡牌侧削减全部经由行动阶段打出的卡牌（另一条独立通道是开始阶段抽牌触发的疲劳，见下）。完整结构与步内顺序的意义见 `systems/services/combat-service.md`。
- **先后手：剧情可指定，否则随机。** 先手方由 **`EncounterSpec.FirstSide`**（可空）承载，由 future-event-service 物化 eventOption 时写入（剧情意图经 plot-manager 调制）；**未指定时由 combat 子流掷**，同一 seed 复现同一个先后手。与「不设先后手抽牌差」并行不悖——后者说不做补偿，前者说谁先动。
- **抽牌堆不重洗，抽空即疲劳（承重）。** 弃牌堆不回流；**抽牌堆为空后每尝试抽一张牌，抽牌方 −1 道念**（下限 0 照常截断）。**这是道念的第二条削减通道**，也让**卡组规模成为真实的构筑 / 编排取舍**（两侧皆不设规模硬限）。**卡组耗尽仍不终止战斗**——定长 10 回合不变，只是从此每回合稳定失血。
- **起始手牌 4、不设 mulligan。** 起始手牌一次发到位，没有换牌 / 调度窗口；**起始 mana = `manaLimit`**（满值开局，首回合不设例外）。数值（起手 4 / 每回合抽 2 / 手牌上限 7）见 `systems/balance.md`。

- **战场（battlefield）= 战斗的公共区（承重）。** 场上的**全部准确数据**（正在生效的卡牌、持续状态、等待中的触发器）落在 battlefield 上，由 combat-service 的 **BattlefieldManager** 持有；**栈**另由 **StackManager** 持有。**二者是两个区**：栈 = 等待结算的队列，战场 = 已结算并正在生效的东西——结算路径 = **打出 → 入栈 → LIFO 弹出结算 → 效果施加 →（若持续）落到战场**。**推论 ①：至今空白的「回合内效果 / 状态系统」有了承载结构**——状态即**战场上带生命周期标记的条目**，结束阶段清理标记为回合内的那些。**推论 ②：结算须以战场为输入**（场上的持续状态会改写本回合出牌的最终结果）。**推论 ③：战场必须进入呈现层**（栈之外的第二个区）。
- **触发式效果的载体开放，不专属卡牌。** 牌上的触发器、**场上的持续状态**、**CharacterPower（神通）** 都可能承载，**清单可再增**；「谁在监听哪个时点」的注册面坐在战场上，命中后由 StackManager 压栈。**推论：轮回级能力必须能被战斗内读到**——参战方组装时要把角色持有的神通注册进战场。
- **道念下限 0 在每一次结算时截断。** 溢出的削减量不结转，故 **LIFO 顺序对最终结果有实际影响**（削减与产出交错时）。见 `systems/scoring.md`。
- **卡牌类型五分 + 异能三分 + 永久物（承重）。** 五类 = **法术 `Sorcery`** / **阵法 `Enchantment`** / **法宝·古宝 `Item`** / **神通·法则 `Power`** / **业障 `Affliction`**；异能三分 = **静止式 / 启动式 / 触发式**（与「载体开放」正交：载体说「挂在谁身上」，类型说「怎么生效」）；**永久物 = 战场条目的子集**（阵法 / `Power`），**永不被结束阶段清理**，且**不区分实体 / 非实体**。**推论：战斗内的来源区从一个变成三个**——卡组（受抽牌运）· 本场可用道具（不受抽牌运，需玩家动作）· 开局入场的 `Power`（不受抽牌运，无需动作）。规则细则见 `systems/character-profile/deck/`。
- **满手时抽牌抽不进。** 牌留在抽牌堆、本次抽牌无事发生；「加入手牌」类效果同理落空。**手牌上限因此是纯上界**，不产生弃牌堆流量。**上限收紧为 7 后它是一条会真实咬合的紧约束**：起手 4 + 每回合抽 2 ⇒ 第 2 回合即撞上限，只有每回合稳定出满 2 张才不损失牌。见 `systems/character-profile/deck/`、`systems/balance.md`。

### 结算产物

- **胜：** `baseReward` + 按道念差加厚；**平：** 只发 `baseReward`；**负：** `baseReward`，**少数事件另夹带负向条目**（额外惩罚**包在 reward 里**，不另立结构——与 `ProfileChangeSpec` 的带符号约定自洽）。

- **`Practice` / `Standard` 两档失败不另加规则层的额外后果（承重）。** 失败的代价**已经有六条**，只是它们分散在五份文档里、从不并排出现，故结算表看起来只有 `lifeTotal` 一列。**六条代价（本表只并列既有定案，不含新增）：**

  | # | 代价 | 量级 / 形态 | 权威 |
  |---|---|---|---|
  | ① | **扣 `lifeTotal`** | `= 敌人道念 − 角色道念`，1:1 无截断；炼气基线仅 10，最坏开局落差 9 ⇒ 一次惨败几乎打穿整条耐久线 | `systems/scoring.md` · `systems/character-profile/life-total.md` |
  | ② | **已支付的 `lifeSpanCost` 打了水漂** | 无条件施加、支付先于结算、不因失败退还；寿元归 0 即 `defeated` | `systems/adventure-event/common-properties.md` |
  | ③ | **占掉一个 `eventCountLimit` 名额** | 纯计数、不分胜负；名额有限 ⇒ 它挤掉的是另一个本可选的事件 | `systems/game-progression.md` |
  | ④ | **经验按 `FailureRatio` 折半** | 50%、向下取整、下限 1；供需比仅 1.15–1.20 ⇒ 反复失败真实导致卡级，而卡级的终点是寿元耗尽而等级未满 → `defeated` | `systems/game-progression.md` |
  | ⑤ | **失去胜利侧的全部奖励厚度** | 线性 `1:1 × rewardPerMomentum` 加厚归零、`advantage` 三档不适用；失败只发 `baseReward` | `systems/scoring.md` · `systems/balance.md` |
  | ⑥ | **隐藏属性照推，且推的是同一份量** | 胜负同施一份 `HiddenStatGrade`、不套 `FailureRatio` ⇒ 输掉一场杀伐类 `Standard` 照样积满煞气 | `systems/adventure-event/common-properties.md` |

  **不另加的四条依据（各自独立成立）：**
  1. **`FailureRatio` 取 50% 而非更低，其论证前提逐字就是「失败已经付了 `lifeTotal` 的硬代价」。** 再加一层后果等于抽掉那次论证的前提——若失败代价不够重，该调的是 `FailureRatio`，不是在旁边并联一条新惩罚。两处不能各调各的。
  2. **代价 ② ③ ④ 隐形但真实**（寿元在 Band 0 / Band 1 不显示数字、配额无专门呈现、经验折半玩家算不出）。**这是呈现问题，不是机制问题**——用加惩罚去解决呈现不足，是给一个已被满足的需求造结构，与 Finale「勉强通过不另立奖励线」是同一条克制。
  3. **失败已是一条通向死亡的连续曲线。** ①（耐久触底 → `LifeTotalExhausted`）与 ④（卡级 → 寿元耗尽）是两条独立的终结路径，一次失败同时把角色往两条线上推。再加第三条压力源改变的不是「失败有代价」，而是**容错量**——而容错量的旋钮是 `baseMomentum` 表 / 赋级带 / `lifeSpanCost` 定价表 / `FailureRatio`，不是新增一条后果。
  4. **它撞休闲定位与「炼气可无限重试」的手感。** `Practice` 被定位为低风险历练，加重惩罚是正面撞击；给 `Standard` 单独加则两档失去共用同一套结算代码的前提之一（三档共用结算，差异只在 `EncounterSpec` 的参数）。

  - **两档的差异化不需要为失败侧另立，三个既有旋钮已自动兑现：** `TurnLimit` 8 / 10 ⇒ 失败时的道念差期望更小，代价 ① 自动更轻；`WinMargin` 0 / 1 ⇒ 判负门槛更靠后，同一场对局在 `Practice` 更可能落在「平即胜」；`ExperienceGrade` 档位偏置 ⇒ 折半后 `Practice` 本就更薄。再加定价表按 `combatTier` 分格，代价 ② 也有现成的分档位。**`Practice` 的「低风险」四条全部由既有参数承担**，这正是「低风险 / 高难度全部由遭遇参数承担」的直接兑现。
  - **内容编排口径：`Practice` 条目默认不挂负向 `OnFailureRules`。** 这是编排偏好，**不设加载期校验**——`OnFailureRules` 本就是内容层的例外通道，为一个 tier 关死它是把编排偏好升格成结构约束，量级不匹配；有故事分量的切磋因此仍有书写位。`Standard` 侧的频次口径见 `systems/balance.md`。
  - **`Practice` 的「点到为止」与「输得够惨仍可能终结一个耐久见底的角色」之间的张力交给叙事层**，不为它松动 1:1（松动的代价是通用刻度分档）。失败的定性文案取「力竭负伤 / 自愧不如」一类，落 `systems/services/plot-manager.md` 的既有叙事层，零新增结构。
- **奖励分两类：强制自动计入（例：经验）/ 可选由玩家择一（参照 Slay the Spire 的战后奖励面板）。** **推论：战斗后需要一个奖励选择步骤**，且它在战斗流程内——**奖励计算与发放归 combat-service**，写入仍由 life-cycle-service 在 `eventEnd` 一次施加。
- **Combat 条目允许声明事件级产出（`OutcomeRule` 的 `GrantFromPool` 等），它与战利品是两条通道（编排须知）。** 战利品出自 `CombatResult.Spoils`、记 `Source.CombatReward`、取值来自 `EncounterSpec.BaseReward` / `RewardPoolId`；事件级产出出自条目模板的产出格、记 `Source.EventOutcome`——**分野判据仍是「谁组装出这条 element」**，两者并存于同一次结算是合规的。**代价明写：** 玩家会看到同一场战斗掉了两批东西，而战后奖励的厚度轴**不覆盖后一批**。故内容作者为 Combat 条目编排事件级产出时须自行把它算进该条目的总产出，不要当作免费附加。字段面与校验见 `systems/adventure-event/common-properties.md`。
- **不是 StS 纯 HP，也不是 Balatro 的 chips × mult。** 道念是**双方对抗的相对量**（比谁高），不是对抗静态阈值的绝对量——与「敌人也出牌、双方对称」的参战方模型一致。
- **mana = 无曲线 · 每回合恢复至 `manaLimit`。** 不采用 mana 曲线（既非 Hearthstone 式每回合 +1 上限，也非 MTG 式打地递增）：战斗内**每回合的开始阶段、回合归属方的 mana 自动恢复到 `manaLimit`**（恢复的是本回合归属方的 mana——非归属方无法出牌，其 mana 在对手回合无用途）；`manaLimit` 的成长有两条来源、同走 `CostKey.ManaLimit` 的增量语义：**由 AdventureEvent 的 cost / reward 推拉**（可升可降，主通道），外加**每次大境界提升 `+1`**（在篇章边界施加一次，常量 `RealmBreakthroughManaBonus`）；**不设下界护栏**（下降极罕见）。语义与三章末推算见 `systems/character-profile/mana.md`。**炼气期标准基线（起始满值）：** lifeTotal = **10**、mana = **5/5**。

### 危险度 = 精确标注敌人等级

- **不做模糊的危险度档位。** 「同阶 / 略高 / 越阶 / 无从揣度」一类模糊标签**否决**；`combatTier` 三档一律在 **eventOptions 上精确标注敌人的等级**。
- **推论 ①（承重）：看到等级即看到起跑线。** 等级 → `baseMomentum` → 开局领先 / 落后量，故精确标注的等级**就是这场遭遇的难度刻度**——这是等级精确可见的唯一承重理由，也是它优于任何主观危险度词汇之处。见 `ux/combat-ux.md`、`systems/balance.md`。
- **推论 ②：越级挑战成为可主动选择的风险 / 回报维度。** 信息可见，抉择才成立：玩家可以明知山有虎地去打高几级的敌人。

### 敌人回合的可读性（承重）

- **敌人的行动不作任何事前预告（承重）。** 本作**不设任何形式的意图预告**——不设揭示档位、不设行动类别标注与内容侧的对应必填字段、不生成回合级行动描述、不设「花代价换情报」的探查通道。可读性由**事中呈现**与**事前知识**两条通道分工承担（清单见下）。
  - **不要靠加一层预告去补可读性。** 那样一层是全库最重的一处机制 ↔ 呈现耦合：内容侧每个效果原语多一个必填字段、一套档位规则、一整套「预估 vs 实际」的解释装置、竖屏约 8% 的高度。而它能给的信息又被本作既有设计自我削减到接近于无——ch2 · ch3 约五分之二是同阶遭遇、`diff = 0` 是分布众数、教学职能另有承担者。**成本要完整支付，信息却所剩无几。**
- **玩家可读的六条通道（承重 · 完整信息面清单）：**

  | 通道 | 给什么 | 时点 |
  |---|---|---|
  | **敌人回合的逐步执行反馈**（飘字 + 战报 `combatLog`） | 敌人**正在**做什么，逐张、逐次结算可见 | 事中（**唯一的动态情报通道**） |
  | **敌人图鉴** | 这个敌人**会**做哪些事 | 事前 |
  | **战场（battlefield）** | 场上正在生效的持续状态、永久物、阵法 | 全程 |
  | **埋伏计数** | 对手有几张埋伏（不给内容） | 全程 |
  | **敌人精确等级 → `baseMomentum`** | 开局起跑线差 = 这场有多难 | 事前 |
  | **道念对比 + 剩余回合数** | 「我落后 8 点、还剩 2 个回合」这本可算的账 | 全程 |

- **已知代价（明写接受）：** 本作没有交互与优先权，故敌人回合对玩家而言是**信息与交互双零**的一段观看。**与 MTG 的差别正在此处**——MTG 里「打出的牌就是足够信息」成立的前提是玩家能响应，本作没有响应窗口。这条代价由上表六条通道承接，并由下一条把逐步反馈升为硬要求。
- **敌人回合的逐步执行反馈是硬要求（承重）。** **敌人回合是玩家获取动态情报的唯一时刻**，看不清就完全不可读。飘字与**战报（`combatLog`）**两者都要、战报的收起态在**双方回合都常驻有内容**（固定预留高度，避免手牌区跳位干扰拖拽出牌）、演出只能加速不能跳过——形态与节奏参数见 `ux/combat-ux.md`。
- **EnemyManager 不受「回合级一次性规划」约束。** AI 逐张决策，每次执行到栈清空后重新组装候选集——栈结算会改变局面，一次性规划出的后续动作在执行到时可能已不合法。**这不引入交互**——敌人回合在玩家回合之后，玩家在其中没有输入窗口。见 `systems/services/combat-service.md`。
- **AI 由两层构成：通用兜底 + 敌人模板级定制策略。** 兜底是任何套牌都能跑的保底出牌逻辑（实现在 EnemyManager 内），定制策略随敌人模板走、可空且空即回落兜底，其内容是一组权重覆写而非代码。**战斗内因此不需要认识功法**——参战方组装时卡组已展开为卡牌集合，策略是敌人模板的属性而非卡组来源的属性。**AI 决策是「局面 + `combat` 子流」的纯函数**，输入面限对称可见信息（埋伏与对手手牌只给计数），且**全流程零随机、零记忆**，故敌人回合仍是一段可确定性重放的区间。字段面归 `systems/enemies/`，算法与确定性约束见 `systems/services/combat-service.md`。
- **AI 偏向打出 `KeyCardIds` 中的牌，这是图鉴可读性的一条承重支撑。** `KeyCardIds` 既是图鉴「关键卡牌」词条的数据源，也是 AI 评分的一项加分因子 ⇒ 图鉴所述与玩家实际观察到的行为对齐。图鉴是**唯一的事前通道**，它的价值建立在「这个敌人会怎么打是可学习的」之上；**AI 零随机**同样服务这一条——给 AI 掷骰是在唯一的事前通道上再打一个折扣。代价是重复遭遇同一敌人时行为完全一致，这是被接受的取向：让同一批敌人打法各异靠多写几条定制策略，而不是靠掷骰。
- **敌人图鉴给静态知识**（这个敌人会做哪些事），**不给动态情报**（它这回合做什么）。**这条边界的理由是「事前知识 / 事中情报」的分工**——图鉴答「它会做什么」，敌人回合的逐步反馈答「它这回合做了什么」。**一次遭遇即解锁全部词条文案**（人物背景 / 功法简介 / 运作方式 / 特点与弱点 / 样本卡组的关键卡牌）。**图鉴是事前知识的主通道**，其慷慨度是否该上调见待决问题。见 `systems/player-profile/codex/enemy-codex.md`。
- **敌人同样持有 item 与 power（来自 `EnemyData` 的两个持有列表），道具是行动的一种。** 它们照常在敌人回合被使用并逐步呈现。**埋伏的信息是双向对称的**——AI 与玩家读到的都是计数而非条目内容，AI 可据此变得谨慎（例：留一张牌不打）但无法针对性规避，故**埋伏的威慑力与实际效果是两件事**。

### 敌人 → `systems/enemies/`

**敌人已升为与 `adventure-event` 平级的系统**（`combatTier` 三档共享同一批条目）。`EnemyData` 的字段与语义、模板 ↔ 实例二元、样本卡组、item / power 持有列表、`EncounterScopes` 与 `PoolScope`、赋级带的接受面、埋伏规则**全部归 `systems/enemies/`**。本文件只保留与战斗规则直接接壤的三条：

- **敌人是对称的参战方。** 敌人也持道念、也出牌、各持一个 `DeckModule`，**敌人侧的战斗内量与玩家侧对称**——同样以道念高低论胜负，不设独立的血量池。参战方结构见 `systems/services/combat-service.md` 的 EnemyManager / CharacterManager。
- **敌人的战斗强度以 `baseMomentum` 为主刻度。** 等级 → 起始道念 → 开局领先量，这是越级压迫感的直接来源；**卡组保持强度中立、不叠第二条强度曲线**。**AI 的定制策略同样只表达打法风格，不作强度 / 难度旋钮**——难度仍只由 `baseMomentum` 与内容编排承担。
- **敌人等级是物化产物**，落在角色等级 `±2` 带内（三章统一），随物化产物落进 `EventOption` 精确标注给玩家。**其唯一消费点是 `baseMomentum` 起跑线**（`diff` 没有第二个消费者，见 `systems/balance.md` 的待决问题）。见 `systems/services/future-event-service.md`、`systems/balance.md`。

Source: `handoffs/2026-07-13.md` · `handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md` · `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md` · `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md` · `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md` · `handoffs/2026-08-02-momentum-conversion-reward-structure-and-mtg-stack.md` · `handoffs/2026-08-02b-stack-without-interaction-and-three-step-turn.md` · `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md` · `handoffs/2026-08-04b-mtg-loanwords-card-types-and-intent-snapshot.md` · `handoffs/2026-08-05-level-band-stack-save-and-token-free-deck.md` · `handoffs/2026-08-06d-combat-open-questions-mass-closure.md` · `handoffs/2026-08-09b-player-power-fragment-finale-bound-drop-chance.md` · `handoffs/2026-08-10b-grant-source-and-fragment-source-scoping.md` · `handoffs/2026-08-11c-combat-turn-flow-fatigue-and-card-type-reduction.md` · `handoffs/2026-08-15c-event-type-collapse-and-batch-shape.md` · `handoffs/2026-08-15d-intent-removal-lifespan-cost-visibility-and-design-audit.md` · `handoffs/2026-08-16-design-audit-adjudication-and-hand-limit.md` · `handoffs/2026-08-17e-finale-combat-only-and-hidden-stat-io.md` · `handoffs/2026-08-22-finale-failure-is-death.md` · `handoffs/2026-08-22-event-outcome-spec-fields.md` · `handoffs/2026-08-22-priority-elevation-criterion.md` · `handoffs/2026-08-22-combat-defeat-consequences.md` · `handoffs/2026-08-25-enemy-deck-from-techniques-and-ai.md` · `handoffs/2026-08-25-combat-presentation-and-action-result.md` · `handoffs/2026-08-23g-hidden-stat-combat-boundary-event-backdrop-and-itemized-rewards.md` · `handoffs/2026-08-26c-enemy-ai-strategy-shape.md`

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- **战斗模型 = mana（出牌）+ 道念（计分与胜负）；胜负 = 道念高者胜；失败按道念差扣 lifeTotal**。
- **战斗固定 10 回合（双方各 5）；道念由卡牌产出、可互削、下限 0、起始 = `baseMomentum`；胜利侧按道念差给奖励厚度**。
- **敌人静态数据 = `EnemyData`；敌人等级为 future-event-service 的物化产物**。
- **敌人的行动不作任何事前预告**（不设揭示档位 / 行动类别标注 / 回合级描述 / 探查通道）；**敌人回合的可读性由逐步执行反馈 + 敌人图鉴 + 战场承担，逐步反馈是硬要求**。
- **mana 无曲线 · 每回合恢复至 `manaLimit`（由事件推拉，另在每次大境界提升 `+1`）、炼气基线 lifeTotal 10 · mana 5/5**。
- **危险度 = eventOptions 上精确标注敌人等级（否决模糊档位）；承重理由 = 看到等级即看到起跑线**。
- **引入 battlefield（战场）及 BattlefieldManager / StackManager；触发载体开放；道念下限 0 逐次结算截断；满手抽不进**。
- **卡牌类型五分 + 异能三分 + 永久物 + 次类型体系；触发条件可跨归属方（埋伏成立）；敌人同样持有 item 与 power**。
- **敌人赋级的合法区间 = 相对角色等级的 `±2` 带**（三章统一，`combatTier` 三档一视同仁，`±2` 为无例外的硬规则，**不按境界给绝对上界**）；**埋伏进入敌人卡池**。
- **遭遇参数（回合数 / `VictoryRule`）落 `EncounterSpec`；enemies 归 `systems/enemies/`**。
- **`VictoryRule` 是单字段 `(int WinMargin)`、`CombatOutcome` 是三值 `{ Victory, Draw, Defeat }`**——**不加 `DrawCountsAsLoss`（三档恒 `false`）、不加 `Fled`（无任何机制支撑逃跑）**，那两个都是没有消费者的死结构。`Draw` 本身仍有真实消费者（`Standard`），不是死结构。
- **Combat 为五类分类法之一；Practice / Standard / Finale 收为 `combatTier` 三档，不各占一个 `eventType`** → `decisions/ADR-0002-adventure-event-taxonomy.md`。
- **三档遭遇参数初值**（`Practice` 8 / `WinMargin 0`；`Standard` 10 / 高者胜；`Finale` 12 / `WinMargin 0`）；**`EncounterScopes` 按档位取值**。
- **天劫 = 带定制卡组的 Enemy，同受 `±2` 赋级带约束，无等级例外**。
- **每篇章一个 Finale、败后不可重战；Finale 失败即角色终结（`DefeatReason.FinaleFailed`）、本篇章不推进；Finale 是道统残卷的唯一累积源与兑现点**。
- **Finale 以 `eventPriority = 1` 出场**（满级那一批有效可选集收窄为它），代价是取消备战窗口；退让位走内容编排与 `systems/balance.md` 的三条难度校准手段，不回退抬升。
- **全部 Finale 均为天劫战，不设非战斗形态的境界突破路径**（`EncounterSpec.Enemy` 恒非空、`CombatEventResolver` 无内部分派）。
- **隐藏属性对五类事件输入与输出两侧全开；`Practice` 推道心不推煞气、`Finale` 胜负同推道心，推拉不套 `FailureRatio`**。
- **平局 = `Standard` 档打满 10 回合道念相等 → 只发基础奖励、不扣 `lifeTotal`（`CombatOutcome.Draw`）**；`Practice` 与 `Finale` 两档 `WinMargin = 0` 使 `Draw` 在这两档**永不可达**（一端相等即胜、一端非胜即败）——两端退化都干净，呈现层需知晓。
- **`Practice` / `Standard` 失败不另加规则层的额外后果**（六条既有代价已足；`Practice` 默认不挂负向 `OnFailureRules` 是软口径、不设校验；`lifeTotal` 扣减维持 1:1 三档统一，「点到为止」的张力交叙事层）。
- **敌人 AI 两层结构 = 通用兜底（实现在 EnemyManager 内）+ 挂 `EnemyData` 的敌人模板级定制策略**（可空、空即回落兜底，经 `EnemyId` 读模板，`EnemyInstance` 不加字段）；**定制策略只表达打法风格，不作强度 / 难度旋钮**；**AI 决策是「局面 + `combat` 子流」的纯函数，输入面限对称可见信息**。
- **敌人图鉴的慷慨度维持「关键卡 3 张、不给样本卡组完整列表」**，上调走「加厚 ③④ 写作 → `KeyCardIds` 上界放宽至 5 → 才考虑全表」的退让阶梯，不重开信息分层裁决 → `systems/player-profile/codex/enemy-codex.md`。

Source: `handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md` · `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md` · `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md` · `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md` · `handoffs/2026-08-02-momentum-conversion-reward-structure-and-mtg-stack.md` · `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md` · `handoffs/2026-08-04b-mtg-loanwords-card-types-and-intent-snapshot.md` · `handoffs/2026-08-05-level-band-stack-save-and-token-free-deck.md` · `handoffs/2026-08-06d-combat-open-questions-mass-closure.md` · `handoffs/2026-08-09b-player-power-fragment-finale-bound-drop-chance.md` · `handoffs/2026-08-15c-event-type-collapse-and-batch-shape.md` · `handoffs/2026-08-15d-intent-removal-lifespan-cost-visibility-and-design-audit.md` · `handoffs/2026-08-22-finale-failure-is-death.md` · `handoffs/2026-08-22-combat-defeat-consequences.md`

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **卡牌产 / 削道念的量纲基准：** 一张牌该产多少、10 回合内一方总产出相对起始值的倍数——**它决定越级追分是否可能**；是否存在道念相关的状态与倍率亦未定。**留待内容扩充后的统计校准。** → `systems/character-profile/deck/`、`systems/balance.md`。
- **敌人平衡：** 敌人各等级的道念**产出**能力（起始值已由 `baseMomentum` 给定）、随境界 / 篇章缩放未定。→ `systems/balance.md`。
- **三档的奖励厚薄：** 回合数与胜负判据已定（`Finale` 12 回合、三档 `WinMargin` 0 / 1 / 0）；**`BaseReward` 与 `RewardPoolId` 的取值**（`Practice` 是否相应变薄、`Finale` 加厚多少）未定，留待**内容扩充后的统计校准**。→ `systems/balance.md`。
- **叙事一致性的编写口径：** 标为 `[Practice, Standard]` 的敌人条目，其图鉴与台词须同时说得通「切磋」与「厮杀」两种语境——具体口径归 `systems/player-profile/codex/enemy-codex.md` 的写作规格。
- **三档各推哪一档 `HiddenStatGrade`（内容编排）：** 三档的默认档位 + 方向口径与「胜负同施、不套 `FailureRatio`」已定（见上方「三档与隐藏属性」）；**逐条目的推拉编排与映射值**仍随「隐藏属性的增减触发」那条待答项与**内容扩充后的统计校准**一并定。→ `systems/services/plot-manager.md`、`systems/balance.md`。

## 对应
提炼至：`.claude/knowledge/systems/adventure-event/combat.md`（待建）
