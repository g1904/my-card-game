---
type: solution-draft
date: 2026-09-06
question: 「`blind` / `ante` 缩放曲线」在本作的形态是什么——它是一条尚未设计的曲线，还是两个已被别的机制完全承载的 Balatro 借词？
source: open-questions.md「derive 就绪度」承重卡点 ③（`🔴 blind / ante 缩放曲线整体尚未陈述`）· open-questions/deferred-content.md:15 → systems/game-progression.md「blind / ante 缩放」小节 · systems/balance.md:826
targets: systems/game-progression.md · systems/balance.md · systems/_index.md · open-questions.md · open-questions/deferred-content.md
status: distilled
reviewed: 2026-09-06 批量评审定案 —— 待答项判定为占位残留整条撤销；`blind` 由 `combatTier` 完整承载、`ante` 用户裁决确认不设（含备选④ 轻量阶梯一并否决）；产出曲线登记表 + 两条分格轴纪律，登记 ADR 候选
distilled-to: handoffs/2026-09-06-blind-ante-scaling-curve.md
---

# 方案 — `blind` / `ante` 缩放曲线的形态

## 问题

`systems/game-progression.md` 有一节「blind / ante 缩放」，正文只有一句：

> blind / ante 的**要求、奖励与 scaling** 归本文档（进程侧）；缩放曲线为可调数值，存入 `.tres` 并归 `systems/balance.md`（ante 曲线）。**具体 blind 要求 / 奖励 / 缩放曲线尚未陈述**，见待决问题。

`systems/balance.md:826`、`open-questions/deferred-content.md:15`、`systems/_index.md` 的两行摘要各有一处同源措辞。
最近一次 `/assess-derive-readiness` 把它列为**全库三条承重卡点之一**，并标注「全库唯一『连形态都没有』的一条，不是取值缺口」，`/derive-requirements systems/game-progression.md`（队列第 17 步）因此带着一条排除面「排除 blind / ante（无形态）」。

**本草稿的结论是：这条待答项本身不成立。** `blind` 与 `ante` 是两个 Balatro 借词，本作对它们的处置早已分别定案——
`blind` 被 `combatTier` 三档**完整承载且已给出全部取值**；`ante` 在本作**没有对应物，且是被结构性否决的**。
那句「尚未陈述」是 2026-07-24 文档重构（`blinds-antes.md` 并入 `game-progression.md`，见该批 handoff 的迁移表）时原样搬过来的占位文本，此后各机制在别处逐条落定，占位句没有被清掉。

> **先例（同型、同日）：** `handoffs/2026-09-06-enemy-momentum-scaling-closure.md`——「敌人各等级的道念产出缩放曲线」同样被三份文档的 `## 待决问题` 登记为未定，直读后判定为落笔漏清的残留，整条删除。**本条与它是同一形态的第二例**：待决项的转发终点（`balance.md`）写着相反的结论。

## 约束（来自既有设计）

- **Balatro 的借鉴范围已被明文限定。** `vision/references.md:12`：借的是「**blind 的难度分档结构**——Practice / Combat / Finale 对位 small / big / boss blind，三档的回合数与胜负条件递进」，并明写「**借的是难度分档，不是出现节律**（Finale 只在篇章边界出现）」。
- **计分结构已明确否决 Balatro 形态。** `systems/scoring.md`「为何是道念而非 chips × mult」：道念是**双方对抗的相对量**，不是对抗一条静态阈值的绝对量；战斗不以任何阈值达标终止。
- **难度分工已定死：** 「全局等级序是一把简单的直尺，**跨境界有多难放进战斗数值里**」（`game-progression.md` 修行等级体系 · `balance.md` `baseMomentum` 表）。
- **敌人赋级 `±2` 是无例外的硬规则**，赋级函数不接受任何区间覆盖参数（`balance.md` · `ADR-0044`）。
- **平衡数值一律住平衡资源、经 `Content.Single<T>()` 取**，不硬编码（`ADR-0074` · `.claude/rules/data-resource-rules.md`）。
- **活文档只保留最新设计**，被取代的内容直接重写替换，不留考古（`.claude/rules/Context.md` 根约定）。

## 建议方案

### 一、`blind` 侧：已由 `combatTier` 完整承载，无缺口

`[既有推演]`

