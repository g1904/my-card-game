# lifeTotal 与 lifeSpan 合并为单一寿元 + 显性化

- id: 2026-08-30-life-lifespan-merge
- date: 2026-08-30
- topic: systems/character-profile/life-span · systems/scoring · systems/balance · systems/services/plot-manager · systems/services/profile-service · ux/screen-flow · decisions/ADR-0016 · ADR-0018 · ADR-0022 · ADR-0031 · ADR-0045 · ADR-0076 · ADR-0081
- status: distilled
- distilled-to: systems/character-profile/life-span.md、systems/character-profile/_index.md、systems/services/life-cycle-service.md、systems/services/profile-service.md、systems/services/plot-manager.md、systems/services/combat-service.md、systems/services/future-event-service.md、systems/architecture.md、systems/scoring.md、systems/balance.md、systems/game-progression.md、systems/_index.md、systems/enemies/_index.md、systems/adventure-event/common-properties.md、systems/adventure-event/combat/_index.md、systems/adventure-event/combat/common-properties.md、systems/adventure-event/research/_index.md、systems/adventure-event/explore/_index.md、systems/character-profile/item/_index.md、systems/character-profile/mana.md、systems/character-profile/power/_index.md、systems/player-profile/player-power/_index.md、terminology.md、program-overview.md、ux/screen-flow.md、ux/combat-ux.md、ux/error-and-blocking-ux.md、vision/pillars.md、vision/references.md、vision/scope.md、decisions/ADR-0004、ADR-0016、ADR-0018、ADR-0022、ADR-0025、ADR-0031、ADR-0034、ADR-0044、ADR-0045、ADR-0063、ADR-0064、ADR-0066、ADR-0076、ADR-0081、ADR-0109

## Intent（distilled）

**一句话：** 把 `lifeTotal`（生命总量 · 明文 · 战斗失败按道念差 1:1 扣减）整体并入 `lifeSpan`（寿元 · 隐藏 · 按事件 `lifeSpanCost` 扣减），保留寿元的定名与量纲，并把合并后的值**显性化**——明文常驻、恒精确展示、退出隐藏属性体系。

### 1. 合并的方向：`lifeTotal` 被 `lifeSpan` 吸收

保留 **`lifeSpan` / 寿元**为合并后的定名，删除 `lifeTotal` / 生命总量。依据三条：

- **量纲承载在寿元侧。** `lifeSpanCost` 定价表的每格是一个定值、表中不设区间列，表值与覆盖值一律非负；若取 `lifeTotal` 的 10 / 25 / 40 量纲，定价表必须落到小数位。
- **结构承载在寿元侧。** 寿元是 `selectCost` 的唯一 element、是跨篇章结转的主体；`lifeTotal` 只有一个扣减点和一个回复口。
- **中文定名在仙侠语境下「寿元」优于「生命总量」。**

### 2. 量纲与换算

- 合并值的量纲**直接沿用寿元预算表**（炼气起始 100 / 抵达筑基 +100 / 金丹 +300 / 元婴 +500，剩余跨篇章结转）；`lifeTotal` 的 10 / 25 / 40 境界基线与 `ceil(1.1 × 最坏落差)` 公式整段删除。
- **新增 `lossPerMomentum`（篇章 × 系数）**，与胜侧 `rewardPerMomentum` 同住 `balance.md`、同形态。**ch1 = 1 锁定**；ch2 / ch3 待反推，先框一个**形状锚**（「一次最坏失败恒落在本章预算的 8%–12%」），写法对齐既有的「越级追分形状锚点（是形状不是取值）」。
- **一维（篇章），不加 `combatTier` 第二维**：`Practice` 的轻量化继续由 `TurnLimit` / `WinMargin` / `ExperienceGrade` 三个既有旋钮承担。
- 量级校核：ch1 最坏落差 9 / 预算 100 ≈ 9%；ch2 23 / ≈115 ≈ 20%；ch3 35 / ≈325 ≈ 11%。对照回寿三档（小 5% / 中 10% / 大 20%），**一次最惨的失败 ≈ 一颗中档到大档补天丹**。设计标语：**「输一场，白走三到五步。」**

### 3. 可见性：明文常驻、恒精确，寿元退出隐藏属性体系

- 合并值明文常驻 EventOption 选择界面的角色状态条（沿用 `❤` 位），**恒显示精确余量**；低于本章预算 10% 转红字（纯视觉强调，不是叙事通道）。
- `selectCost`、回寿数字、道具描述、结算面板寿元行**恒精确展示**，Band 门控三行表整体删除。
- **两段式告警（30% 定性叙事 / 10% 红字倒数）退役。**
- `HiddenStat` 枚举去掉 `LifeSpan`，隐藏属性收敛为**道心 / 煞气**两项；档数 12 → 9，带 `PlotTriggerId` 的档由 3 个减为 2 个（煞气反噬 / 心魔滋生）。
- `Status.LifeSpanBand` 与 `Status.ChapterLifeSpanBudget` **两格均删除**；`Status` 25 → 22 格。

