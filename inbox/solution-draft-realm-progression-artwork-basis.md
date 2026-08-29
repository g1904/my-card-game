---
type: solution-draft
date: 2026-08-28
question: 境界晋升是否改变角色 / 敌人外观？—— 即共有字段 `Artwork` 是保持「一条内容一张」的单格，还是升为按境界索引的结构。
source: open-questions/deferred-content.md → 「美术与音频」末条 · art/visuals/_index.md → 「待决问题」末条 · systems/common-properties.md → `Artwork` 节的 ⚠ 前置依赖 · open-questions.md → 「落笔前的必须裁决」①
targets: systems/common-properties.md（删 ⚠ 一行 + `Artwork` 基数收口一句）· art/visuals/_index.md（类目表「角色形象」「敌人立绘」两行 + 移出待决问题）· art/visuals/art-direction.md（「境界越高画面越沉」的适用口径限定）· systems/character-profile/_index.md（若采纳角色多套：`CharacterData` 新增一格 + `Artwork` 投影段）· systems/viewmodel.md（境界选取的落点）· decisions/（ADR 候选一条）
status: decided
---

# 方案草稿 — 境界晋升是否改变角色 / 敌人外观（`Artwork` 的基数）

## 问题

`ADR-0120`（2026-08-28）刚把视觉资产引用定为**顶层内容共有字段 `Artwork : Texture2D`**，挂载面七类（`CardData` · `EnemyData` · `PowerData` · `ItemData` · `CharacterData` · `LocationData` · `AdventureEventData`），形态是**一条内容一张**的单格。

同一天，`systems/common-properties.md` 在该字段末尾自标了一条 ⚠：

> **⚠ 基数的前置依赖：本格按「一条内容一张」给出。** 若「境界晋升是否改变角色 / 敌人外观」答为「随境界改变」，`Artwork` 须升为按境界索引的结构，本节的形态要重做。

于是这条原本挂在 `art/visuals/_index.md` 搁置清单里的美术产能问题，反向卡住了工程地基：`open-questions.md` 把它列为**「落笔前的必须裁决」仅存的一件**，而 `common-properties.md` 是 derive 顺序第 1 位、被几乎所有内容与服务代码依赖的整份 ready 文档。不先裁掉它，第一批 `.tres` 的 `Artwork` 基数可能推倒重来。

**本题有两个层次，必须分开答：**

1. **数据形态** —— `Artwork` 的基数改不改。这一半有客观答案，本草稿主张它可以**独立于第 2 半**收口。
2. **是否值得做** —— 一个角色 / 敌人出几张图、随境界几档。这一半是美术产能与内容规模的真取向。

## 约束（来自既有设计）

**A. 敌人没有「自己的境界」——等级是物化产物，不在模板上。**
- `systems/enemies/_index.md`：「**敌人等级不在模板上定死**——等级是 future-event-service 的**物化产物**，故同一个敌人可在不同篇章 / 情境下以不同等级出场。」等级落在 `EnemyInstance.Level`（全局序 1–22），不落 `EnemyData`。
- `ADR-0044`：赋级带 = 角色当前全局等级 **`±2` 对称带**，**无例外硬规则**，赋级函数不接受任何区间覆盖参数。⇒ 一个敌人的实际境界由**角色**的等级决定，且在境界交界处（如角色炼气 13 → 敌人 14/15 = 筑基）会跨境界。
- `ADR-0110`：`EnemyData.ChapterScope : int[]`，**空 = 不限（三章通用）**，且这是默认与常态。⇒ 同一条目合法地横跨三个篇章。

**B. 「难度的篇章差异不由换一张更难的图承载」已是定案（同类问题的先例）。**
- `ADR-0042` / `systems/game-progression.md`：「**三个篇章共用同一张图**——location 不随篇章 / 境界变化。**难度的篇章差异不由『换一张更难的图』承载，而由敌人赋级带承载**……这与『全局等级序是一把简单的直尺、境界鸿沟由 `baseMomentum` 承载』是同一种分工：**结构保持简单，难度放进数值。**」

**C. 共有字段的落点判据是可机械判定的（判据卡）。**
- `systems/common-properties.md` 判据卡：「定义在其全部挂载面的**最小公共祖先**，恰好一份」「**只有一个落点的字段不进任何 `common-properties.md`**，留在该类自己的 `_index.md`」。

