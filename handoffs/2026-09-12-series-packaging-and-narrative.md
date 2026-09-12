# 角色系列的包装与叙事承载（方向专场十轴定案）

- id: 2026-09-12-series-packaging-and-narrative
- date: 2026-09-12
- topic: systems/monetization.md · systems/character-profile/_index.md · systems/services/plot-manager.md · vision/scope.md · vision/pillars.md · content/_index.md · content/character/_index.md · narrative/（新建分区）
- status: distilled
- distilled-to: `narrative/_index.md`、`systems/monetization.md`、`systems/character-profile/_index.md`、`systems/services/plot-manager.md`、`vision/scope.md`、`vision/pillars.md`、`content/_index.md`、`content/character/_index.md`、`systems/player-profile/_index.md`、`README.md`、`answer-logs/log-monetization-packaging-and-narrative.md`

## Intent（distilled）

**一句话：** 角色系列是**世界观的切片，不是难度的梯队**；世界观本身走碎片化 lore，只活在轮回里、从不点破，而**剧情不是付费面**。

### 十轴裁决

1. **系列凭什么成为一个系列 —— 分组没有原则。** 系列有一个与世界观兼容的**有意境的名称**（地域、宗门一类）与**一段简要概述**，细节不写在这里而散进轮回内的叙事。**系列对成员角色没有任何规则上的强制要求**：不存在系列加成 / 系列共鸣，也不存在系列层面的规则字段。五行对称仍是内容编排纪律，约束的是每批怎么排，不是系列这个实体持有什么。商店详情页讲的是一段世界观概述，不是一组机制卖点。
2. **首批五角的关系 —— 互不相干的五个独行者，共享同一套世界观架构。** 他们的故事线可能交叉，玩家深度游玩后可拼凑出各自所经历事件之间的交集。「第一个免费系列」承载的不是一个组织，而是一段共同的世界观背景。交叉因此是**内容层的编排义务**：写第二个角色的事件时要能查到第一个角色的事件写了什么。
3. **付费角色是否附带专属剧情 —— 免费与付费一视同仁，剧情不是付费面。** 每个角色（无论轨道）都可能带一条专属线；铺不铺取决于内容排期，而非付费与否。商店的系列详情页**不得**把「专属剧情」列为付费权益。机制侧零成本：`PlotArcData.CharacterIds` 填值即角色专属、零新增 schema，且剧本条目可经 overlay 热更不发版。
4. **推出顺序 —— 先推付费系列，双灵根免费批在后。** 这是全库第一次给后续角色系列定序。首发后的第一次大更新是付费内容，观感风险由「严格横向不卖强度」与「未拥有角色完全不出现在角色选择屏」两条既有纪律承接。
5. **第一个付费系列由什么构成 —— 单灵根五角进阶批。** 5 个角色、五行对称、仍是单灵根，但**复杂度高于首批**；定价锚 = 付 4 个单解之价。它落在「首批压平复杂度、由后续系列抬升」那一格，且不触碰双灵根机制。**双灵根批仍走免费轨道，只是排在付费进阶批之后。** 「复杂度抬升」不得表达为强度抬升——进阶批卖的是更繁的运营与更深的组合空间，不是更高的胜率。
6. **碎片 lore 挂在哪里 —— 只撒在轮回内，不留存。** lore 活在事件描述与剧本节点正文里，读过即过：不进图鉴、不做任何可回看的档案面。图鉴族维持现状不扩张。玩家侧的拼凑成本因此很高，这是被选定的取向。**开发侧的留档是硬要求**（见轴 9）。与支柱 9 的边界须写明：支柱 9 管的是**关于敌人 / 未来 / 世界的可用情报**，lore 碎片不可换取、不影响决策、不进图鉴，不是那种意义上的信息。
7. **lore 的调子 —— 冷的残缺文献体。** 碑文、卷宗、手札残页、旁人记述；叙事性强但情绪冷，不解释、不总结、不动用第一人称。「全作唯一一处第一人称是角色终结的那三句台词」这条纪律因此不破。素语纪律的射程同时得到澄清：**框架 / 系统文案仍是纯数据陈述**，lore 与剧本正文是另一档——允许叙事性与文学质地，但情绪必须是冷的。
8. **故事线交叉怎么让玩家发现 —— 纯隐式，游戏从不点破。** A 的故事里出现的无名者正是 B，但不给提示、不给成就、不做任何「你发现了」的确认。成就系统不为 lore 串联开任何条目。承认并接受：绝大多数玩家永远不会发现，串联主要发生在玩家社区而非游戏内。
9. **lore 留档放在哪里 —— 新建顶层 `narrative/` 分区**，与 `vision/` · `systems/` · `content/` · `art/` · `ux/` 平级，放世界观设定、时间线、人物关系与碎片台账。它既不是机制类定义也不是条目实例，而是**写条目时要查的上游事实源**；且叙事会持续变长，给它自己的分区不会挤压其他区。它是**内部事实源，不是玩家可见面**。
10. **系列的名字与概述由什么承载 —— 建 `CharacterSeriesData` 内容类型，只放名与概述。** `Id` + 名称 + 一段简要概述 + 可选一张商店插图，**不带任何规则字段**。`SeriesId` 现有的两段式前缀 `character_series.<slug>` 本就是为引用它而留的；`character-profile/_index.md` 原先「现在不建该内容类型」的悬置理由（主题包装未定）已随轴 1 解除。

