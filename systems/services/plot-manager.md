# PlotManager（管理器 · 隶属 future-event-service）

> 隐藏剧本管理器：剧本层级（Story / Chapter / SideChapter / SideStory 四级）、隐藏属性驱动（道心 / 煞气 / 寿元）、CharacterProfile 上的 key points、剧本内容的本地解析、eventOptions 调制。
> **它是 manager 而非 service**：生活在 `future-event-service` 内部，共享其事务边界与生命周期，**不被跨服务直接调用**。
> **本 manager 纯本地，永不跨进程边界。** 剧本内容属本地内容层（`res://` 基线 + overlay），经 ContentRegistry 读取。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **AdventurePlot = 隐藏剧本层。** 一棵由**分支可能性**构成的树，在背景中运行、**调制 future-event-service 产出的 eventOptions**（见 `future-event-service.md`、`systems/game-progression.md`）。玩家通常看不到它，但它持续塑造后续会变为可用的 AdventureEvent；部分节点可像 **DnD** 那样让玩家**显式选择分支**。

- **剧本层级（四级）。**

  | 层级 | 英文 / 代码 | 范围 |
  |------|------------|------|
  | 主线剧本 | AdventurePlot-Story | 贯穿**三大篇章**相连的大剧本（一条完整主线） |
  | 篇章剧本 | AdventurePlot-Chapter | **单个篇章**对应的剧本单元（一个 Story 含三个 Chapter） |
  | 支线（篇章内） | AdventurePlot-SideChapter | 在**单个 Chapter 内**穿插的小型支线 |
  | 支线（跨篇章） | AdventurePlot-SideStory | **跨篇章**穿插的支线 |

  即：三个 **Chapter** 相连组成一个 **Story**；Chapter 内可穿插 **SideChapter**，跨 Chapter 可穿插 **SideStory**。

- **隐藏属性驱动。** 属性模型借鉴 **Reigns** 但**反其道：属性隐藏、不作可见仪表**。隐藏属性（**道心 / faith**、**煞气 / Bloodlust**、**寿元 / lifeSpan**）**跨入某个带 `PlotTriggerId` 的档位**时触发对应剧情线。隐藏属性落在 `CharacterProfile.Status`（见 `life-cycle-service.md` 与 `systems/character-profile/`）；由 AdventureEvent 推拉，一切写入经 `profile-service.ProfileManager`。

- **跨档给定性叙事反馈（数值仍隐藏）。** 数值继续隐藏，但**当某个隐藏属性跨过一个隐藏档位时，给一条定性的叙事描述**——**给方向与因果，不给数字**：

  ```
  道心 ↑ 跨档：  「你于静室枯坐三日，心念澄明。」
  煞气 ↑ 跨档：  「你的指节泛起一层洗不去的暗红。」
  寿元 进入 30%：「鬓角新添的白发，你已数不清是第几根。」
  ```

  - **只在跨档时触发**（每个隐藏属性分若干**隐藏档位**，档位表见下条），**不是每次结算都播**——稀缺才有分量。
  - **落点 = 已有的 `ResolveOutcome` → `eventEnd` 阶段，无新结构**（见 `systems/adventure-event/common-properties.md`）。
  - **设计意图：** 玩家学到**方向与因果**（做这类事会推高煞气），学不到**精确数值**，因此**无法做电子表格式优化**。这正是本作对 Reigns 张力的替代路径——Reigns 靠**可见**仪表制造权衡，本作靠**可感知但不可测量**。

- **一套档位模型统一五个消费方（承重）。** 「跨过一个隐藏**档位**」与「达**阈值**时触发剧情线」**是同一件事**：剧情线触发 = 跨入某个带 `PlotTriggerId` 的档。一张档位表同时回答五个问题，不需要五套判定：

  | 消费方 | 用到几档 | 说明 |
  |---|---|---|
  | **eventOptions 调制**（本 manager 的主业） | **全部档** | 档位是调制的粒度：煞气 1 档与 2 档就该抽出不同风味的事件池。**这是档位表存在的首要理由。** |
  | **剧情线触发** | 带 `PlotTriggerId` 的档（3 个） | 煞气反噬 / 心魔滋生 / 大限将至 |
  | **跨档叙事文案** | **只有极值档（4 个）** | 见下方「文案只挂极值档」 |
  | **寿元红字标注** | 寿元 Band 2 | 既定（见 `ux/screen-flow.md`） |
  | **`selectCost` 精确展示** | 寿元 Band 2 | 与红字标注**同一个开关、同时开启**：Band 0 / Band 1 完全不显示成本，Band 2 如实展示精确扣减量。规则与代价见 `systems/adventure-event/common-properties.md`（权威）。**这是本表复用性的又一个实例——不新增字段、不新增流程。** |
  | **回寿数字展示** | 寿元 Band 2 | 与上两条**同一个开关、同时开启**：Band 0 / Band 1 只给定性文案（eventOption 收益标注 / 道具描述 / 结算面板寿元行），Band 2 才给精确 `+n`。**只封成本侧不封产出侧等于给寿元量纲留后门，而回寿是一次性的大数、更适合被当作标尺。** 规则与代价见 `systems/adventure-event/common-properties.md`（权威）。 |

  **12 档的分辨率有真实消费者，不是先于内容而定的空结构（承重）。** 首要消费方 eventOptions 调制的作用面是**全覆盖的**——**所有事件都有可能推拉这三个隐藏属性，不限事件类型**（Combat / Exchange / Research / Explore / Travel 五类无一例外）。故调制需要的分辨率是真实的，12 档 + 回滞 δ + 3 个存档字段这套结构成立。
  - **硬度 = 允许，不是强制。** 取消的是「只有某几类事件才能推拉隐藏属性」这道结构性限制；**具体哪一条内容推哪个属性、推哪一档 `HiddenStatGrade`，仍是逐条目的内容编排决策，不填 = 不推**。内容层的字段核对清单据此写：`HiddenStatGrade` 是**可选**字段,对全部事件类型开放。

  **隐藏属性对五类事件的输入与输出两侧全开（承重）。** 产出侧即上述 `HiddenStatGrade`；**输入侧**同样对五类一律开放，由两条**既有**通道承载，**不新增机制、不新增字段**：

  | 通道 | 形态 | 适用面 |
  |---|---|---|
  | **调制通道（主）** | Band 触发 arc → `PlotModulation` 六字段（`TypeWeights` / `EventWhitelist` / `EventWeights` / `EnemyPoolScope` / `LevelBias` / `Tighten`） | 五类一律 |
  | **结算输入通道** | 事件的数据驱动 outcome 求值读取隐藏属性当前值作为**输入项之一** | 五类一律（Combat 侧经 `EncounterSpec` 的既有可调字段体现） |

  - **承重边界：输入侧全开**不**等于把隐藏属性接进胜负判定。** `VictoryRule` 仍是**单字段**（`WinMargin` 一个数），不做可替换的判定对象、无需策略枚举、无需分发。隐藏属性影响一场遭遇的路径是**拧参数**（更凶的敌人模板、更高的敌人赋级、更差的起手），不是**加一条并列的判定条件**。例：煞气 Band 3 触发的 arc 用 `EnemyPoolScope` 换更凶的天劫模板、用 `LevelBias` 把赋级推向带上沿；道心 Band −2 的 arc 同理。
    - **`Tighten` 对 `Finale` 整档豁免**（`Tier == Finale` → 跳过整个 `Tighten` 的施加，不是错误、不告警）—— **剧本要加压 Finale，只能走敌人侧的两个字段**。`Tighten` 对 `Practice` / `Standard` 仍有真实效果（`WinMargin` 1 → 2 是有意义的加压），故该字段不是死结构。详见下方「`EncounterTighten`」。
  - **「输入」不含「作为 `selectCost` 消耗」。** 隐藏属性**不进成本侧**：成本侧只放**可如实计价的量**（Band 2 精确展示纪律的全部目的是让玩家自己算出「这一步可能是最后一步」，而隐藏量玩家永远算不出那一格——与「能力 element 恒不出现在 `selectCost`」是同一条判据的第二个实例）；且它**没有消费者**——道心 / 煞气触底不构成终态、截断到 `[0, 100]`，扣了不产生任何可判定的后果。`selectCost` 的 element 清单因此仍只有 `lifeSpanCost` 一项。

  **关键的解耦：档多 ≠ 文案多。** 玩家感知到「这条线在动」主要来自**摆在他面前的事件变了**（调制），而不是来自一句旁白。**档数不随文案收窄而减**——砍中间档等于砍掉调制的分辨率，是拿主业去迁就点缀。

  **档号方向（承重）：`BandIndex` 越高 = 越远离常态，而不是「数值越大」。** 「下行不播叙事」若读成「数值下降不播」，寿元既定的 30% 提示（它本身就是数值下降触发的）会被字面废掉。统一定义为「离常态的距离」后，**触发规则对三属性完全一致：`|newBand| > |oldBand|` 才播，反向静默**——不需要方向字段，也不需要为寿元开特例。

- **取值域与档位表。**

  **道心 faith：`[0, 100]`，轮回起始 `50`，双向推拉**（它是「状态」：心境澄明 ↔ 心魔渐生）。**煞气 Bloodlust：`[0, 100]`，轮回起始 `0`，以上行为主、可被净化类事件下拉**（它是「累积物」，既定的「累积到阈值触发煞气反噬」直接对应最高档）。**施加后截断到 `[0, 100]`，不构成终态**（与寿元不同）——两者的区间与终态语义与其余资源 element 同形，逐条写在 `ResourceElements` 表里，见 `systems/services/profile-service.md`。

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

