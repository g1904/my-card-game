# Phase A — future-event-generation-weighting

目标库：`game-design-documents/`（orchestrator 已定）。
输入：`inbox/solution-draft-future-event-generation-weighting.md`（`/provide-solution-draft` 产物 · 已过用户评审 · `## 仍需用户决定` 四项全部裁决）。

## 一句话意图

把 `future-event-service.ComputeEventOptions` 那段从未写下来的算术定死：**类型修正 = 乘性系数（支撑集不变）· 三层框定 = 一条十步管线（seeded RNG 是消费者不是框定层）· 多条 Active arc 的白名单取并 / 权重相乘 · 批次规模 N 由按篇章分格的 `BatchSizeWeights` 掷定（`k` 随之成为其副产品）· 条目基础权重落 `SelectionWeightGrade` 三档枚举 + 平衡表映射**，并配齐取值域、加载期校验、物化后断言与日志。

## 已裁决（评审中定下，不进 interview）

- 多条 `Active` arc 的 `EventWhitelist` 合并算子 → **非空者取并**；全部为空 = 不收窄。
- 常规批的批次规模 N → **按篇章分格的 `BatchSizeWeights` 权重表掷定**（走 map 子流，五格 N=1…5，初值 5/20/45/22/8，三章暂共用一行）；`k` = N 个槽位中抽中 Travel 的次数，**不是独立旋钮**。
- Travel 之外的四类能否被 location 修正到 0 → **不允许**（`EventTypeModifierData.Multiplier > 0`；Travel 行 `>= 0`）。剧本侧 `EventTypeWeight.Multiplier` 恒 `> 0`，**不设 Travel 例外**。
- 条目基础权重的承载形态 → **`AdventureEventData.SelectionWeight : SelectionWeightGrade`**（`Rare / Uncommon / Common`，默认 `Common`）+ 平衡表 `SelectionWeightGrades` 映射（12 / 40 / 100）。
- 跨分片（来自 `solution-draft-enemy-pool-chapter-scoping.md` 的合并裁决）：**`AdventureEventData` 新增 `ChapterScope : int[]`**（空 = 不限，与 `PlotArcData.ChapterScope` / `EnemyData.ChapterScope` 同名同形同义），管线第 ① 步的过滤链据此落笔。**事件侧的落笔归本分片**。
- `[既有推演]` 且与既有权威无冲突的部分（乘性算子、多 arc 权重相乘、RNG 是消费者不是框定层、Travel 行可为 0、`EventWhitelist` 悬空校验、`1 <= Options.Count <= 5` 断言、日志形态、存档 schema 不动、服务 API 面不动）—— 见下方 🔵。

---

## 🔴 冲突

### 🔴-1 批次规模 N 的语义未定，且草稿自称的「降级后仍落在区间内」不成立

- **[问题陈述]** 草稿 ⑤ 步「按 `BatchSizeWeights` 掷定 N」+ 新增断言 `1 <= EventOptionBatch.Options.Count <= 5`，并在断言注里写 **「闸 ②③ 降级后仍须落在区间内」**
  ✗ 这句在三条既有收缩路径下都不成立，且草稿自己也没给收缩后的处置：
  1. **闸 ③ 降级**：`future-event-service.md` 明写「某条目降到 0 → 该条目本次不进批次、**本批少一项**」「**不另取一条填补批次**——本服务不设单项补位，而 1 项的批次本就合法」。掷出 **N = 1（初值 5% 概率，是常态可达而非边角）** 再被闸 ③ 拿掉那一项 ⇒ **0 项批次**，与新断言直接相抵，也等于一次无法推进的空批。
  2. **Travel 的 20% 档**：`travel/_index.md` 常规出场表明写「80% 档 = `k` 个目的地 / **20% 档 = 1 个**」。`k >= 2` 且掷中 20% ⇒ 实际输出比 N **少 `k − 1` 项**。草稿 ⑧ 步原样照抄了这条伪码，却在 ⑤ 步把 N 当成产出数量。
  3. **类型槽位超出该类型可用条目数**（与 🔴-1.3 同源）：见下。
  草稿 ② 步的排序理由只处理了「空类型退出分母」，处理不了「非空但供给不足 / 结构性缩水」。
