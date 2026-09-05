# character-power

> **神通 / CharacterPower** —— **轮回级**的角色能力，**对标账号级的 PlayerPower（法则）**：同一概念的两层，差别只在生命周期与获取面。
> **中文定名 = 神通**。**中文名不表达层级** —— 账号级 ↔ 轮回级的对称只在英文标识符上成立（`Player*` / `Character*`）。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **CharacterPower = 轮回级的角色能力。** 它**对标 `PlayerPower`**（账号级能力，见 `../../player-profile/player-power/`）：二者是同一个「能力」概念在两个生命周期层上的实例。由 CharacterProfile 持有，**随轮回存在、随轮回清理**。
- **「对标」的含义（可复用的形状）。** PlayerPower 已定的那套结构在轮回层同样适用，除非另有陈述：**always-available、带 `status` 开关**、通过**事件触发器施加被动修正**（relic / joker 语义）、以及 **capability flag（布尔）+ modifier pipeline（数值）**两条生效通道。**「拥有 / 失去」与「启用 / 禁用」仍是两个正交维度。** 见 `../../player-profile/player-power/common-properties.md`。（推演自「对标 PlayerPower」）。
  - **两条通道的注册面两层共用（承重）。** `CapabilityManager` 同时遍历账号级 `playerPower` 与当前角色的 `characterPower`，经同三条与门聚合成**同一份**生效能力集与**同一张**修正表——神通与法则都能授予 capability flag 与具名 modifier。**推论 ①：轮回内的 build 因此多一条战斗外的表达通道**（一个神通可以在这一局里让你看见隐藏属性 / 揭示事件类型），代价是全局可见性成为轮回级可变量、且一条轮回级条目可以改写 `ShopPrice` 一类的全局修正——这是被接受的设计取向。**推论 ②：轮回结束后角色级 flag 随重新聚合自然消失，不需要任何清理代码**；无当前角色时（主菜单）只聚合账号级那一份，是正常态、不告警。**推论 ③：`ItemData` 两类不参与聚合**（带 `Charges`、按次主动使用，效果走它自己的两格使用效果面而非常驻通道），下方生效判据表的那两行对道具恒为空集，是自洽而非例外。聚合算法、触发源与两条启动期断言见 `systems/services/profile-service.md`。
