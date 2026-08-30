---
type: solution-draft
date: 2026-08-28
question: Exchange 是否支持「以物易物」（支付侧为一件指定持有物）——还是它只是「以资源换取」的口语说法？
source: open-questions/03-adventure-event-types.md → 「Exchange 是否支持以物易物（08-26 新增）」
targets: systems/adventure-event/exchange/_index.md · systems/adventure-event/exchange/common-properties.md · systems/services/profile-service.md（仅当采纳 B）· systems/common-properties.md（仅当采纳 B）· ux/screen-flow.md（仅当采纳 B）· handoffs/2026-08-26-storage-pack-two-layer-view-and-combat-holdings.md（措辞回改，见「与既有决策的张力」④）
status: distilled
reviewed: 2026-08-28 批量评审裁定落地定值以物易物（支付侧 = 货币或轮回级持有物）；2026-08-30 合并 interview 另裁 2 题（不持有 → 灰显 + 支付要求可见 + 一条 `EVENT_` 说明，**推翻草稿括注里「按 `Holds` 决定是否呈现」** · **新增 `Source.ExchangeBarter = 10`**，推翻草稿 §3c 的否决）
distilled-to: handoffs/2026-08-30-exchange-barter-support.md
---

# 方案草稿 — Exchange 是否支持以物易物

## 问题

08-26 的一次裁决中，用户口头描述「Exchange event 是以物易物或资源换取道具的场景」。该句被 `/analyze-new-ideas` 原样引作两档回收率的论证基底写进了 handoff，但**「以物易物」在本库零承载**：

- `ExchangeOffer` 的支付侧只有一格 `Currency: CostKey` + 两格价格，物化时从「族 × 稀有度」定价表抄下；购买 spec 的成本侧恒为一条 `ChangeElement(offer.Currency, -ListPrice, Add)`。
- `ExchangeStockRule` 上没有任何「以什么换」的书写位——它的五格全部服务于**产出侧**的抽取（`Kind` / `SlotCount` / `RarityFilter` / `PriceOffset` / `DiscountPercent`）。
- `ProfileService.CanAfford(spec)` 按定义**只看 `Op == Add` 且 `BaseValue < 0` 的资源 element**，不读任何持有面。

因此这句话卡住的是一个二选一：**它是一种尚未落地的交易形态，还是「以资源换取」的口语同义表述？** 前者要同时动三处承重面，后者是零改动。它同时阻塞 derive 队列第 18 步（`open-questions.md` 已明写 `exchange/` 须排除本项）。

## 约束（来自既有设计）

- **`CanAfford` 是全库唯一的预校验方法，且唯一消费点就是 Exchange 的商店购买**；事件推进路径不调用它（`selectCost` 无条件施加）。它与 `TryApply` 共用 `Evaluate(spec)`，「两者必须走同一条 pipeline」是承重。→ `systems/services/profile-service.md`
- **`Remove` 的目标不在持有列表 = 可选缺失**：`PushWarning` + 该 element 空操作，**不使整批失败**。→ `systems/services/profile-service.md` 施加失败语义表
- **`AbilityElements` / `DeckElements` 在 `SelectCost` 内恒为空**（不变式，加载期 + 物化后双重断言）。理由：成本侧只放**可如实计价的量**。→ 同上
- **`PairKey` 要求配对两端 `(CarrierKind, Scope)` 相同**，否则 `PushError` + 整批拒绝。→ 同上
- **`Source` 成员名与 code 双双永久冻结**，已删成员的名与 code 永不复用；`ExchangeSell = 8` 只能出现在 `Op == Remove` 且 `(Item, Character)` 上，`ExchangePurchase = 6` 只能出现在 `Op == Grant` 上。→ `systems/common-properties.md`
- **灵石与仙玉完全不可兑换，售出同币回收因而不产生事实汇率**（承重）。→ `systems/character-profile/currency.md`
- **定价的唯一权威是「商品族 × 稀有度」表，`ItemData` 上不加 `Price`**；制造第二处估价即第二权威。→ `systems/adventure-event/exchange/_index.md`
- **每一笔交易即时提交一次 `TryApply`；产出即定稿、消费侧不得回查模板重算。** → `decisions/ADR-0020` · `decisions/ADR-0012`
- **`AbilityChangeElement` 只承载已定稿的 `Id`**，随机性必须在 spec 组装前掷完。→ `systems/services/profile-service.md`
- **`PlotCondition.Kind` 五值（`EventResolved` / `HiddenStatBand` / `BranchChosen` / `ChapterAdvanced` / `EventCount`）中没有持有向**；事件选择面明写不做付得起校验、不设灰态。→ `systems/services/plot-manager.md` · `systems/adventure-event/exchange/_index.md`

