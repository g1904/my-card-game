# enemies / common-properties（敌人条目的共有属性）

> `EnemyData` 条目的共有字段与加载期校验。字段总表与语义见 `_index.md`。

## 意图

### 共有字段（与全库内容条目一致的部分）

- **`Id`（稳定唯一字符串）** —— 一切引用的键：`EnemyInstance.EnemyId`、图鉴词条归属、事件模板的敌人池引用。**绝不用文件路径、数组索引或显示名作键。**
- **`ContentEnabled : bool = true`** —— 线上放量 / 秒关开关。**过滤只在产出侧**：物化取池必须走 `ContentRegistry.AllEnabled<EnemyData>()`；**读取侧 `Get(id)` 不过滤**，使存档中引用到已关闭条目的 `EnemyId` 仍能正确解析（进行中的战斗不会因为线上关掉一个敌人而崩）。**`ContentEnabled == false` 的条目照常参与全量加载校验。**
- **显示字符串与 `Id` 分离**（名称、图鉴五项词条），可改动或本地化而不破坏引用。
- **`Artwork`（共有字段 · 类型 `Texture2D`）。** 本层落在 `EnemyData` 上 = **敌人立绘**。
  - **本层合法取值 / 默认值 =** 可空，默认 `null`（尚未产出 → 呈现层回落占位）。
  - **本层消费点：** 战斗屏敌方区（点按语义 = 选目标）与 `EnemyCodex` 词条页，**同一张资产两处复用**。
  - 类型定义、校验与告警语义见 `systems/common-properties.md`；资产规格见 `art/visuals/_index.md`「敌人立绘」。

### 敌人专有的共有字段

| 字段 | 形态 | 缺失时 |
|------|------|--------|
| `KeyCardIds` | `string[]`，长度 **2–3** | 数量越界或为 0（词条已启用）→ `PushError`；id 不在样本卡组内 → `PushError`（带模板 `Id` + 卡牌 `Id`）。**校验基准 = 展开产物 ∪ 散牌的并集** |
| 功法引用列表 | `TechniqueRef[]`（内嵌 `Resource`，两个具名字段 `TechniqueId : string` + `Tier : int`） | **空列表 → `PushError`**（带模板 `Id`）；`TechniqueId` 不在 `CultivationTechniqueData` 仓储内 → `PushError`（带模板 `Id` + 悬空 `TechniqueId`）+ 抛；`Tier` 不在 `[1, 该功法的 MaxTier]` 内 → `PushError`（带模板 `Id` + 功法 `Id` + 越界值）+ 抛；同一 `TechniqueId` 重复列出 → `PushError`（带模板 `Id` + 重复 `TechniqueId`）；引用的功法 `Pool == Character` → `PushError`（报出模板 `Id` + 功法 `Id`） |
| 游离散牌列表 | `CardData.Id` 序列，允许为空、允许同名重复 | 悬空 id → `PushError`（带模板 `Id` + 卡牌 `Id`） |
| 样本卡组（派生） | 功法展开产物 ∪ 散牌；**规模不设硬限**（逐条编排，与玩家侧同规则） | 并集**为空 → `PushError`**（带模板 `Id`）；并集含 `Pool == Character` 的条目 → `PushError`（报出违规卡 `Id` + 带入它的功法 `Id` + 模板 `Id`） |
| item 持有列表 | `ItemData.Id[]` | 悬空 id → `PushError` |
| power 持有列表 | `PowerData.Id[]` | 悬空 id → `PushError`；带 `IgnoresProtection` 者须满足两条硬准入（仅挂 boss 档载体 · 绝不挂玩家可主动获取的内容，见 `systems/balance.md` 的 ≈5% 口径） |
| `EncounterScopes` | `CombatTier[]`，取值 `{ Practice, Standard, Finale }`（与 `EncounterSpec.Tier` 同一枚举） | **空数组 → `PushError`**（漏填会静默缩小抽取池） |
| `ChapterScope` | `int[]`，取值 `1..3`（对位 `CharacterProfile.chapter`） | **空数组合法**（= 三章通用，与 `PlotArcData.ChapterScope` 同名同义）；越界值 → `PushError`；重复值 → `PushWarning` |
| `PoolScope` | 内嵌 `Resource`，两个具名可空字段 `LocationId` / `PlotArcId`（形态见 `_index.md`） | **允许为 `null`**（= 通用池），不报错；校验见下 |
| `AiProfile` | `EnemyAiProfileData`（`[Export]` 直接类型引用；类形态见 `_index.md`） | **允许为 `null`**（= 走通用兜底），不报错；其余五条校验见下 |
| `Lines` | `EnemyLine[]`（内嵌 `Resource`，两个具名字段 `Slot : LineSlot` + `Text : LocalizedText`；类形态见 `_index.md`）——稀疏数组，只列要写的场合 | **空数组合法**（= 该敌人无台词）；同一 `Slot` 重复出现 → `PushError`（带敌人 `Id` + 重复 `Slot`）；某条的 `Text == null`、或其默认语言缺失 / 为空串 → `PushError` + 抛（带敌人 `Id` + `Slot`） |

