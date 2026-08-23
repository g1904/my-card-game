# Phase A — band-boundary-config-placement

来源草稿：`game-design-documents/inbox/solution-draft-band-boundary-config-placement.md`（`status: awaiting-review`，正文已带「已全部裁决（按推荐 · 待复核）」）
目标库：`game-design-documents/`（plan.md 已定）

## 一句话意图

三章 `±2` 赋级带的边界值**住平衡资源**（不是服务配置），与带内分布权重表**同住一份新资源**（三章各一行具名字段 + 该行权重数组），并在加载期设五条校验；同时**显式作废**一条随意图机制移除而失效的旧一致性检查。

## 已裁决（不进 interview）

- **落点 = 平衡资源，「服务配置」这一层在本库不存在。** 七服务无一持有可调数值配置面；`balance.md` 已列 7 处先例（`CombatRulesData` · `TravelFullFanoutChance` · 篇章重试两行 · `rewardPerMomentum` · `ExperienceGrade` / `HiddenStatGrade` 映射 · `itemPowerRatio` · `MaxConcurrentSideArcs`），无反例。与 `.claude/rules/data-resource-rules.md`「可调数值不硬编码、系统从数据读」一致。
- **写权收口**：赋级函数不接受任何区间覆盖参数；PlotManager 只能乘性调制权重（既有 `PlotModulation.LevelBias`），不得改带边界。既定条款，本草稿不松动。
- **不并入 `CombatRulesData`**：消费者不同（物化 vs 战斗）、覆写纪律相反（不接受覆写 vs `EncounterSpec` 可空覆写）。
- **无存档影响**：`EnemyInstance.Level` 物化即定稿并随 `EventOption` 落存档（`future-event-service.md`「产物随 EventOption 落存档、不重算」）。
- **不与 ADR-0007 冲突**：新增一份平衡资源 = 新 `Id` 随版本发布（`res://` 基线），overlay 侧仍只改不增。

## 待复核（按推荐裁定，需用户确认）

草稿 `## 仍需用户决定` 三项均标 `[采纳推荐 — 待复核]`，**不算用户拍板**，请在合并 interview 中一并复核。若用户不复核，Phase B 按推荐写入并在 handoff 与 `## Open questions` 双处标 `[采纳推荐 — 待复核]`。

1. **三章各一行具名字段（当前三行同值 `(−2, +2)`）** → 推荐 A。理由：`balance.md` 现表述即「三章的带边界」「只读当前篇章的带」；沿用 `chapterRetry` 与三个隐藏属性 band 的「篇章数是固定结构 ⇒ 具名字段、不用字典 / 索引数组」判据；把「分章 → 统一」那次回退的可逆性留在数据侧。B（单一全局值）需同步改写 `balance.md` 两句表述。
2. **新开一份 `EnemyLevelingData`（带边界 + 权重表同住）** → 推荐 A。理由：消费者独立且封闭（future-event-service 物化赋级）；分放两份资源会制造一条无人校验的跨文件不变式（档数 == `Upper − Lower + 1`），破了即静默错位。**注意：类型名本身另有一处冲突，见 🟠-1。**
3. **权重存储单位 = 归一化小数（和为 1）** → 推荐 A。理由：运行期截断重分配本就要归一化；`balance.md` 现以百分数呈现，那是呈现形态。**连带 🟠-3。**

## 🔴 冲突

