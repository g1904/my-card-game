# character-profile

> 角色信息 / **CharacterProfile** —— 单次轮回 / 单个角色的状态与历史（对齐 CycleState 概念）。

## 意图
> _设计意图，从 handoffs 中提炼。保持更新。_

- **CharacterProfile = 单次轮回 / 单个角色的状态与历史。** 每个 CharacterProfile 对齐 **CycleState** 概念：一次轮回、一个角色所走过 / 可走的整段修行历程与当前状态。它由账号级的 **PlayerProfile** 持有（`List<CharacterProfile>`）。（+ `systems/services/life-cycle-service.md`、`terminology.md`）。
- **角色是有身份的模板，不是程序化生成的空白人（承重）。** 引入内容条目 **`CharacterData`**（区别于本文档的 `CharacterProfile` —— 前者是模板，后者是某一次轮回的角色状态）：
  - **开局由玩家从角色池中指定一个角色**（炼气起手仍可无限重试，门禁只落篇章层、不落角色层）。
  - **每个角色自带一个神通（`CharacterPower`）与两门绑定功法**，且**与角色绑定**——同一个角色的每一局，神通与这两门功法都相同。**推论：跨轮回的熟悉感有了载体**，「这个角色打起来是什么手感」成为玩家可积累的知识。
  - **绑定不等于不可动摇**：那两门功法**同样可被弃置**（见 `deck/_index.md`）——角色给的是**起手形状**，不是永久底盘。
  - **每个角色带一个先天灵根 `Affinities`**，它是角色之间除「神通 + 两门绑定功法」之外的第二条辨识轴，唯一的规则后果是功法的**硬性修习准入**（见下方「灵根」段与 `deck/_index.md`）。
  - 角色池的规模、选取机制、是否账号级逐步解锁，见下方「角色模板池的形态」与「`CharacterData` 的字段面」。
- **`CharacterData` 的字段面（内容条目，`[GlobalClass] partial class CharacterData : Resource`，以 `.tres` 编写）。** 它与 `CharacterProfile` 是两件东西：前者是模板、共享只读单例、静态字段不落存档；后者是某一次轮回的角色状态。

  | # | 字段 | 类型 | 必填 | 语义 / 取值 |
  |---|---|---|:--:|---|
  | 1 | `Id` | `string` | 是 | 两段式 **`character.<snake_case_slug>`**（例 `character.ling_yun`）。前缀 `character` 与既有主类型前缀词表（`character_item.` / `player_item.` / `character_power.` / `player_power.`）不撞车 |
  | 2 | `ContentEnabled` | `bool` | 是 | 照常参与 `AllEnabled()` 与 flags 通道；**读取侧 `Get(id)` 不过滤** |
  | 3 | `Artwork` | 见 `systems/common-properties.md`「`Artwork` 挂载面」 | 是 | 角色形象的**基础图**（全部境界的回落底） |
  | 4 | `RealmArtworks` | `RealmArtwork[]` | 否 | **稀疏的境界覆写**：只列「这个境界要换图」的那几档；默认空数组 = 全程用基础图。见下方「角色形象随境界的覆写」段 |
  | 5 | `PowerId` | `string` | 是 | 绑定的那一个神通，须 `PowerData.Scope == Character` |
  | 6 | `TechniqueIds` | `string[]`（长度恒 2） | 是 | 两门绑定功法；**可被弃置**（弃置的是 `CharacterProfile` 里的那份，模板不变） |
  | 7 | `Affinities` | `Affinity[]` | 是 | 该角色的先天灵根，见下方「灵根」段 |

  - **明确不带的格：** **`Rarity`**（它在本库的两个消费点是抽取加权与定价档，角色既不进任何授予池也不被定价；加一格会立刻引出「稀有角色抽不到」这条与「无门槛起手」正面冲突的语义）· **`ExclusiveSource`**（该字段只覆盖 `PowerData` / `ItemData`，语义是「不进抽取池」，与角色的取用方式无关）· **任何解锁条件字段**（首批不做账号级逐步解锁，见下）· **绑定功法的初始层数**（两门绑定功法**恒以第 1 层入组**，与 `LearnTechnique` 的入组层数同款，故不设字段。逐条编排会给角色之间再添一条**纯强度**轴，与「灵根把差异推向能修哪一路、不推向谁更强」相抵；且起始层数的合法上界就是仍待校准的 `MaxTier`，逐条编排此刻只能定结构、定不出取值。见 `deck/_index.md`）。
    - **日后若要做成逐条编排，最小路径已知：** `TechniqueIds : string[]` → `BoundTechniques : BoundTechnique[]`（长度恒 2），元素为 `TechniqueId : string` + `InitialTier : int`（默认 `1`，与今天的口径等价）+ 三条加载期校验（`TechniqueId` 解析不到 / `InitialTier < 1` / `InitialTier > 该功法 MaxTier`，均 `PushError` 带 `characterId` 与功法 `Id`）。**仍是零存档增量**（模板静态字段，不 bump `schemaVersion`、无迁移、后端零影响），代价只在 `.tres` 结构与那一行字段表。集合字段名取复数 `BoundTechniques`、元素类型名取单数 `BoundTechnique`（同 `RealmArtworks` / `RealmArtwork`）。**首批不做。**
  - **静态字段不落存档、不进上行负载。** 存档侧的载体只有 `CharacterProfile.characterDataId` 一格，它早已存在且形态已定 ⇒ **存档 schema 增量为 0、不 bump `schemaVersion`、后端零影响**。
- **`Artwork`（共有字段 · 类型 `Texture2D`）在本层的投影。** 落在 `CharacterData` 上，是该角色的**基础形象**。
  - **本层合法取值 / 默认值 =** 可空，`null` = 尚未产出、呈现层回落占位资产。
  - **本层消费点：** ViewModel 组装角色形象时作为回落链的第二级（第一级是下方 `RealmArtworks` 的境界覆写），见 `systems/viewmodel.md`。
  - 类型定义、取值清单、校验语义见 `systems/common-properties.md`。
