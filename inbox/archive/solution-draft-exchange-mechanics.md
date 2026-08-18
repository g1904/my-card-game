---
type: solution-draft
date: 2026-08-17
question: Exchange 类 AdventureEvent 的通用结算器数据形态（库存生成 / 定价 / 折扣 / 刷新 / 售出）、NPC 与势力是否仍需数据模型、道具定义与交易机制的切分、以及 `Jade` 的 `CostModifier` 取值
source: open-questions/03-adventure-event-types.md → 逐类型 AdventureEvent 机制（Exchange 相关四条）
targets: systems/adventure-event/exchange/_index.md · systems/adventure-event/exchange/common-properties.md · systems/services/profile-service.md · systems/services/future-event-service.md · systems/player-profile/player-item/_index.md · systems/character-profile/currency.md · systems/balance.md · systems/services/plot-manager.md · ux/screen-flow.md
status: distilled
decided-on: 2026-08-17
reviewed: 2026-08-17 — 三项取向裁决：仅 `CharacterItem` 可售出（推翻原推荐「完全不开放」）· reroll 机制落地但首批内容默认关闭 · jade 不铺开买账号级古宝（合法子集表不动）。两条全局纪律的改写一并获准：事务纪律改为「一个事件的收口是一次事务、一个存档点；事件内部的主动消费即时提交」（适用面不限 Exchange）· `PastEventEntry.AppliedChange` 放宽为「本次事件的最终账」（代价须一并落笔）。两项轻量确认：新增 `Source.ExchangeSell` · 槽位总数上界 ≤ 8。
distilled-to: handoffs/2026-08-17d-exchange-mechanics-and-transaction-discipline.md
---

> **本草稿已裁决（2026-08-17）。** 三项取向的定案见「## 定案」一节——其中**售出**一项推翻了原推荐（改为「仅 `CharacterItem` 可售出」），E 节已按定案改写。**张力 ① ②（两条全局纪律的措辞）也已裁决通过**，见文末「## 两条全局纪律的改写」。

# 方案草稿 — Exchange 类 AdventureEvent 的通用结算器与交易机制

## 问题

`open-questions/03-adventure-event-types.md` 里属 Exchange 的四条待答项互相咬合，必须一起答：

1. **Exchange 通用结算器的数据形态** —— 库存生成、定价 / 折扣、刷新、售出。Exchange 是五类中唯一一类「一次事件内玩家要做**多次**主动消费」的类型，而既定的结算流程（`AdvanceEventAsync` 的 `eventStart` → resolver → `eventEnd` 一次合并 `TryApply`）是按「一个事件 = 一次事务 = 一个存档点」写的。两者如何相容尚无答案。
2. **NPC / 势力模型是否仍需要（08-15c）** —— 社交语境并入 Exchange 后，NPC / 势力是降级为风味层，还是仍需一套数据模型（好感 / 关系度 / 跨轮回留存）；社交型产出是否触发 AdventurePlot 分支。
3. **道具定义与交易机制的切分（08-16b · 轻）** —— 同一问题在 `player-item/_index.md` 与 `exchange/_index.md` 两处各登记一次，说明现有切分只有归属结论、没有判据。
4. **`Jade` 的 `CostModifier` 取值（08-16g · 轻）** —— `ResourceElements` 表现填 `null`，理由是「商店价格修正在物化 / 展示侧施加」；本专场若定为「价格在 `TryApply` 时才修正」则需改填。

它卡住的东西：`ResourceElements` 表的 `Jade` 一行、`EventOption` 完整物化字段清单里 Exchange 的那一格、jade 的获取 / 消耗设计（`character-profile/currency.md`）、以及储物袋 9 格对「商店库存深度」的回压（`character-profile/item/_index.md`）。

## 约束（来自既有设计）

- **五类事件只有两个 resolver，拆分轴是「有没有状态机」**，Exchange 走 `GenericEventResolver`。`resolver` 只**描述**结果（`ResolveOutcome`），不自行写档。→ `systems/adventure-event/common-properties.md`「结算阶段」
- **商店购买是「余额不足即拒」的唯一消费点**；`ProfileService.CanAfford(spec)` 与 `ApplyResult.MissingElement` 因它而保留；**买不起的商品灰显并保留价格可见**。判据是「明知做不到仍然去做有没有意义」。→ `exchange/_index.md`、`systems/services/profile-service.md`
- **`CanAfford` 与 `TryApply` 必须走同一条 modifier pipeline**，共用内部 `Evaluate(spec)`。
- **一个 `ModifierKey` 只能有一个施加点**，判据 = 该修正后的值是否需要在施加之前呈现给玩家。→ `profile-service.md`
- **future-event-service 是唯一物化点，产出即定稿、落存档、不得回查模板重算**；**物化产出的数值必进快照**，文本类字段一律不物化。
- **`shop` 已是 `SeedManager` 的既有子流之一**（map / combat / shop / reward），不需要新开。→ `systems/common-properties.md`
- **一切抽取走 `AllEnabled()`；商店库存是四个抽取调用方之一**，`DrawPool<T>` 落地后由它统一承载。→ `systems/services/content-service.md`
- **`Source.ExchangePurchase`（code 6）已冻结存在**；合法子集表：`(Item, Player)` ✅ · `(Power, Character)` ✅ · `(Item, Character)` ✅ · `(Power, Player)` ❌。购买流程组装的 Grant element 走它，Exchange 的**非购买 outcome** 走 `Source.EventOutcome`。→ `systems/common-properties.md`
- **`ExclusiveSource != null` 的内容不进任何抽取池**（成就限定条目）。
- **PlotManager 只调内容不调约束**；`PlotModulation` 六字段是其权力面的逐条投影，写不出第七个。
- **储物袋 `magicPack` 上限 9 格**（按 `ItemId` 堆叠后的条目数），满袋处理尚未定案。
- **jade 取值域 `[0, ∞)`、归 0 不构成终态**、随轮回清理。
- **UI 文案走 `res://text/` 翻译键；内容文本走 `LocalizedText`。**