- **[问题陈述] 本草稿要显式作废的那条旧检查，其被检查对象在两份活文档里仍留有正面表述，本次不清理即成为「文档自证该门槛存在」。**
  ✗ 权威：`systems/balance.md` L29 推论③「境界中段的 `+2` 是同阶，**照常按 `diff` 门槛给信息**」；`systems/services/future-event-service.md` L151 推论④ 同句；同文件 L136「玩家据此与自身等级比对，**理解意图为何被遮蔽**」。
  ✗ 对立权威：意图机制整条移除（三档揭示 / `IntentCategory` / 快照 / 探查全部作废），见 `open-questions/01-combat.md` 顶部治理提示与 `handoffs/2026-08-15d-*`。
  - 选项 (a) 本次一并清理这三处（删掉 `diff` 门槛 / 意图遮蔽的从句，保留「境界中段的 `+2` 是同阶」这条仍成立的判断），并在落点条目下写明「**不设『下界不得使 `diff` 门槛不可达』这条校验**（被检查对象不存在）」——后果：改动面多出 fes 的两处非本草稿小节，但库内不再有指向已删机制的正面表述。
  - 选项 (b) 只在新落点处写「不设该校验」，三处残留留给全库收口 session——后果：文档里同时存在「不设该门槛校验」与「照常按 `diff` 门槛给信息」，实现者读到后者会以为门槛仍在。
  - **推荐 (a)**。依据：技能第 6b「遇到既有违规顺手修（限本次改动触及的小节）」——L151 就在本次要改的赋级带小节内；L136 只需删半句从句，扰动极小。且草稿的核心诉求正是「不能沉默地不实现，要写明」。

- **[问题陈述] `future-event-service.md` 的「推论 ⑦」出现两条，其中一条仍按已作废的 ch1 非对称带描述档位数，并声称带内权重「待定」。**
  ✗ 权威：`future-event-service.md` L155「推论 ⑦：带只约束『能出到几级』，不约束分布。带内各档（**ch1 七格 / ch2 · ch3 五格**）以什么权重出现，仍归本服务的加权规则（**待定**）」。
  ✗ 对立：三章统一 `±2` ⇒ **恒为五格**（同文件 L144、`enemies/_index.md` L88）；带内权重表**已定**（`balance.md` L32–44，5% / 20% / 40% / 25% / 10% + 截断重分配 + 批内去重 + 乘性调制），且 L153 的另一条「推论 ⑦」已正确指向它。「ch1 七格」是 08-06 `[−4, +2]` 的残留，`01-combat.md` 顶部已声明该带作废。
  - 选项 (a) 删除 L155 那条重复的推论 ⑦（其内容已被 L153 与 `balance.md` 完全覆盖），并把 L153 重编为 ⑦——后果：编号连续，无残留失效表述。
  - 选项 (b) 保留并改写为「五格 · 权重表见 balance.md」——后果：与 L153 重复，属同一句话说两遍。
  - **推荐 (a)**。依据：活文档只保留最新设计、不留考古；两条同号推论本身即缺陷。

## 🟠 含糊

- **[🟠-1] 类型名 `LevelBand` 与本库既有的「Band」语义撞名。** 库内 `Band` 已被**隐藏属性档 / 寿元档**独占（`HiddenStatBandData : Resource`、`BandIndex`、寿元 Band 0/1/2、`ADR-0016-hidden-stat-band-model`、`PlotTrigger.HiddenStatBand`）。而本库对这类撞名有明确硬约定的先例：`Tier`（优势档）与 `RarityTier`（稀有度档）**不得复用同一枚举、类型名不写成裸 `Tier` 正是为了避免同页两义**（`balance.md` L138）。
  - 可解读为 (a) 沿用草稿的 `LevelBand`（内嵌行类型）+ `EnemyLevelingData`（容器）——简洁，但「Band」在本库同页会有两义；
  - (b) 行类型改名避开 Band，例如 `EnemyLevelRange` / `LevelDiffRange`（带 = 相对 `diff` 的闭区间 + 逐档权重），容器仍为 `EnemyLevelingData`；
  - (c) 沿用 Band 但在 `terminology.md` 登记「Band（等级带）↔ Band（隐藏属性档）」两条词目并注明不可换算。
  - **推荐 (b)**。依据：`Tier` / `RarityTier` 那条硬约定的判据完全适用（两个档位概念、都在 balance / plot 语境里出现、且都会进 `[Export]` 字段名）。**注**：草稿正文与设计口语一直用「赋级带」，中文侧不受影响；改的只是代码标识符。**本项与「待复核 2」的命名问题同源，请一并呈给用户。**
  - 连带：无论选哪个，`terminology.md` 目前**没有**「赋级 / 赋级带」词条 —— 新引入的代码标识符需登记一行（技能第 2 步：凡引入 / 重命名领域词汇均需在此登记）。

