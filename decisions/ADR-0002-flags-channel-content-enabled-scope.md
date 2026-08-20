# ADR-0002 — flags 第三层只覆盖 `ContentEnabled`

- **状态：** Accepted
- **日期：** 2026-08-11
- **来源：** `handoffs/2026-08-11-content-delivery-manifest-signing-and-flags.md` · `answer-logs/log-content-delivery-manifest-and-flags.md`

## 背景

沿 overlay 通道关掉一个出问题的内容条目，真实生效点是玩家的**下一次冷启动**（overlay 合并与校验在启动链第一步）；且 `.tres` 里的布尔对全体玩家同值，灰度与分批放量无处安放。线上秒关因此需要第三条覆盖通道——但热更通道每放宽一分，客户端「合并后强校验」「只改不增」「存档必可解析」三条纪律就松一分。

## 决策

在 `res://` 基线 < `user://overlay/` 之上叠**第三层 flags**，**只能覆盖 `ContentEnabled` 这一个布尔**，**不得携带任何数值 / 文案 / 新 `Id`**——这是硬边界，不可放宽。

- 端点 `GET /v1/content/flags` 归 **API 域**（需鉴权、按账号计算、`no-cache`），不在 `contentRoot` 下。
- 灰度分桶规则**留在服务端、不下发**；端点只给按账号解析完毕的**结果**（`disabledIds` / `enabledIds`）。
- 刷新时机搭车 `X-Flags-Version` 应答头，零轮询。
- 报文字段表、签名体系（与 manifest 同一密钥体系）、`enabledIds` 初期恒空的理由 → `contracts/content-manifest.md`「flags 通道」。

## 理由

这一层之所以能在**轮回进行中**安全热应用，恰恰因为它被限制得足够窄：`ContentEnabled` 唯一的作用点是产出侧 `AllEnabled()` 取池，读取侧 `Get(id)` 本就不过滤。于是——不改数值 ⇒ 不触碰强校验的任何输入；不增删 `Id` ⇒ 落在「热更只改不增」纪律内；⇒ 「存档引用未知内容」的风险仍为零。**一旦放宽携带数值或新 `Id`，这三条同时失效**，而失效的形态是玩家设备上无法复现的解析失败。→ `contracts/content-manifest.md`「为什么这一层安全」。

分桶规则不下发的理由同源：客户端永远不知道分桶存在，`DrawPool<T>` 的构造签名不必变成 `AllEnabled(bucketContext)` 一类。

## 备选方案

- **沿用 overlay 通道做秒关** — 生效点是下一次冷启动，且全体玩家同值，灰度无处安放。
- **flags 允许携带数值覆盖（顺带做数值热修）** — 当场推翻上述三条纪律，且把一条窄通道变成第二套内容分发。
- **把 flags 放在 CDN 域** — 中间层会按静态对象缓存，导致**灰度分桶串号**：这类事故只在放量时显形且极难定位。
- **把分桶规则下发给客户端自行判定** — 规则即成为客户端可见、可篡改、且必须随运营变更发版的东西。

## 后果

- 秒关的实际延迟 = 玩家下一次事件推进上行，**分钟级以内**；不引入长连接或第三方推送。
- 「撤回」与「停止新激活」是两件事：前者只能靠 ADR-0001 的前滚（冷启动级），flags 只能做后者。
- 任何要求扩大 flags 载荷的提案，等于要求推翻本 ADR，须重新论证上述三条纪律如何继续成立。
- flags 数据源、分桶规则的存放与审计留痕属运营形态，落 `operations/`（栈落定后），仍在 `open-questions/04-content-delivery.md` 待答。
- 客户端侧对位（产出侧 / 读取侧不对称、是否本地缓存 flags 以支撑离线开局）归 `game-design-documents/systems/services/content-service.md`，本库不代为决定。
