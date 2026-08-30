# profile-service（服务）

> 档案服务：**`PlayerProfile` 与 `CharacterProfile` 的唯一写入面**；capability 聚合；成就。**判据 ② —— 需要事务性地跨多个字段一致写入。**

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

### 为何是**一个**服务同时拥有两层 profile

**`PlayerProfile` 持有 `List<CharacterProfile>`**（见 `systems/player-profile/_index.md`）——两层本就是一个聚合。由**单一 profile-service** 作为两者的唯一写入面，带来：

- **事务天然闭合。** 一次结算里「扣账号级 `PlayerItem` 使用次数 + 扣轮回级灵石 + 加卡牌」落在**同一事务**内，不需要跨服务协调原子性。
- **存档提交点唯一。** 一次变更 = 一次提交，交给 sync-service 上行，不会出现「半套写入已上行」的中间态。
- `life-cycle-service` / `combat-service` / `future-event-service` **都只经它写档**，自身不直接改 Profile 字段。

### ProfileManager：统一变更施加点

两个 Profile 的**一切变更**经一个入口，以**声明式的变更规格**驱动：

```csharp
var result = _profileManager.TryApply(spec);   // spec = ProfileChangeSpec（element 列表，BaseValue 带符号）
if (!result.Success)
{
    GD.PushWarning($"[ProfileManager-TryApply] insufficient, missing={result.MissingElement}");
    return;   // 全有或全无，不产生半成品状态
}
```

- **一个事件的收口是一次事务、一个存档点；事件内部的主动消费即时提交（承重）。** 收口侧由 life-cycle-service 在 `eventEnd` 合并为**一次** `TryApply`；事件内部玩家**主动按下的消费**（古宝使用次数、战斗过程中的血 / mana、Exchange 的逐笔交易）**即时经本 manager 写档，不攒到收口**。
  - **两条判据缺一不可：** ① 它是玩家主动按下的一次消费（不是结算算出来的后果）；② 不即时写就会开出「退出重进即回滚」的窗口，或让 `CanAfford` 这类前置校验读到一份与 `Evaluate(spec)` 分裂的影子余额。事件的**后果**一律留到收口。
  - **本 manager 的保证不因此变化**：「全有或全无」约束的是**每一次提交**内部，不是整个事件；即时提交**不新增存档点类型**，走既有的「变更后由 sync-service 上行」通道。
  - **连带：`PastEventEntry.AppliedChange` 是本次事件的最终账**，由 life-cycle-service 把逐笔已提交的 spec 累加进去（**记账，不再施加**）。语义与代价见 `systems/adventure-event/common-properties.md`。
