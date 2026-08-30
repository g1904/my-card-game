# enemies（敌人）

> 敌人的内容定义与物化规则：`EnemyData`（模板）↔ `EnemyInstance`（物化定稿实例）、样本卡组、item / power 持有列表、作用域与池归属、赋级带的接受面。

**与 `adventure-event` 平级的一个系统。** `combatTier` 三档（Practice / Standard / Finale）**共同引用同一批敌人条目**（天劫也是 Enemy 的一种），把共用类型挂在其中一个使用者名下违反归属直觉。这**不违反「内容定义并入系统」**——本目录不是一个泛化的内容层（具体的敌人条目归 `../../content/enemy/`），而是承认 `Enemy` 已具备独立的「类」身份：它有模板 ↔ 实例二元、有自己的 `.tres` 注册表、有独立的图鉴引用面、有自己的赋级规则。并列的另两个二元中 `Card` 住在 `character-profile/deck/`、`AdventureEvent` 住在 `adventure-event/`，三者因此在归属上对称。

## 意图

### `EnemyData` —— 静态内容条目

- **`[GlobalClass] partial class EnemyData : Resource`**，稳定 `Id`，一个 `.tres` 一条，经 `ContentRegistry` 加载并按 `Id` 建索引；带共有字段 `ContentEnabled`。**抽取一律走 `AllEnabled()`，读取侧 `Get(id)` 不过滤。**
- 字段（当前已定的部分）：

  | 字段 | 语义 |
  |------|------|
  | `Id` | 稳定唯一键 |
  | 图鉴五项词条 | 人物背景 / 功法简介 / 运作方式 / 特点与弱点 / 关键卡牌；写作规格见 `systems/player-profile/codex/enemy-codex.md` |
  | `KeyCardIds : string[]` | **长度 2–3**，必须是样本卡组（展开产物 ∪ 散牌的并集）内的 `Id`。图鉴「关键卡牌」词条的数据源，**显式标注不自动挑选** |
  | 构筑面 | **功法引用列表 `TechniqueRef[]`（`TechniqueId` + `Tier`）+ 游离散牌 `CardData.Id` 列表**。样本卡组 = 功法展开产物 ∪ 散牌；**规模逐条编排、不设硬限**，允许同名条目重复。规模偏小的卡组会在后期触发疲劳（抽牌堆不重洗，空堆每抽一张 −1 道念），**这是「牌少而精」的内建对价**，也是一条可用的编排旋钮 |
  | `AiProfile : EnemyAiProfileData` | 挂模板的出牌策略（「这个敌人该怎么打」）。`[Export]` **直接类型引用**，**可空**，`null` = 走通用兜底；形态见下 |
  | item 持有列表 | 敌人没有储物袋，道具直接挂模板 |
  | power 持有列表 | 开局入场的受保护永久物；「不可被移除的场上特性」是 boss / 天劫最自然的表达 |
  | `EncounterScopes : CombatTier[]` | 可出现在哪些**遭遇档位**（`{ Practice, Standard, Finale }`，取值与 `EncounterSpec.Tier` 同一枚举）；**空数组 = 数据缺陷 → 加载期 `PushError`** |
  | `ChapterScope : int[]` | 可出现在哪几个篇章（取值 `1..3`，对位 `CharacterProfile.chapter`）；**空 = 不限（三章通用）**，与 `PlotArcData.ChapterScope` 同名同义 |
  | `PoolScope` | 类型 `PoolScope`（内嵌 `Resource`），**允许为 `null` = 通用池，不报错**。池归属：通用 / 某地点专属 / 某剧情线专属；形态与匹配语义见下 |
  | `Lines : EnemyLine[]` | 敌人台词，**稀疏数组**（只列要写的场合），默认空数组 = 无台词。文本走 `LocalizedText`，不是音频资产；形态见下 |
  | `Artwork : Texture2D` | **共有字段**（本层 = 敌人立绘），可空、默认 `null`。类型定义与校验语义见 `systems/common-properties.md`，本层投影见 `common-properties.md` |

