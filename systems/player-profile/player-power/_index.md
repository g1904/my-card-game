# player-power

> **法则 / PlayerPower** —— 账号级 always-available 能力，带开关（默认开启）；通过事件触发器的被动修正（relic / joker 语义）。**数据定义 = `PowerData`**（两层共用一个类型，由 `AbilityScope` 声明层级；字段面权威在 `../../character-profile/power/_index.md`）。
> **中文定名 = 法则**；轮回级的对应物是 **神通 / CharacterPower**（`../../character-profile/power/`）。**中文名不表达层级** —— 账号级 ↔ 轮回级的对称只在英文标识符上成立。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **PlayerPower = 账号级 always-available 能力，带开关。** always-available，带**开关（默认开启）**；**通常全局、不与角色绑定**；可为 **QoL** 或**影响公平性的一定加强**（需衡量平衡）。由 PlayerProfile 持有（`List<PlayerPower>`），跨轮回持久。**获取越多后续越易，但 AdventureEvent 过程中也可能失去**已获取的 PlayerPower。
- **定位 = 轻度提升（light improvement）。** 承认它影响平衡，但因**本作无 PvP、纯 PvE**，让 power 带来一定强度是**可容忍的**，并**打开更大的设计空间**去做有趣的 power。
- **被动修正 = 挂接到事件触发器。** PlayerPower 通过响应游戏事件（触发器）施加被动修正（relic / joker 语义）。
- **数据定义 = `PowerData`。** relic / joker 的**设计意图、触发条件与效果**在本处陈述；**类型本身不在本文件**——法则与神通共用一个 `PowerData`（`AbilityScope` 声明层级），字段清单的权威在 `../../character-profile/power/_index.md`，异能语法（`AbilityData` 两格 XOR · `EffectData` 子类树 · `TriggerConditionData` / `TimingIds`）的权威在 `../../character-profile/deck/common-properties.md`（`ADR-0115`）。

