---
type: solution-draft
date: 2026-08-28
question: `EnemyData` 的定制 AI 策略字段形态（核验）＋ 立绘 / 台词 / 音效资产引用字段的形态
source: systems/enemies/common-properties.md「## 待决问题」→「敌人数据 schema 的其余字段：立绘 / 台词 / 音效引用……未定义」
targets: systems/common-properties.md · systems/enemies/_index.md · systems/enemies/common-properties.md · systems/services/combat-service.md · systems/player-profile/codex/common-properties.md · systems/character-profile/deck/common-properties.md · art/visuals/_index.md
status: distilled
reviewed: 2026-08-28 — 批量合并 interview。草稿两项取向均取选项 A（一次升为顶层共有字段 · 现在落 `Lines` 形态、`LineSlot` 成员待战斗 UX 专场）。另裁决三项：**Q5 删除「二进制资产无下发通道」断言**（库中无据且与后端 `contracts/content-manifest.md` 的 blob 内容寻址段相抵），改为一条待答项 + 后端对侧承接项；**Q6 `Artwork` 挂载面定为七类**（功法不挂、角色挂，草稿的六类漏了这两个对象）；`Artwork == null` 取 `LoadAll()` 收口汇总一行而非逐条目 `PushWarning`。
distilled-to: handoffs/2026-08-28-content-artwork-enemy-lines-and-ai-weight-vector.md
---

# 方案草稿 — `EnemyData` 的 AI 策略形态（核验）与资产引用字段

## 问题

派单把本稿的范围写作两个子问题。**读全上下文后，两者的实际状态截然不同，必须先分开陈述：**

- **子问题 ①（AI 策略的表达形态）已于 2026-08-26 答定并完成提炼，不需要新方案。**
  `handoffs/2026-08-26c-enemy-ai-strategy-shape.md` 的 `status` 为 `distilled`，其五项结论已逐条落在
  `systems/enemies/_index.md`（`EnemyAiProfileData` / `AiWeight` 类定义 · `AiTerm` 十项语义表 · 三条结构性上界）、
  `systems/enemies/common-properties.md`（六条加载期校验含 `null` 合法、悬空 `PushError` + 抛、空壳 `PushWarning`、
  重复 `Term` `PushError`、越界 `PushError` + 抛、未被引用 `PushWarning`）、
  `systems/services/combat-service.md:83–110`（`ChooseAction` 签名 · `AiTerm` / `EnemyActionKind` / `EnemyAction` 定义 · 候选集）、
  `systems/balance.md:270–294`（`AiFallbackWeights` 十项 · `AiWeightMin` 0.0 / `AiWeightMax` 2.0 · 跨字段不变式）。
  答定记录见 `answer-logs/log-enemy-ai-strategy-shape.md`；`open-questions/01-combat.md` 中已不存在该条目。
  **派单描述的「该格目前只有『允许为空 = 走通用兜底』，字段类型写不出」是过时前提。**
  本稿对 ① 只做一次核验，并提出**一处真实的形式化残留**（`AiWeightVector` 无定义，见「建议方案 · A」）。

- **子问题 ②（立绘 / 台词 / 音效引用）是真空缺，且比登记的范围更大。**
  全库对 `Texture2D` / `AudioStream` / `Sprite` / `res://art` / `IconPath` / `PortraitPath` / `AssetKey` 的检索是**零命中**——
  本库从未写出过任何资产引用字段的字段名、C# 类型、`[Export]` 与否、可空性或缺失处置。
  同一空缺至少还出现在另外两处，且其中一处已经在**引用一个不存在的东西**：
  - `systems/character-profile/deck/common-properties.md:246` —— `CardData` 完整字段清单的末项写作「**· 美术引用**」，无字段名、无类型；
  - `systems/player-profile/codex/common-properties.md:77` —— 图鉴词条构成表写「名称 · 描述 · 立绘 | …与**既有美术挂点** | **不新增**」，
    而那个「既有」在库里查无实据。
  卡住了什么：`content/enemy/` 的就绪度 🟠、`content/card/` 🟠，条目模板 `content/_TEMPLATE-entry.md:53` 的「美术 / 音频需求」一节
  只能写需求文字、填不出字段值；`/derive-requirements` 拿不到可验收的字段面。

## 约束（来自既有设计）

