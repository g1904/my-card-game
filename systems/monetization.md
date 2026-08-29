# monetization（商业化）

> 付费形态与其对玩法的影响面。**当前只有一个付费点：premium bundle（付费礼包）。**

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

### premium bundle（唯一已陈述的付费点）

**可重复购买**；每次购买给予：

| 项 | 内容 | 影响面 |
|----|------|--------|
| ① | **随机 1 个 PlayerPower** | 账号级能力（`systems/player-profile/player-power/`） |
| ② | **随机 2 个 PlayerItem** | 账号级道具（`systems/player-profile/player-item/`） |
| ③ | **第二篇章重试上限 3 → 9** | ADR-0004 / `services/life-cycle-service.md` |
| ④ | **第三篇章重试上限 1 → 3** | 同上 |

第一篇章的重试**本就无限**，礼包不涉及。**① ② 每次购买都给；③ ④ 只在首次购买生效、不叠加**（见下）。

### 推论

- **重试上限首次成为可变量（承重）。** ADR-0004 的「无限 / 3 / 1」不再是常量，而是**基线值**——由账号级的礼包持有状态改写为「无限 / 9 / 3」。凡读取重试上限的地方（`RetryChapter` 的判定、篇章解锁 / 重新锁定的判断、主菜单的剩余次数展示）都要经这一层，不能硬编码常量。
- **它踩在既定的「轻度提升、PvE-only 可容忍」边界上。** PlayerPower 的既定定位（本作无 PvP，故容忍一定强度、以换取更大的设计空间）正是 ① ② 成立的前提。
- **③ ④ 是一次经确认的、有意的口径变化。** 「存档角色是一种会被耗尽的有限资源、构成元进程压力」是 ADR-0004 明写的后果；**付费放宽这条压力线是有意为之**，不是疏漏。因此设计上应正视其后果：**重试上限是元进程难度的主要旋钮，而它现在有两档**（免费 ∞/3/1 与付费 ∞/9/3）——平衡时须以**免费档**为「游戏应当可通关」的基准，付费档是宽松化而非必需品。
- **付费的战斗价值主要由古宝承载，法则保持稀缺（承重的分工）。** 法则与古宝**都能进入战斗**（法则以 `CardType.Power` 开局入场、古宝以 `CardType.Item` 存于储物袋），故礼包的 ① ② 两项**不只影响元进程，也影响战斗玩法层**。这条分工把风险收在两侧：
  - **古宝有使用次数限制** —— **次数天然是节流阀**，让付费的战斗收益是「关键时刻多几次转圜」而非「永久变强」。**这是付费战斗价值的主要承载者。**
  - **法则保持极其稀缺** —— `UsableScene` 含 `InCombat` 的法则应 ≤ **1/5**（加载时统计、超标 `PushWarning`），且强度定位偏**体验改善与容错**（信息、便利、少量兜底），而非直接抬高道念产出上限。见 `player-profile/player-power/`。
  - **不设规则禁令，代价由稀缺性承担** —— premium bundle 是花钱买的，理应让体验更好，而战斗是核心体验的关键一环；用内容配额而非硬编码规则表达这条边界。
  - **它同时满足「花钱体验更好」与「不滑向 pay-to-win」，不需要任何新机制。** 但**法则不可被针对且跨轮回永久持有**，其价值随账号年龄单调累积——平衡时须按「**老账号全开**」校准难度曲线，见 `systems/balance.md`。
- **付费获得的法则不会被游戏销毁（承重）。** 事件侧「失去法则」**永远不强制剥夺**：真正从账号移除只发生在**玩家自愿接受的置换**中（有对价，例如换成另一条法则），其余事件一律降级为**「本轮回禁用」——不从账号删除**。**推论：「花钱买到的东西可能被一个事件拿走」这条风险彻底关闭**，它免去了一整类客诉与退款争议，并让「失去法则」成为一条有梯度的压力线（本场移除 < 本轮回禁用 < 自愿置换）而非二元惩罚。**置换本身是卡组构筑式的取舍，是正向设计而非负向条目。** 见 `player-profile/player-power/`。
  - **古宝同样开放到「本轮回禁用」的 `ThisCycle` 档——这不构成冲突。** 禁用**不销毁、不扣 `Charges`、轮回结束即恢复**，与法则可被本轮回禁用完全对称；对法则开放而对古宝不开放，反而会让内容侧多背一条「哪些层能用哪些档」的例外表。但它确实是对付费内容的一次**可感知削弱**，故补一条**内容侧纪律**：**禁用古宝的事件应比禁用法宝显著更稀有，且一并计入既定的 1% 分子**——评审清单级，不加代码硬规则，与 `IgnoresProtection` 的 1% 同性质。
