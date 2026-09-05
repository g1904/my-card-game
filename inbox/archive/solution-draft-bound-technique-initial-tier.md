---
type: solution-draft
date: 2026-09-01
question: 角色起手绑定的那两门功法各处于第几层 —— 恒为 1，还是可由内容侧逐条编排？
source: open-questions/06-meta-progression.md → 「两门绑定功法的初始层数（08-30 新增）」
targets: systems/character-profile/_index.md（`CharacterData` 字段表第 8 行 · 「明确不带的格」一条）· systems/character-profile/deck/_index.md（构筑变更一节的一句推论）· content/_index.md（`character/` 行的就绪度备注）
status: distilled
reviewed: 2026-09-02 批量评审 —— 取选项 A：初始层数恒为 1、`CharacterData` 不加字段；逐条编排作为纯加法退路写下、首批不做。
distilled-to: handoffs/2026-09-02-bound-technique-initial-tier.md
---

# 方案草稿 — 两门绑定功法的初始层数

## 问题

`CharacterData` 字段表第 8 行至今写作 **⟨待定⟩**：

> 绑定功法的初始层数 —— 全库尚无明文说明两门绑定功法开局各处于第几层（是否恒为 1、是否可逐条编排）。取值定下前 `content/character/` 的条目写不到 `ready`。

它卡住的是**内容层的开张**：`content/_index.md` 的 `character/` 行标 🟠，理由之一即本条；`/assess-derive-readiness` 亦明写它**不阻塞 schema 与加载期校验的 derive**（第 5 步照常走），只阻塞条目编写。

换句话说：这是一条**内容侧编排口径**的空白，不是结构空白 —— 只要选定其中一支，字段面要么零增量、要么是一次纯加法的类型替换。

## 约束（来自既有设计）

1. **`LearnTechnique` 的入组层数已明文恒为 1。** `DeckChangeElement` 五个 `Op` 中：`LearnTechnique`（入组，**`Tier = 1`**）· `UpgradeTechnique`（`Tier` = 目标层数，不是增量）。→ `deck/_index.md`
2. **开局底盘 = 2 个角色绑定功法 + 1 个选来的功法 + 1 件选来的法宝**，其中「选来的那一门」经**闭关三选一同一条链**入组 ⇒ 它恒为第 1 层。→ `deck/_index.md`「开局构筑 = 一个强制的 buff 事件」
3. **层数 `TechniqueTier` 是严格升级**：层数提升即把该功法整组卡牌替换为更强的一版，同一门功法的高层在任何构筑里都强于低层。**每层对应一整套卡牌定义**，内容成本 = 每门功法 × 每层各一套。→ `deck/_index.md`
4. **`MaxTier` 的取值本身仍待答**（功法规模参数，留待内容扩充后的统计校准）。→ `open-questions/01-combat.md`「内容与数值的残留」
5. **存档侧的载体已定且已够用**：`TechniqueEntry(TechniqueId, Tier)`，`Tier >= 1`，读档校验 `Tier < 1 → PushError`。`CharacterData` 是**静态模板、不落存档**，存档侧只有 `CharacterProfile.characterDataId` 一格。→ `character-profile/_index.md`
6. **灵根的唯一规则后果是硬性修习准入，刻意不碰强度**：角色差异被**有意**推向「能修哪一路功法」，而不是「谁更强」。→ `character-profile/_index.md`「灵根」段
7. **已登记的一条同族风险**：全池指定 + ch1 无限重试下，**角色强度差有可能塌缩为「只有一个角色被玩」**（`open-questions/06-meta-progression.md` 上的一条独立待答项，标注「待实测」）。
8. **`CharacterData` 字段表的既定风格是「能不带的格就不带」**：`Rarity` / `ExclusiveSource` / 任何解锁条件字段都被显式列进「明确不带的格」并各附理由。

## 建议方案

### 子项 1 —— 恒为 1，`CharacterData` 不加任何字段

`[既有推演]`

**推荐取「两门绑定功法开局恒为第 1 层」，并把它写成明文，而不是留一格可编排的数字。** 四条依据：

- **① 它是「入组」的唯一既定语义。** 约束 1 已把 `LearnTechnique` 的入组层数钉为 1；绑定功法是角色开局时进入卡组的功法，与闭关 / 商店学到的那一门在卡组里是同一种东西（同一个 `TechniqueEntry`、同一条 `DeckElements` 通道）。给它第二套入组规则等于让「一门功法怎么进卡组」有两个答案。
- **② 开局底盘的三门功法层数因此一致。** 约束 2 已钉死其中一门恒为 1；若另两门起手 ≥2，玩家的第一屏构筑里就出现「同为开局给的功法，两门比第三门强一档」这种无从解释的落差，而卡面上层数是可见的（进化 = 整组替换，牌面直接变）。
- **③ 它避开一条与既定取向相反的强度轴。** 约束 6 明写角色差异被有意推离「谁更强」；起始层数逐条编排恰恰是一条**纯强度**的角色间差值，且与约束 7 那条已登记的「角色强度塌缩」风险直接叠加放大 —— 在零内容条目、道念量纲未定的当下把它打开，是给一条已知风险再加一个未标定的输入。
- **④ 它不与未定的 `MaxTier` 纠缠。** 约束 4 未定 ⇒ 逐条编排此刻**定不出取值**（起始层数的上界就是 `MaxTier`），只能定结构、把取值继续挂待定，问题实质上不收口；而恒为 1 对任何 `MaxTier` 取值都成立。

