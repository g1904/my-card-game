# profile-service（服务）

> 档案服务：**`PlayerProfile` 与 `CharacterProfile` 的唯一写入面**；capability 聚合；成就。**判据 ② —— 需要事务性地跨多个字段一致写入。**

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

### 为何是**一个**服务同时拥有两层 profile

**`PlayerProfile` 持有 `List<CharacterProfile>`**（见 `systems/player-profile/_index.md`）——两层本就是一个聚合。由**单一 profile-service** 作为两者的唯一写入面，带来：

- **事务天然闭合。** 一次结算里「扣账号级 `PlayerItem` 使用次数 + 扣轮回级灵玉 + 加卡牌」落在**同一事务**内，不需要跨服务协调原子性。
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
- **首批具名 element 中已确定的一组：道统残卷。** 「cost element 清单未定」这条待答由此添了具体条目——`PowerFragmentAccumulated`（累加 / 置值）、`PowerFragmentWinOrdinal`（自增）、`PowerFragmentFirstWin(chapter)`（置位）、以及**授予法则**（复用 `GrantPower` 语义，但作为 `Spoils` 的一个 element 提交；**该 element 必须携带 `Source`，残卷这一路取 `Source.FinaleWin`**——凡授予 power / item 的 element 一律强制带来源，见 `systems/common-properties.md`）。四者与 `baseReward` / `lifeTotal` 扣减 / `lifeSpanCost` 落在 Finale 的**同一次 `TryApply`** 内，符合「一个事件的收口是一次事务、一个存档点」。**`Accumulated` 是万分比整数、施加后钳制到 `[0, 10000]`**——上界来自它自己的万分比语义，是钳制必须逐 element 配表（见下）而非定通则的例证之一。
- **`ProfileChangeSpec` = 平级只读列表，逐条按施加语义分列（承重）。** 判据是**施加语义根本不同就分列**，**列表数不进承重表述**——它随字段族增长，把数字写死等于每加一列就要改一次这条纪律。当前各列：`Elements`（资源，量：可加、要钳制、**按 `ResourceElements` 表逐行决定是否走 modifier pipeline**）· `AbilityElements`（能力，集合成员操作：幂等增删、无量纲、**绝不走 modifier pipeline**）· `Stats`（统计计数，纯计数：不钳制、失败不阻断、**绝不走 modifier pipeline**）· `StatusChanges`（Status 规则字段，**绝对置值**：赋一个已算好的值、不累加、按 key 的声明类型可为 id、**绝不走 modifier pipeline**）· `DeckElements`（卡组，**带层数的构筑变更与多重集增删**：层数不可加、散牌可同名多张、无 `Source`、**绝不走 modifier pipeline**）· `PlotElements`（剧本，**按 `ArcId` 的带载荷 upsert**：整条替换、不钳制、无量纲、**绝不走 modifier pipeline**）· `EventStateChanges`（事件态，**绝对置值**）。压进一个带符号 `int` 是让类型说谎。类型定义、以及「一条新语义该落在哪一层（分列 / 加 `Op` / 配表加列）」的三级判据见 `systems/architecture.md`「共享核心类型」。**各列表在同一次 `TryApply` 内提交，「全有或全无、单点提交」不变。**
  - **`AbilityChangeElement` 只承载已定稿的 `Id`。** 「随机挑一条来移除」「限定只能动神通」都是**结算侧的选取规则**，在 spec 组装之前就已掷完——把随机性留在 spec 里等于让同一份 spec 重放两次得到不同结果，而 `PastEventEntry.AppliedChange` 正要求它可重放。这与「`EventOption` 产出即定稿、落存档不重算」是同一条纪律。
  - **置换 = `Remove` + `Grant` 两条 element，由 `PairKey` 配对，不是一条 `Replace`。** ① 原子性已由「全有或全无」免费提供，复合 element 等于在类型层重复实现事务；② `Grant` / `Remove` 各有独立用途（残卷授予法则是纯 `Grant`，事件负向条目是纯 `Remove`），一条 `Replace` 会让「给予半边」与独立 `Grant` 分裂成两条施加路径；③ `PairKey` 保住可读性（履历与 UI 要显示「你用 A 换了 B」，`AppliedChange` 重放时因果还原得出来）；④ **代价明写**：列表形态约束不了配对，故需一条入口校验。
  - **三类移除的表达就此闭合：** 置换型剥夺 = `Remove` + `Grant`（同 `PairKey`）· 三档禁用 = `Disable` 带 `Duration` · 不强制剥夺 = **不表达**（缺省，没有 element）· 战斗内 `IgnoresProtection` = **仍不进 spec**（只动战场条目，不写 Profile）。
  - **施加失败语义表：**

    | 情形 | 语义 | 处置 |
    |---|---|---|
    | `Remove` / `Disable` 的目标不在持有列表 | 可选缺失 | `PushWarning` + 该 element 空操作，**不使整批失败** |
    | `Grant` 的目标已持有 | 可选缺失 | 同上（候选池已排除已有，出现即内容错误） |
    | `AbilityId` 解析不到内容条目 | 必需缺失 | `PushError` + 整批拒绝（悬空 `Id` 写进 Profile 会污染存档） |
    | `PairKey` 配对不成立（非空却未恰好配成 `Remove` + `Grant`，或两者 `(Kind, Scope)` 不同） | 必需缺失 | `PushError` + 整批拒绝 |
    | `Op == Grant` 且 `(Kind, Scope, Source)` 不在合法子集表内，**或 `Source == Unknown`** | 必需缺失（代码组装缺陷） | `PushError` + 整批拒绝（与 `PairKey` 同档）。合法子集表见 `systems/common-properties.md`；它是**代码常量静态查表**，与置换同池判据共用 `(Kind, Scope)` 键。**读档侧相反——遇不合法的既有条目 `PushWarning` + 保留原值**，回落 `Unknown` 会压低残卷的 `x` 并让档位回跳 |
    | `AbilityElements` 出现在 `SelectCost` 内 | 必需缺失 | `PushError` + 整批拒绝（不变式，见 `systems/adventure-event/common-properties.md`） |
    | `Source == ExchangeSell` 出现在 `Op == Grant` 的 element 上 | 必需缺失（代码组装缺陷） | `PushError` + 整批拒绝。它是**卖出侧**的记账值，只能出现在 `Op == Remove` 且 `(Kind, Scope) == (Item, Character)` 的 element 上；合法子集表见 `systems/common-properties.md` |
    | `UpgradeTechnique` 的目标不在卡组 / 已达层数上限 | 可选缺失 | `PushWarning` + 该 element 空操作，**不使整批失败** |
    | `ForgetTechnique` / `RemoveLooseCard` 的目标不在卡组 | 可选缺失 | 同上 |
    | `LearnTechnique` 的目标已在卡组 | 可选缺失 | 同上（候选池已排除已持有，出现即内容错误） |
    | `DeckChangeElement.Id` 解析不到内容条目（功法 / 卡牌注册表） | 必需缺失 | `PushError` + 整批拒绝（悬空 `Id` 写进 Profile 会污染存档） |
    | `Op ∈ { LearnTechnique, UpgradeTechnique }` 且 `Tier < 1`，或其余 `Op` 且 `Tier != -1` | 必需缺失 | `PushError` + 整批拒绝 |
    | `DeckElements` 出现在 `SelectCost` 内 | 必需缺失 | `PushError` + 整批拒绝（不变式，与 `AbilityElements` 同款） |
    | `SelectCost.Elements` 中 `Key == LifeSpan` 且 `BaseValue > 0` | 必需缺失 | `PushError` + 整批拒绝。成本侧的 `LifeSpan` 恒为消耗向，寿元回复只走 outcome 侧；**它是取值域收紧、不是「某个列表恒为空」，故与上两条各自独立**，见 `systems/adventure-event/common-properties.md` |
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
    | `EventStateAssignment` 的 `Key` 与非空载荷格不匹配（如 `Key == EventOption` 却填了 `ActiveEvent`，或两格同时非空） | 必需缺失（代码组装缺陷） | `PushError` + 整批拒绝 |
    | `Key == EventOption` 且两格皆为 `null`（置空） | 必需缺失 | `PushError` + 整批拒绝（**只有 `ActiveEvent` 可置空**；轮回进行中把当前批置空即让玩家无路可走） |
    | 同一批 `EventStateChanges` 内出现两条同 `Key` | 必需缺失（组装缺陷） | `PushError` + 整批拒绝（绝对置值下两条同 `Key` 意味着调用方自己也不知道最终该落哪一份） |
    | `ChangeElement.Key` 在 `ResourceElements` 中无对应行 | 必需缺失（代码缺陷） | `PushError` + 整批拒绝（缺行 = 取值域、终态与修正准入三者皆不明） |
    | `StatusAssignment.Key` 在 `StatusFields` 中无对应行 | 必需缺失（代码缺陷） | `PushError` + 整批拒绝（缺行 = 值类型与取值域皆不明） |
    | `Id` 型 `StatusAssignment` 的值经 `ContentRegistry` 解析不到 | 必需缺失 | `PushError` + 整批拒绝 |
    | 表内登记的 `ModifierKey` 无任何法则注册修正 | 正常，非失败 | `ApplyModifier` 原值返回 |

  - **可追溯性日志（非告警）：** 施加任一 `AbilityChangeElement` 时打一行 `[ProfileManager-TryApply] ability op=Remove kind=Power scope=Player id=xxx pair=yyy`。能力得失是玩家最在意、也最容易被投诉的一类变更，必须在日志里留痕。
  - **施加 `Disable` 时若 `activeCombat != null`**，同步调用战场侧的移除路径——**复用 `IgnoresProtection` 已有的「从战场移除一个受保护 `Power` 条目」内部路径**，不新写第二条；并在 `#if DEBUG` 下 `PushWarning`（该路径在当前链路下不可达，属纪律阶梯第 3 级的大声失败）。
  - **`PowerScope` / `ItemScope` 合并为单一 `AbilityScope`**（值域与语义完全相同；保留两个会逼 element 侧写一层无意义的转换。当前无线上存档 ⇒ 零迁移）。