- **[🟠-2] 落点 + 形态 + 五条加载期校验，写在 `balance.md` 还是 `future-event-service.md`？** 草稿的「后果」只说 balance.md 补一句落点、fes 补一行读取面，但没说五条校验表落哪份；而 fes L146 现写「落点与加载时校验见 `systems/balance.md` 的**待决问题**」——该待决问题本次会被删除，这句引用必然要重写，指向哪里取决于本题。
  - (a) 五条校验 + 资源形态全部落 `balance.md`（该文件已承载多处加载期断言：`GrantPoolWeights` 任一档权重为 0 → `PushError`、`ExperienceGrade` 映射上界断言、三格取池余量），fes L146 改为「本服务只读；资源形态与加载期校验见 `systems/balance.md`」；
  - (b) 校验落 `systems/services/content-service.md`（内容加载期校验的口径权威）；
  - (c) 分家：形态落 balance.md、校验落 fes。
  - **推荐 (a)**。依据：balance.md 已是同类断言的既有落点，且「带边界 + 权重同住一份资源」这条不变式的两个被校验对象都在那一节；(c) 会让不变式的定义与它的校验分居两份文档。

- **[🟠-3] `balance.md` 的权重表以百分数呈现（5% / 20% / 40% / 25% / 10%），存储改为归一化小数后，那张表改不改？** 两种解读会写出不同文档：
  - (a) 表保持百分数呈现，仅在表下补一句「存储单位为归一化小数，和为 1；呈现乘 100」——不动既有表，读者体验不变；
  - (b) 表改写为 0.05 / 0.20 / …，与存储对齐——避免「文档一个单位、资源另一个单位」的二义，但改动了一处与本题无关的既有表述。
  - **推荐 (a)**。依据：最小扰动 + 草稿自己已声明「呈现形态与存储单位不必一致」。**但校验条「权重和 ≠ 1（或百分数和 ≠ 100）」必须在文档里落成一个确定值**，不能照抄草稿那句两可的括号。

## 🔵 可推演

- 落点 = 平衡资源（7 处先例 + 零反例 + `data-resource-rules.md`）；「绕开 overlay 热更 / 绕开启动期强校验 / 制造第二种落点答案」三条否决理由均可由既有文档直接推出。
- 三行具名字段的判据已有同款先例被明写：`balance.md` L282 道统残卷「代码侧只读『当前档的上限 / 基础 / 增量』三个概念，不为分档写分支（**与赋级带『不为分章写分支』同款**）」——即「按行取值 + 调用侧只见一个概念」与「不写分章分支」自洽，无需再问。
- `BandFor(chapter)` 的 chapter 输入取自 `CharacterProfile.所在篇章`（fes 物化输入已列），不新增状态读取。
- 截断重分配是**运行期**行为，与加载期「权重和 = 1」不矛盾——`balance.md` L42 与 fes 推论⑦（L153）均已明写「必须显式实现」，本次只需在校验表旁补一句「两者作用在不同时刻」。
- `enemies/_index.md` L88「带边界是内容侧可调数值」可直接升级为「住在 `<资源名>`」，其余三条（`±2` 硬规则 / 挂 Enemy 不挂事件类型 / 越阶只在末两级）不动。

## 拟改动文档清单（供跨草稿核对）

