# Answer log monetization-packaging-and-narrative

- 日期：2026-09-12
- 来源：`inbox/archive/design-draft-monetization-packaging-and-narrative.md`（`/design-direction-interview` 09-12 专场，十轴定案）→ `handoffs/2026-09-12-series-packaging-and-narrative.md`
- 移出条数：2 全条（均出自 `open-questions/06-meta-progression.md`）

## 逐条

**双灵根批与付费系列的推出时点与主题包装（09-10 新增）** → 拆成三半，两半答定、一半收窄留在清单：

- **次序答定：** 第一个付费系列 = **单灵根五角进阶批**（5 个、五行对称、仍是单灵根、复杂度高于首批，定价锚 = 付 4 个单解之价）；**双灵根免费批排在它之后**，免费轨道不变。归档去向：`systems/monetization.md`「付费解锁角色系列」· `systems/character-profile/_index.md`「角色模板池的形态」· `vision/scope.md`（全库第一次给后续角色系列定序）。
- **包装原则答定：** 系列是**世界观的切片，不是难度的梯队**——分组没有原则，系列有一个与世界观兼容的有意境名称与一段简要概述，**对成员角色零规则强制**（不存在系列加成 / 系列共鸣 / 系列层规则字段）；名与概述落新内容类型 **`CharacterSeriesData`**（`Id` + 名称 + 概述 + 可空 `Artwork`，无规则字段）。归档去向：`systems/monetization.md` · `systems/character-profile/_index.md` · `content/_index.md` 类型登记表 · `narrative/_index.md`。
- **仍待答（收窄后留在 `06-meta-progression.md`）：** 各系列的**具体名字与主题**取哪个世界观实体——需先有 `narrative/` 的世界观底稿；**双灵根批隔几个版本推出**；**进阶批「复杂度更高」的具体表达**。

**付费角色与专属剧情的关系（09-10 新增）** → **剧情不是付费面。** 免费与付费角色在叙事待遇上**一视同仁**：每个角色（无论轨道）都可能带一条专属剧情线，铺不铺取决于内容排期而非付费与否；商店的系列详情页**不得**把「专属剧情」列为付费权益。机制侧零成本（`PlotArcData.CharacterIds` 填值即角色专属、零新增 schema，剧本条目可 overlay 热更不发版）。「专属剧情钩子属后续内容、非首批义务」原样保留，只是对两条轨道同等适用。归档去向：`systems/monetization.md` · `systems/character-profile/_index.md` · `systems/services/plot-manager.md`。

## 同批另记（非移出项）

- **方向裁决 10 项**（十轴定案的完整叙述见来源 handoff）：系列分组原则 · 首批五角关系 · 专属剧情轨道无关 · 推出次序 · 第一个付费系列构成 · 碎片 lore 只撒轮回内不留存 · lore 调子为冷的残缺文献体 · 故事线交叉纯隐式 · 新建顶层 `narrative/` 分区 · 建 `CharacterSeriesData` 内容类型。
- **推翻 0 项。** 十轴与既有 ADR / 支柱零相抵：次序是**首次定序**而非推翻；`ADR-0255`「双灵根首批走免费轨道」保持完好；`character-profile/_index.md` 原先「现在不建 `CharacterSeriesData`」是**悬置条件达成**（悬置理由 = 主题包装未定）而非否决；素语纪律的射程被澄清但对框架文案的约束未改。
- **标准默认（自动采纳）4 项：** `CharacterSeriesData` 字段面 · 两条加载期悬空校验（`PlotArcData.CharacterIds` · `CharacterData.SeriesId`）· `PlotNodeData.CharacterIds` 三处笔误订正为 `PlotArcData.CharacterIds` · 新分区的两处结构登记（本库 `README.md` 文件夹图例 · `.claude/rules/design-library-routing.md` 两库结构差异表）。
- **新增待答 3 条：** `04-hidden-attributes-plot.md` 两条（角色专属 SideStory 的激活口 · `CharacterIds` 的 gating 语义，归一次 `/provide-solution-draft`）· `deferred-content.md` 一条（`narrative/` 的内部结构与世界观底稿）。另有 `06-meta-progression.md`「在售窗口的内容层承载形态」**半条收窄**——「类型建不建」已答定，剩两个载体择一。
