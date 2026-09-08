# Scope — 后端的范围与边界

> 后端要做什么、不做什么。本文件只陈述范围与边界本身，**不复述任何机制**——协议形态在 `contracts/`（六份已成文），技术栈与托管形态已落定（`ADR-0021` · `handoffs/2026-09-03-backend-stack-and-hosting.md`），服务内部与运维形态在 `systems/` 与 `operations/`。
> Source: `game-design-documents/decisions/ADR-0003-online-cloud-authority.md`、`game-design-documents/vision/scope.md`。

## 后端存在的理由

游戏是**强制在线 · 云端权威**的：进度实时同步云端，本地 `user://` 仅作缓存 / 离线临时态，本地↔云端冲突以云端为准。这条决定直接产生了后端——没有它，这个游戏是纯单机的。

## 边界：唯一真实的进程边界

客户端的七个「服务」全部是同一个 Godot 进程内的模块单例，彼此为直接 C# 方法调用。**唯一真实的进程边界是客户端 ↔ 后端。** 跨越这条边界的客户端成分有**三个**，且**全部是服务本身**——没有任何 manager 跨边界：

| 客户端成分 | 后端承担 |
|---|---|
| `account-service` | 账号鉴权、会话、多设备裁决（`contracts/auth.md`）；**合规六端点**——实名 / 防沉迷拦截、注销、数据导出（`contracts/compliance.md`） |
| `sync-service` | 权威存档、`revision` CAS 与 `pushId` 幂等、冲突裁决（`contracts/profile-sync.md`）；**付费验票三端点**——验票、收据幂等读、微信下单（`contracts/purchase.md`，客户端侧走 `IPurchaseBackend`） |
| `content-service` | 内容 overlay 分发（CDN）、`manifest.json`、放量 / 秒关开关（`contracts/content-manifest.md`） |

客户端侧的门面设计见 `game-design-documents/systems/services/`；**边界另一侧全部归本库**。

**剧本内容不跨边界。** 它是客户端本地内容层的一员，热更走 content-service 已有的 overlay 通道，运行时零网络请求。
Source: `handoffs/2026-08-11-plot-service-retired.md`。

## In scope

- 账号与鉴权（登录渠道、会话、多设备裁决）。
- **合规域**：实名核验、防沉迷时段判定、账号注销（含冷静期与执行）、数据导出、昵称审核与风控。它是一条**独立的纵向切片**，不是账号能力的附属——契约在 `contracts/compliance.md`，运维面在 `operations/compliance-ops.md` 与 `moderation.md`。
  **四项能力（实名核验 · 防沉迷时段 · 账号注销 · 数据导出）全部在首版范围内**，不分档：可后置的是各项的增强项，不是能力本身。**第三方昵称审核适配器留位不启用**，触发条件见 `operations/moderation.md`。两份发布前置清单（「首个真实账号建号之前」与「首次面向公众发行之前」）见 `operations/deployment.md`。
- **付费验票域**：向平台服务器验票、权威写入兑现序号、收据幂等与对账。渠道取值域封闭为三条（Google Play Billing · App Store · 微信支付），范围权威在 `game-design-documents/vision/scope.md`。契约在 `contracts/purchase.md`，运维面在 `operations/purchase-ops.md`。
- 权威 profile 存储与同步裁决。
- 内容分发与线上开关（**含剧本文本**——它是普通内容文件，与卡牌 / 事件同走 manifest 通道）。
- 客户端 ↔ 后端协议契约（**本库的核心产出**，落点 `contracts/`）。

Source: `handoffs/2026-09-07-compliance-launch-tiering.md`（合规四项的首版落位）。

## Out of scope

- **玩法规则的服务端复现。** 战斗结算、抽卡、事件生成全在客户端执行；后端存结果、不重跑玩法。唯一例外是**可离线复算**的道统残卷掷骰（客户端执行、后端可复算校验）。
- **实时对战 / 房间 / 匹配。** 游戏是单人的，没有玩家间实时交互。
- **客户端资产打包与分发渠道**（应用商店侧）。
- **剧本下发与剧本运行时生成。** 剧本是预写式内容库、随内容层本地化；后端不解析 key point、不按进度返回文本、不做运行时生成（客户端侧已定，2026-08-11，见 `handoffs/2026-08-11-plot-service-retired.md`）。

## 硬约束

- **移动网络是常态**：弱网、请求已达而响应丢失、长时间后台挂起——协议必须对重试与幂等成立（`pushId` 因此是承重项）。
- **写入频率由玩法决定**：每个 AdventureEvent 后一次上行，节奏由客户端的存档点定义，后端只能约束（限流 / 合并窗口），不能改变其语义。
- **内容热更即时生效**：overlay 更新在轮回进行中即生效，不冻结 `contentVersion`；因此不承诺跨内容版本的可复现性。

## Open questions

见 `open-questions.md`。**范围面本身无待答项**：六份契约已成文（`01-contracts.md` 待答清单已清零）、技术栈与托管已落定。合规能力的首版落位已在上方 In scope 写实，过闸时点见 `operations/deployment.md` 的两份发布前置清单。余下与本文件相关的一条是**范围的时点而非范围的内容**：待实测取值（`06-platform-stack.md`）。
