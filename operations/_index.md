# 运维 —— 部署 · 环境 · 可观测性（索引）

后端的运行时形态：部署与环境分层、发布流程、监控与告警、合规运维（数据存放地、留存与删除）。与 `systems/`（服务内部设计）分开——此处回答「它跑在哪里、怎么发布、怎么看它是否健康」。

## 现状

**尚未建立。** 技术栈与托管形态未定（`open-questions/06-platform-stack.md`）。

已就位的只有分支线：`backend-feature → backend-testing → backend-production`（本地文件夹映射见 `main/README.md`），但对应的**环境实体尚不存在**。

## 计划中的文档

| 文档 | 覆盖 |
|---|---|
| `environments.md` | 环境分层与配置分离、三条分支对应的实体环境 |
| `deployment.md` | 构建与发布流程、回滚 |
| `content-delivery-ops.md` | **内容分发的运营面**（首批有具体对象，见下）：CDN 缓存策略、内容发布与回滚流程、flags 数据源与灰度分桶、签名私钥保管与轮换 |
| `observability.md` | 日志 / 指标 / 追踪的最小集合；同步正确性的线上探针（「本地领先」异常率、`pushId` 去重命中率）；`X-Request-Id` ↔ `requestId` 的两侧日志贯通 |
| `compliance-ops.md` | 数据存放地、留存与删除、账号注销与导出的运维侧流程 |
| `version-matrix.md` | **版本兼容矩阵**（见下）：强更闸门判定的输入，与判定逻辑同处 |

## 已有具体对象的运维面：内容分发

> 语义权威在 `contracts/content-manifest.md`；此处只记它对运维形态的**要求**。栈落定后展开为 `content-delivery-ops.md`。
> Source: `handoffs/2026-08-11-content-delivery-manifest-signing-and-flags.md`。

- **CDN 缓存：两类对象两种 TTL。** `/blobs/<hash>` 内容寻址 → `public, max-age=31536000, immutable`（可永久缓存）；manifest / flags 端点 → `no-cache` 或秒级 TTL——**秒关与回滚的实际生效速度由后者决定**。
- **发布流程（顺序即正确性）：** ① 计算全部 overlay 文件 SHA-256，推送缺失 blob（幂等：已存在的 hash 跳过）；② 生成 manifest（`contentVersion` = 上一版 +1），用当前 `keyId` 的私钥对**原始字节**做 ES256 签名；③ **确认全部 blob 可读后**再发布 `.sig` 与 manifest（`.sig` 先于或与 manifest 同一次原子切换，避免读到无签名的 manifest）；④ **回滚 = 重跑 ①–③，manifest 指回旧 blob，`contentVersion` 继续 +1**（不允许版本号回退）；⑤ **秒关 / 灰度不走本流程**——改 flags 数据源即可，不触碰 blob 与 manifest。
- **签名私钥保管进入运维范围：** 私钥存放（KMS / 密钥托管）与 CI 中的签名步骤，**反向约束 `open-questions/06-platform-stack.md` 的托管选型**。`keyId` 轮换是「先发内置新旧两把公钥的客户端版本 → 覆盖率足够后切私钥」，因此轮换窗口跨越一个客户端发版周期。
- **对 CDN 的能力要求**（不算苛刻，主流 CDN 均满足）：按路径设置差异化 `Cache-Control`、支持 immutable 长缓存、支持 `contentRoot` 域名切换（`contentRoot` 不在被签名的 manifest 内，故切换无需重签历史 manifest）。

## 已有具体对象的运维面：版本兼容矩阵与错误码台账

> 语义权威在 `contracts/envelope.md`；此处只记它对运维形态的**要求**。栈落定后展开为 `version-matrix.md` 与 `observability.md`。
> Source: `handoffs/2026-08-11-contract-expression-envelope-and-error-codes.md`。

- **版本兼容矩阵由后端单点维护，客户端不持有任何副本。** 它是强更闸门服务端判定的**输入**，必须与判定逻辑同处。至少含：支持的 `appVersion` 下界 · 并存的 URL 主版本（`/v1/` …）· 并存的 `manifestSchema` / `schemaVersion` 集合 · 各自的**下线计划**。
- **闸门在签发 token 时判定一次**（`envelope.md` §7b）——运营提升 `appVersion` 下界这个动作，其生效点是玩家**下一次登录**，永远不会打断进行中的轮回。运维流程需据此说明「提升下界后多久覆盖存量会话」，而不是假定即时生效。
- **错误码台账的登记流程。** `code` 是**永不复用、永不改写含义**的稳定标识，`class` 是契约的一部分（同一 `code` 不得因请求而变）。因此新增 / 变更 `code` 是**契约变更**，须先改 `contracts/envelope.md` §6 的台账、再改服务端实现——不允许服务端先发一个未登记的 `code`（客户端会按 `class` 降级，而未知 `class` 会被当作 `Fatal` 上报）。
- **`message` 的落日志纪律进运维范围**：`message` 必填且必须写到能定位问题，同时**不得含 token / 完整凭据 / 密钥**，账号与 `pushId` 一类标识按前缀截断。日志脱敏规则与这条同批落地。
- **统计计数层的运维禁令**：后端不复算、不校验统计计数，**且不得用统计数据驱动任何发放**（活动奖励 / 解锁）。一旦某个统计字段被用于发放，它就必须整体升为规则字段并进 `profile-sync.md` 的「后端可见字段子集」。这是一条**运营侧也要遵守**的约束，不只是实现约束。

## 约定

- **可观测性口径与协议同批定案。** 探针指标（见上表）由契约的语义决定，不能等服务上线后补。
- 只保留最新设计；历史归 git。
