# Travel 的目的地承载字段与档案状态置值 element

- id: 2026-08-17-travel-destination-and-status-change-elements
- date: 2026-08-17
- topic: systems/services/future-event-service · systems/architecture · systems/services/profile-service · systems/services/life-cycle-service · systems/adventure-event/travel/common-properties · systems/adventure-event/explore/_index · systems/character-profile/_index · terminology
- status: distilled
- distilled-to: systems/architecture.md, systems/services/future-event-service.md, systems/services/profile-service.md, systems/services/life-cycle-service.md, systems/adventure-event/travel/common-properties.md, systems/adventure-event/explore/_index.md, systems/adventure-event/common-properties.md, systems/character-profile/_index.md, terminology.md

## Intent（distilled）

**一句话：** Travel 的**规则**已经收口，但它的**数据形态**有两处在库内没有落点——目的地在 `EventOption` 的字段骨架里没有位置，`CurrentLocationId`（`string`）与 `LocationEventCount`（归 0）在 `ProfileChangeSpec` 的既有列表里一个也装不下。本次给的是**通用形态**而非 Travel 专用补丁：Travel 只是第一个撞上「值不是带符号 int」的实例，band 三字段与 `ChapterLifeSpanBudget` 同样悬着。

### ① `EventOption` 增第八个字段 `DestinationLocationId`

```csharp
string DestinationLocationId   // Travel 的目的地 LocationData.Id；非 Travel 为空串
```

- 形态与 `RevealedEventId` 同款（只对某一类型有意义、其余类型填空串的结构性 id 字段）——不引入新惯用法，只是七字段 → 八字段。
- **必须落在定稿实例上，不能事后算。** 目的地由 map 子流从邻接集合抽出，是物化产物，重算不保证同结果；而「产出即定稿、不得回查模板重算」禁止消费侧再抽一次。
- **它使 UI 与结算共用同一份事实**：选项显示「前往 X」、resolver / life-cycle-service 据它写 `CurrentLocationId`——三处看到的必须是同一个 `Id`。

### ② Explore 遮罩 Travel 时，目的地同样在物化时掷定并落在壳实例上

- 推论来自既有纪律：候选必须预先算定并落决策点存档，否则退出重进可以重掷。目的地若等到揭示那一刻才掷，玩家退出重进即可刷一个更合意的地域。
- 故 Explore 壳的 `EventOption` 在 `RevealedEventId` 指向一个 Travel 条目时，`DestinationLocationId` 一并填好（必为随机那一档）。
- **配套的呈现侧约束（承重）：** `DestinationLocationId` 与 `RevealedEventId` 同属**揭示前不得进入呈现层**的字段。既有的 Explore 泄漏面纪律只点了定价侧，本条是它在字段侧的第二个实例，写在同一处以免被当成两条不同的纪律。

### ③ `PastEventEntry` 不新增目的地字段

`PastEventEntry.LocationId` 记出发地，目的地由下一条痕迹的 `LocationId` 自然给出。三种边界情形核查后结论仍成立：

- Travel 结算成功但轮回随即终结 → 目的地已写进 `Status.CurrentLocationId`，可直接读出；
- `Aborted`（支付 `selectCost` 后短路，未进 resolver）→ 换图从未发生，不存在「目的地」这一事实；
- 读档后继续 → `CurrentLocationId` 是存档字段，与痕迹序列一致。

按「重算得出来的不存」，加字段是净负收益。

### ④ `ProfileChangeSpec` 增一条列表 `StatusChanges`：Status 规则字段的绝对置值

```csharp
public sealed class ProfileChangeSpec                                      // 逐条按施加语义分列
{
    public IReadOnlyList<ChangeElement>        Elements        { get; }    // 资源：带符号的量
    public IReadOnlyList<AbilityChangeElement> AbilityElements { get; }    // 能力：按 Id 的集合成员操作
    public IReadOnlyList<StatDelta>            Stats           { get; }    // 统计计数：纯自增
    public IReadOnlyList<StatusAssignment>     StatusChanges   { get; }    // Status 规则字段：绝对置值
}

public readonly record struct StatusAssignment(   // 置值语义：赋为一个已算好的绝对值，不做加减
    StatusKey Key,
    int       IntValue,        // Key 声明为整型时使用
    string    StringValue);    // Key 声明为 id 型时使用；另一格填缺省

public enum StatusKey
{
    CurrentLocationId,          // string  —— 仅由 Travel 结算改写
    LocationEventCount,         // int     —— 非 Travel +1 / Travel 归 0（均以绝对值提交）
    FaithBand, BloodlustBand, LifeSpanBand,   // sbyte 存档字段，spec 内以 int 承载
    ChapterLifeSpanBudget,
}

internal readonly record struct StatusFieldSpec(StatusValueKind Kind, int Min, int? Max);
internal static readonly IReadOnlyDictionary<StatusKey, StatusFieldSpec> StatusFields = ...
public enum StatusValueKind { Int, Id }
```

- **`StatusChanges` 恒不走 modifier pipeline**（与 `AbilityElements` / `Stats` 同）。理由与统计层同源且更重：`CurrentLocationId` 若可被一条法则改写，等于让内容改写玩家的地图位置；band 若可被改写，等于让法则伪造隐藏属性档位。
- **为什么另立一列而不塞进既有几列：** 复用既有的分列判据——**施加语义根本不同就分列**。置值（赋一个已算好的绝对值、不累加、按 key 的声明类型可为 id）与「带符号的量」「集合成员操作」「纯自增」都不同；压进 `Elements` 是让 `ChangeElement.BaseValue` 这个带符号 int 说谎，也会污染 `ApplyResult.MissingElement: CostKey`（它只对资源列表有意义）。
- **事务性不受影响**：各列表在同一次 `TryApply` 内提交，「全有或全无、单点提交」原样成立。
- **一次性关掉四组悬空**：两个 location 字段 · 三个 band · `ChapterLifeSpanBudget`。