| # | 约束 | 来源 |
|---|---|---|
| C1 | 展示字段三层切分：**静态展示文本（显示名 / 描述 / 图标）留在 `XxxData : Resource` 上**；运行时 / 存档态只带 `Id` + 可变状态；组合展示由 ViewModel 组装 | `decisions/ADR-0010`、`systems/common-properties.md`「展示字段的归属」、`systems/viewmodel.md:26` |
| C2 | 共有属性**定义在其全部挂载面的最小公共祖先，恰好一份**；每个落点只写投影。上移判据 = 同一字段在 ≥2 个兄弟节点出现且语义同一 | `decisions/ADR-0057`、`systems/common-properties.md` 判据卡 |
| C3 | **绝不用场景路径、数组索引或显示名作为内容的键**；玩法代码经注册表泛型仓储查找，**不散落 `ResourceLoader.Load`** | `systems/common-properties.md:11 / 21`、`.claude/rules/data-resource-rules.md` |
| C4 | **没有云端内容通道**：内容只有 `res://content/` 基线 + `user://overlay/`；overlay 覆盖对象一律 `.tres`、**只改不增**；**二进制资产没有任何下发通道**（无 blob、无内容寻址；manifest 的 hash 只用于完整性校验，不是寻址键） | `systems/services/content-service.md:10–29 / 165–199 / 325`、`decisions/ADR-0007` |
| C5 | **二进制资产归 `game-feature-branch/`**，设计库只承载 vision / 参考登记 / guide | `decisions/ADR-0040`、`art/_index.md:13–15` |
| C6 | **敌人立绘一张，图鉴与战斗屏复用**（资产类目表原文：「同一敌人在图鉴与战斗屏复用」） | `art/visuals/_index.md:19` |
| C7 | **插画内不得烧入承载可翻译语义的文字**，适用全部资产类目含敌人立绘 ⇒ 视觉资产与 locale 无关 | `decisions/ADR-0084`、`art/visuals/art-direction.md:38` |
| C8 | **美术挂点先占位、末段替换**：几乎全部美术资源在设计达 ~90% 前一律 TBA，架构中始终保留可轻松替换的挂点 | `decisions/ADR-0006`、`vision/scope.md:39–42 / 57 / 62`、`ux/screen-flow.md:180` |
| C9 | 纪律选级四级阶梯；**「能上线且线上不可见」必须做到第 1 / 2 级**，「只在开发期显形且会累积」第 3 级足够 | `decisions/ADR-0013` |
| C10 | `art/soundtracks/` 六个音频类目**没有任何一条按敌人条目逐条产出**（主题曲 / 战斗 BGM / 事件 BGM / 篇章氛围 / UI 音效 / 反馈音效）；且「多数玩家静音游玩，音频必须是增益而非承载信息的唯一通道」 | `art/soundtracks/_index.md:17–32` |
| C11 | 纯加法窗口的排期判据：`LocalizedText` / `DrawPool<T>` 之所以要在第一份 `.tres` 写出之前落地，是因为「窗口在写下第一批 `.tres` 的那一刻关闭」；**`content/` 下当前零条目** | `systems/common-properties.md:210`、`systems/services/content-service.md:297`、`content/_index.md` 登记表（18 行「开张」全 ✗） |
| C12 | 图鉴族「战斗中不可查阅」已定；**立绘的点按语义完全归战斗自身（选目标）** | `systems/player-profile/codex/enemy-codex.md:71`、`answer-logs/log-0823c.md` |

## 建议方案

### A. 子问题 ① 的核验结论 + 一处形式化残留：`AiWeightVector` 无定义

`[既有推演]`

**核验结论：`AiProfile` 那一格已完整可 derive**，本稿不提任何改动。核对清单（逐条已有权威落点）：
字段面 ✓ · 引用形态（直接类型引用，不写 `AiProfileId : string`）✓ · 可空语义 ✓ · `Id` 形态 `enemy_ai.<snake_case_slug>` ✓ ·
六条加载期校验与严重度分档 ✓ · 取值域 `[0.0, 2.0]` 与兜底十项 ✓ · 三条结构性上界与其 `ADR-0013` 级别 ✓ ·
数值分层（兜底向量与取值域住 `CombatRulesData`、profile 逐条取值住 `content/enemy-ai/`）✓。

**残留一处：`AiWeightVector` 这个类型在全库只被使用、从未被定义。**
它出现在 `systems/services/combat-service.md:89` 的 `ChooseAction` 形参上（`in AiWeightVector fallback`，注释「已展开为定长向量」），
除此之外全库零命中（另一处命中在 `inbox/archive/` 的旧草稿内，非权威）。`systems/balance.md:274` 那一侧写的是
`AiFallbackWeights : AiWeight[]`——**两侧是不同形状**（稀疏 `AiWeight[]` vs 定长向量），中间那一次「展开」没有落点、没有失败语义。
derive 时这一格必然被问出来。建议补齐为：

