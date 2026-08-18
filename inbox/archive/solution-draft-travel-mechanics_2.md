---
type: solution-draft
date: 2026-08-17
question: Travel 类 AdventureEvent 的机制虽已收口，但它的「目的地承载字段」与「结算写入面的 element 形态」两处数据形态在库内无落点——目的地在 `EventOption` 七字段骨架里没有位置，`CurrentLocationId`（string）/ `LocationEventCount`（置 0）在 `ProfileChangeSpec` 的三个列表里都装不下。
source: open-questions/03-adventure-event-types.md → 「各类型的结算 / 机制细化」（Travel 段已标注收口）；核查后发现的两处字段缺口，当前只被 `future-event-service.md` 的「`EventOption` 完整物化字段清单未定」笼统覆盖
targets: systems/services/future-event-service.md · systems/architecture.md（共享核心类型）· systems/services/profile-service.md · systems/services/life-cycle-service.md · systems/adventure-event/travel/common-properties.md · systems/adventure-event/explore/_index.md
status: distilled
decided-on: 2026-08-17
reviewed: 2026-08-17 — 四项取向一律取推荐；承重措辞「三个平级列表」改为「逐条按施加语义分列」获裁决通过
distilled-to: handoffs/2026-08-17-travel-destination-and-status-change-elements.md
---

> **本草稿已裁决（2026-08-17）：全部取向项一律按推荐方案定案。** 逐项见文末「## 仍需用户决定 → 已全部裁决」。

# 方案草稿 — Travel 的目的地承载字段与结算写入面的 element 形态

## 问题

Travel 的**玩法机制**确已在 `handoffs/2026-08-16g-travel-mechanics-and-location-carrier.md` 整段收口（常规出场走 location 类型修正 · 80/20 全局常量不可调制 · 代价走定价表且 > 0 · 不设途中遭遇 · 换图后无特殊规则）。`travel/_index.md` 现存的四条待决问题也确实全部归属别处（类型修正运算形态 → future-event-service；槽位数 `k` → 批次规模区间；定价数字 → ch1 数值标杆；关地域的运营替代 → content-service）。

但**收口的是规则，不是数据形态**。逐条核对既有定案与既有类型定义后，有两处 Travel 自己的落地面在库内没有承载：

1. **目的地无字段可放。** `future-event-service.md` 的 Travel 物化伪码写「这些邻接**各物化一个** Travel `EventOption`」——每个选项必须携带「这一个通向哪里」；而 `EventOption` 的七字段骨架（`InstanceId` / `EventId` / `EventType` / `Priority` / `SelectCost` / `IsRevealed` / `RevealedEventId`）里没有它。目前它只被「`EventOption` 完整物化字段清单未定」这条**笼统**待答项覆盖，而那条被明写为「需要一次**内容侧** handoff」——Travel 的目的地不是内容侧问题，它是结构性字段，不该等在那条后面。
2. **结算的写入面无 element 形态。** `travel/common-properties.md` 与 `character-profile/_index.md` 都明写：Travel 在 `eventEnd` 那**一次** `TryApply` 内更新 `CurrentLocationId`（改为目的地）与 `LocationEventCount`（归 0）。但 `ProfileChangeSpec` 是三个平级列表——`Elements: (CostKey Key, int BaseValue)`（带符号的量）· `AbilityElements`（按 `Id` 的集合成员操作）· `Stats: (StatKey, int Delta)`（纯自增）。**`CurrentLocationId` 是 `string`，三个列表没有一个装得下它**；`LocationEventCount` 归 0 是**绝对置值**，而 `Stats` 的语义是纯自增、`Elements` 的语义是带符号累加。

第 2 点不是 Travel 独有：三个隐藏属性 band 字段（`sbyte`，`life-cycle-service.md` 明写「按前值 + `AppliedChange` 算**绝对值**」）、`ChapterLifeSpanBudget`、`plotKeyPoint` 列表都同样声明「写入并入 `eventEnd` 那一次 `TryApply`」而同样没有 element 形态。**Travel 只是这个缺口第一个撞上「值不是 int」的实例**——故本草稿在此处给的是通用形态，而非 Travel 专用补丁。

## 约束（来自既有设计）

