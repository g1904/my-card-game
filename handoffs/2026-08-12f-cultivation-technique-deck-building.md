# 功法（cultivationTechnique）= 卡组的构筑单位；角色升格为有身份的模板

- id: 2026-08-12f-cultivation-technique-deck-building
- date: 2026-08-12
- topic: systems/character-profile/deck · systems/character-profile/_index · systems/character-profile/power · systems/character-profile/item · systems/adventure-event · terminology
- status: distilled
- distilled-to: `terminology.md`, `systems/character-profile/deck/_index.md`, `systems/character-profile/_index.md`, `systems/character-profile/power/_index.md`, `systems/character-profile/item/_index.md`, `systems/adventure-event/_index.md`, `systems/player-profile/codex/enemy-codex.md`, `open-questions/`, `answer-logs/log-0812a.md`, `systems/enemies/_index.md`, `open-questions.md`, `01-combat.md`, `02-event-options.md`, `06-meta-progression.md`, `07-codex-monetization.md`, `update-log.md`

## Intent（distilled）

**一句话：** 卡组不再是一堆散卡，而是由**功法（cultivationTechnique）**——成组入组、可整组升阶的卡牌集合——搭起来的；角色也从「程序化生成的空白人」升格为**有身份的模板**，自带一个神通与两个绑定功法。

### 1. 功法 = 卡组的构筑单位（新概念）

- **一个功法 = 一组必须整组入组的卡牌**（一张或多张）。功法是玩家做构筑决策的**颗粒度**——他选的不是一张牌，是一套路数。
- **卡组由若干功法构成**，数量不限。
- **功法带「层数」**（`TechniqueTier`），表示角色对这门功法钻研到什么程度。
- **每种功法像一只独特的宝可梦，会随进程进化。**

### 2. 进化 = 整组替换（裁决 ④）

层数提升时，**该功法在卡组中的那组牌被整组替换为更强的一版**——不是同一批牌的数字变大，也不是往里追加新卡。

- 每个层数对应一整套卡牌定义，玩家在卡面上直接看得见「我这门功法变了」。
- 内容成本明写：**每门功法 × 每层各一套定义**。
- **推论：卡组规模不随层数增长**——升阶换的是牌的质量不是数量，故层数系统与「疲劳把卡组规模换算为后期失血速率」这条既定压力**互不干涉**（弃置与学新才动规模）。

### 3. 卡组构成 = 功法展开的牌 ∪ 游离散牌（裁决 ③）

功法是**构筑单位**，不是卡组的完全划分：

| 来源 | 进入方式 |
|---|---|
| 功法 | 整组入组 / 整组替换 / 整组移除 |
| 游离散牌 | 业障（事件负向奖励塞入）· 单卡奖励 |

**既有的两条通道原样成立**，不推翻 `deck/_index.md` 推论④。

### 4. 角色 = 有身份的模板

- **开局随机分配一个角色。**
- **每个角色自带一个神通（`CharacterPower`）与两个功法**，且**与角色绑定**——同一个角色的每一局，神通与这两门功法都相同。
- 这把角色从「程序化生成的一组数值」升格为**内容条目**：角色是可辨认的身份，跨轮回的熟悉感由此产生。

### 5. 开局构筑 = 一个强制的 buff 事件（裁决 ① · 推翻草稿原文）

**形态取 Slay the Spire 第一章的味道，而非炉石竞技场的多轮抽选。**

- 起始事件中**必有一个强制事件**，让玩家在其中选择**想要哪一种功法**与**想要哪一件法宝**——各三选一。
- 开局底盘因此是：**2 个角色绑定功法 + 1 个选来的功法 + 1 件选来的法宝**。
- **构筑的多轮性由 adventureEvent 承载**，不由开局承载（见第 6 节）。

### 6. 轮回中的构筑变更（三种操作）

玩家在 adventureEvent 中可以：

| 操作 | 作用对象 |
|---|---|
| **升阶** | 提升某门已有功法的层数 |
| **弃置** | 移除某门已有功法 |
| **学新** | 学会一门新功法 |

**弃置不设限（裁决 ⑤）：角色绑定的那两门功法同样可被弃置。** 角色给的是起手形状，不是不可动摇的底盘——重构空间完全开放。

- **退化情形明写：卡组可以被弃空。** 这不需要新规则来阻止——既有的疲劳规则（抽牌堆空后每次抽牌 −1 道念）已经完整表达了它的后果，且「打不过也得打、输是本作的正常出口」是既定取向。是否要在内容侧回避这种局面（例如卡组只剩一门功法时不再提供弃置选项），归内容排期。

### 7. 定名裁决（裁决 ②）

| | 定名 | 说明 |
|---|---|---|
| 新概念 | **功法 / `CultivationTechnique`** | 占用「功法」一词 |
| 既有次类型 | `power.technique` 功法 → **`power.mystic_art` 秘术** | 中文名与 id **一并**改——英文 `technique` 与 `cultivationTechnique` 在代码侧同样会混淆，只改中文名等于把撞名搬到标识符层 |
| 功法的等级 | **层数 / `TechniqueTier`** | 既有 `level`（境界内层级，炼气 1–13 层……）是承重字段且已登记在 `terminology.md`，**不动**；功法侧另取名，使 UI 与文档中两个量一眼可分 |

## Clarifications（interview 产物）