- **具名 element `BundleGrantOrdinal`：置值语义，表中两个修正列均为空（承重）。** 它被赋为**预先算好的** `ordinal`（不是加法），落 `ProfileChangeSpec.Elements`，与礼包的三条 `Grant` 在**同一次 `TryApply`** 内提交（全有或全无）。留空的理由与统计层同源，只是后果严重得多：**经 pipeline = 一条法则能改写付费凭证**。序号自增与「是否抽中」无关——闸 ③ 真发生时该项计未兑现、不补发，但序号照常 +1，否则下一次购买复用同一 `ordinal`、掷出完全相同的序列，幂等键当场失效。授予流程与三道闸见 `systems/monetization.md`。
- **统计计数经 `StatDelta` 写入，走宽松口径。** `PlayerStatistics` 字段全部只读，**唯一写入路径是 `Stats` 列表经 `TryApply`**，不提供 setter；它与规则字段**同批、同事务**提交。宽松之处只有两条落在本服务：**未知 `StatKey` 跳过而非整批失败**、**统计 element 绝不经过 modifier pipeline**（否则一条法则能改写统计数字）。其余三条（读档校验、上行被拒、后端）见 `sync-service.md`。
- **Status 规则字段经 `StatusChanges` 写入，语义是绝对置值（承重）。** `CharacterProfile.Status` 上的规则字段（`CurrentLocationId` · `LocationEventCount` · 三个隐藏属性 band · `ChapterLifeSpanBudget`）不提供 setter，**唯一写入路径是 `StatusChanges` 列表经 `TryApply`**，与资源 / 能力 / 统计**同批、同事务**提交。**提交的是已算好的绝对值**——「+1」「归 0」「按前值 + `AppliedChange` 算出的新档」都由组装方（life-cycle-service）先算成绝对值再置入，本 manager 不做任何加减。
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
  - **施加侧写严、读档侧读宽，不对称是有意的。** 施加侧的悬空来自代码 / 内容组装缺陷，此刻拒绝还救得回来；读档侧的悬空来自 overlay 热更 / 版本回退，此时拒绝等于让一次内容更新废掉玩家的轮回，故降级为该条惰性并保留条目（见 `systems/services/plot-manager.md`）。先例是 `(Kind, Scope, Source)` 合法子集表的同款读写不对称。
  - **拓扑校验不在本入口。** 「新 `NodeId` 必须是当前节点的一条出边或等于当前节点」由 PlotManager 在推进时 `#if DEBUG` 断言；本 manager 只校验 `Id` 可解析 / 不串线 / 同批不重复。唯一组装方的内部不变式落在纪律阶梯第 3 级即可，升到入口强校验换来的是分层污染。
  - **可追溯性日志（非告警）：** upsert 时打一行 `[ProfileManager-TryApply] plot arc=<ArcId> node=<NodeId> state=<State>`。与能力得失同理——剧本推进是玩家会来问「我这条线怎么突然变了」的一类变更。
  - **增列 ⇒ bump 存档 schema 版本**（当前无线上存档 ⇒ 空迁移）。`PastEventEntry.AppliedChange` 随 `ProfileChangeSpec` 自动获得剧本推进的账，**不新增字段**。
