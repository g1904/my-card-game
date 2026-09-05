# 系统 —— 后端设计意图索引

后端各服务的动态设计文档：每个服务一份文档（或复杂时下沉为文件夹，含 `_index.md`）。此处描述**服务内部怎么实现**；边界报文归 `contracts/`，客户端侧的用法归 `game-design-documents/systems/services/`。

## 现状

协议契约六份已成文（`contracts/envelope.md` · `content-manifest.md` · `auth.md` · `profile-sync.md` · `purchase.md` · `compliance.md`）。技术栈与托管形态为 **C# / ASP.NET Core · 腾讯云托管容器 · 云数据库 PostgreSQL（单主）· 云 Redis · 云 KMS · CDN**（运行时形态见 `operations/`），服务内部设计所需的存储、并发控制与会话形态因此有了确定的地基。

- `account.md` · `profile-store.md` —— 已建立。
- `content-delivery.md` —— 尚未建立。它的**运维形态**已成文（`operations/content-delivery-ops.md`），欠的是服务内部形态所依赖的两项：剧本内容的体积与分发形态、多区域一致性与传播窗口（`open-questions/04-content-delivery.md`）。按「先有设计再建文件」不预先占位。

## 服务

| 文档 / 文件夹 | 职责 | 对位的客户端成分 |
|---|---|---|
| `account.md` | 账号、鉴权、会话、多设备裁决、合规能力（注销 / 导出）、昵称判定链与未过审昵称的存量扫描的服务内部形态 | `account-service` |
| `profile-store.md` | 权威 profile 存储、`revision` 计数器与 CAS、`pushId` 幂等窗口 | `sync-service` |
| `content-delivery.md` | overlay 构建与分发、`manifest.json`、放量 / 秒关开关、**剧本文本随内容一并发布** | `content-service` |

**只有三个服务，对位三个跨边界的客户端成分。** 剧本服务已于 2026-08-11 撤销：剧本内容本地化为客户端内容层的一员，由 `content-delivery` 以普通内容文件承接，后端不再有剧本形态的服务。
Source: `handoffs/2026-08-11-plot-service-retired.md`。

## 共用的存储与并发形态（三份服务文档的公共前提）

下面这一组前提**对本文件夹的每份服务文档同时成立**，各文档不重复论证，只在需要处引用。

- **单库 PostgreSQL 承载全部权威状态。** 账号 / identity / 会话 / profile / 幂等记录同处一库，因此契约要求的「幂等记录与计数器自增同一次事务」是**一次普通的本地事务**，零分布式事务、零两阶段提交。
- **并发单元统一为 `account` 行。** 会话写入与 profile 写入争用同一把行锁，故「一台设备正在 push、另一台正在 signin」有确定的串行顺序，全库只有一套并发模型。
- **profile 文档以 `jsonb` 承载。** `jsonb` 的 `||` 运算符恰好是「顶层键整键替换、不递归」，与 `contracts/profile-sync.md` §3a 的合并语义逐字吻合；它**不是** RFC 7386（没有以 `null` 表示删除的语义），因而与该节对 JSON Merge Patch 的否决天然不冲突。
- **体积余量充足。** `jsonb` 走 TOAST 与压缩，单值上限远高于 `profile-sync.md` §12 的 512 KB 软告警——软告警是观测口径，不是存储能力的边界。
- **三条契约条款直接落为数据库不变式**，不靠应用层检查（并发下只有约束是可靠的）：

  | 契约条款 | 数据库形态 |
  |---|---|
  | 单账号活跃会话上限 1（`auth.md` §4a） | 部分唯一索引 `UNIQUE (account_id) WHERE revoked_at_utc IS NULL` |
  | `(accountId, deviceId)` 唯一（同上） | 普通唯一约束 |
  | `receiptId` 全局唯一、不带账号前缀（`purchase.md` §7） | 全局唯一索引；「已被其他账号核销」因此是一次索引冲突，而不是一次应用层查重 |

- **Redis 只承担限流计数器，不持有任何权威状态。** 它不可用时限流退化为不限流并告警，不影响任何正确性语义（验证码类计数是例外，见 `operations/environments.md`）。按账号的 flags 缓存是否引入归内容分发侧裁决；若引入，缓存键必须含 `flagsVersion`（`decisions/ADR-0009-*`）。
- **字段名用 `snake_case`，报文用 lowerCamelCase**，两者在序列化边界一次映射。

## 明确不引入

逐条给理由，使它们不必被反复重新提出：

- **独立的文档数据库** —— profile 已是 `jsonb`；再加一套存储会把「幂等记录与计数器同事务」拆成跨存储写入，正是 `contracts/profile-sync.md` §9 与 `purchase.md` §7 点名的失败态（`revision` 已推进但幂等记录未落）。
- **消息队列** —— 本域没有需要削峰或跨服务解耦的写入；把 push 异步化会当场破坏「账号级线性化读改写」与「push 应答必须回 `newRevision`」的同步语义。风控事件与告警走日志 / 指标出口即可。
- **分布式事务协调器** —— 单库内已满足全部原子性要求，引入它只是给自己造一个新的故障域。
- **分片 / 多主 / 读写分离** —— 账号级严格单调计数器在多主下无法维持（`contracts/profile-sync.md` §8），而读己所写排除了无条件承接玩家读路径的滞后副本（`decisions/ADR-0013-*`）。它们要解决的规模问题，在契约定义的写入频率下不存在（容量算式见 `operations/environments.md`）。规模真的到来时，纵向扩容 + 按 `accountId` 的单主分区（分区内仍线性化）是保住线性化的扩展方向。

Source: `handoffs/2026-09-03-backend-stack-and-hosting.md`。

## 约定

- **文件名与它所服务的客户端成分对齐**，使一个 handoff 能干净地映射到两侧同一处。
- **不复述客户端设计。** 需要客户端语义时回链 `game-design-documents/`，只在本库写「后端如何兑现它」。
- **持续更新，只保留最新设计**：内容被取代 / 迁移时直接重写替换，不留考古（见 `README.md` 的维护约定）。
