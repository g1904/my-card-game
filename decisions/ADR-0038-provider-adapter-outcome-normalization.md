# ADR-0038 — 外接能力适配层共用 `Outcome` 三档，归一发生在调用方且不新增 `code`

- **状态：** Accepted
- **日期：** 2026-09-06
- **来源：** handoffs/2026-09-06-external-provider-selection-dr.md · answer-logs/log-external-provider-selection-dr.md

## 背景

后端要外接四类原子能力（短信 / 邮件 / 实名核验 / 第三方昵称审核），每类都可能换服务商，每家都有自己的一套错误码。若让服务商的码渗进上层，每换一家就要重读一遍错误码台账。

## 决策

四类能力的适配接口**共用同一套 `Outcome` 三档判别式**（受理 / 明确拒绝 / 不可达），并逐条满足共有形状 A1–A6。其中两条承重：

- **A4** —— 每次外部调用有硬超时，超时归不可达；适配层内**不做应用层重试**（唯一例外是跨供应商 fail-over 的那一次）。
- **A6** —— **适配层不认识 `code`**：它只产出 `Outcome`，归一到 `code` 发生在调用方（端点），构成**单一归一点**。

归一目标集合逐条取自 `contracts/envelope.md` §6 台账，**按调用点所在域取，不新增任何 `code`**；`Outcome` 为不可达时按出参有无 `retryAfter` 二分 `rate.limited` / `server.unavailable`，**不得靠 `providerCode` 分支**。`auth.challenge_expired` 永不来自服务商，不进归一目标集合。

接口签名、A1–A6 与三张映射表见 `operations/external-providers.md`。

## 理由

明确拒绝与服务不可达必须在归一时就分开——把它做进 `Outcome` 的类型层，合并即当场违规。服务商原始码是服务商版本的产物，**任何依赖它的分支都会在服务商更新时静默失效**；这与 `contracts/auth.md` §3a 早已为 `channelCode` 定死的「客户端不解析、只随日志上报」完全同源。

适配层内重试会在下游劣化时放大流量；跨供应商 fail-over 是换目标而非重试，不在此列。

## 备选方案

- 适配层内对外部调用做多次重试 — 下游劣化时放大流量。
- 把服务商原始码放进 `detail` 供客户端分支 — 服务商版本更新时分支静默失效。
- 为「服务商不可达」新增一条 `code` — `server.unavailable` 逐字覆盖，且客户端已有 `Retryable` 处置。

## 后果

- 换服务商是适配器内部的事，端点侧与契约面零改动；本批因此**不新增任何 `code`、不改任何报文字段**。
- `contracts/auth.md` §8 的两处错误清单补列了早已定死但漏写的 `server.unavailable`，属既有事实的补记，不是新增。
- 第三方昵称审核是唯一的结构性例外：它的归一目标不是 `code`，而是判定链的档位（→ `ADR-0044`）。
