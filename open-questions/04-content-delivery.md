# ④ 内容分发（协议与运维形态均已成文 · 余下两条）

> **协议侧四条已于 2026-08-11 全部答结** → `contracts/content-manifest.md`（manifest schema 与三版本号分工、blob 内容寻址、ES256 detached 签名与 `keyId` 轮换、`ContentEnabled` 的 flags 第三层）。移出记录见 `answer-logs/log-content-delivery-manifest-and-flags.md`。
> 客户端侧见 `game-design-documents/systems/services/content-service.md`。

> **三条运维形态已于 2026-09-03 答结** → `operations/content-delivery-ops.md`（flags 规则集的存储形态与变更通道 · 签名私钥的五条保管判据与 `keyId` 轮换的触发 / 节奏 / 覆盖率口径 · 发布侧内容校验闸 C1–C6 与留痕八字段）。移出记录见 `answer-logs/log-content-delivery-ops.md`。

余下两条都不是协议问题，而是**运维形态**，且各有各的前置：剧本分包边界待内容规模落定，多区域一致性与传播窗口 T 与 `02-account-compliance.md` 耦合。

- **剧本内容的体积与分发形态。**（2026-08-11 新增）剧本本地化后（原云端剧本服务撤销，见 `contracts/content-manifest.md` 的「剧本文本」一节），全部剧本文本进入 overlay 的分发量——原云端方案的「按需请求」天然回避了这个问题。待定：是否需要按篇章分包（`contentRoot` 下多份 manifest？还是单 manifest 内按路径前缀分组），首包与增量下载量的可接受上界，以及由此产生的 CDN 成本模型。**客户端侧同题待答**（分包边界，见 `game-design-documents/handoffs/2026-08-11-plot-content-localization.md` 的 Open questions）——契约形态由本库定，分包边界由内容规模决定，两侧须一致。

- **多区域内容分发的一致性。** 若国内渠道要求内容分发也在境内，`contentRoot` 需按区域下发（`contentRoot` 已被排除在被签名的 manifest 之外，正是为留出这个自由度）；但**多区域间 `contentVersion` 是否必须同步推进**、区域间发布的时序差如何处置，未定。与 `02-account-compliance.md` 耦合。
  **本条现在多背一个具体的数值缺口：flags 的传播窗口 T。** 契约已定「新批次须在窗口 T 内在全部区域可见，窗口内客户端观测到更小版本是已知良性态」，**T 的数值上界留在本条**（`contracts/content-manifest.md`「服务端保证」B 组的失效来源表）。

## 已推给别处的（不在本片跟踪）

| 事项 | 归属 |
|---|---|
| 字段名 / 端点风格 / 序列化形态 / 错误码分层 | `01-contracts.md`（契约表达形式） |
| 信封携带 `flagsVersion`、`minAppVersion` 与强更闸门的分工 | `01-contracts.md` → `contracts/envelope.md` |
| CDN 厂商与托管形态选型 | `06-platform-stack.md` |
| **flags 的客户端持久化形态** | **已答**（2026-08-30 · 客户端裁决）：落 `user://cache/flags.json`，带 `schemaVersion`、写入时点唯一为「通过单调闸并被应用之后」、三条失效语义、不设 TTL。收益口径**不是**离线开局（强制在线下无权威档即不可玩），只有「登录成功但 flags 拉取失败」时的降级值。权威见 `game-design-documents/systems/services/content-service.md`。本库对该缓存的义务为零 |
