---
type: solution-draft
date: 2026-08-18
question: (a) `CostKey` 资源族 element 的完整成员清单是什么？(b) `StatKey` 的完整成员清单与增长登记方式，以及它在书写上如何与 `CostKey` 明确分开？
source: open-questions.md（derive 就绪度全局结论「🟠 半处 — `CostKey` 资源族 element 清单」）· open-questions/01-combat.md（「`StatKey` 的完整成员清单」）· systems/services/profile-service.md#待决问题 · systems/player-profile/_index.md#待决问题 · systems/architecture.md#待决问题
targets: systems/architecture.md（`CostKey` / `StatKey` 枚举声明 + `ResourceElements` 注释块）· systems/services/profile-service.md（`ResourceElements` 表 + 两条待决项移出）· systems/player-profile/_index.md（`PlayerStatistics` + `StatKey` 待决项移出）· systems/character-profile/_index.md（两张字段表的「写入通道」列）· systems/services/sync-service.md（枚举名冻结纪律的一处引用）
status: distilled
reviewed: 2026-08-19 — 用户逐条裁决完毕（取向零剩余）；批量提炼时的合并 interview 另有 48 项裁决，全部取推荐项
distilled-to: handoffs/2026-08-19-costkey-statkey-registry.md
---

# 方案 — `CostKey` 资源族 element 清单 与 `StatKey` 成员清单 / 两者的书写分野

## 问题

两条紧耦合的待答项，一并推演：

**(a) `CostKey` 资源族 element 清单未定（承重）。** `ProfileChangeSpec.Elements` 装「带符号的资源量」，每个成员在 `ResourceElements` 表里占一行（取值域 / 终态 / 两向修正准入 / `AllowedOps`）。能力族（`AbilityChangeElement`，三个 `Op`）与统计族（`StatDelta`）已闭合，**只剩资源族这一半**。它卡住 `systems/services/profile-service.md`（blocked）与 `systems/architecture.md`（partial）的 `TryApply` 形状面 —— 后者的 derive 就绪台账明写「只取骨架切片，不取 `CostKey` 资源族相关面」。

**(b) `StatKey` 的完整成员清单未定（轻）。** 首批两项已定（`CyclesCompleted` / `CyclesDefeated`），但**随统计项增长的命名与登记方式**、以及**如何在书写上与 `CostKey` 明确分开**未定。它是 `systems/player-profile/_index.md` 从 blocked 升 partial 后仍卡住的四项之一。

**两条为什么必须一起答：** (b) 的核心难点正是「与 `CostKey` 的书写分野」，而分野规则只有在 (a) 的成员清单落定后才能被验证是否真的可机械检查 —— 两个枚举的成员名空间是否相交，要有两份完整清单才看得出来。

## 约束（来自既有设计）

**硬边界（方案不得违反）：**

1. **成员清单必须与已逐格定案的字段表严格对齐，不得凭空发明标的。** `CharacterProfile` 23 字段 + `Status` 12 格、`PlayerProfile` 15 字段均已定案并逐格标注了「写入通道」列（`systems/character-profile/_index.md`、`systems/player-profile/_index.md`）。**资源族的成员数 = 标注为 `Elements` 的字段数**，这是一个可穷举的封闭集合，不是一个开放的设计题。
2. **`ResourceElements` 是封闭表，启动期断言覆盖 `CostKey` 全部成员**；缺行 = 取值域 / 终态 / 修正准入三者皆不明 → `PushError` + 整批拒绝（`profile-service.md`）。
3. **`AllowedOps` 含 `Set` 的行，两个修正列必须恒为 `null`**（启动期断言）；每行 `AllowedOps != 0`（同上）。
4. **两个修正列是 opt-in 白名单、缺省豁免**；`Op == Set` 恒不经 modifier pipeline（`architecture.md`「共享核心类型」）。
5. **枚举值序列化与 C# 枚举名逐字相同**（`systems/services/sync-service.md`）⇒ **`CostKey` / `StatKey` 的成员名是存档与上行契约的一部分**，重命名即破坏性变更。`Source` 是这条通则唯一的记名例外（上行走名、存档走整数 code）。
6. **两层通则**（`player-profile/_index.md`）：规则字段层 = 被任何判定 / 闸门 / 幂等键读取，严格同步、后端可复算；统计计数层 = 只被 UI 读来展示，宽松同步。**依赖方向单向**，统计层绝不可被规则读取。
7. **命名硬约定（可机械检查）**（同上）：后缀 `Ordinal` ⇒ 规则字段层；前缀 `Total` / 后缀 `Count` ⇒ 统计计数层；规则层的「数量」用后缀 `Used`；**统计计数层禁用 `Ordinal` 后缀**。
8. **三级判据**（`architecture.md`「一个新的施加语义该落在哪里」）：分列 / 加 `Op` / 配表加列，取第一个成立的落点。
9. **具名字段而非字典 / 索引数组**（`chapterRetry` 三字段 · 三个 band · 六个 Codex · `PlayerEntitlement` 的先例）：篇章数是固定的游戏结构，字典只换来一层查找与一处可空。

**本方案不触碰的三处（另有专场 / 另有 worker）：** `activeCombat` 的写入通道 · RNG `State` / `DrawCount` 的写入通道 · `pastEvent` 的追加通道，以及 `Project(spec)` 的语义面。它们是**列结构**问题，本方案是**列内成员**问题（见 `## 前置依赖`）。

