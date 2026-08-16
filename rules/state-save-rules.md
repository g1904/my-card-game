# 轮回状态、RNG 与存档规则

深入配套文档：`.claude/knowledge/standards/rng-determinism.md`、`.claude/knowledge/standards/save-format.md`。

## 轮回状态
- **单次轮回的全部状态归一个持有者**（`life-cycle-service.CycleStateManager`），系统经它读写，不散落全局变量；
  轮回开始时干净重置、结束时拆解——残留的实例化节点 / 静态字段 / 未清空集合会跨轮回泄漏。
  字段清单与存档 schema 见 `game-design-documents/systems/character-profile/_index.md`。

## 带种子的 RNG（确定性）
- 每个轮回存储一个**种子（seed）**。所有玩法随机性（地图生成、抽卡、商店库存、奖励掷骰、敌人行为）都从该种子派生 —— 一律经 `SeedManager` 的具名子流（sub-stream）隔离，
  否则不相关的系统会互相打乱（desync）、同一种子不再复现同一轮回。子流划分见 `game-design-documents/systems/services/life-cycle-service.md`。
- **不要**用未加种子的 `GD.Randi()` / `Random` 来决定玩法结果。
- **绝不假定跨内容版本可复现**：确定性的边界只到同一 `contentVersion` 内，overlay 热更在轮回进行中即生效。
  依赖跨版本复现去做回放 / 排障 / 校验，会得到与线上不一致的结论。
  方向来源：`game-design-documents/handoffs/2026-07-26-event-priority-skip-semantics-and-hotfix-scope.md`。
- 在存档中持久化足够的 RNG 状态，使恢复的轮回能确定性地继续。

## 存档 / 读档
- **强制在线 · 云端权威（取代先前「仅离线，无网络」）。** 进度实时同步云端，本地↔云端冲突**以云端为准**；本地 `user://` 仅作缓存 / 离线临时态，不再是权威存档。方向来源：`game-design-documents/vision/scope.md` 与 `game-design-documents/handoffs/2026-07-22-online-cloud-combat-and-meta-clarifications.md`。（后端 / 账号 / 冲突合并的实现细节仍在设计中。）
- 原子写入与版本化仍适用——对本地缓存写入与上行云端负载都要原子、带版本。
- **原子写入：** 先序列化到临时文件，再重命名覆盖真实文件，这样写入中途崩溃也不会损坏存档。
- **给存档加版本**：带一个 schema 版本字段和一条迁移路径。当存档结构变化时，提升版本并在读取时处理旧版本（迁移或优雅拒绝）—— 绝不在较旧的存档上崩溃。
- 定义明确的自动存档点（例如每场遭遇战/地图节点之后），使被杀掉的应用能在一个合理的边界处恢复。
- 读取时校验存档（参见 `null-check-rules.md`）：未知的内容 id、版本不匹配或缺失字段必须以清晰的错误/迁移来处理，而非静默的 null。
