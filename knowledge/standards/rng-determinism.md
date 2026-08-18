# 标准 —— RNG 与确定性（引用层）

`.claude/rules/state-save-rules.md`（RNG 章节）的配套。**权威：`game-design-documents/systems/services/life-cycle-service.md`**（SeedManager、子流清单、`rng` schema 与字段类型）与 `handoffs/2026-07-27-content-gating-offline-resilience-and-rng-persistence.md` 第 5 节。**子流清单、schema、字段类型去那边看，此处不复制。**

## 代码现状

**尚无 SeedManager、无任何随机源代码。** 下列全是规划中的纪律。

## 确定性的边界（已定案）

每局轮回有一个存储的 `CycleSeed`，一切玩法随机性由它派生；**可复现性只在同一 `contentVersion` 内成立**——overlay 热更在轮回进行中即生效、不冻结版本，跨内容版本复现已明确放弃。存档记两个版本号用于事后归因。**每日种子 / 排行挑战不在中期路线内，不为其预留冻结结构。** → `systems/services/life-cycle-service.md`、`standards/save-format.md`。

## 承重纪律（写代码时会改变写法的那几条）

1. **绝不用未加种子的 `GD.Randi()` / `GD.Randf()` / `System.Random()` 决定任何影响游戏结果的事**——它们只能用于永不需要复现的装饰性抖动。
2. **一律经具名子流取随机，不从单个全局生成器抽**：不隔离会让不相关的系统互相错位（多抽一张卡移动地图生成）。子流清单是 SeedManager 内的常量。→ `systems/services/life-cycle-service.md`
3. **经 `life-cycle-service.Stream(RngStream)` 取 `RandomNumberGenerator`**（而非返回 `int`）——它自带可序列化的 `Seed` / `State`，正是持久化形态的载体。→ `systems/services/life-cycle-service.md`
4. **恢复用 `State`（O(1) 回填），诊断用 `DrawCount`（迁移保险）；读档时在任何抽取发生之前先恢复各状态。** → `systems/services/life-cycle-service.md`
5. **战斗内随机直接用 `combat` 子流，不在其上再派生一层**——防 re-roll 已由决策点存档 + `State` 持久化封住；篇章重试整个换一套新随机流（`RetryChapter` 生成全新 seed）。→ `systems/services/life-cycle-service.md`
6. **账号级掉落的掷骰绝不走 SeedManager 的子流**（否则玩家能靠篇章重试换一次掷骰结果）——残卷改用 `Hash64(AccountSeed, FinaleWinOrdinal)`，序号本身即幂等键。→ `systems/player-profile/player-power/_index.md`
7. **增删子流不 bump 存档 schema**：读档遇未知子流 `PushWarning` + 全新初始化，遇已删子流警告并丢弃。→ `systems/services/life-cycle-service.md`

## 验证小贴士

廉价的确定性测试：**在同一 `contentVersion` 下**以同一 seed 跑两次脚本化输入，断言得到的 `CharacterProfile` 完全一致。若 / 当存在测试框架时加入（默认不要求）。