**D. 角色是随轮回推进跨越四个境界的唯一对象，且它的境界已在存档里。**
- `systems/game-progression.md`：一次轮回 = 三个 chapter，每个 chapter 是相邻两个 realm 之间的攀登；四个 realm（炼气 / 筑基 / 金丹 / 元婴）。
- `systems/architecture.md:475`：`public enum Realm { QiRefining, FoundationEstablishment, GoldenCore, NascentSoul }`（已登记的共享核心枚举）。
- `systems/character-profile/_index.md` 存档字段表第 6 格：`realm : Realm`。⇒ 呈现层要取当前境界，**零新增存档字段**。

**E. 美术是路线上的末段，且资产量级 / 包体预算全库无数字。**
- `ADR-0006` / `vision/scope.md`：「**美术挂点占位、末段替换**」「音轨、卡面、动画等几乎所有美术相关资源在设计达 ~90% 前一律 **TBA**」「架构中**始终为美术保留可轻松替换 / 定制的挂点**」。
- 包体预算**尚未给出**（`open-questions/deferred-content.md` 音频一条明写）。⇒ 「4 套贵不贵」目前**没有可量化的判据**，只能按相对量级判断。
- `vision/scope.md` MVP = **一个可玩篇章（炼气 → 筑基）**。⇒ MVP 阶段最多只涉及 **2 个境界**，不是 4 个。

**F. 美术基调里已有一句与本题相邻、但不同的表述。**
- `art/visuals/art-direction.md` / `ADR-0100`：「修仙是残酷的攀登……**境界越高，画面应越沉**」；色彩节另留一问：「全局色板是否随**境界**推移」。这两句谈的是**风格随进程加深**，不等于「同一条目要出多套图」。
- 同文件类目表「敌人立绘」行：「需传达境界与威胁度；**同一敌人在图鉴与战斗屏复用**」——方向恰好相反（一张图两处用）。
- 类目表「UI 元件与框架」行已含 **「境界指示」**——境界的可见化本就已经规划在 UI 层。

**G. 纯加法窗口仍然开着，但只在第一批 `.tres` 之前。**
- `content/_index.md`：全部 17 个内容类型**均未开张**（「开张」栏全 ✗），`.tres` 存量为零。
- `art/visuals/guides/_index.md` 台账为空，**零份 guide**。⇒ 本题目前不存在任何返工存量。

---

## 建议方案

### 1. 共有字段 `Artwork : Texture2D` 的基数**建议保持单格不变**，且这一条可**独立于「是否值得做」先行收口
`[既有推演]`

**承重论证（不依赖第 2 半的答案）：** 七个挂载面里，能被「境界」索引的只有 `CharacterData` 一个。逐条排除：

| 挂载面 | 能否按境界索引 | 依据 |
|---|---|---|
| `EnemyData` | **否** | 条目本身没有境界（约束 A）；境界是 `EnemyInstance.Level` 的物化产物，且 `ChapterScope` 空 = 三章通用 |
| `LocationData` | **否** | `ADR-0042` 已定「三章共用同一张图，location 不随篇章 / 境界变化」 |
| `CardData` | 否 | 卡牌与境界正交（功法层数 `TechniqueTier` 是另一个量，`terminology.md` 明写不共用「等级」一词） |
| `PowerData` / `ItemData` | 否 | 法则 / 神通 / 古宝 / 法宝是图标级资产，与持有者境界无关 |
| `AdventureEventData` | 否 | 事件插图，全库无任何按境界分版的表述 |
| `CharacterData` | **可能** | 角色是唯一在一次轮回内跨越四个境界的对象（约束 D） |

⇒ 按判据卡（约束 C），**一个只有单一落点的按境界结构不属于 `common-properties.md`**。即使第 2 半答「角色要换外观」，正确落法也是**在 `CharacterData` 自己那份文档上另开一格**，而不是把顶层共有字段的基数改掉。

**因此建议 `systems/common-properties.md` 的改动只有两处、且是删减不是重做：**
- 删掉第 247 行那条 ⚠（「基数的前置依赖……本节的形态要重做」）；
- 在 `Artwork` 节补一句收口：**「基数恒为一条内容一格。境界维度不进本字段——它至多只覆盖 `CharacterData` 一个落点，按判据卡属该类自有字段。」**