- **跨档叙事文案：挂档位、不挂事件；走内容层；只挂极值档。**

  - **挂档位定义**（每档一组固定候选文案），**不随触发它的事件而变**。三条理由：① 同类先例（「渡劫身死」文案）就挂在**状态转换**上、与触发它的事件无关；② 挂事件是 `事件数 × 属性数 × 档数 × 方向` 的组合爆炸（一章 30 事件 × 3 属性 × 2 方向 = 180 条），内容侧不可维护；③ 挂事件会泄露事件与属性的精确映射（「做这件事 → 播这句话」），与「学到方向与因果、学不到精确数值」的边界擦得太近。**局部保留的可能**：日后确需时可在少数标志性事件上加一条覆盖 `Id`，不改本结构。
  - **每档 2–3 条候选，等概率随机取一。****随机源不带种子**——只影响呈现、不产生任何玩法结果，故不占 `SeedManager` 子流。
  - **只有一组文案，没有「上行组 / 下行组」之分。** 配合档号方向定义，触发面收敛为「跨入一个 `|BandIndex|` 更大的档」这一种情形；**回到离常态更近的档一律静默**（只更新 band 字段、不播）。
  - **只有极值档配文案。** 道心 / 煞气**各只有最外一档播**，寿元保持既定两档 ⇒ **全库有文案的档 4 个**（道心 `+2` · 煞气 `3` · 寿元 `1` · 寿元 `2`），**寿元是唯一有两个文案档的属性**。三条依据：
    - **体裁定位（承重）。** 本作是 **deck building / turn-based card combat game，不是 visual novel**。叙事是点缀不是载体；「多写几句」与「少写几句」存疑时一律取少。
    - **因果的主要载体是事件文案本身。** 玩家从内容侧（这个事件在描述什么、他选了什么）就能推断抉择的影响——一个「屠戮山门」的选项不需要旁白告诉他煞气涨了。中间档的旁白是**重复信息**，只会稀释极值那一条的分量。
    - **解耦后频次各调各的**：档位密度服务调制分辨率，文案密度服务「稀缺才有分量」。
    - **玩家侧的理解由题材常识兜底（承重）。** 四档文案之所以够用，是因为它**依赖玩家对修仙题材的基础设定认知**——道心低了会入魔、煞气高了会反噬、寿元将尽是大限——这些不需要本作教。**中间档的沉默不是信息缺口，是常识已经填上的部分。** 由此，「文案只挂四档」是设计意图的正面表述,而不是「覆盖不足、待补」的临时状态。
  - **静默是默认，不用字段声明。** 纪律的可机械检查形态 = 「`|BandIndex| == 该属性的最大档号` 才允许配 `NarrativeIds`，其余档配了 → 加载期 `PushWarning`」。12 档里 8 档静默，为常态设一个必须显式置位的布尔是反向的负担。
  - **常态档（三属性的 Band 0）恒无文案**：没有任何跨入它的路径是「远离常态」。
  - **频次序 = 寿元（每章必来 · 压力计时器）> 煞气 / 道心（打到极端才有 · 里程碑）**：寿元 ≈ 4–6 条 / 轮回、煞气与道心各 ≈ 1–2 条 ⇒ **合计 ≈ 6–10 条 / 轮回**，文案总量 **8–12 条**。一轮回约 86–102 个事件 ⇒ 约每 9–17 个事件一条。
  - **明写的取舍：中间档的跨越对玩家完全无提示**，他只会察觉「摆在面前的事件变了」。这是有意的——**调制才是隐藏属性的主要显影通道，旁白只是极值时刻的一次强调。**
  - **退让位（不是待答项）**：日后若实测觉得太闷，按顺序放宽——① 煞气 Band 2 → ② 道心 `+1` → ③ 才考虑道心下臂。**每一步都只是加内容条目，结构 / 字段 / schema 全不动。** 但**第一旋钮是 `HiddenStatGrade` 的映射值**（见 `systems/balance.md`）——它同时也在改调制的推进速度，比加文案更贴近「让这条线动起来」的真实诉求；**档数永远不是该动的旋钮**。

- **档位与文案的内容形态。** 档位是内容条目 `HiddenStatBandData : Resource`（进 ContentRegistry、有自己的仓储）：

  ```csharp
  [GlobalClass]
  public partial class HiddenStatBandData : Resource
  {
      [Export] public string     Id             { get; set; }  // "plot.band.faith.2"
      [Export] public HiddenStat Stat           { get; set; }  // Faith | Bloodlust | LifeSpan
      [Export] public int        BandIndex      { get; set; }  // 带符号：0 = 常态，|值| 越大越远离常态
      [Export] public int        EnterValue     { get; set; }  // 该档朝常态一侧的边界；LifeSpan 以百分点书写
      [Export] public int        Hysteresis     { get; set; }  // δ，退出阈值 = EnterValue 向常态方向放宽 δ
      [Export] public string[]   NarrativeIds   { get; set; }  // 跨入本档的候选文案；只有极值档允许非空
      [Export] public string     PlotTriggerId  { get; set; }  // 可空：跨入即起剧情线
      [Export] public bool       ContentEnabled { get; set; } = true;   // 恒 true，见下
  }
  ```

  - **档位文案的正文单独成条目**（与「渡劫身死」文案共用那个定性文案类型），本类只持 `Id` 数组——与「快照 / 结构里不存字符串正文」的既有分层一致，也让文案与档位可各自热更。**这条只对档位叙事成立，不推广到剧本正文**：档位文案拆条目是因为每档 2–3 条候选可等概率取一、可单独关掉；剧本节点的正文是一对一、不可替换、与节点同生同灭的，且定性文案类型照旧只改不增（见下方「剧本正文内嵌在节点上」）。
  - `HiddenStat` 是枚举 `{ Faith, Bloodlust, LifeSpan }`（API 表已在用这个类型名）。
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

- **「渡劫身死」的定性文案落在本 manager 的叙事层。** Finale 失败即角色终结（见 `systems/adventure-event/combat/_index.md`），这是本作叙事上最重的一刻，值得一句专属的定性文案，而不是与「寿元耗尽」共用一句通用死亡文案。**落点是本处而非 `ux/screen-flow.md`**：它与上方「跨档给定性叙事」是同一类东西——**一句由状态转换触发的定性文案**，走同一条落点（`ResolveOutcome` → `eventEnd` 阶段），**不新增结构**。

  - **一条文案，不做随机二选一**，也不按篇章 / 隐藏属性分化——终结只发生一次，分化没有可感知的收益。
  - **文案属内容层** —— 走 `res://content/` 基线 + overlay，可热更。**剧本正文同属内容层**，故本 manager 内部没有「云端 / 本地」两类文本之分：两者同经 ContentRegistry 读取，差别只在 **overlay 对剧本条目可新增 `Id`、对定性文案条目照旧只改不增**（见 `content-service.md`）。
  - **承重的边界：它讲的是「劫下身死」，绝不能暗示道统残卷。** 残卷在失败侧**不给任何文案 / 暗示 / 进度条 / 百分比**——而失败恰恰是残卷累积发生的那一刻，这条边界因此比在别处更吃紧。

- **`Practice` 档战斗失败的定性文案走「力竭负伤 / 自愧不如」的口径。** 与「渡劫身死」同属本叙事层、同一条落点（`ResolveOutcome` → `eventEnd`），**不新增结构**。
  - **它承担的是一条机制上不打算解决的张力：** `Practice` 被定位为「比试 / 切磋——点到为止」，而失败仍按道念差 1:1 全额扣 `lifeTotal`（理论上可致角色终结）。**不为它给 `lifeTotal` 加折扣系数**——1:1 的价值恰恰在于它没有例外，开一档就要论证另两档为何不开，而「落后 N 点 = 输了掉 N 点」这条通用刻度一旦分档，玩家的心算账本随之分叉。张力因此落在叙事措辞上：写力竭、写自愧，**不写「败于同门之手身受重创」**。
  - **不为该口径新增档位 / 字段 / 校验**，它是文案写作口径而非结构。规则侧的完整依据见 `systems/adventure-event/combat/_index.md`。

- **寿元 / lifeSpan = 递减的寿命预算。** 炼气起始 **100**、抵达筑基 **+100**、抵达金丹 **+300**、抵达元婴 **+500**（累计 1000；但元婴即游戏终点，该增量**不产生可消耗预算**，只是最后一次数值更新并存档——见 `systems/balance.md`）；**剩余寿元跨篇章结转**（下一篇章预算 = 该章增量 + 上一章剩余，见 `life-cycle-service.md`）。**每完成一个 AdventureEvent 按其 `lifeSpanCost` 扣减寿元**（内容侧为正数量值、物化时取负；`lifeSpanCost` 是 `selectCost` 复合成本类型的一个 element，见 `systems/adventure-event/common-properties.md`）；**递减到 0 → 触发「大限将至」→ 角色 defeated**。寿元是**独立于 `lifeTotal`** 的寿命数值。
- **寿元告警两段式。** **初始隐藏 → 进入 30% 给一条定性叙事提示 → 进入 10% 转为红字数值倒数。** **不要只在 10% 处给一次告警**：对 100 点的第一篇章预算而言那太晚，来不及做战略调整；30% 的定性提示给出一个可行动的提前量，同时不破坏「数值隐藏」。呈现位置是 **EventOption 选择界面的静态标注**，见 `ux/screen-flow.md`。