---

## 建议方案

### 一、方法：清单不靠枚举「想得到的资源」，靠对字段表做一次穷举核对

`[既有推演]`

`CostKey` 的成员**不是一个开放的设计选择**——`ProfileChangeSpec.Elements` 的唯一职责是写 Profile 上的资源型字段，而两层 Profile 的字段表已逐格定案并标注了写入通道。因此正确的推演方式是**反向枚举**：遍历两张字段表，取出所有「写入通道 = `Elements`」的格子，每一格恰好对应一个 `CostKey` 成员；清单闭合的判据是**这个映射双向满射**（每个成员有一个标的字段，每个标注为 `Elements` 的字段有一个成员）。

这次穷举的结果见下节。它同时产出了一条**本次发现的真实缺口**（两个已定案字段没有任何 `CostKey` 承载，见 §二.3），这正是穷举法相对「列举想得到的资源」的价值。

### 二、`CostKey` 资源族的完整成员清单（建议 15 个成员）

#### 1. 轮回层 · `CharacterProfile`（7 个 · 全部已声明，无新增）

`[既有推演]`

穷举 `CharacterProfile` 的 23 字段 + `Status` 12 格：标注为 `Elements` 的恰好是 **`jade` + `Status` 的前六格**，共 7 个 —— 与 `architecture.md` 当前已声明的 7 个 `CostKey` 成员**逐一对应、无缺无余**。

**推论（承重）：轮回层的资源族此刻已经闭合，本次一个成员都不加。** 之所以这条待答项仍挂着「承重」，是因为它的**未闭合部分全在账号层**（`PlayerProfile`），而字段表登记「写入通道 = `Elements`」的那两个具名子类从未被搬进 `ResourceElements` 表 —— 见下两节。

| `CostKey` | 标的字段 | Min | Max | 归 Min 时 | `CostModifier` | `GainModifier` | `AllowedOps` | 状态 |
|---|---|---|---|---|---|---|---|---|
| `LifeSpan` | `Status.lifeSpan` | 0 | 无 | **终态** `LifeSpanExhausted` | `LifeSpanCost` | `null` | `Add` | 已在表内 |
| `Jade` | `jade`（顶层） | 0 | 无 | 无 | `null` | `null` | `Add` | 已在表内 |
| `LifeTotal` | `Status.lifeTotal` | 0 | 无 | **终态** `LifeTotalExhausted` | `null` | `null` | `Add` | 已在表内 |
| `ManaLimit` | `Status.manaLimit` | 0 | 无 | 无 | `null`（硬要求） | `null`（硬要求） | `Add`（`Set` 恒不开） | 已在表内 |
| **`ExperiencePoint`** | `Status.experiencePoint` | 0 | 无 | 无 | `null` | `null` | `Add` | **建议由 `Experience` 改名** |
| `Faith` | `Status.faith` | 0 | 100 | 无 | `null` | `null` | `Add` | 已在表内 |
| `Bloodlust` | `Status.bloodlust` | 0 | 100 | 无 | `null` | `null` | `Add` | 已在表内 |

- **改名 `Experience` → `ExperiencePoint`** `[既有推演]`：它是全表**唯一**一个成员名与标的字段名不一致的行（其余六行逐字对齐：`lifeSpan`↔`LifeSpan`、`jade`↔`Jade`、`lifeTotal`↔`LifeTotal`、`manaLimit`↔`ManaLimit`、`faith`↔`Faith`、`bloodlust`↔`Bloodlust`）。对齐后 §四的「key 名 ⟸ 字段路径」规则才是**无例外**的，而无例外正是它能被机械检查的前提。**成本此刻为零**（无线上存档），窗口在写下第一批存档时关闭 —— 与 `LocalizedText` / `DrawPool<T>` / `CodexEntry` 是同一类窗口判断。
- 六行的取值域 / 终态 / 修正列**原样沿用既有裁决**，本方案不改一格；理由分别在 `life-total.md` / `mana.md` / `currency.md` 与 `profile-service.md` 各行的「依据」列，此处不复述。

#### 2. 账号层 · `PlayerProfile.playerPowerFragment`（7 个字段 → 7 个成员）

`[既有推演]`

`PlayerProfile` 字段表第 13 行 `playerPowerFragment`（`PlayerPowerFragment`，**7 字段**）写入通道明写为 `Elements`。但 `profile-service.md` 的 `ResourceElements` 表只登记了其中 **3 个**（`PowerFragmentAccumulated` / `PowerFragmentWinOrdinal` / `PowerFragmentFirstWin(chapter)`），且其中一个的形态还是 `⟨未定⟩`。**建议按「一个字段一个成员」补齐为 7 个**：

| `CostKey` | 标的字段 | Min | Max | `AllowedOps` | 依据 |
|---|---|---|---|---|---|
| `PowerFragmentAccumulated` | `Accumulated` | 0 | 10000 | `Add \| Set` | 万分比累计；每次 Finale 累加 `x`（`Add`）、发放后重置为 `Base(x+1)`（`Set`）。**已在表内，不改** |
| **`PowerFragmentFinaleWinOrdinal`** | `FinaleWinOrdinal` | 0 | 无 | `Add` | 序号自增；**建议由 `PowerFragmentWinOrdinal` 改名**以与字段名对齐 |
| **`PowerFragmentCh1FirstWin`** | `Ch1FirstWinDone` | 0 | 1 | `Set` | 置位；三个具名成员，见下方「参数化 key 的否决」 |
| **`PowerFragmentCh2FirstWin`** | `Ch2FirstWinDone` | 0 | 1 | `Set` | 同上 |
| **`PowerFragmentCh3FirstWin`** | `Ch3FirstWinDone` | 0 | 1 | `Set` | 同上 |
| **`PowerFragmentLastRoll`** | `LastRoll` | 0 | 9999 | `Set` | **本次新发现的缺口**，见下 |
| **`PowerFragmentLastEffectiveChance`** | `LastEffectiveChance` | 0 | 10000 | `Set` | 同上 |

