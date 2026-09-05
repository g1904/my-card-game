---
type: solution-draft
date: 2026-09-03
question: CharacterPower（神通）的机制细节——与法则的复用边界 · 事件侧获取 / 失去触发 · 篇章突破是否带入 · 与卡牌 / 法宝的边界判据 · 数量与强度尺度
source: open-questions/07-codex-monetization.md → 第 1 条「`CharacterPower`（神通）的机制细节（概念已定，待专场）」
targets: systems/character-profile/power/_index.md · systems/character-profile/power/common-properties.md · systems/character-profile/item/_index.md · systems/character-profile/deck/_index.md · systems/services/life-cycle-service.md · systems/balance.md · systems/player-profile/player-power/_index.md
status: distilled
reviewed: 2026-09-03 — 批量评审：取向 1 → A（不设持有数量硬上限）· 取向 2 → A（绑定神通可被置换换走）· 张力 1 本批不裁决，登记为 ch1 内容编排待处理项。合并 interview 追加五项：绑定神通不填 ExclusiveSource（辨识度稀释的代价明写）· 战斗内强度上沿取 baseMomentum 比例刻度、不设合计总闸 · 校验 P-b 改写为 PowerId 唯一性硬规则 · 校验 P-a 改挂 Abilities 侧（本稿原文挂 ModifierKey 恒不触发）· 本次不碰 content/（character-power 类型尚未开张，内容口径暂住 power/_index.md）
distilled-to: handoffs/2026-09-03-character-power-mechanics.md
---

# 方案草稿 — 神通 `CharacterPower` 的机制细节

## 问题

「轮回级角色能力、对标 `PlayerPower`（法则）」这条概念早已定案并建档，此后又追加了两条：神通可承载战斗内触发式效果（08-03）、每个角色自带一个绑定神通（08-12f，`ADR-0055`）。**留在待答清单上的是五个子项**（`systems/character-profile/power/_index.md` 的「待决问题」逐条对应）：

1. **与法则的复用边界** —— 战斗内那一半（共用 `PowerData` + `AbilityScope`）与战斗外那一半（capability flag / modifier pipeline 注册面两层共用）**都已答定**；文档自陈「仍待定的只剩持有列表与清理规则的落点」。
2. **事件侧的获取 / 失去触发** —— 起手那一份已定（角色绑定），其余在哪些 AdventureEvent 发生、能否失去，未表态。
3. **篇章突破是否随「全部继承」带入下一篇章** —— 文档写着「默认应带入,需确认」。
4. **与卡牌 / 法宝的边界判据** —— 三处文档同时记着「判据未给」。
5. **数量与强度尺度** —— 一次轮回预期获得几个、单条相对法则「轻度提升」定位是更强还是更弱。

它卡住的是：`content/character-power/` 的类型档案状态已是 🟢（字段清单与效果语法均已定），但**内容侧无法开始编排**——不知道一局里该出现几条、该有多强、该从哪来、什么样的效果该写成神通而不是一张牌或一件法宝。同时 `content/character/` 的五个角色条目阻在「功法与神通条目」上，整条 ch1 内容链在此处收窄。

## 约束（来自既有设计）