- **与 PlayerPower 的分界 = 生命周期层，而非能力种类。** 这与全库既定的拆分轴一致（`PlayerItem` ↔ `CharacterItem` 是同一条分界）：**账号级的跨轮回持久、失败不清；轮回级的随 `defeated` / `completed` 一并清理**。因此二者**不共用一份持有列表**，但可以共用同一套能力定义与生效管线。
- **神通可承载战斗内的触发式效果（承重）。** 触发式效果的载体是开放的——**牌上的触发器 / 场上的持续状态 / CharacterPower** 都可能承载。**推论 ①：轮回级能力必须能被战斗内读到**——combat-service 组装参战方时要把角色持有的神通**注册进战场（battlefield）**，触发命中后由 StackManager 压栈。**推论 ②：神通不再只是「战斗外的 build 数值」**——它在战斗内有一条直接的表达通道，与卡牌并列。见 `systems/services/combat-service.md`。
- **神通在战斗内以 `CardType.Power` 呈现，是徽记式的开局入场永久物。** 参战方组装时把神通注册进战场，**法则走同一条路径**。形态：
  - **对位 MTG 的徽记（emblem）** —— 几乎不可被针对或移除、一旦存在就一直存在。**出入**：MTG 的徽记在指挥区且不是永久物；**本作的 `Power` 就落在战场上、是永久物**，只是带 `IsProtected` 标记。**不引入指挥区**（战斗内已有六处位置，为一类不可交互的条目再开第七处，收益不抵竖屏 UI 与存档形态的成本）。
  - **入场条件是两条与门：`status == 开启` 且 `UsableScene` 含 `InCombat`。** `status` 关闭 = **不入场**，而非「入场但不生效」——前者更干净，且让战场上不出现无效条目。两个字段**正交不可合并**：`UsableScene` 是内容侧的静态属性（这个能力在战斗里有没有意义），`status` 是玩家侧的运行时开关（我要不要用它）。
  - **入场时点早于第一个开始阶段**，故「回合开始时」类触发从第 1 回合起就已挂载。
  - **一律受保护**：`IsProtected` 在落场时统一置 true，**不由 `PowerData` 逐条目声明**；**唯一后门 = 效果侧声明 `IgnoresProtection`**，其稀缺性与卡面明示**归内容侧纪律，代码不加硬规则保护**（只留 `PushWarning` 软检查）。
  - **无 mana 费用**（它不被「打出」；启动式异能的启动费另算，形态与加载期校验见 `systems/character-profile/deck/common-properties.md` 的 `AbilityData` 代价面），且**是唯一不产生弃牌堆流量、也不产生栈上「打出」事件的类型**——触发式异能照常压栈，但它自身永远不入栈。
  - **`PowerData` 字段：** `Id` · `Scope: AbilityScope { Character, Player }` · `UsableScene`（**必填**） · `Abilities`（静止式 / 启动式 / 触发式皆可） · `Rarity: RarityTier`（**必填**，缺失 → `PushError`） · `Subtypes` · `GrantedFlags: CapabilityFlag[]`（**否**，缺省空；该条目授予的 flag 集，重复声明幂等） · `Modifiers: ModifierEntry[]`（**否**，缺省空；该条目注册的具名修正，同 key 多条按合并算法求和，见 `../../player-profile/player-power/common-properties.md`）。**无 `IsProtected` 字段、无 mana 费用字段**；`status` 与 **`SourceCode`（授予来源）**仍在 Profile 侧的持有条目上（见 `common-properties.md`）。
  - **三格生效通道至少一格非空，否则 `PushError` + 条目 `Id`。** 三格即 `Abilities`（战斗内）· `GrantedFlags` · `Modifiers`（战斗外两条通道）。判据是「没有任何生效通道的条目是纯负债」——它加载期合法、运行期什么也不做，玩家拿到它等于什么都没拿到。**不能只判 `Abilities` 非空**：一件 `UsableScene = OutOfCombat`、纯靠 capability flag 或具名修正生效的法则本就是合法内容，只判一格会把它拦下。
  - **战斗外的表达面 = `GrantedFlags` + `Modifiers` 两条通道，不含触发式。** 加载期校验：**`UsableScene == OutOfCombat` 且 `Abilities` 中存在 `Kind == Triggered` 的条目 → `PushError` + 条目 `Id`**（`Both` 档不受此限——它的触发式在战斗内成立）。理由是既定纪律「一个时点必须有一处对应的广播点，而广播点是代码」的直接应用：时点常量表首批十个全部是战斗内时点，战斗外一处广播点都没有，故一条挂在纯战斗外条目上的触发式**永不触发且加载期完全合法**——正是「能上线且线上不可见」那一类，必须提到「写不出来」这一级。**日后要开是新增一族时点 + 对应广播点，纯加法、零迁移**；先开一族没有广播点的时点，得到的只是一批静默永不触发的内容。时点表见 `../deck/common-properties.md`。
  - **敌人同样持有 power**（`EnemyData` 需要一个 power 持有列表字段）——「不可被移除的场上特性」正是 boss / 天劫最自然的表达。
  - **`PowerData` 不得含 `LifeSpan` 产出（承重 · 两个 `Scope` 皆然）。** 加载期校验，违规条目 `PushError` + `Id`。**判据有两条**：① `PowerData` 没有 `Charges` 字段，一经持有即永久可用 ⇒ 一条能产寿元的能力条目就是**无次数上限的回寿源**，直接架空「`lifeSpanCost` 是控制篇章时长的主旋钮」这条承重定案；② 神通可在战斗内触发，而**战斗内不得读写这条命**——否则以生命值为终止条件的消耗战从后门回来（资源纪律见 `systems/character-profile/life-span.md`）；`Scope == Player` 一侧还额外撞上付费面「付费续命」那条排除（礼包每次给 1 条随机法则）。寿元回复只挂在**有明确次数上限的一次性消费**（法宝的 `Charges`）与**占事件位的事件产出**上，通道与护栏见 `systems/adventure-event/common-properties.md`。
