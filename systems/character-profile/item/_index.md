# item

> **法宝 / CharacterItem** —— CharacterProfile 持有的、随单次轮回存在的道具（字段 `magicPack: List<CharacterItem>`），含道具设计内容。占位结构，细节待定。
> **中文定名 = 法宝**；账号级的对应物是 **古宝 / PlayerItem**。**中文名不表达层级**。

**三层分工（承重）。** 「`CharacterItem` 指哪一层」一次写死，杜绝单复数漂移再长回来：

| 层 | 标识符 | 说明 |
|---|---|---|
| 内容定义（`Resource`，ContentRegistry 只读单例） | **`ItemData`** | 两层共用，`Scope == AbilityScope.Character` 者即法宝。**不存在 `CharacterItemData` 类型。** |
| 持有条目（存档态，落 `CharacterProfile`） | **`CharacterItem`** | 一份实例 = 集合的一个元素；带 `ItemId` / `Charges` / `status` 等，见 `common-properties.md`。 |
| 集合字段（`CharacterProfile` 上） | **`magicPack`**，类型 `List<CharacterItem>` | **储物袋的轮回级那一半**：储物袋是跨两个持久层的呈现视图，字段名直接命名它承载的那一半（法宝），堆叠规则挂在它上面；**不设容量上限**。 |
| 领域词 / 图鉴 | **法宝** / `CharacterItemCodex` | 本就是单数形态。 |

**通则：类型名恒为单数，复数只属于集合字段名。**

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **角色级道具随轮回存在。** CharacterProfile 通过 `magicPack: List<CharacterItem>` 持有，与账号级的 **PlayerItem**（`player-profile/player-item/`）区分开：CharacterItem 属单次轮回 / 单角色，**储物袋的轮回级那一半（`magicPack`）随轮回清理、账号级古宝不受影响**；PlayerItem 跨轮回持久、有使用次数限制。

- **开局的强制 buff 事件给一件法宝，三选一。** 起始事件中必有一个**强制事件**，玩家在其中同时选**一门功法**与**一件法宝**——各三选一（完整形态见 `../deck/_index.md`）。**这是法宝的第一条确定获取渠道**；候选须经 `AllEnabled()` 取抽取池并由带种子的 RNG 子流掷定。**事件侧的其余获取途径（哪些事件给、给几件）仍待定**。

- **见过的角色道具会进 CharacterItemCodex。** 图鉴族（见 `../../player-profile/codex/`）为角色道具单列一本——**图鉴是账号级、跨轮回持久的**，而 `magicPack` 随轮回清理：轮回结束后道具没了，但「见过它」这条知识留下。解锁触发（获得即记？见到即记？）未定，见图鉴族的待决问题。

- **法宝在战斗内以 `CardType.Item` 呈现（承重）。** 它同时是「事件中使用的道具」与「战斗内的卡牌类型」，两个身份并存。战斗内的形态：
  - **不洗进卡组**，故**不受抽牌运制约**（「像精灵球一样随时可用」），也不占手牌位、不受满手影响；抽牌堆的 seeded 确定性完全不受道具影响。
  - **存于储物袋（`magic pack`）** —— **储物袋是跨两个持久层的呈现视图**：轮回级法宝（`magicPack`）与账号级古宝（`PlayerProfile` 持有的 `PlayerItem`）**同时呈现**，条目上带 `AbilityScope { Character, Player }` 标识来源，与战斗内道具区同形。**跨战斗内外存在**、**容量不设硬上限**，界面由纵向滚动承载。**储物袋不是战斗概念**：战斗只从中筛出 `UsableScene` 含 `InCombat` 的那些，形成参战方持有的「本场可用道具」——跨两层的视图使这条筛选天然覆盖法宝与古宝两级，与战斗道具区「同时呈现两级」一致。**敌人没有储物袋但同样持有道具**（来自 `EnemyData`），正说明容器与本场视图必须分开。
  - **使用窗口 = 自己回合的行动阶段、栈为空时**，与出牌 / 启动式异能完全同窗口——**「随时」= 不受抽牌运制约，不是不受回合限制**，交互不回归。
  - **可带 mana 费用**，零费亦合法；战斗内的效果本体落在 `CombatUseEffects` 一格上（见下方「使用效果面」）。**道具不带异能**——三档异能都以「在场」为前提，而道具从不进场。
  - **本场配额与总剩余次数是两个字段**：本场配额落 `MaxUsesPerCombat`，总剩余次数落持有条目的 `Charges`，两道闸各自成立、取更严者（见下方「配额面」）。
  - **消耗即时经 `ProfileManager.TryApply` 写 CharacterProfile**，不攒到收口。
  - **推论：道具的强度必须比同费法术低**——「确定性 + 不占手牌位 + 不受抽牌运」三重优势若再配同等强度，会让卡牌相形见绌。**折价系数已按 `Charges` 分层定案**，见下。
