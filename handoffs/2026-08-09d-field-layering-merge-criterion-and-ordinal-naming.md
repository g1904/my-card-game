# 账号级字段的两层通则、合并判据与 `Ordinal` 命名硬约定

- id: 2026-08-09d-field-layering-merge-criterion-and-ordinal-naming
- date: 2026-08-09
- topic: systems/player-profile, systems/services/life-cycle-service, systems/services/sync-service, ux/screen-flow, terminology
- status: distilled
- distilled-to: systems/player-profile/_index.md, systems/services/life-cycle-service.md, systems/services/sync-service.md, ux/screen-flow.md, terminology.md, open-questions.md, open-questions/（01-combat.md, 06-meta-progression.md, update-log.md）, answer-logs/log-finale-win-ordinal-vs-statistics.md, `systems/services/（life-cycle-service.md, sync-service.md）`

## Intent（distilled）

**一句话：** 08-09b 留下的「`FinaleWinOrdinal` 会不会被当成统计侧的『总通关数』合并掉」这条边界，本次不靠注释解决，而靠**三条结构性纪律**关死——把 08-06b 已两次用到的分层判据升格为**明写的通则并补上「何时才允许合并」的反向判据**；**统计侧根本不设 Finale 胜利数字段**（展示时直读 `FinaleWinOrdinal`）；**`Ordinal` 后缀立为规则字段层的命名硬约定**。同时定下统计侧「通关」= **完成整个轮回**（`TotalCyclesCompleted`），使两个数在任何账号上都天然不等。

### 1 · 账号级字段分两层，判据是「它有没有被**规则**读」

08-06b（`chapterRetry` 的账号级累计）与 08-09b（`PlayerPowerFragment` 不进统计计数）已两次用到同一条判据，但每次都是就事论事地写在具体字段旁。本次把它写成 `PlayerProfile` 上**账号级字段的通则**：

| | **规则字段层** | **统计计数层** |
|---|---|---|
| 判据 | 被任何判定 / 闸门 / 幂等键读取 | 只被 UI 读来展示 |
| 例 | `PlayerPowerFragment.*`、`CharacterProfile.chapterRetry` | 篇章重试的跨角色累计、`TotalCyclesCompleted` |
| 同步口径 | 严格：随 profile diff 上行，**后端可复算校验** | 宽松：被篡改无玩法后果 |
| 读档校验 | 越界钳制 + 告警；**不由历史重建** | 告警即可，不阻塞、不修复 |
| 篡改后果 | 直接改变发不发一条法则 / 还剩几次重试 | 只是数字不好看 |

**依赖方向单向：** 规则字段层**可以**被统计 / UI 层读取展示；统计计数层**绝不可**被任何规则读取。这条同时防住反向的错误——拿一个走宽松同步口径的读数去做闸门输入。

**展示不改变分层：** 被 UI 读到不会把一个规则字段变成统计计数。判据是「有没有被**规则**读」，不是「有没有被人看见」。

### 2 · 合并判据（本次真正缺的那一条）

> **两个字段口径相近不构成合并理由。可以合并，当且仅当「语义 + 同步口径 + 篡改后果」三者全同。**
> **跨层的两个字段永远不满足这条**——它们的同步口径与篡改后果按定义就不同。

理由：08-09b 描述的风险不是「有人故意合并」，而是**后来者看到两个都叫『Finale 胜利次数』的整数，理所当然地去重**。写一句「注意别合并」在半年后必然失效；写成**可被主动执行的正向判据**（何时才允许合并）才管用。

### 3 · 统计侧不设「Finale 胜利数」字段；展示时直读 `FinaleWinOrdinal`

这是最强的防合并手段——不靠提醒，而是**让重复字段从一开始就不存在**。