- **事件态经 `EventStateChanges` 写入，语义是整块绝对置值（承重）。** `CharacterProfile.eventOption`（当前批快照）与 `CharacterProfile.activeEvent`（结算期间的权威副本）不提供 setter，**唯一写入路径是 `EventStateChanges` 列表经 `TryApply`**，与资源 / 能力 / 统计 / Status / 卡组 / 剧本**同批、同事务**提交。条目类型 `EventStateAssignment` 按 `Key` 分成两个具名可空载荷格，**不用裸 `object`**——贯穿链路的类型一致性不做隐式装箱，且「哪一格该有效」因此是可机械校验的一列（与 `StatusAssignment` 的双字段单列表同构）。
  - **提交的是已算好的整块，本 manager 不做合并 / 增量。** 组装方（life-cycle-service）先算出完整的 `EventOptionSave` / `ActiveEventState` 再置入；两处派生（Explore 揭示 · Exchange 刷新）各是一次对 `activeEvent` 的整体置值。与 `StatusChanges` / `PlotElements`「提交已算好的绝对值」同一条纪律，也使 `AppliedChange` 可直接重放。
  - **它是 Exchange 刷新那一笔原子性的承载。** `ChangeElement(Jade, -刷新价)` 与新库存 + `RerolledCount` 必须落在**同一次** `TryApply`：只落 `-jade` 则同一笔钱可再刷一次（正是防重掷纪律封死的那个窗口），只落库存则免费刷新。分列而非塞进既有列，是因为 `Elements` 只装带符号的量、`StatusChanges` 的值是标量或 id，都装不下一个结构块。
  - **恒不经 modifier pipeline。** 一条法则若能改写 `RerolledCount` 或商店库存，等于账号级内容改写轮回级的定稿实例。
  - **`EventStateChanges` 在 `SelectCost` 内恒为空**，与 `AbilityElements` / `DeckElements` / `PlotElements` 同款不变式、各自独立成行，同样落为物化组装后的断言。理由同构：成本侧只放**可如实计价的量**，而「把一个事件态置成某个值值多少寿元」无法回答。
  - **`activeCombat` 不在本列内。** 它形态相同却仍未明写写入通道，本次不动战斗存档段；这一处不对称是已知的，见待决问题。
  - **可追溯性日志（非告警）：** 置值时打一行 `[ProfileManager-TryApply] eventState key=<Key> instance=<EventInstanceId | batch=<BatchId>>`。它是「退出重进后看到的库存 / 揭示态对不对」这类问询的第一手证据。
  - **增列 ⇒ bump 存档 schema 版本**（当前无线上存档 ⇒ 空迁移）。
- **只读投影 `Project(spec)`：先算后提交，不新增写入面（承重）。** 收口时新一批 eventOptions 必须依**更新后的** profile 重算（`pastEvent` 是 future-event-service 的一等输入），而收口又必须是**一次**事务、一个存档点——两条承重纪律都不放松，故本服务提供一个**施加 spec 后返回未提交只读视图**的方法：life-cycle-service 用它算出新一批，再把批一并放进同一次 `TryApply`。
  - **它不是第二个写入点。** 投影不改任何字段、不触发 `CapabilitiesChanged`、不产生存档点；「一切写入经 `TryApply`」原样成立。
  - **本模型内已有两处同形的先例**：`AppliedChange` 是可直接重放的账（重放即一次纯施加）；`CanAfford` 与 `TryApply` 共用 `Evaluate(spec)`（先算、只有后者提交）。
  - 投影与 `Evaluate(spec)` 的复用关系、以及投影是否同样做钳制与终态判定，见待决问题。
