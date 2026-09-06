# barter 灰态在灰态判据表与键清单里的补位

- id: 2026-09-05-barter-grayed-state-keys
- date: 2026-09-05
- topic: ux/error-and-blocking-ux.md
- status: distilled
- distilled-to: ux/error-and-blocking-ux.md

## Intent（distilled）

Exchange 屏的 barter（以物易物）格在两种情形下灰显，这两条呈现结论在库内已定（`decisions/ADR-0126-exchange-barter-payment.md` 的「不持有支付物 → 灰显而非不呈现」，`systems/adventure-event/exchange/common-properties.md` 的「产出目标已持有（能力族）⇒ UI 侧须同样灰显」），而**灰态的权威文档 `ux/error-and-blocking-ux.md` 对它零承接**：判据表只有四行、没有 barter 行；表下那条列举说明文案键的要点也没有 barter 键。`systems/adventure-event/exchange/_index.md` 把键回链到了一份并不持有它的文档，`/derive-requirements` 写「点按给一条说明」这条验收标准时无处可查。

本次是**一次补位落笔**：不改任何已定判据、不新增机制。

### 判据表补两行

1. **Exchange 商店买不起 → 灰显但价格保持可见。** 它是 barter 行自陈「逐字同构」的那个对照物，此前同样缺席；说明由 `ApplyResult.MissingElement` 机械映射到币种，**不手写第二张表、零新增键**。
2. **Exchange 的 barter 格：不持有 `PayItemId`，或产出目标已持有（能力族）。** 置灰 + 支付要求（图标 + 名称）保持可见 + 点按一行说明；不隐藏、**不按持有面过滤呈现**。判据同「恒真 vs 可变」：是否持有某件法宝是可变状态（轮回内可买到、可由事件产出、可售出），故落在灰显一侧，而非储物袋「古宝无售出键」那种恒真不可用。

**两条触发条件写成一行而非两行**：呈现、判据、驱动源（同为只读 `Holds(...)`）、说明通道四项全同，只有说明句不同；现表既有写法（礼包入口一行吃掉四条前置）即同一处理，逐条的键仍分开给。

### 两个 `EVENT_` 普通键

| 触发条件 | 键 |
|---|---|
| 不持有 `PayItemId` | `EVENT_BARTER_UNAVAILABLE_NOT_HELD` |
| 产出目标已持有（能力族） | `EVENT_BARTER_UNAVAILABLE_ALREADY_OWNED` |

形态取自库内全部四个既有灰态说明键的共同像 `<分区>_<CONTEXT>_UNAVAILABLE_<原因>`（`STORE_UNAVAILABLE_POOL` / `_SYNC` / `_PENDING`、`EVENT_REROLL_UNAVAILABLE_POOL`），逐条过键命名规范三条。`<CONTEXT>` 取 `BARTER`（与 `REROLL` 指刷新按钮同一层级），**不取 `EXCHANGE`**——`EVENT_` 分区已隐含事件界面，再嵌一层事件类型名会让 `EVENT_EXCHANGE_*` 与 `EVENT_REROLL_*` 两种嵌套深度并存。两个键都**不占 `ERR_` 前缀**（本地业务拒绝，没有后端 `code`），`ERR_` 的反向审计不受影响。

两个键都只承载框架句；支付物 / 产出物的名称是内容层 `LocalizedText`，由呈现层以格式参数插入，绝不写进 `event.csv`。

### 灰态是视觉降级，不是禁用

灰格**必须继续接收触控**，否则「点按给一条说明」这条纪律会被一个 `Button.Disabled = true` 静默取消——Godot 的 disabled 控件不发 `pressed`，症状是「点了没反应」，一种线上不可见的失败。形态：降低饱和度 / 透明度表达不可用，触控接收位与可用格完全一致，触控目标尺寸不缩水。同一条对既有的「买不起」格与 Exchange 刷新按钮同样成立。

### 零增量的面（防止 derive 时被误改）

`Holds(...)` 签名与语义不动 · `CanAfford` 不动 · `ApplyResult` 不新增字段 · `BarterOffer` / `ExchangeBarterRule` 字段面不动 · 存档 schema 与 `schemaVersion` 不动 · `ERR_` 分区与三条审计不动 · 分区表不新增分区 · 后端零配合。

## Clarifications

- **是否在同一次落笔中一并补上「Exchange 商店买不起 → 灰显」那一行 → 一并补（用户裁决，原选项 A）。** 增量 = 判据表一行 + 一句「说明由 `ApplyResult.MissingElement` 机械映射到币种，不手写第二张表」，零新增键。理由：两行是同一处漂移的两半，barter 行自陈「与买不起逐字同构」本就假定了对方在表内。
- **判据表写一行而非两行**（标准默认）：两条触发条件的呈现 / 判据 / 驱动源 / 说明通道四项全同。
- **`<CONTEXT>` 取 `BARTER` 而非 `EXCHANGE`**（标准默认）：避免 `EVENT_` 分区出现两种嵌套深度。
- **「灰格必须继续接收触控」写进文档**（标准默认）：兑现既定的「点按给一条说明」与「无 hover-only 可供性」。
- **`EVENT_` 分区行的覆盖描述不扩容**（标准默认）：保持本次声明的改动面；`EVENT_REROLL_UNAVAILABLE_POOL` 未被覆盖描述提及是既有缺口，不因本次新增而恶化。

## Open questions

- **两个键的实际中文措辞待文案定稿**——与 `ux/error-and-blocking-ux.md` 待决区既有的「四条兜底文案与各 `ERR_*` 的实际措辞」同属内容充实，不阻塞结构落地。
- **「已换」/「已售」占位标签键**（`EVENT_BARTER_TRADED` / `EVENT_OFFER_SOLD_OUT` 是自然形态）不是灰态说明、不进判据表，宜随 Exchange 屏的 FR 落地时补齐。