全部七行的两个修正列**恒为 `null`**：它们是残卷的元进程计数与后端复算凭证，经 pipeline = **一条法则能加速自己被获得**（自举回路）或**一条法则能改写反作弊证据**。前者是 `profile-service.md` 已明写的理由，后者是本方案对新增两行的同源推演。含 `Set` 的五行因此自动满足既有的启动期断言（「允许 `Set` ⇒ 两修正列为 `null`」）。

**`PowerFragmentFirstWin(chapter)` 的形态：落三个具名成员，不落参数化 key。** `[既有推演]`
表中该行现写作带参形态且「Min 形态未定」，而 C# `enum` 成员**不能带参数** —— 参数化必然退化为「一个 key + 一个额外的 chapter 载荷格」，那要给 `ChangeElement` 加一个可空字段，正是 `architecture.md` 已明确否决的两个替代之一（「`ChangeElement` 加可空 `TargetId`」）。而存档侧的标的本就是**三个具名布尔** `Ch1/Ch2/Ch3FirstWinDone` —— 与 `chapterRetry` 三字段、三个 band、六个 Codex 同款判据（篇章数是固定的游戏结构，不是可扩展列表）。三个具名成员使 key ↔ 字段仍是一一映射，`ResourceElements` 也无须为「带参 key 怎么查表」开特例。**代价明写：新增篇章要加三个枚举成员 —— 但篇章数不是设计变量**（原话见 `character-profile/_index.md`）。

**⚠ 本次新发现的缺口（承重）：`LastRoll` / `LastEffectiveChance` 没有任何写入通道。** `[既有推演]`
`player-profile/_index.md` 已定案两条**承重的写入约定**：「**每一次** Finale 胜利都掷这一骰并写 `LastRoll`，即使当次不发放」「首胜时 `LastEffectiveChance` 写 `10000`」，并明写「**缺任一条即在正常账号上触发后端风控误报**」。两者同为 `PlayerPowerFragment` 上的只读字段（该类无 setter，字段表写入通道 = `Elements`），却在 `ResourceElements` 表里**没有行** —— 而无行 = `TryApply` 时 `PushError` + 整批拒绝（既有失败语义表最后几行）。**即：按当前两份文档的字面，那次 Finale 收口的 `TryApply` 会被自己拒绝。** 这是一处两份已定案文档之间的真实不一致，不是新设计；补两行即闭合，零结构增量。
- 两者的语义是**赋一个已算好的绝对值**（掷骰原始值 / 当刻生效概率），故 `AllowedOps = Set`，与 `BundleGrantOrdinal` 同款。
- 取值域直接取自字段表已写死的区间：`LastRoll ∈ [0, 9999]`（`AccountRandom.Roll()` 的值域）、`LastEffectiveChance ∈ [0, 10000]`（万分比）。**不是本方案发明的数字。**
- 两者与 `Accumulated` / `FinaleWinOrdinal` / 首胜布尔落在**同一次 `TryApply`**（Finale 收口），既有的「全有或全无」原样成立。

#### 3. 账号层 · `PlayerProfile.entitlement`（1 个成员 · 已在表内）

| `CostKey` | 标的字段 | Min | Max | `AllowedOps` | 依据 |
|---|---|---|---|---|---|
| `BundleGrantOrdinal` | `PlayerEntitlement.BundleGrantOrdinal` | 0 | 无 | `Set` | 付费凭证序号，被赋为预先算好的 `ordinal`；两修正列恒为 `null`（经 pipeline = 一条法则能改写付费凭证）。**已在表内，不改** |

#### 4. 闭合核对：为什么 15 个成员就是全部

`[既有推演]` 把两张字段表逐格走一遍，非 `Elements` 的格子各有已定案的归宿，**没有一格落在资源族而无 key**：

| 归宿 | 字段 | 是否资源族 |
|---|---|---|
| `AbilityElements` | `magicPack` · `characterPower` · `disabledAbility` · `playerPower` · `playerItem` | 否（集合成员操作 · 无量纲） |
| `DeckElements` | `technique` · `looseCard` | 否（带层数的构筑变更 / 多重集） |
| `StatusChanges` | `Status` 后六格（三 band · `ChapterLifeSpanBudget` · `CurrentLocationId` · `LocationEventCount`） | 否（绝对置值 · 另有 `StatusFields` 配表） |
| `PlotElements` | `plotKeyPoint` | 否（按 `ArcId` 的带载荷 upsert） |
| `EventStateChanges` | `eventOption` · `activeEvent` | 否（整块绝对置值） |
| `Stats` | `statistics` | 否（统计层，走 `StatKey`，见 §三） |
| `—`（不经 spec） | `id` · `characterDataId` · `status` · `defeatReason` · `chapter` · `realm` · `level` · `chapterRetry` · 双 `contentVersion` · `accountInfo` · `characterProfile` | 否 |
| **`⟨待定⟩`** | 六个 Codex · `achievement` · `gameSetting` | **否 —— 见下** |
| **未明写（另一 worker）** | `pastEvent` · `activeCombat` · `rng` | **否 —— 见下** |

