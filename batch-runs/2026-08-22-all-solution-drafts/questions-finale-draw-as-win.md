# 补充核查 — Finale Draw 归入胜利侧 · 奖励最低档（用户 08-22 interview 新裁决）

> 只读核查。未写入任何设计库文件。本文件是 `questions-finale-death-rescope.md` 的**增量**，不重复它已列的 A1–A18 / B1–B6 / Q1–Q7。

## 裁决逐字与解读

> 「Finale 档二值化：非胜即败。Draw 归类到胜利，但奖励为最低档。」

**解读（两支）：**
- `d >= 0`（含原 `0 <= d < WinMargin` 的 Draw 区间）→ **通过**：角色存活 · 境界突破 · 篇章推进；落在 `0 <= d < WinMargin` 时**奖励取最低档**。
- `d < 0` → **失败 ⇒ 角色终结**（前一轮裁决）。

**⚠ 这条裁决的真正后果不是「多了一档奖励」，而是把 `WinMargin` 从「胜负门槛」降为「奖励档位线」。**
在 Finale 档，胜负判据的有效值退化为 **`0`**——**与 `Practice` 档同值**。`WinMargin` 3/5/8 在胜负链路上**从此没有任何消费者**。
这直接顶到两处承重结构：① `VictoryRule` 的**单字段形态**（它现在无法同时表达「胜负线 0」与「奖励线 N」）；② `WinMargin` 作为 **Finale 唯一难度旋钮**的地位（被抽空）。详见「新引出的待裁问题 R1 / R2」。

---

## Finale 通过时的全部产出面（逐项）

| # | 产出项 | 路径:行 · 原话要点 | 有无「档」的概念 |
|---|---|---|---|
| **P1** | **境界突破 + 等级归位** | `systems/adventure-event/combat/_index.md:36`「通过后角色进入新境界，**等级归位为新境界的初期**」；`systems/game-progression.md:23–29` 等级表 | **无档**（布尔） |
| **P2** | **篇章推进 + 篇章边界存档点** | `systems/game-progression.md:12`「每个 chapter 边界都是角色档案上的一个存档 / 记录点（共三个）」；`ADR-0004:13`「篇章通关即在所达境界落一个存档点」 | **无档**（布尔） |
| **P3** | **道统残卷 · 掷骰** | `player-power/_index.md:18`「**掷骰 = Finale 战斗胜利**（一次胜利掷一次）」；`:24` `rng = AccountRng.For(PowerFragment, ordinal)`，`ordinal = FinaleWinOrdinal + 1` | **无档**（掷 / 不掷）；生效概率本身有档，但那是 `clamp(Accumulated, Base(x), Cap(x))` 的 `x` 分档，与本次的「奖励档」不是同一个东西 |
| **P4** | **道统残卷 · 发放** | `player-power/_index.md:18`「**发放 = 该 Finale 的 eventReward 界面**」；`life-cycle-service.md:151` 授予 element + `Accumulated` 重置 element | **无档**（命中即发一条法则，法则本身按 `RarityTier` 加权抽） |
| **P5** | **道统残卷 · 累积（互斥另一半）** | `player-power/_index.md:18–19`「累积 = Finale 战斗失败」；「每个角色每篇章至多累积一次**或**掷骰一次且**二者互斥**」 | **无档**（累 / 不累） |
| **P6** | **`FinaleWinOrdinal`** | `player-profile/_index.md:100`「Finale **胜利**序号，单调递增、不清零；同时是掷骰的**幂等键**」 | **无档**（自增计数，+1 或不 +1） |
| **P7** | **`Ch1/2/3FirstWinDone`（首胜 100%）** | `player-profile/_index.md:101`；`player-power/_index.md:21`「某篇章的**首次 Finale 胜利**一律硬置 **100%**，即使该篇章在当前档已不适格」 | **无档**（置位 / 不置位；且置位那一次概率恒 10000，本身就是「最高档」） |
| **P8** | **`LastRoll` / `LastEffectiveChance`** | `player-profile/_index.md:102–107`「**每一次 Finale 胜利都掷这一骰并写 `LastRoll`，即使当次不发放**」；「首胜时 `LastEffectiveChance` 写 `10000`」 | **无档**（随 P3 照写） |
| **P9** | **战后奖励厚度 · 支路 A（强制奖励，可数量）** | `balance.md:124–136`：`element 量 = baseReward 该 element 量 + 道念差 × rewardPerMomentum[element]`；「平局给 0 加成」 | **有档 · 连续**（线性，`d = 0` 时加成恰为 0 = 天然最低） |
| **P10** | **战后奖励厚度 · 支路 B（可选奖励，品质）** | `balance.md:137`：`advantage = 道念差 / max(1, 角色 baseMomentum)` → `< 0.25` **险胜 `Tier.Narrow`** / `0.25~0.75` 优胜 / `≥ 0.75` 碾压；「只影响候选池稀有度权重，不影响数量（数量恒 3）」 | **有档 · 三档**（`Tier.Narrow` 即最低档） |
| **P11** | **`CombatResult.Spoils` 本体** | `combat-service.md:262`；`common-properties.md:242` `Source.CombatReward` | 无独立档，由 P9 + P10 合成 |
| **P12** | **`CombatOutcome` 取值 / 结算走向映射** | `combat-service.md:258`；`future-event-service.md:251–252`（`CombatWon` → `OnResolved`；`CombatOutcome.Draw` → `OnResolved`） | **无档**（枚举取值） |
| **P13** | **隐藏属性推拉（道心 / 煞气）** | `combat/_index.md:65,68`「`Finale` **胜利与失败都推**道心」「**推拉不套用 `FailureRatio`**，胜负同施一份 `HiddenStatGrade`」 | **无档 · 且不受影响**（胜负同施，扩大「胜」的定义不改变施加量） |
| **P14** | **经验产出** | `combat/_index.md:49`「Finale 自身的 `ExperienceGrade` 取 `None` 或 `Minor`」 | **有档但恒定**（Finale 本就近乎不给经验，无需分档） |

