# 后端技术栈 · 托管 · 同步与会话的实现落地 · 可观测性

- id: 2026-09-03-backend-stack-and-hosting
- date: 2026-09-03
- topic: systems/_index · systems/account · systems/profile-store · operations/environments · operations/deployment · operations/observability · operations/version-matrix · contracts/profile-sync（一句通则增补）
- status: distilled
- distilled-to: `systems/_index.md`、`systems/account.md`、`systems/profile-store.md`、`operations/environments.md`、`operations/deployment.md`、`operations/observability.md`、`operations/version-matrix.md`、`contracts/profile-sync.md`

## Intent（distilled）

六份契约全部成文且再无取值留白，全库唯一的结构性前置是技术栈与托管形态。契约刻意把一批实现语义停在语义层并挂账到运维侧，**且明写「落定后进 `operations/`、不回头改契约」**：`revision` CAS 的存储与并发控制 · `(accountId, pushId)` 幂等记录的存储与事务边界 · push 滥用阈值 · 跨区域拓扑 · profile 体积软告警 · 会话记录的存储与同事务吊销 · `signin` 幂等回放记录 · token 签名密钥的保管与轮换 · 三条同步探针与一条透明路径缺失告警。

**它们不是九个独立的选型，而是同一个选型的九个侧面。** 本次先立筛选判据、再用判据淘汰候选，只把真正无客观最优的项交回裁决。

### 选定的形态

**C# / ASP.NET Core · 腾讯云托管容器 · 云数据库 PostgreSQL（单主）· 云 Redis · 云 KMS · CDN；两套云上环境（testing + production）+ 本地 docker-compose 承担 feature。**

### 六条筛选闸（候选只要不满足任一条即出局）

| 闸 | 内容 |
|---|---|
| G1 事务 | 一次事务内原子写 profile 文档 · `revision` 计数器 · 幂等记录（跨表） |
| G2 线性化 | 同账号读改写可线性化、计数器严格单调 ⇒ 多主 / 最终一致写入拓扑出局 |
| G3 读路径 | 玩家读路径不得无条件落在滞后副本上 |
| G4 合并语义 | 能表达「顶层键整键替换、不递归」的浅合并，且不退化为 JSON Merge Patch |
| G5 类型化 | 能把白名单路径还原成类型化值再比较（时间按时刻、数组有序逐元素） |
| G6 体积 | 单条 profile 记录能安全承载超过体积软告警阈值的数据 |

### 三条否定结论

- **多主写入 / 跨区域双写 `revision` 出局**：账号级严格单调计数器在多主下无法维持，而云端权威的全部力量建立在它上面。
- **单条记录硬上限低于体积软告警阈值的 KV 存储出局**：软告警阈值是「正常账号预期会接近并越过」的观测线，把它抬成硬失败等于给正常账号造一条「push 永远失败」的路径，失败面是玩家进度。
- **不能靠 MySQL 的 JSON 合并原语承担浅合并语义**：其一实现的正是被否决的 JSON Merge Patch，其二是递归合并；若选它，浅合并须应用层手写，即把一条承重契约语义从存储不变式降级为代码纪律。

### 落地面

- **表结构承重列 + 事务边界表 + 实现纪律** → `systems/account.md` · `systems/profile-store.md`（公共前提上提到 `systems/_index.md`）。
- **环境实体 · 配置三层 · 旋钮清单 · 区域合规 · 拓扑 · 密钥保管** → `operations/environments.md`。
- **构建 / 迁移 / 网关纪律 / 发布前置清单 / 内容发布侧能力要求** → `operations/deployment.md`。
- **四条探针 + 最小指标集 + 日志脱敏** → `operations/observability.md`。
- **兼容矩阵本体与运维流程** → `operations/version-matrix.md`。

## Clarifications（interview 产物）

- **refresh token 的载荷形态** → 改为 `<tokenId>.<mac>`。草稿原写 `<sid>.<generation>.<mac>`，那会把服务端内部键 `sid` 与轮换代次一起放上报文，与「refresh token 是不透明随机串」「`sid` 不出现在任何报文字段里」两条承重条款相抵。改用与 `sid` 分离的随机 `tokenId`、`generation` 不上报文，**契约因此零改动**；会话行加 `prev_token_id` / `prev_generation` 两列，用以分辨「会话被替换」与「凭据泄漏」——草稿的原形态分辨不了这两者，这是必须补的缺口。
- **access token 的签名与密钥形态** → 算法保持 EdDSA，但**KMS 只保管被包裹的私钥、签名在进程内做**。草稿原写「签发走 KMS Sign API」，那会把 KMS 拉进登录热路径（停机即全体无法登录），并依赖一项未核实的厂商能力。代价是逐次签名审计降级为解包事件审计，这是被接受的取舍。
- **只读副本能否承接玩家读路径** → 统一取「玩家读路径全部走写入区」，只读副本只承担灾备与离线分析。flags 的读路径不受读己所写约束这一自由度**保留但当前未使用**，作为留档写在拓扑一节，不引入按端点分档的例外表。
- **灾备副本的地理位置与档位** → **不定副本数，只写能力要求**：部署形态须满足可演练恢复（「版本号未倒退」是数据库恢复演练的必检项）。副本数与备份保留期同属成本模型输入，DAU 预期未定前不写死。「个人信息不出境 ⇒ 任何副本仍在境内」按已有约束直接落笔。
- **`bind` / `unbind` 是否推进 `revision`** → 推进，并在契约的后端写入表下方补一句通则「后端对 profile 的任何写入均推进 `revision`」。这是一句澄清而非决策变更。
- **`signin` 两步与契约伪码反序** → 按标准默认采纳：同事务内中间态不可观测 ⇒ 语义等价，**契约无需改动**，实现纪律记在 `systems/account.md`。
- **`refresh` 的限流真空** → 只记账 + 告警、不返回限流码，**不改契约**；两条网关纪律作为上线核对项落 `operations/deployment.md`。
- **选 C# 会诱发共享 DTO 的复议** → 在 `operations/deployment.md` 显式引一次「同语言不解锁共享 DTO」的护栏，使复议必须先驳倒它。**只挂一处。**
- **收据幂等记录与 push 幂等记录的存储归属** → 存储选型、分区与事务边界统一落 `systems/profile-store.md`；渠道逐个的 `receipt` 形态与冷存归档归购买域运维文档。
- **发布侧须能取到每个在架客户端版本的基线内容快照** → 作为一条能力要求落 `operations/deployment.md`，与内容发布侧的校验闸互相回链。

## Open questions

- **成本模型 / DAU 预期**：实例规格、副本数与备份保留期无法定稿。
- **三条机检断言的工程承载位置**：本形态具备承接能力，但承载位置本身仍待定。
- **昵称改名频次阈值**：尚未定值，定值后落旋钮表。
- **短信 / 邮件 / 实名核验的服务商选型与多供应商灾备**。
- **合规域的存储与产物、可信服务端时钟**：注销冷静期这条长时状态机会追加对可靠调度的要求，出口已预留、形态未定。

## 客户端侧影响

**无。** 本次全部落在 `systems/` 与 `operations/`，契约面只增补一句既有语义的通则，**报文零改动**：token 密钥轮换纯服务端；access token 的签名算法对客户端不可见（客户端不验签 access token）；refresh token 始终是不透明串，其内部构造不进契约。因此本 handoff 不产生任何客户端义务，不写对侧文档。
