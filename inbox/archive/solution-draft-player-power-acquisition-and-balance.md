---
type: solution-draft
date: 2026-09-10
question: PlayerPower（法则）的获取 / 失去具体触发与平衡边界（是否影响 cycle seed / 计分公平、防 pay-grind-to-win）——同一条未决在五份文档上的五个投影，需一次合成收口
source: open-questions.md「次承重」小节 → 五个投影：`systems/player-profile/player-power/_index.md:127`–`:128` · `systems/player-profile/_index.md:208` · `systems/services/profile-service.md:517`（另 `:513` 半条） · `systems/services/life-cycle-service.md:387` · `ux/screen-flow.md:505`
targets: systems/player-profile/player-power/_index.md（唯一权威） · systems/player-profile/_index.md · systems/services/profile-service.md · systems/services/life-cycle-service.md · ux/screen-flow.md · systems/balance.md（新增一段派生量）
status: distilled
reviewed: 2026-09-10 — 唯一取向 → A. 不开第三条获取渠道（分域校验表两格改判为规则层封死；后端零改动、不落 counterpart）。随后在 `/batch-analyze-new-ideas` 的合并 interview 中另定三项：**法宝置换并入「失去能力」上层 ≈1.0 的分子、不设自持口径**（`ADR-0161` 的自持判据首条是「不写 Profile」，法宝置换写 `CharacterProfile`；四支枚举不扩为五支）；**候选项列表语言的构件加第七位「行尾操作控件」**（仅纵向侧 + 外溢判据），故 `screen-flow.md` 不留「版式待决」；**不与 `GrantPoolMargin` / `K` 合场**（索引原写「宜合场」）。直读另更正本稿五处：`x` 累计应为 ≈14 / ≈34 / ≈74（本稿漏加 2.7）· 残卷分档表实为 6 档 · `profile-service.md` 待决行是 `:515` · 文案分区应为 `PROFILE_` · `player-profile/_index.md:208` 应收窄而非整条删除 · ※ 实为三格（第三格是古宝域的陈旧标记）。
distilled-to: handoffs/2026-09-10-player-power-acquisition-and-balance.md
---

# 方案草稿 —— PlayerPower 的获取 / 失去触发与平衡边界（五投影一次收口）

## 问题

`open-questions.md` 把这一条登记为「同一条未决在五份文档上的五个投影」，并明写**宜合成一场 handoff 一次收口，不要逐份裁决**。五处的措辞各有出入：

| # | 投影 | 现文措辞（要点） |
|---|---|---|
| 1 | `systems/player-profile/player-power/_index.md:127`–`:128` | 「平衡边界待定」「是否影响 cycle seed / 计分公平、防 pay/grind-to-win 均待定」「获取触发未设计（残卷 / 礼包之外）」「是否还有第三条获取渠道（事件 outcome 直接给予？）未陈述」「开关 UI 亦未细化」 |
| 2 | `systems/player-profile/_index.md:208` | 「各账号级条目的解锁 / 获取触发仍待定；PlayerPower 的平衡边界同样待定」 |
| 3 | `systems/services/profile-service.md:513` / `:517` | `:513`「各账号级条目的解锁 / 获取 / 失去的具体触发未定」（已带一份「四项不在本条范围内」的排除清单）；`:517`「具体在哪些 AdventureEvent 获取 / 失去仍待定」 |
| 4 | `systems/services/life-cycle-service.md:387` | 「`PlayerPower` / `PlayerItem` 各自的解锁 / 获取 / 失去触发，以及 `PlayerPower` 的平衡边界（防 pay/grind-to-win、是否影响 cycle seed / 计分公平）」 |
| 5 | `ux/screen-flow.md:505` | 「获取 / 失去的具体触发、是否影响 cycle seed / 计分公平性、平衡边界仍待定」 |

**本草稿的核心论点：这条未决的五个组成部分中，四个已在库内别处答定，只是那四处答案从未回流到这五个投影上；真正仍开着的只有一个（第三条获取渠道是否开放）外加一个 UX 版式缺口。**

之所以看起来像一个大缺口，是因为**答案分散在四份别的文档里**（`systems/common-properties.md` 的分域校验表、`systems/monetization.md` 的负面边界、`systems/balance.md` 的三张分档表与两条上沿、`systems/player-profile/player-power/_index.md` 自身正文的失去三形态表）。**这五处待决行本身已是陈旧副本**——`open-questions.md:73` 已把其中两处点名为「陈旧待决项」。逐份裁决必出五套互不相认的口径，正是索引所警告的。

---

## 约束（来自既有设计）

以下是本方案不得违背的硬边界，逐条带来源：

