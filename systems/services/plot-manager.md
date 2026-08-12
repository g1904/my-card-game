# PlotManager（管理器 · 隶属 future-event-service）

> 隐藏剧本管理器：剧本层级（Story / Chapter / SideChapter / SideStory 四级）、隐藏属性驱动（道心 / 煞气 / 寿元）、CharacterProfile 上的 key points、剧本内容的本地解析、eventOptions 调制。
> **它是 manager 而非 service**：生活在 `future-event-service` 内部，共享其事务边界与生命周期，**不被跨服务直接调用**。Source: `handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md`。
> **本 manager 纯本地，永不跨进程边界。** 剧本内容属本地内容层（`res://` 基线 + overlay），经 ContentRegistry 读取。Source: `handoffs/2026-08-11-plot-content-localization.md`。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **AdventurePlot = 隐藏剧本层。** 一棵由**分支可能性**构成的树，在背景中运行、**调制 future-event-service 产出的 eventOptions**（见 `future-event-service.md`、`systems/game-progression.md`）。玩家通常看不到它，但它持续塑造后续会变为可用的 AdventureEvent；部分节点可像 **DnD** 那样让玩家**显式选择分支**。Source: `handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md`。

- **剧本层级（四级）。**

  | 层级 | 英文 / 代码 | 范围 |
  |------|------------|------|
  | 主线剧本 | AdventurePlot-Story | 贯穿**三大篇章**相连的大剧本（一条完整主线） |
  | 篇章剧本 | AdventurePlot-Chapter | **单个篇章**对应的剧本单元（一个 Story 含三个 Chapter） |
  | 支线（篇章内） | AdventurePlot-SideChapter | 在**单个 Chapter 内**穿插的小型支线 |
  | 支线（跨篇章） | AdventurePlot-SideStory | **跨篇章**穿插的支线 |

  即：三个 **Chapter** 相连组成一个 **Story**；Chapter 内可穿插 **SideChapter**，跨 Chapter 可穿插 **SideStory**。

- **隐藏属性驱动。** 属性模型借鉴 **Reigns** 但**反其道：属性隐藏、不作可见仪表**。隐藏属性（**道心 / faith**、**煞气 / malefic qi**、**寿元 / lifeSpan**）**跨入某个带 `PlotTriggerId` 的档位**时触发对应剧情线。隐藏属性落在 `CharacterProfile.Status`（见 `life-cycle-service.md` 与 `systems/character-profile/`）；由 AdventureEvent 推拉，一切写入经 `profile-service.ProfileManager`。Source: `handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md` + `handoffs/2026-08-12d-hidden-stat-bands-and-crossing-narrative.md`。

