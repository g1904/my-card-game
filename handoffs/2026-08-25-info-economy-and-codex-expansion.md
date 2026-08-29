# 信息经济与图鉴 —— 信息不可购买 · 战斗中锁图鉴 · 第七本功法图鉴 · 战斗前确认页

- id: 2026-08-25-info-economy-and-codex-expansion
- date: 2026-08-25
- topic: vision/pillars · systems/player-profile/codex · systems/player-profile · systems/services/profile-service · systems/services/sync-service · ux/combat-ux · ux/screen-flow · terminology · systems/balance · systems/character-profile/deck
- status: distilled
- distilled-to: `vision/pillars.md`、`terminology.md`、`systems/player-profile/codex/_index.md`、`systems/player-profile/codex/common-properties.md`、`systems/player-profile/codex/technique-codex.md`、`systems/player-profile/codex/enemy-codex.md`、`systems/player-profile/_index.md`、`systems/services/profile-service.md`、`systems/services/sync-service.md`、`systems/services/life-cycle-service.md`、`ux/combat-ux.md`、`ux/screen-flow.md`、`systems/balance.md`、`systems/player-profile/player-power/_index.md`、`systems/character-profile/deck/_index.md`、`systems/adventure-event/combat/_index.md`、`systems/_index.md`、`content/_TEMPLATE-entry.md`、`art/visuals/_index.md`、`decisions/ADR-0027-*`（计数中性化）；对侧：`backend-design-documents/contracts/profile-sync.md`

## 一行摘要

**关于世界的知识只能靠遭遇积累，不能靠资源购买** —— 这条信息哲学升格为设计支柱，并由三件事兑现：战斗中全部图鉴锁死、图鉴族扩为七本（新增功法图鉴，敌我共用一套功法条目）、战斗前设一个确认页把「已解锁的敌人图鉴」当作解锁的回报时刻交还给玩家。

## Intent（distilled）

### 1. 正面原则：信息只能靠遭遇获得，不能靠资源获得

「不留花代价买信息的通道」由一条否决理由升格为**正面设计原则**，用来裁决未来一整类提案 —— 占卜类事件、侦察类法宝、付费情报一律不做。它与「敌人行动不作事前预告」「地域图对玩家不可见、靠 `LocationCodex` 逐格显影」同属一套信息哲学：**信息本身是元进程奖励**。

**射程 = 外部情报**（关于敌人、未来、世界的知识）。**不含**关于玩家自己牌堆 / 手牌的便利类效果 —— 查看自己的牌堆顶不产生任何关于世界的知识。故「每场一次重排手牌 / 查看牌堆顶（道念净贡献为 0）」这一类照常允许，只是它的花费纪律不再挂在「买信息」这个框架下，而按「自身牌序 / 手牌的便利类效果」独立成文（mana 为主 + 古宝 `Charges`，明确排除弃牌）。

原则落 `vision/pillars.md`，并记为 **ADR 候选**（本次不建 ADR）。

### 2. 图鉴在战斗中一律不可查看

全部图鉴（地域 / 敌人 / 功法 / 古宝 / 法宝 / 神通 / 法则）在战斗中锁死，只在非战斗界面可查。战前准备的仪式感与首遇的信息差风险由此成立。

原先允许战斗内查阅的论证是「词条不含动态情报 ⇒ 战斗内可读不改变信息分层」—— 那说明的是**可以**开，不是**必须**开；本次给出的是更强的正面取向，故取后者。连带：动态页眉「本次遭遇：筑基后期」迁往战斗前确认页；「点按敌人立绘 = 开图鉴」的语义条整条作废。

### 3. 新增第七本图鉴 `TechniqueCodex`（功法图鉴）

图鉴族由六本扩为七本。条目按 `CultivationTechnique` 的 `Id` 索引，形态与既有六本一致：账号级、跨轮回持久、静态文案、存档只记解锁状态。标识符 `TechniqueCodex` / `CodexKind.Technique`（枚举末位）/ 存档字段 `techniqueCodex`；成员名随存档冻结，须在第一批存档写下前定稿。

