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
| `CultivationTechnique` | `CultivationTechniqueData` 仓储 | `DeckChangeElement(LearnTechnique, Id, Tier = 1)` |
| `CharacterItem` | `ItemData` 且 `Scope == Character` | `AbilityChangeElement(Grant, Item, Character, id, Source.ExchangePurchase)` |
| `CharacterPower` | `PowerData` 且 `Scope == Character` | `AbilityChangeElement(Grant, Power, Character, id, Source.ExchangePurchase)` |
| `PlayerItem` | `ItemData` 且 `Scope == Player` | `AbilityChangeElement(Grant, Item, Player, id, Source.ExchangePurchase)` |

- **一笔 `Card` 族交易的完整 spec** = `ChangeElement(Jade, -ListPrice, Add)` + 上表那一条 `DeckChangeElement`，落在同一次提交内。
- **法则 `(Power, Player)` 不在族内**——`Source` 合法子集表对 `ExchangePurchase × (Power, Player)` 是 ❌，规则层本就不允许它。
- **`PlayerItem` 在规则层开放，首批内容不编排**：合法子集表那一格是 ✅，但灵玉不用来铺开购买账号级古宝——那是内容口径，不是规则限制。
- **取池链沿用授予池那一条，不另写一段：**

  ```
  AllEnabled() → 按 Kind 映射到对应仓储 → 排除 ExclusiveSource != null → 排除已持有（能力族）
  → RarityFilter 过滤 → 按 RarityTier 权重表 PickMany(shopRng, SlotCount)     // 无放回
  ```

  `PickMany` 无放回是既定契约 ⇒ **同一批库存内不出现重复商品**，这条免费成立、不需要新规则。

### 模板侧：`ExchangeSpec` 与 `ExchangeStockRule`

```csharp
[GlobalClass]
public partial class ExchangeSpec : Resource          // AdventureEventData 上 Exchange 专有的一格；非 Exchange 条目为 null
{
    [Export] public ExchangeStockRule[] StockRules      { get; set; }   // 库存槽位规则；空 → 加载期 PushError
    [Export] public int                 RerollBaseCost  { get; set; }   // 刷新基价（jade）；0 = 本条目不可刷新
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

### 物化侧：`ExchangeOffer`

```csharp
public sealed record ExchangeOffer(          // 定稿商品实例：immutable，随 EventOption 落存档
    string            OfferId,               // 本 Exchange 实例内唯一；购买 / 售罄标记按它定位
    ExchangeGoodsKind Kind,
    string            ContentId,             // 溯源内容条目；展示文案按它现取模板（文本不物化）
    int               TechniqueTier,         // 功法层数；其余族为 0
    int               BasePrice,             // 定价表算出的基准价（未施加偏移、折扣与 modifier）
    int               ListPrice,             // 实际标价 = 定稿价
    bool              SoldOut);              // 购买后置位
```

- **落在 `EventOption.ExchangeStock` 上**，与 `RerolledCount` 一同构成 Exchange 的两个物化字段。骨架见 `systems/services/future-event-service.md`。
- **文本一律不进快照**：显示名 / 描述 / 图标由 UI 按 `ContentId` 现场取模板组装。
- **`BasePrice` 与 `ListPrice` 都存**：前者是售出折算与诊断的基准，后者是玩家看到并实际支付的数。两者都是物化产出，重算不保证同结果。

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
| 定价表某格缺失 | 启动期 `PushError`（同 `ResourceElements` 表的全成员断言） |

**档位供需的核算口径 = 逐 `Kind` 逐 `RarityTier` 档位（承重）：**

```
对每个 Kind 的每个 RarityTier 档位：
    Σ SlotCount（该条目内 RarityFilter 覆盖该档位的全部规则）+ ExchangePoolMargin
        ≤ 该 Kind 该档位过滤后的池条目数