---

## 「最低档」的逐项落点

### ✅ 已有档位的两项：**零新增规则即满足裁决**（重要结论）

代入既定数值验算 `0 <= d < WinMargin` 这一区间：

| 篇章 | `WinMargin` | 巅峰 `baseMomentum` | `advantage` 上界 = `(N−1)/baseMomentum` | 落档 |
|---|---|---|---|---|
| ch1 炼气 | 3 | 15 | 2/15 = 0.133 | `Tier.Narrow` |
| ch2 筑基 | 5 | 32 | 4/32 = 0.125 | `Tier.Narrow` |
| ch3 金丹 | 8 | 75 | 7/75 = 0.093 | `Tier.Narrow` |

⇒ **整个 Draw 区间本来就整体落在 `Tier.Narrow`（险胜 = 最低档）之内**，且支路 A 在 `d = 0` 时加成恰为 0。
**用户要的「奖励最低档」由既有的两条换算规则自动兑现，不需要新字段、新分支、新表。** 这是本次最省的一处。
- **代价明写（须让用户知道）：** `Tier.Narrow` 不为 Draw 区间**独占**——ch1 `d = 3` 时 `3/15 = 0.2` 仍是 `Narrow`。即「刚好打平」与「领先 3 点」拿到**同一档**可选奖励，只在支路 A 的线性量上差 3 个单位。若用户要的是「Draw 区间**严格劣于**任何真胜」，则需新增一条线（见 R2 选项 ③）。

### ❗ 无「档」概念的项：逐项选项 / 后果 / 推荐

> 这是本次核查最重要的产出。这些项**要么给足、要么不给**，不存在「最低档」这个中间形态。

**P1 境界突破 + 等级归位**
- ① **照常突破、等级照常归位。** 后果：与「Draw 归类到胜利」字面一致；`天劫 diff = +1` 的自洽性推论（`combat/_index.md:39`）原样成立。
- ② 突破但等级不归位。后果：下一篇章角色带着上一境界的等级进入，`±2` 赋级带与 `baseMomentum` 表全部错位——**破坏承重结构，不可取**。
- **推荐 ①。** 它是「非胜即败」二值化的必然含义；任何别的选择都会重建被删掉的中间态。

**P2 篇章推进 + 存档点**
- ① **照常推进、照常落存档点。** 推荐。
- ② 推进但不落存档点。后果：玩家通过了 ch2 却无法读档续 ch3，等于隐性剥夺一次通关——与 ADR-0004「篇章通关即落存档点」直接冲突。
- **推荐 ①。**

**P3 残卷掷骰 · P4 发放 · P6 `FinaleWinOrdinal` · P8 两个中间值（四项必须同答，见下）**
- ① **照常掷骰 · 照常按结果发放 · `FinaleWinOrdinal` +1 · 两个中间值照写。**
  - 后果：`FinaleWinOrdinal` 保持「Finale 胜利序号」的字面语义；**后端 `contracts/profile-sync.md` §7 三条校验零改动**（① 逐位比对 ② 单向蕴含 ③ 序号恰 +1）；**后端库仍是零写入**。
- ② 不掷骰，`FinaleWinOrdinal` **不** +1。
  - 后果：残卷线上「这次胜利不存在」。**结构上引入第三态**——`player-power/_index.md:19` 的「每篇章至多累积一次**或**掷骰一次且二者互斥」变成「或都没有」（结构不破，防刷界更紧）。后端不受影响（序号未增即无 push 触发复算）。
  - **代价（重）：** ch3 免费档一生只有 1 次重试 ⇒ 一个「刚好打平」的 ch3 通关**永久拿不到那次掷骰**，而 ch3 是残卷分档表里增量最高的一章。玩家做对了（活着通过了）却在元进程上颗粒无收。
