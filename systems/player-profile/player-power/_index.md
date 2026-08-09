# player-power

> **法则 / PlayerPower** —— 账号级 always-available 能力，带开关（默认开启）；通过事件触发器的被动修正 / relic-joker，含 RelicData 定义。
> **中文定名 = 法则**（08-03 定，取代「玩家能力」）；轮回级的对应物是 **神通 / CharacterPower**（`../../character-profile/power/`）。**中文名不表达层级** —— 账号级 ↔ 轮回级的对称只在英文标识符上成立。Source: `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md`。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **PlayerPower = 账号级 always-available 能力，带开关。** always-available，带**开关（默认开启）**；**通常全局、不与角色绑定**；可为 **QoL** 或**影响公平性的一定加强**（需衡量平衡）。由 PlayerProfile 持有（`List<PlayerPower>`），跨轮回持久。**获取越多后续越易，但 AdventureEvent 过程中也可能失去**已获取的 PlayerPower。Source: `handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。
- **定位 = 轻度提升（light improvement）。** 承认它影响平衡，但因**本作无 PvP、纯 PvE**，让 power 带来一定强度是**可容忍的**，并**打开更大的设计空间**去做有趣的 power。Source: `handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。
- **被动修正 = 挂接到事件触发器。** PlayerPower 通过响应游戏事件（触发器）施加被动修正（relic / joker 语义）。Source: `handoffs/2026-07-24-docs-restructure-class-model.md`。
- **RelicData 定义。** relic / joker 的**设计意图、触发条件与效果**及其数据定义（RelicData）归入本处。Source: `handoffs/2026-07-24-docs-restructure-class-model.md`。