- **角色形象随境界的覆写：`RealmArtworks`（本类自有字段，不是共有字段）。** 角色是七个 `Artwork` 挂载面里**唯一**带真实境界维度的那一个——敌人的境界是 `EnemyInstance` 的物化产物、不在模板上（见 `systems/enemies/_index.md` 与 `decisions/ADR-0044-enemy-leveling-band.md`），地域三章共用同一张图（`decisions/ADR-0042-location-flat-set-and-single-map.md`），卡牌 / 法则 / 神通 / 古宝 / 法宝 / 事件插图与境界正交。**只有一个落点的字段不进 `common-properties.md`**（判据卡），故它落在本文档，共有字段 `Artwork` 的基数保持「一条内容一格」不变。

  ```csharp
  // CharacterData 上的一格。稀疏覆写：只列「这个境界要换图」的那几档。
  [Export] public Godot.Collections.Array<RealmArtwork> RealmArtworks { get; set; } = new();

  [GlobalClass]
  public partial class RealmArtwork : Resource
  {
      [Export] public Realm     Realm   { get; set; }   // 共享核心枚举，见 systems/architecture.md
      [Export] public Texture2D Artwork { get; set; }   // 挂了这一条就必须给图（校验 R-2）
  }
  ```

  - **字段名取复数 `RealmArtworks`、元素类型名取单数 `RealmArtwork`。** 集合字段名与元素类型名不得逐字相同——类内的成员查找会遮蔽同名类型，`new RealmArtwork()` 在 `CharacterData` 内无法解析。同族先例是 `EnemyData.Lines : EnemyLine[]`（`decisions/ADR-0120-content-artwork-and-enemy-lines.md`）。
  - **取稀疏数组，不取按 `Realm` 序号索引的定长四格数组。** 定长形态里「这一档没画」与「这一档就用基础图」不可区分，而两者的正确行为不同（前者该进缺失统计、后者不该）；稀疏数组把它变成干净可判的条件——与可选 `LocalizedText` 字段「缺失 = 子资源本身不存在」（`systems/common-properties.md`）同一种判据风格。
  - **它天然是纯加法。** 内容侧可以先只填基础图一张，日后逐境界补一条，零结构改动，完全落在「美术挂点先占位、末段替换」内（`decisions/ADR-0006-development-phase-order.md`、`vision/scope.md`）。**首发不承诺出满四档。**
  - **选取与回落由 ViewModel 单点承担**（境界覆写 → 基础图 → 占位资产；无当前轮回时直接取基础图），落点与承重见 `systems/viewmodel.md`。**境界来源是既有存档字段 `CharacterProfile.realm`** ⇒ **零新增存档字段、不 bump `schemaVersion`、无迁移、后端零配合**。
  - **overlay 语义与共有字段 `Artwork` 逐字同款**：`RealmArtwork` 是同一份 `.tres` 内的子资源，overlay 覆盖该条 `.tres` 时随之被覆盖，**指向必须落在随包基线内已存在的资产**（换的是引用，不是二进制本身）。
  - **三条加载期校验：**

    | 编号 | 违规 | 处置 |
    |---|---|---|
    | R-1 | 同一条目的 `RealmArtworks` 内 `Realm` 重复 | `PushError`，带 `characterId` 与 `.tres` 路径 —— 两条同境界 ⇒ 选取不确定 |
    | R-2 | 某条 `RealmArtwork` 已挂上但 `Artwork == null` | `PushError`，带 `characterId` 与该条的 `Realm` —— 「挂了却为空」是坏数据，同可选 `LocalizedText` 的既定口径 |
    | R-3 | `RealmArtworks` 为空数组 | **不告警**，合法常态 = 全程用基础形象（同 `Lines` 默认空数组 = 无台词） |

  - **不进 `LoadAll()` 那行 `Artwork` 缺失汇总**：已挂条目的缺图由 R-2 拦死，该汇总的口径不变（只数共有字段 `Artwork == null` 的条目数）。
  - **资产量级：** 每个角色一条基础 + 至多三条境界覆写 ⇒ 全量 **20 张**（池规模 5 × 4 档），MVP（炼气 → 筑基一个篇章）只需 **10 张**，稀疏形态使首发下限为 **5 张**（每角色一张基础图）。
- **角色模板池的形态：全池指定 · 首批 5 个 · 不做账号级解锁。**
  - **池规模 = 5**，五个角色各持一个不同的单灵根（金木水火土全覆盖）。**池规模不是一格数值旋钮，而是 `content/character/` 里 `ContentEnabled == true` 的条目数**；线上收缩用 `ContentEnabled` / flags。增减角色是纯加法（加一份 `.tres` + 一个神通条目 + 两门功法条目），不改任何结构。**它是待校准初值**，随 ch1 starter deck 打磨与功法条目规模定标。**不进 `systems/balance.md`**——角色池的归属在本文档，`balance.md` 无角色维度数值表，新开一行即制造第二权威。
  - **内容量账：** 5 个 `character-power/` 条目 + 10 门 `cultivation-technique/` 条目 × `MaxTier` 套卡牌定义。这是 ch1 排期必须正视的那一笔。
  - **选取机制 = 开局由玩家从全池自行指定。** 无随机候选集、**无重抽通道**（重抽等于免费 reroll，与「候选预先算定、封死 reroll」同向否决；且本作没有账号级可支配货币，重抽也无从定价）。**完全不涉及 RNG**——四条子流不变、`AccountStream` 不动、不新开子流、不占 `RngElements` 列。服务面见 `systems/services/life-cycle-service.md`。
  - **角色是「被选取的产出侧对象」，故配有 `ContentEnabled` 开关。** 判据用现成的那一条——「能被抽取 / 被选取的才配有开关」（`PlotArcData` 与 `LocationData` 的分野即此）。关一个角色只让它**不再被新轮回选中**；已写进 `characterDataId` 的角色照常经 `Get(id)` 解析，**进行中的轮回不因线上关闭而坏档**。这正是「解析不到 → `PushError`」与「线上可秒关一个问题角色」两条不冲突的原因。
  - **可抽取性 = 自身 `ContentEnabled` ∧ 全部绑定条目 `ContentEnabled`。** 它使「绑定条目被关掉」不需要任何运行时特判——取池时多一层过滤即可，与 `AllEnabled()` 的过滤位置完全同构。
  - **首批不做账号级逐步解锁**，全部角色恒可用。三条依据任一单独成立即足以否决：「元进程解锁」明确在范围之外（`vision/scope.md`）· 炼气可无门槛起手、门禁只落篇章层（`ux/onboarding.md`），角色层再加一道门等于把「无门槛」这四个字改掉 · 没有现成载体（`PlayerEntitlement` 只放付费凭证本身与其兑现水位、`Achievement` 的奖励形态限定为法则 / 古宝条目、Codex 记的是「见过」而非准入；flags 是运营灰度通道，分桶规则不在客户端、`AllEnabled()` 拒绝接受 `bucketContext`，与玩家进度通道不得合流）。
    - **负面边界（承重）：解锁绝不可做成付费点。** `systems/monetization.md` 的负面边界五项 + 唯一预留方向（纯外观）已把它关死——付费解锁角色既不是「有档、有上限的宽松化」，也不在纯外观内。
    - **日后要做时的最小路径：** `PlayerProfile` 加一个具名集合字段（元素用 `readonly record struct` 包一层，照 `CodexEntry` 的加法窗口纪律）+ 一条取池过滤（`AllEnabled()` ∩ 已解锁集合）+ 一次 `schemaVersion` bump。**不需要任何新机制。**
  - **已接受的代价（承重）：** ch1 无限重试 + 全池指定下，**角色强度差有可能塌缩为「只有一个角色被玩」**，跨轮回熟悉感因此只覆盖玩家自选的那一个。灵根把角色差异从「谁更强」推向「能修哪一路功法」，已部分缓解这条代价，但**仍可能存在一个综合最优的属性池**——待实测。这条代价是日后重估角色池设计的判据起点，不得删。
  - **首玩局的缓解 = 在选择屏标注推荐项**（内容侧一格标记），**不做「首局跳过选择」的特判**——特判会造出两条起手路径，而两条路径必然各自漂移。
- **灵根 `Affinity`：角色的先天资质，唯一的规则后果是功法的硬性修习准入。**

  ```csharp
  public enum Affinity
  {
      Unspecified = 0,   // 防御性哨兵：唯一作用是让「漏填」可被加载期检出（照 Source.Unknown = 0 的先例）
      Metal = 1,         // 金
      Wood  = 2,         // 木
      Water = 3,         // 水
      Fire  = 4,         // 火
      Earth = 5,         // 土
  }
  ```

  - **`Unspecified = 0` 是必需的**：Godot 的 `[Export]` 枚举未填即取 0，没有哨兵就无法把「漏填」与「填了金」区分开——这与 `Pool` / `CardType` 必填纪律的理由完全相同。
  - **灵根固定在 `CharacterData` 上，一局不变。** 它是内容条目上的**静态分类维度**（与 `Rarity` / `Pool` 同族），**不产生任何运行时状态、不进 `CharacterProfile`、不进上行负载**——故它不落在 `vision/scope.md`「范围之外（暂时）」所排除的那种「支撑 Reigns 式平衡张力的完整属性模型」内（那一条指的是 `faith` / `bloodlust` 一类运行时可推拉的资源条）。
    - **日后若要做成轮回内可变，最小路径已知：** `CharacterProfile` 加一格可空 `Affinity[] affinitiesOverride`（`null` = 取模板值）+ `ProfileChangeSpec` 加一列 + 一次 `schemaVersion` bump + 一条读档校验。**不需要任何新机制**，首批不做。
  - **首批只做单灵根**：五个角色 `Affinities` 各为 `[Metal]` / `[Wood]` / `[Water]` / `[Fire]` / `[Earth]`，长度恒为 1。**「长度恰为 1」是内容编排口径，不是字段约束**——字段本身即为数组，日后引入多灵根角色零结构变更。
  - **无契合度设定、无相生相克、没有「天灵根」品级说法。** 五行之间**没有任何规则关系**，关系只存在于「角色灵根 ⊇ 功法要求」这一条包含判定上。品级标签隐含「单灵根最强」，而机制上它只是「池更窄但有专属功法」，标签会制造预期落差。相生相克的位置留着，日后要开是纯加法。
  - **追加成员（雷 / 冰 / 风一类）的成本为零**：`Affinity` 不落存档、不进上行负载 ⇒ 加成员**不 bump `schemaVersion`、无迁移、后端零影响**。今天的不做不构成明天的债。
  - **规则后果只有一处：功法的硬性修习准入**（判定式、单点纯函数、四个取池点的接入位置、`MaxTier` 一律不折减，全部见 `deck/_index.md`「灵根修习准入」）。**灵根此外一格不碰**：不影响 `mana` / `manaLimit` · 道念的产出与削减 · 寿元与 `lifeSpanCost` · 商店价格 · 隐藏属性 · 经验值 · `baseMomentum` · 敌人赋级 · 任何卡牌数值 · 任何战斗内规则。逐条理由：战斗侧那一批根本看不见功法；其余每一项都已有指定的唯一旋钮，往上叠第二个输入正是本库反复否决的「第二条强度曲线」。
  - **风味标注走描述文本**（`LocalizedText`），不另开字段。