1. **账号级随机绝不走 `SeedManager` 的四条子流。** 判据是「结果写 `PlayerProfile` 的随机，绝不可从 `CycleSeed` 派生」——四条子流全由 `Hash64(CycleSeed, streamName)` 得出，而篇章重试会生成全新 `CycleSeed`。形态 = 具名域 `AccountStream` + 单调序号的三参数派生，随机源是契约定义的纯函数 SplitMix64。→ `systems/common-properties.md`「账号级随机与轮回随机是两条不相交的线」
2. **`Source` 的合法取值按 `(CarrierKind, Scope)` 分域，法则一侧当前恰三格 ✅。** `FinaleWin` / `PremiumBundle` / `AchievementReward`；`EventOutcome` / `ExchangePurchase` 三格标 ※（「暂不开放，取决于尚未设计的第三条获取渠道」），`CombatReward` / `InitialGrant` / 三条卖出成员是规则层封死。→ `systems/common-properties.md` 分域校验表
3. **`x` 只数 `SourceCode == Source.FinaleWin` 的法则，单调不减 ⇒ 残卷档位只降不回跳。** 置换继承被换出条目的 `SourceCode`（关死「用置换刷回高掉率」）；⚠ 明写禁令：**不为「置换所得」设 `Replacement` 成员**。→ 同上
4. **失去恰三形态，无第四种：** 本场移除（战斗内 `IgnoresProtection`，不写 Profile）< 本轮回禁用（`CharacterProfile.disabledAbility`，三档 `DisableDuration`，无同意）< 账号移除（**仅自愿置换**，有等价对价）。→ `systems/player-profile/player-power/_index.md` 三形态表
5. **付费内容不会被游戏销毁。** 法则不可被强制剥夺。→ 同上推论 ①、`systems/monetization.md`
6. **能力 element 恒不出现在 `selectCost`。** `ProfileChangeSpec.AbilityElements` 在 `EventOption.SelectCost` 内恒为空，两处 `PushError` 断言。→ `systems/adventure-event/common-properties.md`
7. **事件产出不能给账号级古宝（承重）。** `GrantFromPool` 的 `PoolKind` 收窄为 `{ CharacterItem, CharacterPower }`，`PlayerItem` 直接拒绝——理由是「由轮回内事件产出会改变账号级经济，也会绕开『账号级授予只走残卷 / 付费 / 成就』三条既定渠道」。→ `systems/services/future-event-service.md:425`
8. **失去能力的频次预算已逐格有数**（`ADR-0161`）：持久三支合计 ≈1.0 次 / 完整轮回；法则置换 ≈0.3、法则禁用 ≈0.2、神通合计 ≈0.5；`IgnoresProtection` ≈1.11 自持战斗分母。→ `systems/player-profile/player-power/_index.md` 四支目标频次表
9. **战斗内法则的强度上沿：单条 ≤ 10% `baseMomentum`、老账号全开合计 ≤ 25%；⚠ 这两个百分比落纪律阶梯第 4 级（零保证），不得被引用为承重依据，且明写「不为它补代理指标」。** 承重的是那条定性定位。→ 同上、`systems/balance.md`
10. **付费面负面边界五项排除 + 唯一预留方向（纯外观）**；礼包两个抽取池的条目一概不得产出寿元（两条加载期 `PushError`）。→ `systems/monetization.md:144`
11. **难度曲线按「老账号全开」校准，免费档仍是「游戏应当可通关」的基准。** → `systems/balance.md:865`、`systems/monetization.md:25`
12. **后端的防作弊边界 = 可复算 `roll`、不复算阈值；不一致仅记账不拒绝。** 后端只做 `Source` 取值识别与 `x = count(sourceCode == "FinaleWin")` 复算，校验表后端不复制。→ `backend-design-documents/contracts/profile-sync.md` §7 / §5、`decisions/ADR-0005-anti-cheat-recompute-boundary.md`（后端库）

---

## 建议方案

### 子项 1 —— 获取通道 = `(Power, Player)` 域的合法 `Source` 集合，逐条已有组装者与施加链路

`[既有推演]` 依据 = 约束 2 + `systems/character-profile/power/_index.md:46` 的**同构先例**。

神通（`CharacterPower`）那一侧已把这条推演写死了，逐字如下：「**获取与失去的通道已闭合，本层只余内容口径。** `(Power, Character)` 域的四个合法 `Source` 已把获取通道逐一命名（…），每条都有现成的组装者与施加链路，**不需要任何新机制、新字段、新 element、新存档格**。」

法则一侧的结构与之逐格同构，故**建议采用同一句话、同一条判据**：

| # | 渠道 | `SourceCode` | 组装者 | 施加时机 / 链路 | 随机源 | 权威 |
|---|---|---|---|---|---|---|
| ① | 道统残卷（Finale 通过掷中） | `Source.FinaleWin` | `CombatEventResolver` → `CombatResult.Spoils` 的一个 element | Finale 的 `eventEnd` 那一次 `TryApply` | `AccountRng.For(AccountStream.PowerFragment, FinaleWinOrdinal + 1)` | `player-power/_index.md` 残卷全链 |
| ② | premium bundle（付费礼包，随机 1 条） | `Source.PremiumBundle` | 兑现事务（客户端，读 `BundleGrantOrdinal` 水位） | 兑现事务内一次 `TryApply` | `AccountRng.For(AccountStream.PremiumBundle, ordinal)` | `systems/monetization.md` |
| ③ | 成就 90% 档一次性奖励（**指定条目，非抽取**） | `Source.AchievementReward` | `AchievementManager` 采集 → 经 `ProfileManager` 单点提交 | 达标那一次 `TryApply`，**零新增存档点** | **无随机**（`AccountStream` 刻意不为它设成员） | `systems/player-profile/achievement/_index.md`、`ux/screen-flow.md:121` |

三条渠道的共同点与既有落点：

- ① ② 共用**同一段抽取**（`GrantPoolManager`，取池链 = `AllEnabled` → 过滤 `(Power, Player)` → 排除 `ExclusiveSource != null` → 排除已持有 → 按 `GrantPoolWeights` 加权），**共用同一张权重表 40/27/18/10/5**；③ 走 `ExclusiveSource == Source.AchievementReward` 的专属条目，按定义**不进任何抽取池**，故三者互不撞车、**成就奖励恒不落空是机械保证**。
- 三条渠道**全部不新增字段、不新增 element 列、不新增存档格、不新增存档点**。
- **`x` 只被 ① 推动**：② ③ 不计入 `x`，这是既定的、有意的——「把付费与成就奖励算进自变量等于让玩家买到的东西反过来掐死自己的残卷线」。

