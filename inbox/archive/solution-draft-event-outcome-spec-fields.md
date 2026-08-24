---
type: solution-draft
date: 2026-08-22
question: `EventOutcomeSpec` 的内部字段面——产出效果原语的表达、`OnResolved` / `OnFailure` 两侧各自的列、经验失败折算的数据形态
source: open-questions/02-event-options.md → 「`EventOutcomeSpec` 的内部字段面（08-17 新增 · 承重）」
targets: systems/services/future-event-service.md · systems/adventure-event/common-properties.md · systems/architecture.md（共享核心类型）· systems/adventure-event/explore/_index.md · systems/services/profile-service.md
status: distilled
reviewed: 2026-08-22 — 4 项取向全部裁决；合并 interview 另裁定承重句不写列数 + 补齐 architecture 的 CodexElements · 经验/隐藏属性三个 key 排除出 OutcomeRule 白名单 · ManaLimit 幅度恒 1 · 事件产出不得给账号级古宝（正向白名单收窄）· 置换/禁用候选前移到物化时掷定并落 EventOption.AbilityChangeSlots（非 OutcomeRule 第四个 Kind）。**待复核 2 项**：GrantFromPool 不加池断言 · OutcomeRule 不支持多选一
confirmed: 2026-08-22 —— 全部 [采纳推荐 — 待复核] 项经批量评审确认，无推翻
distilled-to: handoffs/2026-08-22-event-outcome-spec-fields.md
---

# 方案草稿 — `EventOutcomeSpec` 的内部字段面

## 问题

`EventOption.OutcomeSpec`（类型 `EventOutcomeSpec`）已定三件事：**载体存在于 `EventOption` 上**、**固化时点**（抽取在物化时掷定 / 条件在结算时求值）、**顶层按结算走向分侧**（`OnResolved` / `OnFailure`，映射表已明写）。仍悬着的是它**内部长什么样**：

1. 产出「效果原语」用什么表达；
2. 两侧各自允许出现哪些列 / 哪些 key；
3. 经验的失败折算落成什么数据形态。

它卡住的是四个非战斗事件子类型的产出面——`GenericEventResolver` 明写「读物化后 `EventOption` 上的定稿 `OutcomeSpec`」，而这份 spec 里有什么至今没有定义。

### ⚠ 先核实阻塞来源（清单点名要求的一步）

清单登记本条「阻于效果关键字体系与目标规则」，并注明该前置已于 08-16c 收口。**核实结论：阻塞已解除，而且这条登记从一开始就挂错了对象——两者的作用面不相交。**

| | 08-16c 收口的那一套 | 本条要的那一套 |
|---|---|---|
| 载体 | `EffectData`（第一层原子操作）· `KeywordData` · `TargetSlot` / `EffectScope` / `EntryFilter` | `ProfileChangeSpec` 的各列 element |
| 作用对象 | 战场条目 · 手牌 `CardInstance` · 参战方的道念 / mana | `CharacterProfile` / `PlayerProfile` 的字段 |
| 施加通道 | 战斗内求值管线 + BattlefieldManager | `ProfileManager.TryApply`（唯一写入面） |
| 寿命 | 一场战斗 | 跨事件持久 |

`EffectData` 的七个原子操作（`ModifyMomentum` · `Draw` · `Discard` · `ModifyMana` · `ApplyState` · `RemoveEntry` · `MoveCard`，见 `systems/character-profile/deck/_index.md`）**没有一个写 Profile**；`TargetSlot` / `EntryFilter` 锚定的是战场条目与手牌，而一个事件产出里根本没有战场。反向也成立：`ProfileChangeSpec` 的 12 列在 08-19（`RngElements` / `TraceElements` / `SettingChanges` / `CodexElements` 补齐）之后已全部落定，本条所需的施加语义**没有一格缺口**。