- **敌人与玩家同源构筑。** 敌方卡组由**功法（`CultivationTechnique`）+ 层数**展开，敌我共用同一套 `CultivationTechniqueData` 与同一注册表；玩家在敌人身上观察到的功法强度，就是自己习得后能拿到的强度。战斗内照旧不感知功法——组装时展开为卡牌集合，与玩家侧同一条纪律（`systems/character-profile/deck/_index.md`）。收益：图鉴知识可验证且可迁移、「击败后习得其招」有天然载体、敌我共用一套功法条目使内容产能减半。**被接受的代价**：散牌不属任何功法，故「敌人卡组 = 玩家可习得内容」这一承诺留有一小块例外。
- **两段式（功法 + 散牌）而非纯功法列表**：与玩家侧的「卡组 = 功法展开的牌 ∪ 游离散牌」保持同构，并保住「卡组规模是一条疲劳编排旋钮」——纯功法列表会让规模只能按「功法数 × 每层卡数」整组增减。
- **`TechniqueRef` = 带两个具名字段的内嵌 `Resource`**（内嵌类型一律 `Resource` 派生，同 `PoolScope`）：`TechniqueId : string`（须存在于 `CultivationTechniqueData` 仓储）+ `Tier : int`（须落在 `[1, 该功法的 MaxTier]`；`MaxTier` 的定义在 `systems/character-profile/deck/_index.md`）。
- **敌方专用内容的表达面唯一**：`EnemyData` 引用的功法不得 `Pool == Character`；`Pool` 的枚举与卡池划分语义见 `systems/character-profile/deck/_index.md`「卡池划分」节。天劫这类条目的定制性由 `Pool == Enemy` 的敌方专用功法承担，**不为它开第二条构筑通道**——恒无对象的伸缩位只会让每个消费点都要处理一个永不发生的分支。
- **展开产物不写回条目。** `EnemyData` 是 ContentRegistry 里的共享只读单例；层数固定 ⇒ 展开在加载期即唯一确定，需要缓存就落在 ContentRegistry 侧的**派生索引**（加载期一次算出）。被引用的功法 `ContentEnabled == false` 时敌人**照常展开、不做连带过滤**（过滤只发生在产出侧，读取侧不过滤）；要秒关一个敌人就关它自己那条 `EnemyData`。
- **敌人等级不在模板上定死**——等级是 future-event-service 的**物化产物**，故同一个敌人可在不同篇章 / 情境下以不同等级出场。
- **敌人持有道念、行为，并持有自己的卡组**；**敌人侧的战斗内量与玩家侧对称**，也是道念，不设独立的血量池。
- **敌人的战斗强度以 `baseMomentum` 为主刻度**：等级 → 起始道念 → 开局领先量，这是越级压迫感的直接来源。**卡组保持强度中立，不叠第二条强度曲线**（否则 `±2` 带的数值安全性推导立刻失效）。
- **层数在 `EnemyData` 上逐条编排为固定值，随赋级只动 `baseMomentum`。** 同一个敌人不因赋级变强变弱，强度中立**在同一条目内**成立；「强敌 = 更高层数」成立于内容层而非物化层，`EnemyLevelRange` 与层数**不建立机械对应关系**。理由：层数是严格升级，按定义就是第二条强度曲线——让它随赋级浮动会使难度曲线失去可控性（同一条目在两次遭遇中强度不同，且强度差不体现在玩家唯一能读到的刻度上），而「无隐藏乘数、观察即所得」这个诉求不需要靠层数浮动来兑现。连带收益：层数固定 ⇒ 展开在加载期即唯一确定 ⇒ `KeyCardIds` 的加载期校验与图鉴的静态性一字不改。
- **条目之间的层数散布须有护栏（承重 · 本文件是它的权威）。** 层数固定只解决了同一条目内的浮动；条目**之间**的散布仍是一条与 `diff` 同量纲的旋钮——一档 `TechniqueTier` 差在标准 10 回合内累计 ≈ 一档 `diff` 的 `baseMomentum` 落差（追分锚点见 `systems/balance.md`），而赋级带只框住了起跑线那一维，对层数这一维**不给任何约束**。不设护栏就等于在唯一可见的难度刻度（等级）之外再开一条不可见的强度轴。故：**敌人功法层数按篇章给一个基准档**（对齐玩家在该阶段的典型层数），**逐条目偏离 ≤ ±1 档**。这是**内容编排口径**——「典型层数」随内容扩充而漂移，焊进加载期只会让每次内容调整都撞一次 `PushError`；核对落 **`/audit-content` 汇总（只报告不阻断）**，与「负向 `OnFailureRules` 占比」同款处理。
- **产出缩放与玩家同因**：敌人各等级的道念产出**不设敌方专属的隐藏数值乘区**，决定因素与玩家完全一致；同一门功法同一层数，敌我两侧展开出的是同一批卡牌条目。

