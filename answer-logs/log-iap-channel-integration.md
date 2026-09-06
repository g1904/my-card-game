# Answer log iap-channel-integration

- 日期：2026-09-06
- 来源：`inbox/solution-draft-iap-channel-integration.md` → `handoffs/2026-09-06-iap-channel-integration.md`
- 移出条数：1

## 逐条

**三渠道验票凭据的托管形态（06 分片 · 此前部分答结，本次整条移出）** → **答定**：托管载体 = 云 Secrets（SSM，底层 KMS 加密），条目粒度渠道 × 环境；载荷 `credentials[]` 数组承载新旧并存（渠道侧标识选用，轮换 = 追加-确认-删除三步）；不复用签名密钥的「KMS 包裹 + 启动解包」形态（渠道凭据形态杂、轮换由渠道方驱动需并存窗口，Secrets 条目版本化天然承载——「三把钥匙不共用托管配置」的形态兑现）；读取 = 启动拉取 + 周期刷新（初值 5 分钟，旋钮、待实测校准，进 `environments.md` 旋钮清单）、凭据只在内存；运行角色只读 / 第三条审计线；失效衔接既有 P1 告警面零新增。逐渠道进不进 Secrets 的分界表（Apple 根证书与微信平台证书不进——公开 / 渠道下发材料）；Google 首版服务账号 key + 90 天例行轮换（工作负载身份联合留作备选优化）；微信条目随资质开通后建。（归档去向：`operations/purchase-ops.md` §1「托管形态」；`operations/environments.md` 密钥保管指路一行 + 旋钮清单一行）

## 同批裁决（合并 interview / 批量评审）

- **`status` 三值大小写** → 统一 PascalCase `{ Unknown, Verified, Rejected }`，同批改 `decisions/ADR-0013` 一行与 `contracts/purchase.md` §4，并扫尾 §3b / §6 保证 3 / `purchase-ops.md` §2 与 §3a S3 行的小写字面值；不记显式例外、不挂起到 spec 首落。
- **`GET /receipt/{receiptId}` 的 `Rejected` 原因** → 应答体普通字段 `code` ⊂ { `purchase.receipt_invalid`, `purchase.receipt_claimed` }（最近一次 verify 终态 `code`）+ 可选 `detail` 同形透传；不新造取值集、不给 `envelope.md` §6 台账加行、客户端处置零新增。（归档去向：`contracts/purchase.md` §4）

## 跨边界

客户端半（SDK 选型与封装层、`IPurchaseBackend` 落形、非商店平台入口不渲染）同批落笔于 `game-design-documents/`，见对侧 `handoffs/2026-09-06-iap-channel-integration.md` 与 `answer-logs/log-iap-channel-integration.md`；本 log 不复述其形态。§4 报文补 `code` 对客户端仅知会（既有映射覆盖）。
