# 内容共有字段 `Artwork`、敌人台词 `Lines`，与 `AiWeightVector` 的补齐

- id: 2026-08-28-content-artwork-enemy-lines-and-ai-weight-vector
- date: 2026-08-28
- topic: systems/common-properties.md · systems/enemies/_index.md · systems/enemies/common-properties.md · systems/services/combat-service.md · systems/character-profile/deck/common-properties.md · systems/player-profile/codex/common-properties.md · systems/viewmodel.md · art/visuals/_index.md
- status: distilled
- distilled-to: systems/common-properties.md, systems/enemies/_index.md, systems/enemies/common-properties.md, systems/services/combat-service.md, systems/character-profile/deck/common-properties.md, systems/player-profile/codex/common-properties.md, systems/viewmodel.md, art/visuals/_index.md, backend-design-documents/contracts/content-manifest.md

## Intent（distilled）

三件事，一次落笔：**补齐一个只被使用从未被定义的类型**、**给视觉资产引用一个顶层共有字段**、**给敌人台词一个可写的形态**。

### 一、`AiWeightVector` 的定义与有效权重的合并语义

`AiWeightVector` 出现在 `ChooseAction` 的形参上（`in AiWeightVector fallback`，注释「已展开为定长向量」），而平衡资源一侧写的是稀疏的 `AiFallbackWeights : AiWeight[]`——**两侧是不同形状，中间那一次「展开」既无落点也无失败语义**。补齐为：

- `readonly struct AiWeightVector`，内部 `float[]`（加载期一次分配、此后只读），索引 = `(int)AiTerm`，长度恒 == `AiTerm` 成员数；
- 由 ContentRegistry 在 `LoadAll()` 内从 `CombatRulesData.AiFallbackWeights` **一次性展开、落派生索引**，不写回条目（`CombatRulesData` 是共享只读单例）；
- **有效权重的合并语义只写一处**（`ChooseAction` 契约旁）：`w_k = profile 列了 term_k ? 该条 Value : fallback[term_k]`。敌人侧不复述——两处写出完整算式即第二权威；
- 纯运行时展开产物：不落 `.tres`、不落存档、不进上行负载、不 bump schema。

`AiFallbackWeights` 缺项 → `PushError` + 抛 那条既有校验正是这次展开的前置条件（缺项即向量带一个静默的 `0f`），两者并排书写使「为什么必须全覆盖」自明。

### 二、视觉资产引用 = 顶层内容共有字段 `Artwork : Texture2D`

按最小公共祖先判据，视觉资产引用的挂载面横跨多棵子树 ⇒ 定义落顶层 `systems/common-properties.md`「## 内容共有字段」，各落点只写投影段。

- `[Export] public Texture2D Artwork { get; set; }`，**可空**，默认 `null`；
- **挂载面七类**：`CardData` · `EnemyData` · `PowerData` · `ItemData` · `CharacterData` · `LocationData` · `AdventureEventData`；
- **不挂载**任何运行时 / 存档态类型；**功法不挂**（无独立视觉资产）；
- **不适用多语言**（插画内不得烧入可翻译文字 ⇒ 视觉资产与 locale 无关，故是裸 `Texture2D` 而非某种 `LocalizedTexture`）；
- **不落存档、不进上行负载、不 bump schema、后端零配合**；
- **取直接资源引用**，不取路径字符串、不取按 `Id` 的约定路径推导：路径形态同时撞「不用路径作内容的键」与「不散落 `ResourceLoader.Load`」两条纪律；`.tres` 里落为 `ExtResource`，悬空由引擎在加载期报出，本库不另写悬空校验；
- **缺失 = 合法常态**，呈现层回落占位资产。**告警形态取 `LoadAll()` 收口的一行汇总**（`[Content-LoadAll] Artwork 缺失 N 条（按类型分布：…）`），**逐条目不告警**——第一阶段近乎全部条目为 `null`，逐条目告警会训练出「忽略整个告警通道」的行为；
- **占位资产一处**：由 ViewModel 层统一提供 `res://art/_placeholder.png`（文件归 `game-feature-branch/`，本库只登记这条约定）；
- **overlay 语义只写可机械成立的部分**：overlay 覆盖一条 `.tres` 时 `Artwork` 随之被覆盖，指向必须落在随包基线内已存在的资产。「二进制资产能否经 overlay / blob 通道下发」在两库均未被表述过，作为待答项登记，不在本次拍板。

### 三、敌人台词 `Lines : EnemyLine[]`

台词是**文本内容、不是音频资产**（音频类目里没有人声轨，且台词与图鉴词条并列为写作口径的对象），故走 `LocalizedText`。

