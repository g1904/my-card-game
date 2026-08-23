# 赋级带边界的配置落点 —— `EnemyLevelingData`

- id: 2026-08-22-band-boundary-config-placement
- date: 2026-08-22
- topic: systems/balance.md · systems/services/future-event-service.md · systems/enemies/_index.md · terminology.md
- status: distilled
- distilled-to: systems/balance.md, systems/services/future-event-service.md, systems/enemies/_index.md, terminology.md

## Intent（distilled）

三章 `±2` 赋级带的边界值**住平衡资源**，与带内分布权重表**同住一份**。

**1. 落点 = 平衡资源；「服务配置」这一层在本库不存在。** 七个服务无一持有自己的可调数值配置面；凡可调的数字无一例外住在平衡资源 `.tres`（`CombatRulesData` · `TravelFullFanoutChance` · 篇章重试两行 · `rewardPerMomentum` · `ExperienceGrade` / `HiddenStatGrade` 映射 · `itemPowerRatio` · `MaxConcurrentSideArcs`，七处先例、零反例）。做成 `[Export]` 会绕开 overlay 热更通道（改一个数字要发版，而带边界正是实测后要调的头号候选）、绕开启动期强校验、并制造第二种「可调数值住哪」的答案。这不是取向选择，是既有约定的直接后果。

**2. 与带内分布权重表同住一份资源。** 权重表的**支撑集就是带宽**：`−2 … +2` 五档不是五个独立数字，而是「从下界到上界逐档」的枚举。分放两份会产生一条跨文件不变式（档数 == `Upper − Lower + 1` 且顺序一一对应），这种不变式要么无人校验、要么校验代码得同时加载两份资源猜对应关系；破了就静默错位——**能上线、线上分布悄悄不对却不崩**。同住一份，它退化为一次本地断言。**不并入 `CombatRulesData`**：消费者不同（物化 vs 战斗）、覆写纪律相反（不接受覆写 vs `EncounterSpec` 可空覆写）。

**3. 形态 = 容器 `EnemyLevelingData` + 三章各一行 `EnemyLevelRange`（`Lower` / `Upper` / `Weights`），当前三行同值 `(−2, +2)` 与 `0.05 / 0.20 / 0.40 / 0.25 / 0.10`。** 三行同值不是冗余：三章统一是**当前取值**而非结构性约束，留三行把「分章 ↔ 统一」的可逆性保留在数据侧而非焊进代码。读取收敛为一次取值 `BandFor(chapter)`，调用侧仍只见「当前篇章的带」这一个概念，与「不为分章写分支」自洽。

**4. 行类型定名 `EnemyLevelRange`，刻意避开 `Band`。** 「Band」在本库已被隐藏属性档 / 寿元档独占（`HiddenStatBandData` · `BandIndex` · `PlotTrigger.HiddenStatBand`），同页两义。判据与「`Tier`（优势档）与 `RarityTier`（稀有度档）不得复用同一枚举、类型名不写成裸 `Tier`」那条硬约定完全一致——两个档位概念、都出现在 balance / plot 语境、都会进 `[Export]` 字段名。中文侧照旧叫「赋级带」，改的只是代码标识符；`terminology.md` 新增一行登记。

**5. 写权收口（沿用 `TravelFullFanoutChance` 范式）：** 带边界只有这一份权威，赋级函数不接受任何区间覆盖参数；**PlotManager 只能乘性调制带内权重（只改权重不改支撑集），不得改带边界**——调制若能改支撑集就等于给剧本开了一个绕过 `±2` 硬规则的后门，而 `±2` 的数值安全性推导正建立在支撑集封闭之上。

**6. 五条加载期校验**（带不含 `diff = 0` / 空带 / 权重数组长度 ≠ 带宽 / 权重和 ≠ 1 / 权重含负值，全部 `PushError` + 抛并带章号），连同资源形态**全部落 `systems/balance.md`**——该文件已是同类断言的既有落点，且「带边界 + 权重同住」这条不变式的两个被校验对象都在那一节。

