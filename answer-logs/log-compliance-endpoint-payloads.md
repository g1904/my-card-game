# Answer log compliance-endpoint-payloads

- 日期：2026-09-03
- 来源：`inbox/archive/solution-draft-compliance-endpoint-payloads.md` → `handoffs/2026-09-03-compliance-endpoint-payloads.md`
- 移出条数：1

## 逐条

**`01` —— 合规域端点自身的错误码（随报文本体落笔，非设计未决）** → **答结**

只新增三条码，全 `Fatal`、全映 `OpError.Compliance`：

- `compliance.ticket_invalid`（`reasonKey`：`Expired` / `Consumed` / `Unknown`）
- `compliance.verification_failed`（`reasonKey`：`Mismatch` / `Malformed`）
- `compliance.deletion_irrevocable`（不设 `reasonKey`）

**不新增**的四类，逐条给出复用去向：核验服务不可达 → `server.unavailable`（`Retryable`；混一条可重试进本域会破坏客户端「`Compliance` 档 = 不可重试」的静态推理）· 导出任务不存在 → `resource.not_found` · 任务未就绪不是错误（`200` + `Pending`）· 频次超限 → `rate.limited`。

同批落笔的报文本体（与本条同一次契约变更）：六端点的请求 / 应答字段表 · 共有枚举 `ComplianceRealnameStatus` 四值 · `taskId` 形态 `^[0-9a-f]{32}$` · 导出任务状态机四值 · `downloadUrl` 是外部对象 URL 不进 spec 的 `paths` · 导出产物正列白名单 · 五个新旋钮。

归档去向：`contracts/compliance.md`（§10 报文字段表 · §11 端点自身的错误码 · §2 §3 §4 §5 §8 §9 的连带修订）· `contracts/envelope.md` §6 台账三行与承重表述第三条 · `contracts/envelope.md` §4a 例外表 · `decisions/ADR-0016`（例外表与后果段）· `contracts/_index.md`（compliance 行状态列与完成判据第 2 条的限定句）。

## 同批的用户裁决（非移出项，记录备查）

- **实名 / 撤销成功后如何回到已登录态** → 端点只回状态，客户端重走完整 `signin`。代价：`Phone` 渠道每账号至多一条额外短信。
- **是否下发 `playtimeRemainingSeconds`** → 下发。客户端呈现义务由 `game-design-documents/inbox/solution-draft-backend-batch-client-obligations.md` 承接。
- **撤销注销 `DELETE` → `POST .../cancel`** → 按标准默认采纳（判据不变，改的是例外表的当前解）。
- **`contracts/_index.md` 完成判据第 2 条补限定句** → 按标准默认采纳。

## 仍留在待答清单的部分

`01` 的其余条目不受影响；可信时钟 / 核验服务商 / 导出产物存储与链接签发 / ticket 存储 / 冷静期调度**均归 `06`**，本次未移出。