**⇒ 本条只欠自身落笔，可单独成场。** 建议在移出待答项时把这处误挂如实记进 answer-log：根因是本库「效果」一词有两个所指（战斗效果原语 vs 事件产出 element）。**连带建议一条术语纪律**：本条落笔时把「产出效果原语」正名为**「产出 element」**，与 `OutcomeSpec` 不叫 `Outcome` 的既有防混淆理由同源。

## 约束（来自既有设计）

- **顶层四件已定，本方案不得改动**：载体在 `EventOption` 上 · 抽取物化时掷定 / 条件结算时求值 · 顶层分 `OnResolved` / `OnFailure` · 走向映射表（`Resolved` / `CombatWon` / `Draw` → `OnResolved`；`CombatLost` → `OnFailure`；`Aborted` → 两侧皆不施加）。→ `systems/services/future-event-service.md`
- **`OutcomeSpec != null` 是物化后断言**；无产出的事件用**空 spec** 表达，不用 `null`。→ 同上
- **Combat 类的产出边界**：`OutcomeSpec` 只装隐藏属性推拉 + 经验档 + 事件级产出；**战利品恒不进**（出自 `CombatResult.Spoils`，记 `Source.CombatReward`）；失败侧按道念差扣 `lifeTotal` 由 combat-service 算出、不进 `OutcomeSpec`。→ 同上、`systems/services/life-cycle-service.md`
- **一切 Profile 写入经 `ProfileManager.TryApply(ProfileChangeSpec)`**，12 列已定，`ChangeElement.BaseValue` 带符号（负 = 消耗，正 = 产出）。→ `systems/services/profile-service.md`
- **`SelectCost` 的三条不变式是本条的形态先例**：`AbilityElements` 恒空 · `DeckElements` 恒空 · `Elements` 中 `LifeSpan` 取值域收紧为 ≤ 0。每条各落一处**物化组装后断言** + 一处**内容模板加载期校验**，一律 `PushError`。→ `systems/adventure-event/common-properties.md`
- **授予来源的分野判据 = 谁组装出这条 element**：通用结算器从 outcome 定义算出的授予一律记 `Source.EventOutcome`；`(Power, Player) × EventOutcome` 在合法子集表里是 ❌。→ `systems/common-properties.md`
- **element 只承载已定稿的 `Id`**：随机性在 spec 组装之前掷完，否则 `AppliedChange` 不可重放。→ `systems/services/profile-service.md`
- **经验模型已定**：`ExperienceGrade { None / Minor 0.5× / Standard 1.0× / Major 1.5× }` 枚举 + 平衡表映射，内容侧不落裸数字；**失败 = 同档 50%（`FailureRatio` 默认 0.5，逐条可覆写），向下取整、下限 1；折算在 `ProfileChangeSpec` 组装时完成**。→ `systems/game-progression.md`、`systems/balance.md`
- **隐藏属性推拉 = 一份 `HiddenStatGrade`，胜负同施、不套用 `FailureRatio`**；`Finale` 胜负同推道心。→ `systems/adventure-event/common-properties.md`、`systems/adventure-event/combat/_index.md`
- **寿元回复只走 outcome 侧**；`eventType == Travel` 的条目其 outcome 侧**不得含 `LifeSpan` 产出**（加载期 `PushError`）。→ `systems/adventure-event/common-properties.md`、`travel/_index.md`
- **取池短缺的分界判据**：付过钱的产出少给即事故（前移失败点）；没付钱的玩法内容降级到更少是可接受方差。→ `systems/services/future-event-service.md`
- **三级判据**（分列 / 加 `Op` / 配表加列）约束一切「新语义落在哪」的问题。→ `systems/architecture.md`

## 建议方案

### ① 侧的载体类型 = 复用 `ProfileChangeSpec`，不新建窄类型

`[既有推演]`

```csharp
public sealed record EventOutcomeSpec(
    ProfileChangeSpec OnResolved,     // 恒非 null；无产出时为空 spec
    ProfileChangeSpec OnFailure);     // 同上
```

