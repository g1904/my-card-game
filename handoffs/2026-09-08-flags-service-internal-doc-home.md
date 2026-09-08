# flags 请求处理路径的服务内部形态落 `systems/content-delivery.md`

- id: 2026-09-08-flags-service-internal-doc-home
- date: 2026-09-08
- topic: systems/content-delivery（新建 · flags 请求处理路径）· operations/content-delivery-ops（四行改回链 · 负载段拆分）· decisions/ADR-0047（结尾指路分指两处）· systems/_index（现状段）· operations/observability（一条告警断言）
- status: distilled
- distilled-to: `systems/content-delivery.md`、`operations/content-delivery-ops.md`、`decisions/ADR-0047-flags-propagation-instance-window.md`、`systems/_index.md`、`operations/observability.md`

## Intent（distilled）

**一句话：`GET /v1/content/flags` 的请求处理路径是服务内部行为，归 `systems/content-delivery.md`——该文档本次建立，承接规则集缓存与预热 · 应答体版本取值 · 头的下发算式 · 本实例可兑现版本的取数面 · 应答签名结果缓存 · 回源失败的降级；运维形态原样留在 `operations/content-delivery-ops.md`。契约面零改动、报文零改动、客户端零义务。**

### 归属判据

`systems/_index.md` 把「服务内部怎么实现」钉给 `systems/`，把边界报文钉给 `contracts/`；`operations/content-delivery-ops.md` 的自陈范围是「运维形态的要求，以及由此反向落在托管选型上的约束」。请求处理路径这一批条款——一次请求进来，进程内怎么算——逐条落在前者，被后者的自陈范围逐字排除。服务职责表本就把这份职责登记给 `content-delivery.md`，缺的只是文件本身；本库亦已自陈该服务的内部形态具备开写条件，本次落笔即是那份实质设计的第一批内容。

运维文档因此**一处自陈范围都不用改**：四行整体移出后原位只留一行回链，其余全部内容（规则集存储形态与变更通道 · 发布流水线与校验闸 · 留痕 · 私钥保管与 `keyId` 轮换 · CDN 要求 · 版本传播窗口 T · 数值初值一览）一字不动。

### 本次迁移的范围与一处已知的结构不齐

只迁请求处理路径这一批。规则集表的承重列与唯一写入面（`operations/content-delivery-ops.md` A1–A3 / A5）**仍留在运维文档**，新文档的「存储形态：承重列」与「唯一写入面与事务边界」两节写成指向它的回链。

这与 `account.md` / `profile-store.md` 的方向相反——那两份持有自己的承重列，由运维文档回链它们。**这一次方向反转是被接受的**：它不影响任何机制正确性，也不影响这批切片写成 FR；把 A 表拆成两半是一个相邻但独立的问题，值得单独提出而不是被本次改动裹挟。待下一次触及内容分发时补齐。

### 推演出的一处缺口：版本预热

规则集的装载若纯粹由请求驱动（懒加载），与「头永不领先」这条纪律合成出一个自锁：

```
实例未装载新版本 → 它下发的头不涨 → 客户端不拉 flags → 该实例收不到 flags GET → 永不装载
```

集群内每个实例都懒加载时，**一次 `publish` 可能对全体设备永不生效**，而传播窗口 T 的探针（实例间 gauge 极差 ≠ 0 且持续超 T）**发现不了**——极差为 0，全体一致地卡在旧版本。

⇒ **装载必须有请求无关的触发**：实例侧的当前版本读取缓存每次刷新（TTL 5 秒）发现高水位更大时主动装载该版本，装载成功后本实例可兑现的最大版本才随之抬高（头永不领先因此仍成立）。成本 = 实例数 × 每次发布一次回源，可忽略。

配套的观测缺口落对侧运维文档：现有告警断言只看实例间极差，看不见「全体一致地落后」，故 `operations/observability.md` 增一条断言——**`高水位 − 本实例可兑现的最大版本` 持续 > T 即告警**，取数面仍是既有那个 gauge，零新增机制。

### 边界（不牵动的东西）

契约面零改动：`contracts/content-manifest.md` 不动、报文不动、`flagsSchema` 不提升。`ADR-0047` / `ADR-0009` 的决策本体一字不动——前者只把结尾那句指路由单指运维文档改为分指两处（纪律 → `systems/content-delivery.md`，预算与初值 → `operations/content-delivery-ops.md`）。无存档 / schema 迁移，无数据迁移。

**客户端承接义务：零。**

## Clarifications（interview 产物）

- **请求处理路径这批条款的文档归属：新建 `systems/content-delivery.md`，还是明文裁决就地留在运维文档？** → **新建 `systems/content-delivery.md` 并迁入**（2026-09-08 批量评审裁决，选项 A）。运维文档原位留一行回链，其自陈范围不动。
- **规则集表的承重列与唯一写入面（A1–A3 / A5）是否同批迁入？** → **本次只迁请求处理路径**（同上，选项 B1）。两节写成回链占位，方向反转的结构不齐已知且被接受，待下一次触及时补齐。
- 以下按标准默认直接落笔：规则集缓存的 LRU 容量上限取 **8**（稳态同时可达的版本只有 1–2 个，取一个数量级余量；进程内容量常数、不进运维旋钮表）· 回源失败不写负缓存 · 零装载且回源失败时返回 `Retryable` 类错误而非空 `disabledIds`。

## Notes / triage

- **`systems/` 由两份变三份**，与三服务架构对齐，服务职责表不再指向一份不存在的文件。
- **运维文档的「该端点的真实负载」一段按归属拆开**：请求量量级估算是容量口径，留运维文档；「签名结果按 `(flagsVersion, accountId)` 缓存、缓存的是 `sig` 而非 `disabledIds`」是进程内形态，迁入服务文档，运维处改回链。
- **「按账号结果缓存的引入触发」留在运维文档的数值初值一览**——它是读数与运维阈值；被它触发后要落地的形态（键必须是 `(flagsVersion, accountId)`）属服务文档，故该行的「推导所在」列改为回链服务文档。
- **一处非阻断的下游核对**：零装载时的错误应答需要一个 `code`。`contracts/envelope.md` §5a 已有兜底（应答体无法解析 ⇒ 按状态码降级为 `server.unavailable`，`Retryable`），故不阻塞；「flags 端点是否值得一条专属 `code`」归 `contracts/envelope.md` §6 台账裁决，列为待答项。
- 本次不新增 ADR：归属是文档结构裁决，机制本体已由 `ADR-0047` / `ADR-0009` 固化。

## 客户端侧影响

**无。** 边界报文的字段、形状与取值集合均不变，`X-Flags-Version` 的语义与既有条款逐字一致。`account-service` / `content-service` / `sync-service` 三个跨边界成分均无承接项，`game-design-documents/` 无需同步更新。