- **跨档给定性叙事反馈（已定案 · 数值仍隐藏）。** 数值继续隐藏，但**当某个隐藏属性跨过一个隐藏档位时，给一条定性的叙事描述**——**给方向与因果，不给数字**：

  ```
  道心 ↑ 跨档：  「你于静室枯坐三日，心念澄明。」
  煞气 ↑ 跨档：  「你的指节泛起一层洗不去的暗红。」
  寿元 进入 30%：「鬓角新添的白发，你已数不清是第几根。」
  ```

  - **只在跨档时触发**（每个隐藏属性分若干**隐藏档位**，档位表见下条），**不是每次结算都播**——稀缺才有分量。
  - **落点 = 已有的 `ResolveOutcome` → `eventEnd` 阶段，无新结构**（见 `systems/adventure-event/common-properties.md`）。
  - **设计意图：** 玩家学到**方向与因果**（做这类事会推高煞气），学不到**精确数值**，因此**无法做电子表格式优化**。这正是本作对 Reigns 张力的替代路径——Reigns 靠**可见**仪表制造权衡，本作靠**可感知但不可测量**。
  Source: `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。

- **一套档位模型统一四个消费方（已定案 · 08-12d · 承重）。** 「跨过一个隐藏**档位**」（08-01）与「达**阈值**时触发剧情线」（07-23）**是同一件事**：剧情线触发 = 跨入某个带 `PlotTriggerId` 的档。一张档位表同时回答四个问题，不需要四套判定：

  | 消费方 | 用到几档 | 说明 |
  |---|---|---|
  | **eventOptions 调制**（本 manager 的主业） | **全部档** | 档位是调制的粒度：煞气 1 档与 2 档就该抽出不同风味的事件池。**这是档位表存在的首要理由。** |
  | **剧情线触发** | 带 `PlotTriggerId` 的档（3 个） | 煞气反噬 / 心魔滋生 / 大限将至 |
  | **跨档叙事文案** | **只有极值档（4 个）** | 见下方「文案只挂极值档」 |
  | **寿元红字标注** | 寿元 Band 2 | 既定（见 `ux/screen-flow.md`） |

  **关键的解耦：档多 ≠ 文案多。** 玩家感知到「这条线在动」主要来自**摆在他面前的事件变了**（调制），而不是来自一句旁白。**档数不随文案收窄而减**——砍中间档等于砍掉调制的分辨率，是拿主业去迁就点缀。

  **档号方向（承重）：`BandIndex` 越高 = 越远离常态，而不是「数值越大」。** 「下行不播叙事」若读成「数值下降不播」，寿元既定的 30% 提示（它本身就是数值下降触发的）会被字面废掉。统一定义为「离常态的距离」后，**触发规则对三属性完全一致：`|newBand| > |oldBand|` 才播，反向静默**——不需要方向字段，也不需要为寿元开特例。
  Source: `handoffs/2026-08-12d-hidden-stat-bands-and-crossing-narrative.md`。

- **取值域与档位表（已定案 · 08-12d）。**

  **道心 faith：`[0, 100]`，轮回起始 `50`，双向推拉**（它是「状态」：心境澄明 ↔ 心魔渐生）。**煞气 malefic qi：`[0, 100]`，轮回起始 `0`，以上行为主、可被净化类事件下拉**（它是「累积物」，既定的「累积到阈值触发煞气反噬」直接对应最高档）。**施加后截断到 `[0, 100]`，不构成终态**（与寿元不同）——这同时是 `life-cycle-service.md` 待答项「`TryApply` 施加负值时各资源的钳制规则」在隐藏属性这一半上的答案。

  **有界的理由：** 无界属性的档位只能靠不断加新档追赶，而档位是内容条目、**overlay 只改不增** ⇒ 加档必须发版。有界 + 顶档吸收溢出，使档数在整条内容生命周期里是常量。寿元不套用本条（它已有既定预算模型）。

  **道心 —— 5 档，阈值 20 / 40 / 60 / 80**（唯一的双臂属性，带符号档号）

  | Band | 区间 | 语义（内部命名，不对玩家可见） | `PlotTriggerId` | 文案 |
  |---|---|---|---|---|
  | **+2** | **80–100** | **道心通明 —— 上臂极值档** | — | **✅ 唯一有文案的档** |
  | +1 | 60–79 | 心念澄澈 | — | 静默 |
  | **0** | **40–59** | **常态**（轮回起点 50 落于此档中心） | — | 静默 |
  | −1 | 20–39 | 心绪浮动 | — | 静默 |
  | **−2** | **0–19** | **心魔滋生 —— 下臂极值档** | **✅ 有** | 静默（下行不播，下臂极值不例外） |

  > 带符号档号 `-2 … +2`（存档侧 `sbyte`）比「两个方向各排一套无符号档号 + 一个方向字段」少一层映射，也让「远离常态」直接就是绝对值变大，且不给「方向字段与档号不一致」这种坏状态留位置。
  >
  > **道心下臂 `-2` 不配文案**：「下行不播」优先于「极值播」，叠加结果是「**上行的极值才播**」。**它的存在感由 `PlotTriggerId`（心魔滋生剧情线）与 eventOptions 调制承担**——这是「下臂不播文案」那条取舍能成立的前提：若既无文案又无剧情线，玩家对「掉道心」这条因果链将完全无感。

  **煞气 —— 4 档，阈值 25 / 50 / 75**（单臂，档号即数值序）

  | Band | 区间 | 语义 | `PlotTriggerId` | 文案 |
  |---|---|---|---|---|
  | **3** | **75–100** | **煞气反噬 —— 极值档** | **✅ 有**（既定剧情线） | **✅ 唯一有文案的档** |
  | 2 | 50–74 | 煞气缠身 | — | 静默 |
  | 1 | 25–49 | 煞气初显 | — | 静默 |
  | **0** | **0–24** | **常态**（轮回起点 0） | — | 静默 |

  **寿元 —— 3 档，阈值 30% / 10%**（单臂，**档号与数值反向**）

  | Band | 区间 | 语义 | 文案 |
  |---|---|---|---|
  | **2** | **< 10%** | **红字数值倒数**开始（既定） | **✅ 有**（既定） |
  | **1** | **10% – 30%** | **定性叙事提示**开始（既定） | **✅ 有**（既定） |
  | **0** | **> 30%** | **常态，无提示** | 静默 |

  > 「大限将至」对应的是**寿元归 0（终态）**，不是任何一档——它是 `defeated` 的一个原因子类型，不经 `PlotTriggerId` 通道。

  **百分比的分母 = `CharacterProfile.Status.ChapterLifeSpanBudget`（承重澄清）。** 「剩余寿元跨篇章结转」使寿元没有固定分母；若拿「本章增量」（100 / 100 / 300）作分母，省着花的玩家在第二篇章一开局就可能超过 100%，阈值含义随之漂移。**ChapterManager 在篇章边界把「结转后的可用预算」冻结为该字段**，百分比一律以它为分母（见 `life-cycle-service.md`）。

  **回滞（hysteresis）：每档带进入阈值与退出阈值。** 没有回滞，一个在阈值上反复 ±3 震荡的道心值会把「稀缺才有分量」直接毁掉。**退出阈值 = 进入阈值向常态方向放宽 δ**（写「向常态方向」而非「减」，才对双臂属性成立）；δ 初值：**道心 / 煞气 = 4**（≈ 档宽的 20%）· **寿元 = 3 个百分点**。**代价明写：档位不再是当前值的纯函数 ⇒ 必须持久化「当前所处档」**（`CharacterProfile.Status` 上的三个 band 字段），这是本机制唯一新增的存档结构。**回滞与「下行不播」各管一半**：方向规则挡的是「上去又下来又上去」里的**下来那一次**，回滞挡的是**在同一条阈值线上反复上行**（62 → 58 → 63 会连播两次同一档文案）。
  Source: 同上。

- **跨档叙事文案：挂档位、不挂事件；走内容层；只挂极值档（已定案 · 08-12d）。**

  - **挂档位定义**（每档一组固定候选文案），**不随触发它的事件而变**。三条理由：① 08-10b 的同类先例（Finale 补白）就挂在**状态转换**上、与触发它的事件无关；② 挂事件是 `事件数 × 属性数 × 档数 × 方向` 的组合爆炸（一章 30 事件 × 3 属性 × 2 方向 = 180 条），内容侧不可维护；③ 挂事件会泄露事件与属性的精确映射（「做这件事 → 播这句话」），与「学到方向与因果、学不到精确数值」的边界擦得太近。**局部保留的可能**：日后确需时可在少数标志性事件上加一条覆盖 `Id`，不改本结构。
  - **每档 2–3 条候选，等概率随机取一**（沿用 08-10b）。**随机源不带种子**——只影响呈现、不产生任何玩法结果，故不占 `SeedManager` 子流。
  - **只有一组文案，没有「上行组 / 下行组」之分。** 配合档号方向定义，触发面收敛为「跨入一个 `|BandIndex|` 更大的档」这一种情形；**回到离常态更近的档一律静默**（只更新 band 字段、不播）。
  - **只有极值档配文案。** 道心 / 煞气**各只有最外一档播**，寿元保持既定两档 ⇒ **全库有文案的档 4 个**（道心 `+2` · 煞气 `3` · 寿元 `1` · 寿元 `2`），**寿元是唯一有两个文案档的属性**。三条依据：
    - **体裁定位（承重）。** 本作是 **deck building / turn-based card combat game，不是 visual novel**。叙事是点缀不是载体；「多写几句」与「少写几句」存疑时一律取少。
    - **因果的主要载体是事件文案本身。** 玩家从内容侧（这个事件在描述什么、他选了什么）就能推断抉择的影响——一个「屠戮山门」的选项不需要旁白告诉他煞气涨了。中间档的旁白是**重复信息**，只会稀释极值那一条的分量。
    - **解耦后频次各调各的**：档位密度服务调制分辨率，文案密度服务「稀缺才有分量」。
  - **静默是默认，不用字段声明。** 纪律的可机械检查形态 = 「`|BandIndex| == 该属性的最大档号` 才允许配 `NarrativeIds`，其余档配了 → 加载期 `PushWarning`」。12 档里 8 档静默，为常态设一个必须显式置位的布尔是反向的负担。
  - **常态档（三属性的 Band 0）恒无文案**：没有任何跨入它的路径是「远离常态」。
  - **频次序 = 寿元（每章必来 · 压力计时器）> 煞气 / 道心（打到极端才有 · 里程碑）**：寿元 ≈ 4–6 条 / 轮回、煞气与道心各 ≈ 1–2 条 ⇒ **合计 ≈ 6–10 条 / 轮回**，文案总量 **8–12 条**。一轮回约 86–102 个事件 ⇒ 约每 9–17 个事件一条。
  - **明写的取舍：中间档的跨越对玩家完全无提示**，他只会察觉「摆在面前的事件变了」。这是有意的——**调制才是隐藏属性的主要显影通道，旁白只是极值时刻的一次强调。**
  - **退让位（不是待答项）**：日后若实测觉得太闷，按顺序放宽——① 煞气 Band 2 → ② 道心 `+1` → ③ 才考虑道心下臂。**每一步都只是加内容条目，结构 / 字段 / schema 全不动。** 但**第一旋钮是 `HiddenStatGrade` 的映射值**（见 `systems/balance.md`）——它同时也在改调制的推进速度，比加文案更贴近「让这条线动起来」的真实诉求；**档数永远不是该动的旋钮**。
  Source: 同上。

- **档位与文案的内容形态（已定案 · 08-12d）。** 档位是内容条目 `HiddenStatBandData : Resource`（进 ContentRegistry、有自己的仓储）：

  ```csharp
  [GlobalClass]
  public partial class HiddenStatBandData : Resource
  {
      [Export] public string     Id             { get; set; }  // "plot.band.faith.2"
      [Export] public HiddenStat Stat           { get; set; }  // Faith | MaleficQi | LifeSpan
      [Export] public int        BandIndex      { get; set; }  // 带符号：0 = 常态，|值| 越大越远离常态
      [Export] public int        EnterValue     { get; set; }  // 该档朝常态一侧的边界；LifeSpan 以百分点书写
      [Export] public int        Hysteresis     { get; set; }  // δ，退出阈值 = EnterValue 向常态方向放宽 δ
      [Export] public string[]   NarrativeIds   { get; set; }  // 跨入本档的候选文案；只有极值档允许非空
      [Export] public string     PlotTriggerId  { get; set; }  // 可空：跨入即起剧情线
      [Export] public bool       ContentEnabled { get; set; } = true;   // 恒 true，见下
  }
  ```

  - **文案正文单独成条目**（复用 Finale 补白要用的那个定性文案类型），本类只持 `Id` 数组——与「快照 / 结构里不存字符串正文」的既有分层一致，也让文案与档位可各自热更。
  - `HiddenStat` 是枚举 `{ Faith, MaleficQi, LifeSpan }`（API 表已在用这个类型名）。
  - **热更边界（承重）：阈值 / δ / 文案可线上改，档数不可线上增减**（overlay 只改不增 ⇒ 加一档必须发版）。这正是取值域取有界的原因。
  - **档位条目恒启用，文案条目照常参与放量。** 档位解析走**全量视图**、不经 `AllEnabled()` 抽取池——判据是 content-service 的既定不对称（**过滤只在产出侧**，而档位判定是**查表读取**）；关掉一档会在档位表上造出空洞、触发假跨档。故 `HiddenStatBandData.ContentEnabled == false` → 加载期 **`PushError`**；文案条目不受此限（每档 2–3 条候选，关一条只是少一个候选），秒关一条措辞的运营手段因此保留。
  - **overlay 改阈值后的对齐：** 热更后首次 `eventEnd` 时若存档 band 与按新阈值算出的档不符 → **直接对齐、不播叙事**、`PushWarning` 留痕。否则一次数值热更会给全体在线玩家批量假跨档。

  **加载期校验**（`.claude/rules/data-resource-rules.md` 的「坏数据在启动时大声失败」）：

  | 违规 | 处置 |
  |---|---|
  | 某 `HiddenStat` 的 `BandIndex` 不连续 / 有重复 / 缺常态档 `0` | `PushError` + 抛（带 `Stat` + 缺失的 index） |
  | `EnterValue` 沿档号方向非单调，或 δ 使两档的进出区间交叠 | `PushError`（带两档 `Id`） |
  | `NarrativeIds` 指向不存在的文案条目 | `PushError`（带悬空 `Id`）——它不是剧本 key point，不适用悬空降级 |
  | **非极值档配了 `NarrativeIds`** | `PushWarning` 逐条列出（静默是默认，不需要字段声明） |
  | 某 `Stat` 的极值档 `NarrativeIds` 为空 | `PushWarning`（漏配。**道心下臂 `-2` 是明写例外**） |
  | **文案正文含属性名 / 阿拉伯数字 / 档位序号** | `PushWarning` + 逐条列出——「不给数字」纪律的可机械检查形态，同 `IgnoresProtection` 的清单式软检查 |
  | `HiddenStatBandData.ContentEnabled == false` | `PushError` |
  Source: 同上。

- **Finale「失败但存活」的叙事补白落在本 manager 的叙事层（已定案 · 08-10b · 答结 08-09b 的遗留待答）。** 约 1% 的情形里渡劫失败也能完成篇章、突破境界（见 `systems/adventure-event/finale/_index.md`），「渡劫 = 突破到下一境界」因此需要一句让「失败也能突破」读起来不像笔误的文案。**落点是本处而非 `ux/screen-flow.md`**：它与上方「跨档给定性叙事」是同一类东西——**一句由状态转换触发的定性文案**，走同一条落点（`ResolveOutcome` → `eventEnd` 阶段），**不新增结构**。

  文案两版：

  ```
  「劫败而身存，破境亦有缺。」
  「以败换境，以伤换生。」
  ```

  - **择取规则 = 等概率随机二选一（已定案）**，不按篇章 / 隐藏属性分化。
  - **文案属内容层（已定案）** —— 走 `res://content/` 基线 + overlay，可热更。**自 08-11 剧本正文亦属内容层**，故本 manager 内部不再有「云端 / 本地」两类文本之分：两者同经 ContentRegistry 读取，差别只在 **overlay 对剧本条目可新增 `Id`、对定性文案条目照旧只改不增**（见 `content-service.md`）。
  - **推论：随机源不必带种子。** 二选一只影响呈现、不产生任何玩法结果，故不属于「不用未加种子的 `GD.Randi()` 决定玩法结果」的约束面，也不需要占用 `SeedManager` 的子流。
  - **承重的边界：这句补白讲的是「失败也能突破」，绝不能暗示道统残卷。** 08-09b 定的「失败侧不给任何文案 / 暗示 / 进度条 / 百分比」对残卷仍然成立——两条文案里没有任何一个字指向掉落概率，这是它们能落地的前提。
  Source: `handoffs/2026-08-10b-grant-source-and-fragment-source-scoping.md`。

