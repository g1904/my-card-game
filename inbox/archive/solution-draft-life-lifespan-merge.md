---
type: solution-draft
date: 2026-08-29
question: 是否应把 lifeTotal（生命总量）与 lifeSpan（寿元）合并为同一个值——战斗失利直接扣减它、战斗胜利不回升？
source: inbox/draft-0829.md 第一条（用户提出的新想法；本议题在 open-questions/ 各分片中无对应条目，属全新提案）
targets: >
  systems/character-profile/life-total.md（整份退役，改写为 life-span.md）·
  systems/character-profile/_index.md（Status 字段表）·
  systems/services/life-cycle-service.md · systems/services/plot-manager.md ·
  systems/services/profile-service.md（ResourceElements 表）· systems/architecture.md（CostKey / DefeatReason）·
  systems/scoring.md · systems/balance.md · systems/game-progression.md ·
  systems/adventure-event/common-properties.md · systems/adventure-event/combat/_index.md ·
  systems/adventure-event/research/_index.md · terminology.md · program-overview.md ·
  ux/screen-flow.md · ux/combat-ux.md ·
  decisions/ADR-0004 · ADR-0016 · ADR-0018 · ADR-0022 · ADR-0025 · ADR-0031 · ADR-0045 · ADR-0066 · ADR-0076 ·
  open-questions/01-combat.md · 03-adventure-event-types.md · 04-hidden-attributes-plot.md ·
  06-meta-progression.md · deferred-content.md
status: distilled
reviewed: 2026-08-29 批量评审取形态 A（合并 + 显性化）· 两处支柱级松动接受；2026-08-30 合并 interview 另裁 8 题（Explore 泄漏由定价结构堵死 · 接受失败螺旋 · **删除 Research 的 `Recuperate`** · 六条依据失效的权威一律保结论改理由 · 删 `ChapterLifeSpanBudget` 字段 · 寿元不常驻战斗屏 · 不补偿跨档叙事文案 · `lossPerMomentum` 一维 + 形状锚）
distilled-to: handoffs/2026-08-30-life-lifespan-merge.md
---

# 方案草稿 — 合并 lifeTotal 与 lifeSpan

## 问题

本作当前有**两条各自独立、且各自都能终结角色**的资源线：

| | `lifeSpan`（寿元） | `lifeTotal`（生命总量） |
|---|---|---|
| 语义 | 寿命预算 —— **按事件流逝** | 战斗外耐久 —— **按失败流逝** |
| 量纲 | 炼气起始 **100**，抵达筑基 +100 / 金丹 +300 / 元婴 +500；剩余跨篇章结转 | 境界基线 **10 / 25 / 40**（进入该境界时一次性跃升），无上限字段 |
| 扣减 | 每个 AdventureEvent 按 `lifeSpanCost` 扣（`selectCost` 的唯一 element） | 只在战斗 / 修炼失败的收口时刻按道念差 **1:1** 扣 |
| 回复 | outcome 侧三条通道（回寿事件 / 补天丹 / 商店购入），`ChangeElement(CostKey.LifeSpan, +n)` | AdventureEvent 的 reward，含 Research 的 `Recuperate` 槽内操作 |
| 可见性 | **隐藏属性**，三档表门控：Band 0（>30%）完全无提示 · Band 1（10–30%）跨档定性叙事 · Band 2（<10%）标红精确倒数 | **明文**，常驻 EventOption 选择界面的角色状态条（`❤10`） |
| 归 0 | `DefeatReason.LifeSpanExhausted`（大限将至） | `DefeatReason.LifeTotalExhausted` |

提案是把这两个值**合并为同一个值**：战斗失利直接扣减它，战斗胜利不会让它回升。提案人给出的预期是「平衡难度略微上升，但系统与玩家的理解成本大幅下降」。

悬着的不是某个字段怎么填，而是一条**结构性分工**是否应当推翻——`systems/character-profile/life-total.md` 把它写成承重句：「二者分工清晰：**寿元按事件流逝，lifeTotal 按失败流逝**」，`handoffs/2026-08-22-combat-defeat-consequences.md` 把它称为「**两条独立终结路径**」。

**检索结论：本方案在本库中从未被提出过，也从未被否决过。** `answer-logs/` 全量检索无「两条资源线是否重复 / 是否该合并」的问答记录；它是一个全新议题，但它**正面推翻多条已固化决策**（见「与既有决策的张力」）。

## 约束（来自既有设计）