## 建议方案

### 1. 先把「以物易物」拆成三种互不相同的所指 `[既有推演]`

原句是一句口语，落地形态至少有三种，代价相差一个数量级。先分开它们，再谈取舍：

| 记号 | 形态 | 本库现状 |
|---|---|---|
| **A** | **「以物易物」= 交易的口语同义词**，实际形态是「以货币换取 card / 功法 / 法宝 / 神通」，外加**商店内售出**这条反向通道 | **已完整承载**，零改动 |
| **B** | **定值以物易物**：某个 offer 的支付侧是**一件点名的持有物**（`ContentId` 在内容侧写死），玩家持有它才可换 | 零承载，需动三处 |
| **C** | **估价式换购**：玩家从储物袋里任选若干件抵扣价款，按某个折算率折抵 | 零承载，且与承重纪律正面冲突（见「备选方案」） |

**A 已经在玩法层给出了以物易物的完整体验，只是多一步点击。** 在一个 `SellEnabled == true` 的商店里，玩家可以卖掉法宝并用所得买另一件商品；**售出恒为同币回收**（币种取该条目在定价表那一格），因而这一进一出**恒在同一条价值线内闭合**——玩家在观感上做的就是「拿这件换那件」。B 相对 A 的净增量只有两条：① 把两步合成一步；② 支付物可以是**商店指定**的而非玩家挑选的。

### 2. 推荐取向：按 A 收口，不落地 B `[取向选择]`（本草稿唯一留待用户裁决的一条，详见「仍需用户决定」）

四条理由，逐条对上既有纪律：

- **B 的三处改动全部落在承重面上**（`CanAfford` 的定义 · `Remove` 的失败语义 · 支付侧无表可读），而它换来的玩法增量是「省一次点击 + 商店可点名要哪件」。这两条都不是本作已声明要解决的问题。
- **B 的内容形态天然是死格。** 支付侧必须是**已定稿的 `ContentId`**（`AbilityChangeElement` 只承载定稿 Id；抽取池不知道玩家持有什么）⇒ 一个 barter offer 在绝大多数轮回里玩家并不持有那件法宝，它**恒处灰显**。而「买不起则灰显」这条既有处置针对的是**可变**状态（攒够钱就能买）；一个玩家本轮回大概率永远拿不到的支付物，会把它变成一个**恒不可用的占位**——`ux/screen-flow.md` 已明写「恒真的不可用项不出现、不留灰占位」（古宝上不出现「售出」键即此判据）。B 因此还要额外回答「不持有时这个 offer 出不出现」，而两个答案都不好看：出现即恒灰占位、不出现即库存槽位随玩家持有面浮动（与「物化时掷定、恢复即读结果」冲突）。
- **叙事上真正想要的那个形态不在 Exchange 侧。** 「某 NPC 索要一件信物」的价值全在**剧情门控**，而 `PlotCondition` 五值里没有持有向 ⇒ B 落地后仍写不出这个桥段，只是多了一个恒灰的商店格子。要写它需要另一条独立的持有向门控，那是另一个问题（见「前置依赖」）。
- **五类事件机制刚在 08-17 ~ 08-26 全部收口，`exchange/` 已排进 derive 队列第 18 步。** 判 A 即当场解除该步的排除项；判 B 则两份 exchange 文档 + `profile-service.md` + `common-properties.md` 须先改写再 derive。

**判 A 的动作是三条编辑，不是「什么都不做」**（本草稿不执行，由 `/analyze-new-ideas` 落笔）：