- **全有或全无。** 一次 `TryApply` 是**单点提交**：要么全部 element 一起落，要么一个都不落——不允许半套写入。**事件推进不做「先全量校验付得起、否则整体拒绝」**：`selectCost` **无条件施加**，支付后由 life-cycle-service 做终态判定。**事务性与可负担性校验是两件事**——前者是本服务的硬保证，后者不在事件推进路径上。负值施加时的钳制与终态判据查 `ResourceElements` 表，见下。
- **它是已定 `selectCost` 复合成本类型的唯一消费点。**（它是 **`ProfileChangeSpec`**——由若干 `ChangeElement` 组成，`lifeSpanCost` 是其中一个 element；见 `systems/adventure-event/common-properties.md`。）**成本与产出用同一个类型**：`ChangeElement.BaseValue` 带符号（负 = 消耗，正 = 产出），使一次结算的扣减与收益天然落在同一事务内。
- **modifier pipeline 在此生效，但对 `Elements` 是 opt-in 白名单、缺省豁免（承重）。** 只有在 `ResourceElements` 表中显式登记了 `ModifierKey` 的那一行才走 `ApplyModifier(key, baseValue)`；`AbilityElements` / `Stats` 永不走。凡走的那一条，PlayerPower 的全局数值修正**不需要任何消费层写 `if (hasPowerX)`**——新增一个修正 = 新增一条数据，受影响系统零改动。缺省方向与分向规则见下方 `ResourceElements` 小节。
- **道统残卷占资源族的七个成员。** `PlayerPowerFragment` 的 7 个字段与 7 个 `CostKey` 一一对应——`PowerFragmentAccumulated`（累加 / 置值）、`PowerFragmentFinaleWinOrdinal`（自增）、`PowerFragmentCh1/Ch2/Ch3FirstWinDone`（置位）、`PowerFragmentLastRoll` / `PowerFragmentLastEffectiveChance`（置值），以及**授予法则**（复用 `GrantPower` 语义，但作为 `Spoils` 的一个 element 提交；**该 element 必须携带 `Source`，残卷这一路取 `Source.FinaleWin`**——凡授予 power / item 的 element 一律强制带来源，见 `systems/common-properties.md`）。它们与 `baseReward` / `lifeSpanCost` 落在 Finale 的**同一次 `TryApply`** 内，符合「一个事件的收口是一次事务、一个存档点」。**`Accumulated` 是万分比整数、施加后钳制到 `[0, 10000]`**——上界来自它自己的万分比语义，是钳制必须逐 element 配表（见下）而非定通则的例证之一。
- **`ProfileChangeSpec` = 平级只读列表，逐条按施加语义分列（承重）。** 判据是**施加语义根本不同就分列**，**列表数不进承重表述**——它随字段族增长，把数字写死等于每加一列就要改一次这条纪律。当前各列：`Elements`（资源，**标量值**：可钳制、`Add` 时可加且带符号分向、`Set` 时是已算好的绝对值、**按 `ResourceElements` 表逐行决定是否走 modifier pipeline**）· `AbilityElements`（能力，集合成员操作：幂等增删、无量纲、**绝不走 modifier pipeline**）· `Stats`（统计计数，纯计数：不钳制、失败不阻断、**绝不走 modifier pipeline**）· `StatusChanges`（Status 规则字段，**绝对置值**：赋一个已算好的值、不累加、按 key 的声明类型可为 id、**绝不走 modifier pipeline**）· `DeckElements`（卡组，**带层数的构筑变更与多重集增删**：层数不可加、散牌可同名多张、无 `Source`、**绝不走 modifier pipeline**）· `PlotElements`（剧本，**按 `ArcId` 的带载荷 upsert**：整条替换、不钳制、无量纲、**绝不走 modifier pipeline**）· `EventStateChanges`（事件态，**绝对置值**：三个事件态字段共用一列）· `RngElements`（RNG 子流，**按子流枚举键的双标量 upsert**：幂等置值、不钳制、无量纲、**绝不走 modifier pipeline**）· `TraceElements`（履历，**序列尾部只追加**：**不幂等**、无键、载荷是一整个 `PastEventEntry`、**绝不走 modifier pipeline**）· `SettingChanges`（账号级设置，**绝对置值**：按 key 配表钳制、无量纲、双可空载荷格、**绝不走 modifier pipeline**）· `CodexElements`（图鉴解锁，**按 `(Kind, Id)` 的幂等收录**：零 `Op`、只增不删、无量纲、不钳制、**绝不走 modifier pipeline**）· `ItemElements`（道具次数，**按 `(Scope, ItemId)` 选定一份实例后施加带符号增量**：有量纲、**不幂等**、按内容条目的 `Charges` 钳制、**绝不走 modifier pipeline**）· `ItemUseElements`（战斗外使用痕迹，**序列尾部只追加**：**不幂等**、无键、载荷是一整个 `ItemUseEntry`、**绝不走 modifier pipeline**）。压进一个带符号 `int` 是让类型说谎。类型定义、以及「一条新语义该落在哪一层（分列 / 加 `Op` / 配表加列）」的三级判据见 `systems/architecture.md`「共享核心类型」。**各列表在同一次 `TryApply` 内提交，「全有或全无、单点提交」不变。**
  - **`AbilityChangeElement` 只承载已定稿的 `Id`。** 「随机挑一条来移除」「限定只能动神通」都是**结算侧的选取规则**，在 spec 组装之前就已掷完——把随机性留在 spec 里等于让同一份 spec 重放两次得到不同结果，而 `PastEventEntry.AppliedChange` 正要求它可重放。这与「`EventOption` 产出即定稿、落存档不重算」是同一条纪律。
  - **置换 = `Remove` + `Grant` 两条 element，由 `PairKey` 配对，不是一条 `Replace`。** ① 原子性已由「全有或全无」免费提供，复合 element 等于在类型层重复实现事务；② `Grant` / `Remove` 各有独立用途（残卷授予法则是纯 `Grant`，事件负向条目是纯 `Remove`），一条 `Replace` 会让「给予半边」与独立 `Grant` 分裂成两条施加路径；③ `PairKey` 保住可读性（履历与 UI 要显示「你用 A 换了 B」，`AppliedChange` 重放时因果还原得出来）；④ **代价明写**：列表形态约束不了配对，故需一条入口校验。
  - **三类移除的表达就此闭合：** 置换型剥夺 = `Remove` + `Grant`（同 `PairKey`）· 三档禁用 = `Disable` 带 `Duration` · 不强制剥夺 = **不表达**（缺省，没有 element）· 战斗内 `IgnoresProtection` = **仍不进 spec**（只动战场条目，不写 Profile）。
  - **施加失败语义表：**

    | 情形 | 语义 | 处置 |
    |---|---|---|
    | `Remove` / `Disable` 的目标不在持有列表 | 可选缺失 | `PushWarning` + 该 element 空操作，**不使整批失败** |
    | `Grant` 的目标已持有 | 可选缺失 | 同上（候选池已排除已有，出现即内容错误） |
    | `AbilityId` 解析不到内容条目 | 必需缺失 | `PushError` + 整批拒绝（悬空 `Id` 写进 Profile 会污染存档） |
    | `PairKey` 配对不成立（非空却未恰好配成 `Remove` + `Grant`，或两者 `(CarrierKind, Scope)` 不同） | 必需缺失 | `PushError` + 整批拒绝 |
    | `Op == Grant` 且 `(CarrierKind, Scope, Source)` 不在合法子集表内，**或 `Source == Unknown`** | 必需缺失（代码组装缺陷） | `PushError` + 整批拒绝（与 `PairKey` 同档）。合法子集表见 `systems/common-properties.md`；它是**代码常量静态查表**，与置换同池判据共用 `(CarrierKind, Scope)` 键。**读档侧相反——遇不合法的既有条目 `PushWarning` + 保留原值**，回落 `Unknown` 会压低残卷的 `x` 并让档位回跳 |
    | `AbilityElements` 出现在 `SelectCost` 内 | 必需缺失 | `PushError` + 整批拒绝（不变式，见 `systems/adventure-event/common-properties.md`） |
    | `Source == ExchangeSell` 出现在 `Op == Grant` 的 element 上 | 必需缺失（代码组装缺陷） | `PushError` + 整批拒绝。它是**卖出侧**的记账值，只能出现在 `Op == Remove` 且 `(CarrierKind, Scope) == (Item, Character)` 的 element 上；合法子集表见 `systems/common-properties.md` |
    | `UpgradeTechnique` 的目标不在卡组 / 已达层数上限 | 可选缺失 | `PushWarning` + 该 element 空操作，**不使整批失败** |
    | `ForgetTechnique` / `RemoveLooseCard` 的目标不在卡组 | 可选缺失 | 同上 |
    | `LearnTechnique` 的目标已在卡组 | 可选缺失 | 同上（候选池已排除已持有，出现即内容错误） |
    | `DeckChangeElement.Id` 解析不到内容条目（功法 / 卡牌注册表） | 必需缺失 | `PushError` + 整批拒绝（悬空 `Id` 写进 Profile 会污染存档） |
    | `Op ∈ { LearnTechnique, UpgradeTechnique }` 且 `Tier < 1`，或其余 `Op` 且 `Tier != -1` | 必需缺失 | `PushError` + 整批拒绝 |
    | `DeckElements` 出现在 `SelectCost` 内 | 必需缺失 | `PushError` + 整批拒绝（不变式，与 `AbilityElements` 同款） |
    | `SelectCost.Elements` 中 `Key == LifeSpan` 且 `BaseValue > 0` | 必需缺失 | `PushError` + 整批拒绝。成本侧的 `LifeSpan` 恒为消耗向，寿元回复只走 outcome 侧；**它是取值域收紧、不是「某个列表恒为空」，故与上两条各自独立**，见 `systems/adventure-event/common-properties.md` |
    | `AbilityElements` 出现在 `EventOutcomeSpec` 任一侧且 `Op != Grant` | 必需缺失 | `PushError` + 整批拒绝。**outcome 侧只承载物化时定稿的授予**；置换 / 禁用走 `EventOption.AbilityChangeSlots` 的决策点，由 resolver 在结算时翻译为 element |
    | `EventOutcomeSpec` 任一侧的 `AbilityElements` 中 `Scope != Character`，或 `Source != EventOutcome` | 必需缺失 | `PushError` + 整批拒绝。**正向白名单**，与合法子集表 `EventOutcome` 一行逐格对齐（只开 `(Power, Character)` / `(Item, Character)`）——**事件产出不能给账号级法则或古宝** |
    | `EventOutcomeSpec` 任一侧的 `Elements` 中出现 `PowerFragment*` 七 key 或 `BundleRedeemedOrdinal` | 必需缺失 | `PushError` + 整批拒绝。残卷七格由 life-cycle-service 在 Finale 收口时组装（含账号级掷骰与幂等键），付费水位由兑现流程独占；内容条目声明它 = 一个 `.tres` 能伪造发放 / 兑现记录 |
    | `EventOutcomeSpec` 任一侧的 `Elements` 中 `Key == LifeSpan` 且 `BaseValue < 0` | 必需缺失 | `PushError` + 整批拒绝。成本侧那条的镜像：产出侧的 `LifeSpan` 恒为回复向。**它拦的是「内容作者自己写一条扣寿元的惩罚」**——寿元的负向来源恰两个（`SelectCost` 内的 `lifeSpanCost`、combat-service 组装进 `Spoils` 的战斗失败扣减），两者都由代码侧组装，`OutcomeSpec` 恒不得写负 `LifeSpan` |
    | `EventOutcomeSpec` 任一侧的 `Elements` 中 `Key == ManaLimit` 且 `\|BaseValue\| != 1` | 必需缺失 | `PushError` + 整批拒绝。**`manaLimit` 的单次变动幅度恒为 1**——该行的两个修正列被封死正是为守住它，产出侧不闭合等于从内容侧另开一个同效果的口，且**能上线、线上不可见** |
    | `EventOutcomeSpec` 任一侧的 `Stats` / `StatusChanges` / `PlotElements` / `EventStateChanges` / `RngElements` / `TraceElements` / `SettingChanges` / `CodexElements` **任一列非空** | 必需缺失 | `PushError` + 整批拒绝。**逐列各自独立判定、不合并成通则**（与成本侧同款纪律：日后新增的列未必都该被排除在 outcome 侧之外，新增一列时须逐列重新裁定而非默认继承）；判据是「内容作者能如实声明的量才进 `OutcomeSpec`，由服务算出绝对值或由代码采集的一律不进」，逐列依据见 `systems/services/future-event-service.md` |
    | 未知 `StatKey` | 可选缺失（统计层宽松口径） | `PushWarning` + 跳过该条，**不影响同批其余变更** |
    | `ChangeElement.Op` 不在该 `Key` 的 `AllowedOps` 内 | 必需缺失（代码组装缺陷） | `PushError` + 整批拒绝（准入留在表里，`Op` 只承载「这一次发生了什么」） |
    | `AddLooseCard` 的目标卡 `Pool == Enemy` | 必需缺失（代码 / 内容组装缺陷） | `PushError` + 整批拒绝。取池侧的「玩家侧抽取源只含 `Pool != Enemy`」只管抽取，本行是敌方专用牌进入玩家卡组前的**最后一道闸**——漏进去的后果在轮回中途才可见且已落存档，而 `Id` 也可能来自事件负向奖励的内容定义 |
    | `PlotElements` 出现在 `SelectCost` 内 | 必需缺失 | `PushError` + 整批拒绝（不变式，与 `AbilityElements` / `DeckElements` 同款、独立成行） |
    | `PlotKeyPointAssignment.ArcId` 经 `ContentRegistry` 解析不到 `PlotArcData` | 必需缺失 | `PushError` + 整批拒绝（悬空 `Id` 写进 Profile 会污染存档） |
    | `PlotKeyPointAssignment.NodeId` 解析不到，或其 `ArcId` 与本条不一致（串线） | 必需缺失 | `PushError` + 整批拒绝 |
    | `PlotKeyPointAssignment.State` 越界 | 必需缺失 | `PushError` + 整批拒绝 |
    | 同一批 `PlotElements` 内出现两条同 `ArcId` | 必需缺失（组装缺陷） | `PushError` + 整批拒绝（「一次 `eventEnd` 每条 arc 至多前进一个节点」⇒ 同批两条即缺陷；与读档侧「同 `ArcId` 多条 → `PushWarning` + 保留 `EnteredAtSeq` 最大」不冲突，后者处理的是坏档） |
    | `PlotKeyPointAssignment.EnteredAtChapter < 1` 或 `EnteredAtSeq < 0` | 必需缺失 | `PushError` + 整批拒绝 |
    | `EventStateChanges` 出现在 `SelectCost` 内 | 必需缺失 | `PushError` + 整批拒绝（不变式，与 `AbilityElements` / `DeckElements` / `PlotElements` 同款、独立成行） |
    | `EventStateAssignment` 的 `Key` 与非空载荷格不匹配（如 `Key == EventOption` 却填了 `ActiveEvent`，或多格同时非空） | 必需缺失（代码组装缺陷） | `PushError` + 整批拒绝 |
    | `Key == EventOption` 且各格皆为 `null`（置空） | 必需缺失 | `PushError` + 整批拒绝（**只有 `ActiveEvent` / `ActiveCombat` 可置空**；轮回进行中把当前批置空即让玩家无路可走） |
    | 同一批 `EventStateChanges` 内出现两条同 `Key` | 必需缺失（组装缺陷） | `PushError` + 整批拒绝（绝对置值下两条同 `Key` 意味着调用方自己也不知道最终该落哪一份） |
    | `Key == ActiveCombat` 且值非空，但施加后 `activeEvent == null` | 必需缺失（组装缺陷） | `PushError` + 整批拒绝（一场战斗必然归属某个正在结算的事件） |
    | `Key == ActiveCombat` 且值非空，但其 `EventInstanceId` 与施加后的 `activeEvent.EventInstanceId` 不等 | 必需缺失 | `PushError` + 整批拒绝。它是 `systems/character-profile/_index.md` 读档校验第 6 条的**施加侧对偶**，两侧同为拒绝 |
    | `RngStateAssignment.Stream` 不是已知子流 | 必需缺失（代码缺陷） | `PushError` + 整批拒绝 |
    | 同一批 `RngElements` 内出现两条同 `Stream` | 必需缺失（组装缺陷） | `PushError` + 整批拒绝（绝对置值下两条同键 = 组装方自己也不知道该落哪一份，与 `EventStateChanges` 同款） |
    | `RngStateAssignment.DrawCount` 小于 profile 现值（回退） | 必需缺失 | `PushError` + 整批拒绝。单调不减是「不许回滚 `State` 重掷」的可机械校验形态，与 `RerolledCount` 的单调校验同构。**只约束轮回进行中的 upsert**——子流初始化不走本列，见下 |
    | `RngStateAssignment.DrawCount` 与本次提交声明的消耗数不一致 | 可选缺失（诊断保险） | `PushWarning` 带 `characterId` + 子流名，照常提交 |
    | `TraceElements` 条目的 `Seq != 现有 pastEvent 末条 Seq + 1`（空列表时 `!= 0`） | 必需缺失 | `PushError` + 整批拒绝（「只追加 + 单调递增不复用」的入口保证；读档侧既有的 `Seq` 不连续 / 重复校验是它的对偶） |
    | `TraceElements` 条目的 `InstanceId` 为空 | 必需缺失 | `PushError` + 整批拒绝 |
    | `TraceElements` 条目的 `EventId` / `RevealedEventId` / `Enemy.EnemyId` 经 `ContentRegistry` 解析不到 | 必需缺失 | `PushError` + 整批拒绝（施加侧写严；读档侧对同一字段仍取 `PushWarning` + 降级——读档侧的悬空来自 overlay 热更，施加侧的来自组装缺陷） |
    | 同一批 `TraceElements` 出现两条 | 必需缺失（组装缺陷） | `PushError` + 整批拒绝（一次事件恰一条痕迹） |
    | `TraceElements` 条目的 `AppliedChange.TraceElements` 非空 | 必需缺失 | `PushError` + 整批拒绝（自指防呆：一条痕迹的账里不该再装着一条痕迹） |
    | `RngElements` 出现在 `SelectCost` 内 | 必需缺失 | `PushError` + 整批拒绝（不变式，与 `AbilityElements` / `DeckElements` / `PlotElements` / `EventStateChanges` 同款、独立成行） |
    | `TraceElements` 出现在 `SelectCost` 内 | 必需缺失 | `PushError` + 整批拒绝（不变式，同上款、独立成行） |
    | `ChangeElement.Key` 在 `ResourceElements` 中无对应行 | 必需缺失（代码缺陷） | `PushError` + 整批拒绝（缺行 = 取值域、终态与修正准入三者皆不明） |
    | `StatusAssignment.Key` 在 `StatusFields` 中无对应行 | 必需缺失（代码缺陷） | `PushError` + 整批拒绝（缺行 = 值类型与取值域皆不明） |
    | `Id` 型 `StatusAssignment` 的值经 `ContentRegistry` 解析不到 | 必需缺失 | `PushError` + 整批拒绝 |
    | `SettingAssignment.Key` 在 `SettingFields` 中无对应行 | 必需缺失（代码缺陷） | `PushError` + 整批拒绝（缺行 = 值类型与取值域皆不明；与 `StatusAssignment` 同款） |
    | `SettingAssignment` 的 `Kind` 与非 `null` 载荷格不匹配（`Bool` 型却填了 `IntValue`，或两格同时非 `null`） | 必需缺失（代码组装缺陷） | `PushError` + 整批拒绝 |
    | `Int` 型 `SettingAssignment` 的值越界 | **可选缺失** | `PushWarning` + **钳制**到 `[Min, Max]`，**不整批拒绝**——把一个滑条拖过头变成一次整批失败不成比例 |
    | 同一批 `SettingChanges` 内出现两条同 `Key` | 必需缺失（组装缺陷） | `PushError` + 整批拒绝（绝对置值下两条同 `Key` 意味着调用方自己也不知道该落哪一份；与 `EventStateChanges` 同款） |
    | `SettingChanges` 出现在 `SelectCost` 内 | 必需缺失 | `PushError` + 整批拒绝（不变式，与 `AbilityElements` / `DeckElements` / `PlotElements` / `EventStateChanges` 同款、独立成行。理由同构：成本侧只放**可如实计价的量**，而「把音量调到 60 值多少寿元」无法回答） |
    | `CodexUnlock` 的 `(Kind, Id)` 在该本图鉴中已存在 | **正常** | 该 element **空操作，不告警**。重复遭遇 / 重复获得是常态，不是缺陷；告警会刷屏 |
    | 同一批 `CodexElements` 内出现两条同 `(Kind, Id)` | 正常 | 去重保留一条，**不告警**（同批多次收录同一条目是合法的） |
    | `CodexUnlock.Id` 经 `ContentRegistry` 解析不到 | 必需缺失 | `PushError` + 整批拒绝（悬空 `Id` 写进 Profile 会污染存档，与 `DeckChangeElement.Id` / `PlotKeyPointAssignment.ArcId` 同档）。**与读档侧相反**——读档侧取 `PushWarning` + 保留条目，这条读写不对称与 `PlotElements` 同款、同理由 |
    | `CodexElements` 出现在 `SelectCost` 内 | 必需缺失 | `PushError` + 整批拒绝（不变式，与 `AbilityElements` / `DeckElements` / `PlotElements` / `EventStateChanges` 同款、独立成行。理由同构：成本侧只放**可如实计价的量**，而「解锁一条图鉴词条值多少寿元」无法回答） |
    | `ItemChargeElement` 的 `(Scope, ItemId)` 无任何持有实例 | 可选缺失 | `PushWarning` + 该 element 空操作，**不使整批失败**（与 `Remove` 目标不在持有列表同档） |
    | `(Scope, ItemId)` 的全部实例 `Charges == 0` | 可选缺失 | `PushWarning` + 空操作（UI 本不该让它可按，这是防御位） |
    | `ItemChargeElement.ItemId` 经 `ContentRegistry` 解析不到 | 必需缺失 | `PushError` + 整批拒绝（悬空 `Id` 写进 Profile 会污染存档） |
    | `ItemChargeElement.Delta > 0` | 必需缺失 | `PushError` + 整批拒绝（首批只开消耗向，正向书写位待次数补充机制答定后放开） |
    | `ItemChargeElement.Delta == 0` | 必需缺失 | `PushError` + 整批拒绝（空操作 element 是组装缺陷） |
    | `ItemElements` 出现在 `SelectCost` 内 | 必需缺失 | `PushError` + 整批拒绝（不变式，与 `AbilityElements` / `DeckElements` / `PlotElements` / `EventStateChanges` 同款、独立成行。理由同构：成本侧只放**可如实计价的量**，而「扣一次道具次数值多少寿元」无法回答） |
    | `ItemUseElements` 条目的 `Seq != 现有 pastItemUse 末条 Seq + 1`（空列表时 `!= 0`） | 必需缺失 | `PushError` + 整批拒绝（「只追加 + 单调递增不复用」的入口保证，与 `TraceElements` 同款；读档侧的 `Seq` 不连续 / 重复校验是它的对偶） |
    | `ItemUseElements` 条目的 `AfterEventSeq` 大于现有 `pastEvent` 末条 `Seq`，或 `< -1` | 必需缺失 | `PushError` + 整批拒绝，带 `characterId` + `seq`（越界的归并坐标会让寿元曲线锚不到任何一条痕迹） |
    | `ItemUseElements` 条目的 `ItemId` 经 `ContentRegistry` 解析不到 | 必需缺失 | `PushError` + 整批拒绝（施加侧写严；读档侧对同一字段取 `PushWarning` + 降级，与 `TraceElements` 的读写不对称同款、同理由） |
    | 同一批 `ItemUseElements` 出现两条 | 必需缺失（组装缺陷） | `PushError` + 整批拒绝（一次使用恰一条痕迹） |
    | `ItemUseElements` 条目的 `AppliedChange.ItemUseElements` 非空 | 必需缺失 | `PushError` + 整批拒绝（自指防呆：一条痕迹的账里不该再装着一条痕迹） |
    | `ItemUseElements` 出现在 `SelectCost` 内 | 必需缺失 | `PushError` + 整批拒绝（不变式，同上款、独立成行） |
    | 表内登记的 `ModifierKey` 无任何法则注册修正 | 正常，非失败 | `ApplyModifier` 原值返回 |

  - **可追溯性日志（非告警）：** 施加任一 `AbilityChangeElement` 时打一行 `[ProfileManager-TryApply] ability op=Remove kind=Power scope=Player id=xxx pair=yyy`。能力得失是玩家最在意、也最容易被投诉的一类变更，必须在日志里留痕。
  - **施加 `Disable` 时若 `activeCombat != null`**，同步调用战场侧的移除路径——**复用 `IgnoresProtection` 已有的「从战场移除一个受保护 `Power` 条目」内部路径**，不新写第二条；并在 `#if DEBUG` 下 `PushWarning`（该路径在当前链路下不可达，属纪律阶梯第 3 级的大声失败）。
  - **`PowerScope` / `ItemScope` 合并为单一 `AbilityScope`**（值域与语义完全相同；保留两个会逼 element 侧写一层无意义的转换。当前无线上存档 ⇒ 零迁移）。