- **`CharacterData` 的加载期校验（十一条，全部带定位上下文）。** 判据 = 「坏数据必须在启动期大声失败」。

  | # | 违规 | 处置 |
  |---|---|---|
  | 1 | `AllEnabled<CharacterData>()` 条数 `== 0`（池为空） | `PushError` + 抛 —— 无角色可选 ⇒ 开不了任何轮回，是最硬的一条 |
  | 2 | 绑定的 `PowerId` / 两个 `TechniqueId` 解析不到 | `PushError` + 抛，带 `characterId` 与悬空 `Id` |
  | 3 | 绑定的神通 / 功法 `ContentEnabled == false` | `PushWarning` + **该角色退出可选池**（overlay 秒关一门坏功法是既定运营手段，不该让引用它的角色把整个启动打崩；但一个残缺角色不能被选出去） |
  | 4 | 绑定的 `PowerData.Scope != Character` | `PushError` + 抛 —— 角色自带的是**神通**不是法则，两层不得串写 |
  | 5 | `Id` 不符合 `character.<snake_case_slug>` 形态 | `PushError` + 抛 |
  | 6 | `CharacterData.Affinities` 为空 / 含 `Unspecified` / 含重复 | `PushError` + 抛，带 `characterId` |
  | 7 | `CultivationTechniqueData.RequiredAffinities` 含 `Unspecified` / 含重复 | `PushError` + 抛，带功法 `Id` 与 `.tres` 路径。**空数组合法**（= 无属性要求的通用功法） |
  | 8 | `MaxCharacterAffinityCount < 0` | `PushError` + 抛，带功法 `Id` |
  | 9 | `MaxCharacterAffinityCount > 0` 且 `< RequiredAffinities.Length` | `PushError` + 抛，带功法 `Id` 与两个值 —— 要求的属性数已超过允许的灵根总数，该条目对任何角色都不可修 |
  | 10 | 某个在册角色的可修功法条目数（`Pool != Enemy` 且通过准入）低于取池余量阈值 | `PushError` + 抛，带 `characterId` 与实际条数 —— **该角色开不出局** |
  | 11 | 某个在册 `Affinity` 成员没有任何 `Pool != Enemy` 的功法条目 | `PushWarning`，带成员名（该属性尚无内容；若无角色持有它则不阻断） |

  - **校验 10 与 `ADR-0073` 的候选短缺三段处置是两回事**：那条处理的是运行中池被抽空，这条处理的是**内容层面根本就没铺够**。它是运行期硬阻断的唯一落点；内容编排期的提前发现由 `/audit-content` 的对账项承担。
  - **校验 6–9 落在功法与角色两个类型上，但它们成对成立**，故一并登记于此；功法侧两格的字段面权威在 `deck/_index.md`。
- **CharacterProfile 的完整字段表。** 本表**只有形态列**（字段 / 类型 / 写入通道 / 权威）——字段的语义、取值域与读档校验一律留在权威列所指的文档里，本表只做索引与回链。**写入通道** = 该字段经 `ProfileChangeSpec` 的哪一列写入；`—` = 不经 spec，由 life-cycle-service 在轮回创建 / 篇章边界 / 结算收口时直接赋值。

  | # | 字段 | 类型 | 写入通道 | 权威 |
  |---|---|---|---|---|
  | 1 | `id` | `string` | — | 本文档「五格新字段」 |
  | 2 | `characterDataId` | `string` | — | 本文档「五格新字段」 |
  | 3 | `status` | `CycleStatus` | — | `decisions/ADR-0004-realm-checkpoint-retry-model.md` |
  | 4 | `defeatReason` | `DefeatReason?` | — | 本文档「五格新字段」 |
  | 5 | `chapter` | `int`（1–3） | — | `decisions/ADR-0004-realm-checkpoint-retry-model.md` |
  | 6 | `realm` | `Realm` | — | `systems/game-progression.md` |
  | 7 | `level` | `int`（境界内层号） | — | `systems/game-progression.md` |
  | 8 | `Status` | `CharacterStatus`（具名子类） | 见下方子表 | 见下方子表 |
  | 9 | `spiritStone` | `int` | `Elements`（`CostKey.SpiritStone`） | `currency.md` |
  | 10 | `immortalJade` | `int` | `Elements`（`CostKey.ImmortalJade`） | `currency.md` |
  | 11 | `technique` | `IReadOnlyList<TechniqueEntry>` | `DeckElements` | `deck/_index.md` |
  | 12 | `looseCard` | `IReadOnlyList<string>` | `DeckElements` | `deck/_index.md` |
  | 13 | `magicPack` | `IReadOnlyList<CharacterItem>` | `AbilityElements`（持有）+ `ItemElements`（次数） | `item/common-properties.md` |
  | 14 | `characterPower` | `IReadOnlyList<CharacterPower>` | `AbilityElements` | `power/common-properties.md` |
  | 15 | `disabledAbility` | `IReadOnlyList<DisabledAbilityEntry>` | `AbilityElements`（`Disable`） | 本文档 |
  | 16 | `pastEvent` | `IReadOnlyList<PastEventEntry>` | `TraceElements` | `systems/adventure-event/common-properties.md` |
  | 17 | `pastItemUse` | `IReadOnlyList<ItemUseEntry>` | `ItemUseElements` | 本文档「战斗外道具使用的痕迹序列」 |
  | 18 | `plotKeyPoint` | `IReadOnlyList<PlotKeyPoint>` | `PlotElements` | `systems/services/plot-manager.md` |
  | 19 | `activeCombat` | `ActiveCombat?` | `EventStateChanges` | `systems/services/combat-service.md` |
  | 20 | `eventOption` | `EventOptionSave?` | `EventStateChanges` | 本文档「两个事件态字段」 |
  | 21 | `activeEvent` | `ActiveEventState?` | `EventStateChanges` | 本文档「两个事件态字段」 |
  | 22 | `chapterRetry` | `ChapterRetry`（具名子类 · 三字段） | —（`RetryChapter`） | 本文档 |
  | 23 | `rng` | `RngState`（具名子类） | `RngElements`（`CycleSeed` 与子流初始化为 `—`） | `systems/common-properties.md` |
  | 24 | `startContentVersion` | `int` | — | `systems/services/content-service.md` |
  | 25 | `lastContentVersion` | `int` | — | `systems/services/content-service.md` |

  **`CharacterProfile.Status`（具名子类 · 数值型运行状态）**

  | 字段 | 类型 | 写入通道 | 取值域权威 |
  |---|---|---|---|
  | `manaLimit` | `int` | `Elements`（`CostKey.ManaLimit`） | `ResourceElements` |
  | `experiencePoint` | `int` | `Elements`（`CostKey.ExperiencePoint`） | `ResourceElements` |
  | `faith` | `int` | `Elements`（`CostKey.Faith`） | `ResourceElements` |
  | `bloodlust` | `int` | `Elements`（`CostKey.Bloodlust`） | `ResourceElements` |
  | `lifeSpan` | `int` | `Elements`（`CostKey.LifeSpan`） | `ResourceElements` |
  | `FaithBand` | `sbyte` | `StatusChanges` | `StatusFields` |
  | `BloodlustBand` | `sbyte` | `StatusChanges` | `StatusFields` |
  | `CurrentLocationId` | `string` | `StatusChanges` | `StatusFields` |
  | `LocationEventCount` | `int` | `StatusChanges` | `StatusFields` |

  - **`Status` 装数值型运行状态**；集合型 build 状态（deck / 神通 / 储物袋 / 禁用表 / 剧本锚点）与 `Status` **平级**，不落其内。
  - **`currentMana` 不在 `Status` 内。** 它每回合恢复到 `manaLimit`、回合内不结转，寿命短于一次事件 ⇒ 按「重算得出来的不存」它是战斗内运行态，落 `activeCombat`（见 `systems/services/combat-service.md`）。`Status` 只留 `manaLimit`。
  - **两种轮回货币 `spiritStone` / `immortalJade` 都落顶层、相邻、不落 `Status` 内。** `Status` 装的是**数值型运行状态**，而货币与它平级（同 deck、神通持有列表一档）。两者形态完全同构（`int`，写入通道 `Elements`），差别只在语义，见 `currency.md`。JSON 侧字段名 `spiritStone` / `immortalJade`（camelCase，见 `systems/services/sync-service.md`）。两格属 `schemaVersion` 1，登记见 `systems/services/profile-schema-versions.md`；老档缺字段 → `0`。
  - 两张表的行随字段增长，维护成本明写；它们是索引 + 回链形态，与 `_index.md` 的既有职责一致。`ResourceElements` / `StatusFields` 两张封闭表的逐行取值见 `systems/services/profile-service.md`，枚举声明见 `systems/architecture.md`「共享核心类型」。
