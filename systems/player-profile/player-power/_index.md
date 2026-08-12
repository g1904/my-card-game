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
  - **上限 / 基础概率 / 适格篇章按 `x` 分档；`x` = 已拥有且 `SourceCode == Source.FinaleWin` 的法则数（08-10b 收窄口径）。** 即**只数「靠渡劫拿到的」那些**——礼包、成就奖励等其他渠道得来的法则**不计入**。`status` 开关与「本轮回禁用」同样**不影响计数**（那是生效维度不是持有维度）。**分档自变量的含义由此反转：不再是「拥有得越多，后续越难再得」，而是「靠渡劫拿得越多，后续越难再从渡劫拿到」**——理由见「与 premium bundle 的关系」。**全局前置「尚未拥有的法则数 > 0」仍按全部持有计**（池是否取尽与来源无关），故存在合法状态 `x = 0` 但池已被礼包 / 成就取尽 ⇒ 整条线静默停摆。`SourceCode` / `Source` 的共有约定见 `systems/common-properties.md`。**⚠ `Source` 已于 08-12b 从封闭三值扩为按 `(Kind, Scope)` 分域的七值清单，但 `x` 的口径与全部既有推论原样成立**——法则一侧的合法取值仍恰是 `FinaleWin` / `PremiumBundle` / `AchievementReward`（新增的 `EventOutcome` / `CombatReward` / `ExchangePurchase` / `InitialGrant` 没有一个能出现在法则上），故 `x` 不变、**单调不减 ⇒ 档位只降不回跳**不变、首胜规则 / 全局前置 / 账号级 RNG / 幂等键一概不变。**扩清单没有动残卷。** Source: `handoffs/2026-08-10b-grant-source-and-fragment-source-scoping.md` + `handoffs/2026-08-12b-grant-source-per-kind-scope.md`。**篇章闸门逐档累加地移除**（`x ≥ 5` 移除 ch1、`x ≥ 12` 再移除 ch2），**不是**「限定到某一章」。**承重的合一：适格 Finale ⟺ 该档增量 > 0 的篇章**——两张表是同一条闸门的两面，实现侧只需一张按 `(x, chapter)` 索引的表，`gain == 0` 即该篇章在该档整体退出残卷系统。这条一致性使「在某章输了却只能在别章兑现」的错位不可能出现。分档表见 `systems/balance.md`。
  - **首胜规则优先于闸门：** 某篇章的**首次 Finale 胜利**一律硬置 **100%**，即使该篇章在当前档已不适格。三次首胜是账号生命周期里三份确定的里程碑，被闸门吃掉会造成「第一次渡劫成功却空手」。（`x = 0` 因此不需要单独档位。）
  - **全局前置：** 仅当「尚未拥有的法则数 > 0」时才累积、才掷骰、才发放；池已取尽 → 整条线**静默停摆**，概率停在原值。
  - **生效概率 = `clamp(Accumulated, Base(x), Cap(x))`；发放后重置为 `Base(x + 1)`**（新档地板），**不归 0**——归 0 会让分档表的地板形同虚设。**`x` 跨档时不清空 `Accumulated`，只在读取时被新档钳制**，跨档不吞掉玩家已积累的失败。**`x` 单调不减 ⇒ 档位只会下降、不会回跳**：法则不被强制剥夺；礼包 / 成就奖励不推动 `x`；**置换所得条目继承被换出条目的 `SourceCode`**（08-10b 定），故置换对 `x` 完全中性——这正是为了**关死「用置换刷回高掉率」的通道**，见 `systems/common-properties.md`。
  - **掷骰走账号级 RNG，与 `CycleSeed` 完全解耦：** `rng = AccountRng.For(AccountStream.PowerFragment, FinaleWinOrdinal)`，`roll = rng.Randi() mod 10000`（万分比精度），命中 ⟺ `roll < 生效概率`。**具名域 `AccountStream` 是 08-12e 的修订**（原为两参数 `Hash64(AccountSeed, FinaleWinOrdinal)`）——礼包也走账号级掷骰后，两条渠道的序号会撞出同一序列；**命中判定语义不变，只是加了域**。掷中后的抽取**复用同一个 rng 实例连续抽**，故整次结算由 `(PowerFragment, FinaleWinOrdinal)` 完全确定。**绝不走 `SeedManager` 的四条子流**——它们全由 `Hash64(CycleSeed, streamName)` 派生，而篇章重试会生成全新 `CycleSeed`，挂上去等于让玩家靠重试换一次掷骰结果。**`FinaleWinOrdinal` 同时是幂等键**（同一序号重复结算得同一结果，退出重进 / push 重放都不改变掉落）。**对轮回可复现性零影响**——不派生自 `CycleSeed`、不消耗任何子流 `State`，故「残卷与 seed 公平性的关系」的答案是**两者不相交**。**执行方 = 客户端掷骰、后端可复算**（`AccountSeed` 在后端、序号与命中结果随 profile 上行），防篡改不因客户端执行而丢失，且 **Finale 奖励结算不引入任何新的网络往返**。见 `systems/common-properties.md`。
  - **玩家侧彻底隐含：** Finale 失败结算**不给任何文案 / 暗示 / 进度条 / 百分比**；唯一可见面是命中时的那一次发放（eventReward 界面上的一项奖励）。**它比既定的「隐含状态」更彻底——连隐藏属性的跨档定性叙事都不复用。**
  - **状态落点 = `PlayerProfile` 上的具名小类 `PlayerPowerFragment`**，**不并入**账号级统计计数（08-06b 已立判据：参与规则判定的字段与纯读数分属两层；残卷概率直接决定「发不发一条法则」，与 `chapterRetry` 同性质）。字段清单见 `../_index.md`。
  Source: `handoffs/2026-08-09b-player-power-fragment-finale-bound-drop-chance.md`。