- **具名 element `BundleRedeemedOrdinal`：置值语义，表中两个修正列均为空（承重）。** 它被赋为**本次兑现的** `ordinal`（不是加法），落 `ProfileChangeSpec.Elements`，与礼包的三条 `Grant` 在**同一次 `TryApply`** 内提交（全有或全无）。留空的理由与统计层同源，只是后果严重得多：**经 pipeline = 一条法则能伪造兑现记录**。水位推进与「是否抽中」无关——闸 ③ 真发生时该项计未兑现、不补发，但水位照常置为 `ordinal`，否则客户端每次启动重掷同一 `ordinal`、抽空池、反复报错，幂等键当场失效。**礼包的授予序号 `BundleGrantOrdinal` 不在本表、也不是 `CostKey` 成员**：它只由后端在验票事务内推进、经 pull 下行，客户端永不组装带该 key 的 element，缺行时的「必需缺失 → `PushError` + 整批拒绝」正是这条的硬闸。兑现流程与三道闸见 `systems/monetization.md`。
- **统计计数经 `StatDelta` 写入，走宽松口径。** `PlayerStatistics` 字段全部只读，**唯一写入路径是 `Stats` 列表经 `TryApply`**，不提供 setter；它与规则字段**同批、同事务**提交。宽松之处只有两条落在本服务：**未知 `StatKey` 跳过而非整批失败**、**统计 element 绝不经过 modifier pipeline**（否则一条法则能改写统计数字）。其余三条（读档校验、上行被拒、后端）见 `sync-service.md`。
  - **交易侧不向本列贡献任何 `StatDelta`**：Exchange 的购买 / 售出不设「购买次数」一类的 `StatKey` 成员，判据与被接受的代价见 `systems/adventure-event/exchange/_index.md`。
- **Status 规则字段经 `StatusChanges` 写入，语义是绝对置值（承重）。** `CharacterProfile.Status` 上的规则字段（`CurrentLocationId` · `LocationEventCount` · 两个隐藏属性 band）不提供 setter，**唯一写入路径是 `StatusChanges` 列表经 `TryApply`**，与资源 / 能力 / 统计**同批、同事务**提交。**提交的是已算好的绝对值**——「+1」「归 0」「按前值 + `AppliedChange` 算出的新档」都由组装方（life-cycle-service）先算成绝对值再置入，本 manager 不做任何加减。
  - **逐行查 `StatusFields` 表，与 `ResourceElements` 同款判据。** 每个 key 在表中占一行 `(Kind, Min, Max)`：`Kind` 决定 `IntValue` / `StringValue` 哪一格有效（另一格填缺省即可，**双字段单列表的浪费是每条一个空引用，代价近零**），`Min` / `Max` 是整型 key 施加后的取值域。**拆成 `StatusInts` / `StatusIds` 两个列表被否决**——分表必然出现「加了这张忘了那张」，与 `ResourceElements` 五列合表同一条判据；合表后「哪一格有效」是可机械校验的一列。
  - **`Id` 型置值解析不到 → `PushError` + 整批拒绝。** 与 `CurrentLocationId` 的读档校验口径一致：location 是恒启用的结构性内容，解析不到即坏档。**不取「`PushWarning` + 跳过该条」**——跳过会产生「寿元扣了但人没走成」的半套状态，正是「全有或全无」要防的东西。
  - **恒不经 modifier pipeline。** 理由与统计层同源且更重：`CurrentLocationId` 若可被一条法则改写，等于让内容改写玩家的地图位置；band 若可被改写，等于让法则伪造隐藏属性档位。
  - **启动期断言表覆盖 `StatusKey` 的全部成员**，与 `ResourceElements` 同档——漏行即值类型不明，必须在启动期 `PushError`，而不是在轮回中途撞上。
- **卡组变更经 `DeckElements` 写入，语义是带层数的构筑操作与多重集增删（承重）。** `CharacterProfile` 的卡组（**功法 `Id` + 层数**列表 + 游离散牌 `Id` 列表）不提供 setter，**唯一写入路径是 `DeckElements` 列表经 `TryApply`**，与资源 / 能力 / 统计 / Status **同批、同事务**提交。五个 `Op`（`LearnTechnique` / `UpgradeTechnique` / `ForgetTechnique` / `AddLooseCard` / `RemoveLooseCard`）的语义与卡组侧规则见 `systems/character-profile/deck/_index.md`。
  - **`Tier` 是目标层数，不是增量。** 本 manager 直接把该功法置为 `Tier` 层，不读当前层数做加法——`AppliedChange` 要求这条账可直接重放，写增量会让重放结果依赖当时的层数。
  - **游离散牌的增减两向对称，一条 element 动一张。** `AddLooseCard` 加一张（`Id` = 卡牌 `Id`、`Tier` 写 `-1`，与 `RemoveLooseCard` 完全同款、`DeckChangeElement` 零字段增量），`RemoveLooseCard` 移一张；同名多张一律提交多条 element，**两向都不设 count 字段**（一条 element ↔ 一次可重放的操作，与其余各列同款）。
  - **`AddLooseCard` 的目标已在卡组 → 正常追加一张，既不是失败也不是空操作。** 散牌是多重集，同一张业障可在卡组里出现多张；套用 `LearnTechnique` 的「已在卡组 → `PushWarning` + 空操作」会**静默吞掉第二张**，故它不进失败语义表。
  - **恒不经 modifier pipeline。** 一条法则若能把「层数 +1」放大成 +2，「进化 = 整组替换、每层一整套卡牌定义」当场失效——不存在「1.5 层」的卡牌定义可供展开。
  - **`DeckElements` 在 `SelectCost` 内恒为空**，与 `AbilityElements` 同一条不变式、同样落为物化组装后的断言 + 内容模板加载期校验。理由同构：成本侧只放**可如实计价的量**，而「一门功法值多少寿元」无法回答。
  - **增列 ⇒ bump 存档 schema 版本**（当前无线上存档 ⇒ 空迁移，走既有 MigrationManager 骨架）。`PastEventEntry.AppliedChange` 随 `ProfileChangeSpec` 自动获得卡组变更的账，**不新增字段**。
- **剧本推进经 `PlotElements` 写入，语义是按 `ArcId` 的整条 upsert（承重）。** `CharacterProfile.plotKeyPoint` 不提供 setter，**唯一写入路径是 `PlotElements` 列表经 `TryApply`**，与资源 / 能力 / 统计 / Status / 卡组**同批、同事务**提交；条目类型 `PlotKeyPointAssignment` 是 `PlotKeyPoint` 本体的镜像。
  - **提交的是已算好的绝对状态，本 manager 不认识剧本图。** PlotManager 先按剧本图算出「这条 arc 该在哪个节点、什么态」，`ProfileManager` 只按 `ArcId` upsert，**不做任何推进逻辑**——推进规则、单步节制、出边求值、`ExclusiveGroup`、队列出队全部留在 PlotManager。与 `StatusChanges`「提交已算好的绝对值」同一条纪律，也使 `AppliedChange` 可直接重放（重放结果不依赖当时在哪个节点）。`ChooseBranch` 亦经本入口写入，它组装出的同样是一条 `PlotKeyPointAssignment`。
  - **零 `Op`，因为永不删除。** 「保留惰性条目而非删除」+ 四态 `Queued | Active | Completed | Abandoned` 全部由 `State` 表达（`Abandoned` 是一个态，不是删除）⇒ 不需要 `Remove` 向；`Queued → Active` 的出队也只是一次 upsert。
  - **恒不经 modifier pipeline。** 理由与 `StatusChanges` 同源且同重：一条法则若能改写剧本进度，等于让内容改写玩家在剧情里的位置。
  - **`PlotElements` 在 `SelectCost` 内恒为空**，与 `AbilityElements` / `DeckElements` 同款不变式、各自独立成行，同样落为物化组装后的断言 + 内容模板加载期校验。理由同构：成本侧只放**可如实计价的量**，而「推进半条剧本线值多少寿元」无法回答。
  - **施加侧写严、读档侧读宽，不对称是有意的。** 施加侧的悬空来自代码 / 内容组装缺陷，此刻拒绝还救得回来；读档侧的悬空来自 overlay 热更 / 版本回退，此时拒绝等于让一次内容更新废掉玩家的轮回，故降级为该条惰性并保留条目（见 `systems/services/plot-manager.md`）。先例是 `(CarrierKind, Scope, Source)` 合法子集表的同款读写不对称。
  - **拓扑校验不在本入口。** 「新 `NodeId` 必须是当前节点的一条出边或等于当前节点」由 PlotManager 在推进时 `#if DEBUG` 断言；本 manager 只校验 `Id` 可解析 / 不串线 / 同批不重复。唯一组装方的内部不变式落在纪律阶梯第 3 级即可，升到入口强校验换来的是分层污染。
  - **可追溯性日志（非告警）：** upsert 时打一行 `[ProfileManager-TryApply] plot arc=<ArcId> node=<NodeId> state=<State>`。与能力得失同理——剧本推进是玩家会来问「我这条线怎么突然变了」的一类变更。
  - **增列 ⇒ bump 存档 schema 版本**（当前无线上存档 ⇒ 空迁移）。`PastEventEntry.AppliedChange` 随 `ProfileChangeSpec` 自动获得剧本推进的账，**不新增字段**。
- **事件态经 `EventStateChanges` 写入，语义是整块绝对置值（承重）。** `CharacterProfile.eventOption`（当前批快照）与 `CharacterProfile.activeEvent`（结算期间的权威副本）不提供 setter，**唯一写入路径是 `EventStateChanges` 列表经 `TryApply`**，与资源 / 能力 / 统计 / Status / 卡组 / 剧本**同批、同事务**提交。条目类型 `EventStateAssignment` 按 `Key` 分成两个具名可空载荷格，**不用裸 `object`**——贯穿链路的类型一致性不做隐式装箱，且「哪一格该有效」因此是可机械校验的一列（与 `StatusAssignment` 的双字段单列表同构）。
  - **提交的是已算好的整块，本 manager 不做合并 / 增量。** 组装方（life-cycle-service）先算出完整的 `EventOptionSave` / `ActiveEventState` 再置入；两处派生（Explore 揭示 · Exchange 刷新）各是一次对 `activeEvent` 的整体置值。与 `StatusChanges` / `PlotElements`「提交已算好的绝对值」同一条纪律，也使 `AppliedChange` 可直接重放。
  - **它是 Exchange 刷新那一笔原子性的承载。** `ChangeElement(SpiritStone, -刷新价)` 与新库存 + `RerolledCount` 必须落在**同一次** `TryApply`：只落 `-spiritStone` 则同一笔钱可再刷一次（正是防重掷纪律封死的那个窗口），只落库存则免费刷新。分列而非塞进既有列，是因为 `Elements` 只装带符号的量、`StatusChanges` 的值是标量或 id，都装不下一个结构块。
  - **恒不经 modifier pipeline。** 一条法则若能改写 `RerolledCount` 或商店库存，等于账号级内容改写轮回级的定稿实例。
  - **`EventStateChanges` 在 `SelectCost` 内恒为空**，与 `AbilityElements` / `DeckElements` / `PlotElements` 同款不变式、各自独立成行，同样落为物化组装后的断言。理由同构：成本侧只放**可如实计价的量**，而「把一个事件态置成某个值值多少寿元」无法回答。
  - **`activeCombat` 与它们共用本列，由 combat-service 组装。** 战斗内每个决策点各提交一次 `EventStateChanges[ActiveCombat = 当前局面]`（与 `RngElements[combat 子流]` 同批），`eventEnd` 收口时置空。它在六面上与 `activeEvent` 全部对齐 ⇒ 判据明文要求不分列；**两个中间态字段仍不合并**，共用的只是写入通道。这使「一切写入经 `TryApply`」不再有例外。
  - **入口做 `ActiveCombat.EventInstanceId` 一致性校验，代价明写。** 它与「`PlotElements` 的拓扑校验不在本入口」略有张力；取入口的理由是**读档侧对同一条已是 `PushError` 级**，两侧口径一致比分层纯度更值钱，且比对的两样东西都在同一次施加的可见范围内——本 manager 不需要认识任何战斗规则。
  - **可追溯性日志（非告警）：** 置值时打一行 `[ProfileManager-TryApply] eventState key=<Key> instance=<EventInstanceId | batch=<BatchId>>`。它是「退出重进后看到的库存 / 揭示态对不对」这类问询的第一手证据。
  - **增列 ⇒ bump 存档 schema 版本**（当前无线上存档 ⇒ 空迁移）。