三条依据全部来自既有形状：

- **「成本与产出共用一个类型」是明写定案**（`CostSpec` / `RewardSpec` 合并为单一 `ProfileChangeSpec` 的那条），产出侧另造一个窄类型等于把刚合并掉的东西重新分叉。
- **`eventEnd` 的合并零转换**：五步组装的第 ① 步本就是把各列拼进收口 spec，选中一侧后直接 `Concat` 即可，不需要一层 element 翻译。
- **`SelectCost` 已经示范了「复用宽类型 + 恒空列断言」这套纪律**，本条照抄，读者不需要学第二套。

**代价明写**：`ProfileChangeSpec` 的 12 列里有 9 列在 outcome 侧恒空，需要 9 条断言（见下 ②）。这与 `SelectCost` 侧已有的 7 条同款、同处、同档。

### ② 两侧各自的列 = 三列开放、九列恒空

`[既有推演]`

**判据一句（写判据而非清单）：内容作者能如实声明的量才进 `OutcomeSpec`；由服务算出绝对值、或由代码采集的，一律不进。**

| `ProfileChangeSpec` 列 | outcome 侧 | 依据 |
|---|---|---|
| `Elements`（资源） | ✅ | 经验 / 寿元回复 / `lifeTotal` / `manaLimit` / 隐藏属性 / 灵玉全部走它；取值域另收紧，见 ③ |
| `AbilityElements`（能力） | ✅ | 置换型剥夺 · 三档禁用 · 授予法宝 / 神通**只能出现在 outcome 侧**（`SelectCost` 恒空那条的对偶）；`Source` 恒为 `EventOutcome` |
| `DeckElements`（卡组） | ✅ | Research 六类操作的四类落它；业障入组走 `AddLooseCard`。同为「`SelectCost` 恒空、只能在 outcome 侧」 |
| `Stats`（统计计数） | ❌ | 统计由各消费点代码采集（轮回结束 `+1` 等），内容侧声明它等于让一个 `.tres` 伪造统计数字 |
| `StatusChanges`（Status 规则字段） | ❌ | 三个 band 与两个 location 字段由 life-cycle-service **算出绝对值**后置入（band 要读前值 + 回滞，location 读 `DestinationLocationId`）；内容侧写不出绝对值 |
| `PlotElements`（剧本） | ❌ | 推进逻辑归 PlotManager 独占；内容条目直接推进剧本 = 绕过「剧本要表达强制性只能靠收窄候选池」这条边界 |
| `EventStateChanges`（事件态） | ❌ | 整块中间态，由 life-cycle-service / combat-service 组装；且 `AppliedChange` 累加时本就要剔除它 |
| `RngElements`（RNG 子流） | ❌ | 唯一组装路径是 `SeedManager.AttachRngState(spec)` |
| `TraceElements`（履历） | ❌ | 一次事件恰一条痕迹，由 life-cycle-service 组装；内容侧写它即自指 |
| `SettingChanges`（账号级设置） | ❌ | 设置只在设置屏发起，永不发生在事件结算里（既有明写） |
| `CodexElements`（图鉴解锁） | ❌ | 触发采集与去重归 `CodexManager`；内容侧声明会与 `CodexManager` 的组装打架，`AppliedChange` 记的账与提交的 spec 不一致 |

**落地**：9 条恒空断言合为**一段** Explore / Outcome 校验段（避免散落），两处各跑一遍——**内容模板加载期**（对模板的产出格）与**物化组装后**（对定稿实例），一律 `PushError` + `EventId`。

### ③ `Elements` 内的 key 取值域收紧（第四条不变式）

`[既有推演]`

`Elements` 开放不等于 15 个 `CostKey` 全开。按「谁组装出这条 element」逐条判：