- **CharacterProfile 只存 key points；剧本内容属本地内容层。** `CharacterProfile` 上记录 AdventurePlot 的 **key points（关键节点 / 进度锚点）**；**完整的剧本与分支内容不落存档**，而是作为**内容条目**存于 `res://content/` 基线 + `user://overlay/`，经 **ContentRegistry** 按 `Id` 读取。**没有云端剧本服务，也没有逐事件的剧本请求**——剧本文本在事件发生之前就已在盘上。

  **不设云端剧本服务的理由（承重）：**
  - 判据「按进度动态请求、不被存档引用 ⇒ 归云端」是**描述性、近乎循环**的——「动态请求」是那个选择的*结果*，不能当成它的*理由*。**没有任何 Accepted ADR 把剧本判给云端**（ADR-0003 管存档 / 账号权威，不涉剧本文本）。
  - 剧本一旦上云，它就是**唯一让 manager 跨进程边界的成分**；留在本地，跨边界成分全部是服务本身 ⇒ **「manager 不跨边界」是无例外的结构性事实**。
  - 云端一侧要背一整套复杂度：事务前置、`user://cache/plot/` LRU 预取、延迟预算、超时兜底、断网降级文案——全是「逐事件向云端请求文本」的派生物。
  - 后端也因此少一个服务、少一份协议（无 `IPlotBackend` / `PlotRequest` / `PlotSegment`）。
  - 前提：**剧本是预写式内容库**（非运行时生成——运行时生成无法本地化，密钥 / 成本 / 内容审核都必须在服务端）；**剧透 / datamine 被接受**，与 `content-service.md` 已定的「不承诺防作弊」边界同调（纯 PvE，提取只损失提取者自己的体验）。

- **overlay 对剧本条目可新增 `Id`（「只改不增」的唯一例外）。** `content-service.md` 的「overlay 只改不增」纪律**唯一**的存在目的是关死「旧客户端存档引用到未知内容」这一风险；而剧本文本恰是内容类别里**唯一不被存档引用**的一类，故为它放开新增 `Id` **不重新引入那条纪律要防的风险**。**收益 = 新剧情可热更不发版**，且不需要运行时请求。例外的两条边界（只覆盖剧本类型本身、新增剧本条目不得引用本次 overlay 之外的新 `Id`）见 `content-service.md`。

- **悬空 key point → `PushWarning` + 叙事降级，不阻塞轮回（承重）。** key points 是**指向剧本结构的持久化锚点**，所以「剧本不被存档引用」只对**文本**成立、对**节点**不成立：玩家在带新剧本 arc 的 overlay 下存了 key point，随后 overlay 或客户端版本回退 ⇒ key point 悬空。这是剧本留在本地所带的唯一风险，处置好它正是该形态能成立的前提。

  **处置：** key point 引用的剧本节点在合并结果中不存在 → `GD.PushWarning` 带上悬空的 key point 标识 → **跳过该段叙事以及该分支对 eventOptions 的调制** → **轮回照常继续**，`CharacterProfile` 不因此进入任何异常态。

  - **与既有原则同构：** 这就是 content-service 那条**「读取侧不过滤」不对称**（产出侧按 `ContentEnabled` 过滤、`Get(id)` 不过滤，使存档引用到已关闭条目仍能解析）在剧本侧的对应形态。
  - **代价明写：** 玩家会**静默失去一段剧情与它带来的调制**。这被接受——剧本调制是塑造倾向而非硬性玩法结算，缺一段不会让轮回不可继续。
  - **反向约束 key points 的 schema：** key point **必须能在其引用的剧本节点缺失时被安全跳过**，不得设计成「解析失败即无法确定当前剧本位置」的形态。这是那条待答项（粒度 / schema）的新前置条件。

- **`pastEvent` 是本 manager 的只读输入，与 key points 零结构耦合（承重）。** **`pastEvent` 不持有任何 key point 引用；key points 也不引用 `PastEventEntry`。**
  - **边界依据：** key points 是**指向内容侧剧本节点**的进度锚点，而 `InstanceId` / `Seq` 是客户端物化时随手生成的**存档运行时标识**。把后者塞进 key point，等于让**可热更的剧本内容条目隐式依赖存档的 `InstanceId` 空间**——内容与存档形态就此耦合，一侧变动即破坏另一侧。**且它会直接破坏悬空降级规则**：key point 必须能被独立解析、缺失时安全跳过，而挂上 `InstanceId` 后它的可解析性就取决于存档里那条痕迹是否还在。
  - **不需要新链路：** `ModulateEventOptions(CharacterProfile c, EventOptionBatch batch)` 已经拿到整个 `CharacterProfile`，`pastEvent` 就在其中。读选择偏好是一次**服务内 manager 对宿主数据的只读访问**，不跨任何边界，也不新增方法。
  - **派生索引不落存档：** 「每类事件走过几次」「每 location 走过几次」这类聚合为**读时计算**（n ≈ 200，一次线性扫描，非每帧热路径）或本 manager 内的内存缓存，**不作为存档字段**——存了就有两份真相，迁移与重放时必然对不齐。
  - **可读出的信号有两条：** 「选了什么」（`PastEventEntry` 本体）与「同批还摆着什么而没选」（`Unchosen` 轻摘要）。后者是跳过通道移除后回避信号的新形态。
  - **推论：`pastEvent` 的 schema 不被「key points 粒度」这个待答项阻塞，两者各自定稿。**
- **剧本读取没有网络失败路径（承重）。** 剧本内容随 `res://` 基线与 overlay 一并落地，读取是一次纯内存的 ContentRegistry 查找 ⇒ **不存在「取不到剧本」这一失败态**。因此下列几样东西**都不要建**：
  - **不设剧本的事务前置**（它防的是「扣了成本却没剧情」这种由网络失败造成的半状态，而这里没有网络失败）；
  - **不设 `user://cache/plot/` 与 LRU 预取**——没有要缓存的远端响应；
  - **`sync-service.md` 的降级表里没有「剧本请求」一行**；降级通道只有 push / pull 两条，与剧本无关。
  - **唯一残留的缺失情形是悬空 key point**，走上方的 `PushWarning` + 叙事降级，**不是失败路径**。

- **剧本树不按篇章分包：三篇章的完整剧本树整体随 `res://` 基线发布，更新走 overlay 的文件级增量热更**（`[采纳推荐 — 待复核]`）。不按 `PlotArcData.ChapterScope` 分包、不按 `PlotTier` 分包、不把正文外置只分包正文。**采纳结果是零机制增量**：manifest 不加字段、`manifestSchema` 不提升、`ContentUpdateManager` 不加运行时下载路径、不新增第三处硬阻塞、`PlotArcData` / `PlotNodeData` / `PlotKeyPoint` schema 全不动、不新增任何失败语义或降级分支；后端零参与（服务端不感知内容类别，报文无变化）。

  **承重理由三条：**

  - **分包与「合并后全量强校验」在结构上冲突（最重的一条）。** 下方「剧本条目的加载期校验」是**全量**的：四类悬空校验 + 层级校验 + 可达性 / 含环校验 + `PlotTriggerId` 双向校验。某一包未下载时，跨包引用当场悬空 ⇒ 启动即 `PushError` + 抛。要让分包成立只有三条路，每条都在拆一件承重件：① 放宽剧本侧悬空校验为 `PushWarning` ⇒ 一个真的编排错误与一个「这个包还没下」在日志里长得一模一样；② 给剧本条目造第三种状态「未下载」⇒ 内容层出现既非「存在」也非「不存在」的态，立刻传染到 `Get(id)` / `AllEnabled()` / `newIds` 双闸 / 悬空 key point 降级四处；③ 让边界切在「无跨包引用」处 ⇒ 但 Story arc 按定义贯穿三篇章、`SideStory` 按定义跨篇章、`PlotTriggerId` 按定义跨到档位表——**跨包引用不是可以避开的编排问题，是剧本层级模型本身的形状。**
  - **强制在线消解的是分包的收益侧。** 玩家启动即须登录 + 跑一次 pull（两处硬阻塞）⇒ 必然处在有网环境；「让用户先玩起来、剩下的慢慢下」这条离线优先产品的核心动机在本作没有对应场景。反过来，分包会造出一个既有设计里不存在的失败态：「推进到第 2 篇章却没网」在不分包下完全无害（剧本在盘上，见上一条「剧本读取没有网络失败路径」），在分包下要么成为第三处硬阻塞，要么成为「整章剧本静默缺席」——后者正是悬空 key point 降级把爆炸半径限制在「不阻塞**其余**剧本线」时要避免的那种放大。
  - **量级不成立。** 剧本文本落在包体的**百分之一量级**（未压缩 MB 级、落地增量不足 1 MB，约等于一首 BGM，而引擎基线与卡面美术都是数十 MB 级）。为百分之一的收益买一整套分发机制是净亏。此外 overlay 侧**本就已是文件级增量下载**，本题真正问的只剩「随包基线要不要拆」——热更侧的增量能力早已有了。

  **明写的代价（被接受）：** 初装包永远包含全部三篇章的剧本文本，包括玩家可能永远打不到的第 3 篇章。这笔浪费换来「剧本读取没有网络失败路径」这条结构性事实无例外地成立。

  **复核闸（零成本，不是待答项）：** 第二阶段第一批真实剧本条目写完后，实测 `res://content/plot-arc/` + `plot-node/` 的字节总和与应用总包体之比；**仅当占比与绝对值双双越过届时设定的门槛时**才重开分包讨论。留这道闸是因为上述结论是一个**相对**结论，它依赖「美术 / 音频确实是数十 MB 级」这个前提——包体预算若被定成一个极小的数（如小游戏平台的首包限制），要重算。两个门槛值待实测时再定。护栏形态止于**在 `content/plot-arc/_index.md` 与 `content/plot-node/_index.md` 的条目台账记一行「条目数 + 字节总和」**，**不加加载期校验**（那需要定两个当前没有依据的数字）；两个类型档案尚未开张，本项随开张落地。

  **方向性记录：真要缩初装包，落点是平台原生按需资源，不是 manifest 分包。** Android Play Asset Delivery / iOS On-Demand Resources 是**发行侧的打包配置**，不碰 manifest schema、不碰文件级事务的单一提交点、不碰 `LoadAll()` 的一次性合并；平台自己承担下载、缓存、驱逐、续传与失败重试；且它天然选中的资产是美术与音频而非剧本文本——**真到了那天，要拆的也不是剧本树。** 这与 `content-service.md`「不为每日种子 / 排行挑战预留冻结结构，但把正确做法记一句」是同一种纪律：不预留结构，但留下路标，免得将来因为「manifest 已经现成」而回退全局决策。本条**不在后端库留承接**——发行侧配置后端零参与、报文零变化。