- **禁用的生效判据：截断在「进入生效面」那一步（承重 · 四类通用）。** 神通 / 法则 ≈ MTG 的**静止式异能**（存在即生效），法宝 / 古宝 ≈ **启动式异能**（需主动启用）——这条分界**只用来决定禁用应当在哪一层截断，不按静止式 / 启动式收窄 `Abilities` 的取值域**（三档皆可；纯战斗外条目另受上方那条触发式校验约束）。由它得出统一判据：**禁用一律截断在进入生效面的那一步，而不是在生效面里做例外判断**，与既定的「`status` 关闭 = 不入场，而非入场但不生效」完全同构。

  | 生效面 | 被禁用时 |
  |---|---|
  | 战斗内 `CardType.Power` 入场 | **不入场**（战场上根本不出现该条目） |
  | 战斗内的「本场可用道具」 | **不进该列表**（储物袋里仍在，本场不可选） |
  | 战斗外 capability flag 聚合 | **不进生效能力集**（`CapabilityManager` 遍历时排除） |
  | 战斗外 modifier pipeline | **不进修正表** |
  | 事件触发器（relic / joker 语义的被动修正） | **不注册** |

  - **推论 ①：`Power` 的入场条件由两条与门变成三条与门** —— `status == 开启` 且 `UsableScene` 含 `InCombat` 且**不在 `disabledAbility` 内**。三字段**正交不可合并**：`UsableScene` 是内容侧静态属性、`status` 是账号级玩家开关、`disabledAbility` 是**轮回级外部抑制**。
  - **推论 ②：`Power` 入场的「可重建」依据须补上 `disabledAbility`**（`combat-service.md` 的「不落存档的可重建项」已同步修正）。禁用表就在 `CharacterProfile` 上、随存档走，**重建仍是确定性的，不需要给 `activeCombat` 新增任何字段**。
  - **推论 ③：`CapabilitiesChanged` 多了一个触发源，但不新增机制。** 禁用表写入后 `CapabilityManager` 重新聚合并广播空负载事件；因 profile-service 同时拥有两层 profile，「聚合账号级法则时要读轮回级禁用表」**不跨服务、不新增依赖边**。
  - **战斗中立即生效，但该路径当前不可达。** 规则表述是「禁用一经写入即在全部生效面上立即生效，包括进行中的战斗」；而唯一写入点是 `TryApply`、唯一施加时机是 `eventEnd`（战斗已收口），故落地是**一条不变式 + 一处断言**：施加 `Disable` 时若 `activeCombat != null` 则复用 `IgnoresProtection` 已有的战场移除路径（不新写第二条），并在 `#if DEBUG` 下 `PushWarning` 大声失败。
  - **可见性：** 角色面板 / 元进程界面**照常列出**被禁用条目（仍被持有），呈灰态 + 徽标，按 `Duration` 三档给文案「下一事件失效 / 本篇章失效 / 本轮回失效」，**长按查看来源事件**（由 `SourceInstanceId` 反查 `pastEvent`）；施加禁用的那一刻在事件结算面板上必须明确告知；**战斗屏不呈现被禁用条目**（它们不在场上，且竖屏分区已是压力最大的一处）。
  - 字段与到期规则见 `../_index.md` 的 `disabledAbility`；element 形态见 `systems/services/profile-service.md`。