| `CostKey` | outcome 侧 | 说明 |
|---|---|---|
| `ExperiencePoint` · `LifeTotal` · `ManaLimit` · `Faith` · `Bloodlust` · `Jade` | ✅ | 事件产出的常规面 |
| `LifeSpan` | ✅（**仅正向**） | 回寿通道 A；成本侧恒 ≤ 0、产出侧恒 ≥ 0。**`eventType == Travel` 的条目该 key 恒不得出现**（既有结构性禁令） |
| `PowerFragmentAccumulated` · `PowerFragmentFinaleWinOrdinal` · `PowerFragmentCh1/2/3FirstWinDone` · `PowerFragmentLastRoll` · `PowerFragmentLastEffectiveChance` | ❌ | 道统残卷七格由 life-cycle-service 在 Finale 收口时组装（含账号级 RNG 掷骰与幂等键），内容条目声明它 = 一个 `.tres` 能伪造发放记录 |
| `BundleRedeemedOrdinal` | ❌ | 付费兑现水位；`BundleGrantOrdinal` 更是后端独占 |

**两条附加断言**（同段、同档）：`Op` 必须落在该 key 的 `AllowedOps` 内（既有入口校验的前移）；`AbilityElements` 中 `Op == Grant` 的 `Source` 必须是 `EventOutcome`，`(Power, Player)` 组合直接 `PushError`（合法子集表现成）。

### ④ 隐藏属性推拉：两侧各存一份已算好的 element，不加第三格

`[取向选择]` —— 见「仍需用户决定」第 1 项，推荐**不加第三格**。

「胜负同施一份 `HiddenStatGrade`」意味着 `OnResolved` 与 `OnFailure` 会各带一份**内容完全相同**的道心 / 煞气 element。看起来冗余，但：

- 两侧的 element 由**物化时的同一段组装代码**从模板上**同一个** `HiddenStatGrants` 字段展开，不存在两处真值、不会漂移；
- 加一格 `Always` 会把顶层从「两侧」变成「三格」，**走向映射表要重写**，而 `Aborted` 那一行（两侧皆不施加）立刻要回答「`Always` 施不施加」——那正是本条最不该新开的分叉；
- 冗余的实际体积 = 每侧至多 2 条 element（道心 + 煞气），可忽略。

### ⑤ 经验失败折算：折算在物化组装时完成，`FailureRatio` 不进 `EventOutcomeSpec`

`[既有推演]`

```
物化时：
  base   = ExperienceGradeTable[chapter][ExperienceGrade]          // 平衡表映射，已含篇章放大
  OnResolved.Elements += ChangeElement(ExperiencePoint, +base, Add)
  fail   = max(1, floor(base × FailureRatio))                       // 下限 1；base == 0 时不产出该 element
  OnFailure.Elements  += ChangeElement(ExperiencePoint, +fail, Add)
```

- **`FailureRatio` 留在 `AdventureEventData` 模板侧**（默认 50，逐条可覆写），**不出现在定稿实例上**——「折算在 `ProfileChangeSpec` 组装时完成、`TryApply` 收到的已是最终整数」是既有明写。
- 它同时兑现三条既有纪律：**结算时只选一侧、不掷骰也不算数** · **element 只承载已定稿的量** · **`AppliedChange` 可直接重放**。
- **`ExperienceGrade == None` 时两侧都不产出该 element**（而不是产出一条 `+0`），与「无产出用空 spec 不用 `null`」同向：不产生无消费方的空条目。

### ⑥ 模板侧的参数空间 = 五格，形状照抄两处既有范式

`[既有推演]` + `[通行做法]`

`AdventureEventData` 上的产出格（`eventType` 不限；Travel 另受 `LifeSpan` 禁令约束）：

```csharp
[Export] public ExperienceGrade   ExperienceGrade   { get; set; } = ExperienceGrade.None;
[Export] public int               FailureRatio      { get; set; } = 50;   // 百分比整数，不用 float
[Export] public HiddenStatGrant[] HiddenStatGrants  { get; set; }         // (HiddenStat, HiddenStatGrade)；胜负同施
[Export] public OutcomeRule[]     OnResolvedRules   { get; set; }
[Export] public OutcomeRule[]     OnFailureRules    { get; set; }
```