1. `exchange/_index.md` 「定位与结算形态」首条追加一句正面纪律：**「交易的支付侧恒为一条货币 element；不设以物易物形态——『拿这件换那件』由『在同一家 `SellEnabled` 商店内售出 + 购买』两步表达，同币回收保证这一进一出闭合在同一条价值线内。」** 写下**不做什么**与做什么同等重要，否则同一句口语会在下一次 handoff 里再次被读成一种未落地的形态。
2. 把该项从 `open-questions/03-adventure-event-types.md` 移出、记入 `answer-logs/`，并解除 `open-questions.md` derive 队列第 18 步对本项的排除。
3. 回改 `handoffs/2026-08-26-...` 那两处「Exchange event 的形态是以物易物或资源换取道具」的措辞（见「与既有决策的张力」④）。

### 3. 若判 B：可落地的最小形态（推演到可 derive 的程度）`[既有推演]`

以下不是推荐项，是**为「用户判 B」备好的落地面**。它按「改动最小 + 不新增第二权威」推出，每一条都有既有形态对应。

#### 3a. barter offer 不由抽取产生，与 `StockRules` 平级另开一格 `[既有推演]`

```csharp
public partial class ExchangeSpec : Resource
{
    [Export] public ExchangeStockRule[] StockRules   { get; set; }   // 既有，不改
    [Export] public ExchangeBarterRule[] BarterRules { get; set; }   // 新增；可空 = 该商店无以物易物
    // 其余五格不变
}

[GlobalClass]
public partial class ExchangeBarterRule : Resource   // 一条规则 = 一个定值 barter offer，不产生随机
{
    [Export] public string            PayItemId  { get; set; }   // 支付物：ItemData 且 Scope == Character 的稳定 Id
    [Export] public ExchangeGoodsKind GoodsKind  { get; set; }   // 产出物所属族
    [Export] public string            GoodsId    { get; set; }   // 产出物：该族对应仓储内的稳定 Id
}
```

- **不往 `ExchangeStockRule` 上加 `PayItemId`。** 一条 stock rule 按定义是「若干个**同族**槽位」，`SlotCount` 个 offer 共用一条规则；而支付物只有一件、且必须逐 offer 定稿——形状对不上，加进去必然引出「N 个槽位是不是各要一件支付物」。
- **barter 不进抽取池、不掷 `RngStream.Shop`、不受 `RarityFilter` / 稀有度权重影响。** 它是内容作者点名的固定编排，与「`TargetId` 指定定值的编排不经抽取池」同款（见 `exchange/common-properties.md`「成员卡不从散牌产出侧发放」的例外条）。因而它也**不参与档位供需核算（闸 ①）**——那条闸算的是抽取池分母。
- **产出物同样是点名 `GoodsId`，不走池。** 若走池则支付物固定而产出随机，玩家无从判断这笔换划不划算；且 barter 无价格可比。

#### 3b. 物化侧：`ExchangeOffer` 不改形状，另立一个平级 record `[既有推演]`

```csharp
public sealed record BarterOffer(            // 定稿实例：immutable，随 EventOption 落存档
    string            OfferId,               // 本 Exchange 实例内唯一，与 ExchangeOffer 同一命名空间（购买 / 售罄按它定位）
    string            PayItemId,             // 支付物内容 Id
    ExchangeGoodsKind GoodsKind,
    string            GoodsId,
    int               GoodsTechniqueTier,    // 产出为功法时的层数；其余族为 0
    bool              SoldOut);              // 兑换后置位
```

- **不往 `ExchangeOffer` 上加 `PayItemId` + 一个「这是 barter」的布尔。** 那会让 `Currency` / `BasePrice` / `ListPrice` 三格在 barter 行上恒无意义，而「一个字段在某些行上恒为空」正是分列判据（`systems/architecture.md` 的三级阶梯 ①：**键与载荷的形状**根本不同）。
- **落 `EventOption.BarterStock`**，与既有 `ExchangeStock` / `RerolledCount` 平级 ⇒ **`EventOption` 增一格 ⇒ bump 存档 schema 版本**（当前无线上存档 = 空迁移，走既有 MigrationManager 骨架）。
- **barter offer 不参与刷新（reroll）。** 它是定值编排，重掷它没有语义；`RerolledCount` 只作用于 `ExchangeStock`。这条须在文档里明写，否则「刷新价与新库存必须落在同一次 `TryApply`」那条承重会被读成也要覆盖 barter。