**这一条解除 derive 第 1 步的阻塞**，且**无论第 2 半怎么答都成立**。

### 2. 敌人**建议明确定为不随境界改变外观**——这不是取向，是机制上做不到
`[既有推演]`

不是「不值得做」，而是**没有可索引的键**：

- **模板上没有境界。** 同一条 `EnemyData` 在角色炼气七层时以 level 8 出场、在筑基后期时以 level 17 出场，两次都合法（约束 A）。要按境界换图，只能在 ViewModel 里拿 `EnemyInstance.Level` 反查 realm 再选图——**索引键来自运行时实例，而不是这条内容自己的属性**。
- **`ChapterScope` 空 = 三章通用是默认与常态**（`ADR-0110` 明写「空 = 不限」的不对称是有意的）。一条三章通用的敌人，其境界数组就必须铺满四格；而绝大多数条目实际只在一两个境界出现 ⇒ **多数格恒空**。这正是 `ADR-0120` 否决「按用途拆 `Portrait` / `Icon` / `Illustration` 三格」时用过的同一条判据（「至少两格恒空」）。
- **恒空格 + 「缺失即回落占位」= 静默降级。** `Artwork` 的缺失语义是「回落 `res://art/_placeholder.png`」（`systems/viewmodel.md`），且告警是 `LoadAll()` 收口的一行汇总、逐条目不告警（`ADR-0120`）。⇒ 一个敌人被赋到没画过的那一档境界时，玩家看到的是**占位图而不是这个敌人**，而告警通道按设计不会逐条目报它。**这是一条会静默发生、且已被既定告警形态屏蔽的故障。**
- **它与 `ADR-0042` 是同一道题、同一个答案。** 「同一张地图在三个篇章重走，敌人强度自动跟着角色走」——结构保持简单，难度放进数值。敌人外观是同一条分工的下一格。
- **量级：敌人立绘是逐条目类目，×4 是全库第二大的资产乘数**（仅次于事件插图，而事件插图已明写「前期不产出」）。

**建议的替代兑现方式（不动数据形态）：**
- **「传达境界与威胁度」由该条目自身的画面承担**（类目表已如此写），配合 `ChapterScope` 把它框在叙事上说得通的篇章里；
- **运行时的越阶感由既有通道承担**：`EventOption` 卡片上已要显示敌人等级（`systems/enemies/_index.md` 明写这是 `EnemyInstance` 嵌进 `EventOption` 的三条依据之一），战斗屏的主视觉是双方道念对比（`ux/combat-ux.md`），越阶压迫感由 `baseMomentum` 起跑线承载（`ADR-0034`）。

### 3. 其余四类（`CardData` / `PowerData` / `ItemData` / `AdventureEventData`）与 `LocationData` 同样不随境界改变
`[既有推演]`

`LocationData` 已由 `ADR-0042` 定案。其余四类全库无任何「随境界分版」的表述，且都是逐条目类目（乘数直接落在资产总量最大的三个类目上）。**建议在 `art/visuals/_index.md` 类目表里把「一条目一张」写成显式约定**，使这一条日后不必再问一次。

### 4. 玩家角色：**若要做，形态是 `CharacterData` 自有的一格稀疏覆写数组，不动共有字段**
`[既有推演]`（形态）+ `[取向选择]`（是否做 → 见「仍需用户决定」）

形态与 `ADR-0120` 同批落下的 `Lines : EnemyLine[]` **完全同构**（稀疏覆写数组 + 内嵌 `Resource` + 两个具名 `[Export]`），故不引入任何新的结构范式：

```csharp
// 落 systems/character-profile/_index.md（CharacterData 的字段面）。
// 只有一个落点 ⇒ 按判据卡不进 systems/common-properties.md。

[Export] public Godot.Collections.Array<RealmArtwork> RealmArtwork { get; set; } = new();
//  稀疏覆写数组：只列「这个境界要换图」的那几档；默认空数组 = 全程用共有字段 Artwork。

[GlobalClass]
public partial class RealmArtwork : Resource
{
    [Export] public Realm     Realm   { get; set; }   // 已登记的共享枚举，systems/architecture.md
    [Export] public Texture2D Artwork { get; set; }   // 挂了这一条就必须给图（见校验 R-2）
}
```

