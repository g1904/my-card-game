# 标准 —— 存档格式（引用层）

`.claude/rules/state-save-rules.md`（存档 / 读档章节）的配套。**权威：`game-design-documents/systems/services/sync-service.md`**（API 契约、`PushPolicy` / `SavePointReason`、断线降级表、CAS 与信封字段）、`systems/services/profile-schema-versions.md`（**`schemaVersion` 逐版登记表**）、`systems/character-profile/_index.md` 与 `systems/player-profile/_index.md`（两层 Profile 的完整字段表）、`decisions/ADR-0003-online-cloud-authority.md`。**字段清单、枚举、schema、数值旋钮一律去那边看，此处不复制。**

## 代码现状

**尚无任何存档代码。** `game-feature-branch/` 无 sync-service、无序列化、无 `user://` 写入。下列全是规划中的纪律。

## 结构（一句话版）

`PlayerProfile ⊃ List<CharacterProfile>`，由 **sync-service** 承载持久化（内含哪几个 manager 见权威），写入面唯一（profile-service）。**强制在线 · 云端权威**：启动全量 Pull、存档点 Push、冲突一律以云端为准，`user://cache/` 只是缓存。→ `systems/services/sync-service.md`、`decisions/ADR-0003-online-cloud-authority.md`。

## 承重纪律（写代码时会改变写法的那几条）