- ③ 不掷骰但 `FinaleWinOrdinal` **仍** +1。
  - 后果：**直接打破后端校验 ①**（`contracts/profile-sync.md:281–282,293` 明写「序号 +1 却不写 `lastRoll` ⇒ 校验 ① 会稳定失败」）。**⛔ 禁止选项，列出仅为排除。**
- ④ 照常掷骰，但生效概率按「最低档」折算（如取 `Base(x)` 而不取 `clamp(Accumulated, …)`）。
  - 后果：**破坏 `LastEffectiveChance` 的单一公式**，后端校验 ② 的自洽依赖「`lastEffectiveChance` = 掷骰当刻的生效概率」这一条口径；另开一支折算 ⇒ 客户端要在契约面外多一条规则，后端无从验真。且 `Accumulated` 的「跨档不吞掉玩家已积累的失败」承重语义被开口。
- **推荐 ①。** 依据三条：(a) 用户的裁决字面是「Draw **归类到胜利**」，残卷的三时刻判据写的就是「Finale 战斗胜利」，归类即适用；(b) ① 是唯一让**后端零改动**的选项——②/④ 都要重新表述「胜利」在契约面的含义；(c) 「奖励最低档」自然落在 P9/P10 上，残卷不是「奖励」而是**元进程产出**，把它也压到最低档需要新造一个概念。
- **⚠ 四项必须同答、不可拆：** `FinaleWinOrdinal` 既是掷骰序号又是幂等键又是后端复算入参（`player-power/_index.md:24–25`、`profile-sync.md:276–285`）。「掷骰 ⟺ 序号 +1 ⟺ 写两个中间值」是一个不可分的三元组。

**P5 残卷累积（互斥的另一半）**
- 本项**不需要新裁决，但要明写一条推论**：`life-cycle-service.md:150` 的「失败 → `Accumulated` 累加」现在恒等于「角色终结那一刻」（前一轮裁决），而 `0 <= d < WinMargin` 已划入胜利侧 ⇒ **累积只在 `d < 0` 时发生**。
- **推论：累积的触发面被这条裁决进一步收窄**——原本 `d < WinMargin` 的整个区间都累积（含领先 1~7 点），现在只有真落后才累积。**这削弱了「失败也在推进」的覆盖率**：一个「刚好打平」的玩家既拿不到最低档以外的东西，也不再有累积——但他拿到了通关，账是平的。**记为已知后果，不构成待裁问题。**

**P7 `Ch*FirstWinDone`（首胜 100%）**
- ① **照常置位、照常享 100%**（那一次 `LastEffectiveChance` 写 `10000`）。
  - 后果：与 ① 号 P3 一致；后端「首胜不是校验 ② 的例外」（`profile-sync.md:294`）原样成立。
  - **代价明写：** 玩家可以用「刚好打平」的最低档通过兑掉该篇章一生一次的 100% 首胜。**但这不构成可利用的口子**——要「打差却又不落后」需要精确控分且收益全负（其余产出全在最低档），没有理性玩家会这么做；而**真正的风险是反向的**：玩家在不知情时用一次险胜消耗掉了里程碑。
- ② 置位但不享 100%（首胜 100% 只认 `d >= WinMargin` 的胜利）。
  - 后果：在「首胜优先于闸门」这条**明写为承重**的规则上开一个例外分支；连带 `LastEffectiveChance` 首胜写 `10000` 的约定要跟着开例外 ⇒ **后端 `profile-sync.md:294` 那句「首胜因此不是校验 ② 的例外」失效，本次改动从「后端零写入」变成「跨库承接项」。**
- ③ 不置位（最低档通过不算首胜）。
  - 后果：该篇章的首胜标记仍为 `false`，但 **Finale 一章一次、通过即进入下一章** ⇒ 想再拿这一章的首胜只能重走整章（ch3 免费档仅 1 次）。等于**近乎永久丧失**一份账号级里程碑，且丧失原因玩家永远看不见（残卷对玩家彻底隐含）。**最差选项。**
- **推荐 ①。** 依据：三次首胜是 `player-power/_index.md:21` 明写的「账号生命周期里三份确定的里程碑」，其设立理由是「第一次渡劫成功却空手」的体验事故；② / ③ 都会把这个事故按新的判据重新制造出来。

**P12 `CombatOutcome` 在 Finale 的取值**
- ① **Finale 档 `Draw` 永不可达**：`d >= 0 → Victory`，`d < 0 → Defeat`。
  - 后果：结算走向走 `EventOutcome.CombatWon → OnResolved`，与既有映射表（`future-event-service.md:251`）天然对齐，**映射表零改动**；`combat-service.md:258` 的注释 `Draw = 未达 WinMargin` 须改。
  - **连带：`CombatOutcome.Draw` 的可达面从「两档可达」收为「仅 `Standard` 一档可达」。** 三值枚举仍是活结构（`Standard` 需要它），但 `combat/_index.md:30,157` 的「Practice 档永不可达 —— 干净的退化」要扩写为**两档退化**（Practice 因门槛为 0 而不可达，Finale 因二值化而不可达）。