---

## 建议方案

### A. 结算形态：Exchange 不新增 resolver，交易逐笔即时提交

`[既有推演]`

**A1 —— 仍是 `GenericEventResolver`，不为 Exchange 开第三个 resolver。** 拆分轴是「有没有状态机」，而 Exchange 没有：它没有回合循环、没有跨帧的规则推进、没有需要引擎驱动的阶段机。「浏览 → 买若干件 → 离开」是**一串事件内决策点**，其形状与既定的战后奖励面板、以及能力置换的「失去 A · 得到 B + 接受 / 拒绝」面板**完全同构**——那两处都已被明写为「不新增机制」。

**A2 —— 每一笔交易即时提交一次 `TryApply`，不攒到 `eventEnd`（承重）。** 提案取「即时」而非「收口」，三条理由：

- **`CanAfford` 的正确性要求余额是真的。** 买第二件时的灰显判据必须读**扣掉第一件之后**的 jade。若攒到收口，UI 就要维护一份「已扣但未提交」的影子余额，而它与 `Evaluate(spec)` 是两条路径——正是「`CanAfford` 与 `TryApply` 必须走同一条 pipeline」那条纪律要防的分裂。
- **它堵死「买完退出重进拿回灵玉」。** 与古宝使用次数「即时经 `ProfileManager.TryApply` 写 PlayerProfile，不攒到收口，堵死用完退出重进恢复次数」是**同一条理由的第三个实例**（前两个：古宝次数、战斗内的即时写入）。
- **一笔交易本身就是一个自足事务**（`-jade` + `Grant`），「全有或全无」在这一笔内已经闭合，不需要跨笔的原子性。

**A3 —— 一笔交易的 spec 形状。**

```
Elements       : ChangeElement(Key = Jade, BaseValue = -ListPrice)
AbilityElements: AbilityChangeElement(Op = Grant, Id = ContentId, Source = Source.ExchangePurchase)   // 道具 / 神通类
Stats          : ⟨可选，见「前置依赖」——StatKey 清单未定⟩
```

卡牌 / 功法类商品不走 `AbilityElements`（它只承载 power / item），走卡组变更既有通道（`ProfileChangeSpec` → `TryApply`，见 `character-profile/deck/_index.md`「轮回中的构筑变更」）。

**A4 —— `ResolveOutcome` 只带账，不带第二次施加。** resolver 在玩家点「离开」时收口，`ResolveOutcome` 携带：① 本次已提交的交易清单（**记账用，不再施加**）；② 非购买 outcome / effect（对话结果、赠礼、隐藏属性推拉）。②照常并入 `eventEnd` 那一次合并 `TryApply`。

**A5 —— 存档点。** 每一笔交易的提交即是一次 Profile 变更 ⇒ 走既有的「变更后由 sync-service 上行」通道，与战斗内的即时写入同形。**不新增存档点类型**；`eventEnd` 的自动存档点照常。

---

### B. 库存生成：物化时掷定，随 `EventOption` 定稿落存档

`[既有推演]`

**B1 —— 库存在 future-event-service 物化时掷定**，用 **`shop` 子流**，经 `AllEnabled()` 取池。依据是三条已定纪律的直接推论：唯一物化点 · 产出即定稿、消费侧不得回查模板重算 · **物化产出的数值必进快照**（库存由 seeded RNG + 当时角色状态决定，重算不保证同结果）。

**B2 —— `EventOption` 新增一个物化字段 `ExchangeStock`**（非 Exchange 时为空）。它落在「`EventOption` 完整物化字段清单」那条待答项的 Exchange 那一格——**本方案填的是那一格，不改骨架七字段的任何一个**。

**B3 —— 模板侧的载体 `ExchangeSpec`（挂在 `AdventureEventData` 上）：**