### 被否决的站位（理由承重，留作防复提）

- **按复杂度梯队命名系列** —— 把难度写进商品名，容易被读成「贵的那批更强」，正是严格横向要避的观感。
- **按叙事母题分组** —— 母题维度没有天然供给上限，出到第六批会开始重复。
- **同门五弟子** —— 组织归属感与「独自求生」的压力线有张力，且一旦给了宗门，玩家会期待它在事件与剧本里持续出现。
- **专属剧情作为付费卖点** —— 一道内容付费墙，需要重新表态「这把尺子量的是强度还是整个体验」。
- **双灵根十角改做付费首批** —— 明确推翻既定的免费轨道，且让未经实测的双机制区分先面对付费玩家。
- **lore 进图鉴 / 给成就** —— 把「自己拼凑」变成「游戏告诉你拼对了」，与残卷「不做任何形式的进度可感化」同形地稀释了隐含性。
- **lore 走完整文学性叙述** —— 稀释「唯一一句人声」的凿击感。**lore 走素语极简陈述** —— 残缺句子里那点语调与暗示正是可深挖的东西，全抽掉就没有了。
- **系列名只当 `STORE_` 翻译键** —— 系列名只活在商店里，别处想提就没有可引用的条目。

## Clarifications（interview 产物）

本稿的十轴裁决来自 `/design-direction-interview` 09-12 专场，用户在那场 interview 中逐轴亲口拍板，提炼时视同用户当面裁决，未重新发问。校验未发现与既有 ADR / 支柱 / 承重纪律相抵的项（张力区为空），故本次**未触发二次 interview**、未改写任何 ADR。

**自行推演（标准默认，按 🔵 直接采纳）：**

- `CharacterSeriesData` 的字段面 = `Id`（`character_series.<snake_case_slug>`）+ `LocalizedText` 名称 + `LocalizedText` 概述 + 可空 `Artwork`，走 `ContentRegistry`、带 `ContentEnabled`，与其余内容类型同构；无规则字段（轴 1 的直接推论）。
- 加载期校验补两行：`PlotArcData.CharacterIds` 悬空（既有校验表已为 `PlotTriggerId` / `EventWhitelist` 等各设悬空校验，唯独这一格无处置）、`CharacterData.SeriesId` 悬空（建类型后才有对象可校验）。系列层既有两条（同 `SeriesId` 条目数 ∈ {5, 10}、`Track` 一致）不变。
- 文档漂移订正（笔误级）：`character-profile/_index.md` 与 `player-profile/_index.md` 中写作 `PlotNodeData.CharacterIds` 的三处订正为 **`PlotArcData.CharacterIds`**——schema 权威把它放在 arc 上，且 gating 落在 arc 才与「arc 是激活单元、node 是步骤」自洽。
- 新建 `narrative/` 连带两处登记：本库 `README.md` 的文件夹图例加一行、`.claude/rules/design-library-routing.md` 的两库结构差异表加一行（该表明写两库结构变更时须同改）。

## Open questions

- **各系列的具体名字与主题**（含第一个付费系列取哪个世界观实体、首批五角共享的是哪一场世界事件）——属内容阶段，需先有 `narrative/` 的世界观底稿。
- **`narrative/` 分区的内部结构与文档清单**——本次只定了「建这个分区、放什么类东西」，具体切成几份文档留给建区时。
- **双灵根免费批的具体推出时点**——只定了排在第一个付费系列之后，未定隔几个版本。
- **进阶批「复杂度更高」的具体表达**（更繁的运营？更多的条件判断？更长的连锁？）——属内容与数值阶段。
- **角色专属 SideStory 的激活口**（现有两条 arc 激活通路是 `PlotTriggerId` 与篇章边界，「角色专属、不由隐藏属性触发」的 SideStory 没有明写的激活口）与 **`CharacterIds` 的 gating 语义**（何时比对、不匹配时是不激活还是惰性）——工程推演题，归一次 `/provide-solution-draft`。
- **付费系列「在售窗口」落哪一格**——本次答定了「系列内容类型要建」这一半，剩下的是它落 `CharacterData` 还是 `CharacterSeriesData`，留给开张那一轮。

## Notes / triage

来源草稿：`inbox/archive/design-draft-monetization-packaging-and-narrative.md`（`/design-direction-interview` 09-12 专场）。移出待答两条，记入 `answer-logs/log-monetization-packaging-and-narrative.md`。