- **开关落为 `status` 字段（启用 / 禁用）。** 「带开关」不只是 UX 描述，而是持有条目 record 上的持久字段 `bool Status`（true = 启用，默认 true；record 形态见 `../_index.md`）；它与「拥有 / 失去」是**两个正交维度**（失去 = 移出 `playerPower` 列表，而非置禁用）。**写入经 `ProfileChangeSpec.AbilityStatusChanges`**，门面 `SetAbilityStatus(kind, scope, abilityId, enabled)`，见 `systems/services/profile-service.md`。
- **道统残卷 / `PlayerPowerFragment` = 焊在 Finale 上的 PlayerPower 掉落概率（元进程的失败侧产出 · 承重）。** 失败不是零推进：
  - **不发放账号级货币。** 累积的是**一个递增的概率**——获得新 PlayerPower 的掉落概率；**掷中并授予后即重置**。
  - **为何不是货币：** 可支配的货币会引入**第二套账号级经济**（获取 → 囤积 → 兑换 → 定价），而本作的元进程只想要「失败也在推进」这一条效果。递增概率给了同样的推进感，却不新增任何经济系统。因此它是一个**账号级的隐含状态**（一个概率值 + 重置规则），不是玩家可查看余额、可花费的资源。
  - **三个时刻全部落在 Finale（天劫）上：** **累积 = Finale 战斗失败**（该角色在同刻终结）· **掷骰 = Finale 战斗通过**（一次通过掷一次）· **发放 = 该 Finale 的 eventReward 界面**，掷中的法则与战斗奖励一并呈现。**其余一切失败**——`Standard` / `Practice` 档失败、寿元耗尽、主动弃置——**一律不累积**——「失败侧有产出」这条在残卷上收窄到只认 Finale（见 `systems/scoring.md`）。
  - **累积与角色终结同刻发生 ⇒ 写入顺序是承重的。** `Accumulated` 是账号级写入，必须在角色终结提交之前完成，否则这条机制在每一次失败上都丢——顺序纪律见 `systems/services/life-cycle-service.md`。
  - **「通过」是二值判据（道念差 `>= 0`），不分厚薄。** 勉强通过照常掷骰、照常发放、照常算首胜；奖励的厚薄由战斗奖励那条线承担，不在残卷这条线上分化。
  - **结构性简化（四条）：** ① **不需要跨轮回的待发放字段**（掷骰与发放同刻同事务，`PendingPowerId` 一类中间态不存在）；② **整条机制落在既有 Finale 结算链路上**——`CombatEventResolver` → `CombatResult.Spoils` → `eventEnd` 的那一次 `TryApply`，**授予法则成为 Spoils 的一个 element**，不新增结算阶段、不新增存档点；③ **累积天然有界**——「一篇章一个 Finale + 败后不可重战」⇒ 每个角色每篇章至多累积一次**或**掷骰一次且二者互斥，**残卷不需要任何额外防刷规则**；④ **叙事自洽**——在天劫下身死积攒，在渡劫成功那一刻兑现。
  - **上限 / 基础概率 / 适格篇章按 `x` 分档；`x` = 已拥有且 `SourceCode == Source.FinaleWin` 的法则数。** 即**只数「靠渡劫拿到的」那些**——礼包、成就奖励等其他渠道得来的法则**不计入**。`status` 开关与「本轮回禁用」同样**不影响计数**（那是生效维度不是持有维度）。**分档自变量的含义因此是「靠渡劫拿得越多，后续越难再从渡劫拿到」**——理由见「与 premium bundle 的关系」。**全局前置「尚未拥有的法则数 > 0」仍按全部持有计**（池是否取尽与来源无关），故存在合法状态 `x = 0` 但池已被礼包 / 成就取尽 ⇒ 整条线静默停摆。`SourceCode` / `Source` 的共有约定见 `systems/common-properties.md`。**⚠ `Source` 是按 `(CarrierKind, Scope)` 分域的开放清单，但这不影响 `x`**——法则一侧的合法取值恰是 `FinaleWin` / `PremiumBundle` / `AchievementReward`（`EventOutcome` / `CombatReward` / `ExchangePurchase` / `InitialGrant` 没有一个能出现在法则上），故 `x` 的口径、**单调不减 ⇒ 档位只降不回跳**、首胜规则 / 全局前置 / 账号级 RNG / 幂等键全部照常成立。**`Source` 清单再扩也动不了残卷。****篇章闸门逐档累加地移除**（`x ≥ 5` 移除 ch1、`x ≥ 12` 再移除 ch2），**不是**「限定到某一章」。**承重的合一：适格 Finale ⟺ 该档增量 > 0 的篇章**——两张表是同一条闸门的两面，实现侧只需一张按 `(x, chapter)` 索引的表，`gain == 0` 即该篇章在该档整体退出残卷系统。这条一致性使「在某章输了却只能在别章兑现」的错位不可能出现。分档表见 `systems/balance.md`。
  - **首胜规则优先于闸门：** 某篇章的**首次 Finale 通过**一律硬置 **100%**，即使该篇章在当前档已不适格。三次首胜是账号生命周期里三份确定的里程碑，被闸门吃掉会造成「第一次渡劫成功却空手」。（`x = 0` 因此不需要单独档位。）**已知代价（接受）：** 一次刚好打平的通过同样兑掉该篇章一生一次的里程碑；给它开例外等于按新判据重新制造那个体验事故，且会连带打破「首胜不是后端校验的例外」这条跨库约定。
  - **全局前置：** 仅当「尚未拥有的法则数 > 0」时才累积、才掷骰、才发放；池已取尽 → 整条线**静默停摆**，概率停在原值。
  - **生效概率 = `clamp(Accumulated, Base(x), Cap(x))`；发放后重置为 `Base(x + 1)`**（新档地板），**不归 0**——归 0 会让分档表的地板形同虚设。**`x` 跨档时不清空 `Accumulated`，只在读取时被新档钳制**，跨档不吞掉玩家已积累的失败。**`x` 单调不减 ⇒ 档位只会下降、不会回跳**：法则不被强制剥夺；礼包 / 成就奖励不推动 `x`；**置换所得条目继承被换出条目的 `SourceCode`**，故置换对 `x` 完全中性——这正是为了**关死「用置换刷回高掉率」的通道**，见 `systems/common-properties.md`。
  - **掷骰走账号级 RNG，与 `CycleSeed` 完全解耦：** `rng = AccountRng.For(AccountStream.PowerFragment, ordinal)`，序号取**本次**的值（`ordinal = FinaleWinOrdinal + 1`，先算后写，通则见 `systems/common-properties.md`），`roll = rng.Roll()`（= `NextU64() mod 10000`，万分比精度），命中 ⟺ `roll < 生效概率`。随机源是**契约定义的纯函数 SplitMix64**、不是 Godot 的 `RandomNumberGenerator`——跨语言逐位一致是后端复算成立的前提，见 `systems/common-properties.md`。**具名域 `AccountStream` 是三参数派生的一部分**（两参数派生会让礼包与残卷的同序号撞出同一序列）；**命中判定语义不变，只是加了域**。
  - **每次通过必掷、并把两个中间值落存档（承重的写入约定）：** 掷骰结果写 `LastRoll`、掷骰当刻的生效概率写 `LastEffectiveChance`——**即使当次不发放也照写**（池已取尽而静默停摆时 `FinaleWinOrdinal` 仍 `+1`，不写则后端复算无输入、会在正常账号上稳定误报）；**首次通过那一次 `LastEffectiveChance` 写 `10000`**（首胜 100% 就是那一刻的生效概率，如实记录）。字段与读档校验见 `../_index.md`；后端据这两个值做的三条校验见 `backend-design-documents/contracts/profile-sync.md` §7。掷中后的抽取**复用同一个 rng 实例连续抽**，故整次结算由 `(PowerFragment, FinaleWinOrdinal)` 完全确定。**绝不走 `SeedManager` 的四条子流**——它们全由 `Hash64(CycleSeed, streamName)` 派生，而篇章重试会生成全新 `CycleSeed`，挂上去等于让玩家靠重试换一次掷骰结果。**`FinaleWinOrdinal` 同时是幂等键**（同一序号重复结算得同一结果，退出重进 / push 重放都不改变掉落）。**对轮回可复现性零影响**——不派生自 `CycleSeed`、不消耗任何子流 `State`，故「残卷与 seed 公平性的关系」的答案是**两者不相交**。**执行方 = 客户端掷骰、后端可复算**（`AccountSeed` 在后端、序号与命中结果随 profile 上行），防篡改不因客户端执行而丢失，且 **Finale 奖励结算不引入任何新的网络往返**。见 `systems/common-properties.md`。
  - **玩家侧彻底隐含：** Finale 失败结算**不给任何文案 / 暗示 / 进度条 / 百分比**；唯一可见面是命中时的那一次发放（eventReward 界面上的一项奖励）。**它比既定的「隐含状态」更彻底——连隐藏属性的跨档定性叙事都不复用。**
  - **隐含性与分档复杂度均为设计初衷，不简化（承重）。** 本机制是**分发账户级加强的核心算法**：它的职责是在幕后调控玩家的账户级进程，**不是**一条供玩家学习与优化的曲线。故「不可见 + 高复杂度 ⇒ 玩家学不到、设计者也无从从玩家行为验证」这条质疑**前提不适用**——它本就不打算被学到。三张分档表、五个阈值（3/5/9/12/15）、万分比整数精度、`x` 的收窄口径**全部原样保留**；**不减档、不给任何形式的累积进度可感化**（哪怕是极轻的）——任何可感化都会把它变成可优化对象，直接抵消它的设计目的。
  - **状态落点 = `PlayerProfile` 上的具名小类 `PlayerPowerFragment`**，**不并入**账号级统计计数（判据：参与规则判定的字段与纯读数分属两层；残卷概率直接决定「发不发一条法则」，与 `chapterRetry` 同性质）。字段清单见 `../_index.md`。
