# 标准 —— RNG 与确定性（引用层）

`.claude/rules/state-save-rules.md`（RNG 章节）的配套。**权威：`game-design-documents/10-handoffs/2026-07-27-content-gating-offline-resilience-and-rng-persistence.md` 第 5 节**与 `20-systems/services/life-cycle-service.md`——**`rng` 的 JSON schema、字段类型去那边看**，此处不复制。

## 确定性的边界（已定案）

每局轮回有一个存储的 **`CycleSeed`**（u64），所有游戏随机性由它派生。**可复现性只在同一 `contentVersion` 内成立** ——相同 seed + 相同内容版本 + 相同玩家选择 ⇒ 相同轮回。

**已明确放弃跨内容版本的可复现性。** overlay 热更在轮回进行中即生效、**不冻结** `contentVersion`：「线上随时修正数值」的价值高于「跨版本复现」。存档记 `StartContentVersion` / `LastContentVersion` 两个版本号用于事后归因（→ `save-format.md`）。

**每日种子 / 排行挑战不在中期路线内，不为其预留冻结结构。** 若将来引入，正确做法是让该模式内的轮回绑定一个冻结的 `contentVersion` 快照，把例外**局部化**，而非回退全局决策。

## 承重纪律

1. **不用未加种子的 `GD.Randi()` / `GD.Randf()` / `System.Random()`** 决定任何影响游戏结果的事。它们仅可用于永不需要复现的纯装饰性抖动。
2. **按具名子流取随机，不从单个全局生成器抽。** 否则不相关的系统会互相错位（多抽一张卡会移动地图生成）。子流枚举 `RngStream { Map, Combat, Shop, Reward }`；派生式 **`streamSeed = Hash64(CycleSeed, streamName)`**。
3. **经 `life-cycle-service.Stream(RngStream)` 取 `RandomNumberGenerator`**（而非 `int Next()`）——Godot 的 `RandomNumberGenerator` 自带可序列化的 `Seed` / `State`，正是持久化形态的载体。派生与持有归 SeedManager。
4. **恢复用 `State`，诊断用 `DrawCount`。** `State`（u64）回填即 O(1) 恢复，不必重放；`DrawCount`（int）是迁移保险——`State` 是引擎实现细节，Godot 升级可能改其语义，届时用 `seed + drawCount` fast-forward 重放。读档时**在任何抽取发生之前**先恢复各状态。
5. **战斗内随机不直接用 `combat` 子流**，每场再派生一层 `Hash64(combatStreamSeed, eventId, attemptIndex)`。否则「退出重进」会重掷战斗随机——在强制在线 + 云端权威下这是**最易被发现的漏洞**。（`attemptIndex` 语义待定；若不落存档这层防护会落空 → `open-questions.md`。）
6. **子流清单是 SeedManager 内的常量。** 读档遇存档中没有的**新**子流 → `PushWarning` + 按 `Hash64(CycleSeed, name)` 全新初始化；遇清单里已不存在的**旧**子流 → 警告并丢弃。**增删子流不 bump schema 版本。**

## 验证小贴士

廉价的确定性测试：**在同一 `contentVersion` 下**用脚本化输入以同一 seed 跑两次，断言得到的 `CharacterProfile` 完全一致。若 / 当存在测试框架时加入（默认不要求）。