- **同一 `ItemId` 的道具可以持有多份。** 储物袋按 `ItemId` **堆叠显示 `×N`**，让「同名道具满屏」的视觉噪音消失——**堆叠是呈现层的聚合，不承载任何容量语义**。**推论：`Charges` 是每一份实例各自的次数，不是「一个条目带一个总次数」。** **这正是集合元素类型必须是单数 `CharacterItem`（一份实例）而非「一条 Id 一行」的实证；按 `ItemId` 堆叠是呈现层的聚合，不是存储形态**。
- **折价系数 `itemPowerRatio` 按 `Charges` 分层，不是单一常数。** 判据一句话：**`道具的效果量 ≤ 同 ManaCost 法术的效果量 × itemPowerRatio(Charges)`**。
  - 三重优势逐项估价：不受抽牌运 **×1.40**（单张特定牌本场可用概率 ≈ 0.7）· 不占手牌位 **×1.10** · 使用时机确定 **×1.15** → 合计 ≈ ×1.77 → 等价折价 ≈ 0.57。
  - 但 **`Charges` 是一个反向修正**：次数越少，三重优势越不成立（只能用一次的道具，「不受抽牌运」只兑现一次）。故分层为 **-1（无限法宝）0.55 / ≥5 0.65 / 2–4 0.75 / 1（一次性）0.90**。
  - **这条分层让 monetization 的既定分工有了数字**：古宝（必有 `Charges`）落在 **0.75–0.90**，单次强度接近法术但总量被次数封死，正是「付费收益 = 关键时刻多几次转圜，而非永久变强」。单一常数会把**最该强的一次性古宝**削到与无限法宝同价。
  - **「不受抽牌运的溢价」写成公式而非常数**：`1 / P(本场见到该牌)`，`P` 由卡组规模与抽牌数算出，随二者调整自动跟随。
  - 系数表与前置依赖（「同费法术的效果量」本身仍待内容扩充后的统计校准定出）见 `systems/balance.md`。
