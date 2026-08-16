# character-power

> **神通 / CharacterPower** —— **轮回级**的角色能力，**对标账号级的 PlayerPower（法则）**：同一概念的两层，差别只在生命周期与获取面。占位结构，机制待一次专门 session。
> **中文定名 = 神通**。**中文名不表达层级** —— 账号级 ↔ 轮回级的对称只在英文标识符上成立（`Player*` / `Character*`）。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **CharacterPower = 轮回级的角色能力。** 它**对标 `PlayerPower`**（账号级能力，见 `../../player-profile/player-power/`）：二者是同一个「能力」概念在两个生命周期层上的实例。由 CharacterProfile 持有，**随轮回存在、随轮回清理**。
- **「对标」的含义（可复用的形状）。** PlayerPower 已定的那套结构在轮回层同样适用，除非另有陈述：**always-available、带 `status` 开关**、通过**事件触发器施加被动修正**（relic / joker 语义）、以及 **capability flag（布尔）+ modifier pipeline（数值）**两条生效通道。**「拥有 / 失去」与「启用 / 禁用」仍是两个正交维度。** 见 `../../player-profile/player-power/common-properties.md`。（推演自「对标 PlayerPower」）。
- **与 PlayerPower 的分界 = 生命周期层，而非能力种类。** 这与全库既定的拆分轴一致（`PlayerItem` ↔ `CharacterItem` 是同一条分界）：**账号级的跨轮回持久、失败不清；轮回级的随 `defeated` / `completed` 一并清理**。因此二者**不共用一份持有列表**，但可以共用同一套能力定义与生效管线。
- **神通可承载战斗内的触发式效果（承重）。** 触发式效果的载体是开放的——**牌上的触发器 / 场上的持续状态 / CharacterPower** 都可能承载。**推论 ①：轮回级能力必须能被战斗内读到**——combat-service 组装参战方时要把角色持有的神通**注册进战场（battlefield）**，触发命中后由 StackManager 压栈。**推论 ②：神通不再只是「战斗外的 build 数值」**——它在战斗内有一条直接的表达通道，与卡牌并列。见 `systems/services/combat-service.md`。
- **神通在战斗内以 `CardType.Power` 呈现，是徽记式的开局入场永久物。** 参战方组装时把神通注册进战场，**法则走同一条路径**。形态：
  - **对位 MTG 的徽记（emblem）** —— 几乎不可被针对或移除、一旦存在就一直存在。**出入**：MTG 的徽记在指挥区且不是永久物；**本作的 `Power` 就落在战场上、是永久物**，只是带 `IsProtected` 标记。**不引入指挥区**（战斗内已有六处位置，为一类不可交互的条目再开第七处，收益不抵竖屏 UI 与存档形态的成本）。
  - **入场条件是两条与门：`status == 开启` 且 `UsableScene` 含 `InCombat`。** `status` 关闭 = **不入场**，而非「入场但不生效」——前者更干净，且让战场上不出现无效条目。两个字段**正交不可合并**：`UsableScene` 是内容侧的静态属性（这个能力在战斗里有没有意义），`status` 是玩家侧的运行时开关（我要不要用它）。
  - **入场时点早于第一个开始阶段**，故「回合开始时」类触发从第 1 回合起就已挂载。
  - **一律受保护**：`IsProtected` 在落场时统一置 true，**不由 `PowerData` 逐条目声明**；**唯一后门 = 效果侧声明 `IgnoresProtection`**，其稀缺性与卡面明示**归内容侧纪律，代码不加硬规则保护**（只留 `PushWarning` 软检查）。
  - **无 mana 费用**（它不被「打出」；启动式异能的启动费另算），且**是唯一不产生弃牌堆流量、也不产生栈上「打出」事件的类型**——触发式异能照常压栈，但它自身永远不入栈。
  - **`PowerData` 字段：** `Id` · `Scope: AbilityScope { Character, Player }` · `UsableScene`（**必填**） · `Abilities`（静止式 / 启动式 / 触发式皆可，**至少一个**，否则 `PushError`） · `Rarity: RarityTier`（**必填**，缺失 → `PushError`） · `Subtypes`。**无 `IsProtected` 字段、无 mana 费用字段**；`status` 与 **`SourceCode`（授予来源）**仍在 Profile 侧的持有条目上（见 `common-properties.md`）。
  - **敌人同样持有 power**（`EnemyData` 需要一个 power 持有列表字段）——「不可被移除的场上特性」正是 boss / 天劫最自然的表达。