#### 3c. 一笔 barter 的 spec 形状：零新 `Source` 成员 `[既有推演]`

```
TryApply(
  AbilityElements[
    AbilityChangeElement(Remove, Item, Character, PayItemId, -, Source.ExchangeSell, PairKey = null)
  ]
  + 产出侧那一条既有 element（按 GoodsKind 取 exchange/common-properties.md 的映射表，Source = ExchangePurchase）
)
```

- **支付侧复用 `Source.ExchangeSell`，产出侧复用 `Source.ExchangePurchase`，不新增成员。** 语义精确：这件法宝确实是**交给商店换走的**，与卖给商店在「东西怎么没的」这一职责上完全同一；而产出确实是**从商店换来的**。合法子集表当场成立（`ExchangeSell` 只允许 `Op == Remove` 且 `(Item, Character)`，正是支付侧的形状）。
- **明确否决新增 `Source.ExchangeBarter`。** 成员名与 code 一经写出即永久冻结、不可改名不可复用（承重），而两个既有成员的组合已完整表达这笔交易的两端；新增只换来「账里一眼看出这是 barter 而非卖+买」，而这一点从 `AppliedChange` 里同批出现的两条 element 即可读出。
- **`PairKey` 留空。** barter 跨列（`AbilityElements` 的 `Remove` + 可能落在 `DeckElements` 的产出），而 `PairKey` 要求两端 `(CarrierKind, Scope)` 相同 ⇒ 跨族 barter（付法宝换功法）根本配不出对，非空即 `PushError`。**原子性由 `TryApply` 的「全有或全无」保证，不由 `PairKey` 保证**——后者是置换语义的配对校验，不是事务边界。
- **不产生跨币通道。** barter 一枚货币都不动 ⇒ 「灵石与仙玉完全不可兑换」不受影响，也不产生任何事实汇率。这是 B 相对 C 最重要的结构优势。

#### 3d. 「换得起」的判定：不改 `CanAfford`，在 Exchange 侧加一条只读持有查询 `[既有推演]`

**这是三处改动里唯一真正承重的一处，也是最容易写错的一处。** 直接把 barter spec 交给 `CanAfford` 会**静默通过**：它按定义只看 `Op == Add && BaseValue < 0` 的资源 element，barter spec 里一条都没有 ⇒ 恒返回 `true`；而提交时 `Remove` 目标不在持有列表是**可选缺失**（`PushWarning` + 空操作、不阻断整批）⇒ **产出侧照常 `Grant`，玩家白拿一件商品**。这是一条可被玩家发现并稳定复现的白送漏洞，必须在设计层堵死，不能留给实现者临场判断。

建议落法：

1. **不扩 `CanAfford` 的语义。** 它是全库唯一的预校验方法、与 `TryApply` 共用 `Evaluate(spec)`，扩到 `AbilityElements` 就要回答「`Remove` 不足算不算 `Fail`」，而那与既有失败语义表（可选缺失、不阻断整批）正面矛盾——改它等于改全库每一条 `Remove` 的语义，代价远超本形态。
2. **在 `profile-service` 的门面上补一条只读持有查询**（若当前门面尚无等价方法则新增；形态与既有 `bool Has(CapabilityFlag)` / `bool HasGrantable(...)` 同款）：

   ```csharp
   bool Holds(AbilityCarrierKind kind, AbilityScope scope, string abilityId);   // 未持有 = false，非错误
   ```

   Exchange 屏用它驱动 barter 格的灰显，与「买不起 → 灰显但支付要求保持可见」同一条呈现纪律。
3. **提交路径上补一条门面级前置拒绝**：barter 提交时若 `Holds(...) == false` → `ApplyResult.Fail`（**业务失败，绝不抛**），不组装 spec、不进 `TryApply`。这与 `UseItemOutOfCombat` 的处置逐字同构——「门面在组装前查一次持有与剩余次数，不足 → `ApplyResult.Fail`；element 层那条『可选缺失 + `PushWarning` + 空操作』是**防御位**，正常链路不可达」。**`Remove` 的全局失败语义因此一字不改。**
4. **`ApplyResult.MissingElement` 是 `CostKey`，装不下一个 `AbilityId`** ⇒ barter 的失败**不复用**它；UI 的「差哪一样」提示由 barter 格自己的支付要求承载（那件法宝的名字本就恒在格上可见），不新增字段。