- **两层共用一个 `PowerData`**，由条目上的 `Scope: AbilityScope { Character, Player }` 声明层级；`PowerData` 无 `IsProtected` 字段、无 mana 费用字段、**不得含 `LifeSpan` 产出**（加载期 `PushError`）。→ `systems/character-profile/power/_index.md`
- **三格生效通道至少一格非空**（`Abilities` / `GrantedFlags` / `Modifiers`）；**`UsableScene == OutOfCombat` 且含 `Kind == Triggered` 的 `Abilities` → `PushError`**（战斗外一处广播点都没有）。→ 同上
- **入场三条与门**：`status == 开启` ∧ `UsableScene` 含 `InCombat` ∧ 不在 `disabledAbility` 内；落场即 `IsProtected = true`，唯一后门是效果侧 `IgnoresProtection`（`ADR-0106`，内容侧纪律，代码只留 `PushWarning`）。→ 同上
- **禁用一律截断在「进入生效面」那一步**（五行生效判据表），不在生效面里做例外判断。→ 同上
- **持有条目形态已定**：`readonly record struct CharacterPower(string PowerId, bool Status, Source SourceCode)`，落 `CharacterProfile.characterPower`（**当前 25 字段表的第 14 格**），写入通道 `ProfileChangeSpec.AbilityElements`，唯一写入面 `profile-service.ProfileManager.TryApply(spec)`。→ `systems/player-profile/_index.md`、`systems/character-profile/_index.md`
- **`SourceCode` 在 `(Power, Character)` 域的合法取值恰为四条**：`EventOutcome` / `CombatReward` / `ExchangePurchase` / `InitialGrant`（+ 读档兜底 `Unknown`）；`FinaleWin` / `PremiumBundle` / `AchievementReward` 三格恒 ❌。**本层无规则消费点**（`x` 只数法则）。→ `systems/common-properties.md` 的分域校验表
- **能力得失的表达面已闭合三形态**：置换 = `Remove` + `Grant`（同 `PairKey`）· 三档禁用 = `Disable` 带 `Duration` · 战斗内 `IgnoresProtection` = 不进 spec。`AbilityElements` 在 `SelectCost` 内**恒为空**（不变式 + 两处 `PushError`）。→ `systems/services/profile-service.md`
- **`EventOutcomeSpec` 的 `AbilityElements` 是正向白名单**：`Op == Grant` ∧ `Scope == Character` ∧ `Source == EventOutcome`；置换 / 禁用不由它承载，走 `EventOption.AbilityChangeSlots` 的决策点（物化时掷定、落存档、绝不重掷）。→ `systems/services/future-event-service.md`
- **置换同池判据 = `(CarrierKind, Scope)` 全同 + 同 `Rarity` + 排除已持有**，走 `reward` 子流；空池 → 整个置换成为空操作 + `PushWarning`。神通已明确在四个池之一内。→ `systems/player-profile/player-power/_index.md`
- **篇章继承 = 全部继承，无逐项筛选**（`ADR-0004`）；`defeated` / `completed` 数据在轮回结束时清理。
- **`Exchange` 的五个商品族含 `CharacterPower`，但它恒不可售**（「可售出 ⟺ `Kind == CharacterItem`」写成代码常量）。→ `systems/adventure-event/exchange/_index.md`
- **⚠ 五类 AdventureEvent 逐类型各开一次专场，Combat 已开过第一场，其余四类仍在等各自的专场——「不要在通用文档里替它们臆造机制」**（`adventure-event/_index.md`）。本方案因此**只对既有结构给取值口径，不为任何一类事件设计新的产出机制**。另注：**没有独立的「社交」事件类型**，社交语境归 `Exchange`（故待决问题原文里的「社交传功？」在类型层已有归属）。
- **支柱 9（信息靠遭遇获得）** 排除任何以资源换取**外部情报**的通道；玩家对自己牌堆 / 手牌的便利类效果不在此限。→ `vision/pillars.md`
- **战斗屏的呈现分层已定**：神通 / 法则是**只读层**，「呈现气质是技能感、不是卡牌感」，卡面形态只用于图鉴 / 详情 / 奖励与置换选择面；竖屏分区过载已有多处 ⚠ 标注。→ `ux/combat-ux.md`

---

## 建议方案

### 一、与法则的复用边界：持有列表与清理规则的落点

`[既有推演]`

**建议：这一子项其实已经被三份既有文档合围答完，本方案只做一次归拢定稿，不引入任何新结构。**

| 面 | 结论 | 依据 |
|---|---|---|
| 内容定义 | **共用一个 `PowerData`**，`Scope` 声明层级 | `power/_index.md` 已定 |
| 战斗内生效 | **同一条路径**：`CardType.Power` 开局入场、三条与门、受保护、永不入栈 | `power/_index.md` 已定 |
| 战斗外生效 | **注册面两层共用**：`CapabilityManager` 同时遍历 `playerPower` 与当前角色的 `characterPower`，聚合成同一份能力集与同一张修正表 | `player-power/common-properties.md` 已定 |
| **持有列表** | **不共用**：账号级落 `PlayerProfile.playerPower`，轮回级落 `CharacterProfile.characterPower`（第 14 格） | 本方案定稿（推演自「分界 = 生命周期层」） |
| **清理规则** | **无需任何清理代码**：神通随 `CharacterProfile` 在 `defeated` / `completed` 时整体拆解；角色级 flag / modifier 随 `CapabilityManager` 重新聚合自然消失 | `power/_index.md`「推论 ②」已定 |
| **禁用表** | 共用一张 `CharacterProfile.disabledAbility`，条目带 `(Kind, Scope)` 区分抑制哪一层 | `character-profile/_index.md` 已定 |

- **建议在 `power/_index.md` 的「待决问题」中把这一条整条移出**，理由写：分界只在生命周期层，而生命周期层的两个落点（两份持有列表 · 轮回结束整体拆解）已各自成文，没有剩余待决面。
- **连带订正两处文档漂移**（本方案顺带发现，不属新决策）：`power/_index.md` 现文写「`CharacterProfile.characterPower`（**字段 13**）……见 `../_index.md` 的 **23 字段表**」，而该表现为 **25 行、`characterPower` 是第 14 格**（`magicPack` 占了 13）。