```csharp
// 定长权重向量。索引 = (int)AiTerm；长度恒 == AiTerm 成员数。
// 由 ContentRegistry 在 LoadAll() 内一次性从 CombatRulesData.AiFallbackWeights 展开，落派生索引。
public readonly struct AiWeightVector
{
    private readonly float[] _values;                       // 加载期一次分配，此后只读
    public float this[AiTerm term] => _values[(int)term];
}

// ChooseAction 内的有效权重（不新增结构，只写明合并语义）：
//   w_k = profile?.Weights 中列了 term_k ? 该条的 Value : fallback[term_k]
```

- **展开落在 ContentRegistry 侧的派生索引、加载期算一次**——照抄 `EnemyData` 样本卡组「展开产物不写回条目、需要缓存就落派生索引」
  的既有做法（`systems/enemies/common-properties.md`），理由同源：`CombatRulesData` 是 ContentRegistry 里的**共享只读单例**，不得运行时写回。
- **`AiFallbackWeights` 缺项 → `PushError` + 抛**这条校验（`systems/balance.md:274` 已写）正是这次展开的前置条件——
  缺项即向量有洞，`_values` 会带一个静默的 `0f`。两者应并排书写，使「为什么必须全覆盖」自明。
- **合并语义只写在一处**（`ChooseAction` 的契约旁），不在 `systems/enemies/` 复述——那边已写「profile 只列要覆写的项，未列项取兜底默认值」，
  两处同时写出完整算式即制造第二权威。
- `AiWeightVector` 是**纯运行时展开产物**：不落 `.tres`、不落存档、不进上行负载，故不 bump 任何 schema。

**备注（台账事项，不是方案）：** `content/enemy-ai/` 就绪度已是 🟢（`content/_index.md:44`）而「开张」列仍为 ✗；
开张动作归 `/scaffold-content-type enemy-ai`，`handoffs/2026-08-26c` 的 Clarifications 已明写它不在那次运行范围内。本稿同样不做。

---

### B. 资产引用字段的归属：顶层内容共有字段，不是 `EnemyData` 私有的一格

`[既有推演]`

**判据是 C2（`ADR-0057` 的最小公共祖先规则），机械可判，不是偏好。** 视觉资产引用的挂载面已经由 `art/visuals/_index.md` 的
资产类目表逐行点名，横跨至少五个内容类、两棵子树：

| 资产类目 | 挂载的内容类 | 所在子树 |
|---|---|---|
| 卡面插画 | `CardData` | `character-profile/deck/` |
| 敌人立绘 | `EnemyData` | `enemies/` |
| 法则 / 神通 / 古宝 / 法宝 图标 | `PowerData` / `ItemData` | `player-profile/` + `character-profile/` |
| 事件背景板 | `LocationData` | `game-progression` 侧 |
| 事件插图（前期不产出） | `AdventureEventData` | `adventure-event/` |

≥2 个兄弟节点、语义同一（「这个内容条目的主视觉资产」）⇒ **最小公共祖先是顶层 `systems/common-properties.md` 的「## 内容共有字段」**，
与 `ContentEnabled` / `LocalizedText` / `Rarity` 三条同层。`EnemyData` 侧只写一段五行以内的**投影段**（照判据卡的模板）。

这条归属还有两处独立佐证：
- `systems/common-properties.md`「展示字段的归属」与 `ADR-0010` 已经把「**图标**」与显示名 / 描述并列写进第一层——
  归属本就已定，缺的只是**类型与形态**；紧随其后那句「第一层那些静态展示文本的类型是 `LocalizedText`」只覆盖了文本，视觉那一半悬空至今。
- `systems/player-profile/codex/common-properties.md:77` 直接把它当作「既有美术挂点 · 不新增」来消费——
  图鉴族已经把这格的存在当成前提在写了。

> **落笔面的连带影响（重要）：** 采纳本节即意味着本次不止改 `systems/enemies/*`，还要改
> `systems/common-properties.md`（新增一节定义）、`systems/character-profile/deck/common-properties.md:246`（把「美术引用」换成字段名）、
> `systems/player-profile/codex/common-properties.md:77`（「不新增」需改写为「本次新增一格」）。**范围取向见「## 仍需用户决定」第 1 条。**

---

### C. 视觉资产引用的类型 = `[Export]` 直接资源引用，不是路径字符串、不是约定路径推导

`[既有推演]` + `[通行做法]`

```csharp
// systems/common-properties.md · 「## 内容共有字段」新增一节
// 挂载面：CardData / EnemyData / PowerData / ItemData / LocationData / AdventureEventData
[Export] public Texture2D Artwork { get; set; }       // 可空；null = 尚未产出，呈现层回落占位资产
```