- ② 保留 `Draw` 作为 Finale 的结算取值、只把它路由到胜利侧。
  - 后果：`CombatOutcome` 不再能被单读——消费侧每处都要问「这是哪一档的 Draw」。`future-event-service.md:252` 那行（`Draw` → `OnResolved`，理由写的是「平：只发 baseReward、不扣 lifeTotal」）在 Finale 下**理由不成立**（Finale 的最低档通过要突破境界、要掷骰），映射表要按 tier 分叉。
- **推荐 ①。** 「二值化」的字面即此；② 把一个枚举变成需要上下文才能解读的值，与库内「枚举成员的名字必须说实话」的一贯取向相悖。

---

## `WinMargin` 语义改变导致失效的既有表述（逐条）

> 以下**全部**是本轮新增（前一轮 B5 只动了「三重压迫的 (c)」一条）。

| # | 路径:行 | 原话 | 失效程度 |
|---|---|---|---|
| W1 | `balance.md:162` | 「`combatTier` 三档的遭遇参数：**难度旋钮 = `WinMargin`**，回合数 = 节奏旋钮」 | 🔴 **Finale 档整体失效**（Practice 0 / Standard 1 从来不是可调旋钮 ⇒ 这句话原本只对 Finale 成立，现在对谁都不成立） |
| W2 | `balance.md:164–168` 表 · `combat/_index.md:21` 表 · `ADR-0002:28–30` 表 · `future-event-service.md:108` | Finale 行「`VictoryRule(WinMargin N)`，`N` = ch1 3 / ch2 5 / ch3 8」/「须**领先 N 点**方可突破」 | 🔴 **语义反转**：`N` 不再是突破门槛 |
| W3 | `balance.md:170` | 「`N` 初值……分别对应开局落后 5/13/25 点」（用落差的比例论证 `N` 取值保守） | 🔴 **论证前提失效**——`N` 与开局落差不再叠加 |
| W4 | `balance.md:173` · `combat/_index.md:29` | 「Finale 是 build 的检验场——**「更难」体现在门槛，不体现在窗口**」（12 回合而非减回合的**唯一论据**） | 🔴 **论据被抽空**：门槛已归 0 ⇒「12 回合」这个取值失去了它的支撑理由（结论未必错，但理由要重写） |
| W5 | `balance.md:174` · `combat/_index.md:41` | 「⚠ Finale **三重压迫叠加**：(a) 开局落后 5/13/25 · (b) `WinMargin` 额外门槛 · (c) 失败扣 `lifeTotal` 最狠」 | 🔴 **(b) 整条消失**；(c) 已由前一轮升格为「直接死」⇒ **压迫从三重降为二重**（前一轮 B5 只改 (c)，本轮还要删 (b)）。注：`handoffs/2026-08-15d:114` 记的正是「四重降三重」，本轮是**第二次降级** |
| W6 | `balance.md:174` · `combat/_index.md:41` | 「**`WinMargin` 是双向的第一旋钮：实测过难先砍它、实测偏易先加它**，两个方向都优先于动回合数」（两处逐字重复） | 🔴 **整条作废**——它对 Finale 难度已无作用。**Finale 因此失去唯一的难度旋钮**，见 R2 |
| W7 | `combat/_index.md:80` | 判定伪码「`d >= WinMargin` → `Victory`；否则 → `Draw`」 | 🔴 前一轮 Q2 已列为待补 `Defeat` 分支；**本轮进一步要求 Finale 走另一条判据（`d >= 0`）** |
| W8 | `combat-service.md:254–255` | `int WinMargin, // Standard = 1、Practice = 0、Finale = N` + `// 差额未达 WinMargin → Draw` | 🔴 契约注释失效 |
| W9 | `combat-service.md:258` | `// Victory \| Draw \| Defeat（Draw = 未达 WinMargin，只发基础奖励）` | 🔴 同上 |
| W10 | `scoring.md:33` · `combat-service.md:12` | 「**平局 = 道念相等**……`CombatOutcome` 需要 `Draw` 这一态」 | 🟠 **口径三处不一致的老问题被本轮再顶一次**：`scoring.md` 说平局 = 相等，`combat-service.md:255` 说平局 = 未达 `WinMargin`。裁决后 Finale 侧两种口径都不再产生 `Draw` ⇒ **两句都只对 `Standard` 成立**，须各自加限定 |
| W11 | `scoring.md:56` | 「**`Practice` 与 `Finale` 档的回合数与胜负条件均可被改写**（前者更简单、后者**更难**）」 | 🟠 「后者更难」在胜负条件维度上不再成立（Finale 与 Practice 的胜负条件现在同为「不落后即通过」，只差 `d = 0` 是否算……实际连这个都不差） |
| W12 | `scoring.md:88` · `combat/_index.md:171` | 三档奖励厚薄归 ch1 数值标杆专场，括注引用「`Finale` 12 / `WinMargin` 3-5-8」 | 🟠 引用值语义变了，须改述 |
| W13 | `combat/_index.md:30,157` | 「`CombatOutcome.Draw` 在 `Practice` 档**永不可达**——干净的退化」 | 🟠 **扩写为两档退化**（见 P12 ①） |
| W14 | `combat/_index.md:150` | 「`CombatOutcome` 是三值……不加 `DrawCountsAsLoss`（三档恒 `false`）」 | 🟠 **论据要重看**：`DrawCountsAsLoss` 被删的理由是「三档恒 `false`」；现在 Finale 的行为**恰恰等价于 `DrawCountsAsLoss = false` 的极端形态**（Draw 全归胜侧），结论不变但要确认这条删除仍成立——**是的，仍成立**，因为新形态是把胜负线挪到 0，而不是把 Draw 判负 |
| W15 | `combat/_index.md:58` · `plot-manager.md:58` | 「隐藏属性影响 Finale 的路径是**拧参数**（更凶的天劫模板、**更高的 `WinMargin`**、更差的起手）」+「煞气 Band 3 的 arc 用 `Tighten` 拧 `WinMargin`」 | 🔴 **两处举例失效且是死效果**：`PlotModulation.Tighten`（`plot-manager.md:265` `EncounterTighten` 拧 `TurnLimit` / `VictoryRule`）在 Finale 上拧 `WinMargin` **对难度零作用**。这不只是换个例子——**剧情 / 隐藏属性拧 Finale 难度的通道被这条裁决关掉了一半** |
| W16 | `terminology.md:59`（`FinaleWinOrdinal`） | 前一轮 A12 已列（删「1% 失败但存活」分支）；**本轮追加**：须明确「Finale 胜利」现含最低档通过 | 🟠 |
| W17 | `future-event-service.md:252` | 结算走向映射表「`CombatOutcome.Draw`（打满道念相等）→ `OnResolved` —— 与「平：只发 `baseReward`、不扣 `lifeTotal`」对齐」 | 🟠 该行**只对 `Standard` 成立**，须加限定（选 P12 ① 时映射表本体无需改，只需限定说明） |
| W18 | `inbox/solution-draft-priority-elevation-conditions.md:187–188` | 退让位「① **下调 `WinMargin`**（既定的「双向第一旋钮」）」 | 🔴 **退让位失效**：`WinMargin` 已不控 Finale 难度 ⇒ 该草稿的退让顺序只剩「② 内容侧编排 `Recuperate`」一条。前一轮 Q5 只说要「换理由」，**本轮是这条退让位本身不成立** |