- 「你渡劫成功了几次」的展示数据源 = `PlayerProfile.PlayerPowerFragment.FinaleWinOrdinal`；**统计计数层不持有这个数**。依据是既有的单一真值纪律（与「`x` 不落字段」「`CapabilitiesChanged` 空负载」同款）：落字段即制造第二份真值，而这份真值恰好是**幂等键**。
- 展示口径的一句注解：`FinaleWinOrdinal` 计的是**渡劫成功**次数，1% 的「失败但存活」**不计入**——因此它可能小于已完成的篇章数。**这个差值本身是有味道的信息，不是 bug**，措辞不得暗示二者应当一致。

### 4 · 统计侧的「通关」= 完成整个轮回

- **「通关」= 完成整个轮回**（三篇章全通、抵达元婴），字段 **`TotalCyclesCompleted`**。与 roguelike 通行口径一致（一次 run 一次胜利）。
- 一次完整通关贡献 **3 次** Finale 参与，其中胜利数 ≤ 3（1% 分支下可以只有 2 次胜利却仍完成三篇章）；而 Finale 胜利**可以完全不伴随通关**（只反复打 ch1）。
- 因此 **`TotalCyclesCompleted` 与 `FinaleWinOrdinal` 在任何账号上都不相等**（除极端巧合）。二者并列在同一张字段表里也不会看起来像同一个数——**这条比任何注释都可靠**。
- **首批不设 `TotalChaptersCompleted`**：它与 `FinaleWinOrdinal` 只差 1% 分支的那一点，数值几近恒等，**恰好是最容易被误合并的形态**。日后统计面板若确需「篇章进度」读数，须独立命名、**明写它计入 1% 的失败但存活分支**，且照样受 §2 的合并判据约束。

### 5 · 命名硬约定：`Ordinal` 后缀保留给规则序号 / 幂等键

```
后缀 Ordinal  ⇒ 规则字段层，参与判定 / 幂等键，严格同步
前缀 Total    ⇒ 统计计数层，纯读数，宽松同步
统计计数层禁用 Ordinal 后缀
```

- `...Ordinal` 的语义是「第几次」，是一个**位置**；`Total...` / `...Count` 的语义是「一共多少」，是一个**数量**。`Ordinal` 出现即意味着「有人用它当键」。
- 约定成本为零、**可机械检查**：`/derive-requirements` 与 code review 阶段可直接按后缀核对字段所属层。当前库内只有 `FinaleWinOrdinal` 一个 `Ordinal`，**零迁移成本**。

### 6 · 同步与校验：差别只在口径，不在写入路径

不为统计计数另开写入通道——两层都经 `ProfileManager.TryApply` 的同一次事务写入（既定的「唯一写入面」）。差异只在两处：

- **同步权威性**：规则字段随 `CharacterProfile` diff 严格上行、后端可复算；统计计数**可容忍丢失与最终一致**。**二者在同一次 diff 里，但校验强度不同**——宽松口径不削弱规则字段的严格上行。
- **读档校验**：`FinaleWinOrdinal` 沿用 08-09b 的「不由通关史重建」；**且明确不做两层之间的交叉一致性校验**。写一条「`FinaleWinOrdinal` 应约等于统计通关数」的校验，等于在代码里承认它们该相等，是把已排除的合并从后门放回来。

### 7 · 落地面

| 层 | 字段 | 类型 | 何时变 | 被规则读 | 被 UI 读 | 同步口径 | 读档校验 |
|---|---|---|---|---|---|---|---|
| 规则 | `PlayerPowerFragment.FinaleWinOrdinal` | `int` | **仅 Finale 胜利** +1 | **是**（掷骰幂等键） | **是**（渡劫成功次数） | 严格 · 后端可复算 | 不由历史重建；单调性被破坏 → `GD.PushError` |
| 统计 | `TotalCyclesCompleted` | `int` | 轮回完成（三篇章全通 · 抵达元婴）+1 | 否 | 是（总通关数） | 宽松 | 告警不阻塞、不修复 |
| —— | ~~`TotalFinaleWins`~~ | —— | **不设**：直读 `FinaleWinOrdinal` | —— | —— | —— | —— |
| —— | ~~`TotalChaptersCompleted`~~ | —— | **首批不设**（与 ordinal 数值几近恒等） | —— | —— | —— | —— |