### 二、事件侧的获取触发

`[既有推演]` + `[通行做法]`（内容口径）

**建议：机制面已经完全闭合、一格都不必新增；剩下的纯粹是「首批开哪几条通道」的内容口径。**

**机制面（`[既有推演]`，无需任何决策）：** `(Power, Character)` 域的四个合法 `Source` 已经把四条通道逐一命名，每条都有现成的组装者与现成的施加链路：

| `Source` | 组装者 | 施加链路 | 状态 |
|---|---|---|---|
| `InitialGrant` | life-cycle-service 在 `StartCycle` 按 `CharacterData.PowerId` 写入 | 角色创建 | **已定案**（`ADR-0055`） |
| `CombatReward` | combat-service 在 `RunCombatAsync` 收口段算定 → `CombatResult.Spoils` | `eventEnd` 那一次 `TryApply` | 机制现成 |
| `ExchangePurchase` | Exchange 购买流程 → `AbilityChangeElement(Grant, Power, Character, id, ExchangePurchase)` | 同上 | **已成文**（`exchange/common-properties.md` 的映射表逐行写着） |
| `EventOutcome` | 通用结算器从物化后的 `EventOutcomeSpec` 展开 | 同上 | 机制现成（正向白名单恰好只开 `(Power, Character)` / `(Item, Character)`） |

**故「事件侧获取触发」这一问不需要任何新机制、新字段、新 element、新存档格。** 连内容作者侧的写法都已闭合：模板上授予神通**只能走 `OutcomeRule.Kind == GrantFromPool`**，其 `PoolKind` 已收窄为 `{ CharacterItem, CharacterPower }`（`PlayerItem` 直接拒绝，加载期校验 4，见 `adventure-event/common-properties.md`）。授予时的取池走既有的 `GrantPoolManager`（`TryPickGrantable(Power, Character, rng, out id)`，`reward` 子流），取池链与残卷 / 礼包 / 置换共用同一段代码。

**战斗侧同样已闭合：** combat-service 交出的 `Spoils` 内的授予**一律记 `Source.CombatReward`**（判据是「谁组装出这条 element」，故一个揭示出战斗真身的 Explore 选项其战利品同样记 `CombatReward`），且战斗奖励本就有「强制自动计入 / 可选逐项领取」两类形态，**神通挂在可选那一类上即可，与已有的「玩家选中一门功法 = `Spoils` 内一条 `DeckChangeElement`」逐格同构**。→ `systems/services/combat-service.md`

**内容口径（`[通行做法]`，建议值，可零成本改口）：** 建议首批**只开三条**——

- **`InitialGrant`（起手绑定）** —— 已定，每局恰一条。
- **`CombatReward`** —— 作为**主通道**。理由：`Research` 一侧已明确表态「授予神通暂不放进 Research，语义上归战斗奖励与 Exchange 更自然」（`adventure-event/research/_index.md`），而战斗奖励的厚度本就由道念差分档，天然给了「打得漂亮才拿得到」这条获取曲线。建议进一步收窄到 **`combatTier ∈ { Standard, Finale }`**，`Practice` 档不产出神通——`Practice` 是最轻一档，让它也掉神通会把这条获取面稀释成常规掉落。
- **`ExchangePurchase`** —— 作为**次通道**，玩家用灵石 / 仙玉主动兑换。定价表已有 `CharacterPower` 一行（族 × 稀有度），无需新增旋钮。

**建议首批不开的两条：**
- **`EventOutcome`（通用结算器 outcome）** —— 保留机制、**首批不编排任何条目**。理由与 Research 侧同款：一条能在任意事件的 outcome 里直接塞一个神通的通道，会让「build 增长来自打与买」这条已成形的分工被稀释；且 `EventOutcome` 的授予在物化时就已定稿，玩家看不出它是奖励还是白送。**它是纯内容口径，日后要开是新增 `.tres`、零结构改动。**
- **`Research`（闭关）** —— 维持既有表态不变（「暂不放」）。Research 的产出面已被明写收窄为「卡组 + `manaLimit` + 隐藏属性推拉」，为神通破例要动那条边界。

**`Travel` 恒不产出神通**：Travel 是纯位移事件，其 outcome 侧连 `LifeSpan` key 都有结构性禁令，不该成为 build 增长面。**`Explore` 本身不产出**——它揭示的是真身，产出归真身那一类。这两条是既有结构的直接推论，不需要新规则。

### 三、事件侧的失去触发

