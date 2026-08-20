# ADR-0024 — 平台内购三渠道纳入 MVP

- **状态：** Accepted
- **日期：** 2026-08-15
- **来源：** handoffs/2026-08-15b-monetization-entitlement-purchase-shape-and-scope.md

## 背景

premium bundle 的**兑现段**可以纯客户端演算（见 `decisions/ADR-0023-premium-entitlement-and-redemption.md`），但**购买段**必须唤起平台内购。这是客户端唯一必须引入第三方 SDK 的地方，牵动 Godot 导出配置与各平台构建——它在不在 MVP 内，直接决定第一个可玩版本的工程面有多大。

## 决策

**premium bundle 端到端纳入 MVP**：支付接入（**Google Play Billing / App Store / 微信支付**三渠道）+ Store 屏 + 购后兑现。

配套的范围边界：

- **定价起步单一 SKU、单一价格档**；金额属发行侧，**不落客户端**（价格与货币由平台商店按 SKU 返回，客户端不硬编码任何金额）。**地区定价在范围之外**。
- **SDK 选型与封装层形态不在本库定稿**——归后端的支付渠道选型与一次专门的客户端工程蓝图。
- **唤起内购失败（用户取消 / SDK 失败）一律回主菜单**，无任何 Profile 变更、无痕迹。

范围表述见 `vision/scope.md`「MVP」与「范围之外（暂时）」；客户端侧的时序见 `systems/monetization.md`。

## 理由

- **三渠道对应既定的平台优先级**（移动端优先 → 微信 / QQ 其次 → 海外与跨平台最后，见 `vision/scope.md`），少任何一个都会让某一主要平台上的唯一付费点不可用。
- **多档 SKU 会立刻牵出「哪档给什么」的内容编排**，而内容池规模尚未明朗——故起步单一 SKU。
- **本方案的时序不受 SDK 形态影响**：验票由后端向平台校验、写入只由 verify 承担，客户端这一侧只需要「唤起 → 拿收据 → 上行 → pull 到新序号」。故选型可以推迟而范围可以先定。

## 备选方案

- **把支付接入推迟到 MVP 之后** — 否决：兑现段与 `PlayerEntitlement` 已在 MVP 内成型，购买段缺席会让唯一付费点端到端不可用，且日后补入时要重做 Store 屏与导出配置。
- **首发只做一到两个渠道** — 否决：与既定平台优先级冲突，会在某一主要平台上留下一个不可用的入口。
- **多档 SKU / 地区定价** — 否决：牵出内容编排问题（哪档给什么），而内容池规模未明朗。

## 后果

- 客户端因此有一处第三方 SDK 依赖，牵动 Godot 导出配置与各平台构建——这是 MVP 工程面里唯一的此类项。
- 条件编译清单有一次**已预告的、有边界的扩张（5 → 6）**：新增第四个窄接口 `IPurchaseBackend`（其失败语义——用户取消 / 订单待处理 / 票据重复 / 跨设备重复到账——与 `IProfileBackend` 完全不同）。**本次不新增接口**，裁决点留到真正需要它的时候。
- 合规面（实名 / 防沉迷 / 渠道分成 / 退款）归后端与合规侧；**客户端不读年龄、不做任何本地拦截**，只承接后端 `code` 展示对应 `ERR_*` 文案。
- 影响文档：`vision/scope.md`（权威，范围口径）· `systems/monetization.md` · `systems/architecture.md`（条件编译清单的预告扩张）· `ux/screen-flow.md`（Store 屏）。跨库：`backend-design-documents/contracts/purchase.md`。