#### 3e. 加载期校验（坏数据在启动期大声失败）`[既有推演]`

追加到 `exchange/common-properties.md` 的校验表：

| 违规 | 处置 |
|---|---|
| `BarterRule.PayItemId` 经 ContentRegistry 解析不到，或不是 `ItemData` 且 `Scope == Character` | `PushError`（带 `EventId` + 规则序号）——支付面仅法宝一族，与售出准入同一条代码级常量 |
| `BarterRule.PayItemId` 的条目 `ExclusiveSource != null` | `PushError`——该条目只能由指定渠道给出，把它编排成支付物即要求玩家先走完那条渠道，是无法满足的编排 |
| `BarterRule.GoodsId` 解析不到，或与 `GoodsKind` 对应的仓储 / `Scope` 不匹配 | `PushError`（悬空 Id 会污染存档，与 `DeckChangeElement.Id` 同档） |
| `PayItemId == GoodsId` | `PushError`（换回自己，空交易） |
| 同一条目内两条 `BarterRule` 的 `PayItemId` 相同 | `PushError`——支付物买完即售罄，第二条恒不可达 |
| `eventType != Exchange` 而 `BarterRules` 非空 | `PushError`（与 `ExchangeSpec != null` 那条同款） |

**`GoodsId` 不受「成员卡不从散牌产出侧发放」排除**：那条只约束**散牌产出侧的抽取池**，barter 是点名给出、不经池，与「`TargetId` 指定定值的编排不受影响」同一判据。

#### 3f. 运行期校验与呈现 `[既有推演]` / `[通行做法]`

| 情形 | 语义 | 处置 |
|---|---|---|
| 兑换时 `barterOffer.SoldOut == true` | 业务失败 | `OpResult` 拒绝 + `PushWarning`（正常路径已灰显） |
| 提交时不持有 `PayItemId` | 业务失败 | 门面 `ApplyResult.Fail`，绝不抛（见 3d.3） |
| 产出目标已持有（能力族） | 可选缺失 | `PushWarning` + 空操作（barter 不经取池 ⇒ **没有「已排除已持有」这一层**，须在 UI 侧同样灰显，见下） |

- **呈现（`ux/screen-flow.md` 的 Exchange 屏）：** barter 格与普通 offer 同一网格、同一纵向滚动，价格位改为**支付物的图标 + 名称**（不是数字 + 币种）。不持有 ⇒ 灰显、支付要求保持可见、点按给一条说明「你需要 <某物>」（走 `EVENT_` 普通分区的翻译键，**不占 `ERR_` 前缀**——本地业务拒绝，没有后端 `code`）。**兑换须就地二段确认**：它不可逆地损失一件持有物，与储物袋售出同一条判据（购买不确认是因为损失的是可再获得的货币，barter 损失的是一件具体法宝）。
- **`SoldOut` 后保留占位并标「已换」**，与售罄 offer 同款。
- **日志一行：** `[Exchange-Barter] offer=<OfferId> pay=<PayItemId> goods=<GoodsId> kind=<GoodsKind>` ——**不带 `currency` / `balanceAfter`**，barter 不动货币。

#### 3g. 不受影响的面（明写，防止 derive 时被误改）`[既有推演]`

定价表 · 两条折扣通道 · `SellRatePercent` / `PackSellRatePercent` 两档回收率 · 刷新机制与它的池前置 · 档位供需三道闸 · 「交易不产生统计依赖」 · NPC / 势力不建数据模型——**barter 一条都不触碰**。它只在既有的「浏览 → 买若干件 → 离开」流程里多一类可点的格子。

## 具体形态（可 derive 的落地面）

判 **A** ⇒ 落地面 = 一句正面纪律 + 三条编辑（见 §2 末），无字段、无 schema、无迁移。

判 **B** ⇒ 落地面汇总：