- **开关落为 `status` 字段（启用 / 禁用）。** 「带开关」不只是 UX 描述，而是 PlayerPower 类上的持久字段；它与「拥有 / 失去」是**两个正交维度**（失去 = 移出 `List<PlayerPower>`，而非置禁用）。Source: `handoffs/2026-07-25b-event-cost-fields-capability-flags-and-service-hierarchy.md`。
- **道统残卷 / `PlayerPowerFragment` = 焊在 Finale 上的 PlayerPower 掉落概率（已定案 · 08-09b · 元进程的失败侧产出 · 承重）。** 失败不再是零推进：
  - **不发放账号级货币。** 累积的是**一个递增的概率**——获得新 PlayerPower 的掉落概率；**掷中并授予后即重置**。
  - **为何不是货币：** 可支配的货币会引入**第二套账号级经济**（获取 → 囤积 → 兑换 → 定价），而本作的元进程只想要「失败也在推进」这一条效果。递增概率给了同样的推进感，却不新增任何经济系统。因此它是一个**账号级的隐含状态**（一个概率值 + 重置规则），不是玩家可查看余额、可花费的资源。
  - **三个时刻全部落在 Finale（天劫）上：** **累积 = Finale 战斗失败**（不论是否因此 `defeated`）· **掷骰 = Finale 战斗胜利**（一次胜利掷一次）· **发放 = 该 Finale 的 eventReward 界面**，掷中的法则与战斗奖励一并呈现。**其余一切失败**——普通 Combat / Practice 失败、寿元耗尽、`lifeTotal` 耗尽、主动弃置——**一律不累积**（这是对 08-01「失败侧有产出」的一次有意收窄，见 `systems/scoring.md`）。**「失败但存活」的 1% 分支照常累积、但不掷骰不发放**——发放只认胜利。
  - **结构性简化（四条）：** ① **不需要跨轮回的待发放字段**（掷骰与发放同刻同事务，`PendingPowerId` 一类中间态不存在）；② **整条机制落在既有 Finale 结算链路上**——`CombatEventResolver` → `CombatResult.Spoils` → `eventEnd` 的那一次 `TryApply`，**授予法则成为 Spoils 的一个 element**，不新增结算阶段、不新增存档点；③ **累积天然有界**——「一篇章一个 Finale + 败后不可重战」⇒ 每个角色每篇章至多累积一次**或**掷骰一次且二者互斥，**残卷不需要任何额外防刷规则**；④ **叙事自洽**——在天劫下失败积攒，在渡劫成功那一刻兑现。
  - **上限 / 基础概率 / 适格篇章按已拥有法则数 `x` 分档**（`x` = `List<PlayerPower>` 元素数；`status` 开关与「本轮回禁用」**不影响计数**——那是生效维度不是持有维度）。**篇章闸门逐档累加地移除**（`x ≥ 5` 移除 ch1、`x ≥ 12` 再移除 ch2），**不是**「限定到某一章」。**承重的合一：适格 Finale ⟺ 该档增量 > 0 的篇章**——两张表是同一条闸门的两面，实现侧只需一张按 `(x, chapter)` 索引的表，`gain == 0` 即该篇章在该档整体退出残卷系统。这条一致性使「在某章输了却只能在别章兑现」的错位不可能出现。分档表见 `systems/balance.md`。
  - **首胜规则优先于闸门：** 某篇章的**首次 Finale 胜利**一律硬置 **100%**，即使该篇章在当前档已不适格。三次首胜是账号生命周期里三份确定的里程碑，被闸门吃掉会造成「第一次渡劫成功却空手」。（`x = 0` 因此不需要单独档位。）
  - **全局前置：** 仅当「尚未拥有的法则数 > 0」时才累积、才掷骰、才发放；池已取尽 → 整条线**静默停摆**，概率停在原值。
  - **生效概率 = `clamp(Accumulated, Base(x), Cap(x))`；发放后重置为 `Base(x + 1)`**（新档地板），**不归 0**——归 0 会让分档表的地板形同虚设。**`x` 跨档时不清空 `Accumulated`，只在读取时被新档钳制**，跨档不吞掉玩家已积累的失败。**`x` 单调不减**（法则不被强制剥夺、置换是等价交换）⇒ 档位只会下降、不会回跳。
  - **掷骰走账号级 RNG，与 `CycleSeed` 完全解耦：** `roll = Hash64(AccountSeed, FinaleWinOrdinal) mod 10000`（万分比精度），命中 ⟺ `roll < 生效概率`。**绝不走 `SeedManager` 的四条子流**——它们全由 `Hash64(CycleSeed, streamName)` 派生，而篇章重试会生成全新 `CycleSeed`，挂上去等于让玩家靠重试换一次掷骰结果。**`FinaleWinOrdinal` 同时是幂等键**（同一序号重复结算得同一结果，退出重进 / push 重放都不改变掉落）。**对轮回可复现性零影响**——不派生自 `CycleSeed`、不消耗任何子流 `State`，故「残卷与 seed 公平性的关系」的答案是**两者不相交**。**执行方 = 客户端掷骰、后端可复算**（`AccountSeed` 在后端、序号与命中结果随 profile 上行），防篡改不因客户端执行而丢失，且 **Finale 奖励结算不引入任何新的网络往返**。见 `systems/common-properties.md`。
  - **玩家侧彻底隐含：** Finale 失败结算**不给任何文案 / 暗示 / 进度条 / 百分比**；唯一可见面是命中时的那一次发放（eventReward 界面上的一项奖励）。**它比既定的「隐含状态」更彻底——连隐藏属性的跨档定性叙事都不复用。**
  - **状态落点 = `PlayerProfile` 上的具名小类 `PlayerPowerFragment`**，**不并入**账号级统计计数（08-06b 已立判据：参与规则判定的字段与纯读数分属两层；残卷概率直接决定「发不发一条法则」，与 `chapterRetry` 同性质）。字段清单见 `../_index.md`。
  Source: `handoffs/2026-08-09b-player-power-fragment-finale-bound-drop-chance.md`。