- **五格新字段的形态。**

  ```csharp
  string          Id;                // 轮回创建时由客户端生成的 GUID（"N" 格式，32 位小写十六进制无连字符）
  string          CharacterDataId;   // 指向 CharacterData.Id；轮回创建时写一次，此后不变
  DefeatReason?   DefeatReason;      // null ⟺ status != Defeated
  IReadOnlyList<TechniqueEntry> Technique;   // 卡组的 build 层：功法 + 层数
  IReadOnlyList<string>         LooseCard;   // 游离散牌，多重集：同一 CardData.Id 可出现多次

  public readonly record struct TechniqueEntry(
      string TechniqueId,   // 指向功法内容条目的稳定 Id
      int    Tier);         // 当前层数，>= 1
  ```

  - **`id` 由客户端生成、不向后端申请。** `CharacterProfileDiff` 的键值以下对后端完全不透明，后端从不解析它；向后端申请一个 id 会在轮回开始处插入一次网络往返，而轮回开始是**自动存档点而非阻塞点**。**不用「第 N 个角色」的序号**（要一个账号级计数器 + 一条幂等问题，而角色只增不删却可能并行创建于多篇章，GUID 零协调）；**不用 `characterDataId` 作键**（同一模板可在不同篇章各有一个 ongoing 角色）。它是 diff 的寻址键与全部日志 / 读档校验的定位上下文。
  - **`characterDataId` 是「同一个角色每一局手感相同」的存档载体**，也是 `PlotNodeData.CharacterIds` 比对的那一格。读档校验：解析不到 → **必需缺失** → `PushError` 带 `characterId` + `characterDataId`（角色模板是结构性内容，解析不到即坏档，不能像 `pastEvent` 那样降级）。
  - **`defeatReason` 不设 `None` 哨兵。** `DefeatReason` 是三值封闭枚举（`Discarded` / `LifeSpanExhausted` / `FinaleFailed`），加一个不该出现的成员会让每个消费点都要处理一个多余分支；可空是 C# 表达「这一维只在某状态下有意义」的既有形态。读档校验：`status == Defeated` 且为 null → **可选缺失** → `PushWarning`（履历少一行，不阻断）；`status != Defeated` 且非 null → 不可能态 → `PushWarning` + 按 null 处理。消费方是元进程界面的角色履历与轮回结束屏。
  - **`TechniqueEntry` 取 `readonly record struct`**（字段少、条目个位数、要落存档且进 diff），与 `StatusAssignment` / `DeckChangeElement` 同款；`PastEventEntry` 与 `EventOption` 字段多，才取引用型。
  - **`looseCard` 是裸 `string` 多重集而非 record 列表**：散牌没有任何随实例变化的状态（`CardInstance` 的运行态只存在于战斗内、随 `activeCombat` 走），一个 `Id` 就是全部信息。
  - 读档校验：`TechniqueId` / `looseCard` 元素解析不到 → **必需缺失** → `PushError`（与 `DeckChangeElement.Id` 的施加侧同口径——悬空 `Id` 写进 Profile 即污染存档）；`Tier < 1` → `PushError`。
- **`realm` + `level` 是角色的修行位置。** 二者合成**全局等级序**上的位置，是敌人赋级 `±2` 带与 `baseMomentum` 起跑线的判据；篇章突破后 `level` 归位为新境界的初期。**`manaLimit` 的常规成长由事件 cost / reward 推拉，另在每次大境界提升时 `+1`**（增量，走 `CostKey.ManaLimit`；见 `mana.md`）。
- **决策点存档。** 事件推进过程中（含战斗内）在**决策点**落存档，使退出重进恢复到同一局面与同一份 RNG 状态；`selectCost` **不回滚**。存档点清单见 `systems/services/life-cycle-service.md`；**战斗内的 D0–D7 决策点清单见 `systems/services/combat-service.md`**。
- **`activeCombat`：进行中战斗的中间态（CharacterProfile 上的可空块）。** 战斗开始时创建、`eventEnd` 收口时**置空**；**不进 `pastEvent`**（历史事件只留定稿快照），也**不自带随机流状态**（战斗内随机的 `State` / `DrawCount` 落 `rng.stream[Combat]`）——它是**事件内的中间态，寿命短于一次事件**。
  - **写入通道 = `EventStateChanges`（`Key == ActiveCombat`），与 `activeEvent` 同一列**：combat-service 在每个决策点整块置值，收口时置空。两个中间态字段仍不合并，共用的只是通道。
  - **为什么挂 CharacterProfile 而非独立的战斗存档实体**：与「每篇章至多一个 ongoing」自洽，且 diff 天然落在 `CharacterProfile` 粒度（sync-service 的既定 diff 单位），**无需新增同步单元**。
  - 内容 = 遭遇参数 + 回合 / 步状态 + 两个参战方（含三区 `Id` 序列与 `CardInstance` 运行态）+ 战场条目 + 栈条目 + 挂起态。**完整 schema 与读档校验归 `systems/services/combat-service.md`**（本文件只登记它是 CharacterProfile 的一个字段）。
  - 本字段属 `schemaVersion` 1，登记见 `systems/services/profile-schema-versions.md`。