| 面 | 增量 |
|---|---|
| 内容模板 | `ExchangeSpec.BarterRules: ExchangeBarterRule[]`（新类，三格：`PayItemId` / `GoodsKind` / `GoodsId`） |
| 物化 / 存档 | `EventOption.BarterStock: BarterOffer[]`（新 record，六格）⇒ **bump schema 版本**（空迁移） |
| spec 组装 | `Remove(Item, Character, PayItemId, Source.ExchangeSell)` + 既有产出 element（`Source.ExchangePurchase`）；`PairKey` 留空 |
| 服务门面 | `bool Holds(AbilityCarrierKind, AbilityScope, string abilityId)`（只读，未持有 = `false` 非错误）+ barter 提交路径的门面级前置拒绝 |
| 枚举 | **零增量**（不新增 `Source` 成员、不动 `ExchangeGoodsKind` / `EventOutcome` / `AbilityChangeOp`） |
| 加载期校验 | 六条（见 3e） |
| 运行期校验 | 三条（见 3f） |
| UX | Exchange 屏新增 barter 格形态 + 就地二段确认 + 一个 `EVENT_` 翻译键 |
| 平衡数值 | **零增量**——barter 不读定价表、不产生货币，无新旋钮 |
| 后端 | **零配合**（`Source` 值域已含两个成员；`EventOption` 的 schema bump 走既有通道） |

## 后果

- **判 A：** `exchange/` 两份文档各加一句正面纪律；`open-questions.md` derive 队列第 18 步解除对本项的排除，四个非战斗子类型可整批 derive。08-26 handoff 的措辞需回改（见张力 ④）。零字段、零 schema、零后端。
- **判 B：** 触及 `exchange/_index.md` · `exchange/common-properties.md` · `services/profile-service.md`（门面加一行 + 一条前置）· `ux/screen-flow.md`（Exchange 屏）；**存档 schema bump 一次**（`EventOption` 增一格，当前无线上存档 ⇒ 空迁移）；`systems/common-properties.md` 的 `Source` 表**无需改动**（`ExchangeSell` 的语义描述可加一句「含以物易物的支付侧」）。derive 队列第 18 步须在两份文档改写完成后才能跑。
- **两种判法都不动** 定价表、双币不可兑换纪律、两档回收率的硬校验、`CanAfford` 的既有语义与 `Remove` 的全局失败语义。

## 备选方案（已考虑并否决）

- **C —— 估价式换购（玩家从储物袋任选若干件抵扣价款）。** 否决：它需要一条「玩家侧持有物折算成价款」的规则，而那**就是一条事实汇率**——一件以仙玉计价的法宝若能抵扣以灵石计价的商品，两币不可兑换当场破裂；即便强制同币折抵，它也只是把「售出 + 购买」两步做进一个界面，换来一套多选 UI + 一条新折算率旋钮，收益为零。同币回收「不产生事实汇率」是承重（`systems/character-profile/currency.md`）。
- **新增 `Source.ExchangeBarter` 成员。** 否决：成员名与 code 双双永久冻结，而 `ExchangeSell`（支付侧）+ `ExchangePurchase`（产出侧）的组合语义精确、合法子集表当场成立、零冻结风险。
- **在 `ExchangeStockRule` 上加 `PayItemId`。** 否决：一条 stock rule 产出 `SlotCount` 个同族 offer，而支付物必须逐 offer 定稿——形状对不上（见 3a）。
- **把 `CanAfford` 扩展到读 `AbilityElements`。** 否决：改它即改全库每一条 `Remove` 的失败语义（可选缺失 → 阻断整批），代价远超本形态；`UseItemOutOfCombat` 已给出「门面前置查一次 + element 层留防御位」的现成同构解（见 3d）。
- **新增一个 `PlotCondition.Kind = HoldsAbility` 来门控「持有信物才出现该分支」。** 否决（**在本问题范围内**）：它是一条独立的剧本门控能力，与 Exchange 的支付侧无关；顺手加进本方案会把一个交易机制问题扩成剧本求值链的改动。若确需叙事型以物易物，它应作为独立问题提出（见「前置依赖」）。
- **让 barter offer 在玩家不持有支付物时不出现在库存里。** 否决：库存在物化时掷定并落存档、恢复即读结果、绝不重走取池链；按运行时持有面过滤会让同一个 `EventOption` 在两次进入之间呈现不同内容，与「产出即定稿」正面冲突。