### 剧本树的数据形态

- **树 = 纯调制，没有并行结构（承重）。** AdventurePlot **不产出任何事件，也不持有任何事件序列**；它是 `ComputeEventOptions` 物化链条内部的一个加权 / 框定输入，与 location 框定、map 子流并列。三条既定纪律各自独立地封死并行结构：**唯一物化点 + 唯一出口**（并行结构意味着剧本自己能把事件摆到玩家面前 = 第二个出口）· **事件之间不存在预先编好的前后连边**（剧本树若持有事件序列，它就是一张被编好的连边图，只是换了个地方存）· **只调内容不调约束**（「这一步你必须去某处」的唯一手段是把候选池收窄，那是调制语言的一条算子，不是另一套结构）。
  **推论：剧本树的「节点」不是事件，是一组调制参数 + 一段可选叙事 + 一组出边。** 玩家永远不会「进入一个剧本节点」，他只会**察觉摆在面前的事件变了**（与档位表「调制才是隐藏属性的主要显影通道」同构）。

- **剧本内容 = 两个内容类型 `PlotArcData` + `PlotNodeData`。** 各进 ContentRegistry、各有自己的仓储，形态与 `HiddenStatBandData` / `LocationData` 同族。

  ```csharp
  [GlobalClass]
  public partial class PlotArcData : Resource
  {
      [Export] public string        Id             { get; set; }  // "plot.arc.story.ashen_lineage"
      [Export] public PlotTier      Tier           { get; set; }  // Story | Chapter | SideChapter | SideStory
      [Export] public string        ParentArcId    { get; set; }  // Chapter → 所属 Story；其余可空
      [Export] public string        EntryNodeId    { get; set; }  // 入口 PlotNodeData
      [Export] public string        PlotTriggerId  { get; set; }  // 可空：与 HiddenStatBandData.PlotTriggerId 对接
      [Export] public int[]         ChapterScope   { get; set; }  // 允许存活的篇章；空 = 不限（SideStory）
      [Export] public string[]      CharacterIds   { get; set; }  // 可空：限定角色模板；空 = 任意角色
      [Export] public string        ExclusiveGroup { get; set; }  // 可空：同组 arc 一次轮回内至多激活一条
      [Export] public bool          ContentEnabled { get; set; } = true;
  }

  [GlobalClass]
  public partial class PlotNodeData : Resource
  {
      [Export] public string          Id             { get; set; }  // "plot.node.ashen_lineage.03"
      [Export] public string          ArcId          { get; set; }  // 所属 arc（冗余存一份，供加载期反查校验）
      [Export] public LocalizedText   Body           { get; set; }  // 可空 = 纯调制节点，无叙事
      [Export] public PlotModulation  Modulation     { get; set; }  // 可空 = 纯叙事节点，无调制
      [Export] public PlotEdge[]      Edges          { get; set; }  // 空 = 终止节点（arc → Completed）
      [Export] public bool            ContentEnabled { get; set; } = true;  // 恒 true，见下
  }
  ```

  - **为什么是两个而不是一个：** arc 与 node 的**激活面完全不同**——arc 由 `PlotTriggerId` / 篇章边界激活（一次），node 在 arc 存活期间被反复推进（多次）；且 key points 的粒度落在 arc 上，一个类型无法同时当锚点和当步骤。
  - **为什么不是四个（每级一个类型）：** 四级的差别只在**激活范围与并发规则**，字段集合完全相同。四个类型会让「解析一个 arc」需要四条分支，而层级是一个枚举就能表达的东西。
  - **`CharacterIds` 让「主线是否与角色绑定」两种取向都能承载**（空数组 = 全局主线，填值 = 角色专属），故本形态**不被「角色模板池形态」那条待答项阻塞**——日后定哪一侧都只改内容不改 schema。
  - **两个类型的放量语义相反，判据是「结构身份优先于抽取身份」：**
    - **`PlotArcData` 照常参与 `AllEnabled()` 与 flags 通道**——arc 是**被激活抽取**的（激活是产出侧决策），关一条只让它**不再被新激活**；**已在 key points 里的 arc 照常经 `Get(id)` 解析**（读取侧不过滤），不会因线上关闭而悬空。收益是一条 overlay 热更推上去的坏 arc 可秒关。
    - **`PlotNodeData` 恒启用**，`ContentEnabled == false` → 加载期 `PushError`，与 `HiddenStatBandData` 同款判据：节点是**被 key point 查表定位**的结构，关掉一个中间节点只会在树上造出空洞、让一条正在进行的 arc 卡死。**放量的正确粒度是 arc，不是 node。**
    - 后端侧 flags 通道对这一分野的对应表述见 `backend-design-documents/contracts/content-manifest.md`「剧本文本」一节。

- **剧本正文内嵌在节点上（`PlotNodeData.Body`），不复用定性文案条目、不单列文本类型。** 两条理由：① **热更权限相反**——定性文案条目属「被存档引用」类、照旧只改不增，而剧本例外的全部收益就是「新剧情可热更不发版」；若剧本正文寄生其上，overlay 新增一条 arc 时**写不出它的正文**，例外当场失效。② **拆条目的动机在剧本侧不存在**（见上方档位文案一条），拆开只买到一层 `Id` 间接与一处新的悬空可能。
  `LocalizedText` 的既有语义原样适用（`zh` 缺失 → `PushError`；`en` 缺失 → 静默回落 + 覆盖率审计；overlay 改文案 / 补语言键不算新增 `Id`）。
  **连带（承重）：一条新 arc = 若干 `PlotNodeData` + 一个 `PlotArcData`，全部是剧本类型**，不需要新增任何非剧本 `Id` 就能自足——这正是「新增剧本条目不得引用本次 overlay 之外的新 `Id`」能被机械检查且不误伤正常内容编排的前提（闸形态见 `content-service.md`）。