### `EnemyInstance` —— 物化定稿实例

```csharp
public sealed record EnemyInstance(       // 物化定稿 · immutable · 随 EventOption 落存档
    string                InstanceId,     // 本次物化实例的稳定标识
    string                EnemyId,        // 溯源到模板：ContentRegistry.Get<EnemyData>(EnemyId)
    int                   Level,          // 物化赋级产物（全局序 1–22，落在角色 ±2 带内）
    IReadOnlyList<string> DeckCardIds,    // 展开后的卡组（Id 序列；闭集，无凭空生成的牌）
    IReadOnlyList<string> ItemIds,        // 本场可用道具
    IReadOnlyList<string> PowerIds);      // 开局入场的受保护永久物
```

- **性质对齐 `EventOption` 而非 `CardInstance`**：模板 ↔ 实例通则的三对里，`EventOption` 是定稿不可变、`CardInstance` 是运行态可变；敌人实例属前者——**物化产出即冻结、落存档、下游只读消费**。
- **战斗内的敌人运行态**（道念、手牌、卡组状态、已用道具、`Power` 计数器）由 **EnemyManager 持有**，不进 `EnemyInstance`，也不另立类型。
- **嵌在 `EventOption` 上随批次落存档**（承载格 = `EventOption.Encounter` 内的 `EncounterSpec.Enemy`），不在战斗开始时二次展开。三条依据任一条单独成立即封死另一选项：**① 唯一物化点**（战斗开始时展开 = 在 combat-service 里开第二个物化点）· **② 选择界面就要显示敌人等级**（等级是物化产物，`EventOption` 卡片上的越阶提示与风险评估都发生在战斗之前）· **③ 嵌套使敌人实例在同一份定稿实例内只有一个落点**——平铺一份 `EnemyInstance` 而 `EncounterSpec` 也持一份，会让同一个敌人有两条读取路径且无任何机制保证二者相等；跨落点的副本（结算期的 `activeEvent` 快照）由既定的快照语义统一管辖，权威只有一处。
- **敌人实例存展开层，不存 build 层**（不学玩家侧的「存功法 `Id` + 层数」）：`EnemyInstance` 是产出即冻结、下游只读，而封死另一选项的三条依据之一正是「不在战斗开始时二次展开」——存 build 层等于把展开推迟到战斗开始，就是在 combat-service 里开第二个物化点。
- **本作不存在多敌人场景 —— 承载字段一律写单数** `EnemyInstance Enemy`：战斗模型恒为双方对称的两个参战方、道念各持一份、EnemyManager 一份。**不写列表、不留「日后可能变多」的伸缩位**——留一个恒长 1 的列表只会让每个消费点都要处理一个永不发生的分支。
- **已知代价**：`EnemyInstance` 嵌进 `EventOption` 会放大定稿快照的体积（一批 eventOptions 里每个战斗事件都带一份卡组 `Id` 序列），这让「增量 push 粒度」那条待答更承重。

### 取池 —— 三层框定，全部叠在 `AllEnabled()` 之后

```csharp
var pool = ContentRegistry.AllEnabled<EnemyData>()
    .Where(e => e.EncounterScopes.Contains(spec.Tier))                         // ① 遭遇档位作用域
    .Where(e => e.PoolScope == null                                            // ② 池归属；null = 通用条目，恒进池
             || e.PoolScope.Matches(currentLocationId, activeArcIds))
    .Where(e => e.ChapterScope.Length == 0                                     // ③ 篇章框定；空 = 三章通用
             || e.ChapterScope.Contains(currentChapter));
```

