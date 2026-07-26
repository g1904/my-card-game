# Run 状态、RNG 与存档规则

深入配套文档：`.claude/knowledge/standards/rng-determinism.md`、`.claude/knowledge/standards/save-format.md`。

## Run 状态
- 单一的 **RunState** 拥有全部单次 run 的数据（deck、relic、金币、地图位置、ante/楼层、当前遭遇战）。系统通过 RunState 读取/改动 run 数据，而非通过散落的全局变量。
- RunState 在 run 开始时被干净地重置，在 run 结束时被拆解 —— 不在多个 run 之间遗留数据（当心残留的实例化节点、静态字段和未清空的集合）。

## 带种子的 RNG（确定性）
- 每个 run 存储一个**种子（seed）**。所有玩法随机性（地图生成、抽卡、商店库存、奖励掷骰、敌人行为）都从该种子派生 —— 最好通过具名的子流（sub-stream）（例如地图用一个 RNG、战斗用一个 RNG），使不相关的系统不会互相打乱（desync）。
- 一个给定种子必须复现同一个 run。这是 roguelike 的要求：它使每日/种子 run、bug 复现和公平对比成为可能。**不要**用未加种子的 `GD.Randi()` / `Random` 来决定玩法结果。
- 在存档中持久化足够的 RNG 状态，使恢复的 run 能确定性地继续。

## 存档 / 读档
- **强制在线 · 云端权威（取代先前「仅离线，无网络」）。** 进度实时同步云端，本地↔云端冲突**以云端为准**；本地 `user://` 仅作缓存 / 离线临时态，不再是权威存档。方向来源：`game-design-documents/00-vision/scope.md` 与 `game-design-documents/10-handoffs/2026-07-22-online-cloud-combat-and-meta-clarifications.md`。（后端 / 账号 / 冲突合并的实现细节仍在设计中。）
- 原子写入与版本化仍适用——对本地缓存写入与上行云端负载都要原子、带版本。
- **原子写入：** 先序列化到临时文件，再重命名覆盖真实文件，这样写入中途崩溃也不会损坏存档。
- **给存档加版本**：带一个 schema 版本字段和一条迁移路径。当存档结构变化时，提升版本并在读取时处理旧版本（迁移或优雅拒绝）—— 绝不在较旧的存档上崩溃。
- 定义明确的自动存档点（例如每场遭遇战/地图节点之后），使被杀掉的应用能在一个合理的边界处恢复。
- 读取时校验存档（参见 `null-check-rules.md`）：未知的内容 id、版本不匹配或缺失字段必须以清晰的错误/迁移来处理，而非静默的 null。
