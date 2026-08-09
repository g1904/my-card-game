# Open questions — 后端待答清单

> 后端侧的跨 session 待答清单。只跟踪仍待答的问题；一旦答定就移出并归档进对应主题文档。
> 客户端侧的待答清单在 `game-design-documents/open-questions.md`，两份互不覆盖：一个问题落在哪一侧，看它由谁实现。

## 待答（按主题）

### 强制在线 · 账号与合规（路线已定，仅剩落地）

- **后端 / 账号系统具体选型。** 路线已定为**重账号 + 云端权威**（`game-design-documents/decisions/ADR-0003`）；技术栈、托管形态、账号系统自建还是接第三方均未定。
- **合规落地。** PIPL、实名、防沉迷、渠道审核、账号注销、数据导出——重账号 + 已删游客态 + 国内渠道意味着这些必须正面处理。
- **多设备并发登录的裁决语义。** 同账号在两台设备同时在线时，云端权威如何裁决（后登录挤下线？拒绝？）。→ 客户端侧门面见 `game-design-documents/systems/services/account-service.md`。
- **token 失效时正在进行的轮回如何处理。** 阻塞、本地缓冲上行、还是回退到上一个存档点？与断线降级策略耦合。

### 协议契约（尚未建立 · 优先）

- **客户端 ↔ 后端的契约事实来源尚未成文。** 端点、DTO、错误码、`contentVersion` / `manifest.json` 格式、存档 schema 版本与迁移路径——两侧都读它，必须单点定义。跨越这条边界的客户端服务有四个：`account-service`、`content-service`、`sync-service`、`PlotManager`。
- **契约的表达形式未定。** OpenAPI + JSON Schema 文档级契约，还是（若后端也用 C#）共享 DTO 代码？**这条现在挡着一处具体落地**：Profile 上行负载的**语义**已在客户端侧定案（`pushId` / `baseRevision` / 信封三件套 `contentVersion` · `appVersion` · `revision`），但**报文字段名与序列化形态要等本条才能定稿**。

### 存档同步 / 冲突

- **`revision` 计数器与 CAS 语义的服务端实现（客户端侧已定，2026-08-09）。** 客户端已定案：`revision` = **后端分配的账号级单调递增 `long`**，上行携带 `baseRevision` 作为 CAS 前置条件，后端按三分支应答（相等 → 接受并 `+1` 回 `newRevision`；本地落后 → 拒绝并回当前值；本地领先 → 不可能态，同样拒绝并回当前值）。**后端待定**：计数器的存储与并发控制、跨区域一致性、以及「本地领先」这类异常的服务端观测口径。→ 客户端侧见 `game-design-documents/systems/services/sync-service.md`。
- **`pushId` 幂等窗口（客户端侧语义已定，2026-08-09）。** 客户端每个上行批次携带一个 GUID `pushId`，**随待发队列持久化、跨启动重试保持不变**；后端须对重复到达的 `pushId` **不再 `+1`**，直接回上次结果（`newRevision` + `Deduplicated`）。**后端待定**：记忆多少个 / 保留多久、存储形态。**这一条是承重项**——缺了它，「请求已达、响应丢失」这一移动网络常态会让客户端把已被接受的进度误判为多设备冲突并丢弃。
- **`AccountSeed` 的下发与掷骰复算协议（客户端侧已定，2026-08-09）。** 客户端已定案：`AccountSeed`（`ulong`）**由后端在账号创建时下发**、落 `AccountInfo`、跨设备一致且终身不变；道统残卷的掉落掷骰为 `roll = Hash64(AccountSeed, FinaleWinOrdinal) mod 10000`，**由客户端执行、后端可离线复算**（序号与命中结果随 profile 上行）。**后端待定**：生成与下发时机（随哪条响应返回）、是否对客户端只读、`Hash64` 的跨语言实现须与客户端逐位一致（这是复算成立的前提）、以及**复算不一致时的处置**（拒绝上行 / 以云端复算结果为准改写 / 仅上报风控）。→ 客户端侧见 `game-design-documents/systems/player-profile/account-info.md` 与 `systems/player-profile/player-power/_index.md`。
- **上行负载的版本化与冲突合并细节的其余部分。** 云端权威已定，合并规则与拒绝语义随上面两条落定；仍待后端定的是负载本身的版本化形态与限流交互。
- **自动存档点频率的服务端侧约束。** 每个 AdventureEvent 后 push 的写入频率、是否需服务端限流 / 合并窗口。

### 内容分发（CDN）

- **增量下载的粒度与失败恢复。** 逐文件 hash vs 整包版本、断点续传 / 回滚（避免半套 overlay）。
- **overlay 防篡改。** 客户端 `user://` 可被玩家改写，是否需服务端签名校验及签名方案。

### 剧本下发

- **剧本服务的请求 / 下发 / 缓存 / 离线降级协议。** 客户端只存 key points、内容在剧本服务已定；协议本身未定。→ 客户端侧见 `game-design-documents/systems/services/plot-manager.md`。