- **第二条获取渠道 = premium bundle。** 付费礼包一次性给予**随机 1 个 PlayerPower**（外加随机 2 个 PlayerItem）。它与道统残卷是**同一个获取面上的两条渠道**——一条靠打，一条靠买。**二者的交互 = 完全解耦**：礼包**既不重置 `Accumulated`，也不改变档位**——礼包给的法则 `SourceCode == Source.PremiumBundle`，不计入 `x`。**获取渠道是打还是买，确实改变这条曲线，而这是有意为之**——分档的用途是给**失败侧产出**一条递减曲线，把付费与成就奖励算进自变量等于让玩家买到的东西反过来掐死自己的残卷线。**推论：付费收益是纯净收益**，不附带「下一条法则来得更慢」的代价；礼包因此有一份净强度增益，平衡侧需正视。礼包全貌见 `systems/monetization.md`。
- **已获得的 PlayerPower 会进 PlayerPowerCodex。** 图鉴族（见 `../codex/`）为 PlayerPower 单列一本——它记录「见过 / 得到过哪些能力」的静态文案，与当前**持有**的 `List<PlayerPower>` 是两回事（失去某个 power 不会从图鉴中抹去它）。
- **全局设定类效果 = capability flag + modifier pipeline。** 「让玩家看见隐藏属性」这类改变全局设定的 power，以 **capability flag（布尔）+ modifier pipeline（数值）** 两条通道实现——数据声明 → 中心聚合 → 单点查询，避免在每个受影响层加条件。模型见 `common-properties.md`。

- **法则能承载战斗内触发；战斗内异能是它的第三条生效通道（承重）。** 法则与神通走**同一条路径**：作为 `CardType.Power` **开局入场**（三条与门：`status == 开启` 且 `UsableScene` 含 `InCombat` 且不在 `disabledAbility` 内），落在战场上、是**受保护的永久物**、可挂触发器、可带启动式异能。形态细则与 `PowerData` 字段见 `../../character-profile/power/_index.md`（两层共用一个 `PowerData`，由 `AbilityScope` 声明层级）。
  - **推论 ①：combat-service 第一次需要读 PlayerProfile** —— 参战方组装时要同时读 CharacterProfile 的神通列表与 PlayerProfile 的法则列表。
  - **推论 ②：`UsableScene` 把法则切成两类** —— 纯事件向的能力（影响掷骰、推拉隐藏属性、商店折扣）**不入场**，继续走 capability flag / modifier pipeline 两条既有通道；只有 `InCombat` / `Both` 的才进战场。
  - **推论 ③：账号级内容由此进入战斗玩法层** —— 允许，**但极其稀缺**。理由是 premium bundle 花了钱就该让体验更好，而战斗是核心体验的关键一环；**代价由稀缺性而非规则承担**（不设规则禁令）。
- **战斗内法则的稀缺性纪律（承重）。** 三条可执行形态：
  - **配额纪律：** `UsableScene` 含 `InCombat` 的法则应是明确的少数——**≤ 1/5 的法则条目**；内容加载时统计比例、超标 `PushWarning` + 报出当前比例，让越界在启动时被看见。**这是稀缺性纪律的机械化检查，不是硬校验。**
  - **强度上沿有了可校验的量纲（结构是硬的，百分比是初值）。** 既定定位「偏体验改善与容错、不抬高道念产出上限、允许影响胜负但不应成为胜负的主要来源」缺的正是「主要来源」的量纲。刻度取**道念净贡献占本方 `baseMomentum` 的比例**（`baseMomentum` 已是既定的战斗强度主刻度）：**单条 ≤ 10%** · **老账号全开口径合计 ≤ 25%**（第二道参考闸——法则不可被针对且跨轮回单调累积，没有总闸必然在老账号处失控；它把这条风险量化到一个可讨论的数上，**但见下方降格说明**）· **不得随对局延长而累积**（「每回合 +X 道念」「按手牌数缩放的倍率」一律禁止：在 10 回合定长下它们是线性放大器）。
    - 允许 ✅：**信息 / 便利类**（每场一次重排手牌 / 查看牌堆顶；道念净贡献为 0）· **容错类**（有次数上限的兜底）。（信息类与便利类不分家。**此处的「信息」限于玩家自己的牌序 / 手牌**；关于敌人 / 未来 / 世界的外部情报不存在任何以资源换取的通道，这一类里永远不会出现「花代价买敌人情报」形态的条目。）——前两类道念净贡献为 0（间接）。禁止 ❌：**稳定产出类** · **倍率类**。
    - **明写：战斗内法则在 ch1 前段只能是纯信息 / 便利类、道念贡献为 0**（`baseMomentum` 1–5 时 10% 不足 1 点）。新手期不该被账号级内容干扰——**这条必须写出来，否则内容侧会以为可以给一点点数值。**
    - **⚠ 两个百分比不是承重结论，是评审参考。** 它们不可机械校验（法则的道念贡献往往是间接的，「查看牌堆顶」值多少道念没法算），按「纪律的可执行化」阶梯落在**第 4 级（零保证）** ⇒ **不得被引用为任何设计的承重依据**，用途只有一个：内容评审时判断一条战斗内法则是否明显过线。**承重的是上方那条定性定位**，它不需要数字即成立。**不为它补代理指标。** 系数表与完整论据见 `systems/balance.md`（权威）。
  - **强度定位：** 战斗内的法则偏向**体验改善与容错**（信息、便利、少量兜底），而非直接抬高道念产出上限。**允许影响胜负，但不应成为胜负的主要来源。** 样板：**每场一次重排手牌**、**查看抽牌堆顶**一类零道念贡献的便利能力。
  - **付费的战斗价值主要由古宝承载**——古宝有使用次数限制，次数天然是节流阀，让付费收益是「关键时刻多几次转圜」而非「永久变强」。这个分工同时满足「花钱体验更好」与「不滑向 pay-to-win」，不需要任何新机制。见 `systems/monetization.md`。
  - **仍需留意：** 法则**不可被针对且跨轮回永久持有**，故同一条战斗内法则的价值会随账号年龄**单调累积**；平衡时应按「**老账号全开**」而非「新账号裸奔」校准难度曲线。归 `systems/balance.md`。