## 与既有决策的张力

① **`CanAfford` 的定义 vs barter 的「换得起」。** `CanAfford` 只看资源 element、且被明写为**唯一**预校验方法。B 引入了第二种「付得起」概念。本方案不松动它——改在门面层加只读查询 + 前置拒绝（3d）。**代价明写：** Exchange 屏的灰显判据从此有两条来源（`CanAfford` 管货币格、`Holds` 管 barter 格），而不再是一条。若用户认为「灰显判据必须唯一」是承重，则 B 不成立，应判 A。

② **`Remove` 目标不在持有列表 = 可选缺失（不阻断整批）。** 这条全局语义在 barter 路径上会直接开出白送漏洞。本方案不改它（改动面是全库每一条 `Remove`），改在门面前置拦截。**代价明写：** 该保护落在门面而非 element 层 ⇒ 任何绕过门面直接组装 barter spec 的调用方都能触发白送。这与 `UseItemOutOfCombat` 承担的是同一类风险，处置也相同（正常链路不可达 + `PushWarning` 防御位），但风险确实存在。

③ **「Exchange 只承载交易机制，商品的内容定义归各自子树」。** B 会让 Exchange 第一次持有**指向内容条目的定值引用**（`PayItemId` / `GoodsId`）——此前 Exchange 只持有抽取规则，从不点名任何条目。它不违反那条判据（「这条信息在游戏里没有商店时是否仍然存在？」→ 「这家店要拿 X 换 Y」不存在 ⇒ 归 Exchange 侧），但它确实是一个新的形态类别，值得在文档里明写。

④ **08-26 handoff 已把这句口语当作既定前提用过一次。** `handoffs/2026-08-26-storage-pack-two-layer-view-and-combat-holdings.md` 的「两档回收率的论证基底」两处写着「Exchange event 的形态是以物易物或资源换取道具」。**若判 A，这两处措辞须回改为「以资源换取道具」**——否则它会作为一份影子承载留在库里，下一次读到的人会再次以为存在一种未落地的形态（本次待答项正是这样产生的）。**回收率的两档结论本身不受影响**：它真正依赖的是「大部分可随售的法宝在商店里并不提供回收」（`SellEnabled` 首批以 `false` 为常态），与以物易物是否存在无关。本草稿不执行该回改，落笔归 `/analyze-new-ideas`。

## 前置依赖

- **本方案的形态面不依赖任何未答项。** 定价表数值、两币获取渠道均**不阻塞**本题：barter 不读定价表、不产生货币；它们只影响「一笔 barter 划不划算」的手感校准，那本就归内容扩充后的统计校准。
- **若判 B 且真正想要的是「NPC 索要信物」的叙事桥段：** 它需要一条**持有向的事件 / 分支门控**，而 `PlotCondition.Kind` 五值中没有这一向，且事件选择面明写不做付得起校验、不设灰态。本方案**不臆造**这条门控。该缺口若确实存在，应作为独立问题另行提出——它与 Exchange 的支付侧形状是两件事。
- **derive 队列耦合：** `open-questions.md` 第 18 步（四个非战斗子类型整批 derive）已明写 `exchange/` 须排除本项。判 A ⇒ 当场解除；判 B ⇒ 该步须等两份 exchange 文档 + `profile-service.md` 改写完成。

## 仍需用户决定

**（1 项 · 真取向：产品形态，无客观最优）**

**Exchange 是否需要「定值以物易物」这一交易形态？**