`OutcomeRule` 的形状**照抄 `ExchangeStockRule` / `ResearchSlotSpec` 已有的「规则 → 物化展开」范式**，不发明第三种：

```csharp
[GlobalClass] public partial class OutcomeRule : Resource
{
    [Export] public OutcomeRuleKind   Kind;          // FixedResource | GrantFromPool | DeckOperation
    // Kind == FixedResource
    [Export] public CostKey           ResourceKey;
    [Export] public int               Magnitude;     // 正数量值（与 lifeSpanCost 同一条书写约定）
    [Export] public OutcomeDirection  Direction;     // Gain | Loss —— 取负发生在物化组装，与 SelectCost 同处
    // Kind == GrantFromPool
    [Export] public ExchangeGoodsKind PoolKind;      // 复用既有五值族，不新建枚举
    [Export] public RarityTier[]      RarityFilter;  // 空 = 不限
    [Export] public int               Count = 1;
    // Kind == DeckOperation
    [Export] public DeckOperationKind DeckOp;        // 复用面板层六值枚举
    [Export] public string            TargetId;      // 定值条目；空 = 从 PoolKind 抽
}
```

- **抽取走既有两级取池链，零新增抽取代码**：能力族 `profile-service.TryPickGrantableMany(kind, scope, rng, n)`，内容族 `DrawPool<T>`；随机源 **`RngStream.Reward` 子流，不新开**（与 Research 候选、战后奖励候选完全同构，且三者从不并发）。
- **`FailureRatio` 用百分比整数不用 `float`**：`AppliedChange` 要求可重放，整数百分比 + `floor` 是可复算的；浮点在跨平台重放上不是。
- **短缺处置按分界判据自动落定**：事件产出没付过钱 ⇒ **降级到更少 + `PushWarning`（want / got）**，不拒绝、不拦事件。**不为它新增闸 ①（加载期池断言）**——闸 ① 存在的理由是「不能留空面板」，而事件产出不是面板，少发一件不产生死屏。（这一条请见「仍需用户决定」第 3 项，它有一个反方向的考量。）
- **日志**：`[FutureEvent-Outcome] instance=<InstanceId> event=<EventId> side=<Resolved|Failure> rule=<Kind> want=<n> got=<m>`。

### ⑦ Explore 壳的 `OutcomeSpec` 取真身模板物化（承重）

`[取向选择]` —— 见「仍需用户决定」第 2 项，推荐**取真身**。

这是本次落笔逼出来的一个此前没有答案的洞：`GenericEventResolver` 读 `activeEvent.Option.OutcomeSpec`，而 Explore 壳实例的 `OutcomeSpec` 是由**谁的模板**物化的？两条既有纪律指向相反方向：

| 既有处置 | 取哪一侧 | 理由 |
|---|---|---|
| `SelectCost` | **壳自己** | 支付先于揭示；且取真身会让成本数值成为真身类型的指纹（Band 2 精确展示） |
| `DestinationLocationId` · `Encounter` | **真身** | 防重掷——真身的物化产物必须在物化那一刻就填好壳实例 |

**推荐取真身**，与 `Encounter` / `DestinationLocationId` 同构。理由：① 产出在揭示前**从不展示**（遮罩态卡面只取 Explore 模板的文案与图标），故不存在成本侧那条泄漏面，成本的对称性理由在产出侧不成立；② 取壳的话，一个「秘境里的商店」除了买卖之外拿不到真身条目写好的任何 outcome，真身模板的产出格在被遮罩时整条失效——而同一条目作为普通选项出现时它是生效的，同一份数据两种行为；③ 防重掷要求一致：抽取型产出（`GrantFromPool`）若等到揭示后再掷，退出重进即可重刷。