⇒ **建议落笔的句子**（写进 `player-power/_index.md`，与神通侧同构）：

> **获取与失去的通道已闭合，本层只余内容口径。** `(Power, Player)` 域的三个合法 `Source`（`FinaleWin` / `PremiumBundle` / `AchievementReward`）已把获取通道逐一命名，每条都有现成的组装者与施加链路，不需要任何新机制、新字段、新 element、新存档格。`EventOutcome` / `ExchangePurchase` 两格保持 ❌ —— 见下方「第三条获取渠道」。

### 子项 2 —— 第三条获取渠道（事件 outcome 直接给予法则？）：建议**不开**

`[取向选择]` **本草稿唯一需要用户拍板的一项。** 详见文末 `## 仍需用户决定`。此处只陈述推荐项的推演，以免文末重复。

推荐 **不开**（`(Power, Player)` 域的 `EventOutcome` / `ExchangePurchase` 两格由「※ 暂不开放」改判为**规则层封死**），四条依据：

1. **`PlayerItem` 的同一条理由逐字适用。** 既定承重条明写「**事件产出不能给账号级古宝**……由轮回内事件产出会改变账号级经济，也会绕开『账号级授予只走残卷 / 付费 / 成就』三条既定渠道」（`future-event-service.md:425`）。法则与古宝同为 `Scope == Player` 的账号级持有物；把这条理由套到法则上，**结论不变而论据一字不用改**。反过来说，若对法则开放而对古宝封死，`PoolKind` 就要从「能力族两值」扩成三值并带一条「只许法则不许古宝」的例外表，正是既定判据（两个 `Kind` 职责不重叠）要避免的形态。
2. **它会架空「分发账户级加强的核心算法」。** 残卷的三张分档表是一条**受 `x` 调控的递减供给曲线**（阈值 3/5/9/12/15，篇章闸门逐档移除）。事件 outcome 是一条**不受 `x` 调控、随游玩时长线性增长**的第四条供给——开了它，「靠渡劫拿得越多、后续越难再拿」这条曲线就被一条平行的线性通道旁路。既定文本已把这条算法标为「设计初衷、不简化」。
3. **它开一条后端不可复算的账号级授予通道（跨边界代价）。** 后端当前对法则的全部校验就两条：`x = count(sourceCode == "FinaleWin")` 的复算，与 §7 校验 ②「未命中却新增 `FinaleWin` 法则 ⇒ 异常」的单向蕴含。一条 `sourceCode == "EventOutcome"` 的法则**不触发任何一条**——它是客户端在轮回内自行组装、后端无输入可复算的账号级永久授予。既定的防作弊边界（可复算 `roll`、不复算阈值）在残卷 / 礼包两条上都成立，唯独这条不成立。
4. **它没有对应的设计缺口要填。** 「玩法中途拿到一件东西」的体验位已由**神通 / 法宝 / 卡牌 / 功法四族**在轮回级完整承载（`EventOutcome` 在 `(Power, Character)` / `(Item, Character)` 两域都是 ✅）；账号级那一层的定位本就是「跨轮回我强了多少」，其推进节奏由残卷 / 付费 / 成就三条各自的节律给出。

**若用户裁定开放**，随之而来的连带改动清单见 `## 后果`。

### 子项 3 —— 失去触发：已闭合，本层只余内容编排口径

`[既有推演]` 依据 = 约束 4 + 6 + 8。

`profile-service.md:517`「具体在哪些 AdventureEvent 获取 / 失去仍待定」这句话**问的是一个已被明确判给内容侧的问题**。既定结论逐条如下，建议原样回链、不重新裁决：

| 形态 | 触发点 | 写不写 Profile | element 形态 | 玩家同意 | 目标频次（次 / 完整轮回） |
|---|---|---|---|---|---|
| 本场移除 | 战斗内 `IgnoresProtection` 效果结算 | **否**（仅战场条目被移除） | 无 | 不涉及 | ≈1.11（自持战斗分母，仅挂 boss 档载体） |
| 本轮回禁用 | 事件 outcome 侧（`eventEnd`） | 是（`CharacterProfile.disabledAbility`） | `AbilityChangeSlot(Op = Disable, AllowDecline = false)` | **无同意** | **≈0.2** |
| 账号移除（置换） | 事件 outcome 侧（`eventEnd`），先看后决 | 是（移出 `playerPower`） | `Op = Remove, AllowDecline = true` + 同 `PairKey` 的 `Grant` | **须点头** | **≈0.3** |

三条承重推论（已定，本草稿不改）：**① `selectCost` 侧恒空**（能力得失只出现在 outcome / reward 侧，两处 `PushError` 断言）；**② 候选必须在结算时预先掷定并落决策点存档**，否则退出重进可重掷；**③ 频次的旋钮全落内容侧、零字段零校验零状态位**——带 `AbilityChangeSlots` 的 `AdventureEventData` 条目数 + 各条目的 `SelectionWeight` 档 + 既有 arc 系数。

⇒ 「在哪些 AdventureEvent 上」**按定义不是设计层的答案**：它是内容编排的产物，答案形态是「每支 1–2 条 `Rare` 档条目」，具体条目随 `/author-content` 落地。建议把 `profile-service.md:517` 的后半句直接删除并回链本表。

