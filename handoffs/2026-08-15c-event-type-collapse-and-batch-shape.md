# 事件类型收为五类、批次形状与寿元定价归属

- id: 2026-08-15c-event-type-collapse-and-batch-shape
- date: 2026-08-15
- topic: systems/adventure-event（`_index` · `common-properties` · combat / explore / exchange / research / travel）、decisions/ADR-0002、terminology.md、systems/balance.md
- status: distilled
- distilled-to: decisions/ADR-0002-adventure-event-taxonomy.md, systems/adventure-event/_index.md, systems/adventure-event/common-properties.md, systems/adventure-event/combat/_index.md, systems/adventure-event/combat/common-properties.md, systems/adventure-event/explore/_index.md, systems/adventure-event/exchange/_index.md, systems/adventure-event/research/_index.md, systems/adventure-event/travel/_index.md, systems/architecture.md, systems/services/combat-service.md, systems/services/life-cycle-service.md, systems/services/_index.md, systems/services/future-event-service.md, systems/game-progression.md, systems/balance.md, systems/character-profile/deck/_index.md, terminology.md, program-overview.md, systems/_index.md, systems/common-properties.md, ux/screen-flow.md, `practice/`, `mystery/`, `social/`, `finale/`, `systems/scoring.md`, `systems/enemies/_index.md`, `mana.md`, `life-total.md`, `systems/player-profile/`, `player-power/`, `profile-service.md`, `plot-manager.md`, `ux/combat-ux.md`, `vision/scope.md`, `art/`, `decisions/_index.md`

## Intent（distilled）

**一句话：** 修行事件的分类法从**九类收为五类**（Combat / Exchange / Research / Explore / Travel），被合并掉的四类（Practice / Finale / Mystery / Social）**不是被删除，而是降格**——难度档、元类型语义、交易语境各自被吸收进留下的那一类里；同时定下批次规模（每批 3 项，1–5）、Travel 候选的 80/20 掷定，并把寿元定价从逐条目手写改为**按类型 × 篇章的统一定价表**。

### ① 分类法：九类 → 五类

| 保留的类 | 中文 | 吸收了什么 |
|---|---|---|
| **Combat** | 战斗 | **Practice** 与 **Finale** —— 二者不再是 `eventType`，降格为 **Combat 的遭遇档位** |
| **Exchange** | 交易 | **Social** —— 社交语境并入交易 |
| **Research** | 闭关 | —— （语义收窄，见 ③） |
| **Explore** | 探索秘境 | **Mystery** —— Explore 继承元类型（遮罩）语义 |
| **Travel** | 前往某处地点 | —— |

合并判据一律是「**共有同一套特征（share the same characteristics）**」：三类战斗共用回合循环与参战方结构，Explore / Mystery 共用遮罩—揭示形状，Social / Exchange 共用「与 NPC 打交道、以资源换取东西」的事件式结算。

### ② Combat 内部：`combatTier` 三档（澄清产物）

Practice 与 Finale 的既有设计**全部原样保留**，只是挂载点从 `eventType` 移到 Combat 的一个遭遇档位字段：

| 档位 | 对位 Balatro | 既有定案（不变） |
|---|---|---|
| `Practice` | small blind | `TurnLimit 8` · `WinMargin 0`（道念相等即胜）· `Draw` 永不可达 |
| `Standard` | big blind | `TurnLimit 10` · 道念高者胜 |
| `Finale` | boss blind | `TurnLimit 12` · `WinMargin` ch1 3 / ch2 5 / ch3 8 · 天劫 Enemy · 篇章边界闸门 · 道统残卷唯一累积源与兑现点 |

**Finale 必须留一个可机械判定的锚点**——它是篇章边界、ADR-0004 篇章重试模型、残卷发放三处的判据；靠内容 `Id` 硬编码识别是反模式。`combatTier` 正是这个锚点。`EnemyData.EncounterScopes` 的 `[Practice]` / `[Combat]` 作用域划分随之改为按档位取值，「先在低风险处解锁图鉴、再正式对上」的教学路径保住。

### ③ 各类语义

- **Combat 是最高频的一类**——玩家在此与敌人战斗并获取资源。
- **Exchange**：以资源换取 item / cultivationTechnique / 等。
- **Research**：玩家**调整 / 升阶自己的卡组**。
- **Travel**：**不是常驻可选项**。仅当当前 location 的事件耗尽（`eventCountLimit` 达成）时**必定**出现；即便地图上与当前 location 连通，邻接目的地也**不保证**都出场。
- **Explore**：选中一个被遮罩的事件，其真身可能是 **Combat / Travel / Exchange**，**不含 Research**。

### ④ 批次形状

- **每批 eventOptions 常态 3 项**，取值区间 **1–5**。
- **一次事件完成 ⇒ 整批重算**，且**不基于上一批**，而是基于**角色的整体历程**——重度依赖 `pastEvent`。

### ⑤ Travel 候选的 80 / 20（澄清产物）

