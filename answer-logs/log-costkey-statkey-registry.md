# Answer log costkey-statkey-registry

- 日期：2026-08-19
- 来源：`inbox/solution-draft-costkey-statkey-registry.md` → `handoffs/2026-08-19-costkey-statkey-registry.md`
- 移出条数：2

**`CostKey` 资源族的完整 element 清单（承重）** → 闭合为 **15 个成员**，由两层 Profile 字段表反向穷举而来、与「写入通道 = `Elements`」的格子双向满射：轮回层 7（`LifeSpan` · `Jade` · `LifeTotal` · `ManaLimit` · `ExperiencePoint` · `Faith` · `Bloodlust`）+ `playerPowerFragment` 7（`PowerFragmentAccumulated` · `PowerFragmentFinaleWinOrdinal` · `PowerFragmentCh1/Ch2/Ch3FirstWinDone` · `PowerFragmentLastRoll` · `PowerFragmentLastEffectiveChance`）+ `entitlement` 1（`BundleRedeemedOrdinal`）。连带：两处改名对齐字段（`Experience` → `ExperiencePoint`、`PowerFragmentWinOrdinal` → `PowerFragmentFinaleWinOrdinal`）· 三个首胜标记落三个具名成员并以 `int 0/1` 进 `Elements`（否决另开 `FlagChanges` 列、否决参数化 key）· 补上 `LastRoll` / `LastEffectiveChance` 两行原本缺失的配表行 · `ElementSpec` 保持六列 · 新增一个资源 element 的五步清单。（归档去向：`systems/architecture.md` · `systems/services/profile-service.md`）

**`StatKey` 的完整成员清单与增长登记方式，以及它在书写上如何与 `CostKey` 分开（轻）** → 成员清单**维持首批两项**并改名与字段逐字对齐（`TotalCyclesCompleted` / `TotalCyclesDefeated`）；增长登记为三步（加只读字段 → 加同名成员 → 零迁移），**明确不建 `StatFields` 配表**（六列逐列为空），替代品是启动期 `StatKey` ↔ `PlayerStatistics` **双向覆盖断言**；书写分野落成三条可机械核对的规则（有无配表 · 失败口径 · 词缀空间不相交），其本体是「元素键的分野 = 字段分层的投影」。另新增词缀合规的启动期断言与「成员名只可追加、永不改名 / 复用」的冻结纪律。（归档去向：`systems/player-profile/_index.md` · `systems/services/profile-service.md`）
