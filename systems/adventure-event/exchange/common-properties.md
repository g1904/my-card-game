# adventure-event / exchange / common-properties（Exchange 子类型共有属性）

> Exchange 类 AdventureEvent 专有的字段面：模板侧的库存 / 定价 / 刷新 / 售出规则，物化侧的定稿商品实例，以及两侧的校验。顶层共有属性见 `../common-properties.md`；商品的内容定义见各自的内容子树，本处不重复。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

### 商品族 `ExchangeGoodsKind`：既有抽取池的一一映射

```csharp
public enum ExchangeGoodsKind { Card, CultivationTechnique, CharacterItem, CharacterPower, PlayerItem }
```

| 族 | 取池来源 | 购买产出的 element |
|---|---|---|
| `Card` | `CardData` 仓储（`Pool != Enemy`） | `DeckChangeElement(AddLooseCard, cardId, Tier = -1)` |
| `CultivationTechnique` | `CultivationTechniqueData` 仓储（`Pool != Enemy`） | `DeckChangeElement(LearnTechnique, Id, Tier = 1)` |
| `CharacterItem` | `ItemData` 且 `Scope == Character` | `AbilityChangeElement(Grant, Item, Character, id, Source.ExchangePurchase)` |
| `CharacterPower` | `PowerData` 且 `Scope == Character` | `AbilityChangeElement(Grant, Power, Character, id, Source.ExchangePurchase)` |
| `PlayerItem` | `ItemData` 且 `Scope == Player` | `AbilityChangeElement(Grant, Item, Player, id, Source.ExchangePurchase)` |

- **一笔 `Card` 族交易的完整 spec** = `ChangeElement(offer.Currency, -ListPrice, Add)` + 上表那一条 `DeckChangeElement`，落在同一次提交内。
- **法则 `(Power, Player)` 不在族内**——`Source` 合法子集表对 `ExchangePurchase × (Power, Player)` 是 ❌，规则层本就不允许它。
- **`PlayerItem` 在规则层开放，首批内容不编排**：合法子集表那一格是 ✅，但货币不用来铺开购买账号级古宝——那是内容口径，不是规则限制。
- **取池链沿用授予池那一条，不另写一段：**

  ```
  AllEnabled() → 按 Kind 映射到对应仓储 → 排除 ExclusiveSource != null（能力族；Card 族无此字段，恒为空操作）
  → Card 族另排除「被任一功法引用的成员卡」 → 排除已持有（能力族）
  → RarityFilter 过滤 → 按 RarityTier 权重表 PickMany(shopRng, SlotCount)     // 无放回
  ```

  `PickMany` 无放回是既定契约 ⇒ **同一批库存内不出现重复商品**，这条免费成立、不需要新规则。
  `ExclusiveSource` 只覆盖 `PowerData` / `ItemData`（见 `systems/common-properties.md`），故它对 `Card` 族恒不生效——成员卡的排除是另一条规则，不由这个字段承载。

### 成员卡不从散牌产出侧发放（承重）

加载期以 `CultivationTechniqueData` 每层的卡牌 `Id` 列表反建一份成员索引，**凡被任一功法引用的卡一律不进散牌产出侧的抽取池**。散牌产出侧包括：`Card` 族商店库存、战后奖励池的 `Card` 部分、以及任何 `AddLooseCard` 走池抽的产出——三处套的是同一份索引。`TargetId` 指定定值的编排不受影响（那是内容作者点名给出的一张卡，不经抽取池）。玩家取得整组成员卡的唯一通道是功法本身：学下一门功法即整组入组。