- **`ADR-0031`（Accepted）：** 寿元是按境界递增授予、按 `lifeSpanCost` 递减的预算，归 0 即终结；**「篇章时长的调参入口唯一 = `lifeSpanCost` 定价表，预算四格不参与调参」**。
- **`ADR-0045`（Accepted）：** `lifeTotalLimit` 概念整体删除，只跟踪单值、无上限截断；境界跃升 = 给 `lifeTotal` 加一笔。
- **`ADR-0018`（Accepted）：** 道念差 → `lifeTotal` 损失 = **1:1，中间不隔一层映射**；理由是「战斗屏上『我落后 8 点』同时就是『输了要掉 8 点』，账当场可算，无需额外教学」。**不设上限截断。**
- **`ADR-0016`（Accepted）：** 隐藏属性档位模型 —— 道心 5 档 / 煞气 4 档 / **寿元 3 档（阈值 30% / 10%，分母 = `Status.ChapterLifeSpanBudget`）**，共 12 档；一张表统一六个消费方（eventOptions 调制 · 剧情线触发 · 跨档叙事 · 寿元红字标注 · `selectCost` 精确展示 · 回寿数字展示）。
- **`ADR-0066`（Accepted）：** `selectCost` 内 `LifeSpan` 取值域收紧为非负，**寿元回复只走 outcome / reward 侧**；护栏是三道软闸 + 一条 Travel 禁令，不设硬上限。
- **`ADR-0076`（Accepted）：** `Practice` / `Standard` 失败**不另加规则层后果**——依据正是「失败已有**六条**代价」，其中 ① 扣 `lifeTotal`、② 已付 `lifeSpanCost` 打水漂是**两条不同的账**。
- **`ADR-0025` / `ADR-0004`：** `DefeatReason` **恰四值** `{ Discarded, LifeSpanExhausted, LifeTotalExhausted, FinaleFailed }`；前三为资源触底、由 `ResourceElements` 表驱动，末一为篇章闸门、走唯一一条显式旁路。
- **`vision/pillars.md`「基调与手感」：** 「如手游 **Reigns** 般的**属性平衡求生张力**——玩家在**多重相互竞争的压力之间权衡**，而非最大化某一个数值。」
- **`systems/adventure-event/common-properties.md`（承重）：** 「『省着花有跨篇章回报』这条策略性回报在 Band 0 / Band 1 **不可被精细执行**……**这正是取向本身**」——即「寿元预算不可被电子表格化优化」是一条**主动选择**，不是疏漏。
- **工程前提：** 软件开发尚未开始（0 行代码、0 份 FR、`requirements/` 台账为空），故本方案的**存档迁移成本为零**，纯属设计层重构。

## 利弊评估与结论

### 结论：**有条件采纳（推荐）**——概念方向是对的，但它不是一处字段合并，而是一次牵动九条已固化决策的重构；且它的收益**只在合并值同时显性化时才兑现**。

#### 好处（真实存在，逐条可验）

1. **心智模型真的塌缩了一层。** 现状要求玩家理解「两条命 + 两种死法 + 两套呈现（一个明文一个隐藏）+ 两套回复通道」。合并后是「一条命，两个消耗来源（走路要花、打输要花），一个回复口」。这正是提案人说的 way easier to understand，且判断成立。
2. **战斗与非战斗事件第一次被定价在同一把尺子上。** 合并后「打一场输了 = 花掉三到五个事件的时间」是可跨类型比价的——玩家能把「这场硬仗」和「那次闭关」放在同一个天平上。现状做不到：`lifeTotal` 和 `lifeSpan` 是两个不可通约的量。**这是本方案最大的、也是最容易被低估的收益。**
3. **消掉一整类困惑边界。** 现状允许出现「寿元还剩 80、耐久归 0 → 死」这种「明明还有大把时间却死了」的局面，反之亦然。合并后不存在。
4. **境界跃升从两笔变一笔。** 现状进筑基要同时执行「寿元 +100」与「`lifeTotal` 10 → 25 的跃升」；后者的载体在 `life-total.md`（写作「**置值**跃升」）与 `ResourceElements`（`AllowedOps = Add`，`profile-service.md` 明写「无置值通道」）之间本就有一处措辞张力——合并后这条跃升整体退役，张力顺带消失。
5. **`ADR-0045` 的境界基线公式 `ceil(1.1 × 最坏开局落差)` 及其「已知风险」段落整体作废。** 它存在的全部目的是保证「一次惨败不打穿耐久」；合并后分母从 10 变成 100+，该保证自动且过度成立，**规则层的一处精算负债被删除**。
6. **叙事更贴题材。** grimdark 仙侠语境下「受伤即折寿」比「耐久条」通顺得多；`pillars.md` 第 6 条与之同向。
7. **结构净减：** `CostKey` 少一格 · `ResourceElements` 少一行 · `DefeatReason` 四值 → 三值 · `Status` 少一格 · 主题文档少一份。**零迁移成本**（未开工）。