- **选项**
  - **(a) N = 目标槽位数，实际输出允许少于 N；只保底 `Count >= 1`。** 需补一条保底规则（唯一自然的形态：**收缩到 0 时补一个 Travel** —— 邻接集合不经 `AllEnabled()`、`travel/_index.md` 已把 Travel 定为死局兜底，是全库唯一「恒可产出」的通道）。
    后果：`future-event-service.md` 十步管线在 ⑨ 之后加一条「收缩保底」；断言改为 `1 <= Count <= 5` 且保底路径显式化；`travel/_index.md` 的死局兜底一条扩写为「配额闸门 + 常规批收缩保底」两个触发面。**代价：** 破了「不设单项补位」——需明写这不是补位（不重新取池挑条目，只走既有 Travel 兜底通道）。
  - **(b) N = 目标槽位数，实际输出允许少于 N，下界只靠既有的「内容池为空 = 坏数据 → `PushError` + 抛」兜。** 后果：断言改为 `0 <= Count <= 5`，或干脆不加这条断言；N=1 + 闸③ 的 0 项批次落进 `PushError` 缺陷分支（与闸 ③「理论不可达的缺陷分支」同档）。**代价：** 玩家侧表现为轮回卡死，且它不是理论不可达——N=1 有 5% 基础概率。
  - **(c) 收窄 N 的取值来源，使 N=1 不再由掷骰产生**（`BatchSizeWeights` 的 N=1 格置 0，1 项批次只由结构性场景产生）。后果：`BatchSizeWeights` 初值改为 0/25/45/22/8；仍需回答 (2) 的 Travel 20% 缩水与 (3) 的供给不足。**代价：** 「1 与 5 是有记忆点的少见形状」这条设计意图打了一半折扣。
- **推荐：(a)**。理由：`travel/_index.md` 的「Travel 是死局兜底 · 邻接集合恒非空 · `selectCost` 无条件可支付」已经把这条通道备好了，(a) 是唯一不新增机制就能同时闭合三条收缩路径的形态；(b) 把一个 5% 概率的路径写成「缺陷分支」，与「产出侧不留能上线、线上才炸的洞」的既有取向相抵。

### 🔴-1.3（与上题同源，可一并裁决）类型指派有放回、条目抽取无放回 ⇒ 槽位落空

- **[问题陈述]** 草稿 ⑥「逐槽按类型分布**有放回**抽 N 次」+ ⑦「槽内**无放回**抽取（同批不重复 `EventId`）」
  ✗ 某类型抽中 m 次、但该类型经 ②③ 收窄后只剩 `< m` 条条目 ⇒ 多出的槽位抽不出东西。草稿只论证了「类型为空则退出分母」，没有覆盖「类型非空但供给 < 槽位数」。
- **选项**
  - **(a) ⑥ 步按各类型收窄后的可用条目数封顶**（等价于无放回的多元抽样：抽满一类即把它移出分布并重新归一）。后果：⑥ 步伪码多一句；不产生落空槽位，实际输出恒 = N（除 Travel 20% 与闸③ 外）。
  - (b) 允许落空，落空即少一项（并入 🔴-1 的保底规则）。后果：管线不变，但批次宽度会被内容池丰度间接影响——草稿 ⑤ 的备选表里正是以此为由**否决**了「批次规模由候选池丰度驱动」。
- **推荐：(a)**。理由：(b) 会从后门重新引入草稿自己否决的「玩家可从批次宽度反推内容池状态」；(a) 与 ⑦ 的无放回是同一条纪律的前后一致落地。

### 🔴-2 `PlotModulation.EventWeights` 的既有语义是「加成」，本方案取乘性系数

