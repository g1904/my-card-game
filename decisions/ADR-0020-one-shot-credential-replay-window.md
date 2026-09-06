# ADR-0020 — 一次性凭据的兑付带 60 秒回放窗口：回放不消费、无副作用

- **状态：** Accepted
- **日期：** 2026-09-03
- **来源：** `handoffs/2026-09-03-compliance-endpoint-payloads.md` · `answer-logs/log-compliance-endpoint-payloads.md`

## 背景

`complianceTicket` 是一次性凭据（`ADR-0016` 的直接连带：它替代 `Authorization` 认账号，就必须比 access token 更窄）。但一次性与弱网直接冲突——「请求已达、应答丢失」在移动网络下是常态，客户端持同一 ticket 重试会撞上「已消费」，**而它其实已经成功了**。被合规拦截的玩家此刻手里没有 token，撞死在这里就是被永久挡在门外。

## 决策

**`complianceTicket` 首次兑付成功后的 60 秒内，同一 ticket 原样回放上次应答，不再消费、不产生任何副作用；窗口外再次到达 → `compliance.ticket_invalid` + `reasonKey: "Consumed"`。**

- 窗口值 **60 秒**，与 `refresh` 宽限窗口、`signin` 幂等回放（`ADR-0004`）同值同理由。
- **回放不削弱「一次性」**：回放不消费、无副作用，窗口外即终态。
- 窗口初值与另外四个合规域旋钮 → `contracts/compliance.md` §3 §9。

## 理由

这是 pillar #2「弱网优先：幂等重于优雅」在本域的**第四次兑现**——前三次是 `refresh` 宽限窗口、`signin` 幂等回放、`pushId` 重放（`ADR-0004`）。**四处不是四套机制，而是同一条支柱在四个端点上的兑现**（`contracts/compliance.md` §3）。

窗口取 60 秒的推导与 `ADR-0004` 逐字相同：**须覆盖客户端指数退避的头几次重试**，而它远短于 ticket 自身 10 分钟的寿命，滥用面被「一次性 + 10 分钟 + 单端点」三重夹住之后可忽略。

## 备选方案

- **严格一次性、不设回放窗口** — 一次弱网即把玩家永久挡在合规闸门外，且他手里没有 token、无路可走；与 pillar #2 直接冲突，论证与 `ADR-0004` 否决「裸 rotation」同源。
- **给被拦截的玩家签发 scope 受限的 access token 以替代 ticket** — 为一个域引入整套 scope 授权维度，而双 token 私有模型刻意没有它（`ADR-0016` 已否决）。
- **兑付成功后直接签发 token 对** — 省一条短信，但让 ticket 事实上成为 scope 受限凭据，并造出第二个绕开强更闸门与合规判定的出口（`contracts/compliance.md` §3）。

## 后果

- 服务端必须为 ticket 兑付保留**幂等回放记录**（首次应答 + 消费时刻），与 `refresh` / `signin` / `pushId` 的幂等记录同类；存储形态与保留期归 `operations/` 与 `systems/`，不回头改契约。
- 「一次性凭据为什么允许回放」不再是开放问题——重新提出它等于要求推翻 pillar #2 在本域的兑现。
- 窗口只覆盖**兑付**这一个动作；ticket 的一次性、10 分钟寿命、单端点绑定、不进 `Authorization` 头仍由 `ADR-0016` 承载，本条不放松其中任何一项。
- `compliance.ticket_invalid` 与其 `reasonKey: "Consumed"` 因此是**窗口外**的终态码，而非「重复到达」的即时码 → `contracts/compliance.md` §11、`contracts/envelope.md` §6 台账。
- 玩家可见措辞归客户端（`game-design-documents/ux/error-and-blocking-ux.md`），本库只定 `reasonKey`。
