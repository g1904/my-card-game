# Answer log backend-stack-and-hosting

- 日期：2026-09-03
- 来源：`inbox/solution-draft-backend-stack-and-hosting.md` → `handoffs/2026-09-03-backend-stack-and-hosting.md`
- 移出条数：9 条全条移出 + 1 条部分移出

## `open-questions/06-platform-stack.md`

**技术栈与托管形态未定** → 语言 / 框架 = C# / ASP.NET Core；部署形态 = 腾讯云托管容器；数据库 = 云数据库 PostgreSQL（单主）+ 云 Redis（只做限流计数器，不持权威状态）；选型由六条筛选闸推出，三条否定结论（多主写入 / 单条记录硬上限低于体积软告警阈值的 KV / 靠 MySQL JSON 合并原语承担浅合并）随之成立。（`systems/_index.md`、`operations/environments.md`、`operations/deployment.md`）

**区域与合规托管** → 主区在中国大陆境内；个人信息不出境，任何副本仍在境内；`identity` 与 `profile` 分表分权限；手机号 / 邮箱以 HMAC 派生值参与索引、明文绝不落库落日志；备案与发行资质列入发布前置清单同批推进。（`operations/environments.md`、`operations/deployment.md`）

**token 签名密钥的保管与轮换、会话存储形态** → 算法 EdDSA；KMS 只保管被包裹的私钥、签名在进程内做，KMS 不在签发热路径；`kid` 轮换纯服务端、旧 `kid` 保留 ≥ access token TTL + 余量，例行 90 天 + 疑似泄漏立即；`refreshSecret` 同处 KMS、带自己的 `kid`，轮换时旧 secret 保留至最长 refresh 链自然到期。会话表承重列与并发语义一并落地。（`operations/environments.md`、`systems/account.md`）

**会话记录的存储与并发语义** → `(accountId, deviceId)` 唯一约束 + 部分唯一索引承担「活跃会话上限 1」；「吊销其余」与「写入本设备」同一次事务，且**实现须与契约伪码反序**（先吊销、再写入），因部分唯一索引不可延迟；`signin` 幂等回放记录落关系库、与会话写入同事务、键以 HMAC 派生值存储、保留 10 分钟。refresh token 改为可重算的派生串 `<tokenId>.<mac>`，`tokenId` 与 `sid` 分工写明，`prev_token_id` / `prev_generation` 用于分辨会话被替换与凭据泄漏。（`systems/account.md`）

**环境分层与发布线** → 两套云上环境（testing + production）+ 本地 docker-compose 承担 feature；必须与生产同构的是 testing；配置三层（编译期常量 / 环境配置 / `config_knob` 运行期旋钮）；镜像 tag = commit sha 不可变、三处跑同一 artifact；迁移与代码发布分离走 expand → deploy → contract，迁移只前滚、代码可回滚镜像 tag；发布前置清单四项共用同一个不可逆时刻。（`operations/environments.md`、`operations/deployment.md`）

**可观测性口径** → 基座为结构化 JSON 日志 + OpenTelemetry，`X-Request-Id` ↔ `requestId` ↔ `trace_id` 三者贯通；四条契约语义探针的指标形态与告警口径全部定案（本地领先阈值 = 0；去重命中率相对基线 3× 突增；复算不一致率**必须按三条校验拆分**，①③ 走工程告警、② 走风控入口；透明路径缺失**须带「该顶层键出现在本次 diff 中」的前提**）；另有 RED 三件套、按 `code` 的时间序列、CAS 冲突率与回声拒绝率分开计数、会话面、孤儿取值告警、数据面；日志脱敏在中间件统一实施。（`operations/observability.md`）

**同步侧语义的实现落地** → CAS 用受影响行数分支、判定顺序照契约、回声校验读本事务内已加锁的当前值、零判定权字段关闭 enum 严格校验而驱动判定的枚举保持封闭；`(accountId, pushId)` 幂等记录与 `revision` 同事务，两个旋钮取先到者、实现只做时间那一半（条数降级为观测阈值）；push 滥用阈值走 Redis 账号维度计数器、fail-open 并告警，验证码类计数是例外不 fail-open；跨区域拓扑取单区域部署、不做多活；体积软告警出分布指标与超阈值 gauge，绝不拒绝上行。（`systems/profile-store.md`、`operations/environments.md`、`operations/observability.md`）

**读己所写要求对拓扑与读路径的约束** → 取最简兑现：**玩家读路径全部走写入区**（会话粘滞的极端形态），因此不需要 `revision` 下界等待。只读副本只承担灾备与离线分析。flags 读路径不受读己所写约束这一自由度保留但当前未使用，作留档。（`operations/environments.md`、`systems/profile-store.md`）

**`receiptId` 幂等记录的存储与冷存归档** → **部分答定**：存储选型（关系库 `receipt_idem` 表，`receipt_id` 全局唯一主键）、与序号推进同事务、下单预落未决态记录、永久保留不设 TTL 的落地形态已定。**仍留待答**：分区策略的细化、冷存归档形态、对账信号「持续 N 天」的阈值——归支付渠道分片。（`systems/profile-store.md`）

## `open-questions/01-contracts.md`

**`refresh` 的滥用面与限流形态** → 不限流、只记账 + 告警，**契约不改**。两条网关纪律（refresh 上不得存在返回限流码的限流 · push 阈值走应用层账号维度而非网关 IP 维度）作为上线核对项逐次过闸；refresh 的记账指标进最小指标集。（`operations/deployment.md`、`operations/observability.md`）