- **第二条获取渠道 = premium bundle（已定案 · 08-09b 定交互）。** 付费礼包一次性给予**随机 1 个 PlayerPower**（外加随机 2 个 PlayerItem）。它与道统残卷是**同一个获取面上的两条渠道**——一条靠打，一条靠买。**二者的交互已定案：礼包不重置 `Accumulated`，但使 `x` +1，因而可能把账号推进上限更低的档位**（例：`x` 由 2 变 3 ⇒ 上限 50% → 30%）。**这是有意的**——`x` 分档的本意就是「拥有得越多，后续越难再得」，获取渠道是打还是买不改变这条曲线。**推论：付费不会吞掉玩家已积累的失败，只会让下一条法则来得更慢**，与「付费是增值而非必需」的既定口径同向（净收益仍为正，但不叠加）。礼包全貌见 `systems/monetization.md`。Source: `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md` + `handoffs/2026-08-09b-player-power-fragment-finale-bound-drop-chance.md`。
- **已获得的 PlayerPower 会进 PlayerPowerCodex。** 图鉴族（见 `../codex/`）为 PlayerPower 单列一本——它记录「见过 / 得到过哪些能力」的静态文案，与当前**持有**的 `List<PlayerPower>` 是两回事（失去某个 power 不会从图鉴中抹去它）。Source: 同上。
- **全局设定类效果 = capability flag + modifier pipeline（已定案）。** 「让玩家看见隐藏属性」这类改变全局设定的 power，以 **capability flag（布尔）+ modifier pipeline（数值）** 两条通道实现——数据声明 → 中心聚合 → 单点查询，避免在每个受影响层加条件。模型见 `common-properties.md`。Source: 同上。

- **法则能承载战斗内触发；战斗内异能是它的第三条生效通道（已定案 · 08-04b · 承重 · 答结 08-03 的待决问题）。** 法则与神通走**同一条路径**：作为 `CardType.Power` **开局入场**（条件 = `status == 开启` 且 `UsableScene` 含 `InCombat`），落在战场上、是**受保护的永久物**、可挂触发器、可带启动式异能。形态细则与 `PowerData` 字段见 `../../character-profile/power/_index.md`（两层共用一个 `PowerData`，由 `PowerScope` 声明层级）。
  - **推论 ①：combat-service 第一次需要读 PlayerProfile** —— 参战方组装时要同时读 CharacterProfile 的神通列表与 PlayerProfile 的法则列表。
  - **推论 ②：`UsableScene` 把法则切成两类** —— 纯事件向的能力（影响掷骰、推拉隐藏属性、商店折扣）**不入场**，继续走 capability flag / modifier pipeline 两条既有通道；只有 `InCombat` / `Both` 的才进战场。
  - **推论 ③：账号级内容由此进入战斗玩法层** —— 允许，**但极其稀缺**。理由是 premium bundle 花了钱就该让体验更好，而战斗是核心体验的关键一环；**代价由稀缺性而非规则承担**（不设规则禁令）。

  Source: `handoffs/2026-08-04b-mtg-loanwords-card-types-and-intent-snapshot.md`。
