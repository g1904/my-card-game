# Exchange 支付侧二选一：货币，或一件点名的轮回级法宝

- id: 2026-08-30-exchange-barter-support
- date: 2026-08-30
- topic: systems/adventure-event/exchange · systems/services/profile-service · systems/services/future-event-service · ux/screen-flow · systems/common-properties
- status: distilled
- distilled-to: systems/adventure-event/exchange/_index.md、systems/adventure-event/exchange/common-properties.md、systems/adventure-event/common-properties.md、systems/services/profile-service.md、systems/services/future-event-service.md、systems/common-properties.md、systems/character-profile/_index.md、ux/screen-flow.md、terminology.md

## Intent（distilled）

「Exchange 是以物易物或资源换取道具的场景」这句口语此前在本库**零承载**：`ExchangeOffer` 的支付侧只有一格 `Currency`，`ExchangeStockRule` 五格全部服务于产出侧抽取，`CanAfford` 不读任何持有面。它被裁为**落地**：支付侧由「恒为一条货币 element」放宽为**二选一**。

### 1. 支付侧二选一，两形态并存

一个 offer 的支付侧要么是一条货币 `ChangeElement`（现状不变），要么是**一件点名的轮回级法宝**（定值以物易物 / barter）。**「轮回级」= `AbilityScope.Character`**，与「可售出 ⟺ `Kind == CharacterItem`」同一族；账号级持有物（法则 / 古宝）不得作支付侧——它跨轮回，拿它换一次性收益会把账号级资产变成轮回级消耗品。

### 2. 模板与物化：两个新类型，与既有形态平级

`ExchangeSpec.BarterRules : ExchangeBarterRule[]`（三格：`PayItemId` / `GoodsKind` / `GoodsId`）· `EventOption.BarterStock : BarterOffer[]`（六格 record）⇒ `EventOption` 增一格 ⇒ **bump 存档 schema**（当前无线上存档 = 空迁移）。

**不往 `ExchangeStockRule` 加 `PayItemId`**（一条 stock rule 是若干个同族槽位，支付物必须逐 offer 定稿，形状对不上）；**不往 `ExchangeOffer` 加 barter 字段**（`Currency` / `BasePrice` / `ListPrice` 三格会在 barter 行上恒无意义，而「某些行上恒为空」正是分列判据）。

barter **不进抽取池、不掷 `RngStream.Shop`、不受 `RarityFilter` 影响、不参与档位供需闸 ① 与三道短缺闸、不参与刷新**；`BarterStock` 由 `BarterRules` 逐条平移得出。

### 3. 白送漏洞的堵法是强制项

直接把 barter spec 交给 `CanAfford` 会**静默通过**（它只看 `Op == Add && BaseValue < 0` 的资源 element），而提交时「`Remove` 目标不在持有列表」是可选缺失（`PushWarning` + 空操作、不阻断整批）⇒ 产出侧照常发放，玩家白拿。

堵法：**`profile-service` 门面新增只读 `bool Holds(kind, scope, abilityId)` + barter 提交路径的门面级前置拒绝**（`false` → `ApplyResult.Fail`，绝不抛）。**不扩 `CanAfford`**——扩了就要回答「`Remove` 不足算不算 `Fail`」，等于改全库每一条 `Remove` 的语义。element 层那条可选缺失是防御位，正常链路不可达；与 `UseItemOutOfCombat` 逐字同构。

### 4. 呈现

barter 格与普通 offer 同网格同滚动，价格位改为**支付物图标 + 名称**；**不持有 → 灰显、支付要求保持可见、点按给一条 `EVENT_` 说明**；兑换须**就地二段确认**（不可逆地损失一件具体法宝）；换出后保留占位并标「已换」。

### 5. `Source` 新增一个成员

**`Source.ExchangeBarter = 10`**，只允许 `Op == Remove` 且 `(Item, Character)`。合法子集表加一行（法则 / 古宝 / 神通 ❌，法宝 ✅）；校验扩一格（`Op == Grant` 且 `Source == ExchangeBarter` → `PushError` + 整批拒绝）。产出侧照常 `ExchangePurchase`，如实记账为「从商店取得」。

## 已接受的代价

- **Exchange 屏的灰显判据从一条变两条**（`CanAfford` 管货币格、`Holds` 管 barter 格）。两条各自单点、互不交叠，但「预校验只有一个方法」这句话不再为真。
- **白送保护落在门面而非 element 层** ⇒ 绕过门面直接组装 barter spec 的调用方仍能触发。与 `UseItemOutOfCombat` 同一类风险、同一种处置。
- **Exchange 第一次持有指向内容条目的定值引用**（`PayItemId` / `GoodsId`）——此前它只持有抽取规则、从不点名任何条目。归属判据（「这条信息在没有商店时是否仍然存在」）不受影响。

## Clarifications（interview 产物）

- **不持有支付物时 barter 格的呈现 → 灰显 + 支付要求保持可见 + 点按给一条 `EVENT_` 说明。** 推翻裁决口径里那条括注建议（「按 `Holds` 结果决定是否呈现」）——按运行时持有面过滤呈现，正是草稿在备选方案里点名否决的那一项，否决理由针对的恰恰是呈现（同一个 `EventOption` 在两次进入之间呈现不同内容）。**判据是「恒真 vs 可变」**：玩家是否持有某件法宝是可变状态，故落在「买不起 → 灰显」一侧。`ux/screen-flow.md` 里「古宝无售出键 —— 恒真的不可用项不出现」那条括注**原样成立、未改**。裁决口径中「barter 恒灰、张力仍在」这句**不成立**（张力实际不存在），故未作为被接受的代价写进活文档。
- **barter 支付侧 → 新增 `Source.ExchangeBarter = 10`，不复用 `ExchangeSell`。** 推翻草稿 §3c 的明确否决。三条理由：① 分野判据是「谁组装出这条 element」，barter 由独立的 barter 提交路径组装，与售出流程不是同一条组装路径；② `PackSell` 单列用的正是同一条反面论证（复用会让「在商店里卖了几件」算不准），barter 一枚货币都不动却记成卖给商店，会让同一维度第二次算不准；③ 草稿把「名与 code 永久冻结」当成不新增的理由，而库内已写明冻结恰恰是「宁细勿粗」的理由——细了成本恒为零，粗了要补回来老数据无法回填。`ExchangeSell` 的语义描述**未改**。
- **草稿 targets 漏了四份必改文档，本次补上**：`systems/character-profile/_index.md`（`BarterStock` 承载 + 读档校验第 5 条明写只约束 `ExchangeStock`）· `systems/services/future-event-service.md`（物化伪码的权威在此）· `terminology.md`（新领域词汇登记）· `systems/adventure-event/common-properties.md`（快照判据一句）。

## Open questions

- **新增 0 条。** 草稿的两项「前置依赖」均不新开条目：barter 划不划算的手感校准归内容扩充后的统计校准（与既有待答项重合）；「NPC 索要信物」的持有向剧本门控（`PlotCondition.Kind` 五值无持有向）属独立问题，本次不臆造。

## 决策(-> ADR)

- **ADR 候选一条：** 「Exchange 支付侧二选一：货币或点名的轮回级法宝（定值以物易物）」—— 权威已在 `systems/adventure-event/exchange/_index.md`，立档归 `/write-adr`。