**为什么是稀疏覆写数组而不是定长四格数组：**
- 定长四格里「这一档没画」与「这一档就用基础图」不可区分，而两者的正确行为不同（前者该进缺失统计、后者不该）；稀疏数组用「有没有这一条」把它变成干净可判的条件——与 `LocalizedText` 可选字段「缺失 = 子资源本身不存在」是同一种判据风格（`systems/common-properties.md` 明写「不引入必填 / 可选字段分类清单」的理由）。
- 它使这一格**天然是纯加法**：内容侧可以先只填共有字段 `Artwork` 一张，日后逐境界补一条，**零结构改动**，完全落在「美术挂点先占位、末段替换」内（`ADR-0006`）。

**两级回落，落在既有的单点占位入口内，不新增回落通道：**

```
ViewModel.CharacterArtwork(CharacterData data, Realm realm):
    ① data.RealmArtwork 中 Realm == realm 的那一条 → 取它的 Artwork
    ② 无匹配 → data.Artwork（共有字段，= 基础形象）
    ③ 仍为 null → res://art/_placeholder.png（既有的唯一占位入口，systems/viewmodel.md）
```

`realm` 直接读 `CharacterProfile.realm`（存档字段第 6 格，约束 D）——**不落新存档字段、不 bump schema、无迁移、后端零配合**，与 `Artwork` 本身的性质一致。

**三条加载期校验**（与 `ADR-0110` 给 `ChapterScope` 的两条同形）：

| 编号 | 条件 | 处置 | 理由 |
|---|---|---|---|
| R-1 | 同一条目的 `RealmArtwork` 内 `Realm` 重复 | `PushError` + 报出 `Id` 与 `.tres` 路径 | 两条同境界 ⇒ 选取不确定 |
| R-2 | 某条 `RealmArtwork` 已挂上但 `Artwork == null` | `PushError` | 「挂了却为空仍是坏数据」，同 `LocalizedText` 的既定口径 |
| R-3 | `RealmArtwork` 为空数组 | **不告警**，合法常态 | 同 `Lines` 默认空数组 = 无台词；等价于「全程用基础形象」 |

**缺失统计**：`RealmArtwork` 已挂条目的缺图由 R-2 拦死，故它**不进** `LoadAll()` 那行 `Artwork` 缺失汇总——那行的口径不变（只数共有字段 `Artwork == null` 的条目数）。

**与 overlay 的关系（不变、不加重）：** `RealmArtwork` 是 `.tres` 内的子资源，overlay 覆盖该条 `.tres` 时随之被覆盖；**指向必须落在随包基线内已存在的资产**——与共有字段 `Artwork` 逐字同款。它**不加重**「二进制资产能否经 overlay / blob 通道下发」那条待答项：换的仍是引用，不是二进制本身。

### 5. 「境界感」的主通道建议放在呈现层，不放在整图替换
`[通行做法]` + `[既有推演]`

同类作品里「角色变强了看得出来」通常由**边框 / 底纹 / 光效 / 称号**承担，而非重画立绘（重画的代价与资产量成正比，收益却只在少数几个屏可见）。本库已经把这条通道备好了：

- `art/visuals/_index.md` 类目表「**UI 元件与框架**」行已含 **「境界指示」**——它本就要出，且属于**可九宫格拉伸的 UI 元件**，四档变体的成本与四套立绘差一个数量级；
- `art/visuals/art-direction.md`「境界越高，画面应越沉」与色彩节「全局色板是否随境界推移」都是**guide 编写层**的取向（同一份 guide 在不同境界的条目上给不同色调倾向），**不需要任何字段支撑**；
- 渲染侧的调色 / 光效受 **GL Compatibility** 限制（`vision/scope.md`），故建议**不承诺 shader 级的境界滤镜**，把它留在「UI 元件 + guide 色调倾向」两条已有通道上。

**建议同时在 `art/visuals/art-direction.md` 补一句适用口径**（见「与既有决策的张力」①）：「境界越高画面越沉」按**条目自身的叙事定位**取沉（一条被 `ChapterScope` 框在第三篇章的敌人天生更沉），**不按运行时赋级**取沉——否则 guide 写作会撞上一个数据形态兑现不了的要求。

---

## 具体形态（可 derive 的落地面）