- **随机 PlayerPower 与道统残卷共用同一个获取面，但二者完全解耦（承重）。** 残卷是 Finale 失败累积、Finale 通过掷定的 PlayerPower 掉落概率（见 `player-profile/player-power/`）。
  - **礼包不重置 `Accumulated`** —— 重置只发生在残卷自己掷中并发放时。
  - **礼包也不改变残卷的档位。** 残卷的分档自变量 `x` **只数 `SourceCode == Source.FinaleWin` 的法则**（即「靠渡劫拿到的」），礼包给的法则 `SourceCode == Source.PremiumBundle`，**不计入 `x`**。
  - **获取渠道是打还是买，确实改变这条曲线，且这是有意为之。** 分档的用途是给**失败侧产出**一条递减曲线；把付费与成就奖励算进自变量，等于让玩家买到的东西反过来掐死自己的残卷线。
  - **付费收益是纯净收益，这是设计意图**——**不附带「下一条法则来得更慢」的代价**，付费与元进程之间没有这条负反馈。它仍与「付费是增值而非必需」同向（礼包不改变失败侧的推进速度），但**礼包因此有一份净强度增益，这是被接受的**，平衡时按此校准。
  - **成就奖励同款处理**：`AchievementReward` 得来的法则同样不计入 `x`，不压低残卷掉率（见 `player-profile/achievement/`）。
- **① ② 的「随机」= 与残卷 / 置换共用的那一段抽取。** 取池链、加权与无放回语义的权威在 `player-profile/player-power/_index.md`；此处只记礼包侧的口径：
  - **① 从 `(Power, Player)` 池抽 1 条、② 从 `(Item, Player)` 池抽 2 件**，均已**排除已持有**（故第二次礼包不可能给到与第一次相同的条目）、已**排除成就限定条目**（`ExclusiveSource != null`）、按 `RarityTier` **加权**（与残卷**共用同一张权重表**——分表等于让付费直接买到更高档强度，与「礼包净强度已上升是被接受的」叠加两次）。② 的 2 件走**无放回**抽取，保证两件不同。
  - **掷骰走账号级 RNG 的 `PremiumBundle` 域**：`AccountRng.For(AccountStream.PremiumBundle, ordinal)`，一次派生、3 条连续抽 ⇒ 整次授予由 `(域, 序号)` 完全确定，退出重进 / push 重放不改变结果。随机源是契约定义的纯函数 SplitMix64（`AccountStream.PremiumBundle = 1` 已冻结），见 `systems/common-properties.md`。`ordinal` 取本次要兑现的那个序号（见下方兑现事务），其上界 `BundleGrantOrdinal` 落 `PlayerEntitlement`，JSON path `/entitlement/bundleGrantOrdinal`（账号级、单调递增、不清零、**由后端在验票事务内推进，经 pull 下行进入客户端内存态**）。
  - 授予时照常携带 `Source.PremiumBundle`（授予通道强制带来源，见 `systems/common-properties.md`）。
