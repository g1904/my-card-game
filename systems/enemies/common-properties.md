# enemies / common-properties（敌人条目的共有属性）

> `EnemyData` 条目的共有字段与加载期校验。字段总表与语义见 `_index.md`。

## 意图

### 共有字段（与全库内容条目一致的部分）

- **`Id`（稳定唯一字符串）** —— 一切引用的键：`EnemyInstance.EnemyId`、图鉴词条归属、事件模板的敌人池引用。**绝不用文件路径、数组索引或显示名作键。**
- **`ContentEnabled : bool = true`** —— 线上放量 / 秒关开关。**过滤只在产出侧**：物化取池必须走 `ContentRegistry.AllEnabled<EnemyData>()`；**读取侧 `Get(id)` 不过滤**，使存档中引用到已关闭条目的 `EnemyId` 仍能正确解析（进行中的战斗不会因为线上关掉一个敌人而崩）。**`ContentEnabled == false` 的条目照常参与全量加载校验。**
- **显示字符串与 `Id` 分离**（名称、图鉴五项词条），可改动或本地化而不破坏引用。

### 敌人专有的共有字段

| 字段 | 形态 | 缺失时 |
|------|------|--------|
| `KeyCardIds` | `string[]`，长度 **2–3** | 数量越界或为 0（词条已启用）→ `PushError`；id 不在样本卡组内 → `PushError`（带模板 `Id` + 卡牌 `Id`） |
| 样本卡组 | `CardData.Id` 序列，**规模不设硬限**（逐条编排，与玩家侧同规则），允许同名重复 | **空序列 → `PushError`**（带模板 `Id`）；含 `Pool == Character` 的条目 → `PushError`（报出违规 `Id` 与模板 `Id`） |
| item 持有列表 | `ItemData.Id[]` | 悬空 id → `PushError` |
| power 持有列表 | `PowerData.Id[]` | 悬空 id → `PushError`；带 `IgnoresProtection` 者须满足两条硬准入（仅挂 boss 档载体 · 绝不挂玩家可主动获取的内容，见 `systems/balance.md` 的 ≈5% 口径） |
| `EncounterScopes` | `CombatTier[]`，取值 `{ Practice, Standard, Finale }`（与 `EncounterSpec.Tier` 同一枚举） | **空数组 → `PushError`**（漏填会静默缩小抽取池） |
| `ChapterScope` | `int[]`，取值 `1..3`（对位 `CharacterProfile.chapter`） | **空数组合法**（= 三章通用，与 `PlotArcData.ChapterScope` 同名同义）；越界值 → `PushError`；重复值 → `PushWarning` |
| `PoolScope` | 内嵌 `Resource`，两个具名可空字段 `LocationId` / `PlotArcId`（形态见 `_index.md`） | **允许为 `null`**（= 通用池），不报错；校验见下 |
| `OverridesDeck` | `bool`，默认 `false` | — |

- **样本卡组规模不设硬限，两侧同规则。** 规模偏小的卡组在后期真实触发疲劳（抽牌堆不重洗，空堆每抽一张 −1 道念），这是「牌少而精」的内建对价，也是敌人编排可用的一条旋钮。**规模不是可机械校验的量**——这张表对样本卡组的唯一硬校验是「空序列必是漏填」与「不得含 `Pool == Character`」，两条校验的都是**填了什么**而非**填了多少**。取值与推导见 `systems/balance.md`；字段总表见 `_index.md`。
- **「关键卡牌不得被物化改写」是一条可在物化时机械检查的上界**：改写后若 `KeyCardIds` 中任一张不在最终 `DeckCardIds` 里 → `PushWarning` + 该次改写回退。**`OverridesDeck == true` 的条目显式豁免**（天劫这类定制卡组与模板样本卡组可以完全不同）。理由：图鉴词条挂模板且是静态的，改写把关键卡改掉会让图鉴与玩家实际遭遇对不上，而**图鉴是事前知识的主通道**。

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

### 战斗侧引用关系

- 敌人的**等级**（`EnemyInstance.Level`）经 `baseMomentum` 表决定其战斗起始道念，即开局起跑线。**它同时被精确标注在 eventOptions 上**，故既是内部判据也是对外展示字段——**看到等级即看到起跑线**。
- **敌人侧的战斗内量与玩家侧对称**：也是道念，同一套起手 / 抽牌 / 手牌上限数值（见 `systems/balance.md`），共用同一个 `DeckModule`，**疲劳规则一视同仁**（抽牌堆不重洗，空堆每抽一张 −1 道念）。
- **敌人的抽牌走独立的战斗 RNG 子流**，与玩家抽牌分开——玩家侧的一次额外抽牌不会打乱敌人的牌序（desync 防护）。

Source: `handoffs/2026-08-06d-combat-open-questions-mass-closure.md` · `handoffs/2026-08-22-enemy-pool-chapter-scoping.md` · `handoffs/2026-08-22-enemy-deck-size-and-fatigue-knob.md`

## 决策(-> ADR)

见 `_index.md`。

## 待决问题

- **敌人数据 schema 的其余字段：** 立绘 / 台词 / 音效引用、道念产出能力的缩放参数、行为脚本的表达形态未定义。

## 对应
提炼至：`.claude/knowledge/systems/enemies.md`（待建）