- **钳制、终态与修正接入查 `ResourceElements` 表，不散落字段判断（承重）。** 每个资源 element 在表中占一行 `(Min, Max, DepletionDefeat, CostModifier, GainModifier, AllowedOps)`：`Min` / `Max` 是它的取值域，`DepletionDefeat` 非空即表示**触底构成终态**并给出对应的 `DefeatReason`，两个修正列是它在 modifier pipeline 上的两向准入，`AllowedOps` 是它允许的施加方式集合（`Add` / `Set` / 两者）。类型定义与配表理由见 `systems/architecture.md`「共享核心类型」。首批：

  | `CostKey` | Min | Max | 归 Min 时 | `CostModifier` | `GainModifier` | `AllowedOps` | 依据 |
  |---|---|---|---|---|---|---|---|
  | `LifeSpan` | 0 | 无 | **终态** `DefeatReason.LifeSpanExhausted` | `LifeSpanCost` | `null` | `Add` | 寿元归 0 = 大限将至；`lifeSpanCost` 是文档点名的第一个 modifier 用例。**产出向（寿元回复）已有通道但仍不开修正口**：一条「延寿 +X%」的法则直接乘上篇章时长旋钮，且法则账号级永久持有、须按「老账号全开」校准；按缺省豁免，日后确需时加一行即可。与「`PowerData` 不得含 `LifeSpan` 产出」互补——那条关掉「法则直接产寿元」，本格关掉「法则放大回寿」。**只有消耗与回复两向，从无「赋一个绝对寿元」的通道**，开 `Set` 即给内容一条绕过 `LifeSpanCost` 修正的路 |
  | `Jade` | 0 | 无 | 无（只是变穷） | `null` | `null` | `Add` | `DefeatReason` 三值封闭、无灵玉项；灵玉随轮回清理，不承载终态语义。**两列恒为 `null`**：商店价格修正 `ModifierKey.ShopPrice` 在**物化 / 展示侧**施加并写进 `ExchangeOffer.ListPrice`，element 路径拿到的 `BaseValue` 已是修正后的标价——再填一次即**打两次折**（玩家看到 80、实扣 64，且灰显判据随之偏移），见下「只施加一次」。灵玉的每一笔都是交易的增减，无置值通道 |
  | `LifeTotal` | 0 | **无**（明确不设上界） | **终态** `DefeatReason.LifeTotalExhausted` | `null` | `null` | `Add` | 耐久只跟踪单值、无上限截断；归 0 = 角色终结。无既定修正意图，有具体法则条目时再填；同样无置值通道 |
  | `ManaLimit` | 0 | 无 | 无（不构成终态） | `null` | `null` | `Add` | `Min = 0` 只排除「负上限」这个无法定义的状态（每回合恢复到负值讲不通），**不是被否决的那两条护栏**（保底 ≥ 1 与死牌转化仍然不做，见 `systems/character-profile/mana.md`）；两个修正列留空是**硬要求**——任一列开放，一条法则即可把 ±1 放大为 ±2，直接推翻「单次变动幅度恒为 1」这条承重规则。**`Set` 恒不开亦是硬要求**：一条置值即可跳档，同一条承重规则同样失去载体 |
  | `Experience` | 0 | 无 | 无 | `null` | `null` | `Add` | 修行经验只增不赋；无上界、不构成终态 |
  | `Faith` | 0 | 100 | 无（触底不构成终态） | `null` | `null` | `Add` | 道心经隐藏属性推拉施加，是增减语义；区间来自档位表。**两个修正列留空**：一条法则能伪造隐藏属性，即等于伪造整条剧本线的触发条件 |
  | `MaleficQi` | 0 | 100 | 无（触底不构成终态） | `null` | `null` | `Add` | 煞气同上（可被净化下拉，故两向皆走 `Add`） |
  | `PowerFragmentAccumulated` | 0 | 10000 | 无 | `null` | `null` | `Add \| Set` | 万分比累计，直接决定「这次 Finale 是否授予一条法则」——经 pipeline = **法则加速获得法则**的自举回路。**同一个 key 上真的需要两种**：每次 Finale 累加 `x`（`Add`）、发放法则后重置为 `Base(x + 1)`（`Set`），这是 `Op` 必须逐条带而非逐行配单值的现存例证 |
  | `PowerFragmentWinOrdinal` | 0 | 无 | 无 | `null` | `null` | `Add` | **序号**：自增值被修正即掷骰序列漂移，与 `BundleGrantOrdinal` 同理；自增 = `Add(+1)`，不需要 `Set` |
  | `PowerFragmentFirstWin(chapter)` | 形态未定 | — | 无 | `null` | `null` | `Set` | **置位**：无量纲，修正无意义，`Add` 对布尔同样无意义。它以什么 `CostKey` 形态进 `Elements` 归「cost element 清单」那一问 |
  | `BundleGrantOrdinal` | 0 | 无 | 无 | `null` | `null` | `Set` | 付费凭证的序号，经 pipeline = 一条法则能改写付费凭证（见 `systems/monetization.md`）；它被赋为**预先算好的** `ordinal`，不是加法 |

  末三行随各自的 `CostKey` 成员登记时同步生效。

  - **`Op == Set` 恒不经 modifier pipeline。** `BaseValue` 在 `Set` 下是一个已算好的绝对值，**符号不表达方向**，「按符号分向」无从判断该取 `CostModifier` 还是 `GainModifier`；更重的理由与 `StatusChanges` 同源——让一条法则改写一个已算定的权威值（付费凭证序号、万分比累计），等于让内容改写权威值。
  - **`AllowedOps` 含 `Set` 的行，两个修正列必须恒为 `null`** —— 落为**启动期断言**（与「表覆盖 `CostKey` 全部成员」同档），使上一条不靠人记。**代价明写**：这条断言把「允许 `Set`」与「两个修正列为 `null`」焊在同一个 key 上，结构上排除「同一 key 既走修正的 `Add`、又有不走修正的 `Set`」这一形态；首批与待登记 key 全部零摩擦。
  - **每一行的 `AllowedOps != 0`** —— 同样落为启动期断言：空集意味着该 element 没有任何合法写法。

  - **两个修正列是 opt-in 白名单，缺省豁免（承重）。** 缺省方向不对称：漏填时若缺省豁免，最坏是某条法则本该修正它却没修正——数值不对、可见可复现、改一行修好；若缺省经 pipeline，最坏是某条法则**静默地**改写了幂等键 / 付费凭证 / 元进程计数，无人察觉，且在云端权威 + 后端复算下表现为两侧算不一致。故缺省取豁免侧。
  - **按符号分向。** 同一个资源 element 的消耗向与产出向共用一个 `CostKey`，一条「寿元消耗 −20%」的法则若不分向，会把**寿元回复也削 20%**；既有术语本就是分向的（`lifeSpanCost` 是成本向的名字，不是 `LifeSpan` 字段的名字）。向性由 `BaseValue` 的符号给出，**不在 key 名里再编码一次**——那等于两处真值，且法则条目侧要为「消耗与产出都改」写两条 modifier。
  - **修正与否是 element 类型的属性，不是单次变更的属性。** 故它配在表里，而不是让 `ChangeElement` 自带一个 `ModifierKey?`：后者允许组装方逐次决定「这次让不让法则改」，把一条纪律降级为调用方选项，且 `AppliedChange` 重放时同一 key 可能带不同修正配置。
  - **一个 `ModifierKey` 只能有一个施加点（承重）。** 判据：**该修正后的值是否需要在施加之前呈现给玩家**。需要 → 施加点在物化 / 展示侧（商店价格必须先算才能标价），此时它**不得**再进本表，否则打两次折；不需要 → 施加点在 `TryApply`（`lifeSpanCost` 属此类：`selectCost` 物化时 pipeline 尚未施加，在 `TryApply` 那一刻才生效）。
    - **只读查询不构成施加点。** 寿元 Band 2 的 `selectCost` 精确展示取 `ApplyModifier(LifeSpanCost, SelectCost 内的 LifeSpan 值)` 的**查询结果**，**不写回定稿实例**——`ApplyModifier` 本就是通用查询，读一次不改变任何状态；写回才是第二个施加点，会打两次折（与 `Jade` 行明写的坑同款）。故 `LifeSpan` 行的 `CostModifier` 保持 `LifeSpanCost`、施加点仍在 `TryApply`，而 Band 2 显示的是玩家实际会被扣的数。
  - **表里出现的 key 必须是 `ModifierKey` 的成员，反向不要求。** `ApplyModifier` 仍是通用查询——非 element 路径的数值（商店价格、掉落权重、战斗内数值）照常各自调用它。本表**只约束 element 施加路径**，不收窄 `ApplyModifier` 的用途。
  - **启动期断言表覆盖 `CostKey` 的全部成员。** 漏行即缺省行为不明，必须在启动期 `PushError`，而不是在轮回中途撞上。

  - **`Min = 0` 是资源族的默认，例外逐条写明。** 寿元取默认（截断，不允许为负）的理由：① Band 2 的「标红精确余量倒数」是寿元在全库**唯一**的精确显示通道，让它显示负数与该呈现的语义直接矛盾；② 截断后 `lifeSpan <= 0` 与 `== 0` 两种判据写法同解，消掉一个本库从未指定过的歧义面；③ 剩余寿元跨篇章结转要求它是一个可加的**非负预算**，负值落存档会让读档校验与元进程的寿元曲线都要处理负轴而换来零收益。
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
- **可加性。** 新增一种资源 element = 新增一个 element 类型 + 数据字段；不新增服务、不改调用方。这正是**不为 power / item / card / resource 各开一个 collection 服务**的替代品（见 `_index.md` 的拆分轴）。