**不受影响（`WinMargin` 相关）：** `enemies/_index.md:81`、`combat/_index.md:67`、`handoffs/2026-08-17e:46`——三处都只讲 `Practice` 的 `WinMargin 0`，与 Finale 无关。

---

## 难度口径连带

**① 这是一次可量化的显著难度下调。** 通过所需追回的道念点数：

| 篇章 | 原（落差 + `N`） | 新（仅落差） | 降幅 |
|---|---|---|---|
| ch1 | 5 + 3 = **8** | **5** | −37.5% |
| ch2 | 13 + 5 = **18** | **13** | −27.8% |
| ch3 | 25 + 8 = **33** | **25** | −24.2% |

**② 与 `ADR-0004:21`「平衡基准是免费档」自洽——且是加强，不是冲突。** 该条要求「免费档应当可通关」；判定线下移直接提高免费档通关率。

**③ 与前一轮用户裁决的「ch3 重试上限维持 ∞/3/1、不做补偿」的先后顺序（如实指出）：**
- 用户做那条裁决时，判定线**尚未下移**——当时的语境是「失败必死 + 必须领先 8 点 + 一生 1 次容错」，是三重收紧。
- 本轮裁决后，语境变为「失败必死 + 只需不落后 + 一生 1 次容错」——**收紧与放松各一次，方向相反**。
- ⇒ **该裁决在新语境下不但仍然成立，理由还更强了**（当时用户接受的压力，实际压力低于他当时的判断）。
- **判断：不需要提请用户复核那条，但应在总报告里告知这个先后顺序**，让用户知道「你接受的那个苛刻程度，已经因为后一条裁决而自动缓解了」。若用户在得知后想反向收紧（例如把 ch3 上限从 1 降到 0，或上调开局落差），那是**新的意图**，走新一轮 interview，不属于复核。
- **🔵 可选提请项，非阻断。**