日志：统计计数变更**不单独打日志**（纯读数，无诊断价值）；`FinaleWinOrdinal` 的变更已由 08-09b 的 `[LifeCycle-FinaleResolve] ... ordinal={o} ...` 覆盖。

## 后果

- `systems/player-profile/_index.md` 新增「账号级字段的两层、合并判据与命名硬约定」一条；08-09b 追加在待决问题里的那条边界要求就此移除。
- **统计计数的待决问题范围收窄**：只剩「容器形态（`PlayerStatistics` 类还是直接挂字段）+ 首批统计项完整清单 + 宽松同步的具体形态」；**首批已确定含 `TotalCyclesCompleted`、不含 Finale 胜利数与篇章完成数**。
- `sync-service.md` 补一句两层校验强度的关系；`terminology.md` 补一行 `FinaleWinOrdinal`（明写 ≠ 通关数）。
- `ux/screen-flow.md` 的元婴界面 / 玩家档案侧多一处数据源指向：「渡劫成功次数」读 `FinaleWinOrdinal`、「总通关数」读 `TotalCyclesCompleted`，**并列展示且允许不相等**。
- **存档 schema 不受本次影响**：`FinaleWinOrdinal` 已在 08-09b 的 bump 里；`TotalCyclesCompleted` 的 bump 归统计计数形态那条问题。

## 与既有决策的张力

**无。** 本次完全建立在 08-06b 的分层判据与 08-09b 的字段定案之上，不触及 `ADR-0003` / `ADR-0004`，不改 `PlayerPowerFragment` 的任何既定语义，也不改 push 粒度与存档点清单。唯一的新增约束是 `Ordinal` 命名硬约定，对现有文档零冲突。

**否决的备选（记录理由，避免被重提）：**

- **统计侧照常设 `TotalFinaleWins`，靠注释说明二者不同** — 两者取值恒等（都只在 Finale 胜利时 +1），**本就是同一个数的两份拷贝**，注释救不了；问题不是「说明不足」而是不该存在这个字段。
- **「通关」按篇章计** — 与 `FinaleWinOrdinal` 只差 1% 分支，数值几近恒等，是最容易被合并的形态。
- **把 `FinaleWinOrdinal` 移进统计计数容器、另立一个纯幂等键** — 一个数拆成两个仍需保持同步，幂等性变成两个字段的一致性问题，比现状更脆。
- **改用 `Hash64(AccountSeed, chapterId, characterId)` 之类的复合幂等键，彻底不要序号** — **跨轮回重开同一篇章会得到同一个 key** ⇒ 同一账号在不同轮回的同章掷骰结果恒等，玩家可观测到「这章永远不掉」。单调序号没有这个性质。
- **加一条读档交叉校验 `FinaleWinOrdinal ≈ 统计通关数`** — 见 §6，等于在实现层重新宣称二者应当相等。

## Open questions

- **账号级统计计数的容器形态与首批统计项清单**（前置依赖 · 归 `open-questions/01-combat.md`）：落 `PlayerStatistics` 类还是直接挂字段、除篇章重试与 `TotalCyclesCompleted` 外首批还统计什么、宽松同步的具体形态。**本次四条主张均不依赖它定稿**——通则、不设 Finale 胜利数字段、命名硬约定、`TotalCyclesCompleted` 的口径与容器形态无关；容器一旦定型，按其形态落位即可。
- **「通关」的中文定名**（通关 / 飞升 / 圆满）是否需要与 `terminology.md` 的修真词表对齐。归术语侧，不影响本次的结构主张。

## Notes / triage

来源：`inbox/solution-draft-finale-win-ordinal-vs-statistics.md`（`/provide-solution-draft` 产出，经用户 08-09 裁定三项取向，无剩余待决项）。草稿已移入 `inbox/archive/`。