- **第二条获取渠道 = premium bundle（已定案 · 08-09b 定交互）。** 付费礼包一次性给予**随机 1 个 PlayerPower**（外加随机 2 个 PlayerItem）。它与道统残卷是**同一个获取面上的两条渠道**——一条靠打，一条靠买。**二者的交互 = 完全解耦（08-10b 定）**：礼包**既不重置 `Accumulated`，也不改变档位**——礼包给的法则 `SourceCode == Source.PremiumBundle`，不计入 `x`。**「获取渠道是打还是买不改变这条曲线」这句由此被推翻**：现在渠道确实改变曲线，而这是有意为之——分档的用途是给**失败侧产出**一条递减曲线，把付费与成就奖励算进自变量等于让玩家买到的东西反过来掐死自己的残卷线。**推论：付费收益变为纯净收益**，不再附带「下一条法则来得更慢」的代价；礼包的净强度较 08-09b 上升，平衡侧需正视。礼包全貌见 `systems/monetization.md`。Source: `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md` + `handoffs/2026-08-10b-grant-source-and-fragment-source-scoping.md`。
- **已获得的 PlayerPower 会进 PlayerPowerCodex。** 图鉴族（见 `../codex/`）为 PlayerPower 单列一本——它记录「见过 / 得到过哪些能力」的静态文案，与当前**持有**的 `List<PlayerPower>` 是两回事（失去某个 power 不会从图鉴中抹去它）。Source: 同上。
- **全局设定类效果 = capability flag + modifier pipeline（已定案）。** 「让玩家看见隐藏属性」这类改变全局设定的 power，以 **capability flag（布尔）+ modifier pipeline（数值）** 两条通道实现——数据声明 → 中心聚合 → 单点查询，避免在每个受影响层加条件。模型见 `common-properties.md`。Source: 同上。

- **法则能承载战斗内触发；战斗内异能是它的第三条生效通道（已定案 · 08-04b · 承重 · 答结 08-03 的待决问题）。** 法则与神通走**同一条路径**：作为 `CardType.Power` **开局入场**（条件 = `status == 开启` 且 `UsableScene` 含 `InCombat` 且不在 `disabledAbility` 内，08-10c 补第三条与门），落在战场上、是**受保护的永久物**、可挂触发器、可带启动式异能。形态细则与 `PowerData` 字段见 `../../character-profile/power/_index.md`（两层共用一个 `PowerData`，由 `AbilityScope` 声明层级）。
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
  - **推论 ⑥（08-10b 补）：置换不改变 `SourceCode`。** 换来的条目**继承被换出条目的来源**，故置换对残卷的 `x` 完全中性——否则「换掉一条 `FinaleWin` 法则」就成了压低 `x`、刷回高掉率的通道。见 `systems/common-properties.md`。
  - **推论 ⑤：`Power` 的「受保护」语义是三层，不是两层。** `IsProtected`（战场上的可针对性）· 本轮回持有的有效性（可被禁用）· 账号持有权（**只有自愿置换能动**）。
  Source: `handoffs/2026-08-06b-asymmetric-ch1-band-consented-power-loss-and-chapter-retry-shape.md`。
