# 标准 —— 存档格式（引用层）

`.claude/rules/state-save-rules.md`（存档 / 读档章节）的配套。**权威：`game-design-documents/systems/services/sync-service.md`**（API 契约、`PushPolicy` / `SavePointReason`、断线降级完整表）与 `handoffs/2026-07-27-content-gating-offline-resilience-and-rng-persistence.md`（§2 / §4 / §6）——**字段清单、枚举、数值旋钮去那边看**。

由 **sync-service** 拥有：ProfileSyncManager（上下行与冲突）、LocalCacheManager（`user://` 原子写）、MigrationManager（schema 迁移）。

## 结构与权威

- **`PlayerProfile ⊃ List<CharacterProfile>`** ——账号级主档持有轮回级角色档案。因此**存档提交点唯一**，由单一 profile-service 作为两层的写入面（「扣账号级 PlayerItem 次数 + 扣轮回级灵玉」天然落在同一事务内）。
- **强制在线 · 云端权威**（ADR-0003）：启动全量 Pull，存档点 Push，冲突**一律以云端为准**。`user://cache/` 仅作本地缓存 / 断线临时态，**不是权威**。

## 承重纪律

1. **原子写，绝不原地覆盖。** 序列化到临时文件 → flush/close → **rename 覆盖**真实文件。写入中途崩溃保留上一份完好存档。同一条纪律也用于 overlay 提交点（→ `data/_index.md`）。
2. **绝不回退存档点。** 断线时变更进本地待发队列重试，**不阻塞玩家**；「云端权威」解决的是**冲突**，不是**丢进度**。（唯一硬阻塞是启动 Pull 失败——强制在线下无权威档即不可玩，且**不提供本地缓存开局**。）
3. **存档点 ≠ push。** 每个逻辑存档点（轮回开始 / 每个 AdventureEvent 结算后 / 篇章边界 / 轮回结束 / **战斗内每个决策点**）**立即原子写本地**；受频率约束的只是网络 push（防抖合并）。**应用失焦 / 挂起必须立即 flush** ——那是移动端被系统杀死前的最后机会。
   - **sync 缓冲闸门只计事件级存档点，不计决策点存档**（08-06）。决策点约 31 点/场，按旧口径一场战斗第三个决策点就会弹软阻塞。**闸门计 push 单位、不计本地写入单位。**