- **寿元 / lifeSpan = 递减的寿命预算。** 炼气起始 **100**、抵达筑基 **+100**、抵达金丹 **+300**、抵达元婴 **+500**（累计 1000；但元婴即游戏终点，该增量**不产生可消耗预算**，只是最后一次数值更新并存档——见 `systems/balance.md`）；**剩余寿元跨篇章结转**（下一篇章预算 = 该章增量 + 上一章剩余，见 `life-cycle-service.md`）。**每完成一个 AdventureEvent 按其 `lifeSpanCost` 扣减寿元**（内容侧为正数量值、物化时取负；`lifeSpanCost` 是 `selectCost` 复合成本类型的一个 element，见 `systems/adventure-event/common-properties.md`）；**递减到 0 → 触发「大限将至」→ 角色 defeated**。寿元是**独立于 `life`** 的寿命数值。Source: `handoffs/2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md` + `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。
- **寿元告警两段式（已定案 · 取代「只有 10% 红字」）。** **初始隐藏 → 进入 30% 给一条定性叙事提示 → 进入 10% 转为红字数值倒数。** 原因：对 100 点的第一篇章预算而言，10% 才告警**太晚，来不及做战略调整**；30% 的定性提示给出一个可行动的提前量，同时不破坏「数值隐藏」。呈现位置仍是 **EventOption 选择界面的静态标注**，见 `ux/screen-flow.md`。Source: `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md`。

- **CharacterProfile 只存 key points；剧本内容属本地内容层（已定案 · 08-11 · 反转 07-25c 的分界）。** `CharacterProfile` 上记录 AdventurePlot 的 **key points（关键节点 / 进度锚点）**；**完整的剧本与分支内容不落存档**，而是作为**内容条目**存于 `res://content/` 基线 + `user://overlay/`，经 **ContentRegistry** 按 `Id` 读取。**没有云端剧本服务，也没有逐事件的剧本请求**——剧本文本在事件发生之前就已在盘上。

  **撤销云端剧本服务的理由（承重）：**
  - 「剧本在云端」此前**从未被论证**：07-23 是纯断言；07-25c 的判据「按进度动态请求、不被存档引用 → 云端」是**描述性、近乎循环**的——「动态请求」是那个选择的*结果*，被当成了它的*理由*。**没有任何 Accepted ADR 覆盖剧本归属**（ADR-0003 管存档 / 账号权威，不涉剧本文本），故本次不推翻任何 ADR。
  - 它是**唯一让 manager 跨进程边界的成分**。移走后跨边界成分 **4 → 3**，且全部是服务本身 ⇒ **「manager 不跨边界」成为无例外的结构性事实**。
  - 它带来的复杂度**整条消失**：事务前置、`user://cache/plot/` LRU 预取、延迟预算、超时兜底、断网降级文案——全是「逐事件向云端请求文本」的派生物。
  - 后端少一个服务、少一份协议：`IPlotBackend` / `PlotRequest` / `PlotSegment`（字段本就 ⟨待定⟩）**整套作废**。
  - 前提：**剧本是预写式内容库**（非运行时生成——运行时生成无法本地化，密钥 / 成本 / 内容审核都必须在服务端）；**剧透 / datamine 被接受**，与 `content-service.md` 已定的「不承诺防作弊」边界同调（纯 PvE，提取只损失提取者自己的体验）。
  Source: `handoffs/2026-08-11-plot-content-localization.md`。