- **第 ③ 层的入参 `currentChapter` 是单值 `int`**（取自 `CharacterProfile.chapter`），与第 ② 层的 `activeArcIds` 必须是集合形成对照：角色恒处于**恰一个**篇章，而 `Active` arc 可同时有多条。**不要照抄 arc 那一层的集合形状。**
- **`ChapterScope` 空 = 不限，与 `EncounterScopes` 空 = `PushError` 的不对称是有意的。** 判据是漏填的后果不同：`EncounterScopes` 写成空数组后 `Contains` 恒假 ⇒ 该条目**永不进池**，是一条写了也永不显形的死内容；`ChapterScope` 的过滤写成 `Length == 0 ||`，空数组下恒真 ⇒ 漏填只是**范围偏宽**（三章都出），不是死条目。且它与 `PlotArcData.ChapterScope` 同名同义——两处同名字段取相反语义本身就是一个坑。
- **不设「`ChapterScope` 长度必须 < 3」这类检查**：显式写 `[1,2,3]` 与留空语义相同，而显式写是内容侧表达「我确认过三章都出」的正当方式。

- **`PoolScope` = 带两个具名可空字段的内嵌 `Resource`**（内嵌类型一律 `Resource` 派生：`[Export]` 只接受 Variant 兼容类型与 `Resource`）：

  ```csharp
  [GlobalClass]
  public partial class PoolScope : Resource
  {
      [Export] public string LocationId { get; set; } = string.Empty;  // 空 = 不限地点；非空 → 须存在于 LocationData 仓储
      [Export] public string PlotArcId  { get; set; } = string.Empty;  // 空 = 不限剧情线；非空 → 须存在于 PlotArcData 仓储
  }

  // 匹配 = 逐维度的与门，空维度恒真
  Matches(currentLocationId, IReadOnlyCollection<string> activeArcIds):
        (string.IsNullOrEmpty(LocationId) || LocationId == currentLocationId)
     && (string.IsNullOrEmpty(PlotArcId)  || activeArcIds.Contains(PlotArcId))
  ```

  - **取具名字段而非一组 tag（承重）**：悬空校验是硬要求，而它要求类型已知——具名字段让「去哪个仓储查」写成两行代码；tag 丢掉类型信息，校验要么写不出来，要么得引入一张「前缀 → 该去哪个仓储查」的约定表，而那张表不可机械校验。同族的跨类型引用（`PlotArcData.PlotTriggerId` / `PlotEdge.ToNodeId`）全是具名 `Id` 字段 + 加载期悬空校验，没有一处用 tag。维度数由既有权力面封闭（location 与 arc 各一），tag 的唯一优势——可加性——在此不存在。
  - **字段定名 `PlotArcId`，不是 `PlotLineId`**：剧情线在数据上的载体是 `PlotArcData`（`Id` 形如 `plot.arc.story.ashen_lineage`），一个指向不存在类型的 `Id` 字段名会让悬空校验无处可查。
  - **剧情线一侧的匹配输入是「全部 `Active` arc 的集合」，不是单值**：Story / Chapter 各恒有一条、外加 `MaxConcurrentSideArcs` 条 side arc 同时活跃，「当前剧情线」本就不是一个单值。**取单值会让 side arc 的专属敌人永不出现**，故取池的入参写作 `activeArcIds`。
  - **两字段同时非空 = 双重专属**（只在那条 arc 活跃且身处那个地域时进池），是内容侧最强的收窄手段，不需要额外规则允许它。
  - **`PoolScope == null` 的通用条目恒进池，`Matches` 不被调用**——空判据必须写在与门之外，否则通用条目上会解引用 `null`。
- **地域 / arc 专属条目是叠加，不是替代（承重）。** 本作**不存在地域独占生态**：通用敌人在任何地域、任何 arc 下都恒进池，专属条目只是在通用池之上**加项**。这与「共享敌人池 + 作用域字段，而非另立一批条目」是同一条判据的延伸——地域独占意味着每个地域都要一套自己的完整条目，正是被内容成本否决的那条路。**推论**：某地域「会遇到什么」不再能从一份 location 条目里一眼读全，需要反查——而那本就是 `LocationCodex` 词条（运行时统计）的职责，不是内容编写面。**篇章框定同构**：`ChapterScope` 为空的通用敌人在三章都进池，专章条目只在自己那一章加项——同样是叠加而非替代。