- **`Power` 的战斗内运行态 = 战场条目的 `counters`，不新增结构。** 入场本身不必存档（可由两个 Profile 的持有列表 + `status` + `UsableScene` + `CharacterProfile.disabledAbility` 确定性重建）；「本场已触发 N 次」这类运行态计数器随战场条目整表进每一个决策点存档。**未入场的神通没有计数器落点，是自洽而非缺口**——三条与门任一不成立即不入场，它本场也不可能触发。键约定、值域、读档校验与消费面 API 的权威在 `systems/services/combat-service.md`。
- **神通可被置换移除。** 置换型剥夺**四类通用，但只同类型置换**——同池判据 = `(CarrierKind, Scope)` 全同 + 同 `Rarity` + 排除已持有。完整候选池与对价规则见 `../../player-profile/player-power/_index.md`。
- **每个角色自带一个神通，且与角色绑定。** 角色升格为有身份的模板 `CharacterData` 后，**神通有了第一条确定的获取渠道：开局随角色分配**——同一个角色的每一局，自带的神通都相同。**推论：神通不是「纯靠事件掉落」的浮动项**，每局至少有一个确定的起手神通，它与两门绑定功法共同构成这个角色的可辨认手感。授予落点在 life-cycle-service 的 `StartCycle`（走 `AbilityElements` 的 `Grant`，`SourceCode = Source.InitialGrant`），见 `systems/services/life-cycle-service.md`。**绑定神通可被置换换走**——角色给的是起手形状、不是永久底盘，与绑定功法同款；置换是玩家点头且拿回同 `Rarity` 等价物的正向决策点，不换走反而要主动加一条排除规则。见 `../_index.md`。
- **它是轮回内 build 的一部分。** 与 deck（卡组）、CharacterItem / 法宝（角色道具）并列——一次轮回里「我这局变强了多少」由这三者共同承载，而 PlayerPower 承载的是「跨轮回我强了多少」。
- **有自己的图鉴：CharacterPowerCodex。** 图鉴族（见 `../../player-profile/codex/`）为角色能力单列一本。**图鉴是账号级、跨轮回持久的**，而 CharacterPower 本身随轮回清理：轮回结束后能力没了，但「见过它」这条知识留下。
- **获取与失去的通道已闭合，本层只余内容口径。** `(Power, Character)` 域的四个合法 `Source` 已把获取通道逐一命名（`InitialGrant` / `CombatReward` / `ExchangePurchase` / `EventOutcome`），每条都有现成的组装者与施加链路，**不需要任何新机制、新字段、新 element、新存档格**；模板侧授予只能走 `OutcomeRule.Kind == GrantFromPool`（`PoolKind` 已收窄为 `{ CharacterItem, CharacterPower }`），取池走 `GrantPoolManager` 的 `reward` 子流，与残卷 / 礼包 / 置换共用同一段代码。战斗侧交出的授予一律记 `Source.CombatReward`（判据是「谁组装出这条 element」），挂在战斗奖励「可选逐项领取」那一类上，与「玩家选中一门功法 = `Spoils` 内一条 `DeckChangeElement`」逐格同构。→ `systems/common-properties.md` 的分域校验表、`systems/adventure-event/common-properties.md`、`systems/services/combat-service.md`。
  - **失去恰三种形态，没有第四种。** 严重度阶梯**本场移除 < 本轮回禁用 < 账号移除（仅置换、需自愿）**逐档落到神通上：本场移除 = 战斗内 `IgnoresProtection` 效果结算（战场条目被移除、本场不再触发、**不写 Profile**）· 禁用 = `AbilityChangeSlot(Op = Disable, AllowDecline = false)` 写 `disabledAbility`（仍在持有列表、灰态可见、不进任何生效面）· 置换型剥夺 = `AbilityChangeSlot(Op = Remove, AllowDecline = true)` + 同 `PairKey` 的 `Grant`（真的移出 `characterPower`，换入同 `(Power, Character)` + 同 `Rarity` 的另一条）。**`DisableDuration` 的三档时长（下一事件 / 本篇章 / 本轮回）与这条严重度阶梯正交**，不要混作一维。
  - **不开「无同意的永久剥夺」**（`Op == Remove` + `AllowDecline == false` + 空 `GainAbilityId`）。它在结构上写得出来，但在轮回级上不产生额外表达力：神通本就随轮回清理，`ThisCycle` 档禁用与永久剥夺在这一局里的可玩后果逐格相同，差别只剩「持有列表里还在不在」与「置换池排不排它」两处次要语义。为这点差别开一条分支，代价是打破 `AbilityChangeSlot` 的 `Op ↔ AllowDecline` **既有约定**（`Remove` ⇒ `true` / `Disable` ⇒ `false`），而拒绝置换零代价正靠这条约定表达。
  - **失去侧无 `SourceCode` 表达，且神通买得到、卖不掉**：`ExchangeSell` / `PackSell` / `ExchangeBarter` 在 `(Power, Character)` 域是规则层封死（神通不进任何交易面），Exchange 的可售族恒为 `CharacterItem` 一族。
  - **失去事件计入与法则共用的那一份频次预算，不另立一套。** 该预算的配平口径见 `../../player-profile/player-power/_index.md`。