#### 坏处（同样真实，其中两条是硬伤）

1. **「多重相互竞争的压力」少一组 —— 这是与 `pillars.md` 的正面冲突。** Reigns 的张力恰恰来自数值互相牵制；把两条正交压力线焊成一条，是往支柱的反方向走。现状的「时间紧但还能打」vs「时间宽裕但输不起」两种局面，合并后塌缩为单一的「还剩多少」。
2. **`Research` 的篝火式二选一被改写。** `life-total.md` 明写回复类事件「是『寿元 vs lifeTotal』两条资源线**互相兑换的接口**（花寿元买回耐久）」；`ADR-0022` 把 `Recuperate` 与 `UpgradeTechnique` 同槽并列，正是 StS 篝火那个玩家真会犹豫的选择。合并后它变成「花寿元换寿元」。
   - **但这条没有想象中严重（重要澄清）：** `ADR-0066` 的软闸 ① 已明写「回寿事件照常付 `selectCost` ⇒ **净收益恒小于回寿量**」。故合并后 `Recuperate` 仍然成立，只是语义从「补血 vs 升级」锐化为「**续命 vs 变强**」的直接对赌——在 grimdark 语境下这是**更好的**选择题，不是更差的。
3. **篇章时长反推从算术题退回分布问题（承重 · 这是最实质的平衡代价）。** `balance.md` 明写「`eventCountLimit` 恒为定值 ⇒ **一章的事件总数可枚举**，故时长反推是一道算术题而非按期望值取的估算」。合并后战斗失败扣减（道念差，随机变量）直接吃同一份预算 ⇒ 一个篇章的实际长度重新变成随机变量，且 `ADR-0031` 的「时长调参入口唯一」当场失效。**平衡难度的上升幅度高于提案人预期的「a little」**，这是本方案最该被知情接受的一条。
4. **`ADR-0076` 的六条代价变五条，且论证前提被改写。** 该 ADR 回应的正是「失败看起来单薄」，其依据是「代价确实有六条，只是分散在五份文档里」。合并把 ① 与 ② 折成同一条账 ⇒ **失败面在纸面上更单薄了**，与 ADR 的方向相反。
5. **可见性两难（决定性的一条，见下）。**

#### 可见性两难 —— 本方案的成败落点

`lifeSpan` 隐藏、`lifeTotal` 明文。合并后必须二选一：

- **若合并值保持隐藏**（Band 0 完全无提示）：玩家既看不见余量、也看不见战斗失败扣了多少 ⇒ **战斗前无法为风险定价**，而 `ADR-0076` 六条代价里最重的那条彻底不可感知。这比现状**更难理解**，与提案初衷正相反。**故此路不通。**
- **若合并值显性化**：提案的可理解性收益全额兑现，但代价是寿元**退出隐藏属性体系**——`ADR-0016` 从 12 档减到 9 档、隐藏属性从三项减为两项（道心 / 煞气）、两段式告警与六个 Band 消费方中的三个（红字标注 · `selectCost` 精确展示 · 回寿数字展示）整体退役、`plot-manager.md` 明写的「频次序 = 寿元（每章必来 · 压力计时器）> 煞气 / 道心」被砍掉最频繁的那一根（寿元 ≈ 4–6 条 / 轮回，占跨档叙事总量 6–10 条的一半以上），且 `common-properties.md` 那条「不可被电子表格化优化 —— **这正是取向本身**」被反转。

**推荐取显性化。** 判据：提案的**唯一目的**是降低理解成本；隐藏形态不兑现该目的，故若不接受显性化，正确的动作是**不做这次合并**，而不是做一个隐藏的合并。

## 建议方案

### 一 · 合并的方向：`lifeTotal` 被 `lifeSpan` 吸收，不是反过来
`[既有推演]`

保留 **`lifeSpan` / 寿元**为合并后的定名，删除 `lifeTotal` / 生命总量。依据三条，全部来自量纲与结构承载：

- **量纲承载在寿元侧。** `lifeSpanCost` 定价表明写「每格是一个**非负整数定值**」（`ADR-0031` · `common-properties.md`）。若取 `lifeTotal` 的 10 / 25 / 40 量纲，定价表必须落到小数位，直接推翻该形态。
- **结构承载在寿元侧。** 寿元是 `selectCost` 的唯一 element、是跨篇章结转的主体、是 `ChapterLifeSpanBudget` 的分子；`lifeTotal` 只有一个扣减点和一个回复口。
- **中文定名在仙侠语境下「寿元」优于「生命总量」**，且 `terminology.md` 已把后者标注为「**非 life**」的对照项——对照项消失后该行本就要重写。