- **空池 = 三道闸 + 不补发（承重）。** 礼包与残卷 / 置换有本质区别：**它是玩家付过钱的**。静默少发一条法则 = 收了钱没给货，是客诉与退款级别的问题，且在「强制在线 · 云端权威」下后端必须能看见这件事。既定的「付费内容不会被游戏销毁」讲的是**已授予**的不被拿走；本条补的是**未授予**的不被吞掉。

  | # | 时机 | 判定 | 失败处置 |
  |---|---|---|---|
  | ① | **内容加载期**（合并后强校验阶段） | `(Power, Player)` / `(Item, Player)` **通用池**条目数 ≥ **礼包所需（1 / 2）+ 可调编排余量**（成就限定条目不计入通用池） | **`PushError`**——内容侧硬保证的机械化，越界必须在启动期就大声失败 |
  | ② | **购买入口**（进入付费流程之前） | 当前账号的可授予池 ≥ 礼包所需（1 法则 + 2 古宝，均已排除已持有） | **购买入口不可用 / 拒绝进入付费流程** + `PushError` + 上报。**这是「不收钱又不给货」的真正防线**——把失败点挪到掏钱之前，从「退款争议」降级为「暂不可购买」 |
  | ③ | **兑现结算**（`spec` 组装时） | `TryPickGrantable*` 是否成功 | 理论不可达（② 已拦）。真发生 → `PushError` + 上报 + 该项计未兑现，**不补发、不折价、不降级替代**；③ ④ 两项重试上限不依赖内容池，照常兑现 |

  - **闸 ① 只断言「礼包所需 + 余量」，不断言任何「单账号可获取上限」。** 残卷在 `systems/balance.md` 的三表中**没有账号级上限**（`x ≥ 15` 档仍有 `Gain = +1%` / `Cap = 5%`），且「池已取尽 → 静默停摆」本就是它的**既定正常终局**——因此「单账号可获取上限」不是一个有定义的量，闸 ① 不能建立在它之上。收窄后闸 ① 保住了唯一真实的目的（保护付费兑现）且可机械校验。**残卷把池抽干仍按静默停摆处理，不是事故。**
  - **否决**：为残卷设账号级硬上限（新机制，且与「池取尽 → 静默停摆」重复承担同一职责）；只在兑现处报错而不做前置拦截（让玩家在**付款之后**才撞上失败，是最糟的失败时机）；以灵石 / 其他资源折价补偿（本作没有账号级可支配货币，为兜底引入一条等于新开一套经济，与残卷「不发放账号级货币」同一条理由）。
  - **推论：购买入口多一条可用性前置条件**——它并入下方的**四条前置条件表**（不新增拦截点）；入口的 UI 态为**置灰 + 说明、不隐藏**，见 `ux/error-and-blocking-ux.md` 的灰态判据。
  - **玩法内容侧另有一组三道闸，失败处置方向相反（降级到更少而非拒绝进入）；分界判据 = 玩家有没有为这一次产出付过钱，本体见 `systems/services/future-event-service.md`。** 不复述那一侧的规则——两处看似相反，边界只在那一处写一遍。
  - **内容侧硬纪律**：两个通用池的条目总数必须显著大于礼包所需；闸 ① 是它的机械化检查，与 `UsableScene ≤ 1/5` 的比例检查同一处落地。**空池是运营事故，不是玩法分支**——不为它设计兜底玩法。线上 flags 秒关导致的运行时池收缩由闸 ② 兜住，不需要额外规则。
- **持有状态 = `PlayerProfile.entitlement: PlayerEntitlement`，类内只放付费凭证本身与其兑现水位，不放任何派生量（承重）。** 字段形态、层归属与读档校验的权威在 `systems/player-profile/_index.md`；此处只记本系统侧的判据：
  - **否决 `CapabilityFlag`**：唯一授予源是 PlayerPower 条目（礼包没有宿主条目）· 它是布尔呈现开关而 ③ ④ 要数值 · **致命的一条**——生效能力集受轮回级禁用截断，把付费凭证放进一个设计上就允许被截断的聚合面，是在结构上给「花钱买的东西被事件拿走」留后门。
  - **否决 modifier pipeline 的具名修正**：同受同一条截断（两者由同一个 `CapabilityManager` 聚合）；且 modifier 的定位是**法则对数值的软修正**——让一条法则与一份付费凭证写同一张表，等于承认法则可以改写付费权益。
  - **共同判据（承重）：capability / modifier 都是由内容条目聚合出的派生态，付费凭证是账号上的原始事实——派生态不能承载原始事实。** 付费凭证必须是**硬状态**：不参与 pipeline、后端可复算。
  - **不落客户端**：订单号 / 平台 SKU / 收据 / 购买时间 / 金额。它们是**审计凭证**、权威在后端；落进客户端存档既不可信，又会诱导出「客户端拿订单号做判断」的写法。客服排障的既定出口是设置屏「同步版本 #N」+ 后端订单库。
