# content —— 内容条目索引（实例层）

> **本层持有「有哪些条目」，`systems/` 持有「这类内容怎么运作」。** 二者是**类 ↔ 实例**关系，故平级而非嵌套：`systems/` 按概念结构组织，`content/` 按条目数量组织。
>

## 硬边界：本层不定义字段（承重）

**内容条目文档与类型档案一律不复述字段的类型定义、取值域、枚举成员表、数值 code 或完整校验语义**——那些的权威在 `systems/` 对应的类文档与 `systems/common-properties.md`。本层对每个字段只写**两样东西**：**这个条目在这个字段上填了什么值**，以及**指向权威的回链**。

违反即制造第二权威：两份表会各自漂移，而本库没有任何机制能发现它们不一致（与 `systems/common-properties.md` 判据卡的硬边界逐字同构）。

**可机械检查的越界信号：** 条目文档 / 类型档案里出现枚举成员表、字段取值域穷举、`GD.PushError` 级校验语义的完整表述，或一段 C# 类型定义 ⇒ 违规，压回「值 + 回链」。

Source: `handoffs/2026-08-14c-content-authoring-layer.md` · `handoffs/2026-08-15-content-id-technique-shape-and-subtype-reset.md` · `handoffs/2026-08-16c-effect-keywords-and-targeting.md` · `handoffs/2026-08-16g-travel-mechanics-and-location-carrier.md` · `handoffs/2026-08-16i-plot-data-encoding.md` · `handoffs/2026-08-17c-explore-reveal-mechanics.md` · `handoffs/2026-08-22-singleton-balance-resource-registry.md`

## 三层结构

```
content/
├── _index.md                  ← 本文件：类型登记表 + 约定
├── _TEMPLATE-type.md          ← 类型档案骨架（/scaffold-content-type 用）
├── _TEMPLATE-entry.md         ← 条目文档骨架（/author-content 用）
└── <类型>/                     ← 一个内容类型 = 一个文件夹（开张后才建）
    ├── _index.md              ← 类型档案：字段核对清单（名 + 回链）· id 形态 · 条目台账
    └── <id>.md                ← 一个内容条目 = 一份文档
```

**未开张的类型不预先建空文件夹**（沿用全库「只有在确有真实设计意图时才新增文档」的约定）。开张由 `/scaffold-content-type` 执行，它同时核对该类型的字段是否已定案到能写实条目。

## 类型登记表

**就绪度**回答的是「这个类型现在能不能写出**可 blueprint** 的条目」，不是「这个类型的设计有多完整」。

| 类型（文件夹） | 中文 | 代码类型 | 类定义权威 | 就绪度 | 开张 |
|---|---|---|---|:--:|:--:|
| `card/` | 卡牌 | `CardData` | `systems/character-profile/deck/` | 🟠 字段清单与效果语法已定，阻于 starter deck 内容 | ✗ |
| `cultivation-technique/` | 功法 | `CultivationTechniqueData` | `systems/character-profile/deck/` | 🟠 header 形态已定（含 `RequiredAffinities` / `MaxCharacterAffinityCount` 两格），阻于卡牌条目 | ✗ |
| `character/` | 角色（可玩模板） | `CharacterData` | `systems/character-profile/` | 🟠 字段表已成文（`Affinities` 与稀疏境界覆写 `RealmArtworks` 在内），仍阻于功法与神通条目 + 绑定功法初始层数待定 | ✗ |
| `character-power/` | 神通 | `PowerData`（Character 域） | `systems/character-profile/power/` | 🟢 字段清单与效果语法均已定 | ✗ |
| `character-item/` | 法宝 | `ItemData`（Character 域） | `systems/character-profile/item/` | 🟢 字段清单齐备（含两格使用效果面与配额格）+ 加载期校验 | ✗ |
| `player-power/` | 法则 | `PowerData`（Player 域） | `systems/player-profile/player-power/` | 🟢 两层共用 `PowerData`，字段清单齐备 + 三条加载期校验 | ✗ |
| `player-item/` | 古宝 | `ItemData`（Player 域） | `systems/player-profile/player-item/` | 🟢 与法宝共用 `ItemData`，另受 `Charges > 0` 硬约束 | ✗ |
| `enemy/` | 敌人 | `EnemyData` | `systems/enemies/` | 🟠 依赖功法（套牌 = 功法 Id + 层数） | ✗ |
| `enemy-ai/` | 敌人 AI 策略 | `EnemyAiProfileData` | `systems/enemies/` | 🟢 类定义与六条加载期校验已定；本层持 profile 的**逐条权重取值** | ✗ |
| `adventure-event/` | 修行事件（五子类） | `AdventureEventData` | `systems/adventure-event/<子类>/` | ⛔ **本阶段不开展** | ✗ |
| `location/` | 地域 + 地域图 | `LocationData` / `LocationMapData` | `systems/game-progression.md` | 🟢 载体 + 图校验 | ✗ |
| `plot-arc/` | 剧本线（四级层级之一） | `PlotArcData` | `systems/services/plot-manager.md` | ⛔ 随事件类顺延 | ✗ |
| `plot-node/` | 剧本节点（叙事 + 调制 + 出边） | `PlotNodeData` | `systems/services/plot-manager.md` | ⛔ 随事件类顺延 | ✗ |
| `hidden-stat-band/` | 隐藏属性档位 | `HiddenStatBandData` | `systems/services/plot-manager.md` | 🟢 档位表 | ✗ |
| `achievement/` | 成就 | Achievement 条目 | `systems/player-profile/achievement/` | 🟠 条目 schema 与进度模型未设计；奖励目录另依赖法则 / 古宝**条目**（类定义已齐备，欠的是条目本身） | ✗ |
| `ability/` | 异能 / 效果 / 触发条件 | `AbilityData` / `EffectData` / `TriggerConditionData` | `systems/character-profile/deck/common-properties.md`「效果原语与定义体」 | 🟢 语法已定案 | ✗ **不独立开张** |
| `card-subtype/` | 卡牌次类型 | `CardSubtypeData` | `systems/character-profile/deck/` | ⛔ **清单已归零**（机制保留） | ✗ |
| `keyword/` | 效果关键字 | `KeywordData` | `systems/character-profile/deck/` | ⛔ **清单为空**（机制保留） | ✗ |