- **[问题陈述]** 草稿定 `EventWeight.Multiplier`（乘性系数、恒 `> 0`、缺省 1.0）
  ✗ `systems/services/plot-manager.md` 的 `PlotModulation` 类定义注释原文：`[Export] public EventWeight[] EventWeights { get; set; }  // 单条 AdventureEventData 的权重**加成**`，权力面表亦写「以什么权重出现」。草稿在「与既有决策的张力」第 1 条自陈此点，但**它不在已裁决的四项之内**，故仍需用户点头。
- **选项**
  - **(a) 松动既有措辞，`EventWeights` 与 `TypeWeights` 统一为乘性系数。** 后果：改 `plot-manager.md` 该行注释一个词 + 权力面表措辞；`inbox/archive/solution-draft-plot-data-encoding.md` 是过程档案、不必改。**代价极小（措辞级，字段类型 / 数量 / 位置全不变）。**
  - (b) 保持 `EventWeights` 加性、`TypeWeights` 乘性。后果：`plot-manager.md` 不改；但同一个类型上相邻两个权重字段语义相反，且加性的恒等元是 0、乘性是 1，`.tres` 里读不出作者想的是哪一种。
- **推荐：(a)**。理由：`systems/balance.md` 的赋级带已经把「**调制修正（乘性，只改权重不改支撑集）**」定为本库权重调制的既有算子语言；同一段物化管线、同一批调制源用两种权重语义是纯粹的漂移源。草稿本身也标注 (b)「不建议」。

---

## 🟠 含糊

### 🟠-1 `AdventureEventData.ChapterScope` 的事件侧落笔面只给了字段名，校验与断言未定

- **[原文表述]** 裁决区一句「两侧同形 `ChapterScope : int[]`（空 = 不限）……事件侧的落笔见本稿」，但草稿正文（字段表 / 加载期校验表 / 管线 ① 步）**一格都没写它**。
- 可解读为：
  - **(a) 逐字照抄敌人侧的处置**：取值域 `1..3`，空数组合法，越界 → `PushError`（带 `Id` + 越界值），重复值 → `PushWarning` + 去重；管线 ① 步过滤链 `AllEnabled() → ChapterScope 命中`。**不**为事件侧加「每 (chapter × eventType) 组合池非空」的启动期断言。
  - (b) 同 (a)，**另加**一条事件侧启动期断言（敌人侧有「每 `(eventType, chapter)` 通用池非空 → `PushError`」的对应物）。事件侧的对应形态大致是「每 `(chapter)` 或每 `(chapter, EventType)` 组合，`ChapterScope` 命中的条目数 ≥ 1」——它会把「某章漏配某类事件」从运行期的 `PushError + 抛` 提前到启动期。
  两者写出的 `adventure-event/common-properties.md` 校验表与 `future-event-service.md` ① 步文字不同。
- **推荐：(b)**。理由：既有的「内容池为空 = 坏数据 → `PushError` + 抛」是**运行期**失败，而 `.claude/rules/data-resource-rules.md` 与本服务的闸 ① 都要求「坏数据在启动期大声失败」；`ChapterScope` 一旦落地，「第二章没有任何 Explore 条目」就成了一种可静默编排出来的坏数据。**代价：** 断言粒度取 `(chapter)` 还是 `(chapter, EventType)` 要一并定——前者宽松易过，后者与闸 ① 的敌人侧断言逐字同构，推荐后者。

### 🟠-2 十步管线的适用范围未在文中标注

- **[原文表述]** 草稿把十步管线称作「`ComputeEventOptions` 的主体」，但 ④ 小节的表又列出三种「不走本表」的结构性场景（配额闸门批 / `Priority = 1` 收窄批 / 闸②③ 降级后）。
- 可解读为：
  - **(a) 管线 = 常规批专用**；配额闸门批走 `future-event-service.md` 既有伪码的 `if` 分支（`LocationEventCount >= EventCountLimit`），`Priority = 1` 收窄批走 `adventure-event/_index.md` 既有规则；落笔时在管线抬头明写「以下十步描述常规批；闸门批在 ① 之前短路」。
  - (b) 管线 = 全部批次的统一形态，闸门批表述为管线的一个特例（① 步换池为邻接集合、⑤ 步 N = 出度）。
  两者写出的 `future-event-service.md` 结构差异很大：(b) 要重写既有的 Travel 段伪码。