- **「本轮回禁用」的承载与生效面（已定案 · 08-10c · 承重 · 答结 08-06b 留下的形态问题）。** 禁用集合落 **`CharacterProfile.disabledAbility`**——与 `pastEvent` / `chapterRetry` / `activeCombat` 平级的新字段，**不落 `Status` 内**（`Status` 是数值型运行状态，禁用表是集合型 build 状态）。
  - **三档时长 `DisableDuration { NextEvent, ThisChapter, ThisCycle }`。** 第一档定名 `NextEvent` 而非 `ThisEvent`：施加只发生在 outcome 侧（`eventEnd`，本次事件已结算完毕），「本事件禁用」等于空操作，故它实际管的是**下一次进入的那个事件**——**枚举成员的名字必须说实话**。三档因此全部有效、无死成员。
  - **生效判据 = 截断在「进入生效面」那一步**（不入场 / 不进本场可用道具 / 不进 capability 聚合 / 不进 modifier 表 / 不注册触发器），与「`status` 关闭 = 不入场」同构；**`Power` 的入场由两条与门变三条与门**。完整生效面表见 `../../character-profile/power/_index.md`。
  - **一经写入即在全部生效面上立即生效，包括进行中的战斗**；但当前链路下该路径不可达（唯一写入点 `TryApply` × 唯一施加时机 `eventEnd`），故落地是**复用 `IgnoresProtection` 的战场移除路径 + `#if DEBUG` 大声失败**，不新写中途重算参战方的代码。
  - **对玩家可见**：元进程界面照常列出、灰态 + 徽标 + 三档文案、长按查看来源事件；施加时事件结算面板必须告知；战斗屏不呈现。
  - **禁用不影响持有**：`Charges` 不动，残卷的 `x` 不受影响（生效维度 ≠ 持有维度）。**古宝同样开放到 `ThisCycle` 档**——与法则对称；不销毁、不扣次数、轮回结束即恢复，故不违反「付费内容不会被游戏销毁」。强度由**内容侧稀缺纪律**承担：**禁用古宝的事件应比禁用法宝显著更稀有，且一并计入既定的 1% 分子**（评审清单级，不加代码硬规则）。
  Source: `handoffs/2026-08-10c-ability-disable-replacement-and-player-statistics.md`。
- **置换的候选池与对价规则（已定案 · 08-10c）：排除已有 · 同稀有度 · 先看后决 · 拒绝无代价 · 四类通用但只同类型置换。**
  - **同池判据 = `(Kind, Scope)` 全同** ⇒ 四个独立池（`PlayerPower ↔ PlayerPower` / `CharacterPower ↔ CharacterPower` / `CharacterItem ↔ CharacterItem` / `PlayerItem ↔ PlayerItem`）。跨 `Scope` 置换会把账号级资产换成轮回级（隐性剥夺）或反之（白嫖账号级内容）——`Scope` 本就是「决定持久层」的字段，跨层交换等于绕过它。
  - **抽取 = `AllEnabled()` 全池 → 过滤同 `(Kind, Scope)` → 过滤同 `Rarity` → 排除已持有 → seeded 抽一条**，走 **`reward` 子流**（置换候选是一次奖励性质的内容抽取；不新增子流）。**必须走 `AllEnabled()`**，不得自写 `AllIncludingDisabled().Where(...)`。
  - **空池 → 整个置换成为空操作**（不移除、不给予）+ `PushWarning` 带 `(Kind, Scope, Rarity, characterId)`。它是「拒绝置换无代价」的自然分支；相比「降级到相邻稀有度」不引入任何新规则，且把内容缺口暴露在告警里而非悄悄改变掉落品质。
  - **置换能移除神通**（`Scope == Character` 一侧此前只是没表态；神通是轮回级、语义上无争议）。
  - **置换所得条目继承被换出条目的 `SourceCode`**（08-10b 既定）⇒ 置换对残卷的 `x` 完全中性。
  - **稀有度字段 `Rarity: RarityTier { Tier1..Tier5 }`（五档，档号越高越稀有）**，挂 `PowerData` / `ItemData` / `CardData`；缺失 → `PushError`。**类型名不得写成裸 `Tier`**——战后奖励的优势档已占用 `Tier { Narrow, Solid, Crushing }`，二者**不得复用同一枚举、也不得互相换算**。见 `systems/balance.md`。
  Source: 同上。