### 二 · 量纲与换算：起步保持 1:1，逐篇章系数留作旋钮
`[既有推演]`

**合并值的量纲直接沿用寿元预算表**（炼气起始 100 / 抵达筑基 +100 / 金丹 +300 / 元婴 +500，剩余跨篇章结转）；`lifeTotal` 的 10 / 25 / 40 境界基线整体删除。

对「道念差 1:1 扣减在新量纲下是否失效」的核算——**结论是它没有失效，量级意外地合适**：

| 篇章 | 带内最坏开局落差（`balance.md`） | 本章预算（含结转估算） | 占比 | 折合事件数（按均价反推） |
|---|---|---|---|---|
| ch1 炼气 | 9 | 100 | **9%** | ≈ 3 个事件 |
| ch2 筑基 | 23 | 100 + 结转（≈110–120） | **≈ 20%** | ≈ 3–4 个事件 |
| ch3 金丹 | 35 | 300 + 结转（≈320–330） | **≈ 11%** | ≈ 5 个事件 |

- 对照 `balance.md` 的回寿三档（小 5% / 中 10% / 大 20%）：**一次最惨的失败 ≈ 一颗中档到大档补天丹**。这是一个自洽的量级关系，不是勉强凑上的。
- 落到玩家语言就是一句话：「**输一场，白走三到五步。**」建议把它作为本方案的设计标语写进主题文档——它同时兑现好处 2（跨类型比价）。
- **`baseMomentum` 的量纲膨胀（1 → 100，约 100 倍）远快于预算膨胀（100 → 300，3 倍）**，故 1:1 在后两章会逐渐偏重。既有做法已给出现成对策：胜侧的强制奖励单价 `rewardPerMomentum` 就是**逐篇章下调以吸收量纲膨胀**的（`scoring.md` · `balance.md`）。**建议负侧对称地引入 `lossPerMomentum` 逐篇章系数表**，与胜侧单价表同住 `balance.md`、同形态。
- **建议 ch1 的系数锁定为 1**：`ADR-0018` 那条「落后 8 点 = 掉 8 点、当场可算、无需额外教学」的价值在教学期最高，而 ch1 正是 MVP 范围。ch2 / ch3 由系数吸收膨胀。

### 三 · 可见性：合并值明文常驻，寿元退出隐藏属性体系
`[取向选择]`（推荐显性化 —— 见「利弊评估」的两难分析与「仍需用户决定」第 2 项）

推荐形态：

- 合并值**明文常驻 EventOption 选择界面的角色状态条**，沿用 `lifeTotal` 现有的 `❤` 位（`ux/screen-flow.md` 的角色状态条一行）。
- `selectCost` **恒精确展示**，删除 Band 门控三行表；回寿数字同理恒精确。
- **两段式告警（30% 定性叙事 / 10% 红字倒数）退役**——余量本身已经可见，告警只剩「快没了」这一层，由**红字变色**承担即可，不需要一条独立的叙事通道。
- `HiddenStat` 枚举去掉 `LifeSpan`，隐藏属性收敛为 **道心 / 煞气** 两项；`ADR-0016` 的 12 档 → 9 档，有文案的档从 4 个（道心 +2 · 煞气 3 · 寿元 1 · 寿元 2）减到 2 个。
- `Status.LifeSpanBand` 字段删除；**`ChapterLifeSpanBudget` 保留**——它仍是回寿量三档「占本章预算百分比」标定口径的分母（`balance.md`），只是不再充当 Band 阈值的分母。

### 四 · 「胜利不回升」：现状本就如此，零改动
`[既有推演]`

提案里「won't increase it even if won」这一句**在现状下已经成立**，合并后原样继承：`systems/scoring.md` 的三档结算产物表明写「**胜 → lifeTotal 不变**」，`lifeTotal` 从来就不因战斗胜利回复。

- **必须写清它的射程：它只约束战斗结算侧，不禁 outcome 侧的回复。** 否则会与 `ADR-0066`（回寿三通道 A / B / C）正面冲突。
- 建议措辞：「**战斗结算只会向下推这个值，永不向上；向上只由事件产出与道具承担。**」

### 五 · 回复通道：三条原样继承，`Recuperate` 改口径
`[既有推演]`

- `ADR-0066` 的 A（回寿事件产出）/ B（补天丹类法宝）/ C（商店购入 B）**三条通道原样保留**，共用施加路径 `ChangeElement(CostKey.LifeSpan, +n)`。
- `ADR-0022` 的 `Recuperate` 从「回复 `lifeTotal`」改为「回复 `lifeSpan`」，与补天丹**并入同一条施加路径**——`common-properties.md` 现有的「它与 Research 的 `Recuperate` 是两个量」一句整体删除。
- 三道软闸 + Travel 禁令原样有效，且软闸 ① 在合并后**更强**（回寿事件本身要付 `selectCost`，而那笔现在与战斗损失同源）。

