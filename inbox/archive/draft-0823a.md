---
type: draft
date: 2026-08-23
topic: 数值哲学与平衡锚点（稀有度 · 层数 · 越级追分 · 动态定标）
targets: systems/balance.md · systems/character-profile/deck/ · systems/common-properties.md · decisions/ADR-0006 · vision/scope.md
status: distilled
reviewed: 2026-08-25 批量 interview 逐条裁决（见文末裁决记录）
distilled-to: handoffs/2026-08-25-numeric-philosophy-and-balance-anchors.md
---

# 定案草稿 — 数值哲学与平衡锚点

> 原始想法记于 2026-08-23，经 2026-08-24 设计讨论逐条裁决定案，2026-08-25 批量 interview 补齐三项未决口径。本文只含定案与其限定，无待评审项。

## 定案

### 1. 撤销专门的「数值标杆」session 计划，改为统计驱动的动态定标
`[用户拍板]` 不再安排 dedicated 数值标杆推演会话。具体数值标准在**内容量扩充到足以收集统计数据之后**由实测统计动态确定。前提是先立下第 4 条的形状锚点——**先定形状、后定数值**，避免无锚点堆内容导致事后整体重调。

**处理范围（08-25 裁定）：全面推翻 + 措辞中性化。**
- 直接改写 `decisions/ADR-0006-development-phase-order.md`（**Accepted**）的 §决策第 2 点、§理由第 3 条与 §备选方案的否决依据——后者原本正建立在「悬空数字已有既定的专场回归安排」之上，专场取消则该否决失去依据。按根约定就地改写，不新开取代 ADR。
- 改写 `vision/scope.md`「开发顺序」第 2 点与「悬空的数字按既定安排在 ch1 数值标杆专场统一回归」一句。
- 全库活文档中「归 ch1 数值标杆专场」一律机械替换为中性标签「**内容扩充后的统计校准**」，约 60 处（`systems/balance.md` 占 30 处，另散见 `mana.md` · `combat/_index.md` · `explore/_index.md` · `exchange/_index.md` · `research/_index.md` · `deck/_index.md` · `scoring.md` · `life-total.md` · `plot-manager.md` · `combat-service.md` · `future-event-service.md` · `travel/_index.md` · `enemies/_index.md` · `ADR-0018/0022/0025/0026` · `open-questions/` 各分片）。过程档案（`handoffs/` · `inbox/archive/` · `answer-logs/`）不回改，历史归 git。

### 2. 强度纵轴：层数是严格升级，稀有度是上限与复杂度
`[用户拍板 + 讨论限定]`
- **`TechniqueTier`（层数）越高 = 该功法整组卡牌严格更强**（层数提升 = 整组替换为更强的一版，既有定案，此处确认其强度语义）。
- **`RarityTier`（稀有度）提升的是强度上限与构筑复杂度，不是严格支配**：高稀有度功法的道念产出天花板更高，但往往带构筑条件（依赖特定次类型 / 埋伏配合 / 业障数量等）；低稀有度功法是无条件的稳定底盘。「一门稳定的低稀有度 + 一门 build-around 的高稀有度」应是真实的构筑决策。
- 否决的表述：「稀有度越高在任何构筑里都更强」——会使闭关（Research）选择趣味归零、低稀有度内容在后期沦为废纸。

### 3. `RarityTier` 落到 `CultivationTechnique`（功法整体标稀有度）
`[用户拍板]` 稀有度以**功法为单位**承载（挂功法 header），而非由组内各卡各自表达。

**这一条实为既有定案的确认，不是新增字段**：`systems/character-profile/deck/_index.md` 的功法承载形态已列 `Rarity`，且「功法必须有独立条目」的第一条理由就是「`Rarity` 无处可挂」；`research/common-properties.md` 的功法三选一与 `exchange/common-properties.md` 的 `CultivationTechnique` 族都已按 `RarityTier` 加权取池。本次的真实改动是**四处挂载清单的漂移修复**——`systems/common-properties.md`（挂载核对表 + `Rarity` 小节）· `terminology.md` · `systems/player-profile/player-power/_index.md` · `systems/services/combat-service.md`，均补上 `CultivationTechniqueData`；并给 `Rarity` 的消费点清单补第 ④ 条（功法的两处取池）。

**措辞收窄：** 原稿「置换候选过滤等按功法稀有度消费」需改写——置换只存在于能力族（`TryPickReplacement`），卡牌与功法都没有置换通道（`DeckChangeElement` 的五个 `Op` 里没有置换）。正确表述为「功法档的消费点 = 奖励 / 商店 / 闭关三选一的**抽取权重与过滤**」。

### 3b. 功法内成员卡的稀有度口径（08-25 裁定）
成员卡与游离散牌此前无任何字段可区分，而 Exchange 的 `Card` 族取池是 `CardData` 仓储全量（`Pool != Enemy`）——一门高层数功法的成员卡今天就能被商店当作单张散牌卖出，绕开功法档与「一个功法 = 一组必须整组入组的卡牌」这条构筑颗粒度。

