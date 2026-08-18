# Answer log account-identity-model

- 日期：2026-08-16
- 来源：`inbox/solution-draft-account-identity-model.md`（`status: decided`）→ `handoffs/2026-08-16e-account-identity-client-adoption.md`
- 移出条数：1（部分移出，见下）

## 逐条

**`AccountInfo` 字段 schema（账号 id / 绑定渠道 / 昵称头像 / 注册时间 / 封禁实名状态；多渠道绑定同一账号的模型）** → **字段面已收口**：`AccountId` · `AccountSeed` · `CreatedAtUtc` · `Identities`（只读投影，后端权威）· `Nickname`（客户端写、后端只判定）；**无头像**（首版不做，后置而非否决）；**无账号状态字段**（真值随时可变，本地副本会在会话中途过期，表现全部由登录应答分支与合规错误码承载）。多渠道绑定模型的权威在后端契约，客户端只持有投影。

（归档去向：`systems/player-profile/account-info.md` 的「字段」小节）

**同批答结的客户端 API 面（本就不是清单条目，不计移出）：** `account-service` 增四个 B 形态方法（请求验证码 / 绑定 / 解绑 / 改昵称）、`SignInAsync` 扩一个凭据参数、`rate.limited → OpError.Network`、首版实现 `Phone` + `WeChat` 两个渠道。

## 部分移出

**合规字段的归属**（实名 / 未成年人限制落客户端还是纯后端）**仍留在清单上** —— 它归后端库的合规分级，`AccountInfo` 的字段表因此仍可能增行。

## 本次新增的待答（不是答结）

- **`deviceId` 的生成与持久化落点**（与 refresh token 的客户端持有形态宜一并落）→ `systems/services/account-service.md` 的待决问题。
- **`reasonKey` 二级措辞的逐条文案**（结构与兜底规则已定，取值集合待后端）→ `ux/error-and-blocking-ux.md` 的待解问题。