- **一次授予 = 一次 `TryApply`，序号由后端下行的水位差给出（承重）。** 触发点是主菜单、一次 pull 完成之后；客户端**从不推进** `BundleGrantOrdinal`，它只把兑现水位 `BundleRedeemedOrdinal` 一格一格推到与之追平。

  ```
  while (profile.Entitlement.BundleGrantOrdinal > profile.Entitlement.BundleRedeemedOrdinal)
  {
      ordinal = profile.Entitlement.BundleRedeemedOrdinal + 1   ← 逐一按序，客户端不做任何 +1 到 Grant 上
      rng     = AccountRng.For(AccountStream.PremiumBundle, ordinal)
      picked  = TryPickGrantable(Power, Player, rng) + TryPickGrantableMany(Item, Player, rng, 2)
      spec    = { Elements:        [ BundleRedeemedOrdinal := ordinal ],
                  AbilityElements: [ Grant(picked…, Source.PremiumBundle) ] }
      ProfileManager.TryApply(spec)                             ← 全有或全无，一次事务
  }
  ```

  - 随机在 **spec 组装之前掷完**（既定纪律：`AbilityChangeElement` 只承载已定稿的 `Id`）。
  - **为什么是循环而不是「一次追平到 `Grant`」。** 差值恒 ≤ 1 只在**单设备**下成立——它由购买入口的前置条件维持，而那条读的是本地 pull 快照，挡不住两台设备各自付款。一次跳到 `Grant` 会让中间那个序号**永不被兑现**：玩家付了两次钱只拿一份货，正是本节要防的那件事。差值为 1 时循环体只跑一次，与「直接取 `Grant`」逐字等价。
  - **差值 > 1 属异常但可发生**：`PushError` + 上报，然后照常逐一按序兑现，**不合并成一次事务**——合并会让 `AccountRng` 的 `(域, 序号)` 失去逐次对位。
  - **序号推进与「是否抽中」无关。** 闸 ③ 真发生时（理论不可达）该项计未兑现、不补发，但 `BundleRedeemedOrdinal` **照常置为 `ordinal`**——否则客户端会永远认为自己欠一次兑现，每次启动重掷同一 `ordinal`、抽空池、反复报错。
  - **兑现的 push 失败不阻塞**（既定：push 失败一律不阻塞玩家，`Immediate` 不改变这一条）。已提交的本地事务保证退出重进不回滚；水位已置，不会重兑。
  - **幂等靠水位字段，不靠「重掷同一 `(域, ordinal)` 会得到相同结果」（承重）。** 后者是最诱人的错误答案，且**不成立**：取池已排除已持有，第一次授予之后池子就变了，同一 rng 会抽到**不同**条目 ⇒ 重兑 = 多发，不是幂等。**也不靠「数 `Source.PremiumBundle` 的条目数反推已兑现次数」**：闸 ③ 下序号推进但无条目、自愿置换会移除付费法则、古宝可被消耗——派生量不可靠即不能当幂等键。
  - **该 element 在 `ResourceElements` 表中两个修正列均为空**，故不经 modifier pipeline——这不是本系统的个案例外，而是**通则的缺省**（`Elements` 缺省豁免、只有表中显式登记 `ModifierKey` 的那一行才经）。判据在此处最尖锐：**经 pipeline = 一条法则能伪造兑现记录**。通则、表与逐行取值见 `systems/services/profile-service.md`。
  - **`BundleGrantOrdinal` 在 `ResourceElements` 表中没有行，也不是 `CostKey` 成员（承重）。** 表里的行只为**客户端施加路径**而存在，而客户端永不组装带这个 key 的 element；缺行即命中既有失败语义「`ChangeElement.Key` 无对应行 → `PushError` + 整批拒绝」，**任何日后误写的客户端置位当场在施加时大声失败**，不需要为此新增任何断言或注释。**否决「保留该行但把 `AllowedOps` 置空」**（违反既有启动期断言「每一行的 `AllowedOps != 0`」）；**否决「保留该行、标注 backend-only」**（`ResourceElements` 是**客户端施加语义**的表，表里不存在「后端写入」这一语义位，引入它等于在这张表上开第二种读法——后端写入的落点是 pull 下行的整份 profile，根本不经 `TryApply`）。
  - `SavePointReason` 取 `MetaChanged`、`PushPolicy` 取 `Immediate`，均为既有枚举。
