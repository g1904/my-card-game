# ADR-0046 — `Rejected` 原因复用 verify 终态 `code`，不新造取值集、不进错误体

- **状态：** Accepted
- **日期：** 2026-09-06
- **来源：** handoffs/2026-09-06-iap-channel-integration.md · answer-logs/log-iap-channel-integration.md

## 背景

`GET /v1/purchase/receipt/{receiptId}` 是补查通道：一张收据可能处于 `Rejected`，客户端需要知道为什么。给「为什么」找一个表示面时有两条明显的路——新造一组原因取值，或者把它做成错误。

## 决策

`Rejected` 时以**应答体普通字段 `code`** 给出原因，取值恒为该收据**最近一次 verify 的终态 `code`**（⊂ { `purchase.receipt_invalid`, `purchase.receipt_claimed` }），另附可选 `detail`。

**不新造取值集、不给 `contracts/envelope.md` §6 台账加行、不放进错误体。** 该端点仍是纯读、幂等、不产生任何写入。

见 `contracts/purchase.md` §4。

## 理由

本次请求本身是成功的——**收据状态是数据，不是错误**；放进错误体与端点「纯读、幂等」的定位相抵。

取值域取 §6 台账既有条目的**子集**而非新枚举：只有这两条 `code` 能把记录置为 `Rejected`。新造一组取值就是同一事实的两套表示，与台账构成第二权威，客户端还要再建一张映射表。

## 备选方案

- 新造独立的 `Rejected` 原因取值集 — 同一事实两套取值集，与 §6 台账构成第二权威。
- 放进错误体、让补查直接回错误 — 本次请求成功，且与端点的纯读定位相抵。

## 后果

- `envelope.md` §6 台账零新增行，客户端处置**零新增**（仅知会）。
- 它是「错误码台账单一权威」在读端点上的一次执行；`ADR-0013` 定的是唯一性与读己所写，不覆盖本判据。
- 同批把 `status` 三值统一为 PascalCase `{ Unknown, Verified, Rejected }`，属 `envelope.md` §2 既有枚举约定的机械执行，不单独立档。