### 六 · modifier 耦合：接受「延寿类修正同时减轻两类损耗」，并明写
`[既有推演]` + 一条代价明写

`ElementSpec.CostModifier` 是**按 `CostKey` 配的**，作用于该 key 上所有 `BaseValue < 0` 的施加。现状 `LifeSpan` 行的 `CostModifier = ModifierKey.LifeSpanCost`，`LifeTotal` 行两个修正列**均为 `null`**（`profile-service.md` 明写「无既定修正意图」）。

合并后，**战斗失败扣减会自动经过 `ModifierKey.LifeSpanCost`** ——一条「事件消耗 −20%」的法则将同时减轻 20% 的战斗失败惩罚。

- **建议接受，不拆。** 三条理由：① modifier 载体是账号级法则 / 神通，本就稀缺，且 `profile-service.md` 已对该行写下「按缺省豁免、日后确需时加一行即可」的保守纪律；② 拆成两个 `CostKey` 就等于没合并；③ 叙事上「延寿」同时减轻两类损耗是通顺的。
- **但必须在 `ResourceElements` 的 `LifeSpan` 行依据列写下这句代价**，否则它会成为一个只有在数值失控时才被发现的隐性耦合。
- **明确不做的两条：** 不为战斗损失另开 `ModifierKey`（那是把一个 key 拆成两个）；不给 `LifeSpan` 开 `Set` op（`profile-service.md` 明写「开 `Set` 即给内容一条绕过 `LifeSpanCost` 修正的路」，该禁令原样成立）。

### 七 · 终态与判定链路：纯机械收缩，零新增
`[既有推演]`

- `DefeatReason` 四值 → **三值** `{ Discarded, LifeSpanExhausted, FinaleFailed }`。
- `ResourceElements` 删 `LifeTotal` 行；`CostKey` 删 `LifeTotal` 成员；`Status` 删 `lifeTotal` 字段。
- **表驱动的终态判定完全不受影响**——`life-cycle-service.md` 的判定伪码本就是遍历 `ResourceElements` 中 `DepletionDefeat != null` 的行；删一行即少一个终态资源，正是该结构设计时预期的可扩展方向（「新增一个终态资源 = 表里加一行 + `DefeatReason` 加一个成员」，反向同理）。
- **`ADR-0025` 的 Finale 显式旁路原样保留**，且它「表驱动被开的唯一一个口子」这条描述不变。
- **`ADR-0025` 的「借道 `LifeTotalExhausted` 被否决」一段整体作废**（该成员已不存在），但其结论（Finale 失败走独立的 `FinaleFailed`）不变。

### 八 · 主题文档落点：`life-total.md` 退役，新建 `life-span.md`
`[既有推演]`

合并后寿元**同时是**资源字段与（曾经的）隐藏属性，而它当前没有自己的主题文档——权威散在 `plot-manager.md`（隐藏属性侧）与 `life-cycle-service.md`（预算与终态侧）。显性化后它不再属于 `plot-manager` 的辖区。

- **`systems/character-profile/life-total.md` → 重写为 `systems/character-profile/life-span.md`**，承载：定名 · 预算表与结转 · 两个扣减来源 · 回复三通道 · 归 0 终态 · 无上限 · 呈现位置。
- `systems/_index.md` 的文件夹图例同改；`plot-manager.md` 的寿元段落收缩为一条回链。

## 具体形态（可 derive 的落地面）

### 字段面（`CharacterProfile.Status`）

| 字段 | 变更 | 类型 | 写入通道 | 取值域权威 |
|---|---|---|---|---|
| `lifeSpan` | **保留**（吸收 `lifeTotal` 的语义） | `int` | `Elements`（`CostKey.LifeSpan`） | `ResourceElements` |
| `lifeTotal` | **删除** | — | — | — |
| `LifeSpanBand` | **删除**（显性化后无 Band） | — | — | — |
| `ChapterLifeSpanBudget` | **保留**（回寿量百分比标定的分母） | `int` | `StatusChanges` | `StatusFields` |

### `ResourceElements` 表的两行变更

```
LifeSpan   → (Min 0, Max null, DefeatReason.LifeSpanExhausted, CostModifier: ModifierKey.LifeSpanCost, GainModifier: null, AllowedOps: Add)
             ⚠ 依据列追加：本行的 CostModifier 现同时作用于「事件消耗」与「战斗失败扣减」两个来源；
               一条「延寿类」法则会同时减轻两者，已知并接受，见 ADR-<新>。
LifeTotal  → 整行删除
```