- **RNG 子流状态经 `RngElements` 写入，语义是按子流键的绝对置值 upsert（承重）。** `CharacterProfile.rng.stream[]` 的 `State` / `DrawCount` 不提供 setter，**唯一写入路径是 `RngElements` 列表经 `TryApply`**，与其余各列**同批、同事务**提交。它买到的是一条既有不变式的机械保证：**凡消耗了子流随机的提交，该子流的 `State` / `DrawCount` 必须在同一次原子写内更新**——在此之前这条不变式没有任何结构能让「忘了带」被检出。
  - **`AppliedChange` 照常含 `RngElements`。** 痕迹里的账因此天然带上 RNG 终态，「一条可直接重放的账」这条定性完整成立；每条至多几条 `(Stream, State, DrawCount)` 三元组，体积可忽略。
  - **`CycleSeed` 与子流初始化不走本列。** 轮回开始时生成 `CycleSeed`、派生四条子流是 `StartCycle` 的附带写入，篇章重试则整个换一套新的随机流；本列只承载轮回进行中的 upsert。**单调不减校验因此不需要任何例外口子**——把归零也塞进本列，就得给一条承重校验开「整流重置例外」，而例外口子正是本列要消掉的东西。
  - **恒不经 modifier pipeline。** 一条法则若能改写随机流状态，它改写的是整条确定性链，比改写付费凭证更重。
  - **`Seed` 不进 spec**：`streamSeed` 由 `CycleSeed` 与子流名重算得出，存档里存它只为诊断与自校验；把可重算的值放进 spec 等于让重放依赖一份冗余真值。
  - **不为它配一张逐 key 的表。** 四条子流在取值域、终态、修正准入上完全相同，配一张四行全同的表只会长出一处必须与 `RngStream` 同步增删的枚举镜像。
  - **本 manager 不向 SeedManager 索取状态。** 组装方把子流终态放进 spec 再交来；反向索取要求 profile-service 读 life-cycle-service，与「服务之间不读写对方字段」相反，且会让 spec 里没有 RNG 条目的那条账重放不出同一份 `State`。
  - **可追溯性日志（非告警）：** upsert 时打一行 `[ProfileManager-TryApply] rng stream=<Stream> state=<State> draw=<DrawCount>`。
  - **增列 ⇒ bump 存档 schema 版本**（当前无线上存档 ⇒ 空迁移）；`rng` 块的字段一格未改，改的只是「谁把值写进去」。
- **修行历程的追加经 `TraceElements` 写入，语义是序列尾部只追加（承重）。** `CharacterProfile.pastEvent` 不提供 setter，**唯一写入路径是 `TraceElements` 列表经 `TryApply`**，与其余各列**同批、同事务**提交。**直接后果：「记入 `pastEvent`」并入收口那一次 `TryApply`**，「一个事件的收口是一次事务、一个存档点」由结构兑现。
  - **载荷直接是 `PastEventEntry`，不建镜像类型。** 它字段众多且随快照判据继续增长，镜像一份等于制造两张必须同步增删的字段表；`PlotKeyPointAssignment` 用镜像的理由是五个标量的镜像成本近零，此处不成立。
  - **一次事件恰一条**，同批两条即组装缺陷。
  - **`AppliedChange` 恒不含 `TraceElements`，也恒不含 `ItemUseElements`（不变式）。** 否则一条痕迹的账里装着一条痕迹。落为入口断言，见上表；两条各自独立成行（一条痕迹的账里可能出现另一族痕迹，故不能合并成一条按列族分支的检查）。**这条断言只覆盖这两列**：`RngElements` 照常入账，理由见上。
  - **累加进 `AppliedChange` 的只有变更，不含「账本本身」（承重）。** 由 life-cycle-service 把逐笔已提交的 spec 累加进痕迹时，`EventStateChanges` 这类装的是**整块状态快照**而非一笔变更的列**被剔除**，不进账。不剔除，一次战斗事件会把战斗内每个决策点提交的整块 `ActiveCombat`（单点 2–4 KB）逐份灌进一条痕迹，与「战斗类痕迹只存 `EnemyId` + `Level` 轻摘要」的体积纪律正面相抵。剔除清单与理由归 `systems/adventure-event/common-properties.md`。
  - **恒不经 modifier pipeline。** 一条法则若能改写履历，它改写的是「到底发生过什么」这条账。
  - **施加侧写严、读档侧读宽。** 三个内容 `Id` 在施加侧解析不到即整批拒绝，读档侧仍取 `PushWarning` + 降级；两侧的悬空来源不同（组装缺陷 vs overlay 热更）。
  - **可追溯性日志（非告警）：** 追加时打一行 `[ProfileManager-TryApply] trace seq=<Seq> instance=<InstanceId> outcome=<Outcome>`。
  - **增列 ⇒ bump 存档 schema 版本**（当前无线上存档 ⇒ 空迁移）；`pastEvent` 的 schema 一字未改。
- **账号级设置经 `SettingChanges` 写入，语义是按 key 的绝对置值（承重）。** `PlayerProfile.gameSetting` 的字段不提供 setter，**唯一写入路径是 `SettingChanges` 列表经 `TryApply`**。施加语义是**绝对置值 · 无量纲 · 按 key 配表钳制 · 绝不走 modifier pipeline**——与 `StatusChanges` 逐条相同，但作用对象不同（后者绑定 `CharacterProfile.Status` 上的规则字段），故按「施加语义根本不同就分列」独立成列，而**不塞进 `StatusChanges`**：混住之后 `StatusFields` 的 key 会同时指向两个对象，「这个 key 写哪个对象」从此要读上下文，与「可机械检查是这条通则的全部价值」相抵。
  - **`SettingAssignment` 的两个载荷格皆可空**（`int? IntValue` / `bool? BoolValue`），由 `Kind` 决定哪一格有效、另一格为 `null`。**可空是「哪一格有效」可机械校验的前提**：`bool` 的缺省 `false` 与合法值 `false` 同形，`int` 的缺省 `0` 与合法值 `0`（音量 0 = 静音，是承重的合法取值）同形——非可空下「另一格是否填了」在运行时无法与「填了一个恰好等于缺省的合法值」区分，上表那条 `Kind` 不匹配的校验会变成一条判不出来的纪律。`StatusAssignment` 能用非可空是因为它的另一格是 `string`（`null` 即缺省）；同库先例是 `EventStateAssignment` 的可空载荷格。
  - **逐行查 `SettingFields` 表，与 `ResourceElements` / `StatusFields` 同款判据。** 每个 key 占一行 `(Kind, Min, Max, 默认)`：

    | Key | Kind | Min | Max | 默认 |
    |---|---|---|---|---|
    | `MasterVolume` | `Int` | 0 | 100 | `100` |
    | `MusicVolume` | `Int` | 0 | 100 | `80` |
    | `SfxVolume` | `Int` | 0 | 100 | `100` |
    | `FastCombatAnimation` | `Bool` | — | — | `false` |

    **默认值就住在这张表里，是唯一一处**——老档补默认、读档单字段缺失、UI 初值三处读同一行，各写一份必然漂移。**拆成 `SettingInts` / `SettingBools` 两个列表被否决**，与 `StatusFields` 拒绝分表同一条判据（分表必然出现「加了这张忘了那张」）。
  - **本表落代码常量静态查表，不落 `.tres`。** 与 `(CarrierKind, Scope, Source)` 合法子集表、`RngStream` 子流清单同类。**默认值这一列不是平衡数值**——它们是 UI 初值 / 缺省，不进抽取、不进结算，改它不影响任何玩法平衡；落 `.tres` 还会给设置读取链引入一次 `ContentRegistry` 依赖。
  - **启动期断言表覆盖 `SettingKey` 的全部成员**，与 `ResourceElements` / `StatusFields` 同档——漏行即值类型与取值域皆不明，必须在启动期 `PushError`。
  - **恒不经 modifier pipeline。** 理由与统计层同源：否则一条法则能改写玩家的音量与演出速度。
  - **`SettingChanges` 在 `SelectCost` 内恒为空**，与其余各列同款不变式、独立成行（见上表）。
  - **`AppliedChange` 里实际永不出现 `SettingChanges`**：设置变更只在设置屏发起，永远不发生在事件结算里。这不构成「那就别加进 `ProfileChangeSpec`」的理由——**列的存在是因为写入面唯一**，而 `AppliedChange` 只是忠实记录那一次 spec 里有什么。
  - **提交时机是 UI 侧的一条纪律，不新增机制：** 滑条拖动中只做实时预览（直接改 `AudioServer` 的 bus 音量，不碰 profile），`drag_ended` / 开关切换那一刻提交一次，离屏时若有未提交的预览值强制提交一次。它与「`Project(spec)` 不是第二个写入点」同类——把「预览」与「提交」分清，写入面仍然只有一个；否则「一次提交 ⇒ 一次本地原子写」在一根拖动中的滑条上就是每帧一次磁盘原子写。呈现形态见 `ux/screen-flow.md`，字段与取值语义见 `systems/player-profile/game-setting.md`。
- **图鉴解锁经 `CodexElements` 写入，语义是按 `(Kind, Id)` 的幂等收录（承重）。** `PlayerProfile` 的七个 Codex 字段不提供 setter，**唯一写入路径是 `CodexElements` 列表经 `TryApply`**，与其余各列**同批、同事务**提交。条目类型 `CodexUnlock(CodexKind Kind, string Id)`：`Kind` 是七值路由键，决定这一条落哪一个具名字段。

  ```csharp
  public enum CodexKind { Enemy, CharacterPower, PlayerPower, CharacterItem, PlayerItem, Location, Technique }
  public readonly record struct CodexUnlock(CodexKind Kind, string Id);
  ```

  - **element 带 `Kind` 而存档落七个具名字段，两者不矛盾。** `AbilityChangeElement` 是同形先例：element 带 `(CarrierKind, Scope)` 做路由，持有条目落四个具名字段。「不落 `Dictionary<CodexKind, …>`」约束的是**存档形态**，不是 element 的路由键。
  - **不复用既有的 `(CarrierKind, Scope)` 二元组。** 该二元组的值域（Power / Item × Character / Player）恰好覆盖四本能力 / 道具图鉴，但 **Enemy / Location / Technique 三者落在值域外**；复用会逼出「二元组 + 三个特例」的畸形值域，另设七值 `CodexKind` 更便宜。
  - **必须分列。** 判据与 `EventStateChanges` 分列时逐字相同——`Elements` 只装标量值、`AbilityElements` 的载荷带 `(CarrierKind, Scope, Source, Op, PairKey)` 且改变**持有**、`StatusChanges` 的值是标量或 id；没有一列装得下 `(CodexKind, Id)` 且语义对得上。
  - **零 `Op`，因为永不删除。** 图鉴只增不删（`PlayerProfile` 整体亦然，故 diff 不表达删除）；重复收录是幂等空操作，不是失败。
  - **恒不经 modifier pipeline。** 一条法则若能改写图鉴解锁，等于内容改写玩家的知识资产；与 `PlotElements` / `StatusChanges` 同源同重。
  - **`CodexElements` 在 `SelectCost` 内恒为空**，与其余各列同款不变式、独立成行（见上表）。
  - **触发采集与去重归 `CodexManager`，写入仍组装 `CodexElements` 经 `ProfileManager` 单点提交**——与 AchievementManager「进度采集归本服务、写入仍经单点提交」逐字同构。**不由 `ProfileManager` 看到能力进入持有列表就自动派生 codex element**：零遗漏很诱人，但会让 `AppliedChange` 记的账与组装方提交的 spec 不一致，违反「提交的是已算好的整块，本 manager 不做合并 / 增量」。改用显式组装 + `#if DEBUG` 兜底断言——一批变更中出现使某条能力进入持有列表的 element、或一条 `Op == LearnTechnique` 的 `DeckChangeElement`，而同批没有对应的 `CodexElements` 条目 → `PushWarning`（纪律阶梯第 3 级，与施加 `Disable` 时 `activeCombat != null` 那条同款）。
  - **连锁收录的展开也归 `CodexManager`，同一条纪律的第二个实例。** 收录一个敌人时同时收录该敌人套牌所含的全部功法，落成 **1 条 `(Enemy, enemyId)` + N 条 `(Technique, techniqueId)`**，由 `CodexManager` 展开并去重后随批交来；`ProfileManager` 只按 `(Kind, Id)` 逐条幂等收录，**不认识敌人与功法之间的引用关系**。展开产生的重复（多个敌人共用一门功法、玩家已持有该功法）由既有的幂等语义免费兜住——同批同 `(Kind, Id)` 去重、已存在即空操作，两者都不告警，故连锁收录**不新增任何失败语义行**。
  - **各本的触发口径与组装方**见 `systems/player-profile/codex/common-properties.md`；每一行都搭在一次已经存在的提交上，**不新增存档点、不新增 push、不新增决策点**。战斗事件的那一次是**该事件的收口提交**，判负短路那一路则是失败流程的收尾提交（见 `systems/services/life-cycle-service.md`）——遭遇的判据是接触而非胜利，两条路径都必须带上收录。
  - **可追溯性日志（非告警）：** 收录时打一行 `[ProfileManager-TryApply] codex kind=<Kind> id=<Id>`。
  - **增列 ⇒ bump 存档 schema 版本**（当前无线上存档 ⇒ 空迁移）。
