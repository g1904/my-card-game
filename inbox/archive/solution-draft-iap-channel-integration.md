---
type: solution-draft
date: 2026-09-06
question: 平台内购跨边界依赖的后端余项——渠道验票凭据的托管形态（06 分片「部分答结」条的未定半），连带补上 `GET receipt/{receiptId}` 的 `rejected` 原因取值
source: open-questions/06-platform-stack.md → 「三渠道验票凭据的托管形态（部分答结）」；contracts/purchase.md §4（`rejected` 时附原因——形态未定义）
targets: operations/purchase-ops.md §1（托管形态落笔）· contracts/purchase.md §4（`rejected` 原因取值一行）· operations/environments.md（凭据分层的一句衔接）
status: distilled
reviewed: 2026-09-06 批量评审——`status` 三值统一改 PascalCase { Unknown, Verified, Rejected }（同批改 ADR-0013 一行与 purchase.md §4，不记显式例外）；其余按草稿推演采纳
distilled-to: handoffs/2026-09-06-iap-channel-integration.md
counterpart: game-design-documents/inbox/solution-draft-iap-channel-integration.md
---

# 方案草稿 — 渠道验票凭据的托管形态 + `rejected` 原因取值

## 问题

两库就绪度评估共同点名的「平台内购跨边界依赖」，后端半在 2026-09-03 的渠道接入 handoff 之后**只剩两小块**：

1. **渠道验票凭据的托管形态。** 三把钥匙（内容签名 ES256 私钥 · 会话 token 签名密钥 · 渠道验票凭据）中前两把的保管已定（`operations/environments.md`「密钥保管」），渠道凭据这把未定，且既有纪律要求**三者不共用托管配置**（`operations/purchase-ops.md` §1）。凭据形态与轮换特征已落笔，欠的是「放在哪、怎么读、怎么轮换不停机」。
2. **`GET /v1/purchase/receipt/{receiptId}` 的 `rejected` 原因取值。** `contracts/purchase.md` §4 只写「`rejected` 时附原因」，原因的字段与取值域未定义。08-30 就绪度评估曾把它列为卡点（「与 verify 失败面同源」）；verify 失败面的五条 `code` 现已封定并进 `envelope.md` §6 台账，这一条可以机械收口了。

> **不在本草稿范围内（已定，硬前提，绝不重开）：** 逐渠道 `receipt` 形态与三张渠道状态映射表（`purchase.md` §3a）· 五条 `purchase.*` 错误码及其 §6 台账五列（`envelope.md` §6 已登记）· `receiptId` 取值与幂等窗口（§3a §7 · `ADR-0013`）· 写入权威分配（§2 · `ADR-0007`）· 幂等记录的存储选型判据 / 分区 / TTL 断言 / 冷存触发条件（`operations/purchase-ops.md` §3）。

## 约束（来自既有设计）

- **技术栈已落定**：C# / ASP.NET Core · 腾讯云托管容器 · PostgreSQL 单主 · Redis · **云 KMS** · CDN（`open-questions/06-platform-stack.md` 抬头）。
- **密钥永不进环境变量明文、不进镜像、不进 git**；环境配置里只出现 KMS 密钥别名 / Secrets 引用（`operations/environments.md`「配置分层」）。
- **三把钥匙不共用托管配置**——三者轮换节奏互不相同，共用会让最慢的节奏绑架其余两条（`operations/purchase-ops.md` §1）。
- **渠道凭据的轮换由渠道方日程驱动，须支持新旧并存期**（微信平台证书轮换、Apple key 并存均已明写，`purchase-ops.md` §1 表）。
- **环境隔离在凭据层**：测试环境沙箱凭据、生产环境生产凭据；环境校验以部署环境配置为准（`purchase-ops.md` §1）。
- **渠道 API 401/403 是 P1 告警面**（我方配置事故，`purchase-ops.md` §4）——托管形态必须让「凭据失效」可被这条告警接住而非静默。
- **`status ∈ {unknown, verified, rejected}` 三值已冻结**（`ADR-0013`），「已退款」不进该枚举（`purchase.md` §7）。
- **契约变更完成判据**（`contracts/_index.md`）：spec 尚未落笔，故本次只须 markdown 语义 + §6 台账核对 + 对侧 handoff 互链（若报文面有变）。

## 建议方案

### 子项 1 —— 渠道凭据的载体：云 Secrets 条目（底层 KMS 加密），不走签名密钥的「KMS 包裹 + 启动解包」形态

`[既有推演]` + `[通行做法]`