- **`ItemData` 的字段形态。** `Id` · `DisplayName` / `Description`（`LocalizedText`）· `Scope: AbilityScope { Character, Player }`（决定持久层：CharacterProfile / PlayerProfile；**不按 Power / Item 分裂成两个 scope 枚举**）· `UsableScene { InCombat, OutOfCombat, Both }`（**必填**，非 `InCombat` / `Both` 者不进战斗道具区）· `ManaCost`（可选，允许为 0）· `Charges`（使用次数；古宝必有，法宝可为「无限 = -1」）· **`MaxUsesPerCombat`**（本场配额）· **`CombatUseEffects: EffectData[]`** · **`OutOfCombatUseOutcome: ProfileChangeSpec`** · `Rarity: RarityTier`（**必填**，缺失 → `PushError`）· `Subtypes` · `ExclusiveSource` / `ContentEnabled` / `CodexFlavor`（顶层共有）· 美术引用。**使用窗口是全局规则，不是字段。** 校验：`UsableScene` 缺失 → `PushError`（默认值会让漏填的东西悄悄进战斗）；`Scope == Player` 时 `Charges > 0` → 否则 `PushError`。**`SourceCode`（授予来源）不在此列——它是持有条目的字段，不是内容定义的字段**（见 `common-properties.md`）。
  - **不加的三格**（各有既定理由，写下以免重开）：`Price` / `Purchasable`（价格归定价表、可购性由 `ExclusiveSource` 免费给出，见 `../../adventure-event/exchange/_index.md`）· `IsProtected`（道具不进战场）· `Pool`（道具不洗进卡组，敌人侧持有列表由 `EnemyData` 给）。
  - **不设 `Abilities` 一格（承重）。** 异能三分在道具上一档都不成立：启动式经 `ActivateAbility(entryId, abilityId, targets)` 按**战场条目**寻址，道具不是战场条目、没有 `entryId`；静止式的生效判据是「载体一进场即生效、一离场即失效」，道具从不进场、永无生效时刻；触发式的注册面归战场（「谁在监听哪个时点」），由**在场的**条目注册，道具从不注册 ⇒ 永不触发。留着这一格的后果不是不整洁——内容作者给道具挂一条静止式异能，加载期合法、运行期静默无效，正是「能上线且线上不可见」那一类，必须提到「写不出来」这一级，而不设这一格就是。

- **使用效果面 = 按世界分两格，格的必填性由 `UsableScene` 驱动（承重）。**

  | 格 | 类型 | 何时必须非空 |
  |---|---|---|
  | `CombatUseEffects` | `EffectData[]` | `UsableScene ∈ { InCombat, Both }` |
  | `OutOfCombatUseOutcome` | `ProfileChangeSpec`（内容侧模板，形态见下） | `UsableScene ∈ { OutOfCombat, Both }` |

  **两格而不是一格，三条依据：** ① **执行引擎不同**——战斗内经 `StackManager > EffectProcessor > handler` 的五阶段流水线，战斗外经 `ProfileManager.TryApply` 的单点事务；一格塞两族语义则每次读它都要先分辨它属于哪一族，与「`AbilityData.ManaCost` 不塞进 `ProfileChangeSpec`」那条否决理由同构。② **值域不相交**——效果原语写道念 / mana / 战场条目 / 三区牌 / `counters`，`ProfileChangeSpec` 的各列没有一列能表达「产 3 点道念」，反之亦然；混装必然退化为两个可空子格加一条 XOR 校验，那就是两格的坏形态。③ **加载期可校验性**——两条 `LifeSpan` 校验（见下）因此落成一行读取，混装后要先分辨再筛，校验退化成 `switch`。
  - **`Both` 档两格皆填，这是如实而非冗余**：一件既能在战斗内产道念、又能在战斗外回寿的道具本就是两条不同的效果，它们**在任何一处都不会同时执行**。形状与 `AbilityData` 的 `Effects` / `StaticModifiers` 两格同构，差别只在必填性由 `UsableScene` 驱动而非由异能档驱动，故是「按档的必填表」而不是 XOR。
  - **命名带 `Use` 前缀**与已定的动词分工一致：`Use` 属道具、`Activate` 属异能，两个动词分给两条不同的来源路径。

