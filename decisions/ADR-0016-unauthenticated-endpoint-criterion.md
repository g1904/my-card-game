# ADR-0016 — 免鉴权是一条判据，不是一份名单：「调用它的玩家此刻不可能持有 access token」

- **状态：** Accepted
- **日期：** 2026-08-16
- **来源：** `handoffs/2026-08-16c-compliance-contract-and-session-arbitration.md` · `handoffs/2026-08-13-auth-endpoint-contract.md` · `answer-logs/log-compliance-and-session-arbitration.md`

## 背景

`contracts/envelope.md` §4a 原本以点名方式圈出免鉴权范围（「例外仅限 auth 域」）。合规域成文后立刻出现第二批够格的端点——被 `signin` 的合规拦截挡在门外的玩家手里没有 access token，却必须能提交实名、能撤销注销。点名式护栏在第二个域出现时只能靠改名单，而**改名单的人不必论证自己够不够格**。

## 决策

**一个端点可以免带 `Authorization`，当且仅当调用它的玩家此刻不可能持有 access token。** 凭据因此只能在 body 里随请求送达。

按此判据，例外域有**两个**：

| 例外域 | 免鉴权的端点 | 玩家此刻为什么没有 token |
|---|---|---|
| auth | `challenge` · `signin` · `refresh` | 尚未登录；`refresh` 的存在前提就是 access token 已失效 |
| compliance | `POST /v1/compliance/realname` · `DELETE /v1/compliance/deletion` | 被 `signin` 的合规拦截挡在门外，凭 `complianceTicket` 认账号 |

其余端点一律全带，**包括合规域自己的另外四个端点**。`X-Content-Version` 同样只在这两个域缺省；`X-Request-Id` 无例外。

判据、例外表与逐端点例外 → `contracts/envelope.md` §4a、`contracts/auth.md` §6。

## 理由

判据把「够格」变成一次**必须通过的检验**，而名单不会。检验立刻产生了一个反例并挡住了它：`GET /v1/compliance/status` **同属合规域却不够格**——能查合规态的玩家已经登录成功了（`contracts/envelope.md` §4a）。这正是名单式护栏会放过的那一类，也是它必须被判据取代的证据。

判据同时限定了凭据的位置：既然玩家没有 token，凭据只能在 body 里随请求送达——`complianceTicket` 因此**一次性、10 分钟、单端点、不进 `Authorization`**（`contracts/compliance.md` §3）。

## 备选方案

- **保留「例外仅限 auth 域」的枚举式名单，合规域到来时追加两行** — 追加者不必论证够格，第三个域到来时同样。名单会单调增长而无人守门。
- **把 `complianceTicket` 放进 `Authorization`** — 它不是 access token，混用会让鉴权中间件对两种完全不同的凭据走同一条路径。
- **给被拦截的玩家签发 scope 受限的 access token** — 为一个域引入整套 scope 授权维度，而双 token 私有模型刻意没有它。
- **合规端点全部免鉴权（整域例外）** — `GET /v1/compliance/status` 与另外三个端点的调用者已经登录，白送一个无鉴权读口。

## 后果

- 日后任何新端点要免鉴权，**必须先通过这条检验**并在 §4a 的例外表里说明「玩家此刻为什么没有 token」；说不出即不够格。
- 例外表是判据的**当前解**而非定义——判据不变时表可增行，表变了不等于判据被推翻。
- `complianceTicket` 的一次性 / 时效 / 单端点绑定是本判据的直接连带：既然它替代 `Authorization` 认账号，它就必须比 access token 更窄。
- 合规域六端点自身的报文字段表与错误码仍未落笔（`open-questions.md`「最短解锁路径」第 1 条），本判据只定它们的鉴权面。
- 会话裁决、拦截落在 `signin`、合规域独立成文属 `ADR-0011`；CDN 域三端点无鉴权是另一条独立事实（静态、内容寻址），权威在 `contracts/content-manifest.md`，不由本判据推出。
