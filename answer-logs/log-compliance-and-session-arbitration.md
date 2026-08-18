# Answer log compliance-and-session-arbitration

- 日期：2026-08-16
- 来源：`inbox/archive/solution-draft-compliance-codes-and-reason-keys.md` + `inbox/archive/solution-draft-multi-device-session-arbitration.md`（两份均 `status: decided`，**同批提炼**）→ `handoffs/2026-08-16c-compliance-contract-and-session-arbitration.md`
- 移出条数：2

## 逐条

**`02` —— 合规落地：PIPL / 实名 / 防沉迷 / 渠道审核 / 账号注销 / 数据导出的分支形态与落点** → **答结（分级排期除外）**

拦截落点是**推演的唯一解，不是取向**：`/v1/profile/*` 被 `contracts/profile-sync.md` §11 封死，业务端点撞 `envelope.md` §7b 与 pillar #4，启动 pull 本身即 `/v1/profile/pull` 同样出局——**只剩 `signin`**。据此定下：

- 四条 `compliance.*` 码（`realname_required` / `playtime_blocked` / `account_restricted` / `account_deleting`），全 `Fatal`、全映 `OpError.Compliance`；`restricted` 与 `banned` 共用一个 `code` 靠 `reasonKey` 分辨。
- **`complianceTicket`** 解无 token 态的死锁，用既有的「无鉴权 + body 凭据」先例，不引入 token scope。
- **建号先于合规判定**，拦截不回滚建号（实名不做建号前置——那会造出「半个账号」）。
- **防沉迷时段中途到点复用 `auth.session_revoked`**，access token TTL 卡在时段边界，不新增端点 / 字段 / 客户端路径。
- **新开第六份契约 `contracts/compliance.md`**（六端点），按 `contracts/_index.md` 的分域判据行使——合规域与 auth 域有两条相反的承重纪律（长时状态机 vs 即时判定、不可逆 vs 幂等可重放）。
- 数值：注销冷静期 **15 天** · ticket 寿命 **10 分钟** · 导出保留期 **7 天**；**时段口径不写进契约**，落配置。
- 数据导出**首版必做**，取最简 JSON 形态，不含任何渠道内部键。

归档去向：`contracts/compliance.md`（本体）· `contracts/auth.md` §1a §5a §8 · `contracts/envelope.md` §3 §4a §6 · `contracts/_index.md`。

**仍留在 `02` 的部分：** 合规能力的**上线分级**（哪些必须在首次上线前具备）——它与 `06` 的托管 / 备案排期耦合，不是契约面问题。

---

**`02` —— 多设备并发登录的裁决语义** → **答结**

裁决策略「后登录挤下线」**已被 `auth.md` §2 隐含定案**：§2「窗口内旧设备的 push 由 `revision` CAS 拒绝」那段论证只有在这一裁决下才成立。本次补齐使它得以成立的机制：

- access token 的 JWT claims 含 **`sid`**——没有它，`signout`「吊销当前会话」这个概念在服务端不存在，只能退化为吊销全部会话。`sid` 不进任何报文字段。
- 会话表以 **`(accountId, deviceId)` 为唯一键**，**活跃会话上限 = 1**（两条独立约束，都要留）。
- **同一 `deviceId` 重登 = 原地替换**，旧 refresh token 立即失效，标 `SessionSuperseded`。
- **`signin` 幂等 = 60 秒回放窗口**，与 §4 refresh 宽限窗口同值同理由。**它是「替换」得以成立的前提**——只取替换会让弱网重试的玩家在登录成功后被赶回验证码输入框。
- **`deviceId` 只做裁决与观测的输入，永不参与鉴权。**

连带把三处 `reasonKey` 取值表一次填满：形态 **PascalCase**（锁死，客户端二级文案键由 `code` + `reasonKey` 机械变换）· `session_revoked` **七值** · `nickname_rejected` **三值** · `compliance.*` 各自取值。其中 `TokenReuseDetected` 与 `CredentialChanged` 填的是既有漏洞——§4 与 §7 都会产生 `session_revoked`，而此前只举了两例。

归档去向：`contracts/auth.md` §2 §4a §7 §8 §10 · `contracts/envelope.md` §6。

## 本次的两处 interview 裁决

| 冲突 / 含糊 | 裁决 |
|---|---|
| `envelope.md` §4a 写死「无鉴权例外仅限 auth 域」，而合规域的两个 ticket 端点当场是第二个例外域（两份草稿均未觉察） | **扩为两个例外域，并把枚举升级为判据**：无鉴权例外只允许给「玩家此刻不可能持有 access token」的端点。护栏因此更严而非更松——`GET /v1/compliance/status` 同属合规域却不够格 |
| `auth.md` §5a 新增纪律的措辞范围 | **只约束「拦截」**，不约束 `compliance.` 前缀本身；合规域端点自身的操作错误另有码，随报文本体落笔 |

## 新增待答（不计入移出）

- `01` —— 合规域端点自身的错误码（随 `compliance.md` 报文本体落笔）。
- `06` —— 可信服务端时钟 · 合规域的存储与导出产物 · 会话记录的存储与同事务吊销保证。
- `02` —— 合规能力的上线分级（由上条部分移出所剩）。

## 跨库

本次是**契约变更**，客户端侧的对位（三处 `reasonKey` 的玩家可见措辞、`ComplianceManager` 覆盖面切分）已在 `game-design-documents/open-questions/cross-boundary.md` 立承接项，**本库不代为决定、不催办**。