- **两个事件态字段：`eventOption`（当前批）与 `activeEvent`（正在结算的那一项）。** 前者是**当前批 eventOptions 的定稿快照**，后者是**结算期间的权威副本**，两者与 `pastEvent` / `activeCombat` / `disabledAbility` / `plotKeyPoint` 平级。

  ```csharp
  EventOptionSave?  eventOption;   // null = 尚无批次（StartCycle 之前 / 老档迁移）
  ActiveEventState? activeEvent;   // null = 当前没有事件在结算

  public sealed record EventOptionSave(
      string                     BatchId,
      IReadOnlyList<EventOption> Option,             // 本批定稿实例，1–5 项
      int                        EffectivePriority); // 0 或 1；产出侧算好，呈现层不自算

  public sealed record ActiveEventState(
      string      EventInstanceId,   // 被结算项的 InstanceId
      EventOption Option);           // 派生后的定稿实例
  ```

  - **`activeEvent != null` 时，本次结算涉及的 `EventOption` 一律读 `activeEvent.Option`**；批中的原实例只用于呈现尚未开始的那些选项与组装 `Unchosen` 轻摘要。**当前批里那份原实例一字不动**——两处派生（Explore 揭示 · Exchange 刷新）都是对 `activeEvent.Option` 的整体置值。派生形态见 `systems/adventure-event/explore/_index.md` 与 `exchange/_index.md`。
  - **另立承载而非原地替换当批实例。** 三条理由：「当前批里那份原实例不动」是既定明文；批的持有者 future-event-service 是无记忆的纯产出侧，原地替换等于给它加一个运行时写入面；**「有事件在结算」这个态必须能一次判空得知**，藏进批里就得遍历才知道，而可空块已是 `activeCombat` 立下的形状。**只存派生增量的散字段**同样否决——每新增一个可派生字段就要加一个散字段，而存整份快照对字段增删完全中立。
  - **两者可空、不设哨兵。** 「写一个空 `Option` 的批」要造一个语义上不存在的 `BatchId` 且 `EffectivePriority` 无意义；「迁移期直接重算一批」要在迁移里跑物化（读内容注册表、掷 map 子流），与「迁移只做结构搬运」相抵。
  - **`activeEvent` 与 `activeCombat` 并存、不合并**：前者是**事件级**中间态（哪一项在结算、它派生成什么样），后者是**战斗状态机**的中间态。把后者塞进前者是一次纯重构，牵动 `combat-service.md` 的整段 schema、收益为零。
  - **生命周期。** `eventOption` —— `StartCycle` 写第一批，此后每次 `RefreshAfterEvent` **整块替换**（新一批的写入并入 `eventEnd` 那一次 `TryApply`）。`activeEvent` —— 与 `TryApply(SelectCost)` **同一次**创建（值 = 当批那一项的原样拷贝），`eventEnd` 收口置空，与 `activeCombat` 同一处清空；**终态判定 ① 判负而短路的那一路，由失败流程一并清理它**。
  - **读档校验**（前六条 **必需缺失** → `PushError` 带 `characterId` + `instanceId`；末条可降级）：

    | # | 检查 | 时机 |
    |---|---|---|
    | 1 | `activeEvent.EventInstanceId` 能在 `eventOption.Option` 中按 `InstanceId` 找到 | 读档 |
    | 2 | `activeEvent.Option.InstanceId == EventInstanceId`，且 `EventId` 与批中原实例一致 | 读档 |
    | 3 | `activeEvent.Option.RerolledCount >= 批中原实例.RerolledCount`（单调不减是刷新价递增的前提） | 读档 |
    | 4 | `IsRevealed` 只允许 `false → true`（回落 = 重新遮罩，等于开一次重掷） | 运行时断言 |
    | 5 | `RerolledCount` 增加 ⇒ **`ExchangeStock`** 整批替换（不允许只涨计数不换库存，或反之）。**本条只约束 `ExchangeStock`**——`BarterStock` 是定值编排、不参与刷新，刷新前后必须逐条不变 | 运行时断言 |
    | 6 | `activeCombat != null ⇒ activeCombat.eventInstanceId == activeEvent.EventInstanceId` | 读档（拒绝恢复该战斗，与 `combat-service.md` 既有第 ① 条同档同处置） |
    | 7 | `RerolledCount <= MaxRerollCount` | 读档 + 运行时 → `PushWarning` + 钳到上界（内容侧数值可被 overlay 调低，属可降级） |

  - **Exchange 的物化字段有三格：`ExchangeStock` · `BarterStock` · `RerolledCount`。** `BarterStock : BarterOffer[]` 承载以物易物的定稿 offer（由 `ExchangeSpec.BarterRules` 逐条平移，不经取池、不掷 `Shop` 子流），形态与校验见 `systems/adventure-event/exchange/common-properties.md`；三格属 `schemaVersion` 1，登记见 `systems/services/profile-schema-versions.md`。
  - **恢复即读结果、绝不重走取池链。** 恢复路径读 `activeEvent.Option` 的 `ExchangeStock` / `BarterStock` / `IsRevealed` 直接呈现，不重新抽取——与「奖励候选预先算定、恢复时读结果不重抽」是同一条纪律的又一个实例。`activeEvent == null` 时直接呈现 `eventOption` 的横滑选择区。
  - **痕迹侧零字段增量**：`PastEventEntry` 的定稿实例快照取自 `activeEvent.Option`，而 `ExchangeStock` / `BarterStock` / `RerolledCount` 收口后永无消费方 ⇒ 按「重算不出来**且有消费方**」的完整口径不进痕迹，与 `plotKeyPoint`「不记已走分支路径」同款处置。
  - 两个字段属 `schemaVersion` 1，登记见 `systems/services/profile-schema-versions.md`；老档缺字段 → `null`，按「无进行中批次」处置，下一次 `RefreshAfterEvent` 重算一批。
- **`pastEvent`：修行历程 = `IReadOnlyList<PastEventEntry>`。** 元素**不是 `Resource`**——存的是**定稿实例快照 + 本次结算的最终账**，这是物化模型的直接推论（`AdventureEventData` 是 ContentRegistry 的共享只读单例，痕迹要记的是「这一次走过的那个实例」）。
  - **条目形态 `PastEventEntry`（13 字段）、判据「重算不出来的存」、未选项轻摘要 `UnchosenOptionRef`、`EventOutcome` 四值枚举与加载时校验，权威在 `systems/adventure-event/common-properties.md`**（本文件只登记它是 CharacterProfile 的一个字段）。
  - **只追加、不修改既有条目**（不变式）；体积护栏与 diff 友好性见 `systems/services/sync-service.md`。
  - **写入经 life-cycle-service 组装 → `profile-service.ProfileManager` 的 `TraceElements` 列**，与「档案写入的唯一入口」一致，且与收口的其余各列落在同一次事务里。**`Seq` 首条为 `0`**，追加时的连续性由入口校验。
  - 本字段属 `schemaVersion` 1，登记见 `systems/services/profile-schema-versions.md`。