**④ 真正需要提请的不是重试上限，而是「Finale 还有没有难度旋钮」。** 见 R2——三重压迫已降为二重，且唯一可调的那一重被删除，剩下的 (a) 开局落后是 `baseMomentum` 表的必然结果、**不是旋钮**（动它会同时改变全部战斗的起跑线）。

---

## 新引出的待裁问题

> 按阻断程度排序。R1 改类型形状，必须先问。

### R1 —— `VictoryRule` 单字段形态如何承载「胜负线 0 + 奖励线 N」？【🔴 阻断 · 改契约形状】

**背景：** `VictoryRule(int WinMargin)` 是单字段（`combat/_index.md:80,150`、`combat-service.md:253–255`），且「不做可替换的判定对象、无需策略枚举、无需分发」是**明写的承重结论**（三处逐字重复：`combat/_index.md:58,80`、`plot-manager.md:58`、`handoffs/2026-08-17e:33`）。裁决后 Finale 需要**两个数**：胜负线 `0` 与奖励线 `N`。

- **① 三档 `WinMargin` 统一改为 `Practice 0 / Standard 1 / Finale 0`，`N` 作为奖励线**另立一条平衡数值（如 `FinaleRewardMargin`，落 `systems/balance.md`，**不进 `EncounterSpec` / `VictoryRule`**）。
  - 后果：`VictoryRule` 单字段形态**原样保住**；判定伪码不分叉（`d >= WinMargin → Victory` 对三档一律成立）；奖励线成为纯数值、与胜负判定解耦。
  - 代价：多一个平衡字段；`Tighten` 拧不到奖励线（见 W15 的连带）。
- **② `VictoryRule` 加第二个字段** `(int WinMargin, int RewardMargin)`。
  - 后果：**正是刚删掉的 `DrawCountsAsLoss` 式二字段回潮**；且 `Practice` / `Standard` 的 `RewardMargin` 恒等于 `WinMargin` ⇒ 撞上库内既有判据「**单一取值的维度不是维度**」（`update-log-archive.md:460`、`answer-logs/log-0815b.md:20`）。**不推荐。**
- **③ `WinMargin` 保留 3/5/8，判定按 `Tier` 分支**（Finale 走 `d >= 0`，其余走 `d >= WinMargin`）。
  - 后果：**直接推翻「无需分发」这条三处重复的承重结论**；且同一个字段在不同档下含义不同 = 最坏的一种字段复用。**不推荐。**
- **④ 不设奖励线**——Draw 区间的「最低档」由既有 `Tier.Narrow` + 支路 A 线性自然给出（见上文验算），`WinMargin` 在 Finale **成为无消费者的死结构 ⇒ 按库内既有判据直接删除**（Finale 取 `0`）。
  - 后果：**零新增字段、零新增数值、零结构变化**，且严格符合「没有消费者的死结构直接删」这条本库已执行过两次的判据。
  - 代价：**Finale 彻底失去难度旋钮**（与 R2 合流）；且「最低档」不为 Draw 区间独占（ch1 `d = 3` 也是 `Narrow`）。
- **推荐：④ 优先，退而求其次 ①。** 理由：用户要的「奖励最低档」在既有换算下**已经成立**，为它再造一条线是给一个已被满足的需求新增结构；若用户明确要求「打平的通过必须严格劣于任何真胜」，则取 ①。
  **⚠ 但 ④ 与 ① 都把 R2 顶到台面上**——必须两题连着问。

### R2 —— Finale 失去唯一难度旋钮，用什么补？【🔴 阻断 · 平衡口径 · 与 R1 连答】

裁决后 Finale 的压迫只剩两重：(a) 开局落后 5/13/25（`baseMomentum` 表的必然结果，**不是独立旋钮**——动它会同时改变全部战斗的起跑线）· (c) 失败即角色终结（**二值的，不可调**）。
且 `PlotModulation.Tighten` 拧 `VictoryRule` 这条剧情 / 隐藏属性通道对 Finale **失效**（W15）。

- **① 什么都不补，把 Finale 难度整体交给 ch1 数值标杆专场**（届时可动的是天劫的 `baseMomentum` 越阶量、天劫定制卡组强度、`TurnLimit`）。
  - 后果：最省；但**明写「Finale 现在没有第一旋钮」**这一事实，否则实测发现过易 / 过难时会有人去找那个已经不存在的旋钮。
- **② 把 `TurnLimit` 升为 Finale 的第一旋钮**（12 → 减少 = 更难）。
  - 后果：与 `combat/_index.md:29` / `balance.md:173` 明写的「Finale 更难体现在门槛、不体现在窗口；减回合会退化为纯起跑线检定」**正面冲突**——但那条论证的前提（存在门槛）已经消失，故它**本就需要重写**（W4）。
- **③ 新增一条 Finale 专属的起跑线偏移**（天劫额外 `+X baseMomentum`）。
  - 后果：新增字段 / 数值；但它是**最直接对位「开局落后」这一重压迫**的旋钮，且不碰胜负判定。