**取直接资源引用的四条理由，逐条对上既有纪律：**

1. **C3 的正面要求。** 路径字符串形态（`[Export(PropertyHint.File)] public string ArtworkPath` + 运行时 `ResourceLoader.Load`）
   同时撞两条既有纪律：「绝不用场景路径……作为内容的键」与「不散落 `ResourceLoader.Load`」。
   **「按 `Id` 约定路径推导」（连字段都不要）撞得更狠**——它把资产寻址完全建立在文件路径上，且**不可 overlay 热更**：
   路径由 `Id` 定死，换一张图只能发版，而 C4 允许 overlay 改既有条目的字段值。
2. **它是 Godot 的既定形态。** `.tres` 里落为 `ExtResource`，编辑器可拖拽、类型受检；**悬空引用在资源加载时即由引擎报出**，
   不需要本库另写一条悬空校验，也不需要发明「前缀 → 去哪查」的约定表——这与 `PoolScope` 取具名 `Id` 字段而非 tag 的判据完全同构。
3. **对 overlay 的语义是清楚的、且是自洽的。** C4 下二进制资产恒随包，overlay 能做的是**把一条 `EnemyData.tres` 的 `Artwork`
   改指到基线内已存在的另一张图**；指向基线外的路径则 overlay 加载失败、按既有口径回退基线。
   「换图必须发版、换指向不必」这条分界与「新内容随版本发布、平衡与文案走 overlay」逐字同构。
4. **它不需要多语言结构。** C7 已禁止插画内烧入可翻译文字 ⇒ 视觉资产与 locale 无关，
   **`Artwork` 是裸 `Texture2D` 而非某种 `LocalizedTexture`**——这一格无须回答「第二个 `LocalizedText`」的问题。

**字段名取 `Artwork`（单数、类型中立）而非 `Portrait` / `Icon` / `Illustration`：**
同一格在敌人身上是立绘、在卡牌上是卡面、在法则上是图标；按 C2 上移到顶层的字段必须用**跨落点同义**的名字，
落点差异由各层投影段的「本层语义」一行承载（与 `Rarity` 一格覆盖四类、语义由各层投影解释同款）。

**缺失语义 = 可空 + `PushWarning` + 占位资产（不是 `PushError`）。** 这条由 C8 直接推出：
`vision/scope.md` 与 `ADR-0006` 都把「美术挂点先占位、末段替换」写成路线级安排，若 `Artwork` 必填，
第一批 `.tres` 会在美术产出之前全部过不了 `LoadAll()`。判据与 `AiProfile == null` 合法、`PoolScope == null` 合法完全同款——
**漏填的后果是显示一张占位图，不是死内容、不产生静默污染**（对比 `EncounterScopes` 空数组 → 条目永不进池 → `PushError`）。

按 `ADR-0013` 的选级判据这也正确：漏填在开发期第一眼就显形（屏幕上是占位图），属「只在开发期显形」那一档，第 3 级足够。

```
Artwork == null                          → PushWarning（带条目 Id + 类型名），呈现层回落占位资产
Artwork 非 null 但 ExtResource 悬空       → 由引擎在资源加载期报出，本库不另写校验
```

**占位资产是一处、不是每个类一处：** 由 ViewModel 层统一提供一张 `res://art/_placeholder.png`
（该文件归 `game-feature-branch/`，本库只登记这条约定）。这与「回落逻辑只写一处」的 `LocalizedText.Get()` 同一种偏好。

**明写的代价（见「## 后果」）：** `ExtResource` 直引意味着 `LoadAll()` 会把全部条目的贴图一并驻留。

---

### D. 敌人台词 = `EnemyLine[]`（内嵌 `Resource` + 具名字段），照抄 `AiWeight`；**槽位清单被战斗 UX 专场阻塞**

`[既有推演]`（形态）＋ 前置依赖（成员）

台词是**文本内容、不是音频资产**——这一点全库一致：`art/soundtracks/` 六个类目里没有人声轨、没有「配音 / 语音 / bark」任何字样；
而 `systems/enemies/_index.md:99` 与 `systems/adventure-event/combat/_index.md:204` 都把台词与图鉴词条并列为**写作口径**的对象
（「标为 `[Practice, Standard]` 的条目，其图鉴与台词必须同时说得通『切磋』与『厮杀』」）。故它走 `LocalizedText`，不走资产引用。

台词天然是「若干场合各一句、只写要写的那几句」——**与 `AiWeight` 的稀疏覆写数组逐字同构**，建议直接照抄那个已被采纳的形状：