- `systems/balance.md`：赋级带条目补「落点 = `<资源名>`（带边界与带内权重同住一份）+ 三章各一行具名字段 + 三行当前同值」；补五条加载期校验表 + 「不设『下界不得使 `diff` 门槛不可达』这条校验」的显式声明 + 「截断重分配是运行期、不与加载期权重和校验冲突」一句；权重表补一句存储单位（🟠-3）；**删除 `## 待决问题` 中「带边界的配置落点」整行**（L345）；清理 L29 推论③ 的 `diff` 门槛从句（🔴-1）。
- `systems/services/future-event-service.md`：赋级带小节 L146 改写为「本服务只读『当前篇章的带』；资源形态与加载期校验见 `systems/balance.md`」（消除对已删待决问题的悬空引用）；物化伪码 ② 处补读取面 `BandFor(chapter)` 一行；补「PlotManager 不得改带边界，只能乘性调制权重」（与 L129 三项权力面对齐，可就地补半句）；删除 L155 重复且失效的推论⑦（🔴-2）；清理 L151 与 L136 的意图残留（🔴-1）。
- `systems/enemies/_index.md`：「赋级带的接受面」首条把「带边界是内容侧可调数值」升级为「住在 `<资源名>`（与带内权重同住），随内容 overlay 可调」。
- `terminology.md`：登记「赋级带 ↔ `<代码标识符>`」一行（视 🟠-1 的裁决）。
- **新建 handoff** `handoffs/2026-08-22-<slug>.md`（`status: distilled`）。
- **不碰**：`decisions/`（无 ADR 候选——本方案是既有约定的直接延伸，草稿自述「与既有决策的张力：无」）；「derive 就绪度」小节。

## 待移出的 open-questions 条目

- `open-questions/01-combat.md` → `## 结构与配置的残留` 第一条「**带边界的配置落点（08-06b 立 · 08-15d 收窄）**」整条移出。
- 归档去向：`answer-logs/log-band-boundary-config-placement.md`（`draftSuffix` = `solution-draft-<slug>` 的 slug）。拟写条目：
  - `**三章的 ±2 带边界放在平衡资源里还是服务配置里？** → 平衡资源；与带内分布权重表同住一份新资源（三章各一行具名字段，当前三行同值 (−2,+2)），五条加载期校验；「服务配置」这一层在本库不存在（systems/balance.md、systems/services/future-event-service.md、systems/enemies/_index.md）` —— 附注三项 `[采纳推荐 — 待复核]`（分行形态 / 资源命名与切分 / 权重存储单位）若用户未复核则仍留在待答清单。
  - `**「下界不得使 diff 门槛不可达」一致性检查是否保留？** → 不保留，且在文档中显式写明不设此校验（被检查对象随意图机制移除而不存在）（systems/balance.md）`
- 台账行（orchestrator 代笔）：`answer-logs/_index.md` 追加 `log-band-boundary-config-placement.md | 2026-08-22 | inbox/solution-draft-band-boundary-config-placement.md | 2`。
- `inbox/_index.md`：待处理表删该行，已归档表补 `solution-draft-band-boundary-config-placement.md | solution-draft | 2026-08-22 | handoffs/2026-08-22-<slug>.md | log-band-boundary-config-placement.md`。

## 越界发现

- **单例平衡资源的加载 / 索引形态全库未定（不属本草稿，不顺手处理）。** `CombatRulesData` 一类平衡表被 `content-service.md` L258 归入「被存档引用 · 只改不增 · 有稳定 `Id`」，但库内没有任何一处说明**单例平衡表如何进 ContentRegistry**（Id 形态？仓储？`AllEnabled()` 对单例是否有意义？）。新增 `EnemyLevelingData` 会成为这个空白的第 N 个实例，但不加剧它。建议作为一条新待答项由 orchestrator 判断是否登记进 `open-questions/01-combat.md` 或架构分片。
- **与分片 5（enemy-pool-chapter-scoping）的交叉点。** `01-combat.md` L31「敌人池的篇章框定载体未定」——`EnemyData` 无任何字段表达篇章。本草稿的「三章各一行 + `BandFor(chapter)`」读的是**角色所在篇章**（`CharacterProfile`，已有），与敌人条目的篇章归属是两件事，**不冲突**；但两者若最终引入不同的「篇章」表示（枚举 vs int vs 具名字段），会在同一条物化管线里出现两套 chapter 口径。**请 orchestrator 与分片 5 的报告交叉核对篇章表示形态。**
- 分片 5 与本分片都写 `enemies/_index.md` 与 `future-event-service.md` —— plan.md 已把二者编入同一 worker（W4）串行，符合铁律③，无需再分。