### ⑤ 结算侧的组装点：仍在 life-cycle-service，resolver 不变

- `GenericEventResolver` 对 Travel 不产出任何写入描述；两条 `StatusAssignment` 由 life-cycle-service 在组装 `eventEnd` 那一次 spec 时从 `option.DestinationLocationId` 读出并置入——与 band 字段由本服务算出绝对值并入同一次 spec、resolver 侧恒填空同款，保住「resolver 只描述结果、不自行写档」的边界。
- **判据写 `DestinationLocationId != ""`，不写 `EventType == Travel`。** 前者一次性覆盖「Explore 揭示出的 Travel 也归 0」（该情形 `EventType == Explore`，按类型判会漏），且不需要在 `EventOption` 上再加 `RevealedEventType`、也不需要回查模板。

  ```
  LocationEventCount 的新值 = option.DestinationLocationId != "" ? 0 : 前值 + 1
  CurrentLocationId  的新值 = option.DestinationLocationId != "" ? 该值 : 不提交这一条
  ```

### 落地面

| # | 落点 | 改动 |
|---|---|---|
| 1 | `EventOption` | 七字段 → **八字段**，新增 `string DestinationLocationId`（非 Travel 为空串） |
| 2 | future-event-service Travel 物化伪码 | 抽出的每个邻接 `Id` 填入该字段；Explore 壳在真身为 Travel 时一并填 |
| 3 | `explore/_index.md` | 泄漏面纪律补第二个实例：`DestinationLocationId` 与 `RevealedEventId` 同属揭示前不得进呈现层 |
| 4 | `PastEventEntry` | 不动 |
| 5 | `ProfileChangeSpec` | 增 `StatusChanges` 一列；新增 `StatusAssignment` / `StatusKey` / `StatusFields` / `StatusValueKind` |
| 6 | profile-service | `TryApply` 施加 `StatusChanges`：按 `StatusFields` 校验类型与取值域；`Id` 型解析不到 → `PushError` + 整批拒绝；恒不经 modifier pipeline |
| 7 | life-cycle-service | `eventEnd` 组装段增两条 `StatusAssignment`；判据用 `DestinationLocationId != ""` |
| 8 | 存档 schema | 不额外 bump——两个 `Status` 字段此前已随 location 载体落定并 bump 过；`EventOption` 快照多一个字段随「完整物化字段清单」那次 bump 一并处理 |

## Clarifications（评审裁决）

草稿以 `status: decided` 进入本次提炼，四项取向一律取推荐项：

1. **是否此刻落定 `StatusChanges`** → **此刻落定**。理由：缺口已有六个字段挂着，且 Travel 是其中唯一「整段收口、只等实现」的一类；不落定它，Travel 名义收口而实际不可 blueprint。
2. **`StatusAssignment` 的值形态** → **双字段单列表**（`IntValue` + `StringValue`），有效格由 `StatusFields` 表写死并机械校验。拆成两个列表必然出现「加了这张忘了那张」（与 `ResourceElements` 五列合表同一条判据）。
3. **`Id` 型置值解析不到** → **`PushError` + 整批拒绝**，与 `CurrentLocationId` 的读档校验口径一致。跳过该条会产生「寿元扣了但人没走成」的半套状态。
4. **`ApplyOp { Add, Set }`（`ResourceElements` 增一列）** → **另立待答项**交给 profile-service，不随本次加。它与 Travel 无因果关系，但确实是一处「纪律只写在散文里」的缺口。

**承重措辞改写获裁决通过：** `ProfileChangeSpec` 那条定案的判据本就是「按施加语义分列」，故 `architecture.md`「为什么是三个平级列表」与 `profile-service.md`「三个平级只读列表（承重）」两处改为**「逐条按施加语义分列」**——判据本身不动，只是不再把列表数写进承重表述，日后再增一列不必再改一次标题。

## Open questions

- **`ResourceElements` 是否增一列 `ApplyOp { Add, Set }`。** `ChangeElement` 只有 `(CostKey, int)` 而无 op，但 `BundleGrantOrdinal` 已明写为置值语义、`PowerFragmentAccumulated` 为累加 / 置值——「这一行是加还是赋」目前只写在散文里，没有任何类型或表格承载。**它不是 `StatusChanges` 的替代路径**：即便加了 `ApplyOp`，`CurrentLocationId` 仍是 `string`，`Elements` 仍装不下它。归 profile-service。
- **`plotKeyPoint` 的 element 形态。** 它同样声明「写入并入 `eventEnd` 那一次 `TryApply`」，但它是**集合型**、不是标量置值，`StatusChanges` 装不下。需要另一条列表（集合成员操作，形状可能近似 `AbilityElements`）或另一条通道。归 plot-manager / profile-service。
- **`EventOption` 的完整物化字段清单**仍待一次内容侧 handoff；本次只把 `DestinationLocationId` 这一个**结构性**字段提前落定，不连带答结那条。
- **卡组变更的 element 载体**将由 Research 专场另立一列 `DeckElements`，形态与字段面归那一场，本次不预设。

## Notes / triage

- 输入：`inbox/solution-draft-travel-mechanics.md`（`status: decided`），已归档进 `inbox/archive/`。
- 本次**未答结**任何既有待答项（两处缺口此前只被「`EventOption` 完整物化字段清单未定」笼统覆盖，该条被收窄而非关闭），故无 answer log。
- Travel 的**规则**一律不动：80/20 掷定 · 定价表 Travel 行 · 闸门 · 不设途中遭遇 · 换图后无特殊规则。
