# 设计文档重构 —— 类模型化（class-concept）结构 + explore/travel/地域 新概念

- id: 2026-07-24-docs-restructure-class-model
- date: 2026-07-24
- topic: 全库重构（systems 结构化、30-content 并入、adventure-event/character-profile/player-profile 折叠、services 化 run-manager/adventure-plot、architecture.md、explore/travel/地域 新概念、.claude 知识库降为引用层）
- status: distilled
- distilled-to: terminology.md, systems/_index.md, systems/architecture.md, systems/common-properties.md, systems/game-progression.md, systems/adventure-event/**, systems/character-profile/**, systems/player-profile/**, systems/services/**, systems/balance.md, open-questions.md（.claude/knowledge/* 引用层改造随后）, `systems/**`

## Intent（distilled）

**一句话：** 把 `game-design-documents/` 从「systems + content 两分」重构为「**以类概念（Java class 式）组织的单一 systems 树**」——内容并入其所属系统、adventure-event 展开为按类型分文件夹的深层结构、run-manager/adventure-plot 降为对外提供 API 的**微服务**，并让 `.claude/knowledge/*` 退化为指向本库的**引用层**（本库成为**游戏内容与技术结构的双重事实来源**）。

### 设计理念
- **systems ≈ 一组 Java 类。** 每个系统是一个「类」，其内容（原 30-content 的数据定义）是该类的「字段 / 内嵌类型」，因此内容并入系统而非另立门户。`30-content/` 作为独立层被撤销。
- **复杂类型下沉为文件夹。** 简单主题保持单 `.md`；复杂主题（每个 adventure-event 子类型、deck、item、player-power……）各占一个文件夹，含 `_index.md` 与 `common-properties.md`，为未来「每个具体设计一个 Markdown」预留结构。
- **共有属性显式化。** 每一层的共有字段抽到 `common-properties.md`：adventure-event 各子类型各自一份、adventure-event 顶层一份、systems 顶层一份。
- **run-manager / adventure-plot = 微服务。** 二者不再是并列系统，而是对 `character-profile` 与 `player-profile` 提供 API 的服务，移入 `systems/services/`。

### 目标结构（systems/）
```
systems/
  _index.md                    ← 重写：反映类模型化结构
  architecture.md              ← 新增：代码库如何运作的高层指南（系统结构总览）
  common-properties.md         ← 新增：系统层共有属性
  balance.md                   ← 由 30-content/balance.md 迁入
  game-progression.md          ← 取代 map-progression.md（+地域 location、+travel 路由；并入 blinds-antes）
  adventure-event/             ← 取代 adventure-event-combat.md
    _index.md
    common-properties.md
    combat/       _index.md + common-properties.md   （并入 30-content/enemies.md）
    finale/       _index.md + common-properties.md
    mystery/      _index.md + common-properties.md
    practice/     _index.md + common-properties.md
    exchange/     _index.md + common-properties.md
    research/     _index.md + common-properties.md
    explore/      _index.md + common-properties.md   ← 新类型「探索秘境」
    social/       _index.md + common-properties.md
    travel/       _index.md + common-properties.md   ← 新类型「前往某处地点」（地图路由）
  character-profile/           ← 取代 card-resolution.md + deck-hand.md
    _index.md
    deck/         _index.md（+ common-properties.md）（并入 30-content/cards.md）
    item/         _index.md（+ common-properties.md）
    currency.md   ← 由 energy-economy.md 拆出
    life.md       ← 由 energy-economy.md 拆出
    mana.md       ← 由 energy-economy.md 拆出
  player-profile/              ← 取代 shop-rewards.md + relics-jokers.md
    _index.md
    player-item/  _index.md（+ common-properties.md）（并入 shop-rewards 的可购道具语义）
    player-power/ _index.md（+ common-properties.md）（并入 relics-jokers.md）
  services/                    ← 新增：微服务层
    run-manager.md             ← 迁入并重述为「提供轮回生命周期 API」
    adventure-plot.md          ← 迁入并重述为「提供隐藏剧本 API」（并入 30-content/events.md）
  scoring.md                   ← 保留（draft 未提及；见 Open questions）
```

### 30-content → systems 映射（30-content/ 整体删除）
| 原文件 | 去向 |
|--------|------|
| `cards.md` | `character-profile/deck/` |
| `relics.md` | `player-profile/player-power/` |
| `enemies.md` | `adventure-event/combat/` |
| `adventure-events.md` | `adventure-event/`（拆入各子类型） |
| `events.md` | `services/adventure-plot.md` |
| `blinds-antes.md` | `game-progression.md` |
| `balance.md` | `systems/balance.md`（顶层） |

### 新概念
- **explore / 探索秘境（AdventureEvent-Explore）：** adventure-event 的新子类型（第八类）。语义：探索一处秘境。
- **travel / 前往某处地点（AdventureEvent-Travel）：** adventure-event 的新子类型（第九类），**功能上是一次地图路由选择**——刷新角色所在的 location（地点）。
- **地域 / location：** 新的抽象概念，**框定 `eventOptions`**（角色当前地点决定了下一批可能出现的修行事件池）。归属 `game-progression.md`（travel 通过它换地点）。

### 引用与工具链影响
- **大量引用重构：** 所有跨文档链接（`systems/*`、`30-content/*`、`handoffs/*` 的 distilled-to、`_index.md`、`terminology.md`、`open-questions.md`、各 ADR）指向被移动 / 删除文件之处，都要重写到新路径。
- **`.claude/knowledge/*` 降为引用层：** 本库成为**内容 + 技术结构的双重事实来源**；`.claude/knowledge/*` 改为引用本库对应文件，而非自持副本。`.claude/knowledge/systems/_index.md`、`data/_index.md`、`dictionary.md` 及 `Context.md` 的知识导航表需同步。这是对「设计意图 vs Claude 知识」关系的实质性调整——**ADR 候选**。

## Open questions
- **character-profile 结构不一致（draft 原样）：** `deck` / `item` 为文件夹，而 `currency` / `life` / `mana` 为扁平 `.md`。按 draft 原样执行；是否应把 currency/life/mana 也升为文件夹（与 class-concept 一致）待确认。
- **shop-rewards 的双重语义：** shop（Exchange）既是获取机制（→ `adventure-event/exchange/`），又产出可购道具（→ `player-profile/player-item/`）。当前把**道具定义**归 player-profile、**交易机制**归 adventure-event/exchange；是否需要更清晰的切分待确认。
- **player-profile「etc.」范围：** draft 写「player-item, player-power, **etc.**」——除这两者外是否还有其他 player-profile 子类型（如 achievements、account-info、game-setting，参见 run-manager 元进程字段）待确认。
- **scoring.md 去向：** draft 未提及。当前**原地保留于 systems 顶层**。它是否也应并入某系统（如战斗 / game-progression），或在 life+mana 模型下被废弃，待确认。
- **enemies 归属：** 当前归 `adventure-event/combat/`（敌人只在 Combat/Finale 出现）。若未来 Practice 等也用敌人，是否应升为共享内容层待确认。
- **微服务边界与 API 契约：** run-manager / adventure-plot 作为微服务「对 character-profile / player-profile 提供 API」——具体 API 面（方法 / 事件 / 数据契约）尚未定义，属 architecture.md 待细化。
- **`.claude/knowledge` 引用层改造形态：** 是逐文件替换为「见 `game-design-documents/...`」的薄引用，还是保留提炼摘要 + 回链？影响 sync-knowledge 技能语义——建议以 ADR 固化。

## Notes / triage
- 来源草稿：`inbox/draft-0724.md`。
- 用户裁定（本 session）：① 删除 30-content 并按上表语义映射；② run-manager/adventure-plot 移入 `services/`，未提及文件（scoring 等）原地保留；③ 先出 handoff，随后分派 agents 执行重构。
- 执行分派：见本 session 汇报——按 adventure-event / character-profile+player-profile / progression+services+顶层 三组并行创建，末段单一 pass 统一删除旧文件、重写索引、刷新引用、改造 `.claude/knowledge`。