- **推荐：(a)**。理由：既有伪码是**已定案**的承重文本（`future-event-service.md` 的 Travel 段），(b) 等于无必要地重写它；且闸门批的取池链（邻接集合不经 `AllEnabled()`）与常规批的取池纪律是明写的**例外**关系，硬塞进同一条管线会模糊那条例外。

### 🟠-3 `SelectionWeight` 写进哪一份文档

- **[原文表述]** 草稿「后果」表写：`systems/adventure-event/common-properties.md` — 「新增 `SelectionWeight` 到共有字段清单」。
- 但 `systems/common-properties.md` 的**判据卡**写死：「**只有一个落点的字段不进任何 `common-properties.md`**，留在该类自己的 `_index.md`」；「上移：同一字段在 ≥2 个兄弟节点出现且语义同一」。
  - **(a) 挂载面按「五个事件子类型」算** ⇒ 五个兄弟节点共有 ⇒ 落 `adventure-event/common-properties.md`（与 `eventPriority` / `lifeSpanCost` 同处，这两个字段确实住在那里）。
  - (b) 挂载面按「唯一的 C# 类 `AdventureEventData`」算 ⇒ 单一落点 ⇒ 落 `systems/adventure-event/_index.md`。
- **推荐：(a)**。理由：`eventPriority` 与 `lifeSpanCost` 同样只挂在 `AdventureEventData` 一个类上，却都住在 `adventure-event/common-properties.md`——本库既有的读法就是按事件子类型算挂载面。**但这条一旦定错，`content/adventure-event/` 类型档案开张时的字段核对清单会指向错文档**，故值得一问。

---

## 🔵 可推演