- **战斗内法则的稀缺性纪律（已定案 · 08-04b · 承重）。** 三条可执行形态：
  - **配额纪律：** `UsableScene` 含 `InCombat` 的法则应是明确的少数——**≤ 1/5 的法则条目**；内容加载时统计比例、超标 `PushWarning` + 报出当前比例，让越界在启动时被看见。**这是稀缺性纪律的机械化检查，不是硬校验。**
  - **强度上沿有了可校验的量纲（已定案 · 结构是硬的，百分比是初值）。** 既定定位「偏体验改善与容错、不抬高道念产出上限、允许影响胜负但不应成为胜负的主要来源」缺的正是「主要来源」的量纲。刻度取**道念净贡献占本方 `baseMomentum` 的比例**（`baseMomentum` 已是既定的战斗强度主刻度）：**单条 ≤ 10%** · **老账号全开口径合计 ≤ 25%**（关键的第二道闸——法则不可被针对且跨轮回单调累积，没有总闸必然在老账号处失控；**这就是「难度曲线按老账号全开校准」的可执行形态**）· **不得随对局延长而累积**（「每回合 +X 道念」「按手牌数缩放的倍率」一律禁止：在 10 回合定长下它们是线性放大器）。
    - 允许 ✅：**信息类**（探查）· **便利类**（每场一次重排手牌 / 查看牌堆顶）· **容错类**（有次数上限的兜底）——前两类道念净贡献为 0（间接）。禁止 ❌：**稳定产出类** · **倍率类**。
    - **明写：战斗内法则在 ch1 前段只能是纯信息 / 便利类、道念贡献为 0**（`baseMomentum` 1–5 时 10% 不足 1 点）。新手期不该被账号级内容干扰——**这条必须写出来，否则内容侧会以为可以给一点点数值。**
    - **总闸不可机械校验**（法则的道念贡献往往是间接的，「探查」值多少道念没法算），只能作为**内容评审口径**，与 `IgnoresProtection` 的 1% 同性质。系数表见 `systems/balance.md`。
    Source: `handoffs/2026-08-06d-combat-open-questions-mass-closure.md`。
  - **强度定位：** 战斗内的法则偏向**体验改善与容错**（信息、便利、少量兜底），而非直接抬高道念产出上限。**允许影响胜负，但不应成为胜负的主要来源。** 已定名的**探查**（付出代价换取当回合敌人意图）正是这类能力的样板。
  - **付费的战斗价值主要由古宝承载**——古宝有使用次数限制，次数天然是节流阀，让付费收益是「关键时刻多几次转圜」而非「永久变强」。这个分工同时满足「花钱体验更好」与「不滑向 pay-to-win」，不需要任何新机制。见 `systems/monetization.md`。
  - **仍需留意：** 法则**不可被针对且跨轮回永久持有**，故同一条战斗内法则的价值会随账号年龄**单调累积**；平衡时应按「**老账号全开**」而非「新账号裸奔」校准难度曲线。归 `systems/balance.md`。

  Source: 同上。
- **法则不会被强制剥夺：只有玩家自愿的「置换」能真正移除，其余一律降级为「本轮回禁用」（已定案 · 08-06b · 承重）。** 事件侧移除 `Power` 时**玩家永远有选择权**；上午列的「真的永久剥夺」候选**否决**，采纳的是按**玩家是否点头**把通道一分为二：

  | 形态 | 触发方式 | 对账号的作用 | 适用对象 |
  |---|---|---|---|
  | **置换型剥夺** | **玩家主动选择**（有对价，例如换成另一条法则） | **真的移除**，写 PlayerProfile | 法则 · 神通同理 |
  | **本轮回禁用** | 事件 outcome / 负向条目，玩家未必同意 | **不删除**，仅本轮回不生效 | 法则（PlayerPower） |
  | 战斗内 `IgnoresProtection` | 栈上结算的效果 | **不写 Profile**，仅本场（战场条目被移除） | 已入场的 `Power` 永久物 |

  - **推论 ①（承重）：付费内容不会被游戏销毁。** 法则部分来自 premium bundle，**「花钱买到的东西可能被一个事件拿走」这条风险彻底关闭**——玩家点头才失去，且失去时拿到等价物。与既定付费边界（「花钱体验更好、不滑向 pay-to-win」）同向，并免去一整类客诉与退款争议。见 `systems/monetization.md`。
  - **推论 ②：三级严重度阶梯就此成形。** 本场移除 < 本轮回禁用 < 账号移除（仅置换、需自愿）。**「失去法则」不再是二元事件，而是一条有梯度的压力线**，内容侧可按事件分量选档。
  - **推论 ③：置换是正向设计，不是惩罚。** 「以一换一」本质是**卡组构筑式的取舍**（换掉不合本局流派的法则），把原本会激起挫败的机制转成一个有趣的决策点——**它把「失去法则」从风险面挪到了设计面**。
  - **推论 ④：「本轮回禁用」需要一个轮回级的抑制表达。** `status` 开关是**账号级**持久字段，不能拿它承载本轮回禁用——否则轮回结束后忘了恢复即等同永久剥夺。**它必须落在轮回级状态上**（`CharacterProfile` 侧的一个被禁用 `Id` 集合），使轮回结束即自然失效，与「轮回状态在轮回结束时被干净拆解」的既定纪律一致。形态见待决问题。
  - **推论 ⑤：`Power` 的「受保护」语义是三层，不是两层。** `IsProtected`（战场上的可针对性）· 本轮回持有的有效性（可被禁用）· 账号持有权（**只有自愿置换能动**）。
  Source: `handoffs/2026-08-06b-asymmetric-ch1-band-consented-power-loss-and-chapter-retry-shape.md`。