- **战斗外使用效果 = 一份内容侧的 `ProfileChangeSpec` 模板，复用宽类型 + 恒空列断言。** 只开放三列，其余各列在内容侧恒空：

  | 列 | 是否开放 | 理由 |
  |---|:--:|---|
  | `Elements` | ✅ | 回寿、给灵石 / 仙玉、给经验——道具战斗外产出的主体 |
  | `CodexElements` | ✅ | 「使用后解锁一条图鉴词条」是幂等收录、无副作用；不开它日后必然再开一格 |
  | `Stats` | ✅ | 纯计数自增、失败不阻断，天然安全 |
  | `AbilityElements` | ❌ 恒空 | 道具不得授予 / 移除 / 禁用能力。账号级资产的授予渠道受 `ExclusiveSource` 与残卷机制约束，一件可购道具若能直接给法则，那两套约束全部旁路；与「事件产出不能给账号级法则或古宝」同一条理由，而道具比事件更易获取 |
  | `DeckElements` | ❌ 恒空 | 卡组构筑操作的闭合清单归 Research 面板的六类操作；从储物袋按一下就改卡组会绕开那个唯一编排点 |
  | `StatusChanges` · `EventStateChanges` · `RngElements` · `TraceElements` · `SettingChanges` · `PlotElements` · `ItemElements` · `ItemUseElements` | ❌ 恒空 | 前六列逐条都是「内容侧不该有权改写」的量（地图位置、事件态、RNG 子流状态、履历、账号设置、剧本进度），与它们「恒不走 modifier pipeline」是同一条判据的延伸；后两列由服务在组装时追加，不由内容作者书写——内容侧模板既不得声明次数扣减，也不得声明痕迹 |

  - **表达力上界取「恒定、无条件、无随机」。** 只有这一档能让使用结果**在按下之前原样呈现给玩家**，而储物袋详情卡片的形态本就是「看清楚再按」；条件门与「道具触发一个事件」两条都是纯加法，日后想开随时能开，反向收回则要改内容条目。它同时与「效果数值不做通用表达式」「战斗内代价面首版收敛为单一刻度」两条既定收敛纪律同款。
  - **恒不引入第二条效果结算管线。** `ProfileChangeSpec` 已经是一条带全量校验与单点提交的写入通道，为道具再造一条会立刻要求它自己的校验、自己的原子性与自己的日志。
  - **断言落加载期**（`ItemData` 是内容定义、没有物化环节）：恒空列的校验在 ContentRegistry 合并后全量执行，违规 → `PushError` + 条目 `Id`，与「坏数据在启动期大声失败」一致。
  - **符号方向沿用既定纪律**：内容侧写正数量值，取负的变换发生在组装时，每一层只做自己那一次变换。`Elements` 的每一行仍受 `ResourceElements` 表约束——道具改不了表里没有的资源。**modifier pipeline 照常在 `TryApply` 内生效**，`Elements` 侧仍是 opt-in 白名单：一件回寿道具吃不吃寿元消耗修正由表决定、不由道具决定；按符号分向保证「寿元消耗 −20%」的法则不会削掉道具的寿元回复。

- **战斗外使用不设目标面。** `OutOfCombatUseOutcome` 不带 `TargetSlots`，战斗外的使用入口不进入选目标态。三条支撑：目标的定义是「结算那一刻由 `TargetRef` 锚定到具体条目」，而战斗外没有战场、没有战场条目；`ProfileChangeSpec` 的每一列都是「按枚举键 / 内容 `Id` 索引」的形状，结构上装不下 `TargetRef`；已定的 UX 形态是在储物袋面板内经详情卡片的「使用」键直接使用（见 `ux/screen-flow.md`），本就没有选目标这一步。

- **战斗外使用的执行链路 = 一次组装、一次事务。**
  ```
  储物袋详情卡片「使用」键
    → profile-service 的使用门面 UseItemOutOfCombat(scope, itemId)
    → 一次组装 spec = OutOfCombatUseOutcome + 次数扣减那一笔 +（事件之外时）痕迹那一笔
    → ProfileManager.TryApply(spec)      ← 单次事务，全有或全无
  ```
  **扣次数与产出必须在同一次 `TryApply` 内**——分两次调用即「先扣次数后产出失败」这种半套写入，与 `CostSpec` / `RewardSpec` 被合并为单一 spec 的理由同源。门面签名、次数扣减与痕迹两列的定义与失败语义的权威在 `systems/services/profile-service.md`，本处不复述。

