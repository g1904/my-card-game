# ② 账号与合规（契约面已完全成文 · 待答清零，余一条外部事实挂账项）

> 路线权威：`game-design-documents/decisions/ADR-0003-online-cloud-authority.md`（强制在线 · 云端权威 · 重账号，已删游客态）。
> 客户端侧门面：`game-design-documents/systems/services/account-service.md`。

> **身份模型已于 2026-08-16 答结** → `contracts/auth.md` §1 §1a §3a（身份主体自建 · account↔identity 一对多 · 绑定 / 解绑 / 改名端点 · 换 openid 的三条义务与两类错误映射）。
> 三层切分中，**A 层自建、C 层（短信 / 邮件 / 实名核验 / 支付验票）一律外接以适配器隔离**；适配接口、归一映射与灾备形态见 `operations/external-providers.md`。服务商错误码**不上契约面**，一律先归一到本库已有的 `code`，**按调用点所在域取**。
> 移出记录见 `../answer-logs/log-account-identity-model.md`。
>
> **合规落地与多设备并发裁决已于 2026-08-16 答结** → `contracts/compliance.md`（第六份契约 · 拦截只在 `signin` · `complianceTicket` · 四条码与取值 · 防沉迷复用 `session_revoked` · 时段口径落配置 · 注销冷静期 15 天 · 导出首版必做）与 `contracts/auth.md` §1a §4a §10（建号先于合规判定 · `sid` claim · `(accountId, deviceId)` 唯一约束 · 活跃会话上限 1 · 同设备重登替换 · `signin` 的 60 秒幂等回放窗口 · 三处 `reasonKey` 取值表）。
> 移出记录见 `../answer-logs/log-compliance-and-session-arbitration.md`。
>
>
> **昵称审核口径、未过审昵称的存量扫描、风控落地形态已于 2026-09-03 答结** → `contracts/auth.md` §8（四级短路判定链 · 频次只计被接受的改名 · 归一化串 vs 原串）· `operations/moderation.md`（词表不可变版本化发布与两档分级 · 存量扫描 T1/T2/T3 与处置阶梯 · 风控事件字段表 · `kind` 取值表 · 阈值分档 · 全局熔断 · 自动化止于工单）· `systems/account.md`（判定链与存量扫描的服务内部形态）· `contracts/compliance.md` §10（`nicknameChangeRequired`）与 §5（两处取值表首版不扩）。**后端不改写 / 不置空未过审昵称**，处置只落 `status` 侧；三档处置的可见粒度随之答定为「首版不扩取值表」。移出记录见 `../answer-logs/log-nickname-moderation-and-risk-control.md`。
>
> **合规能力的上线分级（含从属项「第三方昵称审核首版是否启用」）已于 2026-09-07 答结** → 四项能力（实名 / 防沉迷 / 注销 / 导出）**全部首版必备、不分档**，可后置的是各项的增强项；第三方昵称审核适配器**留位不启用**，并补了唯一的启用触发条件（渠道过审点名要求接入）。落点：`operations/deployment.md`（两份发布前置清单）· `vision/scope.md` In scope · `operations/compliance-ops.md`「上线分级」· `contracts/compliance.md` §1 · `operations/moderation.md` · `operations/external-providers.md` · `systems/account.md`（时段判定保证 P1–P5）。首版发行形态同批裁定为**中国大陆正式发行**（iOS / Android 国内渠道 + 微信）。移出记录见 `../answer-logs/log-compliance-launch-tiering.md`。

## 挂账项（须以外部事实核实，不是设计待答）

- **实名核验是否另需对接主管部门的实名认证系统。** 本库把实名核验完整地登记为一条**商用外接原子能力**（`operations/external-providers.md` ②：持牌数据源 / 权威库或运营商要素核验 · 单供 · 按次计费 · 硬超时 5 秒），全库零处提及主管部门侧的认证接入。**这处沉默是一处尚未核实的空白，不是「已确认无此义务」**——核实前不得据此认为实名核验的形态已经完备。
  - **核实所需的外部信息**：版号 / 发行流程中拿到的实名与防沉迷**接入要求文件**，或发行商 / 渠道给出的接入清单。
  - **核实为「须同时接入」时的改动面**：`operations/external-providers.md` 增第五类外接能力（含自己的 `Outcome` 归一与硬超时）· `operations/deployment.md` 第一份前置清单第 5 项旁增一环**外部审批**（其完成时刻不由我方决定，与微信开放平台资质同性质）·「推迟上线」的触发面扩大一条。
  - **核实为「取代商用核验成为唯一数据源」时**：`external-providers.md` ② 整行改写，单供判据与「按次计费 ⇒ 限流 fail-closed」的推导（`contracts/compliance.md` §9 实名提交上限 · `ADR-0031`）须重做。
  - 它**不阻塞**任何一处已落笔的形态：分级结论、两份前置清单与合规六端点均按「只用商用持牌核验」成立。