- **禁用的生效判据：截断在「进入生效面」那一步（承重 · 四类通用）。** 神通 / 法则 ≈ MTG 的**静止式异能**（存在即生效），法宝 / 古宝 ≈ **启动式异能**（需主动启用）——这条分界**只用来决定禁用应当在哪一层截断，不收窄 `Abilities` 的取值域**（静止式 / 启动式 / 触发式皆可）。由它得出统一判据：**禁用一律截断在进入生效面的那一步，而不是在生效面里做例外判断**，与既定的「`status` 关闭 = 不入场，而非入场但不生效」完全同构。

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
- **神通可被置换移除。** 置换型剥夺**四类通用，但只同类型置换**——同池判据 = `(Kind, Scope)` 全同 + 同 `Rarity` + 排除已持有。完整候选池与对价规则见 `../../player-profile/player-power/_index.md`。
- **每个角色自带一个神通，且与角色绑定。** 角色升格为有身份的模板 `CharacterData` 后，**神通有了第一条确定的获取渠道：开局随角色分配**——同一个角色的每一局，自带的神通都相同。**推论：神通不是「纯靠事件掉落」的浮动项**，每局至少有一个确定的起手神通，它与两门绑定功法共同构成这个角色的可辨认手感。**事件侧的获取 / 失去触发仍待定**（本次只答了起手那一份）。见 `../_index.md`。
- **它是轮回内 build 的一部分。** 与 deck（卡组）、CharacterItem / 法宝（角色道具）并列——一次轮回里「我这局变强了多少」由这三者共同承载，而 PlayerPower 承载的是「跨轮回我强了多少」。
- **有自己的图鉴：CharacterPowerCodex。** 图鉴族（见 `../../player-profile/codex/`）为角色能力单列一本。**图鉴是账号级、跨轮回持久的**，而 CharacterPower 本身随轮回清理：轮回结束后能力没了，但「见过它」这条知识留下。

Source: `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md` · `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md` · `handoffs/2026-08-04b-mtg-loanwords-card-types-and-intent-snapshot.md` · `handoffs/2026-08-10c-ability-disable-replacement-and-player-statistics.md` · `handoffs/2026-08-12f-cultivation-technique-deck-building.md`

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- **存在轮回级的 `CharacterPower`，对标账号级的 `PlayerPower`**。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **与 PlayerPower 的复用边界（承重）。** **战斗内那一半已答定**：两层**共用一个 `PowerData` 定义**，由条目上的 `Scope: AbilityScope { Character, Player }` 声明自己属于哪一层——与 `Item` 完全对称（**不按 Power / Item 分裂成两个 scope 枚举**：两个枚举值域与语义完全相同，保留两个会逼 element 侧写一层无意义的转换）。仍待定的是**战斗外那一半**：capability flag / modifier pipeline 的注册面是否也两层共用、持有列表与清理规则的落点。→ `../../player-profile/player-power/common-properties.md`、`systems/services/profile-service.md`。
- **`Power` 的战斗内运行态存档形态未定。** **入场本身不必存档**（可由两个 Profile 的持有列表 + `status` + `UsableScene` + `CharacterProfile.disabledAbility` 确定性重建）；但「本场已触发 N 次」这类**运行态计数器**须进决策点存档，字段形态未定。→ `systems/services/combat-service.md`、`sync-service.md`。
- **获取 / 失去触发。** **起手那一份已定：每个角色自带一个绑定神通**（见上）。**仍待定**：在哪些 AdventureEvent 另行获得（闭关顿悟？社交传功？秘境所得？）、能否失去、篇章突破时是否随「全部继承」一并带入下一篇章（既定的篇章继承是**全部继承**，故默认应带入——需确认）。→ `systems/adventure-event/`、`systems/services/life-cycle-service.md`。
- **与卡牌 / CharacterItem 的边界。** 三者都是轮回内的 build 组件：什么该做成一张卡、什么该做成一件道具、什么该做成一个能力？判据未给。→ `../deck/`、`../item/`。
- **写入面与存档形态。** 持有列表落在 CharacterProfile 的哪个字段、`status` 开关是否也持久化、写入是否同样经 `profile-service.ProfileManager`（应是）。→ `systems/services/profile-service.md`。
- **数量与强度尺度。** 一次轮回里预期获得几个、单个的强度量级（相对 PlayerPower 的「轻度提升」定位是更强还是更弱）未定。→ `systems/balance.md`。

## 对应
提炼至：`.claude/knowledge/systems/character-profile/power/_index.md`（待建）。