「blind 的要求与奖励」在本库的对应物是 `combatTier { Practice, Standard, Finale }` 的**遭遇参数与结算参数**，逐项都已落笔：

| 借词侧的问法 | 本作的承载 | 取值状态 | 权威 |
|---|---|---|---|
| blind 的「要求」（过关条件） | `EncounterSpec.TurnLimit` + `VictoryRule(WinMargin)` | **已定**：Practice 8 / 0 · Standard 10 / 1 · Finale 12 / 0 | `systems/adventure-event/combat/_index.md` · `balance.md`「`combatTier` 三档的遭遇参数」 |
| blind 的「出场条件」 | `Practice` / `Standard` 由类型权重掷出；`Finale` 的出现条件 = `level == 该境界末级`（全局序 13 / 17 / 21），以 `eventPriority = 1` 收窄整批 | **已定** | `game-progression.md` 推论 ② · `systems/services/future-event-service.md` |
| blind 的「难度缩放」 | 敌人赋级 = 角色等级 `±2` 带 + 带内权重；Finale 走指派值 `FinaleDiff`（三章初值恒 `+1`） | **已定**（含八条加载期校验） | `balance.md`「敌人赋级资源 `EnemyLevelingData`」 |
| blind 的「奖励」——可数量 | 支路 A：`baseReward` + 道念差 × `rewardPerMomentum[element]`（篇章单价 1 / ½ / ¼） | **已定** | `balance.md`「胜利侧道念差 → 奖励厚度」 |
| blind 的「奖励」——品质 | 支路 B：`advantage = 道念差 / max(1, 角色 baseMomentum)` → `Tier{Narrow, Solid, Crushing}` 选稀有度权重表，数量恒 3 | **形态已定**；各档权重取值待定 | 同上 · `systems/services/combat-service.md` |
| blind 的「档间奖励厚薄」 | 三档的 `BaseReward` / `RewardPoolId` 偏置 | **取值待定** | `scoring.md`「## 待决问题」· `balance.md`「战后奖励池权重」 |

**⇒ 缺口只剩最后两行，且两行都是取值、且都已在别处各自立有待答条目。** 本条不构成第三条独立缺口——它是那两条的重复登记。

**连带：`blind` 这个词在本库活文档里已经没有承载对象。** 它当前只出现在两处合法位置：`terminology.md` 与 `references.md` 的**对位注释**（说明「Practice 对位 small blind」这个借鉴来源），以及 `balance.md` 档位表的括注。建议保留这三处注释性用法，**其余位置（把 blind 当作一个本作实体来谈的地方）一律改写为 `combatTier`**。

### 二、`ante` 侧：本作无对应物，正式记为「不设」

`[既有推演]`

Balatro 的 ante 是「一个由三关 blind 组成、且逐 ante 抬高过关分数阈值的循环单位」。本作**这三个构成要件一个都不成立**：

1. **没有可被抬高的阈值。** 胜负是双方道念的相对比较，`chips × mult` 的「打分达标」结构已被明文否决（`scoring.md`）。ante 缩放曲线在 Balatro 里缩放的正是那条阈值——**本作没有那个被缩放的对象**。
2. **难度缩放是相对量、且自动跟随，不需要第二条绝对阶梯。** 敌人赋级恒落 `[角色等级 − 2, 角色等级 + 2]`，角色一升级敌人即跟随；「越往后越难」由 `baseMomentum` 跨度随境界放大（1→15→32→75→100）内生地兑现。再叠一条随进度递增的绝对阶梯 = 在唯一可见的难度刻度（等级）之外再开一条不可见的强度轴——这与 `ADR-0090`（层数不随赋级浮动）、`ADR-0044`（`±2` 无例外）被否决的是同一件事，且任何「按进度加压」的实现都必须产出带外 `diff`，直接撞硬规则。
3. **没有可对位的循环单位。** Balatro 的一个 ante = small → big → boss 固定节律 + 商店穿插；本作的进程是「location 串联 + 逐批择一」，`Finale` **只在篇章边界出现一次**且不绑 location，Practice / Standard 由类型权重掷出、无固定节律。`references.md:12` 已明写「借的是难度分档，不是出现节律」。