| 约束 | 来源 |
|---|---|
| 产出即定稿：`EventOption` 一经输出即冻结，消费侧**不得回查模板重算、不得改写字段** | `adventure-event/common-properties.md`「物化」· `future-event-service.md` |
| **物化产出的数值必进快照**（判据：重算不出来的存） | `adventure-event/common-properties.md`「痕迹 schema」 |
| **文本类字段一律不物化**（显示名 / 描述 / 图标 / 风味文案跟随模板） | `future-event-service.md`「意图」 |
| 随机**必须在 spec 组装之前掷完**；候选须预先算定并落存档，否则退出重进可重掷 | `profile-service.md`「`AbilityChangeElement` 只承载已定稿的 `Id`」· `adventure-event/common-properties.md` outcome 侧 |
| 档案写入**唯一入口** = `ProfileManager.TryApply`；一个事件 = 一次事务 = 一个存档点 | `architecture.md` 总则 8 · `life-cycle-service.md` |
| resolver **只描述结果，不自行写档** | `adventure-event/common-properties.md`「结算阶段」 |
| 三个列表分列的判据：施加语义根本不同就分列；**否决**「给 `ChangeElement` 加可空字段」与「多态 element」 | `architecture.md`「为什么是三个平级列表」 |
| `AbilityElements` / `Stats` **绝不走 modifier pipeline**；`Elements` 是 opt-in 白名单、缺省豁免 | `architecture.md` · `profile-service.md` |
| 逐行封闭表优于全局通则（`ResourceElements` 五列的判据） | `architecture.md`「资源 element 的语义是逐行一张封闭表」 |
| Explore 的泄漏面在**定价侧**，不在展示侧；真身在揭示前不可见 | `adventure-event/common-properties.md` · `explore/_index.md` |

## 建议方案

### ① `EventOption` 增加一个字段 `DestinationLocationId`

`[既有推演]`

```csharp
string DestinationLocationId   // Travel 的目的地 LocationData.Id；非 Travel 为空串
```

- **形态与 `RevealedEventId` 完全同款**（同为「只对某一类型有意义、其余类型填空串」的结构性 id 字段），故它不引入新惯用法，只是七字段 → 八字段。
- **它必须落在定稿实例上，不能事后算。** 目的地由 **map 子流从邻接集合抽出**（80% 档抽 `min(k, 邻接数)` 个、20% 档抽 1 个）——是**物化产物**，重算不保证同结果；而「产出即定稿、不得回查模板重算」禁止消费侧自己再抽一次。
- **它使 UI 与结算共用同一份事实**：选项上要显示「前往 X」（`LocationData` 的显示名按 `Id` 现取模板，文本仍不物化），resolver / life-cycle-service 要据它写 `CurrentLocationId`——三处看到的必须是同一个 `Id`。

### ② Explore 遮罩 Travel 时，目的地同样在**物化时**掷定并落在壳实例上

`[既有推演]`

- **推论来自既有纪律，不是新规则：** 「候选必须预先算定并落决策点存档，否则退出重进可以重掷」。若目的地等到揭示那一刻才掷，玩家退出重进即可刷一个更合意的地域——这正是本库反复否决的那类可优化漏洞。
- 故 **Explore 壳的 `EventOption` 在 `RevealedEventId` 指向一个 Travel 条目时，`DestinationLocationId` 一并填好**（必为 20% 随机那一档，见 `travel/_index.md`）。
- **配套的呈现侧约束（承重）：** `DestinationLocationId` 与 `RevealedEventId` 同属**揭示前不得进入呈现层**的字段。既有的 Explore 泄漏面纪律只点了定价侧（`lifeSpanCost` 的 Explore 行不得由真身推导），本条是它在字段侧的**第二个实例**——建议在 `explore/_index.md` 明写，并与 `RevealedEventId` 写在同一条里，避免日后被当成两条不同的纪律。

### ③ `PastEventEntry` **不**新增目的地字段

`[既有推演]`

- 既定：`PastEventEntry.LocationId` **记出发地**，目的地由**下一条痕迹**的 `LocationId` 自然给出。
- **核查过三种边界情形，结论仍成立**，故不必为「最后一条痕迹丢目的地」松动它：
  - Travel 结算成功但轮回随即终结（寿元归 0）→ 目的地已写进 `Status.CurrentLocationId`，可直接读出；
  - `Aborted`（支付 `selectCost` 后即短路，事件未进 resolver）→ **换图从未发生**，此时不存在「目的地」这一事实，痕迹本就不该记；
  - 读档后继续 → `CurrentLocationId` 是存档字段，与痕迹序列一致。
- 按判据「重算得出来的不存」，加字段是**净负收益**（bump schema 换零新增信息）。