### 枚举收缩

```csharp
public enum DefeatReason { Discarded, LifeSpanExhausted, FinaleFailed }   // 四值 → 三值
// CostKey    删除成员 LifeTotal（轮回层由 8 项减为 7 项）
// HiddenStat 由 { Faith, Bloodlust, LifeSpan } 收缩为 { Faith, Bloodlust }
```

### 平衡面（`systems/balance.md`）

| 条目 | 变更 |
|---|---|
| 寿元预算表 100 / +100 / +300 / +500 | **不变**（它现在是全部的命） |
| `lifeTotal` 境界基线 10 / 25 / 40 + `ceil(1.1 × 最坏落差)` 公式 | **整段删除** |
| `lifeSpanCost` 定价表（事件类型 × 篇章） | **形态不变**；反推口径追加一项「战斗失败的期望扣减」（见前置依赖） |
| **新增** `lossPerMomentum`（篇章 × 系数） | ch1 = **1**（锁定，保 `ADR-0018` 的当场可算）；ch2 / ch3 待反推。与胜侧 `rewardPerMomentum` 同住、同形态 |
| 回寿量三档（5% / 10% / 20%） | **形态保留**，标定口径不变（分母仍是 `ChapterLifeSpanBudget`）；三档的手感描述须重写（不再有 Band 可跨） |

### 呈现面（`ux/`）

| 位置 | 变更 |
|---|---|
| EventOption 角色状态条 | 沿用 `❤` 位显示合并值精确余量；低于 10% 转红字（保留视觉强调，删除叙事通道） |
| `selectCost` 展示 | **恒精确展示**，删除 Band 0 / 1 / 2 三行门控表 |
| 回寿收益标注 / 道具描述 / 结算面板寿元行 | **恒精确展示**，删除同一开关的三处门控 |
| 战斗屏 | `ux/combat-ux.md` 的待决问题「lifeTotal 是否常驻战斗屏」**自动答结**：合并值不进战斗屏（沿用「寿元红字倒数不进战斗内」的既定纪律），但结算面板必须如实展示本次扣减量 |
| 死亡屏 | `open-questions/06-meta-progression.md` 的「四条路径观感差别很大」收窄为**三条**，该待答项难度下降 |

## 后果

- **文档面：** 上方 `targets` 列出的 16 份主题文档 + 9 份 ADR + 5 份 open-questions 分片。其中 **`ADR-0045` 整份失效**（其结论被合并吸收），**`ADR-0018` / `ADR-0031` / `ADR-0016` / `ADR-0076` 需实质改写**，其余为引用句级修订。
- **存档 schema：** `Status` 少两格（`lifeTotal` · `LifeSpanBand`）。**无迁移成本**——0 行代码、`requirements/` 台账为空。
- **derive 就绪度连带失效：** `open-questions.md` 判定表中 `life-cycle-service.md` · `balance.md` · `scoring.md` · `plot-manager.md` · `research/_index.md` 五份的「就绪切片」描述均点名了 `lifeTotal` 或寿元条款，本方案采纳后须由一次 `/assess-derive-readiness` 全量重估。**本方案不评估就绪度。**
- **后端：** 零影响（已核实 `backend-design-documents/contracts/` 内 `defeatReason` 零登记；`characterProfile` 的资源字段目前不在透明字段表内）。若日后把合并值提进透明档，`open-questions/cross-boundary.md` 第 26 行的钳制语义预警照旧适用。
- **不采纳的后果：** 现状**没有已知缺陷**，两条线各自自洽、六个消费方齐备。不采纳的成本仅是维持当前的理解门槛。
- **与 `solution-draft-affinity-and-technique-attributes.md` 的写入面交叠（同批评审已核对）：** 两份都改 `systems/balance.md`。该草稿的初版曾把「灵根造成的层数差」钳制在本方案将要删除的 `lifeTotal` 境界基线的「±1 档」前提上；**同批裁决已把它改为硬性修习准入、不再折减层数**，故那条依赖**已解除**，两份互不掣肘。仍建议**提炼时同批**处理 `balance.md`，避免两次改写打架。

## 备选方案（已考虑并否决）

