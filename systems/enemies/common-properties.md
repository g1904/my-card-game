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
| 样本卡组 | `CardData.Id` 序列，**规模 15**，允许同名重复 | 含 `Pool == Character` 的条目 → `PushError`（报出违规 `Id` 与模板 `Id`） |
| item 持有列表 | `ItemData.Id[]` | 悬空 id → `PushError` |
| power 持有列表 | `PowerData.Id[]` | 悬空 id → `PushError`；带 `IgnoresProtection` 者须满足两条硬准入（仅挂 boss 档载体 · 绝不挂玩家可主动获取的内容，见 `systems/balance.md` 的 ≈5% 口径） |
| `EncounterScopes` | `EventType[]`，取值仅限 `{ Practice, Combat, Finale }` | **空数组 → `PushError`**（漏填会静默缩小抽取池） |
| `PoolScope` | 内嵌 `Resource`，两个具名可空字段 `LocationId` / `PlotArcId`（形态见 `_index.md`） | **允许为 `null`**（= 通用池），不报错；四条校验见下 |
| `OverridesDeck` | `bool`，默认 `false` | — |

- **「关键卡牌不得被物化改写」是一条可在物化时机械检查的上界**：改写后若 `KeyCardIds` 中任一张不在最终 `DeckCardIds` 里 → `PushWarning` + 该次改写回退。**`OverridesDeck == true` 的条目显式豁免**（天劫这类定制卡组与模板样本卡组可以完全不同）。理由：图鉴词条挂模板且是静态的，改写把关键卡改掉会让图鉴与玩家实际遭遇对不上，而**图鉴是事前知识的主通道**。

### `PoolScope` 的加载期校验（四条，全部带定位上下文）

| 违规 | 语义 | 处置 |
|---|---|---|
| `PoolScope.LocationId` 非空且不在 `LocationData` 仓储内 | 悬空引用 | `PushError`（带敌人 `Id` + 悬空 `LocationId`）+ 抛 |
| `PoolScope.PlotArcId` 非空且不在 `PlotArcData` 仓储内 | 同上 | `PushError`（带敌人 `Id` + 悬空 `PlotArcId`）+ 抛 |
| `PoolScope` 非 `null` 但两字段皆空 | 空壳：语义等同通用池，但「填了个空壳」与「有意留通用」不可区分 | `PushWarning`（不阻断） |
| 某 `EventType` 下的**通用池**（`PoolScope == null` 或两字段皆空）为空 | **能上线、线上不可见的死锁**：物化取不出敌人 ⇒ 「内容池为空 = 坏数据 → `PushError` + 抛」会在玩家进程里炸 | `PushError` + 报出该 `EventType`，**启动期早失败** |

- **第四条只按 `EventType` 单维枚举**，不含篇章维——`EnemyData` 上尚无表达篇章的字段（见 `_index.md` 待决问题）。它与「`overlay` 双闸」「`Rarity` 缺失 → `PushError`」同族：把只在线上显形的洞提到启动期。
- 反向的悬空（location / arc 条目引用不存在的 `EnemyData`）不存在——池归属的唯一权威在敌人条目一侧，location 条目不持敌人清单。
- **人工审阅级（不硬校验）**：某 arc / location 的专属池非空，但其中条目的 `EncounterScopes` 与该 arc 可达的事件类型无交集 ⇒ 写了永不出现的内容 → `PushWarning` + 列举。

### 战斗侧引用关系

- 敌人的**等级**（`EnemyInstance.Level`）经 `baseMomentum` 表决定其战斗起始道念，即开局起跑线。**它同时被精确标注在 eventOptions 上**，故既是内部判据也是对外展示字段——**看到等级即看到起跑线**。
- **敌人侧的战斗内量与玩家侧对称**：也是道念，同一套起手 / 抽牌 / 手牌上限数值（见 `systems/balance.md`），共用同一个 `DeckModule`，**疲劳规则一视同仁**（抽牌堆不重洗，空堆每抽一张 −1 道念）。
- **敌人的抽牌走独立的战斗 RNG 子流**，与玩家抽牌分开——玩家侧的一次额外抽牌不会打乱敌人的牌序（desync 防护）。

Source: `handoffs/2026-08-06d-combat-open-questions-mass-closure.md`

## 决策(-> ADR)

见 `_index.md`。

## 待决问题

- **敌人数据 schema 的其余字段：** 立绘 / 台词 / 音效引用、道念产出能力的缩放参数、行为脚本的表达形态未定义。
- **敌人池的篇章框定载体**（见 `_index.md` 待决问题）——它决定通用池空池校验能否从 `EventType` 单维扩到两维。

## 对应
提炼至：`.claude/knowledge/systems/enemies.md`（待建）