### CapabilityManager：能力标记聚合面

capability flag 体系归本服务。

- 在启动及 PlayerProfile 变更时，遍历**拥有且 `status = 启用` 且不在 `CharacterProfile.disabledAbility` 内**的 `PlayerPower`，把它们声明授予的 **capability flag**（如 `RevealHiddenStats`、`ShowExploreType`）聚合为一份**生效能力集**，并把具名 **modifier** 聚合为修正表。**第三条与门是轮回级抑制**：被禁用的条目**不进生效能力集、不进修正表**（禁用一律截断在「进入生效面」那一步，见 `systems/character-profile/power/_index.md`）。因本服务同时拥有两层 profile，「聚合账号级法则时要读轮回级禁用表」**不跨服务、不新增依赖边**；禁用表写入后重新聚合并照常广播空负载的 `CapabilitiesChanged`——**多了一个触发源，不新增机制**。
- 变更时经 **EventBus** 广播 `CapabilitiesChanged`。
- **消费侧收敛为「一个 flag ↔ 一处消费点」：** 受影响的 UI 组件**自己订阅**并查询 `Has(flag)`，业务逻辑层完全不知道该 power 存在。散落条件的根因是把呈现决策写进了业务层；把决策点归位，条件自然只剩一处。
- **`status`（启用 / 禁用）与「拥有 / 失去」是正交两维：** 列表成员表达「拥有哪些」，`status` 表达「拥有的这些里哪些当前生效」。失去 = 移出 `List<PlayerPower>`，不是置 `status = 禁用`。详见 `systems/player-profile/player-power/common-properties.md`。