- **篇章突破随「全部继承」带入，不为它单列规则。** 「读档续章带入上一篇章的全部信息、无逐项筛选」这条条款就是答案——需要论证的是「不带入」而非「带入」；`CurrentLocationId`（跨篇章不清零）与剩余寿元（跨篇章结转）是同一条条款推出的两个先例，神通是第三例。**推论：`disabledAbility` 中 `Duration == ThisChapter` 的条目在篇章边界被剔除 ⇒ 一条在 ch1 被禁用的神通，进入 ch2 时自动恢复生效**，内容侧不需要任何恢复动作。篇章边界的既有职责表不增行、`TeardownCycle()` 不新增清理步骤。→ `systems/services/life-cycle-service.md`、`decisions/ADR-0004-realm-checkpoint-retry-model.md`。
- **跨载体边界判据：什么该做成一张卡 / 一件法宝 / 一个神通（承重 · 三者共用一张表）。** 按**「这个效果要付什么代价才能生效」**排序，第一条命中即定型：

  | 提问 | 是 → 做成 | 依据 |
  |---|---|---|
  | 它要**消耗 mana、按次打出、每次生效都重新付一次代价**吗？ | **卡牌**（`Sorcery` / `Enchantment`） | 卡牌是道念的唯一产出途径；mana 与抽牌运是它的两道天然节流阀 |
  | 它要**有明确的使用次数上限**、由玩家**主动**在某一刻花掉吗？ | **法宝**（`ItemData`，`Scope == Character`） | `Charges` 是节流阀；`ItemData` 不设 `Abilities` ⇒ 它写不出常驻 / 触发式效果 |
  | 它是**存在即生效、无代价、一局内不消耗**的常驻改写吗？ | **神通**（`PowerData`，`Scope == Character`） | `PowerData` 无 mana、无 `Charges` ⇒ 凡需要节流阀的效果都写不成神通 |

  - **推论 ①：「无节流阀」是神通的定义性约束，不是它的便利。** `PowerData` 同时缺 mana 与 `Charges` 两格，故**任何随对局延长而累积的效果一律不得写成神通**（「每回合 +X 道念」「按手牌数缩放的倍率」）。这条对神通比对法则**更硬**：法则受「≤ 1/5 条目」的配额纪律与「老账号全开」的校准约束，而神通没有任何配额闸——一局拿两条累积型就能把 10 回合定长的战斗打崩。
  - **推论 ②：战斗外的效果只能写成神通，写不成法宝。** 法宝的战斗外表达力上界是「恒定、无条件、无随机」的一次性 `ProfileChangeSpec`；**改写全局设定**（capability flag / modifier pipeline）在 `ItemData` 上没有落点。故「让玩家看见隐藏属性」「商店打折」这一族恒为神通。
  - **推论 ③：回寿元的效果恒不得写成神通**（加载期 `PushError`，见上方），只能写成法宝（有 `Charges` 上限）或事件产出。
  - **推论 ④：三者共享 `RarityTier` 五档与既有的折价换算体系。** 法宝相对同 `ManaCost` 法术的效果量按 `Charges` 分层折价，是全库唯一一条已量化的跨形态强度换算；神通侧对应的强度刻度见 `systems/balance.md`。
  - **本表是三者边界的唯一权威**，`../deck/_index.md` 与 `../item/_index.md` 各留一行回链、不复述。