- **`PlotModulation` 的字段集合 = PlotManager 权力面的逐条投影，不多一个字段。**

  ```csharp
  [GlobalClass]
  public partial class PlotModulation : Resource
  {
      [Export] public EventTypeWeight[] TypeWeights    { get; set; }  // 事件类型权重的乘性系数（软框定）；缺省行 1.0
      [Export] public string[]          EventWhitelist { get; set; }  // 非空 = 候选池收窄到这些 EventId
      [Export] public EventWeight[]     EventWeights   { get; set; }  // 单条 AdventureEventData 权重的乘性系数；缺省行 1.0
      [Export] public string            EnemyPoolScope { get; set; }  // 一个 PlotArcData.Id：框定该 arc 的专属 EnemyData 池
                                                                      // （对上 PoolScope.PlotArcId），通常填本 arc 自己的 Id
      [Export] public int               LevelBias      { get; set; }  // 带内赋级权重偏移；不改 ±2 带边界
      [Export] public EncounterTighten  Tighten        { get; set; }  // 可空：拧紧遭遇参数（五格，见下）
  }
  ```

  **`EncounterTighten` = 五格带方向约束的增量，不是绝对覆写值。**

  ```csharp
  [GlobalClass]
  public partial class EncounterTighten : Resource   // 内嵌子资源：无 Id、无 ContentEnabled，不进 ContentRegistry
  {
      [Export] public int TurnLimitDelta   { get; set; } = 0;   // 恒 <= 0：只减回合，不加回合
      [Export] public int WinMarginDelta   { get; set; } = 0;   // 恒 >= 0：只抬门槛，不降门槛
      [Export] public int InitialDrawDelta { get; set; } = 0;   // 恒 <= 0：只减起手，不加起手
      [Export] public int DrawPerTurnDelta { get; set; } = 0;   // 恒 <= 0：只减每回合抽牌，不加
      [Export] public int HandLimitDelta   { get; set; } = 0;   // 恒 <= 0：只压手牌上限，不抬
  }
  ```

  三格牌流量的基准 = `EncounterSpec` 的可空覆写组（起手抽牌数 / 每回合抽牌数 / 手牌上限），**字段名以 `systems/services/combat-service.md` 的 `EncounterSpec` 为形状权威**；十个界常量的取值住 `systems/balance.md`。

  - **取增量而非绝对覆写值：** 一条 arc 在 `Active` 期间对**整批**候选生效，而这批里的 Combat 可能物化成 `Practice`（`TurnLimit 8`）也可能是 `Standard`（`10`）。绝对值意味着内容作者必须**在写 arc 时就知道它会撞上哪一档**——写 `9` 对 `Standard` 是收紧、对 `Practice` 是放宽，还得再补一条「不许放宽」的钳制。增量对三档一致，且**与 `LevelBias` 同一种语言**：那一格之所以是 bias 而非绝对等级，正是因为基准值逐次不同，这里的基准值（档位默认回合数）同理。
  - **方向由符号约束焊死，而不是靠字段名提醒。** `Tighten` 的语义是**单向**的：剧本可以加压，不能放水——放水的正确形态是换一个更宽的 `combatTier`，那是模板侧的编排，剧本够不着。写成带符号 delta + 加载期方向校验，使「只能收紧」成为**内容层根本写不出反例**的形态，是「越权的写法在内容层没有字段可填」那条纪律的一次延伸。
  - **字段面止于这五格，判据两条连用：** ① 上方「新增一格物化字段时是否跟着加一格」的落面判据；② **该格上必须存在一个全序 + 一个单调难度方向**，否则「更紧」写不出来。`Enemy`（引用）、`Tier`（枚举，序不是难度序）、`FirstSide`（二值且无难度序）连「哪边更紧」都表达不出；`RewardPoolId` / `BaseReward` 落产出侧（剧本改产出的正确形态是 `EventWeights` 抬高另一条内容条目的权重）；疲劳量没有覆写基准可拧（见 `systems/balance.md`）。
  - **`Tier == Finale` 整档豁免**（跳过整个 `Tighten`，不是错误、不告警）。增量形态下「`WinMargin` 恒 `0` 所以拧不动」**并不自动成立**——`0 + 2 = 2` 是有效果的，恒 `0` 需要被显式保护。落成一条 tier 闸而非逐格例外，是因为一条闸同时挡住三格牌流量对**不可逆终局**的调制：`Finale` 失败即角色终结，把玩家不可见的调制接进不可逆判定，与「隐藏属性影响遭遇是拧参数」的可接受度不在同一档。
  - **`EncounterTighten` 本身不进 `EncounterSpec`、不落存档。** 它是物化期的一个输入，施加完即消失；落存档的是**施加后的五格定值**。combat-service 只见 `EncounterSpec`，不该知道剧本存在 ⇒ 本机制对存档 schema 零改动、零迁移。

  ```csharp
  [GlobalClass]
  public partial class EventTypeWeight : Resource
  {
      [Export] public EventType Type       { get; set; }
      [Export] public float     Multiplier { get; set; } = 1.0f;   // 乘性系数；恒 > 0，不设 Travel 例外
  }

  [GlobalClass]
  public partial class EventWeight : Resource
  {
      [Export] public string Id         { get; set; }              // AdventureEventData.Id
      [Export] public float  Multiplier { get; set; } = 1.0f;      // 乘性系数；恒 > 0
  }
  ```

  **两个权重字段一律是乘性系数，与 location 的类型修正、与赋级带的「调制修正（乘性，只改权重不改支撑集）」同一种权重语言。** 同一段物化管线里两个相邻字段语义相反是纯粹的漂移源：加性的恒等元是 0、乘性是 1，`.tres` 里读不出作者想的是哪一种。
  **剧本侧连 0 都不给**（恒 `> 0`，不设 Travel 例外）：剧本要表达「这一段不出某类事件」的正确形态是 `EventWhitelist` 收窄候选池——那是既定的、唯一的剧本强制性表达位。

  | 既定权力 | 承载字段 |
  |---|---|
  | 影响哪些事件进池、以什么权重出现 | `TypeWeights` · `EventWeights` |
  | 剧本强制性 = 把候选池收窄 | `EventWhitelist` |
  | 框定用哪个敌人池 | `EnemyPoolScope` |
  | 偏移带内赋级权重 | `LevelBias` |
  | 拧紧遭遇参数 | `Tighten` |
  | 抬 `eventPriority` | **无字段**——写不出来 |
  | 改 `eventCountLimit` / 地域配额 | **无字段**——落约束面，且开放它等于借道内容字段间接抬 `eventPriority`（语义与代价见 `systems/game-progression.md`） |
  | 改模板字段 / 改敌人卡组 / 改 item·power 列表 | **无字段**——同上 |

  **多条 `Active` arc 的合并算子（逐字段，同时最多四条）：**

  | 字段 | 合并算子 | 缺省（= 不参与） |
  |---|---|---|
  | `TypeWeights` | **相乘**（Π 各 arc 的系数） | 缺省行 1.0，恒等元 |
  | `EventWeights` | **相乘** | 同上 |
  | `EventWhitelist` | **非空者取并**；全部为空 = 不收窄 | 空数组 |
  | `EnemyPoolScope` | **取并**（arc 一侧传全部 `Active` arc 的集合） | 空串 |
  | `LevelBias` | **相加**，合并后作用于带内权重 | 0 |
  | `Tighten.TurnLimitDelta` | **取 `min`**（最负者 = 砍得最狠；恒 `<= 0`） | `0`，恒等元 |
  | `Tighten.WinMarginDelta` | **取 `max`**（最大者 = 门槛抬得最高；恒 `>= 0`） | `0`，恒等元 |
  | `Tighten.InitialDrawDelta` | **取 `min`**（恒 `<= 0`） | `0`，恒等元 |
  | `Tighten.DrawPerTurnDelta` | **取 `min`**（恒 `<= 0`） | `0`，恒等元 |
  | `Tighten.HandLimitDelta` | **取 `min`**（恒 `<= 0`） | `0`，恒等元 |
  | `Tighten`（整体） | 全为 `null` → `null`；否则逐字段按上五行合并，`null` 参与者视同全 `0` | null |

  - **权重相乘的三条理由：** ① 恒等元是 1 ⇒ 缺省行不需特判（相加时「不修正」要写 0、「翻倍」要写 +100%，两种语义混在同一个数组里，`.tres` 里读不出作者想的是哪一种）；② 相加会让两条 arc 的调制**全有全无地互相湮灭**（arc A 写 `+3`、arc B 写 `-3`，合并后回到基础值，两条线都在「显影」而玩家什么也感知不到），与「排队不丢弃：触发恒定成立，只是延后」正面冲突；③ 与赋级带的「调制修正（乘性）」同构。**正系数下湮灭是连续的而非全有全无**——任一条 arc 单独把某类推高都不会被另一条推成 0。
  - **白名单取并的三条理由：** ① 两条不同剧情线的 `EventWhitelist` 是两组不相交的 `EventId`，**取交为空是常态而非异常**，而空候选池是既定的「坏数据 → `PushError` + 抛」——一次完全正常的内容编排（煞气 arc 与心魔 arc 同时 `Active`）会把游戏打崩；② 取交让一条 arc **静默取消**另一条的强制性，与「触发恒定成立」同一条纪律相抵；③ 可读性的护栏已由 `MaxConcurrentSideArcs = 2` 与 `ExclusiveGroup` 架好，合并算子不需要再承担一次同样的职责。
  - **取并的代价明写（被接受）：** 多条 arc 同时收窄时，每条的强制性被稀释为「本批必出这些线之一」而非「本批只出我这条线」。**要表达独占，正确形态是 `ExclusiveGroup`**（同组至多一条 `Active`），那正是它存在的理由；把独占性塞进白名单合并算子等于制造第二个 `ExclusiveGroup`。
  - **顺带的收益：不存在取交 ⇒ 管线上少一条「白名单收窄后候选池为空」的失败路径**，也不需要发明「空交集则回退取并」的兜底分支。
  - **`Tighten` 五格取极值而不是相加：** 四条 `Active` arc 各写 `TurnLimitDelta = -1`，相加即 `-4`——`Practice` 的 8 回合掉到 4，把节奏旋钮打穿；对 `DrawPerTurnDelta` 更致命（每回合抽 2 相加两条 `-1` 即归零，牌流量断供），而没有任何一条 arc 的作者意图如此。取极值使**加压幅度的上界 = 单条 arc 写得出的最紧值**，内容评审逐条看得住；这与白名单取并那条「护栏由 `MaxConcurrentSideArcs` 与 `ExclusiveGroup` 架好，合并算子不必再承担一次同样职责」同向。
  - **五格里四格取 `min`、一格取 `max`，差别只在方向常量而非算子族**：三格牌流量与回合数同属「少 = 更难」，`WinMargin` 是唯一「多 = 更难」的格。五个恒等元一律 `0`，与相乘那两格的 `1.0` 各自成立——不修正的写法在两种语言里都是「不填」，`.tres` 里读不出歧义。
  - **`min` / `max` 幂等、可交换、可结合** ⇒ 合并顺序不是需要裁决的量（与「乘法可交换 ⇒ location 与 arc 谁先不必定」同构），且**合并算子与施加算子同构**——先合并再施加与逐条施加取最紧，结果相同。**与 `LevelBias` 互不影响**，两者先后同样不是需要定的量。
  - 这些算子在物化管线里的落位（第几步生效、与 location 修正如何相乘、归一化在哪里发生、`Tighten` 的施加与钳制落在哪一步）见 `future-event-service.md` 的十步管线；**乘法可交换 ⇒ location 与 arc 的先后不是需要定的量。**

  **`EnemyPoolScope` 是一个 `PlotArcData.Id`，加载期校验悬空：非空且不在 `PlotArcData` 仓储内 → `PushError`**（带 arc `Id` + 节点 `Id` + 悬空值）。它对上敌人条目一侧的 `PoolScope.PlotArcId`（形态见 `systems/enemies/_index.md`）。**字段允许填入别的 arc 的 `Id`，这是一条有意保留的权力**——把它降级为「隐式取本 arc」会在同时最多四条 `Active` arc 的结构里失去定义；代价（填错只会换个池子）由这条悬空校验从「静默」变为「大声」。

  **新增一格物化字段时是否跟着加一格，只看它落在哪一面（判据）：** 落**内容面**（哪些条目进池、以什么权重出现、用哪个敌人池、带内赋级权重、遭遇参数）→ **已有字段够用**；落**约束面或模板字段面** → **不加字段**，这正是「越权的写法在内容层根本没有字段可填」要保住的东西。**有了这条判据，字段面不必随物化清单每次增长再逐格复核一遍。**

  按此判据核过当前的物化格：产出侧的定稿载体属**模板 outcome 定义的物化产物**，给剧本一个字段去改它等于开「改模板字段」的口子——剧本要改产出，正确形态是用 `EventWeights` 抬高另一条**内容条目**的权重（换池，不改内容）；`SelectCost` 是成本侧、隔着遮罩改定价等于动全局时长旋钮；`Priority` 在上表里明写无字段；Travel 的目的地与出场概率、Research 候选池、Exchange 库存同理，均落在约束面或「换池才是唯一合法表达位」的那一侧。

  **NPC 与势力也由这张表承载，不新增第七个字段。** 「投靠了甲就进不了乙的线」= `PlotArcData.ExclusiveGroup`；「该势力的事件更常出现」= `EventWhitelist` / `EventWeights`；「坊市多交易」= location 的事件类型出现概率修正。**不建 `NpcData` / `FactionData`，不设好感 / 关系度数值**——好感度若有持久数值它就是第四个隐藏属性（牵动 12 档档位表、`Status` 字段与枚举迁移），而**一条 arc 的进度本来就是「关系走到哪一步」的离散表达**，与「给方向不给数字」同向。完整论证见 `systems/adventure-event/exchange/_index.md`。

  **剧情线不转入 `Finale`（承重）。** 隐藏属性剧情线（煞气反噬 / 心魔滋生）触发后**不会造出第二个 Finale**，它的高潮由调制表达。四条理由：

  1. **它会当场炸掉残卷的结构封印。** 「每角色每篇章至多累积一次或掷骰一次，且二者互斥」这条不变式的**唯一支撑就是「每篇章一个 Finale」**；剧情线若能造出第二个 Finale，玩家可以靠推煞气 / 掉道心在一个篇章内刷出额外的残卷累积，而「残卷不需要任何额外的冷却 / 次数上限规则」这条豁免会立刻失效（见 `systems/player-profile/player-power/_index.md`）。
  2. **Finale 的出现条件是一条等级条件**（已达本境界巅峰），而剧情线可能在篇章中段触发——此时天劫 `diff = +1` 的自洽性验证不成立，「渡劫 = 突破到下一境界」的叙事随之破裂。
  3. **本 manager 在数据形态上够不着 Finale。** 上表里写不出 `eventPriority`、写不出 `combatTier`、写不出模板的任何字段。**这条不需要新规则来禁止，它已经被数据形态禁止了。**
  4. `decisions/ADR-0004` 以 Finale 为篇章重试的锚点；第二个 Finale 会让「篇章边界」这个概念本身歧义。

  **替代形态 = 一场被 `PlotModulation` 拧过的 `Standard` 档 Combat（零新结构）。** 六个字段刚好凑齐一个「剧情线 boss」：`EventWhitelist`（本批只出这条线的事件）· `EnemyPoolScope`（派心魔 / 煞气化身而非常规敌人）· `Tighten` + `LevelBias`（比常规遭遇更凶）· `TypeWeights` / `EventWeights`（这条线的事件更容易出现）。**代价明写，也正是想要的：剧情线 boss 不给残卷、不是篇章闸门、失败不影响境界突破。** 它是一段风味与压力，不是第二个篇章收口。

  **这是剧本数据面唯一做到可执行化阶梯第 1 级的地方：**「只调内容不调约束」「碰不到模板任何字段」两条承重纪律在这个类型上退化为**内容作者根本写不出那个字段**。`eventPriority` 的置位方唯一 = future-event-service，这条因此不需要任何运行期检查。