- **共享敌人池 + 作用域字段，而非另立一批「切磋对手」条目。** 依据：赋级规则已定为「挂 Enemy 不挂事件类型，`combatTier` 三档一视同仁」，其自然延伸是**敌人条目本身也一视同仁**；Practice 的低风险已由 `WinMargin: 0` 承担，不必靠特例；**内容成本**——敌人条目含图鉴五项 + 基准数值 + 样本卡组 + 两个持有列表，是本作最重的内容单元之一，翻倍不可接受。
- **承重论据 = 图鉴的正向增益**：共享池使玩家**能先在低风险的 `Practice` 档遇到并解锁某个敌人的图鉴，再在 `Standard` 档里正式对上它**。敌人的行动既不作事前预告，**图鉴就是事前知识的主通道**，这条「先遇见、再对上」的路径因此是可读性的重要来源。另立一批则图鉴要么翻倍、要么分裂成两套。
- **`PoolScope` 是剧情线表达差异化的唯一合法途径**：剧情线**不可调制敌人模板**，「大限将至」线上的绝境敌人 = **该线专属池里的一条完整 `EnemyData`**（自带更凶的样本卡组与 power），不是把通用条目临场改凶。好处：改写幅度天然有界、图鉴词条与实际遭遇恒对得上、可确定性复算；代价：内容量上升，归内容排期。
- **叙事一致性靠内容纪律**：标为 `[Practice, Standard]` 的条目，其图鉴与台词必须同时说得通「切磋」与「厮杀」两种语境——归 `enemy-codex` 的写作规格。**跨篇章一致性则由 `ChapterScope` 承担**：赋级带使任何敌人在任何篇章都**数值可用**，故这一格切的不是强度而是**叙事归属**——炼气期的凡俗山贼以「金丹初期」的赋级出现在第三篇章时，图鉴词条会与实际遭遇当场对不上，而图鉴是敌人可读性的主通道。`ChapterScope` 把这条本来只能靠人工评审的内容纪律变成一格可机械过滤的框定。

### 赋级带的接受面

- **敌人等级的合法区间 = `[角色等级 − 2, 角色等级 + 2]`**，在全局序 1–22 上截断，**三章统一**；带边界住在平衡资源 `EnemyLevelingData`（与带内分布权重同住一份），随内容 overlay 可调。**`±2` 是无例外的硬规则**——赋级函数不接受任何区间覆盖参数。
- **赋级规则挂在 Enemy 上、不挂事件类型上** ⇒ `combatTier` 三档一视同仁；**天劫亦然**（角色在境界巅峰 13 / 17 / 21，天劫在下一境界初期 14 / 18 / 22，`diff` 恒为 +1 且必然越阶）。
- 带内分布权重、截断重分配、批内去重见 `systems/balance.md`；物化管线见 `systems/services/future-event-service.md`。
- **推论**：越阶遭遇只出现在每个境界的末两级（12·13 / 16·17 / 20·21），三章统一。

### 埋伏

- **敌人侧同样布置埋伏**：它在玩家回合触发，对手只见计数——是一个被公开计数的「已知未知」。
- **埋伏的既有规则对敌人侧原样适用**（同名不可重复、触发后进弃牌堆、面朝下、对手只见计数），不为敌人侧另立一套。
- 样本卡组可含埋伏 ⇒ 内容编排上多一个旋钮（这条敌人带不带、带几张）。

### 敌人台词 —— `Lines`

台词天然是「若干场合各一句、只写要写的那几句」，故形态与 `AiWeight` 同构：**稀疏覆写数组 + 内嵌 `Resource` + 两个具名字段**。

```csharp
// EnemyData 上。只落 enemies/：挂载面只有敌人一处，「只有一个落点的字段不进任何 common-properties.md」
[Export] public EnemyLine[] Lines { get; set; } = [];   // 只列要写的场合；空数组合法 = 无台词

[GlobalClass]
public partial class EnemyLine : Resource                // 内嵌 Resource + 两个具名字段，同 AiWeight / TechniqueRef
{
    [Export] public LineSlot      Slot { get; set; }
    [Export] public LocalizedText Text { get; set; }
}

public enum LineSlot { /* ⟨待定：成员随战斗 UX 专场一并定，见 common-properties.md 的待决问题⟩ */ }
```

- **不写成一组具名字段**（`IntroLine` / `VictoryLine` / `DefeatLine`）：每加一个场合就要改 C# 类 + 发版，撞「新增内容 = 新增 / 编辑 `.tres`，不改 switch」——这正是 `LocalizedText` 否决「每语言一个 `[Export]` 字段」的同一条理由。
- **不上移为顶层共有字段**：挂载面只有 `EnemyData` 一处。
- **`LineSlot` 无成员期间，`Lines` 对任何条目都只能是空数组**；三条加载期校验与该阻塞的完整陈述见 `common-properties.md`。