- **法则不会被强制剥夺：只有玩家自愿的「置换」能真正移除，其余一律降级为「本轮回禁用」（承重）。** 事件侧移除 `Power` 时**玩家永远有选择权**；上午列的「真的永久剥夺」候选**否决**，采纳的是按**玩家是否点头**把通道一分为二：

  | 形态 | 触发方式 | 对账号的作用 | 适用对象 |
  |---|---|---|---|
  | **置换型剥夺** | **玩家主动选择**（有对价，例如换成另一条法则） | **真的移除**，写 PlayerProfile | 法则 · 神通同理 |
  | **本轮回禁用** | 事件 outcome / 负向条目，玩家未必同意 | **不删除**，仅本轮回不生效 | 法则（PlayerPower） |
  | 战斗内 `IgnoresProtection` | 栈上结算的效果 | **不写 Profile**，仅本场（战场条目被移除） | 已入场的 `Power` 永久物 |

  - **推论 ①（承重）：付费内容不会被游戏销毁。** 法则部分来自 premium bundle，**「花钱买到的东西可能被一个事件拿走」这条风险彻底关闭**——玩家点头才失去，且失去时拿到等价物。与既定付费边界（「花钱体验更好、不滑向 pay-to-win」）同向，并免去一整类客诉与退款争议。见 `systems/monetization.md`。
  - **推论 ②：三级严重度阶梯就此成形。** 本场移除 < 本轮回禁用 < 账号移除（仅置换、需自愿）。**「失去法则」不再是二元事件，而是一条有梯度的压力线**，内容侧可按事件分量选档。
  - **推论 ③：置换是正向设计，不是惩罚。** 「以一换一」本质是**卡组构筑式的取舍**（换掉不合本局流派的法则），把原本会激起挫败的机制转成一个有趣的决策点——**它把「失去法则」从风险面挪到了设计面**。
  - **推论 ④：「本轮回禁用」需要一个轮回级的抑制表达。** `status` 开关是**账号级**持久字段，不能拿它承载本轮回禁用——否则轮回结束后忘了恢复即等同永久剥夺。**它必须落在轮回级状态上**（`CharacterProfile` 侧的一个被禁用 `Id` 集合），使轮回结束即自然失效，与「轮回状态在轮回结束时被干净拆解」的既定纪律一致。**形态已定，见下一条**「『本轮回禁用』的承载与生效面」（`CharacterProfile.disabledAbility` + 三档 `DisableDuration`）。
  - **推论 ⑥：置换不改变 `SourceCode`。** 换来的条目**继承被换出条目的来源**，故置换对残卷的 `x` 完全中性——否则「换掉一条 `FinaleWin` 法则」就成了压低 `x`、刷回高掉率的通道。见 `systems/common-properties.md`。
  - **推论 ⑤：`Power` 的「受保护」语义是三层，不是两层。** `IsProtected`（战场上的可针对性）· 本轮回持有的有效性（可被禁用）· 账号持有权（**只有自愿置换能动**）。
- **「本轮回禁用」的承载与生效面（承重）。** 禁用集合落 **`CharacterProfile.disabledAbility`**——与 `pastEvent` / `chapterRetry` / `activeCombat` 平级的新字段，**不落 `Status` 内**（`Status` 是数值型运行状态，禁用表是集合型 build 状态）。
  - **三档时长 `DisableDuration { NextEvent, ThisChapter, ThisCycle }`。** 第一档定名 `NextEvent` 而非 `ThisEvent`：施加只发生在 outcome 侧（`eventEnd`，本次事件已结算完毕），「本事件禁用」等于空操作，故它实际管的是**下一次进入的那个事件**——**枚举成员的名字必须说实话**。三档因此全部有效、无死成员。
  - **生效判据 = 截断在「进入生效面」那一步**（不入场 / 不进本场可用道具 / 不进 capability 聚合 / 不进 modifier 表 / 不注册触发器），与「`status` 关闭 = 不入场」同构；**`Power` 的入场由两条与门变三条与门**。完整生效面表见 `../../character-profile/power/_index.md`。
  - **一经写入即在全部生效面上立即生效，包括进行中的战斗**；但当前链路下该路径不可达（唯一写入点 `TryApply` × 唯一施加时机 `eventEnd`），故落地是**复用 `IgnoresProtection` 的战场移除路径 + `#if DEBUG` 大声失败**，不新写中途重算参战方的代码。
  - **对玩家可见**：元进程界面照常列出、灰态 + 徽标 + 三档文案、长按查看来源事件；施加时事件结算面板必须告知；战斗屏不呈现。
  - **禁用不影响持有**：`Charges` 不动，残卷的 `x` 不受影响（生效维度 ≠ 持有维度）。**古宝同样开放到 `ThisCycle` 档**——与法则对称；不销毁、不扣次数、轮回结束即恢复，故不违反「付费内容不会被游戏销毁」。强度由**内容侧稀缺纪律**承担：**禁用古宝的事件应比禁用法宝显著更稀有，且一并计入既定的「失去能力」频次预算分子**（评审清单级，不加代码硬规则）。
- **置换的候选池与对价规则：排除已有 · 同稀有度 · 先看后决 · 拒绝无代价 · 四类通用但只同类型置换。**
  - **同池判据 = `(CarrierKind, Scope)` 全同** ⇒ 四个独立池（`PlayerPower ↔ PlayerPower` / `CharacterPower ↔ CharacterPower` / `CharacterItem ↔ CharacterItem` / `PlayerItem ↔ PlayerItem`）。跨 `Scope` 置换会把账号级资产换成轮回级（隐性剥夺）或反之（白嫖账号级内容）——`Scope` 本就是「决定持久层」的字段，跨层交换等于绕过它。
  - **抽取 = `AllEnabled()` 全池 → 过滤同 `(CarrierKind, Scope)` → 过滤同 `Rarity` → 排除已持有 → seeded 抽一条**，走 **`reward` 子流**（置换候选是一次奖励性质的内容抽取；不新增子流）。**必须走 `AllEnabled()`**，不得自写 `AllIncludingDisabled().Where(...)`。
  - **空池 → 整个置换成为空操作**（不移除、不给予）+ `PushWarning` 带 `(CarrierKind, Scope, Rarity, characterId)`。它是「拒绝置换无代价」的自然分支；相比「降级到相邻稀有度」不引入任何新规则，且把内容缺口暴露在告警里而非悄悄改变掉落品质。
  - **置换能移除神通**（`Scope == Character` 一侧此前只是没表态；神通是轮回级、语义上无争议）。
  - **置换所得条目继承被换出条目的 `SourceCode`** ⇒ 置换对残卷的 `x` 完全中性。
  - **稀有度字段 `Rarity: RarityTier { Tier1..Tier5 }`（五档，档号越高越稀有）**，挂 `PowerData` / `ItemData` / `CardData` / `CultivationTechniqueData`；缺失 → `PushError`。**功法不参与置换**——置换的四个池只覆盖 `(CarrierKind, Scope)` 四类能力条目，`DeckChangeOp` 没有置换算子；功法的 `Rarity` 只被抽取权重与过滤消费，消费点清单见 `systems/common-properties.md`。**类型名不得写成裸 `Tier`**——战后奖励的优势档已占用 `Tier { Narrow, Solid, Crushing }`，二者**不得复用同一枚举、也不得互相换算**。见 `systems/balance.md`。