```csharp
// EnemyData 上（只落 enemies/，不上移——挂载面只有敌人一处，按 C2「只有一个落点的字段不进任何 common-properties.md」）
[Export] public EnemyLine[] Lines { get; set; } = [];     // 只列要写的场合；空数组合法 = 无台词

[GlobalClass]
public partial class EnemyLine : Resource                  // 内嵌 Resource + 两个具名字段，同 AiWeight / TechniqueRef / PoolScope
{
    [Export] public LineSlot      Slot { get; set; }
    [Export] public LocalizedText Text { get; set; }
}

public enum LineSlot { /* ⟨待定：成员清单随战斗 UX 专场一并定，见「## 前置依赖」⟩ */ }
```

加载期校验三条，**逐条照抄既有分档、不另立判据**：

| 违规 | 处置 | 判据来源 |
|---|---|---|
| `Lines` 为空数组 | **合法**，不报错不告警（= 该敌人无台词） | 同 `AiProfile == null`：漏填只是回落到一条可用路径 |
| 同一 `LineSlot` 重复出现 | `PushError`（带敌人 `Id` + 重复 `Slot`） | 逐字照抄 `AiWeight` 同 `Term` 重复、`TechniqueRef` 同 `TechniqueId` 重复 |
| 某条 `Lines` 的 `Text == null`，或其默认语言 `zh` 缺失 / 为空串 | `PushError` + 抛（带敌人 `Id` + `Slot`） | 「挂了却默认语言为空串仍是坏数据」，`systems/common-properties.md` 可选 `LocalizedText` 一节 + `content-service.md:105` |

> 注意第三条与第一条的分工：**整条 `EnemyLine` 不存在 = 合法**（对应「字段本身为 `null`」那条既有判据）；
> **挂上了却是空壳 = 坏数据**。这正是 `log-codex-entry-schema.md` 已经答定的那条口径，本稿不重新裁决。

**`LineSlot` 的成员清单本稿不列举**（绝不臆造）：台词的呈现落点在本库尚无任何表述——
`ux/screen-flow.md:148–163` 的战斗前确认页表格只有「常驻标注（双方等级）」与「图鉴摘要区」两项、**没有台词位**；
`ux/combat-ux.md` 侧「战斗屏幕的其余形态整体未设计，待一次专门的战斗 UX 专场」（`open-questions/01-combat.md:41`）。
成员清单必须与那场专场一并定，否则写下的是一组无消费点的枚举值。**本次落不落这一格，见「## 仍需用户决定」第 2 条。**

---

### E. 敌人条目**不开音效引用字段**；建议把待答清单上的「音效引用」一格以「已判定不需要」结案

`[既有推演]`

`systems/enemies/common-properties.md:81` 把「音效引用」与立绘、台词并列登记，但**它与另两格的性质不同**：

1. **音频类目表里没有它的位置。** `art/soundtracks/_index.md` 六个类目——主题曲 / 战斗 BGM / 事件 BGM / 篇章氛围 /
   UI 音效（出牌、抽牌、结算、按钮、翻页）/ 反馈音效（道念增减、被削减、胜负结算、寿元告警）——
   **没有任何一条是按敌人条目逐条产出的**；出牌音属卡牌动作、受击音属道念反馈，两者都已经在别的类目名下。
   敌人级独有的只剩「入场吼叫」一类，而它的存在性在全库没有一处表述。
2. **恒无对象的伸缩位是本库反复否决的东西。** `EnemyInstance` 写单数不留列表、`PoolScope` 维度按既有权力面封闭、
   敌方不为天劫开第二条构筑通道——三处的理由逐字相同：「留一个恒无对象的格只会让每个消费点都要处理一个永不发生的分支」。
3. **C10 的第二句加固了这个结论**：多数玩家静音游玩，音频必须是增益而非唯一通道 ⇒ 敌人级音效即便日后有，
   也不会承载任何机制语义，属纯演出层；而演出层的挂点归 `visuals/animations/`（其范围与技术载体本就整体待定）。

建议因此把 `systems/enemies/common-properties.md` 那条待决项**改写而非删除**：三格中立绘与台词由本稿给出形态，
音效一格记为「**已判定不为敌人条目开字段**」并留一句理由与回链（日后确有需求是纯加法，与「不另加带数字的胜率口径」同款处理）。

---

## 具体形态（可 derive 的落地面）

### E1 · 顶层新增内容共有字段（`systems/common-properties.md`「## 内容共有字段」）