- `[Export] public EnemyLine[] Lines { get; set; } = [];`——稀疏覆写数组，照抄 `AiWeight` 的形状；
- `EnemyLine : Resource`，两个具名 `[Export]`：`LineSlot Slot` + `LocalizedText Text`；
- **只落 `enemies/`，不上移**——挂载面只有敌人一处，「只有一个落点的字段不进任何 `common-properties.md`」；
- 三条校验照抄既有分档：空数组合法 / 同 `Slot` 重复 → `PushError` / `Text == null` 或默认语言空串 → `PushError` + 抛；
- **`LineSlot` 的成员清单不列举**（写 `⟨待定：随战斗 UX 专场⟩`）——台词的呈现落点在本库尚无任何表述，写下的会是一组无消费点的枚举值。**连带后果如实写出**：枚举无成员 ⇒ 在专场答定成员之前 `Lines` 对任何条目都只能是空数组。

### 四、敌人条目不开音效引用字段

音频六类目中没有任何一条按敌人条目逐条产出；敌人级独有的只剩「入场吼叫」一类，其存在性在全库无一处表述；且多数玩家静音游玩，音频必须是增益而非承载信息的唯一通道 ⇒ 敌人级音效即便日后有也只属演出层。**留一个恒无对象的伸缩位只会让每个消费点都要处理一个永不发生的分支**——该待决项因此改写为「已判定不为敌人条目开字段」+ 理由 + 回链，而非删除。日后确有需求是纯加法。

## Clarifications

- **「二进制资产没有任何下发通道（无 blob、无内容寻址）」这条断言在客户端库无据，且与后端 `contracts/content-manifest.md` 的 blob 内容寻址段直接相抵** → 采纳「诚实最小面」：删掉该断言、不写进任何活文档；`Artwork` 的 overlay 行只写可机械成立的部分；新增一条待答项「二进制资产是否可经 overlay / blob 通道下发」，并在后端库留一条对侧承接项。`Texture2D` 的字段形态不受影响——另三条理由各自自足（不用路径作键 · 不散落 `ResourceLoader.Load` · 视觉资产与 locale 无关）。`content-service.md` 不改。
- **`Artwork` 的挂载面是否含功法与角色** → 功法**不挂**（资产类目表无功法行 + TechniqueCodex 词条清单不含立绘，两条独立既有表述压过图鉴词条构成表一处的笼统措辞），角色**挂**（既有资产类目「角色形象」+ 内容类 `CharacterData` 两个条件齐备，不挂即新造一处「资产类目有、内容类无字段」的失真）⇒ **七类**。连带把图鉴词条构成表里「立绘」一项限定为 `PowerData` / `ItemData` 两类，消掉该文件内部两处自相矛盾的表述。
- **`Artwork == null` 的告警形态**（自动采纳的标准默认）→ `LoadAll()` 收口汇总一行，逐条目不告警。依据：美术挂点先占位、末段替换的路线级安排使第一阶段近乎全部条目为 `null`；纪律选级第 3 级的形态本是「启动期审计」，不是逐条目刷屏。
- **本次落笔范围：只开 `EnemyData` 一格，还是一次升为顶层共有字段** → 一次升为顶层共有字段（最小公共祖先判据是可机械判定的规则；且 `content/` 现零条目，纯加法窗口在写下第一批 `.tres` 时关闭）。
- **是否现在落 `Lines`** → 现在落形态，`LineSlot` 成员写 `⟨待定：随战斗 UX 专场⟩`，不臆造任何槽位。
- **占位回落的承接层** → `systems/viewmodel.md` 加一句职责（该文档此前未定义任何资产加载 / 占位回落职责），与「回落逻辑只写一处」同款。

## Open questions

- **二进制资产是否可经 overlay / blob 通道下发**（决定换图 / 加图是否必须发版）。两库均未表述过，本次不拍板。
- **`LineSlot` 的成员清单** ← 战斗 UX 专场。在它答定之前 `Lines` 对任何条目都只能是空数组。
- **`Artwork` 的基数（单格 vs 按境界的数组）** ← 「境界晋升是否改变角色 / 敌人外观」。本次按单格给出形态；若该项答为「随境界改变」，本次的字段形态须重做。
- **资产的目录划分与 asset 清单完备性校验**。本次使它不再阻塞字段落地（资产寻址不再依赖命名约定），但仍需答定。

## Notes / triage

- 敌人条目的「道念产出能力的缩放参数未定义」不在本次范围，原样保留。
- `content/enemy-ai/` 的开张动作归 `/scaffold-content-type`，不在本次范围。
