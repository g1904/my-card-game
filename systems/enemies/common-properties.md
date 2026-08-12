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
| power 持有列表 | `PowerData.Id[]` | 悬空 id → `PushError`；带 `IgnoresProtection` 者须落在编排核对表内（见 `systems/balance.md` 的 1% 口径） |
| `EncounterScopes` | `EventType[]`，取值仅限 `{ Practice, Combat, Finale }` | **空数组 → `PushError`**（漏填会静默缩小抽取池） |
| `PoolScope` | 地点 / 剧情线归属 | **允许为空**（= 通用池），不报错；非空但指向不存在的 location / 剧情线 → `PushError` |
| `OverridesDeck` | `bool`，默认 `false` | — |

- **「关键卡牌不得被物化改写」是一条可在物化时机械检查的上界**：改写后若 `KeyCardIds` 中任一张不在最终 `DeckCardIds` 里 → `PushWarning` + 该次改写回退。**`OverridesDeck == true` 的条目显式豁免**（天劫这类定制卡组与模板样本卡组可以完全不同）。理由：图鉴词条挂模板且是静态的，改写把关键卡改掉会让图鉴与玩家实际遭遇对不上，而图鉴在意图黑箱档位下是唯一的信息来源。

### 战斗侧引用关系

- 战斗读取敌人的**等级**（`EnemyInstance.Level`）与角色等级在**全局等级序**上求差，据此决定意图揭示档位。**敌人等级同时被精确标注在 eventOptions 上**，故它既是内部判据也是对外展示字段。
- **敌人侧的战斗内量与玩家侧对称**：也是道念，同一套起手 / 抽牌 / 手牌上限数值（见 `systems/balance.md`），共用同一个 `DeckModule`，**疲劳规则一视同仁**（抽牌堆不重洗，空堆每抽一张 −1 道念）。
- **敌人的抽牌走独立的战斗 RNG 子流**，与玩家抽牌分开——玩家侧的一次额外抽牌不会打乱敌人的牌序（desync 防护）。

Source: `handoffs/2026-08-06d-combat-open-questions-mass-closure.md`。

## 决策(-> ADR)

见 `_index.md`。

## 待决问题

- **敌人数据 schema 的其余字段：** 立绘 / 台词 / 音效引用、道念产出能力的缩放参数、行为脚本的表达形态未定义。
- **`PoolScope` 的数据形态**（见 `_index.md` 待决问题）。

## 对应
提炼至：`.claude/knowledge/systems/enemies.md`（待建）