**推论：本作最接近 ante 的单位是「篇章（chapter）」**——它是三条已定曲线的分格轴（`lifeSpanCost` 定价表、`lossPerMomentum` / `rewardPerMomentum` 单价表、灵石 `S(c)`）。但它已经有名字、有权威、有载体，**不需要 `ante` 这个第二名字**；给它起别名只会在同一页上造出两义（与 `Tier` / `RarityTier` 不得复用同一枚举、`EnemyLevelRange` 刻意不叫 `LevelBand` 是同一条纪律）。

⇒ **定案：本作不设 ante 原语、也不设章内绝对难度阶梯**（2026-09-06 用户裁决确认），理由如上三条。采纳后在 `game-progression.md` 新小节里以一句正面陈述落笔（「本作不设 ante 式的章内绝对难度阶梯，缩放的分格轴只有全局等级与篇章两条」），并作为 **ADR 候选**登记——它是一条「否决某机制」的结构性决策，正是 ADR 的典型对象。难度缩放全部是相对量（敌人跟随角色等级）+ 篇章级量纲吸收；章内的推进感由**等级成长**（`baseMomentum` 上升 + 经验条常驻）与**越阶只出现在境界末两级**这两条既有机制承载。

### 三、「缩放曲线」的实体 = 一张既有曲线登记表 + 两条分格轴纪律

`[既有推演]`

问题措辞里的「缩放曲线」并非缺失，而是**分散在十处、从无一份总表**——这正是它读起来像「连形态都没有」的原因。建议把这一节改写成一张登记表（它就是本条的「形态」）：

| # | 曲线 | 分格轴 | 载体 | 权威 | 状态 |
|---|---|---|---|---|---|
| 1 | `baseMomentum`（战斗起跑线 · 强度主刻度） | **全局等级 1–22** | 平衡表 22 格 | `balance.md` | 已定，表已完整 |
| 2 | 敌人赋级带 + 带内权重 + `FinaleDiff` | **篇章**（三行，当前同值）× 相对 `diff` | `EnemyLevelingData` | `balance.md` | 已定（八条加载期校验） |
| 3 | `combatTier` 遭遇参数（`TurnLimit` / `WinMargin`） | **档**（三档） | `EncounterSpec` | `combat/_index.md` | 已定 8 / 10 / 12 · 0 / 1 / 0 |
| 4 | 负侧 `lossPerMomentum` | **篇章** | 平衡表 | `balance.md` | ch1 = 10 锁定；ch2 / ch3 候选 5 / 10 |
| 5 | 胜侧 `rewardPerMomentum`（支路 A 单价） | **篇章** × element | 平衡表 | `balance.md` | 已定 1 / ½ / ¼ |
| 6 | 胜侧 `advantage` 三档（支路 B） | 归一化道念差 | `Tier{Narrow,Solid,Crushing}` | `balance.md` | 形态已定；各档稀有度权重表待取值 |
| 7 | 灵石给予量 `S(c)` + `combatTier` 偏置 | **篇章** × 档 | 书写口径 | `balance.md` | 已定 15 / 35 / 60 · ×0.5 / ×2.0 |
| 8 | `lifeSpanCost` 21 格（`t × λ`） | **篇章** × 事件类型 | `LifeSpanCostTableData` | `balance.md` | 已定 |
| 9 | `experiencePoint` 阈值曲线 + `ExperienceGrade` 给予量 | **境界内递增 + 境界间重置量纲** | 平衡表 | `balance.md` · `game-progression.md` | 已定（ch1 合计 55 / ch2 114 / ch3 138） |
| 10 | `BatchSizeWeights` | **篇章** | 平衡表 | `balance.md` | 已定初值（三章同值） |
| 11 | `RealmBreakthroughManaBonus` | **境界边界**（单值 `+1`） | 平衡资源 | `balance.md` · `mana.md` | 形态已定，取值待校准 |

**两条分格轴纪律（这是本条真正可 derive 的产物）：**

> **本作的一切随进度变化的数值，分格轴只有两条：`①` 全局等级序（1–22，相对量、逐级）与 `②` 篇章（ch1 / ch2 / ch3，绝对量纲吸收）。**
> 新增任何缩放旋钮，其分格列必须是这两条之一；需要第三条轴（例如「章内进度」「已走过的 location 数」「已完成事件数」）时，**须先立 ADR**，因为那等于引入一条既有分工之外的难度轴。