**字段面：零增量。** `CharacterData.TechniqueIds : string[]`（长度恒 2）保持原样；`content/character/` 的条目只写两个功法 `Id`，不写层数。

**加载期校验：零新增。** 存档侧既有的 `Tier < 1 → PushError`（约束 5）已覆盖；模板侧没有可填错的格。

**存档 / 后端：零影响。** `CharacterData` 是静态模板、不落存档、不进上行负载 ⇒ 不 bump `schemaVersion`、无迁移、后端零配合。

### 子项 2 —— 把「恒为 1」写成明文，而不是留白

`[通行做法]`

在 `CharacterData` 字段表第 8 行的位置**删去 ⟨待定⟩ 行**，改为在其下「明确不带的格」一条内追加（与 `Rarity` / `ExclusiveSource` 同款写法）：

> **绑定功法的初始层数** —— 恒为 1，与 `LearnTechnique` 的入组层数同款，故不设字段。逐条编排会给角色之间再添一条纯强度轴，与「灵根把差异推向能修哪一路、不推向谁更强」相抵。

并在 `deck/_index.md`「轮回中的构筑变更」一节补一句推论：

> **角色绑定的两门功法同样以第 1 层入组** —— 开局底盘的三门功法（2 绑定 + 1 选来）起手层数一致。

留白与写明的差别在于：留白时第一个写 `content/character/` 条目的人会自己发明一个口径，而本库对这类事的既定处置是「写下来，使日后有章可循」。

### 子项 3 —— 日后要开的最小路径（写下来，但首批不做）

`[既有推演]`

若日后确要逐条编排，**最小路径已知且是纯加法**，把它写进文档使今天的不做不构成明天的债（与 `Affinity` 的「日后若要做成轮回内可变，最小路径已知」同款处置）：

```csharp
// CharacterData 上：string[] TechniqueIds  →  BoundTechnique[] BoundTechniques（长度恒 2）
[GlobalClass]
public partial class BoundTechnique : Resource
{
    [Export] public string TechniqueId { get; set; } = "";
    [Export] public int    InitialTier { get; set; } = 1;   // 默认 1 = 与今天的口径等价
}
```

- 配三条加载期校验：`TechniqueId` 解析不到 → `PushError`（**即既有校验 2 的平移**，不是新账）· `InitialTier < 1` → `PushError` · `InitialTier > 该功法 MaxTier` → `PushError`，带 `characterId` + 功法 `Id` + 两个值。
- **仍是零存档增量**（模板静态字段），代价只在改 `.tres` 结构与那一行字段表。
- 集合字段名取复数 `BoundTechniques`、元素类型名取单数 `BoundTechnique` —— 沿用 `RealmArtworks` / `RealmArtwork` 与 `EnemyData.Lines` / `EnemyLine` 的既定命名纪律（同名会遮蔽类型）。

## 具体形态（可 derive 的落地面）

| 项 | 推荐方案（恒为 1） | 备选（逐条编排） |
|---|---|---|
| `CharacterData` 字段 | **无新增**；`TechniqueIds : string[]`（长度恒 2）不动 | `BoundTechniques : BoundTechnique[]`（长度恒 2）替换 `TechniqueIds` |
| 类型 / 默认值 | — | `InitialTier : int`，默认 `1` |
| 加载期校验 | **零新增** | 三条（见子项 3） |
| 存档 schema | 零增量、不 bump、无迁移 | 同左（模板静态字段） |
| 内容条目要填什么 | 两个功法 `Id` | 两个功法 `Id` + 各自起始层数 |
| 阻塞面 | **当场解除**：`content/character/` 可写到 `ready` | 仍阻于 `MaxTier` 取值（起始层数的上界） |

**derive 侧：** 推荐方案对 `/derive-requirements` 第 5 步（两层 Profile schema 地基）**零影响** —— 该步本就不含本条；解除的是 `content/` 侧 `character/` 类型的开张闸（`/scaffold-content-type character` → `/author-content`）。

## 后果