- **本条只作用于散牌产出侧。** 功法作为**独立族**参与战后奖励池 · 商店 `CultivationTechnique` 族 · 闭关三选一，取的是 `CultivationTechniqueData` 仓储（同样叠 `Pool != Enemy`，见 `systems/character-profile/deck/_index.md`「卡池划分」），与卡牌池无交集，不受本条排除影响。
- **不新增字段。**「这张卡是不是某功法的成员」的唯一权威是功法侧的每层卡牌 `Id` 列表（见 `systems/character-profile/deck/_index.md`）；在 `CardData` 上再加一格即两份表各自漂移，而本库没有机制发现它们不一致——这正是 `systems/common-properties.md` 那条硬边界所禁。一张卡可被多门功法引用 ⇒ 索引是「被任一功法引用」的并集。
- **索引的输入取全量口径 `AllIncludingDisabled()`，不取 `AllEnabled()`。** 成员关系是结构而非抽取池；按抽取池反建会让一门被 flags 关闭的功法把整组成员卡放进散牌池，而 flags 按账号解析 ⇒ 不同账号看到不同的散牌池，且线上不可见。
- **排除不替代 `AllEnabled()`**，两者取交集：`AllEnabled()` 仍是产出侧唯一的取池入口。
- **`CardData.Rarity` 保持必填**；成员卡的 `Rarity` 没有规则消费点（明写）——商店定价表是「商品族 × 稀有度」，`Card` 族读卡牌档、`CultivationTechnique` 族读功法档，而功法档的抽取权重与过滤消费在**战后奖励 / 商店 / 闭关三选一**这三处。改成可空只会给漏填开口子。
- **已知代价（明写接受）：**「既想作某功法的成员卡、又想作散牌发出去」的牌无法表达。
- **游离散牌这一侧不变**：不被任何功法引用的卡保留卡牌级稀有度，照常参与 `Card` 族商店库存与奖励池。

### 模板侧：`ExchangeSpec` 与 `ExchangeStockRule`

```csharp
[GlobalClass]
public partial class ExchangeSpec : Resource          // AdventureEventData 上 Exchange 专有的一格；非 Exchange 条目为 null
{
    [Export] public ExchangeStockRule[] StockRules      { get; set; }   // 库存槽位规则；空 → 加载期 PushError
    [Export] public int                 RerollBaseCost  { get; set; }   // 刷新基价（灵石）；0 = 本条目不可刷新
    [Export] public int                 RerollCostStep  { get; set; }   // 每次刷新的递增量
    [Export] public int                 MaxRerollCount  { get; set; }   // 刷新次数上限；0 = 不可刷新
    [Export] public bool                SellEnabled     { get; set; }   // 该商店是否收购玩家物品
    [Export] public int                 SellRatePercent { get; set; }   // 回收率：按定价表基准价的百分比
}

[GlobalClass]
public partial class ExchangeStockRule : Resource     // 一条规则 = 若干个同族槽位
{
    [Export] public ExchangeGoodsKind Kind            { get; set; }   // 商品族
    [Export] public int               SlotCount       { get; set; }   // 该规则产出几个 offer
    [Export] public RarityTier[]      RarityFilter    { get; set; }   // 空 = 不限（按稀有度权重表抽）
    [Export] public int               PriceOffset     { get; set; }   // 相对定价表的条目级偏移；正数量值，语义由方向承载
    [Export] public int               DiscountPercent { get; set; }   // 该槽的固定折扣（内容侧静态值，风味用）
}
```

- **售出准入不在这两个类型上。** 「哪一族能卖」是代码级常量（恒为 `CharacterItem`），`SellEnabled` 只表达「这家店收不收」、`SellRatePercent` 只表达「几折收」。理由见 `_index.md`。
- **`SellRatePercent` 折算的基准是定价表的基准价，不是 `ListPrice`。**
- **币种不在规则上，取「族 × 稀有度」定价表该格。** `ExchangeStockRule` 与 `ExchangeSpec` 都**不设币种字段**：不给字段就不存在「谁有权用它」的问题，也就不存在一个填错的条目把高阶商品变成基础货币可买、而校验无从判断作者是否故意。定价表的格值形态（币种 + 基准价）见 `systems/balance.md`。

### 物化侧：`ExchangeOffer`

```csharp
public sealed record ExchangeOffer(          // 定稿商品实例：immutable，随 EventOption 落存档
    string            OfferId,               // 本 Exchange 实例内唯一；购买 / 售罄标记按它定位
    ExchangeGoodsKind Kind,
    string            ContentId,             // 溯源内容条目；展示文案按它现取模板（文本不物化）
    int               TechniqueTier,         // 功法层数；其余族为 0
    CostKey           Currency,              // 计价币种，取自定价表该格；物化时定稿
    int               BasePrice,             // 定价表算出的基准价（未施加偏移、折扣与 modifier）
    int               ListPrice,             // 实际标价 = 定稿价
    bool              SoldOut);              // 购买后置位
```