- **战斗外的一次使用不是决策点，而是一次即时提交（承重）。** 决策点的判据是「状态机即将停下来等玩家输入」，而这一次发生在**批次层**——`AdvanceEventAsync` 未在运行、没有状态机在推进，也没有可取消的长流程。它因此**不进任何既有决策点清单**（战斗侧 D0–D7 与非战斗四类的 R1 / R2 / X1 / X2 / X3 都是**事件内**清单）。但即时提交的两条判据同时成立：① 它是玩家主动按下的一次消费；② 不即时写就开出「用一颗丹 → 退出 → 重进」的无限回寿窗口 ⇒ **一次 `TryApply`，随之一次本地原子写**（「不允许提交了但不落盘」）。
  - **push 走 `PushPolicy.Debounced` + `SavePointReason.InventoryChanged`**（该 reason 同时覆盖随售）；例外只有一条：使用致某条资源触底 → 判负后走既有 `defeated` 的 `Immediate` flush。语义与清单权威在 `systems/services/sync-service.md`。
  - **不触发 `RefreshAfterEvent`，当前批 `eventOption` 一字不变。** 重算会消耗 `map` 子流 ⇒ 这一次当场变成一个真的决策点，并开出「用一颗丹刷新这一批事件」的通道。重算的触发点只有 `StartCycle` 与 `eventEnd` 两处。
  - **照跑终态判定**（`finaleFailed = false`）。战斗外道具不限于回寿，一件扣资源的道具能把某条资源打到 `Min`；不判定就会出现「资源触底但角色仍 `ongoing`」。判负 → `DefeatCharacter` → 落既有 `defeated` 的 `Immediate` flush。
  - **不计软阻塞闸门**（闸门只数事件级存档点），与事件内的即时提交同款。
  - **不消耗任何 RNG 子流**：战斗外使用效果恒定、无条件、无随机。日后若出现带随机效果的战斗外道具，那次提交须同批带 `RngElements`——既有不变式，不为本形态开例外。
  - **痕迹落 `CharacterProfile.pastItemUse`**，经 `ProfileChangeSpec.ItemUseElements` 与次数扣减、产出落在同一次事务内；字段面与读档校验见 `../_index.md`，两列的定义与失败语义见 `systems/services/profile-service.md`。

- **配额面 = `ManaCost` 一格 + `MaxUsesPerCombat` 一格，两格各管一件事。** `Charges` 的语义是 Profile 侧的总剩余次数（即时写、跨轮回持久）；拿它兼作本场配额上限会让一件**无限法宝**的「每场限用一次」在结构上写不出来，也会让一件 `Charges = 5` 的古宝的「本场配额」恒等于 5 而与该设计面无关。
  - **`MaxUsesPerCombat : int` 与 `AbilityData.MaxActivationsPerCombat` 逐字同构**：`-1` = 不限（缺省语义）· `>= 1` = 本场配额 · **`0` 未定义**——`0` 恰是 `[Export]` 的默认值，故漏填必须在加载期被拦。**可预判性判据照搬**：它是显式内容字段而非埋在效果条件里的判断，因为 UI 必须在点下去之前把不可用项灰显，而道具在随身抽屉里同样需要灰态预判。
  - **两侧的闸各自成立、取更严者**：玩家侧本场配额 **且** Profile 侧 `Charges > 0`；**敌人侧没有 Profile**，故它另受 `UsesThisCombat < Charges` 约束（`ItemData.Charges` 在敌人侧读作上限 / 初值，这条既有语义原样保留）。
  - **`ManaCost` 已存在、形态不动**；战斗外没有 mana，故 `UsableScene == OutOfCombat` 的条目 `ManaCost` 须为 0（见校验表），与「`CardType == Power` 且 `ManaCost != 0` → `PushError`」同构。
  - **存档零新增字段**：`CombatItemSave(ItemId, UsesThisCombat)` 结构原样，只是它比对的上限换了一格。

