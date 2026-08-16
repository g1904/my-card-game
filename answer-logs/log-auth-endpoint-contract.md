# Answer log auth-endpoint-contract

- 日期：2026-08-13
- 来源：`inbox/archive/solution-draft-auth-endpoint-contract.md` → `handoffs/2026-08-13-auth-endpoint-contract.md`
- 移出条数：2

## 移出的条目

**`auth.md` 尚未成文（下一份）：token 生命周期（签发 / 刷新 / 吊销）、登录渠道的报文形态、多设备裁决触发 `auth.session_revoked` 的具体条件**（原 `open-questions/01-contracts.md`）
→ **前两部分答定**：端点集封定为四个（`challenge` / `signin` / `refresh` / `signout`）；**双 token**——自包含 JWT access（15 min）+ 不透明 refresh（30 天滑动、rotation 带 60 秒宽限窗口）；登录报文为 `channel` + 按渠道分形的 `credential`，首版只有「标识符 + 一次性码」与「渠道 authCode」两类形态（`Email` 走验证码、密码后置）。**第三部分（多设备裁决的触发条件）仍留在待答清单**——它归 `02-account-compliance.md` 的并发裁决规则，`auth.md` 已把它收敛为一张待填的 `detail.reasonKey` 取值表，报文形状不受影响。（归档去向：`contracts/auth.md`；`contracts/envelope.md` §4a / §6；`contracts/_index.md`）

**token 失效时正在进行的轮回如何处理——后端侧的失效判定与续期窗口未定**（原 `open-questions/02-account-compliance.md`）
→ **答定**：失效判定 = access token 的 JWT `exp`（15 分钟），过期即 `auth.token_expired`；续期窗口 = refresh token 30 天滑动续期，`POST /v1/auth/refresh` 换取新一对 token，旧 refresh token 在轮换后 **60 秒宽限窗口**内回放同一对结果、窗口外才判泄漏。「正在进行的轮回如何处理」按判据拆为两条路径：**网络失败 → 视同断线走 sync 缓冲通道、不硬阻塞、不回退存档点**（客户端侧 2026-08-09 的原语义一字不变）；**收到 `auth.session_revoked` → 硬阻塞重登 + 暂停退避**。`refresh` 的错误清单因此收紧为两条，使这个判据在报文层面无歧义。（归档去向：`contracts/auth.md` §2 §4 §10；`contracts/envelope.md` §6 承重项）

## 跨边界说明

第二条的裁决**同时松动了客户端语义**：`game-design-documents/systems/services/account-service.md` 的「刷新失败视同断线」按判据拆为两条路径。本 log 只记后端侧结论；**客户端侧的措辞修正需 `game-design-documents/` 另写一份 handoff**（连同其余四点跨库待办，见 `handoffs/2026-08-13-auth-endpoint-contract.md` 的「客户端侧影响」段），届时另记一份客户端侧的 answer log。
