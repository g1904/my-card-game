# 两门绑定功法的初始层数恒为 1（`CharacterData` 不加字段）

- id: 2026-09-02-bound-technique-initial-tier
- date: 2026-09-02
- topic: systems/character-profile/_index.md · systems/character-profile/deck/_index.md
- status: distilled
- distilled-to: systems/character-profile/_index.md, systems/character-profile/deck/_index.md

## Intent（distilled）

`CharacterData` 字段表第 8 行长期挂着一个 ⟨待定⟩：**角色开局绑定的那两门功法各处于第几层**。本次把它收口为 **恒为第 1 层**，并且 **`CharacterData` 不新增任何字段** —— 它不是一格数值旋钮，而是一条与既有语义一致的明文口径。

### 四条依据

- **① 「入组」的层数已有唯一既定语义。** `DeckChangeElement` 的 `LearnTechnique` 明文 `Tier = 1`。绑定功法是角色开局时进入卡组的功法，与闭关 / 商店学到的那一门在卡组里是同一种东西（同一个 `TechniqueEntry`、同一条 `DeckElements` 通道）。给它第二套入组规则 = 让「一门功法怎么进卡组」有两个答案。
- **② 开局底盘的三门功法层数因此一致。** 开局底盘 = 2 个绑定功法 + 1 个选来的功法 + 1 件选来的法宝，其中「选来的那门」经闭关同一条链入组、恒为第 1 层。另两门若起手 ≥2，玩家第一屏构筑里就出现「同为开局给的功法，两门比第三门强一档」这种无从解释的落差 —— 而层数在卡面上可见（升阶 = 整组替换，牌面直接变）。
- **③ 它避开一条与既定取向相反的强度轴。** 灵根的唯一规则后果是**硬性修习准入**，角色差异被有意推向「能修哪一路」而非「谁更强」。起始层数逐条编排恰是一条纯强度的角色间差值，且与已登记的「角色强度差可能塌缩为单一最优」这条代价直接叠加。
- **④ 它不与未定的 `MaxTier` 纠缠。** 起始层数的合法上界就是 `MaxTier`，而 `MaxTier` 仍待校准 ⇒ 逐条编排此刻只能定结构、定不出取值，阻塞面不会真正解除；而「恒为 1」对任何 `MaxTier` 取值都成立。

### 落地面

- **字段面：零增量。** `TechniqueIds : string[]`（长度恒 2）不动；`content/character/` 的条目只写两个功法 `Id`，不写层数。
- **加载期校验：零新增。** 存档侧既有的 `Tier < 1 → PushError` 已覆盖，模板侧没有可填错的格。
- **存档 / 后端：零影响。** `CharacterData` 是静态模板、不落存档、不进上行负载 ⇒ 不 bump `schemaVersion`、无迁移、后端零配合。
- **内容层：** 每门绑定功法的第 1 层那一套卡牌定义必然被使用（首玩即见），不产生「写了但没人见得到」的死内容；「第一次升阶」的正反馈落在 ch1 内，可升空间 = 完整的 `MaxTier − 1` 级，不被起手层数预先吃掉一段。

### 日后要开的最小路径（写下来，首批不做）

`TechniqueIds : string[]` → `BoundTechniques : BoundTechnique[]`（长度恒 2），元素为 `TechniqueId : string` + `InitialTier : int`（默认 1，与今天的口径等价）；配三条加载期校验（`TechniqueId` 解析不到 / `InitialTier < 1` / `InitialTier > 该功法 MaxTier`，均 `PushError` 带 `characterId` + 功法 `Id`）。**仍是零存档增量**（模板静态字段），代价只在 `.tres` 结构与那一行字段表。集合字段名取复数、元素类型名取单数（同 `RealmArtworks` / `RealmArtwork`）。

## Clarifications

- **起始层数：恒为 1，还是由内容侧逐条编排 → 选项 A：恒为 1，`CharacterData` 不加字段（用户裁决 · 批量评审）。** 逐条编排（`BoundTechnique.InitialTier`）作为纯加法退路写进文档、本次不实现。
- **`CharacterData` 字段表第 8 行的处置 → 删行，不留空行占位；结论改由「明确不带的格」一条承载**（采纳标准默认，依据：活文档只保留最新设计、不留考古）。
- **同一份文档「待决问题」小节里的重复登记一并删除**（采纳标准默认：同一条不得一边写明文、一边列为待答）。

## Open questions

- **本条不解决「全池指定下角色强度差是否仍塌缩为单一最优」** —— 它待实测；本方案只是不给它再加一个输入。
- `content/character/` 条目写到 `ready` **仍另阻于**功法条目（10 门）与神通条目（5 个）尚不存在。本条只解除三个前置里的一个。

## Notes / triage

- 路由：`systems/character-profile/_index.md`（字段表第 8 行删除 → 「明确不带的格」+ 最小路径一句；「待决问题」小节删同条）· `systems/character-profile/deck/_index.md`（「轮回中的构筑变更」一节补一句推论）。
- `decisions/` 本次零改动 —— 本条与 `ADR-0054` / `ADR-0055` / `ADR-0123` 及 `LearnTechnique` 的既定语义完全同向，只是把一处留白按既有语义补齐，不构成决策变更。
- 存档 / 后端零改动。