**两处「未定」不阻塞本清单，理由是它们在形状上都不是资源族：** `[既有推演]`
- **六个 Codex / `achievement` / `gameSetting`** —— 按三级判据的六个面看：Codex 是 `IReadOnlyList<CodexEntry>` 的**集合成员增补**（解锁 = 一次性全量写入、幂等、无量纲、不钳制），形状与 `AbilityElements` 同族而与「带符号的量」正交；`achievement` 同为集合；`gameSetting` 是一组设置项。**三者都不可能变成 `CostKey` 成员**，故它们的写入通道无论最后落在哪一列，都不会往资源族里加成员。
- **`pastEvent` / `activeCombat` / `rng`** —— 前二者是结构块（`PastEventEntry` / `ActiveCombat`），`rng` 是 `RngState` 子类下的 `State` / `DrawCount`。三者都**没有量纲、不钳制、不构成终态、恒不走 modifier pipeline**，与 `EventStateChanges` 的「整块绝对置值」在六个面上对齐，与 `Elements` 不对齐。**它们要的是一列，不是一个 key** —— 这正是它们被单列为「有纪律、无通道」缺口的原因。

**推论（本方案的主张）：资源族清单可在这三处未决项之前独立闭合。** 这一条正是把 `profile-service.md` / `architecture.md` 从 blocked / partial 解锁所需要的东西。

#### 5. 新增一个资源 element 的完整动作清单（可加性）

`[既有推演]` 日后新增一个资源型字段时，**恰好五步、不多不少**：① Profile 上加字段（只读、无 setter）+ 更新该库字段表的写入通道列 → ② `CostKey` 加一个成员（名 ⟸ 字段路径，见 §四）→ ③ `ResourceElements` 加一行六列 → ④ bump 存档 schema 版本（老档补默认值）→ ⑤ 若该行含 `Set`，两修正列必须留空（已有断言兜底）。**不新增服务、不改任何调用方** —— 这正是 `profile-service.md`「可加性」那条所承诺的形态，本清单把它落成了可照做的步骤。

---

### 三、`StatKey` 的成员清单与增长时的登记方式

#### 1. 成员清单 = 首批两项，与字段一一对应（建议改名对齐）

`[既有推演]` `PlayerStatistics` 明写「**首批就这两项**」，且「统计层新增字段的成本近乎为零……故首批清单的价值在于**小而无歧义**」。故本方案**不扩充清单**，只处理它的形态：

| `StatKey` | 标的字段 | 语义 | 状态 |
|---|---|---|---|
| **`TotalCyclesCompleted`** | `PlayerStatistics.TotalCyclesCompleted` | 通关（三篇章全通 · 抵达元婴）的轮回数 | **建议由 `CyclesCompleted` 改名** |
| **`TotalCyclesDefeated`** | `PlayerStatistics.TotalCyclesDefeated` | 以 `defeated` 收场的轮回数 | **建议由 `CyclesDefeated` 改名** |

**改名的三条理由，逐条对上既有纪律：**
- **既有的命名硬约定说「前缀 `Total` / 后缀 `Count` ⇒ 统计计数层」，且它的全部价值是「可机械检查」。** 当前的 `StatKey.CyclesCompleted` 既无 `Total` 也无 `Count`，**恰好是这条约定管不着的形态** —— 于是「一个裸 key 名属于哪一层」重新退化为「要读上下文」，正是那条约定明写要避免的降级。
- **key 名 ⟸ 字段名逐字对齐**，与 §四的规则统一，使双向覆盖断言（见下）写得出来。
- **成本此刻为零。** `StatKey` 经 `StatDelta` 落进 `ProfileChangeSpec`，而 `ProfileChangeSpec` 是 `PastEventEntry.AppliedChange` 的类型 ⇒ **它落存档**，且按 sync-service 的通则「枚举值序列化与 C# 枚举名逐字相同」⇒ **改名日后即破坏性契约变更**。当前无线上存档，窗口开着；写下第一批存档即关闭。

#### 2. 增长时的登记方式：三步 + 一条双向断言，**不建配表**

`[既有推演]` 新增一个统计项：① `PlayerStatistics` 加一个只读字段（名必须带 `Total` 前缀或 `Count` 后缀）→ ② `StatKey` 加一个**同名**成员 → ③ 无需迁移（老档缺字段 → 0，宽松同步口径）。

**明确不给统计族建 `StatFields` 配表** —— 这是与资源族最重要的一条形态差异，也是「书写分野」的实体载体：

| `ResourceElements` 的列 | 统计层的取值 | 
|---|---|
| `Min` / `Max` | **不钳制**（读档越界只告警不修复） |
| `DepletionDefeat` | 统计层**不构成任何终态** |
| `CostModifier` / `GainModifier` | **恒不走 modifier pipeline**（一条法则能改写统计数字） |
| `AllowedOps` | 只有一种施加方式（`StatDelta` 是纯自增，无 `Op` 维度） |