`[既有推演]`

**建议：同样不需要新机制——`AbilityChangeSlot` 已把「失去」的全部形态闭合，神通只需在三级严重度阶梯上各占一档。**

`power/_index.md` 与 `player-power/_index.md` 已经给出四类通用的三级阶梯，本方案只把它逐档落到神通上并给出内容侧口径：

| 档 | 载体 | 对神通的语义 | 玩家是否点头 |
|---|---|---|---|
| **本场移除** | 战斗内 `IgnoresProtection` 效果结算 | 该神通的战场条目被移除，本场不再触发；**不写 Profile** | 否 |
| **本轮回 / 本篇章 / 下一事件禁用** | `AbilityChangeSlot(Op = Disable, AllowDecline = false)` → `disabledAbility` | 仍在持有列表、灰态可见、不进任何生效面 | 否（只告知） |
| **置换型剥夺** | `AbilityChangeSlot(Op = Remove, AllowDecline = true)` + 同 `PairKey` 的 `Grant` | 真的移出 `characterPower`，换入同 `(Power, Character)` + 同 `Rarity` 的另一条 | **是**（拒绝 = 零 element、零代价） |

- **建议明写：神通没有第四种失去形态**——特别是**不开「无同意的永久剥夺」**（`Op == Remove` + `AllowDecline == false` + `GainAbilityId` 空串）。它在结构上写得出来，但**在轮回级上不产生任何额外表达力**：神通本就随轮回清理，`ThisCycle` 档禁用与永久剥夺在这一局里的可玩后果逐格相同，差别只剩「持有列表里还在不在」与「置换池的排重还排不排它」两处次要语义。为这点差别新开一条分支，代价是打破 `AbilityChangeSlot` 现有的 `Op ↔ AllowDecline` 对应（`Remove` ⇒ `true` / `Disable` ⇒ `false`），而那条对应正是「拒绝置换零代价」的机械保证。
- **内容侧频次口径：神通的失去事件计入既定的那个 1% 分子**（「这次可能失去能力」的事件约占全部 AdventureEvent 的 1%），**与法则共用同一份预算**，不另立一套。⚠ 该预算目前已被 `IgnoresProtection` 那一支吃紧（见「与既有决策的张力」）。
- **`SourceCode` 在失去侧无表达**：`ExchangeSell` / `PackSell` / `ExchangeBarter` 三个成员在 `(Power, Character)` 域全为 ❌，且 Exchange 的可售族恒为 `CharacterItem` 一族——**神通买得到、卖不掉**。这是既有结构，不必新写规则。

### 四、篇章突破是否随「全部继承」带入

`[既有推演]`

**建议：带入，且不为它单列任何规则。**

- `ADR-0004` 的原文是「读档续章时角色带入上一篇章的**全部信息**（deck、法宝、属性、叙事标记等），**无逐项筛选**」。神通是 `CharacterProfile` 上与 deck / `magicPack` 平级的一格集合型 build 状态，**「无逐项筛选」这五个字就是它的答案**——需要论证的是「不带入」，不是「带入」。
- **现成的推理模板**：`CurrentLocationId` 与剩余寿元两格都是用同一条条款推出跨篇章行为的（前者「跨篇章不清零」，后者「跨篇章结转」），神通照抄第三例。
- **推论：`disabledAbility` 里 `Duration == ThisChapter` 的那些条目会在篇章边界被剔除**，故一条在 ch1 被禁用的神通，进入 ch2 时**自动恢复生效**——这不是新规则，是 `life-cycle-service` 既有的两处到期剔除时点之一的直接结果。**建议把这条推论明写进 `power/_index.md`**，否则内容侧会以为「本篇章失效」需要额外的恢复动作。
- **建议在 `power/_index.md` 与 `life-cycle-service.md` 各留一句**，而不是新增字段或新增篇章边界职责：ChapterManager 在篇章边界的既有职责表不增行。

### 五、与卡牌 / 法宝的边界判据

`[既有推演]`

**建议：判据不必新造——把三处文档里已经散着的三条既有事实合成一张表即可，且这张表恰好是可机械核对的（每一格都对着一条既有的结构性禁令）。**

三条现成原料：① `deck/_index.md` 的「三个来源各自绕开的东西不同」；② `power/_index.md` 禁用截断表里的 MTG 对位（神通 / 法则 ≈ 静止式、法宝 / 古宝 ≈ 启动式、卡牌 = 打出）；③ 三条写死的结构性禁令（`ItemData` 不设 `Abilities` · `PowerData` 无 mana / 无 `Charges` / 不得产 `LifeSpan` · 卡组只装法术 / 阵法 / 业障）。

