# ② 账号与合规（契约面已完全成文 · 余下一条上线排期）

> 路线权威：`game-design-documents/decisions/ADR-0003-online-cloud-authority.md`（强制在线 · 云端权威 · 重账号，已删游客态）。
> 客户端侧门面：`game-design-documents/systems/services/account-service.md`。

> **身份模型已于 2026-08-16 答结** → `contracts/auth.md` §1 §1a §3a（身份主体自建 · account↔identity 一对多 · 绑定 / 解绑 / 改名端点 · 换 openid 的三条义务与两类错误映射）。
> 三层切分中，**A 层自建、C 层（短信 / 邮件 / 实名核验 / 支付验票）一律外接以适配器隔离**，服务商选型与灾备归 `06`；服务商错误码**不上契约面**，一律先归一到本库已有的 `code`。
> 移出记录见 `../answer-logs/log-account-identity-model.md`。
>
> **合规落地与多设备并发裁决已于 2026-08-16 答结** → `contracts/compliance.md`（第六份契约 · 拦截只在 `signin` · `complianceTicket` · 四条码与取值 · 防沉迷复用 `session_revoked` · 时段口径落配置 · 注销冷静期 15 天 · 导出首版必做）与 `contracts/auth.md` §1a §4a §10（建号先于合规判定 · `sid` claim · `(accountId, deviceId)` 唯一约束 · 活跃会话上限 1 · 同设备重登替换 · `signin` 的 60 秒幂等回放窗口 · 三处 `reasonKey` 取值表）。
> 移出记录见 `../answer-logs/log-compliance-and-session-arbitration.md`。
>
>
> **昵称审核口径、未过审昵称的存量扫描、风控落地形态已于 2026-09-03 答结** → `contracts/auth.md` §8（四级短路判定链 · 频次只计被接受的改名 · 归一化串 vs 原串）· `operations/moderation.md`（词表不可变版本化发布与两档分级 · 存量扫描 T1/T2/T3 与处置阶梯 · 风控事件字段表 · `kind` 八值 · 阈值分档 · 全局熔断 · 自动化止于工单）· `systems/account.md`（判定链与存量扫描的服务内部形态）· `contracts/compliance.md` §10（`nicknameChangeRequired`）与 §5（两处取值表首版不扩）。**后端不改写 / 不置空未过审昵称**，处置只落 `status` 侧；三档处置的可见粒度随之答定为「首版不扩取值表」。移出记录见 `../answer-logs/log-nickname-moderation-and-risk-control.md`。
>
> 下方一条共用同一个挂接点：**`account.status`（`active` · `restricted` · `banned` · `pendingDeletion`）**，而不是各立一套「是否可玩」的真值。

- **合规能力的上线分级。** 实名 / 防沉迷 / 注销 / 导出的**契约面已完全成文**（`contracts/compliance.md`，含六端点报文字段表与端点自身错误码），但「哪些必须在首次上线前具备、哪些可后置」仍未分级——数据导出已定首版必做，其余三项的过审时点与国内渠道要求耦合，需与 `06` 的托管 / 备案一并排期。**从属项：第三方昵称审核首版是否启用**——判定链已留出适配器位（`contracts/auth.md` §8、`operations/moderation.md`），启用与否取决于本条分级与渠道过审要求。
