# ADR-0274 — 付费角色系列的购买段整体复用，兑现段整段不存在；跨启动补入口两条即闭合，购后不阻塞开新轮回

- **状态：** Accepted
- **日期：** 2026-09-12
- **来源：** handoffs/2026-09-12-premium-character-series-unlock.md · answer-logs/log-premium-character-series-unlock.md

## 背景

premium bundle 立下的购买形态是「购买段后端权威 + 兑现段客户端演算」（`decisions/ADR-0023-premium-entitlement-and-redemption.md`）：客户端掷 `AccountRng` 抽出内容、`TryApply` 落账、用一个兑现水位向云端记账，并在待兑现期间阻塞「开始新轮回」。付费角色系列是本库第二个付费点 —— 它是照抄这套，还是另有形态，必须正面答，否则会照抄出一整套没有对象的机制。

## 决策

**购买段一格不改地复用**（`StoreChannelManager` / `IStoreChannel` / `UnavailableStoreChannel` / `IPurchaseBackend`），**兑现段整段不存在**。

授予即后端写入 `/entitlement/characterSeries`，pull 下来就是终态 ⇒ 客户端在本付费点上**零 `TryApply`、零 `AccountRng`、零兑现水位、零「差值 > 1」异常路径**；空池三道闸 / `GrantPoolMargin` / `K` 一概不适用（无内容抽取）。

**跨启动补入口两条，都不依赖云端水位，合起来即闭合：** ① 本地持久化的 `receiptId` + 收据幂等读；② 每次启动的商店初始化时查询平台未完成交易并补验票（Google Play Billing 与 StoreKit 2 的标准形态，兜住卸载重装 / 换设备 / 清缓存）。**无需第三条。**

**购后 pull 失败不阻塞「开始新轮回」。** 本付费点没有未兑现状态，未到账的最坏后果是几个角色暂时选不到。**premium bundle 的阻塞纪律一字不改**，只是不再被读作全部付费点的通则 —— `systems/monetization.md` 已在原文处加上限定词。

失败处置沿用既有五情形表、不新增情形；`IPurchaseBackend` 的三个应答 record 随对侧按 SKU 类别分形同批调整，**接口方法签名不变**。

## 理由

`systems/monetization.md`：**兑现水位存在的唯一理由是「发货动作在客户端，需要一个云端可见的已发货记号」。** 本付费点的发货在后端 —— 验票成功那一刻货已在云端，水位没有对象可记。照抄一个 `CharacterSeriesRedeemedOrdinal` 因此是最诱人的错误答案（同一论证见 `decisions/ADR-0270-player-entitlement-character-series.md`）。

阻塞纪律同理：它保护的是「客户端还欠玩家一次发货」这个状态。本付费点不存在该状态，阻塞就成了无因的惩罚。

形态上与外观族的 `Cosmetic` 先例逐字同构（`decisions/ADR-0193-cosmetic-ownership-versus-equipped-split.md`），不是新发明的第三种购买形态。

## 备选方案

- **照抄 premium bundle 的兑现段（含水位与阻塞）** — 否决：水位无对象、阻塞无因，凭空复制一整套异常路径。
- **加第三条跨启动补入口（如云端待发货查询）** — 否决：前两条已闭合，第三条是纯冗余且需要新端点。
- **购后 pull 失败也阻塞开新轮回** — 否决：最坏后果只是几个角色暂时选不到，代价与惩罚不匹配。

## 后果

- 本付费点使 premium bundle 的阻塞纪律**从通则降为个例**：`systems/monetization.md` 的原文处已加限定词「只适用于存在客户端兑现动作的付费点」。
- `ux/error-and-blocking-ux.md` 与 `ux/screen-flow.md` 的「待兑现态」措辞靠术语隐含区分两个付费点（premium bundle 的「待兑现态」vs 本付费点的「`receiptId` 待结清态」）；两处若要显式对齐限定词，是一次纯措辞订正。
- 对侧承接：验票报文与幂等 / 事务语义、`verify` / `GET receipt` 应答按 SKU 类别分形 → `backend-design-documents/handoffs/2026-09-12-premium-character-series-unlock.md`。