- **出边与推进条件。**

  ```csharp
  [GlobalClass]
  public partial class PlotEdge : Resource
  {
      [Export] public string        ToNodeId    { get; set; }
      [Export] public PlotCondition Condition   { get; set; }
      [Export] public LocalizedText BranchLabel { get; set; }  // 非空 = 对玩家可见的 DnD 分支；空 = 后台自动推进
  }
  ```

  | `PlotCondition.Kind` | 参数 | 语义 |
  |---|---|---|
  | `EventResolved` | `EventId` / `EventType` / `EventOutcome` | 完成了符合条件的事件 |
  | `HiddenStatBand` | `HiddenStat` + `BandIndex` + 比较向 | 某隐藏属性到达 / 跨入某档 |
  | `BranchChosen` | —— | 由 `ChooseBranch` 显式选定（`BranchLabel` 非空的边专用） |
  | `ChapterAdvanced` | `Chapter` | 篇章推进到某章 |
  | `EventCount` | `n` | 该 arc 在当前节点已停留 n 个事件（`currentSeq − EnteredAtSeq >= n`） |

  - **出边求值顺序 = 数组顺序，取第一条满足的。** 显式顺序优于「按优先级字段排序」——后者会立刻引出「同优先级怎么办」。
  - **`BranchChosen` 边与自动边不得混在同一节点**（要么这个节点让玩家选，要么它自己走）→ 加载期 `PushError`。
  - **`ChooseBranch(branchId)` 的 `branchId` = 该边的 `ToNodeId`。** 边不另设 `Id`：同一节点内两条分支边指向同一目标是无意义的编排（玩家的两个选择通向同一处 = 一个选择），故 `ToNodeId` 在节点内唯一即可充当分支键 → 加载期对同节点的 `BranchChosen` 边校验 `ToNodeId` 互不相同。

- **key points 粒度 = 每条已激活 arc 一条**，不是每节点一条、也不是全局一个指针。

  ```csharp
  // CharacterProfile 上：IReadOnlyList<PlotKeyPoint> plotKeyPoint;   （单数命名，沿用 pastEvent 风格）
  public sealed record PlotKeyPoint(
      string       ArcId,             // PlotArcData 的稳定 Id
      string       NodeId,            // 该 arc 当前所处节点（PlotNodeData 的 Id）
      PlotArcState State,             // 枚举声明见 systems/architecture.md「共享核心类型」
      int          EnteredAtChapter,  // 进入当前节点时的篇章
      int          EnteredAtSeq       // 进入当前节点时的 pastEvent 时序坐标
  );
  ```

  **粒度判据由悬空降级规则反推，不是体积判据。** 既定纪律要求「key point 必须能被独立解析、缺失时安全跳过」：
  - **全局单指针**（只存「当前剧本位置」）→ 一处悬空即**整个剧本层不可解析**，降级规则在结构上不成立 ⇒ 违反硬约束。
  - **每节点一条痕迹**（记走过的全部节点）→ 满足可跳过，但存档随轮回长度线性膨胀，且走过的路径当前**没有消费方**。
  - **每 arc 一条** → 每条记录自成一个可独立解析的单元；一条悬空只让**那一条剧本线**惰性化，其余 arc 照常调制、照常叙事。**降级从「不阻塞轮回」加强为「不阻塞其余剧本线」。**

  **两条硬约束的满足是显式的：** 记录里**只有内容侧 `Id` 与两个整型坐标，没有任何 `InstanceId`**；`EnteredAtSeq` 用 `pastEvent` 的 `Seq`，沿用 `DisabledAbilityEntry.AppliedAtSeq` 的先例。

  **读档 / 解析校验：**

  | 情形 | 语义 | 处置 |
  |---|---|---|
  | `ArcId` 解析不到 | 可选缺失（overlay / 版本回退） | `PushWarning` + **该条整体惰性**（不调制、不叙事）+ 保留条目，轮回继续 |
  | `ArcId` 在、`NodeId` 解析不到 | 同上 | `PushWarning` + 该条惰性；**不尝试回退到入口节点**——那会让玩家重走一遍已走过的剧情 |
  | `State` 缺失 / 越界 | 必需缺失 | `PushError` 带 `characterId` + `ArcId` |
  | 同 `ArcId` 出现多条 | 不可能态 | `PushWarning` + 保留 `EnteredAtSeq` 最大的一条 |
  | `EnteredAtChapter` > 当前 `chapter` | 不可能态 | `PushWarning` + 按 `Completed` 处理 |

  **保留惰性条目而非删除**：与 `disabledAbility`「空指向条目是无害的幂等残留」同款处置——overlay 回滚后再滚上来，那条线应当能自己复活。