- **样本卡组规模不设硬限，两侧同规则。** 规模偏小的卡组在后期真实触发疲劳（抽牌堆不重洗，空堆每抽一张 −1 道念），这是「牌少而精」的内建对价，也是敌人编排可用的一条旋钮——功法列表之外保留一格游离散牌，正是为了让规模能被精确编排而不必按「功法数 × 每层卡数」整组增减。**规模不是可机械校验的量**——这张表对样本卡组的唯一硬校验是「并集为空必是漏填」与「不得含 `Pool == Character`」，两条校验的都是**填了什么**而非**填了多少**。取值与推导见 `systems/balance.md`；字段总表见 `_index.md`。
- **`Pool` 的枚举与卡池划分语义只有一份权威**，在 `systems/character-profile/deck/_index.md`「卡池划分」节（卡牌层与功法层同挂该节）；本表只登记敌人侧的两条闸——引用的功法不得 `Pool == Character`、并集内的卡牌不得 `Pool == Character`。报错多带一格功法 `Id`，否则内容编写者要自己反查是哪门功法把违规卡带进来的。
- **`Tier` 的下界写 `1` 是承重的**：不写下界会让 `0` / `-1` 这类哨兵值静默通过。同一功法重复列出必是编排错误：层数是严格升级，低层是高层的严格劣化版，同门两层同时在组内无合法语义；而**展开后卡牌 `Id` 重复仍合法**（多门功法共享同一张卡），「允许同名条目重复」只讲卡牌层，不受影响。
- **「关键卡牌必在样本卡组内」是一条加载期即可执行的机械检查**：层数在模板上逐条固定 ⇒ 展开唯一确定 ⇒ `KeyCardIds` 中任一张不在「展开产物 ∪ 散牌」里 → `PushError`。理由：图鉴词条挂模板且是静态的，图鉴与玩家实际遭遇对不上会当场废掉**事前知识的主通道**。
- **展开产物不得写回条目。** 校验与展开都是纯只读——`EnemyData` 是 ContentRegistry 里的共享只读单例；需要缓存展开结果就落在 ContentRegistry 侧的**派生索引**（加载期一次算出）。被引用的功法 `ContentEnabled == false` 时**不做连带过滤**，敌人照常展开（过滤只发生在产出侧，读取侧 `Get(id)` 不过滤）。
- **`Lines` 的三条校验分档不另立判据**：整条 `EnemyLine` 不存在 = 合法（对应「字段本身为 `null`」那条既有判据）；**挂上了却是空壳 = 坏数据**；同 `Slot` 重复照抄 `AiWeight` 同 `Term` 重复与 `TechniqueRef` 同 `TechniqueId` 重复的处置。默认语言为空串仍是坏数据这一条的权威在 `systems/common-properties.md` 的可选 `LocalizedText` 一节。
- **`LineSlot` 尚无成员，故 `Lines` 对任何条目都只能是空数组。** 台词的呈现落点在本库尚无表述（战斗屏形态待一次战斗 UX 专场，见 `open-questions/01-combat.md`），成员清单须与那场专场一并定——先写下一组无消费点的枚举值只会让内容编写者填出永不显示的文本。**本格在专场答定成员之前不可填写**；形态先落是为了让类定义、校验与 derive 面此刻即完整。
- **台词是文本内容，不是音频资产**：它走 `LocalizedText`，与图鉴词条并列为写作口径的对象——标为 `[Practice, Standard]` 的条目，其图鉴与台词必须同时说得通「切磋」与「厮杀」，归 `enemy-codex` 的写作规格。
- **敌人条目不开音效引用字段。** `art/soundtracks/` 的六个音频类目没有任何一条按敌人条目逐条产出（出牌音属卡牌动作、受击音属道念反馈，两者都已在别的类目名下）；敌人级独有的只剩「入场吼叫」一类，其存在性在全库无一处表述。且多数玩家静音游玩、**音频必须是增益而非承载信息的唯一通道** ⇒ 敌人级音效即便日后有也只承载演出层语义，而演出层的挂点归 `art/visuals/animations/`。**留一个恒无对象的伸缩位只会让每个消费点都要处理一个永不发生的分支**（同「敌方不为天劫开第二条构筑通道」）。日后确有需求是纯加法。类目表见 `art/soundtracks/_index.md`。