**建议的判据表（按「这个效果要付什么代价才能生效」排序，第一条命中即定型）：**

| 提问 | 是 → 做成 | 依据 |
|---|---|---|
| 它要**消耗 mana、按次打出、可在一局里被重复触发多次**吗？ | **卡牌**（`Sorcery` / `Enchantment`） | 卡牌是道念的唯一产出途径；mana 与抽牌运是它的两道天然节流阀 |
| 它要**有明确的使用次数上限**、由玩家**主动**在某一刻花掉吗？ | **法宝**（`ItemData`，`Scope == Character`） | `Charges` 是节流阀；`ItemData` 不设 `Abilities` ⇒ 它写不出常驻 / 触发式效果 |
| 它是**存在即生效、无代价、一局内不消耗**的常驻改写吗？ | **神通**（`PowerData`，`Scope == Character`） | `PowerData` 无 mana、无 `Charges` ⇒ 反过来说，凡需要节流阀的效果都写不成神通 |

**四条把这张表钉死的推论（建议一并落笔）：**

1. **「无节流阀」是神通的定义性约束，不是它的便利。** `PowerData` 同时缺 mana 与 `Charges` 两格，故**任何随对局延长而累积的效果一律不得写成神通**（「每回合 +X 道念」「按手牌数缩放的倍率」）——这条对法则已明写为承重禁令，对神通**必须同样成立**，理由更硬：法则受「≤ 1/5 条目」的配额纪律与「老账号全开」的校准约束，神通没有任何配额闸，若允许累积型，一局拿两条就能把 10 回合定长的战斗打崩。
2. **战斗外的效果只能写成神通，写不成法宝。** 法宝的战斗外表达力上界是「恒定、无条件、无随机」的一次性 `ProfileChangeSpec`（只开 `Elements` / `CodexElements` / `Stats` 三列）；**改写全局设定**（capability flag / modifier pipeline）在 `ItemData` 上根本没有落点。故「让玩家看见隐藏属性」「商店打折」这一族恒为神通。
3. **回寿元的效果恒不得写成神通**（既有加载期 `PushError`），只能写成法宝（有 `Charges` 上限）或事件产出。这条已成文，此处只是在判据表里给它一个位置。
4. **三者共享 `RarityTier` 五档与既有的 `itemPowerRatio` 换算**（法宝相对同 `ManaCost` 法术的效果量按 `Charges` 分层折价 0.55 / 0.65 / 0.75 / 0.90）。它是全库唯一一条已量化的跨形态强度换算；**神通侧对应的系数属【待内容】，见「前置依赖」——本方案不编数字。**

**边界表的归属**：建议落在 `power/_index.md`（它是三者中唯一同时与另两者相邻的那一个），`deck/_index.md` 与 `item/_index.md` 各留一行回链，**不复述**。

### 六、数量与强度尺度

`[既有推演]`（只给结构与定性，数字属【待内容】）

**建议：本子项的定性面可以现在就答，定量面必须留到第一批内容与 ch1 平衡打磨——本方案不给任何数字。**

**可以现在答的三条定性结论：**

1. **神通的单条强度应显著高于法则的单条，而不是持平或更低。** 推演：法则「轻度提升」这个定位的成因是它**跨轮回单调累积、不可被针对、必须按老账号全开校准**；神通这三条一条都不成立（随轮回清理、可被禁用 / 置换、每局从零起）。用同一档强度约束一个不累积的东西，等于让它在 build 三件套（卡组 / 法宝 / 神通）里成为最不值得关注的那一件，与「它是轮回内 build 的一部分」的既定定位相抵。
2. **战斗内法则的三条强度纪律不整体照搬到神通**：「ch1 前段只能是纯信息 / 便利类、道念贡献为 0」这条**不适用**于神通（它不是账号级内容，新手期不存在「被账号级内容干扰」这个问题——起手绑定神通本就是 ch1 第一分钟就在手里的东西）。但**「不得随对局延长而累积」那条必须照搬且更硬**（理由见上节推论 1）。
3. **不设持有数量的硬规则上限**是本方案的推荐（详见「仍需用户决定」第 1 项），数量由内容侧的获取频次与稀缺纪律承担——与「储物袋不设条数硬上限、由 `Charges` 与内容编排天然封顶」同一条纪律。

**必须留到内容侧的三格（不编造）：** 一次轮回预期获得几条 · 神通相对同 `ManaCost` 法术的效果量系数（`itemPowerRatio` 的对位物）· 各 `RarityTier` 档应有多少条目。三者互相咬合，且第三格已被 `content/character/` 的五个角色（各需一条绑定神通）设下下限 **5 条**。

