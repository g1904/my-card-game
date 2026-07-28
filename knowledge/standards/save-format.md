# 标准 —— 存档格式（引用层）

`.claude/rules/state-save-rules.md`（存档 / 读档章节）的配套。**权威：`game-design-documents/20-systems/services/sync-service.md`**（API 契约、`PushPolicy` / `SavePointReason`、断线降级完整表）与 `10-handoffs/2026-07-27-content-gating-offline-resilience-and-rng-persistence.md`（§2 / §4 / §6）——**字段清单、枚举、数值旋钮去那边看**。

由 **sync-service** 拥有：ProfileSyncManager（上下行与冲突）、LocalCacheManager（`user://` 原子写）、MigrationManager（schema 迁移）。

## 结构与权威

- **`PlayerProfile ⊃ List<CharacterProfile>`** ——账号级主档持有轮回级角色档案。因此**存档提交点唯一**，由单一 profile-service 作为两层的写入面（「扣账号级 PlayerItem 次数 + 扣轮回级灵玉」天然落在同一事务内）。
- **强制在线 · 云端权威**（ADR-0003）：启动全量 Pull，存档点 Push，冲突**一律以云端为准**。`user://cache/` 仅作本地缓存 / 断线临时态，**不是权威**。

## 承重纪律

1. **原子写，绝不原地覆盖。** 序列化到临时文件 → flush/close → **rename 覆盖**真实文件。写入中途崩溃保留上一份完好存档。同一条纪律也用于 overlay 提交点（→ `data/_index.md`）。
2. **绝不回退存档点。** 断线时变更进本地待发队列重试，**不阻塞玩家**；「云端权威」解决的是**冲突**，不是**丢进度**。（唯一硬阻塞是启动 Pull 失败——强制在线下无权威档即不可玩，且**不提供本地缓存开局**。）
3. **存档点 ≠ push。** 每个逻辑存档点（轮回开始 / 每个 AdventureEvent 结算后 / 篇章边界 / 轮回结束）**立即原子写本地**；受频率约束的只是网络 push（防抖合并）。**应用失焦 / 挂起必须立即 flush** ——那是移动端被系统杀死前的最后机会。
4. **`PushAsync` 不接收 profile 参数。** profile 的内存权威在 profile-service；让调用方递一份进来等于把「谁是权威」再打开一次。
5. **增量 push 按 `CharacterProfile` 粒度 diff。** `PlayerProfile` 整聚合含全部历史角色、随账号年龄单调增长，整体上行不可持续。
6. **恢复后先 pull 再 flush。** 若云端 `revision` 已领先本地基线（多设备），**以云端为准丢弃本地缓冲**并明确告知玩家。**不做静默合并、不引入字段级三路合并**——那会实质削弱 ADR-0003。
7. **存档带 `version` 并有迁移路径。** 相等 → 直接加载；更旧 → 逐版迁移；更新 / 未知 → **优雅拒绝**，绝不崩溃。当前无线上存档、迁移为空迁移，但 `MigrationManager` 的骨架**就在此刻**立起来（最便宜的时机）。
8. **读档校验是强制的**（→ `.claude/rules/null-check-rules.md`）：未知内容 `Id`、版本不匹配、缺失字段必须以清晰错误 / 迁移处理，绝不静默为 null。

## 存什么

- **只存 `Id` + 可变状态，不复制展示文本** ——文案变更不触发存档迁移。
- **例外：物化后的 `EventOption` 整份落存档，不能只存 `EventId` 事后重算。** 物化用了 seeded RNG、当时的角色状态与可热更的模板，重算不保证同结果——会导致「呈现时看到的事件」与「结算时执行的事件」不一致。当前批 eventOptions 与 `pastEvent` 痕迹都存物化快照，**按 `InstanceId` 定位**（`EventId` 不可替代——同一模板可在一次轮回被物化多次）。快照的字段 schema 与其对 push 体积的影响**仍待定**。
- **两个内容版本号：** `StartContentVersion`（轮回开始，写一次不变）与 `LastContentVersion`（每个存档点更新）。**二者不等 = 该轮回跨过内容更新**，是排查「数值突变」类反馈的第一判据（因已裁决不冻结 `contentVersion`，一个版本号无法表达「跨过」）。
- **RNG 状态：** `CycleSeed` + 每个子流的 `Seed` / `State` / `DrawCount`。→ `rng-determinism.md`。
- **push 信封**另带 `contentVersion` / `appVersion` / `revision`，让后端**不解 Profile** 即可做版本维度聚合。

## 格式选择

JSON（`System.Text.Json` 或 Godot `JSON`）可读且便于迁移；Godot 资源序列化是另一选项。**选定其一后记录于此**，并把序列化集中在 sync-service 内。

> 篇章边界另有**境界存档点**语义（通关后在所达境界落点；失败清理角色并扣减重试次数 ch1 ∞ / ch2 3 / ch3 1）——归 ChapterManager，权威见 `50-decisions/ADR-0004`。
