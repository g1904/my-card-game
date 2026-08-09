# player-profile

> 玩家信息 / **PlayerProfile** —— 账号级主档，跨轮回持久，持有一组 CharacterProfile 及账号级元数据。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **PlayerProfile = 账号级主档（元进程层）。** 跨轮回持久，持有 `List<CharacterProfile>`（单次轮回状态见 `../character-profile/`）及账号级元数据。与「强制在线 · 云端权威」一致——PlayerProfile 是云端权威主档。Source: `handoffs/2026-07-24-docs-restructure-class-model.md`。
- **账号级字段（大局骨架）。** `List<CharacterProfile>`、`GameSetting`、`List<PlayerPower>`、`List<PlayerItem>`、`List<Achievements>`、**六个 Codex（图鉴族）**、**统计计数（08-06b 新增，见下）**、`AccountInfo` 等——`PlayerPower` / `PlayerItem` / `Achievements` / Codex 是**独立于任何单次轮回**的账号级解锁、成就与收集。Source: `systems/services/life-cycle-service.md` + `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md`。
- **子系统的文件形态（已定案）。** **`player-item/`、`player-power/`、`achievements/`、`codex/` 各成文件夹**（有子结构，`_index.md` + `common-properties.md`）；**`account-info.md`、`game-setting.md` 结构轻，各为独立 markdown**。Source: `handoffs/2026-07-26-event-priority-skip-semantics-and-hotfix-scope.md` + `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md`。
- **图鉴族归本层，共六个（已定案）。** 图鉴是**跨轮回持久的知识资产**，故归账号级而非角色级；它与战斗内的意图揭示 / 探查按「静态知识 vs 动态情报」分层。除 **EnemyCodex** 外还有 **CharacterPowerCodex / PlayerPowerCodex / CharacterItemCodex / PlayerItemCodex / LocationCodex**（**LocationCodex 是玩家不可见的 `locationMap` 唯一的显影通道，「去过即记」**），六者形状相同（账号级、按 `Id` 索引、静态文案、存档只记解锁状态），合为一族。**它是元进程的第三条积累线**（与 PlayerPower 的「能力」、Achievements 的「成就」并列）。见 `codex/`。Source: `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md` + `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。
- **账号级统计计数：新增的一类账号级字段（已定案 · 08-06b）。** 与 `Achievements` 相邻但不同——**成就是有奖励的里程碑，统计计数是纯读数**。首项是**篇章重试的账号级累计**（跨角色累加各篇章重开次数），它与 `CharacterProfile.chapterRetry` **口径不同、不是同一个数的两份拷贝**：角色级参与闸门判定（与上限相减得「还剩几次」），**账号级不参与任何规则判定，只被读来看**。**它同时化解了 ch1 的死字段问题**——ch1 重试 = 随机生成新角色，故角色级 ch1 计数恒为 0，而「你在炼气段重开了多少次」这个有意义的问题由本层回答，**07-30b 的 ch1 重试语义因此不必改写**。字段形态与首批统计项见待决问题。Source: `handoffs/2026-08-06b-asymmetric-ch1-band-consented-power-loss-and-chapter-retry-shape.md`。
- **`PlayerPowerFragment` = `PlayerProfile` 上的具名小类，参与规则判定、不并入统计计数（已定案 · 08-09b）。** 道统残卷（Finale 失败累积、Finale 胜利掷定的 PlayerPower 掉落概率，机制见 `player-power/_index.md`）的状态载体：

  | 字段 | 类型 | 语义 | 默认 |
  |------|------|------|------|
  | `Accumulated` | `int` | 累积概率，**万分比整数** 0–10000。**不用 `float`**：存档 / 跨端一致性 + 后端可复算，且避免浮点比较 | `0` |
  | `FinaleWinOrdinal` | `int` | 账号级 Finale **胜利**序号，单调递增、不清零（失败与「失败但存活」都不自增）；同时是掷骰的**幂等键** | `0` |
  | `Ch1FirstWinDone` / `Ch2FirstWinDone` / `Ch3FirstWinDone` | `bool` | 各篇章 Finale 是否已首胜（首胜 100% 的判定源；**失败但存活不置位**） | `false` |

  - **不并入 08-06b 的账号级统计计数容器。** 判据是 08-06b 已立的那条——**参与规则判定的字段与纯读数的统计计数分属两层**。残卷概率直接决定「发不发一条法则」，是规则输入，与 `CharacterProfile.chapterRetry` 同性质；混进统计计数会让「统计可走宽松同步口径」这条便利判断失效。
  - **三个首胜标记落具名布尔**，沿用 `chapterRetry` 的既定形态（篇章数是固定的游戏结构，不是可扩展列表），不用字典 / 索引数组。
  - **`x`（已拥有法则数）不落字段**——它是 `List<PlayerPower>.Count` 的派生量，落字段即制造第二份真值（与「`CapabilitiesChanged` 空负载、订阅者自行重查」同一条纪律）。
  - **读档校验：** `Accumulated` 落在 `[0, 10000]` 外 → `GD.PushWarning` + 钳制；三个首胜布尔与通关史不一致时**以布尔为准**（它是权威，不由通关史重建）。
  - **schema 影响：** 本类 5 个字段 + `AccountInfo.AccountSeed` ⇒ 存档 schema 版本 bump，迁移 = 老档缺字段以默认值补齐（无损）。
  Source: `handoffs/2026-08-09b-player-power-fragment-finale-bound-drop-chance.md`。
- **账号级字段分两层，判据是「它有没有被规则读」（通则 · 已定案 · 08-09d）。** 08-06b（`chapterRetry` 的账号级累计）与 08-09b（`PlayerPowerFragment` 不进统计计数）两次用到的同一条判据，本次升格为 `PlayerProfile` 上账号级字段的通则：

  | | **规则字段层** | **统计计数层** |
  |---|---|---|
  | 判据 | 被任何判定 / 闸门 / 幂等键读取 | 只被 UI 读来展示 |
  | 例 | `PlayerPowerFragment.*`、`CharacterProfile.chapterRetry` | 篇章重试的跨角色累计、`TotalCyclesCompleted` |
  | 同步口径 | 严格：随 profile diff 上行，**后端可复算校验** | 宽松：被篡改无玩法后果 |
  | 读档校验 | 越界钳制 + 告警；**不由历史重建** | 告警即可，不阻塞、不修复 |
  | 篡改后果 | 直接改变发不发一条法则 / 还剩几次重试 | 只是数字不好看 |

  - **依赖方向单向：** 规则字段层**可以**被统计 / UI 层读取展示；统计计数层**绝不可**被任何规则读取（防住反向的错误——拿走宽松同步口径的读数去做闸门输入）。
  - **展示不改变分层：** 被 UI 读到不会把规则字段变成统计计数。判据是「有没有被**规则**读」，不是「有没有被人看见」。
  - **合并判据（承重）：两个字段口径相近不构成合并理由。可以合并，当且仅当「语义 + 同步口径 + 篡改后果」三者全同；跨层的两个字段永远不满足这条。** 真实风险不是有人故意合并，而是后来者看到两个都叫「Finale 胜利次数」的整数理所当然地去重——只有正向的「何时才允许合并」才是可被主动执行的纪律。
  - **命名硬约定（可机械检查）：** 后缀 `Ordinal` ⇒ 规则字段层（语义是「第几次」，一个**位置**，参与判定 / 幂等键，严格同步）；前缀 `Total` / 后缀 `Count` ⇒ 统计计数层（语义是「一共多少」，一个**数量**，纯读数，宽松同步）。**统计计数层禁用 `Ordinal` 后缀**——`Ordinal` 出现即意味着「有人用它当键」。当前库内只有 `FinaleWinOrdinal` 一个 `Ordinal`，零迁移成本。
  - **`FinaleWinOrdinal` 的应用（已定案 · 08-09d）：统计侧不设「Finale 胜利数」字段**，「你渡劫成功了几次」的展示直读 `PlayerPowerFragment.FinaleWinOrdinal`。这是最强的防合并手段——让重复字段从一开始就不存在；依据是既有的单一真值纪律（落字段即制造第二份真值，而这份真值恰好是幂等键）。它计的是**渡劫成功**次数，1% 的「失败但存活」不计入，**因此可能小于已完成的篇章数——该差值是有味道的信息，不是 bug**。
  - **统计侧的「通关」= 完成整个轮回**（三篇章全通 · 抵达元婴），字段 `TotalCyclesCompleted`。一次通关贡献 3 次 Finale 参与、至多 3 次胜利，而 Finale 胜利可完全不伴随通关 ⇒ **两个数在任何账号上都不相等**，并列在同一张表里也不会看起来像同一个数（比任何注释都可靠）。**首批不设 `TotalChaptersCompleted`**：它与 `FinaleWinOrdinal` 只差 1% 分支、数值几近恒等，恰是最易被误合并的形态；日后若确需须独立命名并明写它计入 1% 分支，且照样受合并判据约束。
  - **不做两层之间的交叉一致性校验。** 写一条「`FinaleWinOrdinal` 应约等于统计通关数」的读档校验，等于在代码里承认它们该相等，是把已排除的合并从后门放回来。
  Source: `handoffs/2026-08-09d-field-layering-merge-criterion-and-ordinal-naming.md`。
- **账号级持有状态还包括付费凭证（已定案）。** premium bundle 的持有状态改写篇章重试上限（无限 / 9 / 3）并授予随机 PlayerPower / PlayerItem，故它是 PlayerProfile 上的一项账号级状态；落成什么字段未定。见 `systems/monetization.md`。Source: `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md`。
- **服务归属：profile-service（已定案）。** 账号级行为——PlayerPower 的获取 / 失去与 `status` 开关持久化、PlayerItem 使用次数扣减、成就进度与奖励发放、capability flag 聚合——归 **`systems/services/profile-service.md`**。因 `PlayerProfile ⊃ List<CharacterProfile>`，该服务**同时是两层 profile 的唯一写入面**（`ProfileManager.TryApply(spec)`，全有或全无），使「扣账号级 PlayerItem 次数 + 扣轮回级灵玉」天然落在同一事务内。登录归 `account-service`，云端同步归 `sync-service`。Source: `handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md`。

## 子系统导航

| 子系统 | 文件 | 内容 |
|--------|------|------|
| 古宝 player-item | `player-item/_index.md`、`player-item/common-properties.md` | 账号级、有使用次数限制的道具（PlayerItem），含可购道具定义。 |
| 法则 player-power | `player-power/_index.md`、`player-power/common-properties.md` | 账号级 always-available 能力（PlayerPower，带开关）；通过事件触发器的被动修正 / relic-joker，含 RelicData 定义。 |
| 成就 achievements | `achievements/_index.md`、`achievements/common-properties.md` | 账号级分组成就与两档（60% / 90%）一次性奖励；80/20 可见比例。 |
| 图鉴族 codex | `codex/_index.md`、`codex/common-properties.md`、`codex/enemy-codex.md` | **六个账号级图鉴**（Enemy / CharacterPower / PlayerPower / CharacterItem / PlayerItem / Location）：记录已遭遇 / 已获得对象的**静态文案知识**，不记录动态情报。 |
| 账号信息 account-info | `account-info.md` | 账号身份与状态元数据（AccountInfo）；强制账号登录，无游客态。 |
| 游戏设置 game-setting | `game-setting.md` | 账号级常规系统设置（GameSetting，音量等）。 |

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- **强制在线 · 云端权威**（PlayerProfile 为云端权威账号主档）→ `decisions/ADR-0003-online-cloud-authority.md`（Accepted）。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **元进程持久化范围与平衡边界：** 各账号级字段的具体 schema、解锁 / 获取触发，以及 PlayerPower 的平衡边界（防 pay/grind-to-win、是否影响 cycle seed / 计分公平）仍待定。→ 见 `systems/services/life-cycle-service.md`。
- **账号级统计计数的容器形态与首批统计项清单（08-06b 新增 · 08-09d 收窄）：** 落成 `PlayerStatistics` 类还是直接挂字段？除篇章重试累计与 `TotalCyclesCompleted` 外首批还统计什么（总 defeated 数 / 各 `DefeatReason` 计数）？宽松同步口径的具体形态是什么？**边界一问已答结**（见「意图」的两层通则与合并判据），**首批已确定含 `TotalCyclesCompleted`、不含 Finale 胜利数与篇章完成数**。→ `systems/services/life-cycle-service.md`、`sync-service.md`。Source: `handoffs/2026-08-06b-asymmetric-ch1-band-consented-power-loss-and-chapter-retry-shape.md` + `handoffs/2026-08-09d-field-layering-merge-criterion-and-ordinal-naming.md`。

## 对应
提炼至：`.claude/knowledge/systems/player-profile/_index.md`（待建）。