### 形态 1（建议默认 · 与第 2 半无关，可立即落笔）

| 文档 | 改动 | 性质 |
|---|---|---|
| `systems/common-properties.md` | 删第 247 行 ⚠；`Artwork` 节补收口句「基数恒为一条内容一格；境界维度不进本字段」 | 净删减；**解除 derive 第 1 步阻塞** |
| `art/visuals/_index.md` | 类目表补「一条内容一张，不随境界分版」的显式约定；「境界晋升是否改变角色 / 敌人外观」从待决问题移出（改由 `content/character` 侧的一条承接，若采纳形态 2） | 索引更新 |
| `art/visuals/art-direction.md` | 「境界越高画面越沉」补适用口径一句 | 一句 |
| `open-questions/deferred-content.md` | 移出「境界晋升是否改变角色 / 敌人外观」（`/analyze-new-ideas` 执行） | 台账 |
| `decisions/` | ADR 候选一条：**「`Artwork` 基数恒为单格；境界维度至多落 `CharacterData` 自有字段」** | 新 ADR |

**共有字段 `Artwork` 的字段定义一字不改**——`[Export] public Texture2D Artwork { get; set; }`，可空、默认 `null`、七类挂载面、直接资源引用、`LoadAll()` 汇总告警、ViewModel 单点占位回落、不落存档，全部原样。`ADR-0120` **不需要推翻，只需在其「后果」补一句指向新 ADR**。

### 形态 2（仅当「玩家角色随境界换形象」= 是）

在形态 1 之上追加，**互不冲突**：

| 项 | 内容 |
|---|---|
| 落点 | `systems/character-profile/_index.md` 的 `CharacterData` 字段面 |
| 字段 | `RealmArtwork : RealmArtwork[]`，稀疏覆写，默认空数组 |
| 内嵌类型 | `RealmArtwork : Resource` = `Realm Realm` + `Texture2D Artwork` |
| 选取 | ViewModel 两级回落（境界覆写 → 共有字段 `Artwork` → `res://art/_placeholder.png`） |
| 境界来源 | `CharacterProfile.realm : Realm`（既有存档字段第 6 格） |
| 校验 | R-1 重复境界 `PushError` · R-2 挂了却缺图 `PushError` · R-3 空数组不告警 |
| 存档 | 不落存档、不进上行负载、不 bump schema、无迁移、后端零配合 |
| overlay | 同共有字段：覆盖 `.tres` 时随之被覆盖，指向须落在随包基线内 |
| 资产增量 | **4 × 角色池规模**（全量）；**MVP 只需 2 × 池规模**（MVP = 炼气 → 筑基一个篇章） |
| 连带 | `art/visuals/_index.md` 类目表「角色形象」行改写为「一条基础 + 至多三条境界覆写」；`common-properties.md` 的 `Artwork` 挂载面表在 `CharacterData` 一格加脚注回链 |

**资产量级对比（相对判断，因包体预算全库无数字）：**

| 若按境界分版 | 乘数落在 | 量级 |
|---|---|---|
| 玩家角色（形态 2） | 角色池条目数（规模未定，量级最小的类目之一） | 全量 ×4，**MVP ×2** |
| 敌人立绘（**不建议**） | 逐条目、全库第二大类目 | ×4 |
| 卡面插画（**不建议**） | 逐条目、类目最大之一 | ×4 |
| 事件插图（**不建议**） | 「数量最大的类目」（类目表原话），且已明写「前期不产出」 | ×4 |

---

## 后果

- **derive 顺序第 1 步（`/derive-requirements systems/common-properties.md`）的最后一件前置解除**，`open-questions.md`「落笔前的必须裁决」清空。
- **第一批 `.tres` 的 `Artwork` 基数不会推倒重来**——纯加法窗口（`content/` 现零条目、零份 guide）在这一条上安全关闭。
- **`ADR-0120` 无需推翻**：七类挂载面、单格形态、可空语义、告警形态、占位回落、overlay 语义全部保持。只在其「后果」补一行指向新 ADR。
- **`systems/common-properties.md` 净变小**（删一条 ⚠、补一句收口），不触及任何其他共有字段。
- **对四个已挂 `Artwork` 的类型（`EnemyData` / `CardData` / `ItemData` / `PowerData`）零改动**——它们的字段清单与投影段一字不动。
- **零存档影响**：不落存档、不 bump schema、无迁移、后端零配合（两种形态皆然）。
- **若采纳形态 2**：`systems/viewmodel.md` 的「视觉资产的占位回落」一节需从一级回落改述为两级（境界覆写 → 基础 → 占位），仍是**单点**；`CharacterData` 的字段面因此有了第一条成文字段（它目前**尚无任何字段清单**，见「前置依赖」）。
- **美术侧**：`art/visuals/_index.md` 的类目表获得一条「资产乘数」的显式约定，日后写 guide 时不必再逐类目回答「要不要出四版」。