**六列逐列为空 ⇒ 建表等于建一张全空表。** 反过来说：**「有没有配表」本身就是两族的第一条可机械核对的分野** —— 一个 key 若需要说清取值域 / 终态 / 修正准入，它按定义属于资源族。

配套的可执行化手段是一条**启动期双向覆盖断言**（纪律阶梯第 3 级，与「表覆盖 `CostKey` 全部成员」同档）：`StatKey` 的每个成员在 `PlayerStatistics` 上有同名字段，且每个字段有同名成员。它替代配表，成本一行反射遍历、只在 `#if DEBUG` 生效。

#### 3. 未知 `StatKey` 的宽松口径不变

`[既有推演]` 既有裁决原样保留：未知 `StatKey` → `PushWarning` + 跳过该条，**不影响同批其余变更**（宽松同步口径五条之一）。它与资源族「缺行 = `PushError` + 整批拒绝」形成**两族第二条可机械核对的分野**（见 §四表）。

---

### 四、`CostKey` 与 `StatKey` 在书写上的分野规则

#### 1. 一句话判据（不是新判据，是既有两层通则的复用）

> **这个数会被规则 / 闸门 / 幂等键读吗？** 会 → `CostKey`（进 `Elements`）；只被 UI 读来看 → `StatKey`（进 `Stats`）。

`[既有推演]` 这与 `player-profile/_index.md`「账号级字段分两层，判据是『它有没有被规则读』」**逐字同源** —— 本方案不引入第二条判据，只指出**元素键的分野就是字段分层的投影**：`CostKey` 是规则字段层的键，`StatKey` 是统计计数层的键。既有的「展示不改变分层」推论同样原样适用（被 UI 读到不会把 `CostKey` 变成 `StatKey`）。

#### 2. 命名词缀规则（把分野做成可机械检查）

`[既有推演]` 直接承接既有的命名硬约定，只是把它从「字段名」扩到「元素键名」：

| | `CostKey` | `StatKey` |
|---|---|---|
| **必须** | 无 | 带 `Total` 前缀 **或** `Count` 后缀 |
| **允许** | `Ordinal` 后缀（位置 / 幂等键）· `Used` 后缀（规则层的数量） | 无其他 |
| **禁用** | `Total` 前缀 · `Count` 后缀 | `Ordinal` 后缀 · `Used` 后缀 |

**⇒ 两个枚举的成员名空间在构造上不相交**：读到任意一个裸 key 名，**不查任何文档**即可判断它属于哪一族。核对当前 15 + 2 个成员：`CostKey` 侧无一个带 `Total` / `Count`（含改名后的 `ExperiencePoint` / `PowerFragmentFinaleWinOrdinal`）；`StatKey` 侧两个都带 `Total`（改名后）。**规则成立且当前零违例。**

#### 3. key 名 ⟸ 字段路径（第三条对齐规则）

`[既有推演]` **key 名 = 标的字段在存档树上的可辨识路径的 PascalCase 拼接**：字段落在 profile 顶层或 `Status` 上 → 裸字段名（`Jade` · `LifeSpan` · `ExperiencePoint`）；落在具名子类上 → 视裸字段名是否全局自明决定是否加容器前缀（`PowerFragmentAccumulated` 需要前缀，`Accumulated` 单独看不出是什么；`BundleGrantOrdinal` 不需要，它本身已自明）。

**这一条明确标注为「约定」而非「可机械检查的规则」** —— 「是否自明」需要人判断。**代价如实写下：它靠评审（纪律阶梯第 4 级）。** **已定案：不抬到第 3 级**——`ElementSpec` 保持六列，不加 `TargetPath`，见 `## 用户裁决（2026-08-19 · 全部定案）` 第 4 项。

#### 4. 分野的主体保障已经在第 1 级 —— 词缀规则只防「读错」，故第 3 级足够

`[既有推演]` 按纪律阶梯的两条选级判据核对：**把一个 `StatKey` 塞进 `ChangeElement`、或把 `CostKey` 塞进 `StatDelta`，在语言层就写不出来**（两个独立 `enum` × 两个独立 record struct × 两个独立列表）—— 这是**第 1 级**，无需任何额外手段。词缀规则要防的是**另一件事**：新增一项时**放错枚举**（把一个纯读数的计数登记成 `CostKey`，或反之）。这类错误会在开发期显形（错登为 `CostKey` ⇒ 缺 `ResourceElements` 行 ⇒ 启动期 `PushError`；错登为 `StatKey` ⇒ 双向覆盖断言当场失败），**不属于「能上线且线上不可见」**，故第 3 级足够，无须付分析器（第 2 级）的成本。

---

### 五、新增成员时的校验与编译闸

`[既有推演]` 汇总为一张表；**标「既有」的四条本方案不改，只加两条第 3 级断言与一条冻结纪律**：

| # | 手段 | 阶梯 | 覆盖的错误 | 状态 |
|---|---|---|---|---|
| 1 | `ResourceElements` 覆盖 `CostKey` 全部成员 | 3 · 启动期 | 加了成员忘了配行 | 既有 |
| 2 | 每行 `AllowedOps != 0` | 3 · 启动期 | 该 key 没有任何合法写法 | 既有 |
| 3 | 含 `Set` 的行两修正列恒为 `null` | 3 · 启动期 | `Set` 下按符号分向无从判断 | 既有 |
| 4 | 未知 `StatKey` → `PushWarning` + 跳过 | 运行期 | 统计层宽松口径 | 既有 |
| 5 | **`StatKey` ↔ `PlayerStatistics` 字段双向覆盖** | 3 · 启动期 | 加了字段忘了成员 / 反之 | **新增** |
| 6 | **两个枚举的成员名词缀合规** | 3 · 启动期 | 放错枚举 · 词缀漂移 | **新增** |
| 7 | **成员名冻结：只可追加，永不改名 / 复用** | 4 · 评审 + 契约 | 破坏存档与上行契约 | **新增（纪律）** |