- **授予候选池 = 三条渠道共用的一段抽取（承重）。** 残卷 · 礼包 · 置换是同一形状的授予，共用同一条取池链、同一段代码：

  ```
  DrawPool<TData> pool = Content.AllEnabled<TData>()
      .Filter(d => d.Kind == kind && d.Scope == scope)   // 四个独立池，判据同置换
      .Filter(d => d.ExclusiveSource == null)            // 去成就限定：专属条目不进任何抽取池
      .Filter(d => !owned.Contains(d.Id))                // 排重：排除已持有
      [.Filter(d => d.Rarity == anchorRarity)]           // 仅置换：锚定被换出条目的稀有度
      .PickOne(rng, weightByRarity)                      // 加权；置换侧已锚定稀有度，退化为等概率
      // rng 的静态类型是泛型参数 TRng : IRandomSource ——
      // 账号级传 AccountRandom（SplitMix64），轮回级传 GodotRandomSource（reward 子流）
  ```

  残卷与礼包 ① 取 `(Power, Player)`，礼包 ② 取 `(Item, Player)`；置换四类通用。
  - **「抽到重复怎么办」在结构上被消解。** 排重发生在**取池阶段而非掷骰之后**：池里根本没有已持有的条目，**抽不出重复**。全局前置写的就是「尚未拥有的法则数 > 0 才掷骰」，它只有在「池 = 未持有集合」时才自洽。**由此 `HasGrantable()` ⟺ 按上式构造的池非空**，它与全局前置是同一个判断、不是两个；`pickedPowerId` 亦随之有定义，**残卷伪码就此完整可执行**。
  - **一次授予多条走无放回抽取**（`PickMany(rng, count)`），保证礼包 ② 的两件古宝不同。**无放回与加权一并成为 `DrawPool<T>` 契约的一部分**，见 `systems/services/content-service.md`。
  - **三条不过滤的维度（各有理由）：** 不按 `UsableScene` 过滤——「战斗内法则 ≤ 1/5」是内容侧的**条目比例**纪律，抽取侧再加一道等于把同一条闸门做成两处、且会让实际掉落比例偏离内容侧的编排意图；不按 `status` / `disabledAbility` 过滤——生效维度与持有维度正交，被禁用的法则**照常算作已持有**、照常排除出池；`ContentEnabled` 的语义**天然吃进来**——线上关闭一条法则即让它退出抽取池，而玩家已持有的那条照常 `Get(id)` 解析、照常计入 `x`（它本就不在池里），无需任何额外规则。
  - **按 `RarityTier` 加权，残卷与礼包共用一张表**（权重表与初值归 `systems/balance.md`）。**共用一张表保留单一旋钮**：分表等于让付费直接买到更高档强度，与「礼包净强度已上升是被接受的」叠加两次。**权重按剩余池即时归一**（排除已持有之后再归一）⇒ 老账号的池逐渐只剩高档条目、高档占比自然上升——它与残卷的递减掉率曲线方向相反，恰好让「越往后越难拿到，但拿到的更好」，不需要为此再加任何规则。**任一档权重为 0 → `PushError`**（否则会出现「池非空但抽不出来」，让 `HasGrantable()` 说谎）。
  - **宿主 = profile-service 内的 internal `GrantPoolManager`。** 抽取需要内容池（content-service）与已持有集合（profile-service）两样东西；后者是 profile-service 的自有状态，前者可经服务门面跨服务读取。反向（放 content-service）要求它读 `PlayerProfile`，违反「服务之间不读写对方字段」。**置换候选池复用同一 picker，经门面上的具名方法 `TryPickReplacement(kind, scope, anchorRarity, rng, out pickedId)` 进入 ⇒ 全库只有一处抽取能力条目的代码。** 取具名方法而非可空形参的理由与门面签名见 `systems/services/profile-service.md`。
  - **空池的处置按渠道分档：** 残卷 → **静默停摆**（既定，玩家侧彻底隐含）；置换 → **整个置换成为空操作** + `PushWarning`（既定）；礼包 → **三道闸 + 不补发**，见 `systems/monetization.md`。
  - **抽取结果在 spec 组装之前定稿**，`AbilityChangeElement` 只拿到已定稿的 `Id`——与「随机在 spec 组装前掷完」的既定纪律一致，无需新规则。
  - **日志**：`[GrantPool-Pick] kind=… scope=… stream=… ordinal=… poolSize=… picked=… rarity=…`。能力得失是玩家最在意、最易被投诉的一类变更，`poolSize` + `ordinal` 足以离线复算「为什么给了这条」。
- **禁用与置换都不出现在 `selectCost`，只出现在 outcome / reward 侧（承重）。** `ProfileChangeSpec.AbilityElements` 在 `EventOption.SelectCost` 内**恒为空**。四条支撑：① **成本侧只放可如实计价的量**——能力得失不可计价，塞进去会让 `selectCost` 的展示从一列数字变成「数字 + 一段能力说明」；② **成本侧无条件施加，与「先看后决 · 拒绝无代价」正面冲突**——把置换塞进成本侧，兑现拒绝权只能靠「不选这个事件」，等于把一次独立的玩法决策折叠进事件选择；③ **能力得失始终是事件的后果，不是入场费**，挪到成本侧与推论 ③「置换是正向设计、是一个决策点」直接相悖；④ **它换来一条可机械检查的不变式**（`SelectCost.AbilityElements` 恒空 ⇒ 物化组装后断言 + 内容加载期校验，两处 `PushError`）。
  - **outcome 侧形态**（置换与禁用共用同一条链路）：候选在**结算时**（`eventEnd` 之前）走 `reward` 子流掷定 → 结算面板展示「失去 A · 得到 B」+ 接受 / 拒绝（禁用型只告知、无选择）→ 拒绝 = 零 element、零代价 → 接受则两条 element 并入 `eventEnd` 那一次 `TryApply`。**这是一个事件内决策点，形状与战后奖励面板完全同构，不新增机制**；**候选必须预先算定并落决策点存档**，否则退出重进可以重掷。
  - **`PastEventEntry.SelectCost` 的快照形状不受影响**（它只装资源 element）；`AppliedChange` 新增能力 element 与统计 element。
