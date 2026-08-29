# ADR-0120 — 插画引用升为顶层共有字段 `Artwork : Texture2D`；敌人台词落 `Lines`，不开音效字段

- **状态：** Accepted
- **日期：** 2026-08-28
- **来源：** handoffs/2026-08-28-content-artwork-enemy-lines-and-ai-weight-vector.md

## 背景

美术方向（`ADR-0100`）与三段生产流水线（`ADR-0040`）都已定，但内容条目上**没有任何一格指向视觉资产**——`content/` 的条目写完也接不上产出的插画。敌人条目同样缺台词与音效两格，三者一并悬着。

## 决策

**视觉资产引用 = 顶层内容共有字段 `Artwork : Texture2D`**，按最小公共祖先判据落 `systems/common-properties.md`，各落点只写投影段：

- **可空，默认 `null`；挂载面七类**（`CardData` · `EnemyData` · `PowerData` · `ItemData` · `CharacterData` · `LocationData` · `AdventureEventData`），**功法不挂**，不挂载任何运行时 / 存档态类型；
- **取直接资源引用**，不取路径字符串、不取按 `Id` 的约定路径推导；
- **不适用多语言**（裸 `Texture2D`，非某种 `LocalizedTexture`）；
- **缺失 = 合法常态**，告警取 `LoadAll()` 收口的**一行汇总**、逐条目不告警；
- **占位回落只写一处**：由 ViewModel 层统一提供 `res://art/_placeholder.png`；
- 不落存档、不进上行负载、不 bump schema、后端零配合。

**敌人台词 = `Lines : EnemyLine[]`**（稀疏覆写数组），`EnemyLine : Resource` 两个具名 `[Export]`：`LineSlot Slot` + `LocalizedText Text`；**只落 `enemies/`，不上移**。`LineSlot` 的成员清单**不列举**，在战斗 UX 专场答定之前 `Lines` 对任何条目只能是空数组。

**敌人条目不开音效引用字段。**

字段表、挂载面表与三条校验 → `systems/common-properties.md`、`systems/enemies/common-properties.md`；占位职责 → `systems/viewmodel.md`。

## 理由

**取直接资源引用**：路径形态同时撞「不用路径作内容的键」与「不散落 `ResourceLoader.Load`」两条纪律；`.tres` 里落为 `ExtResource`，悬空由引擎在加载期报出，本库不另写悬空校验。

**字段名取 `Artwork`（单数、类型中立）而非 `Portrait` / `Icon` / `Illustration`**：同一格在敌人身上是立绘、在卡牌上是卡面、在法则上是图标；按判据上移到顶层的字段必须用跨落点同义的名字。不拆成三个按用途分立的字段——同一敌人在图鉴与战斗屏复用同一张资产，分立会让每个内容类都要回答「我该填哪几格」，且三格中至少两格恒空。

**不适用多语言**：插画内不得烧入承载可翻译语义的文字（`ADR-0084`）⇒ 视觉资产与 locale 无关。

**告警取汇总一行**：美术挂点先占位、末段替换的路线安排使第一阶段近乎全部条目为 `null`，逐条目告警会训练出「忽略整个告警通道」的行为。

**台词走 `LocalizedText` 而非音频资产**：音频类目里没有人声轨，且台词与图鉴词条并列为写作口径的对象——它是文本内容。

**`LineSlot` 不臆造成员**：台词的呈现落点在本库尚无任何表述，写下的会是一组无消费点的枚举值。**连带后果如实写出**，而不是靠占位成员掩盖。

**不开音效字段**：音频六类目中没有一条按敌人条目逐条产出；敌人级独有的只剩「入场吼叫」一类，其存在性全库无一处表述；且多数玩家静音游玩，音频必须是增益而非承载信息的唯一通道。**留一个恒无对象的伸缩位只会让每个消费点都要处理一个永不发生的分支。**

## 备选方案

- **只开 `EnemyData` 一格，不升顶层** — 否决：最小公共祖先判据可机械判定，且 `content/` 现零条目，纯加法窗口在写下第一批 `.tres` 时关闭。
- **路径字符串 / 按 `Id` 约定路径推导** — 否决：撞两条既有纪律。
- **按用途拆 `Portrait` / `Icon` / `Illustration` 三格** — 否决：每个内容类都要回答「我该填哪几格」，且至少两格恒空。
- **`Artwork` 逐条目缺失即告警** — 否决：第一阶段近乎全为 `null`，会废掉整个告警通道。
- **台词做成音频资产引用** — 否决：它是文本内容，音频类目无人声轨。
- **现在就列举 `LineSlot` 成员** — 否决：无消费点的枚举值即臆造。
- **为敌人开音效引用字段** — 否决：见理由；日后确有需求是纯加法。

## 后果

- `systems/common-properties.md` 是 `Artwork` 的权威，七个落点只写投影段；`systems/enemies/common-properties.md` 是 `Lines` 与音效判定的权威。
- `systems/viewmodel.md` 因此背上一条此前不存在的职责：资产加载的占位回落。
- 图鉴词条构成表里「立绘」一项限定为 `PowerData` / `ItemData` 两类，消掉该文件内部两处自相矛盾的表述。
- overlay 语义只写可机械成立的部分：覆盖一条 `.tres` 时 `Artwork` 随之被覆盖，指向必须落在随包基线内已存在的资产。**「二进制资产是否可经 overlay / blob 通道下发」在两库均无表述，已登记为待答项**，后端库留对侧承接项。
- 生成出的二进制资产归 `game-feature-branch/`，本库只登记约定 → `ADR-0040`。