- **overlay 对剧本条目可新增 `Id`（「只改不增」的唯一例外 · 已定案 · 08-11）。** `content-service.md` 的「overlay 只改不增」纪律**唯一**的存在目的是关死「旧客户端存档引用到未知内容」这一风险；而剧本文本恰是内容类别里**唯一不被存档引用**的一类，故为它放开新增 `Id` **不重新引入那条纪律要防的风险**。**收益 = 新剧情可热更不发版**——原云端剧本服务提供的正是这项能力，现由 overlay 通道提供，且不需要运行时请求。例外的两条边界（只覆盖剧本类型本身、新增剧本条目不得引用本次 overlay 之外的新 `Id`）见 `content-service.md`。

- **悬空 key point → `PushWarning` + 叙事降级，不阻塞轮回（已定案 · 08-11 · 承重）。** key points 是**指向剧本结构的持久化锚点**，所以「剧本不被存档引用」只对**文本**成立、对**节点**不成立：玩家在带新剧本 arc 的 overlay 下存了 key point，随后 overlay 或客户端版本回退 ⇒ key point 悬空。这是本地化唯一新生的风险，也是它能成立的前提（此前该风险不存在，是因为云端服务负责解析 key point）。

  **处置：** key point 引用的剧本节点在合并结果中不存在 → `GD.PushWarning` 带上悬空的 key point 标识 → **跳过该段叙事以及该分支对 eventOptions 的调制** → **轮回照常继续**，`CharacterProfile` 不因此进入任何异常态。

  - **与既有原则同构：** 这就是 content-service 那条**「读取侧不过滤」不对称**（产出侧按 `ContentEnabled` 过滤、`Get(id)` 不过滤，使存档引用到已关闭条目仍能解析）在剧本侧的对应形态。
  - **代价明写：** 玩家会**静默失去一段剧情与它带来的调制**。这被接受——剧本调制是塑造倾向而非硬性玩法结算，缺一段不会让轮回不可继续。
  - **反向约束 key points 的 schema：** key point **必须能在其引用的剧本节点缺失时被安全跳过**，不得设计成「解析失败即无法确定当前剧本位置」的形态。这是那条待答项（粒度 / schema）的新前置条件。
  Source: 同上。