```csharp
[GlobalClass]
public partial class ExchangeSpec : Resource          // Exchange 条目专有段；非 Exchange 条目为 null
{
    [Export] public ExchangeStockRule[] StockRules      { get; set; }   // 库存槽位规则；空 → 加载期 PushError
    [Export] public int                 RerollBaseCost  { get; set; }   // 刷新基价（jade）；0 = 本条目不可刷新
    [Export] public int                 RerollCostStep  { get; set; }   // 每次刷新的递增量
    [Export] public int                 MaxRerollCount  { get; set; }   // 刷新次数上限；0 = 不可刷新
    [Export] public bool                SellEnabled     { get; set; }   // 是否收购玩家物品（见取向项 ①）
    [Export] public int                 SellRatePercent { get; set; }   // 回收率（标价的百分比）
}

[GlobalClass]
public partial class ExchangeStockRule : Resource     // 一条规则 = 若干个同族槽位
{
    [Export] public ExchangeGoodsKind Kind            { get; set; }   // 商品族，见 B4
    [Export] public int               SlotCount       { get; set; }   // 该规则产出几个 offer
    [Export] public RarityTier[]      RarityFilter    { get; set; }   // 空 = 不限（按稀有度权重表抽）
    [Export] public int               PriceOffset     { get; set; }   // 相对定价表的条目级偏移；正数量值，语义由方向承载
    [Export] public int               DiscountPercent { get; set; }   // 该槽的固定折扣（风味用，见 D3）
}

public enum ExchangeGoodsKind { Card, CultivationTechnique, CharacterItem, CharacterPower, PlayerItem }
```

**B4 —— 商品族取值域 = 已存在的抽取池，不新建任何池。** `Card` → `CardData`；`CultivationTechnique` → `CultivationTechniqueData`；`CharacterItem` / `PlayerItem` → `ItemData` 按 `Scope` 分；`CharacterPower` → `PowerData` 且 `Scope == Character`。**`(Power, Player)`（法则）不在族内**——`Source` 合法子集表对它是 ❌，规则层本就不允许 `ExchangePurchase` 落到法则上。

**B5 —— 取池链沿用授予池那一条，不另写一段：**

```
AllEnabled() → 按 Kind 映射到对应仓储 → 排除 ExclusiveSource != null → 排除已持有（能力族）
→ RarityFilter 过滤 → 按 RarityTier 权重表 PickMany(shopRng, SlotCount)   // 无放回
```

`PickMany` 无放回是既定契约 ⇒ **同一批库存内不出现重复商品**，这条免费成立、不需要新规则。

**B6 —— 定稿实例 `ExchangeOffer`（immutable，随 `EventOption` 落存档）：**

```csharp
public sealed record ExchangeOffer(
    string            OfferId,      // 本 Exchange 实例内唯一；购买 / 售罄标记按它定位
    ExchangeGoodsKind Kind,
    string            ContentId,    // 溯源内容条目；展示文案按它现取模板（文本不物化）
    int               TechniqueTier,// 功法层数；其余族为 0
    int               BasePrice,    // 定价表算出的基准价（未施加折扣与 modifier）
    int               ListPrice,    // 实际标价 = 定稿价，见 D
    bool              SoldOut);     // 购买后置位
```

**B7 —— 「买完即售罄」，同一 offer 不可重复购买。** 通行做法（Slay the Spire / Balatro 商店皆然），且它是本作既定经济纪律的必需品：不设售罄，一个高价值 offer 会把 jade 全部单点吸走，库存槽位失去意义。

---

### C. 刷新（reroll）：机制给出，首批内容默认关闭

`[通行做法]` + `[取向选择]`

**C1 —— 形态**：花 jade 重掷整批库存，价格 `RerollBaseCost + RerollCostStep × 已刷新次数`，上限 `MaxRerollCount`。掷定走 `shop` 子流。**重掷结果即时落存档**（与既定的「候选必须预先算定并落决策点存档，否则退出重进可以重掷」同一条纪律；这是 reroll 能存在的前提）。

**C2 —— 刷新的支付走购买同一条路径**（`-jade` 的即时 `TryApply`），不新增机制。

**C3 —— 建议首批内容默认关闭**（`RerollBaseCost = 0` / `MaxRerollCount = 0`），理由见「仍需用户决定」取向项 ②。机制先落地、数据先留空是本库既有偏好（`selectCost` 复合形态保留而不塌缩，同款）。

---

### D. 定价与折扣：一张「商品族 × 稀有度」定价表 + 两条既有折扣通道

`[既有推演]`

**D1 —— 定价归属 = 统一定价表，不逐条目手写。** 与 `lifeSpanCost` 的「事件类型 × 篇章」定价表**完全同构**：表放 `systems/balance.md`，**内容条目默认不填、取表值**，需要体现风味差异时在 `ExchangeStockRule.PriceOffset` 上标偏移。三条理由逐条对应既有论证：改一张表即可全局调经济、不必重扫数百个 `.tres`、避免同类商品在不同作者手里定价漂移。

| 维度 | 取值 |
|---|---|
| 行 | `ExchangeGoodsKind` 五族 |
| 列 | `RarityTier` 五档 |
| 格值 | jade 基准价（正整数） |
| 篇章维 | **建议不设**——jade 随轮回清理、每章重置，与寿元的跨篇章结转不同，篇章差异应由「掉落多少 jade」承载而非「同一件东西涨价」 |

**具体数字归 ch1 数值标杆专场**，本方案只定表的形态。