**本阶段不开展的三项（⛔）：**

- **修行事件 `adventure-event/`** —— 八个子类文档仍是空占位、等各自专场（`systems/adventure-event/_index.md` 已定的流程意图）。**不要在通用文档里替它们臆造机制**，也不要先建条目。
  - **开张时须带一项 Explore 专有的台账列与一项对账：** 条目台账登记每条 Explore 的**真身 `Id` 与真身 `eventType`**，`/audit-content` 汇总三类真身的条目占比并与目标区间比对，**只报告不阻断**。理由：真身类型分布**没有运行时旋钮**（三处数据类都不为它加字段），编排口径是它唯一的控制面。目标区间与推导归 `../systems/adventure-event/explore/_index.md`，本层只登记填了什么值。
- **隐藏剧本 `plot-arc/` + `plot-node/`** —— 剧本调制的是 eventOptions，没有事件条目就没有可调制的对象，随事件类顺延。**两个类型各需一轮 `/scaffold-content-type`**：arc 是剧本线的头（激活条件 + 入口节点），node 是树上的一步（叙事 + 调制 + 出边），条目一一对应两个 `Resource` 类型，不合建一个文件夹。
- **效果关键字 `keyword/`** —— **清单为空，但机制保留**：`KeywordData`、`KeywordRef`、`EntryFilter.RequiredKeywords`、加载校验与准入判据全部有效，只是**当前不建任何关键字条目**。正确的清单只能从「哪些效果组合真的重复了 ≥3 次」倒推，而当前卡牌条目数为零；与次类型同批处理即可。详见 `../systems/character-profile/deck/common-properties.md`「清单归零，机制保留」。
- **卡牌次类型 `card-subtype/`** —— **清单已归零，但机制保留**：`CardSubtypeData`、`CardData.Subtypes`、加载校验与准入判据全部原样有效，只是**当前不建任何次类型条目**（唯一存活的 `enchantment.ambush` 是埋伏机制的定名，不是清单候选）。等内容有规模后按既有准入判据（① ≥3 个条目共享 ② ≥1 处筛选引用）自然长出来。详见 `../systems/character-profile/deck/_index.md`「清单归零，机制保留」。

**不单开类型的两项：**

- **图鉴 Codex** —— 词条是**挂在宿主内容 `Resource` 上的静态文案**（`systems/player-profile/codex/_index.md`），故它是那六个宿主类型（敌人 / 神通 / 法则 / 法宝 / 古宝 / 地域）**条目文档里的一个字段块**，不建 `content/codex/`。单开等于给同一份文案造两个落点。
- **平衡数值** —— 归 `systems/balance.md`，不是条目。「填了什么值」的权威已经在那里逐表写着，开一份类型档案会制造第二权威。
  - **不建 `content/` 类型 ≠ 不进 ContentRegistry。** 平衡资源仍是 `.tres`、仍按 `Id` 进注册表、仍受合并后强校验，只是它的取值权威在 `systems/balance.md` 而非条目文档。注册形态（`Id` 形态 · 单例读取面 · 条数校验 · 准入边界）见 `../systems/services/content-service.md`「单例内容的注册与校验」。

**美术 / 音频 guide** 已有自己的落点（`art/visuals/guides/`、`art/soundtracks/guides/`），不并入本层；条目文档以回链方式指向它所需的 guide。