### 敌人 AI —— 通用兜底 + 模板级定制策略

- **两层结构。** ① **通用兜底策略**：任何套牌都能跑的保底出牌逻辑，实现在 EnemyManager 内（AI 行为选择的落点见 `systems/services/combat-service.md`）。② **敌人模板级定制策略**：出牌策略挂在 `EnemyData` 上（「这个敌人该怎么打」），**不挂功法**；字段可空，**空即走兜底**。
- **策略经 `EnemyInstance.EnemyId` → `ContentRegistry.Get<EnemyData>()` 读取，`EnemyInstance` 六字段不变**——模板常量不是物化产物。战斗内因此不需要认识功法，「功法是战斗外的构筑层，战斗内完全不感知它」一字不动。
- **定制策略只表达打法风格，不作强度 / 难度旋钮。** 难度仍只由 `baseMomentum` 与内容编排承担——一边否掉层数浮动、一边开 AI 强度通道会自相矛盾。
- **确定性约束**：AI 决策必须是「局面 + `combat` 子流」的纯函数；跨回合记忆必须可重算，否则必须落存档。**本方案不消耗随机**（见下方「零随机」），故「随机只取 `combat` 子流、不再派生新流」当前是一条空约束——保留它，作为日后引入随机化权重项时的约束。

#### 定制策略的表达形态 —— `EnemyAiProfileData`

```csharp
[GlobalClass]
public partial class EnemyAiProfileData : Resource   // .tres 落内容层，经 ContentRegistry 加载
{
    [Export] public string     Id             { get; set; } = string.Empty;  // enemy_ai.<snake_case_slug>
    [Export] public bool       ContentEnabled { get; set; } = true;
    [Export] public AiWeight[] Weights        { get; set; } = [];            // 只列要覆写的项
}

[GlobalClass]
public partial class AiWeight : Resource             // 内嵌 Resource + 两个具名字段，同 TechniqueRef
{
    [Export] public AiTerm Term  { get; set; }
    [Export] public float  Value { get; set; } = 1.0f;
}
```

- **它是一条独立可复用资源，不是内联字段。** 判据是**是否需跨条目复用**：需要，且是常态——定制策略表达的是**打法风格原型**（守势 / 抢攻 / 消耗 / 埋伏流），一种风格天然被一批敌人共享；内联意味着「把守势打法调一档」要逐个敌人条目改一遍，漏一个即得到一条半改的风格。反面判据同样成立：`PoolScope` / `TechniqueRef` 取内联，正因为它们**逐条目独有、从不共享**。
- **引用形态照抄 `AbilityData`**（直接类型引用，不写 `AiProfileId : string`）——那是本库「有稳定 `Id`、进注册表、被多个载体引用」的既有形状，取 id 字符串会造出第二套引用惯例。
- **不挂 `Rarity`**：它不进任何抽取池（判据见 `systems/common-properties.md`）。
- **profile 只列它要覆写的项**，未列项取兜底默认值。收益有二：兜底调参自动惠及全部 profile，不必逐条同步；profile 文件短到一眼能读出「这个敌人偏在哪」。
- **profile 内没有第二类结构位。** 里面只有权重向量，「优先打关键卡」「保留 N 点 mana」这类偏好一律表达为某个 term 的权重。多开一格结构就是多开一条与权重并行的表达通道，此后每条策略都要回答「这件事该写在哪一格」。
- **本文档只写类定义与形态；profile 的逐条取值归内容层**（`content/enemy-ai/<id>.md`），兜底默认向量与取值域归 `systems/balance.md`。

#### 兜底算法 = 单层加权效用评分 + 确定性 argmax

一次决一个动作：组装候选集 → 逐个试算分数 → 取 argmax → 执行 → 等栈结算干净 → 重新组装候选集。`score(EndTurn) ≡ 0` 作绝对零点，选中它即结束回合。