- **类型修正 = 乘性系数、支撑集不变、五类系数乘完一次归一化。** 依据：`game-progression.md` location 字段表明写该行是「**软**（改权重，不改可及性）」，加性偏移与「白名单 + 权重」都做不到；`balance.md` 赋级带已定「调制修正（**乘性**，只改权重不改支撑集）+ 截断重分配」，同一物化管线复用同一算子语言。
- **乘法可交换 ⇒「location 与 arc 谁先」不是需要裁决的量。** 「叠加顺序」这条待答项在类型权重那一半自动收口。
- **seeded RNG 不是并列的第三层框定，是消费者。** 依据：`future-event-service.md` 物化输入清单把 map 子流与 location 框定、PlotModulation 并列为**输入**，而抽取只发生在分布定形之后；`common-properties.md` 的「全部玩法随机走 `SeedManager` 子流、产出即定稿」不给「RNG 先于框定」留形态。
- **多 arc 权重相乘、白名单取并。** 依据：相加的恒等元是 0 而乘法是 1（缺省行不需特判）；取交在两条不相交白名单下必然为空 → 落既有的「内容池为空 = 坏数据 → `PushError` + 抛」，一次合法编排把游戏打崩；`plot-manager.md`「超上限排队不丢弃，使触发恒定成立、只是延后」与「一条 arc 静默取消另一条」相抵；独占性的正确表达位是既有的 `PlotArcData.ExclusiveGroup`。
- **Travel 行可修正到 0、其余四类不可。** 依据：`travel/_index.md` 明写「Travel 的类型修正允许被修正到 0……闸门路径不受类型修正影响，死局兜底仍成立；**其余四类不适用本推论**」。
- **`k` 是 N 与类型分布的副产品，不是独立旋钮。** 依据：`future-event-service.md` Travel 段伪码已写「Travel 与其余四类一同按 location 的类型修正加权抽取，得槽位数 `k`」。
- **批次规模不由 location / `PlotModulation` / 隐藏属性驱动。** 依据：location 框定面 = **两组**字段（承重）；`plot-manager.md`「落约束面 → 不加字段」，且 `TravelFullFanoutChance = 0.80`「只有一份全局值，不接受任何按剧情线 / location 的覆盖参数」是逐字同一条论证；隐藏属性输入侧只有两条既有通道、明写「不新增机制、不新增字段」。
- **`BatchSizeWeights` 按篇章分格是合法分格轴。** 依据：`lifeSpanCost` 定价表按「事件类型 × 篇章」分格、`MaxConcurrentSideArcs` 住平衡资源；且本服务「只读『当前篇章的那一行』，不为分章写分支」的既有纪律原样成立。三章初值同值仍写成三行，不写成一行。
- **`SelectionWeightGrade` 取枚举档 + 平衡表映射，不落裸 `int`。** 依据：`ExperienceGrade` / `HiddenStatGrade` 两个既有实例；映射值 `<= 0` → `PushError`（同 `GrantPoolWeights`「任一档权重为 0 → `PushError`」）。它与 `Rarity` 的既定排除不冲突——`systems/common-properties.md` 明写事件的出现「由**权重**与优先级控制」，本档正是那个此前无字段承载的权重。
- **「策划 vs 随机」不设旋钮。** 依据：`plot-manager.md`「剧本树不产出任何事件、不持有任何事件序列（承重）」+「事件之间不存在预先编好的前后连边」已封死预排序列；策划度是三条既有通道的涌现量。
- **⑥ 有放回 / ⑦ 无放回的分野。** 依据：`combatTier` 三档共用 `EventType.Combat`（一批两个 Combat 正常）；同批重复 `EventId` 与 Exchange `PickMany` 无放回「同批不出现重复商品」同款理由。
- **存档 schema 不动、服务 API 面不动、既有 `.tres` 不需改。** 依据：批已整批落 `CharacterProfile.eventOption`；`SelectionWeight` / `ChapterScope` 均有默认值且内容存量为零（纯加法窗口）。
- **`EventWhitelist` / `EventWeights` 的 `EventId` 悬空校验已存在**（`plot-manager.md` 校验表：「指向不存在的 `EventId` → `PushError`」）⇒ 草稿校验表里那两行是**既有条目**，落笔时只补定位上下文（arc `Id` + 节点 `Id` + 悬空值），**不要重复新增一行**。
- **日志 `[FutureEvent-Weight] …` 只在屏幕切换点产出一次，不落热路径**，与既有「逐候选条目算一次池计数」的代价论证同款；标签形态符合 `.claude/rules/Context.md` 的 `[System-Method]` 约定。

---

## 拟改动文档清单（供跨草稿核对）

- **`systems/services/future-event-service.md`**
  - 「意图」新增一整节「eventOptions 生成 / 加权管线」：十步管线（取池 → 白名单取并收窄 → 闸②+Explore 壳过滤 → 类型分布归一 → N 掷定 → 类型指派 → 条目无放回抽取 → Travel 段 → 逐项物化 → 断言），并明写**适用范围 = 常规批**（🟠-2）。
  - 明写「seeded RNG 是消费者、不是并列的第三层框定」；明写「乘法可交换 ⇒ location 与 arc 的先后不是需要定的量」。
  - ① 步过滤链补 `ChapterScope`（🟠-1）。
  - 物化后断言新增一条 `1 <= EventOptionBatch.Options.Count <= 5`（形态取决于 🔴-1）+ 收缩保底规则（若裁 (a)）。
  - 新增日志行 `[FutureEvent-Weight] location=… arcs=… N=… dist=… k=…`。
  - **待决问题：整条删除「生成 / 加权规则未定」与「框定叠加顺序」两条。**（第三条「`Priority = 1` 依什么条件抬升」**属分片 ③，本分片不动**；第二条 `EventOutcomeSpec` **属分片 ②，本分片不动**。）
  - ⚠ **本文件是全批最热的写入面（plan.md 标注分片 1,2,3,5,6）**——本分片在 W1 独占写它，但分片 5 的 `ChapterScope` 敌人侧、分片 6 的带边界落点、分片 2/3 的待决问题删除都会再次触碰同一份文件的相邻小节。