---

## 具体形态（可 derive 的落地面）

**A. 零结构增量。** 本方案不新增任何字段、element 列、枚举成员、EventBus 事件或存档格；**不 bump `schemaVersion`、无迁移、后端零影响**。它全部落在「把既有结构的取值口径写死」这一层。

**B. 建议新增的加载期校验（挂在 `PowerData` 上，两条，均带条目 `Id`）：**

| # | 违规 | 处置 | 判据来源 |
|---|---|---|---|
| P-a | `Scope == Character` 且某条 `ModifierEntry.Op == Scale` 作用于随回合数 / 手牌数缩放的 key | `PushWarning` + 报出条目 `Id` 与该 key | 「不得随对局延长而累积」；**取 `PushWarning` 不取 `PushError`**——「是否算累积」不可机械判定，与战斗内法则那两个百分比同属「零保证」级，机械化只能做到让它在启动时被看见 |
| P-b | 全库 `Scope == Character` 且 `ContentEnabled` 的条目数 `< 在册 `CharacterData` 条数` | `PushError` + 抛 | 每个角色的绑定神通须解析得到（既有校验 #2 已逐条拦；这一条是它的总量前置，与 `CharacterData` 校验 #10「可修功法池铺够」同款形态） |

> P-b 与 `CharacterData` 既有校验 #2 / #4 不重复：#2 拦「这个角色的 `PowerId` 悬空」，P-b 拦「内容侧根本没铺够」，与既有的功法侧两条分工逐字同构。

**C. 建议写死的内容口径（不进代码，进 `power/_index.md` 与 `content/character-power/_index.md` 的字段核对清单）：**

| 口径 | 建议值 |
|---|---|
| 首批开放的 `SourceCode` 通道 | `InitialGrant` · `CombatReward`（`Standard` / `Finale` 档） · `ExchangePurchase` |
| 首批不编排的通道 | `EventOutcome`（机制保留、零条目） |
| 失去形态 | 恰三种（本场移除 / 三档禁用 / 置换），**无第四种** |
| 失去事件频次 | 计入与法则共用的那个 1% 分子，不另立预算 |
| 效果形态禁令 | 不得随对局延长而累积；不得产 `LifeSpan`（已是硬校验）；不得提供关于敌人 / 未来 / 世界的外部情报（支柱 9） |
| 条目数下限 | ≥ 5（每个在册角色一条绑定神通） |

**D. 篇章边界与轮回终结：不新增职责。** ChapterManager 的篇章边界职责表不增行（神通随 `CharacterProfile` 整体带入）；`TeardownCycle()` 不新增清理步骤（角色级 flag / modifier 随 `CapabilityManager` 重新聚合自然消失，`power/_index.md`「推论 ②」已定）。

**E. EventBus：不新增事件。** EventBus 的负载契约当前有 14 个事件（权威表在 `systems/architecture.md`「EventBus 负载契约」），其中**不存在** `ProfileChanged` / `AbilityGranted` / `AbilityRemoved` 一类事件。神通的获取 / 失去经 `TryApply` 写入后由 `CapabilityManager` 重新聚合并广播既有的**空负载 `CapabilitiesChanged`**（订阅者自行 `Has(flag)` 重查，`ADR-0017`）；profile-service 的事件面维持两个事件（`CapabilitiesChanged` / `AchievementTierReached`）不变。**「神通得失需要一个新的广播点」是伪需求。**

> **顺带记一笔（不属本方案的决策）：`CapabilitiesChanged` 的触发源当前分散记在三处**（启动链的首次聚合 · 禁用表写入 · 明写不触发的只读投影 `Project(spec)`），**没有一份集中的触发源清单**，而 `power/_index.md` 已引用「触发源清单见 `profile-service.md`」。这是一处台账缺口，归 `/sync-knowledge` 或 profile-service 侧一并补。

## 后果

- **文档影响**：`power/_index.md`（移出待决问题 1 与 3，改写待决问题 2 与 4 为内容口径，新增边界判据表与两条校验，订正「字段 13 / 23 字段表」漂移）· `power/common-properties.md`（一句回链）· `item/_index.md` 与 `deck/_index.md`（各一行边界判据回链，不复述）· `life-cycle-service.md`（篇章边界一句「神通随全部继承带入，`ThisChapter` 禁用在此剔除」）· `balance.md`（新开一行占位：神通强度系数【待内容】）· `content/character-power/_index.md`（字段核对清单加上上表 C 的内容口径行）。
- **存档 / 同步**：**零影响**。不新增字段、不 bump `schemaVersion`、后端零配合。
- **内容链解锁**：`content/character-power/` 从「🟢 可写但不知道写什么」变为可实际开工；`content/character/` 的五个角色条目随之解阻（它阻在「功法与神通条目」上，本方案解开神通那一半）。
- **未解锁的**：数量与强度的定量面仍阻于 ch1 平衡打磨，故 `character-power` 条目**可以写出形状、写不出终值**——与全库既有的「结构先定、数值待校准」节奏一致。