**D2 —— 折扣通道一：`ModifierKey.ShopPrice`（PlayerPower 的具名 modifier）。** 它**在物化时施加，写入 `ExchangeOffer.ListPrice`**，因此**不进 `ResourceElements` 表**——「一个 `ModifierKey` 只能有一个施加点」，商店价格必须先算才能标价 ⇒ 施加点在物化 / 展示侧。这直接给出问题 4 的答案，见 F。

**D3 —— 折扣通道二：`ExchangeStockRule.DiscountPercent`（内容侧固定折扣）。** 用于表达「这位商贾对同门有优待」一类风味。它是**内容作者填的静态值**，与 D2 的玩家侧修正来源不同、可叠加，施加顺序：`ListPrice = ApplyModifier(ShopPrice, (BasePrice + PriceOffset) × (100 − DiscountPercent) / 100)`，结果 `Clamp` 到 `>= 1`（免费商品不由折扣产生，要免费就走非购买 outcome 的赠礼）。

**D4 —— `ListPrice` 在物化时定稿，代价明写。** 轮回中途新获得的降价修正（唯一现实路径 = 中途购买 premium bundle）**不影响已定稿的库存**，下一个 Exchange 事件才生效。接受它的理由：与「`EventOption` 产出即定稿、不得回查模板重算」一致，且反例（展示时现算）会让同一个 offer 在两次进入之间变价、且违反「重算不保证同结果 ⇒ 必进快照」。

---

### E. 售出：**仅 `CharacterItem` 一族可售出**（定案 5）

`[已定案 2026-08-17]` —— 原草稿建议「完全不开放」，**用户定案改为：开放售出，但售出面仅限 `ExchangeGoodsKind.CharacterItem`（角色级道具）**。

**E1 —— 售出准入是一条代码级常量判据，不做成内容可配的族白名单。**

```
可售出 ⟺ offer / 持有物的 ExchangeGoodsKind == CharacterItem
```

其余四族（`Card` · `CultivationTechnique` · `CharacterPower` · `PlayerItem`）**恒不可售**。写成常量而非内容字段的理由：内容侧若能逐条目开族，一个填错的条目就打开一条本定案要封的通道，而**校验无从判断作者是不是故意的**；把它钉在代码里，误开在编译期就不存在。

**E2 —— 条目侧仍保留 `SellEnabled`（该商店是否收购）与 `SellRatePercent`（回收率）两个字段。** 前者让「只卖不收」的商店可编排，后者是回收率旋钮（数值归 ch1 数值标杆专场）。

**E3 —— 原三条反对理由的现状（逐条如实记账，不因定案而抹掉）：**

| 原理由 | 定案后 |
|---|---|
| 卖卡 = 第二条弃卡通道 | **已消解**——`Card` / `CultivationTechnique` 不可售，卡组增删仍**唯一**归 Research。 |
| 古宝被贱卖 / 与 premium 定位冲突 | **已消解**——`PlayerItem` 不可售。 |
| 储物袋 9 格从取舍位变成套利位 | **仍然成立且正落在被开放的这一族上。** 9 格明写为「真正会咬人的构筑取舍位，不是溢出防护」；能卖 ⇒ 满袋从「必须放弃一件」变成「换成 jade」。 |

**E4 —— 对第三条的建议缓解（不改定案，只给旋钮）：**

- **回收率显著低于标价**（建议 `SellRatePercent` 落在 30–50%，具体归 ch1 标杆）。摩擦保住取舍感：卖仍是亏，只是比丢掉强。
- **`SellRatePercent` 施加在 `ListPrice` 上还是在该道具所属「族 × 稀有度」定价表格上**——建议**后者**：`ListPrice` 已含 `ShopPrice` modifier 与 `DiscountPercent`，按它折算会让「在打折商店卖东西更亏」，玩家读不出因果。按定价表基准价折算则与买价折扣完全解耦。
- **售出即时提交**，与购买同一条路径（A2），不攒到收口。
- **售出走 `Source.ExchangeSell`**——`Source` 枚举**需新增一个成员**（`ExchangePurchase` 是买入侧；卖出是一次 `Remove`，记账口径不同）。⚠ **这是本定案唯一的结构增量**：`Source` 落存档，增成员牵动存档 schema bump（当前无线上存档 ⇒ 空迁移）。合法子集表需加一行 `ExchangeSell × (Item, Character)` = ✅，其余格 ❌。

> **仍需在提炼时确认（轻）：** 是否新增 `Source.ExchangeSell`，还是复用 `ExchangePurchase` 表示「与商店的交易」。建议**新增**——`Source` 的既定职责是「这件东西**怎么来的 / 怎么没的**」，买与卖在履历、成就与诊断上是两件事；复用会让「购买次数」这类统计永远算不准。

---

### F. `Jade` 的 `CostModifier`：维持 `null`，并删除它对本专场的依赖

`[既有推演]` —— **这一条由 D2 直接答结，不含取向成分。**

本方案定为「价格在**物化 / 展示侧**修正、`ListPrice` 定稿后再进 `TryApply`」，因此：