**落地**：Explore 校验段加一条断言——壳实例的 `OutcomeSpec` 由 `RevealedEventId` 指向的模板物化，且物化时**不读真身的任何成本字段**（与既有那条断言并列）。

## 具体形态（可 derive 的落地面）

**定稿实例侧**

```csharp
public sealed record EventOutcomeSpec(
    ProfileChangeSpec OnResolved,
    ProfileChangeSpec OnFailure);
// EventOption.OutcomeSpec : EventOutcomeSpec —— 恒非 null（既有断言）
// 两侧各自：Elements / AbilityElements / DeckElements 三列开放，其余九列恒空
```

**物化组装后的断言清单（`PushError` + `EventId` + `InstanceId`）**

| # | 断言 |
|---|---|
| 1 | `OutcomeSpec != null`（既有，保留） |
| 2 | 两侧的 `Stats` / `StatusChanges` / `PlotElements` / `EventStateChanges` / `RngElements` / `TraceElements` / `SettingChanges` / `CodexElements` 八列恒空 |
| 3 | 两侧 `Elements` 中不得出现 `PowerFragment*` 七 key 与 `BundleRedeemedOrdinal` |
| 4 | 两侧 `Elements` 中 `Key == LifeSpan` 时 `BaseValue >= 0`（成本侧那条的镜像） |
| 5 | `eventType`（真身口径）`== Travel` 时两侧不得出现 `Key == LifeSpan`（既有禁令的物化侧对偶） |
| 6 | `AbilityElements` 中 `Op == Grant` 的 `Source == EventOutcome`，且 `(Kind, Scope) != (Power, Player)` |
| 7 | 每条 `ChangeElement.Op ∈ ResourceElements[Key].AllowedOps` |
| 8 | Explore 壳：`OutcomeSpec` 由 `RevealedEventId` 的模板物化（见 ⑦） |

**内容模板加载期校验（`PushError` + 条目 `Id`）**

| # | 校验 |
|---|---|
| 1 | `FailureRatio ∈ [0, 100]` |
| 2 | `OutcomeRule.Kind == FixedResource` 时 `ResourceKey` 落在 ③ 的白名单内、`Magnitude >= 0` |
| 3 | `Kind == GrantFromPool` 时 `PoolKind` 非空且 `Count >= 1`；`PoolKind` 映射到 `(Power, Player)` 时直接拒绝 |
| 4 | `Kind == DeckOperation` 且 `TargetId` 非空时须经 `ContentRegistry` 解析 |
| 5 | `eventType == Travel` 的条目两侧规则不得出现 `ResourceKey == LifeSpan` 且 `Direction == Gain`（既有禁令的模板侧落点） |
| 6 | `HiddenStatGrants` 内同一 `HiddenStat` 出现两条 → 拒绝（两条同属性的档位值互相覆盖，作者自己也不知道该落哪份） |

**快照侧：零增量。** `PastEventEntry` 不新增字段——本次掷定的结果已经在 `AppliedChange` 里，模板上的 outcome 定义按既有判据不进快照。

## 后果

- **改动面**：`systems/services/future-event-service.md`（`EventOutcomeSpec` 定义 + 断言清单 + 日志）· `systems/adventure-event/common-properties.md`（模板侧产出格 + 第四条不变式）· `systems/architecture.md`「共享核心类型」（`EventOutcomeSpec` / `OutcomeRule` / `OutcomeRuleKind` / `OutcomeDirection` / `HiddenStatGrant`）· `systems/adventure-event/explore/_index.md`（⑦ 的断言）· `systems/services/profile-service.md`（`SelectCost` 侧不变式表加一行 outcome 侧镜像）。
- **存档 schema**：`EventOption` 的 `OutcomeSpec` 一格**本就在字段表里**，本条只填它的内部 ⇒ 若与其余待落项同批 bump 即可（当前无线上存档 = 空迁移）。
- **`ProfileChangeSpec` 一列不动、一个 `Op` 不加**——按三级判据核对：outcome 侧的施加语义与既有各列逐面对齐，无一处需要分列。
- **解锁面**：本条落定后，`GenericEventResolver` 的实现面闭合，四个非战斗子类型的产出侧从 blocked 变为可 derive 的候选（`future-event-service` 仍另卡在生成 / 加权那条 🔴 上）。