- **④ 取 R1 的选项 ①，让 `FinaleRewardMargin` 兼任「软难度」旋钮**（不影响通过，只影响奖励厚度）。
  - 后果：它调的是**回报**不是**难度**，回答不了「实测过难」；只回答「实测奖励太甜 / 太苦」。
- **推荐：① + 明写事实，并在 `balance.md` 把「Finale 的难度校准归 ch1 数值标杆专场，可动项为 (天劫 baseMomentum 越阶量 / 天劫卡组 / TurnLimit)」写成一条替代「双向第一旋钮」的指引。** 理由：本库既定分工是「数值归专场」，此刻凭直觉选旋钮与该分工相悖；但**必须留下一条明确的指引**，否则删掉「第一旋钮」那句话之后该位置是空白。

### R3 —— 残卷四项（掷骰 / 发放 / `FinaleWinOrdinal` / 两个中间值）在最低档通过下是否照常？【🔴 阻断 · 决定后端是否零写入】

选项与推荐见上文「P3」。**推荐 ①（全部照常）。**
**⚠ 这一题的答案直接决定本次改动是否仍是「后端库零写入」**：选 ① ⇒ 后端零改动；选 ② ⇒ 后端 §7 需明确「哪一类胜利触发复算」；选 ③ ⇒ 破坏后端校验 ①，禁止。

### R4 —— 最低档通过是否置位 `Ch*FirstWinDone` 并享 100% 首胜？【🟠 影响元进程里程碑】

选项与推荐见上文「P7」。**推荐 ①（照常置位、照常 100%）。**

### R5 —— `combat/_index.md:80` 的判定伪码最终写成什么？【🟠 文档层，答案随 R1 确定】

三档统一（R1 选 ④ / ①）⇒ `d >= WinMargin → Victory；否则 → Defeat`，配一句「`Draw` 只在 `Standard` 档可达（`d == 0` 且 `WinMargin == 1`）」。
**注意与前一轮 Q2 的关系：** 前一轮推荐「Finale 二值化、补 `Defeat` 分支」，用户裁决与之一致但**判定线位置不同**（前一轮设想的是 `d >= N → Victory`，本轮是 `d >= 0`）。**Phase B worker 必须以本轮为准。**

### R6 —— `PlotModulation.Tighten` 拧 Finale 的 `WinMargin` 已成死效果，怎么处置？【🟠 影响剧情调制面】

- ① 保留 `EncounterTighten` 拧 `VictoryRule` 的能力（对 `Standard` 仍有效），只在 `plot-manager.md:58` / `combat/_index.md:58` 把「更高的 `WinMargin`」这个**举例**换成对 Finale 真正有效的路径（更凶的天劫模板 `EnemyPoolScope` / `LevelBias` / 更差的起手）。**推荐。**
- ② 连带审视 `EncounterTighten` 本身是否还需要 `VictoryRule` 一格。后果：`Standard` 档拧 `WinMargin`（1 → 2）仍是有意义的难度手段，**不构成死结构**，不必删。
- **推荐 ①。** 换例即可，不动结构。

---

## 写入面清单（与前一轮合并去重）

**客户端库（`game-design-documents/`）—— 共 20 份主题 / 决策文档**（前一轮 18 份 + 本轮新增 2 份）：

```
systems/adventure-event/combat/_index.md      ← 前轮 A1 A2 A3 B4 B5 B6 + 本轮 W2 W4 W5 W6 W7 W13 W14 W15 P12
systems/game-progression.md                   ← 前轮 A4
systems/services/plot-manager.md              ← 前轮 A7（整节删）+ 本轮 W15 / R6（:58 举例换掉）
systems/services/life-cycle-service.md        ← 前轮 A8 B2 + Q4 写入顺序 + 本轮 P5 推论（:150 累积触发面收窄）
systems/services/combat-service.md            ← 前轮 Q2 + 本轮 W8 W9 W10（:12 :253–258）
systems/services/future-event-service.md      ← 【本轮新增文件】W17（:252 映射行加限定）· W2（:108 遭遇参数括注）
systems/scoring.md                            ← 【本轮新增文件】W10（:33）· W11（:56）· W12（:88）
systems/architecture.md                       ← 前轮 B1（DefeatReason）
systems/character-profile/_index.md           ← 前轮 B1
systems/player-profile/_index.md              ← 前轮 A10 A11 + 本轮 R3 / R4 落定后的 :100 :101 措辞
systems/player-profile/player-power/_index.md ← 前轮 A9 + 本轮 R3 / R4（:18 :21 「胜利」的定义扩大）
systems/balance.md                            ← 前轮 B5 + Q5 + 本轮 W1 W2 W3 W4 W5 W6 + R2 的替代指引（改动量本轮最大）
terminology.md                                ← 前轮 A12 + 本轮 W16
program-overview.md                           ← 前轮 B3
system-overview.md                            ← 前轮 A16
ux/screen-flow.md                             ← 前轮 A13 / Q7（:102 论据作废，本轮不追加）
ux/_index.md                                  ← 前轮 A15
systems/services/content-service.md           ← 前轮 A14
decisions/ADR-0004-realm-checkpoint-retry-model.md ← 前轮 A5（实质推翻）
decisions/ADR-0002-adventure-event-taxonomy.md     ← 前轮 A6 + 本轮 W2（:28–30 三档表 Finale 行）
decisions/ADR-0016-hidden-stat-band-model.md       ← 前轮 A17
```

