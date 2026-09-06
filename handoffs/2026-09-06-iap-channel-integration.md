# 渠道验票凭据的托管形态 + 补查端点 `Rejected` 原因取值

- id: 2026-09-06-iap-channel-integration
- date: 2026-09-06
- topic: operations/purchase-ops §1 · contracts/purchase §4 · operations/environments
- status: distilled
- distilled-to: `operations/purchase-ops.md`（§1 托管形态小节 + 逐渠道 Secrets 分界表）、`contracts/purchase.md`（§4 `Rejected` 附 `code` · `status` 三值 PascalCase 及 §3b / §6 字面值同批统一）、`decisions/ADR-0013-receipt-idempotency-and-read-your-writes.md`（`status` 一行）、`operations/environments.md`（密钥保管指路一行 + 旋钮清单一行）、`answer-logs/log-iap-channel-integration.md`
- counterpart: `game-design-documents/handoffs/2026-09-06-iap-channel-integration.md`（客户端半：SDK 选型与封装层，同批落笔、互相回链）

## Intent（distilled）

平台内购跨边界依赖的后端余项只剩两小块：三把钥匙中渠道验票凭据这把的**托管形态**（前两把的保管早已落 `operations/environments.md`，且三者不共用托管配置），以及 `GET /v1/purchase/receipt/{receiptId}` 在 `Rejected` 时所附**原因的字段与取值域**。本次把两块收口；渠道接入面（逐渠道 `receipt` 形态、五条 `purchase.*` 码、对账通道、`receiptId` 幂等窗口）均为硬前提，不重开。

### 一、托管载体 = 云 Secrets 条目（SSM，底层 KMS 加密）

- 条目粒度 = **渠道 × 环境**，值为 JSON 载荷；载荷内 `credentials[]` 数组承载**新旧并存**（每项带渠道侧标识与可选生效边界，轮换 = 追加-确认-删除三步，不设秒级双活）。
- **不复用签名密钥的「KMS 包裹 + 启动解包」形态**：渠道凭据是向外调用的客户端凭据，形态杂、轮换由渠道方驱动需并存窗口——Secrets 的条目版本化天然承载这两点；这正是「三把钥匙不共用托管配置」在形态上的兑现，不是偷懒。
- **读取**：启动拉取进内存 + 周期刷新（间隔初值 5 分钟，运行期可调旋钮、待实测校准），换凭据不重启不发版；凭据只在内存。
- **权限与审计**：运行角色只读、写入只经部署 / 运维角色，审计线独立于两把签名密钥（**第三条审计线**）。失效衔接既有 P1 告警面（渠道 API 401/403），零新增机制。
- **逐渠道分界（判据：是不是秘密）**：Google 服务账号 key 进 Secrets（首版 key + 例行 90 天轮换，跨云工作负载身份联合留作后续优化的备选记录）；Apple `.p8` + `keyId` + `issuerId` 进、根证书不进（公开材料，随镜像 / 配置分发并保留更新通道）；微信商户私钥 + 证书序列号 + APIv3 密钥进、平台证书不进（官方接口拉取 + 本地缓存）。**微信条目随资质开通时再建**，Secrets 结构先按三渠道设计——契约面与托管结构零变更。

### 二、`Rejected` 原因 = 复用 verify 终态 `code`，不新造取值集

`GET /receipt/{receiptId}` 在 `status = Rejected` 时附应答体普通字段 `code`（不是错误体——本次请求成功，收据状态是数据不是错误），取值 = 该收据最近一次 verify 的终态 `code`，取值域 ⊂ { `purchase.receipt_invalid`, `purchase.receipt_claimed` }——只有这两条能置终态（`receipt_pending` / `server.unavailable` 不写终态、`payload_invalid` 不落记录、`channel_disabled` 无收据）。可选 `detail` 同形透传（形状同 `envelope.md` §6 台账该 `code` 的 `detail` 列），`receipt_claimed` 的脱敏纪律照 §3。**不给 §6 台账加行、客户端处置零新增。** 契约变更完成判据核对：spec 未落笔故 spec 同批条无对象；无新 `code` 故台账条无对象；对侧 handoff 互链由 counterpart 对满足。

### 三、`status` 三值统一 PascalCase `{ Unknown, Verified, Rejected }`

`envelope.md` §2 的枚举约定是「取值与客户端 C# 成员名逐字相同」（PascalCase），而 `ADR-0013` 冻结的三值为小写——尚无任何实现，此刻改成本为零。同批改 `ADR-0013` 一行、`purchase.md` §4，并扫尾库内其余小写字面值（`purchase.md` §3b 预落记录与关单句 · §6 保证 3 覆盖句 · `operations/purchase-ops.md` §2 关单句与 §3a 判据表 S3 行）；不记显式例外、不挂起到 spec 首落。

## Clarifications

- **`status` 三值的大小写张力（草稿仅登记、不代裁）** → 统一改 PascalCase `{ Unknown, Verified, Rejected }`，同批改 `ADR-0013` 与 `purchase.md` §4，不记显式例外、不挂起到 spec 首落（2026-09-06 批量评审裁决）。
- **扫尾面**：除点名的两处外，库内其余 `status` 小写字面值同批统一（§3b · §6 保证 3 · `purchase-ops.md` §2 与 §3a S3 行）——留小写残留即制造新的不一致；`systems/profile-store.md` 无字面值、不动（自行推演，依据裁决「不记显式例外」的必然延伸）。
- **托管细目按既有约定与通行做法直接落笔**（云 SSM Secrets · `credentials[]` 并存 · 5 分钟刷新旋钮 · 逐渠道分界 · Google 联合留备选）——均可由 `environments.md` 配置分层、`purchase-ops.md` §1 既有轮换特征与行业通行做法推演，非取向问题。

## Open questions

（无——本 handoff 范围内无用户当下答不出的远期未知。冷存归档与对账阈值等既有余项仍在 `open-questions/06-platform-stack.md`，不属本次范围。）

## Notes / triage

- 路由：托管形态 → `operations/purchase-ops.md` §1；`Rejected` 原因与 PascalCase → `contracts/purchase.md`；指路与旋钮 → `operations/environments.md`；`status` 一行 → `decisions/ADR-0013`。
- 答结移出：`open-questions/06-platform-stack.md` 的「三渠道验票凭据的托管形态（部分答结）」整条 → `answer-logs/log-iap-channel-integration.md`。
- 08-30 就绪度表对 `purchase.md` 的旧陈述已被后续落笔超越，属台账滞后——如实记录，归 `/assess-derive-readiness` 处理，本次不触碰就绪度小节。

## 客户端侧影响

本 handoff 对客户端 ↔ 后端边界的报文面只有一处变更：**§4 补查应答在 `Rejected` 时附 `code` 与可选 `detail`**。客户端**处置零新增**（两条 `code` 均为既有台账条目，`ADR-0140` 的既有映射覆盖）——仅知会，无需对侧新增任何映射行或文案键。`status` 三值 PascalCase 与客户端枚举成员名逐字对位（对侧 `ReceiptStatus { Unknown, Verified, Rejected }`），`StorePlatform` 成员名两侧同批冻结——受影响成分：sync-service（形态见 counterpart handoff，本库不复述）。托管形态半（子项一）对客户端零义务。