## 备选方案（已考虑并否决）

- **窄类型 `EventOutcomeSide(Elements, AbilityElements, DeckElements)`** —— 类型说实话、免去 9 条断言；否决理由：与「成本与产出共用一个类型」正面相反，且 `eventEnd` 合并时要写一层 element 翻译，翻译层是新的漂移点。
- **顶层三格 `OnResolved` / `OnFailure` / `Always`** —— 消掉隐藏属性推拉的重复；否决理由见 ④（映射表重写 + `Aborted` 语义分叉）。
- **把 `FailureRatio` 落进定稿实例、结算时再折算** —— 否决：违「结算时只选一侧、不掷骰」，且让 `AppliedChange` 的重放依赖一次浮点运算。
- **为 outcome 的 `GrantFromPool` 新开一条抽取链 / 一条子流** —— 否决：`Reward` 子流已承载三个完全同构的用途，新开子流换来零隔离收益（与 Research 候选那条逐字同理）。
- **通用表达式 / 条件树式的 outcome 定义**（「若道心 > 60 则 A 否则 B」）—— 否决：与 08-16c 否决通用表达式同一条理由（需要求值器与沙箱），且「条件在结算时求值」已明写只覆盖**结算走向**这一个分支轴，读隐藏属性当前值只作为输入项、不作为分支器。

## 与既有决策的张力

**一处，在 ⑦。** `SelectCost` 明写「遮罩下只存在 Explore 壳自己的那一份，不读真身任何成本字段」；本方案建议产出侧**相反**地取真身。两者并非矛盾，但**必须在文档里把这条不对称写明并给出理由**（成本侧的对称性服务于防泄漏，产出侧无泄漏面），否则后来者读到两条相反的处置会去「统一」其中一条——统一到哪一侧都会造成实际损坏（统一取壳 ⇒ 真身产出整条失效；统一取真身 ⇒ 成本数值成为真身指纹）。

其余各项均未与既有决策冲突。

## 前置依赖

- **`ExperienceGrade` / `HiddenStatGrade` 的映射值**归 ch1 数值标杆专场 —— **不阻塞本条**（本条定的是结构与取值域，不是数值）。
- **「隐藏属性的增减触发」**（哪些事件推哪一档）是内容编排口径 —— **不阻塞本条**（本条只定 `HiddenStatGrants` 这一格的形状）。
- **`ExchangeGoodsKind` 与 `DeckOperationKind` 两个枚举**已定，本条直接复用，无依赖。
- **`future-event-service` 的生成 / 加权运算形态**（🔴）**不阻塞本条**——物化的抽取链与批次加权是两回事。

## 仍需用户决定 → **已全部裁决（2026-08-22 · 批量评审）**

> 逐条裁决（`/batch-provide-solution-draft` 合并 interview）：
> 1. 隐藏属性推拉：两侧各存一份 vs 顶层 `Always` → **已裁决：A · 两侧各展开一份**
> 2. Explore 壳的 `OutcomeSpec` 取壳模板还是真身模板 → **已裁决：A · 取真身模板**（须在文档写明「成本取壳、产出取真身」这条不对称及其理由，见「与既有决策的张力」）
> 3. `GrantFromPool` 型产出要不要加载期池断言 → **A · 不加** `[已确认 2026-08-22 · 批量评审]`（短缺时物化期降级 + `PushWarning`）
> 4. `OutcomeRule` 是否支持多选一 / 加权掷一条 → **A · 不支持** `[已确认 2026-08-22 · 批量评审]`（一条规则一条产出）
>
> **全部待复核项已于 2026-08-22 经批量评审逐项确认，本草稿再无待复核项。**


