# `Artwork` 的基数恒为单格；境界覆写只落 `CharacterData`

- id: 2026-08-30-realm-progression-artwork-basis
- date: 2026-08-30
- topic: systems/common-properties.md · systems/character-profile/_index.md · systems/viewmodel.md · art/visuals · decisions/ADR-0100 · decisions/ADR-0120
- status: distilled
- distilled-to: systems/common-properties.md、systems/character-profile/_index.md、systems/viewmodel.md、art/visuals/_index.md、art/visuals/art-direction.md、decisions/ADR-0100-art-direction-painterly-chinese-grimdark.md、decisions/ADR-0120-content-artwork-and-enemy-lines.md

## Intent（distilled）

「境界晋升是否改变角色 / 敌人外观」原本是一条美术产能问题，却反向卡住工程地基：`systems/common-properties.md` 的 `Artwork` 一节自挂了一条「若答为随境界改变则本节形态要重做」的前置依赖，而该文档是 derive 顺序第 1 位。本次把它拆成两半分别答齐。

### 1. 数据形态：共有字段 `Artwork` 的基数恒为「一条内容一格」

七个挂载面里能被境界索引的只有 `CharacterData` 一个 —— 敌人的境界是 `EnemyInstance` 的物化产物而不在模板上（赋级带是角色当前等级的 `±2` 对称带、赋级函数不接受任何区间覆盖参数；`ChapterScope` 空 = 三章通用是常态），地域三章共用同一张图，卡牌 / 法则 / 神通 / 古宝 / 法宝 / 事件插图与境界正交。按判据卡「只有一个落点的字段不进任何 `common-properties.md`」⇒ 境界维度属 `CharacterData` 自有字段。

`ADR-0120` 的七类挂载面、单格形态、可空语义、`LoadAll()` 汇总告警、ViewModel 单点占位回落、overlay 语义、不落存档 —— 一字不动，只在其「后果」补一条指向本次落点。

### 2. 敌人与其余五类不随境界换相

不是「不值得做」，而是**没有可索引的键**：模板上没有境界，要按境界换图只能在 ViewModel 里拿运行时实例的等级反查境界；`ChapterScope` 空 = 三章通用是常态 ⇒ 按境界分版必有恒空格；而恒空格叠上「缺失即回落占位」＝ 玩家看到的是占位图而不是这个敌人，且该故障被「逐条目不告警」的既定告警形态屏蔽。它与「三章共用同一张图、难度的篇章差异不由换一张更难的图承载」是同一道题的同一个答案：**结构保持简单，难度放进数值。**

### 3. 玩家角色随境界换形象，形态是 `CharacterData` 自有的一格稀疏覆写数组

`RealmArtworks : RealmArtwork[]`，稀疏覆写，默认空数组 = 全程用基础图；内嵌 `[GlobalClass] RealmArtwork : Resource` = `Realm Realm` + `Texture2D Artwork`。与同批落下的 `EnemyData.Lines : EnemyLine[]` 完全同构，不引入新的结构范式。

- **取稀疏而非定长四格**：定长里「这一档没画」与「这一档就用基础图」不可区分，而两者的正确行为不同；稀疏把它变成干净可判的条件。
- **ViewModel 两级回落**（境界覆写 → 基础图 → 占位资产），**占位入口仍只有一处**；无当前轮回（角色选择屏 / 图鉴 / 主菜单）时跳过第一级、直接取基础图。
- **三条加载期校验**：R-1 同条目内 `Realm` 重复 → `PushError`；R-2 挂了却缺图 → `PushError`；R-3 空数组不告警（合法常态）。已挂条目的缺图由 R-2 拦死，故不进 `LoadAll()` 那行缺失汇总。
- **境界来源是既有存档字段 `CharacterProfile.realm`** ⇒ 零新增存档字段、不 bump `schemaVersion`、无迁移、后端零配合。
- **overlay 语义与共有字段逐字同款**：`.tres` 内子资源随该条 `.tres` 被覆盖，指向必须落在随包基线内 —— 换的是引用不是二进制，与同批「二进制资产不经 overlay / blob 下发」相容。

**资产量级：** 全量 20 张（池规模 5 × 4 档），MVP（炼气 → 筑基一个篇章）10 张，稀疏形态使首发下限为 5 张（每角色一张基础图）。**首发不承诺出满四档。**

### 4. 「境界越高画面越沉」的适用口径收窄

改为**按条目自身的叙事定位取沉，不按运行时赋级取沉** —— 一条被 `ChapterScope` 框在第三篇章的敌人天生更沉，同一条目在运行时被赋到哪一档境界不改变它的画面。方向本体（grimdark / 残酷的攀登）一字不动。

## 已接受的代价

角色形象是全库唯一一条「资产乘数」，它落在条目数最小的类目上，且因稀疏形态而是纯加法 —— 近期实际成本接近零，买的是「日后想做时不必改结构」。

「突破」这个节拍在视觉上此前没有任何兑现（战斗屏主视觉是道念对比、三章共用同一张地图、敌人不随境界换相），本条是它唯一的兑现通道。

## Clarifications（interview 产物）

- **「境界越高画面越沉」是否收窄 → 收窄，且 `ADR-0100` 与 `art/visuals/art-direction.md` 两处同改。** 草稿把这条列为「本次未裁」的张力；用户裁定按草稿建议收窄，并明确要求直接改写该 ADR 的正文那一句（而不是把限定写在下游索引里）。
- **字段名 → `RealmArtworks`（复数），元素类型名保持 `RealmArtwork`。** 推翻草稿伪码里字段名与元素类型名逐字相同的写法：类内成员查找会遮蔽同名类型。
- **草稿否决定长四格数组时用的第二条理由（「它把 `Realm` 的成员序变成序列化契约」）不采用** —— 稀疏数组里的 `[Export] public Realm Realm` 在 `.tres` 中同样序列化为整数，该理由对两种形态同样成立、不构成区分依据。承重理由只保留「没画 vs 用基础图不可区分」这一条。
- **无 `CharacterProfile` 时的边界（草稿未覆盖）→ 取基础图。** 角色选择屏 / 图鉴 / 主菜单没有当前轮回、`realm` 无值，回落链从第二级起算。
- **资产量级按池规模 5 落笔**（20 / 10 / 5）—— 草稿写作时池规模为 4，同批裁决已覆盖为 5。

## Open questions

- 无新增。「境界晋升是否改变角色 / 敌人外观」就此答结并移出待答清单。

## 决策(-> ADR)

- **ADR 候选一条：** 「`Artwork` 基数恒为单格；境界维度只落 `CharacterData` 自有字段 `RealmArtworks`（稀疏覆写）」—— 权威已在 `systems/common-properties.md` 与 `systems/character-profile/_index.md`，立档归 `/write-adr`。