- **`pastItemUse`：战斗外道具使用的痕迹序列 = `IReadOnlyList<ItemUseEntry>`**（与 `pastEvent` 平级的第二条只追加序列）。它承接的是**发生在事件之外的那些使用**：那一刻没有 `PastEventEntry` 可挂，而这一笔重算不出来、又有消费方（元进程的角色履历寿元曲线，以及「这段回升是哪来的」这类诊断）⇒ 按「重算不出来且有消费方的存」它必须落存档。

  ```csharp
  IReadOnlyList<ItemUseEntry> pastItemUse;   // 单数命名，沿用 pastEvent 的既有风格

  public sealed record ItemUseEntry(
      int               Seq,             // 角色内单调递增，首条为 0；与 pastEvent 的 Seq 是两条独立序列
      int               AfterEventSeq,   // 使用时刻已完成的最后一条 PastEventEntry.Seq；首个事件之前 = -1
      string            ItemId,          // 溯源模板（disabled 条目照常解析）
      AbilityScope      Scope,           // Character（法宝）/ Player（古宝）—— 同一入口两层持有物，须区分
      ProfileChangeSpec AppliedChange);  // 这一次使用的账：就是那一次 TryApply 的入参
  ```

  - **五个字段，不带任何派生量。** 判据是「重算不出来且有消费方的存」，而使用后的剩余寿元与剩余次数**两者都重算得出来**（前者见下方读取算法，后者由 `AppliedChange` 里的次数增量与内容条目的 `Charges` 得出）。`PastEventEntry.LifeSpanAfter` 是该判据的**明示例外**，其成立前提是「4 字节换掉一次全序列重放」——本序列不需要全序列重放（见下），成本论证在此不成立；剩余次数的消费方则是诊断日志，由 `ProfileManager` 的可追溯性日志行承担，日志态的问题不上存档。
  - **寿元曲线的读取算法（消费侧，无额外遍历）。** 曲线 = `pastEvent[]` 与 `pastItemUse[]` 按 `(AfterEventSeq, Seq)` 归并的一趟遍历；`pastItemUse` 各条的寿元值 = **最近一条在它之前的 `pastEvent.LifeSpanAfter`（锚点）+ 该锚点之后各条 `pastItemUse.AppliedChange` 里 `LifeSpan` element 的累加**。归并本就要走这一趟，累加是同一次 `O(n)` 内的加法；锚点与当前条之间的跨度以个位数条计。序列尾部（最后一次使用之后尚无事件）取 `Status.lifeSpan` 当前值收尾。**回升段自此可解释。**
  - **与 `pastEvent` 分列两条序列，不合并为单一时序序列。** 合并要把 `pastEvent` 的元素类型改成二成员 sum type，`TraceElements` 的载荷同变，而它的两条入口校验（一次事件恰一条 · `AppliedChange` 恒不含本列）与「载荷直接是 `PastEventEntry`」都绑在载荷类型上，合并后全部退化为按载荷类型分支；`pastEvent`「修行历程」这一已成文的字段语义也会被扩宽。**代价明写：** 读取侧多一次归并，即上面那趟 `O(n)`。
  - **账号级古宝的使用痕迹同样落在角色档**（由 `Scope = Player` 标识）。这条痕迹的消费方是**这个角色这段轮回的曲线**，落账号级反而要为它另造一个消费面。**代价明写：** 轮回清理时它随之消失，古宝的跨轮回使用史不留存；需要时的落点是 `PlayerStatistics` 的聚合项，**首批不加**（与「首批一格计数字段都不加」同款）。
  - **战斗内使用不写本序列。** 那一次在事件之内，账已由该事件的 `AppliedChange` 承载；组装判据是 `activeEvent == null`，见 `systems/services/profile-service.md`。
  - **只追加、不修改既有条目**（不变式），`Seq` 首条为 `0`，追加时的连续性由入口校验（见 `systems/services/profile-service.md`）。
  - **不设条数硬上限。** 条数由 `Charges` 与内容编排（出现频率 / 库存深度 / 定价）天然封顶，与「回寿总量护栏落在内容编排面、规则层不设持有上限」同一条纪律；体积由 `CharacterProfile` 级的既有护栏（`pastEvent` > 500 条 / 序列化 > 512 KB）覆盖，本字段挂同一聚合、同一 diff 粒度，**不新增同步单元**。无界的唯一来源已被 `ItemData` 的一条加载期校验关掉（`Charges == -1` 且 `UsableScene` 含 `OutOfCombat` → `PushError`，见 `item/_index.md`）。
  - **读档校验：** `ItemId` 经 `ContentRegistry` 解析不到 → **可选缺失** → `PushWarning` + 该条降级为「仅标识可读」、**不阻断读档**（与 `PastEventEntry.EventId` 同款——历程是历史记录）；`Seq` 不连续 / 重复 → **必需缺失** → `PushError` 带 `characterId` + `seq`；`AfterEventSeq` 大于 `pastEvent` 末条 `Seq` 或 `< -1` → **必需缺失** → `PushError` 带 `characterId` + `seq`（越界坐标锚不到任何一条痕迹，曲线画不出来）。
  - **存档形状：** `pastItemUse : ItemUseEntry[]`（JSON 侧 camelCase）。本字段属 `schemaVersion` 1，登记见 `systems/services/profile-schema-versions.md`；老档缺字段 → 空列表。
- **`chapterRetry`：篇章重试计数器。** 一个**类**，计数第一 / 第二 / 第三篇章各自的重试次数——**因为 ch2 与 ch3 有重试上限**（无限 / 3 / 1，持 premium bundle 为 无限 / 9 / 3，见 ADR-0004）。**它是计数器容器，不是上限持有者**：上限仍按 ADR-0004 的既定纪律读取（可被账号级持有状态改写、凡读取处不得硬编码常量），`chapterRetry` 只答「用掉了几次」。**推论：篇章解锁 / 重新锁定与「剩余重试次数展示」有了确定的数据源。**
  - **形态 = 三个具名字段 `Ch1RetryUsed` / `Ch2RetryUsed` / `Ch3RetryUsed`**，第一 / 第二 / 第三篇章各一，**不是字典也不是按索引的数组**。**`Used` 后缀**避开两个已被占用的词缀——`Ordinal` 表达「第几次」这个位置且要当幂等键用，`Count` 属统计计数层，而 `chapterRetry` 是规则字段层的一个数量（命名硬约定见 `systems/player-profile/_index.md`）。**与「四境三篇章」这条硬事实对齐**（篇章数是游戏结构，不是可扩展列表）：具名字段让存档 schema 显式、读取处不必处理「键不存在」的分支，也免去按索引访问的越界校验。**代价是新增篇章需改 schema——但篇章数不是设计变量。**
  - **通关后保留计数，不清零** ⇒ **它是历史，不只是配额**。一个通关角色身上留着「我在筑基段挣扎了 3 次」的记录，可供元进程界面的角色履历展示；**同时它简化实现**——没有清零时机就没有「何时清零」的边界情形。
  - **ch1 的角色级计数恒为 0，这不是缺陷。** ch1 重试 = 重新走一次角色选择、创建一个新的 `CharacterProfile`，故角色级 ch1 计数对每个新角色恒为 0。**「你在炼气段重开了多少次」目前没有字段回答**——账号级统计的首批只有 `TotalCyclesCompleted` / `TotalCyclesDefeated`，后者不区分篇章（见 `systems/player-profile/_index.md`）。这是一个**展示需求**，需要时在 `PlayerStatistics` 上纯加法补一项即可（统计层新增字段零迁移、零后端配合）。**两层口径不同，不是同一个数的两份拷贝**：角色级参与闸门判定，账号级只被读来看。
  - **连带：`attemptIndex` 派生层整层删除**（篇章重试 = 换一套随机流，见 `systems/common-properties.md`）。