- **`ResourceElements` 表的 `Jade` 行保持 `(Min = 0, Max = null, DepletionDefeat = null, CostModifier = null, GainModifier = null)`，一格不改。**
- 若改填 `CostModifier = ShopPrice`，会**打两次折**：`CanAfford` 与 `TryApply` 共用 `Evaluate(spec)`，而传入的 `BaseValue` 已是修正后的 `ListPrice` ⇒ 玩家看到 80、实扣 64，且灰显判据也随之偏移。这正是「一个 `ModifierKey` 只能有一个施加点」要防的那个坏状态。
- **连带动作：** `profile-service.md` 待决问题里「**`Jade` 的 `CostModifier` 取值依赖 Exchange 专场（轻）**」一条**可整条移出**（不再是待答项，而是已定：恒 `null`，理由是价格在展示侧定稿）。`open-questions/03-adventure-event-types.md` 的同名条目一并移出。
- **`ModifierKey` 需含成员 `ShopPrice`**（若尚未登记）。「表里出现的 key 必须是 `ModifierKey` 成员，反向不要求」⇒ 它在 `ModifierKey` 里、不在 `ResourceElements` 表里，完全合法。

---

### G. NPC / 势力：降级为风味层，不建数据模型

`[既有推演]`（推荐强度高）

**G1 —— 不新建 `NpcData` / `FactionData`，不设好感 / 关系度数值，不跨轮回留存。** 四条依据：

- **ADR-0002 的判据原样延伸。** 「分成两类只是在内容风味上切一刀，而**风味不需要枚举值来承载**」——同一条判据对字段同样成立：风味不需要一套数据模型来承载。若 NPC 只影响文案与插图，它就是 `AdventureEventData` 的 `Id` 命名约定 + `LocalizedText` + 图标字段，**已经全部就位**。
- **好感 / 关系度若有持久数值，它就是第四个隐藏属性。** 而档位表已定案为三属性 12 档，且明写「**档数永远不是该动的旋钮**」；加一条属性要连带新增：`CharacterProfile.Status` 的 band 字段、一套 `HiddenStatBandData` 档位、回滞 δ、加载期校验、以及 `HiddenStat` 枚举成员（存档迁移）。代价与收益完全不成比例。
- **跨轮回留存会撞既有的两层分层。** 账号级持久数据归 `PlayerProfile`，而它的字段结构本身还是待答项；且「与某 NPC 的关系跨轮回留存」与 jade「随轮回存在、随轮回清理」的经济分层不同轴——一个跨轮回的社交数值会让「新轮回是干净重置」这条不再为真。
- **表达「关系」的既有通道已有两条，且更贴合本作形态。** `PlotArcData` + `PlotKeyPoint`（每条已激活 arc 一条锚点、带 `State`）天然就是「与某人 / 某势力的一段关系走到哪一步」；`pastEvent` 是 PlotManager 的只读输入，「见过谁、跟谁做过交易」直接读得出。**好感度本质上就是一条 arc 的进度**，只是用离散节点而非连续数值表达——这恰好与本作「给方向不给数字」的既定纪律同向。

**G2 —— 「势力」的承载 = 三个既有字段的组合，零新增：** `PlotArcData.ExclusiveGroup`（同组 arc 一次轮回内至多激活一条 ⇒ 「投靠了甲就进不了乙的线」）· `PlotModulation.EventWhitelist` / `EventWeights`（该势力的事件更常出现）· location 的事件类型出现概率修正（坊市多 Exchange）。

**G3 —— 内容侧约定（这是 NPC 唯一需要新写的东西）：** `Id` 前缀承载 NPC 身份，例 `event.exchange.npc.<npc_slug>.<n>`；同一 NPC 的多个事件条目共用 slug。**这是一条内容编排约定，不是代码规则**——不加字段、不加校验（不给字段就不存在「谁有权用它」的问题，与 `TravelFullFanoutChance` 的收口同款）。

**G4 —— 社交型产出触发 AdventurePlot 分支：已经成立，不需要新机制。** 三条通道现成：

| 想表达的 | 既有承载 |
|---|---|
| 「与某 NPC 完成过某次交易」推进剧本 | `PlotCondition.Kind = EventResolved`（参数 `EventId` / `EventType` / `EventOutcome`） |
| 「买下了某件东西」推进剧本 | PlotManager 读 `pastEvent`（它已是一等只读输入）：`AppliedChange` 里有 `Op == Grant` 且 `Source == ExchangePurchase` 的 element |
| DnD 式显式选择（答应 / 拒绝某人的条件） | `PlotEdge.BranchLabel` 非空 + `ChooseBranch(branchId)`，已定案 |

- **明确不做的两件事：** ① **不为「买了什么」新增 `PlotCondition.Kind` 成员**——`pastEvent` 已经读得出，新增等于制造第二条判定路径；② **不动 `EventOutcome` 四值枚举**（`Resolved` / `CombatWon` / `CombatLost` / `Aborted`）——「枚举成员的增删牵动存档迁移」是明写的既定纪律，且 Exchange 的一切走向都落在 `Resolved` 上。

---

### H. 道具定义 vs 交易机制的切分：给判据，并封住一个字段

`[既有推演]`

**H1 —— 维持现切分（定义归 `player-item` / `character-profile/item`，机制归 Exchange），但把结论换成判据：**

> **「这条信息在游戏里没有商店时是否仍然存在？」**
> 仍然存在 → 归道具侧；不存在 → 归 Exchange 侧。