- **`pastEvent` 是本 manager 的只读输入，与 key points 零结构耦合（已定案 · 08-09c · 承重）。** **`pastEvent` 不持有任何 key point 引用；key points 也不引用 `PastEventEntry`。**
  - **边界依据（08-11 换了论据，结论不变）：** key points 是**指向内容侧剧本节点**的进度锚点，而 `InstanceId` / `Seq` 是客户端物化时随手生成的**存档运行时标识**。把后者塞进 key point，等于让**可热更的剧本内容条目隐式依赖存档的 `InstanceId` 空间**——内容与存档形态就此耦合，一侧变动即破坏另一侧。**且它会直接破坏悬空降级规则**：key point 必须能被独立解析、缺失时安全跳过，而挂上 `InstanceId` 后它的可解析性就取决于存档里那条痕迹是否还在。（原论据是「不让云端剧本服务依赖客户端存档标识空间」；剧本本地化后跨进程那一层消失，但上述两条使结论原样保住。）
  - **不需要新链路：** `ModulateEventOptions(CharacterProfile c, EventOptionBatch batch)` 已经拿到整个 `CharacterProfile`，`pastEvent` 就在其中。读选择偏好是一次**服务内 manager 对宿主数据的只读访问**，不跨任何边界，也不新增方法。
  - **派生索引不落存档：** 「每类事件走过几次」「每 location 走过几次」这类聚合为**读时计算**（n ≈ 200，一次线性扫描，非每帧热路径）或本 manager 内的内存缓存，**不作为存档字段**——存了就有两份真相，迁移与重放时必然对不齐。
  - **可读出的信号有两条：** 「选了什么」（`PastEventEntry` 本体）与「同批还摆着什么而没选」（`Unchosen` 轻摘要）。后者是跳过通道移除后回避信号的新形态。
  - **推论：`pastEvent` 的 schema 不被「key points 粒度」这个待答项阻塞，两者各自定稿。**
  Source: `handoffs/2026-08-09c-past-event-trace-schema.md`。