- **载体 = 腾讯云凭据管理系统（SSM）**，每渠道 × 每环境一个 secret 条目，值为 JSON 载荷。SSM 底层本就以 KMS 加密，天然满足「同一 KMS、不同密钥 / 权限 / 审计线」的既有分层（`environments.md`「与内容签名密钥的关系」同构外推到第三把钥匙）。
- **为什么不复用签名密钥的「KMS 包裹私钥 + 进程启动解包一次」形态**：那套形态的取舍点是「KMS 不在签发热路径上」（`environments.md`）；而渠道凭据是**向外调用的客户端凭据**，形态杂（`.p8` 文本 / 服务账号 JSON / APIv3 对称密钥 / 商户 RSA 私钥），且轮换由**渠道方**驱动、需要新旧并存窗口——Secrets 的条目版本化天然承载这两点，KMS 信封包裹则要自管存储与版本并存逻辑。这正是「三把钥匙不共用托管配置」在形态上的兑现，不是偷懒。
- **新旧并存的表达**：secret JSON 载荷内含 `credentials[]` 数组，每项带渠道侧标识（Google 的 key id / Apple 的 `keyId` / 微信的证书序列号）与可选生效边界；验票代码按渠道侧标识选用，轮换 = 先追加新项、渠道侧切换确认后删旧项。**不设「秒级双活切换」机制**——渠道方的轮换窗口以天计，追加-确认-删除三步足够。
- **读取形态**：进程启动拉取进内存 + **周期刷新**（间隔初值 5 分钟，运维旋钮、待实测校准），换凭据**不重启、不发版**。凭据只在内存，沿用「不落盘、不进环境变量、不进镜像」纪律。
- **权限与审计**：验票服务的运行角色对这些条目**只读**；写入只经部署 / 运维角色；审计线独立于两把签名密钥（第三条审计线）。
- **失效告警衔接**：凭据拉取失败或渠道 API 回 401/403 → 既有 P1 告警面（`purchase-ops.md` §4），本方案零新增机制。

### 子项 2 —— 逐渠道细目（进不进 Secrets 的分界：是不是秘密）

`[通行做法]`（版本 / 产品行为假设，**接入时以官方文档核实**）

| 渠道 | 进 Secrets | 不进 Secrets（公开材料，走配置 / 代码 / 自动拉取） |
|---|---|---|
| Google Play | Play Developer API 服务账号 JSON key（权限只给查询 + 消费，既定） | `packageName`（本就取自身配置，`purchase.md` §3a） |
| App Store | IAP `.p8` 私钥 + `keyId` + `issuerId` | **Apple 根证书**——公开证书不是秘密，随镜像 / 配置分发并保留更新通道（`purchase-ops.md` §1 已要求「须有更新通道」），不占 Secrets |
| 微信支付 | 商户 API 私钥 + 证书序列号 + APIv3 密钥 | **微信平台证书 / 公钥**——由官方接口定期拉取 + 本地缓存（以 APIv3 密钥解密下载），新旧并存由拉取逻辑天然承载；它是渠道下发的材料，不由我方托管 |

- Google 侧**首版用服务账号 key + 例行 90 天轮换**；「工作负载身份联合」（免长期 key）是更优方向，但腾讯云 → GCP 的跨云 OIDC 联合配置成本高、可行性**待接入实测核实**——留作后续优化，不作首版前提。备选记录见下。
- 微信首版不开通（用户已裁决，09-03 handoff）⇒ 微信条目**随资质开通时再建**，Secrets 结构先按三渠道设计、条目后补——契约面与托管结构零变更，与 `purchase.channel_disabled` 的「开通时只删实现分支」同一形态。

### 子项 3 —— `rejected` 原因 = 复用终态 `code`，不新造取值集

`[既有推演]`

`GET /v1/purchase/receipt/{receiptId}` 的应答在 `status = rejected` 时附一个 `code` 字段（应答体内的普通字段，不是错误体——本次请求本身是成功的），取值 = **该收据最近一次 verify 产生的终态 `code`**，取值域是 §6 台账既有条目的子集：

| 取值 | 何时置入 |
|---|---|
| `purchase.receipt_invalid` | verify 判无效（签名 / 环境 / SKU / 金额 / 归属不符、已关单 / 已退款首验） |
| `purchase.receipt_claimed` | 该收据已被其他账号核销 |

- **只有这两条能把记录置为 `rejected`**：`receipt_pending` / `server.unavailable` 不写终态；`payload_invalid` 连幂等记录都不落；`channel_disabled` 发生在下单、无收据。这是「与 verify 失败面同源」的机械兑现——**不新造枚举、不给 §6 台账加行**，客户端处置照既有 `code` 映射（对侧 `ADR-0140` 零新增）。
- 可选附 `detail` 同形透传（`{ platform, channelCode? }`，与 §6 台账该 `code` 的 `detail` 形状一致），只作日志，客户端不解析（既定纪律）。
- `receipt_claimed` 的脱敏纪律照搬 §3：**绝不含另一账号的任何标识**。

