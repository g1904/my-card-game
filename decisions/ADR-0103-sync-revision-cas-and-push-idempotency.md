# ADR-0103 — `revision` = 后端分配的账号级单调整数，上行走 CAS 三分支 + 幂等键 `pushId`

- **状态：** Accepted
- **日期：** 2026-08-09
- **来源：** handoffs/2026-08-09-sync-revision-cas-and-immediate-flush-nonblocking.md

## 背景

云端权威（`ADR-0003`）要求有一个版本号来判定「谁的写入更后」，但它的形态、分配权与客户端持有位置都未定。同时，移动网络下「请求已达、响应丢失」是常态——单靠一个单调版本号，重试会被误判为多设备冲突，而「以云端为准丢弃本地缓冲」在那种误判下丢掉的正是玩家刚打完的那一场。

## 决策

**`revision` 由后端分配，形态 = 账号级单调递增 `long`。** 客户端只持一个**传输层**基线值 `baseRevision`，落 `user://cache/sync-envelope.json`，**不进 Profile、不 bump 存档 schema、无迁移**；切账号即丢弃信封、`baseRevision` 归 0、清空待发队列。

**上行走乐观并发（CAS），三分支闭合**：相等则接受并回 `newRevision`；本地落后判 Conflict、以云端为准；`baseRevision > cloudRevision` 是不可能态，处置同 Conflict 但**额外上报一次**、不试图自愈。

**每个上行批次携带客户端生成的幂等键 `pushId`（GUID），重试时保持不变**，并随待发队列条目持久化——跨启动重试必须用同一个 `pushId`。后端据它去重，重复到达时不再 +1、直接回上次结果。

三分支的完整表、失败语义与信封字段 → `systems/services/sync-service.md`。报文字段名与后端记忆窗口不在本库定稿（总则 7）→ `backend-design-documents/contracts/profile-sync.md`。

## 理由

分配权在后端是「云端权威」的直接推论——让客户端分配版本号等于让非权威一侧决定谁更新。

`baseRevision` 排除在 Profile 之外，避免两个具体代价：每次 push 都改动被 push 的东西（自指），以及它会被卷进存档 schema 版本与迁移。本方案因此零迁移。

不可能态单列而不并进 Conflict：处置相同（云端权威下答案唯一），但**它是一个应当被观测到的异常**——静默按 Conflict 处理会让「客户端 `user://` 被改写」这类事件永远看不见。与 content-service 的「验签失败 → 拒绝 + 上报一次」同构。

`pushId` 是本条最承重的一环：`Immediate` flush 点里有一个正是应用失焦 / 挂起，那恰是响应最容易收不到的时刻；没有幂等键，「绝不回退存档点」这条总原则在该时刻失效。

## 备选方案

- **服务端时间戳** — 否决：要比较的是「谁的写入更后」，时间戳需要后端时钟单调且无回拨，同毫秒并发无法定序，相对整数计数器零收益。
- **ETag 字符串** — 否决：ETag 只支持判等，而语义要的是**有序比较**；判等区分不出「落后」与「不可能态」。
- **客户端分配 `revision`** — 否决：违反云端权威。
- **per-`CharacterProfile` 各一个版本号** — 否决：同步单位是 PlayerProfile 聚合，角色粒度 diff 只是传输优化；给每个角色各一个版本号会诱导出已被否决的字段级合并。
- **把 `revision` 落进 `PlayerProfile` 字段** — 否决：自指 + 卷进存档迁移。
- **只靠 `revision`、不引入幂等键** — 否决：会在「请求已达、响应丢失」这一移动网络常态下丢玩家进度。

## 后果

- `systems/services/sync-service.md` 是权威；`systems/architecture.md` 总则 7 的 `IProfileBackend` 两个签名随之带上 `revision` 返回位。
- `systems/services/account-service.md` 承接「切账号即失效」这一必需检查点。
- `BaseRevision` 在设置屏暴露为只读诊断行「同步版本 #N」（`0` 显示「尚未同步」），**不是设置项** → `ux/screen-flow.md`。
- 跨库承接：幂等键的后端记忆窗口、报文字段名与序列化形态归 `backend-design-documents/contracts/profile-sync.md` 与 `backend-design-documents/contracts/envelope.md`。
