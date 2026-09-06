# ADR-0146 — 两门绑定功法恒以第 1 层入组（`CharacterData` 不加字段）

- **状态：** Accepted
- **日期：** 2026-09-02
- **来源：** handoffs/2026-09-02-bound-technique-initial-tier.md

## 背景

角色模板 `CharacterData` 通过 `TechniqueIds : string[]`（长度恒 2）绑定两门开局功法，但「这两门各处于第几层」长期是字段表里的一处留白。两条路摆在面前：把它做成内容侧逐条编排的一格数值（模板上加字段），或把它定成一条与既有语义一致的明文口径。这一格拖着两条下游——`content/character/` 的条目写不到 `ready`，而它的合法上界 `MaxTier` 本身仍待校准。

## 决策

**角色绑定的那两门功法恒以第 1 层入组**，与 `DeckChangeElement.LearnTechnique` 明文的 `Tier = 1` 同款；**`CharacterData` 不新增任何字段**，`TechniqueIds : string[]` 不动，`content/character/` 的条目只写两个功法 `Id`、不写层数。加载期校验零新增（存档侧既有的 `Tier < 1 → PushError` 已覆盖，模板侧没有可填错的格）。逐条编排作为**纯加法退路**记在文档里、首批不做：`TechniqueIds` → `BoundTechniques : BoundTechnique[]`（元素含 `TechniqueId` + `InitialTier`，默认 `1`）。

→ `systems/character-profile/_index.md`「明确不带的格」。

## 理由

- **「入组」的层数在本库只有一个语义。** 绑定功法与闭关 / 商店学来的那门在卡组里是同一种东西（同一个 `TechniqueEntry`、同一条 `DeckElements` 通道）；给它第二套入组规则，等于让「一门功法怎么进卡组」有两个答案。
- **开局底盘的三门功法层数因此一致。** 层数在卡面上可见（升阶 = 整组替换），绑定功法若起手 ≥2，玩家第一屏构筑里就出现「同为开局给的两门比第三门强一档」这种无从解释的落差。
- **它避开一条与既定取向相反的强度轴。** 灵根的唯一规则后果是硬性修习准入（`decisions/ADR-0123-affinity-technique-learning-gate.md`），角色差异被有意推向「能修哪一路」而非「谁更强」；起始层数逐条编排恰是一条纯强度的角色间差值。
- **它不与未定的 `MaxTier` 纠缠。** 逐条编排此刻只能定结构、定不出取值，阻塞面不会真正解除；而「恒为 1」对任何 `MaxTier` 取值都成立。
- 内容面无死角：每门绑定功法第 1 层那套卡牌必然被使用，且「第一次升阶」的正反馈完整落在 ch1 内。

## 备选方案

- **由内容侧逐条编排起始层数（模板上加 `BoundTechnique.InitialTier`）** — 否决：为角色间再添一条纯强度轴、与灵根定位相抵；且上界 `MaxTier` 未定，此刻定不出取值。它作为零存档增量的加法退路保留在文档中，不作为当前形态。

## 后果

- **零字段增量、零校验增量、零存档 / 后端影响**：`CharacterData` 是静态模板，不落存档、不进上行负载 ⇒ 不 bump `schemaVersion`、无迁移、后端零配合。
- 相关文档因此这么写：`systems/character-profile/_index.md`（结论落在「明确不带的格」并附最小加法路径，字段表不留占位行）· `systems/character-profile/deck/_index.md`（推论：开局底盘三门功法起手层数一致）。
- 与 `decisions/ADR-0054-technique-as-deck-unit.md`、`decisions/ADR-0055-character-as-content-template.md` 同向：功法是卡组单元、角色是内容模板，本条把模板侧的一处留白按既有入组语义补齐。
- 放弃了「用起始层数做角色间差异化」这一手段。
- `content/character/` 条目写到 `ready` 的三个前置解除其一，仍另阻于功法条目与神通条目尚不存在。