## 备选方案（已考虑并否决）

- **把 `Artwork` 升为按境界索引的结构（顶层共有字段基数改为多格）** — 否决：违反判据卡（能被境界索引的落点只有 `CharacterData` 一个，单落点字段不进 `common-properties.md`）；且会给七类挂载面里的六类各开三格恒空位，正是 `ADR-0120` 否决「拆 `Portrait` / `Icon` / `Illustration` 三格」时用过的同一条理由。

- **敌人按境界分版立绘（在 ViewModel 里用 `EnemyInstance.Level` 反查 realm 选图）** — 否决：索引键来自运行时实例而非条目自身属性；`ChapterScope` 空 = 三章通用是常态 ⇒ 多数格恒空；缺格时静默回落到占位图（玩家看到的不是这个敌人），而 `ADR-0120` 已把告警定为 `LoadAll()` 一行汇总、逐条目不告警 ⇒ 这条故障被既定告警形态屏蔽；量级 ×4 落在全库第二大类目上。**与 `ADR-0042`（三章共用同一张图）是同一道题的同一个答案。**

- **`EnemyData` 上加一格 `RealmScope` 把条目钉死到某个境界，以便按境界出图** — 否决：直接推翻 `ADR-0044`（`±2` 带无例外硬规则、赋级函数不接受任何区间覆盖参数）与 `ADR-0110`（篇章框定切叙事归属而非强度）；且赋级带在境界交界处必然跨境界，钉死会让「角色炼气 13 打到筑基敌人」这个既定情形无图可用。

- **`CharacterData` 用定长四格数组 `Texture2D[4]`（按 `Realm` 序号索引）** — 否决：「这一档没画」与「这一档就用基础图」不可区分，两者的正确行为不同；且它把 `Realm` 的成员序变成序列化契约的一部分（`Realm` 目前不是 code 冻结的枚举），凭空引入一条与 `Source` 同级的冻结纪律。

- **给 `CharacterData` 的境界覆写另设一个 `LocalizedTexture` 式的包装类型** — 否决：`ADR-0120` 已明确「插画内不得烧入可翻译文字（`ADR-0084`）⇒ 视觉资产与 locale 无关」，境界与语言是两条不相干的轴，不共用结构。

- **用 shader / 运行时调色实现境界滤镜（同一张图四种色调）** — 否决为**默认方案**（可作为日后的纯加法增强）：渲染器是 GL Compatibility，特效受限（`vision/scope.md`）；且它是呈现层实现细节，此刻承诺等于给美术方向立一条兑现不了的约束。**建议的呈现层通道是既有的「UI 元件与框架 · 境界指示」，它是可九宫格拉伸的 UI 元件，不受此限。**

- **不裁决，把 ⚠ 留在 `common-properties.md` 里等美术阶段** — 否决：它当前是 derive 第 1 步的唯一阻塞项，而 derive 第 1 步是全库地基；把它留着等于让整条 derive 链等一个美术产能问题，而该问题的**数据形态那一半根本不依赖美术产能**（见建议 1）。

## 与既有决策的张力

**① `art/visuals/art-direction.md` / `ADR-0100` 的「境界越高，画面应越沉」需要一句适用口径限定。**
- **冲突点：** 这句写在总方向文档、适用**全部七个资产类目**。但敌人条目没有自己的境界（约束 A），一条 `ChapterScope` 为空的敌人在三个篇章都会出场——「画面越沉」在它身上**没有可执行的兑现方式**。
- **需要它松动的理由：** 若不限定口径，第一份敌人 art guide 就会撞上这个要求，而写 guide 的人只能靠猜。
- **松动的代价：** 极小——这句从「随运行时境界越沉」收窄为「按条目自身的叙事定位越沉」，`ADR-0100` 的方向本体（grimdark、残酷的攀登）一字不动；它本就是一句风格陈述，不是机制。
- **不松动时的替代：** 保留原句，但在 `art/visuals/_index.md` 的「敌人立绘」行补注「境界感由该条目自身的定位与 `ChapterScope` 承担，不由多套资产承担」——效果相同，只是把限定写在下游而非上游。**建议取前者**（写在总方向文档，因为它适用全部类目）。