| 归道具侧（`ItemData` / `player-item` / `character-profile/item`） | 归 Exchange 侧 |
|---|---|
| `Id` · `Scope` · `UsableScene` · `ManaCost` · `Charges` · `Abilities` · `Rarity` · `Subtypes` · 折价系数 `itemPowerRatio` | 库存槽位规则 · 标价 / 折扣 / 刷新 / 售出 · `ExchangeOffer` · 购买流程与 `Source.ExchangePurchase` |

**H2 —— 判据的第一条硬推论：`ItemData` 上不加 `Price`，也不加 `Purchasable`。**

- **价格**在没有商店时不存在 ⇒ 归定价表（D1）。把 `Price` 写进 `ItemData` 会制造第二权威：表与条目各自漂移，而本库无机制发现。
- **「能不能买」**已由既有字段免费给出：`ExclusiveSource != null` 的条目不进任何抽取池、库存抽取也是抽取 ⇒ **成就限定条目天然不会出现在商店里**，不需要第二个布尔。

**H3 —— 两处重复登记的收口。** `player-item/_index.md` 与 `exchange/_index.md` 的两条同题待答项**合并为一条判据**：判据本体写在 `exchange/_index.md`（机制侧是提问方），`player-item/_index.md` 只留一句「道具定义不含价格 / 可购标记，判据见 `systems/adventure-event/exchange/_index.md`」+ 回链。**回链而非复述**——这是本库承重纪律。

**H4 —— 措辞修正（`exchange/_index.md` 现文有一处会误导）。** 现写「可购道具的定义归属 `player-profile`」，但商店主要售卖的是**轮回级**的法宝 / 神通 / 功法 / 卡牌，其定义分别在 `character-profile/item/`、`character-profile/power/`、`character-profile/deck/`。建议改为：「商品的**内容定义**一律归各自的内容子树，Exchange 只承载交易机制」，并列出五个商品族各自的定义位置。

---

## 具体形态（可 derive 的落地面）

**新增类型（3 个 `Resource` + 1 个 `record` + 1 个枚举）**

| 类型 | 层 | 落点 |
|---|---|---|
| `ExchangeSpec : Resource` | 模板 | `AdventureEventData` 的一个 `[Export]` 字段（非 Exchange 为 null） |
| `ExchangeStockRule : Resource` | 模板 | `ExchangeSpec.StockRules` |
| `ExchangeOffer`（`sealed record`） | 定稿实例 | `EventOption.ExchangeStock`，随批次落存档 |
| `enum ExchangeGoodsKind` | 代码常量 | `{ Card, CultivationTechnique, CharacterItem, CharacterPower, PlayerItem }` |
| `ModifierKey.ShopPrice` | 代码常量 | 具名 modifier；**不进 `ResourceElements`** |

**`EventOption` 的字段增量（骨架七字段不动）**

```csharp
IReadOnlyList<ExchangeOffer> ExchangeStock,   // 非 Exchange 为空列表
int                          RerolledCount    // 已刷新次数；供刷新价递增与存档恢复
```

**加载期校验（坏数据启动期大声失败）**

| 违规 | 处置 |
|---|---|
| `eventType == Exchange` 而 `ExchangeSpec == null`，或 `StockRules` 为空 | `PushError` + 抛（带 `EventId`） |
| `eventType != Exchange` 而 `ExchangeSpec != null` | `PushError`（带 `EventId`） |
| `StockRules` 的 `SlotCount <= 0` | `PushError`（带 `EventId` + 规则序号） |
| `Kind` 对应的抽取池在 `RarityFilter` 过滤后为空 | `PushError`（带 `EventId` + `Kind`）——否则会在轮回中途开出一个空商店 |
| `MaxRerollCount > 0` 而 `RerollBaseCost <= 0` | `PushError`（可无限免费刷新 = 零成本 reroll 漏洞，与 Travel 定价必须 > 0 同一条理由） |
| `DiscountPercent` 不在 `[0, 100]` | `PushError` |
| 定价表某格缺失 | 启动期 `PushError`（同 `ResourceElements` 表的全成员断言） |

**运行期校验**

| 情形 | 语义 | 处置 |
|---|---|---|
| 购买时 `offer.SoldOut == true` | 业务失败 | `OpResult` 拒绝 + `PushWarning`（正常路径已灰显，到达此处说明 UI 与状态不同步） |
| `CanAfford` 为 false 仍提交 | 业务失败 | `ApplyResult.Fail(MissingElement = Jade)`，绝不抛 |
| 购买 `PlayerItem` 且储物袋 / 持有约束不满足 | ⟨依赖「满袋处理」待答项，见前置依赖⟩ | — |
| `Grant` 目标已持有 | 可选缺失 | `PushWarning` + 空操作（取池已排除已持有，出现即内容错误） |

**日志**（沿用 `[System-Method]` 约定）

```
[Exchange-Purchase] offer=<OfferId> content=<ContentId> price=<ListPrice> jadeAfter=<n>
[Exchange-Reroll]   event=<InstanceId> count=<n> cost=<c>
```