### 子项 4 —— cycle seed 与计分公平：**两者不相交**，该问句已被答定

`[既有推演]` 依据 = 约束 1 + 9。

这是五个投影里**措辞最陈旧的一格**——它在三处（`player-power:127` · `life-cycle-service:387` · `screen-flow:505`）以「是否影响 cycle seed / 计分公平」的形式重复登记，而两半的答案都已写死：

**(a) cycle seed 侧——不相交，且这是结构性的，不是口径。**

- 账号级掷骰**不派生自 `CycleSeed`、不消耗任何子流 `State`** ⇒ 对轮回可复现性零影响。
- 反向也不成立：法则的**持有**不进任何 seeded 抽取的输入（取池链只读「已持有集合」做**排重**，不读 seed；`status` / `disabledAbility` 更是**不参与取池过滤**，因为生效维度与持有维度正交）。
- `FinaleWinOrdinal` 同时是**幂等键**：同一序号重复结算得同一结果，退出重进 / push 重放都不改变掉落。
- ⇒ 建议落笔：**「残卷与 cycle seed 公平性的关系 = 两者不相交」**，并把三处的问句删除。（这句话在 `player-power/_index.md:27` 已经写着，只是那三处的待决行没跟着删。）

**(b) 计分公平侧——刻度已有，且它明确是评审参考而非机械闸。**

- 刻度 = **道念净贡献占本方 `baseMomentum` 的比例**（`baseMomentum` 是既定的战斗强度主刻度）：单条 ≤ 10%、老账号全开合计 ≤ 25%、**不得随对局延长而累积**（禁「每回合 +X」「按手牌数缩放」——10 回合定长下是线性放大器）。
- 允许 ✅ 信息 / 便利类（道念净贡献 0）与容错类；禁止 ❌ 稳定产出类与倍率类。**ch1 前段只能是纯信息 / 便利类、道念贡献恒 0。**
- 25% 这条已被 `balance.md:570` **正向消费**：ch3 的越阶追分明确由「神通 25% + 战斗内法则 25% + 道具」三者承担，合计覆盖 35 点最坏落差。**它不是一条悬空的口径，而是难度曲线的一个已入账的分量。**
- ⚠ 两个百分比**不可机械校验**，落纪律阶梯第 4 级（零保证），且既定文本明写「**不为它补代理指标**」。承重的是那条定性定位（偏体验改善与容错、允许影响胜负但不应成为胜负的主要来源），它不需要数字即成立。

### 子项 5 —— 防 pay-grind-to-win：已有七道护栏，建议整理成表、不新增机制

`[既有推演]` 依据 = 约束 5 + 7 + 10 + 11 + 12。

这条同样不是缺口，而是**答案散在四份文档、从未被并排列出**。建议在 `player-power/_index.md` 落一张表（每行都只是回链，不复述对方的设计）：

| # | 风险面 | 护栏 | 纪律阶梯 | 权威 |
|---|---|---|---|---|
| 1 | 付费直接买战力 | 付费的战斗价值**主要由古宝承载**（`Charges` 是天然节流阀，「关键时刻多几次转圜」而非「永久变强」）；法则保持稀缺 | 第 4 级（分工纪律） | `systems/monetization.md:26`–`:29` |
| 2 | 战斗内法则泛滥 | `UsableScene ∋ InCombat` 的法则 **≤ 1/5 条目**，加载期统计比例、超标 `PushWarning` + 报出当前比例 | **第 3 级（启动期机械检查）** | `player-power/_index.md` 配额纪律 |
| 3 | 付费买到强度档 | 礼包与残卷**共用同一张 `GrantPoolWeights`**（分表 = 让付费直接买到更高档强度） | 第 3 级（任一档权重为 0 → `PushError`） | `systems/balance.md:947` |
| 4 | 付费稀释元进程压力线 | 五项明确排除（付费续命 / 抽卡 / 硬通货 / 体力 / 广告）；礼包两池**一概不得产出寿元**（两条加载期 `PushError`） | **第 1–3 级** | `systems/monetization.md:144`–`:152` |
| 5 | 付费成为必需品 | 重试上限**两档**（免费 ∞/3/1 · 付费 ∞/9/3），**免费档是「游戏应当可通关」的基准**；③ ④ 只首购生效、不叠加 | 第 4 级（校准纪律） | `systems/monetization.md:25`、`ADR-0004` |
| 6 | grind 无限堆叠 | 残卷的**递减供给曲线**：`Cap/Base` 逐档下降（50/30 → 30/20 → 10/5 → 5/3）+ **篇章闸门逐档累加移除**（`x ≥ 5` 移除 ch1、`x ≥ 12` 再移除 ch2）+ 全局前置「未拥有法则数 > 0」+ 「一篇章一个 Finale、败后不可重战」⇒ **残卷不需要任何额外防刷规则** | **第 1 级（结构性）** | `systems/balance.md:918`–`:946` |
| 7 | 刷 / 篡改 | `FinaleWinOrdinal` 是**幂等键**；`LastRoll` / `LastEffectiveChance` 每次通过必写、供后端逐位复算；随机源是跨语言逐位一致的 SplitMix64 | **第 1–2 级（后端可复算）** | `backend-design-documents/contracts/profile-sync.md` §7 |

**两条已知且已被接受的代价，建议如实并列写下（不为它们新增护栏）：**