- **落在 `EventOption.ExchangeStock` 上**，与 `RerolledCount` 一同构成 Exchange 的两个物化字段。骨架见 `systems/services/future-event-service.md`。
- **文本一律不进快照**：显示名 / 描述 / 图标由 UI 按 `ContentId` 现场取模板组装。
- **`BasePrice` 与 `ListPrice` 都存**：前者是售出折算与诊断的基准，后者是玩家看到并实际支付的数。两者都是物化产出，重算不保证同结果。
- **`Currency` 同为物化产出**：物化时从「族 × 稀有度」定价表该格抄下，与两个价格一同定稿。**恢复即读，绝不回查定价表重算**——与「产出即定稿、消费侧不得回查模板」同款。购买 spec、售出所得与余额不足的 `MissingElement` 三处一律读它，币种在一件商品的整个生命周期内是同一个。

### 加载期校验（坏数据在启动期大声失败）

| 违规 | 处置 |
|---|---|
| `eventType == Exchange` 而 `ExchangeSpec == null`，或 `StockRules` 为空 | `PushError` + 抛（带 `EventId`） |
| `eventType != Exchange` 而 `ExchangeSpec != null` | `PushError`（带 `EventId`） |
| 某条 `StockRule` 的 `SlotCount <= 0` | `PushError`（带 `EventId` + 规则序号） |
| `StockRules` 的 `SlotCount` 之和超过槽位总数上界 | `PushError`（上界见 `systems/balance.md`） |
| 某个 `Kind` 的某个 `RarityTier` 档位供不应求 | `PushError`（带 `EventId` + `Kind` + 档位 + 实际条目数）——否则会在轮回中途开出一个空商店。判据见下 |
| `MaxRerollCount > 0` 而 `RerollBaseCost <= 0` | `PushError`（可无限免费刷新 = 零成本 reroll 漏洞，与 Travel 定价必须 > 0 同一条理由） |
| `DiscountPercent` 不在 `[0, 100]` | `PushError` |
| `SellEnabled == true` 而 `SellRatePercent` 不在 `[1, 100]` | `PushError` |
| `SellEnabled == true` 且 `SellRatePercent <= PackSellRatePercent`（随售档全局单值） | `PushError`（带 `EventId` + 两个值）——收购价不高于随手卖掉，这家店作为「更优机会」不成立。判据见 `_index.md`「售出」 |
| 定价表某格缺失 | 启动期 `PushError`（同 `ResourceElements` 表的全成员断言） |
| 定价表某格的币种缺失，或不在 `{ SpiritStone, ImmortalJade }` 内 | 启动期 `PushError`（带 `Kind` + 档位）——同一条全成员断言纪律；币种缺失即无从物化 `ExchangeOffer.Currency` |
| 反建成员索引后，存在被任一功法引用的卡 | `PushWarning`：一次性列出被排除的卡 `Id` 与引用它的功法 `Id`，供人工审阅（审阅辅助，非坏数据） |

**档位供需的核算口径 = 逐 `Kind` 逐 `RarityTier` 档位（承重）：**

```
对每个 Kind 的每个 RarityTier 档位：
    Σ SlotCount（该条目内 RarityFilter 覆盖该档位的全部规则）+ ExchangePoolMargin
        ≤ 该 Kind 该档位过滤后的池条目数
```

- **不按「同 `Kind` + 同 `RarityFilter` 完全相同才合并」核算**：两条 `RarityFilter` 分别为 `[Tier1, Tier2]` 与 `[Tier2, Tier3]` 的规则同样抢同一批 Tier2 条目，按「完全相同才合并」会各自单独判、**放过一个真实的短缺编排**，而闸 ① 的存在理由就是机械化的硬保证。
- **也不按 `Kind` 取并集合并**：并集足够而某单档不足时判不出，方向偏保守但同样漏。逐档位核算精确、无漏无误报，实现是一次分组求和，落在加载期不计成本。
- **`ExchangePoolMargin` 必须存在，不能只断言「≥ Σ`SlotCount`」**：能力族取池链含**排除已持有**，池随玩家推进单调收缩，一个恰好等于所需的静态池在轮回中段必然短缺。取值归 `systems/balance.md`。
- **成员卡排除后，`Card` 族的分母只剩游离散牌**：编排了 `Card` 规则的条目更容易被闸 ① 拦在启动期。这同样是一条有意的收紧——它把「散牌池实际有多大」在启动期就摆到内容作者面前，而不是等到轮回中途开出一个空商店。
- **这是一条有意的收紧**：编排更容易在启动期失败，而当前内容存量为零 ⇒ 落地代价为零，晚做则每多一个 `.tres` 多一份返工。