4. **决策点 = 战斗状态机唯一可以停下来的地方**（公理）。战斗态挂在 `CharacterProfile` 上的**可空 `ActiveCombat` 块**：战场单表 + `kind`、栈**数组序即栈序**、`pending` 全局至多一个、道具只落本场配额、`Power` 运行态 = 战场条目的 `counters`。**恢复回到该选择点、不允许反悔。** 一场战斗内的卡牌集合是**闭集**（不存在凭空生成的牌）——这条**闭集不变式就是读档断言**，存档只需各区 `Id` 序列 + `CardInstance` 运行态。
5. **`PushAsync` 不接收 profile 参数。** profile 的内存权威在 profile-service；让调用方递一份进来等于把「谁是权威」再打开一次。
6. **增量 push 按 `CharacterProfile` 粒度 diff。** `PlayerProfile` 整聚合含全部历史角色、随账号年龄单调增长，整体上行不可持续。
7. **`revision` 是传输层的东西，绝不进存档。** `revision` 由**后端**分配（账号级单调递增 `long`，客户端分配即等于让非权威一侧决定「谁更新」）；客户端只持一个基线值 `baseRevision`，落 `user://cache/sync-envelope.json`（与待发队列同处、同样原子写、跨启动保留），**不落 `PlayerProfile` / `CharacterProfile`、不进存档 schema、不参与迁移**。上行走 CAS 三分支，且**每批带一个客户端生成的幂等键 `pushId`，重试时保持不变并随待发队列持久化**——跨启动重试换了 `pushId` 就会在「请求已达、响应丢失」这一移动网络常态下丢玩家进度。服务门面**不外泄 `Revision`**（只新增只读诊断属性 `BaseRevision`）：**暴露给人看可以，暴露给代码判断不行**。→ `systems/services/sync-service.md`。
8. **flush 是一次「尝试」，软阻塞闸门是一个「状态」。** `Immediate` 只声明「不等 5 秒防抖窗口」，**不声明「发不出去就停下」**；`Debounced` 与 `Immediate` 在**失败处置上完全一致**（进待发队列 + 指数退避 + 不阻塞玩家）。因此**进入战斗前的 flush 失败绝不挡玩家**，也不加额外提示（沿用常驻「离线 · 待同步 N」指示）。阻塞与否只由闸门在既定时机判定——下一次 AdventureEvent 选择前。唯一的两处硬阻塞（启动 pull 失败、被后端挤下线）与 push 通道无关，且**只由已知错误码触发——一个未知 `code` 永远不得新增第三处硬阻塞**。
9. **`Upgrade` 类错误只在登录 / 启动 pull 构成硬阻塞，其余时机一律降级为非阻塞**（08-11b）：本地缓冲保留不丢弃 · 非模态提示 · **暂停自动退避**（重试必然失败，退避只是空耗电量）· **解除条件只有「重新登录成功」**，不因时间流逝或应用重启自动恢复。软阻塞闸门口径**完全不变**，变的只有模态文案与选项（无「重试」）。UI 靠 sync-service 的只读属性 `bool UpgradeRequired` 单点查询区分变体，**不新增 `SyncState` 值**——与 `PendingCount`、空负载 `CapabilitiesChanged` 同构。
10. **账号级字段分两层，判据是「它有没有被**规则**读」。** 规则字段层（被判定 / 闸门 / 幂等键读取，如 `PlayerPowerFragment.*`、`CharacterProfile.chapterRetry`）严格上行、后端可复算、读档越界钳制 + 告警；统计计数层（只被 UI 读来展示，如 `TotalCyclesCompleted`）宽松口径、告警即可。**依赖单向：规则字段可被 UI 读，统计计数绝不可被规则读。** 被 UI 看见不会把规则字段变成统计计数。两层都经同一次 `TryApply` 写入，不另开写入通道。**合并判据：口径相近不构成合并理由——可以合并当且仅当「语义 + 同步口径 + 篡改后果」三者全同，故跨层的两个字段永远不满足。** 也**不做两层间的交叉一致性校验**（写了就等于承认它们该相等，把已排除的合并从后门放回来）。**命名硬约定：后缀 `Ordinal` ⇒ 规则字段层（是「第几次」，有人拿它当键）；前缀 `Total` ⇒ 统计计数层（是「一共多少」）；统计计数层禁用 `Ordinal` 后缀。** → `systems/player-profile/_index.md`。
11. **恢复后先 pull 再 flush。** 若云端 `revision` 已领先本地基线（多设备），**以云端为准丢弃本地缓冲**并明确告知玩家。**不做静默合并、不引入字段级三路合并**——那会实质削弱 ADR-0003。
12. **存档带 `version` 并有迁移路径。** 相等 → 直接加载；更旧 → 逐版迁移；更新 / 未知 → **优雅拒绝**，绝不崩溃。当前无线上存档、迁移为空迁移，但 `MigrationManager` 的骨架**就在此刻**立起来（最便宜的时机）。
13. **读档校验是强制的**（→ `.claude/rules/null-check-rules.md`）：未知内容 `Id`、版本不匹配、缺失字段必须以清晰错误 / 迁移处理，绝不静默为 null。

## 存什么

- **只存 `Id` + 可变状态，不复制展示文本** ——文案变更不触发存档迁移。
- **例外：物化后的 `EventOption` 整份落存档，不能只存 `EventId` 事后重算。** 物化用了 seeded RNG、当时的角色状态与可热更的模板，重算不保证同结果——会导致「呈现时看到的事件」与「结算时执行的事件」不一致。当前批 eventOptions 与 `pastEvent` 痕迹都存物化快照，**按 `InstanceId` 定位**（`EventId` 不可替代——同一模板可在一次轮回被物化多次）。
- **痕迹条目 `PastEventEntry` 已定形（08-09c），但记住判据而不是字段表：「重算不出来的存，重算得出来的不存」**——字段表会随「`EventOption` 完整物化字段清单」继续增长，判据不会。由它落定：**所有文本类字段一律留在模板侧**（显示名 / 描述 / 图标 / **风味文案**都不进快照，快照里一个字符串正文都不存），物化产出的数值（`SelectCost`、`Priority`、Mystery 真身、敌人赋级）必进。**明示例外**是 `LifeSpanAfter`。痕迹存的是 `eventEnd` 那**一次**合并 `TryApply` 的最终 spec，不存分散片段。未选项只归档轻摘要（`UnchosenOptionRef`，求可回溯不求可重建）。单事件增量 ~770 B，**落在既有 ~2 KB 预算内 ⇒ push 粒度不变**。字段清单 → `systems/adventure-event/common-properties.md`。
  - 顺带记住这条**不是**冲突：「定稿实例必须落存档」与「存档态只带 `Id` + 可变状态、不复制展示文本」管的**不是同一类字段**（前者管物化数值，后者管展示文本），两条同时成立——别为消解「冲突」去松动其中一条。
