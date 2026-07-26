# Open questions — 后端待答清单

> 后端侧的跨 session 待答清单。只跟踪仍待答的问题；一旦答定就移出并归档进对应主题文档。
> 客户端侧的待答清单在 `game-design-documents/open-questions.md`，两份互不覆盖：一个问题落在哪一侧，看它由谁实现。

## 待答（按主题）

### 强制在线 · 账号与合规（路线已定，仅剩落地）

- **后端 / 账号系统具体选型。** 路线已定为**重账号 + 云端权威**（`game-design-documents/50-decisions/ADR-0003`）；技术栈、托管形态、账号系统自建还是接第三方均未定。
- **合规落地。** PIPL、实名、防沉迷、渠道审核、账号注销、数据导出——重账号 + 已删游客态 + 国内渠道意味着这些必须正面处理。
- **多设备并发登录的裁决语义。** 同账号在两台设备同时在线时，云端权威如何裁决（后登录挤下线？拒绝？）。→ 客户端侧门面见 `game-design-documents/20-systems/services/account-service.md`。
- **token 失效时正在进行的 run 如何处理。** 阻塞、本地缓冲上行、还是回退到上一个存档点？与断线降级策略耦合。

### 协议契约（尚未建立 · 优先）

- **客户端 ↔ 后端的契约事实来源尚未成文。** 端点、DTO、错误码、`contentVersion` / `manifest.json` 格式、存档 schema 版本与迁移路径——两侧都读它，必须单点定义。跨越这条边界的客户端服务有四个：`account-service`、`content-service`、`sync-service`、`PlotManager`。
- **契约的表达形式未定。** OpenAPI + JSON Schema 文档级契约，还是（若后端也用 C#）共享 DTO 代码？

### 存档同步 / 冲突

- **上行负载的版本化与冲突合并细节。** 云端权威已定，但断线缓冲恢复后的合并规则、拒绝语义、幂等键未定。
- **自动存档点频率的服务端侧约束。** 每个 AdventureEvent 后 push 的写入频率、是否需服务端限流 / 合并窗口。

### 内容分发（CDN）

- **增量下载的粒度与失败恢复。** 逐文件 hash vs 整包版本、断点续传 / 回滚（避免半套 overlay）。
- **overlay 防篡改。** 客户端 `user://` 可被玩家改写，是否需服务端签名校验及签名方案。

### 剧本下发

- **剧本服务的请求 / 下发 / 缓存 / 离线降级协议。** 客户端只存 key points、内容在剧本服务已定；协议本身未定。→ 客户端侧见 `game-design-documents/20-systems/services/plot-manager.md`。
