# Answer log exchange-barter-support

- 日期：2026-08-30
- 来源：`inbox/solution-draft-exchange-barter-support.md`（裁决 2026-08-28；两条落笔口径于 2026-08-30 合并 interview 追裁）
- 移出条数：1

---

**Exchange 是否支持以物易物** → **支持**：落地定值以物易物，**支付侧二选一**——一条货币 `ChangeElement`，或**一件点名的轮回级法宝**（`ItemData` 且 `Scope == Character`）。两种形态并存、不互相取代；账号级持有物（法则 / 古宝）不得作支付侧。

落地面：`ExchangeSpec.BarterRules`（新类三格）· `EventOption.BarterStock`（新 record 六格，bump schema · 空迁移）· 支付侧 `Remove(Item, Character, PayItemId, Source.ExchangeBarter)` + 产出侧既有 `ExchangePurchase` element · `PairKey` 留空 · 六条加载期 + 三条运行期校验 · barter 不进抽取池 / 不掷 `Shop` / 不参与刷新与三道闸 · Exchange 屏 barter 格 + 就地二段确认 + 一个 `EVENT_` 键。

**白送漏洞以门面 `Holds(...)` + barter 提交路径的前置拒绝堵死，不扩 `CanAfford`**（强制项）。

归档去向：`systems/adventure-event/exchange/_index.md`（支付侧二选一的正面纪律）· `systems/adventure-event/exchange/common-properties.md`（模板 / 物化形态 + 九条校验 + 日志）· `systems/services/profile-service.md`（`Holds` 与两层失败语义）· `systems/services/future-event-service.md`（物化平移）· `systems/common-properties.md`（`Source.ExchangeBarter = 10`）· `systems/character-profile/_index.md`（`BarterStock` 承载与读档校验）· `ux/screen-flow.md`（Exchange 屏）· `terminology.md`。

**两条 interview 裁决是本条的组成部分，不单独计数：**

1. **不持有支付物时 barter 格灰显、支付要求保持可见、点按给一条 `EVENT_` 说明** —— 不按持有面过滤呈现（那会让同一个 `EventOption` 在两次进入之间呈现不同内容）。判据是「恒真 vs 可变」：是否持有某件法宝是可变状态。
2. **新增 `Source.ExchangeBarter = 10`，不复用 `ExchangeSell`** —— 按「成员的分野判据 = 谁组装出这条 element」与 `PackSell` 单列的同一条推理；复用会让「在商店里卖了几件」再次算不准。`ExchangeSell` 语义描述未改。

**新增待答项 0 条。**

---

**连带：** `open-questions.md` 的 derive 就绪度小节中 `exchange/` 一行与 derive 顺序第 18 步仍写着「Exchange 是否支持以物易物 —— 待用户拍板」，本次后失真；该小节的唯一写入者是 `/assess-derive-readiness`，故本次不改，留待下一次全量重估。