- **道具使用次数经 `ItemElements` 写入，语义是按 `(Scope, ItemId)` 选定一份实例后施加带符号增量（承重）。** 两层持有条目上的 `Charges`（轮回级 `CharacterProfile.magicPack` / 账号级 `PlayerProfile.playerItem`）不提供 setter，**唯一写入路径是 `ItemElements` 列表经 `TryApply`**，与其余各列**同批、同事务**提交。它买到的是一条既有纪律的可落地形态：「道具使用次数的扣减即时经 `ProfileManager.TryApply` 写档」在此之前没有任何 element 装得下它。

  ```csharp
  public readonly record struct ItemChargeElement(
      AbilityScope Scope,      // Character → CharacterProfile.magicPack；Player → PlayerProfile 的古宝列表
      string       ItemId,     // 指向 ItemData.Id
      int          Delta);     // 恒为负（消耗）；首批只开消耗向
  ```

  - **必须分列。** 按三级判据的六面核对：`Elements` 只按 `CostKey` 索引一个标量，装不下「哪一层 + 哪个 `ItemId` + 选哪一份实例」，且给 `CostKey` 加成员会破坏它与两层 Profile 字段表的**双向满射**、并留下一行填不出 `(Min, Max, DepletionDefeat)` 的配表条目（次数的上界是逐条目的 `ItemData.Charges`，不是常量）；`AbilityElements` 是**集合成员操作**（幂等增删、无量纲），扣次数**有量纲且不幂等**；`StatusChanges` 绑定 `CharacterProfile.Status` 上的规则字段。
  - **实例选取规则是纯函数（承重）。** 持有条目上**没有实例 `Id`**（`CharacterItem` / `PlayerItem` 是 `readonly record struct`，同 `ItemId` 多份彼此值相等），而储物袋按 `ItemId` 堆叠 `×N`、玩家点的是堆叠而非某一份 ⇒ 必须有一条确定性规则：**取同 `(Scope, ItemId)` 中 `Charges > 0` 且 `Charges` 最小者；并列取存档列表中靠前者；`Charges == -1`（无限）的实例不参与选取。** 只依赖存档列表顺序 ⇒ 同一份 spec 重放两次得同一结果，「`AppliedChange` 可直接重放」原样成立。取最小非零使可用次数尽快收敛到少数几份，堆叠 `×N` 与「已耗尽」chip 的读数因此可预期。
  - **无限法宝不产出本 element。** 选取规则对它得空 ⇒ 组装方不组装，而不是组装一条被忽略的 element。
  - **施加后钳制到 `[0, ItemData.Charges]`**，与资源列的钳制同一条纪律（截断只发生在施加到字段那一刻，spec 与快照记未截断值）。
  - **恒不经 modifier pipeline。** 一条法则若能改写次数扣减，「古宝的总量被次数封死」这条付费分工当场失效——与 `BundleRedeemedOrdinal` 两个修正列必须为空同源同重。
  - **`ItemElements` 在 `SelectCost` 内恒为空**，与其余各列同款不变式、独立成行（见上表）。
  - **可追溯性日志（非告警）：** 施加时打一行 `[ProfileManager-TryApply] itemCharge scope=<Scope> id=<ItemId> delta=<Delta> after=<剩余次数>`。「我这颗丹到底扣没扣」是玩家会来问的一类变更，且 `after` 是诊断侧唯一的剩余次数证据——存档不为它留派生字段。
  - **连带（零改动）：战斗内使用的次数扣减自此也有了 element 形态**，战斗侧流程一字不改（它本就是一次即时提交）。
  - **增列 ⇒ bump 存档 schema 版本**（当前无线上存档 ⇒ 空迁移）；持有条目的字段一格未改。
- **战斗外使用痕迹经 `ItemUseElements` 写入，语义是序列尾部只追加（承重）。** `CharacterProfile.pastItemUse` 不提供 setter，**唯一写入路径是 `ItemUseElements` 列表经 `TryApply`**，与其余各列**同批、同事务**提交。**直接后果：痕迹与它记录的那一次变更落在同一次原子写内**，不存在「扣了次数但痕迹没落下」的中间态。
  - **与 `TraceElements` 分列，不合并（承重）。** 两列的施加语义同形（序列尾部只追加），但 `TraceElements` 的两条入口校验（**一次事件恰一条**、**`AppliedChange` 恒不含本列**）与「载荷直接是 `PastEventEntry`、不建镜像类型」**都绑定在载荷类型上**；合并需要把载荷改成一个二成员 sum type，并把两条校验改成按载荷类型分支——那正是分列要消掉的东西。**代价明写：** 这是本模型里第一次出现「施加语义同形但仍分列」的两列，分列判据因此多一句「载荷类型不同且入口校验绑定在载荷上时同样分列」。
  - **载荷 `ItemUseEntry` 的字段面与读档校验归 `systems/character-profile/_index.md`**，本处不复述。
  - **一次使用恰一条**，同批两条即组装缺陷；`Seq` 连续性与 `AfterEventSeq` 的取值域由入口校验（见上表）。
  - **恒不经 modifier pipeline。** 与 `TraceElements` 同源：一条法则若能改写履历，它改写的是「到底发生过什么」这条账。
  - **施加侧写严、读档侧读宽**，与 `TraceElements` 逐字同款（施加侧的悬空来自组装缺陷，读档侧的来自 overlay 热更）。
  - **`ItemUseElements` 在 `SelectCost` 内恒为空**，与其余各列同款不变式、独立成行（见上表）。
  - **可追溯性日志（非告警）：** 追加时打一行 `[ProfileManager-TryApply] itemUse seq=<Seq> afterEvent=<AfterEventSeq> id=<ItemId> scope=<Scope>`。
  - **增列 ⇒ bump 存档 schema 版本**（与 `ItemElements`、`pastItemUse` 三处合并为**一次** bump；当前无线上存档 ⇒ 空迁移）。
- **只读投影 `Project(spec)`：先算后提交，不新增写入面（承重）。** 收口时新一批 eventOptions 必须依**更新后的** profile 重算（`pastEvent` 是 future-event-service 的一等输入），而收口又必须是**一次**事务、一个存档点——两条承重纪律都不放松，故本服务提供一个**施加 spec 后返回未提交只读视图**的方法：life-cycle-service 用它算出新一批，再把批一并放进同一次 `TryApply`。
  - **它不是第二个写入点。** 投影不改任何字段、不触发 `CapabilitiesChanged`、不产生存档点；「一切写入经 `TryApply`」原样成立。
  - **本模型内已有两处同形的先例**：`AppliedChange` 是可直接重放的账（重放即一次纯施加）；`CanAfford` 与 `TryApply` 共用 `Evaluate(spec)`（先算、只有后者提交）。
  - **它与 `TryApply` / `CanAfford` 共用同一段 `Evaluate(spec)`（承重）。** 三者是一段施加实现的三个门面：`TryApply` = `Evaluate` + 提交 + 广播 + 落存档点，`Project` = `Evaluate` 取投影后丢弃提交，`CanAfford` = `Evaluate` 取判定。**另写一段轻量施加代码是明令否决的**：分叉后「新一批所依据的 profile」与「实际提交后的 profile」可能不同，而新一批**已经落存档**——玩家会拿到一批依据一份从未存在过的历程算出的选项，且事后无从发现。这比 `CanAfford` 分叉（UI 显示买得起而实际拒绝）更重。
  - **投影做钳制。** 「截断只发生在施加到 Profile 字段那一刻」——投影正是施加。不钳制则重算方会看到 `lifeSpan < 0`，而寿元百分比与 band 判定都没有负轴语义；且不钳制等于两条施加路径分叉。
  - **投影不做终态判定，且不需要为此另写一条规则。** 终态判定本就不在 `Evaluate` 内——它是 `CycleStateManager` 在两个明确时点跑的读取侧纯函数。`Project` 只施加、不判定，是既有分层的自然结果。
  - **一份「已判负」的投影照常交给重算方，重算与提交都不短路。** 短路要把「`Key == EventOption` 置空」从 `PushError` 改为条件合法（一条承重校验），并新增第三处终态判定；换来的只是省一次纯内存物化，而判负后整个 `CharacterProfile` 随失败流程拆解，那一批随之消失。**推论：重算入口的入参语义恒为「结算后的角色状态」，不多一个分支。**
  - **失败即必需缺失：`PushError` + `throw`，不返回 `false`。** 投影只在收口 spec 组装缺陷时失败，那是必须大声失败的情形，落总则 2 的第一档；调用方不写失败分支。**不取 `bool TryProject(..., out ...)` 形状**——那是可选缺失（`PushWarning` + 调用方降级）的签名，全库该形状无一例外都是可降级的。
  - **返回值是一次性的只读投影视图，不得存字段、不得跨 `await` 持有（承重）。** 一旦真正提交（或期间发生任何一次事件内即时提交），缓存的投影就是一份过期的第二真值，而它**不触发 `CapabilitiesChanged`**，持有者收不到任何失效通知。
  - **这条纪律做到阶梯第 1 级：视图是 `ref struct` 包装。** C# 在语言层禁止把 `ref struct` 存进字段、也禁止跨 `await` 持有——正是这两条纪律的逐字对应，零运行时成本。选级理由：跨 `await` 持有可能只在线上时序下发生，符合「能上线且线上不可见 → 必须第 1 或第 2 级」；`#if DEBUG` 的提交序号比对保留为兜底。
  - **消费点唯一 = life-cycle-service 的收口重算。** 新增消费点须同批评审——多一个消费点就多一处可能把投影存起来的地方。