**② `ADR-0120` 的「后果」里那句 overlay 表述需要跟一条脚注（仅形态 2）。**
- **冲突点：** `ADR-0120` 后果第 4 条只谈共有字段 `Artwork` 的 overlay 语义。形态 2 新增的 `RealmArtwork` 是同一份 `.tres` 里的子资源，语义逐字相同但未被覆盖到。
- **代价：** 一句话。**不构成实质冲突**，列在此处只为不让它悄悄漂移。

**③ `content/_index.md` 与 `systems/` 对 `CharacterData` 权威落点的记载不一致（先于本题存在）。**
- `content/_index.md:38` 把 `CharacterData` 的类定义权威写作 `systems/character-profile/deck/`，但该路径下并无 `CharacterData` 的任何字段面；概念定案在 `systems/character-profile/_index.md` 与 `ADR-0055`。
- **对本题的影响：** 形态 2 要落的那一格没有明确的落笔位置。建议落 `systems/character-profile/_index.md`（与 `ADR-0055`「字段面与存档关系 → `systems/character-profile/_index.md`」一致），并顺手订正 `content/_index.md` 的权威栏。**这一条是先于本题的既有不一致，不由本题引入。**

## 前置依赖

- **角色池规模未定** —— `open-questions/06-meta-progression.md`：「仍待定：池中有几个角色、是否账号级逐步解锁、能否重抽或指定」。⇒ 形态 2 的**资产总量算不出**（4 × N，N 未定）。**但它不阻塞裁决**：字段形态与「做不做」都不依赖 N，只有「一共几张图」依赖它。
- **`CharacterData` 尚无字段清单** —— 全库只有概念定案（`ADR-0055`），字段面从未落笔。⇒ 形态 2 若采纳，`RealmArtwork` 会成为 `CharacterData` 的第一条成文字段；建议**不为它单开一次落笔**，而是随 `CharacterData` 字段面专场一并写。**形态 1 不受此影响。**
- **`art-direction.md` 的色彩节整段待写**（`> _（待写：主色板、每个境界 / 篇章的色彩倾向……）_`）—— 建议 5 里「guide 层的境界色调倾向」这条通道，其**具体内容**要等该节成文。⇒ 本草稿只主张「这条通道存在且够用」，**不主张具体色调**。
- **「二进制资产是否可经 overlay / blob 通道下发」仍未答定** —— 两库均无表述（后端承接项在 `backend-design-documents/contracts/content-manifest.md`）。⇒ 「换图 / 加图是否必须发版」这一半仍悬着。**本方案不加重它**（两种形态换的都是引用，不是二进制本身），故**不构成阻塞**。
- **包体预算全库无数字** —— ⇒ 「4 套贵不贵」只能按相对量级判断（见「具体形态」的量级对比表），**给不出绝对判据**。这是「仍需用户决定」那一条只能由用户拍的直接原因。

## 仍需用户决定

**（1 项）玩家角色的形象是否随境界晋升更换？**（敌人与其余五类已由建议 2 / 3 推演为「不换」，不在此题内）

| 选项 | 后果 | 资产增量 |
|---|---|---|
| **A. 不换**（`CharacterData` 只有共有字段 `Artwork` 一张基础形象） | 只落形态 1。境界感全部由「UI 元件 · 境界指示」+ guide 色调倾向承担。**零新增字段、零新增校验。** 日后要改仍是纯加法（形态 2 随时可加），**没有窗口关闭风险**——`CharacterData` 的字段面本就尚未落笔 | ×1 |
| **B. 换**（落形态 2：`RealmArtwork` 稀疏覆写数组） | 形态 1 + 形态 2。突破成为一次**看得见**的进程兑现，正对 `ADR-0100`「修仙是残酷的攀登，境界越高画面越沉」与三篇章即三次境界攀登的结构。代价 = `CharacterData` 一格 + 一个内嵌 `Resource` + 三条加载期校验 + ViewModel 回落多一级 | 全量 **×4**；**MVP 只需 ×2**（MVP = 炼气 → 筑基一个篇章） |