**词条深度：不列卡牌清单。** 词条 = 功法名 / 描述 / `Rarity` / 路数概括 + 可选 `CodexFlavor`，即四本能力 · 道具类图鉴的既有深度口径。卡牌列表只在玩家**自己持有**该功法时由卡组 / 构筑界面提供。

理由承重，必须留在正文：敌人套牌是「功法 + 层数」，而功法条目本身含「每层一份卡牌 `Id` 列表」。词条若列出卡表，玩家可从敌人词条②→ 功法图鉴**反查出敌人完整卡组**，实质绕过「慷慨度维持 3 张关键卡、不给样本卡组完整列表」这条裁决 —— 完整卡组列表把词条从事前知识推向事中情报，那是读牌堆。本裁定同时保住「敌我共用一套功法条目、知识可验证可迁移」与「图鉴不侵蚀越级黑箱」。

**存档面增量：** `PlayerProfile` 增字段 `techniqueCodex`；`CodexKind` 增一值；`PlayerProfileDiff` 增一个顶层 Codex 键；bump `schemaVersion`（当前无线上存档 ⇒ 空迁移）。不进透明路径白名单，后端零配合。

### 4. 连锁解锁：解锁敌人 = 解锁其全部功法词条

`EnemyCodex` 收录一个敌人时，同时把**该敌人的功法引用列表**所含全部功法收录进 `TechniqueCodex`。玩家自己习得功法亦解锁对应词条（触发口径沿用「进入持有列表」，搭在 `DeckElements` 的 `LearnTechnique` 那次提交上）。

**机制上零新增：** `CodexElements` 的语义是按 `(Kind, Id)` 的幂等收录、零 `Op`、重复收录是幂等空操作 ⇒ 一次敌人收录展开为 1 条 `(Enemy, enemyId)` + N 条 `(Technique, techniqueId)` 完全合法。展开的组装方是 **`CodexManager`**（触发采集与去重归它），写入仍组装 `CodexElements` 经 `ProfileManager` 单点提交，不由 `ProfileManager` 自动派生。零新增提交点成立。

`Pool == Enemy` 的敌方专用功法**照常收录**，玩家永远学不到不影响收录；「敌方专属」是呈现层由 `Pool` 字段现算的一格标注，不新增任何存档字段（与 `LocationCodex` 三态派生同一先例）。完成度分母含它 —— 打赢敌人即可解锁，不存在无法达成的分母。

### 5. 入账时点与判据

判据是**遭遇**而非胜利 —— 战败 / 中途终局同样入账。失败路径不需要额外分支：`eventEnd` 的提交在角色终结判定之前已落地。

**「只有 `eventEnd` 入账」这一条只约束 `EnemyCodex` 与 `TechniqueCodex`**，其余五本的触发表原样不动。理由：触发表的承重结论是「零新增提交点，每一行都搭在一次已经存在的提交上」，而出生地与自带绑定神通落在「轮回创建」那一次提交上（那不是任何事件的 `eventEnd`），Exchange 的购买则是逐笔即时提交、明令不攒到 `eventEnd`。全族改 `eventEnd` 需为三处各开例外，把一张可机械核对的触发表变成三条例外规则。

收窄后「零新增提交点」不破，且它正是确认页能成立的前提 —— 本场遭遇不当场解锁，才有「上次输给它，这次进场前能看到它的底牌」。

### 6. 战斗前确认页展示已解锁的敌人图鉴摘要

进入 Combat 事件、开打之前设一个确认页：若该敌人已在 `EnemyCodex` 解锁，则显示其图鉴摘要（词条全文五项 + 功法词条入口）；未解锁则摘要区不出现。这不违反「战斗中不可查」（尚未开打），并给图鉴解锁一个明确的回报时刻。**首遇的信息差即首遇的风险定价。**

「未解锁则不显示任何情报」**不覆盖敌人等级标注** —— 等级是实例信息，不是图鉴词条内容。承接自第 2 条的动态页眉与本页自带的等级标注合并为一行，不同屏出现两次。