1. **原子写，绝不原地覆盖**（临时文件 → rename）——写入中途崩溃不得损坏上一份存档。**`user://` 的原子写只有一处实现：共享静态工具 `AtomicJsonFile`**，`deviceId` / refresh token 一类设备维度小文件与存档缓存同走它，别各写一遍。→ `systems/services/sync-service.md`、`systems/services/account-service.md`
2. **断线绝不回退存档点、绝不阻塞玩家**：变更进本地待发队列重试；唯一硬阻塞是启动 Pull 失败。→ `systems/services/sync-service.md`
3. **存档点 ≠ push**：每个逻辑存档点立即本地原子写，只有网络 push 受防抖约束；应用失焦 / 挂起必须立即 flush。**软阻塞闸门只计事件级存档点，不计战斗内决策点。** → `systems/services/sync-service.md`
4. **决策点是战斗状态机唯一可以停下来的地方**，战斗态落 `CharacterProfile` 上的可空 `ActiveCombat` 块；恢复回到该选择点、不允许反悔。→ `systems/character-profile/_index.md`、`systems/services/combat-service.md`
5. **`PushAsync` 不接收 profile 参数**——profile 的内存权威在 profile-service，递一份进来等于把「谁是权威」重新打开。→ `systems/services/sync-service.md`
6. **增量 push 按 `CharacterProfile` 粒度 diff**，不整体上行 `PlayerProfile`（它随账号年龄单调增长）。→ `systems/services/sync-service.md`
7. **`revision` 由后端分配、只作传输层基线，绝不进存档 schema**；客户端只持 `baseRevision` 落 `user://cache/`。→ `systems/services/sync-service.md`
8. **`pushId` 与 `X-Request-Id` 的重试语义相反、绝不能混用**（一个是跨启动不变的幂等键，一个每次重试都换）——写反即丢玩家进度或丢日志定位能力。→ `backend-design-documents/contracts/profile-sync.md`
9. **flush 失败不挡玩家**：`Immediate` 只声明「不等防抖窗口」，失败处置与 `Debounced` 完全一致。→ `systems/services/sync-service.md`
10. **只有已知错误码能触发硬阻塞，未知 `code` 永远不得新增第三处硬阻塞。** → `ux/error-and-blocking-ux.md`
11. **账号级字段分规则字段层与统计计数层，依赖单向**（规则字段可被 UI 读，统计计数绝不可被规则读）；两族**各有专属词缀、互相禁用对方的词缀**，故成员名空间在构造上不相交、可机械核对——**词缀表逐条见权威，此处不复制**。同一条投影也适用于 `CostKey`（规则层）↔ `StatKey`（统计层）。→ `game-design-documents/systems/player-profile/_index.md`
12. **恢复后先 pull 再 flush**；云端领先即丢弃本地缓冲并告知玩家，**不做静默合并、不做字段级三路合并**（那会实质削弱 ADR-0003）。→ `systems/services/sync-service.md`
13. **存档带 `schemaVersion` 并有迁移路径**：更旧逐版迁移、更新 / 未知优雅拒绝，绝不崩溃；`MigrationManager` 骨架此刻就立起来、且**只持执行面**。**某次结构改动属于哪一版以逐版登记表为准，别处一律回链、不得就地宣布 bump。** → `game-design-documents/systems/services/profile-schema-versions.md`、`systems/services/sync-service.md`
14. **读档校验强制**：未知内容 `Id` / 版本不匹配 / 缺失字段一律清晰报错或迁移，不静默为 null。→ `.claude/rules/null-check-rules.md`
15. **跨边界枚举值以字符串序列化、与 C# 枚举名逐字相同** ⇒ 重命名一个跨边界枚举值即是破坏性契约变更，须与后端同批改。**冻结的只是成员名——枚举的类型名不参与序列化，重命名类型是零迁移、不 bump、不与后端同批改。** → `backend-design-documents/contracts/envelope.md`、`game-design-documents/systems/architecture.md`
16. **向受约束顶层键内的对象「加一个字段」不是零配合的加法**：客户端强类型 record 反序列化再序列化会**静默丢掉**不认识的字段 ⇒ 下一次回声校验当场失败 ⇒ 整批被拒。故加字段也须两侧同批落笔。→ `systems/services/sync-service.md`、`decisions/ADR-0028-upstream-echo-validation-scope.md`
17. **集合字段名与类型名恒为单数**（边界 = 两层 Profile 及其子对象的存档字段名）——字段名机械映射为 JSON path，改名即破坏性契约变更。→ `systems/character-profile/_index.md`
18. **改了两层 Profile 的序列化形状 = 登记表上必须有一行**，护栏是 `ProfileShapeCheck`（序列化形状 ⟷ 该版 golden JSON 快照逐字比对，打包管线不通过不产包 + `#if DEBUG` 启动期兜底）；golden 快照签入 `game-feature-branch/`，是生成物不是规格。分界：**引入一个顶层键要进版本行，已登记顶层键内向对象追加字段不一定**。→ `game-design-documents/systems/services/profile-schema-versions.md`
19. **`SavePointReason` 另有批次层的储物袋通道**：战斗外道具使用 / 随售是**即时提交**（一次 `TryApply` + 一次本地原子写），**不是事件内决策点、不触发 `RefreshAfterEvent`、不计软阻塞闸门**，但**照跑终态判定**（否则会出现「资源触底而角色仍 `ongoing`」）。→ `decisions/ADR-0122-batch-layer-inventory-commit-and-trace.md`
20. **后端主动写入只有购买段一处，靠时机纪律关闭冲突窗口**：购买只能在主菜单（轮回外）发起、进入付费前待发队列须为空，购后强制一次 pull、pull 失败即阻塞在主菜单重试。否则后端 `+1` 会让云端 revision 领先本地基线、CAS 判 `Conflict` ⇒ 丢掉玩家刚打完的战斗。**「购后 pull 失败阻塞开新轮回」这一条只适用于存在客户端兑现动作的付费点（premium bundle），不是全部付费点的通则**——付费角色系列的兑现段整段不存在（发货在后端），未到账的最坏后果只是几个角色暂时选不到。→ `game-design-documents/systems/services/sync-service.md`、`decisions/ADR-0274-character-series-no-redemption-stage.md`
21. **`PlayerEntitlement.CharacterSeries`（`/entitlement/characterSeries`）只由后端在验票事务内尾部追加**：客户端**无写入通道**（不进任何 `ProfileChangeSpec` 列、`ResourceElements` 不加行），且对该 path **不改写、不去重、不归一化**——对侧按有序逐元素做回声比对，任一侧单独破会在**正常账号**上稳定失败。不配兑现水位。**它是本库第一次真实 `schemaVersion` bump（v2）的来源**（条件分支：若在首发前落地则并入 v1）。→ `decisions/ADR-0270-player-entitlement-character-series.md`
22. **回声路径的「老档缺字段」分两个时点、口径不同**：迁移时点写入空列表（迁移是结构搬运，不是造值去回声）；**迁移之后的读档时点缺失即真异常**——`PushError` + 该顶层键本次不进 diff + 触发一次 pull，**不补默认值**。这是通则，不逐付费点各推演一遍。→ `decisions/ADR-0271-echo-path-missing-field-two-timepoints.md`
23. **一个角色恒为存档里的一条 `characterProfile` 记录**，原地跨三篇章推进；「清理」分三层——运行时拆解 / 运行态字段清空两条出口都做，**角色实体状态只在 `defeated` 处置（留墓碑）、`completed` 保留（= 境界存档）**；`pastEvent` / `pastItemUse` **跨篇章只追加，不在篇章边界清空、不随重试回滚**（本篇章切片由篇章起始 `Seq` 锚点求差得出）。→ `decisions/ADR-0165-cycle-exit-three-layer-teardown.md`、`decisions/ADR-0166-trace-append-only-across-chapters.md`

## 存什么（判据，不是字段表）

- **只存 `Id` + 可变状态，不复制展示文本**——文案变更不触发存档迁移。
- **例外：物化后的 `EventOption` 整份落存档**（含战斗类的 `Encounter`），不能只存 `EventId` 事后重算；按 `InstanceId` 定位。→ `systems/adventure-event/common-properties.md`
- **痕迹 `PastEventEntry` 记住判据而非字段表：「重算不出来的存，重算得出来的不存」。** → `systems/adventure-event/common-properties.md`
- **两个内容版本号 `StartContentVersion` / `LastContentVersion`**，二者不等 = 该轮回跨过内容更新（已裁决不冻结 `contentVersion`）。→ `standards/rng-determinism.md`
- **RNG 状态**（`CycleSeed` + 各子流状态）→ `standards/rng-determinism.md`。

## 格式选择

JSON（`System.Text.Json` 或 Godot `JSON`），**序列化配置集中在一处、取 camelCase**——多于一处必然出现半配置态。选定的具体实现落地后记录于此。
