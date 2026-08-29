# 数值哲学与平衡锚点：形状先于数值

- id: 2026-08-25-numeric-philosophy-and-balance-anchors
- date: 2026-08-25
- topic: systems/balance.md · systems/character-profile/deck/ · systems/common-properties.md · systems/services/combat-service.md · systems/adventure-event/exchange/ · decisions/ADR-0006 · vision/scope.md
- status: distilled
- distilled-to: `systems/balance.md`、`systems/character-profile/deck/_index.md`、`deck/common-properties.md`、`systems/character-profile/mana.md`、`life-total.md`、`item/_index.md`、`systems/common-properties.md`、`terminology.md`、`systems/player-profile/player-power/_index.md`、`systems/services/combat-service.md`、`services/plot-manager.md`、`services/future-event-service.md`、`systems/scoring.md`、`systems/enemies/_index.md`、`systems/adventure-event/exchange/common-properties.md`、`exchange/_index.md`、`combat/_index.md`、`explore/_index.md`、`research/_index.md`、`travel/_index.md`、`adventure-event/common-properties.md`、`decisions/ADR-0006-development-phase-order.md`、`vision/scope.md`、`decisions/ADR-0018`、`ADR-0022`、`ADR-0025`、`ADR-0026`

## Intent（distilled）

**一句话：** 撤销「先开一场专门会议把数值定死」的安排，改为**先立形状锚点、后由实测统计定值**；同时把功法的两条强度纵轴与成员卡的产出边界写成规则。

### 1. 数值定标：先定形状，后定数值

不再安排专门的数值标杆推演会话。具体数值标准在**内容量扩充到足以收集统计数据、且游戏可运行之后，由实测统计动态确定**，落开发路线第 ③ 阶段「平衡与体验」；第 ② 阶段只铺内容与形状锚点。

前提是先立下形状锚点——**避免无锚点堆内容导致事后整体重调**。定标流程因此是：内容量达标 → 游戏可运行 → 实测统计 → 校准。

此举推翻了 `ADR-0006` 中「先开一场专门的『ch1 数值标杆』session 定全部数值标杆」这条安排，该 ADR 已就地改写（第 ② 阶段不再承诺定数值，只留形状锚点）；其 §备选方案中「中断设计先落最小可跑回路」的否决**继续成立**，只是否决依据换成了「悬空数字的回归依赖内容铺开后的统计样本，一个提前拼凑的最小回路给不出可据以定标的样本量」。全库活文档中指向该安排的措辞统一中性化为「**内容扩充后的统计校准**」。

### 2. 强度纵轴有两条，语义不同

- **层数 `TechniqueTier` 是严格升级**——层数提升即把该功法整组卡牌替换为更强的一版，同一门功法的高层在任何构筑里都强于低层。
- **稀有度 `RarityTier` 提升的是强度上限与构筑复杂度，不是严格支配**——高稀有度功法的道念产出天花板更高，但往往带构筑条件（依赖特定次类型 / 埋伏配合 / 业障数量等）；低稀有度功法是**无条件的稳定底盘**。

**「一门稳定的低稀有度 + 一门 build-around 的高稀有度」必须是一个真实的构筑决策。** 若稀有度做成「任何构筑里都更强」的单调支配，闭关三选一与商店的功法档就退化为「选档位最高的那个」，选择趣味归零，且低稀有度内容在后期沦为废纸。

### 3. `RarityTier` 以功法为单位承载

稀有度挂 `CultivationTechnique` header，而非由组内各卡各自表达。**这是既有定案的确认，不是新增字段**——功法的承载形态早已列 `Rarity`，且「功法必须有独立条目」的第一条理由正是「`Rarity` 无处可挂」。本次的实际改动是**挂载清单的漂移修复**（五个落点补上 `CultivationTechniqueData`）与**消费点清单补第 ④ 条**。

**功法档的消费点 = 战后奖励池 · 商店 `CultivationTechnique` 族库存 · 闭关（Research）功法三选一（含开局构筑强制事件）的抽取权重与过滤。** 置换不在其列——置换通道只存在于能力族，卡牌与功法都没有置换算子。

**战后奖励池由此扩为三类混合**（`CardData` / `ItemData` / `CultivationTechniqueData`）。它不需要任何新结构：`CombatResult.Spoils` 本就是一份完整的 `ProfileChangeSpec`，其 `DeckElements` 已能承载 `DeckChangeElement(LearnTechnique, id, Tier = 1)`，与商店买下一门功法产出的 element 逐字同构。候选中出现已持有的功法则排除、不折算为升阶（与闭关三选一同处置）；玩家选中即整组入组。

### 3b. 功法内成员卡不进散牌产出侧

成员卡与游离散牌此前无任何字段可区分，而商店 `Card` 族的取池是 `CardData` 仓储全量——一门高层数功法的成员卡今天就能被当作单张散牌卖出，绕开功法档与「一个功法 = 一组必须整组入组的卡牌」这条构筑颗粒度。

**处置：由功法引用派生排除。** 加载期以 `CultivationTechniqueData` 每层的卡牌 `Id` 列表反建成员索引，**凡被任一功法引用的卡一律不进散牌产出侧的抽取池**——商店 `Card` 族、战后奖励池的 `Card` 部分、以及任何走池抽的 `AddLooseCard` 产出，套的是同一份索引。玩家取得整组成员卡的唯一通道是功法本身。

