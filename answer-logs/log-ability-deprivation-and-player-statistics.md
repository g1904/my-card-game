# Answer log ability-deprivation-and-player-statistics

- 日期：2026-08-10
- 来源：`inbox/solution-draft-ability-deprivation-and-player-statistics.md`（原始意图 `inbox/draft-0810a.md`）→ `handoffs/2026-08-10c-ability-disable-replacement-and-player-statistics.md`
- 移出条数：**4**（`open-questions/01-combat.md` 的「本轮回禁用」与置换型剥夺片区全部；同名条目在 `player-power/_index.md`、`character-profile/_index.md`、`player-profile/_index.md`、`life-cycle-service.md` 一并移出）

---

**「本轮回禁用」的承载字段与生效面** → 落 **`CharacterProfile.disabledAbility`**，与 `pastEvent` / `chapterRetry` / `activeCombat` 平级，**不落 `Status` 内**（`Status` 是数值型运行状态，禁用表是集合型 build 状态）。条目 `DisabledAbilityEntry`（`Kind` / `Scope` / `AbilityId` / `Duration` / `AppliedAtSeq` / `AppliedAtChapter` / `SourceInstanceId`），**存「施加时坐标 + 时长」不存「到期坐标」**；三档 `DisableDuration { NextEvent, ThisChapter, ThisCycle }`，由 life-cycle-service 在 `eventEnd` 收口后与篇章边界两个既有时点纯函数式剔除。**生效判据统一为「截断在进入生效面那一步」**（`Power` 不入场、`Item` 不进本场可用道具、不进 capability 聚合与 modifier 表、触发器不注册）⇒ `Power` 的入场由两条与门变**三条与门**。**立即生效包括进行中的战斗**，但该路径在当前链路下不可达，故落地是「复用 `IgnoresProtection` 的战场移除路径 + `#if DEBUG` 大声失败」。**对玩家可见**：元进程界面照常列出、灰态 + 徽标 + 三档文案 + 长按查看来源；战斗屏不呈现。（→ `systems/character-profile/_index.md`、`systems/character-profile/power/_index.md`、`systems/character-profile/item/_index.md`、`systems/player-profile/player-power/_index.md`、`systems/player-profile/player-item/_index.md`、`systems/services/combat-service.md`、`systems/services/life-cycle-service.md`）

**置换型剥夺的候选池与对价规则** → **排除已有 · 同稀有度 · 先看后决 · 拒绝无代价 · 四类通用但只同类型置换**。同池判据 = `(Kind, Scope)` 全同（四个独立池，跨 `Scope` 置换会绕过「决定持久层」这个字段的语义）；抽取 = `AllEnabled()` 全池 → 同 `(Kind, Scope)` → 同 `Rarity` → 排除已持有 → seeded 抽一条，走 **`reward` 子流**（不新增子流）；**空池 → 整个置换成为空操作 + `PushWarning`**（不降级到相邻稀有度）；**置换能移除神通**；置换所得继承被换出条目的 `SourceCode`（08-10b），对残卷的 `x` 中性。新定名内容稀有度 **`RarityTier { Tier1..Tier5 }`**，挂 `PowerData` / `ItemData` / `CardData`，缺失 → `PushError`；**与优势档 `Tier { Narrow, Solid, Crushing }` 不得复用同一枚举、不得互相换算**。（→ `systems/player-profile/player-power/_index.md`、`systems/common-properties.md`、`systems/balance.md`、`systems/services/combat-service.md`）

**`ProfileChangeSpec` 表达三类移除的 element 形态** → **拆成三个平级只读列表**（`Elements` 资源 / `AbilityElements` 能力 / `Stats` 统计），而非给 `ChangeElement` 加可空字段——三者施加语义根本不同（走不走 modifier pipeline、要不要钳制、失败是否阻断）。**置换 = `Remove` + `Grant` 两条 element，由 `PairKey` 配对**，不是一条 `Replace`（原子性已由 `TryApply` 的「全有或全无」免费提供）。**⚠ 推翻旧措辞「置换作为选择成本似乎合理」：能力 element 在 `SelectCost` 内恒为空**，三种操作只出现在 outcome / reward 侧，形状与战后奖励面板同构的一个事件内决策点。**「按 `Id` / 随机 / 按 `Scope` 限定」三选一的旧问消解**——element 只承载已定稿的 `Id`。**`PushWarning` 的对称落点定在内容加载侧、形态是「清单列举」而非「比例校验」**（outcome 侧样本量是 1，必然误报；告警落在玩家进程里等于没人看见），另加一条非告警的可追溯性日志。连带把 `PowerScope` / `ItemScope` **合并为 `AbilityScope`**。（→ `systems/architecture.md`、`systems/services/profile-service.md`、`systems/adventure-event/common-properties.md`、`systems/services/content-service.md`）

**账号级统计计数的容器形态与首批统计项清单 · 宽松同步口径的具体形态** → 落成具名类 **`PlayerStatistics`** 挂 `PlayerProfile`（**一个类型就是一道可见的边界**，把「统计层不得被规则读」从纪律阶梯第 4 级抬到接近第 3 级）；**首批两项 `TotalCyclesCompleted` + `TotalCyclesDefeated`**，字段只读、唯一写入路径是 `StatDelta` 经 `TryApply`、与规则字段同批同事务；**不做按 `DefeatReason` 的分解**（平衡诊断归后端聚合）。**⚠ 推翻 08-06b「首项 = 篇章重试的账号级累计」**——它不在首批，**代价明写：「你在炼气段重开了多少次」目前没有字段回答**，需要时纯加法补。**宽松同步口径穷举为五处**：未知 `StatKey` 跳过而非整批失败 · 绝不经 modifier pipeline · 读档越界钳制到 0 且不由历史重建 · 上行被拒时随之丢弃不做补偿重放 · **后端不复算不校验，且不得用统计驱动任何发放**（第 5 条是防滑坡的关键纪律，须同时写进 `backend-design-documents/`）。（→ `systems/player-profile/_index.md`、`systems/services/sync-service.md`、`systems/services/life-cycle-service.md`）

---

**未随本次答结、仍留在待答清单的相邻项：** `RarityTier` 的分布与权重表 · `StatKey` 的完整成员清单（两条均为 08-10c 新增，落 `open-questions/01-combat.md`）；`CostKey` 的资源 element 清单与「负值施加的钳制规则」不受本次影响，仍待答。