**inbox 草稿（本轮新增一处实质改动，非仅换理由）：**
```
inbox/solution-draft-priority-elevation-conditions.md ← W18：退让位 ①「下调 WinMargin」本身不成立（前一轮 Q5 只说换理由，本轮升级为删除该退让位）
```
**⚠ 这条把「不能与 priority-elevation 分片并行」的结论进一步加强**——两者现在不只共写 `combat/_index.md`，本改动还直接**作废了该草稿的一条已裁决内容**。

**共享台账（orchestrator 单写者）：** 同前一轮，另加 `open-questions/01-combat.md`（若 R1 / R2 留作待答，须新增两条）。

**后端库（`backend-design-documents/`）：零写入 —— 但这个结论现在有前提。**
仅当 **R3 选 ①**（照常掷骰 / 序号照常 +1 / 两个中间值照写）且 **R4 选 ①**（首胜照常 100%、`LastEffectiveChance` 写 10000）时成立。
R3 选 ② ⇒ `profile-sync.md` §7 须明确「触发复算的胜利」口径；R4 选 ② ⇒ `profile-sync.md:294`「首胜因此不是校验 ② 的例外」失效。**两者任一非 ① ⇒ 本次升级为跨库改动，须按 `design-library-routing.md` 的对称落笔纪律在两侧留痕。**

---

## 不受影响（已核实，备案）

- **`Practice` / `Standard` 两档完全不受影响。** 裁决明确收窄到 Finale 一档。
  - `Practice`：`WinMargin 0` ⇒ `d >= 0 → Victory`。**注意一个新出现的巧合**——若 R1 取 ④（Finale `WinMargin` 也归 0），`Practice` 与 `Finale` 的**胜负判据取值相同**。这是两条独立理由收敛到同一个数（一个是「点到为止」，一个是「非胜即败」），**不是重复、不构成合并理由**，两档的语义、回合数、奖惩、残卷挂载全部不同。**必须在文档里写明这是巧合**，否则日后会有人把两档的 `VictoryRule` 提取成共享常量。
  - `Standard`：`WinMargin 1`、`d == 0 → Draw`、`Draw → OnResolved`、只发 `baseReward` 不扣 `lifeTotal` —— **`Draw` 的语义在该档原样保留**，且它现在是 `CombatOutcome.Draw` 的**唯一可达档**。
  - 两档的失败语义（只扣 `lifeTotal`、经 `LifeTotalExhausted` 通道）原样保留 —— 与前一轮结论一致。
- **`CombatOutcome` 仍需三值。** `Draw` 有唯一但真实的消费者（`Standard`），不是死结构；`DrawCountsAsLoss` 的删除理由仍成立（见 W14）。
- **隐藏属性推拉（P13）不受影响。** `Finale` 胜负同推道心、不套 `FailureRatio` ⇒ 扩大「胜」的定义不改变施加量。
- **经验（P14）不受影响。** Finale `ExperienceGrade` 取 `None` / `Minor` 是由「角色必须在进 Finale 前升满本境界」推出的硬约束，与胜负线无关。
- **`Source` / `SourceCode` / `x` 的口径不受影响**（R3 选 ① 时）。`x = count(SourceCode == FinaleWin)`，最低档通过发放的法则照常记 `FinaleWin`。
- **残卷防刷结构不受影响，且再次收紧。** 「每篇章至多累积一次或掷骰一次且二者互斥」在新判定下界更紧（累积面收窄到 `d < 0`）。
- **`chapterRetry` 字段形态 · Travel / `eventCountLimit` / location 继承 · 天劫 `diff = +1` 的自洽性推论 · `EncounterSpec` 七字段形状** —— 全部不受影响。
- **`answer-logs/` · `handoffs/` · `open-questions/update-log-archive.md`** —— 归档层，按库内约定不追改（含 `handoffs/2026-08-15d:114` 的「四重降三重」与 `handoffs/2026-08-17e:33,37` 的拧 `WinMargin` 举例）。**但 `handoffs/2026-08-17e` 的那两条已被 `plot-manager.md:58` / `combat/_index.md:58` 复述到活文档里，活文档那两处必须改（W15）。**