- **购买段后端权威 · 兑现段客户端演算，且整条流程只在主菜单发起（承重）。**

  | 段 | 谁做 | 内容 |
  |---|---|---|
  | **① 购买段** | 平台 SDK + 后端 | 唤起平台内购 → 收据 → 上行验票 → **后端**把云端 `bundleGrantOrdinal` +1、`cloudRevision` +1 |
  | **② 兑现段** | 客户端（后端复算） | 客户端 **pull** 到新序号 → 用 `(PremiumBundle, ordinal)` 掷骰抽 3 条 → 一次 `TryApply` → `Immediate` push；后端以同一 `(AccountSeed, stream, ordinal)` 复算校验 |

  - **验票端点的报文、幂等口径与服务端保证的权威在 `backend-design-documents/contracts/purchase.md`**（验票由后端向平台校验、写入只由 verify 承担、渠道回调只作对账；平台收据 id 是幂等键，同一张票重复提交绝不重复 `+1`）。本文件只写客户端这一半，不复述报文。
  - **购后 pull 失败 ⇒ 阻塞在主菜单重试直到成功**，不允许在未兑现状态下开始新轮回；重试走该契约的收据幂等读，`receiptId` 随待兑现态持久化。**正确性由 `/entitlement` 两字段之差承载，本地待兑现态只是加速补查的优化**——跨启动补入口是「每次启动 pull 后比较 `Grant > Redeemed`」，不依赖本地态是否还在。形态与否决项见 `systems/services/sync-service.md`。
  - **购后等待期的呈现 = Store 流程内的全屏模态进度态**（进度指示 + 重试 + 退出应用，文案走 `STORE_` 分区），**不是阻塞屏的第四个变体**；兑现完成后同屏切到兑现结果态。判据与形态见 `ux/error-and-blocking-ux.md` 与 `ux/screen-flow.md`。**无硬超时、永不放弃**——「超时后放弃」= 收了钱不给货，玩家最坏体验是「稍后回来」而不是「钱没了」。

  - 「谁有权把 `BundleGrantOrdinal` 从 n 推到 n+1」**只能是后端**，否则整套防篡改归零。**否决客户端自行置位 + 后端事后校验**（客户端置位 = 客户端有权发货；事后发现不一致时玩家已拿到东西，回收比不发更糟），**否决兑现也放后端做**（`AccountRng` / `GrantPoolPicker` 要在两侧各实现一遍，与既定的「客户端掷、后端复算」分裂成两条路径）。
  - **⚠ 它引入同步模型此前没有的第四种情形：后端主动写入。** 时机纪律与它关闭冲突窗口的机理见 `systems/services/sync-service.md`；本系统侧只承接其结果——**购买入口在轮回内 / 战斗内 / 结算流程内不存在**。
  - **购买入口的前置条件表（四条全满足才可点；闸 ② 并入此表，不新增拦截点）：**

    | # | 条件 | 不满足时 |
    |---|---|---|
    | 1 | 当前在主菜单（不在任何轮回内） | 入口不渲染 |
    | 2 | 待发队列为空（或一次 `FlushPendingAsync` 成功） | 入口置灰 + 「请先完成同步」 |
    | 3 | `GrantableCount(Power, Player) ≥ 1` 且 `GrantableCount(Item, Player) ≥ 2` | 入口置灰 + 说明 + `PushError` + 上报（既定闸 ②） |
    | 4 | `BundleGrantOrdinal == BundleRedeemedOrdinal`（无待兑现） | 入口置灰 + 「上一笔购买正在发放」 |

    条件 4 是不变式 `Grant - Redeemed ≤ 1` 在单设备下的维持者；在待兑现状态下允许再次付款，会把一个待发放问题叠成两个。**它是往这张既有的表里加一行，拦截点数量不变**（表本身就是那个拦截点）。