**确认动作：带一个「进入战斗」按钮，且只新增这一次确认，不新增可退出通道。** 玩家在此页不能返回地图 —— 「成本已支付、规则层不可回退」这一半仍然成立。Explore 揭示转场层本身仍不设确认按钮（它对 Combat / Travel / Exchange 三种真身通用），故 Explore→Combat 全程只确认一次。

摘要内容取词条全文而非再切一层摘要：词条本就设计为 150–280 字一屏读完，再切一层是多一套写作规格。

## Clarifications（interview 产物）

- **「进入战斗」按钮是否构成新的事件内决策点** → **不构成**。既有判据是「这一刻有没有新状态产生」，确认页与已被逐字裁决为不列的「Exchange 面板打开 / Research 面板打开」同形，状态已由「择一进入」那次 `TryApply` 覆盖。决策点清单、D0–D6 冻结词表、`sync-service` 的「D0 就是『进入战斗前』这个 flush 点」等式**一字不动**。这推翻了原稿第 6 条自述的两条「连带」。
- **确认按钮落在哪一层** → 原稿点名要推翻的「确认｜无（不设『确定进入』按钮）」那一行实际属于 Explore **揭示转场层**表格、对三种真身通用；表格行保留「无」，只改写其下那句绝对化的承重理由使其容纳确认页这一例外。照字面改会让 Explore→Combat 出现两次确认并波及 Travel / Exchange，与原稿自己的边界「只新增一次确认操作」矛盾。
- **`Pool == Enemy` 功法在功法图鉴中如何呈现** → 照常收录 + 呈现层现算「敌方专属」标注，完成度分母含它、不加 `Pool` 过滤、不新增存档字段。这答定了敌人构筑一稿留下的同名 Open question。
- **连锁解锁的展开依据** → 按**该敌人的功法引用列表**展开。原稿写「按本次遭遇实例实际使用的功法展开，不按模板」，其理由（`OverridesDeck` 条目下会解锁错的东西）已随 `OverridesDeck` 字段删除而失效，且层数逐条固定 ⇒ 实例功法集恒等于模板引用列表，结论不变而措辞须改。

**标准默认（自动采纳，未出题）：**

- `eventEnd` 射程收窄到 `EnemyCodex` + `TechniqueCodex`；`CodexKind.Technique` 命名与末位枚举顺序；摘要取词条全文五项；原则落 `vision/pillars.md` + 记 ADR 候选；扩员是纯加法但仍 bump `schemaVersion`（空迁移）；完成度分母取 `AllIncludingDisabled()`。
- 图鉴族的**序数措辞**（「第六本」）一律去序数化而非改成「第七本」—— 序数会在下次扩员时再次失真；明写数量处照实改七。
- 「不在最高频操作上加模态」这条纪律收窄为「不加模态弹层 / 不加提示」即可容纳一个非模态的确认页，其余五处援引点无须改动。
- `CultivationTechniqueData` 字段清单补一个可选 `CodexFlavor` —— 本次唯一新增的内容字段。
- 后端侧 `schemaVersion` bump 触发的兼容矩阵登记是每次 bump 都存在的既有机械义务，由既有通则单点承接，不写进契约正文。

## Open questions

- 图鉴入口在主菜单 / 非战斗界面如何组织（「战斗内能否查阅」这一半已答定，组织方式仍待定）。
- 功法在内容层 `content/` 的 id 前缀未定 —— C# 短名 `Technique` 不等于已定的内容 id 前缀。
- 一门功法含几张牌、层数上限 `MaxTier`、每层替换幅度 —— 留待内容扩充后的统计校准（承自敌人构筑一稿）。

## Notes / triage

来源：`inbox/draft-0823c.md`（`status: decided`，经 2026-08-25 批量 interview 逐条裁决）。
前置依赖 `draft-0823b` 已提炼（`2026-08-25-enemy-deck-from-techniques-and-ai.md`），本稿承接其「敌人构筑面 = 功法引用」。
跨边界承接：`backend-design-documents/handoffs/2026-08-25-codex-key-count-neutralization.md`（后端侧只做契约措辞去计数化，不复述本稿的图鉴设计）。