- **推进时点 = 已有的 `eventEnd`，单步推进。**
  - **判定并入隐藏属性 band 写入的同一次 `TryApply`** ⇒「一个事件的收口是一次事务、一个存档点」原样成立，**不新增存档点、不新增结算阶段**。
  - **载体 = `ProfileChangeSpec.PlotElements` 的 `PlotKeyPointAssignment`**（`PlotKeyPoint` 的镜像），语义是按 `ArcId` 的整条 upsert：本 manager 先按剧本图算出「这条 arc 该在哪个节点、什么态」，交给 `ProfileManager` 的是**已算好的绝对状态**；`ChooseBranch` 组装出的同样是一条 `PlotKeyPointAssignment`。施加与失败语义见 `systems/services/profile-service.md`。
  - **「单步推进」的拓扑校验落在本 manager**：新 `NodeId` 必须是当前节点的一条出边或等于当前节点，由推进时的 `#if DEBUG` 断言把关。`ProfileManager` 不持有剧本图的拓扑知识——它只校验 `Id` 可解析 / 不串线 / 同批不重复。越级推进只能由本 manager 自身的缺陷产生，而本 manager 是唯一组装方，故纪律阶梯第 3 级足够；升到入口强校验换来的是分层污染与每次 upsert 一次多余的图查询。
  - **一次 `eventEnd`，每条 arc 至多前进一个节点。** 允许链式推进会让一次结算跑完半条剧本线（若干出边条件恰好同时满足），玩家在一个事件后突然发现候选池换了三轮。单步推进使「剧本推进速度 ≤ 事件推进速度」成为结构性事实。
  - **推进是 key point 的唯一变更方式**；`ChooseBranch` 亦经 `ProfileManager` 写入，不另开写入口。

- **同时激活的 side arc 上限 = `MaxConcurrentSideArcs`（平衡数值，初值 2），超出排队不丢弃。**
  - 只统计 `Tier ∈ { SideChapter, SideStory }` 且 `State == Active` 的 arc；**Story 与 Chapter 各恒有一条，不占配额**（它们是结构不是穿插）。数值住 `systems/balance.md`。
  - **依据：调制是叠加的。** 三条 side arc 同时改类型权重 / 事件权重，候选池会变成谁也说不清的混合物——而调制正是隐藏属性与剧本的主要显影通道。上限保住的是这条通道的可读性。
  - **超出上限 → 排队，不丢弃（承重）。** 丢弃会让 `PlotTriggerId` 触发变成「有时不生效」——一个跨入煞气 Band 3 却什么都没发生的轮回，无法与「机制坏了」区分。排队使触发恒定成立，只是延后。
  - **排队即写 key point：** 触发时立刻写一条 `PlotKeyPoint`（`State = Queued`，`NodeId = EntryNodeId`），出队时改为 `Active`。**队列因此是存档事实而非读时重建物**——道心双向、煞气可被净化下拉，band 回落后「曾跨入触发档」这一事实重算不出来，按判据「重算不出来的存」它必须落存档。形态上**零新增字段**（复用每 arc 一条的既有结构），并发上限的统计口径（只数 `Active`）原样成立。
  - **出队时点 = `eventEnd`**，与 arc 推进同一次判定；一次 `eventEnd` 至多出队一条（与单步推进同款节制）。
  - **`ExclusiveGroup` 先于队列生效**：同组已有 `Active` arc 时，新 arc 直接判为不激活，不进队列。
  - **上限是纯内容侧数值，不改任何结构**——日后实测觉得闷，改 `2` 为 `3` 即可，schema / 字段 / 校验全不动。

- **key points 不持久化已走分支路径。** `PlotKeyPoint` 只记「这条线现在在哪个节点」，不记它是怎么走过来的。
  - **判据「重算不出来的存」有两半，须连用：重算不出来且有消费方。** 分支选择确实重算不出（它是玩家输入），但路径当前**没有任何消费方**——调制只读当前节点、叙事只读当前节点、推进只读当前节点。
  - **日后确需（角色履历展示「你在这条线上选了什么」）的落点是 `PastEventEntry`，不是 key point。** 选分支本就发生在某个事件里，记进那条事件痕迹比在 key point 上另开一个随轮回长度线性增长的数组更贴近既有分层（`pastEvent` 只追加、已有 `Unchosen` 轻摘要这一先例）。
  - **代价明写：** 在补上那个字段之前，**已结束的轮回无法回顾分支选择**——补记是补不回来的。这被接受：履历展示不在中期路线图内，而每条 key point 上挂一个无人读的数组会先付出存档体积与 diff 噪音的代价（`CharacterProfile` 是 sync-service 的既定 diff 单位）。

- **剧本条目的加载期校验**（合并后强校验，走 `AllIncludingDisabled()`）：

  | 违规 | 处置 |
  |---|---|
  | `PlotArcData.EntryNodeId` / `ParentArcId` / `PlotNodeData.ArcId` / `PlotEdge.ToNodeId` 悬空 | `PushError` + 双方 `Id` + 抛 |
  | `PlotNodeData.ArcId` 与「从该 arc 入口可达」不一致（孤儿节点 / 串线节点） | `PushError` + `Id` |
  | 从 `EntryNodeId` 出发的可达图**含环** | `PushError` + 环上 `Id` 序列（剧本树是树，环会让单步推进永不终止） |
  | 存在**不可达节点** | `PushWarning` + 逐条列出（多半是编排遗漏，不阻塞） |
  | `Tier == Chapter` 而 `ParentArcId` 为空 / 指向非 `Story` | `PushError` |
  | `PlotArcData.PlotTriggerId` 与任一 `HiddenStatBandData.PlotTriggerId` 对不上 | `PushError` + 悬空 `PlotTriggerId`（**双向校验**：档位表侧配了触发 id 却无 arc 承接同样报错） |
  | 同一节点混有 `BranchChosen` 边与自动边，或同节点两条 `BranchChosen` 边 `ToNodeId` 相同 | `PushError` |
  | `PlotNodeData.ContentEnabled == false` | `PushError` |
  | `Body` 与 `Modulation` 同时为空 | `PushWarning`（既不叙事也不调制的节点是编排失误，不阻塞） |
  | `EventWhitelist` / `EventWeights` 指向不存在的 `EventId` | `PushError` + arc `Id` + 节点 `Id` + 悬空值（overlay 侧另加「必须来自基线」，见 `content-service.md`） |
  | `EventTypeWeight.Multiplier <= 0` | `PushError` + arc `Id` + 节点 `Id` + 类型（剧本侧无 Travel 例外） |
  | `EventWeight.Multiplier <= 0` | `PushError` + arc `Id` + 节点 `Id` |
  | `LevelBias` 绝对值超出内容侧配置的上界 | `PushWarning`（带不越界由赋级函数保证，这里只挡明显的编排失误） |
  | `Tighten` 的 `TurnLimitDelta` / `InitialDrawDelta` / `DrawPerTurnDelta` / `HandLimitDelta` 中任一 `> 0` | `PushError` + arc `Id` + 节点 `Id` + 越界字段名（方向违规，同 `Multiplier <= 0` 那两行的严厉度） |
  | `Tighten.WinMarginDelta < 0` | `PushError` + arc `Id` + 节点 `Id`（同上） |
  | 非空 `Tighten` 但五格皆为 `0` | `PushWarning`（等价于不填，多半是编排遗漏；同 `Body` 与 `Modulation` 同时为空那行） |
  | `Tighten` 任一 delta 的绝对值超出该格的内容侧上界常量（见 `systems/balance.md`） | `PushWarning`（同 `LevelBias` 越界那行——硬界由物化期钳制保证，这里只挡明显的编排失误） |

- **`Id` 约定。** 与 `plot.band.faith.2` / `location.wilds.bamboo_sea` 的点分小写同构：arc = `plot.arc.<tier>.<name>`（`plot.arc.story.ashen_lineage`）· node = `plot.node.<arc-name>.<两位序号>`（`plot.node.ashen_lineage.03`）。
  **node 的 `Id` 带 arc 名是有意的**：合并后校验能在**不解引用**的前提下先做一次廉价的命名一致性检查，且 overlay 新增一条 arc 时它的全部新 `Id` 共享同一前缀，人工评审一眼可辨。

### event / EventData（剧本内容侧）
- **event = 剧本内容单元。** 承载**提示文本以及分支式的选择 / 结果**；AdventurePlot 负责结构模型，event 内容侧负责具体剧本文本与分支。event 内容是**本地内容条目**（`res://` 基线 + overlay，经 ContentRegistry 按 `Id` 读取），由 key points 定位。
- **隐藏属性驱动剧情线（三条）：**
  - **煞气 / Bloodlust** —— 跨入 Band 3（75+）→ 触发 **「煞气反噬」** 剧情线（经 `PlotTriggerId`）。
  - **道心 / faith** —— 跨入 Band `−2`（0–19）→ 触发 **「心魔滋生」** 剧情线（经 `PlotTriggerId`）。**该档无叙事文案**，剧情线与调制是它唯一的显影通道。
  - **寿元 / lifeSpan** —— 递减到 0 → 触发 **「大限将至」**（角色 defeated）。**它对应终态而非任何一档**，不经 `PlotTriggerId` 通道。

