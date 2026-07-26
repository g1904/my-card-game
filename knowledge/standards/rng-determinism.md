# 标准 —— RNG 与确定性（深入）

`.claude/rules/state-save-rules.md`（RNG 章节）的配套文档。roguelike 的完整性依赖于此。

## 核心规则
每局 run 都有一个存储的 **seed**。所有游戏随机性都由它派生。相同 seed + 相同玩家选择 ⇒ 相同的 run。这使得 seeded/每日 run、bug 复现与公平排行榜成为可能。

## 子流（Sub-streams）
- 不要从单个全局生成器抽取所有随机性——不相关的系统会互相错位（多抽一张卡会移动地图生成）。
- 为每个领域提供从主 seed 派生的**独立**seeded 生成器，例如通过每领域的偏移/哈希：`map`、`combat`、`shop`、`rewards`、`events`。
- Godot 的 `RandomNumberGenerator`（`Seed`、`State`）是自然之选；为每个子流创建一个实例。派生与持有归 **life-cycle-service 的 SeedManager**；状态随 `CharacterProfile` 持久化。

## 不要做的事
- 对任何影响游戏结果的事物，不要使用未 seed 的 `GD.Randi()`、`GD.Randf()` 或 `System.Random()`。这些仅可用于永远不需要复现的纯装饰性抖动。

## 持久化
- 保存主 seed **以及**每个子流的 `State`（位置），使恢复的 run 继续完全相同的序列，而不是重启某个流。
- 读档时，在任何随机抽取发生之前先恢复各状态。

## 验证小贴士
一个廉价的确定性测试：用脚本化输入以同一 seed 运行两次，断言得到的 `CharacterProfile` 完全一致。若/当存在测试框架时加入此测试（默认不要求）。

> **待决张力：** 内容热更（`user://overlay/`）可能在 run 进行中改变数值，与「同一 seed 复现同一 run」冲突；是否需为进行中的 run **冻结 `contentVersion`** 尚未定。→ `game-design-documents/20-systems/services/content-service.md`。
