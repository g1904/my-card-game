# Answer log sync-revision-and-soft-block

- 日期：2026-08-09
- 来源：`inbox/archive/solution-draft-sync-revision-and-soft-block.md` → `handoffs/2026-08-09-sync-revision-cas-and-immediate-flush-nonblocking.md`
- 移出条数：**2**

## 逐条

**`revision` 的产生方与语义（由谁分配、什么形态、客户端如何持有基线值）** → **后端分配的账号级单调递增 `long`**（分配权必须在权威一侧，否则 `ADR-0003` 被架空；时间戳与 ETag 均否决——前者需时钟单调且同刻并发无法定序，后者只能判等、区分不出「落后」与「不可能态」）；**账号级一个，不做 per-`CharacterProfile` 版本号**（逐角色版本号会诱导出已被否决的字段级合并）。客户端只持基线值 `baseRevision`，落 **`user://cache/sync-envelope.json`** 的**传输层元数据**，**不进 `PlayerProfile`、不 bump 存档 schema、无迁移**；切账号即失效（必需缺失 → `PushError` + 丢弃信封与待发队列）。上行走 **CAS 三分支**（相等 → 接受 `+1`；本地落后 → Conflict，以云端为准；本地领先 → 不可能态，同处置 + `GD.PushError` 上报一次，不自愈），并携带幂等键 **`pushId`**（GUID，随待发队列持久化、跨启动重试不变；后端重复到达不再 `+1`，回上次结果 + `Deduplicated`）——**没有它，「请求已达、响应丢失」这一移动网络常态会让客户端把已被接受的进度误判为多设备冲突并丢弃，直接违反「绝不回退存档点」**。连带修订总则 7 的 `IProfileBackend` 两个返回类型（`ProfileSnapshot` / `PushAck`），服务门面新增只读诊断属性 `long BaseRevision { get; }`。（归档去向：`systems/services/sync-service.md`「`revision` 语义与幂等键」+「API 面」、`systems/architecture.md` 总则 7、`systems/services/account-service.md`「意图」）

**软阻塞与「进入战斗前强制 flush」的交互（谁先谁后）** → **两者不是先后关系，而是不同层：flush 是一次「尝试」，闸门是一个「状态」。** `Immediate` 只声明「不等防抖窗口」，**不声明「发不出去就停下」**——**进入战斗前的 flush 失败不挡玩家**。四条既有定案各自独立指向同一答案：断线降级表的「不阻塞玩家」从不按 `PushPolicy` 分叉 · 软阻塞措辞「不打断进行中的事件」而选中 Combat 时事件已开始 · `SelectCost` 不回滚使「付了成本却拿不到事件」的代价不可接受 · D0 不参与闸门判定已是定案而 D0 就是这个 flush 点。连带明写三条推论（战斗结束后闸门自然对齐 · 滞留计时不因战斗暂停且这是正确行为 · 该 flush 点的意图是「趁长区间前尽力送出已有的事件级变更」）。UX 两项取向同时签核：**进战斗前 flush 失败不加任何额外提示**（由常驻「离线 · 待同步 N」承担，前提是该指示在战斗屏内可见）· **`BaseRevision` 在设置屏显示为只读「同步版本 #N」**（`0` → 「尚未同步」；诊断展示而非玩法数据）。（归档去向：`systems/services/sync-service.md`「`Immediate` flush 的失败语义」、`systems/services/combat-service.md` D0、`systems/services/life-cycle-service.md` 自动存档点、`ux/combat-ux.md`、`ux/screen-flow.md`）

## 剩余 / 新增

- **新增待答（后端侧）**：`pushId` 的后端记忆窗口（记多少个 / 保留多久）与报文字段名 —— 已登记进 `05-service-contracts.md` 与 `backend-design-documents/open-questions.md`。
- **不受影响**：`sync-service.md` 的「迁移失败的玩家侧表现」相邻但不耦合，**保留**在待答清单；`05-service-contracts.md` 的其余 8 条不受影响。
