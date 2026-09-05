# ADR-0126 — Exchange 支付侧二选一：货币，或一件点名的轮回级法宝

- **状态：** Accepted
- **日期：** 2026-08-30
- **来源：** handoffs/2026-08-30-exchange-barter-support.md

## 背景

「Exchange 是以物易物或资源换取道具的场景」这句口语此前在本库**零承载**：`ExchangeOffer` 的支付侧只有一格 `Currency`，`ExchangeStockRule` 五格全部服务于产出侧抽取，`CanAfford` 不读任何持有面。「拿这件换那件」只能依赖「在同一家 `SellEnabled` 商店里先卖后买」两步绕行。

## 决策

**一个 offer 的支付侧二选一：一条货币 `ChangeElement`（现状不变），或一件点名的轮回级法宝（定值以物易物 / barter）。两种形态并存，一种不排除另一种**——绝大多数 offer 仍是货币交易，barter 是内容作者点名编排的少数格子。

**「轮回级」= `AbilityScope.Character`**，与「可售出 ⟺ `Kind == CharacterItem`」同一族；**账号级持有物（法则 / 古宝）不得作支付侧**。

两个新类型与既有形态平级：`ExchangeSpec.BarterRules : ExchangeBarterRule[]`（`PayItemId` / `GoodsKind` / `GoodsId`）与 `EventOption.BarterStock : BarterOffer[]`（六格 record）。barter **不进抽取池、不掷 `RngStream.Shop`、不受 `RarityFilter` 影响、不参与档位供需闸与三道短缺闸、不参与刷新**。

**白送漏洞的堵法是强制项**：`profile-service` 门面新增只读 `bool Holds(kind, scope, abilityId)` + barter 提交路径的门面级前置拒绝（`false` → `ApplyResult.Fail`，绝不抛）。**不扩 `CanAfford`。**

**`Source` 新增成员 `ExchangeBarter = 10`**，只允许 `Op == Remove` 且 `(Item, Character)`；产出侧照常记 `ExchangePurchase`。字段面、九条校验与呈现细节见 `systems/adventure-event/exchange/_index.md` 与 `exchange/common-properties.md`。

## 理由

- **不往 `ExchangeStockRule` 加 `PayItemId`**：一条 stock rule 是若干个同族槽位，而支付物必须逐 offer 定稿，形状对不上。**不往 `ExchangeOffer` 加 barter 字段**：`Currency` / `BasePrice` / `ListPrice` 三格会在 barter 行上恒无意义，而「某些行上恒为空」正是本库既定的分列判据。
- **白送漏洞是真的**：直接把 barter spec 交给 `CanAfford` 会静默通过（它只看 `Op == Add && BaseValue < 0` 的资源 element），而提交时「`Remove` 目标不在持有列表」是可选缺失（`PushWarning` + 空操作、不阻断整批）⇒ 产出侧照常发放，玩家白拿。
- **不扩 `CanAfford`**：扩了就要回答「`Remove` 不足算不算 `Fail`」，等于改全库每一条 `Remove` 的语义。element 层那条可选缺失是防御位、正常链路不可达；门面级前置拒绝与 `UseItemOutOfCombat` 逐字同构。
- **账号级持有物不得作支付侧**：它跨轮回，拿它换一次性收益会把账号级资产变成轮回级消耗品。
- **`Source` 取新成员而非复用 `ExchangeSell`**：① 分野判据是「谁组装出这条 element」（`decisions/ADR-0051-grant-source-and-exclusive-source.md`），barter 由独立的提交路径组装；② `PackSell` 单列用的正是同一条反面论证——barter 一枚货币都不动却记成卖给商店，会让同一维度第二次算不准；③ 「名与 code 永久冻结」恰恰是本库「宁细勿粗」的理由——细了成本恒为零，粗了要补回来而老数据无法回填。
- **不持有支付物 → 灰显而非不呈现**：判据是「恒真 vs 可变」。是否持有某件法宝是**可变状态**，故落在「买不起 → 灰显 + 价格保持可见」一侧；按运行时持有面过滤呈现会让同一个 `EventOption` 在两次进入之间呈现不同内容。`ux/screen-flow.md` 里「古宝无售出键——恒真的不可用项不出现」那条括注因此原样成立。

## 备选方案

- **支付侧恒为货币，以物易物靠「先卖后买」两步** — 否决：这句口语的零承载正是本条要关的空档；两步绕行还要求同一家商店 `SellEnabled`。
- **按 `Holds` 结果决定 barter 格是否呈现** — 否决：见理由的「恒真 vs 可变」判据。
- **扩 `CanAfford` 使其读持有面** — 否决：牵动全库每一条 `Remove` 的失败语义。
- **复用 `Source.ExchangeSell`** — 否决：见理由三条。

## 后果

- `EventOption` 上的 `BarterStock` 一格属 `schemaVersion` 1，登记见 `systems/services/profile-schema-versions.md`。
- **灰显判据从一条变两条**：`CanAfford` 管货币格、`Holds` 管 barter 格。两条各自单点、互不交叠，但「预校验只有一个方法」这句话不再为真。
- **白送保护落在门面而非 element 层** ⇒ 绕过门面直接组装 barter spec 的调用方仍能触发。与 `UseItemOutOfCombat` 同一类风险、同一种处置。
- **Exchange 第一次持有指向内容条目的定值引用**（`PayItemId` / `GoodsId`）——此前它只持有抽取规则、从不点名任何条目。
- 兑换须**就地二段确认**（不可逆地损失一件具体法宝），换出后保留占位并标「已换」。
- **零增量的面（防止 derive 时被误改）**：`ExchangeGoodsKind` / `EventOutcome` / `AbilityChangeOp` 不动 · 定价表与两条折扣通道不动（barter 不读定价表）· 两档回收率不动 · `Remove` 的全局失败语义不动 · 平衡数值零增量 · **后端零配合**。
- 因此必须这么写的文档：`systems/adventure-event/exchange/_index.md` · `exchange/common-properties.md` · `systems/adventure-event/common-properties.md` · `systems/services/profile-service.md` · `systems/services/future-event-service.md` · `systems/common-properties.md`（`Source` 合法子集表加一行）· `systems/character-profile/_index.md` · `ux/screen-flow.md` · `terminology.md`。
