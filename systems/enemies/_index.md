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
  | `KeyCardIds : string[]` | **长度 2–3**，必须是样本卡组内的 `Id`。图鉴「关键卡牌」词条的数据源，**显式标注不自动挑选** |
  | 样本卡组 | 物化时按赋级对齐 / 风味替换；**规模逐条编排、不设硬限**，允许同名条目重复。规模偏小的卡组会在后期触发疲劳（抽牌堆不重洗，空堆每抽一张 −1 道念），**这是「牌少而精」的内建对价**，也是一条可用的编排旋钮 |
  | item 持有列表 | 敌人没有储物袋，道具直接挂模板 |
  | power 持有列表 | 开局入场的受保护永久物；「不可被移除的场上特性」是 boss / 天劫最自然的表达 |
  | `EncounterScopes : CombatTier[]` | 可出现在哪些**遭遇档位**（`{ Practice, Standard, Finale }`，取值与 `EncounterSpec.Tier` 同一枚举）；**空数组 = 数据缺陷 → 加载期 `PushError`** |
  | `ChapterScope : int[]` | 可出现在哪几个篇章（取值 `1..3`，对位 `CharacterProfile.chapter`）；**空 = 不限（三章通用）**，与 `PlotArcData.ChapterScope` 同名同义 |
  | `PoolScope` | 类型 `PoolScope`（内嵌 `Resource`），**允许为 `null` = 通用池，不报错**。池归属：通用 / 某地点专属 / 某剧情线专属；形态与匹配语义见下 |
  | `OverridesDeck : bool` | 定制卡组标记（天劫等）；为 `true` 时跳过「关键卡牌不得被改写」的检查，图鉴条目自带说明 |

- **敌人等级不在模板上定死**——等级是 future-event-service 的**物化产物**，故同一个敌人可在不同篇章 / 情境下以不同等级出场。
- **敌人持有道念、行为，并持有自己的卡组**；**敌人侧的战斗内量与玩家侧对称**，也是道念，不设独立的血量池。
- **敌人的战斗强度以 `baseMomentum` 为主刻度**：等级 → 起始道念 → 开局领先量，这是越级压迫感的直接来源。**卡组保持强度中立，不叠第二条强度曲线**（否则 `±2` 带的数值安全性推导立刻失效）。

### `EnemyInstance` —— 物化定稿实例

```csharp
public sealed record EnemyInstance(       // 物化定稿 · immutable · 随 EventOption 落存档
    string                InstanceId,     // 本次物化实例的稳定标识
    string                EnemyId,        // 溯源到模板：ContentRegistry.Get<EnemyData>(EnemyId)
    int                   Level,          // 物化赋级产物（全局序 1–22，落在角色 ±2 带内）
    IReadOnlyList<string> DeckCardIds,    // 改写后的卡组（Id 序列；闭集，无凭空生成的牌）
    IReadOnlyList<string> ItemIds,        // 本场可用道具
    IReadOnlyList<string> PowerIds);      // 开局入场的受保护永久物
```

- **性质对齐 `EventOption` 而非 `CardInstance`**：模板 ↔ 实例通则的三对里，`EventOption` 是定稿不可变、`CardInstance` 是运行态可变；敌人实例属前者——**物化产出即冻结、落存档、下游只读消费**。
- **战斗内的敌人运行态**（道念、手牌、卡组状态、已用道具、`Power` 计数器）由 **EnemyManager 持有**，不进 `EnemyInstance`，也不另立类型。
- **嵌在 `EventOption` 上随批次落存档**（承载格 = `EventOption.Encounter` 内的 `EncounterSpec.Enemy`），不在战斗开始时二次展开。三条依据任一条单独成立即封死另一选项：**① 唯一物化点**（战斗开始时展开 = 在 combat-service 里开第二个物化点）· **② 选择界面就要显示敌人等级**（等级是物化产物，`EventOption` 卡片上的越阶提示与风险评估都发生在战斗之前）· **③ 嵌套使敌人实例在同一份定稿实例内只有一个落点**——平铺一份 `EnemyInstance` 而 `EncounterSpec` 也持一份，会让同一个敌人有两条读取路径且无任何机制保证二者相等；跨落点的副本（结算期的 `activeEvent` 快照）由既定的快照语义统一管辖，权威只有一处。
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
- 样本卡组可含埋伏 ⇒ 物化改写多一个旋钮（这一场带不带、带几张）。

Source: `handoffs/2026-08-01b-abstraction-levels-combat-numbers-codex-family-and-monetization.md` · `handoffs/2026-08-04b-mtg-loanwords-card-types-and-intent-snapshot.md` · `handoffs/2026-08-05-level-band-stack-save-and-token-free-deck.md` · `handoffs/2026-08-06d-combat-open-questions-mass-closure.md` · `handoffs/2026-08-22-enemy-pool-chapter-scoping.md` · `handoffs/2026-08-22-band-boundary-config-placement.md`

## 决策(-> ADR)

- **敌人模板与实例只有两个类型：模板统一定名 `EnemyData`（不存在第二层「模板」结构），实例定名 `EnemyInstance`，嵌在 `EventOption` 上随批次落存档；不存在多敌人场景（字段单数）**。
- **enemies 升为与 `adventure-event` 平级的系统；`combatTier` 三档共享同一批条目，由 `EncounterScopes : CombatTier[]` 声明档位作用域、由 `ChapterScope : int[]` 声明篇章归属**。
- **剧情线不可调制敌人模板；剧情线与地点各自可拥有专属敌人模板池，池归属的唯一权威是敌人条目上的 `PoolScope`**（location 条目不持敌人清单）。

## 待决问题

- **敌人是否也以功法构筑卡组。** 功法（`CultivationTechnique`）已定为**角色侧**的卡组构筑单位；`EnemyData` 的样本卡组当前仍是**直接的卡牌列表**。若敌人也用功法，图鉴词条②「功法简介」可与系统概念合流、敌人内容的编写颗粒度也随之变粗；若不用，词条②保持为纯风味文案。→ `systems/character-profile/deck/_index.md`、`systems/player-profile/codex/enemy-codex.md`。
- **敌人 AI 的规划形态：** 「回合级一次性规划」这条硬约束**已随 08-15d 意图机制整条移除而解除**——AI 可在自己回合内逐张决策。仍未定义：具体算法、**规划粒度（一次性 vs 逐张）**、多回合行为倾向、难度旋钮的落点。→ `systems/services/combat-service.md` 的 EnemyManager、`systems/adventure-event/combat/_index.md`。
- **敌人各等级的道念产出缩放：** 起始值已由 `baseMomentum` 给定，产出能力的缩放曲线未定 → `systems/balance.md`（ch1 数值标杆专场）。

## 对应
提炼至：`.claude/knowledge/systems/enemies.md`（待建）