Source: `handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md` · `handoffs/2026-07-27b-service-api-contracts.md` · `handoffs/2026-08-06c-skip-channel-removal-priority-two-tier-and-location-codex-edges.md` · `handoffs/2026-08-09b-player-power-fragment-finale-bound-drop-chance.md` · `handoffs/2026-08-10b-grant-source-and-fragment-source-scoping.md` · `handoffs/2026-08-10c-ability-disable-replacement-and-player-statistics.md` · `handoffs/2026-08-15b-monetization-entitlement-purchase-shape-and-scope.md` · `handoffs/2026-08-16d-cost-side-closure.md` · `handoffs/2026-08-16f-elements-modifier-pipeline-opt-in.md` · `handoffs/2026-08-17-travel-destination-and-status-change-elements.md` · `handoffs/2026-08-17b-research-build-panel-and-deck-elements.md` · `handoffs/2026-08-17d-exchange-mechanics-and-transaction-discipline.md` · `handoffs/2026-08-17f-lifespan-restoration-paths.md` · `handoffs/2026-08-17g-element-carrier-gaps.md` · `handoffs/2026-08-17j-event-option-derived-persistence.md`

## 管理器

| manager | 职责 |
|---------|------|
| **ProfileManager** | 两个 Profile 的唯一写入面；`TryApply(spec)` 原子施加成本 / 产出；modifier pipeline 生效点 |
| **CapabilityManager** | capability flag 聚合 + 具名 modifier 表；`CapabilitiesChanged` 广播 |
| **AchievementManager** | 成就进度累计（组内加权）、60% / 90% 两档一次性奖励发放 |
| **GrantPoolPicker**（`internal`） | 账号级 / 轮回级能力条目的**唯一抽取处**：取池（`AllEnabled()` → `(Kind, Scope)` → 去成就限定 → 排除已持有 → 可选锚定 `Rarity`）+ 按 `RarityTier` 加权 seeded 抽取。残卷 · 礼包 · 置换三条渠道共用；见 `systems/player-profile/player-power/_index.md`。**置换经具名方法 `TryPickReplacement` 进入，而不是给既有方法加一个可空 `anchorRarity` 形参**——可空默认值会让「忘了锚定稀有度」成为最短路径，而忘了锚定的置换会把 Tier1 换成 Tier5，**能上线、线上不可见**；名字里带 `Replacement` 则调用方必须显式选择语义。这与「删掉中性诱饵名 `All()`」是同一条纪律 |

## API 面（契约）

> 总则与共享类型见 `systems/architecture.md`「API 契约总则」。本服务**纯本地**，永不跨进程边界，故**全部方法为形态 A**、不实现 `IBootstrappable`。

| 方法 | 形态 | 完整签名 | 失败语义 |
|------|------|----------|----------|
| 载入 | A | `void Hydrate(PlayerProfile profile)` | `profile == null` = 程序缺陷 → `PushError` + 抛；触发 CapabilityManager 首次聚合 |
| 施加变更 | A | `ApplyResult TryApply(ProfileChangeSpec spec)` | **业务失败** → `ApplyResult.Fail(missingElement)`，全有或全无，绝不抛 |
| 只读投影 | A | `PlayerProfile Project(ProfileChangeSpec spec)` | 施加 spec 得到一份**未提交**的只读视图，供收口前重算新一批；**不提交、不广播、不落存档点** |
| 预校验 | A | `bool CanAfford(ProfileChangeSpec spec)` | 供 UI 灰显 / 预览，**不提交**。**唯一消费点 = Exchange 的商店购买；事件推进路径不调用它**（`selectCost` 无条件施加） |
| 能力查询 | A | `bool Has(CapabilityFlag flag)` | 未授予 = `false`，非错误 |
| 数值修正 | A | `int ApplyModifier(ModifierKey key, int baseValue)` | 无修正 = 原值返回 |
| 开关 | A | `ApplyResult SetPowerStatus(string powerId, bool enabled)` | 未拥有该 power → `ApplyResult.Fail` |
| 授予 / 撤销 | A | `ApplyResult GrantPower(string powerId, Source source)` / `ApplyResult RevokePower(string powerId)` | 同上；**`source` 无默认值**——省略即产生来源未知的条目，而残卷的 `x` 直接读它。**`source` 须落在该条目 `(Kind, Scope)` 的合法子集内且不为 `Unknown`**，否则 `PushError` + 拒绝。见 `systems/common-properties.md` |
| 授予池 · 有无 | A | `bool HasGrantable(AbilityKind kind, AbilityScope scope)` | 池空 = `false`，非错误。**⟺ 残卷全局前置「尚未拥有的法则数 > 0」**（同一个判断，不是两个） |
| 授予池 · 计数 | A | `int GrantableCount(AbilityKind kind, AbilityScope scope)` | 供礼包购买入口判「够不够 2 件」（闸 ②） |
| 付费权益查询 | A | `bool HasPremiumBundle { get; }` | 未购买 = `false`，非错误。`=> Entitlement.BundleGrantOrdinal > 0`，**单点查询、不进任何事件负载**（同 `Has(flag)` / `PendingCount` / `UpgradeRequired` 的纪律）。消费方是 life-cycle-service 的重试上限选行，见 `systems/monetization.md` |
| 授予池 · 抽一条 | A | `bool TryPickGrantable<TRng>(AbilityKind kind, AbilityScope scope, TRng rng, out string pickedId) where TRng : IRandomSource` | **可选缺失**（池空）→ `PushWarning`，由调用方决定降级方式（残卷静默停摆 / 礼包报错不补发） |
| 授予池 · 抽多条 | A | `bool TryPickGrantableMany<TRng>(AbilityKind kind, AbilityScope scope, TRng rng, int count, out IReadOnlyList<string> pickedIds) where TRng : IRandomSource` | 同上，含「不足 count」的部分情形。**无放回**——保证多条互不相同 |
| 置换取池 | A | `bool TryPickReplacement<TRng>(AbilityKind kind, AbilityScope scope, RarityTier anchorRarity, TRng rng, out string pickedId) where TRng : IRandomSource` | **可选缺失**（锚定档后池空）→ `PushWarning`，调用方按「整个置换成为空操作」处置 |
| 消耗账号道具 | A | `ApplyResult ConsumePlayerItem(string itemId, int count = 1)` | 次数不足 → `ApplyResult.Fail` |
| 成就采集 | A | `void ReportProgress(AchievementSignal signal)` | — |
| 只读快照 | A | `PlayerProfile Snapshot { get; }` | **只读视图**（非可变引用），供 sync / ViewModel 组装 |