| 项 | 取值 |
|---|---|
| 字段 | `Artwork : Texture2D`，`[Export]`，**可空**，默认 `null` |
| 挂载面 | `CardData` · `EnemyData` · `PowerData` · `ItemData` · `LocationData` · `AdventureEventData` |
| 语义 | 该内容条目的**主视觉资产**（一条内容一张；各层语义由投影段解释） |
| 不挂载 | 任何运行时 / 存档态类型（`CardInstance` / `EnemyInstance` / `EventOption` / 图鉴 `CodexEntry`）——C1 第二层只带 `Id` |
| 多语言 | **不适用**（C7：插画内不得烧入可翻译文字） |
| 存档 | **不落存档、不进上行负载**，不 bump schema、无迁移（同 `LocalizedText`） |
| overlay | 落在「只改不增」内——可改指向，**不可引入基线外的新资产**（C4） |
| 校验 | `null` → `PushWarning`（带条目 `Id` + 类型名），呈现层回落占位；悬空 `ExtResource` 由引擎在加载期报出 |
| 消费点 | ViewModel 组装（`systems/viewmodel.md`）；敌人侧两处：战斗屏（点按 = 选目标）与图鉴词条页 |

### E2 · `EnemyData` 侧投影段（`systems/enemies/common-properties.md`，照判据卡模板 ≤5 行）

```markdown
- **`Artwork`（共有字段 · 类型 `Texture2D` · 2026-08-28）。** 本层落在 `EnemyData` 上 = 敌人立绘。
  - **本层合法取值 / 默认值 =** 可空，默认 `null`（尚未产出 → 呈现层占位）。
  - **本层消费点：** 战斗屏敌方区（点按语义 = 选目标）与 `EnemyCodex` 词条页，**同一张资产两处复用**。
  - 类型定义、校验语义见 `systems/common-properties.md`；资产规格见 `art/visuals/_index.md`「敌人立绘」。
```

### E3 · `EnemyData` 独有字段（`systems/enemies/_index.md` 字段总表 + `common-properties.md` 校验表）

| 字段 | 形态 | 缺失时 |
|---|---|---|
| `Lines` | `EnemyLine[]`（内嵌 `Resource`：`LineSlot Slot` + `LocalizedText Text`） | **空数组合法**（= 无台词）；同 `Slot` 重复 → `PushError`；`Text == null` 或默认语言空串 → `PushError` + 抛 |
| （音效） | **不设字段**（见 § E） | — |

### E4 · 连带修订的三处既有表述

| 文件 | 现状 | 建议改为 |
|---|---|---|
| `systems/character-profile/deck/common-properties.md:246` | 字段清单末项「· 美术引用」 | 「· `Artwork`（共有字段）」+ 一句投影 |
| `systems/player-profile/codex/common-properties.md:77` | 「…与既有美术挂点 \| **不新增**」 | 「…与 `Artwork`（`systems/common-properties.md`，2026-08-28 新增一格）\| 不新增**结构**」 |
| `art/visuals/_index.md:19` | 敌人立绘一行的「对应内容条目」列写 `systems/adventure-event/combat/`（`EnemyData`） | 改为 `systems/enemies/`——enemies 自 08-22 已升为与 `adventure-event` 平级的系统（见「越界发现」） |

## 后果

- **改动面横跨五份主题文档**（`systems/common-properties.md` · `systems/enemies/_index.md` + `common-properties.md` ·
  `systems/character-profile/deck/common-properties.md` · `systems/player-profile/codex/common-properties.md`），
  外加 `art/visuals/_index.md` 一处回链修正与 `systems/services/combat-service.md` 的 `AiWeightVector` 补齐。
  **这超出「只答敌人一条」的范围**，是 C2 判据的必然结果，非本稿主动扩张——取向见下。
- **存档 / 同步零影响**：`Artwork` 与 `Lines` 都是内容定义的属性，不落存档、不进上行负载，**不 bump schema、无迁移**。
  后端零配合。
- **内存代价（明写接受 + 退让阶梯）：** `ExtResource` 直引使 `LoadAll()` 把全部条目的贴图一并驻留内存。
  条目量级（敌人数十、卡牌百级）× 移动端压缩贴图，量级上可接受；**若真机实测超包体 / 内存预算，退让阶梯是**：
  ① 先降资产分辨率与压缩格式（纯资产侧，零结构改动）→ ② 才考虑改为 `[Export(PropertyHint.File)] string` +
  在 ViewModel 层开**唯一一处**受控的资产加载入口（仍不散落 `ResourceLoader.Load`）。
  给出阶梯是为了让「内存不够」将来有一条不必重开本次形态裁决的出路（写法照抄 `KeyCardIds` 上界的退让阶梯）。