- **剧本读取没有网络失败路径（08-11 · 取代「事务前置 + LRU 预取」）。** 剧本内容随 `res://` 基线与 overlay 一并落地，读取是一次纯内存的 ContentRegistry 查找 ⇒ **不存在「取不到剧本」这一失败态**，因此：
  - **事务前置整条不再必要**（它防的是「扣了成本却没剧情」这种由网络失败造成的半状态）；
  - **`user://cache/plot/` 与 LRU 预取整条作废**——没有要缓存的远端响应；
  - **`sync-service.md` 降级表中的「剧本请求」一行随之删除**；剩下的两条降级通道（push / pull）与剧本无关。
  - **唯一残留的缺失情形是悬空 key point**，走上方的 `PushWarning` + 叙事降级，**不是失败路径**。
  Source: `handoffs/2026-08-11-plot-content-localization.md`。

### event / EventData（剧本内容侧）
- **event = 剧本内容单元。** 承载**提示文本以及分支式的选择 / 结果**；AdventurePlot 负责结构模型，event 内容侧负责具体剧本文本与分支。event 内容是**本地内容条目**（`res://` 基线 + overlay，经 ContentRegistry 按 `Id` 读取），由 key points 定位。
- **隐藏属性驱动剧情线（三条 · 08-12d 由两条扩为三条）：**
  - **煞气 / malefic qi** —— 跨入 Band 3（75+）→ 触发 **「煞气反噬」** 剧情线（经 `PlotTriggerId`）。
  - **道心 / faith** —— 跨入 Band `−2`（0–19）→ 触发 **「心魔滋生」** 剧情线（经 `PlotTriggerId`）。**该档无叙事文案**，剧情线与调制是它唯一的显影通道。
  - **寿元 / lifeSpan** —— 递减到 0 → 触发 **「大限将至」**（角色 defeated）。**它对应终态而非任何一档**，不经 `PlotTriggerId` 通道。
  Source: `handoffs/2026-08-12d-hidden-stat-bands-and-crossing-narrative.md`。

