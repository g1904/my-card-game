# 标准 —— 存档格式（引用层）

`.claude/rules/state-save-rules.md`（存档 / 读档章节）的配套。**权威：`game-design-documents/systems/services/sync-service.md`**（API 契约、`PushPolicy` / `SavePointReason`、断线降级表、CAS 与信封字段）、`systems/character-profile/_index.md` 与 `systems/player-profile/_index.md`（两层 Profile 的完整字段表）、`decisions/ADR-0003-online-cloud-authority.md`。**字段清单、枚举、schema、数值旋钮一律去那边看，此处不复制。**

## 代码现状

**尚无任何存档代码。** `game-feature-branch/` 无 sync-service、无序列化、无 `user://` 写入。下列全是规划中的纪律。

## 结构（一句话版）

`PlayerProfile ⊃ List<CharacterProfile>`，由 **sync-service** 承载持久化（ProfileSyncManager / LocalCacheManager / MigrationManager），写入面唯一（profile-service）。**强制在线 · 云端权威**：启动全量 Pull、存档点 Push、冲突一律以云端为准，`user://cache/` 只是缓存。→ `systems/services/sync-service.md`、`decisions/ADR-0003-online-cloud-authority.md`。

## 承重纪律（写代码时会改变写法的那几条）

1. **原子写，绝不原地覆盖**（临时文件 → rename）——写入中途崩溃不得损坏上一份存档。→ `systems/services/sync-service.md`
2. **断线绝不回退存档点、绝不阻塞玩家**：变更进本地待发队列重试；唯一硬阻塞是启动 Pull 失败。→ `systems/services/sync-service.md`
3. **存档点 ≠ push**：每个逻辑存档点立即本地原子写，只有网络 push 受防抖约束；应用失焦 / 挂起必须立即 flush。**软阻塞闸门只计事件级存档点，不计战斗内决策点。** → `systems/services/sync-service.md`
4. **决策点是战斗状态机唯一可以停下来的地方**，战斗态落 `CharacterProfile` 上的可空 `ActiveCombat` 块；恢复回到该选择点、不允许反悔。→ `systems/character-profile/_index.md`、`systems/services/combat-service.md`
5. **`PushAsync` 不接收 profile 参数**——profile 的内存权威在 profile-service，递一份进来等于把「谁是权威」重新打开。→ `systems/services/sync-service.md`
6. **增量 push 按 `CharacterProfile` 粒度 diff**，不整体上行 `PlayerProfile`（它随账号年龄单调增长）。→ `systems/services/sync-service.md`
7. **`revision` 由后端分配、只作传输层基线，绝不进存档 schema**；客户端只持 `baseRevision` 落 `user://cache/`。→ `systems/services/sync-service.md`
8. **`pushId` 跨启动重试必须不变（幂等键），`X-Request-Id` 每次重试必须换（日志关联键）**——写反前者丢玩家进度，写反后者让日志无法定位单次尝试。→ `backend-design-documents/contracts/profile-sync.md`
9. **flush 失败不挡玩家**：`Immediate` 只声明「不等防抖窗口」，失败处置与 `Debounced` 完全一致。→ `systems/services/sync-service.md`
10. **只有已知错误码能触发硬阻塞，未知 `code` 永远不得新增第三处硬阻塞。** → `ux/error-and-blocking-ux.md`
11. **账号级字段分规则字段层与统计计数层，依赖单向（规则字段可被 UI 读，统计计数绝不可被规则读）；命名硬约定 `Ordinal` 后缀 ⇒ 规则层、`Total` 前缀 ⇒ 统计层。** → `systems/player-profile/_index.md`
12. **恢复后先 pull 再 flush**；云端领先即丢弃本地缓冲并告知玩家，**不做静默合并、不做字段级三路合并**（那会实质削弱 ADR-0003）。→ `systems/services/sync-service.md`
13. **存档带 `schemaVersion` 并有迁移路径**：更旧逐版迁移、更新 / 未知优雅拒绝，绝不崩溃；`MigrationManager` 骨架此刻就立起来。→ `systems/services/sync-service.md`
14. **读档校验强制**：未知内容 `Id` / 版本不匹配 / 缺失字段一律清晰报错或迁移，不静默为 null。→ `.claude/rules/null-check-rules.md`
15. **跨边界枚举值以字符串序列化、与 C# 枚举名逐字相同** ⇒ 重命名一个跨边界枚举值即是破坏性契约变更，须与后端同批改。→ `backend-design-documents/contracts/envelope.md`
16. **集合字段名与类型名恒为单数**（边界 = 两层 Profile 及其子对象的存档字段名）——字段名机械映射为 JSON path，改名即破坏性契约变更。→ `systems/character-profile/_index.md`

## 存什么（判据，不是字段表）

- **只存 `Id` + 可变状态，不复制展示文本**——文案变更不触发存档迁移。
- **例外：物化后的 `EventOption` 整份落存档**（含战斗类的 `Encounter`），不能只存 `EventId` 事后重算；按 `InstanceId` 定位。→ `systems/adventure-event/common-properties.md`
- **痕迹 `PastEventEntry` 记住判据而非字段表：「重算不出来的存，重算得出来的不存」。** → `systems/adventure-event/common-properties.md`
- **两个内容版本号 `StartContentVersion` / `LastContentVersion`**，二者不等 = 该轮回跨过内容更新（已裁决不冻结 `contentVersion`）。→ `standards/rng-determinism.md`
- **RNG 状态**（`CycleSeed` + 各子流状态）→ `standards/rng-determinism.md`。

## 格式选择

JSON（`System.Text.Json` 或 Godot `JSON`），**序列化配置集中在一处、取 camelCase**——多于一处必然出现半配置态。选定的具体实现落地后记录于此。