**第 7 条的推演** `[既有推演]`：`CostKey` / `StatKey` 都随 `ProfileChangeSpec` 落进 `PastEventEntry.SelectCost` / `AppliedChange`（存档），按 sync-service 的通则以**成员名**序列化 ⇒ 它们与 `SavePointReason` 等跨边界枚举受同一条纪律：**重命名一个成员即破坏性契约变更，必须 bump `schemaVersion` 并与后端同批改**。这条纪律给本方案的三处改名（`Experience` / `PowerFragmentWinOrdinal` / 两个 `StatKey`）划出了明确的执行窗口：**必须在写下第一批存档之前，此后成本从零跳到一次真实迁移**。

**明确不做的一件事：不给 `CostKey` / `StatKey` 分配显式整数 code。** `[既有推演]` `Source` 分配 code 是因为它**在存档里以整数序列化**（名 / code 双轨，是通则的记名例外）；两个 element 键无此包袱，按通则走成员名单轨即可。加一套 code = 加一份要冻结的第二真值，而收益为零。

---

## 具体形态（可 derive 的落地面）

### `systems/architecture.md`「共享核心类型」的枚举声明

```csharp
public enum CostKey                       // 资源族 element 键；15 值，全部在 ResourceElements 表中占一行
{
    // 轮回层 · CharacterProfile
    LifeSpan, Jade, LifeTotal, ManaLimit, ExperiencePoint, Faith, Bloodlust,
    // 账号层 · PlayerProfile.playerPowerFragment（7 字段 ↔ 7 成员）
    PowerFragmentAccumulated, PowerFragmentFinaleWinOrdinal,
    PowerFragmentCh1FirstWin, PowerFragmentCh2FirstWin, PowerFragmentCh3FirstWin,
    PowerFragmentLastRoll, PowerFragmentLastEffectiveChance,
    // 账号层 · PlayerProfile.entitlement
    BundleGrantOrdinal,
}
public enum StatKey { TotalCyclesCompleted, TotalCyclesDefeated }   // 统计族；无配表
```

**⚠ 成员序不构成契约**（两者均按成员名序列化，见 §五第 7 条）；但**成员名构成契约**，只可追加。

### `ResourceElements` 表的新增 / 改动八行

（其余七行原样保留，仅 `Experience` 一行改名）

| `CostKey` | Min | Max | 归 Min 时 | `CostModifier` | `GainModifier` | `AllowedOps` | 依据 |
|---|---|---|---|---|---|---|---|
| `PowerFragmentAccumulated` | 0 | 10000 | 无 | `null` | `null` | `Add \| Set` | 已在表内，不改 |
| `PowerFragmentFinaleWinOrdinal` | 0 | 无 | 无 | `null` | `null` | `Add` | 序号自增；仅改名 |
| `PowerFragmentCh1FirstWin` | 0 | 1 | 无 | `null` | `null` | `Set` | 置位（0/1）；无量纲，修正与 `Add` 皆无意义 |
| `PowerFragmentCh2FirstWin` | 0 | 1 | 无 | `null` | `null` | `Set` | 同上 |
| `PowerFragmentCh3FirstWin` | 0 | 1 | 无 | `null` | `null` | `Set` | 同上 |
| `PowerFragmentLastRoll` | 0 | 9999 | 无 | `null` | `null` | `Set` | 后端逐位复算比对的原始值；经 pipeline = 一条法则能改写反作弊证据 |
| `PowerFragmentLastEffectiveChance` | 0 | 10000 | 无 | `null` | `null` | `Set` | 同上；首胜时写 `10000` |
| `BundleGrantOrdinal` | 0 | 无 | 无 | `null` | `null` | `Set` | 已在表内，不改 |

### 布尔字段以 `int 0/1` 进 `Elements` 的形态说明

`[既有推演]` 三个首胜布尔在存档上是 `bool`，在 `ChangeElement.BaseValue`（`int`）上以 `0 / 1` 承载，`Min = 0 / Max = 1` 由钳制兜住。**这不新增任何结构** —— `profile-service.md` 已把 `PowerFragmentFirstWin` 归入 `Elements` 且 `AllowedOps = Set`，本方案只是把它的取值域填上。**代价明写：**「量」这一列上出现了一个无量纲的 0/1，与 `Elements` 那句「资源是量」有轻微张力（见 `## 与既有决策的张力`）。**已考虑并否决**为它另开一列 `FlagChanges`：按三级判据的六个面核对，它与 `Elements` 在**五个面上全对齐**（要钳制 · `Set` 下不走 pipeline · 失败阻断整批 · `Set` 幂等 · 键与载荷是标量），只在「有无量纲」一面不同 —— 而判据明写「任一既有列在这六面上与新语义**全部**对齐 ⇒ 不分列」的反面是**只差一面不足以分列**，否则每个 `Set` 型标量都要一列。

### 两库字段表的连带更新