- **`content/` 层受益**：`content/_TEMPLATE-entry.md:53` 的「美术 / 音频需求」一节从此有一个可填的字段值
  （条目文档只写「填了什么」+ 回链 guide，不复述类型——`content/_index.md:6–12` 的硬边界原样成立）。
- **`deferred-content.md:46`「生成资产落地的命名与导入规则」的性质改变**：本方案取显式引用后，
  资产**寻址**不再依赖命名约定，那条待答项收窄为「目录划分 + 是否需要 asset 清单做完备性校验」两问，不再阻塞字段落地。

## 备选方案（已考虑并否决）

- **`[Export(PropertyHint.File, "*.png")] public string ArtworkPath` + 运行时 `ResourceLoader.Load`** —— 撞 C3 两条纪律
  （路径当键、散落 `Load`），且丢掉类型信息使悬空只能在运行时炸；仅作为内存实测失败后的退让阶梯第二档保留。
- **无字段，按 `Id` 约定路径推导（`res://art/enemy/<Id>.png`）** —— 同上两条之外再加两条致命处：
  **不可 overlay 热更**（路径由 `Id` 定死，换图必须发版），且「资产缺失」无法在加载期机械发现。
- **`Portrait` / `Icon` / `Illustration` 三个按用途分立的字段** —— C6 已明写敌人立绘「图鉴与战斗屏复用」同一张；
  分立会让每个内容类都要回答「我该填哪几格」，且三格中至少两格恒空。
- **为敌人另开 `Sfx : AudioStream` / `VoiceLine` 字段** —— 见 § E：音频类目表无对应类目、恒无对象的伸缩位。
- **台词写成一组具名字段（`IntroLine` / `VictoryLine` / `DefeatLine`）而非稀疏数组** ——
  每加一个场合就要改 C# 类 + 发版，撞「新增内容 = 新增 / 编辑 `.tres`，不改 switch」；
  这正是 `LocalizedText` 否决「每语言一个 `[Export]` 字段」的同一条理由。
- **把台词也上移为顶层共有字段** —— C2 的下沉判据：挂载面只有 `EnemyData` 一处，
  「只有一个落点的字段不进任何 `common-properties.md`」。
- **在 `EnemyData` 上另开一格 `AiWeightVector` 的缓存** —— 撞「`XxxData` 是共享只读单例，任何服务不得运行时写它」；
  展开产物落 ContentRegistry 派生索引，与样本卡组同款。

## 与既有决策的张力

1. **`systems/player-profile/codex/common-properties.md:77` 的「既有美术挂点 · 不新增」是一处指向不存在之物的引用。**
   本方案采纳后它不再失真，但那一行的**结论词需要连带修订**（词条构成表里那一行的「不新增」原本是在陈述「不为图鉴新增结构」，
   而事实是这格连在内容类上都还不存在）。冲突的不是决定本身、只是措辞与前提；**不松动任何决策即可修复**，
   只需按 E4 改写。**若用户认为该行应原样保留**，则本方案的 B 节归属结论需重新讨论。
2. **`deferred-content.md` 把 `art/` 整体搁置到开发路线第 ② ③ 阶段，而本稿主张现在就定字段形态。**
   两者**不冲突但必须明写区分**：搁置的是**资产产出与逐条取值**，本稿定的是**字段形态**；
   论据即 C11 的纯加法窗口判据（`LocalizedText` / `DrawPool<T>` 用的是同一条），且 `content/` 下当前零条目、窗口仍开着。
   **需要用户确认这条区分成立**——若用户认为「形态也该一并搁置」，本稿 B / C / D 三节整体延后，① 的 `AiWeightVector` 补齐仍可单独落。
3. **本稿主张的落笔面超出「敌人一条待答项」。** 严格按 `ADR-0057` 判据，这格必须落顶层；
   但那意味着一次运行改五份主题文档、并触碰两个不属于敌人的子树。这条张力由「## 仍需用户决定」第 1 条承接。

## 前置依赖

- **`LineSlot` 的成员清单** ← **战斗 UX 专场**（`open-questions/01-combat.md:41`「战斗屏幕的其余形态整体未设计，
  待一次专门的战斗 UX 专场」；`ux/screen-flow.md:148–163` 的战斗前确认页表格现无台词位）。
  **本方案的 D 节形态可先定稿，枚举成员在该专场答定前无法填写**——本稿不臆造任何槽位。