### 取池相关字段的加载期校验（六条，全部带定位上下文）

| 违规 | 语义 | 处置 |
|---|---|---|
| `PoolScope.LocationId` 非空且不在 `LocationData` 仓储内 | 悬空引用 | `PushError`（带敌人 `Id` + 悬空 `LocationId`）+ 抛 |
| `PoolScope.PlotArcId` 非空且不在 `PlotArcData` 仓储内 | 同上 | `PushError`（带敌人 `Id` + 悬空 `PlotArcId`）+ 抛 |
| `PoolScope` 非 `null` 但两字段皆空 | 空壳：语义等同通用池，但「填了个空壳」与「有意留通用」不可区分 | `PushWarning`（不阻断） |
| `ChapterScope` 含 `1..3` 之外的值 | 越界，指向不存在的篇章 | `PushError`（带敌人 `Id` + 越界值）+ 抛 |
| `ChapterScope` 含重复值 | 无害但多半是手误——重复值对 `Contains(currentChapter)` 无任何影响 | `PushWarning`，**只告警、取池不受影响**（校验是纯只读，绝不写回条目——模板是 ContentRegistry 里的共享只读单例） |
| 某 `(combatTier, 篇章)` 组合下的**通用池**（`PoolScope == null` 或两字段皆空，且 `ChapterScope` 命中该章）为空 | **能上线、线上不可见的死锁**：物化取不出敌人 ⇒ 「内容池为空 = 坏数据 → `PushError` + 抛」会在玩家进程里炸 | `PushError` + 报出该组合，**启动期早失败**；`Finale` 一行按下述放宽口径 |

- **末条按 `(combatTier × 篇章)` 两维枚举**（3 × 3 = 9）。**枚举面封闭且极小**，故这是纯粹的加法、无组合爆炸风险——这正是「篇章数是固定的游戏结构」这条判据买来的好处。它与「`overlay` 双闸」「`Rarity` 缺失 → `PushError`」同族：把只在线上显形的洞提到启动期。
- **`Finale` 那三格的口径放宽为「该 `(Finale, chapter)` 下的池（含专属条目）非空」**，与 `Practice` / `Standard` 两行的「通用池非空」不同。理由：天劫是篇章边界的高度定制内容，把它写成某条 Story / Chapter arc 的**专属条目**（`PoolScope.PlotArcId` 非空）是正当甚至更自然的编排；按通用池口径枚举会把这种编排当成缺内容拦下。放宽后仍能堵住「某一章忘了写天劫」这个洞。
- **通用池的判据是 `PoolScope == null` 或两字段皆空**（空壳语义等同通用池，这正是它只 `PushWarning` 而非 `PushError` 的理由），篇章维在其后以与门叠加，两者正交。
- 反向的悬空（location / arc 条目引用不存在的 `EnemyData`）不存在——池归属的唯一权威在敌人条目一侧，location 条目不持敌人清单。
- **人工审阅级（不硬校验）**：某 arc / location 的专属池非空，但其中条目的 `EncounterScopes` 与该 arc 可达的档位无交集 ⇒ 写了永不出现的内容 → `PushWarning` + 列举。
- **`ChapterScope` 留空是机械不可发现的**（漏填与「有意三章通用」形状相同）。缓解手段是**纯结构判定**、不做文案扫描：`ChapterScope` 为空的条目在 `content/enemy/` 类型档案的评审清单里逐条过一遍，确认其图鉴词条三章都说得通。**不按境界词（筑基 / 金丹 / 元婴）做子串扫描**——图鉴五项词条的类型是 `LocalizedText`，子串规则在任何非中文语言下都失效，中文侧也会误命中。