- `systems/player-profile/_index.md` 字段表第 13 行 `playerPowerFragment` 的写入通道由 `Elements` 细化为 `Elements`（7 个 `CostKey`），第 12 行 `statistics` 由 `Stats`（`StatDelta`）保持不变但成员名更新。
- `systems/character-profile/_index.md` 两张表的写入通道列**唯一改动**是 `experiencePoint` 行由 `CostKey.Experience` 改为 `CostKey.ExperiencePoint`。

---

## 后果

- **解锁两份 blocked / partial 文档的一半。** `systems/services/profile-service.md`（blocked，四项之一是它）与 `systems/architecture.md`（partial，「其余卡于」第一项就是它）的 `TryApply` 形状面因此可 derive；`open-questions.md` 的全局结论「🟠 半处」中的这一半可移出。**注意：`profile-service.md` 仍被另外三项卡住**（`activeCombat` / RNG / `pastEvent` 三处通道 + `Project(spec)` 语义面），本方案不解锁它们。
- **`systems/player-profile/_index.md` 的四项卡点去掉一项**（`StatKey` 完整成员清单），其余三项（`CodexEntry` schema · `GameSetting` 清单 · `Achievement` schema）不受影响。
- **存档 schema：一次 bump、空迁移。** 三处改名 + 七行新登记均不改变任何字段的形状（`PlayerPowerFragment` 的 7 个字段本就已定案存在），只是补齐它们的写入通道；当前无线上存档 ⇒ 空迁移，走既有 MigrationManager 骨架。
- **后端零配合。** 新增的两个 key（`LastRoll` / `LastEffectiveChance`）对应的字段与 JSON path（`/playerPowerFragment/lastRoll` · `/lastEffectiveChance`）**已经是既有的透明路径**，后端的复算校验口径（`backend-design-documents/contracts/profile-sync.md` §7）不变 —— 本方案补的是客户端**怎么写**它们，不改**写什么**。**故本方案不跨库**（见 `## 前置依赖`）。
- **可加性形态明确化。** §二.5 的五步清单使「新增一种资源 element = 加字段 + 加成员 + 加一行」成为可照做的步骤，兑现 `profile-service.md`「可加性」那条承诺。

## 备选方案（已考虑并否决）

- **`CostKey` 用字符串 key 而非 `enum`** — 否决。与「`CapabilityFlag` 用 `enum` 而非字符串 key」逐字同源：消费点必然是一段代码，字符串只是把「拼错了」从编译期推迟到运行时；且 `ResourceElements` 的查表会失去编译期的成员完备性。
- **`PowerFragmentFirstWin` 用参数化 key（一个成员 + 一个 chapter 载荷格）** — 否决。要给 `ChangeElement` 加一个可空字段，正是 `architecture.md` 已明确否决的替代之一；且存档侧标的本就是三个具名布尔。
- **为三个首胜布尔（及日后的布尔型字段）另开一列 `FlagChanges`** — 否决，理由见上文三级判据核对（只差「有无量纲」一面）。
- **给统计族建一张 `StatFields` 配表以与资源族对称** — 否决。六列逐列为空；`architecture.md` 已明写「**按内容建，不按对称建**」（`common-properties.md` 判据卡的同款措辞）。
- **`StatKey` 成员沿用 `CyclesCompleted` / `CyclesDefeated`（不加 `Total`）** — 否决。理由是它恰好落在既有词缀约定的检查范围之外，使「一个裸 key 名属于哪一层」退化为要读上下文；且改名窗口即将随第一批存档关闭。**它确有「读起来啰嗦」的代价，但已定案取改名，见 `## 用户裁决（2026-08-19 · 全部定案）` 第 2 项。**
- **给 `CostKey` / `StatKey` 分配显式整数 code（仿 `Source`）** — 否决，见 §五末。
- **等 `activeCombat` / RNG / `pastEvent` 三处通道答定后再一并闭合资源族清单** — 否决。§二.4 已论证三者在形状上都不是资源族（要的是一列，不是一个 key），等待只是让两份文档继续 blocked。

## 与既有决策的张力

1. **「`Elements` 装的是**量**」 vs 三个 0/1 首胜标记。** `architecture.md` 描述 `Elements` 为「资源是量（可加、要钳制、按表决定是否走 pipeline）」，而 0/1 置位**无量纲、不可加**。**本方案主张这不构成需要松动的冲突**：该描述是六面判据的一句概括，而判据本身（「任一既有列在六面上全部对齐 ⇒ 不分列」）在此仍成立于五面。**但这一句概括建议顺手改写为更准确的措辞**（如「资源是**标量值**：可钳制、`Add` 时可加且带符号分向、`Set` 时为已算好的绝对值」），否则日后读者会拿它当作「首胜标记放错了列」的依据。**这是措辞层的改动，不是决策层的松动。**
2. **`FinaleWinOrdinal` 走 `Add`、`BundleGrantOrdinal` 走 `Set`，两个形状相同的序号取了不同的 `Op`。** 既有表已如此登记，各有理由（残卷序号由客户端自增；礼包序号是后端验票后拿到的已算定绝对值）。**该不对称已随 `BundleGrantOrdinal` 整行撤下而消解**（后端唯一 `+1`，它不再是 `CostKey` 成员），表内只剩 `FinaleWinOrdinal`，无需再写那行理由。见 `## 用户裁决（2026-08-19 · 全部定案）` 第 3 项。
3. **`profile-service.md` 现有的表把 `PowerFragmentFirstWin(chapter)` 的 Min 写作「形态未定」并注「它以什么 `CostKey` 形态进 `Elements` 归『cost element 清单』那一问」。** 本方案正是在答这一问，故改写该行不算推翻既有决策，是既有决策明确挂起的那一格被填上。
4. **无。** 除上述三条外，本方案与 `ResourceElements` / 两层通则 / 三级判据 / 纪律阶梯 / 命名硬约定**全部一致**，未要求任何一条松动。