- **钳制、终态与修正接入查 `ResourceElements` 表，不散落字段判断（承重）。** 每个资源 element 在表中占一行 `(Min, Max, DepletionDefeat, CostModifier, GainModifier, AllowedOps)`：`Min` / `Max` 是它的取值域，`DepletionDefeat` 非空即表示**触底构成终态**并给出对应的 `DefeatReason`，两个修正列是它在 modifier pipeline 上的两向准入，`AllowedOps` 是它允许的施加方式集合（`Add` / `Set` / 两者）。类型定义与配表理由见 `systems/architecture.md`「共享核心类型」。全表 15 行：

  | `CostKey` | Min | Max | 归 Min 时 | `CostModifier` | `GainModifier` | `AllowedOps` | 依据 |
  |---|---|---|---|---|---|---|---|
  | `LifeSpan` | 0 | 无 | **终态** `DefeatReason.LifeSpanExhausted` | `LifeSpanCost` | `null` | `Add` | 寿元归 0 = 大限将至；`lifeSpanCost` 是文档点名的第一个 modifier 用例。**⚠ 本行的 `CostModifier` 同时作用于两个负向来源**——事件成本 `lifeSpanCost` 与战斗失败扣减；一条「事件消耗 −20%」的法则会连带减轻 20% 的战斗失败惩罚。**已知并接受**（拆成两个 `CostKey` 就等于没有合并，叙事上「延寿」同时减轻两类损耗也通顺），但它是一处只有在数值失控时才会被发现的隐性耦合，故在此明写。**产出向（寿元回复）已有通道但仍不开修正口**：一条「延寿 +X%」的法则直接乘上篇章时长旋钮，而寿元现在是角色唯一的那条命 ⇒ 该修正等于同时放大容错与篇章时长两个维度，理由强度较之前**翻倍**；且法则账号级永久持有、须按「老账号全开」校准；按缺省豁免，日后确需时加一行即可。与「`PowerData` 不得含 `LifeSpan` 产出」互补——那条关掉「法则直接产寿元」，本格关掉「法则放大回寿」。**只有消耗与回复两向，从无「赋一个绝对寿元」的通道**，开 `Set` 即给内容一条绕过 `LifeSpanCost` 修正的路 |
  | `SpiritStone` | 0 | 无 | 无（只是变穷） | `null` | `null` | `Add` | `DefeatReason` 封闭、无货币项；灵石随轮回清理，不承载终态语义。**两列恒为 `null`**：商店价格修正 `ModifierKey.ShopPrice` 在**物化 / 展示侧**施加并写进 `ExchangeOffer.ListPrice`，element 路径拿到的 `BaseValue` 已是修正后的标价——再填一次即**打两次折**（玩家看到 80、实扣 64，且灰显判据随之偏移），见下「只施加一次」。灵石的每一笔都是交易的增减，无置值通道 |
  | `ImmortalJade` | 0 | 无 | 无（只是变穷） | `null` | `null` | `Add` | 高阶货币，与灵石**逐列同形**：同样随轮回清理、同样不承载终态语义（`DefeatReason` 封闭、无货币项）。**两列恒为 `null`** 同因——仙玉计价商品的 `ShopPrice` 修正同样在物化 / 展示侧施加并写进 `ExchangeOffer.ListPrice`，再填一次即打两次折。仙玉的每一笔同样是产出或交易的增减，无置值通道。它与灵石的分野**只在获取通道与花销面**，不在本表任何一列，见 `systems/character-profile/currency.md` |
  | `ManaLimit` | 0 | 无 | 无（不构成终态） | `null` | `null` | `Add` | `Min = 0` 只排除「负上限」这个无法定义的状态（每回合恢复到负值讲不通），**不是被否决的那两条护栏**（保底 ≥ 1 与死牌转化仍然不做，见 `systems/character-profile/mana.md`）；两个修正列留空是**硬要求**——任一列开放，一条法则即可把 ±1 放大为 ±2，直接推翻「单次变动幅度恒为 1」这条承重规则。**`Set` 恒不开亦是硬要求**：一条置值即可跳档，同一条承重规则同样失去载体。**事件产出侧另有一条同源闸**——`EventOutcomeSpec` 内 `Key == ManaLimit` 的 element 其量值恒为 1（见上方施加失败语义表与 `systems/adventure-event/common-properties.md` 的模板侧校验），否则一个 `.tres` 即可从内容侧另开一个同效果的口。**大境界提升时的 `+1` 走同一条 `Add` 通道、幅度同为 1**（由 life-cycle-service 在篇章边界施加，语义见 `systems/character-profile/mana.md`），故它不构成本行的例外，**也不需要为它开 `Set`** |
  | `ExperiencePoint` | 0 | 无 | 无 | `null` | `null` | `Add` | 修行经验只增不赋；无上界、不构成终态。key 名与标的字段 `Status.experiencePoint` 逐字对齐，使「key 名 ⟸ 字段路径」这条规则**零例外**——一条约定一旦开例外，就从「可机械检查」降级为「要读上下文」 |
  | `Faith` | 0 | 100 | 无（触底不构成终态） | `null` | `null` | `Add` | 道心经隐藏属性推拉施加，是增减语义；区间来自档位表。**两个修正列留空**：一条法则能伪造隐藏属性，即等于伪造整条剧本线的触发条件 |
  | `Bloodlust` | 0 | 100 | 无（触底不构成终态） | `null` | `null` | `Add` | 煞气同上（可被净化下拉，故两向皆走 `Add`） |
  | `PowerFragmentAccumulated` | 0 | 10000 | 无 | `null` | `null` | `Add \| Set` | 万分比累计，直接决定「这次 Finale 是否授予一条法则」——经 pipeline = **法则加速获得法则**的自举回路。**同一个 key 上真的需要两种**：每次 Finale 累加 `x`（`Add`）、发放法则后重置为 `Base(x + 1)`（`Set`），这是 `Op` 必须逐条带而非逐行配单值的现存例证 |
  | `PowerFragmentFinaleWinOrdinal` | 0 | 无 | 无 | `null` | `null` | `Add` | **序号**：自增值被修正即掷骰序列漂移，它同时是 `AccountRng` 的 `ordinal` 与幂等键；自增 = `Add(+1)`，不需要 `Set` |
  | `PowerFragmentCh1FirstWinDone` | 0 | 1 | 无 | `null` | `null` | `Set` | **置位**：`bool` 字段以 `int 0/1` 承载，取值域由钳制兜住；无量纲，修正无意义，`Add` 对布尔同样无意义。**落三个具名成员而非一个带 chapter 参数的 key**：C# 枚举成员不能带参数，参数化必然退化为给 `ChangeElement` 加一个可空载荷格，那正是被否决的替代之一；存档侧标的本就是三个具名布尔，与 `chapterRetry` 三字段同款判据（篇章数是固定的游戏结构）。**已核对并否决为它们另开一列 `FlagChanges`**：按三级判据的六面核对只在「有无量纲」一面不同，五面全对齐 ⇒ 不分列，否则每个 `Set` 型标量都要一列。**代价明写**：新增篇章要加三个枚举成员 |
  | `PowerFragmentCh2FirstWinDone` | 0 | 1 | 无 | `null` | `null` | `Set` | 同上 |
  | `PowerFragmentCh3FirstWinDone` | 0 | 1 | 无 | `null` | `null` | `Set` | 同上 |
  | `PowerFragmentLastRoll` | 0 | 9999 | 无 | `null` | `null` | `Set` | 最近一次 Finale 通过掷骰的原始值，被赋为一个已掷出的绝对值；区间即 `AccountRandom.Roll()` 的值域。**两列恒为 `null`：经 pipeline = 一条法则能改写反作弊证据**（后端逐位复算比对读它）。**每一次 Finale 通过都必须带上这一条**，缺行 / 缺条即在正常账号上触发后端风控误报 |
  | `PowerFragmentLastEffectiveChance` | 0 | 10000 | 无 | `null` | `null` | `Set` | 那一次掷骰当刻的生效概率，万分比；首胜写 `10000`。理由与上一行同源 |
  | `BundleRedeemedOrdinal` | 0 | 无 | 无 | `null` | `null` | `Set` | 付费礼包的**兑现水位**，被赋为本次兑现的绝对 `ordinal`、不是加法；经 pipeline = 一条法则能伪造兑现记录（见 `systems/monetization.md`）。授予序号 `BundleGrantOrdinal` 由后端写、经 pull 下行，**不在本表**，故客户端置位它必然 `PushError` |

  **本表已覆盖 `CostKey` 的全部成员，与两层 Profile 字段表中写入通道标为 `Elements` 的格子双向满射**——轮回层 `spiritStone` + `immortalJade` + `Status` 前五格，账号层 `playerPowerFragment` 的 7 个字段与 `entitlement.BundleRedeemedOrdinal`。含 `Set` 的各行两个修正列一律 `null`，故自动满足下方那条启动期断言。

  - **`Elements` 列明确允许同键多条（例外 · 必须写下来）。** 其余各列（`EventStateChanges` / `PlotElements` / `RngElements`）均明令「同批两条同键 = 组装缺陷」，`Elements` **不适用该口径**：一次战斗事件的收口 spec 必然带两条 `Key == LifeSpan` 的 `Add`（事件成本一条、战斗失败扣减一条），它们来自两个合法且独立的组装方。**语义 = 同键各条先求和，再按该行的取值域一次钳制**（不是逐条钳制——逐条会让「先扣 8 到 0、再扣 3」丢掉第二笔）。**不要按惯例给 `Elements` 补一条同键去重校验**，那会当场打断每一次战斗失败的收口组装，且失败发生在轮回中途而非启动期。
  - **`Op == Set` 恒不经 modifier pipeline。** `BaseValue` 在 `Set` 下是一个已算好的绝对值，**符号不表达方向**，「按符号分向」无从判断该取 `CostModifier` 还是 `GainModifier`；更重的理由与 `StatusChanges` 同源——让一条法则改写一个已算定的权威值（付费凭证序号、万分比累计），等于让内容改写权威值。
  - **`AllowedOps` 含 `Set` 的行，两个修正列必须恒为 `null`** —— 落为**启动期断言**（与「表覆盖 `CostKey` 全部成员」同档），使上一条不靠人记。**代价明写**：这条断言把「允许 `Set`」与「两个修正列为 `null`」焊在同一个 key 上，结构上排除「同一 key 既走修正的 `Add`、又有不走修正的 `Set`」这一形态；全表 15 行零摩擦。
  - **每一行的 `AllowedOps != 0`** —— 同样落为启动期断言：空集意味着该 element 没有任何合法写法。

  - **两个修正列是 opt-in 白名单，缺省豁免（承重）。** 缺省方向不对称：漏填时若缺省豁免，最坏是某条法则本该修正它却没修正——数值不对、可见可复现、改一行修好；若缺省经 pipeline，最坏是某条法则**静默地**改写了幂等键 / 付费凭证 / 元进程计数，无人察觉，且在云端权威 + 后端复算下表现为两侧算不一致。故缺省取豁免侧。
  - **按符号分向。** 同一个资源 element 的消耗向与产出向共用一个 `CostKey`，一条「寿元消耗 −20%」的法则若不分向，会把**寿元回复也削 20%**；既有术语本就是分向的（`lifeSpanCost` 是成本向的名字，不是 `LifeSpan` 字段的名字）。向性由 `BaseValue` 的符号给出，**不在 key 名里再编码一次**——那等于两处真值，且法则条目侧要为「消耗与产出都改」写两条 modifier。
  - **修正与否是 element 类型的属性，不是单次变更的属性。** 故它配在表里，而不是让 `ChangeElement` 自带一个 `ModifierKey?`：后者允许组装方逐次决定「这次让不让法则改」，把一条纪律降级为调用方选项，且 `AppliedChange` 重放时同一 key 可能带不同修正配置。
  - **一个 `ModifierKey` 只能有一个施加点（承重）。** 判据：**该修正后的值是否需要在施加之前呈现给玩家**。需要 → 施加点在物化 / 展示侧（商店价格必须先算才能标价），此时它**不得**再进本表，否则打两次折；不需要 → 施加点在 `TryApply`（`lifeSpanCost` 属此类：`selectCost` 物化时 pipeline 尚未施加，在 `TryApply` 那一刻才生效）。
    - **只读查询不构成施加点。** `selectCost` 的精确展示取 `ApplyModifier(LifeSpanCost, SelectCost 内的 LifeSpan 值)` 的**查询结果**，**不写回定稿实例**——`ApplyModifier` 本就是通用查询，读一次不改变任何状态；写回才是第二个施加点，会打两次折（与两条货币行明写的坑同款）。故 `LifeSpan` 行的 `CostModifier` 保持 `LifeSpanCost`、施加点仍在 `TryApply`，而界面上显示的是玩家实际会被扣的数。
  - **表里出现的 key 必须是 `ModifierKey` 的成员，反向不要求。** `ApplyModifier` 仍是通用查询——非 element 路径的数值（商店价格、掉落权重、战斗内数值）照常各自调用它。本表**只约束 element 施加路径**，不收窄 `ApplyModifier` 的用途。
  - **启动期断言表覆盖 `CostKey` 的全部成员。** 漏行即缺省行为不明，必须在启动期 `PushError`，而不是在轮回中途撞上。
  - **启动期断言：`StatKey` 与 `PlayerStatistics` 字段双向覆盖。** 每个 `StatKey` 成员在 `PlayerStatistics` 上有同名字段，且每个字段有同名成员。它是统计族**不建配表**的替代品——一行反射遍历，只在 `#if DEBUG` 生效，覆盖「加了字段忘了成员 / 反之」。理由与清单见 `systems/player-profile/_index.md`。
  - **启动期断言：两个枚举的成员名词缀合规。** `CostKey` 侧不得出现 `Total` 前缀 / `Count` 后缀，`StatKey` 侧必须带 `Total` 前缀或 `Count` 后缀且不得出现 `Ordinal` / `Used` 后缀。它把「两个枚举的成员名空间不相交」从一条读得懂的约定变成开机就能失败的检查，覆盖的错误是**新增一项时放错枚举**。选级理由：错登为 `CostKey` ⇒ 缺 `ResourceElements` 行 ⇒ 启动期 `PushError`；错登为 `StatKey` ⇒ 双向覆盖断言当场失败——都在开发期显形，不属「能上线且线上不可见」，故第 3 级足够。词缀表见 `systems/player-profile/_index.md`。
  - **成员名冻结：只可追加，永不改名 / 复用。** 两个枚举随 `ProfileChangeSpec` 落进 `PastEventEntry.SelectCost` / `AppliedChange` 并以成员名逐字序列化 ⇒ 改名即破坏性契约变更，须 bump `schemaVersion` 并与后端同批改（见 `systems/architecture.md` 与 `systems/services/sync-service.md`）。**也不给两者分配显式整数 code。**

  - **`Min = 0` 是资源族的默认，例外逐条写明。** 寿元取默认（截断，不允许为负）的理由：① 余量是明文常驻、恒精确展示的，让它显示负数与该呈现的语义直接矛盾；② 截断后 `lifeSpan <= 0` 与 `== 0` 两种判据写法同解，消掉一个本库从未指定过的歧义面；③ 剩余寿元跨篇章结转要求它是一个可加的**非负预算**，负值落存档会让读档校验与元进程的寿元曲线都要处理负轴而换来零收益。
  - **施加顺序**（`Evaluate(spec)` 内，逐 `ChangeElement`）：

    ```
    spec = ResourceElements[e.Key]                                   // 缺行 = 必需缺失 → PushError + 整批拒绝
    if (e.Op & spec.AllowedOps) == 0 → PushError + 整批拒绝           // op 准入
    if e.Op == Set:
        落值 = Clamp(e.BaseValue, spec.Min, spec.Max)                 // 不读当前值、不经 pipeline
    else:
        key  = e.BaseValue < 0 ? spec.CostModifier
             : e.BaseValue > 0 ? spec.GainModifier : null            // BaseValue == 0 无向可分，且是空操作
        eff  = key == null ? e.BaseValue : ApplyModifier(key.Value, e.BaseValue)
        raw  = 当前值 + eff
        落值 = Clamp(raw, spec.Min, spec.Max)
    ```

    **`CanAfford` 与 `TryApply` 共用的 `Evaluate(spec)` 读同一张表**，故「两者必须走同一条 pipeline」自动保持。**`Set` 不参与可负担性**——它不是消耗，`CanAfford` 只看 `Op == Add` 且 `BaseValue < 0` 的那些。**截断不构成 `ApplyResult.Fail`**——「全有或全无」约束的是各列表是否一起落，不是每个 element 是否落满。
  - **spec 与快照记未截断值。** `ChangeElement.BaseValue` 与 `PastEventEntry.SelectCost` / `AppliedChange` 一律保留原值，理由见 `systems/architecture.md` 同一处。
  - **`ApplyResult` 不带「触底 element」字段。** 终态判定读 `Snapshot.Status`，判据即「该字段 == 对应 `ElementSpec.Min` 且 `DepletionDefeat != null`」；「本来就是 0 还在推进」在规则层不可达（归 0 当场终结），故触底与既有值无须区分。加一个 `IReadOnlyList<CostKey> Depleted` 的收益仅限诊断，代价是每次 `TryApply` 一次堆分配，与 `ApplyResult` 是 `readonly record struct` 的零分配纪律相抵；确需触底诊断时正确的加法是在本 manager 内部打一行 `[ProfileManager-TryApply] depleted key=LifeSpan` 的可追溯性日志。