- **`CostSpec` / `RewardSpec` 已合并为单一 `ProfileChangeSpec`**（`ChangeElement.BaseValue` 带符号：负 = 消耗，正 = 产出）。两个类型会诱导出「先 `TryApply(cost)` 再 `TryApply(reward)`」这种半套写入，与「全有或全无、单点提交」直接冲突。
- **`CanAfford` / `ApplyResult.MissingElement` 保留，`AdvanceStage.CostRejected` 与 `AdvanceResult.MissingElement` 删除——判据是「有无消费点」。** 前两者有一个已定存在的消费点（Exchange 的商店购买），删掉要原样加回来；后两者只服务于事件推进路径，而该路径已定「无条件施加、不做付得起校验」⇒ 成员不可达。留着不只是死代码，它会主动诱导后来者把校验加回来。`MissingElement` 是 `CanAfford` 失败时唯一能告诉 UI「差的是哪一样」的通道。
- **商店可以灰显买不起的商品，事件选择面不可以——判据同为一条：「明知做不到仍然去做」有没有意义。** 事件选择面有意义（明知是死路仍然走，与「打不过也得打」同构，且换来一段终局叙事）；商店里点一件买不起的商品没有任何意义——不产生终态、不产生叙事、不推进任何东西，只产生一次挫败。**写下的是判据而非结论**，否则「事件面不灰显」会被误推广到商店。呈现形态（灰显 / 弹窗 / 价格标注）归 Exchange 专场。
- **`CanAfford` 与 `TryApply` 必须走同一条 modifier pipeline**，否则 UI 显示「买得起」而实际拒绝。二者共用一个内部 `Evaluate(spec)`，`TryApply` = `Evaluate` + 提交。
- **`Snapshot` 返回只读视图**（总则 3）；运行态写入一律经 `TryApply`。
- **四个授予池方法为何落在本服务：** 抽取需要**内容池**（content-service）与**已持有集合**（profile-service）两样东西。后者是本服务的自有状态，前者可经对方服务门面跨服务读取（跨服务方法调用允许，不触及对方 manager 私有字段）；反向（放 content-service）则要求它读 `PlayerProfile`，违反「服务之间不读写对方字段」。它们**纯内存查询、不跨边界，故为形态 A、不带 `Async`**。**随机源以泛型约束 `TRng : IRandomSource` 传入**，使账号级掷骰（`AccountRandom`，契约定义的 SplitMix64）与轮回级抽取（`GodotRandomSource`，子流薄适配）共用同一段取池代码而不装箱；类型定义见 `systems/common-properties.md`。**抽取结果在 spec 组装之前定稿** —— `AbilityChangeElement` 只拿到已定稿的 `Id`，与既定的「随机在 spec 组装前掷完」一致。置换候选池复用同一 picker（只多传一个 `anchorRarity`）⇒ 全库只有一处抽取能力条目的代码。
- **`CapabilityFlag` 是 C# `enum` 而非字符串 key**：flag 的消费点必然是一段 UI 代码，新增 flag 本就要写消费代码；字符串只是把「拼错了」从编译期推迟到运行时。可加的是 `.tres` 里**谁授予哪个已定义的 flag**。

**事件面：**

| 事件 | 负载 |
|------|------|
| `CapabilitiesChanged` | **空负载**——订阅者收到后自行 `ProfileService.Instance.Has(flag)` 重查（既定的「一个 flag ↔ 一处消费点 · 单点查询」；把生效集塞进负载反而制造第二份真值） |
| `AchievementTierReached` | `(string GroupId, int TierPercent)` |

