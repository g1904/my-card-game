# Answer log content-delivery-manifest-and-flags

- 日期：2026-08-11
- 来源：`inbox/archive/solution-draft-content-delivery-manifest-and-flags.md` → `handoffs/2026-08-11-content-delivery-manifest-signing-and-flags.md`
- 移出条数：4（`open-questions/04-content-delivery.md` 的全部协议侧条目）

---

**增量下载的粒度与失败恢复（逐文件 hash vs 整包版本、断点续传 / 回滚、避免半套 overlay）**
→ **服务端无状态**：不设下载会话、无断点协商、无下载令牌、不记录客户端进度；只保证三件事——每个文件有独立可 GET 的稳定 URL、URL 字节不可变（**内容寻址 `/blobs/<sha256>`**）、manifest 与其列出文件的发布是原子的（**先推全部 blob、后推 manifest**）。事务模型全部由客户端已定的 staging → 校验 → 搬入 → 原子 rename 承担。**回滚 = 前滚**：`contentVersion` 严格单调递增，撤回坏 overlay 靠发布更大的版本指回旧 blob。字节级断点续传不做、不写进契约、客户端不依赖。
（归档去向：`contracts/content-manifest.md` §服务端保证 / §版本化 · `operations/_index.md` §发布流程 · ADR 候选①）

**overlay 防篡改（是否需服务端签名及签名方案）**
→ **ES256（ECDSA P-256 + SHA-256）detached 签名**，签 manifest 的**原始字节**而非规范化后的 JSON（内嵌签名要求两侧规范化重序列化，差异会造成设备上无法复现的随机验签失败）。签名信封 `{alg, keyId, sig}`，**`keyId` 从第一天就在**，客户端内置一组 `keyId → publicKey` 映射以支持轮换。文件 hash = SHA-256 小写 hex。不引入证书链 / PKI（威胁模型只到防误 / 防随手改）。防回放靠 `contentVersion` 单调性，**不做绝对时间 TTL**（设备时钟不可信）。flags 走同一密钥体系。
（归档去向：`contracts/content-manifest.md` §防篡改 · `operations/_index.md` §签名私钥保管）

**`manifest.json` 的 schema 与版本化**
→ 字段：`manifestSchema` · `contentVersion` · `generatedAt` · `minAppVersion` · `files[].path/hash/size`。`files` 是**全量清单**（不在清单里 = 应从 overlay 删除），blob URL 不写进条目、由 `contentRoot` 拼出，`ContentEnabled` 不在 manifest 里。`manifestSchema` 只在破坏性变更时 +1、客户端必须忽略未知字段、破坏性变更时并存 N-1 与 N 两版端点。**三版本号分工**：`appVersion`（二进制）/ `manifestSchema`（结构）/ `contentVersion`（内容）；**`manifestSchema` 不受支持时降级到基线而非强更**，强更归 `envelope` 的版本协商。`minAppVersion` 比较规则 = **semver 三段数值比较**（interview 裁决）。
（归档去向：`contracts/content-manifest.md` §manifest schema / §版本化。**同时答结客户端侧 `content-service.md` 的「`manifestSchema` 的版本化」待决项**——客户端侧的落笔归客户端 handoff）

**放量与秒关开关的下发通道（随 overlay 全量分发 vs 独立通道）**
→ **独立 flags 通道，作为合并的第三层**，只覆盖 `ContentEnabled`（`res://基线 < overlay < flags`）。硬边界：**只能覆盖这一个布尔，不得携带数值 / 文案 / 新 `Id`**。**灰度分桶留在服务端**，只下发按账号解析完的结果（`disabledIds`）；**刷新靠信封搭载 `flagsVersion`，零轮询**，秒关延迟为分钟级。`enabledIds` 保留字段、初期恒空。flags 报文中的 `contentVersion` **仅信息性，客户端不据此判断**（interview 裁决）。
（归档去向：`contracts/content-manifest.md` §flags 通道 · ADR 候选② · `contracts/_index.md` 给 `envelope.md` 记下 `flagsVersion` 欠账。**同时答结客户端侧 `content-service.md` 的「`ContentEnabled` 粒度是否够用」**——答：分桶留服务端，客户端仍只见布尔，`DrawPool<T>` 不必带 `bucketContext`）

---

**部分答结的说明：** 第 4 条的**服务端侧**已完全定案，但它反向要求客户端新增一个合并层——**「flags 是否落地本地缓存以支撑离线开局」仍未答**，归客户端侧裁决（见 `04-content-delivery.md` 的「已推给别处的」表）。此外 `04` 分片并未清空：三条**运维与选型**条目（flags 数据源与分桶的运营形态、签名私钥保管、多区域一致性）仍在待答清单中。

**跨边界：** 本次裁决松动了客户端 `content-service.md` 的「overlay 是唯一热更层」。客户端侧结论需由 `game-design-documents/` 另写一份 handoff 承载，届时对应 `game-design-documents/answer-logs/log-*.md`。