**7. 显式作废一条已失效的旧检查。** 「下界不得使 `diff` 门槛不可达」的被检查对象（按 `diff` 分档的信息揭示门槛）在本作中已不存在，**文档必须写明不设此校验**，而不是沉默地不实现——沉默会让它日后被重新捡起来去检查一个不存在的东西。同时清理库内三处仍在正面陈述该门槛存在的残留（`balance.md` 与 `future-event-service.md` 的「照常按 `diff` 门槛给信息」、后者的「理解意图为何被遮蔽」），保留「境界中段的 `+2` 是同阶」这条仍成立的判断。

**8. 权重的存储单位 = 归一化小数（和为 1）**；`balance.md` 的表**保持百分数呈现**，表下补一句存储单位（呈现乘 100）。运行期的截断重分配本就要做一次归一化，用小数少一次单位换算。**截断重分配是运行期行为，与加载期「权重和 = 1」作用在不同时刻，二者不矛盾**——须写明，以免实现者以为它们打架。

**无存档影响**：带边界是内容侧数值，赋级结果 `EnemyInstance.Level` 在物化时即定稿并随 `EventOption` 落存档，线上调带边界不影响已定稿的实例。**不与 ADR-0007 冲突**：新增一份平衡资源 = 新 `Id` 随版本发布（`res://` 基线），overlay 侧仍只改不增。

## Clarifications（interview 产物）

- **意图机制残留** → **一并清理三处**（`balance.md` 推论③ · `future-event-service.md` 推论④与「理解意图为何被遮蔽」），只删 `diff` 门槛 / 意图遮蔽的从句。否则文档里会同时存在「不设该门槛校验」与「照常按 `diff` 门槛给信息」，实现者读到后者会以为门槛仍在。
- **`future-event-service.md` 的两条「推论 ⑦」** → **删除仍按已作废的 ch1 七格描述档位数、并称带内权重「待定」的那一条**；正确的那条（指向 `balance.md` 权重表）重编为 ⑦，编号恢复连续。三章统一 `±2` ⇒ 恒为五格；权重表已定。
- **行类型命名** → 改名避开 `Band`，取 `EnemyLevelRange`（容器仍为 `EnemyLevelingData`），并在 `terminology.md` 登记一行。库内此前没有「赋级 / 赋级带」词条。
- **五条校验与资源形态落哪份文档** → 全部落 `balance.md`；`future-event-service.md` 的赋级带小节改为「本服务只读『当前篇章的带』；资源形态与加载期校验见 `systems/balance.md`」——原措辞引用的是本次会被删除的那条待决问题，不改即成悬空引用。
- **权重表的呈现单位** → 表保持百分数、表下补一句存储单位（最小扰动）。**但校验条的和值落成一个确定值 `1`（浮点比较取容差 `1e-6`）**，不照抄草稿那句「和 ≠ 1（或百分数和 ≠ 100，按最终取值单位定）」的两可括号。

## Open questions

以下三项按推荐落笔，均 `[采纳推荐 — 待复核]`，**不是用户拍板**，仍留在待答清单：

- **三章各一行具名字段（当前三行同值）** vs 单一全局值。选 A 的理由：与 `balance.md` 既有表述一致，沿用 `chapterRetry` 与三个隐藏属性档的「篇章数是固定结构 ⇒ 具名字段」判据，把「分章 ↔ 统一」的可逆性留在数据侧。
- **新开一份 `EnemyLevelingData`** vs 并进既有平衡资源的一节。选 A 的理由：消费者独立且封闭；分放会制造无人校验的跨文件不变式。
- **权重存归一化小数（和为 1）** vs 百分数整数。选 A 的理由：运行期截断重分配本就要归一化。

## Notes / triage

- **越界发现（未处理）**：**单例平衡资源如何进 ContentRegistry 全库未定**——`Id` 形态？仓储？`AllEnabled()` 对单例是否有意义？`EnemyLevelingData` 是这个空白的又一个实例，但不加剧它。
- **与 `enemy-pool-chapter-scoping` 的交叉点已核对**：`BandFor(chapter)` 读的是**角色所在篇章**（`CharacterProfile.chapter : int`），`EnemyData.ChapterScope : int[]` 表的是**内容条目的篇章归属**——两件事、同一底层表示 `int`，物化管线里只有一套 chapter 口径，无冲突。