- **`ItemData` 的加载期校验（`PushError` 一律带条目 `Id` 与 `.tres` 路径）。**

  | # | 规则 | 违反时 |
  |---|---|---|
  | I-1 | `UsableScene ∈ { InCombat, Both }` 且 `CombatUseEffects` 为空 | `PushError` |
  | I-2 | `UsableScene ∈ { OutOfCombat, Both }` 且 `OutOfCombatUseOutcome` 为空 spec | `PushError` |
  | I-3 | `UsableScene == OutOfCombat` 且 `CombatUseEffects` 非空 | `PushError`（那些效果永不执行） |
  | I-4 | `UsableScene == InCombat` 且 `OutOfCombatUseOutcome` 非空 | `PushError`（同上） |
  | I-5 | `OutOfCombatUseOutcome` 的恒空列中任一非空（`AbilityElements` · `DeckElements` · `StatusChanges` · `EventStateChanges` · `RngElements` · `TraceElements` · `SettingChanges` · `PlotElements` · `ItemElements` · `ItemUseElements`） | `PushError`，指名是哪一列 |
  | I-6 | `OutOfCombatUseOutcome.Elements` 中某行的 `Key` 不在 `ResourceElements` 表内，或其 `Op` 不在该行 `AllowedOps` 内 | `PushError` + 报出 `CostKey` |
  | I-7 | `MaxUsesPerCombat == 0` | `PushError`（`0` 是未定义取值，与 `MaxActivationsPerCombat` 同款哨兵校验） |
  | I-8 | `UsableScene == OutOfCombat` 且 `ManaCost != 0` | `PushError` |
  | I-9 | `CombatUseEffects` 内出现 `BumpCounterEffect` 或 `CounterAtLeastCondition` | `PushError`。与 `CardData.OnPlay` 的同款校验逐字同构：`counters` 键空间闭合于 `<abilityId>[#<子名>]`，而道具的使用效果**没有宿主 `AbilityData`**，键根本拼不出来 |
  | I-10 | `CombatUseEffects` 的槽位总数 `> 32` | `PushError`（`FizzledSlots` 位掩码的硬上限，与卡牌侧同一条） |
  | I-11 | 同上 `> 4` | `PushWarning`（清单式软检查） |
  | I-12 | `Charges == -1`（无限）且 `UsableScene` 含 `OutOfCombat` | `PushError`。战斗外效果恒是一份写 Profile 的 `ProfileChangeSpec` 模板 ⇒ 一件无限次可用的战斗外道具就是一个**没有次数上限的重复消费源**：玩家可在批次层无限次点它，`pastItemUse` 被刷成一条无界序列。与既有两条准入校验（`PowerData` 不得产寿元、含寿元产出者不得含 `InCombat`）是**同一条判据的第三个实例**。代价明写：内容侧就此关掉「无限次可用的战斗外道具」整类书写位 |

  两条 `LifeSpan` 校验（见下方「回寿法宝」条）与本表并列，合起来是 `ItemData` 侧加载期校验的全部。

- **法宝可被「本轮回禁用」，也可被置换。** 禁用的统一判据是「截断在进入生效面那一步」（完整表见 `../power/_index.md`）：**法宝 ≈ 启动式异能**，故被禁用 = **不进「本场可用道具」列表**——储物袋里仍在、`Charges` 分毫不动，只是本轮回 / 本篇章 / 下一事件不可启动。**同 `ItemId` 多份按 `ItemId` 整体禁用**，不区分实例。「本场可用道具」的派生规则（按 `UsableScene` 筛储物袋）因此**加一条禁用过滤**。置换与法宝同池（`(CarrierKind, Scope)` 全同 + 同 `Rarity` + 排除已持有），见 `../../player-profile/player-power/_index.md`。禁用表字段见 `../_index.md` 的 `disabledAbility`。

- **法宝是唯一可售出的一族，售出有两条通道。** 售出面仅对 `CharacterItem` 开放（其余四族恒不可售，判据是**代码级常量**：可售出 ⟺ `ExchangeGoodsKind == CharacterItem`）。两条通道是：**Exchange 商店内售出**（权威在 `systems/adventure-event/exchange/_index.md`）与**储物袋随售**（权威落本处）。随售**直接复用**那条代码级常量，不加第二个条件、不另立族白名单；古宝在两条通道上均不可售。出售只在 **Exchange 与 event selection 时可发起**——与储物袋入口挂在角色状态条上、只出现于 EventOption 选择界面一致。