- **`systems/game-progression.md`**
  - location 两组字段表的「事件类型出现概率修正」一行补上：**乘性系数 · 缺省 1.0 · Travel 行 `>= 0` / 其余四类 `> 0`**。
  - `LocationData` 代码块下补 `EventTypeModifierData` 的字段面（`Type` + `Multiplier`）。
  - 八条加载期校验表新增三条：`Multiplier <= 0` 且 `Type != Travel`（location `Id` + 类型）· Travel 行 `< 0` · 同一 location 某类型出现多行。
  - **待决问题：删除「事件类型概率修正的形态」与「location 与 AdventurePlot 调制的叠加顺序」两条**；「eventOptions 生成 / 加权」那条（第 174 行附近）中「叠加顺序」「策划 vs 随机权重」两半亦答定，需重写为只剩五类配比那一半（**该半归 `02-event-options.md` 第二条，仍开放**）。
- **`systems/services/plot-manager.md`**
  - `PlotModulation` 三个权重字段的注释对齐为**乘性系数 · 恒 `> 0` · 缺省 1.0**（`EventWeights` 那行的「加成」措辞见 🔴-2）；补 `EventTypeWeight` / `EventWeight` 的字段面（`Type|Id` + `Multiplier`）。
  - 新增「多条 `Active` arc 的合并算子」小表：`TypeWeights` / `EventWeights` **相乘**（恒等元 1.0）· `EventWhitelist` **非空者取并** · `EnemyPoolScope` 已定取并 · `LevelBias` 相加 · `Tighten` 逐字段取更紧（**待 `EncounterTighten` 字段面落笔，不展开**）。
  - 加载期校验表新增：`EventTypeWeight.Multiplier <= 0` · `EventWeight.Multiplier <= 0`（均带 arc `Id` + 节点 `Id`）。
  - `ModulateEventOptions` 一节把「合并规则归『框定叠加顺序』那条待答项」改写为直接给出算子。
  - **待决问题：整条删除「多条 `Active` arc 的 `PlotModulation` 如何合并」。**
- **`systems/adventure-event/common-properties.md`**
  - 「批次规模 = 常态 3、区间 1–5」一条补上驱动源（`BatchSizeWeights` 掷定 · 三种结构性场景不走本表）。
  - 共有字段清单新增 **`SelectionWeight: SelectionWeightGrade`**（落点见 🟠-3）与 **`ChapterScope: int[]`**（🟠-1），各带取值域与加载期处置。
  - **待决问题：删除「可用事件的生成规则」一条**（数量 / 重算依据已定，类型配比运算形态 + 叠加顺序 + 区间两端由本次答定；**唯一残留的「五类配比取值」归 `02-event-options.md` 第二条**）。
  - ⚠ **plan.md 标注分片 1,2,3 都写这份文件**——本分片改「批次规模」条与共有字段清单两处。
- **`systems/adventure-event/travel/_index.md`**
  - 「常规出场概率」一条补上运算形态（乘性系数、Travel 行允许 0）与「`k` = N 个槽位中抽中 Travel 的次数」。
  - 若 🔴-1 裁 (a)：「Travel 同时是死局兜底」一条扩写出第二个触发面（常规批收缩保底）。
  - **待决问题：删除「事件类型出现概率修正的运算形态」与「常规批次里 Travel 的槽位数 `k` 从何而来」两条**（保留「Travel 一行的具体定价」与「失去 flags 关地域后的运营替代」两条）。
  - ⚠ 分片 4（remaining-event-decision-points）也写这份文件。
