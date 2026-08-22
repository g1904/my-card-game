# ② 账号与合规（契约面已成文，余下为运营口径与风控）

> 路线权威：`game-design-documents/decisions/ADR-0003-online-cloud-authority.md`（强制在线 · 云端权威 · 重账号，已删游客态）。
> 客户端侧门面：`game-design-documents/systems/services/account-service.md`。

> **身份模型已于 2026-08-16 答结** → `contracts/auth.md` §1 §1a §3a（身份主体自建 · account↔identity 一对多 · 绑定 / 解绑 / 改名端点 · 换 openid 的三条义务与两类错误映射）。
> 三层切分中，**A 层自建、C 层（短信 / 邮件 / 实名核验 / 支付验票）一律外接以适配器隔离**，服务商选型与灾备归 `06`；服务商错误码**不上契约面**，一律先归一到本库已有的 `code`。
> 移出记录见 `../answer-logs/log-account-identity-model.md`。
>
> **合规落地与多设备并发裁决已于 2026-08-16 答结** → `contracts/compliance.md`（第六份契约 · 拦截只在 `signin` · `complianceTicket` · 四条码与取值 · 防沉迷复用 `session_revoked` · 时段口径落配置 · 注销冷静期 15 天 · 导出首版必做）与 `contracts/auth.md` §1a §4a §10（建号先于合规判定 · `sid` claim · `(accountId, deviceId)` 唯一约束 · 活跃会话上限 1 · 同设备重登替换 · `signin` 的 60 秒幂等回放窗口 · 三处 `reasonKey` 取值表）。
> 移出记录见 `../answer-logs/log-compliance-and-session-arbitration.md`。
>
> 下方各条共用同一个挂接点：**`account.status`（`active` · `restricted` · `banned` · `pendingDeletion`）**，而不是各立一套「是否可玩」的真值。

- **敏感词词表与审核口径。** `auth.nickname_rejected.detail.reasonKey` 的取值表已封定（`contracts/auth.md` §10 三值），待定的是 `SensitiveWord` 的**判定输入**：词表来源、审核口径、是否接第三方审核服务（服务商与阈值归 `06`）。

- **未过审昵称的存量扫描。** 改名端点只判定「这一次提交」，而昵称由客户端写入 profile，改包可绕过（代价已在 `contracts/auth.md` §8 如实记下）。扫描触发频率与处置（改写 / 置空 / 标 `restricted`）待定。**挂接点**：处置落在 `status`。

- **合规能力的上线分级。** 实名 / 防沉迷 / 注销 / 导出的**契约面已成文**（`contracts/compliance.md`），但「哪些必须在首次上线前具备、哪些可后置」仍未分级——数据导出已定首版必做，其余三项的过审时点与国内渠道要求耦合，需与 `06` 的托管 / 备案一并排期。

- **风控与滥用面。** 客户端执行、后端可离线复算的掷骰意味着存在改包伪造收益的通道。**处置口径已定（2026-08-14）**：复算不一致 → **接受写入 + 打一条结构化风控事件，不拒绝、不改写**（`contracts/profile-sync.md` §7a）；且**有一条已知的残留通道**——`lastEffectiveChance` 后端无法验真，「篡改客户端把生效概率写成 10000」只能由风控接住，不被复算接住。**挂接点**：「观察 / 限制 / 封禁」三档处置的落点即 `restricted` / `banned`。**仍待定**：是否建风控系统、风控事件的字段与落地形态、累计频次到什么程度算异常、异常账号如何处置（观察 / 限制 / 封禁）。与 `06` 的可观测性口径耦合。
  - **从属项：三档处置向玩家的可见粒度。**（2026-08-22 采集 · 此前散在契约文档、未进本清单）当前 `auth.session_revoked.detail.reasonKey` 的 `OperatorRevoked` 与 `compliance.account_restricted` 的取值够用；若风控要向玩家区分「哪一类异常」，两处取值表需再扩。**不阻塞任何契约**——新增 `reasonKey` 不要求客户端同批发版（`contracts/envelope.md` §5b）。它的前提就是上一条：三档处置的判据不定，就无从判断要不要分。→ `contracts/auth.md` §10、`contracts/compliance.md` §4。