- **`disabledAbility`：本轮回禁用表**（与 `pastEvent` / `chapterRetry` / `activeCombat` 平级）。**法则不被强制剥夺，其余一律降级为本轮回禁用**——本字段是这条语义的承载面，覆盖**四类**能力条目（神通 / 法则 / 法宝 / 古宝）。
  - **不落 `Status` 内。** `Status` 装的是**数值型运行状态**（`lifeSpan` / `manaLimit` / `experiencePoint` / 隐藏属性），禁用表是**集合型 build 状态**，与 deck、神通持有列表同层。

    ```csharp
    IReadOnlyList<DisabledAbilityEntry> disabledAbility;   // 单数命名，沿用 pastEvent 的既有风格

    public sealed record DisabledAbilityEntry(
        AbilityCarrierKind Kind,             // Power | Item —— 两个 Id 空间不同，必须显式区分
        AbilityScope    Scope,            // Character | Player —— 决定它抑制哪一层的持有列表
        string          AbilityId,        // PowerData / ItemData 的稳定 Id
        DisableDuration Duration,         // NextEvent | ThisChapter | ThisCycle
        int             AppliedAtSeq,     // 施加时的 pastEvent 时序坐标
        int             AppliedAtChapter, // 施加时的篇章
        string          SourceInstanceId  // 施加它的事件实例，供履历展示与诊断
    );
    ```
  - **存「施加时坐标 + 时长」，不存「到期坐标」。** 施加坐标是**重算不出来的原始事实**，到期判定是它的纯函数；篇章边界的 `Seq` 在施加当时还不知道，存到期坐标要么存不出来、要么要事后回写（回写破坏只追加的便利）。判据同「重算不出来的存」。
  - **三档时长与到期剔除**（`life-cycle-service` 在两个时点各跑一次纯函数式剔除，见该文件）：`NextEvent`（施加之后进入的**下一个** AdventureEvent 全程，`currentSeq >= AppliedAtSeq + 1` 时于 `eventEnd` 收口后剔除）· `ThisChapter`（`currentChapter > AppliedAtChapter` 时于篇章边界剔除）· `ThisCycle`（无需剔除，随 `CharacterProfile` 整体拆解）。
  - **去重键 = `(CarrierKind, Scope, AbilityId)`；重复禁用不叠加，取时长较长的一条**（长短序 `NextEvent < ThisChapter < ThisCycle`）。叠加会造出「禁用三次到底禁到什么时候」这种无谓语义。
  - **禁用不影响持有，也不影响 `Charges`**；同 `Id` 多份的道具按 `Id` 整体禁用（储物袋本就按 `Id` 堆叠）。**禁用表条目不因失去持有而自动移除**——生效面按「持有 ∩ 未禁用」求交，空指向条目是无害的幂等残留。
  - **读档校验：** `AbilityId` 经 `ContentRegistry` 解析不到 → **可选缺失** → `PushWarning` + 保留条目、不阻断读档（与 `pastEvent` 同类处置）；`Duration` 越界 / 缺失 → **必需缺失** → `PushError` 带 `characterId` + `abilityId`；`AppliedAtChapter` 大于当前 `chapter` → 不可能态 → `PushWarning` + 按已到期剔除；同键重复 → `PushWarning` + 合并为时长较长的一条。
  - **生效判据、可见性与施加通道归各自文档**：生效面（不入场 / 不进列表 / 不进聚合）见 `power/_index.md` 与 `item/_index.md`，施加的 element 形态见 `systems/services/profile-service.md`。
  - 本字段属 `schemaVersion` 1，登记见 `systems/services/profile-schema-versions.md`；老档缺字段 → 空列表。
- **`Status` 上的隐藏属性档位（两个字段）。** 隐藏属性的档位带**回滞**（进入阈值 / 退出阈值不同）⇒ **档位不再是当前值的纯函数，必须持久化**。

  ```csharp
  // 当前所处档（索引 HiddenStatBandData.BandIndex；0 = 常态，|值| 越大越远离常态）
  sbyte FaithBand;             // 带符号 —— 道心是唯一的双臂属性，取值 -2..+2
  sbyte BloodlustBand;         // 0..3
  ```

  - **两个 band 落成两个具名字段而非字典** —— 与 `chapterRetry` 的「篇章数是固定的游戏结构，不用字典 / 索引数组」同款判据：隐藏属性清单虽仍待答，但**增删属性本就要动 schema**，字典只换来一层查找与一处可空。
  - **写入并入 `eventEnd` 那一次 `TryApply`**（band 在组装 spec 时按「前值 + `AppliedChange`」算出**绝对值**，不是相对增量；载体是 `ProfileChangeSpec.StatusChanges` 的 `StatusAssignment`，`sbyte` 存档字段在 spec 内以 `int` 承载）⇒「一个事件的收口是一次事务、一个存档点」原样成立，**不新增存档点、不新增结算阶段**。
  - **不进 `PastEventEntry`**：band 设值已在 `AppliedChange` 内、可重放，按判据「重算得出来的不存」⇒ 快照不加字段。
  - 档位表本身、阈值 / 回滞 δ 与跨档叙事规则归 `systems/services/plot-manager.md`。
  - 两个字段属 `schemaVersion` 1，登记见 `systems/services/profile-schema-versions.md`。
- **`Status` 上的地域位置与地域配额（两个字段）。** 图本身不落存档（全局不变、启动加载一次），落存档的只有「人在哪」与「在这儿做了几件事」：

  | 字段 | 类型 | 语义 | 生命周期 |
  |---|---|---|---|
  | `CurrentLocationId` | `string` | 当前所在地域（`LocationData.Id`） | **跨篇章持久**，仅由 Travel 结算改写；篇章重试时随该篇章起始存档一并回滚 |
  | `LocationEventCount` | `int` | 当前地域已结算事件数（**不计 Travel**） | 非 Travel 事件结算 `+1`；Travel 结算归 `0` |

  - **两者的更新并入 `eventEnd` 那一次 `TryApply`**，不新增结算阶段、不新增存档点——与三个 band 字段同款处理。**载体是 `ProfileChangeSpec.StatusChanges` 的 `StatusAssignment`，语义为绝对置值**：`+1` 与「归 0」都由 life-cycle-service 先算成绝对值再提交，`ProfileManager` 不做加减。字段的值类型与取值域逐行查 `StatusFields` 表，见 `systems/services/profile-service.md`。
  - **`LocationEventCount` 归 0 恒成立，包括由 Explore 揭示而来的 Travel**：该 Explore 的 `+1` 随即被归 0 覆盖，因为计数的语义是「在这个地域做了几件事」，换了地域即作废。
  - **`CurrentLocationId` 跨篇章不清零**，因为「篇章继承 = 全部继承」+「三章共用同一张图」⇒ 下一篇章从上一篇章结束时所在的地域继续，不需要「起始地域」这个概念。
  - **读档校验：** `CurrentLocationId` 经 `ContentRegistry` 解析不到 → **必需缺失** → `PushError` 带 `characterId` + `locationId`（location 是恒启用的结构性内容，解析不到即坏档，不能像 `pastEvent` 那样降级）；`LocationEventCount < 0` → `PushWarning` + 钳到 0。
  - 字段语义、图的载体与加载期校验归 `systems/game-progression.md`。
  - 两个字段属 `schemaVersion` 1，登记见 `systems/services/profile-schema-versions.md`。
- **`plotKeyPoint`：AdventurePlot 的进度锚点 = 每条已激活 arc 一条**（与 `pastEvent` / `disabledAbility` 平级的集合型字段）。

  ```csharp
  IReadOnlyList<PlotKeyPoint> plotKeyPoint;   // 单数命名，沿用 pastEvent 的既有风格

  public sealed record PlotKeyPoint(
      string       ArcId,             // PlotArcData 的稳定 Id
      string       NodeId,            // 该 arc 当前所处节点（PlotNodeData 的 Id）
      PlotArcState State,             // 枚举声明见 systems/architecture.md「共享核心类型」
      int          EnteredAtChapter,  // 进入当前节点时的篇章
      int          EnteredAtSeq       // 进入当前节点时的 pastEvent 时序坐标
  );
  ```

  - **只有内容侧 `Id` 与两个整型坐标，没有任何 `InstanceId`** —— 内容条目不得隐式依赖存档的运行时标识空间；`EnteredAtSeq` 用 `pastEvent` 的 `Seq`，与 `DisabledAbilityEntry.AppliedAtSeq` 同款坐标。
  - **粒度由悬空降级规则反推**：每条记录自成一个可独立解析的单元，一条悬空只让**那一条剧本线**惰性化，其余 arc 照常调制、照常叙事。
  - **`Queued` 是排队中的 side arc**（触发时即写，出队时改 `Active`）：band 回落后「曾跨入触发档」这一事实重算不出来，按判据「重算不出来的存」它必须落存档。并发上限只数 `Active`。
  - **不记已走分支路径**：路径当前无消费方（调制 / 叙事 / 推进都只读当前节点），按判据的完整口径「重算不出来**且有消费方**」⇒ 不存。日后履历展示的落点是 `PastEventEntry`。
  - **写入并入 `eventEnd` 那一次 `TryApply`**（与三个 band 字段、两个 location 字段同款），不新增存档点、不新增结算阶段；一次结算每条 arc 至多前进一个节点。**载体 = `ProfileChangeSpec.PlotElements`，条目类型 `PlotKeyPointAssignment`**（本 record 的镜像，语义是按 `ArcId` 的整条 upsert）。
  - **读档校验**（悬空 → `PushWarning` + 该条惰性、保留条目；`State` 缺失 / 越界 → `PushError`）与推进规则归 `systems/services/plot-manager.md`。
  - 本字段属 `schemaVersion` 1，登记见 `systems/services/profile-schema-versions.md`；老档缺字段 → 空列表。