### 4. 终态与结构收缩

- `DefeatReason` 四值 → **三值** `{ Discarded, LifeSpanExhausted, FinaleFailed }`。
- `ResourceElements` 删 `LifeTotal` 行；`CostKey` 删 `LifeTotal` 成员（16 → 15）；`OutcomeDirection` 五 key → 四 key；`Status` 删 `lifeTotal` / `LifeSpanBand` / `ChapterLifeSpanBudget` 三格。
- 表驱动的终态判定不受影响——删一行即少一个终态资源，正是该结构预期的可扩展方向；`ADR-0025` 的 Finale 显式旁路原样保留。

### 5. 回复通道与 Research

- 回寿三通道（回寿事件 / 补天丹 / 商店购入）**原样继承**，共用 `ChangeElement(CostKey.LifeSpan, +n)`。三道软闸 + Travel 禁令原样有效。
- **Research 的 `Recuperate` 整条删除**，六类操作 → **五类**；Research 收敛为**纯构筑事件**，产出面 = 卡组 + `manaLimit`。

### 6. modifier 耦合

`LifeSpan` 行的 `CostModifier = ModifierKey.LifeSpanCost` 在合并后同时作用于「事件消耗」与「战斗失败扣减」。**接受不拆**，并在 `ResourceElements` 的依据列明写这条耦合代价。**明确不做的两条：** 不为战斗损失另开 `ModifierKey`；不给 `LifeSpan` 开 `Set` op。

### 7. 文档落点

`systems/character-profile/life-total.md` 退役，新建 `systems/character-profile/life-span.md`，承载：定名 · 预算表与结转 · 两个扣减来源 · 回复三通道 · 归 0 终态 · 单值无上限（含 mana 非对称的理由段）· 战斗内不读写的资源纪律 · 呈现位置 · 寿元曲线回链。

## Clarifications（interview 产物）

### 用户裁决（合并 interview · 2026-08-30）

- **Explore 的定价指纹泄漏怎么堵？** → **用 Explore 行的独立定值堵死**：壳恒按 Explore 行的唯一定值报价，成本数字不含真身信息。护栏由「呈现门控」升为「定价结构」，条目不得覆盖 Explore 行的禁令由「配合门控」升为「独立承重」。`pillars.md` 第 9 条不松动（**第三处支柱级松动未发生**）。`ADR-0109` 否决「区间掷定」的理由由三条减为两条。
- **合并把两条死亡曲线焊成正反馈螺旋，是否加阻尼？** → **接受螺旋，写为设计取向**（grimdark：一次惨败真的会滚雪球）。`FailureRatio` **保持 50%**；`game-progression.md` 的验收项扩充为「即使发生 N 次典型失败仍能在预算内升满」，交平衡阶段反推；`lossPerMomentum` 的 ch2/ch3 系数登记为**这条螺旋的调参旋钮**（不只是量纲吸收旋钮）。
- **Research 的 `Recuperate` 保留还是删除？** → **删除**（推翻了原草稿「保留 `Recuperate`、只改口径为回寿元」与「实际张力变锐（续命 vs 变强）」那一段）。六类操作 → 五类，回寿改由事件 outcome 与补天丹 / 商店购入独占；Research 收敛为纯构筑事件；`ADR-0022` 的篝火式二选一整条退役，**直接改写该 ADR**。`combat/_index.md` 的退让位「满级前一批必有一个带 `Recuperate` 的 Research」作废，改挂「回寿事件 outcome 的编排下限」。连带好处：无须写净额语义与「回寿量恒小于已付 `lifeSpanCost`」的编排口径。
- **六条依据失效的既有权威如何处置？** → **一律保结论、改理由。**
  1. `ADR-0016` 的减档禁令射程收窄为「不得为**文案密度 / 调制手感**而减档；某属性**整体退役**导致的减档不在此列」，禁令对道心 / 煞气原样有效。
  2. `ADR-0081` 管辖收窄为道心 / 煞气两项；**同时**把「寿元在战斗过程中不被读写、只在收口时刻被扣」升格为一条**资源纪律**，权威落 `life-span.md` + `scoring.md`。
  3. `plot-manager.md` 的「1:1 不得分档」射程收窄为「**不按 `combatTier` 分档**（三档共用同一系数）；按**篇章**分档是量纲膨胀的必要吸收」；`balance.md` 的疲劳类比改述为「疲劳扣减不隔映射层」。
  4. 境界基线公式删除，但**敌人赋级带 `±2` 与「层数散布 ≤±1 档」取值全不变**，依据改写为非数值理由（`ADR-0044` 自身的「不给覆盖参数」硬规则 + 难度曲线可控）；**`±1 档` 护栏整条迁往 `systems/enemies/_index.md`**，`/audit-content` 归属不变；「合并后带宽是否可放宽」记为新的待答项。
  5. `ADR-0066` 的「战斗内回寿道具 → 拒」**保留禁令、换新理由**：战斗内不得读写这条命，否则以生命值为终止条件的战斗从后门回来。`power/_index.md` 的同族禁令同理。
  6. `profile-service.md` 明写两条组装纪律：① `LifeSpan` 的负向来源恰两个（`SelectCost` 内的 `lifeSpanCost`、combat-service 组装的失败扣减），内容侧 `OutcomeSpec` 恒不得写负 `LifeSpan`；② `Elements` 列**明确允许同键多条**（求和后一次钳制）并写明理由。