### 依赖链（决定开张顺序 · 承重）

```
ability（效果原语）
   └─▶ card ─▶ cultivation-technique ─┬─▶ character
   └─▶ character-power ───────────────┘
   └─▶ character-item / player-power / player-item
              └─▶ achievement（奖励目录指定条目）
   cultivation-technique ─▶ enemy（套牌 = 功法 Id + 层数，展开为样本卡组；另含游离散牌）
enemy-ai（独立，权重向量；被 `EnemyData.AiProfile` 可空引用，可与 enemy 同批或后开）
location（独立，可开张）
hidden-stat-band（独立，档位表）

⛔ adventure-event（五子类，各等专场）─▶ plot-arc ─▶ plot-node    本阶段不开展
⛔ card-subtype · keyword                                 清单为空，机制保留
```

**`ability/` 是五个类型的共同底座，其语法已定案**——`EffectData` 子类树、首批八原语、触发器与条件的表达形态、效果流水线的阶段划分全部落在 `../systems/character-profile/deck/common-properties.md`，下游五个类型因此能写出可 blueprint 的效果定义。

**它不独立开张为内容类型文件夹。** 异能实例几乎恒为某张卡 / 某个神通的组成部分，**先内联在宿主条目文档里**；等某条异能出现 ≥3 处复用再抽成独立条目（判据照抄次类型与关键字那两条准入）。单开一个几乎每条都只被引用一次的文件夹，只会给每个宿主条目多一次跳转。

**功法 ↔ 卡牌的方向（承重）：功法条目持每层的卡牌 `Id` 列表，卡牌条目不带功法标记。** 因此**写作顺序是先卡牌、后功法**——反过来写，功法的列表在中间态必然悬空。一张卡可被多门功法引用。理由与被否决的替代（卡牌侧带 `(TechniqueId, Tier)` 标记）见 `../systems/character-profile/deck/_index.md`「承载形态」。**敌人条目引用功法条目**，故完整的写作顺序是**卡牌 → 功法 → 敌人**。

## 条目 `Id` 约定

**`<内容类型>.<snake_case_slug>`**。例：`location.yunmeng_marsh` · `player_power.crimson_vow` · `card.spirit_slash`。各类型档案照抄本约定，不各自发明。

> **前缀词表纪律（承重）：内容条目 id 绝不用裸 `item.` / `power.`。**
> 那两个词是**次类型**的主类型前缀（次类型 id 规范 = `<主类型>.<name>`，形如 `enchantment.ambush`，见 `../systems/character-profile/deck/_index.md`）。`Item` 与 `Power` 都是主类型，两套 id 活在同一个点分命名空间里，前缀撞车即无法区分。
> 因此四类持有条目一律用**全名前缀**：`character_item.` / `player_item.` / `character_power.` / `player_power.`，与 `terminology.md` 的四词定名（法宝 / 古宝 / 神通 / 法则）一一对应。
> 这条现在是空成本的（次类型清单已归零），但**次类型重建时必然重新引入 `item.*`**，届时若无此纪律即撞车。

- **文件名 = `Id` 去掉类型前缀**（`content/location/yunmeng_marsh.md`），避免路径里把类型名写两遍。
- 稳定 `Id` 的通则（绝不用路径 / 索引 / 显示名作键、显示字符串与 `Id` 分离）见 `systems/common-properties.md`「稳定 Id 键」。

## 状态词汇（条目）

- `draft` —— 已由 `/author-content` 写就，仍有 Open questions 或等待你评审。
- `ready` —— 你已签核；字段齐备、验收断言可核验；可安全 `/blueprint`。
- `blueprinted` —— 已存在一份 `.claude/blueprints/<slug>.md`。
- `built` —— `.tres` 已在 `game-feature-branch/` 中落地并验证。

**内容不进 `requirements/_index.md` 的台账**（内容直接喂 `/blueprint`，不经 FR），故**完成度追踪落在各类型档案的条目台账上**。这是如实记下的代价。

## 流水线位置

```
systems/<类文档> 详尽 ──▶ /scaffold-content-type ──▶ content/<类型>/_index.md（类型档案）
                                                          │
你的草稿（inbox/ 或粘贴）──▶ /author-content ──▶ content/<类型>/<id>.md（status: draft）
                                                          │  你签核 draft → ready
                                                          ▼
                                                    /blueprint ──▶ /implement ──▶ .tres
                                                          │
                             条目一多 ──▶ /audit-content（id 唯一性 · 交叉引用 · 池分布 · 覆盖率）
```

**类型级的设计意图（「功法这个系统该怎么运作」）不走本层**，走 `/analyze-new-ideas` → `systems/`。判据：**讲这一类内容的规则 → `systems/`；讲某一个具体条目 → `content/`。**