- **购买形态 = 可重复购买；① ② 每次都给，③ ④ 只在首次生效、不叠加。**
  - **否决「一次性不可重复」**：商业化封顶为一次性小额，与「重账号 + 强制在线 + 长期运营」的路线不匹配，且让闸 ② 几乎永无用武之地。
  - **否决「③ ④ 叠加」**：花钱买接近无限的重试 ⇒ 抹平 ADR-0004 唯一的失败压力线，与「免费档是基准、付费是宽松化而非必需品」正面冲突。
  - **两条依据**：① **取池链本身已假定了重复购买**——它明写「按排重，第二次礼包不可能给到与第一次相同的条目」并为池不足设了闸 ②，而一次性购买几乎不可能抽干通用池，**闸 ② 只有在可重复形态下才有真实意义**；② ③ ④ 不叠加的理由本文件自己写着——重试上限是元进程难度的主要旋钮，两档是有意的口径变化，第三档、第四档就不是了。
  - **诚实性纪律（承重）**：第二次及以后的购买，**UI 必须在付款前**如实标注「本次仅含随机 1 法则 + 2 古宝；重试上限已达上限，不再提升」。付了钱却没拿到宣传的四项之二是退款争议的标准形态——与「把失败点挪到掏钱之前」同一条纪律。
  - **定价：起步单一 SKU、单一价格档**；金额属发行侧，**不落客户端**（价格与货币由平台商店按 SKU 返回，客户端不硬编码任何金额）。多档 SKU 会立刻牵出「哪档给什么」的内容编排，而内容池规模尚未明朗。
  - **连带：闸 ① 的口径改写为「支撑 K 次重复购买」**，余量语义变为「留给第 K+1 次的缓冲」；`K` 与 `GrantPoolMargin` 数值仍待内容规模明朗（见 `systems/balance.md`）。
- **付费面的边界：五项明确排除 + 一个唯一预留方向（负面边界）。**

  | 排除项 | 理由 |
  |---|---|
  | **付费续命 / 复活**（花钱撤销一次 `defeated`） | **最强的一条**：ADR-0004 明写「存档角色是一种会被耗尽的有限资源、构成元进程压力」。付费续命不是放宽这条压力线（③ ④ 那样、有档、有上限），而是**按次取消**它——pay-to-win 滑坡的教科书形态。**它的软形态已被结构性关死**：礼包两个抽取池的条目一概不得产出寿元（`ItemData.Scope == Player` 与 `PowerData` 各一条加载期 `PushError`），否则「花钱 → 抽到 → 续寿」等价于按次稀释同一条压力线——没有「撤销一次 `defeated`」，只是让它更晚到来。见 `systems/character-profile/item/_index.md`、`systems/character-profile/power/_index.md` |
  | **抽卡 / 扭蛋 / 随机付费箱** | 本作的随机授予是**买断式一次授予**（付了钱必得 1+2、排重、三道闸保兑现），与「反复付费抽同一个池」形态相反；且概率公示 / 未成年人限额的合规成本高 |
  | **消耗型货币 / 硬通货** | 已被「本作没有账号级可支配货币」关死；「为兜底引入一条」等于新开一套经济，已否决 |
  | **体力 / 付费加速** | 本作无体力、无 grind、无等待——没有可被加速的对象 |
  | **广告变现（激励视频）** | 与买断式增值路线不冲突但稀释格调，且「看广告换重试」等价于付费续命的免费版本 |

  - **唯一预留方向 = 纯外观**（角色皮肤 / 卡背 / 界面主题）：唯一零玩法影响、可无限扩展、不触及任何平衡讨论的付费面。**架构预留、首批不做**——首批不新增任何字段、不新增任何屏；落地时 = `PlayerEntitlement` 加一个具名字段 + bump 一次 schema，不需要该类之外的新机制。做成哪些外观仍待定。
  - **通行证 / 赛季：当前不做**——它要求先有赛季结构与持续内容产能，而本作当前没有赛季结构。若将来做，须先答「赛季是什么」，不能反过来。
- **UX 观感 = 安静的一等入口 + 绝不在失败时刻推销。** 入口位置、三条呈现纪律与灰态判据的权威在 `ux/screen-flow.md` 与 `ux/error-and-blocking-ux.md`；此处只记本系统侧的两条结论：
  - **重试次数耗尽时不提示购买**，两条独立理由——① 那是玩家刚失去一个角色的时刻，此处推销正是「付费才玩得下去」观感的经典成因，且会把 ③ ④ 从「宽松化」在观感上变成「解锁继续游玩」；② **它在结构上本就不可行**（购买只在主菜单发起、待发队列为空，而重试耗尽是轮回内 / 结算流程内的时刻）。
  - **允许的全部呈现穷举为三处**：主菜单入口本身；礼包详情页内如实列出四项权益（及第二次起的删减说明）；**兑现结果态**（列出本次获得的 1 法则 + 2 古宝）。这句穷举约束的是**推销面**——兑现结果不是推销：它发生在付款之后、内容已定，且「付了钱看不到货」与本文件反复出现的诚实性纪律正面相悖，也是退款争议的常见诱因。

