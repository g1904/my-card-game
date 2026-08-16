# Answer log profile-sync-contract

- 日期：2026-08-14
- 来源：`inbox/archive/solution-draft-profile-sync-contract.md`（`status: decided`，用户裁决五项）→ `handoffs/2026-08-14-profile-sync-contract.md`
- 移出条数：**6**（`01-contracts.md` 一条 + `03-sync-conflict.md` 全部五条 ⇒ 该分片整片删除）

---

**`profile-sync.md` 尚未成文——负载信封字段表、三分支应答报文、「后端可见字段子集」的逐字段清单（原 `01-contracts.md`）** → **成文**：两端点封定（`GET pull` 无 body、账号取自 token / `POST push`）；负载信封四字段（`pushId` / `baseRevision` / `schemaVersion` / `reason`，其中 `reason` 只做日志与聚合维度、不驱动判定）+ 两段 diff；四种应答情形（CAS 三分支 + 幂等命中）**不新增任何错误码**；可见字段子集 = **八条 JSON path 的白名单**，补集即不透明段，并立「**透明字段的 JSON path 是契约的一部分**，移动 / 重命名 = 破坏性变更须 bump `schemaVersion`」这条承重纪律。`statistics` 明确不透明（否则等于给「拿统计驱动发放」开门）。（→ `contracts/profile-sync.md` §1–§5）

**`revision` 计数器与 CAS 语义的服务端实现（原 `03`）** → **停在语义层定案**：同一 `accountId` 上的「读 → 比对 → 写并 `+1`」必须是一次**线性化的读改写**，实现不限（条件 UPDATE / 事务 / 单分区串行）；**绝不允许「先写 profile 再改 revision」**的两步非原子形态；跨区域取**单写入区 + 只读副本**（账号级严格单调计数器在多主下无法维持，而云端权威的全部力量建立在它上面）；「本地领先」回 `sync.revision_ahead` 并作为服务端指标单列。**具体存储与并发控制归 `06`**。（→ `contracts/profile-sync.md` §8；实现项 → `open-questions/06-platform-stack.md`）

**`pushId` 幂等窗口——记忆多少个 / 保留多久 / 存储形态（原 `03`）** → `(accountId, pushId)` 唯一键 → `{ newRevision, acceptedAtUtc }`，**每账号最近 200 条 / 30 天**（对齐 refresh token TTL，使两处窗口不互相穿帮），**与 revision 写入同一次事务**；命中回上次结果、不再 `+1`、不重写 profile；**不做 body 深比对**；窗口过期是**安全降级**（退化为 `sync.conflict`）而非错误接受。（→ `contracts/profile-sync.md` §9；实现与初值校准 → `06`）

**`AccountSeed` 的下发与掷骰复算协议（原 `03`）** → 四段全部定案：**下发** = 后端在账号创建时写进 profile 骨架（`{"accountInfo":{"accountSeed":"…"}}`，初始 `revision = 1`），客户端在启动 pull 中拿到，**以 16 位小写 hex 字符串**（`ulong` 超 2⁵³，JSON number 会静默丢低位）；**随机源** = 契约定义的纯函数 **SplitMix64**，不走 Godot `RandomNumberGenerator`（跨语言逐位一致是复算前提，不能押在引擎实现细节上），`stream` 取值冻结、测试向量表为验收物、轮回级 RNG 不受影响；**复算边界** = **可复算 `roll`、不可复算阈值**（生效概率取决于随 overlay 热更的分档表 ⇒ 否决「后端持有平衡表全量验算」），客户端上报 `lastRoll` / `lastEffectiveChance`，后端做三条校验（逐位比对 · **单向蕴含**「未命中却新增 = 异常」· 结构不变式）；**不一致的处置** = **仅记账 + 上报风控，不拒绝、不改写**。（→ `contracts/profile-sync.md` §2 §6 §7 §7a）

**上行负载的版本化与冲突合并细节的其余部分（原 `03`）** → 被契约覆盖：负载版本 = `schemaVersion`，越界回 `sync.payload_schema_unsupported` 且**判定发生在 CAS 之前**（不消耗 revision）；合并语义 = **顶层键粒度的浅合并**（`playerDiff` 出现的顶层键整键替换、`characterDiffs[i].diff` 整体替换该角色、空对象 = 无变化、**不提供删除语义**，因客户端 profile 只增不删）；与限流的交互见下一条。（→ `contracts/profile-sync.md` §3 §3a §4）

**自动存档点频率的服务端侧约束（原 `03`）** → **不设常规节流，只设滥用阈值**：客户端稳态约每分钟一次上行（5 秒防抖 + 事件级存档点粒度），常规节流只会打到正常玩家且重试会把同一批数据再送一次；阈值初值 60 次/分钟/账号，触发回 `rate.limited`（`Retryable`）+ `Retry-After`，**绝不映 `Conflict`**。**不做服务端合并窗口**——幂等与 CAS 已使重放安全，合并窗口只会引入第二套顺序语义。实现与实际阈值归 `06`。（→ `contracts/profile-sync.md` §10）

---

**同时被答结的 handoff 级 open question 三条**（原在 `handoffs/2026-08-12-grant-source-code-contract.md`，不在待答清单分片中，故不计入移出条数）：枚举序列化冲突 → **收口①**（契约字符串名 + 存档整数 code + 边界一次映射，连带「名与 code 双双冻结」）· `x` 复算的触发时机与不一致处置 → `finaleWinOrdinal` 递增的那次 push / 仅记账 · 轮回级 `sourceCode` 是否进透明档 → **不进**。

**跨边界说明**：本次裁决同时改动客户端语义（两个新字段 + 两条写入约定 · hex 解析 · 路径稳定性纪律 · `sourceCode` 边界映射 · **`AccountRng` 换随机源含返回类型改动** · diff 序列化形态）。本 log 只记后端侧结论；客户端侧需另写一份 handoff 并在其 answer log 中记录相应移出。
