# ⑥ 技术栈 · 托管 · 运维（栈与运维形态已落定 · 余两条待实测取值）

> 后端尚未开工（`backend-feature-branch/` 只有 README），但**技术栈与托管形态已落定**：C# / ASP.NET Core · 腾讯云托管容器 · 云数据库 PostgreSQL（单主）· 云 Redis · 云 KMS · CDN；两套云上环境 + 本地 docker-compose。
>
> **八条已于 2026-09-03 答结** → `systems/_index.md`（共用的存储与并发形态 · 明确不引入）· `systems/account.md`（会话表与并发语义 · `tokenId` 与 `sid` 的分工 · refresh token 的派生形态 · access token 签发）· `systems/profile-store.md`（`revision` CAS · 两类幂等记录 · 读己所写的落地）· `operations/environments.md`（区域与合规 · 拓扑与副本 · 两把密钥的保管与轮换）· `operations/deployment.md`（环境分层与发布线 · 迁移三步 · 网关纪律）· `operations/observability.md`（可观测性口径与四条探针）· `operations/version-matrix.md`。移出记录见 `answer-logs/log-backend-stack-and-hosting.md`。
>
> **四条已于 2026-09-06 答结** → `operations/compliance-ops.md`（可信服务端时钟 · 合规域的存储与产物）· `operations/purchase-ops.md` §3d §4（`receiptId` 幂等记录的冷存归档与对账阈值形态）· `operations/external-providers.md`（外接原子能力的选型判据、灾备与切换、凭据托管、微信资质时序）。移出记录见 `../answer-logs/log-trusted-server-clock.md` · `log-compliance-domain-storage.md` · `log-receipt-idem-cold-archive.md` · `log-external-provider-selection-dr.md`。
>
> 余下**两条**待答，都不取决于栈：需要真实体量 / 流量才能定的数值。昵称审核两阈值随「合规能力的上线分级」于 2026-09-07 答结（首版不启用 ⇒ 不定值），已转为下方的条件化核对项。

- **成本模型。** 强制在线意味着每次事件推进都有一次上行；QPS 预估与单账号成本未估算。它是一批数值的共同前置：实例规格 · 灾备副本数与备份保留期（`operations/environments.md` 只写了能力要求）· CDN 成本模型 · **剧本首包与增量下载量的可接受上界**（2026-09-05 从 `04-content-delivery.md` 并入——分包边界本身已由客户端 `ADR-0029` 答定为「不分包」，余下的只是量级与成本，本库不再持有形态问题）。
  **收据归档的三条触发阈值与对账阈值 N 的定值同属此列**——形态、旋钮位置与校准公式已定（`operations/purchase-ops.md` §3d §4），只差上线后的实测数据。
  **本次新增两个输入**（仍不足以定成本模型，缺 DAU）：短信双供的接入成本与按条计费口径 · 实名核验的按次计费口径（`operations/external-providers.md`）。

- **`riskEventBufferRows`（风控事件旁路缓冲上界）的取值。** 形态与旋钮落点已定（`operations/moderation.md`「四张台账的存储形态」· `operations/environments.md`「旋钮清单」），只差上线后的真实事件速率标定；改值不发版。与收据归档三条触发阈值同属「形态已定、只欠实测」一列，同样不阻断 derive。

## 条件化核对项（不是待办）

承接 `operations/moderation.md` 的适配器阈值一节。**第三方昵称审核首版不启用**（唯一启用触发条件：渠道过审点名要求接入第三方内容审核能力），故 `rejectThreshold` / `reviewThreshold` **首版不定值**；下列两点**条件化于「该能力被触发启用」这一假设**，在触发之前不构成任何待办：

1. 两阈值的取值——形态已定（两阈值 · 服务商 × 环境维度 · 以真实人工判定样本标定，取使漏放最小、误拒可接受的一对），启用之日标定并登记进 `operations/moderation.md` 的数值初值表；
2. 该能力的服务商选型（过 H1–H4）与其凭据的独立审计线——形态已由 `operations/external-providers.md` 定死，触发时按同一套判据执行。

两点的完整陈述在 `operations/moderation.md` 与 `operations/external-providers.md`，本处只承接指路、不复述判据。

## 已答结、移出本片的（不在此跟踪）

- **外接原子能力的适配接口与归一映射 · 逐能力供应商数与灾备切换 · 选型判据与凭据托管** → `operations/external-providers.md`；**昵称改名频次上限** 3 次 / 30 天滚动 → `contracts/auth.md` §8；**微信开放平台资质**的前置链、过闸断言与延误处置（推迟上线）→ `operations/external-providers.md` · `operations/deployment.md` 第一份前置清单第 4 项。移出记录见 `../answer-logs/log-external-provider-selection-dr.md`。
