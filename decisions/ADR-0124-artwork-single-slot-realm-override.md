# ADR-0124 — `Artwork` 基数恒为单格；境界覆写只落 `CharacterData.RealmArtworks`

- **状态：** Accepted
- **日期：** 2026-08-30
- **来源：** handoffs/2026-08-30-realm-progression-artwork-basis.md

## 背景

「境界晋升是否改变角色 / 敌人外观」原本是一条美术产能问题，却反向卡住工程地基：`systems/common-properties.md` 的 `Artwork` 一节自挂了「若答为随境界改变则本节形态要重做」的前置依赖，而该文档是 derive 顺序第 1 位、被几乎所有内容与服务代码依赖。不先裁掉它，第一批 `.tres` 的 `Artwork` 基数可能推倒重来。

## 决策

**共有字段 `Artwork` 的基数恒为「一条内容一格」，境界维度不进本字段。** `decisions/ADR-0120-content-artwork-and-enemy-lines.md` 的七类挂载面、单格形态、可空语义、`LoadAll()` 汇总告警、ViewModel 单点占位回落、不落存档——一字不动。

**玩家角色随境界换形象，形态是 `CharacterData` 自有的一格稀疏覆写数组** `RealmArtworks : RealmArtwork[]`（内嵌 `[GlobalClass] RealmArtwork : Resource` = `Realm Realm` + `Texture2D Artwork`），默认空数组 = 全程用基础图。ViewModel 取两级回落：境界覆写 → 基础图 → 占位资产；无当前轮回（角色选择屏 / 图鉴 / 主菜单）时跳过第一级。三条加载期校验 R-1 ~ R-3 见 `systems/character-profile/_index.md`。

**敌人与其余五类不随境界换相。** 同批收窄「境界越高画面越沉」的适用口径：**按条目自身的叙事定位取沉，不按运行时赋级取沉**；方向本体（grimdark / 残酷的攀登）不变。

## 理由

- **七个挂载面里能被境界索引的只有 `CharacterData` 一个**：敌人的境界是 `EnemyInstance` 的物化产物、不在模板上（`decisions/ADR-0044-enemy-leveling-band.md`），地域三章共用同一张图（`decisions/ADR-0042-location-flat-set-and-single-map.md`），其余各类与境界正交。按判据卡「只有一个落点的字段不进 `common-properties.md`」，境界维度即属 `CharacterData` 自有字段。
- **敌人不换相不是「不值得做」，而是没有可索引的键**：`ChapterScope` 空 = 三章通用是常态 ⇒ 按境界分版必有恒空格，而恒空格叠上「缺失即回落占位」= 玩家看到的是占位图而不是这个敌人，且该故障被「逐条目不告警」的既定告警形态屏蔽。它与「三章共用同一张地图、难度的篇章差异不由换一张更难的图承载」是同一道题的同一个答案：**结构保持简单，难度放进数值。**
- **取稀疏而非定长四格**：定长里「这一档没画」与「这一档就用基础图」不可区分，而两者的正确行为不同；稀疏把它变成干净可判的条件。
- 与同批的 `EnemyData.Lines : EnemyLine[]` 完全同构，不引入新的结构范式。
- **境界来源是既有存档字段 `CharacterProfile.realm`** ⇒ 零新增存档字段、不 bump `schemaVersion`、无迁移、后端零配合。

## 备选方案

- **`Artwork` 升为按境界索引的结构（共有字段层面）** — 只有一个落点却上移到七个挂载面，其余六类恒空。
- **定长四格数组** — 「没画」与「就用基础图」不可区分。（草稿否决它时用的第二条理由「把 `Realm` 的成员序变成序列化契约」**不采用**：稀疏数组里的 `[Export] Realm Realm` 在 `.tres` 中同样序列化为整数，对两种形态同样成立。）
- **字段名与元素类型名逐字相同（`RealmArtwork` / `RealmArtwork`）** — 类内成员查找会遮蔽同名类型，`new RealmArtwork()` 在 `CharacterData` 内无法解析。
- **敌人按境界分版立绘** — 见上，无可索引的键。

## 后果

- **`systems/common-properties.md` 的 `Artwork` 一节自挂的前置依赖就此解除**，该文档作为 derive 第 1 步的 ready 判定不再带条件。
- 资产量级：全量 20 张（池规模 5 × 4 档），MVP（炼气 → 筑基）10 张，稀疏形态使首发下限为 5 张（每角色一张基础图）。**首发不承诺出满四档。**
- 角色形象是全库唯一一条「资产乘数」，落在条目数最小的类目上且为纯加法——近期实际成本接近零，买的是「日后想做时不必改结构」。「突破」这个节拍在视觉上此前没有任何兑现，本条是它唯一的兑现通道。
- overlay 语义与共有字段逐字同款：`.tres` 内子资源随该条 `.tres` 被覆盖，**指向必须落在随包基线内**——与同批的「二进制资产不经 overlay / blob 下发」（`decisions/ADR-0125-no-binary-over-overlay.md`）相容。
- 因此必须这么写的文档：`systems/common-properties.md`（基数一行 + 挂载面表内 `CharacterData` 的括注）· `systems/character-profile/_index.md`（字段表第 4 格 + 「角色形象随境界的覆写」段 + R-1 ~ R-3）· `systems/viewmodel.md`（两级回落）· `art/visuals/_index.md` · `decisions/ADR-0100-art-direction-painterly-chinese-grimdark.md` 与 `art/visuals/art-direction.md`（「越高越沉」的口径收窄）· `decisions/ADR-0120-content-artwork-and-enemy-lines.md`（后果补一条指向本落点）。
