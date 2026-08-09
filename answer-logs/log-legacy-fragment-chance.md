# Answer log legacy-fragment-chance

- 日期：2026-08-09
- 来源：`inbox/solution-draft-legacy-fragment-chance.md`（已评审 · 机制核心由用户 08-09 三轮直接裁定）→ `handoffs/2026-08-09b-player-power-fragment-finale-bound-drop-chance.md`
- 移出条数：**2**（另 2 条收窄）

## 移出

**道统残卷概率的累积规则与上限（分片 ⑥ · 08-01 挂起）** → **整条答结，机制焊到 Finale 上**：

- **定名 = 道统残卷 / `PlayerPowerFragment`**（`terminology.md` 的「标识符待定」填实）。
- **累积粒度** = **Finale 战斗失败**（其余一切失败不累积），增量按 `(x, chapter)` 双重分档（`x` = 账号已拥有法则数）。
- **上限** = 按 `x` 分档的硬上限（50% → 30% → 30% → 10% → 10% → 5%），另有该档**基础概率作地板**；**适格篇章逐档累加地移除**（`x ≥ 5` 移除 ch1、`x ≥ 12` 再移除 ch2）；**每篇章首次 Finale 胜利硬置 100% 且优先于闸门**。**承重合一：适格 Finale ⟺ 该档增量 > 0 的篇章**，实现侧只需一张表。
- **掷骰与发放时刻** = **Finale 胜利、在该 Finale 的 eventReward 界面即时发放**（跨轮回时序整个消失，`PendingPowerId` 一类中间态不存在）；失败但存活的 1% 分支照常累积、不掷骰不发放。发放后 `Accumulated` 重置为 `Base(x + 1)`（不归 0），跨档不清空只钳制。
- **与 seed 公平性的关系** = **两者不相交**。掷骰走 `Hash64(AccountSeed, FinaleWinOrdinal) mod 10000`，**不经 SeedManager 的四条子流**（子流由 `CycleSeed` 派生，而篇章重试换 `CycleSeed` ⇒ 挂上去即可刷）；序号同时是幂等键；客户端掷、后端可复算。
- **落在 PlayerProfile 的哪个字段** = 新增具名小类 **`PlayerPowerFragment`**（`Accumulated` / `FinaleWinOrdinal` / 三个首胜布尔），**不并入账号级统计计数**（08-06b 的「参与判定 vs 纯读数」判据）；`AccountSeed` 落 `AccountInfo`。
- （归档去向：`systems/player-profile/player-power/_index.md`、`systems/player-profile/_index.md`、`systems/player-profile/account-info.md`、`systems/balance.md`、`systems/common-properties.md`、`systems/services/life-cycle-service.md`、`systems/services/profile-service.md`、`terminology.md`）

**礼包给的 PlayerPower 是否重置残卷概率（分片 ⑦ / `monetization.md` 待决项的一半）** → **不重置**，但使 `x` +1 从而可能把账号推进上限更低的档位。**这是有意的负反馈**：`x` 分档的本意就是「拥有得越多，后续越难再得」，渠道是打还是买不改变曲线。推论：**付费不吞掉已积累的失败，只让下一条法则来得更慢**，与「付费是增值而非必需」同向。（归档去向：`systems/monetization.md`、`systems/player-profile/player-power/_index.md`）

## 收窄（仍留在待答清单）

- **两条 PlayerPower 获取渠道的随机口径（分片 ⑦）** —— 交互与 RNG 两问已答结（见上），**剩下的只有「从哪个池抽、抽到重复怎么办」**，它是残卷伪码里 `pickedPowerId` / `HasGrantable()` 的前置依赖；残卷其余部分不依赖它。
- **账号级统计计数的字段形态（`player-profile/` 待答项）** —— 本次未答，但**追加一条边界要求**：定形态时须明写它与 `FinaleWinOrdinal` 的区别（前者纯读数、后者参与判定且是掷骰幂等键），避免被当成重复字段合并。

## 连带推翻 / 新增

- **推翻 08-06d 的「Finale 失败后可再次挑战」** —— 改为**每篇章一个 Finale、败后不可在同一篇章内重战**（`systems/adventure-event/finale/_index.md`）。
- **新增：Finale 失败但存活（约 1%）⇒ 篇章照常完成、境界照常突破** ⇒ **渡劫的胜负不再是篇章推进的闸门**（`systems/game-progression.md`）。
- **口径收窄：** 08-01 的「失败侧首次有产出」对**绝大多数失败**不再成立，常规失败的产出只剩 EnemyCodex 遭遇即记与失败经验两条；`systems/scoring.md` 与 `systems/services/future-event-service.md` 的论证链已相应改写。
- **新增待答 2 条**（分片 ⑥）：`FinaleWinOrdinal` 与统计计数的边界 · 1% 存活分支的叙事补白落点；**后端库新增 1 条**：`AccountSeed` 的下发与复算协议。