- **失去能力的频次预算：持久三支合计 ≈ 1 次 / 完整轮回，且不限于战斗。** 「稀缺性归内容侧纪律」这条量化口径的**承重表述取每完整轮回的期望次数，不取百分比**——百分比口径会被分母漂移静默重定价，而内容编排关心的是「玩家一局撞上几次」；百分比只作括号里的换算副本（**≈0.88%** 的全部 AdventureEvent（五类，含 Travel），分母 ≈114），分母变动时只重算括号、目标值本身不动。**分子 = 三支持久支**：法则置换型事件 · 法则禁用型事件 · 神通（`CharacterPower`）置换 / 禁用（挤进同一份预算，不另立一套，见 `../../character-profile/power/_index.md`）。**概率控制归内容侧**（与「稀缺性归内容侧纪律、代码只留 `PushWarning`」一致）。
  - **推论 ③：这是「出现频次」口径，不是「条目占比」口径**，故**无法被加载时机械化校验**。加载期的 `PushWarning` 逐条列举因此照做（作用是让清单始终可见、可人工审阅）；预算落在**内容编排与抽取权重侧**，且校验面从战斗内容**扩到整个事件池**，落点主要在 `systems/services/future-event-service.md` 的物化与加权规则上。
  - **战斗内 `IgnoresProtection` 一支不计入上层合计，单独持有自己的口径**（战斗类遭遇为分母，目标 ≈ 3%，3% × 约 37 场 ≈ **1.11 次 / 轮回**——这个数字比百分比直观得多，是内容编排时唯一需要记住的口径）。解除嵌套的三条依据：① **它不写 Profile**（`systems/services/profile-service.md`）——本场结束即恢复，上层口径保护的「构筑投入不被拿走」这条心理契约它根本不触碰；② **分母不同**（战斗类遭遇 vs 全五类事件）——子集百分比嵌进全集百分比，战斗占比一变内层目标就被静默重定价；③ **控制旋钮不同**——它由载体编排控制，三支持久支落在内容编排与抽取权重侧，两者不共享任何一个可调的数。分母 / 分子定义、两条硬准入（仅挂 boss 档载体 · 绝不挂玩家可主动获取的内容）与**无轮回内次数上限、`CycleState` 不设任何相关状态位**的权威在 `systems/balance.md`，本处不复述。
  - **四支目标频次（次 / 完整轮回 · 待实测校准的初值）：**

    | 支 | 目标频次 | 换算副本（分母 114 事件） | 口径归属 |
    |---|---|---|---|
    | 战斗内 `IgnoresProtection` | ≈1.11（= 3% × 37 场战斗类遭遇） | ——（自持战斗分母） | `systems/balance.md` |
    | 神通置换 + 禁用合计 | ≈0.5（置换 : 禁用 ≈ 2 : 1） | ≈0.44% | 上层口径内 |
    | 法则置换型 | ≈0.3 | ≈0.26% | 上层口径内 |
    | 法则禁用型 | ≈0.2 | ≈0.18% | 上层口径内 |
    | **上层口径 = 持久三支合计** | **≈1.0** | **≈0.88%** | **承重表述** |
    | 四支合计（导出量 · 非闸门） | ≈2.11 | —— | 只作叙事密度 sanity check |

    三支持久支之间按「持久度 × 是否经玩家同意」两条轴分配：频次与「持久度 × 无同意」反相关——轮回级的可以最常见（神通随轮回清理、`ThisChapter` 档篇章边界自动恢复），无同意的必须最稀有。**法则禁用是唯一取低值的一格**——禁用是无同意的施加、最伤「构筑投入」契约，让出的份额转给同等严重度但有同意的置换侧（置换是正向决策点）。频次的旋钮全落内容侧、零字段零校验零状态位：带 `AbilityChangeSlots` 的 `AdventureEventData` 条目数 + 各条目的 `SelectionWeight` 档（`Rare` 已是最低档 ⇒ 主旋钮实为条目数，典型每支 1–2 条 `Rare` 档条目）+ 既有 arc 系数（`systems/services/future-event-service.md` 管线 ⑦）；`IgnoresProtection` 的旋钮是带该效果的 boss 档载体条目数与出现权重。
  - **法宝一族的失去事件同样在上层 ≈1.0 的分子内。** **法宝（`CharacterItem`）置换与法宝 / 古宝禁用一并计入上层 ≈1.0 的分子**；**具体份额归 `../../character-profile/item/` 侧裁定并回链本表**。判据是自持口径的第一条——`IgnoresProtection` 之所以能自持战斗分母，正因为**它不写 Profile**；法宝置换写 `CharacterProfile`，且法宝本就是上层口径所保护的「构筑投入」本身（与 deck、神通并列），故它触碰的恰是上层口径保护的那条心理契约。同层的神通置换（同为轮回级 build 损失、同写 Profile）在上层合计内占 ≈0.5，法宝一族排在合计之外需要一条不存在的新判据。
  - **推论 ④：量级坐实。** 法则置换 ≈0.3 / 轮回、法则禁用 ≈0.2 / 轮回——两支各自落在**一个篇章遇上一次或更少**的量级，两支合计每两个轮回一次。「我的法则会不会被拆」因此是跨篇章尺度的稀有事件，与既定的「内容级稀缺保证而非类型级绝对保证」量级吻合。

