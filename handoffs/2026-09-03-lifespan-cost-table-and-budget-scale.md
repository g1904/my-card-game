# 寿元定价表 21 格、预算量纲 ×10 与三个旋钮的联合反推

- id: 2026-09-03-lifespan-cost-table-and-budget-scale
- date: 2026-09-03
- topic: systems/balance.md · systems/character-profile/life-span.md · systems/game-progression.md · systems/adventure-event/* · systems/scoring.md · ux/* · decisions/ADR-0018 · ADR-0031 · ADR-0044 · ADR-0045 · ADR-0066 · ADR-0109 · ADR-0127
- status: distilled
- distilled-to: systems/balance.md, systems/character-profile/life-span.md, systems/character-profile/_index.md, systems/game-progression.md, systems/scoring.md, systems/adventure-event/common-properties.md, systems/adventure-event/combat/_index.md, systems/adventure-event/explore/_index.md, systems/adventure-event/research/_index.md, systems/adventure-event/travel/_index.md, systems/services/life-cycle-service.md, systems/services/future-event-service.md, systems/services/combat-service.md, systems/services/profile-service.md, terminology.md, vision/scope.md, ux/screen-flow.md, ux/combat-ux.md, decisions/ADR-0018-momentum-scoring-model.md, decisions/ADR-0031-lifespan-budget-countdown.md, decisions/ADR-0044-enemy-leveling-band.md, decisions/ADR-0045-life-span-single-value.md, decisions/ADR-0066-lifespan-gain-outcome-side-only.md, decisions/ADR-0109-lifespan-cost-fixed-value.md, decisions/ADR-0127-life-merged-into-lifespan.md

## Intent（distilled）

### 一、定价的形状：`lifeSpanCost = round(t(type) × λ(chapter))`

`lifeSpanCost` 在本库里只有一个职责——控制篇章时长。由此直接得出定价必须**正比于玩家实际耗时**：若某类事件时间贵而寿元便宜，它的单位时间价就低于其他类型，最优策略变成尽量只选它，篇章时长随之爆表，而旋钮精度是这张表存在的唯一理由。**耗时正比是唯一不产生套利的定价形状**，它同时把三条各自论证过的既定相对关系统一为一条式子（Research 最贵 ⟸ 闭关最慢 · Travel 最便宜 ⟸ 结算是毫秒级 · Combat 三档分别给值 ⟸ 8 / 10 / 12 是三个不同的 `t`）。

`t(type)` 是一张**标定台账**，住 `systems/balance.md`，**不进任何 `Resource`**：`Practice` 2.0 · `Standard` 2.5 · `Finale` 3.0 · `Research` 2.8 · `Explore` 1.6 · `Exchange` 1.0 · `Travel` 0.4（分钟）。Explore 一行按整个条目池的**真身分布期望**标定，产出仍是与任何具体真身无关的常数。

### 二、量纲：寿元预算四格整体 ×10

预算四格改为 **1000 / +1000 / +3000 / +5000**。理由是**分辨率**：百点级预算 ÷ 约 25 个事件 = 单价 2–7 点，整数粒度即 14%–50%，七行里四行在 ch1 → ch2 之间完全无法体现「逐篇章略微上调」，逐格取整误差累积到篇章总支出的 ±10%，与旋钮本身的调节幅度同量级。结构零改动——仍是非负整数单值、无上限、无截断。

**放大发生在 λ 层，不是把已取整的格子字面 ×10。** 字面 ×10 会让 ch1 → ch2 的变化率一位不改，量纲改动买的唯一东西（分辨率）当场落空。λ = **23 / 25 / 63**，21 格 = `round(t × λ)`，**半值四舍五入向上**（`62.5 → 63`）。

### 三、λ 的反推式（三个旋钮联立）

```
B_c = 篇章增量_c + 上章结转 C_{c-1}
S_c = λ_c × T_c
F_c = 常规战斗场数 × 败率 × E[道念差] × lossPerMomentum_c
C_c = B_c + R_c − F_c − S_c   （须 ≥ 0）
⇒ λ_c = ( B_c + R_c − F_c − C_c ) / T_c
```

八个输入连同两个**待实测校准的标定假设**（败率 20% · `E[道念差]`）全部落进 `systems/balance.md`，使 21 格可复算——重定价时改 λ 或改 `t`，表自动重算。ch1 收支校验：25 批次 / 39.3 分钟 / 支出 904 / `C1` = 136。

### 四、结转是 ch2 的必要预算构成（承重发现）

不计结转时 `λ_2` 不高于 `λ_1`，「ch2 略微上调」这条既定取向**从未经过算术检验**。它成立的唯一通道是结转：`C1 ≳ 140`（约 15% 的 ch1 预算）。推论：跨篇章结转从「省着花有回报」升级为「ch2 的预算构成」；把 ch1 花到只剩个位数的玩家在 ch2 面对结构性偏紧的预算——这是被接受的失败面，但必须是**有意的**，**不留作暗账**。

### 五、`lossPerMomentum` 随量纲同步 ×10

道念量纲不变而寿元 ×10 ⇒ 若系数留在 1，一次带内最坏失败从预算的 9% 掉到 0.9%，形状锚「一次最坏落差的失败恒落本章可用预算的 8%–12%」当场破，失败惩罚在 ch1 事实上归零。故三章取 **10 / 5 / 10**（ch2 沿用分数记法「1 / 2 点」的 ×10 形态）。形状锚逐格校验：9×10/1000 = 9% · 23×5/1150 = 10.0% · 35×10/3100 = 11.3%。

### 六、ch1 经验阈值曲线下调

事件数由 26–30 下修至 ≈ 25 后，ch1 的经验供给 62 对旧需求 79 只有 0.78，远低于既定验收 1.15–1.20。**阈值曲线本就是由事件数倒推的从属量**，上游被改、下游跟着重算是正解。ch1 合计 **79 → 55**：`threshold(L) = 4 + floor((L−1)/8)`（L = 1..11），L = 12 特例取 8（+3 的收尾台阶，与 `baseMomentum` 表「第十三层跳到 15」同构）。曲线的下界被「单次给予量 ≤ 该境界最小阈值」钉在 4，故只能靠拉长同值段变平。`baseMomentum` / 炼气 13 层 / ch2 · ch3 阈值全不动。

### 七、载体与校验

`LifeSpanCostTableData` 独立成一份 `ISingletonContent`（三个具名篇章字段 + 行类型 `LifeSpanCostRow : Resource` 的七个 `[Export] int`），**不并入 `CombatRulesData`**——消费者不同、且后者可被 `EncounterSpec` 覆写而本表不接受任何覆写参数，覆写纪律相反。三条加载期校验：任一格 < 0 → `PushError`；某章 `Travel == 0` → `PushError`；`Travel` 越出 `Exchange` 的 1/3 ~ 1/2 → `PushWarning`。

## Clarifications（interview 产物）

- **21 格的执行口径 → λ 层重算，不是把已取整的格子字面 ×10。** 推翻草稿裁决行「21 格定价表与相关标定值按本稿自陈原样 ×10」的字面口径：那会使 ch1 → ch2 的变化率一位不改，量纲改动的唯一收益落空。λ = 23 / 25 / 63，21 格 = `round(t × λ)`；ch1 支出 904、`C1 = 136`。
- **半值取整方向 → 四舍五入向上**（`62.5 → 63`）。草稿未指定，不写死则文档与实现会各取一半。
- **`lossPerMomentum` ch1 由 1 改为 10 → 用户确认推翻 `ADR-0018` 与 `ADR-0127` 正文里「锁定为 1 · 落后 8 点 = 掉 8 点当场可算」这条明写论证。** 两份 ADR 就地改写。**论证强度下降如实写出**：可算性由 1:1 变为 ×10（「落后 8 点 = 掉 80 点」，仍属心算可及）。草稿完全没有提到 `lossPerMomentum`。
- **ch1 经验缺口 → 下调阈值曲线**（79 → 55），不是提高阈值。**草稿引用的收口方向是反的**——它引的那条既定收口（「提高 ch1 阈值 + 降低覆盖率」）针对的是升级感太廉价（供给过剩），本次是供给不足。
- **「Travel = 常规事件基准的 1/3 ~ 1/2」的分母 → 取 `Exchange` 行并在两处写死**，不再留「常规事件基准」这个未定指代。判据：该纪律的目的是堵零成本 reroll，绑住最便宜的常规行才是紧的那一边；拟增校验本就以 `Exchange` 为分母。
- **λ 反推式的 8 个输入 → 全部写进 `balance.md`**，败率 20% 与 `E[道念差]` 两格显式标注「待实测校准的标定假设，不是设计结论」。取向依据：活文档须独立可读，且既定做法是把标定做成可算的校验表而非死记数字。
- **「Research 最高」→ 采纳收窄解读「在玩家可自由比价的行之间最高」**，同批改写 `game-progression.md` 的括号注**与 `research/_index.md` 的「全类型最贵一档」**。草稿只点名了前者；后者是走火入魔风险档「承重、不可省」这条论证的前提，不改写即留下一条前提已伪的承重论证。替代项（把 ch3 Research 抬到 ≥ 189）要求 `t(Research) ≥ 3.0`，与耗时驱动的定价形状正面相抵。
- **预算四格 → 1000 / +1000 / +3000 / +5000**（草稿取向 ① 选项 A，原样生效）。
- **压力曲线 → ch2 依赖结转维持「略微上调」（`C1 ≈ 150`）· ch3 算术中性**（草稿取向 ② 选项 A）。「结转是 ch2 的必要预算构成」须在设计库明写、不留暗账。
- **张力 ① → 放松耗时估值**（三条超定估算里唯一无论证支撑的一条）：混合均值上修至 ≈ 1.57、ch1 事件数下修至 ≈ 25。
- **量纲 ×10 的范围纪律 → 只订正活文档。** `handoffs/` · `answer-logs/` · `inbox/archive/` · `open-questions/update-log*.md` 是过程档案，其中的旧数值一律保留原值。

**自行推演的标准默认（不占 interview）：**

- `E[道念差]` · 最坏落差 9 / 23 / 35 · `baseMomentum` 表 · `rewardPerMomentum` 单价表 · 回寿三档的 5% / 10% / 20% · 「余量 < 本章预算 10% 转红字」——**一律不 ×10**（道念量或百分比，与寿元量纲无关）。回寿的**绝对点数** ×10（ch1 50 / 100 / 200）。
- **条目级偏移幅度按 ≈ ±15% 在新表上重算为 ±7 / ±8 / ±19**，不是把「±1」×10。草稿「ch1 / ch2 单位太粗、多数条目不填」那句论证随分辨率提升而失效，落笔时删去。
- **`LifeSpanCostTableData` 照 `EnemyLevelingData` 范式用三个具名篇章字段**，不用长度 3 的索引数组。
- **`Research ≥ Standard` 只作 `/audit-content` 汇总，不进加载期校验**（它依赖可比价作用域的读法）。
- **「设计期按真身分布期望标定 ≠ 运行期按真身取价」的区分必须写进 `explore/_index.md`**，否则 Explore 行唯一有依据的定法会被该文既有纪律否掉。
- **`vision/scope.md` 的预算列举漏了 `+500`**，×10 订正时顺手补齐为四格。
- **「落差 9 ≈ 9%」是 ch1 预算恰为 100 的巧合等式**（`预算 ÷ 系数 = 100`），措辞改写为正面陈述，避免读者当作规律。
- **示例数字随量纲更新**（措辞失真，不是设计改动）：「耗 3 点」→ 30 · 「`1` = 消耗 1 点」→ 10 · 「一条 `+8` 的扣减量」→ +80 · 「花 4 点的总是打架」→ 40 · 「倒赚 20 寿元」→ 200 · 「先扣 8 到 0、再扣 3」→ 80 / 30 · 状态条 `❤92` → `❤920`。
- **`int32` 无溢出风险**（三章合计上限 9000 量级），存档 / 同步字节预算不受影响。
- **一轮回的场次口径随事件数下修一并重算**：战斗场数 30–36 → 约 23、事件总数 86–102 → 约 84；`IgnoresProtection` 与跨档叙事密度两处换算随之更新。

## Open questions

- **`lossPerMomentum` 的 ch2 / ch3 定案。** 形状锚已解出候选值 5 / 10，定案仍待「典型道念差的实际分布」。
- **回寿量三档的绝对点数与每章回寿事件次数。** 本次只给按百分比的折算（ch1 50 / 100 / 200），不构成定案。
- **λ 反推式里的两个标定假设**（熟练玩家败率 20% · `E[道念差]`）只能靠可玩版本实测；败率翻倍即 `F_c` 翻倍。
- **卡牌的道念产 / 削量纲基准**——它同时阻塞 `E[道念差]` 与上面两条。
- **ch1 的供给 / 需求当前落在 1.13**，略低于 1.15–1.20 的目标区间（差约 2%，在参考构成的浮动内）。收口在实测校准时随 λ、构成与曲线一并处理。
- **ch2 / ch3 的 `eventCountLimit` 取值与途经 location 数**（ch1 已有反推产出：4–5 个 location × 容量 4–5）。
- **走火入魔风险档候选的出现权重。**

## Notes / triage

- 输入：`inbox/solution-draft-lifespan-cost-chapter-tiers.md`（`status: decided`，用户已在批量评审中裁定两个取向与张力 ① 的处置）。
- 草稿只点名了四处波及面（`ADR-0031` / `ADR-0045` / `balance.md` / `life-span.md`）；实际活文档波及 **21 份、60 余处**。三处最危险的遗漏：`lossPerMomentum` 的九处 · `ADR-0127` 的三处 · `research/_index.md` 的「全类型最贵一档」。
