# ④ 内容分发（协议与运维形态均已成文 · 余下一条）

> **协议侧四条已于 2026-08-11 全部答结** → `contracts/content-manifest.md`（manifest schema 与三版本号分工、blob 内容寻址、ES256 detached 签名与 `keyId` 轮换、`ContentEnabled` 的 flags 第三层）。移出记录见 `answer-logs/log-content-delivery-manifest-and-flags.md`。
> 客户端侧见 `game-design-documents/systems/services/content-service.md`。

> **三条运维形态已于 2026-09-03 答结** → `operations/content-delivery-ops.md`（flags 规则集的存储形态与变更通道 · 签名私钥的五条保管判据与 `keyId` 轮换的触发 / 节奏 / 覆盖率口径 · 发布侧内容校验闸 C1–C6 与留痕八字段）。移出记录见 `answer-logs/log-content-delivery-ops.md`。

> **剧本内容的体积与分发形态已由对侧答结**（2026-09-05 核对移出）→ 客户端裁定**剧本树不按篇章分包**、整体随 `res://` 基线发布、更新走 overlay 的文件级增量热更，权威见 `game-design-documents/decisions/ADR-0029-plot-tree-single-baseline-package.md`（Accepted）与 `game-design-documents/systems/services/plot-manager.md`。**本库零机制增量**：manifest 不加字段、`manifestSchema` 不提升、报文无变化。余下的下载量上界与 CDN 成本已并入 `06-platform-stack.md` 的成本模型条。移出记录见 `../answer-logs/log-0905.md`。

余下一条不是协议问题，而是**运维形态**。

- **多区域内容分发的一致性与传播窗口 T。** 后端服务侧已定案：**主区在中国大陆境内 · 单区域部署、不做跨区域多活 · 个人信息不出境**（→ `operations/environments.md`「区域与合规」「拓扑与副本」）。**仍未定的是 CDN 侧**：`contentRoot` 按区域下发这条自由度是否启用（`contentRoot` 已被排除在被签名的 manifest 之外，正是为留出它）、多区域间 `contentVersion` 是否必须同步推进、区域间发布的时序差如何处置。
  **本条现在背着一个具体的数值缺口：flags 的传播窗口 T。** 契约已定「新批次须在窗口 T 内在全部区域可见」，窗口内客户端观测到更小版本是已知良性态；**T 的数值上界留在本条**（→ `contracts/content-manifest.md`「服务端保证」B 组的失效来源表，`operations/content-delivery-ops.md` 亦以「运维 SLO 窗口 T」引用它）。与 `02-account-compliance.md` 的渠道 / 备案口径耦合。

## 条件化核对项（不是待办）

承接 `contracts/content-manifest.md`「blob 通道不承载二进制资产」一节的指路。二进制资产**不经 blob 通道下发**是已裁定的否定结论（`game-design-documents/decisions/ADR-0125-no-binary-over-overlay.md`），下列三点**条件化于「日后开放」这一假设**，在开放被提出之前不构成任何待办：

1. `files[].size` 的口径与磁盘预检在 MB 级下的运维含义；
2. A 组「字节级 Range 不写进契约」这条否定**须与对侧同批重估**（对侧那条否决带一个量级前提）；
3. CDN 缓存与回源成本模型（与 `06-platform-stack.md` 的成本模型条同源）。

三点的完整陈述在契约正文同节，本处只承接指路、不复述判据。

## 已推给别处的（不在本片跟踪）

| 事项 | 归属 |
|---|---|
| 字段名 / 端点风格 / 序列化形态 / 错误码分层 | `01-contracts.md`（契约表达形式） |
| 信封携带 `flagsVersion`、`minAppVersion` 与强更闸门的分工 | `01-contracts.md` → `contracts/envelope.md` |
| CDN 厂商与托管形态选型 · **剧本首包与增量下载量的可接受上界 · CDN 成本模型** | `06-platform-stack.md` |
| **flags 的客户端持久化形态** | **已答**（2026-08-30 · 客户端裁决）：落 `user://cache/flags.json`，带 `schemaVersion`、写入时点唯一为「通过单调闸并被应用之后」、三条失效语义、不设 TTL。收益口径**不是**离线开局（强制在线下无权威档即不可玩），只有「登录成功但 flags 拉取失败」时的降级值。权威见 `game-design-documents/systems/services/content-service.md`。本库对该缓存的义务为零 |
| **剧本树是否按篇章分包** | **已答**（2026-09-05 核对 · 客户端裁决 `ADR-0029`）：不分包，整体随基线发布。本库零机制增量、报文无变化 |