- **不新增字段。**「这张卡是不是某功法的成员」已有唯一权威（功法侧的每层卡牌 `Id` 列表）；在 `CardData` 上再加一格即两份表各自漂移，而本库没有机制发现它们不一致。
- **索引的输入取全量口径**（`AllIncludingDisabled()`），不取 `AllEnabled()`：成员关系是结构而非抽取池，按抽取池反建会让一门被 flags 关闭的功法把整组成员卡放进散牌池，而 flags 按账号解析 ⇒ 不同账号看到不同的散牌池。
- **排除不替代 `AllEnabled()`**，两者取交集。
- **`CardData.Rarity` 保持必填，但成员卡的这一格无规则消费点**（明写）：定价表按「商品族 × 稀有度」索引，功法族读功法档、卡牌族读卡牌档；改成可空会给漏填开一个口子。
- 配一条加载期 `PushWarning` 列出被排除的卡，使清单可人工审阅。
- **已知代价：**「既想作成员卡、又想作散牌发」的牌无法表达——这是为构筑颗粒度不被单张散牌绕开而接受的对价。
- 游离散牌保留卡牌级稀有度，照常参与商店 `Card` 族与奖励池，这一侧不变。

> 功法作为**独立族**进战后奖励池（见第 3 条）与成员卡从 **`Card` 部分**排除是两条互不矛盾的规则：功法不是散牌。

### 4. 越级追分的形状锚点

更高层数的功法产出更多道念，使低等级方可能追平或反超起始道念差。量化形状（调参靶心，非最终数值）：

> **一档 `TechniqueTier` 差带来的每回合道念产出期望差，在标准 10 回合内累计 ≈ 一档 `diff` 的 `baseMomentum` 落差。**

- **粒度 = 整副卡组整体高一档。** 标定目标是「卡组内每门功法都高一档」时的累计差。开局底盘为 3 门功法，故追分需整体升级；单门功法高一档不构成该产出差。
- **「一档」= 赋级带的一个 `diff` 档**，其落差 = 自角色等级起连续 n 步 `baseMomentum` 增量之和。境界中段同于相邻全局等级差；境界巅峰级 `diff = +1` 跨境界为 +5 / +13 / +25，倒数第二级 `diff = +2` 跨境界为 8 / 17 / 35。
  依据：**「等级差 → 开局落差」的唯一产生通道**是赋级带的 `diff`，锚点若不按赋级带的档计就没有可对账的对象；且该口径使「越阶只出现在境界末两级」这条既有推论直接成为追分难度的分布——`diff = +2` 的越阶遭遇需两档以上层数差才追得平，自动兑现「追分可能，但很难，境界差越大越难」。
- **「标准 10 回合」= 一场 `Standard` 档遭遇的整场**（`TurnLimit = 10`，双方各 5 个己方回合），故「每回合产出期望差 × 10」实为**己方 5 次产出的累计差**——与 `balance.md` 全篇按「己方 5 个回合」推算牌流与资源线一致。
- **两个旋钮独立**：境界 / 等级鸿沟由 `baseMomentum` 起跑线承载，追分能力由功法产出承载。

## Clarifications（interview 产物）

本次为批量运行，五个分片并行校验后合并出题，用户逐条裁决：

- **锚点里「一档 `TechniqueTier` 差」的作用粒度** → **整副卡组整体高一档**。细化了原始输入未言明的粒度；单门读法会把追分门槛降为约 1/3，与既有定案「追分可能但很难」冲突，也使原稿自写的「两档以上层数差」失去依据。
- **功法 `Rarity` 的消费点范围** → **三处，战后奖励池也能开出功法**。推翻了原始输入 §3 自述的「功法的两处取池」，取其「奖励 / 商店 / 闭关三选一」那一句为准；连带把战后奖励池扩为三类混合。
- **「统计」的来源** → **实测统计**，落开发路线第 ③ 阶段。原始输入同一句中「实测统计」与「内容量扩充」两种指向并存，此裁决取前者，并与 `vision/scope.md`「相当一部分精算结论在第一次跑起来之前无法证伪」闭合。
- **`open-questions.md`「derive 就绪度」小节内的措辞** → **一次性例外，允许纯标签替换，判定文字一字不动**。该小节通常由 `/assess-derive-readiness` 独占写入；本次只换等待对象的名字，不触碰任何就绪度结论。

**事实订正（核实后按正确事实落笔，非用户裁决）：**

- 原稿「境界末两级跨境界时为 +5 / +13 / +25」的数字定位有误——这三个数是**境界巅峰级 + `diff = +1`** 那一步的落差；倒数第二级以 `diff = +2` 跨境界时是 8 / 17 / 35。已按正确通式书写，用户裁定的口径本身不受影响。
- 原稿「`baseMomentum` 在本库的唯一消费点就是赋级带产生的开局落差」不成立（另有 `advantage` 归一化分母、战斗内法则上沿刻度、`lifeTotal` 境界基线公式、胜侧单价表逐章下调）。已收窄为「**『等级差 → 开局落差』的唯一产生通道**是赋级带的 `diff`」，理由照旧承重。
- 原稿「置换候选过滤等按功法稀有度消费」为错述——置换只存在于能力族，卡牌与功法都无置换通道。已收窄为「抽取权重与过滤」。
- 原稿估「约 60 处」措辞替换偏低：活文档实测 77 处、待答清单侧 28 处，且该安排在库中有 ≥6 个字面变体。范围以实测为准。

## Open questions

- **`OutcomeRule(DeckOperation, AddLooseCard, TargetId = 空)` 的「对应的池」在本库无定义**，且业障作为负向奖励从一个通用卡牌池抽讲不通。这是既有空白，非本次引入；本次以「散牌产出侧」通则措辞绕过，未填。

Source: `inbox/archive/draft-0823a.md`