```

- **不按「同 `Kind` + 同 `RarityFilter` 完全相同才合并」核算**：两条 `RarityFilter` 分别为 `[Tier1, Tier2]` 与 `[Tier2, Tier3]` 的规则同样抢同一批 Tier2 条目，按「完全相同才合并」会各自单独判、**放过一个真实的短缺编排**，而闸 ① 的存在理由就是机械化的硬保证。
- **也不按 `Kind` 取并集合并**：并集足够而某单档不足时判不出，方向偏保守但同样漏。逐档位核算精确、无漏无误报，实现是一次分组求和，落在加载期不计成本。
- **`ExchangePoolMargin` 必须存在，不能只断言「≥ Σ`SlotCount`」**：能力族取池链含**排除已持有**，池随玩家推进单调收缩，一个恰好等于所需的静态池在轮回中段必然短缺。取值归 `systems/balance.md`。
- **这是一条有意的收紧**：编排更容易在启动期失败，而当前内容存量为零 ⇒ 落地代价为零，晚做则每多一个 `.tres` 多一份返工。
- **池计数口径不含储物袋满袋过滤**——满袋是购买前置校验的拒收，不是库存侧过滤（见 `systems/character-profile/item/_index.md`）。

### 运行期校验

| 情形 | 语义 | 处置 |
|---|---|---|
| 购买时 `offer.SoldOut == true` | 业务失败 | `OpResult` 拒绝 + `PushWarning`（正常路径已灰显，到达此处说明 UI 与状态不同步） |
| `CanAfford` 为 false 仍提交 | 业务失败 | `ApplyResult.Fail(MissingElement = Jade)`，绝不抛 |
| 售出的目标不是 `CharacterItem` | 必需缺失（代码组装缺陷） | `PushError` + 拒绝（准入是代码常量，到达此处即调用方缺陷） |
| `Grant` 目标已持有 | 可选缺失 | `PushWarning` + 空操作（取池已排除已持有，出现即内容错误） |
| 购买 `PlayerItem` / `CharacterItem` 且储物袋约束不满足 | ⟨阻于「储物袋满袋处理」待答项⟩ | — |
| 某条 `StockRule` 抽到 `0 < n < SlotCount` | 可选缺失 | `PushWarning` + want / got；**该规则产出 n 个 offer，不补位、不用别族顶替** |
| 某条 `StockRule` 抽到 0 条 | 可选缺失 | 同上；该规则贡献 0 个槽位，其余规则照常 |
| 整店 `ExchangeStock` 为空 | 必需缺失（取池期前置本应拦住） | `PushError` + 上报，该条目本次不进批次 |

- **短缺处置的层次、取池期前置（闸 ②）与三道闸的分界判据归 `systems/services/future-event-service.md`**；本处只记 Exchange 侧的逐情形行为。
- **短缺不给玩家任何提示、不新增文案键**（reroll 按钮的池前置置灰是另一个界面元素，见 `_index.md`）。玩家看到的就是一个商品少一点的店，它与内容作者编排出的小店在观感上无法区分。
- **快照只记实际结果：** `EventOption.ExchangeStock` 的长度就是实际抽到的 offer 数（可 < Σ`SlotCount`），**不新增「期望数量 / 短缺标记」字段**——期望值在模板的 `SlotCount` 上随时读得到。**推论：一个因池收缩而少给的商店，退出重进后仍然少给**，即便此刻 flags 已把条目放回来；这是防重掷纪律要的行为（恢复即读结果，绝不重走取池链）。

### 日志（沿用 `[System-Method]` 约定）

```
[Exchange-Purchase] offer=<OfferId> content=<ContentId> price=<ListPrice> jadeAfter=<n>
[Exchange-Sell]     item=<ItemId> base=<BasePrice> rate=<SellRatePercent> jadeAfter=<n>
[Exchange-Reroll]   event=<InstanceId> count=<n> cost=<c>

[ContentRegistry-Validate]  exchange pool short: event=<EventId> kind=<ExchangeGoodsKind> rarity=<RarityTier> need=<ΣSlotCount+margin> pool=<n>
[FutureEvent-ExchangeStock] instance=<InstanceId> event=<EventId> rule=<i> kind=<Kind> want=<n> got=<m>
```

Source: `handoffs/2026-08-17d-exchange-mechanics-and-transaction-discipline.md` · `handoffs/2026-08-17g-element-carrier-gaps.md` · `handoffs/2026-08-19-pickmany-shortfall-handling.md`

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- 见 `_index.md`。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **各字段的数值取值**（定价表每格、刷新价参数、回收率、槽位总数上界）归 ch1 数值标杆专场。→ `systems/balance.md`。

## 对应
提炼至：`.claude/knowledge/systems/adventure-event/exchange.md`（待建）