- **`Status.ChapterLifeSpanBudget` 是否保留？** → **删除字段**（推翻了草稿「`ChapterLifeSpanBudget` 保留」那一句）。`Status` 25 → 22 格；「占本章预算百分比」降为 `balance.md` 的书写口径术语；ChapterManager 的冻结职责删除；分母漂移的承重推论整体退役。
- **合并值是否常驻战斗屏？** → **不常驻；结算面板如实展示**本次扣减量与扣后余量。战斗屏只呈现道念对比与差值。该待答条目的另两半（道念对比形态 / 道念差是否显式呈现）**不被答结**。
- **跨档叙事频次塌陷是否补偿？「大限将至」改挂何处？** → 用户答复：**「不再需要大限将至等提示文案，因为已经显性展示。」** 射程：不启用煞气 Band 2 文案档、不新增非 Band 叙事通道；寿元的三条 `HiddenStatBandData` 文案条目随 Band 退役**一并删除**；「大限将至」**不另找载体**；**终态死亡屏的 `DefeatReason` 呈现照旧保留**（它是结果呈现，不是提示文案）；「跨档叙事频次是否过稀」不记为待答项。
- **`lossPerMomentum` 的维度与初值口径？** → **一维（篇章）+ 形状锚**：ch1 = 1；`Practice` 的轻量化继续由三个既有旋钮承担；ch2/ch3 不留空，先框「一次最坏失败恒落在本章预算的 8%–12%」的形状锚。
- **事件选项付不起 `selectCost` 是否改设灰态？** → **仍不设灰态**，论证收敛为单一理由：支付是无条件可推进行为；余量恒可见反而强化了「知情地走进死路」这个决策。

### 草稿评审已裁决（2026-08-29）

- **取形态 A —— 合并 + 显性化。** 九条张力全部按「需要它松动」处理。
- **两处支柱级松动均接受：** ① `vision/pillars.md`「多重相互竞争的压力」按压力线由两条并为一条改写；② `adventure-event/common-properties.md`「寿元预算不可被电子表格化优化 —— 这正是取向本身」这条纪律**反转**。
  - 落笔时的补充核实（同族纪律共四组）：`common-properties.md` 的寿元预算段——反转；回寿道具定价「这颗丹值不值这个价」的代价明写——显性化后整条消失；`ux/screen-flow.md` 的原始出处 + `game-progression.md` 的 eventOption 不标注经验产出档位——**不受影响**；`exchange/_index.md` + `plot-manager.md` 的好感度不设数值——**不受影响**。改写时须明写反转只及于寿元，另两条纪律的依据各自独立成立。
- **`lossPerMomentum` 按建议方案二落形态**（ch1 = 1 锁定，ch2 / ch3 待反推）。

### 自行采纳的标准默认（🔵 · 依据既有设计推演）