- **两个内容版本号：** `StartContentVersion`（轮回开始，写一次不变）与 `LastContentVersion`（每个存档点更新）。**二者不等 = 该轮回跨过内容更新**，是排查「数值突变」类反馈的第一判据（因已裁决不冻结 `contentVersion`，一个版本号无法表达「跨过」）。
- **RNG 状态：** `CycleSeed` + 每个子流的 `Seed` / `State` / `DrawCount`。→ `rng-determinism.md`。
- **篇章重试计数分两层、口径不同，不是同一个数的两份拷贝：** 角色级 `CharacterProfile.chapterRetry` = **三个具名字段**（与「四境三篇章」对齐），是闸门输入、**通关后保留**（它是历史不只是配额）；账号级另有**纯读数的统计计数**（`PlayerProfile` 上新的一类字段族，与 Achievements 相邻但无奖励）。ch1 角色级恒为 0 不是死字段——「炼气段重开几次」由账号级回答。
- **战斗挂起态：** `CharacterProfile.ActiveCombat` 可空块（见承重纪律 4）。轮回结束 / 战斗收口后置空。
- **「本轮回禁用」落轮回级字段 `CharacterProfile.disabledAbility`**（与 `pastEvent` / `activeCombat` 平级，不进 `Status`）——账号级 `status` 开关承载不了。法则**不会被强制从账号剥夺**，真正移除只发生在玩家自愿的「置换」中。**存「施加时坐标 + 时长」，不存「到期坐标」**（判据同 08-09c：重算不出来的存）。**连带修正一处既定 schema：`ActiveCombat` 的「可重建项」重放依据须补 `disabledAbility`**——`Power` 的入场从两条与门变成三条（`status` 开启 ∧ `UsableScene` 含 `InCombat` ∧ 不在禁用表内），但禁用表本身随存档走，重建仍确定性，**不需要给 `activeCombat` 新增任何字段**。→ `systems/character-profile/_index.md`。
- **push 信封**另带内容 / 应用版本与 `revision`，让后端**不解 Profile** 即可做版本维度聚合。**客户端 record 不因传输形态改动**（08-11b）：`AppVersion` / `ContentVersion` 与 token 由 `HttpXxxBackend` 搬进 HTTP 头，`pushId` / `baseRevision` / `schemaVersion` / `reason` 留在 body 的信封段（CAS 前置条件与它保护的负载留在同一层面，**不用 `If-Match`/ETag 表达**）。
  - **`X-Request-Id` 与 `pushId` 是一对反向纪律，写反哪个都静默失效：** `pushId` 是幂等键，**跨启动重试必须不变**；`X-Request-Id` 是日志关联键，**每次重试都必须换**。前者写错丢进度，后者写错让日志无法定位单次尝试。
  - **跨边界枚举值以字符串序列化且与 C# 枚举名逐字相同** ⇒ **重命名一个跨边界枚举值即是破坏性契约变更**，必须与后端同批改，不能当作纯客户端重构。

## 格式选择

JSON（`System.Text.Json` 或 Godot `JSON`）可读且便于迁移；Godot 资源序列化是另一选项。**选定其一后记录于此**，并把序列化集中在 sync-service 内。

> 篇章边界另有**境界存档点**语义（通关后在所达境界落点；失败清理该角色并扣减该篇章重试次数）——归 ChapterManager。**逐篇章的重试次数是基线值、可被 premium bundle 抬高**，具体取值见 `decisions/ADR-0004` 与 `systems/monetization.md`，不在此复制。