- **礼包是一份净强度增益。** 付费收益是纯净收益（不附带「下一条法则来得更慢」的代价），**这是有意为之**，平衡侧按此校准。→ `systems/monetization.md:37`
- **账号级法则总量没有硬上限，而「老账号全开 ≤ 25%」是零保证的评审参考。** 既定文本已两次明确拒绝为此加机制：`monetization.md:51` 明写闸 ① 「不断言任何单账号可获取上限」（「单账号可获取上限」不是一个有定义的量）；`player-power/_index.md:44` 明写「不为它补代理指标」。⇒ **本草稿不提出任何新的机械闸**，改为补一个**可算的分母**（见子项 6）——那才是「按老账号全开校准」这句话缺的东西。

### 子项 6 —— 「老账号全开」的分母：给出账号级法则获取速率的派生量（新增推导）

`[既有推演]` + `[通行做法]` 依据 = 三张分档表 + 首胜规则 + 「一篇章一个 Finale」。

`balance.md:865` 要求「难度曲线按老账号全开校准」，`player-power/_index.md:41` 的合计上沿也以「老账号全开口径」表述——**但库内从未给出「老账号」持有多少条法则**。没有这个分母，那条 25% 无法被任何人对照。建议补上（**全部是派生量，不是新决策**）：

**推导。** 每完整轮回（三篇章全通）= 3 次 Finale 通过 = 3 次掷骰。生效概率 = `clamp(Accumulated, Base(x), Cap(x))`，取该档 `[Base, Cap]` 的中值作估算；适格篇章数取该档的闸门行；首胜三次硬置 100% ⇒ 前 3 条几乎确定。

| `x` 档 | 适格篇章数 | 生效概率中值 | 每完整轮回新增 `FinaleWin` 法则 | 走完本档所需完整轮回数 |
|---|---|---|---|---|
| `0 → 3` | — | — | 由三次首胜占满 | 3（各章首通） |
| `3 ≤ x < 5` | 3 | 25% | ≈ 0.75 | ≈ 2.7 |
| `5 ≤ x < 9` | 2（移除 ch1） | 25% | ≈ 0.5 | ≈ 8 |
| `9 ≤ x < 12` | 2 | 7.5% | ≈ 0.15 | ≈ 20 |
| `12 ≤ x < 15` | 1（再移除 ch2） | 7.5% | ≈ 0.075 | ≈ 40 |
| `x ≥ 15` | 1 | 4% | ≈ 0.04 | 每条 ≈ 25 |

**累计：`x = 9` 约在第 11 个完整轮回、`x = 12` 约在第 31 个、`x = 15` 约在第 71 个。**

**三条读法（这才是这段推导的用处）：**

1. **「老账号全开」的现实分母是 `x ≈ 9–12`，不是「池被取尽」。** `x ≥ 15` 是一条**渐近线而非可达点**——按此估算需 70+ 次完整通关。校准 ≤ 25% 时应按 `x ≈ 12` + 礼包所得（每次购买 1 条）+ 成就 90% 档所得（条数 = 成就组数，尚未定，见 `## 前置依赖`）取分母。
2. **这是上界，真实速率更低。** 表的分母是**完整轮回**（三篇章全通）；绝大多数轮回在中途身死，只贡献 1–2 次 Finale 通过。故实际到达各档的游玩量比表中数字**大**。
3. **旋钮位置与调整方向已定，本草稿不动它们。** 旋钮 = 阈值 `3/5/9/12/15` 与三张表各格取值，随 overlay 可调；`balance.md:946` 已给方向：「若上线后残卷掉率偏高，**下调阈值，表结构不变**」。本表是那条复核提示的量化底稿。

⇒ 建议把本表落进 `systems/balance.md` 残卷三张表**之后**，标题写明「派生量 · 由 ① ② 两表与首胜规则算出 · 待实测校准」，并明确它**不是第四张配置表、不落任何字段**。

### 子项 7 —— `status` 开关 UI：形态已有，缺的只是列表版式

`[通行做法]` 依据 = 既有的四个落点。

`player-power/_index.md:128` 的「开关 UI 亦未细化」被登记为设计缺口，但库内已有四样东西：主菜单 **PlayerPower（法则）入口**（`screen-flow.md:46`）· 写入通道 `ProfileChangeSpec.AbilityStatusChanges` + 门面 `SetAbilityStatus(kind, scope, abilityId, enabled)` · 默认值 `true` + 老档缺格补 `true` · **禁用态的完整呈现规格**（「元进程界面照常列出、灰态 + 徽标 + 三档文案、长按查看来源事件；施加时事件结算面板必须告知；战斗屏不呈现」）。

缺的只是**这一屏的版式**。建议的具体形态（提案，落地时归一次 UX 专场）：

- **一屏一列表**，不新增主菜单入口（入口已在），不做分页 / 分类 tab——法则总数量级是个位到十几条（见子项 6），分类是为不存在的规模付成本。
- **每行 = 图标 + 名称 + 一行描述 + 右侧开关**。开关落 `Control` 自带的 toggle，**满足触控目标尺寸下限**，`status == false` 时整行弱化但**不移出列表**（与禁用态灰态呈现同款语汇，避免同一屏出现两种「不生效」的表达）。
- **本轮回禁用的行**：灰态 + 徽标 + 三档时长文案 + 长按查看来源事件（已定），且**开关在该行上仍可操作**——`status` 与 `disabledAbility` 是两个正交维度，把开关一并锁掉会让玩家以为自己永久失去了这条法则。
- **零 hover 通道**；描述超长走点按展开而非悬停。
- **文案走 `res://text/` 翻译键**；框架文案归 `MENU_` 分区（该分区已覆盖主菜单族），法则名 / 描述是内容层 `LocalizedText`，**一个字不进 `menu.csv`**。
- **零新增存档字段、零新增服务方法**（写入走既有 `SetAbilityStatus`）。