- **RNG 状态与内容版本落在 CharacterProfile 上。** 三组字段属 `schemaVersion` 1，登记见 `systems/services/profile-schema-versions.md`：

  | 字段 | 类型 | 语义 |
  |------|------|------|
  | `StartContentVersion` | `int` | 轮回开始时生效的内容版本，**写一次不再变** |
  | `LastContentVersion` | `int` | **每个自动存档点**更新为当时生效的版本；与上一字段不等 = 该轮回跨过内容更新（数值突变类反馈的第一判据） |
  | `Rng.CycleSeed` | `ulong` | 轮回开始时生成，不变 |
  | `Rng.Stream[]` | `Name` / `Seed` / `State` / `DrawCount`（`string` / `ulong` / `ulong` / `int`） | 具名子流状态；`State` 为恢复权威字段，`DrawCount` 为诊断与迁移保险 |

  **`State` / `DrawCount` 经 `ProfileChangeSpec.RngElements` 与消耗它们的那一次提交同批写入**（`CycleSeed` 与 `StartCycle` 的子流初始化不走本列），使「凡消耗了子流随机的提交，该子流状态必须在同一次原子写内更新」这条不变式由结构而非自律兑现；`Seed` 可由 `CycleSeed` 与子流名重算，不进 spec。施加与失败语义见 `systems/services/profile-service.md`。

  schema 形态（JSON 侧一律 camelCase，见 `systems/services/sync-service.md`「JSON 序列化命名策略」）：

  ```jsonc
  "rng": {
    "cycleSeed": 12345678901234567890,        // u64，轮回开始时生成，不变
    "stream": [
      { "name": "map",    "seed": 0, "state": 0, "drawCount": 0 },
      { "name": "combat", "seed": 0, "state": 0, "drawCount": 0 },
      { "name": "shop",   "seed": 0, "state": 0, "drawCount": 0 },
      { "name": "reward", "seed": 0, "state": 0, "drawCount": 0 }
    ]
  }
  ```

  派生规则与恢复语义见 `systems/common-properties.md`；双 `contentVersion` 的诊断用途见 `systems/services/content-service.md`。
- **角色状态是终态收敛的状态机。** `status` 收敛为 `ongoing | defeated | completed`（`defeated` 的三种原因：discarded / 寿元归 0 / 渡劫失败——前两种是资源触底，末一种是篇章闸门）；`defeated` 与 `completed` 数据都会在轮回结束时被清理。→ 见 `systems/services/life-cycle-service.md` 与 `decisions/ADR-0004-realm-checkpoint-retry-model.md`。

Source: `handoffs/2026-09-02-bound-technique-initial-tier.md` · `handoffs/2026-08-30-realm-progression-artwork-basis.md` · `handoffs/2026-08-30-exchange-barter-support.md` · `handoffs/2026-08-30-character-template-pool.md` · `handoffs/2026-08-30-affinity-and-technique-attributes.md` · `handoffs/2026-08-30-life-lifespan-merge.md` · `handoffs/2026-07-24-docs-restructure-class-model.md` · `handoffs/2026-07-25-lifespan-service-refactor-and-legacy-cleanup.md` · `handoffs/2026-07-27-content-gating-offline-resilience-and-rng-persistence.md` · `handoffs/2026-07-30b-combat-level-intent-and-decision-point-saves.md` · `handoffs/2026-08-06-ch1-band-widening-cross-realm-crush-and-chapter-retry.md` · `handoffs/2026-08-06b-asymmetric-ch1-band-consented-power-loss-and-chapter-retry-shape.md` · `handoffs/2026-08-06d-combat-open-questions-mass-closure.md` · `handoffs/2026-08-09c-past-event-trace-schema.md` · `handoffs/2026-08-10c-ability-disable-replacement-and-player-statistics.md` · `handoffs/2026-08-12d-hidden-stat-bands-and-crossing-narrative.md` · `handoffs/2026-08-12f-cultivation-technique-deck-building.md` · `handoffs/2026-08-16g-travel-mechanics-and-location-carrier.md` · `handoffs/2026-08-16i-plot-data-encoding.md` · `handoffs/2026-08-17-travel-destination-and-status-change-elements.md` · `handoffs/2026-08-17d-exchange-mechanics-and-transaction-discipline.md` · `handoffs/2026-08-17g-element-carrier-gaps.md` · `handoffs/2026-08-17h-profile-field-schema.md` · `handoffs/2026-08-17j-event-option-derived-persistence.md` · `handoffs/2026-08-19-profile-change-spec-gaps.md` · `handoffs/2026-08-22-finale-failure-is-death.md` · `handoffs/2026-08-22-mana-baseline-realm-jump.md`

## 子系统导航

| 子系统 | 文件 | 内容 |
|--------|------|------|
| 卡组 deck | `deck/_index.md`、`deck/common-properties.md` | 抽牌堆 / hand / 弃牌堆、seeded 洗牌、deck 变更；**功法（构筑单位，带层数、整组替换式升阶）**；卡牌 / CardData 定义（费用、目标、效果流水线、触发器）；起始卡组等内容设计。 |
| 法宝 item | `item/_index.md`、`item/common-properties.md` | **CharacterItem**：轮回级角色道具（含道具设计内容；细节待定）。 |
| 轮回货币 currency | `currency.md` | 轮回货币 **灵石 `spiritStone`（基础）/ 仙玉 `immortalJade`（高阶）** 的获取 / 消耗；两者不可兑换。 |
| 神通 power | `power/_index.md`、`power/common-properties.md` | **CharacterPower**：轮回级角色能力，**对标账号级 PlayerPower（法则）**（同一概念的两层，分界是生命周期）；随轮回清理，**可承载战斗内触发式效果**。 |
| 寿元 lifeSpan | `life-span.md` | **角色唯一的资源命线**：两个扣减来源（每个事件的 `lifeSpanCost` · 战斗失败按道念差 × `lossPerMomentum`），战斗过程中不被读写；**归 0 → defeated**；回复走 outcome 侧三通道；炼气起始 1000；单值、无上限。 |
| 法力 mana | `mana.md` | 每回合出牌资源；**每回合恢复至 `manaLimit`**，上限由事件推拉、另在每次大境界提升时 `+1`；炼气基线 5/5。 |

## 决策(-> ADR)
> _已定案的决定链接到 decisions/ADR-####。_

- **子系统结构。** `deck` / `item` / `power` 为**文件夹**——除规则外还要容纳**内容设计**（起始卡组 starter decks、道具设计 item designs、能力条目）；`life-span` / `currency` / `mana` 为**扁平 `.md`**——它们是系统性资源（systematic resource），预期规则足够短，暂以单文件承载。
- **境界存档 · 篇章重试模型**（CharacterProfile 状态机 `ongoing | defeated | completed`、全部继承、重试上限）→ `decisions/ADR-0004-realm-checkpoint-retry-model.md`（Accepted）。

## 待决问题
> _尚未解决，需要一次 handoff/决策。_

- **全池指定下角色强度差是否仍塌缩为单一最优。** 灵根把差异推向「能修哪一路功法」，但仍可能存在一个综合最优的属性池；ch1 无限重试放大该效应。待实测。→ 本文档。
- **隐藏属性完整清单是否还有第三项。** `Status` 上目前是道心 / 煞气两项；取值域、档位表与阈值见 `systems/services/plot-manager.md`。→ 见 `systems/services/plot-manager.md`。

## 对应
提炼至：`.claude/knowledge/systems/character-profile/_index.md`（待建）。