1. **「炉石竞技场式的多轮择一」描述的是哪一段？** → **推翻草稿第 1 行。** 实际形态是「StS 第一章 + 竞技场的味道」：一个**强制 buff 事件**让玩家选功法与法宝。原文「starting deck is like hearthstone arena mode, where player choose among options several times」作废；构筑的多轮性落在 adventureEvent 而非开局。
   - 附带查证：草稿写「As said before」，但**全库检索不到任何关于炉石竞技场式构筑的既有记载**——它在设计库中从来不是既有定案。
2. **「功法」撞名怎么裁？** → 新概念占用「功法」，既有次类型改名为 **秘术 `power.mystic_art`**（中文名与 id 一并改）。
3. **卡组是否被功法完全划分？** → **否**：功法 + 游离散牌并存，既有的业障 / 单卡奖励两条通道不动。
4. **「像宝可梦一样进化」的机制？** → **整组替换为更强版本**（每层一整套卡牌定义）。
5. **功法的 level 与既有 level 撞名？** → 功法侧另取名 **层数 / `TechniqueTier`**；角色的 `level` 不动。
6. **角色绑定的两门功法能否弃置？** → **都能弃，不设限**（用户选择了非推荐项；「至少保留一门」的下限不设）。

## 自行推演（🔵 · 依据既有设计逻辑必然得出）

- **强制 buff 事件不需要新机制。** 既有 `eventPriority` 两档（`0` 常态 / `1` 收窄有效可选集）+ `ifMandatory` 已能表达「本批必须进这个」，起始事件走既有通道即可。Source 依据：`handoffs/2026-08-06c-skip-channel-removal-priority-two-tier-and-location-codex-edges.md`。
- **三选一候选必须走 `AllEnabled()` 抽取 + 带种子的 RNG 子流**——它是「从内容集合抽取」的标准形态。依据：`.claude/rules/data-resource-rules.md`、`state-save-rules.md`。
- **功法与角色都是新的内容类型**（`CultivationTechniqueData` / `CharacterData`：稳定 `Id`、`ContentEnabled`、经 ContentRegistry 加载、`.tres` 编写）。依据：`.claude/rules/data-resource-rules.md`。
- **存档存 build 层而非展开层**：卡组落存档的是「功法 `Id` + 层数」列表 + 游离牌 `Id` 列表，展开成卡牌集合由内容侧完成。依据：既定的「存档只记 `Id`，静态字段挂 `Resource`」。
- **战斗内完全不受影响。** 功法是**战斗外的构筑层**；参战方组装时卡组已展开为卡牌集合，`activeCombat` 仍只记各区 `Id` 序列，「一场战斗内卡牌是闭集」原样成立。
- **三种操作走既有事务通道**：升阶 / 弃置 / 学新都是轮回级卡组变更，走 `ProfileChangeSpec` → `TryApply`，不新增存档点。依据：`deck/_index.md` 推论④。
- **敌人侧不引入功法。** 输入只讲角色侧；`EnemyData` 的样本卡组仍是直接的卡牌列表。**推论：敌人图鉴词条②「功法简介」现在是一个纯风味文案名**，不指向 `CultivationTechnique` 系统概念——写作规格不变，但须点明以免被读成系统联动（敌人是否也该以功法构筑，见 Open questions）。

## Open questions

- **功法的规模参数。** 一门功法含几张牌、层数上限是几、每层的替换幅度多大 —— 与「一张牌该产多少道念」同属 **ch1 数值标杆专场**。→ `systems/balance.md`、`systems/character-profile/deck/`。
- **强制 buff 事件属九类中的哪一类**（Research 闭关？Social 社交？还是第十类）—— 分类法归 ADR-0002，需要一次裁定。→ `systems/adventure-event/_index.md`、`decisions/ADR-0002-adventure-event-taxonomy.md`。
- **角色模板池的形态。** 池中有几个角色、是否账号级逐步解锁、能否重抽或指定 —— 涉及元进程压力模型。→ `systems/character-profile/_index.md`、`systems/player-profile/`。
- **候选里出现已持有功法怎么办**（排除？还是折算为一次升阶？）—— 三选一抽取的边界情形，输入未覆盖。→ `systems/character-profile/deck/`。
- **敌人是否也以功法构筑卡组。** 当前 `EnemyData` 是直接卡牌列表；若敌人也用功法，图鉴词条②「功法简介」可与系统概念合流，反之它保持为纯风味文案。→ `systems/enemies/`、`systems/player-profile/codex/enemy-codex.md`。
- **卡组被弃空的内容侧态度。** 规则层允许（疲劳规则已表达后果），是否在内容侧回避（只剩一门时不给弃置选项）未定。→ `systems/adventure-event/`、`systems/balance.md`。
- **功法三选一 / 法宝三选一的抽取归哪条 RNG 子流**（复用 `reward`，还是新开一条）。→ `systems/common-properties.md`。

## Notes / triage

- 输入：`inbox/draft-0812a.md`（已归档至 `inbox/archive/`）。
- 两轮 interview 共 7 项裁决，其中 **1 项推翻了草稿原文**（第 1 行的炉石竞技场式多轮择一）。
- **不推翻任何既有 ADR 或定案**；唯一的既有内容改写是次类型 `power.technique` → `power.mystic_art`（纯定名，不动语义与结构）。
- **纯客户端，无跨库影响**——功法与角色模板都是本地内容条目，走既有的 content-service overlay 分发面，不新增协议契约。

## 待答清单账

整条答结 0 条 · 部分移出 1 条 · 新增待答 7 条