- **数量与强度的定性面（定量属【待内容】）。**
  - **单条神通的强度应显著高于单条法则**，而不是持平或更低。法则「轻度提升」这个定位的成因是它跨轮回单调累积、不可被针对、必须按老账号全开校准；神通这三条**一条都不成立**（随轮回清理、可被禁用 / 置换、每局从零起）。用同一档强度约束一个不累积的东西，等于让它在 build 三件套（卡组 / 法宝 / 神通）里成为最不值得关注的那一件。
  - **法则的「ch1 前段只能是纯信息 / 便利类、道念贡献为 0」不适用于神通**——它不是账号级内容，新手期不存在「被账号级内容干扰」这个问题，起手绑定神通本就是 ch1 第一分钟就在手里的东西。但**「不得随对局延长而累积」照搬且更硬**（推论 ①）。战斗内强度上沿的刻度见 `systems/balance.md`。
  - **不设持有数量的硬规则上限**，数量由内容侧的获取频次与稀缺纪律承担——与「储物袋不设条数硬上限、由 `Charges` 与内容编排天然封顶」同一条纪律。**代价明写：**战斗屏只读层的条目数因此无上限，竖屏呈现形状由 `ux/combat-ux.md` 的分区专场承接。
- **内容编排口径（首批值 · 纯内容侧，日后要改是新增 `.tres`、零结构改动）。** `content/character-power/` 开张时，其字段核对清单从本子块回链取用。

  | 口径 | 首批值 |
  |---|---|
  | 开放的 `SourceCode` 通道 | `InitialGrant` · `CombatReward`（收窄到 `combatTier ∈ { Standard, Finale }`，`Practice` 档不产神通——最轻一档也掉神通会把这条获取面稀释成常规掉落） · `ExchangePurchase`（定价表已有 `CharacterPower` 行，不新增旋钮） |
  | 不编排的通道 | `EventOutcome`（**保留机制、零条目**——一条能在任意事件 outcome 里直接塞一个神通的通道会稀释「build 增长来自打与买」这条分工，且它在物化时就已定稿、玩家看不出是奖励还是白送）；Research 维持「暂不放」（其产出面已收窄为卡组 + `manaLimit` + 隐藏属性推拉，为神通破例要动那条边界） |
  | 恒不产出的事件类 | `Travel`（纯位移事件，不该成为 build 增长面）· `Explore`（揭示的是真身，产出归真身那一类） |
  | 失去形态 | 恰三种（本场移除 / 三档禁用 / 置换），无第四种 |
  | 失去事件频次 | 计入与法则共用的那一份预算，不另立 |
  | 效果形态禁令 | 不得随对局延长而累积 · 不得产 `LifeSpan`（硬校验）· 不得提供关于敌人 / 未来 / 世界的外部情报（`vision/pillars.md` 的支柱 9；玩家对自己牌堆 / 手牌的便利类不在此限） |
  | 条目数下限 | **≥ 5**（每个在册角色一条专属绑定神通，是下方 `PowerId` 唯一性校验的直接推论） |

  - **绑定神通不填 `ExclusiveSource`**，即它照常进抽取 / 置换换入池。这让首批 5 条就能使 `CombatReward` / `ExchangePurchase` / 置换换入三条通道非空，无需为流通面另铺一批条目。**已知代价明写、不掩饰：一个角色的标志性神通会作为战利品 / 商品出现在另一个角色的轮回里**，「跨轮回熟悉感有了载体」这条价值在内容侧被稀释；要保护辨识度就得主动填这一格，而那会把首批条目量从 5 抬到「5 + 逐档若干」（置换池按 `RarityTier` 锚定，同档至少 2 条才不恒空）。
