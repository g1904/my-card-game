# ADR-0130 — `ContentEnabled` 增第三层覆盖来源 flags：overlay 不再是唯一热更层

- **状态：** Accepted
- **日期：** 2026-08-11
- **来源：** handoffs/2026-08-11b-contract-boundary-and-flags-client-side.md

## 背景

内容载体原本只有两层——随包基线 `res://` 与热更 `user://overlay/`（`decisions/ADR-0007-local-content-layer-and-overlay.md`），且「overlay 是唯一热更层」被当作通则。但 overlay 是**数值型热更**：它要走合并后的全量强校验、要重新合并、在轮回进行中应用不安全。而线上事故的止血需求是**分钟级关掉一个条目**，overlay 这条通道兑现不了。

## 决策

**`ContentEnabled` 的覆盖来源改为三层：`res://` 基线 < `user://overlay/` < flags。「overlay 是唯一热更层」不再成立。**

flags 这一层被刻意限制得极窄：**只覆盖 `ContentEnabled` 一个布尔，不改任何数值、不新增也不删除任何 `Id`。**

- **作用点唯一：`AllEnabled()` 取池。** 读取侧 `Get(id)` 照旧不过滤；合并后强校验照旧走 `AllIncludingDisabled()`，**flags 不参与校验**。
- **首次拉取排在登录之后**：该端点需鉴权，而 content-service 是启动链第一步。flags 的首次拉取另立一个方法，由 Bootstrap 在登录之后、sync 初始化之前调用。
- **刷新时机 = 搭车应答头，零轮询**；拉到即生效于下一次抽取，不需重启、不重新合并 overlay、不触碰注册表校验 ⇒ **轮回进行中安全**。
- **本地缓存 `user://cache/flags.json`**，原子写、跨启动保留、**切账号即失效**；失败一律 `PushWarning` + 用缓存（无缓存则回落 overlay 的布尔）+ **绝不阻塞**。
- **走同一密钥体系**（ES256 detached + `keyId`）：验签失败 / `keyId` 未知 → 拒绝这批 + `PushError` + 保留上一批。
- **分桶规则哪也不放在客户端**：端点按账号计算后只给结果。

单调拉取语义见 `decisions/ADR-0079-flags-monotonic-fetch.md`，落盘纪律与非 `.tres` 处置见 `systems/services/content-service.md`。

## 理由

- **这一层安全，恰恰因为它被限制得足够窄**（三条逐条对上既有纪律）：不改任何数值 ⇒ 不触碰合并后强校验的任何输入，校验模型原样成立；不新增 / 不删除 `Id` ⇒ 完全落在「热更只改不增」纪律内；不影响读取侧 ⇒「存档引用未知内容」的风险依然为零。
- **它兑现的是 overlay 兑现不了的那件事**：秒关的实际延迟 = 该玩家的下一次上行，分钟级以内，且不引入长连接 / 第三方推送。
- **本地缓存的收益不在离线开局**：启动 pull 是硬阻塞、强制在线下无权威档即不可玩 ⇒ 根本不存在「断网启动并进入轮回」这条路径。真实收益只有一处——**登录成功但 flags 拉取失败**时的降级值：用上一次已知 flags 优于回落到 overlay 里的布尔（后者会让被秒关的条目复活）。
- **切账号即失效**：分桶是按账号解析后的结果，跨账号复用等于灰度串号。与 `sync-envelope.json` 的切账号纪律同构。
- **拉取失败不另开重试机制**：下一次搭车观察到版本差异时自然重试。

## 备选方案

- **用 overlay 承担秒关** — 否决：数值型热更要走全量重校验与重新合并，轮回进行中不安全，且延迟按发包节奏计。
- **让 flags 也能改数值 / 增删 `Id`** — 否决：三条安全性依据全部作废（触碰强校验输入、突破「只改不增」、可能让存档引用未知内容）。
- **flags 参与合并后强校验** — 否决：校验须看到全量条目，故走 `AllIncludingDisabled()`。
- **轮询 flags 端点** — 否决：搭车应答头即可，零轮询、零长连接。
- **首次拉取放在 content-service 初始化内（登录之前）** — 否决：该端点需鉴权，两者对不上。

## 后果

- **启动链插入一步**：flags 首次拉取位于登录之后、sync 初始化之前——抽取池必须在轮回开始前正确，而它失败不阻塞、排在硬阻塞的 pull 之前不增加任何阻塞风险。
- `AllEnabled()` 的取池语义改为三层合并；`AllIncludingDisabled()` 的全量口径不变。
- 不改动任何客户端 record 与存档 schema：flags 是运行时态、不入存档。
- **仍未答**：flags 拉取的频次护栏（服务端版本短时间连续抖动时是否需要最小拉取间隔）。
- 因此必须这么写的文档：`systems/services/content-service.md`（存储形态三层 + flags 通道整节 + 本地缓存）· `systems/architecture.md`（启动链）。对侧契约见 `backend-design-documents/contracts/content-manifest.md`。