⇒ 建议把「开关 UI 未细化」这半条**从 `player-power/_index.md` 移到 `ux/screen-flow.md` 的待决问题**（它是版式问题，权威在 UX 侧），并在那里写明「形态已定、只余版式」。

---

## 具体形态（可 derive 的落地面）

### A. 五个投影的收敛落点（**单一权威 + 四处回链**）

| # | 文件 · 行 | 建议改动 | 改动后承载 |
|---|---|---|---|
| 1 | `systems/player-profile/player-power/_index.md:127`–`:128` | **删两条待决项**；在「意图」节新增一条承重句「**获取与失去的通道已闭合，本层只余内容口径**」（子项 1 的句子 + 三渠道表 + 子项 5 的护栏表 + 子项 4 的两句结论）；`:128` 的「开关 UI」半条移交 `ux/screen-flow.md` | **唯一权威** |
| 2 | `systems/player-profile/_index.md:208` | 整条**删除**（`open-questions.md:73` 已点名此行须收窄——照现文写会把三个已闭合子系统一并拖成 blocked） | 无（字段表第 3 行已回链 `player-power/_index.md`） |
| 3 | `systems/services/profile-service.md:513` / `:517` | `:513` 的「四项不在本条待决范围内」清单**扩为五项**，第五项 = `PlayerPower` 的获取 / 失去触发 → 回链权威；`:517` 整条**删除** | 一行回链 |
| 4 | `systems/services/life-cycle-service.md:387` | 删去 `PlayerPower` 那半与「平衡边界」那半，改为一句回链。⚠ **`PlayerItem` 那半不在本草稿范围内**——见「越界发现」 | 一行回链 |
| 5 | `ux/screen-flow.md:505` | 改写为**只余版式**的 UX 待决：「法则列表屏的版式（形态已定：入口在主菜单、写入走 `SetAbilityStatus`、禁用态呈现已定；缺的是列表版式）」；删去 cycle seed / 计分公平 / 平衡边界三句 | 版式待决 |
| + | `systems/balance.md`（残卷三张表之后） | **新增**子项 6 的派生量表，标「派生量 · 待实测校准 · 不落字段」 | 校准分母 |
| + | `systems/common-properties.md` 分域校验表 | **仅当用户裁定「不开第三渠道」时**：`(Power, Player)` 列的三个 ※ 由「暂不开放」改判为规则层封死，※ 脚注改写 | 校验表口径 |

### B. 获取通道（形态清单，可直接 derive 成验收标准）

```
① FinaleWin        : 触发 = Finale 战斗通过；rng = AccountRng.For(PowerFragment, FinaleWinOrdinal + 1)
                     命中 ⟺ roll < clamp(Accumulated, Base(x), Cap(x))；发放后 Accumulated ← Base(x + 1)
                     授予 element 是 CombatResult.Spoils 的一个 element，并入 eventEnd 那一次 TryApply
② PremiumBundle    : 触发 = BundleRedeemedOrdinal < BundleGrantOrdinal（一次纯比较）
                     rng = AccountRng.For(PremiumBundle, 本次 ordinal)；同一 rng 连续抽 1 法则 + 2 古宝
                     兑现事务内一次 TryApply，同批置 BundleRedeemedOrdinal ← 本次 ordinal
③ AchievementReward: 触发 = 某成就组加权进度达 90%；发放指定条目（ExclusiveSource == AchievementReward）
                     无随机、无取池；经 AchievementManager 采集 → ProfileManager 单点提交、零新增存档点

共有：授予 element 必须携带 Source（无默认值）；Op == Grant 且 (Power, Player, Source) 不在合法表内 → PushError + 整批拒绝
共有：抽取结果在 spec 组装之前定稿，AbilityChangeElement 只拿到已定稿的 Id
```

### C. 存档与上行负载：**零新增**

| 面 | 结论 | 依据 |
|---|---|---|
| `PlayerProfile` 字段 | 零新增（`playerPower` / `playerPowerFragment` / `entitlement` 三格已在 17 行字段表内） | `player-profile/_index.md` 字段表 |
| `schemaVersion` | **不 bump** | 无字段形状变更 |
| 上行负载 / JSON path | 零新增（`/playerPower[*]/powerId` · `/sourceCode` · `/playerPowerFragment/*` 均已在白名单） | `backend-design-documents/contracts/profile-sync.md` §5 |
| 后端义务 | **零新增**（推荐项下）。后端只做 `Source` 取值识别与 `x` 复算，本方案不改 `x` 口径、不新增会被后端读到的取值 | 同上 §5 / §7 |
| 存档点 | 零新增（三条渠道全部并入既有的 `TryApply` 时刻） | `life-cycle-service.md` 存档点清单 |
| 新枚举 / 新 element 列 | 零新增 | — |

> **⚠ 这一列在「开放第三渠道」的取向下会变。** 见 `## 后果`。

### D. cycle seed / 计分公平的判据（可直接写成断言）