### ④ `ProfileChangeSpec` 增加**第四个平级只读列表**：Status 规则字段的绝对置值

`[既有推演]` + `[取向选择]`（形态推荐明确，是否此刻落定归用户）

```csharp
public sealed class ProfileChangeSpec                                      // 四个平级只读列表
{
    public IReadOnlyList<ChangeElement>        Elements        { get; }    // 资源：带符号的量
    public IReadOnlyList<AbilityChangeElement> AbilityElements { get; }    // 能力：按 Id 的集合成员操作
    public IReadOnlyList<StatDelta>            Stats           { get; }    // 统计计数：纯自增
    public IReadOnlyList<StatusAssignment>     StatusChanges   { get; }    // ← 新增：Status 规则字段的绝对置值
}

public readonly record struct StatusAssignment(   // 置值语义：赋为一个已算好的绝对值，不做加减
    StatusKey Key,
    int       IntValue,        // Key 声明为整型时使用
    string    StringValue);    // Key 声明为 id 型时使用；另一格填缺省

public enum StatusKey
{
    CurrentLocationId,          // string  —— 仅由 Travel 结算改写
    LocationEventCount,         // int     —— 非 Travel +1 / Travel 归 0（均以绝对值提交）
    FaithBand, MaleficQiBand, LifeSpanBand,   // sbyte 存档字段，spec 内以 int 承载
    ChapterLifeSpanBudget,
    /* ⟨随各专场逐条补⟩ */
}

// 封闭表：逐行给出该 key 的值类型与取值域，与 ResourceElements 同款判据
internal readonly record struct StatusFieldSpec(StatusValueKind Kind, int Min, int? Max);
internal static readonly IReadOnlyDictionary<StatusKey, StatusFieldSpec> StatusFields = ...
// CurrentLocationId   → (Id,  -, -)      值须能经 ContentRegistry 解析为 LocationData，否则 PushError + 整批拒绝
// LocationEventCount  → (Int,  0, null)  施加后钳到 [0, ∞)
// FaithBand           → (Int, -2, 2)
// MaleficQiBand       → (Int,  0, 3)
// LifeSpanBand        → (Int,  0, 2)
public enum StatusValueKind { Int, Id }
```

- **`StatusChanges` 恒不走 modifier pipeline**（与 `AbilityElements` / `Stats` 同）。理由与统计层同源且更重：`CurrentLocationId` 若可被一条法则改写，等于让内容改写玩家的地图位置；band 若可被改写，等于让法则伪造隐藏属性档位。
- **为什么是第四个列表，而不是塞进既有三个：** 完全复用 `architecture.md` 已写下的分列判据——**施加语义根本不同就分列**。置值（赋一个已算好的绝对值、不累加、按 key 的声明类型可为 id）与「带符号的量」「集合成员操作」「纯自增」都不同；压进 `Elements` 是让 `ChangeElement.BaseValue` 这个带符号 int 说谎，也会污染 `ApplyResult.MissingElement: CostKey` 的语义（该字段被明写为「只对资源列表有意义」）。
- **事务性不受影响**：四个列表在同一次 `TryApply` 内提交，「全有或全无、单点提交」原样成立；`life-cycle-service` 的「一个事件 = 一次事务 = 一个存档点」不动。
- **它一次性关掉四组悬空**：两个 location 字段 · 三个 band · `ChapterLifeSpanBudget` · （`plotKeyPoint` 若按同款处理则另需一条集合型 element，见「前置依赖」）。

### ⑤ 顺带修补：`Elements` 的「累加 vs 置值」当前只由散文承载

`[既有推演]`（归属 profile-service，本草稿只提出）

`ChangeElement` 只有 `(CostKey, int)`，没有 op；但 `profile-service.md` 已明写 `BundleGrantOrdinal` 是**置值语义**、`PowerFragmentAccumulated` 是**累加 / 置值**。也就是说「这一行是加还是赋」目前**没有任何类型或表格承载**，只写在散文里。建议在 `ResourceElements` 增一列 `ApplyOp { Add, Set }`（逐行配表，与既有五列同款判据：没有通则能给出它）。

**这不是本方案的替代路径**——即便加了 `ApplyOp`，`CurrentLocationId` 仍是 `string`，`Elements` 仍装不下它。两条各修各的。

### ⑥ 结算侧的组装点：仍在 life-cycle-service，resolver 不变

`[既有推演]`