Source: `handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md` · `handoffs/2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md` · `handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md` · `handoffs/2026-08-01-momentum-scoring-lifespan-tuning-and-failure-payoff.md` · `handoffs/2026-08-09c-past-event-trace-schema.md` · `handoffs/2026-08-10b-grant-source-and-fragment-source-scoping.md` · `handoffs/2026-08-11-plot-content-localization.md` · `handoffs/2026-08-12d-hidden-stat-bands-and-crossing-narrative.md` · `handoffs/2026-08-15d-intent-removal-lifespan-cost-visibility-and-design-audit.md` · `handoffs/2026-08-16-design-audit-adjudication-and-hand-limit.md` · `handoffs/2026-08-16i-plot-data-encoding.md` · `handoffs/2026-08-17d-exchange-mechanics-and-transaction-discipline.md` · `handoffs/2026-08-17e-finale-combat-only-and-hidden-stat-io.md` · `handoffs/2026-08-17f-lifespan-restoration-paths.md` · `handoffs/2026-08-17g-element-carrier-gaps.md` · `handoffs/2026-08-22-finale-failure-is-death.md` · `handoffs/2026-08-22-event-generation-weighting-pipeline.md` · `handoffs/2026-08-22-encounter-tighten-fields.md` · `handoffs/2026-08-22-plot-tree-chapter-packaging.md` · `handoffs/2026-08-22-eventcountlimit-plot-modulation.md` · `handoffs/2026-08-22-combat-defeat-consequences.md`

## 管理器角色 / API 面（契约）
> _总则与共享类型见 `systems/architecture.md`「API 契约总则」。**本 manager 纯本地，永不跨进程边界，故全部方法为形态 A**（剧本内容属本地内容层）。_

- **定位。** PlotManager 是**剧本内容的解析器**（按 key points 从 ContentRegistry 定位剧本节点）+ **eventOptions 的调制源**。它**不直接写 eventOptions**、也不向 game-progression / UI 暴露 eventOptions——对外呈现 eventOptions 的**唯一出口是宿主服务 future-event-service**。
- **类型声明为 `internal sealed`**（总则 3）：跨服务代码里根本写不出本 manager 的类型名。

| 方法 | 形态 | 完整签名 | 失败语义 |
|------|------|----------|----------|
| 解析剧本 | A | `bool TryResolvePlot(CharacterProfile c, out PlotSegment segment)` | **悬空 key point → `PushWarning` + 返回 `false`**，调用方跳过该段叙事与调制、轮回继续（不是失败路径） |
| 调制 | A | `EventOptionBatch ModulateEventOptions(CharacterProfile c, EventOptionBatch batch)` | 无调制 = 原批返回 |
| 档位驱动 | A | `void OnHiddenStatThreshold(CharacterProfile c, HiddenStat stat)` | — |
| 选分支 | A | `OpResult ChooseBranch(string branchId)` | 业务失败 → `OpResult`；经 ProfileManager 推进 key points |

- **形态 B → A 是本地化的直接推论**（`systems/common-properties.md`：形态 B 的定义就是「跨客户端 ↔ 后端边界」，形态 B / C 带 `Async` 后缀、形态 A 不带）。原 `ResolvePlotAsync` 的取不到语义由 `TryResolvePlot` 的 `bool` 承载——它对应「可选但缺失 → 警告 + 安全默认值」，而非「必需但缺失」。
- **`PlotSegment`（`TryResolvePlot` 的产出）：**

  ```csharp
  public sealed record PlotSegment(
      string                          ArcId,
      string                          NodeId,
      LocalizedText                   Body,        // 可空
      IReadOnlyList<PlotBranchOption> Branches,    // 空 = 无玩家选择；非空 = DnD 选分支
      PlotModulation                  Modulation); // 可空

  public readonly record struct PlotBranchOption(string BranchId, LocalizedText Label);
  ```

  - **`TryResolvePlot` 的 `bool` 语义：** 任一 key point 惰性 → 该条不产 segment；**全部 arc 都惰性 / 无 `Active` arc → 返回 `false`**，调用方跳过叙事与调制、轮回继续。
  - **`ModulateEventOptions` 的输入 = 全部 `Active` arc 的 `PlotModulation` 之并**，逐字段按上方「多条 `Active` arc 的合并算子」表合并（权重相乘 · 白名单非空者取并 · `LevelBias` 相加 · `Tighten` 五格逐格取极值）。
  - **无 `PlotRequest`**（无远端请求，key points 直接来自传入的 `CharacterProfile`）。

**只有 `ChooseBranch` 投影到服务门面上。** 前三个方法是宿主服务 `ComputeEventOptions` 物化链条**内部**的一环，不被跨服务调用（manager 纪律）；`ChooseBranch` 因需要玩家输入，故由 future-event-service 以同名方法转发。

**没有后端接口。** 总则 7 的三个窄后端接口全部落在服务身上，**本 manager 不持有任何后端接口**（不设 `IPlotBackend` 一类）；条件编译清单共 5 处，本 manager 不占其一（见 `system-overview.md`）。它只经宿主服务读 ContentRegistry。

**事件面：** 剧情线触发经宿主服务广播 `PlotThresholdReached(string CharacterId, HiddenStat Stat, int BandIndex)`；分支揭示 / 选择、key point 推进同样由**宿主服务**代为广播（manager 不直接持有 EventBus 通道）。
- **负载末位是 `BandIndex` 而非 `Threshold`**：它传的不是阈值数值，而是「跨进了第几档」；`OnHiddenStatThreshold` 的方法名不随之改动。
- **数据契约：** CharacterProfile 存 key points（轻量锚点，**必须可独立解析、缺失时可安全跳过**）；剧本内容是本地内容条目（不落存档，经 ContentRegistry 读）；**档位表是内容条目 `HiddenStatBandData`，当前所处档持久化在 `CharacterProfile.Status` 的三个 band 字段上**（见「意图」与 `systems/character-profile/_index.md`）。

## 决策(-> ADR)

- **剧本内容属本地内容层 · overlay 对剧本可新增 `Id`**（不设云端剧本服务）→ **ADR 候选**（宜与 content-service 的「内容载体形态」候选合并固化）。
- **它是 future-event-service 内部的 manager，不是服务**（层级词表见 `systems/architecture.md`），**ADR 候选**。
- **跨档叙事挂档位不挂事件 · 档位是内容条目且档数不可热更增减** → **ADR 候选**（宜与 content-service 的「内容载体形态」候选合并固化）。
- **剧本树 = 纯调制无并行结构 · 剧本内容落 `PlotArcData` + `PlotNodeData` 两个类型 · key points 每 arc 一条** → **ADR 候选**（宜与上一条同批固化）。

Source: `handoffs/2026-07-25c-service-manager-hierarchy-and-content-pipeline.md` · `handoffs/2026-08-11-plot-content-localization.md` · `handoffs/2026-08-12d-hidden-stat-bands-and-crossing-narrative.md`
- **强制在线 · 云端权威（`decisions/ADR-0003-online-cloud-authority.md`，Accepted）原样成立**，本 manager 不再依赖它——剧本本地化改的是内容载体，不是账号 / 存档模型。

## 待决问题

- **DnD 式选分支：** 触发点、UI、以及玩家可见 / 不可见分支的边界未定。
- **隐藏属性清单与推拉触发：** 已定 **道心 / 煞气 / 寿元** 三项且均隐藏，**取值域、档位表、阈值与回滞已定案**（见「意图」）；仍待定：是否还有其他隐藏属性、**增减触发（哪些 AdventureEvent 推拉、各推哪一档 `HiddenStatGrade`）**、每条剧情线的具体内容与 key points。**Combat 三档已有默认口径**（`Practice` 推道心不推煞气 · `Finale` 胜负同推道心，见 `systems/adventure-event/combat/_index.md`），它是这条待答项的一个子集，其余四类与逐条目编排仍欠。（寿元的消耗侧与回复侧均已定案：回复通道存在、只走 outcome 侧，且**回升 = 档号减小 = 静默**，不改任何结构，见 `systems/adventure-event/common-properties.md`。）→ 亦见 `life-cycle-service.md`、`systems/balance.md`。
- **`HiddenStatGrade` 的三个映射值随 ch1 数值标杆专场校准。** 初值 `Minor 2 / Standard 5 / Major 10` 与「每属性每篇章跨档 2–4 次」是**反推验收项，不是死数字**，其校验依赖上一条的「增减触发」。**档位结构、阈值形态、文案形态、呈现形态均不被它阻塞**——它约束的是标定，不是结构。→ `systems/balance.md`。

Source: `handoffs/2026-07-23-adventure-plot-hidden-stats-and-clarifications.md` · `handoffs/2026-08-09c-past-event-trace-schema.md` · `handoffs/2026-08-11-plot-content-localization.md` · `handoffs/2026-08-12d-hidden-stat-bands-and-crossing-narrative.md` · `handoffs/2026-08-16i-plot-data-encoding.md` · `handoffs/2026-08-17f-lifespan-restoration-paths.md`

## 对应
提炼至：`.claude/knowledge/systems/plot-manager.md`（引用层，待建）。