- **可加性，落成恰好五步、不多不少。** ① Profile 上加字段（只读、无 setter）并更新该库字段表的写入通道列 → ② `CostKey` 加一个成员（名 ⟸ 标的字段路径）→ ③ `ResourceElements` 加一行六列 → ④ bump 存档 schema 版本（老档补默认值）→ ⑤ 若该行含 `Set`，两个修正列必须留空（启动期断言兜底）。**不新增服务、不改任何调用方。**这正是**不为 power / item / card / resource 各开一个 collection 服务**的替代品（见 `_index.md` 的拆分轴）。

### CapabilityManager：能力标记聚合面

capability flag 体系归本服务。

- **聚合范围 = 两层持有列表（承重）。** 在启动及两层 Profile 变更时，遍历 `PlayerProfile.playerPower` **与当前角色 `CharacterProfile.characterPower`**，把**同三条与门**（拥有 · `status == 启用` · 不在 `CharacterProfile.disabledAbility` 内）都成立的条目所声明授予的 **capability flag**（如 `RevealHiddenStats`、`ShowExploreType`）聚合为**同一份**生效能力集，并把它们声明的具名 **modifier** 聚合为**同一张**修正表。**第三条与门是轮回级抑制**：被禁用的条目**不进生效能力集、不进修正表**（禁用一律截断在「进入生效面」那一步，见 `systems/character-profile/power/_index.md`）。因本服务同时拥有两层 profile，两层遍历与「聚合账号级法则时要读轮回级禁用表」**都不跨服务、不新增依赖边**。
  - **无当前角色时（主菜单）只聚合账号级那一份，是正常态，不告警。**
  - **轮回结束后角色级 flag 随重新聚合自然消失，不需要任何清理代码**——生效集是派生态，重算即正确。
  - **`ItemData` 两类（法宝 / 古宝）不参与聚合**：它们带 `Charges`、按次主动使用，效果走它自己的两格使用效果面（战斗内 `EffectData[]` / 战斗外 `ProfileChangeSpec` 模板，见 `systems/character-profile/item/_index.md`）而非常驻通道；常驻派生态的表达属静止式的 power 两类。生效判据表里那两行对道具恒为空集，是自洽而非例外。
- **触发源清单（全部走同一条 `Recompute()`，不新增机制）：** `Hydrate` 首次聚合 · 能力得失（`AbilityElements` 提交后）· `status` 开关 · `disabledAbility` 写入 / 到期 · **轮回开始 / 拆解**。每次重算后经 **EventBus** 广播空负载的 `CapabilitiesChanged`。
- **叠加 = 集合并，幂等（承重）。** 两个条目授予同一 flag ⇒ 该 flag 在生效集里出现一次，**不计数、不叠层、不告警**（重复授予是常态而非缺陷，与 `CodexElements`「同批同 `(Kind, Id)` 去重、不告警」同款口径）。给它计数会立刻引出「两份是不是该更强」，而布尔量没有这个语义。
- **冲突在结构上关死，而不是运行时裁决（承重）。** 全部 flag 恒为**增益向 / 打开向**，因此不存在两个 flag 互相矛盾的可能，union 就是全部规则——**不需要优先级字段、不需要声明序、不需要「谁赢」的裁决表**。
  - **命名规范是这条不变式的可机械检查护栏：** 成员名 = 动词 + 宾语，动词取自封闭三词表 `Reveal`（把已存在但被隐藏的**信息**显出来）· `Show`（把某处 **UI 元素**显示出来）· `Unlock`（打开一个原本不可用的**入口**）；**禁止否定式 / 关闭式命名**（`Hide*` · `No*` · `Disable*` · `Suppress*` · `Prevent*`）。允许一个 `Hide*` 进枚举的那一天，才需要一张裁决表。
  - **确需「关闭某项默认可见的东西」时的正确形态：** 把默认态挪到内容侧 / `GameSetting`，用一个**正向** flag 打开它，不引入负向 flag。
- **落地形态 = `HashSet<CapabilityFlag>`，`CapabilityFlag` 保持普通序数 `enum`、不加 `[Flags]`。** 位掩码会给 flag 数量焊上 32 / 64 的上界，并让成员值变成必须手工维护的 2 的幂——换来的只是 `Has` 从一次哈希查找变成一次按位与，而 `Has` 的调用点是 UI 重绘、不在热路径。
- **新增一个 flag 恰好三步，不多不少：** ① `CapabilityFlag` 加一个成员 → ② 受影响的 UI 组件加一次 `Has(flag)` 自查 + 订阅 `CapabilitiesChanged` → ③ 某条 `PowerData` 的 `.tres` 声明授予它。**不 bump 存档 schema、不改任何服务、不新增事件**——生效能力集是派生态，不落存档。
- **modifier 的合并算法（承重）。** 一条修正的形态是 `ModifierEntry(ModifierKey Key, ModifierOp Op, int Value)`，`ModifierOp { Add, Scale }`，**`Scale` 的 `Value` 是万分比增量**（`-2000` = −20%）——沿用 `PlayerPowerFragment.Accumulated` 的万分比整数纪律，禁 `float`（存档 / 跨端一致 + 后端可复算 + 不做浮点比较）。`ApplyModifier(key, baseValue)` 按**同层求和 → 只乘一次 → 只取整一次**结算：

  ```
  sum    = baseValue + Σ(Op == Add   的 Value)
  scale  = 10000 + Σ(Op == Scale 的 Value)      // 同层求和，不连乘
  scale  = Max(scale, 0)                        // 钳制 ①
  result = sum * scale / 10000                  // 整数运算，向零取整，全程只取整这一次
  ```

  - **两条钳制：** ① `scale` 钳到 `[0, ∞)`——**总折扣不得翻号**。翻号后一笔「消耗」会变成「产出」，而 `ResourceElements` 的两个修正列是**按符号分向**准入的，这一笔会走到另一向的准入上去，并当场撞上入口校验（「产出侧 `LifeSpan` 恒为回复向」那一行）。② 结果与 `baseValue` **同号或为 0**（① 成立时它自动成立，仍写下来作为断言）。
  - **只取整一次**：分步取整会让「两条 −10%」与「一条 −20%」出现 off-by-one，而后端要逐位复算。
  - **结果与顺序无关 ⇒ 不设优先级字段、不设稳定排序、不设声明序约定。** 加法可交换、乘数求和亦可交换，故结果与声明顺序、遍历顺序、条目获得先后全部无关；逐条相乘则相反（两条 −50% 连乘 = −75%，且掺入取整后不可复算），并会让多条小修正叠出远超预期的乘积。
  - **无修正 = 原值返回**；**一个 `ModifierKey` 只能有一个施加点**（不放松，见 `decisions/ADR-0017-capability-flag-and-modifier-pipeline.md`）。
  - 战斗内数值的求值管线用的是**另一套 key 空间** `ModifierTarget`（见 `systems/character-profile/deck/common-properties.md`）：两套 key 不合并——合并会让「一个 `ModifierKey` 只能有一个施加点」被战斗内条目撑破。**量纲与合并算法两侧逐字相同**（万分比整数 · 同层求和 → 只乘一次 → 只取整一次）。
- **消费侧收敛为「一个 flag ↔ 一处消费点」：** 受影响的 UI 组件**自己订阅**并查询 `Has(flag)`，业务逻辑层完全不知道该 power 存在。散落条件的根因是把呈现决策写进了业务层；把决策点归位，条件自然只剩一处。
- **两条启动期断言（`#if DEBUG`，纪律阶梯第 3 级）：** ① 反射遍历 `CapabilityFlag` 成员名，首个词须落在 `{Reveal, Show, Unlock}` 内且不含禁用词 → 违规 `PushError`；② 内容加载期 `PowerData.GrantedFlags` / `Modifiers` 中出现枚举外的值 → `PushError` + `Id`（`.tres` 上的枚举序号会因枚举重排而错位）。
  - **「每个 flag 至少有一处消费点」无法机械检查**（消费点是一段 UI 代码），**如实停在纪律阶梯第 4 级（评审清单）**——不为它造一张必须手工同步的注册表。
- **`status`（启用 / 禁用）与「拥有 / 失去」是正交两维：** 列表成员表达「拥有哪些」，`status` 表达「拥有的这些里哪些当前生效」。失去 = 移出 `List<PlayerPower>`，不是置 `status = 禁用`。详见 `systems/player-profile/player-power/common-properties.md`。

Source: `handoffs/2026-08-30-life-lifespan-merge.md` · `handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md` · `handoffs/2026-07-27b-service-api-contracts.md` · `handoffs/2026-08-06c-skip-channel-removal-priority-two-tier-and-location-codex-edges.md` · `handoffs/2026-08-09b-player-power-fragment-finale-bound-drop-chance.md` · `handoffs/2026-08-10b-grant-source-and-fragment-source-scoping.md` · `handoffs/2026-08-10c-ability-disable-replacement-and-player-statistics.md` · `handoffs/2026-08-15b-monetization-entitlement-purchase-shape-and-scope.md` · `handoffs/2026-08-16d-cost-side-closure.md` · `handoffs/2026-08-16f-elements-modifier-pipeline-opt-in.md` · `handoffs/2026-08-17-travel-destination-and-status-change-elements.md` · `handoffs/2026-08-17b-research-build-panel-and-deck-elements.md` · `handoffs/2026-08-17d-exchange-mechanics-and-transaction-discipline.md` · `handoffs/2026-08-17f-lifespan-restoration-paths.md` · `handoffs/2026-08-17g-element-carrier-gaps.md` · `handoffs/2026-08-17j-event-option-derived-persistence.md` · `handoffs/2026-08-19-profile-change-spec-gaps.md` · `handoffs/2026-08-19-bundle-grant-ordinal-authority.md` · `handoffs/2026-08-19-costkey-statkey-registry.md` · `handoffs/2026-08-19-game-setting-schema.md` · `handoffs/2026-08-19-codex-entry-schema.md` · `handoffs/2026-08-19-pickmany-shortfall-handling.md` · `handoffs/2026-08-22-event-outcome-spec-fields.md` · `handoffs/2026-08-22-mana-baseline-realm-jump.md` · `handoffs/2026-08-25-info-economy-and-codex-expansion.md` · `handoffs/2026-08-27-capability-flag-and-entitlement.md`

## 管理器

| manager | 职责 |
|---------|------|
| **ProfileManager** | 两个 Profile 的唯一写入面；`TryApply(spec)` 原子施加成本 / 产出；modifier pipeline 生效点 |
| **CapabilityManager** | capability flag 聚合 + 具名 modifier 表；`CapabilitiesChanged` 广播 |
| **AchievementManager** | 成就进度累计（组内加权）、60% / 90% 两档一次性奖励发放 |
| **CodexManager** | 图鉴族的收录触发采集、连锁展开与同批去重；写入仍组装 `CodexElements` 交 ProfileManager 单点提交 |
| **GrantPoolPicker**（`internal`） | 账号级 / 轮回级能力条目的**唯一抽取处**：取池（`AllEnabled()` → `(CarrierKind, Scope)` → 去成就限定 → 排除已持有 → 可选锚定 `Rarity`）+ 按 `RarityTier` 加权 seeded 抽取。残卷 · 礼包 · 置换三条渠道共用；见 `systems/player-profile/player-power/_index.md`。**置换经具名方法 `TryPickReplacement` 进入，而不是给既有方法加一个可空 `anchorRarity` 形参**——可空默认值会让「忘了锚定稀有度」成为最短路径，而忘了锚定的置换会把 Tier1 换成 Tier5，**能上线、线上不可见**；名字里带 `Replacement` 则调用方必须显式选择语义。这与「删掉中性诱饵名 `All()`」是同一条纪律 |

## API 面（契约）

> 总则与共享类型见 `systems/architecture.md`「API 契约总则」。本服务**纯本地**，永不跨进程边界，故**全部方法为形态 A**、不实现 `IBootstrappable`。