- **合并但保持隐藏（提案原文的字面读法）** — 否决：玩家既看不见余量也看不见失败代价，比现状更难理解，与提案初衷相反。详见「可见性两难」。
- **合并为 `lifeTotal` 的量纲（10 / 25 / 40）** — 否决：`lifeSpanCost` 定价表明写每格是非负整数定值，10 点量纲要求定价落到小数位。
- **保留 `lifeTotal` 之名吸收寿元** — 否决：量纲与结构承载都在寿元侧；且「生命总量」在仙侠语境下弱于「寿元」。
- **不合并，只在 UI 上把两个值并成一屏** — 否决：两个数、两种死法的心智负担来自**规则**不来自**布局**，改呈现不解决提案要解决的问题。
- **合并后把战斗失败扣减拆成独立的 `CostKey` 以隔离 modifier** — 否决：那在存档与施加链路上就是没合并，只是换了个说法。
- **给战斗失败扣减设上限截断以稳住时长反推** — 否决：`ADR-0018` 明写「不设上限截断，1:1 就是全部规则」；且截断会让「一次惨败」失去分量。正确的旋钮是 `lossPerMomentum` 系数（建议方案二）。
- **合并后给寿元设 `Max` 上界** — 预先驳回：`ADR-0066` 已明写「加上界会引出『补满时用丹浪费』这一整类挫败感，而 `lifeTotal` 那条线正是专门不设上限来消掉它的」。合并后该理由**双倍成立**。

## 与既有决策的张力

| # | 冲突的决策 | 冲突点 | 为什么需要它松动 | 松动的代价 | 不松动时的替代 |
|---|---|---|---|---|---|
| 1 | **`ADR-0031`**：篇章时长的调参入口**唯一** = `lifeSpanCost` 定价表 | 合并后战斗失败成为第二个消耗面，且是随机变量 | 合并的定义就是「两个来源吃同一份预算」 | 时长反推从算术题变分布问题；`balance.md` 的「事件总数可枚举 ⇒ 反推是算术」一段须改写 | 给战斗扣减设硬上限（与 `ADR-0018` 直接冲突）或不合并 |
| 2 | **`ADR-0018`**：道念差 → 损失 **1:1，中间不隔一层映射** | 后两章量纲膨胀（`baseMomentum` 100 倍 vs 预算 3 倍）需要系数吸收 | 不吸收则 ch3 的一次惨败占比失控 | 「当场可算」在 ch2 / ch3 变成「乘一个已知系数后可算」 | **建议的折中：ch1 系数锁定为 1**，教学期原样保住；胜侧 `rewardPerMomentum` 早有同款先例，非对称已存在 |
| 3 | **`ADR-0016`** + **`vision/pillars.md`「Reigns 式多重压力权衡」** | 寿元退出隐藏属性（3 项 → 2 项，12 档 → 9 档，文案档 4 → 2） | 合并的收益只在显性化时兑现 | 隐藏属性体系失去频次最高的一根（寿元 ≈ 4–6 条 / 轮回，占跨档叙事总量一半以上）；`pillars.md` 那句须微调 | 保持隐藏（则见「可见性两难」，收益不兑现） |
| 4 | **`common-properties.md`（承重）**：「省着花的策略性回报在 Band 0/1 不可被精细执行——**这正是取向本身**」 | 显性化后玩家可以电子表格化优化整章寿元预算 | 同上 | 一条明写为「取向本身」的纪律被反转；它与「eventOption 不标注经验数字」是同族纪律，反转一个会让另一个显得任意 | 同上 |
| 5 | **`ADR-0076`**：失败**六条**代价，故不另加后果 | ① 与 ② 折成同一条账 → 五条 | 合并的必然推论 | 该 ADR 的核心论证（「代价确实有六条，只是分散」）须重写为五条；失败面在纸面上更单薄 | 无——只能重写论证；但结论（不另加后果）仍然成立 |
| 6 | **`ADR-0045`** | 整份 ADR 的对象消失 | 同上 | 无实质代价：其「无上限截断」结论原样继承给寿元（`profile-service.md` 已明写寿元不设 `Max`）；mana 非对称的理由段落须迁移到 `life-span.md` | 无 |
| 7 | **`ADR-0004`**：`defeated` 原因**恰四种** | → 三种 | 同上 | 纯措辞；`ADR-0025` 的「唯一旁路」描述不变 | 无 |
| 8 | **`ADR-0022`** / `research/_index.md`：`Recuperate` 回 `lifeTotal`、与 `UpgradeTechnique` 同槽的篝火张力 | 变成「花寿元换寿元」 | 同上 | 见「坏处 2」——实际张力**变锐**（续命 vs 变强），但既有论证句须重写 | 无 |
| 9 | **`life-total.md`（承重句）**：「寿元按事件流逝，lifeTotal 按失败流逝」；`handoffs/2026-08-22-combat-defeat-consequences.md`：「**两条独立终结路径**」 | 分工本身被取消 | 这就是提案要做的事 | 全库对「为什么要两条线」的**唯一一处系统性正面论述**整体作废 | 无 |

