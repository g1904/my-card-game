# Answer log external-provider-selection-dr

- 日期：2026-09-06
- 来源：`inbox/archive/solution-draft-external-provider-selection-dr.md` → `handoffs/2026-09-06-external-provider-selection-dr.md`
- 移出条数：**1**（部分移出）

---

**`open-questions/06-platform-stack.md`「短信 / 邮件 / 实名核验的服务商选型与灾备（08-16b 采集）」** → **主体答结，一条残余留在 `06`**。

逐项结论：

- **外接原子能力的适配接口形态** → 四类能力共用一套 `Outcome` 三档判别式 + 六条共有形状 A1–A6（判别式不合并 · `providerCode` 只随日志上报永不参与分支 · 入参带 `requestId` · 硬超时且适配层内不做应用层重试 · 个人信息只穿过不留存 · 适配层不认识 `code`、归一发生在调用方端点）。归档去向：`operations/external-providers.md`。
- **归一映射** → 归一到本库已有的 `code`，**按调用点所在域取**；不新增任何 `code`。两条订正：`auth.challenge_expired` 永不来自服务商（验证码由本方生成 / 存储 / 判超时）· 实名核验的明确拒绝归 `compliance.verification_failed` 而非 `auth.credential_invalid`。新增一条判别依据：不可达归 `rate.limited` 还是 `server.unavailable`，看出参有没有 `retryAfter`。归档去向：`operations/external-providers.md`；措辞订正连带 `systems/account.md`、`open-questions/02-account-compliance.md` 顶部引言。
- **多供应商灾备与切换** → 判据是「停摆的玩家后果」而非一刀切。短信 2 家（唯一一条「外部停摆 = `Phone` 渠道玩家全体进不来」且无替代登录路径的能力）· 邮件 0 家（首版零调用面）· 实名核验 1 家 · 昵称审核 0 家。切换只对短信，降级自动、回切带滞后，明确拒绝不计入触发判据。三条承重处置：禁并发双发 · 允许「同码转备用」一次且只在首家未返回受理 id 时 · 禁双验。归档去向：`operations/external-providers.md`。
- **选型判据与凭据托管** → H1–H4 硬判据（境内节点 · 资质齐备 · 有沙箱通道 · 可无停机轮换）不满足即出局；S1–S4 软判据。托管条目粒度 = 能力 × 供应商 × 环境，自成一类托管条目与独立审计线，与既有各类钥匙不共用。归档去向：`operations/external-providers.md`；指路连带 `operations/environments.md`「密钥保管」。
- **昵称改名频次阈值** → 定值 **3 次 / 30 天滚动窗口**（滚动而非自然月：月末月初连改是一条免费的刷子路径）。归档去向：`contracts/auth.md` §8 数值初值表新增一行；旋钮登记连带 `operations/environments.md`「旋钮清单」与 `operations/moderation.md` 数值初值表。
  **同批答定的一条自锁**：`nicknameChangeRequired` 为真时豁免频次级的**拦截**、不豁免**计数**（否则处置阶梯与频次闸互相锁死且无自解通道）。归档去向：`contracts/auth.md` §8 · `operations/moderation.md` 处置阶梯 · `systems/account.md` 判定链与 N6 断言。
  **另一条同批答定的口径**：「单标识符验证码日上限 10 次」只计**成功受理**的一次下发。归档去向：`contracts/auth.md` §8 该旋钮行。
- **微信开放平台资质** → 前置链结构（逐环外部审批）· 资质链与域名备案**同批发起** · 过闸断言改为可验证的运行时事实（`backend-testing` 环境真实微信登录取到非空 `unionid` 且 `idKind` 落为 `unionid`）· **审批未在计划上线日前到位则推迟上线，不以 `openid` 先行建号**。归档去向：`operations/external-providers.md`「微信开放平台资质：时序与过闸」· `operations/deployment.md` 发布前置清单第 4 项。

**仍留在 `06` 的残余：第三方昵称审核的 `rejectThreshold` / `reviewThreshold` 取值。** 形态已定（两阈值 · 服务商 × 环境维度 · 以人工已判定样本标定 · 归一档位），但**首版是否启用**从属于 `open-questions/02-account-compliance.md` 的「合规能力的上线分级」；能力未启用 ⇒ 不定值。

**顺带落笔（非移出项）：** `contracts/auth.md` §8 的 `challenge` 与 `signin` 错误清单补列既有的 `server.unavailable`。§3a 早已定死「渠道 / 通道不可达 → `server.unavailable`」，两处清单漏列是一处既有的契约文本失真，由本次的归一映射显性化。**不新增 `code`、不改任何报文字段、不动 `contracts/envelope.md` §6 台账。**