| 方法 | 形态 | 完整签名 | 失败语义 |
|------|------|----------|----------|
| 载入 | A | `void Hydrate(PlayerProfile profile)` | `profile == null` = 程序缺陷 → `PushError` + 抛；触发 CapabilityManager 首次聚合 |
| 施加变更 | A | `ApplyResult TryApply(ProfileChangeSpec spec)` | **业务失败** → `ApplyResult.Fail(missingElement)`，全有或全无，绝不抛 |
| 只读投影 | A | `ProfileProjection Project(ProfileChangeSpec spec)` | 施加 spec 得到一份**未提交**的只读视图，供收口前重算新一批；**不提交、不广播、不落存档点、不判终态**。**必需缺失**（收口 spec 组装缺陷）→ `PushError` + `throw`。返回类型是包装 `PlayerProfile` 的 `ref struct`，使「不存字段、不跨 `await` 持有」在语言层写不出来 |
| 预校验 | A | `bool CanAfford(ProfileChangeSpec spec)` | 供 UI 灰显 / 预览，**不提交**。**唯一消费点 = Exchange 商店购买的货币格；事件推进路径不调用它**（`selectCost` 无条件施加）。以物易物那一类格子不动货币，可用性改由 `Holds(...)` 判定 |
| 能力查询 | A | `bool Has(CapabilityFlag flag)` | 未授予 = `false`，非错误 |
| 能力持有查询 | A | `bool Holds(AbilityCarrierKind kind, AbilityScope scope, string abilityId)` | 未持有 = `false`，非错误。纯内存查询。消费点 = Exchange 的 barter 格灰显与 barter 提交路径的门面级前置 |
| 数值修正 | A | `int ApplyModifier(ModifierKey key, int baseValue)` | 无修正 = 原值返回 |
| 开关 | A | `ApplyResult SetPowerStatus(string powerId, bool enabled)` | 未拥有该 power → `ApplyResult.Fail` |
| 授予 / 撤销 | A | `ApplyResult GrantPower(string powerId, Source source)` / `ApplyResult RevokePower(string powerId)` | 同上；**`source` 无默认值**——省略即产生来源未知的条目，而残卷的 `x` 直接读它。**`source` 须落在该条目 `(CarrierKind, Scope)` 的合法子集内且不为 `Unknown`**，否则 `PushError` + 拒绝。见 `systems/common-properties.md` |
| 授予池 · 有无 | A | `bool HasGrantable(AbilityCarrierKind kind, AbilityScope scope)` | 池空 = `false`，非错误。**⟺ 残卷全局前置「尚未拥有的法则数 > 0」**（同一个判断，不是两个） |
| 授予池 · 计数 | A | `int GrantableCount(AbilityCarrierKind kind, AbilityScope scope, RarityTier[] rarityFilter = null)` | 供礼包购买入口判「够不够 2 件」与 Exchange / Research 的取池期前置判定（闸 ②）。**`rarityFilter` 为 `null` / 空 = 不限**；给出时口径与 `RarityFilter` 过滤后的实际抽取链一致——闸的判据与抽取链不同口径，就会出现「总池非空、过滤后为空」而闸判过 |
| 付费权益查询 | A | `bool HasPremiumBundle { get; }` | 未购买 = `false`，非错误。`=> Entitlement.BundleGrantOrdinal > 0`，**单点查询、不进任何事件负载**（同 `Has(flag)` / `PendingCount` / `UpgradeRequired` 的纪律）。消费方是 life-cycle-service 的重试上限选行，见 `systems/monetization.md` |
| 授予池 · 抽一条 | A | `bool TryPickGrantable<TRng>(AbilityCarrierKind kind, AbilityScope scope, TRng rng, out string pickedId) where TRng : IRandomSource` | **可选缺失**（池空）→ `PushWarning`，由调用方决定降级方式（残卷静默停摆 / 礼包报错不补发） |
| 授予池 · 抽多条 | A | `bool TryPickGrantableMany<TRng>(AbilityCarrierKind kind, AbilityScope scope, TRng rng, int count, out IReadOnlyList<string> pickedIds) where TRng : IRandomSource` | **可选缺失**（池空或不足 `count`）→ `false` + `PushWarning`；`pickedIds` 带回池中全部已抽出条目（不足时 `Count` < `count`，池空时为空列表），**永不为 `null`**，由调用方据此降级。**无放回**——保证多条互不相同 |
| 置换取池 | A | `bool TryPickReplacement<TRng>(AbilityCarrierKind kind, AbilityScope scope, RarityTier anchorRarity, TRng rng, out string pickedId) where TRng : IRandomSource` | **可选缺失**（锚定档后池空）→ `PushWarning`，调用方按「整个置换成为空操作」处置 |
| 消耗道具次数 | A | `ApplyResult ConsumeItem(AbilityScope scope, string itemId, int count = 1)` | 次数不足 → `ApplyResult.Fail`。**「只扣次数、无产出」的那条路径**（战斗内使用、随售的次数面）；内部组装 `ItemElements` 交 `TryApply` |
| 战斗外使用道具 | A | `ApplyResult UseItemOutOfCombat(AbilityScope scope, string itemId)` | 业务失败（未持有 / 次数耗尽 / 被本轮回禁用）→ `ApplyResult.Fail`，绝不抛；供 UI 灰显「使用」键 |
| 成就采集 | A | `void ReportProgress(AchievementSignal signal)` | — |
| 只读快照 | A | `PlayerProfile Snapshot { get; }` | **只读视图**（非可变引用），供 sync / ViewModel 组装 |

- **`CostSpec` / `RewardSpec` 已合并为单一 `ProfileChangeSpec`**（`ChangeElement.BaseValue` 带符号：负 = 消耗，正 = 产出）。两个类型会诱导出「先 `TryApply(cost)` 再 `TryApply(reward)`」这种半套写入，与「全有或全无、单点提交」直接冲突。
- **`CanAfford` / `ApplyResult.MissingElement` 保留，`AdvanceStage.CostRejected` 与 `AdvanceResult.MissingElement` 删除——判据是「有无消费点」。** 前两者有一个已定存在的消费点（Exchange 的商店购买），删掉要原样加回来；后两者只服务于事件推进路径，而该路径已定「无条件施加、不做付得起校验」⇒ 成员不可达。留着不只是死代码，它会主动诱导后来者把校验加回来。`MissingElement` 是 `CanAfford` 失败时唯一能告诉 UI「差的是哪一样」的通道。
- **商店可以灰显买不起的商品，事件选择面不可以——判据同为一条：「明知做不到仍然去做」有没有意义。** 事件选择面有意义（明知是死路仍然走，与「打不过也得打」同构，且换来一段终局叙事）；商店里点一件买不起的商品没有任何意义——不产生终态、不产生叙事、不推进任何东西，只产生一次挫败。**写下的是判据而非结论**，否则「事件面不灰显」会被误推广到商店。呈现形态（灰显 / 弹窗 / 价格标注）归 Exchange 专场。
- **`CanAfford` 与 `TryApply` 必须走同一条 modifier pipeline**，否则 UI 显示「买得起」而实际拒绝。二者共用一个内部 `Evaluate(spec)`，`TryApply` = `Evaluate` + 提交。
- **`Snapshot` 返回只读视图**（总则 3）；运行态写入一律经 `TryApply`。
- **战斗外使用收敛为单一门面，一次组装、一次事务（承重）。** `UseItemOutOfCombat` 内部**一次**组装 `OutOfCombatUseOutcome`（内容侧模板，见 `systems/character-profile/item/_index.md`）+ 该道具的 `ItemElements` +（`activeEvent == null` 时）`ItemUseElements`，交**一次** `TryApply`。分两次调用即「先扣次数后产出失败」这种半套写入，与 `CostSpec` / `RewardSpec` 被合并的理由同源。
  - **`activeEvent == null ⇒ 写 ItemUseElements，否则不写`** 是可机械判定的组装判据：事件之内的那一次账已由该事件的 `AppliedChange` 承载，再记一条即重复记账。
  - **失败语义分两层，不重复。** 门面在组装前查一次持有与剩余次数，不足 → `ApplyResult.Fail`（业务失败，绝不抛）；element 层那两条「可选缺失 + `PushWarning` + 空操作」是**防御位**，正常链路不可达。
  - **Exchange 的以物易物提交路径同款，且该保护是强制项。** 门面在组装 spec 前查一次 `Holds(...)`，`false` → `ApplyResult.Fail`（业务失败，绝不抛），不组装、不进 `TryApply`；element 层那条「`Remove` 目标不在持有列表 = 可选缺失 + `PushWarning` + 空操作」同样是**防御位**，正常链路不可达。**`Remove` 的全局失败语义因此一字不改。**
    - **不扩 `CanAfford` 去读 `AbilityElements`。** 扩了就要回答「`Remove` 不足算不算 `Fail`」，而那与施加失败语义表正面矛盾——等于改全库每一条 `Remove` 的语义，代价远超这一个形态。
    - **不把 barter 失败复用 `ApplyResult.MissingElement`**：它是 `CostKey`，装不下一个 `AbilityId`；UI 的「差哪一样」由 barter 格自己恒可见的支付要求承载，不新增字段（`UseItemOutOfCombat` 已有「返回 `Fail` 但无 `MissingElement`」的先例）。
    - **代价明写：** 保护落在门面而非 element 层 ⇒ 任何绕过门面直接组装 barter spec 的调用方都能触发白送。这与 `UseItemOutOfCombat` 承担的是同一类风险、同一种处置。
  - **两层用同一个门面，用 `AbilityScope` 选层。** 储物袋是跨两个持久层的呈现视图，同一个「使用」键要同时服务法宝与古宝；为法宝另开一个 `ConsumeCharacterItem` 会重演按类分裂的方法 / 枚举，而 `PowerScope` / `ItemScope` 合并为 `AbilityScope`、`Source` 不按类拆四个是同一条纪律的两个先例。
- **四个授予池方法为何落在本服务：** 抽取需要**内容池**（content-service）与**已持有集合**（profile-service）两样东西。后者是本服务的自有状态，前者可经对方服务门面跨服务读取（跨服务方法调用允许，不触及对方 manager 私有字段）；反向（放 content-service）则要求它读 `PlayerProfile`，违反「服务之间不读写对方字段」。它们**纯内存查询、不跨边界，故为形态 A、不带 `Async`**。**随机源以泛型约束 `TRng : IRandomSource` 传入**，使账号级掷骰（`AccountRandom`，契约定义的 SplitMix64）与轮回级抽取（`GodotRandomSource`，子流薄适配）共用同一段取池代码而不装箱；类型定义见 `systems/common-properties.md`。**抽取结果在 spec 组装之前定稿** —— `AbilityChangeElement` 只拿到已定稿的 `Id`，与既定的「随机在 spec 组装前掷完」一致。置换候选池复用同一 picker（只多传一个 `anchorRarity`）⇒ 全库只有一处抽取能力条目的代码。
- **`CapabilityFlag` 是 C# `enum` 而非字符串 key**：flag 的消费点必然是一段 UI 代码，新增 flag 本就要写消费代码；字符串只是把「拼错了」从编译期推迟到运行时。可加的是 `.tres` 里**谁授予哪个已定义的 flag**。

**事件面：**

| 事件 | 负载 |
|------|------|
| `CapabilitiesChanged` | **空负载**——订阅者收到后自行 `ProfileService.Instance.Has(flag)` 重查（既定的「一个 flag ↔ 一处消费点 · 单点查询」；把生效集塞进负载反而制造第二份真值） |
| `AchievementTierReached` | `(string GroupId, int TierPercent)` |

Source: `handoffs/2026-08-30-exchange-barter-support.md` · `handoffs/2026-07-27b-service-api-contracts.md` · `handoffs/2026-08-12b-grant-source-per-kind-scope.md` · `handoffs/2026-08-12e-ability-grant-draw-pool.md` · `handoffs/2026-08-16b-cross-library-alignment-and-bridge-ledger.md` · `handoffs/2026-08-16d-cost-side-closure.md` · `handoffs/2026-08-16f-elements-modifier-pipeline-opt-in.md`

## 与其他服务的关系

- **上游写入方：** `life-cycle-service`（轮回状态与隐藏属性）、`combat-service`（战斗内的 life / deck / 道具变更）、`future-event-service`（key points 推进）——**都只经 ProfileManager 写**。
- **下游：** `sync-service` 负责把变更后的聚合持久化 / 上行；本服务不做 I/O。
- **内容查找：** 一切 `Id` → 内容的解析经 `content-service.ContentRegistry`。

## 决策(-> ADR)

- **capability flag（布尔）+ modifier pipeline（数值）两条通道** → `decisions/ADR-0017-capability-flag-and-modifier-pipeline.md`（Accepted）；**两条通道的落地形态与合并算法**（扁平枚举 + 正向三词表命名 · 幂等集合并 · **注册面两层共用** · 万分比整数 + 「同层求和 → 只乘一次 → 只取整一次」· 顺序无关故不设优先级）→ `decisions/ADR-0116-capability-flag-and-modifier-shape.md`（Accepted）。
- **单一 profile-service 拥有两层 profile、ProfileManager 为唯一写入面** → `decisions/ADR-0009-single-entry-points-and-orchestrator.md`（Accepted）。
- **收口前的重算走只读投影 `Project(spec)`，不新增第二个写入面** → `decisions/ADR-0108-profile-readonly-projection.md`（Accepted）。

Source: `handoffs/2026-07-25b-event-cost-fields-capability-flags-and-service-hierarchy.md` · `handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md`
- **强制在线 · 云端权威** → `decisions/ADR-0003-online-cloud-authority.md`（Accepted）。

## 待决问题

- **`status` 与「拥有 / 失去」两态的存档表达。** 两个正交维度如何编码进 schema 未定。
- **AchievementManager 的触发采集面。** 成就进度靠订阅 EventBus **被动采集**（解耦但易漏），还是由各服务**主动上报**（可靠但反向依赖）？
- **成就两档奖励内容。** 阈值 60% / 90%、一次性、目录 80% 可见已定；**各档发放何种奖励**待定。→ `ux/screen-flow.md`。
- **元进程字段结构。** `Achievement` 条目 schema 未定；各账号级条目的解锁 / 获取 / 失去的具体触发未定。（`PlayerPower` / `PlayerItem` 的持有条目形态、`AccountInfo` 与 `GameSetting` 的字段面已定，见 `systems/player-profile/_index.md`。）→ `systems/player-profile/`。
- **PlayerPower 的平衡边界。** 方向已定为「轻度提升、PvE-only 可容忍」；是否影响 cycle seed / 计分公平仍待定。

Source: `handoffs/2026-08-06c-skip-channel-removal-priority-two-tier-and-location-codex-edges.md` · `handoffs/2026-08-10c-ability-disable-replacement-and-player-statistics.md` · `handoffs/2026-08-15b-monetization-entitlement-purchase-shape-and-scope.md` · `handoffs/2026-08-16d-cost-side-closure.md` · `handoffs/2026-08-16f-elements-modifier-pipeline-opt-in.md` · `handoffs/2026-08-17d-exchange-mechanics-and-transaction-discipline.md`

## 对应
提炼至：`.claude/knowledge/systems/profile-service.md`（引用层，待建）。