| 断言 | 可验证方式 |
|---|---|
| 账号级掷骰不派生自 `CycleSeed`，不消耗任何子流 `State` | 同一 `(AccountStream, ordinal)` 在任意 `CycleSeed` 下得同一 `roll`；篇章重试换 `CycleSeed` 后重掷得同一结果 |
| `FinaleWinOrdinal` 是幂等键 | 同一序号重复结算（退出重进 / push 重放）得同一 `pickedPowerId` |
| 取池不读 seed、不读 `status` / `disabledAbility` | 被禁用的法则照常算作已持有、照常排除出池 |
| 每次 Finale 通过必写 `LastRoll` / `LastEffectiveChance`，即使不发放 | 池取尽（静默停摆）时 `FinaleWinOrdinal` 仍 `+1` 且两个字段照写；首胜那次 `LastEffectiveChance == 10000` |
| 战斗内法则不得随对局延长而累积 | 内容评审：无「每回合 +X 道念」「按手牌数缩放」形态的条目 |

---

## 后果

**推荐项（不开第三渠道）下：**

- 触及 5 份主题文档 + 1 份平衡文档（改动清单见「具体形态 A」），**其中 4 份是删除 / 收窄待决行**。
- **五份文档的 derive 排除面同时收窄。** 按 `open-questions.md` 的就绪度台账，`life-cycle-service.md`（`:387` 是其**唯一一条实质卡点**）与 `profile-service.md`（两条卡点之一）可望**由 partial 升 ready 或接近 ready**；`player-profile/_index.md`（唯一卡点）同理；`player-power/_index.md` 卡点由两条减为零；`ux/screen-flow.md` 卡点由两条减为一条（且剩下那条降级为版式）。这正是索引所说的「一次收口同时收窄这五份的排除面」。
- **零存档影响、零 schema bump、零后端配合、零新机制、零新字段。**

**若用户裁定开放第三渠道，连带改动清单（供裁决时对照）：**

1. `systems/common-properties.md` 分域校验表：`(Power, Player)` 列翻 1–2 格（`EventOutcome` 必翻；`ExchangePurchase` 是否一并翻是第二问）。
2. `systems/adventure-event/common-properties.md` + `systems/services/future-event-service.md`：`GrantFromPool` 的 `PoolKind` 由两值扩为三值（含 `PlayerPower`），加载期校验第 4 条同改；**并须重写 `future-event-service.md:425` 的承重条**（它现在的理由对法则同样成立，开放即要求它给出「为什么法则可以、古宝不可以」的新判据）。
3. **必须同批裁决：这条渠道给的法则计不计入 `x`？** 计入 ⇒ 玩家可在轮回内刷事件压低残卷掉率（且与「`x` 单调不减」的推演绑在一起）；不计入 ⇒ 又一条纯净增益通道，与残卷的递减曲线并行。
4. **必须同批裁决：频次预算怎么算？** 现有四支频次表只覆盖**失去**侧；新增一条获取通道要么进内容编排预算，要么明写不设预算。
5. **跨库承接项（必须成对落笔）：** `backend-design-documents/` 需登记「`(Power, Player)` 域新增可出现的 `sourceCode` 取值，且该通道**后端不可复算**」——它是既定防作弊边界（可复算 `roll`）的第一个例外，须由用户明确接受或补一条校验。**本草稿未落这份后端 counterpart**（推荐项下它不存在），若裁定开放则需补跑一次。

---

## 备选方案（已考虑并否决）

- **逐份裁决五个投影** —— 索引已明写会出五套互不相认的口径；且四个组成部分的答案本就在别处，逐份写只会制造第六、第七套副本。
- **为「老账号全开 ≤ 25%」补一个可机械校验的代理指标**（例：加载期统计 `InCombat` 法则条目数 × 10% 名义上沿，超 25% → `PushWarning`）—— **既定文本明写「不为它补代理指标」**，理由是「为一个不可机械校验的评审参考再加一把同样不可校验的闸，规则密度上升而保证不变」。本草稿改为补一个**可算的分母**（子项 6），那不是闸门、不落字段，与该纪律不冲突。
- **为残卷设账号级硬上限**（例：`x` 封顶）—— `monetization.md:52` 已明确否决：新机制，且与「池取尽 → 静默停摆」重复承担同一职责；`x ≥ 15` 档仍有 `Gain = +1%` / `Cap = 5%` 正是这条否决的体现。
- **新设 `Source.Replacement` 成员以区分置换所得** —— `common-properties.md:285` 已立**明确禁令**：会立刻打破 `x` 的单调不减，重开「用置换刷回高掉率」的通道。
- **把「本轮回禁用」承载在 `status` 字段上** —— 已否决（`status` 是账号级持久字段，轮回结束忘了恢复即等同永久剥夺）；已落 `CharacterProfile.disabledAbility`。
- **把开关 UI 做成分类 tab / 分页列表** —— 法则总数量级是个位到十几条（子项 6），为不存在的规模付版式成本；与「主菜单入口预算紧张」同一条判据。

---

## 与既有决策的张力

**一处，且是「本草稿主动不去动它」的那种张力，如实写下：**

- **「战斗内法则老账号全开 ≤ 25%」是零保证的评审参考，而账号级法则总量没有硬上限。** 这两条同时成立即意味着：**pay-grind-to-win 的最后一格没有任何机械兜底**，全靠内容评审。库内已两次明确拒绝为此加机制（`monetization.md:51` 拒绝上限、`player-power/_index.md:44` 拒绝代理指标），故本草稿**不提议松动任何一条**，改为补一个可算的分母使那条评审参考**第一次变得可对照**。
  - **如果用户认为这道口子仍需收紧**，唯一不与既定纪律冲突的方向是**降低供给速率而非加闸**——即下调残卷阈值 `3/5/9/12/15`（`balance.md:946` 已把它写成官方的调整方向，且表结构不变）。这不是本草稿提出的改动，只是把可用的旋钮指出来。