`[通行做法]` 这条纪律的形式与本库已有的两条同型约束一致——「代码侧只读『当前篇章的那一行』，**不为分章写分支**」（赋级带 · `BatchSizeWeights` · 残卷分档三处逐字相同），本条只是把它从三处各写一遍上收为一条通则。

- **两条轴的分工可一句话说清：** 轴 ① 承载「谁比谁强」（相对，敌人跟随角色），轴 ② 承载「数字量纲膨胀多少」（绝对，吸收 `baseMomentum` 的百倍膨胀）。既有十一条曲线逐条都能归入其一，无例外——这是这条纪律不是臆造的证据。

### 四、措辞收口的逐处清单

`[通行做法]` 按「活文档只保留最新设计、直接重写替换」的根约定，采纳后应改的位置（**本草稿不改任何一处，由 `/analyze-new-ideas` 落笔**）：

| 位置 | 现状 | 建议改法 |
|---|---|---|
| `systems/game-progression.md:184-185`「### blind / ante 缩放」小节 | 整节只有一句占位 | **改写为「难度与数值缩放的分格轴」小节**：放上方登记表（或表的指路版 + 两条轴纪律），删除 `blind` / `ante` 两词 |
| `systems/game-progression.md:201` 待决问题条目 | 「blind / ante 缩放（未陈述）」 | **整条删除**（零信息损失：残余缺口是三档 `BaseReward` / `RewardPoolId` 与战后奖励池权重，两者已在 `scoring.md` / `balance.md` 各自登记） |
| `systems/game-progression.md:3` 抬头摘要 | 「…、blind / ante 缩放」 | 改为「…、难度与数值缩放的分格轴」 |
| `systems/balance.md:826` 待决问题条目 | 「blind / ante 缩放曲线…尚未陈述」 | **整条删除** |
| `systems/balance.md:3` 与 `:772` | 「ante 曲线」 | 改为「篇章 / 等级维度的缩放曲线」 |
| `systems/_index.md:13` · `:15` | 两行摘要各含 `ante` / `blind/ante` | 同上改写 |
| `open-questions.md`（就绪度小节承重卡点 ③ · 第 17 步排除面 · 最短解锁路径第 6 条） | 三处登记 | 撤条目（归 `/summarize-open-questions`）；第 17 步的排除面「排除…blind / ante（无形态）」随之删去 |
| `open-questions/deferred-content.md:15` | 「blind / ante 缩放曲线本身尚未陈述」 | 撤该半句，保留「平衡数值整体」那条 |
| `terminology.md:186-188` · `references.md:12` · `balance.md` 档位表括注 | Balatro 对位注释 | **保留不动**——它们是溯源注释，不是把 blind 当本作实体使用 |

> **行号漂移提示：** 就绪度小节引的是 `game-progression.md:181`，当前文件的实际落点是 `:184-185`（小节）与 `:201`（待决条目）；`:181` 现在是 `CurrentLocationId` 跨篇章持久的推论。落笔时按标题定位，勿按行号。

## 具体形态（可 derive 的落地面）

采纳后，`/derive-requirements systems/game-progression.md`（队列第 17 步）**可去掉「排除 blind / ante（无形态）」这条排除面**——不是因为补上了新机制，而是因为该面下没有任何待实现物。新增的可 derive 面为零：上表十一条曲线的载体、字段与加载期校验**全部已在各自权威文档中成文**，本条不新增任何字段、枚举、资源或校验。

唯一新增的是一条**编排 / 评审期纪律**（无运行期形态，与「负向 `OnFailureRules` 占比 ≤ 10%」「条目级偏移 ≈ ±15%」同档）：

- **落点：** `/audit-content` 无从检查（它检查条目，不检查文档新增的表），故本条**不进任何自动校验**，落在设计评审：新写一张按进度分格的数值表时，检查它的分格列是否为「全局等级」或「篇章」。
- **按「纪律的可执行化」阶梯，它落在第 4 级（零成本、零保证）** ——如实标注，不为它编造一个代理指标。

## 后果