Source: `handoffs/2026-07-27b-service-api-contracts.md` · `handoffs/2026-08-12b-grant-source-per-kind-scope.md` · `handoffs/2026-08-12e-ability-grant-draw-pool.md` · `handoffs/2026-08-16b-cross-library-alignment-and-bridge-ledger.md` · `handoffs/2026-08-16d-cost-side-closure.md` · `handoffs/2026-08-16f-elements-modifier-pipeline-opt-in.md`

## 与其他服务的关系

- **上游写入方：** `life-cycle-service`（轮回状态与隐藏属性）、`combat-service`（战斗内的 life / deck / 道具变更）、`future-event-service`（key points 推进）——**都只经 ProfileManager 写**。
- **下游：** `sync-service` 负责把变更后的聚合持久化 / 上行；本服务不做 I/O。
- **内容查找：** 一切 `Id` → 内容的解析经 `content-service.ContentRegistry`。

## 决策(-> ADR)

- **capability flag（布尔）+ modifier pipeline（数值）两条通道** → **ADR 候选**（待固化）。
- **单一 profile-service 拥有两层 profile、ProfileManager 为唯一写入面** → **ADR 候选**（待固化）。

Source: `handoffs/2026-07-25b-event-cost-fields-capability-flags-and-service-hierarchy.md` · `handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md`
- **强制在线 · 云端权威** → `decisions/ADR-0003-online-cloud-authority.md`（Accepted）。

## 待决问题

- **cost element 清单未定（资源族；能力族与统计族已闭合）。** `TryApply` 的形状取决于它：**资源族**有哪些 element（jade / mana / 道具 / 隐藏属性推拉？）、各自数据形态（固定值 / 区间 / 公式）仍未定。**能力族已闭合**（`AbilityChangeElement`，三个 Op），**统计族已闭合**（`StatDelta`）；剩下的只有 `StatKey` 随统计项增长的成员清单（见下条）。→ `systems/adventure-event/common-properties.md`。
- **`StatKey` 的完整成员清单未定（轻）。** 首批两项（`CyclesCompleted` / `CyclesDefeated`）已定；随统计项增长的命名与登记方式、以及如何在书写上与 `CostKey` 明确分开未定。→ `systems/player-profile/_index.md`。
- **capability flag 的枚举与命名空间；叠加 / 冲突规则。** 两个 power 授予同一 flag 如何处理；多个 modifier 作用于同一 key 时的**运算顺序**（加法先于乘法？声明序？优先级字段？）未定。→ `systems/player-profile/player-power/common-properties.md`。
- **`status` 与「拥有 / 失去」两态的存档表达。** 两个正交维度如何编码进 schema 未定。
- **AchievementManager 的触发采集面。** 成就进度靠订阅 EventBus **被动采集**（解耦但易漏），还是由各服务**主动上报**（可靠但反向依赖）？
- **成就两档奖励内容。** 阈值 60% / 90%、一次性、目录 80% 可见已定；**各档发放何种奖励**待定。→ `ux/screen-flow.md`。
- **元进程字段结构。** `Achievement` 条目 schema 与 `GameSetting` 的设置项清单未定；各账号级条目的解锁 / 获取 / 失去的具体触发未定。（`PlayerPower` / `PlayerItem` 的持有条目形态与 `AccountInfo` 已定，见 `systems/player-profile/_index.md`。）→ `systems/player-profile/`。
- **只读投影 `Project(spec)` 的语义面未定。** 它与 `Evaluate(spec)` 能否复用同一段施加代码、投影是否同样做钳制与终态判定（若做，一份「已判负」的投影交给重算方意味着什么）、以及投影视图的生命周期（一次性值还是可缓存）均未定。→ 本文档、`systems/services/life-cycle-service.md`。
- **`activeCombat` 的写入通道未明写（承重）。** `activeEvent` 已定走 `EventStateChanges`，形态相同的 `activeCombat` 仍来路不明 ⇒ 两套写入纪律的风险。现成方案是把它收进同一列，范围落在战斗存档段。→ `systems/services/combat-service.md`、本文档。
- **RNG 状态的写入通道形态未定。** 已落「凡消耗了子流随机的提交，该子流 `State` / `DrawCount` 必须在同一次原子写内更新」这条不变式，但 `Rng` 块目前没有任何 spec 列可落 ⇒ 不变式暂无机械保证。是否纳入 `EventStateChanges` 或另开一列，牵动 `activeCombat` 与四条子流的全部写入点。→ `systems/services/life-cycle-service.md`、本文档。
- **`pastEvent` 的追加同样没有 spec 列。** 本文档明写「`pastEvent` 写入经 life-cycle-service 组装 → `ProfileManager`」，但各列里没有一列装得下 `PastEventEntry`，而结算流程把「记入 pastEvent」画在收口那次 `TryApply` 之外。→ 本文档、`systems/adventure-event/common-properties.md`。
- **PlayerPower 的平衡边界。** 方向已定为「轻度提升、PvE-only 可容忍」；是否影响 cycle seed / 计分公平仍待定。

Source: `handoffs/2026-08-06c-skip-channel-removal-priority-two-tier-and-location-codex-edges.md` · `handoffs/2026-08-10c-ability-disable-replacement-and-player-statistics.md` · `handoffs/2026-08-15b-monetization-entitlement-purchase-shape-and-scope.md` · `handoffs/2026-08-16d-cost-side-closure.md` · `handoffs/2026-08-16f-elements-modifier-pipeline-opt-in.md` · `handoffs/2026-08-17d-exchange-mechanics-and-transaction-discipline.md`

## 对应
提炼至：`.claude/knowledge/systems/profile-service.md`（引用层，待建）。