- **`GenericEventResolver` 对 Travel 不产出任何写入描述**；两条 `StatusAssignment` 由 **life-cycle-service 在组装 `eventEnd` 那一次 spec 时**从 `option.DestinationLocationId` 直接读出并置入——与既定的「band 字段由 life-cycle-service 算出绝对值并入同一次 spec、resolver 侧恒填空」**完全同款**，保住「resolver 只描述结果、不自行写档」的边界。
- **`LocationEventCount` 的判据建议写成 `DestinationLocationId != ""`，而不是 `EventType == Travel`。** 前者一次性覆盖「Explore 揭示出的 Travel 也归 0」这条既定规则（该情形下 `EventType == Explore`，按类型判会漏），且不需要在 `EventOption` 上再加一个 `RevealedEventType` 字段、也不需要回查模板。
  ```
  LocationEventCount 的新值 = option.DestinationLocationId != "" ? 0 : 前值 + 1
  CurrentLocationId  的新值 = option.DestinationLocationId != "" ? 该值 : 不提交这一条
  ```

## 具体形态（可 derive 的落地面）

| # | 落点 | 改动 |
|---|---|---|
| 1 | `EventOption` | 七字段 → **八字段**，新增 `string DestinationLocationId`（非 Travel 为空串） |
| 2 | `future-event-service` Travel 物化伪码 | 抽出的每个邻接 `Id` 填入该字段；Explore 壳在真身为 Travel 时一并填 |
| 3 | `explore/_index.md` | 泄漏面纪律补第二个实例：`DestinationLocationId` 与 `RevealedEventId` 同属揭示前不得进呈现层 |
| 4 | `PastEventEntry` | **不动**（目的地由下一条痕迹给出，三种边界情形均已核查） |
| 5 | `ProfileChangeSpec` | 三列表 → **四列表**，新增 `StatusChanges`；新增 `StatusAssignment` / `StatusKey` / `StatusFields` / `StatusValueKind` |
| 6 | `profile-service` | `TryApply` 施加 `StatusChanges`：按 `StatusFields` 校验类型与取值域；`Id` 型解析不到 → `PushError` + 整批拒绝（location 恒启用，解析不到即坏档，与读档校验口径一致）；**恒不经 modifier pipeline** |
| 7 | `life-cycle-service` | `eventEnd` 组装段增两条 `StatusAssignment`；判据用 `DestinationLocationId != ""` |
| 8 | 存档 schema | **不额外 bump**——`CurrentLocationId` / `LocationEventCount` 两个 `Status` 字段已随 08-16g 落定并 bump 过；本次改的是**运行时 spec 类型**，`EventOption` 快照多一个字段则随「完整物化字段清单」那次 bump 一并处理 |

## 后果

- **正面：** 四组「已声明并入 `TryApply` 却没有 element 形态」的 Status 规则字段一次性有了承载，且形态是既有分列判据的直接延伸，不引入新惯用法；Travel 的目的地从「笼统待答项里的一项」变成已定字段，Travel 自此**真正可 blueprint**。
- **代价：** `ProfileChangeSpec` 从三列表变四列表，`architecture.md`「共享核心类型」与「为什么是三个平级列表」两段需同改（后者的论证结构不变，只是从三条扩到四条）。
- **不触及：** 事务性、存档点数量、resolver 边界、modifier pipeline 的 opt-in 白名单纪律、Travel 的任何**规则**（80/20 · 定价 · 闸门 · 不设途中遭遇一律不动）。

## 备选方案（已考虑并否决）

- **给 `ChangeElement` 加可空 `TargetId` / op 字段** —— `architecture.md` 已明写否决（破坏带符号约定、让类型说谎）。
- **多态 element（`abstract record` + 子类）** —— 同上，已明写否决（破坏 `readonly record struct` 的零分配与 diff / 序列化的简单形态）。
- **给 `ProfileManager` 开一条窄通道 `SetLocation(string id)`** —— 否决：第二条写入通道与「档案写入唯一入口」「一个事件 = 一次事务」正面冲突，且 Travel 的换图必须与 `lifeSpanCost` 扣减落在同一事务内，分两次调用会产生半套写入。
- **把目的地藏进 `EventId` 的命名约定**（如 `travel.to_bamboo_sea`）—— 否决：目的地是从邻接集合 seeded 抽出的**运行时产物**，不是内容条目身份；这么做等于要求内容作者为每条边写一个 `.tres`，与「Travel 的常规出场不需要任何新字段」「目的地不是内容作者连好的边」直接冲突。
- **让消费侧按 `RevealedEventId` 回查模板取真身类型** —— 否决：`DestinationLocationId != ""` 这一判据已足够，且回查模板在消费侧是被明令禁止的动作。