### AI 策略字段的加载期校验（六条，全部带定位上下文）

| 违规 | 语义 | 处置 |
|---|---|---|
| `AiProfile == null` | **合法** —— 显式不在必填清单内，绝大多数条目走此路 | 不报错、不告警 |
| `AiProfile` 非 `null` 但其 `Id` 为空、或不在 `EnemyAiProfileData` 仓储内 | 悬空引用 | `PushError`（带敌人 `Id` + profile `Id`）+ 抛 |
| `AiProfile` 非 `null` 但 `Weights` 为空数组 | 空壳：语义等同兜底，但「填了个空壳」与「有意留兜底」不可区分 | `PushWarning`（不阻断） |
| 同一 `AiTerm` 在 `Weights` 中重复出现 | 必是编排错误（后一条静默覆盖前一条） | `PushError`（带 profile `Id` + 重复 `Term`） |
| `AiWeight.Value` 落在 `[AiWeightMin, AiWeightMax]` 之外 | 越界权重会击穿「定制不强于兜底」的取值域上界 | `PushError`（带 profile `Id` + `Term` + 越界值）+ 抛 |
| 某条 `EnemyAiProfileData` 未被任何 `EnemyData` 引用 | 写了永不生效的内容 | `PushWarning` + 列举 |

- **「允许为空 = 走通用兜底」在校验中的表达 = 该格显式不进必填清单，且首行把 `null` 明写为合法。** 与 `PoolScope`（`null` = 通用池、不报错）同款；反面是 `EncounterScopes`（空数组 → `PushError`），两者的不对称判据仍是那条——**漏填的后果不同**：`AiProfile` 漏填只是回落到一条可用路径，不产生静默污染，不是死内容。
- 空壳 `PushWarning` 与重复 `Term` `PushError` 分别照抄 `PoolScope` 空壳与 `TechniqueRef` 重复两条的分档，不另立判据。
- **取值域两端 `AiWeightMin` / `AiWeightMax` 与兜底默认向量同住 `CombatRulesData`**，其上另有一条跨字段不变式：每个默认权重须落在区间内，否则 `PushError` + 抛。取值见 `systems/balance.md`。

### 战斗侧引用关系

- 敌人的**等级**（`EnemyInstance.Level`）经 `baseMomentum` 表决定其战斗起始道念，即开局起跑线。**它同时被精确标注在 eventOptions 上**，故既是内部判据也是对外展示字段——**看到等级即看到起跑线**。
- **敌人侧的战斗内量与玩家侧对称**：也是道念，同一套起手 / 抽牌 / 手牌上限数值（见 `systems/balance.md`），共用同一个 `DeckModule`，**疲劳规则一视同仁**（抽牌堆不重洗，空堆每抽一张 −1 道念）。
- **敌人抽牌与玩家共用同一条 `combat` RNG 子流**，不按侧分流：两侧牌序在参战方组装时各洗一次即定，此后抽牌只是从定序列表取值、零随机消耗，故一侧的额外抽牌不会打乱另一侧的牌序。初洗与先后手掷点的顺序规则见 `systems/services/combat-service.md`「确定性」。

Source: `handoffs/2026-08-06d-combat-open-questions-mass-closure.md` · `handoffs/2026-08-22-enemy-pool-chapter-scoping.md` · `handoffs/2026-08-22-enemy-deck-size-and-fatigue-knob.md` · `handoffs/2026-08-25-enemy-deck-from-techniques-and-ai.md` · `handoffs/2026-08-26b-combat-substream-arbitration.md` · `handoffs/2026-08-26c-enemy-ai-strategy-shape.md` · `handoffs/2026-08-28-content-artwork-enemy-lines-and-ai-weight-vector.md`

## 决策(-> ADR)

见 `_index.md`。

## 待决问题

- **敌人台词的槽位清单（`LineSlot` 的成员）：** 字段形态已给出（见上方 `Lines`），成员清单待一次**战斗 UX 专场**——台词的呈现落点尚无表述。在它答定之前 `Lines` 只能是空数组。→ `ux/combat-ux.md`、`open-questions/01-combat.md`。
- **敌人各等级的道念产出能力的缩放参数未定义。** → `systems/balance.md`。

## 对应
提炼至：`.claude/knowledge/systems/enemies.md`（待建）