## 管理器角色 / API 面（契约）
> _总则与共享类型见 `systems/architecture.md`「API 契约总则」。**本 manager 纯本地，永不跨进程边界，故全部方法为形态 A**（08-11 剧本本地化后；此前它是全项目唯一跨边界的 manager）。Source: `handoffs/2026-07-27b-service-api-contracts.md` + `handoffs/2026-08-11-plot-content-localization.md`。_

- **定位。** PlotManager 是**剧本内容的解析器**（按 key points 从 ContentRegistry 定位剧本节点）+ **eventOptions 的调制源**。它**不直接写 eventOptions**、也不向 game-progression / UI 暴露 eventOptions——对外呈现 eventOptions 的**唯一出口是宿主服务 future-event-service**。
- **类型声明为 `internal sealed`**（总则 3）：跨服务代码里根本写不出本 manager 的类型名。

| 方法 | 形态 | 完整签名 | 失败语义 |
|------|------|----------|----------|
| 解析剧本 | A | `bool TryResolvePlot(CharacterProfile c, out PlotSegment segment)` | **悬空 key point → `PushWarning` + 返回 `false`**，调用方跳过该段叙事与调制、轮回继续（不是失败路径） |
| 调制 | A | `EventOptionBatch ModulateEventOptions(CharacterProfile c, EventOptionBatch batch)` | 无调制 = 原批返回 |
| 档位驱动 | A | `void OnHiddenStatThreshold(CharacterProfile c, HiddenStat stat)` | — |
| 选分支 | A | `OpResult ChooseBranch(string branchId)` | 业务失败 → `OpResult`；经 ProfileManager 推进 key points |

- **形态 B → A 是本地化的直接推论**（`systems/common-properties.md`：形态 B 的定义就是「跨客户端 ↔ 后端边界」，形态 B / C 带 `Async` 后缀、形态 A 不带）。原 `ResolvePlotAsync` 的取不到语义由 `TryResolvePlot` 的 `bool` 承载——它对应「可选但缺失 → 警告 + 安全默认值」，而非「必需但缺失」。
- **`PlotSegment` 的字段 ⟨待定⟩**，依赖「剧本内容类型的数据形态」这条待答项。**原 `PlotRequest` 不再需要**（无远端请求，key points 直接来自传入的 `CharacterProfile`）。

**只有 `ChooseBranch` 投影到服务门面上。** 前三个方法是宿主服务 `ComputeEventOptions` 物化链条**内部**的一环，不被跨服务调用（manager 纪律）；`ChooseBranch` 因需要玩家输入，故由 future-event-service 以同名方法转发。

**没有后端接口（08-11）。** 总则 7 的四个窄后端接口中，`IPlotBackend`（连同 `HttpPlotBackend` / `OfflinePlotBackend` 与 `BackendSelector.CreatePlot()`）**整套作废**——**总则 7 由四接口降为三接口**，条件编译清单由 6 处降为 **5 处**（见 `system-overview.md`）。本 manager 只经宿主服务读 ContentRegistry。