## 备选方案（已考虑并否决）

- **给神通开「无同意的永久剥夺」（`Remove` + `AllowDecline == false`）** —— 否决。在轮回级上与 `ThisCycle` 档禁用的可玩后果逐格相同，却要打破 `AbilityChangeSlot` 现有的 `Op ↔ AllowDecline` 对应，而那条对应是「拒绝置换零代价」的机械保证。
- **为神通新开一个 `CharacterPowerData` 类型** —— 否决。`PowerData` 两层共用已定案，且与 `ItemData` 的两层共用完全对称；分裂会连带逼出第二套 `Scope` 枚举与一层无意义转换（`PowerScope` / `ItemScope` 合并为 `AbilityScope` 正是刚做完的反向动作）。
- **给神通新增一个 EventBus 事件（`AbilityGranted` 一类）** —— 否决。`CapabilitiesChanged` 是空负载 + 单点重查的既定形状，新增带负载事件等于制造第二份真值；且神通的 UI 消费点（角色面板 / 战斗只读层）本就走 ViewModel 重组，不靠事件负载。
- **把神通做成有槽位数量上限的「技能栏」** —— **未否决，留作取向项**（见下，它对竖屏只读层的呈现压力有实际影响）。
- **在 Research（闭关）开一条「顿悟得神通」通道** —— 首批否决（维持既有表态）。Research 的产出面已明写收窄为卡组 + `manaLimit` + 隐藏属性推拉；为神通破例要动那条边界，而 `CombatReward` + `ExchangePurchase` 两条已足够承载获取面。**日后要开是纯内容动作，合法子集表该格本就是 ✅。**
- **让神通可在 Exchange 售出** —— 否决。「可售出 ⟺ `Kind == CharacterItem`」是写死的代码常量，改它等于打开一条本该封死的通道；且售出会与置换（同池、有对价、玩家点头）语义重叠而对价口径不同。

## 与既有决策的张力

1. **「失去能力」的 1% 频次预算已被 `IgnoresProtection` 一支吃紧，本方案又往同一预算里塞了神通的置换 / 禁用两支。** `player-power/_index.md` 已明写这条张力（5% × 约 30–36 场战斗 ≈ 1~2 次 / 轮回，单这一支已接近「三类合计 ≈ 全部事件 1%」的全部预算）并挂在「归 ch1 内容编排一并定」。本方案**不预先拍板**，只如实登记：神通侧的置换 / 禁用条目挤进的是同一份预算，故 ch1 编排时要么上调上层合计口径，要么四类合计地收窄。
2. **「篇章继承 = 全部继承」已有一处既有例外**——轮回货币明写「随轮回清理、**每章重置**」（`currency.md` / `balance.md`）。这说明该条款事实上不是绝对的，故「神通带入」虽是本方案的推荐，但它站在条款的**默认方向**上而非条款的**绝对性**上。若用户对某类 build 组件希望篇章间清零，这是可以谈的——只是没有任何依据支持对神通这么做。
3. **竖屏只读层的呈现压力。** `ux/combat-ux.md` 已多处标注「竖屏分区过载」并把「只读层的形状」推给了一个已排期的专场。神通数量若无上限，只读层的条目数就无上限——本方案把这条张力显式转成下方取向项 1，不在此处替呈现层拍板。

## 前置依赖

- **数量与强度的定量面阻于第一批内容与 ch1 平衡打磨**：一次轮回预期获得几条 · 神通相对同 `ManaCost` 法术的效果量系数 · 各 `RarityTier` 档的条目数。三者互相咬合，且需要 starter deck 与功法条目规模先落地才有分母。**本方案不给任何数字**；`balance.md` 只留一行占位。
- **「失去能力」四类合计的频次预算重新配平** —— 已在 `player-power/_index.md` 挂着的待决项，归 ch1 内容编排一并定（见张力 1）。
- **战斗屏只读层的形状** —— 已排期的竖屏分区专场（`ux/combat-ux.md`）。取向项 1 若选「设上限」，该专场的输入随之收窄；若选「不设」，该专场需要给出一个能容纳 N 条的形状。
- **`content/character-power/` 的条目下限 5 条**依赖 `content/character/` 的角色池规模（当前建议值 5，本身是待校准初值）。
- **`status`（启用 / 禁用）与「拥有 / 失去」两个正交维度如何编码进 schema** —— 它是 `power/_index.md` 待决问题里**与本方案并列的另一条**，权威归 `systems/services/profile-service.md` 的同名待决项，**不在本方案范围内**。它不阻塞本方案（本方案的每一项都只读 `status` 的语义、不依赖它的编码形态），但两条一起答完才算「神通机制细节」整条收口。
- **四类事件的各自专场**（Exchange / Research / Explore / Travel）—— 本方案给的是内容口径而非机制；若某场专场改变了该类事件的产出面结构，本方案第二节的通道口径需随之复核。