- **两条加载期校验（挂 `PowerData` / `CharacterData`，均带定位上下文）。**

  | 违规 | 处置 | 判据 |
  |---|---|---|
  | `Scope == Character` 且 `Abilities` 中存在 `Kind == Triggered` 且触发时点属**「每回合」族** | `PushWarning` + 条目 `Id` + 该时点名 | 「不得随对局延长而累积」的可机械化那一半——时点常量表是封闭表，故该子集可机械枚举。**取 `PushWarning` 不取 `PushError`**：「是否算累积」整体不可机械判定，机械化只能做到让它在启动时被看见 |
  | 在册 `CharacterData` 的 `PowerId` 出现**重复** | `PushError` + 抛，报出两个 `characterId` | 每个角色一条**专属**绑定神通：辨识度论证（同一个角色的每一局神通都相同 · 五个角色各持一个不同的单灵根）逐条指向唯一，两个角色共用一条会让辨识度直接重叠。它**不读 `ContentEnabled`**，故与「绑定条目 `ContentEnabled == false` → `PushWarning` + 该角色退池」不冲突——overlay 秒关一门坏内容仍不打崩启动 |

  **明确不做**「全库 `Scope == Character` 条目数 < 在册角色数 → `PushError`」这条总量前置检查，理由必须留在文档里：它与上方退池那条的处置正面相抵（overlay 关掉一条绑定神通即抛异常打崩启动），且在「每个角色的 `PowerId` 都解析得到」的前提下恒真、永不触发——一条写下来永不响的警报，是「能上线、线上不可见」那一类的镜像。

Source: `handoffs/2026-09-03-character-power-mechanics.md` · `handoffs/2026-08-30-life-lifespan-merge.md` · `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md` · `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md` · `handoffs/2026-08-04b-mtg-loanwords-card-types-and-intent-snapshot.md` · `handoffs/2026-08-10c-ability-disable-replacement-and-player-statistics.md` · `handoffs/2026-08-12f-cultivation-technique-deck-building.md` · `handoffs/2026-08-17f-lifespan-restoration-paths.md` · `handoffs/2026-08-22-combat-runtime-counter-persistence.md` · `handoffs/2026-08-26d-activate-ability-contract.md` · `handoffs/2026-08-27-capability-flag-and-entitlement.md` · `handoffs/2026-08-28-item-use-effect-face-and-carrier-kind.md`

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- **存在轮回级的 `CharacterPower`，对标账号级的 `PlayerPower`**。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **获取 / 失去的内容口径未定量。** 机制面已闭合（四个合法 `Source` · `AbilityChangeSlot` 的三种失去形态 · 首批通道口径见上方「内容编排口径」）；**仍待定的是频次与分布**：每条开放通道在一次轮回里应出产几条、失去型事件在与法则共用的那份预算里各占多少——归 ch1 内容编排一并定。→ `systems/adventure-event/`、`../../player-profile/player-power/_index.md`。
- **`status` 开关的存档表达。** **写入面已定**：持有列表落 `CharacterProfile.characterPower`（字段 14，`IReadOnlyList<CharacterPower>`），写入通道 = `ProfileChangeSpec.AbilityElements`，经 `profile-service.ProfileManager.TryApply(spec)`——见 `../_index.md` 的 25 字段表。**仍待定的只剩一条**：`status`（启用 / 禁用）与「拥有 / 失去」这两个正交维度如何编码进 schema。→ `systems/services/profile-service.md` 的同名待决项。
- **强度尺度的定量三格。** 定性面已答（单条显著强于法则 · 不得累积 · 不设持有数量硬上限，见上方）；**仍待定的是数字**：一次轮回预期获得几条 · 单条相对同 `ManaCost` 法术的效果量系数 · 各 `RarityTier` 档应有多少条目。三者互相咬合，需 starter deck 与功法条目规模先落地才有分母。→ `systems/balance.md`。

## 对应
提炼至：`.claude/knowledge/systems/character-profile/power/_index.md`（待建）。