## 前置依赖

- **无阻塞性前置依赖。** §二.4 已论证资源族清单可在 `activeCombat` / RNG / `pastEvent` 三处通道与 `Project(spec)` 语义面之前独立闭合。
- **弱依赖（不阻塞定稿，仅影响文档措辞）→ 已答定：** 同批四份草稿合计把 `ProfileChangeSpec` 由 7 列推到 **11** 列（`RngElements` · `TraceElements` · `CodexElements` · `SettingChanges`），且**四份单批收口、共用同一次 `schemaVersion` bump** —— 本方案的任何一处**都不引用列表数**（既有承重表述本就明写「列表数不进承重表述」），故无实质冲突，仅 §二.4 的归宿表需要补一行。**本方案假定 `Elements` 这一列本身的形状不变**（`ChangeElement(CostKey, int BaseValue, ApplyOp Op)` 三字段），这是唯一的跨方案假定。
- **弱依赖：** 若日后 `CodexEntry` / `Achievement` / `GameSetting` 的写入通道落定为某个新列，本方案的归宿表需补三行 —— 但按 §二.4 的形状核对，它们**不会往资源族加成员**。
- **不跨库。** 新增的两个 key 对应的字段与 JSON path 已是既有透明路径，后端复算口径不变；本方案只定客户端**怎么写**，故按归属判据整体归客户端库，**不在 `backend-design-documents/` 落配套草稿**。

## 用户裁决（2026-08-19 · 全部定案）

**四项取向全部定案：决定 1 / 2 沿用 2026-08-18 批量评审的裁决，决定 3 已消解，决定 4 按本方案的推荐定案。** 本方案自此为**定案方案**，`## 建议方案` 与 `## 具体形态` 各节即最终形态，可直接喂给 `/analyze-new-ideas` 提炼。

| # | 取向 | 定案 | 承重理由（保留） |
|---|---|---|---|
| 1 | `CostKey.Experience` 是否改名 | **取 A —— 改名对齐字段**：`Experience` → `ExperiencePoint`、`PowerFragmentWinOrdinal` → `PowerFragmentFinaleWinOrdinal`<br>*（2026-08-18 已裁，照录）* | 一条约定一旦开例外就从「可机械检查」降级为「要读上下文」；且**改名成本此刻为零**（无线上存档），窗口随第一批存档写下而关闭 |
| 2 | `StatKey` 首批两项是否改名 | **取 A —— 改名，成员名 = 字段名逐字**：`TotalCyclesCompleted` / `TotalCyclesDefeated`<br>*（2026-08-18 已裁，照录）* | 「`Total` 前缀 ⇒ 统计层」的词缀约定对元素键也成立 ⇒ §四.2 的「两个枚举成员名空间不相交」成为**真的**可机械检查；且 `StatKey` 落存档、按成员名序列化，窗口与第 1 项同时关闭 |
| 3 | 两个序号 `Op` 的不对称如何处置 | **已消解，无需裁决。** `solution-draft-bundle-grant-ordinal-authority.md` 裁定「后端唯一 `+1`」⇒ `BundleGrantOrdinal` **整行撤下、不登记为 `CostKey` 成员**，表内只剩 `FinaleWinOrdinal`，不对称不复存在 | — |
| 4 | 是否给 `ElementSpec` 加第七列 `TargetPath` | **取 B —— 不加列，对齐规则停在评审级（第 4 级）**，`ElementSpec` 保持六列 | 按纪律阶梯的选级判据：「能上线且线上不可见 → 第 1 / 2 级；只在开发期显形 → 第 3 级足够」。命名不对齐**连开发期错误都不是**，是纯可读性问题；为它付一列常量 + 一段反射断言正是本库多次拒绝过的「为对称而加」。**留一句退让位**：若 `CostKey` 成员数长到 30+，性价比翻转，届时再加 |

**决定 1 / 2 连带的成员清单修正（照录 2026-08-18）：** 账号层第 8 个成员由 `BundleGrantOrdinal` 换为客户端写的水位字段 **`BundleRedeemedOrdinal`**（`AllowedOps = Set`、两修正列 `null`、不变式 `0 ≤ redeemed ≤ grant`），**总数仍为 15**。详见 `solution-draft-bundle-grant-ordinal-authority.md`。

**跨草稿裁决（`ProfileChangeSpec` 总列面）：** 本批四份草稿合计把列面由 7 推到 **11** 列，**已裁决为接受**，附硬要求：四份**单批收口、共用同一次 `schemaVersion` bump**。本方案「保留 `Elements` 一列、不新增列、不给 `ChangeElement` 加字段」的主张与之相容（§一 的跨方案假定成立）。

**非取向项、照方案闭合：** 本方案发现的 **`LastRoll` / `LastEffectiveChance` 无 `CostKey` 缺口**是一处实打实的不一致而非取舍，**补两行闭合**，不需要裁决。