## 仍需用户决定

### 1. 神通的持有数量：设硬上限（槽位制），还是不设、由内容侧稀缺性承担？

| 选项 | 后果 |
|---|---|
| **A. 不设硬上限**（推荐） | 与法则、储物袋同款形态（「不设条数硬上限，由内容编排天然封顶」是既有纪律）。零结构增量。代价：战斗屏只读层的条目数无上限，竖屏呈现压力落到已排期的专场上；且「拿到第 N 条神通」的边际收益递减无机制保证。 |
| **B. 设硬上限**（例如 3–5 个槽位，超出时必须弃一） | 每次获得都变成一个取舍决策点，build 张力更强，只读层的呈现形状有确定上界。代价：**要新增机制**——一个「满槽时选择弃哪一条」的决策点（形状可复用 `AbilityChangeSlot`，但需新增 `Op` 或新增一类 slot），并要回答「起手绑定神通是否占槽、能否被挤掉」。上限值本身属【待内容】，此刻定不出。 |

**推荐 A**，理由：① 它是零结构增量，B 要新开一个决策点；② 全库对同类集合（法宝、法则、`pastItemUse`）一律采「不设硬上限 + 内容编排封顶」，B 会造出唯一的例外；③ 上限值此刻无从确定（依赖尚未存在的条目规模），而结构一旦开就得同时给出值。**但这条确实是玩法取向**——B 换来的「每次获得都是一次取舍」是 Slay the Spire 遗物之外另一路成熟手感，值不值得那条新机制由你判断。

→ **已裁决（2026-09-03 · 批量评审）：选项 A —— 不设持有数量硬上限，由内容编排天然封顶。** 战斗屏只读层的条目数无上限这一点，随「竖屏分区专场」一并承接。

### 2. 角色绑定的那一条神通（`CharacterData.PowerId`），能否被置换换走？

| 选项 | 后果 |
|---|---|
| **A. 可以换走**（推荐） | 与「绑定功法同样可被弃置——角色给的是**起手形状**，不是永久底盘」逐字对称（`ADR-0055`）。零结构增量：置换池按 `(Power, Character)` + 同 `Rarity` 取，绑定神通今天就已在候选内，**不做任何事就是这个结果**。代价：`ADR-0055` 立的「跨轮回熟悉感有了载体」这条价值在换走后当局归零，而神通只有一条（功法有两门，换掉一门还剩一门）。 |
| **B. 绑定神通受保护、不进置换的失去侧** | 保住「这个角色打起来是什么手感」这条辨识度不被一次事件抹掉。代价：**要新增机制**——持有条目上要能区分「这条是绑定来的」，而 `CharacterPower` 现有三格（`PowerId` / `Status` / `SourceCode`）里 `SourceCode == InitialGrant` 恰好能承担这个判据（零字段增量），但置换的候选选取侧要加一条排除，且要回答「若玩家只有这一条神通，置换事件是不是就恒为空操作」。 |

**推荐 A**，理由：① 对称性是硬的——同一份 `ADR-0055` 在功法那半边已经明确「绑定不等于不可动摇」，为神通反过来会让同一条 ADR 内部自相矛盾；② A 是当前默认行为，B 要主动加规则；③ 置换是**玩家点头**才发生的，且拿回同 `Rarity` 的等价物——「主动换掉自己不合本局流派的起手神通」正是既定的「置换是正向设计、是一个决策点」那条推论的最佳用例。**但辨识度这条价值是 `ADR-0055` 自己立的**，你可能希望它比对称性更硬。

→ **已裁决（2026-09-03 · 批量评审）：选项 A —— 绑定神通可被置换换走**（即当前默认行为，无需任何新增规则）。

## 张力 1 的处置（2026-09-03 · 批量评审）

「失去能力」四类合计的 1% 频次预算配平**本批不裁决**，按本稿建议原样登记为 ch1 内容编排时的待处理项（要么上调上层口径、要么四类合计收窄）。
