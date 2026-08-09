# Answer log finale-win-ordinal-vs-statistics

- 日期：2026-08-09
- 来源：`inbox/solution-draft-finale-win-ordinal-vs-statistics.md`（已评审 · 用户裁定三项取向）→ `handoffs/2026-08-09d-field-layering-merge-criterion-and-ordinal-naming.md`
- 移出条数：1（另 1 条收窄）

## 移出

**`FinaleWinOrdinal` 与账号级统计计数的边界（原 `open-questions/06-meta-progression.md`）** → 边界靠**三条结构性纪律**关死，不靠注释：

- **① 分层通则升格 + 补上合并判据。** 08-06b / 08-09b 两次用到的判据（**参与规则判定的字段 vs 纯读数分属两层**，判据 = 有没有被**规则**读）写成 `PlayerProfile` 上账号级字段的通则，含两层的同步口径 / 读档校验 / 篡改后果对照；并补上真正缺的反向判据——**可以合并，当且仅当「语义 + 同步口径 + 篡改后果」三者全同；跨层永远不满足**。附带两条：依赖方向单向（规则层可被 UI 读，统计层绝不可被规则读）、**被 UI 读到不改变分层**。（→ `systems/player-profile/_index.md`）
- **② 统计侧不设「Finale 胜利数」字段，展示直读 `FinaleWinOrdinal`（用户裁定）。** 让重复字段从一开始就不存在，比任何注释可靠；依据是既有的单一真值纪律。渡劫成功次数**向玩家展示**，1% 的「失败但存活」不计入，故可能小于已完成篇章数——**差值是有味道的信息，不是 bug**。（→ `systems/player-profile/_index.md`、`ux/screen-flow.md`）
- **③ 统计侧「通关」= 完成整个轮回（用户裁定，原选项 A）。** 字段 `TotalCyclesCompleted`（三篇章全通 · 抵达元婴 +1）。一次通关贡献 3 次 Finale 参与、至多 3 次胜利，而 Finale 胜利可完全不伴随通关 ⇒ **两个数在任何账号上都不相等**。**首批不设 `TotalChaptersCompleted`**（与 ordinal 数值几近恒等，最易被误合并）。（→ `systems/services/life-cycle-service.md`）
- **④ `Ordinal` 命名硬约定（用户裁定）。** 后缀 `Ordinal` ⇒ 规则字段层（位置 / 幂等键 / 严格同步）；`Total` / `Count` ⇒ 统计计数层（数量 / 纯读数 / 宽松同步）；**统计计数层禁用 `Ordinal` 后缀**。可机械检查，当前库内仅一个 `Ordinal`，零迁移成本。（→ `systems/player-profile/_index.md`、`terminology.md`）
- **⑤ 同步与校验的差别只在口径，不在写入路径。** 两层同经 `ProfileManager.TryApply`、同在一次 diff 里；规则字段严格上行 · 后端可复算，统计计数可容忍丢失与最终一致。**明确不做两层之间的交叉一致性校验**——那等于在实现层宣称二者应当相等。（→ `systems/services/sync-service.md`）

**否决记录：** 设 `TotalFinaleWins` 靠注释区分（本就是同一个数的两份拷贝）· 「通关」按篇章计 · 把 `FinaleWinOrdinal` 移进统计容器另立幂等键 · 改用复合幂等键 `Hash64(AccountSeed, chapterId, characterId)`（跨轮回重开同章会得到同一 key，玩家可观测到「这章永远不掉」）· 加读档交叉校验。

## 收窄（仍待答）

**账号级统计计数的形态与范围（`open-questions/01-combat.md`）** —— 只剩**容器形态**（`PlayerStatistics` 类 vs 直接挂字段）、**首批统计项完整清单**（除篇章重试累计与 `TotalCyclesCompleted` 外）、**宽松同步的具体形态**三项；边界一问不再挂在它上面，层归属（宽松侧）与首批的两项含 / 不含也已定。