**事件面：** 剧情线触发经宿主服务广播 `PlotThresholdReached(string CharacterId, HiddenStat Stat, int BandIndex)`；分支揭示 / 选择、key point 推进同样由**宿主服务**代为广播（manager 不直接持有 EventBus 通道）。
- **负载末位由 `Threshold` 改名为 `BandIndex`（08-12d）**：它传的从来不是那个阈值数值，而是「跨进了第几档」；`OnHiddenStatThreshold` 的方法名沿用不改。
- **数据契约：** CharacterProfile 存 key points（轻量锚点，**必须可独立解析、缺失时可安全跳过**）；剧本内容是本地内容条目（不落存档，经 ContentRegistry 读）；**档位表是内容条目 `HiddenStatBandData`，当前所处档持久化在 `CharacterProfile.Status` 的三个 band 字段上**（见「意图」与 `systems/character-profile/_index.md`）。

## 决策(-> ADR)

- **剧本内容属本地内容层 · overlay 对剧本可新增 `Id`**（08-11，反转 07-25c 的本地 / 云端分界判据，撤销云端剧本服务）→ 已定案，**ADR 候选**（宜与 content-service 的「内容载体形态」候选合并固化）。Source: `handoffs/2026-08-11-plot-content-localization.md`。
- **降为 future-event-service 内部的 manager** → 已定案（层级词表见 `systems/architecture.md`），**ADR 候选**。Source: `handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md`。
- **跨档叙事挂档位不挂事件 · 档位是内容条目且档数不可热更增减**（08-12d）→ 已定案，**ADR 候选**（宜与 content-service 的「内容载体形态」候选合并固化）。Source: `handoffs/2026-08-12d-hidden-stat-bands-and-crossing-narrative.md`。
- **强制在线 · 云端权威（`decisions/ADR-0003-online-cloud-authority.md`，Accepted）原样成立**，本 manager 不再依赖它——剧本本地化改的是内容载体，不是账号 / 存档模型。

## 待决问题

- **数据编码与 key points 粒度（08-09c 收窄 · 08-11 新增前置约束）：** AdventurePlot 树如何用数据表达？它是**调制** eventOptions，还是并行结构？key points 的粒度与 schema？两条硬约束：**①** 不得以「让 key point 引用 `InstanceId`」的形态回答（零结构耦合，见「意图」；本条因此**不阻塞 `pastEvent` 定稿**）；**② 08-11 新增：key point 必须能在其引用的剧本节点缺失时被安全跳过**——不得设计成「解析失败即无法确定当前剧本位置」的形态，否则悬空降级规则不成立。Source: `handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md` + `handoffs/2026-08-09c-past-event-trace-schema.md` + `handoffs/2026-08-11-plot-content-localization.md`。
- **剧本内容类型的数据形态（08-11 新增）。** 剧本条目是一种 `XxxData : Resource`（进 ContentRegistry、有自己的仓储），还是别的载体？若进 ContentRegistry，合并后强校验对它生效，则**「新增剧本条目不得引用本次 overlay 之外的新 `Id`」这条约束需要一个可机械检查的形态**——按 `systems/architecture.md`「纪律的可执行化」的选级判据，它属**能上线且线上不可见**（漏检即线上悬空引用），应做到阶梯第 1 / 2 级，而非仅约定。Source: 同上。
- **剧本内容的体积与分发粒度（08-11 新增）。** 三篇章的完整剧本树随包 + overlay 会有多大？是否需要按篇章分包 / 按进度增量下载（复用 manifest 的文件级事务即可，但**分包边界**未定）。原云端方案的「按需请求」天然回避了这个问题，本地化后它变成一个真实的包体 / 下载量问题。Source: 同上。
- **DnD 式选分支：** 触发点、UI、以及玩家可见 / 不可见分支的边界未定。
- **隐藏属性清单与推拉触发：** 已定 **道心 / 煞气 / 寿元** 三项且均隐藏，**取值域、档位表、阈值与回滞已于 08-12d 定案**（见「意图」）；仍待定：是否还有其他隐藏属性、**增减触发（哪些 AdventureEvent 推拉、各推哪一档 `HiddenStatGrade`）**、每条剧情线的具体内容与 key points。（寿元消耗已定；仅剩「是否有非境界突破的寿元增长途径」待定——它只影响寿元回升路径是否存在，**回升 = 档号减小 = 静默**，答任一侧都不改结构。）→ 亦见 `life-cycle-service.md`、`systems/balance.md`。
- **`HiddenStatGrade` 的三个映射值随 ch1 数值标杆专场校准（08-12d 新增）。** 初值 `Minor 2 / Standard 5 / Major 10` 与「每属性每篇章跨档 2–4 次」是**反推验收项，不是死数字**，其校验依赖上一条的「增减触发」。**档位结构、阈值形态、文案形态、呈现形态均不被它阻塞**——它约束的是标定，不是结构。→ `systems/balance.md`。Source: `handoffs/2026-08-12d-hidden-stat-bands-and-crossing-narrative.md`。

## 对应
提炼至：`.claude/knowledge/systems/plot-manager.md`（引用层，待建）。