其余各处**无张力**：本方案的每一条建议都是把既有结论回链到位，未推翻任何 ADR 或承重结论。

---

## 前置依赖

1. **成就组数（⇒ `AchievementReward` 渠道的法则供给量）尚未定。** 90% 档每组发一条法则 ⇒ 该渠道的总供给 = 成就组数。这个数没定，子项 6 的「老账号分母」就只能给出残卷 + 礼包两条的量。→ `systems/player-profile/achievement/_index.md` 的「两档专属奖励条目目录」（依赖法则 / 古宝条目先行，属内容阶段）。**本方案的其余部分不受它阻塞。**
2. **`GrantPoolMargin` / `K` 的取值待内容规模明朗。** `open-questions.md` 的「下一阶段」条目建议本条**与它合场**（「三者实为同一条内容规模问题的三个投影」）。本草稿**未合场**——它是数值取值问题（结构已定、可先填 0 而不阻塞落地），与本条的通道 / 边界口径问题不是同一层。→ `systems/balance.md:1143`、`systems/monetization.md:198`。合不合场请用户裁定（见越界发现）。
3. **子项 6 的派生表是估算，不是实测值。** 它建立在「生效概率取该档 `[Base, Cap]` 中值」这一个假设上（真实值取决于失败频次推动的 `Accumulated`），且分母取完整轮回。**标注为待实测校准的派生量**，不得被当作独立锚引用。

---

## 仍需用户决定

### 【唯一一项】法则是否开放第三条获取渠道（事件 outcome 直接给予）？

→ **已裁决（2026-09-10 · 批量评审）：A. 不开。** 分域校验表上法则那一列的 `EventOutcome` / `ExchangePurchase` 两格由「※ 暂不开放」改判为**规则层封死**。⇒ 本草稿判定的「后端零改动、不落 counterpart」随之成立（该判定原为条件性结论，条件已满足）；无需授权后端库写入。

**背景（自包含）。** 「法则 / PlayerPower」是本作的**账号级永久能力**（跨轮回持有、默认开启、可被玩家用开关关掉）。它当前只有三条获取渠道：**渡劫成功时由「道统残卷」机制掷中发放** · **付费礼包给 1 条** · **成就组进度达 90% 发 1 条**。库内一直挂着一句「是否还有第三条获取渠道（事件 outcome 直接给予？）未陈述」——意思是：玩家在一次轮回的**冒险事件**里做出某个选择后，能不能当场拿到一条**账号级永久**法则。

这条问题在代码侧的具体表现是一张校验表上的两格：`systems/common-properties.md` 的 `(CarrierKind, Scope) → 允许的 Source 集合` 表中，法则那一列的 `EventOutcome`（事件产出）与 `ExchangePurchase`（商店购买）两格现在标着「※ 暂不开放」——**这两格翻不翻，就是这道题**。（`Source` = 记录「这件东西是怎么来的」的枚举字段，落在玩家的持有条目上。）

| 选项 | 具体含义 | 后果 |
|---|---|---|
| **A. 不开（推荐）** | 两格由「暂不开放」改判为**规则层封死**，与「事件产出不能给账号级古宝」同一条理由 | ✅ 零改动收口，五份文档的 derive 排除面同时收窄 · ✅ 账号级授予保持「打 / 买 / 成就」三条、全部后端可复算 · ✅ 残卷那条受调控的递减供给曲线不被旁路 · ❌ 关闭了一条「在冒险中拿到永久奖励」的体验位（但该体验位已由轮回级的神通 / 法宝 / 卡牌 / 功法四族承载） |
| **B. 只开 `EventOutcome`（事件产出）** | 事件 outcome 可给账号级法则，商店仍不卖 | ✅ 多一条稀有的高光时刻（「这次冒险让我永久变强了」）· ❌ 需重写「事件产出不能给账号级古宝」那条承重条并给出「为何法则可以、古宝不可以」的新判据 · ❌ 须同批裁决两个新问题（计不计入残卷的 `x`？占不占内容频次预算？）· ❌ **开出本作第一条后端不可复算的账号级授予通道**（现有三条渠道后端都能验，这条不能），须明确接受 · ❌ 需在后端设计库补一份配套草稿 |
| **C. 两格全开**（`EventOutcome` + `ExchangePurchase`） | 事件可给、商店也可用轮回内货币买账号级法则 | 含 B 的全部代价，另加：❌ 用轮回内货币（灵石 / 仙玉）买账号级永久资产，会把「账号级授予只走残卷 / 付费 / 成就」这条边界整个打开，且直接抵触「账号级持有物不进任何交易面」的既定封死 |

**推荐 A。** 四条理由：① **「事件产出不能给账号级古宝」这条承重结论的论据对法则一字不用改**（同为 `Scope == Player` 的账号级持有物），开法则而封古宝要额外背一条例外表；② 它会**架空残卷那条受 `x` 调控的递减供给曲线**——而那条曲线被既定文本标为「分发账户级加强的核心算法、不简化」；③ 它开出**本作第一条后端不可复算的账号级授予通道**，是既定防作弊边界的第一个例外；④ 它**没有对应的设计缺口要填**——「冒险中拿到东西」的体验位已由轮回级四族完整承载。

> **裁决方式：** 直接在本条目下写「→ 已裁决：A / B / C」即可，视同用户拍板。选 B 或 C 时，`## 后果` 一节列出的五项连带改动（含一份后端 counterpart 草稿）需一并纳入下一步。