| 选项 | 后果 | |
|---|---|---|
| **A — 判为口语说法，按「以资源换取」收口** | 零字段、零 schema、零后端；`exchange/` 加一句正面纪律后立即可 derive。**放弃的东西**：写不出「这位商贾只收一件特定法宝」的桥段；玩家想拿这件换那件仍需「卖 + 买」两步，且只在 `SellEnabled == true` 的少数商店可行。 | **← 推荐** |
| **B — 落地定值以物易物** | 按 §3 落地：内容模板加一个类、`EventOption` 加一格（bump schema · 空迁移）、服务门面加一条只读查询 + 一条前置拒绝、九条校验、Exchange 屏加一类格子；`Source` / `ExchangeGoodsKind` / 定价表 / 双币纪律全部零增量。**换来的**：商店可点名索要一件持有物、一步完成兑换。**代价**：Exchange 屏的灰显判据从一条变两条；barter offer 在玩家不持有支付物时恒灰（B 无法回避这一点，见 §2 第二条）。 | |
| ~~C — 估价式换购~~ | 已否决（制造事实汇率，与两币不可兑换正面冲突）。 | ✗ |

**推荐 A 的理由（三条，均为既有推演而非偏好）：**
1. **玩法增量近乎为零。** 「卖 + 买」两步已在同一家商店内、同一条价值线内闭合地表达了以物易物；B 的净增量是「省一次点击 + 商店可点名」。
2. **B 的内容形态天然是死格。** 支付物必须定稿 ⇒ 玩家大概率不持有 ⇒ 恒灰显，而 `ux/screen-flow.md` 已明写「恒真的不可用项不出现、不留灰占位」。B 因此还要额外回答一个两边都不好看的问题（出现即恒灰占位 / 不出现即库存随持有面浮动，后者违反「产出即定稿」）。
3. **叙事上真正想要的那半在别处。** 「NPC 索要信物」的价值全在剧情门控，而 `PlotCondition` 五值无持有向 ⇒ B 落地后仍写不出那个桥段。

**若用户判 B，§3 已给出可直接 derive 的完整落地面，无需再问第二轮。**

→ **已裁决（2026-08-28 · 批量评审）：选项 B —— 落地定值以物易物。** 用户原话：**「可以是货币，或者玩家持有的轮回级物品」**。

裁决口径（写给 `/analyze-new-ideas`，提炼时以此为准，优先级高于本草稿正文的推荐项）：

- **支付侧为二选一，而非以 barter 取代货币**：一个 offer 的支付侧要么是**一条货币 `ChangeElement`**（现状，不变），要么是**一件点名的轮回级持有物**。两种形态并存，不互相替代。
- **「轮回级」= `AbilityScope.Character`**，与「可售出 ⟺ `Kind == CharacterItem`」同一族；账号级持有物（法则 / 古宝等 `Scope == Player` 的条目）**不得**作为支付侧——它跨轮回，拿它换一次性收益会把账号级资产变成轮回级消耗品。
- 因此 §3 的 `Remove(Item, Character, PayItemId, Source.ExchangeSell)` 形态**照原样采纳**，其余落地面（`ExchangeSpec.BarterRules` · `EventOption.BarterStock` · 六条加载期 + 三条运行期校验 · `PairKey` 留空 · Exchange 屏 barter 格与就地二段确认 · 一个 `EVENT_` 键）一并采纳。
- **§2 那条会白送商品的漏洞的堵法是强制项，不是可选项**：`profile-service` 门面新增只读 `bool Holds(AbilityCarrierKind, AbilityScope, string abilityId)` + barter 提交路径的门面级前置拒绝；**不扩 `CanAfford`**。
- **随裁决被接受的两项代价**（本草稿已如实列出，用户在知悉后仍选 B）：① Exchange 屏灰显判据从一条变两条（`CanAfford` 管货币格、`Holds` 管 barter 格）；② barter offer 在玩家不持有支付物时恒灰，与 `ux/screen-flow.md`「恒真的不可用项不出现、不留灰占位」张力仍在 —— **这一条须在提炼时给出明确处置**（建议：barter 格按 `Holds` 结果决定是否呈现，属呈现层过滤、不动已物化的库存数据，从而不违反「产出即定稿」）。
- **derive 队列耦合随之确定**：第 18 步须等 `exchange/` 两份 + `profile-service.md` 改写完成后才能跑（不是当场解除）。
- **张力 ④ 反向失效**：`handoffs/2026-08-26-storage-pack-two-layer-view-and-combat-holdings.md` 那两处「以物易物或资源换取道具」的措辞**无须回改**——判 B 后它成为如实表述。
