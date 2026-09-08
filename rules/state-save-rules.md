# 轮回状态、RNG 与存档规则

深入配套文档：`.claude/knowledge/standards/rng-determinism.md`、`.claude/knowledge/standards/save-format.md`。

## 轮回状态
- **单次轮回状态归 `CharacterProfile`，唯一写入面是 `profile-service.ProfileManager.TryApply(spec)`**；`CycleStateManager` 只管状态机，不持有状态。
  散落写入会绕过「全量校验 → 全有或全无 → 单点提交」，写坏的档要到轮回中途才炸。
  → `game-design-documents/systems/character-profile/_index.md`
- 轮回开始时干净重置、结束时按**三层拆解**逐层收口——残留的实例化节点 / 静态字段 / 未清空集合会跨轮回泄漏，漏掉哪一层由权威逐层给出。
  → `game-design-documents/decisions/ADR-0165-cycle-exit-three-layer-teardown.md`
- 存档 `schemaVersion` 的**逐版登记**见 `game-design-documents/systems/services/profile-schema-versions.md`；JSON 字段名与上下行形态见 `game-design-documents/systems/services/sync-service.md`。

## 带种子的 RNG（确定性）
- 每个轮回存储一个**种子 `CycleSeed`**。**轮回级**的玩法随机性都从它派生 —— 一律经 `SeedManager` 的具名子流（sub-stream）隔离，
  否则不相关的系统会互相打乱（desync）、同一种子不再复现同一轮回。子流清单见 `game-design-documents/systems/common-properties.md` 与 `game-design-documents/systems/services/life-cycle-service.md`。
- **账号级随机绝不走 `SeedManager` 的子流**——子流由 `CycleSeed` 派生，而篇章重试会换 `CycleSeed`，挂上去等于让玩家靠重试换一次掉落结果。
  账号级另走具名域 + 单调序号的派生，随机源是契约定义的纯函数（后端要能复算）。
  → `game-design-documents/systems/common-properties.md`
- **不要**用未加种子的 `GD.Randi()` / `Random` 决定玩法结果；恢复所需的 RNG 状态必须随存档持久化，否则读档后的轮回不再复现。
  → `game-design-documents/systems/services/life-cycle-service.md`
- **绝不假定跨内容版本可复现**：确定性的边界只到同一 `contentVersion` 内，overlay 热更在轮回进行中即生效。
  依赖跨版本复现去做回放 / 排障 / 校验，会得到与线上不一致的结论。
  方向来源：`game-design-documents/handoffs/2026-07-26-event-priority-skip-semantics-and-hotfix-scope.md`。
- 在存档中持久化足够的 RNG 状态，使恢复的轮回能确定性地继续。

## 存档 / 读档
- **强制在线 · 云端权威。** 进度实时同步云端，本地↔云端冲突**以云端为准**；本地 `user://` 仅作缓存 / 离线临时态，不再是权威存档。
  **冲突语义已定案：云端领先即丢弃本地缓冲并告知玩家，明确否决字段级三路合并**（静默合并会实质削弱云端权威）。
  → `game-design-documents/vision/scope.md`、`game-design-documents/systems/services/sync-service.md`、`game-design-documents/decisions/ADR-0003-online-cloud-authority.md`
- 原子写入与版本化仍适用——对本地缓存写入与上行云端负载都要原子、带版本。
- **原子写入：** 先序列化到临时文件，再重命名覆盖真实文件，这样写入中途崩溃也不会损坏存档。**`user://` 的原子写只有一处实现（共享静态工具 `AtomicJsonFile`）**——各写一遍就是各漏一处 rename 语义。→ `game-design-documents/systems/architecture.md`「共享核心类型」
- **存档带 `schemaVersion` 与迁移路径，但不是每份 `user://` 文件都带版本。** 无脑加版本会让「版本不认识就整份丢弃」误伤设备维度小文件；漏加则旧档在新结构上直接崩。
  → `game-design-documents/systems/services/profile-schema-versions.md`
- 自动存档点是**一份已穷举的清单**（状态机边界 + 事件推进过程中的每个决策点），不要凭直觉自造新的落点；本作**没有玩家可见的地图节点**，别按那个心智去放存档点。
  → `game-design-documents/systems/services/life-cycle-service.md`（存档点清单）、`game-design-documents/systems/services/combat-service.md`（战斗内决策点）
- 读取时校验存档（参见 `null-check-rules.md`）：未知的内容 id、版本不匹配或缺失字段必须以清晰的错误/迁移来处理，而非静默的 null。