- **授予候选池 = 三条渠道共用的一段抽取（已定案 · 08-12e · 承重 · 答结「两条获取渠道的候选池与排重规则」）。** 残卷 · 礼包 · 置换是同一形状的授予，共用同一条取池链、同一段代码：

  ```
  DrawPool<TData> pool = Content.AllEnabled<TData>()
      .Filter(d => d.Kind == kind && d.Scope == scope)   // 四个独立池，判据同置换
      .Filter(d => d.ExclusiveSource == null)            // 去成就限定：专属条目不进任何抽取池
      .Filter(d => !owned.Contains(d.Id))                // 排重：排除已持有
      [.Filter(d => d.Rarity == anchorRarity)]           // 仅置换：锚定被换出条目的稀有度
      .PickOne(rng, weightByRarity)                      // 加权；置换侧已锚定稀有度，退化为等概率
  ```

  残卷与礼包 ① 取 `(Power, Player)`，礼包 ② 取 `(Item, Player)`；置换四类通用。
  - **「抽到重复怎么办」在结构上被消解。** 排重发生在**取池阶段而非掷骰之后**：池里根本没有已持有的条目，**抽不出重复**。这不是新选择，而是既有设计已隐含的答案——全局前置写的就是「尚未拥有的法则数 > 0 才掷骰」，它只有在「池 = 未持有集合」时才自洽。**由此 `HasGrantable()` ⟺ 按上式构造的池非空**，它与全局前置是同一个判断、不是两个；`pickedPowerId` 亦随之有定义，**08-09b 的残卷伪码就此完整可执行**。
  - **一次授予多条走无放回抽取**（`PickMany(rng, count)`），保证礼包 ② 的两件古宝不同。**无放回与加权一并成为 `DrawPool<T>` 契约的一部分**，见 `systems/services/content-service.md`。
  - **三条不过滤的维度（各有理由）：** 不按 `UsableScene` 过滤——「战斗内法则 ≤ 1/5」是内容侧的**条目比例**纪律，抽取侧再加一道等于把同一条闸门做成两处、且会让实际掉落比例偏离内容侧的编排意图；不按 `status` / `disabledAbility` 过滤——生效维度与持有维度正交（08-10c），被禁用的法则**照常算作已持有**、照常排除出池；`ContentEnabled` 的语义**天然吃进来**——线上关闭一条法则即让它退出抽取池，而玩家已持有的那条照常 `Get(id)` 解析、照常计入 `x`（它本就不在池里），无需任何额外规则。
  - **按 `RarityTier` 加权，残卷与礼包共用一张表**（权重表与初值归 `systems/balance.md`）。**共用一张表保留单一旋钮**：分表等于让付费直接买到更高档强度，与「礼包净强度已上升是被接受的」叠加两次。**权重按剩余池即时归一**（排除已持有之后再归一）⇒ 老账号的池逐渐只剩高档条目、高档占比自然上升——它与残卷的递减掉率曲线方向相反，恰好让「越往后越难拿到，但拿到的更好」，不需要为此再加任何规则。**任一档权重为 0 → `PushError`**（否则会出现「池非空但抽不出来」，让 `HasGrantable()` 说谎）。
  - **宿主 = profile-service 内的 internal `GrantPoolPicker`。** 抽取需要内容池（content-service）与已持有集合（profile-service）两样东西；后者是 profile-service 的自有状态，前者可经服务门面跨服务读取。反向（放 content-service）要求它读 `PlayerProfile`，违反「服务之间不读写对方字段」。**置换候选池复用同一 picker，只多传一个 `anchorRarity` ⇒ 全库只有一处抽取能力条目的代码。** 门面方法见 `systems/services/profile-service.md`。
  - **空池的处置按渠道分档：** 残卷 → **静默停摆**（既定，玩家侧彻底隐含）；置换 → **整个置换成为空操作** + `PushWarning`（既定）；礼包 → **三道闸 + 不补发**，见 `systems/monetization.md`。
  - **抽取结果在 spec 组装之前定稿**，`AbilityChangeElement` 只拿到已定稿的 `Id`——与「随机在 spec 组装前掷完」的既定纪律一致，无需新规则。
  - **日志**：`[GrantPool-Pick] kind=… scope=… stream=… ordinal=… poolSize=… picked=… rarity=…`。能力得失是玩家最在意、最易被投诉的一类变更，`poolSize` + `ordinal` 足以离线复算「为什么给了这条」。
  Source: `handoffs/2026-08-12e-ability-grant-draw-pool.md`。