1. **隐藏属性推拉：两侧各存一份，还是顶层加第三格 `Always`？**
   - **选项 A（推荐）**：两侧各展开一份相同 element。后果：`OnResolved` / `OnFailure` 各多 0–2 条 element；走向映射表一字不改；`Aborted` 两侧皆不施加原样成立。
   - **选项 B**：顶层加 `Always : ProfileChangeSpec`。后果：消掉重复，但映射表要重写为三列，且必须新答「`Aborted` 时 `Always` 施不施加」——两种答案各有一串后果（施加 ⇒ 一个短路的事件仍然改隐藏属性；不施加 ⇒ `Always` 名不副实）。
   - **理由**：重复由同一段组装代码从同一个模板字段展开，不构成第二真值；而 B 用一次结构改动换一处零漂移风险的冗余，还附带一个新分叉。

2. **Explore 壳的 `OutcomeSpec` 取壳模板还是真身模板物化？**（承重 —— 此前无答案）
   - **选项 A（推荐）**：取**真身**模板物化，与 `Encounter` / `DestinationLocationId` 同构。后果：真身条目的产出格在遮罩路径与普通路径下行为一致；Explore 校验段加一条断言；须在文档写明「成本取壳、产出取真身」这条不对称及其理由。
   - **选项 B**：取**壳**模板，与 `SelectCost` 完全对称。后果：处置整齐、无需解释不对称；但真身条目的 outcome 格在被遮罩时整条失效（同一份数据两种行为），且 Explore 壳条目要为三类真身各自编排一套产出，内容量与作者心智成本上升。
   - **理由**：成本侧取壳的**唯一**理由是 Band 2 精确展示会泄漏真身类型；产出在揭示前从不展示，该理由整条不成立，而防重掷的理由在产出侧成立且已由 `Encounter` 立过先例。

3. **`GrantFromPool` 型产出要不要一条加载期池断言（闸 ①）？**
   - **选项 A（推荐）**：**不加**。后果：短缺时按分界判据降级 + `PushWarning`，运营上要靠日志发现「某事件长期发不出东西」。
   - **选项 B**：加，比照 Research / Exchange 的闸 ①（池条目数 ≥ `Count` + 余量）。后果：编排错误在启动期大声失败；代价是要为它定义第三个余量常量（`OutcomePoolMargin`），且 `AdventureEventData` 的产出格数量远多于 Research 槽与 Exchange 规则，全量核算会拉长启动期校验。
   - **理由**：闸 ① 的存在理由是「不能留空面板」，而事件产出不是面板——少发一件不产生死屏、不卡玩家；这与「付过钱的产出少给即事故 / 没付钱的降级是可接受方差」这条分界判据一致。**但若用户认为「一个永远发不出奖励的事件条目」属于必须启动期拦下的编排错误，B 也自洽**，故留给裁决。

4. **`OutcomeRule` 是否要支持「多选一 / 加权掷一条」**（例：「随机获得下列三者之一」）？
   - **选项 A（推荐）**：**不支持**，一条规则一条产出；「随机三选一」由 `GrantFromPool` + `RarityFilter` 表达。后果：结构最小；表达「A 或 B 或 C」这种**具名的**互斥产出要拆成三个内容条目。
   - **选项 B**：给 `OutcomeRule[]` 加一层 `WeightedGroup`。后果：表达力上去了，但它是「参数空间」向「小型脚本语言」滑的第一步，与 08-16c 否决通用表达式同一条滑坡。
   - **理由**：本库对这类口子的一贯收口方式是不给；且真需要时补一个字段是纯加法，而先做再退回要改存档结构（与「一槽位 = 一个目标、不做 `TargetCount`」逐字同理）。