**UX 落地面（竖屏 · 触控 · 归 `ux/screen-flow.md`）**

- offer 以纵向可滚动网格呈现，每格 = 图标 + 名称 + 价格；**买不起 → 灰显但价格保持可见**（既定），点按给一条说明差哪一样的提示（由 `MissingElement` 驱动，走 `res://text/` 翻译键，**不写文案字面量**）。
- 售罄 offer 保留占位并标「已售」，不从网格移除——移除会让布局跳动，且玩家失去「我买了什么」的现场记忆。
- 刷新按钮（若该条目开放）常驻底部，标注当前刷新价与剩余次数；**无 hover-only 可供性**。
- 「离开」按钮常驻，点击即收口结算。

---

## 后果

- **文档面：** `exchange/_index.md`（结算形态 · NPC 结论 · 切分判据 · 措辞修正）· `exchange/common-properties.md`（`ExchangeSpec` / `ExchangeOffer` 字段表）· `future-event-service.md`（库存物化段 + `EventOption` 字段增量）· `profile-service.md`（移出 `Jade.CostModifier` 待答项、`ModifierKey` 增 `ShopPrice`）· `player-item/_index.md`（切分待答项收口为回链）· `currency.md`（jade 的消耗点至此有形态，获取渠道仍待定）· `balance.md`（新增「商品族 × 稀有度」定价表 + 刷新价参数）· `plot-manager.md`（NPC / 势力由既有通道承载，不新增字段）· `ux/screen-flow.md`（商店屏）。
- **存档 schema：** `EventOption` 新增两个物化字段，**外加定案 5 带来的 `Source.ExchangeSell` 新成员**（若采纳 E4 末的建议）⇒ **bump 存档 schema 版本**；当前无线上存档 ⇒ **空迁移**，走既有 MigrationManager 骨架。
- **待答项净变化：** 答结 2 条（`Jade.CostModifier` · NPC / 势力模型）· 收窄 2 条（Exchange 结算器数据形态 → 只剩数值；道具 / 交易切分 → 只剩措辞落笔）· **新增 0 条**（取向项若被采纳即闭合，若否决则各自留一条）。
- **不受影响：** `PastEventEntry` 的字段表（除 `AppliedChange` 语义澄清外）· `EventOutcome` 枚举 · `PlotModulation` 六字段 · 三个隐藏属性与 12 档档位表 · `ResourceElements` 表的任何一格。

---

## 备选方案（已考虑并否决）

- **为 Exchange 开第三个 resolver（`ExchangeEventResolver`）。** 否决：拆分轴是「有没有状态机」而非「有几个类型」，这是明写的既定判据；Exchange 的多步交互全在 UI 层，没有需要引擎驱动的阶段机。开第三个即打开「每类事件各开一个 resolver」的滑坡。
- **交易攒到 `eventEnd` 一次提交。** 否决：`CanAfford` 会被迫读一份与 `Evaluate(spec)` 分裂的影子余额；且它重开「买完退出重进拿回灵玉」的窗口，正是古宝次数即时写入所堵死的那一类。
- **把价格写进 `ItemData.Price` / `CardData.Price`。** 否决：制造第二权威（表与条目各自漂移），且「新增一个商品族」要改 N 个内容类；定价的设计判据本就是全局经济而非单个条目的风味——与 `lifeSpanCost` 定价表同一条论证。
- **给 `Jade` 填 `CostModifier = ShopPrice`。** 否决：打两次折，显示价与实扣价不一致，直接违反「一个 `ModifierKey` 只能有一个施加点」。
- **`ExchangeOffer` 只存 `ContentId`，价格在展示时现算。** 否决：违反「重算不保证同结果 ⇒ 必进快照」；且同一 offer 会在两次进入之间变价。
- **为 NPC 建 `NpcData` + 好感度数值。** 否决：好感度 = 第四个隐藏属性，牵动档位表 / 存档字段 / 枚举迁移；而 arc + key point + `pastEvent` 三条既有通道已能表达关系推进，且更贴合「给方向不给数字」。
- **为「买了什么」新增 `PlotCondition.Kind` 成员。** 否决：`pastEvent.AppliedChange` 已读得出（`Source == ExchangePurchase` 的 Grant element），新增等于第二条判定路径。
- **库存按 location 分池（每个地域一套独立商品池）。** 否决：与「location 是软框定、改权重不改可及性」冲突；风味差异由 `ExchangeStockRule` 的 `RarityFilter` / `PriceOffset` 与 location 的事件类型修正共同表达已足。

---

## 与既有决策的张力

**张力 ① —— 「一个事件 = 一次事务 = 一个存档点」与逐笔提交（A2）。**

- 冲突的是哪一条：`profile-service.md` 与 `adventure-event/common-properties.md` 都写有「一个事件 = 一次事务 = 一个存档点」。
- 为什么需要它松动：多次主动消费在一次事务内无法维持 `CanAfford` 的正确性（见 A2）。
- 松动的代价：Exchange 事件的 Profile 变更不再是单点提交，中途退出的玩家会停在「已买两件、第三件没买」的状态——但这**正是玩家的真实意图**，而非半成品状态。
- **不松动时的替代方案**：影子余额（已否决，理由见备选）；或每个 Exchange 只允许买一件（把商店退化为一次三选一，丢掉「花光身上的钱」这一层决策）。
- **它其实已有两个先例**：古宝使用次数的即时写入、战斗内的即时写入——两处的措辞都是「不攒到收口」。建议的处置是**把这条纪律改写为准确形态**：「一个事件的**收口**是一次事务一个存档点；事件**内部**的主动消费即时提交」，而非为 Exchange 开例外。**裁决权在用户。**

