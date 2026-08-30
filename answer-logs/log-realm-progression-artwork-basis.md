# Answer log realm-progression-artwork-basis

- 日期：2026-08-30
- 来源：`inbox/solution-draft-realm-progression-artwork-basis.md`（裁决 2026-08-28 · 「境界越高画面越沉」的口径于 2026-08-30 合并 interview 追裁）
- 移出条数：2

---

**境界晋升是否改变角色 / 敌人外观（即共有字段 `Artwork` 的基数）** → 分两半答定：

- **数据形态：基数恒为「一条内容一格」。** 七个挂载面里能被境界索引的只有 `CharacterData` 一个，按判据卡「只有一个落点的字段不进任何 `common-properties.md`」⇒ 境界维度落该类自有字段。`ADR-0120` 的七类挂载面、单格形态、可空语义、告警形态、占位回落、overlay 语义全部不动。
- **敌人与其余五类不换相**：模板上没有境界（境界是 `EnemyInstance` 的物化产物、赋级带无覆盖参数、`ChapterScope` 空 = 三章通用）⇒ 没有可索引的键；恒空格叠上「缺失即回落占位」会让玩家看到占位图而非该敌人，且被「逐条目不告警」的既定告警形态屏蔽。
- **玩家角色随境界换形象**，形态是 `CharacterData` 自有的一格稀疏覆写数组 `RealmArtworks : RealmArtwork[]`（默认空数组 = 全程用基础图）+ 内嵌 `RealmArtwork : Resource` + 三条加载期校验 + ViewModel 两级回落。境界取既有存档字段 `CharacterProfile.realm` ⇒ 零存档影响、后端零配合。量级：全量 20 张、MVP 10 张、首发下限 5 张。

归档去向：`systems/common-properties.md`（`Artwork` 一节的基数收口 + 挂载面回链）· `systems/character-profile/_index.md`（`RealmArtworks` 字段面 + 投影段 + 三条校验）· `systems/viewmodel.md`（两级回落）· `art/visuals/_index.md`（类目表两行 + 「一条内容一张，不随境界分版」通则）· `decisions/ADR-0120-content-artwork-and-enemy-lines.md`（「后果」补一条）。

---

**「境界越高，画面应越沉」的适用口径** → 收窄为**按条目自身的叙事定位取沉，不按运行时赋级取沉**；`ADR-0100` 与 `art/visuals/art-direction.md` 两处同改，方向本体（grimdark / 残酷的攀登）一字不动。

原因：敌人条目没有自己的境界，无限定的原句在它身上没有可执行的兑现方式，第一份敌人 art guide 会撞上一个数据形态兑现不了的要求。

归档去向：`decisions/ADR-0100-art-direction-painterly-chinese-grimdark.md`（决策段）· `art/visuals/art-direction.md`（「基调」段）。

---

**连带解除：** `systems/common-properties.md` 的 `Artwork` 一节不再挂任何指向待答清单的前置依赖，derive 顺序第 1 步的「落笔前的必须裁决」就此清空。**新增待答项 0 条。**