- **获取与失去的通道已闭合，本层只余内容口径（承重）。** `(Power, Player)` 域的三个合法 `Source` 已把获取通道逐一命名，每条都有现成的组装者与施加链路，**不需要任何新机制、新字段、新 element、新存档格、新存档点、新枚举**。`EventOutcome` / `ExchangePurchase` 两格是**规则层的封死**，不是「暂不开放」——账号级授予恒走「打 / 买 / 成就」三条：轮回内事件产出会改变账号级经济、绕开这三条既定渠道，且会开出一条**后端无输入可复算的账号级永久授予**（既定防作弊边界是「可复算 `roll`、不复算阈值」，三条现有渠道逐条成立）；同时它会用一条**不受 `x` 调控、随游玩时长线性增长**的平行供给旁路掉残卷那条受调控的递减曲线。「在冒险中拿到东西」的体验位由轮回级的神通 / 法宝 / 卡牌 / 功法四族完整承载，账号级这一层的定位本就是「跨轮回我强了多少」。分域校验表见 `systems/common-properties.md`。

  | # | 渠道 | `SourceCode` | 组装者 | 施加时机 / 链路 | 随机源 |
  |---|---|---|---|---|---|
  | ① | 道统残卷（Finale 通过掷中） | `Source.FinaleWin` | `CombatEventResolver` → `CombatResult.Spoils` 的一个 element | Finale 的 `eventEnd` 那一次 `TryApply` | `AccountRng.For(AccountStream.PowerFragment, FinaleWinOrdinal + 1)` |
  | ② | premium bundle（随机 1 条） | `Source.PremiumBundle` | 兑现事务（读 `BundleGrantOrdinal` 水位） | 兑现事务内一次 `TryApply` | `AccountRng.For(AccountStream.PremiumBundle, 本次 ordinal)` |
  | ③ | 成就 90% 档一次性奖励（**指定条目，非抽取**） | `Source.AchievementReward` | `AchievementManager` 采集 → `ProfileManager` 单点提交 | 达标那一次 `TryApply`，**零新增存档点** | **无随机**（`AccountStream` 刻意不为它设成员） |

  - ① ② 共用上方那段抽取与同一张 `GrantPoolWeights`；③ 走 `ExclusiveSource == Source.AchievementReward` 的专属条目、按定义不进任何抽取池 ⇒ 三者互不撞车，**成就奖励恒不落空是机械保证**。渠道 ② ③ 不推动 `x`。
  - **失去侧同样闭合**：三形态（本场移除 < 本轮回禁用 < 账号移除）的触发点、写不写 Profile、element 形态、是否需玩家同意、目标频次均见上方三形态表与四支频次表。**「具体落在哪些 AdventureEvent 上」按定义不是设计层的答案**——它是内容编排的产物，旋钮是带 `AbilityChangeSlots` 的 `AdventureEventData` 条目数 + `SelectionWeight` 档 + 既有 arc 系数，答案形态是「每支 1–2 条 `Rare` 档条目」，具体条目随内容阶段落地。
- **与 cycle seed 的关系 = 两者不相交；计分公平的刻度已有，且它是评审参考而非机械闸。** 前者是结构性的，不是口径问题：账号级掷骰不派生自 `CycleSeed`、不消耗任何子流 `State`（见上方残卷条），**反向也不成立**——法则的持有不进任何 seeded 抽取的输入（取池链只读「已持有集合」做排重、不读 seed；`status` / `disabledAbility` 更不参与取池过滤，生效维度与持有维度正交）。后者的刻度是道念净贡献占本方 `baseMomentum` 的比例（单条 ≤ 10% · 老账号全开合计 ≤ 25% · 不得随对局延长而累积），系数表与完整论据在 `systems/balance.md`；**这两个百分比落纪律阶梯第 4 级（零保证）、不得被引为任何设计的承重依据，且不为它补代理指标**——承重的是那条定性定位（偏体验改善与容错，允许影响胜负但不应成为胜负的主要来源）。
- **防 pay-grind-to-win 的护栏已有七道，逐条只回链、不复述对方设计（承重的是这张表的完备性，不是任何一行的措辞）。**

  | # | 风险面 | 护栏 | 纪律阶梯 | 权威 |
  |---|---|---|---|---|
  | 1 | 付费直接买战力 | 付费的战斗价值**主要由古宝承载**（`Charges` 是天然节流阀 ⇒「关键时刻多几次转圜」而非「永久变强」）；法则保持稀缺 | 第 4 级（分工纪律） | `systems/monetization.md` |
  | 2 | 战斗内法则泛滥 | `UsableScene` 含 `InCombat` 的法则 **≤ 1/5 条目**，加载期统计比例、超标 `PushWarning` + 报出当前比例 | **第 3 级（启动期机械检查）** | 本文件「战斗内法则的稀缺性纪律」 |
  | 3 | 付费买到强度档 | 礼包与残卷**共用同一张 `GrantPoolWeights`**（分表 = 让付费直接买到更高档强度） | 第 3 级（任一档权重为 0 → `PushError`） | `systems/balance.md`「授予池稀有度权重表」 |
  | 4 | 付费稀释元进程压力线 | 付费面五项明确排除；礼包两个抽取池的条目**一概不得产出寿元**（两条加载期 `PushError`） | **第 1–3 级** | `systems/monetization.md`「负面边界」 |
  | 5 | 付费成为必需品 | 重试上限**两档**，且**免费档是「游戏应当可通关」的基准** | 第 4 级（校准纪律） | `systems/monetization.md`、`decisions/ADR-0004-realm-checkpoint-retry-model.md` |
  | 6 | grind 无限堆叠 | 残卷的**递减供给曲线**（`Cap` / `Base` 逐档下降）+ **篇章闸门逐档累加移除** + 全局前置「未拥有法则数 > 0」+「一篇章一个 Finale、败后不可重战」⇒ **残卷不需要任何额外防刷规则** | **第 1 级（结构性）** | `systems/balance.md`「道统残卷的分档表」 |
  | 7 | 刷 / 篡改 | `FinaleWinOrdinal` 是**幂等键**；`LastRoll` / `LastEffectiveChance` 每次通过必写、供后端逐位复算；随机源是跨语言逐位一致的 SplitMix64 | **第 1–2 级（后端可复算）** | `backend-design-documents/contracts/profile-sync.md` |

  - **两条已知且已被接受的代价，如实并列（不为它们新增护栏）：** ① **礼包是一份净强度增益**——付费收益不附带「下一条法则来得更慢」的代价，这是有意为之，平衡侧按此校准；② **账号级法则总量没有硬上限**，而「老账号全开 ≤ 25%」是**零保证的评审参考**（第 4 级）。两条同时成立即意味着这道口子的最后一格没有机械兜底，全靠内容评审——**这是被接受的取向**：闸 ① 不断言任何单账号可获取上限（「单账号可获取上限」不是一个有定义的量），代理指标也已被否决（为一个不可机械校验的评审参考再加一把同样不可校验的闸，规则密度上升而保证不变）。**本层不新增任何机械闸**；若日后认为需收紧，唯一与既定纪律相容的方向是**降低供给速率**（下调残卷阈值、表结构不变）。
  - **可算的分母（这才是「按老账号全开校准」缺的东西）。** 「老账号全开」的**现实分母是 `x ≈ 9–12`，不是「池被取尽」**：`x ≥ 15` 是一条**渐近线而非可达点**（按派生量估算需 ≈74 次完整通关；`x = 9` ≈第 14 个、`x = 12` ≈第 34 个完整轮回）。校准 ≤ 25% 时按 `x ≈ 12` + 礼包所得 + 成就 90% 档所得取分母。**派生量的推导表、两个方向相反的偏差与「不得被当作独立锚引用」的题注在 `systems/balance.md`**（推导来源，不进 `.tres`、不进任何 `Resource`、待实测校准）；本处只承载它的读法。
