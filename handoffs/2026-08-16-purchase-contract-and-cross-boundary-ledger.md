# 购买域契约（第五份）与跨边界承接台账

- id: 2026-08-16-purchase-contract-and-cross-boundary-ledger
- date: 2026-08-16
- topic: contracts/purchase（新建）· contracts/profile-sync（§2 §5 后端写入字段表 + 白名单补行）· contracts/_index（四份 → 五份）· open-questions/cross-boundary（新建）
- status: distilled
- distilled-to: `contracts/purchase.md`、`contracts/profile-sync.md`、`contracts/_index.md`、`open-questions/cross-boundary.md`、`open-questions/01-contracts.md`、`open-questions.md`、`open-questions/update-log.md`、`answer-logs/log-cross-library-alignment.md`、`README.md`
- counterpart: `game-design-documents/handoffs/2026-08-16b-cross-library-alignment-and-bridge-ledger.md`

## Intent（distilled）

**一句话：购买域单开第五份契约 `contracts/purchase.md`（验票端点 + 收据幂等读），「后端只读」那条承重纪律松动为一张封闭两行表，并新立 `open-questions/cross-boundary.md` 装「客户端已定案、本库尚未承接」的条目。**

客户端已定案：购买由后端验票，验票通过后后端把云端 `bundleGrantOrdinal` 与 `cloudRevision` 各 +1，客户端称之为同步模型此前没有的第四种情形——后端主动写入。本库对此零承载。（另两处失配欠在客户端侧，本库不重复设计，见 counterpart。）

### B1. 单开第五份，不塞进 `profile-sync`

三条理由：**域不同**——`profile-sync` 的承重纪律（后端对透明段只读、后端不裁决、复算不拒绝）**恰恰全部不适用于购买**（后端权威写入、必须裁决、必须能拒绝），两套相反的纪律塞进一份契约，读者无法判断哪条管哪个端点；`_index.md` 的分域惯例本就按域切；它牵动平台 SDK 与渠道回调，独立成文才让那条耦合显式可见。

文件命名取 `purchase.md`（按域命名，与既有四份同形）。否决 `entitlement.md`——本域主体是验票流程，权益本身的形态归客户端。

### B2. 两个端点

`POST /v1/purchase/verify`（提交平台收据 → 后端向平台校验 → 通过则两个计数各 +1，回新序号与新 `revision`）与 `GET /v1/purchase/receipt/{receiptId}`（幂等读，纯读不产生写入）。

**第二个端点是承重的，不是可选便利**：客户端在「已付款、后端已 +1、但响应丢失」这一移动网络常态下必须有一条查得回来的路径。幂等键是平台收据 id——天然全局唯一、由平台发放，无须客户端生成。**同一 `receiptId` 重复提交绝不重复 +1**，直接回上次结果；缺这一条，网络重试会让玩家序号跳号、掷骰序列错位。

**渠道回调只作对账 / 补偿通道，不作写入路径。** 回调时序不可控（可能早于、晚于、或永不到达客户端的 verify），作为写入路径会让「已付款但序号未涨」无处排查，且要额外处理回调与 verify 的竞态——而那条竞态的收益仅在「客户端崩溃且从不回来」这一场景。写入只由 verify 承担；回调记账与补偿任务落 `operations/`。

### B3. 与 CAS 共存：不新增机制

客户端已用时机纪律在结构上关掉了冲突窗口（购买前待发队列必为空 ⇒ 那一刻没有任何未上行的变更）。后端只需三条声明：两个计数的自增与 `revision` 自增在**同一次事务**内；verify **不接受 `baseRevision`、不做 CAS 判定**（它是后端权威写入，不是客户端提交的 diff）；**verify 的应答只回序号 + revision，不内联新 profile**——客户端另发一次 pull，两侧形态因此一致，且让 verify 保持窄接口，不与 profile 的下行形态耦合。

### B4 / B5

`/entitlement/bundleGrantOrdinal` 按同形态补进 §5 透明字段白名单的预留行（客户端落点已定）。购买段的复算**共用 §6 已定义的 SplitMix64**（`PremiumBundle` 域早已冻结为 `stream = 1`），购买契约不定义任何新随机源，只回链；复算不一致的处置沿用「接受写入 + 打风控事件」，不为购买单开更严的处置——真正需要严格把关的是验票那一步，而它由平台校验兜住。

### D. 跨边界承接台账（本库侧）

机制设计、病因诊断与维护者分工见 **counterpart 的 D 段**（不重复写，避免第二权威）。本库只记落点与首批条目：新增 `open-questions/cross-boundary.md`，只装「客户端已定案、本库尚未承接」的条目，只回链不复述。首批一条即购买段——由本次同批关闭。

## Clarifications（interview 产物）

本次无新增澄清项：四项取向已由用户于 2026-08-16 逐条定案（松动获准并采封闭两行表 · 文件命名 `purchase.md` · verify 应答不内联 profile · 渠道回调只作对账）。跨库唯一的实现形态分叉（客户端的最小随机源接口）落在 counterpart，与本库契约无关。

## Notes / triage

「契约面四份齐备，无第五份」这一断言在三处成文（`contracts/_index.md`、`profile-sync.md` §1、`README.md`），本次一并改写为五份。它当初排除的是已撤销的剧本契约，没有预见到购买段。

## Open questions

- **verify 的 `receipt` 字段内部形态与渠道错误码映射** —— 待 `02-account-compliance.md` 的「自建 vs 接第三方」。**不阻塞** B1 / B3 / B4 / B5 与四条服务端保证（它们与渠道无关）。
- **幂等记录的存储、事务边界的实现、对账与补偿任务的落点** —— 全部归 `06` 落 `operations/`，**不回头改契约**。

## 客户端侧影响

本 handoff 改动客户端 ↔ 后端边界的语义，受影响的客户端成分是 **`sync-service`**（新增一条后端主动写入的通道对位）与商业化侧的购买流程。客户端侧的对位改动已在同批的 counterpart 中落笔：`/entitlement/bundleGrantOrdinal` 的 JSON path 确认、`monetization.md` 与 `sync-service.md` 的回链、以及**购后 pull 失败 = 阻塞在主菜单重试**（其重试路径正是本库的收据幂等读端点）。**本库不代为决定客户端的阻塞形态**，只保证那条查询通道存在且幂等。