- **决策粒度 = 逐张，且每次重算候选集。** 理由是必然而非偏好：**栈结算会改变局面**（连锁触发、道念被下限 0 截断、条目落场 / 离场），一次性规划出的第 2、3 个动作在执行到时的合法性与价值都可能已经变了。「逐张」说的是 AI 在自己回合内的内部推进顺序，与「敌人回合内部不落决策点、一个决策点覆盖整段」完全自洽。
- **单层（1-ply）试算，不模拟连锁触发——这是规则，不是实现细节。** 每个候选的收益按该动作自身 `EffectData` 在求值管线（加法层 → 乘法层 → 下限 0 截断）上跑一遍得出，不展开它可能引发的触发链。模拟连锁等于把 StackManager 的结算在评分里重跑一遍（性能与正确性双重风险），且它正是强度上界的主要来源之一；不写成规则，日后有人顺手加一层，上界当场失效。
- **`score(EndTurn) ≡ 0` 是承重的**：它把「还该不该继续行动」变成 argmax 的自然产物，不需要第二套「何时收手」的规则；同时它意味着权重向量恒有一个绝对零点，取值域因此可被钳制。
- **`AiTerm` 十项初值，开放可加**（形态照抄 `EffectData` 原子操作清单：原语在代码、组合在数据）：

  | `AiTerm` | 语义（全部只读对称可见信息） |
  |---|---|
  | `MomentumGain` | 试算得到的自己道念净产出 |
  | `MomentumDenial` | 对对手道念的**有效**削减 = `min(声明削减量, 对手当前道念)`，直接复用「下限 0 逐次截断、溢出不结转」这条规则 ⇒ AI 天然不会把大削减砸在残血对手上 |
  | `ManaEfficiency` | `(MomentumGain + MomentumDenial) / max(1, manaCost)`；打满 mana 的倾向由它承担 |
  | `BoardPresence` | 本动作落场的永久物条目数 |
  | `Removal` | 本动作移除的**对手**战场条目数 |
  | `AmbushCaution` | 对手埋伏计数 > 0 时对高费一次性投入的折价（**只读计数、不读内容**——这正是「埋伏的威慑力与实际效果是两件事」的落地） |
  | `HandRetention` | 打出后手牌张数过低时的负分（消耗流留手） |
  | `KeyCardBias` | 本动作的卡牌 `Id` ∈ 该敌人的 `KeyCardIds` 时加分 |
  | `ClosingUrgency` | 己方剩余回合数 ≤ 2 时，对即时收益加权、对铺垫类收益减权 |
  | `ItemEagerness` | 己方剩余回合数 ≤ 2 时对用道具加分（道具不带走，末回合不用即浪费） |

- **`KeyCardBias` 有一条免费的正向副作用**：`KeyCardIds` 是图鉴「关键卡牌」词条的数据源，而图鉴是**事前知识的主通道**；让 AI 真的偏向打出关键卡，使图鉴所述与玩家实际观察到的行为对齐。这是它存在的第二个理由，不只是打法风格。
- **目标选择复用同一个评分函数**：对每个槽位，在既定的 `LegalTargets` 求解结果中取使该动作试算分数最高的那一个；仍平手取序列中的第一个。不为目标另写一套启发式——两套会各自漂移，而本库没有机制发现它们不一致。**`LegalTargets` 为空的槽位使该候选整个不进候选集**（不是先选中再 fizzle）：AI 没有理由主动打出一张必然落空的牌。
- 候选集的完整组成、动作与视图类型、纯函数签名见 `systems/services/combat-service.md`。

#### 零随机 · 零记忆

- **全流程零随机。** 兜底与定制策略均不消耗任何随机；平手打破取确定性字典序（`−score` → 动作种类序 → 主体 id 的组装序，取最小）。实例发号本就确定（闭集按固定顺序发号），故「组装序」是现成的可复现全序，不需要新增任何状态。承重理由不止工程：敌人不作任何事前预告，**图鉴是唯一的事前通道**，而它的价值建立在「这个敌人会怎么打是可学习的」之上；给 AI 掷骰是在唯一的事前通道上再打一个折扣。**代价是重复遭遇同一敌人时行为完全一致**，这是被接受的取向——「显得机械」的解法更便宜：多写两条 profile，让同一批敌人打法各异。
- **多回合行为倾向 = 局面函数，零记忆。** 一切「倾向」都写成当前局面的函数（剩余回合数 · 双方道念差 · 自己抽牌堆余量 · 自己战场上的条目 · 手牌张数），这些全部已在 `ActiveCombat` 内 ⇒ **存档 schema 一格不加、零迁移**，且「敌人回合是一段可确定性重放的区间」原样成立——退出重进重放整段不可能分叉，因为压根没有不在存档里的东西。「前期铺场、后期梭哈」由 `ClosingUrgency` / `BoardPresence` 两个 term 表达，不需要一个「我打算铺场」的记忆位。
- **AI 不得持有任何跨动作、跨回合的私有字段。** 决策函数写成 `static` 纯函数，私有记忆在语言层无处存放（`ADR-0013` 第 1 级）。