- **`status` 开关的呈现面 = 法则列表屏一屏一列表，开关落条目的行尾操作控件。** 入口在主菜单（`ux/screen-flow.md`），写入走 `SetAbilityStatus`，**零新增存档字段、零新增服务方法**。不做分页 / 分类 tab——法则总数量级是个位到十几条，分类是为不存在的规模付版式成本。
  - 行本身复用**候选项列表语言**的统一构件，开关落其中**第七位「行尾操作控件」（仅纵向侧）**；构件表、触控目标纪律与该位的外溢判据（**仅当该行的操作是幂等的账号级开关时**才开放）的权威在 `ux/screen-flow.md`，本处不复述。
  - `status == false` 时**整行弱化但不移出列表**，与禁用态灰态呈现同款语汇（避免同一屏出现两种「不生效」的表达）。
  - **本轮回禁用的行上开关仍可操作**——`status` 与 `disabledAbility` 是两个正交维度，把开关一并锁掉会让玩家以为自己永久失去了这条法则。
  - **零 hover 通道**；描述超长走长按详情。框架文案走 `res://text/` 的 `PROFILE_` 分区（PlayerProfile 面板族），法则名 / 描述仍是内容层 `LocalizedText`，**一个字不进 `profile.csv`**。见 `ux/error-and-blocking-ux.md`。

> `status` 开关模型与 capability flag / modifier 的**声明面**见 `common-properties.md`（`ADR-0116`）；`PowerData` 字段清单见 `../../character-profile/power/_index.md`；触发器体系与效果原语语法见 `../../character-profile/deck/common-properties.md`（`ADR-0115`）。

Source: `handoffs/2026-08-30-life-lifespan-merge.md` · `handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md` · `handoffs/2026-07-24-docs-restructure-class-model.md` · `handoffs/2026-07-25b-event-cost-fields-capability-flags-and-service-hierarchy.md` · `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md` · `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md` · `handoffs/2026-08-04b-mtg-loanwords-card-types-and-intent-snapshot.md` · `handoffs/2026-08-05-level-band-stack-save-and-token-free-deck.md` · `handoffs/2026-08-06-ch1-band-widening-cross-realm-crush-and-chapter-retry.md` · `handoffs/2026-08-06b-asymmetric-ch1-band-consented-power-loss-and-chapter-retry-shape.md` · `handoffs/2026-08-06d-combat-open-questions-mass-closure.md` · `handoffs/2026-08-09b-player-power-fragment-finale-bound-drop-chance.md` · `handoffs/2026-08-10b-grant-source-and-fragment-source-scoping.md` · `handoffs/2026-08-10c-ability-disable-replacement-and-player-statistics.md` · `handoffs/2026-08-12b-grant-source-per-kind-scope.md` · `handoffs/2026-08-12e-ability-grant-draw-pool.md` · `handoffs/2026-08-16-design-audit-adjudication-and-hand-limit.md` · `handoffs/2026-08-16b-cross-library-alignment-and-bridge-ledger.md` · `handoffs/2026-08-22-finale-failure-is-death.md` · `handoffs/2026-08-25-numeric-philosophy-and-balance-anchors.md` · `handoffs/2026-08-25-info-economy-and-codex-expansion.md` · `handoffs/2026-09-06-status-vs-ownership-encoding.md` · `handoffs/2026-09-06-chapter-duration-rescale.md` · `handoffs/2026-09-06-ability-loss-frequency-budget.md` · `handoffs/2026-09-10-player-power-acquisition-and-balance.md`

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **`Rarity` 的分布与权重表。** 五档 `RarityTier` 已定名并挂上 `PowerData` / `ItemData` / `CardData`；**授予池（残卷 / 礼包）的权重表已给出结构与初值**（40/27/18/10/5，见 `systems/balance.md`）。仍待定：**战后奖励池**的各档权重（按优势档 `Tier` 三档各一张表），以及内容侧「每档应有多少条目」的编排口径。（**置换候选池不需要权重表**——它按锚定稀有度过滤后同档等概率。）→ `systems/balance.md`。
- **relic / joker 的内容条目仍为空（属内容阶段，不是设计缺口）。** 类型面已闭合：`PowerData` 字段清单（`../../character-profile/power/_index.md`）· 触发条件与效果原语语法（`ADR-0115`）· capability flag / modifier 声明面（`ADR-0116`）均已收口；缺的只是条目目录本身，开张动作归 `/scaffold-content-type player-power`。

## 对应
提炼至：`.claude/knowledge/systems/player-profile/player-power/_index.md`（待建）；`PowerData` 见 `.claude/knowledge/data/_index.md`。