- **`Artwork` 的基数（单格 vs 按境界的数组）** ← **「境界晋升是否改变角色 / 敌人外观」**
  （`open-questions/deferred-content.md:52`，原文「直接决定同一角色需要 1 套还是 4 套资产」）。
  本稿按**单格**给出形态（当前唯一有依据的口径是 C6「同一敌人在图鉴与战斗屏复用」一张）；
  若该项答为「随境界改变」，`Artwork` 需升为按境界索引的结构，**本稿的 C / E1 两节须重做**。
- **资产的目录划分与 asset 清单完备性校验** ← `open-questions/deferred-content.md:46`
  （本方案使它不再阻塞字段落地，但仍需答定，见「后果」末条）。
- **兜底权重十项的数值初值** ← 「卡牌产 / 削道念的量纲基准」（`open-questions/01-combat.md:22`）。
  **不阻塞 A 节**——`systems/balance.md:291` 已明写「结构不受阻塞，字段形态、term 清单、校验规则可先落笔并 derive」。

## 仍需用户决定

1. **本次落笔的范围：只给 `EnemyData` 开一格，还是按 `ADR-0057` 判据一次升为顶层共有字段？**
   - **选项 A（推荐）· 一次做全库。** 在 `systems/common-properties.md` 定义 `Artwork`，
     `EnemyData` / `CardData` / 图鉴族三处各写投影或连带修订（E1 + E2 + E4）。
     **后果**：本次改五份主题文档；`CardData` 字段清单的「美术引用」占位与图鉴族的「既有美术挂点」同时被填实，
     全库不再有第二处指向不存在字段的引用。**理由**：C2 是可机械判定的规则而非偏好；
     且 C11 的纯加法窗口对全库同时成立——`content/` 现在零条目，窗口在写下第一批 `.tres` 时关闭，
     届时补做等于「改全部资产」（`LocalizedText` 排期用的正是这条论证）。
   - **选项 B · 只落 `EnemyData` 一格，顶层化留待日后。**
     **后果**：改动面小、可控；但等于**明知违反 C2 而先落一处**，且 `CardData` / 图鉴族两处失真原样留着；
     日后上移时要改 `.tres`（若届时已有条目）与三份文档，成本单调上升。
   - **选项 C · 连字段形态也一并搁置**（承认「张力 2」不成立，`art/` 整体延后即字段也延后）。
     **后果**：`content/enemy/`、`content/card/` 的条目文档继续填不出这一格；纯加法窗口在第一批 `.tres` 写下时关闭。

   → **已裁决（2026-08-28 · 批量评审）：选 A —— 一次升为顶层共有字段。** 按 E1 + E2 + E4 执行：
   `systems/common-properties.md` 新增 `Artwork : Texture2D` 定义节，`EnemyData` 侧写投影段，
   并连带修订 `deck/common-properties.md:246`（「· 美术引用」→ 字段名）、`codex/common-properties.md:77`（「既有美术挂点 · 不新增」→ 指向新格）、
   `art/visuals/_index.md:19`（敌人立绘行的过时回链）。**张力 1 与张力 2 随本裁决一并解除**：
   张力 1 按 E4 改写措辞（不松动任何决策）；张力 2 的区分成立——搁置的是资产产出与逐条取值，本次定的是字段形态。

2. **本次是否落 `Lines`（敌人台词）一格？**
   - **选项 A（推荐）· 现在落形态，`LineSlot` 成员留空并明写阻塞。**
     形态（内嵌 `Resource` + 稀疏数组 + 三条校验）已完全可由既有形状推出，与 `AiWeight` 逐字同构，不欠任何前提；
     枚举成员写成 `⟨待定：随战斗 UX 专场⟩`，与本库「形状依赖未答问题的写 `⟨待定：链接到待决项⟩`，不留空白也不臆造」
     这条 API 书写规范一致。**后果**：`systems/enemies/` 多一格暂无成员的枚举，
     `/derive-requirements` 对该格只能产出形态级验收标准。
   - **选项 B · 整格延后到战斗 UX 专场一并定。**
     **后果**：`systems/enemies/common-properties.md:81` 的待决项从「三格」收窄为「一格（台词）」，
     条目文档在专场之前无处写台词；好处是一次把形态与成员一起定完，不留半格。

   → **已裁决（2026-08-28 · 批量评审）：选 A —— 现在落形态，`LineSlot` 成员写 `⟨待定：随战斗 UX 专场⟩`。**
   D 节的形态（内嵌 `Resource` + 稀疏数组 + 三条校验）按原样提炼；枚举成员留待专场，不臆造任何槽位。

> 除上述两条外，本稿其余各项均已由既有决策或工程常识默认给出，不需要用户逐条点头；
> 被否决的备选已逐条列在「## 备选方案」。
