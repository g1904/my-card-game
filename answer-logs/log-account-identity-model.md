# Answer log account-identity-model

- 日期：2026-08-16
- 来源：`inbox/solution-draft-account-identity-model.md`（`status: decided`）→ `handoffs/2026-08-16b-account-identity-model.md`
- 移出条数：1（另有 1 条**部分移出**，见下）

## 逐条

**账号系统自建还是接第三方？（重账号的注册 / 登录 / 找回 / 多端绑定全链路由谁承担）** → **拆成三层，分开之后没有一层是取向**：

- **A 身份主体 = 自建**（`accountId` 由本方发放、账号生命周期与会话签发在本方）。四条既定设计逼出这个答案：主键不租给第三方 · 建号须与 `accountSeed` 写入 profile 骨架同一步 · 三条会话语义（宽限窗口幂等回放 / `reasonKey` / 强更闸门只在 `signin`）无托管 IdP 现成表达 · 合规能力须能落到账号上。**同时明确不做 OAuth2 / OIDC provider**——无第三方消费者。
- **B 登录凭据 = 两类并存**，形态在 `contracts/auth.md` §3 早已封定；本次只补 identity 模型与首版上线渠道（`Phone` + `WeChat`，**不实现 ≠ 从契约删除**）。
- **C 原子能力 = 一律外接**，以内部稳定接口隔离服务商；服务商错误码不上契约面，归一到已有 `code`。

（归档去向：`contracts/auth.md` §1 §1a §3a §7 §8 §9 · `contracts/envelope.md` §6 · `contracts/profile-sync.md` §5 · `contracts/_index.md`）

**连带答结的三项**（原本各自散在契约文档的显式留白里，不单独计数）：

- **绑定 / 解绑端点** → 进 `auth.md` §1，不单开契约；`bind` 复用 `signin` 的 `credential` 判别式，`unbind` 归零即拒。（原留白：`auth.md` §1「待客户端 `account-info.md` 的多渠道绑定模型」）
- **第三方渠道换取 openid 的报文与错误映射** → 契约只写三条后端义务；**渠道明确拒绝 → `auth.channel_rejected`（`Fatal`）、渠道不可达 → `server.unavailable`（可重试）**，两类必须在报文层面可区分。（原留白：`auth.md` §3）
- **绑定列表如何下行** → 扩 `profile-sync.md` §5 后端写入表，客户端随 pull 取回只读投影；否决另立 `GET /v1/auth/identities`（造第二下行口）与客户端自行写入（新设备首登时列表为空）。

## 部分移出

**`purchase.md` 的 `receipt` 字段形态** —— 它此前挂在本条之下，属**指向错误**：那里的「渠道」是**支付渠道**（应用商店 / 平台 IAP），与登录渠道不同轴。已改指向 `06-platform-stack.md` 的支付渠道选型；**本次定案不解锁它**。

## 本次一并新增的三项待答（不是答结）

均落 `02` 与 `06`：实名是否为建号前置 · `auth.nickname_rejected.reasonKey` 取值与词表口径 · 未过审昵称的存量扫描；服务商选型与灾备 · 昵称改名频次阈值 · 微信开放平台资质（**首个玩家建号前必须完成**）。
