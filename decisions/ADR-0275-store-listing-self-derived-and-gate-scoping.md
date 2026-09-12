# ADR-0275 — 在售系列清单由内容层自给、`productId` 机械变换；购买入口前置条件表按作用域重排两段并加三行

- **状态：** Accepted
- **日期：** 2026-09-12
- **来源：** handoffs/2026-09-12-premium-character-series-unlock.md · answer-logs/log-premium-character-series-unlock.md

## 背景

商店要展示「有哪些付费系列在售」。最直觉的做法是开一个下发通道让后端把在售清单推下来 —— 但那会新增一个端点、一份需要与内容层对账的下行数据，并把内容编排知识复制到边界另一侧。同时，购买入口的既有五条前置条件是为单一 SKU（premium bundle）写的，多 SKU 之后「Store 入口能不能开」与「这个商品能不能买」被混在同一张表里。

## 决策

**在售系列清单由内容层自给：** 对 `AllIncludingDisabled<CharacterData>()` 按 `SeriesId` 归组，取 `Track == Paid`、不在 `entitlement.CharacterSeries` 内、且落在在售窗口内的那些。**走 `AllIncludingDisabled()` 而非 `AllEnabled()`。**

**`productId` 由 `SeriesId` 经机械变换拼出**，客户端**不硬编码任何 `productId` 字面量、不持任何映射表**；变换规则本身的权威在 `backend-design-documents/contracts/purchase.md`，本库不复述规则文本。

⇒ **零新增端点、零新增下发通道、零新增内容字段**（`SeriesId` 一格两用）。

**购买入口前置条件表按作用域重排为两段**：全局段管 Store 入口本身，per-SKU 段管某一个商品能不能买。**既有五条一条不删、语义一字不改**，新增三行：**6**（该 `SeriesId` 不在 `entitlement.CharacterSeries` 内）· **7**（该系列全部条目当前 `ContentEnabled == true`）· **8**（当前时刻落在在售窗口内），并加一列标作用域。

表格本体（逐条条件、适用 SKU、不满足时的处置与文案键）的权威在 `systems/monetization.md`（**本 ADR 不复述**）。

## 理由

`systems/monetization.md`：**走 `AllIncludingDisabled()` 是承重的** —— flags 秒关一个角色不应让整个系列从商店里消失。该情形由前置条件 7 置灰承接，玩家看到的是「本系列暂不可购」而不是「这个系列凭空没了」。用 `AllEnabled()` 会让一次运营止血动作在商店里表现为商品蒸发。

机械变换而非映射表：一张 `SKU → seriesId` 的映射表若由客户端持有，就是内容编排知识的第二份副本，两份各自漂移而本库无发现机制（`decisions/ADR-0005-knowledge-thin-reference-layer.md` 的副本判据）。

两段化的必要性：多 SKU 之后，「未登录」这类条件挡的是整个入口，「已拥有」这类条件只挡一个商品。混在一张无作用域的表里，实现方无从判断某条不满足时该灰掉哪个控件。

## 备选方案

- **后端下发在售清单** — 否决：新增端点与下行通道，且把内容编排知识复制到边界另一侧。
- **客户端持 `productId` 映射表** — 否决：同上，第二权威。
- **用 `AllEnabled()` 推导在售清单** — 否决：flags 秒关一个角色会让整系列从商店消失。
- **前置条件表不分段，只追加三行** — 否决：不满足时该灰整个入口还是灰一个商品，表本身答不出。

## 后果

- 在售窗口作为过滤条件之一进入本推导 → `decisions/ADR-0276-paid-series-sale-window.md`。
- 三条 per-SKU 灰态说明走 `STORE_UNAVAILABLE_SERIES_OWNED` / `_PARTIAL` / `_WINDOW`，**不占 `ERR_` 前缀**（它们是本地业务拒绝，没有后端 `code`）→ `ux/error-and-blocking-ux.md`。
- 对侧承接：`productId ↔ seriesId` 变换规则、SKU 表上架窗口字段与窗口外购买请求的拒绝语义 → `backend-design-documents/handoffs/2026-09-12-premium-character-series-unlock.md`。