- **禁用与置换都不出现在 `selectCost`，只出现在 outcome / reward 侧（已定案 · 08-10c · 承重 · 推翻「置换作为选择成本似乎合理」）。** `ProfileChangeSpec.AbilityElements` 在 `EventOption.SelectCost` 内**恒为空**。四条支撑：① **成本侧只放可如实计价的量**——能力得失不可计价，塞进去会让 `selectCost` 的展示从一列数字变成「数字 + 一段能力说明」；② **成本侧无条件施加，与「先看后决 · 拒绝无代价」正面冲突**——把置换塞进成本侧，兑现拒绝权只能靠「不选这个事件」，等于把一次独立的玩法决策折叠进事件选择；③ **能力得失始终是事件的后果，不是入场费**，挪到成本侧与推论 ③「置换是正向设计、是一个决策点」直接相悖；④ **它换来一条可机械检查的不变式**（`SelectCost.AbilityElements` 恒空 ⇒ 物化组装后断言 + 内容加载期校验，两处 `PushError`）。
  - **outcome 侧形态**（置换与禁用共用同一条链路）：候选在**结算时**（`eventEnd` 之前）走 `reward` 子流掷定 → 结算面板展示「失去 A · 得到 B」+ 接受 / 拒绝（禁用型只告知、无选择）→ 拒绝 = 零 element、零代价 → 接受则两条 element 并入 `eventEnd` 那一次 `TryApply`。**这是一个事件内决策点，形状与战后奖励面板完全同构，不新增机制**；**候选必须预先算定并落决策点存档**，否则退出重进可以重掷。
  - **`PastEventEntry.SelectCost` 的快照形状不受影响**（它只装资源 element）；`AppliedChange` 新增能力 element 与统计 element。
  Source: 同上。
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
- **获取触发未设计（残卷 / 礼包之外）。**（**失去的语义已定案 · 08-06b**，见上方三形态表；剩余的是形态问题，已单列。）开关 UI 亦未细化。是否还有第三条获取渠道（事件 outcome 直接给予？）未陈述。→ `systems/adventure-event/common-properties.md`。
- **`Rarity` 的分布与权重表（08-10c 立 · 08-12e 部分答结）。** 五档 `RarityTier` 已定名并挂上 `PowerData` / `ItemData` / `CardData`；**授予池（残卷 / 礼包）的权重表已给出结构与初值**（40/27/18/10/5，见 `systems/balance.md`）。仍待定：**战后奖励池**的各档权重（按优势档 `Tier` 三档各一张表），以及内容侧「每档应有多少条目」的编排口径。（**置换候选池不需要权重表**——它按锚定稀有度过滤后同档等概率。）→ `systems/balance.md`。Source: `handoffs/2026-08-10c-ability-disable-replacement-and-player-statistics.md` + `handoffs/2026-08-12e-ability-grant-draw-pool.md`。
- **relic / joker 内容为占位。** 触发条件、效果关键字、RelicData 字段清单均尚未设计，需一次 handoff。

## 对应
提炼至：`.claude/knowledge/systems/player-profile/player-power/_index.md`（待建）；RelicData 见 `.claude/knowledge/data/_index.md`。