> **⚠ 张力 9 是本方案的核心债务。** 它不是引用句修订——它是本库唯一一处正面论证「两条线各自的必要性」的地方。采纳本方案意味着**明确地判定该论证不再成立**，理由是「可通约的单一压力尺 + 更低的理解成本」高于「两条正交压力线」。这一判定权在用户，不在本草稿。

## 前置依赖

以下待答项在答定前，本方案的**数值部分无法定稿**（形态部分不受影响）：

- **`lifeSpanCost` 定价表的逐格取值**（`open-questions/04-hidden-attributes-plot.md` · `balance.md` 待决）——它决定「一个事件值多少点」，进而决定「9 点 = 几个事件」这条设计标语是否成立。
- **卡牌产 / 削道念的量纲基准**（`open-questions/deferred-content.md` · `scoring.md` 待决，已明确推迟到内容横向扩展阶段）——它决定**典型**道念差是多少。上表的 9 / 23 / 35 是**最坏开局落差**，而 `balance.md` 明写「最终道念差可能大于开局落差」；`lossPerMomentum` 的 ch2 / ch3 初值反推不出来，除非先有典型道念差的分布。
- **回寿量的绝对点数**（`balance.md` 待决）——合并后它同时承担原 `Recuperate` 的职能，三档取值须一并重估。
- **`experiencePoint` 阈值曲线与产出分布**（`open-questions/06-meta-progression.md`，明写「与寿元预算互相约束、必须一同反推」）——合并后预算多了一个随机消耗面，这条互相约束**变紧**，两者更必须同批反推。
- **三档 `BaseReward` / `RewardPoolId` 取值**（`scoring.md` 待决）——负侧改了换算，胜侧厚度须同批校准以维持胜负两侧的对称。

**本方案不为上述任一项臆造数值。** 建议方案二的 `lossPerMomentum` 只给出**形态与 ch1 = 1 这一个锚**，ch2 / ch3 留空待反推。

## 仍需用户决定

1. **是否采纳合并，取哪一形态？**
   - **A（推荐）· 合并 + 显性化** —— 合并值明文常驻，寿元退出隐藏属性体系。收益全额兑现（心智塌缩 · 跨类型比价 · 少一份精算负债），代价是张力 1 / 3 / 4 / 5 / 9 全部要处理，且篇章时长反推变成分布问题。
   - **B · 不合并，维持现状** —— 零成本；理解门槛维持现状。**现状没有已知缺陷**，这是一个完全体面的选项。
   - **C · 合并但保持隐藏（提案原文的字面读法）** —— **不推荐**：玩家既看不见余量也看不见失败代价，比现状更难理解，与提案初衷正相反。
   - **推荐 A。** 理由：提案指出的问题（两条命 + 两种死法 + 两套呈现）是真实的理解成本，而 A 是唯一真正解决它的形态；平衡难度的上升是可控的（`lossPerMomentum` 是一个现成形态的旋钮，胜侧已有同款），且当前**零代码零 FR**，是做这种结构性重构成本最低的时刻——再往后每一份 FR 都会抬高它。
   - **→ 已裁决（2026-08-29 · 批量评审）：取 A —— 合并 + 显性化。** 上文九条张力全部按「需要它松动」处理；`lossPerMomentum` 按建议方案二落形态（ch1 = 1，ch2 / ch3 待反推）。

2. **若取 A：是否接受寿元退出隐藏属性体系所带来的两处支柱级松动？**
   - ① `vision/pillars.md`「Reigns 式**多重相互竞争的压力**之间权衡」—— 隐藏属性由三项减为两项，压力线由两条并为一条。
   - ② `common-properties.md` 那条明写为「**这正是取向本身**」的纪律 —— 寿元预算从此**可被电子表格化优化**（玩家能精确规划整章开销）。它与「eventOption 不标注经验产出数字」是同族纪律，反转其一会让另一条显得任意。
   - **推荐接受。** 理由：这两条纪律保护的是「粗略感知下的求生张力」，而合并后压力尺变成一条**可通约、可跨事件类型比价**的尺——玩家能算清楚，但要算的东西从「两条互不通约的线」变成「一条线上的取舍」，**决策的深度不降、只是从模糊变清晰**；而模糊本身不是本作的支柱（`pillars.md` 第 7 条「直觉化系统 · OUT：一上来就是一堵规则墙」与之同向）。若不接受，正确的动作是取 B 而非 C。
   - **→ 已裁决（2026-08-29 · 批量评审）：两条都接受。** ① `pillars.md` 的「多重相互竞争的压力」一句按压力线由两条并为一条改写；② `common-properties.md` 那条「不可被电子表格化优化 —— 这正是取向本身」的纪律**反转**，寿元预算从此可被玩家精确规划。提炼时须同批处理与它同族的「eventOption 不标注经验产出数字」那条，说明两者为何不再同向。