**张力 ② —— `PastEventEntry.AppliedChange` 的语义。**

- 现定义是「`eventEnd` 那一次合并 `TryApply` 的最终 spec」。逐笔提交后，购买不在那一次里。
- 建议：把它的语义按文档自己写下的设计意图（「**这个角色一路上到底发生了什么，是一条可直接重放的账**」）明确为**本次事件的最终账**——由 life-cycle-service 把逐笔已提交的 spec 累加进 `AppliedChange`（**记账，不再施加**）。
- 不这样做的代价：履历 / 剧本 / 诊断三个消费方都读不出玩家在商店里做了什么，而这正是 `AppliedChange` 被引入时要消除的那个坏状态。
- **代价明写**：`AppliedChange` 不再与「那一次 `TryApply` 的入参」逐字段相等，两者的一致性不能再机械断言。

**张力 ③ —— `EventOption` 的批次快照体积。** 一批最多 5 项、每个 Exchange 挂若干 offer，若某条目开出 8 个槽位，单事件快照会明显变胖。建议在 `ExchangeSpec` 加载期校验里加一条**槽位总数上界**（建议 ≤ 8，具体归 balance），并注意 `sync-service.md` 已有的体积护栏。

---

## 前置依赖

- **`EventOption` 完整物化字段清单**（`future-event-service.md` 待答）—— 本方案填 Exchange 那一格，但字段的最终排布须与该项一并定稿。
- **jade 的获取渠道与掉落权重**（`character-profile/currency.md` 待答）—— **定价表的绝对数字在它答定前无法反推**；本方案只定表的形态。
- **储物袋满袋处理**（`character-profile/item/_index.md` 待答 · 承重）—— 「满袋时能否购买道具」这一条**在它答定前无法定稿**：拒收 / 强制择一丢弃 / 库存侧过滤三种处置会给出三套不同的购买前置校验。它同时决定「商店库存深度是否需要同步下调」。
- **ch1 数值标杆专场** —— 定价表每格填多少、刷新价、售出回收率（若开放）。
- **`StatKey` 的完整成员清单**（`profile-service.md` 待答 · 轻）—— 若要统计购买次数，需要一个 `StatKey` 成员；不统计则本方案零依赖。
- **`DrawPool<T>` 与 `LocalizedText` 的落地排期**（第二阶段开工前）—— 库存抽取是 `DrawPool<T>` 的四个调用方之一，本方案的取池链按它的最终形态书写。

---

## 定案（2026-08-17）

| 原取向项 | 定案 | 相对原推荐 |
|---|---|---|
| ① 是否开放玩家侧售出 | **仅 `CharacterItem` 一族可售出** | **推翻**原推荐（原为「完全不开放」）；见改写后的 E 节 |
| ② 是否开放刷新 reroll | **机制落地、首批内容默认关闭** | 与推荐一致（原 A） |
| ③ jade 能否购买账号级古宝 | **不铺开**（合法子集表那一格不动，规则层保持开放） | 与推荐一致（原 A） |

## 两条全局纪律的改写：**已裁决通过（2026-08-17）**

原「与既有决策的张力」①②**均已获用户点头**，提炼时按下列形态落笔：

**① 「一个事件 = 一次事务 = 一个存档点」改写为准确形态。**

> **一个事件的收口是一次事务、一个存档点；事件内部的主动消费即时提交。**

- 适用面**不限于 Exchange**——它把已有的两个先例（古宝使用次数的即时写入、战斗内的即时写入）与 Exchange 的逐笔交易统一到同一条措辞下，**不是为 Exchange 开例外**。
- 落笔处：`systems/services/profile-service.md` 与 `systems/adventure-event/common-properties.md` 两处现有措辞同改，且**必须同改**——留一处旧措辞就是留一个第二权威。

**② `PastEventEntry.AppliedChange` 的语义放宽为「本次事件的最终账」。**

- 由 life-cycle-service 把逐笔已提交的 spec **累加**进 `AppliedChange`（**记账，不再施加**——它不是第二次写入点）。
- **代价明写（须一并落进文档，不得省略）：** `AppliedChange` 不再与「`eventEnd` 那一次 `TryApply` 的入参」逐字段相等，两者的一致性**不能再机械断言**；诊断与回放读它时以「最终账」为准。

**两项轻量确认（不阻塞，提炼时一并落笔）：**
- **新增 `Source.ExchangeSell`**（见 E4 末的建议与理由）——买与卖在履历、成就与诊断上是两件事。
- **槽位总数上界 ≤ 8**（张力 ③），具体数字归 balance。

## 仍需用户决定

**无。** 三项取向 + 两条全局纪律改写均已裁决（见上方两节）。