- **失去 `Power` 的配额 ≈ 1% 的 event，且不限于战斗（已定案 · 08-05 立 · 08-06 定分母 · 08-06b 定分子构成）。** 08-04b「稀缺性归内容侧纪律」那条纪律有了量化口径：**「这次可能失去法则」的事件应约占玩家经历的全部 AdventureEvent（九类）的 1%**。**分子的构成现在明确**：置换型事件 + 本轮回禁用型事件 + 战斗内带 `IgnoresProtection` 的遭遇，三类合计约 1%，**概率控制归内容侧**（与「稀缺性归内容侧纪律、代码只留 `PushWarning`」一致）。
  - **推论 ③：1% 是「出现频次」口径，不是「条目占比」口径**，故**无法被加载时机械化校验**。08-04b 的 `PushWarning` 逐条列举保持不变（作用是让清单始终可见、可人工审阅）；1% 落在**内容编排与抽取权重侧**，且校验面从战斗内容**扩到整个事件池**，落点主要在 `systems/services/future-event-service.md` 的物化与加权规则上。
  - **战斗内 `IgnoresProtection` 那一支另有自己的分母（已定案 · 与上条嵌套不冲突）：** **分母 = 一次完整轮回中玩家进入并结算的战斗类遭遇总数**（Combat + Practice + Finale，按「进入」计不按胜负计）；**分子 = 其中至少发生过一次 `IgnoresProtection` 实际结算的遭遇数**；目标同样 ≈ 1%。**「实际结算」而非「敌人持有」是关键**——带该效果的敌人若本场没打出那张牌，玩家没撞上，不计入分子。量级换算：一次轮回约 30–36 场战斗 ⇒ **1% ≈ 每 3 次完整轮回撞上 1 次**（这个数字比「1%」直观得多，是内容编排时唯一需要记住的口径）。编排规则（仅挂 boss 档载体 · 每篇章至多 1 个载体 · **一次轮回内至多结算一次** · **绝不挂在玩家可主动获取的内容上** · 保留 `PushWarning` + 人工核对表）见 `systems/balance.md`。**「一次轮回至多一次」需要一个轮回级布尔位落 `CycleState`** ⇒ **「1% 不落代码」的措辞微调为「1% 的分布归内容编排，仅一个轮回级布尔位落代码」**——它是「平均 1%」与「体感 1%」之间的唯一桥。Source: `handoffs/2026-08-06d-combat-open-questions-mass-closure.md`。
  - **推论 ④：量级坐实。** 篇章时长上调后事件总数「多得多」，按数十个事件计，1% ≈ **一个篇章遇上一次或更少**。「我的法则会不会被拆」因此是跨篇章尺度的稀有事件，与 08-04b 接受的那条代价（内容级稀缺保证而非类型级绝对保证）量级吻合。
  Source: `handoffs/2026-08-05-level-band-stack-save-and-token-free-deck.md` + `handoffs/2026-08-06-ch1-band-widening-cross-realm-crush-and-chapter-retry.md` + `handoffs/2026-08-06b-asymmetric-ch1-band-consented-power-loss-and-chapter-retry-shape.md`。