## 与既有决策的张力

- **一处，且是「扩写」而非「推翻」：** `architecture.md` 的小节标题「**为什么是三个平级列表**」与 `profile-service.md` 的「`ProfileChangeSpec` = 三个平级只读列表（承重）」都把「三」写进了承重表述。本方案要求把它改成四。**判据本身完全不动**（施加语义不同就分列），改的只是它当前枚举出的实例数——若用户接受，应把两处措辞改为「平级只读列表，逐条按施加语义分列」，让日后再加第五条时不必再改一次标题。
- **不松动任何其他既有决策。**

## 前置依赖

- **不阻塞本方案：** 类型修正的运算形态 · 批次规模区间两端 / 槽位数 `k` · `lifeSpanCost` 定价表的绝对数字——三者都只影响 Travel 出几个、多贵，不影响它的字段形态。
- **本方案不覆盖、需另行答定：** `plotKeyPoint`（`IReadOnlyList<PlotKeyPoint>`）同样声明「写入并入 `eventEnd` 那一次 `TryApply`」，但它是**集合型**、不是标量置值，`StatusChanges` 装不下。它需要第五条列表（集合成员操作，形状可能近似 `AbilityElements`）或另一条通道——**归 plot-manager / profile-service 专场**，本草稿不预设形态。
- **`EventOption` 完整物化字段清单**仍待一次内容侧 handoff；本方案只主张把 `DestinationLocationId` 这一个**结构性**字段提前落定，不试图连带答结那条。

## 仍需用户决定 → **已全部裁决（2026-08-17）**

> **定案：四项一律取推荐项。** 即：
> ① **此刻落定 `StatusChanges`** —— 用户定案「`ProfileChangeSpec` 那条定案的判据本就是『按施加语义分列』，增列即可」，故张力节所述的承重措辞改写**已获裁决通过**：「三个平级列表」→「**逐条按施加语义分列**」。⚠ 本次与 Research 草稿的 `DeckElements` **合并生效，三 → 五**（两份草稿各增一列，不是各自三 → 四）。
> ② `StatusAssignment` 取**双字段单列表**（`IntValue` + `StringValue`，有效格由 `StatusFields` 表写死并机械校验）。
> ③ `Id` 型置值解析不到 → **`PushError` + 整批拒绝**。
> ④ `ApplyOp { Add, Set }` **另立待答项**交给 profile-service，不随本次加。
>
> 下列原文保留为选项与理由的溯源。

1. **是否此刻落定 `StatusChanges`（第四列表），还是留给 profile-service 专场一并处理。**
   - **推荐：此刻落定。** 缺口已有四组字段挂在上面（两个 location + 三个 band + 预算），且 Travel 是其中唯一已「整段收口、只等实现」的一类——不落定它，Travel 名义收口而实际不可 blueprint。
   - 代价：`architecture.md` 的承重措辞要改一次（见「张力」）。
2. **`StatusAssignment` 的值形态：双字段（`IntValue` + `StringValue`，按 key 的声明类型取其一）还是拆成两个列表（`StatusInts` / `StatusIds`）。**
   - **推荐：双字段单列表。** 拆表必然出现「加了这张忘了那张」（`ResourceElements` 五列合表的同一条判据）；双字段的浪费是每条 element 一个空引用，代价近零，且 `StatusFields` 表把「哪一格有效」写死成可机械校验的一列。
3. **`Id` 型 `StatusAssignment` 解析不到时：`PushError` + 整批拒绝，还是 `PushWarning` + 跳过该条。**
   - **推荐：`PushError` + 整批拒绝**，与 `CurrentLocationId` 的读档校验口径一致（location 是恒启用的结构性内容，解析不到即坏档）。跳过该条会产生「寿元扣了但人没走成」的半套状态，正是「全有或全无」要防的东西。
4. **`ApplyOp { Add, Set }` 这一列（建议 ⑤）是随本次一并加，还是另立一条待答项交给 profile-service。**
   - **推荐：另立待答项。** 它与 Travel 无因果关系，混进来会让本次评审面变宽；但它确实是一处「纪律只写在散文里」的缺口，不该无声漏掉。