#### 强弱差 = 三条结构性上界

「策略不得强于兜底多少」仍是**不可机械校验的编排口径**，但它的绝大部分由三条上界变成结构性事实：

| # | 上界 | 它封住了什么 | `ADR-0013` 级别 |
|---|---|---|---|
| ① | **定制层只提供权重向量，不提供代码** | 定制与兜底跑同一条 argmax 循环、同一套 term、同一个候选集：无法多看一层、无法多算一步、无法读到兜底读不到的输入 | 第 1 级 |
| ② | **搜索深度恒为 1-ply，试算不展开连锁** | 强度天花板由算法深度决定，而深度是代码常量、不在数据面上 | 第 1 级 |
| ③ | **`Value` 钳在 `[AiWeightMin, AiWeightMax]`**，加载期越界 `PushError` + 抛 | 极端权重只能让 AI **偏科**（更像某种风格），不能让它更强——分数是同一批 term 的线性组合，缩放不改变可达动作集 | 第 3 级 |

- **推论：定制策略「不强于兜底」在结构上已近乎自动成立**——它是兜底在同一搜索空间内的一次重新加权。剩余的自由度（某种偏科恰好特别克某类玩家套路）不可机械校验，那一小块仍留在编排口径。
- **不另加带数字的胜率口径**（如「定制相对兜底的基准胜率偏差 ≤ ±5pp」）：该数字在量纲基准与首批 starter deck 成型之前无法测量，写下即是一条无人执行的条款。日后确有需要时它是纯加法。
- 取值域住平衡资源，故可随 overlay 热更收紧，不必发版。

Source: `handoffs/2026-08-30-affinity-and-technique-attributes.md` · `handoffs/2026-08-30-life-lifespan-merge.md` · `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md` · `handoffs/2026-08-04b-mtg-loanwords-card-types-and-intent-snapshot.md` · `handoffs/2026-08-05-level-band-stack-save-and-token-free-deck.md` · `handoffs/2026-08-06d-combat-open-questions-mass-closure.md` · `handoffs/2026-08-22-enemy-pool-chapter-scoping.md` · `handoffs/2026-08-22-band-boundary-config-placement.md` · `handoffs/2026-08-25-enemy-deck-from-techniques-and-ai.md` · `handoffs/2026-08-26c-enemy-ai-strategy-shape.md` · `handoffs/2026-08-28-content-artwork-enemy-lines-and-ai-weight-vector.md`

## 决策(-> ADR)

- **敌人模板与实例只有两个类型：模板统一定名 `EnemyData`（不存在第二层「模板」结构），实例定名 `EnemyInstance`，嵌在 `EventOption` 上随批次落存档；不存在多敌人场景（字段单数）**。
- **enemies 升为与 `adventure-event` 平级的系统；`combatTier` 三档共享同一批条目，由 `EncounterScopes : CombatTier[]` 声明档位作用域、由 `ChapterScope : int[]` 声明篇章归属**。
- **剧情线不可调制敌人模板；剧情线与地点各自可拥有专属敌人模板池，池归属的唯一权威是敌人条目上的 `PoolScope`**（location 条目不持敌人清单）。
- **定制 AI 策略 = 权重向量的重新加权：`AiProfile : EnemyAiProfileData`（独立可复用资源、直接类型引用、可空、空即兜底），定制层不提供代码；兜底算法 = 1-ply 加权效用评分 + 确定性 argmax，决策粒度逐张；AI 全流程零随机、零记忆，`ActiveCombat` 一格不加** → `decisions/ADR-0113-enemy-ai-weight-vector.md`（Accepted；它给 `ADR-0092` 的软约束补上了三条结构性上界）。

## 待决问题

- **敌人各等级的道念产出缩放：** 起始值已由 `baseMomentum` 给定，产出能力的缩放曲线未定 → `systems/balance.md`（留待内容扩充后的统计校准）。

## 对应
提炼至：`.claude/knowledge/systems/enemies.md`（待建）