> 具体的触发器体系、`status` 开关模型、capability flag 提案、RelicData 字段等共有属性见 `common-properties.md`。

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **PlayerPower 平衡边界待定。** 是否影响 cycle seed / 计分公平、防 pay/grind-to-win 的边界均待定。→ 见 `systems/services/life-cycle-service.md`。Source: `handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。
- **两条获取渠道的候选池与排重规则（08-09b 收窄为「抽哪一条」这一半）。** **获取时机与渠道交互均已定案**：道统残卷在 Finale 胜利时掷定并即时发放（RNG 与轮回 seed 不相交），礼包不重置概率但压低上限。**仍待定的是抽取本身**——从哪个池抽（`AllEnabled()` 全池 / 排除已拥有 / 按稀有度）、抽到重复怎么办；它同时是残卷伪码里 `pickedPowerId` 与 `HasGrantable()` 的前置依赖（**残卷其余部分不依赖它**）。→ `systems/monetization.md`。Source: `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md` + `handoffs/2026-08-09b-player-power-fragment-finale-bound-drop-chance.md`。
- **获取触发未设计（残卷 / 礼包之外）。**（**失去的语义已定案 · 08-06b**，见上方三形态表；剩余的是形态问题，已单列。）开关 UI 亦未细化。是否还有第三条获取渠道（事件 outcome 直接给予？）未陈述。→ `systems/adventure-event/common-properties.md`。
- **「本轮回禁用」的承载字段与生效面（08-06b 新增）。** 落在 `CharacterProfile` 的哪个位置（一个被禁用 `PowerId` 集合？`Status` 内还是与 deck 平级）；被禁用的法则在战斗中如何表现（**开局根本不入场**，还是入场后立刻被移除——前者更干净）；禁用是否对进行中的战斗立即生效；禁用状态是否对玩家可见（元进程界面标注「本轮回失效」）。→ `systems/character-profile/`、`systems/services/combat-service.md`。Source: `handoffs/2026-08-06b-asymmetric-ch1-band-consented-power-loss-and-chapter-retry-shape.md`。
- **置换型剥夺的候选池与对价规则（08-06b 新增）。** 换来的法则从哪个池抽（全池 / 排除已有 / 同稀有度）、玩家能否先看到换来的是什么再决定、拒绝置换是否有代价，以及**置换能否移除神通**（`Scope == Character` 一侧尚未表态，虽然神通是轮回级、语义上无争议）。→ `systems/character-profile/power/`、`systems/adventure-event/common-properties.md`。Source: 同上。
- **`ProfileChangeSpec` 表达三类移除的 element 形态（08-06 新增 · 08-06b 收窄为「怎么写」）。** 语义已定（置换 / 禁用 / 不强制剥夺）；仍待定：按 `Id` 指定 / 随机 / 按 `Scope` 限定；「置换」是一个原子的双向 element 还是「移除 + 给予」两条；能否出现在 `SelectCost` 侧（**置换作为选择成本似乎合理**，但禁用型不该出现在成本侧）；以及 08-04b 的 `PushWarning` 逐条列举是否要在事件 outcome 侧补一处对称落点。→ `systems/adventure-event/common-properties.md`、`systems/services/life-cycle-service.md`、`systems/services/future-event-service.md`。Source: `handoffs/2026-08-06-ch1-band-widening-cross-realm-crush-and-chapter-retry.md` + `handoffs/2026-08-06b-asymmetric-ch1-band-consented-power-loss-and-chapter-retry-shape.md`。
- **relic / joker 内容为占位。** 触发条件、效果关键字、RelicData 字段清单均尚未设计，需一次 handoff。

## 对应
提炼至：`.claude/knowledge/systems/player-profile/player-power/_index.md`（待建）；RelicData 见 `.claude/knowledge/data/_index.md`。