- **储物袋随售：常态的弃置途径。** Exchange event 的形态是以物易物或资源换取道具，**大部分可随售的道具在 Exchange 中并不提供回收**（首批内容以「不收购」为常态，属内容编排口径）。随售因此是玩家弃置不需要物品的主要途径，而它的回收率**显著低于商店档**——低回收率使「清仓」不构成一条经济来源，弃置的收益只是聊胜于无；少数**提供回收**的商店是**罕见的更优机会**，商店档恒优于随售档由一条加载期硬校验保证（校验行落 `systems/adventure-event/exchange/common-properties.md`），这正是它作为机会的全部意义。
  - **两档是两个独立旋钮，互不作缺省**：商店档 `SellRatePercent` 是逐条目字段（编排面，存在理由是让「只卖不收」的商店可编排）；随售档 `PackSellRatePercent` 是全局平衡资源单值（随售没有编排主体）。数值格与取值区间见 `systems/balance.md`。
  - **折算基准取「族 × 稀有度」定价表的基准价**，不含 `PriceOffset` / `DiscountPercent` / `ListPrice`（随售没有 stock rule、没有 offer，天然读不到），否则「在打折商店卖东西更亏」，玩家读不出因果。**已知代价**：定价表被 overlay 在轮回中途改动时随售价随之变化，落在「确定性边界只到同一 `contentVersion` 内」之内。
  - **同币回收**：币种由定价表那一格决定，落在收仙玉那一格的法宝随售即产出仙玉。净产出敞口的量级归统计校准，见 `systems/balance.md`。
  - **随售的来源标注 = `Source.PackSell`**（成员表与 `(CarrierKind, Scope)` 合法子集表的权威在 `systems/common-properties.md`）。它进 `TryApply` 的可追溯性日志与客服溯源，**不进存档**——随售没有 `PastEventEntry` 可挂，又不落 `SourceCode`（东西已不在），故**事后不可重建**，这条代价被明写接受。不新开 `PastEventEntry` 通道，不为「售出次数」设 `StatKey`。
  - **售出即时提交**，沿用既有路径，不新增存档点类型（玩家主动发起且本身自足）。它与战斗外使用同属批次层的储物袋操作，**push 走同一个 `SavePointReason.InventoryChanged`**（见 `systems/services/sync-service.md`）；随售的其余规则一字不变。

- **补天丹一类的回寿法宝 = 战斗外效果的第一个具体条目形态。** 它是寿元回复通道的载体之一（通道形态、展示门控与平衡护栏的权威在 `systems/adventure-event/common-properties.md`）：`Scope = AbilityScope.Character` · `UsableScene = OutOfCombat` · `Charges` 为有限正整数，其 `OutOfCombatUseOutcome.Elements` 里有一行 `(CostKey.LifeSpan, +n)`，使用时**即时经 `ProfileManager.TryApply` 写档**（与既定的「消耗即时写、不攒到收口」同一条纪律）。它同时是 `ExchangeGoodsKind.CharacterItem` 一族的普通商品，可经商店购入。
  - **两条加载期校验（`PushError` + 条目 `Id`）：**

    | 违规 | 依据 |
    |---|---|
    | `ItemData.Scope == Player` 且 `OutOfCombatUseOutcome.Elements` 含 `(Key == CostKey.LifeSpan && BaseValue > 0)` | 付费面五项排除的第一条**付费续命**：礼包从 `(Item, Player)` 池抽 2 件古宝，池中一旦有回寿古宝，「花钱 → 抽到 → 续寿」就是它的软形态——没有「撤销一次 `defeated`」，只是让 `defeated` 更晚到来，而那条压力线被按次稀释、效果相同 |
    | `OutOfCombatUseOutcome.Elements` 含 `(Key == CostKey.LifeSpan && BaseValue > 0)` 且 `UsableScene` 含 `InCombat` | **战斗内不得读写这条命**：一旦能在战斗里回寿，以生命值为终止条件的消耗战就从后门回来，而本作的战斗终止条件是道念比拼（资源纪律见 `systems/character-profile/life-span.md`） |

  - **能力条目一概不得产出寿元**（`PowerData` 两个 `Scope` 皆然），判据是次数——它没有 `Charges`，见 `../power/_index.md`。回寿只挂在**有明确次数上限的一次性消费**与**占事件位的事件产出**上。
  - **回寿的总量护栏在内容编排面**（出现频率、商店库存深度、定价），**规则层不设持有上限**——上方两道加载期校验管的是条目合法性，能囤多少交给编排。口径未定，见待决问题。