**裁定：由功法引用派生排除。** 加载期以 `CultivationTechniqueData` 的每层卡牌 `Id` 列表反建索引，凡被任一功法引用的卡从**散牌产出侧**（Exchange `Card` 族取池 + 战后奖励池的 Card 部分）排除；抽取一律看功法档。
- `CardData.Rarity` **保持必填不变**，但成员卡的 `Rarity` **无规则消费点**（明写，不省略）。商店定价表是「商品族 × 稀有度」，功法族读功法档、卡牌族读卡牌档；把成员卡改成可空会给漏填开一个口子。
- 不新增字段：「这张卡是不是某功法的成员」已有唯一权威（功法侧的每层卡牌 `Id` 列表），再加一格就是制造第二权威，正是 `systems/common-properties.md` 硬边界所禁的形态。
- 配一条加载期 `PushWarning` 列出被排除的卡，使清单可人工审阅。
- 已知代价：「既想作成员卡、又想作散牌发」的牌无法表达。
- **散卡产出场景确实存在**（商店 `Card` 族 · 战后奖励 `RewardPoolId` · 业障），游离散牌保留卡牌级稀有度参与奖励池，这一侧不变。

### 4. 越级追分的形状锚点
`[用户拍板]` 更高级的功法产出更多道念，使低等级方可能追平或反超起始道念差。量化形状（调参靶心，非最终数值）：

> **一档 `TechniqueTier` 差带来的每回合道念产出期望差，在标准 10 回合内累计 ≈ 一档 `baseMomentum` 差。**

即：境界 / 等级鸿沟由 `baseMomentum` 起跑线承载，追分能力由功法产出承载，两个旋钮独立；「越一档追平一档」是内容数值成型后统计校准的目标形状。

**「一档」的口径（08-25 裁定）= 赋级带的一个 `diff` 档。** 境界中段同于相邻全局等级差，境界末两级跨境界时为 +5 / +13 / +25。依据：`baseMomentum` 在本库的唯一消费点就是赋级带产生的开局落差，锚点若不按赋级带的档计就没有可对账的对象；且该口径使「越阶只出现在境界末两级」这条既有推论直接成为追分难度的分布——`diff = +2` 的越阶遭遇需两档以上层数差才追得平，自动兑现既定的「追分可能，但很难，境界差越大越难」。

**「标准 10 回合」的口径：** 一场 `Standard` 档遭遇的整场（`TurnLimit = 10`，双方各 5 个己方回合），故「每回合产出期望差 × 10」实为**己方 5 次产出的累计差**——与 `balance.md` 全篇按「己方 5 个回合」推算牌流与资源线一致。

## 后果
- `systems/balance.md`：新增形状锚点小节；数值定标流程改为「内容量达标 → 统计 → 校准」；30 处专场措辞中性化。
- `systems/character-profile/deck/_index.md`：功法 `Rarity` 的语义成文（上限与复杂度、build-around vs 稳定底盘）；成员卡口径成文。
- `systems/common-properties.md`：`Rarity` 挂载清单补 `CultivationTechniqueData`，消费点补第 ④ 条，并明写成员卡本层无规则消费点。
- `terminology.md` · `player-power/_index.md` · `combat-service.md`：挂载清单同步。
- `systems/adventure-event/exchange/common-properties.md`：`Card` 族取池链补排除口径 + 加载期 `PushWarning`。
- `decisions/ADR-0006` · `vision/scope.md`：按第 1 条改写。

## 与既有决策的张力
- 第 1 条推翻 Accepted 的 `ADR-0006`，已由用户裁定全面推翻并中性化措辞。
- 第 3b 条的成员卡口径已裁定，不再是开放张力。

## 前置依赖
无。

## interview 裁决记录（2026-08-25 批量）

- **撤销 ch1 数值标杆专场，如何处理它推翻的 ADR 与全库措辞** → 全面推翻 + 措辞中性化（改写 ADR-0006 与 `vision/scope.md`，活文档约 60 处替换为「内容扩充后的统计校准」）。
- **锚点里「一档 `baseMomentum` 差」指哪一档** → 赋级带的一个 `diff` 档。
- **功法内成员卡的稀有度口径** → 由功法引用派生排除，`CardData.Rarity` 保持必填但成员卡无规则消费点。过程中确认散卡产出场景（商店 Card 族 / 战后奖励 / 业障）确实存在。
- 标准默认（未出题，直接采纳）：第 3 条为既有定案的确认而非新增字段；「置换候选过滤」措辞收窄为抽取权重与过滤；「高稀有度带构筑条件」不受「次类型清单归零」阻塞；锚点不被「功法层数上限」这条待答项阻塞。
