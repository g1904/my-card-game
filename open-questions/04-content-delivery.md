# ④ 内容分发（CDN · 协议已定案，剩运维与选型）

> **协议侧四条已于 2026-08-11 全部答结** → `contracts/content-manifest.md`（manifest schema 与三版本号分工、blob 内容寻址、ES256 detached 签名与 `keyId` 轮换、`ContentEnabled` 的 flags 第三层）。移出记录见 `answer-logs/log-content-delivery-manifest-and-flags.md`。
> 客户端侧见 `game-design-documents/systems/services/content-service.md`。

余下条目都不是协议问题，而是**运维形态与选型**——它们的共同前置是 `06-platform-stack.md`。

- **flags 数据源与灰度分桶的运营形态（余下部分）。** 分桶规则已定**留在服务端**、只下发结果；**审计留痕已于 2026-08-23 答结**（四项最低要求 + 规则集不可变版本化 O1–O7，见 `operations/_index.md`）。未定的只剩：规则存在哪（配置表 / 数据库 / 控制台）、由谁改、`GET /v1/content/flags` 的按账号计算是否需要缓存层——**若引入缓存层，缓存键必须含 `flagsVersion`** 已是硬约束（`contracts/content-manifest.md`「服务端保证」B 组）。→ 落点 `operations/`。

- **签名私钥的保管与 CI 签名步骤。** ES256 私钥存放形态（KMS / 密钥托管）与发布流水线中的签名环节未定，**反向约束 `06-platform-stack.md` 的托管选型**。`keyId` 轮换窗口跨越一个客户端发版周期（先发内置新旧两把公钥的版本，覆盖率足够后切私钥），轮换的触发条件与节奏未定。

- **剧本内容的体积与分发形态。**（2026-08-11 新增）剧本本地化后（原云端剧本服务撤销，见 `contracts/content-manifest.md` 的「剧本文本」一节），全部剧本文本进入 overlay 的分发量——原云端方案的「按需请求」天然回避了这个问题。待定：是否需要按篇章分包（`contentRoot` 下多份 manifest？还是单 manifest 内按路径前缀分组），首包与增量下载量的可接受上界，以及由此产生的 CDN 成本模型。**客户端侧同题待答**（分包边界，见 `game-design-documents/handoffs/2026-08-11-plot-content-localization.md` 的 Open questions）——契约形态由本库定，分包边界由内容规模决定，两侧须一致。

- **发布侧内容校验闸的运维形态。**（2026-08-16 新增 · 客户端承接项）客户端已定 overlay 的两条合并期闸（新增 `Id` 的宿主类型必须是剧本类型 · 新增剧本条目引用的非剧本 `Id` 必须来自基线），并明确这类纪律的客户端天花板只到启动期 `PushError`——检查对象是 `.tres` 的**引用图**，编译期手段够不着。等价的更强形态是**把同一份校验前移到发布侧：产包前跑一遍，不通过就不产出包**（判据、闸的规则与「必须内嵌在打包工具本身、否则退化为评审级」见 `game-design-documents/systems/services/content-service.md` 与 `.../systems/architecture.md`「纪律的可执行化」）。
  **落本库的理由**：执行时点在发布流程上（推 blob → 推 manifest 之前），而本库已定「manifest 与它列出的全部文件在发布上是原子的」。**待定**：校验在哪一步跑、由谁触发、失败如何阻断发布、是否需要留痕，以及它与签名步骤的先后。**校验逻辑本身归客户端**（复用其 `LoadAll()` 路径），本库不实现、不复述其规则。→ 落点 `operations/`；共同前置 `06-platform-stack.md`（与上一条的 CI 签名环节多半是同一条流水线）。

- **多区域内容分发的一致性。** 若国内渠道要求内容分发也在境内，`contentRoot` 需按区域下发（`contentRoot` 已被排除在被签名的 manifest 之外，正是为留出这个自由度）；但**多区域间 `contentVersion` 是否必须同步推进**、区域间发布的时序差如何处置，未定。与 `02-account-compliance.md` 耦合。
  **本条现在多背一个具体的数值缺口：flags 的传播窗口 T。** 契约已定「新批次须在窗口 T 内在全部区域可见，窗口内客户端观测到更小版本是已知良性态」，**T 的数值上界留在本条**（`contracts/content-manifest.md`「服务端保证」B 组的失效来源表）。

## 已推给别处的（不在本片跟踪）

| 事项 | 归属 |
|---|---|
| 字段名 / 端点风格 / 序列化形态 / 错误码分层 | `01-contracts.md`（契约表达形式） |
| 信封携带 `flagsVersion`、`minAppVersion` 与强更闸门的分工 | `01-contracts.md` → `contracts/envelope.md` |
| CDN 厂商与托管形态选型 | `06-platform-stack.md` |
| **flags 是否落地客户端本地缓存以支撑离线开局** | **客户端侧**（`game-design-documents/`）——本定案唯一未闭合的语义缺口，归客户端裁决 |