### 运行期校验

| 情形 | 语义 | 处置 |
|---|---|---|
| 购买时 `offer.SoldOut == true` | 业务失败 | `OpResult` 拒绝 + `PushWarning`（正常路径已灰显，到达此处说明 UI 与状态不同步） |
| `CanAfford` 为 false 仍提交 | 业务失败 | `ApplyResult.Fail(MissingElement = offer.Currency)`，绝不抛 |
| 售出的目标不是 `CharacterItem` | 必需缺失（代码组装缺陷） | `PushError` + 拒绝（准入是代码常量，到达此处即调用方缺陷） |
| `Grant` 目标已持有 | 可选缺失 | `PushWarning` + 空操作（取池已排除已持有，出现即内容错误） |
| 某条 `StockRule` 抽到 `0 < n < SlotCount` | 可选缺失 | `PushWarning` + want / got；**该规则产出 n 个 offer，不补位、不用别族顶替** |
| 某条 `StockRule` 抽到 0 条 | 可选缺失 | 同上；该规则贡献 0 个槽位，其余规则照常 |
| 整店 `ExchangeStock` 为空 | 必需缺失（取池期前置本应拦住） | `PushError` + 上报，该条目本次不进批次 |

- **短缺处置的层次、取池期前置（闸 ②）与三道闸的分界判据归 `systems/services/future-event-service.md`**；本处只记 Exchange 侧的逐情形行为。
- **短缺不给玩家任何提示、不新增文案键**（reroll 按钮的池前置置灰是另一个界面元素，见 `_index.md`）。玩家看到的就是一个商品少一点的店，它与内容作者编排出的小店在观感上无法区分。
- **快照只记实际结果：** `EventOption.ExchangeStock` 的长度就是实际抽到的 offer 数（可 < Σ`SlotCount`），**不新增「期望数量 / 短缺标记」字段**——期望值在模板的 `SlotCount` 上随时读得到。**推论：一个因池收缩而少给的商店，退出重进后仍然少给**，即便此刻 flags 已把条目放回来；这是防重掷纪律要的行为（恢复即读结果，绝不重走取池链）。

### 日志（沿用 `[System-Method]` 约定）

```
[Exchange-Purchase] offer=<OfferId> content=<ContentId> price=<ListPrice> currency=<CostKey> balanceAfter=<n>
[Exchange-Sell]     item=<ItemId> base=<BasePrice> rate=<SellRatePercent> currency=<CostKey> balanceAfter=<n>
[Exchange-Reroll]   event=<InstanceId> count=<n> cost=<c>

[ContentRegistry-Validate]  exchange pool short: event=<EventId> kind=<ExchangeGoodsKind> rarity=<RarityTier> need=<ΣSlotCount+margin> pool=<n>
[ContentRegistry-Validate]  technique member cards excluded from loose-card pools: count=<n> ids=<...>
[FutureEvent-ExchangeStock] instance=<InstanceId> event=<EventId> rule=<i> kind=<Kind> want=<n> got=<m>
```

一笔交易只动一种币 ⇒ 买卖两行各记**一个** `currency` + 一个 `balanceAfter`，不并列两个互斥的余额字段。

Source: `handoffs/2026-08-25-currency-split-spirit-stone-and-immortal-jade.md` · `handoffs/2026-08-17d-exchange-mechanics-and-transaction-discipline.md` · `handoffs/2026-08-17g-element-carrier-gaps.md` · `handoffs/2026-08-19-pickmany-shortfall-handling.md` · `handoffs/2026-08-25-numeric-philosophy-and-balance-anchors.md` · `handoffs/2026-08-25-enemy-deck-from-techniques-and-ai.md` · `handoffs/2026-08-26-storage-pack-two-layer-view-and-combat-holdings.md`

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- 见 `_index.md`。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **各字段的数值取值**（定价表每格、刷新价参数、两档回收率、槽位总数上界）留待内容扩充后的统计校准。→ `systems/balance.md`。

## 对应
提炼至：`.claude/knowledge/systems/adventure-event/exchange.md`（待建）