Source: `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md` · `handoffs/2026-08-04b-mtg-loanwords-card-types-and-intent-snapshot.md` · `handoffs/2026-08-06b-asymmetric-ch1-band-consented-power-loss-and-chapter-retry-shape.md` · `handoffs/2026-08-10b-grant-source-and-fragment-source-scoping.md` · `handoffs/2026-08-10c-ability-disable-replacement-and-player-statistics.md` · `handoffs/2026-08-12e-ability-grant-draw-pool.md` · `handoffs/2026-08-15b-monetization-entitlement-purchase-shape-and-scope.md` · `handoffs/2026-08-16b-cross-library-alignment-and-bridge-ledger.md` · `handoffs/2026-08-16f-elements-modifier-pipeline-opt-in.md` · `handoffs/2026-08-17f-lifespan-restoration-paths.md` · `handoffs/2026-08-19-bundle-grant-ordinal-authority.md` · `handoffs/2026-08-19-pickmany-shortfall-handling.md`

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- **premium bundle = 唯一已陈述的付费点；重试上限是基线值而非常量**（付费放宽为有意的口径变化，见 `decisions/ADR-0004-realm-checkpoint-retry-model.md`）。**上限的载体形状与选行链路** → `decisions/ADR-0117-chapter-retry-limit-carrier.md`（Accepted：两档表住 `ChapterRetryLimitsData`、按 `HasPremiumBundle` 选行、**不新增任何存档结构**）；**计数落 `CharacterProfile.chapterRetry`** → `decisions/ADR-0101-chapter-retry-counter-carrier.md`（Accepted）。
- **付费凭证 = `PlayerEntitlement` 的两字段（后端写的授予序号 `BundleGrantOrdinal` + 客户端写的兑现水位 `BundleRedeemedOrdinal`）；序号只由后端推进、兑现由客户端逐一按序演算、只在主菜单发起；可重复购买且 ③ ④ 不叠加；付费面五项明确排除** → `decisions/ADR-0023-premium-entitlement-and-redemption.md`（Accepted）。
- **平台内购三渠道（Google Play Billing / App Store / 微信支付）纳入 MVP** → `decisions/ADR-0024-in-app-purchase-channels-in-mvp.md`（Accepted）。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **`GrantPoolMargin` 的数值与 `K`。** 闸 ① 的口径已改写为「支撑 K 次重复购买 + 留给第 K+1 次的缓冲」，**结构已定、数值待内容规模明朗**。→ `systems/balance.md`。
- **纯外观付费点做成什么。** 架构预留、首批不做已定；做成角色皮肤 / 卡背 / 界面主题的哪些、落成 `PlayerEntitlement` 的哪个具名字段形状，仍未定。通行证 / 赛季已明确「当前不做」。
- **合规。** 付费与实名 / 防沉迷 / 渠道分成 / 退款的交互归后端与合规侧；客户端不读年龄、不做任何本地拦截，只承接后端 `code` 展示对应 `ERR_*` 文案。→ `backend-design-documents/`。
- **平台内购 SDK 的选型与封装层（不在本库定稿）。** Google Play Billing / App Store / 微信支付三渠道**纳入 MVP**（见 `vision/scope.md`），它们是客户端**唯一必须引入第三方 SDK 的地方**，牵动 Godot 导出配置与各平台构建。SDK 选型、封装层形态与三渠道的收据差异归后端的支付渠道选型（`backend-design-documents/`）与一次专门的客户端工程蓝图；本方案的时序不受其形态影响——唤起内购失败（用户取消 / SDK 失败）一律回主菜单，无任何 Profile 变更、无痕迹。

## 对应
提炼至：`.claude/knowledge/systems/monetization.md`（待建）。
