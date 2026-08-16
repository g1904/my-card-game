# 条目 id 定案 · 功法承载形态 · 次类型清单归零

- id: 2026-08-15-content-id-technique-shape-and-subtype-reset
- date: 2026-08-15
- topic: content/_index.md（id 约定 + 登记表）· systems/character-profile/deck/_index.md（功法形态 + 次类型清单）· terminology.md
- status: distilled
- distilled-to: `content/_index.md`、`systems/character-profile/deck/_index.md`、`terminology.md`

## Intent（distilled）

答结 `handoffs/2026-08-14c-content-authoring-layer.md` 留下的三项 Open question，并顺带裁定次类型清单的处置。

### ① 条目 `Id` = `<内容类型>.<snake_case_slug>`（已定案）

采纳 `content/_index.md` 的默认约定，不再标「待确认」。例：`location.yunmeng_marsh` · `player_power.crimson_vow` · `card.spirit_slash`。

- **前缀词表纪律（承重）：次类型 id 用主类型前缀（`enchantment.ambush`），内容条目 id 用内容类型全名前缀（`card.` / `character_item.` / `player_item.`）。**
  **内容条目 id 绝不用裸 `item.` / `power.`** —— 那两个词是次类型的主类型前缀（`item.pill` / `power.physique` 形态），撞上即两套 id 在同一个点分命名空间里无法区分。用 `character_item` / `player_item` / `character_power` / `player_power` 四个全名前缀，与 `terminology.md` 的四词定名（法宝 / 古宝 / 神通 / 法则）一一对应。
  这条纪律现在是空成本的（次类型清单已归零，见 ③），但**次类型重建时必然重新引入 `item.*`**，届时若无此纪律即撞车。

### ② 功法 = 轻量 header 条目 + 每层的卡牌 `Id` 列表；每张卡各自建条目（已定案 · 承重）

**采纳「每张卡单独建立条目」**（用户裁定），**成员关系写在功法侧**（功法持列表），卡牌侧不带功法标记。

- `CultivationTechniqueData` 是一份**轻量 header**：`Id` · 显示名 / 描述（`LocalizedText`）· `Rarity` · `ContentEnabled` · 层数上限 · **每层一份卡牌 `Id` 列表**。它**不内联卡牌定义**——卡牌是 `content/card/` 里各自独立的条目，功法只引用它们的 `Id`。
- **一张卡可被多门功法引用**（共享牌自然成立），这是列表方向相对标记方向多出来的表达力。

**否决「功法无独立条目、每张卡带 `(TechniqueId, Tier)` 标记」的三条理由，逐条对上既有定案：**

1. **`Rarity` 无处可挂。** 开局三选一与「学新功法」的三选一**都要抽功法**，而 `systems/common-properties.md` 已定案「凡会被抽取或置换的内容定义都带 `Rarity`」。纯标记方案里功法只是一组卡的 DISTINCT 结果，没有实体可以承载稀有度、也没有实体可以进抽取池。
2. **`ContentEnabled` 失去原子性。** 关掉一门功法要改 N 张卡的字段；**漏一张就得到一门半组功法**——直接违反「一个功法 = 一组必须整组入组的卡牌」（08-12f 承重）。header 方案下关一门功法是翻一个布尔。
3. **存档的功法 `Id` 无从校验。** 08-12f 已定案「卡组落存档的是功法 `Id` + 层数」；没有注册表条目，那个 `Id` 就是一个指向不存在之物的字符串，**交叉引用悬空校验无对象可查**，与「坏数据必须在启动期大声失败」相抵。

**另两条附带收益：** 「这一层到底是哪几张」在一处可读（标记方案要 grep 全库）；**overlay 可以热更某一层的卡牌列表**（改既有字段，落在「只改不增」内），而调整卡牌侧标记同样可热更、但没有一处能看出整组的完整性。

**否决「两侧都写」**：双向冗余需要一条额外的一致性校验，且制造第二权威。

**不推翻 08-12f 的任何一条**：整组入组 · 进化 = 整组替换 · 卡组规模不随层数增长 · 存档存 build 层 · 战斗内不感知功法 · 弃置不设限，全部原样成立。本次只是把「逐层的卡牌定义挂在它上面」这句话的形态明确为**引用 `Id` 列表**而非内联定义。

### ③ 次类型：机制保留、清单归零（已定案）

**推翻的是那张 18 行的清单初值，不是次类型机制。** 用户原话「现有次类型皆为 outdated fillers」经核对只对**清单**成立，对**机制**不成立：

- `CardSubtypeData : Resource`（`Id` / `DisplayName` / `Description` / `AllowedCardTypes` / `ContentEnabled`）、`CardData.Subtypes` 字段、加载校验与准入判据**全部保留，零改动**。
- 保留的理由是它承重：**埋伏（`enchantment.ambush`）的整套规则直接以次类型为载体**，且**效果的目标筛选按次类型走**（「所有『灵兽』获得 +1」是文档明写的「次类型存在的主要理由」）。删掉机制等于同时删掉埋伏牌与一整类 payoff 设计。

**归零的范围与例外：**

- **那张清单初值表（`sorcery.*` / `enchantment.*` / `item.*` / `power.*` / `affliction.*` 共 18 个 id）整体作废**，不建任何对应的 `.tres`。文档本就写明它「内容横向扩展时可整体重排，重排不动 schema」——本次是把它重排为**空**。
- **唯一例外 `enchantment.ambush` 保留**：它不是清单里的一个候选，而是**埋伏机制的定名**，已登记在 `terminology.md` 且被战斗规则直接引用。它天然满足准入判据（自带 payoff = 埋伏的触发规则）。
- **重建时机与判据不变**：等内容有规模后，按既有准入判据（① ≥3 个内容条目共享它；② ≥1 处目标筛选引用它）自然长出来。**没有 payoff 的次类型就是展示标签**，这条纪律原样保留——它正是防止清单再次长成 filler 的机制。
- **`power.mystic_art`（秘术）随清单一并作废**，但**它的定名动机升格为一条词表保留**：「功法」一词已被 `CultivationTechnique` 占用，日后重建 `Power` 次类型时**不得再用「功法」命名任何次类型**，`power.technique` 这个 id 同样不得复用。

### ④ 事件类内容暂不开展（已定案）

九类 `AdventureEvent` 的条目**本阶段不开张**。八个子类文档仍是空占位、等各自专场（`systems/adventure-event/_index.md` 已定的流程意图），故 `content/adventure-event/` 不建；`content/adventure-plot/`（依赖事件条目）随之顺延。

## Open questions

- **一门功法含几张牌、层数上限、每层的替换幅度** —— 08-12f 已挂在 ch1 数值标杆专场，本次不动。→ `systems/balance.md`。
- **卡牌条目与功法条目的编写顺序。** 功法持卡牌 `Id` 列表 ⇒ 先写卡牌、后写功法则无悬空；反之中间态必然悬空。是否要求成组提交（一门功法 + 它整层的卡牌一次写完）？倾向要求，但等第一门功法落笔时确认。→ `content/cultivation-technique/_index.md`（开张时写入）。
- **共享牌的规模纪律。** 一张卡可被多门功法引用已成立，但「一张牌最多被几门功法共享」若无约束，功法之间的辨识度会被稀释。→ `systems/character-profile/deck/`。

## Notes / triage

本 handoff 答结了 `2026-08-14c` 的全部三项 Open question（条目 id 形态 / 事件类开张 / 一份文档 ↔ 一个还是一组 `.tres`——第三项由 ② 答结：**一份文档 = 一个 `.tres`**，功法与它的卡牌是若干份彼此引用的文档）。