- **`ADR-0016` 的消费方是五个不是六个** —— `selectCost` 与回寿数字精确展示是同一个开关。五个中两个整体退役（红字标注 · 精确展示开关），另三个（eventOptions 调制 · 剧情线触发 · 跨档叙事）由三属性减为两属性。`plot-manager.md` 的六行表口径顺手对齐为五。
- **`ADR-0045` 并非整份失效**，也没有「已知风险」段落——其承重结论（单值 · 无上限字段 · 无截断）保留并继承给寿元，失效的只有境界基线公式。
- **`ADR-0045` 的 mana 非对称承重段整段迁往 `life-span.md`**，迁移后它拦的是「把寿元也拆成 `currentX / xLimit` 两字段」；两列实质重写。
- **`ADR-0025` 的两条论据不受伤**：「借道 `LifeTotalExhausted` 被否决」一段随成员删除而作废但结论不变；「分不清两种死法」在合并后不成立——资源触底只剩一种，反而更清楚。
- **Finale 失败与资源触底同刻竞合 → `FinaleFailed` 优先**（既有旁路已在资源表循环之前，无需新规则）。
- **`CostKey` 16 → 15**；`architecture.md` 的「新增一个资源 element 恰好五步」补一条**反向**五步（表只把增长登记为预期形态）；四处计数（`architecture.md` 的「16 值」、`profile-service.md` 的「全表 16 行」两处、满射断言「`Status` 前六格」→ 前五格）一并改。
- **`OutcomeDirection` 五 key → 四 key**；`common-properties.md` 校验 2 的 `ResourceKey` 集合删 `LifeTotal`，镜像位 `future-event-service.md` 的 `FixedResource` 可写 key 五 → 四同改。
- **`common-properties.md` 校验 9（`HiddenStatGrants` 内 `Stat == HiddenStat.LifeSpan` → 拒）整条退役** —— `HiddenStat` 收缩后该坏形态在类型层面已写不出来；三条理由段一并作废。纯净收缩，但显式登记以免留下永假断言。
- **删除寿元的三条 `HiddenStatBandData` 内容条目**；「`LifeSpan` 以百分点书写」这条唯一的异类语义随之消失；`BandIndex` 连续性校验覆盖面减一属性；`Status` 上 band 字段 3 → 2。
- **「档号方向 = 离常态的距离」的承重定义**结论不动，理由段改写为以道心（双臂）为例。
- **`profile-service.md` 的 `Min = 0` 理由 ① 重写**（结论由理由 ②③ 独立支撑）；「只读查询不构成施加点、不写回定稿实例」去掉 Band 限定词但**保留「不写回定稿实例」**；「产出向不开 `GainModifier`」的理由在合并后强度翻倍，同批加重。
- **「按符号分向是必需的」原样成立**；合并只是让 `CostModifier` 多覆盖一个来源。
- **`PastEventEntry.LifeSpanAfter` 与寿元曲线读取算法零改动**，语义反而更强——它现在就是角色的完整生命曲线。
- **`architecture.md` 的举例「寿元与耐久归 0 构成终态」→「寿元归 0 构成终态」**；`ADR-0063` 的「三个不同区间」举证由三减为二（结论不变）。
- **`terminology.md`：** 寿元词条的「（非 life）」括注删除（合并后寿元就是 life）；赋级带词条的 `Band` 命名注改为「已被隐藏属性档（道心 / 煞气）占用」，命名结论不变；`settle` 定义中的扣减对象改写。
- **`ADR-0031` 曾否决「`selectCost` 塌缩为单一 `int`」的理由**改述为「复合类型是为成本侧未来容纳其他资源留的位」（该处张力是既有的、非本次引入）。
- **后端零影响核实通过**（对侧库全量检索零命中）；`open-questions/cross-boundary.md` 的钳制语义预警去掉「耐久」，预警本身照旧适用。
- **`content/` 与 `requirements/` 全量检索零命中**，零迁移成本核实通过。
- **旧 answer-log 一律不改**（log 是只读历史记录），被作废的旧结论只在本次新建的 log 里记明取代关系。
- **不评估 derive 就绪度**，不碰 `open-questions.md` 的该小节。
- **`.claude/knowledge/` 的 4 处引用**归 `/sync-knowledge`，本次不代写。
- **「大限将至」对应终态而非任何一档、不经 `PlotTriggerId`** 原样成立。
- **`ADR-0017` 已核对不改**（按符号分向的论证原样成立）。

## Design pillars / anti-goals

- **IN：** 一条可通约的压力尺；知情的取舍；grimdark 的滚雪球式失败面。
- **OUT：** 以生命值为终止条件的战斗（战斗内不得读写这条命）；给寿元加上界（会引出「补满时用丹浪费」这一整类挫败感）；用上限截断稳住时长反推（换算就是全部规则）；把战斗失败扣减拆成独立 `CostKey`（那在施加链路上就是没合并）。

## Open questions

- `lossPerMomentum` 的 ch2 / ch3 系数取值（形状锚已给，取值待反推）。
- 回寿量三档在新量纲下的绝对点数重估。
- 合并后敌人赋级带 `±2` 与层数散布 `±1 档` 是否可放宽（留给内容 / 平衡阶段）。
- 失败螺旋的容错量验收：「即使发生 N 次典型失败仍能在预算内升满」中的 N 与验收口径。