- **什么该做成一件法宝而不是一张卡 / 一个神通**：判据 = **有明确的使用次数上限、由玩家主动在某一刻花掉**（`Charges` 是节流阀；`ItemData` 不设 `Abilities` ⇒ 它写不出常驻 / 触发式效果）。三者共用的完整判据表与四条推论在 `../power/_index.md`，本文件**不复述**。

> 本文件夹为「每类角色道具 / 每份道具设计一个 Markdown」预留结构；具体语义见 `common-properties.md` 与待决问题。

Source: `handoffs/2026-09-03-character-power-mechanics.md` · `handoffs/2026-08-30-life-lifespan-merge.md` · `handoffs/2026-07-24-docs-restructure-class-model.md` · `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md` · `handoffs/2026-08-03-battlefield-stack-hand-limit-and-power-item-naming.md` · `handoffs/2026-08-04b-mtg-loanwords-card-types-and-intent-snapshot.md` · `handoffs/2026-08-06d-combat-open-questions-mass-closure.md` · `handoffs/2026-08-10c-ability-disable-replacement-and-player-statistics.md` · `handoffs/2026-08-12c-identifier-singular-collapse.md` · `handoffs/2026-08-12f-cultivation-technique-deck-building.md` · `handoffs/2026-08-17d-exchange-mechanics-and-transaction-discipline.md` · `handoffs/2026-08-17f-lifespan-restoration-paths.md` · `handoffs/2026-08-26-storage-pack-two-layer-view-and-combat-holdings.md` · `handoffs/2026-08-28-item-use-effect-face-and-carrier-kind.md`

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **角色级道具的内容目录未设计。** **已定：战斗内形态 = `CardType.Item`、储物袋、`UsableScene` 三档、`ItemData` 字段形态与两格使用效果面、本场配额格、加载期校验、消耗即时写 Profile、以及战斗外效果的第一个具体条目形态（回寿法宝）**（见上）；**载体判据亦已给出**，见 `../power/_index.md` 的跨载体边界判据表。**仍未设计**：道具的种类目录本身。
- **道具的获取途径：哪些事件给、给几件。** 战斗内形态与折价系数均已给出；**获取途径已有三条**（开局强制事件三选一 · 商店购入 · 事件产出），仍未给的是各条通道的分布与数量口径。→ `systems/adventure-event/`、`systems/balance.md`。
- **回寿法宝的总量护栏在内容编排面的具体口径未定（承重）。** 规则层不设持有上限后，出现频率 / 商店库存深度 / 定价共同承接这条护栏，而三者的口径都还空着——它是寿元这条压力线的唯一剩余数量闸。→ 本文档、`systems/adventure-event/`、`systems/balance.md`。

> **储物袋的 UI 形态**（不进主菜单、纵向滚动网格 + 筛选 chip、战斗内视图称「随身」= 角标 + 底部抽屉），见 `ux/screen-flow.md` 与 `ux/combat-ux.md`。条目数不设上限、可观 ⇒ **筛选 chip 与排序是必要的**，具体排布归 UX 侧。

## 对应
提炼至：`.claude/knowledge/systems/character-profile/item/`（待建）。
