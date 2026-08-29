# push 负载 `reason` 取值清单增第六值 `"InventoryChanged"`，并明写未知取值的识别面

- id: 2026-08-28-save-point-reason-inventory-changed
- date: 2026-08-28
- topic: contracts/profile-sync
- status: distilled
- distilled-to: contracts/profile-sync.md

> **一行摘要：** 上行负载信封的 `reason` 取值清单由五值扩为六值（追加 `"InventoryChanged"`），并把「未知取值 → 记录原值、不改写、不拒收」按同文件 `sourceCode` 的既有形状明写下来。字段类型、必填性、判定路径与契约版本**均不变**。

## Intent（distilled）

### 1. 取值清单扩为六值

`reason` 的定义是「`SavePointReason` 枚举名逐字」，清单随该枚举增员而扩：追加 `"InventoryChanged"`。**纯表格增量**——不改字段类型（仍是 `string`）、不改必填性（仍必填）、不改任何判定路径，因为 `reason` 本就不驱动判定（判定只看 `baseRevision` 与 `pushId`）。

该成员在客户端的语义、触发时机与存档语义——它由哪一类操作发出、为什么不复用既有 reason、push policy 取什么——的权威在 `game-design-documents/systems/services/sync-service.md`，**本库不复述**。成员名的最终拼写以客户端侧冻结时的成员名为准（第一批存档写下前冻结）。

### 2. 未知 `reason` 的识别面 = 宽容接收 + 记录，不拒绝报文

收到清单外的 `reason` 取值时，**照常处理该次 push，把未识别值原样记入日志与聚合维度，不返回错误、不拒绝报文**。它与同文件 `sourceCode` 那条「未知取值：记录原值、不改写、不拒收」是同一个形状的第二个实例，故照该形状书写而非另立一套措辞。

- 依据是 `reason` 自身的定位：**它不驱动任何判定**。因一个零判定权的日志维度取值不认识就拒收一次合法的进度上行，等于让该字段获得阻断玩家进度的能力，与它的定位直接矛盾。
- 它同时给出两侧**发版顺序的自由度**：客户端先上线带新 reason 的版本、后端稍后补清单，期间不产生故障；反向本就无害。这在两侧独立发版的强制在线架构下是必需的。
- **代价明写：** 清单因此不是一道校验闸，拼错的成员名不会被机械发现，只会在聚合维度里多出一个孤儿取值。这是可接受的——`reason` 的消费方是运维观测，孤儿取值在看板上一眼可见。

### 3. 不 bump 契约版本

取值清单增量与「未知值宽容」两条合起来即向后兼容。存储侧无 schema 变更（若 `reason` 落聚合表，字符串列天然容纳新取值）。

## Open questions

无。两条均可由既有决策直接推出（`reason` 的零判定定位 + 两侧独立发版的现实），不含取向选择。

## Notes / triage

- 客户端那一半（新增的 `SavePointReason` 成员本体、触发它的两类批次层储物袋操作、push policy 与存档语义）落 `game-design-documents/handoffs/2026-08-28-out-of-combat-item-use-savepoint-and-trace.md`，两侧互相回链。
- 未来同类增员的通道就此定形：宽容语义写下之后，后续再加 reason 成员不再需要成对发版，后端补清单变成纯观测侧的跟进动作。