- 受影响文档：`character-profile/_index.md`（字段表第 8 行 → 「明确不带的格」）· `deck/_index.md`（一句推论）· `content/_index.md`（`character/` 行的就绪度备注从「+ 绑定功法初始层数待定」删去，仍阻于功法与神通条目）。
- 存档 / 后端：**零影响**。
- 内容编排：五个角色的 `.tres` 各少填一格；每门绑定功法的**第 1 层那一套卡牌定义必然被使用**（首玩即见），不产生「写了但没人见得到」的死内容 —— 起手 ≥2 时，被跳过的低层套只有在敌人（`Pool == Both` 且被 `EnemyData` 引用）或另一角色也修同门时才会露面。
- 玩法：**「第一次升阶」的正反馈落在 ch1 内**，且每门绑定功法的可升空间 = 完整的 `MaxTier − 1` 级，不被起手层数预先吃掉一段。
- **本条不解决** `open-questions/06-meta-progression.md` 上「角色强度差是否塌缩为单一最优」那条 —— 它待实测；本方案只是不给它再加一个输入。

## 备选方案（已考虑并否决）

- **逐条编排起始层数（`InitialTier` 一格）** — 否决理由见子项 1 的四条；其中④是当下的硬阻：`MaxTier` 未定 ⇒ 取值定不出来，问题不真正收口。**但它在结构上是纯加法，日后可开**（子项 3）。若用户认为「起手层数」是角色辨识度的必要一维，这一支仍开着，见「仍需用户决定」。
- **恒为 1，但给某个角色的某一门开一次性例外（内容侧特判）** — 否决：与「不做『首局跳过选择』的特判，特判会造出两条起手路径」同一条纪律；一个例外就要求字段面先存在，等价于选了逐条编排。
- **让起始层数随篇章 / 境界浮动（ch2 起手更高层）** — 否决：ch1 是唯一的起手点（ch2 / ch3 由**篇章继承**而来，不重新起手），这一支没有作用对象；且它会把 `TechniqueTier` 与 `realm` 两条纵轴耦合，而层数已明文与境界 `level` 刻意可分（定名纪律）。
- **把初始层数挂在功法条目上（`CultivationTechniqueData.DefaultInitialTier`）** — 否决：同一门功法可被多个角色绑定、也可被闭关学到（那一路恒为 1），挂在功法上会与 `LearnTechnique` 的明文冲突，并制造第二权威。

## 与既有决策的张力

**无。** 推荐方案与 `ADR-0054`（功法 = 卡组构筑单位）、`ADR-0055`（角色 = 内容模板）、`ADR-0123` 及 `LearnTechnique` 的既定语义完全同向；它不要求任何既有条目松动，只是把一处留白按既有语义补齐。

## 前置依赖

- **推荐方案（恒为 1）：无前置。** 它对任何 `MaxTier` 取值都成立。
- **备选方案（逐条编排）：依赖「功法的规模参数」中的 `MaxTier` 取值**（`open-questions/01-combat.md`「内容与数值的残留」，留待内容扩充后的统计校准）—— 起始层数的合法上界就是它，`MaxTier` 定下之前只能定结构、不能定取值，本条的阻塞面不会真正解除。
- 无论走哪一支，`content/character/` 条目写到 `ready` **仍另阻于**：功法条目（10 门）与神通条目（5 个）尚不存在（`content/_index.md` 的 `character/` 行明写）。**本条只解除三个前置里的一个。**

## 仍需用户决定 → **已全部裁决（2026-09-02 · 批量评审）**

1. **起始层数：恒为 1（推荐）vs 由内容侧逐条编排。**
   - **选项 A —— 恒为 1，不加字段（推荐）。** 后果：五个角色的起手差异只由「哪两门功法 + 哪个神通 + 哪个灵根」承担，不叠数值轴；`content/character/` 当场可写到 `ready`（就本条而言）；第一层卡牌定义必被使用；日后要开是纯加法（子项 3），零存档代价。
   - **选项 B —— 逐条编排（`BoundTechnique.InitialTier`，默认 1）。** 后果：角色辨识度多一维（「这个角色一上来就有一门修到二层的功法」是可感知的身份表达）；代价是它成为一条**纯强度**的角色间差值，与「灵根把差异推向能修哪一路」的既定取向相反，且与已登记的「角色强度可能塌缩为单一最优」叠加；内容成本上升（被跳过的低层套可能无人见得到）；**并且它此刻定不出取值**——上界 `MaxTier` 仍待答，本条的阻塞面因此不会真正解除。
   - **推荐 A**，理由是约束 1 / 2 的明文与约束 4 的时序：A 现在就能收口、B 现在收不了口，而 B 的门在 A 之后仍然开着（纯加法、零存档迁移）。
   - → **已裁决（2026-09-02 · 批量评审）：选项 A —— 恒为 1，`CharacterData` 不加字段。** 逐条编排的纯加法退路（`BoundTechnique.InitialTier`）保留在子项 3 作为日后可开的门，本次不实现。
