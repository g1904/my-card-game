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
- **每个角色自带一个神通，且与角色绑定。** 角色升格为有身份的模板 `CharacterData` 后，**神通有了第一条确定的获取渠道：开局随角色分配**——同一个角色的每一局，自带的神通都相同。**推论：神通不是「纯靠事件掉落」的浮动项**，每局至少有一个确定的起手神通，它与两门绑定功法共同构成这个角色的可辨认手感。**事件侧的获取 / 失去触发仍待定**（本次只答了起手那一份）。见 `../_index.md`。
- **它是轮回内 build 的一部分。** 与 deck（卡组）、CharacterItem / 法宝（角色道具）并列——一次轮回里「我这局变强了多少」由这三者共同承载，而 PlayerPower 承载的是「跨轮回我强了多少」。
- **有自己的图鉴：CharacterPowerCodex。** 图鉴族（见 `../../player-profile/codex/`）为角色能力单列一本。**图鉴是账号级、跨轮回持久的**，而 CharacterPower 本身随轮回清理：轮回结束后能力没了，但「见过它」这条知识留下。

Source: `handoffs/2026-08-30-life-lifespan-merge.md` · `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md` · `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md` · `handoffs/2026-08-04b-mtg-loanwords-card-types-and-intent-snapshot.md` · `handoffs/2026-08-10c-ability-disable-replacement-and-player-statistics.md` · `handoffs/2026-08-12f-cultivation-technique-deck-building.md` · `handoffs/2026-08-17f-lifespan-restoration-paths.md` · `handoffs/2026-08-22-combat-runtime-counter-persistence.md` · `handoffs/2026-08-26d-activate-ability-contract.md` · `handoffs/2026-08-27-capability-flag-and-entitlement.md` · `handoffs/2026-08-28-item-use-effect-face-and-carrier-kind.md`

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- **存在轮回级的 `CharacterPower`，对标账号级的 `PlayerPower`**。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **与 PlayerPower 的复用边界（承重）。** **战斗内那一半已答定**：两层**共用一个 `PowerData` 定义**，由条目上的 `Scope: AbilityScope { Character, Player }` 声明自己属于哪一层——与 `Item` 完全对称（**不按 Power / Item 分裂成两个 scope 枚举**：两个枚举值域与语义完全相同，保留两个会逼 element 侧写一层无意义的转换）。**战斗外那一半亦已答定**：capability flag / modifier pipeline 的注册面**两层共用**（见上方「对标」条）。**仍待定的只剩持有列表与清理规则的落点。** → `../../player-profile/player-power/common-properties.md`、`systems/services/profile-service.md`。
- **获取 / 失去触发。** **起手那一份已定：每个角色自带一个绑定神通**（见上）。**仍待定**：在哪些 AdventureEvent 另行获得（闭关顿悟？社交传功？秘境所得？）、能否失去、篇章突破时是否随「全部继承」一并带入下一篇章（既定的篇章继承是**全部继承**，故默认应带入——需确认）。→ `systems/adventure-event/`、`systems/services/life-cycle-service.md`。
- **与卡牌 / CharacterItem 的边界。** 三者都是轮回内的 build 组件：什么该做成一张卡、什么该做成一件道具、什么该做成一个能力？判据未给。→ `../deck/`、`../item/`。
- **`status` 开关的存档表达。** **写入面已定**：持有列表落 `CharacterProfile.characterPower`（字段 13，`IReadOnlyList<CharacterPower>`），写入通道 = `ProfileChangeSpec.AbilityElements`，经 `profile-service.ProfileManager.TryApply(spec)`——见 `../_index.md` 的 23 字段表。**仍待定的只剩一条**：`status`（启用 / 禁用）与「拥有 / 失去」这两个正交维度如何编码进 schema。→ `systems/services/profile-service.md` 的同名待决项。
- **数量与强度尺度。** 一次轮回里预期获得几个、单个的强度量级（相对 PlayerPower 的「轻度提升」定位是更强还是更弱）未定。→ `systems/balance.md`。

## 对应
提炼至：`.claude/knowledge/systems/character-profile/power/_index.md`（待建）。