**推荐：B（换），但按稀疏形态落、且内容侧不承诺首发即出满四档。**

**理由（四条，逐条对上既有设计）：**

1. **它是四类挂载面里唯一有真实境界维度的那一个**，而且它的境界**已经在存档里**（`CharacterProfile.realm`）——形态 2 的实现成本是全库最低的一档：一格字段 + 一个两字段的内嵌 `Resource` + 三条校验，零存档影响、零后端配合、零迁移。
2. **量级落在最小的类目上。** 角色池是内容类型里条目数最小的之一（每个角色自带一个神通 + 两门绑定功法，逐个手工编排），而卡牌 / 敌人 / 事件三个类目一律不受影响。**MVP 阶段只涉及炼气 → 筑基两个境界**，首发增量是 ×2 而非 ×4。
3. **稀疏形态使 B 不是一次性承诺，而是一条随时可用可不用的挂点。** 空数组 = 全程用基础形象（R-3 不告警），内容侧可以先出一套、末段逐档补——这正是 `vision/scope.md`「架构中**始终为美术保留可轻松替换 / 定制的挂点**」与 `ADR-0006`「美术挂点占位、末段替换」写的那件事。**选 B 的实际近期成本接近零**，它买的是「日后想做时不必改结构」。
4. **突破是本作唯一一个"进程被兑现"的时刻。** 三个篇章各以一次 Finale 收口、胜则境界突破并落存档点、败则角色当场终结（`systems/game-progression.md`）——这是整个 roguelike 循环里最重的一个节拍，而目前它在视觉上**没有任何兑现**（战斗屏主视觉是道念对比、地图三章共用同一张图、敌人不随境界换相）。若一处都不做，「残酷的攀登」这条支柱在画面上完全落空。

**选 A 的正当理由（如实列出）：** 若判断美术产能是当前最紧的约束、或角色池将来会开得较大（每多一个角色多三张图），A 是**完全安全**的选择——因为形态 2 是纯加法，A 不关闭任何门。**两个选项的差别只在「现在写不写这一格」，不在「日后能不能做」。**

→ **已裁决（2026-08-28 · 批量评审）：选项 B —— 换，按稀疏 `RealmArtwork` 落。**

连带确定（来自同批其余两份草稿的裁决，提炼时须一并读入）：

- **资产总量已可算出。** 同批 `solution-draft-character-template-pool.md` 裁定**首批角色池 = 4 个**（且为全池指定，不抽候选）⇒ 全量立绘 **4 × 4 = 16 张**，**MVP（炼气 → 筑基）只需 4 × 2 = 8 张**。稀疏形态使「先出基础一套（4 张）、末段逐档补」成立，故首发下限仍是 4 张。
- **建议 1 / 2 / 3 随本裁决一并采纳**（`Artwork` 共有字段基数保持单格 · 敌人与其余五类不随境界换相 · 境界维度只落 `CharacterData` 自有字段）⇒ **`systems/common-properties.md:247` 的 ⚠ 行可删、`Artwork` 一节无须重做、第一批 `.tres` 不受影响，derive 顺序第 1 步的最后一件前置就此解除。**
- **前置依赖 4 已关闭。** 同批 `solution-draft-client-flag-cache-and-binary-overlay.md` 裁定**二进制资产不经 overlay / blob 下发** ⇒ `RealmArtwork` 的多张立绘随版本发布，与本方案「换的是引用不是二进制」逐字相容，无矛盾。
- **张力 ① 仍待落笔时处置**（`art-direction.md` / `ADR-0100`「境界越高画面越沉」的适用口径限定）——本次未裁，按草稿建议的「收窄为按条目自身的叙事定位」交 `/analyze-new-ideas` 落笔，若用户届时另有取向可覆盖。

---

> **本文件是提案，不是定案。** 评审后请运行
> `/analyze-new-ideas game-design-documents/inbox/solution-draft-realm-progression-artwork-basis.md`
> 以提炼进主题文档、并把该问题移出待答清单。