- **`/assess-derive-readiness` 的承重卡点由三条降为两条**（剩 `status` × 拥有 / 失去的存档编码、战斗内容本体）。这不是就绪度提升的假象——第 17 步确实少一条排除面。
- **`systems/balance.md` 的待决问题由 14 条降为 13 条**；`game-progression.md` 的待决问题由 4 条降为 3 条。
- **不触碰任何存档 schema、字段、枚举或加载期校验** ⇒ 零迁移、零代码影响。
- **`ante` 一词从活文档中消失**（`terminology.md` 本就没有它的词条——已核实，那里只有 `blind` 作为三个 `combatTier` 的对位括注）。
- **代价如实写下：** 第三条分格轴（章内进度）从此需要一次 ADR 才能引入。若日后实测发现「一个篇章的中段太平」，补救手段被限定为**调既有曲线**（`BatchSizeWeights` / 赋级权重的剧本乘性调制 / `eventCountLimit` 序列），而不是加一条新阶梯。这正是本条想要的约束力，但它确实关掉了一条快速手段。

## 备选方案（已考虑并否决）

- **保留待答项、等内容阶段再答。** 否决：它不是取值缺口，等再久也不会有新输入；而它现在正**实际制造成本**——一条虚假的承重卡点会让每次就绪度评估重复报告它，并让第 17 步长期带一条空排除面。同型先例（敌人道念缩放）已按删除处理。
- **引入 `ante` 作为「篇章」的别名。** 否决：同页两义，与 `Tier` / `RarityTier`、`EnemyLevelRange` 不叫 `LevelBand` 的既有纪律正面冲突；且 `ante` 的原义含「阈值递增」，用作篇章别名会持续误导。
- **把登记表写进 `systems/balance.md` 而非 `game-progression.md`。** 否决：表中过半条目的**取值**确实归 `balance.md`，但表本身回答的是「进程如何变难 / 变大」这个进程侧问题，而 `game-progression.md` 的归属声明本就写着「要求、奖励与 scaling 归本文档（进程侧），缩放数值归 balance」——本方案维持这条既有分工，只是把「进程侧那一半」从占位句换成实表。
- **补一条「按进度递增」的轻量阶梯（真 ante 语义的最小版）。** 否决（用户裁决确认不设）。唯一不撞 `±2` 硬规则的形态是乘性调制带内权重（把 `+1` / `+2` 档权重按章内进度逐步上调后归一化），但它会引入第三条分格轴（章内进度）、让赋级从「不读角色在境界内的位置」变成要读，并与「篇章尾部变险由越阶规则单独承载」重复施压。只有当实测确认「章中段太平」且经验条补偿不够时才值得重提，届时按新增 ADR 处理。

## 与既有决策的张力

**无。** 本方案不与任何 Accepted ADR 冲突，反而是三份 ADR 的直接推论：`ADR-0044`（`±2` 赋级带无例外）· `ADR-0090`（层数逐条固定、不叠第二条强度曲线）· `ADR-0034`（全局等级序是一把直尺、难度放进数值）。

唯一需要点明的措辞层张力：`vision/references.md:12` 与 `terminology.md:186-188` 会保留 `blind` 一词。**这不是遗留而是有意**——它们是「借鉴来源」的溯源注释，删掉会丢掉「三档回合数递进为何是那个形状」的依据。判据：**注释里的 `blind` 指 Balatro 的东西，正文里的 `blind` 指本作的东西**；本方案只清后者。

## 前置依赖

**无——本条不依赖任何仍待答的问题，可独立采纳。** 逐条核实：

- 三档 `BaseReward` / `RewardPoolId` 厚薄取值 → 待定，但**已在 `scoring.md` 的 `## 待决问题` 独立登记**，删本条不会让它失去登记。
- 战后奖励池各档 `RarityTier` 权重 → 待定，**已在 `balance.md:816` 独立登记**。
- 卡牌产 / 削道念的量纲基准、`lossPerMomentum` ch2 / ch3 → 待定，**均已独立登记**，且都不影响本条的结构结论。

⇒ 「删掉这条会不会丢东西」的答案是**不会**：残余的三处缺口全部是取值，全部另有登记（与敌人道念缩放那次收口的核对方式一致）。

## 已知代价（随定案如实写下）

- 两条分格轴（全局等级序 · 篇章）成为硬纪律，第三条轴（章内进度）从此需要一次 ADR 才能引入。
- ch2 / ch3 中段的节奏缺口（`game-progression.md` 已明写：每 9–11 个事件才升一级、连续十几分钟无等级反馈）**只由经验进度条补一半**——维持现状、不因本条得到新的补救。