## 具体形态（可 derive 的落地面）

**`operations/purchase-ops.md` §1 追加（托管形态小节）：**

```
托管载体：云 Secrets（SSM，底层 KMS 加密）；条目粒度 = 渠道 × 环境。
载荷：JSON { credentials: [ { channelKeyId, material…, addedAtUtc } ] }（新旧并存 = 数组多项）。
读取：启动拉取 + 周期刷新（初值 5 min，旋钮、待实测校准）；凭据只在内存。
权限：运行角色只读 / 部署角色可写；审计线独立（第三条，不与两把签名密钥共线）。
```

**`contracts/purchase.md` §4 补一句（契约变更，走完成判据；spec 未落笔故条 2 无对象）：**

```
`rejected` 时附 `code`（取值 ⊂ { purchase.receipt_invalid, purchase.receipt_claimed }，
即该收据最近一次 verify 的终态 code）与可选 `detail`（形状同 §6 台账该 code 的 detail 列）。
```

## 后果

- `open-questions/06-platform-stack.md` 的「三渠道验票凭据的托管形态（部分答结）」条可整条移出（由 `/analyze-new-ideas` 执行）。
- `operations/environments.md`「密钥保管」宜补一行指路（第三把钥匙在 `purchase-ops.md` §1），不复述。
- `contracts/purchase.md` §4 的一句补充属报文面变更 → 对侧 handoff 互链义务成立；但客户端**处置零新增**（`ADR-0140` 既有映射覆盖），对侧只需知会。
- 就绪度影响本草稿不评估（归 `/assess-derive-readiness`）；但如实记录：08-30 就绪度表对 `purchase.md` 的「blocked · 卡点一字未动」陈述已被 09-03 的落笔超越，属台账滞后。

## 备选方案（已考虑并否决）

- **渠道凭据也走「KMS 包裹 + 启动解包」**（与签名密钥同形）— 形态杂、轮换由渠道方驱动需并存窗口，自管版本并存等于重造 Secrets 已有的东西；且违反「三把钥匙不共用托管配置」的精神（共用形态是共用配置的前奏）。
- **凭据进环境变量 / 配置中心明文** — 与 `environments.md`「密钥永不进环境变量明文」正面相悖。
- **Google 首版即上工作负载身份联合** — 跨云 OIDC 联合的配置与排障成本高，且渠道接入本身已是首版关键路径；key + 例行轮换是行业常态，联合留作优化。
- **`rejected` 原因新造独立枚举（如 `{ Invalid, Claimed }`）** — 同一事实两套取值集，与 §6 台账构成第二权威；且客户端要为它再建一张映射表，`ADR-0140`「不建逐 code 表」的对侧纪律会被间接绕开。
- **`rejected` 原因放进错误体**（让 GET 直接回错误）— 本次请求成功、收据状态是数据不是错误；且会与「纯读、幂等」的端点定位相抵。

## 与既有决策的张力

- **`status` 三值的大小写。** `ADR-0013` 冻结 `{ unknown, verified, rejected }`（小写），而 `envelope.md` §2 的枚举约定是「取值与客户端 C# 成员名逐字相同」（PascalCase）——`inbox/archive/solution-draft-compliance-endpoint-payloads.md` 已点过一次这处不一致。本草稿新增的 `code` 字段不受影响（`code` 本就是点分小写域名形态），但 **spec 首落时须对 `status` 三值裁决一次**（改 PascalCase 属破坏性变更？——尚无任何实现，此刻改的成本为零，拖到实现后成本最高）。本草稿不代裁，仅登记。
  → 已裁决（2026-09-06 · 批量评审）：统一改 PascalCase `{ Unknown, Verified, Rejected }`，同批改 `ADR-0013` 一行与 `purchase.md` §4；不记显式例外、不挂起到 spec 首落。

## 前置依赖

- **微信开放平台资质**（`06` 分片，**首个玩家建号前必须完成**）——微信条目的建立时点挂在它之后；不阻塞本方案其余部分。
- **counterpart 互依**：客户端封装层（`game-design-documents/inbox/solution-draft-iap-channel-integration.md`）产出的逐渠道凭据必须与 `purchase.md` §3a 三表逐字对位（客户端侧按回链取形态、不另立表）；两份草稿须**同批采纳**，单侧采纳即两侧不一致。托管形态本身（子项 1 · 2）不依赖客户端。

## 仍需用户决定

（无——两个子项均可由既有约定与通行做法推演得出；Google 的 key vs 联合已按通行做法直接建议并留备选记录。）