- **80%** 的场景：列出**当前 location 的全部邻接地域**供玩家选择。
- **20%** 的场景：**seeded 随机取一个**邻接地域，玩家无从选择去哪。
- **Explore 揭示出的 Travel 必为随机那一档。**
- 该掷定**对常规出场与配额闸门一律适用**——规则只有一条。即使只剩一个目的地也不产生死局（仍可推进）。

### ⑥ `selectCost` 与寿元定价

- **`selectCost` 现阶段只是寿元扣减的一个包装**：想不出还该有别的成本 element。**但复合形态保留**（`ProfileChangeSpec`，`lifeSpanCost` 是其唯一在用的 element），不塌缩为单一 `int`——内容侧写正数量值、物化取负、`PastEventEntry.SelectCost` 存定稿快照这整条链路不动，日后真需要第二个 element 时零成本加上。
- **寿元定价改为按「事件类型 × 篇章」的统一定价表**（归 `systems/balance.md`），内容条目只在需要时标偏移 / 覆盖值。理由：定价的设计判据本就是**目标游玩时长**（ch1 30–40 / ch2 35–45 / ch3 45–55 分钟），改一张表即可全局调时长，不必重扫数百个 `.tres`；也避免同类事件定价漂移。

### ⑦ 开局强制构筑事件归 Research（澄清产物 · 答结阻断项）

起始批次中那个强制事件（选一门功法 + 一件法宝，各三选一）**归 Research**，与「Research = 调整 / 升阶卡组」的新定义直接对位。**不需要第六类**，承载机制仍是既有的 `eventPriority = 1`（本批有效可选集收窄）。

## Clarifications（interview 产物）

| 问题 | 用户裁决 | 它推翻 / 细化了什么 |
|---|---|---|
| Finale 合并后靠什么识别 | **Combat 上加遭遇档位字段** | 细化原文「finale is a special designed type of combat with extra content」——「extra content」落为 `combatTier = Finale` 这个可机械判定的锚点，而非纯内容层约定 |
| 「practice no longer exists」的力度 | **只废枚举值，保留难度档** | 收窄原文：Practice 消失的是 `eventType` 成员，small blind 档（`TurnLimit 8` / `WinMargin 0`）与 `EncounterScopes` 的两层敌人池**不作废** |
| Explore 的形态 | **遮罩单个固定事件，进入即揭示** | 排除「进入后二次择一（嵌套菜单）」与「进入时现掷」两种解读；Explore 完整继承旧 Mystery 的「遮罩的是一个**固定**事件」定案，不新增机制 |
| Travel 候选数量（草稿「randomly choose one option」✗ 08-05b「闸门给多个并列」） | **80% 列全部邻接 / 20% 随机一个；Explore 揭示出的必为随机；常规与闸门一律适用** | 两侧都不作废而是合成一条掷定规则；同时答结「是否列出全部邻接还是抽取其中几个」这条待答项 |
| `selectCost` 形态 | **保留复合形态，目前只填寿元** | 细化原文「only a wrapper」——是**用法**上只有一项，不是**类型**上塌缩 |
| 寿元定价形态 | **按类型 / 档位统一定价表** | 把原文「maybe there's a better way」落为具体形态 |
| 开局强制构筑事件归属 | **归 Research** | 原文未提；由「Research = 调整 / 升阶卡组」推出并经确认 |

**另需知悉（原文前提已过时）：** 草稿中「余额扣减与确保可选 is messy」所指的那套机制**已在 08-06c 整体消解**——`selectCost` 早已改为**无条件施加、不做「付得起」校验**，支付之后再做终态判定（寿元归 0 → `defeated`）；`skipCost` / `ifMandatory` / 「付不起则拒绝」回路均已删除。因此这条 messiness 已不存在，无需再解。留下的只有「寿元定价怎么归属」那一半，已由上表答结。

## Open questions

- **Explore 揭示池的权重。** 真身取值域已定（Combat / Travel / Exchange，不含 Research），但三者的出现权重、是否随 location / 剧本调制未定。
- **Social 并入 Exchange 后，NPC / 势力模型是否仍需要。** 原 Social 的待答项（NPC 如何定义、好感 / 关系度是否持久、跨轮回是否留存）在合并后是**降级为 Exchange 的风味层**，还是仍需一套数据模型？归 Exchange 专场。
- **`combatTier` 除 `EncounterSpec` 外的落点。** `EncounterSpec.Tier` 已定；呈现层与履历是否也需要它出现在 `EventOption` / `PastEventEntry` 上，未定。
- **寿元定价表的具体取值。** 表的形态已定（类型 × 篇章 + 条目级覆盖），**数值**仍归 ch1 数值标杆专场。
- **Travel 的 80 / 20 是否可被剧本调制。** 掷定比例是全局常量还是可由 PlotManager 推拉，未定。
- **每批 1–5 的区间由什么驱动。** 常态 3 已定；何时收到 1、何时放到 5（location？篇章？剧本？隐藏属性？）未定。

## 待答清单账

答结 6 条 · 部分答结 / 收窄 5 条 · 因前提消失作废 3 条 · 新增待答 6 条