- **`systems/balance.md`**
  - 新增 **`BatchSizeWeights`**（按篇章分格、五格权重、Σ 归一；初值 5/20/45/22/8，三章同值三行；标注「纯经验初值，待 ch1 数值标杆专场校准」）。
  - 新增 **`SelectionWeightGrades`**（Rare 12 / Uncommon 40 / Common 100；映射值 `<= 0` → `PushError`）。
  - 加载期校验：`BatchSizeWeights` 五格全 0 / 存在负值 / 支撑集越出 `[1,5]` → `PushError`（带篇章号）。
  - ⚠ 分片 6（band-boundary）与分片 10（flags-throttle）也写这份文件；本分片只新增两个旋钮条目，不动赋级带与既有表。
- **`systems/common-properties.md`** —— **不改**。`Rarity` 那条对 `AdventureEventData` 的排除原样成立（本方案落的是 `SelectionWeight`，不同名不同表）；若落笔时想在该条补一句回链，**须先与分片 5 对表**（它也在动共有字段面）。
- **`handoffs/2026-08-22-<slug>.md`** —— 本分片的新 handoff（Phase B 写）。

## 待移出的 open-questions 条目

- `open-questions/02-event-options.md` → **「生成 / 加权规则与叠加顺序（08-05b 收窄 · 08-15c 再收窄）」** → **整条移出**。结论：类型修正 = 乘性系数（支撑集不变，Travel 行可为 0、其余四类 `> 0`）· 叠加顺序 = 十步管线且乘法可交换使 location/arc 顺序不是量 · 多 arc 白名单取并 / 权重相乘 · 批次规模由 `BatchSizeWeights` 按篇章掷定，`k` 是其副产品 · 策划 vs 随机配比 = 涌现量不设旋钮。
- `open-questions/02-event-options.md` → **第二条「五类之间的配比，以及 Combat 内 `combatTier` 三档的配比」** → **不移出**，但需补一句：**运算形态已定（`BaseTypeWeights` 以乘性参与、归一化在类型分布层发生），本条只欠取值。**
- 其余分片：**无**（`Priority = 1` 抬升条件归分片 ③、`EventOutcomeSpec` 归分片 ②、选择区呈现手感与 `eventCountLimit` 剧本调制均未被本稿答定）。
- answer log 文件名（供 orchestrator 代笔）：`answer-logs/log-future-event-generation-weighting.md`；台账行 `log-future-event-generation-weighting.md | 2026-08-22 | inbox/solution-draft-future-event-generation-weighting.md | 1`（若 🟠-1/🟠-3 的裁决额外答定别的条目再加）。

## 越界发现（属于别的草稿 / 分片的问题，只记不处理）

1. **`AdventureEventData.ChapterScope` 是分片 5 的裁决派生给本分片的落笔任务**，但 `content/_index.md` 的敌人字段核对清单归分片 5；**事件类型档案（`content/adventure-event/`）尚未开张**，故事件侧无回填面。两分片都在 `future-event-service.md` 的「取池 / 框定输入」附近落笔 —— **plan.md 把它们排在 W1 与 W4 两个不同波次，需 orchestrator 确认后写的那一个不会覆盖前一个的 ① 步文字**。
2. **`EncounterTighten` 的字段面全库未定**（本稿 ③ 小节表里 `Tighten` 一行只能写「逐字段取更紧」）。它不阻塞本分片其余五个字段的合并算子，但会让 `plot-manager.md` 新增的合并表留一格半成品。不属任何在办草稿 → 建议进 `open-questions/`（`02-event-options.md` 或 plot 相关分片），由 orchestrator 决定落点。
3. **`future-event-service.md` 的「`EventOutcomeSpec` 阻塞来源待重新确认」**（08-22 对账发现）已由分片 2 承接，本分片不动。
4. **`systems/game-progression.md` 第 174 行附近的「eventOptions 生成 / 加权」待决条**与 `open-questions/02-event-options.md` 第一条、`future-event-service.md`「生成 / 加权规则未定」、`adventure-event/common-properties.md`「可用事件的生成规则」、`travel/_index.md` 两条 —— **同一个问题在全库有 5 份副本**。本分片一并清理，orchestrator 收尾时请确认没有第 6 份（建议对 `grep -rn "叠加顺序\|区间两端由什么驱动"` 全库跑一次）。
