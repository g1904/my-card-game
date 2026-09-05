# ⑥ 技术栈 · 托管 · 运维（栈已落定 · 余下为外部依赖与成本）

> 后端尚未开工（`backend-feature-branch/` 只有 README），但**技术栈与托管形态已落定**：C# / ASP.NET Core · 腾讯云托管容器 · 云数据库 PostgreSQL（单主）· 云 Redis · 云 KMS · CDN；两套云上环境 + 本地 docker-compose。
>
> **八条已于 2026-09-03 答结** → `systems/_index.md`（共用的存储与并发形态 · 明确不引入）· `systems/account.md`（会话表与并发语义 · `tokenId` 与 `sid` 的分工 · refresh token 的派生形态 · access token 签发）· `systems/profile-store.md`（`revision` CAS · 两类幂等记录 · 读己所写的落地）· `operations/environments.md`（区域与合规 · 拓扑与副本 · 两把密钥的保管与轮换）· `operations/deployment.md`（环境分层与发布线 · 迁移三步 · 网关纪律）· `operations/observability.md`（可观测性口径与四条探针）· `operations/version-matrix.md`。移出记录见 `answer-logs/log-backend-stack-and-hosting.md`。
>
> 余下各条的共同点是**它们不取决于栈**：外部服务商、监管口径的数据源、以及需要真实流量才能定的数值。

- **可信服务端时钟（08-16c 采集）。** 未成年时段判定的时间源**不得**依赖设备时钟——`contracts/envelope.md` §4b 已定 `X-Server-Time` 仅供诊断，改一次系统时间即可绕过时段限制。时钟源的形态（NTP 层级、跨区域一致性、时区与法定节假日表的数据源）待定。→ `contracts/compliance.md` §6，落 `operations/`。

- **合规域的存储与产物（08-16c 采集）。** 三项：`complianceTicket` 的存储与一次性消费保证（含兑付的 60 秒回放窗口）· 注销冷静期这条**跨天长时状态机**的调度形态（到期生效、撤销、幂等重入）· **数据导出产物的存储与下载链接签发**（产物含个人信息，保留期初值 7 天，链接不得可枚举）。→ `contracts/compliance.md` §2 §3 §9；承接对象已登记进 `operations/moderation.md` 末节。

- **`receiptId` 幂等记录的冷存归档与对账阈值（部分答结）。** 存储选型（关系库 `receipt_idem`，`receipt_id` 全局唯一主键）· 与序号 / `cloudRevision` 的写入同一次事务 · 下单时预落未决态记录 · 永久保留不设 TTL 的落地形态**已定**（→ `systems/profile-store.md`；分区、索引、TTL 禁用断言与选型判据见 `operations/purchase-ops.md`）。**仍待落定**：体量增长后的**冷存归档形态**，以及对账信号「`bundleGrantOrdinal > bundleRedeemedOrdinal` 持续 N 天」的阈值——**只作人工 / 工单入口，不驱动任何自动写入**。两者都需要真实体量才能定。

- **三渠道验票凭据的托管形态（部分答结）。** 接入面**已落笔**：逐渠道 `receipt` 形态、`receiptId` 取值、平台错误码归一（五条 `purchase.*`）、退款 / 撤单对账通道、凭据形态与轮换特征见 `contracts/purchase.md` §3a §3b 与 `operations/purchase-ops.md`。**仍待落定的是托管形态**——三把钥匙（内容签名 ES256 私钥、会话 token 签名密钥、渠道验票凭据）中，前两把的保管已定（`operations/environments.md`），渠道凭据这把未定，且**三者不共用托管配置**。→ `operations/purchase-ops.md` §1。

- **短信 / 邮件 / 实名核验的服务商选型与灾备（08-16b 采集）。** 身份模型已定「C 层原子能力一律外接、每类能力在后端内部有一个稳定接口使服务商可换」（`contracts/auth.md`）；具体服务商、多供应商灾备策略与切换形态归本分片。**服务商错误码不上契约面**——一律先归一到本库已有的 `code`（`rate.limited` / `auth.credential_invalid` / `auth.challenge_expired` / `server.unavailable`）。另有三项同归此处：**昵称改名频次阈值**与**第三方昵称审核服务商 / 评分阈值**（判定链已留出适配器位，见 `operations/moderation.md`）· **微信开放平台资质申请**——首版以 `unionid` 建 identity 是不可逆决定，**必须在首个玩家建号之前完成**，已列入 `operations/deployment.md` 的发布前置清单。

- **成本模型。** 强制在线意味着每次事件推进都有一次上行；QPS 预估与单账号成本未估算。它是一批数值的共同前置：实例规格 · 灾备副本数与备份保留期（`operations/environments.md` 只写了能力要求）· CDN 成本模型。
