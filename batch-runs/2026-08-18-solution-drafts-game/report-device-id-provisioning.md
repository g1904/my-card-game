# report — device-id-provisioning

> worker 自身写入本文件被 harness 拦截，报告由 orchestrator 代为落盘（内容为 worker 原样交回）。

- **library**: `game-design-documents`（单库，**未动后端库**）
- **file**: `game-design-documents/inbox/solution-draft-device-id-provisioning.md`
- **依据构成**：既有推演 6 · 通行做法 1 · 取向选择 2
- **跨库判定：否。** 后端 `contracts/auth.md` §4a 与 signin 请求表已覆盖后端那一半，且明确把生成与持久化移交客户端；对后端零新增义务 ⇒ 不开对侧草稿。

## 建议要点

- **客户端生成**：`deviceId` 是 `signin` 请求本身的必填字段；后端下发须新开无鉴权端点、还得幂等、值仍要落盘 ⇒ 等于把同一个持久化问题推后一步 + 多一条协议面。
- **取值 = `Guid.NewGuid().ToString("N")`**（32 位小写 hex，`^[0-9a-f]{32}$`）。排除全部平台硬件标识（SSAID / OAID / IMEI / MAC / IDFV / IDFA）：其唯一卖点「卸载后仍存活」已被契约的「重装后变化可接受」宣布为不需要，而 PIPL / 渠道审核成本非零（`ADR-0003` Consequences）；且 IDFV 同厂商 App 全卸即变、SSAID 恢复出厂即变。
- **落点 = `user://cache/device-id.json`，单字段，刻意不带 `accountId`。** 与 `dismissed-recommended-version.json` 逐条同形。**「没有 `accountId` 这一格」是承重设计**：有了它，同设备切账号即重新生成 → 后端按 `(accountId, deviceId)` 判成新设备 → 白挤一次会话；没有它，该错误在结构上写不出来。
- **归属 = `account-service.AuthManager` 私有，不进任何服务 API 面**，**不提供 `TryGetDeviceId()`** —— 把「不得把任何本地判断挂在它上面」从纪律阶梯第 4 级抬到第 1 级。不落 `LocalCacheManager` 的两条理由：① 边界纪律禁止伸手进对方 manager；② 启动顺序对不上（`SignInAsync` 第三步 vs `SyncService.InitializeAsync` 第五步）。
- **惰性生成，先落盘成功再上行**；缺失 / 损坏 / 落盘失败三处**一律 `PushWarning` 不 `PushError`**（它永不参与鉴权）。允许「先上行后落盘」会导致玩家每次启动自己挤自己一次且**永不自愈**。
- **`SignInAsync` 签名逐字不变**（八个方法与四个共享类型零变化）；`deviceId` 由 `AuthManager` 填给内部 `IAccountBackend`。它是传输层元数据，与 `X-App-Version` / `baseRevision` / `pushId` 同类。
- **五种情形语义表**（缓存被清 / 重装换机 / 多设备同账号 / 同设备多账号 / 同设备同账号重登）—— 后两行均「玩家无可见后果」，正是不按 `accountId` 分区的兑现点。
- **存档 schema 零影响、零迁移；后端零改动。**

## 台账行

> `inbox/_index.md` 的「在办清单」**实际表头是 `文件 | status | 说明`**（不是技能正文写的五列）。当前是 `| *（空）* | — | — |` 占位行，须被替换。

```
| `solution-draft-device-id-provisioning.md` | awaiting-review | `deviceId` 的生成算法 / 持久化落点（`user://cache/device-id.json`）/ 四种情形语义。评审 2 项取向后 `/analyze-new-ideas` |
```

对侧库台账行：**无**。

## 仍需用户决定（结构化）

### ① 是否提供一个只读的 `deviceId` 展示口（诊断 / 客服用）
- **问题**：`deviceId` 的用途之一是「观测」。客服排障时玩家是否需要能读出并复制它？决定它是 `AuthManager` 私有字段，还是「设置 → 关于」的一行只读展示。
- **A. 不提供** → 客服须由后端按 `accountId` 反查会话表（该表就以 `(accountId, deviceId)` 为键，反查路径现成）。
- **B. 「设置 → 关于」只读展示 + 一键复制** → 客服链路更短；代价是 `deviceId` 成为公开可读值，「不得把本地校验 / 缓存归属 / 降级判断挂在它上面」由**结构保证（第 1 级）降级为评审纪律（第 4 级）**。
- **推荐 A**：B 的增量收益仅省一次后端查询，却把一条能靠结构保证的纪律降三级。与 `AccountInfo.Identities` 只读投影、`AccountSeed` 不出 API 面同源。

### ② 取值形态：32 位裸 hex vs 标准 36 位带连字符 GUID
- **A. `Guid("N")`** → `^[0-9a-f]{32}$`，与 `AccountInfo.AccountSeed` 的「定长小写 hex · 无前缀」同形；无大小写 / 分隔符归一面。
- **B. `Guid("D")`** → 带连字符 36 字符，与多数后端日志 / 存储 UUID 惯例同形；多一处归一约定。
- **推荐 A**（库内形态一致 > 与外部惯例一致）。**低风险**：改动面仅一处常量 + 一处校验式。

### ③ `user://` 原子写实现的归属（**超出本分片范围，只提请裁决**）
- **问题**：`sync-service.md` 的 manager 表把「`user://` 原子写（临时文件 → rename）」写给 `LocalCacheManager`，但 `flags.json`（content-service）与 `dismissed-recommended-version.json`（UI 层）已各写各的；本方案的 `device-id.json`（account-service）是**第三个**非 sync-service 写入方。同一条纪律四份实现 ⇒ 必然漂移，漂移形态正是「某处漏了 rename、崩溃时留下半个文件」。
- **A（草稿倾向）** 提为不属任何服务的共享静态工具（例 `AtomicJsonFile.TryRead<T>/TryWrite<T>`），四处同用。**不违反**「服务之间不伸手进对方 manager」（无状态工具，非跨服务调用）。代价：新增「共享工具层」概念，架构文档当前无这一层。
- **B** 维持现状，`AuthManager` 自带一小段原子写。代价：第四份副本。
- **倾向 A 但明确不裁决**：牵动 sync-service / content-service / UI 层三处既有文档。本方案在 A / B 任一裁决下都成立 ⇒ 不阻断。建议单列或转成一条新待答项。

## 越界发现

- **refresh token 的客户端持有形态**（同一条待决项的另一半）—— 未处理，但产生一条**必须传给它的硬约束**（已写进草稿「前置依赖」）：**两者不得合进同一个文件** —— 失效口径恰好相反（refresh token 必须按账号失效，`deviceId` 必须切账号不变），同处一份文件会逼出「清一半留一半」的写入路径。
- **`ComplianceManager` 客户端侧覆盖面切分** —— 未触碰。
- **`user://` 原子写实现归属**（见 ③）—— 跨三处的既有漂移。
- **后端契约未对 `deviceId` 声明长度 / 字符集约束**（signin 请求表只写 `string` · 必填）。32 位 hex 必然落在任何合理约束内 ⇒ 不构成跨边界义务；仅记为一条可选的契约收紧建议。
- **`player-profile/_index.md` 的「不进 `PlayerProfile` 的三样」是否补为四样** —— 草稿只提倾向（倾向补上），未改该文档。

## 合规声明
未写 `inbox/_index.md` · 未写 `open-questions*` / `answer-logs/` · 未改任何主题文档 · 未写 `backend-design-documents/` 任何文件（只读引用）· 未调用 `AskUserQuestion`。唯一写入 = 草稿文件。
